-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Claims.lua
-- ============================================================================
-- SAFEHOUSES AND FACTIONS, THE CLIENT'S MODEL (ZeDUI/MP_ADMIN_SCOPE.md, Phase 3). No drawing: ZeD_ClaimCards.lua reads
-- this and calls it. Every act goes through the game's own global (sendSafehouseClaim, sendFactionCreate ...), exactly as
-- its windows call them; its server checks them all, so this works on a server without ZeD's server part. The server
-- part only adds what a client cannot learn (ZeD_ServerClaims.lua).
--
-- Once a second the game's objects are read into plain tables here (C.safe, C.fac, C.wars, C.rules), and C.seq bumps
-- if anything changed. The cards draw those tables and never touch a Java object in a frame.
--
-- The game's two invitation modals are taken off their events and an invitation waits in C.invites, as a note in the
-- Server tab. The game has no answer to most calls: C.expect watches for the change to arrive and reports if it does not.
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ClaimProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/Tr"
require "ZeD/ZeD_Messages"
require "ISUI/UserPanel/ISSafehouseUI"
require "ISUI/UserPanel/ISFactionUI"

ZeD = ZeD or {}
ZeD.Claims = ZeD.Claims or {}
local C = ZeD.Claims
local S = ZeD.ServerPart
local Cl = ZeD.Cl

local REFRESH_MS = 1000       -- the game's objects read this often
local CHECK_MS = 2000         -- "Can I claim this?" asked this often while it shows; the game's check walks the cell's objects
local INFO_MS = 30000         -- the server part asked this often while the link is up
local INFO_SOON_MS = 6000     -- after a change, this soon (its limit is 5 s)
local EXPECT_MS = 8000        -- the game gives no answer: past this, what was asked has not happened

C.seq = C.seq or 0            -- bumps when anything below changes
C.invites = C.invites or {}   -- invitations waiting: { kind = "safe" | "fac", obj, host, user, name }
C.sent = C.sent or { safe = {}, fac = {} }   -- who I invited and has not answered: name -> when
C.info = C.info or {}         -- what the server part last said
C.declined = C.declined or {} -- invitations answered this session, so a late c_info does not raise them again

local waits = {}              -- what the game has been asked and has not shown yet
local doneTick = 0

local function now() return getTimestampMs() end
local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end

function C.bump() C.seq = C.seq + 1 end

function C.player() return getPlayer() end

function C.me()
    local p = getPlayer()
    return p and p:getUsername() or ""
end

function C.cap(name)
    if C.qaCaps then return C.qaCaps[name] == true end
    local p = getPlayer()
    local c = Capability and Capability[name]
    if not (p and c) then return false end
    local ok, r = pcall(function() return p:getRole():hasCapability(c) end)
    return ok and r == true
end

-- ---------------------------------------------------------------------------
-- THE SERVER'S RULES, from its own options (getServerOptions() on a client holds what the server sent at connect)
-- ---------------------------------------------------------------------------
function C.readRules()
    local so = getServerOptions and getServerOptions()
    local function b(k) return safe(function() return so:getBoolean(k) end, false) == true end
    local function i(k) return safe(function() return so:getInteger(k) end, 0) end
    return {
        player = b("PlayerSafehouse"), admin = b("AdminSafehouse"), claimDay = i("SafehouseDaySurvivedToClaim"),
        anyBuilding = b("SafehouseAllowNonResidential"), trespass = b("SafehouseAllowTrepass"), loot = b("SafehouseAllowLoot"),
        fire = b("SafehouseAllowFire"), respawn = b("SafehouseAllowRespawn"), removal = i("SafeHouseRemovalTime"),
        ownerOff = b("DisableSafehouseWhenOwnerConnected"),
        faction = b("Faction"), factionDay = i("FactionDaySurvivedToCreate"), tagNeeds = i("FactionPlayersRequiredForTag"),
        war = b("War"), warDelay = i("WarStartDelay"), warLength = i("WarDuration"),
    }
end

