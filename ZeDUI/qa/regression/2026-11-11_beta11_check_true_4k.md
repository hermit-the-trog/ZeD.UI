# ZeD-UI regression - 2026-11-11 12:11 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-11 12:11:22 |
| Finished | 2026-11-11 12:16:14 (4 min 51 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta11 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b11_stage.txt (6 scripts) |
| Result | **3/6 pass**, 0 warn, 3 fail, 0 timeout |
| Go numbers | 10000 to 10007 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam -cachedir=%USERPROFILE%\ZomboidStaged (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- clicked again at 1920,1080 (the bridge had not armed in game after 30 s)
- clicked again at 1920,1080 (the bridge had not armed in game after 61 s)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 10006, 10007)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_release_check.lua | rel | PASS | 15 | zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png |  |
| 3 | zedqa_staged_ver.lua | sv | PASS | 1 |  |  |
| 4 | zedqa_b11_notes.lua | b11n | **FAIL** | 40 | zqa_b11n_3840x2160_1_hands_empty.png, zqa_b11n_3840x2160_2_two_handed_peek.png, zqa_b11n_3840x2160_3_hands_empty_again.png, zqa_b11n_3840x2160_4_char_card_open.png, zqa_b11n_3840x2160_5_char_card_closed.png, zqa_b11n_3840x2160_6_char_folded.png, zqa_b11n_3840x2160_7_world_folded.png, zqa_b11n_3840x2160_8_world_floor_empty.png, zqa_b11n_3840x2160_9_world_crate_empty.png, zqa_b11n_3840x2160_10_char_bag_empty.png, zqa_b11n_3840x2160_11_dark_teal_card.png, zqa_b11n_3840x2160_12_dark_orange_card.png, zqa_b11n_3840x2160_13_stack_list_asc.png, zqa_b11n_3840x2160_14_stack_list_desc.png, zqa_b11n_3840x2160_15_stack_grid_asc.png, zqa_b11n_3840x2160_16_stack_grid_desc.png, zqa_b11n_3840x2160_17_stack_open.png | 1 Java exception(s) in the log; 4 ERR line(s) |
| 5 | zedqa_b11_notes_r2.lua | b11n2 | **FAIL** | 39 | zqa_b11n2_3840x2160_1_hands_empty.png, zqa_b11n2_3840x2160_2_two_handed_peek.png, zqa_b11n2_3840x2160_3_hands_empty_again.png, zqa_b11n2_3840x2160_4_char_card_open.png, zqa_b11n2_3840x2160_5_char_card_closed.png, zqa_b11n2_3840x2160_6_char_folded.png, zqa_b11n2_3840x2160_7_world_folded.png, zqa_b11n2_3840x2160_8_world_floor_empty.png, zqa_b11n2_3840x2160_9_world_crate_empty.png, zqa_b11n2_3840x2160_10_char_bag_empty.png, zqa_b11n2_3840x2160_11_dark_teal_card.png, zqa_b11n2_3840x2160_12_dark_orange_card.png, zqa_b11n2_3840x2160_13_stack_list_asc.png, zqa_b11n2_3840x2160_14_stack_list_desc.png, zqa_b11n2_3840x2160_15_stack_grid_asc.png, zqa_b11n2_3840x2160_16_stack_grid_desc.png, zqa_b11n2_3840x2160_17_stack_open.png | 1 Java exception(s) in the log; 3 ERR line(s) |
| 6 | zedqa_b11_notes_r3.lua | b11n3 | **FAIL** | 39 | zqa_b11n3_3840x2160_1_hands_empty.png, zqa_b11n3_3840x2160_2_two_handed_peek.png, zqa_b11n3_3840x2160_3_hands_empty_again.png, zqa_b11n3_3840x2160_4_char_card_open.png, zqa_b11n3_3840x2160_5_char_card_closed.png, zqa_b11n3_3840x2160_6_char_folded.png, zqa_b11n3_3840x2160_7_world_folded.png, zqa_b11n3_3840x2160_8_world_floor_empty.png, zqa_b11n3_3840x2160_9_world_crate_empty.png, zqa_b11n3_3840x2160_10_char_bag_empty.png, zqa_b11n3_3840x2160_11_dark_teal_card.png, zqa_b11n3_3840x2160_12_dark_orange_card.png, zqa_b11n3_3840x2160_13_stack_list_asc.png, zqa_b11n3_3840x2160_14_stack_list_desc.png, zqa_b11n3_3840x2160_15_stack_grid_asc.png, zqa_b11n3_3840x2160_16_stack_grid_desc.png, zqa_b11n3_3840x2160_17_stack_open.png | 1 Java exception(s) in the log; 2 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 10000 at 12:13:20

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_release_check.lua (`ZEDQA rel`) - PASS, 15 s

- go 10001 at 12:13:26
- screenshots: zqa_rel_4_card.png, zqa_rel_3_menu.png, zqa_rel_5_watch.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel start
[ZeD.QA] run #2 ok=true
ZEDQA rel PASS the windows start shut
ZEDQA rel PASS 1: both windows open
ZEDQA rel rolled up before the hold: Character false, World false
ZEDQA rel the test item: Base.Spiffo
ZEDQA rel PASS 2: the test item is in the Character window's list
ZEDQA rel PASS 2: the test item went to the floor (the game's transfer)
ZEDQA rel PASS 2: the World window lists it
ZEDQA rel rolled up now: Character false, World false
ZEDQA rel PASS 2: it came back to the inventory
ZEDQA rel PASS 2: the Character window lists it again
ZEDQA rel PASS 4: the controller's focus is on the test item's row
ZEDQA rel 4: after A: charItemCard:hverb_1
ZEDQA rel PASS 4: A on the row opens its card, focus on its primary action (charItemCard:hverb_1)
ZEDQA rel 4: after B: invrow:21
ZEDQA rel PASS 4: B goes back to the row
ZEDQA rel PASS 3: the test item's row has a place on screen
ZEDQA rel PASS 3: the row is in the list's view (y 401 of 650)
ZEDQA rel 3: row invrow:21 at 214,401 91x91 in the window; the window at 1197,46
ZEDQA rel asked the helper for a right-click at 1441,492
ZEDQA rel PASS 3: the helper made the real right-click
ZEDQA rel 3: menu open true (ZeD_ContextMenu)
ZEDQA rel PASS 3: a real right-click on the row opens the item menu for that item (1 items)
ZEDQA rel PASS 5: the worn watch shows (belt true, corner true)
ZEDQA rel PASS 5: its face reads the game's time (13:53, the game 13:53)
ZEDQA rel RESULT PASS: all 16 checks
ZEDQA rel DONE
```

### 3. zedqa_staged_ver.lua (`ZEDQA sv`) - PASS, 1 s

- go 10002 at 12:13:44

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sv version=0.3.0-beta11 dir=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI
[ZeD.QA] run #3 ok=true
ZEDQA sv DONE
```

### 4. zedqa_b11_notes.lua (`ZEDQA b11n`) - FAIL, 40 s

- go 10003 at 12:13:48
- 1 Java exception(s) in the log
- 4 ERR line(s)
- screenshots: zqa_b11n_3840x2160_1_hands_empty.png, zqa_b11n_3840x2160_2_two_handed_peek.png, zqa_b11n_3840x2160_3_hands_empty_again.png, zqa_b11n_3840x2160_4_char_card_open.png, zqa_b11n_3840x2160_5_char_card_closed.png, zqa_b11n_3840x2160_6_char_folded.png, zqa_b11n_3840x2160_7_world_folded.png, zqa_b11n_3840x2160_8_world_floor_empty.png, zqa_b11n_3840x2160_9_world_crate_empty.png, zqa_b11n_3840x2160_10_char_bag_empty.png, zqa_b11n_3840x2160_11_dark_teal_card.png, zqa_b11n_3840x2160_12_dark_orange_card.png, zqa_b11n_3840x2160_13_stack_list_asc.png, zqa_b11n_3840x2160_14_stack_list_desc.png, zqa_b11n_3840x2160_15_stack_grid_asc.png, zqa_b11n_3840x2160_16_stack_grid_desc.png, zqa_b11n_3840x2160_17_stack_open.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b11n screen 3840x2160
ZEDQA b11n start
[ZeD.QA] run #4 ok=true
ZEDQA b11n theme dark / teal / small
ZEDQA b11n PASS the belt's HUD is up
ZEDQA b11n PASS 155 the belt has a main hand and an off hand box
ZEDQA b11n PASS 155 empty hands: the main ring draws hand_right
ZEDQA b11n PASS 155 empty hands: the off ring draws hand_left
ZEDQA b11n PASS 155 the off ring's icon is the smaller (main 42 px, off 28 px)
ZEDQA b11n PASS 155 both icons dim (alpha 1 / 1, textDim 1)
ZEDQA b11n PASS 155 the icon color is textDim (not the accent)
ZEDQA b11n PASS 155 icon hand_right exists at 16
ZEDQA b11n PASS 155 icon hand_right exists at 24
ZEDQA b11n PASS 155 icon hand_right exists at 32
ZEDQA b11n PASS 155 icon hand_right exists at 48
ZEDQA b11n PASS 155 icon hand_left exists at 16
ZEDQA b11n PASS 155 icon hand_left exists at 24
ZEDQA b11n PASS 155 icon hand_left exists at 32
ZEDQA b11n PASS 155 icon hand_left exists at 48
ZEDQA b11n 155 textures: hand_right@16=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\16\zw_hand_right.png(16) hand_right@24=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\24\zw_hand_right.png(24) hand_right@32=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\32\zw_hand_right.png(32) hand_right@48=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\48\zw_hand_right.png(48) hand_left@16=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\16\zw_hand_left.png(16) hand_left@24=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\24\zw_hand_left.png(24) hand_left@32=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\32\zw_hand_left.png(32) hand_left@48=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\48\zw_hand_left.png(48)
ZEDQA b11n 155 drawn: right 116,28 box 42; left 24,34 box 28
ZEDQA b11n PASS 155 no hand word drawn in the rings (330 belt texts seen, 0 are a hand word)
ZEDQA b11n 155 hint words: main 'Right Hand' off 'Left Hand'; the game's 'Right Hand' / 'Left Hand'
ZEDQA b11n PASS 155 the main hand's hint is the game's Right Hand
ZEDQA b11n PASS 155 the off hand's hint is the game's Left Hand
ZEDQA b11n PASS 155 the belt no longer says Primary / Secondary
ZEDQA b11n shot 1_hands_empty
ZEDQA b11n 155 two-handed item: Base.Sledgehammer, isTwoHandWeapon true
ZEDQA b11n PASS 155 the two-handed item is in both hands
ZEDQA b11n PASS 155 the off ring is a peek (peek true, peekW 44 of 77)
ZEDQA b11n PASS 155 no empty-hand icon is drawn while one item fills both hands
ZEDQA b11n 155 peek: main 25,98, off 0,77
ZEDQA b11n shot 2_two_handed_peek
ZEDQA b11n PASS 155 unequipped: both hand icons are back
ZEDQA b11n PASS 155 unequipped: the off ring is a ring again
ZEDQA b11n shot 3_hands_empty_again
ZEDQA b11n PASS 156 setup: the Character list shows the carried inventory with a hammer in it
ZEDQA b11n 156 card open: tab=loot mode=item open=true card=true tabUnder=nil
ZEDQA b11n PASS 156 a Loot item card opens (item mode, drawer open)
ZEDQA b11n shot 4_char_card_open
ZEDQA b11n 156 tab mode with a card: tab=loot mode=tab open=true card=true tabUnder=nil
ZEDQA b11n FAIL 156 tab mode on Loot with a card up becomes the card (no tab drawer)
ZEDQA b11n 156 card closed: tab=loot mode=nil open=false card=false tabUnder=nil
ZEDQA b11n PASS 156 closing the card folds the drawer (no half card left)
ZEDQA b11n shot 5_char_card_closed
ZEDQA b11n 156 tab mode, nothing in it: tab=loot mode=tab open=true card=false tabUnder=nil
ZEDQA b11n FAIL 156 Character: a tab drawer on Loot with nothing in it folds
ZEDQA b11n PASS 156 Character: no placeholder line drawn (0 seen, 0 texts)
ZEDQA b11n shot 6_char_folded
ZEDQA b11n 156 World: tab=loot mode=nil open=false tabUnder=nil
ZEDQA b11n PASS 156 World: a tab drawer on Loot with nothing in it folds
ZEDQA b11n PASS 156 World: no Coming soon / placeholder line drawn (0 seen)
ZEDQA b11n shot 7_world_folded
ZEDQA b11n PASS 157 setup: a bare tile was found near the QA spot (923.5,13038.5)
ZEDQA b11n 157 after the move: player 923.50,13038.50, square 923,13038
ZEDQA b11n 157 floor container: floor, 0 item(s)
ZEDQA b11n PASS 157 setup: the floor tile under the character is empty (move the character to a bare tile if not)
ZEDQA b11n 157 World, empty floor: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n PASS 157 World, empty floor: the empty list draws the key's words
ZEDQA b11n PASS 157 World, empty floor: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n shot 8_world_floor_empty
ZEDQA b11n PASS 157 setup: an empty crate was built beside the character
ERROR: General f:3558> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.WornItems.BodyLocation.isMultiItem()" because "location" is null at BodyLocationGroup.isMultiItem(BodyLocationGroup.java:119).
    Lua(Vanilla).pcall(spawnpoints.lua:440)
    Lua(Vanilla).add(spawnpoints.lua:440)
    Lua(Vanilla).drive(spawnpoints.lua:756)
ZEDQA b11n 157 bag worn at nil: isEquipped false
ZEDQA b11n 157 bag held instead: isEquipped true
ZEDQA b11n PASS 157 setup: an empty schoolbag is worn or held
ZEDQA b11n PASS 157 the crate has a stop in the World window's container strip
ZEDQA b11n PASS 157 the World list shows the crate
ZEDQA b11n 157 World, empty crate: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n PASS 157 World, empty crate: the empty list draws the key's words
ZEDQA b11n PASS 157 World, empty crate: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n shot 9_world_crate_empty
ZEDQA b11n 157 Character strip stops: Inventory, Angel Cross's Key Ring, Small Backpack
ZEDQA b11n PASS 157 the bag has a stop in the Character window's container strip
ZEDQA b11n 157 Character active container: 3, viewed 3
ZEDQA b11n 157 Character, empty bag: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n PASS 157 Character, empty bag: the empty list draws the key's words
ZEDQA b11n PASS 157 Character, empty bag: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n shot 10_char_bag_empty
ZEDQA b11n 160 the item card's label uses T.textSec, its value T.text, its dim tags T.textDim (ItemCardOrganism / Atoms.drawSecondary)
ZEDQA b11n 160 Dark teal: window 19,22,21 (surf1 alpha 0.90); body T.text 216,217,217 alpha 1.00 = 12.89:1; secondary T.textSec 147,167,162 = 7.18:1; dim T.textDim 150,151,151 = 6.23:1; over a white world: secondary 5.29:1, dim 4.59:1
ZEDQA b11n PASS 160 Dark/teal: body text >= 12:1 (12.89)
ZEDQA b11n PASS 160 Dark/teal: secondary text >= 7:1 within 0.1 (7.18)
ZEDQA b11n PASS 160 Dark/teal: dim text >= 4.5:1 (6.23)
ZEDQA b11n PASS 160 Dark/teal: secondary and dim >= 4.5:1 on the window over a white world (5.29 / 4.59)
ZEDQA b11n PASS 160 Dark/teal: the three tiers run body > secondary > dim
ZEDQA b11n shot 11_dark_teal_card
ZEDQA b11n PASS 160 the Orange accent exists
ZEDQA b11n 160 Dark orange: window 23,21,19 (surf1 alpha 0.90); body T.text 218,217,215 alpha 1.00 = 12.87:1; secondary T.textSec 178,163,141 = 7.39:1; dim T.textDim 152,151,150 = 6.22:1; over a white world: secondary 5.44:1, dim 4.58:1
ZEDQA b11n PASS 160 Dark/orange: body text >= 12:1 (12.87)
ZEDQA b11n PASS 160 Dark/orange: secondary text >= 7:1 within 0.1 (7.39)
ZEDQA b11n PASS 160 Dark/orange: dim text >= 4.5:1 (6.22)
ZEDQA b11n PASS 160 Dark/orange: secondary and dim >= 4.5:1 on the window over a white world (5.44 / 4.58)
ZEDQA b11n PASS 160 Dark/orange: the three tiers run body > secondary > dim
ZEDQA b11n shot 12_dark_orange_card
ZEDQA b11n 160 theme restored: dark / teal / small
ZEDQA b11n 162 bottles: fluid=0.00 fluid=0.30 fluid=0.60 fluid=1.00
ZEDQA b11n PASS 162 setup: four bottles, one empty and the rest watered
ZEDQA b11n 162 the player's list: grid sorted name asc (player)
ZEDQA b11n PASS 162 list: the water bottles are one stack of 6
ZEDQA b11n 162 list not drawn: row y 736, list height 650, scroll 0, bars seen 6
ZEDQA b11n 162 list: sort Cond ascending, the stack's head item holds 0.00, the emptiest holds 0.00, bar drawn none (row not drawn)
ZEDQA b11n PASS 162 list: the emptiest bottle is the empty one (0.00)
ZEDQA b11n FAIL 162 list: the stack's bar was drawn
ZEDQA b11n PASS 162 list: ItemMeter.ofStack says the same (0)
ZEDQA b11n shot 13_stack_list_asc
ZEDQA b11n PASS 162 list: the water bottles are one stack of 6
ZEDQA b11n 162 list: sort Cond descending, the stack's head item holds 1.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n PASS 162 list: the emptiest bottle is the empty one (0.00)
ZEDQA b11n PASS 162 list: the stack's bar was drawn
ZEDQA b11n PASS 162 list: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n PASS 162 list: ItemMeter.ofStack says the same (0)
ZEDQA b11n shot 14_stack_list_desc
ZEDQA b11n PASS 162 grid: the water bottles are one stack of 6
ZEDQA b11n 162 grid: sort Cond ascending, the stack's head item holds 0.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n PASS 162 grid: the emptiest bottle is the empty one (0.00)
ZEDQA b11n PASS 162 grid: the stack's bar was drawn
ZEDQA b11n PASS 162 grid: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n PASS 162 grid: ItemMeter.ofStack says the same (0)
ZEDQA b11n shot 15_stack_grid_asc
ZEDQA b11n PASS 162 grid: the water bottles are one stack of 6
ZEDQA b11n 162 grid: sort Cond descending, the stack's head item holds 1.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n PASS 162 grid: the emptiest bottle is the empty one (0.00)
ZEDQA b11n PASS 162 grid: the stack's bar was drawn
ZEDQA b11n PASS 162 grid: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n PASS 162 grid: ItemMeter.ofStack says the same (0)
ZEDQA b11n shot 16_stack_grid_desc
ZEDQA b11n PASS 162 the stack opens into its own rows (6 bottle rows)
ZEDQA b11n 162 open stack: head own 0.00 bar none; row own 0.00 bar none; row own 0.00 bar none; row own 0.30 bar none; row own 0.60 bar none; row own 1.00 bar none (the head row keeps the stack's bar as drawn)
ZEDQA b11n FAIL 162 each opened row's bar is its own bottle's level (0 of 5)
ZEDQA b11n shot 17_stack_open
ZEDQA b11n PASS cleanup: everything spawned is gone (0 left)
ZEDQA b11n cleanup: theme dark / teal / small, player's list grid
ZEDQA b11n RESULT 75 pass, 4 fail
ZEDQA b11n DONE
```

### 5. zedqa_b11_notes_r2.lua (`ZEDQA b11n2`) - FAIL, 39 s

- go 10004 at 12:14:31
- 1 Java exception(s) in the log
- 3 ERR line(s)
- screenshots: zqa_b11n2_3840x2160_1_hands_empty.png, zqa_b11n2_3840x2160_2_two_handed_peek.png, zqa_b11n2_3840x2160_3_hands_empty_again.png, zqa_b11n2_3840x2160_4_char_card_open.png, zqa_b11n2_3840x2160_5_char_card_closed.png, zqa_b11n2_3840x2160_6_char_folded.png, zqa_b11n2_3840x2160_7_world_folded.png, zqa_b11n2_3840x2160_8_world_floor_empty.png, zqa_b11n2_3840x2160_9_world_crate_empty.png, zqa_b11n2_3840x2160_10_char_bag_empty.png, zqa_b11n2_3840x2160_11_dark_teal_card.png, zqa_b11n2_3840x2160_12_dark_orange_card.png, zqa_b11n2_3840x2160_13_stack_list_asc.png, zqa_b11n2_3840x2160_14_stack_list_desc.png, zqa_b11n2_3840x2160_15_stack_grid_asc.png, zqa_b11n2_3840x2160_16_stack_grid_desc.png, zqa_b11n2_3840x2160_17_stack_open.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b11n2 screen 3840x2160
ZEDQA b11n2 start
[ZeD.QA] run #5 ok=true
ZEDQA b11n2 theme dark / teal / small
ZEDQA b11n2 PASS the belt's HUD is up
ZEDQA b11n2 PASS 155 the belt has a main hand and an off hand box
ZEDQA b11n2 PASS 155 empty hands: the main ring draws hand_right
ZEDQA b11n2 PASS 155 empty hands: the off ring draws hand_left
ZEDQA b11n2 PASS 155 the off ring's icon is the smaller (main 42 px, off 28 px)
ZEDQA b11n2 PASS 155 both icons dim (alpha 1 / 1, textDim 1)
ZEDQA b11n2 PASS 155 the icon color is textDim (not the accent)
ZEDQA b11n2 PASS 155 icon hand_right exists at 16
ZEDQA b11n2 PASS 155 icon hand_right exists at 24
ZEDQA b11n2 PASS 155 icon hand_right exists at 32
ZEDQA b11n2 PASS 155 icon hand_right exists at 48
ZEDQA b11n2 PASS 155 icon hand_left exists at 16
ZEDQA b11n2 PASS 155 icon hand_left exists at 24
ZEDQA b11n2 PASS 155 icon hand_left exists at 32
ZEDQA b11n2 PASS 155 icon hand_left exists at 48
ZEDQA b11n2 155 textures: hand_right@16=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\16\zw_hand_right.png(16) hand_right@24=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\24\zw_hand_right.png(24) hand_right@32=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\32\zw_hand_right.png(32) hand_right@48=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\48\zw_hand_right.png(48) hand_left@16=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\16\zw_hand_left.png(16) hand_left@24=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\24\zw_hand_left.png(24) hand_left@32=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\32\zw_hand_left.png(32) hand_left@48=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\48\zw_hand_left.png(48)
ZEDQA b11n2 155 drawn: right 116,28 box 42; left 24,34 box 28
ZEDQA b11n2 PASS 155 no hand word drawn in the rings (378 belt texts seen, 0 are a hand word)
ZEDQA b11n2 155 hint words: main 'Right Hand' off 'Left Hand'; the game's 'Right Hand' / 'Left Hand'
ZEDQA b11n2 PASS 155 the main hand's hint is the game's Right Hand
ZEDQA b11n2 PASS 155 the off hand's hint is the game's Left Hand
ZEDQA b11n2 PASS 155 the belt no longer says Primary / Secondary
ZEDQA b11n2 shot 1_hands_empty
ZEDQA b11n2 155 two-handed item: Base.Sledgehammer, isTwoHandWeapon true
ZEDQA b11n2 PASS 155 the two-handed item is in both hands
ZEDQA b11n2 FAIL 155 the off ring is a peek (peek nil, peekW nil of 77)
ZEDQA b11n2 PASS 155 no empty-hand icon is drawn while one item fills both hands
ZEDQA b11n2 155 peek: main 88,98, off 0,77
ZEDQA b11n2 shot 2_two_handed_peek
ZEDQA b11n2 PASS 155 unequipped: both hand icons are back
ZEDQA b11n2 PASS 155 unequipped: the off ring is a ring again
ZEDQA b11n2 shot 3_hands_empty_again
ZEDQA b11n2 PASS 156 setup: the Character list shows the carried inventory with a hammer in it
ZEDQA b11n2 156 card open: tab=loot mode=item open=true card=true tabUnder=nil
ZEDQA b11n2 PASS 156 a Loot item card opens (item mode, drawer open)
ZEDQA b11n2 shot 4_char_card_open
ZEDQA b11n2 156 tab mode with a card: tab=loot mode=item open=true card=true tabUnder=nil
ZEDQA b11n2 PASS 156 tab mode on Loot with a card up becomes the card (no tab drawer)
ZEDQA b11n2 156 card closed: tab=loot mode=nil open=false card=false tabUnder=nil
ZEDQA b11n2 PASS 156 closing the card folds the drawer (no half card left)
ZEDQA b11n2 shot 5_char_card_closed
ZEDQA b11n2 156 tab mode, nothing in it: tab=loot mode=nil open=false card=false tabUnder=nil
ZEDQA b11n2 PASS 156 Character: a tab drawer on Loot with nothing in it folds
ZEDQA b11n2 PASS 156 Character: no placeholder line drawn (0 seen, 12 texts)
ZEDQA b11n2 shot 6_char_folded
ZEDQA b11n2 156 World: tab=loot mode=nil open=false tabUnder=nil
ZEDQA b11n2 PASS 156 World: a tab drawer on Loot with nothing in it folds
ZEDQA b11n2 PASS 156 World: no Coming soon / placeholder line drawn (0 seen)
ZEDQA b11n2 shot 7_world_folded
ZEDQA b11n2 PASS 157 setup: a bare tile was found near the QA spot (923.5,13038.5)
ZEDQA b11n2 157 after the move: player 923.50,13038.50, square 923,13038
ZEDQA b11n2 157 floor container: floor, 0 item(s)
ZEDQA b11n2 PASS 157 setup: the floor tile under the character is empty (move the character to a bare tile if not)
ZEDQA b11n2 157 World, empty floor: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n2 PASS 157 World, empty floor: the empty list draws the key's words
ZEDQA b11n2 PASS 157 World, empty floor: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n2 shot 8_world_floor_empty
ZEDQA b11n2 PASS 157 setup: an empty crate was built beside the character
ERROR: General f:5662> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.WornItems.BodyLocation.isMultiItem()" because "location" is null at BodyLocationGroup.isMultiItem(BodyLocationGroup.java:119).
    Lua(Vanilla).pcall(spawnpoints.lua:440)
    Lua(Vanilla).add(spawnpoints.lua:440)
    Lua(Vanilla).drive(spawnpoints.lua:756)
ZEDQA b11n2 157 bag worn at nil: isEquipped false
ZEDQA b11n2 157 bag held instead: isEquipped true
ZEDQA b11n2 PASS 157 setup: an empty schoolbag is worn or held
ZEDQA b11n2 PASS 157 the crate has a stop in the World window's container strip
ZEDQA b11n2 PASS 157 the World list shows the crate
ZEDQA b11n2 157 World, empty crate: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n2 PASS 157 World, empty crate: the empty list draws the key's words
ZEDQA b11n2 PASS 157 World, empty crate: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n2 shot 9_world_crate_empty
ZEDQA b11n2 157 Character strip stops: Inventory, Angel Cross's Key Ring, Small Backpack
ZEDQA b11n2 PASS 157 the bag has a stop in the Character window's container strip
ZEDQA b11n2 157 Character active container: 3, viewed 3
ZEDQA b11n2 157 Character, empty bag: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n2 PASS 157 Character, empty bag: the empty list draws the key's words
ZEDQA b11n2 PASS 157 Character, empty bag: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n2 shot 10_char_bag_empty
ZEDQA b11n2 160 the item card's label uses T.textSec, its value T.text, its dim tags T.textDim (ItemCardOrganism / Atoms.drawSecondary)
ZEDQA b11n2 160 Dark teal: window 19,22,21 (surf1 alpha 0.90); body T.text 216,217,217 alpha 1.00 = 12.89:1; secondary T.textSec 147,167,162 = 7.18:1; dim T.textDim 150,151,151 = 6.23:1; over a white world: secondary 5.29:1, dim 4.59:1
ZEDQA b11n2 PASS 160 Dark/teal: body text >= 12:1 (12.89)
ZEDQA b11n2 PASS 160 Dark/teal: secondary text >= 7:1 within 0.1 (7.18)
ZEDQA b11n2 PASS 160 Dark/teal: dim text >= 4.5:1 (6.23)
ZEDQA b11n2 PASS 160 Dark/teal: secondary and dim >= 4.5:1 on the window over a white world (5.29 / 4.59)
ZEDQA b11n2 PASS 160 Dark/teal: the three tiers run body > secondary > dim
ZEDQA b11n2 shot 11_dark_teal_card
ZEDQA b11n2 PASS 160 the Orange accent exists
ZEDQA b11n2 160 Dark orange: window 23,21,19 (surf1 alpha 0.90); body T.text 218,217,215 alpha 1.00 = 12.87:1; secondary T.textSec 178,163,141 = 7.39:1; dim T.textDim 152,151,150 = 6.22:1; over a white world: secondary 5.44:1, dim 4.58:1
ZEDQA b11n2 PASS 160 Dark/orange: body text >= 12:1 (12.87)
ZEDQA b11n2 PASS 160 Dark/orange: secondary text >= 7:1 within 0.1 (7.39)
ZEDQA b11n2 PASS 160 Dark/orange: dim text >= 4.5:1 (6.22)
ZEDQA b11n2 PASS 160 Dark/orange: secondary and dim >= 4.5:1 on the window over a white world (5.44 / 4.58)
ZEDQA b11n2 PASS 160 Dark/orange: the three tiers run body > secondary > dim
ZEDQA b11n2 shot 12_dark_orange_card
ZEDQA b11n2 160 theme restored: dark / teal / small
ZEDQA b11n2 162 bottles: fluid=0.00 fluid=0.30 fluid=0.60 fluid=1.00
ZEDQA b11n2 PASS 162 setup: four bottles, one empty and the rest watered
ZEDQA b11n2 162 the player's list: grid sorted name asc (player)
ZEDQA b11n2 PASS 162 list: the water bottles are one stack of 6
ZEDQA b11n2 162 list not drawn: row y 736, list height 650, scroll 0, bars seen 6
ZEDQA b11n2 162 list: sort Cond ascending, the stack's head item holds 0.00, the emptiest holds 0.00, bar drawn none (row not drawn)
ZEDQA b11n2 PASS 162 list: the emptiest bottle is the empty one (0.00)
ZEDQA b11n2 FAIL 162 list: the stack's bar was drawn
ZEDQA b11n2 PASS 162 list: ItemMeter.ofStack says the same (0)
ZEDQA b11n2 shot 13_stack_list_asc
ZEDQA b11n2 PASS 162 list: the water bottles are one stack of 6
ZEDQA b11n2 162 list: sort Cond descending, the stack's head item holds 1.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n2 PASS 162 list: the emptiest bottle is the empty one (0.00)
ZEDQA b11n2 PASS 162 list: the stack's bar was drawn
ZEDQA b11n2 PASS 162 list: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n2 PASS 162 list: ItemMeter.ofStack says the same (0)
ZEDQA b11n2 shot 14_stack_list_desc
ZEDQA b11n2 PASS 162 grid: the water bottles are one stack of 6
ZEDQA b11n2 162 grid: sort Cond ascending, the stack's head item holds 0.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n2 PASS 162 grid: the emptiest bottle is the empty one (0.00)
ZEDQA b11n2 PASS 162 grid: the stack's bar was drawn
ZEDQA b11n2 PASS 162 grid: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n2 PASS 162 grid: ItemMeter.ofStack says the same (0)
ZEDQA b11n2 shot 15_stack_grid_asc
ZEDQA b11n2 PASS 162 grid: the water bottles are one stack of 6
ZEDQA b11n2 162 grid: sort Cond descending, the stack's head item holds 1.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n2 PASS 162 grid: the emptiest bottle is the empty one (0.00)
ZEDQA b11n2 PASS 162 grid: the stack's bar was drawn
ZEDQA b11n2 PASS 162 grid: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n2 PASS 162 grid: ItemMeter.ofStack says the same (0)
ZEDQA b11n2 shot 16_stack_grid_desc
ZEDQA b11n2 PASS 162 the stack opens into its own rows (6 bottle rows)
ZEDQA b11n2 162 open stack: head own 0.00 bar none; row own 0.00 bar none; row own 0.00 bar none; row own 0.30 bar none; row own 0.60 bar none; row own 1.00 bar none (the head row keeps the stack's bar as drawn)
ZEDQA b11n2 FAIL 162 each opened row's bar is its own bottle's level (0 of 5)
ZEDQA b11n2 shot 17_stack_open
ZEDQA b11n2 PASS cleanup: everything spawned is gone (0 left)
ZEDQA b11n2 cleanup: theme dark / teal / small, player's list grid
ZEDQA b11n2 RESULT 76 pass, 3 fail
ZEDQA b11n2 DONE
```

### 6. zedqa_b11_notes_r3.lua (`ZEDQA b11n3`) - FAIL, 39 s

- go 10005 at 12:15:13
- 1 Java exception(s) in the log
- 2 ERR line(s)
- screenshots: zqa_b11n3_3840x2160_1_hands_empty.png, zqa_b11n3_3840x2160_2_two_handed_peek.png, zqa_b11n3_3840x2160_3_hands_empty_again.png, zqa_b11n3_3840x2160_4_char_card_open.png, zqa_b11n3_3840x2160_5_char_card_closed.png, zqa_b11n3_3840x2160_6_char_folded.png, zqa_b11n3_3840x2160_7_world_folded.png, zqa_b11n3_3840x2160_8_world_floor_empty.png, zqa_b11n3_3840x2160_9_world_crate_empty.png, zqa_b11n3_3840x2160_10_char_bag_empty.png, zqa_b11n3_3840x2160_11_dark_teal_card.png, zqa_b11n3_3840x2160_12_dark_orange_card.png, zqa_b11n3_3840x2160_13_stack_list_asc.png, zqa_b11n3_3840x2160_14_stack_list_desc.png, zqa_b11n3_3840x2160_15_stack_grid_asc.png, zqa_b11n3_3840x2160_16_stack_grid_desc.png, zqa_b11n3_3840x2160_17_stack_open.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=40 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b11n3 screen 3840x2160
ZEDQA b11n3 start
[ZeD.QA] run #6 ok=true
ZEDQA b11n3 theme dark / teal / small
ZEDQA b11n3 PASS the belt's HUD is up
ZEDQA b11n3 PASS 155 the belt has a main hand and an off hand box
ZEDQA b11n3 PASS 155 empty hands: the main ring draws hand_right
ZEDQA b11n3 PASS 155 empty hands: the off ring draws hand_left
ZEDQA b11n3 PASS 155 the off ring's icon is the smaller (main 42 px, off 28 px)
ZEDQA b11n3 PASS 155 both icons dim (alpha 1 / 1, textDim 1)
ZEDQA b11n3 PASS 155 the icon color is textDim (not the accent)
ZEDQA b11n3 PASS 155 icon hand_right exists at 16
ZEDQA b11n3 PASS 155 icon hand_right exists at 24
ZEDQA b11n3 PASS 155 icon hand_right exists at 32
ZEDQA b11n3 PASS 155 icon hand_right exists at 48
ZEDQA b11n3 PASS 155 icon hand_left exists at 16
ZEDQA b11n3 PASS 155 icon hand_left exists at 24
ZEDQA b11n3 PASS 155 icon hand_left exists at 32
ZEDQA b11n3 PASS 155 icon hand_left exists at 48
ZEDQA b11n3 155 textures: hand_right@16=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\16\zw_hand_right.png(16) hand_right@24=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\24\zw_hand_right.png(24) hand_right@32=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\32\zw_hand_right.png(32) hand_right@48=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\48\zw_hand_right.png(48) hand_left@16=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\16\zw_hand_left.png(16) hand_left@24=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\24\zw_hand_left.png(24) hand_left@32=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\32\zw_hand_left.png(32) hand_left@48=%USERPROFILE%\ZomboidStaged\mods\ZeD-UI\42\media\textures\ZeD\wheel\48\zw_hand_left.png(48)
ZEDQA b11n3 155 drawn: right 116,28 box 42; left 24,34 box 28
ZEDQA b11n3 PASS 155 no hand word drawn in the rings (378 belt texts seen, 0 are a hand word)
ZEDQA b11n3 155 hint words: main 'Right Hand' off 'Left Hand'; the game's 'Right Hand' / 'Left Hand'
ZEDQA b11n3 PASS 155 the main hand's hint is the game's Right Hand
ZEDQA b11n3 PASS 155 the off hand's hint is the game's Left Hand
ZEDQA b11n3 PASS 155 the belt no longer says Primary / Secondary
ZEDQA b11n3 shot 1_hands_empty
ZEDQA b11n3 155 two-handed item: Base.Sledgehammer, isTwoHandWeapon true
ZEDQA b11n3 PASS 155 the two-handed item is in both hands
ZEDQA b11n3 PASS 155 the off ring is a peek (peek true, peekW 44 of 77)
ZEDQA b11n3 PASS 155 no empty-hand icon is drawn while one item fills both hands
ZEDQA b11n3 155 peek: main 25,98, off 0,77
ZEDQA b11n3 shot 2_two_handed_peek
ZEDQA b11n3 PASS 155 unequipped: both hand icons are back
ZEDQA b11n3 PASS 155 unequipped: the off ring is a ring again
ZEDQA b11n3 shot 3_hands_empty_again
ZEDQA b11n3 PASS 156 setup: the Character list shows the carried inventory with a hammer in it
ZEDQA b11n3 156 card open: tab=loot mode=item open=true card=true tabUnder=nil
ZEDQA b11n3 PASS 156 a Loot item card opens (item mode, drawer open)
ZEDQA b11n3 shot 4_char_card_open
ZEDQA b11n3 156 tab mode with a card: tab=loot mode=item open=true card=true tabUnder=nil
ZEDQA b11n3 PASS 156 tab mode on Loot with a card up becomes the card (no tab drawer)
ZEDQA b11n3 156 card closed: tab=loot mode=nil open=false card=false tabUnder=nil
ZEDQA b11n3 PASS 156 closing the card folds the drawer (no half card left)
ZEDQA b11n3 shot 5_char_card_closed
ZEDQA b11n3 156 tab mode, nothing in it: tab=loot mode=nil open=false card=false tabUnder=nil
ZEDQA b11n3 PASS 156 Character: a tab drawer on Loot with nothing in it folds
ZEDQA b11n3 PASS 156 Character: no placeholder line drawn (0 seen, 12 texts)
ZEDQA b11n3 shot 6_char_folded
ZEDQA b11n3 156 World: tab=loot mode=nil open=false tabUnder=nil
ZEDQA b11n3 PASS 156 World: a tab drawer on Loot with nothing in it folds
ZEDQA b11n3 PASS 156 World: no Coming soon / placeholder line drawn (0 seen)
ZEDQA b11n3 shot 7_world_folded
ZEDQA b11n3 PASS 157 setup: a bare tile was found near the QA spot (923.5,13038.5)
ZEDQA b11n3 157 after the move: player 923.50,13038.50, square 923,13038
ZEDQA b11n3 157 floor container: floor, 0 item(s)
ZEDQA b11n3 PASS 157 setup: the floor tile under the character is empty (move the character to a bare tile if not)
ZEDQA b11n3 157 World, empty floor: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n3 PASS 157 World, empty floor: the empty list draws the key's words
ZEDQA b11n3 PASS 157 World, empty floor: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n3 shot 8_world_floor_empty
ZEDQA b11n3 PASS 157 setup: an empty crate was built beside the character
ERROR: General f:7663> Lua(Vanilla).pcall> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.characters.WornItems.BodyLocation.isMultiItem()" because "location" is null at BodyLocationGroup.isMultiItem(BodyLocationGroup.java:119).
    Lua(Vanilla).pcall(spawnpoints.lua:440)
    Lua(Vanilla).add(spawnpoints.lua:440)
    Lua(Vanilla).drive(spawnpoints.lua:756)
ZEDQA b11n3 157 bag worn at nil: isEquipped false
ZEDQA b11n3 157 bag held instead: isEquipped true
ZEDQA b11n3 PASS 157 setup: an empty schoolbag is worn or held
ZEDQA b11n3 PASS 157 the crate has a stop in the World window's container strip
ZEDQA b11n3 PASS 157 the World list shows the crate
ZEDQA b11n3 157 World, empty crate: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n3 PASS 157 World, empty crate: the empty list draws the key's words
ZEDQA b11n3 PASS 157 World, empty crate: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n3 shot 9_world_crate_empty
ZEDQA b11n3 157 Character strip stops: Inventory, Angel Cross's Key Ring, Small Backpack
ZEDQA b11n3 PASS 157 the bag has a stop in the Character window's container strip
ZEDQA b11n3 157 Character active container: 3, viewed 3
ZEDQA b11n3 157 Character, empty bag: drawn 'Nothing here.', key UI_ZeD_Inv_Empty says 'Nothing here.'
ZEDQA b11n3 PASS 157 Character, empty bag: the empty list draws the key's words
ZEDQA b11n3 PASS 157 Character, empty bag: the words are Nothing here. (not Nothing in here.)
ZEDQA b11n3 shot 10_char_bag_empty
ZEDQA b11n3 160 the item card's label uses T.textSec, its value T.text, its dim tags T.textDim (ItemCardOrganism / Atoms.drawSecondary)
ZEDQA b11n3 160 Dark teal: window 19,22,21 (surf1 alpha 0.90); body T.text 216,217,217 alpha 1.00 = 12.89:1; secondary T.textSec 147,167,162 = 7.18:1; dim T.textDim 150,151,151 = 6.23:1; over a white world: secondary 5.29:1, dim 4.59:1
ZEDQA b11n3 PASS 160 Dark/teal: body text >= 12:1 (12.89)
ZEDQA b11n3 PASS 160 Dark/teal: secondary text >= 7:1 within 0.1 (7.18)
ZEDQA b11n3 PASS 160 Dark/teal: dim text >= 4.5:1 (6.23)
ZEDQA b11n3 PASS 160 Dark/teal: secondary and dim >= 4.5:1 on the window over a white world (5.29 / 4.59)
ZEDQA b11n3 PASS 160 Dark/teal: the three tiers run body > secondary > dim
ZEDQA b11n3 shot 11_dark_teal_card
ZEDQA b11n3 PASS 160 the Orange accent exists
ZEDQA b11n3 160 Dark orange: window 23,21,19 (surf1 alpha 0.90); body T.text 218,217,215 alpha 1.00 = 12.87:1; secondary T.textSec 178,163,141 = 7.39:1; dim T.textDim 152,151,150 = 6.22:1; over a white world: secondary 5.44:1, dim 4.58:1
ZEDQA b11n3 PASS 160 Dark/orange: body text >= 12:1 (12.87)
ZEDQA b11n3 PASS 160 Dark/orange: secondary text >= 7:1 within 0.1 (7.39)
ZEDQA b11n3 PASS 160 Dark/orange: dim text >= 4.5:1 (6.22)
ZEDQA b11n3 PASS 160 Dark/orange: secondary and dim >= 4.5:1 on the window over a white world (5.44 / 4.58)
ZEDQA b11n3 PASS 160 Dark/orange: the three tiers run body > secondary > dim
ZEDQA b11n3 shot 12_dark_orange_card
ZEDQA b11n3 160 theme restored: dark / teal / small
ZEDQA b11n3 162 bottles: fluid=0.00 fluid=0.30 fluid=0.60 fluid=1.00
ZEDQA b11n3 PASS 162 setup: four bottles, one empty and the rest watered
ZEDQA b11n3 162 the player's list: grid sorted name asc (player)
ZEDQA b11n3 PASS 162 list: the water bottles are one stack of 6
ZEDQA b11n3 162 list not drawn: row y 736, list height 650, scroll 0, bars seen 6
ZEDQA b11n3 162 list: sort Cond ascending, the stack's head item holds 0.00, the emptiest holds 0.00, bar drawn none (row not drawn)
ZEDQA b11n3 PASS 162 list: the emptiest bottle is the empty one (0.00)
ZEDQA b11n3 FAIL 162 list: the stack's bar was drawn
ZEDQA b11n3 PASS 162 list: ItemMeter.ofStack says the same (0)
ZEDQA b11n3 shot 13_stack_list_asc
ZEDQA b11n3 PASS 162 list: the water bottles are one stack of 6
ZEDQA b11n3 162 list: sort Cond descending, the stack's head item holds 1.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n3 PASS 162 list: the emptiest bottle is the empty one (0.00)
ZEDQA b11n3 PASS 162 list: the stack's bar was drawn
ZEDQA b11n3 PASS 162 list: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n3 PASS 162 list: ItemMeter.ofStack says the same (0)
ZEDQA b11n3 shot 14_stack_list_desc
ZEDQA b11n3 PASS 162 grid: the water bottles are one stack of 6
ZEDQA b11n3 162 grid: sort Cond ascending, the stack's head item holds 0.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n3 PASS 162 grid: the emptiest bottle is the empty one (0.00)
ZEDQA b11n3 PASS 162 grid: the stack's bar was drawn
ZEDQA b11n3 PASS 162 grid: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n3 PASS 162 grid: ItemMeter.ofStack says the same (0)
ZEDQA b11n3 shot 15_stack_grid_asc
ZEDQA b11n3 PASS 162 grid: the water bottles are one stack of 6
ZEDQA b11n3 162 grid: sort Cond descending, the stack's head item holds 1.00, the emptiest holds 0.00, bar drawn 0.00
ZEDQA b11n3 PASS 162 grid: the emptiest bottle is the empty one (0.00)
ZEDQA b11n3 PASS 162 grid: the stack's bar was drawn
ZEDQA b11n3 PASS 162 grid: the bar reads the emptiest (drawn 0.00, wanted 0.00)
ZEDQA b11n3 PASS 162 grid: ItemMeter.ofStack says the same (0)
ZEDQA b11n3 shot 16_stack_grid_desc
ZEDQA b11n3 PASS 162 the stack opens into its own rows (6 bottle rows)
ZEDQA b11n3 162 open stack: head own 0.00 bar none; row own 0.00 bar none; row own 0.00 bar none; row own 0.30 bar none; row own 0.60 bar none; row own 1.00 bar none (the head row keeps the stack's bar as drawn)
ZEDQA b11n3 FAIL 162 each opened row's bar is its own bottle's level (0 of 5)
ZEDQA b11n3 shot 17_stack_open
ZEDQA b11n3 PASS cleanup: everything spawned is gone (0 left)
ZEDQA b11n3 cleanup: theme dark / teal / small, player's list grid
ZEDQA b11n3 RESULT 77 pass, 2 fail
ZEDQA b11n3 DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
