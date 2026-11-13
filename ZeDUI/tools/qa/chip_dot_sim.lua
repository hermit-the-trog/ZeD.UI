-- ZeDUI/tools/qa/chip_dot_sim.lua  (Nov 11 2026, Build): the tags lose their boxes (the director: "pills and
-- bordered chips read as modern web design"), checked on the real pieces of the changed files with no game running.
--   TAG      ZeD.Atoms.drawTag draws no outline: a marked tag is the 6u square and the word 4u after it, from x;
--            an unmarked tag is the word at x; tagW is that width; a hollow mark is the square's own outline only;
--            minW (drawBadge's old room) centres the square and the word; markGap moves the word
--   INJURY   a Health injury row's tags: each square under the part's square (x + 2), each word under the part's
--            name (x + 14) on every line of the wrap, an unmarked tag's word in step; measuring and drawing agree
--   ROW      the inventory row's Belt 2 / Next level: since the tab catalog's review (Nov 12 2026) its status square
--            (Belt n the info colour, Next level the accent), then the word in the secondary ink (textDim), the focus
--            ink on the controller's row, no outline: bare, the word read as more of the item's name; the Equipment
--            belt's In hand the same (info)
--   CALLERS  the layouts that measured the old box (Health, Equipment, the inventory rows, the medic card, the
--            Animals tab, the station rows, the mod list, the belt's In hand) measure the new one
-- Run from the repo root:  lua51 ZeDUI/tools/qa/chip_dot_sim.lua
-- It prints FAIL lines and a last line "chip_dot_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]chip_dot_sim%.lua$", "")

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
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
local function srcOf(rel) return readFile("42/media/lua/client/ZeD/" .. rel) or "" end

-- a top-level piece of a file, from its opening text to its first unindented "end"
local function cutFn(src, open)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local e = src:find("\nend\n", a, true)
    if not e then return nil end
    return src:sub(a, e + 4)
end
local function load(rel, prefix, openings)
    local src = srcOf(rel)
    if src == "" then return false, "no file " .. rel end
    local parts = { prefix or "" }
    for _, o in ipairs(openings) do
        local piece = cutFn(src, o)
        if not piece then return false, "not found in " .. rel .. ": " .. o end
        parts[#parts + 1] = piece
    end
    local chunk, err = loadstring(table.concat(parts), "=" .. rel .. " (cut)")
    if not chunk then return false, err end
    return pcall(chunk)
end

-- the tokens at 1x (a design unit is a pixel); every glyph 8 wide
local F1_H = 14
local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end
ZeD = {
    T = {
        px = function(n) return n end,
        fontF1 = "F1", fontF2 = "F2",
        text = col(1, 1, 1), textDim = col(0.5, 0.5, 0.5), textOnFocus = col(0, 0, 0), borderS = col(0.3, 0.3, 0.3),
        danger = col(1, 0, 0), warning = col(1, 0.6, 0), positive = col(0, 1, 0),
        sp = { badgeGap = 6 },
    },
    TM = {
        getFontHeight = function() return F1_H end,
        MeasureStringX = function(_, f, s) return #tostring(s) * 8 end,
    },
    Atoms = {}, Molecules = {}, HealthTab = {},
}
ZeD.textCase = function(s) return s end

-- the draw log: every rect, outline and word
local LOG = {}
local panel = {
    drawRect = function(_, x, y, w, h, a, r, g, b) LOG[#LOG + 1] = { k = "rect", x = x, y = y, w = w, h = h, r = r } end,
    drawRectBorder = function(_, x, y, w, h) LOG[#LOG + 1] = { k = "border", x = x, y = y, w = w, h = h } end,
    drawText = function(_, s, x, y, r, g, b, a) LOG[#LOG + 1] = { k = "text", s = s, x = x, y = y, r = r } end,
}
ZeD.Atoms.frame = function(_, x, y, w, h) LOG[#LOG + 1] = { k = "frame", x = x, y = y, w = w, h = h } end
local function count(k) local n = 0; for _, e in ipairs(LOG) do if e.k == k then n = n + 1 end end; return n end
local function first(k) for _, e in ipairs(LOG) do if e.k == k then return e end end end
local function all(k) local o = {}; for _, e in ipairs(LOG) do if e.k == k then o[#o + 1] = e end end; return o end

section("TAG: the square and the word, no box")
do
    local ok, err = load("Atoms.lua", "local NO_OPTS = {}\nlocal function textCase(s) return s end\n",
        { "local function tagMeasure(", "function ZeD.Atoms.tagW(", "function ZeD.Atoms.drawTag(" })
    check("tagMeasure / tagW / drawTag cut and load", ok, err)
    ZeD.Molecules.drawTag = function(...) return ZeD.Atoms.drawTag(...) end
    if ok then
        local T = ZeD.T
        LOG = {}
        local w, h = ZeD.Atoms.drawTag(panel, 100, 50, "Bleeding", T.danger)
        check("marked: no outline", count("frame") == 0 and count("border") == 0, count("frame"))
        check("marked: one square", count("rect") == 1, count("rect"))
        local sq, tx = first("rect"), first("text")
        check("marked: the square at x", sq and sq.x == 100 and sq.w == 6 and sq.h == 6, sq and sq.x)
        check("marked: the square in the 16u row's middle", sq and sq.y == 55, sq and sq.y)
        check("marked: the square in the status colour", sq and sq.r == 1)
        check("marked: the word 4u after the square", tx and tx.x == 110, tx and tx.x)
        check("marked: the word in the default ink", tx and tx.r == 1)
        check("marked: width = square + gap + word", w == 6 + 4 + 64, w)
        check("marked: 16u tall", h == 16, h)
        check("tagW agrees (marked)", ZeD.Atoms.tagW("Bleeding", true) == w, ZeD.Atoms.tagW("Bleeding", true))

        LOG = {}
        w = ZeD.Atoms.drawTag(panel, 100, 50, "Belt 2", nil)
        check("unmarked: nothing but the word", #LOG == 1 and LOG[1].k == "text", #LOG)
        check("unmarked: the word at x", first("text") and first("text").x == 100)
        check("unmarked: width = the word", w == 48, w)
        check("tagW agrees (unmarked)", ZeD.Atoms.tagW("Belt 2", false) == 48)

        LOG = {}
        ZeD.Atoms.drawTag(panel, 0, 0, "Unread", T.warning, { hollow = true })
        local fr = all("frame")
        check("hollow: the square's outline only", #fr == 1 and fr[1].w == 6 and fr[1].h == 6, #fr)

        LOG = {}
        w = ZeD.Atoms.drawTag(panel, 0, 0, "Ok", T.positive, { minW = 60 })
        check("minW: the room kept", w == 60, w)
        check("minW: square and word centred", first("rect") and first("rect").x == 17, first("rect") and first("rect").x)
        check("minW: no outline round the room", count("frame") == 0)

        LOG = {}
        ZeD.Atoms.drawTag(panel, 0, 0, "Pain", T.warning, { markGap = 6 })
        check("markGap: the word 6u after the square", first("text") and first("text").x == 12, first("text") and first("text").x)

        local src = srcOf("Atoms.lua")
        local body = cutFn(src, "function ZeD.Atoms.drawTag(") or ""
        check("drawTag draws no frame but the hollow mark's", select(2, body:gsub("Atoms%.frame%(", "")) == 1)
        check("drawTag makes no table", not body:find("{", 1, true))
    end
end

section("INJURY: squares under the part's square, words under its name")
do
    local ok, err = load("HealthTab.lua", nil,
        { "local SEV_TOKEN = {", "local TAG_SQ, TAG_MARK_GAP, TAG_GAP", "local function condTags(" })
    check("sevColor / tagHang / condTags cut and load", ok, err)
    -- (the cut pieces are locals of the chunk: reach them through what the file exports)
    local src = srcOf("HealthTab.lua")
    local chunk = loadstring(cutFn(src, "local SEV_TOKEN = {") .. cutFn(src, "local TAG_SQ, TAG_MARK_GAP, TAG_GAP")
        .. cutFn(src, "local function condTags(") .. "\nreturn condTags, tagHang, sevColor\n", "=HealthTab.lua (cut)")
    local condTags, tagHang, sevColor = chunk()
    local T = ZeD.T
    local x0 = 20                  -- the list's left edge
    local indent = 2 + 6 + 6       -- injuryRowLayout's indent: the square's inset, the square, the gap to the name
    check("the hang reaches back to the part's square", tagHang() == indent - 2, tagHang())
    local conds = {
        { label = "Bleeding", severity = "danger" },
        { label = "Laceration", severity = "warning" },
        { label = "Deep wound", severity = "danger" },
        { label = "Healthy", severity = "ok" },
        { label = "Bandaged", severity = "positive" },
    }
    local maxW = 200 - indent
    LOG = {}
    local hDraw = condTags(panel, conds, x0 + indent, 300, maxW, tagHang())
    local hMeasure = condTags(nil, conds, 0, 0, maxW, tagHang())
    check("measure and draw agree", hDraw == hMeasure, hDraw .. " vs " .. hMeasure)
    check("no outline anywhere", count("frame") == 0 and count("border") == 0)
    local sqs, words = all("rect"), all("text")
    check("a square for each marked tag", #sqs == 4, #sqs)
    check("a word for each tag", #words == 5, #words)
    local lines = {}
    for _, t in ipairs(words) do lines[t.y] = lines[t.y] or t.x; if t.x < lines[t.y] then lines[t.y] = t.x end end
    local nLines = 0
    for y, lx in pairs(lines) do
        nLines = nLines + 1
        check("line at " .. y .. ": its first word under the name", lx == x0 + indent, lx)
    end
    check("the tags wrap (more than one line)", nLines >= 2, nLines)
    local sqLeft = {}
    for _, s in ipairs(sqs) do sqLeft[s.y] = math.min(sqLeft[s.y] or 1e9, s.x) end
    for y, sx in pairs(sqLeft) do check("line square " .. y .. ": under the part's square", sx == x0 + 2, sx) end
    -- (in the 16u row the square sits 5u down, the 14u word 1u down)
    for i, s in ipairs(sqs) do
        local w = nil
        for _, t in ipairs(words) do if t.y == s.y - 4 and t.x == s.x + 12 then w = t end end
        check("square " .. i .. ": its word 6u after it, level", w ~= nil)
    end
    for _, t in ipairs(words) do
        if t.s == "Healthy" then
            local prev = nil
            for _, s in ipairs(sqs) do if s.y - 4 == t.y and s.x + 12 == t.x then prev = s end end
            check("unmarked: no square before the word", prev == nil)
            check("unmarked: the word keeps the square's room", t.x > x0 + indent, t.x)
        end
    end
    local body = cutFn(src, "local function condTags(") or ""
    check("condTags makes no table a frame", not body:find("{", 1, true))
    check("the Health list hangs its tags", src:find("listX + tagIndent, curY + row.tagsY, listW - tagIndent, tagHang())", 1, true) ~= nil)
    check("the list's height hangs them too", select(2, src:gsub("tagIndent, tagHang%(%)%)", "")) >= 2)
    local medic = srcOf("ObjectCardMedic.lua")
    check("the medic card's tags under its names", medic:find("HT.condTags(card, en.conditions, x + ind, ty, w - ind, hang)", 1, true) ~= nil)
end

section("ROW: Belt 2, Next level and In hand: the status square, then the word in the secondary ink")
do
    local ok, err = load("InventoryRenderer.lua", nil, { "local _rowTagOpts = {}" })
    check("rowTag cuts and loads", ok, err)
    local src = srcOf("InventoryRenderer.lua")
    local chunk = loadstring(cutFn(src, "local _rowTagOpts = {}") .. "\nreturn rowTag\n", "=InventoryRenderer.lua (cut)")
    local rowTag = chunk()
    local T = ZeD.T
    T.info = col(0.3, 0.6, 0.7)
    LOG = {}
    rowTag(panel, 200, 10, 30, "Belt 2", nil, T.info)
    local t, sq = first("text"), first("rect")
    check("Belt 2: its square, then the word", #LOG == 2 and t ~= nil and sq ~= nil, #LOG)
    check("Belt 2: the square at x, in the info colour", sq and sq.x == 200 and sq.w == 6 and sq.r == T.info.r, sq and sq.x)
    check("Belt 2: the word after the square, in the secondary ink", t and t.x == 210 and t.r == T.textDim.r, t and t.x)
    LOG = {}
    rowTag(panel, 200, 10, 30, "Belt 2", T.textOnFocus, T.info)
    check("Belt 2 on the focused row: the focus ink, the square kept", first("text") and first("text").r == T.textOnFocus.r
        and first("rect") ~= nil)
    -- the ink is read fresh: a theme change shows on the next call
    local was = T.textDim
    T.textDim = col(0.25, 0.25, 0.25)
    LOG = {}
    rowTag(panel, 200, 10, 30, "Belt 2", nil, T.info)
    check("the secondary ink read fresh", first("text") and first("text").r == 0.25)
    T.textDim = was
    check("the rows hand Belt n the info square", src:find("rowTag(self, xOff + afterName, y, rowH, tag, focusTxt, T.info)", 1, true) ~= nil)
    check("the rows hand Next level the accent square (the grid's next-level arrow)",
        src:find("rowTag(self, xOff + afterName, y, rowH, nextTag, focusTxt, T.accentText or T.accent)", 1, true) ~= nil)
    local eq = srcOf("EquipmentTab.lua")
    check("In hand: the secondary ink", eq:find("_beltTagOpts.textColor = ink or ZeD.T.textDim", 1, true) ~= nil)
    check("In hand: the info square", eq:find("return ZeD.Molecules.drawTag(panel, x, y, text, ZeD.T.info, _beltTagOpts)", 1, true) ~= nil)
end

section("CALLERS: no layout measures the old box")
do
    local function has(rel, s) return srcOf(rel):find(s, 1, true) ~= nil end
    check("inventory rows measure through tagW, the square in", has("InventoryRenderer.lua", "return ZeD.Atoms.tagW(text, true)"))
    check("Equipment's In hand measures through tagW, the square in", has("EquipmentTab.lua", "return ZeD.Atoms.tagW(text, true)"))
    check("the station rows measure through tagW", has("StationAppliance.lua", "tagW = ZeD.Atoms.tagW(tagTxt, tagMark ~= nil) + T.px(6)"))
    check("the mod list measures through tagW", has("ZeD_MainMenuMods.lua", "return ZeD.Atoms.tagW(text, tagMark(variant) ~= nil)"))
    check("the belt's In hand centres the word itself", has("ZeD_Belt.lua", "local tw = tm:MeasureStringX(f5, ZeD.textCase(text))\n"))
    check("the Animals tab drops the padding", not has("AnimalsTab.lua", "tc(text)) + T.px(10)"))
    check("the wheel's breadcrumb centres in its fill", has("ZeD_Wheel.lua", "minW = w, keepCase = true"))
    check("the Health tab's own box width is gone", not has("HealthTab.lua", "ZeD.textCase(label)) + T.px(10)"))
end

print(string.format("chip_dot_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
