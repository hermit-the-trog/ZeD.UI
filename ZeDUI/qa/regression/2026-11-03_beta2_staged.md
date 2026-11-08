# ZeD-UI regression - 2026-11-03 14:34 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 14:34:43 |
| Finished | 2026-11-03 14:39:55 (5 min 12 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\release_check_beta2.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 19666 to 19671 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19670, 19671)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_release_check.lua | rel | PASS | 17 | zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png |  |
| 3 | zedqa_cook80.lua | c80 | PASS | 58 | zqa_c80_3840x2160_1_open.png, zqa_c80_3840x2160_2_stew_plan.png, zqa_c80_3840x2160_2_stew_made.png, zqa_c80_3840x2160_3_count.png, zqa_c80_3840x2160_4_stirfry_full.png, zqa_c80_3840x2160_4_by_kind.png, zqa_c80_3840x2160_5_dish_list.png, zqa_c80_3840x2160_5_use_instead.png, zqa_c80_3840x2160_5_not_in_reach.png, zqa_c80_3840x2160_6_by_kind_pad.png |  |
| 4 | zedqa_mech79.lua | m79 | PASS | 137 | zqa_m79_3840x2160_1_by_section.png, zqa_m79_3840x2160_2_hover_row.png, zqa_m79_3840x2160_3_sort_gated.png, zqa_m79_3840x2160_4_by_condition.png, zqa_m79_3840x2160_5_card_tire.png, zqa_m79_3840x2160_6_card_brake_step.png, zqa_m79_3840x2160_7_after_uninstall.png, zqa_m79_3840x2160_t_PickUpTruck_lit.png, zqa_m79_3840x2160_t_PickUpTruck_card.png, zqa_m79_3840x2160_t_Van_lit.png, zqa_m79_3840x2160_t_Van_card.png, zqa_m79_3840x2160_t_SportsCar_lit.png, zqa_m79_3840x2160_t_SportsCar_card.png, zqa_m79_3840x2160_t_Trailer_lit.png, zqa_m79_3840x2160_t_Trailer_card.png, zqa_m79_3840x2160_8_trailer.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 19666 at 14:35:46

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_release_check.lua (`ZEDQA rel`) - PASS, 17 s

