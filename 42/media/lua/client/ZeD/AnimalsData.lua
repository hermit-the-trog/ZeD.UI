-- ZeD-UI/42/media/lua/client/ZeD/AnimalsData.lua
-- ============================================================================
-- ANIMALS DATA — live getters, skill gate, portrait resolver, action icons.
-- Central access point for all animal data reads. Every UI element in the
-- Animals tab pulls through here — never calls engine getters directly.
--
-- API correction (S84): hunger is on the Stats object (0.0–1.0 scale),
-- NOT on getData(). Thirst has a direct shortcut animal:getThirst().
-- ============================================================================

require "ZeD/AnimalsDisorderCatalog"

ZeD = ZeD or {}
ZeD.AnimalsData = ZeD.AnimalsData or {}

local AD = ZeD.AnimalsData
local DC = ZeD.AnimalsDisorderCatalog

-- ============================================================================
-- CONSTANTS
-- ============================================================================

AD.PERK_NAME  = "Husbandry"            -- engine perk ID
AD.PERK_LABEL = "Animal Care"          -- user-facing display name

-- Acceptance thresholds (from vanilla ISAnimalContextMenu)
AD.ACCEPT_CALL    = 40
AD.ACCEPT_PETTING = 50

-- ============================================================================
-- SKILL GATE — maps info categories to minimum Husbandry level
-- ============================================================================

local VISIBILITY = {
    -- Always visible (Lv 0)
    species         = 0,
    breed           = 0,
    sex             = 0,
    stage           = 0,
    custom_name     = 0,
    zone_assign     = 0,
    health_text     = 0,    -- "Healthy" / "Sickly" (vanilla getHealthText)
    hunger_text     = 0,
    thirst_text     = 0,
    stress_text     = 0,    -- "Calm" / "Stressed" (vanilla getStressTxt)

    -- Numeric readouts (Lv 3)
    health_num      = 3,
    hunger_num      = 3,
    thirst_num      = 3,
    stress_num      = 3,
    pregnancy_yn    = 3,
    weight_rough    = 3,

    -- Production detail (Lv 5)
    pregnancy_bar   = 5,
    production_state = 5,   -- "milkable", "shearable", etc.
    acceptance_num  = 5,
    male_warning    = 5,

    -- Management detail (Lv 7)
    trough_levels   = 7,
    production_est  = 7,
    disorder_severe = 7,
    mating_calendar = 7,

    -- Expert detail (Lv 9)
    disorder_all    = 9,
    gene_hints      = 9,
    last_milked     = 9,

    -- Debug only
    genome_raw      = 99,
}

AD.VISIBILITY = VISIBILITY

function AD.canSee(player, category)
    if not player then return false end
    local gate = VISIBILITY[category] or 0
    local level = player:getPerkLevel(Perks.Husbandry)
    return level >= gate
end

function AD.getSkillLevel(player)
    if not player then return 0 end
    return player:getPerkLevel(Perks.Husbandry)
end

-- ============================================================================
-- SAFE STAT GETTERS — normalize to 0–100 for display
-- Engine returns 0.0–1.0 for hunger/thirst via Stats object.
-- Stress and health are already 0–100 from engine.
-- ============================================================================

function AD.getHunger(animal)
    if not animal then return 0 end
    -- Primary: Stats object (confirmed in ISAnimalContextMenu)
    local stats = animal.getStats and animal:getStats()
    if stats then
        local ok, val = pcall(function() return stats:get(CharacterStat.HUNGER) end)
        if ok and val then return val * 100 end
    end
    -- Fallback: direct getter (may not exist)
    if animal.getHunger then
        local ok, val = pcall(animal.getHunger, animal)
        if ok and val then return val * 100 end
    end
    return 0
end

function AD.getThirst(animal)
    if not animal then return 0 end
    -- Primary: direct shortcut (confirmed in ISGiveWaterToAnimal)
    if animal.getThirst then
        local ok, val = pcall(animal.getThirst, animal)
        if ok and val then return val * 100 end
    end
    -- Fallback: Stats object
    local stats = animal.getStats and animal:getStats()
    if stats then
        local ok, val = pcall(function() return stats:get(CharacterStat.THIRST) end)
        if ok and val then return val * 100 end
    end
    return 0
end

function AD.getHealth(animal)
    if not animal then return 0 end
    local ok, val = pcall(animal.getHealth, animal)
    if ok and val then return val end
    return 0
end

function AD.getStress(animal)
    if not animal then return 0 end
    local ok, val = pcall(animal.getStress, animal)
    if ok and val then return val end
    return 0
end

