# ZeD-UI regression - 2026-11-06 00:26 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-06 00:26:57 |
| Finished | 2026-11-06 00:29:53 (2 min 56 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_ticket_cards_large.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21609 to 21614 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; at the main menu
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1929,1118 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21613, 21614)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 2 | zedqa_large_text.lua | ltx | PASS | 1 |  |  |
| 3 | mp_ticket_cards.lua | mtc | PASS | 84 |  |  |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21610 at 00:27:58

```text
LOG : Lua f:256 st:106,076,074> [ZeD.QA] state #1 speed=1 paused=false player=10999,9701 grid=15 inCar=false vehicles=0
LOG : Lua f:256 st:106,076,075> [ZeD.QA] windows reset (R)
LOG : Lua f:256 st:106,076,076> ZEDQA pnw pinned both windows
LOG : Lua f:256 st:106,076,076> [ZeD.QA] run #1 ok=true
LOG : Lua f:276 st:106,076,233> ZEDQA pnw DONE
```

### 2. zedqa_large_text.lua (`ZEDQA ltx`) - PASS, 1 s

- go 21611 at 00:28:02

```text
LOG : Lua f:796 st:106,080,573> [ZeD.QA] state #2 speed=1 paused=false player=10999,9701 grid=15 inCar=false vehicles=0
LOG : Lua f:796 st:106,080,574> [ZeD.QA] windows reset (R)
LOG : Lua f:796 st:106,080,579> ZEDQA ltx text size now large
LOG : Lua f:796 st:106,080,580> [ZeD.QA] run #2 ok=true
LOG : Lua f:857 st:106,081,082> ZEDQA ltx DONE
```

### 3. mp_ticket_cards.lua (`ZEDQA mtc`) - PASS, 84 s

- go 21612 at 00:28:06

```text
LOG : Lua f:1306 st:106,084,928> [ZeD.QA] state #3 speed=1 paused=false player=10999,9701 grid=15 inCar=false vehicles=0
LOG : Lua f:1306 st:106,084,932> [ZeD.QA] windows reset (R)
LOG : Lua f:1306 st:106,084,933> [ZeD.QA] run #3 ok=true
LOG : Lua f:1466 st:106,086,586> ZEDQA mtc server-list: 7 stops
LOG : Lua f:1653 st:106,088,247> ZEDQA mtc server-empty: 4 stops
LOG : Lua f:1828 st:106,089,903> ZEDQA mtc server-flash: 7 stops
LOG : Lua f:2012 st:106,091,562> ZEDQA mtc ask-blank: 11 stops
LOG : Lua f:2199 st:106,093,216> ZEDQA mtc ask-griefing: 11 stops
LOG : Lua f:2388 st:106,094,874> ZEDQA mtc ask-off: 11 stops
LOG : Lua f:2574 st:106,096,533> ZEDQA mtc ask-link-wait: 11 stops
LOG : Lua f:2759 st:106,098,186> ZEDQA mtc ask-refused: 11 stops
LOG : Lua f:2947 st:106,099,851> ZEDQA mtc mine-open: 4 stops
LOG : Lua f:3114 st:106,101,508> ZEDQA mtc mine-answered: 3 stops
LOG : Lua f:3304 st:106,103,170> ZEDQA mtc mine-closed: 3 stops
LOG : Lua f:3485 st:106,104,841> ZEDQA mtc mine-long: 43 stops
LOG : Lua f:3671 st:106,106,508> ZEDQA mtc server-fallback: 5 stops
LOG : Lua f:3862 st:106,108,185> ZEDQA mtc mine-fallback: 3 stops
LOG : Lua f:4033 st:106,109,851> ZEDQA mtc queue-link-wait: 39 stops
LOG : Lua f:4208 st:106,111,507> ZEDQA mtc queue-loading: 49 stops
LOG : Lua f:4350 st:106,113,169> ZEDQA mtc queue-open: 55 stops
LOG : Lua f:4532 st:106,114,823> ZEDQA mtc queue-answered: 52 stops
LOG : Lua f:4676 st:106,116,478> ZEDQA mtc queue-closed: 51 stops
LOG : Lua f:4860 st:106,118,133> ZEDQA mtc queue-all: 58 stops
LOG : Lua f:5026 st:106,119,806> ZEDQA mtc queue-spam-admin: 51 stops
LOG : Lua f:5179 st:106,121,479> ZEDQA mtc queue-spam-moderator: 51 stops
LOG : Lua f:5345 st:106,123,140> ZEDQA mtc queue-none: 50 stops
LOG : Lua f:5524 st:106,124,799> ZEDQA mtc queue-no-match: 50 stops
LOG : Lua f:5687 st:106,126,480> ZEDQA mtc queue-paged-1: 77 stops
LOG : Lua f:5855 st:106,128,143> ZEDQA mtc queue-paged-2: 53 stops
LOG : Lua f:6002 st:106,129,808> ZEDQA mtc queue-notes: 55 stops
LOG : Lua f:6178 st:106,131,468> ZEDQA mtc queue-frozen: 55 stops
LOG : Lua f:6334 st:106,133,140> ZEDQA mtc queue-pop-kind: 55 stops
LOG : Lua f:6485 st:106,134,799> ZEDQA mtc queue-pop-mine: 55 stops
LOG : Lua f:6645 st:106,136,450> ZEDQA mtc queue-pop-who-many: 77 stops
LOG : Lua f:6806 st:106,138,111> ZEDQA mtc queue-fallback: 49 stops
LOG : Lua f:6992 st:106,139,774> ZEDQA mtc card-open: 12 stops
LOG : Lua f:7168 st:106,141,427> ZEDQA mtc card-progress-notes: 14 stops
LOG : Lua f:7354 st:106,143,088> ZEDQA mtc card-answered: 11 stops
LOG : Lua f:7538 st:106,144,742> ZEDQA mtc card-closed: 11 stops
LOG : Lua f:7720 st:106,146,407> ZEDQA mtc card-no-kind: 11 stops
LOG : Lua f:7907 st:106,148,060> ZEDQA mtc card-spam-admin: 7 stops
LOG : Lua f:8083 st:106,149,721> ZEDQA mtc card-spam-moderator: 6 stops
LOG : Lua f:8265 st:106,151,377> ZEDQA mtc card-moderator: 11 stops
LOG : Lua f:8448 st:106,153,035> ZEDQA mtc card-confirm: 9 stops
LOG : Lua f:8636 st:106,154,696> ZEDQA mtc card-no-go: 12 stops
LOG : Lua f:8819 st:106,156,369> ZEDQA mtc card-no-stats: 12 stops
LOG : Lua f:9006 st:106,158,019> ZEDQA mtc card-frozen: 12 stops
LOG : Lua f:9170 st:106,159,687> ZEDQA mtc card-removed-game: 12 stops
LOG : Lua f:9351 st:106,161,343> ZEDQA mtc card-flash: 12 stops
LOG : Lua f:9527 st:106,163,005> ZEDQA mtc card-long: 70 stops
LOG : Lua f:9715 st:106,164,668> ZEDQA mtc card-fallback: 6 stops
LOG : Lua f:9903 st:106,166,324> ZEDQA mtc card-fallback-answered: 5 stops
LOG : Lua f:10087 st:106,167,989> ZEDQA mtc card-fallback-confirm: 6 stops
LOG : Lua f:10137 st:106,168,496> ZEDQA mtc DONE
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
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
