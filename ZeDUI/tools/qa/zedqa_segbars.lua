-- ZeDUI/tools/qa/zedqa_segbars.lua  (Oct 30 2026)
-- The segmented fill bars (punch list 22, director: "keeping it 93; the segments
-- help info at a glance"): every fill bar is ten separate segments, lit or dark,
-- one per whole tenth, and pointing at it puts the exact value in the help line.
-- Drawn on a stand-in panel that records its rects (nothing on screen, nothing
-- to put back):
--   1. ZeD.Atoms.drawFillBar lights 6 at 64%, 0 at 4%, 10 at 100%, 0 at 0, 7 at
--      70% and 3 at 30% (the floating-point tenths), always ten cells in all, the
--      lit ones in the bar's colour;
--   2. at its narrowest (ZeD.Atoms.fillBarMinW) the ten cells are still distinct:
--      none overlaps, a gap between each, all inside the frame;
--   3. a skill at level 5 lights 5 (ZeD.Atoms.drawSegFill, one per level), and the
--      Skills tab's help words ("Fitness 5, 40% to level 6"; "Fitness 10" at the top);
--   4. the pointer on a bar: the help line says "Condition 64%" (drawFillBar with a
--      label), "64%" (no label) and "Bite 64%" (ZeD.Molecules.drawStatBarRow);
--      the pointer off it: nothing. Skipped while the controller's cues show (the
--      pointer's hover is off then).
-- Copy to Zomboid/Lua/zedqa.lua, bump zedqa.go; grep "ZEDQA segb"; ends
-- "ZEDQA segb DONE".
local function say(s) print("ZEDQA segb " .. tostring(s)) end
local fails = 0
local function check(ok, msg) if not ok then fails = fails + 1; say("FAIL " .. msg) end; return ok end

local A, M, T = ZeD.Atoms, ZeD.Molecules, ZeD.T
local LIT = { r = 0.123, g = 0.456, b = 0.789, a = 1 }   -- (a colour nothing else draws in)

-- the stand-in: a ZeD window to the help line (ZeD.Help.set stamps _helpText), the pointer where we put it
local P = { isZeDWindow = true, mx = -1000, my = -1000, rects = {} }
function P:getMouseX() return self.mx end
function P:getMouseY() return self.my end
function P:drawRect(x, y, w, h, a, r, g, b) local t = self.rects; t[#t + 1] = { x = x, y = y, w = w, h = h, r = r, g = g, b = b } end
function P:drawRectBorder() end
function P:drawText() end
function P:drawTextRight() end
local function reset(mx, my) P.rects = {}; P._helpText = nil; P.mx = mx or -1000; P.my = my or -1000 end
local function same(c, r) return math.abs(c.r - r.r) < 1e-6 and math.abs(c.g - r.g) < 1e-6 and math.abs(c.b - r.b) < 1e-6 end
-- the cells drawn: lit (the test colour) and dark (T.surf3), left to right
local function cells()
    local lit, dark, all = 0, 0, {}
    for _, r in ipairs(P.rects) do
        if same(LIT, r) then lit = lit + 1; all[#all + 1] = r
        elseif same(T.surf3, r) then dark = dark + 1; all[#all + 1] = r end
    end
    table.sort(all, function(a, b) return a.x < b.x end)
    return lit, dark, all
end

local cuesOn = false
do
    local F = ZeD.Input and ZeD.Input.Focus
    cuesOn = F and F.cuesVisible and F.cuesVisible() or false
end

local function run()
    local H = T.fillBarH
    -- 1. the lit counts at known values
    local cases = { { 0.64, 6 }, { 0.04, 0 }, { 1.0, 10 }, { 0, 0 }, { 0.7, 7 }, { 0.3, 3 }, { 0.999, 9 } }
    for _, c in ipairs(cases) do
        reset()
        A.drawFillBar(P, 0, 0, 200, c[1], false, LIT, H)
        local lit, dark = cells()
        check(lit == c[2], string.format("%.3f lights %d, not %d", c[1], lit, c[2]))
        check(lit + dark == 10, string.format("%.3f draws %d cells, not 10", c[1], lit + dark))
        check(A.fillSegsLit(c[1]) == c[2], string.format("fillSegsLit(%.3f) is %d, not %d", c[1], A.fillSegsLit(c[1]), c[2]))
        say(string.format("%.3f -> %d lit, %d dark", c[1], lit, dark))
    end
    -- 2. ten distinct cells at the narrowest bar, and at the list rows' compact height
    local minW = A.fillBarMinW()
    reset()
    A.drawFillBar(P, 0, 0, minW, 0.5, false, LIT, A.fillBarCompactH())
    local lit, dark, all = cells()
    local bw = T.line(T.borderW)
    check(lit == 5 and dark == 5, string.format("at %d px: %d lit, %d dark (5 and 5 wanted)", minW, lit, dark))
    for i, r in ipairs(all) do
        check(r.w >= 1, string.format("at %d px cell %d is %d wide", minW, i, r.w))
        if all[i + 1] then check(all[i + 1].x >= r.x + r.w + 1, string.format("at %d px cells %d and %d touch", minW, i, i + 1)) end
    end
    if all[1] and all[#all] then
        check(all[1].x >= bw and all[#all].x + all[#all].w <= minW - bw, string.format("at %d px a cell crosses the frame", minW))
    end
    say(string.format("narrowest %d px (scale %.2f): %d cells, %d to %d px wide", minW, T.scale or 0, #all,
        all[1] and all[1].w or -1, all[#all] and all[#all].w or -1))
    -- 3. a skill at level 5, one segment per level; the Skills tab's help words
    reset()
    A.drawSegFill(P, 0, 0, A.rowBarW(), A.fillBarCompactH(), 10, 5, LIT)
    lit, dark = cells()
    check(lit == 5 and dark == 5, string.format("level 5: %d lit, %d dark", lit, dark))
    if ZeD.SkillsTab and ZeD.SkillsTab.barHelp then
        local h5 = ZeD.SkillsTab.barHelp({ name = "Fitness", level = 5, xpProgress = 0.4 })
        check(h5 == ZeD.tr("UI_ZeD_Skills_BarHelp", "Fitness", 5, "40%", 6), "level 5 help reads " .. tostring(h5))
        local h10 = ZeD.SkillsTab.barHelp({ name = "Fitness", level = 10, xpProgress = 1 })
        check(h10 == ZeD.tr("UI_ZeD_Bar_Help", "Fitness", 10), "level 10 help reads " .. tostring(h10))
        say("skill help: " .. tostring(h5) .. " | " .. tostring(h10))
    else
        check(false, "ZeD.SkillsTab.barHelp is missing")
    end
    -- 4. the help line under the pointer
    if cuesOn then
        say("hover checks skipped: the controller's cues are showing")
    else
        local want = ZeD.tr("UI_ZeD_Bar_Help", "Condition", "64%")
        reset(100, math.floor(H / 2))
        local hov = A.drawFillBar(P, 0, 0, 200, 0.64, true, nil, H, "Condition")
        check(hov == true, "drawFillBar does not say the pointer is on it")
        check(P._helpText == want, "help line " .. tostring(P._helpText) .. ", not " .. want)
        say("hover: " .. tostring(P._helpText))
        reset(100, math.floor(H / 2))
        A.drawFillBar(P, 0, 0, 200, 0.64, true, nil, H)
        check(P._helpText == "64%", "no label: help line " .. tostring(P._helpText))
        reset(300, math.floor(H / 2))
        A.drawFillBar(P, 0, 0, 200, 0.64, true, nil, H, "Condition")
        check(P._helpText == nil, "pointer off the bar: help line " .. tostring(P._helpText))
        -- the stat bar row: its bar at the right, 4 units in
        local w = 300
        local barW = math.max(A.fillBarMinW(), math.min(A.rowBarW(), math.floor(w * 0.4)))
        local rowH = math.max(ZeD.TM:getFontHeight(T.fontF3), ZeD.TM:getFontHeight(T.fontF2)) + T.px(8)
        reset(w - T.px(4) - math.floor(barW / 2), math.floor(rowH / 2))
        M.drawStatBarRow(P, 0, 0, w, "64%", "Bite", 0.64, LIT)
        lit = cells()
        check(lit == 6, "stat bar row at 64% lights " .. tostring(lit))
        check(P._helpText == ZeD.tr("UI_ZeD_Bar_Help", "Bite", "64%"), "stat bar row help line " .. tostring(P._helpText))
        say("stat row hover: " .. tostring(P._helpText))
    end
end

local ok, err = pcall(run)
if not ok then check(false, "error: " .. tostring(err)) end
say(fails == 0 and "PASS" or ("FAILS " .. fails))
say("DONE")
