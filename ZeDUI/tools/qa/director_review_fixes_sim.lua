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
    local ok, err = load("IdentityTab.lua", { "local _traitLay = {}" })
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

        -- the card is still drawn for a piece the cursor read (QA's retake showed only "Point at furniture.":
        -- the shot never aimed the pointer at a piece; the old picture said the same). The real drawTarget, with
        -- the module's constants, on a stand-in panel: a capture gives the picture, the name and the status.
        local a = src:find("local DOT = ", 1, true)
        local b = src:find("local function hit(", 1, true)
        local parts = { "local FT = ...\n", a and b and src:sub(a, b - 1) or "",
                        cutFn(src, "local function dotFor(") or "", cutFn(src, "local function drawTarget(") or "",
                        "return drawTarget\n" }
        local chunk, cerr = loadstring(table.concat(parts), "=FurnitureTab.lua (cut)")
        check("drawTarget cuts and loads", chunk ~= nil, cerr)
        if chunk then
            local okC, drawTarget = pcall(chunk, FT)
            check("drawTarget runs its chunk", okC, drawTarget)
            local T = ZeD.T
            for _, k in ipairs({ "surf1", "borderS", "positive", "danger", "textDim", "border" }) do T[k] = T[k] or { r = 1, g = 1, b = 1, a = 1 } end
            T.fontF4 = "F4"
            ZeD.tr = function(k) return k end
            ZeD.CraftingCore = { truncText = function(s) return s end }
            getTexture = function() return {} end
            local texts, rects, empties = {}, 0, 0
            local panel = {
                drawRect = function() rects = rects + 1 end, drawRectBorder = function() rects = rects + 1 end,
                drawTextureScaledAspect = function() rects = rects + 1 end,
                drawText = function(_, s) texts[#texts + 1] = s end,
            }
            ZeD.Molecules.drawEmptyLine = function() empties = empties + 1; return BODY_H end
            ZeD.Atoms.drawStatusDot = function() end
            local cap = { mp = { name = "Outdoor Bench" }, tex = "furniture_seating_outdoor_01_0", canCreate = false }
            local info = { name = "Outdoor Bench", facts = { { label = "Weight", value = "18.0", state = "plain" } }, notes = {} }
            local okD, hD = pcall(drawTarget, panel, {}, 8, 100, 460, cap, "pickup", info)
            check("a read piece draws its card", okD, hD)
            local joined = table.concat(texts, "|")
            check("the card shows the piece's name", joined:find("Outdoor Bench", 1, true) ~= nil, joined)
            check("the card shows the mode's status (Cannot pick up)", joined:find("UI_ZeD_Furn_PickupNo", 1, true) ~= nil, joined)
            check("the card draws its picture", rects >= 2, rects)
            check("no 'Point at furniture.' over a read piece", empties == 0)
            check("the card is as tall as the picture at least", okD and hD >= 104, hD)
            texts, empties = {}, 0
            local okE, hE = pcall(drawTarget, panel, {}, 8, 100, 460, nil, "pickup", { facts = {}, notes = {} })
            check("nothing read: the one line, flush left", okE and empties == 1 and hE == FT.emptyTargetH(), hE)
        end
        local qa = readFile("ZeDUI/tools/qa/zedqa_director_review.lua") or ""
        check("the retake rests the pointer on a piece before the shot", qa:find("restOn(function() if Z.sc.ok and FU.sx then return FU.sx, FU.sy end", 1, true) ~= nil)
        check("the retake waits until the tab has read the piece", qa:find("return FU.capName() ~= nil", 1, true) ~= nil)
    end
end

-- ---- the second review (Nov 11 2026, director_review_20261111) ----

-- (Nov 12 2026, review) The note stands over the windows from its own see-through note layer (ZeD_MoodleNote),
-- never by raising the moodle layer: a raised layer stayed above every window after its note went, took the
-- windows' pointer in its strip, and a moodle under a window popped its balloon over that window. The whole file
-- runs here in its own globals, on stubs that record what is asked of each panel.
section("MOODLE: the note over the windows, from the note layer; the moodle layer in its place")
do
    local src = readFile("42/media/lua/client/ZeD/ZeD_Moodles.lua") or ""
    local W = { mx = -100, my = -100, over = false, notices = true, safe = false }
    local env = setmetatable({}, { __index = _G })
    env.Events = setmetatable({}, { __index = function(t, k)
        local e = { fns = {} }
        e.Add = function(fn) e.fns[#e.fns + 1] = fn end
        e.Remove = function() end
        rawset(t, k, e)
        return e
    end })
    env.require, env.print = function() end, function() end
    env.getTimestampMs = function() return 5000 end
    env.UIManager = { getMoodleUI = function() return nil end }
    local Base = {}
    Base.__index = Base
    for _, k in ipairs({ "X", "Y" }) do
        Base["get" .. k] = function(self) return self[k:lower()] end
        Base["set" .. k] = function(self, v) self[k:lower()] = v end
    end
    function Base:getWidth() return self.w end
    function Base:getHeight() return self.h end
    function Base:getAbsoluteX() return self.x end
    function Base:getAbsoluteY() return self.y end
    function Base:getMouseX() return W.mx - self.x end
    function Base:getMouseY() return W.my - self.y end
    function Base:isMouseOver() return W.over end
    function Base:initialise() end
    function Base:addToUIManager() self.added = true end
    function Base:setVisible(v) self.visible = v end
    function Base:getIsVisible() return self.visible ~= false end
    function Base:setAlwaysOnTop(b) self.onTop = b end
    function Base:bringToTop() self.tops = (self.tops or 0) + 1 end
    function Base:drawText(s, x, y) self.texts = self.texts or {}; self.texts[#self.texts + 1] = { s = s, x = x, y = y } end
    env.ZeD_Panel = {
        derive = function() return setmetatable({}, { __index = Base }) end,
        new = function(_, x, y, w, h) return setmetatable({ x = x, y = y, w = w, h = h }, Base) end,
    }
    local md = { getMoodleDisplayString = function() return "Hungry" end,
                 getMoodleDescriptionString = function() return "Eat something" end }
    local player = { getMoodles = function() return md end }
    env.getSpecificPlayer = function() return player end
    local canvases = {}
    env.ZeD = {
        T = { px = function(n) return n end, fontF2 = "F2", fontF4 = "F4", text = { r = 1, g = 1, b = 1 },
              textDim = { r = 0.5, g = 0.5, b = 0.5 }, positive = { r = 0, g = 1, b = 0 }, warning = { r = 1, g = 1, b = 0 },
              danger = { r = 1, g = 0, b = 0 } },
        TM = { getFontHeight = function() return 12 end },
        Safe = { on = function() return W.safe end, register = function(_, spec) W.safeSpec = spec end },
        Settings = { moodleNoticesOn = function() return W.notices end },
        Bubbles = { TRAIL_LEN = 3, syncColours = function() end, cloudShadow = function() end, drawTrail = function() end,
                    cloudBody = function(cv) canvases[#canvases + 1] = cv end },
        Px = { k = function() return 1 end, canvas = function(el, ox, oy, k) return { el = el, ox = ox, oy = oy, k = k } end },
        Atoms = { wrapText = function(s) return { s } end, drawStatusDot = function() end },
        Scale = { root = function() return 1 end },
    }
    local chunk, err = loadstring(src, "=ZeD_Moodles.lua")
    check("ZeD_Moodles.lua loads on the stubs", chunk ~= nil, err)
    local ok2, err2 = false, nil
    if chunk then
        setfenv(chunk, env)
        ok2, err2 = pcall(chunk)
        check("it runs", ok2, err2)
    end
    if ok2 then
        local M = env.ZeD.Moodles
        local L = M.install(0)
        local N = L and L._note
        check("installing the layer makes its note layer", N ~= nil and N.added == true)
        check("the note layer stands over every window", N ~= nil and N.onTop == true)
        check("the note layer takes no pointer", N ~= nil and N.wantMouseEvents == false and N.w == 1 and N.h == 1)
        check("the moodle layer is never set over the windows", L.onTop == nil and (L.tops or 0) == 0)
        -- the right column at 1800, 300: one moodle, 48 a side
        L.x, L.y, L.w, L.h = 1800, 300, 48, 1080
        L._mode, L._show, L._size = "right", true, 48
        L._list = { { key = "HUNGRY", type = {}, level = 2, gbn = 2, art = "Status_Hunger" } }
        L:prerender()                          -- (the first look at the player: the levels, no notice)
        L._notices = { "HUNGRY" }
        L:prerender()
        check("a notice: the moodle layer still keeps its place", L.onTop == nil and (L.tops or 0) == 0)
        if N then N:render() end
        local cv = canvases[#canvases]
        local c = L._chip
        check("the note draws on the note layer", cv ~= nil and cv.el == N)
        check("at the moodle's place: the layer's corner plus the note's own spot", cv and c
            and cv.ox == 1800 + c.x and cv.oy == 300 + c.y, cv and c and (cv.ox .. "," .. cv.oy .. " / " .. c.x .. "," .. c.y))
        check("the note left of the column (its place in the layer's own space)", c and c.x + c.w <= 0)
        check("its words on the note layer, nothing on the moodle layer", N and N.texts and #N.texts > 0 and L.texts == nil)
        -- the pointer on the moodle: a window over it there takes it
        W.mx, W.my = 1800 + 10, 300 + 10
        W.over = false
        check("a moodle under a window is not pointed at", L:_hoverIndex() == nil)
        W.over = true
        check("an uncovered moodle is", L:_hoverIndex() == 1)
        check("a press on the strip leaves the layer where it is", rawget(env.ZeD_MoodleLayer, "onFocus") ~= nil
            and (function() L:onFocus(); return (L.tops or 0) == 0 end)())
        -- a game started again: the old note layer draws nothing
        local before = #canvases
        M._layers[0] = nil
        L:prerender()
        if N then N:render() end
        check("a note layer whose moodle layer is gone draws nothing", N ~= nil and #canvases == before)
        M._layers[0] = L
        -- safe mode hides both, taking over again shows both
        if W.safeSpec then
            W.safeSpec.leave()
            check("safe mode hides the note layer with its moodle layer", L.visible == false and N and N.visible == false)
            W.safeSpec.enter()
            check("taking over again shows both", L.visible == true and N and N.visible == true)
        else
            check("safe mode registered", false)
        end
    end
end

section("LOADOUTS: the empty line wraps")
do
    local src = readFile("42/media/lua/client/ZeD/ZeD_EquipLoadout.lua") or ""
    local piece = cutFn(src, "local function wrapEmpty(")
    check("wrapEmpty cut", piece ~= nil)
    if piece then
        ZeD.tr = function(k) return (k == "UI_ZeD_EqBar_EmptyLine") and "lists from the Journal, to restock before you head out" or k end
        ZeD.Atoms = { wrapText = function(text, _, w)
            local out, line = {}, ""
            for word in tostring(text):gmatch("%S+") do
                local try = (line == "") and word or (line .. " " .. word)
                if #try * 8 > w and line ~= "" then out[#out + 1] = line; line = word else line = try end
            end
            if line ~= "" or #out == 0 then out[#out + 1] = line end
            return out
        end }
        local chunk, err = loadstring("local BAR_ROW = 38\nlocal emptyWrap = {}\nlocal function fh(f) return ZeD.TM:getFontHeight(f) end\n"
            .. piece .. "return wrapEmpty\n", "=ZeD_EquipLoadout.lua (cut)")
        check("it loads", chunk ~= nil, err)
        if chunk then
            local wrapEmpty = chunk()
            -- the second row at 1080p 1x (the drawer's 460): the line, Restock 0:00, Save
            local empty = { k = "empty", w = 320 }
            local row = { empty, { k = "verb", w = 104, right = true }, { k = "save", w = 52, right = true } }
            local h = wrapEmpty(row, 460)
            local words = table.concat(empty.lines or {}, " ")
            check("every word kept", words == "lists from the Journal, to restock before you head out", words)
            check("more than one line, the row as tall as its lines", #empty.lines > 1 and h == math.max(38, #empty.lines * F1_H + 8),
                #(empty.lines or {}) .. " lines, " .. h)
            local room = 460 - 16 - 104 - 8 - 52 - 8
            local fits = true
            for _, s in ipairs(empty.lines) do if #s * 8 > room then fits = false end end
            check("each line fits the room the draw gives it", fits)
            -- the Deck: narrower still, more lines, still whole
            local deck = { k = "empty", w = 320 }
            wrapEmpty({ deck, { k = "verb", w = 104, right = true }, { k = "save", w = 52, right = true } }, 340)
            check("at the Deck every word kept", table.concat(deck.lines, " ") == words)
            check("a row with no empty line keeps its height", wrapEmpty({ { k = "ready", w = 80 } }, 460) == 38)
        end
    end
    check("the line is no longer cut", not src:find('trunc(ZeD.tr("UI_ZeD_EqBar_EmptyLine")', 1, true))
    check("the bar's height sums its rows", src:find("for _, rh in ipairs(hs) do h = h + rh end", 1, true) ~= nil)
end

print(string.format("director_review_fixes_sim: %d checks, %d failed", checks, failed))
if failed > 0 then os.exit(1) end
