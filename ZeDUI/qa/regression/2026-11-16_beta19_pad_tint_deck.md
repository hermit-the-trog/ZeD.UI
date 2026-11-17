# ZeD-UI regression - 2026-11-16 22:43 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-16 22:43:08 |
| Finished | 2026-11-16 22:45:55 (2 min 47 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b19.txt (3 scripts) |
| Result | **1/3 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 28024 to 28028 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1920,1080) of 3840x2160; pointer parked at (3836,2156)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28027, 28028)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_b19_pad.lua | b19p | WARN | 57 | zqa_b19p_228e_safe_ask.png, zqa_b19p_228i_msg_box.png, zqa_b19p_228i_msg_menu.png, zqa_b19p_228i_reader_box.png, zqa_b19p_228g_keyboard.png, zqa_b19p_228m_identity.png, zqa_b19p_228p_window_menu.png, zqa_b19p_228p_controller_map.png, zqa_b19p_228p_hidden.png | 2 ERR line(s) |
| 3 | zedqa_b19_tint.lua | b19t | **FAIL** | 14 | zqa_b19t_off_dark.png, zqa_b19t_dark_on.png, zqa_b19t_dark_hover.png, zqa_b19t_light_on.png, zqa_b19t_light_hover.png, zqa_b19t_hicon_on.png, zqa_b19t_hicon_hover.png | 1 Java exception(s) in the log |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28024 at 22:44:13

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1022,0 888x840 rolled false pinned true/true
ZEDQA pre layout world 1930,0 888x840 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_b19_pad.lua (`ZEDQA b19p`) - WARN, 57 s

