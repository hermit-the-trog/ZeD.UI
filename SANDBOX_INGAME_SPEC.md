# SANDBOX_INGAME_SPEC: this save's sandbox settings, changed in game

**Status:** APPROVED and built (director, Oct 24 2026: "Yes, build the sandbox window as the mockup shows: pause window line, default off, single player first."). Mockup `ZeDUI/mockups/zed_sandbox_ingame_v1.html`.
**Asked for (director, Oct 24 2026):** "add our own midgame sandbox settings option, default off, setting in the options menu. If the settings can be verbose and show what does what, what might have negative affects on a save and tips."
**Replaces:** Change Sandbox Options (by Star, Workshop 2894296454), credited in `ZeDUI/workshop/steam_threads/6_credits.txt`.
**Code:** `42/media/lua/client/ZeD/ZeD_SandboxInGame.lua` (the window), `ZeD_SandboxNotes.lua` (when and risk per setting), the pause window's line in `ZeD_MainMenu.lua`, the switch in `Settings.lua` and `ZeD_MainMenuOptionGroups.lua`. HOOK_MAP: "Sandbox options in game".

## 1. How it opens

- Options, ZeD setup, **Sandbox**: "Sandbox options in game", an on/off switch, **off** by default.
- With it on, the pause window gets a **Sandbox options** line under Options (vanilla's own words, `UI_optionscreen_SandboxOptions`). The game stays paused while the window is open.
- **Single player only:** no line when `isClient()`. On a server, vanilla's admin panel has its own editor (`ISServerSandboxOptionsUI`); ZeD's for admins is a later step (it would send with `SandboxOptions:sendToServer()`; not tested).

## 2. The window

The in-game Options window's layout (pages, Find, rows, the action strip), 1060 x 800 design units, centred over the paused game.

- **Pages:** vanilla's (`ServerSettingsScreen.getSandboxSettingsTable()`, the table its admin editor uses; other mods' settings arrive on their own pages), then **Changed (n)** and **History**. A dot beside a page with changes. Find searches every page's names and help.
- **Rows:** vanilla's labels and controls (list, tick box, a number or text edited in its row). A changed row has the accent dot and "was X" under its name. Two pairs vanilla labels alike are renamed: Water Shutoff (day) / (range), Electricity Shutoff (day) / (range).
- **Tags** at the right of each row (Visual Catalog A06 badges):
  - WHEN: **Now** (positive), **New places** (info), **New characters** (info), **Next load** (accent: the game reads it only when the save loads; its zombie population manager takes the zombie numbers at load and Lua cannot ask it again), **Fixed** (neutral; the row is greyed and locked). Next load was added in the build, from the code reading (17 settings); the mockup had four.
  - RISK: **Careful** (warning: harder or stranger, setting it back undoes it), **Can't undo** (danger: deletes or changes something for good).