function AD.getWeight(animal)
    if not animal then return 0 end
    local data = animal.getData and animal:getData()
    if data and data.getWeight then
        local ok, val = pcall(data.getWeight, data)
        if ok and val then return val end
    end
    return 0
end

-- ============================================================================
-- IDENTITY GETTERS
-- ============================================================================

function AD.getAnimalType(animal)
    if not animal then return "unknown" end
    local ok, val = pcall(animal.getAnimalType, animal)
    return (ok and val) or "unknown"
end

function AD.getDisplayName(animal)
    if not animal then return "Unknown" end
    -- Custom name first
    local custom = animal.getCustomName and animal:getCustomName()
    if custom and custom ~= "" then return custom end
    -- Fallback: translated type name
    local atype = AD.getAnimalType(animal)
    return getText("IGUI_AnimalType_" .. atype) or atype
end

function AD.getBreedName(animal)
    if not animal then return "" end
    local data = animal.getData and animal:getData()
    if not data then return "" end
    local breed = data.getBreed and data:getBreed()
    if not breed then return "" end
    local ok, val = pcall(breed.getName, breed)
    return (ok and val) or ""
end

function AD.isFemale(animal)
    if not animal then return false end
    local ok, val = pcall(animal.isFemale, animal)
    return ok and val
end

function AD.isBaby(animal)
    if not animal then return false end
    local ok, val = pcall(animal.isBaby, animal)
    return ok and val
end

function AD.isWild(animal)
    if not animal then return true end
    local ok, val = pcall(animal.isWild, animal)
    return ok and val
end

function AD.getZoneName(animal)
    if not animal then return nil end
    local zone = animal.getDZone and animal:getDZone()
    if not zone then return nil end
    local ok, val = pcall(zone.getName, zone)
    return (ok and val) or nil
end

function AD.getDaysSurvived(animal)
    if not animal then return 0 end
    local data = animal.getData and animal:getData()
    if data and data.getDaysSurvived then
        local ok, val = pcall(data.getDaysSurvived, data)
        if ok and val then return val end
    end
    return 0
end

-- ============================================================================
-- VANILLA TEXT GETTERS — skill-aware formatted strings from engine
-- These are the best source for low-skill display (vague descriptors).
-- ============================================================================

function AD.getAgeText(animal, player)
    if not animal or not animal.getAgeText then return "" end
    local lvl = AD.getSkillLevel(player)
    local ok, val = pcall(animal.getAgeText, animal, false, lvl)
    return (ok and val) or ""
end

function AD.getHealthText(animal, player)
    if not animal or not animal.getHealthText then return "" end
    local lvl = AD.getSkillLevel(player)
    local ok, val = pcall(animal.getHealthText, animal, false, lvl)
    return (ok and val) or ""
end

function AD.getStressText(animal, player)
    if not animal or not animal.getStressTxt then return "" end
    local lvl = AD.getSkillLevel(player)
    local ok, val = pcall(animal.getStressTxt, animal, false, lvl)
    return (ok and val) or ""
end

-- ============================================================================
-- PRODUCTION GETTERS
-- ============================================================================

function AD.getMilkQuantity(animal)
    if not animal then return 0 end
    local data = animal.getData and animal:getData()
    if data and data.getMilkQuantity then
        local ok, val = pcall(data.getMilkQuantity, data)
        if ok and val then return val end
    end
    return 0
end

function AD.getMaxMilk(animal)
    if not animal then return 0 end
    local data = animal.getData and animal:getData()
    if data and data.getMaxMilk then
        local ok, val = pcall(data.getMaxMilk, data)
        if ok and val then return val end
    end
    return 0
end

function AD.isUdderUrgent(animal)
    return AD.getMilkQuantity(animal) > AD.getMaxMilk(animal)
end

function AD.getLastMilkedHours(animal)
    if not animal then return nil end
    local data = animal.getData and animal:getData()
    if data and data.getLastTimeMilkedInHour then
        local ok, val = pcall(data.getLastTimeMilkedInHour, data)
        if ok and val then return val end
    end
    return nil
end

function AD.getWoolQuantity(animal)
    if not animal then return 0 end
    local data = animal.getData and animal:getData()
    if data and data.getWoolQuantity then
        local ok, val = pcall(data.getWoolQuantity, data)
        if ok and val then return val end
    end
    return 0
end

function AD.getMaxWool(animal)
    if not animal then return 0 end
    local data = animal.getData and animal:getData()
    if data and data.getMaxWool then
        local ok, val = pcall(data.getMaxWool, data)
        if ok and val then return val end
    end
    return 0
end

function AD.canBeMilked(animal)
    if not animal or not animal.canBeMilked then return false end
    local ok, val = pcall(animal.canBeMilked, animal)
    return ok and val
