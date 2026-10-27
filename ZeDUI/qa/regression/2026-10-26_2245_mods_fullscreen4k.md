# ZeD-UI regression - 2026-10-26 22:45 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 22:45:56 |
| Finished | 2026-10-26 22:48:17 (2 min 20 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\AppData\Local\Temp\claude\C--Users-danie-Zomboid\989d1212-0f15-49ba-a371-9ee134c38e7f\scratchpad\r3\msg_manifest.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 13895 to 13898 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13897, 13898)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_messages.lua | msg | **FAIL** | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 2 Java exception(s) in the log; 1 expected exception(s) ignored (expect=); 14 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13895 at 22:47:29

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_messages.lua (`ZEDQA msg`) - FAIL, 11 s

- go 13896 at 22:47:34
- 2 Java exception(s) in the log
- 1 expected exception(s) ignored (expect=)
- 14 ERR line(s)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #2 ok=true
ZEDQA msg PASS nothing kept: no envelope on the belt
ZEDQA msg FAIL the three notes are not on screen
ZEDQA msg FAIL the three notes are kept in Messages
ZEDQA msg FAIL the source has three messages (1)
ZEDQA msg FAIL three are new (1)
ZEDQA msg PASS a toast names the mod
ZEDQA msg PASS the game runs on after the mod paused it for its note (speed 1)
ZEDQA msg PASS the envelope is on the belt
ZEDQA msg PASS a question still asks at once
ERROR: General f:924> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in step at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).step(spawnpoints.lua:85)
    Lua(Vanilla).tick(spawnpoints.lua:198)
ZEDQA msg ERR step 6: Object tried to call nil in step java.lang.RuntimeException
ZEDQA msg FAIL the mod got its answer (YES)
ZEDQA msg FAIL a copy of the question, already read, is in Messages
ERROR: General f:941 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:941> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(spawnpoints.lua:99)
ZEDQA msg FAIL the one error is filed in Messages, counted once (0 -> 2)
ZEDQA msg PASS Messages opens on the mod
ZEDQA msg PASS opening it marks the mod's messages read
ZEDQA msg FAIL four cards: three notes and the question (1)
ZEDQA msg FAIL three OK buttons, one per note (1)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg FAIL A on the next card's OK ran its callback
ZEDQA msg FAIL the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (3641 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ERROR: General f:1472> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in step at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).step(spawnpoints.lua:161)
    Lua(Vanilla).tick(spawnpoints.lua:198)
ZEDQA msg ERR step 17: Object tried to call nil in step java.lang.RuntimeException
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg FAIL the last unanswered note got its OK as it left
ZEDQA msg 12 failed
ZEDQA msg DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
