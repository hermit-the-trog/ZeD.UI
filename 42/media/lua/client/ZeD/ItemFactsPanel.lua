-- ZeD-UI/42/media/lua/client/ZeD/ItemFactsPanel.lua
-- ============================================================================
-- ITEM FACTS PANEL REGISTRY (S120 - Phase 4)
-- Five item-type-specific Facts panels - each a factory taking (item) and
-- returning a structured panel description, or nil if the item is not its
-- target type. The Phase 5 (S121) ItemCard organism queries the registry
-- via factsFor(item) - never branches on item class itself.
--
-- Factory return shape:
--   nil  → this panel doesn't apply to the item
--   {
--     title         = "Nutrition Facts",
--     hasDisclosure = bool, -- 220w only: clothing collapses behind a chevron
--                           -- because zones compete for vertical space; other
--                           -- panels stay always-expanded
--     groups        = { -- separated by thin rules in render
--       { rows = { {label, value, valueClass, isSub, needsProbe}, ... } },
--       ...
--     }
--   }
--
-- needsProbe = true → renderer appends a small "★" badge after the label
-- (mockup convention from v13 - values whose Java getter we haven't probed
-- yet). Phase 4 PZ probes Q125-Q128 will retire these flags as they land.
-- ============================================================================

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

-- Format a percentage-like int with sign, e.g. "5%" / "-2%" / "+15"
local function _pct(n, withSign)
    if not n then return nil end
    n = math.floor(n + 0.5)
    if withSign and n > 0 then return "+" .. tostring(n) .. "%" end
    return tostring(n) .. "%"
end

-- Color class from a 0..1 ratio (warn at <0.6, bad at <0.3, good at >=0.6, dim at 0)
local function _condClass(ratio)
    if not ratio or ratio <= 0 then return "dim" end
    if ratio < 0.3  then return "bad"  end
    if ratio < 0.6  then return "warn" end
    if ratio < 0.85 then return nil    end  -- normal
    return "good"
end

