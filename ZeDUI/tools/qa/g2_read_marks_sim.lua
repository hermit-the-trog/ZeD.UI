-- ZeDUI/tools/qa/g2_read_marks_sim.lua  (Nov 12 2026, Build; punch list 175a A2 and D6, 175f(1) and 175f(2)): read marks,
-- the inventory list, Papers and Notebooks, checked on the real pieces of the changed files with no game running.
--   UNREAD   A2, "Unread" everywhere, no period: the read hover card (the real ReadMarks.compute on a map, a titled
--            book and a skill book) starts "Unread", not the game's "Unread."; the Papers rows and the Papers and
--            Books rows under "No notebook on you" say UI_ZeD_Read_Unread, not "Not read yet" or the game's "Unread.";
--            UI_ZeD_Read_Unread has a word and no period in all 28 UI.json
--   LARGE    175f(1): the real fitColumns keeps Status over Category when read marks are on and only one fits (and
--            drops as before with them off); the list asks it with readOn; the real readTagW holds the mark and the
--            word, and the real drawReadCond given that width draws the word after the name (at Small and Large text)
--   LIGHT    175f(2): the real J.paperTones gives an unread paper row's title and kind line a colour that keeps
--            4.5 : 1 on the window over either world, in Dark, Light and High contrast; the list's "Dim read items"
--            name is T.textDim at full strength, not faded to half
--   HEADS    D6: the Papers reader's section heads and the loadout's sections are the one small mono line
--            (drawCategoryRow), no drawSectionHeader left in either Journal file
-- Today's code (before these fixes) fails UNREAD, LARGE, LIGHT and HEADS.
-- What it can't show is the look in the game: the in-game check is the Papers tab in Light and the inventory at Large.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/g2_read_marks_sim.lua
-- It prints FAIL lines and a last line "g2_read_marks_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = arg and arg[1] or string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]g2_read_marks_sim%.lua$", "")
if ROOT ~= "" and not ROOT:match("[/\\]$") then ROOT = ROOT .. "/" end
local CL = "42/media/lua/client/ZeD/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return "" end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
-- a piece of a file: from `from` (plain) to the first "\nend\n" after it
local function cutFn(src, from)
    local a = src:find(from, 1, true)
    local b = a and src:find("\nend\n", a, true)
    return (a and b) and src:sub(a, b + 4) or nil
end

