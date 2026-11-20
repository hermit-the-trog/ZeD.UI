# ZeD-UI regression - 2026-11-20 06:17 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-20 06:17:10 |
| Finished | 2026-11-20 06:21:54 (4 min 43 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rt_menus_sys_only.txt (5 scripts) |
| Result | **4/5 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 30774 to 30780 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30779, 30780)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 7 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_menus.lua | rt_menu | PASS | 6 |  |  |
| 4 | rt_lite.lua | rt_lite | PASS | 7 |  |  |
| 5 | rt_system.lua | rt_sys | **FAIL** | 157 |  | 20 Java exception(s) in the log; 8 ERR line(s); its own checks failed (VERDICT FAIL) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 7 s

- go 30774 at 06:18:17

```text
[ZeD.QA] state #1 speed=1 paused=false player=910,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 910,13039,0 to the drag strip
ZEDQA pre clock 0.89 -> 11.00 (daylight)
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

- go 30775 at 06:18:28

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_menus.lua (`ZEDQA rt_menu`) - PASS, 6 s

- go 30776 at 06:18:32

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_menu start (48 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_menu PASS ZeD's Context menu setting is there
ZEDQA rt_menu PASS the Character window is open
ZEDQA rt_menu PASS three tools of kinds the bag does not hold were given | 3 given
ZEDQA rt_menu PASS the strip test: the tool's row in the bag takes a right-click | Crowbar
ZEDQA rt_menu PASS the right-click opens ZeD's strip (ZeD_ContextMenu) on the tool | menu ZeD_ContextMenu, on the tool true
ZEDQA rt_menu PASS the strip: every row and submenu row has its icon | 18 rows
ZEDQA rt_menu PASS the strip: every top row has its category (USE to ADMIN) |
ZEDQA rt_menu PASS on screen (the strip open): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_menu PASS the strip: the pad's D-pad Right steps one cell on, Left steps back | 1 -> 2 -> 1 of 14
ZEDQA rt_menu PASS the strip: the pad's RB jumps to the next group, LB back to the group before | ACTION -> CRAFT -> ACTION
ZEDQA rt_menu PASS the strip: a click on the right chevron pages on, the left one pages back | 1 -> 11 -> 1 of 14
ZEDQA rt_menu SKIP the strip: a click on a bumper jumps groups (no bumpers drawn on this strip)
ZEDQA rt_menu PASS the strip stays open through its navigation
ZEDQA rt_menu PASS the strip: the selected option is the one lit in the game's menu (its target outline) | Attach / lit Attach
ZEDQA rt_menu PASS the strip: the target reads as the tool (getTargetDisplay; getMetaFor answers) | Crowbar / meta "cond 100%"
ZEDQA rt_menu PASS the strip: Move to opens its submenu | 1 rows under it; top: Attach, Place Item, Favorite, Set Unwanted, Move to, Pin to title bar, Craft, Set to be Unusable in Recipes, Equip in Both Hands, Equip Primary, Equip Secondary, Drop, Save to loadout, Rename
ZEDQA rt_menu PASS on screen (the strip with its submenu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_menu PASS the strip: the pad's B backs out of the submenu to the top | depth 1
ZEDQA rt_menu PASS the strip: Equip Primary is picked | picked
ZEDQA rt_menu PASS the strip's pick ran the game's Equip Primary: the tool is in the hand, the menu closed | hand Crowbar, menu false
ZEDQA rt_menu PASS the list test: the tool's row in the bag takes a right-click | Screwdriver
ZEDQA rt_menu PASS the right-click opens ZeD's list (ZeD_ContextList) on the tool | menu ZeD_ContextList, on the tool true
ZEDQA rt_menu PASS the list: every row and submenu row has its icon | 19 rows
ZEDQA rt_menu PASS the list: every top row has its category (USE to ADMIN) |
ZEDQA rt_menu PASS on screen (the list open): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_menu PASS the list's box is on screen | 1 levels inside 3840x2160
ZEDQA rt_menu PASS the list: the pad's Down moves the selection a row, Up back | 1 -> 2 -> 1
ZEDQA rt_menu PASS the list: the pad's Right on Move to opens its submenu, its first row selected | levels 2
ZEDQA rt_menu PASS the list: the submenu cascades beside the list, on screen | 2 levels inside 3840x2160
ZEDQA rt_menu PASS the list: the pad's Left backs out of the submenu | levels 1
ZEDQA rt_menu SKIP the list: the balloon for the selected row (the row Dismantle Simple Electronic Item has no words to show)
ZEDQA rt_menu PASS the list: a click on Move to opens its submenu | levels 2
ZEDQA rt_menu PASS the list: the selected option is the one lit in the game's menu (its target outline) | Move to / lit Move to
ZEDQA rt_menu PASS the list: the target reads as the tool (getTargetDisplay; getMetaFor answers) | Screwdriver / meta "cond 100%"
ZEDQA rt_menu PASS the list: its heading names the tool | drew: Screwdriver | Attach | Dismantle Simple Electronic Item | Place Item | Favorite | Set Unwanted | Move to | Pin to title bar | Craft | Set to be Unusable in Recipes | Equip Primary | Equip Secondary | Drop | Save to loadout | Rename | Screwdriver | Attach | Dismantle Simple Electronic Item | Place Item | Favorite | Set Unwanted | Move to | Pin to title bar | Craft | Set to be Unusable in Recipes | Equip Primary | Equip Secondary | Drop | Save to loadout | Rename | Screwdriver | Attach | Dismantle Simple Electronic Item | Place Item | Favorite | Set Unwanted | Move to | Pin to title bar | Craft | Set to be Unusable in Recipes | Equip Primary | Equip Secondary | Drop | Save to loadout | Rename
ZEDQA rt_menu PASS the list: Move to opens its submenu | 1 rows under it; top: Attach, Dismantle Simple Electronic Item, Place Item, Favorite, Set Unwanted, Move to, Pin to title bar, Craft, Set to be Unusable in Recipes, Equip Primary, Equip Secondary, Drop, Save to loadout, Rename
ZEDQA rt_menu PASS on screen (the list with its submenu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_menu PASS the list and its submenu are on screen | 2 levels inside 3840x2160
ZEDQA rt_menu PASS the list: the pad's B backs out of the submenu to the top | depth 1
ZEDQA rt_menu PASS the list: Equip Primary is picked | picked
ZEDQA rt_menu PASS the list's pick ran the game's Equip Primary: the tool is in the hand, the menu closed | hand Screwdriver, menu false
ZEDQA rt_menu PASS pins: the third tool's row takes a right-click
ZEDQA rt_menu PASS pins: the tool's row takes a right-click again
ZEDQA rt_menu PASS pins: a saved pin (Equip Secondary) comes first in its group (EQUIP), marked pinned | first: Equip Secondary, pinned true
ZEDQA rt_menu PASS tooltip: ZeD's methods are on the game's tooltips
ZEDQA rt_menu PASS tooltip: a tooltip and the tool's tooltip are made and shown |
ZEDQA rt_menu PASS tooltip: a tooltip (ISToolTip) draws as ZeD's box (its frame, ZeD's frame color, no error) | framed true, error nil, the game's menu visibleCheck nil
ZEDQA rt_menu PASS tooltip: a tooltip (ISToolTip) is on screen | 1280,720 420x104 in 3840x2160
ZEDQA rt_menu PASS tooltip: the tool's tooltip (ISToolTipInv) draws as ZeD's box (its frame, ZeD's frame color, no error) | framed true, error nil, the game's menu visibleCheck nil
ZEDQA rt_menu PASS tooltip: the tool's tooltip (ISToolTipInv) is on screen | 1946,1105 255x113 in 3840x2160
ZEDQA rt_menu PASS context icons: the data is loaded (Walk to has its icon) | person-walking-arrow-right
ZEDQA rt_menu PASS the pause menu opens (for the pad and Options checks)
ZEDQA rt_menu PASS pause menu up: no ZeD window takes the pad (claimFocus declines) | menu up true, focused nil
ZEDQA rt_menu PASS Options opens from the pause menu (for its sub-pages)
ZEDQA rt_menu PASS Options: the controller page (Button map and test) opens as its sub-page | pad
ZEDQA rt_menu PASS on screen (the controller page): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_menu PASS Options: Advanced game sounds opens with its sounds | sounds, 10 categories
ZEDQA rt_menu SKIP Options, game sounds: a slider step sets the sound's volume and reads back (the game's advanced sound options are off (SystemDisabler), so every sound's volume reads 1.0)
ZEDQA rt_menu PASS on screen (the game sounds page): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_menu PASS the pause menu shuts again
ZEDQA rt_menu PASS the Context menu setting is back as it was | 2
ZEDQA rt_menu PASS the hands hold what they held
ZEDQA rt_menu end: 59 pass, 0 fail, 3 skipped
ZEDQA rt_menu VERDICT PASS 59
ZEDQA rt_menu DONE
```

