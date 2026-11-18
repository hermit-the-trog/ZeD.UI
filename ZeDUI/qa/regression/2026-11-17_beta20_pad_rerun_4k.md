# ZeD-UI regression - 2026-11-17 23:23 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 23:23:59 |
| Finished | 2026-11-17 23:26:13 (2 min 14 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b20_pad_rerun.txt (4 scripts) |
| Result | **1/4 pass**, 3 warn, 0 fail, 0 timeout |
| Go numbers | 29180 to 29185 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29184, 29185)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_navmap.lua | nav | WARN | 16 |  | 42 ERR line(s) |
| 3 | zedqa_world_pad_take.lua | wpt | WARN | 11 |  | 1 ERR line(s) |
| 4 | zedqa_cov_input.lua | cov_input | WARN | 11 | zqa_cin_icons.png, zqa_cin_pad_world.png, zqa_cin_zoomed_in.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29180 at 23:25:01

```text
[ZeD.QA] state #1 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_navmap.lua (`ZEDQA nav`) - WARN, 16 s

- go 29181 at 23:25:06
- 42 ERR line(s)

```text
[ZeD.QA] state #2 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA nav start
[ZeD.QA] run #2 ok=true
ZEDQA nav char loot: 45 targets | TRAP 3 {halfpin:drawer,halfpin:inv,windowbox} | ISLAND 0 {}
ZEDQA nav char loot STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) invrow:29(D) container:1(D) charCtl:xfer(D) charCtl:same(D) charCtl:near(D) halfpin:drawer(U) halfpin:inv(U) windowbox(U)
ZEDQA nav FAIL trap: char loot trap halfpin:drawer
ZEDQA nav FAIL trap: char loot trap halfpin:inv
ZEDQA nav FAIL trap: char loot trap windowbox
ZEDQA nav char equip: 80 targets | TRAP 3 {halfpin:drawer,halfpin:inv,windowbox} | ISLAND 0 {}
ZEDQA nav char equip STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) equippart:Right Foot(D) equippart:Left Foot(D) invrow:29(D) container:1(D) charCtl:xfer(D) charCtl:same(D) charCtl:near(D) halfpin:drawer(U) halfpin:inv(U) windowbox(U)
ZEDQA nav FAIL trap: char equip trap halfpin:drawer
ZEDQA nav FAIL trap: char equip trap halfpin:inv
ZEDQA nav FAIL trap: char equip trap windowbox
ZEDQA nav char health: 67 targets | TRAP 3 {halfpin:drawer,halfpin:inv,windowbox} | ISLAND 0 {}
ZEDQA nav char health STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) health:exercise(D) health:time:dec(D) health:time:inc(D) health:start(D) invrow:29(D) container:1(D) charCtl:xfer(D) charCtl:same(D) charCtl:near(D) halfpin:drawer(U) halfpin:inv(U) windowbox(U)
ZEDQA nav FAIL trap: char health trap halfpin:drawer
ZEDQA nav FAIL trap: char health trap halfpin:inv
ZEDQA nav FAIL trap: char health trap windowbox
ZEDQA nav char thermal: 64 targets | TRAP 3 {halfpin:drawer,halfpin:inv,windowbox} | ISLAND 0 {}
ZEDQA nav char thermal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) thermal:view(D) invrow:29(D) container:1(D) charCtl:xfer(D) charCtl:same(D) charCtl:near(D) halfpin:drawer(U) halfpin:inv(U) windowbox(U)
ZEDQA nav FAIL trap: char thermal trap halfpin:drawer
ZEDQA nav FAIL trap: char thermal trap halfpin:inv
ZEDQA nav FAIL trap: char thermal trap windowbox
ZEDQA nav char identity: 97 targets | TRAP 3 {halfpin:drawer,halfpin:inv,windowbox} | ISLAND 0 {}
ZEDQA nav char identity STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) identity:trait:Smoker(D) invrow:29(D) container:1(D) charCtl:xfer(D) charCtl:same(D) charCtl:near(D) halfpin:drawer(U) halfpin:inv(U) windowbox(U)
ZEDQA nav FAIL trap: char identity trap halfpin:drawer
ZEDQA nav FAIL trap: char identity trap halfpin:inv
ZEDQA nav FAIL trap: char identity trap windowbox
ZEDQA nav char journal: 65 targets | TRAP 3 {halfpin:drawer,halfpin:inv,windowbox} | ISLAND 0 {}
ZEDQA nav char journal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) journal:__save(D) invrow:29(D) container:1(D) charCtl:xfer(D) charCtl:same(D) charCtl:near(D) halfpin:drawer(U) halfpin:inv(U) windowbox(U)
ZEDQA nav FAIL trap: char journal trap halfpin:drawer
ZEDQA nav FAIL trap: char journal trap halfpin:inv
ZEDQA nav FAIL trap: char journal trap windowbox
ZEDQA nav char skills: 106 targets | TRAP 3 {halfpin:drawer,halfpin:inv,windowbox} | ISLAND 0 {}
ZEDQA nav char skills STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(DL) training:col1_Foraging(D) training:col2_MetalWelding(D) invrow:29(D) container:1(D) charCtl:xfer(D) charCtl:same(D) charCtl:near(D) halfpin:drawer(U) halfpin:inv(U) windowbox(U)
ZEDQA nav FAIL trap: char skills trap halfpin:drawer
ZEDQA nav FAIL trap: char skills trap halfpin:inv
ZEDQA nav FAIL trap: char skills trap windowbox
ZEDQA nav world loot: 18 targets | TRAP 3 {halfpin:inv,halfpin:drawer,windowbox} | ISLAND 0 {}
ZEDQA nav world loot STUCK: container:1(D) tab:loot(R) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(DR) worldCtl:take(D) worldCtl:same(D) halfpin:inv(U) halfpin:drawer(U) windowbox(UR)
ZEDQA nav FAIL trap: world loot trap halfpin:inv
ZEDQA nav FAIL trap: world loot trap halfpin:drawer
ZEDQA nav FAIL trap: world loot trap windowbox
ZEDQA nav world craft: 27 targets | TRAP 3 {halfpin:inv,halfpin:drawer,windowbox} | ISLAND 0 {}
ZEDQA nav world craft STUCK: container:1(D) craft:sortMenu(D) craft:showMenu(D) tab:loot(R) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(DR) worldCtl:take(D) worldCtl:same(D) halfpin:inv(U) halfpin:drawer(U) windowbox(UR)
ZEDQA nav FAIL trap: world craft trap halfpin:inv
ZEDQA nav FAIL trap: world craft trap halfpin:drawer
ZEDQA nav FAIL trap: world craft trap windowbox
ZEDQA nav world build: 30 targets | TRAP 3 {halfpin:inv,halfpin:drawer,windowbox} | ISLAND 0 {}
ZEDQA nav world build STUCK: container:1(D) build:sortMenu(D) build:showMenu(D) tab:loot(R) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(DR) worldCtl:take(D) worldCtl:same(D) halfpin:inv(U) halfpin:drawer(U) windowbox(UR)
ZEDQA nav FAIL trap: world build trap halfpin:inv
ZEDQA nav FAIL trap: world build trap halfpin:drawer
ZEDQA nav FAIL trap: world build trap windowbox
ZEDQA nav world furniture: 23 targets | TRAP 3 {halfpin:inv,halfpin:drawer,windowbox} | ISLAND 0 {}
ZEDQA nav world furniture STUCK: container:1(D) fur:mode:pickup(D) fur:mode:place(D) fur:mode:rotate(D) fur:mode:scrap(D) fur:mode:repair(D) tab:loot(R) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(DR) worldCtl:take(D) worldCtl:same(D) halfpin:inv(U) halfpin:drawer(U) windowbox(UR)
ZEDQA nav FAIL trap: world furniture trap halfpin:inv
ZEDQA nav FAIL trap: world furniture trap halfpin:drawer
ZEDQA nav FAIL trap: world furniture trap windowbox
ZEDQA nav world maps: 37 targets | TRAP 3 {halfpin:inv,halfpin:drawer,windowbox} | ISLAND 0 {}
ZEDQA nav world maps STUCK: container:1(D) map:style:survey(D) map:style:color(D) map:style:paper(D) map:ext:key(D) tab:loot(R) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(DR) worldCtl:take(D) worldCtl:same(D) halfpin:inv(U) halfpin:drawer(U) windowbox(UR)
ZEDQA nav FAIL trap: world maps trap halfpin:inv
ZEDQA nav FAIL trap: world maps trap halfpin:drawer
ZEDQA nav FAIL trap: world maps trap windowbox
ZEDQA nav world forage: 21 targets | TRAP 3 {halfpin:inv,halfpin:drawer,windowbox} | ISLAND 0 {}
ZEDQA nav world forage STUCK: container:1(D) forage:search(D) tab:loot(R) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(DR) worldCtl:take(D) worldCtl:same(D) halfpin:inv(U) halfpin:drawer(U) windowbox(UR)
ZEDQA nav FAIL trap: world forage trap halfpin:inv
ZEDQA nav FAIL trap: world forage trap halfpin:drawer
ZEDQA nav FAIL trap: world forage trap windowbox
ZEDQA nav world animals: 21 targets | TRAP 3 {halfpin:inv,halfpin:drawer,windowbox} | ISLAND 0 {}
ZEDQA nav world animals STUCK: container:1(D) animals:createzone(D) tab:loot(R) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(DR) worldCtl:take(D) worldCtl:same(D) halfpin:inv(U) halfpin:drawer(U) windowbox(UR)
ZEDQA nav FAIL trap: world animals trap halfpin:inv
ZEDQA nav FAIL trap: world animals trap halfpin:drawer
ZEDQA nav FAIL trap: world animals trap windowbox
ZEDQA nav 14 tabs audited: 42 traps, 0 islands (strict: each one is a failing line)
ZEDQA nav DONE
```

### 3. zedqa_world_pad_take.lua (`ZEDQA wpt`) - WARN, 11 s

- go 29182 at 23:25:25
- 1 ERR line(s)

```text
[ZeD.QA] state #3 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA wpt not run: 7 every tab's bottom (cut Nov 12 2026)
ZEDQA wpt start
[ZeD.QA] run #3 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Key Ring, 3:Ground | stops container:3@0, container:1@100, container:2@163
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldTabBar:tab:craft
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldContainerStrip:container:1
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:3
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
ZEDQA wpt 3 timing: card buttons ready after 5 ticks, 4 frames; focus in the card after 5 ticks, 4 frames (watched 5 ticks, 4 frames)
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
ZEDQA wpt 6 Left from the World window's strip: Char charMainInv:invrow:1 (Baseball Cap)
ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
ZEDQA wpt 6 LB: Char charTabBar:tab:equip
ZEDQA wpt PASS LB lands in the Character window on a lit element
ZEDQA wpt 6 Right: Char charTitlePins:halfpin:drawer
ZEDQA wpt FAIL Right from a row lands on the bag on show
ZEDQA wpt PASS Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on the nails: focus is on the card's primary action (DROP)
ZEDQA wpt PASS Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is DROP; A runs it
ZEDQA wpt PASS A on the card's primary action (Drop) moved the nails out of the bag (10 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (EQUIP)
ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Baseball Cap)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt 8 after X: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 X on a crate row moves the thing out of the crate (223)
ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Tweezers)
ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA layout wpt put back
ZEDQA wpt 36 passed, 1 failed
ZEDQA wpt DONE
```

### 4. zedqa_cov_input.lua (`ZEDQA cov_input`) - WARN, 11 s

- go 29183 at 23:25:40
- 1 ERR line(s)
- screenshots: zqa_cin_icons.png, zqa_cin_pad_world.png, zqa_cin_zoomed_in.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cov_input start: mode gamepad, chord IDLE, pad on Character, Character window open, World window open, zoom target between 0.75 and 1.25, lock in ZeD setup auto
[ZeD.QA] run #4 ok=true
ZEDQA cov_input PASS action map: the pad spec's 18 actions are all in the table (18 entries)
ZEDQA cov_input PASS action map: the engine's A button object maps to confirm
ZEDQA cov_input PASS action map: the engine's B button object maps to cancel
ZEDQA cov_input PASS action map: the engine's X button object maps to context_menu
ZEDQA cov_input PASS action map: the engine's Y button object maps to window_control
ZEDQA cov_input PASS action map: the engine's LeftBump button object maps to window_prev
ZEDQA cov_input PASS action map: the engine's RightBump button object maps to window_next
ZEDQA cov_input PASS action map: the engine's Back button object maps to layout_mode
ZEDQA cov_input PASS action map: the engine's Start button object maps to (none)
ZEDQA cov_input PASS action map: the engine's Guide button object maps to (none)
ZEDQA cov_input PASS action map: the engine's LeftStick button object maps to list_sort
ZEDQA cov_input PASS action map: the engine's RightStick button object maps to list_view
ZEDQA cov_input PASS action map: the engine's DPadUp button object maps to nav_up strip_hotbar
ZEDQA cov_input PASS action map: the engine's DPadDown button object maps to nav_down strip_social
ZEDQA cov_input PASS action map: the engine's DPadLeft button object maps to nav_left strip_contextual
ZEDQA cov_input PASS action map: the engine's DPadRight button object maps to nav_right strip_favorites
ZEDQA cov_input PASS action map: Joypad.AButton, what the engine dispatches, is the engine's A object (not a number) and maps to confirm
ZEDQA cov_input PASS action map: key KEY_RETURN maps to confirm
ZEDQA cov_input PASS action map: key KEY_ESCAPE maps to cancel
ZEDQA cov_input PASS action map: key KEY_UP maps to nav_up
ZEDQA cov_input PASS action map: key KEY_DOWN maps to nav_down
ZEDQA cov_input PASS action map: key KEY_LEFT maps to nav_left
ZEDQA cov_input PASS action map: key KEY_RIGHT maps to nav_right
ZEDQA cov_input PASS action map: key KEY_I maps to inspect
ZEDQA cov_input PASS action map: an unbound key (102) maps to nothing
ZEDQA cov_input PASS action map: a key name in place of a key code maps to nothing
ZEDQA cov_input PASS action map: the spec name "Y" maps as the engine's Y does
ZEDQA cov_input PASS action map: a list handed out is a copy (changing it leaves the map as it was)
ZEDQA cov_input PASS action map: getBinding per mode (confirm Return and A, context menu the right button, LB no key)
ZEDQA cov_input PASS action map: getBinding of an unknown action or mode is nil
ZEDQA cov_input PASS action map: Y's hold config is 400 ms, a tap toggles the pair, the hold closes it
ZEDQA cov_input PASS action map: an action with no hold has no hold config
ZEDQA cov_input PASS action map: Y's hold in the map matches the gp.holdMs token FocusManager times Y with
ZEDQA cov_input PASS action map: rebuild() picks up an action added to the table and one taken out
ZEDQA cov_input PASS top-left buttons: the override is on the game's column (presence: its patch flag)
ZEDQA cov_input PASS top-left buttons: invBtn is hidden
ZEDQA cov_input PASS top-left buttons: healthBtn is hidden
ZEDQA cov_input PASS top-left buttons: craftingBtn is hidden
ZEDQA cov_input PASS top-left buttons: buildBtn is hidden
ZEDQA cov_input PASS top-left buttons: movableBtn is hidden
ZEDQA cov_input PASS top-left buttons: searchBtn is hidden
ZEDQA cov_input PASS top-left buttons: zoneBtn is hidden
ZEDQA cov_input PASS top-left buttons: mapBtn is hidden
ZEDQA cov_input PASS top-left buttons: no hover label is left for a hidden button
ZEDQA cov_input PASS top-left buttons: the debug button is left alone (showing, with its hover label)
ZEDQA cov_input PASS top-left buttons: the hand slots the belt hid leave no hover zone (else the held item's tooltip opens over the empty corner)
ZEDQA cov_input SHOT zqa_cin_icons.png
ZEDQA cov_input PASS top-left buttons: the furniture hint the game raises for its cursor is taken down in the same frame
ZEDQA cov_input PASS top-left buttons: the furniture pop-up the game raises for the pointer on its button is taken down in the same frame
ZEDQA cov_input PASS top-left buttons: safe mode's hand-back shows the buttons the game had showing
ZEDQA cov_input PASS top-left buttons: the hand-back also puts the game's whole hover list back
ZEDQA cov_input PASS top-left buttons: the next frames hide them and their hover labels again
ZEDQA cov_input PASS text scale: the text, border and entry patches are in and ZeD.LeanDraw is published (presence: the flags)
ZEDQA cov_input INFO root scale 1.750, T.px(1) = 2, fallback fonts false
ZEDQA cov_input PASS text scale: role font F1 zooms by its px x the root over its face
ZEDQA cov_input PASS text scale: role font F2 zooms by its px x the root over its face
ZEDQA cov_input PASS text scale: role font F3 zooms by its px x the root over its face
ZEDQA cov_input PASS text scale: role font F4 zooms by its px x the root over its face
ZEDQA cov_input PASS text scale: role font F5 zooms by its px x the root over its face
ZEDQA cov_input PASS text scale: drawText of the body role font takes the engine's zoom call at its zoom
ZEDQA cov_input PASS text scale: drawTextRight ends the zoomed text at x (x less its zoomed width)
ZEDQA cov_input PASS text scale: drawTextCentre centers the zoomed text on x
ZEDQA cov_input PASS text scale: a collapsed element draws no zoomed text (as ISUIElement's own rule)
ZEDQA cov_input PASS text scale: a vanilla font (Small) keeps the engine's own call, no zoom
ZEDQA cov_input PASS text scale: drawTextRight of a vanilla font is the engine's DrawTextRight, untouched
ZEDQA cov_input PASS text scale: a vanilla element's border stays the engine's one-pixel lines
ZEDQA cov_input PASS text scale: a ZeD element's border is four rects T.px(1) = 2 px thick
ZEDQA cov_input PASS text scale: the lean drawRect (case 1) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the lean drawRectBorder (case 2) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the lean drawText (case 3) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the lean drawText (case 4) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the lean drawTextureScaled (case 5) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the lean drawTextureScaled (case 6) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the lean drawTextureScaledAspect (case 7) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the lean drawTextureScaledAspect (case 8) makes exactly ISUIElement's Java calls
ZEDQA cov_input PASS text scale: the 25 listed ZeD classes are flagged for scaled borders (presence: the flag the border draw reads)
ZEDQA cov_input PASS text scale: every ZeD UI class (94) has the lean draw calls or its own, none left on ISUIElement's (presence)
ZEDQA cov_input PASS text scale: the open Character window carries the scaled-border flag and the lean text and border calls (presence)
ZEDQA cov_input PASS text scale: ZeD.TM measures a role font zoomed, as it draws
ZEDQA cov_input PASS text scale: ZeD.TM's line height of a role font is zoomed
ZEDQA cov_input PASS text scale: ZeD.TM measures a vanilla font as the engine does
ZEDQA cov_input PASS text scale: the game's getTextManager() hands vanilla panels the zoomed proxy
ZEDQA cov_input PASS text scale: inside withFontScale (the tooltip's Large text, Overrides/Tooltip.lua) the role's zoom is 1.3 times its own
ZEDQA cov_input PASS text scale: F2's zoom is as it was after withFontScale
ZEDQA cov_input PASS text scale: no font is left marked for a multiple (X._mulFont)
ZEDQA cov_input PASS text scale: a ZeD text entry takes the entry face for this scale
ZEDQA cov_input PASS text scale: the game's own placeholder of a ZeD entry is emptied
ZEDQA cov_input PASS text scale: ZeD draws the entry's placeholder while it is empty and not focused
ZEDQA cov_input PASS input mode: locked to mouse and keys, then let go, the detector stays on kbm
ZEDQA cov_input PASS input mode: a stick inside the dead zone (0.85 of it, both axes; read 11 times in auto mode, past the cooldown) leaves mouse and keys
ZEDQA cov_input PASS input mode: a stick past the dead zone switches to the pad
ZEDQA cov_input PASS input mode: ZeD_InputModeChanged fires (gamepad, kbm)
ZEDQA cov_input PASS input mode: a key 14 ms after the switch, inside the 200 ms cooldown, does not switch back
ZEDQA cov_input PASS input mode: a key after the cooldown switches back to mouse and keys
ZEDQA cov_input PASS input mode: ZeD_InputModeChanged fires (kbm, gamepad)
ZEDQA cov_input PASS input mode: a stick and a key on the same tick (the stick read 1 times), the key (the newer event) wins
ZEDQA cov_input PASS input mode: a trigger at 0.6 of its threshold (read 11 times in auto mode, past the cooldown) leaves mouse and keys
ZEDQA cov_input PASS input mode: a trigger pulled past its threshold switches to the pad
ZEDQA cov_input FAIL input mode: a pad unplugged with none left goes back to mouse and keys (not checked: 1 real pad(s) connected: the unplug would reach the game's own pad handlers)
ZEDQA cov_input PASS input mode: a pad named "Xbox Wireless Controller" reads as xbox
ZEDQA cov_input PASS input mode: a pad named "DualSense Wireless Controller" reads as playstation
ZEDQA cov_input PASS input mode: a pad named "Nintendo Switch Pro Controller" reads as nintendo
ZEDQA cov_input PASS input mode: a pad named "Generic USB Joystick" reads as unknown
ZEDQA cov_input PASS input mode: an empty slot reads as unknown
ZEDQA cov_input PASS input mode: a lock to the pad answers at once
ZEDQA cov_input PASS input mode: the lock switches the detector and tells the listeners (gamepad)
ZEDQA cov_input PASS input mode: a lock value that is not a mode is ignored
ZEDQA cov_input PASS input mode: a key press does not move a locked mode
ZEDQA cov_input PASS pad path: RB on the focused Character window moves the pad to the World window (window_next)
ZEDQA cov_input SHOT zqa_cin_pad_world.png
ZEDQA cov_input PASS pad path: LB moves it back to the Character window (window_prev)
ZEDQA cov_input PASS pad path: a press on the window that does not hold the pad does nothing
ZEDQA cov_input PASS pad path: L3 steps the list's sort (list_sort)
ZEDQA cov_input PASS bumper zoom: with a window holding the pad, LB held is not the chord's (FocusManager turned it off)
ZEDQA cov_input PASS bumper zoom: with the pad released, LB held arms the chord (LB_HELD, active)
ZEDQA cov_input PASS bumper zoom: hold LB, tap RB fires the chord (CONSUMED)
ZEDQA cov_input PASS bumper zoom: hold LB, tap RB zooms in one level
ZEDQA cov_input PASS bumper zoom: a second RB tap with LB held stays in the chord
ZEDQA cov_input PASS bumper zoom: each further RB tap with LB held zooms in one more
ZEDQA cov_input PASS bumper zoom: both let go, the chord is idle again
ZEDQA cov_input SHOT zqa_cin_zoomed_in.png
ZEDQA cov_input PASS bumper zoom: RB held arms the chord the other way (RB_HELD)
ZEDQA cov_input PASS bumper zoom: hold RB, tap LB fires the chord
ZEDQA cov_input PASS bumper zoom: hold RB, tap LB zooms out one level
ZEDQA cov_input PASS bumper zoom: let go, idle again
ZEDQA cov_input PASS bumper zoom: LB alone arms the chord
ZEDQA cov_input PASS bumper zoom: LB tapped alone and let go does nothing (back to IDLE)
ZEDQA cov_input PASS bumper zoom: a bumper alone leaves the zoom
ZEDQA cov_input PASS bumper zoom: both bumpers on one tick fire the chord (LB counts first)
ZEDQA cov_input PASS bumper zoom: both bumpers on one tick zoom in
ZEDQA cov_input PASS bumper zoom: let go after both, idle again
ZEDQA cov_input PASS bumper zoom: setEnabled(false) mid-chord drops it to IDLE
ZEDQA cov_input PASS bumper zoom: turned off, an RB tap with LB held does nothing
ZEDQA cov_input PASS bumper zoom: turned off, the zoom stays
ZEDQA cov_input PASS bumper zoom: with no pad on player 1's slot the bumpers are not read
ZEDQA cov_input PASS bumper zoom: the pad back, LB held arms the chord again
ZEDQA cov_input PASS bumper zoom: a switch to mouse and keys mid-chord drops it to IDLE
ZEDQA cov_input PASS bumper zoom: on mouse and keys the bumpers are not read
ZEDQA cov_input RESULT 133 pass, 1 fail (1 of them checks that could not run)
ZEDQA cov_input DONE
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
