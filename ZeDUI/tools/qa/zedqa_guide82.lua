-- ZeDUI/tools/qa/zedqa_guide82.lua  (Nov 3 2026, QA; punch list 82, the survival guide's Simple look, Build's b641524e)
-- ZeD_SurvivalGuide.lua in game: the hooks (the game's F1 handler off, ZeD's on, openEntry and the Help wheel point at
-- ZeD's window), F1 and Escape open and close it, the pause, the topics read from the game, Find, folding, Previous /
-- Next and the wrap, every section's clip (video effects on) and still (off), scrolling, The Rules in Numbers on
-- Skill Books, the start-up box, F1 from the Skills and Craft tabs, the forage window's entry, the controller's paths.
-- Pictures: Skill Books with the rules, a topic mid-clip, Find narrowed. Settings put back. grep "ZEDQA g82".
local function say(s) print("ZEDQA g82 " .. tostring(s)) end
local G = ZeD and ZeD.Guide
if not G then say("ERR ZeD.Guide is not loaded"); say("DONE"); return end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_g82_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function Wn() return G.get(0) end
local function open() local w = Wn(); return w ~= nil and w:isReallyVisible() end
local function f1() triggerEvent("OnKeyPressed", core:getKey(KeybindId.TOGGLE_SURVIVAL_GUIDE)) end
local function speed() local s = -1; pcall(function() s = getGameSpeed() end); return s end
local function vanillaShown() return SurvivalGuide and SurvivalGuide.instance and SurvivalGuide.instance:isVisible() or false end
local function topicBy(key) local w = Wn(); for _, t in ipairs((w and w.flat) or {}) do if t.titleKey == key then return t end end; return nil end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local was = {}

step(60, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    was.startup, was.video = core:getOptionShowSurvivalGuide(), core:getOptionDoVideoEffects()
    say("before: start-up box " .. tostring(was.startup) .. ", video effects " .. tostring(was.video))
    check(_G._zedGuideHooked == true, "ZeD's guide hooked the game's entry points")
    check(SurvivalGuide and SurvivalGuide.onKeyPressed ~= nil and SurvivalGuide.openEntry ~= nil, "SurvivalGuide.onKeyPressed and openEntry are ZeD's")
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
end)
-- ---- F1 opens, pauses; F1 again closes, runs
step(20, function() f1() end)
step(30, function()
    check(open(), "F1 opens ZeD's guide")
    check(not vanillaShown(), "the game's own guide does not open")
    check(speed() == 0, "the game is paused while it is open (speed " .. speed() .. ")")
    local w = Wn()
    local nt = 0
    for _, s in ipairs(w.sections or {}) do nt = nt + #s.topics end
    say("sections " .. #(w.sections or {}) .. ", topics " .. nt .. "; first topic " .. tostring(w.flat[1] and w.flat[1].title))
    check(#(w.sections or {}) >= 10 and nt == #w.flat, "the game's sections and topics are read (" .. #(w.sections or {}) .. " sections, " .. nt .. " topics)")
end)
step(20, function() f1() end)
step(30, function()
    check(not open(), "F1 again closes it")
    check(speed() == 1, "the game runs again (speed " .. speed() .. ")")
end)
-- ---- Escape and the Escape taker
step(20, function() f1() end)
step(20, function() local w = Wn(); if w then w:onKeyPress(Keyboard.KEY_ESCAPE) end end)
step(20, function() check(not open() and speed() == 1, "Escape closes it and the game runs") end)
step(20, function() f1() end)
step(20, function() check(ZeD.EscapeTakers and ZeD.EscapeTakers.guide and ZeD.EscapeTakers.guide() == true, "ZeD's Escape taker closes it") end)
step(20, function() check(not open(), "closed by the Escape taker") end)
-- ---- the Help wheel and openEntry
step(20, function() pcall(function() ISDPadWheels.showSurvGuide(0) end) end)
step(30, function()
    check(open() and not vanillaShown(), "the Help wheel opens ZeD's guide")
    Wn():close()
end)
step(20, function() pcall(function() SurvivalGuide.openEntry(SurvivalGuideEntry.FORAGING) end) end)
step(30, function()
    local w = Wn()
    local t = w and w.byId[w.sel]
    say("openEntry(FORAGING) -> " .. tostring(t and t.titleKey))
    check(open() and t and t.id == tostring(SurvivalGuideEntry.FORAGING), "the forage window's entry opens Foraging")
end)
-- ---- Skill Books: the rules
step(20, function() local t = topicBy("SurvivalGuide_skill_books_title"); if t then Wn():choose(t.id, true) end end)
step(30, function()
    local r = G.Rules.SurvivalGuide_skill_books_title and G.Rules.SurvivalGuide_skill_books_title()
    if not check(r ~= nil, "Skill Books has The Rules in Numbers") then return end
    say("rules columns: " .. table.concat(r.cols, " | "))
    for i, row in ipairs(r.rows) do say("rules row " .. i .. ": " .. table.concat(row, " | ")) end
    check(#r.rows == 5, "five volumes")
    check(r.rows[1][2] ~= "" and r.rows[5][2] ~= "", "each volume's levels shown (" .. tostring(r.rows[1][2]) .. " ... " .. tostring(r.rows[5][2]) .. ")")
    check(r.rows[1][3] == "x3" and r.rows[5][3] == "x16", "the main column runs x3 to x16 (" .. tostring(r.rows[1][3]) .. ", " .. tostring(r.rows[5][3]) .. ")")
    local last = r.cols[#r.cols] or ""
    check(#r.cols >= 4 and last:find("Aiming") and last:find("Reloading") and last:find("Long Blade"), "the last column names Aiming, Reloading and Long Blade (" .. last .. ")")
    check(r.rows[1][#r.cols] == "x1.5" and r.rows[5][#r.cols] == "x8", "and runs x1.5 to x8 (" .. tostring(r.rows[1][#r.cols]) .. ", " .. tostring(r.rows[5][#r.cols]) .. ")")
    local w = Wn()
    local has = false
    for _, it in ipairs((w._g and w._g.items) or {}) do if it.kind == "rules" then has = true end end
    check(has, "the rules box is laid out in the topic")
end)
step(10, function() local w = Wn(); w.scroll = w._maxS or 0 end)
step(40, function() shot("1_skill_books_rules"); local w = Wn(); check((w._maxS or 0) > 0 and w._g.textNeedsBar, "the long topic scrolls with a bar (" .. tostring(w._maxS) .. " px)") end)
step(10, function() local w = Wn(); w.scroll = 0 end)
-- ---- Find
step(10, function() local w = Wn(); w._findField.onFilter(w._findField, "vault") end)
step(20, function()
    local w = Wn(); local n, names = 0, {}
    for _, r in ipairs(w._g.rows) do if r.topic then n = n + 1; names[#names + 1] = r.topic.title end end
    say("Find vault: " .. table.concat(names, ", "))
    check(n >= 1 and n < #w.flat, "Find narrows the list (\"vault\": " .. n .. ")")
end)
step(10, function() local w = Wn(); w._findField.onFilter(w._findField, "book") end)
step(30, function()
    local w = Wn(); local n = 0
    for _, r in ipairs(w._g.rows) do if r.topic then n = n + 1 end end
    check(n >= 1 and n < #w.flat, "Find narrows the list (\"book\": " .. n .. ")")
    pcall(function() w._findField.input:setText("book") end)
end)
step(30, function() shot("2_find_book") end)
step(10, function() local w = Wn(); pcall(function() w._findField.input:setText("") end); w._findField.onFilter(w._findField, "") end)
step(20, function()
    local w = Wn(); local n = 0
    for _, r in ipairs(w._g.rows) do if r.topic then n = n + 1 end end
    check(n == #w.flat or w._g.listNeedsBar, "Find cleared: the whole list back (" .. n .. " rows in view of " .. #w.flat .. ")")
end)
-- ---- folding
step(10, function()
    local w = Wn()
    for _, r in ipairs(w._g.rows) do if r.section and not was.fold then was.fold = r.section.id; w:pressRow(r) end end
end)
step(20, function()
    local w = Wn(); local shown = 0
    for _, r in ipairs(w._g.rows) do if r.topic and r.topic.section.id == was.fold then shown = shown + 1 end end
    check(w.closed[was.fold] and shown == 0, "a section folds")
    for _, r in ipairs(w._g.rows) do if r.section and r.section.id == was.fold then w:pressRow(r) end end
end)
step(20, function()
    local w = Wn(); local shown = 0
    for _, r in ipairs(w._g.rows) do if r.topic and r.topic.section.id == was.fold then shown = shown + 1 end end
    check(not w.closed[was.fold] and shown > 0, "and opens again (" .. shown .. " topics)")
end)
-- ---- Previous / Next walk every topic and wrap
step(10, function()
    local w = Wn(); w:choose(w.flat[1].id, true)
    local seen, ok = {}, true
    for i = 2, #w.flat do w:step(1); if w.sel ~= w.flat[i].id then ok = false end; seen[w.sel] = true end
    check(ok, "Next walks every topic in the game's order (" .. #w.flat .. ")")
    w:step(1)
    check(w.sel == w.flat[1].id, "Next wraps from the last to the first")
    w:step(-1)
    check(w.sel == w.flat[#w.flat].id, "Previous wraps from the first to the last")
    local g = w._g
    check(g.foot[1] and g.foot[1].id == "startup" and g.foot[2].id == "prev" and g.foot[3].id == "next", "the band: the start-up box, Previous, Next")
end)
-- ---- clips: every section's first topic with a clip, video effects on, then off
local clipTopics = {}
step(10, function()
    local w = Wn()
    for _, s in ipairs(w.sections) do for _, t in ipairs(s.topics) do if t.video and t.video ~= "" then clipTopics[#clipTopics + 1] = t; break end end end
    say("sections with a clip: " .. #clipTopics)
    core:setOptionDoVideoEffects(true)
end)
for i = 1, 16 do
    step(10, function() local t = clipTopics[i]; if t then Wn():choose(t.id, true) end end)
    step(45, function()
        local t = clipTopics[i]; if not t then return end
        local w = Wn()
        local ok = w._clip ~= nil
        if not ok then say("clip: " .. tostring(t.titleKey) .. " " .. tostring(t.video) .. " -> none") end
        check(ok, "the clip plays: " .. tostring(t.title) .. " (" .. tostring(t.video) .. ")")
        if i == 3 then shot("3_clip_" .. tostring(t.titleKey):gsub("SurvivalGuide_", ""):gsub("_title", "")) end
    end)
end
step(10, function() core:setOptionDoVideoEffects(false); local w = Wn(); w._clipFor = nil; if clipTopics[1] then w:choose(clipTopics[1].id, true) end end)
step(30, function()
    local w = Wn()
    check(w._clip == nil and w._still ~= nil, "video effects off: the still shows instead (" .. tostring(clipTopics[1] and clipTopics[1].thumb) .. ")")
    shot("4_still")
    core:setOptionDoVideoEffects(was.video); w._clipFor = nil
end)
-- ---- the start-up box
step(10, function()
    local w = Wn()
    local before = core:getOptionShowSurvivalGuide()
    w:pressFoot(w._g.foot[1])
    check(core:getOptionShowSurvivalGuide() == not before, "the start-up box ticks and clears the game's option")
    w:pressFoot(w._g.foot[1])
    check(core:getOptionShowSurvivalGuide() == before, "and back")
end)
step(10, function() Wn():close() end)
-- ---- F1 on the Skills tab, the Craft tab
step(20, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(0) end
end)
step(30, function()
    local cw = ZeD_CharacterWindow.getWindow()
    local strip = cw and cw._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:skills" then strip:onMouseDown(z.x + 2, z.y + 2) end end
end)
step(60, function() say("context with Skills: " .. tostring(G.contextTopicKey())); f1() end)
step(30, function()
    local w = Wn(); local t = w and w.byId[w.sel]
    check(open() and t and t.titleKey == "SurvivalGuide_skill_books_title", "F1 on the Skills tab opens Skill Books (" .. tostring(t and t.titleKey) .. ")")
    f1()
end)
step(30, function()
    local cw = ZeD_CharacterWindow.getWindow()
    local strip = cw and cw._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:loot" then strip:onMouseDown(z.x + 2, z.y + 2) end end
    local ww = ZeD_WorldWindow.getWindow()
    local st = ww and ww._actionTabStrip
    local ids = {}
    for _, z in ipairs(st and st._hitZones or {}) do ids[#ids + 1] = z.id; if z.id == "tab:craft" then st:onMouseDown(z.x + 2, z.y + 2) end end
    say("World tabs: " .. table.concat(ids, ", "))
end)
step(60, function() say("context with Craft: " .. tostring(G.contextTopicKey())); f1() end)
step(30, function()
    local w = Wn(); local t = w and w.byId[w.sel]
    check(open() and t and t.titleKey == "SurvivalGuide_crafting_menu_title", "F1 on the Craft tab opens Crafting Menu (" .. tostring(t and t.titleKey) .. ")")
end)
-- ---- the controller (the window's own handlers, as the pad drives them)
step(10, function()
    local w = Wn(); w:choose(w.flat[1].id, true); w.zone = "list"; w.listFocus = w.sel
    w:onJoypadDirDown(); w:onJoypadDirDown()
    check(w.sel ~= w.flat[1].id, "D-pad down walks the list (" .. tostring(w.byId[w.sel] and w.byId[w.sel].title) .. ")")
    w:onJoypadDown(Joypad.AButton)
    check(w.zone == "text", "A on a topic goes into its text")
    w:onJoypadDirLeft()
    check(w.zone == "list", "left goes back to the list")
    w:onJoypadDown(Joypad.AButton)
    local s0 = w.scroll
    w:onJoypadDirDown()
    check(w.scroll > s0 or w.zone == "foot", "down in the text scrolls it (or reaches the band)")
    w.zone = "list"
    local sel = w.sel
    w:onJoypadDown(Joypad.RBumper)
    check(w.sel ~= sel, "RB turns to the next topic")
    w:onJoypadDown(Joypad.LBumper)
    check(w.sel == sel, "LB turns back")
    w.zone = "foot"; w.footFocus = 3
    w:onJoypadDirLeft()
    check(w.footFocus == 2, "on the band, left moves from Next to Previous")
    w:onJoypadDirUp()
    check(w.zone == "list", "up leaves the band for the list")
    w:onJoypadDown(Joypad.BButton)
end)
step(20, function() check(not open() and speed() == 1, "B closes it and the game runs") end)
-- ---- put back
step(20, function()
    core:setOptionShowSurvivalGuide(was.startup); core:setOptionDoVideoEffects(was.video)
    pcall(function() core:saveOptions() end)
    if open() then Wn():close() end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("put back: the start-up box " .. tostring(was.startup) .. ", video effects " .. tostring(was.video))
    say(string.format("RESULT %d pass, %d fail", passes, fails))
    say("DONE")
end)

local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
-- (the guide pauses the game: the steps run on OnRenderTick, which draws on while paused)
Events.OnRenderTick.Add(tick)
say("start")
