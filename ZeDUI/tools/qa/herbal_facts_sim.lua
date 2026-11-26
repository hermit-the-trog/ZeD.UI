-- ZeDUI/tools/qa/herbal_facts_sim.lua  (Nov 25 2026, Build; QA K3 and K17)
-- What the game lets the player know about food, and ZeD now follows:
--   NAME      ZeD.herbalName mirrors ISInventoryPane.lua:2107-2127: with Herbalist a berry is "Poisonous Berry" or
--             "Berry" (mushrooms the same), without it "Unknown Berry" / "Unknown Mushroom"; setName writes it on the
--             item; what it returns is getName(player) after; anything else keeps its name and is never renamed
--   POISON    the item card's Nutrition Facts has no poison row (the game's food tooltip shows none), with or without
--             Herbalist; the old card's Poison stat is gone too
--   NUTRITION Calories, Proteins, Fat, Carbs only for a Nutritionist (either trait) or a packaged food the player can
--             read; packaged but illiterate or too dark: the game's one Nutrition line with the reason
--   CALLERS   the list, the item card and the trade window call the shared helper
-- Run from the repo root:  lua51 ZeDUI/tools/qa/herbal_facts_sim.lua
-- It prints FAIL lines and a last line "herbal_facts_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]herbal_facts_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CDIR = ROOT .. "42/media/lua/client/ZeD/"
local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then failed = failed + 1; print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")) end
end

function require() end
instanceof = function(o, cls) return type(o) == "table" and o._is ~= nil and o._is[cls] == true end
getText = function(k) return "T:" .. k end
CharacterTrait = { NUTRITIONIST = "nutritionist", NUTRITIONIST2 = "nutritionist2", ILLITERATE = "illiterate" }
ZeD = { T = {}, tr = function(k) return k end }

local PLAYER
getSpecificPlayer = function() return PLAYER end
local function player(t)
    t = t or {}
    return {
        isRecipeActuallyKnown = function(_, r) return r == "Herbalist" and t.herbalist == true end,
        hasTrait = function(_, tr) return t.traits ~= nil and t.traits[tr] == true end,
        tooDarkToRead = function() return t.dark == true end,
    }
end

-- a food: its name kept as the game keeps it (setName writes it, getName / getDisplayName read it)
local function food(t)
    local o = { _is = { Food = true }, _name = t.name, _sets = 0, _md = t.md or {} }
    o.IsFood = function() return t.food ~= false end
    o.getHerbalistType = function() return t.herbal end
    o.getPoisonPower = function() return t.poison or 0 end
    o.getDisplayName = function(self) return self._name end
    o.getName = function(self) return self._name end
    o.setName = function(self, n) self._name = n; self._sets = self._sets + 1 end
    o.isPackaged = function() return t.packaged == true end
    o.getModData = function(self) return self._md end
    o.getCalories = function() return 14 end
    o.getProteins = function() return 1 end
    o.getLipids = function() return 2 end
    o.getCarbohydrates = function() return 3 end
    o.getHungerChange = function() return -0.05 end
    o.getThirstChange = function() return 0 end
    o.getBoredomChange = function() return 0 end
    o.getUnhappyChange = function() return 0 end
    return o
end

assert(loadfile(CDIR .. "ZeD_HerbalName.lua"))()
assert(loadfile(CDIR .. "ItemFactsPanel.lua"))()
local FP = ZeD.ItemFactsPanel