-- ---------------------------------------------------------------------------
-- READING THE GAME
-- ---------------------------------------------------------------------------
-- the owner first, then each name once, sorted. The game's safehouse keeps the owner on its list, and its faction apart.
function C.names(owner, list)
    local seen, out = {}, {}
    if owner and owner ~= "" then seen[owner] = true end
    if list then
        for i = 0, list:size() - 1 do
            local u = tostring(list:get(i))
            if not seen[u] then seen[u] = true; out[#out + 1] = u end
        end
    end
    table.sort(out, function(a, b) return string.lower(a) < string.lower(b) end)
    if owner and owner ~= "" then table.insert(out, 1, owner) end
    return out
end

function C.readSafe(p)
    local h = SafeHouse.hasSafehouse(p)
    if not h then return nil end
    local me = p:getUsername()
    local owner = h:getOwner()
    local mine = h:isOwner(p)
    return {
        obj = h, id = h:getId(), title = h:getTitle() or "", owner = owner, x = h:getX(), y = h:getY(),
        location = safe(function() return h:getLocation() end, nil),
        created = safe(function() return h:getDatetimeCreatedStr() end, nil),
        respawn = h:isRespawnInSafehouse(me), isOwner = mine, manage = mine or C.cap("CanSetupSafehouses"),
        names = C.names(owner, h:getPlayers()),
    }
end

function C.readFaction(p)
    local f = Faction.getPlayerFaction(p)
    if not f then return nil end
    local me = p:getUsername()
    local owner = f:getOwner()
    local mine = f:isOwner(me)
    local cheat = C.cap("FactionCheat")
    local col = f:getTagColor()
    return {
        obj = f, name = f:getName() or "", tag = f:getTag(), owner = owner, isOwner = mine, manage = mine or cheat,
        canTag = (mine or cheat) and (f:canCreateTag() or cheat), hasRoom = f:canCreateTag(),
        color = col and { r = col:getR(), g = col:getG(), b = col:getB() } or nil,
        names = C.names(owner, f:getPlayers()),
        showTag = p:isShowTag(), pvp = p:isFactionPvp(),
    }
end

function C.readWars(p)
    local out = {}
    local list = getWars()
    if not list then return out end
    -- (a shared list the game clears on its next call: copied at once)
    for i = 0, list:size() - 1 do
        local w = list:get(i)
        out[#out + 1] = { id = w:getOnlineID(), attacker = w:getAttacker(), defender = w:getDefender(),
            state = w:getState():name(), time = w:getTime() }
    end
    local all = SafeHouse.getSafehouseList()
    for _, r in ipairs(out) do
        -- (SafeHouse.getSafeHouse has a String overload beside the int one: found by walking the list instead)
        for i = 0, all:size() - 1 do
            local h = all:get(i)
            if h:getOnlineID() == r.id then r.title = h:getTitle(); break end
        end
    end
    return out
end

local function sigList(t) return table.concat(t or {}, ",") end

function C.signature()
    local parts = {}
    local h, f, r = C.safe, C.fac, C.rules
    if h then
        parts[#parts + 1] = table.concat({ "s", tostring(h.title), tostring(h.owner), tostring(h.respawn), tostring(h.manage), sigList(h.names) }, "|")
    end
    if f then
        local c = f.color
        parts[#parts + 1] = table.concat({ "f", tostring(f.name), tostring(f.tag), tostring(f.owner), tostring(f.showTag), tostring(f.pvp), tostring(f.canTag),
            tostring(f.manage), c and (tostring(c.r) .. tostring(c.g) .. tostring(c.b)) or "", sigList(f.names) }, "|")
    end
    if r then
        parts[#parts + 1] = table.concat({ tostring(r.player), tostring(r.admin), tostring(r.claimDay), tostring(r.anyBuilding), tostring(r.trespass),
            tostring(r.loot), tostring(r.fire), tostring(r.respawn), tostring(r.removal), tostring(r.ownerOff), tostring(r.faction), tostring(r.factionDay),
            tostring(r.tagNeeds), tostring(r.war) }, "|")
    end
    for _, w in ipairs(C.wars or {}) do
        parts[#parts + 1] = table.concat({ tostring(w.id), tostring(w.attacker), tostring(w.state), tostring(w.time) }, "|")
    end
    for _, i in ipairs(C.invites) do parts[#parts + 1] = i.kind .. tostring(i.host) end
    for _, kind in ipairs({ "safe", "fac" }) do
        for n in pairs(C.sent[kind]) do parts[#parts + 1] = kind .. n end
    end
    return table.concat(parts, ";")
end

-- ---------------------------------------------------------------------------
-- A SECOND'S WORK
-- ---------------------------------------------------------------------------
function C.refresh()
    local p = getPlayer()
    if not p then return end
    C.rules = C.readRules()
    C.safe = safe(function() return C.readSafe(p) end, nil)
    C.fac = safe(function() return C.readFaction(p) end, nil)
    C.wars = safe(function() return C.readWars(p) end, {})
    C.prune()
    local sig = C.signature()
    if sig ~= C.sig then
        C.sig = sig
        C.bump()
    end
end

-- invitations that can no longer be answered go; those I sent are done when the player is in
function C.prune()
    local kept = {}
    for _, i in ipairs(C.invites) do
        local good = false
        if i.kind == "safe" then
            good = not C.safe and safe(function() return SafeHouse.getSafehouseList():contains(i.obj) end, false)
        else
            good = not C.fac and safe(function() return Faction.getFactions():contains(i.obj) end, false)
        end
        if good then kept[#kept + 1] = i end
    end
    C.invites = kept
    for _, kind in ipairs({ "safe", "fac" }) do
        local v = (kind == "safe") and C.safe or C.fac
        if v then
            for _, n in ipairs(v.names) do C.sent[kind][n] = nil end
        else
            C.sent[kind] = {}
        end
    end
end

function C.expect(test, done)
    waits[#waits + 1] = { test = test, done = done or function() end, at = now() }
    C.dirty = true
end

-- (a done can ask for the next thing: it lands on the new list)
local function runWaits()
    local list = waits
    waits = {}
    for _, w in ipairs(list) do
        local ok, hit = pcall(w.test)
        if ok and hit then
            w.done(true)
        elseif now() - w.at >= EXPECT_MS then
            w.done(false)
        else
            waits[#waits + 1] = w
        end
    end
end

function C.tick()
    if not isClient() or C.qaHold then return end
    local t = now()
    if C.dirty or t - doneTick >= REFRESH_MS then
        C.dirty = nil
        doneTick = t
        C.refresh()
        runWaits()
    end
    if S.available() and (not C.infoAt or t - C.infoAt >= (C.infoEvery or INFO_MS)) then C.ask() end
end

-- the server part, when it is there
function C.ask()
    C.infoAt, C.infoEvery = now(), INFO_MS
    S.send(Cl.MOD, "c_info", {})
end

function C.askSoon()
    C.infoEvery = INFO_SOON_MS
end

function C.hasPart() return S.available() end

local function noteInfo(a)
    C.info = { at = now(), safe = a.safe, fac = a.fac }
    for _, kind in ipairs({ "safe", "fac" }) do
        local list = a[kind] and a[kind].invited
        if type(list) == "table" then
            -- (the server's word for who is waiting; one sent since it answered stays)
            local keep = {}
            for n, at in pairs(C.sent[kind]) do
                if now() - at < INFO_SOON_MS then keep[n] = at end
            end
            for i = 1, (list.n or 0) do keep[tostring(list[i])] = now() end
            C.sent[kind] = keep
        end
    end
    local list = a.invites
    for i = 1, (list and list.n or 0) do
        local e = list[i]
        if type(e) == "table" then C.recover(e) end
    end
    C.dirty = true
end

-- an invitation the server still holds and this client has no note of (it joined after it was sent)
function C.recover(e)
    local key = e.kind .. "|" .. tostring(e.host)
    if C.declined[key] then return end
    for _, i in ipairs(C.invites) do
        if i.kind == e.kind and i.host == e.host then return end
    end
    local obj
    if e.kind == "safe" then
        local all = SafeHouse.getSafehouseList()
        for n = 0, all:size() - 1 do
            local h = all:get(n)
            if h:getId() == e.key then obj = h; break end
        end
    elseif e.kind == "fac" then
        obj = Faction.getFaction(e.key)
    end
    if obj then C.addInvite(e.kind, obj, e.host, C.me(), e.name) end
end

S.on(Cl.MOD, function(command, args)
    if command == "c_info" then noteInfo(args or {})
    elseif command == "c_ack" and args and C.ackFn and args.rid == C.ackRid then
        local fn = C.ackFn
        C.ackFn = nil
        fn(args)
    end
end)

-- ---------------------------------------------------------------------------
-- INVITATIONS: a note in the Server tab, never the game's modal
-- ---------------------------------------------------------------------------
function C.addInvite(kind, obj, host, user, name)
    for _, i in ipairs(C.invites) do
        if i.kind == kind and i.host == host then i.obj, i.user, i.name = obj, user, name; return i end
    end
    local it = { kind = kind, obj = obj, host = host, user = user, name = name }
    C.invites[#C.invites + 1] = it
    C.declined[kind .. "|" .. tostring(host)] = nil
    C.bump()
    if Cl.INVITE_NOTE and ZeD.Messages and ZeD.Messages.invite then
        ZeD.Messages.invite(C.inviteText(it))
    end
    return it
end

function C.inviteText(i)
    if i.kind == "safe" then return tr("UI_ZeD_Cl_InviteSafe", tostring(i.host)) end
    return tr("UI_ZeD_Cl_InviteFaction", tostring(i.host), tostring(i.name))
end

-- as the game's handlers: no invitation for someone who already has one
function C.onSafeInvite(h, host, username)
    if SafeHouse.hasSafehouse(getPlayer()) then return end
    C.addInvite("safe", h, host, username, safe(function() return h:getTitle() end, ""))
end

function C.onFactionInvite(f, host, username)
    if Faction.getPlayerFaction(getPlayer()) then return end
    C.addInvite("fac", f, host, username, safe(function() return f:getName() end, ""))
end

function C.answer(inv, yes, done)
    local list = {}
    for _, i in ipairs(C.invites) do
        if i ~= inv then list[#list + 1] = i end
    end
    C.invites = list
    C.declined[inv.kind .. "|" .. tostring(inv.host)] = true
    if inv.kind == "safe" then acceptSafehouseInvite(inv.obj, inv.host, inv.user, yes == true)
    else acceptFactionInvite(inv.obj, inv.host, inv.user, yes == true) end
    C.bump()
    if yes then
        C.expect(function()
            local p = getPlayer()
            if inv.kind == "safe" then return SafeHouse.hasSafehouse(p) ~= nil end
            return Faction.getPlayerFaction(p) ~= nil
        end, function(ok) if done then done(ok) end end)
    elseif done then
        done(true)
    end
end

-- ---------------------------------------------------------------------------
-- CAN I CLAIM THIS? The game's own check, its own words, a line for each reason.
-- ---------------------------------------------------------------------------
function C.claimAnswer(p)
    local r = C.rules or C.readRules()
    if not r.player and not r.admin then return { lines = { tr("UI_ZeD_Cl_ClaimsOff") } } end
    local sq = p:getCurrentSquare()
    if not sq then return { lines = { tr("UI_ZeD_Cl_ClaimWait") } } end
    local x, y = math.floor(p:getX()), math.floor(p:getY())
    -- (the context menu asks only with a building under the square: canBeSafehouse reads it without a test)
    if not sq:getBuilding() then return { lines = { getText("IGUI_Safehouse_NotInside") }, x = x, y = y } end
    local held = SafeHouse.getSafeHouse(sq)
    if held then return { lines = { tr("UI_ZeD_Cl_ClaimTaken", tostring(held:getOwner())) }, x = x, y = y } end
    local s = SafeHouse.canBeSafehouse(sq, p)
    if s == nil then
        return { lines = { r.admin and getText("UI_ServerOption_AdminSafehouse_tooltip") or tr("UI_ZeD_Cl_ClaimsOff") }, x = x, y = y }
    end
    local lines = Cl.lines(s)
    if #lines == 0 then return { ok = true, lines = { tr("UI_ZeD_Cl_ClaimYes", tostring(x) .. " x " .. tostring(y)) }, x = x, y = y } end
    return { lines = lines, x = x, y = y }
end

-- at most every CHECK_MS, sooner when the player has stepped to another square
function C.claimCheck()
    local p = getPlayer()
    if not p then return nil end
    local a = C.claim
    local t = now()
    local at = tostring(math.floor(p:getX())) .. "," .. tostring(math.floor(p:getY())) .. "," .. tostring(math.floor(p:getZ()))
    if a and a.at == at and t - a.t < CHECK_MS then return a end
    local ok, ans = pcall(C.claimAnswer, p)
    if not ok then
        ZeD.logOnce("claim check", ans)
        ans = { lines = { tr("UI_ZeD_Cl_ClaimWait") } }
    end
    ans.at, ans.t = at, t
    if not a or table.concat(a.lines, "|") ~= table.concat(ans.lines, "|") then C.bump() end
    C.claim = ans
    return ans
end

-- ---------------------------------------------------------------------------
-- THE GAME'S CALLS, as its own windows make them
-- ---------------------------------------------------------------------------
function C.doClaim(done)
    local p = getPlayer()
    local sq = p and p:getCurrentSquare()
    if not sq then return false end
    sendSafehouseClaim(sq, p, p:getUsername())       -- (ISWorldObjectContextMenu.onTakeSafeHouse)
    C.expect(function() return SafeHouse.hasSafehouse(getPlayer()) ~= nil end, done)
    return true
end

function C.rename(text, done)
    local h = C.safe
    if not h then return end
    sendSafehouseChangeTitle(h.obj, text)
    C.expect(function() return C.safe and C.safe.title == text end, done)
end

function C.setRespawn(on)
    local h = C.safe
    if not h then return end
    sendSafehouseChangeRespawn(h.obj, C.me(), on == true)
    h.respawn = on == true
    C.bump()
end

function C.invite(kind, who)
    local me = C.me()
    if kind == "safe" then
        if not C.safe then return end
        sendSafehouseInvite(C.safe.obj, me, who)
    else
        if not C.fac then return end
        sendFactionInvite(C.fac.obj, me, who)
    end
    C.sent[kind][who] = now()
    C.bump()
    C.askSoon()
end

-- an invitation back: only the server holds the list (the game has no call)
function C.cancelInvite(kind, who, done)
    C.ackRid = (C.ackRid or 0) + 1
    C.ackFn = function(a)
        if a.ok ~= false then
            C.sent[kind][who] = nil
            C.bump()
        end
        if done then done(a) end
    end
    S.send(Cl.MOD, "c_cancel", { kind = kind, who = who, rid = C.ackRid })
end

function C.changeOwner(kind, who, done)
    if kind == "safe" then
        sendSafehouseChangeOwner(C.safe.obj, who)
        C.expect(function() return C.safe and C.safe.owner == who end, done)
    else
        sendFactionChangeOwner(C.fac.obj, who)
        C.expect(function() return C.fac and C.fac.owner == who end, done)
    end
end

function C.remove(kind, who, done)
    local function gone(v)
        if not v then return true end
        for _, n in ipairs(v.names) do if n == who then return false end end
        return true
    end
    if kind == "safe" then
        sendSafehouseChangeMember(C.safe.obj, who)
        C.expect(function() return gone(C.safe) end, done)
    else
        sendFactionRemoveMember(C.fac.obj, who)
        C.expect(function() return gone(C.fac) end, done)
    end
end

function C.release(done)
    sendSafehouseRelease(C.safe.obj)
    C.expect(function() return SafeHouse.hasSafehouse(getPlayer()) == nil end, done)
end

function C.quit(done)
    sendSafehouseChangeMember(C.safe.obj, C.me())
    C.expect(function() return SafeHouse.hasSafehouse(getPlayer()) == nil end, done)
end

function C.createFaction(name, done)
    sendFactionCreate(name, C.me())
    C.expect(function() return Faction.getPlayerFaction(getPlayer()) ~= nil end, done)
end

function C.renameFaction(name, done)
    sendFactionChangeTitle(C.fac.obj, name)
    C.expect(function() return C.fac and C.fac.name == name end, done)
end

function C.setTag(tag, done)
    local f = C.fac
    f.obj:setTag(tag)                                -- (ISCreateFactionTagUI: set here, then sent)
    sendFactionChangeTag(f.obj)
    C.expect(function() return C.fac and C.fac.tag == tag end, done)
end

function C.setColor(c)
    local f = C.fac
    f.obj:setTagColor(ColorInfo.new(c.r, c.g, c.b, 1))
    sendFactionChangeTag(f.obj)
    f.color = { r = c.r, g = c.g, b = c.b }
    C.bump()
end

function C.showTag(on)
    local p = getPlayer()
    p:setShowTag(on == true)
    sendFactionStatsChange(p)
    if C.fac then C.fac.showTag = on == true end
    C.bump()
end

function C.factionPvp(on)
    local p = getPlayer()
    p:setFactionPvp(on == true)
    sendFactionStatsChange(p)
    if C.fac then C.fac.pvp = on == true end
    C.bump()
end

function C.disband(done)
    sendFactionDisband(C.fac.obj)
    C.expect(function() return Faction.getPlayerFaction(getPlayer()) == nil end, done)
end

function C.leave(done)
    sendFactionRemoveMember(C.fac.obj, C.me())
    C.expect(function() return Faction.getPlayerFaction(getPlayer()) == nil end, done)
end

function C.war(row, stateName)
    sendWarManagerUpdate(row.id, row.attacker, State[stateName])
    C.dirty = true
end

-- is a name free? The game's own test, case kept. (C.qaTaken, C.qaCanCreate, C.qaOthers: what a QA script stages)
function C.factionTaken(name)
    if C.qaTaken then return C.qaTaken[name] == true end
    return Faction.factionExist(name)
end
function C.tagTaken(tag)
    if C.qaTaken then return C.qaTaken[tag] == true end
    return Faction.tagExist(tag)
end
function C.canCreateFaction()
    if C.qaCanCreate ~= nil then return C.qaCanCreate end
    local p = getPlayer()
    return p ~= nil and Faction.canCreateFaction(p)
end
function C.survivedToClaim()
    if C.qaHold then return true end
    local p = getPlayer()
    return p ~= nil and not SafeHouse.hasNotSurvivedEnoughToClaim(p)
end
function C.hoursSurvived()
    if C.qaHours then return C.qaHours end
    local p = getPlayer()
    return p and p:getHoursSurvived() or 0
end

-- who else has a safehouse or a faction, for the Add Player drawer
function C.safeOf(who)
    if C.qaOthers then return C.qaOthers.safe[who] end
    local h = C.safe
    if not h then return nil end
    local other = safe(function() return h.obj:alreadyHaveSafehouse(who) end, nil)
    if other and other ~= h.obj then return safe(function() return other:getTitle() end, "") end
    return nil
end
function C.factionOf(who)
    if C.qaOthers then return C.qaOthers.fac[who] end
    if not Faction.isAlreadyInFaction(who) then return nil end
    local f = Faction.getPlayerFaction(who)
    return f and f:getName() or ""
end

-- ---------------------------------------------------------------------------
-- HOOKS
-- ---------------------------------------------------------------------------
local function refreshSoon() C.dirty = true end

-- if ZeD's note fails, the game's modal runs, so an invitation is never lost
local function guarded(fn, game)
    return function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            ZeD.logOnce("claims invite", err)
            if game then game(...) end
        end
    end
end

if not C.hooked then
    C.hooked = true
    if ISSafehouseUI and ISSafehouseUI.ReceiveSafehouseInvite then
        Events.ReceiveSafehouseInvite.Remove(ISSafehouseUI.ReceiveSafehouseInvite)
    end
    if ISFactionUI and ISFactionUI.ReceiveFactionInvite then
        Events.ReceiveFactionInvite.Remove(ISFactionUI.ReceiveFactionInvite)
    end
    Events.ReceiveSafehouseInvite.Add(guarded(function(...) C.onSafeInvite(...) end, ISSafehouseUI and ISSafehouseUI.ReceiveSafehouseInvite))
    Events.ReceiveFactionInvite.Add(guarded(function(...) C.onFactionInvite(...) end, ISFactionUI and ISFactionUI.ReceiveFactionInvite))
    Events.OnSafehousesChanged.Add(refreshSoon)
    Events.SyncFaction.Add(refreshSoon)
    Events.AcceptedSafehouseInvite.Add(refreshSoon)
    Events.AcceptedFactionInvite.Add(refreshSoon)
    Events.OnWarUpdate.Add(refreshSoon)
    Events.OnTick.Add(function() C.tick() end)
end

return C
