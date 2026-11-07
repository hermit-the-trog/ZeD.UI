-- ZeDUI/tools/qa/mp_admin_cards.lua  (Nov 5 2026, QA): multiplayer Phase 2, every state of the Admin tab and its cards, from
-- the mockup's players (mockups/zed_admin_tools_v1.html), one picture each. grep "ZEDQA mac". Pictures: mac_<state>.png, in
-- the screenshots folder.
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_admin_cards.txt
-- It holds the traffic (ZeD.Admin.qaHold, ZeD.TicketCards.qaHold) and puts the mockup's data in the model, so nothing here
-- reaches the server's record. mp_admin.lua is the run against the real server. For Deck, 720 and Large text run it again at
-- those settings (zedqa_run -Width -Height; ZeD setup's text size): the states are the same.
-- admin_cards_sim.lua loads this file too, for the same states with no game: it sets ZEDQA_CARDS_SIM and gets the table.

local Q = {}

local NOW = 1793913240

local function caps(list)
    local out = {}
    for _, c in ipairs(list) do out[c] = true end
    return out
end
local MOD = { "CanSeePlayersStats", "SeeNetworkUsers", "SeePlayersConnected", "KickUser", "BanUnbanUser", "AddUserlog", "TeleportToPlayer", "ReadUserLog",
    "AnswerTickets", "CanSeeMessageForAdmin", "PVPLogTool", "InspectPlayerInventory", "RolesRead" }
local OVER = { "TeleportPlayerToAnotherPlayer", "ToggleInvisibleHimself" }
for _, c in ipairs(MOD) do OVER[#OVER + 1] = c end
local GM = { "AddItem", "StartStopRain", "ClimateManager", "TeleportToPlayer", "TeleportPlayerToAnotherPlayer", "DisplayServerMessage", "ToggleInvisibleHimself", "ToggleGodModHimself", "SeePlayersConnected", "RolesRead" }

function Q.allCaps(Adm)
    local out = {}
    for _, g in ipairs(Adm.GROUPS) do
        for _, c in ipairs(g.caps) do out[#out + 1] = c end
    end
    return out
end

-- the game's roles (B42 defaults) as ZeD_Admin reads them, least to most
function Q.roles(Adm)
    local function row(name, pos, r, g, b, desc, list, readOnly, defaults)
        return { name = name, pos = pos, color = { r = r, g = g, b = b }, desc = desc, caps = caps(list), readOnly = readOnly, defaults = defaults or {}, obj = { name = name } }
    end
    return {
        row("banned", 0, 0.48, 0.48, 0.48, "Can't join.", {}, true, { "defaultForBanned" }),
        row("user", 1, 0.83, 0.83, 0.85, "Everyone, to start.", { "LoginOnServer" }, true, { "defaultForNewUser", "defaultForUser" }),
        row("priority", 2, 0.31, 0.53, 0.78, "Gets in when the server is full.", { "LoginOnServer", "PriorityLogin" }),
        row("observer", 3, 0.60, 0.42, 0.77, "Watches; can't touch the world.", { "ToggleInvisibleHimself", "ToggleNoclipHimself" }),
        row("GM", 4, 0.35, 0.60, 0.29, "Runs events.", GM),
        row("moderator", 5, 0.77, 0.56, 0.25, "Keeps the peace.", MOD),
        row("overseer", 6, 0.83, 0.57, 0.16, "A moderator who can ban.", OVER),
        row("admin", 7, 0.77, 0.25, 0.25, "Everything.", Q.allCaps(Adm), true),
    }
end

function Q.rows()
    return {
        { user = "Hermit", role = "admin", on = true, warn = 0, kicks = 0, steam = "hermit.trog" },
        { user = "Kade_R", role = "user", on = true, warn = 2, kicks = 1, steam = "kader_ky", sid = "76561198000000003" },
        { user = "Rosa", role = "moderator", on = true, warn = 0, kicks = 0, steam = "rosa.m" },
        { user = "Aretha", role = "user", on = true, warn = 0, kicks = 0, steam = "aretha.b" },
        { user = "Mags_77", role = "user", on = true, warn = 0, kicks = 0, steam = "magpie77" },
        { user = "mike_d", role = "user", on = true, warn = 1, kicks = 0, steam = "miked" },
        { user = "tjk", role = "priority", on = false, warn = 0, kicks = 0, steam = "tjk", lastT = NOW - 61 * 3600 },
        { user = "lootdrop99", role = "banned", on = false, warn = 5, kicks = 1, steam = "lootdrop99", lastT = NOW - 3 * 86400 },
    }
end

function Q.cards()
    local skills = { { id = "Farming", name = "Farming", lv = 5 }, { id = "Strength", name = "Strength", lv = 7 }, { id = "Woodwork", name = "Carpentry", lv = 2 },
        { id = "Aiming", name = "Aiming", lv = 1 }, { id = "Cooking", name = "Cooking", lv = 0 }, { id = "Sprinting", name = "Sprinting", lv = 10 } }
    return {
        Hermit = { user = "Hermit", on = true, role = "admin", prof = "Carpenter", traits = { "Handy", "Night Owl" }, skills = { { id = "Woodwork", name = "Carpentry", lv = 6 } }, x = 6330, y = 5390, z = 0, oid = 1, tickets = {}, ticketN = 0 },
        Kade_R = { user = "Kade_R", on = true, role = "user", prof = "Farmer", traits = { "Strong", "Gardener", "Smoker" }, skills = skills, x = 6280, y = 5350, z = 0, oid = 2, ticketN = 2,
            tickets = { { id = 14, kind = "GRIEF", st = "Open", first = "Someone pulled the engine out of my pickup at the farm." }, { id = 9, kind = "GRIEF", st = "Closed", first = "My fence got knocked down again." } } },
        Rosa = { user = "Rosa", on = true, role = "moderator", prof = "Nurse", traits = { "Fast Learner", "First Aider" }, skills = { { id = "Doctor", name = "First Aid", lv = 4 } }, x = 10650, y = 9970, z = 0, oid = 3, tickets = {}, ticketN = 0 },
        tjk = { user = "tjk", on = false, role = "priority", last = NOW - 61 * 3600, prof = "Park Ranger", traits = { "Outdoorsman" }, skills = { { id = "PlantScavenging", name = "Foraging", lv = 4 } }, tickets = {}, ticketN = 0 },
        lootdrop99 = { user = "lootdrop99", on = false, role = "banned", last = NOW - 3 * 86400, prof = "Unemployed", traits = {}, skills = {}, tickets = {}, ticketN = 0, banId = 1 },
    }
end

function Q.logs()
    return { Kade_R = {
        { type = "WarningPoint", text = "Took the shared generator to his farm.", by = "Rosa", amount = 1, when = "Day 9" },
        { type = "Kicked", text = "Spamming chat after a death.", by = "Hermit", amount = 0, when = "Day 6" },
    } }
end

function Q.bans()
    return {
        { id = 1, user = "lootdrop99", reason = "Scam spam in chat and tickets.", by = "Jules", day = 9, at = NOW - 86400, sid = "76561198000000001", banIp = true },
        { id = 2, user = "xX_Torch", reason = "Burned the Riverside farm, twice.", by = "Hermit", day = 11, at = NOW - 3600, untilT = NOW + 259200, sid = "76561198000000002" },
    }
end

function Q.items()
    local out = {}
    local names = { "Axe", "Baseball Bat", "Katana", "Hammer", "Saw", "Nails", "Plank", "Bandage", "Antibiotics", "Canned Beans", "Water Bottle", "Gas Can", "Car Battery", "Generator", "Shotgun Shells",
        "Crowbar", "Screwdriver", "Wrench", "Rope", "Tarp", "Bucket", "Lighter", "Flashlight", "Radio" }
    for _, n in ipairs(names) do out[#out + 1] = { name = n, full = "Base." .. string.gsub(n, " ", ""), cat = "Tool" } end
    return out
end

-- every state of the Admin tab: run(win, st) puts it on screen
function Q.bind(TC, AC, M, Adm)
    local ALL = {}
    for _, c in ipairs(Q.allCaps(Adm)) do ALL[c] = true end
    local function reset(win, st)
        TC.qaHold = true
        TC.qaRole, TC.qaLink, TC.qaGo, TC.qaStats = "admin", nil, true, true
        M.qaHold, M.qaLink, M.qaCaps = true, true, ALL
        M.qaRoles, M.qaItems, M.qaAllCaps = Q.roles(Adm), Q.items(), Q.allCaps(Adm)
        st.card, st.screen, st.pfind, st.ponly, st.msgRepeat, st.msgEvery = nil, nil, "", nil, nil, nil
        local t = TC.qaState(st)
        t.popup, t.confirm, t.flashText, t.busy = nil, nil, nil, nil
        M.rows, M.onlineN = Q.rows(), 6
        M.cards, M.logs, M.bans, M.mutes = Q.cards(), Q.logs(), Q.bans(), {}
        M.repeats = { { id = 1, text = "Trading post Saturday at the Muldraugh church. Bring what you can spare.", every = 60 } }
        M.gameIps, M.gameSids = {}, {}
        M.bump()
    end
    local out = {}
    local function S1(name, fn) out[#out + 1] = { name = name, tab = "admin", reset = reset, run = fn } end
    local function player(user, win, st) AC.qaOpen(win, st, "player", user) end

    -- the tab
    S1("home", function() end)
    S1("home-find", function(win, st) st.pfind = "kade"; M.bump() end)
    S1("home-nobody", function(win, st) st.pfind = "zzz"; M.bump() end)
    S1("home-online", function(win, st) st.ponly = true; M.bump() end)
    S1("home-repeat", function(win, st) st.msgRepeat, st.msgEvery = true, 30; M.bump() end)
    S1("home-no-repeats", function() M.repeats = {}; M.bump() end)
    S1("home-long", function()
        for i = 1, 60 do M.rows[#M.rows + 1] = { user = "player_with_a_long_name_" .. i, role = "user", on = false, warn = i % 3, lastT = NOW - i * 3600 } end
        M.bump()
    end)
    S1("home-empty", function() M.rows, M.onlineN = {}, 0; M.bump() end)
    S1("home-moderator", function() M.qaCaps = caps(MOD); M.bump() end)
    S1("home-gm", function() M.qaCaps = caps(GM); M.bump() end)
    S1("home-nothing", function() M.qaCaps = {}; M.bump() end)
    S1("home-no-part", function() M.qaLink = false; TC.qaLink = "off"; M.repeats = {}; M.bump() end)
    S1("home-flash", function(win, st) TC.qaFlash(st, ZeD.tr("UI_ZeD_Adm_SentOnce")) end)   -- (the card's own words, in the game's language)
    S1("tickets-screen", function(win, st) st.screen = "tickets" end)

    -- the player card
    S1("player", function(win, st) player("Kade_R", win, st) end)
    S1("player-self", function(win, st) player("Hermit", win, st) end)
    S1("player-offline", function(win, st) player("tjk", win, st) end)
    S1("player-banned", function(win, st) player("lootdrop99", win, st) end)
    S1("player-never-seen", function(win, st) player("Mags_77", win, st) end)
    S1("player-moderator", function(win, st) M.qaCaps = caps(MOD); player("Kade_R", win, st) end)
    S1("player-nothing", function(win, st) M.qaCaps = {}; player("Kade_R", win, st) end)
    S1("player-no-part", function(win, st) M.qaLink = false; TC.qaLink = "off"; player("Kade_R", win, st) end)
    S1("player-muted", function(win, st) M.mutes = { kade_r = true }; player("Kade_R", win, st) end)
    S1("player-all-skills", function(win, st) player("Kade_R", win, st); st.card.allSkills = true end)
    S1("player-kick", function(win, st) player("Kade_R", win, st); AC.qaPart(st, "kick") end)
    S1("player-ban", function(win, st) player("Kade_R", win, st); AC.qaPart(st, "ban") end)
    S1("player-ban-perm", function(win, st) player("Kade_R", win, st); AC.qaPart(st, "ban"); st.card.len = "perm"; st.card.banIp = true end)
    S1("player-warn", function(win, st) player("Kade_R", win, st); AC.qaPart(st, "warn") end)
    S1("player-warn-max", function(win, st) player("Kade_R", win, st); AC.qaPart(st, "warn"); st.card.warnN = 10 end)
    S1("player-role-powers", function(win, st) player("Kade_R", win, st); AC.qaPart(st, "role", "GM") end)
    S1("player-role-kept", function(win, st) player("Kade_R", win, st); AC.qaPart(st, "role", "GM"); st.card.keep.GodMod = true end)
    S1("player-role-down", function(win, st) player("Rosa", win, st); AC.qaPart(st, "role", "user") end)
    S1("player-flash", function(win, st) player("Kade_R", win, st); TC.qaFlash(st, ZeD.tr("UI_ZeD_Adm_Kicked", "Kade_R")) end)

    -- roles
    S1("roles", function(win, st) AC.qaOpen(win, st, "roles") end)
    S1("roles-nothing", function(win, st) M.qaCaps = caps({ "RolesRead" }); AC.qaOpen(win, st, "roles") end)
    S1("role-moderator", function(win, st) AC.qaOpen(win, st, "role", "moderator") end)
    S1("role-locked", function(win, st) AC.qaOpen(win, st, "role", "admin") end)
    S1("role-user", function(win, st) AC.qaOpen(win, st, "role", "user") end)
    S1("role-read-only", function(win, st) M.qaCaps = caps({ "RolesRead" }); AC.qaOpen(win, st, "role", "moderator") end)
    S1("role-changed", function(win, st) AC.qaOpen(win, st, "role", "moderator"); st.card.d.caps.AddItem = true; M.bump() end)
    S1("role-new", function(win, st) AC.qaOpen(win, st, "role", nil) end)
    S1("role-shut", function(win, st)
        AC.qaOpen(win, st, "role", "moderator")
        for _, g in ipairs(Adm.GROUPS) do st.card.closed[g.id] = true end
        M.bump()
    end)
    S1("role-confirm", function(win, st) AC.qaOpen(win, st, "role", "moderator"); TC.qaState(st).confirm = true end)

    -- bans
    S1("bans", function(win, st) AC.qaOpen(win, st, "bans") end)
    S1("bans-none", function(win, st) M.bans = {}; M.rows = {}; AC.qaOpen(win, st, "bans") end)
    S1("bans-game", function(win, st)
        M.gameSids = { { sid = "76561198000000044", reason = "From the game's own window." } }
        M.gameIps = { { ip = "203.0.113.7", user = "old_user", reason = "" } }
        AC.qaOpen(win, st, "bans")
    end)
    S1("bans-stayed", function(win, st) M.bans[2].stay = NOW; AC.qaOpen(win, st, "bans") end)
    S1("bans-confirm", function(win, st) AC.qaOpen(win, st, "bans"); TC.qaState(st).confirm = M.bans[1] end)
    S1("bans-no-power", function(win, st) M.qaCaps = caps({ "SeePlayersConnected" }); AC.qaOpen(win, st, "bans") end)
    S1("bans-no-part", function(win, st) M.qaLink = false; TC.qaLink = "off"; AC.qaOpen(win, st, "bans") end)

    -- spawn items
    S1("spawn", function(win, st) AC.qaOpen(win, st, "spawn") end)
    S1("spawn-find", function(win, st) AC.qaOpen(win, st, "spawn"); st.card.find = "ban" end)
    S1("spawn-none", function(win, st) AC.qaOpen(win, st, "spawn"); st.card.find = "zzzz" end)
    S1("spawn-picked", function(win, st) AC.qaOpen(win, st, "spawn"); st.card.item = Q.items()[1]; st.card.n = 5 end)
    S1("spawn-page-2", function(win, st) AC.qaOpen(win, st, "spawn"); st.card.page = 2 end)
    S1("spawn-to-player", function(win, st) AC.qaOpen(win, st, "spawn"); st.card.item = Q.items()[2]; st.card.to = "Kade_R" end)
    S1("spawn-no-part", function(win, st) M.qaLink = false; TC.qaLink = "off"; AC.qaOpen(win, st, "spawn"); st.card.item = Q.items()[1] end)
    S1("spawn-max", function(win, st) AC.qaOpen(win, st, "spawn"); st.card.item = Q.items()[1]; st.card.n = 100 end)
    return out
end

-- ---------------------------------------------------------------------------
if ZEDQA_CARDS_SIM then return Q end

local function say(s) print("ZEDQA mac " .. tostring(s)) end
local TC, AC, M, Adm = ZeD.TicketCards, ZeD.AdminCards, ZeD.Admin, ZeD.Adm
local states = Q.bind(TC, AC, M, Adm)
local WW = ZeD_WorldWindow.getWindow

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

for _, s in ipairs(states) do
    add(250, function() ZeD_WorldWindow.openTab(0, "admin") end)
    add(500, function()
        local win = WW()
        local st = win._adminTab
        if not st then say("no tab state for " .. s.name); return end
        s.reset(win, st)
        s.run(win, st)
    end)
    add(900, function()
        local win = WW()
        say(s.name .. ": " .. #ZeD.AdminTab.buildFocusables(win) .. " stops")
        pcall(function() getCore():TakeFullScreenshot("mac_" .. s.name .. ".png") end)
    end)
end
add(500, function()
    TC.qaHold, TC.qaRole, TC.qaGo, TC.qaStats, TC.qaLink = nil, nil, nil, nil, nil
    M.qaHold, M.qaLink, M.qaCaps, M.qaRoles, M.qaItems, M.qaAllCaps = nil, nil, nil, nil, nil, nil
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
