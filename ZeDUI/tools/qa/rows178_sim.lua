-- ZeDUI/tools/qa/rows178_sim.lua  (Nov 12 2026, Build; punch list 178): the two rows under the title bar, one size each
-- across both windows, checked on the real pieces of the changed files with no game running.
--   TOKENS   the real Tokens.lua's applyTheme at each text size (Small, the default, and Large; there is no third) and
--            UI scale 0.75, 1 and 1.75 (4K at 1.75, 1080p at 1, 1280x800 at 0.75): row 1 (T.stripH) and row 2
--            (T.sortBarH) are there; at Small and scale 1 they are today's 37 and 20; Large is taller than Small at
--            every scale; both grow with the scale; T.sp.tabHeaderH and T.sp.colHdrH are the same numbers; the sort
--            font (T.sortFont) is F5 at Small (today's look) and F1 at Large, which grows, and its line fits row 2
--   FIT      the narrow sort headings at Small and Large, in a real per-face width (F5 about 0.48 of its px a
--            character, F1 0.6): the longest translations of "Cond / Amt" fit the COND column's cap whole
--            (the cap read from the real InventoryRenderer line), and the Equip protection heads are measured
--            in the sort font
--   STOPS    the pad's tab stops (the real _buildTabBarElements and _buildWorldTabBarElements): each one is the
--            strip's width (never past it into the drawer or past the window's edge) and row 1 high
--   BANDS    the station band and the Animals back bar are kept their own height on purpose (a heading and icon,
--            a full-size button); the punch list says so, so QA does not flag them
--   CHAR     the Character window's real drawTabStrip and drawContainerStrip on a recording panel: the top tab's cell,
--            the main container's cell with the line under it, and the tab's header (the real drawTabHeader) are one
--            height with their lines on one y; the strip's sort row starts there and is row 2 high, its word in the
--            sort font; the first container button starts right under it (no gap, no overlap)
--   WORLD    the same for the World window's drawWorldTabStrip and drawWorldContainerStrip (the floor's cell)
--   CONTENT  the inventory's column header: both windows set the heading's offset to row 1 before each draw (so the
--            column header starts where the strips' sort rows do), it is T.sp.colHdrH (row 2) high and its words
--            are in the sort font; no file keeps a copy of 37 or 20 made at load for these rows
--   TABS     the tabs that draw their own row 1 read T.stripH: the sub-tab strips (Furniture, Animals) end on it, the
--            station header is row 1 high with its select centered, the card back bar is row 1 high either way
-- Today's code (before punch list 178) fails TOKENS, CHAR, WORLD and CONTENT: it has no T.stripH or T.sortBarH, its
-- strip rows are T.px(36) + 1 and T.px(20) beside a heading that grows with Large, and its sort words are F5.
-- What it can't show is the look in the game: the in-game check is at Deck size with Large text.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/rows178_sim.lua  [another checkout's root, to run it on that code]
-- It prints FAIL lines and a last line "rows178_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = arg and arg[1] or string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]rows178_sim%.lua$", "")
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
-- the file's top-level number constants (local NAME = 36), for the pieces cut out of it
local function constants(src, into)
    for name, v in src:gmatch("\nlocal ([A-Z][A-Z0-9_]*)%s*=%s*(%-?[%d%.]+)") do into[name] = tonumber(v) end
    return into
end