- **World page:** a first line with the world's day in the count the shut-offs use, and whether water and power are on for good, on until day N, or off since day N (after Apply, when those are changed). The game keeps a supply on while the world's age is under its day: -1 is off from the start, 2147483647 (the game's Never) on for good.
- **Help band**, three parts: **What it does** (vanilla's tooltip, its Default and Range), **On this save | WHEN** (the risk in its colour, then what changing it does to this save, then "This save: X | after Apply: Y"), **Tip** (only when there is one). It follows the pointer and keeps the last setting.
- **Strip:** Close | Undo changes, Apply. Apply asks first and shows the Changed page: "Apply 3 changes to this save? Can't be undone: 1." (Apply turns red when any can't be undone). Close with changes asks: Discard or Apply. After Apply: "Applied 3 changes. The game keeps them when it next saves."
- **History** (global ModData `ZeD_SandboxHistory`, kept in the save, the latest 60 applies): each apply with its in-game date, every change "from > to" with **Put back**, which sets the row back and waits on the Changed page for Apply.
- **Controller:** LB / RB pages, D-pad rows, left / right change a list, A opens a list or a number, X Undo changes (asks), Y Apply (asks), B Close (asks if changed). Escape out of the game drops changes not applied, as Options does.

## 3. What Apply does (checked in the game's code, javap of projectzomboid.jar)

1. Each changed option: `getSandboxOptions():getOptionByName(name):parse(value)` (only the changed ones).
2. `getSandboxOptions():toLua()`: every value into `SandboxVars` (Change Sandbox Options wrote `SandboxVars` by hand).
3. Day Length changed: `getGameTime():setMinutesPerDay(getSandboxOptions():getDayLengthMinutes())`. Never `applySettings()`: it also sets the start year, month, day and time (only multiplayer join and server code call it).
4. `IsoWorld.parseDistributions()` and `StoryClutter.Init()`, as vanilla's admin editor does after an apply (the loot removal list, mods' distribution code), and `ItemPickerJava.InitSandboxLootSettings()`: the Loot Rarity numbers are copied into the loot picker's own fields once, at world load, so without it they would wait for the next load.
5. The save keeps the change: `GameWindow.save` writes `SandboxOptions.instance` to the save's `map_sand.bin` every time the game saves; loading reads it back and calls `toLua()`.

Facts behind the risk notes:
- Water: `IsoObject` compares `GameTime.getWorldAgeDaysSinceBegin()` with `getWaterShutModifier()` every time; power the same (`IsoLightSwitch`, `ItemContainer`, `Food`). Moving the day turns the supply on or off at once.
- `getWorldAgeDaysSinceBegin()` adds `getTimeSinceApo()`: raising Months since the Apocalypse ages the world at once.
- Water Shutoff (range) and Electricity Shutoff (range) only roll the day when the world is made (`randomWaterShut`, `randomElectricityShut`); afterwards they do nothing (Fixed).
- The world item removal list is checked by `IsoGridSquare` for loose items (on the ground or on a surface) as a square loads; items in containers and bags are not touched.
- The zombie population numbers (Zombie Count, Distribution, Respawn, Migration, the Advanced Zombie Options numbers) reach the native population manager at world load (`MapCollisionData.init`, `onConfigReloaded`); only a server's /reloadoptions calls it again. These are tagged Next load.
- Erosion Days is read every ten game minutes and works growth out from a counter that does not match the world's growth, so changing it can drop or jump the growth; it is Can't undo. Erosion Speed is read only when the save has no erosion.ini (a new world): Fixed.
- All Known On Start marks the whole map known when the map is first used after a load and saves it that way: turning it off later does not forget the map (Can't undo, Next load).
- Time Before Corpse Removal deletes zombie corpses older than the hours set, with what they carry (Can't undo).

## 4. When and risk for every setting

`ZeD_SandboxNotes.lua` holds WHEN and RISK for each vanilla setting; the words are `UI_ZeD_SbxSave_<name>` and `UI_ZeD_SbxTip_<name>` in UI.json (dots as underscores), then a section's (`UI_ZeD_SbxSecSave_<section>`), then the WHEN's generic line (`UI_ZeD_SbxWhen_<when>`). A setting another mod adds is Now, with no risk, and shows its own tooltip. The evidence behind each classification is listed in section 6.

## 5. QA

`ZeDUI/tools/qa/zedqa_sandbox_ig.lua` (tag `sbx`, in regression.txt): the line only with the switch on; the window, its pages and rows; a Fixed setting does not change; Zombie Count sets Population Multiplier; Undo changes; Apply asks first; four harmless changes applied (the options, SandboxVars, the clock's day length, History); Put back and Apply return every value; the controller's prompts. It puts back the settings, the switch and History. `zedqa_sandbox_dump.lua` writes every setting of the running save to `Lua/ZeD_sandbox_dump.json`.

## 6. Per-setting evidence

When and risk for each setting, and what in the game's code backs it (Oct 24 2026). Unverified ones are worded with "may" or left to the generic line.

| Setting | Page | When | Risk | Checked | Evidence |
|---|---|---|---|---|---|
| Day Length (in real time) (`DayLength`) | Time | now | care | yes | GameTime.update and getDeltaMinutesPerDay read GameTime.minutesPerDay (BodyDamage, IsoGameCharacter, IsoPlayer, Food). SandboxOptions.applySettings and load() copy dayLength into it; set() alone does not, so the window must call setMinutesPerDay. GameTime.load never overwrites it. |
| Months since the Apocalypse (`TimeSinceApo`) | Time | now | care | yes | GameTime.getWorldAgeDaysSinceBegin adds (TimeSinceApo-1)*30 live; IsoObject.isWaterInfinite, IsoLightSwitch, ItemContainer, Food, SandboxOptions.getCurrentLootedChance/getCurrentRatIndex and IsoChunk.doLoadGridsquare (corpses) and Vehicles.Create.Battery read it. ErosionMain.initConfig and ZomboidRadio.Init use it for new worlds only. |
| Start Month (`StartMonth`) | Time | fix | - | yes | GameTime.init sets the date from the Start values, GameTime.load then restores the saved date; applySettings is the only other caller. |
| Start Day (`StartDay`) | Time | fix | - | yes | GameTime.init sets the date from the Start values, GameTime.load then restores the saved date; applySettings is the only other caller. |
| Start Hour (`StartTime`) | Time | fix | - | yes | GameTime.init sets timeOfDay from startTimeOfDay, GameTime.load then restores the saved time of day. |
| Zombie Count (`Zombies`) | Zombie | load | care | yes | MapCollisionData.init pushes SandboxOptions.Zombies to the native layer at load (no later call); IsoWorld.getZombiesDisabled, VirtualZombieManager.getZombieCountForRoom and RandomizedBuildingBase.addZombies read it live. |
| Zombie Distribution (`Distribution`) | Zombie | load | - | yes | MapCollisionData.init pushes it to native at load; IsoMetaChunk.getZombieIntensity reads it live. |
| Voronoi Noise (`ZombieVoronoiNoise`) | Zombie | load | - | yes | ZombieVoronoi.evaluateCellCutoff is called from IsoMetaGrid$MetaGridLoaderThread (map load); no other game reader. |
| Zombie Respawn (`ZombieRespawn`) | Zombie | load | care | yes | No Java reader for zombieRespawn; the effect is ZombieConfig.RespawnHours/UnseenHours/Multiplier, pushed to native by ZombiePopulationManager.onConfigReloaded (called from init and the server /reloadoptions command only). |
| Zombie Migration (`ZombieMigrate`) | Zombie | load | - | yes | No Java reader for zombieMigrate; ZombieConfig.RedistributeHours is pushed to native at init only. |
| Speed (`ZombieLore.Speed`) | Zombie | now | - | yes | IsoZombie.DoZombieSpeeds/determineZombieSpeed run when a zombie is made or loaded (constructor, load, resetForReuse, toggleCrawling, makeInactive). |
| Random Sprinter Amount (`ZombieLore.SprinterPercentage`) | Zombie | now | - | yes | IsoZombie.determineZombieSpeed, same call sites as Speed. |
| Strength (`ZombieLore.Strength`) | Zombie | now | - | yes | BodyDamage.AddRandomDamageFromZombie, IsoGameCharacter.testDefense and IsoDoor.Thump read it live; IsoZombie.DoZombieStats reads it at make or load. |
| Toughness (`ZombieLore.Toughness`) | Zombie | new | - | yes | IsoZombie.resetForReuse, VirtualZombieManager.createZombieOutsideWorld and IsoDeadBody.reanimate read it; IsoZombie.DoZombieStats (run on load) does not. |
| Transmission (`ZombieLore.Transmission`) | Zombie | now | - | yes | BodyPart.SetBitten/generateZombieInfection and IsoGameCharacter.shouldBecomeZombieAfterDeath read it when the event happens. |
| Infection Mortality (`ZombieLore.Mortality`) | Zombie | now | - | yes | BodyDamage.Update reads it every update; BodyDamage.pickMortalityDuration reads it at infection. |
| Reanimate Time (`ZombieLore.Reanimate`) | Zombie | now | - | yes | IsoDeadBody.getReanimateDelay reads it live. |
| Cognition (`ZombieLore.Cognition`) | Zombie | now | - | yes | IsoZombie.DoZombieStats (constructor, load, resetForReuse). |
| Random Door Opening Amount (`ZombieLore.DoorOpeningPercentage`) | Zombie | now | - | yes | IsoZombie.DoZombieStats (constructor, load, resetForReuse). |
| Crawl Under Vehicle (`ZombieLore.CrawlUnderVehicle`) | Zombie | now | - | yes | IsoZombie.DoZombieStats calls initCanCrawlUnderVehicle. |
| Memory (`ZombieLore.Memory`) | Zombie | now | - | yes | IsoZombie.DoZombieStats and getSandboxMemoryDuration read it. |
| Sight (`ZombieLore.Sight`) | Zombie | now | - | yes | IsoZombie.DoZombieStats (make or load) and getVisionRadiusAdjusted (live) read it. |
| Hearing (`ZombieLore.Hearing`) | Zombie | now | - | yes | IsoZombie.DoZombieStats, RespondToSound, WorldSoundManager.addSound and ZombiePopulationManager.addWorldSound read it. |
| New Stealth System (`ZombieLore.SpottedLogic`) | Zombie | now | - | yes | IsoZombie.spotted reads it live. |
| Environmental Attacks (`ZombieLore.ThumpNoChasing`) | Zombie | now | - | yes | IsoZombie.collideWith and tryThump read it live. |
| Damage Construction (`ZombieLore.ThumpOnConstruction`) | Zombie | now | - | yes | IsoThumpable.Thump, IsoCompost.Thump and IsoZombie.collideWith read it live. |
| Day/Night Zombie Speed Effect (`ZombieLore.ActiveOnly`) | Zombie | now | - | yes | GameTime.isZombieActivityPhase reads it live. |
| Zombie House Alarm Triggering (`ZombieLore.TriggerHouseAlarm`) | Zombie | now | - | yes | IsoWindow.damage and ToggleWindow read it live. |
| Drag Down (`ZombieLore.ZombiesDragDown`) | Zombie | now | - | yes | BodyDamage.AddRandomDamageFromZombie reads it live. |
| Crawlers Drag Down (`ZombieLore.ZombiesCrawlersDragDown`) | Zombie | now | - | yes | BodyDamage.AddRandomDamageFromZombie reads it live. |
| Zombie Lunge (`ZombieLore.ZombiesFenceLunge`) | Zombie | now | - | yes | IsoZombie.shouldDoFenceLunge reads it live. |
| Fake Dead Zombie Reanimation (`ZombieLore.DisableFakeDead`) | Zombie | now | - | no | IsoZombie.isFakeDead and IsoDeadBody.setFakeDead/updateFakeDead/updateRotting read it; not read in detail. |
| Zombie Armor Factor (`ZombieLore.ZombiesArmorFactor`) | Zombie | now | - | yes | CombatManager.calculateTotalDefense reads it live. |
| Maximum Zombie Armor Defense (`ZombieLore.ZombiesMaxDefense`) | Zombie | now | - | yes | CombatManager.calculateTotalDefense reads it live. |
| Chance Of Attached Weapon (`ZombieLore.ChanceOfAttachedWeapon`) | Zombie | load | - | yes | AttachedWeaponDefinitions.init (via checkDirty) copies it into a cached field; dirty is set true only by the constructor and LuaManager (Lua reload). |
| Zombie Fall Damage Multiplier (`ZombieLore.ZombiesFallDamage`) | Zombie | now | - | yes | IsoZombie.handleLandingImpact reads it live. |
| Player Spawn Area (`ZombieLore.PlayerSpawnZombieRemoval`) | Zombie | chr | - | yes | PlayerSpawns$PlayerSpawn.allowZombie reads it live, but entries are removed after 10 seconds and are added only when a player spawns (IsoWorld.init new-character branch, AddCoopPlayer). |
| Population Multiplier (`ZombieConfig.PopulationMultiplier`) | Zombie | load | care | yes | ZombiePopulationManager.onConfigReloaded pushes it to native; callers are init and the server /reloadoptions command only. ItemPickerJava.getBaseChanceMultiplier also reads it live. |
| Population Start Multiplier (`ZombieConfig.PopulationStartMultiplier`) | Zombie | load | care | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Population Peak Multiplier (`ZombieConfig.PopulationPeakMultiplier`) | Zombie | load | care | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Population Peak Day (`ZombieConfig.PopulationPeakDay`) | Zombie | load | care | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Respawn Hours (`ZombieConfig.RespawnHours`) | Zombie | load | care | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Respawn Unseen Hours (`ZombieConfig.RespawnUnseenHours`) | Zombie | load | care | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Respawn Multiplier (`ZombieConfig.RespawnMultiplier`) | Zombie | load | care | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Redistribute Hours (`ZombieConfig.RedistributeHours`) | Zombie | load | - | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Follow Sound Distance (`ZombieConfig.FollowSoundDistance`) | Zombie | load | - | yes | ZombiePopulationManager.onConfigReloaded (init and /reloadoptions only). |
| Rally Group Size (`ZombieConfig.RallyGroupSize`) | Zombie | now | - | yes | ZombieGroupManager.findNearestGroup/preupdate/shouldBeInGroup read it live. |
| Rally Group Size Variance (`ZombieConfig.RallyGroupSizeVariance`) | Zombie | now | - | yes | ZombieGroup constructor reads it. |
| Rally Travel Distance (`ZombieConfig.RallyTravelDistance`) | Zombie | now | - | yes | ZombieGroupManager.findNearestGroup and ZombieGroup.update read it live. |
| Rally Group Separation (`ZombieConfig.RallyGroupSeparation`) | Zombie | now | - | yes | ZombieGroupManager.update reads it live. |
| Rally Group Radius (`ZombieConfig.RallyGroupRadius`) | Zombie | now | - | yes | ZombieGroupManager.update reads it live. |
| Zombie count before deletion (`ZombieConfig.ZombiesCountBeforeDelete`) | Zombie | fix | - | yes | ZombieCountOptimiser.prepareZombiesForDeletion returns at once when GameServer.udpEngine is null; it is its only reader. |
| Hours for Loot Respawn (`HoursForLootRespawn`) | Loot | now | care | yes | LootRespawn.update/checkChunk read the interval live; respawnInContainer calls ItemPickerJava.fillContainer on containers under the item limit and adds to the existing items; respawnInChunk honours Construction Prevents and Seen Hours. |
| Loot Seen Prevent Hours (`SeenHoursPreventLootRespawn`) | Loot | now | - | yes | LootRespawn.respawnInChunk reads it live. |
| Max Items For Loot Respawn (`MaxItemsForLootRespawn`) | Loot | now | - | yes | LootRespawn.respawnInContainer reads it live. |
| Construction Prevents Loot Respawn (`ConstructionPreventsLootRespawn`) | Loot | now | - | yes | LootRespawn.respawnInChunk reads it live together with Zone.haveConstruction. |
| Maximum Looted Building Chance (`MaximumLooted`) | Loot | new | - | yes | SandboxOptions.getCurrentLootedChance is read by RandomizedBuildingBase.getChance and RBLooted/RBShopLooted/RBTrashed.isValid when a building is first set up. |
| Days Until Max Looted Building Chance (`DaysUntilMaximumLooted`) | Loot | new | - | yes | SandboxOptions.getCurrentLootedChance uses GameTime.getWorldAgeDaysSinceBegin; read when a building is first set up. |
| Rural Building Looted Chance Multiplier (`RuralLooted`) | Loot | new | - | yes | SandboxOptions.getCurrentLootedChance (building first set up). |
| Maximum Diminished Loot Percentage (`MaximumDiminishedLoot`) | Loot | new | - | yes | SandboxOptions.getCurrentLootMultiplier is read by ItemPickerJava.getActualSpawnChance when a container is filled. |
| Days Until Maximum Diminished Loot (`DaysUntilMaximumDiminishedLoot`) | Loot | new | - | yes | SandboxOptions.getCurrentDiminishedLootPercentage uses GameTime.getWorldAgeDaysSinceBegin; read at container fill. |
| Maximum Looted Building Rooms (`MaximumLootedBuildingRooms`) | Loot | new | - | yes | RBLooted, RBShopLooted and RBTrashed.isValid read it. |
| Perishable Food (`FoodLootNew`) | Loot | new | - | yes | ItemPickerJava.InitSandboxLootSettings copies it into a static field read by getLootModifierFromType when a container is filled. Only IsoWorld (world load, parseDistributions) calls the init, so the window must call it after set(). |
| Non-Perishable Food (`CannedFoodLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Melee Weapons (`WeaponLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Ranged Weapons (`RangedWeaponLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Ammo (`AmmoLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Medical (`MedicalLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Survival Essentials (`SurvivalGearsLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Mechanics (`MechanicsLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Skill Books (`SkillBookLoot`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Recipe Resources (`RecipeResourceLoot`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Other Literature (`LiteratureLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Clothing (`ClothingLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Bags (`ContainerLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Keys (`KeyLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. VirtualZombieManager and BaseVehicle also read the option live for key spawns. |
| Media (`MediaLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Mementos (`MementoLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Cooking (`CookwareLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Material (`MaterialLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Farming (`FarmingLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Tools (`ToolLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Other (`OtherLootNew`) | Loot | new | - | yes | Same as FoodLootNew: cached by ItemPickerJava.InitSandboxLootSettings. |
| Generators (`GeneratorSpawning`) | Loot | new | - | yes | ItemPickerJava.getLootModifierFromType and IsoCell.ProcessSpottedRooms read it live when loot is rolled or a room is first seen. |
| Loot Item Removal List (`LootItemRemovalList`) | Loot | new | - | yes | SandboxOptions.lootItemRemovalListContains rebuilds its set when the string changes; ItemPickerJava.getLootModifier reads it at roll time. |
| Remove Unwanted Story Loot (`RemoveStoryLoot`) | Loot | new | - | yes | IsoChunk.addItemOnGround and RandomizedWorldBase/RandomizedBuildingBase item spawners read it live. |
| Remove Unwanted Zombie Loot (`RemoveZombieLoot`) | Loot | new | - | yes | AttachedWeaponDefinitions.addAttachedWeapon reads it live when a zombie is made. |
| Rolls Multiplier [!] (`RollsMultiplier`) | Loot | new | - | yes | ItemPickerJava.doRollItemInternal and rollContainerItemInternal read it live. |
| Zombie Population Loot Effect (`ZombiePopLootEffect`) | Loot | new | - | yes | ItemPickerJava.getZombieDensityFactor reads it live at container fill. |
| Water Shutoff (day) (`WaterShutModifier`) | World | now | care | yes | IsoObject.isWaterInfinite compares GameTime.getWorldAgeDaysSinceBegin with getWaterShutModifier on every query; SandboxOptions.randomWaterShut returns -1 for Instant and 2147483647 for Never. |
| Electricity Shutoff (day) (`ElecShutModifier`) | World | now | care | yes | SandboxOptions.doesPowerGridExist (IsoWorld.getWorldAgeDays vs getElecShutModifier) feeds IsoGridSquare.hasGridPower and the ambient power update; Food.updateAge, ItemContainer.isFridgeOrFreezerWarming and IsoLightSwitch.update read the modifier live; randomElectricityShut returns -1 for Instant and 2147483647 for Never. |
| Water Shutoff (range) (`WaterShut`) | World | fix | - | yes | Field waterShut has no reader; only SandboxOptions.randomWaterShut uses it, called from MainScreen.lua at new game. |
| Electricity Shutoff (range) (`ElecShut`) | World | fix | - | yes | Field elecShut has no reader; only SandboxOptions.randomElectricityShut uses it, called from MainScreen.lua at new game. |
| Alarm Battery Decay (`AlarmDecay`) | World | new | - | no | Only IsoMetaGrid.CreateStep2 reads it (randomAlarmDecay) into BuildingDef.alarmDecay, which IsoMetaGrid.savePart writes and load() restores. |
| House Alarms Frequency (`Alarm`) | World | new | - | no | Only IsoMetaGrid.CreateStep2 reads it into BuildingDef.alarmed, which IsoMetaGrid.savePart writes and load() restores. |
| Locked Houses Frequency (`LockedHouses`) | World | new | - | yes | IsoDoor and IsoWindow constructors read it. |
| Fire Spread (`FireSpread`) | World | now | - | yes | IsoFire.Spread and IsoGameCharacter.SpreadFire read it live. |
| Generator Working in Exterior (`AllowExteriorGenerator`) | World | now | - | yes | IsoGridSquare.haveElectricity, IsoObject.getPipedFuelAmount and IsoGenerator.setSurroundingElectricity read it live. |
| Generator tile range (`GeneratorTileRange`) | World | new | - | yes | IsoGenerator constructors call setGeneratorRange, which is its only reader. |
| Generator vertical range (`GeneratorVerticalPowerRange`) | World | new | - | yes | IsoGenerator constructors call setGeneratorRange, which is its only reader. |
| Infinite Gas Pumps (`FuelStationGasInfinite`) | World | now | - | yes | IsoObject.getPipedFuelAmount checks it live before reading the stored amount. |
| Initial Minimum Gas Pump Amount (`FuelStationGasMin`) | World | new | - | no | IsoObject.getPipedFuelAmount rolls the amount only when no stored amount exists; the store step was not traced. |
| Initial Maximum Gas Pump Amount (`FuelStationGasMax`) | World | new | - | no | IsoObject.getPipedFuelAmount rolls the amount only when no stored amount exists; the store step was not traced. |
| Initial Gas Pump Empty Chance (`FuelStationGasEmptyChance`) | World | new | - | no | IsoObject.getPipedFuelAmount rolls the amount only when no stored amount exists; the store step was not traced. |
| Light Bulb Lifespan (`LightBulbLifespan`) | World | now | - | yes | IsoLightSwitch.update reads it live. |
| Food Spoilage (`FoodRotSpeed`) | World | now | - | yes | Food.getFoodRotSpeed reads it live. |
| Refrigeration Effectiveness (`FridgeFactor`) | World | now | - | yes | Food.getFridgeFactor reads it live. |
| Rotten Food Removal (`DaysForRottenFoodRemoval`) | World | now | undo | yes | Food.updateRotting destroys the item when age > offAgeMax + days unless the container parent is an IsoCompost; Food.shouldUpdateInWorld returns true for all food when the value is not -1. |
| World Item Removal List (`WorldItemRemovalList`) | World | now | undo | yes | IsoGridSquare.load removes an IsoWorldInventoryObject with dropTime above -1 once worldAgeHours minus dropTime exceeds the hours, when the type is on the list (or off it, with the toggle). |
| Hours for Removal List (`HoursForWorldItemRemoval`) | World | now | undo | yes | IsoGridSquare.load reads it; the removal path requires the value above 0. |
| Removal List as Whitelist (`ItemRemovalListBlacklistToggle`) | World | now | undo | yes | IsoGridSquare.load inverts the worldItemRemovalListContains test when the toggle is on. |
| Basement Spawn Frequency (`Basement.SpawnFrequency`) | World | fix | - | yes | Field spawnFrequency is referenced only inside SandboxOptions$Basement; no Java class and no vanilla Lua file reads it. |
| Maximum Fire Fuel Hours (`MaximumFireFuelHours`) | World | now | - | yes | camping_fuel.lua reads it when fuel is added. |
| Darkness during night (`NightDarkness`) | Nature | now | - | yes | RenderSettings$PlayerRenderSettings.updateRenderSettings reads it every frame. |
| Temperature (`Temperature`) | Nature | load | - | no | Only ErosionMain.start reads getTemperatureModifier (no other Java reader, no active Lua reader: server/Seasons/season.lua has its events commented out). Could not confirm that weather temperature ignores it. |
| Rain (`Rain`) | Nature | now | - | yes | WeatherPeriod.createWeatherPattern and ClimateValues.updateValues read getRainModifier when weather is planned. |
| Maximum Fog Intensity (`MaxFogIntensity`) | Nature | now | - | yes | IsoWeatherFX.setFogIntensity reads it live. |
| Maximum Rain FX Intensity (`MaxRainFxIntensity`) | Nature | now | - | yes | IsoWeatherFX.setPrecipitationIntensity reads it live. |
| Erosion Speed (`ErosionSpeed`) | Nature | fix | - | yes | ErosionMain.initConfig reads getErosionSpeed only after the early return taken when the save already has a readable erosion.ini; no other reader. |
| Erosion Days (`ErosionDays`) | Nature | now | undo | yes | ErosionMain.mainTimer reads it each call: <0 sets eTicks to 0; >0 sets eTicks = ticks/144/days*100 from a counter that the default branch resets every tickUnit; chunks re-run NatureGeneric.update with the lower stage when the daily epoch changes. |
| Farming Speed (`FarmingSpeedNew`) | Nature | now | - | yes | farming_vegetableconf.calcNextGrowing/calcNextTimeFactor read it when a stage is scheduled. |
| Compost Time (`CompostTime`) | Nature | now | - | yes | IsoCompost.update reads getCompostHours live. |
| Fishing Abundance (`FishAbundance`) | Nature | now | - | yes | FishSchoolManager.getNumberOfFishInPoint reads it live. |
| Nature's Abundance (`NatureAbundance`) | Nature | now | - | yes | forageSystem.lua reads SandboxVars.NatureAbundance when foraging zones are filled. |
| Plant Resilience (`PlantResilience`) | Nature | now | - | yes | SFarmingSystem.lua and SPlantGlobalObject.lua read SandboxVars.PlantResilience on each update. |
| Farming Abundance (`FarmingAmountNew`) | Nature | now | - | no | farming_vegetableconf.getVegetablesNumber assigns the multiplied value to a global (numberOfVeg) but returns the unmultiplied nbOfVegetable; SFarmingSystem.harvest uses the return value. Could not rule out a use elsewhere. |
| Kill Crops Grown Inside (`KillInsideCrops`) | Nature | now | care | yes | SFarmingSystem.changeHealth reads it each health pass and subtracts 1 times the bad multiplier per pass from indoor, non-greenhouse, non-houseplant crops. |
| Plant Growing Seasons (`PlantGrowingSeasons`) | Nature | now | care | yes | SFarmingSystem.changeHealth marks outdoor crops cursed in bad months or winter and subtracts 3 times the bad multiplier in bad months; SPlantGlobalObject reads it for growth. |
| Farms not on Ground Level [!] (`PlaceDirtAboveground`) | Nature | now | - | yes | ISFarmingMenu.lua reads it when the farming menu is built. |
| Snow on Ground (`EnableSnowOnGround`) | Nature | now | - | yes | IsoCell.setSnowTarget and FBORenderCell read it live. |
| Enable 'Tainted Water' tooltip (`EnableTaintedWaterText`) | Nature | now | - | yes | Tooltip and context menu code read it live. |
| Maximum Vermin Index (`MaximumRatIndex`) | Nature | new | - | yes | IsoChunk.doLoadGridsquare/addRatsAfterLoading (new chunks) and RBBasic.initRDSMap (per building) read getCurrentRatIndex. |
| Days Until Maximum Vermin Index (`DaysUntilMaximumRatIndex`) | Nature | new | - | yes | SandboxOptions.getCurrentRatIndex uses GameTime.getWorldAgeDaysSinceBegin; read for new chunks and buildings. |
| Clay chance - Lake (`ClayLakeChance`) | Nature | new | - | yes | server/WorldGen biome rules read Sandbox.ClayLakeChance through ProbaString when a chunk is generated. |
| Clay chance - River (`ClayRiverChance`) | Nature | new | - | yes | server/WorldGen biome rules read Sandbox.ClayRiverChance through ProbaString when a chunk is generated. |
| Helicopter (`Helicopter`) | Meta | now | - | yes | GameTime.update fires the event on helicopterDay1 without reading the option; the option is read only to reschedule (Sometimes, Often) after that day has passed. GameTime.init reads it only for new games. |
| Meta Event (`MetaEvent`) | Meta | now | - | yes | GameTime.update and doMetaEvents read it live. |
| Sleeping Event (`SleepingEvent`) | Meta | now | - | yes | SleepingEvent.setPlayerFallAsleep reads it live. |
| Generator Fuel Consumption (`GeneratorFuelConsumption`) | Meta | now | - | yes | IsoGenerator.update and getBasePowerConsumption read it live. |
| Randomized Building Chance (`SurvivorHouseChance`) | Meta | new | - | yes | RandomizedBuildingBase.ChunkLoaded and RBBasic.randomizeBuilding read it. |
| Randomized Road Stories Chance (`VehicleStoryChance`) | Meta | new | - | yes | RandomizedVehicleStoryBase.doRandomStory reads it. |
| Randomized Zone Stories Chance (`ZoneStoryChance`) | Meta | new | - | yes | RandomizedZoneStoryBase.doRandomStory reads it. |
| Annotated Map Chance (`AnnotatedMapChance`) | Meta | new | - | yes | StashSystem.checkStashItem reads it. |
| Time Before Corpse Removal (`HoursForCorpseRemoval`) | Meta | now | undo | yes | IsoDeadBody.updateBodies returns when the value is 0 or less; otherwise it removes bodies whose age since death passes the value (3 hours more for skeletons) and skips non-zombie bodies unless a server option is on. |
| Decaying Corpse Health Impact (`DecayingCorpseHealthImpact`) | Meta | now | - | yes | BodyDamage.UpdateIllness, Moodle.Update and FliesSound.update read it live. |
| Zombie Health Impact (`ZombieHealthImpact`) | Meta | now | - | yes | CorpseCount.getCorpseCount reads it live. |
| Blood Level (`BloodLevel`) | Meta | now | - | yes | CombatManager.splash and IsoGameCharacter.doDeathSplatterAndSounds read it live. |
| Blood Splat Lifespan Days (`BloodSplatLifespanDays`) | Meta | now | - | yes | IsoChunk.LoadFromDiskOrBufferInternal and IsoObject.load read it. |
| Corpse Maggot Spawn (`MaggotSpawn`) | Meta | now | - | yes | IsoDeadBody.updateRotting reads it live. |
| Media List Meta Knowledge (`MetaKnowledge`) | Meta | now | - | yes | ISLiteratureUI.lua reads it each time the list is drawn. |
| Day / Night Cycle (`DayNightCycle`) | Meta | now | - | yes | GameTime.isEndlessDay/isEndlessNight and ErosionSeason read it live. |
| Climate Cycle (`ClimateCycle`) | Meta | now | - | yes | ClimateManager.updateSandboxOverrides reads it live. |
| Fog Cycle (`FogCycle`) | Meta | now | - | yes | ClimateManager.updateSandboxOverrides reads it live. |
| Zombies To Damage Fences (`ZombieLore.FenceThumpersRequired`) | Meta | now | - | yes | BentFences.getThumpersRequired reads it live. |
| Fence Damage Multiplier (`ZombieLore.FenceDamageMultiplier`) | Meta | now | - | yes | BentFences.getFenceDamageMultiplier reads it live. |
| Allow World Map (`Map.AllowWorldMap`) | Meta | now | - | yes | ISWorldMap.lua reads it when the map is used. |
| Allow Mini-Map (`Map.AllowMiniMap`) | Meta | now | - | yes | ISMiniMap.lua reads it when the mini-map is used. |
| All Known On Start (`Map.MapAllKnown`) | Meta | load | undo | yes | WorldMapVisited.getInstance reads it once when the singleton is made, calls setKnownInCells for the whole map and saves; the singleton is dropped on Reset. |
| Light Needed To Read Map (`Map.MapNeedsLight`) | Meta | now | - | yes | ISWorldMap.lua and ISMiniMap.lua read it when a map is read. |
| Stats Decrease (`StatsDecrease`) | Character | now | - | yes | IsoGameCharacter.updateStats_Awake/updateThirst and IsoPlayer.updateStats_Sleeping read it live. |
| Endurance Regeneration (`EndRegen`) | Character | now | - | yes | IsoPlayer.updateEndurance* read it live. |
| Nutrition System (`Nutrition`) | Character | now | - | yes | Nutrition.update reads it live. |
| Starter Kit (`StarterKit`) | Character | chr | - | yes | shared/Items/SpawnItems.lua reads SandboxVars.StarterKit when a character is created. |
| Free Trait Points (`CharacterFreePoints`) | Character | chr | - | yes | CharacterCreationProfession.lua reads SandboxVars.CharacterFreePoints in the creation screen. |
| Player-built Construction Strength (`ConstructionBonusPoints`) | Character | new | - | yes | ISBuildIsoEntity.lua scales bonusHealth when the object is made; it is the only reader. |
| Injury Severity (`InjurySeverity`) | Character | now | - | yes | BodyPart.generate*/set* and IsoPlayer.applyDamageFromVehicleHit read it when an injury happens. |
| Bone Fracture (`BoneFracture`) | Character | now | - | yes | BodyPart.generateFracture and IsoGameCharacter.handleLandingImpact read it live. |
| Muscle Strain Factor (`MuscleStrainFactor`) | Character | now | - | yes | IsoGameCharacter.add*MuscleStrain read it live. |
| Discomfort Factor (`DiscomfortFactor`) | Character | now | - | yes | Item.getDiscomfortModifier reads it live. |
| Wound Infection Damage Factor (`WoundInfectionFactor`) | Character | now | - | yes | BodyDamage.getGeneralWoundInfectionLevel and Update read it live. |
| Clothing Degradation (`ClothingDegradation`) | Character | now | - | yes | Clothing.getClothingDirtynessIncreaseLevel and BloodClothingType.addBlood/addDirt read it live. |
| No Black Clothes (`NoBlackClothes`) | Character | new | - | yes | OutfitRNG.randomImmutableColor reads it. |
| Rear Vulnerability (`RearVulnerability`) | Character | now | - | yes | BodyDamage.AddRandomDamageFromZombie reads it live. |
| Weapon Multi Hit (`MultiHitZombies`) | Character | now | - | yes | CombatManager.calculateHitInfoList reads it live. |
| Firearms Use Damage Chance (`FirearmUseDamageChance`) | Character | now | - | yes | CombatManager.attackCollisionCheck reads it live. |
| Firearm Noise Multiplier (`FirearmNoiseMultiplier`) | Character | now | - | yes | Only ISReloadWeaponAction.lua (reload noise radius) and a debug panel (FirearmPanel) read it; no Java or Lua code that fires a shot does. |
| Firearm Jam Multiplier (`FirearmJamMultiplier`) | Character | now | - | yes | HandWeapon.checkJam reads it live. |
| Firearm Moodle Multiplier (`FirearmMoodleMultiplier`) | Character | now | - | yes | CombatManager.getMoodlesPenalty reads it live. |
| Firearm Weather Multiplier (`FirearmWeatherMultiplier`) | Character | now | - | yes | CombatManager.getWeatherPenalty reads it live. |
| Firearm Headgear Effect (`FirearmHeadGearEffect`) | Character | now | - | yes | CombatManager.calculateHitChanceData reads it live. |
| Melee Movement Disruption (`AttackBlockMovements`) | Character | now | - | yes | SwipeStatePlayer and PlayerDraggingCorpse.OnAnimEvent_BlockMovement read it live. |
| All Clothing Unlocked (`AllClothesUnlocked`) | Character | chr | - | yes | CharacterCreationMain.lua reads getAllClothesUnlocked in the creation screen. |
| Enable Poisoning (`EnablePoisoning`) | Character | now | - | yes | ISInventoryPaneContextMenu.lua reads SandboxVars.EnablePoisoning when the menu is built. |
| Literature Cooldown Days (`LiteratureCooldown`) | Character | now | - | yes | IsoGameCharacter.isLiteratureRead reads it live. |
| Negative Traits Penalty (`NegativeTraitsPenalty`) | Character | chr | - | yes | CharacterCreationProfession.lua reads it in the creation screen. |
| Minutes Per Skill Book Page (`MinutesPerPage`) | Character | now | - | yes | ISReadABook.new reads it when the action is made. |
| Maximum Dismantling XP Level (`LevelForDismantleXPCutoff`) | Character | now | - | yes | ISMoveableSpriteProps.lua reads it when scrapping. |
| Maximum Media XP Level (`LevelForMediaXPCutoff`) | Character | now | - | yes | ISRadioInteractions.lua reads it when media gives XP. |
| Easy Climbing (`EasyClimbing`) | Character | now | - | yes | ClimbSheetRopeState, ClimbOverWallState and ClimbDownSheetRopeState read it live. |
| See Not Known Recipes (`SeeNotLearntRecipe`) | Character | now | - | yes | IsoGameCharacter.isRecipeKnown and Item.getUsedInRecipes read it live. |
| Global Multiplier (`MultiplierConfig.Global`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Use Global Multiplier (`MultiplierConfig.GlobalToggle`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Fitness Multiplier (`MultiplierConfig.Fitness`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Strength Multiplier (`MultiplierConfig.Strength`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Sprinting Multiplier (`MultiplierConfig.Sprinting`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Lightfooted Multiplier (`MultiplierConfig.Lightfoot`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Nimble Multiplier (`MultiplierConfig.Nimble`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Sneaking Multiplier (`MultiplierConfig.Sneak`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Axe Multiplier (`MultiplierConfig.Axe`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Long Blunt Multiplier (`MultiplierConfig.Blunt`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Short Blunt Multiplier (`MultiplierConfig.SmallBlunt`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Long Blade Multiplier (`MultiplierConfig.LongBlade`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Short Blade Multiplier (`MultiplierConfig.SmallBlade`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Spear Multiplier (`MultiplierConfig.Spear`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Maintenance Multiplier (`MultiplierConfig.Maintenance`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Agriculture Multiplier (`MultiplierConfig.Farming`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Animal Care Multiplier (`MultiplierConfig.Husbandry`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Carpentry Multiplier (`MultiplierConfig.Woodwork`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Carving Multiplier (`MultiplierConfig.Carving`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Cooking Multiplier (`MultiplierConfig.Cooking`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Electrical Multiplier (`MultiplierConfig.Electricity`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| First Aid Multiplier (`MultiplierConfig.Doctor`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Knapping Multiplier (`MultiplierConfig.FlintKnapping`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Masonry Multiplier (`MultiplierConfig.Masonry`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Mechanics Multiplier (`MultiplierConfig.Mechanics`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Blacksmithing Multiplier (`MultiplierConfig.Blacksmith`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Pottery Multiplier (`MultiplierConfig.Pottery`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Tailoring Multiplier (`MultiplierConfig.Tailoring`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Welding Multiplier (`MultiplierConfig.MetalWelding`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Aiming Multiplier (`MultiplierConfig.Aiming`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Reloading Multiplier (`MultiplierConfig.Reloading`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Fishing Multiplier (`MultiplierConfig.Fishing`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Foraging Multiplier (`MultiplierConfig.PlantScavenging`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Tracking Multiplier (`MultiplierConfig.Tracking`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Trapping Multiplier (`MultiplierConfig.Trapping`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Butchering Multiplier (`MultiplierConfig.Butchering`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Glassmaking Multiplier (`MultiplierConfig.Glassmaking`) | Character | now | - | yes | IsoGameCharacter$XP.AddXP reads the global multiplier and toggle, or the skill option, each time XP is added. |
| Vehicles (`EnableVehicles`) | Vehicles | new | - | yes | IsoChunk.AddVehicles runs only for new chunks not yet in VehiclesDB2 (addZombies flag). |
| Easy Use (`VehicleEasyUse`) | Vehicles | now | - | yes | BaseVehicle.tryStartEngine requires a key or hotwire when it is off; trySpawnKey puts the key in the glove box when it is on; Vehicles.lua reads it at car creation. |
| Recent Survivor Vehicles (`RecentlySurvivorVehicles`) | Vehicles | new | - | yes | BaseVehicle.createPhysics reads it only while the created flag is false. |
| Zombie Attraction Multiplier (`ZombieAttractionMultiplier`) | Vehicles | now | - | yes | BaseVehicle.updatePartStats, VehiclePart.repair and Vehicles.lua read it live. |
| Vehicle Spawn Rate (`CarSpawnRate`) | Vehicles | new | - | yes | IsoChunk.AddVehicles and AddVehicles_OnZone run only for new chunks. |
| Chance Has Gas (`ChanceHasGas`) | Vehicles | new | - | yes | Vehicles.lua reads it in the car creation functions. |
| Initial Gas (`InitialGas`) | Vehicles | new | - | yes | Vehicles.lua reads it in the car creation functions. |
| Gas Consumption (`CarGasConsumption`) | Vehicles | now | - | yes | Vehicles.lua reads SandboxVars.CarGasConsumption in the fuel use update. |
| Locked Vehicle Frequency (`LockedCar`) | Vehicles | new | - | yes | Vehicles.lua reads it in the car creation functions. |
| General Condition (`CarGeneralCondition`) | Vehicles | new | - | yes | VehiclePart.setGeneralCondition and setRandomCondition read it at part creation. |
| Car Wreck Congestion (`TrafficJam`) | Vehicles | new | - | yes | IsoChunk.AddVehicles reads it for new chunks. |
| Vehicle Alarms Frequency (`CarAlarm`) | Vehicles | new | - | yes | IsoChunk.AddVehicles_OnZone and AddVehicles_OnZonePolyline read it. |
| Player Damage from Crash (`PlayerDamageFromCrash`) | Vehicles | now | - | yes | BaseVehicle.damagePlayers reads it live. |
| Car Damage on Impact (`CarDamageOnImpact`) | Vehicles | now | - | yes | BaseVehicle.crash reads it live. |
| Siren Shutoff Hours (`SirenShutoffHours`) | Vehicles | now | - | yes | VehicleSoundOwner.sirenShutoffTimeExpired reads it live. |
| Player Damage From Vehicle Impact (`DamageToPlayerFromHitByACar`) | Vehicles | now | - | yes | IsoPlayer.applyDamageFromVehicleHit and onHitByVehicleApplyDamage read it live. |
| Vehicle Sirens Attract Zombies (`SirenEffectsZombies`) | Vehicles | now | - | yes | BaseVehicle.updateWorldSounds reads it live. |
| Stats Reduction Speed (`AnimalStatsModifier`) | Livestock | now | - | yes | AnimalData.getHungerReductionMod reads it live. |
| Pregnancy Time (`AnimalPregnancyTime`) | Livestock | now | - | yes | AnimalData.getPregnantPeriod and getTimeBeforeNextPregnancy read it live. |
| Egg Hatch Time (`AnimalEggHatch`) | Livestock | new | - | yes | Food.setTimeToHatch reads it. |
| Aging Modifier Speed (`AnimalAgeModifier`) | Livestock | now | - | yes | AnimalData.getAgeGrowModifier reads it live. |
| Milk Increase Speed (`AnimalMilkIncModifier`) | Livestock | now | - | yes | AnimalData.getMilkIncModifier reads it live. |
| Wool Increase Speed (`AnimalWoolIncModifier`) | Livestock | now | - | yes | AnimalData.getWoolIncModifier reads it live. |
| Animal Spawn Chance (`AnimalRanchChance`) | Livestock | new | - | yes | RandomizedRanchBase.doRandomRanch reads it. |
| Grass Regrowth time (`AnimalGrassRegrowTime`) | Livestock | now | - | yes | IsoChunk.CheckGrassRegrowth reads it live. |
| Meta Predator (`AnimalMetaPredator`) | Livestock | now | - | yes | IsoAnimal.checkKilledByMetaPredator reads it live. |
| Breeding Season (`AnimalMatingSeason`) | Livestock | now | - | yes | AnimalData and IsoAnimal.isInMatingSeason read it live. |
| Animals Attract Zombies (`AnimalSoundAttractZombies`) | Livestock | now | - | yes | AnimalSoundState.start reads it live. |
| Animal Tracks Chance (`AnimalTrackChance`) | Livestock | new | - | no | AnimalTracksDefinitions.getRandomTrack and AnimalZones.spawnAnimalsOnZone read it; the call timing was not traced. |
| Animal Paths Chance (`AnimalPathChance`) | Livestock | new | - | yes | ZoneGenerator.genAnimalsPath (via IsoMetaCell.checkAnimalZonesGenerated) reads it for cells that have none yet. |
| Start Year (`StartYear`) | Time | fix | - | yes | IsoWorld.init runs GameTime.init (date from Start values) then GameTime.load, which restores the saved day, month, year and time. Only other reader: ItemCodeOnCreate.getDate (year printed on new magazines). The window offers one year only. |
