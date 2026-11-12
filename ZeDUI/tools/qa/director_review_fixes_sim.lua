-- ZeDUI/tools/qa/director_review_fixes_sim.lua  (Nov 11 2026, Build): the director's notes on the tab pictures
-- (tab_review_20261111), checked on the real pieces of the changed files with no game running.
--   INJURY   a Health injury row's band: the name line and its tags in the middle, the same pad over and under,
--            the tags starting under the name (past the status square), not at the band's left edge.
--   THERMAL  the stat bar row drawn flat (the Thermal tab) draws no inset and no badge fill, only the bar and words;
--            the ordinary row (Equipment) keeps both.
--   NOTE     the notebook page takes what a taller drawer leaves under it, down to the view's foot, and never
--            draws shorter than its own height in a short one.
--   TRAITS   a trait row is the icon, the dot, the name, left to right, the icon the game's 18 units.
--   RADIO    the World window's radio tab is the full card wherever it fits (480 at 1x), the half card held in.
--   FURN     the Furniture tab's strip and its "Point at furniture." line start at the drawer's tab pad.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/director_review_fixes_sim.lua
-- It prints FAIL lines and a last line "director_review_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]director_review_fixes_sim%.lua$", "")

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

-- a top-level function of a file, from its opening text to its first unindented "end"
local function cutFn(src, open)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local e = src:find("\nend\n", a, true)
    if not e then return nil end
    return src:sub(a, e + 4)
