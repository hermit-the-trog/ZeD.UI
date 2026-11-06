-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerLog.lua
-- ============================================================================
-- THE LOG, THE SERVER'S SIDE (ZeDUI/MP_ADMIN_SCOPE.md, Phase 4; MP_SERVER_PART_DESIGN.md, A5 and A6). Srv.action is the one
-- log: md.log in the admin table holds it, and the file gets each line as it is written. This file reads that ring for the
-- Log view, and adds what the game has no event for:
--   vehicles   the seven timed actions wrapped where their complete runs, the last driver by the car's sqlId, a look every
--              10 seconds at who is driving (one pass over the players, never over the vehicles), and the tow command
--   PvP        kills from OnCharacterDeath; the game's own PvP log read off PVPLogTool, in a ring of its own
--   other mods the global writeLog tapped, in a ring of its own. Any client can write to any logger (A5), so those lines are
--              always labeled by where they came from, are never written to the ZeD log, and can't push out anything else
--
-- E2 is unsettled, though the bytecode reads well: NetTimedAction.perform takes complete with KahluaTable.rawget, and
-- KahluaTableImpl.rawget walks the metatable, so a wrap on the class is what it calls. Each class also has its .new wrapped, to
-- count. A class that makes HOOK_MISS actions and never reaches its complete turns the fallback on: each new action carries the
-- wrap itself. If the class wrap was fine all along that costs nothing, since rawget finds the same function first. l_probe and
-- one line in the ZeD log per class say which happened (ZeDUI/tools/qa/mp_log.lua reads them).
--
-- Views are allowlists. A line from the game's PvP log needs PVPLogTool, and the place of a role above the reader's stays out
-- of the view, as on the Player card. Nothing here touches a ticket's words.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_AdminProto"
require "ZeD/ZeD_LogProto"
require "ZeD/ZeD_ServerCore"
require "ZeD/ZeD_ServerTickets"
require "ZeD/ZeD_ServerAdmin"

local Srv = ZeD.Srv
local Tk = ZeD.Tk
local Lg = ZeD.Lg
if not Srv or Srv.off then return end

local L = Lg.L
-- (a capability a later game renamed would be nil, and hasCapability(nil) matches no overload: the view stays off)
local CAP_VIEW = Capability and Capability[Lg.VIEW_CAP]
local CAP_PVP = Capability and Capability.PVPLogTool
local CAP_ADMIN = Srv.CAP_ADMIN

-- memory only; a /reloadlua of this file keeps the probe's counts
local Lo = Srv.L or { P = { hooks = {}, missing = {}, tap = 0, tapKept = 0, pvp = 0, kills = 0, weapons = 0, polls = 0 }, pace = {}, pvpSeen = {}, weapon = {} }
Srv.L = Lo

-- the rings beside md.log and the last drivers, in the same secret table. Each line takes its s from md.log, so one order holds
local function rings(md)
    md.pvp = md.pvp or { n = 0, at = 0 }
    md.tap = md.tap or { n = 0, at = 0 }
    md.drivers = md.drivers or {}
    md.driverN = md.driverN or 0
    return md
end

local function ringAdd(md, ring, max, row)
    md.log.s = (md.log.s or 0) + 1
    row.s = md.log.s
    ring.at = (ring.at >= max) and 1 or (ring.at + 1)
    ring.n = math.min(ring.n + 1, max)
    ring[ring.at] = row
end

-- nil until the tables are open: nothing may open them before the game has loaded them
local function table_()
    if not (Srv.A and Srv.A.md) or Srv.logFrozen() then return nil end
    return rings(Srv.A.md)
end

-- at most n a minute per key; true when this one is over
local function over(key, n)
    local now = getTimestamp()
    local e = Lo.pace[key]
    if not e or now - e.at >= 60 then
        Lo.pace[key] = { at = now, n = 1 }
        return false
    end
    e.n = e.n + 1
    return e.n > n
end

-- ---------------------------------------------------------------------------
-- VEHICLES (A6)
-- ---------------------------------------------------------------------------
local function floor3(o) return math.floor(o:getX()), math.floor(o:getY()), math.floor(o:getZ()) end

-- what a line says about a car, read before the action runs: a stripped wreck is gone after it
local function carFacts(md, v)
    local id = v:getSqlId()
    local script = v:getScript()
    local d = (id and id >= 0) and md.drivers[id] or nil
    return { id = id, car = script and script:getName() or nil, owner = d and d.u or nil }
