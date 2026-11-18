# ZeD-UI regression - 2026-11-17 18:05 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 18:05:00 |
| Finished | 2026-11-17 18:09:01 (4 min 1 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\gallery_v1_b_zed.txt (13 scripts) |
| Result | **12/13 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 28581 to 28595 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28594, 28595)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 2 |  |  |
| 3 | gallery_b11_look.lua | g14l | PASS | 1 |  |  |
| 4 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 5 | gallery_b10_glasses.lua | gls | PASS | 2 |  |  |
| 6 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 7 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 8 | gallery_v1_b_lib.lua | g1lib | PASS | 1 |  | late output from unl (5 line(s), not counted) |
| 9 | gallery_v1_b_craft.lua | g1bc | PASS | 13 |  | late output from unl (17 line(s), not counted) |
| 10 | gallery_v1_b_fish.lua | g1bf | WARN | 59 |  | 1 ERR line(s); late output from unl (65 line(s), not counted) |
| 11 | gallery_v1_b_pad.lua | g1bp | PASS | 26 |  | late output from unl (30 line(s), not counted) |
| 12 | gallery_reload.lua | rel | PASS | 1 |  |  |
| 13 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28581 at 18:06:07

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 2 s

- go 28582 at 18:06:12

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_b11_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 28583 at 18:06:18

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark teal small | GAL_LOOK dark teal, GAL_STILL 20
[ZeD.QA] run #3 ok=true
ZEDQA g14l DONE
```

### 4. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 28584 at 18:06:22

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA day time 11.73 -> 11.00
[ZeD.QA] run #4 ok=true
ZEDQA day DONE
```

### 5. gallery_b10_glasses.lua (`ZEDQA gls`) - PASS, 2 s

- go 28585 at 18:06:27

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gls wearing Base.Glasses_Prescription
[ZeD.QA] run #5 ok=true
ZEDQA gls DONE
```

### 6. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 28586 at 18:06:32

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #6 ok=true
ZEDQA hcn DONE
```

### 7. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28587 at 18:06:37

```text
[ZeD.QA] state #7 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 32.7 of 8 kg, 62 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 36 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #7 ok=true
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (x3)
```

### 8. gallery_v1_b_lib.lua (`ZEDQA g1lib`) - PASS, 1 s

- go 28588 at 18:06:41
- late output from unl (5 line(s), not counted)

```text
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)
[ZeD.QA] state #8 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1lib GV1 defined (gallery_v1_b helpers)
[ZeD.QA] run #8 ok=true
ZEDQA g1lib DONE
ZEDQA unl load 12.3 of 8 kg, 26 items, Heavy Load 1   (late output from unl)   (x4)
```

### 9. gallery_v1_b_craft.lua (`ZEDQA g1bc`) - PASS, 13 s

- go 28589 at 18:06:45
- late output from unl (17 line(s), not counted)

```text
[ZeD.QA] state #9 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1bc start
[ZeD.QA] run #9 ok=true
ZEDQA g1bc hidden: ZeD_MessagesToasts, ZeD_MessagesToasts, ZeD_MessagesToasts, ZeD_MessagesToasts
ZEDQA g1bc fluid holders taken out for the run: 1
ZEDQA g1bc given: rag true, brandy true
ZEDQA unl load 13.7 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1bc recipe open: MakeMolotovCocktail (Make Molotov Cocktail), written to Lua/gallery_v1_b_recipe.txt
ZEDQA unl load 13.7 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA g1bc list status missing, the game's check false
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA unl load 13.7 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA g1bc shot g1_46_craft_zed | load 13.7 of 18 kg, 27 items, Heavy Load 0
ZEDQA g1bc boxes ZeD_Watch@3576,10 248x352; ZeD_Window@1134,0 777x735; ZeD_Window@1929,0 1617x735
ZEDQA g1bc character at 1920,1136 clear
ZEDQA unl load 13.7 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1bc building recipe open: Advanced_Forge (Advanced Forge), status missing
ZEDQA unl load 13.7 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA g1bc shot g1_04_build_zed | load 13.7 of 18 kg, 27 items, Heavy Load 0
ZEDQA g1bc boxes ZeD_Watch@3576,10 248x352; ZeD_Window@1134,0 777x735; ZeD_Window@1929,0 1617x735
ZEDQA g1bc character at 1920,1136 clear
ZEDQA unl load 13.7 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA g1bc fluid holders put back: 1
ZEDQA g1bc taken 2: g1_46_craft_zed g1_04_build_zed
ZEDQA g1bc not taken 0:
ZEDQA g1bc put back: cards shut, Show as it was, given things out, fluid holders back, the place
ZEDQA g1bc DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
```

