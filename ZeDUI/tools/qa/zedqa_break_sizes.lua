-- ZeDUI/tools/qa/zedqa_break_sizes.lua  (Oct 31 2026, QA; the director: "Try to break things. Click
-- repeatedly, make things too small and too big.")
-- Every tab of both windows drawn with the windows far too small (1 x 1: the window's own minimum must
-- hold) and far too big (twice the screen), at UI scale 0.5 and 2.0 (the menu's range), with Large text; then the windows
-- opened and shut every tick, the tabs switched every tick, an item card opened and shut every tick.
-- After each part: the window sizes it ended at, and whether ZeD's safe mode stepped aside (the runner
-- counts the game's own errors per script). Shots zqa_brk_<part>.png. Puts back the scale, the text size,
-- the layout and the tabs. grep "ZEDQA brk".
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local p = getPlayer(); local pn = p:getPlayerNum()
local Sc = ZeD.Scale
local function say(s) print("ZEDQA brk " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_brk_" .. n .. ".png") end) end
local function CW() return CWm.getWindow() end
local function WW() return WWm.getWindow() end
local function tripped() local ok, v = pcall(function() return ZeD.Safe.on() end); return ok and v == true end
local function tabsOf(strip) local out = {}; for _, z in ipairs((strip and strip._hitZones) or {}) do if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = z end end; return out end
local function sizes() local c, w = CW(), WW(); return string.format("char %sx%s world %sx%s", c and math.floor(c:getWidth()) or "-", c and math.floor(c:getHeight()) or "-", w and math.floor(w:getWidth()) or "-", w and math.floor(w:getHeight()) or "-") end
local function open() if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(pn) end end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function part(name)
    step(2, function()
        local t = tripped()
        check(not t, name .. ": ZeD still in charge (safe mode did not step aside); " .. sizes())
        if t then pcall(function() ZeD.Safe.reset() end); open() end
        shot(name)
    end)
end
-- every tab of both windows, one per few frames (each is drawn at least twice)
-- (Oct 31 2026, break-it B1: the walk goes by the windows' own tab lists; a tab scrolled out of
-- sight is brought in with the strip's own wheel first, as a player would. By hit-zone position
-- alone, the tabs below a scrolling strip were never reached.)
local function nthTab(which, win, i)
    local M = (which == "c") and CWm or WWm
    local n = 0
    for _, t in ipairs(M.TABS or {}) do
        if M.isTabVisible(t, win) then n = n + 1; if n == i then return "tab:" .. t.id end end
    end
end
local function zoneOf(strip, id) for _, z in ipairs(tabsOf(strip)) do if z.id == id then return z end end end
local function walkTabs(label, perTab)
    step(2, function() open() end)
    for _, which in ipairs({ "c", "w" }) do
        for i = 1, 12 do
            step(4, function()
                local win = (which == "c") and CW() or WW()
                local strip = win and ((which == "c") and win._tabStripPanel or win._actionTabStrip)
                local id = win and nthTab(which, win, i)
                if id and strip and not zoneOf(strip, id) then pcall(function() strip:onMouseWheel(-12) end) end
            end)
            step(4, function()
                local win = (which == "c") and CW() or WW()
                local strip = win and ((which == "c") and win._tabStripPanel or win._actionTabStrip)
                local id = win and nthTab(which, win, i)
                if id and strip and not zoneOf(strip, id) then pcall(function() strip:onMouseWheel(12) end) end
            end)
            step(4, function()
                local win = (which == "c") and CW() or WW()
                local strip = win and ((which == "c") and win._tabStripPanel or win._actionTabStrip)
                local id = win and nthTab(which, win, i)
                local z = id and strip and zoneOf(strip, id)
                if z then strip:onMouseDown(z.x + 2, z.y + 2) end
            end)
            if perTab then step(25, function()
                local win = (which == "c") and CW() or WW()
                if win and win._activeTab then shot(label .. "_" .. which .. "_" .. tostring(win._activeTab) .. "_" .. i) end
            end) end
        end
    end
    part(label)
end
local function setSize(wf, hf)
    step(2, function()
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        for _, win in ipairs({ CW(), WW() }) do
            if win then
                win:setWidth(math.max(1, math.floor(sw * wf))); win:setHeight(math.max(1, math.floor(sh * hf)))
                pcall(function() win:onResize() end)
            end
        end
    end)
end
local function scale(v) step(2, function() Sc.override = v; Sc.refresh(); ZeD.applyTheme() end) end
local sizeWas
step(5, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    open(); sizeWas = ZeD.currentSize
    say("start: " .. sizes() .. " scale " .. tostring(Sc.root and Sc.root()))
end)
-- 1. far too small, then far too big, at the run's scale
setSize(0, 0); step(20, function() say("after 1x1: " .. sizes()) end)
walkTabs("tiny")
setSize(2, 2); step(20, function() say("after twice the screen: " .. sizes()) end)
walkTabs("huge")
step(5, function() pcall(ZeD_Window.resetLayout) end)
-- 2. the smallest and the largest UI scale, small and large text
scale(0.5); step(60, function() pcall(ZeD_Window.resetLayout) end)
walkTabs("scale050")
setSize(0, 0); walkTabs("scale050_tiny")
scale(2.0); step(60, function() pcall(ZeD_Window.resetLayout) end)
walkTabs("scale200")
setSize(2, 2); walkTabs("scale200_huge")
step(2, function() ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, "large") end)
step(30, function() pcall(ZeD_Window.resetLayout) end)
walkTabs("scale200_large", true)
scale(0.5); step(60, function() pcall(ZeD_Window.resetLayout) end)
walkTabs("scale050_large", true)
scale(nil); step(2, function() ZeD.applyTheme(ZeD.currentBase, ZeD.currentAccent, sizeWas) end)
step(60, function() pcall(ZeD_Window.resetLayout) end)
-- 3. rapid: the windows opened and shut every tick (40 times)
for _ = 1, 40 do step(1, function() pcall(function() CWm.toggleBothPaired(pn) end) end) end
step(20, function() open() end)
part("rapid_windows")
-- 4. rapid: every tab of both windows, one a tick, three rounds
for _ = 1, 3 do
    for _, which in ipairs({ "c", "w" }) do
        for i = 1, 12 do
            step(1, function()
                local win = (which == "c") and CW() or WW()
                local strip = win and ((which == "c") and win._tabStripPanel or win._actionTabStrip)
                local z = tabsOf(strip)[i]
                if z then strip:onMouseDown(z.x + 2, z.y + 2) end
            end)
        end
    end
end
part("rapid_tabs")
-- 5. rapid: an item card opened and shut every tick (the first ten items, 40 times)
local items = {}
step(2, function()
    local s = CW()._tabStripPanel
    for _, z in ipairs(tabsOf(s)) do if z.id == "tab:loot" then s:onMouseDown(z.x + 2, z.y + 2) end end
    local list = p:getInventory():getItems()
    for i = 0, math.min(9, list:size() - 1) do items[#items + 1] = list:get(i) end
end)
for k = 1, 40 do
    step(1, function()
        local c = CW(); local cp = c and c._mainContent
        if not (cp and #items > 0) then return end
        local sel = cp._selectedItems or {}
        for key in pairs(sel) do sel[key] = nil end
        if k % 2 == 1 then sel[items[(k % #items) + 1]] = true end
        cp._selectedItems = sel
        pcall(function() c._updateDrawer(cp) end)
    end)
end
part("rapid_cards")
-- put back
step(5, function()
    local c = CW(); local cp = c and c._mainContent
    if cp and cp._selectedItems then for key in pairs(cp._selectedItems) do cp._selectedItems[key] = nil end; pcall(function() c._updateDrawer(cp) end) end
    pcall(ZeD_Window.resetLayout)
    for _, pair in ipairs({ { CW(), "_tabStripPanel" }, { WW(), "_actionTabStrip" } }) do
        local win, s = pair[1], pair[1] and pair[1][pair[2]]
        for _, z in ipairs(tabsOf(s)) do if z.id == "tab:loot" then s:onMouseDown(z.x + 2, z.y + 2) end end
    end
end)
step(20, function() say("end: " .. sizes()); say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE") end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