### 4. rt_lite.lua (`ZEDQA rt_lite`) - PASS, 7 s

- go 30777 at 06:18:41

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_lite start (39 steps)
[ZeD.QA] run #4 ok=true
ZEDQA rt_lite PASS Lite: ZeD's settings, molecules and options are loaded
ZEDQA rt_lite as found: Style 1 (1 Full, 2 Lite), additions preset 4
ZEDQA rt_lite PASS Style Lite: Options opens from the pause menu
ZEDQA rt_lite PASS Style Lite: ZeD setup has the Style row
ZEDQA rt_lite PASS Style Lite: ZeD setup leaves out the Additions and Chords groups | additions false, chords false/0
ZEDQA rt_lite PASS Style Lite: none of the eight retired switches is in ZeD setup |
ZEDQA rt_lite PASS Style Lite: the Style row stays in ZeD setup
ZEDQA rt_lite PASS on screen (ZeD setup in Lite): every ZeD window and pop-up inside 3840x2160 | 0 seen
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
ZEDQA rt_lite PASS on screen (Lite: the watch in its corner): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_lite PASS Lite buttons: a primary button is drawn filled with the good color under a two-hairline line | x1: 2 lines, 0 double
ZEDQA rt_lite PASS Lite dashboard: every car gets the Dash Elite (a pickup, a police car) | dashelite, dashelite
ZEDQA rt_lite PASS Lite dashboard: in the black cabin | v_black
ZEDQA rt_lite SKIP Lite watch: the big time is in the accent color (the big time is not drawn through drawText (another drawing path))
ZEDQA rt_lite PASS Lite watch fold: the face has its fold hit and a click lands on it
ZEDQA rt_lite PASS Lite watch fold: a click on the face folds it to one line (shorter, the strip is one fold hit) | thin true, h 43.1484375 < 146.296875, hits fold
ZEDQA rt_lite PASS Lite watch fold: the strip's time is in the accent color | 11:06
ZEDQA rt_lite PASS on screen (Lite: the folded watch): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_lite PASS Lite watch fold: a click on the strip unfolds it to its full height | thin false, h 146.296875
ZEDQA rt_lite PASS Lite watch: the alarm line has its hit
ZEDQA rt_lite PASS Lite watch: a click on the alarm line opens the alarm setting | true
ZEDQA rt_lite PASS Lite device faces: no preset keys, memory key or dial lamp on any radio's plain controls | 17 readings, 0 with them:
ZEDQA rt_lite PASS Lite device faces: the memory key and the lamp are on the Lite drop list
ZEDQA rt_lite PASS Lite windows: the inventory has its List or Grid key
ZEDQA rt_lite PASS Lite windows: List or Grid is drawn as its word | List view: 153.76953125 wide, the word's button 153.76953125
ZEDQA rt_lite PASS Lite windows: Filter is drawn as its word | 116.7734375 wide, the word's button 116.7734375
ZEDQA rt_lite PASS Lite windows: no Same type or Same type nearby button | xfer
ZEDQA rt_lite PASS Lite windows: the container buttons' trim keeps Transfer all only | 1 left
ZEDQA rt_lite PASS Lite windows: the pencil's row is in the Character window's list
ZEDQA rt_lite PASS Lite windows: a click on the row opens its item card
ZEDQA rt_lite PASS Lite windows: the item card has no marks strip | nil
ZEDQA rt_lite PASS on screen (Lite: both windows and the item card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_lite PASS Lite windows: a second click closes the card
ZEDQA rt_lite PASS Style Full: Options opens from the pause menu
ZEDQA rt_lite PASS Style Full: ZeD setup has the Style row
ZEDQA rt_lite PASS Style Full: ZeD setup has the Additions and Chords groups again | additions true, chords true
ZEDQA rt_lite PASS Style Full: the retired switches stay out of ZeD setup |
ZEDQA rt_lite PASS on screen (ZeD setup in Full): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_lite PASS Style Full: the pause menu shuts
ZEDQA rt_lite PASS Style Full: ZeD.Settings.lite() is false once applied | 1
ZEDQA rt_lite PASS Style Full: the forms' helpers all answer Full | 6 helpers
ZEDQA rt_lite PASS Full buttons: ZeD.Molecules.lite() is false
ZEDQA rt_lite PASS Full watch: its place is the Watch option's again | belt false, option 2
ZEDQA rt_lite PASS Full dashboard: a pickup and a police car have their own dash again | d6, police
ZEDQA rt_lite PASS Full device faces: the radios' preset keys, memory key and lamp come back | 12 readings with them
ZEDQA rt_lite PASS Lite device faces: every plate's power row stays in Lite |
ZEDQA rt_lite PASS Full windows: List or Grid is the square picture key again | 46x46
ZEDQA rt_lite PASS Full windows: Same type and Same type nearby come back | xfer same near
ZEDQA rt_lite PASS Full windows: the item card has its marks strip again | 14
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

### 5. rt_system.lua (`ZEDQA rt_sys`) - FAIL, 157 s

- go 30778 at 06:18:52
- 20 Java exception(s) in the log
- 8 ERR line(s)
- its own checks failed (VERDICT FAIL)

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_sys start (170 steps)
[ZeD.QA] run #5 ok=true
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
ZEDQA rt_sys PASS on screen (ZeD setup from the Select wheel): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_sys PASS the pause menu shuts after the wheel's ZeD setup
ZEDQA rt_sys FAIL Options: the game's Inventory font row is marked moot | no Inventory font row
ZEDQA rt_sys PASS Options: the game's Dyslexic font row says where it still works | UI_ZeD_Options_OnlyDyslexic
ZEDQA rt_sys FAIL ZeD setup: the game settings it mirrors (Font size first) work the game's own control | 0 rows
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ERROR: General f:2657> Lua((MOD:ZeD-GUI)).pcall> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in pcall at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).pcall(ZeD_MainMenuOptions.lua:349)
    Lua((MOD:ZeD-GUI)).help(ZeD_MainMenuOptions.lua:344)
    Lua((MOD:ZeD-GUI)).q(ZeD_MainMenuOptions.lua:903)
    Lua((MOD:ZeD-GUI)).findRows(ZeD_MainMenuOptionGroups.lua:694)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_MainMenuOptions.lua:901)