end

function AD.canBeSheared(animal)
    if not animal or not animal.canBeSheared then return false end
    local ok, val = pcall(animal.canBeSheared, animal)
    return ok and val
end

function AD.getEggsPerDay(animal)
    if not animal or not animal.getEggsPerDay then return 0 end
    local ok, val = pcall(animal.getEggsPerDay, animal)
    return (ok and val) or 0
end

function AD.isLaying(animal)
    if not animal then return false end
    local data = animal.getData and animal:getData()
    if not data or not data.isInLayingEggPeriod then return false end
    if not getGameTime then return false end
    local gt = getGameTime()
    if not gt or not gt.getCalender then return false end
    local cal = gt:getCalender()
    if not cal then return false end
    local ok, val = pcall(data.isInLayingEggPeriod, data, cal)
    return ok and val
end

-- ============================================================================
-- BREEDING GETTERS
-- ============================================================================

function AD.isPregnant(animal)
    if not animal then return false end
    local data = animal.getData and animal:getData()
    if not data or not data.isPregnant then return false end
    local ok, val = pcall(data.isPregnant, data)
    return ok and val
end

function AD.getPregnancyProgress(animal)
    if not animal then return 0, 0 end
    local data = animal.getData and animal:getData()
    if not data then return 0, 0 end
    local current, total = 0, 0
    if data.getPregnancyTime then
        local ok, val = pcall(data.getPregnancyTime, data)
        if ok and val then current = val end
    end
    if data.getPregnantPeriod then
        local ok, val = pcall(data.getPregnantPeriod, data)
        if ok and val then total = val end
    end
    return current, total
end

function AD.isInMatingSeason(animal)
    if not animal or not animal.isInMatingSeason then return false end
    local ok, val = pcall(animal.isInMatingSeason, animal)
    return ok and val
end

function AD.haveMatingSeason(animal)
    if not animal or not animal.haveMatingSeason then return false end
    local ok, val = pcall(animal.haveMatingSeason, animal)
    return ok and val
end

-- ============================================================================
-- RELATIONSHIP GETTERS
-- ============================================================================

function AD.getMother(animal)
    if not animal or not animal.getMother then return nil end
    local ok, val = pcall(animal.getMother, animal)
    return (ok and val) or nil
end

function AD.getBabies(animal)
    if not animal or not animal.getBabies then return nil end
    local ok, val = pcall(animal.getBabies, animal)
    return (ok and val) or nil
end

function AD.getPlayerAcceptance(animal, player)
    if not animal or not player then return 0 end
    if not animal.getPlayerAcceptance then return 0 end
    local ok, val = pcall(animal.getPlayerAcceptance, animal, player)
    return (ok and val) or 0
end

function AD.needsMother(animal)
    if not animal then return false end
    if not AD.isBaby(animal) then return false end
    if not animal.needMom then return false end
    local ok, needsMom = pcall(animal.needMom, animal)
    if not ok or not needsMom then return false end
    local mother = AD.getMother(animal)
    if not mother then return true end
    if mother.isExistInTheWorld then
        local ok2, exists = pcall(mother.isExistInTheWorld, mother)
        if ok2 and not exists then return true end
    end
    return false
end

function AD.isInHutch(animal)
    if not animal or not animal.getHutch then return false end
    local ok, val = pcall(animal.getHutch, animal)
    return ok and val ~= nil
end

function AD.attacksOtherMales(animal)
    if not animal or not animal.attackOtherMales then return false end
    local ok, val = pcall(animal.attackOtherMales, animal)
    return ok and val
end

-- ============================================================================
-- DISORDER HELPERS — wraps DisorderCatalog with skill gating
-- ============================================================================

function AD.getVisibleDisorders(animal, player)
    if not animal then return {} end
    local disorders = animal.getGeneticDisorder and animal:getGeneticDisorder()
    if not disorders then return {} end

    local canSeeSevere = AD.canSee(player, "disorder_severe")
    local canSeeAll    = AD.canSee(player, "disorder_all")
    local result = {}

    for i = 0, disorders:size() - 1 do
        local key = string.lower(tostring(disorders:get(i)))
        local entry = DC.lookup(key)
        if entry then
            local show = false
            if entry.sev == "positive" then
                show = canSeeSevere  -- show positive alongside severe
            elseif entry.sev == "severe" then
                show = canSeeSevere
            elseif entry.sev == "minor" then
                show = canSeeAll
            end
            if show then
                table.insert(result, {
                    key   = key,
                    sev   = entry.sev,
                    label = entry.label,
                    desc  = entry.desc,
                })
            end
        end
    end
    return result
