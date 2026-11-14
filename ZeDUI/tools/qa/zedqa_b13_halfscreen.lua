-- ZeDUI/tools/qa/zedqa_b13_halfscreen.lua  (Nov 13 2026, QA; beta 13 split view, item 4 of batch 1)
-- QA's stand-in for a second player: ZeD.splitWindows on and ZeD._qaRect[0] = the left half of the screen. Both windows
-- are laid out again (ZeD_Window.resetLayout) and must fit inside the left half; then each window's drawer is opened
-- (a tab), so the drawer pushes stay inside the half too. A shot of each step. Everything is put back.
-- grep "ZEDQA half".
local function say(s) print("ZEDQA half " .. tostring(s)) end
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local cw, ww = CWm and CWm.getWindow(), WWm and WWm.getWindow()
if not (cw and ww and ZeD.playerRect and ZeD.screenOf) then say("ERR windows or split helpers missing"); say("DONE"); return end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_half_" .. n .. ".png") end) end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local half = math.floor(sw / 2)
local wasSplit, wasRect = ZeD.splitWindows, ZeD._qaRect
local function rect(w) return w:getX(), w:getY(), w:getWidth(), w:getHeight() end
local function inside(w, label)
    local x, y, ww_, hh = rect(w)
    say(label .. " at " .. x .. "," .. y .. " " .. ww_ .. "x" .. hh .. " (the half: 0,0 " .. half .. "x" .. sh .. ")")
    return x >= 0 and y >= 0 and x + ww_ <= half + 1 and y + hh <= sh + 1
end
local function tabClick(strip, id) for _, z in ipairs(strip and strip._hitZones or {}) do if z.id == "tab:" .. id then strip:onMouseDown(z.x + 2, z.y + 2); return true end end; return false end

local Q, qi, qc = {}, 1, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
step(5, function()
    ZeD.splitWindows = true
    ZeD._qaRect = { [0] = { 0, 0, half, sh } }
    local a, b, c, d = ZeD.screenOf(cw)
    say("screenOf(Character) " .. a .. "x" .. b .. " at " .. c .. "," .. d .. "; playerNum " .. tostring(cw.playerNum) .. "/" .. tostring(ww.playerNum))
    check(a == half and b == sh, "the Character window's screen is the left half")
    pcall(function() ZeD_Window.resetLayout() end)
end)
step(60, function()
    check(inside(cw, "Character"), "the Character window fits inside the left half")
    check(inside(ww, "World"), "the World window fits inside the left half")
    shot("1_layout")
    tabClick(cw._tabStripPanel, "health"); tabClick(ww._actionTabStrip, "maps")
end)
step(60, function()
    check(inside(cw, "Character with its drawer"), "with the Health drawer open, the Character window stays in the half")
    check(inside(ww, "World with its drawer"), "with the Maps drawer open, the World window stays in the half")
    shot("2_drawers")
end)
step(10, function()
    tabClick(cw._tabStripPanel, "loot"); tabClick(ww._actionTabStrip, "loot")
    ZeD.splitWindows, ZeD._qaRect = wasSplit, wasRect
    pcall(function() ZeD_Window.resetLayout() end)
end)
step(60, function()
    local x, _, w = rect(ww)
    check(x + w > half, "switch off again: the World window is back on the whole screen (" .. x .. "+" .. w .. ")")
    shot("3_back")
    say(fails == 0 and "all checks passed" or (fails .. " failed")); say("DONE")
end)
local function tick()
    local s = Q[qi]
    if not s then Events.OnTick.Remove(tick); return end
    qc = qc + 1
    if qc < s.n then return end
    qi, qc = qi + 1, 0
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
