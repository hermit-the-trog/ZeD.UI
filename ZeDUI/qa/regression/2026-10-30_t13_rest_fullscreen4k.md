# ZeD-UI regression - 2026-10-30 11:00 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-30 11:00:35 |
| Finished | 2026-10-30 11:07:08 (6 min 32 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | t13_rest.txt (5 scripts) |
| Result | **3/5 pass**, 2 warn, 0 fail, 0 timeout |
| Go numbers | 16534 to 16540 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 16539, 16540)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_world_pad_take.lua | wpt | WARN | 62 |  | 1 ERR line(s) |
| 3 | zedqa_px_icons.lua | px | PASS | 5 | zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png |  |
| 4 | zedqa_two_widths.lua | tww | PASS | 77 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png |  |
| 5 | zedqa_dash_green.lua | dgr | WARN | 118 | zqa_dgr_d6_parked_day.png, zqa_dgr_d6_parked_day_keyin.png, zqa_dgr_dashelite_night_on.png, zqa_dgr_dashelite_night_off.png, zqa_dgr_primani_night_on.png, zqa_dgr_primani_night_off.png, zqa_dgr_suv_night_on.png, zqa_dgr_suv_night_off.png, zqa_dgr_luxury_night_on.png, zqa_dgr_luxury_night_off.png, zqa_dgr_cossette_night_on.png, zqa_dgr_cossette_night_off.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 16534 at 11:01:56

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 903,13164,0 to the drag strip
ZEDQA pre clock 23.62 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:349 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:356 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_world_pad_take.lua (`ZEDQA wpt`) - WARN, 62 s

