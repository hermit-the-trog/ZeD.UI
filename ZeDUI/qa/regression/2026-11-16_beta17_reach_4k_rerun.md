# ZeD-UI regression - 2026-11-16 11:56 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-16 11:56:37 |
| Finished | 2026-11-16 12:00:08 (3 min 31 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta17 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b17.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 27789 to 27794 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 27793, 27794)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_b17_belt.lua | b17b | PASS | 10 | zqa_b17b_dash_knob.png |  |
| 3 | zedqa_b17_inv.lua | b17i | PASS | 41 | zqa_b17i_trash_ask_cancel.png, zqa_b17i_journal_keyboard.png, zqa_b17i_cat_folded.png |  |
| 4 | zedqa_b17_scroll.lua | b17s | PASS | 57 | zqa_b17s_tv_top.png, zqa_b17s_radio_top.png, zqa_b17s_twoway_ham_top.png, zqa_b17s_cd_player_top.png, zqa_b17s_oven_top.png, zqa_b17s_microwave_top.png, zqa_b17s_generator_top.png, zqa_b17s_propane_grill_top.png, zqa_b17s_laundry_top.png, zqa_b17s_item_card_foot.png, zqa_b17s_mechanics_foot.png, zqa_b17s_furniture_foot.png, zqa_b17s_journal_ask.png, zqa_b17s_journal_after_delete.png, zqa_b17s_equip_card_unequip.png, zqa_b17s_equip_after_unequip.png, zqa_b17s_equip_card_drop.png, zqa_b17s_equip_after_drop.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 27789 at 11:57:43

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta17 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_b17_belt.lua (`ZEDQA b17b`) - PASS, 10 s