ZEDQA rt_sys PASS Options, Find "scale": only the matching rows, UI scale among them | 1 of 310 rows, UI scale true
ZEDQA rt_sys PASS Options, Find cleared: ZeD setup's rows come back | 47 rows, 47 before
ZEDQA rt_sys PASS ZeD setup: every group has its heading and a named row for each of its options | 7 groups, 36 rows
ZEDQA rt_sys FAIL ZeD setup: with Wheel toggle mode On, Wheel open and Wheel commit are dimmed and take no change | toggle false, open 1, commit 1
ZEDQA rt_sys FAIL ZeD setup: with Toggle mode Off, Wheel open Hold and Wheel commit Stick click are read live | tap, flick
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
ZEDQA rt_sys PASS after ZeD setup's controls the scale is the run's own | root 1.75
ZEDQA rt_sys PASS on screen (the windows after ZeD setup's controls): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS UI scale UI_ZeD_Settings_ScaleAuto: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS on screen (UI scale UI_ZeD_Settings_ScaleAuto): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys SKIP UI scale 0.5x drawn at 0.5x (retired in the beta: ZeD setup's slider dims it and the wheel leaves it out)
ZEDQA rt_sys PASS UI scale 0.5x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.5x set by hand: drawn at the floor 0.75x, the saved pick kept | root 0.75, ZeD.T.root 0.75, item 2
ZEDQA rt_sys PASS on screen (UI scale 0.5x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale 0.75x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.75x: drawn at that scale (ZeD.T.root) | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 0.75x): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS UI scale 1x: the theme follows the new scale and both windows are open again | root 1
ZEDQA rt_sys PASS UI scale 1x: drawn at that scale (ZeD.T.root) | root 1, ZeD.T.root 1
ZEDQA rt_sys PASS on screen (UI scale 1x): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS UI scale 1.25x: the theme follows the new scale and both windows are open again | root 1.25
ZEDQA rt_sys PASS UI scale 1.25x: drawn at that scale (ZeD.T.root) | root 1.25, ZeD.T.root 1.25
ZEDQA rt_sys PASS on screen (UI scale 1.25x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale 1.5x: the theme follows the new scale and both windows are open again | root 1.5
ZEDQA rt_sys PASS UI scale 1.5x: drawn at that scale (ZeD.T.root) | root 1.5, ZeD.T.root 1.5
ZEDQA rt_sys PASS on screen (UI scale 1.5x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale 1.75x: the theme follows the new scale and both windows are open again | root 1.75
ZEDQA rt_sys PASS UI scale 1.75x: drawn at that scale (ZeD.T.root) | root 1.75, ZeD.T.root 1.75
ZEDQA rt_sys PASS on screen (UI scale 1.75x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale 2x: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS UI scale 2x: drawn at that scale (ZeD.T.root) | root 2, ZeD.T.root 2
ZEDQA rt_sys PASS on screen (UI scale 2x): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_sys PASS UI scale cap: every step fits this screen and there is no too-big line | cap 2
ZEDQA rt_sys PASS ZeD text follows the root scale: the body font's zoom is the root times its size at every step | 8 steps, zoom 0.15234375 to 0.40625
ZEDQA rt_sys PASS UI scale put back on the run's own step | option 7, root 1.75
ZEDQA layout rt_sys scale put back
ZEDQA rt_sys PASS on screen (the windows back after the scale steps): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS theme dark: the window box's Theme pick applies to ZeD's table and is saved as item 1 | dark, option 1
ZEDQA rt_sys PASS theme dark: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme dark: See-through is the player's pick | surfaceAlpha 0.9, want 0.9
ZEDQA rt_sys PASS on screen (theme dark): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS theme light: the window box's Theme pick applies to ZeD's table and is saved as item 2 | light, option 2
ZEDQA rt_sys PASS theme light: the accent is its light variant | rgb 26 102 85, want rgb 26 102 85
ZEDQA rt_sys PASS theme light: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme light): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS theme hicon: the window box's Theme pick applies to ZeD's table and is saved as item 3 | hicon, option 3
ZEDQA rt_sys PASS theme hicon: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme hicon: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme hicon): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS accent red: the window box's Accent pick gives its light color and is saved as item 1 | red, rgb 122 26 26, want rgb 122 26 26, option 1
ZEDQA rt_sys PASS accent orange: the window box's Accent pick gives its light color and is saved as item 2 | orange, rgb 122 80 16, want rgb 122 80 16, option 2
ZEDQA rt_sys PASS accent yellow: the window box's Accent pick gives its light color and is saved as item 3 | yellow, rgb 107 95 10, want rgb 107 95 10, option 3
ZEDQA rt_sys PASS accent green: the window box's Accent pick gives its light color and is saved as item 4 | green, rgb 18 85 24, want rgb 18 85 24, option 4
ZEDQA rt_sys PASS accent blue: the window box's Accent pick gives its light color and is saved as item 5 | blue, rgb 26 68 119, want rgb 26 68 119, option 5
ZEDQA rt_sys PASS accent teal: the window box's Accent pick gives its light color and is saved as item 6 | teal, rgb 26 102 85, want rgb 26 102 85, option 6
ZEDQA rt_sys PASS accent purple: the window box's Accent pick gives its light color and is saved as item 7 | purple, rgb 68 24 136, want rgb 68 24 136, option 7
ZEDQA rt_sys PASS accent pink: the window box's Accent pick gives its light color and is saved as item 8 | pink, rgb 136 34 68, want rgb 136 34 68, option 8
ZEDQA rt_sys PASS accent mono: the window box's Accent pick gives its light color and is saved as item 9 | mono, rgb 58 58 58, want rgb 58 58 58, option 9
ZEDQA rt_sys PASS text size small: the window box's Text size pick sets the scale and the sort font, saved as item 1 | scale 1.75, want 1.75, option 1
ZEDQA rt_sys PASS on screen (text size small): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS text size large: the window box's Text size pick sets the scale and the sort font, saved as item 2 | scale 2.0124999999999997, want 2.0124999999999997, option 2
ZEDQA rt_sys PASS on screen (text size large): every ZeD window and pop-up inside 3840x2160 | 7 seen
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
ZEDQA rt_sys PASS on screen (the windows at 60 see-through): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS See-through and the theme put back | 2, light
ZEDQA rt_sys FAIL Solid while in use: the window box's row flips it and saves it | true -> true, option 2
ZEDQA rt_sys PASS Solid while in use: a second pick puts it back | true
ZEDQA rt_sys PASS Low-health pixel blink Off: the pixel holds lit | 41 of 41 moments lit
ZEDQA rt_sys FAIL Low-health pixel blink On: the pixel blinks | 0 of 41 moments dark
ZEDQA rt_sys PASS Low-health pixel blink put back | false
ZEDQA rt_sys FAIL Item-colored grid tiles: the switch is read back at once | true
ZEDQA rt_sys PASS Item-colored grid tiles put back | true
ZEDQA rt_sys PASS Item-colored grid tiles: the item colors are loaded (Acorn) | 8806442
ZEDQA rt_sys PASS Controller highlight hand: the window box's pick is read and saved | hand, option 1
ZEDQA rt_sys PASS Controller highlight corners: the window box's pick is read and saved | corners, option 2
ZEDQA rt_sys PASS Controller highlight wash: the window box's pick is read and saved | wash, option 3
ZEDQA rt_sys PASS Controller highlight ants: the window box's pick is read and saved | ants, option 4
ZEDQA rt_sys PASS the controller highlights drew with no Lua error | 0 new
ZEDQA rt_sys PASS Controller highlight put back | hand
ZEDQA rt_sys PASS Lite or Full forms: each form's getter follows Style at once (belt, devices, watch, guide, mods, identity; the dash has no plain form) | 6 forms
ZEDQA rt_sys PASS UI sounds: Off plays no click, Full plays it (a sound id) | Off nil, Full 12092416
ZEDQA rt_sys PASS Button glyph set: item 3 reads the PlayStation set, item 1 Auto | ps / auto
ZEDQA rt_sys PASS Test language On: within half a second a ZeD phrase reads stretched, in brackets | 361 ms, 15 letters, plain 9
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
ZEDQA rt_sys PASS on screen (the windows after a safe mode reset): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS the Safe mode option On is picked up by itself within a second | 460 ms
ZEDQA rt_sys PASS Safe mode On: the game's own pages, no trip note
ZEDQA rt_sys PASS never caught in safe mode: with safe mode On, Messages keeps no other mod's note
ZEDQA rt_sys PASS the Safe mode option Off is picked up by itself within a second | 474 ms
ZEDQA rt_sys PASS Safe mode Off: ZeD back
ZEDQA rt_sys PASS Safe mode recovery: switched Off, nothing of the game's own is left applied | applied false
ZEDQA rt_sys PASS with safe mode Off the same note would be kept again (the control)
ZEDQA rt_sys PASS Safe mode recovery: the ZeD Character and World windows open again
ZEDQA rt_sys PASS the watchdog: a five-frame burst of faults leaves ZeD on
ZEDQA rt_sys PASS the watchdog: under two seconds of faults ZeD stays on | 2019 ms, 121 frames
ZEDQA rt_sys PASS the watchdog: two seconds of faults every frame trip it | 2019 ms
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
ZEDQA rt_sys PASS on screen (the Messages window): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS OK in Messages runs the mod's own callback once | 1 calls
ZEDQA rt_sys PASS put back: the test mod's messages are cleared
ZEDQA rt_sys PASS Messages, balloons On: a new message shows its balloon | 1 balloons
ZEDQA rt_sys PASS Messages: the balloon goes after six seconds | 6013 ms
ZEDQA rt_sys PASS Messages, balloons Off: a new message shows no balloon | 0 balloons
ZEDQA rt_sys PASS put back: the balloon test's messages and the switch
ZEDQA rt_sys PASS Bug report: the count it returns is the caught errors' | 13, want 13
ZEDQA rt_sys PASS Bug report: the clipboard holds the report (it starts "ZeD-GUI ") | ZeD-GUI 0.3.0-beta21 | Project Zomboid 4
ZEDQA rt_sys PASS put back: the clipboard as it was | 9 characters, 9 before
ZEDQA rt_sys PASS on screen (the Messages window with its foot band): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS Messages foot band: Pop-ups on saves the mod in ZeD_messages.txt, pressed again it is off | on true, in the file true, after false
ZEDQA rt_sys PASS Messages foot band: Mark all read leaves nothing unread | 2 -> 0
ZEDQA rt_sys PASS Messages foot band: Delete asks first and deletes nothing yet | asking true
ZEDQA rt_sys PASS Messages foot band: Yes to the question deletes the mod's messages | Yes button true
ZEDQA rt_sys PASS put back: every message's read mark, ZeD_messages.txt and the balloon switch | 0 marks off, 1 lines, 1 before
ZEDQA rt_sys soak start: 1726464 KB, 60 Lua errors so far
ZEDQA rt_sys PASS the soak ran its two minutes | 120 s
ZEDQA rt_sys PASS the soak: no Lua error in two minutes with the windows open | 0 new
ZEDQA rt_sys PASS the soak: Lua memory grows by no more than 262144 KB | 1726464 KB -> 1761280 KB (34816 KB)
ZEDQA rt_sys PASS on screen (the windows after the soak): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS every key in ZeD's English UI.json has text in the game | 7003 keys
ZEDQA rt_sys PASS every ZeD key read while the script ran has text | 411 keys
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
ZEDQA rt_sys end: 195 pass, 7 fail, 2 skipped
ZEDQA rt_sys VERDICT FAIL 7
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
