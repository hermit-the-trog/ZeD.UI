# ZeD-UI regression - 2026-11-06 00:34 - windowed (1280x720 window)

| | |
|---|---|
| Started | 2026-11-06 00:34:07 |
| Finished | 2026-11-06 00:37:03 (2 min 56 s) |
| Mode | windowed (1280x720 window) |
| Display | fullScreen=false height=720 width=1280 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_ticket_cards_large.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21620 to 21625 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x720 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; at the main menu
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1929,1118 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21624, 21625)
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

- go 21621 at 00:35:08

```text
LOG : Lua f:315 st:106,506,177> [ZeD.QA] state #1 speed=1 paused=false player=10999,9701 grid=13 inCar=false vehicles=0
LOG : Lua f:315 st:106,506,178> [ZeD.QA] windows reset (R)
LOG : Lua f:315 st:106,506,179> ZEDQA pnw pinned both windows
LOG : Lua f:315 st:106,506,179> [ZeD.QA] run #1 ok=true
LOG : Lua f:335 st:106,506,341> ZEDQA pnw DONE
```

### 2. zedqa_large_text.lua (`ZEDQA ltx`) - PASS, 1 s

- go 21622 at 00:35:12

```text
LOG : Lua f:825 st:106,510,427> [ZeD.QA] state #2 speed=1 paused=false player=10999,9701 grid=13 inCar=false vehicles=0
LOG : Lua f:825 st:106,510,428> [ZeD.QA] windows reset (R)
LOG : Lua f:825 st:106,510,432> ZEDQA ltx text size now large
LOG : Lua f:825 st:106,510,433> [ZeD.QA] run #2 ok=true
LOG : Lua f:886 st:106,510,933> ZEDQA ltx DONE
```

### 3. mp_ticket_cards.lua (`ZEDQA mtc`) - PASS, 84 s

- go 21623 at 00:35:16

```text
LOG : Lua f:1335 st:106,514,682> [ZeD.QA] state #3 speed=1 paused=false player=10999,9701 grid=13 inCar=false vehicles=0
LOG : Lua f:1335 st:106,514,686> [ZeD.QA] windows reset (R)
LOG : Lua f:1335 st:106,514,687> [ZeD.QA] run #3 ok=true
LOG : Lua f:1492 st:106,516,349> ZEDQA mtc server-list: 7 stops
LOG : Lua f:1668 st:106,518,007> ZEDQA mtc server-empty: 4 stops
LOG : Lua f:1841 st:106,519,670> ZEDQA mtc server-flash: 7 stops
LOG : Lua f:2024 st:106,521,333> ZEDQA mtc ask-blank: 11 stops
LOG : Lua f:2204 st:106,522,998> ZEDQA mtc ask-griefing: 11 stops
LOG : Lua f:2388 st:106,524,662> ZEDQA mtc ask-off: 11 stops
LOG : Lua f:2576 st:106,526,316> ZEDQA mtc ask-link-wait: 11 stops
LOG : Lua f:2765 st:106,527,982> ZEDQA mtc ask-refused: 11 stops
LOG : Lua f:2953 st:106,529,633> ZEDQA mtc mine-open: 4 stops
LOG : Lua f:3121 st:106,531,284> ZEDQA mtc mine-answered: 3 stops
LOG : Lua f:3307 st:106,532,937> ZEDQA mtc mine-closed: 3 stops
LOG : Lua f:3483 st:106,534,600> ZEDQA mtc mine-long: 43 stops
LOG : Lua f:3666 st:106,536,265> ZEDQA mtc server-fallback: 5 stops
LOG : Lua f:3854 st:106,537,933> ZEDQA mtc mine-fallback: 3 stops
LOG : Lua f:4024 st:106,539,591> ZEDQA mtc queue-link-wait: 39 stops
LOG : Lua f:4176 st:106,541,258> ZEDQA mtc queue-loading: 49 stops
LOG : Lua f:4324 st:106,542,923> ZEDQA mtc queue-open: 55 stops
LOG : Lua f:4476 st:106,544,582> ZEDQA mtc queue-answered: 52 stops
LOG : Lua f:4616 st:106,546,241> ZEDQA mtc queue-closed: 51 stops
LOG : Lua f:4775 st:106,547,997> ZEDQA mtc queue-all: 58 stops
LOG : Lua f:4934 st:106,549,662> ZEDQA mtc queue-spam-admin: 51 stops
LOG : Lua f:5076 st:106,551,316> ZEDQA mtc queue-spam-moderator: 51 stops
LOG : Lua f:5220 st:106,552,981> ZEDQA mtc queue-none: 50 stops
LOG : Lua f:5366 st:106,554,641> ZEDQA mtc queue-no-match: 50 stops
LOG : Lua f:5533 st:106,556,291> ZEDQA mtc queue-paged-1: 77 stops
LOG : Lua f:5671 st:106,557,951> ZEDQA mtc queue-paged-2: 53 stops
LOG : Lua f:5806 st:106,559,628> ZEDQA mtc queue-notes: 55 stops
LOG : Lua f:5953 st:106,561,281> ZEDQA mtc queue-frozen: 55 stops
LOG : Lua f:6106 st:106,562,948> ZEDQA mtc queue-pop-kind: 55 stops
LOG : Lua f:6263 st:106,564,616> ZEDQA mtc queue-pop-mine: 55 stops
LOG : Lua f:6428 st:106,566,281> ZEDQA mtc queue-pop-who-many: 77 stops
LOG : Lua f:6597 st:106,567,945> ZEDQA mtc queue-fallback: 49 stops
LOG : Lua f:6754 st:106,569,611> ZEDQA mtc card-open: 12 stops
LOG : Lua f:6914 st:106,571,277> ZEDQA mtc card-progress-notes: 14 stops
LOG : Lua f:7053 st:106,572,935> ZEDQA mtc card-answered: 11 stops
LOG : Lua f:7230 st:106,574,589> ZEDQA mtc card-closed: 11 stops
LOG : Lua f:7405 st:106,576,249> ZEDQA mtc card-no-kind: 11 stops
LOG : Lua f:7575 st:106,577,910> ZEDQA mtc card-spam-admin: 7 stops
LOG : Lua f:7755 st:106,579,574> ZEDQA mtc card-spam-moderator: 6 stops
LOG : Lua f:7929 st:106,581,231> ZEDQA mtc card-moderator: 11 stops
LOG : Lua f:8099 st:106,582,893> ZEDQA mtc card-confirm: 9 stops
LOG : Lua f:8268 st:106,584,564> ZEDQA mtc card-no-go: 12 stops
LOG : Lua f:8452 st:106,586,219> ZEDQA mtc card-no-stats: 12 stops
LOG : Lua f:8638 st:106,587,870> ZEDQA mtc card-frozen: 12 stops
LOG : Lua f:8803 st:106,589,535> ZEDQA mtc card-removed-game: 12 stops
LOG : Lua f:8985 st:106,591,191> ZEDQA mtc card-flash: 12 stops
LOG : Lua f:9139 st:106,592,850> ZEDQA mtc card-long: 70 stops
LOG : Lua f:9301 st:106,594,517> ZEDQA mtc card-fallback: 6 stops
LOG : Lua f:9453 st:106,596,177> ZEDQA mtc card-fallback-answered: 5 stops
LOG : Lua f:9628 st:106,597,832> ZEDQA mtc card-fallback-confirm: 6 stops
LOG : Lua f:9679 st:106,598,344> ZEDQA mtc DONE
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
