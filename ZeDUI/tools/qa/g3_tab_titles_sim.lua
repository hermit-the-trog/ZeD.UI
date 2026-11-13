-- ZeDUI/tools/qa/g3_tab_titles_sim.lua  (Nov 12 2026, Build): the design review's rulings (punch list 175a,
-- ZeDUI/REVIEW_design_tab_catalog_20261112.md) on Crafting, Building, Cooking, Furniture and the stations, with no
-- game running.
--   C2      every dropdown reads "Label: Value": the real Stations.drawSelect draws "Station:" and the value, and
--           keeps the label in a narrow box (it was "Station Hand", the label dropped when narrow); the category
--           for every recipe is the game's "All", not its crafting window's "-- ALL --" (the real
--           CC.categoryLabel); Building's select has its "Category" label (the real CC.renderStaticHeader); the
--           band's Sort / Show and Cooking's Sort, Dish and In keep their label when short of room
--   C1      every tab body opens with its title: the real CC.renderStaticHeader draws "Crafting" / "Building" on
--           row 1 and the selects on the strip under it; Cooking, Furniture and a station's view the same
--   D6      one section heading style, the small mono line (drawCategoryRow), in all nine files
--   FURN    the version mark's room counts the game's player cap notice on a server for more than 32 (the real
--           FT.versionStackW; versionLines already counted the line)
-- Run from the repo root:  lua51 ZeDUI/tools/qa/g3_tab_titles_sim.lua
-- It prints FAIL lines and a last line "g3_tab_titles_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]g3_tab_titles_sim%.lua$", "")
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
local function noop() end
local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return "" end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end
-- a top-level function from its opening text to its first unindented "end"
local function cutFn(src, open)
    local a = src:find(open, 1, true)
    if not a then return nil end
    local e = src:find("\nend\n", a, true)
    return e and src:sub(a, e + 4) or nil
end