- go 16535 at 11:02:04
- 1 ERR line(s)

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #2 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@100
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldContainerStrip:container:2
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldContainerStrip:container:2
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:2
ZEDQA wpt PASS on the strip, focus is on the container on show (the ground)
ZEDQA wpt 2 Down x1: World worldContainerStrip:container:1
ZEDQA wpt PASS Down from the ground reaches the crate (1 presses)
ZEDQA wpt 2 after A on the crate: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS A on the crate puts focus on its first item, lit
ZEDQA wpt 2 Left: World worldContainerStrip:container:1
ZEDQA wpt PASS Left from the list lands on the crate (the container on show)
ZEDQA wpt 2 Right: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS Right goes back to the same row
ZEDQA wpt 2 Left from a lower row: World worldContainerStrip:container:1
ZEDQA wpt PASS Left from a lower row lands on the crate too
ZEDQA wpt PASS and Right goes back to that row
ZEDQA wpt 3 timing: card buttons ready after 8 ticks, 7 frames; focus in the card after 8 ticks, 7 frames (watched 8 ticks, 7 frames)
ZEDQA wpt 3 A on the bandage: World worldItemCard:hverb_1
ZEDQA wpt PASS 3 A on the bandage: focus is on the card's primary action (TAKE)
ZEDQA wpt 3 Down in the card: World worldItemCard:name_row
ZEDQA wpt PASS Down moves to the card's next control
ZEDQA wpt 3 Up: World worldItemCard:hverb_1
ZEDQA wpt PASS Up from inside the card is back on the primary action in one press
ZEDQA wpt 3 after B: World worldMainInv:invrow:4 (Tweezers)
ZEDQA wpt PASS B closes the card and focus is back on the bandage row, lit
ZEDQA wpt 4 A on the nails: World worldItemCard:hverb_1
ZEDQA wpt PASS 4 A on the nails: focus is on the card's primary action (TAKE)
ZEDQA wpt PASS the nails' card offers Take as its primary action
ZEDQA wpt PASS A on Take moved the nails into the bag (vanilla's transfer, 10 ticks)
ZEDQA wpt 4 after the take: World worldMainInv:invrow:3 (Tweezers)
ZEDQA wpt 5 before the padlock card: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt 5 the padlock card: World worldItemCard:oc:verb:usecombo
ZEDQA wpt PASS the object card opens with focus on its main live verb (oc:verb:usecombo)
ZEDQA wpt PASS A on it ran the verb (the padlock's code wheel shows)
ZEDQA wpt 5 after B: World worldMainInv:invrow:1 (Apple (Fresh))
ZEDQA wpt PASS B closes the object card and focus is back in the list, lit
ZEDQA wpt 6 Left from the World window's strip: Char charContainerStrip:container:1
ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
ZEDQA wpt 6 LB: Char charContainerStrip:container:1
ZEDQA wpt PASS LB lands in the Character window on a lit element
ZEDQA wpt 6 Right: Char charMainInv:invrow:10 (Flier: Fossoil (West Point): Fossoil (West Point))
ZEDQA wpt FAIL Right from a row lands on the bag on show
ZEDQA wpt PASS Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on the nails: focus is on the card's primary action (DROP)
ZEDQA wpt PASS Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is DROP; A runs it
ZEDQA wpt PASS A on the card's primary action (Drop) moved the nails out of the bag (10 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (USE)
ZEDQA wpt 6 after B: Char charMainInv:invrow:6 (Cigarette Pack)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt PASS 8 X on a row opens the context menu
ZEDQA wpt 8 after the menu's B: World worldMainInv:invrow:2 (Corkscrew)
ZEDQA wpt PASS 8 the menu closed: focus is back on the same row, lit
ZEDQA wpt 8 after hold A: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 hold A moved the hammer out of the crate
ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt 7 tabs: 13 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 639 of 650)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 624 of 650)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column exercise:time:dec and it is in view (bottom 526 of 650)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 526 of 650)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 958 px in a 585 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:__gridscroll and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 650 of 650)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 564 of 650)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 564 of 650)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:group:6_1993 and it is in view (bottom 443 of 650)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 443 of 650)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 634 of 650)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:row:AddACigarette and it is in view (bottom 296 of 650)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:row:AddACigarette is in view at the bottom (bottom 296 of 650)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:section:all and it is in view (bottom 126 of 650)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:section:all is in view at the bottom (bottom 126 of 650)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 121 of 650)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 121 of 650)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:canvas:cursor and it is in view (bottom 650 of 650)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 650 of 650)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:disclosure and it is in view (bottom 344 of 650)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:disclosure is in view at the bottom (bottom 344 of 650)
ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 World vehicle small pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 641 of 650)
ZEDQA wpt PASS 7 World vehicle small wheel: the lowest control mech:inspect is in view at the bottom (bottom 641 of 650)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 620 of 638)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 610 of 638)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column bodypart:Left Foot and it is in view (bottom 149 of 638)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 152 of 638)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 1013 px in a 564 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:__gridscroll and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 638 of 638)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 541 of 638)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 541 of 638)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:group:6_1993 and it is in view (bottom 504 of 638)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 476 of 638)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 620 of 638)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:row:AddACigarette and it is in view (bottom 338 of 638)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:row:AddACigarette is in view at the bottom (bottom 338 of 638)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:section:all and it is in view (bottom 144 of 638)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:section:all is in view at the bottom (bottom 144 of 638)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 138 of 638)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 138 of 638)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:canvas:cursor and it is in view (bottom 638 of 638)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 638 of 638)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:disclosure and it is in view (bottom 393 of 638)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:disclosure is in view at the bottom (bottom 393 of 638)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 628 of 638)
ZEDQA wpt PASS 7 World vehicle large pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 628 of 638)
ZEDQA wpt PASS 7 World vehicle large wheel: the lowest control mech:inspect is in view at the bottom (bottom 628 of 638)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 92 passed, 1 failed
ZEDQA wpt DONE
```

### 3. zedqa_px_icons.lua (`ZEDQA px`) - PASS, 5 s

- go 16536 at 11:03:10
- screenshots: zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png

```text
[ZeD.QA] windows reset (R)
ZEDQA px scale 1.75: the 16-unit icon box is 28 px, the drawing for it 24
ZEDQA px ok 29 icons, four drawings each, the box picks 24
ZEDQA px ok a licensed name is no pixel icon (the row falls back to words, not a picture)
ZEDQA px ok the wheels use the same lookup
[ZeD.QA] run #3 ok=true
ZEDQA px shot zqa_px_panel
ZEDQA px ok the test panel drew
ZEDQA px ok the card opened on Digital Watch
ZEDQA px shot zqa_px_card
ZEDQA px card toggle rects nil
ZEDQA px shot zqa_px_rows
ZEDQA px ok Fav put back
ZEDQA px DONE 0 failed
```

### 4. zedqa_two_widths.lua (`ZEDQA tww`) - PASS, 77 s

- go 16537 at 11:03:18
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #4 ok=true
ZEDQA tww screen 3840x2160, root 1.75, half card 385 px, full card 840 px
ZEDQA tww to the deep run's home, 10608,11151
ZEDQA tww the pair at the start: Character 1134,0 777x735, World 1929,0 777x735
ZEDQA tww PASS the pair starts apart
ZEDQA tww 13 tab cases
ZEDQA tww Character equip: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character equip: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character equip: it is the full card (full)
ZEDQA tww PASS Character equip: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character equip: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character equip: both windows are on the screen
ZEDQA tww PASS Character equip: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character equip: closed, the other window is where it was
ZEDQA tww Character health: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character health: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character health: it is the full card (full)
ZEDQA tww PASS Character health: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character health: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character health: both windows are on the screen
ZEDQA tww PASS Character health: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character health: closed, the other window is where it was
ZEDQA tww Character thermal: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character thermal: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character thermal: it is the full card (full)
ZEDQA tww PASS Character thermal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character thermal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character thermal: both windows are on the screen
ZEDQA tww PASS Character thermal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character thermal: closed, the other window is where it was
ZEDQA tww Character identity: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character identity: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character identity: it is the full card (full)
ZEDQA tww PASS Character identity: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character identity: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character identity: both windows are on the screen
ZEDQA tww PASS Character identity: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character identity: closed, the other window is where it was
ZEDQA tww Character journal: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character journal: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character journal: it is the full card (full)
ZEDQA tww PASS Character journal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character journal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character journal: both windows are on the screen
ZEDQA tww PASS Character journal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character journal: closed, the other window is where it was
ZEDQA tww Character skills: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character skills: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character skills: it is the full card (full)
ZEDQA tww PASS Character skills: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character skills: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character skills: both windows are on the screen
ZEDQA tww PASS Character skills: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character skills: closed, the other window is where it was
ZEDQA tww World craft: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World craft: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World craft: it is the full card (full)
ZEDQA tww PASS World craft: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World craft: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World craft: both windows are on the screen
ZEDQA tww PASS World craft: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World craft: closed, the other window is where it was
ZEDQA tww World build: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World build: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World build: it is the full card (full)
ZEDQA tww PASS World build: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World build: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World build: both windows are on the screen
ZEDQA tww PASS World build: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World build: closed, the other window is where it was
ZEDQA tww World furniture: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World furniture: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World furniture: it is the full card (full)
ZEDQA tww PASS World furniture: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World furniture: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World furniture: both windows are on the screen
ZEDQA tww PASS World furniture: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World furniture: closed, the other window is where it was
ZEDQA tww World maps: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World maps: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World maps: it is the full card (full)
ZEDQA tww PASS World maps: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World maps: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World maps: both windows are on the screen
ZEDQA tww PASS World maps: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World maps: closed, the other window is where it was
ZEDQA tww World forage: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World forage: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World forage: it is the full card (full)
ZEDQA tww PASS World forage: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World forage: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World forage: both windows are on the screen
ZEDQA tww PASS World forage: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World forage: closed, the other window is where it was
ZEDQA tww World animals: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World animals: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World animals: it is the full card (full)
ZEDQA tww PASS World animals: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World animals: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World animals: both windows are on the screen
ZEDQA tww PASS World animals: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World animals: closed, the other window is where it was
ZEDQA tww World vehicle: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World vehicle: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World vehicle: it is the full card (full)
ZEDQA tww PASS World vehicle: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World vehicle: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World vehicle: both windows are on the screen
ZEDQA tww PASS World vehicle: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World vehicle: closed, the other window is where it was
ZEDQA tww an oven placed: true
ZEDQA tww a generator placed: true
ZEDQA tww a ham set placed: true
ZEDQA tww 25 more cases
ZEDQA tww Character Equip to-do: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Equip to-do: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Equip to-do: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Equip to-do: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Equip to-do: both windows are on the screen
ZEDQA tww PASS Character Equip to-do: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Equip to-do: closed, the other window is where it was
ZEDQA tww Character Journal Loadouts page: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal Loadouts page: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal Loadouts page: it is the full card (full)
ZEDQA tww PASS Character Journal Loadouts page: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal Loadouts page: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal Loadouts page: both windows are on the screen
ZEDQA tww PASS Character Journal Loadouts page: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal Loadouts page: closed, the other window is where it was
ZEDQA tww Character Journal page 1: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 1: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 1: it is the full card (full)
ZEDQA tww PASS Character Journal page 1: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 1: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 1: both windows are on the screen
ZEDQA tww PASS Character Journal page 1: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 1: closed, the other window is where it was
ZEDQA tww Character Journal page 2: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 2: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 2: it is the full card (full)
ZEDQA tww PASS Character Journal page 2: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 2: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 2: both windows are on the screen
ZEDQA tww PASS Character Journal page 2: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 2: closed, the other window is where it was
ZEDQA tww Character Journal page 3: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 3: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 3: it is the full card (full)
ZEDQA tww PASS Character Journal page 3: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 3: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 3: both windows are on the screen
ZEDQA tww PASS Character Journal page 3: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 3: closed, the other window is where it was
ZEDQA tww Character Journal page 4: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 4: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 4: it is the full card (full)
ZEDQA tww PASS Character Journal page 4: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 4: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 4: both windows are on the screen
ZEDQA tww PASS Character Journal page 4: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 4: closed, the other window is where it was
ZEDQA tww Character Journal page 5: drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Journal page 5: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Journal page 5: it is the full card (full)
ZEDQA tww PASS Character Journal page 5: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Journal page 5: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Journal page 5: both windows are on the screen
ZEDQA tww PASS Character Journal page 5: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Journal page 5: closed, the other window is where it was
ZEDQA tww World item card: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1162x735
ZEDQA tww PASS World item card: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS World item card: it is the half card (half)
ZEDQA tww PASS World item card: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World item card: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World item card: both windows are on the screen
ZEDQA tww PASS World item card: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World item card: closed, the other window is where it was
ZEDQA tww Character item card: drawer 385 px = half | Character 749,0 1162x735 | World 1929,0 777x735
ZEDQA tww PASS Character item card: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS Character item card: it is the half card (half)
ZEDQA tww PASS Character item card: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character item card: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character item card: both windows are on the screen
ZEDQA tww PASS Character item card: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character item card: closed, the other window is where it was
ZEDQA tww World object card fluid: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World object card fluid: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World object card fluid: it is the full card (full)
ZEDQA tww PASS World object card fluid: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World object card fluid: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World object card fluid: both windows are on the screen
ZEDQA tww PASS World object card fluid: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World object card fluid: closed, the other window is where it was
ZEDQA tww World object card generator: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World object card generator: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World object card generator: it is the full card (full)
ZEDQA tww PASS World object card generator: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World object card generator: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World object card generator: both windows are on the screen
ZEDQA tww PASS World object card generator: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World object card generator: closed, the other window is where it was
ZEDQA tww World object card place3d: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World object card place3d: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World object card place3d: it is the full card (full)
ZEDQA tww PASS World object card place3d: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World object card place3d: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World object card place3d: both windows are on the screen
ZEDQA tww PASS World object card place3d: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World object card place3d: closed, the other window is where it was
ZEDQA tww World Craft at an oven: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Craft at an oven: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Craft at an oven: it is the full card (full)
ZEDQA tww PASS World Craft at an oven: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Craft at an oven: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Craft at an oven: both windows are on the screen
ZEDQA tww PASS World Craft at an oven: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Craft at an oven: closed, the other window is where it was
ZEDQA tww World Craft (no station): drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Craft (no station): the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Craft (no station): it is the full card (full)
ZEDQA tww PASS World Craft (no station): the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Craft (no station): the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Craft (no station): both windows are on the screen
ZEDQA tww PASS World Craft (no station): closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Craft (no station): closed, the other window is where it was
ZEDQA tww Character Radio (a walkie): drawer 840 px = full | Character 294,0 1617x735 | World 1929,0 777x735
ZEDQA tww PASS Character Radio (a walkie): the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS Character Radio (a walkie): the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS Character Radio (a walkie): the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS Character Radio (a walkie): both windows are on the screen
ZEDQA tww PASS Character Radio (a walkie): closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS Character Radio (a walkie): closed, the other window is where it was
ZEDQA tww World Radio (a ham set): drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Radio (a ham set): the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Radio (a ham set): the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Radio (a ham set): the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Radio (a ham set): both windows are on the screen
ZEDQA tww PASS World Radio (a ham set): closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Radio (a ham set): closed, the other window is where it was
ZEDQA tww World Maps: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Maps: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Maps: it is the full card (full)
ZEDQA tww PASS World Maps: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Maps: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Maps: both windows are on the screen
ZEDQA tww PASS World Maps: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Maps: closed, the other window is where it was
ZEDQA tww World Maps pop-out: drawer 840 px = full | Character 1134,0 777x735 | World 1929,0 1617x735
ZEDQA tww PASS World Maps pop-out: the drawer is the half card or the full card (840 px; half 385, full 840)
ZEDQA tww PASS World Maps pop-out: it is the full card (full)
ZEDQA tww PASS World Maps pop-out: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS World Maps pop-out: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS World Maps pop-out: both windows are on the screen
ZEDQA tww the pop-out 538,238 2764x1684: over the Character window true, over the World window true (it is a window of its own, centred)
ZEDQA tww PASS World Maps pop-out: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS World Maps pop-out: closed, the other window is where it was
ZEDQA tww 15 held-in cases
ZEDQA tww held in: Character equip: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character equip: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character equip: it is the half card (half)
ZEDQA tww PASS held in: Character equip: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character equip: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character equip: both windows are on the screen
ZEDQA tww PASS held in: Character equip: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character equip: closed, the other window is where it was
ZEDQA tww held in: Character health: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character health: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character health: it is the half card (half)
ZEDQA tww PASS held in: Character health: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character health: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character health: both windows are on the screen
ZEDQA tww PASS held in: Character health: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character health: closed, the other window is where it was
ZEDQA tww held in: Character thermal: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character thermal: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character thermal: it is the half card (half)
ZEDQA tww PASS held in: Character thermal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character thermal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character thermal: both windows are on the screen
ZEDQA tww PASS held in: Character thermal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character thermal: closed, the other window is where it was
ZEDQA tww held in: Character identity: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character identity: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character identity: it is the half card (half)
ZEDQA tww PASS held in: Character identity: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character identity: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character identity: both windows are on the screen
ZEDQA tww PASS held in: Character identity: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character identity: closed, the other window is where it was
ZEDQA tww held in: Character journal: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character journal: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character journal: it is the half card (half)
ZEDQA tww PASS held in: Character journal: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character journal: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character journal: both windows are on the screen
ZEDQA tww PASS held in: Character journal: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character journal: closed, the other window is where it was
ZEDQA tww held in: Character skills: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character skills: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character skills: it is the half card (half)
ZEDQA tww PASS held in: Character skills: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character skills: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character skills: both windows are on the screen
ZEDQA tww PASS held in: Character skills: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character skills: closed, the other window is where it was
ZEDQA tww held in: Character radio: drawer 385 px = half | Character 910,0 1001x735 | World 1929,0 777x735
ZEDQA tww PASS held in: Character radio: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: Character radio: it is the half card (half)
ZEDQA tww PASS held in: Character radio: the other window did not move or change size (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: Character radio: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: Character radio: both windows are on the screen
ZEDQA tww PASS held in: Character radio: closed, the window is back where and as wide as it was (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: Character radio: closed, the other window is where it was
ZEDQA tww held in: World craft: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World craft: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World craft: it is the half card (half)
ZEDQA tww PASS held in: World craft: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World craft: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World craft: both windows are on the screen
ZEDQA tww PASS held in: World craft: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World craft: closed, the other window is where it was
ZEDQA tww held in: World build: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World build: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World build: it is the half card (half)
ZEDQA tww PASS held in: World build: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World build: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World build: both windows are on the screen
ZEDQA tww PASS held in: World build: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World build: closed, the other window is where it was
ZEDQA tww held in: World furniture: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World furniture: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World furniture: it is the half card (half)
ZEDQA tww PASS held in: World furniture: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World furniture: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World furniture: both windows are on the screen
ZEDQA tww PASS held in: World furniture: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World furniture: closed, the other window is where it was
ZEDQA tww held in: World maps: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World maps: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World maps: it is the half card (half)
ZEDQA tww PASS held in: World maps: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World maps: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World maps: both windows are on the screen
ZEDQA tww PASS held in: World maps: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World maps: closed, the other window is where it was
ZEDQA tww held in: World forage: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World forage: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World forage: it is the half card (half)
ZEDQA tww PASS held in: World forage: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World forage: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World forage: both windows are on the screen
ZEDQA tww PASS held in: World forage: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World forage: closed, the other window is where it was
ZEDQA tww held in: World animals: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World animals: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World animals: it is the half card (half)
ZEDQA tww PASS held in: World animals: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World animals: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World animals: both windows are on the screen
ZEDQA tww PASS held in: World animals: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World animals: closed, the other window is where it was
ZEDQA tww held in: World radio: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World radio: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World radio: it is the half card (half)
ZEDQA tww PASS held in: World radio: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World radio: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World radio: both windows are on the screen
ZEDQA tww PASS held in: World radio: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World radio: closed, the other window is where it was
ZEDQA tww held in: World vehicle: drawer 385 px = half | Character 1134,0 777x735 | World 1929,0 1001x735
ZEDQA tww PASS held in: World vehicle: the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS held in: World vehicle: it is the half card (half)
ZEDQA tww PASS held in: World vehicle: the other window did not move or change size (1134,0 777x735 -> 1134,0 777x735)
ZEDQA tww PASS held in: World vehicle: the windows do not overlap (Character ends at 1911, World starts at 1929)
ZEDQA tww PASS held in: World vehicle: both windows are on the screen
ZEDQA tww PASS held in: World vehicle: closed, the window is back where and as wide as it was (1929,0 777x735 -> 1929,0 777x735)
ZEDQA tww PASS held in: World vehicle: closed, the other window is where it was
ERROR: General f:13950 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:13958 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA tww PASS after the whole run both windows are where and as big as they were (1134,0 777x735 / 1929,0 777x735 -> 1134,0 777x735 / 1929,0 777x735)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card lock, World object card plant, World object card track, World object card trough
ZEDQA tww ALL PASS
ZEDQA tww DONE
```

