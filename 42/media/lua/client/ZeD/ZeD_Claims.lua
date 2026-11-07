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
-- Server tab; while that tab is away (safe mode) ZeD calls the modals itself. The game has no answer to most calls:
-- C.expect watches for the change to arrive and reports if it does not.
-- ============================================================================

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ClaimProto"
require "ZeD/ZeD_ServerLink"
require "ZeD/Tr"
require "ZeD/ZeD_Messages"
require "ZeD/SafeMode"
require "ISUI/UserPanel/ISSafehouseUI"
require "ISUI/UserPanel/ISFactionUI"

ZeD = ZeD or {}
ZeD.Claims = ZeD.Claims or {}
local C = ZeD.Claims
local S = ZeD.ServerPart
local Cl = ZeD.Cl
local Tk = ZeD.Tk

local REFRESH_MS = 1000       -- the game's objects read this often
local CHECK_MS = 2000         -- "Can I claim this?" asked this often while it shows; the game's check walks the cell's objects
local INFO_MS = 30000         -- the server part asked this often while the link is up
local INFO_SOON_MS = 6000     -- after a change, this soon (its limit is 5 s)
local EXPECT_MS = 8000        -- the game gives no answer: past this, what was asked has not happened
local SENT_MS = 300000        -- "invited, waiting" ends after this unless the server's list still holds the name: the game tells the host nothing of a no
local INVITE_GRACE_MS = 6000  -- a note this new stays, whatever a c_info sent before it arrived says
local CANCEL_GAP_MS = Cl.LIMITS.CANCEL_MS + 100   -- between two taken back (the margin: packets do not land evenly spaced)
local CANCEL_TRIES = 3        -- a take-back the limit refused anyway goes again, this many times in all

C.seq = C.seq or 0            -- bumps when anything below changes
C.invites = C.invites or {}   -- invitations waiting: { kind = "safe" | "fac", key, obj, host, user, name, at }
C.sent = C.sent or { safe = {}, fac = {} }   -- who I invited and has not answered: name -> when
C.sentSure = C.sentSure or {} -- kind -> true while the server part's list is what C.sent holds, not only what this client sent
C.info = C.info or {}         -- what the server part last said
C.declined = C.declined or {} -- invitations answered this session, so a late c_info does not raise them again

local waits = {}              -- what the game has been asked and has not shown yet
local joining = nil           -- when a yes to a safehouse went, until it lands or is given up on
local cancels = {}            -- invitations being taken back, oldest first; the first is the one on the wire
local cancelAt = 0            -- when the first went
local doneTick = 0

local function now() return getTimestampMs() end
local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end

