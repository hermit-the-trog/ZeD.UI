# ZeD-UI regression - 2026-11-19 15:30 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-19 15:30:25 |
| Finished | 2026-11-19 15:32:28 (2 min 2 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rt_pad_only.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 30402 to 30406 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30405, 30406)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 8 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_pad.lua | rt_pad | PASS | 21 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 8 s

- go 30402 at 15:31:28

```text
[ZeD.QA] state #1 speed=1 paused=false player=911,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 911,13039,0 to the drag strip
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. rt_kit.lua (`ZEDQA rtk`) - PASS, 1 s

- go 30403 at 15:31:39

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_pad.lua (`ZEDQA rt_pad`) - PASS, 21 s

- go 30404 at 15:31:43

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_pad start (95 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_pad PASS every pad module is loaded
ZEDQA rt_pad PASS the input mode is held on the controller
ZEDQA rt_pad PASS focus: the windows open for the pad
ZEDQA rt_pad PASS focus: the Character window has the pad
ZEDQA rt_pad PASS focus: it lands on the list's first item | charMainInv 1 Apple
ZEDQA rt_pad PASS focus: D-pad Down moves to the next item | Baseball Cap
ZEDQA rt_pad PASS focus: D-pad Up moves back | Apple
ZEDQA rt_pad PASS on screen (windows on the pad): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS grid view: R3 on the list turns its container between List and Grid | grid false to true, every item placed true
ZEDQA rt_pad PASS grid view: R3 again puts the container's view back | false
ZEDQA rt_pad PASS card: the pad is on the list
ZEDQA rt_pad PASS card: on the landed item by frame 2 on every move, never the item before, no flicker | 8 of 8
ZEDQA rt_pad PASS on screen (the pad's item card): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS left: the Character wheel opens
ZEDQA rt_pad PASS left: the wheel has its slices | 10
ZEDQA rt_pad PASS on screen (Character wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS left: Tabs is there
ZEDQA rt_pad PASS left: Tabs opens its wheel, Back last
ZEDQA rt_pad PASS left: Tabs has Health
ZEDQA rt_pad PASS left: Health opens the Character window on Health | health
ZEDQA rt_pad PASS inner wheel: Character has Tabs
ZEDQA rt_pad PASS inner wheel: Back goes up one level, then from the top closes the wheel | 2, 1, closed true
ZEDQA rt_pad PASS right: the World wheel opens
ZEDQA rt_pad PASS on screen (World wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS right: the eight slices, Tabs to Designated zones | Tabs, Map, Vehicle, Animal, Craft and build, Search, Lights and power, Designated Zones
ZEDQA rt_pad PASS right: Vehicle is live with a car in reach, else off with its reason | No vehicle in reach.
ZEDQA rt_pad PASS right: Animal is live with an animal in reach, else off with its reason | No tame animal in reach.
ZEDQA rt_pad PASS right: Tabs is there
ZEDQA rt_pad PASS right: Tabs has Loot
ZEDQA rt_pad PASS right: Loot opens the World window on Loot | loot
ZEDQA rt_pad PASS up: the Social wheel opens
ZEDQA rt_pad PASS on screen (Social wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS up: Shout is live
ZEDQA rt_pad PASS up: Shout runs the game's shout
ZEDQA rt_pad PASS down: the Here and now wheel opens
ZEDQA rt_pad PASS on screen (Here and now wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS down: Sit, Crouch, Auto walk, Game speed, Zoom, View, Help, Light | Sit, Crouch, Auto-walk, Game speed, Zoom, View, Help, Lighter
ZEDQA rt_pad PASS down: on foot, Sit, Crouch and Auto walk are not off for a vehicle
ZEDQA rt_pad SKIP down: Sit, Crouch and Auto walk off "in vehicle" in a car (on foot here; rt_vehicles has the car)
ZEDQA rt_pad PASS down: Zoom is there
ZEDQA rt_pad PASS down: Zoom has in
ZEDQA rt_pad PASS down: Zoom > in changes the zoom and the wheel closes | 1.00 to 0.75, closed true
ZEDQA rt_pad PASS select: the ZeD wheel opens
ZEDQA rt_pad PASS on screen (ZeD wheel): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS select: the slices by name, Theme to Safe mode | Base theme, Accent color, Text size, See-through, Controller highlight, UI scale, Moodles, Style, Messages, Bug report, Reset windows, ZeD setup, Safe mode
ZEDQA rt_pad PASS select: Moodles is there
ZEDQA rt_pad PASS select: Moodles lists the places
ZEDQA rt_pad PASS select: the pick moves the moodles | 2
ZEDQA rt_pad PASS reset: the pair is open
ZEDQA rt_pad PASS reset: the ZeD wheel has Reset windows
ZEDQA rt_pad PASS reset: both windows back at their places, side by side at the top | char 1134,0 777x735; world 1929,0; middle 1920, gap 9
ZEDQA rt_pad PASS on screen (the pair after Reset windows): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS highlight: the pair is open for the pad
ZEDQA rt_pad PASS highlight hand: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight hand: the style is on its wheel
ZEDQA rt_pad PASS highlight hand: the style reads back | hand
ZEDQA rt_pad PASS highlight hand: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight hand: the words keep their color
ZEDQA rt_pad PASS highlight hand: the hand stays on the screen | 1197 - 32
ZEDQA rt_pad PASS on screen (highlight hand): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS highlight corners: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight corners: the style is on its wheel
ZEDQA rt_pad PASS highlight corners: the style reads back | corners
ZEDQA rt_pad PASS highlight corners: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight corners: the words keep their color
ZEDQA rt_pad PASS on screen (highlight corners): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS highlight wash: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight wash: the style is on its wheel
ZEDQA rt_pad PASS highlight wash: the style reads back | wash
ZEDQA rt_pad PASS highlight wash: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight wash: the words turn to textOnFocus on a plain stop
ZEDQA rt_pad PASS on screen (highlight wash): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_pad PASS highlight ants: the ZeD wheel has Controller highlight
ZEDQA rt_pad PASS highlight ants: the style is on its wheel
ZEDQA rt_pad PASS highlight ants: the style reads back | ants
ZEDQA rt_pad PASS highlight ants: picked, reads back, the focused stop marked and drawn with no error | 6 marks, 6 overlay passes
ZEDQA rt_pad PASS highlight ants: the words keep their color
ZEDQA rt_pad PASS on screen (highlight ants): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS pointer: on the mouse it shows (as Display cursor has it) | true
ZEDQA rt_pad PASS pointer: back on the pad it hides | false
ZEDQA rt_pad PASS pointer: the mouse moved shows it again | true
ZEDQA rt_pad PASS pointer: a pad press on a ZeD window hides it again | false
ZEDQA rt_pad PASS mode: with no lock a key press reads the mouse and keyboard; players 2 to 4 read the controller | kbm, player 2 gamepad
ZEDQA rt_pad PASS flip: the pair is shut before the flip
ZEDQA rt_pad PASS flip: locking the controller opens the Character and World windows
ZEDQA rt_pad PASS flip: on the pad the focus marks show; back on the mouse they hide | before true
ZEDQA rt_pad PASS moodles: the pointer on a moodle brings up its balloon, fully on screen | moodle:HEAVY_LOAD 1848,1823 560x119
ZEDQA rt_pad PASS fishing: the line's tension is kept and drawn as the rod in hand | drawn true, tension 0.5
ZEDQA rt_pad PASS routes: Designated zones opens the World window on Animals | animals
ZEDQA rt_pad PASS on screen (World window on Animals): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS routes: Investigate area opens the World window on Foraging | forage
ZEDQA rt_pad PASS on screen (World window on Foraging): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_pad PASS gesture: Here and now opens with Crouch on it
ZEDQA rt_pad PASS gesture tap: the wheel opens and stays up | tap
ZEDQA rt_pad PASS gesture tap: the stick lights Crouch | 2
ZEDQA rt_pad PASS gesture tap: letting the stick go takes Crouch and the wheel closes
ZEDQA rt_pad PASS gesture trigger: a trigger closes the wheel, nothing taken
ZEDQA rt_pad PASS gesture hold: the wheel is held | hold
ZEDQA rt_pad PASS gesture hold: A takes the lit slice
ZEDQA rt_pad PASS gesture click: the wheel waits for the stick's click | click
ZEDQA rt_pad PASS gesture click: letting the stick go keeps Crouch lit
ZEDQA rt_pad PASS gesture click: R3 takes it
ZEDQA rt_pad PASS gesture toggle: the wheel opens in Toggle mode | toggle
ZEDQA rt_pad PASS gesture toggle: D-pad Up lights the top slice, Right walks to the next | 1 then 2
ZEDQA rt_pad PASS gesture toggle: A takes the lit slice
ZEDQA rt_pad PASS gesture bumper: LB tapped on a wheel closes it and opens the pair, the pad on the Character window | wheel false, focus ZeD_Window
ZEDQA rt_pad PASS chord: RB + R3 is on Here and now > Crouch
ZEDQA rt_pad PASS chord: no window has the pad (the chord is the world's)
ZEDQA rt_pad PASS chord: the press is taken as RB + R3 | RB+R3
ZEDQA rt_pad PASS chord: the press is the chord's, so the game's own press never runs | true
ZEDQA rt_pad PASS chord: the character crouches
ZEDQA rt_pad PASS chord: again, and it stands as it was
ZEDQA rt_pad PASS chord: the Character window is open for the window checks
ZEDQA rt_pad PASS chord: with a window holding the pad the chord does nothing | false
ZEDQA rt_pad PASS D-pad on a focused window: no wheel opens, the window's focus moves | 1 to 2
ZEDQA rt_pad PASS chord: on a slice that is off it does nothing and says why | No vehicle in reach.
ZEDQA rt_pad PASS chord: on a slice that is gone it says so | No QA gone on you.
ZEDQA rt_pad PASS put back: the switch is on
ZEDQA rt_pad PASS put back: a bottle of water in a bag
ZEDQA rt_pad PASS put back: after the drink the bottle is back in the bag | Bag_Schoolbag
ZEDQA rt_pad PASS map: Here and now has Help
ZEDQA rt_pad PASS map: Help has Controller map
ZEDQA rt_pad PASS map: the Controller map opens
ZEDQA rt_pad PASS map: its twelve rows are drawn | 12 of 12
ZEDQA rt_pad PASS map: it draws the pad from its textures | k 4, xbox
ZEDQA rt_pad PASS map: the pad fits the window's width
ZEDQA rt_pad PASS on screen (Controller map): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_pad PASS put back: the pad is the game's again
ZEDQA rt_pad PASS put back: the stand-ins are gone
ZEDQA rt_pad PASS put back: the controller highlight | hand
ZEDQA rt_pad PASS put back: the moodles' place
ZEDQA rt_pad put back: the input mode lock is nil again; the mode reads gamepad
ZEDQA rt_pad end: 130 pass, 0 fail, 1 skipped
ZEDQA rt_pad VERDICT PASS 130
ZEDQA rt_pad DONE
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
