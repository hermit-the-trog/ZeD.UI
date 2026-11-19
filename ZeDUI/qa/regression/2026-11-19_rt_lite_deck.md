# ZeD-UI regression - 2026-11-19 13:31 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-19 13:31:45 |
| Finished | 2026-11-19 13:33:29 (1 min 44 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rt_lite_only.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 30324 to 30328 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800; pointer parked at (2565,1514)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30327, 30328)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_lite.lua | rt_lite | PASS | 7 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 30324 at 13:32:50

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 360,0 276x315 rolled false pinned true/true
ZEDQA pre layout world 644,0 276x315 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. rt_kit.lua (`ZEDQA rtk`) - PASS, 1 s

- go 30325 at 13:32:55

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 1280x800
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_lite.lua (`ZEDQA rt_lite`) - PASS, 7 s

- go 30326 at 13:33:00

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_lite start (39 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_lite PASS Lite: ZeD's settings, molecules and options are loaded
ZEDQA rt_lite as found: Style 1 (1 Full, 2 Lite), additions preset 4
ZEDQA rt_lite PASS Style Lite: Options opens from the pause menu
ZEDQA rt_lite PASS Style Lite: ZeD setup has the Style row
ZEDQA rt_lite PASS Style Lite: ZeD setup leaves out the Additions and Chords groups | additions false, chords false/0
ZEDQA rt_lite PASS Style Lite: none of the eight retired switches is in ZeD setup |
ZEDQA rt_lite PASS Style Lite: the Style row stays in ZeD setup
ZEDQA rt_lite PASS on screen (ZeD setup in Lite): every ZeD window and pop-up inside 1280x800 | 0 seen
ZEDQA rt_lite PASS Style Lite: the pause menu shuts
ZEDQA rt_lite PASS Style Lite: ZeD.Settings.lite() is true once applied | 2
ZEDQA rt_lite PASS Style Lite: the forms' helpers all answer Lite (devices, watch, guide, mods, identity, belt) | 6 helpers
ZEDQA rt_lite PASS Style Lite: the additions are on the Vanilla preset | preset 1, 15 additions
ZEDQA rt_lite PASS Lite buttons: ZeD.Molecules.lite() is true
ZEDQA rt_lite PASS Lite buttons: Cancel, No and a danger button are the bad kind | Cancel bad, No bad, danger bad
ZEDQA rt_lite PASS Lite buttons: a primary or default answer is the good kind, a plain button neither | good / nil
ZEDQA rt_lite PASS Lite buttons: a grayed button has no kind
ZEDQA rt_lite PASS Lite buttons: the good color is the game's getGoodHighlitedColor | rgb 0 255 0 / rgb 0 255 0
ZEDQA rt_lite PASS Lite buttons: the bad color is the game's getBadHighlitedColor | rgb 255 0 0 / rgb 255 0 0
ZEDQA rt_lite PASS Lite watch: off the belt, in the corner (W.beltMode() false) | lite true, belt false
ZEDQA rt_lite PASS Lite watch: its keys are the speed row speed0 to speed3, then the face and the alarm line | speed0 speed1 speed2 speed3 alarmline fold
ZEDQA rt_lite PASS on screen (Lite: the watch in its corner): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_lite PASS Lite buttons: a primary button is drawn filled with the good color under a two-hairline line | x1: 2 lines, 0 double
ZEDQA rt_lite PASS Lite dashboard: every car gets the Dash Elite (a pickup, a police car) | dashelite, dashelite
ZEDQA rt_lite PASS Lite dashboard: in the black cabin | v_black
ZEDQA rt_lite SKIP Lite watch: the big time is in the accent color (the big time is not drawn through drawText (another drawing path))
ZEDQA rt_lite PASS Lite watch fold: the face has its fold hit and a click lands on it
ZEDQA rt_lite PASS Lite watch fold: a click on the face folds it to one line (shorter, the strip is one fold hit) | thin true, h 18.4921875 < 78.4765625, hits fold
ZEDQA rt_lite PASS Lite watch fold: the strip's time is in the accent color | 11:19
ZEDQA rt_lite PASS on screen (Lite: the folded watch): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_lite PASS Lite watch fold: a click on the strip unfolds it to its full height | thin false, h 78.4765625
ZEDQA rt_lite PASS Lite watch: the alarm line has its hit
ZEDQA rt_lite PASS Lite watch: a click on the alarm line opens the alarm setting | true
ZEDQA rt_lite PASS Lite device faces: no preset keys, memory key or dial lamp on any radio's plain controls | 17 readings, 0 with them:
ZEDQA rt_lite PASS Lite device faces: the memory key and the lamp are on the Lite drop list
ZEDQA rt_lite PASS Lite windows: the inventory has its List or Grid key
ZEDQA rt_lite PASS Lite windows: List or Grid is drawn as its word | List view: 66.47265625 wide, the word's button 66.47265625
ZEDQA rt_lite PASS Lite windows: Filter is drawn as its word | 50.6171875 wide, the word's button 50.6171875
ZEDQA rt_lite PASS Lite windows: no Same type or Same type nearby button | xfer
ZEDQA rt_lite PASS Lite windows: the container buttons' trim keeps Transfer all only | 1 left
ZEDQA rt_lite PASS Lite windows: the pencil's row is in the Character window's list
ZEDQA rt_lite PASS Lite windows: a click on the row opens its item card
ZEDQA rt_lite PASS Lite windows: the item card has no marks strip | nil
ZEDQA rt_lite PASS on screen (Lite: both windows and the item card): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_lite PASS Lite windows: a second click closes the card
ZEDQA rt_lite PASS Style Full: Options opens from the pause menu
ZEDQA rt_lite PASS Style Full: ZeD setup has the Style row
ZEDQA rt_lite PASS Style Full: ZeD setup has the Additions and Chords groups again | additions true, chords true
ZEDQA rt_lite PASS Style Full: the retired switches stay out of ZeD setup |
ZEDQA rt_lite PASS on screen (ZeD setup in Full): every ZeD window and pop-up inside 1280x800 | 0 seen
ZEDQA rt_lite PASS Style Full: the pause menu shuts
ZEDQA rt_lite PASS Style Full: ZeD.Settings.lite() is false once applied | 1
ZEDQA rt_lite PASS Style Full: the forms' helpers all answer Full | 6 helpers
ZEDQA rt_lite PASS Full buttons: ZeD.Molecules.lite() is false
ZEDQA rt_lite PASS Full watch: its place is the Watch option's again | belt false, option 2
ZEDQA rt_lite PASS Full dashboard: a pickup and a police car have their own dash again | d6, police
ZEDQA rt_lite PASS Full device faces: the radios' preset keys, memory key and lamp come back | 12 readings with them
ZEDQA rt_lite PASS Lite device faces: every plate's power row stays in Lite |
ZEDQA rt_lite PASS Full windows: List or Grid is the square picture key again | 20x20
ZEDQA rt_lite PASS Full windows: Same type and Same type nearby come back | xfer same near
ZEDQA rt_lite PASS Full windows: the item card has its marks strip again | 37.1328125
ZEDQA rt_lite PASS Map always light: in Dark, Always light reads the Light map | light
ZEDQA rt_lite PASS Map always light: in Dark, Follows the theme reads the Dark map | dark
ZEDQA rt_lite PASS Map always light: High contrast keeps its own map | hicon
ZEDQA rt_lite PASS Map always light: the theme and the option put back | light
ZEDQA rt_lite PASS put back: every ZeD option as found, Style among them | Style 1
ZEDQA rt_lite PASS put back: ModOptions.ini line for line | 65 lines, 65 before
ZEDQA rt_lite PASS put back: the windows open or shut as found
ZEDQA rt_lite PASS Lite and Full drew with no Lua error | 0 new
ZEDQA rt_lite end: 66 pass, 0 fail, 1 skipped
ZEDQA rt_lite VERDICT PASS 66
ZEDQA rt_lite DONE
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
