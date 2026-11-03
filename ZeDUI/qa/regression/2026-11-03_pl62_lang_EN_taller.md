# ZeD-UI regression - 2026-11-03 11:12 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 11:12:05 |
| Finished | 2026-11-03 11:13:44 (1 min 38 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\lang_check.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 19536 to 19539 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19538, 19539)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_lang.lua | lng | WARN | 11 | zqa_lng_EN_1_windows.png, zqa_lng_EN_2_health.png, zqa_lng_EN_3_skills.png, zqa_lng_EN_4_action_bar.png, zqa_lng_EN_5_watch_corner.png | 4 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 19536 at 11:13:03

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_lang.lua (`ZEDQA lng`) - WARN, 11 s

- go 19537 at 11:13:08
- 4 ERR line(s)
- screenshots: zqa_lng_EN_1_windows.png, zqa_lng_EN_2_health.png, zqa_lng_EN_3_skills.png, zqa_lng_EN_4_action_bar.png, zqa_lng_EN_5_watch_corner.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lng start
[ZeD.QA] run #2 ok=true
ZEDQA lng the game's language: EN
ZEDQA lng FAIL the game runs in EN
ZEDQA lng its name in the language list: English | a ZeD machine draft false
ZEDQA lng FAIL EN is one of ZeD's machine-translated languages (the list marks it)
ZEDQA lng PASS ZeD's English keys read (4257)
ZEDQA lng EN: 4257 keys | no text 0 | same as the English 523 (e.g. UI_ZeD_Accent_Teal, UI_ZeD_Act_AddChumToWaterAction, UI_ZeD_Act_AIAttachLureAction, UI_ZeD_Act_AIRemoveLureAction, UI_ZeD_Act_CreateChumFromGroundSandAction, UI_ZeD_Act_HealthPanelAction, UI_ZeD_Act_ISActivateCarBatteryChargerAction, UI_ZeD_Act_ISActivateGenerator, UI_ZeD_Act_ISAddAnimalInTrailer, UI_ZeD_Act_ISAddBaitAction, UI_ZeD_Act_ISAddBaitToFishNetAction, UI_ZeD_Act_ISAddCompost)
ZEDQA lng PASS EN: every ZeD key has text (no raw UI_ZeD_ key can show)
ZEDQA lng FAIL EN: nearly every key is translated (523 the same as the English)
ZEDQA lng summary: 3 of 5 checks FAIL
ZEDQA lng DONE
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
