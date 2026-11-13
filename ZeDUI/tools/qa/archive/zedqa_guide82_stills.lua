-- ZeDUI/tools/qa/zedqa_guide82_stills.lua  (Nov 3 2026, QA; punch list 82, bug 2: Build's e87c0f62, a still from each clip)
-- With Video effects off every topic's clip box shows its still (ZeD/guide/<clip>.png); on swaps to the playing clip
-- at once and off swaps back. Then the director's pictures, in the gallery look: Skill Books with the rules (the
-- clip playing), Skill Books with its still (the director's own setting), another topic mid-clip, and Find narrowed to
-- "book". The Video effects option is put back. Shots zqa_g82s_<w>x<h>_*.png; grep "ZEDQA g8s".
local function say(s) print("ZEDQA g8s " .. tostring(s)) end
local G = ZeD and ZeD.Guide
if not G then say("ERR ZeD.Guide is not loaded"); say("DONE"); return end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() core:TakeFullScreenshot("zqa_g82s_" .. sw .. "x" .. sh .. "_" .. n .. ".png") end); say("shot " .. n) end
local function Wn() return G.get(0) end
local function topicBy(key) local w = Wn(); for _, t in ipairs((w and w.flat) or {}) do if t.titleKey == key then return t end end; return nil end
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local was = {}
local missing = {}

step(60, function()
    was.video = core:getOptionDoVideoEffects()
    core:setOptionDoVideoEffects(false)
    -- (Nov 9 2026: the default guide look is the book now; these pictures are the window, so the look is Simple for the run)
    local lopt = ZeD.Settings and ZeD.Settings.guideStyleOption
    if lopt then was.look = lopt:getValue(); pcall(function() lopt:setValue(2) end) end
    pcall(function() Mouse.setXY(sw - 4, sh - 4) end)
    if was.look then triggerEvent("OnKeyPressed", core:getKey(KeybindId.TOGGLE_SURVIVAL_GUIDE)) else G.open(0) end
end)
-- every topic, effects off: its still
local N = 0
step(20, function() N = #(Wn().flat or {}); say("topics " .. N) end)
for i = 1, 90 do
    step(3, function()
        local w = Wn(); local t = w.flat[i]
        if not t then return end
        w:choose(t.id, true)
    end)
    step(3, function()
        local w = Wn(); local t = w.flat[i]
        if not t then return end
        if not (w._still and not w._clip) then missing[#missing + 1] = tostring(t.title) .. " (" .. tostring(t.video) .. ")" end
    end)
end
step(5, function()
    check(N > 0 and #missing == 0, "effects off: every topic shows its still (" .. N .. " topics" .. (#missing > 0 and ("; none for " .. table.concat(missing, ", ")) or "") .. ")")
end)
-- the swap, on Skill Books
step(10, function() local t = topicBy("SurvivalGuide_skill_books_title"); if t then Wn():choose(t.id, true) end end)
step(20, function()
    local w = Wn()
    say("Skill Books still: " .. tostring(w.byId[w.sel] and w.byId[w.sel].video))
    check(w._still ~= nil, "Skill Books shows its still with effects off")
    core:setOptionDoVideoEffects(true)
end)
step(20, function()
    local w = Wn()
    check(w._clip ~= nil and w._still == nil, "effects on: the playing clip at once")
    core:setOptionDoVideoEffects(false)
end)
step(20, function()
    local w = Wn()
    check(w._clip == nil and w._still ~= nil, "effects off again: the still at once")
end)
-- the director's pictures
step(10, function() Wn().scroll = 0 end)
step(40, function() shot("1_skill_books_still") end)
step(10, function() core:setOptionDoVideoEffects(true) end)
step(150, function() shot("2_skill_books_rules_clip") end)
-- (Nov 11 2026) the Skill Books topic now ends on the occupation and trait tables: scroll to the first rules table (The Rules in
-- Numbers, the XP table) instead of the bottom
step(10, function()
    local w = Wn()
    local y = nil
    for _, it in ipairs((w._g and w._g.items) or {}) do if it.kind == "rules" then y = it.y; break end end
    w.scroll = math.min(w._maxS or 0, math.max(0, (y or (w._maxS or 0)) - ZeD.T.px(60)))
    say("2b: rules table at " .. tostring(y) .. ", scroll " .. tostring(w.scroll) .. " of " .. tostring(w._maxS))
end)
step(60, function() shot("2b_skill_books_rules_full"); Wn().scroll = 0 end)
step(10, function() local t = topicBy("SurvivalGuide_barricades_title") or topicBy("SurvivalGuide_vaulting_title"); if t then Wn():choose(t.id, true); say("mid-clip topic: " .. tostring(t.title)) end end)
step(150, function() shot("3_mid_clip") end)
step(10, function()
    local w = Wn()
    local t = topicBy("SurvivalGuide_skill_books_title"); if t then w:choose(t.id, true) end
    pcall(function() w._findField.input:setText("book") end)
    w._findField.onFilter(w._findField, "book")
end)
step(120, function() shot("4_find_book") end)
step(10, function()
    local w = Wn()
    pcall(function() w._findField.input:setText("") end)
    w._findField.onFilter(w._findField, "")
    w:close()
    core:setOptionDoVideoEffects(was.video)
    if was.look then pcall(function() ZeD.Settings.guideStyleOption:setValue(was.look) end) end
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    say("put back: video effects " .. tostring(was.video))
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
-- (the guide pauses the game: the steps run on OnRenderTick)
Events.OnRenderTick.Add(tick)
say("start")