- go 27790 at 11:57:49
- screenshots: zqa_b17b_dash_knob.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b17b start
[ZeD.QA] run #2 ok=true
ZEDQA b17b pad nil, at 925,13040
ZEDQA b17b PASS a Timez worn: the watch is on the belt
ZEDQA b17b PASS 250 Loadouts off: the Character wheel has 9 slices (want 9), the last Belt
ZEDQA b17b Belt off: nil
ZEDQA b17b PASS 250 Loadouts on: the Character wheel has 10 slices (want 10), the last Belt
ZEDQA b17b Belt off: nil
ZEDQA b17b not run: the pad on the belt (no controller bound: setJoypadFocus needs one)
ZEDQA b17b not run: Start round trip (no pad on the belt)
ZEDQA b17b not run: the full watch on the pad (no controller or no watch)
ZEDQA b17b PASS 263 face (oven): Start goes to the game's pause
ZEDQA b17b PASS 263 Messages: Start goes to the game's pause
ZEDQA b17b PASS 263 reader: Start goes to the game's pause
ZEDQA b17b PASS 263 guide window: Start goes to the game's pause
ZEDQA b17b PASS 263 guide book: Start goes to the game's pause
ZEDQA b17b not run: opening the station pop-out (needs a bound station), the siren (a police car), chat (a server)
ZEDQA b17b PASS 263 station pop-out: Start goes to the game's pause (handler only)
ZEDQA b17b PASS 263 siren: Start goes to the game's pause (handler only)
ZEDQA b17b PASS 263 chat: Start goes to the game's pause (handler only)
ZEDQA vp b17b player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=917,13030 dist=13.6 chunk=true inMap=true car=Base.CarNormal at 917.0,13030.0 dist=13.6 vehicles=32
ZEDQA car b17b Base.CarNormal spawned on spot 11 (917,13030)
ZEDQA b17b PASS 263 seat pop-out: Start goes to the game's pause
ZEDQA b17b PASS 250 in the driver's seat the Belt slice reads Not now (Not now.)
ZEDQA b17b PASS 265 the pad on the dash lands on the volume knob (dash:vol)
ZEDQA b17b PASS 265 tap A grabs the knob
ZEDQA b17b before the turns: speed 1, driver true, set on true, power 1, volume 0.5
ZEDQA b17b PASS 265 Right turns up from half (volume 0.6000000238418579)
ZEDQA b17b PASS 265 Right stops at full, no wrap (volume 1)
ZEDQA b17b PASS 265 Left turns it down (volume 0.8999999761581421)
ZEDQA b17b PASS 265 B lets go, the dash keeps the pad
ZEDQA b17b PASS 265 X is power (true -> false)
ZEDQA b17b PASS 263 car dash: Start goes to the game's pause
ZEDQA b17b PASS 263 car radio: Start goes to the game's pause
ZEDQA b17b put back: volume 1 (was 1), power false (was false)
ZEDQA b17b put back: Loadouts 2, Watch 2, speed 1, pad on the game
ZEDQA b17b all checks passed
ZEDQA b17b DONE
```

### 3. zedqa_b17_inv.lua (`ZEDQA b17i`) - PASS, 41 s

- go 27791 at 11:58:02
- screenshots: zqa_b17i_trash_ask_cancel.png, zqa_b17i_journal_keyboard.png, zqa_b17i_cat_folded.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b17i start
[ZeD.QA] run #3 ok=true
ZEDQA b17i setup: trash can true, 4 things given, paused was false
ZEDQA b17i PASS 249: the trash can has a stop on the World window's container strip
ZEDQA b17i PASS 249: Remove all is a stop in the trash can's buttons
ZEDQA b17i PASS 249: A on Remove all asks first
ZEDQA b17i PASS 249: the question opens with the pad on Cancel (no)
ZEDQA b17i PASS 249: B closes the question
ZEDQA b17i PASS 249: after B the pad is back on Remove all
ZEDQA b17i PASS 249: nothing deleted after B (3 of 3)
ZEDQA b17i PASS 249: A on Cancel closes the question
ZEDQA b17i PASS 249: after Cancel the pad is back on Remove all
ZEDQA b17i PASS 249: nothing deleted after Cancel (3 of 3)
ZEDQA b17i not run: 249 another container question (Remove all is the only container button that asks, ContainerControls.lua)
ZEDQA b17i PASS 252 Journal write box: A opens the pad keyboard
ZEDQA b17i PASS 252 Journal write box: the keyboard types into this box
ZEDQA b17i PASS 252 Journal write box: B puts the keyboard away
ZEDQA b17i PASS 252 Journal write box: the pad is back on the box (journal:__write)
ZEDQA b17i PASS 252 Journal search: A opens the pad keyboard
ZEDQA b17i PASS 252 Journal search: the keyboard types into this box
ZEDQA b17i PASS 252 Journal search: B puts the keyboard away
ZEDQA b17i PASS 252 Journal search: the pad is back on the box (journal:__find)
ZEDQA b17i PASS 252 Notebooks search: A opens the pad keyboard
ZEDQA b17i PASS 252 Notebooks search: the keyboard types into this box
ZEDQA b17i PASS 252 Notebooks search: B puts the keyboard away
ZEDQA b17i PASS 252 Notebooks search: the pad is back on the box (journal:__find)
ZEDQA b17i not run: 252 Notebooks quick note (no stop jr:note on screen)
ZEDQA b17i PASS 252 Recipes search: A opens the pad keyboard
ZEDQA b17i PASS 252 Recipes search: the keyboard types into this box
ZEDQA b17i PASS 252 Recipes search: B puts the keyboard away
ZEDQA b17i PASS 252 Recipes search: the pad is back on the box (jrecipe:search)
ZEDQA b17i PASS 252 Craft search: A opens the pad keyboard
ZEDQA b17i PASS 252 Craft search: the keyboard types into this box
ZEDQA b17i PASS 252 Craft search: B puts the keyboard away
ZEDQA b17i PASS 252 Craft search: the pad is back on the box (craft:search)
ZEDQA b17i PASS 252 Build search: A opens the pad keyboard
ZEDQA b17i PASS 252 Build search: the keyboard types into this box
ZEDQA b17i PASS 252 Build search: B puts the keyboard away
ZEDQA b17i PASS 252 Build search: the pad is back on the box (build:search)
ZEDQA b17i PASS 254: Into is a controller stop on the Journal page (a notebook carried)
ZEDQA b17i 254: 2 books to write in carried (the given notebook and the character's own)
ZEDQA b17i 254: widths through the cycle 255.1328125 -> 242.80078125 -> 209.11328125 -> 255.1328125
ZEDQA b17i PASS 254: the pad stays on Into for each of the 3 presses
ZEDQA b17i PASS 254: the first A steps Into off the log only
ZEDQA b17i PASS 254: after 3 presses (the log only + 2 books) Into is back on the log only
ZEDQA b17i 253: the card in the overview true at 430 of 698
ZEDQA b17i PASS 253: the zone's card is a controller stop in the overview
ZEDQA b17i PASS 253: X on the zone's card opens the zone's menu (ZEDQA b17 pen)
ZEDQA b17i PASS 253: the zone's page is open (zone)
ZEDQA b17i PASS 253: Remove zone is a controller stop
ZEDQA b17i PASS 253: A on Remove zone asks first
ZEDQA b17i PASS 253: the remove question lands on Cancel (animals:zone:no)
ZEDQA b17i PASS 253: B cancels the remove
ZEDQA b17i PASS 253: the zone is still there
ZEDQA b17i PASS 253: the pad is back on Remove zone (animals:zone:remove)
ZEDQA b17i PASS 253: Rename is a controller stop
ZEDQA b17i PASS 253: A on Rename starts the rename
ZEDQA b17i PASS 253: the rename lands on Save (animals:zone:save)
ZEDQA b17i 253 rename: the pad keyboard up false (it opens only with a controller connected)
ZEDQA b17i PASS 253: B cancels the rename
ZEDQA b17i PASS 253: the zone keeps its name
ZEDQA b17i PASS 253: the pad is back on Rename (animals:zone:rename)
ZEDQA b17i PASS 253: the zone's name is a controller stop
ZEDQA b17i PASS 253: X on the zone's name opens the zone's menu
ZEDQA b17i PASS 255: the pad is on a row of the Character window's list
ZEDQA b17i PASS 255: L3 on Name A-Z reverses it (name false)
ZEDQA b17i PASS 255: L3 again goes on to Category A-Z (cat true)
ZEDQA b17i PASS 256 list: a category heading is a controller stop
ZEDQA b17i PASS 256 list: A folds Accessory
ZEDQA b17i PASS 256 list: the pad stays on the heading (cathead:0:Accessory)
ZEDQA b17i PASS 256 list: A again opens Accessory
ZEDQA b17i PASS 256 list: every category folded, each heading is still a stop (22 of 22)
ZEDQA b17i PASS 256 list: all folded, A opens Accessory
ZEDQA b17i PASS 256 grid: a category heading is a controller stop
ZEDQA b17i PASS 256 grid: A folds Accessory
ZEDQA b17i PASS 256 grid: the pad stays on the heading (cathead:0:Accessory)
ZEDQA b17i PASS 256 grid: A again opens Accessory
ZEDQA b17i PASS 256 grid: every category folded, each heading is still a stop (22 of 22)
ZEDQA b17i PASS 256 grid: all folded, A opens Accessory
ZEDQA b17i 256 column: trash can as a column true
ZEDQA b17i PASS 256 Loot column: a category heading is a controller stop
ZEDQA b17i PASS 256 Loot column: A folds Cooking
ZEDQA b17i PASS 256 Loot column: the pad stays on the heading (cathead:1:Cooking)
ZEDQA b17i PASS 256 Loot column: A again opens Cooking
ZEDQA layout b17i put back
ZEDQA b17i put back: the zone gone true, given things left 0, keyboard up false
ZEDQA b17i all checks passed
ZEDQA b17i DONE
```

