# QA b12 checks, round 2 (Nov 12 2026)

Main commit at the start: ea7e6668f. Everything ran at 4K fullscreen (3840x2160, UI scale 1.75x) unless said otherwise, with -debug -nosteam on the ZeD-QA save. Pictures: Zomboid/Screenshots/b12_round2_20261112/<part> (outside the repo).

## Part 1. The sims

Ran: python ZeDUI/tools/qa/run_sims.py (the local Python 3.12). 124 sims, 3,894,742 checks in all, 0 not clean (no failure, no crash, no missing count), 255 s.
List A: none. List B: none. Not run: none.

## Part 2. The trimmed main run

Ran: zedqa_run.ps1 -Manifest ZeDUI/tools/qa/main_run.txt at 4K fullscreen (87 scripts, about 47 minutes). Report: ZeDUI/qa/regression/2026-11-12_2006_fullscreen4k.md. Result: 75 pass, 10 warn, 2 fail, 0 timeout, 0 not run. The game loaded and stayed up the whole run. Pictures: Zomboid/Screenshots/b12_round2_20261112/p2.
cov_input, cov_vehicles, cov_equipfurn, cov_reading, cov_b9to11 and pad_figure are in main_run.txt, so they ran there and were not run again.

### List A (real mod bugs)
1. The Fishing tab has no picture on the wheel (the same item as Part 4's wheel check).
   Line: `ZEDQA wi FAIL 144 slices on ZeD's five wheels, 126 with a wheel icon, the rest items, glyphs or colours: right > Tabs > Fishing: rod is no icon`
   Picture: Zomboid/Screenshots/b12_round2_20261112/p2/zqa_wi_dpad_right.png (the right wheel; the Tabs slice).

### List B (test trouble)
- Car scripts. Every `ZEDQA car ...` line is copied in full below. No spot was refused for its floor; all 40 lines name spot 9 (917,13037). The failures are the spot being taken: an earlier script's car stays on it ("a car on it at 916,13034"), so the next spawn refuses. That cascades:
  - dpx 23_meadesheriff and 24_lcpd: `ZEDQA dpx FAIL 23_meadesheriff: the character got into the car` and the 24_lcpd twin (spawn refused, spot 9 taken).
  - m79: `ZEDQA m79 summary: 35 of 37 checks FAIL` (no car on any of its five spawns, so every check on the car read nil).
  - dl: its elite car spawn failed; its hover-chip and lamp FAILs read from a different car than the one staged (unclear whether any lamp line is real; the chip text itself was found: "nil: Battery | table 0x... { 1=Condition 100%, 2=Charge 97% }" means the hover chip exists but the check's expected shape differs. Unclear).
  - dgr: six spawns refused the same way ("dgr ERR ... spawn failed"; its design checks read the wrong car).
  - wi: `ZEDQA wi not run: in the car (the car is not ready (no square, no chunk or its physics never woke))`, twice.
  - pb: `ZEDQA pb not run: the tire scene (no deep-run car within 10 tiles)`.
- cov_input: `ZEDQA cov_input FAIL input mode: a pad unplugged with none left goes back to mouse and keys (not checked: 1 real pad(s) connected: the unplug would reach the game's own pad handlers)`. A real pad is plugged in on this machine; the script says itself it did not check.
- cov_vehicles: `ZEDQA cov_vehicles FAIL slack: the rod gets the slack tension, vanilla's dial its own angle (nil vs -0.6 / -62)`. Unclear: the ZeD value reads nil, which may be the test reading the plate before it drew, or a real gap. One line, one sentence for Build.
- cov_equipfurn (14 ERR lines). Unclear, leaning test staging: the furniture lines (Rotate south, Repair/Pick up "ON THIS TILE" rows, Disassemble) read cursor and tile values that differ by one tile (cursor 4 vs 3 on 926,13040), a staged piece not under the cursor. The defense lines are unclear and worth a human look, they may be real: `ZEDQA cov_equipfurn FAIL outfit: average bite over all parts (27 vs 30)`, `ZEDQA cov_equipfurn FAIL a garment held in the hand is not counted as worn (7 vs 6)` and the layered-defense lines (7 parts differ, first ForeArm_L bite 20 vs game 27).
- cov_reading. Unclear: the recipe lines (`each row is locked or open as the game's own rule says ... (9 off (first MakeBoneForearmArmor shows unlocked) vs 0 off)`, the Category list click, Show Known) disagree with the game's rule or with the staged list; they may be real. The newspaper lines (`KnoxKnews_July1: the body sets at a readable size, 11.5 or more (... 0.46 vs >= 11.5)`, `story 2 column 3 wide`, `NationalDispatch_July6: ... story 3 drawn to 812.2, room to 801.0`) look like a page read at the wrong size in this run; unclear.
- cov_b9to11: `ZEDQA cov_b9to11 FAIL [a 1.75x] #134 color: a map mod's label ... (isVisible false (PlaceNames false, user defined false) ...)`. Unclear: the check needs the map's Place Names option on, and it reads false.
- soak: `ZEDQA soak FAIL after the run, the reader shut: 37 UI elements (35 at the start; the reader's own window may stay as one)`. Two extra elements; the script itself allows one for the reader. Unclear, could be a small leak (real) or leftover windows from earlier scripts.
- cov_objcards: 82 pass, 0 fail (the old setAxis failure did not show).
- wi: the other 3 lines of its WARN are the car "not run" lines above.

### Not run (Part 2)
- The wheel and car scenes above (wi "in the car", pb tire scene): not run, car scenes.
- cov_input's pad-unplug step: not checked, a real pad is connected.

### Every `ZEDQA car ...` line, verbatim
```
ZEDQA car wi Base.PickUpTruck spawned on spot 9 (917,13037)
ZEDQA car dw Base.CarNormal spawned on spot 9 (917,13037)
ZEDQA car pg Base.CarNormal spawned on spot 9 (917,13037)
ZEDQA car cov_vehicles Base.CarLightsPolice spawned on spot 9 (917,13037)
ZEDQA car dpx Base.CarLuxury spawned on spot 9 (917,13037)
ZEDQA car dpx Base.CarNormal spawned on spot 9 (917,13037)
ZEDQA car dpx Base.SportsCar spawned on spot 9 (917,13037)
ZEDQA car dpx Base.CarLightsPolice spawned on spot 9 (917,13037)
ZEDQA car dpx Base.PickUpTruck spawned on spot 9 (917,13037)
ZEDQA car dpx Base.ModernCar spawned on spot 9 (917,13037)
ZEDQA car dpx Base.ModernCar02 spawned on spot 9 (917,13037)
ZEDQA car dpx Base.SmallCar spawned on spot 9 (917,13037)
ZEDQA car dpx Base.SmallCar02 spawned on spot 9 (917,13037)
ZEDQA car dpx Base.CarStationWagon spawned on spot 9 (917,13037)
ZEDQA car dpx Base.SUV spawned on spot 9 (917,13037)
ZEDQA car dpx Base.VanSpiffo spawned on spot 9 (917,13037)
ZEDQA car dpx Base.PickUpVan spawned on spot 9 (917,13037)
ZEDQA car dpx Base.OffRoad spawned on spot 9 (917,13037)
ZEDQA car dpx Base.CarTaxi spawned on spot 9 (917,13037)
ZEDQA car dpx Base.VanAmbulance spawned on spot 9 (917,13037)
ZEDQA car dpx Base.PickUpTruckLightsFire spawned on spot 9 (917,13037)
ZEDQA car dpx Base.CarLightsRanger spawned on spot 9 (917,13037)
ZEDQA car dpx Base.RaceCar12 spawned on spot 9 (917,13037)
ZEDQA car dpx Base.Van_KnoxDisti spawned on spot 9 (917,13037)
ZEDQA car dpx Base.PickUpTruckLightsFossoil spawned on spot 9 (917,13037)
ZEDQA car dpx Base.CarNormalSmashedFront spawned on spot 9 (917,13037)
ZEDQA car dpx spawn failed Base.ModernCarLightsMeadeSheriff: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dpx spawn failed Base.CarLightsLouisvilleCounty: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car m79 spawn failed Base.CarNormal: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car m79 spawn failed Base.PickUpTruck: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car m79 spawn failed Base.Van: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car m79 spawn failed Base.SportsCar: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car m79 spawn failed Base.Trailer: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dl spawn failed Base.ModernCar: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dgr spawn failed Base.PickUpTruck: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dgr spawn failed Base.ModernCar: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dgr spawn failed Base.ModernCar02: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dgr spawn failed Base.SUV: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dgr spawn failed Base.CarLuxury: spot 9 (917,13037): a car on it at 916,13034
ZEDQA car dgr spawn failed Base.SportsCar: spot 9 (917,13037): a car on it at 916,13034
```

### navmap LIST lines, verbatim (87)
```
ZEDQA nav LIST trap: char equip trap equipslot:doll:torso
ZEDQA nav LIST trap: char equip trap equipslot:doll:hands
ZEDQA nav LIST trap: char equip trap equipslot:doll:belt
ZEDQA nav LIST trap: char equip trap equipslot:doll:legs
ZEDQA nav LIST trap: char equip trap equipslot:doll:feet
ZEDQA nav LIST trap: char equip trap equipslot:doll:head
ZEDQA nav LIST trap: char equip trap equipslot:doll:eyes
ZEDQA nav LIST trap: char equip trap equipslot:doll:neck
ZEDQA nav LIST trap: char equip trap equipslot:doll:outer
ZEDQA nav LIST trap: char equip trap equipslot:doll:back
ZEDQA nav LIST trap: char equip trap equipslot:doll:arms
ZEDQA nav LIST trap: char equip trap equipslot:doll:ears
ZEDQA nav LIST trap: char equip trap equipslot:doll:eartop
ZEDQA nav LIST trap: char equip trap equipslot:doll:nose
ZEDQA nav LIST trap: char equip trap equipslot:doll:necklace
ZEDQA nav LIST trap: char equip trap equipslot:doll:necklacelong
ZEDQA nav LIST trap: char equip trap equipslot:doll:gorget
ZEDQA nav LIST trap: char equip trap equipslot:doll:padl
ZEDQA nav LIST trap: char equip trap equipslot:doll:padr
ZEDQA nav LIST trap: char equip trap equipslot:doll:padsport
ZEDQA nav LIST trap: char equip trap equipslot:doll:elbowl
ZEDQA nav LIST trap: char equip trap equipslot:doll:elbowr
ZEDQA nav LIST trap: char equip trap equipslot:doll:wristl
ZEDQA nav LIST trap: char equip trap equipslot:doll:wristr
ZEDQA nav LIST trap: char equip trap equipslot:doll:forearml
ZEDQA nav LIST trap: char equip trap equipslot:doll:forearmr
ZEDQA nav LIST trap: char equip trap equipslot:doll:belly
ZEDQA nav LIST trap: char equip trap equipslot:doll:holster
ZEDQA nav LIST trap: char equip trap equipslot:doll:lmiddle
ZEDQA nav LIST trap: char equip trap equipslot:doll:lring
ZEDQA nav LIST trap: char equip trap equipslot:doll:rmiddle
ZEDQA nav LIST trap: char equip trap equipslot:doll:rring
ZEDQA nav LIST trap: char equip trap equipslot:doll:satchel
ZEDQA nav LIST trap: char equip trap equipslot:doll:airtank
ZEDQA nav LIST trap: char equip trap equipslot:doll:tail
ZEDQA nav LIST trap: char equip trap equipslot:doll:fpfront
ZEDQA nav LIST trap: char equip trap equipslot:doll:fpback
ZEDQA nav LIST trap: char equip trap equipslot:doll:webbing
ZEDQA nav LIST trap: char equip trap equipslot:doll:ammo
ZEDQA nav LIST trap: char equip trap equipslot:doll:beltholster
ZEDQA nav LIST trap: char equip trap equipslot:doll:kneel
ZEDQA nav LIST trap: char equip trap equipslot:doll:kneer
ZEDQA nav LIST trap: char equip trap equipslot:doll:thighl
ZEDQA nav LIST trap: char equip trap equipslot:doll:thighr
ZEDQA nav LIST trap: char equip trap equipslot:doll:shinl
ZEDQA nav LIST trap: char equip trap equipslot:doll:shinr
ZEDQA nav LIST trap: char equip trap equipslot:doll:gaiterl
ZEDQA nav LIST trap: char equip trap equipslot:doll:gaiterr
ZEDQA nav LIST trap: char equip trap equipslot:doll:ankleholster
ZEDQA nav LIST trap: char equip trap equipslot:doll:main
ZEDQA nav LIST trap: char equip trap equipslot:doll:off
ZEDQA nav LIST trap: char identity trap hb:part
ZEDQA nav LIST trap: char skills trap skill:Aiming
ZEDQA nav LIST trap: char skills trap skill:Reloading
ZEDQA nav LIST trap: char skills trap skill:Blacksmithing
ZEDQA nav LIST trap: char skills trap skill:Carpentry
ZEDQA nav LIST trap: char skills trap skill:Carving
ZEDQA nav LIST trap: char skills trap skill:Cooking
ZEDQA nav LIST trap: char skills trap skill:Electrical
ZEDQA nav LIST trap: char skills trap skill:Glassmaking
ZEDQA nav LIST trap: char skills trap skill:Knapping
ZEDQA nav LIST trap: char skills trap skill:Masonry
ZEDQA nav LIST trap: char skills trap skill:Mechanics
ZEDQA nav LIST trap: char skills trap skill:Pottery
ZEDQA nav LIST trap: char skills trap skill:Tailoring
ZEDQA nav LIST trap: char skills trap skill:Welding
ZEDQA nav LIST trap: char skills trap skill:First Aid
ZEDQA nav LIST trap: char skills trap skill:Fishing
ZEDQA nav LIST trap: char skills trap skill:Foraging
ZEDQA nav LIST trap: char skills trap skill:Tracking
ZEDQA nav LIST trap: char skills trap skill:Trapping
ZEDQA nav LIST trap: char skills trap skill:Axe
ZEDQA nav LIST trap: char skills trap skill:Long Blade
ZEDQA nav LIST trap: char skills trap skill:Long Blunt
ZEDQA nav LIST trap: char skills trap skill:Maintenance
ZEDQA nav LIST trap: char skills trap skill:Short Blade
ZEDQA nav LIST trap: char skills trap skill:Short Blunt
ZEDQA nav LIST trap: char skills trap skill:Spear
ZEDQA nav LIST trap: char skills trap skill:Agriculture
ZEDQA nav LIST trap: char skills trap skill:Animal Care
ZEDQA nav LIST trap: char skills trap skill:Butchering
ZEDQA nav LIST trap: char skills trap skill:Fitness
ZEDQA nav LIST trap: char skills trap skill:Lightfooted
ZEDQA nav LIST trap: char skills trap skill:Nimble
ZEDQA nav LIST trap: char skills trap skill:Running
ZEDQA nav LIST trap: char skills trap skill:Sneaking
ZEDQA nav LIST trap: char skills trap skill:Strength
```

(navmap also printed: char equip TRAP 51, char identity TRAP 1 {hb:part}, char skills TRAP 35 {skill:...}; all other tabs 0 traps, 0 islands.)

## Part 3. The shared row sizes (punch list 178)

Ran: a short bridge script of my own (kept out of the repo) after the prelude, which sets the default layout with the console closed. For each of the text sizes ZeD has, it set the size, then put the Character and World windows side by side on four pairs of tabs and took a picture of each: Loot (Character) + Crafting (World); Health + (World on its own Loot); Skills + Crafting; Loot + Forage. At 4K fullscreen (UI scale 1.75x) and at 1280x800 windowed (UI scale 0.75x, the run's Auto). Reports: ZeDUI/qa/regression/2026-11-12_b12r2_p3_4k.md and ..._p3_deck.md (each 2/2 pass). Pictures: Zomboid/Screenshots/b12_round2_20261112/p3 (16 files, zqa_p3_<4k|deck>_<small|large>_<char tab>_<world tab>.png).

Sizes: ZeD's own text size has only Small and Large (the Normal preset is gone from ZeD: Settings.lua lists small and large only; a saved Medium falls back to Small). So "Normal" was not a separate size; Small is ZeD's normal. Not run: a third size.

Measured values printed by the script: 4K Small strip 65 px, sort bar 35 px; 4K Large 75 and 41. Deck Small 28 and 15; Deck Large 32 and 18. Both are one number for everything at a size; they grow from Small to Large and with the UI scale.

What the pictures show:
- Row 1 (the strip under the title bar): one height across both windows, and the container strips on both sides line up with it edge to edge: the "Inventory" and "Ground" headers, the Skills and Health headings, the Crafting Station / Category / Find row and the side strips' top cells all sit in the same band. Yes at Small and at Large, at 4K and at the Deck size.
- Row 2 (the sorting bar): one height and one line across both windows on Loot and Crafting ("Name / Cat / Status / Wt" beside the Crafting list's "All Recipes" line) at both sizes and both screens. The Health and Skills tabs have no sort row of their own, so only the Inventory's sort row shows there.
- Text fit: fits at every case except one, below.

### List A (real mod bugs)
- At Large on the 1280x800 screen the Character window's header word "Inventory" is cut to "Invent..." (the window is 276 px wide there). Picture: Zomboid/Screenshots/b12_round2_20261112/p3/zqa_p3_deck_large_loot_craft.png. Minor; the items' names also take ellipses at that width, as designed.
### List B: none. Not run: Normal as a third size (does not exist); the Journal and Foraging sort rows were not pictured (Forage appears in the Loot + Forage pictures).

## Part 4. Build's remaining check list

Ran (reports in ZeDUI/qa/regression/: 2026-11-12_b12r2_p4_4k.md, _p4_deck.md, _fishing_4k.md, _cn_4k.md, _ch_4k.md). Pictures: Zomboid/Screenshots/b12_round2_20261112/p4 (tooltips, console, window pictures, tab search, hair and beard), p4fish, p4cn.
For the by-hand items I wrote one short bridge script of my own (kept out of the repo) and ran it at 4K and at 1280x800.

- zedqa_container_controls.lua: ran inside the main run (tag ct): PASS, 27 s.
- cov_input, cov_vehicles, cov_equipfurn, cov_reading, cov_b9to11: all in main_run.txt, so they ran there (Part 2), not again.
- Game's Tooltip Font option: PASS. A tooltip built with ZeD's tooltip code at 4K measured 420 x 192 at Small, 455 x 214 at Medium, 508 x 236 at Large (and 180 / 195 / 218 wide at 1280x800); the text is visibly bigger in the pictures p4/zqa_p4_4k_tooltip_Small.png and _Large.png. The sim (coverage_bugs_sim, TOOLTIP part) is clean.
- "Previous" on the first of several object cards wraps to the last: PASS on the real code in the game (OC.browse on a three-object list: Previous from 1 gives 3, Next from 3 gives 1, under the game's own Kahlua). Not checked on a staged set of two or more real objects in reach: needs staging. Also a sim (coverage_bugs_sim, BROWSE).
- Two-way radio, CH down on channel 01 goes to the last stored channel: now a sim (coverage_bugs_sim, CHANNEL, clean). Not checked in the game: needs a staged two-way set with stored channels.
- Hold LB, tap RB zooms in; hold RB, tap LB zooms out: now a sim (coverage_bugs_sim, CHORD, clean). Not checked in the game: needs a pad on the path (a real pad is connected but nobody was there to press).
- Hidden belt hands show no hover text: now a sim (coverage_bugs_sim, HANDS, clean). Not checked in the game.
- Window and inventory fixes, pictured at 4K and 1280x800 (char_loot, char_equip, char_health; the Part 3 pictures show the World window too):
  - Weight reads "0.0 / 8 kg" in the Inventory header and title bar with "63 items" under it: the form is right (the QA character carries 0.0 of 8, not 5.8 of 28: a bag with a load was not staged). "5.8 / 28 kg" appears only in my sample tooltip text.
  - The title bar shows names, units and words (Angel Cross, Flashlight | 100%, 0.0 / 8 kg, Ground, 18 items), no bare number: seen in all pictures.
  - Not checked (needs staging, or is a sim now): a bare character's header over "Nothing here."; "Belt n" and "In hand" tags with the square marker; the Category column running into an empty Cond cell; no trunk prompt in the gap between paired windows (no trunk open); Loot column Filter focus staying put (inventory_filter_sim holds the logic); a saved window position closing Loot columns (window_saved_pos_sim).
- Fishing live (zedqa_fishing_tab_live): PASS, 2/2 (33 PASS lines, no ERR or FAIL line), pictures in p4fish. The reload half (tag ftr) was not run (it needs a quit and a second launch).
- zedqa_hairbeard.lua: every check FAILed from the start: `ZEDQA hb FAIL the Character window is on Identity` came first (the script did not reach the Identity tab, so the rest read 0 or nil). List B, unclear whether the tab id moved. Not checked: hair and beard.
- Tab search on Skills and Equipment with the pad path (zedqa_tab_search): the pad lines passed: `A on the field: the pad keyboard opens`, `under the keyboard: the hand on the field`, `X on the field clears`, `the field is a stop in the tab's zone`; one pad line failed: `ZEDQA ts FAIL RT: the hand lands on the first match | skill:Blacksmithing`. Typed-text lines failed too: `Skills 'bla': some kept, the rest dimmed`, `'combat'`, `'piloting': nothing matches`, `Clear empties the field`, `Equipment 'hand'`, `Defense block hides` / `is back` (the cook and foot lines passed). All of those drive the field by script text, not typed keys: List B, unclear (a real gap in the filter is possible; tab_search_sim is the logic check and is clean). Not checked: "B leaves" and "doors still open with A afterwards" (the script has no such step; needs a pad).
- The Fishing tab has a picture on the wheel: FAIL, a real gap, see List A (the same line as Part 2).
- Chinese speech balloon (language CN): the four-character string built with string.char (E6 90 9C E5 88 AE E7 8A B6 E6 80 81) draws garbled, not as Chinese; see List A. Picture: p4cn/zqa_cn_CN_balloon.png.
- Two tabs in CN (Health + Crafting, Skills + Foraging) and two in CH (the same): whole, sharp, no boxes and no cut text at 4K. Pictures: p4cn/zqa_cn_CN_health_craft.png, zqa_cn_CN_skills_forage.png, zqa_cn_CH_health_craft.png, zqa_cn_CH_skills_forage.png. Language put back to EN (options.ini restored whole).
- The console in -debug, through the game's own ProcessCommand route (ZeD's DebugConsole.run, the call the box's Enter makes; I did not type keys): `local x = nil; x.y = 1` run three times gave TWO error rows, each with a count of 3 (one from the game's box with the Java line `zombie.ui.UIDebugConsole.ProcessCommand(UIDebugConsole.java:391)`, one from the F11 list with `attempted index of non-table`), not one row; each opens to its stack. See List A. `print("a","b")`: a row "a b" was found twice at 4K and none at 1280x800; unclear. Pictures: p4/zqa_p4_4k_console_errors.png, zqa_p4_4k_console_error_opened.png, zqa_p4_4k_console_print_ab.png and the _deck twins.

### List A (real mod bugs), Part 4
1. `ZEDQA wi FAIL 144 slices on ZeD's five wheels, 126 with a wheel icon, the rest items, glyphs or colours: right > Tabs > Fishing: rod is no icon` (Part 2's line; the Fishing tab's slice has no picture). Picture: p2/zqa_wi_dpad_right.png.
2. Chinese balloon garbled: the balloon shows Latin-1 shapes (the bytes read as single letters) for the bytes E6 90 9C ... when the game language is CN. Picture: p4cn/zqa_cn_CN_balloon.png. Caveat: the string reached the game through the player's Say with the bytes as separate characters; if the balloon expects another hand-over, this is the check's route, not the mod's. I followed the director's description exactly.
3. The console's error rows: the same error run three times is two rows, not one (the box row and the F11 row do not merge when their messages differ). Lines: `ZEDQA p4 C errrow n=3 box=3 f11=nil mod=ZeD-GUI msg=zombie.ui.UIDebugConsole.ProcessCommand(UIDebugConsole.java:391) stack=47` and `ZEDQA p4 C errrow n=3 box=nil f11=3 mod=ZeD-GUI msg=attempted index of non-table stack=73`. Pictures: p4/zqa_p4_deck_console_errors.png and the 4K twin.
4. Part 3's "Invent..." cut at Large on 1280x800.

### List B (test trouble), Part 4
- hairbeard: the Identity tab step failed (above).
- tab_search: typed-text lines drive the field by script text; unclear.
- At 4K the print rows were listed twice: unclear whether the console shows each print twice or my listing counted twice.

### Not run / not checked, Part 4
Object cards on real staged objects; the two-way set; LB/RB zoom on the pad path; hidden belt hands hover; bare character header; Belt n / In hand tags; Category into an empty Cond cell; trunk prompt gap; Filter focus; saved position; hair and beard; "B leaves" and A on doors in tab search; the fishing reload half.

## Part 5. The drawn controller (pad_figure)

Ran: pad_figure.txt at 4K inside the main run (tag padfig, PASS, 31 PASS lines; pictures p2/zqa_padfig_*_3840x2160.png) and at 1280x800 windowed by its own manifest (2/2 pass, 29 PASS lines, no FAIL; pictures p5/zqa_padfig_*_1280x800.png; report 2026-11-12_b12r2_padfig_deck.md). The Deck run reports ZeD scale 0.75, k 2, the pad 376x212 in a 732x416 box.
List A: none. List B: none. Not run: the real controller steps below.

### For the director's controller session
With a controller in hand, on Options > Controls > Button map and test:
- each face button, View, Menu and both bumpers: held, it fills with the accent; a face button and View / Menu sit one art pixel down and right, their shadow gone
- each D-pad arm: that arm lights with its arrow; the D-pad's label picture shows the arm
- each stick: the cap follows the push (up is up), the label's dial dot too; a click lights the cap
- each trigger: fills from the bottom row up as it is pulled, the label's percent counts to 100
- the D-pad walks the labels (one stop each); A opens a label's actions; on a stick or the D-pad A first asks which element; B there goes back, B again closes; B on the page backs out
- Test controller: pick the pad, the page leaves the buttons alone; A and Y held together end the test
- the same with the button pictures on PlayStation (the D-pad up top) and on Xbox (the left stick up top)

## Part 6. Summer Car with the mod on

Ran: zedqa_mods_run.ps1 with summercar_mods.txt and summercar_manifest.txt (the prelude and zedqa_summercar.lua), once, at 4K fullscreen (UI scale 1.75x), ZeD last in the mod list, the real-mouse helper beside it (stopped afterwards). The mod came from SteamCMD's download folder, copied into Zomboid/mods for the run and removed after; the runner restored the ZeD-QA save and its mods.txt lists only ZeD_UI. The Deck-size and ZeD-first runs of batch_summercar.ps1 were not run (one run per script). Report: ZeDUI/qa/regression/2026-11-12_2128_mods_fullscreen4k.md (prelude pass, summercar WARN: 155 s). Pictures: Zomboid/Screenshots/b12_round2_20261112/p6 (zqa_sc_B..N, 9 files).

What it showed:
- "Inspect engine components" works from the engine row's menu and from the footer verb (F and G PASS); ZeD's menu cells: `DBG: ISVehicleMechanics.cheat=true | Remove engine at lift | Inspect engine components`; no Take engine parts or Repair engine.
- Positions and sizes at 4K, default layout (World window x=1929, y=0, 1617 x 735): the engine components window opens at x=1419, y=10, 500 x 631, anchored. It is top-aligned with the World window (10 px lower than its top edge) with a 10 px gap, but on the LEFT of the World window, not the right: 1419 + 500 = 1919, then 10 px, then 1929. The right side has no room at the default layout (the World window ends at 3546; the screen is 3840; 500 + 10 does not fit), so it takes the left side and sits over the Character window's inventory strip (picture p6/zqa_sc_F_menu.png). When the World window is dragged left to x=1111 it opens on the right at x=2738, y=10 (gap 10 after 1111 + 1617 = 2728) (step L, PASS). With a second car: x=1419, y=10 (World window at 2643, 903 wide), one window only (I, PASS).
- It closes with the tab: the hood shut closes it, rolling the World window closes it and unrolling brings it back, closing the World window closes it and reopening on the Vehicle tab brings it back (H, J, K PASS), and a fold's close comes back with the tab (D PASS).
- The mod's sentence on a shut hood: "The hood must be open to inspect engine components." (H PASS).

### List A (real mod bugs), Part 6
- None sure. A deviation from the expected "sits to the right": at the default 4K layout it opens on the left of the World window, over the Character window's inventory strip, because the right side is too narrow (picture above). That may be as designed ("beside, or 420 wide at x 10 over the inventory side" is the script's own line); the director should look.

### List B (test trouble), Part 6
- `ZEDQA sc ERR step 'B wait inspected' timed out` and the lines that follow from it: `ZEDQA sc B opened: no engine window` (62987 ms after the inspection), `ZEDQA sc ERR B: the World window not moved (1929)`, `ZEDQA sc ERR C: still open 5 s later` (no window to stay), `ZEDQA sc ERR D: the pointer on the engine window holds the tab`, `ZEDQA sc ERR E: Loot and back: still shut (the player's close lasts)`. The auto-open on inspecting the car never happened in this run, so B, C, D (hold) and E (Loot and back) read as failed; F onward opened it through the menu and passed. Unclear whether the auto-open is a real gap or the inspection step did not run; the "the reported bug" step C needs an open window to judge, so it was not judged.
- Not run: step M (the wheels: `M outside wheel:` printed no result) and O (`skipped: no pad (the sim proves the hand-back)`).

## Part 7. Lua Console 93 Professional Edition (CHECK_luaconsole93.md)

Setup: built and staged with build_luaconsole93.py --stage (it rewrote three tracked files in products/LuaConsole93 to a fresh build, Molecules.lua, Scale.lua and Tokens.lua; I put those three back to their committed bytes, so the repo is untouched, but the staged mod in Zomboid/mods/LuaConsole93 is the fresh build). The sheet's LC93-QA save copy was not used: the director's rule is the ZeD-QA save only, so the three passes ran through zedqa_mods_run.ps1, which writes the ZeD-QA save's mod list for the run and puts the save back afterwards (its mods.txt reads only ZeD_UI now). For the alone pass the dev-only ZeDQAShim (a copy of the QA bridge, no ZeD-GUI) stood in the list so the bridge could run; the main menu's list (default.txt) was LuaConsole93 and ZeDQAShim for that pass, ZeD_UI and LuaConsole93 in each order for Run 2, and was put back after (reads ZeD_UI as before; its backup file removed). The staged mod was left in place, as the sheet says. The console was opened through the game's own console flag (not the console key) and lines went through the console's Run (the call the box's Enter makes); no keys were typed. Pictures: Zomboid/Screenshots/b12_round2_20261112/p7 (run1, run2a, run2b, with each run's console.txt). Reports: ZeDUI/qa/regression/2026-11-12_2151_mods_fullscreen4k.md (alone), _2153_ (order A: ZeD first), _2156_ (order B), and _2139_ (a first alone attempt that never loaded: default.txt lacked the bridge shim, run stopped by its own 5-minute timeout, nothing ran; the game process I started was stopped by its PID). A very first alone run (_2136_) ran with ZeD_UI still in the main menu's list, so its console.txt held ZeD lines; it is not the alone pass and I discarded its result.

### Run 1: alone on the plain game (4K, -debug -nosteam)
- Window opens in -debug: PASS. Title "Lua Console 93", on the Log page; the game's own console did not show.
- The log: PASS. `print("hello")` and `print(LC93 ~= nil, ZeD == nil)` gave a "ran" row and the output `true true` (as the sheet expects: LC93 is there, ZeD is not).
- Error row: FAIL against the sheet (see List A): the error run three times gave four rows (count 3 / 6 / 3 / 3), not one row with x3. The stack opens in place (PASS).
- Export: PASS. File LuaConsole93_<date>_<time>.log, first line `Lua Console 93 | 2026-11-12_215242 | 65 of 65 | errors 4`, last line says the user name is taken out ("Your user name is taken out of this report. ..."), and no line in it names a Users folder.
- Scratchpad: PASS for what it can run: a two-line snippet ran and printed rows `a` and `b` (from Console), and Save snippet wrote LuaConsole93_snippets.txt. Not checked: right-click rename, the swap back with one line.
- Suggestions: not checked. Calling the console's complete with "getPl" returned nothing; the script cannot type into the box, so this needs a hand check (typing getPl and seeing getPlayer in the pull-down).
- Commands and Help pages: both open and draw (pictures p7/run1/zqa_lc_x_4k_commands.png and _help.png): the commands list with the debug-menu way for each ("Debug menu > Cheats"), the Help page's folds (What runs where, Keys, Controller, Files). Not checked: picking /godmode opens the Cheats window; the four fold headers' open and shut.
- Nothing refers to ZeD-GUI: PASS. console.txt of the alone run: no `[ZeD]` line and no ZeD-GUI line from the console or the mod; the only ZeD-named things are the dev shim's own `[ZeD.QA] bridge armed` lines (the test's bridge, not the product) and "loading ZeDQAShim". No `[Lua Console 93]` failure line.
- console.txt: no error from a LuaConsole93 file except the deliberate ones I ran (the three `local t = nil; print(t.x)` runs, which the game logs as Lua errors by design). Beyond them the usual game noise (font page textures, sanitizing container names) as in every run.
- Print rows: FAIL against the sheet's spirit (see List A): every print shows as two rows ("hello" appears twice; the scratchpad's `a` and `b` each twice, once from Console and once from Game).
- Not run: step 12's Deck-size look (1280x800), step 13 (controller), step 14 (hand-back switch file), step 14a (Russian and Polish), the controller wheel, the 4K look at borders and dragging by eye beyond the pictures.

### Run 2: both installed, each load order
- Order A (ZeD_UI, then LuaConsole93): ZeD-GUI's console opens (title "Lua console"), never Lua Console 93's; LC93 is nil, ZeD is there (`globals: LC93=false ZeD=true`; the line `print(LC93 ~= nil, ZeD == nil)` I ran gave `false false`, which is the sheet's `LC93 == nil, ZeD ~= nil` = true true read the other way round). Export file: ZeD_console_<date>_<time>.log with first line `ZeD-GUI Lua console | ...`. console.txt holds `[Lua Console 93] ZeD-GUI is on: its console is used` exactly twice (the main menu's load and the save's load) and no other `[Lua Console 93]` line. PASS.
- Order B (LuaConsole93, then ZeD_UI): the same answers, the same line twice. PASS.
- Not checked in Run 2: the controller's Back wheel (no pad on the path); the scratchpad's snippets file (ZeD-GUI's own; not run).
- The two-rows error issue below shows in ZeD-GUI's console too (four rows for the same error).

### Run 3: the release check list
- `build_luaconsole93.py --check`: FAIL. products/LuaConsole93 differs from a fresh build in 3 files: Molecules.lua, Scale.lua and Tokens.lua (under 42/media/lua/client/LuaConsole93/). A rebuild after the last console-related change in ZeD-GUI (punch list 178's row sizes) is needed before the upload. List A.
- luaconsole93_sim: 272 checks, 0 failed. kahlua_guard on products/LuaConsole93: RESULT: PASS. The five console sims of ZeD-GUI: 0 failed (inside Part 1's 124 clean sims).
- mod.info: name Lua Console 93 Professional Edition, id LuaConsole93, modversion 1.0.0, versionMin 42.17.0, url empty, poster.png and icon.png and LICENSE.txt beside it, no require= line. PASS.
- The pictures: preview.png, poster.png and icon.png are byte-identical to ZeDUI/art/lua_console_93/'s. PASS.
- "beta" anywhere a player reads: mod.info and README.txt hold no "beta"; workshop_description.bbcode was not at products/LuaConsole93/workshop/ (not found), the pictures not read by eye. Not checked.
- "Runs 1 and 2 passed on 42.22": they ran on 42.22.2, with the two failures below.
- The Workshop item and the upload folder: the director's step; not checked.

### List A (real mod bugs), Part 7
1. products/LuaConsole93 is behind a fresh build by three files (`build_luaconsole93.py --check`: "differs from a fresh build in 3 files": Molecules.lua, Scale.lua, Tokens.lua). Rebuild and commit before the release.
2. One error run three times is four rows, not one with x3, in Lua Console 93 and in ZeD-GUI's console (two rows there). Lines (alone pass): `ZEDQA lc errrow n=3 box=3 f11=nil mod=#game msg=------------------------------------------------------------- stack=1`, `ZEDQA lc errrow n=6 box=6 f11=nil mod=Lua Console 93 Professional Edition msg=dumping Lua stack trace stack=9`, `ZEDQA lc errrow n=3 box=3 f11=2 mod=Lua Console 93 Professional Edition msg=attempted index: x of non-table: null stack=64`, `ZEDQA lc errrow n=3 box=3 f11=nil mod=Lua Console 93 Professional Edition msg=zombie.ui.UIDebugConsole.ProcessCommand(UIDebugConsole.java:391) stack=47`. Picture: p7/run1/zqa_lc_x_4k_error_stack.png. The game's own box lines (the separator, "dumping Lua stack trace", the Java exception) each become a row with a count, and the Lua error from the F11 list is a fourth; they are not merged.
3. A print shows as two rows (the director's `print("a","b")` check, here on `print("hello")` and the scratchpad's prints): `ZEDQA lc row print | hello   (x2)`, `ZEDQA lc scratch print row: a mod=#console` with `ZEDQA lc scratch print row: a mod=#game`. Picture: p7/run1/zqa_lc_x_4k_prints.png (each line twice). The same doubling shows in ZeD-GUI's console in Part 4.
Caveat for 2 and 3: both came through the console's Run route (the same ProcessCommand the box's Enter uses), not typed keys. If a typed line gives one row, the route is the difference; the director's own check by hand settles it.

### List B (test trouble), Part 7
- The first two alone attempts (above): setup, not the mod.
- Suggestions read nil: the script cannot type; needs a hand look.

### End of the check
default.txt put back from its backup and the backup deleted; no LuaConsole93_off.txt existed; the LuaConsole93_* export, snippet and history files this check made in Zomboid/Lua were removed; the staged mod stays, as the sheet says.

## End state confirmation
- options.ini restored whole from my backup: fullScreen=true, 3840x2160, fontSize=2, language=EN. ModOptions.ini matches its backup. zedqa.autoload reads 0. zedqa.lock reads free. The game is closed. Game speed 1 (every script set it; the game is shut). The ZeD-QA save's mods.txt lists only ZeD_UI. Summer Car's copy removed from Zomboid/mods; LuaConsole93 stays staged on purpose. No background tasks left (the mouse helper was stopped with its stop file; no loops).
- Committed: the runners' reports (ZeDUI/qa/regression/) and this file; no pictures. My scratch scripts and manifests (_b12r2_*) are not committed and were deleted from the checkout.
