-- ZeDUI/tools/qa/paper_tone_b10_sim.lua  (Nov 8 2026): no large near-white areas, with no game running. Every big
-- light sheet ZeD draws sits at the paper tone (Tokens.lua's PAPER_TONE, 0.70 of its printed brightness), and the
-- words on it still read 4.5 : 1.
--   TOKEN    PAPER_TONE is 0.70; paperTone keeps the hue (each channel times 0.70) and makes a new table;
--            paperToneOver lays black at 0.30, which brings any pixel under it to 0.70
--   SHEETS   the guide's book page, its rules bar and page edge, the button pictures' paper; the reader's page,
--            a picture's box, the notebook's paper, rules and margin; the Journal's notebook and paper thumbnails;
--            the printed page ZeD sets itself; the desk's sticky note: each defined as paperTone of its old color,
--            and each big fill drawn with the toned color
--   ENGINE   the sheets the engine draws (a paper map, the Paper style, the game's own newspaper page) are dimmed
--            with paperToneOver in the render, after the engine's sheet
--   INK      every text color on those sheets at 4.5 : 1 or better on the toned paper (the sheets are the same on
--            every theme)
--   THEMES   the Simple guide and the balloons draw on the theme's surfaces: text and the status texts at 4.5 : 1
--            on surface 1 and 2 in Dark, Light and High contrast (deriveReadable's own lift)
-- Run from the repo root: lua51 ZeDUI/tools/qa/paper_tone_b10_sim.lua
local LUA = "42/media/lua/"
local CL = LUA .. "client/ZeD/"

local function slurp(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return (s:gsub("\r", "")) end
local pass, fail = 0, 0
local function ok(c, name) if c then pass = pass + 1 else fail = fail + 1; print("FAIL " .. name) end end

-- ---------------------------------------------------------------- the real tokens on stubs
require = function() end
UIFont = setmetatable({}, { __index = function(_, k) return k end })
function getCore() return setmetatable({}, { __index = function() return function() return 1920 end end }) end
ZeD = { Text = { noFonts = true } }
local okT, errT = pcall(function() assert(loadstring(slurp(LUA .. "shared/ZeD/Tokens.lua")))() end)
if not okT then print("NOTE Tokens.lua's own applyTheme stopped on the stubs: " .. tostring(errT)) end
ok(ZeD.paperTone and ZeD.paperToneOver and ZeD.contrast, "TOKEN Tokens.lua gives paperTone, paperToneOver and contrast")

local K = 0.70
local function near(a, b) return math.abs(a - b) < 1e-6 end

-- TOKEN
ok(ZeD.PAPER_TONE == K, "TOKEN PAPER_TONE is 0.70")
do
    local src = { r = 0.961, g = 0.925, b = 0.824, a = 0.5 }
    local t = ZeD.paperTone(src)
    ok(t ~= src and src.r == 0.961, "TOKEN paperTone makes a new table and leaves the old one")
    ok(near(t.r, 0.961 * K) and near(t.g, 0.925 * K) and near(t.b, 0.824 * K) and t.a == 0.5,
       "TOKEN paperTone is each channel times 0.70, alpha kept")
    ok(near(t.r / t.g, src.r / src.g) and near(t.g / t.b, src.g / src.b), "TOKEN paperTone keeps the hue")
    -- paperToneOver: black at 1 - 0.70 over a pixel p gives p * 0.70
    local drawn = {}
    local panel = { drawRect = function(_, x, y, w, h, a, r, g, b) drawn[#drawn + 1] = { x, y, w, h, a, r, g, b } end }
    ZeD.paperToneOver(panel, 5, 6, 70, 80)
    local d = drawn[1]
    ok(d and d[1] == 5 and d[2] == 6 and d[3] == 70 and d[4] == 80 and d[6] == 0 and d[7] == 0 and d[8] == 0,
       "TOKEN paperToneOver lays black over the rect it is given")
    if d then
        for _, p in ipairs({ 1.0, 0.95, 0.5 }) do
            local out = p * (1 - d[5]) + 0 * d[5]
            ok(near(out, p * K), "TOKEN paperToneOver brings " .. p .. " to " .. p * K)
        end
    end
    ZeD.paperToneOver(panel, 0, 0, 0, 10)
    ok(#drawn == 1, "TOKEN paperToneOver draws nothing for an empty rect")
end

-- ---------------------------------------------------------------- the sheets, read from the source
-- a local color in a file: { r, g, b } and whether it is defined through paperTone
local function color(src, name)
    local esc = name:gsub("_", "%%_")
    local r, g, b = src:match("\nlocal " .. esc .. "%s*=%s*ZeD%.paperTone%(%{ r = ([%d%.]+), g = ([%d%.]+), b = ([%d%.]+) %}%)")
    if r then return { r = tonumber(r) * K, g = tonumber(g) * K, b = tonumber(b) * K }, true, { r = tonumber(r), g = tonumber(g), b = tonumber(b) } end
    r, g, b = src:match("\nlocal " .. esc .. "%s*=%s*%{ r = ([%d%.]+), g = ([%d%.]+), b = ([%d%.]+)")
    if r then return { r = tonumber(r), g = tonumber(g), b = tonumber(b) }, false end
    return nil
end
-- a fill or an ink as drawn, through Tokens' paperTone (the real function, not the sim's own sum)
local function toned(c0) return ZeD.paperTone(c0) end

local function sheet(file, name, tag)
    local src = slurp(CL .. file)
    local c, isToned, old = color(src, name)
    ok(c ~= nil, "SHEETS " .. tag .. ": " .. name .. " is defined in " .. file)
    ok(isToned, "SHEETS " .. tag .. ": " .. name .. " is paperTone of its color")
    if old then
        local t = toned(old)
        ok(near(t.r, old.r * K) and near(t.g, old.g * K) and near(t.b, old.b * K), "SHEETS " .. tag .. ": " .. name .. " at 0.70 brightness")
        return t, src
    end
    return c, src
end
local function ink(src, name, tag)
    local c, isToned = color(src, name)
    ok(c ~= nil and not isToned, "INK " .. tag .. ": " .. name .. " is plain ink, not dimmed")
    return c
end
local function reads(fg, bg, tag)
    if not (fg and bg) then ok(false, "INK " .. tag .. " (a color is missing)"); return end
    local r = ZeD.contrast(fg, bg)
    ok(r >= 4.5, string.format("INK %s reads %.2f : 1", tag, r))
    print(string.format("  %-58s %.2f : 1", tag, r))
end
local function has(src, pat, tag) ok(src:find(pat, 1, true) ~= nil, tag) end

print("contrast on the paper at the paper tone:")
-- the guide's book (Immersive)
do
    -- (PAPER stays the stock's own color for words printed in it on ink; PAGE is the sheet as drawn)
    local src = slurp(CL .. "ZeD_SurvivalGuideBook.lua")
    local stock = color(src, "PAPER")
    ok(stock ~= nil, "SHEETS book: PAPER, the stock's color, is defined")
    has(src, "local PAGE = ZeD.paperTone(PAPER)", "SHEETS book: PAGE is the paper at the paper tone")
    local page = stock and toned(stock)
    ok(page and near(page.r, stock.r * K) and near(page.b, stock.b * K), "SHEETS book: PAGE at 0.70 brightness")
    has(src, "self:drawRect(bk.x, bk.y, bk.w, bk.h, 1, PAGE.r, PAGE.g, PAGE.b)", "SHEETS book: the page is drawn in PAGE")
    has(src, "local BOOK_PAL = { text = INK, surf3 = PAGE, surf1 = PAGE, base = PAGE }", "SHEETS book: the button pictures sit on PAGE")
    local tint = sheet("ZeD_SurvivalGuideBook.lua", "TINT", "book")
    local edge = sheet("ZeD_SurvivalGuideBook.lua", "EDGE_C", "book")
    has(src, "EDGE_C.r, EDGE_C.g, EDGE_C.b)", "SHEETS book: the page edge is drawn in EDGE_C")
    ok(not src:find("1, PAPER.r, PAPER.g, PAPER.b)", 1, true), "SHEETS book: nothing fills at the old paper")
    local INK = ink(src, "INK", "book")
    reads(INK, page, "book: ink on the page")
    reads(INK, tint, "book: ink on the rules bar")
    ok(edge and (edge.r < page.r), "SHEETS book: the page edge stays a step under the page")
end
-- the reader
do
    local paper, src = sheet("ZeD_Reader.lua", "PAPER", "reader")
    local pic = sheet("ZeD_Reader.lua", "PIC_FILL", "reader")
    sheet("ZeD_Reader.lua", "PIC_EDGE", "reader")
    sheet("ZeD_Reader.lua", "RULE", "reader notebook")
    sheet("ZeD_Reader.lua", "MARGIN_C", "reader notebook")
    has(src, "self:drawRect(px, y0, pw, total, 1, PAPER.r, PAPER.g, PAPER.b)", "SHEETS reader: the Words page is drawn in PAPER")
    has(src, "self:drawRect(px, py, pw, ph, 1, PAPER.r, PAPER.g, PAPER.b)", "SHEETS reader: the notebook page is drawn in PAPER")
    has(src, "PIC_FILL.r, PIC_FILL.g, PIC_FILL.b)", "SHEETS reader: a picture's box is drawn in PIC_FILL")
    local INK, DIM = ink(src, "INK", "reader"), ink(src, "INK_DIM", "reader")
    reads(INK, paper, "reader: ink on the page")
    reads(DIM, paper, "reader: grey ink (kickers, page numbers) on the page")
    reads(DIM, pic, "reader: grey ink on a picture's box")
    -- ENGINE: the game's own page is dimmed over, after it draws
    local r0 = src:find("P.vanillaRender(self)", 1, true)
    local r1 = src:find("ZeD.paperToneOver(self, r.x, r.y, r.w, r.h)", 1, true)
    ok(r0 and r1 and r1 > r0, "ENGINE reader: the game's page is brought to the paper tone after it draws")
    has(src, "self._pageTone = { x = x1, y = y1, w = x2 - x1, h = y2 - y1 }", "ENGINE reader: only the page's part in the canvas")
end
-- the Journal's notebooks and papers
do
    local paper, src = sheet("ZeD_JournalReaders.lua", "PAPER", "journal")
    sheet("ZeD_JournalReaders.lua", "RULE", "journal")
    sheet("ZeD_JournalReaders.lua", "MARGIN", "journal")
    reads(ink(src, "INK", "journal"), paper, "journal: ink on the notebook page")
end
-- the printed page ZeD sets itself (the reader's fallback, the Journal's thumbnails)
do
    local sheetC, src = sheet("ZeD_PrintPage.lua", "SHEET", "print")
    has(src, "1, SHEET.r, SHEET.g, SHEET.b)   -- the paper itself", "SHEETS print: the page is drawn in SHEET")
    has(src, "a, SHEET.r, SHEET.g, SHEET.b)", "SHEETS print: the thumbnail is drawn in SHEET")
    ok(not src:find("0.86, 0.85, 0.83", 1, true), "SHEETS print: nothing fills at the old paper")
    reads({ r = 0, g = 0, b = 0 }, sheetC, "print: the page's black words on the sheet")
end
-- the desk's sticky note
do
    local paper, src = sheet("ZeD_MainMenuNotes.lua", "PAPER", "sticky")
    sheet("ZeD_MainMenuNotes.lua", "PAPER_TOP", "sticky")
    reads(ink(src, "INK", "sticky"), paper, "sticky: ink on the note")
    reads(ink(src, "INK_HINT", "sticky"), paper, "sticky: the empty note's hint")
end
-- ENGINE: paper maps (an item read, the Paper style)
do
    local src = slurp(CL .. "MapsTab.lua")
    local a = src:find("if self._paperItem or self.paper then ZeD.paperToneOver(self, 0, 0, self:getWidth(), self:getHeight()) end", 1, true)
    local s = src:find("self:setStencilRect(0, 0, self:getWidth(), self:getHeight())", 1, true)
    local m = src:find("self:renderAnnotations()", 1, true)
    ok(a and s and m and s < a and a < m, "ENGINE map: a paper map is dimmed in the map's clip, under ZeD's own marks")
end

-- ---------------------------------------------------------------- THEMES: the Simple guide and the balloons
print("contrast on the theme surfaces (Simple guide, balloons):")
local function flat(world, s)
    local sa = s.a or 1
    return { r = s.r * sa + world * (1 - sa), g = s.g * sa + world * (1 - sa), b = s.b * sa + world * (1 - sa) }
end
for _, theme in ipairs({ "dark", "light", "hicon" }) do
    local worst = { text = 99, positiveText = 99, dangerText = 99, textSec = 99 }
    for _, ak in ipairs({ "red", "orange", "yellow", "green", "blue", "teal", "purple", "pink", "mono" }) do
        if ZeD.AccentColors[ak] then
            ZeD.surfaceAlpha = nil
            ZeD.applyTheme(theme, ak, "small")
            local T = ZeD.T
            local world = (theme ~= "light") and 1 or 0
            for _, s in ipairs({ flat(world, T.surf1), flat(world, T.surf2), { r = T.surf2.r, g = T.surf2.g, b = T.surf2.b } }) do
                for key in pairs(worst) do
                    local c = T[key]
                    if c then worst[key] = math.min(worst[key], ZeD.contrast(c, s)) end
                end
            end
        end
    end
    for key, v in pairs(worst) do
        ok(v >= 4.5, string.format("THEMES %s: %s at %.2f : 1", theme, key, v))
        print(string.format("  %-58s %.2f : 1", theme .. ": " .. key .. " (worst accent, surface 1 / 2)", v))
    end
end

print(string.format("paper_tone_b10_sim: %d passed, %d failed", pass, fail))
if fail > 0 then os.exit(1) end
