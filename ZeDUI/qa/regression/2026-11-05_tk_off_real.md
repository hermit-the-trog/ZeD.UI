# ZeD-UI regression - 2026-11-06 00:57 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-06 00:57:16 |
| Finished | 2026-11-06 00:59:44 (2 min 27 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_tk_off.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21657 to 21661 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; at the main menu
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1929,1118 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21660, 21661)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 2 | mp_tk_off.lua | mtf | PASS | 60 |  |  |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21658 at 00:58:17

```text
LOG : Lua f:257 st:107,895,077> [ZeD.QA] state #1 speed=1 paused=false player=10999,9701 grid=15 inCar=false vehicles=0
LOG : Lua f:257 st:107,895,079> [ZeD.QA] windows reset (R)
LOG : Lua f:257 st:107,895,079> ZEDQA pnw pinned both windows
LOG : Lua f:257 st:107,895,080> [ZeD.QA] run #1 ok=true
LOG : Lua f:277 st:107,895,256> ZEDQA pnw DONE
```

### 2. mp_tk_off.lua (`ZEDQA mtf`) - PASS, 60 s

- go 21659 at 00:58:21

```text
LOG : Lua f:767 st:107,899,479> [ZeD.QA] state #2 speed=1 paused=false player=10999,9701 grid=15 inCar=false vehicles=0
LOG : Lua f:767 st:107,899,481> [ZeD.QA] windows reset (R)
LOG : Lua f:767 st:107,899,482> [ZeD.QA] run #2 ok=true
LOG : Lua f:6165 st:107,944,488> ZEDQA mtf PASS with no server part the client says so (false)
LOG : Lua f:6165 st:107,944,489> ZEDQA mtf PASS not staff by the server part
LOG : Lua f:6285 st:107,945,488> ZEDQA mtf PASS the link reads off
LOG : Lua f:6530 st:107,948,100> ZEDQA mtf the ack: true true
LOG : Lua f:6530 st:107,948,100> ZEDQA mtf PASS Send goes through the game
LOG : Lua f:6770 st:107,950,101> ZEDQA mtf PASS my list reads the game's row (GRIEF)
LOG : Lua f:6770 st:107,950,102> ZEDQA mtf its words: qa: the fallback's words (10999 x 9701); status Sent
LOG : Lua f:7031 st:107,952,602> ZEDQA mtf PASS the queue reads the game's list (1)
LOG : Lua f:7031 st:107,952,603> ZEDQA mtf PASS the row keeps its kind (GRIEF)
LOG : Lua f:7127 st:107,953,803> ZEDQA mtf PASS viewed reads Seen (Seen)
LOG : Lua f:7265 st:107,955,304> ZEDQA mtf PASS answered (Answered)
LOG : Lua f:7392 st:107,956,805> ZEDQA mtf PASS the player reads Answered (Answered)
LOG : Lua f:7510 st:107,958,314> ZEDQA mtf PASS removed
LOG : Lua f:7510 st:107,958,315> ZEDQA mtf DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N st:0 at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N st:0 at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