-- a note is answered in the Server tab of ZeD's Character window. While that window is away (safe mode, or Windows given
-- back in ZeD setup) the game's pop-ups answer instead. Asked each time: the option reads Off at load (SafeMode.lua), and
-- a player or the watchdog can change it at any point in a session
local function gamePopups() return ZeD.Safe.on("windows") end

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
        obj = h, id = Cl.houseKey(h), title = h:getTitle() or "", owner = owner, x = h:getX(), y = h:getY(),
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
        -- (FactionChangeTagPacket tests canCreateTag with no exception for any role, so a role does not open the field)
        canTag = (mine or cheat) and f:canCreateTag(), hasRoom = f:canCreateTag(),
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
    if not f then
        -- (nothing else changes when a player passes the day to create one)
        parts[#parts + 1] = tostring(safe(C.canCreateFaction, false)) .. tostring(math.floor(safe(C.hoursSurvived, 0) / 24))
    end
    for _, i in ipairs(C.invites) do parts[#parts + 1] = i.key end
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
        local keep = {}
        if v then
            local t = now()
            for n, at in pairs(C.sent[kind]) do
                if t - at < SENT_MS then keep[n] = at end
            end
            for _, n in ipairs(v.names) do keep[n] = nil end
        end
        C.sent[kind] = keep
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
        if #C.invites > 0 and gamePopups() then C.handBack() end
    end
    C.cancelTurn(t)
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
        C.sentSure[kind] = type(list) == "table"
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
    -- (list.live: the server can read invitations. A full list may have left one out, so it takes nothing away)
    if list and list.live and (list.n or 0) < Cl.LIMITS.INVITES_MAX then C.dropGone(list) end
    for i = 1, (list and list.n or 0) do
        local e = list[i]
        if type(e) == "table" then C.recover(e) end
    end
    C.dirty = true
end

-- what identifies an invitation: the safehouse or the faction. The event's host is a client's word (the game tests only
-- that it is not empty), and staff can send for an owner, so one house gives one note whoever sent it
function C.inviteKey(kind, obj)
    if kind == "safe" then return "safe|" .. tostring(Cl.houseKey(obj)) end
    return "fac|" .. tostring(obj:getName())
end

function C.findHouse(id)
    local all = SafeHouse.getSafehouseList()
    for n = 0, all:size() - 1 do
        local h = all:get(n)
        if Cl.houseKey(h) == id then return h end
    end
    return nil
end

-- the host took an invitation back: the note goes, or Accept would wait to be told it no longer stands
function C.dropGone(list)
    local held = {}
    for n = 1, (list.n or 0) do
        local e = list[n]
        if type(e) == "table" then held[e.kind .. "|" .. tostring(e.key)] = true end
    end
    local kept = {}
    local t = now()
    for _, i in ipairs(C.invites) do
        local key = safe(function() return C.inviteKey(i.kind, i.obj) end, i.key)
        if held[key] or t - i.at < INVITE_GRACE_MS then kept[#kept + 1] = i end
    end
    if #kept ~= #C.invites then
        C.invites = kept
        C.bump()
    end
end

-- an invitation the server still holds and this client has no note of (it joined after it was sent)
function C.recover(e)
    -- (no note while the tab is away: nothing shows it, and the game's pop-up may already hold this one)
    if gamePopups() then return end
    local obj
    if e.kind == "safe" then obj = C.findHouse(e.key)
    elseif e.kind == "fac" then obj = Faction.getFaction(e.key) end
    if not obj or C.declined[C.inviteKey(e.kind, obj)] then return end
    if #C.invites >= Cl.LIMITS.INVITES_MAX then return end
    C.addInvite(e.kind, obj, C.me())
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
-- INVITATIONS: a note in the Server tab; the game's modal only while that tab is away
-- ---------------------------------------------------------------------------
-- the game's pop-up for this one is still up (the option turned back while it showed): a note beside it would be a second
-- way to answer, and a second answer to a safehouse is the kick C.answer guards against
local function popupHolds(kind, obj)
    local ui = (kind == "safe") and ISSafehouseUI or ISFactionUI
    local key = C.inviteKey(kind, obj)
    for _, d in pairs(ui and ui.inviteDialogs or {}) do
        local held = d.safehouse or d.faction
        if held and C.inviteKey(kind, held) == key and safe(function() return d:isReallyVisible() end, false) then return true end
    end
    return false
end

function C.addInvite(kind, obj, user)
    for _, i in ipairs(C.invites) do
        if i.obj == obj then i.user = user; return i end
    end
    if popupHolds(kind, obj) then return nil end
    -- (the owner and the name from the object, cut: both can be any length of a client's text)
    local host = Tk.name(obj:getOwner())
    local name = (kind == "safe") and obj:getTitle() or obj:getName()
    local it = { kind = kind, key = C.inviteKey(kind, obj), obj = obj, host = host, user = user, name = Tk.name(name or ""), at = now() }
    C.invites[#C.invites + 1] = it
    while #C.invites > Cl.LIMITS.INVITES_MAX do table.remove(C.invites, 1) end
    C.declined[it.key] = nil
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
    C.addInvite("safe", h, username)
end

function C.onFactionInvite(f, host, username)
    if Faction.getPlayerFaction(getPlayer()) then return end
    C.addInvite("fac", f, username)
end

-- the game's accept packet goes through its safehouse anti-cheat, which tests "already has a safehouse" and never reads the
-- answer: a yes or a no landing after a yes has landed is a kick at the default setting (SafehouseAcceptPacket,
-- AntiCheatSafeHouseNotMember). The note goes only when the client hears, so the gap is a press away. A faction has no such test
local function houseAnswerClosed()
    if joining and now() - joining < EXPECT_MS then return true end
    local p = getPlayer()
    return not p or SafeHouse.hasSafehouse(p) ~= nil
end

function C.answer(inv, yes, done)
    local closed = inv.kind == "safe" and houseAnswerClosed()
    -- (a yes keeps its note: if the first fails, this one still stands)
    if closed and yes then
        if done then done(false) end
        return
    end
    local list = {}
    for _, i in ipairs(C.invites) do
        if i ~= inv then list[#list + 1] = i end
    end
    C.invites = list
    C.declined[inv.key] = true
    -- (a no that cannot go ends here: the note goes, and one left on the server's list harms nothing)
    if not closed then
        if inv.kind == "safe" then acceptSafehouseInvite(inv.obj, inv.host, inv.user, yes == true)
        else acceptFactionInvite(inv.obj, inv.host, inv.user, yes == true) end
    end
    C.bump()
    if yes then
        if inv.kind == "safe" then joining = now() end
        C.expect(function()
            local p = getPlayer()
            if inv.kind == "safe" then return SafeHouse.hasSafehouse(p) ~= nil end
            return Faction.getPlayerFaction(p) ~= nil
        end, function(ok)
            if inv.kind == "safe" then joining = nil end
            if done then done(ok) end
        end)
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
    if held then
        -- (a stranger learns that it is claimed, not whom to look for; playerAllowed holds its members and staff)
        local words = held:playerAllowed(p) and tr("UI_ZeD_Cl_ClaimTaken", tostring(held:getOwner())) or tr("UI_ZeD_Cl_ClaimHeld")
        return { lines = { words }, x = x, y = y }
    end
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

local function cancelled(c, a)
    if a.err == "wait" and c.tries < CANCEL_TRIES then return end   -- (it stays first and goes again)
    table.remove(cancels, 1)
    if a.ok ~= false or a.err == "gone" then
        C.sent[c.kind][c.who] = nil
        C.bump()
    end
    if c.done then c.done(a) end
end

function C.cancelTurn(t)
    local c = cancels[1]
    if not c then return end
    if C.ackFn then
        -- (the answer never came: said so, and the next one is not held up by it)
        if t - cancelAt >= EXPECT_MS then
            C.ackFn = nil
            cancelled(c, { ok = false, err = "lost" })
        end
        return
    end
    if t - cancelAt < CANCEL_GAP_MS then return end
    C.ackRid = (C.ackRid or 0) + 1
    c.tries = c.tries + 1
    cancelAt = t
    C.ackFn = function(a) cancelled(c, a) end
    S.send(Cl.MOD, "c_cancel", { kind = c.kind, who = c.who, rid = C.ackRid })
end

-- an invitation back: only the server holds the list (the game has no call). It takes one a second from a player and one
-- answer is listened for at a time, and presses come faster than that: they go in turn, so each gets its own answer
function C.cancelInvite(kind, who, done)
    for _, c in ipairs(cancels) do
        if c.kind == kind and c.who == who then return end
    end
    cancels[#cancels + 1] = { kind = kind, who = who, done = done, tries = 0 }
    C.cancelTurn(now())
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

-- h: the card's read of the safehouse. hasSafehouse answers the first match and staff can hold two: done is "this one has
-- gone", not "I have none"
function C.release(h, done)
    sendSafehouseRelease(h.obj)
    C.expect(function() return C.findHouse(h.id) == nil end, done)
end

function C.quit(h, done)
    local me = C.me()
    sendSafehouseChangeMember(h.obj, me)
    C.expect(function()
        local o = C.findHouse(h.id)
        return o == nil or not o:getPlayers():contains(me)
    end, done)
end

function C.createFaction(name, done)
    sendFactionCreate(name, C.me())
    C.expect(function() return Faction.getPlayerFaction(getPlayer()) ~= nil end, done)
end

function C.renameFaction(name, done)
    sendFactionChangeTitle(C.fac.obj, name)
    C.expect(function() return C.fac and C.fac.name == name end, done)
end

-- sendFactionChangeTag reads the tag and color off the object as it sends (ISCreateFactionTagUI sets them first). They go
-- back straight after: a tag the server takes comes to every client in a FactionSync, this one too, so the object here only
-- ever holds what the server does and C.expect proves something. (A color alone resends the tag the faction already holds,
-- and FactionChangeTagPacket.isConsistent takes that only from the owner's connection, whatever the role.)
function C.setTag(tag, done)
    local f = C.fac
    local was = f.obj:getTag()
    f.obj:setTag(tag)
    sendFactionChangeTag(f.obj)
    f.obj:setTag(was)
    C.expect(function() return C.fac and C.fac.tag == tag end, done)
end

function C.setColor(c, done)
    local f = C.fac
    local was = f.obj:getTagColor()
    f.obj:setTagColor(ColorInfo.new(c.r, c.g, c.b, 1))
    sendFactionChangeTag(f.obj)
    f.obj:setTagColor(was)
    C.colorAsked = c
    -- (a later press takes over: only the last color asked can be missing)
    C.expect(function() return C.colorAsked ~= c or (C.fac and Cl.sameColor(C.fac.color, c)) end, done)
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

local gameInvite = {
    safe = ISSafehouseUI and ISSafehouseUI.ReceiveSafehouseInvite,
    fac = ISFactionUI and ISFactionUI.ReceiveFactionInvite,
}

-- the Server tab has gone with notes still waiting: each goes to the game's modal, once. One left unanswered there is
-- still on the server's list, so it comes back as a note when the tab does
function C.handBack()
    local list = C.invites
    C.invites = {}
    for _, i in ipairs(list) do
        local game = gameInvite[i.kind]
        local ok, err = pcall(function() if game then game(i.obj, i.host, i.user) end end)
        if not ok then ZeD.logOnce("claims invite", err) end
    end
    C.bump()
end

-- if ZeD's note fails, the game's modal runs, so an invitation is never lost. The game's handlers stay off the event in
-- safe mode too, and run from here: the event can then only raise one or the other, whichever way the option turns
local function guarded(fn, game)
    return function(...)
        if gamePopups() then
            if game then game(...) end
            return
        end
        local ok, err = pcall(fn, ...)
        if not ok then
            ZeD.logOnce("claims invite", err)
            if game then game(...) end
        end
    end
end

if not C.hooked then
    C.hooked = true
    if gameInvite.safe then Events.ReceiveSafehouseInvite.Remove(gameInvite.safe) end
    if gameInvite.fac then Events.ReceiveFactionInvite.Remove(gameInvite.fac) end
    Events.ReceiveSafehouseInvite.Add(guarded(function(...) C.onSafeInvite(...) end, gameInvite.safe))
    Events.ReceiveFactionInvite.Add(guarded(function(...) C.onFactionInvite(...) end, gameInvite.fac))
    Events.OnSafehousesChanged.Add(refreshSoon)
    Events.SyncFaction.Add(refreshSoon)
    Events.AcceptedSafehouseInvite.Add(refreshSoon)
    Events.AcceptedFactionInvite.Add(refreshSoon)
    Events.OnWarUpdate.Add(refreshSoon)
    Events.OnTick.Add(function() C.tick() end)
end

return C
