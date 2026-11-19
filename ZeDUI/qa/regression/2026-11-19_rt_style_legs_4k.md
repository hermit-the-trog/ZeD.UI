# ZeD-UI regression - 2026-11-19 10:31 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-19 10:31:53 |
| Finished | 2026-11-19 10:38:44 (6 min 51 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta21 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\rt_style_legs.txt (7 scripts) |
| Result | **6/7 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 30170 to 30178 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 30177, 30178)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | rt_kit.lua | rtk | PASS | 1 |  |  |
| 3 | rt_cards.lua | rt_cards | PASS | 44 |  |  |
| 4 | rt_hud.lua | rt_hud | PASS | 45 |  |  |
| 5 | rt_media.lua | rt_media | PASS | 26 |  |  |
| 6 | rt_vehicles.lua | rt_veh | PASS | 26 |  |  |
| 7 | rt_system.lua | rt_sys | **FAIL** | 157 |  | 2 ERR line(s); its own checks failed (VERDICT FAIL) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 30170 at 10:32:58

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
ZEDQA pre ZeD version=0.3.0-beta21 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. rt_kit.lua (`ZEDQA rtk`) - PASS, 1 s

- go 30171 at 10:33:03

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rtk kit ready: player 0, screen 3840x2160
[ZeD.QA] run #2 ok=true
ZEDQA rtk DONE
```

### 3. rt_cards.lua (`ZEDQA rt_cards`) - PASS, 44 s

- go 30172 at 10:33:07

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_cards start (257 steps)
[ZeD.QA] run #3 ok=true
ZEDQA rt_cards PASS an apple, a bat, a book and a pencil are given | Apple, Baseball Bat, Book: "2023: Intergalactic Voyage", by Katie C. Scott, Pencil
ZEDQA rt_cards PASS the Character window's list shows the main inventory | none
ZEDQA rt_cards PASS pad: the focus lands on the apple's row (FocusManager, charMainInv)
ZEDQA rt_cards PASS pad: A on the apple's row opens its card | Apple
ZEDQA rt_cards PASS pad: the card is half or full wide | 385
ZEDQA rt_cards PASS on screen (the apple's item card (pad)): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS pad: the focus goes back to the apple's row, its card still open
ZEDQA rt_cards PASS pad: A on the row whose card is open opens the game's menu for the apple (ZeD's menu) | menu ZeD_ContextList, on the apple true
ZEDQA rt_cards PASS on screen (the apple's menu (pad A)): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_cards PASS on screen (the apple's menu (pad A)): every level of the list | 1 levels
ZEDQA rt_cards PASS eat: the card shows EAT and the pad's focus lands on it | EAT MORE
ZEDQA rt_cards PASS eat: A held on Eat queues the game's own eat (ISEatFoodAction) | ISEatFoodAction
ZEDQA rt_cards PASS mouse: its row is in the Character window's list | Baseball Bat
ZEDQA rt_cards PASS mouse: a click on the bat's row opens its card | Baseball Bat
ZEDQA rt_cards PASS mouse: the card is half (220) or full (480) wide | 385
ZEDQA rt_cards PASS facts: the card shows the bat's weight | 2.0 kg (want 2.0 kg)
ZEDQA rt_cards PASS facts: the card's facts show the bat's condition | 15 / 15 (want 15 / 15)
ZEDQA rt_cards PASS on screen (the bat's item card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS width: the drawer's card is the compact one (under 320) and it draws its name row, back bar and verbs | 385 wide, 2 verbs
ZEDQA rt_cards PASS rename: the pad's focus lands on the card's name row (name_row)
ZEDQA rt_cards PASS rename: A on the name row opens the rename prompt with the bat's name | Baseball Bat
ZEDQA rt_cards PASS on screen (the rename prompt): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS rename: OK names the bat as typed | ZeD QA bat
ZEDQA rt_cards PASS rename: the prompt opens again
ZEDQA rt_cards PASS rename: Cancel leaves the name as it was | ZeD QA bat
ZEDQA rt_cards PASS lists: the card shows its Lists mark and the pad's focus lands on it (toggle_lists) | true
ZEDQA rt_cards PASS lists: A on the Lists mark opens the lists' pop-up | Baseball Bat in lists
ZEDQA rt_cards PASS on screen (the Lists pop-up): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS on screen (the Lists pop-up): every level of the list | 1 levels
ZEDQA rt_cards PASS lists: the pop-up opens at the card (from the mark's lower left) | 1028+443 vs card 812
ZEDQA rt_cards PASS read: its row is in the Character window's list | Book: "2023: Intergalactic Voyage", by Katie C. Scott
ZEDQA rt_cards PASS read: a click on the book's row opens its card | Book: "2023: Intergalactic Voyage", by Katie C. Scott
ZEDQA rt_cards PASS read: the card shows READ and the pad's focus lands on it | READ MORE
ZEDQA rt_cards PASS read: Read queues the game's own read (ISReadABook) | ISReadABook
ZEDQA rt_cards PASS equip: its row is in the Character window's list | Baseball Bat
ZEDQA rt_cards PASS equip: the bat's card opens again | Baseball Bat
ZEDQA rt_cards PASS equip: the card shows EQUIP and the pad's focus lands on it | EQUIP MORE
ZEDQA rt_cards PASS equip: Equip puts the bat in the hand (the game's equip action) | Baseball Bat
ZEDQA rt_cards PASS equip: the card now reads the bat as equipped | equipped
ZEDQA rt_cards PASS width: the Equip tab opens the bat's card at full width (480) and it draws its back bar and verbs | 840 wide, item Baseball Bat
ZEDQA rt_cards PASS on screen (the Equip tab's card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS width: the card's back key returns the Equip tab to its list
ZEDQA rt_cards PASS drop: its row is in the Character window's list | Pencil
ZEDQA rt_cards PASS drop: a click on the pencil's row opens its card | Pencil
ZEDQA rt_cards PASS drop: the card shows MORE and the pad's focus lands on it | EQUIP MORE
ZEDQA rt_cards PASS drop: MORE opens the pencil's whole context menu | true
ZEDQA rt_cards PASS more: the menu MORE opens is the pencil's, and it shows | ZeD_ContextList, on the pencil true
ZEDQA rt_cards PASS on screen (the pencil's MORE menu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS on screen (the pencil's MORE menu): every level of the list | 1 levels
ZEDQA rt_cards PASS drop: the menu has the game's Drop and it can be picked | picked
ZEDQA rt_cards PASS drop: Drop puts the pencil on the ground (the game's drop action) | world item true, container nil
ZEDQA rt_cards PASS tool verbs: a dull knife, a whetstone, a dirty shirt, sewing things and a barrel of water | knife true, shirt true, water true
ZEDQA rt_cards PASS sharpen: its row is in the Character window's list | Hunting Knife
ZEDQA rt_cards PASS sharpen: the card offers sharpen and the pad's focus lands on it
ZEDQA rt_cards NOTE sharpen: one frame after A the queue holds none
ZEDQA rt_cards PASS sharpen: A on it queues the game's own action (Craft) | ISHandcraftAction
ZEDQA rt_cards PASS repair: its row is in the Character window's list | Hunting Knife
ZEDQA rt_cards PASS repair: with no fixing for the knife, the card offers no repair (verb_repair) | card true, repair stop false
ZEDQA rt_cards PASS wash: its row is in the Character window's list | T-shirt
ZEDQA rt_cards PASS wash: the card offers wash and the pad's focus lands on it
ZEDQA rt_cards NOTE wash: one frame after A the queue holds none
ZEDQA rt_cards PASS wash: A on it queues the game's own action (ISWashClothing) | ISWashClothing
ZEDQA rt_cards PASS pad all: its row is in the Character window's list | T-shirt
ZEDQA rt_cards PASS pad all: the card offers pad_all and the pad's focus lands on it
ZEDQA rt_cards NOTE pad all: one frame after A the queue holds none
ZEDQA rt_cards PASS pad all: A on it queues the game's own action (ISRepairClothing) | ISRepairClothing ISRepairClothing ISRepairClothing ISRepairClothing
ZEDQA rt_cards PASS repair all: its row is in the Character window's list | T-shirt
ZEDQA rt_cards PASS repair all: the card offers repair_all and the pad's focus lands on it
ZEDQA rt_cards NOTE repair all: one frame after A the queue holds none
ZEDQA rt_cards PASS repair all: A on it queues the game's own action (ISRepairClothing) | ISRepairClothing
ZEDQA rt_cards PASS preview: the Craft tab lists a recipe row in view
ZEDQA rt_cards PASS preview: a click on the recipe's row opens its craft card (the icon at its top) | RipClothing
ZEDQA rt_cards PASS preview: a click on the craft card's icon opens the recipe preview card | preview
ZEDQA rt_cards PASS preview: the preview card is the half card (220) | 385
ZEDQA rt_cards PASS on screen (the recipe preview card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS preview: picking another recipe closes the preview card | nil
ZEDQA rt_cards PASS generator: placed beside the character
ZEDQA rt_cards PASS generator: ZeD's hook is on the game's Info
ZEDQA rt_cards PASS generator: the game's Info opens ZeD's generator card on it | generator
ZEDQA rt_cards PASS generator: the card is the full card (480) | 840
ZEDQA rt_cards PASS generator: the card reads its fuel and condition | 10 / 90 (want 10 / 90)
ZEDQA rt_cards PASS generator: the card says it is off | Off
ZEDQA rt_cards PASS on screen (the generator card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS generator: connected with fuel, its engine switch is live (gen:engine)
ZEDQA rt_cards PASS generator: the engine switch starts it (the game's own activate)
ZEDQA rt_cards PASS generator: running, its card reads it on | Running
ZEDQA rt_cards PASS generator: the engine switch again stops it
ZEDQA rt_cards PASS generator: with no fuel the engine switch refuses (nothing to run) | zone run false, verb on false
ZEDQA rt_cards PASS fire: a campfire made beside the character (the game's campfire system)
ZEDQA rt_cards PASS fire: ZeD's hook is on the campfire's Info
ZEDQA rt_cards PASS fire: the campfire is in the world
ZEDQA rt_cards PASS fire: the campfire's Info opens ZeD's fire card | fire campfire
ZEDQA rt_cards PASS fire: a new campfire reads no fuel and not lit | 0 false
ZEDQA rt_cards PASS fire: the card says Out | Out
ZEDQA rt_cards PASS on screen (the fire card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS fire: with fuel carried, the card lists it to add (fire:fuel:1)
ZEDQA rt_cards PASS fire: Add fuel adds fuel time (the game's add fuel) | 0 -> 120
ZEDQA rt_cards PASS fire: with matches and paper, the card offers Light (fire:light:1)
ZEDQA rt_cards PASS fire: Light lights it (the game's light) and the pill reads burning | Burning
ZEDQA rt_cards PASS fire: a lit campfire beside the character logs no exception (its flame has no window) | pcall true, answer false
ZEDQA rt_cards PASS fire: Put out puts the lit campfire out (the game's put-out action)
ZEDQA rt_cards PASS laundry: a washer placed beside the character | appliances_laundry_01_4
ZEDQA rt_cards PASS laundry: the washer is in the World window's container list
ZEDQA rt_cards PASS laundry: the washer's container row has ZeD's gears button | take same floor obj:ZeDLaundry
ZEDQA rt_cards PASS laundry: the gears button opens ZeD's laundry card on the washer | laundry
ZEDQA rt_cards PASS laundry: the card says it is off | Off
ZEDQA rt_cards PASS laundry: the card reads the power as the game has it | false vs false
ZEDQA rt_cards PASS on screen (the laundry card): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS fridge: a fridge placed beside the character, milk inside | true
ZEDQA rt_cards PASS fridge: the World window lists the fridge by name | Fridge
ZEDQA rt_cards PASS fridge: it opens in the Loot pane
ZEDQA rt_cards PASS fridge: the pane lists what is inside (the milk) | 6
ZEDQA rt_cards PASS on screen (the fridge in the Loot pane): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS stove: a range placed beside the character
ZEDQA rt_cards PASS stove: ZeD's hook is on the game's stove settings
ZEDQA rt_cards PASS stove: the game's stove settings open ZeD's stove (its face popped out, or the Craft tab on it) | face true, station nil
ZEDQA rt_cards PASS stove: its state reads as the game has it (power, switch) | No power (want No power)
ZEDQA rt_cards PASS on screen (the stove): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS band: the stove's container row draws its button band
ZEDQA rt_cards SKIP band: the stove's buttons scroll sideways (they all fit the list's 651 px here (no overflow))
ZEDQA rt_cards PASS oven: the stove has power (the grid, or the generator beside it run for the test)
ZEDQA rt_cards PASS oven: the stove is bound in the Craft tab, its panel's controls drawn
ZEDQA rt_cards PASS oven: a knob or key on its panel changes the stove's setting | heat: heat 200 -> 250, timer -1 -> -1
ZEDQA rt_cards PASS oven: its timer knob sets the timer | -1 -> 60
ZEDQA rt_cards PASS oven: its power key turns the stove on (the game's stove command) | on
ZEDQA rt_cards PASS oven: pressed again it turns off
ZEDQA rt_cards PASS pop-out: the stove's panel (Simple) has its pop-out button
ZEDQA rt_cards PASS pop-out: the stove opens in its own window, centred | up true, middle 1919 of 3840
ZEDQA rt_cards PASS on screen (the stove's own window): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS pop-out: the tab's bring-it-back closes the stove's window
ZEDQA rt_cards PASS pop-out: letting the station go closes its window | opened again true
ZEDQA rt_cards PASS station: a Primitive Kiln built beside the character (a craft bench) | 1 objects
ZEDQA rt_cards PASS station: the game's station option binds the kiln in the World window's Craft tab | Primitive Kiln
ZEDQA rt_cards PASS station: the kiln reads in use by you | In use by you
ZEDQA rt_cards PASS station: the kiln holds the game's one-player lock for you
ZEDQA rt_cards PASS on screen (the kiln in the Craft tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards SKIP a mod's general station card (StationGeneral.lua) (no mod station is installed on the release-test save)
ZEDQA rt_cards PASS rack: a herb drying rack built beside the character | 2 objects
ZEDQA rt_cards PASS rack: bound in the Craft tab, its Add offers the basil carried
ZEDQA rt_cards NOTE rack Add: queue ISItemSlotAddAction ISItemSlotAddAction, free output slots 20, distance 1.4, basil 2
ZEDQA rt_cards PASS rack: Add puts the basil into its input slots (the game's slot action) | 2 -> 0 carried
ZEDQA rt_cards PASS rack: its input slots show the basil to take
ZEDQA rt_cards SKIP rack: Take all empties the output (nothing has dried (the drying takes 24 game hours); a slot's take is checked instead)
ZEDQA rt_cards PASS rack: a slot's take brings the basil back out (the game's slot action) | 0 -> 1 carried
ZEDQA rt_cards PASS rack: Start runs it (isRunning)
ZEDQA rt_cards NOTE rack stop: at the press, isUsingPlayer true (getUsingPlayer you), isStopRequested false, isRunning true, Start zone true running false
ZEDQA rt_cards NOTE rack stop: just after the press, queue none, isUsingPlayer true (getUsingPlayer you), isStopRequested true
ZEDQA rt_cards PASS rack: Start pressed again stops it (its stop request is taken) | isRunning false, isStopRequested false, queue none
ZEDQA rt_cards NOTE rack stop: at the check, isUsingPlayer true (getUsingPlayer you)
ZEDQA rt_cards NOTE rack stop (ZeD Stop): unwrapped; isValid ran 0 times, perform 0 times
ZEDQA rt_cards NOTE rack Cancel: the first stop stopped it; Start pressed again before the comparison
ZEDQA rt_cards NOTE rack Cancel: before the comparison, isRunning true, isStopRequested false, queue none, restarted true
ZEDQA rt_cards NOTE rack Cancel: safe mode on (was 1), ZeD.Safe.on() true, isUsingPlayer true (getUsingPlayer you)
ZEDQA rt_cards NOTE rack Cancel: the game's window is open, isUsingPlayer true (getUsingPlayer you), isRunning true, isStopRequested false, same component as ZeD's true
ZEDQA rt_cards NOTE rack stop (game Cancel): isValid ran (call 1) -> true, funcCanStart true, isUsingPlayer true (getUsingPlayer you)
ZEDQA rt_cards NOTE rack Cancel: cancelCraft called, queue ISGenericCraftStart
ZEDQA rt_cards NOTE rack stop (game Cancel): isValid ran (call 2) -> true, funcCanStart true, isUsingPlayer true (getUsingPlayer you)
ZEDQA rt_cards NOTE rack stop (game Cancel): isValid ran (call 8) -> false, funcCanStart true, isUsingPlayer false (getUsingPlayer nil)
ZEDQA rt_cards NOTE rack Cancel: queue empty, after the game's Cancel isRunning true, isStopRequested false, isUsingPlayer false (getUsingPlayer nil)
ZEDQA rt_cards NOTE rack stop (game Cancel): unwrapped; isValid ran 8 times, perform 0 times
ZEDQA rt_cards NOTE rack Cancel: safe mode option put back to 1, ZeD.Safe.on() false
ZEDQA rt_cards NOTE rack Cancel: with ZeD back, isRunning true, isStopRequested false, ZeD.Safe.on() false
ZEDQA rt_cards PASS tab strip (Character window): a press on Skills opens it | tab skills
ZEDQA rt_cards PASS tab strip (Character window): Skills pressed again folds back to Loot | tab loot
ZEDQA rt_cards PASS Loot snaps the Character window to the inventory alone, its right edge kept | 777 wide, want 777; right 1911, anchor 1911
ZEDQA rt_cards SKIP tab strip scroll arrows (the strip shows every tab at this size (no overflow, no arrows))
ZEDQA rt_cards PASS tab strip (World window): a press on Craft opens it | tab craft
ZEDQA rt_cards PASS tab strip (World window): Craft pressed again folds back to Loot | tab loot
ZEDQA rt_cards NOTE halves at the wait's end: pad=false, cw.drag=table 0x328122191{ active=false, pending=false, ghostCount=0, ghostX=0, ghostY=0, startX=0, startY=0, threshold=4 }, cw.dragActive=false, ww.drag=table 0x356506100{ active=false, pending=false, ghostCount=0, ghostX=0, ghostY=0, startX=0, startY=0, threshold=4 }, ww.dragActive=false, moving=nil, pinned=false, outSince-now=nil, halves=table 0x1866884943{ key=char, side=left, strip=_tabStripPanel, zone=charTitlePins, inv=table 0x978594151, drawer=table 0x1548131749, rightRect=table 0x928849824, leftRect=table 0x1811769883, dragMine=false, invShown=true, lastEffW=840, foldTab=skills }, halves.drawer=table 0x1548131749{ pinned=false, rolled=true, hover=false }, drawer.out=nil, drawer.rolled=true, drawer.pinned=false, invDrawerOpen=true, _drawerOpen=false, _drawerMode=nil, mouseDown0=false, mouseDown1=false, absX=294, absY=0, width=1617, shownH=735, spot=1920,24, mouse=1920,24, split=903, hit(drawer)=false/false
ZEDQA rt_cards PASS halves: the unpinned drawer rolls up after 2 s with the pointer away | 1992 ms
ZEDQA rt_cards PASS halves: the rolled drawer keeps its tab (Skills) | folded skills, shaded false, tab skills
ZEDQA rt_cards PASS queued transfers: both moves waiting show on their rows (InvTip.queued) | 2 of 2
ZEDQA rt_cards PASS queued transfers: the queue stopped, no row shows a move waiting | 0 still shown
ZEDQA rt_cards PASS watch: the game's clock and speed controls are parked off screen | clock y -4000, speed controls y -4000
ZEDQA rt_cards PASS Maps: the header has its Key button
ZEDQA rt_cards PASS Maps: the Key button opens the map's key | true
ZEDQA rt_cards PASS on screen (the map's key): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_cards PASS Maps: the key's close box shuts it | false
ZEDQA rt_cards PASS Read Map: a town map is given |
ZEDQA rt_cards PASS Read Map on a paper map opens ZeD's map on that paper (a pop-out) | Base.MuldraughMap:zombie.inventory.types.MapItem@5eeacf86
ZEDQA rt_cards PASS on screen (the paper map): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS Read Map: the paper gone from the main inventory, its map folds away
ZEDQA rt_cards PASS wheel: the game's emote wheel opens drawn ZeD's way (menu._zed) | opened true, zed true
ZEDQA rt_cards PASS on screen (the emote wheel): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS wheel: a click towards a slice runs that slice's command | slice under the click 2, ran 2
ZEDQA rt_cards PASS form card: it opens from its spec and shows
ZEDQA rt_cards PASS on screen (the form card): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_cards PASS form card: A on its check row runs the row | 1 runs
ZEDQA rt_cards PASS form card: B is its cancel and the card closes | cancel 1, finished 1
ZEDQA rt_cards PASS put back: the things given are taken back | 0 left
ZEDQA rt_cards PASS put back: the campfire is gone
ZEDQA rt_cards PASS put back: everything placed or built is taken away | 0 left
ZEDQA rt_cards end: 166 pass, 0 fail, 4 skipped
ZEDQA rt_cards VERDICT PASS 166
ZEDQA rt_cards DONE
```

