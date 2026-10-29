-- ZeDUI/tools/qa/zedqa_skills_ab.lua  (Oct 29 2026, the drawing-cost pass)
-- Before / after captures of the Skills tab for a drawing change that must keep the same
-- pixels: the Character window on Skills, at Small then Large text, each at the top of the
-- scroll and at its bottom, and once with the first two training groups of the left column
-- unfolded. Screenshots zqa_<prefix>_<n>.png (prefix from the global SKAB_PREFIX, default
-- "sk": run once with the old file in place as "sko", once with the new as "skn", then
-- compare the pairs with an image diff). In game on the ZeD-QA save after zedqa_prelude.lua.
-- Puts the text size, the scroll and the unfolded groups back. grep "ZEDQA skab".
local PFX = SKAB_PREFIX or "sk"
local p = getPlayer()
local pn = p:getPlayerNum()
local function say(s) print("ZEDQA skab " .. tostring(s)) end
local steps, tick = {}, 0
local function at(n, fn) steps[#steps + 1] = { n = n, fn = fn } end
local function cw() return ZeD_CharacterWindow.getWindow() end
-- a tab's strip zone clicked, as the mouse would (the same as zedqa_large.lua)
local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_" .. PFX .. "_" .. n .. ".png") end); say("shot zqa_" .. PFX .. "_" .. n .. ".png") end
-- the Skills scroll (set up by the first render) sent to its top or bottom
local function scrollTo(pos)
    local w = cw(); local s = w and w._skillsScroll
    if s and s.setScrollPos then s:setScrollPos(pos) end
    say(string.format("scroll %.1f visible=%s", pos, tostring(s and s.visible)))
end
-- the first two training groups of the left column unfolded (their keys as the tab makes them)
local unfolded = {}
local function unfold(on)
    local w = cw(); if not w then return end
    w._trainingExpanded = w._trainingExpanded or {}
    local tr = w._trainingCache or {}
    if on then
        for i = 1, math.min(2, #tr) do
            local key = "col1_" .. tostring(tr[i].label)
            w._trainingExpanded[key] = true
            unfolded[#unfolded + 1] = key
        end
        say("unfolded " .. #unfolded .. " training groups")
    else
        for _, key in ipairs(unfolded) do w._trainingExpanded[key] = nil end
        unfolded = {}
    end
end
local orig = ZeD.currentSize
at(2, function() if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end end)
at(20, function() tab("skills") end)
at(80, function() scrollTo(0) end)
at(100, function() shot("1_small_top") end)
at(102, function() scrollTo(1) end)
at(122, function() shot("2_small_bottom") end)
at(124, function() scrollTo(0); unfold(true) end)
at(150, function() shot("3_small_unfolded") end)
at(152, function() unfold(false); ZeD.applyTheme(nil, nil, "large") end)
at(200, function() tab("skills"); scrollTo(0) end)
at(240, function() shot("4_large_top") end)
at(242, function() scrollTo(1) end)
at(262, function() shot("5_large_bottom") end)
at(264, function() scrollTo(0); ZeD.applyTheme(nil, nil, orig) end)
at(300, function() tab("loot"); say("size back to " .. tostring(orig) .. " | DONE") end)
local function onTick()
    tick = tick + 1
    for _, s in ipairs(steps) do if s.n == tick then local ok, e = pcall(s.fn); if not ok then say("ERR " .. s.n .. " " .. tostring(e)) end end end
    if tick > 305 then Events.OnTick.Remove(onTick) end
end
Events.OnTick.Add(onTick)
say("start prefix=" .. PFX)
