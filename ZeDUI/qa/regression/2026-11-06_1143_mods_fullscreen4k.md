# ZeD-UI regression - 2026-11-06 11:43 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 11:43:45 |
| Finished | 2026-11-06 11:46:34 (2 min 48 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\roadworthy_list_manifest.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 22077 to 22080 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22079, 22080)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_modlist.lua | mls | PASS | 1 |  |  |
| 2 | zedqa_roadworthy.lua | rw | **FAIL** | 78 | zqa_rw_1_elite.png, zqa_rw_2_amber.png, zqa_rw_3_red.png, zqa_rw_4_blink.png, zqa_rw_5_stalled.png, zqa_rw_6_lamps.png, zqa_rw_7_full_unpainted.png, zqa_rw_8_simple.png | 3 Java exception(s) in the log |

## Scripts

### 1. zedqa_modlist.lua (`ZEDQA mls`) - PASS, 1 s

- go 22077 at 11:44:49

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=47 missing=get
[ZeD.QA] windows reset (R)
ZEDQA mls on: VehicleSwissKnife, RealisticDrivingOverhaul, ZeD_UI
[ZeD.QA] run #1 ok=true
ZEDQA mls DONE
```

### 2. zedqa_roadworthy.lua (`ZEDQA rw`) - FAIL, 78 s

- go 22078 at 11:44:53
- 3 Java exception(s) in the log
- screenshots: zqa_rw_1_elite.png, zqa_rw_2_amber.png, zqa_rw_3_red.png, zqa_rw_4_blink.png, zqa_rw_5_stalled.png, zqa_rw_6_lamps.png, zqa_rw_7_full_unpainted.png, zqa_rw_8_simple.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=47 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rw start
[ZeD.QA] run #2 ok=true
ERROR: General f:1553 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA rw PASS the dash reads the library
ZEDQA rw PASS temperature is Roadworthy's gauge: 0 / 0
ZEDQA rw PASS oil is Roadworthy's gauge: 0.6529188183277314 / 0.6529188183277314
ZEDQA rw World Scale 0.65, speed multiplier 1.5384615384615383
ZEDQA rw PASS the speed multiplier is the scale's
ZEDQA rw PASS Roadworthy's odometer is published: 21665.578385589415 km
ZEDQA rw PASS Simple's figure is the odometer: 13462
ZEDQA rw PASS the LCD is its last four figures: 3462
ZEDQA rw gear label R, plate letter R
ZEDQA rw PASS the gear label reached the dash
ZEDQA rw PASS 125: the hot lamp is amber: #ffb02e
ZEDQA rw PASS 125: the published needle: 0.7727272727272727
ZEDQA rw PASS 125: the needle climbs: 0.001465156111650011 -> 0.626619290880884
ZEDQA rw PASS 132: the hot lamp is red: #ff3a20
ZEDQA rw PASS 132: the engine lamp's role is red with it (checkEngine)
ZEDQA rw PASS 142: red and dark, blinking
ZEDQA rw PASS the engine died: the dash stays lit
ZEDQA rw PASS lamps: the dash reads the library
ZEDQA rw lamp rdo.temp (Engine temperature) role=tempLamp on=false rank=0
ZEDQA rw PASS rdo.temp as Roadworthy has it: off
ZEDQA rw lamp rdo.belt (Seat belt) role=beltLamp on=true rank=3
ZEDQA rw PASS rdo.belt as Roadworthy has it: crit
ZEDQA rw lamp rdo.oil (Engine oil) role=oilLamp on=false rank=0
ZEDQA rw PASS rdo.oil as Roadworthy has it: off
ZEDQA rw lamp rdo.charge (Charge) role=genLamp on=false rank=0
ZEDQA rw PASS rdo.charge as Roadworthy has it: off
ZEDQA rw lamp rdo.check (Check engine) role=engLamp on=false rank=0
ZEDQA rw PASS rdo.check as Roadworthy has it: off
ZEDQA rw PASS unbuckled: the belt lamp is red
ERROR: General f:6807> Lua(Vanilla).spawnpoints> Exception thrown
    se.krka.kahlua.vm.KahluaException: on purpose at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).spawnpoints(spawnpoints.lua:225)
    Lua((MOD:Vehicle Kit Library (B42))).poll(VSK_Dashboard.lua:310)
    Lua((MOD:ZeD-GUI)).read(VSKDash.lua:212)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Dashboard.lua:1633)
[VSK][dash] provider zedqa.throws failed (1/3): on purpose
ERROR: General f:6815> Lua(Vanilla).spawnpoints> Exception thrown
    se.krka.kahlua.vm.KahluaException: on purpose at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).spawnpoints(spawnpoints.lua:225)
    Lua((MOD:Vehicle Kit Library (B42))).poll(VSK_Dashboard.lua:310)
    Lua((MOD:ZeD-GUI)).read(VSKDash.lua:212)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Dashboard.lua:1633)
[VSK][dash] provider zedqa.throws failed (2/3): on purpose
ERROR: General f:6825> Lua(Vanilla).spawnpoints> Exception thrown
    se.krka.kahlua.vm.KahluaException: on purpose at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).spawnpoints(spawnpoints.lua:225)
    Lua((MOD:Vehicle Kit Library (B42))).poll(VSK_Dashboard.lua:310)
    Lua((MOD:ZeD-GUI)).read(VSKDash.lua:212)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Dashboard.lua:1633)
[VSK][dash] provider zedqa.throws failed (3/3): on purpose
[VSK][dash] provider zedqa.throws disabled for this session
ZEDQA rw PASS a lamp with no spot is published and lit
ZEDQA rw PASS Full: nothing on the plate took it (the constant is off)
ZEDQA rw PASS the throwing provider has retired
ZEDQA rw PASS the dash runs on
ZEDQA rw errors=0
ZEDQA rw all checks passed
ZEDQA rw DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
