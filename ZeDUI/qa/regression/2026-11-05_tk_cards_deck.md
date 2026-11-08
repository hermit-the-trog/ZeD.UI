# ZeD-UI regression - 2026-11-06 00:23 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-06 00:23:26 |
| Finished | 2026-11-06 00:26:19 (2 min 52 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_ticket_cards_pin.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21604 to 21608 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; at the main menu
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1929,1118 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21607, 21608)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 2 | mp_ticket_cards.lua | mtc | PASS | 84 |  |  |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21605 at 00:24:27

```text
LOG : Lua f:288 st:105,865,933> [ZeD.QA] state #1 speed=1 paused=false player=10999,9701 grid=15 inCar=false vehicles=0
LOG : Lua f:288 st:105,865,934> [ZeD.QA] windows reset (R)
LOG : Lua f:288 st:105,865,935> ZEDQA pnw pinned both windows
LOG : Lua f:288 st:105,865,935> [ZeD.QA] run #1 ok=true
LOG : Lua f:308 st:105,866,093> ZEDQA pnw DONE
```

### 2. mp_ticket_cards.lua (`ZEDQA mtc`) - PASS, 84 s

- go 21606 at 00:24:32

```text
LOG : Lua f:798 st:105,870,181> [ZeD.QA] state #2 speed=1 paused=false player=10999,9701 grid=15 inCar=false vehicles=0
LOG : Lua f:798 st:105,870,184> [ZeD.QA] windows reset (R)
LOG : Lua f:798 st:105,870,185> [ZeD.QA] run #2 ok=true
LOG : Lua f:945 st:105,871,851> ZEDQA mtc server-list: 7 stops
LOG : Lua f:1121 st:105,873,520> ZEDQA mtc server-empty: 4 stops
LOG : Lua f:1301 st:105,875,184> ZEDQA mtc server-flash: 7 stops
LOG : Lua f:1482 st:105,876,851> ZEDQA mtc ask-blank: 11 stops
LOG : Lua f:1660 st:105,878,512> ZEDQA mtc ask-griefing: 11 stops
LOG : Lua f:1843 st:105,880,167> ZEDQA mtc ask-off: 11 stops
LOG : Lua f:2028 st:105,881,826> ZEDQA mtc ask-link-wait: 11 stops
LOG : Lua f:2210 st:105,883,483> ZEDQA mtc ask-refused: 11 stops
LOG : Lua f:2397 st:105,885,141> ZEDQA mtc mine-open: 4 stops
LOG : Lua f:2563 st:105,886,797> ZEDQA mtc mine-answered: 3 stops
LOG : Lua f:2749 st:105,888,455> ZEDQA mtc mine-closed: 3 stops
LOG : Lua f:2925 st:105,890,114> ZEDQA mtc mine-long: 43 stops
LOG : Lua f:3113 st:105,891,770> ZEDQA mtc server-fallback: 5 stops
LOG : Lua f:3298 st:105,893,443> ZEDQA mtc mine-fallback: 3 stops
LOG : Lua f:3459 st:105,895,101> ZEDQA mtc queue-link-wait: 39 stops
LOG : Lua f:3608 st:105,896,772> ZEDQA mtc queue-loading: 49 stops
LOG : Lua f:3741 st:105,898,439> ZEDQA mtc queue-open: 55 stops
LOG : Lua f:3871 st:105,900,104> ZEDQA mtc queue-answered: 52 stops
LOG : Lua f:4035 st:105,901,774> ZEDQA mtc queue-closed: 51 stops
LOG : Lua f:4176 st:105,903,429> ZEDQA mtc queue-all: 58 stops
LOG : Lua f:4331 st:105,905,088> ZEDQA mtc queue-spam-admin: 51 stops
LOG : Lua f:4464 st:105,906,740> ZEDQA mtc queue-spam-moderator: 51 stops
LOG : Lua f:4603 st:105,908,405> ZEDQA mtc queue-none: 50 stops
LOG : Lua f:4767 st:105,910,066> ZEDQA mtc queue-no-match: 50 stops
LOG : Lua f:4905 st:105,911,734> ZEDQA mtc queue-paged-1: 77 stops
LOG : Lua f:5039 st:105,913,389> ZEDQA mtc queue-paged-2: 53 stops
LOG : Lua f:5211 st:105,915,049> ZEDQA mtc queue-notes: 55 stops
LOG : Lua f:5347 st:105,916,723> ZEDQA mtc queue-frozen: 55 stops
LOG : Lua f:5508 st:105,918,388> ZEDQA mtc queue-pop-kind: 55 stops
LOG : Lua f:5654 st:105,920,060> ZEDQA mtc queue-pop-mine: 55 stops
LOG : Lua f:5784 st:105,921,717> ZEDQA mtc queue-pop-who-many: 77 stops
LOG : Lua f:5934 st:105,923,382> ZEDQA mtc queue-fallback: 49 stops
LOG : Lua f:6105 st:105,925,042> ZEDQA mtc card-open: 12 stops
LOG : Lua f:6272 st:105,926,708> ZEDQA mtc card-progress-notes: 14 stops
LOG : Lua f:6417 st:105,928,367> ZEDQA mtc card-answered: 11 stops
LOG : Lua f:6576 st:105,930,026> ZEDQA mtc card-closed: 11 stops
LOG : Lua f:6751 st:105,931,684> ZEDQA mtc card-no-kind: 11 stops
LOG : Lua f:6911 st:105,933,362> ZEDQA mtc card-spam-admin: 7 stops
LOG : Lua f:7079 st:105,935,040> ZEDQA mtc card-spam-moderator: 6 stops
LOG : Lua f:7243 st:105,936,700> ZEDQA mtc card-moderator: 11 stops
LOG : Lua f:7401 st:105,938,363> ZEDQA mtc card-confirm: 9 stops
LOG : Lua f:7568 st:105,940,026> ZEDQA mtc card-no-go: 12 stops
LOG : Lua f:7738 st:105,941,691> ZEDQA mtc card-no-stats: 12 stops
LOG : Lua f:7913 st:105,943,342> ZEDQA mtc card-frozen: 12 stops
LOG : Lua f:8063 st:105,945,013> ZEDQA mtc card-removed-game: 12 stops
LOG : Lua f:8233 st:105,946,682> ZEDQA mtc card-flash: 12 stops
LOG : Lua f:8395 st:105,948,337> ZEDQA mtc card-long: 70 stops
LOG : Lua f:8562 st:105,950,000> ZEDQA mtc card-fallback: 6 stops
LOG : Lua f:8748 st:105,951,662> ZEDQA mtc card-fallback-answered: 5 stops
LOG : Lua f:8927 st:105,953,330> ZEDQA mtc card-fallback-confirm: 6 stops
LOG : Lua f:8973 st:105,953,840> ZEDQA mtc DONE
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
