# ZeD-UI translation context

Generated from the sweep. One row per key in `Translate/EN/UI.json`: the English, where the phrase shows, and the longest it should be. JSON has no room for comments, so this file is the notes.

- `%1` to `%4` are filled in by the game (a number, a name). Keep them, in any order that suits your language.
- Markup like `<LINE>` or `<RGB:1,1,1>` stays as written.
- **Max** is the most characters that fit where the phrase is drawn. "-" means there is no fixed limit (the box grows or the text wraps). Pixel-face text (the action bar, and the watch, dash and radio readouts) draws capitals, digits and a few signs; accented Latin and Cyrillic capitals work, other alphabets fall back to the plain face.
- Only the pixel-face words are capitals: the action bar labels (READING, CHEWING) and the marks on the dash, watch and radio. They stay capitals in your language. Everything else in English is sentence case, one capital at the start and the rest in lower case (Next level, Show survey), for headings, column heads, tags, buttons and status words alike; write yours the way your language writes a heading or a button, not in capitals.
- Where the game already has a phrase (body parts, exercise names, thermal views, Steam item states, farming states, short tags and column heads), ZeD uses the key of the game itself, so it arrives translated from the game files and is not listed here. A tag or column head arrives in whatever case the game text has, and ZeD sets it in sentence case.

Total keys: 3434.

## Areas

- [Accent](#accent) (1)
- [Act](#act) (284)
- [ActionBar](#actionbar) (4)
- [Animals](#animals) (163)
- [Appliance](#appliance) (21)
- [Belt](#belt) (34)
- [Card](#card) (95)
- [Char](#char) (31)
- [Controls](#controls) (13)
- [Craft](#craft) (29)
- [Credits](#credits) (3)
- [CtxMenu](#ctxmenu) (2)
- [Curtain](#curtain) (4)
- [CW](#cw) (4)
- [Dash](#dash) (65)
- [Death](#death) (12)
- [DescEdit](#descedit) (72)
- [Desktop](#desktop) (7)
- [Disclose](#disclose) (3)
- [Doll](#doll) (23)
- [Drawer](#drawer) (2)
- [Equip](#equip) (40)
- [Farm](#farm) (50)
- [Fire](#fire) (60)
- [Fluid](#fluid) (31)
- [Flyer](#flyer) (4)
- [Focus](#focus) (1)
- [Forage](#forage) (52)
- [Furn](#furn) (25)
- [Hair](#hair) (71)
- [Health](#health) (12)
- [Hook](#hook) (30)
- [Host](#host) (10)
- [Hud](#hud) (1)
- [Hutch](#hutch) (41)
- [Identity](#identity) (21)
- [Inv](#inv) (17)
- [ItemAct](#itemact) (3)
- [ItemMenu](#itemmenu) (1)
- [Join](#join) (44)
- [Journal](#journal) (32)
- [Keyboard](#keyboard) (12)
- [Lock](#lock) (58)
- [Looks](#looks) (11)
- [Machine](#machine) (18)
- [MainMenu](#mainmenu) (52)
- [Map](#map) (81)
- [Meta](#meta) (8)
- [MMHelp](#mmhelp) (58)
- [MMWord](#mmword) (2)
- [Modal](#modal) (2)
- [Mods](#mods) (293)
- [ModScan](#modscan) (36)
- [Msg](#msg) (38)
- [NewGame](#newgame) (3)
- [Notebook](#notebook) (23)
- [ObjCard](#objcard) (17)
- [Options](#options) (93)
- [Papers](#papers) (21)
- [PartAbbr](#partabbr) (14)
- [Place](#place) (8)
- [Power](#power) (47)
- [Print](#print) (2)
- [Progress](#progress) (1)
- [Prompt](#prompt) (38)
- [Radio](#radio) (38)
- [RadioPrompt](#radioprompt) (18)
- [Read](#read) (18)
- [Reader](#reader) (49)
- [Recipe](#recipe) (1)
- [Safe](#safe) (3)
- [Sandbox](#sandbox) (13)
- [Saves](#saves) (14)
- [Sbx](#sbx) (189)
- [Seat](#seat) (8)
- [Server](#server) (55)
- [Settings](#settings) (88)
- [Siren](#siren) (4)
- [Skills](#skills) (15)
- [Spawn](#spawn) (9)
- [SPNCC](#spncc) (28)
- [SRJ](#srj) (9)
- [Station](#station) (31)
- [Status](#status) (3)
- [Strip](#strip) (3)
- [TAS](#tas) (39)
- [Target](#target) (2)
- [Thermal](#thermal) (10)
- [Track](#track) (9)
- [Traits](#traits) (19)
- [Trough](#trough) (27)
- [Veh](#veh) (176)
- [Watch](#watch) (14)
- [Wheel](#wheel) (105)
- [Window](#window) (1)
- [WinMenu](#winmenu) (7)
- [Workshop](#workshop) (51)
- [World](#world) (19)
- [XR](#xr) (3)
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
| `UI_ZeD_Act_FoodChew` | `CHEWING` | Action bar (pixel face, capitals): the game's eat action on a food item whose own verb is Chew (gum) | 14 |
| `UI_ZeD_Act_FoodDrink` | `DRINKING` | Action bar (pixel face, capitals): the game's eat action on a food item whose own verb is Drink (a juice box, a can of pop) | 14 |
| `UI_ZeD_Act_FoodSmoke` | `SMOKING` | Action bar (pixel face, capitals): the game's eat action on a food item whose own verb is Smoke (a cigarette, a cigar) | 14 |
| `UI_ZeD_Act_FoodSniff` | `SNIFFING` | Action bar (pixel face, capitals): the game's eat action on a food item whose own verb is Sniff | 14 |
| `UI_ZeD_Act_FoodTake` | `TAKING` | Action bar (pixel face, capitals): the game's eat action on a food item whose own verb is Take | 14 |
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
| `UI_ZeD_Animals_AlertDefault` | `Alert` | Animals tab alert row: badge text for an alert with no specific label | 10 |
| `UI_ZeD_Animals_AlertOrphan` | `Orphan` | Animals tab alert row: badge when a baby has lost its mother | 10 |
| `UI_ZeD_Animals_AnimalCountMany` | `%1 animals` | Animals tab zone view, info band: how many animals are in the zone (none or several) | 14 |
| `UI_ZeD_Animals_AnimalCountOne` | `%1 animal` | Animals tab zone view, info band: how many animals are in the zone (exactly one) | 14 |
| `UI_ZeD_Animals_BadgeDoorOpen` | `Door open` | Animals tab hutch row: badge when the hutch door is open | 12 |
| `UI_ZeD_Animals_BadgeHatchOpen` | `Hatch open` | Animals tab hutch row: badge when the egg hatch door is open | 12 |
| `UI_ZeD_Animals_BadgeOnHook` | `On hook` | Animals tab butcher hook row: badge when an animal hangs on the hook | 12 |
| `UI_ZeD_Animals_BadgeShut` | `Shut` | Animals tab hutch row badge (the hutch is closed) and Vehicle tab trailer summary (the trunk lid is shut) | 10 |
| `UI_ZeD_Animals_BtnCreateZone` | `+ Create zone` | Animals tab ranch overview, footer: button that starts drawing a new livestock zone | 18 |
| `UI_ZeD_Animals_CountSpecies` | `%1 %2` | Animals tab zone card: one species in the breakdown line (%1 = how many, %2 = species name), e.g. "3 Cow" | 24 |
| `UI_ZeD_Animals_CreateZoneHint` | `Create an Animal zone to get started` | Animals tab ranch overview, footer: hint next to the Create zone button | 50 |
| `UI_ZeD_Animals_CreateZoneTitle` | `Create livestock zone` | Animals tab, zone drawing mode: heading band at the top | 32 |
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
| `UI_ZeD_Animals_Eggs` | `Eggs` | Animals tab animal view, Production: label of the eggs row | 10 |
| `UI_ZeD_Animals_EggsPerDay` | `eggs/day` | Animals tab ranch overview, Totals section: unit after the eggs figure | 12 |
| `UI_ZeD_Animals_EligibleCount` | `%1 eligible` | Animals tab butcher view, summary band: how many animals can be butchered | 20 |
| `UI_ZeD_Animals_EstMeat` | `\| ~%1 kg meat` | Animals tab butcher row, second line after the species: estimated meat yield (%1 = kg, one decimal) | 20 |
| `UI_ZeD_Animals_HdrBreeding` | `Breeding` | Animals tab animal view: section heading for pregnancy, mating and trust | 16 |
| `UI_ZeD_Animals_HdrGenetics` | `Genetics` | Animals tab animal view: section heading for genetic traits | 16 |
| `UI_ZeD_Animals_HdrProduction` | `Production` | Animals tab animal view: section heading for milk, wool and eggs | 16 |
| `UI_ZeD_Animals_HdrVitals` | `Vitals` | Animals tab animal view: section heading | 14 |
| `UI_ZeD_Animals_HookBlood` | `Blood %1 L` | Animals tab butcher hook row: blood still to collect in litres (one item of a list; %1 = litres) | 16 |
| `UI_ZeD_Animals_HookLeft` | `%1 left` | Animals tab butcher hook row, second line: what is still on the animal (%1 = the items above joined with " \| ") | 40 |
| `UI_ZeD_Animals_HookNothingLeft` | `Nothing left` | Animals tab butcher hook row, second line: the animal on the hook has been fully butchered | 16 |
| `UI_ZeD_Animals_HoursAgo` | `%1h ago` | Animals tab animal view, Last milked row: hours since (%1 = hours) | 12 |
| `UI_ZeD_Animals_HutchLine` | `%1 / %2 birds \| %3 eggs \| dirt %4` | Animals tab hutch row, second line (%1 birds inside, %2 capacity, %3 eggs, %4 dirtiness as a percentage with its % sign) | 50 |
| `UI_ZeD_Animals_InSeason` | `In season` | Animals tab animal view, Mating row: the animal is in its mating season | 14 |
| `UI_ZeD_Animals_LastMilked` | `Last milked` | Animals tab animal view, Production: label of the row that tells when the animal was last milked | 16 |
| `UI_ZeD_Animals_MalesBadge` | `%1 males` | Animals tab zone card: warning badge when 2 or more adult males of a species may fight (%1 = species name) | 24 |
| `UI_ZeD_Animals_Mating` | `Mating` | Animals tab animal view, Breeding: label of the mating season row | 12 |
| `UI_ZeD_Animals_MilkAmount` | `%1/%2 ml` | Animals tab animal view, Milk row: milk held against the most it can hold (%1 held, %2 maximum, in millilitres) | 18 |
| `UI_ZeD_Animals_MilkPerDay` | `milk/day` | Animals tab ranch overview, Totals section: unit after the milk figure | 12 |
| `UI_ZeD_Animals_NoEligible` | `No eligible animals` | Animals tab butcher view: empty-state line when no animal can be butchered | 40 |
| `UI_ZeD_Animals_NoEligibleHint` | `Adults only, excludes pregnant` | Animals tab butcher view: small line under the empty-state line | 50 |
| `UI_ZeD_Animals_NoZones` | `No livestock zones` | Animals tab, ranch overview: empty-state line under the zone icon | 32 |
| `UI_ZeD_Animals_OffSeason` | `Off season` | Animals tab animal view, Mating row: the animal is out of its mating season | 14 |
| `UI_ZeD_Animals_Overview` | `Overview` | Animals tab: breadcrumb text on the zone view (click to go back to the ranch overview) | 20 |
| `UI_ZeD_Animals_PerDay` | `%1/day` | Animals tab animal view, Eggs row: eggs per day (%1 = number with one decimal) | 12 |
| `UI_ZeD_Animals_Pregnancy` | `Pregnancy` | Animals tab animal view, Breeding: label of the pregnancy row | 14 |
| `UI_ZeD_Animals_PregnantPct` | `Pregnant - %1` | Animals tab animal view, Pregnancy bar: pregnancy progress (%1 = percentage with its % sign) | 24 |
| `UI_ZeD_Animals_ProdBone` | `Bone` | Animals tab butcher row: product badge, the animal gives bone | 10 |
| `UI_ZeD_Animals_ProdFeathers` | `Feathers` | Animals tab butcher row: product badge, the animal gives feathers | 10 |
| `UI_ZeD_Animals_ProdLeather` | `Leather` | Animals tab butcher row: product badge, the animal gives leather | 10 |
| `UI_ZeD_Animals_RemoveZonePrompt` | `Remove zone?` | Animals tab zone view, footer: confirmation prompt next to Yes / No | 24 |
| `UI_ZeD_Animals_Roof` | `Roof` | Animals tab zone card and zone info: label above the roofed-area bar | 8 |
| `UI_ZeD_Animals_Roster` | `Roster` | Animals tab butcher view: heading above the list of animals | 20 |
| `UI_ZeD_Animals_SecAlerts` | `Alerts` | Animals tab ranch overview: collapsible section heading (followed by the count) | 14 |
| `UI_ZeD_Animals_SecHooks` | `Hooks` | Animals tab butcher view: section heading above the nearby butcher hooks (followed by the count) | 14 |
| `UI_ZeD_Animals_SecHutches` | `Hutches` | Animals tab zone view: section heading above the zone's hutches (followed by the count) | 14 |
| `UI_ZeD_Animals_SecTotals` | `Totals` | Animals tab ranch overview: collapsible section heading (followed by the count) | 14 |
| `UI_ZeD_Animals_SecTroughs` | `Feeding Troughs` | Animals tab zone view: section heading above the zone's feeding troughs (followed by the count) | 24 |
| `UI_ZeD_Animals_SecZones` | `Zones` | Animals tab ranch overview: section heading (followed by the count) | 14 |
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
| `UI_ZeD_Animals_StructAnimalsMany` | `%1 animals` | Animals tab trough row, second line: animals linked to the trough (none or several) | 14 |
| `UI_ZeD_Animals_StructAnimalsOne` | `%1 animal` | Animals tab trough row, second line: animals linked to the trough (exactly one) | 14 |
| `UI_ZeD_Animals_SubRanch` | `Ranch` | Animals tab: first sub-tab (Ranch / Butcher strip) | 16 |
| `UI_ZeD_Animals_TagLaying` | `Laying` | Animals tab: badge on an animal that is laying eggs (animal row, header) | 12 |
| `UI_ZeD_Animals_TagMilkable` | `Milkable` | Animals tab: green badge on an animal that can be milked (animal row and header) | 14 |
| `UI_ZeD_Animals_TagUdderUrgent` | `Udder urgent` | Animals tab: red badge on an animal whose udder is over full (animal row and header) | 16 |
| `UI_ZeD_Animals_TagWoolReady` | `Wool ready` | Animals tab: green badge on an animal that can be sheared (animal row and header) | 14 |
| `UI_ZeD_Animals_ThirstDehydrated` | `Dehydrated` | Animals tab animal view, Thirst row: severe thirst | 14 |
| `UI_ZeD_Animals_ThirstHydrated` | `Hydrated` | Animals tab animal view, Thirst row: value when the animal is not thirsty (skill level too low for numbers) | 14 |
| `UI_ZeD_Animals_ThirstParched` | `Parched` | Animals tab animal view, Thirst row: mild thirst | 14 |
| `UI_ZeD_Animals_TilesMany` | `%1 tiles` | Animals tab hook row, second line: distance to the hook (none or several tiles) | 12 |
| `UI_ZeD_Animals_TilesOne` | `%1 tile` | Animals tab hook row, second line: distance to the hook (exactly one tile) | 12 |
| `UI_ZeD_Animals_TroughFeed` | `Feed %1` | Animals tab trough row, second line: amount of feed held (%1 = amount) | 20 |
| `UI_ZeD_Animals_TroughWater` | `Water %1 / %2 L` | Animals tab trough row, second line: water held against capacity in litres (%1 = held, %2 = capacity) | 24 |
| `UI_ZeD_Animals_Trust` | `Trust` | Animals tab animal view, Breeding: label of the row showing how much the animal trusts the player | 12 |
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
| `UI_ZeD_Animals_AnimalCheats` | `Animal cheats` | Animals tab, animal view, Genome section: tag at the right end of the heading, saying this panel is the cheat panel | 16 |
| `UI_ZeD_Animals_AnimalGone` | `That animal is no longer here.` | Animals tab, animal view: line shown when the animal that was open has left or died | - |
| `UI_ZeD_Animals_BtnCreate` | `Create` | Animals tab, zone creation: button in the band that asks "Create this zone?" | 12 |
| `UI_ZeD_Animals_BtnRemoveZone` | `Remove zone` | Animals tab, zone view: footer button that removes the zone | 14 |
| `UI_ZeD_Animals_CreateZoneAsk` | `Create this zone? %1 x %2 tiles.` | Animals tab, zone creation: the question in the band after the zone is drawn; %1 and %2 = the zone's width and height in tiles | - |
| `UI_ZeD_Animals_CreateZoneBtn` | `Create zone` | Animals tab, Ranch overview: the button that starts drawing a new zone | 14 |
| `UI_ZeD_Animals_GeneDisorder` | `Disorder` | Animals tab, animal view, Genome section (cheat panel): button that marks the picked allele as a disorder | 12 |
| `UI_ZeD_Animals_GeneDominant` | `Dominant` | Animals tab, animal view, Genome section (cheat panel): button that makes the picked allele dominant | 12 |
| `UI_ZeD_Animals_GeneSwitch` | `Switch` | Animals tab, animal view, Genome section (cheat panel): button that switches the picked allele | 12 |
| `UI_ZeD_Animals_Genome` | `Genome` | Animals tab, animal view: heading of the genome section (the cheat panel) | 14 |
| `UI_ZeD_Animals_HelpAnimalRow` | `Open this animal: how it is doing and what it needs` | Animals tab: help line over an animal's row | - |
| `UI_ZeD_Animals_HelpBackButcher` | `Back to the butcher list` | Animals tab, butcher view: help line over the Back button that returns to the butcher list | - |
| `UI_ZeD_Animals_HelpBackOverview` | `Back to the overview of your zones` | Animals tab, zone view: help line over the Back button that returns to the overview of zones | - |
| `UI_ZeD_Animals_HelpBackZone` | `Back to %1` | Animals tab, animal view: help line over the Back button; %1 = the zone's name | - |
| `UI_ZeD_Animals_HelpButcher` | `Butcher: which animals can be butchered and what they would give` | Animals tab: help line over the Butcher sub-tab | - |
| `UI_ZeD_Animals_HelpCreateZone` | `Create zone: draw a new livestock zone on the ground` | Animals tab, Ranch overview: help line over the Create zone button | - |
| `UI_ZeD_Animals_HelpFold` | `Fold or unfold this section` | Animals tab, overview: help line over the heading of a section that folds (alerts, totals) | - |
| `UI_ZeD_Animals_HelpRanch` | `Ranch: your livestock zones and the animals in them` | Animals tab: help line over the Ranch sub-tab | - |
| `UI_ZeD_Animals_HelpRemoveBtn` | `Remove zone: asks first, then takes this zone away` | Animals tab, zone view: help line over the Remove zone button | - |
| `UI_ZeD_Animals_HelpRemoveCancel` | `Do not remove the zone` | Animals tab, zone view: help line over the No button of the remove question | - |
| `UI_ZeD_Animals_HelpRemoveDo` | `Remove the zone; its animals stay where they are` | Animals tab, zone view: help line over the Yes button of the remove question | - |
| `UI_ZeD_Animals_HelpRename` | `Rename the zone: click to type a new name` | Animals tab, zone view: help line over the zone's name | - |
| `UI_ZeD_Animals_HelpRenameBtn` | `Rename: give this zone a new name` | Animals tab, zone view: help line over the Rename button | - |
| `UI_ZeD_Animals_HelpRenameCancel` | `Keep the old name` | Animals tab, zone view: help line over the Cancel button while the zone is being renamed | - |
| `UI_ZeD_Animals_HelpRenameReset` | `Put back the automatic name` | Animals tab, zone view: help line over the Reset button while the zone is being renamed | - |
| `UI_ZeD_Animals_HelpRenameSave` | `Save the new name` | Animals tab, zone view: help line over the Save button while the zone is being renamed | - |
| `UI_ZeD_Animals_HelpSort` | `Sort order: click to change how the animals are sorted` | Animals tab: help line over the sort button above the animal list | - |
| `UI_ZeD_Animals_HelpStruct` | `Open its card (you walk there first if it is out of reach)` | Animals tab: help line over a hutch, trough or other structure row | - |
| `UI_ZeD_Animals_HelpZoneCard` | `Open this zone: its animals, food and water` | Animals tab, Ranch overview: help line over a zone's card | - |
| `UI_ZeD_Animals_HelpZoneCreate` | `Create the zone you drew` | Animals tab, zone creation: help line over the Create button of the confirm band | - |
| `UI_ZeD_Animals_HelpZoneLeave` | `Stop drawing and leave zone creation` | Animals tab, zone creation: help line over the Cancel button while a zone is being drawn | - |
| `UI_ZeD_Animals_HelpZoneRedraw` | `Do not create this zone; draw it again` | Animals tab, zone creation: help line over the Cancel button of the confirm band | - |
| `UI_ZeD_Animals_NoEligibleYet` | `No animals can be butchered yet. Only adults that are not pregnant count.` | Animals tab, butcher view: line shown when no animal can be butchered | - |
| `UI_ZeD_Animals_NoZonesYet` | `No animal zones yet.` | Animals tab, Ranch overview: line shown when there is no zone | - |
| `UI_ZeD_Animals_RemoveZoneAsk` | `Remove the zone? Its animals stay where they are.` | Animals tab, zone view: the question in the band after Remove zone is pressed; the band then offers a yes and a no | - |

## Appliance

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Appliance_Empty` | `Empty` | Craft tab, oven or microwave: line when nothing is inside | 16 |
| `UI_ZeD_Appliance_InMicrowave` | `In the microwave` | Craft tab, microwave: section heading above the food inside | 28 |
| `UI_ZeD_Appliance_InOven` | `In the oven` | Craft tab, oven: section heading above the food inside | 28 |
| `UI_ZeD_Appliance_Left` | `%1 left` | Craft tab, microwave state line: time remaining (%1 is like 1:30) | 12 |
| `UI_ZeD_Appliance_MinLeft` | `%1 min left` | Craft tab, oven state line: minutes remaining | 14 |
| `UI_ZeD_Appliance_MinShort` | `%1m` | Craft tab, oven or microwave food row: minutes left, after the bar (short) | 6 |
| `UI_ZeD_Appliance_NoPower` | `No power` | Craft tab, oven or microwave: line under the plate when unpowered | 12 |
| `UI_ZeD_Appliance_PopIn` | `Bring it back` | Craft tab, oven or microwave in its own window: button that puts it back in the tab | 18 |
| `UI_ZeD_Appliance_PopOut` | `Open in its own window` | Craft tab, oven or microwave: hover hint of the icon button that opens it in a window of its own | 28 |
| `UI_ZeD_Appliance_PoppedOut` | `In its own window.` | Craft tab, oven or microwave: line shown in the tab while it is in its own window | 28 |
| `UI_ZeD_Appliance_PowerHi` | `Hi` | Craft tab, microwave state line: power level 5 of 5 | 8 |
| `UI_ZeD_Appliance_PowerLo` | `Lo` | Craft tab, microwave state line: power level 1 of 5 | 8 |
| `UI_ZeD_Appliance_PowerMed` | `Med` | Craft tab, microwave state line: power level 3 of 5 | 8 |
| `UI_ZeD_Appliance_PowerMedHi` | `Med-hi` | Craft tab, microwave state line: power level 4 of 5 | 8 |
| `UI_ZeD_Appliance_PowerMedLo` | `Med-lo` | Craft tab, microwave state line: power level 2 of 5 | 8 |
| `UI_ZeD_Appliance_Raw` | `Raw` | Craft tab, oven or microwave: tag on a raw food row | 10 |
| `UI_ZeD_Appliance_Set` | `%1 set` | Craft tab, microwave state line: time set while off (%1 is like 1:30) | 12 |
| `UI_ZeD_Appliance_SetHeat` | `Set %1` | Craft tab, oven state line: heat that is set while off (%1 is like 200Â°C) | 14 |
| `UI_ZeD_Appliance_TimerMin` | `Timer %1 min` | Craft tab, oven state line: timer set while off | 14 |
| `UI_ZeD_Appliance_EmptyOven` | `Nothing is in the oven.` | Craft tab, oven: line when nothing is inside | 32 |
| `UI_ZeD_Appliance_EmptyMicrowave` | `Nothing is in the microwave.` | Craft tab, microwave: line when nothing is inside | 32 |

## Belt

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Belt_BestLight` | `Best light: %1` | Belt HUD, controller list row for the best light; %1 = the light's name | 40 |
| `UI_ZeD_Belt_Both` | `Both` | Belt HUD, foot of the off hand when the main hand holds a two-handed item | 8 |
| `UI_ZeD_Belt_InBags` | `In your bags` | Belt HUD, header of the controller list of weapons and lights in the bags | 20 |
| `UI_ZeD_Belt_InHand` | `In hand` | Belt HUD, foot of a slot whose item is in a hand | 8 |
| `UI_ZeD_Belt_Replace` | `Replace %1` | Belt HUD, chip over a full slot while dragging an item onto it; %1 = the item now there | 40 |
| `UI_ZeD_Belt_SlotAnkle` | `Ankle` | Belt HUD, name printed inside an empty ankle holster slot box | 9 |
| `UI_ZeD_Belt_SlotBeltL` | `Belt L` | Belt HUD, name printed inside an empty hotbar slot box (waist belt, left) | 9 |
| `UI_ZeD_Belt_SlotBeltR` | `Belt R` | Belt HUD, name printed inside an empty hotbar slot box (waist belt, right) | 9 |
| `UI_ZeD_Belt_SlotHolster` | `Holster` | Belt HUD, name printed inside an empty holster slot box | 9 |
| `UI_ZeD_Belt_SlotHolsterL` | `Holster L` | Belt HUD, name printed inside an empty left holster slot box | 9 |
| `UI_ZeD_Belt_SlotKey` | `%1 \| key %2` | Belt HUD, chip above a hovered slot; %1 = the slot's name, %2 = the key bound to it | 40 |
| `UI_ZeD_Belt_SlotPack` | `Pack` | Belt HUD, name printed inside an empty bedroll / pack slot box | 9 |
| `UI_ZeD_Belt_SlotShoulder` | `Shoulder` | Belt HUD, name printed inside an empty shoulder holster slot box | 9 |
| `UI_ZeD_Belt_SlotWebL` | `Web L` | Belt HUD, name printed inside an empty webbing slot box (left) | 9 |
| `UI_ZeD_Belt_SlotWebR` | `Web R` | Belt HUD, name printed inside an empty webbing slot box (right) | 9 |
| `UI_ZeD_Belt_Tag` | `Belt %1` | Inventory lists, tag on an item attached to the belt; %1 = the slot's key (1 to 8) | 10 |
| `UI_ZeD_Belt_Watch` | `Watch` | Belt HUD, chip over the mini watch when the item has no name | 14 |
| `UI_ZeD_Belt_WatchFull` | `%1 \| Full watch` | Belt HUD, chip over the mini watch's face when the full watch is closed; %1 = watch name | 40 |
| `UI_ZeD_Belt_WatchLight` | `Light` | Belt HUD, chip over the mini watch's light button | 10 |
| `UI_ZeD_Belt_WatchSpeed` | `Speed \| %1x` | Belt HUD, chip over the mini watch's speed button; %1 = the game speed multiplier (1, 2, 3) | 14 |
| `UI_ZeD_Belt_WatchStart` | `Start` | Belt HUD, chip over the mini watch's start / pause button while the game is paused | 10 |
| `UI_ZeD_Belt_WatchTuck` | `%1 \| tuck away` | Belt HUD, chip over the mini watch's face when the full watch is open; %1 = watch name | 40 |
| `UI_ZeD_Belt_AmmoEmpty` | `Empty` | Belt HUD, ammo box beside the main hand: the gun holds no rounds (large figures) | 6 |
| `UI_ZeD_Belt_AmmoMags` | `%1 mag` | Belt HUD, ammo box: loaded magazines carried; %1 = how many | 8 |
| `UI_ZeD_Belt_AmmoRounds` | `%1 rds` | Belt HUD, ammo box: loose rounds carried; %1 = how many | 8 |
| `UI_ZeD_Belt_AmmoBoxes` | `+%1 box` | Belt HUD, ammo box: unopened ammo boxes carried (not counted as rounds); %1 = how many | 8 |
| `UI_ZeD_Belt_AmmoGunEmpty` | `%1 \| empty` | Belt HUD, the ammo chip's first line when the gun is empty; %1 = the gun's name | - |
| `UI_ZeD_Belt_AmmoInMag` | `%1 \| %2 in the magazine` | Belt HUD, the ammo chip's first line, a gun with a magazine; %1 = the gun's name, %2 = rounds | - |
| `UI_ZeD_Belt_AmmoInCyl` | `%1 \| %2 in the cylinder` | Belt HUD, the ammo chip's first line, a revolver; %1 = the gun's name, %2 = rounds | - |
| `UI_ZeD_Belt_AmmoLoaded` | `%1 \| %2 loaded` | Belt HUD, the ammo chip's first line, a shotgun or rifle loaded by hand; %1 = the gun's name, %2 = rounds | - |
| `UI_ZeD_Belt_AmmoChambered` | `%1, 1 chambered` | Belt HUD, the ammo chip's first line with a round in the chamber; %1 = the line before it | - |
| `UI_ZeD_Belt_AmmoCarried` | `Carried: %1` | Belt HUD, the ammo chip's second line; %1 = what is carried, joined by \| | - |
| `UI_ZeD_Belt_AmmoCarriedNone` | `Carried: no %1` | Belt HUD, the ammo chip's second line when nothing is carried; %1 = the rounds' name | - |
| `UI_ZeD_Belt_AmmoCountOf` | `%1 %2` | Belt HUD, the ammo chip: a count and an item's name (2 M9 Magazine, 34 9mm Rounds); %1 = count, %2 = name | - |

## Card

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Card_Any` | `Any` | Reading Facts: value of Level Range when a book has no level limits | 10 |
| `UI_ZeD_Card_ChipDispose` | `Dispose` | Item card, chip that marks an item as unwanted | 10 |
| `UI_ZeD_Card_ChipFav` | `Fav` | Item card, chip that marks an item favourite | 6 |
| `UI_ZeD_Card_ChipNoCraft` | `No-craft` | Item card, chip that keeps an item out of recipes | 10 |
| `UI_ZeD_Card_Combat` | `Combat` | Item card top stats (clothing): combat speed modifier row label | 10 |
| `UI_ZeD_Card_CondLossHit` | `Cond loss / hit` | Defense Facts: how much condition the garment loses per hit (wide card) | 20 |
| `UI_ZeD_Card_Cotton` | `Cotton` | Item card, clothing: fabric shown when the garment names none | 10 |
| `UI_ZeD_Card_CritPct` | `Critical %%` | Combat Facts: critical hit chance of a weapon | 22 |
| `UI_ZeD_Card_Fabric` | `Fabric` | Item card top stats (clothing): fabric row label | 10 |
| `UI_ZeD_Card_Facts` | `Facts` | Item card: title of a facts panel that names no title | 14 |
| `UI_ZeD_Card_FactsCombat` | `Combat Facts` | Item card (weapons): title of the combat panel | 22 |
| `UI_ZeD_Card_FactsContainer` | `Container Facts` | Item card (containers): title of the container panel | 22 |
| `UI_ZeD_Card_FactsDefense` | `Defense Facts` | Item card (clothing): title of the defense panel | 22 |
| `UI_ZeD_Card_FactsNutrition` | `Nutrition Facts` | Item card (food): title of the nutrition panel, styled like a nutrition label | 24 |
| `UI_ZeD_Card_FactsReading` | `Reading Facts` | Item card (books and magazines): title of the reading panel | 22 |
| `UI_ZeD_Card_FlagDenim` | `Denim` | Item card, clothing zones (wide card): flag column beside a zone's bar | 9 |
| `UI_ZeD_Card_FlagFabric` | `Fabric` | Item card, clothing zones (wide card): flag column beside a zone's bar | 9 |
| `UI_ZeD_Card_FlagLeather` | `Leather` | Item card, clothing zones (wide card): flag column beside a zone's bar | 9 |
| `UI_ZeD_Card_FlagTorn` | `Torn` | Item card, clothing zones (wide card): flag column beside a zone's bar | 9 |
| `UI_ZeD_Card_FlagWorn` | `Worn` | Item card, clothing zones (wide card): flag column beside a zone's bar | 9 |
| `UI_ZeD_Card_Happiness` | `Happiness` | Nutrition Facts: change to happiness from the food | 22 |
| `UI_ZeD_Card_HungerReduction` | `Hunger reduction` | Nutrition Facts: how much eating the food lowers hunger | 22 |
| `UI_ZeD_Card_Items` | `Items` | Item card: number of items inside a container (top stats row and the Container Facts panel) | 10 |
| `UI_ZeD_Card_Kind` | `Kind` | Item card top stats: the item's category row label | 10 |
| `UI_ZeD_Card_Knockback` | `Knockback` | Combat Facts: knockback power of a weapon | 22 |
| `UI_ZeD_Card_Level` | `Level` | Item card top stats (books): skill level range row label | 10 |
| `UI_ZeD_Card_LevelRange` | `Level range` | Reading Facts: the skill levels a book is useful for | 22 |
| `UI_ZeD_Card_Marked` | `Marked` | Item card, label before the three mark chips (Fav, No-craft, Dispose) | 10 |
| `UI_ZeD_Card_NeckProt` | `Neck protection` | Defense Facts: neck protection row label (wide card) | 20 |
| `UI_ZeD_Card_NeedWhetstone` | `Needs a whetstone or a file` | Note over the character's head when SHARPEN is pressed with no whetstone or file | 36 |
| `UI_ZeD_Card_NoWaterInReach` | `No water in reach` | Note over the character's head when WASH is pressed with no water within two tiles | 28 |
| `UI_ZeD_Card_OneInN` | `1-in-N degrade` | Defense Facts: sub-row, the chance one in N hits wears the garment (wide card) | 20 |
| `UI_ZeD_Card_Progress` | `Progress` | Item card: reading progress row label (top stats and the Reading Facts panel) | 12 |
| `UI_ZeD_Card_Raw` | `Raw` | Item card top stats (food): value of the Cooked row for a food that is dangerous uncooked | 10 |
| `UI_ZeD_Card_Reach` | `Reach` | Item card top stats (weapons): reach row label | 10 |
| `UI_ZeD_Card_Read` | `Read` | Reading Facts: row label, whether you have already read this book (value Yes or No) | 14 |
| `UI_ZeD_Card_Run` | `Run` | Item card top stats (clothing): run speed modifier row label | 10 |
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
| `UI_ZeD_Card_WeightReduce` | `Weight reduce` | Item card top stats (containers): weight reduction row label, narrow column | 10 |
| `UI_ZeD_Card_WeightReduction` | `Weight reduction` | Container Facts: how much a container lightens its contents | 22 |
| `UI_ZeD_Card_WetPct` | `Wet %1` | Item card, clothing: chip for a wet garment; %1 is the wetness with its percent sign, e.g. 40% | 12 |
| `UI_ZeD_Card_ZoneFoot` | `Foot` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_ZoneHand` | `Hand` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_ZoneLeft` | `Left` | Item card, clothing zones: the side word before a zone's bar (Left arm, Left thigh...) | 6 |
| `UI_ZeD_Card_ZoneLower` | `Lower` | Item card, clothing zones: the torso row 'Lower' under the TORSO heading | 6 |
| `UI_ZeD_Card_ZoneLowerArm` | `Lower arm` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_ZoneOther` | `Other` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_ZoneRight` | `Right` | Item card, clothing zones: the side word before a zone's bar (Right arm, Right thigh...) | 6 |
| `UI_ZeD_Card_Zones` | `Zones` | Item card, clothing: heading of the zones section | 8 |
| `UI_ZeD_Card_ZoneShin` | `Shin` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_ZoneThigh` | `Thigh` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_ZoneTorso` | `Torso` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_ZoneUpper` | `Upper` | Item card, clothing zones: the torso row 'Upper' under the TORSO heading | 6 |
| `UI_ZeD_Card_ZoneUpperArm` | `Upper arm` | Item card, clothing zones: group heading over the zone rows | 12 |
| `UI_ZeD_Card_NeedsSewing` | `a needle, thread and fabric strips` | Item card (clothing): what Repair holes and Pad need, in lower case, filling %1 of "With %1 you could %2" in the folded hidden-actions row, and %2 of "%1 needs %2" | - |
| `UI_ZeD_Card_HintRepairHoles` | `repair its holes` | Item card (clothing): what the Repair holes action does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Card_HintPad` | `pad it` | Item card (clothing): what the Pad action does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Card_NeedsWater` | `water within reach` | Item card: what Wash needs, in lower case, filling %1 of "With %1 you could %2" in the folded hidden-actions row, and %2 of "%1 needs %2" | - |
| `UI_ZeD_Card_HintWash` | `wash it` | Item card: what the Wash action does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Card_NeedsFixer` | `a repair item in your bags` | Item card: what Repair needs, in lower case, filling %1 of "With %1 you could %2" in the folded hidden-actions row, and %2 of "%1 needs %2" | - |
| `UI_ZeD_Card_HintRepair` | `repair it` | Item card: what the Repair action does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Card_NeedsWhetstone` | `a whetstone or a file in your bags` | Item card (blade): what Sharpen needs, in lower case, filling %1 of "With %1 you could %2" in the folded hidden-actions row, and %2 of "%1 needs %2" | - |
| `UI_ZeD_Card_HintSharpen` | `sharpen it` | Item card (blade): what the Sharpen action does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Card_HelpEquip` | `%1: put it on, or in your hands` | Item card: help line over the Equip button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpUnequip` | `%1: take it off, or out of your hands` | Item card: help line over the Unequip button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpDrop` | `%1: put it on the floor` | Item card: help line over the Drop button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpTake` | `%1: put it in your inventory` | Item card: help line over the Take button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpEat` | `%1: all of it` | Item card (food): help line over the Eat button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpRead` | `%1: read it now` | Item card: help line over the Read button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpUse` | `%1: use it, as a double-click does` | Item card: help line over the Use button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpDrink` | `%1: drink from it` | Item card: help line over the Drink button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpWear` | `%1: put it on` | Item card: help line over the Wear button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpOffHand` | `%1: put it in your other hand` | Item card: help line over the Off hand button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpMore` | `%1: everything else you can do with it` | Item card: help line over the More button, which opens the rest of the item's actions; %1 = the button's label | - |
| `UI_ZeD_Card_HelpWash` | `%1: wash it at the water nearby` | Item card: help line over the Wash button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpRepairHoles` | `%1: sew up its holes` | Item card (clothing): help line over the Repair holes button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpPad` | `%1: sew padding onto it` | Item card (clothing): help line over the Pad button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpRepair` | `%1: repair it with what you carry` | Item card: help line over the Repair button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpSharpen` | `%1: sharpen its edge` | Item card (blade): help line over the Sharpen button; %1 = the button's label | - |
| `UI_ZeD_Card_HelpRename` | `Rename: press to give it a name of your own` | Item card: help line over the item's name row, which a press turns into a name field | - |
| `UI_ZeD_Card_HelpDockRepair` | `Repair this part's hole` | Item card (clothing): help line over a part's cell in the patch dock when its button repairs the hole | - |
| `UI_ZeD_Card_HelpDockPatch` | `Take this part's patch off` | Item card (clothing): help line over a part's cell in the patch dock when its button takes the patch off | - |
| `UI_ZeD_Card_HelpBack` | `Back: close this card` | Item card: help line over the Back button that closes the card | - |

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
| `UI_ZeD_Char_SortDist` | `Dist` | Character window, container strip (narrow vertical bar of container buttons): label of the sort button under the active container; clicking cycles the three - sort by distance (the strip is about 36 px wide) | 5 |
| `UI_ZeD_Char_SortType` | `Type` | Character window, container strip (narrow vertical bar of container buttons): label of the sort button under the active container; clicking cycles the three - sort by type | 5 |
| `UI_ZeD_Char_SortWt` | `Wt` | Character window, container strip (narrow vertical bar of container buttons): label of the sort button under the active container; clicking cycles the three - sort by weight | 5 |
| `UI_ZeD_Char_TabEquipment` | `Equipment` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') | 14 |
| `UI_ZeD_Char_TabIdentity` | `Identity` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab'); also the pinned heading of the Identity drawer | 14 |
| `UI_ZeD_Char_TabJournal` | `Journal` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') | 14 |
| `UI_ZeD_Char_TabLoot` | `Loot` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') (the inventory and the containers around) | 14 |
| `UI_ZeD_Char_TabRadio` | `Radio` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab') (only shown while the character has a radio) | 14 |
| `UI_ZeD_Char_TabThermal` | `Thermal` | Character window: tab name - appended to the window title while the tab's drawer is open ('Name  +  Tab'); also the pinned heading of the Thermal drawer | 14 |
| `UI_ZeD_Char_WeightOfMax` | `%1/%2kg` | Character window, Loot tab: column header, weight carried over capacity, small text above the item count; %1 is the weight (one decimal), %2 the capacity | 16 |
| `UI_ZeD_Char_Window` | `Character` | Character window: the title the window is created with, before it shows the character's name (barely seen) | 20 |
| `UI_ZeD_Chord_BestPick` | `best pick` | ZeD setup, Quick actions: in the list of actions, after a slice that opens a list ("Eat: best pick"): the chord does the list's first pick at once | 20 |
| `UI_ZeD_Chord_Gone` | `No %1 on you.` | Quick action chords (a bumper held with A, B, X, Y, L3 or R3): over the character's head when the chord's thing is not carried any more; %1 = its name ("Canned Corn") | - |
| `UI_ZeD_Chord_Help` | `Hold %1 and press %2 in the world: %3.` | ZeD setup, Quick actions: the help band for a chord; %1 = the bumper's name on this pad ("L1"), %2 = the button's ("Square"), %3 = the action and where it lives ("Character > Eat") | - |
| `UI_ZeD_Chord_HelpNone` | `Hold %1 and press %2 in the world: nothing. Choose an action for it.` | ZeD setup, Quick actions: the help band for a chord with no action; %1 = the bumper, %2 = the button | - |
| `UI_ZeD_Chord_LoadGame` | `Load a game to choose from the wheels.` | ZeD setup at the main menu, Quick actions: in the list of actions (the wheels need a character) | 50 |
| `UI_ZeD_Chord_None` | `None` | ZeD setup, Quick actions: a chord with no action, and the list's first item (clears it) | 16 |
| `UI_ZeD_Chord_NotHere` | `This wheel is the game's: put the slice that opens it on a chord.` | D-pad wheels: the bubble, after holding a bumper and pressing a button on a slice of a wheel the game fills (Vehicle, Animal, a gesture group) | 70 |
| `UI_ZeD_Chord_NotOnZeD` | `The ZeD wheel's settings can't go on a chord.` | The ZeD wheel (Select): the bubble, after holding a bumper and pressing a button on one of its slices (they can't go on a quick action chord) | 50 |
| `UI_ZeD_Chord_NowOn` | `Now on %1.` | D-pad wheels: the bubble, after a slice was put on a quick action chord; %1 = the chord in the pad's names ("L1 + Square") | 40 |
| `UI_ZeD_Chord_OpensWheel` | `opens its wheel` | ZeD setup, Quick actions: in the list of actions, after a slice the game fills (Vehicle, Animal, a gesture group): the chord opens that wheel | 24 |
| `UI_ZeD_Chord_PromptClear` | `Remove` | ZeD setup, Quick actions: the controller prompt for X on a chord row | 12 |
| `UI_ZeD_Chord_Replaces` | `It replaces %1.` | D-pad wheels: after UI_ZeD_Chord_NowOn, when that chord held another action; %1 = that action's name | 40 |

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
| `UI_ZeD_Craft_AltOther` | `Other compatible` | Craft and Build tabs, alternatives list: heading above items you do not carry | 24 |
| `UI_ZeD_Craft_AltOwned` | `Owned` | Craft and Build tabs, alternatives list: heading above items you carry | 20 |
| `UI_ZeD_Craft_BadgeKnown` | `Known` | Recipe card: badge when you know the recipe | 10 |
| `UI_ZeD_Craft_BadgeNeeds` | `Needs %1` | Craft tab, recipe card: badge naming the station a recipe needs; %1 is a short station name like KILN | 16 |
| `UI_ZeD_Craft_BadgeUnknown` | `Unknown` | Recipe card: badge when you do not know the recipe | 10 |
| `UI_ZeD_Craft_Compatible` | `Compatible` | Craft and Build tabs: fixed label in the category box while choosing an alternative ingredient | 18 |
| `UI_ZeD_Craft_FilterAlts` | `Filter alternatives...` | Craft and Build tabs: search box placeholder while choosing an alternative ingredient | - |
| `UI_ZeD_Craft_FindRecipe` | `Find recipe magazine or schematic` | Journal recipe card: hint for a recipe that must be learned from a magazine | - |
| `UI_ZeD_Craft_HowToLearn` | `How to learn` | Journal recipe card: section heading above skill requirements | 20 |
| `UI_ZeD_Craft_Known` | `Known` | Craft, Build and Journal tabs: sort button, and the Show toggle value (recipes you know) | 10 |
| `UI_ZeD_Craft_NoAlts` | `No alternatives found` | Craft and Build tabs, alternatives list: empty state | - |
| `UI_ZeD_Craft_NoneWithin` | `None within %1 tiles.` | Craft tab, recipe card: second line when no needed station is near | - |
| `UI_ZeD_Craft_Pinned` | `Pinned` | Craft and Build tabs: section heading above pinned recipes | 20 |
| `UI_ZeD_Craft_Required` | `Required` | Recipe card: section heading above the ingredients | 20 |
| `UI_ZeD_Craft_Results` | `Results` | Craft, Build and Journal tabs: section heading above search results | 20 |
| `UI_ZeD_Craft_ShowAll` | `All` | Craft, Build and Journal tabs: value in the Show toggle (every recipe) | 8 |
| `UI_ZeD_Craft_ShowReady` | `Ready` | Craft and Build tabs: value in the Show toggle (recipes you can make now) | 8 |
| `UI_ZeD_Craft_ShowToggle` | `Show: %1` | Craft, Build and Journal tabs: the button that cycles which recipes are listed; %1 is Ready, Known or All | 16 |
| `UI_ZeD_Craft_SkillLevel` | `%1 Level %2` | Journal recipe card: a skill requirement, e.g. Carpentry Level 3 | - |
| `UI_ZeD_Craft_SortCraftable` | `Craftable` | Craft, Build and Journal tabs: sort button | 12 |
| `UI_ZeD_Craft_SortFreq` | `Freq` | Craft and Build tabs: sort button (most used recipes) | 8 |
| `UI_ZeD_Craft_SortName` | `Name` | Craft, Build and Journal tabs: sort button | 8 |
| `UI_ZeD_Craft_SortRecent` | `Recent` | Craft and Build tabs: sort button (recently made recipes) | 10 |
| `UI_ZeD_Craft_TagFuel` | `Fuel` | Craft tab, recipe card: small tag on a fuel ingredient | 6 |
| `UI_ZeD_Craft_TimeMinSec` | `%1m%2s` | Recipe card: badge with the time a craft takes (minutes and seconds) | 10 |
| `UI_ZeD_Craft_TimeSec` | `%1s` | Recipe card: badge with the time a craft takes (seconds) | 8 |
| `UI_ZeD_Craft_UseStation` | `Use %1` | Craft tab, recipe card: button that binds the nearby station; %1 is the station name in lower case | 24 |
| `UI_ZeD_Craft_CategoryHelp` | `Category: press to choose which recipes the list shows` | Craft tab: help line over the category choice above the recipe list | - |

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
| `UI_ZeD_Curtain_TabHelp` | `%1, %2 items: press to roll it down, or drop things on it` | Character and World windows: help line over the tab of a rolled-up inventory side; %1 = its name, %2 = how many items (2 or more) | - |
| `UI_ZeD_Curtain_TabHelpOne` | `%1, 1 item: press to roll it down, or drop things on it` | Character and World windows: help line over the tab of a rolled-up inventory side that holds exactly one item; %1 = its name | - |
| `UI_ZeD_Curtain_RollHelp` | `Roll this side up under its rod: the drawer stays open` | Character and World windows: help line over the small roll button in the title bar that rolls the inventory side up | - |

## CW

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_CW_TabHelp` | `%1: press to show it in the drawer` | Character window: help line over a tab name; %1 = the tab's name | - |
| `UI_ZeD_CW_MainHelp` | `%1: press to show it` | Character window: help line over the main container (what you carry) in the container strip; %1 = its name | - |
| `UI_ZeD_CW_BagHelp` | `%1: press to show it, or drag it up or down the strip` | Character window: help line over a bag or other container in the container strip; %1 = its name | - |
| `UI_ZeD_CW_SortHelp` | `The order of the bags below: press for the next order` | Character window: help line over the button that changes the order of the bags in the container strip | - |

## Dash

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Dash_AshClose` | `Close ash tray` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face): the car's ash tray, open now | 16 |
| `UI_ZeD_Dash_AshOpen` | `Open ash tray` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face): the car's ash tray, shut now | 16 |
| `UI_ZeD_Dash_ClimateAc` | `A/C` | Dashboard climate readout (pixel face): air conditioning on | 5 |
| `UI_ZeD_Dash_ClimateAuto` | `AUTO` | Dashboard climate readout (pixel face): heater on without A/C | 5 |
| `UI_ZeD_Dash_ClimateFan` | `FAN%1` | Dashboard climate readout (pixel face): fan speed; %1 = the speed (0 to 4), no space | 6 |
| `UI_ZeD_Dash_ClimateOff` | `OFF` | Dashboard climate readout (pixel face): climate off | 5 |
| `UI_ZeD_Dash_HintAb` | `A %1  B %2` | Dashboard top edge (pixel face, controller only): A and B actions of the focused control; %1 = A action, %2 = B action | 46 |
| `UI_ZeD_Dash_HintAxb` | `A %1  X %2  B %3` | Dashboard top edge (pixel face, controller only): A, X and B actions of the focused control; %1 = A action, %2 = X action, %3 = B action | 46 |
| `UI_ZeD_Dash_HintWheel` | `D-pad Right: Vehicle / Dashboard` | Dashboard top edge (pixel face, controller only), driver's seat, while the dash does not have the controller: where to give it the controller (the World wheel, its Vehicle slice, then Dashboard). The pixel face has only A-Z, 0-9 and . ' - / + % : (no comma) | 46 |
| `UI_ZeD_Dash_MeterOff` | `Meter off` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face): the taxi's fare meter, running now (puts its flag up) | 16 |
| `UI_ZeD_Dash_MeterOn` | `Meter on` | Dashboard controller prompt: what the A or X button does on the focused control (also shown on the dash's top edge, pixel face): the taxi's fare meter, stopped now (pulls its flag down) | 16 |
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
| `UI_ZeD_Dash_LampCond` | `condition %1` | Dashboard, the chip above a warning lamp: the part's condition; %1 = a percentage | - |
| `UI_ZeD_Dash_LampCharge` | `charge %1` | Dashboard, the chip above the battery lamp: the battery's charge; %1 = a percentage | - |
| `UI_ZeD_Dash_LampLeft` | `left %1` | Dashboard, the chip above the headlight lamp: the left headlight's condition; %1 = a percentage or Missing | - |
| `UI_ZeD_Dash_LampRight` | `right %1` | Dashboard, the chip above the headlight lamp: the right headlight's condition; %1 = a percentage or Missing | - |
| `UI_ZeD_Dash_LampCondLine` | `Condition %1` | Dashboard, the hover card of a warning lamp: a line under the part's name giving its condition; %1 = a percentage | - |
| `UI_ZeD_Dash_LampChargeLine` | `Charge %1` | Dashboard, the hover card of the battery lamp: a line under the battery's condition giving its charge; %1 = a percentage | - |
| `UI_ZeD_Dash_LampLeftLine` | `Left %1` | Dashboard, the hover card of the headlight lamp: the left headlight's condition; %1 = a percentage or Missing | - |
| `UI_ZeD_Dash_LampRightLine` | `Right %1` | Dashboard, the hover card of the headlight lamp: the right headlight's condition; %1 = a percentage or Missing | - |

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
| `UI_ZeD_DescEdit_AddBlock` | `Add a block` | Description editor: heading over the palette of block types (small caps heading) | 14 |
| `UI_ZeD_DescEdit_AddSection` | `Add a section` | Description editor: heading over the list of ready-made sections (small caps heading) | 16 |
| `UI_ZeD_DescEdit_AskKeep` | `Keep the changes to the description?` | Description editor: question in the action strip when leaving with changes | - |
| `UI_ZeD_DescEdit_Count` | `%1 of %2 characters` | Description editor: action strip: how much of Steam's limit is used. %1 characters now, %2 the limit (both with thousands commas) | - |
| `UI_ZeD_DescEdit_CountOver` | `%1 of %2 characters: too long for Steam` | Description editor: action strip: same, when over the limit | - |
| `UI_ZeD_DescEdit_DefaultTitle` | `Your mod` | Description editor: the heading a brand-new description starts with when the mod has no name yet | - |
| `UI_ZeD_DescEdit_Discard` | `Discard changes` | Description editor: button that drops the changes to the description | 12 |
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
| `UI_ZeD_DescEdit_KindCode` | `Code` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindDivider` | `Divider` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindHeading` | `Heading` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindLink` | `Link` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindList` | `List` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindNumbered` | `Numbered list` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindPicture` | `Picture` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindQuote` | `Quote` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindSpoiler` | `Spoiler` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindTable` | `Table` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_KindText` | `Text` | Description editor: small caps label at the left of a block's card, naming its type | 16 |
| `UI_ZeD_DescEdit_MarkBold` | `B` | Description editor: small button that puts bold codes at the cursor (one letter) | 2 |
| `UI_ZeD_DescEdit_MarkItalic` | `I` | Description editor: small button that puts italic codes at the cursor (one letter) | 2 |
| `UI_ZeD_DescEdit_MarkLink` | `Link` | Description editor: small button on a picked text block that puts a link code at the cursor | 6 |
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
| `UI_ZeD_DescEdit_HintLevel` | `Heading level %1` | Description editor: hover hint of a heading-level button (H1, H2, H3); %1 = the level, 1 to 3 | - |

## Desktop

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Desktop_EmptyTrash` | `Empty trash` | Trash window: button that empties the trash (asks to quit the game) | 16 |
| `UI_ZeD_Desktop_FileKind` | `the whole system` | Trash window: the kind of the one file in it (the Computer), under its name | 20 |
| `UI_ZeD_Desktop_FileName` | `Computer` | Trash window: the name of the one file in it, the computer itself (the old joke of throwing the computer in the trash) | 20 |
| `UI_ZeD_Desktop_ModUploader` | `Mod Uploader` | Desktop: name under the Workshop icon (opens the Workshop window, where you upload your own mods); a program's name, so title case | 14 |
| `UI_ZeD_Desktop_OneItem` | `1 item` | Trash window: count in the title bar | 10 |
| `UI_ZeD_Desktop_PromptDpad` | `D-pad Move` | Desktop: controller legend along the foot of the screen (the word D-PAD names the controller's cross) | - |
| `UI_ZeD_Desktop_Trash` | `Trash` | Desktop: name under the trash icon; title of the trash window | 14 |

## Disclose

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Disclose_Needs` | `%1 needs %2.` | Any action list (item card, object card): the line under a grayed action that says what it needs; %1 = the action's name, %2 = what is missing | - |
| `UI_ZeD_Disclose_One` | `With %1 you could %2.` | Any action list with Hidden actions on Folded: the folded row when one action is out of reach; %1 = what is needed ("scissors"), %2 = the action ("cut your hair") | - |
| `UI_ZeD_Disclose_Many` | `%1 more with the right things` | Any action list with Hidden actions on Folded: the folded row when several actions are out of reach; %1 = how many | - |

## Doll

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Doll_Arms` | `Arms` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the right-column slot box (one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_BeltSlot` | `Belt %1` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under a belt slot box; %1 is its hotbar key number | 8 |
| `UI_ZeD_Doll_EmptyHint` | `Empty: %1` | Equipment tab, Doll view (the character photo with slot boxes either side): hover hint over an empty belt slot; %1 is the slot's name | - |
| `UI_ZeD_Doll_Eyes` | `Eyes` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Feet` | `Feet` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the right-column slot box (one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Hands` | `Hands` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Innermost` | `Innermost` | Equipment tab, item card of a worn item with layers: strip under the card: %3 of the layer line when the last layer is shown | 14 |
| `UI_ZeD_Doll_LayerStrip` | `Layer %1 of %2 \| %3` | Equipment tab, item card of a worn item with layers: strip under the card; %1 the layer shown, %2 how many, %3 is Outermost / Innermost / Under N | 40 |
| `UI_ZeD_Doll_Main` | `Main` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the main-hand box in the row below the photo | 7 |
| `UI_ZeD_Doll_Off` | `Off` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the off-hand box in the row below the photo | 7 |
| `UI_ZeD_Doll_Outer` | `Outer` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Outermost` | `Outermost` | Equipment tab, item card of a worn item with layers: strip under the card: %3 of the layer line when the first layer is shown | 14 |
| `UI_ZeD_Doll_StepInner` | `Inner` | Equipment tab, item card of a worn item with layers: strip under the card: button that steps to the next layer inwards (sentence case) | 10 |
| `UI_ZeD_Doll_StepOuter` | `Outer` | Equipment tab, item card of a worn item with layers: strip under the card: button that steps to the next layer outwards (sentence case) | 10 |
| `UI_ZeD_Doll_Torso` | `Torso` | Equipment tab, Doll view (the character photo with slot boxes either side): caption under the left-column slot box (one box wide, about 76 px) | 7 |
| `UI_ZeD_Doll_Under` | `%1 (+%2 under)` | Equipment tab, Doll view (the character photo with slot boxes either side): hover hint over a slot with several layers; %1 is the outermost item's name, %2 how many layers lie under it | - |
| `UI_ZeD_Doll_UnderN` | `Under %1` | Equipment tab, item card of a worn item with layers: strip under the card: %3 of the layer line for a middle layer; %1 is how many layers lie above it | 14 |
| `UI_ZeD_Doll_ViewDoll` | `Doll` | Equipment tab heading, List \| Doll toggle buttons: hover hint of the doll button (icon-only button) | 10 |
| `UI_ZeD_Doll_ViewList` | `List` | Equipment tab heading, List \| Doll toggle buttons: hover hint of the list button (icon-only button) | 10 |
| `UI_ZeD_Doll_SlotHelp` | `%1: press for its card` | Equipment tab: help line over a worn or carried item on the doll or in the list; %1 = the item's name | - |
| `UI_ZeD_Doll_EmptyHelp` | `%1: empty` | Equipment tab: help line over an empty slot; %1 = the slot's name | - |
| `UI_ZeD_Doll_ListHelp` | `List: what you wear and carry, as rows` | Equipment tab: help line over the List button of the List \| Doll toggle | - |
| `UI_ZeD_Doll_DollHelp` | `Doll: what you wear, on your figure` | Equipment tab: help line over the Doll button of the List \| Doll toggle | - |

## Drawer

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Drawer_Prev` | `Previous one` | Radio tab: hover hint of the left arrow on the strip that steps to the previous radio (icon-only button) | - |
| `UI_ZeD_Drawer_Next` | `Next one` | Radio tab: hover hint of the right arrow on the strip that steps to the next radio (icon-only button) | - |

## Equip

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Equip_Arms` | `Arms` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_AvgBite` | `%1 avg bite defense` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): line under OVERALL GRADE; %1 is a percentage such as 25% | 30 |
| `UI_ZeD_Equip_BackBag` | `Back/bag` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_BeltAlways` | `Always there` | Equipment tab (Character window), list view: under a belt slot's name when no worn item is needed for the slot | 20 |
| `UI_ZeD_Equip_BeltFrom` | `From the %1` | Equipment tab (Character window), list view: under a belt slot's name; %1 is the worn item that gives the slot (a belt, a holster...) | 40 |
| `UI_ZeD_Equip_BeltHeadLeft` | `The belt \| keys` | Equipment tab (Character window), list view: belt sub-header, left side (' \| ' is ZeD's separator). The keys are the hotbar keys 1-8 | 24 |
| `UI_ZeD_Equip_BeltHeadRight` | `Slot \| what gives it` | Equipment tab (Character window), list view: belt sub-header, right side: slot name, then the worn item that provides the slot | 28 |
| `UI_ZeD_Equip_BestZone` | `Best zone` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): stat label above the most protected body part | 14 |
| `UI_ZeD_Equip_ColBullet` | `Bul` | Equipment tab (Character window), list view: column head above the slot rows (fixed narrow column) - bullet protection | 4 |
| `UI_ZeD_Equip_ColCond` | `Cond` | Equipment tab (Character window), list view: column head above the slot rows (fixed narrow column) - condition bar | 6 |
| `UI_ZeD_Equip_ColScratch` | `Scr` | Equipment tab (Character window), list view: column head above the slot rows (fixed narrow column) - scratch protection | 4 |
| `UI_ZeD_Equip_ColSlot` | `Slot` | Equipment tab (Character window), list view: column head above the slot rows (fixed narrow column) - slot the item is worn in | 8 |
| `UI_ZeD_Equip_ColWeight` | `Wt` | Equipment tab (Character window), list view: column head above the slot rows (fixed narrow column) - weight | 4 |
| `UI_ZeD_Equip_Defense` | `Defense` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): section heading (only used by the legacy header path) | 14 |
| `UI_ZeD_Equip_Detach` | `Detach` | Equipment tab (Character window), list view: button on a belt slot row holding an item (shown in sentence case) | 12 |
| `UI_ZeD_Equip_Empty` | `Empty` | Equipment tab (Character window), list view: belt slot row with nothing attached, in place of the item name | 12 |
| `UI_ZeD_Equip_Equipped` | `Equipped` | Equipment tab (Character window), list view: pinned heading of the tab (disclosure strip over the slot list) | 14 |
| `UI_ZeD_Equip_Eyewear` | `Eyewear` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_Garments` | `Garments` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): stat label above the worn garment count | 14 |
| `UI_ZeD_Equip_GarmentsEquipped` | `%1 equipped` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): value under Garments; %1 is how many garments are worn | 14 |
| `UI_ZeD_Equip_GroupArms` | `Arms + hands` | Equipment tab (Character window), list view: collapsible group header strip, followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupHead` | `Head + face` | Equipment tab (Character window), list view: collapsible group header strip, followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupHeld` | `Held + belt` | Equipment tab (Character window), list view: collapsible group header strip, followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupLegs` | `Legs + feet` | Equipment tab (Character window), list view: collapsible group header strip, followed by the count in brackets | 20 |
| `UI_ZeD_Equip_GroupTorso` | `Torso` | Equipment tab (Character window), list view: collapsible group header strip, followed by the count in brackets | 20 |
| `UI_ZeD_Equip_InHand` | `In hand` | Equipment tab (Character window), list view: small outlined tag on a belt slot row whose item is in the hands | 10 |
| `UI_ZeD_Equip_Inner` | `Inner` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_KneeLeg` | `Knee/leg` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_LayerMany` | `%1 layers` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): hover detail for a body part; %1 layers of clothing cover it (plural; 0 and 2 or more) | 12 |
| `UI_ZeD_Equip_LayerOne` | `%1 layer` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): hover detail for a body part, after the Bite/Scratch/Bullet bars; one layer of clothing covers it | 12 |
| `UI_ZeD_Equip_Outer` | `Outer` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_OverallGrade` | `Overall grade` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): small caps label beside the big letter grade box | 16 |
| `UI_ZeD_Equip_PutBack` | `Put back` | Equipment tab (Character window), list view: button on a belt slot row whose item is in hand (shown in sentence case) | 12 |
| `UI_ZeD_Equip_Ring` | `Ring` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_Shoulder` | `Shoulder` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_WorstZone` | `Worst zone` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): stat label above the least protected body part | 14 |
| `UI_ZeD_Equip_Wrist` | `Wrist` | Equipment tab (Character window), list view: SLOT column text on a slot row (narrow column, one short word) | 10 |
| `UI_ZeD_Equip_ZonePct` | `%1 (%2)` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): value under Worst/Best Zone; %1 is a body part name, %2 its bite protection as a percentage | 36 |
| `UI_ZeD_Equip_ZoneUncovered` | `%1 (uncovered)` | Equipment tab (Character window), list view, Defense body (figure + stats, bottom of the tab): value under Worst Zone when that part has no protection; %1 is a body part name | 36 |
| `UI_ZeD_Equip_BeltRowHelp` | `%1 on the belt: %2 is the button at the right` | Equipment tab, list view: help line over a belt slot row; %1 = the item's name (or Empty), %2 = the label of the row's button | - |

## Farm

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Farm_ConfirmClear` | `Clear the %1?` | Farm plot card: confirmation in the footer for a dead or empty plot; %1 is the plot's name in lower case | - |
| `UI_ZeD_Farm_ConfirmDig` | `Dig up the %1? The crop is lost.` | Farm plot card: confirmation in the footer; %1 is the crop's name in lower case | - |
| `UI_ZeD_Farm_DigUp` | `Dig up` | Farm plot card: verb button (danger) | 10 |
| `UI_ZeD_Farm_Fertilize` | `Fertilize` | Farm plot card: verb button | 12 |
| `UI_ZeD_Farm_Garden` | `Garden in reach` | Farm plot card: section heading over the grid of nearby plots | - |
| `UI_ZeD_Farm_GardenPlowed` | `Plowed` | Farm plot card: cell of the garden grid for plowed land (cell about 6 letters wide) | 6 |
| `UI_ZeD_Farm_LockTag` | `Farming %1` | Farm plot card: tag on a reading that needs Farming skill level %1 (bordered tag) | 14 |
| `UI_ZeD_Farm_NeedSeeds` | `Sow: needs seeds` | Farm plot card: the NEEDS line under the verbs when the plot is plowed and you carry no seeds | - |
| `UI_ZeD_Farm_NeedShovel` | `Dig up: needs a shovel or trowel` | Farm plot card: the NEEDS line under the verbs | - |
| `UI_ZeD_Farm_NeedSpray` | `Treat: needs %1` | Farm plot card: the NEEDS line when a pest shows and you carry no spray; %1 is the spray's item name | - |
| `UI_ZeD_Farm_NeedWater` | `Water: needs water in your hands or inventory` | Farm plot card: the NEEDS line under the verbs | - |
| `UI_ZeD_Farm_NextIn` | `in %1` | Farm plot card: value of NEXT STAGE; %1 is the game's own time phrase in lower case, e.g. 'in 2 days, 3 hours' | 20 |
| `UI_ZeD_Farm_NextStage` | `Next stage` | Farm plot card: label of the next-stage line | 14 |
| `UI_ZeD_Farm_Pests` | `Pests and disease` | Farm plot card: section heading over the pest rows | - |
| `UI_ZeD_Farm_PhaseAlmostReady` | `Almost ready` | Farm plot card: growth phase on the six-cell strip (cell about 9 letters wide); Ready and Rotten also name the header pill | 9 |
| `UI_ZeD_Farm_PhaseReady` | `Ready` | Farm plot card: growth phase on the six-cell strip (cell about 9 letters wide); Ready and Rotten also name the header pill | 9 |
| `UI_ZeD_Farm_PillEmpty` | `Empty` | Farm plot card: header pill for plowed land with nothing planted | 9 |
| `UI_ZeD_Farm_PillGrowing` | `Growing` | Farm plot card: header pill for a healthy growing plant | 9 |
| `UI_ZeD_Farm_Plot` | `Farm Plot` | Farm plot card: card title, and the plot's name when the game gives none | 20 |
| `UI_ZeD_Farm_Skill` | `Your farming %1` | Farm plot card: line under the plant's name; %1 is the player's Farming level | 24 |
| `UI_ZeD_Farm_SkillReadyToSow` | `Your farming %1 \| ready to sow` | Farm plot card: line under the name of plowed land; %1 is the player's Farming level (the bar is a separator) | 36 |
| `UI_ZeD_Farm_SowFromBags` | `Sow from your bags` | Farm plot card: section heading over the seed list | - |
| `UI_ZeD_Farm_SummaryDry` | `%1 dry` | Farm plot card: Garden in reach summary: how many plots are dry or parched | 14 |
| `UI_ZeD_Farm_SummaryPlotMany` | `%1 plots` | Farm plot card: Garden in reach summary for two or more plots | 14 |
| `UI_ZeD_Farm_SummaryPlotOne` | `%1 plot` | Farm plot card: Garden in reach summary for exactly one plot | 14 |
| `UI_ZeD_Farm_SummaryThirsty` | `%1 thirsty` | Farm plot card: Garden in reach summary: how many plots are thirsty | 14 |
| `UI_ZeD_Farm_TagInSeason` | `In season` | Farm plot card: tag on a seed row of the Sow list (bordered tag) | 14 |
| `UI_ZeD_Farm_TagRiskyMonth` | `Risky month` | Farm plot card: tag on a seed row of the Sow list (bordered tag) | 14 |
| `UI_ZeD_Farm_Treat` | `Treat` | Farm plot card: verb button, and the button on each pest row | 10 |
| `UI_ZeD_Farm_HelpCompost` | `Compost: spread compost on the plot` | Farm plot card: help line over the Compost button | - |
| `UI_ZeD_Farm_HelpDig` | `Dig up: take the plot out with a shovel` | Farm plot card: help line over the Dig up button | - |
| `UI_ZeD_Farm_HelpFertilize` | `Fertilize: feed the plot with fertilizer` | Farm plot card: help line over the Fertilize button | - |
| `UI_ZeD_Farm_HelpHarvest` | `Harvest: pick what is ripe` | Farm plot card: help line over the Harvest button | - |
| `UI_ZeD_Farm_HelpPlot` | `Plot: look at this plot` | Farm plot card: help line over a plot in the row of nearby plots; a press shows that plot | - |
| `UI_ZeD_Farm_HelpSow` | `Sow: pick a seed from your bags` | Farm plot card: help line over the Sow button that opens the list of seeds | - |
| `UI_ZeD_Farm_HelpSowSeed` | `Sow: plant %1 in this plot` | Farm plot card: help line over a seed in the Sow list; %1 = the seed's name | - |
| `UI_ZeD_Farm_HelpTreat` | `Treat: spray the plant against pests` | Farm plot card: help line over the Treat button | - |
| `UI_ZeD_Farm_HelpTreatPest` | `Treat: spray against %1` | Farm plot card: help line over the Treat button of one pest; %1 = the pest's name in lower case | - |
| `UI_ZeD_Farm_HelpWater` | `Water: water the plant from what you carry` | Farm plot card: help line over the Water button | - |
| `UI_ZeD_Farm_HintDig` | `dig it up` | Farm plot card: what Dig up does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Farm_HintFertilize` | `fertilize it` | Farm plot card: what Fertilize does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Farm_HintSow` | `sow it` | Farm plot card: what Sow does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Farm_HintTreat` | `treat it` | Farm plot card: what Treat does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Farm_HintWater` | `water it` | Farm plot card: what Water does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Farm_NeedsFertilizer` | `fertilizer in your bags` | Farm plot card: what Fertilize needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Farm_NeedsSeeds` | `seeds in your bags` | Farm plot card: what Sow needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Farm_NeedsShovel` | `a shovel or trowel` | Farm plot card: what Dig up needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Farm_NeedsSpray` | `a spray in your bags` | Farm plot card: what Treat needs when no particular spray is named, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Farm_NeedsSprayNamed` | `%1 in your bags` | Farm plot card: what Treat needs when a particular spray is named, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2"; %1 = the spray's item name | - |
| `UI_ZeD_Farm_NeedsWater` | `water in your hands or bags` | Farm plot card: what Water needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |

## Fire

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Fire_AddFromBags` | `Add fuel from your bags` | Fire card: section heading over the fuel list | - |
| `UI_ZeD_Fire_Adds` | `Adds` | Fire card: right side of that heading, over the column of time each piece adds | 8 |
| `UI_ZeD_Fire_AllFuel` | `All fuel (%1)` | Fire card: fuel list row that adds everything carried; %1 is the number of pieces | - |
| `UI_ZeD_Fire_ConfirmTakeApart` | `Take the campfire apart? You get 3 stones; what is on it drops.` | Fire card: confirmation in the footer | - |
| `UI_ZeD_Fire_Fire` | `Fire` | Fire card: card title when the game gives the fire no name | 24 |
| `UI_ZeD_Fire_FuelFull` | `The fire holds no more fuel` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_GainEach` | `+%1 each` | Fire card: time one piece of fuel adds when more than one is carried; %1 is the time, e.g. '+1 h 30 m each' | 16 |
| `UI_ZeD_Fire_GasLeft` | `Gas left` | Fire card: propane barbecue, label of the hours of gas | 14 |
| `UI_ZeD_Fire_Hrs` | `%1 hrs` | Fire card: propane barbecue, hours of gas as H:MM, e.g. 12:30 hrs | 12 |
| `UI_ZeD_Fire_InsertTank` | `Insert tank` | Fire card: verb button on the propane barbecue | 14 |
| `UI_ZeD_Fire_LightWith` | `Light with` | Fire card: section heading over the lighting methods | - |
| `UI_ZeD_Fire_NameAll` | `%1: all (%2)` | Fire card: fuel row that adds every piece of one kind; %1 is the item name, %2 the number | - |
| `UI_ZeD_Fire_NameAllThatFit` | `%1: all that fit (%2)` | Fire card: fuel row that adds as many pieces of one kind as fit; %1 is the item name, %2 the number | - |
| `UI_ZeD_Fire_NeedFuelFirst` | `Light: needs fuel in the fire first` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_NeedFuelItems` | `Add fuel: needs something that burns` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_NeedGasTank` | `Turn on: needs a propane tank with gas` | Fire card: the NEEDS line under the verbs of a propane barbecue | - |
| `UI_ZeD_Fire_NeedLighter` | `Light: needs a lighter or matches with tinder, or a notched plank and a stick` | Fire card: the NEEDS line under the verbs | - |
| `UI_ZeD_Fire_NeedsFuel` | `Needs fuel` | Fire card: tag on the kindling row of the Light with list | 14 |
| `UI_ZeD_Fire_NeedsStick` | `Needs a stick` | Fire card: tag on the kindling row of the Light with list | 14 |
| `UI_ZeD_Fire_NeedTank` | `Insert tank: needs a propane tank` | Fire card: the NEEDS line under the verbs of a propane barbecue | - |
| `UI_ZeD_Fire_OfFuelHolds` | `of fuel \| holds %1 h` | Fire card: small text beside the big time-left readout; %1 is the most hours the fire can hold (the bar is a separator) | 24 |
| `UI_ZeD_Fire_OnTheFire` | `On the fire` | Fire card: section heading over the cooking rows | - |
| `UI_ZeD_Fire_OnTheGrill` | `On the grill` | Fire card: section heading over the cooking rows of a propane barbecue | - |
| `UI_ZeD_Fire_PillOut` | `Out` | Fire card: header pill for a fire that is out | 12 |
| `UI_ZeD_Fire_PropaneBBQ` | `Propane Barbecue` | Fire card: card title when the game gives the barbecue no name | 24 |
| `UI_ZeD_Fire_PutOut` | `Put out` | Fire card: verb button | 12 |
| `UI_ZeD_Fire_RemoveTank` | `Remove tank` | Fire card: verb button on the propane barbecue | 14 |
| `UI_ZeD_Fire_ScaleFull` | `Full` | Fire card: right end of the fuel strip's scale | 6 |
| `UI_ZeD_Fire_ScaleHours` | `+%1 H` | Fire card: hour marks along the fuel strip's scale, e.g. +2 H | 8 |
| `UI_ZeD_Fire_ScaleNow` | `Now` | Fire card: left end of the fuel strip's scale | 6 |
| `UI_ZeD_Fire_TagFull` | `Full` | Fire card: tag on a fuel row that no longer fits (bordered tag) | 8 |
| `UI_ZeD_Fire_TakeApart` | `Take apart` | Fire card: verb button (danger), campfire only | 12 |
| `UI_ZeD_Fire_Tank` | `Tank` | Fire card: propane barbecue, label of the tank state | 14 |
| `UI_ZeD_Fire_TankIn` | `In` | Fire card: propane barbecue, value of Tank when a tank is fitted | 6 |
| `UI_ZeD_Fire_TooTired` | `Too tired` | Fire card: tag on the kindling row of the Light with list | 14 |
| `UI_ZeD_Fire_HelpAdd` | `Add: put %1 on the fire` | Fire card: help line over an Add button in the fuel list; %1 = the fuel's name | - |
| `UI_ZeD_Fire_HelpAddEvery` | `Add all: put everything on the list on the fire` | Fire card: help line over the Add all button on the All fuel row | - |
| `UI_ZeD_Fire_HelpAddMany` | `Add all: put every %1 that fits on the fire` | Fire card: help line over the Add all button on a fuel row; %1 = the fuel's name | - |
| `UI_ZeD_Fire_HelpBurner` | `Burner knob: turn the grill on or off` | Fire card (propane barbecue): help line over the burner knob | - |
| `UI_ZeD_Fire_HelpFuel` | `Add fuel: put something that burns on the fire` | Fire card: help line over the Add fuel button | - |
| `UI_ZeD_Fire_HelpIgnite` | `Igniter: light the burner` | Fire card (propane barbecue): help line over the igniter | - |
| `UI_ZeD_Fire_HelpInsert` | `Insert tank: put a propane tank in the cart` | Fire card (propane barbecue): help line over the Insert tank button | - |
| `UI_ZeD_Fire_HelpLight` | `Light: choose how to light the fire` | Fire card: help line over the Light button that opens the list of ways to light the fire | - |
| `UI_ZeD_Fire_HelpLightWith` | `Light: light the fire with %1` | Fire card: help line over a row of the Light with list; %1 = what lights the fire | - |
| `UI_ZeD_Fire_HelpOff` | `Turn off: shut the gas` | Fire card (propane barbecue): help line over the Turn off button | - |
| `UI_ZeD_Fire_HelpOn` | `Turn on: light the burner` | Fire card (propane barbecue): help line over the Turn on button | - |
| `UI_ZeD_Fire_HelpOut` | `Put out: put the fire out` | Fire card: help line over the Put out button | - |
| `UI_ZeD_Fire_HelpRemove` | `Remove tank: take the tank out of the cart` | Fire card (propane barbecue): help line over the Remove tank button | - |
| `UI_ZeD_Fire_HelpTake` | `Take apart: take the campfire down` | Fire card: help line over the Take apart button | - |
| `UI_ZeD_Fire_HelpTankPart` | `Tank: put a tank in the cart or take it out` | Fire card (propane barbecue): help line over the tank in the picture | - |
| `UI_ZeD_Fire_HintFuel` | `add fuel` | Fire card: what Add fuel does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Fire_HintLight` | `light it` | Fire card: what Light does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Fire_HintOn` | `turn it on` | Fire card (propane barbecue): what Turn on does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Fire_HintTank` | `put a tank in` | Fire card (propane barbecue): what Insert tank does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Fire_NeedsFuelFirst` | `fuel on the fire` | Fire card: what Light needs when the fire has no fuel, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fire_NeedsFuelItems` | `something that burns in your bags` | Fire card: what Add fuel needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fire_NeedsGas` | `a propane tank with gas` | Fire card (propane barbecue): what Turn on needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fire_NeedsLighter` | `a lighter or matches in your bags` | Fire card: what Light needs when the fire has fuel, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fire_NeedsSpareTank` | `a propane tank in your bags` | Fire card (propane barbecue): what Insert tank needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fire_QTakeApart` | `Take the campfire apart? The fire is lost.` | Fire card: the question in the footer after Take apart is pressed; the footer then offers a yes and a no | - |

## Fluid

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Fluid_ConfirmEmpty` | `Pour %1 of %2 out on the ground?` | Fluid card: confirmation in the footer; %1 is the amount, e.g. 1.25 L, %2 the liquid's name in lower case | - |
| `UI_ZeD_Fluid_Container` | `Container` | Fluid card: a container's name when neither the item nor the game names it | 22 |
| `UI_ZeD_Fluid_From` | `From` | Fluid card: button on each container row that makes it the one to pour from | 8 |
| `UI_ZeD_Fluid_HintFrom` | `Choose "From" on a container below` | Fluid card: hint inside the empty left tank | - |
| `UI_ZeD_Fluid_HintInto` | `Choose "Into" on a container below` | Fluid card: hint inside the empty right tank | - |
| `UI_ZeD_Fluid_Into` | `Into` | Fluid card: button on each container row that makes it the one to pour into | 8 |
| `UI_ZeD_Fluid_LiquidWord` | `liquid` | Fluid card: the word for the liquid in the empty-out question when the liquid has no name (lower case) | 14 |
| `UI_ZeD_Fluid_NearbyTile` | `Nearby \| %1 tile` | Fluid card: under the pinned world container's name; %1 is the distance, exactly 1 (the bar is a separator) | 24 |
| `UI_ZeD_Fluid_NearbyTiles` | `Nearby \| %1 tiles` | Fluid card: under the pinned world container's name; %1 is the distance, any other number (the bar is a separator) | 24 |
| `UI_ZeD_Fluid_PourProgress` | `%1 of %2` | Fluid card: while pouring, how much has poured of the whole amount, e.g. 0.50 of 1.25 L | - |
| `UI_ZeD_Fluid_TagFull` | `Full` | Fluid card: tag on a container row that is full (bordered tag) | 10 |
| `UI_ZeD_Fluid_TagMixes` | `Mixes` | Fluid card: tag on a container row where the pour would mix liquids (bordered tag) | 10 |
| `UI_ZeD_Fluid_TagSame` | `Same` | Fluid card: tag on a container row holding the same liquid as the one being poured (bordered tag) | 10 |
| `UI_ZeD_Fluid_TagTooHeavy` | `Too heavy` | Fluid card: tag on a container row in a bag when the inventory is over its limit (bordered tag) | 10 |
| `UI_ZeD_Fluid_TagWontMix` | `Won't mix` | Fluid card: tag on a container row whose liquid cannot mix with the one being poured (bordered tag) | 10 |
| `UI_ZeD_Fluid_TagWontTake` | `Won't take` | Fluid card: tag on a container row that refuses the liquid being poured (bordered tag; the widest tag, it sets the column) | 10 |
| `UI_ZeD_Fluid_TooFull` | `You carry too much to pour into a container in your bags.` | Fluid card: the NEEDS line when the inventory is over its limit and the target container is in a bag | - |
| `UI_ZeD_Fluid_YourContainers` | `Your containers` | Fluid card: section heading over the list of containers | - |
| `UI_ZeD_Fluid_HelpEmpty` | `Empty: pour the liquid out on the ground` | Fluid card: help line over the Empty button | - |
| `UI_ZeD_Fluid_HelpFromRow` | `From: pour out of %1` | Fluid card: help line over a container in the From list; %1 = its name | - |
| `UI_ZeD_Fluid_HelpIntoRow` | `Into: pour into %1` | Fluid card: help line over a container in the Into list; %1 = its name | - |
| `UI_ZeD_Fluid_HelpPour` | `Pour: move the amount from the left container to the right` | Fluid card: help line over the Pour button | - |
| `UI_ZeD_Fluid_HelpSlider` | `Amount: drag to choose how much to pour` | Fluid card: help line over the amount slider | - |
| `UI_ZeD_Fluid_HelpStep` | `Amount: %1 of the most that can move` | Fluid card: help line over a step button beside the amount slider; %1 = the button's label | - |
| `UI_ZeD_Fluid_HelpStop` | `Stop: stop pouring` | Fluid card: help line over the Stop button while pouring | - |
| `UI_ZeD_Fluid_HelpSwitch` | `Switch: swap the two containers` | Fluid card: help line over the Switch button that swaps the From and Into containers | - |
| `UI_ZeD_Fluid_HintPour` | `pour` | Fluid card: what Pour does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Fluid_NeedsAmount` | `an amount above zero` | Fluid card: what Pour needs when the amount is zero, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fluid_NeedsFit` | `a container that can take it` | Fluid card: what Pour needs when the other container cannot take the liquid, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fluid_NeedsLiquid` | `something to pour and room to pour it into` | Fluid card: what Pour needs when there is nothing to pour or no room, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Fluid_QEmpty` | `Empty the container? %1 of %2 is lost.` | Fluid card: the question in the footer after Empty is pressed; %1 = the amount, e.g. 1.25 L, %2 = the liquid's name in lower case; the footer then offers a yes and a no | - |

## Flyer

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Flyer_BeenThere` | `Been there` | Maps, hover card over a flyer pin: status line (visited) | - |
| `UI_ZeD_Flyer_ClickRead` | `Click to read` | Maps, hover card over a flyer pin with a mouse: hint line | - |
| `UI_ZeD_Flyer_NotBeenThere` | `Not been there` | Maps, hover card over a flyer pin: status line (not visited) | - |
| `UI_ZeD_Flyer_PadRead` | `Press to read` | Maps, hover card over a flyer pin with a controller: hint line (A is the controller button) | - |

## Focus

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Focus_Sample` | `Sample` | ZeD setup and the window menu, Controller highlight choices: the word in the small sample row that shows how each highlight looks | 12 |

## Forage

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Forage_CatCommon` | `Common` | World window, Foraging tab, More detail, Categories grid: a common category here | 8 |
| `UI_ZeD_Forage_CatIn` | `In` | World window, Foraging tab, More detail, Categories grid: a category present here (value column) | 8 |
| `UI_ZeD_Forage_CatLocked` | `L%1` | World window, Foraging tab, More detail, Categories grid: value of a category not yet unlocked (%1 = Foraging level needed) | 5 |
| `UI_ZeD_Forage_CatPeak` | `Peak` | World window, Foraging tab, More detail, Categories grid: the most common category here | 8 |
| `UI_ZeD_Forage_CatRare` | `Rare` | World window, Foraging tab, More detail, Categories grid: a rare category here | 8 |
| `UI_ZeD_Forage_CatsInRange` | `Categories in range` | World window, Foraging tab, More detail: sub-header over the categories grid | 28 |
| `UI_ZeD_Forage_CatsLocked` | `%1 / %2 locked` | World window, Foraging tab, More detail: right side of the categories sub-header (%1 = categories listed, %2 = how many are locked) | 20 |
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
| `UI_ZeD_Forage_Day` | `Day` | World window, Foraging tab: under the sky arc, it is daytime | 8 |
| `UI_ZeD_Forage_FindDist` | `%1T %2` | World window, Foraging tab, Recent finds: distance and bearing of a find (%1 = tiles away, T = tiles, %2 = compass direction) | 8 |
| `UI_ZeD_Forage_FindsEmpty` | `Recent finds will appear here.` | World window, Foraging tab: empty state of the recent finds list | 40 |
| `UI_ZeD_Forage_FocusAll` | `All categories` | World window, Foraging tab: first option of the Search Focus dropdown (no focus) | 24 |
| `UI_ZeD_Forage_HeadDist` | `Dist` | World window, Foraging tab, Recent finds: column header, distance (the column is about 48 design pixels wide) | 6 |
| `UI_ZeD_Forage_HeadWeight` | `Wt` | World window, Foraging tab, Recent finds: column header, weight (right-aligned, about 36 design pixels) | 4 |
| `UI_ZeD_Forage_ModClothing` | `Clothing` | World window, Foraging tab, More detail, Modifiers grid: penalty from clothing | 14 |
| `UI_ZeD_Forage_ModFatigue` | `Fatigue` | World window, Foraging tab, More detail, Modifiers grid: penalty from tiredness | 14 |
| `UI_ZeD_Forage_ModHealth` | `Health` | World window, Foraging tab, More detail, Modifiers grid: penalty from injury or illness | 14 |
| `UI_ZeD_Forage_Modifiers` | `Modifiers` | World window, Foraging tab, More detail: sub-header over the modifiers grid | 20 |
| `UI_ZeD_Forage_ModMoving` | `Moving` | World window, Foraging tab, More detail, Modifiers grid: penalty from moving | 14 |
| `UI_ZeD_Forage_ModPanic` | `Panic` | World window, Foraging tab, More detail, Modifiers grid: penalty from panic | 14 |
| `UI_ZeD_Forage_MoreDetail` | `More detail` | World window, Foraging tab: disclosure row that opens the categories and modifiers | 24 |
| `UI_ZeD_Forage_Net` | `Net` | World window, Foraging tab: label under the net modifier percent in the hero band | 6 |
| `UI_ZeD_Forage_NetValue` | `%1 net` | World window, Foraging tab, More detail: right side of the modifiers sub-header (%1 = signed percent, e.g. +5%) | 16 |
| `UI_ZeD_Forage_Night` | `Night` | World window, Foraging tab: under the sky arc, it is night | 8 |
| `UI_ZeD_Forage_SeasonSummer` | `Summer` | World window, Foraging tab: season chip (the other seasons are the game's own words) | 12 |
| `UI_ZeD_Forage_StanceAim` | `Aim` | World window, Foraging tab: stance row tile (read-only status) | 12 |
| `UI_ZeD_Forage_StanceAiming` | `Aiming` | World window, Foraging tab: hero chip and a modifier row name | 12 |
| `UI_ZeD_Forage_StanceCrouch` | `Crouch` | World window, Foraging tab: stance row tile (read-only status) | 12 |
| `UI_ZeD_Forage_StanceSearching` | `Searching` | World window, Foraging tab: hero chip and the Searching tile of the stance row | 14 |
| `UI_ZeD_Forage_StanceSneaking` | `Sneaking` | World window, Foraging tab: hero chip and a modifier row name | 12 |
| `UI_ZeD_Forage_StanceWalking` | `Walking` | World window, Foraging tab: hero chip, what the character is doing | 12 |
| `UI_ZeD_Forage_Tiles` | `Tiles` | World window, Foraging tab: label under the search radius number (unit of the radius) | 8 |
| `UI_ZeD_Forage_Unknown` | `Unknown` | World window, Foraging tab: zone, season or item name the game cannot give | 14 |
| `UI_ZeD_Forage_WxClear` | `Clear` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxCloudy` | `Cloudy` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxFog` | `Fog` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxOvercast` | `Overcast` | World window, Foraging tab: hero chip, weather | 12 |
| `UI_ZeD_Forage_WxRain` | `Rain` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxSnow` | `Snow` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_WxStorm` | `Storm` | World window, Foraging tab: hero chip, weather | 10 |
| `UI_ZeD_Forage_SearchHelp` | `Search mode: press to start or stop looking for things to forage` | Foraging tab: help line over the search mode button | - |
| `UI_ZeD_Forage_MoreHelp` | `More detail: press to show or hide the categories and modifiers` | Foraging tab: help line over the More detail button that shows or hides the categories and modifiers | - |

## Furn

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Furn_Always` | `Always` | Furniture tab, Disassemble mode: chance column when an item is always returned | 8 |
| `UI_ZeD_Furn_CarryNone` | `You carry no furniture.` | Furniture tab, Place mode: empty state | - |
| `UI_ZeD_Furn_Facing` | `Facing` | Furniture tab, Place and Rotate modes: small label before the N E S W buttons | 10 |
| `UI_ZeD_Furn_MayYield` | `May yield` | Furniture tab, Disassemble mode: section heading above the items you may get back | 20 |
| `UI_ZeD_Furn_More` | `+ %1 more` | Furniture tab, fact row: how many more acceptable tools there are (e.g. Claw Hammer + 3 more) | - |
| `UI_ZeD_Furn_NothingToPlace` | `Nothing to place.` | Furniture tab, Place mode: line when you carry nothing to place | - |
| `UI_ZeD_Furn_OnCursor` | `On cursor` | Furniture tab, Place mode: small tag on the furniture currently on the cursor | 12 |
| `UI_ZeD_Furn_OnThisTile` | `On this tile` | Furniture tab: section heading above the objects on the pointed tile | 20 |
| `UI_ZeD_Furn_PickupNo` | `Cannot pick up` | Furniture tab, Pick up mode: status line and tile chip when it cannot be picked up | - |
| `UI_ZeD_Furn_PickupReady` | `Ready to pick up` | Furniture tab, Pick up mode: status line when the pointed furniture can be picked up | - |
| `UI_ZeD_Furn_PlaceNo` | `Does not fit here` | Furniture tab, Place mode: status line and tile chip when it does not fit | - |
| `UI_ZeD_Furn_PlaceReady` | `Fits here` | Furniture tab, Place mode: status line when the furniture fits | - |
| `UI_ZeD_Furn_PointBuilt` | `Point at something built or crafted.` | Furniture tab, Repair mode: prompt when nothing repairable is pointed at | - |
| `UI_ZeD_Furn_PointFurniture` | `Point at furniture.` | Furniture tab: prompt when nothing is pointed at | - |
| `UI_ZeD_Furn_RepairNo` | `Cannot repair` | Furniture tab, Repair mode: status line and tile chip when it cannot be repaired | - |
| `UI_ZeD_Furn_RepairReady` | `Ready to repair` | Furniture tab, Repair mode: status line when it can be repaired | - |
| `UI_ZeD_Furn_RollChance` | `Roll chance` | Furniture tab, Disassemble mode: second column legend of the yield list | 14 |
| `UI_ZeD_Furn_RotateNo` | `Cannot turn` | Furniture tab, Rotate mode: status line and tile chip when it cannot be turned | - |
| `UI_ZeD_Furn_RotateReady` | `Turns in place` | Furniture tab, Rotate mode: status line when it can be turned | - |
| `UI_ZeD_Furn_ScrapNo` | `Cannot take apart` | Furniture tab, Disassemble mode: status line and tile chip when it cannot be taken apart | - |
| `UI_ZeD_Furn_ScrapReady` | `Ready to take apart` | Furniture tab, Disassemble mode: status line when it can be taken apart | - |
| `UI_ZeD_Furn_Target` | `Target` | Furniture tab: small tag on the object currently targeted | 12 |
| `UI_ZeD_Furn_ToCursor` | `To the cursor` | Controller prompt for B on the Furniture tab (hands the stick back to the world cursor) | 20 |
| `UI_ZeD_Furn_UpTo` | `Up to` | Furniture tab, Disassemble mode: first column legend of the yield list (most you can get) | 10 |
| `UI_ZeD_Furn_YourFurniture` | `Your furniture` | Furniture tab, Place mode: section heading above the furniture you carry | 20 |

## Hair

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Hair_After` | `After` | Identity tab, Hair and beard: caption under the drawn head after the picked cut | 8 |
| `UI_ZeD_Hair_BusyCut` | `Cutting hair` | Identity tab, Hair and beard: the strip while the cut runs (a progress bar under it) | 30 |
| `UI_ZeD_Hair_BusyTie` | `Tying hair` | Identity tab, Hair and beard: the strip while the hair is tied | 30 |
| `UI_ZeD_Hair_BusyTrim` | `Trimming the beard` | Identity tab, Hair and beard: the strip while the beard is trimmed or shaved | 30 |
| `UI_ZeD_Hair_BusyUntie` | `Untying hair` | Identity tab, Hair and beard: the strip while the hair is untied | 30 |
| `UI_ZeD_Hair_Color` | `Color` | Identity tab, Hair and beard: small label of the hair colour line (beside Hair and Beard) | 8 |
| `UI_ZeD_Hair_DoneBeard` | `Done: beard is now %1` | Identity tab, Hair and beard: the strip after a trim; %1 is the new beard | - |
| `UI_ZeD_Hair_DoneHair` | `Done: hair is now %1` | Identity tab, Hair and beard: the strip after a cut; %1 is the new style | - |
| `UI_ZeD_Hair_EmptyBeard` | `No beard to trim. It grows back over time.` | Identity tab, Hair and beard: in place of the list when there is no beard | - |
| `UI_ZeD_Hair_EmptyHair` | `Nothing to cut: the hair is too short. It grows back over time.` | Identity tab, Hair and beard: in place of the list when the hair cannot be cut or tied | - |
| `UI_ZeD_Hair_FromMod` | `(from %1)` | Identity tab, Hair and beard: small note after a row a hair mod added; %1 is the mod's name | - |
| `UI_ZeD_Hair_GrowsBack` | `Grows over time` | Identity tab, Hair and beard: small note at the right of the hair colour line | 18 |
| `UI_ZeD_Hair_GrpCut` | `Cut` | Identity tab, Hair and beard: group heading over the cuts that need Scissors | 10 |
| `UI_ZeD_Hair_GrpShave` | `Shave` | Identity tab, Hair and beard: group heading over Shave Hair / Shave Beard | 10 |
| `UI_ZeD_Hair_GrpStyle` | `Style` | Identity tab, Hair and beard: group heading over the styles that need Hair Gel or Hair Spray | 10 |
| `UI_ZeD_Hair_GrpTie` | `Tie` | Identity tab, Hair and beard: group heading over the tie choices (no tool) | 10 |
| `UI_ZeD_Hair_GrpTrim` | `Trim` | Identity tab, Hair and beard: group heading over the beard trims | 10 |
| `UI_ZeD_Hair_HatOff` | `Your %1 comes off first` | Identity tab, Hair and beard: the strip's small line, the game takes the hat off before a cut; %1 is the hat's name | - |
| `UI_ZeD_Hair_HintMouse` | `Hover a row for the game's hint.` | Identity tab, Hair and beard: small line under the strip's first line (mouse) | 44 |
| `UI_ZeD_Hair_HintPad` | `Focus a row: it shows here. Press to do it.` | Identity tab, Hair and beard: small line under the strip's first line (controller; A is the controller's A button) | 44 |
| `UI_ZeD_Hair_Len0` | `None` | Identity tab, Hair and beard: hair or beard length beside its three small bars (level 0) | 8 |
| `UI_ZeD_Hair_Len1` | `Short` | Identity tab, Hair and beard: hair or beard length beside its three small bars (level 1) | 8 |
| `UI_ZeD_Hair_Len2` | `Medium` | Identity tab, Hair and beard: hair or beard length beside its three small bars (level 2) | 8 |
| `UI_ZeD_Hair_Len3` | `Long` | Identity tab, Hair and beard: hair or beard length beside its three small bars (level 3) | 8 |
| `UI_ZeD_Hair_NoTool` | `No tool` | Identity tab, Hair and beard: right of the Tie group heading (tying needs nothing) | 12 |
| `UI_ZeD_Hair_NoToolNeeded` | `No tool needed` | Identity tab, Hair and beard: the strip's small line and the hover hint for tying or untying | - |
| `UI_ZeD_Hair_NotFromBeard` | `Can't be trimmed from %1.` | Identity tab, Hair and beard: why a beard style is out of reach; %1 is the current beard | - |
| `UI_ZeD_Hair_NotFromHair` | `Can't be cut from %1.` | Identity tab, Hair and beard: why a style is out of reach although the hair is long enough; %1 is the current style | - |
| `UI_ZeD_Hair_NotePictures` | `%1 is on: its styles are in this list.` | Identity tab, Hair and beard: note under the list when a hair mod with a picture window (Improved Hair Menu, NeatUI Hairstyler) is on; its styles are rows here, each with the character's 3D figure; %1 is the mod's name | - |
| `UI_ZeD_Hair_NoteSpongie` | `%1 is on: every style at or under this length can be chosen. Rows it adds carry its name.` | Identity tab, Hair and beard: note under the list when Spongie's Hairstyle Unlocker is on; %1 is the mod's name | - |
| `UI_ZeD_Hair_Now` | `Now` | Identity tab, Hair and beard: caption under the drawn head as it is now | 8 |
| `UI_ZeD_Hair_OutOfReach` | `Not available here` | Identity tab, Hair and beard: folded group of the styles the hair (or beard) cannot be cut into from here | 16 |
| `UI_ZeD_Hair_OutTitle` | `%1: not available here` | Identity tab, Hair and beard: the strip when an out-of-reach row is picked; %1 is the style | - |
| `UI_ZeD_Hair_PartCount` | `%1 (%2)` | Identity tab, Hair and beard: a half of the Hair / Beard switch; %1 is the game's word Hair or Beard, %2 how many choices | 16 |
| `UI_ZeD_Hair_Pick` | `Choose a row to see what it needs` | Identity tab, Hair and beard: the strip at the foot of the drawer before a row is picked | 40 |
| `UI_ZeD_Hair_Section` | `Hair and beard` | Identity tab (Character window), Hair and beard section: heading under the license | 24 |
| `UI_ZeD_Hair_Stop` | `Stop` | Identity tab, Hair and beard: the strip's button while a cut runs (stops it) | 10 |
| `UI_ZeD_Hair_TagNotFromBeard` | `Not from this beard` | Identity tab, Hair and beard: short tag at the right of an out-of-reach beard row | 22 |
| `UI_ZeD_Hair_TagNotFromHair` | `Not from this style` | Identity tab, Hair and beard: short tag at the right of an out-of-reach row | 22 |
| `UI_ZeD_Hair_TagTooShort` | `Too short` | Identity tab, Hair and beard: short tag at the right of an out-of-reach row | 18 |
| `UI_ZeD_Hair_Tied` | `(tied, %1 loose)` | Identity tab, Hair and beard: after the hair style when it is tied; %1 is the style it goes back to when untied | - |
| `UI_ZeD_Hair_ToHand` | `Puts the %1 in your hand` | Identity tab, Hair and beard: the strip's small line, the game puts the tool in the main hand; %1 is the tool's name | - |
| `UI_ZeD_Hair_TooShortBeard1` | `Beard too short. Needs a short beard.` | Identity tab, Hair and beard: why a beard style is out of reach (length 1) | - |
| `UI_ZeD_Hair_TooShortBeard2` | `Beard too short. Needs a medium beard.` | Identity tab, Hair and beard: why a beard style is out of reach (length 2) | - |
| `UI_ZeD_Hair_TooShortBeard3` | `Beard too short. Needs a long beard.` | Identity tab, Hair and beard: why a beard style is out of reach (length 3) | - |
| `UI_ZeD_Hair_TooShortHair1` | `Hair too short. Needs short hair.` | Identity tab, Hair and beard: why a style is out of reach (it needs hair of length 1) | - |
| `UI_ZeD_Hair_TooShortHair2` | `Hair too short. Needs medium hair.` | Identity tab, Hair and beard: why a style is out of reach (it needs hair of length 2) | - |
| `UI_ZeD_Hair_TooShortHair3` | `Hair too short. Needs long hair.` | Identity tab, Hair and beard: why a style is out of reach (it needs hair of length 3) | - |
| `UI_ZeD_Hair_ToolOr` | `%1 or %2` | Identity tab, Hair and beard: two tools, either of which will do; %1 and %2 are the game's item names (Razor, Scissors) | - |
| `UI_ZeD_Hair_Uses` | `Uses your %1` | Identity tab, Hair and beard: the strip's small line, a style uses some of the gel or spray; %1 is its name | - |
| `UI_ZeD_Hair_VerbCut` | `Cut` | Identity tab, Hair and beard: the strip's button (sentence case) | 10 |
| `UI_ZeD_Hair_VerbShave` | `Shave` | Identity tab, Hair and beard: the strip's button (sentence case) | 10 |
| `UI_ZeD_Hair_VerbStyle` | `Style` | Identity tab, Hair and beard: the strip's button (sentence case) | 10 |
| `UI_ZeD_Hair_VerbTie` | `Tie` | Identity tab, Hair and beard: the strip's button (sentence case) | 10 |
| `UI_ZeD_Hair_VerbTrim` | `Trim` | Identity tab, Hair and beard: the strip's button (sentence case) | 10 |
| `UI_ZeD_Hair_VerbUntie` | `Untie` | Identity tab, Hair and beard: the strip's button (sentence case) | 10 |
| `UI_ZeD_Hair_YouHave` | `You have %1.` | Identity tab, Hair and beard: hover hint on a row that can be done; %1 is the tool's name | - |
| `UI_ZeD_Hair_HelpMore` | `Show the styles you can't pick yet.` | Identity tab, Hair and beard: help line over the folded row of styles you cannot pick yet | - |
| `UI_ZeD_Hair_HelpMoreOpen` | `Fold the styles you can't pick yet.` | Identity tab, Hair and beard: help line over the same row while it is open | - |
| `UI_ZeD_Hair_HelpPart` | `Show the choices for %1.` | Identity tab, Hair and beard: help line over the Hair and Beard switch; %1 = the game's name for the part (hair style or beard style) | - |
| `UI_ZeD_Hair_HelpRow` | `Pick %1 to see what it needs.` | Identity tab, Hair and beard: help line over a style row; %1 = the style's name | - |
| `UI_ZeD_Hair_HelpStop` | `Stop and leave it as it is.` | Identity tab, Hair and beard: help line over the Stop button while a cut or trim runs | - |
| `UI_ZeD_Hair_HintCut` | `cut your hair` | Identity tab, Hair and beard: what Cut does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hair_HintMoreStyles` | `choose from more styles` | Identity tab, Hair and beard: what the folded row of more styles lets you do, in lower case, filling %2 of "With %1 you could %2" | - |
| `UI_ZeD_Hair_HintShave` | `shave your head` | Identity tab, Hair and beard: what shaving the head does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hair_HintShaveBeard` | `shave your beard` | Identity tab, Hair and beard: what shaving the beard does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hair_HintStyle` | `style your hair` | Identity tab, Hair and beard: what styling the hair does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hair_HintTrim` | `trim your beard` | Identity tab, Hair and beard: what trimming the beard does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hair_NeedsLongerBeard` | `a longer beard` | Identity tab, Hair and beard: what a style needs when the beard is too short, in lower case, filling %2 of "%1 needs %2" | - |
| `UI_ZeD_Hair_NeedsLongerHair` | `longer hair` | Identity tab, Hair and beard: what a style needs when the hair is too short, in lower case, filling %2 of "%1 needs %2" | - |
| `UI_ZeD_Hair_OutTitleNA` | `%1: not available here` | Identity tab, Hair and beard: the strip when an unavailable row is picked; %1 = the style | - |

## Health

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Health_Burn` | `Burn` | Health tab (Character window): condition badge on a burned body part (pill) | 14 |
| `UI_ZeD_Health_GlassShards` | `Glass shards` | Health tab (Character window): condition badge on an injured body part (pill) | 18 |
| `UI_ZeD_Health_Healthy` | `Healthy` | Health tab (Character window): hover detail for a body part with no conditions (beside a green dot) | 14 |
| `UI_ZeD_Health_InjuredOf` | `%1 of %2 injured` | Health tab (Character window): summary line; %1 is how many body parts have a wound or condition, %2 how many body parts there are | 24 |
| `UI_ZeD_Health_NoInjuries` | `No injuries` | Health tab (Character window): summary line (with a green dot) when nothing is wounded and health is fine | 20 |
| `UI_ZeD_Health_NoInjuriesLow` | `No injuries, low body health` | Health tab (Character window): summary line (with a yellow dot) when nothing is wounded but some body part has reduced health (hunger, illness, cold) | 32 |
| `UI_ZeD_Health_Overall` | `Overall` | Health tab (Character window): stat row label at the top of the summary, before the overall body health percentage | 12 |
| `UI_ZeD_Health_Qualified` | `%1 (%2)` | Health tab (Character window): a condition with its severity or state in a badge, e.g. Deep Wound (Severe), Stitched (Good); %1 the condition, %2 the severity word | 28 |
| `UI_ZeD_Health_HelpExercise` | `Do %1 for %2 minutes.` | Health tab (Character window): help line while the pointer is on an exercise button; %1 = the exercise's name, %2 = the session length in minutes | - |
| `UI_ZeD_Health_HelpHeader` | `Show or hide the body figure.` | Health tab (Character window): help line while the pointer is on the Health header above the body figure | - |
| `UI_ZeD_Health_HelpTimeLess` | `Make the session 10 minutes shorter.` | Health tab (Character window): help line while the pointer is on the minus button beside the exercise session length | - |
| `UI_ZeD_Health_HelpTimeMore` | `Make the session 10 minutes longer.` | Health tab (Character window): help line while the pointer is on the plus button beside the exercise session length | - |

## Hook

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Hook_BleedingOnGround` | `Bleeding onto the ground` | Butcher hook card: label of the progress band while blood runs onto the ground | 26 |
| `UI_ZeD_Hook_BleedOnGround` | `Bleed onto the ground` | Butcher hook card: row under the container list: let the blood run onto the ground | - |
| `UI_ZeD_Hook_BloodLostHead` | `Taking the head now splashes the %1 of blood still in it.` | Butcher hook card: the NEEDS line before taking the head while blood remains; %1 is the amount, e.g. 1.50 L | - |
| `UI_ZeD_Hook_BloodLostMeat` | `Taking the meat now loses the %1 of blood still in it; the head splashes it.` | Butcher hook card: the NEEDS line before taking meat while blood remains; %1 is the amount, e.g. 1.50 L | - |
| `UI_ZeD_Hook_CollectInto` | `Collect into` | Butcher hook card: section heading over the list of containers for the blood | - |
| `UI_ZeD_Hook_DeadNearby` | `Dead animals nearby` | Butcher hook card: section heading over the list of carcasses to hang | - |
| `UI_ZeD_Hook_GroundTile` | `Ground \| %1 tile` | Butcher hook card: where a dead animal lies, exactly 1 tile away (the bar is a separator) | 24 |
| `UI_ZeD_Hook_GroundTiles` | `Ground \| %1 tiles` | Butcher hook card: where a dead animal lies, any other distance (the bar is a separator) | 24 |
| `UI_ZeD_Hook_Hang` | `Hang` | Butcher hook card: button on a carcass row that hangs it on the hook (btn sentence case applies) | 10 |
| `UI_ZeD_Hook_InUseBy` | `Someone else is using the hook.` | Butcher hook card: the NEEDS line under the verbs | - |
| `UI_ZeD_Hook_Knife` | `Knife` | Butcher hook card: label of the line naming the knife in use | 10 |
| `UI_ZeD_Hook_NotForHook` | `Not for the hook` | Butcher hook card: tag on a carcass the hook does not take (bordered tag) | 18 |
| `UI_ZeD_Hook_PillBleeding` | `Bleeding` | Butcher hook card: header pill while the carcass bleeds out | 12 |
| `UI_ZeD_Hook_PillEmpty` | `Empty` | Butcher hook card: header pill for a hook with no carcass | 12 |
| `UI_ZeD_Hook_PillInUse` | `In use` | Butcher hook card: header pill when another player uses the hook | 12 |
| `UI_ZeD_Hook_PillOnHook` | `On the hook` | Butcher hook card: header pill for a carcass on the hook | 12 |
| `UI_ZeD_Hook_Taken` | `Taken` | Butcher hook card: value of Leather, Head or Meat once that part has been taken from the carcass | 10 |
| `UI_ZeD_Hook_Within2` | `Within 2 tiles or carried` | Butcher hook card: right side of that heading | - |
| `UI_ZeD_Hook_HelpAdd` | `Add corpse: hang a dead animal on the hook` | Butcher hook card: help line over the Add corpse button | - |
| `UI_ZeD_Hook_HelpBleed` | `Bleed: let the blood run onto the ground` | Butcher hook card: help line over the Bleed button | - |
| `UI_ZeD_Hook_HelpGather` | `Gather: take the parts off the carcass` | Butcher hook card: help line over the Gather button | - |
| `UI_ZeD_Hook_HelpHang` | `Hang: put %1 on the hook` | Butcher hook card: help line over a corpse in the Hang list; %1 = the animal's name | - |
| `UI_ZeD_Hook_HelpInto` | `Into: let the blood run into %1` | Butcher hook card: help line over a container in the Into list; %1 = its name | - |
| `UI_ZeD_Hook_HelpPart` | `Gather: take the %1 from the carcass` | Butcher hook card: help line over the button that gathers one part; %1 = the part's name (the game's word: leather, blood, head) | - |
| `UI_ZeD_Hook_HelpRemove` | `Remove corpse: take the carcass off the hook` | Butcher hook card: help line over the Remove corpse button | - |
| `UI_ZeD_Hook_HelpStop` | `Stop: stop the work` | Butcher hook card: help line over the Stop button while the work runs | - |
| `UI_ZeD_Hook_HintGather` | `gather the parts` | Butcher hook card: what Gather does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hook_HintHang` | `hang one up` | Butcher hook card: what Add corpse does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hook_NeedsCorpse` | `a dead animal nearby or in your bags` | Butcher hook card: what Add corpse needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Hook_NeedsKnife` | `a knife in your bags` | Butcher hook card: what Gather needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |

## Host

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Host_AskDeletePlayer` | `Delete this character from the server?` | Host screen: question in the action strip | - |
| `UI_ZeD_Host_AskDeleteWorld` | `Delete the world? It cannot be undone.` | Host screen: question in the action strip | - |
| `UI_ZeD_Host_AskReset` | `Soft-reset the server?` | Host screen: question in the action strip | - |
| `UI_ZeD_Host_BadAccount` | `That account name will not do.` | Host screen: red note under the form when the account name is not valid | - |
| `UI_ZeD_Host_LabelAccount` | `Account` | Host screen: caps label at the left of the account name row (about 18 letters of room) | 18 |
| `UI_ZeD_Host_LabelSettings` | `Server settings` | Host screen: caps label at the left of the server settings choice | 18 |
| `UI_ZeD_Host_LabelWorld` | `The world` | Host screen: caps label at the left of the world upkeep buttons | 18 |
| `UI_ZeD_Host_Reset` | `Reset` | Host screen: strip button that confirms the soft reset | 12 |
| `UI_ZeD_Host_Resetting` | `Resetting` | Host screen: caps heading over the soft reset progress bar | - |
| `UI_ZeD_Host_Title` | `Project Zomboid  +  Host a game` | Host screen: title bar. The + is the ZeD title separator | - |

## Hud

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Hud_PutAway` | `Put away` | Controller prompt strip of the car radio and the siren controller: the B button puts the prop away | 20 |

## Hutch

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Hutch_Bleach` | `Bleach \| twice as fast` | Hutch card: cleaning checklist: optional bleach (the bar is a separator) | - |
| `UI_ZeD_Hutch_BothShut` | `Both doors shut` | Hutch card: plate where shut doors hide the boxes | 18 |
| `UI_ZeD_Hutch_Box` | `Box %1` | Hutch card: heading of one egg laying box, e.g. Box 2 | 8 |
| `UI_ZeD_Hutch_Boxes` | `%1 boxes` | Hutch card: right side of the Egg laying boxes heading when both doors are shut | 14 |
| `UI_ZeD_Hutch_BoxesFull` | `Every box is full: the hens will lay outside.` | Hutch card: the NEEDS line under the boxes | - |
| `UI_ZeD_Hutch_CloseHatch` | `Close hatch` | Hutch card: verb button for the egg hatch door | 14 |
| `UI_ZeD_Hutch_Dirtiness` | `Dirtiness` | Hutch card: label over the floor's dirtiness bar | 14 |
| `UI_ZeD_Hutch_DoorOpen` | `Door open` | Hutch card: text beside the main door's lamp | 14 |
| `UI_ZeD_Hutch_DoorShut` | `Door shut` | Hutch card: text beside the main door's lamp, and the plate where a shut door hides the perches | 14 |
| `UI_ZeD_Hutch_EggsBoxes` | `%1 eggs \| %2 boxes` | Hutch card: right side of the Egg laying boxes heading: eggs and boxes (the bar is a separator) | 24 |
| `UI_ZeD_Hutch_HatchOpen` | `Egg hatch open` | Hutch card: text beside the egg hatch's lamp | 18 |
| `UI_ZeD_Hutch_HatchShut` | `Egg hatch shut` | Hutch card: text beside the egg hatch's lamp | 18 |
| `UI_ZeD_Hutch_HenSitting` | `Hen sitting` | Hutch card: the disabled button of a box that has a hen sitting in it (the box is about 12 letters wide) | 12 |
| `UI_ZeD_Hutch_Mop` | `Mop, towel or broom` | Hutch card: cleaning checklist: a cleaning tool needed, when you carry none | - |
| `UI_ZeD_Hutch_MopNamed` | `Mop, towel or broom \| %1` | Hutch card: cleaning checklist: the tool you have; %1 is its item name (the bar is a separator) | - |
| `UI_ZeD_Hutch_NoBirds` | `No birds inside.` | Hutch card: line under COOP ROOSTING when no bird is inside | - |
| `UI_ZeD_Hutch_OpenHatch` | `Open hatch` | Hutch card: verb button for the egg hatch door | 14 |
| `UI_ZeD_Hutch_PillShut` | `Shut` | Hutch card: header pill when both doors are shut | 8 |
| `UI_ZeD_Hutch_PutIn` | `Put in` | Hutch card: verb button, shown when you hold a bird the hutch takes | 10 |
| `UI_ZeD_Hutch_PutInNeeds` | `Put in: %1` | Hutch card: the NEEDS line when the bird cannot go in; %1 is the game's own reason (doors shut, hutch full) | - |
| `UI_ZeD_Hutch_Sitting` | `Sitting \| %1` | Hutch card: under a hen sitting in a box; %1 is the number of eggs under her (the bar is a separator) | 14 |
| `UI_ZeD_Hutch_SubAdult` | `%1 \| adult` | Hutch card: small line under a bird's name on the perch list; %1 is the species (the bar is a separator) | 24 |
| `UI_ZeD_Hutch_SubYoung` | `%1 \| young` | Hutch card: small line under a young bird's name on the perch list; %1 is the species (the bar is a separator) | 24 |
| `UI_ZeD_Hutch_Water` | `Water` | Hutch card: cleaning checklist: water needed, when you carry none | - |
| `UI_ZeD_Hutch_WaterNamed` | `Water \| %1` | Hutch card: cleaning checklist: the water you have; %1 is its item name (the bar is a separator) | - |
| `UI_ZeD_Hutch_HelpClean` | `Clean: wash the floor` | Hutch card: help line over the Clean button | - |
| `UI_ZeD_Hutch_HelpCloseDoor` | `Close door: shut the main door` | Hutch card: help line over the Close door button | - |
| `UI_ZeD_Hutch_HelpCloseHatch` | `Close hatch: shut the egg hatch` | Hutch card: help line over the Close hatch button | - |
| `UI_ZeD_Hutch_HelpEggs` | `Grab eggs: take the eggs from every free box` | Hutch card: help line over the Grab eggs button | - |
| `UI_ZeD_Hutch_HelpGrabBird` | `Grab: take %1 out of the coop` | Hutch card: help line over the Grab button on a bird; %1 = the bird's name | - |
| `UI_ZeD_Hutch_HelpGrabBox` | `Grab: take the eggs from box %1` | Hutch card: help line over the Grab button on an egg box; %1 = the box's number | - |
| `UI_ZeD_Hutch_HelpInfo` | `Info: see %1 in the Animals tab` | Hutch card: help line over the Info button on a bird; %1 = the bird's name | - |
| `UI_ZeD_Hutch_HelpOpenDoor` | `Open door: open the main door` | Hutch card: help line over the Open door button | - |
| `UI_ZeD_Hutch_HelpOpenHatch` | `Open hatch: open the egg hatch` | Hutch card: help line over the Open hatch button | - |
| `UI_ZeD_Hutch_HelpPutIn` | `Put in: put the bird you carry in the hutch` | Hutch card: help line over the Put in button | - |
| `UI_ZeD_Hutch_HintClean` | `clean the floor` | Hutch card: what Clean does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hutch_HintPutIn` | `put the bird in` | Hutch card: what Put in does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Hutch_NeedsBoth` | `%1 and %2` | Hutch card: joins two needs of Clean into one, filling %2 of "%1 needs %2"; %1 = the water need, %2 = the cleaning tool need | - |
| `UI_ZeD_Hutch_NeedsMop` | `a mop, towel or broom` | Hutch card: what Clean needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Hutch_NeedsOpen` | `a door or the egg hatch open` | Hutch card: what Put in needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Hutch_NeedsWater` | `water in your bags` | Hutch card: what Clean needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |

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
| `UI_ZeD_Identity_TraitsNegative` | `Negative (%1)` | Identity tab (Character window), driver's-license card: Traits section, small subheading over the bad traits; %1 is how many | 20 |
| `UI_ZeD_Identity_TraitsPositive` | `Positive (%1)` | Identity tab (Character window), driver's-license card: Traits section, small subheading over the good traits; %1 is how many | 20 |
| `UI_ZeD_Identity_Unknown` | `Unknown` | Identity tab (Character window), driver's-license card: surname / hair colour shown when the game gives none | 16 |
| `UI_ZeD_Identity_WeightKg` | `%1 kg` | Identity tab (Character window), driver's-license card: weight pill at the top right of the card; %1 is the number (kilograms) | 10 |
| `UI_ZeD_Identity_HelpHeader` | `Switch the license photo between the bust and the whole body.` | Identity tab (Character window): help line over the header above the license photo | - |

## Inv

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Inv_ColCat` | `Cat` | Inventory list: column heading for the item category | 6 |
| `UI_ZeD_Inv_ColCond` | `Cond` | Inventory list: column heading for item condition | 6 |
| `UI_ZeD_Inv_ColName` | `Name` | Inventory list: column heading, and the name of the sort order in the grid's order line | 8 |
| `UI_ZeD_Inv_ColWt` | `Wt` | Inventory list: column heading for item weight | 4 |
| `UI_ZeD_Inv_Empty` | `Nothing in here.` | Inventory list: centered message when a container has no items | 24 |
| `UI_ZeD_Inv_GridView` | `Grid view` | Inventory lists: hover hint on the grid button of the List/Grid toggle | - |
| `UI_ZeD_Inv_ItemsMany` | `%1 items` | Inventory lists (both windows), compact container header: how many items it holds (several or none) | 12 |
| `UI_ZeD_Inv_ItemsOne` | `%1 item` | Inventory lists (both windows), compact container header: how many items it holds (one) | - |
| `UI_ZeD_Inv_OrderLine` | `Order: %1, as the list` | Inventory grid, column bar: names the list's sort order the grid follows; %1 is NAME, CATEGORY, CONDITION or WEIGHT | - |
| `UI_ZeD_Inv_OrderWt` | `Weight` | Inventory grid, order line: name of the sort order (by weight) | 14 |
| `UI_ZeD_Inv_RowHelp` | `%1: press for its card, drag it to move it, right-click for its menu` | Inventory list: help line over an item's row; %1 = the item's name | - |
| `UI_ZeD_Inv_ColHelp` | `Sort by %1: press again to turn the order around` | Inventory list: help line over a column heading; %1 = the heading's text | - |
| `UI_ZeD_Inv_CatFoldHelp` | `Press to fold this group` | Inventory list, Equipment tab and item card lists: help line over the heading of a group that is open | - |
| `UI_ZeD_Inv_CatOpenHelp` | `Press to open this group` | Inventory list, Equipment tab and item card lists: help line over the heading of a group that is folded | - |
| `UI_ZeD_Inv_ListHelp` | `List: this container's things as rows` | Inventory lists: help line over the List button of the List \| Grid toggle | - |
| `UI_ZeD_Inv_GridHelp` | `Grid: this container's things as icons` | Inventory lists: help line over the Grid button of the List \| Grid toggle | - |
| `UI_ZeD_Inv_XferHelp` | `Move the selected things to column %1` | Inventory lists with several columns: help line over the button that moves the selected items to another column; %1 = the column's number | - |

## ItemAct

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_ItemAct_MinutesShort` | `%1m` | Item card progress band, minutes left to cook or burn (%1 is the number) | 6 |
| `UI_ZeD_ItemAct_Reading` | `Reading` | Item card progress band label while a book is read | 14 |
| `UI_ZeD_ItemAct_Repairing` | `Repairing` | Item card progress band label while clothing is repaired | 14 |

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
| `UI_ZeD_Join_Forget` | `Remove` | Join screen: strip button that removes a public server from the saved ones | 12 |
| `UI_ZeD_Join_KeepPassword` | `Leave it empty to keep the saved one.` | Join screen: note under the password field when editing an account | - |
| `UI_ZeD_Join_KvAddress` | `Address` | Join screen: caps label in the server facts (about 12 letters of room) | 12 |
| `UI_ZeD_Join_KvWhitelist` | `Whitelist` | Join screen: caps label in the server facts | 12 |
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
| `UI_ZeD_Journal_AskDelete` | `Delete the entry? It can't be brought back.` | Character window, Journal tab, Journal sub-tab: the question in the band after an entry's delete button is pressed; the band then offers a yes and a no | - |
| `UI_ZeD_Journal_Delete` | `Delete` | Character window, Journal tab, Journal sub-tab: hover hint of an entry's delete button, and the yes button of the delete question | 12 |
| `UI_ZeD_Journal_HelpDelete` | `Delete this entry. It asks first.` | Character window, Journal tab, Journal sub-tab: help line over an entry's delete button | - |
| `UI_ZeD_Journal_HelpGroupHide` | `Fold the entries of %1.` | Character window, Journal tab, Journal sub-tab: help line over the heading of a group of entries that is open; %1 = the group's name | - |
| `UI_ZeD_Journal_HelpGroupShow` | `Show the entries of %1.` | Character window, Journal tab, Journal sub-tab: help line over the heading of a group of entries that is folded; %1 = the group's name | - |
| `UI_ZeD_Journal_HelpKillsHide` | `Fold the kills by kind.` | Character window, Journal tab: help line over the kills heading while the list of kinds is open | - |
| `UI_ZeD_Journal_HelpKillsShow` | `Show the kills by kind.` | Character window, Journal tab: help line over the kills heading while the list of kinds is folded | - |
| `UI_ZeD_Journal_HelpSubTab` | `Open %1.` | Character window, Journal tab: help line over a sub-tab that is not the open one; %1 = its name | - |

## Keyboard

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Keyboard_Show` | `Show` | On-screen keyboard, key that reveals a masked (password) field | 8 |
| `UI_ZeD_Keyboard_HelpChar` | `Type %1.` | On-screen keyboard: help line over a letter, digit or sign key; %1 = the character it types | - |
| `UI_ZeD_Keyboard_HelpDelete` | `Delete the character before the caret.` | On-screen keyboard: help line over the delete key | - |
| `UI_ZeD_Keyboard_HelpCaps` | `Keep typing capital letters until you press it again.` | On-screen keyboard: help line over the caps lock key | - |
| `UI_ZeD_Keyboard_HelpShift` | `A capital for the next letter.` | On-screen keyboard: help line over the shift key | - |
| `UI_ZeD_Keyboard_HelpAccept` | `Accept what you typed.` | On-screen keyboard: help line over the accept key of a one-line field | - |
| `UI_ZeD_Keyboard_HelpEnter` | `Start a new line.` | On-screen keyboard: help line over the key that ends a line in a many-line field | - |
| `UI_ZeD_Keyboard_HelpSpace` | `Type a space.` | On-screen keyboard: help line over the space bar | - |
| `UI_ZeD_Keyboard_HelpLeft` | `Move the caret one letter left.` | On-screen keyboard: help line over the left arrow key | - |
| `UI_ZeD_Keyboard_HelpRight` | `Move the caret one letter right.` | On-screen keyboard: help line over the right arrow key | - |
| `UI_ZeD_Keyboard_HelpCancel` | `Close the keyboard and put the field back as it was.` | On-screen keyboard: help line over the cancel key | - |
| `UI_ZeD_Keyboard_HelpShow` | `Show or hide what you have typed.` | On-screen keyboard: help line over the Show key that reveals a masked (password) field | - |

## Lock

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Lock_BusyLocking` | `Locking` | Padlock card: label in the progress band while the padlock is being locked (small, left of the bar) | 24 |
| `UI_ZeD_Lock_BusyPutting` | `Putting the padlock on` | Padlock card: label in the progress band while a key padlock goes on | 26 |
| `UI_ZeD_Lock_BusyRemoving` | `Removing the padlock` | Padlock card: label in the progress band while a padlock comes off | 26 |
| `UI_ZeD_Lock_BusyTrying` | `Trying %1` | Padlock card: label in the progress band while a code is tried; %1 is the code with spaces, e.g. 3 1 9 | 24 |
| `UI_ZeD_Lock_BusyWalking` | `Walking over` | Padlock card: label in the progress band while the character walks to the object | 24 |
| `UI_ZeD_Lock_ComboIn` | `Combination Padlock \| in your inventory` | Padlock card: value of the padlock line while choosing a code (the bar is a separator) | - |
| `UI_ZeD_Lock_ComboNone` | `No Combination Padlock in your inventory` | Padlock card: value of the padlock line while choosing a code with no padlock | - |
| `UI_ZeD_Lock_FactContainer` | `Container` | Padlock card: label of the container line (the label column is about 12 letters wide) | 12 |
| `UI_ZeD_Lock_FactKey` | `Key` | Padlock card: label of the key line (the label column is about 12 letters wide) | 12 |
| `UI_ZeD_Lock_FactPadlock` | `Padlock` | Padlock card: label of the padlock line (the label column is about 12 letters wide) | 12 |
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
| `UI_ZeD_Lock_NeedsLock` | `Needs \| lock` | Padlock card: section heading over the list of what locking needs (the bar is a separator) | - |
| `UI_ZeD_Lock_NeedsRemove` | `Needs \| remove padlock` | Padlock card: section heading over the list of what removing a key padlock needs (the bar is a separator) | - |
| `UI_ZeD_Lock_NeedUseCombo` | `Use combination padlock: a Combination Padlock in your inventory` | Padlock card: checklist row | - |
| `UI_ZeD_Lock_NeedUsePad` | `Use padlock: a Padlock with its keys in your inventory` | Padlock card: checklist row | - |
| `UI_ZeD_Lock_NoPadlock` | `No padlock on it` | Padlock card: plate where the padlock would be, on an object with none | 22 |
| `UI_ZeD_Lock_NoteSet` | `Locked to everyone, you included, until the code takes the padlock off` | Padlock card: note under the padlock while choosing a code (wraps, centred) | - |
| `UI_ZeD_Lock_PadComboLocked` | `Combination \| locked to everyone` | Padlock card: value of the padlock line for a code lock (the bar is a separator) | - |
| `UI_ZeD_Lock_PadKeyOpens` | `Key padlock \| opens for whoever carries its key` | Padlock card: value of the padlock line for a key lock (the bar is a separator) | - |
| `UI_ZeD_Lock_PillCode` | `Code lock` | Padlock card: header pill for a code-locked object | 16 |
| `UI_ZeD_Lock_PillKey` | `Key lock` | Padlock card: header pill for a key-locked object | 16 |
| `UI_ZeD_Lock_PillSetting` | `Setting a code` | Padlock card: header pill while choosing a code | 16 |
| `UI_ZeD_Lock_PillUnlocked` | `Unlocked` | Padlock card: header pill for an object with no padlock | 16 |
| `UI_ZeD_Lock_StatusNoCombo` | `Can't lock: no Combination Padlock in your inventory` | Padlock card: footer line | - |
| `UI_ZeD_Lock_StatusNoKey` | `Can't remove the padlock: its key is not in your inventory` | Padlock card: footer line | - |
| `UI_ZeD_Lock_StatusReadyKey` | `Ready to remove the padlock with its key` | Padlock card: footer line | - |
| `UI_ZeD_Lock_StatusReadyLock` | `Ready to lock it with %1` | Padlock card: footer line; %1 is the code with spaces, e.g. 3 1 9 | - |
| `UI_ZeD_Lock_StatusReadyTry` | `Ready to try %1` | Padlock card: footer line; %1 is the code with spaces, e.g. 3 1 9 | - |
| `UI_ZeD_Lock_StatusWalking` | `Walking over to the padlock` | Padlock card: footer line while the character walks to the object | - |
| `UI_ZeD_Lock_StatusWorking` | `Working on the padlock` | Padlock card: footer line while a padlock action runs | - |
| `UI_ZeD_Lock_StatusWrong` | `Wrong code: %1. The padlock stays on.` | Padlock card: footer line (red) after a wrong try; %1 is the code with spaces, e.g. 3 1 9 | - |
| `UI_ZeD_Lock_StatusZeroCode` | `Can't lock: a code of 000 does nothing` | Padlock card: footer line | - |
| `UI_ZeD_Lock_WhatItLocks` | `What it locks` | Padlock card: section heading | - |
| `UI_ZeD_Lock_HelpLock` | `Lock: put the combination padlock on` | Padlock card: help line over the Lock button | - |
| `UI_ZeD_Lock_HelpRemove` | `Remove padlock: take the padlock off with its key` | Padlock card: help line over the Remove padlock button of a key padlock | - |
| `UI_ZeD_Lock_HelpStop` | `Stop: stop what the character is doing` | Padlock card: help line over the Stop button while the character is working on the padlock | - |
| `UI_ZeD_Lock_HelpTry` | `Remove padlock: try the code on the dial` | Padlock card: help line over the Remove padlock button of a combination padlock | - |
| `UI_ZeD_Lock_HelpUseCombo` | `Use combination padlock: set a code and lock it` | Padlock card: help line over the Use combination padlock button | - |
| `UI_ZeD_Lock_HelpUsePad` | `Use padlock: put a key padlock on` | Padlock card: help line over the Use padlock button | - |
| `UI_ZeD_Lock_HintLock` | `lock it` | Padlock card: what Lock does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Lock_HintRemove` | `take the padlock off` | Padlock card: what Remove padlock does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Lock_HintUseCombo` | `put it on` | Padlock card: what Use combination padlock does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Lock_HintUsePad` | `put it on` | Padlock card: what Use padlock does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Lock_NeedsBoth` | `%1 and %2` | Padlock card: joins two needs of Lock into one, filling %2 of "%1 needs %2"; %1 = the padlock need, %2 = the code need | - |
| `UI_ZeD_Lock_NeedsCode` | `a code other than 000` | Padlock card: what Lock needs when the code on the dial is 000, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Lock_NeedsCombo` | `a Combination Padlock in your bags` | Padlock card: what Lock and Use combination padlock need, the game's item name for the padlock, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Lock_NeedsKey` | `its key in your bags` | Padlock card: what Remove padlock needs for a key padlock, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Lock_NeedsKeyPad` | `a padlock with its keys in your bags` | Padlock card: what Use padlock needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Lock_QLock` | `Lock the container? It shuts to everyone.` | Padlock card: the question in the footer after Lock is pressed; the footer then offers a yes and a no | - |

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
| `UI_ZeD_Looks_TurnLeft` | `Turn left` | Character looks screen (new game): hover hint of the arrow button that turns the figure left (icon-only button) | - |
| `UI_ZeD_Looks_TurnRight` | `Turn right` | Character looks screen (new game): hover hint of the arrow button that turns the figure right (icon-only button) | - |

## Machine

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Machine_AboutDayOne` | `About 1 day` | Craft tab, drying rack: time left, one day | 20 |
| `UI_ZeD_Machine_AboutDays` | `About %1 days` | Craft tab, drying rack: time left, several days (follows "%1 LEFT") | 20 |
| `UI_ZeD_Machine_AboutHourOne` | `About 1 hour` | Craft tab, drying rack: time left, one hour | 20 |
| `UI_ZeD_Machine_AboutHours` | `About %1 hours` | Craft tab, drying rack: time left, several hours | 20 |
| `UI_ZeD_Machine_AboutMinuteOne` | `About 1 minute` | Craft tab, drying rack: time left, one minute | 20 |
| `UI_ZeD_Machine_AboutMinutes` | `About %1 minutes` | Craft tab, drying rack: time left, several minutes | 20 |
| `UI_ZeD_Machine_Add` | `Add` | Craft tab, drying rack: button that adds an item to the rack | 8 |
| `UI_ZeD_Machine_DayEachOne` | `1 day each` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_DaysEach` | `%1 days each` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_FromBags` | `From your bags` | Craft tab, drying rack: small heading above items you can add | 24 |
| `UI_ZeD_Machine_HourEachOne` | `1 hour each` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_HoursEach` | `%1 hours each` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_Left` | `%1 left` | Craft tab, drying rack progress text; %1 is the "ABOUT ..." time phrase | 30 |
| `UI_ZeD_Machine_MinEach` | `%1 min each` | Craft tab, drying rack recipe line: how long each item takes | 14 |
| `UI_ZeD_Machine_NothingFits` | `Nothing you carry fits this rack.` | Craft tab, drying rack: line when none of your items can go on it | - |
| `UI_ZeD_Machine_Recipe` | `Recipe` | Craft tab, drying rack: small heading before the recipe name | 10 |
| `UI_ZeD_Machine_Start` | `Start` | Craft tab, drying rack: start button | 8 |
| `UI_ZeD_Machine_Stop` | `Stop` | Craft tab, drying rack: stop button | 8 |

## MainMenu

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_MainMenu_AboutDisplay` | `Display` | About block: left label of the screen size row | 12 |
| `UI_ZeD_MainMenu_AboutEncryption` | `Encryption` | About block: left label of a fact row (about 12 letters of room) | 12 |
| `UI_ZeD_MainMenu_AboutEncryptionValue` | `16-bit (was 8)` | About block: value of the Encryption row | - |
| `UI_ZeD_MainMenu_AboutGame` | `Game` | About block: left label of the game version row | 12 |
| `UI_ZeD_MainMenu_AboutPara` | `Zero Day OS is a homemade SECURE kernal of ZNIX made by some hard working freedom loving good guys (mostly me). FBI and you government slime, if you are reading this you must have got me--but I got you. This thing has state of the art anti phone tap programming in the BIOS AND we just upgraded from 8 to 16bit encryption that my cousins elementary school friends girlfriends uncle got out of MIT. dont ask. Suck on it commies!! You cant crack ZeD-OS. also it runs off the truck battery if it comes to that. LONG LIVE FREEDOM` | Main menu bar, ZeD menu, About block: the owner's own words (a fictional character's rough draft; keep the misspellings and the run-on, do not tidy) | - |
| `UI_ZeD_MainMenu_AboutPhoneTaps` | `Phone taps` | About block: left label of a fact row (about 12 letters of room) | 12 |
| `UI_ZeD_MainMenu_AboutPhoneTapsValue` | `None found` | About block: value of the Phone taps row | - |
| `UI_ZeD_MainMenu_AboutSub` | `secure ZNIX kernal -- DO NOT UNPLUG` | Main menu bar, ZeD menu, About block: the line under the title | - |
| `UI_ZeD_MainMenu_AboutUptime` | `Uptime` | About block: left label of the row showing how long the game has run | 12 |
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
| `UI_ZeD_MainMenu_PromptSelect` | `Choose` | Controller prompt in the footer of the main menu, pause window and their screens (A button) | 10 |
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
| `UI_ZeD_Map_FoldBack` | `Click or press here to fold it back` | Maps tab: placeholder line while the map is open in its own window (A is the controller button) | - |
| `UI_ZeD_Map_NoteDefault` | `Note` | Maps tab: default text of a new map note (saved with the note if left unchanged), the text box's starting text and the cursor preview | - |
| `UI_ZeD_Map_PadFold` | `Fold` | Map window, controller prompt for B (fold the map back into the tab) | 12 |
| `UI_ZeD_Map_PadMove` | `Move` | Map window, controller prompt next to L-STICK | - |
| `UI_ZeD_Map_StyleColor` | `Color` | Maps tab toolbar: map style pill | 10 |
| `UI_ZeD_Map_StylePaper` | `Paper` | Maps tab toolbar: map style pill | 10 |
| `UI_ZeD_Map_StyleSurvey` | `Survey` | Maps tab toolbar: map style pill | 10 |
| `UI_ZeD_Map_Unavailable` | `Map unavailable` | Maps tab: centered message when the world map is turned off | 24 |
| `UI_ZeD_Map_Unfolded` | `Map unfolded` | Maps tab: placeholder heading while the map is open in its own window | 24 |
| `UI_ZeD_Map_SideList` | `Players and notes` | Maps tab toolbar (World window drawer): hover hint of the icon that shows or hides the side list | - |
| `UI_ZeD_Map_KeyButton` | `Key` | Maps tab toolbar: button that opens the map key | 8 |
| `UI_ZeD_Map_KeyColor` | `The Color map is the ground as it looks from above: roofs, roads and trees, not buildings by use. The key's colors are on Survey.` | Maps tab, map key panel on the Color map (Color and Survey are the map style buttons) | - |
| `UI_ZeD_Map_KeyPaper` | `The Paper map is the road map as printed: roads, towns and water, not buildings by use. The key's colors are on Survey.` | Maps tab, map key panel on the Paper map (Paper and Survey are the map style buttons) | - |
| `UI_ZeD_Map_ShowSurvey` | `Show survey` | Maps tab, map key panel: button that switches the map to Survey | 18 |
| `UI_ZeD_Map_DrawDraw` | `Draw` | Maps tab with Draw On The Map: the toolbar button and the free-hand tool (stands in for the mod's own word while the game cannot read it) | 10 |
| `UI_ZeD_Map_DrawLine` | `Line` | Maps tab with Draw On The Map: the straight-line tool (the mod's word) | 10 |
| `UI_ZeD_Map_DrawErase` | `Erase` | Maps tab with Draw On The Map: the eraser tool (the mod's word) | 10 |
| `UI_ZeD_Map_DrawThickness` | `Thickness` | Maps tab with Draw On The Map: label before the stroke size slider (the mod's word) | 12 |
| `UI_ZeD_Map_DrawFill` | `Fill` | Maps tab with Draw On The Map: label before the stroke density slider (the mod's word) | 8 |
| `UI_ZeD_Map_DrawInk` | `Ink: %1` | Maps tab with Draw On The Map: drawing row, the pen the strokes are drawn in. %1 an item name (Red Pen) | - |
| `UI_ZeD_Map_DirN` | `north` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_DirNE` | `north-east` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_DirE` | `east` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_DirSE` | `south-east` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_DirS` | `south` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_DirSW` | `south-west` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_DirW` | `west` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_DirNW` | `north-west` | Maps tab with Players On Map: which way another player is | - |
| `UI_ZeD_Map_AwayM` | `%1 m %2` | Maps tab with Players On Map: how far and which way a player is. %1 meters, %2 a direction (north) | - |
| `UI_ZeD_Map_AwayKm` | `%1 km %2` | Maps tab with Players On Map: how far and which way a player is. %1 kilometers (1.2), %2 a direction (north) | - |
| `UI_ZeD_Map_LearnedNotes` | `Learned notes` | Maps tab with Share Annotations: side list heading over the sets of notes the character learned | - |
| `UI_ZeD_Map_SetPlace` | `1 place` | Maps tab with Share Annotations: a learned set's row when the set has one mark | - |
| `UI_ZeD_Map_SetDeleteAskOne` | `Delete the notes %1? Its 1 place goes from your map.` | Maps tab with Share Annotations: the side list's question before deleting a set of one mark. %1 the set's name | - |
| `UI_ZeD_Map_SetPlaces` | `%1 places` | Maps tab with Share Annotations: a learned set's row. %1 how many marks it has | - |
| `UI_ZeD_Map_SetHidden` | `hidden` | Maps tab with Share Annotations: a learned set's row, after the places, when the set is hidden | - |
| `UI_ZeD_Map_SetHiddenBefore` | `Hidden on the game's map before` | Maps tab with Share Annotations: a set hidden on the game's own map, which can be shown again here | - |
| `UI_ZeD_Map_SetDeleteAsk` | `Delete the notes %1? Its %2 places go from your map.` | Maps tab with Share Annotations: the side list's question before deleting a set. %1 the set's name, %2 how many marks | - |
| `UI_ZeD_Map_NotesEmpty` | `No learned notes. Use %1 on a paper with someone's notes to learn them.` | Maps tab with Share Annotations: side list when no notes are learned. %1 the mod's menu entry (Remember annotations) | - |
| `UI_ZeD_Map_WhereOff` | `Kentucky, USA` | Maps tab with Where Am I?: over the map when the character is in none of the mod's areas (the mod's own words) | - |
| `UI_ZeD_Map_HelpCant` | `%1: %2` | Maps tab: help line over a mark, pen or tool that cannot be used now; %1 = its name, %2 = the reason (the game's own words, e.g. you need a pen) | - |
| `UI_ZeD_Map_HelpDraw` | `Show or hide the drawing tools.` | Maps tab, toolbar: help line over the button that shows or hides the drawing tools | - |
| `UI_ZeD_Map_HelpDrawErase` | `Erase: press on the map and move over the marks to take them off.` | Maps tab, drawing tools: help line over the Erase tool | - |
| `UI_ZeD_Map_HelpDrawFree` | `Draw freehand: press on the map and move.` | Maps tab, drawing tools: help line over the freehand Draw tool | - |
| `UI_ZeD_Map_HelpDrawLine` | `Draw a straight line: press where it starts and let go where it ends.` | Maps tab, drawing tools: help line over the Line tool | - |
| `UI_ZeD_Map_HelpFill` | `How close together the dots of a line are.` | Maps tab, drawing tools: help line over the slider for how close together the dots of a drawn line are | - |
| `UI_ZeD_Map_HelpFold` | `Fold the map back into the Maps tab.` | Maps tab: help line over the fold button while the map is open in its own window | - |
| `UI_ZeD_Map_HelpInk` | `%1: marks and notes in this color.` | Maps tab: help line over a color swatch; %1 = the color's name | - |
| `UI_ZeD_Map_HelpKey` | `Show or hide the map key: what the colors on the Survey map mean.` | Maps tab: help line over the button that shows or hides the map key | - |
| `UI_ZeD_Map_HelpKeyClose` | `Close the map key.` | Maps tab: help line over the close button of the map key | - |
| `UI_ZeD_Map_HelpMark` | `%1: pick this mark up, then click the map to put it down.` | Maps tab: help line over a mark on the toolbar; %1 = the mark's name | - |
| `UI_ZeD_Map_HelpMarkGrid` | `%1: pick this mark up. A right-click pins it to the toolbar or takes it off.` | Maps tab: help line over a mark in the full set of marks; %1 = the mark's name | - |
| `UI_ZeD_Map_HelpMarksClose` | `Fold the full set of marks away.` | Maps tab: help line over the button that folds the full set of marks away | - |
| `UI_ZeD_Map_HelpMarksOpen` | `Show every mark, to pick one or pin it to the toolbar.` | Maps tab: help line over the button that shows the full set of marks | - |
| `UI_ZeD_Map_HelpNote` | `Note: type the words in the box under the toolbar, then click the map to write them.` | Maps tab: help line over the Note tool on the toolbar | - |
| `UI_ZeD_Map_HelpRowDelete` | `Delete this from your map. You are asked first.` | Maps tab, side list of players and notes: help line over a row's delete button | - |
| `UI_ZeD_Map_HelpSideList` | `Show or hide the list of players and notes beside the map.` | Maps tab: help line over the button that shows or hides the side list | - |
| `UI_ZeD_Map_HelpStyleColor` | `Color: the ground as it looks from above.` | Maps tab: help line over the Color choice of the map style menu | - |
| `UI_ZeD_Map_HelpStyleMenu` | `How the map is drawn: Survey, Color or Paper.` | Maps tab: help line over the map style menu | - |
| `UI_ZeD_Map_HelpStylePaper` | `Paper: the county road map as printed.` | Maps tab: help line over the Paper choice of the map style menu | - |
| `UI_ZeD_Map_HelpStyleSurvey` | `Survey: the game's own map, buildings colored by use.` | Maps tab: help line over the Survey choice of the map style menu, and over the Survey entry in the map key | - |
| `UI_ZeD_Map_HelpSymbolReset` | `Back to the game's own size.` | Maps tab: help line over the Reset button beside the mark size slider | - |
| `UI_ZeD_Map_HelpSymbolSize` | `The size new marks and notes are made at.` | Maps tab: help line over the mark size slider | - |
| `UI_ZeD_Map_HelpThickness` | `How thick the lines are.` | Maps tab, drawing tools: help line over the line thickness slider | - |
| `UI_ZeD_Map_HelpUnfold` | `Open the map in a large window of its own.` | Maps tab: help line over the unfold button while the map sits in the tab | - |
| `UI_ZeD_Map_MarkAlert` | `Alert` | Maps tab: name of the alert (exclamation) mark; hover hint on the toolbar and in the full set of marks, and %1 of the mark help lines | - |
| `UI_ZeD_Map_MarkAxe` | `Axe` | Maps tab: name of the axe mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkCheck` | `Check mark` | Maps tab: name of the check mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkCross` | `Cross` | Maps tab: name of the cross mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkFire` | `Fire` | Maps tab: name of the fire mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkFood` | `Food` | Maps tab: name of the food mark (a burger; hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkGears` | `Gears` | Maps tab: name of the gears mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkGun` | `Gun` | Maps tab: name of the gun mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkHeart` | `Heart` | Maps tab: name of the heart mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkHouse` | `House` | Maps tab: name of the house mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkQuestion` | `Question mark` | Maps tab: name of the question mark mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkSkull` | `Skull` | Maps tab: name of the skull mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkStar` | `Star` | Maps tab: name of the star mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkTarget` | `Target` | Maps tab: name of the target mark (hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_MarkX` | `X` | Maps tab: name of the X mark (the letter X; hover hint, and %1 of the mark help lines) | - |
| `UI_ZeD_Map_Unfold` | `Unfold` | Maps tab: hover hint of the unfold button (opens the map in a window of its own); the same button reads Fold while it is open | - |

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

## MMHelp

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_MMHelp_Back` | `Back: go to the screen before this one.` | Main menu screens: help line over the Back button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_BackPause` | `Back: return to the pause menu.` | Pause window, Mods page: help line over the Back button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Close` | `Close: close this window.` | Main menu screens: help line over the Close button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Cancel` | `Cancel: leave things as they are.` | Main menu screens and the quit question: help line over the Cancel button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Delete` | `Delete: remove the chosen item. It asks first.` | Main menu screens: help line over a Delete button that asks first (begins with the button's name) | - |
| `UI_ZeD_MMHelp_DeleteProfile` | `Delete: remove the profile. This cannot be undone.` | Mod manager: help line over the Delete button of the question about deleting a profile (begins with the button's name) | - |
| `UI_ZeD_MMHelp_DeleteSave` | `Delete: remove the chosen save from the disk. This cannot be undone.` | Load game screen: help line over the Delete button of the question about deleting a save (begins with the button's name) | - |
| `UI_ZeD_MMHelp_DeleteSaveAsk` | `Delete: remove the chosen save. It asks first.` | Load game screen: help line over the Delete button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_More` | `More: other things to do with the chosen item.` | Main menu screens: help line over the More button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Play` | `Play: start the chosen game.` | Main menu screens: help line over the Play button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_PlaySave` | `Play: load the chosen save and start playing.` | Load game screen: help line over the Play button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Next` | `Next: go on to the next step.` | New game screens: help line over the Next button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_ChooseMods` | `Choose mods: pick the mods this game uses.` | New game screens: help line over the Choose mods button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Apply` | `Apply: put the changes into the game.` | Main menu screens: help line over the Apply button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_DiscardChanges` | `Discard changes: throw away what you changed since this window opened.` | Options, Mod manager and Server settings: help line over the Discard changes button of the question about leaving with unsaved changes (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Defaults` | `Defaults: put ZeD's settings back to how they start.` | Options, ZeD setup page: help line over the Defaults button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Start` | `Start: start the server and join it.` | Main menu screens: help line over the Start button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_HostStart` | `Start: start the server and join it.` | Host screen: help line over the Start button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_HostReset` | `Reset: start the server's world over. The question says what it keeps.` | Host screen: help line over the Reset button of the reset question (begins with the button's name) | - |
| `UI_ZeD_MMHelp_HostDeleteWorld` | `Delete: remove the server's world from the disk. This cannot be undone.` | Host screen: help line over the Delete button of the question about deleting the world (begins with the button's name) | - |
| `UI_ZeD_MMHelp_HostDeletePlayer` | `Delete: remove the character from the server. This cannot be undone.` | Host screen: help line over the Delete button of the question about deleting a character (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Abort` | `Abort: stop the server that is starting.` | Host screen: help line over the Abort button while the server is starting (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Connect` | `Connect: join the chosen server.` | Join screen: help line over the Connect button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Refresh` | `Refresh: ask the servers again.` | Join screen: help line over the Refresh button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Save` | `Save: keep your changes.` | Main menu screens: help line over the Save button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Rename` | `Rename: give it the new name.` | Main menu screens: help line over the Rename button in the bottom strip (begins with the button's name) | - |
| `UI_ZeD_MMHelp_RenameSave` | `Rename: give the save its new name.` | Load game screen: help line over the Rename button of the rename question (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Rewind` | `Rewind: roll the credits backwards.` | Credits screen: help line over the rewind button, marked << (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Fast` | `Fast forward: roll the credits faster.` | Credits screen: help line over the fast forward button, marked >> (begins with the button's name) | - |
| `UI_ZeD_MMHelp_PlayPause` | `Pause or play the credits.` | Credits screen: help line over the pause and play button | - |
| `UI_ZeD_MMHelp_EmptyTrash` | `Empty trash: throw away the file in it.` | Trash window: help line over the Empty trash button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Options` | `Options: change the game's settings and ZeD's.` | Main menu window and pause window, bottom strip: help line over the Options button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Mods` | `Mods: turn mods on and off, and set the order they load in.` | Main menu window, bottom strip: help line over the Mods button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Workshop` | `Mod uploader: send a mod of yours to the Steam Workshop.` | Main menu window, bottom strip: help line over the Mod uploader button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Credits` | `Credits: see who made the game.` | Main menu window, bottom strip: help line over the Credits button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Quit` | `Quit: leave the game. It asks first.` | Main menu window, bottom strip: help line over the Quit button, which asks first (begins with the button's name) | - |
| `UI_ZeD_MMHelp_QuitGame` | `Quit: leave the game. Anything unsaved is lost.` | Main menu window: help line over the Quit button of the quit question (begins with the button's name) | - |
| `UI_ZeD_MMHelp_QuitDesktop` | `Quit: leave to the desktop. It asks first.` | Pause window, bottom strip: help line over the button that leaves to the desktop, which asks first (begins with the button's name) | - |
| `UI_ZeD_MMHelp_SaveQuit` | `Save and quit: save the game, then leave to the main menu.` | Pause window, bottom strip: help line over the Save and quit button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_MonitorBack` | `Cancel: go back to the screen settings you had.` | Options: help line over the Cancel button of the question that appears after the screen settings change (begins with the button's name) | - |
| `UI_ZeD_MMHelp_MonitorKeep` | `Keep: keep the new screen settings.` | Options: help line over the Keep button of the question that appears after the screen settings change (begins with the button's name) | - |
| `UI_ZeD_MMHelp_SaveRow` | `Click a save to choose it, and click it again to play it.` | Load game screen: help line over a save's row, shown for the mouse only | - |
| `UI_ZeD_MMHelp_GameIcon` | `Click a game to choose it, and click it again to go on.` | New game screen: help line over a game's icon, shown for the mouse only | - |
| `UI_ZeD_MMHelp_Continue` | `Continue: load your latest save and keep playing.` | Main menu: help line over the big Continue button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_NewGame` | `New game: start a new game.` | Main menu: help line over the big New game button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_LoadGame` | `Load game: pick a saved game to play.` | Main menu: help line over the big Load game button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_JoinServer` | `Join a server: play with others on a server.` | Main menu: help line over the big Join a server button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_HostGame` | `Host a game: start a server on this computer for friends to join.` | Main menu: help line over the big Host a game button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Tutorial` | `Tutorial: learn the basics in a small practice game.` | Main menu: help line over the big Tutorial button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Resume` | `Resume: go back to the game.` | Pause menu (in game): help line over the big Resume button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_PauseMods` | `Mods: see the mods this game runs.` | Pause menu (in game): help line over the big Mods button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_SandboxIG` | `Sandbox options: this game's world settings.` | Pause menu (in game): help line over the big Sandbox options button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Players` | `Players: see who is on the server.` | Pause menu (in game, on a server): help line over the big Players button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_Invite` | `Invite: ask a friend to join through Steam.` | Pause menu (in game, on a server): help line over the big Invite button (begins with the button's name) | - |
| `UI_ZeD_MMHelp_ModRow` | `Click a mod to see it. Click it again, or use its box, to turn it on or off.` | Mod manager: help line over a mod's row, shown for the mouse only | - |
| `UI_ZeD_MMHelp_JoinRow` | `Click a server or an account to choose it. Click it again to connect.` | Join screen: help line over a server or account row, shown for the mouse only | - |
| `UI_ZeD_MMHelp_TownRow` | `Click a town to see it on the map. Click it again to go on.` | Spawn location screen (new game): help line over a town's row, shown for the mouse only | - |
| `UI_ZeD_MMHelp_WsFolder` | `Click a folder to edit its page on the Workshop.` | Workshop window: help line over a mod folder's row, shown for the mouse only | - |

## MMWord

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_MMWord_DiscardChanges` | `Discard changes` | Main menu screens (Options, Mod manager, Server settings, Workshop, description editor): the danger answer to the question about leaving with unsaved changes (shown in sentence case) | 18 |
| `UI_ZeD_MMWord_UndoChanges` | `Undo changes` | Mod manager, bottom strip: button that puts the mod list back as it was when the window opened (shown in sentence case) | 16 |

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
| `UI_ZeD_Mods_ChipConflictMany` | `%1 conflicts` | Mod manager: small caps tag on a mod's row, several conflicts. %1 is the number | 14 |
| `UI_ZeD_Mods_ChipConflictOne` | `%1 conflict` | Mod manager: small caps tag on a mod's row, one conflict. %1 is 1 | 14 |
| `UI_ZeD_Mods_ChipQueued` | `Queued` | Mod manager: small caps tag on a mod's row: its download is queued | 12 |
| `UI_ZeD_Mods_ChipUpdate` | `Update` | Mod manager: small caps tag on a mod's row: an update is waiting on Steam | 12 |
| `UI_ZeD_Mods_ChipUpdated` | `Updated` | Mod manager: small caps tag on a mod's row: Steam updated it while the game ran | 12 |
| `UI_ZeD_Mods_ConflictsChecking` | `Checking...` | Mod manager: under the Conflicts heading while the scan runs | - |
| `UI_ZeD_Mods_ConflictsHead` | `Conflicts` | Mod manager: caps heading in the detail pane over the conflicts | 20 |
| `UI_ZeD_Mods_ConflictsLater` | `Checked once a reload brings it in.` | Mod manager: under the Conflicts heading of a mod that is not loaded yet | - |
| `UI_ZeD_Mods_ConflictsNone` | `None found.` | Mod manager: under the Conflicts heading | - |
| `UI_ZeD_Mods_CopyName` | `%1 copy` | Mod manager: the name suggested for a duplicated profile. %1 is the original's name | - |
| `UI_ZeD_Mods_EmptyChecking` | `Checking the mods for conflicts` | Mod manager: the Conflicts tab while the scan runs | - |
| `UI_ZeD_Mods_EmptyConflicts` | `No conflicts among the mods running now` | Mod manager: empty list on the Conflicts tab | - |
| `UI_ZeD_Mods_EmptyFavs` | `No favorites yet` | Mod manager: empty list on the Starred tab | - |
| `UI_ZeD_Mods_EmptyNone` | `No mods match` | Mod manager: empty list when Find matches nothing | - |
| `UI_ZeD_Mods_EmptyProblems` | `Every mod can run` | Mod manager: empty list on the Problems tab | - |
| `UI_ZeD_Mods_HiddenMany` | `%1 conflicts hidden.` | Mod manager: under the list of conflicts | - |
| `UI_ZeD_Mods_HiddenOne` | `%1 conflict hidden.` | Mod manager: under the list of conflicts | - |
| `UI_ZeD_Mods_KvGame` | `Game` | Mod manager: caps label in the detail pane: the game versions the mod supports | 12 |
| `UI_ZeD_Mods_KvLoadOrder` | `Load order` | Mod manager: caps label in the detail pane and heading on the Profiles page | 12 |
| `UI_ZeD_Mods_KvReplaces` | `Replaces` | Mod manager: caps label in the detail pane: the game's scripts the mod replaces | 12 |
| `UI_ZeD_Mods_KvSize` | `Size` | Mod manager: caps label in the Workshop item's detail pane | 12 |
| `UI_ZeD_Mods_KvType` | `Type` | Mod manager: caps label in the detail pane (map, vehicle...) | 12 |
| `UI_ZeD_Mods_KvUpdated` | `Updated` | Mod manager: caps label in the Workshop item's detail pane | 12 |
| `UI_ZeD_Mods_ListCannotWith` | `Cannot run with` | Mod manager: caps heading in the detail pane over the mods it is incompatible with | 20 |
| `UI_ZeD_Mods_ListNeeds` | `Needs` | Mod manager: caps heading in the detail pane over the mods it needs | 20 |
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
| `UI_ZeD_Mods_ProfLoadingIt` | `Loading it` | Mod manager: caps heading on the Profiles page over what loading the profile does | 16 |
| `UI_ZeD_Mods_ProfMissing` | `Not installed %1: stays off` | Mod manager: what loading the profile does. %1 how many | - |
| `UI_ZeD_Mods_ProfNoChange` | `Changes nothing: these are the mods on now` | Mod manager: what loading the profile does | - |
| `UI_ZeD_Mods_ProfNothingOnOff` | `Turns nothing on or off` | Mod manager: what loading the profile does | - |
| `UI_ZeD_Mods_ProfPlain` | `Plain Project Zomboid` | Mod manager: the picked No mods profile's facts | - |
| `UI_ZeD_Mods_ProfSaved` | `saved %1` | Mod manager: the picked profile's facts. %1 is the date it was saved | - |
| `UI_ZeD_Mods_ProfSortedByRules` | `Sorted by the mods' own rules` | Mod manager: under a profile's load order when it keeps none | - |
| `UI_ZeD_Mods_ProfTurnsOff` | `Turns off %1` | Mod manager: what loading the profile does. %1 how many | - |
| `UI_ZeD_Mods_ProfTurnsOn` | `Turns on %1` | Mod manager: what loading the profile does. %1 how many | - |
| `UI_ZeD_Mods_PromptFavourite` | `Favorite` | Mod manager: controller prompt (X button) on the mods list | 12 |
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
| `UI_ZeD_Mods_TagMissing` | `Not installed` | Mod manager: small caps tag on a Workshop tab row | 16 |
| `UI_ZeD_Mods_TagOk` | `Up to date` | Mod manager: small caps tag on a Workshop tab row | 16 |
| `UI_ZeD_Mods_TagQueued` | `Download queued` | Mod manager: small caps tag on a Workshop tab row | 16 |
| `UI_ZeD_Mods_TagUpdate` | `Update waiting` | Mod manager: small caps tag on a Workshop tab row | 16 |
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
| `UI_ZeD_Mods_VerbFavourite` | `Favorite` | Mod manager: detail pane button | 16 |
| `UI_ZeD_Mods_VerbHide` | `Fine, hide this` | Mod manager: button that hides a conflict | 20 |
| `UI_ZeD_Mods_VerbLoadAfter` | `Load %1 after it` | Mod manager: button that moves a mod after the winner in the load order. %1 is its (shortened) name | - |
| `UI_ZeD_Mods_VerbShowAgain` | `Show again` | Mod manager: button that shows hidden conflicts again | 14 |
| `UI_ZeD_Mods_VerbUnfavourite` | `Unfavorite` | Mod manager: detail pane button | 16 |
| `UI_ZeD_Mods_VersionRange` | `%1 to %2` | Mod manager: the game versions a mod supports. %1 lowest, %2 highest (either may be 'any') | - |
| `UI_ZeD_Mods_WhyCollection` | `A collection: its items show in this list on their own as Steam fetches them.` | Mod manager: note in the Workshop item's pane | - |
| `UI_ZeD_Mods_WhyFetching` | `Steam is fetching it on its own. This screen notices when it lands.` | Mod manager: note in the Workshop item's pane | - |
| `UI_ZeD_Mods_WhyFile` | `%1 loads later, so its copy is the one the game uses; %2's copy never runs.` | Mod manager: explains a Lua file conflict. %1 the winning mod, %2 the losing mod | - |
| `UI_ZeD_Mods_DTabAbout` | `About` | Mod manager, a mod's info pane: folder tab with what the pane always showed | - |
| `UI_ZeD_Mods_DTabOptions` | `Options` | Mod manager, info pane: folder tab with the mod's own options | - |
| `UI_ZeD_Mods_DTabSandbox` | `Sandbox` | Mod manager, info pane: folder tab with the sandbox settings the mod adds to each game | - |
| `UI_ZeD_Mods_DTabConflicts` | `Conflicts` | Mod manager, info pane: folder tab with the mod's conflicts | - |
| `UI_ZeD_Mods_DTabCount` | `%1 %2` | Mod manager, info pane: a tab with its count. %1 the tab's name, %2 how many | - |
| `UI_ZeD_Mods_OptHead` | `Options` | Mod manager, Options tab: section heading | - |
| `UI_ZeD_Mods_OptHeadNote` | `yours, for every game \| kept as you change them` | Mod manager, Options tab: small note at the heading's right; the options are the player's, kept for every game, saved as soon as they change | - |
| `UI_ZeD_Mods_OptInOptions` | `set in Options` | Mod manager, Options tab: in place of a control (a key or a typed value) that is changed in the Options window | - |
| `UI_ZeD_Mods_OptNone` | `This mod has no options of its own.` | Mod manager, Options tab: the mod has no options | - |
| `UI_ZeD_Mods_OptTurnOn` | `Turn it on to see its options. A mod's options are made by its own code, and that code only runs while the mod is on. After Turn on and the reload, they show here.` | Mod manager, Options tab, a mod that is off | - |
| `UI_ZeD_Mods_OptAfterReload` | `Its options show after the reload: its code has not run yet.` | Mod manager, Options tab: a mod just turned on (its code runs after the reload) | - |
| `UI_ZeD_Mods_OptSandboxStillOne` | `Its %1 sandbox setting can be read now, in the Sandbox tab.` | Mod manager, Options tab of a mod that is off: its sandbox setting can still be read. %1 is 1 | - |
| `UI_ZeD_Mods_OptSandboxStill` | `Its %1 sandbox settings can be read now, in the Sandbox tab.` | Mod manager, Options tab of a mod that is off: its sandbox settings can still be read. %1 how many | - |
| `UI_ZeD_Mods_OptZeDOwn` | `ZeD's own options are in Options, ZeD setup.` | Mod manager, Options tab of ZeD itself | - |
| `UI_ZeD_Mods_VerbOpenOptions` | `Open in Options` | Mod manager, Options tab: button that opens the Options window on its Mods page | - |
| `UI_ZeD_Mods_ValueOn` | `On` | Mod manager: a tick box option's value, in the help band's default | - |
| `UI_ZeD_Mods_ValueOff` | `Off` | Mod manager: a tick box option's value, in the help band's default | - |
| `UI_ZeD_Mods_SayDefaults` | `%1: options back to their defaults.` | Mod manager: note after Defaults. %1 the mod's name | - |
| `UI_ZeD_Mods_VerbResetSettings` | `Reset settings` | Mod manager, Options tab: button that puts the mod's options back to their defaults and empties its settings files (asks first in the strip) | 20 |
| `UI_ZeD_Mods_FilesHead` | `Settings files` | Mod manager, Options tab: section heading over the files the mod keeps | - |
| `UI_ZeD_Mods_FilesHeadNote` | `in Zomboid/Lua` | Mod manager, Options tab: small note at the Settings files heading's right (the folder name stays as written) | - |
| `UI_ZeD_Mods_FilesLooking` | `Reading its code for the files it keeps...` | Mod manager, Options tab: while the mod's code is read for file names | - |
| `UI_ZeD_Mods_FilesNone` | `It keeps no settings files in Zomboid/Lua.` | Mod manager, Options tab: a mod with no options and no settings files | - |
| `UI_ZeD_Mods_FileWhyNamed` | `named in its code` | Mod manager, Options tab: small note at a file's right: the mod's code names this file | 22 |
| `UI_ZeD_Mods_FileWhyId` | `named after the mod` | Mod manager, Options tab: small note at a file's right: the file's name holds the mod's id | 22 |
| `UI_ZeD_Mods_FileWhyPart` | `its part only` | Mod manager, Options tab: small note at the right of a file many mods share: only this mod's part is reset | 22 |
| `UI_ZeD_Mods_FileOldOptions` | `%1, part [%2] (Mod Options, Build 41)` | Mod manager, Options tab: the old Mod Options library's shared file. %1 the file name, %2 the section names | - |
| `UI_ZeD_Mods_FilesHow` | `Reset settings copies each file to Zomboid/Lua/%1/ first, then empties it: the game lets a mod empty a file, not delete it. The mod then starts from its own defaults.` | Mod manager, Options tab: under the settings files. %1 the backup folder (ZeD_reset/<mod id>, stays as written) | - |
| `UI_ZeD_Mods_AskReset` | `Reset %1: %2. Copies go to Zomboid/Lua/%3/.` | Mod manager, the strip: the question before Reset settings. %1 the mod's name, %2 what is reset (the two parts below), %3 the backup folder | - |
| `UI_ZeD_Mods_ResetPartOptions` | `its %1 options back to their defaults` | Mod manager, the strip's question: the options part. %1 how many | - |
| `UI_ZeD_Mods_ResetPartOptionsOne` | `its option back to its default` | Mod manager, the strip's question: the options part, one option. %1 is 1 | - |
| `UI_ZeD_Mods_ResetPartFiles` | `%1 files emptied (%2)` | Mod manager, the strip's question: the files part. %1 how many, %2 their names | - |
| `UI_ZeD_Mods_ResetPartFilesOne` | `%2 emptied` | Mod manager, the strip's question: the files part, one file. %1 is 1, %2 its name | - |
| `UI_ZeD_Mods_AskResetShort` | `Reset %1: %2. Copies kept in Zomboid/Lua/%3/.` | Mod manager, the strip: the question before Reset settings when the full one does not fit (the pane lists the files). %1 the mod's name, %2 what is reset, %3 the backup folder | - |
| `UI_ZeD_Mods_ResetPartOptionsShort` | `%1 options to their defaults` | Mod manager, the strip's short question: the options part. %1 how many | - |
| `UI_ZeD_Mods_ResetPartOptionsShortOne` | `%1 option to its default` | Mod manager, the strip's short question: the options part. %1 is 1 | - |
| `UI_ZeD_Mods_ResetPartFilesShort` | `%1 files emptied` | Mod manager, the strip's short question: the files part. %1 how many | - |
| `UI_ZeD_Mods_ResetPartFilesShortOne` | `%1 file emptied` | Mod manager, the strip's short question: the files part. %1 is 1 | - |
| `UI_ZeD_Mods_SayReset` | `%1: settings reset. The old files are in Zomboid/Lua/%2/.` | Mod manager: note after Reset settings. %1 the mod's name, %2 the backup folder | - |
| `UI_ZeD_Mods_SayResetFailed` | `%1 files could not be copied and were left as they were.` | Mod manager: added to the note after Reset settings. %1 how many | - |
| `UI_ZeD_Mods_SayResetFailedOne` | `One file could not be copied and was left as it was.` | Mod manager: added to the note after Reset settings. %1 is 1 | - |
| `UI_ZeD_Mods_SayResetReload` | `Reload so it reads them again.` | Mod manager: added to the note after Reset settings: the mod is running and reads its files when its code runs | - |
| `UI_ZeD_Mods_PendingReset` | `Settings of %1 reset. A reload has it read them again, no restart.` | Mod manager, the strip: a mod's settings were reset and a reload has its code read them. %1 the mod's name | - |
| `UI_ZeD_Mods_HelpTitled` | `%1. %2` | Mod manager, help band: a setting's name, then its help text. %1 name, %2 help | - |
| `UI_ZeD_Mods_SbHead` | `Sandbox settings` | Mod manager, Sandbox tab: section heading | - |
| `UI_ZeD_Mods_SbHeadNote` | `for each game \| defaults shown` | Mod manager, Sandbox tab: small note at the heading's right | - |
| `UI_ZeD_Mods_SbHeadNoteOff` | `readable while it is off \| defaults shown` | Mod manager, Sandbox tab of a mod that is off: small note at the heading's right | - |
| `UI_ZeD_Mods_SbNone` | `This mod adds no sandbox settings.` | Mod manager, Sandbox tab: the mod adds none | - |
| `UI_ZeD_Mods_SbWhere` | `Chosen when you start a game: New game, Sandbox, page %1. Read from the mod's own files.` | Mod manager, Sandbox tab: where the settings are chosen. %1 the page names in the sandbox screen | - |
| `UI_ZeD_Mods_SbWhereNoPage` | `Chosen when you start a game: New game, Sandbox. Read from the mod's own files.` | Mod manager, Sandbox tab: where the settings are chosen (no page named) | - |
| `UI_ZeD_Mods_SbRange` | `Range: %1 to %2` | Mod manager, help band: a number setting's range. %1 lowest, %2 highest | - |
| `UI_ZeD_Mods_ChipSameText` | `Same text` | Mod manager: tag on a mod's row: it shares a file with another mod, word for word the same (no conflict). | - |
| `UI_ZeD_Mods_ChipPicked` | `Picked` | Mod manager: tag on a mod's row: its conflict is settled by files picked one by one. | - |
| `UI_ZeD_Mods_ChipFilesOne` | `%1 file` | Mod manager: tag on the ZeD picks row: how many files it holds. %1 is 1. | - |
| `UI_ZeD_Mods_ChipFilesMany` | `%1 files` | Mod manager: tag on the ZeD picks row: how many files it holds. %1 how many. | - |
| `UI_ZeD_Mods_SameTextOne` | `Same file as %1, same text` | Mod manager, Conflicts tab: card title. %1 the other mod | - |
| `UI_ZeD_Mods_SameTextMany` | `Same %1 files as %2, same text` | Mod manager, Conflicts tab: card title. %1 how many files, %2 the other mod | - |
| `UI_ZeD_Mods_SameTextWhy` | `Both copies are the same, word for word: whichever one loads, nothing changes.` | Mod manager, Conflicts tab: why same-text copies are no conflict | - |
| `UI_ZeD_Mods_PickedOne` | `%1 file picked from %2` | Mod manager, Conflicts tab: card title. %1 is 1, %2 the mod the file was picked from | - |
| `UI_ZeD_Mods_PickedMany` | `%1 files picked from %2` | Mod manager, Conflicts tab: card title. %1 how many files, %2 the mod they were picked from | - |
| `UI_ZeD_Mods_PickedMore` | `and %1 more` | Mod manager, Conflicts tab: under the first picked files listed. %1 how many more | - |
| `UI_ZeD_Mods_PickedKeepsOne` | `%1 keeps the other %2 shared file. The picked copies sit in ZeD picks, which loads last.` | Mod manager, Conflicts tab. %1 the other mod, %2 is 1. ZeD picks is the helper mod's name | - |
| `UI_ZeD_Mods_PickedKeeps` | `%1 keeps the other %2 shared files. The picked copies sit in ZeD picks, which loads last.` | Mod manager, Conflicts tab. %1 the other mod, %2 how many files. ZeD picks is the helper mod's name | - |
| `UI_ZeD_Mods_VerbPickFiles` | `Choose file by file...` | Mod manager, Conflicts tab: button that opens the picker (choose a copy per file) | - |
| `UI_ZeD_Mods_VerbChangePicks` | `Change picks...` | Mod manager, Conflicts tab: button that opens the picker again | - |
| `UI_ZeD_Mods_VerbUndoPicks` | `Undo picks` | Mod manager, Conflicts tab: button that removes the picks (load order decides again) | - |
| `UI_ZeD_Mods_SayPicksUndone` | `Picks undone. Reload to put load order back in charge.` | Mod manager: note after Undo picks | - |
| `UI_ZeD_Mods_SayPicksKept` | `Picks kept (%1 files). Reload to put them to work.` | Mod manager: note after Use these picks. %1 how many files | - |
| `UI_ZeD_Mods_TitlePicks` | `Choose files` | Mod manager: window title of the picker | - |
| `UI_ZeD_Mods_PickShared` | `Shared %1 \| picked %2` | Picker: list heading. %1 shared files, %2 picked | - |
| `UI_ZeD_Mods_PickChipPicked` | `%1 (picked)` | Picker: tag on a file whose copy is picked. %1 the mod | - |
| `UI_ZeD_Mods_PickDiffOne` | `%1 line differs` | Picker: how many lines differ between the two copies. %1 is 1 | - |
| `UI_ZeD_Mods_PickDiffMany` | `%1 lines differ` | Picker: how many lines differ between the two copies. %1 how many | - |
| `UI_ZeD_Mods_PickChoose` | `In both mods. Choose whose copy the game runs.` | Picker: under the file's path | - |
| `UI_ZeD_Mods_PickRunsNow` | `%1 lines \| loads later: runs now` | Picker: under a mod's name on its choice card. %1 the copy's line count | - |
| `UI_ZeD_Mods_PickLoadsLater` | `%1 lines \| loads later` | Picker: under the later mod's name while the other copy is picked. %1 lines | - |
| `UI_ZeD_Mods_PickNeverRuns` | `%1 lines \| loads earlier: never runs` | Picker: under the earlier mod's name. %1 lines | - |
| `UI_ZeD_Mods_PickPickedSub` | `%1 lines \| picked: runs after a reload` | Picker: under the picked mod's name. %1 lines | - |
| `UI_ZeD_Mods_PickWarn` | `Mixing copies can break a mod whose other files expect its own copy. Any error shows in Messages, and Undo picks puts everything back. Single player only.` | Picker: the warning at the foot | - |
| `UI_ZeD_Mods_BtnUsePicks` | `Use these picks` | Picker: the strip's button that keeps the picks | - |
| `UI_ZeD_Mods_PickStripOne` | `%1 file from %2. %3 keeps the other %4.` | Picker: the strip. %1 is 1, %2 the picked mod, %3 the other mod, %4 the files it keeps | - |
| `UI_ZeD_Mods_PickStripMany` | `%1 files from %2. %3 keeps the other %4.` | Picker: the strip. %1 files picked, %2 the picked mod, %3 the other mod, %4 the files it keeps | - |
| `UI_ZeD_Mods_PickStripNone` | `Choose a copy for any file. The rest stay with load order.` | Picker: the strip before anything is picked | - |
| `UI_ZeD_Mods_PromptOtherCopy` | `Other copy` | Picker, controller prompt for A on a file: switch to the other mod's copy | - |
| `UI_ZeD_Mods_PendingPicks` | `Picked files changed. A reload puts them in place, no restart.` | Mod manager, the strip: the picked copies were rewritten and a reload puts them in place | - |
| `UI_ZeD_Mods_OffHead` | `If you turn it off` | Mod manager: Mod manager, About tab: section heading: what turning the mod off does to a save | - |
| `UI_ZeD_Mods_OffForSave` | `For the save %1:` | Mod manager: About tab, the list is a save's own (Load game, More, Choose mods). %1 the save's folder name | - |
| `UI_ZeD_Mods_OffForMain` | `Saves keep their own mod lists, so this list changes new games only. In a save's own list (Load game, More, Choose mods), turning it off would mean:` | Mod manager: About tab, the main mod list | - |
| `UI_ZeD_Mods_OffSafe` | `Safe to turn off` | Mod manager: About tab: grade (green dot) | - |
| `UI_ZeD_Mods_OffCareful` | `Careful: the save loses things` | Mod manager: About tab: grade (yellow dot) | - |
| `UI_ZeD_Mods_OffUnchecked` | `Not checked: it is not running now` | Mod manager: About tab: grade (yellow dot); the mod's scripts are not loaded, so its items cannot be counted | - |
| `UI_ZeD_Mods_OffUnsafe` | `Not safe for a game in progress` | Mod manager: About tab: grade (red dot) | - |
| `UI_ZeD_Mods_OffMapOne` | `It adds a map (%1 folder). Its places are part of the world: without it they are empty, and a character standing in them can load into nothing.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffMapMany` | `It adds a map (%1 folders). Its places are part of the world: without it they are empty, and a character standing in them can load into nothing.` | Mod manager: About tab. %1 how many map folders | - |
| `UI_ZeD_Mods_OffTilesOne` | `It adds %1 set of tiles. Anything built or placed from them goes missing from the world.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffTilesMany` | `It adds %1 sets of tiles. Anything built or placed from them goes missing from the world.` | Mod manager: About tab. %1 how many | - |
| `UI_ZeD_Mods_OffItemsOne` | `It adds %1 item of its own. In the save it disappears: from you, your bags, containers and the ground.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffItemsMany` | `It adds %1 items of its own. In the save they disappear: from you, your bags, containers and the ground.` | Mod manager: About tab. %1 how many | - |
| `UI_ZeD_Mods_OffVehiclesOne` | `It adds %1 vehicle. In the save it is removed, with what is in it.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffVehiclesMany` | `It adds %1 vehicles. In the save they are removed, with what is in them.` | Mod manager: About tab. %1 how many | - |
| `UI_ZeD_Mods_OffBuildingsOne` | `It adds %1 thing you can build or place. One already in the world goes missing.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffBuildingsMany` | `It adds %1 things you can build or place. Ones already in the world go missing.` | Mod manager: About tab. %1 how many | - |
| `UI_ZeD_Mods_OffRecipesOne` | `Its %1 recipe goes away; what you already made stays, unless it is one of its own items.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffRecipesMany` | `Its %1 recipes go away; what you already made stays, unless it is one of its own items.` | Mod manager: About tab. %1 how many | - |
| `UI_ZeD_Mods_OffOverridesOne` | `It changes %1 of the game's own items or recipes: it goes back to the game's version.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffOverridesMany` | `It changes %1 of the game's own items or recipes: they go back to the game's version.` | Mod manager: About tab. %1 how many | - |
| `UI_ZeD_Mods_OffNotChecked` | `It is not running now (it is off in the main list), so its items and vehicles cannot be counted. Its map and tiles are checked.` | Mod manager: About tab | - |
| `UI_ZeD_Mods_OffRegistries` | `It adds its own game lists (such as traits or tags). A character who has one of its traits may lose it.` | Mod manager: About tab | - |
| `UI_ZeD_Mods_OffSandboxOne` | `Its %1 sandbox setting stays in the save, unused, until the mod is back.` | Mod manager: About tab. %1 is 1 | - |
| `UI_ZeD_Mods_OffSandboxMany` | `Its %1 sandbox settings stay in the save, unused, until the mod is back.` | Mod manager: About tab. %1 how many | - |
| `UI_ZeD_Mods_OffCodeOnly` | `It adds no items, vehicles, map or tiles: nothing in a save is made of it. Its options and saved data wait for it.` | Mod manager: About tab: why a mod is safe to turn off | - |
| `UI_ZeD_Mods_OffAlsoOff` | `It also turns off %1 (they need it):` | Mod manager: About tab. %1 a list of the mods that need this one | - |
| `UI_ZeD_Mods_OffDepGrade` | `%1: %2` | Mod manager: About tab: a mod that turns off with it and its grade. %1 the mod, %2 the grade | - |
| `UI_ZeD_Mods_AskOffUnsafe` | `Not safe for %2: %1 has a map or tiles in that world. Turn it off?` | Mod manager: The strip's question when turning a mod off in a save's own list. %1 the mod, %2 the save | - |
| `UI_ZeD_Mods_AskOffCareful` | `%2 loses what %1 added (items, vehicles). Turn it off?` | Mod manager: The strip's question. %1 the mod, %2 the save | - |
| `UI_ZeD_Mods_AskOffUnchecked` | `%1 is not running now, so it was not checked. %2 may lose what it added. Turn it off?` | Mod manager: The strip's question. %1 the mod, %2 the save | - |
| `UI_ZeD_Mods_BtnKeepOn` | `Keep it on` | Mod manager: The strip's button that answers the question: the mod stays on | - |
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

## Msg

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Msg_Answered` | `answered %1` | Messages: a card's head once its button was pressed; %1 = the button ("OK") | 24 |
| `UI_ZeD_Msg_AtStart` | `at game start` | Messages: a card's head, after the time, for a note that came in the first minute of play | 20 |
| `UI_ZeD_Msg_Choose` | `Choose` | Messages: the strip, the A button's word | 12 |
| `UI_ZeD_Msg_Clear` | `Delete` | Messages: footer button, removes the chosen mod's messages | 12 |
| `UI_ZeD_Msg_Copied` | `Copied` | Messages: the Copy for a bug report button after it was pressed | 18 |
| `UI_ZeD_Msg_Copy` | `Copy for a bug report` | Messages: an error card's button, puts that mod's errors on the clipboard | 26 |
| `UI_ZeD_Msg_CountStat` | `%1 kept` | Messages: the title bar's count, and the ZeD wheel's Messages slice; %1 = how many messages | 14 |
| `UI_ZeD_Msg_DpadMove` | `D-pad Move` | Messages: the strip on a controller | 14 |
| `UI_ZeD_Msg_ErrorCount` | `%1 errors from %2` | Messages: an error card's first line; %1 = how many, %2 = the mod's name | - |
| `UI_ZeD_Msg_Errors` | `Errors` | Messages: the list's second heading (mods whose code made Lua errors) | 14 |
| `UI_ZeD_Msg_FromMods` | `From mods` | Messages: the list's first heading (mods that opened a note) | 14 |
| `UI_ZeD_Msg_Help` | `A mod's notes and errors land here instead of on top of the game. Questions still ask at once.` | Messages: the help line above the footer | - |
| `UI_ZeD_Msg_KindAnswered` | `Answered` | Messages: a card's tag, a question you already answered (a copy) | 10 |
| `UI_ZeD_Msg_KindError` | `Error` | Messages: a card's tag, a mod's Lua errors | 10 |
| `UI_ZeD_Msg_KindNote` | `Note` | Messages: a card's tag, a mod's note (one OK button) | 10 |
| `UI_ZeD_Msg_LampNew` | `Messages \| %1 new` | The belt's envelope: its name chip on hover; %1 = how many are new | 22 |
| `UI_ZeD_Msg_MarkAllRead` | `Mark all read` | Messages: footer button (the main one) | 16 |
| `UI_ZeD_Msg_New` | `%1 new` | The ZeD wheel's Messages slice, its second line; %1 = how many are new | 10 |
| `UI_ZeD_Msg_None` | `No messages.` | Messages: an empty list; the ZeD wheel's Messages slice when nothing is kept | - |
| `UI_ZeD_Msg_NoneHelp` | `Notes and errors from other mods land here.` | Messages: the empty right side | - |
| `UI_ZeD_Msg_ShowPopups` | `Show this mod's notes as pop-ups` | Messages: footer tick box for the chosen mod (its notes then open on top of the game, as before) | - |
| `UI_ZeD_Msg_TheGame` | `Project Zomboid` | Messages: the source name for an error no mod is named in | - |
| `UI_ZeD_Msg_Title` | `Messages` | The Messages window's title; the ZeD wheel slice; the belt envelope's chip when nothing is new | 14 |
| `UI_ZeD_Msg_ToastError` | `Error` | A toast's tag when a mod's error comes | 8 |
| `UI_ZeD_Msg_ToastErrors` | `%1 errors` | An error toast's text; %1 = how many so far | 12 |
| `UI_ZeD_Msg_ToastMod` | `Mod` | A toast's tag when a mod's note comes | 8 |
| `UI_ZeD_Msg_ToastNote` | `a note` | A note toast's text, after the mod's name | 12 |
| `UI_ZeD_Msg_When` | `Day %1, %2` | Messages: a card's time; %1 = the day of play, %2 = the time ("7:42") | - |
| `UI_ZeD_Msg_YouAnswered` | `You answered %1.` | Messages: under a copied question; %1 = the button you pressed | - |
| `UI_ZeD_Msg_HelpRow` | `Show the messages from %1.` | Messages: help line over a source in the list on the left; %1 = the mod's name | - |
| `UI_ZeD_Msg_HelpCardButton` | `Press %1, the mod's own button.` | Messages: help line over a button a mod put on its own message card; %1 = the button's label | - |
| `UI_ZeD_Msg_HelpCopy` | `Copy this report to the clipboard, ready to paste into a bug report.` | Messages: help line over the Copy button on an error report | - |
| `UI_ZeD_Msg_HelpPopups` | `Choose whether this mod's notes pop up in the game or wait here.` | Messages: help line over the footer check box that sets whether a mod's notes pop up in the game or wait in this window | - |
| `UI_ZeD_Msg_HelpClear` | `Delete every message from this source.` | Messages: help line over the footer Delete button, and over the Yes button of the delete question | - |
| `UI_ZeD_Msg_HelpAllRead` | `Mark every message as read.` | Messages: help line over the Mark all read button | - |
| `UI_ZeD_Msg_DeleteAsk` | `Delete all notes? They can't be brought back.` | Messages: the footer question after pressing Delete on a source's notes; the footer then offers a yes and a no | - |
| `UI_ZeD_Msg_DeleteAskErrors` | `Delete all errors? They can't be brought back.` | Messages: the footer question after pressing Delete on a source's errors; the footer then offers a yes and a no | - |
| `UI_ZeD_Msg_HelpAskNo` | `Keep the messages.` | Messages: help line over the No button of the delete question | - |

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
| `UI_ZeD_Notebook_HelpInto` | `Pick where Save writes the entry: the log only, or a notebook too.` | Character window, Journal tab, Journal sub-tab: help line over the Into pill left of Save | - |
| `UI_ZeD_Notebook_HelpPick` | `Show %1.` | Character window, Journal tab, Notebooks sub-tab: help line over a notebook's tab; %1 = the notebook's name | - |

## ObjCard

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_ObjCard_CloseCard` | `Close card` | Controller button prompt (B) while an object card is open and nothing is being confirmed | 16 |
| `UI_ZeD_ObjCard_Done` | `Done` | Object cards, cooking rows: right of the bar on cooked food | 6 |
| `UI_ZeD_ObjCard_GaugeE` | `E` | Object cards, fuel gauge face: the empty end of the needle's arc (one letter) | 2 |
| `UI_ZeD_ObjCard_GaugeF` | `F` | Object cards, fuel gauge face: the full end of the needle's arc (one letter) | 2 |
| `UI_ZeD_ObjCard_Hours` | `%1 h` | Object cards: a duration of whole hours (e.g. 3 h) | 10 |
| `UI_ZeD_ObjCard_HoursMinutes` | `%1 h %2 m` | Object cards: a duration of hours and minutes (e.g. 2 h 20 m) in times left and fuel left; h and m stand for hours and minutes | 14 |
| `UI_ZeD_ObjCard_MinLeft` | `%1m` | Object cards, cooking rows: minutes left to cook or to burn, right of the bar (e.g. 12m) | 6 |
| `UI_ZeD_ObjCard_Minutes` | `%1 m` | Object cards: a duration under an hour (e.g. 45 m) | 10 |
| `UI_ZeD_ObjCard_TagRaw` | `Raw` | Object cards, cooking rows: tag on raw food while the heat is off (in a bordered tag) | 10 |
| `UI_ZeD_ObjCard_WhereNearby` | `Nearby` | Object cards, pick lists: where an item sits when it is not in the inventory and not in a named bag | 12 |
| `UI_ZeD_ObjCard_HelpBack` | `Back: close this card` | Object cards: help line over the Back button that closes the card | - |
| `UI_ZeD_ObjCard_HelpCancel` | `Cancel: leave things as they are` | Object cards: help line over the Cancel button of a footer question | - |
| `UI_ZeD_ObjCard_HelpMore` | `Actions you can't do yet: press to see what they need` | Object cards: help line over the folded row of actions you cannot take yet | - |
| `UI_ZeD_ObjCard_HelpNext` | `Next: the next one in reach` | Object cards: help line over the arrow button that goes to the next object in reach | - |
| `UI_ZeD_ObjCard_HelpPrev` | `Previous: the previous one in reach` | Object cards: help line over the arrow button that goes to the previous object in reach | - |
| `UI_ZeD_ObjCard_Next` | `Next` | Object cards: hover hint of the arrow button that goes to the next object in reach (icon-only button) | - |
| `UI_ZeD_ObjCard_Prev` | `Previous` | Object cards: hover hint of the arrow button that goes to the previous object in reach (icon-only button) | - |

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
| `UI_ZeD_Options_Defaults` | `Reset to defaults` | (existing) | - |
| `UI_ZeD_Options_Discard` | `Discard changes` | Options screen: strip button, footer prompt: throw the changes away | 12 |
| `UI_ZeD_Options_Find` | `Find:` | Options screen: label of the search box over the page list | 10 |
| `UI_ZeD_Options_FirstRunNote` | `First time with ZeD: these set the game up for ZeD's look. Change what you like, then Apply. They stay here, and each game setting is in its own group too.` | Options screen: note on top of ZeD setup the first time the game starts with ZeD | - |
| `UI_ZeD_Options_GoBack` | `Go back` | Options screen: strip button that returns to the previous screen settings | 12 |
| `UI_ZeD_Options_GroupControls` | `Controls` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupDisplay` | `Display` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupGraphics` | `Graphics` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupInterface` | `Interface` | Options screen (groups): page list entry | 22 |
| `UI_ZeD_Options_GroupZed` | `ZeD setup` | Options screen (groups): page list entry: ZeD's own settings and the game settings its look depends on | 22 |
| `UI_ZeD_Options_HeadGameSettings` | `Game settings ZeD uses` | Options screen (groups): section heading in ZeD setup over the game's settings that ZeD depends on (shown in caps) | - |
| `UI_ZeD_Options_HelpDeadzone` | `How far a stick must move before the game counts it, for the controller chosen under Test Controller.` | Options screen: help band for the deadzone row | - |
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
| `UI_ZeD_Options_PickController` | `Choose a Test Controller below` | Options screen: value of the deadzone row when no controller is picked | - |
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
| `UI_ZeD_Options_ZedChords` | `Quick actions (controller)` | ZeD setup: section header over the twelve bumper chords | 30 |
| `UI_ZeD_Options_ZedControls` | `Controls` | (existing) | - |
| `UI_ZeD_Options_ZedHud` | `HUD` | (existing) | - |
| `UI_ZeD_Options_ZedLook` | `Look` | (existing) | - |
| `UI_ZeD_Options_ZedMessages` | `Messages` | ZeD setup: the section heading for the Messages settings | 20 |
| `UI_ZeD_Options_ZedPutBack` | `Put things back` | ZeD setup: section header over the Put things back switch | 30 |
| `UI_ZeD_Options_ZedTrouble` | `Troubleshooting` | (existing) | - |
| `UI_ZeD_Options_ZedWindows` | `Windows` | (existing) | - |
| `UI_ZeD_Options_ZedSandbox` | `Sandbox` | Options, ZeD setup: group heading | 24 |
| `UI_ZeD_Options_UnderSandboxIG` | `A line in the pause window` | Options, ZeD setup: the line under the Sandbox switch's name | - |

## Papers

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Papers_Count` | `%1 read of %2 carried` | Character window, Journal tab, Papers sub-tab: line over the list (%1 = pieces read, %2 = pieces carried) | 40 |
| `UI_ZeD_Papers_CountWithPlaces` | `%1 read of %2 carried \| %3 with places` | Character window, Journal tab, Papers sub-tab: line over the list when some read pieces name places (%3 = how many) | 60 |
| `UI_ZeD_Papers_FilterFlyers` | `Flyers` | Character window, Journal tab, Papers sub-tab: filter pill for flyers and brochures | 10 |
| `UI_ZeD_Papers_FilterNews` | `News` | Character window, Journal tab, Papers sub-tab: filter pill for newspapers | 10 |
| `UI_ZeD_Papers_FilterOnMap` | `On map` | Character window, Journal tab, Papers sub-tab: filter pill for read pieces that name places | 10 |
| `UI_ZeD_Papers_Find` | `Find a paper...` | Character window, Journal tab, Papers sub-tab: placeholder in the search box | 30 |
| `UI_ZeD_Papers_HeadStories` | `On this page: %1 stories` | Papers quick look: heading over the piece's text when it has several stories (%1 = how many) | 36 |
| `UI_ZeD_Papers_HeadWords` | `The words` | Papers quick look: heading over the piece's text | 24 |
| `UI_ZeD_Papers_NoneCarried` | `Nothing to read on you` | Character window, Journal tab, Papers sub-tab: empty list, the character carries no paper | 40 |
| `UI_ZeD_Papers_NoneMatch` | `None of these on you` | Character window, Journal tab, Papers sub-tab: empty list, nothing matches the filter or search | 40 |
| `UI_ZeD_Papers_OpenFull` | `Open full` | Papers quick look and Notebooks sub-tab: button that opens the full reader or full page (shown in sentence case) | 16 |
| `UI_ZeD_Papers_PlaceMany` | `%1 places` | Character window, Journal tab, Papers sub-tab: second line of a list row when the piece names several places (%1 = 2 to 5) | 12 |
| `UI_ZeD_Papers_PlaceOne` | `1 place` | Character window, Journal tab, Papers sub-tab: second line of a list row when the piece names one place | 12 |
| `UI_ZeD_Papers_ShowPlaceN` | `Show place %1` | Papers quick look: button for the nth place when a piece names several (%1 = 1 to 5) | 20 |
| `UI_ZeD_Papers_StateRead` | `Read` | Character window, Journal tab, Papers sub-tab: right side of a list row, piece read (next to a green dot) | 14 |
| `UI_ZeD_Papers_StateUnread` | `Not read yet` | Character window, Journal tab, Papers sub-tab: right side of a list row, piece not read (next to a grey dot) | 16 |
| `UI_ZeD_Papers_TooDark` | `Too dark to read` | Papers quick look: dim line under the disabled Read button | 30 |
| `UI_ZeD_Papers_HelpBack` | `Back to the list.` | Character window, Journal tab, Papers sub-tab: help line over the Back button of a piece being read | - |
| `UI_ZeD_Papers_HelpFilter` | `Show %1.` | Character window, Journal tab, Papers sub-tab: help line over a filter pill; %1 = the filter's name | - |
| `UI_ZeD_Papers_HelpOpen` | `Open %1.` | Character window, Journal tab, Papers sub-tab: help line over a row in the list; %1 = the piece's title | - |
| `UI_ZeD_Papers_HelpRead` | `Read it. The words, the read mark and the places come from reading.` | Character window, Journal tab, Papers sub-tab: help line over the Read button in a piece's quick look, shown while the piece is unread | - |

## PartAbbr

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_PartAbbr_LeftFoot` | `L. foot` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftForearm` | `L. forearm` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftHand` | `L. hand` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftShin` | `L. shin` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftThigh` | `L. thigh` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LeftUpperArm` | `L. uarm` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_LowerTorso` | `L. torso` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightFoot` | `R. foot` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightForearm` | `R. forearm` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightHand` | `R. hand` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightShin` | `R. shin` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightThigh` | `R. thigh` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_RightUpperArm` | `R. uarm` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |
| `UI_ZeD_PartAbbr_UpperTorso` | `U. torso` | Short body part name for the uncovered-zone pills (kept tight, flex-wrapped) | 11 |

## Place

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Place_Degrees` | `Degrees` | 3D placement card: right side of the ROTATION heading | 12 |
| `UI_ZeD_Place_Item` | `Item` | 3D placement card: card title when the item has no name | 20 |
| `UI_ZeD_Place_WithinTile` | `Within the tile` | 3D placement card: right side of the MOVEMENT heading | 18 |
| `UI_ZeD_Place_HelpDone` | `Done: keep the placement and close the card` | 3D placement card: help line over the Done button | - |
| `UI_ZeD_Place_HelpNudgeDown` | `Nudge down: a small step less on %1` | 3D placement card: help line over the minus button beside a slider; %1 = the slider's axis name | - |
| `UI_ZeD_Place_HelpNudgeUp` | `Nudge up: a small step more on %1` | 3D placement card: help line over the plus button beside a slider; %1 = the slider's axis name | - |
| `UI_ZeD_Place_HelpRevert` | `Revert: put the item back as it was` | 3D placement card: help line over the Revert button | - |
| `UI_ZeD_Place_HelpSlider` | `Slider: drag to place the item` | 3D placement card: help line over a placement slider | - |

## Power

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Power_CanName` | `%1 (%2 of %3 L)` | Generator card: a petrol can in the add-fuel list; %1 is its name, %2 how much petrol it holds, %3 its capacity | - |
| `UI_ZeD_Power_Connect` | `Connect` | Generator card: verb button (plug the generator into the building) | 14 |
| `UI_ZeD_Power_Days` | `%1 days` | Generator card: run time left under the plate when over 100 hours, e.g. 12 DAYS | 12 |
| `UI_ZeD_Power_Disconnect` | `Disconnect` | Generator card: verb button (unplug the generator from the building) | 14 |
| `UI_ZeD_Power_Fix` | `Fix` | Generator card: verb button | 10 |
| `UI_ZeD_Power_Fuel` | `Fuel` | Generator card: label of the fuel reading under the plate | 10 |
| `UI_ZeD_Power_FuelOf` | `%1 of %2 L` | Generator card: fuel in the tank under the plate, e.g. 4.5 OF 10 L | 14 |
| `UI_ZeD_Power_Fumes` | `Indoors. Running it here fills the building with toxic fumes. Move it outside first.` | Generator card: warning band (red) while the generator stands inside a building | - |
| `UI_ZeD_Power_Hrs` | `%1 hrs` | Generator card: run time left under the plate as hours and minutes, e.g. 33:20 HRS | 12 |
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
| `UI_ZeD_Power_PillRunning` | `Running` | Generator card: header pill while the generator runs | 10 |
| `UI_ZeD_Power_Powering` | `Powering` | Generator card: section heading over the list of what the generator powers | - |
| `UI_ZeD_Power_RunTimeLeft` | `Run time left` | Generator card: label of the run time under the plate (the half-width column holds about 14 letters) | 14 |
| `UI_ZeD_Power_HelpAddCan` | `Add: pour %1 into the generator` | Generator card: help line over a petrol can in the add-fuel list; %1 = the can's name | - |
| `UI_ZeD_Power_HelpConnect` | `Connect: plug the generator into the building` | Generator card: help line over the Connect button | - |
| `UI_ZeD_Power_HelpDisconnect` | `Disconnect: unplug it from the building` | Generator card: help line over the Disconnect button | - |
| `UI_ZeD_Power_HelpEngine` | `Engine switch: turn the generator on or off` | Generator card: help line over the engine switch in the picture | - |
| `UI_ZeD_Power_HelpFix` | `Fix: repair it with scrap electronics` | Generator card: help line over the Fix button | - |
| `UI_ZeD_Power_HelpFuel` | `Add fuel: pour petrol in from a can` | Generator card: help line over the Add fuel button | - |
| `UI_ZeD_Power_HelpOff` | `Turn off: stop the generator` | Generator card: help line over the Turn off button | - |
| `UI_ZeD_Power_HelpOn` | `Turn on: start the generator` | Generator card: help line over the Turn on button | - |
| `UI_ZeD_Power_HelpOutlet` | `Outlet: connect or disconnect the building's cord` | Generator card: help line over the outlet in the picture | - |
| `UI_ZeD_Power_HelpTake` | `Take: pick the generator up` | Generator card: help line over the Take button | - |
| `UI_ZeD_Power_HintConnect` | `connect it` | Generator card: what Connect does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Power_HintDisconnect` | `disconnect it` | Generator card: what Disconnect does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Power_HintFix` | `fix it` | Generator card: what Fix does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Power_HintFuel` | `add fuel` | Generator card: what Add fuel does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Power_HintOn` | `turn it on` | Generator card: what Turn on does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Power_HintTake` | `pick it up` | Generator card: what Take does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Power_NeedsCan` | `a can with petrol in your bags` | Generator card: what Add fuel needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Power_NeedsConnected` | `the generator connected` | Generator card: what Turn on needs while the generator is not connected, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Power_NeedsDisconnected` | `the generator disconnected` | Generator card: what Take needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Power_NeedsElec` | `Electricity 3` | Generator card: what Fix and Connect need, the Electrical skill level required (the game's own skill name and a level), filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Power_NeedsFuel` | `fuel in the tank` | Generator card: what Turn on needs when the tank is empty, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Power_NeedsOff` | `the generator turned off` | Generator card: what Add fuel, Fix, Connect and Take need while the generator runs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Power_NeedsScrap` | `Scrap Electronics in your bags` | Generator card: what Fix needs, the game's item name for scrap electronics, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |

## Print

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Print_Flyer` | `Flyer` | Kind of paper in the reader side column, Papers quick look and Papers list second line (the game has no word for it) | 14 |
| `UI_ZeD_Print_Paper` | `Paper` | Kind of paper when the item is none of newspaper, brochure, flyer, magazine | 14 |

## Progress

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Progress_CancelHelp` | `Cancel: stop doing this` | Any progress bar with a Cancel button (a timed action): help line over the Cancel button | - |

## Prompt

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Prompt_Back` | `Back` | Controller button legend, B prompt | 12 |
| `UI_ZeD_Prompt_Card` | `Card` | Controller button legend at the window foot, A prompt on an inventory row or equipment slot (opens its card) | 12 |
| `UI_ZeD_Prompt_DPadMove` | `D-pad Move` | Pop-up prompt controller legend, dim note: the D-pad moves between buttons | 18 |
| `UI_ZeD_Prompt_DPadMoveStep` | `D-pad Move / Step` | Pop-up prompt controller legend for the alarm clock and timer dialogs: the D-pad moves and steps values | 22 |
| `UI_ZeD_Prompt_DPadScroll` | `D-pad Scroll` | Pop-up prompt controller legend, dim note: the D-pad scrolls long text | 18 |
| `UI_ZeD_Prompt_Edit` | `Edit` | Controller button legend, X prompt on the map canvas | 12 |
| `UI_ZeD_Prompt_Fold` | `Fold` | Controller button legend, A prompt on the map's fold control | 12 |
| `UI_ZeD_Prompt_Hold` | `%1 (hold)` | Controller button legend, hold-A prompt; %1 is the action word (Use) | 18 |
| `UI_ZeD_Prompt_Hour` | `Hour` | Alarm clock dialog, label of the hour stepper row | 10 |
| `UI_ZeD_Prompt_Keyboard` | `Keyboard` | Pop-up prompt controller legend, A prompt on a text field (opens the on-screen keyboard) | 12 |
| `UI_ZeD_Prompt_Menu` | `Menu` | Controller button legend, X prompt (opens the context menu) | 12 |
| `UI_ZeD_Prompt_Minute` | `Minute` | Alarm clock dialog, label of the minute stepper row | 10 |
| `UI_ZeD_Prompt_Pin` | `Pin` | Controller button legend, X prompt on a map grid tool or a skill row | 12 |
| `UI_ZeD_Prompt_Press` | `Press` | Pop-up prompt controller legend, A prompt on a button | 12 |
| `UI_ZeD_Prompt_Recipe` | `Recipe` | Controller button legend, A prompt on a crafting, journal-recipe or build row | 12 |
| `UI_ZeD_Prompt_Reset` | `Reset` | Controller button legend, X prompt on a control that resets | 12 |
| `UI_ZeD_Prompt_Search` | `Search` | Controller button legend, A prompt on the forage stance control | 12 |
| `UI_ZeD_Prompt_Select` | `Choose` | Controller button legend, A prompt on a control with no more specific word | 12 |
| `UI_ZeD_Prompt_Sort` | `Sort` | Window footer prompt beside L3: step the sort of the list the controller is on | 10 |
| `UI_ZeD_Prompt_Start` | `Start` | Controller button legend, A prompt on an exercise | 12 |
| `UI_ZeD_Prompt_Switch` | `Switch` | Controller button legend, A prompt on a sub-tab switch | 12 |
| `UI_ZeD_Prompt_Tool` | `Tool` | Controller button legend, A prompt on a map tool | 12 |
| `UI_ZeD_Prompt_Unfold` | `Unfold` | Controller button legend, A prompt on the map's pop-out control | 12 |
| `UI_ZeD_Prompt_Use` | `Use` | Controller button legend, hold-A prompt on an inventory row (used inside 'Use (hold)') | 12 |
| `UI_ZeD_Prompt_Windows` | `Windows` | Controller button legend, Y prompt (swaps between the two windows) | 12 |
| `UI_ZeD_Prompt_Locked` | `Locked` | Controller button legend at the window foot, Y prompt while the Y hold is locked on (replaces the usual Y prompt) | 12 |
| `UI_ZeD_Prompt_HelpYes` | `Answer yes.` | Pop-up prompt: help line over the Yes button | - |
| `UI_ZeD_Prompt_HelpNo` | `Answer no.` | Pop-up prompt: help line over the No button | - |
| `UI_ZeD_Prompt_HelpOk` | `Accept and close.` | Pop-up prompt: help line over the OK button | - |
| `UI_ZeD_Prompt_HelpCancel` | `Close without changing anything.` | Pop-up prompt: help line over the Cancel button | - |
| `UI_ZeD_Prompt_HelpSwatch` | `Use this color for the text.` | Pop-up prompt for text color: help line over a color swatch | - |
| `UI_ZeD_Prompt_HelpHourDown` | `Set the alarm one hour earlier.` | Pop-up prompt for the alarm clock: help line over the button that sets the alarm one hour earlier | - |
| `UI_ZeD_Prompt_HelpHourUp` | `Set the alarm one hour later.` | Pop-up prompt for the alarm clock: help line over the button that sets the alarm one hour later | - |
| `UI_ZeD_Prompt_HelpMinuteDown` | `Set the alarm ten minutes earlier.` | Pop-up prompt for the alarm clock: help line over the button that sets the alarm ten minutes earlier | - |
| `UI_ZeD_Prompt_HelpMinuteUp` | `Set the alarm ten minutes later.` | Pop-up prompt for the alarm clock: help line over the button that sets the alarm ten minutes later | - |
| `UI_ZeD_Prompt_HelpTick` | `Turn the alarm on or off.` | Pop-up prompt for the alarm clock: help line over the check box that turns the alarm on or off | - |
| `UI_ZeD_Prompt_HelpTimerLess` | `Take %1 seconds off the timer.` | Pop-up prompt for the timer: help line over a minus button; %1 = the number of seconds | - |
| `UI_ZeD_Prompt_HelpTimerMore` | `Add %1 seconds to the timer.` | Pop-up prompt for the timer: help line over a plus button; %1 = the number of seconds | - |

## Radio

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Radio_Ac` | `AC` | Two-way radio's display (radio tab, full view; pixel face): in place of BAT on a set running on the grid or a generator (its power bars stay dark) | 3 |
| `UI_ZeD_Radio_Bat` | `BAT` | Two-way radio's display (radio tab, full view; pixel face): label before the battery bars | 3 |
| `UI_ZeD_Radio_Batt` | `BATT` | Character / World window, Radio tab: silkscreen label on the display, before the battery bar | 5 |
| `UI_ZeD_Radio_CdLoaded` | `DISC LOADED` | Character / World window, Radio tab, CD display: a disc is in but no track is chosen | 16 |
| `UI_ZeD_Radio_CdNone` | `NO DISC` | Character / World window, Radio tab, CD display: no disc | 12 |
| `UI_ZeD_Radio_CdTrack` | `TRK %1   %2` | Character / World window, Radio tab, CD display: track number and state (%1 = two-digit track, %2 = PLAY or STOP below) | 20 |
| `UI_ZeD_Radio_Ch` | `CH` | Two-way radio's display (radio tab, full view; pixel face): small label over the memory channel's number | 3 |
| `UI_ZeD_Radio_ChCleared` | `CH %1 CLEARED` | Two-way radio display flash after a channel is forgotten; %1 = the channel number, two digits | 16 |
| `UI_ZeD_Radio_ChStored` | `CH %1 STORED` | Two-way radio display flash after MEM; %1 = the channel number, two digits | 16 |
| `UI_ZeD_Radio_CloseFullView` | `Close full view` | Character / World window, Radio tab: hover hint of the full view button while the radio is in full view (pressing it closes full view) | 24 |
| `UI_ZeD_Radio_CompactDisc` | `COMPACT DISC` | CD receiver display line when a disc has no title | 16 |
| `UI_ZeD_Radio_Empty` | `EMPTY` | Radio display flash when a preset button has no station | 8 |
| `UI_ZeD_Radio_FullView` | `Full view` | Character / World window, Radio tab: hover hint of the icon button at the header's right end that shows a two-way radio's face on its own, over the world | 24 |
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
| `UI_ZeD_Radio_TwoWayBase` | `* 2-WAY BASE SET` | Character / World window, Radio tab: right end of a ham radio's brand bar (the brand name stays English) | 24 |
| `UI_ZeD_Radio_TwoWayPortable` | `* 2-WAY PORTABLE` | Character / World window, Radio tab: right end of a walkie talkie's (or the Manpack's) brand bar (the brand name stays English) | 24 |
| `UI_ZeD_Radio_TxOk` | `TX OK` | Two-way radio display: transmitting is possible | 6 |
| `UI_ZeD_Radio_UnknownFreq` | `Unknown frequency` | Character / World window, Radio tab: display line when the game has no name for the tuned channel (after a '> ' arrow) | 28 |
| `UI_ZeD_Radio_Vol` | `VOL` | Character / World window, Radio tab: silkscreen label before the volume bar and on the control strip; also a two-way radio's display (pixel face), before its volume bars, where only 3 fit | 3 |

## RadioPrompt

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_RadioPrompt_ChannelDown` | `Channel down` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_ChannelUp` | `Channel up` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Dpad` | `D-pad Move / Turn` | Car radio up close, controller prompt strip: the D-pad's job | 30 |
| `UI_ZeD_RadioPrompt_Eject` | `Eject` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_InsertCd` | `Insert a CD` | Car radio up close, controller prompt strip: what the A or X button does on the focused control | 20 |
| `UI_ZeD_RadioPrompt_Lamp` | `Light` | Two-way radio in full view, controller prompt strip: what A does on the LAMP key (lights the display for 5 s) | 20 |
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
| `UI_ZeD_RadioPrompt_Move` | `Move / turn` | Two-way radio in full view and car radio up close, controller prompt strip: the D-pad's job (the D-pad picture stands before it) | 20 |

## Read

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Read_Unread` | `Unread` | Item lists, COND column beside the read mark: nothing read yet | 12 |
| `UI_ZeD_Read_Read` | `Read` | Item lists, COND column beside the read mark: read (or below your level) | 12 |
| `UI_ZeD_Read_Known` | `Known` | Item lists, COND column beside the read mark: a recipe magazine whose recipes are all known | 12 |
| `UI_ZeD_Read_Watched` | `Watched` | Item lists, COND column beside the read mark: a VHS tape seen to the end | 12 |
| `UI_ZeD_Read_NotWatched` | `Not watched` | Item lists, COND column beside the read mark: a VHS tape not seen to the end | 12 |
| `UI_ZeD_Read_Heard` | `Heard` | Item lists, COND column beside the read mark: a CD or cassette heard to the end | 12 |
| `UI_ZeD_Read_NotHeard` | `Not heard` | Item lists, COND column beside the read mark: a CD or cassette not heard to the end | 12 |
| `UI_ZeD_Read_Pages` | `%1 of %2` | Item lists, COND column and hover text: pages read of a book's pages; %1 = read, %2 = all | 12 |
| `UI_ZeD_Read_SomeKnown` | `%1 of %2 known` | Item lists, COND column: a recipe magazine with some recipes known; %1 = known, %2 = all | 14 |
| `UI_ZeD_Read_NextLevel` | `Next level` | Item lists, a tag after a skill book's name: the book suits your next level | 12 |
| `UI_ZeD_Read_NextFor` | `Good for your next level: %1` | Item lists, hover text of a skill book; %1 = a skill and level (Mechanics 4) | - |
| `UI_ZeD_Read_PastLevels` | `Your %1 is %2, past this book's levels (%3 to %4)` | Item lists, hover text of a skill book below your level; %1 = skill, %2 = your level, %3 to %4 = the book's levels | - |
| `UI_ZeD_Read_ForLevels` | `for %1 %2 to %3 (you have %4)` | Item lists, hover text after the pages of a skill book above your next level; %1 = skill, %2 to %3 = the book's levels, %4 = your level | - |
| `UI_ZeD_Read_KnownList` | `Known: %1` | Item lists, hover text of a recipe magazine; %1 = recipe names | - |
| `UI_ZeD_Read_NotKnownList` | `Not known: %1` | Item lists, hover text of a recipe magazine; %1 = recipe names | - |
| `UI_ZeD_Read_NotWatchedYet` | `Not watched yet.` | Item lists, hover text of a VHS tape not seen to the end | - |
| `UI_ZeD_Read_NotHeardYet` | `Not heard yet.` | Item lists, hover text of a CD or cassette not heard to the end | - |
| `UI_ZeD_Read_AlreadyHeard` | `Already heard.` | Item lists, hover text of a CD or cassette heard to the end | - |

## Reader

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Reader_Blank` | `Blank` | Notebook page window, left rail: row text for a page with nothing written | 14 |
| `UI_ZeD_Reader_Counts` | `%1 of %2 lines \| %3 of %4 letters` | Notebook page window: how much of the page is used (%1 lines used, %2 lines allowed, %3 letters used, %4 letters allowed; thousands have a comma) | 50 |
| `UI_ZeD_Reader_Erase` | `Erase` | Notebook page window, bottom strip: the confirm button of the erase question (shown in sentence case) | 12 |
| `UI_ZeD_Reader_EraseAsk` | `Erase page %1? Its words can't be brought back.` | Notebook page window, bottom strip: question when Erase page is pressed (%1 = page) | 70 |
| `UI_ZeD_Reader_ErasePage` | `Erase page` | Notebook page window, bottom strip: button that clears the page (shown in sentence case) | 16 |
| `UI_ZeD_Reader_HeadPiece` | `This piece` | Reader side column and Papers quick look: section heading over kind, date, read | 20 |
| `UI_ZeD_Reader_HeadPlaces` | `Places` | Reader side column and Papers quick look: heading over the places the piece names (Show on map) | 20 |
| `UI_ZeD_Reader_HeadStories` | `On this page` | Reader side column: heading over the list of stories (headlines) on the page | 22 |
| `UI_ZeD_Reader_KeepIt` | `Keep it` | Notebook page window, bottom strip: the cancel button of the erase question (shown in sentence case) | 12 |
| `UI_ZeD_Reader_LabelDate` | `Date` | Reader side column and Papers quick look: label for the date of the paper; narrow label column | 8 |
| `UI_ZeD_Reader_LabelKind` | `Kind` | Reader side column and Papers quick look: label for the kind of paper (Newspaper, Flyer...); narrow label column | 8 |
| `UI_ZeD_Reader_LabelRead` | `Read` | Reader side column and Papers quick look: label for whether the character has read it; narrow label column | 8 |
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
| `UI_ZeD_Reader_HelpBack` | `Close the reader.` | Reader window (a newspaper, flyer or brochure): help line over the Back button | - |
| `UI_ZeD_Reader_HelpNoteBack` | `Leave the notebook as it was.` | Notebook page window: help line over the Back button while writing | - |
| `UI_ZeD_Reader_HelpDone` | `Save every page and the name, and close.` | Notebook page window: help line over the Done button | - |
| `UI_ZeD_Reader_HelpErasePage` | `Erase everything written on this page. It asks first.` | Notebook page window: help line over the Erase page button | - |
| `UI_ZeD_Reader_HelpEraseNow` | `Erase this page for good.` | Notebook page window: help line over the Erase button of the erase question | - |
| `UI_ZeD_Reader_HelpKeep` | `Keep the page as it is.` | Notebook page window: help line over the Keep it button of the erase question | - |
| `UI_ZeD_Reader_HelpLock` | `Lock the notebook so only you can write in it.` | Notebook page window: help line over the Lock button | - |
| `UI_ZeD_Reader_HelpUnlock` | `Unlock the notebook for everyone.` | Notebook page window: help line over the Unlock button | - |
| `UI_ZeD_Reader_HelpPrev` | `Turn to the previous page.` | Notebook page window: help line over the previous page button | - |
| `UI_ZeD_Reader_HelpNext` | `Turn to the next page.` | Notebook page window: help line over the next page button | - |
| `UI_ZeD_Reader_PagePrev` | `Previous page` | Notebook page window: hover hint of the previous page button (icon-only button) | - |
| `UI_ZeD_Reader_PageNext` | `Next page` | Notebook page window: hover hint of the next page button (icon-only button) | - |
| `UI_ZeD_Reader_HelpPage` | `Turn to this page.` | Notebook page window, left rail: help line over a page row | - |
| `UI_ZeD_Reader_HelpPaper` | `Show the piece as it was printed.` | Reader window: help line over the Paper button | - |
| `UI_ZeD_Reader_HelpWords` | `Show the piece as plain text.` | Reader window: help line over the Words button | - |
| `UI_ZeD_Reader_HelpZoomIn` | `Zoom in on the page.` | Reader window: help line over the plus zoom button | - |
| `UI_ZeD_Reader_HelpZoomOut` | `Zoom out.` | Reader window: help line over the minus zoom button | - |
| `UI_ZeD_Reader_HelpStory` | `Read this story in Words.` | Reader window, Paper view, side column: help line over a story (headline) in the list | - |
| `UI_ZeD_Reader_HelpPlace` | `Show this place on the map.` | Reader window, side column: help line over a place the piece names | - |
| `UI_ZeD_Reader_PromptTurn` | `Turn the page` | Reader window, controller prompt strip: what the bumpers do (turn the page) | 20 |
| `UI_ZeD_Reader_PromptView` | `Paper or words` | Reader window, controller prompt strip: what the bumpers do on a piece that has both views (switch between Paper and Words) | 20 |
| `UI_ZeD_Reader_PromptWrite` | `Write` | Notebook page window, controller prompt strip: what A does (starts writing) | 14 |
| `UI_ZeD_Reader_PromptZoom` | `Zoom` | Reader window, controller prompt strip: what X and Y do in the Paper view | 14 |

## Recipe

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Recipe_Fuel` | `Fuel` | Crafting list, small tag on an ingredient that can be burnt as fuel | 8 |

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
| `UI_ZeD_Saves_KvMode` | `Mode` | Load game screen: caps label in the save's facts (about 12 letters of room) | 12 |
| `UI_ZeD_Saves_KvPlayed` | `Played` | Load game screen: caps label in the save's facts (when it was last played) | 12 |
| `UI_ZeD_Saves_KvPlayingAs` | `Playing as` | Load game screen: caps label before the list of characters to play | 12 |
| `UI_ZeD_Saves_ModsMissing` | `%1 not found` | Load game screen: value of the Mods fact when every mod is missing. %1 is how many | - |
| `UI_ZeD_Saves_More` | `More` | Load game screen: strip button that opens the More pop-up; also a controller prompt (Y) | 10 |
| `UI_ZeD_Saves_NameDead` | `%1, dead` | Load game screen: a dead character's name in the list and the heading. %1 is the name | - |
| `UI_ZeD_Saves_NoteModsMissing` | `Mods not found: %1` | Load game screen: red note under the facts. %1 is a comma separated list of mods | - |
| `UI_ZeD_Saves_RenameFile` | `Rename file...` | Load game screen: row of the More pop-up | - |
| `UI_ZeD_Saves_Title` | `Project Zomboid  +  Load game` | Load game screen: title bar. The + is the ZeD title separator | - |

## Sbx

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_SbxSave_Alarm` | `Each building gets its alarm, or none, from this setting when the map data is first made. Buildings already stored in the save should keep their alarm state.` | Sandbox options in game: help band, On this save, for House Alarms Frequency (World page) | - |
| `UI_ZeD_SbxSave_AlarmDecay` | `Each building gets its alarm battery time from this setting when the map data is first made. Buildings already stored in the save should keep theirs.` | Sandbox options in game: help band, On this save, for Alarm Battery Decay (World page) | - |
| `UI_ZeD_SbxSave_AnimalEggHatch` | `Read when an egg is made. Eggs already laid keep their hatch time.` | Sandbox options in game: help band, On this save, for Egg Hatch Time (Livestock page) | - |
| `UI_ZeD_SbxSave_AnimalPathChance` | `Read when an area is first set up. Areas you have already seen keep their paths.` | Sandbox options in game: help band, On this save, for Animal Paths Chance (Livestock page) | - |
| `UI_ZeD_SbxSave_AnimalRanchChance` | `Read when a farm is first set up. Farms you have already seen keep their animals.` | Sandbox options in game: help band, On this save, for Animal Spawn Chance (Livestock page) | - |
| `UI_ZeD_SbxSave_AnimalTrackChance` | `Read when the game places animal tracks. Tracks already placed stay.` | Sandbox options in game: help band, On this save, for Animal Tracks Chance (Livestock page) | - |
| `UI_ZeD_SbxSave_AnnotatedMapChance` | `Read when a map is made. Maps you already hold keep their notes, or lack of them.` | Sandbox options in game: help band, On this save, for Annotated Map Chance (Meta page) | - |
| `UI_ZeD_SbxSave_Basement_SpawnFrequency` | `No code in the game reads this setting in this build, so changing it does nothing.` | Sandbox options in game: help band, On this save, for Basement Spawn Frequency (World page) | - |
| `UI_ZeD_SbxSave_BloodSplatLifespanDays` | `Old blood splats are removed as map chunks load, so setting it can clear them for good. 0 keeps them forever.` | Sandbox options in game: help band, On this save, for Blood Splat Lifespan Days (Meta page) | - |
| `UI_ZeD_SbxSave_CarAlarm` | `Read when a car is first made. Cars already in the world keep their alarm state.` | Sandbox options in game: help band, On this save, for Vehicle Alarms Frequency (Vehicles page) | - |
| `UI_ZeD_SbxSave_CarGeneralCondition` | `Read when a car is first made. Cars already in the world keep their condition.` | Sandbox options in game: help band, On this save, for General Condition (Vehicles page) | - |
| `UI_ZeD_SbxSave_CarSpawnRate` | `Only affects areas the game fills for the first time. Cars already in the world stay where they are.` | Sandbox options in game: help band, On this save, for Vehicle Spawn Rate (Vehicles page) | - |
| `UI_ZeD_SbxSave_ChanceHasGas` | `Read when a car is first made. Cars already in the world keep their fuel.` | Sandbox options in game: help band, On this save, for Chance Has Gas (Vehicles page) | - |
| `UI_ZeD_SbxSave_ClayLakeChance` | `Read when ground is generated for the first time. Ground you have already seen keeps its tiles.` | Sandbox options in game: help band, On this save, for Clay chance - Lake (Nature page) | - |
| `UI_ZeD_SbxSave_ClayRiverChance` | `Read when ground is generated for the first time. Ground you have already seen keeps its tiles.` | Sandbox options in game: help band, On this save, for Clay chance - River (Nature page) | - |
| `UI_ZeD_SbxSave_ConstructionBonusPoints` | `Read when something finishes building. Applies to what you build from now on. Things already built keep their strength.` | Sandbox options in game: help band, On this save, for Player-built Construction Strength (Character page) | - |
| `UI_ZeD_SbxSave_ConstructionPreventsLootRespawn` | `With it off and Hours for Loot Respawn above 0, buildings you have built in or barricaded can refill with loot too, and so can your own storage there.` | Sandbox options in game: help band, On this save, for Construction Prevents Loot Respawn (Loot page) | - |
| `UI_ZeD_SbxSave_DayLength` | `Days get longer or shorter in real time from now on. The clock and the date do not move. Needs, healing, food spoiling and crop growth run on game time, so they follow the new day length.` | Sandbox options in game: help band, On this save, for Day Length (in real time) (Time page) | - |
| `UI_ZeD_SbxSave_DaysForRottenFoodRemoval` | `Food that has been rotten for more than this many days is deleted the next time the game updates it. This can include food in containers. Compost bins are skipped. Deleted food does not come back.` | Sandbox options in game: help band, On this save, for Rotten Food Removal (World page) | - |
| `UI_ZeD_SbxSave_DaysUntilMaximumDiminishedLoot` | `Read each time a container is filled, so it applies to containers filled from now on.` | Sandbox options in game: help band, On this save, for Days Until Maximum Diminished Loot (Loot page) | - |
| `UI_ZeD_SbxSave_DaysUntilMaximumLooted` | `Read when the game decides whether a building was looted before you came. Buildings you have already seen keep their state.` | Sandbox options in game: help band, On this save, for Days Until Max Looted Building Chance (Loot page) | - |
| `UI_ZeD_SbxSave_DaysUntilMaximumRatIndex` | `Read when the game fills an area for the first time. Areas you have already seen keep their state.` | Sandbox options in game: help band, On this save, for Days Until Maximum Vermin Index (Nature page) | - |
| `UI_ZeD_SbxSave_Distribution` | `The game reads this when the save loads. It shapes where zombies are placed in areas that are not filled yet. Zombies already placed may stay where they are.` | Sandbox options in game: help band, On this save, for Zombie Distribution (Zombie page) | - |
| `UI_ZeD_SbxSave_ElecShut` | `The shutoff day was picked from this range when the world was made. Changing the range does not pick a day again, so it is locked.` | Sandbox options in game: help band, On this save, for Electricity Shutoff (range) (World page) | - |
| `UI_ZeD_SbxSave_ElecShutModifier` | `Checked all the time against the world's age in days. Set a day in the past and the grid goes off now: lights stop, and fridges and freezers warm so food spoils. Set a day in the future and it comes back. Generators keep working.` | Sandbox options in game: help band, On this save, for Electricity Shutoff (day) (World page) | - |
| `UI_ZeD_SbxSave_EnableVehicles` | `Only affects areas the game fills for the first time. Cars already in the world stay where they are.` | Sandbox options in game: help band, On this save, for Vehicles (Vehicles page) | - |
| `UI_ZeD_SbxSave_ErosionDays` | `Read every ten game minutes. Above 0, growth is worked out from a counter that does not start where your world's growth is, so growth can drop back or jump ahead. -1 stops growth and clears it. Setting 0 again does not bring it back.` | Sandbox options in game: help band, On this save, for Erosion Days (Nature page) | - |
| `UI_ZeD_SbxSave_ErosionSpeed` | `The growth speed is stored in the save's erosion file when the world is made. Changing it afterwards does nothing, so it is locked.` | Sandbox options in game: help band, On this save, for Erosion Speed (Nature page) | - |
| `UI_ZeD_SbxSave_FarmingAmountNew` | `Read when you harvest. In this build the farming code works out the result but does not appear to use it, so it may have no effect.` | Sandbox options in game: help band, On this save, for Farming Abundance (Nature page) | - |
| `UI_ZeD_SbxSave_FarmingSpeedNew` | `Read each time a plant is scheduled for its next growth stage. A stage already scheduled keeps its time.` | Sandbox options in game: help band, On this save, for Farming Speed (Nature page) | - |
| `UI_ZeD_SbxSave_FirearmNoiseMultiplier` | `In this game only weapon reloading reads this number. No other use was found.` | Sandbox options in game: help band, On this save, for Firearm Noise Multiplier (Character page) | - |
| `UI_ZeD_SbxSave_FoodRotSpeed` | `Changes how fast all food spoils from now on, including food in your fridge and bags.` | Sandbox options in game: help band, On this save, for Food Spoilage (World page) | - |
| `UI_ZeD_SbxSave_FuelStationGasEmptyChance` | `A pump gets its starting fuel the first time the game checks it. Pumps already checked should keep their amount.` | Sandbox options in game: help band, On this save, for Initial Gas Pump Empty Chance (World page) | - |
| `UI_ZeD_SbxSave_FuelStationGasMax` | `A pump gets its starting fuel the first time the game checks it. Pumps already checked should keep their amount.` | Sandbox options in game: help band, On this save, for Initial Maximum Gas Pump Amount (World page) | - |
| `UI_ZeD_SbxSave_FuelStationGasMin` | `A pump gets its starting fuel the first time the game checks it. Pumps already checked should keep their amount.` | Sandbox options in game: help band, On this save, for Initial Minimum Gas Pump Amount (World page) | - |
| `UI_ZeD_SbxSave_GeneratorTileRange` | `A generator takes its range when it is placed or when the save loads. Generators already running keep their range until you reload.` | Sandbox options in game: help band, On this save, for Generator tile range (World page) | - |
| `UI_ZeD_SbxSave_GeneratorVerticalPowerRange` | `A generator takes its range when it is placed or when the save loads. Generators already running keep their range until you reload.` | Sandbox options in game: help band, On this save, for Generator vertical range (World page) | - |
| `UI_ZeD_SbxSave_Helicopter` | `Read when the game plans each flyover. A flyover already planned still happens if you set Never. Moving from Never or Once to Sometimes or Often plans a new one.` | Sandbox options in game: help band, On this save, for Helicopter (Meta page) | - |
| `UI_ZeD_SbxSave_HoursForCorpseRemoval` | `Zombie corpses older than this many hours are removed, and so is what they carry. Lowering it can clear corpses you have left lying around. 0 or less turns removal off.` | Sandbox options in game: help band, On this save, for Time Before Corpse Removal (Meta page) | - |
| `UI_ZeD_SbxSave_HoursForLootRespawn` | `Turning it on lets containers in towns and trailer parks refill with loot, including ones you have emptied. The game checks areas as they load and as time passes. A container holding fewer than Max Items For Loot Respawn items refills, and the new loot is added to what is there.` | Sandbox options in game: help band, On this save, for Hours for Loot Respawn (Loot page) | - |
| `UI_ZeD_SbxSave_HoursForWorldItemRemoval` | `Lowering it deletes listed items sooner, including ones already lying there. The check runs when that part of the map loads. 0 stops the removal.` | Sandbox options in game: help band, On this save, for Hours for Removal List (World page) | - |
| `UI_ZeD_SbxSave_InitialGas` | `Read when a car is first made. Cars already in the world keep their fuel.` | Sandbox options in game: help band, On this save, for Initial Gas (Vehicles page) | - |
| `UI_ZeD_SbxSave_ItemRemovalListBlacklistToggle` | `Turns the list around: every loose item that is not on World Item Removal List is deleted after Hours for Removal List, when its part of the map loads. On a lived-in save that can clear the floors and surfaces of your base.` | Sandbox options in game: help band, On this save, for Removal List as Whitelist (World page) | - |
| `UI_ZeD_SbxSave_KillInsideCrops` | `Turning it on drains health from crops growing indoors, until they die. Greenhouse rooms and house plants are exempt.` | Sandbox options in game: help band, On this save, for Kill Crops Grown Inside (Nature page) | - |
| `UI_ZeD_SbxSave_LockedCar` | `Read when a car is first made. Cars already in the world keep their locks.` | Sandbox options in game: help band, On this save, for Locked Vehicle Frequency (Vehicles page) | - |
| `UI_ZeD_SbxSave_LockedHouses` | `Read when a door or window is first made. Doors and windows you have seen keep their state.` | Sandbox options in game: help band, On this save, for Locked Houses Frequency (World page) | - |
| `UI_ZeD_SbxSave_Map_MapAllKnown` | `Read the first time the game uses the map after the save loads. If it is on then, the whole world map is marked as known and saved that way. Turning it off later does not forget the map.` | Sandbox options in game: help band, On this save, for All Known On Start (Meta page) | - |
| `UI_ZeD_SbxSave_MaximumDiminishedLoot` | `Read each time a container is filled, so it applies to containers filled from now on.` | Sandbox options in game: help band, On this save, for Maximum Diminished Loot Percentage (Loot page) | - |
| `UI_ZeD_SbxSave_MaximumFireFuelHours` | `Read when you add fuel. Fuel already in a fire or stove is not changed.` | Sandbox options in game: help band, On this save, for Maximum Fire Fuel Hours (World page) | - |
| `UI_ZeD_SbxSave_MaximumLooted` | `Read when the game decides whether a building was looted before you came. Buildings you have already seen keep their state.` | Sandbox options in game: help band, On this save, for Maximum Looted Building Chance (Loot page) | - |
| `UI_ZeD_SbxSave_MaximumLootedBuildingRooms` | `Read when a building is first set up. Buildings you have already seen keep their state.` | Sandbox options in game: help band, On this save, for Maximum Looted Building Rooms (Loot page) | - |
| `UI_ZeD_SbxSave_MaximumRatIndex` | `Read when the game fills an area for the first time. Areas you have already seen keep their state.` | Sandbox options in game: help band, On this save, for Maximum Vermin Index (Nature page) | - |
| `UI_ZeD_SbxSave_MinutesPerPage` | `Read when you start reading a book. A book you are already reading keeps its pace.` | Sandbox options in game: help band, On this save, for Minutes Per Skill Book Page (Character page) | - |
| `UI_ZeD_SbxSave_NoBlackClothes` | `Read when a random clothing color is picked, for example for a zombie that spawns. Clothes already made keep their color.` | Sandbox options in game: help band, On this save, for No Black Clothes (Character page) | - |
| `UI_ZeD_SbxSave_PlantGrowingSeasons` | `Turning it on makes crops outdoors suffer in bad months and in winter. Crops already planted out of season lose health quickly and can die.` | Sandbox options in game: help band, On this save, for Plant Growing Seasons (Nature page) | - |
| `UI_ZeD_SbxSave_Rain` | `Applies to weather the game plans from now on. A front already under way may run its course.` | Sandbox options in game: help band, On this save, for Rain (Nature page) | - |
| `UI_ZeD_SbxSave_RecentlySurvivorVehicles` | `Read when a car is first made. Cars already in the world keep their state.` | Sandbox options in game: help band, On this save, for Recent Survivor Vehicles (Vehicles page) | - |
| `UI_ZeD_SbxSave_RuralLooted` | `Read when the game decides whether a building was looted before you came. Buildings you have already seen keep their state.` | Sandbox options in game: help band, On this save, for Rural Building Looted Chance Multiplier (Loot page) | - |
| `UI_ZeD_SbxSave_StarterKit` | `Only a character made after this gets the kit.` | Sandbox options in game: help band, On this save, for Starter Kit (Character page) | - |
| `UI_ZeD_SbxSave_SurvivorHouseChance` | `Read when a building is first set up. Buildings you have already seen keep what they have.` | Sandbox options in game: help band, On this save, for Randomized Building Chance (Meta page) | - |
| `UI_ZeD_SbxSave_Temperature` | `The game code reads this only when the save loads, to set the plant growth seasons. No other use was found, so it may not change the weather temperature.` | Sandbox options in game: help band, On this save, for Temperature (Nature page) | - |
| `UI_ZeD_SbxSave_TimeSinceApo` | `Each month adds 30 days to the world's age. Raising it ages the world at once: water and power go off if the new age is past their shutoff days, and areas you have not seen yet are made older (more looted buildings, corpses, flat car batteries).` | Sandbox options in game: help band, On this save, for Months since the Apocalypse (Time page) | - |
| `UI_ZeD_SbxSave_TrafficJam` | `Only affects areas the game fills for the first time. Wrecks already on the road stay where they are.` | Sandbox options in game: help band, On this save, for Car Wreck Congestion (Vehicles page) | - |
| `UI_ZeD_SbxSave_VehicleEasyUse` | `Read when you start a car and when cars are made. Off: a car needs its key or a hotwire. Cars made while it was on carry their key in the glove box.` | Sandbox options in game: help band, On this save, for Easy Use (Vehicles page) | - |
| `UI_ZeD_SbxSave_VehicleStoryChance` | `Read when a road story is first set up. Stories already placed stay.` | Sandbox options in game: help band, On this save, for Randomized Road Stories Chance (Meta page) | - |
| `UI_ZeD_SbxSave_WaterShut` | `The shutoff day was picked from this range when the world was made. Changing the range does not pick a day again, so it is locked.` | Sandbox options in game: help band, On this save, for Water Shutoff (range) (World page) | - |
| `UI_ZeD_SbxSave_WaterShutModifier` | `Checked all the time against the world's age in days. Set a day in the past and the taps stop now. Set a day in the future and they run again. Water already in pots, bottles and barrels is not touched.` | Sandbox options in game: help band, On this save, for Water Shutoff (day) (World page) | - |
| `UI_ZeD_SbxSave_WorldItemRemovalList` | `Items of these types lying loose in the world, on the ground or on a surface, are deleted once they have been there longer than Hours for Removal List, when that part of the map loads. Items you dropped yourself count. Deleted items do not come back.` | Sandbox options in game: help band, On this save, for World Item Removal List (World page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_FollowSoundDistance` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Follow Sound Distance (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_PopulationMultiplier` | `This is the number behind Zombie Count. The game sends it to its zombie population manager when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Population Multiplier (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_PopulationPeakDay` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Population Peak Day (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_PopulationPeakMultiplier` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Population Peak Multiplier (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_PopulationStartMultiplier` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Population Start Multiplier (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_RallyGroupSizeVariance` | `Read when a zombie group forms, so it applies to groups formed from now on.` | Sandbox options in game: help band, On this save, for Rally Group Size Variance (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_RedistributeHours` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load. 0 turns migration off.` | Sandbox options in game: help band, On this save, for Redistribute Hours (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_RespawnHours` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load. Above 0, zombies can return to areas you have cleared.` | Sandbox options in game: help band, On this save, for Respawn Hours (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_RespawnMultiplier` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Respawn Multiplier (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_RespawnUnseenHours` | `The game sends this to its zombie population manager when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Respawn Unseen Hours (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieConfig_ZombiesCountBeforeDelete` | `Only a multiplayer server uses this number. A single-player game ignores it.` | Sandbox options in game: help band, On this save, for Zombie count before deletion (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ActiveOnly` | `Read every game update, so it applies at once.` | Sandbox options in game: help band, On this save, for Day/Night Zombie Speed Effect (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ChanceOfAttachedWeapon` | `The game reads this once after the save loads, when it makes the first zombie, so a change shows after the next load. It then applies to zombies made from that point.` | Sandbox options in game: help band, On this save, for Chance Of Attached Weapon (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_DisableFakeDead` | `Read when corpses and downed zombies are set up or updated. Corpses already lying around may keep the state they have.` | Sandbox options in game: help band, On this save, for Fake Dead Zombie Reanimation (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_Mortality` | `Read as infection runs, so a character who is already infected may follow the new timing.` | Sandbox options in game: help band, On this save, for Infection Mortality (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_PlayerSpawnZombieRemoval` | `Applies when a new character spawns in this world, for example after a death. It clears zombies near where that character appears. Your current character has already spawned.` | Sandbox options in game: help band, On this save, for Player Spawn Area (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_Reanimate` | `Applies to corpses of the infected from now on.` | Sandbox options in game: help band, On this save, for Reanimate Time (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_SpottedLogic` | `Read every time a zombie checks for you, so it applies at once.` | Sandbox options in game: help band, On this save, for New Stealth System (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_Strength` | `Takes effect at once for bites and hits on you and for zombies hitting doors. Zombies already out there also pick it up when they next load.` | Sandbox options in game: help band, On this save, for Strength (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ThumpNoChasing` | `Read when a zombie bumps into something, so it applies at once.` | Sandbox options in game: help band, On this save, for Environmental Attacks (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ThumpOnConstruction` | `Read when a zombie hits something you built, so it applies at once.` | Sandbox options in game: help band, On this save, for Damage Construction (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_Toughness` | `Applies to zombies made after the change, such as new spawns and risen corpses. Zombies already out there keep their toughness.` | Sandbox options in game: help band, On this save, for Toughness (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_Transmission` | `Applies to bites, scratches and deaths from now on.` | Sandbox options in game: help band, On this save, for Transmission (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_TriggerHouseAlarm` | `Read when a window or door is broken or opened, so it applies at once.` | Sandbox options in game: help band, On this save, for Zombie House Alarm Triggering (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ZombiesArmorFactor` | `Read on every hit, so it applies at once.` | Sandbox options in game: help band, On this save, for Zombie Armor Factor (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ZombiesCrawlersDragDown` | `Read each time a zombie attacks, so it applies at once.` | Sandbox options in game: help band, On this save, for Crawlers Drag Down (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ZombiesDragDown` | `Read each time a zombie attacks, so it applies at once.` | Sandbox options in game: help band, On this save, for Drag Down (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ZombiesFallDamage` | `Read when a zombie lands from a height, so it applies at once.` | Sandbox options in game: help band, On this save, for Zombie Fall Damage Multiplier (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ZombiesFenceLunge` | `Read when a zombie climbs a fence or window, so it applies at once.` | Sandbox options in game: help band, On this save, for Zombie Lunge (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieLore_ZombiesMaxDefense` | `Read on every hit, so it applies at once.` | Sandbox options in game: help band, On this save, for Maximum Zombie Armor Defense (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieMigrate` | `This is a shortcut for Redistribute Hours in Advanced Zombie Options. The game reads that number when the save loads, so a change starts after the next load.` | Sandbox options in game: help band, On this save, for Zombie Migration (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieRespawn` | `This is a shortcut for the three Respawn numbers in Advanced Zombie Options. The game reads those when the save loads, so respawning starts or stops after the next load.` | Sandbox options in game: help band, On this save, for Zombie Respawn (Zombie page) | - |
| `UI_ZeD_SbxSave_ZombieVoronoiNoise` | `The game reads this while it loads the map data, so a change shows after the next load.` | Sandbox options in game: help band, On this save, for Voronoi Noise (Zombie page) | - |
| `UI_ZeD_SbxSave_Zombies` | `The game hands this count to its zombie population manager when the save loads, so a change shows after the next load. Rooms and stories you open use the new count at once.` | Sandbox options in game: help band, On this save, for Zombie Count (Zombie page) | - |
| `UI_ZeD_SbxSave_ZoneStoryChance` | `Read when a zone story is first set up. Stories already placed stay.` | Sandbox options in game: help band, On this save, for Randomized Zone Stories Chance (Meta page) | - |
| `UI_ZeD_SbxSecSave_LootRarity` | `Applies to containers filled from now on. Containers already filled keep their loot.` | Sandbox options in game: help band, On this save, for every setting under the section LootRarity | - |
| `UI_ZeD_SbxSecSave_XPMultipliers` | `XP earned from now on uses the new rate. Levels already earned stay.` | Sandbox options in game: help band, On this save, for every setting under the section XPMultipliers | - |
| `UI_ZeD_SbxSecSave_ZombieLore` | `Most of these are set on each zombie as it is made or loads in. Zombies already out there may keep their old ways until you leave the area and come back.` | Sandbox options in game: help band, On this save, for every setting under the section ZombieLore | - |
| `UI_ZeD_SbxSecTip_LootRarity` | `Raising it makes new places richer. Places you have already looted stay looted unless loot respawn is on (Hours for Loot Respawn, top of the Loot page).` | Sandbox options in game: help band, Tip, for every setting under the section LootRarity | - |
| `UI_ZeD_SbxSecTip_XPMultipliers` | `The skill rows only count while Use Global Multiplier is off.` | Sandbox options in game: help band, Tip, for every setting under the section XPMultipliers | - |
| `UI_ZeD_SbxTip_DaysForRottenFoodRemoval` | `-1 never removes it. Leave it at -1 if you keep rotten food in containers for compost.` | Sandbox options in game: help band, Tip, for Rotten Food Removal (World page) | - |
| `UI_ZeD_SbxTip_DaysUntilMaximumDiminishedLoot` | `The effect grows with the world's age, which includes Months since the Apocalypse.` | Sandbox options in game: help band, Tip, for Days Until Maximum Diminished Loot (Loot page) | - |
| `UI_ZeD_SbxTip_DaysUntilMaximumLooted` | `The chance rises with the world's age, which includes Months since the Apocalypse.` | Sandbox options in game: help band, Tip, for Days Until Max Looted Building Chance (Loot page) | - |
| `UI_ZeD_SbxTip_DaysUntilMaximumRatIndex` | `The index rises with the world's age, which includes Months since the Apocalypse.` | Sandbox options in game: help band, Tip, for Days Until Maximum Vermin Index (Nature page) | - |
| `UI_ZeD_SbxTip_ElecShut` | `To move the day, change Electricity Shutoff (day).` | Sandbox options in game: help band, Tip, for Electricity Shutoff (range) (World page) | - |
| `UI_ZeD_SbxTip_ElecShutModifier` | `-1 means off from the start. 2147483647 keeps the power on for good. The world's day count is at the top of this page.` | Sandbox options in game: help band, Tip, for Electricity Shutoff (day) (World page) | - |
| `UI_ZeD_SbxTip_ErosionDays` | `Leave this at 0 on a world that already has growth you want to keep.` | Sandbox options in game: help band, Tip, for Erosion Days (Nature page) | - |
| `UI_ZeD_SbxTip_ErosionSpeed` | `Erosion Days still works, but it can reset growth. Read its note first.` | Sandbox options in game: help band, Tip, for Erosion Speed (Nature page) | - |
| `UI_ZeD_SbxTip_FoodRotSpeed` | `Slower spoiling does not make rotten food fresh again.` | Sandbox options in game: help band, Tip, for Food Spoilage (World page) | - |
| `UI_ZeD_SbxTip_HoursForLootRespawn` | `Construction Prevents Loot Respawn keeps buildings you have built in or barricaded from refilling. 0 turns respawn off.` | Sandbox options in game: help band, Tip, for Hours for Loot Respawn (Loot page) | - |
| `UI_ZeD_SbxTip_ItemRemovalListBlacklistToggle` | `Leave it off unless you mean to clear the world.` | Sandbox options in game: help band, Tip, for Removal List as Whitelist (World page) | - |
| `UI_ZeD_SbxTip_LootItemRemovalList` | `Write item types as Module.Name, for example Base.Hat, with commas between.` | Sandbox options in game: help band, Tip, for Loot Item Removal List (Loot page) | - |
| `UI_ZeD_SbxTip_MaxItemsForLootRespawn` | `Only has an effect while Hours for Loot Respawn is above 0.` | Sandbox options in game: help band, Tip, for Max Items For Loot Respawn (Loot page) | - |
| `UI_ZeD_SbxTip_MultiplierConfig_Global` | `Only counts while Use Global Multiplier is on.` | Sandbox options in game: help band, Tip, for Global Multiplier (Character page) | - |
| `UI_ZeD_SbxTip_MultiplierConfig_GlobalToggle` | `On: every skill uses Global Multiplier. Off: each skill uses its own row.` | Sandbox options in game: help band, Tip, for Use Global Multiplier (Character page) | - |
| `UI_ZeD_SbxTip_PlantGrowingSeasons` | `The season rules only apply to crops outdoors.` | Sandbox options in game: help band, Tip, for Plant Growing Seasons (Nature page) | - |
| `UI_ZeD_SbxTip_RollsMultiplier` | `The game text advises leaving this at 1.` | Sandbox options in game: help band, Tip, for Rolls Multiplier [!] (Loot page) | - |
| `UI_ZeD_SbxTip_SeenHoursPreventLootRespawn` | `Only has an effect while Hours for Loot Respawn is above 0.` | Sandbox options in game: help band, Tip, for Loot Seen Prevent Hours (Loot page) | - |
| `UI_ZeD_SbxTip_TimeSinceApo` | `To move only the water or power shutoff, change Water Shutoff (day) or Electricity Shutoff (day) on the World page. Lowering this gives the days back.` | Sandbox options in game: help band, Tip, for Months since the Apocalypse (Time page) | - |
| `UI_ZeD_SbxTip_VehicleEasyUse` | `Turning it off can leave you in a car whose key you do not hold.` | Sandbox options in game: help band, Tip, for Easy Use (Vehicles page) | - |
| `UI_ZeD_SbxTip_WaterShut` | `To move the day, change Water Shutoff (day).` | Sandbox options in game: help band, Tip, for Water Shutoff (range) (World page) | - |
| `UI_ZeD_SbxTip_WaterShutModifier` | `-1 means off from the start. 2147483647 keeps the water on for good. The world's day count is at the top of this page.` | Sandbox options in game: help band, Tip, for Water Shutoff (day) (World page) | - |
| `UI_ZeD_SbxTip_WorldItemRemovalList` | `Items inside containers and bags are not touched. Pick up anything you want to keep before adding its type here.` | Sandbox options in game: help band, Tip, for World Item Removal List (World page) | - |
| `UI_ZeD_SbxTip_ZombieConfig_PopulationMultiplier` | `To see the new count outdoors, save and load the game again.` | Sandbox options in game: help band, Tip, for Population Multiplier (Zombie page) | - |
| `UI_ZeD_SbxTip_ZombieRespawn` | `None keeps cleared areas clear. Above None, zombies can return to areas you have cleared, including around your base.` | Sandbox options in game: help band, Tip, for Zombie Respawn (Zombie page) | - |
| `UI_ZeD_SbxTip_Zombies` | `To see the new count outdoors, save and load the game again.` | Sandbox options in game: help band, Tip, for Zombie Count (Zombie page) | - |
| `UI_ZeD_SbxWhen_chr` | `Only for a character made after this, for example after a death in this world. Your current character keeps what it had.` | Sandbox options in game: help band, On this save, for a setting tagged New characters without words of its own | - |
| `UI_ZeD_SbxWhen_fix` | `Used once, when this world was made. Changing it now would do nothing, so it is locked.` | Sandbox options in game: help band, On this save, for a setting tagged Fixed without words of its own | - |
| `UI_ZeD_SbxWhen_load` | `The game reads this only when the save loads. Apply, save, quit to the main menu and continue to see it.` | Sandbox options in game: help band, On this save, for a setting tagged Next load without words of its own | - |
| `UI_ZeD_SbxWhen_new` | `Only for places you have not been to yet: rooms, containers, cars and areas are filled the first time you see them. What you already found stays as it is.` | Sandbox options in game: help band, On this save, for a setting tagged New places without words of its own | - |
| `UI_ZeD_SbxWhen_now` | `Takes effect as soon as you apply.` | Sandbox options in game: help band, On this save, for a setting tagged Now without words of its own | - |
| `UI_ZeD_Sbx_AfterApply` | `(after Apply)` | Sandbox options in game: added to the World page's first line while the shut-off days are changed but not applied | - |
| `UI_ZeD_Sbx_AfterApplyIs` | `after Apply: %1` | Sandbox options in game: help band, after This save while changed; %1 = the value after Apply | - |
| `UI_ZeD_Sbx_Any` | `any` | Sandbox options in game: the Range's largest number when there is no real limit | 8 |
| `UI_ZeD_Sbx_Applied` | `Applied %1. The game keeps them when it next saves.` | Sandbox options in game: action strip after Apply; %1 = "1 change" / "3 changes" (Count1 / CountN) | - |
| `UI_ZeD_Sbx_AskApply` | `Apply %1 to this save?` | Sandbox options in game: action strip question before Apply; %1 = "1 change" / "3 changes" | - |
| `UI_ZeD_Sbx_AskCareN` | `Needs care: %1.` | Sandbox options in game: added to the Apply question; %1 = how many of the changes need care | - |
| `UI_ZeD_Sbx_AskClose` | `%1 not applied.` | Sandbox options in game: action strip question when closing with changes; %1 = "1 change" / "3 changes" | - |
| `UI_ZeD_Sbx_AskUndo` | `Undo %1?` | Sandbox options in game: action strip question before undoing every change (controller X); %1 = "1 change" / "3 changes" | - |
| `UI_ZeD_Sbx_AskUndoN` | `Can't be undone: %1.` | Sandbox options in game: added to the Apply question; %1 = how many of the changes can't be undone | - |
| `UI_ZeD_Sbx_ChangedNone` | `No changes yet. Settings you change are listed here until you apply them.` | Sandbox options in game: the Changed page when nothing is changed | - |
| `UI_ZeD_Sbx_Count1` | `1 change` | Sandbox options in game: one change, inside the strip's questions and History's headings | - |
| `UI_ZeD_Sbx_CountN` | `%1 changes` | Sandbox options in game: %1 = how many changes, inside the strip's questions and History's headings | - |
| `UI_ZeD_Sbx_Empty` | `(empty)` | Sandbox options in game: a text setting with nothing in it (the removal lists) | - |
| `UI_ZeD_Sbx_HeadSave` | `On this save \| %1` | Sandbox options in game: help band, second heading; %1 = the row's when tag (Now, New places ...) | - |
| `UI_ZeD_Sbx_HeadTip` | `Tip` | Sandbox options in game: help band, third heading | 12 |
| `UI_ZeD_Sbx_HeadWhat` | `What it does` | Sandbox options in game: help band, first heading: the game's own description | 20 |
| `UI_ZeD_Sbx_HelpNone` | `Point at a setting to read what it does, what changing it does to this save, and a tip.` | Sandbox options in game: help band before the pointer has been on a setting | - |
| `UI_ZeD_Sbx_HistNone` | `Nothing applied yet. Every change you apply is listed here with the in-game date, and stays in the save.` | Sandbox options in game: the History page before anything was applied | - |
| `UI_ZeD_Sbx_HistWhen` | `%1, %2` | Sandbox options in game: History page, an apply's heading; %1 = the in-game date, %2 the in-game time | - |
| `UI_ZeD_Sbx_LabelPowerDay` | `Electricity Shutoff (day)` | Sandbox options in game: the name of the row for the power shut-off day | - |
| `UI_ZeD_Sbx_LabelPowerRange` | `Electricity Shutoff (range)` | Sandbox options in game: the name of the row for the range the power shut-off day was picked from | - |
| `UI_ZeD_Sbx_LabelWaterDay` | `Water Shutoff (day)` | Sandbox options in game: the name of the row for the water shut-off day (vanilla calls it Water Shutoff, like the range) | - |
| `UI_ZeD_Sbx_LabelWaterRange` | `Water Shutoff (range)` | Sandbox options in game: the name of the row for the range the water shut-off day was picked from | - |
| `UI_ZeD_Sbx_PageChanged` | `Changed` | Sandbox options in game: page list, the page of settings changed but not applied | 20 |
| `UI_ZeD_Sbx_PageChangedN` | `Changed (%1)` | Sandbox options in game: the same page while there are changes; %1 = how many | 20 |
| `UI_ZeD_Sbx_PageHistory` | `History` | Sandbox options in game: page list, the page of every applied change | 20 |
| `UI_ZeD_Sbx_PowerOff` | `Power: off since day %1` | Sandbox options in game: World page first line; %1 = the day the power went off | - |
| `UI_ZeD_Sbx_PowerOnGood` | `Power: on for good` | Sandbox options in game: World page first line, power never shuts off | - |
| `UI_ZeD_Sbx_PowerOnUntil` | `Power: on until day %1` | Sandbox options in game: World page first line; %1 = the day the power goes off | - |
| `UI_ZeD_Sbx_PutBack` | `Undo change` | Sandbox options in game: History page, the button beside each applied change; also the help band's heading for it | 14 |
| `UI_ZeD_Sbx_PutBackHelp` | `Sets %1 back to %2. It waits on the Changed page until you apply it.` | Sandbox options in game: help band for a Put back button; %1 = the setting, %2 = the value it goes back to | - |
| `UI_ZeD_Sbx_Range` | `Range: %1 to %2` | Sandbox options in game: help band, under What it does; %1 = the smallest number, %2 the largest | - |
| `UI_ZeD_Sbx_StatChanged` | `This save, %1 changed` | Sandbox options in game: title bar, right side, while settings are changed; %1 = how many | - |
| `UI_ZeD_Sbx_StatSave` | `This save` | Sandbox options in game: title bar, right side | - |
| `UI_ZeD_Sbx_TagCare` | `Careful` | Sandbox options in game: tag: the change can make the save harder or stranger | 14 |
| `UI_ZeD_Sbx_TagChr` | `New characters` | Sandbox options in game: tag: only a character made after the change | 16 |
| `UI_ZeD_Sbx_TagFix` | `Fixed` | Sandbox options in game: tag: only used when the world was made; the row is locked | 14 |
| `UI_ZeD_Sbx_TagLoad` | `Next load` | Sandbox options in game: tag: the game reads it only when the save loads | 14 |
| `UI_ZeD_Sbx_TagNew` | `New places` | Sandbox options in game: tag: only places, containers and cars not seen yet | 14 |
| `UI_ZeD_Sbx_TagNow` | `Now` | Sandbox options in game: tag at the right of a row: the change takes effect at once | 14 |
| `UI_ZeD_Sbx_TagUndo` | `Can't undo` | Sandbox options in game: tag: the change deletes or changes something for good | 14 |
| `UI_ZeD_Sbx_ThisSave` | `This save: %1` | Sandbox options in game: help band, under On this save; %1 = the value this save has | - |
| `UI_ZeD_Sbx_UndoChanges` | `Undo changes` | Sandbox options in game: action strip button, puts every changed setting back as the save has it | 18 |
| `UI_ZeD_Sbx_WarnCare` | `Careful: you can change it back.` | Sandbox options in game: help band, On this save, first line (yellow) for a setting tagged Careful | - |
| `UI_ZeD_Sbx_WarnUndo` | `Can't be undone.` | Sandbox options in game: help band, On this save, first line (red) for a setting tagged Can't undo | - |
| `UI_ZeD_Sbx_Was` | `was %1` | Sandbox options in game: under a changed setting's name; %1 = its value before the change | - |
| `UI_ZeD_Sbx_WaterOff` | `Water: off since day %1` | Sandbox options in game: World page first line; %1 = the day the water stopped | - |
| `UI_ZeD_Sbx_WaterOnGood` | `Water: on for good` | Sandbox options in game: World page first line, water never shuts off | - |
| `UI_ZeD_Sbx_WaterOnUntil` | `Water: on until day %1` | Sandbox options in game: World page first line; %1 = the day the water stops | - |
| `UI_ZeD_Sbx_WorldDay` | `This world is on day %1 of the count the shut-offs use. %2. %3.` | Sandbox options in game: the first line of the World page. %1 = the world's day number, %2 the water line, %3 the power line (below) | - |

## Seat

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Seat_ByDoor` | `By the %1 door.` | Seat chooser, line under the seat name when a door is pointed; %1 = the seat's name | 40 |
| `UI_ZeD_Seat_DpadMove` | `D-pad Move` | Seat chooser, controller prompt strip: the D-pad's job | 20 |
| `UI_ZeD_Seat_GetOutHere` | `Get out here` | Seat chooser, controller prompt strip: X leaves by the pointed seat's door | 20 |
| `UI_ZeD_Seat_NumberGetOut` | `+ number: Get out` | Seat chooser, keyboard prompt strip: holding Shift and pressing a seat number leaves by that door | 24 |
| `UI_ZeD_Seat_Sit` | `Sit` | Seat chooser, prompt strip: take the pointed seat (A button or number key) | 14 |
| `UI_ZeD_Seat_HelpDoor` | `Get out by this door.` | Seat chooser: help line while the pointer is on a door | - |
| `UI_ZeD_Seat_HelpSeat` | `Take this seat: %1.` | Seat chooser: help line while the pointer is on a seat; %1 = the seat's name | - |
| `UI_ZeD_Seat_HelpCancel` | `Close this and stay where you are.` | Seat chooser: help line over the Cancel button | - |

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
| `UI_ZeD_Server_HeadServer` | `Server` | Server settings screen (Host a game, Manage settings): caps heading in the page list over the server's own setting pages | - |
| `UI_ZeD_Server_LabelAddMap` | `Add a map folder` | Server settings screen (Host a game, Manage settings): caps label over the field that adds a map by folder name | - |
| `UI_ZeD_Server_LabelAddPoint` | `Add a point` | Server settings screen (Host a game, Manage settings): caps label over the field that adds a spawn point | - |
| `UI_ZeD_Server_LabelAddWorkshop` | `Add by Workshop ID` | Server settings screen (Host a game, Manage settings): caps label over the field that adds a Workshop item by its number | - |
| `UI_ZeD_Server_LabelAnotherOccupation` | `Another occupation (its ID)` | Server settings screen (Host a game, Manage settings): caps label over the field that adds an occupation by id | - |
| `UI_ZeD_Server_LabelBecome` | `The files become` | Server settings screen (Host a game, Manage settings): caps heading over the renamed files | - |
| `UI_ZeD_Server_LabelCopies` | `The copies` | Server settings screen (Host a game, Manage settings): caps heading over the copied files | - |
| `UI_ZeD_Server_LabelFiles` | `Its files` | Server settings screen (Host a game, Manage settings): caps heading over the files of the picked settings | - |
| `UI_ZeD_Server_LabelFixedPoint` | `Fixed spawn point (X,Y,Z)` | Server settings screen (Host a game, Manage settings): caps label over the fixed spawn point field | - |
| `UI_ZeD_Server_LabelGo` | `These files go` | Server settings screen (Host a game, Manage settings): caps heading over the files that will be deleted | - |
| `UI_ZeD_Server_LabelMakes` | `It makes these files` | Server settings screen (Host a game, Manage settings): caps heading over the files that a new settings name would make | - |
| `UI_ZeD_Server_LabelMaps` | `Maps (where they overlap, the one higher up wins)` | Server settings screen (Host a game, Manage settings): caps heading over the server's list of maps | - |
| `UI_ZeD_Server_LabelMods` | `The server's mods` | Server settings screen (Host a game, Manage settings): caps heading over the server's list of mods | - |
| `UI_ZeD_Server_LabelOccupations` | `Occupations` | Server settings screen (Host a game, Manage settings): caps heading over the list of occupations on the spawn points page | - |
| `UI_ZeD_Server_LabelPoints` | `Its spawn points (X,Y,Z)` | Server settings screen (Host a game, Manage settings): caps heading over the picked occupation's points | - |
| `UI_ZeD_Server_LabelPreset` | `Start from a preset` | Server settings screen (Host a game, Manage settings): caps heading over the list of sandbox presets | - |
| `UI_ZeD_Server_LabelRegFile` | `File` | Server settings screen (Host a game, Manage settings): caps label at the left of the spawn region's file field | 8 |
| `UI_ZeD_Server_LabelWorkshop` | `Steam Workshop items` | Server settings screen (Host a game, Manage settings): caps heading over the server's Workshop items | - |
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
| `UI_ZeD_Settings_CharAccentTip` | `An accent of its own for the Character window, or the same as Accent color. The window menu's Accent sets it too.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_ContextMenu` | `Context menu` | Options > Mods > ZeD-GUI: name of the right-click menu style setting | - |
| `UI_ZeD_Settings_ContextMenuTip` | `The right-click menu: a strip of icons with the target and what the action needs, or a list, one action to a row, as the game's own.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_ContextStrip` | `Icon strip` | Options > Mods > ZeD-GUI: choice of the Context menu setting | - |
| `UI_ZeD_Settings_Dark` | `Dark` | Options > Mods > ZeD-GUI: base theme choice | - |
| `UI_ZeD_Settings_EquipView` | `Equipped items` | Options > Mods > ZeD-GUI: name of the Equip tab view setting | - |
| `UI_ZeD_Settings_EquipViewTip` | `How the Equip tab shows what you wear: a list, or your character with each slot beside the place it is worn.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_Gamepad` | `Gamepad` | Options > Mods > ZeD-GUI: choice of the Input mode lock setting | - |
| `UI_ZeD_Settings_Glyphs` | `Gamepad glyph display` | Options > Mods > ZeD-GUI: name of the gamepad glyph setting | - |
| `UI_ZeD_Settings_GlyphsTip` | `Which controller's button pictures to show. Auto follows the game's controller button style. Keyboard/mouse and Off show the buttons as lettered boxes.` | Options > Mods > ZeD-GUI: hover help | - |
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
| `UI_ZeD_Settings_MsgCatch` | `Keep other mods' notes in Messages` | ZeD setup, Messages: the switch | - |
| `UI_ZeD_Settings_MsgCatchTip` | `A note another mod opens (one OK button) goes into the Messages window instead of covering the game. Questions still ask at once. Off: every note opens as before.` | ZeD setup, Messages: the help for the switch | - |
| `UI_ZeD_Settings_MsgToast` | `Show a toast when one comes` | ZeD setup, Messages: the switch | - |
| `UI_ZeD_Settings_MsgToastTip` | `A small strip at the right of the screen for six seconds names the mod. Click it to open Messages.` | ZeD setup, Messages: the help for the switch | - |
| `UI_ZeD_Settings_PutBack` | `Put things back after an action` | ZeD setup / Options > Mods > ZeD-GUI: the switch's name | 40 |
| `UI_ZeD_Settings_PutBackTip` | `When on, whatever an action takes out of a bag, a container in reach or off the floor goes back where it came from once the action finishes, leftovers too, and your hands as they were. The game's own move action, so it takes the same game time. Not after an interruption.` | ZeD setup: the help band for Put things back | - |
| `UI_ZeD_Settings_SafeMode` | `Safe mode` | Options > Mods > ZeD-GUI: name of the safe mode setting | - |
| `UI_ZeD_Settings_SafeModeOn` | `On: the game's own interface` | Options > Mods > ZeD-GUI: second choice of the Safe mode setting | - |
| `UI_ZeD_Settings_SafeModeTip` | `On: ZeD-GUI steps aside and the game's own interface is used (its inventory, hotbar, clock, moodles and dashboard) until you turn it Off. Use it if ZeD-GUI ever fails to open. ZeD-GUI also steps aside by itself, for the rest of a session, if it hits an error that keeps repeating.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_SameAsAccent` | `Same as Accent color` | Options > Mods > ZeD-GUI: last choice of the two window accent settings | - |
| `UI_ZeD_Settings_ScaleAuto` | `Auto (fits the screen)` | Options > Mods > ZeD-GUI: first choice of the UI scale setting (the other choices are numbers like 1.5x). Do not use a % sign | - |
| `UI_ZeD_Settings_TestLanguage` | `Test language (stretched text)` | Options > Mods > ZeD-GUI: name of the test language setting | - |
| `UI_ZeD_Settings_TestLanguageTip` | `For checking layouts: every ZeD phrase shows about 40%% longer, accented and in brackets. Leave it Off to play normally.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_TextSize` | `Text size` | Options > Mods > ZeD-GUI: name of the text size setting | - |
| `UI_ZeD_Settings_TextSizeTip` | `Controls font sizes and component dimensions.` | Options > Mods > ZeD-GUI: hover help of the text size setting | - |
| `UI_ZeD_Settings_UiScale` | `UI scale` | Options > Mods > ZeD-GUI: name of the UI scale setting | - |
| `UI_ZeD_Settings_UiScaleTip` | `Auto sizes all of ZeD-GUI to your screen: 1x at 1080p, 2x at 4K. Choose a fixed size to override it (1x is the 1080p size).` | Options > Mods > ZeD-GUI: hover help of the UI scale setting | - |
| `UI_ZeD_Settings_ViewDoll` | `Doll` | Options > Mods > ZeD-GUI: choice of the Equipped items setting: the character figure | - |
| `UI_ZeD_Settings_ViewGrid` | `Grid` | Options > Mods > ZeD-GUI: choice of the Inventory setting: a grid of icons | - |
| `UI_ZeD_Settings_ViewList` | `List` | Options > Mods > ZeD-GUI: choice of the Equipped items, Inventory and Context menu settings | - |
| `UI_ZeD_Settings_Watch` | `Watch` | Options > Mods > ZeD-GUI: name of the watch placement setting | - |
| `UI_ZeD_Settings_WatchBelt` | `On the belt` | Options > Mods > ZeD-GUI: choice of the Watch setting | - |
| `UI_ZeD_Settings_WatchCorner` | `Corner` | Options > Mods > ZeD-GUI: choice of the Watch setting | - |
| `UI_ZeD_Settings_WatchTip` | `Where the watch you wear shows: small on the belt beside the hand of its wrist (press its face for the full watch, which you can drag anywhere), or the full watch in the top right corner.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_WorldAccent` | `World window accent` | Options > Mods > ZeD-GUI: name of the World window accent setting | - |
| `UI_ZeD_Settings_WorldAccentTip` | `An accent of its own for the World window, or the same as Accent color. The window menu's Accent sets it too.` | Options > Mods > ZeD-GUI: hover help | - |
| `UI_ZeD_Settings_SandboxIG` | `Sandbox options in game` | Options, ZeD setup, Sandbox: the switch's name | - |
| `UI_ZeD_Settings_SandboxIGTip` | `Adds a Sandbox options line to the pause window, for changing this save's sandbox settings without starting a new game. Single player only.` | Options, ZeD setup: help band for the switch | - |
| `UI_ZeD_Settings_DimRead` | `Dim read items` | Options, ZeD setup, ZeD windows: the switch's name | - |
| `UI_ZeD_Settings_DimReadTip` | `In the item lists, fades the books, magazines, maps and tapes you have already read, so the unread ones stand out.` | Options, ZeD setup: help band for the switch | - |
| `UI_ZeD_Settings_AmmoBox` | `Ammo on the belt` | Options, ZeD setup, HUD: the switch's name | - |
| `UI_ZeD_Settings_AmmoBoxTip` | `With a gun in your main hand, a pouch beside it on the belt shows the rounds in the gun, one segment each, and what you carry for a reload. Off: the belt as the game has it.` | Options, ZeD setup: help band for the switch | - |
| `UI_ZeD_Settings_ReadMarks` | `Read marks in item lists` | Options, ZeD setup, ZeD windows: the switch's name | - |
| `UI_ZeD_Settings_ReadMarksTip` | `Books, magazines, maps and tapes show whether you have read them: a mark and a word in the lists, a mark in the grid, and the details when you point at them.` | Options, ZeD setup: help band for the switch | - |
| `UI_ZeD_Settings_ReadNext` | `Next level on skill books` | Options, ZeD setup, ZeD windows: the switch's name | - |
| `UI_ZeD_Settings_ReadNextTip` | `Marks the skill books that suit your next level in that skill.` | Options, ZeD setup: help band for the switch | - |
| `UI_ZeD_Settings_DashLamps` | `Dashboard warning lamps` | Options, ZeD setup, HUD: the switch's name | - |
| `UI_ZeD_Settings_DashLampsTip` | `The battery, engine and heater lamps light amber or red when the part is worn, and pointing at a lamp shows the part's condition. Off: the lamps as the game has them.` | Options, ZeD setup: help band for the switch | - |
| `UI_ZeD_Settings_MoodleNotices` | `Moodle notices` | Options, ZeD setup, HUD: the switch's name | - |
| `UI_ZeD_Settings_MoodleNoticesTip` | `A moodle that comes on or changes shows its thought bubble by itself for a few seconds. Off: the bubble shows only when you point at the moodle.` | Options, ZeD setup: help band for the switch | - |
| `UI_ZeD_Settings_SeeThrough` | `See-through` | Options > Mods > ZeD-GUI, and the window menu and the Select wheel: name of the See-through setting | - |
| `UI_ZeD_Settings_SeeThroughTip` | `How much of the game shows through ZeD's windows: 100 is solid, 60 shows the most. Words, lines and controls stay solid.` | Options > Mods > ZeD-GUI: hover help of the See-through setting; 100 is solid, 60 is the most see-through | - |
| `UI_ZeD_Settings_SeeThroughPct` | `%1%%` | Options > Mods > ZeD-GUI, the window menu and the Select wheel: a choice of See-through; %1 = the number, 100 down to 60 (keep the %% for the percent sign) | - |
| `UI_ZeD_Settings_SolidInUse` | `Solid while in use` | Options > Mods > ZeD-GUI, and the window menu and the Select wheel: name of the Solid while in use setting (an on / off choice) | - |
| `UI_ZeD_Settings_SolidInUseTip` | `A window turns solid while the pointer is over it or the controller is in it, and goes back to the See-through setting when you leave it.` | Options > Mods > ZeD-GUI: hover help of the Solid while in use setting | - |
| `UI_ZeD_Settings_FocusStyle` | `Controller highlight` | Options > Mods > ZeD-GUI, and the window menu and the Select wheel: name of the Controller highlight setting | - |
| `UI_ZeD_Settings_FocusStyleTip` | `How the controller marks the thing it is on: a pointing hand, corner marks, one wash of the accent color, or marching ants.` | Options > Mods > ZeD-GUI: hover help of the Controller highlight setting; the four choices are named in the sentence | - |
| `UI_ZeD_Settings_FocusHand` | `Pointing hand` | Options > Mods > ZeD-GUI and the window menu: choice of the Controller highlight setting (a hand points at the control the controller is on) | - |
| `UI_ZeD_Settings_FocusCorners` | `Corner marks` | Options > Mods > ZeD-GUI and the window menu: choice of the Controller highlight setting (marks in the four corners of the control) | - |
| `UI_ZeD_Settings_FocusWash` | `One wash` | Options > Mods > ZeD-GUI and the window menu: choice of the Controller highlight setting (the whole control filled once with the accent color) | - |
| `UI_ZeD_Settings_FocusAnts` | `Marching ants` | Options > Mods > ZeD-GUI and the window menu: choice of the Controller highlight setting (a dashed outline that moves round the control) | - |
| `UI_ZeD_Settings_HiddenActions` | `Hidden actions` | Options > Mods > ZeD-GUI: name of the Hidden actions setting | - |
| `UI_ZeD_Settings_HiddenActionsTip` | `The actions you cannot take right now. Folded: under a hint row you can open. Show all, grayed: every one, grayed out. Hide: none of them.` | Options > Mods > ZeD-GUI: hover help of the Hidden actions setting; the three choices are named in the sentence | - |
| `UI_ZeD_Settings_HiddenFolded` | `Folded: a hint row you can open` | Options > Mods > ZeD-GUI: choice of the Hidden actions setting (actions you cannot take now sit under one row that opens) | - |
| `UI_ZeD_Settings_HiddenAll` | `Show all, grayed` | Options > Mods > ZeD-GUI: choice of the Hidden actions setting (every action stays in the list, grayed out) | - |
| `UI_ZeD_Settings_HiddenHide` | `Hide` | Options > Mods > ZeD-GUI: choice of the Hidden actions setting (actions you cannot take now are left out) | - |

## Siren

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Siren_Dpad` | `D-pad Left / Right: switch   Up / Down: turn` | Siren controller, controller prompt strip: the D-pad's job | 50 |
| `UI_ZeD_Siren_Step` | `Step` | Siren controller, controller prompt strip: A steps the focused switch to its next position | 14 |
| `UI_ZeD_Siren_PromptSwitch` | `Switch` | Siren controller, controller prompt strip: what the left and right D-pad buttons do | 14 |
| `UI_ZeD_Siren_PromptTurn` | `Turn` | Siren controller, controller prompt strip: what the up and down D-pad buttons do (turns the focused switch) | 14 |

## Skills

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Skills_Boost` | `+%1 XP` | Skills tab (Character window): small green pill at the right end of a skill row; %1 is 75%, 100% or 125% (the XP boost from a trait or job) | 12 |
| `UI_ZeD_Skills_StatusCollected` | `Collected` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book in the inventory, not yet read | 12 |
| `UI_ZeD_Skills_StatusMissing` | `Not found` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book not found yet | 12 |
| `UI_ZeD_Skills_StatusRead` | `Read` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book fully read | 12 |
| `UI_ZeD_Skills_StatusReading` | `Reading` | Skills tab (Character window), Training Materials: legend of the coloured squares (shown under the heading, one line, and as the status of each book) - book partly read | 12 |
| `UI_ZeD_Skills_TrainingMaterials` | `Training Materials` | Skills tab (Character window): heading of the skill-book section under the skill grid | 24 |
| `UI_ZeD_Skills_Volume` | `%1 Vol. %2` | Skills tab (Character window), Training Materials: a book row when a skill group is open; %1 is the book's title, %2 its volume number as a roman numeral (I, II, III...) | - |
| `UI_ZeD_Skills_CardLine` | `%1: %2` | Skills tab: a line of a skill row's hover card, a label and its value; %1 = the label, %2 = the value | - |
| `UI_ZeD_Skills_HelpBooksHide` | `Fold the books that train %1.` | Skills tab: help line over the button that folds the skill books of a skill away; %1 = the skill's name | - |
| `UI_ZeD_Skills_HelpBooksShow` | `Show the books that train %1.` | Skills tab: help line over the button that shows the skill books of a skill; %1 = the skill's name | - |
| `UI_ZeD_Skills_HelpHeader` | `Show or hide the skills.` | Skills tab: help line over the Skills header above the list | - |
| `UI_ZeD_Skills_HelpPin` | `Pin %1 to the title bar.` | Skills tab: help line over the pin button of a skill that is not pinned; %1 = the skill's name | - |
| `UI_ZeD_Skills_HelpUnpin` | `Unpin %1 from the title bar.` | Skills tab: help line over the pin button of a skill that is pinned; %1 = the skill's name | - |
| `UI_ZeD_Skills_CardLevel` | `Level %1 \| %2 / %3 XP to level %4` | Skills tab: a skill row's hover card, under the skill's name. %1 level, %2 XP so far in it, %3 XP the level takes, %4 the next level | - |
| `UI_ZeD_Skills_CardMax` | `Level %1` | Skills tab: a skill row's hover card, under the name of a skill at the top level. %1 the level | - |

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

## SPNCC

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_SPNCC_BeardStubble` | `Beard stubble` | Appearance tab with Spongie's Character Customisation (Character window): row label for the beard stubble, over its status | 18 |
| `UI_ZeD_SPNCC_Body` | `Body` | Appearance tab with Spongie's Character Customisation: heading over the stubble and body hair rows | 14 |
| `UI_ZeD_SPNCC_BodyHair` | `Body hair` | Appearance tab with Spongie's Character Customisation: row label for body hair, over its status | 18 |
| `UI_ZeD_SPNCC_Grown` | `Grown` | Appearance tab with Spongie's Character Customisation: status word after a green dot on a stubble or body hair row that has grown (a Shave button follows) | 10 |
| `UI_ZeD_SPNCC_HeadStubble` | `Head stubble` | Appearance tab with Spongie's Character Customisation: row label for the head stubble, over its status | 18 |
| `UI_ZeD_SPNCC_MuscleFrom` | `Shows from Strength 6` | Appearance tab with Spongie's Character Customisation: value of the Muscle row when the server shows muscle from Strength 6 | 28 |
| `UI_ZeD_SPNCC_MuscleOff` | `Not shown` | Appearance tab with Spongie's Character Customisation: value of the Muscle row when the server does not show muscle | 14 |
| `UI_ZeD_SPNCC_NewText` | `Spongie's Character Customisation is new to this save. Choose a face and details, then Save. The game waits, paused, until you save or close this window.` | Appearance tab with Spongie's Character Customisation: body of the banner shown when the mod is new to the save; the game is paused until Save or close | - |
| `UI_ZeD_SPNCC_NewTitle` | `New to this save` | Appearance tab with Spongie's Character Customisation: title of the banner shown when the mod is new to the save | 30 |
| `UI_ZeD_SPNCC_NoDetails` | `None of the mods on adds details.` | Appearance tab with Spongie's Character Customisation: dim line under the Details heading when no mod provides any | - |
| `UI_ZeD_SPNCC_None` | `None` | Appearance tab with Spongie's Character Customisation: status word after a hollow dot on a stubble or body hair row with nothing grown | 10 |
| `UI_ZeD_SPNCC_NoneWorn` | `None` | Appearance tab with Spongie's Character Customisation: dim line in a read-only list (the server does not let the player change it) when no face or detail is chosen | 14 |
| `UI_ZeD_SPNCC_NotSaved` | `Not saved` | Appearance tab with Spongie's Character Customisation: word in the bottom strip when something was changed since the last save | 14 |
| `UI_ZeD_SPNCC_NotSavedYet` | `Not saved yet` | Appearance tab with Spongie's Character Customisation: word in the bottom strip when the character has never been saved with the mod | 18 |
| `UI_ZeD_SPNCC_Saved` | `Saved` | Appearance tab with Spongie's Character Customisation: word in the bottom strip when nothing was changed since the last save | 14 |
| `UI_ZeD_SPNCC_Shaving` | `Shaving` | Appearance tab with Spongie's Character Customisation: status word after an accent dot on a stubble or body hair row while the shave runs | 10 |
| `UI_ZeD_SPNCC_SpiffoText` | `While you carry it, the face and details can change.` | Appearance tab with Spongie's Character Customisation: body of the banner shown when the server limits changes to carrying a Spiffo item | - |
| `UI_ZeD_SPNCC_SpiffoTitle` | `Appearance changing Spiffo` | Appearance tab with Spongie's Character Customisation: title of the banner shown when the server limits changes to carrying a Spiffo item | 30 |
| `UI_ZeD_SPNCC_HelpCheck` | `Turn %1 on or off.` | Appearance tab with Spongie's Character Customisation: help line over a check box; %1 = its label | - |
| `UI_ZeD_SPNCC_HelpShave` | `Shave: %1.` | Appearance tab with Spongie's Character Customisation: help line over a Shave button when a razor is at hand; %1 = the row's label | - |
| `UI_ZeD_SPNCC_HelpTile` | `Choose %1.` | Appearance tab with Spongie's Character Customisation: help line over a picture tile or list row that is not chosen; %1 = the option's name | - |
| `UI_ZeD_SPNCC_HelpTileOn` | `%1 is chosen.` | Appearance tab with Spongie's Character Customisation: help line over a picture tile or list row that is chosen; %1 = the option's name | - |
| `UI_ZeD_SPNCC_TurnLeft` | `Turn left` | Appearance tab with Spongie's Character Customisation: hover hint of the button that turns the preview figure left (icon-only button) | - |
| `UI_ZeD_SPNCC_TurnRight` | `Turn right` | Appearance tab with Spongie's Character Customisation: hover hint of the button that turns the preview figure right (icon-only button) | - |
| `UI_ZeD_SPNCC_ViewList` | `List` | Appearance tab with Spongie's Character Customisation: hover hint of the button that shows the options as a list | - |
| `UI_ZeD_SPNCC_ViewPictures` | `Pictures` | Appearance tab with Spongie's Character Customisation: hover hint of the button that shows the options as picture tiles | - |
| `UI_ZeD_SPNCC_ZoomIn` | `Zoom in` | Appearance tab with Spongie's Character Customisation: hover hint of the button that zooms the preview figure in (icon-only button) | - |
| `UI_ZeD_SPNCC_ZoomOut` | `Zoom out` | Appearance tab with Spongie's Character Customisation: hover hint of the button that zooms the preview figure out (icon-only button) | - |

## SRJ

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_SRJ_NotWrittenTotal` | `%1 XP not yet written` | Skills tab with Skill Recovery Journal: the key line, right side. %1 XP of all skills not yet written into the journal | - |
| `UI_ZeD_SRJ_JournalOn` | `%1 on you` | Skills tab with Skill Recovery Journal: the key line when a journal is carried. %1 the journal's name (Bound Journal) | - |
| `UI_ZeD_SRJ_JournalNone` | `No %1 on you` | Skills tab with Skill Recovery Journal: the key line when no journal is carried. %1 the journal's name (Bound Journal) | - |
| `UI_ZeD_SRJ_WrittenBy` | `written by %1` | Skills tab with Skill Recovery Journal: after the journal, who wrote it. %1 a character's name | - |
| `UI_ZeD_SRJ_JournalIn` | `in %1` | Skills tab with Skill Recovery Journal: after the journal, where it is. %1 Inventory or a bag's name | - |
| `UI_ZeD_SRJ_StaysRecorded` | `what you wrote stays recorded` | Skills tab with Skill Recovery Journal: after No Bound Journal on you (the record is kept with the character, not the book) | - |
| `UI_ZeD_SRJ_NoteOn` | `%1 XP not yet written. Transcribe Into Journal on the Bound Journal keeps it.` | Skills tab with Skill Recovery Journal: a skill's hover card, last line, with a journal carried. %1 XP; Transcribe Into Journal is the mod's menu entry | - |
| `UI_ZeD_SRJ_NoteNone` | `%1 XP not yet written. Carry the journal and use Transcribe Into Journal on it to keep it.` | Skills tab with Skill Recovery Journal: a skill's hover card, last line, no journal carried. %1 XP | - |
| `UI_ZeD_SRJ_NoteAll` | `All of it is written down.` | Skills tab with Skill Recovery Journal: a skill's hover card, last line, when nothing is left to write | - |

## Station

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Station_AnySurface` | `Any surface` | Craft tab, station dropdown: small note on the Hand row | 14 |
| `UI_ZeD_Station_Fallback` | `Station` | Craft tab, station select and band: name when the station has none | - |
| `UI_ZeD_Station_Hand` | `Hand` | Craft tab, station dropdown and select: crafting with no station, by hand | 18 |
| `UI_ZeD_Station_InReach` | `Within reach` | Craft tab, station dropdown: heading above the stations you can use | 24 |
| `UI_ZeD_Station_InUse` | `In use` | Craft tab, station dropdown: small note on a station someone else is using | 14 |
| `UI_ZeD_Station_KindAppliance` | `Appliance` | Craft tab, station band: kind word after the distance | 12 |
| `UI_ZeD_Station_KindBench` | `Bench` | Craft tab, station band: kind word after the distance | 12 |
| `UI_ZeD_Station_KindMachine` | `Machine` | Craft tab, station band: kind word after the distance | 12 |
| `UI_ZeD_Station_Leave` | `Leave station` | Controller prompt for B in the Craft tab while a station is chosen | 16 |
| `UI_ZeD_Station_ListComma` | `%1, %2` | Craft tab, recipe card: joins stations in a list of three or more | - |
| `UI_ZeD_Station_ListOr` | `%1 or %2` | Craft tab, recipe card: joins the last two stations a recipe accepts (Simple Forge or Advanced Forge) | - |
| `UI_ZeD_Station_NearestMany` | `The nearest is %1 tiles away.` | Craft tab, recipe card: second line when the needed station is several tiles away | - |
| `UI_ZeD_Station_NearestOne` | `The nearest is 1 tile away.` | Craft tab, recipe card: second line when the needed station is 1 tile away | - |
| `UI_ZeD_Station_NeedsA` | `Needs a %1.` | Craft tab, recipe card: the station a recipe needs (name starts with a consonant) | - |
| `UI_ZeD_Station_NeedsAn` | `Needs an %1.` | Craft tab, recipe card: the station a recipe needs (name starts with a vowel) | - |
| `UI_ZeD_Station_NoneInReach` | `Nothing within reach` | Craft tab, station dropdown: heading when no station is near | 24 |
| `UI_ZeD_Station_SelectLabel` | `Station` | Craft tab: small label inside the station select box | 10 |
| `UI_ZeD_Station_ShortBarrel` | `Barrel` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortBeam` | `Beam` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortCharcoal` | `Charcoal` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortCoffee` | `Coffee` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortFallback` | `Station` | Craft tab, recipe row and card badge: short name when a recipe's station has no short name | 9 |
| `UI_ZeD_Station_ShortMill` | `Mill` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortQuern` | `Quern` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_ShortRack` | `Rack` | Craft tab, recipe row and card badge: short name of the station a recipe needs | 9 |
| `UI_ZeD_Station_StateIdle` | `Idle` | Craft tab, station band: a machine that is not working | 16 |
| `UI_ZeD_Station_StateInUseByYou` | `In use by you` | Craft tab, station band: state of the bench you stand at | 16 |
| `UI_ZeD_Station_StateNoPower` | `No power` | Craft tab, station band: an appliance with no power | 16 |
| `UI_ZeD_Station_StateRunning` | `Running` | Craft tab, station band: a machine that is working | 16 |
| `UI_ZeD_Station_TileMany` | `%1 tiles` | Craft tab, station band and station list: distance to the station | 10 |
| `UI_ZeD_Station_TileOne` | `1 tile` | Craft tab, station band and station list: distance to the station | 10 |

## Status

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Status_Danger` | `Danger` | Status chip text, red. | 10 |
| `UI_ZeD_Status_Info` | `Info` | Status chip text, blue. | 10 |
| `UI_ZeD_Status_Warning` | `Warning` | Status chip text, amber. | 10 |

## Strip

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Strip_OwnedCount` | `%1/%2 owned` | Crafting list, alternative-items strip, centre readout: items owned of items needed | 18 |
| `UI_ZeD_Strip_OwnedOnly` | `Owned only` | Crafting list, alternative-items strip, toggle that hides items you do not own | 16 |
| `UI_ZeD_Strip_Sort` | `Sort` | Crafting list, label at the left of the sort strip | 8 |

## TAS

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_TAS_All` | `All (%1)` | Traits tab: left half of the All / With a trait switch; %1 is how many ladders | 16 |
| `UI_ZeD_TAS_And` | `%1 and %2` | Traits tab, details: joins the last two skill names | - |
| `UI_ZeD_TAS_At` | `at %1: %2` | Traits tab, details: Level up line; %1 the first level that changes something, %2 what it changes | - |
| `UI_ZeD_TAS_Bad` | `%1 negative` | Traits tab: summary line, how many bad traits (a red dot before it) | 12 |
| `UI_ZeD_TAS_Category` | `Category: %1` | Traits tab, details: at the right of the title; %1 is the mod's category name | - |
| `UI_ZeD_TAS_Credit` | `%1 by %2` | Traits tab (Character window, with the Traits As Skills mod): small line at the top naming the mod; %1 is the mod's name, %2 its author | - |
| `UI_ZeD_TAS_DownAt` | `Level down at %1: %2` | Traits tab, details: after the Level up line; %1 the first level down that changes something, %2 what it changes | - |
| `UI_ZeD_TAS_Find` | `Find` | Traits tab: placeholder in the Find box at the right of the tab's heading | 12 |
| `UI_ZeD_TAS_Follows` | `Follows your %1 skill: %2` | Traits tab, details: a ladder that follows one skill; %1 the skill's name, %2 its level with a decimal | - |
| `UI_ZeD_TAS_FollowsAvg` | `Follows your %1 skills (the average): %2` | Traits tab, details: a ladder that follows several skills; %1 their names, %2 their average level | - |
| `UI_ZeD_TAS_GainT` | `gain %1` | Traits tab, details: a trait a level gives; %1 is the trait's name | - |
| `UI_ZeD_TAS_Good` | `%1 positive` | Traits tab: summary line, how many good traits the ladders give now (a green dot before it) | 12 |
| `UI_ZeD_TAS_Here` | `You are here` | Traits tab: hover hint over the step the character stands on | - |
| `UI_ZeD_TAS_KLevelUp` | `Level up` | Traits tab, details: label of the line that says what the next level changes | 10 |
| `UI_ZeD_TAS_KNow` | `Now` | Traits tab, details: label of the line with the trait's description | 10 |
| `UI_ZeD_TAS_KProgress` | `Progress` | Traits tab, details: label of the progress line | 10 |
| `UI_ZeD_TAS_LevelOf` | `Level %1 of 10` | Traits tab, details: beside the ladder's name | 14 |
| `UI_ZeD_TAS_LoseT` | `lose %1` | Traits tab, details: a trait a level takes away; %1 is the trait's name | - |
| `UI_ZeD_TAS_New` | `New` | Traits tab: small tag beside a trait gained since the tab was last opened | 5 |
| `UI_ZeD_TAS_NoChange` | `no change` | Traits tab, details: a level that changes nothing | - |
| `UI_ZeD_TAS_NoChangeAbove` | `no change above` | Traits tab, details: Level up line when no higher level changes anything | - |
| `UI_ZeD_TAS_NoDesc` | `(the game gives this trait no description)` | Traits tab, details: after a trait's name when the game has no description for it | - |
| `UI_ZeD_TAS_NoTrait` | `No trait` | Traits tab: at the right of a ladder that gives no trait now; also a step's hover hint | 14 |
| `UI_ZeD_TAS_NoTraitN` | `%1 with no trait` | Traits tab: summary line, how many ladders give no trait now | 20 |
| `UI_ZeD_TAS_NoneList` | `None` | Traits tab, details: the Gain or Lose line when the mod lists nothing | - |
| `UI_ZeD_TAS_NoneShort` | `none` | Traits tab, details: under a range of the ladder that holds no trait | 8 |
| `UI_ZeD_TAS_Nothing` | `Nothing matches "%1".` | Traits tab: in place of the list when Find matches nothing; %1 is what was typed | - |
| `UI_ZeD_TAS_NowNone` | `No trait at this level.` | Traits tab, details: the Now line when the ladder gives no trait | - |
| `UI_ZeD_TAS_Or` | `%1 or %2` | Traits tab: hover hint over a step whose range holds a pair of traits (either one) | - |
| `UI_ZeD_TAS_Pick` | `Choose a row to see its ladder, what raises or lowers it, and what the next level changes.` | Traits tab: the details panel at the foot before a row is picked | - |
| `UI_ZeD_TAS_StepTitle` | `%1 level %2` | Traits tab: hover hint over one of a row's ten steps; %1 the ladder, %2 the level | - |
| `UI_ZeD_TAS_TopLevel` | `Top level` | Traits tab, details: progress line of a ladder at level 10 | - |
| `UI_ZeD_TAS_WeightKg` | `Weight: %1 kg` | Traits tab, details: progress line of the Weight ladder; %1 is the character's weight | - |
| `UI_ZeD_TAS_WithTrait` | `With a trait (%1)` | Traits tab: right half of the switch, only the ladders that give the character a trait now; %1 is how many | 22 |
| `UI_ZeD_TAS_XpTo` | `XP: %1 / %2 to level %3` | Traits tab, details: progress of a ladder that levels by XP; %1 XP so far, %2 the XP the level needs, %3 the next level | - |
| `UI_ZeD_TAS_HelpCatHide` | `Fold the %1 ladders.` | Traits tab: help line over a category heading whose ladders are showing; %1 = the category's name | - |
| `UI_ZeD_TAS_HelpCatShow` | `Show the %1 ladders.` | Traits tab: help line over a category heading whose ladders are folded away; %1 = the category's name | - |
| `UI_ZeD_TAS_HelpOnly` | `Show: %1.` | Traits tab: help line over a half of the All / With a trait switch; %1 = that half's label | - |
| `UI_ZeD_TAS_HelpRow` | `Show the details of %1.` | Traits tab: help line over a ladder row; %1 = the ladder's name | - |

## Target

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Target_Selection` | `Selection` | Right-click menu, target card name when the clicked items cannot be named | - |
| `UI_ZeD_Target_Survivor` | `Survivor` | Right-click menu, target card name when a character has no name | - |

## Thermal

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Thermal_Air` | `Air` | Thermal tab, readout line above the gradient bar: label before the air temperature | 8 |
| `UI_ZeD_Thermal_ByRegion` | `%1 by region` | Thermal tab, heading over the two-column body part grid; %1 is the active view's name (Skin temp, Insulation...) | - |
| `UI_ZeD_Thermal_Core` | `Core` | Thermal tab, readout line above the gradient bar: label before the core temperature | 8 |
| `UI_ZeD_Thermal_RowShiver` | `Shiver / sweat` | Thermal tab hover detail (body part rolled over): stat row label, with the other seven metrics | 20 |
| `UI_ZeD_Thermal_TempC` | `%1°C` | Thermal tab: a temperature when the player's game option shows Celsius (core/air/wind line, skin temperature rows). %1 is the number with one decimal | 10 |
| `UI_ZeD_Thermal_TempF` | `%1°F` | Thermal tab: a temperature when the player's game option shows Fahrenheit. %1 is the converted number with one decimal | 10 |
| `UI_ZeD_Thermal_ViewShiver` | `Shiver / sweat` | Thermal tab (Character window): view button in the column beside the body figure, one of seven stacked pills (full column width) | 18 |
| `UI_ZeD_Thermal_ViewWetness` | `Wetness` | Thermal tab (Character window): view button in the column beside the body figure, one of seven stacked pills (full column width) | 18 |
| `UI_ZeD_Thermal_HelpHeader` | `Show or hide the body figure.` | Thermal tab (Character window): help line over the header above the body figure | - |
| `UI_ZeD_Thermal_HelpView` | `Color the figure by %1.` | Thermal tab (Character window): help line over a view button; %1 = the view's name (the game's own word) | - |

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
| `UI_ZeD_Track_TrackingLevel` | `\| Tracking %1` | Animal track card: small dim text after the species; %1 is the player's Tracking level (the bar is a separator) | 16 |

## Traits

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Traits_AskDelete` | `Delete the build %1?` | Occupation and traits screen (new game): question in the action strip. %1 is the build's name | - |
| `UI_ZeD_Traits_AskName` | `Build name:` | Occupation and traits screen (new game): label before the name field in the action strip | - |
| `UI_ZeD_Traits_Builds` | `Builds...` | Occupation and traits screen (new game): strip button that opens the Builds pop-up | 14 |
| `UI_ZeD_Traits_ClearTraits` | `Reset traits` | Occupation and traits screen (new game): strip button that gives back every chosen trait | 16 |
| `UI_ZeD_Traits_DeleteBuild` | `Delete %1...` | Occupation and traits screen (new game): row of the Builds pop-up. %1 is the saved build's name | - |
| `UI_ZeD_Traits_FromOccupation` | `From the occupation.` | Occupation and traits screen (new game): added to the help of a trait the occupation gives for free | - |
| `UI_ZeD_Traits_HeadChosen` | `Chosen` | Occupation and traits screen (new game): caps heading over the chosen traits | - |
| `UI_ZeD_Traits_HeadNegative` | `Negative` | Occupation and traits screen (new game): caps heading over the negative traits column | - |
| `UI_ZeD_Traits_HeadPositive` | `Positive` | Occupation and traits screen (new game): caps heading over the positive traits column | - |
| `UI_ZeD_Traits_HeadSkills` | `Starting skills` | Occupation and traits screen (new game): caps heading over the starting skills list | - |
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
| `UI_ZeD_Trough_Animals` | `Animals` | Feeding trough card: label of the number of animals using the trough | 12 |
| `UI_ZeD_Trough_ConfirmEmpty` | `Pour %1 of %2 out of the trough?` | Feeding trough card: confirmation in the footer; %1 is the amount, e.g. 4.5 L, %2 the liquid's name in lower case | - |
| `UI_ZeD_Trough_Feed` | `Feed` | Feeding trough card: small word after the big feed amount | 8 |
| `UI_ZeD_Trough_InTrough` | `In the trough` | Feeding trough card: section heading over the list of feed lying in the trough | - |
| `UI_ZeD_Trough_LinkedTo` | `Linked to` | Feeding trough card: label of the zone's name (the half-width column holds about 14 letters) | 14 |
| `UI_ZeD_Trough_NeedAddFood` | `Add food: %1` | Feeding trough card: the NEEDS line when the trough holds water; %1 is the game's own reason | - |
| `UI_ZeD_Trough_NeedAddWater` | `Add water: %1` | Feeding trough card: the NEEDS line when the trough holds feed; %1 is the game's own reason | - |
| `UI_ZeD_Trough_NothingToAdd` | `You carry nothing the trough takes.` | Feeding trough card: line under YOUR FEED when you have no feed | - |
| `UI_ZeD_Trough_NoZoneWarn` | `Not in an animal zone. Animals only eat and drink from troughs inside their zone.` | Feeding trough card: warning band (red) at the top | - |
| `UI_ZeD_Trough_PillFood` | `Food` | Feeding trough card: header pill for a trough holding feed | 10 |
| `UI_ZeD_Trough_UseIt` | `%1 use it` | Feeding trough card: value of ANIMALS; %1 is how many animals use the trough | 16 |
| `UI_ZeD_Trough_WaterUnit` | `L of %1 \| %2` | Feeding trough card: small text after the big water amount: litres of the trough's maximum, then the liquid; %1 is the maximum, e.g. 8.0 L, %2 the liquid (the bar is a separator) | 30 |
| `UI_ZeD_Trough_WaterWord` | `Water` | Feeding trough card: the word for the trough's water when the game names no liquid (also used lower-cased in the empty-out question) | 14 |
| `UI_ZeD_Trough_YourFeed` | `Your feed` | Feeding trough card: section heading over the list of feed you carry | - |
| `UI_ZeD_Trough_Zone` | `Zone` | Feeding trough card: section heading over the zone lines | - |
| `UI_ZeD_Trough_ZoneLinked` | `Linked` | Feeding trough card: right side of the ZONE heading when the trough is in an animal zone | 10 |
| `UI_ZeD_Trough_HelpEmpty` | `Empty: pour the water out of the trough` | Feeding trough card: help line over the Empty button | - |
| `UI_ZeD_Trough_HelpFeed` | `Add: put %1 in the trough` | Feeding trough card: help line over the Add button on a feed row; %1 = the feed's name | - |
| `UI_ZeD_Trough_HelpFood` | `Add food: pick feed from your bags` | Feeding trough card: help line over the Add food button | - |
| `UI_ZeD_Trough_HelpPour` | `Pour: pour %1 into the trough` | Feeding trough card: help line over the Pour button on a water container row; %1 = the container's name | - |
| `UI_ZeD_Trough_HelpTake` | `Take: move %1 out to your bags` | Feeding trough card: help line over the Take button on a feed row; %1 = the feed's name | - |
| `UI_ZeD_Trough_HelpWater` | `Add water: pour water in from a container` | Feeding trough card: help line over the Add water button | - |
| `UI_ZeD_Trough_HintFood` | `add food` | Feeding trough card: what Add food does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Trough_NeedsFeed` | `feed in your bags` | Feeding trough card: what Add food needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Trough_QEmpty` | `Empty the trough? %1 of %2 is lost.` | Feeding trough card: the question in the footer after Empty is pressed; %1 = the amount, e.g. 1.25 L, %2 = the liquid's name in lower case; the footer then offers a yes and a no | - |

## Veh

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Veh_About` | `About` | Vehicle tab part card: heading above the part's description | 12 |
| `UI_ZeD_Veh_ActClosingLid` | `Closing the lid` | Vehicle tab animal trailer page: progress band text while the trunk lid closes | 24 |
| `UI_ZeD_Veh_ActFeeding` | `Feeding` | Vehicle tab animal trailer page: progress band text while an animal is fed | 24 |
| `UI_ZeD_Veh_ActGivingWater` | `Giving water` | Vehicle tab animal trailer page: progress band text while an animal is watered | 24 |
| `UI_ZeD_Veh_ActGrabbing` | `Grabbing` | Vehicle tab animal trailer page: progress band text while an animal is picked up out of the trailer | 24 |
| `UI_ZeD_Veh_ActOpeningLid` | `Opening the lid` | Vehicle tab animal trailer page: progress band text while the trunk lid opens | 24 |
| `UI_ZeD_Veh_ActPuttingIn` | `Putting in` | Vehicle tab animal trailer page: progress band text while an animal is loaded | 24 |
| `UI_ZeD_Veh_ActTakingOut` | `Taking out` | Vehicle tab animal trailer page: progress band text while an animal is taken out | 24 |
| `UI_ZeD_Veh_ActUnlockingLid` | `Unlocking the lid` | Vehicle tab animal trailer page: progress band text while the trunk lid is unlocked | 24 |
| `UI_ZeD_Veh_ActWalkingBack` | `Walking to the back` | Vehicle tab animal trailer page: progress band text while the character walks to the back door first | 28 |
| `UI_ZeD_Veh_AirInTire` | `Air in the tire` | Vehicle tab part card, NEEDS list for Deflate: requirement line | 24 |
| `UI_ZeD_Veh_AmountLeft` | `%1 left` | Vehicle tab part card, NEEDS list: how much is still in the part (%1 = amount) | 12 |
| `UI_ZeD_Veh_AtBack` | `At the back` | Vehicle tab animal trailer page, Load from here list: the animal is right at the back door | 20 |
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
| `UI_ZeD_Veh_Failed` | `Failed` | Vehicle tab: progress band text after an install or uninstall went wrong | 10 |
| `UI_ZeD_Veh_FailurePct` | `Failure %1` | Vehicle tab part card: chance bar label, right (%1 = percentage with its % sign) | 16 |
| `UI_ZeD_Veh_FixMissing` | `missing %1` | Vehicle tab part card, repair list second line: why a repair cannot be done (%1 = item name) | 30 |
| `UI_ZeD_Veh_FixOutcome` | `+%1 \| %2 success` | Vehicle tab part card, repair list second line: condition gained and chance of success (both with % signs) | 24 |
| `UI_ZeD_Veh_FixSkillLow` | `skill too low` | Vehicle tab part card, repair list second line: why a repair cannot be done | 20 |
| `UI_ZeD_Veh_Friction` | `Friction` | Vehicle tab: tire friction label (summary and card) | 12 |
| `UI_ZeD_Veh_FromBags` | `From your bags and nearby` | Vehicle tab part card for Install: heading above the list of parts you can fit | 34 |
| `UI_ZeD_Veh_FromYourBags` | `From your bags` | Vehicle tab animal trailer animal card: right-hand tag on the Give water heading | 20 |
| `UI_ZeD_Veh_GrabWhy` | `Grab: %1` | Vehicle tab animal trailer animal card, NEEDS list: why the animal cannot be grabbed (%1 = vanilla's reason, e.g. too heavy) | 50 |
| `UI_ZeD_Veh_HdrCond` | `Cond` | Vehicle tab part list: column heading for condition, click to sort by condition | 8 |
| `UI_ZeD_Veh_HdrInfo` | `Info` | Vehicle tab part list: column heading | 8 |
| `UI_ZeD_Veh_HdrPart` | `Part` | Vehicle tab part list: column heading, click to sort by area | 8 |
| `UI_ZeD_Veh_Hp` | `%1 hp` | Vehicle tab: engine power value (%1 = horsepower number) | 10 |
| `UI_ZeD_Veh_InspectThe` | `Inspect the %1 to read its parts` | Vehicle tab (not inspected yet): empty-state line under the car figure (%1 = vehicle name) | 60 |
| `UI_ZeD_Veh_InspectToRead` | `Inspect to read` | Vehicle tab (animal trailer, not yet inspected): right-hand tag on the collapsed part list | 20 |
| `UI_ZeD_Veh_InYourHands` | `In your hands` | Vehicle tab animal trailer page, Load from here list: the animal or carcass you are carrying | 20 |
| `UI_ZeD_Veh_KeyHotwired` | `Hotwired` | Vehicle tab, Key row: the vehicle has been hotwired | 14 |
| `UI_ZeD_Veh_KeyNotNeeded` | `Not needed` | Vehicle tab, Key row: no key is needed for this vehicle | 14 |
| `UI_ZeD_Veh_KeyOnYou` | `On you` | Vehicle tab, Key row: the car key is in your inventory | 14 |
| `UI_ZeD_Veh_KgCaps` | `%1 kg` | Vehicle tab animal trailer animal card, NEEDS list: small right-hand tag with the animal's weight (%1 = number) | 10 |
| `UI_ZeD_Veh_KMustBeOff` | `Must be off` | Vehicle tab part card, NEEDS list: small right-hand tag, another part must be taken off first | 14 |
| `UI_ZeD_Veh_KMustBeOn` | `Must be on` | Vehicle tab part card, NEEDS list: small right-hand tag, another part must be installed first | 14 |
| `UI_ZeD_Veh_Known` | `Known` | Vehicle tab part card, NEEDS list: value when you know the required recipe | 12 |
| `UI_ZeD_Veh_KRecipe` | `Recipe` | Vehicle tab part card, NEEDS list: small right-hand tag on a required recipe | 12 |
| `UI_ZeD_Veh_KRequired` | `Required` | Vehicle tab part card, NEEDS list: small right-hand tag on a required skill level | 12 |
| `UI_ZeD_Veh_KToReachIn` | `To reach in` | Vehicle tab animal trailer animal card, NEEDS list: small right-hand tag on the trunk lid requirement | 14 |
| `UI_ZeD_Veh_KWithinReach` | `Within reach` | Vehicle tab part card, NEEDS list for Install: small right-hand tag | 16 |
| `UI_ZeD_Veh_LidOpen` | `Trunk lid open` | Vehicle tab animal trailer animal card, NEEDS list: requirement line, met | 24 |
| `UI_ZeD_Veh_LoadFromHere` | `Load from here` | Vehicle tab animal trailer page: list heading for animals that can be loaded from where you stand | 20 |
| `UI_ZeD_Veh_LocInHand` | `In hand` | Vehicle tab animal trailer card, water and feed lists: where an item is, small second line (item is in a hand) | 14 |
| `UI_ZeD_Veh_Lock` | `Lock` | Vehicle tab door card: label of the row that shows the lock is broken | 10 |
| `UI_ZeD_Veh_Loudness` | `Loudness` | Vehicle tab: engine loudness label (summary and cards) | 12 |
| `UI_ZeD_Veh_LowersEngine` | `Lowers the engine's condition` | Vehicle tab part card, NEEDS list for Take parts: warning line | 36 |
| `UI_ZeD_Veh_MissingWorn` | `%1 missing  \|  %2 worn` | Vehicle tab summary: status line (%1 = missing or smashed parts, %2 = parts at 60% or less) | 30 |
| `UI_ZeD_Veh_NeedPart` | `A part to install` | Vehicle tab part card, NEEDS list for Install: requirement line | 30 |
| `UI_ZeD_Veh_NeedsFor` | `Needs \| %1` | Vehicle tab part card: heading above the NEEDS list (%1 = the action name) | 30 |
| `UI_ZeD_Veh_NoAnimalsInside` | `No animals inside` | Vehicle tab animal trailer page: empty-state line in the Animals list | 30 |
| `UI_ZeD_Veh_NoneNearby` | `None nearby` | Vehicle tab part card for Install: right-hand tag on a part type you do not have | 16 |
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
| `UI_ZeD_Veh_Overall` | `Overall` | Vehicle tab summary: label above the overall condition bar | 12 |
| `UI_ZeD_Veh_PartEmpty` | `%1 empty` | Vehicle tab part card, NEEDS list: requirement that the part is empty (%1 = part name) | 30 |
| `UI_ZeD_Veh_PartsClosed` | `> Parts (%1)` | Vehicle tab (animal trailer, not yet inspected): collapsed heading of the part list (%1 = part count) | 16 |
| `UI_ZeD_Veh_Power` | `Power` | Vehicle tab: engine power label (summary and engine card) | 12 |
| `UI_ZeD_Veh_Pressure` | `Pressure` | Vehicle tab tire card: label of the air pressure row | 12 |
| `UI_ZeD_Veh_Psi` | `%1 psi` | Vehicle tab part card, NEEDS list: air pressure reading (%1 = number) | 12 |
| `UI_ZeD_Veh_PsiOf` | `%1 / %2 psi` | Vehicle tab: tire air pressure, current over normal, in the part list and on a tire's card (%1 current, %2 normal) | 20 |
| `UI_ZeD_Veh_PutIn` | `Put in` | Vehicle tab animal trailer page, Load from here list: small button that loads the animal | 12 |
| `UI_ZeD_Veh_ReadyCarcass` | `Ready to take the carcass out at the back` | Vehicle tab animal trailer animal card, footer status for a dead animal | 50 |
| `UI_ZeD_Veh_ReadyInstall` | `Ready to install` | Vehicle tab part card, footer: status when an install can start | 30 |
| `UI_ZeD_Veh_ReadyInstallItem` | `Ready to install %1` | Vehicle tab part card, footer: status when an install can start (%1 = item name) | 50 |
| `UI_ZeD_Veh_ReadyRepair` | `Ready to repair` | Vehicle tab part card, footer: status when a repair can start | 30 |
| `UI_ZeD_Veh_ReadyRepairWith` | `Ready to repair with %1` | Vehicle tab part card, footer: status when a repair can start (%1 = item name) | 50 |
| `UI_ZeD_Veh_ReadyTo` | `Ready to %1` | Vehicle tab part card, footer: status when an action can start (%1 = action name in lower case) | 36 |
| `UI_ZeD_Veh_ReadyWalkHer` | `Ready to walk her out at the back` | Vehicle tab animal trailer animal card, footer status for a female animal | 46 |
| `UI_ZeD_Veh_ReadyWalkHim` | `Ready to walk him out at the back` | Vehicle tab animal trailer animal card, footer status for a male animal | 46 |
| `UI_ZeD_Veh_Removed` | `Removed` | Vehicle tab part card, NEEDS list: value when another part has been removed as required | 12 |
| `UI_ZeD_Veh_RepairWith` | `Repair with` | Vehicle tab part card for Repair: heading above the list of repair options | 20 |
| `UI_ZeD_Veh_Seat` | `Seat` | Vehicle tab seat card: label of the row that shows the seat is occupied | 12 |
| `UI_ZeD_Veh_SizeHdr` | `Size` | Vehicle tab animal trailer page: right-hand tag on the Load from here heading (how much space each animal takes) | 8 |
| `UI_ZeD_Veh_Smashed` | `Smashed` | Vehicle tab: window state, in the summary, the card's Condition row and the part list badge | 12 |
| `UI_ZeD_Veh_Space` | `Space` | Vehicle tab animal trailer page: label for the trailer's animal capacity (summary row, list heading tag, row column, card) | 12 |
| `UI_ZeD_Veh_SpaceLeft` | `%1 of %2 \| %3 left` | Vehicle tab animal trailer summary, Space row: used, capacity and how much is left (%1 used, %2 capacity, %3 left) | 28 |
| `UI_ZeD_Veh_SpaceOver` | `%1 of %2 \| %3 over` | Vehicle tab animal trailer summary, Space row: used, capacity and how far over it is (%1 used, %2 capacity, %3 over) | 28 |
| `UI_ZeD_Veh_State` | `State` | Vehicle tab summary of a highlighted part: label of the row that shows its state (open, locked, charge...) | 12 |
| `UI_ZeD_Veh_StClosed` | `Closed` | Vehicle tab part list, info column: the door is closed | 10 |
| `UI_ZeD_Veh_StOccupied` | `Occupied` | Vehicle tab: a seat has someone in it (part list info column, and the Seat row on a seat card) | 12 |
| `UI_ZeD_Veh_StOpen` | `Open` | Vehicle tab: state of a door or window (part list info column) and the label of the Open row on a door or window card | 10 |
| `UI_ZeD_Veh_SuccessPct` | `Success %1` | Vehicle tab part card: chance bar label, left (%1 = percentage with its % sign) | 16 |
| `UI_ZeD_Veh_Temp` | `Temp` | Vehicle tab part card: label of the temperature row | 10 |
| `UI_ZeD_Veh_ThirstyCount` | `%1 of %2 \| no water inside` | Vehicle tab animal trailer summary, Thirsty row: how many animals are thirsty (%1 thirsty, %2 alive) | 36 |
| `UI_ZeD_Veh_TileFromBack` | `%1 tile from the back` | Vehicle tab animal trailer page, Load from here list: distance of an animal from the back door (exactly one tile) | 28 |
| `UI_ZeD_Veh_Tiles` | `%1 tiles` | Vehicle tab summary before an inspection: distance to the vehicle (none or several tiles) | 12 |
| `UI_ZeD_Veh_TilesFromBack` | `%1 tiles from the back` | Vehicle tab animal trailer page, Load from here list: distance of an animal from the back door (several tiles) | 28 |
| `UI_ZeD_Veh_TilesOne` | `%1 tile` | Vehicle tab summary before an inspection: distance to the vehicle (exactly one tile) | 12 |
| `UI_ZeD_Veh_TowedBy` | `Towed by` | Vehicle tab summary: label of the row that names the vehicle towing this trailer | 12 |
| `UI_ZeD_Veh_Towing` | `Towing` | Vehicle tab summary: label of the row that names the trailer this vehicle tows | 12 |
| `UI_ZeD_Veh_VDeflate` | `Deflate` | Vehicle tab part card: action button on a tire | 14 |
| `UI_ZeD_Veh_VInflate` | `Inflate` | Vehicle tab part card: action button on a tire | 14 |
| `UI_ZeD_Veh_VSmash` | `Smash` | Vehicle tab part card: action button on a window | 14 |
| `UI_ZeD_Veh_VTakeParts` | `Take parts` | Vehicle tab part card: action button on the engine, takes spare parts out of it | 16 |
| `UI_ZeD_Veh_WaterMeta` | `%1  \|  %2 ml` | Vehicle tab animal trailer card, Give water list, second line (%1 = where the container is, %2 = millilitres of water) | 40 |
| `UI_ZeD_Veh_WhatItEats` | `What it eats from your bags` | Vehicle tab animal trailer animal card: right-hand tag on the Feed heading | 34 |
| `UI_ZeD_Veh_WorkingBack` | `Working at the back of the trailer` | Vehicle tab animal trailer animal card, footer status while an action runs | 40 |
| `UI_ZeD_Veh_WorkingOn` | `Working on the %1` | Vehicle tab part card, footer: status while an action runs (%1 = part name, lower case) | 36 |
| `UI_ZeD_Veh_WorstFirst` | `Worst first` | Vehicle tab part list: heading used when the list is sorted by condition | 16 |
| `UI_ZeD_Veh_HelpAnimalRow` | `Open this animal: its needs, with Remove, Grab and Info` | Vehicle tab, animal trailer page: help line over an animal's row | - |
| `UI_ZeD_Veh_HelpCloseHood` | `Close the hood` | Vehicle tab: help line over the footer button that closes the hood | - |
| `UI_ZeD_Veh_HelpCloseLid` | `Close the trunk lid` | Vehicle tab, animal trailer page: help line over the lid button while the trunk lid is open | - |
| `UI_ZeD_Veh_HelpCloseWindow` | `Close this window` | Vehicle tab part card: help line over the button that closes a window | - |
| `UI_ZeD_Veh_HelpConfirmNo` | `Do not do it` | Vehicle tab part card: help line over the No button of a footer question (smash, take parts) | - |
| `UI_ZeD_Veh_HelpDefault` | `Do this to the part` | Vehicle tab part card: help line over an action button that has no help line of its own | - |
| `UI_ZeD_Veh_HelpDeflate` | `Let the air out of the tire` | Vehicle tab part card: help line over the button that lets air out of a tire | - |
| `UI_ZeD_Veh_HelpFeed` | `Feed the animal this` | Vehicle tab, animal trailer page: help line over a food item you can give the animal | - |
| `UI_ZeD_Veh_HelpFix` | `Repair this part with the recipe picked below` | Vehicle tab part card: help line over the Repair button | - |
| `UI_ZeD_Veh_HelpFold` | `Fold or unfold this group` | Vehicle tab: help line over a group heading in the list of parts | - |
| `UI_ZeD_Veh_HelpGiveWater` | `Give the animal water from this` | Vehicle tab, animal trailer page: help line over a water source you can give the animal | - |
| `UI_ZeD_Veh_HelpGoTow` | `Show the other vehicle in this link` | Vehicle tab: help line over the button that shows the other vehicle of a towing link | - |
| `UI_ZeD_Veh_HelpGrabAnimal` | `Grab: pick the animal up and carry it` | Vehicle tab, animal trailer page: help line over the Grab button on an animal | - |
| `UI_ZeD_Veh_HelpInflate` | `Pump air into the tire` | Vehicle tab part card: help line over the button that pumps air into a tire | - |
| `UI_ZeD_Veh_HelpInfoAnimal` | `Info: open this animal's details in the Animals tab` | Vehicle tab, animal trailer page: help line over the Info button on an animal | - |
| `UI_ZeD_Veh_HelpInspect` | `Inspect: walk over and look the vehicle over to read its parts` | Vehicle tab: help line over the footer Inspect button | - |
| `UI_ZeD_Veh_HelpInstall` | `Install the part picked below` | Vehicle tab part card: help line over the Install button | - |
| `UI_ZeD_Veh_HelpOpenBox` | `Show what is inside in the Loot pane` | Vehicle tab, animal trailer page: help line over the button that shows a container's contents in the loot pane | - |
| `UI_ZeD_Veh_HelpOpenLid` | `Open the trunk lid; the other actions wait for it` | Vehicle tab, animal trailer page: help line over the lid button while the trunk lid is closed | - |
| `UI_ZeD_Veh_HelpOpenWindow` | `Open this window` | Vehicle tab part card: help line over the button that opens a window | - |
| `UI_ZeD_Veh_HelpPartRow` | `Open this part: its condition, repairs and what it needs` | Vehicle tab: help line over a part's row | - |
| `UI_ZeD_Veh_HelpPutIn` | `Put this animal in the trailer` | Vehicle tab, animal trailer page: help line over the button that puts an animal in the trailer | - |
| `UI_ZeD_Veh_HelpRemoveAnimal` | `Remove: walk the animal out at the back` | Vehicle tab, animal trailer page: help line over the Remove button on an animal | - |
| `UI_ZeD_Veh_HelpRepairEngine` | `Repair the engine with spare engine parts` | Vehicle tab part card (engine): help line over the Repair engine button | - |
| `UI_ZeD_Veh_HelpRepairLightbar` | `Repair the light bar` | Vehicle tab part card (light bar): help line over the Repair button | - |
| `UI_ZeD_Veh_HelpSmash` | `Smash the window; the glass is lost` | Vehicle tab part card (window): help line over the Smash button | - |
| `UI_ZeD_Veh_HelpSortArea` | `Sort the parts by area of the vehicle` | Vehicle tab: help line over the sort button of the part list while it sorts by area | - |
| `UI_ZeD_Veh_HelpSortCond` | `Sort the parts by condition, worst first` | Vehicle tab: help line over the sort button of the part list while it sorts by condition | - |
| `UI_ZeD_Veh_HelpTakeParts` | `Take parts out of the engine; it loses condition` | Vehicle tab part card (engine): help line over the Take parts button | - |
| `UI_ZeD_Veh_HelpUninstall` | `Take this part off the vehicle` | Vehicle tab part card: help line over the Uninstall button | - |
| `UI_ZeD_Veh_HintCloseWindow` | `close the window` | Vehicle tab part card: what Close window does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintDefault` | `work on this part` | Vehicle tab part card: what an action with no wording of its own does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintDeflate` | `let the air out of the tire` | Vehicle tab part card: what Deflate does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintFix` | `repair it` | Vehicle tab part card: what Repair does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintGoTow` | `Show the other vehicle` | Vehicle tab: hover hint of the button that shows the other vehicle of a towing link | - |
| `UI_ZeD_Veh_HintGrabAnimal` | `pick the animal up` | Vehicle tab, animal trailer page: what Grab does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintInflate` | `pump up the tire` | Vehicle tab part card: what Inflate does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintInstall` | `install a part here` | Vehicle tab part card: what Install does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintOpenWindow` | `open the window` | Vehicle tab part card: what Open window does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintRemoveAnimal` | `take the animal out at the back` | Vehicle tab, animal trailer page: what Remove does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintRepairEngine` | `repair the engine` | Vehicle tab part card (engine): what Repair engine does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintRepairLightbar` | `repair the light bar` | Vehicle tab part card (light bar): what Repair does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintSmash` | `smash the window` | Vehicle tab part card (window): what Smash does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintTakeParts` | `take parts out of the engine` | Vehicle tab part card (engine): what Take parts does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_HintUninstall` | `take the part off` | Vehicle tab part card: what Uninstall does, in lower case, filling %2 of "With %1 you could %2" in the folded hidden-actions row | - |
| `UI_ZeD_Veh_InspectParts` | `Inspect the %1 to read its parts.` | Vehicle tab (not inspected yet): empty-state line over the list of parts; %1 = the vehicle's name | - |
| `UI_ZeD_Veh_NeedFixWhat` | `materials for one of the repair recipes` | Vehicle tab part card, NEEDS list for Repair: the requirement line while no recipe has its materials | - |
| `UI_ZeD_Veh_NeedLid` | `the trunk lid open` | Vehicle tab, animal trailer page: what Open needs, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |
| `UI_ZeD_Veh_NeedPartWhat` | `a part to install within reach` | Vehicle tab part card, NEEDS list for Install: the requirement line while no part is within reach | - |
| `UI_ZeD_Veh_NoAnimalsHere` | `No animals inside.` | Vehicle tab, animal trailer page: line shown when the trailer holds no animals | - |
| `UI_ZeD_Veh_NoVehicleReach` | `No vehicle within reach.` | Vehicle tab: line shown when no vehicle is within reach | - |
| `UI_ZeD_Veh_NotNow` | `%1 is not possible right now.` | Vehicle tab part card: the NEEDS line under an action that cannot be done at the moment although nothing is missing; %1 = the action's name | - |
| `UI_ZeD_Veh_PartsLabel` | `Parts` | Vehicle tab: heading of the list of parts | 14 |
| `UI_ZeD_Veh_RightConditions` | `the right conditions` | Vehicle tab part card: what an action needs when nothing specific is missing, in lower case, filling %2 of "%1 needs %2" and %1 of "With %1 you could %2" | - |

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
| `UI_ZeD_Wheel_DashboardDetail` | `The D-pad on its controls. Back lets go.` | D-pad wheels: second line of the Dashboard slice in World > Vehicle (driver's seat): the controller moves to the dashboard's controls until B | 40 |
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
| `UI_ZeD_Wheel_ResetWindowsDetail` | `Both windows back to where they start` | D-pad wheels: Second line of Reset windows | 32 |
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

## Window

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Window_ResizeHelp` | `Drag to change the window's size.` | Any resizable ZeD window: help line while the pointer is on the resize box in the window's bottom corner | - |

## WinMenu

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_WinMenu_Theme` | `Theme` | Window menu (the box at the right end of a window's title bar): name of the submenu that picks the theme | - |
| `UI_ZeD_WinMenu_Accent` | `Accent` | Window menu (the box at the right end of a window's title bar): name of the submenu that picks the accent color | - |
| `UI_ZeD_WinMenu_ResetThis` | `Reset this window` | Window menu: puts this window back to its starting size and place | - |
| `UI_ZeD_WinMenu_ResetBoth` | `Reset both windows` | Window menu, on the Character and World windows only: puts both windows back to their starting size and place | - |
| `UI_ZeD_WinMenu_Setup` | `ZeD setup...` | Window menu, last row: opens ZeD setup (Options > Mods > ZeD-GUI) | - |
| `UI_ZeD_WinMenu_Help` | `Window menu: theme, accent, text size, see-through, controller highlight and reset.` | Any ZeD window: help line while the pointer is on the window menu box (the box at the right end of the title bar) | - |
| `UI_ZeD_WinMenu_CloseHelp` | `Close the window.` | Any ZeD window: help line while the pointer is on the close box at the left end of the title bar | - |

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
| `UI_ZeD_Workshop_DescriptionTooLong` | `The description is too long: %1 characters at most` | Workshop upload screen: in the strip, why Upload is off. %1 is the room left: Steam's 8,000 less the lines the game adds (Workshop ID, Mod IDs) | - |
| `UI_ZeD_Workshop_ItemNew` | `New: Steam gives it a number on the first upload.` | Workshop upload screen: value of the Workshop item row for a new item | - |
| `UI_ZeD_Workshop_LabelChangeNote` | `Change note` | Workshop upload screen: caps label at the left of the change note field | 15 |
| `UI_ZeD_Workshop_LabelItem` | `Workshop item` | Workshop upload screen: caps label at the left of the item number | 15 |
| `UI_ZeD_Workshop_LabelPreview` | `Preview picture` | Workshop upload screen: caps label at the left of the preview picture | 15 |
| `UI_ZeD_Workshop_LabelWhatGoesUp` | `What goes up` | Workshop upload screen: caps label at the left of the check of the folder's contents | 15 |
| `UI_ZeD_Workshop_LabelWho` | `Who can see it` | Workshop upload screen: caps label at the left of the visibility buttons | 15 |
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
| `UI_ZeD_Workshop_YourMods` | `Your mods` | Workshop upload screen: caps heading over the list of folders in Zomboid/Workshop | - |
| `UI_ZeD_Workshop_StatusOne` | `1 mod folder` | Workshop window (main menu): footer line when nothing is under the pointer and the list holds one mod folder | - |
| `UI_ZeD_Workshop_StatusMany` | `%1 mod folders` | Workshop window (main menu): footer line when nothing is under the pointer and the list holds several mod folders; %1 = how many | - |

## World

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_World_ComingSoon` | `Coming soon` | World window: placeholder for a tab that has no content yet | - |
| `UI_ZeD_World_ContainersMany` | `%1 containers` | World window: title when several container columns are shown | - |
| `UI_ZeD_World_ContainersOne` | `%1 container` | World window: title when one container column is shown | - |
| `UI_ZeD_World_SearchStructures` | `Search structures...` | Build tab: search box placeholder | - |
| `UI_ZeD_World_SortDist` | `Dist` | World window container strip: sort button, natural (distance) order | 5 |
| `UI_ZeD_World_SortType` | `Type` | World window container strip: sort button, by type | 5 |
| `UI_ZeD_World_SortWt` | `Wt` | World window container strip: sort button, heaviest first | 5 |
| `UI_ZeD_World_TabAnimals` | `Animals` | World window: tab name | 12 |
| `UI_ZeD_World_TabBuilding` | `Building` | World window: tab name | 12 |
| `UI_ZeD_World_TabLoot` | `Loot` | World window: tab name (hover title and drawer title) | 12 |
| `UI_ZeD_World_TabMaps` | `Maps` | World window: tab name | 12 |
| `UI_ZeD_World_TabVehicle` | `Vehicle` | World window: tab name (shown only near a vehicle) | 12 |
| `UI_ZeD_World_Title` | `World` | World window: title bar text, and the window-rolled tab's fallback name | 16 |
| `UI_ZeD_World_TabHelp` | `%1: press to open this tab` | World window: help line over a tab name; %1 = the tab's name | - |
| `UI_ZeD_World_FloorHelp` | `The floor around you: press to show it or put it away` | World window: help line over the floor in the container strip | - |
| `UI_ZeD_World_ContainerHelp` | `%1: press to show it or put it away` | World window: help line over a container in the container strip; %1 = its name | - |
| `UI_ZeD_World_LockedHelp` | `%1 is locked: press for its lock` | World window: help line over a locked container in the container strip; %1 = its name | - |
| `UI_ZeD_World_SortHelp` | `Order of the containers: press for the next (distance, weight, type)` | World window: help line over the button that changes the order of the containers in the strip | - |
| `UI_ZeD_World_WeightOf` | `%1 of %2 kg` | World window: the weight part of the footer line for the open container, after the item count; %1 = weight inside (kg, one decimal), %2 = most it holds (kg) | - |

## XR

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_XR_Stage` | `Levels %1 to %2` | Skills tab with Exp Recovery for Skill Books: a skill's hover card, one line per skill book stage that holds saved XP, in front of the XP. %1 and %2 the first and last level that book trains (1 to 2, 3 to 4, ...) | - |
| `UI_ZeD_XR_SavedXP` | `Saved XP` | Skills tab with Exp Recovery for Skill Books: a skill's hover card, the bold total line, in front of the saved XP of all the skill's book stages | - |
| `UI_ZeD_XR_Note` | `Reading the skill book for those levels pays the saved XP out.` | Skills tab with Exp Recovery for Skill Books: a skill's hover card, last line | - |

## General

| Key | English | Where it shows | Max |
|---|---|---|---|
| `UI_ZeD_Close` | `Close` | Close button text. | 12 |
| `UI_ZeD_ModDesc` | `Total UI overhaul for Project Zomboid` | The mod list: the mod's one-line description. | 60 |
| `UI_ZeD_ModName` | `ZeD-GUI` | The mod list: the mod's name. | 12 |
| `UI_ZeD_NoResults` | `No results` | Empty list line when a search finds nothing. | 24 |
| `UI_ZeD_Weight` | `Weight` | Weight label. | 12 |