end

local function vehLine(md, o, what, car, ex)
    local user = o:getUsername()
    if car.owner == user and not Lg.OWN_CAR_LINES and what ~= "drive" then return end
    if over("veh:" .. user, L.VEH_PER_MIN) then return end
    local x, y, z = floor3(o)
    ex = ex or {}
    ex.car = car.car
    local detail = tostring(car.car)
    if ex.part then detail = detail .. "/" .. ex.part end
    if ex.locked then detail = detail .. " locked" end
    Srv.action("vehicle", user, what, car.owner, detail, x, y, z, ex)
end

local function trimDrivers(md)
    if md.driverN <= L.DRIVERS_MAX then return end
    local list, n = {}, 0
    for id, d in pairs(md.drivers) do
        n = n + 1
        list[n] = { id = id, t = d.t or 0 }
    end
    table.sort(list, function(a, b) return a.t < b.t end)
    local drop = math.max(1, math.floor(n / 10))
    for i = 1, drop do md.drivers[list[i].id] = nil end
    md.driverN = n - drop
end

-- A6's rule: someone other than the last driver has the car moving
function Lo.driverSeen(md, o, v)
    local id = v:getSqlId()
    if not id or id < 0 then return end
    local user = o:getUsername()
    local d = md.drivers[id]
    if d and d.u == user then
        d.t = getTimestamp()
        return
    end
    if d then vehLine(md, o, "drive", carFacts(md, v)) end
    if not d then md.driverN = md.driverN + 1 end
    md.drivers[id] = { u = user, t = getTimestamp() }
    trimDrivers(md)
end

-- each action: the car it works on, read before it runs, and what to say after. r is what the game's complete answered
local ACT = {
    ISSmashVehicleWindow = {
        before = function(act, snap)
            local parent = act.part and act.part:getParent()
            local door = parent and parent:getDoor()
            snap.locked = (door and door:isLocked()) and true or nil
        end,
        after = function(md, o, act, snap) vehLine(md, o, "smash", snap.car, { part = act.part and act.part:getId() or nil, locked = snap.locked }) end,
    },
    ISUninstallVehiclePart = {
        before = function(act, snap) snap.had = act.part ~= nil and act.part:getInventoryItem() ~= nil end,
        -- (the roll can fail: only a part that really came off is a line)
        after = function(md, o, act, snap)
            if snap.had and act.part:getInventoryItem() == nil then vehLine(md, o, "part", snap.car, { part = act.part:getId() }) end
        end,
    },
    ISTakeEngineParts = { after = function(md, o, act, snap) vehLine(md, o, "eparts", snap.car) end },
    ISTakeGasolineFromVehicle = { after = function(md, o, act, snap) vehLine(md, o, "siphon", snap.car) end },
    ISRemoveBurntVehicle = { after = function(md, o, act, snap) vehLine(md, o, "strip", snap.car) end },
    ISStartVehicleEngine = { after = function(md, o, act, snap) Lo.driverSeen(md, o, snap.v) end },
    ISHotwireVehicle = {
        after = function(md, o, act, snap)
            if snap.v:isHotwired() then
                vehLine(md, o, "hotwire", snap.car)
                Lo.driverSeen(md, o, snap.v)
            end
        end,
    },
}
Lo.ACT = ACT

local function actor(act)
    local o = act and act.character
    if o and instanceof(o, "IsoPlayer") then return o end
    return nil
end

-- (each runs inside pcall: a slip here must never cost the game its action)
local function before(name, act)
    local md = table_()
    local o = actor(act)
    if not (md and o) then return nil end
    local v = act.vehicle or (act.part and act.part:getVehicle()) or o:getVehicle()
    if not v then return nil end
    local snap = { v = v, car = carFacts(md, v) }
    local spec = ACT[name]
    if spec.before then spec.before(act, snap) end
    return snap
end

local function after(name, act, snap, r)
    local h = Lo.P.hooks[name]
    h.done = h.done + 1
    if h.done == 1 then Srv.action("admin", "server", "vehicle hook reached", name, h.fallback and "by the .new fallback" or "by the class") end
    if r == false or not snap then return end
    local md = table_()
    local o = actor(act)
    if md and o then ACT[name].after(md, o, act, snap) end
