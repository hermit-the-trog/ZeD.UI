-- ZeD-UI/42/media/lua/server/ZeD/ZeD_ServerClaims.lua
-- ============================================================================
-- SAFEHOUSES AND FACTIONS, THE SERVER'S SIDE (ZeDUI/MP_ADMIN_SCOPE.md, Phase 3). Almost nothing: the game's own calls do
-- the work and the game checks them, so the cards work with no server part at all. This file adds only what a client
-- cannot know or do:
--   c_info     when your safehouse was last visited (the game never sends it to clients), who your invitations are
--              still waiting on, and invitations waiting for you (the game sends one once, to a player online)
--   c_cancel   takes an invitation back: the game has no call for it, and only the server holds the list
--   the log    claims, releases and faction changes, by comparing the game's own lists, so a change made from any
--              window is logged and none rests on a client's word. Phase 4 reads these lines.
-- This file stores nothing: it all reads the game's live lists, and the log's lines go into the server part's one log
-- (Srv.action). A view is built from an allowlist, for one player, about their own safehouse and faction.
-- ============================================================================
if not isServer() then return end

require "ZeD/ZeD_TicketProto"
require "ZeD/ZeD_ClaimProto"
require "ZeD/ZeD_ServerCore"

local Srv = ZeD.Srv
local Tk, Cl = ZeD.Tk, ZeD.Cl
if not Srv or Srv.off then return end
local L = Cl.LIMITS

Srv.modules[Cl.MOD] = true
Srv.claims = Srv.claims or {}
local W = Srv.claims              -- the log's memory of the lists; a restart starts it again, writing nothing

local CAP_SAFE = Capability and Capability.CanSetupSafehouses
local CAP_FACTION = Capability and Capability.FactionCheat

local function can(p, cap) return cap ~= nil and Srv.can(p, cap) end
local function ack(p, rid, ok, err, extra) Srv.ack(p, rid, ok, err, extra, Cl.MOD, "c_ack") end

local function each(list, fn)
    if not list then return end
    for i = 0, list:size() - 1 do fn(list:get(i)) end
end

local function safeOf(p) return SafeHouse.hasSafehouse(p) end
local function factionOf(p) return Faction.getPlayerFaction(p) end

-- the safehouse this player runs, or the one they named if they may run any
local function runsSafe(p)
    local h = safeOf(p)
    if h and (h:isOwner(p) or can(p, CAP_SAFE)) then return h end
    return nil
end
local function runsFaction(p)
    local f = factionOf(p)
    if f and (f:isOwner(p:getUsername()) or can(p, CAP_FACTION)) then return f end
    return nil
end

-- who online holds an invitation to this. hasInvite comes from a parent class the game does not expose by name: if Lua
-- cannot see it, this says so and the card's Cancel stays gray
local function invited(o)
    if not o.hasInvite then return nil end
    local out, n = { n = 0 }, 0
    Srv.eachOnline(function(pl)
        local u = pl:getUsername()
        if n < L.NAMES_MAX and o:hasInvite(u) then
            n = n + 1
            out[n] = u
            out.n = n
        end
    end)
    return out
end

-- every invitation waiting for this player. live: the server could read them, so one missing here has gone
local function waiting(p)
    local me = p:getUsername()
    local out, n = { n = 0 }, 0
    local function holds(o)
        if not o.hasInvite then return false end
        out.live = true
        return o:hasInvite(me)
    end
    local function add(kind, key, name, host)
        if n < L.INVITES_MAX then
            n = n + 1
            out[n] = { kind = kind, key = key, name = name, host = host }
            out.n = n
        end
    end
    if not safeOf(p) then
        each(SafeHouse.getSafehouseList(), function(h)
            if holds(h) then add("safe", h:getId(), h:getTitle(), h:getOwner()) end
        end)
    end
    if not factionOf(p) then
        each(Faction.getFactions(), function(f)
            if holds(f) then add("fac", f:getName(), f:getName(), f:getOwner()) end
        end)
    end
    return out
end

-- what a player may read of their own safehouse. The game keeps last visited in milliseconds; it goes as hours ago, so no
-- client's clock enters the sum
local function safeView(p, h)
    local v = { visitedH = (getTimestampMs() - h:getLastVisited()) / 3600000 }
    local list = invited(h)
    if list then v.invited = list end
    return v
end

Srv.register(Cl.MOD, "c_info", { limit = L.INFO_MS, ackModule = Cl.MOD, ackCommand = "c_ack" }, function(p, a, rid)
    local r = { rid = rid, invites = waiting(p) }
    local h = safeOf(p)
    if h then r.safe = safeView(p, h) end
    local f = factionOf(p)
    if f then
        local list = invited(f)
        r.fac = { invited = list or nil }
    end
    Srv.to(p, Cl.MOD, "c_info", r)
end)

