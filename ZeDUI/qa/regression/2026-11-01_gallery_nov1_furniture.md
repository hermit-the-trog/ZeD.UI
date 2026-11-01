# ZeD-UI regression - 2026-11-01 15:17 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-01 15:17:42 |
| Finished | 2026-11-01 15:20:38 (2 min 55 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\AppData\Local\Temp\claude\C--Users-you--claude-spares-spare-8vLpAQ\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\furniture_again_manifest.txt (10 scripts) |
| Result | **10/10 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 18013 to 18024 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 18023, 18024)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_t14_look.lua | g14l | PASS | 1 |  |  |
| 3 | gallery_daylight.lua | day | PASS | 2 |  |  |
| 4 | gallery_v3_core.lua | g3c | PASS | 19 |  |  |
| 5 | gallery_v3_reveal.lua | g3r | PASS | 10 |  |  |
| 6 | gallery_v3_stage.lua | g3s | PASS | 8 |  |  |
| 7 | gallery_nov1_only_furniture.lua | n1of | PASS | 1 |  |  |
| 8 | gallery_nov1_lot.lua | n1l | PASS | 9 |  |  |
| 9 | gallery_v3_teardown.lua | g3t | PASS | 10 |  |  |
| 10 | gallery_t14_end.lua | g14e | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 18013 at 15:18:40

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_t14_look.lua (`ZEDQA g14l`) - PASS, 1 s

- go 18014 at 15:18:46

```text
[ZeD.QA] windows reset (R)
ZEDQA g14l desk menu bar: Debug left out true
ZEDQA g14l position readout and cheat lines off true
ZEDQA g14l left-edge column hidden true
ZEDQA g14l look dark orange small | GAL_LOOK dark orange, GAL_STILL 20
[ZeD.QA] run #2 ok=true
ZEDQA g14l DONE
```

### 3. gallery_daylight.lua (`ZEDQA day`) - PASS, 2 s

- go 18015 at 15:18:50

```text
[ZeD.QA] windows reset (R)
ZEDQA day time 11.30 -> 11.00
[ZeD.QA] run #3 ok=true
ZEDQA day DONE
```

### 4. gallery_v3_core.lua (`ZEDQA g3c`) - PASS, 19 s

- go 18016 at 15:18:55

```text
[ZeD.QA] windows reset (R)
ZEDQA g3c start (18 steps)
[ZeD.QA] run #4 ok=true
ZEDQA g3c start at 925,13040 zoom 1 | ZeD true
ZEDQA g3c forced spot 13935,5729
ZEDQA g3c standing at 13935,5729 floor blends_street_01_102 outside true | cars within 22: 2 | zombies in the cell 0
ZEDQA g3c floors round the spot: blends_street_01=81
ZEDQA g3c zoom 1.75
ZEDQA g3c shot g3_scout_wide ok
ZEDQA g3c zoom 1
ZEDQA g3c shot g3_scout_mid ok
ZEDQA g3c end: 2 shots ok, 0 errors
ZEDQA g3c DONE
```

### 5. gallery_v3_reveal.lua (`ZEDQA g3r`) - PASS, 10 s

- go 18017 at 15:19:18

```text
[ZeD.QA] windows reset (R)
ZEDQA g3r start (172 steps)
[ZeD.QA] run #5 ok=true
ZEDQA g3r toured: 16 stops
ZEDQA g3r end: 0 shots ok, 0 errors
ZEDQA g3r DONE
```

### 6. gallery_v3_stage.lua (`ZEDQA g3s`) - PASS, 8 s

- go 18018 at 15:19:31