### 4. rt_hud.lua (`ZEDQA rt_hud`) - PASS, 45 s

- go 30173 at 10:33:55

```text
[ZeD.QA] state #4 speed=1 paused=false player=928,13039 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_hud start (126 steps)
[ZeD.QA] run #4 ok=true
ZEDQA rt_hud PASS safe mode is off, so ZeD draws the HUD
ZEDQA rt_hud PASS every HUD module is loaded
ZEDQA rt_hud PASS window alone: toggle opens the Character window without the World window
ZEDQA rt_hud PASS window alone: it opens on Loot with the drawer shut | loot, drawer false
ZEDQA rt_hud PASS on screen (the Character window alone): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS window alone: toggle again closes it
ZEDQA rt_hud PASS UI scale Auto: ZeD.Scale is loaded
ZEDQA rt_hud PASS UI scale Auto: the root is the screen height over 1080, held to 0.75 .. 4, times the font knob | 2, want 2 at 2160 px high
ZEDQA rt_hud PASS belt: drawn
ZEDQA rt_hud PASS belt: at the bottom of the screen | 1535,2034 662x98
ZEDQA rt_hud PASS belt: the game's hotbar is parked off screen (Overrides/Belt.lua)
ZEDQA rt_hud PASS belt: the game's left column shows no hands and no window buttons | column up; showing:
ZEDQA rt_hud PASS hands: two circles, the main hand the bigger | 98 and 77
ZEDQA rt_hud PASS hands: the off hand left of the main hand (seen from behind)
ZEDQA rt_hud PASS on screen (belt): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS hands: one item in both hands slides the off hand under the main hand
ZEDQA rt_hud PASS hands: one hand free again, the off hand back beside the main hand
ZEDQA rt_hud PASS belt menu: the hammer is in the main hand
ZEDQA rt_hud PASS belt menu: the belt takes a right-click on the main hand
ZEDQA rt_hud PASS belt menu, right-click on the main hand: a menu opens
ZEDQA rt_hud PASS belt menu, right-click on the main hand: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, right-click on the main hand): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt menu: it holds the hammer's own options | 12
ZEDQA rt_hud PASS belt menu, the pad's X on the main hand: a menu opens
ZEDQA rt_hud PASS belt menu, the pad's X on the main hand: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, the pad's X on the main hand): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt menu: the pad's menu names the belt its origin (the way back to it)
ZEDQA rt_hud PASS belt menu, the pad's X on a slot: a menu opens
ZEDQA rt_hud PASS belt menu, the pad's X on a slot: the menu is on screen | 0,0 3840x2160
ZEDQA rt_hud PASS on screen (belt menu, the pad's X on a slot): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt: a number key held past half a second opens its slot's list
ZEDQA rt_hud PASS belt: the slot's list opens at its slot, on screen | 0,0 3840x2160, slot at x 1798
ZEDQA rt_hud PASS on screen (the slot's list): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS belt: the key's release after the list draws nothing
ZEDQA rt_hud PASS belt: the Messages note is on the belt
ZEDQA rt_hud PASS belt: a click on the Messages note opens the Messages window
ZEDQA rt_hud PASS belt: the Messages window is on screen
ZEDQA rt_hud PASS on screen (the Messages window): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS belt: the note's anchor is a point on the belt | 2248,2049
ZEDQA rt_hud PASS Lite belt: Style Lite gives the simple belt (Z.Belt.simple())
ZEDQA rt_hud PASS simple belt: no strap and no buckle
ZEDQA rt_hud PASS simple belt: the slots SIMPLE_GAP apart | 11 px, want 11
ZEDQA rt_hud PASS simple belt: on screen
ZEDQA rt_hud PASS on screen (simple belt): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS Lite belt: Style Full brings the strap back
ZEDQA rt_hud PASS watch: the worn watch is on the belt | Base.WristWatch_Left_DigitalBlack
ZEDQA rt_hud PASS watch: the mini sits beside its own hand (left wrist)
ZEDQA rt_hud PASS watch: the full watch is tucked away while the mini shows
ZEDQA rt_hud PASS watch: the middle of the mini is its face | face
ZEDQA rt_hud PASS watch: the face opens the full watch | 248x352
ZEDQA rt_hud PASS watch: the full watch stands above the mini on the belt | 2023 over 2037
ZEDQA rt_hud PASS on screen (full watch): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS watch: a second press tucks it back
ZEDQA rt_hud PASS watch: its light comes on | no light spot on the mini: the watch's own light control
ZEDQA rt_hud PASS action bar: a bag to pack
ZEDQA rt_hud PASS action bar: the game's timed action is drawn
ZEDQA rt_hud PASS action bar: it names the action | MOVING PENCIL
ZEDQA rt_hud PASS action bar: the queue count reads the moves queued | qi 0 of 4, queued 4
ZEDQA rt_hud PASS action bar: its layer shows
ZEDQA rt_hud PASS on screen (action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS action bar: the bar follows the action | 0.00 to 0.10
ZEDQA rt_hud PASS action bar: the job ends with Done drawn from it
ZEDQA rt_hud PASS action bar: the Done fades and the bar clears
ZEDQA rt_hud PASS action bar: the action did its work (4 in the bag)
ZEDQA rt_hud PASS bar style: Style Lite draws the simple bar | simple
ZEDQA rt_hud PASS bar style: the simple bar is 53 x 9 units | 53 x 9
ZEDQA rt_hud PASS bar style: the simple bar is on screen | 1867,987 106x18
ZEDQA rt_hud PASS bar style: the simple bar stands above the head | 1005 over 1017.40625
ZEDQA rt_hud PASS on screen (simple action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bar style: the simple job ends
ZEDQA rt_hud PASS bar style: Detailed draws the thought bubble | verbose
ZEDQA rt_hud PASS bar style: the detailed bar has its size | 64 x 30
ZEDQA rt_hud PASS bar style: the detailed bar is on screen | 1858,909 152x104
ZEDQA rt_hud PASS on screen (detailed action bar): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bar style: the detailed job ends
ZEDQA rt_hud PASS no bar: the attach starts
ZEDQA rt_hud PASS no bar: the game's own flag is read (useProgressBar false, _zedBar false)
ZEDQA rt_hud PASS no bar: the action bar has no state for it
ZEDQA rt_hud PASS right: the moodles are placed right | right
ZEDQA rt_hud PASS right: at least three moodles are on | 5
ZEDQA rt_hud PASS right: every moodle is on screen | 3782,940 48x280
ZEDQA rt_hud PASS right: the column is at the right edge | 3782
ZEDQA rt_hud PASS on screen (moodles right): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS left: the moodles are placed left | left
ZEDQA rt_hud PASS left: at least three moodles are on | 5
ZEDQA rt_hud PASS left: every moodle is on screen | 10,940 48x280
ZEDQA rt_hud PASS left: the column is at the left edge | 10
ZEDQA rt_hud PASS on screen (moodles left): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bottom: the moodles are placed bottom | bottom
ZEDQA rt_hud PASS bottom: at least three moodles are on | 5
ZEDQA rt_hud PASS bottom: every moodle is on screen | 1780,1965 280x48
ZEDQA rt_hud PASS bottom: the row is centred
ZEDQA rt_hud PASS bottom: the row sits above the belt
ZEDQA rt_hud PASS bottom: the game's column is out of sight (no double)
ZEDQA rt_hud PASS on screen (moodles bottom): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bubble: a line the character says is in ZeD's balloon
ZEDQA rt_hud PASS bubble: the over-head layer draws it
ZEDQA rt_hud PASS on screen (speech bubble): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS bubble: it fades and goes
ZEDQA rt_hud PASS xp: Perks.Woodwork exists in this build
ZEDQA rt_hud PASS xp: skill XP goes through with ZeD on, no error
ZEDQA rt_hud PASS xp: the gain is logged in Messages | Carpentry +1.2 XP
ZEDQA rt_hud PASS xp: a game note goes to ZeD's bubble, marked good
ZEDQA rt_hud PASS xp: the over-head layer draws the note
ZEDQA rt_hud PASS on screen (over-head note): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS xp: the note fades and goes
ZEDQA rt_hud PASS guide: a fresh machine arms the bubble
ZEDQA rt_hud PASS guide: the bubble comes out
ZEDQA rt_hud PASS guide: the guide's own words | New to Knox County? Check out this handy survival guide. Stop alt-tabbing for information: click this bubble or press F1 instead. You can dismiss this bubble at any time.
ZEDQA rt_hud PASS guide: a long bare balloon for player one
ZEDQA rt_hud PASS guide: it comes out of the belt's Messages note
ZEDQA rt_hud PASS on screen (guide bubble): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS guide: the bubble goes by itself
ZEDQA rt_hud PASS guide: its line stays in Messages
ZEDQA rt_hud SKIP hint strip at a door (no door within 12 tiles on this floor)
ZEDQA home rt_hud moved from 928,13039,0 to the drag strip
ZEDQA rt_hud PASS forage: ZeD's pin and pointer are loaded
ZEDQA rt_hud PASS forage: search mode is on
ZEDQA rt_hud NOTE forage: 0 things earlier runs left on the ground by the home taken away
ZEDQA rt_hud PASS forage: a find is staged | Base.MushroomGeneric1
ZEDQA rt_hud PASS forage: a pinned find's pointer is empty (its pin marks it) | zed_forage_hand_none
ZEDQA rt_hud PASS forage: the pointer to the find is up | a find in sight, not spotted yet: true
ZEDQA rt_hud PASS forage: the pointer is ZeD's hand for the find's side | zed_forage_hand_up_a
ZEDQA rt_hud PASS forage: the hand is its set size | 36 x 63, want 36 x 63
ZEDQA rt_hud PASS forage: white at its set alpha | alpha 0.4000000059604645, want 0.4
ZEDQA rt_hud PASS forage: the pin over the find is ZeD's magnifying glass | 184 of 226 draws
ZEDQA rt_hud PASS forage: the search-mode eye is in ZeD's over-head stack
ZEDQA rt_hud PASS forage pointer: a find on the ground shows ZeD's hand | zed_forage_hand_up_a, 36 x 63
ZEDQA rt_hud SKIP forage pointer: a stash find shows ZeD's hand (the game draws no pointer to a stash (ISBaseIcon:updateWorldMarker skips iconClass stashObject))
ZEDQA rt_hud PASS forage pointer: an animal track shows ZeD's hand | zed_forage_hand_up_a, 36 x 63
ZEDQA rt_hud PASS on screen (forage): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_hud PASS forage: the find and its pointer are gone again
ZEDQA rt_hud PASS forage tab: the World window's Foraging tab opens from the strip
ZEDQA rt_hud PASS forage tab: the band draws its Search button
ZEDQA rt_hud PASS forage tab: a click on Search flips the game's search mode | true
ZEDQA rt_hud PASS forage tab: a second click puts search mode back
ZEDQA rt_hud PASS balloon: it shows | rtqa:a
ZEDQA rt_hud PASS balloon: near the screen's corner it stays fully on screen | 3454,2015 350x80
ZEDQA rt_hud PASS balloon: one at a time (a second one asked while it is up does not draw) | up: rtqa:a
ZEDQA rt_hud PASS balloon: dismissed, it stays down while its control still asks
ZEDQA rt_hud PASS balloon: the focus on another control brings a balloon back
ZEDQA rt_hud PASS paused: the Character window is open
ZEDQA rt_hud PASS paused: the game reads paused
ZEDQA rt_hud PASS paused: the glass lies on the Character window
ZEDQA rt_hud PASS paused: the glass covers the item list
ZEDQA rt_hud PASS paused: the glass takes a press and a right press (nothing is used)
ZEDQA rt_hud PASS paused: the pad's A and X are held outside the tab strip and the bags | no live zone
ZEDQA rt_hud PASS on screen (paused Character window): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_hud PASS paused: the tab strip still switches tabs | equip, want equip
ZEDQA rt_hud PASS paused: playing again, the glass is gone
ZEDQA rt_hud PASS pin: the Skills tab opens from the strip
ZEDQA rt_hud PASS pin: the Skills tab draws its skill rows
ZEDQA rt_hud PASS pin: a right-click on the skill row opens its menu
ZEDQA rt_hud PASS on screen (skill row menu): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_hud PASS pin: the menu offers Pin to title bar
ZEDQA rt_hud PASS pin: the skill is pinned | Aiming
ZEDQA rt_hud PASS pin: the title bar shows its level and XP | 0/75 in: Long Blade - Lv.0 - 0/75 | Aiming - Lv.0 - 0/75 | 28.4 / 16 kg
ZEDQA rt_hud PASS pin item: four pinnable things to pin | 4 of 4
ZEDQA rt_hud PASS pin item: the item's own menu offers Pin to title bar
ZEDQA rt_hud PASS pin item: the pick puts the item's kind and id in ZeD_Pins | cond 1547949995
ZEDQA rt_hud PASS pin item: ZeD.Pins.stats gives its row | Claw Hammer | 10/10
ZEDQA rt_hud PASS pin item: the Character window's title bar shows it | Claw in: Claw Hammer | 10/10 | 36.9 / 16 kg
ZEDQA rt_hud PASS pins: a fourth pin takes off the oldest (three at most) | 3 pins
ZEDQA rt_hud PASS pins: a note over the head says which pin went | Firefighter Axe pinned. Claw Hammer was taken off (3 at most).
ZEDQA rt_hud PASS popclear: a ZeD window is open to keep clear of
ZEDQA rt_hud PASS popclear: a pop-out over a ZeD window moves clear of it, on screen | 2265,367 to 2265,749
ZEDQA rt_hud PASS popclear: a spot clear of the windows is kept | 0,0 to 0,0
ZEDQA rt_hud PASS prompt: the game's ISTextBox is ZeD's text prompt | ZeD_Prompt
ZEDQA rt_hud PASS prompt: the text prompt shows
ZEDQA rt_hud PASS prompt: the text prompt is on screen
ZEDQA rt_hud PASS on screen (text prompt): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS prompt: the text prompt has its OK
ZEDQA rt_hud PASS prompt: OK hands the typed text back in entry | OK ZeD QA typed
ZEDQA rt_hud PASS prompt: the text prompt closes on OK
ZEDQA rt_hud PASS prompt: the game's ISModalRichText is ZeD's rich prompt | ZeD_Prompt
ZEDQA rt_hud PASS prompt: the rich prompt shows
ZEDQA rt_hud PASS prompt: the long rich text stays on screen | 1537,616 770x930 on 3840x2160
ZEDQA rt_hud PASS prompt: the long text scrolls inside it instead of growing past the screen | 1889.390625
ZEDQA rt_hud PASS on screen (rich prompt): every ZeD window and pop-up inside 3840x2160 | 6 seen
ZEDQA rt_hud PASS prompt: the rich prompt has its OK
ZEDQA rt_hud PASS prompt: OK answers and closes the rich prompt
ZEDQA rt_hud PASS prompt: the game's ISModalDialog is ZeD's question
ZEDQA rt_hud PASS prompt: the question is the prompt on top
ZEDQA rt_hud PASS prompt: Escape answers No on the prompt on top | NO
ZEDQA rt_hud PASS prompt: that Escape does not open the pause menu
ZEDQA rt_hud PASS prompt: the second question is the prompt on top
ZEDQA rt_hud PASS prompt: Enter presses the main answer (Yes) | YES
ZEDQA rt_hud SKIP the mini-map stays hidden (the game made no mini-map for this player)
ZEDQA rt_hud PASS run-sneak: the module and its setting are loaded
ZEDQA rt_hud PASS run-sneak: Run held 400 ms standing still crouches | crouch
ZEDQA rt_hud PASS run-sneak: held again, it stands | stand
ZEDQA rt_hud PASS put back: the character where it started
ZEDQA rt_hud PASS put back: the moodles' place
ZEDQA rt_hud PASS put back: the watch's place
ZEDQA rt_hud end: 189 pass, 0 fail, 3 skipped
ZEDQA rt_hud VERDICT PASS 189
ZEDQA rt_hud DONE
```