Srv.register(Cl.MOD, "c_cancel", { limit = L.CANCEL_MS, ackModule = Cl.MOD, ackCommand = "c_ack" }, function(p, a, rid)
    local who = a.who
    if (a.kind ~= "safe" and a.kind ~= "fac") or type(who) ~= "string" or #who < 1 or #who > Tk.LIMITS.NAME_MAX then
        Srv.bad(p, "c_cancel")
        return ack(p, rid, false, "text")
    end
    local o
    if a.kind == "safe" then o = runsSafe(p) else o = runsFaction(p) end
    if not o then
        Srv.deny(p, "c_cancel")
        return ack(p, rid, false, "perm")
    end
    if not o.removeInvite then return ack(p, rid, false, "fail") end
    -- (no invitation, no line: the log says what happened)
    if o.hasInvite and not o:hasInvite(who) then return ack(p, rid, false, "gone") end
    o:removeInvite(who)
    Srv.action((a.kind == "safe") and "safehouse" or "faction", p:getUsername(), "invite cancelled", Tk.name(who))
    ack(p, rid, true)
end)

-- ---------------------------------------------------------------------------
-- THE LOG: the game's lists compared with what they held last time. Every line says what changed and where; a change that
-- names no doer (a member gone) says whom it touched. Titles and names are players' words, so each is cut to one short line,
-- with no | to pass for a field of the line. A safehouse line says where, a faction line names the faction as its target.
-- A change undone between two passes leaves no line, which is the limit of comparing lists:
-- ZeDUI/MP_SERVER_PART_DESIGN.md says so for Phase 4.
-- ---------------------------------------------------------------------------
local function short(s) return (string.gsub(string.sub(Tk.name(s or ""), 1, L.LOG_TEXT), "|", "/")) end

local function line(kind, what, who, target, x, y)
    if W.lines >= L.LOG_PER_SCAN then
        W.dropped = W.dropped + 1
        return
    end
    W.lines = W.lines + 1
    Srv.action(kind, who, what, target, nil, x, y)
end

local function membersOf(list, owner)
    local out = {}
    if owner and owner ~= "" then out[owner] = true end
    each(list, function(n) out[n] = true end)
    return out
end

local function compareMembers(kind, was, now, target, x, y)
    for n in pairs(now) do
        if not was[n] then line(kind, "member in", short(n), target, x, y) end
    end
    for n in pairs(was) do
        if not now[n] then line(kind, "member out", short(n), target, x, y) end
    end
end

local function readSafe()
    local out = {}
    each(SafeHouse.getSafehouseList(), function(h)
        local owner = h:getOwner()
        out[h:getId()] = { owner = owner, title = h:getTitle(), x = h:getX(), y = h:getY(), members = membersOf(h:getPlayers(), owner) }
    end)
    return out
end

-- (by the object: the game's rename has no test for a name already taken, and the object is what a rename leaves alone)
local function readFaction()
    local out = {}
    each(Faction.getFactions(), function(f)
        local owner = f:getOwner()
        out[f] = { name = f:getName(), owner = owner, tag = f:getTag(), members = membersOf(f:getPlayers(), owner) }
    end)
    return out
end

local function compareSafe(was, now)
    for id, h in pairs(now) do
        local o = was[id]
        if not o then
            line("safehouse", "claim", short(h.owner), nil, h.x, h.y)
        else
            if o.owner ~= h.owner then line("safehouse", "owner from " .. short(o.owner), short(h.owner), nil, h.x, h.y) end
            if o.title ~= h.title then line("safehouse", "title " .. short(h.title), short(h.owner), nil, h.x, h.y) end
            compareMembers("safehouse", o.members, h.members, nil, h.x, h.y)
        end
    end
    for id, h in pairs(was) do
        if not now[id] then line("safehouse", "release", short(h.owner), nil, h.x, h.y) end
    end
end

local function compareFaction(was, now)
    for key, f in pairs(now) do
        local o = was[key]
        local name = short(f.name)
        if not o then
            line("faction", "create", short(f.owner), name)
        else
            if o.name ~= f.name then line("faction", "name from " .. short(o.name), short(f.owner), name) end
            if o.owner ~= f.owner then line("faction", "owner from " .. short(o.owner), short(f.owner), name) end
            if o.tag ~= f.tag then line("faction", "tag " .. short(f.tag), short(f.owner), name) end
            compareMembers("faction", o.members, f.members, name)
        end
    end
    for key, f in pairs(was) do
        if not now[key] then line("faction", "disband", short(f.owner), short(f.name)) end
    end
end

function Srv.claimsWatch()
    local t = getTimestampMs()
    if W.at and t - W.at < L.WATCH_MS then return end
    W.at = t
    local safes, factions = readSafe(), readFaction()
    W.lines, W.dropped = 0, 0
    if W.safes then compareSafe(W.safes, safes) end
    if W.factions then compareFaction(W.factions, factions) end
    W.safes, W.factions = safes, factions
    if W.dropped > 0 then Srv.action("claims", "server", tostring(W.dropped) .. " changes not logged") end
end

if not W.watching then
    W.watching = true
    Events.OnTickEvenPaused.Add(function()
        local ok, err = pcall(ZeD.Srv.claimsWatch)
        if not ok and not W.failed then
            W.failed = true
            print("[ZeD] server: the claims log failed: " .. tostring(err))
            Srv.action("admin", "server", "claims log failed", nil, err)
        end
    end)
end

return Srv