end
local function load(rel, openings, env)
    local src = readFile("42/media/lua/client/ZeD/" .. rel)
    if not src then return false, "no file " .. rel end
    local parts = { "local FT, J = ...\n" }
    for _, o in ipairs(openings) do
        local piece = cutFn(src, o)
        if not piece then return false, "not found in " .. rel .. ": " .. o end
        parts[#parts + 1] = piece
    end
    local chunk, err = loadstring(table.concat(parts), "=" .. rel .. " (cut)")
    if not chunk then return false, err end
    local ok, e2 = pcall(chunk, env and env.FT, env and env.J)
    return ok, e2
end

-- the tokens at 1x (a design unit is a pixel)
local BODY_H, F1_H, F3_H = 19, 14, 16
ZeD = {
    T = {
        px = function(n) return n end,
        fontF1 = "F1", fontF2 = "F2", fontF3 = "F3",
        base = { r = 0, g = 0, b = 0, a = 1 }, surf3 = { r = 0.2, g = 0.2, b = 0.2 }, badgeBgA = 0.6,
        toneNorm = { r = 1, g = 1, b = 1, a = 1 }, text = { r = 1, g = 1, b = 1, a = 1 }, accent = { r = 0, g = 1, b = 1 },
        sp = { scrollbarW = 10, sm = 10 },
    },
    TM = {
        getFontHeight = function(_, f) return (f == "F1" and F1_H) or (f == "F3" and F3_H) or BODY_H end,
        MeasureStringX = function(_, f, s) return #tostring(s) * 8 end,
    },
    Molecules = { getTabPad = function() return 8 end },
    HealthTab = {}, IdentityTab = {},
}
ZeD_WorldWindow = {}

section("INJURY: the row's band")
do
    local ok, err = load("HealthTab.lua", { "function ZeD.HealthTab.injuryRowLayout(" })
    check("injuryRowLayout cuts and loads", ok, err)
    local L = ZeD.HealthTab.injuryRowLayout
    if ok and L then
        for _, tagsH in ipairs({ 0, 16, 34 }) do
            local r = L(BODY_H, tagsH)
            local contentTop = r.nameY
            local contentBottom = (tagsH > 0) and (r.tagsY + tagsH) or (r.nameY + BODY_H)
            local under = (r.h - 1) - contentBottom      -- (the last unit is the groove)
            check("tags " .. tagsH .. ": pad over = pad under", contentTop == under, contentTop .. " vs " .. under)
            check("tags " .. tagsH .. ": the pad is 6 to 10", contentTop >= 6 and contentTop <= 10, contentTop)
            if tagsH > 0 then check("tags " .. tagsH .. ": the tags under the name", r.tagsY >= r.nameY + BODY_H, r.tagsY) end
        end
        local r = L(BODY_H, 16)
        check("the tags start at the name's left edge (square inset 2, square 6, gap 6)", r.indent == 14, r.indent)
        local src = readFile("42/media/lua/client/ZeD/HealthTab.lua") or ""
        check("the name draws at the tags' indent", src:find("A.drawBody(panel, ZeD.partLabel(entry.name), listX + tagIndent", 1, true) ~= nil)
        check("the tags draw at the indent", src:find("condTags(panel, entry.conditions, listX + tagIndent", 1, true) ~= nil)
        check("measure and draw share the row height", select(2, src:gsub("injuryRowLayout%(bodyH, tagsH%)", "")) >= 2)
    end
end

section("THERMAL: the flat stat bar row")
do
    local rects = {}
    local panel = {
        drawRect = function(_, x, y, w, h, a, r, g, b) rects[#rects + 1] = { x = x, w = w, r = r } end,
        drawText = function() end,
    }
    ZeD.Atoms = {
        fillBarMinW = function() return 40 end, rowBarW = function() return 60 end, fillBarCompactH = function() return 6 end,
        drawSegFill = function() return false end, FILL_SEGS = 10, fillSegsLit = function(r) return math.floor(r * 10) end,
        truncateText = function(s) return s end,
    }
    local ok, err = load("Molecules.lua", { "function ZeD.Molecules.drawStatBarRow(" })
    check("drawStatBarRow cuts and loads", ok, err)
    if ok then
        rects = {}
        ZeD.Molecules.drawStatBarRow(panel, 0, 0, 200, "91.4F", "Head", 0.5, nil, nil, true)
        check("flat: no fill drawn under the row", #rects == 0, #rects)
        rects = {}
        ZeD.Molecules.drawStatBarRow(panel, 0, 0, 200, "91.4F", "Head", 0.5)
        check("ordinary: the inset and the badge still drawn", #rects == 2, #rects)
        local src = readFile("42/media/lua/client/ZeD/ThermalTab.lua") or ""
        local n = select(2, src:gsub("M%.drawStatBarRow%(", ""))
        local flat = select(2, src:gsub("M%.drawStatBarRow%([^\n]*, true%)", ""))
        check("every Thermal stat row is flat", n > 0 and n == flat, flat .. " of " .. n)
    end
end

section("NOTE: the page fills the drawer")
do
    local J = {}
    local ok, err = load("ZeD_JournalReaders.lua", { "function J.fillPageH(" }, { J = J })
    check("fillPageH cuts and loads", ok, err)
    if ok and J.fillPageH then
        local tail = 10 + 40 + 6 + F3_H
        -- a 1056 tall window: the view from 37 to 1000; the page starts at 260
        local minH = J.fillPageH(1000 - 10, 260, tail)
        check("tall drawer: the page reaches the foot", minH and 260 + minH + tail == 990, minH)
        local taller = J.fillPageH(1200 - 10, 260, tail)
        check("a taller drawer gives a taller page", taller and taller > minH, taller)
        check("a drawer with no room left: no least height", J.fillPageH(300, 260, tail) == nil)
        local src = readFile("42/media/lua/client/ZeD/ZeD_JournalReaders.lua") or ""
        check("the page never draws under its own height", src:find("local ph = math.max(T.px(10) + head + rows * lh + T.px(10), minH or 0)", 1, true) ~= nil)
    end
end

section("TRAITS: icon, dot, name")
do
    local ok, err = load("IdentityTab.lua", { "function ZeD.IdentityTab.traitRowLayout(" })
    check("traitRowLayout cuts and loads", ok, err)
    local L = ZeD.IdentityTab.traitRowLayout
    if ok and L then
        local r = L(23)
        check("the icon is the game's 18", r.icon == 18, r.icon)
        check("icon, then dot, then name", r.iconX + r.icon <= r.dotX and r.dotX + r.dot <= r.nameX, r.dotX .. "," .. r.nameX)
        check("the icon sits in the row's middle", r.iconY == 2, r.iconY)
        local src = readFile("42/media/lua/client/ZeD/IdentityTab.lua") or ""
        check("the trait's texture is read from its definition", src:find("texture = traitDef:getTexture() or nil", 1, true) ~= nil)
        check("a trait with no texture draws no icon", src:find("if trait.texture then", 1, true) ~= nil)
    end
end

section("RADIO: the World window's card")
do
    local ok, err = load("ZeD_WorldWindow.lua", { "function ZeD_WorldWindow.tabCardW(" })
    check("tabCardW cuts and loads", ok, err)
    local W = ZeD_WorldWindow.tabCardW
    if ok and W then
        check("radio, a table radio's half want: the full card", W("radio", 220, 220, 480, false) == 480)
        check("radio held in (the Deck): the half card", W("radio", 480, 220, 480, true) == 220)
        check("another full tab stays full", W("maps", 480, 220, 480, false) == 480)
        check("a half tab stays half", W("loot", 220, 220, 480, false) == 220)
        local src = readFile("42/media/lua/client/ZeD/ZeD_WorldWindow.lua") or ""
        check("the drawer width goes through tabCardW", src:find("base = ZeD_WorldWindow.tabCardW(win._activeTab, base, half, full, heldIn)", 1, true) ~= nil)
        local cw = readFile("42/media/lua/client/ZeD/ZeD_CharacterWindow.lua") or ""
        check("the Character window's radio still asks the face (wantW)", cw:find("ZeD.RadioTab.wantW(win, want", 1, true) ~= nil)
    end
end

section("FURN: no indent")
do
    local FT = {}
    local ok, err = load("FurnitureTab.lua", { "function FT.edge(", "function FT.emptyTargetH(" }, { FT = FT })
    check("FT.edge cuts and loads", ok, err)
    if ok then
        check("the edge is the tab pad", FT.edge() == 8, FT.edge())
        check("the empty target is one line tall", FT.emptyTargetH() == BODY_H + 4, FT.emptyTargetH())
        local src = readFile("42/media/lua/client/ZeD/FurnitureTab.lua") or ""
        check("the strip starts at the edge", src:find("local tabL = x + ep\n", 1, true) ~= nil)
        check("the body starts at the edge", src:find("local bx0, bw0 = x + ep, w - ep * 2 - sbW", 1, true) ~= nil)
        check("the empty line draws at x, no box before it", src:find("ZeD.Molecules.drawEmptyLine(panel, x, y, w, msg)", 1, true) ~= nil)
        check("no dashed placeholder left", src:find("dashed(", 1, true) == nil)
    end
end

print(string.format("director_review_fixes_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
