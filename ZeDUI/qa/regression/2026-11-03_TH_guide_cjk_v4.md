# ZeD-UI regression - 2026-11-03 21:11 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 21:11:43 |
| Finished | 2026-11-03 21:13:33 (1 min 49 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\guide_cjk.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 20037 to 20042 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 20041, 20042)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 3 | zedqa_guide82_measure.lua | g8m | WARN | 6 |  | 1 ERR line(s) |
| 4 | zedqa_book83_lang.lua | b8l | PASS | 7 | zqa_b8l_TH_1_window_skill_books.png, zqa_b8l_TH_2_window_rules.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 20037 at 21:12:42

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 20038 at 21:12:47

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #2 ok=true
ZEDQA hcn DONE
```

### 3. zedqa_guide82_measure.lua (`ZEDQA g8m`) - WARN, 6 s

- go 20039 at 21:12:51
- 1 ERR line(s)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g8m start
[ZeD.QA] run #3 ok=true
ZEDQA g8m lines 290; letters per line: most 83, longest tenth from 74; measure 617 px; window 1204 x 1164 px
ZEDQA g8m FAIL letters per line about 60-70 (most 83, longest tenth 74)
ZEDQA g8m PASS no line carries a line break inside it (drawn a line low)
ZEDQA g8m PASS no line runs past the measure
ZEDQA g8m PASS the clip fits the measure
ZEDQA g8m PASS the rules table fits the measure
ZEDQA g8m PASS the head line (title, section, n of 81) fits
ZEDQA g8m PASS the band fits: the start-up box, Previous, Next inside the window and apart
ZEDQA g8m PASS the window fits the screen
ZEDQA g8m RESULT 7 pass, 1 fail
ZEDQA g8m DONE
```

### 4. zedqa_book83_lang.lua (`ZEDQA b8l`) - PASS, 7 s

- go 20040 at 21:13:01
- screenshots: zqa_b8l_TH_1_window_skill_books.png, zqa_b8l_TH_2_window_rules.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8l start
[ZeD.QA] run #4 ok=true
ZEDQA b8l language TH: F1 look the window
ZEDQA b8l shot 1_window_skill_books
ZEDQA b8l shot 2_window_rules
ZEDQA b8l DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    2x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
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
