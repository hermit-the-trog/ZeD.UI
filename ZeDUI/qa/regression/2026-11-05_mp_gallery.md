# ZeD-UI regression - 2026-11-05 16:08 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 16:08:41 |
| Finished | 2026-11-05 16:11:04 (2 min 23 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_surfaces_shots.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 21201 to 21205 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1920,1080 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21204, 21205)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 2 | mp_surfaces_shots.lua | mss | **FAIL** | 49 |  | 3 Java exception(s) in the log |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21202 at 16:09:46

```text
LOG : Lua f:149 st:76,184,118> [ZeD.QA] state #1 speed=1 paused=false player=10999,9701 grid=19 inCar=false vehicles=0
LOG : Lua f:149 st:76,184,121> [ZeD.QA] windows reset (R)
LOG : Lua f:149 st:76,184,121> ZEDQA pnw pinned both windows
LOG : Lua f:149 st:76,184,122> [ZeD.QA] run #1 ok=true
LOG : Lua f:169 st:76,184,353> ZEDQA pnw DONE
```

### 2. mp_surfaces_shots.lua (`ZEDQA mss`) - FAIL, 49 s

- go 21203 at 16:09:50
- 3 Java exception(s) in the log

```text
LOG : Lua f:629 st:76,188,415> [ZeD.QA] state #2 speed=1 paused=false player=10999,9701 grid=19 inCar=false vehicles=0
LOG : Lua f:629 st:76,188,417> [ZeD.QA] windows reset (R)
LOG : Lua f:629 st:76,188,418> [ZeD.QA] run #2 ok=true
LOG : Lua f:872 st:76,192,816> ZEDQA mss shot mps_01_server_tab_top.png
LOG : Lua f:965 st:76,194,925> ZEDQA mss shot mps_02_server_tab_foot.png
LOG : Lua f:1146 st:76,197,017> ZEDQA mss shot mps_03_belt_pvp_marker_and_chat_key.png
LOG : Lua f:1434 st:76,200,097> ZEDQA mss shot mps_04_belt_chat_count.png
LOG : Lua f:1613 st:76,202,177> ZEDQA mss shot mps_05_chat_window_general.png
LOG : Lua f:1752 st:76,204,040> ZEDQA mss shot mps_06_chat_window_admin_tab.png
LOG : Lua f:1898 st:76,205,828> ZEDQA mss shot mps_07_chat_window_typing.png
LOG : Lua f:3529 st:76,220,495> ZEDQA mss shot mps_08_chat_window_dimmed.png
LOG : Lua f:3854 st:76,225,908> ZEDQA mss shot mps_09_admin_tab_top_player_picked.png
LOG : Lua f:3959 st:76,228,005> ZEDQA mss shot mps_10_admin_tab_middle.png
LOG : Lua f:4050 st:76,230,116> ZEDQA mss shot mps_11_admin_tab_foot.png
LOG : Lua f:4124 st:76,232,228> ZEDQA mss shot mps_12_game_window_options.png
ERROR: General f:4124 st:76,232,230> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(roomtones.lua:13)
    Lua(Vanilla).closeTop(roomtones.lua:13)
    Lua(Vanilla).add(roomtones.lua:59)
    Lua(Vanilla).drive(roomtones.lua:67)
LOG : Lua f:4192 st:76,234,342> ZEDQA mss shot mps_13_game_window_faction.png
ERROR: General f:4192 st:76,234,344> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(roomtones.lua:13)
    Lua(Vanilla).closeTop(roomtones.lua:13)
    Lua(Vanilla).add(roomtones.lua:59)
    Lua(Vanilla).drive(roomtones.lua:67)
LOG : Lua f:4263 st:76,236,506> ZEDQA mss shot mps_14_game_window_tickets.png
ERROR: General f:4263 st:76,236,508> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(roomtones.lua:13)
    Lua(Vanilla).closeTop(roomtones.lua:13)
    Lua(Vanilla).add(roomtones.lua:59)
    Lua(Vanilla).drive(roomtones.lua:67)
LOG : Lua f:4264 st:76,236,531> ZEDQA mss DONE (14 pictures)
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
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