-- NAME
local herb, plain = player({ herbalist = true }), player()
local b = food({ name = "Berries", herbal = "Berry", poison = 10 })
check("NAME a poisonous berry, Herbalist: Poisonous Berry", ZeD.herbalName(b, herb) == "T:IGUI_PoisonousBerry", b._name)
check("NAME setName wrote it on the item", b._sets == 1 and b:getDisplayName() == "T:IGUI_PoisonousBerry", b._sets)
ZeD.herbalName(b, herb)
check("NAME the same name again: no second setName", b._sets == 1, b._sets)
b = food({ name = "Berries", herbal = "Berry", poison = 0 })
check("NAME a safe berry, Herbalist: Berry", ZeD.herbalName(b, herb) == "T:IGUI_Berry" and b._sets == 1, b._name)
b = food({ name = "Berries", herbal = "Berry", poison = 10 })
check("NAME a poisonous berry, no Herbalist: Unknown Berry", ZeD.herbalName(b, plain) == "T:IGUI_UnknownBerry" and b._sets == 1, b._name)
b = food({ name = "Berries", herbal = "Berry", poison = 0 })
check("NAME a safe berry, no Herbalist: Unknown Berry (the same: nothing given away)", ZeD.herbalName(b, plain) == "T:IGUI_UnknownBerry", b._name)
local m = food({ name = "Mushrooms", herbal = "Mushroom", poison = 5 })
check("NAME a poisonous mushroom, Herbalist: Poisonous Mushroom", ZeD.herbalName(m, herb) == "T:IGUI_PoisonousMushroom", m._name)
m = food({ name = "Mushrooms", herbal = "Mushroom", poison = 0 })
check("NAME a safe mushroom, Herbalist: Mushroom", ZeD.herbalName(m, herb) == "T:IGUI_Mushroom", m._name)
m = food({ name = "Mushrooms", herbal = "Mushroom", poison = 5 })
check("NAME a mushroom, no Herbalist: Unknown Mushroom", ZeD.herbalName(m, plain) == "T:IGUI_UnknownMushroom", m._name)
b = food({ name = "Berries", herbal = "Berry", poison = 10 })
ZeD.herbalName(b, plain); ZeD.herbalName(b, herb)
check("NAME learning Herbalist later: the next listing names it again", b._name == "T:IGUI_PoisonousBerry" and b._sets == 2, b._name)
local apple = food({ name = "Apple", herbal = "" })
check("NAME an apple keeps its name, never renamed", ZeD.herbalName(apple, herb) == "Apple" and apple._sets == 0)
local tool = food({ name = "Hammer", food = false, herbal = "Berry" })
check("NAME not food: its name, never renamed", ZeD.herbalName(tool, herb) == "Hammer" and tool._sets == 0)
check("NAME nil item: nil, no error", ZeD.herbalName(nil, herb) == nil)
b = food({ name = "Berries", herbal = "Berry" })
check("NAME no player: its name, not renamed", ZeD.herbalName(b, nil) == "Berries" and b._sets == 0)