### 4. zedqa_b17_scroll.lua (`ZEDQA b17s`) - PASS, 57 s

- go 27792 at 11:58:46
- screenshots: zqa_b17s_tv_top.png, zqa_b17s_radio_top.png, zqa_b17s_twoway_ham_top.png, zqa_b17s_cd_player_top.png, zqa_b17s_oven_top.png, zqa_b17s_microwave_top.png, zqa_b17s_generator_top.png, zqa_b17s_propane_grill_top.png, zqa_b17s_laundry_top.png, zqa_b17s_item_card_foot.png, zqa_b17s_mechanics_foot.png, zqa_b17s_furniture_foot.png, zqa_b17s_journal_ask.png, zqa_b17s_journal_after_delete.png, zqa_b17s_equip_card_unequip.png, zqa_b17s_equip_after_unequip.png, zqa_b17s_equip_card_drop.png, zqa_b17s_equip_after_drop.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b17s start
[ZeD.QA] run #4 ok=true
ZEDQA b17s text size 1 -> large
ZEDQA b17s windows held to 972 px (World 972, Character 972); 8 machines placed
ZEDQA b17s tv: face 676 px top stop to lowest control; window 972 px
ZEDQA b17s tv: window 548 px, face view 376 px for a 676 px face (8 steps)
ZEDQA b17s PASS tv: the face's controls are pad stops (radio:tw:power)
ZEDQA b17s tv: lowest control radio:tw:play after 2 Downs, scroll 0.217
ZEDQA b17s PASS tv: Up from the lowest control scrolls the face to the very top (0.217 -> 0.000, on radio:full after 5 Ups)
ZEDQA b17s radio: face 526 px top stop to lowest control; window 972 px
ZEDQA b17s radio: window 455 px, face view 283 px for a 526 px face (10 steps)
ZEDQA b17s PASS radio: the face's controls are pad stops (radio:tw:power)
ZEDQA b17s radio: lowest control radio:tw:battery after 4 Downs, scroll 0.198
ZEDQA b17s PASS radio: Up from the lowest control scrolls the face to the very top (0.198 -> 0.000, on radio:full after 7 Ups)
ZEDQA b17s twoway_ham: face 358 px top stop to lowest control; window 972 px
ZEDQA b17s twoway_ham: window 455 px, face view 283 px for a 358 px face (11 steps)
ZEDQA b17s PASS twoway_ham: the face's controls are pad stops (radio:tab:1)
ZEDQA b17s twoway_ham: lowest control radio:tw:mic after 3 Downs, scroll 0.021
ZEDQA b17s PASS twoway_ham: Up from the lowest control scrolls the face to the very top (0.021 -> 0.000, on radio:full after 3 Ups)
ZEDQA b17s cd_player: face 416 px top stop to lowest control; window 972 px
ZEDQA b17s cd_player: window 455 px, face view 283 px for a 416 px face (11 steps)
ZEDQA b17s PASS cd_player: the face's controls are pad stops (radio:tw:power)
ZEDQA b17s cd_player: lowest control radio:tw:battery after 1 Downs, scroll 0.103
ZEDQA b17s PASS cd_player: Up from the lowest control scrolls the face to the very top (0.103 -> 0.000, on radio:full after 5 Ups)
ZEDQA b17s oven: face 46 px top stop to lowest control; window 972 px
ZEDQA b17s oven: window 455 px, face view 152 px for a 46 px face (11 steps)
ZEDQA b17s PASS oven: the face's controls are pad stops (craft:stDrop)
ZEDQA b17s oven: lowest control craft:a:popout after 1 Downs, scroll 0.000
ZEDQA b17s oven: NOTE the walk down never scrolled the face (scroll now 0.000)
ZEDQA b17s microwave: face 779 px top stop to lowest control; window 972 px
ZEDQA b17s microwave: window 760 px, face view 457 px for a 779 px face (4 steps)
ZEDQA b17s PASS microwave: the face's controls are pad stops (craft:stDrop)
ZEDQA b17s microwave: lowest control craft:a:popout after 1 Downs, scroll 0.000
ZEDQA b17s microwave: NOTE the walk down never scrolled the face (scroll now 0.000)
ZEDQA b17s generator: face 448 px top stop to lowest control; window 972 px
ZEDQA b17s generator: window 548 px, face view 239 px for a 448 px face (8 steps)
ZEDQA b17s PASS generator: the face's controls are pad stops (oc:back)
ZEDQA b17s generator: lowest control gen:outlet after 3 Downs, scroll 0.000
ZEDQA b17s generator: NOTE the walk down never scrolled the face (scroll now 0.000)
ZEDQA b17s propane_grill: face 432 px top stop to lowest control; window 972 px
ZEDQA b17s propane_grill: window 495 px, face view 236 px for a 432 px face (9 steps)
ZEDQA b17s PASS propane_grill: the face's controls are pad stops (oc:back)
ZEDQA b17s propane_grill: lowest control bbq:tank after 2 Downs, scroll 0.600
ZEDQA b17s PASS propane_grill: Up from the lowest control scrolls the face to the very top (0.600 -> 0.000, on oc:back after 2 Ups)
ZEDQA b17s laundry: face 309 px top stop to lowest control; window 972 px
ZEDQA b17s laundry: window 455 px, face view 210 px for a 309 px face (11 steps)
ZEDQA b17s PASS laundry: the face's controls are pad stops (oc:back)
ZEDQA b17s laundry: lowest control ldy:door after 1 Downs, scroll 0.710
ZEDQA b17s PASS laundry: Up from the lowest control scrolls the face to the very top (0.710 -> 0.000, on oc:back after 1 Ups)
ZEDQA b17s PASS item card: the food card opens (Canned Beans)
ZEDQA b17s item_card: Down did nothing at 236.000 of 236.414
ZEDQA b17s item_card: Down steps 236 (60 units = 105 px), view 236.000 of 236.414
ZEDQA b17s PASS item_card: Down at the last stop scrolls the view with the focus kept (1 presses)
ZEDQA b17s PASS item_card: the move leaves the view only once its end shows (left at 236.000)
ZEDQA b17s PASS item_card: Up past the first stop scrolls to the top (0.000, 2 Ups, on hverb_1)
ZEDQA b17s mechanics: car CarNormalSmashedFront 9.2 tiles off, now 2.5
ZEDQA b17s mechanics: tab vehicle, 1 cars offered, view overview, 40 part rows
ZEDQA b17s PASS mechanics: a part with About text in the list (Battery)
ZEDQA b17s mechanics: card Battery, right column scrolls 20.227, from mech:more
ZEDQA b17s mechanics: Down steps 20 (60 units = 105 px), view 20.227 of 20.227
ZEDQA b17s PASS mechanics: Down at the last stop scrolls the view with the focus kept (1 presses)
ZEDQA b17s PASS mechanics: a step is at most 60 units (20 <= 105)
ZEDQA b17s PASS mechanics: the move leaves the view only once its end shows (left at 20.227)
ZEDQA b17s PASS mechanics: Up past the first stop scrolls to the top (0.000, 1 Ups, on mech:more)
ZEDQA b17s furniture: place list scrolls 416.000, from fur:inv:1
ZEDQA b17s furniture: Down did nothing at 416.000 of 416.000
ZEDQA b17s furniture: Down steps 56 56 56 56 56 56 56 24 (60 units = 105 px), view 416.000 of 416.000
ZEDQA b17s PASS furniture: Down at the last stop scrolls the view with the focus kept (8 presses)
ZEDQA b17s PASS furniture: a step is at most 60 units (56 <= 105)
ZEDQA b17s PASS furniture: the move leaves the view only once its end shows (left at 416.000)
ZEDQA b17s PASS furniture: Up past the first stop scrolls to the top (0.000, 21 Ups, on fur:inv:1)
ZEDQA b17s PASS journal: the test entry's delete cross is a pad stop
ZEDQA b17s PASS journal: A on the cross asks first
ZEDQA b17s PASS journal: the question lands on Cancel (journal:ask:cancel)
ZEDQA b17s PASS journal: Cancel puts the pad back on the entry's cross (journal:del:1)
ZEDQA b17s PASS journal: Delete is a pad stop on the question
ZEDQA b17s PASS journal: Delete takes the test entry away
ZEDQA b17s PASS journal: after Delete the pad lands on the next entry's cross (journal:del:1)
ZEDQA b17s equip: wearing 2 test items
ZEDQA b17s PASS equip: the worn test item's slot is a pad stop (equipslot:HAT)
ZEDQA b17s PASS equip: the card offers UNEQUIP as a pad stop
ZEDQA b17s PASS equip: UNEQUIP takes the test item off
ZEDQA b17s PASS equip: after UNEQUIP the pad lands on the next filled slot (equipslot:INR, want equipslot:INR)
ZEDQA b17s PASS equip: no jump to the top (scroll 0.000 -> 0.000)
ZEDQA b17s PASS equip: the worn test item's slot is a pad stop (equipslot:NKL)
ZEDQA b17s PASS equip: the card offers DROP as a pad stop
ZEDQA b17s PASS equip: DROP takes the test item off
ZEDQA b17s PASS equip: after DROP the pad lands on the next filled slot (equipslot:GLV, want equipslot:GLV)
ZEDQA b17s PASS equip: no jump to the top (scroll 0.000 -> 0.000)
ZEDQA b17s put back: 8 objects and 18 items taken away, heights 735 / 735
ZEDQA b17s all checks passed
ZEDQA b17s DONE
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
