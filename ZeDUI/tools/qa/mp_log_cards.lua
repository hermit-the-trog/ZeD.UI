-- ZeDUI/tools/qa/mp_log_cards.lua  (Nov 6 2026, QA): multiplayer Phase 4, every state of the Log card, from the mockup's lines
-- (mockups/zed_logs_v1.html), one picture each. grep "ZEDQA mlc". Pictures: mlc_<state>.png, in the screenshots folder.
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_log_cards.txt
-- It holds the traffic (ZeD.Logs.qaHold, ZeD.Admin.qaHold, ZeD.TicketCards.qaHold) and puts the mockup's data in the model, so
-- nothing here reaches the server's log. mp_log.lua is the run against the real server. For Deck, 720 and Large text run it again
-- at those settings (zedqa_run -Width -Height; ZeD setup's text size): the states are the same.
-- log_cards_sim.lua loads this file too, for the same states with no game: it sets ZEDQA_CARDS_SIM and gets the table.

local Q = {}

local function caps(list)
    local out = {}
    for _, c in ipairs(list) do out[c] = true end
    return out
end
local ALL = { "AnswerTickets", "TeleportToCoordinates", "CanSeePlayersStats", "PVPLogTool", "SeePlayersConnected" }

-- the mockup's lines, newest first, with the times it draws: ago is minutes before now
function Q.lines(now)
    local n = 0
    local function L(ago, k, who, what, target, text, x, y, extra)
        n = n + 1
        local r = { s = 500 - n, t = now - ago * 60, day = (ago < 1000) and 12 or 11, k = k, who = who, what = what, target = target, text = text, x = x, y = y, z = x and 0 or nil }
        for key, v in pairs(extra or {}) do r[key] = v end
        return r
    end
    return {
        L(8, "ticket", "Aretha", "filed", "#15", "STUCK", 6347, 5372),
        L(30, "admin", "Hermit", "teleport to", "Rosa", nil, 10650, 9970),
        L(36, "ticket", "Kade_R", "filed", "#14", "GRIEF", 6280, 5350),
        L(59, "ticket", "Rosa", "filed", "#13", "STUCK", 10650, 9970),
        L(74, "vehicle", "mike_d", "drive", "Kade_R", "CarNormal", 6284, 5351, { car = "CarNormal" }),
        L(81, "vehicle", "mike_d", "part", "Kade_R", "CarNormal/Battery", 6283, 5352, { car = "CarNormal", part = "Battery" }),
        L(84, "vehicle", "mike_d", "smash", "Kade_R", "CarNormal/WindowFrontLeft locked", 6283, 5352, { car = "CarNormal", part = "WindowFrontLeft", locked = true }),
        L(89, "pvp", "mike_d", "hit", "Mags_77", "Baseball Bat", 10790, 10120, { src = "pvp" }),
        L(115, "admin", "Rosa", "warning points", "mike_d", "1: Rammed a car into the gas station queue.", 10650, 9970),
        L(138, "faction", "Rosa", "member in", "Riverside Farmers"),
        L(160, "admin", "Hermit", "spawn", "Rosa", "10 x Base.Bandage to Rosa", 6330, 5390),
        L(206, "safehouse", "Aretha", "title Riverside Motel", nil, nil, 6347, 5372),
        L(1730, "admin", "Jules", "ban", "lootdrop99", "permanent: Scam spam in chat and tickets.", 8100, 11650),
        L(1850, "safehouse", "Kade_R", "claim", nil, nil, 6278, 5346),
    }
end

function Q.page(now, rows)
    rows = rows or Q.lines(now)
    return { rows = rows, n = #rows, all = 16, page = 1, pages = 1, names = { "Aretha", "Hermit", "Jules", "Kade_R", "mike_d", "Rosa" } }
end

function Q.ticket(now, placed)
    return { id = 14, kind = "GRIEF", author = "Kade_R", status = "Open", day = 12, filed = now - 36 * 60, updated = now - 36 * 60, source = "zed",
        place = placed ~= false and { x = 6280, y = 5350, z = 0 } or nil, near = placed ~= false and { n = 1, "Hermit" } or nil,
        thread = { n = 1, { who = "Kade_R", t = now - 36 * 60, text = "Someone pulled the engine out of my pickup at the farm." } }, notes = { n = 0 } }
end

-- every state: run(win, st) puts it on screen, after(win, st) runs once it has drawn
function Q.bind(TC, LC, Lm, M, C, S)
    local D = TC._D
    local function reset(win, st)
        local now = getTimestamp()
        TC.qaHold = true
        TC.qaRole, TC.qaLink, TC.qaGo, TC.qaStats = "admin", nil, true, true
        M.qaHold, M.qaLink, M.qaCaps = true, true, caps(ALL)
        Lm.qaHold, Lm.qaLink = true, true
        Lm.page, C.gameSilent = nil, nil
        st.card, st.screen = nil, nil
        local t = TC.qaState(st)
        t.popup, t.confirm, t.flashText, t.busy = nil, nil, nil, nil
        M.bump()
        Lm.bump()
    end
    local out = {}
    local function S1(name, fn, after) out[#out + 1] = { name = name, tab = "admin", reset = reset, run = fn, after = after } end
    local function log(win, st, page)
        LC.qaOpen(win, st)
        Lm.page = page or Q.page(getTimestamp())
        Lm.bump()
    end
    local function around(win, st, rows, missed)
        LC.qaOpen(win, st, 14)
        local now = getTimestamp()
        local p = Q.page(now, rows)
        p.around = { id = 14, x = 6280, y = 5350, from = now - 216 * 60, to = now - 6 * 60, filed = now - 36 * 60, missed = missed }
        Lm.page = p
        Lm.bump()
    end
    local function near(now)
        local rows = {}
        for _, r in ipairs(Q.lines(now)) do
            if r.x and math.abs(r.x - 6280) < 31 and math.abs(r.y - 5350) < 31 then rows[#rows + 1] = r end
        end
        return rows
    end
    local function missed(now) return { { who = "mike_d", from = now - 84 * 60, to = now - 74 * 60 } } end

    -- the tab
    S1("home-row", function() end)
    S1("home-no-part", function() Lm.qaLink = false; M.bump() end)
    S1("home-no-part-no-power", function() Lm.qaLink = false; M.qaCaps = {}; M.bump() end)
    S1("home-no-power", function() M.qaCaps = caps({ "SeePlayersConnected" }); M.bump() end)

    -- the card
    S1("log", function(win, st) log(win, st) end)
    S1("log-waiting", function(win, st) LC.qaOpen(win, st) end)
    for _, k in ipairs({ "admin", "safehouse", "faction", "vehicle", "pvp", "ticket" }) do
        S1("log-kind-" .. k, function(win, st)
            log(win, st)
            local rows = {}
            for _, r in ipairs(Lm.page.rows) do if r.k == k then rows[#rows + 1] = r end end
            Lm.page.rows, Lm.page.n = rows, #rows
            LC.qaSet(st, "kindF", k)
        end)
    end
    S1("log-who", function(win, st) log(win, st); LC.qaSet(st, "who", "mike_d") end)
    S1("log-who-long", function(win, st) log(win, st); LC.qaSet(st, "who", "player_with_a_very_long_name_indeed") end)
    S1("log-hour", function(win, st) log(win, st); LC.qaSet(st, "when", "hour") end)
    S1("log-3days", function(win, st) log(win, st); LC.qaSet(st, "when", "d3") end)
    S1("log-find", function(win, st) log(win, st); D.setField(win, "lfind", "Chevalier"); LC.qaSet(st, "find", "Chevalier") end)
    S1("log-nothing", function(win, st) log(win, st, Q.page(getTimestamp(), {})) end)
    S1("log-one-line", function(win, st)
        local rows = Q.lines(getTimestamp())
        log(win, st, Q.page(getTimestamp(), { rows[1] }))
    end)
    S1("log-container-on", function(win, st)
        local now = getTimestamp()
        local rows = Q.lines(now)
        table.insert(rows, 4, { s = 900, t = now - 188 * 60, day = 12, k = "container", who = "Rosa", what = "took", text = "2 x Canned Beans from Crate (reported by their game)", x = 6349, y = 5370, z = 0 })
        local p = Q.page(now, rows)
        p.opt = true
        log(win, st, p)
    end)
    S1("log-who-pick", function(win, st) log(win, st) end, function(win, st)
        for _, it in ipairs(TC.qaState(st).items or {}) do
            for _, c in ipairs(it.ctls or {}) do
                if c.id == "lwho" then c.run(win) end
            end
        end
    end)
    S1("log-flash", function(win, st) log(win, st); TC.qaFlash(st, ZeD.tr("UI_ZeD_Tk_Going", ZeD.Tk.whereText({ x = 6283, y = 5352 }))) end)
    S1("log-pages", function(win, st)
        local now = getTimestamp()
        local rows = {}
        for i = 1, 25 do rows[i] = { s = 900 - i, t = now - i * 60, day = 12, k = "vehicle", who = "mike_d", what = "eparts", target = "Kade_R", car = "CarNormal", x = 6283, y = 5352, z = 0 } end
        log(win, st, { rows = rows, n = 61, all = 200, page = 2, pages = 3 })
    end)
    S1("log-first-page", function(win, st)
        local now = getTimestamp()
        local p = Q.page(now)
        p.page, p.pages, p.n = 1, 2, 30
        log(win, st, p)
    end)
    S1("log-long-words", function(win, st)
        local now = getTimestamp()
        local name = string.rep("long_name_", 5)
        log(win, st, Q.page(now, {
            { s = 40, t = now - 60, day = 12, k = "admin", who = name, what = "ban", target = name, text = "d3: " .. string.rep("A reason that keeps on going and going. ", 5), x = 6280, y = 5350, z = 0 },
            { s = 39, t = now - 120, day = 12, k = "other", who = name, what = "ISTakeSomething", text = string.rep("[extra][x]", 9), src = "tap", lg = "LogExtender", by = name, x = 1, y = 2, z = 0 },
            { s = 38, t = now - 180, day = 12, k = "vehicle", who = name, what = "drive", target = name, car = "CarNormal", x = 6280, y = 5350, z = 0 },
        }))
        LC.qaPick(st, 40)
    end)
    -- a picked line
    S1("line-vehicle", function(win, st) log(win, st); LC.qaPick(st, 494) end)
    S1("line-pvp", function(win, st) log(win, st); LC.qaPick(st, 492) end)
    S1("line-ticket", function(win, st) log(win, st); LC.qaPick(st, 499) end)
    S1("line-no-place", function(win, st) log(win, st); LC.qaPick(st, 490) end)
    S1("line-server", function(win, st)
        local now = getTimestamp()
        log(win, st, Q.page(now, { { s = 77, t = now - 60, day = 12, k = "admin", who = ZeD.Tk.SYS, what = "ban lifted", target = "lootdrop99", text = "the time ran out" } }))
        LC.qaPick(st, 77)
    end)
    S1("line-hidden-place", function(win, st)
        local now = getTimestamp()
        log(win, st, Q.page(now, { { s = 78, t = now - 60, day = 12, k = "admin", who = "Hermit", what = "power on: GodMod", hid = true } }))
        LC.qaPick(st, 78)
    end)
    S1("line-tap", function(win, st)
        local now = getTimestamp()
        log(win, st, Q.page(now, { { s = 79, t = now - 60, day = 12, k = "vehicle", who = "Kade_R", what = "ISEnterVehicle", text = "[Base.CarNormal]", src = "tap", lg = "Vehicle", by = "griefer", x = 1, y = 2, z = 0 } }))
        LC.qaPick(st, 79)
    end)
    S1("line-no-teleport", function(win, st) TC.qaGo = false; log(win, st); LC.qaPick(st, 494) end)
    S1("line-no-stats", function(win, st) M.qaCaps = caps({ "AnswerTickets", "TeleportToCoordinates" }); log(win, st); LC.qaPick(st, 494) end)
    -- around a ticket
    S1("around", function(win, st) around(win, st, near(getTimestamp()), missed(getTimestamp())) end)
    S1("around-nobody-missed", function(win, st) around(win, st, near(getTimestamp()), {}) end)
    S1("around-three-missed", function(win, st)
        local now = getTimestamp()
        local m = missed(now)
        m[2] = { who = "player_with_a_very_long_name_indeed", from = now - 90 * 60, to = now - 80 * 60 }
        m[3] = { who = "Mags_77", from = now - 70 * 60, to = now - 70 * 60 }
        around(win, st, near(now), m)
    end)
    S1("around-waiting", function(win, st) LC.qaOpen(win, st, 14) end)
    S1("around-nothing", function(win, st) around(win, st, {}, {}) end)
    S1("around-line", function(win, st) around(win, st, near(getTimestamp()), missed(getTimestamp())); LC.qaPick(st, 494) end)
    S1("around-added", function(win, st)
        around(win, st, near(getTimestamp()), missed(getTimestamp()))
        LC.qaPick(st, 494)
        st.card.added[494] = true
        TC.qaFlash(st, ZeD.tr("UI_ZeD_Log_Added", 14))   -- (the card's own words, in the game's language)
    end)
    S1("around-cleared", function(win, st)
        around(win, st, near(getTimestamp()), {})
        LC.qaSet(st, "around", nil)
    end)
    S1("around-busy", function(win, st)
        around(win, st, near(getTimestamp()), missed(getTimestamp()))
        LC.qaPick(st, 494)
        TC.qaState(st).busy = true
    end)
    -- the ticket card's row
    S1("ticket-around", function(win, st)
        C.card = Q.ticket(getTimestamp())
        TC.openStaff(win, st, 14)
        C.seq = C.seq + 1
    end)
    S1("ticket-no-place", function(win, st)
        C.card = Q.ticket(getTimestamp(), false)
        TC.openStaff(win, st, 14)
        C.seq = C.seq + 1
    end)
    S1("ticket-no-log", function(win, st)
        Lm.qaLink = false
        C.card = Q.ticket(getTimestamp())
        TC.openStaff(win, st, 14)
        C.seq = C.seq + 1
    end)
    -- the Tickets queue's line
    S1("queue-silent", function(win, st)
        st.screen = "tickets"
        C.gameSilent = true
        C.queue = { rows = {}, n = 0, page = 1, pages = 1 }
        C.seq = C.seq + 1
    end)
    return out
end

-- ---------------------------------------------------------------------------
if ZEDQA_CARDS_SIM then return Q end

local function say(s) print("ZEDQA mlc " .. tostring(s)) end
local TC, LC, Lm, M, C, S = ZeD.TicketCards, ZeD.LogCards, ZeD.Logs, ZeD.Admin, ZeD.Tickets, ZeD.ServerPart
local states = Q.bind(TC, LC, Lm, M, C, S)
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
    add(400, function()
        local win = WW()
        if s.after and win._adminTab then s.after(win, win._adminTab) end
    end)
    add(600, function()
        local win = WW()
        say(s.name .. ": " .. #ZeD.AdminTab.buildFocusables(win) .. " stops")
        pcall(function() getCore():TakeFullScreenshot("mlc_" .. s.name .. ".png") end)
    end)
end
add(500, function()
    TC.qaHold, TC.qaRole, TC.qaGo, TC.qaStats, TC.qaLink = nil, nil, nil, nil, nil
    M.qaHold, M.qaLink, M.qaCaps = nil, nil, nil
    Lm.qaHold, Lm.qaLink, Lm.page = nil, nil, nil
    C.gameSilent = nil
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
