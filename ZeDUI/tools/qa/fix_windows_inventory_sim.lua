-- ZeDUI/tools/qa/fix_windows_inventory_sim.lua  (Nov 12 2026, Build): the tab catalog's design review, the windows
-- and inventory items, checked on the real pieces of the changed files with no game running.
--   WEIGHT    one way to write a load over a capacity: ZeD.Atoms.loadText, "5.8 / 28 kg" (the load to one decimal,
--             the capacity without ".0" when whole), the load alone where there is no capacity (the floor); every
--             inventory heading, the Character window's title bar and the item card write it, and no other load
--             format is left in them; all 28 languages have both strings, spaced, in one unit
--   COUNT     a bare character's heading counts what the list shows: the glasses worn and the knife in hand are in
--             the container but not in the rows, so the heading says what the rows say ("0 items" over "Nothing
--             here."); the headings, the columns and the help line all read the list's own count (shownCount)
--   CATEGORY  a row's category words run on into an empty Cond cell (no bar, no read mark): rowCondition says when
--             it drew; a row with a bar keeps the cell; the card's Kind word is run in card_model_sim
--   GAP       the Character and World windows side by side: the crack between them is drawn in the frame's color,
--             by the left one, where they overlap; apart, not overlapping, or one hidden, nothing is drawn
--   VERSION   the version line at the lower right ("42.22.2 ... pzBullet") is the game's own watermark
--             (ISVersionWaterMark): no ZeD file draws, moves or hides it, so it is left as the game has it
-- Run from the repo root:  lua51 ZeDUI/tools/qa/fix_windows_inventory_sim.lua
-- It prints FAIL lines and a last line "fix_windows_inventory_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]fix_windows_inventory_sim%.lua$", "")
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
-- a piece of a file: from `from` (plain) to the first "\nend\n" after it, as a chunk
local function cutFn(src, from)
    local a = src:find(from, 1, true)
    local b = a and src:find("\nend\n", a, true)
    return (a and b) and src:sub(a, b + 4) or nil
end

-- the English words, as the game gives them (%1.. filled in, %% a percent sign)
local EN = readFile("42/media/lua/shared/Translate/EN/UI.json")
local function enTr(key, ...)
    local s = EN:match('"' .. key .. '": "(.-)",?\n')
    if not s then return key end
    local a = { ... }
    s = s:gsub("%%(%d)", function(d) local v = a[tonumber(d)]; return v ~= nil and tostring(v) or "" end)
    return (s:gsub("%%%%", "%%"))
end

local NOW = 1762900000000
getTimestampMs = function() return NOW end
Events = setmetatable({}, { __index = function() return { Add = function() end } end })
instanceof = function() return false end
ZeD = {
    tr = enTr, _trGen = 1,
    T = { px = function(n) return n end, borderS = { r = 0.1, g = 0.2, b = 0.3, a = 1 } },
    Atoms = {},
    InventoryRenderer = { catKey = function(item) return item.cat or "Other" end },
    ContainerGates = {
        get = function() return nil end, keeps = function() return true end,
        count = function(inv) return inv and inv:getItems():size() or 0 end,
    },
    ContainerGroups = { groupOf = function() return nil end, keys = function() return {} end,
                        sortKeys = function(k) table.sort(k) end, sig = function() return false end },
    ItemMeter = { sortKey = function() return 1 end },
}
stackWeight = function() return 0 end

local CWS, WWS, IRS = readFile(CL .. "ZeD_CharacterWindow.lua"), readFile(CL .. "ZeD_WorldWindow.lua"), readFile(CL .. "InventoryRenderer.lua")