end

-- ============================================================================
-- CONDITION TAGS — computed status flags for roster row display
-- ============================================================================

function AD.getConditionTags(animal, player)
    local tags = {}
    if AD.isUdderUrgent(animal) then
        table.insert(tags, { id = "udder_urgent", label = "Udder URGENT", sev = "danger" })
    end
    if AD.canBeMilked(animal) then
        table.insert(tags, { id = "milkable", label = "Milkable", sev = "good" })
    end
    if AD.canBeSheared(animal) then
        table.insert(tags, { id = "shearable", label = "Wool ready", sev = "good" })
    end
    if AD.isLaying(animal) then
        table.insert(tags, { id = "laying", label = "Laying", sev = "good" })
    end
    if AD.isPregnant(animal) then
        table.insert(tags, { id = "pregnant", label = "Pregnant", sev = "info" })
    end
    if AD.needsMother(animal) then
        table.insert(tags, { id = "orphan", label = "Orphan", sev = "danger" })
    end
    if AD.isInHutch(animal) then
        table.insert(tags, { id = "hutch", label = "In hutch", sev = "neutral" })
    end
    return tags
end

-- ============================================================================
-- PORTRAIT ICON RESOLVER
-- Maps (animalType, breed, sex, isBaby) → media/ui/ texture path.
-- Uses Head_ variants for compact roster portraits.
-- ============================================================================

local PORTRAITS = {
    -- Chickens — full body sprites available
    chicken_hen_brown     = "media/ui/Item_Chicken_HenBrown.png",
    chicken_hen_white     = "media/ui/Item_Chicken_HenWhite.png",
    chicken_rooster_brown = "media/ui/Item_Chicken_RoosterBrown.png",
    chicken_rooster_white = "media/ui/Item_Chicken_RoosterWhite.png",
    chicken_chick         = "media/ui/Item_Chicken_Chick.png",

    -- Cows — head variants by breed color + sex
    cow_female_brown       = "media/ui/Item_Head_CowFemale_Brown.png",
    cow_female_black       = "media/ui/Item_Head_CowFemale_Black.png",
    cow_female_blackwhite  = "media/ui/Item_Head_CowFemale_BlackWhite.png",
    cow_male_brown         = "media/ui/Item_Head_CowMale_Brown.png",
    cow_male_black         = "media/ui/Item_Head_CowMale_Black.png",
    cow_male_blackwhite    = "media/ui/Item_Head_CowMale_BlackWhite.png",
    cow_calf_brown         = "media/ui/Item_Head_CowCalf_Brown.png",
    cow_calf_black         = "media/ui/Item_Head_CowCalf_Black.png",
    cow_calf_blackwhite    = "media/ui/Item_Head_CowCalf_BlackWhite.png",

    -- Pigs — head variants
    pig_female_pink        = "media/ui/Item_Head_PigFemale_Pink.png",
    pig_female_black       = "media/ui/Item_Head_PigFemale_Black.png",
    pig_male_pink          = "media/ui/Item_Head_PigMale_Pink.png",
    pig_male_black         = "media/ui/Item_Head_PigMale_Black.png",
    pig_piglet_pink        = "media/ui/Item_Head_PigPiglet_Pink.png",
    pig_piglet_black       = "media/ui/Item_Head_PigPiglet_Black.png",

    -- Sheep — head variants
    sheep_white            = "media/ui/Item_Head_Sheep_White.png",
    sheep_black            = "media/ui/Item_Head_Sheep_Black.png",
    sheep_lamb_white       = "media/ui/Item_Head_SheepLamb_White.png",
    sheep_lamb_black       = "media/ui/Item_Head_SheepLamb_Black.png",

    -- Turkey
    turkey_tom             = "media/ui/Item_Head_Turkey.png",
    turkey_hen             = "media/ui/Item_Head_Turkey.png",    -- same icon, no hen variant
    turkey_poult           = "media/ui/Item_Head_Turkey_Poult.png",

    -- Rabbit — head variants
    rabbit_brown           = "media/ui/Item_Head_Rabbit_Brown.png",
    rabbit_grey            = "media/ui/Item_Head_Rabbit_Grey.png",
    rabbit_kit_brown       = "media/ui/Item_Head_Rabbit_Brown_Kit.png",
    rabbit_kit_grey        = "media/ui/Item_Head_Rabbit_Grey_Kit.png",

    -- Raccoon
    raccoon                = "media/ui/Item_Head_Raccoon.png",

    -- Deer — head variants
    deer_male              = "media/ui/Item_Head_DeerMale.png",
    deer_female            = "media/ui/Item_Head_DeerFemale.png",
    deer_fawn              = "media/ui/Item_Head_DeerFawn.png",

    -- Fallback
    _default               = "media/ui/Zone_Animal_On.png",
}

