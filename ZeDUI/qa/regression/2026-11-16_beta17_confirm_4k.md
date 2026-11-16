# ZeD-UI regression - 2026-11-16 12:01 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-16 12:01:45 |
| Finished | 2026-11-16 12:06:07 (4 min 22 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta17 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b17_confirm.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 27795 to 27800 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 27799, 27800)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_b17_scroll.lua | b17s | PASS | 56 | zqa_b17s_tv_top.png, zqa_b17s_radio_top.png, zqa_b17s_twoway_ham_top.png, zqa_b17s_cd_player_top.png, zqa_b17s_oven_top.png, zqa_b17s_microwave_top.png, zqa_b17s_generator_top.png, zqa_b17s_propane_grill_top.png, zqa_b17s_laundry_top.png, zqa_b17s_item_card_foot.png, zqa_b17s_mechanics_foot.png, zqa_b17s_furniture_foot.png, zqa_b17s_journal_ask.png, zqa_b17s_journal_after_delete.png, zqa_b17s_equip_card_unequip.png, zqa_b17s_equip_after_unequip.png, zqa_b17s_equip_card_drop.png, zqa_b17s_equip_after_drop.png |  |
| 3 | zedqa_plates_336.lua | p336 | PASS | 82 | zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png |  |
| 4 | zedqa_cov_objcards.lua | cov_objcards | WARN | 26 | zqa_ocv_track.png, zqa_ocv_placement.png, zqa_ocv_fluid.png, zqa_ocv_fire.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 27795 at 12:02:47

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

### 2. zedqa_b17_scroll.lua (`ZEDQA b17s`) - PASS, 56 s

- go 27796 at 12:02:53
- screenshots: zqa_b17s_tv_top.png, zqa_b17s_radio_top.png, zqa_b17s_twoway_ham_top.png, zqa_b17s_cd_player_top.png, zqa_b17s_oven_top.png, zqa_b17s_microwave_top.png, zqa_b17s_generator_top.png, zqa_b17s_propane_grill_top.png, zqa_b17s_laundry_top.png, zqa_b17s_item_card_foot.png, zqa_b17s_mechanics_foot.png, zqa_b17s_furniture_foot.png, zqa_b17s_journal_ask.png, zqa_b17s_journal_after_delete.png, zqa_b17s_equip_card_unequip.png, zqa_b17s_equip_after_unequip.png, zqa_b17s_equip_card_drop.png, zqa_b17s_equip_after_drop.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b17s start
[ZeD.QA] run #2 ok=true
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
ZEDQA b17s radio: lowest control radio:tw:battery after 4 Downs, scroll 0.209
ZEDQA b17s PASS radio: Up from the lowest control scrolls the face to the very top (0.209 -> 0.000, on radio:full after 7 Ups)
ZEDQA b17s twoway_ham: face 358 px top stop to lowest control; window 972 px
ZEDQA b17s twoway_ham: window 455 px, face view 283 px for a 358 px face (11 steps)
ZEDQA b17s PASS twoway_ham: the face's controls are pad stops (radio:tab:1)
ZEDQA b17s twoway_ham: lowest control radio:tw:mic after 3 Downs, scroll 0.018
ZEDQA b17s PASS twoway_ham: Up from the lowest control scrolls the face to the very top (0.018 -> 0.000, on radio:full after 3 Ups)
ZEDQA b17s cd_player: face 416 px top stop to lowest control; window 972 px
ZEDQA b17s cd_player: window 455 px, face view 283 px for a 416 px face (11 steps)
ZEDQA b17s PASS cd_player: the face's controls are pad stops (radio:tw:power)
ZEDQA b17s cd_player: lowest control radio:tw:battery after 1 Downs, scroll 0.096
ZEDQA b17s PASS cd_player: Up from the lowest control scrolls the face to the very top (0.096 -> 0.000, on radio:full after 5 Ups)
ZEDQA b17s oven: face 189 px top stop to lowest control; window 972 px
ZEDQA b17s oven: window 455 px, face view 152 px for a 189 px face (11 steps)
ZEDQA b17s PASS oven: the face's controls are pad stops (craft:stDrop)
ZEDQA b17s oven: lowest control craft:a:popout after 1 Downs, scroll 0.000
ZEDQA b17s oven: NOTE the walk down never scrolled the face (scroll now 0.000)
ZEDQA b17s microwave: face 779 px top stop to lowest control; window 972 px
ZEDQA b17s microwave: window 760 px, face view 457 px for a 779 px face (4 steps)
ZEDQA b17s PASS microwave: the face's controls are pad stops (craft:stDrop)
ZEDQA b17s microwave: lowest control craft:a:popout after 1 Downs, scroll 0.000
ZEDQA b17s microwave: NOTE the walk down never scrolled the face (scroll now 0.000)
ZEDQA b17s generator: face 383 px top stop to lowest control; window 972 px
ZEDQA b17s generator: window 495 px, face view 186 px for a 383 px face (9 steps)
ZEDQA b17s PASS generator: the face's controls are pad stops (oc:back)
ZEDQA b17s generator: lowest control gen:outlet after 3 Downs, scroll 0.025
ZEDQA b17s PASS generator: Up from the lowest control scrolls the face to the very top (0.025 -> 0.000, on oc:back after 3 Ups)
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

