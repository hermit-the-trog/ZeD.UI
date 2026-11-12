-- ZeDUI/tools/qa/tab_review_fixes_sim.lua  (Nov 11 2026, Build): the tab review's faults (QA, 50 pictures at
-- 1920x1080, tab_review_20261111) fixed in CraftingCore.lua and CookingTab.lua, with no game running.
--   DESC     a recipe card's description is one line: the Advanced Forge's text, broken in two at its <br>, drew its
--            second line over the first Required row (item 1). CC.oneLine on the game's text with a line break, a
--            <br> left in, tabs and runs of space; the card's draw goes through it.
--   EMPTY    an empty recipe list says why under its "(0)" head, as the other empty lists do (item 9): the real
--            CC.renderRecipeList on a stub panel, with no recipes under Show: Ready, under All, and for a search;
--            none with rows, none with the group folded. The search box stays (it is the way back).
--   COOK     the Cooking tab opens on a dish something in reach goes into (item 7): the real CookingTab.lua on a stub
--            world holding an empty metal cup (Beverage, nothing for it) and a pot of water with vegetables (Soup,
--            Stew). The old choice, the first by name, was Beverage: "Nothing in reach goes into this dish".
-- Run from the repo root:  lua51 ZeDUI/tools/qa/tab_review_fixes_sim.lua
-- It prints FAIL lines and a last line "tab_review_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]tab_review_fixes_sim%.lua$", "")

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
local function list(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end }
end
local function readFile(rel)
    local f = io.open(ROOT .. rel, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return (string.gsub(s, "\r\n", "\n"))
end

require = function() return nil end
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = noop, Remove = noop }
    rawset(t, k, e)
    return e
end })
getTimestampMs = function() return 100000 end

local TR = {
    UI_ZeD_TAS_Nothing = "Nothing matches \"%1\".",
    UI_ZeD_Craft_EmptyReady = "Nothing is ready to make with what is in reach.",
    UI_ZeD_Craft_EmptyNone = "No recipes to list.",
}
local T = {
    scale = 1, hover = { r = 1, g = 1, b = 1, a = 0.1 }, accent = {}, warning = {},
    sp = { catHdrH = 15, scrollbarW = 10 },
    px = function(n) return n end,
}
ZeD = {
    T = T,
    tr = function(k, a) local s = TR[k] or k; if a ~= nil then s = string.gsub(s, "%%1", tostring(a)) end; return s end,
    textCase = function(s) return s end,
}