end

function Lo.before(name, act)
    local ok, snap = pcall(before, name, act)
    if ok then return snap end
    Lo.slip("before " .. name, snap)
    return nil
end
function Lo.after(name, act, snap, r)
    local ok, err = pcall(after, name, act, snap, r)
    if not ok then Lo.slip("after " .. name, err) end
end
function Lo.made(name, o, wrapped)
    local h = Lo.P.hooks[name]
    h.new = h.new + 1
    if h.new >= L.HOOK_MISS and h.done == 0 and not h.fallback then
        h.fallback = true
        Srv.action("admin", "server", "vehicle hook fallback on", name, tostring(h.new) .. " made, none completed")
    end
    if h.fallback and type(o) == "table" then o.complete = wrapped end
end
function Lo.slip(where, err)
    if over("slip:" .. where, 1) then return end
    Srv.action("admin", "server", "log hook failed", nil, where .. ": " .. tostring(err))
    print("[ZeD] server: log hook failed: " .. where .. ": " .. tostring(err))
end

-- (reload guard: Srv.hooked keeps its place across a /reloadlua, and each wrap looks Srv.L up at every call)
Srv.hooked = Srv.hooked or {}
local function wrap(name)
    if Srv.hooked[name] then return end
    local C = _G[name]
    if type(C) ~= "table" or type(C.complete) ~= "function" or type(C.new) ~= "function" then
        Lo.P.missing[#Lo.P.missing + 1] = name
        return
    end
    Srv.hooked[name] = true
    Lo.P.hooks[name] = Lo.P.hooks[name] or { new = 0, done = 0 }
    local base, baseNew = C.complete, C.new
    local wrapped = function(self)
        local snap = ZeD.Srv.L.before(name, self)
        local r = base(self)
        ZeD.Srv.L.after(name, self, snap, r)
        return r
    end
    C.complete = wrapped
    C.new = function(...)
        local o = baseNew(...)
        ZeD.Srv.L.made(name, o, wrapped)
        return o
    end
end
for name in pairs(ACT) do wrap(name) end

-- a tow: the game's own command, through one listener that tests the module first (A6)
function Lo.onCommand(module, command, player, args)
    if module ~= "vehicle" or command ~= "attachTrailer" then return end
    if type(args) ~= "table" or not player then return end
    -- (a client's numbers: anything but a whole one would match no overload of getVehicleById)
    if not (Tk.whole(args.vehicleA) and Tk.whole(args.vehicleB)) then return end
    local towed = getVehicleById(args.vehicleB)
    local md = table_()
    if towed and md then vehLine(md, player, "tow", carFacts(md, towed)) end
end

-- ---------------------------------------------------------------------------
-- PVP
-- ---------------------------------------------------------------------------
-- a kill: IsoGameCharacter.DoDeath fires this, and asks getAttackedBy as here to write the game's own kill line
function Lo.onDeath(chr)
    if not instanceof(chr, "IsoPlayer") or chr:isAnimal() then return end
    local by = chr:getAttackedBy()
    if not by or by == chr or not instanceof(by, "IsoPlayer") then return end
    Lo.P.kills = Lo.P.kills + 1
    local x, y, z = floor3(chr)
    Srv.action("pvp", by:getUsername(), "kill", chr:getUsername(), nil, x, y, z)
end

-- the weapon behind the game's next PvP line, which keeps no weapon of its own. A weapon is forgotten at each read
function Lo.onHit(wielder, target, weapon)
    if not (instanceof(wielder, "IsoPlayer") and instanceof(target, "IsoPlayer") and weapon) then return end
    Lo.P.weapons = Lo.P.weapons + 1
    Lo.weapon[wielder:getUsername() .. "\n" .. target:getUsername()] = weapon:getName()
end

-- the game keeps its last ten hits here on the server (PVPLogTool). A line reads [time] "wielder" hit "target"; the time is
-- the server's own, in a form nothing else here shares, so a line takes the time it was read, at most POLL_S late
function Lo.readPvp(md)
    if not PVPLogTool then
        Lo.weapon = {}
        return
    end
    local list = PVPLogTool.getEvents()
    local seen = {}
    for i = list:size() - 1, 0, -1 do
        local e = list:get(i)
        if e:isSet() then
            local text = e:getText()
            seen[text] = true
            if not Lo.pvpSeen[text] then
                local who, target = string.match(text, '^%[.-%] "(.*)" hit "(.*)"$')
                if who then
                    Lo.P.pvp = Lo.P.pvp + 1
                    ringAdd(md, md.pvp, L.PVP_MAX, { t = getTimestamp(), day = Srv.day(), kind = "pvp", src = "pvp", who = Tk.name(who), what = "hit", target = Tk.name(target),
                        text = Lo.weapon[who .. "\n" .. target], x = math.floor(e:getX()), y = math.floor(e:getY()), z = math.floor(e:getZ()) })
                end
            end
        end
    end
    Lo.pvpSeen = seen
    Lo.weapon = {}
end

-- ---------------------------------------------------------------------------
-- OTHER MODS' LINES (A5). The global writeLog, wrapped: every caller that looks it up at call time passes here, the game's own
-- ISLogSystem channel included. The ZeD log's own lines are skipped by name. The file gets its line whatever happens here.
-- ---------------------------------------------------------------------------
local function oneLine(text)
    local s = string.gsub(Tk.clean(string.sub(text, 1, 2 * L.TAP_TEXT)) or "", "\n", " ")
    return string.sub(s, 1, L.TAP_TEXT)
end

function Lo.tap(name, text)
    if type(name) ~= "string" or type(text) ~= "string" then return end
    if string.find(Lg.plainName(name), "zed", 1, true) then return end
    local md = table_()
    if not md then return end
    Lo.P.tap = Lo.P.tap + 1
    local by = Srv.tapBy
    if over("tap:" .. (by or ("=" .. name)), L.TAP_PER_MIN) then return end
    Lo.P.tapKept = Lo.P.tapKept + 1
    local kindWord, user, x, y, z = Lg.tapParse(text)
    ringAdd(md, md.tap, L.TAP_MAX, { t = getTimestamp(), day = Srv.day(), kind = Lg.tapKind(name, kindWord), src = "tap", lg = Tk.name(name), by = by,
        who = Tk.name(user or by or "?"), what = kindWord and Tk.name(kindWord) or nil, text = oneLine(text), x = x, y = y, z = z })
end

if not Srv.tapOn and writeLog then
    Srv.tapOn = true
    local base = writeLog
    writeLog = function(name, text)
        pcall(function() ZeD.Srv.L.tap(name, text) end)
        return base(name, text)
    end
end

-- ---------------------------------------------------------------------------
-- THE CLOCK: POLL_S seconds apart, on OnTickEvenPaused: the game clock stops on an empty server (A1)
-- ---------------------------------------------------------------------------
function Lo.tick()
    local now = getTimestamp()
    if Lo.at and now - Lo.at < L.POLL_S then return end
    Lo.at = now
    local md = table_()
    if not md then return end
    Lo.P.polls = Lo.P.polls + 1
    Srv.eachOnline(function(o)
        local v = o:getVehicle()
        if v and v:isDriver(o) and v:isEngineRunning() then Lo.driverSeen(md, o, v) end
    end)
    Lo.readPvp(md)
    for key, e in pairs(Lo.pace) do
        if now - e.at >= 60 then Lo.pace[key] = nil end
    end
end

if not Srv.logHooked then
    Srv.logHooked = true
    -- (looked up at each call, so a reload of this file takes effect; a slip costs one pass, not the event chain)
    local function safely(where, fn)
        return function(...)
            local ok, err = pcall(fn, ...)
            if not ok then ZeD.Srv.L.slip(where, err) end
        end
    end
    Events.OnTickEvenPaused.Add(safely("clock", function() ZeD.Srv.L.tick() end))
    Events.OnClientCommand.Add(safely("tow", function(module, command, player, args) ZeD.Srv.L.onCommand(module, command, player, args) end))
    Events.OnCharacterDeath.Add(safely("death", function(chr) ZeD.Srv.L.onDeath(chr) end))
    Events.OnWeaponHitCharacter.Add(safely("hit", function(wielder, target, weapon) ZeD.Srv.L.onHit(wielder, target, weapon) end))
end

-- ---------------------------------------------------------------------------
-- WHAT EACH PERSON RECEIVES: built field by field from an allowlist
-- ---------------------------------------------------------------------------
local function rowView(l)
    return { s = l.s, t = l.t, day = l.day, k = Lg.kindOf(l.kind), who = l.who, what = l.what, target = l.target, text = l.text, x = l.x, y = l.y, z = l.z,
        car = l.car, part = l.part, locked = l.locked, src = l.src, lg = l.lg, by = l.by }
end

local function noPlace(l)
    local c = {}
    for k, v in pairs(l) do c[k] = v end
    c.x, c.y, c.z = nil, nil, nil
    return c
end

local NO_RING = { n = 0 }
local function eachRing(md, fn)
    for _, ring in ipairs({ md.log, md.pvp or NO_RING, md.tap or NO_RING }) do
        for i = 1, ring.n do
            local l = ring[i]
            if l then fn(l) end
        end
    end
end

-- how this reader sees a line, or nil when it is not theirs to see. above: names found above them so far, this read
local function seenBy(l, canPvp, above, p)
    if l.src == "pvp" and not canPvp then return nil end
    if not l.x then return l end
    local up = above[l.who]
    if up == nil then
        up = Srv.outranks(p, l.who)
        above[l.who] = up
    end
    if up then return noPlace(l) end
    return l
end

local function canSeePvp(p) return CAP_PVP ~= nil and Srv.can(p, CAP_PVP) end

local function badText(s, max)
    return s ~= nil and (type(s) ~= "string" or #s > max)
end

-- who the Around line names: anyone seen here up to the filing whom the ticket's nearby list did not hold
local function missedOf(lines, facts)
    local by, out = {}, {}
    for _, l in ipairs(lines) do
        if l.t <= facts.filed and l.src ~= "tap" and l.who ~= "server" and l.who ~= facts.author and not facts.near[l.who] then
            local e = by[l.who]
            if e then
                e.from, e.to = math.min(e.from, l.t), math.max(e.to, l.t)
            else
                e = { who = l.who, from = l.t, to = l.t }
                by[l.who] = e
                out[#out + 1] = e
            end
        end
    end
    table.sort(out, function(a, b) return a.to > b.to end)
    for i = #out, L.MISSED_MAX + 1, -1 do out[i] = nil end
    return out
end

-- a read: q from the client's words, or nil with the answer sent
local function readQuery(p, a, rid)
    local kind, who, when, find = a.kind, a.who, a.when, a.find
    if (kind ~= nil and not Lg.KIND[kind]) or (when ~= nil and not Lg.WHEN[when]) or badText(who, Tk.LIMITS.NAME_MAX) or badText(find, L.FIND_MAX) or (a.page ~= nil and not Tk.whole(a.page)) then
        Srv.bad(p, "l_query")
        Srv.ack(p, rid, false, "text")
        return nil
    end
    local q = { kind = kind, who = who }
    find = Tk.clean(find)
    if find and find ~= "" then q.find = string.lower(find) end
    return q, when or Lg.DEFAULT_WHEN
end

local function query(p, a, rid)
    local md = Srv.logTable()
    local q, when = readQuery(p, a, rid)
    if not q then return end
    local base = {}                 -- the place and time alone, before the card's filters
    local around = nil
    local facts = nil
    if a.around ~= nil then
        if not Tk.whole(a.around) then
            Srv.bad(p, "l_query")
            Srv.ack(p, rid, false, "gone")
            return
        end
        facts = Srv.ticketFacts(a.around)
        if not facts then Srv.ack(p, rid, false, "gone"); return end
        if not (facts.place and facts.filed) then Srv.ack(p, rid, false, "noplace"); return end
        base.near = { x = facts.place.x, y = facts.place.y, r = Tk.NEAR }
        base.since, base.untilT = facts.filed - Lg.AROUND_BEFORE, facts.filed + Lg.AROUND_AFTER
        around = { id = facts.id, x = facts.place.x, y = facts.place.y, from = base.since, to = base.untilT, filed = facts.filed }
    else
        base.since = Lg.since(when, getTimestamp())
    end
    q.near, q.since, q.untilT = base.near, base.since, base.untilT
    local canPvp, above = canSeePvp(p), {}
    local kept, n, spot, all, names = {}, 0, {}, 0, {}
    eachRing(md, function(l0)
        local l = seenBy(l0, canPvp, above, p)
        if not l then return end
        all = all + 1
        if l.who ~= "server" and not names[l.who] then names[l.who] = true end
        if facts and Lg.keep(l, base) then spot[#spot + 1] = l end
        if Lg.keep(l, q) then
            n = n + 1
            kept[n] = l
        end
    end)
    table.sort(kept, Lg.newest)
    local pages = math.max(1, math.ceil(n / L.ROWS))
    local page = math.min(a.page or 1, pages)
    local rows = {}
    for i = (page - 1) * L.ROWS + 1, math.min(n, page * L.ROWS) do rows[#rows + 1] = rowView(kept[i]) end
    local out = { qid = Tk.whole(a.qid) and a.qid or nil, rows = rows, n = n, all = all, page = page, pages = pages, opt = Lg.CONTAINER_LOG and true or nil }
    if page == 1 then
        local list = {}
        for u in pairs(names) do list[#list + 1] = u end
        table.sort(list, function(x, y) return string.lower(x) < string.lower(y) end)
        for i = #list, L.NAMES_MAX + 1, -1 do list[i] = nil end
        out.names = list
    end
    if around then
        around.missed = missedOf(spot, facts)
        out.around = around
    end
    Srv.to(p, Lg.MOD, "l_page", out)
    if rid then Srv.ack(p, rid, true) end
end

-- a line in words the server can write, for an admin note. Its times are written with the line: the card's dates are the viewer's
local function noteText(l)
    local parts = { "Log, " .. Lg.stamp(l.t) .. ", day " .. tostring(l.day) .. ": " .. tostring(l.who) }
    if l.what then parts[#parts] = parts[#parts] .. " " .. l.what end
    if l.target then parts[#parts + 1] = tostring(l.target) end
    if l.car then parts[#parts + 1] = tostring(l.car) end
    if l.part then parts[#parts + 1] = tostring(l.part) end
    if l.locked then parts[#parts + 1] = "locked" end
    if l.text then parts[#parts + 1] = tostring(l.text) end
    if l.x then parts[#parts + 1] = "at " .. tostring(l.x) .. " x " .. tostring(l.y) end
    if l.src == "pvp" then parts[#parts + 1] = "from the game's PvP log" end
    if l.src == "tap" then parts[#parts + 1] = "from the log " .. tostring(l.lg) .. ", not proved" end
    return string.sub(table.concat(parts, ", "), 1, Tk.LIMITS.TEXT_MAX)
end

local function lineOf(md, s)
    local found = nil
    eachRing(md, function(l) if l.s == s then found = l end end)
    return found
end

-- ---------------------------------------------------------------------------
-- THE COMMANDS
-- ---------------------------------------------------------------------------
if CAP_VIEW and Srv.logTable then
    Srv.register(Lg.MOD, "l_query", { cap = CAP_VIEW, limit = L.QUERY_MS }, query)

    -- a line of the log, as an admin note on its ticket
    Srv.register(Lg.MOD, "l_tonote", { cap = Srv.CAP_STAFF, limit = L.NOTE_MS }, function(p, a, rid)
        if not (Tk.whole(a.id) and Tk.whole(a.s)) then
            Srv.bad(p, "l_tonote")
            Srv.ack(p, rid, false, "gone")
            return
        end
        local md = Srv.logTable()
        local l0 = lineOf(md, a.s)
        local l = l0 and seenBy(l0, canSeePvp(p), {}, p) or nil
        if not l then
            Srv.ack(p, rid, false, "gone")
            return
        end
        local ok, err = Srv.ticketNote(p, a.id, noteText(l))
        Srv.ack(p, rid, ok, err)
    end)

    -- QA: what the hooks have seen (E2, E1). Counts only
    Srv.register(Lg.MOD, "l_probe", { cap = CAP_ADMIN }, function(p, a, rid)
        local P = Lo.P
        local hooks = {}
        for name, h in pairs(P.hooks) do hooks[name] = { new = h.new, done = h.done, fallback = h.fallback } end
        Srv.to(p, Lg.MOD, "l_probe", { hooks = hooks, missing = P.missing, tap = P.tap, tapKept = P.tapKept, pvp = P.pvp, kills = P.kills, weapons = P.weapons, polls = P.polls, hasPvp = PVPLogTool ~= nil })
    end)

    Srv.modules[Lg.MOD] = true
    Srv.helloAdds.log = function(p, r) r.lg = 1 end
else
    Srv.action("admin", "server", "log view off", nil, "no " .. Lg.VIEW_CAP .. " capability, or no admin tools to hold the ring")
end

return Lo
