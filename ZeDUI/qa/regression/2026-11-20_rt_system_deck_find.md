# ZeD-UI regression - 2026-11-20 06:48 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-20 06:48:56 |
| Finished | 2026-11-20 06:53:11 (4 min 15 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rt_system_only.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 30820 to 30824 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800; pointer parked at (2565,1514)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30823, 30824)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_system.lua | rt_sys | PASS | 156 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 30820 at 06:50:00

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

- go 30821 at 06:50:05

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 1280x800
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_system.lua (`ZEDQA rt_sys`) - PASS, 156 s

- go 30822 at 06:50:09

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_sys start (170 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_sys PASS ZeD's settings, safe mode, main menu and scale modules are loaded
ZEDQA rt_sys PASS a changed setting is written to ModOptions.ini | file 2, want 2
ZEDQA rt_sys PASS the saved setting comes back when the game reads ModOptions.ini | value 2
ZEDQA rt_sys PASS the setting is put back, in memory and in the file | value 1, file 1
ZEDQA rt_sys PASS ModOptions.ini is back line for line | 65 lines, 65 before
ZEDQA rt_sys PASS the pause menu opens (ZeD's pause window)
ZEDQA rt_sys PASS Options opens from the pause menu (ZeD's window)
ZEDQA rt_sys PASS every Options group's page was opened | 9 of 9
ZEDQA rt_sys PASS ZeD setup opens with its groups and rows | 7 groups, 55 rows
ZEDQA rt_sys PASS Options, ZeD setup: the page opens, the window on screen | 55 rows
ZEDQA rt_sys PASS Options, Display: the page opens, the window on screen | 7 rows
ZEDQA rt_sys PASS Options, Graphics: the page opens, the window on screen | 30 rows
ZEDQA rt_sys PASS Options, Audio: the page opens, the window on screen | 19 rows
ZEDQA rt_sys PASS Options, Controls: the page opens, the window on screen | 116 rows
ZEDQA rt_sys PASS Options, Gameplay: the page opens, the window on screen | 35 rows
ZEDQA rt_sys PASS Options, Interface: the page opens, the window on screen | 23 rows
ZEDQA rt_sys PASS Options, Accessibility: the page opens, the window on screen | 8 rows
ZEDQA rt_sys PASS Options, Mods: the page opens, the window on screen | 65 rows
ZEDQA rt_sys PASS Options has ZeD setup
ZEDQA rt_sys PASS the Options pages drew with no Lua error | 0 new
ZEDQA rt_sys PASS Back leaves Options for the pause menu | pause
ZEDQA rt_sys PASS the pause menu shuts again
ZEDQA rt_sys PASS the Select wheel's ZeD setup row: the pause screen, then Options on its first page | view options, page 1, pause up true
ZEDQA rt_sys PASS on screen (ZeD setup from the Select wheel): every ZeD window and pop-up inside 1280x800 | 0 seen
ZEDQA rt_sys PASS the pause menu shuts after the wheel's ZeD setup
ZEDQA rt_sys PASS Options: the game's settings that do nothing with ZeD on (Inventory font and the rest) are not listed | none listed
ZEDQA rt_sys PASS Options: the game's Dyslexic font row says where it still works | UI_ZeD_Options_OnlyDyslexic
ZEDQA rt_sys PASS ZeD setup: no copies of the game's settings; Font size is in its own group | 0 copies, Font size row true
ZEDQA rt_sys PASS Options, Find "scale": only the matching rows, UI scale among them | 1 of 310 rows, UI scale true
ZEDQA rt_sys PASS Options, Find cleared: ZeD setup's rows come back | 47 rows, 47 before
ZEDQA rt_sys PASS ZeD setup: every group has its heading and a named row for each of its options | 7 groups, 36 rows
ZEDQA rt_sys PASS ZeD setup: each of the Wheels row's four ways (Hold and flick, Tap and flick, Tap and click, Toggle) is read live | 4 ways
ZEDQA rt_sys PASS ZeD setup: each Wheel dead zone step is read live | 9 steps
ZEDQA rt_sys PASS Options: Back with a change pending asks first, and the window stays | changed true, confirm back, view options
ZEDQA rt_sys PASS Options: Discard puts every changed ZeD setup control back on its stored pick |
ZEDQA rt_sys PASS ZeD setup, Additions: picking Vanilla Plus sets every addition to the preset's | preset 2
ZEDQA rt_sys PASS ZeD setup, Additions: one addition changed by hand makes the preset read Custom | preset 4
ZEDQA rt_sys PASS Options: Discard puts the preset and the additions back |
ZEDQA rt_sys PASS ZeD setup: a base theme picked without Apply shows at once (the live preview) | dark, want dark
ZEDQA rt_sys PASS Discard puts back the live preview: the stored base theme is on screen again | light, want light |
ZEDQA rt_sys PASS Restock needs Loadouts: with Loadouts Off its row takes no change, with Loadouts On it does | item 2, Loadouts Off 2, Loadouts On 1
ZEDQA rt_sys PASS Options: Discard puts Loadouts and Restock back |
ZEDQA rt_sys PASS ZeD setup, Defaults: every ZeD option's control is on the item it starts on | 33 rows
ZEDQA rt_sys PASS ZeD setup, Defaults: afterwards nothing is off its default (the button greys out)
ZEDQA rt_sys PASS Options: Discard after Defaults puts every control and the look back | | light / teal
ZEDQA rt_sys PASS Back leaves Options with nothing pending | pause
ZEDQA rt_sys PASS after ZeD setup's controls the scale is the run's own | root 0.75
ZEDQA rt_sys PASS on screen (the windows after ZeD setup's controls): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS UI scale UI_ZeD_Settings_ScaleAuto: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS on screen (UI scale UI_ZeD_Settings_ScaleAuto): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys SKIP UI scale 0.5x drawn at 0.5x (retired in the beta: ZeD setup's slider dims it and the wheel leaves it out)
ZEDQA rt_sys PASS UI scale 0.5x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.5x set by hand: drawn at the floor 0.75x, the saved pick kept | root 0.75, ZeD.T.root 0.75, item 2
ZEDQA rt_sys PASS on screen (UI scale 0.5x): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS UI scale 0.75x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.75x: drawn at that scale (ZeD.T.root) | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 0.75x): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys SKIP UI scale 1x drawn at 1x (not offered on this 1280x800 screen: over its cap of 0.75x)
ZEDQA rt_sys PASS UI scale 1x: dimmed, and ZeD setup's help line says it is too big | Too big for this screen: 1x and up.
ZEDQA rt_sys PASS UI scale 1x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 1x set by hand: drawn at this screen's cap 0.75x | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 1x): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys SKIP UI scale 1.25x drawn at 1.25x (not offered on this 1280x800 screen: over its cap of 0.75x)
ZEDQA rt_sys PASS UI scale 1.25x: dimmed, and ZeD setup's help line says it is too big | Too big for this screen: 1x and up.
ZEDQA rt_sys PASS UI scale 1.25x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 1.25x set by hand: drawn at this screen's cap 0.75x | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 1.25x): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys SKIP UI scale 1.5x drawn at 1.5x (not offered on this 1280x800 screen: over its cap of 0.75x)
ZEDQA rt_sys PASS UI scale 1.5x: dimmed, and ZeD setup's help line says it is too big | Too big for this screen: 1x and up.
ZEDQA rt_sys PASS UI scale 1.5x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 1.5x set by hand: drawn at this screen's cap 0.75x | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 1.5x): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys SKIP UI scale 1.75x drawn at 1.75x (not offered on this 1280x800 screen: over its cap of 0.75x)
ZEDQA rt_sys PASS UI scale 1.75x: dimmed, and ZeD setup's help line says it is too big | Too big for this screen: 1x and up.
ZEDQA rt_sys PASS UI scale 1.75x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 1.75x set by hand: drawn at this screen's cap 0.75x | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 1.75x): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys SKIP UI scale 2x drawn at 2x (not offered on this 1280x800 screen: over its cap of 0.75x)
ZEDQA rt_sys PASS UI scale 2x: dimmed, and ZeD setup's help line says it is too big | Too big for this screen: 1x and up.
ZEDQA rt_sys PASS UI scale 2x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 2x set by hand: drawn at this screen's cap 0.75x | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 2x): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS UI scale cap: this screen offers up to 0.75x and ZeD setup names the steps too big | 1x 1.25x 1.5x 1.75x 2x | Too big for this screen: 1x and up.
ZEDQA rt_sys PASS ZeD text follows the root scale: the body font's zoom is the root times its size at every step | 8 steps, zoom 0.15234375 to 0.15234375
ZEDQA rt_sys PASS UI scale put back on the run's own step | option 1, root 0.75
ZEDQA layout rt_sys scale put back
ZEDQA rt_sys PASS on screen (the windows back after the scale steps): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS theme dark: the window box's Theme pick applies to ZeD's table and is saved as item 1 | dark, option 1
ZEDQA rt_sys PASS theme dark: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme dark: See-through is the player's pick | surfaceAlpha 0.9, want 0.9
ZEDQA rt_sys PASS on screen (theme dark): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS theme light: the window box's Theme pick applies to ZeD's table and is saved as item 2 | light, option 2
ZEDQA rt_sys PASS theme light: the accent is its light variant | rgb 26 102 85, want rgb 26 102 85
ZEDQA rt_sys PASS theme light: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme light): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS theme hicon: the window box's Theme pick applies to ZeD's table and is saved as item 3 | hicon, option 3
ZEDQA rt_sys PASS theme hicon: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme hicon: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme hicon): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS accent red: the window box's Accent pick gives its light color and is saved as item 1 | red, rgb 122 26 26, want rgb 122 26 26, option 1
ZEDQA rt_sys PASS accent orange: the window box's Accent pick gives its light color and is saved as item 2 | orange, rgb 122 80 16, want rgb 122 80 16, option 2
ZEDQA rt_sys PASS accent yellow: the window box's Accent pick gives its light color and is saved as item 3 | yellow, rgb 107 95 10, want rgb 107 95 10, option 3
ZEDQA rt_sys PASS accent green: the window box's Accent pick gives its light color and is saved as item 4 | green, rgb 18 85 24, want rgb 18 85 24, option 4
ZEDQA rt_sys PASS accent blue: the window box's Accent pick gives its light color and is saved as item 5 | blue, rgb 26 68 119, want rgb 26 68 119, option 5
ZEDQA rt_sys PASS accent teal: the window box's Accent pick gives its light color and is saved as item 6 | teal, rgb 26 102 85, want rgb 26 102 85, option 6
ZEDQA rt_sys PASS accent purple: the window box's Accent pick gives its light color and is saved as item 7 | purple, rgb 68 24 136, want rgb 68 24 136, option 7
ZEDQA rt_sys PASS accent pink: the window box's Accent pick gives its light color and is saved as item 8 | pink, rgb 136 34 68, want rgb 136 34 68, option 8
ZEDQA rt_sys PASS accent mono: the window box's Accent pick gives its light color and is saved as item 9 | mono, rgb 58 58 58, want rgb 58 58 58, option 9
ZEDQA rt_sys PASS text size small: the window box's Text size pick sets the scale and the sort font, saved as item 1 | scale 0.75, want 0.75, option 1
ZEDQA rt_sys PASS on screen (text size small): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS text size large: the window box's Text size pick sets the scale and the sort font, saved as item 2 | scale 0.8624999999999999, want 0.8624999999999999, option 2
ZEDQA rt_sys PASS on screen (text size large): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS the run's own theme, accent and text size are back | light / teal / small
ZEDQA rt_sys PASS Status colors Color blind: good, warning and bad come from the color blind set | light, rgb 1 78 142, want rgb 1 78 142
ZEDQA rt_sys PASS Status colors Standard: good, warning and bad are the base theme's own | rgb 42 85 17, want rgb 42 85 17
ZEDQA rt_sys PASS split view per-player theme: player 2's pick is in player 2's table only (a stand-in player 2) | dark / light, shared light
ZEDQA rt_sys PASS the Character window's own accent: its window box's pick sets it and saves it | purple, option 7
ZEDQA rt_sys PASS the World window's own accent: its window box's pick sets it and saves it | green, option 4
ZEDQA rt_sys PASS a window's own accent leaves the interface's accent alone | teal
ZEDQA rt_sys PASS the windows' own accents are kept over a close and reopen | purple / green
ZEDQA rt_sys PASS the Character window's "Same as Accent color" follows the interface's accent again | nil, option 10
ZEDQA rt_sys PASS See-through 60: the window box's pick draws the windows at 0.6 in Dark and is saved | surfaceAlpha 0.6
ZEDQA rt_sys PASS one see-through layer per window: the windows and their bands draw at 60 with no guarded fault and no Lua error | 0 faults, 0 new errors
ZEDQA rt_sys PASS on screen (the windows at 60 see-through): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS See-through and the theme put back | 2, light
ZEDQA rt_sys PASS Solid while in use: a window in use is always solid, with the saved option Off or On | true, true
ZEDQA rt_sys PASS Solid while in use: the window box's See-through has no row for it | 5 rows
ZEDQA rt_sys PASS Low-health pixel: it holds lit (solid red) at every moment, with the saved option Off or On | 0 and 0 of 41 moments dark
ZEDQA rt_sys PASS Low-health pixel option put back | 2
ZEDQA rt_sys PASS Item-colored grid tiles: on in Full, off in Lite | Full true, Lite false
ZEDQA rt_sys PASS Style put back | 1
ZEDQA rt_sys PASS Item-colored grid tiles: the item colors are loaded (Acorn) | 8806442
ZEDQA rt_sys PASS Controller highlight hand: the window box's pick is read and saved | hand, option 1
ZEDQA rt_sys PASS Controller highlight corners: the window box's pick is read and saved | corners, option 2
ZEDQA rt_sys PASS Controller highlight wash: the window box's pick is read and saved | wash, option 3
ZEDQA rt_sys PASS Controller highlight ants: the window box's pick is read and saved | ants, option 4
ZEDQA rt_sys PASS the controller highlights drew with no Lua error | 0 new
ZEDQA rt_sys PASS Controller highlight put back | hand
ZEDQA rt_sys PASS Lite or Full forms: each form's getter follows Style at once (belt, devices, watch, guide, mods, identity; the dash has no plain form) | 6 forms
ZEDQA rt_sys PASS UI sounds: Off plays no click, Full plays it (a sound id) | Off nil, Full 4050176
ZEDQA rt_sys PASS Button glyph set: item 3 reads the PlayStation set, item 1 Auto | ps / auto
ZEDQA rt_sys PASS Test language On: within half a second a ZeD phrase reads stretched, in brackets | 433 ms, 15 letters, plain 9
ZEDQA rt_sys PASS Test language Off: the phrase is plain again | Safe mode
ZEDQA rt_sys PASS the inventory key: the Character and World windows close together and open together, the game's page hidden | open true, shut true, game's page false, open again true
ZEDQA rt_sys safe mode baseline: on false | pair shut false | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS safe mode: ZeD runs to start with (its windows, its hotbar)
ZEDQA rt_sys tripped: on true | pair shut true | game's inventory true | hotbar vanilla | moodle layer false
ZEDQA rt_sys PASS a trip: ZeD's windows shut
ZEDQA rt_sys PASS a trip: the game's own inventory page, hotbar and moodles come back
ZEDQA rt_sys PASS a trip: the note shows (the game's own dialog) and closes
ZEDQA rt_sys PASS tripped, the inventory key works the game's own page (hides, shows) | true -> false -> true
ZEDQA rt_sys reset: on false | pair shut true | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS a reset brings ZeD back and hides the game's page
ZEDQA rt_sys PASS trip recovery by hand: ZeD.Safe.reset() clears the trip and the switch reads Off | tripped false
ZEDQA rt_sys PASS after the reset ZeD's windows open again
ZEDQA rt_sys PASS on screen (the windows after a safe mode reset): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS the Safe mode option On is picked up by itself within a second | 419 ms
ZEDQA rt_sys PASS Safe mode On: the game's own pages, no trip note
ZEDQA rt_sys PASS never caught in safe mode: with safe mode On, Messages keeps no other mod's note
ZEDQA rt_sys PASS the Safe mode option Off is picked up by itself within a second | 448 ms
ZEDQA rt_sys PASS Safe mode Off: ZeD back
ZEDQA rt_sys PASS Safe mode recovery: switched Off, nothing of the game's own is left applied | applied false
ZEDQA rt_sys PASS with safe mode Off the same note would be kept again (the control)
ZEDQA rt_sys PASS Safe mode recovery: the ZeD Character and World windows open again
ZEDQA rt_sys PASS the watchdog: a five-frame burst of faults leaves ZeD on
ZEDQA rt_sys PASS the watchdog: under two seconds of faults ZeD stays on | 2011 ms, 121 frames
ZEDQA rt_sys PASS the watchdog: two seconds of faults every frame trip it | 2011 ms
ZEDQA rt_sys PASS the watchdog's note shows and closes
ZEDQA rt_sys safe mode put back: on false | pair shut false | game's inventory false | hotbar replaced | moodle layer true
ZEDQA rt_sys PASS safe mode put back: the option as it was, ZeD running
ZEDQA rt_sys PASS Safe mode from the Select wheel asks first (Yes and No), and nothing is on yet | question true, safe mode false
ZEDQA rt_sys PASS Safe mode asks first: No leaves safe mode off and the option as it was | safe mode false, option 1
ZEDQA rt_sys PASS one screen handed back: the belt's switch On gives the belt alone to the game | belt true, all false, hook true
ZEDQA rt_sys PASS one screen handed back: the belt's switch Off makes the belt ZeD's again | hook false
ZEDQA rt_sys SKIP step-aside (no active mod replaces a ZeD screen in this game)
ZEDQA rt_sys PASS step-aside: a supported mod (AutoHideHotbar and the rest) is never detected | none detected
ZEDQA rt_sys PASS another mod's note is kept in Messages, not shown over the game
ZEDQA rt_sys PASS Messages keeps the note, new, under the mod's name | 1
ZEDQA rt_sys PASS the Messages window opens on the mod
ZEDQA rt_sys PASS the window shows the note's card with its OK | 1
ZEDQA rt_sys PASS on screen (the Messages window): every ZeD window and pop-up inside 1280x800 | 7 seen
ZEDQA rt_sys PASS OK in Messages runs the mod's own callback once | 1 calls
ZEDQA rt_sys PASS put back: the test mod's messages are cleared
ZEDQA rt_sys PASS Messages, balloons On: a new message shows its balloon | 1 balloons
ZEDQA rt_sys PASS Messages: the balloon goes after six seconds | 6020 ms
ZEDQA rt_sys PASS Messages, balloons Off: a new message shows no balloon | 0 balloons
ZEDQA rt_sys PASS put back: the balloon test's messages and the switch
ZEDQA rt_sys PASS Bug report: the count it returns is the caught errors' | 0, want 0
ZEDQA rt_sys PASS Bug report: the clipboard holds the report (it starts "ZeD-GUI ") | ZeD-GUI 0.3.0-beta21 | Project Zomboid 4
ZEDQA rt_sys PASS put back: the clipboard as it was | 9 characters, 9 before
ZEDQA rt_sys PASS on screen (the Messages window with its foot band): every ZeD window and pop-up inside 1280x800 | 7 seen
ZEDQA rt_sys PASS Messages foot band: Pop-ups on saves the mod in ZeD_messages.txt, pressed again it is off | on true, in the file true, after false
ZEDQA rt_sys PASS Messages foot band: Mark all read leaves nothing unread | 1 -> 0
ZEDQA rt_sys PASS Messages foot band: Delete asks first and deletes nothing yet | asking true
ZEDQA rt_sys PASS Messages foot band: Yes to the question deletes the mod's messages | Yes button true
ZEDQA rt_sys PASS put back: every message's read mark, ZeD_messages.txt and the balloon switch | 0 marks off, 1 lines, 1 before
ZEDQA rt_sys soak start: 1628160 KB, 0 Lua errors so far
ZEDQA rt_sys PASS the soak ran its two minutes | 120 s
ZEDQA rt_sys PASS the soak: no Lua error in two minutes with the windows open | 0 new
ZEDQA rt_sys PASS the soak: Lua memory grows by no more than 262144 KB | 1628160 KB -> 1671168 KB (43008 KB)
ZEDQA rt_sys PASS on screen (the windows after the soak): every ZeD window and pop-up inside 1280x800 | 6 seen
ZEDQA rt_sys PASS every key in ZeD's English UI.json has text in the game | 7003 keys
ZEDQA rt_sys PASS every ZeD key read while the script ran has text | 426 keys
ZEDQA rt_sys PASS every game key ZeD borrowed while the script ran has text | 53 keys
ZEDQA rt_sys PASS sandbox tags: each setting's WHEN and RISK is one the window knows (DayLength now) | |
ZEDQA rt_sys PASS sandbox tags: a "fix" setting's row is locked, a "now" one is not | true / false
ZEDQA rt_sys PASS capitals: the sharp s stays one letter and an accented letter takes its capital | 6 letters
ZEDQA rt_sys PASS pixel fonts: the 3x5 and 5x7 faces have their signs, accented capitals and Cyrillic (the extra file merged)
ZEDQA rt_sys PASS Sandbox options line on the pause window: shown with its switch On, gone Off | true / false
ZEDQA rt_sys PASS Read marks: a skill book's mark follows the pages read (unread, part, read), none with the switch Off | 0:u 110:p 220:r
ZEDQA rt_sys PASS put back: the character's pages read and the read marks switch | 0 pages, 0 before
ZEDQA rt_sys PASS Chord setup: a chord given a path reads it back, saved, off its default | zedqa:1, saved zedqa:1, default false
ZEDQA rt_sys PASS Chord setup: a reset chord is its default again | now:3, want now:3
ZEDQA rt_sys PASS put back: the chord and ZeD_chords.txt as found | now:3, was now:3
ZEDQA layout rt_sys put back
ZEDQA rt_sys PASS put back: ZeD.tr is ZeD's own again
ZEDQA rt_sys PASS put back: every setting this script changed is as it was
ZEDQA rt_sys PASS put back: every ZeD option's value, the accent, the text size and the see-through as found |
ZEDQA rt_sys PASS put back: ModOptions.ini is as found, line for line | 65 lines, 65 before
ZEDQA rt_sys end: 205 pass, 0 fail, 7 skipped
ZEDQA rt_sys VERDICT PASS 205
ZEDQA rt_sys DONE
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
