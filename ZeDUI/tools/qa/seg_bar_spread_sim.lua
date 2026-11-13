-- ZeDUI/tools/qa/seg_bar_spread_sim.lua  (Nov 10 2026, Build; the fill bars' cells spread evenly)
-- QA's Mac run measured the Cond column: end cells 5 and 6 px beside 3 px middle ones at 1x, 9 beside 5 at 1.75x. The
-- director: "Keep 10, spread evenly". With no game running, the real Atoms.lua's drawSegBar (framed) paints each bar on
-- a pixel row, through the gap texture's path (seg.png's row: a gap lit, the cell clear, repeated) and through the
-- plain rects. For 5 and 10 cells, inside widths 20 to 400 px, gaps of 1 and 2 px, 0, 3 and all cells lit, it checks:
-- the right number of cells, every cell within a pixel of the others, the cells meeting the frame at both ends, and at
-- most seven draws a bar on the texture path. STATUS (punch list 143): the status bars' five cells, rounded up, and their
-- color by cells lit.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/seg_bar_spread_sim.lua
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]seg_bar_spread_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; if failed <= 20 then print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end end
end
local stub; stub = setmetatable({}, { __index = function() return stub end, __call = function() return stub end })
function require() end
ZeD = { T = { px = function(v) return v end, line = function(v) return v or 1 end, borderW = 1, borderS = { r = 0, g = 0, b = 0 },
              base = { r = 0.5, g = 0.5, b = 0.5 }, accent = { r = 1, g = 0, b = 0 } } }
setmetatable(_G, { __index = function() return stub end })
local f, err = loadfile(ROOT .. "42/media/lua/client/ZeD/Atoms.lua")
local ok, e = pcall(f or error, err)
setmetatable(_G, nil)
check("Atoms.lua loads on the stubs", f and ok, err or e)
local A = ZeD.Atoms
local row, draws = {}, 0
local jo = { DrawSubTextureRGBA = function(_, tex, sx, sy, sw, sh, x, y, w, h)
    draws = draws + 1
    local cellW = sy % 64 + 1; local gap = math.floor(sy / 64) + 1
    for t = 0, w - 1 do if t % (cellW + gap) < gap then row[x + t] = "g" end end end }
local panel = { drawRect = function(_, x, y, ww, h, a, r)
    draws = draws + 1
    for xx = x, x + ww - 1 do row[xx] = (r == 0.5 and "g") or (r == 1 and "L") or (r == 0 and "f") or "d" end end }