-- ---------------------------------------------------------------------------
-- DESC and EMPTY: the real pieces of CraftingCore.lua
-- ---------------------------------------------------------------------------
local DRAWN = {}
M = {
    drawCategoryRow = function(_, x, y, w, text, count) DRAWN[#DRAWN + 1] = { kind = "head", text = text, count = count, y = y } end,
    drawRecipeRow = function(_, x, y, w, row) DRAWN[#DRAWN + 1] = { kind = "row", text = row.displayName, y = y } end,
    drawEmptyLine = function(_, x, y, w, text) DRAWN[#DRAWN + 1] = { kind = "empty", text = text, y = y }; return 14 end,
}
NO_FOCUS_OPTS = {}
local CC = { ROW_H = 24, getTopFrequent = function() return {} end }
ZeD.CraftingCore = CC
local cut = dofile(ROOT .. "ZeDUI/tools/qa/cc_cut.lua")
local okCut, errCut = pcall(cut, ROOT, CC, { "local function cuesOn(", "local function anyOpen(", "function CC.oneLine(",
    "function CC.showMode(", "function CC.emptyListText(", "function CC.renderRecipeList(" })
check("the CraftingCore pieces cut and load", okCut, errCut)

section("DESC: one line")
if okCut then
    local forge = { description = "For the most advanced metal forging, including\nmetal armors, blades, and tool heads." }
    check("a line break becomes a space", CC.oneLine(forge) == "For the most advanced metal forging, including metal armors, blades, and tool heads.",
        CC.oneLine(forge))
    check("kept on the entry (made once)", forge._descLine == CC.oneLine(forge))
    local e2 = { description = "  A <br>B\r\n\tC   D  " }
    check("<br>, CR LF, tab and runs of space: one space each, no ends", CC.oneLine(e2) == "A B C D", CC.oneLine(e2))
    local e3 = { description = "Plain words." }
    check("a plain line is left as it is", CC.oneLine(e3) == "Plain words.")
    check("no line break is left in any", not string.find(CC.oneLine(e2), "[\r\n]"))
end
do
    local src = readFile("42/media/lua/client/ZeD/CraftingCore.lua") or ""
    local a = string.find(src, "function CC.renderCraftCard(", 1, true)
    local b = a and string.find(src, "\nend\n", a, true)
    local body = a and b and string.sub(src, a, b) or ""
    check("the recipe card draws its description through CC.oneLine",
        string.find(body, "CC.truncText(CC.oneLine(entry)", 1, true) ~= nil)
    check("the card no longer draws the raw description",
        string.find(body, "CC.truncText(entry.description", 1, true) == nil)
end

section("EMPTY: the recipe list's empty line")
local function panel()
    return { setStencilRect = noop, clearStencilRect = noop, getMouseX = function() return -1 end,
             getMouseY = function() return -1 end }
end
local function scroll()
    return { scrollPos = 0, setScrollPos = noop, setBarSize = noop, draw = noop }
end
local function listOf(state, config)
    DRAWN = {}
    state.zones, state.scroll, state._sectionsStale = {}, scroll(), true
    state.pins = state.pins or {}
    CC.renderRecipeList(panel(), 0, 0, 240, 600, state, config, { flatRecipes = {} }, {})
    local out = { heads = {}, rows = 0, empty = nil }
    for _, d in ipairs(DRAWN) do
        if d.kind == "head" then out.heads[#out.heads + 1] = d
        elseif d.kind == "row" then out.rows = out.rows + 1
        elseif d.kind == "empty" then out.empty = d end
    end
    return out
end
if okCut then
    local cfg = { prefix = "build", countKey = "k" }
    local r = listOf({ filteredCache = {}, search = "" }, cfg)
    check("Show: Ready, nothing ready: the line says so", r.empty and r.empty.text == TR.UI_ZeD_Craft_EmptyReady,
        r.empty and r.empty.text)
    check("... under the All Recipes (0) head", r.heads[1] and r.heads[1].text == "UI_ZeD_Craft_AllRecipes"
        and r.heads[1].count == 0 and r.empty and r.empty.y > r.heads[1].y)
    r = listOf({ filteredCache = {}, search = "", show = "all" }, cfg)
    check("Show: All, nothing: no recipes to list", r.empty and r.empty.text == TR.UI_ZeD_Craft_EmptyNone, r.empty and r.empty.text)
    r = listOf({ filteredCache = {}, search = "zzzzqq" }, cfg)
    check("a search that finds nothing names it", r.empty and r.empty.text == "Nothing matches \"zzzzqq\".", r.empty and r.empty.text)
    check("... under the Results (0) head", r.heads[1] and r.heads[1].text == "UI_ZeD_Craft_Results")
    r = listOf({ filteredCache = {}, search = "", show = "known" }, { prefix = "jrecipe", readOnly = true })
    check("the Journal's read-only list, nothing known: no recipes to list", r.empty and r.empty.text == TR.UI_ZeD_Craft_EmptyNone)
    r = listOf({ filteredCache = {}, search = "", allCollapsed = true }, cfg)
    check("the group folded: no line", r.empty == nil)
    local rd = { entry = { name = "Forge", displayName = "Advanced Forge" }, status = "unlocked" }
    r = listOf({ filteredCache = { rd }, search = "" }, cfg)
    check("a list with a row: no line", r.empty == nil and r.rows == 1, r.rows)
    -- TEETH: the line hangs on the list being empty, not on the head's count alone
    r = listOf({ filteredCache = { rd }, search = "zz" }, cfg)
    check("TEETH: a search with a hit draws its row, no line", r.empty == nil and r.rows == 1)
end

-- ---------------------------------------------------------------------------
-- COOK: the real CookingTab.lua on a stub world
-- ---------------------------------------------------------------------------
section("COOK: the dish the tab opens on")
local function Item(ft, name, cont)
    return { _ft = ft, _name = name, _cont = cont,
             getFullType = function(self) return self._ft end, getDisplayName = function(self) return self._name end,
             getContainer = function(self) return self._cont end }
end
local INV = { getType = function() return "none" end, getContainingItem = function() return nil end }
local ITEMS = {}
INV.getItems = function() return list(ITEMS) end
local CHR = { getPlayerNum = function() return 0 end, getInventory = function() return INV end,
              getPerkLevel = function() return 3 end }
local CUP = Item("Base.MetalCup", "Empty Metal Cup", INV)
local POT = Item("Base.Pot", "Water (Pot)", INV)
local VEG = { Item("Base.Potato", "Potato", INV), Item("Base.Carrots", "Carrots", INV), Item("Base.Onion", "Onion", INV) }
ITEMS = { CUP, POT, VEG[1], VEG[2], VEG[3] }
local function Recipe(un, label, base, result, takes)
    return { _un = un, _label = label, _base = base, _result = result, _takes = takes,
             getUntranslatedName = function(self) return self._un end, getName = function(self) return self._label end,
             isHidden = function() return false end, getBaseItem = function(self) return self._base end,
             getFullResultItem = function(self) return self._result end, getMinimumWater = function() return 0 end,
             hasMinimumWater = function() return true end, getMaxItems = function() return 6 end,
             getItemsCanBeUse = function(self, chr, base, conts)
                 local out = {}
                 for _, it in ipairs(ITEMS) do if self._takes[it._ft] then out[#out + 1] = it end end
                 return list(out)
             end }
end
-- the Beverage takes only the cup itself (the game may hand the base back): no ingredient for it
local RECIPES = {
    Recipe("Beverage", "Beverage", "Base.MetalCup", "Base.MetalCupBeverage", { ["Base.MetalCup"] = true }),
    Recipe("Soup", "Soup", "Base.Pot", "Base.PotOfSoupRecipe", { ["Base.Potato"] = true, ["Base.Carrots"] = true }),
    Recipe("Stew", "Stew", "Base.Pot", "Base.PotOfStew", { ["Base.Onion"] = true }),
}
getEvolvedRecipes = function() return list(RECIPES) end
getTextOrNull = function() return nil end
getText = function(k) return k end
getPlayerInventory = function() return {} end
getPlayerLoot = function() return {} end
ISInventoryPaneContextMenu = { getContainers = function() return list({ INV }) end }
local function derive() local c = {}; c.__index = c; c.derive = derive; return c end
ISBaseTimedAction = { derive = function() return derive() end }
ISAddItemInRecipe = { derive = function() return derive() end }
ZeD_CharacterWindow = { addTab = noop }
instanceof = function() return false end
Perks = { Cooking = "Cooking" }

local okCK, errCK = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/CookingTab.lua")
check("CookingTab.lua loads on the stubs", okCK, errCK)
local CK = ZeD.CookingTab
if okCK and CK then
    check("CK.firstDish is there", type(CK.firstDish) == "function")
    local win = { _playerObj = CHR }
    check("the tab shows (the pot of water takes the vegetables)", CK.visible(win) == true)
    local s = win._cook
    check("three dishes in reach, by name", s and s.dishList and #s.dishList == 3 and s.dishList[1] == "Beverage",
        s and s.dishList and table.concat(s.dishList, ","))
    local pick = CK.firstDish(s, CHR)
    check("it opens on Soup, the first dish something in reach goes into", pick == "Soup", pick)
    check("TEETH: the old choice, the first by name, was the Beverage", s.dishList[1] == "Beverage" and pick ~= s.dishList[1])
    -- the pot gone: nothing goes into anything, the first there is
    ITEMS = { CUP }
    CK.visible(win)   -- (within the scan's second: the old list)
    s.scanAt, s.visAt = -1, nil   -- (the scan and the visible check both due again)
    CK.visible({ _playerObj = CHR, _cook = s })
    local p2 = CK.firstDish(s, CHR)
    check("nothing goes into any dish: the first there is", p2 == "Beverage", p2)
    -- a base that is not on the player does not choose the dish
    ITEMS = { CUP, POT, VEG[1] }
    local FLOOR = { getType = function() return "floor" end, getContainingItem = function() return nil end }
    POT._cont = FLOOR
    s.scanAt, s.visAt = -1, nil   -- (the scan and the visible check both due again)
    CK.visible({ _playerObj = CHR, _cook = s })
    local p3 = CK.firstDish(s, CHR)
    check("a pot on the floor (not on the player) does not choose it", p3 == "Beverage", p3)
    POT._cont = INV
    local src = readFile("42/media/lua/client/ZeD/CookingTab.lua") or ""
    check("the render picks the dish through CK.firstDish",
        string.find(src, "s.dish, s.baseIdx, s.plan, s.qty = CK.firstDish(s, chr), 1, {}, 1", 1, true) ~= nil)
end

print("tab_review_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
