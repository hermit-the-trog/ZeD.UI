-- ZeDUI/tools/qa/mp_claims.lua  (Nov 5 2026, QA): multiplayer Phase 3, safehouses and factions, on the local server.
-- grep "ZEDQA mcl", then the server's logs in C:\Users\danie\Zomboid\zedqa_mp\Logs (*_ZeD.txt: "safehouse |", "faction |").
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"     (the shim carries ZeDQA.role)
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_claims.txt
-- It drives ZeD.Claims, which makes the game's own calls, and the server answers. PROBE lines are the things the code could
-- not settle: read them against MP_SERVER_PART_DESIGN.md's last section. What needs a second player (an invitation that really
-- crosses, Change Owner, Remove, a war) prints as TODO: claims_sim.lua proves their logic without the game. mp_claim_cards.lua
-- takes the pictures. The test client joins as admin; ZeDQA.role makes it a plain user for the owner-only and refused steps.
local function say(s) print("ZEDQA mcl " .. tostring(s)) end
local function pass(name, ok, detail)
    say((ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local p = getPlayer()
local me = p:getUsername()
local C, Cl, S = ZeD.Claims, ZeD.Cl, ZeD.ServerPart

local got = {}
local function tap(module, command, args)
    if module == Cl.MOD then got[#got + 1] = { c = command, a = args or {} } end
end
Events.OnServerCommand.Add(tap)
local function last(cmd)
    for i = #got, 1, -1 do if got[i].c == cmd then return got[i].a end end
    return nil
end
local function role(name) sendClientCommand(p, "ZeDQA", "role", { name = name }) end
local function nolimits() sendClientCommand(p, "ZeDQA", "nolimits", {}) end
local function goTo(x, y) SendCommandToServer("/teleportto " .. tostring(x) .. "," .. tostring(y) .. ",0") end

-- the nearest square indoors, read from the cell the game has loaded
local function indoors(r)
    local cx, cy = math.floor(p:getX()), math.floor(p:getY())
    local cell = getCell()
    for d = 1, r do
        for dx = -d, d do
            for dy = -d, d do
                if math.abs(dx) == d or math.abs(dy) == d then
                    local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
                    if sq and sq:getBuilding() and not SafeHouse.getSafeHouse(sq) then return cx + dx, cy + dy end
                end
            end
        end
    end
    return nil
end

local SPOTS = { { 10737, 10234 }, { 10650, 10267 }, { 10815, 10037 } }
local spot = 1
local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

add(3000, function()
    pass("the link is up", S.available())
    C.refresh()
    local r = C.rules
    say("rules: claim day " .. tostring(r.claimDay) .. ", player " .. tostring(r.player) .. ", admin " .. tostring(r.admin) .. ", any building " .. tostring(r.anyBuilding)
        .. ", trespass " .. tostring(r.trespass) .. ", loot " .. tostring(r.loot) .. ", fire " .. tostring(r.fire) .. ", respawn " .. tostring(r.respawn)
        .. ", removal " .. tostring(r.removal) .. ", protection off while on " .. tostring(r.ownerOff) .. ", war " .. tostring(r.war))
    pass("the option names read", r.removal ~= nil and r.removal > 0, r.removal)
    pass("the game's invite modals are off their events", ISSafehouseUI.ReceiveSafehouseInvite ~= nil)
    say("PROBE canBeSafehouse outdoors, no building: " .. tostring(p:getCurrentSquare() and p:getCurrentSquare():getBuilding() ~= nil))
    local a = C.claimCheck()
    say("the checker here: " .. tostring(a and a.lines[1]))
end)
add(500, function() goTo(SPOTS[1][1], SPOTS[1][2]) end)
for n = 1, #SPOTS do
    add(6000, function()
        local x, y = indoors(30)
        say("spot " .. n .. ": indoors at " .. tostring(x) .. "," .. tostring(y))
        if x then goTo(x, y) end
    end)
    add(3000, function()
        C.claim = nil
        local a = C.claimCheck()
        for _, s in ipairs(a and a.lines or {}) do say("the checker: " .. tostring(s)) end
        if a and a.ok then
            spot = n
        elseif SPOTS[n + 1] then
            goTo(SPOTS[n + 1][1], SPOTS[n + 1][2])
        end
    end)
end
local claimed = nil
add(1000, function()
    C.claim = nil
    local a = C.claimCheck()
    pass("a building to claim", a and a.ok == true, a and a.lines[1])
    C.doClaim(function(ok) claimed = ok end)
end)
add(9000, function()
    pass("Claim Safehouse", claimed == true and C.safe ~= nil, C.safe and C.safe.title)
    local h = C.safe
    if not h then return end
    pass("the title is the username", h.title == me, h.title)
    say("PROBE client getLastVisited: " .. tostring(h.obj:getLastVisited()) .. " now " .. tostring(getTimestampMs()) .. " (the sync packet does not carry it)")
    say("PROBE hasInvite on Lua: " .. tostring(h.obj.hasInvite ~= nil) .. ", removeInvite: " .. tostring(h.obj.removeInvite ~= nil))
    say("PROBE location: " .. tostring(h.location) .. ", created: " .. tostring(h.created))
    C.rename("Riverside Motel", function(ok) pass("the title saves", ok == true) end)
end)
add(3000, function()
    C.setRespawn(true)
end)
add(3000, function()
    pass("respawn reads back", C.safe and C.safe.respawn == true)
    nolimits()
    C.ask()
end)
add(2000, function()
    local a = last("c_info")
    pass("c_info answers", a ~= nil)
    say("PROBE visited hours ago, server side: " .. tostring(a and a.safe and a.safe.visitedH) .. " (0 while standing in it, if IsoPlayer's check runs on the server)")
    local keep = ZeD.ClaimCards.keepWords()
    say("the card says: " .. tostring(keep))
    -- an invitation as a note, by the game's own event
    C.invites = {}
    triggerEvent("ReceiveFactionInvite", nil, "QA_host", me)
    say("(nil faction, so no note and no modal expected: the handler only reads it)")
end)
add(1000, function()
    C.createFaction("ZeD QA", function(ok) pass("Create Faction", ok == true and C.fac ~= nil) end)
end)
add(9000, function()
    local f = C.fac
    if not f then return end
    say("PROBE canCreateTag with one player: " .. tostring(f.hasRoom) .. ", tag on server option " .. tostring(C.rules.tagNeeds))
    pass("the name is taken now", C.factionTaken("ZeD QA") == true)
    C.setTag("ZQA", function(ok) pass("the tag saves", ok == true) end)
end)
add(9000, function()
    C.setColor(Cl.COLORS[5])
end)
add(2000, function()
    local c = C.fac and C.fac.color
    pass("the color reads back", c and Cl.sameColor(c, Cl.COLORS[5]), c and c.g)
    C.showTag(true)
    C.factionPvp(true)
end)
add(2000, function()
    pass("the two ticks are the player's", p:isShowTag() == true and p:isFactionPvp() == true)
    C.factionPvp(false)
    C.renameFaction("ZeD QA 2", function(ok) pass("the faction renames", ok == true) end)
end)
add(4000, function()
    say("wars here: " .. tostring(#(C.wars or {})) .. ", option " .. tostring(C.rules.war))
    say("TODO two players: an invitation that crosses, Accept and Decline, relog with one waiting, Change Owner, Remove, a member's Quit, a war. claims_sim.lua covers the logic")
    say("TODO grep the server's ZeD log for: safehouse | claim, safehouse | title, faction | create, faction | tag, faction | name from")
    -- a plain user refused by the server part
    role("user")
end)
add(2000, function()
    S.send(Cl.MOD, "c_cancel", { kind = "fac", who = "nobody", rid = 91 })
end)
add(2000, function()
    local a = last("c_ack")
    say("as a plain user, owner of what they named: " .. tostring(a and a.ok) .. " " .. tostring(a and a.err))
    role("admin")
    C.disband(function(ok) pass("Disband", ok == true) end)
end)
add(9000, function()
    C.release(C.safe, function(ok) pass("Release", ok == true) end)
end)
add(9000, function()
    pass("nothing left", C.safe == nil and C.fac == nil)
    Events.OnServerCommand.Remove(tap)
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then Events.OnTick.Remove(drive); return end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs(); i = i + 1
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