local TR = {
    UI_ZeD_Select_Label = "%1:", UI_ZeD_Station_SelectLabel = "Station", UI_ZeD_Station_Hand = "Hand",
    IGUI_invpanel_Category = "Category", UI_All = "All", UI_ZeD_World_TabBuilding = "Building",
    IGUI_CraftingWindow_Title = "Crafting", IGUI_CraftingCategories_All = "-- ALL --",
}
getText = function(k) return TR[k] or k end
getTextOrNull = function(k) return TR[k] end
local T = {
    scale = 1, stripH = 37, inputH = 22, disabledAlpha = 0.4, borderS = {}, hover = { a = 0.1 }, text = {},
    textDim = {}, textOnFocus = {}, fontF1 = "F1", fontF2 = "F2",
    sp = { inputPadX = 6 },
    px = function(n) return n end,
}
local TM = {
    MeasureStringX = function(_, f, s) return #tostring(s or "") * 7 end,
    getFontHeight = function() return 12 end,
}
local DRAWN, TITLES, SELECTS = {}, {}, {}
ZeD = {
    T = T, TM = TM,
    tr = function(k, a) local s = TR[k] or k; if a ~= nil then s = string.gsub(s, "%%1", tostring(a)) end; return s end,
    upper = string.upper,
    textCase = function(s) return s end,
    Atoms = {
        textCase = function(s) return s end, surfaceFill = noop, frame = noop, drawTriangleDown = noop,
        drawDividerH = noop,
    },
    Focus = { mark = function() return false end },
    Help = { set = noop },
    CraftingCore = {
        truncText = function(s, f, w)
            s = tostring(s or "")
            if #s * 7 <= w then return s end
            local n = math.max(0, math.floor(w / 7) - 3)
            return string.sub(s, 1, n) .. "..."
        end,
    },
}
M = { drawTabHeader = function(_, x, y, w, text) TITLES[#TITLES + 1] = { text = text, y = y }; return T.stripH end }
ZeD.Molecules = M
local panel = {
    drawRect = noop,
    drawText = function(_, s, x) DRAWN[#DRAWN + 1] = { s = s, x = x } end,
    getMouseX = function() return -1 end, getMouseY = function() return -1 end,
}

-- ---------------------------------------------------------------------------
section("C2: the real Stations.drawSelect")
-- ---------------------------------------------------------------------------
local STS = readFile(CL .. "Stations.lua")
local ST = {}
do
    local parts = {}
    for _, open in ipairs({ "function ST.selectLabel(", "function ST.selectW(", "function ST.drawSelect(" }) do
        local p = cutFn(STS, open)
        if p then parts[#parts + 1] = p end
    end
    local chunk = loadstring("local ST = ...\n" .. table.concat(parts), "=Stations.lua (cut)")
    if chunk then chunk(ST) end
end
check("drawSelect cut and loads", type(ST.drawSelect) == "function")
local function texts()
    local out = {}
    for _, d in ipairs(DRAWN) do out[#out + 1] = d.s end
    return table.concat(out, "|")
end
if ST.drawSelect then
    DRAWN = {}
    ST.drawSelect(panel, 0, 0, 300, 22, "Station", "Hand", false, false, false)
    check("a wide box reads 'Station: Hand' (the label with its colon, then the value)",
        DRAWN[1] and DRAWN[1].s == "Station:" and DRAWN[2] and DRAWN[2].s == "Hand", texts())
    check("the value sits after the label", DRAWN[2] and DRAWN[1] and DRAWN[2].x > DRAWN[1].x)
    DRAWN = {}
    ST.drawSelect(panel, 0, 0, 120, 22, "Station", "Advanced Forge", false, false, false)
    check("a narrow box keeps its label (the value is cut)", DRAWN[1] and DRAWN[1].s == "Station:"
        and DRAWN[2] and DRAWN[2].s ~= "Advanced Forge" and string.find(DRAWN[2].s, "...", 1, true) ~= nil, texts())
    DRAWN = {}
    ST.drawSelect(panel, 0, 0, 300, 22, nil, "Hand", false, false, false)
    check("with no label: the value alone", #DRAWN == 1 and DRAWN[1].s == "Hand", texts())
    if ST.selectW then
        check("selectW: the room for the label, its colon and the whole value",
            ST.selectW("Category", "All") >= #("Category:") * 7 + #("All") * 7 + 6)
    end
end

-- ---------------------------------------------------------------------------
section("C2 and C1: the real CraftingCore pieces")
-- ---------------------------------------------------------------------------
ZeD.Stations = ST
ST.current = function() return nil end
local CC = { }
-- (the module's own locals the cut pieces read)
_catLabelCache, DD_MAX_VIS, DD_ROW_H = {}, 9, 26
local cut = dofile(ROOT .. "ZeDUI/tools/qa/cc_cut.lua")
local CCSRC = readFile(CL .. "CraftingCore.lua")
local okCut, errCut = pcall(cut, ROOT, CC, { "local function anyOpen(", "function CC.categoryLabel(",
    "function CC.activeCategoryLabel(", "local function drawCatSelect(", "function CC.placeSearch(",
    "function CC.tabTitleText(", "function CC.renderTabTitle(",
    "function CC.renderStaticHeader(" })
check("the CraftingCore pieces cut and load", okCut, errCut)
if okCut then
    check("the category for every recipe is the game's 'All', not '-- ALL --'", CC.activeCategoryLabel({ activeCat = "all" }) == "All",
        CC.activeCategoryLabel({ activeCat = "all" }))
    check("a named category keeps the game's word", CC.categoryLabel("Cooking") == "Cooking")
    ST.drawSelect = function(_, x, y, w, h, label, value) SELECTS[#SELECTS + 1] = { label = label, value = value, y = y } end
    local function header(config)
        TITLES, SELECTS = {}, {}
        local state = { zones = {}, activeCat = "all" }
        local ok, h = pcall(CC.renderStaticHeader, panel, 0, 0, 600, state, config, { _playerObj = {} })
        return ok, h
    end
    local ok, h = header({ prefix = "build", titleKey = "UI_ZeD_World_TabBuilding" })
    check("Building's header draws", ok, h)
    local cat = SELECTS[#SELECTS]
    check("Building's select is labeled: 'Category: All'", cat and cat.label == "Category" and cat.value == "All",
        cat and (tostring(cat.label) .. " / " .. tostring(cat.value)))
    check("Building opens with its title on row 1", TITLES[1] and TITLES[1].text == "Building" and TITLES[1].y == 0,
        TITLES[1] and TITLES[1].text)
    check("the select sits on the strip under the title", cat and cat.y >= T.stripH, cat and cat.y)
    check("the header is the title row and the strip", ok and h == 2 * T.stripH, h)
    ok, h = header({ prefix = "craft", stations = true, titleVKey = "IGUI_CraftingWindow_Title" })
    check("Crafting's header draws", ok, h)
    check("Crafting opens with its title", TITLES[1] and TITLES[1].text == "Crafting", TITLES[1] and TITLES[1].text)
    check("Crafting's selects: 'Station: Hand' and 'Category: All'", SELECTS[1] and SELECTS[1].label == "Station"
        and SELECTS[1].value == "Hand" and SELECTS[2] and SELECTS[2].label == "Category" and SELECTS[2].value == "All")
end
do
    local a = CCSRC:find("local function drawBandActions(", 1, true)
    local b = a and CCSRC:find("\nfunction CC.renderPopMenu(", a, true)
    local band = a and b and CCSRC:sub(a, b) or ""
    check("the band's Sort box always carries 'Sort: ...' and no choice-alone fallback",
        band:find('drawPopBox(panel, state, "sort", lx, by, sortW, bh, sortName, sortModes, frozen, fid == pfx .. ":sortMenu", mx, my, nil, narrow)', 1, true) ~= nil
        and band:find('local sortName = ZeD.tr("UI_ZeD_Craft_SortPick"', 1, true) ~= nil)
    check("the band's Show box the same",
        band:find('drawPopBox(panel, state, "show", lx, by, showW, bh, showName, showModes, frozen, fid == pfx .. ":showMenu", mx, my, nil, narrow)', 1, true) ~= nil
        and band:find('local showName = ZeD.tr("UI_ZeD_Craft_ShowToggle"', 1, true) ~= nil)
    local pw = cutFn(CCSRC, "local function popWidths(") or ""
    check("short of room the boxes are sized for the label and the choice at tight pads",
        pw:find('M.popupMenuW(ZeD.tr("UI_ZeD_Craft_SortPick", m.label), true)', 1, true) ~= nil
        and pw:find('M.popupMenuW(ZeD.tr("UI_ZeD_Craft_ShowToggle", m.label), true)', 1, true) ~= nil)
    check("Crafting and Building name their title", readFile(CL .. "CraftingTab.lua"):find('titleVKey   = "IGUI_CraftingWindow_Title"', 1, true) ~= nil
        and readFile(CL .. "BuildingTab.lua"):find('titleKey    = "UI_ZeD_World_TabBuilding"', 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("C1 and C2: Cooking, Furniture, a station's view")
-- ---------------------------------------------------------------------------
do
    local CK = readFile(CL .. "CookingTab.lua")
    local hdr = cutFn(CK, "local function renderHeader(") or ""
    check("Cooking opens with its title", hdr:find('M.drawTabHeader(panel, x, y, w, getText("IGUI_perks_Cooking"), false, false, true)', 1, true) ~= nil)
    check("Cooking's header returns the title row and the strip", hdr:find("return titleH + h", 1, true) ~= nil)
    check("Dish keeps its label when short of room", hdr:find('focusFor(s, "cook:dish"), false, nil, false)', 1, true) ~= nil)
    check("In keeps its label when short of room", hdr:find('focusFor(s, "cook:base"), false, nil, false)', 1, true) ~= nil)
    check("Sort keeps its label when short of room", CK:find('focusFor(s, "cook:sort"), false, nil, tight)', 1, true) ~= nil
        and CK:find('label, tight, sw = modes[cur].label, true, 0', 1, true) == nil)
    local FUR = readFile(CL .. "FurnitureTab.lua")
    check("Furniture opens with its title", FUR:find('M.drawTabHeader(panel, x, y, w, getText("IGUI_CraftingCategories_Furniture"), false, false, true)', 1, true) ~= nil)
    check("Furniture's sub-tabs move under the title", FUR:find("local tabY = y + titleH + T.stripH - T.tabH", 1, true) ~= nil)
    local vh = cutFn(STS, "function ST.renderViewHeader(") or ""
    check("a station's view opens with the Crafting title",
        vh:find('ZeD.Molecules.drawTabHeader(panel, x, y, w, getText("IGUI_CraftingWindow_Title"), false, false, true)', 1, true) ~= nil
        and vh:find("return titleH + used", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("D6: one section heading style")
-- ---------------------------------------------------------------------------
for _, f in ipairs({ "CraftingCore.lua", "CraftingTab.lua", "BuildingTab.lua", "CookingTab.lua", "Stations.lua",
                     "StationAppliance.lua", "StationGeneral.lua", "StationMachine.lua", "FurnitureTab.lua" }) do
    local src = readFile(CL .. f)
    check(f .. ": no section head in the large style (drawSectionHeader)", src:find("drawSectionHeader(", 1, true) == nil)
end
do
    local n = select(2, readFile(CL .. "CraftingCore.lua"):gsub("M%.drawCategoryRow%(", ""))
    check("CraftingCore: How to learn, Required and Creates are the small mono line", n >= 3, n)
    n = select(2, readFile(CL .. "FurnitureTab.lua"):gsub("M%.drawCategoryRow%(", ""))
    check("Furniture: May yield, Your furniture and On this tile are the small mono line", n == 3, n)
    check("Cooking's sections are the small mono line", readFile(CL .. "CookingTab.lua"):find("M.drawCategoryRow(panel, x + pad, cy, cw - pad, text, nil, true, _secOpts)", 1, true) ~= nil)
    check("the oven's contents head is the small mono line", readFile(CL .. "StationAppliance.lua"):find("ZeD.Molecules.drawCategoryRow(panel, x + T.px(10), cyy", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("FURN: the version mark's room on a big server")
-- ---------------------------------------------------------------------------
do
    local FUR = readFile(CL .. "FurnitureTab.lua")
    local p = cutFn(FUR, "function FT.versionStackW(")
    local FT = {}
    local chunk = p and loadstring("local FT = ...\n" .. p, "=FurnitureTab.lua (cut)")
    check("versionStackW cut and loads", chunk ~= nil)
    if chunk then
        chunk(FT)
        local NOTE = "32+ player server. Potentially unstable. And a long translation of it, longer than every other line."
        local maxP = 64
        UIFont = { NewSmall = "NS" }
        getTextManager = function() return TM end
        getCheatTypes = function() return { size = function() return 0 end } end
        isClient = function() return true end
        getMaxPlayers = function() return maxP end
        getServerName, getServerIP, getServerPort = function() return "S" end, function() return "1.2.3.4" end, function() return 16261 end
        local saveGT = getText
        getText = function(k) if k == "UI_MaxPlayers_Notification" then return NOTE end return k end
        check("a server for 64: the room takes the player cap notice", FT.versionStackW() >= #NOTE * 7 + 10, FT.versionStackW())
        FT._stackW, maxP = nil, 32
        check("a server for 32: no notice, no room for it", FT.versionStackW() < #NOTE * 7, FT.versionStackW())
        getText = saveGT
        UIFont, getTextManager, getCheatTypes, isClient, getMaxPlayers = nil, nil, nil, nil, nil
        getServerName, getServerIP, getServerPort = nil, nil, nil
    end
end

-- ---------------------------------------------------------------------------
section("STRINGS: the colon in every language")
-- ---------------------------------------------------------------------------
do
    local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT",
                    "JP", "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
    local miss = ""
    for _, L in ipairs(LANGS) do
        local v = readFile("42/media/lua/shared/Translate/" .. L .. "/UI.json"):match('"UI_ZeD_Select_Label": "([^"]*)"')
        if not (v and v:find("%1", 1, true)) then miss = miss .. L .. " " end
    end
    check("UI_ZeD_Select_Label in all 28 languages, with its %1", miss == "", miss)
    check("its context row", readFile("ZeDUI/i18n/UI_ZeD.context.md"):find("`UI_ZeD_Select_Label`", 1, true) ~= nil)
end

print("g3_tab_titles_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
