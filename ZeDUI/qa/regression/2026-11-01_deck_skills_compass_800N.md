# ZeD-UI regression - 2026-11-01 15:23 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-01 15:23:07 |
| Finished | 2026-11-01 15:25:54 (2 min 47 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\AppData\Local\Temp\claude\C--Users-danie--claude-spares-spare-8vLpAQ\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\deck_skills_compass_manifest.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 18025 to 18030 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 18029, 18030)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_probe_skills_down.lua | pskd | PASS | 7 | zqa_pskd_pass1.png, zqa_pskd_pass2_large.png |  |
| 3 | zedqa_world_pad_take.lua | wpt | WARN | 61 |  | 1 ERR line(s) |
| 4 | zedqa_probe_compass.lua | cmp | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 18025 at 15:24:08

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_probe_skills_down.lua (`ZEDQA pskd`) - PASS, 7 s

- go 18026 at 15:24:12
- screenshots: zqa_pskd_pass1.png, zqa_pskd_pass2_large.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA pskd ---- pass1: small text, screen 1280x800, root 0.750
ZEDQA pskd view h 278 | scroll 0.000 | one column false | drawer 360 px
ZEDQA pskd training stops in the ring: 24 of 60 stops in charTabContent
ZEDQA pskd focus on the first col1 training stop: table 0x1377340235{ x=6, y=578.984375, w=164, h=20, id=training:col1_Aiming, trainingId=col1_Aiming, onFocus=closure 0x2038492036, onActivate=closure 0x1658618082 } -> training:col1_Aiming x 6 y 578.984375 w 164 h 20
ZEDQA pskd Down 1 -> training:col1_Blacksmith x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.612 | one column false | drawer 360 px
ZEDQA pskd Down 2 -> training:col1_Butchering x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.649 | one column false | drawer 360 px
ZEDQA pskd Down 3 -> training:col1_Carpentry x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.687 | one column false | drawer 360 px
ZEDQA pskd Down 4 -> training:col1_Carving x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.725 | one column false | drawer 360 px
ZEDQA pskd Down 5 -> training:col1_Cooking x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.762 | one column false | drawer 360 px
ZEDQA pskd Down 6 -> training:col1_Electricity x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.800 | one column false | drawer 360 px
ZEDQA pskd Down 7 -> training:col1_Farming x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.837 | one column false | drawer 360 px
ZEDQA pskd Down 8 -> training:col1_FirstAid x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.875 | one column false | drawer 360 px
ZEDQA pskd Down 9 -> training:col1_Fishing x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.912 | one column false | drawer 360 px
ZEDQA pskd Down 10 -> training:col1_FlintKnapping x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.950 | one column false | drawer 360 px
ZEDQA pskd Down 11 -> training:col1_Foraging x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.987 | one column false | drawer 360 px
ZEDQA pskd Down 12 -> training:col1_Foraging x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.987 | one column false | drawer 360 px
ZEDQA pskd Down 13 -> training:col1_Foraging x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.987 | one column false | drawer 360 px
ZEDQA pskd ended on training:col1_Foraging x 6 y 258.984375 w 164 h 20 | view h 278 | scroll 0.987 | one column false | drawer 360 px
ZEDQA pskd training stops below the last one: 0
ZEDQA pskd dry run of Down: nil:nil (nil)
ZEDQA pskd stamped training zones this frame: 24 | the first col1_Aiming x 6 y 27.984375 w 164 h 20 | the last col2_Trapping x 178 y 258.984375 w 164 h 20
ZEDQA pskd text size -> large
ZEDQA pskd ---- pass2_large: large text, screen 1280x800, root 0.750
ZEDQA pskd view h 273 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd training stops in the ring: 24 of 60 stops in charTabContent
ZEDQA pskd focus on the first col1 training stop: table 0x1114667286{ x=7, y=-1.109375, w=189, h=22, id=training:col1_Aiming, trainingId=col1_Aiming, onFocus=closure 0x1496966024, onActivate=closure 0x1775141505 } -> training:col1_Aiming x 7 y -1.109375 w 189 h 22
ZEDQA pskd Down 1 -> training:col1_Blacksmith x 7 y 55.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 2 -> training:col1_Butchering x 7 y 78.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 3 -> training:col1_Carpentry x 7 y 101.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 4 -> training:col1_Carving x 7 y 124.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 5 -> training:col1_Cooking x 7 y 147.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 6 -> training:col1_Electricity x 7 y 170.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 7 -> training:col1_Farming x 7 y 193.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 8 -> training:col1_FirstAid x 7 y 216.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 9 -> training:col1_Fishing x 7 y 239.890625 w 189 h 22 | view h 273 | scroll 0.937 | one column false | drawer 414 px
ZEDQA pskd Down 10 -> training:col1_FlintKnapping x 7 y 251.890625 w 189 h 22 | view h 273 | scroll 0.954 | one column false | drawer 414 px
ZEDQA pskd Down 11 -> training:col1_Foraging x 7 y 251.890625 w 189 h 22 | view h 273 | scroll 0.988 | one column false | drawer 414 px
ZEDQA pskd Down 12 -> training:col1_Foraging x 7 y 251.890625 w 189 h 22 | view h 273 | scroll 0.988 | one column false | drawer 414 px
ZEDQA pskd Down 13 -> training:col1_Foraging x 7 y 251.890625 w 189 h 22 | view h 273 | scroll 0.988 | one column false | drawer 414 px
ZEDQA pskd ended on training:col1_Foraging x 7 y 251.890625 w 189 h 22 | view h 273 | scroll 0.988 | one column false | drawer 414 px
ZEDQA pskd training stops below the last one: 0
ZEDQA pskd dry run of Down: nil:nil (nil)
ZEDQA pskd stamped training zones this frame: 24 | the first col1_Aiming x 7 y -1.109375 w 189 h 22 | the last col2_Trapping x 205 y 251.890625 w 189 h 22
ZEDQA pskd text size back to small | DONE
```

### 3. zedqa_world_pad_take.lua (`ZEDQA wpt`) - WARN, 61 s

- go 18027 at 15:24:22
- 1 ERR line(s)

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #3 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@43
ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldMainInv:invrow:1 (Firefighter Axe Head)
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldMainInv:invrow:1 (Firefighter Axe Head)
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
ZEDQA wpt 3 timing: card buttons ready after 9 ticks, 8 frames; focus in the card after 9 ticks, 8 frames (watched 9 ticks, 8 frames)
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
ZEDQA wpt 6 Right: Char charTabContent:training:col1_Foraging
ZEDQA wpt FAIL Right from a row lands on the bag on show
ZEDQA wpt PASS Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on the nails: focus is on the card's primary action (DROP)
ZEDQA wpt PASS Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is DROP; A runs it
ZEDQA wpt PASS A on the card's primary action (Drop) moved the nails out of the bag (10 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (EQUIP)
ZEDQA wpt 6 after B: Char charMainInv:invrow:4 (Broken Large Handle)
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
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 276 of 278)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 266 of 278)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control health:exercise is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 284 px in a 222 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:view is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 273 of 278)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 268 of 278)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:__save is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 278 of 278)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 271 of 278)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:sortMenu is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 28 of 278)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 28 of 278)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:style:survey is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:search is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 World vehicle small pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 274 of 278)
ZEDQA wpt PASS 7 World vehicle small wheel: the lowest control mech:inspect is in view at the bottom (bottom 274 of 278)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 268 of 273)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 260 of 273)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control health:exercise is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 301 px in a 210 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:view is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 268 of 273)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 262 of 273)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:__save is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 273 of 273)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 265 of 273)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:sortMenu is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 32 of 273)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 32 of 273)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:style:survey is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:search is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 269 of 273)
ZEDQA wpt PASS 7 World vehicle large pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 269 of 273)
ZEDQA wpt PASS 7 World vehicle large wheel: the lowest control mech:inspect is in view at the bottom (bottom 269 of 273)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 92 passed, 1 failed
ZEDQA wpt DONE
```

### 4. zedqa_probe_compass.lua (`ZEDQA cmp`) - PASS, 1 s

- go 18028 at 15:25:27

```text
[ZeD.QA] windows reset (R)
ZEDQA cmp PASS a find 5 east, 0 south of the character: E (want E) dist 5
ZEDQA cmp PASS a find 0 east, -5 south of the character: N (want N) dist 5
ZEDQA cmp PASS a find -5 east, 0 south of the character: W (want W) dist 5
ZEDQA cmp PASS a find 0 east, 5 south of the character: S (want S) dist 5
ZEDQA cmp PASS a find 5 east, -5 south of the character: NE (want NE) dist 7
ZEDQA cmp PASS a find -5 east, -5 south of the character: NW (want NW) dist 7
ZEDQA cmp PASS a find -5 east, 5 south of the character: SW (want SW) dist 7
ZEDQA cmp PASS a find 5 east, 5 south of the character: SE (want SE) dist 7
ZEDQA cmp 8 of 8 headings right
[ZeD.QA] run #4 ok=true
ZEDQA cmp DONE
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