- go 19667 at 14:35:51
- screenshots: zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel start
[ZeD.QA] run #2 ok=true
ZEDQA rel PASS the windows start shut
ZEDQA rel PASS 1: both windows open
ZEDQA rel the test item: Base.Spiffo
ZEDQA rel PASS 2: the test item is in the Character window's list
ZEDQA rel PASS 2: the test item went to the floor (the game's transfer)
ZEDQA rel PASS 2: the World window lists it
ZEDQA rel PASS 2: it came back to the inventory
ZEDQA rel PASS 2: the Character window lists it again
ZEDQA rel PASS 4: the controller's focus is on the test item's row
ZEDQA rel 4: after A: charItemCard:hverb_1
ZEDQA rel PASS 4: A on the row opens its card, focus on its primary action (charItemCard:hverb_1)
ZEDQA rel 4: after B: invrow:16
ZEDQA rel PASS 4: B goes back to the row
ZEDQA rel PASS 3: the test item's row has a place on screen
ZEDQA rel PASS 3: the row is in the list's view (y 533 of 650)
ZEDQA rel 3: row invrow:16 at 0,533 350x53 in the window; the window at 1197,46
ZEDQA rel asked the helper for a right-click at 1257,605
ZEDQA rel PASS 3: the helper made the real right-click
ZEDQA rel 3: menu open true (ZeD_ContextMenu)
ZEDQA rel PASS 3: a real right-click on the row opens the item menu for that item (1 items)
ZEDQA rel PASS 5: the worn watch shows (belt true, corner true)
ZEDQA rel PASS 5: its face reads the game's time (15:54, the game 15:54)
ZEDQA rel RESULT PASS: all 16 checks
ZEDQA rel DONE
```

### 3. zedqa_cook80.lua (`ZEDQA c80`) - PASS, 58 s

- go 19668 at 14:36:12
- screenshots: zqa_c80_3840x2160_1_open.png, zqa_c80_3840x2160_2_stew_plan.png, zqa_c80_3840x2160_2_stew_made.png, zqa_c80_3840x2160_3_count.png, zqa_c80_3840x2160_4_stirfry_full.png, zqa_c80_3840x2160_4_by_kind.png, zqa_c80_3840x2160_5_dish_list.png, zqa_c80_3840x2160_5_use_instead.png, zqa_c80_3840x2160_5_not_in_reach.png, zqa_c80_3840x2160_6_by_kind_pad.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA c80 start
[ZeD.QA] run #3 ok=true
ZEDQA c80 before: tab shown false (the character's own bags)
ZEDQA c80 own bags: carrots 0, potatoes 0, cabbage 0, stews 0, pots 0
ZEDQA c80 pot water: 1.5
ZEDQA c80 PASS a pot of water, a carrot and a potato on the character: the Cooking tab is in the strip
ZEDQA c80 PASS the Cooking tab opens
ZEDQA c80 dish Soup; dishes: Soup, Stew
ZEDQA c80 shot 1_open
ZEDQA c80 PASS the pot taken away: the tab goes (carrot and potato still there)
ZEDQA c80 PASS the window leaves the tab when it goes (now loot)
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 PASS three vegetables in the dish (Base.Carrots, Base.Potato, Base.Cabbage)
ZEDQA c80 PASS all three count as ingredients, none as seasoning (0 as seasoning; the hunger total adds them)
ZEDQA c80 PASS Make is lit
ZEDQA c80 PASS no count for one pot
ZEDQA c80 shot 2_stew_plan
ZEDQA c80 PASS one pot of stew made (1)
ZEDQA c80 PASS it holds all three (3): Vegetable Stew
ZEDQA c80 PASS the carrot and the potato went in (cabbage left: 1, part used)
ZEDQA c80 PASS no empty pot left behind
ZEDQA c80 shot 2_stew_made
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 two pots: dish Stew, bases [Base.Pot ok mine, Base.Pot ok mine], in reach [Base.Potato x2, Base.Carrots x2], plan Base.Carrots, Base.Potato
ZEDQA c80 PASS two pots and enough for two: the count shows
ZEDQA c80 PASS the count goes to 2 (2)
ZEDQA c80 PASS and stops at 2 (2)
ZEDQA c80 shot 3_count
ZEDQA c80 PASS two pots of stew made (2)
ZEDQA c80 PASS each holds a carrot and a potato (2, 2)
ZEDQA c80 Base.Broccoli frozen true; Base.Carrots frozen true
ZEDQA c80 dishes now: Stir fry
ZEDQA c80 PASS the Dish list picks Stir-fry (now Stir fry)
ZEDQA c80 stir-fry: recipe Stir fry, max 4, base Base.Pan; the game offers [Base.Onion, Base.Cabbage, Base.Carrots, Base.BellPepper, Base.Tomato, Base.Potato]; frozen now [Base.Broccoli, Base.Carrots]
ZEDQA c80 stir-fry four in: dish Stir fry, bases [Base.Pan ok mine], in reach [Base.Onion x1, Base.Cabbage x1, Base.Carrots x1, Base.BellPepper x1, Base.Tomato x1, Base.Potato x1], plan Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion
ZEDQA c80 PASS four in the stir-fry (Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion)
ZEDQA c80 PASS the four are ingredients (Ingredients 4 / 4), none seasoning
ZEDQA c80 PASS a fifth greys (bell pepper)
ZEDQA c80 PASS a press on it adds nothing
ZEDQA c80 PASS no seasoning offered to a new stir-fry (as the game)
ZEDQA c80 PASS still four (Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion)
ZEDQA c80 PASS frozen broccoli is not offered (as the game)
ZEDQA c80 carrots: 1 usable, why nil
ZEDQA c80 stir-fry full: dish Stir fry, bases [Base.Pan ok mine], in reach [Base.Onion x1, Base.Cabbage x1, Base.Carrots x1, Base.BellPepper x1, Base.Tomato x1, Base.Potato x1], plan Base.Potato, Base.Cabbage, Base.Tomato, Base.Onion
ZEDQA c80 PASS a frozen carrot beside a good one: the good one still goes in
ZEDQA c80 shot 4_stirfry_full
ZEDQA c80 shot 4_by_kind
ZEDQA c80 PASS the Dish list picks Stew (now Stew)
ZEDQA c80 PASS Save is in the band
ZEDQA c80 PASS the dish is saved (1)
ZEDQA c80 PASS Save turns to Forget
ZEDQA c80 PASS the saved dish heads the Dish list
ZEDQA c80 shot 5_dish_list
ZEDQA c80 PASS the saved dish loads (Base.Carrots, Base.Potato)
ZEDQA c80 PASS the potato not in reach: Use <same kind> is offered
ZEDQA c80 PASS Make waits while an ingredient is missing
ZEDQA c80 shot 5_use_instead
ZEDQA c80 PASS Use takes the cabbage (Base.Carrots, Base.Cabbage)
ZEDQA c80 PASS nothing of the same kind: no Use offered
ZEDQA c80 shot 5_not_in_reach
ZEDQA c80 PASS Forget takes it off the list (0)
ZEDQA c80 PASS A on an ingredient: a stop for it
ZEDQA c80 PASS A adds it (Base.Carrots)
ZEDQA c80 PASS A on the dish's row takes it out
ZEDQA c80 PASS A on Sort opens its list
ZEDQA c80 PASS with the list open, only its choices and the boxes are stops
ZEDQA c80 PASS A picks By category and shuts the list
ZEDQA c80 PASS B shuts an open list
ZEDQA c80 PASS the list is shut
ZEDQA c80 shot 6_by_kind_pad
ZEDQA c80 put back: 26 items taken away, the saved dishes as they were
ZEDQA c80 RESULT 47 pass, 0 fail
ZEDQA c80 DONE
```

### 4. zedqa_mech79.lua (`ZEDQA m79`) - PASS, 137 s

- go 19669 at 14:37:13
- screenshots: zqa_m79_3840x2160_1_by_section.png, zqa_m79_3840x2160_2_hover_row.png, zqa_m79_3840x2160_3_sort_gated.png, zqa_m79_3840x2160_4_by_condition.png, zqa_m79_3840x2160_5_card_tire.png, zqa_m79_3840x2160_6_card_brake_step.png, zqa_m79_3840x2160_7_after_uninstall.png, zqa_m79_3840x2160_t_PickUpTruck_lit.png, zqa_m79_3840x2160_t_PickUpTruck_card.png, zqa_m79_3840x2160_t_Van_lit.png, zqa_m79_3840x2160_t_Van_card.png, zqa_m79_3840x2160_t_SportsCar_lit.png, zqa_m79_3840x2160_t_SportsCar_card.png, zqa_m79_3840x2160_t_Trailer_lit.png, zqa_m79_3840x2160_t_Trailer_card.png, zqa_m79_3840x2160_8_trailer.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA m79 start
[ZeD.QA] run #4 ok=true
ZEDQA m79 before: Basic Mechanics known false, magazine read false
ZEDQA m79 car at 928,13040; Mechanics 4 -> 3
ZEDQA m79 WARN step 2: waited 3600 frames, went on
ZEDQA m79 Basic Mechanics known by reading the magazine: false
ZEDQA m79 front left tire off: true
ZEDQA m79 PASS the game's Vehicle Mechanics inspects the car and the World window shows the Vehicle tab
ZEDQA m79 rows (By section, 40): Muffler, EngineDoor, Battery, Engine, Heater, Windshield, Radio, HeadlightLeft, HeadlightRight, GasTank, TireFrontLeft, BrakeFrontLeft, SuspensionFrontLeft, TireFrontRight, BrakeFrontRight, SuspensionFrontRight, TireRearLeft, BrakeRearLeft, SuspensionRearLeft, TireRearRight, BrakeRearRight, SuspensionRearRight, HeadlightRearLeft, HeadlightRearRight, DoorFrontLeft, WindowFrontLeft, DoorFrontRight, WindowFrontRight, DoorRearLeft, WindowRearLeft, DoorRearRight, WindowRearRight, TrunkDoor, TruckBed, WindshieldRear, SeatFrontLeft, SeatFrontRight, SeatRearLeft, SeatRearRight, GloveBox
ZEDQA m79 PASS the list opens By section
ZEDQA m79 PASS a brake sits under its tire (BrakeRearLeft after TireRearLeft, no tire between)
ZEDQA m79 PASS a suspension sits under its tire
ZEDQA m79 PASS a window sits under its door
ZEDQA m79 PASS the missing front left tire keeps its row
ZEDQA m79 PASS no back arrow
ZEDQA m79 PASS every row sits inside the list column
ZEDQA m79 shot 1_by_section
ZEDQA m79 PASS hover on a row lights its part on the diagram (Muffler, lit Muffler)
ZEDQA m79 PASS hover never opens the card
ZEDQA m79 shot 2_hover_row
ZEDQA m79 PASS the Sort box opens its list
ZEDQA m79 PASS By condition is greyed at Mechanics 3
ZEDQA m79 shot 3_sort_gated
ZEDQA m79 PASS pressing the greyed By condition changes nothing (area)
ZEDQA m79 PASS By condition is usable at Mechanics 4
ZEDQA m79 PASS By condition sorts the list (cond)
ZEDQA m79 rows (By condition): TireFrontLeft, SeatRearRight, Radio, BrakeRearRight, GasTank, DoorRearRight, Engine, HeadlightRight, TrunkDoor, TruckBed, SeatFrontLeft, SeatFrontRight, SeatRearLeft, GloveBox, Battery, Muffler, EngineDoor, Heater, Windshield, WindshieldRear, WindowFrontLeft, WindowFrontRight, WindowRearLeft, WindowRearRight, DoorFrontLeft, DoorFrontRight, DoorRearLeft, TireFrontRight, TireRearLeft, TireRearRight, BrakeFrontLeft, BrakeFrontRight, BrakeRearLeft, SuspensionFrontLeft, SuspensionFrontRight, SuspensionRearLeft, SuspensionRearRight, HeadlightLeft, HeadlightRearLeft, HeadlightRearRight
ZEDQA m79 shot 4_by_condition
ZEDQA m79 (mech:row:TireRearRight is out of view: pressed directly)
ZEDQA m79 PASS a click on a row opens its card (TireRearRight)
ZEDQA m79 PASS the card has no back arrow
ZEDQA m79 tire card footer verbs: deflate, uninstall
ZEDQA m79 PASS the tire's main verb, Uninstall, is in the footer and lit
ZEDQA m79 PASS the Sort box stays in the footer with the card open
ZEDQA m79 shot 5_card_tire
ZEDQA m79 PASS the mouse wheel over the card does not close it
ZEDQA m79 (mech:row:TireRearRight is out of view: pressed directly)
ZEDQA m79 PASS the same row again closes the card
ZEDQA m79 (mech:row:TireRearRight is out of view: pressed directly)
ZEDQA m79 (mech:row:DoorFrontLeft is out of view: pressed directly)
ZEDQA m79 PASS another row swaps the card (DoorFrontLeft)
ZEDQA m79 (mech:row:DoorFrontLeft is out of view: pressed directly)
ZEDQA m79 PASS a click on the diagram picks a part (Engine)
ZEDQA m79 (mech:row:BrakeRearLeft is out of view: pressed directly)
ZEDQA m79 brake card: verbs | Basic Mechanics known false | uninstall table: recipes Basic Mechanics, skills Mechanics:3, requireUninstalled TireRearLeft
ZEDQA m79 PASS a brake's card shows the step before (take the tire off first) with its button
ZEDQA m79 shot 6_card_brake_step
ZEDQA m79 PASS the step before's button opens that part's card (TireRearLeft)
ZEDQA m79 (mech:row:TireRearRight is out of view: pressed directly)
ZEDQA m79 PASS Uninstall from the footer takes the rear right tire off for real
ZEDQA m79 PASS the card stays on the part after the uninstall
ZEDQA m79 shot 7_after_uninstall
ZEDQA m79 PASS Install is lit on the missing tire's card
ZEDQA m79 PASS Install from the footer puts it back for real
ZEDQA m79 PASS the card stays on the part after the install
ZEDQA m79 (mech:row:TireRearRight is out of view: pressed directly)
ZEDQA m79 A on mech:row:EngineDoor
ZEDQA m79 PASS A on a row opens its card (EngineDoor)
ZEDQA m79 PASS B closes the card
ZEDQA m79 PASS Base.PickUpTruck: inspected, its tab on it
ZEDQA m79 PASS Base.PickUpTruck: hover on a row lights its part (Muffler, lit Muffler)
ZEDQA m79 Base.PickUpTruck: rows Muffler, EngineDoor, Battery, Engine, Heater, Windshield, Radio, HeadlightLeft, HeadlightRight, GasTank, TireFrontLeft, BrakeFrontLeft, SuspensionFrontLeft, TireFrontRight, BrakeFrontRight, SuspensionFrontRight, TireRearLeft, BrakeRearLeft, SuspensionRearLeft, TireRearRight, BrakeRearRight, SuspensionRearRight, HeadlightRearLeft, HeadlightRearRight, DoorFrontLeft, WindowFrontLeft, DoorFrontRight, WindowFrontRight, TruckBedOpen, WindshieldRear, SeatFrontLeft, SeatFrontRight, GloveBox
ZEDQA m79 shot t_PickUpTruck_lit
ZEDQA m79 PASS Base.PickUpTruck: a click on the diagram picks a part (EngineDoor)
ZEDQA m79 shot t_PickUpTruck_card
ZEDQA m79 PASS Base.Van: inspected, its tab on it
ZEDQA m79 PASS Base.Van: hover on a row lights its part (Muffler, lit Muffler)
ZEDQA m79 Base.Van: rows Muffler, EngineDoor, Battery, Engine, Heater, Windshield, Radio, HeadlightLeft, HeadlightRight, GasTank, TireFrontLeft, BrakeFrontLeft, SuspensionFrontLeft, TireFrontRight, BrakeFrontRight, SuspensionFrontRight, TireRearLeft, BrakeRearLeft, SuspensionRearLeft, TireRearRight, BrakeRearRight, SuspensionRearRight, HeadlightRearLeft, HeadlightRearRight, DoorFrontLeft, WindowFrontLeft, DoorFrontRight, WindowFrontRight, DoorRear, WindshieldRear, TruckBed, SeatFrontLeft, SeatFrontRight, GloveBox
ZEDQA m79 shot t_Van_lit
ZEDQA m79 PASS Base.Van: a click on the diagram picks a part (EngineDoor)
ZEDQA m79 shot t_Van_card
ZEDQA m79 PASS Base.SportsCar: inspected, its tab on it
ZEDQA m79 PASS Base.SportsCar: hover on a row lights its part (Muffler, lit Muffler)
ZEDQA m79 Base.SportsCar: rows Muffler, EngineDoor, Battery, Engine, Heater, Windshield, Radio, HeadlightLeft, HeadlightRight, GasTank, TireFrontLeft, BrakeFrontLeft, SuspensionFrontLeft, TireFrontRight, BrakeFrontRight, SuspensionFrontRight, TireRearLeft, BrakeRearLeft, SuspensionRearLeft, TireRearRight, BrakeRearRight, SuspensionRearRight, HeadlightRearLeft, HeadlightRearRight, DoorFrontLeft, WindowFrontLeft, DoorFrontRight, WindowFrontRight, TrunkDoor, TruckBed, WindshieldRear, SeatFrontLeft, SeatFrontRight, GloveBox
ZEDQA m79 shot t_SportsCar_lit
ZEDQA m79 PASS Base.SportsCar: a click on the diagram picks a part (EngineDoor)
ZEDQA m79 shot t_SportsCar_card
ZEDQA m79 PASS Base.Trailer: inspected, its tab on it
ZEDQA m79 PASS Base.Trailer: hover on a row lights its part (TireFrontLeft, lit TireFrontLeft)
ZEDQA m79 Base.Trailer: rows TireFrontLeft, SuspensionFrontLeft, TireFrontRight, SuspensionFrontRight, TrailerTrunk
ZEDQA m79 shot t_Trailer_lit
ZEDQA m79 PASS Base.Trailer: a click on the diagram picks a part (TireFrontLeft)
ZEDQA m79 shot t_Trailer_card
ZEDQA m79 trailer true
ZEDQA m79 animals in the trailer: 4
ZEDQA m79 trailer rows: TireFrontLeft, BrakeFrontLeft, SuspensionFrontLeft, TireFrontRight, BrakeFrontRight, SuspensionFrontRight, TireRearLeft, BrakeRearLeft, SuspensionRearLeft, TireRearRight, BrakeRearRight, SuspensionRearRight, TrunkDoorOpened, TrailerAnimalFood, TrailerAnimalEggs
ZEDQA m79 PASS the trailer's rows, animals included, fit the list column
ZEDQA m79 shot 8_trailer
ZEDQA m79 after: Basic Mechanics known false, magazine read false
ZEDQA m79 put back: car, trailer, 4 animals, 10 items taken away; Mechanics 4
ZEDQA m79 summary: all 45 PASS
ZEDQA m79 DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