AD.PORTRAITS = PORTRAITS

--- Resolve portrait texture path for a given animal.
-- Tries breed-specific → species+sex → species fallback → default.
function AD.resolvePortrait(animal)
    if not animal then return PORTRAITS._default end

    local atype  = string.lower(AD.getAnimalType(animal))
    local breed  = string.lower(AD.getBreedName(animal)):gsub("%s+", "")
    local female = AD.isFemale(animal)
    local baby   = AD.isBaby(animal)

    -- Chicken special handling (full body sprites, sex-specific)
    if atype == "chicken" or atype == "rooster" or atype == "hen" then
        if baby then return PORTRAITS.chicken_chick or PORTRAITS._default end
        if female then
            if breed:find("white") then return PORTRAITS.chicken_hen_white end
            return PORTRAITS.chicken_hen_brown
        else
            if breed:find("white") then return PORTRAITS.chicken_rooster_white end
            return PORTRAITS.chicken_rooster_brown
        end
    end

    -- Cow
    if atype == "cow" or atype == "bull" or atype == "calf" then
        local color = "brown"
        if breed:find("black") and breed:find("white") then color = "blackwhite"
        elseif breed:find("black") then color = "black" end
        if baby then return PORTRAITS["cow_calf_" .. color] or PORTRAITS.cow_calf_brown end
        if female then return PORTRAITS["cow_female_" .. color] or PORTRAITS.cow_female_brown end
        return PORTRAITS["cow_male_" .. color] or PORTRAITS.cow_male_brown
    end

    -- Pig
    if atype == "pig" or atype == "sow" or atype == "boar" or atype == "piglet" then
        local color = breed:find("black") and "black" or "pink"
        if baby then return PORTRAITS["pig_piglet_" .. color] or PORTRAITS.pig_piglet_pink end
        if female then return PORTRAITS["pig_female_" .. color] or PORTRAITS.pig_female_pink end
        return PORTRAITS["pig_male_" .. color] or PORTRAITS.pig_male_pink
    end

    -- Sheep
    if atype == "sheep" or atype == "ewe" or atype == "ram" or atype == "lamb" then
        local color = breed:find("suffolk") and "black" or (breed:find("black") and "black" or "white")
        if baby then return PORTRAITS["sheep_lamb_" .. color] or PORTRAITS.sheep_lamb_white end
        return PORTRAITS["sheep_" .. color] or PORTRAITS.sheep_white
    end

    -- Turkey
    if atype == "turkey" or atype == "turkeyhen" then
        if baby then return PORTRAITS.turkey_poult end
        return PORTRAITS.turkey_tom
    end

    -- Rabbit
    if atype == "rabbit" then
        local color = breed:find("grey") and "grey" or "brown"
        if baby then return PORTRAITS["rabbit_kit_" .. color] or PORTRAITS.rabbit_kit_brown end
        return PORTRAITS["rabbit_" .. color] or PORTRAITS.rabbit_brown
    end

    -- Raccoon
    if atype == "raccoon" then return PORTRAITS.raccoon end

    -- Deer
    if atype == "deer" or atype == "stag" or atype == "doe" or atype == "fawn" then
        if baby then return PORTRAITS.deer_fawn end
        if female then return PORTRAITS.deer_female end
        return PORTRAITS.deer_male
    end

    return PORTRAITS._default
end

-- ============================================================================
-- ACTION ICONS — constant paths for detail card action strip
-- ============================================================================

AD.ACTION_ICONS = {
    grab  = "media/ui/AnimalActions_Grab.png",
    kill  = "media/ui/AnimalActions_Kill.png",
    milk  = "media/ui/AnimalActions_Milk.png",
    pet   = "media/ui/AnimalActions_Pet.png",
    rope  = "media/ui/AnimalActions_Rope.png",
    shear = "media/ui/AnimalActions_Shear.png",
    stats = "media/ui/AnimalActions_Stats.png",
}

-- ============================================================================
-- INFRASTRUCTURE ICONS
-- ============================================================================

AD.BUILD_ICONS = {
    hook   = "media/ui/Build_ButcherHook.png",
    trough = "media/ui/Build_TroughMetal.png",
    coop   = "media/ui/Build_Coop.png",
}

-- ============================================================================
-- ZONE ICON
-- ============================================================================

AD.ZONE_ICON_ON  = "media/ui/Zone_Animal_On.png"
AD.ZONE_ICON_OFF = "media/ui/Zone_Animal_Off.png"
