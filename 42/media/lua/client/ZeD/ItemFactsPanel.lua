-- ZeD-UI/42/media/lua/client/ZeD/ItemFactsPanel.lua
-- ============================================================================
-- ITEM FACTS PANEL REGISTRY - client; data only, no drawing.
-- Five item-type Facts panels - each a factory taking (item) and returning
-- a structured panel description, or nil if the item is not its target
-- type. The ItemCard organism gets an item's facts through factsFor(item)
-- instead of branching on item class itself.
--
-- Factory return shape:
--   nil  → this panel doesn't apply to the item
--   {
--     title         = "Nutrition Facts",
--     hasDisclosure = bool, -- 220w only: clothing collapses behind a chevron
--                           -- because zones compete for vertical space; other
--                           -- panels stay always-expanded
--     groups        = { -- separated by thin rules in render
--       { rows = { {label, value, valueClass, isSub, needsProbe, short?}, ... } },
--       (label and short are already translated; short is the 220w label)
--       ...
--     }
--   }
--
-- needsProbe = true → the facts row appends a small "*" badge after the
-- label in the warning color: the value comes from a Java getter not yet
-- confirmed in-game. The flag comes off as each getter is confirmed.
-- ============================================================================

require "ZeD/Tr"
ZeD = ZeD or {}
ZeD.ItemFactsPanel = ZeD.ItemFactsPanel or {}

local M = ZeD.ItemFactsPanel
local safeGet = ZeD.Atoms and ZeD.Atoms.safeGet or function(item, m, ...)
    if not item then return nil end
    local fn = item[m]; if not fn then return nil end
    local ok, r = pcall(fn, item, ...); if ok then return r end; return nil
end

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

-- Format a percentage-like int with sign, e.g. "5%" / "-2%" / "+15%"
local function _pct(n, withSign)
    if not n then return nil end
    n = math.floor(n + 0.5)
    if withSign and n > 0 then return "+" .. tostring(n) .. "%" end
    return tostring(n) .. "%"
end

-- A 0..1 value as whole hundredths, rounded: these are floats, and 0.35 reads back as 0.34999...
local function _hundredths(n)
    return math.floor(n * 100 + 0.5)
end

-- Color class from a 0..1 ratio: dim at 0 or nil, bad under 0.3, warn under
-- 0.6, plain up to 0.85, good from there on.
local function _condClass(ratio)
    if not ratio or ratio <= 0 then return "dim" end
    if ratio < 0.3  then return "bad"  end
    if ratio < 0.6  then return "warn" end
    if ratio < 0.85 then return nil    end  -- normal
    return "good"
end

