# ZeD-UI regression - 2026-11-05 19:26 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 19:26:16 |
| Finished | 2026-11-05 19:28:54 (2 min 37 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/elbows.txt (3 scripts) |
| Result | **2/3 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 21470 to 21474 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21473, 21474)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_elbows.lua | elb | **FAIL** | 26 | zqa_elb_board.png, zqa_elb_male_health.png, zqa_elb_male_thermal.png, zqa_elb_male_equip.png, zqa_elb_female_health.png, zqa_elb_female_thermal.png, zqa_elb_female_equip.png | 3 Java exception(s) in the log |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21470 at 19:27:53

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21471 at 19:27:58

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_elbows.lua (`ZEDQA elb`) - FAIL, 26 s

- go 21472 at 19:28:03
- 3 Java exception(s) in the log
- screenshots: zqa_elb_board.png, zqa_elb_male_health.png, zqa_elb_male_thermal.png, zqa_elb_male_equip.png, zqa_elb_female_health.png, zqa_elb_female_thermal.png, zqa_elb_female_equip.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=46 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
WARN : General f:815> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '%1$s' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "UI_ZeD_Order_PickNoneAfter"
ZEDQA elb PASS UI_ZeD_Order_PickNoneAfter: Choose the mod %1$s loads after. Grayed mods cannot be chose
WARN : General f:815> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '%1$s' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "UI_ZeD_Order_PickNoneBefore"
ZEDQA elb PASS UI_ZeD_Order_PickNoneBefore: Choose the mod %1$s loads before. Grayed mods cannot be chos
WARN : General f:815> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '%1$s' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "UI_ZeD_Mods_HelpLabel"
ZEDQA elb PASS UI_ZeD_Mods_HelpLabel: Label: %1$s. It colors the folder's picture, or the separato
ZEDQA elb PASS UI_ZeD_GCh_zed_look_Text: Every ZeD window has a window menu at its top left. It sets
ZEDQA elb PASS UI_ZeD_GCh_whatsnew_beta3_Text: The survival guide: this book or the plain window (Full or S
ZEDQA elb male, viewer's left: 80 Right Upper Arm, 104 Right Forearm, 136 Right Hand
ZEDQA elb male, viewer's right: 56 Left Upper Arm, 104 Left Forearm, 108 Groin, 108 Left Forearm, 112 Groin, 112 Left Forearm, 116 Groin, 116 Left Forearm, 120 Groin, 120 Left Forearm, 124 Groin, 124 Left Forearm, 128 Groin, 128 Left Upper Leg, 128 Left Forearm, 132 Left Upper Leg, 132 Left Forearm, 136 Left Upper Leg, 136 Left Hand, 140 Left Upper Leg, 140 Left Hand, 144 Left Upper Leg, 144 Left Hand, 148 Left Upper Leg, 148 Left Hand, 152 Left Upper Leg, 152 Left Hand, 156 Left Upper Leg, 156 Left Hand, 160 Left Upper Leg, 160 Left Hand, 164 Left Upper Leg, 164 Left Hand, 168 Left Upper Leg
ZEDQA elb female, viewer's left: 76 Right Upper Arm, 104 Right Forearm, 136 Right Hand
ZEDQA elb female, viewer's right: 56 Left Upper Arm, 104 Left Forearm, 108 Groin, 108 Left Forearm, 112 Groin, 112 Left Forearm, 116 Groin, 116 Left Forearm, 120 Groin, 120 Left Forearm, 124 Groin, 124 Left Forearm, 128 Groin, 128 Left Upper Leg, 128 Left Forearm, 132 Left Upper Leg, 132 Left Forearm, 136 Left Upper Leg, 136 Left Hand, 140 Left Upper Leg, 140 Left Hand, 144 Left Upper Leg, 144 Left Hand, 148 Left Upper Leg, 148 Left Hand, 152 Left Upper Leg, 152 Left Hand, 156 Left Upper Leg, 156 Left Hand, 160 Left Upper Leg, 160 Left Hand, 164 Left Upper Leg, 164 Left Hand, 168 Left Upper Leg
ZEDQA elb the character is male: false
ZEDQA elb the character is female: true
ZEDQA elb DONE
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
