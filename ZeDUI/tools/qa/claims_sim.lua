-- ZeDUI/tools/qa/claims_sim.lua  (Nov 5 2026, QA): multiplayer Phase 3, safehouses and factions, with no game running.
-- Lua 5.1 stubs of the game's SafeHouse, Faction, wars, server options and the packets those cards use, each
-- written from its javap listing, so a call the game would refuse is refused here too. The real files run against them:
-- ZeD_TicketProto, ZeD_ClaimProto, ZeD_ServerCore and ZeD_ServerClaims on the server side (or none of them, for a server
-- without the server part), ZeD_ServerLink and ZeD_Claims on each simulated client. Every message crosses a stub of the
-- network with the game's rules, a step at a time. Claims, rules, the checker, invitations, owners, tags, wars, the server
-- part's views and permissions, and the log. Run from the repo root:
--   lua51 ZeDUI/tools/qa/claims_sim.lua
-- It prints FAIL lines and a last line "claims_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]claims_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ---------------------------------------------------------------------------
-- THE WORLD
-- ---------------------------------------------------------------------------
local W

local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end,
        contains = function(_, v) for _, x in ipairs(t) do if x == v then return true end end return false end }
end

local function events()
    return setmetatable({}, { __index = function(self, name)
        local ev = { list = {} }
        function ev.Add(fn) ev.list[#ev.list + 1] = fn end
        function ev.Remove(fn)
            for i = #ev.list, 1, -1 do if ev.list[i] == fn then table.remove(ev.list, i) end end
        end
        function ev.fire(...) for _, fn in ipairs(ev.list) do fn(...) end end
        rawset(self, name, ev)
        return ev
    end })
end

local function netCopy(v)
    local t = type(v)
    if t == "table" then
        local out = {}
        for k, x in pairs(v) do
            if type(k) ~= "string" and type(k) ~= "number" then error("a key the network drops: " .. type(k)) end
            out[k] = netCopy(x)
        end
        return out
    elseif t == "string" or t == "number" or t == "boolean" then
        return v
    end
    error("a value the network drops: " .. t)
end
local function wire(a)
    local c = netCopy(a or {})
    if next(c) == nil then return nil end
    return c
end

local function drain()
    local guard = 0
    while #W.net > 0 do
        guard = guard + 1
        if guard > 100000 then error("the network never drains") end
        table.remove(W.net, 1)()
    end
end
local function net(fn) W.net[#W.net + 1] = fn end

local function step(ms)
    W.clock = W.clock + ms
    drain()
    for _, c in pairs(W.clients) do
        if c.up then c.env.Events.OnTick.fire() end
    end
    drain()
    if W.server then W.server.Events.OnTickEvenPaused.fire() end
    drain()
end
local function advance(ms)
    drain()
    while ms > 0 do
        local d = math.min(ms, 100)
        step(d)
        ms = ms - d
    end
end

local CAPS = { AnswerTickets = "AnswerTickets", RolesWrite = "RolesWrite", CanSetupSafehouses = "CanSetupSafehouses",
    FactionCheat = "FactionCheat", CanGoInsideSafehouses = "CanGoInsideSafehouses" }
local function role(name, caps)
    local r = { name = name, caps = caps }
    function r.getName(self) return self.name end
    function r.hasCapability(self, cap)
        if cap == nil then error("No implementation found: hasCapability(nil)") end
        return self.caps[cap] == true
    end
    return r
end
local ROLES = {
    user = role("user", {}),
    admin = role("admin", { AnswerTickets = true, RolesWrite = true, CanSetupSafehouses = true, FactionCheat = true, CanGoInsideSafehouses = true }),
}

-- ---------------------------------------------------------------------------
-- THE GAME: its lists, and each packet's checks from the bytecode
-- ---------------------------------------------------------------------------
local function colorInfo(r, g, b) return { getR = function() return r end, getG = function() return g end, getB = function() return b end } end

local cheat

local function newSafe(x, y, w, h, owner)
    W.safeN = W.safeN + 1
    local s = { x = x, y = y, w = w, h = h, owner = owner, title = owner, players = { owner }, respawn = {}, invites = {},
        id = "safe" .. W.safeN, onlineId = 1000 + W.safeN, visited = W.clock, created = "Nov 5", location = "Riverside" }
    function s.getId(self) return self.id end
    function s.getOwner(self) return self.owner end
    function s.getTitle(self) return self.title end
    function s.getX(self) return self.x end
    function s.getY(self) return self.y end
    function s.getW(self) return self.w end
    function s.getH(self) return self.h end
    function s.getOnlineID(self) return self.onlineId end
    function s.getLocation(self) return self.location end
    function s.getDatetimeCreatedStr(self) return self.created end
    function s.getLastVisited(self) return self.visited end
    function s.getPlayers(self) return jlist(self.players) end
    function s.isOwner(self, who)
        if type(who) == "table" then who = who:getUsername() end
        return self.owner == who
    end
    function s.isRespawnInSafehouse(self, who) return self.respawn[who] == true end
    function s.playerAllowed(self, who)
        for _, n in ipairs(self.players) do if n == who:getUsername() then return true end end
        return cheat(who, "CanGoInsideSafehouses")
    end
    function s.alreadyHaveSafehouse(self, who)
        for _, o in ipairs(W.safes) do
            for _, n in ipairs(o.players) do if n == who then return o end end
        end
        return nil
    end
    function s.hasInvite(self, who) return self.invites[who] == true end
    function s.removeInvite(self, who) self.invites[who] = nil end
    W.safes[#W.safes + 1] = s
    return s
end

local function safeOfName(name)
    for _, s in ipairs(W.safes) do
        for _, n in ipairs(s.players) do if n == name then return s end end
    end
    return nil
end

local function newFaction(name, owner)
    local f = { name = name, owner = owner, players = {}, invites = {} }
    function f.getName(self) return self.name end
    function f.getOwner(self) return self.owner end
    function f.getTag(self) return self.tag end
    function f.setTag(self, s) self.tag = s end
    function f.getTagColor(self) return self.color end
    function f.setTagColor(self, c) self.color = c end
    function f.getPlayers(self) return jlist(self.players) end
    function f.isOwner(self, who) return self.owner == who end
    function f.isMember(self, who)
        if self.owner == who then return true end
        for _, n in ipairs(self.players) do if n == who then return true end end
        return false
    end
    function f.canCreateTag(self) return #self.players + 1 >= W.opts.FactionPlayersRequiredForTag end
    function f.hasInvite(self, who) return self.invites[who] == true end
    function f.removeInvite(self, who) self.invites[who] = nil end
    W.factions[#W.factions + 1] = f
    return f
end

local function factionOfName(name)
    for _, f in ipairs(W.factions) do
        if f:isMember(name) then return f end
    end
    return nil
end

local function player(name, roleName, x, y)
    local p = { name = name, role = ROLES[roleName or "user"], x = x or 6402.5, y = y or 5410.5, z = 0, hours = 300, showTag = true, pvp = false }
    function p.getUsername(self) return self.name end
    function p.getRole(self) return self.role end
    function p.getX(self) return self.x end
    function p.getY(self) return self.y end
    function p.getZ(self) return self.z end
    function p.getHoursSurvived(self) return self.hours end
    function p.isShowTag(self) return self.showTag end
    function p.setShowTag(self, v) self.showTag = v end
    function p.isFactionPvp(self) return self.pvp end
    function p.setFactionPvp(self, v) self.pvp = v end
    function p.getCurrentSquare(self) return W.squareAt(self) end
    W.online[#W.online + 1] = p
    W.players[name] = p
    return p
end

local function square(p, inside, building)
    return { player = p, getBuilding = function() return inside and (building or {}) or nil end, getX = function() return p.x end, getY = function() return p.y end }
end

function cheat(p, cap) return p.role.caps[cap] == true end

-- SafeHouse.canBeSafehouse, its reasons in its order
local function canBe(sq, p)
    local o = W.opts
    if not o.PlayerSafehouse and not o.AdminSafehouse then return nil end
    local out = ""
    if o.PlayerSafehouse and safeOfName(p.name) then out = out .. "already have\r\n" end
    local days = o.SafehouseDaySurvivedToClaim
    if not o.PlayerSafehouse and o.AdminSafehouse then
        if not cheat(p, "CanSetupSafehouses") then return nil end
        days = 0
    end
    if days > 0 and p.hours < days * 24 then out = out .. "survive " .. days .. "\r\n" end
    if W.spawnBuilding then out = out .. "spawn\r\n" end
    if W.someoneInside then out = out .. "occupied\r\n" end
    if W.notHome and not o.SafehouseAllowNonResidential then out = out .. "not house\r\n" end
    return out
end

local function hurt(c, what)
    c.refused = c.refused or {}
    c.refused[#c.refused + 1] = what
end

-- AntiCheatSafeHouseOwner and AntiCheatSafeHouseMember: these do not just drop a packet. The counter acts at 1 and
-- AntiCheatSafeHouse defaults to 2, so the first one kicks.
local function ownerCheck(c, p, s)
    if s.owner == p.name or cheat(p, "CanSetupSafehouses") then return true end
    hurt(c, "KICK owner not found")
    return false
end
local function memberCheck(c, p, s, who)
    if cheat(p, "CanSetupSafehouses") then return true end
    if who ~= p.name and s.owner ~= p.name then hurt(c, "KICK player not found and sender is not owner"); return false end
    if safeOfName(who) ~= s then hurt(c, "KICK player is not member or owner of safehouse"); return false end
    return true
end

local function syncAll()
    for _, c in pairs(W.clients) do
        if c.up then net(function() c.env.Events.OnSafehousesChanged.fire() end) end
    end
end
local function syncFaction(name)
    for _, c in pairs(W.clients) do
        if c.up then net(function() c.env.Events.SyncFaction.fire(name) end) end
    end
end

local function installGame(env, c, p)
    env.getServerOptions = function()
        return {
            getBoolean = function(_, k) return W.opts[k] end,
            getInteger = function(_, k) return W.opts[k] end,
        }
    end
    env.SafeHouse = {
        hasSafehouse = function(who) return safeOfName(type(who) == "table" and who:getUsername() or who) end,
        getSafehouseList = function() return jlist(W.safes) end,
        getSafeHouse = function(sq)
            if type(sq) ~= "table" then error("getSafeHouse: only a square here") end
            return W.claimedHere
        end,
        canBeSafehouse = function(sq, pl)
            W.calls.canBe = W.calls.canBe + 1
            if not sq:getBuilding() then error("NullPointerException: the game reads the building with no test") end
            return canBe(sq, pl)
        end,
        hasNotSurvivedEnoughToClaim = function(pl)
            if cheat(pl, "CanSetupSafehouses") then return false end
            return W.opts.SafehouseDaySurvivedToClaim > 0 and pl.hours < W.opts.SafehouseDaySurvivedToClaim * 24
        end,
    }
    env.Faction = {
        getPlayerFaction = function(who) return factionOfName(type(who) == "table" and who:getUsername() or who) end,
        getFactions = function() return jlist(W.factions) end,
        getFaction = function(name)
            for _, f in ipairs(W.factions) do if f.name == name then return f end end
            return nil
        end,
        factionExist = function(name)
            for _, f in ipairs(W.factions) do if f.name == name then return true end end
            return false
        end,
        tagExist = function(tag)
            for _, f in ipairs(W.factions) do if f.tag == tag then return true end end
            return false
        end,
        isAlreadyInFaction = function(who) return factionOfName(type(who) == "table" and who:getUsername() or who) ~= nil end,
        canCreateFaction = function(pl)
            if not W.opts.Faction then return false end
            if cheat(pl, "FactionCheat") then return true end
            if W.opts.FactionDaySurvivedToCreate == 0 then return true end
            return pl.hours >= W.opts.FactionDaySurvivedToCreate * 24
        end,
    }
    env.ColorInfo = { new = function(r, g, b, a) return colorInfo(r, g, b) end }
    env.State = { Accepted = "Accepted", Refused = "Refused", Canceled = "Canceled", Ended = "Ended", Claimed = "Claimed" }
    if not c then return end
    -- the client's globals: each sends a packet with the server's checks, as javap shows them
    local function packet(fn) net(fn) end
    env.getWars = function()
        local out = {}
        for _, w in ipairs(W.wars) do
            if cheat(p, "CanGoInsideSafehouses") or w.attacker == p.name or w:getDefender() == p.name then out[#out + 1] = w end
        end
        return jlist(out)
    end
    env.sendSafehouseClaim = function(sq, pl, title)
        W.calls.claim = W.calls.claim + 1
        packet(function()
            if canBe(sq, pl) ~= "" then return hurt(c, "claim") end
            local s = newSafe(math.floor(pl.x) - 5, math.floor(pl.y) - 5, 10, 10, pl.name)
            s.title = title
            syncAll()
        end)
    end
    env.sendSafehouseChangeTitle = function(s, title)
        packet(function()
            if title == nil or title == "" then return hurt(c, "title empty") end
            if not ownerCheck(c, p, s) then return end
            s.title = title
            syncAll()
        end)
    end
    env.sendSafehouseChangeRespawn = function(s, who, on)
        packet(function() s.respawn[who] = on or nil; syncAll() end)
    end
    env.sendSafehouseInvite = function(s, host, who)
        packet(function()
            if not ownerCheck(c, p, s) then return end
            if safeOfName(who) then return hurt(c, "already in one") end
            s.invites[who] = true
            local to = W.clients[who]
            if to and to.up then net(function() to.env.Events.ReceiveSafehouseInvite.fire(s, host, who) end) end
        end)
    end
    env.acceptSafehouseInvite = function(s, host, who, yes)
        packet(function()
            if safeOfName(who) then return hurt(c, "already in one") end
            if not s.invites[who] then return hurt(c, "invite is not found") end
            if yes then s.players[#s.players + 1] = who end
            s.invites[who] = nil
            syncAll()
        end)
    end
    env.sendSafehouseChangeMember = function(s, who)
        packet(function()
            if not memberCheck(c, p, s, who) then return end
            if s.owner == who then return hurt(c, "player is owner") end
            for i = #s.players, 1, -1 do if s.players[i] == who then table.remove(s.players, i) end end
            syncAll()
        end)
    end
    env.sendSafehouseChangeOwner = function(s, who)
        packet(function()
            if not ownerCheck(c, p, s) then return end
            local t = W.players[who]
            if not t then return hurt(c, "player is not found") end
            if env.SafeHouse.hasNotSurvivedEnoughToClaim(t) then return hurt(c, "player is not survived enough") end
            if s.owner == who then return hurt(c, "player is already owner") end
            local o = safeOfName(who)
            if o and o ~= s then return hurt(c, "player is already member") end
            s.owner = who
            local found = false
            for _, n in ipairs(s.players) do if n == who then found = true end end
            if not found then s.players[#s.players + 1] = who end
            syncAll()
        end)
    end
    env.sendSafehouseRelease = function(s)
        packet(function()
            if not ownerCheck(c, p, s) then return end
            for i = #W.safes, 1, -1 do if W.safes[i] == s then table.remove(W.safes, i) end end
            syncAll()
        end)
    end
    env.sendFactionCreate = function(name, who)
        packet(function()
            if env.Faction.factionExist(name) then return hurt(c, "faction is already exists") end
            if #name < 3 or #name > 15 then return hurt(c, "title length is incorrect") end
            if factionOfName(who) and not cheat(p, "FactionCheat") then return hurt(c, "already member") end
            if not env.Faction.canCreateFaction(W.players[who]) then return hurt(c, "can't create") end
            newFaction(name, who)
            syncFaction(name)
        end)
    end
    env.sendFactionChangeTitle = function(f, name)
        packet(function()
            if f.owner ~= p.name and not cheat(p, "FactionCheat") then return hurt(c, "owner not found") end
            f.name = name
            syncFaction(name)
        end)
    end
    -- (what FactionTag copies off the object as it sends. Only the server's FactionSync writes it to the clients, the sender too)
    env.sendFactionChangeTag = function(f)
        local tag, color = f.tag, f.color
        packet(function()
            if tag == nil then return hurt(c, "tag is null") end
            if env.Faction.tagExist(tag) and f.owner ~= p.name then return hurt(c, "tag already exists") end
            if #tag < 1 or #tag > 4 then return hurt(c, "tag length is incorrect") end
            if not f:canCreateTag() then return hurt(c, "no enough players") end
            f.tag, f.color = tag, color
            syncFaction(f.name)
        end)
    end
    env.sendFactionInvite = function(f, host, who)
        packet(function()
            if factionOfName(who) then return hurt(c, "already in one") end
            f.invites[who] = true
            local to = W.clients[who]
            if to and to.up then net(function() to.env.Events.ReceiveFactionInvite.fire(f, host, who) end) end
        end)
    end
    env.acceptFactionInvite = function(f, host, who, yes)
        packet(function()
            if factionOfName(who) then return hurt(c, "already in one") end
            if not f.invites[who] then return hurt(c, "invite is not found") end
            if yes then f.players[#f.players + 1] = who end
            f.invites[who] = nil
            syncFaction(f.name)
        end)
    end
    env.sendFactionChangeOwner = function(f, who)
        packet(function()
            local t = W.players[who]
            if not t then return hurt(c, "player is not found") end
            if not env.Faction.canCreateFaction(t) then return hurt(c, "can't create") end
            if f.owner == who then return hurt(c, "already owner") end
            local o = factionOfName(who)
            if o and o ~= f then return hurt(c, "already member") end
            for i = #f.players, 1, -1 do if f.players[i] == who then table.remove(f.players, i) end end
            f.players[#f.players + 1] = f.owner
            f.owner = who
            syncFaction(f.name)
        end)
    end
    env.sendFactionRemoveMember = function(f, who)
        packet(function()
            if f.owner == who then return hurt(c, "player is owner") end
            for i = #f.players, 1, -1 do if f.players[i] == who then table.remove(f.players, i) end end
            syncFaction(f.name)
        end)
    end
    env.sendFactionDisband = function(f)
        packet(function()
            for i = #W.factions, 1, -1 do if W.factions[i] == f then table.remove(W.factions, i) end end
            syncFaction(f.name)
        end)
    end
    env.sendFactionStatsChange = function(pl) packet(function() syncFaction("") end) end
    env.sendWarManagerUpdate = function(id, attacker, state)
        W.warCalls[#W.warCalls + 1] = { id = id, attacker = attacker, state = state, by = p.name }
        for _, w in ipairs(W.wars) do
            if w.onlineId == id and w.attacker == attacker then w.state = state end
        end
    end
end

local function newWar(s, attacker, state, time)
    local w = { onlineId = s.onlineId, attacker = attacker, state = state, time = time or "00:04:30" }
    function w.getOnlineID(self) return self.onlineId end
    function w.getAttacker(self) return self.attacker end
    function w.getDefender(self) return s.owner end
    function w.getState(self) local st = self.state; return { name = function() return st end } end
    function w.getTime(self) return self.time end
    W.wars[#W.wars + 1] = w
    return w
end

-- ---------------------------------------------------------------------------
-- THE TWO SIDES
-- ---------------------------------------------------------------------------
local function baseEnv()
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.Events = events()
    env.print = function(s) env.printed = (env.printed or "") .. tostring(s) .. "\n" end
    env.getTimestampMs = function() return W.clock end
    env.getTimestamp = function() return math.floor(W.clock / 1000) end
    env.Capability = CAPS
    env.loaded = {}
    return env
end

local function runFile(env, rel)
    local f = assert(loadfile(ROOT .. rel))
    setfenv(f, env)
    return f()
end

local FILES = {
    ["ZeD/ZeD_TicketProto"] = "42/media/lua/shared/ZeD/ZeD_TicketProto.lua",
    ["ZeD/ZeD_ClaimProto"] = "42/media/lua/shared/ZeD/ZeD_ClaimProto.lua",
    ["ZeD/ZeD_ServerCore"] = "42/media/lua/server/ZeD/ZeD_ServerCore.lua",
    ["ZeD/ZeD_ServerLink"] = "42/media/lua/client/ZeD/ZeD_ServerLink.lua",
}
local function requireIn(env, name)
    if env.loaded[name] then return end
    env.loaded[name] = true
    if FILES[name] then runFile(env, FILES[name]) end
end

local function serverStart()
    local env = baseEnv()
    W.server = env
    env.isServer = function() return true end
    env.isClient = function() return false end
    env.require = function(n) requireIn(env, n) end
    env.getOnlinePlayers = function() return jlist(W.online) end
    env.getGameTime = function() return { getWorldAgeHours = function() return 270 end } end
    env.writeLog = function(name, line) W.logs[#W.logs + 1] = { name = name, line = line } end
    env.sendServerCommand = function(p, module, command, args)
        local a = wire(args)
        net(function()
            local c = W.clients[p.name]
            if c and c.up then c.env.Events.OnServerCommand.fire(module, command, a) end
        end)
    end
    env.ISLogSystem = { writeLog = function() end }
    installGame(env)
    requireIn(env, "ZeD/ZeD_ServerCore")
    runFile(env, "42/media/lua/server/ZeD/ZeD_ServerClaims.lua")
    return env
end

local function clientJoin(p)
    local env = baseEnv()
    local c = { env = env, p = p, up = true, notes = {} }
    W.clients[p.name] = c
    env.isServer = function() return false end
    env.isClient = function() return true end
    env.require = function(n) requireIn(env, n) end
    env.getPlayer = function() return p end
    env.getText = function(k, ...)
        local a = { ... }
        return k .. (a[1] and (":" .. tostring(a[1])) or "")
    end
    env.ZeD = {
        tr = function(k, ...)
            local a = { ... }
            return k .. (a[1] and (":" .. tostring(a[1])) or "")
        end,
        logOnce = function(k, m) check("no client error", false, tostring(k) .. ": " .. tostring(m)) end,
        Messages = { invite = function(text) c.notes[#c.notes + 1] = text end },
    }
    c.modals = {}
    env.ISSafehouseUI = { ReceiveSafehouseInvite = function() c.modals[#c.modals + 1] = "safe" end }
    env.ISFactionUI = { ReceiveFactionInvite = function() c.modals[#c.modals + 1] = "fac" end }
    env.Events.ReceiveSafehouseInvite.Add(env.ISSafehouseUI.ReceiveSafehouseInvite)
    env.Events.ReceiveFactionInvite.Add(env.ISFactionUI.ReceiveFactionInvite)
    env.sendClientCommand = function(pl, module, command, args)
        local a = wire(args)
        net(function()
            if W.server then W.server.Events.OnClientCommand.fire(module, command, pl, a) end
        end)
    end
    installGame(env, c, p)
    requireIn(env, "ZeD/ZeD_ClaimProto")
    requireIn(env, "ZeD/ZeD_ServerLink")
    c.C = runFile(env, "42/media/lua/client/ZeD/ZeD_Claims.lua")
    env.Events.OnCreatePlayer.fire(0, p)
    advance(300)
    return c
end

local OPTS = {
    PlayerSafehouse = true, AdminSafehouse = false, SafehouseDaySurvivedToClaim = 5, SafehouseAllowNonResidential = false,
    SafehouseAllowTrepass = false, SafehouseAllowLoot = false, SafehouseAllowFire = false, SafehouseAllowRespawn = true,
    SafeHouseRemovalTime = 72, DisableSafehouseWhenOwnerConnected = false, Faction = true, FactionDaySurvivedToCreate = 3,
    FactionPlayersRequiredForTag = 3, War = true, WarStartDelay = 600, WarDuration = 3600,
}

local function world(noPart)
    W = { clock = 1793913240000, net = {}, logs = {}, online = {}, players = {}, clients = {}, safes = {}, factions = {}, wars = {}, warCalls = {},
        safeN = 0, calls = { canBe = 0, claim = 0 }, opts = {} }
    for k, v in pairs(OPTS) do W.opts[k] = v end
    W.inside = true
    W.squareAt = function(p) return square(p, W.inside) end
    if not noPart then serverStart() end
end

local function logHas(word)
    for _, l in ipairs(W.logs) do
        if l.name == "ZeD" and string.find(l.line, word, 1, true) then return true end
    end
    return false
end
local function has(list, v)
    for _, x in ipairs(list or {}) do if x == v then return true end end
    return false
end

-- ---------------------------------------------------------------------------
-- THE TESTS
-- ---------------------------------------------------------------------------
section("the pure checks")
do
    world()
    local a = player("Aretha")
    local c = clientJoin(a)
    local Cl = c.env.ZeD.Cl
    check("2 is short", Cl.nameProblem("ab", false) == "length")
    check("3 is fine", Cl.nameProblem("abc", false) == nil)
    check("14 is fine", Cl.nameProblem(string.rep("a", 14), false) == nil)
    check("15 is over the game's words", Cl.nameProblem(string.rep("a", 15), false) == "length")
    check("a name taken", Cl.nameProblem("Muldraugh", true) == "exists")
    check("spaces do not count", Cl.nameProblem("  ab  ", false) == "length")
    check("0 is no tag", Cl.tagProblem("", false) == "length")
    check("1 to 4", Cl.tagProblem("A", false) == nil and Cl.tagProblem("ABCD", false) == nil)
    check("5 is long", Cl.tagProblem("ABCDE", false) == "length")
    check("a tag taken", Cl.tagProblem("RVF", true) == "exists")
    check("a title may not be empty", Cl.titleProblem("   ") == "empty")
    check("a title past the limit", Cl.titleProblem(string.rep("x", 31)) == "long")
    check("a tag goes up", Cl.tagText(" rvf ") == "RVF")
    check("reasons split on the game's separator", #Cl.lines("one\r\ntwo\r\n") == 2 and Cl.lines("one\r\ntwo\r\n")[2] == "two")
    check("no reasons", #Cl.lines("") == 0)
    check("control characters leave a name", Cl.name("a\tb") == "ab" and Cl.name("a\nb") == "a b")
    check("hours left", math.abs(Cl.hoursLeft(1000000, 1000000 + 3600000, 72) - 71) < 0.001)
    check("past the limit reads none left", Cl.hoursLeft(0 + 1, 3600000 * 100, 72) == 0)
    check("no option, no count", Cl.hoursLeft(1000, 2000, 0) == nil)
    local d = Cl.warActions("Claimed", "Kade", "Aretha", "Aretha", false)
    check("the defender accepts or refuses", d[1] == "Accepted" and d[2] == "Refused" and #d == 2)
    local at = Cl.warActions("Claimed", "Kade", "Aretha", "Kade", false)
    check("the attacker cancels", at[1] == "Canceled" and #at == 1)
    check("nobody else", #Cl.warActions("Claimed", "Kade", "Aretha", "Rosa", false) == 0)
    check("End needs the power", Cl.warActions("Started", "Kade", "Aretha", "Rosa", true)[1] == "Ended")
    check("a started war has no accept", #Cl.warActions("Started", "Kade", "Aretha", "Aretha", false) == 0)
    check("the game's three countdowns", Cl.warClock("Claimed") == "IGUI_WarManager_TimeToAccept" and Cl.warClock("Accepted") == "IGUI_WarManager_TimeToStart"
        and Cl.warClock("Started") == "IGUI_WarManager_TimeToEnd" and Cl.warClock("Ended") == nil)
    check("a color matches near enough", Cl.sameColor({ r = 0.77, g = 0.31, b = 0.31 }, Cl.COLORS[1]))
    check("eight colors", #Cl.COLORS == 8)
end

section("the rules, from the server's options")
do
    world()
    W.opts.SafehouseDaySurvivedToClaim = 9
    W.opts.DisableSafehouseWhenOwnerConnected = true
    W.opts.SafeHouseRemovalTime = 96
    local c = clientJoin(player("Aretha"))
    advance(1200)
    local r = c.C.rules
    check("the claim day", r.claimDay == 9)
    check("homes only", r.anyBuilding == false)
    check("trespass, loot, fire", r.trespass == false and r.loot == false and r.fire == false)
    check("respawn", r.respawn == true)
    check("removal", r.removal == 96)
    check("protection while the owner is online", r.ownerOff == true)
    local seq = c.C.seq
    W.opts.SafehouseAllowFire = true
    advance(1200)
    check("a changed option is read again", c.C.rules.fire == true and c.C.seq > seq)
end

section("the claim checker")
do
    world()
    local a = player("Aretha")
    local c = clientJoin(a)
    advance(1200)
    local ans = c.C.claimCheck()
    check("yes in a house", ans.ok == true)
    check("yes says where", ans.lines[1] == "UI_ZeD_Cl_ClaimYes:6402 x 5410", ans.lines[1])
    local n = W.calls.canBe
    c.C.claimCheck()
    check("not asked again at once", W.calls.canBe == n)
    a.x = a.x + 3
    c.C.claimCheck()
    check("asked again on a new square", W.calls.canBe == n + 1)
    advance(2100)
    c.C.claimCheck()
    check("and after a while", W.calls.canBe == n + 2)
    W.inside = false
    advance(2100)
    ans = c.C.claimCheck()
    check("outdoors: the game's words, and no call into it", ans.ok == nil and ans.lines[1] == "IGUI_Safehouse_NotInside" and W.calls.canBe == n + 2, ans.lines[1])
    W.inside = true
    a.hours = 24
    advance(2100)
    ans = c.C.claimCheck()
    check("too early: the game's reason", ans.ok == nil and ans.lines[1] == "survive 5", ans.lines[1])
    a.hours = 300
    W.someoneInside, W.notHome = true, true
    advance(2100)
    ans = c.C.claimCheck()
    check("every reason on a line", #ans.lines == 2 and ans.lines[1] == "occupied" and ans.lines[2] == "not house")
    W.someoneInside, W.notHome = nil, nil
    local allowed = false
    W.claimedHere = { getOwner = function() return "Mags_77" end, playerAllowed = function() return allowed end }
    advance(2100)
    ans = c.C.claimCheck()
    check("someone's claim: a stranger is not told whose", ans.lines[1] == "UI_ZeD_Cl_ClaimHeld", ans.lines[1])
    allowed = true
    advance(2100)
    ans = c.C.claimCheck()
    check("someone let in there is", ans.lines[1] == "UI_ZeD_Cl_ClaimTaken:Mags_77", ans.lines[1])
    W.claimedHere = nil
    W.opts.PlayerSafehouse = false
    advance(2100)
    ans = c.C.claimCheck()
    check("no claims at all", ans.lines[1] == "UI_ZeD_Cl_ClaimsOff", ans.lines[1])
    W.opts.AdminSafehouse = true
    advance(2100)
    ans = c.C.claimCheck()
    check("admins only: the game's words", ans.lines[1] == "UI_ServerOption_AdminSafehouse_tooltip", ans.lines[1])
end

section("claim, rename, respawn, members, release")
do
    world()
    local a, b, m = player("Aretha"), player("Rosa"), player("Mags_77")
    local ca, cb, cm = clientJoin(a), clientJoin(b), clientJoin(m)
    advance(1200)
    local got = nil
    check("the claim goes", ca.C.doClaim(function(ok) got = ok end) == true)
    advance(1200)
    check("the game's claim, with the username as its title", W.safes[1] and W.safes[1].title == "Aretha")
    check("the wait reports it", got == true)
    check("my safehouse reads", ca.C.safe and ca.C.safe.owner == "Aretha" and ca.C.safe.isOwner == true and ca.C.safe.manage == true)
    check("one name on it", #ca.C.safe.names == 1)
    local r = nil
    ca.C.rename("Riverside Motel", function(ok) r = ok end)
    advance(1200)
    check("the title saves", W.safes[1].title == "Riverside Motel" and ca.C.safe.title == "Riverside Motel" and r == true)
    ca.C.setRespawn(true)
    advance(1200)
    check("respawn is the game's", W.safes[1].respawn.Aretha == true and ca.C.safe.respawn == true)
    -- the invitation, as a note
    ca.C.invite("safe", "Rosa")
    advance(300)
    check("no modal", #cb.modals == 0)
    check("a note waits", #cb.C.invites == 1 and cb.C.invites[1].kind == "safe" and cb.C.invites[1].host == "Aretha")
    check("the belt has it", cb.notes[1] == "UI_ZeD_Cl_InviteSafe:Aretha", cb.notes[1])
    check("the owner sees it pending", ca.C.sent.safe.Rosa ~= nil)
    ca.C.invite("safe", "Rosa")
    advance(300)
    check("the same host once", #cb.C.invites == 1)
    local j = nil
    cb.C.answer(cb.C.invites[1], true, function(ok) j = ok end)
    advance(1200)
    check("accepted", has(W.safes[1].players, "Rosa") and j == true)
    check("the note goes", #cb.C.invites == 0)
    check("she reads the safehouse", cb.C.safe and cb.C.safe.isOwner == false and cb.C.safe.manage == false)
    check("off the pending list when in", ca.C.sent.safe.Rosa == nil)
    check("two names", #ca.C.safe.names == 2 and ca.C.safe.names[1] == "Aretha")
    -- declined
    ca.C.invite("safe", "Mags_77")
    advance(300)
    cm.C.answer(cm.C.invites[1], false)
    advance(1200)
    check("declined: not in", not has(W.safes[1].players, "Mags_77") and W.safes[1].invites.Mags_77 == nil)
    check("the note goes", #cm.C.invites == 0)
    -- owner
    local own = nil
    ca.C.changeOwner("safe", "Rosa", function(ok) own = ok end)
    advance(1200)
    check("change owner", W.safes[1].owner == "Rosa" and own == true)
    check("the old owner stays a member", has(W.safes[1].players, "Aretha") and ca.C.safe and ca.C.safe.isOwner == false)
    cb.C.changeOwner("safe", "Aretha")
    advance(1200)
    -- remove
    ca.C.invite("safe", "Mags_77")
    advance(300)
    cm.C.answer(cm.C.invites[1], true)
    advance(1200)
    local rem = nil
    ca.C.remove("safe", "Mags_77", function(ok) rem = ok end)
    advance(1200)
    check("removed", not has(W.safes[1].players, "Mags_77") and rem == true)
    -- quit, then release
    local q = nil
    cb.C.quit(cb.C.safe, function(ok) q = ok end)
    advance(1200)
    check("quit", not has(W.safes[1].players, "Rosa") and q == true and cb.C.safe == nil)
    local rel = nil
    ca.C.release(ca.C.safe, function(ok) rel = ok end)
    advance(1200)
    check("released", #W.safes == 0 and rel == true and ca.C.safe == nil)
    check("nothing refused", ca.refused == nil and cb.refused == nil and cm.refused == nil, ca.refused and ca.refused[1])
end

section("a call the game refuses reports it")
do
    world()
    local a = player("Aretha")
    local c = clientJoin(a)
    newFaction("Muldraugh Mall", "Mags")
    advance(1200)
    local r = nil
    c.C.createFaction("Muldraugh Mall", function(ok) r = ok end)
    advance(9500)
    check("no faction appears: false, in time", r == false)
    check("the game refused it", c.refused and c.refused[1] == "faction is already exists")
end

section("faction: create, tag, color, invites, owner, leave, disband")
do
    world()
    local a, k, m = player("Aretha"), player("Kade_R"), player("Mags_77")
    local ca, ck, cm = clientJoin(a), clientJoin(k), clientJoin(m)
    advance(1200)
    local r = nil
    ca.C.createFaction("Riverside", function(ok) r = ok end)
    advance(1200)
    check("created", W.factions[1] and W.factions[1].owner == "Aretha" and r == true)
    check("I read it", ca.C.fac and ca.C.fac.isOwner == true and ca.C.fac.manage == true)
    check("no tag yet: too few", ca.C.fac.canTag == false and ca.C.fac.hasRoom == false)
    ca.C.invite("fac", "Kade_R")
    advance(300)
    check("no modal", #ck.modals == 0)
    check("a note, with the faction's name", #ck.C.invites == 1 and ck.C.invites[1].name == "Riverside")
    check("the belt's words", ck.notes[1] == "UI_ZeD_Cl_InviteFaction:Aretha", ck.notes[1])
    ck.C.answer(ck.C.invites[1], true)
    ca.C.invite("fac", "Mags_77")
    advance(300)
    cm.C.answer(cm.C.invites[1], true)
    advance(1200)
    check("three in", #W.factions[1].players == 2 and #ca.C.fac.names == 3 and ca.C.fac.names[1] == "Aretha")
    check("the tag opens", ca.C.fac.canTag == true)
    check("a member cannot tag", ck.C.fac.canTag == false and ck.C.fac.manage == false)
    local t = nil
    ca.C.setTag("RVF", function(ok) t = ok end)
    advance(1200)
    check("tag set", W.factions[1].tag == "RVF" and t == true)
    check("a taken tag reads as taken", ca.C.tagTaken("RVF") == true and ca.C.tagTaken("rvf") == false)
    ca.C.setColor(ca.env.ZeD.Cl.COLORS[4])
    advance(1200)
    check("the color is a ColorInfo", math.abs(W.factions[1].color:getG() - 0.604) < 0.01)
    check("read back", ca.env.ZeD.Cl.sameColor(ca.C.fac.color, ca.env.ZeD.Cl.COLORS[4]))
    ca.C.showTag(false)
    ca.C.factionPvp(true)
    advance(1200)
    check("the ticks are the player's", a.showTag == false and a.pvp == true and k.pvp == false)
    check("read back", ca.C.fac.showTag == false and ca.C.fac.pvp == true)
    local nm = nil
    ca.C.renameFaction("Riverfolk", function(ok) nm = ok end)
    advance(1200)
    check("renamed", W.factions[1].name == "Riverfolk" and nm == true)
    local o = nil
    ca.C.changeOwner("fac", "Kade_R", function(ok) o = ok end)
    advance(1200)
    check("change owner", W.factions[1].owner == "Kade_R" and o == true)
    check("the old owner is a member", W.factions[1]:isMember("Aretha") and ca.C.fac.isOwner == false)
    ck.C.remove("fac", "Mags_77")
    advance(1200)
    check("removed", not W.factions[1]:isMember("Mags_77") and cm.C.fac == nil)
    local l = nil
    ca.C.leave(function(ok) l = ok end)
    advance(1200)
    check("left", not W.factions[1]:isMember("Aretha") and l == true)
    local d = nil
    ck.C.disband(function(ok) d = ok end)
    advance(1200)
    check("disbanded", #W.factions == 0 and d == true and ck.C.fac == nil)
    check("nothing refused", ca.refused == nil and ck.refused == nil, ca.refused and ca.refused[1])
end

section("an invitation is never lost, and goes when it can't be answered")
do
    world()
    local a, b = player("Aretha"), player("Rosa")
    local ca, cb = clientJoin(a), clientJoin(b)
    local s = newSafe(100, 100, 10, 10, "Aretha")
    local f = newFaction("Riverside", "Aretha")
    advance(1200)
    ca.C.invite("safe", "Rosa")
    ca.C.invite("fac", "Rosa")
    advance(300)
    check("both wait", #cb.C.invites == 2)
    check("across a second's work", (function() advance(3000); return #cb.C.invites == 2 end)())
    -- ZeD's handler failing hands it to the game's modal
    local add = cb.C.addInvite
    local logged = cb.env.ZeD.logOnce
    cb.env.ZeD.logOnce = function() end
    cb.C.addInvite = function() error("boom") end
    cb.env.Events.ReceiveFactionInvite.fire(f, "Other", "Rosa")
    cb.C.addInvite = add
    cb.env.ZeD.logOnce = logged
    check("a failure falls to the game's modal", cb.modals[1] == "fac")
    -- the safehouse goes
    ca.C.release(ca.C.safe)
    advance(1200)
    check("a released safehouse takes its note", #cb.C.invites == 1 and cb.C.invites[1].kind == "fac")
    W.factions = {}
    advance(1200)
    check("a disbanded faction takes its note", #cb.C.invites == 0)
    -- already in one: as the game's handler
    local s2 = newSafe(200, 200, 10, 10, "Rosa")
    advance(1200)
    cb.env.Events.ReceiveSafehouseInvite.fire(s, "Aretha", "Rosa")
    check("someone with a safehouse gets no note", #cb.C.invites == 0 and #cb.modals == 1)
    check("the game's two handlers are off the events", (function()
        local env = cb.env
        for _, fn in ipairs(env.Events.ReceiveFactionInvite.list) do
            if fn == env.ISFactionUI.ReceiveFactionInvite then return false end
        end
        return true
    end)())
end

section("without the server part")
do
    world(true)
    local a, b = player("Aretha"), player("Rosa")
    local ca, cb = clientJoin(a), clientJoin(b)
    advance(42000)
    check("no server part", ca.env.ZeD.ServerPart.present == false)
    check("everything local still works: the claim", ca.C.doClaim(function() end) == true)
    advance(1200)
    check("claimed", ca.C.safe ~= nil)
    ca.C.invite("safe", "Rosa")
    advance(300)
    check("the invitation arrives", #cb.C.invites == 1)
    cb.C.answer(cb.C.invites[1], true)
    advance(1200)
    check("accepted", cb.C.safe ~= nil)
    check("no time left to show", ca.C.info.safe == nil)
    check("no take-back", ca.C.hasPart() == false)
    local r = nil
    ca.C.createFaction("Riverside", function(ok) r = ok end)
    advance(1200)
    check("a faction too", r == true)
end

section("the server part: what it tells a player")
do
    world()
    local a, b, c3 = player("Aretha"), player("Rosa"), player("Mags_77")
    local ca, cb = clientJoin(a), clientJoin(b)
    local s = newSafe(100, 100, 10, 10, "Aretha")
    local f = newFaction("Riverside", "Aretha")
    advance(1200)
    check("the link is up", ca.env.ZeD.ServerPart.available())
    s.visited = W.clock - 61 * 3600000
    ca.C.invite("safe", "Rosa")
    ca.C.invite("fac", "Rosa")
    advance(7000)
    check("last visited, as hours ago", ca.C.info.safe and math.abs(ca.C.info.safe.visitedH - 61) < 0.1, ca.C.info.safe and ca.C.info.safe.visitedH)
    check("who is waiting", ca.C.sent.safe.Rosa ~= nil and ca.C.sent.fac.Rosa ~= nil)
    -- a view holds nothing else
    local seen = {}
    local base = ca.env.Events.OnServerCommand
    base.Add(function(m, cmd, args) if m == "ZeDC" then seen[#seen + 1] = { cmd = cmd, args = args } end end)
    advance(6000)
    ca.C.ask()
    advance(300)
    local rep = seen[#seen] and seen[#seen].args or {}
    check("the reply is c_info", seen[#seen] and seen[#seen].cmd == "c_info")
    check("c_info holds an allowlist", (function()
        for k in pairs(rep) do
            if k ~= "safe" and k ~= "fac" and k ~= "invites" and k ~= "rid" then return false end
        end
        for k in pairs(rep.invites or {}) do
            if type(k) ~= "number" and k ~= "n" and k ~= "live" then return false end
        end
        for k in pairs(rep.safe or {}) do
            if k ~= "visitedH" and k ~= "invited" then return false end
        end
        return true
    end)())
    -- recovery: a client that joined after the invitation
    local c2 = clientJoin(c3)
    advance(300)
    newSafe(300, 300, 10, 10, "Kade")
    W.safes[#W.safes].invites["Mags_77"] = true
    advance(6000)
    c2.C.ask()
    advance(300)
    check("an invitation the client never heard of is raised", #c2.C.invites == 1 and c2.C.invites[1].host == "Kade", #c2.C.invites)
    check("the note says so", c2.notes[1] ~= nil)
    c2.C.answer(c2.C.invites[1], false)
    advance(6000)
    W.safes[#W.safes].invites["Mags_77"] = true
    c2.C.ask()
    advance(300)
    check("a declined one does not come back", #c2.C.invites == 0)
    -- cancel
    local ans = nil
    ca.C.cancelInvite("safe", "Rosa", function(x) ans = x end)
    advance(300)
    check("taken back", s.invites.Rosa == nil and ans and ans.ok == true)
    check("and off the list", ca.C.sent.safe.Rosa == nil)
    check("a line in the log", logHas("safehouse | invite cancelled | Aretha | Rosa |"))
    -- not the owner
    s.players[#s.players + 1] = "Rosa"
    advance(1200)
    ans = nil
    W.clients.Rosa.C.cancelInvite("safe", "Aretha", function(x) ans = x end)
    advance(300)
    check("a member cannot take one back", ans and ans.ok == false and ans.err == "perm", ans and ans.err)
    -- hostile
    local function raw(pl, cmd, args) W.server.Events.OnClientCommand.fire("ZeDC", cmd, pl, args) end
    advance(1200)
    raw(a, "c_cancel", { kind = "nope", who = "x" })
    advance(1200)
    raw(a, "c_cancel", { kind = "safe", who = 12 })
    advance(1200)
    raw(a, "c_cancel", { kind = "safe", who = string.rep("x", 500) })
    advance(1200)
    raw(a, "c_cancel", nil)
    advance(1200)
    raw(a, "c_info", nil)
    advance(1200)
    check("nothing failed", not logHas("handler failed"))
    check("a bad-argument line", logHas("bad arguments | Aretha | - | - | c_cancel"))
    -- the limit
    advance(6000)
    ca.C.ask()
    advance(100)
    seen = {}
    ca.C.ask()
    advance(100)
    check("c_info answers wait inside its limit", seen[1] and seen[1].cmd == "c_ack" and seen[1].args.err == "wait")
    -- a stray refusal is not taken for the answer to a Cancel
    ans = nil
    ca.C.ackRid = (ca.C.ackRid or 0) + 1
    ca.C.ackFn = function(x) ans = x end
    ca.C.ask()
    advance(100)
    check("an ack for something else is left alone", ans == nil)
    ca.C.ackFn = nil
    -- no message reaches anyone else
    local leaks = 0
    cb.env.Events.OnServerCommand.Add(function(m, cmd) if m == "ZeDC" and cmd == "c_info" then leaks = leaks + 1 end end)
    advance(6000)
    ca.C.ask()
    advance(300)
    check("one player's answer goes to them", leaks == 0)
end

section("the log: from the game's lists, whoever did it")
do
    world()
    newSafe(100, 100, 10, 10, "Old")
    local a = player("Aretha")
    local c = clientJoin(a)
    advance(6000)
    check("nothing written for what was there at the start", not logHas("safehouse | claim | Old"))
    W.logs = {}
    c.C.doClaim(function() end)
    advance(6000)
    check("a claim", logHas("safehouse | claim | Aretha |"))
    check("who, where and the day", logHas("| day 12"))
    c.C.rename("Riverside\nMotel\tfake | line")
    advance(6000)
    check("a title: one line", (function()
        for _, l in ipairs(W.logs) do
            if string.find(l.line, "title", 1, true) then return not string.find(l.line, "\n", 1, true) end
        end
        return false
    end)())
    W.safes[#W.safes].players[#W.safes[#W.safes].players + 1] = "Rosa"
    advance(6000)
    check("a member in", logHas("safehouse | member in | Rosa"))
    W.safes[#W.safes].owner = "Rosa"
    advance(6000)
    check("an owner", logHas("safehouse | owner from Aretha | Rosa"))
    c.C.createFaction("Riverside", function() end)
    advance(6000)
    check("a faction", logHas("faction | create | Aretha | Riverside"))
    W.factions[1].name = "Riverfolk"
    advance(6000)
    check("a rename is one line", logHas("faction | name from Riverside | Aretha | Riverfolk") and not logHas("faction | disband"))
    W.factions[1].tag = "RVF"
    advance(6000)
    check("a tag", logHas("faction | tag RVF"))
    W.factions = {}
    advance(6000)
    check("a disband", logHas("faction | disband | Aretha | Riverfolk"))
    local s = W.safes[#W.safes]
    table.remove(W.safes)
    advance(6000)
    check("a release, or the game's own expiry", logHas("safehouse | release"))
    -- a flood stops at the page
    for i = 1, 100 do newSafe(1000 + i * 20, 1000, 10, 10, "p" .. i) end
    W.logs = {}
    advance(6000)
    local n = 0
    for _, l in ipairs(W.logs) do if string.find(l.line, "safehouse | claim", 1, true) then n = n + 1 end end
    check("one pass writes at most its lines", n == 40, n)
    -- once a pass, not once a tick
    W.logs = {}
    advance(1000)
    check("quiet between passes", #W.logs == 0)
end

section("wars")
do
    world()
    local a, k, adm = player("Aretha"), player("Kade_R"), player("Hermit", "admin")
    local ca, ck, cadm = clientJoin(a), clientJoin(k), clientJoin(adm)
    local s = newSafe(100, 100, 10, 10, "Aretha")
    s.title = "Riverside Motel"
    local w = newWar(s, "Kade_R", "Claimed", "00:09:00")
    advance(1200)
    check("the defender reads it", #ca.C.wars == 1 and ca.C.wars[1].title == "Riverside Motel" and ca.C.wars[1].state == "Claimed" and ca.C.wars[1].defender == "Aretha")
    check("the countdown", ca.C.wars[1].time == "00:09:00")
    check("the attacker reads it", #ck.C.wars == 1)
    check("admins read every war", #cadm.C.wars == 1)
    local other = player("Rosa")
    local cr = clientJoin(other)
    advance(1200)
    check("nobody else", #cr.C.wars == 0)
    ca.C.war(ca.C.wars[1], "Accepted")
    check("the game's call: id, attacker, state", W.warCalls[1].id == s.onlineId and W.warCalls[1].attacker == "Kade_R" and W.warCalls[1].state == "Accepted")
    advance(1200)
    check("it moved on", ca.C.wars[1].state == "Accepted")
    local seq = ca.C.seq
    w.time = "00:08:59"
    advance(1200)
    check("the time bumps the card", ca.C.seq > seq)
    cadm.C.war(cadm.C.wars[1], "Ended")
    check("End", W.warCalls[2].state == "Ended")
end

section("the review: a host's name is a client's word")
do
    world()
    local a, b = player("Aretha"), player("Rosa")
    local ca, cb = clientJoin(a), clientJoin(b)
    local f = newFaction("Riverside", "Aretha")
    advance(1200)
    for i = 1, 30 do cb.env.Events.ReceiveFactionInvite.fire(f, "Admin_" .. i, "Rosa") end
    check("one faction, one note, whatever names it sends", #cb.C.invites == 1 and #cb.notes == 1, #cb.C.invites)
    check("the note says who owns it", cb.C.invites[1].host == "Aretha", cb.C.invites[1].host)
    cb.env.Events.ReceiveFactionInvite.fire(f, string.rep("x", 60000), "Rosa")
    check("and no text of the sender's reaches it", #cb.C.inviteText(cb.C.invites[1]) < 200)
    cb.C.answer(cb.C.invites[1], false)
    cb.env.Events.ReceiveFactionInvite.fire(f, "Aretha", "Rosa")
    check("declined, then asked again: a note again", #cb.C.invites == 1)
    cb.C.invites = {}
    f.name = string.rep("n", 60000)
    cb.env.Events.ReceiveFactionInvite.fire(f, "Aretha", "Rosa")
    check("a faction's name is cut too (the game's rename does not test it)", #cb.C.invites[1].name <= 64, #cb.C.invites[1].name)
    f.name = "Riverside"
    cb.C.invites = {}
    for i = 1, 14 do
        local g = newFaction("Spam" .. i, "Own" .. i)
        cb.env.Events.ReceiveFactionInvite.fire(g, "x", "Rosa")
    end
    check("the list has a cap, the oldest goes", #cb.C.invites == 10 and cb.C.invites[10].name == "Spam14" and cb.C.invites[1].name == "Spam5", #cb.C.invites)
end

section("the review: one house, one note, and it goes when the host takes it back")
do
    world()
    local bob, adm, cara = player("Bob"), player("Adm", "admin"), player("Cara")
    local cbob, cadm, cc = clientJoin(bob), clientJoin(adm), clientJoin(cara)
    local s = newSafe(100, 100, 10, 10, "Bob")
    s.players[#s.players + 1] = "Adm"
    advance(1200)
    check("staff, a member, may invite", cadm.C.safe and cadm.C.safe.manage == true)
    cadm.C.invite("safe", "Cara")
    advance(300)
    check("a note from staff, naming the owner", #cc.C.invites == 1 and cc.C.invites[1].host == "Bob")
    advance(6000)
    cc.C.ask()
    advance(300)
    check("the server's list adds no second note", #cc.C.invites == 1, #cc.C.invites)
    -- the host takes it back, and the note stays a poll at most
    local ans = nil
    cbob.C.sent.safe.Cara = W.clock
    cbob.C.cancelInvite("safe", "Cara", function(x) ans = x end)
    advance(300)
    check("taken back", s.invites.Cara == nil and ans and ans.ok == true)
    advance(7000)
    cc.C.ask()
    advance(300)
    check("the note goes at the next answer", #cc.C.invites == 0, #cc.C.invites)
    check("nobody was refused", cc.refused == nil and cbob.refused == nil and cadm.refused == nil, cbob.refused and cbob.refused[1])
    -- a note newer than the answer stays
    cadm.C.invite("safe", "Cara")
    advance(300)
    s.invites.Cara = nil
    advance(5500)
    cc.C.ask()
    advance(300)
    s.invites.Cara = true
    check("not yet settled: a note a moment old stays", #cc.C.invites == 1)
    -- if Lua cannot read invitations the server says so, and nothing is taken away
    advance(6000)
    local read = s.hasInvite
    s.hasInvite = nil
    cc.C.ask()
    advance(300)
    s.hasInvite = read
    check("no sight of them: the note stays", #cc.C.invites == 1)
end

section("the review: Cancel on a name not invited writes no line")
do
    world()
    local a = player("Aretha")
    local c = clientJoin(a)
    newSafe(100, 100, 10, 10, "Aretha")
    advance(1200)
    c.C.sent.safe.an_admin = W.clock
    W.logs = {}
    local ans = nil
    c.C.cancelInvite("safe", "an_admin", function(x) ans = x end)
    advance(300)
    check("said no", ans and ans.ok == false and ans.err == "gone", ans and ans.err)
    check("no false line", not logHas("invite cancelled"))
    check("the row goes: there was nothing to wait for", c.C.sent.safe.an_admin == nil)
end

section("the review: the log")
do
    world()
    local a = player("Aretha")
    local c = clientJoin(a)
    local s = newSafe(100, 100, 10, 10, "Aretha")
    local f1 = newFaction("Riverside", "Rosa")
    local f2 = newFaction("Other", "Hostile")
    advance(6000)
    W.logs = {}
    s.title = "x | release | Admin | 1,1 | day 1"
    advance(6000)
    local fields = 0
    for _, l in ipairs(W.logs) do
        if string.find(l.line, "safehouse | title", 1, true) then
            local _, n = string.gsub(l.line, " | ", "")
            fields = n
        end
    end
    check("a title cannot pass for fields", fields == 6, fields)
    W.logs = {}
    f2.name = "Riverside"
    advance(6000)
    check("a stolen name is a rename, of the one who did it", logHas("faction | name from Other | Hostile | Riverside"))
    check("and no takeover of the other", not logHas("owner from Rosa") and not logHas("member in") and not logHas("member out"))
    W.logs = {}
    for i = #W.factions, 1, -1 do if W.factions[i] == f2 then table.remove(W.factions, i) end end
    newFaction("Bravo", "Hostile")
    advance(6000)
    check("a disband and a create are two lines", logHas("faction | disband | Hostile") and logHas("faction | create | Hostile | Bravo"))
    check("not a rename", not logHas("name from"))
    for i = 1, 45 do newSafe(1000 + i * 20, 1000, 10, 10, "p" .. i) end
    W.logs = {}
    advance(6000)
    check("past the page it says how many went unwritten", logHas("claims | 5 changes not logged"))
end

section("the review: a house at a time, for staff with two")
do
    world()
    local adm = player("Hermit", "admin")
    local c = clientJoin(adm)
    local s1 = newSafe(100, 100, 10, 10, "Hermit")
    local s2 = newSafe(200, 200, 10, 10, "Hermit")
    advance(1200)
    check("the first reads", c.C.safe.id == s1.id)
    local r = nil
    c.C.release(c.C.safe, function(ok) r = ok end)
    advance(1200)
    check("it goes, and that is what done means", r == true and #W.safes == 1 and W.safes[1] == s2)
    check("the other is left", c.C.safe.id == s2.id)
    -- quit, with a house still held
    local s3 = newSafe(300, 300, 10, 10, "Rosa")
    s3.players[#s3.players + 1] = "Hermit"
    table.remove(W.safes, 1)
    W.safes[#W.safes + 1] = s2
    advance(1200)
    check("now in Rosa's first", c.C.safe.id == s3.id)
    local q = nil
    c.C.quit(c.C.safe, function(ok) q = ok end)
    advance(1200)
    check("quit is done when off that house", q == true and c.C.safe.id == s2.id)
end

section("the review: a tag the server refuses is not saved")
do
    world()
    local adm = player("Hermit", "admin")
    local c = clientJoin(adm)
    local f = newFaction("Small", "Hermit")
    advance(1200)
    check("too few members: no field, even for FactionCheat", c.C.fac.canTag == false and c.C.fac.hasRoom == false)
    local got = nil
    c.C.setTag("AB", function(ok) got = ok end)
    advance(9500)
    check("the server refused", c.refused and c.refused[1] == "no enough players")
    check("said so", got == false)
    check("this client holds what the server does", f.tag == nil and c.C.fac.tag == nil, f.tag)
    W.opts.FactionPlayersRequiredForTag = 1
    advance(1200)
    got = nil
    c.C.setTag("AB", function(ok) got = ok end)
    advance(1200)
    check("taken, it arrives by the server's sync", f.tag == "AB" and c.C.fac.tag == "AB" and got == true)
    local Cl = c.env.ZeD.Cl
    got = nil
    c.C.setColor(Cl.COLORS[2], function(ok) got = ok end)
    check("a color waits for the server too", c.C.fac.color == nil or not Cl.sameColor(c.C.fac.color, Cl.COLORS[2]))
    advance(1200)
    check("then shows", Cl.sameColor(c.C.fac.color, Cl.COLORS[2]) and got == true)
    -- staff who are not the owner: the tag exists, so the game refuses a color
    f.owner, f.players = "Rosa", { "Hermit" }
    advance(1200)
    got = nil
    c.refused = nil
    c.C.setColor(Cl.COLORS[3], function(ok) got = ok end)
    advance(9500)
    check("refused: told, and the color stands", got == false and Cl.sameColor(c.C.fac.color, Cl.COLORS[2]), tostring(got))
end

section("the review: invited, waiting has an end")
do
    world(true)
    local a, b = player("Aretha"), player("Rosa")
    local ca, cb = clientJoin(a), clientJoin(b)
    newSafe(100, 100, 10, 10, "Aretha")
    advance(1200)
    ca.C.invite("safe", "Rosa")
    advance(300)
    cb.C.answer(cb.C.invites[1], false)
    advance(44000)
    check("the game tells the host nothing", ca.C.sent.safe.Rosa ~= nil)
    check("no server's word for it", not ca.C.sentSure.safe)
    advance(260000)
    check("it ends by itself", ca.C.sent.safe.Rosa == nil)
end
do
    world()
    local a, b = player("Aretha"), player("Rosa")
    local ca, cb = clientJoin(a), clientJoin(b)
    newSafe(100, 100, 10, 10, "Aretha")
    advance(1200)
    ca.C.invite("safe", "Rosa")
    ca.C.askSoon()
    advance(7000)
    check("the server's list is heard", ca.C.sentSure.safe == true and ca.C.sent.safe.Rosa ~= nil)
    advance(330000)
    check("it keeps a name past the time, while it holds one", ca.C.sent.safe.Rosa ~= nil)
    cb.C.answer(cb.C.invites[1], false)
    advance(40000)
    check("and lets it go the moment it does not", ca.C.sent.safe.Rosa == nil)
end

section("the review: the belt keeps the newest invitations, and nothing else goes")
do
    world()
    local env = baseEnv()
    env.require = function() end
    env.ZeD = { tr = function(k, a) return k .. (a ~= nil and (":" .. tostring(a)) or "") end }
    env.getGameTime = function() return nil end
    env.getText = function(k) return k end
    runFile(env, "42/media/lua/client/ZeD/ZeD_Messages.lua")
    local M = env.ZeD.Messages
    local name = "UI_ZeD_Char_TabServer"
    M.add(name, "mods", { k = "note", text = "keep me" })
    for i = 1, 25 do M.invite("invitation " .. i) end
    local items = M.sources[name].items
    local n, kept = 0, false
    for _, it in ipairs(items) do
        if it.k == "invite" then n = n + 1 end
        if it.text == "keep me" then kept = true end
    end
    check("ten invitation notes at most", n == 10, n)
    check("the newest stays", items[1].text == "invitation 25", items[1].text)
    check("another mod's note is not touched", kept)
end

print("claims_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