### 5. rt_media.lua (`ZEDQA rt_media`) - PASS, 26 s

- go 30174 at 10:34:43

```text
[ZeD.QA] state #5 speed=1 paused=false player=928,13039 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_media start (159 steps)
[ZeD.QA] run #5 ok=true
ZEDQA rt_media PASS the media modules are loaded (RtvFace, RadioTab, RadioOps, TwoWayFace, MapNotes, MapsTab, JournalReaders)
ZEDQA rt_media PASS the radio: given (Base.RadioRed)
ZEDQA rt_media PASS the radio: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the radio: its own face draws in the tab | face radio_red, want radio_red
ZEDQA rt_media PASS on screen (the radio's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the radio: the face has its power control (power)
ZEDQA rt_media PASS the radio: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the radio: the face has its tuning knob
ZEDQA rt_media PASS the radio: TUNE's right half tunes up one step | 99600 -> 99800
ZEDQA rt_media PASS the radio: TUNE's left half tunes back down | now 99600, want 99600
ZEDQA rt_media PASS the radio: power again turns it off
ZEDQA rt_media PASS the radio: the pad's first stop on the face is power | radio:tw:power
ZEDQA rt_media PASS the radio: A on the power stop turns it on
ZEDQA rt_media PASS the radio: A again turns it off
ZEDQA rt_media PASS the radio: the face has its pop-out button
ZEDQA rt_media PASS the radio: the pop-out button pops its face out
ZEDQA rt_media PASS on screen (the radio's face popped out): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS the radio: Escape puts the popped face away | Escape
ZEDQA rt_media PASS the radio wheel: Radio has its slices for the set in hand | 3 slices
ZEDQA rt_media PASS the radio wheel: its power slice turns the set on
ZEDQA rt_media PASS the radio wheel: Next station moves the channel | 99600 -> 101200
ZEDQA rt_media PASS the radio wheel: the power slice again turns it off
ZEDQA rt_media PASS the two-way: given (Base.WalkieTalkie2)
ZEDQA rt_media PASS the two-way: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the two-way: its own face draws in the tab | face walkie_valutech@180, want walkie_valutech
ZEDQA rt_media PASS on screen (the two-way's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the two-way: the face has its power control (vol)
ZEDQA rt_media PASS the two-way: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the two-way: the face has its tuning knob
ZEDQA rt_media PASS the two-way: TUNE's right half tunes up one step | 151200 -> 151400
ZEDQA rt_media PASS the two-way: TUNE's left half tunes back down | now 151200, want 151200
ZEDQA rt_media PASS the two-way: power again turns it off
ZEDQA rt_media PASS the CD player: given (Base.CDplayer)
ZEDQA rt_media PASS the CD player: in hand, the Character window's Radio tab opens on it from the strip
ZEDQA rt_media PASS the CD player: its own face draws in the tab | face cd_player, want cd_player
ZEDQA rt_media PASS on screen (the CD player's face in the Radio tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the CD player: the face has its power control (power)
ZEDQA rt_media PASS the CD player: a click on power turns the set on (the game's device data)
ZEDQA rt_media PASS the CD player: VOL raises the volume (0.50 -> 0.60; it has no tuner)
ZEDQA rt_media PASS the CD player: power again turns it off
ZEDQA rt_media PASS a free room square with room for the TV beside it is found
ZEDQA rt_media PASS the TV's room has grid power (the grid turned on for the test)
ZEDQA rt_media PASS a TV is placed beside the character
ZEDQA rt_media PASS the World window's Radio list has the TV
ZEDQA rt_media PASS the World window's Radio tab opens from the strip
ZEDQA rt_media PASS the World window's Radio tab: a click on the TV's own tab picks it among the radios | idx 1, want 1 of 2
ZEDQA rt_media PASS the TV: its own face draws in the tab | face tv_black@392
ZEDQA rt_media PASS on screen (the TV's face in the World window): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS the TV: on the grid and off to start with
ZEDQA rt_media PASS the TV's face has its power key
ZEDQA rt_media PASS the TV: a click on power turns it on
ZEDQA rt_media PASS the TV's face has CH up
ZEDQA rt_media PASS the TV: CH up tunes the next channel | 1 -> 2
ZEDQA rt_media PASS the TV: power again turns it off
ZEDQA rt_media PASS the TV: a click on it in the world pops its face out |
ZEDQA rt_media PASS on screen (the TV's face popped out): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS the TV: a second click on it puts its face away
ERROR: General f:9020 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA rt_media back at 928,13039
ZEDQA rt_media PASS the World window's Maps tab opens from the strip
ZEDQA rt_media PASS the Maps tab draws its map
ZEDQA rt_media PASS on screen (the Maps tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey: the map restyles and draws | style survey
ZEDQA rt_media PASS survey: the map's own place labels show | 8 label layers, strongest alpha 255
ZEDQA rt_media PASS survey: the note hand keeps its ink | alpha 255
ZEDQA rt_media PASS color: the map restyles and draws | style color
ZEDQA rt_media PASS color: the map's own place labels show | 8 label layers, strongest alpha 255
ZEDQA rt_media PASS color: the note hand keeps its ink | alpha 255
ZEDQA rt_media PASS paper: the map restyles and draws | style paper
ZEDQA rt_media PASS paper: the map's own place labels are hidden (the paper prints its own) | 8 label layers, strongest alpha 0
ZEDQA rt_media PASS paper: the note hand keeps its ink | alpha 255
ZEDQA rt_media PASS the note tool arms from the Maps header
ZEDQA rt_media PASS a note placed at the cursor lands once in the game's own map marks | marks 2 -> 3
ZEDQA rt_media PASS the cursor finds the note
ZEDQA rt_media PASS ZeD's menu on the note offers Delete
ZEDQA rt_media PASS on screen (the menu on a map note): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Delete takes the note off the map | marks now 2
ZEDQA rt_media PASS zoom: the map is up
ZEDQA rt_media PASS zoom: the mouse wheel zooms the map | 16.00 to 16.14
ZEDQA rt_media PASS zoom: the pad's trigger zooms it (gpZoom)
ZEDQA rt_media PASS pan: the pad's cursor at the map's edge pans it (gpMoveCursor) | 729.7 to 84.3
ZEDQA rt_media SKIP pan: a drag pans the map (the pointer could not be moved on this run)
ZEDQA rt_media PASS unfold: the Maps header has its unfold button
ZEDQA rt_media PASS unfold: the map opens in a window of its own and draws there
ZEDQA rt_media PASS unfold: the live map is the pop-out's
ZEDQA rt_media PASS on screen (the unfolded map): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS fold: the drawer shows the fold-back place
ZEDQA rt_media PASS fold: a click on the drawer folds the map back into the tab
ZEDQA rt_media PASS survey: MapsSurvey is loaded and the map is up
ZEDQA rt_media PASS survey: opening Survey raises no Lua error and trips no fault | errors 0 -> 0
ZEDQA rt_media PASS on screen (the Survey map): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey colors: the roads, water and buildings in the theme's palette | light
ZEDQA rt_media PASS survey colors: the map keeps the palette it drew | light
ZEDQA rt_media PASS survey woods: the forest layer carries the theme's tree-mark tile | 1 texture stops, media/textures/ZeD/map/woods_light.png
ZEDQA rt_media PASS survey lakes: a lake layer per lake, just above the water, in the lake blue | 59 lakes, water at 2
ZEDQA rt_media PASS survey recolor: a status-colour change recolors it once, no new layers | light:cb, 1 restyles, layers 85 -> 85
ZEDQA rt_media PASS survey recolor: the status colours put back, the palette follows
ZEDQA rt_media PASS survey grid: lines and letters drawn, all on the map | 9 lines, 5 letters, 0 off the map
ZEDQA rt_media PASS survey scale: the bar is its metres x px per square, boxed at the foot | want 186 px for 2 km; bar true, box true, label true, N true
ZEDQA rt_media PASS survey places: MapsSurveyData has places
ZEDQA rt_media PASS survey places: a badge at each place in view from zoom 15 | zoom 15, 15 badges of 19 px, 15 places in view
ZEDQA rt_media PASS survey places: no place badges below zoom 15 | zoom 14.899999618530273, 0 badges
ZEDQA rt_media PASS survey shields: MapsSurveyData has route shields
ZEDQA rt_media PASS survey shields: every shield drawn carries its number, 110 px apart, off the town names | zoom 14, 3 shields, 3 numbered, 0 too close, 0 on a town name
ZEDQA rt_media PASS survey bridges: MapsSurveyData has bridges
ZEDQA rt_media PASS survey bridges: a bridge in view gets its two lines, wholly on the map | zoom 16, 30 marks by it, 0 off the map
ZEDQA rt_media PASS survey towns: MapsSurveyData has a city (size 3)
ZEDQA rt_media PASS survey towns: a dot per town in view, a filled square for a city | zoom 12, 3 dots and 1 squares for 4 towns (1 cities)
ZEDQA rt_media PASS survey zone: MapsSurveyData has the map's bounds
ZEDQA rt_media PASS survey zone: magenta bars inside the edge, its label wholly on the map | 210 bars, 0 outside the bounds, label true
ZEDQA rt_media PASS survey key: the Maps band has the Key button
ZEDQA rt_media PASS survey key: the Key button opens Survey's key with its two pages
ZEDQA rt_media PASS survey key: Symbols turns the page; the key fits on the map | symbols, panel 812x424.15234375 on a 840x456 map
ZEDQA rt_media PASS on screen (the map key, Symbols): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey key: Colors turns it back; the key fits on the map | colors
ZEDQA rt_media PASS on screen (the map key, Colors): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS survey key: its close box shuts it
ZEDQA rt_media PASS a flyer and a notebook are given
ZEDQA rt_media PASS the Character window's Journal tab opens from the strip
ZEDQA rt_media PASS Papers lists the flyer carried
ZEDQA rt_media PASS the flyer has its row on the page
ZEDQA rt_media PASS on screen (the Journal's Papers page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Papers: a click on the flyer's row opens it on the page | ustoreitmuldraugh
ZEDQA rt_media PASS on screen (the flyer open on the Papers page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Papers: Back on the open flyer returns to the list
ZEDQA rt_media PASS Notebooks lists the notebook carried, with its row
ZEDQA rt_media PASS a click on the notebook's row picks it
ZEDQA rt_media PASS on screen (the Journal's Notebooks page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS light to write by (noon set for the test)
ZEDQA rt_media PASS the quick note's Write button is live
ZEDQA rt_media PASS the line written from the quick note is kept on the notebook's page (ZeD_WriteNoteAction)
ZEDQA rt_media PASS the notebook's Open full button is live
ZEDQA rt_media PASS Open full opens the notebook in ZeD's reader
ZEDQA rt_media PASS the reader opens it to write (a pencil carried)
ZEDQA rt_media PASS the reader shows the written line on its first page
ZEDQA rt_media PASS on screen (the reader): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS Done keeps the second page's text as written
ZEDQA rt_media PASS Done keeps the first page's line
ZEDQA rt_media PASS Done closes the reader
ZEDQA rt_media PASS the Journal page draws its write box and tag picks
ZEDQA rt_media PASS on screen (the Journal page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS a click on a tag pick ticks it (news)
ZEDQA rt_media PASS the Journal page has its Save
ZEDQA rt_media PASS Save writes the entry at the top of the log | ZEDQA rt log: the water tower is dry (2 entries, were 1)
ZEDQA rt_media PASS the entry keeps the ticked tag
ZEDQA rt_media PASS Save clears the box and the ticks
ZEDQA rt_media PASS Recipes: the page draws its recipe rows | 1167 rows
ZEDQA rt_media PASS on screen (the Journal's Recipes page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Recipes: a click on the All recipes head is taken
ZEDQA rt_media PASS Recipes: the head folds its group | 0 rows now
ZEDQA rt_media PASS Recipes: a second click opens it again | 1167 rows
ZEDQA rt_media PASS book: the guide opens as the book, at its first spread
ZEDQA rt_media PASS on screen (the guide book): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS book: its strip has Next page
ZEDQA rt_media PASS book: Next page turns a page (mouse) | 2
ZEDQA rt_media PASS book: the wheel turns back | 1
ZEDQA rt_media PASS book: RB turns on (its own pad handler) | 2
ZEDQA rt_media PASS book: the right arrow key turns on | 3
ZEDQA rt_media PASS book: its strip has Contents
ZEDQA rt_media PASS book: Contents opens the contents spread | 2, want 2
ZEDQA rt_media PASS book: the contents spread lists its chapters
ZEDQA rt_media PASS book: a contents row opens its chapter | 4, want 4
ZEDQA rt_media PASS book: its strip has the start-up box
ZEDQA rt_media PASS book: the start-up box flips the game's own option
ZEDQA rt_media PASS book: a second press puts the option back
ZEDQA rt_media PASS book: a click on a spoiler bar shows its numbers | SurvivalGuide_treat_water_title#1
ZEDQA rt_media PASS book: that bar is gone from the page
ZEDQA rt_media PASS book: opening the guide again hides the spoilers again
ZEDQA rt_media PASS book: A on the pages shows every spoiler on the spread
ZEDQA rt_media PASS Escape closes the book (and the pause menu stays shut)
ZEDQA rt_media PASS B closes the book (its own pad handler)
ZEDQA rt_media PASS F1: with the Health tab open the guide's topic is First aid | SurvivalGuide_first_aid_title
ZEDQA rt_media PASS F1: the key opens the book on that topic, past its first spread | 22
ZEDQA rt_media PASS on screen (the guide book opened by F1): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_media PASS F1: the key again closes the guide
ZEDQA rt_media PASS the Simple look opens the guide window
ZEDQA rt_media PASS on screen (the guide window): every ZeD window and pop-up inside 3840x2160 | 9 seen
ZEDQA rt_media PASS Escape closes the guide window
ZEDQA rt_media PASS Health: its fill blocks draw their heads
ZEDQA rt_media PASS Health: a click on a fill block's head is taken
ZEDQA rt_media PASS Health: a fill block's head folds or opens its block | moodles: false -> true
ZEDQA rt_media PASS Health: pressed again, the block is back as it was
ZEDQA rt_media PASS Thermal: the region grid draws its cells
ZEDQA rt_media PASS Thermal: a click on a grid cell picks that region | Head, want Head
ZEDQA rt_media PASS on screen (the Thermal tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_media PASS Hair and beard: the Identity tab draws the section's part switch
ZEDQA rt_media PASS Hair and beard: a click on the switch changes the part | beard, want beard
ZEDQA rt_media PASS Hair and beard: a click on a row picks it | h:cut:Bald
ZEDQA rt_media PASS Hair and beard: Cut is live for the picked row
ZEDQA rt_media PASS Hair and beard: Cut queues the game's haircut (ISCutHair)
ZEDQA rt_media PASS Hair and beard: stopped at once, the hair is as it was | Grungey
ZEDQA rt_media PASS put back: the character is where it started | 928,13039
ZEDQA rt_media PASS put back: the hands hold what they held
ZEDQA rt_media end: 190 pass, 0 fail, 1 skipped
ZEDQA rt_media VERDICT PASS 190
ZEDQA rt_media DONE
```