-- facts helpers
local function rows(panel)
    local out = {}
    for _, g in ipairs(panel and panel.groups or {}) do for _, r in ipairs(g.rows or {}) do out[#out + 1] = r end end
    return out
end
local function find(panel, label) for _, r in ipairs(rows(panel)) do if r.label == label then return r end end end
local function hasPoison(panel)
    for _, r in ipairs(rows(panel)) do
        local s = string.lower(tostring(r.label) .. " " .. tostring(r.value))
        if s:find("sickness", 1, true) or s:find("poison", 1, true) then return true end
    end
    return false
end

-- POISON
PLAYER = herb
local pb = food({ name = "Berries", herbal = "Berry", poison = 10 })
check("POISON no poison row on a poisonous berry, Herbalist", not hasPoison(FP.NutritionFacts(pb, 0)))
PLAYER = plain
check("POISON no poison row on a poisonous berry, no Herbalist", not hasPoison(FP.NutritionFacts(pb, 0)))
local fh = io.open(CDIR .. "ItemCard.lua", "rb"); local ic = fh and fh:read("*a") or ""; if fh then fh:close() end
check("POISON the old card's food stats read no poison power", not ic:find("getPoisonPower", 1, true))
fh = io.open(CDIR .. "ItemFactsPanel.lua", "rb"); local fp = fh and fh:read("*a") or ""; if fh then fh:close() end
check("POISON the facts panel reads no poison power", not fp:find("getPoisonPower", 1, true))

-- NUTRITION
local CAL = "T:Tooltip_food_Calories"
PLAYER = plain
local loose = food({ name = "Berries", herbal = "Berry" })
local p = FP.NutritionFacts(loose, 0)
check("NUTRITION hidden without the trait (Calories, Proteins, Fat, Carbs)", p and not find(p, CAL) and not find(p, "T:Tooltip_food_Prots")
      and not find(p, "T:Tooltip_food_Fat") and not find(p, "T:Tooltip_food_Carbs") and not find(p, "T:Tooltip_food_Nutrition"))
check("NUTRITION the panel still shows hunger without the trait", p and find(p, "UI_ZeD_Card_HungerReduction") ~= nil)
PLAYER = player({ traits = { nutritionist = true } })
p = FP.NutritionFacts(loose, 0)
check("NUTRITION shown for a Nutritionist", find(p, CAL) and find(p, CAL).value == "14" and find(p, "T:Tooltip_food_Carbs") ~= nil)
PLAYER = player({ traits = { nutritionist2 = true } })
check("NUTRITION shown for a Nutritionist (the profession's trait)", find(FP.NutritionFacts(loose, 0), CAL) ~= nil)
PLAYER = plain
local can = food({ name = "Canned Beans", packaged = true })
check("NUTRITION shown on packaged food without the trait", find(FP.NutritionFacts(can, 0), CAL) ~= nil)
PLAYER = player({ traits = { illiterate = true } })
p = FP.NutritionFacts(can, 0)
check("NUTRITION packaged, illiterate: no numbers, the game's Nutrition line says why",
      not find(p, CAL) and find(p, "T:Tooltip_food_Nutrition") and find(p, "T:Tooltip_food_Nutrition").value == "T:ContextMenu_Illiterate")
PLAYER = player({ dark = true })
p = FP.NutritionFacts(can, 0)
check("NUTRITION packaged, too dark to read: the Nutrition line says so",
      not find(p, CAL) and find(p, "T:Tooltip_food_Nutrition") and find(p, "T:Tooltip_food_Nutrition").value == "T:ContextMenu_TooDark")
PLAYER = player({ traits = { illiterate = true, nutritionist = true } })
check("NUTRITION a Nutritionist knows it without reading the label", find(FP.NutritionFacts(can, 0), CAL) ~= nil)
PLAYER = plain
check("NUTRITION packaged with no label (NoLabel): hidden", not find(FP.NutritionFacts(food({ name = "Jar", packaged = true, md = { NoLabel = true } }), 0), CAL))
local s1 = ZeD.seesNutrition(loose, plain); local s2 = ZeD.seesNutrition(nil, plain)
check("NUTRITION seesNutrition: false for loose food without the trait, nil item safe", s1 == false and s2 == false)
check("NUTRITION the old card's label asks the same rule", ic:find("ZeD.seesNutrition(item, getSpecificPlayer(playerNum or 0))", 1, true) ~= nil)

-- CALLERS
local function src(f) local h = io.open(CDIR .. f, "rb"); local t = h and h:read("*a") or ""; if h then h:close() end; return t end
local ir, co, tr = src("InventoryRenderer.lua"), src("ItemCardOrganism.lua"), src("ZeD_Trade.lua")
check("CALLERS the list renames as it builds its model", ir:find("pcall(ZeD.herbalName, item, playerObj)", 1, true) ~= nil)
check("CALLERS the item card renames before its title", co:find("ZeD.herbalName, item, getSpecificPlayer", 1, true) ~= nil
      and ic:find("ZeD.herbalName, item, getSpecificPlayer", 1, true) ~= nil)
check("CALLERS the trade window uses the shared helper, its own copy gone", tr:find("ZeD.herbalName(item, player)", 1, true) ~= nil
      and not tr:find("IGUI_UnknownBerry", 1, true))
for _, f in ipairs({ "InventoryRenderer.lua", "ItemCardOrganism.lua", "ItemCard.lua", "ItemFactsPanel.lua", "ZeD_Trade.lua" }) do
    check("CALLERS " .. f .. " requires the helper", src(f):find('require "ZeD/ZeD_HerbalName"', 1, true) ~= nil)
end

print("herbal_facts_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
