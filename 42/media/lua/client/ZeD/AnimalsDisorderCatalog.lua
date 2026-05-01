-- ZeD-UI/42/media/lua/client/ZeD/AnimalsDisorderCatalog.lua
-- ============================================================================
-- DISORDER CATALOG — maps engine disorder strings to human-readable labels.
-- Three severity tiers control skill-gated reveal:
--   "positive" — always shown when disorders are visible
--   "severe"   — revealed at Husbandry 7+
--   "minor"    — revealed at Husbandry 9+
-- ============================================================================

ZeD = ZeD or {}
ZeD.AnimalsDisorderCatalog = ZeD.AnimalsDisorderCatalog or {}

-- ---------------------------------------------------------------------------
-- CATALOG
-- Key = engine disorder string (lowercase, from animal:getGeneticDisorder())
-- ---------------------------------------------------------------------------

local CATALOG = {
    -- Positive traits
    fertile       = { sev = "positive", label = "Fertile",       desc = "Always breeds successfully" },
    strong        = { sev = "positive", label = "Strong",        desc = "Higher damage when attacking" },

    -- Severe (revealed at Husbandry 7)
    sterile       = { sev = "severe",   label = "Sterile",       desc = "Cannot breed" },
    noeggs        = { sev = "severe",   label = "No Eggs",       desc = "Never lays eggs" },
    nomilk        = { sev = "severe",   label = "No Milk",       desc = "Never produces milk" },
    nowool        = { sev = "severe",   label = "No Wool",       desc = "Never grows wool" },
    dieatbirth    = { sev = "severe",   label = "Weak Birth",    desc = "Offspring may die at birth" },

    -- Minor (revealed at Husbandry 9)
    poorfertility = { sev = "minor",    label = "Low Fertility",  desc = "Rarely breeds successfully" },
    poormilk      = { sev = "minor",    label = "Low Milk",       desc = "~80% less milk generation" },
    poorwool      = { sev = "minor",    label = "Low Wool",       desc = "~80% less wool generation" },
    smalleggs     = { sev = "minor",    label = "Small Eggs",     desc = "Negligible hunger value" },
    dwarf         = { sev = "minor",    label = "Dwarfism",       desc = "Smaller size, shorter life" },
    poorlife      = { sev = "minor",    label = "Fragile",        desc = "Shorter lifespan" },
    skinny        = { sev = "minor",    label = "Skinny",         desc = "Reduced weight" },
    gluttonous    = { sev = "minor",    label = "Gluttonous",     desc = "Eats more than average" },
    highthirst    = { sev = "minor",    label = "Thirsty",        desc = "Drinks more than average" },
    highstress    = { sev = "minor",    label = "Anxious",        desc = "Stresses easily" },
    fidget        = { sev = "minor",    label = "Restless",       desc = "Wanders farther than average" },
    craven        = { sev = "minor",    label = "Craven",         desc = "Flees almost any threat" },
}

ZeD.AnimalsDisorderCatalog.CATALOG = CATALOG

-- ---------------------------------------------------------------------------
-- lookup(key) — returns catalog entry or nil
-- ---------------------------------------------------------------------------

function ZeD.AnimalsDisorderCatalog.lookup(key)
    if not key then return nil end
    return CATALOG[string.lower(tostring(key))]
end

-- ---------------------------------------------------------------------------
-- hasDisorder(animal, disorderKey) — check if animal has a specific disorder
-- ---------------------------------------------------------------------------

function ZeD.AnimalsDisorderCatalog.hasDisorder(animal, disorderKey)
    local disorders = animal and animal.getGeneticDisorder and animal:getGeneticDisorder()
    if not disorders then return false end
    local target = string.lower(tostring(disorderKey))
    for i = 0, disorders:size() - 1 do
        if string.lower(tostring(disorders:get(i))) == target then
            return true
        end
    end
    return false
end
