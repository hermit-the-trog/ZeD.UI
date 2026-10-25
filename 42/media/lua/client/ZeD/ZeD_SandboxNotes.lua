-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SandboxNotes.lua
-- ============================================================================
-- SANDBOX OPTIONS IN GAME: what changing each setting does to a running save
-- (director, Oct 24 2026; mockup zed_sandbox_ingame_v1; ZeD_SandboxInGame.lua)
--
-- For every vanilla sandbox setting:
--   WHEN  "now"  takes effect as soon as it is applied
--         "new"  only places, containers, cars, zombies and animals made or first
--                seen after the change
--         "chr"  only a character made after the change
--         "load" the game reads it only when the save loads (its zombie population
--                manager, the world map's "all known"): seen after the next load
--         "fix"  used once, when the world was made (or never in single player):
--                locked in the window
--   RISK  "care" can make the save harder or stranger; setting it back undoes it
--         "undo" deletes or changes something for good
-- A setting not named here (another mod's) is "now" with no risk.
--
-- The words: UI_ZeD_SbxSave_<name> (on this save) and UI_ZeD_SbxTip_<name> (a tip),
-- the name's dots as underscores; a setting without its own words takes its
-- section's (UI_ZeD_SbxSecSave_ / UI_ZeD_SbxSecTip_ + the section's raw title),
-- then the WHEN's (UI_ZeD_SbxWhen_<when>). Checked against the game's code; the
-- notes behind each are in SANDBOX_INGAME_SPEC.md.
-- ============================================================================

ZeD = ZeD or {}
ZeD.SandboxNotes = ZeD.SandboxNotes or {}
local N = ZeD.SandboxNotes

N.WHEN = {}
N.RISK = {}

local function set(t, v, names) for _, n in ipairs(names) do t[n] = v end end

-- BEGIN GENERATED (scratchpad integrate.py from the Oct 24 2026 code reading; SANDBOX_INGAME_SPEC.md section 6)
set(N.WHEN, "fix", {
    "StartMonth", "StartDay", "StartTime", "ZombieConfig.ZombiesCountBeforeDelete", "WaterShut", "ElecShut",
    "Basement.SpawnFrequency", "ErosionSpeed", "StartYear" })
set(N.WHEN, "chr", {
    "ZombieLore.PlayerSpawnZombieRemoval", "StarterKit", "CharacterFreePoints", "AllClothesUnlocked",
    "NegativeTraitsPenalty" })
set(N.WHEN, "new", {
    "ZombieLore.Toughness", "MaximumLooted", "DaysUntilMaximumLooted", "RuralLooted", "MaximumDiminishedLoot",
    "DaysUntilMaximumDiminishedLoot", "MaximumLootedBuildingRooms", "FoodLootNew", "CannedFoodLootNew",
    "WeaponLootNew", "RangedWeaponLootNew", "AmmoLootNew", "MedicalLootNew", "SurvivalGearsLootNew",
    "MechanicsLootNew", "SkillBookLoot", "RecipeResourceLoot", "LiteratureLootNew", "ClothingLootNew",
    "ContainerLootNew", "KeyLootNew", "MediaLootNew", "MementoLootNew", "CookwareLootNew", "MaterialLootNew",
    "FarmingLootNew", "ToolLootNew", "OtherLootNew", "GeneratorSpawning", "LootItemRemovalList", "RemoveStoryLoot",
    "RemoveZombieLoot", "RollsMultiplier", "ZombiePopLootEffect", "AlarmDecay", "Alarm", "LockedHouses",
    "GeneratorTileRange", "GeneratorVerticalPowerRange", "FuelStationGasMin", "FuelStationGasMax",
    "FuelStationGasEmptyChance", "MaximumRatIndex", "DaysUntilMaximumRatIndex", "ClayLakeChance", "ClayRiverChance",
    "SurvivorHouseChance", "VehicleStoryChance", "ZoneStoryChance", "AnnotatedMapChance", "ConstructionBonusPoints",
    "NoBlackClothes", "EnableVehicles", "RecentlySurvivorVehicles", "CarSpawnRate", "ChanceHasGas", "InitialGas",
    "LockedCar", "CarGeneralCondition", "TrafficJam", "CarAlarm", "AnimalEggHatch", "AnimalRanchChance",
    "AnimalTrackChance", "AnimalPathChance" })
set(N.WHEN, "load", {
    "Zombies", "Distribution", "ZombieVoronoiNoise", "ZombieRespawn", "ZombieMigrate",
    "ZombieLore.ChanceOfAttachedWeapon", "ZombieConfig.PopulationMultiplier",
    "ZombieConfig.PopulationStartMultiplier", "ZombieConfig.PopulationPeakMultiplier",
    "ZombieConfig.PopulationPeakDay", "ZombieConfig.RespawnHours", "ZombieConfig.RespawnUnseenHours",
    "ZombieConfig.RespawnMultiplier", "ZombieConfig.RedistributeHours", "ZombieConfig.FollowSoundDistance",
    "Temperature", "Map.MapAllKnown" })
set(N.RISK, "care", {
    "DayLength", "TimeSinceApo", "Zombies", "ZombieRespawn", "ZombieConfig.PopulationMultiplier",
    "ZombieConfig.PopulationStartMultiplier", "ZombieConfig.PopulationPeakMultiplier",
    "ZombieConfig.PopulationPeakDay", "ZombieConfig.RespawnHours", "ZombieConfig.RespawnUnseenHours",
    "ZombieConfig.RespawnMultiplier", "HoursForLootRespawn", "WaterShutModifier", "ElecShutModifier",
    "KillInsideCrops", "PlantGrowingSeasons" })
set(N.RISK, "undo", {
    "DaysForRottenFoodRemoval", "WorldItemRemovalList", "HoursForWorldItemRemoval", "ItemRemovalListBlacklistToggle",
    "ErosionDays", "HoursForCorpseRemoval", "Map.MapAllKnown" })
-- END GENERATED

-- the window's own names for two pairs vanilla labels alike ("Water Shutoff" twice)
N.LABEL = {
    WaterShutModifier = "UI_ZeD_Sbx_LabelWaterDay", ElecShutModifier = "UI_ZeD_Sbx_LabelPowerDay",
    WaterShut = "UI_ZeD_Sbx_LabelWaterRange", ElecShut = "UI_ZeD_Sbx_LabelPowerRange",
}

function N.when(name) return N.WHEN[name] or "now" end
function N.risk(name) return N.RISK[name] or "" end

local function key(name) return (tostring(name):gsub("%.", "_")) end
local function tr(k) local t = ZeD.tr(k); if t == k then return nil end; return t end

-- this setting's words for "on this save", and its tip (nil when none)
function N.save(name, section)
    return tr("UI_ZeD_SbxSave_" .. key(name)) or (section and tr("UI_ZeD_SbxSecSave_" .. key(section)))
        or ZeD.tr("UI_ZeD_SbxWhen_" .. N.when(name))
end
function N.tip(name, section)
    return tr("UI_ZeD_SbxTip_" .. key(name)) or (section and tr("UI_ZeD_SbxSecTip_" .. key(section))) or nil
end
