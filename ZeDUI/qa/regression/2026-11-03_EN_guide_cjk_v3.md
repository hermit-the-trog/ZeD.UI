# ZeD-UI regression - 2026-11-03 20:54 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 20:54:16 |
| Finished | 2026-11-03 20:56:08 (1 min 52 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\guide_cjk.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 19996 to 20001 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 20000, 20001)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 3 | zedqa_guide82_measure.lua | g8m | PASS | 7 |  |  |
| 4 | zedqa_book83_lang.lua | b8l | PASS | 9 | zqa_b8l_EN_1_title.png, zqa_b8l_EN_2_contents_intro.png, zqa_b8l_EN_3_chapter_opener.png, zqa_b8l_EN_4_skill_books_rules.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 19996 at 20:55:14

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 17.10 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 19997 at 20:55:20

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #2 ok=true
ZEDQA hcn DONE
```

### 3. zedqa_guide82_measure.lua (`ZEDQA g8m`) - PASS, 7 s

- go 19998 at 20:55:24

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA g8m start
[ZeD.QA] run #3 ok=true
ZEDQA g8m lines 351; letters per line: most 71, longest tenth from 67; measure 690 px; window 1277 x 1164 px
ZEDQA g8m PASS letters per line about 60-70 (most 71, longest tenth 67)
ZEDQA g8m PASS no line carries a line break inside it (drawn a line low)
ZEDQA g8m PASS no line runs past the measure
ZEDQA g8m PASS the clip fits the measure
ZEDQA g8m PASS the rules table fits the measure
ZEDQA g8m PASS the head line (title, section, n of 81) fits
ZEDQA g8m PASS the band fits: the start-up box, Previous, Next inside the window and apart
ZEDQA g8m PASS the window fits the screen
ZEDQA g8m RESULT 8 pass, 0 fail
ZEDQA g8m DONE
```

### 4. zedqa_book83_lang.lua (`ZEDQA b8l`) - PASS, 9 s

- go 19999 at 20:55:34
- screenshots: zqa_b8l_EN_1_title.png, zqa_b8l_EN_2_contents_intro.png, zqa_b8l_EN_3_chapter_opener.png, zqa_b8l_EN_4_skill_books_rules.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8l start
[ZeD.QA] run #4 ok=true
ZEDQA b8l language EN: F1 look the book
ZEDQA b8l shot 1_title
ZEDQA b8l shot 2_contents_intro
ZEDQA b8l shot 3_chapter_opener
ZEDQA b8l shot 4_skill_books_rules
ZEDQA b8l DONE
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