### 5. zedqa_dash_green.lua (`ZEDQA dgr`) - WARN, 118 s

- go 16538 at 11:04:39
- 1 ERR line(s)
- screenshots: zqa_dgr_d6_parked_day.png, zqa_dgr_d6_parked_day_keyin.png, zqa_dgr_dashelite_night_on.png, zqa_dgr_dashelite_night_off.png, zqa_dgr_primani_night_on.png, zqa_dgr_primani_night_off.png, zqa_dgr_suv_night_on.png, zqa_dgr_suv_night_off.png, zqa_dgr_luxury_night_on.png, zqa_dgr_luxury_night_off.png, zqa_dgr_cossette_night_on.png, zqa_dgr_cossette_night_off.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #5 ok=true
ZEDQA dgr d6 speedometer pivot 240,96 r1=60 a0=210 a1=330
ZEDQA dgr shot d6_parked_day design=d6 rect=1120,1804,1600,356 k=2 n8=0 lit=false tmap=false needleOwn=nil lights=false running=false kmh=0.0 mph=0.0
ZEDQA dgr shot d6_parked_day_keyin design=d6 rect=1120,1804,1600,356 k=2 n8=0 lit=false tmap=false needleOwn=nil lights=false running=false kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=1 push=100 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=2 push=200 kmh=2.1 mph=1.3
ZEDQA dgr fire drive t=3 push=400 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=4 push=800 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=5 push=1600 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=6 push=3200 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=7 push=6400 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=8 push=12800 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=9 push=25600 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=10 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=11 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=12 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=13 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=14 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=15 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=16 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=17 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=18 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drive t=19 push=50000 kmh=0.0 mph=0.0
ZEDQA dgr fire drove: max 2.1 km/h
ZEDQA dgr ERR fire never reached 64 km/h (max 2.1)
ZEDQA dgr shot dashelite_night_on design=dashelite rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot dashelite_night_off design=dashelite rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA dgr shot primani_night_on design=primani rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot primani_night_off design=primani rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA dgr shot suv_night_on design=suv rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot suv_night_off design=suv rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA dgr shot luxury_night_on design=luxury rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=true lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot luxury_night_off design=luxury rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=true lights=false running=true kmh=0.0 mph=0.0
ZEDQA dgr shot cossette_night_on design=cossette rect=1120,1804,1600,356 k=2 n8=8 lit=true tmap=true needleOwn=nil lights=true running=true kmh=0.0 mph=0.0
ZEDQA dgr shot cossette_night_off design=cossette rect=1120,1804,1600,356 k=2 n8=8 lit=false tmap=true needleOwn=nil lights=false running=true kmh=0.0 mph=0.0
ZEDQA dgr errors 1
ZEDQA dgr DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