- go 28025 at 22:44:18
- 2 ERR line(s)
- screenshots: zqa_b19p_228e_safe_ask.png, zqa_b19p_228i_msg_box.png, zqa_b19p_228i_msg_menu.png, zqa_b19p_228i_reader_box.png, zqa_b19p_228g_keyboard.png, zqa_b19p_228m_identity.png, zqa_b19p_228p_window_menu.png, zqa_b19p_228p_controller_map.png, zqa_b19p_228p_hidden.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b19p start
[ZeD.QA] run #2 ok=true
ZEDQA b19p start: pad bound false, at 925,13040
ZEDQA b19p PASS 218: the door prompt wrap is on
ZEDQA b19p not run: 218 door (none within 14 tiles)
ZEDQA b19p not run: 218 window (none within 14 tiles)
ZEDQA b19p FAIL 228e safe mode: the question takes the pad (ZeD_Prompt)
ZEDQA b19p PASS 228e safe mode: it remembers the ZeD window (ZeD_Window)
ZEDQA b19p PASS 228e safe mode: No gives the pad back to the Character window (ZeD_Window)
ZEDQA b19p PASS 228e safe mode: No leaves safe mode off
ZEDQA b19p not run: 228e Better Folders' name prompt (its support code is not loaded without the mod)
ZEDQA b19p PASS 228f Messages: opened, it holds the pad
ZEDQA b19p PASS 228i Messages: Up from the top row reaches the window box (zone box)
ZEDQA b19p PASS 228i Messages: A on the box opens the window menu
ZEDQA b19p PASS 228i Messages: Down from the box goes back into the window (zone list)
ZEDQA b19p PASS 228n Messages: Up from the cards panel (not grabbed) goes to the window box (zone box)
ZEDQA b19p PASS 228f Messages: closed, the pad goes back to the ZeD window (ZeD_Window)
ZEDQA b19p PASS 228f Reader: opened, it holds the pad
ZEDQA b19p PASS 228i Reader: Up at the top of the page reaches the window box
ZEDQA b19p PASS 228i Reader: A on the box opens the window menu
ZEDQA b19p PASS 228i Reader: Down comes back to the page
ZEDQA b19p PASS 228f Reader: closed, the pad goes back to the ZeD window (ZeD_Window)
ZEDQA b19p not run: 228f siren and car radio (need a police car / a seat in a car with a radio: the director's hands)
ZEDQA b19p PASS 228g keyboard: put away with nothing named, the pad is not left on the bare field (ZeD_Window)
ZEDQA b19p PASS 228g keyboard: it goes to the focused ZeD window, else the game (ZeD_Window, focused ZeD_Window)
ZEDQA b19p 228m parts: hair | beard | makeup
ZEDQA b19p PASS 228m: Left at hair stays put
ZEDQA b19p PASS 228m: Right at makeup stays put
ZEDQA b19p PASS 228m: Up and Down leave the switch
ZEDQA b19p PASS 228m: Right inside the switch still moves (beard)
ZEDQA b19p 228p menu with a pad: Theme | Accent | Text size | See-through | Controller highlight | Reset this window | Reset both windows | Save position | Go to saved position | Bug report | Controller map | Hide the interface | ZeD setup...
ZEDQA b19p PASS 228p: with a pad the window menu has Controller map and Hide interface
ZEDQA b19p PASS 228p: without a pad, Hide interface only (no Controller map)
ZEDQA b19p PASS 228p: they sit after Bug report (10, 12)
ZEDQA b19p PASS 228p: Hide interface hides the windows
ZEDQA b19p PASS 228p: the interface comes back (the game's toggle)
ZEDQA b19p 217 tap 1: Character rolled false
ZEDQA b19p 217 tap 2: Character rolled false
ZEDQA b19p 217 tap 3: Character rolled false
ZEDQA b19p 217 tap 4: Character rolled false
ZEDQA b19p 217 tap 5: Character rolled false
ZEDQA b19p 217 tap 6: Character rolled false
ZEDQA b19p FAIL 217: each Y-tap hide printed a [ZeD.LagClose] line (0)
ZEDQA b19p 2 failed
ZEDQA b19p DONE
```

### 3. zedqa_b19_tint.lua (`ZEDQA b19t`) - FAIL, 14 s

- go 28026 at 22:45:18
- 1 Java exception(s) in the log
- screenshots: zqa_b19t_off_dark.png, zqa_b19t_dark_on.png, zqa_b19t_dark_hover.png, zqa_b19t_light_on.png, zqa_b19t_light_hover.png, zqa_b19t_hicon_on.png, zqa_b19t_hicon_hover.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b19t start
[ZeD.QA] run #3 ok=true
ERROR: General f:5759> Lua(Vanilla).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).pcall(spawnpoints.lua:27)
    Lua(Vanilla).step(spawnpoints.lua:27)
    Lua(Vanilla).tick(spawnpoints.lua:100)
ZEDQA b19t as found: 1, default nil
ZEDQA b19t PASS the choice is off as found (1)
ZEDQA b19t PASS off: an axe tile has no tint
ZEDQA b19t shot zqa_b19t_off_dark
ZEDQA b19t PASS dark: on, the axe tile has a tint
ZEDQA b19t PASS dark: the axe tile's lightness 0.17 near 0.17 (r 0.22 g 0.13 b 0.12)
ZEDQA b19t PASS dark: no texture, no tint
ZEDQA b19t shot zqa_b19t_dark_on
ZEDQA b19t shot zqa_b19t_dark_hover
ZEDQA b19t PASS light: on, the axe tile has a tint
ZEDQA b19t PASS light: the axe tile's lightness 0.74 near 0.74 (r 0.82 g 0.68 b 0.66)
ZEDQA b19t PASS light: no texture, no tint
ZEDQA b19t shot zqa_b19t_light_on
ZEDQA b19t shot zqa_b19t_light_hover
ZEDQA b19t PASS hicon: on, the axe tile has a tint
ZEDQA b19t PASS hicon: the axe tile's lightness 0.13 near 0.13 (r 0.18 g 0.09 b 0.08)
ZEDQA b19t PASS hicon: no texture, no tint
ZEDQA b19t shot zqa_b19t_hicon_on
ZEDQA b19t shot zqa_b19t_hicon_hover
ZEDQA b19t put back: choice 1, theme light
ZEDQA b19t all checks passed
ZEDQA b19t DONE
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
