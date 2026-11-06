-- ZeDUI/tools/qa/mp_extras_cards.lua  (Nov 6 2026, QA): multiplayer Phase 6, every state of the Server extras card, the Server
-- tab's block and Your claims, from the mockup (mockups/zed_community_v1.html), one picture each. grep "ZEDQA mxc". Pictures:
-- mxc_<state>.png, in the screenshots folder.
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_extras_cards.txt
-- It holds the traffic (ZeD.Extras.qaHold, ZeD.Admin.qaHold, ZeD.TicketCards.qaHold) and puts the mockup's data in the model, so
-- nothing here reaches the server's record. mp_extras.lua is the run against the real server. For Deck, 720 and Large text run it
-- again at those settings (zedqa_run -Width -Height; ZeD setup's text size): the states are the same.
-- extras_cards_sim.lua loads this file too, for the same states with no game: it sets ZEDQA_CARDS_SIM and gets the table.

local Q = {}

local function caps(list)
    local out = {}
    for _, c in ipairs(list) do out[c] = true end
    return out
end

-- the game's roles as ZeD_Admin reads them, least to most, those with the map's teleport as drawn
function Q.roles()
    local function row(name, pos, r, g, b, desc, list, readOnly, defaults)
        return { name = name, pos = pos, color = { r = r, g = g, b = b }, desc = desc, caps = caps(list), readOnly = readOnly, defaults = defaults or {}, obj = { name = name } }
    end
    return {
        row("banned", 0, 0.48, 0.48, 0.48, "Can't join.", {}, true, { "defaultForBanned" }),
        row("user", 1, 0.83, 0.83, 0.85, "Everyone, to start.", { "LoginOnServer" }, true, { "defaultForNewUser", "defaultForUser" }),
        row("moderator", 5, 0.77, 0.56, 0.25, "Keeps the peace.", { "TeleportToCoordinates", "AnswerTickets" }),
        row("overseer", 6, 0.83, 0.57, 0.16, "A moderator who can ban.", { "TeleportToCoordinates", "AnswerTickets", "BanUnbanUser" }),
        row("admin", 7, 0.77, 0.25, 0.25, "Everything.", { "TeleportToCoordinates", "AnswerTickets", "ChangeAndReloadServerOptions", "ManipulateVehicle", "RolesWrite" }, true),
    }
end

local ADMIN = { "TeleportToCoordinates", "AnswerTickets", "ChangeAndReloadServerOptions", "ManipulateVehicle", "RolesWrite", "RolesRead", "SeePlayersConnected" }

function Q.claims()
    return {
        { key = "v4021", name = "PickUpTruck", x = 6402, y = 5410 },
        { key = "v4388", name = "CarStationWagon", x = 6395, y = 5301 },
    }
end

function Q.bind(TC, AC, EC, E, M, Ex)
    local out = {}
    local function reset(win, st)
        st.card, st.screen = nil, nil
        TC.qaHold, TC.qaRole, TC.qaLink = true, "admin", nil
        E.qaHold, E.qaLink, E.frozen = true, true, false
        M.qaHold, M.qaLink, M.qaCaps, M.qaRoles = true, true, caps(ADMIN), Q.roles()
        E.set = Ex.defaults()
        E.mineRows, E.minePer = nil, nil
        E.cars = {}
        E.bump()
        M.bump()
    end
    local function S1(name, tab, run)
        out[#out + 1] = { name = name, tab = tab, reset = reset, run = run }
    end
    local function A1(name, run) S1(name, "admin", run) end
    local function P1(name, run) S1(name, "server", run) end
    local function all(s)
        s.vc.on, s.sp.on, s.tp.on, s.cl.on = true, true, true, true
    end
    local function open(win, st, fn)
        if fn then fn(E.set) end
        E.bump()
        EC.qaOpen(win, st, "extras")
    end
    local function draft(win, st, fn)
        EC.qaOpen(win, st, "extras")
        fn(st.card.d)
        st.card.rev = (st.card.rev or 0) + 1
    end

    -- the Admin tab's row
    A1("admin-home", function() end)
    A1("admin-home-some-on", function() E.set.vc.on, E.set.sp.on = true, true; E.bump() end)
    A1("admin-home-no-part", function() E.qaLink = false; E.bump() end)

    -- the card
    A1("extras-all-off", function(win, st) open(win, st) end)
    A1("extras-claims", function(win, st) open(win, st, function(s) s.vc.on = true end) end)
    A1("extras-claims-tow-1-30", function(win, st) open(win, st, function(s) s.vc.on, s.vc.tow, s.vc.per, s.vc.lapse = true, true, 1, 30 end) end)
    A1("extras-claims-5-1", function(win, st) open(win, st, function(s) s.vc.on, s.vc.per, s.vc.lapse = true, 5, 1 end) end)
    A1("extras-protection", function(win, st) open(win, st, function(s) s.sp.on = true end) end)
    A1("extras-protection-no-lot", function(win, st) open(win, st, function(s) s.sp.on, s.sp.lot = true, false end) end)
    A1("extras-teleport", function(win, st) open(win, st, function(s) s.tp.on = true end) end)
    A1("extras-teleport-no-role", function(win, st) M.qaRoles = {}; open(win, st, function(s) s.tp.on = true end) end)
    A1("extras-log", function(win, st) open(win, st, function(s) s.cl.on = true end) end)
    A1("extras-all-on", function(win, st) open(win, st, all) end)
    A1("extras-not-saved", function(win, st) draft(win, st, function(d) d.vc.on = true end) end)
    A1("extras-all-on-not-saved", function(win, st) draft(win, st, all) end)
    A1("extras-saving", function(win, st)
        draft(win, st, function(d) d.vc.on = true end)
        TC.qaState(st).busy = true
    end)
    A1("extras-no-power", function(win, st)
        M.qaCaps = caps({ "AnswerTickets" })
        open(win, st, all)
    end)
    A1("extras-no-power-off", function(win, st)
        M.qaCaps = caps({ "AnswerTickets" })
        open(win, st)
    end)
    A1("extras-frozen", function(win, st)
        E.frozen = true
        open(win, st, all)
    end)
    A1("extras-link-lost", function(win, st)
        open(win, st, all)
        E.qaLink = false
    end)

    -- the Server tab
    P1("tab-all-off", function() end)
    P1("tab-claims", function() E.set.vc.on = true; E.mineRows = {}; E.bump() end)
    P1("tab-claims-all-ticks", function() E.set.vc.on, E.set.vc.tow = true, true; E.mineRows = Q.claims(); E.bump() end)
    P1("tab-claims-no-ticks", function() E.set.vc.on, E.set.vc.parts, E.set.vc.drive = true, false, false; E.bump() end)
    P1("tab-protection-lot", function() E.set.sp.on = true; E.bump() end)
    P1("tab-protection-walls", function() E.set.sp.on, E.set.sp.lot = true, false; E.bump() end)
    P1("tab-protection-dismantle", function() E.set.sp.on, E.set.sp.destroy = true, false; E.bump() end)
    P1("tab-log", function() E.set.cl.on = true; E.bump() end)
    P1("tab-all-on", function() all(E.set); E.mineRows = Q.claims(); E.bump() end)
    P1("tab-no-part", function() E.qaLink = false; E.bump() end)

    -- your claims
    P1("claims-wait", function(win, st) E.set.vc.on = true; E.bump(); EC.qaOpen(win, st, "xclaims") end)
    P1("claims-none", function(win, st) E.set.vc.on = true; E.mineRows = {}; E.bump(); EC.qaOpen(win, st, "xclaims") end)
    P1("claims-two", function(win, st) E.set.vc.on = true; E.mineRows = Q.claims(); E.bump(); EC.qaOpen(win, st, "xclaims") end)
    P1("claims-unknown-car", function(win, st)
        E.set.vc.on = true
        E.mineRows = { { key = "v1" }, { key = "v2", name = "SomeModdedCarWithAVeryLongScriptNameIndeedOfTheKindModsUse", x = 16402, y = 15410 } }
        E.bump()
        EC.qaOpen(win, st, "xclaims")
    end)
    P1("claims-release-ask", function(win, st)
        E.set.vc.on = true
        E.mineRows = Q.claims()
        E.bump()
        EC.qaOpen(win, st, "xclaims")
        EC.qaAsk(st, E.mineRows[1])
    end)
    return out
end

-- ---------------------------------------------------------------------------
if ZEDQA_CARDS_SIM then return Q end

local function say(s) print("ZEDQA mxc " .. tostring(s)) end
local TC, AC, EC, E, M, Ex = ZeD.TicketCards, ZeD.AdminCards, ZeD.ExtrasCards, ZeD.Extras, ZeD.Admin, ZeD.Ex
local states = Q.bind(TC, AC, EC, E, M, Ex)

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

local function windowOf(tab)
    if tab == "admin" then return ZeD_WorldWindow.getWindow() end
    return ZeD_CharacterWindow.getWindow(0)
end

for _, s in ipairs(states) do
    add(250, function()
        if s.tab == "admin" then ZeD_WorldWindow.openTab(0, "admin") else ZeD_CharacterWindow.openTab(0, "server") end
    end)
    add(500, function()
        local win = windowOf(s.tab)
        local st = (s.tab == "admin") and win._adminTab or win._serverTab
        if not st then say("no tab state for " .. s.name); return end
        s.reset(win, st)
        s.run(win, st)
    end)
    add(900, function()
        say(s.name)
        pcall(function() getCore():TakeFullScreenshot("mxc_" .. s.name .. ".png") end)
    end)
end
add(500, function()
    TC.qaHold, TC.qaRole, TC.qaLink = nil, nil, nil
    E.qaHold, E.qaLink, E.mineRows = nil, nil, nil
    M.qaHold, M.qaLink, M.qaCaps, M.qaRoles = nil, nil, nil, nil
    ZeD.ServerPart.hello()
    say("DONE")
end)

local function drive()
    local st = plan[i]
    if not st then
        Events.OnTick.Remove(drive)
        return
    end
    if getTimestampMs() - t0 < st.ms then return end
    t0 = getTimestampMs()
    i = i + 1
    local ok, err = pcall(st.fn)
    if not ok then say("FAIL " .. tostring(err)) end
end
Events.OnTick.Add(drive)