-- ---------------------------------------------------------------------------
-- THE STUBS: the game
-- ---------------------------------------------------------------------------
local NOW = 1762900000000
getTimestampMs = function() return NOW end
Events = setmetatable({}, { __index = function() return { Add = function() end } end })
triggerEvent = function() end
UIFont = setmetatable({}, { __index = function(_, k) return k end })
local ROOTSC = 1
ZeD = {}
ZeD.Scale = { root = function() return ROOTSC end }
ZeD.Text = { checkRoleFonts = function() return false end }
-- a role font's line: the face's 77/64 of its px at the root (the atlas metrics); a character 0.6 of the px
local function fontPx(f) return (ZeD.T and ZeD.T.fontPx and ZeD.T.fontPx[f]) or 10 end
ZeD.TM = {
    getFontHeight = function(_, f) return math.floor(fontPx(f) * ROOTSC * 77 / 64 + 0.5) end,
    MeasureStringX = function(_, f, s) return math.floor(#tostring(s or "") * fontPx(f) * ROOTSC * 0.6 + 0.5) end,
}
getTextManager = function() return ZeD.TM end

local tokSrc = readFile("42/media/lua/shared/ZeD/Tokens.lua")
local okT, errT = pcall(function() assert(loadstring(tokSrc, "@Tokens.lua"))() end)
check("Tokens.lua loads and applies its default theme on the stubs", okT, errT)

local function apply(size, root)
    ROOTSC = root
    local ok, e = pcall(ZeD.applyTheme, "dark", ZeD.DEFAULT_ACCENT, size)
    if not ok then print("NOTE applyTheme " .. size .. " " .. root .. ": " .. tostring(e)) end
    return ZeD.T
end

local SIZES  = { "small", "large" }
local SCALES = { 0.75, 1, 1.75 }

-- ---------------------------------------------------------------------------
section("TOKENS")
-- ---------------------------------------------------------------------------
local got = {}
for _, root in ipairs(SCALES) do
    got[root] = {}
    for _, size in ipairs(SIZES) do
        local T = apply(size, root)
        local tag = size .. " x" .. root
        got[root][size] = { s = T.stripH, b = T.sortBarH }
        check("TOKENS " .. tag .. ": row 1 (T.stripH) is a whole number of px", type(T.stripH) == "number" and T.stripH == math.floor(T.stripH), T.stripH)
        check("TOKENS " .. tag .. ": row 2 (T.sortBarH) is a whole number of px", type(T.sortBarH) == "number" and T.sortBarH == math.floor(T.sortBarH), T.sortBarH)
        check("TOKENS " .. tag .. ": T.sp.tabHeaderH is row 1", T.sp and T.sp.tabHeaderH == T.stripH, tostring(T.sp and T.sp.tabHeaderH) .. " / " .. tostring(T.stripH))
        check("TOKENS " .. tag .. ": T.sp.colHdrH is row 2", T.sp and T.sp.colHdrH == T.sortBarH, tostring(T.sp and T.sp.colHdrH) .. " / " .. tostring(T.sortBarH))
        local want = (size == "large") and T.fontF1 or T.fontF5
        check("TOKENS " .. tag .. ": the sort font is " .. ((size == "large") and "F1" or "F5 (today's look)"),
            T.sortFont ~= nil and T.sortFont == want, tostring(T.sortFont))
        if type(T.stripH) == "number" then
            check("TOKENS " .. tag .. ": row 1 holds the Find field and the buttons with air",
                T.stripH >= math.max(T.inputH, T.buttonH) + T.px(8), T.stripH .. " vs " .. math.max(T.inputH, T.buttonH))
            check("TOKENS " .. tag .. ": row 1 holds a heading line (F4) with air", T.stripH >= ZeD.TM:getFontHeight(T.fontF4) + T.px(8))
        end
        if type(T.sortBarH) == "number" and T.sortFont then
            local lh = ZeD.TM:getFontHeight(T.sortFont)
            check("TOKENS " .. tag .. ": the sort font's line fits row 2 with air", T.sortBarH >= lh + T.px(4), T.sortBarH .. " vs " .. lh)
        end
    end
end
local s1, l1 = got[1].small, got[1].large
check("TOKENS Small (the default) at scale 1 is today's 37 for row 1", s1.s == 37, s1.s)
check("TOKENS Small (the default) at scale 1 is today's 20 for row 2", s1.b == 20, s1.b)
for _, root in ipairs(SCALES) do
    local s, l = got[root].small, got[root].large
    check("TOKENS x" .. root .. ": row 1 at Large is taller than at Small", type(l.s) == "number" and type(s.s) == "number" and l.s > s.s, tostring(s.s) .. " / " .. tostring(l.s))
    check("TOKENS x" .. root .. ": row 2 at Large is taller than at Small", type(l.b) == "number" and type(s.b) == "number" and l.b > s.b, tostring(s.b) .. " / " .. tostring(l.b))
end
for _, size in ipairs(SIZES) do
    local a, b, c = got[0.75][size], got[1][size], got[1.75][size]
    check("TOKENS " .. size .. ": both rows grow with the UI scale",
        type(a.s) == "number" and a.s < b.s and b.s < c.s and a.b < b.b and b.b < c.b)
    check("TOKENS " .. size .. " x1.75 (4K): row 1 is the scale times row 1 at x1, give or take a px",
        type(c.s) == "number" and math.abs(c.s - b.s * 1.75) <= 1, tostring(c.s) .. " vs " .. tostring(b.s))
end
-- the sort font grows with Large
apply("small", 1); local fSm = ZeD.TM:getFontHeight(ZeD.T.sortFont or ZeD.T.fontF5)
apply("large", 1); local fLg = ZeD.TM:getFontHeight(ZeD.T.sortFont or ZeD.T.fontF5)
check("TOKENS the sort font's line is taller at Large", fLg > fSm, fSm .. " / " .. fLg)
check("TOKENS the sort font at Large is not F5 (tiny there)", ZeD.T.sortFont ~= nil and ZeD.T.sortFont ~= ZeD.T.fontF5)

-- ---------------------------------------------------------------------------
section("FIT")
-- ---------------------------------------------------------------------------
do
    local IR0 = readFile(CL .. "InventoryRenderer.lua")
    local capLine = IR0:match("cond = math%.max%([^\n]*\n([^\n]*)")
    check("FIT the COND cap reads the sort font's width (T.sortWidthK)", capLine and capLine:find("math.floor(90 * scale * (T.sortWidthK or 1))", 1, true) ~= nil, capLine)
    -- the longest headings, as their character counts (the translations, letters with marks counted once)
    local HEADS = { EN = "Cond / Amt", CA = "Cond. / Quant.", ES = "Cond. / Cant.", DE = "Zust. / Menge",
                    DA = "Tilst. / Mgd.", FI = "Kunto / Maara", HU = "All. / Menny.", RU = "Sost. / Kol." }
    for _, root in ipairs(SCALES) do
        for _, size in ipairs(SIZES) do
            local T = apply(size, root)
            local pre = ZeD.TextSizes[size]
            local isF1 = (T.sortFont == T.fontF1)
            local em = isF1 and 0.6 or 0.48
            local fpx = (isF1 and pre.fontF1.px or pre.fontF5.px) * root
            local cap = math.floor(90 * T.scale * (T.sortWidthK or 1))
            local padX = T.sp.sm
            local room = cap - padX - T.px(2)   -- (renderItemList shortens the heading to its cell less the inset and 2u)
            for lang, s in pairs(HEADS) do
                local need = math.ceil(#s * fpx * em)
                check("FIT " .. size .. " x" .. root .. " " .. lang .. ": '" .. s .. "' fits the COND cap whole", need <= room, need .. " vs " .. room)
            end
        end
    end
    local EQ = readFile(CL .. "EquipmentTab.lua")
    local narrow = cutFn(EQ, "local function getNarrowColW(") or ""
    check("FIT Equip: the protection heads are measured in the sort font", narrow:find("MeasureStringX(T.sortFont, ZeD.tr(k))", 1, true) ~= nil)
    check("FIT Equip: the narrow columns are measured again at a new size (keyed on T.scale)", narrow:find("tostring(ZeD.T.scale)", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
-- THE STUBS: ZeD's library and a recording panel
-- ---------------------------------------------------------------------------
local REC
local function newPanel(w, h)
    local p = { rects = {}, texts = {}, zones = {}, divs = {}, w = w, h = h }
    function p:getWidth() return self.w end
    function p:getHeight() return self.h end
    function p:getMouseX() return -1 end
    function p:getMouseY() return -1 end
    function p:getX() return 0 end
    function p:getY() return 0 end
    function p:isMouseOver() return false end
    function p:clearHitZones() self.zones = {} end
    function p:addHitZone(id, x, y, zw, zh) self.zones[#self.zones + 1] = { id = id, x = x, y = y, w = zw, h = zh } end
    function p:drawRect(x, y, rw, rh) self.rects[#self.rects + 1] = { x = x, y = y, w = rw, h = rh } end
    function p:drawText(s, x, y, r, g, b, a, font) self.texts[#self.texts + 1] = { s = s, x = x, y = y, font = font } end
    function p:drawTextureScaledAspect() end
    function p:setStencilRect() end
    function p:clearStencilRect() end
    return p
end
local function zone(p, id)
    for _, z in ipairs(p.zones) do if z.id == id then return z end end
end
local function noop() end
local anyMeta = {}
local ANY = setmetatable({}, anyMeta)
anyMeta.__index = function() return ANY end
anyMeta.__call = function() return nil end
ZeD.Atoms = setmetatable({
    drawDividerH = function(p, x, y, w) p.divs[#p.divs + 1] = y end,
    surfaceFill = noop, mouseIn = function() return false end,
    textCase = function(s) return s end, truncateText = function(s) return s end,
    drawTriangleDown = noop, drawTriangleRight = noop, drawTriangleUp = noop, syncHintLayer = noop,
}, { __index = function() return noop end })
ZeD.Surface = { fill = noop }
ZeD.Help = { set = noop }
ZeD.Focus = { mark = function() return false end }
ZeD.StripDecorators = { run = noop }
ZeD.TabPx = { has = function() return true end, drawTab = noop }
ZeD.tr = function(k) return k end
ZeD.textCase = function(s) return s end
ZeD.logOnce = noop
ZeD.genericContainerTex = function() return nil end

-- the tab's header: the real drawTabHeader / getTabHeaderH
local MOL = readFile(CL .. "Molecules.lua")
-- (TAB_HEADER_H: the copy older code made at load, so the sim runs on that code too)
local molEnv = setmetatable(constants(MOL, { NO_OPTS = {}, TAB_HEADER_H = ZeD.Spacing and ZeD.Spacing.tabHeaderH }), { __index = _G })
for _, from in ipairs({ "function ZeD.Molecules.drawTabHeader(", "function ZeD.Molecules.getTabHeaderH(" }) do
    local piece = cutFn(MOL, from)
    ZeD.Molecules = ZeD.Molecules or {}
    local fn = piece and loadstring(piece, "@Molecules.lua")
    if fn then setfenv(fn, molEnv); fn() end
    check("Molecules.lua: " .. from .. " cut out and loaded", fn ~= nil)
end

-- a window's strip pieces, cut out of the file, run with the file's constants and stubs for its other locals
local function loadPieces(rel, names, extra)
    local src = readFile(rel)
    local env = constants(src, {})
    for k, v in pairs(extra) do env[k] = v end
    setmetatable(env, { __index = _G })
    local out = {}
    for _, name in ipairs(names) do
        local piece = cutFn(src, "local function " .. name .. "(")
        local fn = piece and loadstring(piece:gsub("^local function ", "function "), "@" .. rel)
        if fn then setfenv(fn, env); fn(); out[name] = env[name] end
        check(rel .. ": " .. name .. " cut out and loaded", out[name] ~= nil)
    end
    return out, src
end

local TABS = { { id = "loot", group = 1 }, { id = "health", group = 1 }, { id = "skills", group = 1 } }
local function stubsFor(tabsName)
    local e = {
        isTabVisible = function() return true end,
        tabStripFollow = function(_, _, off) return off end,
        _switchTabForNav = noop, lootDrawerFallback = noop,
        remapCharContainers = noop, buildContainers = function() return {} end,
        buildWorldContainers = function() return {} end, sortContainerOrder = noop, sortWorldContainerOrder = noop,
        _holdWorldView = noop, getMcCapacity = function() return 3 end,
        ZeD_CharacterWindow = { tabLabel = function(t) return t.id end },
        ZeD_WorldWindow = { tabLabel = function(t) return t.id end },
    }
    e[tabsName] = TABS
    return e
end
local function measureTabs(T) return #TABS * (T.stripH or T.px(36)) end

-- one window at one size: where the rows fall in the tab strip, the header and the container strip
local function layout(pieces, tabFn, stripFn, mainId, sortId, firstListId, side)
    local T = ZeD.T
    local win = { _activeTab = "loot", _containerTimer = 1, _containerDueMs = NOW + 1e9, _containerSortMode = "dist",
                  _invDrawerOpen = true, _mainVisible = true, _activeContainer = nil, _mcSelected = {},
                  _radios = {}, _radioIdx = 1, _containerOrder = nil }
    local floor = { name = "Floor", isFloor = true }
    if side == "char" then
        win._containers = { { name = "Inventory", isMain = true }, { name = "Bag" }, { name = "Fanny pack" } }
    else
        win._containers = { { name = "Crate" }, { name = "Shelf" }, floor }
        win._activeContainer = 3
    end
    local tabP = newPanel(T.px(36), 800)
    local okA, eA = pcall(pieces[tabFn], tabP, win)
    local stripP = newPanel(T.px(36), 800)
    local okB, eB = pcall(pieces[stripFn], stripP, win, { _colStates = {} })
    local hdrP = newPanel(400, 800)
    local okH, hh = pcall(ZeD.Molecules.drawTabHeader, hdrP, 0, 0, 400, "Health", true, false)
    if not okH then print("NOTE drawTabHeader: " .. tostring(hh)); hh = nil end
    return { okA = okA, eA = eA, okB = okB, eB = eB, tab = zone(tabP, "tab:loot"), tabRects = tabP.rects,
             main = zone(stripP, mainId), sort = zone(stripP, sortId), list = zone(stripP, firstListId),
             stripDivs = stripP.divs, stripTexts = stripP.texts, hdrH = hh, hdrDiv = hdrP.divs[#hdrP.divs] }
end

local function windowChecks(label, pieces, tabFn, stripFn, mainId, sortId, firstListId, side)
    for _, root in ipairs(SCALES) do
        for _, size in ipairs(SIZES) do
            local T = apply(size, root)
            local tag = label .. " " .. size .. " x" .. root
            local L = layout(pieces, tabFn, stripFn, mainId, sortId, firstListId, side)
            check(tag .. ": the tab strip draws on the stubs", L.okA, L.eA)
            check(tag .. ": the container strip draws on the stubs", L.okB, L.eB)
            -- (older code has no shared rows: its header's own height and the 20 its sort rows used stand in, so the
            -- checks below still say where it falls apart)
            check(tag .. ": the shared rows exist", type(T.stripH) == "number" and type(T.sortBarH) == "number")
            local r1, r2 = T.stripH or L.hdrH, T.sortBarH or T.px(20)
            if type(r1) == "number" then
                check(tag .. ": the tab's header is row 1 high", L.hdrH == r1, tostring(L.hdrH) .. " vs " .. r1)
                check(tag .. ": the header's line is row 1's last px", L.hdrDiv == r1 - T.px(1), tostring(L.hdrDiv) .. " vs " .. (r1 - T.px(1)))
                check(tag .. ": the top tab's cell is row 1 high, from the top", L.tab and L.tab.y == 0 and L.tab.h == r1,
                    L.tab and (L.tab.y .. "+" .. L.tab.h) or "no tab zone")
                local tabLine = nil
                if L.tab then
                    for _, rc in ipairs(L.tabRects) do
                        if rc.h == T.px(1) and rc.y > 0 and rc.y < L.tab.h + 2 and rc.w > T.px(20) then tabLine = rc.y; break end
                    end
                end
                check(tag .. ": the top tab's line is on the header's line", tabLine ~= nil and tabLine == L.hdrDiv, tostring(tabLine) .. " vs " .. tostring(L.hdrDiv))
                check(tag .. ": the strip's top cell starts at the top", L.main and L.main.y == 0, L.main and L.main.y)
                local mainBottom = L.main and (L.main.y + L.main.h)
                check(tag .. ": the strip's top cell's line is on the header's line", L.main and mainBottom == L.hdrDiv,
                    tostring(mainBottom) .. " vs " .. tostring(L.hdrDiv))
                check(tag .. ": the strip's sort row starts where row 1 ends", L.sort and L.sort.y == r1, L.sort and (L.sort.y .. " vs " .. r1))
                check(tag .. ": the strip's sort row is row 2 high", L.sort and L.sort.h == r2, L.sort and (L.sort.h .. " vs " .. r2))
                check(tag .. ": the first container button starts right under row 2 (no gap, no overlap)",
                    L.list and L.list.y == r1 + r2, L.list and (L.list.y .. " vs " .. (r1 + r2)))
                local word
                for _, t in ipairs(L.stripTexts) do if tostring(t.s):find("Sort") then word = t end end
                check(tag .. ": the sort row's word is in the sort font", word and T.sortFont and word.font == T.sortFont, word and word.font)
                check(tag .. ": the sort row's word sits inside row 2", word and word.y >= r1 and word.y + ZeD.TM:getFontHeight(word.font) <= r1 + r2,
                    word and word.y)
            end
        end
    end
end

-- ---------------------------------------------------------------------------
section("CHAR")
-- ---------------------------------------------------------------------------
local cwExtra = stubsFor("CHAR_TABS")
cwExtra.measureTabStripH = function() return measureTabs(ZeD.T) end
local CWP, CWS = loadPieces(CL .. "ZeD_CharacterWindow.lua", { "drawTabStrip", "drawContainerStrip", "_buildTabBarElements" }, cwExtra)
if CWP.drawTabStrip and CWP.drawContainerStrip then
    windowChecks("CHAR", CWP, "drawTabStrip", "drawContainerStrip", "main_toggle", "wt_sort", "cnt:2", "char")
end

-- ---------------------------------------------------------------------------
section("WORLD")
-- ---------------------------------------------------------------------------
local WWS0 = readFile(CL .. "ZeD_WorldWindow.lua")
local wTabs = WWS0:match("for _, tab in ipairs%(([%w_]+)%) do") or "WORLD_TABS"
local wwExtra = stubsFor("ACTION_TABS")
for name in WWS0:gmatch("ipairs%(([A-Z_]+_TABS)%)") do wwExtra[name] = TABS end
wwExtra.measureWorldTabStripH = function() return measureTabs(ZeD.T) end
wwExtra.worldTabStripFollow = function(_, _, off) return off end
local WWP, WWS = loadPieces(CL .. "ZeD_WorldWindow.lua", { "_worldStripListOrder", "drawWorldTabStrip", "drawWorldContainerStrip", "_buildWorldTabBarElements" }, wwExtra)
if WWP.drawWorldTabStrip and WWP.drawWorldContainerStrip then
    -- the floor is the last container, pinned at the top: its zone is its index (3); the first list button is 1
    windowChecks("WORLD", WWP, "drawWorldTabStrip", "drawWorldContainerStrip", 3, "wt_sort", 1, "world")
end

-- ---------------------------------------------------------------------------
section("CONTENT")
-- ---------------------------------------------------------------------------
local IRS = readFile(CL .. "InventoryRenderer.lua")
for name, src in pairs({ CharacterWindow = CWS, WorldWindow = WWS }) do
    check("CONTENT " .. name .. ": the heading's offset is row 1 at build",
        src:find("content._hdrYOffset = T.stripH", 1, true) and src:find("content._defaultHdrYOffset = T.stripH", 1, true))
    check("CONTENT " .. name .. ": the side-by-side columns' offset is set again before each draw",
        src:find("self._defaultHdrYOffset = ZeD.T.stripH[^\n]*\n%s*r.renderMultiColumnContent%(self%)") ~= nil)
    check("CONTENT " .. name .. ": the one list's offset is set again before each draw",
        src:find("self._hdrYOffset = ZeD.T.stripH[^\n]*\n%s*r.renderItemList%(self%)") ~= nil)
    check("CONTENT " .. name .. ": no 20 of its own for the sort row", not src:find("colHdrH%s*=%s*T%.px%(20%)"))
end
check("CONTENT the column header is T.sp.colHdrH (row 2) high", IRS:find("local colHdrH  = T.sp.colHdrH", 1, true) ~= nil)
check("CONTENT the column header's top is the heading's offset (row 1) down",
    IRS:find("local hdrY    = barH + ((type(hdrYOff) == \"number\") and hdrYOff or 0) + (self._fbarH or 0)", 1, true) ~= nil)
check("CONTENT no 37 of its own for the heading", not IRS:find("_defaultHdrYOffset or T%.px%(37%)") and not IRS:find("_defaultHdrYOffset or ZeD%.T%.px%(37%)"))
local hdrBlock = IRS:match("COLUMN HEADER BAR.-DRAW ROWS") or ""
check("CONTENT the column header's words are in the sort font", hdrBlock:find("T.sortFont", 1, true) ~= nil and not hdrBlock:find("T.fontF5", 1, true))
check("CONTENT the grid's sort keys are measured in the sort font", (cutFn(IRS, "local function gridSortDefs(") or ""):find("T.sortFont", 1, true) ~= nil)
-- nothing copies the rows at load
for _, rel in ipairs({ "Molecules.lua", "CraftingCore.lua", "MapsTab.lua", "EquipmentTab.lua", "MechanicsTab.lua", "RadioTab.lua",
                       "CookingTab.lua", "ObjectCards.lua", "ZeD_EquipLoadout.lua", "ForagingTab.lua" }) do
    local src = readFile(CL .. rel)
    local copy = src:match("\nlocal [%w_]+%s*=%s*%(?ZeD%.Spacing and ZeD%.Spacing%.tabHeaderH%)?[^\n]*")
              or src:match("\nlocal [%w_]+%s*=%s*%(?ZeD%.Spacing and ZeD%.Spacing%.colHdrH%)?[^\n]*")
    check("CONTENT " .. rel .. ": no copy of the rows made at load", copy == nil, copy)
    check("CONTENT " .. rel .. ": no 37 for row 1", not src:find("T%.px%(37%)") and not src:find("tabHeaderH%) or 37%)"))
end

-- ---------------------------------------------------------------------------
section("STOPS")
-- ---------------------------------------------------------------------------
-- the strips are T.px(36) wide in both windows (TAB_STRIP_W, ACTION_TAB_STRIP_W)
local function stopChecks(label, build, stripName, srcText)
    local stripW = constants(srcText, {})[stripName]
    check(label .. ": " .. stripName .. " read from the file", type(stripW) == "number", stripW)
    if not (build and stripW) then return end
    for _, root in ipairs(SCALES) do
        for _, size in ipairs(SIZES) do
            local T = apply(size, root)
            local ok, els = pcall(build, {})
            local tag = label .. " " .. size .. " x" .. root
            check(tag .. ": the tab stops build on the stubs", ok and type(els) == "table" and #els == #TABS, ok and #els or els)
            if ok and type(els) == "table" then
                for i, e in ipairs(els) do
                    check(tag .. " stop " .. i .. ": the strip's width, not past it", e.x == 0 and e.w == T.px(stripW), e.w .. " vs " .. T.px(stripW))
                    check(tag .. " stop " .. i .. ": row 1 high, one under the other", e.h == T.stripH and e.y == (i - 1) * T.stripH, e.y .. "+" .. e.h)
                end
            end
        end
    end
end
stopChecks("STOPS CHAR", CWP._buildTabBarElements, "TAB_STRIP_W", CWS)
stopChecks("STOPS WORLD", WWP._buildWorldTabBarElements, "ACTION_TAB_STRIP_W", WWS)

-- ---------------------------------------------------------------------------
section("BANDS")
-- ---------------------------------------------------------------------------
do
    local PL = readFile("ZeDUI/PUNCH_LIST.md")
    local e178 = PL:match("\n178%. .*") or ""
    check("BANDS the punch list keeps the station band and the Animals back bar their own height, on purpose",
        e178:find("station band", 1, true) ~= nil and e178:find("back bar", 1, true) ~= nil)
    local STS = readFile(CL .. "Stations.lua")
    check("BANDS Stations: the band is its own 28u (a heading and an icon)", STS:find("\nST.BAND_H = 28", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("TABS")
-- ---------------------------------------------------------------------------
local FUR, ANI = readFile(CL .. "FurnitureTab.lua"), readFile(CL .. "AnimalsTab.lua")
-- (Nov 12 2026, design review C1 + D6: every tab's title is row 1, the sub-tabs end on the strip under it)
check("TABS Furniture: the sub-tabs sit at the foot of the strip under the title", FUR:find("local tabY = y + titleH + T.stripH - T.tabH", 1, true) ~= nil)
check("TABS Animals: row 1 is the tab's title, the sub-tabs under it",
    ANI:find('local titleH = M.drawTabHeader(panel, x, y, w, ZeD.tr("UI_ZeD_World_TabAnimals"), false, false, true)', 1, true) ~= nil)
-- the station header (the real renderViewHeader)
do
    local STS = readFile(CL .. "Stations.lua")
    local piece = cutFn(STS, "function ST.renderViewHeader(")
    local ST = { drawSelect = noop, drawBand = function() return 0 end }
    local env = setmetatable({ ST = ST, getText = function(k) return k end }, { __index = _G })
    local fn = piece and loadstring(piece, "@Stations.lua")
    if fn then setfenv(fn, env); fn() end
    check("TABS Stations: renderViewHeader cut out and loaded", ST.renderViewHeader ~= nil)
    if ST.renderViewHeader then
        for _, root in ipairs(SCALES) do
            for _, size in ipairs(SIZES) do
                local T = apply(size, root)
                local p = newPanel(400, 600)
                local state = { zones = {} }
                local used = ST.renderViewHeader(p, { _playerObj = {} }, 0, 0, 400, state, { name = "Bench" })
                local z = state.zones[1]
                -- (Nov 12 2026, design review C1: the tab's title on row 1, the select on the strip under it)
                check("TABS station header " .. size .. " x" .. root .. ": the title row and the strip, each row 1 high",
                    used == 2 * T.stripH, tostring(used) .. " vs " .. tostring(T.stripH))
                check("TABS station header " .. size .. " x" .. root .. ": its select centered in the strip under the title",
                    z and type(T.stripH) == "number" and math.abs((z.y + z.h / 2) - (T.stripH + T.stripH / 2)) <= 1, z and z.y)
            end
        end
    end
end
-- the card back bar (the real drawCardBackBar): row 1 high, compact or not
do
    local piece = cutFn(MOL, "function ZeD.Molecules.drawCardBackBar(")
    check("Molecules.lua: drawCardBackBar is row 1 high, compact or not",
        piece and piece:find("h, btnH, padX, gap, btnPadX = T.stripH, T.buttonH - T.px(4)", 1, true)
              and piece:find("h, btnH, padX, gap, btnPadX = T.stripH, T.buttonH, T.px(6)", 1, true))
end

print("rows178_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
