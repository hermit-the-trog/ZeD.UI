# ZeD-UI regression - 2026-11-05 16:47 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-05 16:47:32 |
| Finished | 2026-11-05 16:49:36 (2 min 3 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_nosafety.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 21275 to 21279 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1920,1080 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21278, 21279)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 2 | mp_srvtab.lua | mst | WARN | 30 |  | 1 ERR line(s) |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21276 at 16:48:39

```text
LOG : Lua f:112 st:78,517,721> [ZeD.QA] state #1 speed=1 paused=false player=10999,9701 grid=19 inCar=false vehicles=0
LOG : Lua f:112 st:78,517,723> [ZeD.QA] windows reset (R)
LOG : Lua f:112 st:78,517,723> ZEDQA pnw pinned both windows
LOG : Lua f:112 st:78,517,724> [ZeD.QA] run #1 ok=true
LOG : Lua f:132 st:78,517,934> ZEDQA pnw DONE
```

### 2. mp_srvtab.lua (`ZEDQA mst`) - WARN, 30 s

- go 21277 at 16:48:44
- 1 ERR line(s)

```text
LOG : Lua f:592 st:78,521,960> [ZeD.QA] state #2 speed=1 paused=false player=10999,9701 grid=19 inCar=false vehicles=0
LOG : Lua f:592 st:78,521,962> [ZeD.QA] windows reset (R)
LOG : Lua f:592 st:78,521,963> [ZeD.QA] run #2 ok=true
LOG : Lua f:809 st:78,524,774> ZEDQA mst session mp mp_3840x2160: tabs [loot, equip, health, thermal, identity, journal, skills, server, radio]
LOG : Lua f:809 st:78,524,774> ZEDQA mst PASS server: the Server tab on the strip
LOG : Lua f:809 st:78,524,775> ZEDQA mst belt PvP marker words: nil
LOG : Lua f:809 st:78,524,775> ZEDQA mst ZeD_CharacterWindow.openTab exists (the belt marker's click uses it): true
LOG : Lua f:1023 st:78,527,789> ZEDQA mst tab open server; buttons [options, faction, tickets]; players 1
LOG : Lua f:1023 st:78,527,790> ZEDQA mst player zedqa (zedqa)
LOG : Lua f:1023 st:78,527,791> ZEDQA mst pvp state: nil (safety system off?)
LOG : Lua f:1086 st:78,529,603> ZEDQA mst options -> the game's window open true
LOG : Lua f:1204 st:78,531,409> ZEDQA mst faction -> the game's window open true
LOG : Lua f:1243 st:78,532,019> ZEDQA mst safehouse: no button on the tab
LOG : Lua f:1321 st:78,533,230> ZEDQA mst safehouse -> the game's window open false
LOG : Lua f:1444 st:78,535,052> ZEDQA mst tickets -> the game's window open true
LOG : Lua f:1482 st:78,535,562> ZEDQA mst pvp: no button (safety system off on the server?)
LOG : Lua f:1677 st:78,538,063> ZEDQA mst pvp +2s: on nil, left nil; belt marker 'nil'
LOG : Lua f:1819 st:78,540,572> ZEDQA mst pvp +5s: on nil, left nil; belt marker 'nil'
LOG : Lua f:2015 st:78,543,080> ZEDQA mst pvp +7s: on nil, left nil; belt marker 'nil'
LOG : Lua f:2216 st:78,545,585> ZEDQA mst pvp +10s: on nil, left nil; belt marker 'nil'
LOG : Lua f:2421 st:78,548,086> ZEDQA mst pvp +12s: on nil, left nil; belt marker 'nil'
LOG : Lua f:2647 st:78,550,595> ZEDQA mst pvp +15s: on nil, left nil; belt marker 'nil'
LOG : Lua f:2692 st:78,551,097> ZEDQA mst FAIL pvp flipped: was nil, now nil
LOG : Lua f:2716 st:78,551,402> ZEDQA mst DONE
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
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
