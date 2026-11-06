# ZeD-UI regression - 2026-11-05 21:19 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-05 21:19:33 |
| Finished | 2026-11-05 21:22:26 (2 min 52 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\identity.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21480 to 21484 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 21483, 21484)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_identity.lua | idt | PASS | 82 | zqa_id_1280x800_immersive_bust.png, zqa_id_1280x800_immersive_body.png, zqa_id_1280x800_simple_bust.png, zqa_id_1280x800_simple_body.png, zqa_id_1280x800_immersive_trend_steady.png, zqa_id_1280x800_simple_trend_steady.png, zqa_id_1280x800_immersive_trend_up.png, zqa_id_1280x800_simple_trend_up.png, zqa_id_1280x800_immersive_trend_upup.png, zqa_id_1280x800_simple_trend_upup.png, zqa_id_1280x800_immersive_trend_down.png, zqa_id_1280x800_simple_trend_down.png, zqa_id_1280x800_prof_policeofficer.png, zqa_id_1280x800_prof_veteran.png, zqa_id_1280x800_prof_securityguard.png, zqa_id_1280x800_prof_parkranger.png, zqa_id_1280x800_prof_burgerflipper.png, zqa_id_1280x800_prof_burglar.png, zqa_id_1280x800_prof_unemployed.png, zqa_id_1280x800_longname_immersive.png, zqa_id_1280x800_longname_simple.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 21480 at 21:20:30

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=22 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21481 at 21:20:35

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=22 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_identity.lua (`ZEDQA idt`) - PASS, 82 s

- go 21482 at 21:20:40
- screenshots: zqa_id_1280x800_immersive_bust.png, zqa_id_1280x800_immersive_body.png, zqa_id_1280x800_simple_bust.png, zqa_id_1280x800_simple_body.png, zqa_id_1280x800_immersive_trend_steady.png, zqa_id_1280x800_simple_trend_steady.png, zqa_id_1280x800_immersive_trend_up.png, zqa_id_1280x800_simple_trend_up.png, zqa_id_1280x800_immersive_trend_upup.png, zqa_id_1280x800_simple_trend_upup.png, zqa_id_1280x800_immersive_trend_down.png, zqa_id_1280x800_simple_trend_down.png, zqa_id_1280x800_prof_policeofficer.png, zqa_id_1280x800_prof_veteran.png, zqa_id_1280x800_prof_securityguard.png, zqa_id_1280x800_prof_parkranger.png, zqa_id_1280x800_prof_burgerflipper.png, zqa_id_1280x800_prof_burglar.png, zqa_id_1280x800_prof_unemployed.png, zqa_id_1280x800_longname_immersive.png, zqa_id_1280x800_longname_simple.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=22 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA idt the drawer's width 360, scale 0.75, narrow card false
ZEDQA idt shot immersive_bust window 0,0 640x315
ZEDQA idt shot immersive_body window 0,0 640x315
ZEDQA idt shot simple_bust window 0,0 640x315
ZEDQA idt shot simple_body window 0,0 640x315
ZEDQA idt shot immersive_trend_steady window 0,0 640x315
ZEDQA idt shot simple_trend_steady window 0,0 640x315
ZEDQA idt shot immersive_trend_up window 0,0 640x315
ZEDQA idt shot simple_trend_up window 0,0 640x315
ZEDQA idt shot immersive_trend_upup window 0,0 640x315
ZEDQA idt shot simple_trend_upup window 0,0 640x315
ZEDQA idt shot immersive_trend_down window 0,0 640x315
ZEDQA idt shot simple_trend_down window 0,0 640x315
ZEDQA idt shot prof_policeofficer window 0,0 640x315
ZEDQA idt shot prof_veteran window 0,0 640x315
ZEDQA idt shot prof_securityguard window 0,0 640x315
ZEDQA idt shot prof_parkranger window 0,0 640x315
ZEDQA idt shot prof_burgerflipper window 0,0 640x315
ZEDQA idt shot prof_burglar window 0,0 640x315
ZEDQA idt shot prof_unemployed window 0,0 640x315
ZEDQA idt shot longname_immersive window 0,0 640x315
ZEDQA idt shot longname_simple window 0,0 640x315
ZEDQA idt model press 1 at 95,140, zone 23,75 90x90, model 50,95 90x90, full body false
ZEDQA idt PASS model press 1 turns the photo: false to true
ZEDQA idt model press 2 at 95,189, zone 12,75 113x188, model 39,95 113x188, full body true
ZEDQA idt PASS model press 2 turns the photo: true to false
ZEDQA idt sky press 1 at 55,100, zone 23,75 90x90, model 50,95 90x90, full body false
ZEDQA idt PASS sky press 1 turns the photo: false to true
ZEDQA idt sky press 2 at 44,100, zone 12,75 113x188, model 39,95 113x188, full body true
ZEDQA idt PASS sky press 2 turns the photo: true to false
ZEDQA idt DONE
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
