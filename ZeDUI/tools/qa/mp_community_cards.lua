-- ZeDUI/tools/qa/mp_community_cards.lua  (Nov 6 2026, QA): multiplayer Phase 5: every state of community's cards, from the mockup's
-- people and words (mockups/zed_community_v1.html), one picture each. grep "ZEDQA mcm".
-- Pictures: mcm_<state>.png, in the screenshots folder.
--   pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"
--   pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mp -Manifest ZeDUI/tools/qa/mp_community_cards.txt
-- It holds the model (ZeD.Community.qaHold) and puts the mockup's words in it, so nothing here reaches the server. mp_community.lua is
-- the run against the real server. For Deck, 720 and Large text run it again at those settings (zedqa_run -Width -Height; ZeD
-- setup's text size): the states are the same. community_cards_sim.lua loads this file too, for the same states with no game: it
-- sets ZEDQA_CARDS_SIM and gets the table.

local Q = {}

Q.MOTD = "Welcome to Knox Survivors. Day 12: the power's still on in Riverside. Trading post Saturday at the Muldraugh church."
Q.RULES = { "Be decent in chat. No slurs, no spam.", "Don't take from a claimed safehouse, or from a locked car that isn't yours.",
    "No killing on sight inside towns. Outside town, PvP is fair, with a warning first.", "Ask the admins (Server tab) for anything: bugs, griefing, getting stuck.",
    "Leave roads clear when you build." }
Q.POSTS = {
    { id = 3, text = "Trading post Saturday at the Muldraugh church, 7 PM. Bring what you can spare.", by = "Hermit", pin = true },
    { id = 1, text = "The server restarts every day at 4 AM Pacific. You'll get a 10-minute warning.", by = "Hermit", pin = true },
    { id = 2, text = "Vehicle claims are coming with the next update.", by = "Rosa", pin = false },
}

function Q.view(over)
    local v = { motd = Q.MOTD, appeal = "discord.gg/knoxsurvivors", changed = getTimestamp() - 86400, rev = 2, since = 1, rules = { n = #Q.RULES }, news = { n = #Q.POSTS } }
    for i, s in ipairs(Q.RULES) do v.rules[i] = { id = i, text = s, rev = (i == 2) and 2 or 1 } end
    for i, post in ipairs(Q.POSTS) do
        v.news[i] = { id = post.id, text = post.text, by = post.by, pin = post.pin, t = getTimestamp() - 86400 * i }
    end
    v.edit = { ask = true, reask = true, base = 4, by = "Hermit", at = getTimestamp() - 3600 }
    for k, s in pairs(over or {}) do
        if s == false then v[k] = nil else v[k] = s end
    end
    return v
end

function Q.manyRules(n, long)
    local rules = { n = n }
    for i = 1, n do
        rules[i] = { id = i, rev = (i % 3 == 0) and 2 or 1, text = long and string.rep("A long rule that says a great deal about very little. ", 3) or ("Rule number " .. i .. " of this server.") }
    end
    return rules
end

function Q.manyPosts(n)
    local news = { n = n }
    for i = 1, n do news[i] = { id = i, text = "Post " .. i .. ": " .. string.rep("something everyone should know ", 4), by = "Hermit", pin = i < 3, t = getTimestamp() - i * 3600 } end
    return news
end

-- every state; tab "server" or "admin"; run(win, st) puts it on screen. CM, M, TC, AC, A2 from Q.bind.
function Q.bind(CM, M, TC, AC, A2, S)
    local out = {}
    local ALL = {}
    for _, name in ipairs({ ZeD.Cm.CAP_RULES, ZeD.Cm.CAP_NEWS, "AnswerTickets", "RolesRead", "BanUnbanUser", "AddItem", "DisplayServerMessage" }) do ALL[name] = true end
    local NEWS = { [ZeD.Cm.CAP_NEWS] = true, AnswerTickets = true }
    local RULES = { [ZeD.Cm.CAP_RULES] = true }
    local function reset(caps)
        M.qaHold, M.qaLink, TC.qaHold, A2.qaHold, A2.qaLink = true, true, true, true, true
        A2.qaCaps = caps or ALL
        S.present, S.forceOff, S.cm = true, nil, true
        M.view = Q.view()
        M.bump()
    end
    local function state(name, tab, caps, run)
        out[#out + 1] = { name = name, tab = tab,
            reset = function(win, st)
                reset(caps)
                st.card = nil
                st.cmKey, st.homeKey = nil, nil
                local t = TC.qaState(st)
                t.confirm, t.busy, t.flashText = nil, nil, nil
            end,
            run = run }
    end
    local function server(name, run) state(name, "server", nil, run) end
    local function admin(name, caps, run) state(name, "admin", caps, run) end
    local function see(over)
        M.view = Q.view(over)
        M.bump()
    end
    local function card(st) return st.card end

    -- the Server tab
    server("tab", function() end)
    server("tab-no-news", function() see({ news = { n = 0 } }) end)
    server("tab-no-motd", function() see({ motd = "" }) end)
    server("tab-no-rules", function() see({ rules = { n = 0 } }) end)
    server("tab-empty", function() see({ motd = "", rules = { n = 0 }, news = { n = 0 } }) end)
    server("tab-many-posts", function() see({ news = Q.manyPosts(50) }) end)
    server("tab-long-motd", function() see({ motd = string.rep("A long message of the day that runs on. ", 15) }) end)
    server("tab-no-part", function() M.qaLink = false; M.bump() end)
    -- the rules card
    server("rules", function(win, st) CM.qaOpen(win, st, "rules") end)
    server("rules-no-appeal", function(win, st) see({ appeal = "" }); CM.qaOpen(win, st, "rules") end)
    server("rules-no-motd", function(win, st) see({ motd = "" }); CM.qaOpen(win, st, "rules") end)
    server("rules-many", function(win, st) see({ rules = Q.manyRules(30, true) }); CM.qaOpen(win, st, "rules") end)
    -- joining: the join card on the tab's panel; the window holds the same card
    server("join-first", function(win, st) see({ since = false }); CM.qaJoinCard(st) end)
    server("join-new", function(win, st) CM.qaJoinCard(st) end)
    server("join-new-many", function(win, st) see({ rules = Q.manyRules(12) }); CM.qaJoinCard(st) end)
    server("join-no-appeal", function(win, st) see({ appeal = "" }); CM.qaJoinCard(st) end)
    server("join-no-motd", function(win, st) see({ motd = "" }); CM.qaJoinCard(st) end)
    server("join-long", function(win, st) see({ rules = Q.manyRules(30, true), motd = string.rep("A long message of the day. ", 22) }); CM.qaJoinCard(st) end)

    -- a report from chat, on the Ask the admins card and on a ticket
    local rep = { who = "mike_d", n = 4, { who = "Kade_R", text = "anyone seen my truck? it was at the farm", t = "9:31" }, { who = "mike_d", text = "lol nope", t = "9:32", mark = true },
        { who = "Rosa", text = "Kade, file a ticket and we'll look at the logs.", t = "9:33" }, { who = "", text = "A server line with no sender.", t = "" } }
    Q.REP = rep
    server("ask-report", function(win, st) TC.openReport(win, st, rep) end)
    server("ask-report-no-part", function(win, st) TC.qaLink = "off"; TC.openReport(win, st, rep) end)

    -- Rules and news
    local function edit(win, st, over)
        if over then see(over) end
        CM.qaOpen(win, st, "edit")
    end
    admin("admin-row", nil, function() end)
    admin("admin-row-no-part", nil, function() M.qaLink = false; M.bump() end)
    admin("admin-row-gray", {}, function() end)
    admin("edit", nil, function(win, st) edit(win, st) end)
    admin("edit-dirty", nil, function(win, st) edit(win, st); Q.typed = { "cm:motd", "New words for today." } end)
    admin("edit-empty-rule", nil, function(win, st, t)
        edit(win, st)
        CM.qaAdd(win, st, TC.qaState(st), card(st))
    end)
    admin("edit-long-rule", nil, function(win, st) edit(win, st); Q.typed = { "cm:r1", string.rep("A rule that goes on and on. ", 6) } end)
    admin("edit-stale", nil, function(win, st) edit(win, st); card(st).stale = "Bea"; Q.typed = { "cm:motd", "Mine." } end)
    admin("edit-ask-off", nil, function(win, st) edit(win, st); card(st).ask = false end)
    admin("edit-no-rules", nil, function(win, st) edit(win, st, { rules = { n = 0 } }) end)
    admin("edit-rules-full", nil, function(win, st) edit(win, st, { rules = Q.manyRules(30) }) end)
    admin("edit-no-news", nil, function(win, st) edit(win, st, { news = { n = 0 } }) end)
    admin("edit-many-posts", nil, function(win, st) edit(win, st, { news = Q.manyPosts(50) }) end)
    admin("edit-post-typed", nil, function(win, st) edit(win, st); Q.typed = { "cm:post", "Trading post moved to Sunday." } end)
    admin("edit-confirm-delete", nil, function(win, st) edit(win, st); CM.qaConfirm(st, M.view.news[1]) end)
    admin("edit-moderator", NEWS, function(win, st) edit(win, st) end)
    admin("edit-rules-only", RULES, function(win, st) edit(win, st) end)
    admin("edit-frozen", nil, function(win, st) edit(win, st, { frozen = true }) end)
    return out
end

-- ---------------------------------------------------------------------------
if ZEDQA_CARDS_SIM then return Q end

local function say(s) print("ZEDQA mcm " .. tostring(s)) end
local CM, M, TC, AC, A2, S = ZeD.CommunityCards, ZeD.Community, ZeD.TicketCards, ZeD.AdminCards, ZeD.Admin, ZeD.ServerPart
local states = Q.bind(CM, M, TC, AC, A2, S)

local plan, i, t0 = {}, 1, getTimestampMs()
local function add(ms, fn) plan[#plan + 1] = { ms = ms, fn = fn } end
local function winOf(tab)
    if tab == "server" then return ZeD_CharacterWindow.getWindow() end
    return ZeD_WorldWindow.getWindow()
end
local function stOf(tab, win)
    if tab == "server" then return win._serverTab end
    return win._adminTab
end

for _, s in ipairs(states) do
    add(250, function()
        if s.tab == "server" then ZeD_CharacterWindow.openTab(0, "server") else ZeD_WorldWindow.openTab(0, "admin") end
    end)
    add(500, function()
        local win = winOf(s.tab)
        local st = stOf(s.tab, win)
        if not st then say("no tab state for " .. s.name); return end
        Q.typed = nil
        TC.qaLink = nil
        s.reset(win, st)
        s.run(win, st)
    end)
    add(300, function()
        if Q.typed then CM.qaType(winOf(s.tab), Q.typed[1], Q.typed[2]) end
    end)
    add(700, function()
        pcall(function() getCore():TakeFullScreenshot("mcm_" .. s.name .. ".png") end)
        say(s.name)
    end)
end
add(500, function()
    M.qaHold, M.qaLink, TC.qaHold, TC.qaLink, A2.qaHold, A2.qaLink, A2.qaCaps = nil, nil, nil, nil, nil, nil, nil
    for _, tab in ipairs({ "server", "admin" }) do
        local win = winOf(tab)
        local st = win and stOf(tab, win)
        if st then st.card = nil end
    end
    S.hello()
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