-- ---------------------------------------------------------------------------
-- DefenseFacts - clothing
-- ---------------------------------------------------------------------------
function M.DefenseFacts(item)
    if not item then return nil end
    local isClothing = safeGet(item, "IsClothing")
    if not isClothing and not (instanceof and instanceof(item, "Clothing")) then
        return nil
    end

    -- Defense values (the item's flat figures - any per-zone view is the
    -- organism's business; the factory shows the item-level defense).
    -- Read from the clothing itself: of these
    -- the script item has only insulation and getConditionLowerChance. Same
    -- scales as the game's tooltip: defense 0..100, the thermal three 0..1.
    local biteDef    = safeGet(item, "getBiteDefense")
    local scratchDef = safeGet(item, "getScratchDefense")
    local bulletDef  = safeGet(item, "getBulletDefense")
    local insulation = safeGet(item, "getInsulation")
    local windRes    = safeGet(item, "getWindresistance")
    local waterRes   = safeGet(item, "getWaterResistance")
    -- A multiplier on defense at the neck, and the game ignores it at 1 (every
    -- item that sets none): only a value under 1 says anything.
    local neckProt   = safeGet(item, "getNeckProtectionModifier")
    if neckProt and neckProt >= 1 then neckProt = nil end
    -- The game rolls this 1-in-N only for clothing that cannot get holes; the
    -- rest lose condition per hole, whatever the script says. An explicit
    -- false: a build without the call shows "-", never a wrong figure.
    local condLoss   = nil
    if safeGet(item, "getCanHaveHoles") == false then
        condLoss = safeGet(item, "getConditionLowerChance")
    end

    local panel = {
        title         = ZeD.tr("UI_ZeD_Card_FactsDefense"),
        hasDisclosure = true,  -- 220w: zones compete, defense behind chevron
        groups        = {},
    }

    -- Group 1: bite/scratch/bullet. No status mark on these rows - protection
    -- is good news and the number says it; a zero only dims.
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = getText("Tooltip_BiteDefense"),    short = ZeD.tr("IGUI_health_Bite"),
             value = biteDef    and _pct(biteDef)    or "0%",
             valueClass = not ((biteDef    or 0) > 0) and "dim" or nil},
            {label = getText("Tooltip_ScratchDefense"), short = ZeD.tr("IGUI_health_Scratch"),
             value = scratchDef and _pct(scratchDef) or "0%",
             valueClass = not ((scratchDef or 0) > 0) and "dim" or nil},
            {label = getText("Tooltip_BulletDefense"),  short = ZeD.tr("IGUI_health_Bullet"),
             value = bulletDef  and _pct(bulletDef)  or "0%",
             valueClass = not ((bulletDef  or 0) > 0) and "dim" or nil},
        },
    }

    -- Group 2: thermal + water + neck
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = getText("Tooltip_item_Insulation"), value = insulation and string.format("%d / 100", _hundredths(insulation)) or "-",
             valueClass = (not insulation) and "dim" or nil, needsProbe = insulation == nil},
            {label = getText("IGUI_Temp_WindResistance"), short = ZeD.tr("UI_ZeD_Card_ShortWind"),
             value = windRes and string.format("%d / 100", _hundredths(windRes)) or "-",
             valueClass = (not windRes) and "dim" or nil, needsProbe = windRes == nil},
            {label = getText("Tooltip_item_Waterresist"), short = ZeD.tr("UI_ZeD_Card_ShortWaterRes"),
             value = waterRes and string.format("%d / 100", _hundredths(waterRes)) or "-",
             valueClass = "dim"},
            {label = ZeD.tr("UI_ZeD_Card_NeckProt"), short = ZeD.tr("UI_ZeD_Card_ShortNeckProt"),
             value = neckProt and string.format("%d%%", _hundredths(neckProt)) or "-",
             valueClass = "dim"},
        },
    }

    -- Group 3: condition decay
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = ZeD.tr("UI_ZeD_Card_CondLossHit"), short = ZeD.tr("UI_ZeD_Card_ShortCondHit"),
             value = condLoss and "1 / " .. tostring(condLoss) or "-"},
            {label = ZeD.tr("UI_ZeD_Card_OneInN"), short = ZeD.tr("UI_ZeD_Card_ShortOneInN"),
             value = condLoss and tostring(condLoss) or "-", isSub = true},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- NutritionFacts - food
-- ---------------------------------------------------------------------------
function M.NutritionFacts(item)
    if not item then return nil end
    if not (instanceof and instanceof(item, "Food")) then return nil end

    local hunger   = safeGet(item, "getHungerChange")
    local thirst   = safeGet(item, "getThirstChange")
    local cal      = safeGet(item, "getCalories")
    local protein  = safeGet(item, "getProteins")
    local fat      = safeGet(item, "getLipids")
    local carbs    = safeGet(item, "getCarbohydrates")
    local sickness = safeGet(item, "getPoisonPower")  -- 0 if not poisoned/raw
    local boredom  = safeGet(item, "getBoredomChange")
    local happy    = safeGet(item, "getUnhappyChange")

    local panel = {
        title         = ZeD.tr("UI_ZeD_Card_FactsNutrition"),
        hasDisclosure = false,
        groups        = {},
    }

    -- Group 1: hunger + thirst (the two primary needs the food addresses)
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = ZeD.tr("UI_ZeD_Card_HungerReduction"), value = hunger and string.format("%+d", -math.floor(hunger * 100 + 0.5)) or "-"},
            {label = ZeD.tr("UI_ZeD_Card_ThirstReduction"), value = thirst and string.format("%+d", -math.floor(thirst * 100 + 0.5)) or "-"},
        },
    }

    -- Group 2: macro nutrients
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = getText("Tooltip_food_Calories"), value = cal     and tostring(math.floor(cal     + 0.5))             or "-"},
            {label = getText("Tooltip_food_Prots"),    value = protein and string.format("%d g", math.floor(protein + 0.5)) or "-"},
            {label = getText("Tooltip_food_Fat"),      value = fat     and string.format("%d g", math.floor(fat     + 0.5)) or "-"},
            {label = getText("Tooltip_food_Carbs"),    value = carbs   and string.format("%d g", math.floor(carbs   + 0.5)) or "-"},
        },
    }

    -- Group 3: secondary effects
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = ZeD.tr("UI_ZeD_Card_SicknessRisk"), value = (sickness and sickness > 0) and string.format("+%d%%", sickness) or "0%",
             valueClass = (sickness and sickness > 0) and "bad" or "dim"},
            {label = getText("Tooltip_food_Boredom"),    value = boredom and string.format("%+d", math.floor(boredom + 0.5)) or "-",
             valueClass = (boredom or 0) > 0 and "warn" or nil},
            {label = ZeD.tr("UI_ZeD_Card_Happiness"),    value = happy   and string.format("%+d", math.floor(-happy  + 0.5)) or "-"},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- CombatFacts - weapons
