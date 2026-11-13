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
