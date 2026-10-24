# ZeD-UI translation context

Generated from the sweep. One row per key in `Translate/EN/UI.json`: the English, where the phrase shows, and the longest it should be. JSON has no room for comments, so this file is the notes.

- `%1` to `%4` are filled in by the game (a number, a name). Keep them, in any order that suits your language.
- Markup like `<LINE>` or `<RGB:1,1,1>` stays as written.
- **Max** is the most characters that fit where the phrase is drawn. "-" means there is no fixed limit (the box grows or the text wraps). Pixel-face text (action bar, belt, watch, dash, radio) draws capitals, digits and a few signs; accented Latin and Cyrillic capitals work, other alphabets fall back to the plain face.
- Phrases that are all capitals in English (READING, IN HAND) are meant to be capitals in your language too.
- Where the game already has a phrase (body parts, exercise names, thermal views, Steam item states, farming states, short tags and column heads), ZeD uses the key of the game itself, so it arrives translated from the game files and is not listed here. A tag or column head is drawn in capitals by ZeD whatever case the game text has.

Total keys: 2199.

## Areas

- [Accent](#accent) (1)
- [Act](#act) (279)
- [ActionBar](#actionbar) (4)
- [Animals](#animals) (128)
- [Appliance](#appliance) (16)
- [Belt](#belt) (22)
- [Card](#card) (66)
- [Char](#char) (19)
- [Controls](#controls) (13)
- [Craft](#craft) (28)
- [Credits](#credits) (3)
- [CtxMenu](#ctxmenu) (2)
- [Curtain](#curtain) (1)
- [Dash](#dash) (53)
- [Death](#death) (12)
- [DescEdit](#descedit) (71)
- [Desktop](#desktop) (6)
- [Doll](#doll) (19)
- [Equip](#equip) (39)
- [Farm](#farm) (29)
- [Fire](#fire) (35)
- [Fluid](#fluid) (18)
- [Flyer](#flyer) (4)
- [Forage](#forage) (50)
- [Furn](#furn) (25)
- [Health](#health) (8)
- [Hook](#hook) (18)
- [Host](#host) (10)
- [Hud](#hud) (1)
- [Hutch](#hutch) (25)
- [Identity](#identity) (20)
- [Inv](#inv) (10)
- [ItemAct](#itemact) (3)
- [ItemMenu](#itemmenu) (1)
- [Join](#join) (44)
- [Journal](#journal) (24)
- [Keyboard](#keyboard) (1)
- [Lock](#lock) (42)
- [Looks](#looks) (9)
- [Machine](#machine) (18)
- [MainMenu](#mainmenu) (52)
- [Map](#map) (10)
- [Meta](#meta) (8)
- [Modal](#modal) (2)
- [Mods](#mods) (176)
- [ModScan](#modscan) (36)
- [NewGame](#newgame) (3)
- [Notebook](#notebook) (21)
- [ObjCard](#objcard) (10)
- [Options](#options) (89)
- [Papers](#papers) (17)
- [PartAbbr](#partabbr) (14)
- [Place](#place) (3)
- [Power](#power) (24)
- [Print](#print) (2)
- [Prompt](#prompt) (24)
- [Radio](#radio) (31)
- [RadioPrompt](#radioprompt) (16)
- [Reader](#reader) (26)
- [Recipe](#recipe) (1)
- [Safe](#safe) (3)
- [Sandbox](#sandbox) (13)
- [Saves](#saves) (14)
- [Seat](#seat) (5)
- [Server](#server) (55)
- [Settings](#settings) (52)
- [Siren](#siren) (2)
- [Skills](#skills) (7)
- [Spawn](#spawn) (9)
- [Station](#station) (31)
- [Status](#status) (3)
- [Strip](#strip) (3)
- [Target](#target) (2)
- [Thermal](#thermal) (8)
- [Track](#track) (9)
- [Traits](#traits) (19)
- [Trough](#trough) (18)
- [Veh](#veh) (122)
- [Watch](#watch) (14)
- [Wheel](#wheel) (1)
- [Workshop](#workshop) (49)
- [World](#world) (13)
- [General](#general) (5)

## Accent

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Accent_Teal` | `PZ Teal` | Options > Mods > ZeD-GUI: accent color choice (also the window accent settings) | - |

## Act

Action bar over the character's head: one label per game action (pixel face, capitals, 14 letters at most).

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Act_AddChumToWaterAction` | `CHUMMING` | Action bar over the character's head, first line (pixel face), while the action AddChumToWaterAction runs | 14 |
| `UI_ZeD_Act_AIAttachLureAction` | `ATTACHING LURE` | Action bar over the character's head, first line (pixel face), while the action AIAttachLureAction runs | 14 |
| `UI_ZeD_Act_AIRemoveLureAction` | `REMOVING LURE` | Action bar over the character's head, first line (pixel face), while the action AIRemoveLureAction runs | 14 |
| `UI_ZeD_Act_CreateChumFromGroundSandAction` | `MAKING CHUM` | Action bar over the character's head, first line (pixel face), while the action CreateChumFromGroundSandAction runs | 14 |
| `UI_ZeD_Act_HealthPanelAction` | `TREATING` | Action bar over the character's head, first line (pixel face), while the action HealthPanelAction runs | 14 |
| `UI_ZeD_Act_ISActivateCarBatteryChargerAction` | `SWITCHING ON` | Action bar over the character's head, first line (pixel face), while the action ISActivateCarBatteryChargerAction runs | 14 |
| `UI_ZeD_Act_ISActivateGenerator` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISActivateGenerator runs | 14 |
| `UI_ZeD_Act_ISAddAnimalInTrailer` | `LOADING` | Action bar over the character's head, first line (pixel face), while the action ISAddAnimalInTrailer runs | 14 |
| `UI_ZeD_Act_ISAddBaitAction` | `BAITING` | Action bar over the character's head, first line (pixel face), while the action ISAddBaitAction runs | 14 |
| `UI_ZeD_Act_ISAddBaitToFishNetAction` | `BAITING` | Action bar over the character's head, first line (pixel face), while the action ISAddBaitToFishNetAction runs | 14 |
| `UI_ZeD_Act_ISAddCompost` | `COMPOSTING` | Action bar over the character's head, first line (pixel face), while the action ISAddCompost runs | 14 |
| `UI_ZeD_Act_ISAddFluidFromItemAction` | `FILLING` | Action bar over the character's head, first line (pixel face), while the action ISAddFluidFromItemAction runs | 14 |
| `UI_ZeD_Act_ISAddFuel` | `ADDING FUEL` | Action bar over the character's head, first line (pixel face), while the action ISAddFuel runs | 14 |
| `UI_ZeD_Act_ISAddFuelAction` | `ADDING FUEL` | Action bar over the character's head, first line (pixel face), while the action ISAddFuelAction runs | 14 |
| `UI_ZeD_Act_ISAddGasolineToVehicle` | `REFUELING` | Action bar over the character's head, first line (pixel face), while the action ISAddGasolineToVehicle runs | 14 |
| `UI_ZeD_Act_ISAddItemInRecipe` | `ADDING` | Action bar over the character's head, first line (pixel face), while the action ISAddItemInRecipe runs | 14 |
| `UI_ZeD_Act_ISAddSheetAction` | `HANGING SHEET` | Action bar over the character's head, first line (pixel face), while the action ISAddSheetAction runs | 14 |
| `UI_ZeD_Act_ISAddSheetRope` | `TYING ROPE` | Action bar over the character's head, first line (pixel face), while the action ISAddSheetRope runs | 14 |
| `UI_ZeD_Act_ISAddTakeDispenserBottle` | `CHANGING` | Action bar over the character's head, first line (pixel face), while the action ISAddTakeDispenserBottle runs | 14 |
| `UI_ZeD_Act_ISAddWaterToTrough` | `FILLING` | Action bar over the character's head, first line (pixel face), while the action ISAddWaterToTrough runs | 14 |
| `UI_ZeD_Act_ISApplyBandage` | `BANDAGING` | Action bar over the character's head, first line (pixel face), while the action ISApplyBandage runs | 14 |
| `UI_ZeD_Act_ISApplyMakeUp` | `MAKING UP` | Action bar over the character's head, first line (pixel face), while the action ISApplyMakeUp runs | 14 |
| `UI_ZeD_Act_ISAttachAnimalToPlayer` | `LEASHING` | Action bar over the character's head, first line (pixel face), while the action ISAttachAnimalToPlayer runs | 14 |
| `UI_ZeD_Act_ISAttachAnimalToTree` | `TYING UP` | Action bar over the character's head, first line (pixel face), while the action ISAttachAnimalToTree runs | 14 |
| `UI_ZeD_Act_ISAttachItemHotbar` | `ATTACHING` | Action bar over the character's head, first line (pixel face), while the action ISAttachItemHotbar runs | 14 |
| `UI_ZeD_Act_ISAttachTrailerToVehicle` | `HITCHING` | Action bar over the character's head, first line (pixel face), while the action ISAttachTrailerToVehicle runs | 14 |
| `UI_ZeD_Act_ISBarricadeAction` | `BARRICADING` | Action bar over the character's head, first line (pixel face), while the action ISBarricadeAction runs | 14 |
| `UI_ZeD_Act_ISBBQAddFuel` | `ADDING FUEL` | Action bar over the character's head, first line (pixel face), while the action ISBBQAddFuel runs | 14 |
| `UI_ZeD_Act_ISBBQExtinguish` | `PUTTING OUT` | Action bar over the character's head, first line (pixel face), while the action ISBBQExtinguish runs | 14 |
| `UI_ZeD_Act_ISBBQInfoAction` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISBBQInfoAction runs | 14 |
| `UI_ZeD_Act_ISBBQInsertPropaneTank` | `FITTING TANK` | Action bar over the character's head, first line (pixel face), while the action ISBBQInsertPropaneTank runs | 14 |
| `UI_ZeD_Act_ISBBQLightFromKindle` | `LIGHTING` | Action bar over the character's head, first line (pixel face), while the action ISBBQLightFromKindle runs | 14 |
| `UI_ZeD_Act_ISBBQLightFromLiterature` | `LIGHTING` | Action bar over the character's head, first line (pixel face), while the action ISBBQLightFromLiterature runs | 14 |
| `UI_ZeD_Act_ISBBQLightFromPetrol` | `LIGHTING` | Action bar over the character's head, first line (pixel face), while the action ISBBQLightFromPetrol runs | 14 |
| `UI_ZeD_Act_ISBBQRemovePropaneTank` | `REMOVING TANK` | Action bar over the character's head, first line (pixel face), while the action ISBBQRemovePropaneTank runs | 14 |
| `UI_ZeD_Act_ISBBQToggle` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISBBQToggle runs | 14 |
| `UI_ZeD_Act_ISBuildAction` | `BUILDING` | Action bar over the character's head, first line (pixel face), while the action ISBuildAction runs | 14 |
| `UI_ZeD_Act_ISBurnCorpseAction` | `BURNING` | Action bar over the character's head, first line (pixel face), while the action ISBurnCorpseAction runs | 14 |
| `UI_ZeD_Act_ISBuryCorpse` | `BURYING` | Action bar over the character's head, first line (pixel face), while the action ISBuryCorpse runs | 14 |
| `UI_ZeD_Act_ISButcherAnimal` | `BUTCHERING` | Action bar over the character's head, first line (pixel face), while the action ISButcherAnimal runs | 14 |
| `UI_ZeD_Act_IsCampfireInfoAction` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action IsCampfireInfoAction runs | 14 |
| `UI_ZeD_Act_ISChangeFishingRodEquip` | `CHANGING` | Action bar over the character's head, first line (pixel face), while the action ISChangeFishingRodEquip runs | 14 |
| `UI_ZeD_Act_ISCheckAnimalInsideTrailer` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISCheckAnimalInsideTrailer runs | 14 |
| `UI_ZeD_Act_ISCheckFishingNetAction` | `CHECKING NET` | Action bar over the character's head, first line (pixel face), while the action ISCheckFishingNetAction runs | 14 |
| `UI_ZeD_Act_ISCheckTrapAction` | `CHECKING TRAP` | Action bar over the character's head, first line (pixel face), while the action ISCheckTrapAction runs | 14 |
| `UI_ZeD_Act_ISChopTreeAction` | `CHOPPING` | Action bar over the character's head, first line (pixel face), while the action ISChopTreeAction runs | 14 |
| `UI_ZeD_Act_ISCleanBandage` | `CLEANING` | Action bar over the character's head, first line (pixel face), while the action ISCleanBandage runs | 14 |
| `UI_ZeD_Act_ISCleanBlood` | `CLEANING` | Action bar over the character's head, first line (pixel face), while the action ISCleanBlood runs | 14 |
| `UI_ZeD_Act_ISCleanBurn` | `CLEANING` | Action bar over the character's head, first line (pixel face), while the action ISCleanBurn runs | 14 |
| `UI_ZeD_Act_ISCleanGraffiti` | `CLEANING` | Action bar over the character's head, first line (pixel face), while the action ISCleanGraffiti runs | 14 |
| `UI_ZeD_Act_ISClearAshes` | `CLEARING ASHES` | Action bar over the character's head, first line (pixel face), while the action ISClearAshes runs | 14 |
| `UI_ZeD_Act_ISClimbOverFence` | `CLIMBING` | Action bar over the character's head, first line (pixel face), while the action ISClimbOverFence runs | 14 |
| `UI_ZeD_Act_ISClimbSheetRopeAction` | `CLIMBING` | Action bar over the character's head, first line (pixel face), while the action ISClimbSheetRopeAction runs | 14 |
| `UI_ZeD_Act_ISClimbThroughWindow` | `CLIMBING` | Action bar over the character's head, first line (pixel face), while the action ISClimbThroughWindow runs | 14 |
| `UI_ZeD_Act_ISCloseVehicleDoor` | `CLOSING` | Action bar over the character's head, first line (pixel face), while the action ISCloseVehicleDoor runs | 14 |
| `UI_ZeD_Act_ISClothingExtraAction` | `CHANGING` | Action bar over the character's head, first line (pixel face), while the action ISClothingExtraAction runs | 14 |
| `UI_ZeD_Act_ISComfreyCataplasm` | `APPLYING` | Action bar over the character's head, first line (pixel face), while the action ISComfreyCataplasm runs | 14 |
| `UI_ZeD_Act_ISConfigHeadlight` | `ADJUSTING` | Action bar over the character's head, first line (pixel face), while the action ISConfigHeadlight runs | 14 |
| `UI_ZeD_Act_ISConnectCarBatteryToChargerAction` | `CONNECTING` | Action bar over the character's head, first line (pixel face), while the action ISConnectCarBatteryToChargerAction runs | 14 |
| `UI_ZeD_Act_ISConsolidateDrainable` | `COMBINING` | Action bar over the character's head, first line (pixel face), while the action ISConsolidateDrainable runs | 14 |
| `UI_ZeD_Act_ISCraftAction` | `CRAFTING` | Action bar over the character's head, first line (pixel face), while the action ISCraftAction runs | 14 |
| `UI_ZeD_Act_ISCraftAnimAction` | `CRAFTING` | Action bar over the character's head, first line (pixel face), while the action ISCraftAnimAction runs | 14 |
| `UI_ZeD_Act_ISCurePlantAction` | `TREATING` | Action bar over the character's head, first line (pixel face), while the action ISCurePlantAction runs | 14 |
| `UI_ZeD_Act_ISCutAnimalOnHook` | `BUTCHERING` | Action bar over the character's head, first line (pixel face), while the action ISCutAnimalOnHook runs | 14 |
| `UI_ZeD_Act_ISCutHair` | `CUTTING HAIR` | Action bar over the character's head, first line (pixel face), while the action ISCutHair runs | 14 |
| `UI_ZeD_Act_ISDeflateTire` | `DEFLATING` | Action bar over the character's head, first line (pixel face), while the action ISDeflateTire runs | 14 |
| `UI_ZeD_Act_ISDestroyStuffAction` | `DESTROYING` | Action bar over the character's head, first line (pixel face), while the action ISDestroyStuffAction runs | 14 |
| `UI_ZeD_Act_ISDetachItemHotbar` | `DETACHING` | Action bar over the character's head, first line (pixel face), while the action ISDetachItemHotbar runs | 14 |
| `UI_ZeD_Act_ISDetachTrailerFromVehicle` | `UNHITCHING` | Action bar over the character's head, first line (pixel face), while the action ISDetachTrailerFromVehicle runs | 14 |
| `UI_ZeD_Act_ISDeviceBatteryAction` | `CHANGING` | Action bar over the character's head, first line (pixel face), while the action ISDeviceBatteryAction runs | 14 |
| `UI_ZeD_Act_ISDeviceMediaAction` | `CHANGING MEDIA` | Action bar over the character's head, first line (pixel face), while the action ISDeviceMediaAction runs | 14 |
| `UI_ZeD_Act_ISDigStairsAction` | `DIGGING` | Action bar over the character's head, first line (pixel face), while the action ISDigStairsAction runs | 14 |
| `UI_ZeD_Act_ISDisinfect` | `DISINFECTING` | Action bar over the character's head, first line (pixel face), while the action ISDisinfect runs | 14 |
| `UI_ZeD_Act_ISDismantleAction` | `DISMANTLING` | Action bar over the character's head, first line (pixel face), while the action ISDismantleAction runs | 14 |
| `UI_ZeD_Act_ISDrinkFluidAction` | `DRINKING` | Action bar over the character's head, first line (pixel face), while the action ISDrinkFluidAction runs | 14 |
| `UI_ZeD_Act_ISDrinkFromBottle` | `DRINKING` | Action bar over the character's head, first line (pixel face), while the action ISDrinkFromBottle runs | 14 |
| `UI_ZeD_Act_ISDropAnimalCorpseAndThen` | `DROPPING` | Action bar over the character's head, first line (pixel face), while the action ISDropAnimalCorpseAndThen runs | 14 |
| `UI_ZeD_Act_ISDropCorpseAction` | `DROPPING` | Action bar over the character's head, first line (pixel face), while the action ISDropCorpseAction runs | 14 |
| `UI_ZeD_Act_ISDropCorpseIntoContainer` | `DROPPING` | Action bar over the character's head, first line (pixel face), while the action ISDropCorpseIntoContainer runs | 14 |
| `UI_ZeD_Act_ISDropVehicleItemAction` | `DROPPING` | Action bar over the character's head, first line (pixel face), while the action ISDropVehicleItemAction runs | 14 |
| `UI_ZeD_Act_ISDropWorldItemAction` | `DROPPING` | Action bar over the character's head, first line (pixel face), while the action ISDropWorldItemAction runs | 14 |
| `UI_ZeD_Act_ISDryMyself` | `DRYING OFF` | Action bar over the character's head, first line (pixel face), while the action ISDryMyself runs | 14 |
| `UI_ZeD_Act_ISDumpContentsAction` | `EMPTYING` | Action bar over the character's head, first line (pixel face), while the action ISDumpContentsAction runs | 14 |
| `UI_ZeD_Act_ISDumpWaterAction` | `POURING OUT` | Action bar over the character's head, first line (pixel face), while the action ISDumpWaterAction runs | 14 |
| `UI_ZeD_Act_ISDyeHair` | `DYEING HAIR` | Action bar over the character's head, first line (pixel face), while the action ISDyeHair runs | 14 |
| `UI_ZeD_Act_ISEatFoodAction` | `EATING` | Action bar over the character's head, first line (pixel face), while the action ISEatFoodAction runs | 14 |
| `UI_ZeD_Act_ISEjectMagazine` | `EJECTING` | Action bar over the character's head, first line (pixel face), while the action ISEjectMagazine runs | 14 |
| `UI_ZeD_Act_ISEmptyRainBarrelAction` | `EMPTYING` | Action bar over the character's head, first line (pixel face), while the action ISEmptyRainBarrelAction runs | 14 |
| `UI_ZeD_Act_ISEmptyWaterInTrough` | `EMPTYING` | Action bar over the character's head, first line (pixel face), while the action ISEmptyWaterInTrough runs | 14 |
| `UI_ZeD_Act_ISEnterVehicle` | `GETTING IN` | Action bar over the character's head, first line (pixel face), while the action ISEnterVehicle runs | 14 |
| `UI_ZeD_Act_ISEquipHeavyItem` | `LIFTING` | Action bar over the character's head, first line (pixel face), while the action ISEquipHeavyItem runs | 14 |
| `UI_ZeD_Act_ISEquipWeaponAction` | `EQUIPPING` | Action bar over the character's head, first line (pixel face), while the action ISEquipWeaponAction runs | 14 |
| `UI_ZeD_Act_ISExitVehicle` | `GETTING OUT` | Action bar over the character's head, first line (pixel face), while the action ISExitVehicle runs | 14 |
| `UI_ZeD_Act_ISExtendedPlacementAction` | `PLACING` | Action bar over the character's head, first line (pixel face), while the action ISExtendedPlacementAction runs | 14 |
| `UI_ZeD_Act_ISFeedAnimalFromHand` | `FEEDING` | Action bar over the character's head, first line (pixel face), while the action ISFeedAnimalFromHand runs | 14 |
| `UI_ZeD_Act_ISFertilizeAction` | `FERTILIZING` | Action bar over the character's head, first line (pixel face), while the action ISFertilizeAction runs | 14 |
| `UI_ZeD_Act_ISFillGrave` | `FILLING GRAVE` | Action bar over the character's head, first line (pixel face), while the action ISFillGrave runs | 14 |
| `UI_ZeD_Act_ISFitnessAction` | `EXERCISING` | Action bar over the character's head, first line (pixel face), while the action ISFitnessAction runs | 14 |
| `UI_ZeD_Act_ISFixAction` | `REPAIRING` | Action bar over the character's head, first line (pixel face), while the action ISFixAction runs | 14 |
| `UI_ZeD_Act_ISFixGenerator` | `REPAIRING` | Action bar over the character's head, first line (pixel face), while the action ISFixGenerator runs | 14 |
| `UI_ZeD_Act_ISFixVehiclePartAction` | `REPAIRING` | Action bar over the character's head, first line (pixel face), while the action ISFixVehiclePartAction runs | 14 |
| `UI_ZeD_Act_ISFluidEmptyAction` | `EMPTYING` | Action bar over the character's head, first line (pixel face), while the action ISFluidEmptyAction runs | 14 |
| `UI_ZeD_Act_ISFluidPanelAction` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISFluidPanelAction runs | 14 |
| `UI_ZeD_Act_ISFluidTransferAction` | `POURING` | Action bar over the character's head, first line (pixel face), while the action ISFluidTransferAction runs | 14 |
| `UI_ZeD_Act_ISForageAction` | `FORAGING` | Action bar over the character's head, first line (pixel face), while the action ISForageAction runs | 14 |
| `UI_ZeD_Act_ISGarlicCataplasm` | `APPLYING` | Action bar over the character's head, first line (pixel face), while the action ISGarlicCataplasm runs | 14 |
| `UI_ZeD_Act_ISGatherBloodFromAnimal` | `BLEEDING` | Action bar over the character's head, first line (pixel face), while the action ISGatherBloodFromAnimal runs | 14 |
| `UI_ZeD_Act_ISGeneratorInfoAction` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISGeneratorInfoAction runs | 14 |
| `UI_ZeD_Act_ISGenericCraftStart` | `CRAFTING` | Action bar over the character's head, first line (pixel face), while the action ISGenericCraftStart runs | 14 |
| `UI_ZeD_Act_ISGetAnimalBones` | `TAKING BONES` | Action bar over the character's head, first line (pixel face), while the action ISGetAnimalBones runs | 14 |
| `UI_ZeD_Act_ISGetCompost` | `TAKING COMPOST` | Action bar over the character's head, first line (pixel face), while the action ISGetCompost runs | 14 |
| `UI_ZeD_Act_ISGetHutchInfo` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISGetHutchInfo runs | 14 |
| `UI_ZeD_Act_ISGetOnBedAction` | `LYING DOWN` | Action bar over the character's head, first line (pixel face), while the action ISGetOnBedAction runs | 14 |
| `UI_ZeD_Act_ISGiveWaterToAnimal` | `WATERING` | Action bar over the character's head, first line (pixel face), while the action ISGiveWaterToAnimal runs | 14 |
| `UI_ZeD_Act_ISGrabCorpseAction` | `LIFTING` | Action bar over the character's head, first line (pixel face), while the action ISGrabCorpseAction runs | 14 |
| `UI_ZeD_Act_ISGrabCorpseItem` | `LIFTING` | Action bar over the character's head, first line (pixel face), while the action ISGrabCorpseItem runs | 14 |
| `UI_ZeD_Act_ISGrabItemAction` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISGrabItemAction runs | 14 |
| `UI_ZeD_Act_ISHandcraftAction` | `CRAFTING` | Action bar over the character's head, first line (pixel face), while the action ISHandcraftAction runs | 14 |
| `UI_ZeD_Act_ISHarvestPlantAction` | `HARVESTING` | Action bar over the character's head, first line (pixel face), while the action ISHarvestPlantAction runs | 14 |
| `UI_ZeD_Act_ISHorn` | `HONKING` | Action bar over the character's head, first line (pixel face), while the action ISHorn runs | 14 |
| `UI_ZeD_Act_ISHotwireVehicle` | `HOTWIRING` | Action bar over the character's head, first line (pixel face), while the action ISHotwireVehicle runs | 14 |
| `UI_ZeD_Act_ISHurricaneLanternExtinguish` | `PUTTING OUT` | Action bar over the character's head, first line (pixel face), while the action ISHurricaneLanternExtinguish runs | 14 |
| `UI_ZeD_Act_ISHutchCleanFloor` | `CLEANING` | Action bar over the character's head, first line (pixel face), while the action ISHutchCleanFloor runs | 14 |
| `UI_ZeD_Act_ISHutchCleanNest` | `CLEANING` | Action bar over the character's head, first line (pixel face), while the action ISHutchCleanNest runs | 14 |
| `UI_ZeD_Act_ISHutchGrabAnimal` | `GRABBING` | Action bar over the character's head, first line (pixel face), while the action ISHutchGrabAnimal runs | 14 |
| `UI_ZeD_Act_ISHutchGrabCorpseAction` | `GRABBING` | Action bar over the character's head, first line (pixel face), while the action ISHutchGrabCorpseAction runs | 14 |
| `UI_ZeD_Act_ISHutchGrabEgg` | `TAKING EGGS` | Action bar over the character's head, first line (pixel face), while the action ISHutchGrabEgg runs | 14 |
| `UI_ZeD_Act_ISInflateTire` | `INFLATING` | Action bar over the character's head, first line (pixel face), while the action ISInflateTire runs | 14 |
| `UI_ZeD_Act_ISInsertLightSourceFuelAction` | `REFUELING` | Action bar over the character's head, first line (pixel face), while the action ISInsertLightSourceFuelAction runs | 14 |
| `UI_ZeD_Act_ISInsertMagazine` | `LOADING` | Action bar over the character's head, first line (pixel face), while the action ISInsertMagazine runs | 14 |
| `UI_ZeD_Act_ISInspectAnimalTrackAction` | `TRACKING` | Action bar over the character's head, first line (pixel face), while the action ISInspectAnimalTrackAction runs | 14 |
| `UI_ZeD_Act_ISInstallVehiclePart` | `INSTALLING` | Action bar over the character's head, first line (pixel face), while the action ISInstallVehiclePart runs | 14 |
| `UI_ZeD_Act_ISInventoryTransferAction` | `MOVING` | Action bar over the character's head, first line (pixel face), while the action ISInventoryTransferAction runs | 14 |
| `UI_ZeD_Act_ISItemSlotAddAction` | `ADDING` | Action bar over the character's head, first line (pixel face), while the action ISItemSlotAddAction runs | 14 |
| `UI_ZeD_Act_ISItemSlotRemoveAction` | `REMOVING` | Action bar over the character's head, first line (pixel face), while the action ISItemSlotRemoveAction runs | 14 |
| `UI_ZeD_Act_ISKillAnimal` | `KILLING` | Action bar over the character's head, first line (pixel face), while the action ISKillAnimal runs | 14 |
| `UI_ZeD_Act_ISKillAnimalInInventory` | `KILLING` | Action bar over the character's head, first line (pixel face), while the action ISKillAnimalInInventory runs | 14 |
| `UI_ZeD_Act_ISLightActions` | `LIGHTING` | Action bar over the character's head, first line (pixel face), while the action ISLightActions runs | 14 |
| `UI_ZeD_Act_ISLightbarUITimedAction` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISLightbarUITimedAction runs | 14 |
| `UI_ZeD_Act_ISLightFromKindle` | `LIGHTING` | Action bar over the character's head, first line (pixel face), while the action ISLightFromKindle runs | 14 |
| `UI_ZeD_Act_ISLightFromLiterature` | `LIGHTING` | Action bar over the character's head, first line (pixel face), while the action ISLightFromLiterature runs | 14 |
| `UI_ZeD_Act_ISLightFromPetrol` | `LIGHTING` | Action bar over the character's head, first line (pixel face), while the action ISLightFromPetrol runs | 14 |
| `UI_ZeD_Act_ISLitCandleExtinguish` | `SNUFFING` | Action bar over the character's head, first line (pixel face), while the action ISLitCandleExtinguish runs | 14 |
| `UI_ZeD_Act_ISLoadBulletsInMagazine` | `LOADING` | Action bar over the character's head, first line (pixel face), while the action ISLoadBulletsInMagazine runs | 14 |
| `UI_ZeD_Act_ISLockDoor` | `LOCKING` | Action bar over the character's head, first line (pixel face), while the action ISLockDoor runs | 14 |
| `UI_ZeD_Act_ISLockDoors` | `LOCKING` | Action bar over the character's head, first line (pixel face), while the action ISLockDoors runs | 14 |
| `UI_ZeD_Act_ISLockVehicleDoor` | `LOCKING` | Action bar over the character's head, first line (pixel face), while the action ISLockVehicleDoor runs | 14 |
| `UI_ZeD_Act_ISLureAnimal` | `LURING` | Action bar over the character's head, first line (pixel face), while the action ISLureAnimal runs | 14 |
| `UI_ZeD_Act_ISMedicalCheckAction` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISMedicalCheckAction runs | 14 |
| `UI_ZeD_Act_ISMilkAnimal` | `MILKING` | Action bar over the character's head, first line (pixel face), while the action ISMilkAnimal runs | 14 |
| `UI_ZeD_Act_ISMoveablesAction` | `MOVING` | Action bar over the character's head, first line (pixel face), while the action ISMoveablesAction runs | 14 |
| `UI_ZeD_Act_ISMultiStageBuild` | `BUILDING` | Action bar over the character's head, first line (pixel face), while the action ISMultiStageBuild runs | 14 |
| `UI_ZeD_Act_ISOpenAnimalInfo` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISOpenAnimalInfo runs | 14 |
| `UI_ZeD_Act_ISOpenButcherHookUI` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISOpenButcherHookUI runs | 14 |
| `UI_ZeD_Act_ISOpenCloseCurtain` | `USING` | Action bar over the character's head, first line (pixel face), while the action ISOpenCloseCurtain runs | 14 |
| `UI_ZeD_Act_ISOpenCloseDoor` | `USING` | Action bar over the character's head, first line (pixel face), while the action ISOpenCloseDoor runs | 14 |
| `UI_ZeD_Act_ISOpenCloseLid` | `USING` | Action bar over the character's head, first line (pixel face), while the action ISOpenCloseLid runs | 14 |
| `UI_ZeD_Act_ISOpenCloseVehicleWindow` | `WINDING` | Action bar over the character's head, first line (pixel face), while the action ISOpenCloseVehicleWindow runs | 14 |
| `UI_ZeD_Act_ISOpenCloseWindow` | `USING` | Action bar over the character's head, first line (pixel face), while the action ISOpenCloseWindow runs | 14 |
| `UI_ZeD_Act_ISOpenContainerTimedAction` | `OPENING` | Action bar over the character's head, first line (pixel face), while the action ISOpenContainerTimedAction runs | 14 |
| `UI_ZeD_Act_ISOpenMechanicsUIAction` | `INSPECTING` | Action bar over the character's head, first line (pixel face), while the action ISOpenMechanicsUIAction runs | 14 |
| `UI_ZeD_Act_ISOpenVehicleDoor` | `OPENING` | Action bar over the character's head, first line (pixel face), while the action ISOpenVehicleDoor runs | 14 |
| `UI_ZeD_Act_ISOvenUITimedAction` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISOvenUITimedAction runs | 14 |
| `UI_ZeD_Act_ISPadlockAction` | `LOCKING` | Action bar over the character's head, first line (pixel face), while the action ISPadlockAction runs | 14 |
| `UI_ZeD_Act_ISPadlockByCodeAction` | `LOCKING` | Action bar over the character's head, first line (pixel face), while the action ISPadlockByCodeAction runs | 14 |
| `UI_ZeD_Act_ISPaintAction` | `PAINTING` | Action bar over the character's head, first line (pixel face), while the action ISPaintAction runs | 14 |
| `UI_ZeD_Act_ISPaintSignAction` | `PAINTING` | Action bar over the character's head, first line (pixel face), while the action ISPaintSignAction runs | 14 |
| `UI_ZeD_Act_ISPathFindAction` | `WALKING` | Action bar over the character's head, first line (pixel face), while the action ISPathFindAction runs | 14 |
| `UI_ZeD_Act_ISPetAnimal` | `PETTING` | Action bar over the character's head, first line (pixel face), while the action ISPetAnimal runs | 14 |
| `UI_ZeD_Act_ISPickAxeGroundCoverItem` | `DIGGING UP` | Action bar over the character's head, first line (pixel face), while the action ISPickAxeGroundCoverItem runs | 14 |
| `UI_ZeD_Act_ISPickupAnimal` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISPickupAnimal runs | 14 |
| `UI_ZeD_Act_ISPickupBrokenGlass` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISPickupBrokenGlass runs | 14 |
| `UI_ZeD_Act_ISPickupDung` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISPickupDung runs | 14 |
| `UI_ZeD_Act_ISPickupFishAction` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISPickupFishAction runs | 14 |
| `UI_ZeD_Act_ISPickUpGroundCoverItem` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISPickUpGroundCoverItem runs | 14 |
| `UI_ZeD_Act_ISPlaceCarBatteryChargerAction` | `PLACING` | Action bar over the character's head, first line (pixel face), while the action ISPlaceCarBatteryChargerAction runs | 14 |
| `UI_ZeD_Act_ISPlaceFishingNetAction` | `SETTING NET` | Action bar over the character's head, first line (pixel face), while the action ISPlaceFishingNetAction runs | 14 |
| `UI_ZeD_Act_ISPlaceTrap` | `SETTING TRAP` | Action bar over the character's head, first line (pixel face), while the action ISPlaceTrap runs | 14 |
| `UI_ZeD_Act_ISPlantainCataplasm` | `APPLYING` | Action bar over the character's head, first line (pixel face), while the action ISPlantainCataplasm runs | 14 |
| `UI_ZeD_Act_ISPlantInfoAction` | `CHECKING` | Action bar over the character's head, first line (pixel face), while the action ISPlantInfoAction runs | 14 |
| `UI_ZeD_Act_ISPlasterAction` | `PLASTERING` | Action bar over the character's head, first line (pixel face), while the action ISPlasterAction runs | 14 |
| `UI_ZeD_Act_ISPlowAction` | `DIGGING` | Action bar over the character's head, first line (pixel face), while the action ISPlowAction runs | 14 |
| `UI_ZeD_Act_ISPlugGenerator` | `PLUGGING IN` | Action bar over the character's head, first line (pixel face), while the action ISPlugGenerator runs | 14 |
| `UI_ZeD_Act_ISPlumbItem` | `PLUMBING` | Action bar over the character's head, first line (pixel face), while the action ISPlumbItem runs | 14 |
| `UI_ZeD_Act_ISPutAnimalInHutch` | `PUTTING IN` | Action bar over the character's head, first line (pixel face), while the action ISPutAnimalInHutch runs | 14 |
| `UI_ZeD_Act_ISPutAnimalOnHook` | `HANGING` | Action bar over the character's head, first line (pixel face), while the action ISPutAnimalOnHook runs | 14 |
| `UI_ZeD_Act_ISPutOutCampfireAction` | `PUTTING OUT` | Action bar over the character's head, first line (pixel face), while the action ISPutOutCampfireAction runs | 14 |
| `UI_ZeD_Act_ISPutOutFire` | `PUTTING OUT` | Action bar over the character's head, first line (pixel face), while the action ISPutOutFire runs | 14 |
| `UI_ZeD_Act_ISQueueActionsAction` | `PREPARING` | Action bar over the character's head, first line (pixel face), while the action ISQueueActionsAction runs | 14 |
| `UI_ZeD_Act_ISRackFirearm` | `RACKING` | Action bar over the character's head, first line (pixel face), while the action ISRackFirearm runs | 14 |
| `UI_ZeD_Act_ISRadioAction` | `TUNING` | Action bar over the character's head, first line (pixel face), while the action ISRadioAction runs | 14 |
| `UI_ZeD_Act_ISReadABook` | `READING` | Action bar over the character's head, first line (pixel face), while the action ISReadABook runs | 14 |
| `UI_ZeD_Act_ISReadWorldMap` | `READING` | Action bar over the character's head, first line (pixel face), while the action ISReadWorldMap runs | 14 |
| `UI_ZeD_Act_ISRefuelFromGasPump` | `REFUELING` | Action bar over the character's head, first line (pixel face), while the action ISRefuelFromGasPump runs | 14 |
| `UI_ZeD_Act_ISReloadWeaponAction` | `RELOADING` | Action bar over the character's head, first line (pixel face), while the action ISReloadWeaponAction runs | 14 |
| `UI_ZeD_Act_ISRemoveAnimalFromHook` | `TAKING DOWN` | Action bar over the character's head, first line (pixel face), while the action ISRemoveAnimalFromHook runs | 14 |
| `UI_ZeD_Act_ISRemoveAnimalFromTrailer` | `UNLOADING` | Action bar over the character's head, first line (pixel face), while the action ISRemoveAnimalFromTrailer runs | 14 |
| `UI_ZeD_Act_ISRemoveBaitAction` | `TAKING BAIT` | Action bar over the character's head, first line (pixel face), while the action ISRemoveBaitAction runs | 14 |
| `UI_ZeD_Act_ISRemoveBrokenGlass` | `CLEARING GLASS` | Action bar over the character's head, first line (pixel face), while the action ISRemoveBrokenGlass runs | 14 |
| `UI_ZeD_Act_ISRemoveBullet` | `EXTRACTING` | Action bar over the character's head, first line (pixel face), while the action ISRemoveBullet runs | 14 |
| `UI_ZeD_Act_ISRemoveBurntVehicle` | `CLEARING WRECK` | Action bar over the character's head, first line (pixel face), while the action ISRemoveBurntVehicle runs | 14 |
| `UI_ZeD_Act_ISRemoveBush` | `CLEARING` | Action bar over the character's head, first line (pixel face), while the action ISRemoveBush runs | 14 |
| `UI_ZeD_Act_ISRemoveCampfireAction` | `TAKING APART` | Action bar over the character's head, first line (pixel face), while the action ISRemoveCampfireAction runs | 14 |
| `UI_ZeD_Act_ISRemoveCarBatteryFromChargerAction` | `DISCONNECTING` | Action bar over the character's head, first line (pixel face), while the action ISRemoveCarBatteryFromChargerAction runs | 14 |
| `UI_ZeD_Act_ISRemoveFishingNetAction` | `TAKING NET` | Action bar over the character's head, first line (pixel face), while the action ISRemoveFishingNetAction runs | 14 |
| `UI_ZeD_Act_ISRemoveGlass` | `REMOVING GLASS` | Action bar over the character's head, first line (pixel face), while the action ISRemoveGlass runs | 14 |
| `UI_ZeD_Act_ISRemoveGrass` | `CUTTING GRASS` | Action bar over the character's head, first line (pixel face), while the action ISRemoveGrass runs | 14 |
| `UI_ZeD_Act_ISRemoveHeadFromAnimal` | `REMOVING HEAD` | Action bar over the character's head, first line (pixel face), while the action ISRemoveHeadFromAnimal runs | 14 |
| `UI_ZeD_Act_ISRemoveLeatherFromAnimal` | `SKINNING` | Action bar over the character's head, first line (pixel face), while the action ISRemoveLeatherFromAnimal runs | 14 |
| `UI_ZeD_Act_ISRemoveLightSourceFuelAction` | `TAKING FUEL` | Action bar over the character's head, first line (pixel face), while the action ISRemoveLightSourceFuelAction runs | 14 |
| `UI_ZeD_Act_ISRemoveMeatFromAnimal` | `TAKING MEAT` | Action bar over the character's head, first line (pixel face), while the action ISRemoveMeatFromAnimal runs | 14 |
| `UI_ZeD_Act_ISRemovePatch` | `REMOVING PATCH` | Action bar over the character's head, first line (pixel face), while the action ISRemovePatch runs | 14 |
| `UI_ZeD_Act_ISRemoveSheetAction` | `TAKING DOWN` | Action bar over the character's head, first line (pixel face), while the action ISRemoveSheetAction runs | 14 |
| `UI_ZeD_Act_ISRemoveSheetRope` | `UNTYING ROPE` | Action bar over the character's head, first line (pixel face), while the action ISRemoveSheetRope runs | 14 |
| `UI_ZeD_Act_ISRemoveTrapAction` | `TAKING TRAP` | Action bar over the character's head, first line (pixel face), while the action ISRemoveTrapAction runs | 14 |
| `UI_ZeD_Act_ISRemoveWeaponUpgrade` | `REMOVING` | Action bar over the character's head, first line (pixel face), while the action ISRemoveWeaponUpgrade runs | 14 |
| `UI_ZeD_Act_ISRepairClothing` | `REPAIRING` | Action bar over the character's head, first line (pixel face), while the action ISRepairClothing runs | 14 |
| `UI_ZeD_Act_ISRepairEngine` | `REPAIRING` | Action bar over the character's head, first line (pixel face), while the action ISRepairEngine runs | 14 |
| `UI_ZeD_Act_ISRepairLightbar` | `REPAIRING` | Action bar over the character's head, first line (pixel face), while the action ISRepairLightbar runs | 14 |
| `UI_ZeD_Act_ISResearchRecipe` | `RESEARCHING` | Action bar over the character's head, first line (pixel face), while the action ISResearchRecipe runs | 14 |
| `UI_ZeD_Act_ISRestAction` | `RESTING` | Action bar over the character's head, first line (pixel face), while the action ISRestAction runs | 14 |
| `UI_ZeD_Act_ISScything` | `SCYTHING` | Action bar over the character's head, first line (pixel face), while the action ISScything runs | 14 |
| `UI_ZeD_Act_ISSeedActionNew` | `SOWING` | Action bar over the character's head, first line (pixel face), while the action ISSeedActionNew runs | 14 |
| `UI_ZeD_Act_ISSetComboWasherDryerMode` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISSetComboWasherDryerMode runs | 14 |
| `UI_ZeD_Act_ISShearAnimal` | `SHEARING` | Action bar over the character's head, first line (pixel face), while the action ISShearAnimal runs | 14 |
| `UI_ZeD_Act_ISShovelAction` | `SHOVELING` | Action bar over the character's head, first line (pixel face), while the action ISShovelAction runs | 14 |
| `UI_ZeD_Act_ISShovelGround` | `SHOVELING` | Action bar over the character's head, first line (pixel face), while the action ISShovelGround runs | 14 |
| `UI_ZeD_Act_ISShutOffVehicleEngine` | `SWITCHING OFF` | Action bar over the character's head, first line (pixel face), while the action ISShutOffVehicleEngine runs | 14 |
| `UI_ZeD_Act_ISSitOnGround` | `SITTING` | Action bar over the character's head, first line (pixel face), while the action ISSitOnGround runs | 14 |
| `UI_ZeD_Act_ISSmashVehicleWindow` | `SMASHING` | Action bar over the character's head, first line (pixel face), while the action ISSmashVehicleWindow runs | 14 |
| `UI_ZeD_Act_ISSmashWindow` | `SMASHING` | Action bar over the character's head, first line (pixel face), while the action ISSmashWindow runs | 14 |
| `UI_ZeD_Act_ISSplint` | `SPLINTING` | Action bar over the character's head, first line (pixel face), while the action ISSplint runs | 14 |
| `UI_ZeD_Act_ISStartCraftProcessorAction` | `STARTING` | Action bar over the character's head, first line (pixel face), while the action ISStartCraftProcessorAction runs | 14 |
| `UI_ZeD_Act_ISStartVehicleEngine` | `STARTING` | Action bar over the character's head, first line (pixel face), while the action ISStartVehicleEngine runs | 14 |
| `UI_ZeD_Act_ISStitch` | `STITCHING` | Action bar over the character's head, first line (pixel face), while the action ISStitch runs | 14 |
| `UI_ZeD_Act_ISStopAlarmClockAction` | `SILENCING` | Action bar over the character's head, first line (pixel face), while the action ISStopAlarmClockAction runs | 14 |
| `UI_ZeD_Act_ISStopVehicle` | `STOPPING` | Action bar over the character's head, first line (pixel face), while the action ISStopVehicle runs | 14 |
| `UI_ZeD_Act_ISSwitchVehicleSeat` | `CHANGING SEATS` | Action bar over the character's head, first line (pixel face), while the action ISSwitchVehicleSeat runs | 14 |
| `UI_ZeD_Act_ISTakeBricks` | `TAKING BRICKS` | Action bar over the character's head, first line (pixel face), while the action ISTakeBricks runs | 14 |
| `UI_ZeD_Act_ISTakeCarBatteryChargerAction` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISTakeCarBatteryChargerAction runs | 14 |
| `UI_ZeD_Act_ISTakeEngineParts` | `TAKING PARTS` | Action bar over the character's head, first line (pixel face), while the action ISTakeEngineParts runs | 14 |
| `UI_ZeD_Act_ISTakeFuel` | `TAKING FUEL` | Action bar over the character's head, first line (pixel face), while the action ISTakeFuel runs | 14 |
| `UI_ZeD_Act_ISTakeGasolineFromVehicle` | `SIPHONING` | Action bar over the character's head, first line (pixel face), while the action ISTakeGasolineFromVehicle runs | 14 |
| `UI_ZeD_Act_ISTakeGenerator` | `PICKING UP` | Action bar over the character's head, first line (pixel face), while the action ISTakeGenerator runs | 14 |
| `UI_ZeD_Act_ISTakePillAction` | `TAKING PILLS` | Action bar over the character's head, first line (pixel face), while the action ISTakePillAction runs | 14 |
| `UI_ZeD_Act_ISTakeTrap` | `TAKING TRAP` | Action bar over the character's head, first line (pixel face), while the action ISTakeTrap runs | 14 |
| `UI_ZeD_Act_ISTakeWaterAction` | `DRINKING` | Action bar over the character's head, first line (pixel face), while the action ISTakeWaterAction runs | 14 |
| `UI_ZeD_Act_ISThrowCorpseOverFence` | `THROWING` | Action bar over the character's head, first line (pixel face), while the action ISThrowCorpseOverFence runs | 14 |
| `UI_ZeD_Act_ISThrowCorpseThroughWindow` | `THROWING` | Action bar over the character's head, first line (pixel face), while the action ISThrowCorpseThroughWindow runs | 14 |
| `UI_ZeD_Act_ISToggleClothingDryer` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISToggleClothingDryer runs | 14 |
| `UI_ZeD_Act_ISToggleClothingWasher` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISToggleClothingWasher runs | 14 |
| `UI_ZeD_Act_ISToggleComboWasherDryer` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISToggleComboWasherDryer runs | 14 |
| `UI_ZeD_Act_ISToggleHutchDoor` | `OPENING` | Action bar over the character's head, first line (pixel face), while the action ISToggleHutchDoor runs | 14 |
| `UI_ZeD_Act_ISToggleHutchEggHatchDoor` | `OPENING` | Action bar over the character's head, first line (pixel face), while the action ISToggleHutchEggHatchDoor runs | 14 |
| `UI_ZeD_Act_ISToggleLightAction` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISToggleLightAction runs | 14 |
| `UI_ZeD_Act_ISToggleLightSourceAction` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISToggleLightSourceAction runs | 14 |
| `UI_ZeD_Act_ISToggleStoveAction` | `SWITCHING` | Action bar over the character's head, first line (pixel face), while the action ISToggleStoveAction runs | 14 |
| `UI_ZeD_Act_ISTransferAction` | `MOVING` | Action bar over the character's head, first line (pixel face), while the action ISTransferAction runs | 14 |
| `UI_ZeD_Act_ISTransferWaterAction` | `POURING` | Action bar over the character's head, first line (pixel face), while the action ISTransferWaterAction runs | 14 |
| `UI_ZeD_Act_ISTrimBeard` | `TRIMMING` | Action bar over the character's head, first line (pixel face), while the action ISTrimBeard runs | 14 |
| `UI_ZeD_Act_ISUnbarricadeAction` | `PRYING OFF` | Action bar over the character's head, first line (pixel face), while the action ISUnbarricadeAction runs | 14 |
| `UI_ZeD_Act_ISUnequipAction` | `TAKING OFF` | Action bar over the character's head, first line (pixel face), while the action ISUnequipAction runs | 14 |
| `UI_ZeD_Act_ISUninstallVehiclePart` | `REMOVING` | Action bar over the character's head, first line (pixel face), while the action ISUninstallVehiclePart runs | 14 |
| `UI_ZeD_Act_ISUnloadBulletsFromFirearm` | `UNLOADING` | Action bar over the character's head, first line (pixel face), while the action ISUnloadBulletsFromFirearm runs | 14 |
| `UI_ZeD_Act_ISUnloadBulletsFromMagazine` | `UNLOADING` | Action bar over the character's head, first line (pixel face), while the action ISUnloadBulletsFromMagazine runs | 14 |
| `UI_ZeD_Act_ISUnlockVehicleDoor` | `UNLOCKING` | Action bar over the character's head, first line (pixel face), while the action ISUnlockVehicleDoor runs | 14 |
| `UI_ZeD_Act_ISUpgradeWeapon` | `UPGRADING` | Action bar over the character's head, first line (pixel face), while the action ISUpgradeWeapon runs | 14 |
| `UI_ZeD_Act_ISWaitWhileGettingUp` | `GETTING UP` | Action bar over the character's head, first line (pixel face), while the action ISWaitWhileGettingUp runs | 14 |
| `UI_ZeD_Act_ISWakeOtherPlayer` | `WAKING` | Action bar over the character's head, first line (pixel face), while the action ISWakeOtherPlayer runs | 14 |
| `UI_ZeD_Act_ISWalkToTimedAction` | `WALKING` | Action bar over the character's head, first line (pixel face), while the action ISWalkToTimedAction runs | 14 |
| `UI_ZeD_Act_ISWalkToTimedActionF` | `WALKING` | Action bar over the character's head, first line (pixel face), while the action ISWalkToTimedActionF runs | 14 |
| `UI_ZeD_Act_ISWallpaperAction` | `WALLPAPERING` | Action bar over the character's head, first line (pixel face), while the action ISWallpaperAction runs | 14 |
| `UI_ZeD_Act_ISWashClothing` | `WASHING` | Action bar over the character's head, first line (pixel face), while the action ISWashClothing runs | 14 |
| `UI_ZeD_Act_ISWashVehicle` | `WASHING` | Action bar over the character's head, first line (pixel face), while the action ISWashVehicle runs | 14 |
| `UI_ZeD_Act_ISWashYourself` | `WASHING` | Action bar over the character's head, first line (pixel face), while the action ISWashYourself runs | 14 |
| `UI_ZeD_Act_ISWaterPlantAction` | `WATERING` | Action bar over the character's head, first line (pixel face), while the action ISWaterPlantAction runs | 14 |
| `UI_ZeD_Act_ISWearClothing` | `PUTTING ON` | Action bar over the character's head, first line (pixel face), while the action ISWearClothing runs | 14 |
| `UI_ZeD_Act_ISWringClothing` | `WRINGING OUT` | Action bar over the character's head, first line (pixel face), while the action ISWringClothing runs | 14 |
| `UI_ZeD_Act_ISWriteSomething` | `WRITING` | Action bar over the character's head, first line (pixel face), while the action ISWriteSomething runs | 14 |

## ActionBar

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_ActionBar_Done` | `DONE` | Action bar, first line, when a job finishes (green) | 14 |
| `UI_ZeD_ActionBar_Stopped` | `STOPPED` | Action bar, first line, after the player stops an action (greyed) | 14 |
| `UI_ZeD_ActionBar_Then` | `THEN %1` | Action bar, second line (3x5 legend face) while walking to the next job; %1 = that job's label | 20 |
| `UI_ZeD_ActionBar_Working` | `WORKING` | Action bar, first line, for an action with no known name | 14 |

## Animals

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Animals_AlertDefault` | `Alert` | Animals tab alert row: badge text for an alert with no specific label (drawn in capitals) | 10 |
| `UI_ZeD_Animals_AlertOrphan` | `Orphan` | Animals tab alert row: badge when a baby has lost its mother (drawn in capitals) | 10 |
| `UI_ZeD_Animals_AnimalCountMany` | `%1 animals` | Animals tab zone view, info band: how many animals are in the zone (none or several) | 14 |
| `UI_ZeD_Animals_AnimalCountOne` | `%1 animal` | Animals tab zone view, info band: how many animals are in the zone (exactly one) | 14 |
| `UI_ZeD_Animals_BadgeDoorOpen` | `Door open` | Animals tab hutch row: badge when the hutch door is open | 12 |
| `UI_ZeD_Animals_BadgeHatchOpen` | `Hatch open` | Animals tab hutch row: badge when the egg hatch door is open | 12 |
| `UI_ZeD_Animals_BadgeOnHook` | `On hook` | Animals tab butcher hook row: badge when an animal hangs on the hook | 12 |
| `UI_ZeD_Animals_BadgeShut` | `Shut` | Animals tab hutch row badge (the hutch is closed) and Vehicle tab trailer summary (the trunk lid is shut) | 10 |
| `UI_ZeD_Animals_BtnCreateZone` | `+ Create zone` | Animals tab ranch overview, footer: button that starts drawing a new livestock zone | 18 |
| `UI_ZeD_Animals_CountSpecies` | `%1 %2` | Animals tab zone card: one species in the breakdown line (%1 = how many, %2 = species name), e.g. "3 Cow" | 24 |
| `UI_ZeD_Animals_CreateZoneHint` | `Create an Animal zone to get started` | Animals tab ranch overview, footer: hint next to the Create zone button | 50 |
| `UI_ZeD_Animals_CreateZoneTitle` | `CREATE LIVESTOCK ZONE` | Animals tab, zone drawing mode: heading band at the top | 32 |
| `UI_ZeD_Animals_Dis_Anxious_Desc` | `Stresses easily` | Animals tab animal view, Genetics: one-line explanation under the Anxious badge | 40 |
| `UI_ZeD_Animals_Dis_Anxious_Label` | `Anxious` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Craven_Desc` | `Flees almost any threat` | Animals tab animal view, Genetics: one-line explanation under the Craven badge | 40 |
| `UI_ZeD_Animals_Dis_Craven_Label` | `Craven` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Dwarfism_Desc` | `Smaller size, shorter life` | Animals tab animal view, Genetics: one-line explanation under the Dwarfism badge | 40 |
| `UI_ZeD_Animals_Dis_Dwarfism_Label` | `Dwarfism` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Fertile_Desc` | `Always breeds successfully` | Animals tab animal view, Genetics: one-line explanation under the Fertile badge | 40 |
| `UI_ZeD_Animals_Dis_Fertile_Label` | `Fertile` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Fragile_Desc` | `Shorter lifespan` | Animals tab animal view, Genetics: one-line explanation under the Fragile badge | 40 |
| `UI_ZeD_Animals_Dis_Fragile_Label` | `Fragile` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Gluttonous_Desc` | `Eats more than average` | Animals tab animal view, Genetics: one-line explanation under the Gluttonous badge | 40 |
| `UI_ZeD_Animals_Dis_Gluttonous_Label` | `Gluttonous` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_LowFertility_Desc` | `Rarely breeds successfully` | Animals tab animal view, Genetics: one-line explanation under the Low Fertility badge | 40 |
| `UI_ZeD_Animals_Dis_LowFertility_Label` | `Low fertility` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_LowMilk_Desc` | `~80%% less milk generation` | Animals tab animal view, Genetics: one-line explanation under the Low Milk badge | 40 |
| `UI_ZeD_Animals_Dis_LowMilk_Label` | `Low milk` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_LowWool_Desc` | `~80%% less wool generation` | Animals tab animal view, Genetics: one-line explanation under the Low Wool badge | 40 |
| `UI_ZeD_Animals_Dis_LowWool_Label` | `Low wool` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_NoEggs_Desc` | `Never lays eggs` | Animals tab animal view, Genetics: one-line explanation under the No Eggs badge | 40 |
| `UI_ZeD_Animals_Dis_NoEggs_Label` | `No eggs` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_NoMilk_Desc` | `Never produces milk` | Animals tab animal view, Genetics: one-line explanation under the No Milk badge | 40 |
| `UI_ZeD_Animals_Dis_NoMilk_Label` | `No milk` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_NoWool_Desc` | `Never grows wool` | Animals tab animal view, Genetics: one-line explanation under the No Wool badge | 40 |
| `UI_ZeD_Animals_Dis_NoWool_Label` | `No wool` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Restless_Desc` | `Wanders farther than average` | Animals tab animal view, Genetics: one-line explanation under the Restless badge | 40 |
| `UI_ZeD_Animals_Dis_Restless_Label` | `Restless` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Skinny_Desc` | `Reduced weight` | Animals tab animal view, Genetics: one-line explanation under the Skinny badge | 40 |
| `UI_ZeD_Animals_Dis_Skinny_Label` | `Skinny` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_SmallEggs_Desc` | `Negligible hunger value` | Animals tab animal view, Genetics: one-line explanation under the Small Eggs badge | 40 |
| `UI_ZeD_Animals_Dis_SmallEggs_Label` | `Small eggs` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Sterile_Desc` | `Cannot breed` | Animals tab animal view, Genetics: one-line explanation under the Sterile badge | 40 |
| `UI_ZeD_Animals_Dis_Sterile_Label` | `Sterile` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Strong_Desc` | `Higher damage when attacking` | Animals tab animal view, Genetics: one-line explanation under the Strong badge | 40 |
| `UI_ZeD_Animals_Dis_Strong_Label` | `Strong` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Dis_Thirsty_Desc` | `Drinks more than average` | Animals tab animal view, Genetics: one-line explanation under the Thirsty badge | 40 |
| `UI_ZeD_Animals_Dis_WeakBirth_Desc` | `Offspring may die at birth` | Animals tab animal view, Genetics: one-line explanation under the Weak Birth badge | 40 |
| `UI_ZeD_Animals_Dis_WeakBirth_Label` | `Weak birth` | Animals tab animal view, Genetics: name of a genetic trait or disorder badge (shown at Animal Care level 7 or 9) | 16 |
| `UI_ZeD_Animals_Eggs` | `Eggs` | Animals tab animal view, Production: label of the eggs row (drawn in capitals) | 10 |
| `UI_ZeD_Animals_EggsPerDay` | `eggs/day` | Animals tab ranch overview, Totals section: unit after the eggs figure | 12 |
| `UI_ZeD_Animals_EligibleCount` | `%1 eligible` | Animals tab butcher view, summary band: how many animals can be butchered | 20 |
| `UI_ZeD_Animals_EstMeat` | `\| ~%1 kg meat` | Animals tab butcher row, second line after the species: estimated meat yield (%1 = kg, one decimal) | 20 |
| `UI_ZeD_Animals_HdrBreeding` | `BREEDING` | Animals tab animal view: section heading for pregnancy, mating and trust | 16 |
| `UI_ZeD_Animals_HdrGenetics` | `GENETICS` | Animals tab animal view: section heading for genetic traits | 16 |
| `UI_ZeD_Animals_HdrProduction` | `PRODUCTION` | Animals tab animal view: section heading for milk, wool and eggs | 16 |
| `UI_ZeD_Animals_HdrVitals` | `VITALS` | Animals tab animal view: section heading | 14 |
| `UI_ZeD_Animals_HookBlood` | `BLOOD %1 L` | Animals tab butcher hook row: blood still to collect in litres (one item of a list; %1 = litres) | 16 |
| `UI_ZeD_Animals_HookLeft` | `%1 LEFT` | Animals tab butcher hook row, second line: what is still on the animal (%1 = the items above joined with " \| ") | 40 |
| `UI_ZeD_Animals_HookNothingLeft` | `NOTHING LEFT` | Animals tab butcher hook row, second line: the animal on the hook has been fully butchered | 16 |
| `UI_ZeD_Animals_HoursAgo` | `%1h ago` | Animals tab animal view, Last milked row: hours since (%1 = hours) | 12 |
| `UI_ZeD_Animals_HutchLine` | `%1 / %2 BIRDS \| %3 EGGS \| DIRT %4` | Animals tab hutch row, second line (%1 birds inside, %2 capacity, %3 eggs, %4 dirtiness as a percentage with its % sign) | 50 |
| `UI_ZeD_Animals_InSeason` | `In season` | Animals tab animal view, Mating row: the animal is in its mating season | 14 |
| `UI_ZeD_Animals_LastMilked` | `LAST MILKED` | Animals tab animal view, Production: label of the row that tells when the animal was last milked | 16 |
| `UI_ZeD_Animals_MalesBadge` | `%1 MALES` | Animals tab zone card: warning badge when 2 or more adult males of a species may fight (%1 = species name) | 24 |
| `UI_ZeD_Animals_Mating` | `Mating` | Animals tab animal view, Breeding: label of the mating season row (drawn in capitals) | 12 |
| `UI_ZeD_Animals_MilkAmount` | `%1/%2 ml` | Animals tab animal view, Milk row: milk held against the most it can hold (%1 held, %2 maximum, in millilitres) | 18 |
| `UI_ZeD_Animals_MilkPerDay` | `milk/day` | Animals tab ranch overview, Totals section: unit after the milk figure | 12 |
| `UI_ZeD_Animals_NoEligible` | `No eligible animals` | Animals tab butcher view: empty-state line when no animal can be butchered | 40 |
| `UI_ZeD_Animals_NoEligibleHint` | `Adults only, excludes pregnant` | Animals tab butcher view: small line under the empty-state line | 50 |
| `UI_ZeD_Animals_NoZones` | `No livestock zones` | Animals tab, ranch overview: empty-state line under the zone icon | 32 |
| `UI_ZeD_Animals_OffSeason` | `Off season` | Animals tab animal view, Mating row: the animal is out of its mating season | 14 |
| `UI_ZeD_Animals_Overview` | `Overview` | Animals tab: breadcrumb text on the zone view (click to go back to the ranch overview) | 20 |
| `UI_ZeD_Animals_PerDay` | `%1/day` | Animals tab animal view, Eggs row: eggs per day (%1 = number with one decimal) | 12 |
| `UI_ZeD_Animals_Pregnancy` | `Pregnancy` | Animals tab animal view, Breeding: label of the pregnancy row (drawn in capitals) | 14 |
| `UI_ZeD_Animals_PregnantPct` | `Pregnant - %1` | Animals tab animal view, Pregnancy bar: pregnancy progress (%1 = percentage with its % sign) | 24 |
| `UI_ZeD_Animals_ProdBone` | `Bone` | Animals tab butcher row: product badge, the animal gives bone (drawn in capitals) | 10 |
| `UI_ZeD_Animals_ProdFeathers` | `Feathers` | Animals tab butcher row: product badge, the animal gives feathers (drawn in capitals) | 10 |
| `UI_ZeD_Animals_ProdLeather` | `Leather` | Animals tab butcher row: product badge, the animal gives leather (drawn in capitals) | 10 |
| `UI_ZeD_Animals_RemoveZonePrompt` | `Remove zone?` | Animals tab zone view, footer: confirmation prompt next to Yes / No | 24 |
| `UI_ZeD_Animals_Roof` | `Roof` | Animals tab zone card and zone info: label above the roofed-area bar (drawn in capitals) | 8 |
| `UI_ZeD_Animals_Roster` | `Roster` | Animals tab butcher view: heading above the list of animals | 20 |
| `UI_ZeD_Animals_SecAlerts` | `Alerts` | Animals tab ranch overview: collapsible section heading (drawn in capitals, followed by the count) | 14 |
| `UI_ZeD_Animals_SecHooks` | `Hooks` | Animals tab butcher view: section heading above the nearby butcher hooks (drawn in capitals, followed by the count) | 14 |
| `UI_ZeD_Animals_SecHutches` | `Hutches` | Animals tab zone view: section heading above the zone's hutches (drawn in capitals, followed by the count) | 14 |
| `UI_ZeD_Animals_SecTotals` | `Totals` | Animals tab ranch overview: collapsible section heading (drawn in capitals, followed by the count) | 14 |
| `UI_ZeD_Animals_SecTroughs` | `Feeding Troughs` | Animals tab zone view: section heading above the zone's feeding troughs (drawn in capitals, followed by the count) | 24 |
| `UI_ZeD_Animals_SecZones` | `Zones` | Animals tab ranch overview: section heading (drawn in capitals, followed by the count) | 14 |
| `UI_ZeD_Animals_SexF` | `F` | Animals tab butcher row: female, in brackets after the species name, e.g. "Cow (F)" | 2 |
| `UI_ZeD_Animals_SexM` | `M` | Animals tab butcher row: male, in brackets after the species name, e.g. "Cow (M)" | 2 |
| `UI_ZeD_Animals_SortBy` | `Sort: %1` | Animals tab zone view, right end of the roster heading: click to change the sort order (%1 = Name, Species or Alerts) | 26 |
| `UI_ZeD_Animals_SortSpecies` | `Species` | Animals tab zone view: name of the "Species" sort order, shown after "Sort:" | 12 |
| `UI_ZeD_Animals_StressAnxious` | `anxious trait` | Animals tab animal view, Stress row: one reason in the "why stressed" list, the animal has the Anxious trait (lower case) | 24 |
| `UI_ZeD_Animals_StressHunger` | `hunger` | Animals tab animal view, Stress row: small line "-> reasons" under the vitals; one reason in the list (lower case) | 16 |
| `UI_ZeD_Animals_StressMales` | `male-on-male tension` | Animals tab animal view, Stress row: one reason in the "why stressed" list, another adult male of the same species shares the zone (lower case) | 28 |
| `UI_ZeD_Animals_StressMore` | `+%1 more` | Animals tab animal view, Stress row: last item when there are more than three reasons (%1 = how many are left out) | 12 |
| `UI_ZeD_Animals_StressRain` | `rain` | Animals tab animal view, Stress row: one reason in the "why stressed" list, the animal is out in the rain (lower case) | 16 |
| `UI_ZeD_Animals_StressThirst` | `thirst` | Animals tab animal view, Stress row: one reason in the "why stressed" list (lower case) | 16 |
| `UI_ZeD_Animals_StressVehicle` | `moving vehicle` | Animals tab animal view, Stress row: one reason in the "why stressed" list, the animal is in a moving vehicle (lower case) | 24 |
| `UI_ZeD_Animals_StressZombie` | `zombie nearby` | Animals tab animal view, Stress row: one reason in the "why stressed" list, exactly one zombie within 15 tiles (lower case) | 24 |
| `UI_ZeD_Animals_StressZombies` | `%1 zombies nearby` | Animals tab animal view, Stress row: one reason in the "why stressed" list, several zombies within 15 tiles (%1 = how many; lower case) | 26 |
| `UI_ZeD_Animals_StructAnimalsMany` | `%1 ANIMALS` | Animals tab trough row, second line: animals linked to the trough (none or several) | 14 |
| `UI_ZeD_Animals_StructAnimalsOne` | `%1 ANIMAL` | Animals tab trough row, second line: animals linked to the trough (exactly one) | 14 |
| `UI_ZeD_Animals_SubRanch` | `Ranch` | Animals tab: first sub-tab (Ranch / Butcher strip) | 16 |
| `UI_ZeD_Animals_TagLaying` | `Laying` | Animals tab: badge on an animal that is laying eggs (animal row, header; the eggs row shows it in capitals) | 12 |
| `UI_ZeD_Animals_TagMilkable` | `Milkable` | Animals tab: green badge on an animal that can be milked (animal row and header) | 14 |
| `UI_ZeD_Animals_TagUdderUrgent` | `Udder URGENT` | Animals tab: red badge on an animal whose udder is over full (animal row and header) | 16 |
| `UI_ZeD_Animals_TagWoolReady` | `Wool ready` | Animals tab: green badge on an animal that can be sheared (animal row and header) | 14 |
| `UI_ZeD_Animals_ThirstDehydrated` | `Dehydrated` | Animals tab animal view, Thirst row: severe thirst | 14 |
| `UI_ZeD_Animals_ThirstHydrated` | `Hydrated` | Animals tab animal view, Thirst row: value when the animal is not thirsty (skill level too low for numbers) | 14 |
| `UI_ZeD_Animals_ThirstParched` | `Parched` | Animals tab animal view, Thirst row: mild thirst | 14 |
| `UI_ZeD_Animals_TilesMany` | `%1 TILES` | Animals tab hook row, second line: distance to the hook (none or several tiles) | 12 |
| `UI_ZeD_Animals_TilesOne` | `%1 TILE` | Animals tab hook row, second line: distance to the hook (exactly one tile) | 12 |
| `UI_ZeD_Animals_TroughFeed` | `FEED %1` | Animals tab trough row, second line: amount of feed held (%1 = amount) | 20 |
| `UI_ZeD_Animals_TroughWater` | `WATER %1 / %2 L` | Animals tab trough row, second line: water held against capacity in litres (%1 = held, %2 = capacity) | 24 |
| `UI_ZeD_Animals_Trust` | `Trust` | Animals tab animal view, Breeding: label of the row showing how much the animal trusts the player (drawn in capitals) | 12 |
| `UI_ZeD_Animals_TrustCall` | `Can call` | Animals tab animal view, Trust row: small hint beside the number, trust is high enough to call the animal | 14 |
| `UI_ZeD_Animals_TrustNone` | `Untrusting` | Animals tab animal view, Trust row: small hint beside the number, trust is too low | 14 |
| `UI_ZeD_Animals_TrustPet` | `Can pet` | Animals tab animal view, Trust row: small hint beside the number, trust is high enough to pet | 14 |
| `UI_ZeD_Animals_TypeNewName` | `Type new name` | Animals tab zone view, footer while renaming a zone: hint next to the Yes / No / Reset buttons | 30 |
| `UI_ZeD_Animals_UnnamedZone` | `Unnamed Zone` | Animals tab: zone card title when a zone has no name | 30 |
| `UI_ZeD_Animals_WeightKg` | `%1 kg` | Animals tab animal view, header: weight (%1 = number with one decimal) | 12 |
| `UI_ZeD_Animals_YieldSummary` | `Est. %1 kg meat  \|  %2 kg total weight` | Animals tab butcher view, summary band: estimated meat and total weight of all eligible animals (%1 meat, %2 weight, in kg, one decimal) | 60 |
| `UI_ZeD_Animals_ZoneAutoName` | `Livestock Zone #%1` | Animals tab: default name given to a new livestock zone (editable; the number is the next free one) | 30 |
| `UI_ZeD_Animals_ZoneDrawHint` | `Click and drag on the ground to draw your zone rectangle.` | Animals tab, zone drawing (waiting to start): instruction line | 70 |
| `UI_ZeD_Animals_ZoneReleaseHint` | `Release to set zone` | Animals tab, zone drawing footer while dragging: hint next to Cancel | 30 |
| `UI_ZeD_Animals_ZoneSizeLimits` | `Min %1x%1, max %2x%2 tiles` | Animals tab, zone drawing (waiting to start): size limits line (%1 = smallest side, %2 = largest side, in tiles) | 40 |
| `UI_ZeD_Animals_ZoneSquares` | `%1 sq.` | Animals tab zone view, info band: zone area in tiles, beside the zone name | 12 |

## Appliance

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Appliance_Empty` | `Empty` | Craft tab, oven or microwave: line when nothing is inside | 16 |
| `UI_ZeD_Appliance_InMicrowave` | `IN THE MICROWAVE` | Craft tab, microwave: section heading above the food inside | 28 |
| `UI_ZeD_Appliance_InOven` | `IN THE OVEN` | Craft tab, oven: section heading above the food inside | 28 |
| `UI_ZeD_Appliance_Left` | `%1 LEFT` | Craft tab, microwave state line: time remaining (%1 is like 1:30) | 12 |
| `UI_ZeD_Appliance_MinLeft` | `%1 MIN LEFT` | Craft tab, oven state line: minutes remaining | 14 |
| `UI_ZeD_Appliance_MinShort` | `%1m` | Craft tab, oven or microwave food row: minutes left, after the bar (short) | 6 |
| `UI_ZeD_Appliance_NoPower` | `NO POWER` | Craft tab, oven or microwave: line under the plate when unpowered | 12 |
| `UI_ZeD_Appliance_PowerHi` | `HI` | Craft tab, microwave state line: power level 5 of 5 | 8 |
| `UI_ZeD_Appliance_PowerLo` | `LO` | Craft tab, microwave state line: power level 1 of 5 | 8 |
| `UI_ZeD_Appliance_PowerMed` | `MED` | Craft tab, microwave state line: power level 3 of 5 | 8 |
| `UI_ZeD_Appliance_PowerMedHi` | `MED-HI` | Craft tab, microwave state line: power level 4 of 5 | 8 |
| `UI_ZeD_Appliance_PowerMedLo` | `MED-LO` | Craft tab, microwave state line: power level 2 of 5 | 8 |
| `UI_ZeD_Appliance_Raw` | `RAW` | Craft tab, oven or microwave: tag on a raw food row | 10 |
| `UI_ZeD_Appliance_Set` | `%1 SET` | Craft tab, microwave state line: time set while off (%1 is like 1:30) | 12 |
| `UI_ZeD_Appliance_SetHeat` | `SET %1` | Craft tab, oven state line: heat that is set while off (%1 is like 200Â°C) | 14 |
| `UI_ZeD_Appliance_TimerMin` | `TIMER %1 MIN` | Craft tab, oven state line: timer set while off | 14 |

## Belt

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Belt_BestLight` | `Best light: %1` | Belt HUD, controller list row for the best light; %1 = the light's name | 40 |
| `UI_ZeD_Belt_Both` | `BOTH` | Belt HUD, foot of the off hand when the main hand holds a two-handed item | 8 |
| `UI_ZeD_Belt_InBags` | `IN YOUR BAGS` | Belt HUD, header of the controller list of weapons and lights in the bags | 20 |
| `UI_ZeD_Belt_InHand` | `IN HAND` | Belt HUD, foot of a slot whose item is in a hand | 8 |
| `UI_ZeD_Belt_Replace` | `REPLACE %1` | Belt HUD, chip over a full slot while dragging an item onto it; %1 = the item now there, in capitals | 40 |
| `UI_ZeD_Belt_SlotAnkle` | `ANKLE` | Belt HUD, name printed inside an empty ankle holster slot box | 9 |
| `UI_ZeD_Belt_SlotBeltL` | `BELT L` | Belt HUD, name printed inside an empty hotbar slot box (waist belt, left) | 9 |
| `UI_ZeD_Belt_SlotBeltR` | `BELT R` | Belt HUD, name printed inside an empty hotbar slot box (waist belt, right) | 9 |
| `UI_ZeD_Belt_SlotHolster` | `HOLSTER` | Belt HUD, name printed inside an empty holster slot box | 9 |
| `UI_ZeD_Belt_SlotHolsterL` | `HOLSTER L` | Belt HUD, name printed inside an empty left holster slot box | 9 |
| `UI_ZeD_Belt_SlotKey` | `%1 \| KEY %2` | Belt HUD, chip above a hovered slot; %1 = the slot's name in capitals, %2 = the key bound to it | 40 |
| `UI_ZeD_Belt_SlotPack` | `PACK` | Belt HUD, name printed inside an empty bedroll / pack slot box | 9 |
| `UI_ZeD_Belt_SlotShoulder` | `SHOULDER` | Belt HUD, name printed inside an empty shoulder holster slot box | 9 |
| `UI_ZeD_Belt_SlotWebL` | `WEB L` | Belt HUD, name printed inside an empty webbing slot box (left) | 9 |
| `UI_ZeD_Belt_SlotWebR` | `WEB R` | Belt HUD, name printed inside an empty webbing slot box (right) | 9 |
| `UI_ZeD_Belt_Tag` | `BELT %1` | Inventory lists, tag on an item attached to the belt; %1 = the slot's key (1 to 8) | 10 |
| `UI_ZeD_Belt_Watch` | `WATCH` | Belt HUD, chip over the mini watch when the item has no name | 14 |
| `UI_ZeD_Belt_WatchFull` | `%1 \| FULL WATCH` | Belt HUD, chip over the mini watch's face when the full watch is closed; %1 = watch name in capitals | 40 |
| `UI_ZeD_Belt_WatchLight` | `LIGHT` | Belt HUD, chip over the mini watch's light button | 10 |
| `UI_ZeD_Belt_WatchSpeed` | `SPEED \| %1X` | Belt HUD, chip over the mini watch's speed button; %1 = the game speed multiplier (1, 2, 3) | 14 |
| `UI_ZeD_Belt_WatchStart` | `START` | Belt HUD, chip over the mini watch's start / pause button while the game is paused | 10 |
| `UI_ZeD_Belt_WatchTuck` | `%1 \| TUCK AWAY` | Belt HUD, chip over the mini watch's face when the full watch is open; %1 = watch name in capitals | 40 |

## Card

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Card_Any` | `Any` | Reading Facts: value of Level Range when a book has no level limits | 10 |
| `UI_ZeD_Card_ChipDispose` | `Dispose` | Item card, chip that marks an item as unwanted | 10 |
| `UI_ZeD_Card_ChipFav` | `Fav` | Item card, chip that marks an item favourite | 6 |
| `UI_ZeD_Card_ChipNoCraft` | `No-craft` | Item card, chip that keeps an item out of recipes | 10 |
| `UI_ZeD_Card_Combat` | `Combat` | Item card top stats (clothing): combat speed modifier row label (shown in capitals) | 10 |
| `UI_ZeD_Card_CondLossHit` | `Cond loss / hit` | Defense Facts: how much condition the garment loses per hit (wide card) | 20 |
| `UI_ZeD_Card_Cotton` | `Cotton` | Item card, clothing: fabric shown when the garment names none | 10 |
| `UI_ZeD_Card_CritPct` | `Critical %%` | Combat Facts: critical hit chance of a weapon | 22 |
| `UI_ZeD_Card_Fabric` | `Fabric` | Item card top stats (clothing): fabric row label (shown in capitals) | 10 |
| `UI_ZeD_Card_Facts` | `Facts` | Item card: title of a facts panel that names no title | 14 |
| `UI_ZeD_Card_FactsCombat` | `Combat Facts` | Item card (weapons): title of the combat panel | 22 |
| `UI_ZeD_Card_FactsContainer` | `Container Facts` | Item card (containers): title of the container panel | 22 |
| `UI_ZeD_Card_FactsDefense` | `Defense Facts` | Item card (clothing): title of the defense panel | 22 |
| `UI_ZeD_Card_FactsNutrition` | `Nutrition Facts` | Item card (food): title of the nutrition panel, styled like a nutrition label | 24 |
| `UI_ZeD_Card_FactsReading` | `Reading Facts` | Item card (books and magazines): title of the reading panel | 22 |
| `UI_ZeD_Card_FlagDenim` | `DENIM` | Item card, clothing zones (wide card): flag column beside a zone's bar; capitals | 9 |
| `UI_ZeD_Card_FlagFabric` | `FABRIC` | Item card, clothing zones (wide card): flag column beside a zone's bar; capitals | 9 |
| `UI_ZeD_Card_FlagLeather` | `LEATHER` | Item card, clothing zones (wide card): flag column beside a zone's bar; capitals | 9 |
| `UI_ZeD_Card_FlagTorn` | `TORN` | Item card, clothing zones (wide card): flag column beside a zone's bar; capitals | 9 |
| `UI_ZeD_Card_FlagWorn` | `WORN` | Item card, clothing zones (wide card): flag column beside a zone's bar; capitals | 9 |
| `UI_ZeD_Card_Happiness` | `Happiness` | Nutrition Facts: change to happiness from the food | 22 |
| `UI_ZeD_Card_HungerReduction` | `Hunger reduction` | Nutrition Facts: how much eating the food lowers hunger | 22 |
| `UI_ZeD_Card_Items` | `Items` | Item card: number of items inside a container (top stats row and the Container Facts panel) | 10 |
| `UI_ZeD_Card_Kind` | `Kind` | Item card top stats: the item's category row label (shown in capitals) | 10 |
| `UI_ZeD_Card_Knockback` | `Knockback` | Combat Facts: knockback power of a weapon | 22 |
| `UI_ZeD_Card_Level` | `Level` | Item card top stats (books): skill level range row label (shown in capitals) | 10 |
| `UI_ZeD_Card_LevelRange` | `Level range` | Reading Facts: the skill levels a book is useful for | 22 |
| `UI_ZeD_Card_Marked` | `MARKED` | Item card, label before the three mark chips (Fav, No-craft, Dispose) | 10 |
| `UI_ZeD_Card_NeckProt` | `Neck protection` | Defense Facts: neck protection row label (wide card) | 20 |
| `UI_ZeD_Card_NeedWhetstone` | `Needs a whetstone or a file` | Note over the character's head when SHARPEN is pressed with no whetstone or file | 36 |
| `UI_ZeD_Card_NoWaterInReach` | `No water in reach` | Note over the character's head when WASH is pressed with no water within two tiles | 28 |
| `UI_ZeD_Card_OneInN` | `1-in-N degrade` | Defense Facts: sub-row, the chance one in N hits wears the garment (wide card) | 20 |
| `UI_ZeD_Card_Progress` | `Progress` | Item card: reading progress row label (top stats and the Reading Facts panel) | 12 |
| `UI_ZeD_Card_Raw` | `Raw` | Item card top stats (food): value of the Cooked row for a food that is dangerous uncooked | 10 |
| `UI_ZeD_Card_Reach` | `Reach` | Item card top stats (weapons): reach row label (shown in capitals) | 10 |
| `UI_ZeD_Card_Read` | `Read` | Reading Facts: row label, whether you have already read this book (value Yes or No) | 14 |
| `UI_ZeD_Card_Run` | `Run` | Item card top stats (clothing): run speed modifier row label (shown in capitals) | 10 |
| `UI_ZeD_Card_ShortCondHit` | `Cond / hit` | Defense Facts, narrow card: short label for Cond Loss / Hit | 11 |
| `UI_ZeD_Card_ShortNeckProt` | `Neck prot.` | Defense Facts, narrow card: short label for Neck Protection | 11 |
| `UI_ZeD_Card_ShortOneInN` | `1-in-N` | Defense Facts, narrow card: short label for the 1-in-N sub-row | 9 |
| `UI_ZeD_Card_ShortWaterRes` | `Water res.` | Defense Facts, narrow card: short label for Water Resistance | 11 |
| `UI_ZeD_Card_ShortWind` | `Wind` | Defense Facts, narrow card: short label for Wind Resistance | 9 |
| `UI_ZeD_Card_SicknessRisk` | `Sickness risk` | Nutrition Facts: chance of illness from the food | 22 |
| `UI_ZeD_Card_Swing` | `Swing` | Combat Facts: swing time of a weapon | 22 |
| `UI_ZeD_Card_ThirstReduction` | `Thirst reduction` | Nutrition Facts: how much eating the food lowers thirst | 22 |
| `UI_ZeD_Card_VerbEquip` | `Equip` | Item card header button: put on or hold the item | 10 |
| `UI_ZeD_Card_VerbOffHand` | `Off hand` | Item card header button: hold a weapon in the second hand | 10 |
| `UI_ZeD_Card_VerbPad` | `Pad` | Item card button strip (clothing): add padding to every unpadded zone | 10 |
| `UI_ZeD_Card_VerbSharpen` | `Sharpen` | Item card button strip (blades): sharpen the weapon | 10 |
| `UI_ZeD_Card_VerbUse` | `Use` | Item card header button: use a drainable item (flashlight battery, lighter...) | 10 |
| `UI_ZeD_Card_WeightReduce` | `Weight reduce` | Item card top stats (containers): weight reduction row label, narrow column (shown in capitals) | 10 |
| `UI_ZeD_Card_WeightReduction` | `Weight reduction` | Container Facts: how much a container lightens its contents | 22 |
| `UI_ZeD_Card_WetPct` | `WET %1` | Item card, clothing: chip for a wet garment; %1 is the wetness with its percent sign, e.g. 40% | 12 |
| `UI_ZeD_Card_ZoneFoot` | `FOOT` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |
| `UI_ZeD_Card_ZoneHand` | `HAND` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |
| `UI_ZeD_Card_ZoneLeft` | `Left` | Item card, clothing zones: the side word before a zone's bar (Left arm, Left thigh...) | 6 |
| `UI_ZeD_Card_ZoneLower` | `Lower` | Item card, clothing zones: the torso row 'Lower' under the TORSO heading | 6 |
| `UI_ZeD_Card_ZoneLowerArm` | `LOWER ARM` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |
| `UI_ZeD_Card_ZoneOther` | `OTHER` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |
| `UI_ZeD_Card_ZoneRight` | `Right` | Item card, clothing zones: the side word before a zone's bar (Right arm, Right thigh...) | 6 |
| `UI_ZeD_Card_Zones` | `ZONES` | Item card, clothing: heading of the zones section (shown in capitals) | 8 |
| `UI_ZeD_Card_ZoneShin` | `SHIN` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |
| `UI_ZeD_Card_ZoneThigh` | `THIGH` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |
| `UI_ZeD_Card_ZoneTorso` | `TORSO` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |
| `UI_ZeD_Card_ZoneUpper` | `Upper` | Item card, clothing zones: the torso row 'Upper' under the TORSO heading | 6 |
| `UI_ZeD_Card_ZoneUpperArm` | `UPPER ARM` | Item card, clothing zones: group heading over the zone rows (shown in capitals) | 12 |

## Char

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Char_ContainersMany` | `%1 containers` | Character window: window title when the multi-column loot view shows several columns | 20 |
| `UI_ZeD_Char_ContainersOne` | `%1 container` | Character window: window title when the multi-column loot view shows one column | 20 |
| `UI_ZeD_Char_ItemsMany` | `%1 items` | Character window, Loot tab: column header, small text under the weight; the container holds several items (0 or 2+) | 14 |
| `UI_ZeD_Char_ItemsOne` | `%1 item` | Character window, Loot tab: column header, small text under the weight; the container holds one item | 14 |
| `UI_ZeD_Char_JournalSearchEntries` | `Search entries...` | Character window, Journal tab: placeholder in the search box over the entries list | 24 |
| `UI_ZeD_Char_JournalWrite` | `Write something...` | Character window, Journal tab: placeholder text in the entry box where the character writes a note | 30 |
| `UI_ZeD_Char_PinLevel` | `%1 - Lv.%2 - %3` | Character window: title bar readout of a pinned skill; %1 is the skill name, %2 its level, %3 the XP progress such as 150/300 | 40 |
| `UI_ZeD_Char_PinMax` | `%1 - Lv.10` | Character window: title bar readout of a pinned skill at the top level; %1 is the skill name | 28 |
| `UI_ZeD_Char_SortDist` | `DIST` | Character window, container strip (narrow vertical bar of container buttons): label of the sort button under the active container; clicking cycles the three - sort by distance (capitals; the strip is about 36 px wide) | 5 |
| `UI_ZeD_Char_SortType` | `TYPE` | Character window, container strip (narrow vertical bar of container buttons): label of the sort button under the active container; clicking cycles the three - sort by type (capitals) | 5 |
| `UI_ZeD_Char_SortWt` | `WT` | Character window, container strip (narrow vertical bar of container buttons): label of the sort button under the active container; clicking cycles the three - sort by weight (capitals) | 5 |
| `UI_ZeD_Char_TabEquipment` | `Equipment` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') | 14 |
| `UI_ZeD_Char_TabIdentity` | `Identity` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab'); also the pinned heading of the Identity drawer | 14 |
| `UI_ZeD_Char_TabJournal` | `Journal` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') | 14 |
| `UI_ZeD_Char_TabLoot` | `Loot` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') (the inventory and the containers around) | 14 |
| `UI_ZeD_Char_TabRadio` | `Radio` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') (only shown while the character has a radio) | 14 |
| `UI_ZeD_Char_TabThermal` | `Thermal` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab'); also the pinned heading of the Thermal drawer | 14 |
| `UI_ZeD_Char_WeightOfMax` | `%1/%2kg` | Character window, Loot tab: column header, weight carried over capacity, small text above the item count; %1 is the weight (one decimal), %2 the capacity | 16 |
| `UI_ZeD_Char_Window` | `Character` | Character window: the title the window is created with, before it shows the character's name (barely seen) | 20 |

## Controls

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Controls_DeleteAskMany` | `Delete all %1 items for good?` | World window trash can row, confirmation question (several items) | - |
| `UI_ZeD_Controls_DeleteAskOne` | `Delete all %1 item for good?` | World window trash can row, confirmation question (one item) | - |
| `UI_ZeD_Controls_HintNearby` | `Each kind into a nearby container that holds it` | Character window container row, hover hint on nearby button | - |
| `UI_ZeD_Controls_HintPutInKinds` | `Put in the kinds it already holds` | Character window container row, hover hint on Same type | - |
| `UI_ZeD_Controls_HintTakeKinds` | `Take the kinds you already carry` | World window container row, hover hint on Same type | - |
| `UI_ZeD_Controls_HintToFloor` | `Everything to the floor` | World window container row, hover hint on To floor | - |
| `UI_ZeD_Controls_InsertTank` | `Insert tank` | World window container row, propane barbecue button | 14 |
| `UI_ZeD_Controls_PutOut` | `Put out` | World window container row, campfire hover hint | 12 |
| `UI_ZeD_Controls_RemoveTank` | `Remove tank` | World window container row, propane barbecue button | 14 |
| `UI_ZeD_Controls_SameType` | `Same type` | Container row button hint (both windows) | 14 |
| `UI_ZeD_Controls_SameTypeNearby` | `Same type, all nearby` | Character window container row, hover hint | - |
| `UI_ZeD_Controls_TakeApart` | `Take apart` | World window container row, campfire button | 14 |
| `UI_ZeD_Controls_ToFloor` | `To floor` | World window container row button | 14 |

## Craft

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Craft_AllRecipes` | `All Recipes` | Craft, Build and Journal tabs: section heading above the full recipe list | 20 |
| `UI_ZeD_Craft_AltOther` | `OTHER COMPATIBLE` | Craft and Build tabs, alternatives list: heading above items you do not carry | 24 |
| `UI_ZeD_Craft_AltOwned` | `OWNED` | Craft and Build tabs, alternatives list: heading above items you carry | 20 |
| `UI_ZeD_Craft_BadgeKnown` | `KNOWN` | Recipe card: badge when you know the recipe | 10 |
| `UI_ZeD_Craft_BadgeNeeds` | `NEEDS %1` | Craft tab, recipe card: badge naming the station a recipe needs; %1 is a short station name like KILN | 16 |
| `UI_ZeD_Craft_BadgeUnknown` | `UNKNOWN` | Recipe card: badge when you do not know the recipe | 10 |
| `UI_ZeD_Craft_Compatible` | `Compatible` | Craft and Build tabs: fixed label in the category box while choosing an alternative ingredient | 18 |
| `UI_ZeD_Craft_FilterAlts` | `Filter alternatives...` | Craft and Build tabs: search box placeholder while choosing an alternative ingredient | - |
| `UI_ZeD_Craft_FindRecipe` | `Find recipe magazine or schematic` | Journal recipe card: hint for a recipe that must be learned from a magazine | - |
| `UI_ZeD_Craft_HowToLearn` | `HOW TO LEARN` | Journal recipe card: section heading above skill requirements | 20 |
| `UI_ZeD_Craft_Known` | `Known` | Craft, Build and Journal tabs: sort button, and the Show toggle value (recipes you know) | 10 |
| `UI_ZeD_Craft_NoAlts` | `No alternatives found` | Craft and Build tabs, alternatives list: empty state | - |
| `UI_ZeD_Craft_NoneWithin` | `None within %1 tiles.` | Craft tab, recipe card: second line when no needed station is near | - |
| `UI_ZeD_Craft_Pinned` | `Pinned` | Craft and Build tabs: section heading above pinned recipes | 20 |
| `UI_ZeD_Craft_Required` | `REQUIRED` | Recipe card: section heading above the ingredients | 20 |
| `UI_ZeD_Craft_Results` | `Results` | Craft, Build and Journal tabs: section heading above search results | 20 |
| `UI_ZeD_Craft_ShowAll` | `All` | Craft, Build and Journal tabs: value in the Show toggle (every recipe) | 8 |
| `UI_ZeD_Craft_ShowReady` | `Ready` | Craft and Build tabs: value in the Show toggle (recipes you can make now) | 8 |
| `UI_ZeD_Craft_ShowToggle` | `Show: %1` | Craft, Build and Journal tabs: the button that cycles which recipes are listed; %1 is Ready, Known or All | 16 |
| `UI_ZeD_Craft_SkillLevel` | `%1 Level %2` | Journal recipe card: a skill requirement, e.g. Carpentry Level 3 | - |
| `UI_ZeD_Craft_SortCraftable` | `Craftable` | Craft, Build and Journal tabs: sort button | 12 |
| `UI_ZeD_Craft_SortFreq` | `Freq` | Craft and Build tabs: sort button (most used recipes) | 8 |
| `UI_ZeD_Craft_SortName` | `Name` | Craft, Build and Journal tabs: sort button | 8 |
| `UI_ZeD_Craft_SortRecent` | `Recent` | Craft and Build tabs: sort button (recently made recipes) | 10 |
| `UI_ZeD_Craft_TagFuel` | `FUEL` | Craft tab, recipe card: small tag on a fuel ingredient | 6 |
| `UI_ZeD_Craft_TimeMinSec` | `%1m%2s` | Recipe card: badge with the time a craft takes (minutes and seconds) | 10 |
| `UI_ZeD_Craft_TimeSec` | `%1s` | Recipe card: badge with the time a craft takes (seconds) | 8 |
| `UI_ZeD_Craft_UseStation` | `Use %1` | Craft tab, recipe card: button that binds the nearby station; %1 is the station name in lower case | 24 |

## Credits

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Credits_PromptFast` | `Fast` | Credits screen: controller prompt (X button) that speeds the roll up | 10 |
| `UI_ZeD_Credits_PromptRewind` | `Rewind` | Credits screen: controller prompt (Y button) that rolls the credits backwards | 10 |
| `UI_ZeD_Credits_Title` | `Project Zomboid  +  Credits` | Credits screen: title bar. The + is the ZeD title separator | - |

## CtxMenu

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_CtxMenu_Back` | `< Back` | Right-click menu, the first cell inside a submenu: its name in the floating label | 14 |
| `UI_ZeD_CtxMenu_BackBody` | `Return to previous level.` | Right-click menu, the Back cell's description in the info bubble | - |

## Curtain

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Curtain_Unroll` | `Unroll` | Controller prompt for A over a rolled-up window's tab | 14 |

## Dash

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Dash_ClimateAc` | `A/C` | Dashboard climate readout (pixel face): air conditioning on | 5 |
| `UI_ZeD_Dash_ClimateAuto` | `AUTO` | Dashboard climate readout (pixel face): heater on without A/C | 5 |
| `UI_ZeD_Dash_ClimateFan` | `FAN%1` | Dashboard climate readout (pixel face): fan speed; %1 = the speed (0 to 4), no space | 6 |
| `UI_ZeD_Dash_ClimateOff` | `OFF` | Dashboard climate readout (pixel face): climate off | 5 |
| `UI_ZeD_Dash_HintAb` | `A %1  B %2` | Dashboard top edge (pixel face, controller only): A and B actions of the focused control; %1 = A action, %2 = B action | 46 |
| `UI_ZeD_Dash_HintAxb` | `A %1  X %2  B %3` | Dashboard top edge (pixel face, controller only): A, X and B actions of the focused control; %1 = A action, %2 = X action, %3 = B action | 46 |
| `UI_ZeD_Dash_HintReenter` | `Dash: re-enter the seat to focus` | Dashboard top edge (pixel face, controller only): shown when no control has focus | 46 |
| `UI_ZeD_Dash_Passenger` | `PASSENGER` | Dashboard top edge (pixel face) when the player is not the driver | 12 |
| `UI_ZeD_Dash_PromptAc` | `A/C` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptAcOff` | `A/C off` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptChannelMinus` | `Channel -` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptChannelPlus` | `Channel +` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptChooseDisc` | `Choose a disc` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptClimateOff` | `Climate off` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptCooler` | `Cooler` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptCruiseOff` | `Cruise off` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptCruiseSet` | `Cruise set` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptDefrost` | `Defrost` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptDrive` | `Drive` | Dashboard controller prompt: B button hands the controller back to driving | 14 |
| `UI_ZeD_Dash_PromptEject` | `Eject` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptFanMinus` | `Fan -` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptFanPlus` | `Fan +` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptHeaterOff` | `Heater off` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptHeaterOn` | `Heater on` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptInsertKey` | `Insert key` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptLightsOff` | `Lights off` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptLightsOn` | `Lights on` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptLock` | `Lock` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptMute` | `Mute` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptNoKey` | `No key` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptPlayStop` | `Play / stop` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptPreset` | `Preset` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptPress` | `Press` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptRadioOff` | `Radio off` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptRadioOn` | `Radio on` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptRadioUp` | `Radio up close` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptRemoveKey` | `Remove key` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptScan` | `Scan` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptSeek` | `Seek` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptSeekBack` | `Seek back` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptSiren` | `Siren` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptSoundOn` | `Sound on` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptStart` | `Start` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptStore` | `Store` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptStoreChannel` | `Store channel` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptTuneMinus` | `Tune -` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptTunePlus` | `Tune +` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptUnlock` | `Unlock` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptVolumePlus` | `Volume +` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_PromptWarmer` | `Warmer` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face) | 16 |
| `UI_ZeD_Dash_UnitCab` | `%1 - CAB %2` | Dashboard badge: a taxi's unit line; %1 = the fleet name, %2 = the number | 22 |
| `UI_ZeD_Dash_UnitEngine` | `%1 - ENGINE %2` | Dashboard badge: a fire engine's unit line; %1 = the fleet name, %2 = the number | 22 |
| `UI_ZeD_Dash_UnitUnit` | `%1 - UNIT %2` | Dashboard badge: any other fleet car's unit line; %1 = the fleet name, %2 = the number | 22 |

## Death

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Death_AreYouSure` | `Are you sure?` | Death screen, question after pressing Shut down | 30 |
| `UI_ZeD_Death_BestSkills` | `Best skills` | Death screen record, bold heading above the best skills | 24 |
| `UI_ZeD_Death_Died` | `%1 died.` | Death screen, heading (%1 is the character's name) | - |
| `UI_ZeD_Death_KillExplosion` | `Explosion` | Death screen record, kills by explosion (followed by a count) | 14 |
| `UI_ZeD_Death_KillFire` | `Fire` | Death screen record, kills by fire (followed by a count) | 14 |
| `UI_ZeD_Death_Kills` | `Kills` | Death screen record, bold heading above the kills by kind | 24 |
| `UI_ZeD_Death_KillVehicle` | `Vehicle` | Death screen record, kills by vehicle (followed by a count) | 14 |
| `UI_ZeD_Death_LastLine` | `The last line in the log` | Death screen record, bold heading above the journal's last entry | 40 |
| `UI_ZeD_Death_MainMenu` | `Main menu` | Death screen, button that returns to the main menu | 18 |
| `UI_ZeD_Death_Restart` | `Restart` | Death screen, button that continues with a new character | 18 |
| `UI_ZeD_Death_ShutDown` | `Shut down` | Death screen, button that quits to desktop (also the confirm button) | 18 |
| `UI_ZeD_Death_When` | `%1 %2, %3, %4.` | Death screen, date and time line under the character's name (%1 month name, %2 day, %3 year, %4 time such as 08:30) | - |

## DescEdit

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_DescEdit_AddBlock` | `ADD A BLOCK` | Description editor: heading over the palette of block types (small caps heading) | 14 |
| `UI_ZeD_DescEdit_AddSection` | `ADD A SECTION` | Description editor: heading over the list of ready-made sections (small caps heading) | 16 |
| `UI_ZeD_DescEdit_AskKeep` | `Keep the changes to the description?` | Description editor: question in the action strip when leaving with changes | - |
| `UI_ZeD_DescEdit_Count` | `%1 of %2 characters` | Description editor: action strip: how much of Steam's limit is used. %1 characters now, %2 the limit (both with thousands commas) | - |
| `UI_ZeD_DescEdit_CountOver` | `%1 of %2 characters: too long for Steam` | Description editor: action strip: same, when over the limit | - |
| `UI_ZeD_DescEdit_DefaultTitle` | `Your mod` | Description editor: the heading a brand-new description starts with when the mod has no name yet | - |
| `UI_ZeD_DescEdit_Discard` | `Discard` | Description editor: button that drops the changes to the description | 12 |
| `UI_ZeD_DescEdit_Empty` | `Empty. Add a block from the left.` | Description editor: middle column when the description has no blocks | - |
| `UI_ZeD_DescEdit_HintBold` | `Bold` | Description editor: hover hint of the B button | - |
| `UI_ZeD_DescEdit_HintItalic` | `Italic` | Description editor: hover hint of the I button | - |
| `UI_ZeD_DescEdit_HintLink` | `Link: put the address after the =` | Description editor: hover hint of the LINK button | - |
| `UI_ZeD_DescEdit_HintRemove` | `Remove this block` | Description editor: hover hint of a block's X button | - |
| `UI_ZeD_DescEdit_HintStrike` | `Strike through` | Description editor: hover hint of the S button | - |
| `UI_ZeD_DescEdit_HintUnderline` | `Underline` | Description editor: hover hint of the U button | - |
| `UI_ZeD_DescEdit_HowLink` | `The address on the first line, the words to show on the second` | Description editor: hint under a picked link block | - |
| `UI_ZeD_DescEdit_HowList` | `One point per line` | Description editor: hint under a picked list block | - |
| `UI_ZeD_DescEdit_HowNumbered` | `One step per line` | Description editor: hint under a picked numbered list block | - |
| `UI_ZeD_DescEdit_HowPicture` | `The picture's address (Steam shows pictures from the web)` | Description editor: hint under a picked picture block | - |
| `UI_ZeD_DescEdit_HowTable` | `One row per line, cells split by " \| "; the first row is the header` | Description editor: hint under a picked table block (keep the " \| " separator) | - |
| `UI_ZeD_DescEdit_KindCode` | `CODE` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindDivider` | `DIVIDER` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindHeading` | `HEADING` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindLink` | `LINK` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindList` | `LIST` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindNumbered` | `NUMBERED LIST` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindPicture` | `PICTURE` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindQuote` | `QUOTE` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindSpoiler` | `SPOILER` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindTable` | `TABLE` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindText` | `TEXT` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_MarkBold` | `B` | Description editor: small button that puts bold codes at the cursor (one letter) | 2 |
| `UI_ZeD_DescEdit_MarkItalic` | `I` | Description editor: small button that puts italic codes at the cursor (one letter) | 2 |
| `UI_ZeD_DescEdit_MarkLink` | `LINK` | Description editor: small button on a picked text block that puts a link code at the cursor | 6 |
| `UI_ZeD_DescEdit_MarkStrike` | `S` | Description editor: small button that puts strike-through codes at the cursor (one letter) | 2 |
| `UI_ZeD_DescEdit_MarkUnderline` | `U` | Description editor: small button that puts underline codes at the cursor (one letter) | 2 |
| `UI_ZeD_DescEdit_NoAddress` | `no address yet` | Description editor: preview of a picture block with no web address typed | - |
| `UI_ZeD_DescEdit_PalCode` | `Code` | Description editor: palette button that adds a code block | 12 |
| `UI_ZeD_DescEdit_PalDivider` | `Divider` | Description editor: palette button that adds a divider block | 12 |
| `UI_ZeD_DescEdit_PalHeading` | `Heading` | Description editor: palette button that adds a heading block | 12 |
| `UI_ZeD_DescEdit_PalLink` | `Link` | Description editor: palette button that adds a link block | 12 |
| `UI_ZeD_DescEdit_PalList` | `List` | Description editor: palette button that adds a list block | 12 |
| `UI_ZeD_DescEdit_PalNumbered` | `Numbered` | Description editor: palette button that adds a numbered block | 12 |
| `UI_ZeD_DescEdit_PalPicture` | `Picture` | Description editor: palette button that adds a picture block | 12 |
| `UI_ZeD_DescEdit_PalQuote` | `Quote` | Description editor: palette button that adds a quote block | 12 |
| `UI_ZeD_DescEdit_PalSpoiler` | `Spoiler` | Description editor: palette button that adds a spoiler block | 12 |
| `UI_ZeD_DescEdit_PalTable` | `Table` | Description editor: palette button that adds a table block | 12 |
| `UI_ZeD_DescEdit_PalText` | `Text` | Description editor: palette button that adds a text block | 12 |
| `UI_ZeD_DescEdit_PicturePreview` | `Picture: %1` | Description editor: preview of a picture block. %1 is the file name or the 'no address yet' text | - |
| `UI_ZeD_DescEdit_Redo` | `Redo` | Description editor: action strip button | 10 |
| `UI_ZeD_DescEdit_SecChangelog` | `Changelog` | Description editor: ready-made section button; also the heading it adds | - |
| `UI_ZeD_DescEdit_SecChangelogBody` | `1.0: first release` | Description editor: the point the Changelog section starts with | - |
| `UI_ZeD_DescEdit_SecCompat` | `Compatibility` | Description editor: ready-made section button; also the heading it adds | - |
| `UI_ZeD_DescEdit_SecCredits` | `Credits` | Description editor: ready-made section button; also the heading it adds | - |
| `UI_ZeD_DescEdit_SecFeatures` | `Features` | Description editor: ready-made section button; also the heading it adds | - |
| `UI_ZeD_DescEdit_SecFeaturesBody` | `What it does What else it does` | Description editor: the points the Features section starts with | - |
| `UI_ZeD_DescEdit_SecKnownIssues` | `Known issues` | Description editor: ready-made section button; also the heading it adds | - |
| `UI_ZeD_DescEdit_SecLoadOrder` | `Load order` | Description editor: ready-made section button; also the heading it adds | - |
| `UI_ZeD_DescEdit_SecLoadOrderBody` | `This mod Mods that patch it` | Description editor: the steps the Load order section starts with | - |
| `UI_ZeD_DescEdit_SecRequirements` | `Requirements` | Description editor: ready-made section button; also the heading it adds | - |
| `UI_ZeD_DescEdit_SecRequirementsBody` | `Build 42` | Description editor: the point the Requirements section starts with | - |
| `UI_ZeD_DescEdit_StartHeading` | `Heading` | Description editor: text of a newly added heading block (the user replaces it) | - |
| `UI_ZeD_DescEdit_StartLink` | `https:// Where it goes` | Description editor: text of a newly added link block: the address on the first line (keep https://), the words to show on the second | - |
| `UI_ZeD_DescEdit_StartList` | `First point Second point` | Description editor: text of a newly added list block, one point per line | - |
| `UI_ZeD_DescEdit_StartNumbered` | `First step Second step` | Description editor: text of a newly added numbered list block, one step per line | - |
| `UI_ZeD_DescEdit_StartTable` | `Works with \| Notes Another mod \| How they get along` | Description editor: text of a newly added table block: one row per line, cells split by ' \| ', first row is the header | - |
| `UI_ZeD_DescEdit_TabCodes` | `Steam codes` | Description editor: preview tab that shows the description as Steam's formatting codes | - |
| `UI_ZeD_DescEdit_TabSteam` | `As Steam shows it` | Description editor: preview tab that shows the description laid out like Steam's page | - |
| `UI_ZeD_DescEdit_Title` | `Project Zomboid  +  Description` | Description editor: title bar. The + is the ZeD title separator | - |
| `UI_ZeD_DescEdit_TitleNamed` | `Project Zomboid  +  Description: %1` | Description editor: title bar with the mod's name. %1 is the mod's name | - |
| `UI_ZeD_DescEdit_Undo` | `Undo` | Description editor: action strip button | 10 |
| `UI_ZeD_DescEdit_UseThis` | `Use this description` | Description editor: action strip button that hands the text back to the upload window | 24 |

## Desktop

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Desktop_EmptyTrash` | `Empty trash` | Trash window: button that empties the trash (asks to quit the game) | 16 |
| `UI_ZeD_Desktop_FileKind` | `the whole system` | Trash window: the kind of the one file in it (the Computer), under its name | 20 |
| `UI_ZeD_Desktop_FileName` | `Computer` | Trash window: the name of the one file in it, the computer itself (the old joke of throwing the computer in the trash) | 20 |
| `UI_ZeD_Desktop_OneItem` | `1 item` | Trash window: count in the title bar | 10 |
| `UI_ZeD_Desktop_PromptDpad` | `D-PAD Move` | Desktop: controller legend along the foot of the screen (the word D-PAD names the controller's cross) | - |
| `UI_ZeD_Desktop_Trash` | `Trash` | Desktop: name under the trash icon; title of the trash window | 14 |

## Doll

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Doll_Arms` | `ARMS` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the right-column slot box (capitals, one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_BeltSlot` | `BELT %1` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under a belt slot box; %1 is its hotbar key number | 8 |
| `UI_ZeD_Doll_EmptyHint` | `Empty: %1` | Equipment tab, Doll view (the character photo with slot boxes either side): hover hint over an empty belt slot; %1 is the slot's name | - |
| `UI_ZeD_Doll_Eyes` | `EYES` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (capitals, one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Feet` | `FEET` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the right-column slot box (capitals, one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Hands` | `HANDS` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (capitals, one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Innermost` | `INNERMOST` | Equipment tab, item card of a worn item with layers: strip under the card: %3 of the layer line when the last layer is shown | 14 |
| `UI_ZeD_Doll_LayerStrip` | `LAYER %1 OF %2 \| %3` | Equipment tab, item card of a worn item with layers: strip under the card (capitals); %1 the layer shown, %2 how many, %3 is Outermost / Innermost / Under N | 40 |
| `UI_ZeD_Doll_Main` | `MAIN` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the main-hand box in the row below the photo (capitals) | 7 |
| `UI_ZeD_Doll_Off` | `OFF` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the off-hand box in the row below the photo (capitals) | 7 |
| `UI_ZeD_Doll_Outer` | `OUTER` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (capitals, one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Outermost` | `OUTERMOST` | Equipment tab, item card of a worn item with layers: strip under the card: %3 of the layer line when the first layer is shown | 14 |
| `UI_ZeD_Doll_StepInner` | `Inner` | Equipment tab, item card of a worn item with layers: strip under the card: button that steps to the next layer inwards (sentence case) | 10 |
| `UI_ZeD_Doll_StepOuter` | `Outer` | Equipment tab, item card of a worn item with layers: strip under the card: button that steps to the next layer outwards (sentence case) | 10 |
| `UI_ZeD_Doll_Torso` | `TORSO` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (capitals, one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Under` | `%1 (+%2 under)` | Equipment tab, Doll view (the character photo with slot boxes either side): hover hint over a slot with several layers; %1 is the outermost item's name, %2 how many layers lie under it | - |
| `UI_ZeD_Doll_UnderN` | `UNDER %1` | Equipment tab, item card of a worn item with layers: strip under the card: %3 of the layer line for a middle layer; %1 is how many layers lie above it | 14 |
| `UI_ZeD_Doll_ViewDoll` | `Doll` | Equipment tab heading, List \| Doll toggle buttons: hover hint of the doll button (icon-only button) | 10 |
| `UI_ZeD_Doll_ViewList` | `List` | Equipment tab heading, List \| Doll toggle buttons: hover hint of the list button (icon-only button) | 10 |

## Equip

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Equip_Arms` | `Arms` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_AvgBite` | `%1 avg bite defense` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): line under OVERALL GRADE; %1 is a percentage such as 25% | 30 |
| `UI_ZeD_Equip_BackBag` | `Back/bag` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_BeltAlways` | `ALWAYS THERE` | Equipment tab (Character window), list view: under a belt slot's name when no worn item is needed for the slot | 20 |
| `UI_ZeD_Equip_BeltFrom` | `FROM THE %1` | Equipment tab (Character window), list view: under a belt slot's name; %1 is the worn item that gives the slot (a belt, a holster...) in capitals | 40 |
| `UI_ZeD_Equip_BeltHeadLeft` | `THE BELT \| KEYS` | Equipment tab (Character window), list view: belt sub-header, left side (capitals; ' \| ' is ZeD's separator). The keys are the hotbar keys 1-8 | 24 |
| `UI_ZeD_Equip_BeltHeadRight` | `SLOT \| WHAT GIVES IT` | Equipment tab (Character window), list view: belt sub-header, right side (capitals): slot name, then the worn item that provides the slot | 28 |
| `UI_ZeD_Equip_BestZone` | `Best zone` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): stat label (shown in capitals) above the most protected body part | 14 |
| `UI_ZeD_Equip_ColBullet` | `BUL` | Equipment tab (Character window), list view: column head above the slot rows (capitals, fixed narrow column) - bullet protection | 4 |
| `UI_ZeD_Equip_ColCond` | `COND` | Equipment tab (Character window), list view: column head above the slot rows (capitals, fixed narrow column) - condition bar | 6 |
| `UI_ZeD_Equip_ColScratch` | `SCR` | Equipment tab (Character window), list view: column head above the slot rows (capitals, fixed narrow column) - scratch protection | 4 |
| `UI_ZeD_Equip_ColSlot` | `SLOT` | Equipment tab (Character window), list view: column head above the slot rows (capitals, fixed narrow column) - slot the item is worn in | 8 |
| `UI_ZeD_Equip_ColWeight` | `WT` | Equipment tab (Character window), list view: column head above the slot rows (capitals, fixed narrow column) - weight | 4 |
| `UI_ZeD_Equip_Defense` | `Defense` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): section heading (only used by the legacy header path) | 14 |
| `UI_ZeD_Equip_Detach` | `DETACH` | Equipment tab (Character window), list view: button on a belt slot row holding an item (shown in sentence case) | 12 |
| `UI_ZeD_Equip_Empty` | `Empty` | Equipment tab (Character window), list view: belt slot row with nothing attached, in place of the item name | 12 |
| `UI_ZeD_Equip_Equipped` | `Equipped` | Equipment tab (Character window), list view: pinned heading of the tab (disclosure strip over the slot list) | 14 |
| `UI_ZeD_Equip_Eyewear` | `Eyewear` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_Garments` | `Garments` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): stat label (shown in capitals) above the worn garment count | 14 |
| `UI_ZeD_Equip_GarmentsEquipped` | `%1 equipped` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): value under Garments; %1 is how many garments are worn | 14 |
| `UI_ZeD_Equip_GroupArms` | `ARMS + HANDS` | Equipment tab (Character window), list view: collapsible group header strip (shown in capitals), followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupHead` | `HEAD + FACE` | Equipment tab (Character window), list view: collapsible group header strip (shown in capitals), followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupHeld` | `HELD + BELT` | Equipment tab (Character window), list view: collapsible group header strip (shown in capitals), followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupLegs` | `LEGS + FEET` | Equipment tab (Character window), list view: collapsible group header strip (shown in capitals), followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupTorso` | `TORSO` | Equipment tab (Character window), list view: collapsible group header strip (shown in capitals), followed by the count in brackets | 20 |
| `UI_ZeD_Equip_InHand` | `IN HAND` | Equipment tab (Character window), list view: small outlined tag on a belt slot row whose item is in the hands | 10 |
| `UI_ZeD_Equip_Inner` | `Inner` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_KneeLeg` | `Knee/leg` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_LayerMany` | `%1 layers` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): hover detail for a body part; %1 layers of clothing cover it (plural; 0 and 2 or more) | 12 |
| `UI_ZeD_Equip_LayerOne` | `%1 layer` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): hover detail for a body part, after the Bite/Scratch/Bullet bars; one layer of clothing covers it | 12 |
| `UI_ZeD_Equip_Outer` | `Outer` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_OverallGrade` | `OVERALL GRADE` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): small caps label beside the big letter grade box | 16 |
| `UI_ZeD_Equip_PutBack` | `PUT BACK` | Equipment tab (Character window), list view: button on a belt slot row whose item is in hand (shown in sentence case) | 12 |
| `UI_ZeD_Equip_Ring` | `Ring` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_Shoulder` | `Shoulder` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_WorstZone` | `Worst zone` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): stat label (shown in capitals) above the least protected body part | 14 |
| `UI_ZeD_Equip_Wrist` | `Wrist` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_ZonePct` | `%1 (%2)` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): value under Worst/Best Zone; %1 is a body part name, %2 its bite protection as a percentage | 36 |
| `UI_ZeD_Equip_ZoneUncovered` | `%1 (uncovered)` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): value under Worst Zone when that part has no protection; %1 is a body part name | 36 |

## Farm

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Farm_ConfirmClear` | `Clear the %1?` | Farm plot card: confirmation in the footer for a dead or empty plot; %1 is the plot's name in lower case | - |
| `UI_ZeD_Farm_ConfirmDig` | `Dig up the %1? The crop is lost.` | Farm plot card: confirmation in the footer; %1 is the crop's name in lower case | - |
| `UI_ZeD_Farm_DigUp` | `Dig up` | Farm plot card: verb button (danger) | 10 |
| `UI_ZeD_Farm_Fertilize` | `Fertilize` | Farm plot card: verb button | 12 |
| `UI_ZeD_Farm_Garden` | `GARDEN IN REACH` | Farm plot card: section heading over the grid of nearby plots (capitals) | - |
| `UI_ZeD_Farm_GardenPlowed` | `PLOWED` | Farm plot card: cell of the garden grid for plowed land (tiny capitals, cell about 6 letters wide) | 6 |
| `UI_ZeD_Farm_LockTag` | `FARMING %1` | Farm plot card: tag on a reading that needs Farming skill level %1 (capitals, bordered tag) | 14 |
| `UI_ZeD_Farm_NeedSeeds` | `Sow: needs seeds` | Farm plot card: the NEEDS line under the verbs when the plot is plowed and you carry no seeds | - |
| `UI_ZeD_Farm_NeedShovel` | `Dig up: needs a shovel or trowel` | Farm plot card: the NEEDS line under the verbs | - |
| `UI_ZeD_Farm_NeedSpray` | `Treat: needs %1` | Farm plot card: the NEEDS line when a pest shows and you carry no spray; %1 is the spray's item name | - |
| `UI_ZeD_Farm_NeedWater` | `Water: needs water in your hands or inventory` | Farm plot card: the NEEDS line under the verbs | - |
| `UI_ZeD_Farm_NextIn` | `in %1` | Farm plot card: value of NEXT STAGE; %1 is the game's own time phrase in lower case, e.g. 'in 2 days, 3 hours' | 20 |
| `UI_ZeD_Farm_NextStage` | `NEXT STAGE` | Farm plot card: label of the next-stage line (capitals) | 14 |
| `UI_ZeD_Farm_Pests` | `PESTS AND DISEASE` | Farm plot card: section heading over the pest rows (capitals) | - |
| `UI_ZeD_Farm_PhaseAlmostReady` | `ALMOST READY` | Farm plot card: growth phase on the six-cell strip (tiny capitals, cell about 9 letters wide); Ready and Rotten also name the header pill | 9 |
| `UI_ZeD_Farm_PhaseReady` | `READY` | Farm plot card: growth phase on the six-cell strip (tiny capitals, cell about 9 letters wide); Ready and Rotten also name the header pill | 9 |
| `UI_ZeD_Farm_PillEmpty` | `EMPTY` | Farm plot card: header pill for plowed land with nothing planted (capitals) | 9 |
| `UI_ZeD_Farm_PillGrowing` | `GROWING` | Farm plot card: header pill for a healthy growing plant (capitals) | 9 |
| `UI_ZeD_Farm_Plot` | `Farm Plot` | Farm plot card: card title, and the plot's name when the game gives none | 20 |
| `UI_ZeD_Farm_Skill` | `YOUR FARMING %1` | Farm plot card: line under the plant's name; %1 is the player's Farming level (capitals) | 24 |
| `UI_ZeD_Farm_SkillReadyToSow` | `YOUR FARMING %1 \| ready to sow` | Farm plot card: line under the name of plowed land; %1 is the player's Farming level (capitals; the bar is a separator) | 36 |
| `UI_ZeD_Farm_SowFromBags` | `SOW FROM YOUR BAGS` | Farm plot card: section heading over the seed list (capitals) | - |
| `UI_ZeD_Farm_SummaryDry` | `%1 DRY` | Farm plot card: GARDEN IN REACH summary: how many plots are dry or parched (capitals) | 14 |
| `UI_ZeD_Farm_SummaryPlotMany` | `%1 PLOTS` | Farm plot card: GARDEN IN REACH summary for two or more plots (capitals) | 14 |
| `UI_ZeD_Farm_SummaryPlotOne` | `%1 PLOT` | Farm plot card: GARDEN IN REACH summary for exactly one plot (capitals) | 14 |
| `UI_ZeD_Farm_SummaryThirsty` | `%1 THIRSTY` | Farm plot card: GARDEN IN REACH summary: how many plots are thirsty (capitals) | 14 |
| `UI_ZeD_Farm_TagInSeason` | `IN SEASON` | Farm plot card: tag on a seed row of the Sow list (capitals, bordered tag) | 14 |
| `UI_ZeD_Farm_TagRiskyMonth` | `RISKY MONTH` | Farm plot card: tag on a seed row of the Sow list (capitals, bordered tag) | 14 |
| `UI_ZeD_Farm_Treat` | `Treat` | Farm plot card: verb button, and the button on each pest row | 10 |

## Fire

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Fire_AddFromBags` | `ADD FUEL FROM YOUR BAGS` | Fire card: section heading over the fuel list (capitals) | - |
| `UI_ZeD_Fire_Adds` | `ADDS` | Fire card: right side of that heading, over the column of time each piece adds (capitals) | 8 |
| `UI_ZeD_Fire_AllFuel` | `All fuel (%1)` | Fire card: fuel list row that adds everything carried; %1 is the number of pieces | - |
| `UI_ZeD_Fire_ConfirmTakeApart` | `Take the campfire apart? You get 3 stones; what is on it drops.` | Fire card: confirmation in the footer | - |
| `UI_ZeD_Fire_Fire` | `Fire` | Fire card: card title when the game gives the fire no name | 24 |
| `UI_ZeD_Fire_FuelFull` | `The fire holds no more fuel` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_GainEach` | `+%1 each` | Fire card: time one piece of fuel adds when more than one is carried; %1 is the time, e.g. '+1 h 30 m each' | 16 |
| `UI_ZeD_Fire_GasLeft` | `GAS LEFT` | Fire card: propane barbecue, label of the hours of gas (capitals) | 14 |
| `UI_ZeD_Fire_Hrs` | `%1 HRS` | Fire card: propane barbecue, hours of gas as H:MM, e.g. 12:30 HRS (capitals) | 12 |
| `UI_ZeD_Fire_InsertTank` | `Insert tank` | Fire card: verb button on the propane barbecue | 14 |
| `UI_ZeD_Fire_LightWith` | `LIGHT WITH` | Fire card: section heading over the lighting methods (capitals) | - |
| `UI_ZeD_Fire_NameAll` | `%1: all (%2)` | Fire card: fuel row that adds every piece of one kind; %1 is the item name, %2 the number | - |
| `UI_ZeD_Fire_NameAllThatFit` | `%1: all that fit (%2)` | Fire card: fuel row that adds as many pieces of one kind as fit; %1 is the item name, %2 the number | - |
| `UI_ZeD_Fire_NeedFuelFirst` | `Light: needs fuel in the fire first` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_NeedFuelItems` | `Add fuel: needs something that burns` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_NeedGasTank` | `Turn on: needs a propane tank with gas` | Fire card: the NEEDS line under the verbs of a propane barbecue | - |
| `UI_ZeD_Fire_NeedLighter` | `Light: needs a lighter or matches with tinder, or a notched plank and a stick` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_NeedsFuel` | `NEEDS FUEL` | Fire card: tag on the kindling row of the LIGHT WITH list (capitals) | 14 |
| `UI_ZeD_Fire_NeedsStick` | `NEEDS A STICK` | Fire card: tag on the kindling row of the LIGHT WITH list (capitals) | 14 |
| `UI_ZeD_Fire_NeedTank` | `Insert tank: needs a propane tank` | Fire card: the NEEDS line under the verbs of a propane barbecue | - |
| `UI_ZeD_Fire_OfFuelHolds` | `OF FUEL \| HOLDS %1 H` | Fire card: small text beside the big time-left readout; %1 is the most hours the fire can hold (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Fire_OnTheFire` | `ON THE FIRE` | Fire card: section heading over the cooking rows (capitals) | - |
| `UI_ZeD_Fire_OnTheGrill` | `ON THE GRILL` | Fire card: section heading over the cooking rows of a propane barbecue (capitals) | - |
| `UI_ZeD_Fire_PillOut` | `OUT` | Fire card: header pill for a fire that is out (capitals) | 12 |
| `UI_ZeD_Fire_PropaneBBQ` | `Propane Barbecue` | Fire card: card title when the game gives the barbecue no name | 24 |
| `UI_ZeD_Fire_PutOut` | `Put out` | Fire card: verb button | 12 |
| `UI_ZeD_Fire_RemoveTank` | `Remove tank` | Fire card: verb button on the propane barbecue | 14 |
| `UI_ZeD_Fire_ScaleFull` | `FULL` | Fire card: right end of the fuel strip's scale (tiny capitals) | 6 |
| `UI_ZeD_Fire_ScaleHours` | `+%1 H` | Fire card: hour marks along the fuel strip's scale, e.g. +2 H (tiny capitals) | 8 |
| `UI_ZeD_Fire_ScaleNow` | `NOW` | Fire card: left end of the fuel strip's scale (tiny capitals) | 6 |
| `UI_ZeD_Fire_TagFull` | `FULL` | Fire card: tag on a fuel row that no longer fits (capitals, bordered tag) | 8 |
| `UI_ZeD_Fire_TakeApart` | `Take apart` | Fire card: verb button (danger), campfire only | 12 |
| `UI_ZeD_Fire_Tank` | `TANK` | Fire card: propane barbecue, label of the tank state (capitals) | 14 |
| `UI_ZeD_Fire_TankIn` | `IN` | Fire card: propane barbecue, value of TANK when a tank is fitted (capitals) | 6 |
| `UI_ZeD_Fire_TooTired` | `TOO TIRED` | Fire card: tag on the kindling row of the LIGHT WITH list (capitals) | 14 |

## Fluid

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Fluid_ConfirmEmpty` | `Pour %1 of %2 out on the ground?` | Fluid card: confirmation in the footer; %1 is the amount, e.g. 1.25 L, %2 the liquid's name in lower case | - |
| `UI_ZeD_Fluid_Container` | `Container` | Fluid card: a container's name when neither the item nor the game names it | 22 |
| `UI_ZeD_Fluid_From` | `From` | Fluid card: button on each container row that makes it the one to pour from | 8 |
| `UI_ZeD_Fluid_HintFrom` | `Pick "From" on a container below` | Fluid card: hint inside the empty left tank | - |
| `UI_ZeD_Fluid_HintInto` | `Pick "Into" on a container below` | Fluid card: hint inside the empty right tank | - |
| `UI_ZeD_Fluid_Into` | `Into` | Fluid card: button on each container row that makes it the one to pour into | 8 |
| `UI_ZeD_Fluid_LiquidWord` | `liquid` | Fluid card: the word for the liquid in the empty-out question when the liquid has no name (lower case) | 14 |
| `UI_ZeD_Fluid_NearbyTile` | `NEARBY \| %1 TILE` | Fluid card: under the pinned world container's name; %1 is the distance, exactly 1 (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Fluid_NearbyTiles` | `NEARBY \| %1 TILES` | Fluid card: under the pinned world container's name; %1 is the distance, any other number (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Fluid_PourProgress` | `%1 of %2` | Fluid card: while pouring, how much has poured of the whole amount, e.g. 0.50 of 1.25 L | - |
| `UI_ZeD_Fluid_TagFull` | `FULL` | Fluid card: tag on a container row that is full (capitals, bordered tag) | 10 |
| `UI_ZeD_Fluid_TagMixes` | `MIXES` | Fluid card: tag on a container row where the pour would mix liquids (capitals, bordered tag) | 10 |
| `UI_ZeD_Fluid_TagSame` | `SAME` | Fluid card: tag on a container row holding the same liquid as the one being poured (capitals, bordered tag) | 10 |
| `UI_ZeD_Fluid_TagTooHeavy` | `TOO HEAVY` | Fluid card: tag on a container row in a bag when the inventory is over its limit (capitals, bordered tag) | 10 |
| `UI_ZeD_Fluid_TagWontMix` | `WON'T MIX` | Fluid card: tag on a container row whose liquid cannot mix with the one being poured (capitals, bordered tag) | 10 |
| `UI_ZeD_Fluid_TagWontTake` | `WON'T TAKE` | Fluid card: tag on a container row that refuses the liquid being poured (capitals, bordered tag; the widest tag, it sets the column) | 10 |
| `UI_ZeD_Fluid_TooFull` | `You carry too much to pour into a container in your bags.` | Fluid card: the NEEDS line when the inventory is over its limit and the target container is in a bag | - |
| `UI_ZeD_Fluid_YourContainers` | `YOUR CONTAINERS` | Fluid card: section heading over the list of containers (capitals) | - |

## Flyer

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Flyer_BeenThere` | `Been there` | Maps, hover card over a flyer pin: status line (visited) | - |
| `UI_ZeD_Flyer_ClickRead` | `Click to read` | Maps, hover card over a flyer pin with a mouse: hint line | - |
| `UI_ZeD_Flyer_NotBeenThere` | `Not been there` | Maps, hover card over a flyer pin: status line (not visited) | - |
| `UI_ZeD_Flyer_PadRead` | `A to read` | Maps, hover card over a flyer pin with a controller: hint line (A is the controller button) | - |

## Forage

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Forage_CatCommon` | `Common` | World window, Foraging tab, More detail, Categories grid: a common category here | 8 |
| `UI_ZeD_Forage_CatIn` | `In` | World window, Foraging tab, More detail, Categories grid: a category present here (value column) | 8 |
| `UI_ZeD_Forage_CatLocked` | `L%1` | World window, Foraging tab, More detail, Categories grid: value of a category not yet unlocked (%1 = Foraging level needed) | 5 |
| `UI_ZeD_Forage_CatPeak` | `Peak` | World window, Foraging tab, More detail, Categories grid: the most common category here | 8 |
| `UI_ZeD_Forage_CatRare` | `Rare` | World window, Foraging tab, More detail, Categories grid: a rare category here | 8 |
| `UI_ZeD_Forage_CatsInRange` | `CATEGORIES IN RANGE` | World window, Foraging tab, More detail: sub-header over the categories grid | 28 |
| `UI_ZeD_Forage_CatsLocked` | `%1 / %2 LOCKED` | World window, Foraging tab, More detail: right side of the categories sub-header (%1 = categories listed, %2 = how many are locked) | 20 |
| `UI_ZeD_Forage_CompassE` | `E` | World window, Foraging tab, Recent finds: compass direction E of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CompassN` | `N` | World window, Foraging tab, Recent finds: compass direction N of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CompassNE` | `NE` | World window, Foraging tab, Recent finds: compass direction NE of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CompassNW` | `NW` | World window, Foraging tab, Recent finds: compass direction NW of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CompassS` | `S` | World window, Foraging tab, Recent finds: compass direction S of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CompassSE` | `SE` | World window, Foraging tab, Recent finds: compass direction SE of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CompassSW` | `SW` | World window, Foraging tab, Recent finds: compass direction SW of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CompassW` | `W` | World window, Foraging tab, Recent finds: compass direction W of the find, 1 to 2 letters | 3 |
| `UI_ZeD_Forage_CondFair` | `Fair` | World window, Foraging tab: hero chip, search conditions are fair | 10 |
| `UI_ZeD_Forage_CondGood` | `Good` | World window, Foraging tab: hero chip, search conditions are good | 10 |
| `UI_ZeD_Forage_CondPoor` | `Poor` | World window, Foraging tab: hero chip, search conditions are poor | 10 |
| `UI_ZeD_Forage_Day` | `DAY` | World window, Foraging tab: under the sky arc, it is daytime | 8 |
| `UI_ZeD_Forage_FindDist` | `%1T %2` | World window, Foraging tab, Recent finds: distance and bearing of a find (%1 = tiles away, T = tiles, %2 = compass direction) | 8 |
| `UI_ZeD_Forage_FindsEmpty` | `RECENT FINDS WILL APPEAR HERE` | World window, Foraging tab: empty state of the recent finds list | 40 |
| `UI_ZeD_Forage_FocusAll` | `All categories` | World window, Foraging tab: first option of the Search Focus dropdown (no focus) | 24 |
| `UI_ZeD_Forage_HeadDist` | `DIST` | World window, Foraging tab, Recent finds: column header, distance (the column is about 48 design pixels wide) | 6 |
| `UI_ZeD_Forage_HeadWeight` | `WT` | World window, Foraging tab, Recent finds: column header, weight (right-aligned, about 36 design pixels) | 4 |
| `UI_ZeD_Forage_ModClothing` | `Clothing` | World window, Foraging tab, More detail, Modifiers grid: penalty from clothing | 14 |
| `UI_ZeD_Forage_ModFatigue` | `Fatigue` | World window, Foraging tab, More detail, Modifiers grid: penalty from tiredness | 14 |
| `UI_ZeD_Forage_ModHealth` | `Health` | World window, Foraging tab, More detail, Modifiers grid: penalty from injury or illness | 14 |
| `UI_ZeD_Forage_Modifiers` | `MODIFIERS` | World window, Foraging tab, More detail: sub-header over the modifiers grid | 20 |
| `UI_ZeD_Forage_ModMoving` | `Moving` | World window, Foraging tab, More detail, Modifiers grid: penalty from moving | 14 |
| `UI_ZeD_Forage_ModPanic` | `Panic` | World window, Foraging tab, More detail, Modifiers grid: penalty from panic | 14 |
| `UI_ZeD_Forage_MoreDetail` | `MORE DETAIL` | World window, Foraging tab: disclosure row that opens the categories and modifiers | 24 |
| `UI_ZeD_Forage_Net` | `NET` | World window, Foraging tab: label under the net modifier percent in the hero band | 6 |
| `UI_ZeD_Forage_NetValue` | `%1 NET` | World window, Foraging tab, More detail: right side of the modifiers sub-header (%1 = signed percent, e.g. +5%) | 16 |
| `UI_ZeD_Forage_Night` | `NIGHT` | World window, Foraging tab: under the sky arc, it is night | 8 |
| `UI_ZeD_Forage_SeasonSummer` | `Summer` | World window, Foraging tab: season chip (the other seasons are the game's own words) | 12 |
| `UI_ZeD_Forage_StanceAim` | `Aim` | World window, Foraging tab: stance row tile (read-only status) | 12 |
| `UI_ZeD_Forage_StanceAiming` | `Aiming` | World window, Foraging tab: hero chip and a modifier row name | 12 |
| `UI_ZeD_Forage_StanceCrouch` | `Crouch` | World window, Foraging tab: stance row tile (read-only status) | 12 |
| `UI_ZeD_Forage_StanceSearching` | `Searching` | World window, Foraging tab: hero chip and the Searching tile of the stance row | 14 |
| `UI_ZeD_Forage_StanceSneaking` | `Sneaking` | World window, Foraging tab: hero chip and a modifier row name | 12 |
| `UI_ZeD_Forage_StanceWalking` | `Walking` | World window, Foraging tab: hero chip, what the character is doing | 12 |
| `UI_ZeD_Forage_Tiles` | `TILES` | World window, Foraging tab: label under the search radius number (unit of the radius) | 8 |
| `UI_ZeD_Forage_Unknown` | `Unknown` | World window, Foraging tab: zone, season or item name the game cannot give | 14 |
| `UI_ZeD_Forage_WxClear` | `Clear` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxCloudy` | `Cloudy` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxFog` | `Fog` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxOvercast` | `Overcast` | World window, Foraging tab: hero chip, weather | 12 |
| `UI_ZeD_Forage_WxRain` | `Rain` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxSnow` | `Snow` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxStorm` | `Storm` | World window, Foraging tab: hero chip, weather | 10 |

## Furn

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Furn_Always` | `ALWAYS` | Furniture tab, Disassemble mode: chance column when an item is always returned | 8 |
| `UI_ZeD_Furn_CarryNone` | `You carry no furniture.` | Furniture tab, Place mode: empty state | - |
| `UI_ZeD_Furn_Facing` | `FACING` | Furniture tab, Place and Rotate modes: small label before the N E S W buttons | 10 |
| `UI_ZeD_Furn_MayYield` | `MAY YIELD` | Furniture tab, Disassemble mode: section heading above the items you may get back | 20 |
| `UI_ZeD_Furn_More` | `+ %1 more` | Furniture tab, fact row: how many more acceptable tools there are (e.g. Claw Hammer + 3 more) | - |
| `UI_ZeD_Furn_NothingToPlace` | `Nothing to place` | Furniture tab, Place mode: line when you carry nothing to place | - |
| `UI_ZeD_Furn_OnCursor` | `ON CURSOR` | Furniture tab, Place mode: small tag on the furniture currently on the cursor | 12 |
| `UI_ZeD_Furn_OnThisTile` | `ON THIS TILE` | Furniture tab: section heading above the objects on the pointed tile | 20 |
| `UI_ZeD_Furn_PickupNo` | `Cannot pick up` | Furniture tab, Pick up mode: status line and tile chip when it cannot be picked up | - |
| `UI_ZeD_Furn_PickupReady` | `Ready to pick up` | Furniture tab, Pick up mode: status line when the pointed furniture can be picked up | - |
| `UI_ZeD_Furn_PlaceNo` | `Does not fit here` | Furniture tab, Place mode: status line and tile chip when it does not fit | - |
| `UI_ZeD_Furn_PlaceReady` | `Fits here` | Furniture tab, Place mode: status line when the furniture fits | - |
| `UI_ZeD_Furn_PointBuilt` | `Point at something built or crafted` | Furniture tab, Repair mode: prompt when nothing repairable is pointed at | - |
| `UI_ZeD_Furn_PointFurniture` | `Point at furniture` | Furniture tab: prompt when nothing is pointed at | - |
| `UI_ZeD_Furn_RepairNo` | `Cannot repair` | Furniture tab, Repair mode: status line and tile chip when it cannot be repaired | - |
| `UI_ZeD_Furn_RepairReady` | `Ready to repair` | Furniture tab, Repair mode: status line when it can be repaired | - |
| `UI_ZeD_Furn_RollChance` | `ROLL CHANCE` | Furniture tab, Disassemble mode: second column legend of the yield list | 14 |
| `UI_ZeD_Furn_RotateNo` | `Cannot turn` | Furniture tab, Rotate mode: status line and tile chip when it cannot be turned | - |
| `UI_ZeD_Furn_RotateReady` | `Turns in place` | Furniture tab, Rotate mode: status line when it can be turned | - |
| `UI_ZeD_Furn_ScrapNo` | `Cannot take apart` | Furniture tab, Disassemble mode: status line and tile chip when it cannot be taken apart | - |
| `UI_ZeD_Furn_ScrapReady` | `Ready to take apart` | Furniture tab, Disassemble mode: status line when it can be taken apart | - |
| `UI_ZeD_Furn_Target` | `TARGET` | Furniture tab: small tag on the object currently targeted | 12 |
| `UI_ZeD_Furn_ToCursor` | `To the cursor` | Controller prompt for B on the Furniture tab (hands the stick back to the world cursor) | 20 |
| `UI_ZeD_Furn_UpTo` | `UP TO` | Furniture tab, Disassemble mode: first column legend of the yield list (most you can get) | 10 |
| `UI_ZeD_Furn_YourFurniture` | `YOUR FURNITURE` | Furniture tab, Place mode: section heading above the furniture you carry | 20 |

## Health

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Health_Burn` | `Burn` | Health tab (Character window): condition badge on a burned body part (pill, shown in capitals) | 14 |
| `UI_ZeD_Health_GlassShards` | `Glass shards` | Health tab (Character window): condition badge on an injured body part (pill, shown in capitals) | 18 |
| `UI_ZeD_Health_Healthy` | `Healthy` | Health tab (Character window): hover detail for a body part with no conditions (beside a green dot) | 14 |
| `UI_ZeD_Health_InjuredOf` | `%1 of %2 injured` | Health tab (Character window): summary line; %1 is how many body parts have a wound or condition, %2 how many body parts there are | 24 |
| `UI_ZeD_Health_NoInjuries` | `No injuries` | Health tab (Character window): summary line (with a green dot) when nothing is wounded and health is fine | 20 |
| `UI_ZeD_Health_NoInjuriesLow` | `No injuries, low body health` | Health tab (Character window): summary line (with a yellow dot) when nothing is wounded but some body part has reduced health (hunger, illness, cold) | 32 |
| `UI_ZeD_Health_Overall` | `Overall` | Health tab (Character window): stat row label at the top of the summary, before the overall body health percentage | 12 |
| `UI_ZeD_Health_Qualified` | `%1 (%2)` | Health tab (Character window): a condition with its severity or state in a badge, e.g. Deep Wound (Severe), Stitched (Good); %1 the condition, %2 the severity word | 28 |

## Hook

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Hook_BleedingOnGround` | `BLEEDING ONTO THE GROUND` | Butcher hook card: label of the progress band while blood runs onto the ground (capitals) | 26 |
| `UI_ZeD_Hook_BleedOnGround` | `BLEED ONTO THE GROUND` | Butcher hook card: row under the container list: let the blood run onto the ground (capitals) | - |
| `UI_ZeD_Hook_BloodLostHead` | `Taking the head now splashes the %1 of blood still in it.` | Butcher hook card: the NEEDS line before taking the head while blood remains; %1 is the amount, e.g. 1.50 L | - |
| `UI_ZeD_Hook_BloodLostMeat` | `Taking the meat now loses the %1 of blood still in it; the head splashes it.` | Butcher hook card: the NEEDS line before taking meat while blood remains; %1 is the amount, e.g. 1.50 L | - |
| `UI_ZeD_Hook_CollectInto` | `COLLECT INTO` | Butcher hook card: section heading over the list of containers for the blood (capitals) | - |
| `UI_ZeD_Hook_DeadNearby` | `DEAD ANIMALS NEARBY` | Butcher hook card: section heading over the list of carcasses to hang (capitals) | - |
| `UI_ZeD_Hook_GroundTile` | `GROUND \| %1 TILE` | Butcher hook card: where a dead animal lies, exactly 1 tile away (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Hook_GroundTiles` | `GROUND \| %1 TILES` | Butcher hook card: where a dead animal lies, any other distance (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Hook_Hang` | `HANG` | Butcher hook card: button on a carcass row that hangs it on the hook (btn sentence case applies) | 10 |
| `UI_ZeD_Hook_InUseBy` | `Someone else is using the hook.` | Butcher hook card: the NEEDS line under the verbs | - |
| `UI_ZeD_Hook_Knife` | `KNIFE` | Butcher hook card: label of the line naming the knife in use (capitals) | 10 |
| `UI_ZeD_Hook_NotForHook` | `NOT FOR THE HOOK` | Butcher hook card: tag on a carcass the hook does not take (capitals, bordered tag) | 18 |
| `UI_ZeD_Hook_PillBleeding` | `BLEEDING` | Butcher hook card: header pill while the carcass bleeds out (capitals) | 12 |
| `UI_ZeD_Hook_PillEmpty` | `EMPTY` | Butcher hook card: header pill for a hook with no carcass (capitals) | 12 |
| `UI_ZeD_Hook_PillInUse` | `IN USE` | Butcher hook card: header pill when another player uses the hook (capitals) | 12 |
| `UI_ZeD_Hook_PillOnHook` | `ON THE HOOK` | Butcher hook card: header pill for a carcass on the hook (capitals) | 12 |
| `UI_ZeD_Hook_Taken` | `Taken` | Butcher hook card: value of Leather, Head or Meat once that part has been taken from the carcass | 10 |
| `UI_ZeD_Hook_Within2` | `WITHIN 2 TILES OR CARRIED` | Butcher hook card: right side of that heading (capitals) | - |

## Host

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Host_AskDeletePlayer` | `Delete this character from the server?` | Host screen: question in the action strip | - |
| `UI_ZeD_Host_AskDeleteWorld` | `Delete the world? It cannot be undone.` | Host screen: question in the action strip | - |
| `UI_ZeD_Host_AskReset` | `Soft-reset the server?` | Host screen: question in the action strip | - |
| `UI_ZeD_Host_BadAccount` | `That account name will not do.` | Host screen: red note under the form when the account name is not valid | - |
| `UI_ZeD_Host_LabelAccount` | `ACCOUNT` | Host screen: caps label at the left of the account name row (about 18 letters of room) | 18 |
| `UI_ZeD_Host_LabelSettings` | `SERVER SETTINGS` | Host screen: caps label at the left of the server settings choice | 18 |
| `UI_ZeD_Host_LabelWorld` | `THE WORLD` | Host screen: caps label at the left of the world upkeep buttons | 18 |
| `UI_ZeD_Host_Reset` | `Reset` | Host screen: strip button that confirms the soft reset | 12 |
| `UI_ZeD_Host_Resetting` | `RESETTING` | Host screen: caps heading over the soft reset progress bar | - |
| `UI_ZeD_Host_Title` | `Project Zomboid  +  Host a game` | Host screen: title bar. The + is the ZeD title separator | - |

## Hud

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Hud_PutAway` | `Put away` | Controller prompt strip of the car radio and the siren controller: the B button puts the prop away | 20 |

## Hutch

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Hutch_Bleach` | `Bleach \| twice as fast` | Hutch card: cleaning checklist: optional bleach (the bar is a separator) | - |
| `UI_ZeD_Hutch_BothShut` | `BOTH DOORS SHUT` | Hutch card: plate where shut doors hide the boxes (capitals) | 18 |
| `UI_ZeD_Hutch_Box` | `BOX %1` | Hutch card: heading of one egg laying box, e.g. BOX 2 (capitals) | 8 |
| `UI_ZeD_Hutch_Boxes` | `%1 BOXES` | Hutch card: right side of the EGG LAYING BOXES heading when both doors are shut (capitals) | 14 |
| `UI_ZeD_Hutch_BoxesFull` | `Every box is full: the hens will lay outside.` | Hutch card: the NEEDS line under the boxes | - |
| `UI_ZeD_Hutch_CloseHatch` | `Close hatch` | Hutch card: verb button for the egg hatch door | 14 |
| `UI_ZeD_Hutch_Dirtiness` | `DIRTINESS` | Hutch card: label over the floor's dirtiness bar (capitals) | 14 |
| `UI_ZeD_Hutch_DoorOpen` | `DOOR OPEN` | Hutch card: text beside the main door's lamp (capitals) | 14 |
| `UI_ZeD_Hutch_DoorShut` | `DOOR SHUT` | Hutch card: text beside the main door's lamp, and the plate where a shut door hides the perches (capitals) | 14 |
| `UI_ZeD_Hutch_EggsBoxes` | `%1 EGGS \| %2 BOXES` | Hutch card: right side of the EGG LAYING BOXES heading: eggs and boxes (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Hutch_HatchOpen` | `EGG HATCH OPEN` | Hutch card: text beside the egg hatch's lamp (capitals) | 18 |
| `UI_ZeD_Hutch_HatchShut` | `EGG HATCH SHUT` | Hutch card: text beside the egg hatch's lamp (capitals) | 18 |
| `UI_ZeD_Hutch_HenSitting` | `HEN SITTING` | Hutch card: the disabled button of a box that has a hen sitting in it (capitals; the box is about 12 letters wide) | 12 |
| `UI_ZeD_Hutch_Mop` | `Mop, towel or broom` | Hutch card: cleaning checklist: a cleaning tool needed, when you carry none | - |
| `UI_ZeD_Hutch_MopNamed` | `Mop, towel or broom \| %1` | Hutch card: cleaning checklist: the tool you have; %1 is its item name (the bar is a separator) | - |
| `UI_ZeD_Hutch_NoBirds` | `No birds inside.` | Hutch card: line under COOP ROOSTING when no bird is inside | - |
| `UI_ZeD_Hutch_OpenHatch` | `Open hatch` | Hutch card: verb button for the egg hatch door | 14 |
| `UI_ZeD_Hutch_PillShut` | `SHUT` | Hutch card: header pill when both doors are shut (capitals) | 8 |
| `UI_ZeD_Hutch_PutIn` | `Put in` | Hutch card: verb button, shown when you hold a bird the hutch takes | 10 |
| `UI_ZeD_Hutch_PutInNeeds` | `Put in: %1` | Hutch card: the NEEDS line when the bird cannot go in; %1 is the game's own reason (doors shut, hutch full) | - |
| `UI_ZeD_Hutch_Sitting` | `SITTING \| %1` | Hutch card: under a hen sitting in a box; %1 is the number of eggs under her (tiny capitals; the bar is a separator) | 14 |
| `UI_ZeD_Hutch_SubAdult` | `%1 \| ADULT` | Hutch card: small line under a bird's name on the perch list; %1 is the species in capitals (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Hutch_SubYoung` | `%1 \| YOUNG` | Hutch card: small line under a young bird's name on the perch list; %1 is the species in capitals (capitals; the bar is a separator) | 24 |
| `UI_ZeD_Hutch_Water` | `Water` | Hutch card: cleaning checklist: water needed, when you carry none | - |
| `UI_ZeD_Hutch_WaterNamed` | `Water \| %1` | Hutch card: cleaning checklist: the water you have; %1 is its item name (the bar is a separator) | - |

## Identity

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Identity_BodyHair` | `Body hair` | Identity tab (Character window), driver's-license card: small field label (second row, right column) | 18 |
| `UI_ZeD_Identity_BodyHairHeavy` | `Heavy` | Identity tab (Character window), driver's-license card: Body Hair value | 14 |
| `UI_ZeD_Identity_BodyHairLevel` | `Level %1` | Identity tab (Character window), driver's-license card: Body Hair value for a level the game adds beyond the four named ones | 14 |
| `UI_ZeD_Identity_BodyHairLight` | `Light` | Identity tab (Character window), driver's-license card: Body Hair value | 14 |
| `UI_ZeD_Identity_BodyHairNormal` | `Normal` | Identity tab (Character window), driver's-license card: Body Hair value | 14 |
| `UI_ZeD_Identity_BodyHairVeryHeavy` | `Very heavy` | Identity tab (Character window), driver's-license card: Body Hair value | 14 |
| `UI_ZeD_Identity_FacialHair` | `Facial hair` | Identity tab (Character window), driver's-license card: small field label (third row, right column) | 18 |
| `UI_ZeD_Identity_HairAuburn` | `Auburn` | Identity tab (Character window), driver's-license card: Hair Color value | 14 |
| `UI_ZeD_Identity_HairBlonde` | `Blonde` | Identity tab (Character window), driver's-license card: Hair Color value (read from the hair's colour) | 14 |
| `UI_ZeD_Identity_HairColor` | `Hair color` | Identity tab (Character window), driver's-license card: small field label (third row, left column) | 18 |
| `UI_ZeD_Identity_HairDarkBrown` | `Dark brown` | Identity tab (Character window), driver's-license card: Hair Color value | 14 |
| `UI_ZeD_Identity_HairDarkRed` | `Dark red` | Identity tab (Character window), driver's-license card: Hair Color value | 14 |
| `UI_ZeD_Identity_HairStyle` | `Hair style` | Identity tab (Character window), driver's-license card: small field label (second row, left column) | 18 |
| `UI_ZeD_Identity_NotApplicable` | `N/A` | Identity tab (Character window), driver's-license card: Facial Hair value for a female character | 6 |
| `UI_ZeD_Identity_NoTraits` | `No traits` | Identity tab (Character window), driver's-license card: Traits section, when the character has none | 20 |
| `UI_ZeD_Identity_Profession` | `Profession` | Identity tab (Character window), driver's-license card: small field label (first row, right column) | 18 |
| `UI_ZeD_Identity_TraitsNegative` | `NEGATIVE (%1)` | Identity tab (Character window), driver's-license card: Traits section, small subheading over the bad traits (capitals); %1 is how many | 20 |
| `UI_ZeD_Identity_TraitsPositive` | `POSITIVE (%1)` | Identity tab (Character window), driver's-license card: Traits section, small subheading over the good traits (capitals); %1 is how many | 20 |
| `UI_ZeD_Identity_Unknown` | `Unknown` | Identity tab (Character window), driver's-license card: surname / hair colour shown when the game gives none | 16 |
| `UI_ZeD_Identity_WeightKg` | `%1 kg` | Identity tab (Character window), driver's-license card: weight pill at the top right of the card; %1 is the number (kilograms) | 10 |

## Inv

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Inv_ColCat` | `CAT` | Inventory list: column heading for the item category | 6 |
| `UI_ZeD_Inv_ColCond` | `COND` | Inventory list: column heading for item condition | 6 |
| `UI_ZeD_Inv_ColName` | `NAME` | Inventory list: column heading, and the name of the sort order in the grid's order line | 8 |
| `UI_ZeD_Inv_ColWt` | `WT` | Inventory list: column heading for item weight | 4 |
| `UI_ZeD_Inv_Empty` | `INVENTORY EMPTY` | Inventory list: centered message when a container has no items | 24 |
| `UI_ZeD_Inv_GridView` | `Grid view` | Inventory lists: hover hint on the grid button of the List/Grid toggle | - |
| `UI_ZeD_Inv_ItemsMany` | `%1 items` | Inventory lists (both windows), compact container header: how many items it holds (several or none) | 12 |
| `UI_ZeD_Inv_ItemsOne` | `%1 item` | Inventory lists (both windows), compact container header: how many items it holds (one) | - |
| `UI_ZeD_Inv_OrderLine` | `ORDER: %1, AS THE LIST` | Inventory grid, column bar: names the list's sort order the grid follows; %1 is NAME, CATEGORY, CONDITION or WEIGHT | - |
| `UI_ZeD_Inv_OrderWt` | `WEIGHT` | Inventory grid, order line: name of the sort order (by weight) | 14 |

## ItemAct

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_ItemAct_MinutesShort` | `%1m` | Item card progress band, minutes left to cook or burn (%1 is the number) | 6 |
| `UI_ZeD_ItemAct_Reading` | `READING` | Item card progress band label while a book is read | 14 |
| `UI_ZeD_ItemAct_Repairing` | `REPAIRING` | Item card progress band label while clothing is repaired | 14 |

## ItemMenu

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_ItemMenu_NameThis` | `Name this item` | Title of the rename text box opened from an item's right-click menu or its card's name row | 30 |

## Join

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Join_AddAccount` | `Add account...` | Join screen: strip button that adds an account to the picked server | 18 |
| `UI_ZeD_Join_AddServer` | `Add server...` | Join screen: strip button that adds a server | 18 |
| `UI_ZeD_Join_AskDeleteAccount` | `Delete the account %1?` | Join screen: question in the action strip. %1 is the account name | - |
| `UI_ZeD_Join_AskPassword` | `Password for %1:` | Join screen: question in the action strip, before a field for the password. %1 is the account name | - |
| `UI_ZeD_Join_AskRemoveServer` | `Remove %1 from your saved servers?` | Join screen: question in the action strip. %1 is the server's name | - |
| `UI_ZeD_Join_AsUser` | `as %1` | Join screen: connecting window, under the server's name. %1 is the account name | - |
| `UI_ZeD_Join_Connecting` | `Connecting` | Join screen: title of the connecting window when the game gives none | - |
| `UI_ZeD_Join_ErrBadAddress` | `That address is not allowed.` | Join screen: red note under the address field | - |
| `UI_ZeD_Join_ErrBadName` | `That name is not allowed.` | Join screen: red note under the server name field | - |
| `UI_ZeD_Join_ErrNoName` | `Give the server a name.` | Join screen: red note under the server name field | - |
| `UI_ZeD_Join_ErrNoPassword` | `Give the account's password.` | Join screen: red note under the account password field | - |
| `UI_ZeD_Join_ErrNoPort` | `Give the port (16261 by default).` | Join screen: red note under the port field | - |
| `UI_ZeD_Join_ErrPortNumber` | `The port is a number.` | Join screen: red note under the port field | - |
| `UI_ZeD_Join_ErrShortAddress` | `An address is at least 7 characters.` | Join screen: red note under the address field | - |
| `UI_ZeD_Join_FilterEmpty` | `Empty` | Join screen: tick box on the Public tab: show empty servers | - |
| `UI_ZeD_Join_FilterFull` | `Full` | Join screen: tick box on the Public tab: show full servers | - |
| `UI_ZeD_Join_FilterVersion` | `Same version` | Join screen: tick box on the Public tab: show only servers running your version | - |
| `UI_ZeD_Join_Find` | `Find:` | Join screen: label of the search box on the Public tab | 10 |
| `UI_ZeD_Join_Forget` | `Forget` | Join screen: strip button that removes a public server from the saved ones | 12 |
| `UI_ZeD_Join_KeepPassword` | `Leave it empty to keep the saved one.` | Join screen: note under the password field when editing an account | - |
| `UI_ZeD_Join_KvAddress` | `ADDRESS` | Join screen: caps label in the server facts (about 12 letters of room) | 12 |
| `UI_ZeD_Join_KvWhitelist` | `WHITELIST` | Join screen: caps label in the server facts | 12 |
| `UI_ZeD_Join_LastOn` | `last on %1` | Join screen: under a saved account, after a \| separator. %1 is the date of the last logon | - |
| `UI_ZeD_Join_MinPlayed` | `%1 min played` | Join screen: under a saved account. %1 is the minutes played | - |
| `UI_ZeD_Join_Modded` | `Modded` | Join screen: tick box on the Public tab (show modded servers) and a tag on a server row | - |
| `UI_ZeD_Join_NoServers` | `No servers to show.` | Join screen: empty Public list | - |
| `UI_ZeD_Join_NotPlayed` | `Not played yet` | Join screen: under a saved account that never joined | - |
| `UI_ZeD_Join_Password` | `Password` | Join screen: tick box on the Public tab (show password-protected servers) and a tag on a server row | - |
| `UI_ZeD_Join_PingMs` | `%1 ms` | Join screen: server facts, ping. %1 is milliseconds | - |
| `UI_ZeD_Join_PlayersOf` | `%1 of %2` | Join screen: server facts, players. %1 on the server now, %2 the most it allows | - |
| `UI_ZeD_Join_PromptTabs` | `Saved / Public` | Join screen: controller prompt for the bumpers, which switch tabs | - |
| `UI_ZeD_Join_RefreshWait` | `Refresh (%1)` | Join screen: strip button while the game makes you wait. %1 is the seconds left | 14 |
| `UI_ZeD_Join_SavedMany` | `%1 saved servers` | Join screen: count in the title bar, none or several saved servers. %1 is the number | - |
| `UI_ZeD_Join_SavedOne` | `%1 saved server` | Join screen: count in the title bar, one saved server. %1 is the number | - |
| `UI_ZeD_Join_SaveServer` | `Save server` | Join screen: strip button that saves a public server | 14 |
| `UI_ZeD_Join_TabPublic` | `Public` | Join screen: folder tab for the public server list | 12 |
| `UI_ZeD_Join_TabSaved` | `Saved` | Join screen: folder tab for the servers you saved | 12 |
| `UI_ZeD_Join_Title` | `Project Zomboid  +  Join a server` | Join screen: title bar. The + is the ZeD title separator | - |
| `UI_ZeD_Join_TitleAddAccount` | `Project Zomboid  +  Add account` | Join screen: title bar while adding an account | - |
| `UI_ZeD_Join_TitleAddServer` | `Project Zomboid  +  Add server` | Join screen: title bar while adding a server | - |
| `UI_ZeD_Join_TitleConnect` | `Project Zomboid  +  %1` | Join screen: title bar of the connecting window. %1 is the game's own title for it | - |
| `UI_ZeD_Join_TitleEditAccount` | `Project Zomboid  +  Edit account` | Join screen: title bar while editing an account | - |
| `UI_ZeD_Join_TitleEditServer` | `Project Zomboid  +  Edit server` | Join screen: title bar while editing a saved server | - |
| `UI_ZeD_Join_Whitelist` | `Whitelist` | Join screen: tick box on the Public tab (show whitelist servers) and a tag on a server row | - |

## Journal

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Journal_EntrySource` | `%1, page %2` | Character window, Journal tab, Journal sub-tab: end of an entry's date line when it was also written into a notebook (%1 = its name, %2 = page) | 36 |
| `UI_ZeD_Journal_EntryStamp` | `Day %1  %2 %3, %4` | Character window, Journal tab, Journal sub-tab: date line of an entry, without the time, which follows as ' - 14:05' (%1 = day survived, %2 = short month, %3 = day of month, %4 = year) | 36 |
| `UI_ZeD_Journal_GroupLabel` | `%1, Year %2` | Character window, Journal tab, Journal sub-tab: heading of a month group (%1 = full month name, %2 = in-game year) | 28 |
| `UI_ZeD_Journal_KillExplosion` | `Explosion` | Character window, Journal tab, Journal sub-tab: kills list, row for kills by explosion | 20 |
| `UI_ZeD_Journal_KillFire` | `Fire` | Character window, Journal tab, Journal sub-tab: kills list, row for kills by fire | 20 |
| `UI_ZeD_Journal_KillVehicle` | `Vehicle` | Character window, Journal tab, Journal sub-tab: kills list, row for kills by vehicle | 20 |
| `UI_ZeD_Journal_MonthApr` | `Apr` | Character window, Journal tab, Journal sub-tab: short month name 4 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthAug` | `Aug` | Character window, Journal tab, Journal sub-tab: short month name 8 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthDec` | `Dec` | Character window, Journal tab, Journal sub-tab: short month name 12 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthFeb` | `Feb` | Character window, Journal tab, Journal sub-tab: short month name 2 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthJan` | `Jan` | Character window, Journal tab, Journal sub-tab: short month name 1 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthJul` | `Jul` | Character window, Journal tab, Journal sub-tab: short month name 7 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthJun` | `Jun` | Character window, Journal tab, Journal sub-tab: short month name 6 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthMar` | `Mar` | Character window, Journal tab, Journal sub-tab: short month name 3 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthMay` | `May` | Character window, Journal tab, Journal sub-tab: short month name 5 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthNov` | `Nov` | Character window, Journal tab, Journal sub-tab: short month name 11 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthOct` | `Oct` | Character window, Journal tab, Journal sub-tab: short month name 10 in the date line of each entry | 5 |
| `UI_ZeD_Journal_MonthSep` | `Sep` | Character window, Journal tab, Journal sub-tab: short month name 9 in the date line of each entry | 5 |
| `UI_ZeD_Journal_NoEntries` | `No entries yet` | Character window, Journal tab, Journal sub-tab: empty log | 30 |
| `UI_ZeD_Journal_TabJournal` | `Journal` | Character window, Journal tab: sub-tab | 14 |
| `UI_ZeD_Journal_TabNotebooks` | `Notebooks` | Character window, Journal tab: sub-tab | 14 |
| `UI_ZeD_Journal_TabPapers` | `Papers` | Character window, Journal tab: sub-tab | 14 |
| `UI_ZeD_Journal_WeaponOther` | `Other` | Character window, Journal tab, Journal sub-tab: kills list, row for kills with other weapons | 20 |
| `UI_ZeD_Journal_WeaponUnarmed` | `Unarmed` | Character window, Journal tab, Journal sub-tab: kills list, row for kills without a weapon | 20 |

## Keyboard

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Keyboard_Show` | `SHOW` | On-screen keyboard, key that reveals a masked (password) field | 8 |

## Lock

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Lock_BusyLocking` | `LOCKING` | Padlock card: label in the progress band while the padlock is being locked (small, left of the bar; capitals) | 24 |
| `UI_ZeD_Lock_BusyPutting` | `PUTTING THE PADLOCK ON` | Padlock card: label in the progress band while a key padlock goes on (capitals) | 26 |
| `UI_ZeD_Lock_BusyRemoving` | `REMOVING THE PADLOCK` | Padlock card: label in the progress band while a padlock comes off (capitals) | 26 |
| `UI_ZeD_Lock_BusyTrying` | `TRYING %1` | Padlock card: label in the progress band while a code is tried; %1 is the code with spaces, e.g. 3 1 9 (capitals) | 24 |
| `UI_ZeD_Lock_BusyWalking` | `WALKING OVER` | Padlock card: label in the progress band while the character walks to the object (capitals) | 24 |
| `UI_ZeD_Lock_ComboIn` | `Combination Padlock \| in your inventory` | Padlock card: value of the padlock line while choosing a code (the bar is a separator) | - |
| `UI_ZeD_Lock_ComboNone` | `No Combination Padlock in your inventory` | Padlock card: value of the padlock line while choosing a code with no padlock | - |
| `UI_ZeD_Lock_FactContainer` | `CONTAINER` | Padlock card: label of the container line (capitals; the label column is about 12 letters wide) | 12 |
| `UI_ZeD_Lock_FactKey` | `KEY` | Padlock card: label of the key line (capitals; the label column is about 12 letters wide) | 12 |
| `UI_ZeD_Lock_FactPadlock` | `PADLOCK` | Padlock card: label of the padlock line (capitals; the label column is about 12 letters wide) | 12 |
| `UI_ZeD_Lock_FlashOff` | `Padlock off. It shows in the Loot pane.` | Padlock card: footer line for a few seconds after the padlock comes off | - |
| `UI_ZeD_Lock_Hidden` | `hidden while locked` | Padlock card: what the container holds, when it is locked to you | - |
| `UI_ZeD_Lock_ItemsMany` | `%1 items \| %2 / %3` | Padlock card: container line, any other number of items; %2 is the weight, %3 the capacity (the bar is a separator) | - |
| `UI_ZeD_Lock_ItemsOne` | `%1 item \| %2 / %3` | Padlock card: container line, exactly one item; %2 is the weight, %3 the capacity (the bar is a separator) | - |
| `UI_ZeD_Lock_KeyIn` | `Padlock Key \| in your inventory` | Padlock card: value of the key line when you carry the key (the bar is a separator) | - |
| `UI_ZeD_Lock_KeyNotIn` | `Padlock Key \| not in your inventory` | Padlock card: value of the key line when you do not carry the key (the bar is a separator) | - |
| `UI_ZeD_Lock_Lock` | `Lock` | Padlock card: verb button that puts the code padlock on | 10 |
| `UI_ZeD_Lock_NeedCode` | `A code other than 000` | Padlock card: checklist row | - |
| `UI_ZeD_Lock_NeedCombo` | `Combination Padlock in your inventory` | Padlock card: checklist row | - |
| `UI_ZeD_Lock_NeedKey` | `Its key in your inventory` | Padlock card: checklist row | - |
| `UI_ZeD_Lock_NeedsLock` | `NEEDS \| LOCK` | Padlock card: section heading over the list of what locking needs (capitals; the bar is a separator) | - |
| `UI_ZeD_Lock_NeedsRemove` | `NEEDS \| REMOVE PADLOCK` | Padlock card: section heading over the list of what removing a key padlock needs (capitals; the bar is a separator) | - |
| `UI_ZeD_Lock_NeedUseCombo` | `Use combination padlock: a Combination Padlock in your inventory` | Padlock card: checklist row | - |
| `UI_ZeD_Lock_NeedUsePad` | `Use padlock: a Padlock with its keys in your inventory` | Padlock card: checklist row | - |
| `UI_ZeD_Lock_NoPadlock` | `NO PADLOCK ON IT` | Padlock card: plate where the padlock would be, on an object with none (capitals) | 22 |
| `UI_ZeD_Lock_NoteSet` | `Locked to everyone, you included, until the code takes the padlock off` | Padlock card: note under the padlock while choosing a code (wraps, centred) | - |
| `UI_ZeD_Lock_PadComboLocked` | `Combination \| locked to everyone` | Padlock card: value of the padlock line for a code lock (the bar is a separator) | - |
| `UI_ZeD_Lock_PadKeyOpens` | `Key padlock \| opens for whoever carries its key` | Padlock card: value of the padlock line for a key lock (the bar is a separator) | - |
| `UI_ZeD_Lock_PillCode` | `CODE LOCK` | Padlock card: header pill for a code-locked object (capitals) | 16 |
| `UI_ZeD_Lock_PillKey` | `KEY LOCK` | Padlock card: header pill for a key-locked object (capitals) | 16 |
| `UI_ZeD_Lock_PillSetting` | `SETTING A CODE` | Padlock card: header pill while choosing a code (capitals) | 16 |
| `UI_ZeD_Lock_PillUnlocked` | `UNLOCKED` | Padlock card: header pill for an object with no padlock (capitals) | 16 |
| `UI_ZeD_Lock_StatusNoCombo` | `Can't lock: no Combination Padlock in your inventory` | Padlock card: footer line | - |
| `UI_ZeD_Lock_StatusNoKey` | `Can't remove the padlock: its key is not in your inventory` | Padlock card: footer line | - |
| `UI_ZeD_Lock_StatusReadyKey` | `Ready to remove the padlock with its key` | Padlock card: footer line | - |
| `UI_ZeD_Lock_StatusReadyLock` | `Ready to lock it with %1` | Padlock card: footer line; %1 is the code with spaces, e.g. 3 1 9 | - |
| `UI_ZeD_Lock_StatusReadyTry` | `Ready to try %1` | Padlock card: footer line; %1 is the code with spaces, e.g. 3 1 9 | - |
| `UI_ZeD_Lock_StatusWalking` | `Walking over to the padlock` | Padlock card: footer line while the character walks to the object | - |
| `UI_ZeD_Lock_StatusWorking` | `Working on the padlock` | Padlock card: footer line while a padlock action runs | - |
| `UI_ZeD_Lock_StatusWrong` | `Wrong code: %1. The padlock stays on.` | Padlock card: footer line (red) after a wrong try; %1 is the code with spaces, e.g. 3 1 9 | - |
| `UI_ZeD_Lock_StatusZeroCode` | `Can't lock: a code of 000 does nothing` | Padlock card: footer line | - |
| `UI_ZeD_Lock_WhatItLocks` | `WHAT IT LOCKS` | Padlock card: section heading (capitals) | - |

## Looks

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Looks_AskDeleteOutfit` | `Delete the preset %1?` | Character looks screen (new game): question in the action strip. %1 is the outfit's name | - |
| `UI_ZeD_Looks_AskOutfitName` | `Preset name:` | Character looks screen (new game): label before the name field in the action strip | - |
| `UI_ZeD_Looks_DeleteOutfit` | `Delete %1...` | Character looks screen (new game): row of the Outfits pop-up that deletes the picked saved outfit. %1 is its name | - |
| `UI_ZeD_Looks_Outfits` | `Presets...` | Character looks screen (new game): strip button that opens the saved outfits pop-up | 14 |
| `UI_ZeD_Looks_PresetName` | `Preset` | Character looks screen (new game): the name suggested for a saved outfit when the character has no name | - |
| `UI_ZeD_Looks_PromptOutfits` | `Presets` | Character looks screen (new game): controller prompt (Y button) that opens the saved outfits | 10 |
| `UI_ZeD_Looks_PromptTurn` | `Turn` | Character looks screen (new game): controller prompt for the bumpers, which turn the figure | 10 |
| `UI_ZeD_Looks_SaveOutfit` | `Save preset...` | Character looks screen (new game): row of the Outfits pop-up that saves the current look | - |
| `UI_ZeD_Looks_Title` | `Project Zomboid  +  Character` | Character looks screen (new game): title bar. The + is the ZeD title separator | - |

## Machine

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Machine_AboutDayOne` | `ABOUT 1 DAY` | Craft tab, drying rack: time left, one day | 20 |
| `UI_ZeD_Machine_AboutDays` | `ABOUT %1 DAYS` | Craft tab, drying rack: time left, several days (follows "%1 LEFT") | 20 |
| `UI_ZeD_Machine_AboutHourOne` | `ABOUT 1 HOUR` | Craft tab, drying rack: time left, one hour | 20 |
| `UI_ZeD_Machine_AboutHours` | `ABOUT %1 HOURS` | Craft tab, drying rack: time left, several hours | 20 |
| `UI_ZeD_Machine_AboutMinuteOne` | `ABOUT 1 MINUTE` | Craft tab, drying rack: time left, one minute | 20 |
| `UI_ZeD_Machine_AboutMinutes` | `ABOUT %1 MINUTES` | Craft tab, drying rack: time left, several minutes | 20 |
| `UI_ZeD_Machine_Add` | `ADD` | Craft tab, drying rack: button that adds an item to the rack | 8 |
| `UI_ZeD_Machine_DayEachOne` | `1 DAY EACH` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_DaysEach` | `%1 DAYS EACH` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_FromBags` | `FROM YOUR BAGS` | Craft tab, drying rack: small heading above items you can add | 24 |
| `UI_ZeD_Machine_HourEachOne` | `1 HOUR EACH` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_HoursEach` | `%1 HOURS EACH` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_Left` | `%1 LEFT` | Craft tab, drying rack progress text; %1 is the "ABOUT ..." time phrase | 30 |
| `UI_ZeD_Machine_MinEach` | `%1 MIN EACH` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_NothingFits` | `Nothing you carry fits this rack.` | Craft tab, drying rack: line when none of your items can go on it | - |
| `UI_ZeD_Machine_Recipe` | `RECIPE` | Craft tab, drying rack: small heading before the recipe name | 10 |
| `UI_ZeD_Machine_Start` | `Start` | Craft tab, drying rack: start button | 8 |
| `UI_ZeD_Machine_Stop` | `Stop` | Craft tab, drying rack: stop button | 8 |

## MainMenu

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_MainMenu_AboutDisplay` | `DISPLAY` | About block: left label of the screen size row | 12 |
| `UI_ZeD_MainMenu_AboutEncryption` | `ENCRYPTION` | About block: left label of a fact row (about 12 letters of room) | 12 |
| `UI_ZeD_MainMenu_AboutEncryptionValue` | `16-bit (was 8)` | About block: value of the Encryption row | - |
| `UI_ZeD_MainMenu_AboutGame` | `GAME` | About block: left label of the game version row | 12 |
| `UI_ZeD_MainMenu_AboutPara` | `Zero Day OS is a homemade SECURE kernal of Ynix made by some hard working freedom loving good guys (mostly me). FBI and you government slime, if you are reading this you must have got me--but I got you. This thing has state of the art anti phone tap programming in the BIOS AND we just upgraded from 8 to 16bit encryption that my cousins elementary school friends girlfriends uncle got out of MIT. dont ask. Suck on it commies!! You cant crack ZeD-OS. also it runs off the truck battery if it comes to that. LONG LIVE FREEDOM` | Main menu bar, ZeD menu, About block: the owner's own words (a fictional character's rough draft; keep the misspellings and the run-on, do not tidy) | - |
| `UI_ZeD_MainMenu_AboutPhoneTaps` | `PHONE TAPS` | About block: left label of a fact row (about 12 letters of room) | 12 |
| `UI_ZeD_MainMenu_AboutPhoneTapsValue` | `None found` | About block: value of the Phone taps row | - |
| `UI_ZeD_MainMenu_AboutSub` | `secure Ynix kernal -- DO NOT UNPLUG` | Main menu bar, ZeD menu, About block: the line under the title | - |
| `UI_ZeD_MainMenu_AboutUptime` | `UPTIME` | About block: left label of the row showing how long the game has run | 12 |
| `UI_ZeD_MainMenu_AM` | `AM` | Clock in the main menu dates (12-hour) | 3 |
| `UI_ZeD_MainMenu_AndMore` | `and %1 more` | Pause window, Mods page: last line when the list is cut. %1 is how many more mods there are | - |
| `UI_ZeD_MainMenu_AskQuitGame` | `Quit Project Zomboid?` | Main menu: question in the action strip before quitting the game | - |
| `UI_ZeD_MainMenu_BuildVersion` | `Build %1` | About block: the game's build. %1 is the version number | - |
| `UI_ZeD_MainMenu_DayTime` | `Day %1 \| %2` | Pause window header: the in-game day and the clock. %1 day number, %2 time | - |
| `UI_ZeD_MainMenu_HostGame` | `Host a game` | Main menu bar, Multiplayer menu: opens the Host screen | - |
| `UI_ZeD_MainMenu_JoinServer` | `Join a server` | Main menu bar, Multiplayer menu: opens the Join screen | - |
| `UI_ZeD_MainMenu_KnoxCountry` | `Knox Country` | Main menu and Load: the map line of a save that uses the whole county | - |
| `UI_ZeD_MainMenu_LastPlayed` | `Last played %1` | Main menu Continue card: when the latest save was played. %1 is the date and time | - |
| `UI_ZeD_MainMenu_LoadGame` | `Load game` | Main menu bar, File menu: opens the Load screen | - |
| `UI_ZeD_MainMenu_MainTitle` | `Project Zomboid  +  Main menu` | Main menu: title bar of the main window. The + is the ZeD title separator | - |
| `UI_ZeD_MainMenu_MenuFile` | `File` | Main menu bar: the File menu's title | 12 |
| `UI_ZeD_MainMenu_MenuSettings` | `Settings` | Main menu bar: the Settings menu's title | 12 |
| `UI_ZeD_MainMenu_ModErrors` | `Errors this session` | Pause window, Mods page: status of a mod that raised errors this session | 20 |
| `UI_ZeD_MainMenu_ModNotAvailable` | `Not available` | Pause window, Mods page: status of a mod that is not available | 16 |
| `UI_ZeD_MainMenu_ModNotFound` | `Not found` | Pause window, Mods page: status of an active mod the game cannot find | 16 |
| `UI_ZeD_MainMenu_ModsCount` | `Mods (%1)` | Main menu and pause window: button that opens the mods. %1 is how many are switched on | 14 |
| `UI_ZeD_MainMenu_ModsOn` | `Mods (%1 on)` | Main menu bar, Settings menu: opens the mod manager. %1 is how many mods are switched on | - |
| `UI_ZeD_MainMenu_MonthApr` | `Apr` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthAug` | `Aug` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthDec` | `Dec` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthFeb` | `Feb` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthJan` | `Jan` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthJul` | `Jul` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthJun` | `Jun` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthMar` | `Mar` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthMay` | `May` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthNov` | `Nov` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthOct` | `Oct` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_MonthSep` | `Sep` | Main menu: month abbreviation in a save's title and its last-played date | 4 |
| `UI_ZeD_MainMenu_PausedTitle` | `%1  +  Paused` | Pause window: title bar. %1 is the character's name (or Paused). The + is the ZeD title separator | - |
| `UI_ZeD_MainMenu_PlayedDate` | `%1 %2 %3, %4` | Main menu: when a save was last played. %1 month, %2 day, %3 year, %4 time. Example: Oct 14 2026, 7:52 PM | - |
| `UI_ZeD_MainMenu_PM` | `PM` | Clock in the main menu dates (12-hour) | 3 |
| `UI_ZeD_MainMenu_PromptLegal` | `Legal` | Controller prompt in the footer of the main window (Y button, opens the terms of service) | 10 |
| `UI_ZeD_MainMenu_PromptSelect` | `Select` | Controller prompt in the footer of the main menu, pause window and their screens (A button) | 10 |
| `UI_ZeD_MainMenu_ReportBug` | `Report a bug` | Main menu bar, ZeD menu: opens the bug report page | - |
| `UI_ZeD_MainMenu_SaveAndQuit` | `Save and quit` | Pause window: button that saves and quits to the main menu | 16 |
| `UI_ZeD_MainMenu_SaveDate` | `%1, %2 %3` | Main menu: a save named by date. %1 game mode, %2 month abbreviation, %3 day of the month. Example: Sandbox, Oct 12 | - |
| `UI_ZeD_MainMenu_TermsOfService` | `Terms of service` | Main menu bar, ZeD menu: opens the terms of service | - |
| `UI_ZeD_MainMenu_UptimeHours` | `%1 h %2 min` | About block: uptime of an hour or more. %1 hours, %2 minutes (two digits) | - |
| `UI_ZeD_MainMenu_UptimeMinutes` | `%1 min` | About block: uptime under an hour. %1 minutes | - |
| `UI_ZeD_MainMenu_WallpaperNew` | `New wallpaper` | Main menu bar, Settings menu: picks the new title video as the desktop wallpaper | - |
| `UI_ZeD_MainMenu_WallpaperOriginal` | `Original wallpaper` | Main menu bar, Settings menu: picks the painting as the desktop wallpaper | - |

## Map

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Map_ChangeColor` | `Change color` | Maps tab: right-click menu on a map marking (changes its pen color) | - |
| `UI_ZeD_Map_FoldBack` | `A or click here to fold it back` | Maps tab: placeholder line while the map is open in its own window (A is the controller button) | - |
| `UI_ZeD_Map_NoteDefault` | `Note` | Maps tab: default text of a new map note (saved with the note if left unchanged), the text box's starting text and the cursor preview | - |
| `UI_ZeD_Map_PadFold` | `Fold` | Map window, controller prompt for B (fold the map back into the tab) | 12 |
| `UI_ZeD_Map_PadMove` | `Move` | Map window, controller prompt next to L-STICK | - |
| `UI_ZeD_Map_StyleColor` | `Color` | Maps tab toolbar: map style pill | 10 |
| `UI_ZeD_Map_StylePaper` | `Paper` | Maps tab toolbar: map style pill | 10 |
| `UI_ZeD_Map_StyleSurvey` | `Survey` | Maps tab toolbar: map style pill | 10 |
| `UI_ZeD_Map_Unavailable` | `MAP UNAVAILABLE` | Maps tab: centered message when the world map is turned off | 24 |
| `UI_ZeD_Map_Unfolded` | `MAP UNFOLDED` | Maps tab: placeholder heading while the map is open in its own window | 24 |

## Meta

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Meta_Bite` | `bite %1` | Right-click menu, target card meta line for clothing: bite defence value | - |
| `UI_ZeD_Meta_Condition` | `cond %1%%` | Right-click menu, target card meta line for a weapon: condition percent (%1 is the number, the percent sign stays) | - |
| `UI_ZeD_Meta_FluidAmount` | `%1 / %2 L` | Right-click menu, target card meta line for a fluid container: amount over capacity in litres (%1 amount, %2 capacity) | - |
| `UI_ZeD_Meta_Hunger` | `%1 hunger` | Right-click menu, target card meta line for food: hunger change (%1 is a signed number such as -20) | - |
| `UI_ZeD_Meta_Pages` | `%1 pages` | Right-click menu, target card meta line for a book not yet started: number of pages | - |
| `UI_ZeD_Meta_PagesRead` | `%1 / %2 pages` | Right-click menu, target card meta line for a book: pages read of total | - |
| `UI_ZeD_Meta_Ripe` | `Ripe` | Right-click menu, target card meta line for food that is neither fresh nor stale (the other two words are the game's own Fresh and Stale) | - |
| `UI_ZeD_Meta_Wet` | `wet %1%%` | Right-click menu, target card meta line for clothing: wetness percent | - |

## Modal

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Modal_Confirm` | `Confirm` | Title bar of ZeD's confirm dialog | 24 |
| `UI_ZeD_Modal_Warning` | `Warning` | Title bar of ZeD's warning and danger dialogs | 24 |

## Mods

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Mods_AlsoOff` | `Also turned off (needs it): %1` | Mod manager: note after turning a mod off. %1 is a list of the other mods that went with it | - |
| `UI_ZeD_Mods_AlsoOn` | `Also turned on (needed): %1` | Mod manager: note after turning a mod on. %1 is a list of the other mods that came along | - |
| `UI_ZeD_Mods_AndMore` | `%1 and %2 more` | Mod manager: under a conflict's title: the first thing it names, and how many more. %1 the first, %2 the rest | - |
| `UI_ZeD_Mods_Any` | `any` | Mod manager: stands for no limit in the previous range | - |
| `UI_ZeD_Mods_AskCopyAs` | `Copy as:` | Mod manager: label before the name field in the action strip | - |
| `UI_ZeD_Mods_AskDelete` | `Delete the profile %1?` | Mod manager: question in the action strip. %1 is the profile's name | - |
| `UI_ZeD_Mods_AskKeep` | `Keep the changes to your mods?` | Mod manager: question in the action strip | - |
| `UI_ZeD_Mods_AskNewName` | `New profile name:` | Mod manager: label before the name field in the action strip | - |
| `UI_ZeD_Mods_AskProfileText` | `Profile text:` | Mod manager: label before the field where profile text is pasted | - |
| `UI_ZeD_Mods_AskReplaceMany` | `Replace %1 with the %2 mods on now?` | Mod manager: question in the action strip. %1 profile name, %2 the number | - |
| `UI_ZeD_Mods_AskReplaceOne` | `Replace %1 with the %2 mod on now?` | Mod manager: question in the action strip. %1 profile name, %2 is 1 | - |
| `UI_ZeD_Mods_BitOff` | `%1 turned off` | Mod manager: part of the note after loading a profile. %1 is a number | - |
| `UI_ZeD_Mods_BitOn` | `%1 turned on` | Mod manager: part of the note after loading a profile. %1 is a number | - |
| `UI_ZeD_Mods_BtnAuto` | `Auto` | Mod manager: strip button on the Load order page that sorts by the mods' rules | 10 |
| `UI_ZeD_Mods_BtnLoadOrder` | `Load order` | Mod manager: strip button on the mods list | 14 |
| `UI_ZeD_Mods_BtnMapOrder` | `Map order` | Mod manager: strip button on the mods list | 14 |
| `UI_ZeD_Mods_BtnNew` | `New...` | Mod manager: strip button on the Profiles page | 12 |
| `UI_ZeD_Mods_BtnOpenWorkshop` | `Open the Workshop` | Mod manager: strip button on the Workshop tab | 20 |
| `UI_ZeD_Mods_BtnProfiles` | `Profiles` | Mod manager: strip button on the mods list | 12 |
| `UI_ZeD_Mods_BtnQuitRestart` | `Quit to restart` | Mod manager: strip button when a restart is needed | 18 |
| `UI_ZeD_Mods_BtnReload` | `Reload` | Mod manager: strip button that applies pending changes with a Lua reload | 12 |
| `UI_ZeD_Mods_BtnUpdate` | `Update...` | Mod manager: strip button on the Profiles page | 12 |
| `UI_ZeD_Mods_By` | `by %1` | Mod manager: under a mod's name in its detail pane. %1 is the author | - |
| `UI_ZeD_Mods_ChipConflictMany` | `%1 CONFLICTS` | Mod manager: small caps tag on a mod's row, several conflicts. %1 is the number | 14 |
| `UI_ZeD_Mods_ChipConflictOne` | `%1 CONFLICT` | Mod manager: small caps tag on a mod's row, one conflict. %1 is 1 | 14 |
| `UI_ZeD_Mods_ChipQueued` | `QUEUED` | Mod manager: small caps tag on a mod's row: its download is queued | 12 |
| `UI_ZeD_Mods_ChipUpdate` | `UPDATE` | Mod manager: small caps tag on a mod's row: an update is waiting on Steam | 12 |
| `UI_ZeD_Mods_ChipUpdated` | `UPDATED` | Mod manager: small caps tag on a mod's row: Steam updated it while the game ran | 12 |
| `UI_ZeD_Mods_ConflictsChecking` | `Checking...` | Mod manager: under the Conflicts heading while the scan runs | - |
| `UI_ZeD_Mods_ConflictsHead` | `CONFLICTS` | Mod manager: caps heading in the detail pane over the conflicts | 20 |
| `UI_ZeD_Mods_ConflictsLater` | `Checked once a reload brings it in.` | Mod manager: under the Conflicts heading of a mod that is not loaded yet | - |
| `UI_ZeD_Mods_ConflictsNone` | `None found.` | Mod manager: under the Conflicts heading | - |
| `UI_ZeD_Mods_CopyName` | `%1 copy` | Mod manager: the name suggested for a duplicated profile. %1 is the original's name | - |
| `UI_ZeD_Mods_EmptyChecking` | `Checking the mods for conflicts` | Mod manager: the Conflicts tab while the scan runs | - |
| `UI_ZeD_Mods_EmptyConflicts` | `No conflicts among the mods running now` | Mod manager: empty list on the Conflicts tab | - |
| `UI_ZeD_Mods_EmptyFavs` | `No favourites yet` | Mod manager: empty list on the Starred tab | - |
| `UI_ZeD_Mods_EmptyNone` | `No mods match` | Mod manager: empty list when Find matches nothing | - |
| `UI_ZeD_Mods_EmptyProblems` | `Every mod can run` | Mod manager: empty list on the Problems tab | - |
| `UI_ZeD_Mods_HiddenMany` | `%1 conflicts hidden.` | Mod manager: under the list of conflicts | - |
| `UI_ZeD_Mods_HiddenOne` | `%1 conflict hidden.` | Mod manager: under the list of conflicts | - |
| `UI_ZeD_Mods_KvGame` | `GAME` | Mod manager: caps label in the detail pane: the game versions the mod supports | 12 |
| `UI_ZeD_Mods_KvLoadOrder` | `LOAD ORDER` | Mod manager: caps label in the detail pane and heading on the Profiles page | 12 |
| `UI_ZeD_Mods_KvReplaces` | `REPLACES` | Mod manager: caps label in the detail pane: the game's scripts the mod replaces | 12 |
| `UI_ZeD_Mods_KvSize` | `SIZE` | Mod manager: caps label in the Workshop item's detail pane | 12 |
| `UI_ZeD_Mods_KvType` | `TYPE` | Mod manager: caps label in the detail pane (map, vehicle...) | 12 |
| `UI_ZeD_Mods_KvUpdated` | `UPDATED` | Mod manager: caps label in the Workshop item's detail pane | 12 |
| `UI_ZeD_Mods_ListCannotWith` | `CANNOT RUN WITH` | Mod manager: caps heading in the detail pane over the mods it is incompatible with | 20 |
| `UI_ZeD_Mods_ListNeeds` | `NEEDS` | Mod manager: caps heading in the detail pane over the mods it needs | 20 |
| `UI_ZeD_Mods_ListNotInstalled` | `%1, not installed` | Mod manager: a required mod that is not installed; also in a profile's order. %1 is the mod's name or id | - |
| `UI_ZeD_Mods_ListOff` | `%1, off` | Mod manager: a required mod and its state. %1 is its name | - |
| `UI_ZeD_Mods_ListOn` | `%1, on` | Mod manager: a required mod and its state. %1 is its name | - |
| `UI_ZeD_Mods_LoadOrderChanged` | `Load order changed` | Mod manager: in the strip, what is pending when only the order changed | - |
| `UI_ZeD_Mods_MapRule` | `Maps nearer the top win where they overlap` | Mod manager: map order rule | - |
| `UI_ZeD_Mods_MapShares` | `Shares map cells with: %1` | Mod manager: map order rule. %1 is a list of maps | - |
| `UI_ZeD_Mods_MoreAllOn` | `Turn every mod on` | Mod manager: row of the More pop-up | - |
| `UI_ZeD_Mods_MoreCopyText` | `Copy as text` | Mod manager: row of the More pop-up | - |
| `UI_ZeD_Mods_MoreDelete` | `Delete %1...` | Mod manager: row of the More pop-up. %1 is the profile's name | - |
| `UI_ZeD_Mods_MoreDuplicate` | `Duplicate %1...` | Mod manager: row of the More pop-up. %1 is the profile's name | - |
| `UI_ZeD_Mods_MorePaste` | `Paste profile text...` | Mod manager: row of the More pop-up | - |
| `UI_ZeD_Mods_MoreRename` | `Rename %1...` | Mod manager: row of the More pop-up. %1 is the profile's name | - |
| `UI_ZeD_Mods_NMods` | `%1 mods` | Mod manager: '3 mods', in the sentence about Steam updating several mods | - |
| `UI_ZeD_Mods_NoMods` | `No mods` | Mod manager: the first profile on the Profiles page: every mod off | - |
| `UI_ZeD_Mods_OrderOf` | `%1 of %2` | Mod manager: the mod's place in the load order. %1 its place, %2 how many mods are on | - |
| `UI_ZeD_Mods_PendingReload` | `%1. A reload covers it, no restart.` | Mod manager: in the strip: what is pending (%1) and that a reload is enough | - |
| `UI_ZeD_Mods_PendingThenSteam` | `%1. %2` | Mod manager: in the strip: what is pending (%1), then the Steam sentence (%2) | - |
| `UI_ZeD_Mods_ProbCannot` | `Cannot run` | Mod manager: why a mod cannot be turned on | - |
| `UI_ZeD_Mods_ProbCannotLower` | `cannot run` | Mod manager: the reason in the previous line when there is none | - |
| `UI_ZeD_Mods_ProbConflicts` | `Conflicts with %1` | Mod manager: why a mod cannot be turned on. %1 is a list of mods that are on | - |
| `UI_ZeD_Mods_ProbNeeds` | `Needs %1` | Mod manager: why a mod cannot be turned on. %1 is a list of mods it needs | - |
| `UI_ZeD_Mods_ProbVersion` | `Made for another game version` | Mod manager: why a mod cannot be turned on (red dot) | - |
| `UI_ZeD_Mods_ProbVersionRange` | `Made for another game version (%1 to %2)` | Mod manager: why a mod cannot be turned on. %1 and %2 are the lowest and highest game version it supports | - |
| `UI_ZeD_Mods_ProfCannot` | `Cannot run %1: stays off` | Mod manager: what loading the profile does. %1 how many | - |
| `UI_ZeD_Mods_ProfCannotRow` | `%1 (%2)` | Mod manager: a mod that cannot run and why. %1 the mod's name, %2 the reason | - |
| `UI_ZeD_Mods_ProfCountMany` | `%1 mods` | Mod manager: under a profile's name. %1 is the number | - |
| `UI_ZeD_Mods_ProfCountManyMissing` | `%1 mods, %2 not installed` | Mod manager: under a profile with missing mods. %1 how many, %2 how many are missing | - |
| `UI_ZeD_Mods_ProfCountManyOn` | `%1 mods, on now` | Mod manager: under a profile that matches the mods on now. %1 is the number | - |
| `UI_ZeD_Mods_ProfCountOne` | `%1 mod` | Mod manager: under a profile's name. %1 is 1 | - |
| `UI_ZeD_Mods_ProfCountOneMissing` | `%1 mod, %2 not installed` | Mod manager: under a profile with a missing mod. %1 is 1, %2 how many are missing | - |
| `UI_ZeD_Mods_ProfCountOneOn` | `%1 mod, on now` | Mod manager: under a profile that matches the mods on now. %1 is 1 | - |
| `UI_ZeD_Mods_ProfEveryOff` | `Every mod off` | Mod manager: under the No mods row of the Profiles page | - |
| `UI_ZeD_Mods_ProfLastLoaded` | `Last loaded %1` | Mod manager: the picked profile's facts. %1 is the date | - |
| `UI_ZeD_Mods_ProfLoadingIt` | `LOADING IT` | Mod manager: caps heading on the Profiles page over what loading the profile does | 16 |
| `UI_ZeD_Mods_ProfMissing` | `Not installed %1: stays off` | Mod manager: what loading the profile does. %1 how many | - |
| `UI_ZeD_Mods_ProfNoChange` | `Changes nothing: these are the mods on now` | Mod manager: what loading the profile does | - |
| `UI_ZeD_Mods_ProfNothingOnOff` | `Turns nothing on or off` | Mod manager: what loading the profile does | - |
| `UI_ZeD_Mods_ProfPlain` | `Plain Project Zomboid` | Mod manager: the picked No mods profile's facts | - |
| `UI_ZeD_Mods_ProfSaved` | `saved %1` | Mod manager: the picked profile's facts. %1 is the date it was saved | - |
| `UI_ZeD_Mods_ProfSortedByRules` | `Sorted by the mods' own rules` | Mod manager: under a profile's load order when it keeps none | - |
| `UI_ZeD_Mods_ProfTurnsOff` | `Turns off %1` | Mod manager: what loading the profile does. %1 how many | - |
| `UI_ZeD_Mods_ProfTurnsOn` | `Turns on %1` | Mod manager: what loading the profile does. %1 how many | - |
| `UI_ZeD_Mods_PromptFavourite` | `Favourite` | Mod manager: controller prompt (X button) on the mods list | 12 |
| `UI_ZeD_Mods_PromptFilter` | `Filter` | Mod manager: controller prompt for the bumpers, which switch the filter tabs | 10 |
| `UI_ZeD_Mods_PromptNew` | `New` | Mod manager: controller prompt (Y button) on the Profiles page | 10 |
| `UI_ZeD_Mods_PromptOnOff` | `On / off` | Mod manager: controller prompt (A button) on the mods list | 12 |
| `UI_ZeD_Mods_Replace` | `Replace` | Mod manager: strip button that replaces a profile with the mods on now | 12 |
| `UI_ZeD_Mods_RuleAfter` | `Loads after: %1` | Mod manager: load order rules of the picked mod. %1 is a list of mods | - |
| `UI_ZeD_Mods_RuleBad` | `A mod it needs loads after it; "Done" waits until it is fixed` | Mod manager: red note (Done is the name of the Done button) | - |
| `UI_ZeD_Mods_RuleBefore` | `Loads before: %1` | Mod manager: load order rules of the picked mod. %1 is a list of mods | - |
| `UI_ZeD_Mods_RuleFix` | `Fix the red rows (or press "Auto") to set the order` | Mod manager: red note (Auto is the name of the Auto button) | - |
| `UI_ZeD_Mods_RuleNeeds` | `Needs, loaded first: %1` | Mod manager: load order rules of the picked mod. %1 is a list of mods | - |
| `UI_ZeD_Mods_RuleNone` | `No order rules` | Mod manager: load order rules of the picked mod | - |
| `UI_ZeD_Mods_RuleSoft` | `Its load-before / load-after wish is not kept` | Mod manager: amber note | - |
| `UI_ZeD_Mods_SameDefinition` | `Same definition as %1` | Mod manager: a conflict's title, one script of mixed kinds. %1 is the other mod's name | - |
| `UI_ZeD_Mods_SameDefinitions` | `Same %1 definitions as %2` | Mod manager: a conflict's title, several scripts of mixed kinds. %1 how many, %2 the other mod's name | - |
| `UI_ZeD_Mods_SameFile` | `Same file as %1` | Mod manager: a conflict's title, one Lua file. %1 is the other mod's name | - |
| `UI_ZeD_Mods_SameFiles` | `Same %1 files as %2` | Mod manager: a conflict's title, several Lua files. %1 how many, %2 the other mod's name | - |
| `UI_ZeD_Mods_SayAdded` | `Added %1` | Mod manager: note after pasting a profile. %1 is its name | - |
| `UI_ZeD_Mods_SayAllOn` | `Every mod that can run is on` | Mod manager: note after Turn every mod on | - |
| `UI_ZeD_Mods_SayCopied` | `Copied %1 as %2` | Mod manager: note after duplicating a profile. %1 old name, %2 new name | - |
| `UI_ZeD_Mods_SayCopiedText` | `Copied %1 to the clipboard as text` | Mod manager: note. %1 is the profile's name | - |
| `UI_ZeD_Mods_SayDeleted` | `Deleted %1` | Mod manager: note. %1 is the profile's name | - |
| `UI_ZeD_Mods_SayDiscarded` | `Changes discarded` | Mod manager: note | - |
| `UI_ZeD_Mods_SayLoadAfter` | `%1 now loads after %2. Reload to put it to work.` | Mod manager: note after the fix button of a conflict. %1 and %2 are mod names | - |
| `UI_ZeD_Mods_SayLoaded` | `Loaded %1` | Mod manager: note after loading a profile that changed nothing. %1 is the profile's name | - |
| `UI_ZeD_Mods_SayLoadedBits` | `Loaded %1: %2` | Mod manager: note after loading a profile. %1 is its name, %2 is e.g. '3 turned on, 1 turned off' | - |
| `UI_ZeD_Mods_SayMapsSet` | `Map order set` | Mod manager: note | - |
| `UI_ZeD_Mods_SayNoMods` | `No mods: %1 turned off` | Mod manager: note after loading the No mods profile. %1 is how many were turned off | - |
| `UI_ZeD_Mods_SayNothingToAdd` | `Nothing to add: the text is not a profile` | Mod manager: note after pasting text that is not a profile | - |
| `UI_ZeD_Mods_SayNotInstalled` | `%1. Not installed: %2` | Mod manager: the note after loading, plus the mods the profile names that are not installed. %1 the note, %2 a list | - |
| `UI_ZeD_Mods_SayOrderSet` | `Load order set` | Mod manager: note | - |
| `UI_ZeD_Mods_SayRenamed` | `Renamed %1 to %2` | Mod manager: note. %1 old name, %2 new name | - |
| `UI_ZeD_Mods_SaySaved` | `Saved %1 (%2 mods)` | Mod manager: note after saving a profile. %1 its name, %2 how many mods | - |
| `UI_ZeD_Mods_SayUpdated` | `Updated %1 to the mods on now` | Mod manager: note. %1 is the profile's name | - |
| `UI_ZeD_Mods_StatOn` | `%1 of %2 on` | Mod manager: status in the title bar. %1 mods on, %2 mods in all | - |
| `UI_ZeD_Mods_SteamUpdatedMany` | `Steam updated %1: their new pictures need a restart.` | Mod manager: in the strip. %1 is 'A and B' or '3 mods' | - |
| `UI_ZeD_Mods_SteamUpdatedOne` | `Steam updated %1: its new pictures need a restart.` | Mod manager: in the strip. %1 is the mod's name | - |
| `UI_ZeD_Mods_TabAll` | `All %1` | Mod manager: filter tab. %1 is the count | 14 |
| `UI_ZeD_Mods_TabConflicts` | `Conflicts %1` | Mod manager: filter tab. %1 is the count | 14 |
| `UI_ZeD_Mods_TabMaps` | `Maps %1` | Mod manager: filter tab. %1 is the count | 14 |
| `UI_ZeD_Mods_TabOn` | `On %1` | Mod manager: filter tab. %1 is the count | 14 |
| `UI_ZeD_Mods_TabProblems` | `Problems %1` | Mod manager: filter tab. %1 is the count | 14 |
| `UI_ZeD_Mods_TabStarred` | `Starred %1` | Mod manager: filter tab. %1 is the count | 14 |
| `UI_ZeD_Mods_TabWorkshop` | `Workshop %1` | Mod manager: filter tab. %1 is the count | 14 |
| `UI_ZeD_Mods_TagMissing` | `NOT INSTALLED` | Mod manager: small caps tag on a Workshop tab row | 16 |
| `UI_ZeD_Mods_TagOk` | `UP TO DATE` | Mod manager: small caps tag on a Workshop tab row | 16 |
| `UI_ZeD_Mods_TagQueued` | `DOWNLOAD QUEUED` | Mod manager: small caps tag on a Workshop tab row | 16 |
| `UI_ZeD_Mods_TagUpdate` | `UPDATE WAITING` | Mod manager: small caps tag on a Workshop tab row | 16 |
| `UI_ZeD_Mods_Title` | `Mods` | Mod manager: title bar section (after 'Project Zomboid  +  ') | - |
| `UI_ZeD_Mods_TitleFmt` | `Project Zomboid  +  %1` | Mod manager: title bar. %1 is one of the section names above. The + is the ZeD title separator | - |
| `UI_ZeD_Mods_TitleMaps` | `Map order` | Mod manager: title bar section | - |
| `UI_ZeD_Mods_TitleOrder` | `Load order` | Mod manager: title bar section | - |
| `UI_ZeD_Mods_TitleProfiles` | `Mod profiles` | Mod manager: title bar section | - |
| `UI_ZeD_Mods_TitleServer` | `Server mods` | Mod manager: title bar section while choosing the mods of a server | - |
| `UI_ZeD_Mods_TitleServerMaps` | `Server map order` | Mod manager: title bar section | - |
| `UI_ZeD_Mods_TitleServerOrder` | `Server load order` | Mod manager: title bar section | - |
| `UI_ZeD_Mods_TitleServerProfiles` | `Server mod profiles` | Mod manager: title bar section | - |
| `UI_ZeD_Mods_TurnedOffMany` | `%1 mods turned off` | Mod manager: in the strip, what is pending, when nothing was turned on. %1 is the number | - |
| `UI_ZeD_Mods_TurnedOffOne` | `%1 mod turned off` | Mod manager: in the strip, what is pending, when nothing was turned on. %1 is 1 | - |
| `UI_ZeD_Mods_TurnedOffShort` | `%1 turned off` | Mod manager: in the strip, after '3 mods turned on, ': the second part. %1 is the number | - |
| `UI_ZeD_Mods_TurnedOnMany` | `%1 mods turned on` | Mod manager: in the strip, what is pending. %1 is the number | - |
| `UI_ZeD_Mods_TurnedOnOne` | `%1 mod turned on` | Mod manager: in the strip, what is pending. %1 is 1 | - |
| `UI_ZeD_Mods_UpdatedAgoLower` | `updated %1` | Mod manager: part of the Workshop fact, after a \| separator. %1 is e.g. '3 days ago' | - |
| `UI_ZeD_Mods_UpdatedNote` | `Steam updated this mod while the game ran. A reload brings in its new code and scripts; pictures it already showed stay old until the game restarts.` | Mod manager: note in the detail pane | - |
| `UI_ZeD_Mods_UpdatedWhileRan` | `Updated while the game ran` | Mod manager: value of the Workshop fact | - |
| `UI_ZeD_Mods_VerbFavourite` | `Favourite` | Mod manager: detail pane button | 16 |
| `UI_ZeD_Mods_VerbHide` | `Fine, hide this` | Mod manager: button that hides a conflict | 20 |
| `UI_ZeD_Mods_VerbLoadAfter` | `Load %1 after it` | Mod manager: button that moves a mod after the winner in the load order. %1 is its (shortened) name | - |
| `UI_ZeD_Mods_VerbShowAgain` | `Show again` | Mod manager: button that shows hidden conflicts again | 14 |
| `UI_ZeD_Mods_VerbUnfavourite` | `Unfavourite` | Mod manager: detail pane button | 16 |
| `UI_ZeD_Mods_VersionRange` | `%1 to %2` | Mod manager: the game versions a mod supports. %1 lowest, %2 highest (either may be 'any') | - |
| `UI_ZeD_Mods_WhyCollection` | `A collection: its items show in this list on their own as Steam fetches them.` | Mod manager: note in the Workshop item's pane | - |
| `UI_ZeD_Mods_WhyFetching` | `Steam is fetching it on its own. This screen notices when it lands.` | Mod manager: note in the Workshop item's pane | - |
| `UI_ZeD_Mods_WhyFile` | `%1 loads later, so its copy is the one the game uses; %2's copy never runs.` | Mod manager: explains a Lua file conflict. %1 the winning mod, %2 the losing mod | - |
| `UI_ZeD_Mods_WhyFixed` | `%1 loads after it once you reload.` | Mod manager: added to the explanation. %1 is the losing mod | - |
| `UI_ZeD_Mods_WhyMissing` | `You subscribe to it, but Steam has not downloaded it yet. Steam fetches Workshop items on its own (the game cannot start a download); it shows up here once it lands.` | Mod manager: note in the Workshop item's pane | - |
| `UI_ZeD_Mods_WhyNeeds` | `%1 needs %2, so this looks deliberate.` | Mod manager: added to the explanation. %1 the winning mod, %2 the losing mod | - |
| `UI_ZeD_Mods_WhyNoMod` | `Installed, but no mod in it matches this game. It may hold mods for another version of the game.` | Mod manager: note in the Workshop item's pane | - |
| `UI_ZeD_Mods_WhyScriptMany` | `Both define them; %1's versions win. The game reads these by file name, not load order, so moving either mod changes nothing. Usually fine when one mod is a fix for the other.` | Mod manager: explains a script conflict about several things. %1 is the winning mod | - |
| `UI_ZeD_Mods_WhyScriptOne` | `Both define it; %1's version wins. The game reads these by file name, not load order, so moving either mod changes nothing. Usually fine when one mod is a fix for the other.` | Mod manager: explains a script conflict about one thing. %1 is the winning mod | - |
| `UI_ZeD_Mods_WsAsking` | `Asking Steam` | Mod manager: the Workshop tab while Steam answers | - |
| `UI_ZeD_Mods_WsCollection` | `Collection of %1` | Mod manager: value of the Workshop fact for a collection. %1 is how many items | - |
| `UI_ZeD_Mods_WsCollectionItems` | `Collection of %1 items` | Mod manager: under a Workshop collection's name. %1 is how many items | - |
| `UI_ZeD_Mods_WsNoSteam` | `Steam is not running, so there is no Workshop to read` | Mod manager: empty Workshop tab | - |
| `UI_ZeD_Mods_WsNotFetched` | `Subscribed, Steam has not fetched it` | Mod manager: under a Workshop item that is not downloaded yet | - |
| `UI_ZeD_Mods_WsNothing` | `Nothing subscribed on the Workshop` | Mod manager: empty Workshop tab | - |
| `UI_ZeD_Mods_WsUpdatedAgo` | `Updated %1` | Mod manager: under a Workshop item. %1 is e.g. '3 days ago' | - |

## ModScan

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_ModScan_AgoDate` | `%1 %2, %3` | Mod manager: conflicts and Workshop state: a date, for an update older than two weeks. %1 month abbreviation, %2 day, %3 year | - |
| `UI_ZeD_ModScan_AgoDays` | `%1 days ago` | Mod manager: conflicts and Workshop state: when a Workshop item was last updated. %1 is days (2 or more) | - |
| `UI_ZeD_ModScan_AgoHour` | `within the hour` | Mod manager: conflicts and Workshop state: when a Workshop item was last updated | - |
| `UI_ZeD_ModScan_AgoHours` | `%1 h ago` | Mod manager: conflicts and Workshop state: when a Workshop item was last updated. %1 is whole hours (1 to 23) | - |
| `UI_ZeD_ModScan_AgoYesterday` | `yesterday` | Mod manager: conflicts and Workshop state: when a Workshop item was last updated | - |
| `UI_ZeD_ModScan_CountBuilding` | `%1 building` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, one: %1 is 1 | - |
| `UI_ZeD_ModScan_CountBuildings` | `%1 buildings` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, several: %1 is the number | - |
| `UI_ZeD_ModScan_CountItem` | `%1 item` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, one: %1 is 1 | - |
| `UI_ZeD_ModScan_CountItems` | `%1 items` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, several: %1 is the number | - |
| `UI_ZeD_ModScan_CountModel` | `%1 model` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, one: %1 is 1 | - |
| `UI_ZeD_ModScan_CountModels` | `%1 models` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, several: %1 is the number | - |
| `UI_ZeD_ModScan_CountRecipe` | `%1 recipe` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, one: %1 is 1 | - |
| `UI_ZeD_ModScan_CountRecipes` | `%1 recipes` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, several: %1 is the number | - |
| `UI_ZeD_ModScan_CountVehicle` | `%1 vehicle` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, one: %1 is 1 | - |
| `UI_ZeD_ModScan_CountVehicles` | `%1 vehicles` | Mod manager: conflicts and Workshop state: a count of the game's scripts a mod replaces, several: %1 is the number | - |
| `UI_ZeD_ModScan_ListAnd` | `%1 and %2` | Mod manager: conflicts and Workshop state: joins a list: %1 is the first part (maybe already a comma list), %2 the last | - |
| `UI_ZeD_ModScan_SameBuilding` | `Same building as %1` | Mod manager: title of a conflict card, one script. %1 is the other mod's name | - |
| `UI_ZeD_ModScan_SameBuildings` | `Same %1 buildings as %2` | Mod manager: conflicts and Workshop state: title of a conflict card, several scripts. %1 is the number, %2 the other mod's name | - |
| `UI_ZeD_ModScan_SameItem` | `Same item as %1` | Mod manager: title of a conflict card, one script. %1 is the other mod's name | - |
| `UI_ZeD_ModScan_SameItems` | `Same %1 items as %2` | Mod manager: conflicts and Workshop state: title of a conflict card, several scripts. %1 is the number, %2 the other mod's name | - |
| `UI_ZeD_ModScan_SameModel` | `Same model as %1` | Mod manager: title of a conflict card, one script. %1 is the other mod's name | - |
| `UI_ZeD_ModScan_SameModels` | `Same %1 models as %2` | Mod manager: conflicts and Workshop state: title of a conflict card, several scripts. %1 is the number, %2 the other mod's name | - |
| `UI_ZeD_ModScan_SameRecipe` | `Same recipe as %1` | Mod manager: title of a conflict card, one script. %1 is the other mod's name | - |
| `UI_ZeD_ModScan_SameRecipes` | `Same %1 recipes as %2` | Mod manager: conflicts and Workshop state: title of a conflict card, several scripts. %1 is the number, %2 the other mod's name | - |
| `UI_ZeD_ModScan_SameVehicle` | `Same vehicle as %1` | Mod manager: title of a conflict card, one script. %1 is the other mod's name | - |
| `UI_ZeD_ModScan_SameVehicles` | `Same %1 vehicles as %2` | Mod manager: conflicts and Workshop state: title of a conflict card, several scripts. %1 is the number, %2 the other mod's name | - |
| `UI_ZeD_ModScan_TheGames` | `the game's %1` | Mod manager: conflicts and Workshop state: 'Replaces' line of a mod: %1 is a list such as 3 items and 2 recipes | - |
| `UI_ZeD_ModScan_ThingBuilding` | `building "%1"` | Mod manager: conflicts and Workshop state: one conflicting script, e.g. item "Base.Axe". %1 is the script's id (keep it in quotes) | - |
| `UI_ZeD_ModScan_ThingItem` | `item "%1"` | Mod manager: conflicts and Workshop state: one conflicting script, e.g. item "Base.Axe". %1 is the script's id (keep it in quotes) | - |
| `UI_ZeD_ModScan_ThingModel` | `model "%1"` | Mod manager: conflicts and Workshop state: one conflicting script, e.g. item "Base.Axe". %1 is the script's id (keep it in quotes) | - |
| `UI_ZeD_ModScan_ThingRecipe` | `recipe "%1"` | Mod manager: conflicts and Workshop state: one conflicting script, e.g. item "Base.Axe". %1 is the script's id (keep it in quotes) | - |
| `UI_ZeD_ModScan_ThingVehicle` | `vehicle "%1"` | Mod manager: conflicts and Workshop state: one conflicting script, e.g. item "Base.Axe". %1 is the script's id (keep it in quotes) | - |
| `UI_ZeD_ModScan_WsMissing` | `Not installed` | Mod manager: conflicts and Workshop state: Workshop state of a subscribed item | 24 |
| `UI_ZeD_ModScan_WsOk` | `Up to date` | Mod manager: conflicts and Workshop state: Workshop state of a subscribed item | 24 |
| `UI_ZeD_ModScan_WsQueued` | `Download queued` | Mod manager: conflicts and Workshop state: Workshop state of a subscribed item | 24 |
| `UI_ZeD_ModScan_WsUpdate` | `Update waiting` | Mod manager: conflicts and Workshop state: Workshop state of a subscribed item | 24 |

## NewGame

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_NewGame_PromptChooseMods` | `Choose mods` | New game screen: controller prompt (Y button) | 14 |
| `UI_ZeD_NewGame_Title` | `Project Zomboid  +  New game` | New game screen: title bar. The + is the ZeD title separator | - |
| `UI_ZeD_NewGame_TitleChallenges` | `Project Zomboid  +  Challenges` | New game screen: title bar while the challenges are shown | - |

## Notebook

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Notebook_AddLine` | `Add a line to page %1...` | Character window, Journal tab, Notebooks sub-tab: placeholder of the quick note box (%1 = page) | 36 |
| `UI_ZeD_Notebook_Find` | `Find in your notes...` | Character window, Journal tab, Notebooks sub-tab: placeholder in the search box | 30 |
| `UI_ZeD_Notebook_Into` | `Into: %1` | Character window, Journal tab, Journal sub-tab: pill left of Save that picks a notebook (%1 = the notebook's name, or the log-only phrase) | 30 |
| `UI_ZeD_Notebook_Kind` | `Notebook` | Notebooks sub-tab: kind of book shown when the game gives no item name (rare fallback) | 16 |
| `UI_ZeD_Notebook_LogOnly` | `the log only` | Character window, Journal tab: value of the Into pill when no notebook is chosen (goes after 'Into: ') | 20 |
| `UI_ZeD_Notebook_NoneCarried` | `No notebook on you` | Character window, Journal tab, Notebooks sub-tab: empty list, the character carries no notebook, journal or diary | 40 |
| `UI_ZeD_Notebook_NoneMatch` | `None of your notebooks has that` | Character window, Journal tab, Notebooks sub-tab: empty list, nothing matches the search | 40 |
| `UI_ZeD_Notebook_NoRoomIn` | `No room in %1` | Character window, Journal tab, Journal sub-tab: note beside the Into pill when the chosen notebook is full (%1 = its name) | 40 |
| `UI_ZeD_Notebook_NoRoomPage` | `No room left on this page` | Character window, Journal tab, Notebooks sub-tab: status line after Write when the line does not fit the page | 40 |
| `UI_ZeD_Notebook_ReadyMany` | `Pencil or pen at hand \| light enough \| %1 lines left on this page` | Character window, Journal tab, Notebooks sub-tab: status line under the note box (%1 = lines left) | 70 |
| `UI_ZeD_Notebook_ReadyOne` | `Pencil or pen at hand \| light enough \| 1 line left on this page` | Character window, Journal tab, Notebooks sub-tab: status line under the note box, one line left | 70 |
| `UI_ZeD_Notebook_SubBlank` | `%1 \| blank \| %2 pages` | Character window, Journal tab, Notebooks sub-tab: second line of a book row with nothing written (%1 = kind of book, %2 = pages in it) | 36 |
| `UI_ZeD_Notebook_SubLockedMany` | `Locked \| %1 pages` | Character window, Journal tab, Notebooks sub-tab: second line of a book row, locked by someone else (%1 = pages written) | 24 |
| `UI_ZeD_Notebook_SubLockedOne` | `Locked \| 1 page` | Character window, Journal tab, Notebooks sub-tab: second line of a book row, a book locked by someone else with one page written | 24 |
| `UI_ZeD_Notebook_SubWritten` | `%1 \| %2 of %3 pages` | Character window, Journal tab, Notebooks sub-tab: second line of a book row (%1 = kind of book, %2 = pages written, %3 = pages in it) | 36 |
| `UI_ZeD_Notebook_WhyLockedMine` | `Locked: unlock it on the full page to write` | Notebooks sub-tab status line and Journal sub-tab note: the character locked the book themselves | 60 |
| `UI_ZeD_Notebook_WhyLockedOther` | `Locked by its writer` | Notebooks sub-tab status line and Journal sub-tab note: why the character cannot write | 40 |
| `UI_ZeD_Notebook_WhyNoTool` | `No pencil or pen` | Notebooks sub-tab status line and Journal sub-tab note: nothing to write with | 40 |
| `UI_ZeD_Notebook_WhyTooDark` | `Too dark to write` | Notebooks sub-tab status line and Journal sub-tab note: not enough light | 40 |
| `UI_ZeD_Notebook_Write` | `Write` | Character window, Journal tab, Notebooks sub-tab: button that writes the quick note onto the page (shown in sentence case) | 12 |
| `UI_ZeD_Notebook_Writing` | `Writing...` | Character window, Journal tab, Notebooks sub-tab and the Journal sub-tab's Into line: status while the character writes | 14 |

## ObjCard

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_ObjCard_CloseCard` | `Close card` | Controller button prompt (B) while an object card is open and nothing is being confirmed | 16 |
| `UI_ZeD_ObjCard_Done` | `DONE` | Object cards, cooking rows: right of the bar on cooked food (capitals) | 6 |
| `UI_ZeD_ObjCard_GaugeE` | `E` | Object cards, fuel gauge face: the empty end of the needle's arc (one letter) | 2 |
| `UI_ZeD_ObjCard_GaugeF` | `F` | Object cards, fuel gauge face: the full end of the needle's arc (one letter) | 2 |
| `UI_ZeD_ObjCard_Hours` | `%1 h` | Object cards: a duration of whole hours (e.g. 3 h) | 10 |
| `UI_ZeD_ObjCard_HoursMinutes` | `%1 h %2 m` | Object cards: a duration of hours and minutes (e.g. 2 h 20 m) in times left and fuel left; h and m stand for hours and minutes | 14 |
| `UI_ZeD_ObjCard_MinLeft` | `%1m` | Object cards, cooking rows: minutes left to cook or to burn, right of the bar (e.g. 12m) | 6 |
| `UI_ZeD_ObjCard_Minutes` | `%1 m` | Object cards: a duration under an hour (e.g. 45 m) | 10 |
| `UI_ZeD_ObjCard_TagRaw` | `RAW` | Object cards, cooking rows: tag on raw food while the heat is off (capitals, in a bordered tag) | 10 |
| `UI_ZeD_ObjCard_WhereNearby` | `NEARBY` | Object cards, pick lists: where an item sits when it is not in the inventory and not in a named bag (capitals) | 12 |

## Options

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Options_AlsoIn` | `Also in %1 \| %2` | Options screen (groups): small line under a game setting copied into ZeD setup. %1 is the page it also lives on, %2 the section | 30 |
| `UI_ZeD_Options_AskDiscardMany` | `Discard %1 changes?` | Options screen: question in the action strip. %1 is how many settings changed (2 or more) | - |
| `UI_ZeD_Options_AskDiscardOne` | `Discard 1 change?` | Options screen: question in the action strip when leaving or discarding one changed setting | - |
| `UI_ZeD_Options_AskDup` | `%1 is already %2.` | Options screen: question in the action strip when a key is taken. %1 is the key, %2 the action that has it | - |
| `UI_ZeD_Options_AskKey` | `Press a key or mouse button for %1.` | Options screen: question in the action strip while binding a key. %1 is the action's name | - |
| `UI_ZeD_Options_AskKeyIt` | `it` | Options screen: stands in for the action's name in the previous sentence when it has none | - |
| `UI_ZeD_Options_AskMonitorMany` | `Keep these screen settings? Going back in %1 seconds.` | Options screen: question in the action strip after changing the screen mode. %1 is the seconds left | - |
| `UI_ZeD_Options_AskMonitorOne` | `Keep these screen settings? Going back in 1 second.` | Options screen: question in the action strip after changing the screen mode, one second left | - |
| `UI_ZeD_Options_AskValue` | `Value:` | Options screen: label before the text field of a mod's text setting, in the action strip | - |
| `UI_ZeD_Options_ButtonMap` | `Button map` | Options screen: name of the row that opens the button map | - |
| `UI_ZeD_Options_ButtonMapAndTest` | `Button map and test` | Options screen: name of the row that opens the controller setup | - |
| `UI_ZeD_Options_Changed` | `Changed` | Options screen: status word in the title bar while any setting is changed and not applied | 12 |
| `UI_ZeD_Options_ChangedNote` | `Changed: Apply to keep it.` | Options screen: help band for a changed setting that has no help of its own | - |
| `UI_ZeD_Options_ControllerTest` | `Controller test` | Options screen: name of the row that opens the controller test (Controls group) | - |
| `UI_ZeD_Options_DefaultIs` | `Default: %1` | (existing) | - |
| `UI_ZeD_Options_Defaults` | `Defaults` | (existing) | - |
| `UI_ZeD_Options_Discard` | `Discard` | Options screen: strip button, footer prompt: throw the changes away | 12 |
| `UI_ZeD_Options_Find` | `Find:` | Options screen: label of the search box over the page list | 10 |
| `UI_ZeD_Options_FirstRunNote` | `First time with ZeD: these set the game up for ZeD's look. Change what you like, then Apply. They stay here, and each game setting is in its own group too.` | Options screen: note on top of ZeD setup the first time the game starts with ZeD | - |
| `UI_ZeD_Options_GoBack` | `Go back` | Options screen: strip button that returns to the previous screen settings | 12 |
| `UI_ZeD_Options_GroupControls` | `Controls` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupDisplay` | `Display` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupGraphics` | `Graphics` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupInterface` | `Interface` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupZed` | `ZeD setup` | Options screen (groups): page list entry: ZeD's own settings and the game settings its look depends on | 22 |
| `UI_ZeD_Options_HeadGameSettings` | `Game settings ZeD uses` | Options screen (groups): section heading in ZeD setup over the game's settings that ZeD depends on (shown in caps) | - |
| `UI_ZeD_Options_HeadLook` | `ZeD's look` | Options screen (groups): section heading in ZeD setup over ZeD's own settings (shown in caps) | - |
| `UI_ZeD_Options_HelpDeadzone` | `How far a stick must move before the game counts it, for the controller picked under Test Controller.` | Options screen: help band for the deadzone row | - |
| `UI_ZeD_Options_HelpKey` | `Click the key, then press the new one (or a mouse button).` | Options screen: help band under the list while a key binding row is under the pointer | - |
| `UI_ZeD_Options_HelpSpecial` | `The button map editor and the controller test open on vanilla's controller page.` | Options screen: help band for the controller setup row | - |
| `UI_ZeD_Options_KeepEditing` | `Keep editing` | Options screen: strip button that stays in Options | 16 |
| `UI_ZeD_Options_KeyDefault` | `Default` | Options screen: strip button that gives the action its default key | 12 |
| `UI_ZeD_Options_MoodlesBottom` | `Above the belt` | (existing) | - |
| `UI_ZeD_Options_MoodlesLeft` | `Left` | (existing) | - |
| `UI_ZeD_Options_MoodlesRight` | `Right` | (existing) | - |
| `UI_ZeD_Options_MootClockFormat` | `The watch shows the day of the month only.` | Options screen (groups): reason for the Clock format setting | - |
| `UI_ZeD_Options_MootClockSize` | `The watch shows the time; the game's clock is put away.` | Options screen (groups): reason for the Clock size setting | - |
| `UI_ZeD_Options_MootContainerSize` | `ZeD's windows have their own container column.` | Options screen (groups): reason for the Inventory container size setting | - |
| `UI_ZeD_Options_MootContextMenuFont` | `ZeD draws every context menu in ZeD's text: use Text size in ZeD setup.` | Options screen (groups): reason for the Context menu font setting | - |
| `UI_ZeD_Options_MootCraftingXP` | `ZeD's Craft tab replaces the game's crafting window.` | Options screen (groups): reason for the Show crafting XP setting | - |
| `UI_ZeD_Options_MootCycleContainer` | `ZeD's container column doesn't cycle containers by key and wheel.` | Options screen (groups): reason for the Cycle container key setting | - |
| `UI_ZeD_Options_MootHelp` | `Does nothing with ZeD active. %1` | Options screen: help band for a setting ZeD makes moot. %1 is the reason (a sentence) | - |
| `UI_ZeD_Options_MootInventoryFont` | `ZeD's lists draw in ZeD's text: use Text size in ZeD setup.` | Options screen (groups): reason under a setting that does nothing with ZeD (the Inventory font setting). 'Text size' and 'ZeD setup' are names shown elsewhere | - |
| `UI_ZeD_Options_MootShoulderButtons` | `LB and RB open ZeD's Character and World windows.` | Options screen (groups): reason for the shoulder button container switch setting | - |
| `UI_ZeD_Options_MootUnder` | `Does nothing with ZeD active` | Options screen: small line under the name of a setting ZeD makes moot | 40 |
| `UI_ZeD_Options_NoKey` | `No key` | Options screen: strip button that leaves the action with no key | 12 |
| `UI_ZeD_Options_NoMatch` | `No option matches` | Options screen: empty list while Find matches nothing | - |
| `UI_ZeD_Options_OnlyDyslexic` | `Replaces ZeD's text fonts` | Options screen (groups): small line under the Dyslexic font setting | 30 |
| `UI_ZeD_Options_OnlyDyslexicHelp` | `Replaces ZeD's text fonts with the game's dyslexic fonts.` | Options screen (groups): help band for the Dyslexic font setting, after the game's own help | - |
| `UI_ZeD_Options_OnlySidebar` | `Multiplayer only` | Options screen (groups): small line under the Sidebar size setting | 30 |
| `UI_ZeD_Options_OnlySidebarHelp` | `ZeD hides these buttons in single player; in multiplayer they stay.` | Options screen (groups): help band for the Sidebar size setting, after the game's own help | - |
| `UI_ZeD_Options_OnlyTooltip` | `Item and ZeD tooltips` | Options screen (groups): small line under the Tooltip font setting | 30 |
| `UI_ZeD_Options_OnlyTooltipHelp` | `It sizes the item tooltip's facts and the text in ZeD's tooltips.` | Options screen (groups): help band for the Tooltip font setting, after the game's own help | - |
| `UI_ZeD_Options_OpenController` | `Open controller setup` | Options screen: button on the controller setup row | - |
| `UI_ZeD_Options_PickController` | `Pick a Test Controller below` | Options screen: value of the deadzone row when no controller is picked | - |
| `UI_ZeD_Options_PressKey` | `Press a key` | Options screen: text of a key binding button while it waits for the key | 14 |
| `UI_ZeD_Options_PromptChange` | `Change` | Controller prompt in the footer of the Options, Sandbox and Character screens: left/right changes the value | 10 |
| `UI_ZeD_Options_PromptPage` | `Page` | Controller prompt for the bumpers, which switch pages | 10 |
| `UI_ZeD_Options_PromptToggle` | `Toggle` | Controller prompt (A button) on a tick box row | 10 |
| `UI_ZeD_Options_SameAsAccent` | `Same as Accent` | (existing) | - |
| `UI_ZeD_Options_ScaleAutoNow` | `Auto (%1 here)` | (existing) | - |
| `UI_ZeD_Options_SecColors` | `Colors` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecEffects` | `Effects` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecHighlights` | `Highlights` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecHud` | `HUD` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecMenus` | `Menus` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecMouse` | `Mouse` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecOnItsOwn` | `On its own` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecReading` | `Reading` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecRendering` | `Rendering` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecScreen` | `Screen` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecStreaming` | `Streaming` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecText` | `Text` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_SecVoice` | `Voice chat` | Options screen (groups): section heading inside a page (shown in caps) | - |
| `UI_ZeD_Options_Set` | `Set` | Options screen: strip button that sets the typed value | 8 |
| `UI_ZeD_Options_TakeIt` | `Take it` | Options screen: strip button that takes the key from the other action | 12 |
| `UI_ZeD_Options_Title` | `Project Zomboid  +  Options` | Options screen: title bar. The + is the ZeD title separator | - |
| `UI_ZeD_Options_Toggles` | `Toggles` | Options screen: section heading over the key binding toggles (shown in caps) | - |
| `UI_ZeD_Options_UnderSafeMode` | `The game's own interface` | (existing) | - |
| `UI_ZeD_Options_WhyFontSize` | `ZeD's windows grow with the game's font size.` | Options screen (groups): help band for the copy of the Font size setting in ZeD setup | - |
| `UI_ZeD_Options_WhyMoodleSize` | `ZeD places the moodles and sizes its moodle row from it.` | Options screen (groups): help band for the copy of the Moodle size setting in ZeD setup | - |
| `UI_ZeD_Options_WhyTooltipFont` | `ZeD's tooltips and the item tooltip's facts are sized by it.` | Options screen (groups): help band for the copy of the Tooltip font setting in ZeD setup | - |
| `UI_ZeD_Options_WhyVideoEffects` | `The New wallpaper plays only with it on.` | Options screen (groups): help band for the copy of the Video effects setting in ZeD setup | - |
| `UI_ZeD_Options_WhyWatch` | `The watch reads it.` | Options screen (groups): help band for the copies of the clock and temperature settings in ZeD setup | - |
| `UI_ZeD_Options_ZedControls` | `Controls` | (existing) | - |
| `UI_ZeD_Options_ZedHud` | `HUD` | (existing) | - |
| `UI_ZeD_Options_ZedLook` | `Look` | (existing) | - |
| `UI_ZeD_Options_ZedTrouble` | `Troubleshooting` | (existing) | - |
| `UI_ZeD_Options_ZedWindows` | `Windows` | (existing) | - |

## Papers

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Papers_Count` | `%1 read of %2 carried` | Character window, Journal tab, Papers sub-tab: line over the list (%1 = pieces read, %2 = pieces carried) | 40 |
| `UI_ZeD_Papers_CountWithPlaces` | `%1 read of %2 carried \| %3 with places` | Character window, Journal tab, Papers sub-tab: line over the list when some read pieces name places (%3 = how many) | 60 |
| `UI_ZeD_Papers_FilterFlyers` | `Flyers` | Character window, Journal tab, Papers sub-tab: filter pill for flyers and brochures | 10 |
| `UI_ZeD_Papers_FilterNews` | `News` | Character window, Journal tab, Papers sub-tab: filter pill for newspapers | 10 |
| `UI_ZeD_Papers_FilterOnMap` | `On map` | Character window, Journal tab, Papers sub-tab: filter pill for read pieces that name places | 10 |
| `UI_ZeD_Papers_Find` | `Find a paper...` | Character window, Journal tab, Papers sub-tab: placeholder in the search box | 30 |
| `UI_ZeD_Papers_HeadStories` | `ON THIS PAGE: %1 STORIES` | Papers quick look: heading over the piece's text when it has several stories (%1 = how many) | 36 |
| `UI_ZeD_Papers_HeadWords` | `THE WORDS` | Papers quick look: heading over the piece's text | 24 |
| `UI_ZeD_Papers_NoneCarried` | `Nothing to read on you` | Character window, Journal tab, Papers sub-tab: empty list, the character carries no paper | 40 |
| `UI_ZeD_Papers_NoneMatch` | `None of these on you` | Character window, Journal tab, Papers sub-tab: empty list, nothing matches the filter or search | 40 |
| `UI_ZeD_Papers_OpenFull` | `Open full` | Papers quick look and Notebooks sub-tab: button that opens the full reader or full page (shown in sentence case) | 16 |
| `UI_ZeD_Papers_PlaceMany` | `%1 places` | Character window, Journal tab, Papers sub-tab: second line of a list row when the piece names several places (%1 = 2 to 5) | 12 |
| `UI_ZeD_Papers_PlaceOne` | `1 place` | Character window, Journal tab, Papers sub-tab: second line of a list row when the piece names one place | 12 |
| `UI_ZeD_Papers_ShowPlaceN` | `Show place %1` | Papers quick look: button for the nth place when a piece names several (%1 = 1 to 5) | 20 |
| `UI_ZeD_Papers_StateRead` | `Read` | Character window, Journal tab, Papers sub-tab: right side of a list row, piece read (next to a green dot) | 14 |
| `UI_ZeD_Papers_StateUnread` | `Not read yet` | Character window, Journal tab, Papers sub-tab: right side of a list row, piece not read (next to a grey dot) | 16 |
| `UI_ZeD_Papers_TooDark` | `Too dark to read` | Papers quick look: dim line under the disabled Read button | 30 |

## PartAbbr

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_PartAbbr_LeftFoot` | `L. FOOT` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftForearm` | `L. FOREARM` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftHand` | `L. HAND` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftShin` | `L. SHIN` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftThigh` | `L. THIGH` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftUpperArm` | `L. UARM` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LowerTorso` | `L. TORSO` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightFoot` | `R. FOOT` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightForearm` | `R. FOREARM` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightHand` | `R. HAND` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightShin` | `R. SHIN` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightThigh` | `R. THIGH` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightUpperArm` | `R. UARM` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_UpperTorso` | `U. TORSO` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |

## Place

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Place_Degrees` | `DEGREES` | 3D placement card: right side of the ROTATION heading (capitals) | 12 |
| `UI_ZeD_Place_Item` | `Item` | 3D placement card: card title when the item has no name | 20 |
| `UI_ZeD_Place_WithinTile` | `WITHIN THE TILE` | 3D placement card: right side of the MOVEMENT heading (capitals) | 18 |

## Power

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Power_CanName` | `%1 (%2 of %3 L)` | Generator card: a petrol can in the add-fuel list; %1 is its name, %2 how much petrol it holds, %3 its capacity | - |
| `UI_ZeD_Power_Connect` | `Connect` | Generator card: verb button (plug the generator into the building) | 14 |
| `UI_ZeD_Power_Days` | `%1 DAYS` | Generator card: run time left under the plate when over 100 hours, e.g. 12 DAYS (capitals) | 12 |
| `UI_ZeD_Power_Disconnect` | `Disconnect` | Generator card: verb button (unplug the generator from the building) | 14 |
| `UI_ZeD_Power_Fix` | `Fix` | Generator card: verb button | 10 |
| `UI_ZeD_Power_Fuel` | `FUEL` | Generator card: label of the fuel reading under the plate (capitals) | 10 |
| `UI_ZeD_Power_FuelOf` | `%1 OF %2 L` | Generator card: fuel in the tank under the plate, e.g. 4.5 OF 10 L (capitals) | 14 |
| `UI_ZeD_Power_Fumes` | `Indoors. Running it here fills the building with toxic fumes. Move it outside first.` | Generator card: warning band (red) while the generator stands inside a building | - |
| `UI_ZeD_Power_Hrs` | `%1 HRS` | Generator card: run time left under the plate as hours and minutes, e.g. 33:20 HRS (capitals) | 12 |
| `UI_ZeD_Power_MayFail` | `%1 \| may fail to start` | Generator card: value of the condition line at 50% or less; %1 is the percentage with its sign, e.g. 40% (the bar is a separator) | - |
| `UI_ZeD_Power_NeedCan` | `Add fuel: needs a can with petrol` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedConnected` | `Turn on: needs it connected` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedDisconnected` | `Take: needs it disconnected` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedElecPlug` | `Connect: needs Electricity 3 or the generator magazine` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedElecPlugFix` | `Connect and fix: need Electricity 3 or the generator magazine` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedElecUnplug` | `Disconnect: needs Electricity 3 or the generator magazine` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedElecUnplugFix` | `Disconnect and fix: need Electricity 3 or the generator magazine` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedFuel` | `Turn on: needs fuel` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_NeedOffConnect` | `Turn it off to add fuel, fix or connect it` | Generator card: the NEEDS line while the generator runs and is not connected | - |
| `UI_ZeD_Power_NeedOffDisconnect` | `Turn it off to add fuel, fix or disconnect it` | Generator card: the NEEDS line while the generator runs and is connected | - |
| `UI_ZeD_Power_NeedScrap` | `Fix: needs Scrap Electronics` | Generator card: the NEEDS line under the verbs | - |
| `UI_ZeD_Power_PillRunning` | `RUNNING` | Generator card: header pill while the generator runs (capitals) | 10 |
| `UI_ZeD_Power_Powering` | `POWERING` | Generator card: section heading over the list of what the generator powers (capitals) | - |
| `UI_ZeD_Power_RunTimeLeft` | `RUN TIME LEFT` | Generator card: label of the run time under the plate (capitals; the half-width column holds about 14 letters) | 14 |

## Print

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Print_Flyer` | `Flyer` | Kind of paper in the reader side column, Papers quick look and Papers list second line (the game has no word for it) | 14 |
| `UI_ZeD_Print_Paper` | `Paper` | Kind of paper when the item is none of newspaper, brochure, flyer, magazine | 14 |

## Prompt

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Prompt_Back` | `Back` | Controller button legend, B prompt | 12 |
| `UI_ZeD_Prompt_Card` | `Card` | Controller button legend at the window foot, A prompt on an inventory row or equipment slot (opens its card) | 12 |
| `UI_ZeD_Prompt_DPadMove` | `D-PAD Move` | Pop-up prompt controller legend, dim note: the D-pad moves between buttons | 18 |
| `UI_ZeD_Prompt_DPadMoveStep` | `D-PAD Move / Step` | Pop-up prompt controller legend for the alarm clock and timer dialogs: the D-pad moves and steps values | 22 |
| `UI_ZeD_Prompt_DPadScroll` | `D-PAD Scroll` | Pop-up prompt controller legend, dim note: the D-pad scrolls long text | 18 |
| `UI_ZeD_Prompt_Edit` | `Edit` | Controller button legend, X prompt on the map canvas | 12 |
| `UI_ZeD_Prompt_Fold` | `Fold` | Controller button legend, A prompt on the map's fold control | 12 |
| `UI_ZeD_Prompt_Hold` | `%1 (hold)` | Controller button legend, hold-A prompt; %1 is the action word (Use) | 18 |
| `UI_ZeD_Prompt_Hour` | `HOUR` | Alarm clock dialog, label of the hour stepper row | 10 |
| `UI_ZeD_Prompt_Keyboard` | `Keyboard` | Pop-up prompt controller legend, A prompt on a text field (opens the on-screen keyboard) | 12 |
| `UI_ZeD_Prompt_Menu` | `Menu` | Controller button legend, X prompt (opens the context menu) | 12 |
| `UI_ZeD_Prompt_Minute` | `MINUTE` | Alarm clock dialog, label of the minute stepper row | 10 |
| `UI_ZeD_Prompt_Pin` | `Pin` | Controller button legend, X prompt on a map grid tool or a skill row | 12 |
| `UI_ZeD_Prompt_Press` | `Press` | Pop-up prompt controller legend, A prompt on a button | 12 |
| `UI_ZeD_Prompt_Recipe` | `Recipe` | Controller button legend, A prompt on a crafting, journal-recipe or build row | 12 |
| `UI_ZeD_Prompt_Reset` | `Reset` | Controller button legend, X prompt on a control that resets | 12 |
| `UI_ZeD_Prompt_Search` | `Search` | Controller button legend, A prompt on the forage stance control | 12 |
| `UI_ZeD_Prompt_Select` | `Select` | Controller button legend, A prompt on a control with no more specific word | 12 |
| `UI_ZeD_Prompt_Sort` | `Sort` | Window footer prompt beside L3: step the sort of the list the controller is on | 10 |
| `UI_ZeD_Prompt_Start` | `Start` | Controller button legend, A prompt on an exercise | 12 |
| `UI_ZeD_Prompt_Switch` | `Switch` | Controller button legend, A prompt on a sub-tab switch | 12 |
| `UI_ZeD_Prompt_Tool` | `Tool` | Controller button legend, A prompt on a map tool | 12 |
| `UI_ZeD_Prompt_Unfold` | `Unfold` | Controller button legend, A prompt on the map's pop-out control | 12 |
| `UI_ZeD_Prompt_Use` | `Use` | Controller button legend, hold-A prompt on an inventory row (used inside 'Use (hold)') | 12 |
| `UI_ZeD_Prompt_Windows` | `Windows` | Controller button legend, Y prompt (swaps between the two windows) | 12 |

## Radio

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Radio_Batt` | `BATT` | Character / World window, Radio tab: silkscreen label on the display, before the battery bar | 5 |
| `UI_ZeD_Radio_CdLoaded` | `DISC LOADED` | Character / World window, Radio tab, CD display: a disc is in but no track is chosen | 16 |
| `UI_ZeD_Radio_CdNone` | `NO DISC` | Character / World window, Radio tab, CD display: no disc | 12 |
| `UI_ZeD_Radio_CdTrack` | `TRK %1   %2` | Character / World window, Radio tab, CD display: track number and state (%1 = two-digit track, %2 = PLAY or STOP below) | 20 |
| `UI_ZeD_Radio_ChCleared` | `CH %1 CLEARED` | Two-way radio display flash after a channel is forgotten; %1 = the channel number, two digits | 16 |
| `UI_ZeD_Radio_ChStored` | `CH %1 STORED` | Two-way radio display flash after MEM; %1 = the channel number, two digits | 16 |
| `UI_ZeD_Radio_CompactDisc` | `COMPACT DISC` | CD receiver display line when a disc has no title | 16 |
| `UI_ZeD_Radio_Empty` | `EMPTY` | Radio display flash when a preset button has no station | 8 |
| `UI_ZeD_Radio_LocBack` | `Back` | Character / World window, Radio tab: header pill, radio carried on the back | 12 |
| `UI_ZeD_Radio_LocPrimary` | `Primary` | Character / World window, Radio tab: header pill, radio held in the primary hand | 12 |
| `UI_ZeD_Radio_LocSecondary` | `Secondary` | Character / World window, Radio tab: header pill, radio held in the secondary hand | 12 |
| `UI_ZeD_Radio_MemFull` | `MEMORY FULL` | Two-way radio display flash when MEM has no room left | 16 |
| `UI_ZeD_Radio_Mic` | `MIC` | Dash head unit (two-way set) small display: microphone muted | 4 |
| `UI_ZeD_Radio_MicOff` | `MIC OFF` | Two-way radio display: microphone muted | 8 |
| `UI_ZeD_Radio_Mute` | `MUTE` | Car radio and dash head unit display: sound muted | 6 |
| `UI_ZeD_Radio_NameChannel` | `Name channel %1 (empty forgets it)` | Car radio: title of the text box asking for a channel's name; %1 = the channel number, two digits | 50 |
| `UI_ZeD_Radio_NoCds` | `No CDs on you` | Car radio: the disc list when the character carries no CD | 30 |
| `UI_ZeD_Radio_None` | `No radio in range` | Character / World window, Radio tab: empty state, centered | 40 |
| `UI_ZeD_Radio_Range` | `RANGE %1 KM` | Two-way radio, line printed on the face; %1 = the range in kilometres (may have a decimal) | 16 |
| `UI_ZeD_Radio_Scan` | `SCAN` | Car radio and dash head unit display: station scan running | 6 |
| `UI_ZeD_Radio_Seek` | `SEEK` | Character / World window, Radio tab: control strip silkscreen label before the seek buttons | 6 |
| `UI_ZeD_Radio_Sig` | `SIG` | Character / World window, Radio tab: display readout label for signal, and the corner label of the signal wave | 5 |
| `UI_ZeD_Radio_SigGood` | `GOOD` | Character / World window, Radio tab: display readout value, signal received | 6 |
| `UI_ZeD_Radio_SigWeak` | `WEAK` | Character / World window, Radio tab: display readout value, no signal | 6 |
| `UI_ZeD_Radio_Stereo` | `STEREO` | Character / World window, Radio tab: chassis display chip (decorative, always off) | 8 |
| `UI_ZeD_Radio_Store` | `STORE %1` | Radio display flash after holding a preset button; %1 = the preset number (1 to 6). Small faces show P%1 instead | 16 |
| `UI_ZeD_Radio_TagPremium` | `* AM/FM TUNER + CD` | Character / World window, Radio tab: right end of the Premium Technologies brand bar (the brand name and model number stay English) | 24 |
| `UI_ZeD_Radio_TagValu` | `* AM/FM PORTABLE` | Character / World window, Radio tab: right end of the ValuTech brand bar (the brand name stays English) | 24 |
| `UI_ZeD_Radio_TxOk` | `TX OK` | Two-way radio display: transmitting is possible | 6 |
| `UI_ZeD_Radio_UnknownFreq` | `Unknown frequency` | Character / World window, Radio tab: display line when the game has no name for the tuned channel (after a '> ' arrow) | 28 |
| `UI_ZeD_Radio_Vol` | `VOL` | Character / World window, Radio tab: silkscreen label before the volume bar and on the control strip | 5 |

## RadioPrompt

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_RadioPrompt_ChannelDown` | `Channel down` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_ChannelUp` | `Channel up` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Dpad` | `D-PAD Move / Turn` | Car radio up close, controller prompt strip: the D-pad's job | 30 |
| `UI_ZeD_RadioPrompt_Eject` | `Eject` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_InsertCd` | `Insert a CD` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Listen` | `Listen` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Mute` | `Mute` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_NameChannel` | `Name channel` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_PlayStop` | `Play / stop` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Press` | `Press` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Scan` | `Scan` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Seek` | `Seek` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_SeekBack` | `Seek back` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Store` | `Store` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_StoreChannel` | `Store channel` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Tune` | `Tune` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |

## Reader

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Reader_Blank` | `Blank` | Notebook page window, left rail: row text for a page with nothing written | 14 |
| `UI_ZeD_Reader_Counts` | `%1 of %2 lines \| %3 of %4 letters` | Notebook page window: how much of the page is used (%1 lines used, %2 lines allowed, %3 letters used, %4 letters allowed; thousands have a comma) | 50 |
| `UI_ZeD_Reader_Erase` | `Erase` | Notebook page window, bottom strip: the confirm button of the erase question (shown in sentence case) | 12 |
| `UI_ZeD_Reader_EraseAsk` | `Erase page %1? Its words cannot be brought back.` | Notebook page window, bottom strip: question when Erase page is pressed (%1 = page) | 70 |
| `UI_ZeD_Reader_ErasePage` | `Erase page` | Notebook page window, bottom strip: button that clears the page (shown in sentence case) | 16 |
| `UI_ZeD_Reader_HeadPiece` | `THIS PIECE` | Reader side column and Papers quick look: section heading over kind, date, read | 20 |
| `UI_ZeD_Reader_HeadPlaces` | `PLACES` | Reader side column and Papers quick look: heading over the places the piece names (Show on map) | 20 |
| `UI_ZeD_Reader_HeadStories` | `ON THIS PAGE` | Reader side column: heading over the list of stories (headlines) on the page | 22 |
| `UI_ZeD_Reader_KeepIt` | `Keep it` | Notebook page window, bottom strip: the cancel button of the erase question (shown in sentence case) | 12 |
| `UI_ZeD_Reader_LabelDate` | `DATE` | Reader side column and Papers quick look: label for the date of the paper; narrow label column | 8 |
| `UI_ZeD_Reader_LabelKind` | `KIND` | Reader side column and Papers quick look: label for the kind of paper (Newspaper, Flyer...); narrow label column | 8 |
| `UI_ZeD_Reader_LabelRead` | `READ` | Reader side column and Papers quick look: label for whether the character has read it; narrow label column | 8 |
| `UI_ZeD_Reader_Lock` | `Lock` | Notebook page window, bottom strip: button that locks the book to its writer (shown in sentence case) | 12 |
| `UI_ZeD_Reader_NotYet` | `Not yet` | Reader side column and Papers quick look: value of the READ line when unread | 14 |
| `UI_ZeD_Reader_PageOf` | `Page %1 of %2` | Notebook page window (page corner and bottom strip) and Notebooks sub-tab page bar (%1 = page, %2 = pages in the book) | 20 |
| `UI_ZeD_Reader_Picture` | `Picture: %1` | Reader Words view and Papers quick look: caption box for a picture on the page (%1 = the caption text) | - |
| `UI_ZeD_Reader_PlaceN` | `Place %1` | Reader side column: name of the nth place when a piece has several (%1 = 1 to 5) | 20 |
| `UI_ZeD_Reader_ReadOnlyLocked` | `Locked by its writer. You can read it; you cannot write in it.` | Notebook page window: band above the page when someone else locked the book | 80 |
| `UI_ZeD_Reader_ReadOnlyNoTool` | `No pencil or pen: you can read it, not write in it.` | Notebook page window: band above the page when the character has nothing to write with | 80 |
| `UI_ZeD_Reader_ShowOnMap` | `Show on map` | Reader side column and Papers quick look: button that marks the piece's place on the map | 24 |
| `UI_ZeD_Reader_StatRead` | `Read` | Full reader window (newspaper, flyer, brochure), title bar chip: shown when the piece has been read | 10 |
| `UI_ZeD_Reader_StatReading` | `Reading` | Notebook page window, title bar chip when the book is read-only | 10 |
| `UI_ZeD_Reader_StatWriting` | `Writing` | Notebook page window, title bar chip when the book can be written in | 10 |
| `UI_ZeD_Reader_Unlock` | `Unlock` | Notebook page window, bottom strip: button that unlocks the book (shown in sentence case) | 12 |
| `UI_ZeD_Reader_ViewPaper` | `Paper` | Reader bottom strip: button for the view of the paper as printed (shown in sentence case) | 14 |
| `UI_ZeD_Reader_ViewWords` | `Words` | Reader bottom strip: button for the clean text view (shown in sentence case) | 14 |

## Recipe

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Recipe_Fuel` | `FUEL` | Crafting list, small tag on an ingredient that can be burnt as fuel | 8 |

## Safe

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Safe_LastTime` | `ZeD-GUI stepped aside last time (%1). It is on again now. If it happens again, turn on Safe mode under Options > Mods > ZeD-GUI.` | Safe mode note (game dialog) shown once on the next launch after a trip; %1 names the place that failed | - |
| `UI_ZeD_Safe_SteppedAside` | `ZeD-GUI stepped aside.` | Safe mode note (game dialog), first paragraph, shown when ZeD hit a repeating error | - |
| `UI_ZeD_Safe_TrippedBody` | `It hit an error that kept repeating (%1), so the game's own interface is back for this session. To keep it that way, turn on Safe mode under Options > Mods > ZeD-GUI. The error is in console.txt.` | Safe mode note (game dialog), second paragraph; %1 names the place that failed (not translated) | - |

## Sandbox

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Sandbox_AskDelete` | `Delete the preset %1?` | Sandbox options screen (new game): question in the action strip. %1 is the preset's name | - |
| `UI_ZeD_Sandbox_AskLoad` | `Load %1? Your changes will be lost.` | Sandbox options screen (new game): question in the action strip. %1 is the preset's name | - |
| `UI_ZeD_Sandbox_AskName` | `Preset name:` | Sandbox options screen (new game): label before the name field in the action strip | - |
| `UI_ZeD_Sandbox_ChangedNote` | `Differs from the preset.` | Sandbox options screen (new game): help band for an option that differs from the chosen preset and has no help of its own | - |
| `UI_ZeD_Sandbox_CustomNumber` | `Custom number...` | Sandbox options screen (new game): last row of an option's list of named steps: type any number | - |
| `UI_ZeD_Sandbox_DeletePreset` | `Delete %1...` | Sandbox options screen (new game): row of the Presets pop-up. %1 is the saved preset's name | - |
| `UI_ZeD_Sandbox_NewPresetName` | `New` | Sandbox options screen (new game): the name suggested for a new preset | - |
| `UI_ZeD_Sandbox_Presets` | `Presets...` | Sandbox options screen (new game): strip button that opens the presets pop-up | 14 |
| `UI_ZeD_Sandbox_PromptEdit` | `Edit` | Sandbox options screen (new game): controller prompt (A button) on a number row | 10 |
| `UI_ZeD_Sandbox_PromptPresets` | `Presets` | Sandbox options screen (new game): controller prompt (Y button) that opens the presets pop-up | 10 |
| `UI_ZeD_Sandbox_SavePreset` | `Save as preset...` | Sandbox options screen (new game): row of the Presets pop-up | - |
| `UI_ZeD_Sandbox_StatChanged` | `%1, %2 changed` | Sandbox options screen (new game): status in the title bar. %1 is the preset's name, %2 how many options differ from it | - |
| `UI_ZeD_Sandbox_Title` | `Project Zomboid  +  Sandbox options` | Sandbox options screen (new game): title bar. The + is the ZeD title separator | - |

## Saves

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Saves_AskDelete` | `Delete %1? It cannot be undone.` | Load game screen: question in the action strip. %1 is the save's name | - |
| `UI_ZeD_Saves_AskRename` | `Rename to:` | Load game screen: label before the name field in the action strip | - |
| `UI_ZeD_Saves_CountMany` | `%1 saves` | Load game screen: count in the title bar, none or several saves | - |
| `UI_ZeD_Saves_CountOne` | `%1 save` | Load game screen: count in the title bar, one save | - |
| `UI_ZeD_Saves_Find` | `Find:` | Load game screen: label of the search box over the list of saves | 10 |
| `UI_ZeD_Saves_KvMode` | `MODE` | Load game screen: caps label in the save's facts (about 12 letters of room) | 12 |
| `UI_ZeD_Saves_KvPlayed` | `PLAYED` | Load game screen: caps label in the save's facts (when it was last played) | 12 |
| `UI_ZeD_Saves_KvPlayingAs` | `PLAYING AS` | Load game screen: caps label before the list of characters to play | 12 |
| `UI_ZeD_Saves_ModsMissing` | `%1 not found` | Load game screen: value of the Mods fact when every mod is missing. %1 is how many | - |
| `UI_ZeD_Saves_More` | `More` | Load game screen: strip button that opens the More pop-up; also a controller prompt (Y) | 10 |
| `UI_ZeD_Saves_NameDead` | `%1, dead` | Load game screen: a dead character's name in the list and the heading. %1 is the name | - |
| `UI_ZeD_Saves_NoteModsMissing` | `Mods not found: %1` | Load game screen: red note under the facts. %1 is a comma separated list of mods | - |
| `UI_ZeD_Saves_RenameFile` | `Rename file...` | Load game screen: row of the More pop-up | - |
| `UI_ZeD_Saves_Title` | `Project Zomboid  +  Load game` | Load game screen: title bar. The + is the ZeD title separator | - |

## Seat

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Seat_ByDoor` | `By the %1 door.` | Seat chooser, line under the seat name when a door is pointed; %1 = the seat's name | 40 |
| `UI_ZeD_Seat_DpadMove` | `D-PAD Move` | Seat chooser, controller prompt strip: the D-pad's job | 20 |
| `UI_ZeD_Seat_GetOutHere` | `Get out here` | Seat chooser, controller prompt strip: X leaves by the pointed seat's door | 20 |
| `UI_ZeD_Seat_NumberGetOut` | `+ number: Get out` | Seat chooser, keyboard prompt strip: holding Shift and pressing a seat number leaves by that door | 24 |
| `UI_ZeD_Seat_Sit` | `Sit` | Seat chooser, prompt strip: take the pointed seat (A button or number key) | 14 |

## Server

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Server_AddInstalled` | `Add installed...` | Server settings screen (Host a game, Manage settings): button that adds an installed map or Workshop item | 20 |
| `UI_ZeD_Server_AddOccupation` | `Add occupation...` | Server settings screen (Host a game, Manage settings): button that adds an occupation from the game's list | 24 |
| `UI_ZeD_Server_AskDelete` | `Delete these settings? It cannot be undone.` | Server settings screen (Host a game, Manage settings): question in the action strip | - |
| `UI_ZeD_Server_AskLeave` | `Leave without saving the changes?` | Server settings screen (Host a game, Manage settings): question in the action strip | - |
| `UI_ZeD_Server_BadWorkshopId` | `Not a Workshop ID (only its digits).` | Server settings screen (Host a game, Manage settings): red note under that field | - |
| `UI_ZeD_Server_BtnDelete` | `Delete...` | Server settings screen (Host a game, Manage settings): strip button | 14 |
| `UI_ZeD_Server_BtnDuplicate` | `Duplicate...` | Server settings screen (Host a game, Manage settings): strip button | 14 |
| `UI_ZeD_Server_BtnRename` | `Rename...` | Server settings screen (Host a game, Manage settings): strip button | 14 |
| `UI_ZeD_Server_ChangedNote` | `Changed since this page opened.` | Server settings screen (Host a game, Manage settings): help band for a changed setting that has no help of its own | - |
| `UI_ZeD_Server_ChooseOccupation` | `Choose an occupation` | Server settings screen (Host a game, Manage settings): the points list while no occupation is picked | - |
| `UI_ZeD_Server_Duplicate` | `Duplicate` | Server settings screen (Host a game, Manage settings): strip button that makes the copy | 14 |
| `UI_ZeD_Server_EditPoints` | `Edit spawn points...` | Server settings screen (Host a game, Manage settings): button that edits a region's spawn points file | 24 |
| `UI_ZeD_Server_ErrCharacters` | `A name cannot use \ / : * ? " < > \|` | Server settings screen (Host a game, Manage settings): red note under the name field (keep the signs as they are) | - |
| `UI_ZeD_Server_ErrNoName` | `Give the settings a name.` | Server settings screen (Host a game, Manage settings): red note under the name field | - |
| `UI_ZeD_Server_ErrSameName` | `Choose a different name.` | Server settings screen (Host a game, Manage settings): red note under the name field | - |
| `UI_ZeD_Server_ErrTaken` | `That name is taken, or has characters a file name cannot use.` | Server settings screen (Host a game, Manage settings): red note under the name field | - |
| `UI_ZeD_Server_ErrTooLong` | `That name is too long for the settings folder.` | Server settings screen (Host a game, Manage settings): red note under the name field | - |
| `UI_ZeD_Server_HeadServer` | `SERVER` | Server settings screen (Host a game, Manage settings): caps heading in the page list over the server's own setting pages | - |
| `UI_ZeD_Server_LabelAddMap` | `ADD A MAP FOLDER` | Server settings screen (Host a game, Manage settings): caps label over the field that adds a map by folder name | - |
| `UI_ZeD_Server_LabelAddPoint` | `ADD A POINT` | Server settings screen (Host a game, Manage settings): caps label over the field that adds a spawn point | - |
| `UI_ZeD_Server_LabelAddWorkshop` | `ADD BY WORKSHOP ID` | Server settings screen (Host a game, Manage settings): caps label over the field that adds a Workshop item by its number | - |
| `UI_ZeD_Server_LabelAnotherOccupation` | `ANOTHER OCCUPATION (ITS ID)` | Server settings screen (Host a game, Manage settings): caps label over the field that adds an occupation by id | - |
| `UI_ZeD_Server_LabelBecome` | `THE FILES BECOME` | Server settings screen (Host a game, Manage settings): caps heading over the renamed files | - |
| `UI_ZeD_Server_LabelCopies` | `THE COPIES` | Server settings screen (Host a game, Manage settings): caps heading over the copied files | - |
| `UI_ZeD_Server_LabelFiles` | `ITS FILES` | Server settings screen (Host a game, Manage settings): caps heading over the files of the picked settings | - |
| `UI_ZeD_Server_LabelFixedPoint` | `FIXED SPAWN POINT (X,Y,Z)` | Server settings screen (Host a game, Manage settings): caps label over the fixed spawn point field | - |
| `UI_ZeD_Server_LabelGo` | `THESE FILES GO` | Server settings screen (Host a game, Manage settings): caps heading over the files that will be deleted | - |
| `UI_ZeD_Server_LabelMakes` | `IT MAKES THESE FILES` | Server settings screen (Host a game, Manage settings): caps heading over the files that a new settings name would make | - |
| `UI_ZeD_Server_LabelMaps` | `MAPS (WHERE THEY OVERLAP, THE ONE HIGHER UP WINS)` | Server settings screen (Host a game, Manage settings): caps heading over the server's list of maps | - |
| `UI_ZeD_Server_LabelMods` | `THE SERVER'S MODS` | Server settings screen (Host a game, Manage settings): caps heading over the server's list of mods | - |
| `UI_ZeD_Server_LabelOccupations` | `OCCUPATIONS` | Server settings screen (Host a game, Manage settings): caps heading over the list of occupations on the spawn points page | - |
| `UI_ZeD_Server_LabelPoints` | `ITS SPAWN POINTS (X,Y,Z)` | Server settings screen (Host a game, Manage settings): caps heading over the picked occupation's points | - |
| `UI_ZeD_Server_LabelPreset` | `START FROM A PRESET` | Server settings screen (Host a game, Manage settings): caps heading over the list of sandbox presets | - |
| `UI_ZeD_Server_LabelRegFile` | `FILE` | Server settings screen (Host a game, Manage settings): caps label at the left of the spawn region's file field | 8 |
| `UI_ZeD_Server_LabelWorkshop` | `STEAM WORKSHOP ITEMS` | Server settings screen (Host a game, Manage settings): caps heading over the server's Workshop items | - |
| `UI_ZeD_Server_ModsNote` | `Mods are chosen on the way in: "Cancel", "Edit", then "Choose mods..."` | Server settings screen (Host a game, Manage settings): note under the mods list (the quoted words are button names) | - |
| `UI_ZeD_Server_NoMaps` | `No maps` | Server settings screen (Host a game, Manage settings): empty list of maps | - |
| `UI_ZeD_Server_NoMods` | `No mods: the server runs the game as it is.` | Server settings screen (Host a game, Manage settings): empty list of mods | - |
| `UI_ZeD_Server_NoName` | `(no name)` | Server settings screen (Host a game, Manage settings): a spawn region that has no name | - |
| `UI_ZeD_Server_NoOccupations` | `No occupations` | Server settings screen (Host a game, Manage settings): empty list | - |
| `UI_ZeD_Server_NoPoints` | `No points` | Server settings screen (Host a game, Manage settings): empty list of an occupation's points | - |
| `UI_ZeD_Server_NoRegions` | `No spawn regions` | Server settings screen (Host a game, Manage settings): empty list of spawn regions | - |
| `UI_ZeD_Server_NoSettings` | `No server settings yet: "New..." makes one.` | Server settings screen (Host a game, Manage settings): empty list of server settings (New... is the name of the New button) | - |
| `UI_ZeD_Server_NoWorkshop` | `No Workshop items` | Server settings screen (Host a game, Manage settings): empty list of Workshop items | - |
| `UI_ZeD_Server_PointCountMany` | `%1 points` | Server settings screen (Host a game, Manage settings): count beside an occupation. %1 is the number | - |
| `UI_ZeD_Server_PointCountOne` | `%1 point` | Server settings screen (Host a game, Manage settings): count beside an occupation. %1 is 1 | - |
| `UI_ZeD_Server_PointsEmpty` | `%1 has no points yet: add one, or remove it.` | Server settings screen (Host a game, Manage settings): red note on the spawn points page. %1 is the occupation's name | - |
| `UI_ZeD_Server_PointsNeedsOne` | `%1 needs a point: anyone whose occupation is not listed spawns there.` | Server settings screen (Host a game, Manage settings): red note on the spawn points page. %1 is the occupation's name | - |
| `UI_ZeD_Server_PresetNote` | `"Apply" sets every sandbox option of this server to the preset's.` | Server settings screen (Host a game, Manage settings): note under the presets list (Apply is the name of the Apply button) | - |
| `UI_ZeD_Server_PresetYours` | `yours` | Server settings screen (Host a game, Manage settings): small tag on a preset you saved yourself | 10 |
| `UI_ZeD_Server_Title` | `Project Zomboid  +  Server settings` | Server settings screen (Host a game, Manage settings): title bar. The + is the ZeD title separator | - |
| `UI_ZeD_Server_TitleCopy` | `Copy %1` | Server settings screen (Host a game, Manage settings): heading of the Duplicate page. %1 is the settings' name | - |
| `UI_ZeD_Server_TitleDelete` | `Delete %1` | Server settings screen (Host a game, Manage settings): heading of the Delete page. %1 is the settings' name | - |
| `UI_ZeD_Server_TitleNew` | `New server settings` | Server settings screen (Host a game, Manage settings): heading of the New page | - |
| `UI_ZeD_Server_TitleRename` | `Rename %1` | Server settings screen (Host a game, Manage settings): heading of the Rename page. %1 is the settings' name | - |

## Settings

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Settings_AccentColor` | `Accent color` | Options > Mods > ZeD-GUI: name of the accent color setting | - |
| `UI_ZeD_Settings_AccentColorTip` | `Controls selection, hover, and active element colors.` | Options > Mods > ZeD-GUI: hover help of the accent color setting | - |
| `UI_ZeD_Settings_ActionBar` | `Action bar` | Options > Mods > ZeD-GUI: name of the action bar setting | - |
| `UI_ZeD_Settings_ActionBarSimple` | `Simple` | Options > Mods > ZeD-GUI: choice of the Action bar setting | - |
| `UI_ZeD_Settings_ActionBarTip` | `The bar over your character's head while it works. Verbose: what it is doing, with what, how far, and what comes next. Simple: ten segments, no words.` | Options > Mods > ZeD-GUI: hover help (Verbose and Simple are the names of the two choices) | - |
| `UI_ZeD_Settings_ActionBarVerbose` | `Verbose` | Options > Mods > ZeD-GUI: choice of the Action bar setting | - |
| `UI_ZeD_Settings_Auto` | `Auto` | Options > Mods > ZeD-GUI: choice of the Gamepad glyph display and Input mode lock settings | - |
| `UI_ZeD_Settings_BaseTheme` | `Base theme` | Options > Mods > ZeD-GUI: name of the base theme setting | - |
| `UI_ZeD_Settings_BaseThemeTip` | `Controls surface colors, text contrast, and border weight.` | Options > Mods > ZeD-GUI: hover help of the base theme setting | - |
| `UI_ZeD_Settings_CharAccent` | `Character window accent` | Options > Mods > ZeD-GUI: name of the Character window accent setting | - |
| `UI_ZeD_Settings_CharAccentTip` | `An accent of its own for the Character window, or the same as Accent color. Cycled via footer button.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_ContextMenu` | `Context menu` | Options > Mods > ZeD-GUI: name of the right-click menu style setting | - |
| `UI_ZeD_Settings_ContextMenuTip` | `The right-click menu: a strip of icons with the target and what the action needs, or a list, one action to a row, as the game's own.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_ContextStrip` | `Icon strip` | Options > Mods > ZeD-GUI: choice of the Context menu setting | - |
| `UI_ZeD_Settings_Dark` | `Dark` | Options > Mods > ZeD-GUI: base theme choice | - |
| `UI_ZeD_Settings_EquipView` | `Equipped items` | Options > Mods > ZeD-GUI: name of the Equip tab view setting | - |
| `UI_ZeD_Settings_EquipViewTip` | `How the Equip tab shows what you wear: a list, or your character with each slot beside the place it is worn.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_Gamepad` | `Gamepad` | Options > Mods > ZeD-GUI: choice of the Input mode lock setting | - |
| `UI_ZeD_Settings_Glyphs` | `Gamepad glyph display` | Options > Mods > ZeD-GUI: name of the gamepad glyph setting | - |
| `UI_ZeD_Settings_GlyphsTip` | `Which button icons to show in gamepad prompts. Auto follows the connected controller.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_HighContrast` | `High contrast` | Options > Mods > ZeD-GUI: base theme choice | - |
| `UI_ZeD_Settings_InputLock` | `Input mode lock` | Options > Mods > ZeD-GUI: name of the input mode setting | - |
| `UI_ZeD_Settings_InputLockTip` | `Force a specific input mode. Auto lets the mod detect your active device.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_Inventory` | `Inventory` | Options > Mods > ZeD-GUI: name of the inventory view setting | - |
| `UI_ZeD_Settings_InventoryTip` | `How containers show their items unless you set one with its List \| Grid toggle: a list with columns, or a grid of icons.` | Options > Mods > ZeD-GUI: hover help (List \| Grid is the name of a toggle in the inventory) | - |
| `UI_ZeD_Settings_KeyboardMouse` | `Keyboard/mouse` | Options > Mods > ZeD-GUI: choice of the Gamepad glyph display and Input mode lock settings | - |
| `UI_ZeD_Settings_Light` | `Light` | Options > Mods > ZeD-GUI: base theme choice | - |
| `UI_ZeD_Settings_Moodles` | `Moodles` | Options > Mods > ZeD-GUI: name of the moodle placement setting (use the game's own word for moodles) | - |
| `UI_ZeD_Settings_MoodlesBottom` | `Bottom, above the belt` | Options > Mods > ZeD-GUI: choice of the moodle placement setting | - |
| `UI_ZeD_Settings_MoodlesLeft` | `Left edge` | Options > Mods > ZeD-GUI: choice of the moodle placement setting | - |
| `UI_ZeD_Settings_MoodlesRight` | `Right edge` | Options > Mods > ZeD-GUI: choice of the moodle placement setting | - |
| `UI_ZeD_Settings_MoodlesTip` | `Where the moodles sit. Right edge or Left edge: a column centered on the middle of the screen. Bottom: a row above the belt (above the dashboard in a car).` | Options > Mods > ZeD-GUI: hover help of the moodle placement setting | - |
| `UI_ZeD_Settings_SafeMode` | `Safe mode` | Options > Mods > ZeD-GUI: name of the safe mode setting | - |
| `UI_ZeD_Settings_SafeModeOn` | `On: the game's own interface` | Options > Mods > ZeD-GUI: second choice of the Safe mode setting | - |
| `UI_ZeD_Settings_SafeModeTip` | `On: ZeD UI steps aside and the game's own interface is used (its inventory, hotbar, clock, moodles and dashboard) until you turn it Off. Use it if ZeD UI ever fails to open. ZeD UI also steps aside by itself, for the rest of a session, if it hits an error that keeps repeating.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_SameAsAccent` | `Same as Accent color` | Options > Mods > ZeD-GUI: last choice of the two window accent settings | - |
| `UI_ZeD_Settings_ScaleAuto` | `Auto (fits the screen)` | Options > Mods > ZeD-GUI: first choice of the UI scale setting (the other choices are numbers like 1.5x). Do not use a % sign | - |
| `UI_ZeD_Settings_TestLanguage` | `Test language (stretched text)` | Options > Mods > ZeD-GUI: name of the test language setting | - |
| `UI_ZeD_Settings_TestLanguageTip` | `For checking layouts: every ZeD phrase shows about 40%% longer, accented and in brackets. Leave it Off to play normally.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_TextSize` | `Text size` | Options > Mods > ZeD-GUI: name of the text size setting | - |
| `UI_ZeD_Settings_TextSizeTip` | `Controls font sizes and component dimensions.` | Options > Mods > ZeD-GUI: hover help of the text size setting | - |
| `UI_ZeD_Settings_UiScale` | `UI scale` | Options > Mods > ZeD-GUI: name of the UI scale setting | - |
| `UI_ZeD_Settings_UiScaleTip` | `Auto sizes the whole ZeD UI to your screen: 1x at 1080p, 2x at 4K. Pick a fixed size to override it (1x is the 1080p size).` | Options > Mods > ZeD-GUI: hover help of the UI scale setting | - |
| `UI_ZeD_Settings_ViewDoll` | `Doll` | Options > Mods > ZeD-GUI: choice of the Equipped items setting: the character figure | - |
| `UI_ZeD_Settings_ViewGrid` | `Grid` | Options > Mods > ZeD-GUI: choice of the Inventory setting: a grid of icons | - |
| `UI_ZeD_Settings_ViewList` | `List` | Options > Mods > ZeD-GUI: choice of the Equipped items, Inventory and Context menu settings | - |
| `UI_ZeD_Settings_Watch` | `Watch` | Options > Mods > ZeD-GUI: name of the watch placement setting | - |
| `UI_ZeD_Settings_WatchBelt` | `On the belt` | Options > Mods > ZeD-GUI: choice of the Watch setting | - |
| `UI_ZeD_Settings_WatchCorner` | `Corner` | Options > Mods > ZeD-GUI: choice of the Watch setting | - |
| `UI_ZeD_Settings_WatchTip` | `Where the watch you wear shows: small on the belt beside the hand of its wrist (press its face for the full watch, which you can drag anywhere), or the full watch in the top right corner.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_WorldAccent` | `World window accent` | Options > Mods > ZeD-GUI: name of the World window accent setting | - |
| `UI_ZeD_Settings_WorldAccentTip` | `An accent of its own for the World window, or the same as Accent color. Cycled via footer button.` | Options > Mods > ZeD-GUI: hover help | - |

## Siren

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Siren_Dpad` | `D-PAD Left / Right: switch   Up / Down: turn` | Siren controller, controller prompt strip: the D-pad's job | 50 |
| `UI_ZeD_Siren_Step` | `Step` | Siren controller, controller prompt strip: A steps the focused switch to its next position | 14 |

## Skills

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Skills_Boost` | `+%1 XP` | Skills tab (Character window): small green pill at the right end of a skill row; %1 is 75%, 100% or 125% (the XP boost from a trait or job) | 12 |
| `UI_ZeD_Skills_StatusCollected` | `COLLECTED` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book in the inventory, not yet read (capitals) | 12 |
| `UI_ZeD_Skills_StatusMissing` | `NOT FOUND` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book not found yet (capitals) | 12 |
| `UI_ZeD_Skills_StatusRead` | `READ` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book fully read (capitals) | 12 |
| `UI_ZeD_Skills_StatusReading` | `READING` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book partly read (capitals) | 12 |
| `UI_ZeD_Skills_TrainingMaterials` | `Training Materials` | Skills tab (Character window): heading of the skill-book section under the skill grid | 24 |
| `UI_ZeD_Skills_Volume` | `%1 Vol. %2` | Skills tab (Character window), Training Materials: a book row when a skill group is open; %1 is the book's title, %2 its volume number as a roman numeral (I, II, III...) | - |

## Spawn

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Spawn_ErrCharacters` | `Those characters can't be used.` | Spawn location screen (new game): red note under the save name field | - |
| `UI_ZeD_Spawn_ErrDot` | `Can't start or end with a dot.` | Spawn location screen (new game): red note under the save name field | - |
| `UI_ZeD_Spawn_ErrExists` | `A save with this name exists.` | Spawn location screen (new game): red note under the save name field | - |
| `UI_ZeD_Spawn_ErrNoName` | `Give the save a name.` | Spawn location screen (new game): red note under the save name field | - |
| `UI_ZeD_Spawn_ErrSpaces` | `Use _ instead of spaces.` | Spawn location screen (new game): red note under the save name field (keep the _ sign) | - |
| `UI_ZeD_Spawn_NewSeed` | `New seed` | Spawn location screen (new game): button beside the seed field that makes a fresh seed | 14 |
| `UI_ZeD_Spawn_PromptNewSeed` | `New seed` | Spawn location screen (new game): controller prompt (Y button) | 12 |
| `UI_ZeD_Spawn_RandomDesc` | `A town picked at random when you press "Next".` | Spawn location screen (new game): description of the Random entry (Next is the name of the Next button) | - |
| `UI_ZeD_Spawn_Title` | `Project Zomboid  +  Spawn location` | Spawn location screen (new game): title bar. The + is the ZeD title separator | - |

## Station

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Station_AnySurface` | `ANY SURFACE` | Craft tab, station dropdown: small note on the Hand row | 14 |
| `UI_ZeD_Station_Fallback` | `Station` | Craft tab, station select and band: name when the station has none | - |
| `UI_ZeD_Station_Hand` | `Hand` | Craft tab, station dropdown and select: crafting with no station, by hand | 18 |
| `UI_ZeD_Station_InReach` | `WITHIN REACH` | Craft tab, station dropdown: heading above the stations you can use | 24 |
| `UI_ZeD_Station_InUse` | `IN USE` | Craft tab, station dropdown: small note on a station someone else is using | 14 |
| `UI_ZeD_Station_KindAppliance` | `APPLIANCE` | Craft tab, station band: kind word after the distance | 12 |
| `UI_ZeD_Station_KindBench` | `BENCH` | Craft tab, station band: kind word after the distance | 12 |
| `UI_ZeD_Station_KindMachine` | `MACHINE` | Craft tab, station band: kind word after the distance | 12 |
| `UI_ZeD_Station_Leave` | `Leave station` | Controller prompt for B in the Craft tab while a station is chosen | 16 |
| `UI_ZeD_Station_ListComma` | `%1, %2` | Craft tab, recipe card: joins stations in a list of three or more | - |
| `UI_ZeD_Station_ListOr` | `%1 or %2` | Craft tab, recipe card: joins the last two stations a recipe accepts (Simple Forge or Advanced Forge) | - |
| `UI_ZeD_Station_NearestMany` | `The nearest is %1 tiles away.` | Craft tab, recipe card: second line when the needed station is several tiles away | - |
| `UI_ZeD_Station_NearestOne` | `The nearest is 1 tile away.` | Craft tab, recipe card: second line when the needed station is 1 tile away | - |
| `UI_ZeD_Station_NeedsA` | `Needs a %1.` | Craft tab, recipe card: the station a recipe needs (name starts with a consonant) | - |
| `UI_ZeD_Station_NeedsAn` | `Needs an %1.` | Craft tab, recipe card: the station a recipe needs (name starts with a vowel) | - |
| `UI_ZeD_Station_NoneInReach` | `NOTHING WITHIN REACH` | Craft tab, station dropdown: heading when no station is near | 24 |
| `UI_ZeD_Station_SelectLabel` | `STATION` | Craft tab: small label inside the station select box | 10 |
| `UI_ZeD_Station_ShortBarrel` | `BARREL` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortBeam` | `BEAM` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortCharcoal` | `CHARCOAL` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortCoffee` | `COFFEE` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortFallback` | `STATION` | Craft tab, recipe row and card badge: short name when a recipe's station has no short name | 9 |
| `UI_ZeD_Station_ShortMill` | `MILL` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortQuern` | `QUERN` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortRack` | `RACK` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_StateIdle` | `Idle` | Craft tab, station band: a machine that is not working | 16 |
| `UI_ZeD_Station_StateInUseByYou` | `In use by you` | Craft tab, station band: state of the bench you stand at | 16 |
| `UI_ZeD_Station_StateNoPower` | `No power` | Craft tab, station band: an appliance with no power | 16 |
| `UI_ZeD_Station_StateRunning` | `Running` | Craft tab, station band: a machine that is working | 16 |
| `UI_ZeD_Station_TileMany` | `%1 TILES` | Craft tab, station band and station list: distance to the station | 10 |
| `UI_ZeD_Station_TileOne` | `1 TILE` | Craft tab, station band and station list: distance to the station | 10 |

## Status

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Status_Danger` | `DANGER` | Status chip text, red. | 10 |
| `UI_ZeD_Status_Info` | `INFO` | Status chip text, blue. | 10 |
| `UI_ZeD_Status_Warning` | `WARNING` | Status chip text, amber. | 10 |

## Strip

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Strip_OwnedCount` | `%1/%2 owned` | Crafting list, alternative-items strip, centre readout: items owned of items needed | 18 |
| `UI_ZeD_Strip_OwnedOnly` | `Owned only` | Crafting list, alternative-items strip, toggle that hides items you do not own | 16 |
| `UI_ZeD_Strip_Sort` | `SORT` | Crafting list, label at the left of the sort strip | 8 |

## Target

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Target_Selection` | `Selection` | Right-click menu, target card name when the clicked items cannot be named | - |
| `UI_ZeD_Target_Survivor` | `Survivor` | Right-click menu, target card name when a character has no name | - |

## Thermal

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Thermal_Air` | `AIR` | Thermal tab, readout line above the gradient bar: label before the air temperature | 8 |
| `UI_ZeD_Thermal_ByRegion` | `%1 by region` | Thermal tab, heading over the two-column body part grid; %1 is the active view's name (Skin temp, Insulation...) | - |
| `UI_ZeD_Thermal_Core` | `CORE` | Thermal tab, readout line above the gradient bar: label before the core temperature | 8 |
| `UI_ZeD_Thermal_RowShiver` | `Shiver / sweat` | Thermal tab hover detail (body part rolled over): stat row label, with the other seven metrics | 20 |
| `UI_ZeD_Thermal_TempC` | `%1°C` | Thermal tab: a temperature when the player's game option shows Celsius (core/air/wind line, skin temperature rows). %1 is the number with one decimal | 10 |
| `UI_ZeD_Thermal_TempF` | `%1°F` | Thermal tab: a temperature when the player's game option shows Fahrenheit. %1 is the converted number with one decimal | 10 |
| `UI_ZeD_Thermal_ViewShiver` | `Shiver / sweat` | Thermal tab (Character window): view button in the column beside the body figure, one of seven stacked pills (full column width) | 18 |
| `UI_ZeD_Thermal_ViewWetness` | `Wetness` | Thermal tab (Character window): view button in the column beside the body figure, one of seven stacked pills (full column width) | 18 |

## Track

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Track_CompassE` | `E` | Animal track card: the compass letter for east, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_CompassN` | `N` | Animal track card: the compass letter for north, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_CompassNE` | `NE` | Animal track card: the compass letter for north-east, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_CompassNW` | `NW` | Animal track card: the compass letter for north-west, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_CompassS` | `S` | Animal track card: the compass letter for south, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_CompassSE` | `SE` | Animal track card: the compass letter for south-east, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_CompassSW` | `SW` | Animal track card: the compass letter for south-west, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_CompassW` | `W` | Animal track card: the compass letter for west, drawn round the compass ring (1 letter for the main points, 2 for the corners; the corners use a tiny face) | 2 |
| `UI_ZeD_Track_TrackingLevel` | `\| TRACKING %1` | Animal track card: small dim text after the species; %1 is the player's Tracking level (capitals; the bar is a separator) | 16 |

## Traits

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Traits_AskDelete` | `Delete the build %1?` | Occupation and traits screen (new game): question in the action strip. %1 is the build's name | - |
| `UI_ZeD_Traits_AskName` | `Build name:` | Occupation and traits screen (new game): label before the name field in the action strip | - |
| `UI_ZeD_Traits_Builds` | `Builds...` | Occupation and traits screen (new game): strip button that opens the Builds pop-up | 14 |
| `UI_ZeD_Traits_ClearTraits` | `Clear traits` | Occupation and traits screen (new game): strip button that gives back every chosen trait | 16 |
| `UI_ZeD_Traits_DeleteBuild` | `Delete %1...` | Occupation and traits screen (new game): row of the Builds pop-up. %1 is the saved build's name | - |
| `UI_ZeD_Traits_FromOccupation` | `From the occupation.` | Occupation and traits screen (new game): added to the help of a trait the occupation gives for free | - |
| `UI_ZeD_Traits_HeadChosen` | `CHOSEN` | Occupation and traits screen (new game): caps heading over the chosen traits | - |
| `UI_ZeD_Traits_HeadNegative` | `NEGATIVE` | Occupation and traits screen (new game): caps heading over the negative traits column | - |
| `UI_ZeD_Traits_HeadPositive` | `POSITIVE` | Occupation and traits screen (new game): caps heading over the positive traits column | - |
| `UI_ZeD_Traits_HeadSkills` | `STARTING SKILLS` | Occupation and traits screen (new game): caps heading over the starting skills list | - |
| `UI_ZeD_Traits_NoneYet` | `None yet` | Occupation and traits screen (new game): empty list of chosen traits | - |
| `UI_ZeD_Traits_Penalty` | `Negative trait penalty %1` | Occupation and traits screen (new game): title bar note. %1 is the points the sandbox takes off | - |
| `UI_ZeD_Traits_PointsMany` | `%1 points` | Occupation and traits screen (new game): points left, shown in the title bar, for any other number | - |
| `UI_ZeD_Traits_PointsOne` | `%1 point` | Occupation and traits screen (new game): points left, shown in the title bar, when the number is 1 or -1 | - |
| `UI_ZeD_Traits_PromptBuilds` | `Builds` | Occupation and traits screen (new game): controller prompt (Y button) that opens the saved builds | 10 |
| `UI_ZeD_Traits_PromptChoose` | `Choose` | Occupation and traits screen (new game): controller prompt (A button) on the occupations column | 10 |
| `UI_ZeD_Traits_PromptGiveBack` | `Give back` | Occupation and traits screen (new game): controller prompt (A button) on the chosen traits column | 12 |
| `UI_ZeD_Traits_SaveBuild` | `Save build...` | Occupation and traits screen (new game): row of the Builds pop-up | - |
| `UI_ZeD_Traits_Title` | `Project Zomboid  +  Occupation and traits` | Occupation and traits screen (new game): title bar. The + is the ZeD title separator | - |

## Trough

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Trough_AddFood` | `Add food` | Feeding trough card: verb button | 14 |
| `UI_ZeD_Trough_AddWater` | `Add water` | Feeding trough card: verb button | 14 |
| `UI_ZeD_Trough_Animals` | `ANIMALS` | Feeding trough card: label of the number of animals using the trough (capitals) | 12 |
| `UI_ZeD_Trough_ConfirmEmpty` | `Pour %1 of %2 out of the trough?` | Feeding trough card: confirmation in the footer; %1 is the amount, e.g. 4.5 L, %2 the liquid's name in lower case | - |
| `UI_ZeD_Trough_Feed` | `FEED` | Feeding trough card: small word after the big feed amount (capitals) | 8 |
| `UI_ZeD_Trough_InTrough` | `IN THE TROUGH` | Feeding trough card: section heading over the list of feed lying in the trough (capitals) | - |
| `UI_ZeD_Trough_LinkedTo` | `LINKED TO` | Feeding trough card: label of the zone's name (capitals; the half-width column holds about 14 letters) | 14 |
| `UI_ZeD_Trough_NeedAddFood` | `Add food: %1` | Feeding trough card: the NEEDS line when the trough holds water; %1 is the game's own reason | - |
| `UI_ZeD_Trough_NeedAddWater` | `Add water: %1` | Feeding trough card: the NEEDS line when the trough holds feed; %1 is the game's own reason | - |
| `UI_ZeD_Trough_NothingToAdd` | `You carry nothing the trough takes.` | Feeding trough card: line under YOUR FEED when you have no feed | - |
| `UI_ZeD_Trough_NoZoneWarn` | `Not in an animal zone. Animals only eat and drink from troughs inside their zone.` | Feeding trough card: warning band (red) at the top | - |
| `UI_ZeD_Trough_PillFood` | `FOOD` | Feeding trough card: header pill for a trough holding feed (capitals) | 10 |
| `UI_ZeD_Trough_UseIt` | `%1 use it` | Feeding trough card: value of ANIMALS; %1 is how many animals use the trough | 16 |
| `UI_ZeD_Trough_WaterUnit` | `L OF %1 \| %2` | Feeding trough card: small text after the big water amount: litres of the trough's maximum, then the liquid; %1 is the maximum, e.g. 8.0 L, %2 the liquid in capitals (capitals; the bar is a separator) | 30 |
| `UI_ZeD_Trough_WaterWord` | `Water` | Feeding trough card: the word for the trough's water when the game names no liquid (also used lower-cased in the empty-out question) | 14 |
| `UI_ZeD_Trough_YourFeed` | `YOUR FEED` | Feeding trough card: section heading over the list of feed you carry (capitals) | - |
| `UI_ZeD_Trough_Zone` | `ZONE` | Feeding trough card: section heading over the zone lines (capitals) | - |
| `UI_ZeD_Trough_ZoneLinked` | `LINKED` | Feeding trough card: right side of the ZONE heading when the trough is in an animal zone (capitals) | 10 |

## Veh

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Veh_About` | `ABOUT` | Vehicle tab part card: heading above the part's description | 12 |
| `UI_ZeD_Veh_ActClosingLid` | `CLOSING THE LID` | Vehicle tab animal trailer page: progress band text while the trunk lid closes | 24 |
| `UI_ZeD_Veh_ActFeeding` | `FEEDING` | Vehicle tab animal trailer page: progress band text while an animal is fed | 24 |
| `UI_ZeD_Veh_ActGivingWater` | `GIVING WATER` | Vehicle tab animal trailer page: progress band text while an animal is watered | 24 |
| `UI_ZeD_Veh_ActGrabbing` | `GRABBING` | Vehicle tab animal trailer page: progress band text while an animal is picked up out of the trailer | 24 |
| `UI_ZeD_Veh_ActOpeningLid` | `OPENING THE LID` | Vehicle tab animal trailer page: progress band text while the trunk lid opens | 24 |
| `UI_ZeD_Veh_ActPuttingIn` | `PUTTING IN` | Vehicle tab animal trailer page: progress band text while an animal is loaded | 24 |
| `UI_ZeD_Veh_ActTakingOut` | `TAKING OUT` | Vehicle tab animal trailer page: progress band text while an animal is taken out | 24 |
| `UI_ZeD_Veh_ActUnlockingLid` | `UNLOCKING THE LID` | Vehicle tab animal trailer page: progress band text while the trunk lid is unlocked | 24 |
| `UI_ZeD_Veh_ActWalkingBack` | `WALKING TO THE BACK` | Vehicle tab animal trailer page: progress band text while the character walks to the back door first | 28 |
| `UI_ZeD_Veh_AirInTire` | `Air in the tire` | Vehicle tab part card, NEEDS list for Deflate: requirement line | 24 |
| `UI_ZeD_Veh_AmountLeft` | `%1 left` | Vehicle tab part card, NEEDS list: how much is still in the part (%1 = amount) | 12 |
| `UI_ZeD_Veh_AtBack` | `AT THE BACK` | Vehicle tab animal trailer page, Load from here list: the animal is right at the back door | 20 |
| `UI_ZeD_Veh_Below` | `Below %1` | Vehicle tab part card, NEEDS list for lightbar repair: condition must be under this (%1 = 100%) | 16 |
| `UI_ZeD_Veh_BelowPsi` | `Below %1 psi` | Vehicle tab part card, NEEDS list for Inflate: the tire must be below this pressure (%1 = number) | 24 |
| `UI_ZeD_Veh_Braking` | `Braking` | Vehicle tab brake card: label of the braking force row | 12 |
| `UI_ZeD_Veh_CantDo` | `Can't %1` | Vehicle tab part card, footer: status when an action is blocked; the missing requirement follows after a colon (%1 = action name in lower case) | 30 |
| `UI_ZeD_Veh_Charge` | `%1 charge` | Vehicle tab: battery charge, in the part list's info column and the summary (%1 = percentage with its % sign) | 16 |
| `UI_ZeD_Veh_ConfirmSmash` | `Smash the %1? The glass is lost.` | Vehicle tab part card, footer: confirmation question next to Yes / No (%1 = part name, lower case) | 50 |
| `UI_ZeD_Veh_ConfirmTakeParts` | `Take engine parts? The engine loses condition.` | Vehicle tab part card, footer: confirmation question next to Yes / No | 50 |
| `UI_ZeD_Veh_CountName` | `%1 %2` | Vehicle tab part card, repair list: how many of an item a repair uses (%1 = number, %2 = item name) | 40 |
| `UI_ZeD_Veh_Distance` | `Distance` | Vehicle tab summary before an inspection: label of the distance row | 12 |
| `UI_ZeD_Veh_EggMany` | `%1 eggs` | Vehicle tab animal trailer summary, Eggs container row: the container holds several eggs | 12 |
| `UI_ZeD_Veh_EggOne` | `%1 egg` | Vehicle tab animal trailer summary, Eggs container row: the container holds one egg | 12 |
| `UI_ZeD_Veh_EngineAbove` | `Engine above %1` | Vehicle tab part card, NEEDS list for Take parts: the engine must be over this condition (%1 = 10%) | 24 |
| `UI_ZeD_Veh_EngineBelow` | `Engine below %1` | Vehicle tab part card, NEEDS list for Repair engine: the engine must be under this condition (%1 = 100%) | 24 |
| `UI_ZeD_Veh_Failed` | `FAILED` | Vehicle tab: progress band text after an install or uninstall went wrong | 10 |
| `UI_ZeD_Veh_FailurePct` | `FAILURE %1` | Vehicle tab part card: chance bar label, right (%1 = percentage with its % sign) | 16 |
| `UI_ZeD_Veh_FixMissing` | `missing %1` | Vehicle tab part card, repair list second line: why a repair cannot be done (%1 = item name) | 30 |
| `UI_ZeD_Veh_FixOutcome` | `+%1 \| %2 success` | Vehicle tab part card, repair list second line: condition gained and chance of success (both with % signs) | 24 |
| `UI_ZeD_Veh_FixSkillLow` | `skill too low` | Vehicle tab part card, repair list second line: why a repair cannot be done | 20 |
| `UI_ZeD_Veh_Friction` | `Friction` | Vehicle tab: tire friction label (summary and card) | 12 |
| `UI_ZeD_Veh_FromBags` | `FROM YOUR BAGS AND NEARBY` | Vehicle tab part card for Install: heading above the list of parts you can fit | 34 |
| `UI_ZeD_Veh_FromYourBags` | `FROM YOUR BAGS` | Vehicle tab animal trailer animal card: right-hand tag on the Give water heading | 20 |
| `UI_ZeD_Veh_GrabWhy` | `GRAB: %1` | Vehicle tab animal trailer animal card, NEEDS list: why the animal cannot be grabbed (%1 = vanilla's reason, e.g. too heavy) | 50 |
| `UI_ZeD_Veh_HdrCond` | `COND` | Vehicle tab part list: column heading for condition, click to sort by condition | 8 |
| `UI_ZeD_Veh_HdrInfo` | `INFO` | Vehicle tab part list: column heading | 8 |
| `UI_ZeD_Veh_HdrPart` | `PART` | Vehicle tab part list: column heading, click to sort by area | 8 |
| `UI_ZeD_Veh_Hp` | `%1 hp` | Vehicle tab: engine power value (%1 = horsepower number) | 10 |
| `UI_ZeD_Veh_InspectThe` | `Inspect the %1 to read its parts` | Vehicle tab (not inspected yet): empty-state line under the car figure (%1 = vehicle name) | 60 |
| `UI_ZeD_Veh_InspectToRead` | `INSPECT TO READ` | Vehicle tab (animal trailer, not yet inspected): right-hand tag on the collapsed part list | 20 |
| `UI_ZeD_Veh_InYourHands` | `IN YOUR HANDS` | Vehicle tab animal trailer page, Load from here list: the animal or carcass you are carrying | 20 |
| `UI_ZeD_Veh_KeyHotwired` | `Hotwired` | Vehicle tab, Key row: the vehicle has been hotwired | 14 |
| `UI_ZeD_Veh_KeyNotNeeded` | `Not needed` | Vehicle tab, Key row: no key is needed for this vehicle | 14 |
| `UI_ZeD_Veh_KeyOnYou` | `On you` | Vehicle tab, Key row: the car key is in your inventory | 14 |
| `UI_ZeD_Veh_KgCaps` | `%1 KG` | Vehicle tab animal trailer animal card, NEEDS list: small right-hand tag with the animal's weight (%1 = number) | 10 |
| `UI_ZeD_Veh_KMustBeOff` | `MUST BE OFF` | Vehicle tab part card, NEEDS list: small right-hand tag, another part must be taken off first | 14 |
| `UI_ZeD_Veh_KMustBeOn` | `MUST BE ON` | Vehicle tab part card, NEEDS list: small right-hand tag, another part must be installed first | 14 |
| `UI_ZeD_Veh_Known` | `Known` | Vehicle tab part card, NEEDS list: value when you know the required recipe | 12 |
| `UI_ZeD_Veh_KRecipe` | `RECIPE` | Vehicle tab part card, NEEDS list: small right-hand tag on a required recipe | 12 |
| `UI_ZeD_Veh_KRequired` | `REQUIRED` | Vehicle tab part card, NEEDS list: small right-hand tag on a required skill level | 12 |
| `UI_ZeD_Veh_KToReachIn` | `TO REACH IN` | Vehicle tab animal trailer animal card, NEEDS list: small right-hand tag on the trunk lid requirement | 14 |
| `UI_ZeD_Veh_KWithinReach` | `WITHIN REACH` | Vehicle tab part card, NEEDS list for Install: small right-hand tag | 16 |
| `UI_ZeD_Veh_LidOpen` | `Trunk lid open` | Vehicle tab animal trailer animal card, NEEDS list: requirement line, met | 24 |
| `UI_ZeD_Veh_LoadFromHere` | `LOAD FROM HERE` | Vehicle tab animal trailer page: list heading for animals that can be loaded from where you stand | 20 |
| `UI_ZeD_Veh_LocInHand` | `IN HAND` | Vehicle tab animal trailer card, water and feed lists: where an item is, small second line (item is in a hand) | 14 |
| `UI_ZeD_Veh_Lock` | `Lock` | Vehicle tab door card: label of the row that shows the lock is broken | 10 |
| `UI_ZeD_Veh_Loudness` | `Loudness` | Vehicle tab: engine loudness label (summary and cards) | 12 |
| `UI_ZeD_Veh_LowersEngine` | `Lowers the engine's condition` | Vehicle tab part card, NEEDS list for Take parts: warning line | 36 |
| `UI_ZeD_Veh_MissingWorn` | `%1 missing  \|  %2 worn` | Vehicle tab summary: status line (%1 = missing or smashed parts, %2 = parts at 60% or less) | 30 |
| `UI_ZeD_Veh_NeedPart` | `A part to install` | Vehicle tab part card, NEEDS list for Install: requirement line | 30 |
| `UI_ZeD_Veh_NeedsFor` | `NEEDS \| %1` | Vehicle tab part card: heading above the NEEDS list (%1 = the action name in capitals) | 30 |
| `UI_ZeD_Veh_NoAnimalsInside` | `No animals inside` | Vehicle tab animal trailer page: empty-state line in the Animals list | 30 |
| `UI_ZeD_Veh_NoneNearby` | `NONE NEARBY` | Vehicle tab part card for Install: right-hand tag on a part type you do not have | 16 |
| `UI_ZeD_Veh_NoRecipeMaterials` | `no recipe has its materials` | Vehicle tab part card, Repair: line shown when no repair can be done with what you have | 36 |
| `UI_ZeD_Veh_NotEmpty` | `Not empty` | Vehicle tab part card, NEEDS list: value when the part still holds something | 12 |
| `UI_ZeD_Veh_NotFound` | `Not found` | Vehicle tab, Key row and requirement lists: no matching key in reach | 14 |
| `UI_ZeD_Veh_NothingItEats` | `Nothing it eats in your bags` | Vehicle tab animal trailer animal card, Feed list: shown when you carry nothing the animal eats | 40 |
| `UI_ZeD_Veh_NothingNeeded` | `Nothing needed` | Vehicle tab part card, NEEDS list: action with no requirements | 20 |
| `UI_ZeD_Veh_NothingNeedsWork` | `Nothing needs work` | Vehicle tab summary: status line when every part is fine | 26 |
| `UI_ZeD_Veh_NothingToDo` | `Nothing to do here` | Vehicle tab part card, footer: status when the part has no actions | 30 |
| `UI_ZeD_Veh_NotInspected` | `Not inspected` | Vehicle tab summary before an inspection: status line | 20 |
| `UI_ZeD_Veh_NoVehicle` | `No vehicle within reach` | Vehicle tab: empty-state line when no vehicle is near | 40 |
| `UI_ZeD_Veh_OfCap` | `%1 of %2` | Vehicle tab animal trailer animal card, Space row: space this animal takes of the trailer's capacity | 16 |
| `UI_ZeD_Veh_OrMore` | `%1 or %2 more` | Vehicle tab part card, NEEDS list: a requirement that several items can meet (%1 = first item name, %2 = how many others) | 40 |
| `UI_ZeD_Veh_OrOne` | `%1 or %2` | Vehicle tab part card, NEEDS list: a requirement that two items can meet (%1 and %2 = item names) | 40 |
| `UI_ZeD_Veh_Overall` | `Overall` | Vehicle tab summary: label above the overall condition bar (drawn in capitals) | 12 |
| `UI_ZeD_Veh_PartEmpty` | `%1 empty` | Vehicle tab part card, NEEDS list: requirement that the part is empty (%1 = part name) | 30 |
| `UI_ZeD_Veh_PartsClosed` | `> PARTS (%1)` | Vehicle tab (animal trailer, not yet inspected): collapsed heading of the part list (%1 = part count) | 16 |
| `UI_ZeD_Veh_Power` | `Power` | Vehicle tab: engine power label (summary and engine card) | 12 |
| `UI_ZeD_Veh_Pressure` | `Pressure` | Vehicle tab tire card: label of the air pressure row | 12 |
| `UI_ZeD_Veh_Psi` | `%1 psi` | Vehicle tab part card, NEEDS list: air pressure reading (%1 = number) | 12 |
| `UI_ZeD_Veh_PsiOf` | `%1 / %2 psi` | Vehicle tab: tire air pressure, current over normal, in the part list and on a tire's card (%1 current, %2 normal) | 20 |
| `UI_ZeD_Veh_PutIn` | `PUT IN` | Vehicle tab animal trailer page, Load from here list: small button that loads the animal | 12 |
| `UI_ZeD_Veh_ReadyCarcass` | `Ready to take the carcass out at the back` | Vehicle tab animal trailer animal card, footer status for a dead animal | 50 |
| `UI_ZeD_Veh_ReadyInstall` | `Ready to install` | Vehicle tab part card, footer: status when an install can start | 30 |
| `UI_ZeD_Veh_ReadyInstallItem` | `Ready to install %1` | Vehicle tab part card, footer: status when an install can start (%1 = item name) | 50 |
| `UI_ZeD_Veh_ReadyRepair` | `Ready to repair` | Vehicle tab part card, footer: status when a repair can start | 30 |
| `UI_ZeD_Veh_ReadyRepairWith` | `Ready to repair with %1` | Vehicle tab part card, footer: status when a repair can start (%1 = item name) | 50 |
| `UI_ZeD_Veh_ReadyTo` | `Ready to %1` | Vehicle tab part card, footer: status when an action can start (%1 = action name in lower case) | 36 |
| `UI_ZeD_Veh_ReadyWalkHer` | `Ready to walk her out at the back` | Vehicle tab animal trailer animal card, footer status for a female animal | 46 |
| `UI_ZeD_Veh_ReadyWalkHim` | `Ready to walk him out at the back` | Vehicle tab animal trailer animal card, footer status for a male animal | 46 |
| `UI_ZeD_Veh_Removed` | `Removed` | Vehicle tab part card, NEEDS list: value when another part has been removed as required | 12 |
| `UI_ZeD_Veh_RepairWith` | `REPAIR WITH` | Vehicle tab part card for Repair: heading above the list of repair options | 20 |
| `UI_ZeD_Veh_Seat` | `Seat` | Vehicle tab seat card: label of the row that shows the seat is occupied | 12 |
| `UI_ZeD_Veh_SizeHdr` | `SIZE` | Vehicle tab animal trailer page: right-hand tag on the Load from here heading (how much space each animal takes) | 8 |
| `UI_ZeD_Veh_Smashed` | `Smashed` | Vehicle tab: window state, in the summary, the card's Condition row and (in capitals) the part list badge | 12 |
| `UI_ZeD_Veh_Space` | `SPACE` | Vehicle tab animal trailer page: label for the trailer's animal capacity (summary row, list heading tag, row column, card) | 12 |
| `UI_ZeD_Veh_SpaceLeft` | `%1 of %2 \| %3 left` | Vehicle tab animal trailer summary, Space row: used, capacity and how much is left (%1 used, %2 capacity, %3 left) | 28 |
| `UI_ZeD_Veh_SpaceOver` | `%1 of %2 \| %3 over` | Vehicle tab animal trailer summary, Space row: used, capacity and how far over it is (%1 used, %2 capacity, %3 over) | 28 |
| `UI_ZeD_Veh_State` | `State` | Vehicle tab summary of a highlighted part: label of the row that shows its state (open, locked, charge...) | 12 |
| `UI_ZeD_Veh_StClosed` | `Closed` | Vehicle tab part list, info column: the door is closed | 10 |
| `UI_ZeD_Veh_StOccupied` | `Occupied` | Vehicle tab: a seat has someone in it (part list info column, and the Seat row on a seat card) | 12 |
| `UI_ZeD_Veh_StOpen` | `Open` | Vehicle tab: state of a door or window (part list info column) and the label of the Open row on a door or window card | 10 |
| `UI_ZeD_Veh_SuccessPct` | `SUCCESS %1` | Vehicle tab part card: chance bar label, left (%1 = percentage with its % sign) | 16 |
| `UI_ZeD_Veh_Temp` | `Temp` | Vehicle tab part card: label of the temperature row | 10 |
| `UI_ZeD_Veh_ThirstyCount` | `%1 of %2 \| no water inside` | Vehicle tab animal trailer summary, Thirsty row: how many animals are thirsty (%1 thirsty, %2 alive) | 36 |
| `UI_ZeD_Veh_TileFromBack` | `%1 TILE FROM THE BACK` | Vehicle tab animal trailer page, Load from here list: distance of an animal from the back door (exactly one tile) | 28 |
| `UI_ZeD_Veh_Tiles` | `%1 tiles` | Vehicle tab summary before an inspection: distance to the vehicle (none or several tiles) | 12 |
| `UI_ZeD_Veh_TilesFromBack` | `%1 TILES FROM THE BACK` | Vehicle tab animal trailer page, Load from here list: distance of an animal from the back door (several tiles) | 28 |
| `UI_ZeD_Veh_TilesOne` | `%1 tile` | Vehicle tab summary before an inspection: distance to the vehicle (exactly one tile) | 12 |
| `UI_ZeD_Veh_TowedBy` | `TOWED BY` | Vehicle tab summary: label of the row that names the vehicle towing this trailer | 12 |
| `UI_ZeD_Veh_Towing` | `TOWING` | Vehicle tab summary: label of the row that names the trailer this vehicle tows | 12 |
| `UI_ZeD_Veh_VDeflate` | `Deflate` | Vehicle tab part card: action button on a tire (drawn in capitals) | 14 |
| `UI_ZeD_Veh_VInflate` | `Inflate` | Vehicle tab part card: action button on a tire (drawn in capitals) | 14 |
| `UI_ZeD_Veh_VSmash` | `Smash` | Vehicle tab part card: action button on a window (drawn in capitals) | 14 |
| `UI_ZeD_Veh_VTakeParts` | `Take parts` | Vehicle tab part card: action button on the engine, takes spare parts out of it (drawn in capitals) | 16 |
| `UI_ZeD_Veh_WaterMeta` | `%1  \|  %2 ML` | Vehicle tab animal trailer card, Give water list, second line (%1 = where the container is, %2 = millilitres of water) | 40 |
| `UI_ZeD_Veh_WhatItEats` | `WHAT IT EATS FROM YOUR BAGS` | Vehicle tab animal trailer animal card: right-hand tag on the Feed heading | 34 |
| `UI_ZeD_Veh_WorkingBack` | `Working at the back of the trailer` | Vehicle tab animal trailer animal card, footer status while an action runs | 40 |
| `UI_ZeD_Veh_WorkingOn` | `Working on the %1` | Vehicle tab part card, footer: status while an action runs (%1 = part name, lower case) | 36 |
| `UI_ZeD_Veh_WorstFirst` | `WORST FIRST` | Vehicle tab part list: heading used when the list is sorted by condition | 16 |

## Watch

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Watch_Alarm` | `ALARM` | Full watch, LCD or dial display while setting the alarm and the alarm is armed | 8 |
| `UI_ZeD_Watch_AlarmOff` | `ALARM OFF` | Full watch, display while setting the alarm and it is off | 10 |
| `UI_ZeD_Watch_Alm` | `ALM` | Full watch, LCD indicator that the alarm is armed | 4 |
| `UI_ZeD_Watch_DayFr` | `FR` | Full watch, digital LCD: the weekday abbreviation for Friday, exactly two letters | 2 |
| `UI_ZeD_Watch_DayMo` | `MO` | Full watch, digital LCD: the weekday abbreviation for Monday, exactly two letters | 2 |
| `UI_ZeD_Watch_DaySa` | `SA` | Full watch, digital LCD: the weekday abbreviation for Saturday, exactly two letters | 2 |
| `UI_ZeD_Watch_DaySu` | `SU` | Full watch, digital LCD: the weekday abbreviation for Sunday, exactly two letters | 2 |
| `UI_ZeD_Watch_DayTh` | `TH` | Full watch, digital LCD: the weekday abbreviation for Thursday, exactly two letters | 2 |
| `UI_ZeD_Watch_DayTu` | `TU` | Full watch, digital LCD: the weekday abbreviation for Tuesday, exactly two letters | 2 |
| `UI_ZeD_Watch_DayWe` | `WE` | Full watch, digital LCD: the weekday abbreviation for Wednesday, exactly two letters | 2 |
| `UI_ZeD_Watch_Pause` | `PAUSE` | Full watch, display while the game is paused | 6 |
| `UI_ZeD_Watch_SetHint` | `-1H  +1H` | Full watch, display while setting the alarm: the two keys step the hour down and up (H = hour) | 10 |
| `UI_ZeD_Watch_SetText` | `AL %1` | Full watch, small display while setting the alarm; %1 = the alarm hour, two digits | 6 |
| `UI_ZeD_Watch_SetTextOff` | `AL OFF` | Full watch, small display while setting the alarm and it is off | 6 |

## Wheel

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Wheel_Animal` | `Animal` | D-pad wheels: World wheel slice: the animal wheel | 12 |
| `UI_ZeD_Wheel_AutoWalk` | `Auto-walk` | D-pad wheels: Here and now slice: auto-walk on / off | 12 |
| `UI_ZeD_Wheel_AutoZoom` | `Auto zoom is on in Options.` | D-pad wheels: Reason on the zoom slices | 32 |
| `UI_ZeD_Wheel_BeltSlot` | `Belt, slot %1` | D-pad wheels: Second line of a weapon slice: on the belt; %1 = slot number | 20 |
| `UI_ZeD_Wheel_Character` | `Character` | D-pad wheels: Name of the D-pad Left wheel (breadcrumb under the ring) | 16 |
| `UI_ZeD_Wheel_CharacterWindow` | `Character window` | D-pad wheels: Second line of the Character wheel's Tabs slice | 24 |
| `UI_ZeD_Wheel_Chat` | `Chat` | D-pad wheels: Social wheel slice: type in the server chat | 12 |
| `UI_ZeD_Wheel_ChatDetail` | `Type with a keyboard` | D-pad wheels: Second line of Chat | 24 |
| `UI_ZeD_Wheel_Clothing` | `Clothing` | D-pad wheels: Character wheel slice: hood, mask, glasses and the like | 16 |
| `UI_ZeD_Wheel_ComingLater` | `Coming later.` | D-pad wheels: Reason on a wheel slice that is not built yet | 30 |
| `UI_ZeD_Wheel_ControllerMap` | `Controller map` | D-pad wheels: Help slice: what every button does (not built yet) | 20 |
| `UI_ZeD_Wheel_CraftBuild` | `Craft and build` | D-pad wheels: World wheel slice: crafting, building, furniture | 20 |
| `UI_ZeD_Wheel_Crouch` | `Crouch` | D-pad wheels: Here and now slice: crouch on / off | 12 |
| `UI_ZeD_Wheel_EveryRadio` | `Every radio you carry` | D-pad wheels: Second line of the Radio tab slice | 24 |
| `UI_ZeD_Wheel_EveryWound` | `Every wound` | D-pad wheels: Second line of the Health tab slice in Medicine and first aid | 20 |
| `UI_ZeD_Wheel_EverythingYouWear` | `Everything you wear` | D-pad wheels: Second line of the Equipment tab slice in Clothing | 24 |
| `UI_ZeD_Wheel_FireCard` | `Choose how on the fire's card` | D-pad wheels: Second line of Light fire: it opens the fire's card | 32 |
| `UI_ZeD_Wheel_FireLit` | `Burning` | D-pad wheels: Second line of Put out fire | 16 |
| `UI_ZeD_Wheel_GameSpeed` | `Game speed` | D-pad wheels: Here and now slice: pause, play, fast forward | 16 |
| `UI_ZeD_Wheel_GetUp` | `Get up` | D-pad wheels: Sit wheel slice while sitting | 12 |
| `UI_ZeD_Wheel_GlyphSelect` | `SELECT` | D-pad wheels: The Select (View / Share) button's name in a button prompt box | 8 |
| `UI_ZeD_Wheel_HandsAlreadyFree` | `Your hands are already free.` | D-pad wheels: Reason: nothing in either hand | 34 |
| `UI_ZeD_Wheel_HandsFree` | `Hands free` | D-pad wheels: Weapons wheel slice: put away what both hands hold | 16 |
| `UI_ZeD_Wheel_HandsFreeDetail` | `Put both hands' things away` | D-pad wheels: Second line of Hands free | 30 |
| `UI_ZeD_Wheel_Help` | `Help` | D-pad wheels: Here and now slice: survival guide, controller map | 12 |
| `UI_ZeD_Wheel_HereNow` | `Here and now` | D-pad wheels: Name of the D-pad Down wheel (breadcrumb) | 20 |
| `UI_ZeD_Wheel_HideInterface` | `Hide the interface` | D-pad wheels: View slice: hide every window and HUD piece | 24 |
| `UI_ZeD_Wheel_HideInterfaceDetail` | `Until you take this again` | D-pad wheels: Second line of Hide the interface | 28 |
| `UI_ZeD_Wheel_InUse` | `In use` | D-pad wheels: Second line of a wheel slice: the choice in use now | 16 |
| `UI_ZeD_Wheel_InVehicle` | `In a vehicle.` | D-pad wheels: Reason on Sit, Crouch and Auto-walk while seated in a vehicle | 24 |
| `UI_ZeD_Wheel_InYourHands` | `In your hands` | D-pad wheels: Second line of a weapon slice: already held | 20 |
| `UI_ZeD_Wheel_Light` | `Light` | D-pad wheels: Here and now slice when you carry no light | 12 |
| `UI_ZeD_Wheel_LightsPower` | `Lights and power` | D-pad wheels: World wheel slice: room lights, generator, fire | 20 |
| `UI_ZeD_Wheel_Map` | `Map` | D-pad wheels: World wheel slice: world map and mini-map | 12 |
| `UI_ZeD_Wheel_Medicine` | `Medicine and first aid` | D-pad wheels: Character wheel slice: pills and wound treatments | 24 |
| `UI_ZeD_Wheel_NextStation` | `Next station` | D-pad wheels: Radio wheel slice: tune to the next station | 16 |
| `UI_ZeD_Wheel_NoAnimal` | `No tame animal in reach.` | D-pad wheels: Reason on the Animal slice | 30 |
| `UI_ZeD_Wheel_NoFire` | `No fire nearby.` | D-pad wheels: Reason on the fire slice | 24 |
| `UI_ZeD_Wheel_NoGenerator` | `No generator nearby.` | D-pad wheels: Reason on the Generator slice | 30 |
| `UI_ZeD_Wheel_NoLight` | `No light on you.` | D-pad wheels: Reason on the Light slice | 24 |
| `UI_ZeD_Wheel_NoLights` | `No lights or power in reach.` | D-pad wheels: Reason on the Lights and power slice | 34 |
| `UI_ZeD_Wheel_NoMiniMap` | `The mini-map is off in this game.` | D-pad wheels: Reason: the sandbox turns the mini-map off | 40 |
| `UI_ZeD_Wheel_NoRadioInReach` | `No radio in reach.` | D-pad wheels: Reason on the World window's Radio tab slice | 30 |
| `UI_ZeD_Wheel_NoRadioOnYou` | `No radio in your hands or on your back.` | D-pad wheels: Reason on the Radio slice and tab | 44 |
| `UI_ZeD_Wheel_NoSafetyHere` | `This server has no safety system.` | D-pad wheels: Reason on Safety | 40 |
| `UI_ZeD_Wheel_NoSeat` | `No seat in reach.` | D-pad wheels: Reason on Sit on a seat | 24 |
| `UI_ZeD_Wheel_NoSleepHere` | `This server does not allow sleeping.` | D-pad wheels: Reason on the Sleep slice on a server without sleep | 40 |
| `UI_ZeD_Wheel_NoSwitch` | `No light switch in reach.` | D-pad wheels: Reason on Room lights | 30 |
| `UI_ZeD_Wheel_NoVehicle` | `No vehicle in reach.` | D-pad wheels: Reason on the Vehicle slice | 30 |
| `UI_ZeD_Wheel_NoWatch` | `No watch on your wrist.` | D-pad wheels: Reason on the Watch slice | 30 |
| `UI_ZeD_Wheel_NoWeapon` | `No weapon on you.` | D-pad wheels: Reason: no weapon to equip | 30 |
| `UI_ZeD_Wheel_NoWorldMap` | `The world map is off in this game.` | D-pad wheels: Reason: the sandbox turns the world map off | 40 |
| `UI_ZeD_Wheel_NotNow` | `Not now.` | D-pad wheels: Reason on a wheel slice that cannot be used right now | 30 |
| `UI_ZeD_Wheel_NothingFound` | `Nothing found yet.` | D-pad wheels: Reason on Pick up: search mode has found nothing | 30 |
| `UI_ZeD_Wheel_NothingToChange` | `Nothing you wear can change.` | D-pad wheels: Reason on the Clothing slice | 34 |
| `UI_ZeD_Wheel_NothingToDrink` | `Nothing to drink on you.` | D-pad wheels: Reason on the Drink slice | 30 |
| `UI_ZeD_Wheel_NothingToEat` | `Nothing to eat on you.` | D-pad wheels: Reason on the Eat slice | 30 |
| `UI_ZeD_Wheel_NothingToRead` | `Nothing to read on you.` | D-pad wheels: Reason on the Read slice | 30 |
| `UI_ZeD_Wheel_NothingToSmoke` | `Nothing to smoke, or nothing to light it.` | D-pad wheels: Reason on the Smoke slice | 44 |
| `UI_ZeD_Wheel_NothingToTreat` | `Nothing to treat, no medicine on you.` | D-pad wheels: Reason on the Medicine and first aid slice | 40 |
| `UI_ZeD_Wheel_OnTheBelt` | `On the belt` | D-pad wheels: Second line of a weapon slice: on the belt, slot unknown | 20 |
| `UI_ZeD_Wheel_OpenWatch` | `Open the watch` | D-pad wheels: Watch wheel slice: show the full watch | 20 |
| `UI_ZeD_Wheel_Players` | `Players` | D-pad wheels: Social wheel slice: who is on the server | 12 |
| `UI_ZeD_Wheel_PlayersDetail` | `Who is on the server` | D-pad wheels: Second line of Players | 24 |
| `UI_ZeD_Wheel_PromptClose` | `Close` | D-pad wheels: Prompt under a wheel: B closes it | 12 |
| `UI_ZeD_Wheel_PromptHold` | `Hold` | D-pad wheels: Prompt under a wheel: hold the D-pad direction | 12 |
| `UI_ZeD_Wheel_PromptLetGo` | `Let go: take` | D-pad wheels: Prompt under a wheel: let go of the D-pad to take the pointed slice | 20 |
| `UI_ZeD_Wheel_PromptPoint` | `Point` | D-pad wheels: Prompt under a wheel: point with the right stick | 12 |
| `UI_ZeD_Wheel_PromptTake` | `Take` | D-pad wheels: Prompt under an inner wheel: A takes the pointed slice | 12 |
| `UI_ZeD_Wheel_RadioIsOff` | `The radio is off.` | D-pad wheels: Reason on Next station | 24 |
| `UI_ZeD_Wheel_ResetWindows` | `Reset windows` | D-pad wheels: Slice: both windows back to their default places (the footer's R) | 20 |
| `UI_ZeD_Wheel_ResetWindowsDetail` | `Both windows, as the footer's R` | D-pad wheels: Second line of Reset windows | 32 |
| `UI_ZeD_Wheel_RoomLights` | `Room lights` | D-pad wheels: Lights and power slice: the room's light switch | 16 |
| `UI_ZeD_Wheel_SafeModeAsk` | `Turn on safe mode? ZeD-GUI steps aside and the game's own interface comes back. To turn it off again: Options, ZeD setup, Safe mode.` | D-pad wheels: Prompt before the ZeD wheel turns safe mode on | 160 |
| `UI_ZeD_Wheel_SafeModeDetail` | `The game's own interface` | D-pad wheels: Second line of the Safe mode slice | 28 |
| `UI_ZeD_Wheel_Safety` | `Safety` | D-pad wheels: Social wheel slice: the safety against other players | 12 |
| `UI_ZeD_Wheel_SafetyWait` | `Wait: safety can't change yet.` | D-pad wheels: Reason on Safety during its countdown | 34 |
| `UI_ZeD_Wheel_Search` | `Search` | D-pad wheels: World wheel slice: search mode, investigate, pick up | 12 |
| `UI_ZeD_Wheel_ServerOnly` | `On a server only.` | D-pad wheels: Reason on a Social wheel slice in single player | 30 |
| `UI_ZeD_Wheel_ServerTime` | `On a server the server sets the time.` | D-pad wheels: Reason on Game speed on a server | 40 |
| `UI_ZeD_Wheel_ShowInterface` | `Show the interface` | D-pad wheels: View slice while the interface is hidden | 24 |
| `UI_ZeD_Wheel_Sit` | `Sit` | D-pad wheels: Here and now slice: sit on the ground or a seat | 12 |
| `UI_ZeD_Wheel_SitOn` | `Sit on: %1` | D-pad wheels: Sit wheel slice: the nearest seat; %1 = the seat's name | 30 |
| `UI_ZeD_Wheel_SitOnSeat` | `Sit on a seat` | D-pad wheels: Sit wheel slice when no seat is near | 20 |
| `UI_ZeD_Wheel_SleepInCar` | `In the car` | D-pad wheels: Second line of the Sleep slice when seated in a car | 20 |
| `UI_ZeD_Wheel_Social` | `Social` | D-pad wheels: Name of the D-pad Up wheel (breadcrumb) | 16 |
| `UI_ZeD_Wheel_Tabs` | `Tabs` | D-pad wheels: Wheel slice that opens a wheel of the window's tabs | 16 |
| `UI_ZeD_Wheel_Use` | `Use` | D-pad wheels: Character wheel slice: smoke, read, watch, radio | 12 |
| `UI_ZeD_Wheel_UseDetail` | `Smoke \| Read \| Watch \| Radio` | D-pad wheels: Second line of the Use slice (what is inside) | 32 |
| `UI_ZeD_Wheel_Vehicle` | `Vehicle` | D-pad wheels: World wheel slice: the vehicle wheel | 12 |
| `UI_ZeD_Wheel_View` | `View` | D-pad wheels: Here and now slice: interface and windows | 12 |
| `UI_ZeD_Wheel_ViewDetail` | `Interface and windows` | D-pad wheels: Second line of View | 24 |
| `UI_ZeD_Wheel_Watch` | `Watch` | D-pad wheels: Use wheel slice: the watch you wear | 12 |
| `UI_ZeD_Wheel_WatchAlarm` | `Alarm` | D-pad wheels: Watch wheel slice: the alarm on / off | 12 |
| `UI_ZeD_Wheel_WatchAlwaysOpen` | `The watch is always open (Options: Watch, Corner).` | D-pad wheels: Reason on Open the watch when the watch is set to the corner | 52 |
| `UI_ZeD_Wheel_WatchLight` | `Light` | D-pad wheels: Watch wheel slice: light the watch | 12 |
| `UI_ZeD_Wheel_WatchNoLight` | `This watch has no light.` | D-pad wheels: Reason on the watch's Light slice | 30 |
| `UI_ZeD_Wheel_Weapons` | `Weapons` | D-pad wheels: Character wheel slice: the weapons you carry | 16 |
| `UI_ZeD_Wheel_World` | `World` | D-pad wheels: Name of the D-pad Right wheel (breadcrumb) | 16 |
| `UI_ZeD_Wheel_WorldWindow` | `World window` | D-pad wheels: Second line of the World wheel's Tabs slice | 20 |
| `UI_ZeD_Wheel_ZeD` | `ZeD` | D-pad wheels: Name of the Select button's wheel (breadcrumb) | 12 |
| `UI_ZeD_Wheel_ZeDSetupDetail` | `Options, on ZeD's page` | D-pad wheels: Second line of the ZeD setup / Options slice | 28 |
| `UI_ZeD_Wheel_Zoom` | `Zoom` | D-pad wheels: Here and now slice: zoom in and out | 12 |
| `UI_ZeD_Wheel_TreatWounds` | `Treat wounds` | Controller D-pad Right wheel, the slice that opens the Health tab when a wound needs care | 24 |

## Workshop

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Workshop_AskEveryone` | `Upload "%1" for everyone to see?` | Workshop upload screen: question in the action strip. %1 is the item's title | - |
| `UI_ZeD_Workshop_AskFriends` | `Upload "%1" for your Steam friends to see?` | Workshop upload screen: question in the action strip. %1 is the item's title | - |
| `UI_ZeD_Workshop_Asking` | `Asking Steam for a new item...` | Workshop upload screen: progress text in the strip while a new item is created | - |
| `UI_ZeD_Workshop_AskLink` | `Upload "%1" for anyone with the link to see?` | Workshop upload screen: question in the action strip. %1 is the item's title | - |
| `UI_ZeD_Workshop_AskOnlyYou` | `Upload "%1" for only you to see?` | Workshop upload screen: question in the action strip. %1 is the item's title | - |
| `UI_ZeD_Workshop_AskSave` | `Save your changes to workshop.txt?` | Workshop upload screen: question in the action strip when leaving with unsaved edits | - |
| `UI_ZeD_Workshop_CodesCopied` | `The description's Steam codes are on the clipboard` | Workshop upload screen: note after Copy Steam codes | - |
| `UI_ZeD_Workshop_ContentsOk` | `The folder has what Steam needs.` | Workshop upload screen: the check of the folder's contents passed | - |
| `UI_ZeD_Workshop_CopyCodes` | `Copy Steam codes` | Workshop upload screen: button that copies the description's formatting codes | 20 |
| `UI_ZeD_Workshop_CreateFailed` | `Steam would not start a new item. Is Steam running and signed in?` | Workshop upload screen: red note | - |
| `UI_ZeD_Workshop_DescriptionTooLong` | `The description is over Steam's %1 characters` | Workshop upload screen: in the strip, why Upload is off. %1 is the limit | - |
| `UI_ZeD_Workshop_ItemNew` | `New: Steam gives it a number on the first upload.` | Workshop upload screen: value of the Workshop item row for a new item | - |
| `UI_ZeD_Workshop_LabelChangeNote` | `CHANGE NOTE` | Workshop upload screen: caps label at the left of the change note field | 15 |
| `UI_ZeD_Workshop_LabelItem` | `WORKSHOP ITEM` | Workshop upload screen: caps label at the left of the item number | 15 |
| `UI_ZeD_Workshop_LabelPreview` | `PREVIEW PICTURE` | Workshop upload screen: caps label at the left of the preview picture | 15 |
| `UI_ZeD_Workshop_LabelWhatGoesUp` | `WHAT GOES UP` | Workshop upload screen: caps label at the left of the check of the folder's contents | 15 |
| `UI_ZeD_Workshop_LabelWho` | `WHO CAN SEE IT` | Workshop upload screen: caps label at the left of the visibility buttons | 15 |
| `UI_ZeD_Workshop_NeedDescription` | `It needs a description` | Workshop upload screen: in the strip, why Upload is off | - |
| `UI_ZeD_Workshop_NeedTitle` | `It needs a title` | Workshop upload screen: in the strip, why Upload is off | - |
| `UI_ZeD_Workshop_NoFolders` | `No folders in Zomboid/Workshop yet. Copy ModTemplate there, rename it and put your mod in its Contents/mods folder; it shows here.` | Workshop upload screen: empty folder list (keep the names ModTemplate, Zomboid/Workshop and Contents/mods) | - |
| `UI_ZeD_Workshop_NoneYet` | `None yet.` | Workshop upload screen: the description when it is empty | - |
| `UI_ZeD_Workshop_NoPicture` | `No picture: the folder needs a preview.png, 256 x 256.` | Workshop upload screen: under the picture box (keep preview.png and 256 x 256) | - |
| `UI_ZeD_Workshop_NoSteam` | `Steam is not running` | Workshop upload screen: red status in the title bar | - |
| `UI_ZeD_Workshop_NotCreated` | `Steam did not create the item (its answer: %1)` | Workshop upload screen: red note. %1 is Steam's answer | - |
| `UI_ZeD_Workshop_NoteHelpNew` | `Shown on the change notes page from the first upload on.` | Workshop upload screen: under the change note field, for a new item | - |
| `UI_ZeD_Workshop_NoteHelpUpdate` | `What changed, for the item's change notes page.` | Workshop upload screen: under the change note field, for an item already on the Workshop | - |
| `UI_ZeD_Workshop_NothingToUpload` | `Nothing to upload` | Workshop upload screen: in the strip when there are no folders | - |
| `UI_ZeD_Workshop_NotOnWorkshop` | `Not on the Workshop yet` | Workshop upload screen: under a folder in the list | - |
| `UI_ZeD_Workshop_NotSaved` | `not saved` | Workshop upload screen: added after a \| to a folder whose form has unsaved edits | - |
| `UI_ZeD_Workshop_NotUpdated` | `The upload did not go through (Steam's answer: %1)` | Workshop upload screen: red note. %1 is Steam's answer | - |
| `UI_ZeD_Workshop_OnWorkshop` | `On the Workshop \| %1` | Workshop upload screen: under a folder in the list. %1 is the item number. The \| is a separator | - |
| `UI_ZeD_Workshop_OpenInSteam` | `Open in Steam` | Workshop upload screen: button that opens the item's Steam page | 18 |
| `UI_ZeD_Workshop_PictureOk` | `256 x 256: the size the game asks for. It must stay under 1000 KB.` | Workshop upload screen: under the picture box | - |
| `UI_ZeD_Workshop_PictureWrongSize` | `This one is %1 x %2; the game takes only 256 x 256.` | Workshop upload screen: under the picture box. %1 and %2 are its width and height | - |
| `UI_ZeD_Workshop_Saved` | `Saved to Workshop/%1/workshop.txt` | Workshop upload screen: note after Save. %1 is the folder's name (keep the path as it is) | - |
| `UI_ZeD_Workshop_SaveFailed` | `Could not write workshop.txt` | Workshop upload screen: red note after Save failed | - |
| `UI_ZeD_Workshop_SeenEveryone` | `Seen by everyone.` | Workshop upload screen: line under the visibility buttons | - |
| `UI_ZeD_Workshop_SeenFriends` | `Seen by your Steam friends.` | Workshop upload screen: line under the visibility buttons | - |
| `UI_ZeD_Workshop_SeenLink` | `Seen by anyone with the link.` | Workshop upload screen: line under the visibility buttons | - |
| `UI_ZeD_Workshop_SeenOnlyYou` | `Seen by only you.` | Workshop upload screen: line under the visibility buttons | - |
| `UI_ZeD_Workshop_SendFailed` | `Steam would not take the upload. Is Steam running and signed in?` | Workshop upload screen: red note | - |
| `UI_ZeD_Workshop_Title` | `Project Zomboid  +  Workshop` | Workshop upload screen: title bar. The + is the ZeD title separator | - |
| `UI_ZeD_Workshop_Upload` | `Upload` | Workshop upload screen: strip button; also confirms the question | 12 |
| `UI_ZeD_Workshop_Uploaded` | `Uploaded. It is item %1 on the Workshop.` | Workshop upload screen: note after a good upload. %1 is the Workshop item number | - |
| `UI_ZeD_Workshop_UploadedLegal` | `Uploaded. It is item %1 on the Workshop. Steam asks you to accept the Workshop agreement on its page before others can see it.` | Workshop upload screen: note after a good upload that still needs the Workshop agreement. %1 is the item number | - |
| `UI_ZeD_Workshop_Uploading` | `Uploading to the Workshop %1 \| %2 of %3` | Workshop upload screen: progress text in the strip. %1 percent (with its % sign), %2 bytes sent, %3 bytes in all (sizes like 2.4 MB) | - |
| `UI_ZeD_Workshop_UploadingNoTotal` | `Uploading to the Workshop...` | Workshop upload screen: progress text in the strip before the size is known | - |
| `UI_ZeD_Workshop_UploadUpdate` | `Upload update` | Workshop upload screen: strip button for an item already on the Workshop | 16 |
| `UI_ZeD_Workshop_YourMods` | `YOUR MODS` | Workshop upload screen: caps heading over the list of folders in Zomboid/Workshop | - |

## World

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_World_ComingSoon` | `Coming soon` | World window: placeholder for a tab that has no content yet | - |
| `UI_ZeD_World_ContainersMany` | `%1 containers` | World window: title when several container columns are shown | - |
| `UI_ZeD_World_ContainersOne` | `%1 container` | World window: title when one container column is shown | - |
| `UI_ZeD_World_SearchStructures` | `Search structures...` | Build tab: search box placeholder | - |
| `UI_ZeD_World_SortDist` | `DIST` | World window container strip: sort button, natural (distance) order | 5 |
| `UI_ZeD_World_SortType` | `TYPE` | World window container strip: sort button, by type | 5 |
| `UI_ZeD_World_SortWt` | `WT` | World window container strip: sort button, heaviest first | 5 |
| `UI_ZeD_World_TabAnimals` | `Animals` | World window: tab name | 12 |
| `UI_ZeD_World_TabBuilding` | `Building` | World window: tab name | 12 |
| `UI_ZeD_World_TabLoot` | `Loot` | World window: tab name (hover title and drawer title) | 12 |
| `UI_ZeD_World_TabMaps` | `Maps` | World window: tab name | 12 |
| `UI_ZeD_World_TabVehicle` | `Vehicle` | World window: tab name (shown only near a vehicle) | 12 |
| `UI_ZeD_World_Title` | `World` | World window: title bar text, and the window-rolled tab's fallback name | 16 |

## General

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Close` | `Close` | Close button text. | 12 |
| `UI_ZeD_ModDesc` | `Total UI overhaul for Project Zomboid` | The mod list: the mod's one-line description. | 60 |
| `UI_ZeD_ModName` | `ZeD-GUI` | The mod list: the mod's name. | 12 |
| `UI_ZeD_NoResults` | `No results` | Empty list line when a search finds nothing. | 24 |
| `UI_ZeD_Weight` | `Weight` | Weight label. | 12 |