-- ---------------------------------------------------------------------------
section("WEIGHT (one format for a load over a capacity)")
do
    local piece = cutFn(readFile(CL .. "Atoms.lua"), "function ZeD.Atoms.loadText(load, cap)")
    check("WEIGHT: Atoms.lua writes a load over a capacity (loadText)", piece ~= nil)
    if piece then assert(loadstring(piece, "=loadText"))() end
    local LT = ZeD.Atoms.loadText or function() return "" end
    check("WEIGHT: 5.83 of 28: 5.8 / 28 kg", LT(5.83, 28) == "5.8 / 28 kg", LT(5.83, 28))
    check("WEIGHT: nothing of 8: 0.0 / 8 kg", LT(0, 8) == "0.0 / 8 kg", LT(0, 8))
    check("WEIGHT: a capacity not whole keeps its decimal: 5.8 / 27.5 kg", LT(5.8, 27.5) == "5.8 / 27.5 kg", LT(5.8, 27.5))
    check("WEIGHT: a capacity that rounds to whole: 4.0 / 28 kg", LT(4, 27.96) == "4.0 / 28 kg", LT(4, 27.96))
    check("WEIGHT: no capacity (the floor): the load alone, 2.0 kg", LT(2, 0) == "2.0 kg", LT(2, 0))
    -- every place that writes a load over a capacity
    local ICO, IFP = readFile(CL .. "ItemCardOrganism.lua"), readFile(CL .. "ItemFactsPanel.lua")
    check("WEIGHT: the title bar's weight", CWS:find("{ text = ZeD.Atoms.loadText(weight, maxWt), noMark = true }", 1, true) ~= nil)
    check("WEIGHT: the Character window's heading", CWS:find("or ZeD.Atoms.loadText(cWeight, cMax),", 1, true) ~= nil)
    check("WEIGHT: the World window's heading", WWS:find("or ZeD.Atoms.loadText(cWeight, cMax),", 1, true) ~= nil)
    check("WEIGHT: the columns' headings", IRS:find("or ZeD.Atoms.loadText(weight, capacity)", 1, true) ~= nil)
    check("WEIGHT: the item card's capacity", ICO:find("held and ZeD.Atoms.loadText(held, cap)", 1, true) ~= nil)
    check("WEIGHT: Container Facts' capacity", IFP:find("ZeD.Atoms.loadText(current, cap)", 1, true) ~= nil)
    local stale = {}
    for name, src in pairs({ CharacterWindow = CWS, WorldWindow = WWS, InventoryRenderer = IRS, ItemCardOrganism = ICO,
                             ItemFactsPanel = IFP }) do
        if src:find('"%.1f/%', 1, true) or src:find("/%skg", 1, true) or src:find('"%.1f / %d kg"', 1, true)
           or src:find('weight .. " / " .. maxWt', 1, true) or src:find('UI_ZeD_Char_WeightOfMax", string.format', 1, true) then
            stale[#stale + 1] = name
        end
    end
    table.sort(stale)
    check("WEIGHT: no other load format left", #stale == 0, table.concat(stale, ","))
    local LANGS = { "AR", "CA", "CH", "CN", "CS", "DA", "DE", "EN", "ES", "ES_CL", "ES_MX", "FI", "FR", "HU", "ID", "IT", "JP",
                    "KO", "NL", "NO", "PL", "PT", "PTBR", "RO", "RU", "TH", "TR", "UA" }
    local bad = {}
    for _, L in ipairs(LANGS) do
        local t = readFile("42/media/lua/shared/Translate/" .. L .. "/UI.json")
        local wom = t:match('"UI_ZeD_Char_WeightOfMax": "([^"]*)"')
        local lk = t:match('"UI_ZeD_Inv_LoadKg": "([^"]*)"')
        local u1 = wom and wom:match("^%%1 / %%2 (%S+)$")
        local u2 = lk and lk:match("^%%1 (%S+)$")
        if not (u1 and u2 and u1 == u2) then bad[#bad + 1] = L end
    end
    check("WEIGHT: all 28 languages: '%1 / %2 <unit>' and '%1 <unit>', one unit", #bad == 0, table.concat(bad, ","))
    local ctx = readFile("ZeDUI/i18n/UI_ZeD.context.md")
    check("WEIGHT: the translators' notes have both rows",
        ctx:find("| `UI_ZeD_Char_WeightOfMax` | `%1 / %2 kg` |", 1, true) ~= nil and ctx:find("| `UI_ZeD_Inv_LoadKg` | `%1 kg` |", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("COUNT (the heading counts what the list shows)")
do
    local a = IRS:find("local MODEL_REFRESH_MS", 1, true)
    local b = a and IRS:find("-- ROW PARTS", a, true)
    check("COUNT: the list's model and its count cut out of InventoryRenderer.lua", a ~= nil and b ~= nil)
    local itemModel = assert(loadstring(IRS:sub(a or 1, (b or 2) - 1) .. "\nreturn itemModel", "=model"))()
    local shownCount = ZeD.InventoryRenderer.shownCount
    check("COUNT: InventoryRenderer.shownCount", shownCount ~= nil)
    -- a bare character: glasses on the face, a knife in the hand, both in the inventory's container
    local things = {}
    local inv = {}
    local function thing(name, cat)
        local it = { nm = name, cat = cat }
        function it:getName() return name end
        function it:isHidden() return false end
        function it:getContainer() return inv end
        function it:getFullType() return "Base." .. name end
        function it:getDisplayCategory() return cat end
        function it:getUnequippedWeight() return 0.1 end
        things[#things + 1] = it
        return it
    end
    local glasses, knife = thing("Glasses", "Accessory"), thing("Knife", "ToolWeapon")
    local P = {}
    function inv:getItems() return { size = function() return #things end, get = function(_, i) return things[i + 1] end } end
    function inv:getParent() return P end
    function inv:getCapacityWeight() return #things * 0.1 end
    function P:getInventory() return inv end
    function P:getWornItems() return { size = function() return 1 end, get = function() return { getItem = function() return glasses end } end } end
    function P:getPrimaryHandItem() return knife end
    function P:getSecondaryHandItem() return nil end
    function P:isEquipped(it) return it == glasses or it == knife end
    local panel = {}
    local fresh = shownCount and shownCount(panel, inv, P)
    check("COUNT: before the list has drawn: the container's own count", fresh == 2, fresh)
    local M = itemModel(panel, inv, P, true, "cat", true, {}, {})
    check("COUNT: the list shows neither the glasses nor the knife", M and #M.flatItems == 0, M and #M.flatItems)
    local n = shownCount and shownCount(panel, inv, P)
    check("COUNT: the heading counts what the list shows: 0, not the container's 2", n == 0, n)
    check("COUNT: so the heading reads 0 items over Nothing here.", enTr(n == 1 and "UI_ZeD_Char_ItemsOne" or "UI_ZeD_Char_ItemsMany", n)
        == "0 items", enTr("UI_ZeD_Char_ItemsMany", n))
    thing("Apple", "Food")
    NOW = NOW + 16
    M = itemModel(panel, inv, P, true, "cat", true, {}, {})
    n = shownCount and shownCount(panel, inv, P)
    check("COUNT: an apple put in: 1 in the rows, 1 in the heading", #M.flatItems == 1 and n == 1, n)
    -- every count of the rows reads it: both windows' headings, the columns' headings, the help line's columns
    local PK = readFile(CL .. "InventoryPicked.lua")
    check("COUNT: the Character window's heading and help line", CWS:find("local cItems = cInv and ZeD.InventoryRenderer.shownCount(self, cInv, win._playerObj) or 0", 1, true) ~= nil)
    check("COUNT: the World window's heading and help line", WWS:find("local cItems = cInv and ZeD.InventoryRenderer.shownCount(self, cInv, win._playerObj) or 0", 1, true) ~= nil)
    check("COUNT: the columns' headings", IRS:find("local itemCount = inv and ZeD.InventoryRenderer.shownCount(self, inv, self._playerObj) or 0", 1, true) ~= nil)
    check("COUNT: the help line's count across columns", PK:find("ZeD.InventoryRenderer.shownCount(holder, cs.inventory, playerObj)", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("CATEGORY (the words run on into an empty Cond cell)")
do
    local piece = cutFn(IRS, "local function rowCondition(self, item, x, y, w, rowH, stackInfo)")
    check("CATEGORY: rowCondition cut out", piece ~= nil)
    local bars = 0
    ZeD.Atoms.drawFillBar = function() bars = bars + 1 end
    ZeD.Atoms.fillBarCompactH = function() return 8 end
    ZeD.ItemMeter = {
        ofStack = function(item) return item.kind, item.f end,
        style = function() return nil, true end,
        label = function() return "Condition" end,
    }
    local rowCondition = assert(loadstring((piece or "") .. "\nreturn rowCondition", "=rowCondition"))()
    local can, axe = { kind = nil }, { kind = "cond", f = 0.6 }
    local drewCan = rowCondition({}, can, 0, 0, 60, 26, nil)
    check("CATEGORY: a row with no bar leaves the cell empty and says so", drewCan == false and bars == 0, tostring(drewCan))
    local drewAxe = rowCondition({}, axe, 0, 0, 60, 26, nil)
    check("CATEGORY: a row with a bar draws it and says so", drewAxe == true and bars == 1, tostring(drewAxe))
    check("CATEGORY: the row asks the Cond cell first and lends an empty one to the category",
        IRS:find("condFree = not rowCondition(self, item, xOff + condX + T.px(2), y, condColW - T.px(4), rowH, stackInfo)", 1, true) ~= nil
        and IRS:find("catColW - padX * 2 + (condFree and condColW or 0))", 1, true) ~= nil)
    local a = IRS:find("local condFree = showCond", 1, true)
    local b = a and IRS:find("if showCat then", a, true)
    local cond = (a and b) and IRS:sub(a, b) or ""
    check("CATEGORY: a read mark keeps its cell", cond:find("drawReadCond(", 1, true) ~= nil and cond:find("condFree = false", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("GAP (the crack between the two windows side by side)")
do
    local OR = readFile(CL .. "Organisms.lua")
    local a = OR:find("local PAIR_GAP = ", 1, true)
    local piece = a and cutFn(OR:sub(a), "local PAIR_GAP = ")
    check("GAP: drawPairGap cut out of Organisms.lua", piece ~= nil)
    local drawPairGap = assert(loadstring((piece or "") .. "\nreturn drawPairGap", "=drawPairGap"))()
    local function win(key, x, y, w, h)
        local o = { key = key, x = x, y = y, w = w, h = h, vis = true }
        function o:pairKey() return self.key end
        function o:getX() return self.x end
        function o:getY() return self.y end
        function o:getWidth() return self.w end
        function o:shownHeight() return self.h end
        function o:isVisible() return self.vis end
        return o
    end
    local CWw, WWw = win("char", 331, 0, 304, 420), win("world", 645, 0, 304, 420)
    ZeD_CharacterWindow = { getWindow = function() return CWw end }
    ZeD_WorldWindow = { getWindow = function() return WWw end }
    local RECTS = {}
    local P = { drawRect = function(_, x, y, w, h, a2, r) RECTS[#RECTS + 1] = { x = x, y = y, w = w, h = h, r = r } end }
    local function run(w)
        RECTS = {}
        if drawPairGap then drawPairGap(w, P, w:getWidth(), w:shownHeight()) end
        return RECTS
    end
    local r = run(CWw)
    check("GAP: the spread's 10 px crack is drawn by the left window, its full height",
        #r == 1 and r[1].x == 304 and r[1].w == 10 and r[1].y == 0 and r[1].h == 420 and r[1].r == ZeD.T.borderS.r, #r)
    check("GAP: the right window draws nothing there", #run(WWw) == 0)
    WWw.y, WWw.h = 100, 500
    r = run(CWw)
    check("GAP: only where the two overlap top to bottom", #r == 1 and r[1].y == 100 and r[1].h == 320, r[1] and (r[1].y .. "+" .. r[1].h))
    WWw.y, WWw.h = 0, 420
    WWw.x = 700
    check("GAP: two windows apart (45 px) are not a spread: nothing drawn", #run(CWw) == 0)
    WWw.x, WWw.y = 645, 430
    check("GAP: one under the other: nothing drawn", #run(CWw) == 0)
    WWw.y, WWw.vis = 0, false
    check("GAP: the other window shut: nothing drawn", #run(CWw) == 0)
    WWw.vis = true
    -- the World window on the left: it draws the crack
    WWw.x, CWw.x = 20, 334
    r = run(WWw)
    check("GAP: the windows swapped: the World window, on the left, draws it", #r == 1 and r[1].x == 304 and r[1].w == 10, #r)
    WWw.x, CWw.x = 645, 331
    check("GAP: the frame draw calls it", OR:find("    drawFrameRect(p, w, h, lit)\n    drawPairGap(win, p, w, h)", 1, true) ~= nil)
end

-- ---------------------------------------------------------------------------
section("VERSION (the game's own line, left as it is)")
do
    local van = io.open("E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/lua/client/ISUI/ISVersionWaterMark.lua", "rb")
    if van then
        local vs = van:read("*a")
        van:close()
        check("VERSION: the game draws it (ISVersionWaterMark: the version and pzBullet, at the lower right)",
            vs:find('"pzBullet(" .. getCore():getBulletVersion()', 1, true) ~= nil and vs:find("getCore():getScreenWidth() - 10", 1, true) ~= nil)
    else
        print("  (the game's Lua is not on this machine: the vanilla side is not read)")
    end
    local touched = {}
    for _, rel in ipairs({ "ZeD_CharacterWindow.lua", "ZeD_WorldWindow.lua", "Organisms.lua", "InventoryRenderer.lua", "ZeD_HUD.lua",
                           "SafeMode.lua", "ZeD_StepAside.lua" }) do
        local s = readFile(CL .. rel)
        if s:find("WaterMarkUI", 1, true) or s:find("ISVersionWaterMark", 1, true) or s:find("getBulletVersion", 1, true) then
            touched[#touched + 1] = rel
        end
    end
    check("VERSION: no ZeD window draws, moves or hides the game's version line", #touched == 0, table.concat(touched, ","))
end

print(string.format("fix_windows_inventory_sim: %d checks, %d failed", checks, failed))
os.exit(failed > 0 and 1 or 0)