-- ---------------------------------------------------------------------------
-- THE STUBS: the game, and the real Tokens.lua
-- ---------------------------------------------------------------------------
getTimestampMs = function() return 1762900000000 end
Events = setmetatable({}, { __index = function() return { Add = function() end } end })
triggerEvent = function() end
UIFont = setmetatable({}, { __index = function(_, k) return k end })
require = function() end
local ROOTSC = 1
ZeD = {}
ZeD.Scale = { root = function() return ROOTSC end }
ZeD.Text = { checkRoleFonts = function() return false end }
local function fontPx(f) return (ZeD.T and ZeD.T.fontPx and ZeD.T.fontPx[f]) or 10 end
ZeD.TM = {
    getFontHeight = function(_, f) return math.floor(fontPx(f) * ROOTSC * 77 / 64 + 0.5) end,
    MeasureStringX = function(_, f, s) return math.floor(#tostring(s or "") * fontPx(f) * ROOTSC * 0.6 + 0.5) end,
}
getTextManager = function() return ZeD.TM end
local GAME = { Tooltip_literature_NotBeenRead = "Unread.", Tooltip_literature_HasBeenRead = "Has been read.", IGUI_Pages = "Pages" }
getText = function(k, ...) return GAME[k] or k end

local okT, errT = pcall(function() assert(loadstring(readFile("42/media/lua/shared/ZeD/Tokens.lua"), "@Tokens.lua"))() end)
check("Tokens.lua loads on the stubs", okT, errT)
local function apply(base, size)
    local ok, e = pcall(ZeD.applyTheme, base, ZeD.DEFAULT_ACCENT, size or "small")
    if not ok then print("NOTE applyTheme " .. base .. ": " .. tostring(e)) end
    return ZeD.T
end
apply("dark", "small")

-- the English words (the real EN UI.json), for ZeD.tr
local EN = {}
for k, v in readFile("42/media/lua/shared/Translate/EN/UI.json"):gmatch('"([%w_]+)"%s*:%s*"([^"]*)"') do EN[k] = v end
ZeD.trDefaults = function(t) for k, v in pairs(t) do if EN[k] == nil then EN[k] = v end end end
ZeD.tr = function(k, ...)
    local s = EN[k] or k
    local args = { ... }
    return (s:gsub("%%(%d)", function(n) return tostring(args[tonumber(n)]) end))
end
ZeD._trGen = 1

-- ---------------------------------------------------------------------------
section("UNREAD")
-- ---------------------------------------------------------------------------
local RMsrc = readFile(CL .. "ReadMarks.lua")
local okR, errR = pcall(function() assert(loadstring(RMsrc, "@ReadMarks.lua"))() end)
check("UNREAD ReadMarks.lua loads on the stubs", okR, errR)
local R = ZeD.ReadMarks
local function fakeItem(t)
    local it = {}
    for k, v in pairs(t) do it[k] = function() return v end end
    it.hasModData = function() return t._md ~= nil end
    it.getModData = function() return t._md end
    it.getFullType = function() return "Base.Thing" end
    return it
end
local P0 = {
    hasReadMap = function() return false end,
    isLiteratureRead = function() return false end,
    isPrintMediaRead = function() return false end,
    getKnownRecipes = function() return { contains = function() return false end } end,
    getPerkLevel = function() return 2 end,
    getAlreadyReadPages = function() return 0 end,
}
SkillBook = { Carpentry = { perk = "Woodwork" } }
PerkFactory = { getPerk = function() return { getName = function() return "Carpentry" end } end }
if R and R.compute then
    local cases = {
        { "a map", fakeItem({ IsMap = true }) },
        { "a titled book", fakeItem({ IsLiterature = true, canBeWrite = false, _md = { literatureTitle = "Some Title" } }) },
        { "a skill book", fakeItem({ IsLiterature = true, canBeWrite = false, getSkillTrained = "Carpentry", getLvlSkillTrained = 3,
            getMaxLevelTrained = 4, getNumberOfPages = 220 }) },
    }
    for _, c in ipairs(cases) do
        local ok, s = pcall(R.compute, P0, c[2])
        check("UNREAD " .. c[1] .. ": computes", ok and s ~= nil, s)
        if ok and s then
            check("UNREAD " .. c[1] .. ": its tag says Unread", s.st == "u" and s.word == "Unread", s.word)
            check("UNREAD " .. c[1] .. ": its hover card starts 'Unread' with no period", s.lines and s.lines[1] == "Unread", s.lines and s.lines[1])
        end
    end
end
check("UNREAD ReadMarks: no game 'Unread.' (Tooltip_literature_NotBeenRead) left", not RMsrc:find("Tooltip_literature_NotBeenRead", 1, true))
local JR = readFile(CL .. "ZeD_JournalReaders.lua")
check("UNREAD Papers: no 'Not read yet' (UI_ZeD_Papers_StateUnread) left", not JR:find("UI_ZeD_Papers_StateUnread", 1, true))
check("UNREAD Books on you: no game 'Unread.' (Tooltip_literature_NotBeenRead) left", not JR:find("Tooltip_literature_NotBeenRead", 1, true))
local _, nU = JR:gsub("UI_ZeD_Read_Unread", "")
check("UNREAD Papers list, Papers fill rows and Books fill rows all say UI_ZeD_Read_Unread", nU >= 3, nU)
local langs = 0
local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP", "KO",
    "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
for _, dir in ipairs(LANGS) do
    local js = readFile("42/media/lua/shared/Translate/" .. dir .. "/UI.json")
    if js ~= "" then
        langs = langs + 1
        local v = js:match('"UI_ZeD_Read_Unread"%s*:%s*"([^"]*)"')
        check("UNREAD " .. dir .. ": UI_ZeD_Read_Unread has a word", v ~= nil and v ~= "", v)
        check("UNREAD " .. dir .. ": UI_ZeD_Read_Unread has no period", v ~= nil and not v:find("%.%s*$"), v)
    end
end
check("UNREAD all 28 UI.json read", langs == 28, langs)

-- ---------------------------------------------------------------------------
section("LARGE")
-- ---------------------------------------------------------------------------
local IR = readFile(CL .. "InventoryRenderer.lua")
local A = {}
ZeD.InventoryRenderer = A
local pieces = { "local function drawReadCond(", "local function readTagW(", "local function fitColumns(" }
local chunk = {}
for _, p in ipairs(pieces) do
    local c = cutFn(IR, p)
    check("LARGE InventoryRenderer has " .. p, c ~= nil)
    chunk[#chunk + 1] = c or ""
end
chunk[#chunk + 1] = "return drawReadCond, readTagW, fitColumns"
local okI, drawReadCond, readTagW, fitColumns = pcall(function() return assert(loadstring(table.concat(chunk, "\n"), "@IR pieces"))() end)
check("LARGE the pieces load", okI, drawReadCond)
if okI and fitColumns then
    -- room past the name's least width; Category 80, Status 70
    local c1, k1 = fitColumns(200, 80, 70, true)
    check("LARGE both fit: both kept", c1 == true and k1 == true)
    local c2, k2 = fitColumns(100, 80, 70, true)
    check("LARGE read marks on, one fits: Status kept, Category dropped", c2 == true and k2 == false, tostring(c2) .. "/" .. tostring(k2))
    local c3, k3 = fitColumns(100, 80, 70, false)
    check("LARGE read marks off, one fits: as before, Status dropped, Category kept", c3 == false and k3 == true, tostring(c3) .. "/" .. tostring(k3))
    local c4, k4 = fitColumns(60, 80, 70, true)
    check("LARGE nothing fits: both dropped", c4 == false and k4 == false)
    local c5, k5 = fitColumns(75, 80, 70, false)
    check("LARGE read marks off, neither alone of Category fits: both dropped", c5 == false and k5 == false)
end
check("LARGE the list asks fitColumns with readOn", IR:find("fitColumns(colW - nameX - wtD - padX - scrollW - MIN_NAME, catColW, condColW, readOn)", 1, true) ~= nil)
check("LARGE a hidden Status column puts the mark and its word after the name",
    IR:find("(rs and not showCond) and readTagW(rs) or 0", 1, true) ~= nil
    and IR:find("drawReadCond(self, rs, xOff + afterName, y, rowH, dotW + math.floor(padX / 2), padX, focusTxt)", 1, true) ~= nil)
if okI and readTagW and drawReadCond then
    ZeD.Atoms = { drawStatusDot = function() end, drawStatusHalf = function() end, drawStatusHollow = function() end }
    for _, size in ipairs({ "small", "large" }) do
        local T = apply("dark", size)
        local padX = T.sp.sm
        for _, rs in ipairs({ { st = "u", word = "Unread" }, { st = "r", word = "Read" }, { st = "p", word = "3 of 10", short = "30%" } }) do
            local w = readTagW(rs)
            local texts = {}
            local panel = { drawRect = function() end, drawText = function(_, s) texts[#texts + 1] = s end }
            drawReadCond(panel, rs, 0, 0, T.rowH, w + math.floor(padX / 2), padX, nil)
            local want = rs.short or rs.word
            check("LARGE " .. size .. " '" .. rs.word .. "': the tag after the name draws its word", texts[1] == want, texts[1])
        end
    end
end

-- ---------------------------------------------------------------------------
section("LIGHT")
-- ---------------------------------------------------------------------------
local J = {}
local tones = cutFn(JR, "function J.paperTones(")
check("LIGHT ZeD_JournalReaders has J.paperTones", tones ~= nil)
local okJ, errJ = pcall(function() assert(loadstring("local J = ...\n" .. (tones or ""), "@paperTones"))(J) end)
check("LIGHT J.paperTones loads", okJ and J.paperTones ~= nil, errJ)
local function over(world, s)
    local a = s.a or 1
    return { r = world * (1 - a) + s.r * a, g = world * (1 - a) + s.g * a, b = world * (1 - a) + s.b * a, a = 1 }
end
local function onto(bg, c)
    local a = c.a or 1
    return { r = bg.r * (1 - a) + c.r * a, g = bg.g * (1 - a) + c.g * a, b = bg.b * (1 - a) + c.b * a, a = 1 }
end
if J.paperTones then
    for _, base in ipairs({ "dark", "light", "hicon" }) do
        local T = apply(base, "small")
        local hi, sc, tc = J.paperTones(false, false)
        for _, world in ipairs({ 0, 1 }) do
            local bg = over(world, T.surf1)
            local cH, cS, cT = ZeD.contrast(onto(bg, hi), bg), ZeD.contrast(onto(bg, sc), bg), ZeD.contrast(onto(bg, tc), bg)
            check("LIGHT " .. base .. " world " .. world .. ": the unread row's title keeps 4.5 : 1", cH >= 4.5, string.format("%.2f", cH))
            check("LIGHT " .. base .. " world " .. world .. ": the unread row's kind line keeps 4.5 : 1", cS >= 4.5, string.format("%.2f", cS))
            check("LIGHT " .. base .. " world " .. world .. ": the unread row's state word keeps 4.5 : 1", cT >= 4.5, string.format("%.2f", cT))
        end
        local rh = J.paperTones(true, false)
        check("LIGHT " .. base .. ": a read row's title stays the accent text (toneHi)", rh == T.toneHi)
        local fh = J.paperTones(false, true)
        check("LIGHT " .. base .. ": a focused row's words are textOnFocus", fh == T.textOnFocus)
    end
end
check("LIGHT the Papers list draws its words through J.paperTones", JR:find("local hi, sc, tc, a = J.paperTones(e.read, swapped)", 1, true) ~= nil)
check("LIGHT the list's dimmed read name is T.textDim, not faded",
    IR:find("focusTxt or (dimA < 1 and T.textDim) or", 1, true) ~= nil and not IR:find("(nameColor.a or 1) * dimA", 1, true))

-- ---------------------------------------------------------------------------
section("HEADS")
-- ---------------------------------------------------------------------------
local JL = readFile(CL .. "ZeD_JournalLists.lua")
check("HEADS ZeD_JournalReaders: no drawSectionHeader left", not JR:find("drawSectionHeader", 1, true))
check("HEADS ZeD_JournalLists: no drawSectionHeader left", not JL:find("drawSectionHeader", 1, true))
local sec = cutFn(JR, "local function section(") or ""
check("HEADS the reader's section head is the small mono line, no triangle", sec:find("drawCategoryRow(", 1, true) ~= nil and sec:find("noArrow = true", 1, true) ~= nil)
check("HEADS the loadout's sections fold on the small mono line",
    JL:find("M.drawCategoryRow(panel, x, cy, w, label, #sec.lines, not folded, { hover = hover, focus = focusOf(win, id), h = h, inset = T.px(6) })", 1, true) ~= nil)

print("g2_read_marks_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