```text
[ZeD.QA] windows reset (R)
ZEDQA g3s start (15 steps)
[ZeD.QA] run #6 ok=true
ZEDQA g3s aside: 6 worn, 1 on the belt, 71 items, hands nil / nil
ZEDQA g3s worn: Tshirt_DefaultTEXTURE_TINT Shirt_Lumberjack Jacket_ArmyOliveDrab Vest_Hunting_Khaki Trousers_Denim Socks_Heavy Shoes_ArmyBoots Gloves_LeatherGlovesBlack Hat_BaseballCapGreen Belt2 HolsterSimple_Black Kneepad_Left_Tactical Kneepad_Right_Tactical WristWatch_Left_DigitalBlack Glasses_Prescription_Aviators Bag_ALICEpack_Army Bag_ChestRig Bag_FannyPackBack Bag_Satchel_Leather
ZEDQA g3s bag back (Base.Bag_ALICEpack_Army): 13 things
ZEDQA g3s bag webbing (Base.Bag_ChestRig): 3 things
ZEDQA g3s bag fannypackback (Base.Bag_FannyPackBack): 2 things
ZEDQA g3s bag satchel (Base.Bag_Satchel_Leather): 3 things
ZEDQA g3s belt: HuntingKnife@smallbeltleft Hammer@smallbeltright Pistol@holsterright Shotgun@back
ZEDQA g3s hotbar slots: Back* HolsterRight* SmallBeltLeft* SmallBeltRight* BedrollBottomALICE
ZEDQA g3s trunk lid: open
ZEDQA g3s trunk: 11 things
ZEDQA g3s trunk area centre 13936.2,5729.6: the character goes to 13936.20,5730.01
ZEDQA g3s at 13936,5730: in the trunk area true, trunk reachable true
ZEDQA g3s duffel on the ground: 9 things
ZEDQA g3s parked cars spawned: 4 | cars within 22 now: 3
ZEDQA g3s background zombies: 8 | in the cell 8
ZEDQA g3s zombies still there after 150 frames: 8/8 | in the cell 8
ZEDQA g3s zoom 1
ZEDQA g3s shot g3_stage_mid ok
ZEDQA g3s end: 1 shots ok, 0 errors
ZEDQA g3s DONE
```

### 7. gallery_nov1_only_furniture.lua (`ZEDQA n1of`) - PASS, 1 s

- go 18019 at 15:19:42

```text
[ZeD.QA] windows reset (R)
ZEDQA n1of sections: furniture
[ZeD.QA] run #7 ok=true
ZEDQA n1of DONE
```

### 8. gallery_nov1_lot.lua (`ZEDQA n1l`) - PASS, 9 s

- go 18020 at 15:19:47

```text
[ZeD.QA] windows reset (R)
ZEDQA n1l start (25 steps)
[ZeD.QA] run #8 ok=true
ZEDQA n1l theme dark orange size small | scale nil
ZEDQA n1l zoom 1
ZEDQA n1l tall: char 777x2118 at 1136,21 | world 777x2118 at 1927,21 | screen 3840x2160
ZEDQA n1l furniture: the pointer's square 13935,5729 (isoToScreen named 13928,5736)
ZEDQA n1l furniture: furniture_seating_outdoor_01_17 placed at 13935,5729 (screen 1010,1100)
ZEDQA n1l furniture: mode pickup | the tab reads nil at 13935,5729
ZEDQA n1l shot zed_52_furniture ok
ZEDQA n1l rect zed_52_furniture char drawer 1199 67 0 2033 window 1136 21 777 2118 header 65 footer 39 tab loot
ZEDQA n1l rect zed_52_furniture world drawer 2641 67 840 2033 window 1927 21 1617 2118 header 65 footer 39 tab furniture
ZEDQA n1l furniture put back: the chair removed
ZEDQA n1l put back: heights, places, tabs, options | theme dark orange
ZEDQA n1l end: 1 shots ok, 0 errors
ZEDQA n1l DONE
```

### 9. gallery_v3_teardown.lua (`ZEDQA g3t`) - PASS, 10 s

- go 18021 at 15:19:59

```text
[ZeD.QA] windows reset (R)
ZEDQA g3t start (13 steps)
[ZeD.QA] run #9 ok=true
ZEDQA g3t removed 8 zombies, 4 ground things, 5 cars | zombies left in the cell 0
ZEDQA g3t kit off: 18 worn, 31 items removed
ZEDQA g3t back: 71 items, 6 worn, hands nil / nil
ZEDQA g3t belt back: 1/1
ERROR: General f:7674 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:7682 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA g3t zoom 1
ZEDQA g3t back at 925,13040 (was 925,13040) | carried 71 | zombies in the cell 0
ZEDQA g3t end: 0 shots ok, 0 errors
ZEDQA g3t DONE
```

### 10. gallery_t14_end.lua (`ZEDQA g14e`) - PASS, 1 s

- go 18022 at 15:20:12

```text
[ZeD.QA] windows reset (R)
ZEDQA g14e put back: menus true, watermark true, column true, options true | look now dark teal
[ZeD.QA] run #10 ok=true
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