### 10. gallery_v1_b_fish.lua (`ZEDQA g1bf`) - WARN, 59 s

- go 28590 at 18:07:02
- 1 ERR line(s)
- late output from unl (65 line(s), not counted)

```text
[ZeD.QA] state #10 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1bf start
[ZeD.QA] run #10 ok=true
ZEDQA g1bf trying West Point, north at 11700,6620
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA g1bf found at 11672,6602 (West Point, north) facing N
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x16)
ZEDQA g1bf at the shore 11672,6602 (West Point, north) facing N, the target 11672.5,6597.5, fish in front 19
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.3 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.6 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf rod in hand true, manager None
ZEDQA unl load 12.6 of 18 kg, 29 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.3 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 12.6 of 18 kg, 29 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf bait Base.Worm
ZEDQA g1bf aim 1: pointer 2242,877 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 2: pointer 2563,674 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA g1bf aim 3: pointer 2884,471 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 4: pointer 3205,268 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA g1bf aim 5: pointer 3526,65 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 6: pointer 3847,-138 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA g1bf aim 7: pointer 4168,-341 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA g1bf aim 8: pointer 4489,-544 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf aim 9: pointer 4810,-747 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA g1bf aim 10: pointer 5131,-950 -> 11673.2,6603.2, 5.7 off, on water false, state None, under the pointer nil
ZEDQA g1bf ERR the manager is not Idle (None): the cast may not go
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x20)
ZEDQA g1bf after the cast: state None (120 polls)
ZEDQA g1bf not taken: g1_59_fishing (the line did not go out (state None))
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA unl load 12.6 of 18 kg, 28 items, Heavy Load 0   (late output from unl)
ZEDQA g1bf taken 0:
ZEDQA g1bf not taken 1: g1_59_fishing
ZEDQA g1bf put back: the line in, aiming off, the hands, rod and worms out (0 other new things out), the place
ZEDQA g1bf DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ERROR: General f:10076 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
```

### 11. gallery_v1_b_pad.lua (`ZEDQA g1bp`) - PASS, 26 s

- go 28591 at 18:08:04
- late output from unl (30 line(s), not counted)

```text
[ZeD.QA] state #11 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g1bp start
[ZeD.QA] run #11 ok=true
ZEDQA g1bp pad bound false, input lock was nil
ZEDQA g1bp trying West Point, by the Fossoil at 12060,7105
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x4)
ZEDQA g1bp found at 12074,7117 (West Point, by the Fossoil)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x11)
ZEDQA g1bp mid-street at 12074,7117 (West Point, by the Fossoil), floor blends_street_01_16
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA g1bp zombies within 15 squares: 9
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bp Here and now slices:
ZEDQA g1bp not taken: g1_63_now_wheel (the Here and now wheel did not open)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bp Character wheel slices: 1:Tabs Character window 2:Weapons 3:Eat Nothing to eat on you. 4:Drink 5:Medicine and first aid 6:Sleep Not tired enough to sleep. 7:Clothing 8:Use Smoke | Read | Watch | Radio 9:Loadouts Restock a saved loadout 10:Belt
ZEDQA g1bp Belt slice 10
ZEDQA g1bp shot g1_65_wheel_belt | load 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA g1bp boxes ZeD_Watch@3576,10 248x352; ISRadialMenu@1577,737 686x686
ZEDQA g1bp character at 1920,1136 COVERED by ISRadialMenu
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA unl pointer parked at 3837,1080 and hidden   (late output from unl)   (x2)
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA g1bp shot g1_65_help_pad | load 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA g1bp boxes ZeD_Watch@3576,10 248x352; ZeD_Window@1134,0 777x735; ZeD_Window@1929,0 777x735
ZEDQA g1bp character at 1920,1136 clear
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ERROR: General f:11979 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA g1bp taken 2: g1_65_wheel_belt g1_65_help_pad
ZEDQA g1bp not taken 1: g1_63_now_wheel
ZEDQA g1bp put back: wheels shut, focus let go, input lock nil, the pair open, the place
ZEDQA g1bp DONE
ZEDQA unl load 12.3 of 18 kg, 26 items, Heavy Load 0   (late output from unl)   (x3)
```

### 12. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28592 at 18:08:34

```text
[ZeD.QA] state #12 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 12.3 of 18 kg, 26 items, Heavy Load 0
ZEDQA rel put back 36 things; after: 32.7 of 18 kg, 62 items, Heavy Load 1 OVER
[ZeD.QA] run #12 ok=true
ZEDQA rel DONE
```

### 13. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 28593 at 18:08:38

```text
[ZeD.QA] state #13 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now light teal
[ZeD.QA] run #13 ok=true
ZEDQA g14e DONE
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
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
