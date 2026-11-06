-- ZeDUI/tools/qa/mp_claim_cards.lua  (Nov 5 2026, QA): multiplayer Phase 3: every state of the safehouse, faction and wars
-- cards, from the mockup's people (mockups/zed_safehouse_faction_v1.html), one picture each. grep "ZEDQA mcc".
-- Pictures: mcc_<state>.png, in the screenshots folder.
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_claim_cards.txt
-- It holds the model (ZeD.Claims.qaHold) and puts the mockup's people in it, so nothing here reaches the game. mp_claims.lua is
-- the run against the real server. For Deck, 720 and Large text run it again at those settings (zedqa_run -Width -Height; ZeD
-- setup's text size): the states are the same. claim_cards_sim.lua loads this file too, for the same states with no game: it
-- sets ZEDQA_CARDS_SIM and gets the table.

local Q = {}

Q.ONLINE = { "Rosa", "Kade_R", "Mags_77", "mike_d", "tjk" }

function Q.players(extra)
    local out = {}
    for _, n in ipairs(extra or Q.ONLINE) do out[#out + 1] = { user = n, name = n } end
    return out
end

function Q.rules(over)
    local r = { player = true, admin = false, claimDay = 5, anyBuilding = false, trespass = false, loot = false, fire = false, respawn = true,
        removal = 72, ownerOff = false, faction = true, factionDay = 3, tagNeeds = 3, war = true, warDelay = 600, warLength = 3600 }
    for k, v in pairs(over or {}) do r[k] = v end
    return r
end

function Q.safe(me, role, over)
    local v = { id = "s1", title = "Riverside Motel", owner = (role == "owner") and me or "Rosa", x = 6347, y = 5372, location = "Riverside", created = "Nov 2, 1993",
        respawn = true, isOwner = role == "owner", manage = role == "owner", names = (role == "owner") and { me, "Rosa", "tjk" } or { "Rosa", me, "tjk" } }
    for k, s in pairs(over or {}) do v[k] = s end
    return v
end

function Q.faction(me, role, over)
    local v = { name = "Riverside", tag = "RVF", owner = (role == "owner") and me or "Kade_R", isOwner = role == "owner", manage = role == "owner",
        canTag = role == "owner", hasRoom = true, color = { r = 0.353, g = 0.604, b = 0.290 }, showTag = true, pvp = false,
        names = (role == "owner") and { me, "Kade_R", "Rosa" } or { "Kade_R", me, "Rosa" } }
    for k, s in pairs(over or {}) do v[k] = s end
    if v.noTag then v.tag = nil end
    return v
end

-- every state: tab "server"; run(win, st) puts it on screen. CC, C, S and me from Q.bind.
function Q.bind(CC, C, S, me, TC)
    local out = {}
    local function reset()
        C.qaHold, TC.qaHold = true, true
        C.qaCaps, C.qaTaken, C.qaCanCreate, C.qaHours = {}, { ["Muldraugh Mall"] = true, MALL = true }, true, 288
        C.qaOthers = { safe = { Kade_R = "Rosewood" }, fac = { Mags_77 = "Muldraugh Mall", mike_d = "Muldraugh Mall" } }
        C.rules = Q.rules()
        C.safe, C.fac, C.wars, C.invites, C.info = nil, nil, {}, {}, {}
        C.sent = { safe = {}, fac = {} }
        C.claim = { ok = true, lines = { ZeD.tr("UI_ZeD_Cl_ClaimYes", "6402 x 5410") }, at = "x", t = getTimestampMs() + 600000 }
        C.seq = C.seq + 1
        S.present, S.forceOff = true, nil
        if ZeD.ServerTab then
            ZeD.ServerTab.players = Q.players()
            ZeD.ServerTab.askedAt = getTimestampMs() + 600000
        end
    end
    local function S1(name, run)
        out[#out + 1] = { name = name, tab = "server",
            reset = function(win, st)
                reset()
                st.card = nil
                local t = TC.qaState(st)
                t.confirm, t.busy, t.flashText = nil, nil, nil
                t.cl = {}
            end,
            run = run }
    end
    local function info(h) C.info = { at = getTimestampMs(), safe = { visitedH = h } } end
    local function both(role1, role2)
        C.safe, C.fac = Q.safe(me, role1), Q.faction(me, role2)
        C.seq = C.seq + 1
    end

    -- the Server tab
    S1("tab-owner", function() both("owner", "owner") end)
    S1("tab-member", function() both("member", "member") end)
    S1("tab-none", function() end)
    S1("tab-reasons", function()
        C.claim = { lines = { getText("IGUI_Safehouse_AlreadyHaveSafehouse"), getText("IGUI_Safehouse_SomeoneInside"), getText("IGUI_Safehouse_NotHouse") }, at = "x", t = getTimestampMs() + 600000 }
    end)
    S1("tab-outdoors", function() C.claim = { lines = { getText("IGUI_Safehouse_NotInside") }, at = "x", t = getTimestampMs() + 600000 } end)
    S1("tab-taken", function() C.claim = { lines = { ZeD.tr("UI_ZeD_Cl_ClaimTaken", "Mags_77") }, at = "x", t = getTimestampMs() + 600000 } end)
    S1("tab-off", function()
        C.rules = Q.rules({ player = false, admin = false })
        C.claim = { lines = { ZeD.tr("UI_ZeD_Cl_ClaimsOff") }, at = "x", t = getTimestampMs() + 600000 }
    end)
    S1("tab-adminonly", function()
        C.rules = Q.rules({ player = false, admin = true })
        C.claim = { lines = { getText("UI_ServerOption_AdminSafehouse_tooltip") }, at = "x", t = getTimestampMs() + 600000 }
    end)
    S1("tab-faction-early", function() C.qaCanCreate = false end)
    S1("tab-faction-off", function() C.rules = Q.rules({ faction = false }); C.qaCanCreate = false end)
    S1("tab-note-faction", function() C.invites = { { kind = "fac", host = "Mags_77", name = "Muldraugh Mall", user = me } } end)
    S1("tab-note-safe", function() C.fac = Q.faction(me, "member"); C.invites = { { kind = "safe", host = "Rosa", name = "Riverside Motel", user = me } } end)
    S1("tab-note-two", function()
        C.invites = { { kind = "fac", host = "Mags_77", name = "Muldraugh Mall", user = me }, { kind = "safe", host = "Rosa", name = "Riverside Motel", user = me } }
    end)
    S1("tab-keep-low", function() both("owner", "owner"); info(61) end)
    S1("tab-wars", function()
        both("owner", "owner")
        C.wars = { { id = 1, attacker = "Kade_R", defender = me, state = "Claimed", time = "00:04:30", title = "Riverside Motel" } }
    end)
    S1("tab-wars-off", function() both("owner", "owner"); C.rules = Q.rules({ war = false }) end)
    S1("tab-flash", function(win, st) both("owner", "owner"); TC.qaFlash(st, ZeD.tr("UI_ZeD_Cl_Released")) end)

    -- the safehouse card
    local function safe(win, st, role, over)
        C.safe = Q.safe(me, role, over)
        C.seq = C.seq + 1
        CC.qaOpen(win, st, "safe")
    end
    S1("safe-owner", function(win, st) safe(win, st, "owner") end)
    S1("safe-owner-keep", function(win, st) info(10); safe(win, st, "owner") end)
    S1("safe-owner-keep-low", function(win, st) info(61); safe(win, st, "owner") end)
    S1("safe-owner-keep-soon", function(win, st) info(71.5); safe(win, st, "owner") end)
    S1("safe-member", function(win, st) safe(win, st, "member") end)
    S1("safe-respawn-off", function(win, st) C.rules = Q.rules({ respawn = false }); safe(win, st, "owner") end)
    S1("safe-respawn-unset", function(win, st) safe(win, st, "owner", { respawn = false }) end)
    S1("safe-rules-loose", function(win, st)
        C.rules = Q.rules({ trespass = true, loot = true, fire = true, respawn = false, ownerOff = true, anyBuilding = true, claimDay = 0 })
        safe(win, st, "owner")
    end)
    S1("safe-row", function(win, st) safe(win, st, "owner"); CC.qaRow(st, "safe", "Rosa") end)
    S1("safe-row-offline", function(win, st) safe(win, st, "owner", { names = { me, "Rosa", "Aunt_May" } }); CC.qaRow(st, "safe", "Aunt_May") end)
    S1("safe-pending", function(win, st) C.sent.safe = { Mags_77 = 1 }; safe(win, st, "owner") end)
    S1("safe-pending-nopart", function(win, st) S.forceOff = true; C.sent.safe = { Mags_77 = 1 }; safe(win, st, "owner") end)
    S1("safe-drawer", function(win, st) safe(win, st, "owner"); CC.qaDrawer(st, "safe") end)
    S1("safe-drawer-empty", function(win, st) ZeD.ServerTab.players = Q.players({ "Rosa" }); safe(win, st, "owner"); CC.qaDrawer(st, "safe") end)
    S1("safe-drawer-wait", function(win, st) ZeD.ServerTab.players = {}; safe(win, st, "owner"); CC.qaDrawer(st, "safe") end)
    S1("safe-edit", function(win, st) safe(win, st, "owner"); Q.typed = { "safeTitle", "The Riverside Motel" } end)
    S1("safe-edit-empty", function(win, st) safe(win, st, "owner"); Q.typed = { "safeTitle", "   " } end)
    S1("safe-edit-long", function(win, st) safe(win, st, "owner"); Q.typed = { "safeTitle", "A title that runs on past the limit" } end)
    S1("safe-confirm-release", function(win, st) safe(win, st, "owner"); CC.qaConfirm(st, { act = "release" }) end)
    S1("safe-confirm-quit", function(win, st) safe(win, st, "member"); CC.qaConfirm(st, { act = "quit" }) end)
    S1("safe-confirm-remove", function(win, st) safe(win, st, "owner"); CC.qaRow(st, "safe", "Rosa"); CC.qaConfirm(st, { act = "remove", kind = "safe", who = "Rosa" }) end)
    S1("safe-confirm-owner", function(win, st) safe(win, st, "owner"); CC.qaRow(st, "safe", "Rosa"); CC.qaConfirm(st, { act = "owner", kind = "safe", who = "Rosa" }) end)
    S1("safe-flash", function(win, st) safe(win, st, "owner"); TC.qaFlash(st, ZeD.tr("UI_ZeD_Cl_Claimed")) end)
    S1("safe-many", function(win, st)
        local names = { me }
        for i = 1, 30 do names[#names + 1] = "survivor_" .. i end
        safe(win, st, "owner", { names = names })
    end)
    S1("safe-long-words", function(win, st)
        safe(win, st, "member", { title = "AVeryLongTitleWithNoSpacesAtAll", owner = "averyveryverylongusernamehere", names = { "averyveryverylongusernamehere", me } })
    end)

    -- the faction card
    local function fac(win, st, role, over)
        C.fac = Q.faction(me, role, over)
        C.seq = C.seq + 1
        CC.qaOpen(win, st, "faction")
    end
    S1("fac-owner", function(win, st) fac(win, st, "owner") end)
    S1("fac-member", function(win, st) fac(win, st, "member") end)
    S1("fac-few", function(win, st) fac(win, st, "owner", { canTag = false, hasRoom = false, noTag = true, names = { me } }) end)
    S1("fac-member-few", function(win, st) fac(win, st, "member", { hasRoom = false, noTag = true, names = { "Kade_R", me } }) end)
    S1("fac-notag", function(win, st) fac(win, st, "owner", { noTag = true }) end)
    S1("fac-tag-hidden", function(win, st) fac(win, st, "owner", { showTag = false }) end)
    S1("fac-pvp", function(win, st) fac(win, st, "owner", { pvp = true }) end)
    S1("fac-row", function(win, st) fac(win, st, "owner"); CC.qaRow(st, "fac", "Kade_R") end)
    S1("fac-pending", function(win, st) C.sent.fac = { tjk = 1 }; fac(win, st, "owner") end)
    S1("fac-drawer", function(win, st) fac(win, st, "owner"); CC.qaDrawer(st, "fac") end)
    S1("fac-edit-name", function(win, st) fac(win, st, "owner"); Q.typed = { "facName", "Riverfolk" } end)
    S1("fac-edit-short", function(win, st) fac(win, st, "owner"); Q.typed = { "facName", "Ri" } end)
    S1("fac-edit-long", function(win, st) fac(win, st, "owner"); Q.typed = { "facName", "Riverside Farmers" } end)
    S1("fac-edit-taken", function(win, st) fac(win, st, "owner"); Q.typed = { "facName", "Muldraugh Mall" } end)
    S1("fac-edit-tag", function(win, st) fac(win, st, "owner"); Q.typed = { "facTag", "rvr" } end)
    S1("fac-edit-tag-taken", function(win, st) fac(win, st, "owner"); Q.typed = { "facTag", "MALL" } end)
    S1("fac-edit-tag-long", function(win, st) fac(win, st, "owner"); Q.typed = { "facTag", "RVFARM" } end)
    S1("fac-confirm-disband", function(win, st) fac(win, st, "owner"); CC.qaConfirm(st, { act = "disband" }) end)
    S1("fac-confirm-leave", function(win, st) fac(win, st, "member"); CC.qaConfirm(st, { act = "leave" }) end)
    S1("fac-confirm-remove", function(win, st) fac(win, st, "owner"); CC.qaRow(st, "fac", "Rosa"); CC.qaConfirm(st, { act = "remove", kind = "fac", who = "Rosa" }) end)
    S1("fac-confirm-owner", function(win, st) fac(win, st, "owner"); CC.qaRow(st, "fac", "Rosa"); CC.qaConfirm(st, { act = "owner", kind = "fac", who = "Rosa" }) end)

    -- create a faction
    S1("new-empty", function(win, st) CC.qaOpen(win, st, "newfac") end)
    S1("new-short", function(win, st) CC.qaOpen(win, st, "newfac"); Q.typed = { "newFac", "Ri" } end)
    S1("new-typed", function(win, st) CC.qaOpen(win, st, "newfac"); Q.typed = { "newFac", "Riverside" } end)
    S1("new-taken", function(win, st) CC.qaOpen(win, st, "newfac"); Q.typed = { "newFac", "Muldraugh Mall" } end)
    S1("new-nodays", function(win, st) C.rules = Q.rules({ factionDay = 0 }); CC.qaOpen(win, st, "newfac") end)

    -- wars
    local function w(state, attacker, defender, time)
        return { id = 1, attacker = attacker, defender = defender, state = state, time = time or "00:04:30", title = "Riverside Motel" }
    end
    S1("wars-none", function(win, st) CC.qaOpen(win, st, "wars") end)
    S1("wars-off", function(win, st) C.rules = Q.rules({ war = false }); CC.qaOpen(win, st, "wars") end)
    S1("wars-defender", function(win, st) C.wars = { w("Claimed", "Kade_R", me) }; CC.qaOpen(win, st, "wars") end)
    S1("wars-attacker", function(win, st) C.wars = { w("Claimed", me, "Rosa") }; CC.qaOpen(win, st, "wars") end)
    S1("wars-accepted", function(win, st) C.wars = { w("Accepted", "Kade_R", me) }; CC.qaOpen(win, st, "wars") end)
    S1("wars-started", function(win, st) C.wars = { w("Started", "Kade_R", me) }; CC.qaOpen(win, st, "wars") end)
    S1("wars-refused", function(win, st) C.wars = { w("Refused", "Kade_R", me) }; CC.qaOpen(win, st, "wars") end)
    S1("wars-admin", function(win, st) C.qaCaps = { CanGoInsideSafehouses = true }; C.wars = { w("Started", "Kade_R", "Rosa") }; CC.qaOpen(win, st, "wars") end)
    S1("wars-confirm-accept", function(win, st)
        local row = w("Claimed", "Kade_R", me)
        C.wars = { row }
        CC.qaOpen(win, st, "wars")
        CC.qaConfirm(st, { act = "war", row = row, state = "Accepted", from = "tk:back" })
    end)
    S1("wars-confirm-end", function(win, st)
        C.qaCaps = { CanGoInsideSafehouses = true }
        local row = w("Started", "Kade_R", me)
        C.wars = { row }
        CC.qaOpen(win, st, "wars")
        CC.qaConfirm(st, { act = "war", row = row, state = "Ended", from = "tk:back" })
    end)
    S1("wars-several", function(win, st)
        local list = {}
        for i = 1, 6 do
            local r = w((i % 2 == 0) and "Claimed" or "Started", "attacker_" .. i, me)
            r.id = i
            list[i] = r
        end
        C.wars = list
        CC.qaOpen(win, st, "wars")
    end)
    return out
end

-- ---------------------------------------------------------------------------
if ZEDQA_CARDS_SIM then return Q end

local function say(s) print("ZEDQA mcc " .. tostring(s)) end
local CC, C, S, TC = ZeD.ClaimCards, ZeD.Claims, ZeD.ServerPart, ZeD.TicketCards
local p = getPlayer()
local states = Q.bind(CC, C, S, p:getUsername(), TC)
local CW = ZeD_CharacterWindow.getWindow

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end

for _, s in ipairs(states) do
    add(250, function() ZeD_CharacterWindow.openTab(0, "server") end)
    add(500, function()
        local win = CW()
        local st = win._serverTab
        if not st then say("no tab state for " .. s.name); return end
        Q.typed = nil
        s.reset(win, st)
        s.run(win, st)
    end)
    add(300, function()
        if Q.typed then CC.qaType(CW(), Q.typed[1], Q.typed[2]) end
    end)
    add(700, function()
        say(s.name .. ": " .. #ZeD.ServerTab.buildFocusables(CW()) .. " stops")
        pcall(function() getCore():TakeFullScreenshot("mcc_" .. s.name .. ".png") end)
    end)
end
add(500, function()
    C.qaHold, C.qaCaps, C.qaTaken, C.qaCanCreate, C.qaHours, C.qaOthers = nil, nil, nil, nil, nil, nil
    TC.qaHold = nil
    C.claim, C.info = nil, {}
    ZeD.ServerTab.askedAt = 0
    local win = CW()
    if win and win._serverTab then win._serverTab.card = nil end
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
    local ok, e = pcall(st.fn)
    if not ok then say("ERR step " .. (i - 1) .. ": " .. tostring(e)) end
end
Events.OnTick.Add(drive)