### 6. rt_vehicles.lua (`ZEDQA rt_veh`) - PASS, 26 s

- go 30175 at 10:35:12

```text
[ZeD.QA] state #6 speed=1 paused=false player=928,13039 grid=19 inCar=false vehicles=21 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_veh start (48 steps)
[ZeD.QA] run #6 ok=true
ZEDQA vp rt_veh player=928,13039 grid=19 chunks (152 tiles) loaded x 856-1008 y 12960-13112 sq=917,13030 dist=14.9 chunk=true inMap=true car=Base.ModernCarLightsMeadeSheriff at 917.0,13030.0 dist=14.9 vehicles=21
ZEDQA car rt_veh Base.CarLightsPolice spawned on spot 11 (917,13030)
ZEDQA rt_veh PASS a police car spawned beside the character, the character in the driver's seat | nil
ZEDQA rt_veh PASS dash: ZeD's dash shows in the car
ZEDQA rt_veh PASS dash: the game's own dash is not shown beside ZeD's
ZEDQA rt_veh PASS dash: it has a design for the car | police
ZEDQA rt_veh PASS dash: its design has gauges | 5 needles
ZEDQA rt_veh PASS dash: its design has lamps | 9 lamps
ZEDQA rt_veh PASS on screen (the dash): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS dash: a click on the ignition puts the key in
ZEDQA rt_veh PASS dash: key on, engine off: the bulb check lights the lamps | check true, battery true, engine true, oil true
ZEDQA rt_veh PASS dash: a second click on the ignition starts the engine (the game's start) | 0 retries
ZEDQA rt_veh PASS dash: running: the rev needle is up | rpm 754
ZEDQA rt_veh PASS dash: the fuel needle reads the full tank | fuel 1.00
ZEDQA rt_veh PASS dash: running: the bulb check is over (oil lamp dark) | false
ZEDQA rt_veh PASS on screen (the dash, engine running): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS dash: it has its headlight switch | tripReset lights lock trunk ignition lbar siren temp heat fan ac def vol radio chup chdn mem mic mute tune
ZEDQA rt_veh PASS dash: a click on the headlight switch flips the headlights | false -> true
ZEDQA rt_veh PASS dash: a second click puts the headlights back | false
ZEDQA rt_veh PASS radio: ZeD's hook is on the wheel's Device Options
ZEDQA rt_veh PASS radio: Device Options brings the car radio up close | ham
ZEDQA rt_veh PASS on screen (the car radio): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_veh PASS radio: it has a power control | vol chup chdn mem mic mute tune
ZEDQA rt_veh PASS radio: the click turns it on (the game's radio action)
ZEDQA rt_veh PASS radio: with the engine running it plays
ZEDQA rt_veh PASS radio: it has a tuning knob | vol chup chdn mem mic mute tune
ZEDQA rt_veh PASS radio: a click on TUNE's right half moves the frequency | 99600 -> 99800
ZEDQA rt_veh PASS radio: TUNE's left half tunes it back | 99600
ZEDQA rt_veh PASS radio: Device Options again puts it away
ZEDQA rt_veh PASS seats: ZeD's hook is on the seat key
ZEDQA rt_veh PASS seats: a car the cabin cannot lay out gets ZeD's seat chooser | ZeD_SeatChooser
ZEDQA rt_veh PASS seats: it lists every seat of the car | 4 of 4
ZEDQA rt_veh PASS seats: the driver's seat is yours | you
ZEDQA rt_veh PASS on screen (the seat chooser): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_veh PASS seats: it closes
ZEDQA rt_veh PASS seats: in Lite the seat key opens the cabin pop-out | pop-out true, chooser false
ZEDQA rt_veh PASS on screen (the seat pop-out): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_veh PASS seats: the cabin pop-out closes
ZEDQA rt_veh PASS siren: the police car has a lightbar
ZEDQA rt_veh PASS siren: ZeD's hook is on the wheel's Lightbar
ZEDQA rt_veh PASS siren: the Lightbar brings the siren controller up close
ZEDQA rt_veh PASS siren: its plate is loaded (SirenPlate, PhysPx)
ZEDQA rt_veh PASS on screen (the siren controller): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_veh PASS siren: LIGHTS has its 1 position | lights:0 lights:1 lights:2 lights:3 lights:knob siren:0 siren:1 siren:2 siren:3 siren:knob
ZEDQA rt_veh PASS siren: a click on LIGHTS 1 turns the bar on (the game's command) | 1
ZEDQA rt_veh PASS siren: the dash's lightbar lamp follows | true
ZEDQA rt_veh PASS siren: a click on its OFF puts the bar back | 0
ZEDQA rt_veh PASS dash: a click on the ignition shuts the engine off
ZEDQA rt_veh PASS vehicle: the game's Vehicle Mechanics inspects the car and opens the World window's Vehicle tab
ZEDQA rt_veh PASS dash: out of the car, ZeD's dash is put away | in a car false, dash false
ZEDQA rt_veh PASS vehicle: the tab lists the car's parts | 41 of 41
ZEDQA rt_veh PASS vehicle: the parts' rows are drawn | 41
ZEDQA rt_veh PASS on screen (the Vehicle tab): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS vehicle: a click on a part's row opens its card | Muffler (want Muffler)
ZEDQA rt_veh PASS vehicle: the same row again closes the card | nil
ZEDQA home rt_veh moved from 916,13027,0 to the drag strip
ZEDQA car rt_veh took away a car an earlier spawn left behind
ZEDQA vp rt_veh player=925,13040 grid=19 chunks (152 tiles) loaded x 840-992 y 12952-13104 sq=910,13037 dist=15.9 chunk=true inMap=true car=Base.Trailer_Livestock at 910.0,13037.0 dist=15.9 vehicles=40
ZEDQA car rt_veh Base.Trailer_Livestock spawned on spot 12 (910,13037)
ZEDQA rt_veh PASS trailer: an animal trailer spawned beside the character | nil
ZEDQA rt_veh PASS trailer: ZeD's hook is on the game's Check Animals
ZEDQA rt_veh PASS trailer: Check Animals opens the Vehicle tab on the trailer's page | tab vehicle, trailer true
ZEDQA rt_veh PASS on screen (the trailer's page): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_veh PASS put back: the character out, the key taken back, the car removed
ZEDQA rt_veh end: 58 pass, 0 fail, 0 skipped
ZEDQA rt_veh VERDICT PASS 58
ZEDQA rt_veh DONE
```