-- ---------------------------------------------------------------------------
function M.CombatFacts(item)
    if not item then return nil end
    if not (instanceof and instanceof(item, "HandWeapon")) then return nil end

    local dmgMin    = safeGet(item, "getMinDamage")
    local dmgMax    = safeGet(item, "getMaxDamage")
    local rangeMin  = safeGet(item, "getMinRange")
    local rangeMax  = safeGet(item, "getMaxRange")
    local swingTime = safeGet(item, "getSwingTime")
    local knockback = safeGet(item, "getPushBackMod")
    local cond      = safeGet(item, "getCondition")
    local condMax   = safeGet(item, "getConditionMax")
    local critChance= safeGet(item, "getCriticalChance")
    -- the ammo's own name ("9mm Rounds"); getAmmoType is an AmmoType object, which tostring
    -- would print as its registry id ("base:bullets_9mm")
    local ammoType
    if ZeD.Atoms and ZeD.Atoms.ammoOf then
        local _, an = ZeD.Atoms.ammoOf(item)
        ammoType = an
    else
        ammoType = safeGet(item, "getAmmoType")
    end

    local panel = {
        title         = ZeD.tr("UI_ZeD_Card_FactsCombat"),
        hasDisclosure = false,
        groups        = {},
    }

    -- Group 1: damage + reach
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = getText("Tooltip_weapon_Damage"), value = (dmgMin and dmgMax) and string.format("%.1f - %.1f", dmgMin, dmgMax) or "-"},
            {label = getText("Tooltip_weapon_Range"),  value = (rangeMin and rangeMax) and string.format("%.1f - %.1f m", rangeMin, rangeMax) or "-"},
            {label = ZeD.tr("UI_ZeD_Card_Swing"),      value = swingTime and string.format("%.2f s", swingTime) or "-"},
        },
    }

    -- Group 2: handling + crit
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = ZeD.tr("UI_ZeD_Card_Knockback"),  value = knockback   and string.format("%.2f", knockback)   or "-"},
            {label = ZeD.tr("UI_ZeD_Card_CritPct"),    value = critChance  and string.format("%d%%", critChance)  or "-"},
        },
    }

    -- Group 3: durability + ammo
    local ratio  = (cond and condMax and condMax > 0) and (cond / condMax) or nil
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = getText("Tooltip_weapon_Condition"), value = (cond and condMax) and string.format("%d / %d", cond, condMax) or "-",
             valueClass = _condClass(ratio)},
            {label = getText("Tooltip_weapon_Ammo"),      value = (ammoType and ammoType ~= "") and tostring(ammoType) or "-",
             valueClass = (not ammoType or ammoType == "") and "dim" or nil},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- ContainerFacts - bags / boxes / cooking pots. The capacity is the card's