### 3. zedqa_plates_336.lua (`ZEDQA p336`) - PASS, 82 s

- go 27797 at 12:03:52
- screenshots: zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA p336 start
[ZeD.QA] run #3 ok=true
ZEDQA p336 indoors at 891,13006
ZEDQA p336 placed: oven true, microwave true, chrome true, generator true, grill true
ZEDQA p336 phase A: root 1.75 (the run's own scale)
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale175, root 1.75, zoom 2]: plate oven_modern, drawn oven_modern@392, tab 840 px (half 385, full 840); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the face that fills the card is drawn (want oven_modern@392, drawn oven_modern@392)
ZEDQA p336 PASS oven: it sits inside the card at the whole zoom (784 of 815 px)
ZEDQA p336 PASS oven: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale175, root 1.75, zoom 2]: plate mw_white, drawn mw_white@392, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the face that fills the card is drawn (want mw_white@392, drawn mw_white@392)
ZEDQA p336 PASS microwave: it sits inside the card at the whole zoom (784 of 815 px)
ZEDQA p336 PASS microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale175, root 1.75, zoom 2]: plate mw_chrome, drawn mw_chrome@392, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the face that fills the card is drawn (want mw_chrome@392, drawn mw_chrome@392)
ZEDQA p336 PASS chrome microwave: it sits inside the card at the whole zoom (784 of 815 px)
ZEDQA p336 PASS chrome microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale175, root 1.75]: card 840 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 generator: plate room 804 px, the face for it gen_red@392
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale175, root 1.75]: card 840 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 grill: plate room 804 px, the face for it grill_propane@392
ZEDQA p336 PASS grill: the face has its controls
ERROR: General f:4376 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13007.5 (grill 893,13008)
ZEDQA p336 grill: the card before the burner: up true, visible true, entry true, hasFuel read true, refreshed at 8.339999999999991
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ERROR: General f:5106 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 PASS grill: walking 8 tiles away with nothing queued closes the card
ZEDQA p336 phase B: forced root 0.50
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale050, root 0.50, zoom 1]: plate oven_modern, drawn oven_modern_n, tab 240 px (half 110, full 240); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the face that fills the card is drawn (want oven_modern_n, drawn oven_modern_n)
ZEDQA p336 PASS oven: it sits inside the card at the whole zoom (200 of 233 px)
ZEDQA p336 PASS oven: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale050, root 0.50, zoom 1]: plate mw_white, drawn mw_white_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the face that fills the card is drawn (want mw_white_n, drawn mw_white_n)
ZEDQA p336 PASS microwave: it sits inside the card at the whole zoom (200 of 233 px)
ZEDQA p336 PASS microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale050, root 0.50, zoom 1]: plate mw_chrome, drawn mw_chrome_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the face that fills the card is drawn (want mw_chrome_n, drawn mw_chrome_n)
ZEDQA p336 PASS chrome microwave: it sits inside the card at the whole zoom (200 of 233 px)
ZEDQA p336 PASS chrome microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale050, root 0.50]: card 240 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 generator: plate room 230 px, the face for it gen_red_n
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale050, root 0.50]: card 240 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 grill: plate room 230 px, the face for it grill_propane_n
ZEDQA p336 PASS grill: the face has its controls
ERROR: General f:7192 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13007.5 (grill 893,13008)
ZEDQA p336 grill: the card before the burner: up true, visible true, entry true, hasFuel read true, refreshed at 2.5799999999999956
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ERROR: General f:7955 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA p336 PASS grill: walking 8 tiles away with nothing queued closes the card
ZEDQA p336 cleanup done: 5 things removed
ZEDQA p336 all checks passed
ZEDQA p336 DONE
ERROR: General f:8094 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 4. zedqa_cov_objcards.lua (`ZEDQA cov_objcards`) - WARN, 26 s