### 7. rt_system.lua (`ZEDQA rt_sys`) - FAIL, 157 s

- go 30176 at 10:35:42
- 2 ERR line(s)
- its own checks failed (VERDICT FAIL)

```text
[ZeD.QA] state #7 speed=1 paused=false player=911,13039 grid=19 inCar=false vehicles=44 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rt_sys start (170 steps)
[ZeD.QA] run #7 ok=true
ZEDQA rt_sys PASS ZeD's settings, safe mode, main menu and scale modules are loaded
ZEDQA rt_sys PASS a changed setting is written to ModOptions.ini | file 2, want 2
ZEDQA rt_sys PASS the saved setting comes back when the game reads ModOptions.ini | value 2
ZEDQA rt_sys PASS the setting is put back, in memory and in the file | value 1, file 1
ZEDQA rt_sys PASS ModOptions.ini is back line for line | 64 lines, 64 before
ZEDQA rt_sys PASS the pause menu opens (ZeD's pause window)
ZEDQA rt_sys PASS Options opens from the pause menu (ZeD's window)
ZEDQA rt_sys PASS every Options group's page was opened | 9 of 9
ZEDQA rt_sys PASS ZeD setup opens with its groups and rows | 8 groups, 81 rows
ZEDQA rt_sys PASS Options, ZeD setup: the page opens, the window on screen | 81 rows
ZEDQA rt_sys PASS Options, Display: the page opens, the window on screen | 7 rows
ZEDQA rt_sys PASS Options, Graphics: the page opens, the window on screen | 30 rows
ZEDQA rt_sys PASS Options, Audio: the page opens, the window on screen | 19 rows
ZEDQA rt_sys PASS Options, Controls: the page opens, the window on screen | 118 rows
ZEDQA rt_sys PASS Options, Gameplay: the page opens, the window on screen | 35 rows
ZEDQA rt_sys PASS Options, Interface: the page opens, the window on screen | 29 rows
ZEDQA rt_sys PASS Options, Accessibility: the page opens, the window on screen | 8 rows
ZEDQA rt_sys PASS Options, Mods: the page opens, the window on screen | 64 rows
ZEDQA rt_sys PASS Options has ZeD setup
ZEDQA rt_sys PASS the Options pages drew with no Lua error | 0 new
ZEDQA rt_sys PASS Back leaves Options for the pause menu | pause
ZEDQA rt_sys PASS the pause menu shuts again
ZEDQA rt_sys PASS the Select wheel's ZeD setup row: the pause screen, then Options on its first page | view options, page 1, pause up true
ZEDQA rt_sys PASS on screen (ZeD setup from the Select wheel): every ZeD window and pop-up inside 3840x2160 | 0 seen
ZEDQA rt_sys PASS the pause menu shuts after the wheel's ZeD setup
ZEDQA rt_sys PASS Options: the game's Inventory font row is marked moot and takes no change | UI_ZeD_Options_MootInventoryFont, item 1 -> 1
ZEDQA rt_sys PASS Options: the game's Dyslexic font row says where it still works | UI_ZeD_Options_OnlyDyslexic
ZEDQA rt_sys PASS ZeD setup: the game settings it mirrors (Font size first) work the game's own control | 6 rows
ZEDQA rt_sys PASS Options, Find "scale": only the matching rows, UI scale among them | 1 of 342 rows, UI scale true
ZEDQA rt_sys PASS Options, Find cleared: ZeD setup's rows come back | 71 rows, 71 before
ZEDQA rt_sys PASS ZeD setup: every group has its heading and a named row for each of its options | 7 groups, 55 rows
ZEDQA rt_sys PASS ZeD setup: with Wheel toggle mode On, Wheel open and Wheel commit are dimmed and take no change | toggle true, open 1, commit 1
ZEDQA rt_sys PASS ZeD setup: with Toggle mode Off, Wheel open Hold and Wheel commit Stick click are read live | hold, click
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
ZEDQA rt_sys PASS ZeD setup, Defaults: every ZeD option's control is on the item it starts on | 53 rows
ZEDQA rt_sys PASS ZeD setup, Defaults: afterwards nothing is off its default (the button greys out)
ZEDQA rt_sys PASS Options: Discard after Defaults puts every control and the look back | | light / teal
ZEDQA rt_sys PASS Back leaves Options with nothing pending | pause
ZEDQA rt_sys PASS after ZeD setup's controls the scale is the run's own | root 1.75
ZEDQA rt_sys PASS on screen (the windows after ZeD setup's controls): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale UI_ZeD_Settings_ScaleAuto: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS on screen (UI scale UI_ZeD_Settings_ScaleAuto): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys SKIP UI scale 0.5x drawn at 0.5x (retired in the beta: ZeD setup's slider dims it and the wheel leaves it out)
ZEDQA rt_sys PASS UI scale 0.5x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.5x set by hand: drawn at the floor 0.75x, the saved pick kept | root 0.75, ZeD.T.root 0.75, item 2
ZEDQA rt_sys PASS on screen (UI scale 0.5x): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_sys PASS UI scale 0.75x: the theme follows the new scale and both windows are open again | root 0.75
ZEDQA rt_sys PASS UI scale 0.75x: drawn at that scale (ZeD.T.root) | root 0.75, ZeD.T.root 0.75
ZEDQA rt_sys PASS on screen (UI scale 0.75x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 1x: the theme follows the new scale and both windows are open again | root 1
ZEDQA rt_sys PASS UI scale 1x: drawn at that scale (ZeD.T.root) | root 1, ZeD.T.root 1
ZEDQA rt_sys PASS on screen (UI scale 1x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 1.25x: the theme follows the new scale and both windows are open again | root 1.25
ZEDQA rt_sys PASS UI scale 1.25x: drawn at that scale (ZeD.T.root) | root 1.25, ZeD.T.root 1.25
ZEDQA rt_sys PASS on screen (UI scale 1.25x): every ZeD window and pop-up inside 3840x2160 | 5 seen
ZEDQA rt_sys PASS UI scale 1.5x: the theme follows the new scale and both windows are open again | root 1.5
ZEDQA rt_sys PASS UI scale 1.5x: drawn at that scale (ZeD.T.root) | root 1.5, ZeD.T.root 1.5
ZEDQA rt_sys PASS on screen (UI scale 1.5x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 1.75x: the theme follows the new scale and both windows are open again | root 1.75
ZEDQA rt_sys PASS UI scale 1.75x: drawn at that scale (ZeD.T.root) | root 1.75, ZeD.T.root 1.75
ZEDQA rt_sys PASS on screen (UI scale 1.75x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale 2x: the theme follows the new scale and both windows are open again | root 2
ZEDQA rt_sys PASS UI scale 2x: drawn at that scale (ZeD.T.root) | root 2, ZeD.T.root 2
ZEDQA rt_sys PASS on screen (UI scale 2x): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS UI scale cap: every step fits this screen and there is no too-big line | cap 2
ZEDQA rt_sys PASS ZeD text follows the root scale: the body font's zoom is the root times its size at every step | 8 steps, zoom 0.15234375 to 0.40625
ZEDQA rt_sys PASS UI scale put back on the run's own step | option 7, root 1.75
ZEDQA layout rt_sys scale put back
ZEDQA rt_sys PASS on screen (the windows back after the scale steps): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS theme dark: the window box's Theme pick applies to ZeD's table and is saved as item 1 | dark, option 1
ZEDQA rt_sys PASS theme dark: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme dark: See-through is the player's pick | surfaceAlpha 0.9, want 0.9
ZEDQA rt_sys PASS on screen (theme dark): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS theme light: the window box's Theme pick applies to ZeD's table and is saved as item 2 | light, option 2
ZEDQA rt_sys PASS theme light: the accent is its light variant | rgb 26 102 85, want rgb 26 102 85
ZEDQA rt_sys PASS theme light: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme light): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS theme hicon: the window box's Theme pick applies to ZeD's table and is saved as item 3 | hicon, option 3
ZEDQA rt_sys PASS theme hicon: the accent is its dark variant | rgb 71 161 140, want rgb 71 161 140
ZEDQA rt_sys PASS theme hicon: See-through is forced solid | surfaceAlpha 1, want 1
ZEDQA rt_sys PASS on screen (theme hicon): every ZeD window and pop-up inside 3840x2160 | 7 seen
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
ZEDQA rt_sys PASS Solid while in use: the window box's row flips it and saves it | true -> false, option 1
ZEDQA rt_sys PASS Solid while in use: a second pick puts it back | true
ZEDQA rt_sys PASS Low-health pixel blink Off: the pixel holds lit | 41 of 41 moments lit
ZEDQA rt_sys PASS Low-health pixel blink On: the pixel blinks | 20 of 41 moments dark
ZEDQA rt_sys PASS Low-health pixel blink put back | true
ZEDQA rt_sys PASS Item-colored grid tiles: the switch is read back at once | true
ZEDQA rt_sys PASS Item-colored grid tiles put back | false
ZEDQA rt_sys PASS Item-colored grid tiles: the item colors are loaded (Acorn) | 8806442
ZEDQA rt_sys PASS Controller highlight hand: the window box's pick is read and saved | hand, option 1
ZEDQA rt_sys PASS Controller highlight corners: the window box's pick is read and saved | corners, option 2
ZEDQA rt_sys PASS Controller highlight wash: the window box's pick is read and saved | wash, option 3
ZEDQA rt_sys PASS Controller highlight ants: the window box's pick is read and saved | ants, option 4
ZEDQA rt_sys PASS the controller highlights drew with no Lua error | 0 new
ZEDQA rt_sys PASS Controller highlight put back | hand
ZEDQA rt_sys FAIL Immersive or simple forms: each form's getter follows its option at once (belt, devices, watch, dash, guide, mods, identity) | beltStyle false/false; devicesStyle false/false; watchStyle false/false; dashStyle false/false; guideStyle false/false; modsStyle false/false; identityStyle false/false
ZEDQA rt_sys PASS UI sounds: Off plays no click, Full plays it (a sound id) | Off nil, Full 60408832
ZEDQA rt_sys PASS Button glyph set: item 3 reads the PlayStation set, item 1 Auto | ps / auto
ZEDQA rt_sys PASS Test language On: within half a second a ZeD phrase reads stretched, in brackets | 240 ms, 15 letters, plain 9
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
ZEDQA rt_sys PASS the Safe mode option On is picked up by itself within a second | 235 ms
ZEDQA rt_sys PASS Safe mode On: the game's own pages, no trip note
ZEDQA rt_sys PASS never caught in safe mode: with safe mode On, Messages keeps no other mod's note
ZEDQA rt_sys PASS the Safe mode option Off is picked up by itself within a second | 493 ms
ZEDQA rt_sys PASS Safe mode Off: ZeD back
ZEDQA rt_sys PASS Safe mode recovery: switched Off, nothing of the game's own is left applied | applied false
ZEDQA rt_sys PASS with safe mode Off the same note would be kept again (the control)
ZEDQA rt_sys PASS Safe mode recovery: the ZeD Character and World windows open again
ZEDQA rt_sys PASS the watchdog: a five-frame burst of faults leaves ZeD on
ZEDQA rt_sys PASS the watchdog: under two seconds of faults ZeD stays on | 2021 ms, 121 frames
ZEDQA rt_sys PASS the watchdog: two seconds of faults every frame trip it | 2021 ms
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
ZEDQA rt_sys PASS Messages: the balloon goes after six seconds | 6021 ms
ZEDQA rt_sys PASS Messages, balloons Off: a new message shows no balloon | 0 balloons
ZEDQA rt_sys PASS put back: the balloon test's messages and the switch
ZEDQA rt_sys PASS Bug report: the count it returns is the caught errors' | 0, want 0
ZEDQA rt_sys PASS Bug report: the clipboard holds the report (it starts "ZeD-GUI ") | ZeD-GUI 0.3.0-beta21 | Project Zomboid 4
ZEDQA rt_sys PASS put back: the clipboard as it was | 9 characters, 9 before
ZEDQA rt_sys PASS on screen (the Messages window with its foot band): every ZeD window and pop-up inside 3840x2160 | 8 seen
ZEDQA rt_sys PASS Messages foot band: Pop-ups on saves the mod in ZeD_messages.txt, pressed again it is off | on true, in the file true, after false
ZEDQA rt_sys PASS Messages foot band: Mark all read leaves nothing unread | 1 -> 0
ZEDQA rt_sys PASS Messages foot band: Delete asks first and deletes nothing yet | asking true
ZEDQA rt_sys PASS Messages foot band: Yes to the question deletes the mod's messages | Yes button true
ZEDQA rt_sys PASS put back: every message's read mark, ZeD_messages.txt and the balloon switch | 0 marks off, 1 lines, 1 before
ZEDQA rt_sys soak start: 1841152 KB, 0 Lua errors so far
ZEDQA rt_sys PASS the soak ran its two minutes | 120 s
ZEDQA rt_sys PASS the soak: no Lua error in two minutes with the windows open | 0 new
ZEDQA rt_sys PASS the soak: Lua memory grows by no more than 262144 KB | 1841152 KB -> 1837056 KB (-4096 KB)
ZEDQA rt_sys PASS on screen (the windows after the soak): every ZeD window and pop-up inside 3840x2160 | 7 seen
ZEDQA rt_sys PASS every key in ZeD's English UI.json has text in the game | 6933 keys
ZEDQA rt_sys PASS every ZeD key read while the script ran has text | 415 keys
ZEDQA rt_sys PASS every game key ZeD borrowed while the script ran has text | 52 keys
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
ZEDQA rt_sys PASS put back: ModOptions.ini is as found, line for line | 64 lines, 64 before
ZEDQA rt_sys end: 201 pass, 1 fail, 2 skipped
ZEDQA rt_sys VERDICT FAIL 1
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
