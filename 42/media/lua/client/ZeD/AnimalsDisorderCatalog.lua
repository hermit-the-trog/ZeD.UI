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

-- label / desc are TEXT KEYS (UI_ZeD_Animals_Dis_<Name>_Label / _Desc); the reader
-- translates them where they are shown (ZeD.AnimalsData.getVisibleDisorders).
local CATALOG = {
    -- Positive traits
    fertile       = { sev = "positive", label = "UI_ZeD_Animals_Dis_Fertile_Label",       desc = "UI_ZeD_Animals_Dis_Fertile_Desc" },
    strong        = { sev = "positive", label = "UI_ZeD_Animals_Dis_Strong_Label",        desc = "UI_ZeD_Animals_Dis_Strong_Desc" },

    -- Severe (revealed at Husbandry 7)
    sterile       = { sev = "severe",   label = "UI_ZeD_Animals_Dis_Sterile_Label",       desc = "UI_ZeD_Animals_Dis_Sterile_Desc" },
    noeggs        = { sev = "severe",   label = "UI_ZeD_Animals_Dis_NoEggs_Label",        desc = "UI_ZeD_Animals_Dis_NoEggs_Desc" },
    nomilk        = { sev = "severe",   label = "UI_ZeD_Animals_Dis_NoMilk_Label",        desc = "UI_ZeD_Animals_Dis_NoMilk_Desc" },
    nowool        = { sev = "severe",   label = "UI_ZeD_Animals_Dis_NoWool_Label",        desc = "UI_ZeD_Animals_Dis_NoWool_Desc" },
    dieatbirth    = { sev = "severe",   label = "UI_ZeD_Animals_Dis_WeakBirth_Label",     desc = "UI_ZeD_Animals_Dis_WeakBirth_Desc" },

    -- Minor (revealed at Husbandry 9)
    poorfertility = { sev = "minor",    label = "UI_ZeD_Animals_Dis_LowFertility_Label",  desc = "UI_ZeD_Animals_Dis_LowFertility_Desc" },
    poormilk      = { sev = "minor",    label = "UI_ZeD_Animals_Dis_LowMilk_Label",       desc = "UI_ZeD_Animals_Dis_LowMilk_Desc" },
    poorwool      = { sev = "minor",    label = "UI_ZeD_Animals_Dis_LowWool_Label",       desc = "UI_ZeD_Animals_Dis_LowWool_Desc" },
    smalleggs     = { sev = "minor",    label = "UI_ZeD_Animals_Dis_SmallEggs_Label",     desc = "UI_ZeD_Animals_Dis_SmallEggs_Desc" },
    dwarf         = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Dwarfism_Label",      desc = "UI_ZeD_Animals_Dis_Dwarfism_Desc" },
    poorlife      = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Fragile_Label",       desc = "UI_ZeD_Animals_Dis_Fragile_Desc" },
    skinny        = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Skinny_Label",        desc = "UI_ZeD_Animals_Dis_Skinny_Desc" },
    gluttonous    = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Gluttonous_Label",    desc = "UI_ZeD_Animals_Dis_Gluttonous_Desc" },
    highthirst    = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Thirsty_Label",       desc = "UI_ZeD_Animals_Dis_Thirsty_Desc" },
    highstress    = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Anxious_Label",       desc = "UI_ZeD_Animals_Dis_Anxious_Desc" },
    fidget        = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Restless_Label",      desc = "UI_ZeD_Animals_Dis_Restless_Desc" },
    craven        = { sev = "minor",    label = "UI_ZeD_Animals_Dis_Craven_Label",        desc = "UI_ZeD_Animals_Dis_Craven_Desc" },
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
