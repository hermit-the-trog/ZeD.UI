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
--   CARD     (Nov 12 2026, design review Q5) the craft card is the list's picked row: Show never hides the open
--            card's recipe, a category or search that leaves it out closes the card, a recipe opened from outside
--            (an item card's Makes row, the game's craft entries) clears the category and an old search
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

-- (Nov 12 2026, design review Q5) The Crafting card showed "Add Cigarette to Pack" beside a list of six rows
-- (Station Hand, Show: Ready) that did not hold it: the card reads its recipe from all the data, the list from the
-- filtered rows, and nothing kept them together. An item card's Makes row (RecipeIndex.open, through the game's
-- OpenHandcraftWindow) opened a recipe that was not ready under Show: Ready; a search or a category picked later
-- left the open card's recipe out of the list too. Now the card is the list's picked row: Show never hides the open
-- card's recipe, a list that leaves it out closes the card, and a recipe opened from outside clears the category
-- and an old search so its row shows.
section("CARD: the card is the list's picked row")
do
    local function rd(name, cat, status)
        return { entry = { name = name, displayName = name, category = cat, inputDefs = {}, outputDefs = {} },
                 learned = true, hasSkill = true, status = status }
    end
    local function scroll() return { setScrollPos = function() end } end
    -- the list alone: Show never hides the open card's recipe
    local C1 = { }
    local okF, errF = pcall(cut, ROOT, C1, { "function CC.showMode(", "function CC.filterAndSort(" })
    check("filterAndSort cuts and loads", okF, errF)
    if okF then
        local data = { recipes = { rd("Base.AddCigaretteToPack", "Miscellaneous", "missing"), rd("Base.OpenCan", "Cooking", "craftable") } }
        local st = { show = "ready", activeCat = "all", search = "", pins = {}, selected = "Base.AddCigaretteToPack" }
        local rows = C1.filterAndSort(data, st, nil)
        local seen = false
        for _, r in ipairs(rows) do if r.entry.name == "Base.AddCigaretteToPack" then seen = true end end
        check("under Show: Ready the open card's recipe (not ready) still has its row", seen and #rows == 2, #rows)
        st.selected = nil
        check("with no card open it does not", #C1.filterAndSort(data, st, nil) == 1)
    end
    local C2 = { }
    local okC, errC = pcall(cut, ROOT, C2, { "function CC.showMode(", "function CC.filterAndSort(", "function CC.openCraft(",
        "function CC.closeCraft(", "function CC.refilter(" })
    check("filterAndSort, openCraft, closeCraft and refilter cut and load", okC, errC)
    if okC then
        local data = { recipes = { rd("Base.AddCigaretteToPack", "Miscellaneous", "missing"), rd("Base.OpenCan", "Cooking", "craftable"),
                                   rd("Base.RipSheets", "Miscellaneous", "craftable") } }
        local state = { show = "ready", activeCat = "all", search = "", pins = {}, cardScroll = scroll(), picks = {} }
        local function listed(name)
            for _, r in ipairs(state.filteredCache or {}) do if r.entry.name == name then return true end end
            return false
        end
        C2.refilter(data, state, nil)
        check("Show: Ready holds back a recipe that is not ready", not listed("Base.AddCigaretteToPack") and listed("Base.OpenCan"))
        -- opened from an item's card while it is not ready: its row shows, the card stays
        C2.openCraft(state, "Base.AddCigaretteToPack")
        C2.refilter(data, state, nil)
        check("the open card's recipe keeps its row under Show: Ready", listed("Base.AddCigaretteToPack"))
        check("and its card stays open", state.selected == "Base.AddCigaretteToPack")
        -- a category that leaves it out closes the card
        state.activeCat = "cooking"
        C2.refilter(data, state, nil)
        check("a category that leaves the open recipe out closes its card", state.selected == nil and state.splitTarget == 0,
            tostring(state.selected))
        check("closing the card filters the list again", state.filterDirty == true)
        -- a search that leaves it out closes the card too
        state.activeCat, state.search = "all", ""
        C2.openCraft(state, "Base.RipSheets")
        state.search = "can"
        C2.refilter(data, state, nil)
        check("a search that leaves the open recipe out closes its card", state.selected == nil)
        -- a recipe that is no longer ready after a craft keeps its card
        state.search = ""
        C2.openCraft(state, "Base.RipSheets")
        data.recipes[3].status = "missing"
        C2.refilter(data, state, nil)
        check("a craft that used the last ingredients keeps the card and its row", state.selected == "Base.RipSheets" and listed("Base.RipSheets"))
        -- the card closed, the row Show held back for it goes
        C2.closeCraft(state)
        C2.refilter(data, state, nil)
        check("the card closed: the row Show held back for it goes", not listed("Base.RipSheets"))
    end
    -- the way in from outside: the category and an old search step aside
    local src = readFile("42/media/lua/client/ZeD/Overrides/Stations.lua") or ""
    local a = src:find("local function focusRecipe(", 1, true)
    local e = a and src:find("\nend\n", a, true)
    check("focusRecipe found", a ~= nil and e ~= nil)
    if a and e then
        local W = { _craftState = { activeCat = "cooking", search = "old", filterDirty = false } }
        local field = { input = { text = "old", setText = function(self, t) self.text = t end } }
        W._craftSearch = field
        local opened = nil
        local saveZ, saveW = ZeD.CraftingCore, ZeD_WorldWindow
        ZeD.CraftingCore = { openCraft = function(st, name) st.selected = name; opened = name end }
        ZeD_WorldWindow = { getWindow = function() return W end }
        local chunk, err = loadstring(src:sub(a, e + 4) .. "return focusRecipe\n", "=Overrides/Stations.lua (cut)")
        check("it loads", chunk ~= nil, err)
        if chunk then
            local focusRecipe = chunk()
            focusRecipe("_craftState", "_craftSearch", { getName = function() return "Base.AddCigaretteToPack" end }, nil)
            local st = W._craftState
            check("a recipe opened from outside: the card opens on it", opened == "Base.AddCigaretteToPack")
            check("the category steps aside (All)", st.activeCat == "all", st.activeCat)
            check("an old search is cleared, field and list", st.search == "" and field.input.text == "", st.search)
        end
        ZeD.CraftingCore, ZeD_WorldWindow = saveZ, saveW
    end
end

print("tab_review_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
