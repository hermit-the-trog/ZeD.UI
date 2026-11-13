# ZeD-UI regression - 2026-11-12 21:54 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-12 21:54:03 |
| Finished | 2026-11-12 21:55:53 (1 min 50 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI\tools\qa\_b12r2_lc_manifest.txt (1 scripts) |
| Result | **0/1 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 26046 to 26048 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 26047, 26048)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | _b12r2_lc.lua | lc | **FAIL** | 17 | zqa_lc_x_4k_open.png, zqa_lc_x_4k_prints.png, zqa_lc_x_4k_error_stack.png, zqa_lc_x_4k_scratch.png, zqa_lc_x_4k_suggest.png, zqa_lc_x_4k_commands.png, zqa_lc_x_4k_help.png | 3 Java exception(s) in the log |

## Scripts

### 1. _b12r2_lc.lua (`ZEDQA lc`) - FAIL, 17 s

- go 26046 at 21:55:08
- 3 Java exception(s) in the log
- screenshots: zqa_lc_x_4k_open.png, zqa_lc_x_4k_prints.png, zqa_lc_x_4k_error_stack.png, zqa_lc_x_4k_scratch.png, zqa_lc_x_4k_suggest.png, zqa_lc_x_4k_commands.png, zqa_lc_x_4k_help.png

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lc globals: LC93=false ZeD=true ZeD.DebugConsole=true
ZEDQA lc console in use: ZeD's
ZEDQA lc armed
[ZeD.QA] run #1 ok=true
ZEDQA lc open=true page=log title=Lua console
ZEDQA lc shot open
ZEDQA lc row print | ZEDQA lc shot open
ZEDQA lc row print | ZEDQA lc open=true page=log title=Lua console
ZEDQA lc row print | ZEDQA lc shot open
ZEDQA lc row ran | > print("hello")
ZEDQA lc row ran | > - "print("hello")".
ZEDQA lc row print | hello   (x2)
ZEDQA lc row ran | > print(LC93 ~= nil, ZeD == nil)
ZEDQA lc row ran | > - "print(LC93 ~= nil, ZeD == nil)".
ZEDQA lc row print | false false   (x2)
ZEDQA lc shot prints
ERROR: General f:227 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: x of non-table: null
ERROR: General f:227> Lua(Vanilla).console> Exception thrown
    java.lang.RuntimeException: attempted index: x of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).console(spawnpoints.lua:1)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)
    Lua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)
    Lua(Vanilla).step(spawnpoints.lua:36)
    Lua(Vanilla).onTick(spawnpoints.lua:20)
ERROR: General f:242 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: x of non-table: null
ERROR: General f:242> Lua(Vanilla).console> Exception thrown
    java.lang.RuntimeException: attempted index: x of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).console(spawnpoints.lua:1)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)
    Lua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)
    Lua(Vanilla).step(spawnpoints.lua:37)
    Lua(Vanilla).onTick(spawnpoints.lua:20)
ERROR: General f:257 at KahluaThread.flushErrorMessage > -------------------------------------------------------------
    attempted index: x of non-table: null
ERROR: General f:257> Lua(Vanilla).console> Exception thrown
    java.lang.RuntimeException: attempted index: x of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).console(spawnpoints.lua:1)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:266)
    Lua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:266)
    Lua(Vanilla).step(spawnpoints.lua:38)
    Lua(Vanilla).onTick(spawnpoints.lua:20)
ZEDQA lc errrow n=3 box=3 f11=nil mod=#game msg=------------------------------------------------------------- stack=1
ZEDQA lc errrow n=6 box=6 f11=nil mod=ZeD-GUI msg=dumping Lua stack trace stack=9
ZEDQA lc errrow n=3 box=3 f11=2 mod=ZeD-GUI msg=attempted index: x of non-table: null stack=64
ZEDQA lc errrow n=3 box=3 f11=nil mod=ZeD-GUI msg=zombie.ui.UIDebugConsole.ProcessCommand(UIDebugConsole.java:391) stack=47
ZEDQA lc error rows=4 (expect 1, count 3)
ZEDQA lc stack opened=true
ZEDQA lc shot error_stack
ZEDQA lc export name=ZeD_console_2026-11-12_215516.log lines=65
ZEDQA lc export first line: ZeD-GUI Lua console | 2026-11-12_215516 | 65 of 65 | errors 4
ZEDQA lc export last line: Your user name is taken out of this report. Files like console.txt still have it: look them over before you post them.
ZEDQA lc export lines naming a Users folder: 0
ZEDQA lc NOT RUN scratchpad: LC93.ConsoleScratch missing (this is not LC93's console)
ZEDQA lc shot scratch
ZEDQA lc suggestion for getPl: nil | nil
ZEDQA lc shot suggest
ZEDQA lc page cmds=cmds
ZEDQA lc shot commands
ZEDQA lc page help=help
ZEDQA lc shot help
ZEDQA lc page back log=log
ZEDQA lc DONE
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