-- ---------------------------------------------------------------------------
-- T4.1 DefenseFacts - clothing
-- ---------------------------------------------------------------------------
function M.DefenseFacts(item)
    if not item then return nil end
    local isClothing = safeGet(item, "IsClothing")
    if not isClothing and not (instanceof and instanceof(item, "Clothing")) then
        return nil
    end

    -- Defense values (per-zone aggregated to "for any zone covered" - the
    -- exact aggregation lives in the organism; the factory just shows the
    -- representative max defense from the script item).
    local script = safeGet(item, "getScriptItem")
    local biteDef    = script and safeGet(script, "getBiteDefense")
    local scratchDef = script and safeGet(script, "getScratchDefense")
    local bulletDef  = script and safeGet(script, "getBulletDefense")
    local insulation = script and safeGet(script, "getInsulation")        -- Q125 probe
    local windRes    = script and safeGet(script, "getWindResistance")     -- Q126 probe
    local waterRes   = script and safeGet(script, "getWaterResistance")
    local neckProt   = script and safeGet(script, "getNeckProtectionModifier")
    local condLoss   = script and safeGet(script, "getConditionLowerChanceOneIn")

    local panel = {
        title         = "Defense Facts",
        hasDisclosure = true,  -- 220w: zones compete, defense behind chevron
        groups        = {},
    }

    -- Group 1: bite/scratch/bullet
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Bite Defense",    value = biteDef    and _pct(biteDef)    or "0%",
             valueClass = (biteDef    or 0) > 0 and "warn" or "dim"},
            {label = "Scratch Defense", value = scratchDef and _pct(scratchDef) or "0%",
             valueClass = (scratchDef or 0) > 0 and "warn" or "dim"},
            {label = "Bullet Defense",  value = bulletDef  and _pct(bulletDef)  or "0%",
             valueClass = (bulletDef  or 0) > 0 and "warn" or "dim"},
        },
    }

    -- Group 2: thermal + water + neck
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Insulation",      value = insulation and string.format("%d / 100", insulation * 100) or "-",
             valueClass = insulation and nil or "dim", needsProbe = insulation == nil},
            {label = "Wind Resistance", value = windRes and string.format("%d / 100", windRes * 100) or "-",
             valueClass = windRes and nil or "dim", needsProbe = windRes == nil},
            {label = "Water Resistance",value = waterRes and string.format("%d / 100", waterRes * 100) or "-",
             valueClass = "dim"},
            {label = "Neck Protection", value = neckProt and string.format("%d%%", neckProt * 100) or "-",
             valueClass = "dim"},
        },
    }

    -- Group 3: condition decay
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Cond Loss / Hit", value = condLoss and "1 / " .. tostring(condLoss) or "-"},
            {label = "1-in-N degrade",  value = condLoss and tostring(condLoss) or "-", isSub = true},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- T4.2 NutritionFacts - food
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
        title         = "Nutrition Facts",
        hasDisclosure = false,
        groups        = {},
    }

    -- Group 1: hunger + thirst (the two primary needs the food addresses)
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Hunger Reduction", value = hunger and string.format("%+d", -math.floor(hunger * 100 + 0.5)) or "-"},
            {label = "Thirst Reduction", value = thirst and string.format("%+d", -math.floor(thirst * 100 + 0.5)) or "-"},
        },
    }

    -- Group 2: macro nutrients
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Calories", value = cal     and tostring(math.floor(cal     + 0.5))             or "-"},
            {label = "Protein",  value = protein and string.format("%d g", math.floor(protein + 0.5)) or "-"},
            {label = "Fat",      value = fat     and string.format("%d g", math.floor(fat     + 0.5)) or "-"},
            {label = "Carbs",    value = carbs   and string.format("%d g", math.floor(carbs   + 0.5)) or "-"},
        },
    }

    -- Group 3: secondary effects
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Sickness Risk", value = (sickness and sickness > 0) and string.format("+%d%%", sickness) or "0%",
             valueClass = (sickness and sickness > 0) and "bad" or "dim"},
            {label = "Boredom",       value = boredom and string.format("%+d", math.floor(boredom + 0.5)) or "-",
             valueClass = (boredom or 0) > 0 and "warn" or nil},
            {label = "Happiness",     value = happy   and string.format("%+d", math.floor(-happy  + 0.5)) or "-"},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- T4.3 CombatFacts - weapons
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
    local ammoType  = safeGet(item, "getAmmoType")

    local panel = {
        title         = "Combat Facts",
        hasDisclosure = false,
        groups        = {},
    }

    -- Group 1: damage + reach
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Damage", value = (dmgMin and dmgMax) and string.format("%.1f - %.1f", dmgMin, dmgMax) or "-"},
            {label = "Range",  value = (rangeMin and rangeMax) and string.format("%.1f - %.1f m", rangeMin, rangeMax) or "-"},
            {label = "Swing",  value = swingTime and string.format("%.2f s", swingTime) or "-"},
        },
    }

    -- Group 2: handling + crit
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Knockback",     value = knockback   and string.format("%.2f", knockback)   or "-"},
            {label = "Critical %",    value = critChance  and string.format("%d%%", critChance)  or "-"},
        },
    }

    -- Group 3: durability + ammo
    local ratio  = (cond and condMax and condMax > 0) and (cond / condMax) or nil
    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Condition",     value = (cond and condMax) and string.format("%d / %d", cond, condMax) or "-",
             valueClass = _condClass(ratio)},
            {label = "Ammo",          value = (ammoType and ammoType ~= "") and tostring(ammoType) or "-",
             valueClass = (not ammoType or ammoType == "") and "dim" or nil},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- T4.4 ContainerFacts - bags / boxes / cooking pots