- go 27798 at 12:05:18
- 1 ERR line(s)
- screenshots: zqa_ocv_track.png, zqa_ocv_placement.png, zqa_ocv_fluid.png, zqa_ocv_fire.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cov_objcards start
[ZeD.QA] run #4 ok=true
ZEDQA cov_objcards set aside 8 of the character's own things
ZEDQA cov_objcards home 925,13040; spots: place 925,13039, fire 923,13038
ZEDQA cov_objcards PASS the World window is open and down
ZEDQA cov_objcards World window on the tab loot, pinned true
ZEDQA cov_objcards PASS track: ZeD's hook on Inspect Track (ISInspectAnimalTrackAction) is in place
ZEDQA cov_objcards waited for the track card
ZEDQA cov_objcards PASS track: Inspect Track (the game's action) opens the track card
ZEDQA cov_objcards PASS track: the card has its data (its refresh ran)
ZEDQA cov_objcards PASS track: the title is the track's type
ZEDQA cov_objcards PASS track: the way it went is the track's direction
ZEDQA cov_objcards PASS track: reads the character's Tracking level
ZEDQA cov_objcards PASS track: the species shows from Tracking 5, the track size below (level 10)
ZEDQA cov_objcards PASS track: the tag is the freshness
ZEDQA cov_objcards PASS track: no verbs drawn
ZEDQA cov_objcards SHOT zqa_ocv_track.png
ZEDQA cov_objcards PASS track: an animal the game does not know reads ???
ZEDQA cov_objcards PASS track: a carried track's card has no leash (open and drawing 9 squares off)
ZEDQA cov_objcards PASS track: the close key closes the card
ZEDQA cov_objcards PASS placement: ZeD's hook on Extended placement (ISExtendedPlacementAction) is in place
ZEDQA cov_objcards waited for the placement card
ZEDQA cov_objcards PASS placement: Extended placement (the game's action) opens the placement card
ZEDQA cov_objcards PASS placement: the card has its start and its data
ZEDQA cov_objcards PASS placement: the card starts from the item's place and turn
ZEDQA cov_objcards PASS placement: Done is the main verb, Revert beside it
ZEDQA cov_objcards PASS placement: the controller lands on Movement X
ZEDQA cov_objcards PASS placement: +0.01 moves the item along X
ZEDQA cov_objcards PASS placement: the card is still open
ZEDQA cov_objcards PASS placement: +15 turns the item about Z and the gizmo turns to rotating
ZEDQA cov_objcards PASS placement: the D-pad's right on the Y slider moves 0.05 and the gizmo turns to moving
ZEDQA cov_objcards PASS placement: -0.01 at the floor keeps Z at 0
ZEDQA cov_objcards SHOT zqa_ocv_placement.png
ZEDQA cov_objcards PASS placement: -15 from 5 degrees wraps to 350
ZEDQA cov_objcards PASS placement: Revert puts the item back where it was
ZEDQA cov_objcards PASS placement: Done closes the card
ZEDQA cov_objcards PASS placement: Done keeps the new place
ZEDQA cov_objcards PASS placement: the card opens again on the hammer and draws (for the leash)
ZEDQA cov_objcards PASS placement: the card closes past the game's 3 squares
ZEDQA cov_objcards PASS fluid: ZeD's hook on an item's Pour (ISFluidContainerMenu.showUI) is in place
ZEDQA cov_objcards waited for the fluid card
ZEDQA cov_objcards PASS fluid: a bottle's Pour (the game's menu) opens the fluid card
ZEDQA cov_objcards PASS fluid: the card has its data (its refresh ran)
ZEDQA cov_objcards PASS fluid: the bottle goes on the left, the right is empty
ZEDQA cov_objcards PASS fluid: the bottle poured from is its row's From
ZEDQA cov_objcards PASS fluid: an empty bottle is tagged Empty and takes the pour
ZEDQA cov_objcards PASS fluid: a full bottle is tagged Full and refuses (the engine's reason)
ZEDQA cov_objcards PASS fluid: the tag names the liquid
ZEDQA cov_objcards PASS fluid: with the right empty the controller lands on an Into button
ZEDQA cov_objcards PASS fluid: no Pour until the right side is set
ZEDQA cov_objcards PASS fluid: Into on the empty bottle puts it on the right
ZEDQA cov_objcards PASS fluid: the card is still open
ZEDQA cov_objcards PASS fluid: Max pour is the smaller of what is in and the room
ZEDQA cov_objcards PASS fluid: Pour shows once both sides are set
ZEDQA cov_objcards PASS fluid: 1/2 sets half the max
ZEDQA cov_objcards PASS fluid: the D-pad's left on the slider takes a twentieth off
ZEDQA cov_objcards PASS fluid: Pour queues the game's pour (ISFluidTransferAction)
ZEDQA cov_objcards waited for the pour
ZEDQA cov_objcards PASS fluid: the pour moved half the max
ZEDQA cov_objcards SHOT zqa_ocv_fluid.png
ZEDQA cov_objcards PASS fluid: Switch swaps the two sides
ZEDQA cov_objcards PASS fluid: Empty asks first in the band, with the litres
ZEDQA cov_objcards PASS fluid: the question's Cancel empties nothing
ZEDQA cov_objcards PASS fluid: the question's Empty shuts the question and queues the game's empty (ISFluidEmptyAction)
ZEDQA cov_objcards waited for the bottle emptied
ZEDQA cov_objcards PASS fluid: Empty (the game's action) emptied the bottle
ZEDQA cov_objcards PASS fire: ZeD's hook on the campfire's Info (ISCampingMenu.onDisplayInfo) is in place
ZEDQA cov_objcards PASS fire: a campfire staged
ZEDQA cov_objcards waited for the fire card
ZEDQA cov_objcards PASS fire: the campfire's Info (the game's menu) opens the fire card
ZEDQA cov_objcards PASS fire: the card has its data (its refresh ran)
ZEDQA cov_objcards PASS fire: a new campfire reads no fuel and not lit
ZEDQA cov_objcards PASS fire: the tag says Out
ZEDQA cov_objcards PASS fire: no Put out on a dead fire
ZEDQA cov_objcards PASS fire: Light waits with nothing to light with, and says what it needs
ZEDQA cov_objcards PASS fire: Take apart shows and asks first
ZEDQA cov_objcards PASS fire: the card is still open
ZEDQA cov_objcards PASS fire: the two planks carried are an Add fuel row
ZEDQA cov_objcards PASS fire: paper with a lighter is a Light with row
ZEDQA cov_objcards PASS fire: with a lighter, Light is live and the main verb
ZEDQA cov_objcards PASS fire: Add fuel is live, not the main verb while it can be lit
ZEDQA cov_objcards PASS fire: Add fuel jumps to the fuel list
ZEDQA cov_objcards PASS fire: the plank row's Add runs (its row's own code)
ZEDQA cov_objcards waited for the fuel
ZEDQA cov_objcards PASS fire: the plank added its burn time
ZEDQA cov_objcards PASS fire: one plank fewer on the list
ZEDQA cov_objcards PASS fire: the paper row's Light runs (its row's own code)
ZEDQA cov_objcards waited for the fire to light
ZEDQA cov_objcards PASS fire: lit with the paper (the game's action): the tag says Burning
ZEDQA cov_objcards PASS fire: lit: Put out shows, Light is gone
ZEDQA cov_objcards SHOT zqa_ocv_fire.png
ZEDQA cov_objcards PASS fire: Put out queues the game's action (ISPutOutCampfireAction)
ZEDQA cov_objcards waited for the fire to go out
ZEDQA cov_objcards PASS fire: Put out (the game's action) puts it out: the tag says Out
ZEDQA cov_objcards PASS fire: Take apart asks first, a red question
ZEDQA cov_objcards PASS fire: the question's Cancel keeps the campfire
ZEDQA cov_objcards PASS fire: the question's Take apart shuts the question and queues the game's action (ISRemoveCampfireAction)
ZEDQA cov_objcards waited for the campfire taken apart
ZEDQA cov_objcards PASS fire: Take apart (the game's action) removes the campfire
ZEDQA cov_objcards PASS fire: the card closes with its campfire
ZEDQA cov_objcards restored (the end): given taken back 2, new things swept 3, set aside and given back 8 of 8; hammer 1, campfire 0, trough 0, hens 0 (+0 out in the world), hen house 0, plots 0, zones 0, things lying on the staged squares 2
ZEDQA cov_objcards PASS cleanup: everything staged is gone
ZEDQA cov_objcards RESULT 82 pass, 0 fail, 0 step errors
ZEDQA cov_objcards fails 0
ZEDQA cov_objcards DONE
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
