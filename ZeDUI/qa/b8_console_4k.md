# ZeD-UI regression - 2026-11-08 08:00 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-08 08:00:48 |
| Finished | 2026-11-08 08:02:31 (1 min 42 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.3.0-beta8 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b8_console_manifest.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 23928 to 23931 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 23930, 23931)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 4 |  |  |
| 2 | zedqa_b8_console.lua | b8dc | WARN | 14 | zqa_b8dc_open.png, zqa_b8dc_typed.png, zqa_b8dc_errors.png, zqa_b8dc_handed_back.png | 1 expected exception(s) ignored (expect=); 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 4 s

- go 23928 at 08:01:45

```text
[ZeD.QA] state #1 speed=1 paused=false player=928,13041 grid=19 inCar=false vehicles=27 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 928,13041,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_b8_console.lua (`ZEDQA b8dc`) - WARN, 14 s

- go 23929 at 08:01:53
- 1 expected exception(s) ignored (expect=)
- 1 ERR line(s)
- screenshots: zqa_b8dc_open.png, zqa_b8dc_typed.png, zqa_b8dc_errors.png, zqa_b8dc_handed_back.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8dc start
[ZeD.QA] run #2 ok=true
ZEDQA b8dc NOTE the console was up at the start: true (UI.DebugConsole.StartVisible)
ZEDQA b8dc PASS 1: with the game's flag down ZeD's Lua console is shut
ZEDQA b8dc PASS 1: the game's own console is off the screen
ZEDQA b8dc PASS 1: with the flag up (the key) ZeD's Lua console opens
ZEDQA b8dc PASS 1: and the game's own console stays parked off the screen
ZEDQA b8dc PASS 1: the window is on the screen
ZEDQA b8dc PASS 3: print(...) shows in the list
ZEDQA b8dc PASS 3: the game's line is empty after the run
ZEDQA b8dc PASS 3: the line is the newest history entry (print("hello_b8dc"))
ZEDQA b8dc PASS 6: the same line twice in a row keeps one history entry (1 then 1)
ZEDQA b8dc PASS 3b: ZeD's input line exists
ZEDQA b8dc 3b typed line face Dialogue, entry px 11, F3 px 11
ERROR: General f:1141> Lua(Vanilla).console> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index of non-table at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).console(spawnpoints.lua:1)
    Lua((MOD:ZeD-GUI)).pcall(ZeD_DebugConsole.lua:211)
    Lua((MOD:ZeD-GUI)).run(ZeD_DebugConsole.lua:211)
    Lua(Vanilla).step(spawnpoints.lua:160)
    Lua(Vanilla).onTick(spawnpoints.lua:69)
ZEDQA b8dc PASS 4: a runtime error adds an error block (0 then 1)
ZEDQA b8dc 4 bytes line 14: 76,79,71,32,32,58 err=nil
ZEDQA b8dc 4 bytes line 15: 91,85,83,69,82,93 err=nil
ZEDQA b8dc 4 bytes line 16: 97,32,112,114,105,110 err=nil
ZEDQA b8dc 4 bytes line 17: 76,79,71,32,32,58 err=nil
ZEDQA b8dc 4 bytes line 18: 90,69,68,81,65,32 err=nil
ZEDQA b8dc 4 parse of a clean copy: 1 error block(s); line 2 err true; text length 4184, lines 69, errors counted 1
ZEDQA b8dc PASS 4: its words are in the list
ZEDQA b8dc PASS 5: a line that does not compile adds an error block (1 then 2)
ZEDQA b8dc PASS 5: the console's own compile message is in the list
ZEDQA b8dc PASS 6: the history ends with the last line run (oldest first; 4 entries)
ZEDQA b8dc FAIL 7: the game's suggestion for getPlay names getPlayer (nil)
ZEDQA b8dc PASS 7: Tab turns getPlay into getPlayer() (getPlayer())
ZEDQA b8dc PASS 7: a suggestion that does not start with the typed word (getPl) is not offered (nil)
ZEDQA b8dc PASS 7: Tab on getPl changes nothing (nil)
ZEDQA b8dc PASS 8: Clear empties the list
ZEDQA b8dc PASS 8: new output shows after a clear
ZEDQA b8dc PASS 8: the typed command clear empties the list too
ZEDQA b8dc PASS 11: the close box shuts ZeD's window
ZEDQA b8dc PASS 11: and the game's flag goes down with it
ZEDQA b8dc PASS 11: the key (the flag) opens it again
ZEDQA b8dc PASS pad 1: the ZeD wheel's last slice is the Lua console (Lua console)
ZEDQA b8dc PASS pad 1: with the pencil icon
ZEDQA b8dc PASS 12: the switch On hands the console back to the game
ZEDQA b8dc PASS 12: ZeD's window is shut
ZEDQA b8dc PASS 12: the game's own console is back in its place (x 20)
ZEDQA b8dc PASS 12: and open, as ZeD's was
ZEDQA b8dc PASS 12: the switch Off takes it again
ZEDQA b8dc PASS 12: ZeD's window is back
ZEDQA b8dc PASS 12: the game's own console is parked again
ZEDQA b8dc checks: passes=33 misses=1
ZEDQA b8dc DONE
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