for _, texture in ipairs({ true, false }) do
    A.lineJo = texture and function() return jo end or nil
    A.lineTex = function() return {} end
    for _, n in ipairs({ 5, 10 }) do for w = 20, 400 do for _, gap in ipairs({ 1, 2 }) do for _, k in ipairs({ 0, 3, n }) do
        if w >= n * (1 + gap) then
            row, draws = {}, 0
            A.drawSegBar(panel, 0, 0, w + 2, 8, n, k, { r = 1, g = 0, b = 0 }, { r = 0.2, g = 0.2, b = 0.2 }, gap, { framed = true, exactH = true })
            local cells, cur, len = {}, nil, 0
            for xx = 1, w do local c = row[xx]; if c ~= cur then if cur and cur ~= "g" then cells[#cells + 1] = len end; cur, len = c, 0 end; len = len + 1 end
            if cur ~= "g" then cells[#cells + 1] = len end
            local mn, mx = 1e9, 0
            for _, c in ipairs(cells) do mn = math.min(mn, c); mx = math.max(mx, c) end
            local tag = ("%s n=%d w=%d gap=%d k=%d"):format(texture and "texture" or "rects", n, w, gap, k)
            check(tag .. ": " .. n .. " cells", #cells == n, #cells)
            check(tag .. ": within a pixel", mx - mn <= 1, mn .. ".." .. mx)
            check(tag .. ": meets the frame", row[1] ~= "g" and row[w] ~= "g")
            if texture then check(tag .. ": seven draws at most", draws <= 7, draws) end
        end
    end end end end
end
-- STATUS (punch list 143, Nov 10 2026): a status bar's five cells light rounded up, and its color goes by cells lit:
-- four or five green, two or three yellow, one or none red
ZeD.T.positive, ZeD.T.warning, ZeD.T.warningText, ZeD.T.danger = "G", "Y", "y", "R"
check("STATUS: five cells", A.STATUS_SEGS == 5, A.STATUS_SEGS)
for _, c in ipairs({ { 0, 0, "R" }, { 0.001, 1, "R" }, { 0.2, 1, "R" }, { 0.2001, 2, "Y" }, { 0.4, 2, "Y" }, { 0.6, 3, "Y" },
                     { 0.6001, 4, "G" }, { 0.8, 4, "G" }, { 0.81, 5, "G" }, { 0.95, 5, "G" }, { 1, 5, "G" }, { 1.5, 5, "G" },
                     { -1, 0, "R" } }) do
    check(("STATUS: %.4f lights %d"):format(c[1], c[2]), A.statusSegsLit(c[1]) == c[2], A.statusSegsLit(c[1]))
    check(("STATUS: %.4f is %s"):format(c[1], c[3]), A.statusColor(c[1]) == c[3], A.statusColor(c[1]))
end
check("STATUS: the text shade for words", A.statusColor(0.5, true) == "y", A.statusColor(0.5, true))
-- every share in whole hundredths and thousandths: the color always matches the cells lit
for i = 0, 1000 do
    local f = i / 1000
    local lit, col = A.statusSegsLit(f), A.statusColor(f)
    check("STATUS: color by cells at " .. f, (lit >= 4 and col == "G") or (lit >= 2 and lit <= 3 and col == "Y") or (lit <= 1 and col == "R"), lit .. " " .. col)
end
-- FILL (from zedqa_segbars.lua, Nov 12 2026): drawFillBar's ten cells lit by whole tenths (the floating-point ones
-- too), at its narrowest still ten distinct cells inside the frame; drawSegFill one cell a skill level and the Skills
-- tab's help words; the pointer on a bar puts its value in the help line (with and without a label, and the stat bar
-- row's), off the bar nothing. SkillsTab.barHelp and Molecules.drawStatBarRow are cut from their real files.
do
    local T = ZeD.T
    T.hair, T.fillBarH, T.surf3, T.base, T.accent = 1, 13, { r = 0.2, g = 0.2, b = 0.2 }, { r = 0.5, g = 0.5, b = 0.5, a = 1 }, { r = 0.9, g = 0, b = 0 }
    T.fontF2, T.fontF3, T.toneNorm, T.text, T.badgeBgA = "F2", "F3", { r = 1, g = 1, b = 1 }, { r = 1, g = 1, b = 1 }, 1
    A.truncateText = function(s) return s end
    ZeD.TM = { getFontHeight = function() return 16 end, MeasureStringX = function(_, _, s) return #tostring(s) * 8 end }
    ZeD.tr = function(k, ...) local t = { k }; for _, v in ipairs({ ... }) do t[#t + 1] = tostring(v) end; return table.concat(t, "|") end
    local help
    ZeD.Help = { set = function(_, s) help = s end }
    local LIT = { r = 1, g = 0, b = 0 }
    A.lineJo = nil
    local fp = setmetatable({ mx = -1000, my = -1000 }, { __index = function() return function() end end })
    fp.getMouseX = function(self) return self.mx end
    fp.getMouseY = function(self) return self.my end
    fp.drawRect = panel.drawRect
    local function lay(mx, my) row, help, fp.mx, fp.my = {}, nil, mx or -1000, my or -1000 end
    local function count(x0, x1)
        local lit, dark, runs, cur = 0, 0, {}, nil
        for xx = x0, x1 do
            local c = row[xx]
            if c ~= cur then
                if cur == "L" or cur == "d" then runs[#runs + 1] = cur end
                cur = c
            end
        end
        if cur == "L" or cur == "d" then runs[#runs + 1] = cur end
        for _, c in ipairs(runs) do if c == "L" then lit = lit + 1 else dark = dark + 1 end end
        return lit, dark
    end
    for _, c in ipairs({ { 0.64, 6 }, { 0.04, 0 }, { 1.0, 10 }, { 0, 0 }, { 0.7, 7 }, { 0.3, 3 }, { 0.999, 9 } }) do
        lay()
        A.drawFillBar(fp, 0, 0, 200, c[1], false, LIT, T.fillBarH)
        local lit, dark = count(0, 200)
        check(("FILL: %.3f lights %d"):format(c[1], c[2]), lit == c[2] and A.fillSegsLit(c[1]) == c[2], lit)
        check(("FILL: %.3f draws ten cells"):format(c[1]), lit + dark == 10, lit + dark)
    end
    local minW = A.fillBarMinW()
    lay()
    A.drawFillBar(fp, 0, 0, minW, 0.5, false, LIT, A.fillBarCompactH())
    local lit, dark = count(0, minW - 1)
    check("FILL: at its narrowest (" .. minW .. " px) ten distinct cells, five lit", lit == 5 and dark == 5, lit .. "/" .. dark)
    check("FILL: at its narrowest the frame is at both ends", row[0] == "f" and row[minW - 1] == "f", tostring(row[0]) .. tostring(row[minW - 1]))
    lay()
    A.drawSegFill(fp, 0, 0, A.rowBarW(), A.fillBarCompactH(), 10, 5, LIT)
    lit, dark = count(0, A.rowBarW())
    check("FILL: a skill at level 5 lights 5 of 10", lit == 5 and dark == 5, lit .. "/" .. dark)
    local function cut(file, head)
        local fh = io.open(ROOT .. "42/media/lua/client/ZeD/" .. file, "rb"); local s = fh:read("*a"):gsub("\r\n", "\n"); fh:close()
        local a = s:find(head, 1, true); local b = a and s:find("\nend\n", a, true)
        check("FILL: " .. head .. " found in " .. file, a and b)
        if a and b then assert(loadstring(s:sub(a, b + 4)))() end
    end
    ZeD.SkillsTab, ZeD.Molecules = {}, {}
    cut("SkillsTab.lua", "function ZeD.SkillsTab.barHelp(skill)")
    cut("Molecules.lua", "function ZeD.Molecules.drawStatBarRow(")
    if ZeD.SkillsTab.barHelp then
        check("FILL: skill help 'Fitness 5, 40% to level 6'", ZeD.SkillsTab.barHelp({ name = "Fitness", level = 5, xpProgress = 0.4 }) == "UI_ZeD_Skills_BarHelp|Fitness|5|40%|6")
        check("FILL: skill help 'Fitness 10' at the top", ZeD.SkillsTab.barHelp({ name = "Fitness", level = 10, xpProgress = 1 }) == "UI_ZeD_Bar_Help|Fitness|10")
    end
    lay(100, 6)
    check("FILL: the pointer on a bar is reported", A.drawFillBar(fp, 0, 0, 200, 0.64, true, nil, T.fillBarH, "Condition") == true)
    check("FILL: the help line reads 'Condition 64%'", help == "UI_ZeD_Bar_Help|Condition|64%", help)
    lay(100, 6)
    A.drawFillBar(fp, 0, 0, 200, 0.64, true, nil, T.fillBarH)
    check("FILL: no label, the help line reads '64%'", help == "64%", help)
    lay(300, 6)
    A.drawFillBar(fp, 0, 0, 200, 0.64, true, nil, T.fillBarH, "Condition")
    check("FILL: the pointer off the bar sets nothing", help == nil, help)
    if ZeD.Molecules.drawStatBarRow then
        local w = 300
        local barW = math.max(A.fillBarMinW(), math.min(A.rowBarW(), math.floor(w * 0.4)))
        lay(w - 4 - math.floor(barW / 2), 12)
        ZeD.Molecules.drawStatBarRow(fp, 0, 0, w, "64%", "Bite", 0.64, LIT)
        lit = count(w - 4 - barW, w - 4)
        check("FILL: the stat bar row at 64% lights 6", lit == 6, lit)
        check("FILL: the stat bar row's help line reads 'Bite 64%'", help == "UI_ZeD_Bar_Help|Bite|64%", help)
    end
end
print("seg_bar_spread_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