-- ---------------------------------------------------------------------------
function M.ContainerFacts(item)
    if not item then return nil end
    local inv = safeGet(item, "getInventory")
    if not inv then return nil end

    local cap     = safeGet(inv, "getCapacity") or safeGet(item, "getCapacity")
    local current = safeGet(inv, "getContentsWeight")
    local nItems  = safeGet(inv, "getItems")
    local count   = nItems and safeGet(nItems, "size") or nil
    local reduce  = safeGet(item, "getWeightReduction")

    local fillRatio = (cap and cap > 0 and current) and (current / cap) or nil

    local panel = {
        title         = "Container Facts",
        hasDisclosure = false,
        groups        = {},
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Capacity", value = (current and cap) and string.format("%.1f / %d kg", current, cap) or "-",
             valueClass = _condClass(fillRatio and (1 - fillRatio) or nil)},
            {label = "Items",    value = count and tostring(count) or "-"},
        },
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Weight Reduction", value = reduce and string.format("%d%%", reduce) or "-",
             valueClass = (reduce and reduce > 0) and "good" or "dim"},
        },
    }

    return panel
end

-- ---------------------------------------------------------------------------
-- T4.5 ReadingFacts - books / magazines / recipe sources
-- ---------------------------------------------------------------------------
function M.ReadingFacts(item)
    if not item then return nil end
    if not (instanceof and instanceof(item, "Literature")) then return nil end

    local skill        = safeGet(item, "getSkillTrained")
    local lvlMin       = safeGet(item, "getLvlSkillTrained")
    local lvlMax       = safeGet(item, "getMaxLevelTrained")
    local pages        = safeGet(item, "getNumberOfPages")
    local pagesRead    = safeGet(item, "getNumberOfPagesToRead")  -- progress
    local recipeCount  = safeGet(item, "getNumberOfMappedRecipes")
    local alreadyRead  = safeGet(item, "isAlreadyReadByPlayer")

    local readRatio = (pages and pages > 0 and pagesRead)
        and ((pages - pagesRead) / pages) or nil

    local panel = {
        title         = "Reading Facts",
        hasDisclosure = false,
        groups        = {},
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Skill",       value = (skill and skill ~= "") and tostring(skill) or "-",
             valueClass = (not skill or skill == "") and "dim" or nil},
            {label = "Level Range", value = (lvlMin and lvlMax and lvlMin >= 0) and string.format("%d - %d", lvlMin, lvlMax) or "Any",
             valueClass = (not (lvlMin and lvlMax and lvlMin >= 0)) and "dim" or nil},
        },
    }

    panel.groups[#panel.groups + 1] = {
        rows = {
            {label = "Progress", value = (pages and pagesRead) and string.format("%d / %d", pages - pagesRead, pages) or "-",
             valueClass = readRatio and (readRatio >= 1 and "good" or "warn") or nil},
            {label = "Read",     value = alreadyRead and "Yes" or "No",
             valueClass = alreadyRead and "dim" or nil},
        },
    }

    if recipeCount and recipeCount > 0 then
        panel.groups[#panel.groups + 1] = {
            rows = {
                {label = "Recipes", value = tostring(recipeCount)},
            },
        }
    end

    return panel
end

-- ---------------------------------------------------------------------------
-- T4.6 Registry + dispatch
-- ---------------------------------------------------------------------------
-- Priority order: most-specific first. ContainerFacts last so a bag-of-food
-- shows NutritionFacts on the food, not the bag's container stats.
M._registry = {
    {key = "reading",   factory = M.ReadingFacts},
    {key = "nutrition", factory = M.NutritionFacts},
    {key = "combat",    factory = M.CombatFacts},
    {key = "defense",   factory = M.DefenseFacts},
    {key = "container", factory = M.ContainerFacts},
}

--- Dispatch: find the first factory that produces a non-nil panel.
--- @param item PZ inventory item
--- @return panel | nil
function M.factsFor(item)
    if not item then return nil end
    for _, entry in ipairs(M._registry) do
        local panel = entry.factory(item)
        if panel then
            panel._key = entry.key
            return panel
        end
    end
    return nil
end

--- Mutator: late-register or override a factory. Used by mod extensions
--- (custom item types, total conversion content). Insert at given priority
--- index (1 = first), or append if priority is nil.
--- @param key      string key for the panel type
--- @param factory  function(item) -> panel|nil
--- @param priority integer | nil
function M.register(key, factory, priority)
    if not key or not factory then return end
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