-- character's (playerNum): getEffectiveCapacity, so Organized holds more and
-- Disorganized less, as the game checks a transfer and shows it in its own
-- tooltip and inventory (the bare getCapacity ignores both traits).
-- ---------------------------------------------------------------------------
function M.ContainerFacts(item, playerNum)
    if not item then return nil end
    local inv = safeGet(item, "getInventory")
    if not inv then return nil end

    local chr     = getSpecificPlayer and getSpecificPlayer(playerNum or 0) or nil
    local cap     = safeGet(inv, "getEffectiveCapacity", chr) or safeGet(inv, "getCapacity") or safeGet(item, "getCapacity")
    local current = safeGet(inv, "getContentsWeight")
    local nItems  = safeGet(inv, "getItems")
    local count   = nItems and safeGet(nItems, "size") or nil
    local reduce  = safeGet(item, "getWeightReduction")

    local fillRatio = (cap and cap > 0 and current) and (current / cap) or nil

    local panel = {
        title         = ZeD.tr("UI_ZeD_Card_FactsContainer"),
        hasDisclosure = false,
        groups        = {},
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = ZeD.tr("Tooltip_container_Capacity"), value = (current and cap) and string.format("%.1f / %d kg", current, cap) or "-",
             valueClass = _condClass(fillRatio and (1 - fillRatio) or nil)},
            {label = ZeD.tr("UI_ZeD_Card_Items"), value = count and tostring(count) or "-"},
        },
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = ZeD.tr("UI_ZeD_Card_WeightReduction"), value = reduce and string.format("%d%%", reduce) or "-",
             valueClass = (reduce and reduce > 0) and "good" or "dim"},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- LiquidFacts - a liquid container: what is in it, exactly (punch list 152; the director, Nov 11 2026: hovering
-- shows the level, "It's not until you inspect it ... where you see how much is in it"). Each liquid and how much of
-- it, largest first; the game's "Tainted" on it where the game's tooltip shows that; the total in the container's
-- capacity; "Empty" or "Unknown" (the game's words) where so. The water card's rules (ObjectCardFluid.lua,
-- ZeD.Fluid). First in the list, so a saucepan of water shows its water, then its combat facts below.
-- ---------------------------------------------------------------------------
function M.LiquidFacts(item)
    if not item then return nil end
    local fc = ZeD.ItemMeter and ZeD.ItemMeter.fluidOf(item) or safeGet(item, "getFluidContainer")
    if not fc then return nil end
    local cap = safeGet(fc, "getCapacity") or 0
    if cap <= 0 then return nil end
    local FL = ZeD.Fluid
    local function word(k, fb) local t = getTextOrNull and getTextOrNull(k); return t or fb end
    local L = (FL and FL.L) or function(v) return string.format("%.2f L", v or 0) end
    local hidden = safeGet(fc, "isHiddenAmount")
    local liquids = {}
    if FL and FL.liquidsOf then
        local ok, v = pcall(FL.liquidsOf, fc)
        if ok and type(v) == "table" then liquids = v end
    end
    local tainted = false
    if FL and FL.taintedShown then
        local ok, v = pcall(FL.taintedShown, fc, liquids)
        tainted = ok and v == true
    end
    local panel = { title = ZeD.tr("UI_ZeD_Card_FactsLiquid"), hasDisclosure = false, groups = {} }
    local rows = {}
    if safeGet(fc, "isEmpty") then
        rows[#rows + 1] = { label = word("Fluid_Empty", "Empty"), value = "-", valueClass = "dim" }
    elseif #liquids == 0 then
        local pf = safeGet(fc, "getPrimaryFluid")
        local nm = pf and (safeGet(pf, "getTranslatedName") or safeGet(pf, "getFluidTypeString")) or word("Fluid_Mixture", "Mixture")
        rows[#rows + 1] = { label = tostring(nm), value = hidden and word("Fluid_Unknown", "Unknown") or L(safeGet(fc, "getAmount") or 0),
                            valueClass = tainted and "bad" or nil }
    else
        for _, l in ipairs(liquids) do
            rows[#rows + 1] = { label = tostring(l.name), value = hidden and "?" or L(l.amt),
                                valueClass = (tainted and (l.tainted or l.poison)) and "bad" or nil }
        end
    end
    panel.groups[#panel.groups + 1] = { rows = rows }
    local total = { label = ZeD.tr("UI_ZeD_Card_Amount"),
                    value = hidden and word("Fluid_Unknown", "Unknown") or (L(safeGet(fc, "getAmount") or 0) .. " / " .. L(cap)) }
    local g2 = { rows = { total } }
    if tainted then g2.rows[#g2.rows + 1] = { label = word("Tooltip_tainted", "Tainted"), value = "", valueClass = "bad" } end
    panel.groups[#panel.groups + 1] = g2
    -- (a pot or a bottle swung is a weapon too: its combat facts follow)
    local combat = M.CombatFacts and M.CombatFacts(item)
    if combat then for _, g in ipairs(combat.groups or {}) do panel.groups[#panel.groups + 1] = g end end
    return panel
end

-- ---------------------------------------------------------------------------
-- ReadingFacts - books / magazines / recipe sources
-- ---------------------------------------------------------------------------
function M.ReadingFacts(item)
    if not item then return nil end
    if not (instanceof and instanceof(item, "Literature")) then return nil end

    local skill        = safeGet(item, "getSkillTrained")
    local lvlMin       = safeGet(item, "getLvlSkillTrained")
    local lvlMax       = safeGet(item, "getMaxLevelTrained")
    local pages        = safeGet(item, "getNumberOfPages")
    local recipes      = safeGet(item, "getLearnedRecipes")
    local recipeCount  = recipes and safeGet(recipes, "size")

    -- The pages read live on the character (the game's tooltip reads them there);
    -- a book with none, such as a magazine, has no progress to show.
    local player       = getPlayer and getPlayer()
    local fullType     = safeGet(item, "getFullType")
    local pagesRead    = nil
    if pages and pages > 0 then
        pagesRead = player and fullType and safeGet(player, "getAlreadyReadPages", fullType)
            or safeGet(item, "getAlreadyReadPages")
    end

    -- ReadMarks holds the game's own test (a skill book past your level counts as
    -- read). It asks compute, not state: state answers nil while read marks are off in setup.
    local alreadyRead  = false
    local marks = ZeD.ReadMarks
    if player and marks and marks.compute then
        local ok, status = pcall(marks.compute, player, item)
        alreadyRead = ok and status ~= nil and status.st == "r"
    end

    local readRatio = pagesRead and (pagesRead / pages) or nil

    local panel = {
        title         = ZeD.tr("UI_ZeD_Card_FactsReading"),
        hasDisclosure = false,
        groups        = {},
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = getText("IGUI_Skill"),       value = (skill and skill ~= "") and tostring(skill) or "-",
             valueClass = (not skill or skill == "") and "dim" or nil},
            {label = ZeD.tr("UI_ZeD_Card_LevelRange"), value = (lvlMin and lvlMax and lvlMin >= 0) and string.format("%d - %d", lvlMin, lvlMax) or ZeD.tr("UI_ZeD_Card_Any"),
             valueClass = (not (lvlMin and lvlMax and lvlMin >= 0)) and "dim" or nil},
        },
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = ZeD.tr("UI_ZeD_Card_Progress"), value = pagesRead and string.format("%d / %d", pagesRead, pages) or "-",
             valueClass = readRatio and (readRatio >= 1 and "good" or (readRatio > 0 and "warn" or "dim")) or nil},
            {label = ZeD.tr("UI_ZeD_Card_Read"),     value = alreadyRead and getText("IGUI_Yes") or getText("IGUI_No"),
             valueClass = alreadyRead and "dim" or nil},
        },
    }

    if recipeCount and recipeCount > 0 then
        panel.groups[#panel.groups + 1] = {
            rows = {
                {label = getText("IGUI_LiteratureUI_Recipes"), value = tostring(recipeCount)},
            },
        }
    end

    return panel
end

-- ---------------------------------------------------------------------------
-- Registry + dispatch
-- ---------------------------------------------------------------------------
-- Priority order: most-specific first. ContainerFacts last so a bag-of-food
-- shows NutritionFacts on the food, not the bag's container stats.
M._registry = {
    {key = "liquid",    factory = M.LiquidFacts},   -- (first: a liquid container's liquid before a weapon's combat)
    {key = "reading",   factory = M.ReadingFacts},
    {key = "nutrition", factory = M.NutritionFacts},
    {key = "combat",    factory = M.CombatFacts},
    {key = "defense",   factory = M.DefenseFacts},
    {key = "container", factory = M.ContainerFacts},
}

--- Dispatch: find the first factory that produces a non-nil panel.
--- @param item PZ inventory item
--- @param playerNum whose card it is (handed on to each factory; a factory that takes only the item ignores it)
--- @return panel | nil
function M.factsFor(item, playerNum)
    if not item then return nil end
    for _, entry in ipairs(M._registry) do
        local panel = entry.factory(item, playerNum)
        if panel then
            panel._key = entry.key
            return panel
        end
    end
    return nil
end

--- Late-register or override a factory, so an add-on mod can card its own
--- item types. Inserts at the given priority index (1 = first), or appends
--- when priority is nil.
--- @param key      string key for the panel type
--- @param factory  function(item, playerNum) -> panel|nil (playerNum: whose card; may be ignored)
--- @param priority integer | nil
function M.register(key, factory, priority)
    if not key or not factory then return end
    M.gen = (M.gen or 0) + 1   -- a card showing an item builds its model again (ItemCardOrganism.lua)
    -- Drop any existing entry with the same key
    for i = #M._registry, 1, -1 do
        if M._registry[i].key == key then
            table.remove(M._registry, i)
        end
    end
    local entry = {key = key, factory = factory}
    if priority and priority >= 1 and priority <= #M._registry + 1 then
        table.insert(M._registry, priority, entry)
    else
        table.insert(M._registry, entry)
    end
end
