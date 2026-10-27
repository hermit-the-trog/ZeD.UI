# ZeD-UI regression - 2026-10-25 20:13 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-25 20:13:26 |
| Finished | 2026-10-25 20:19:44 (6 min 18 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/AppData/Local/Temp/claude/C--Users-danie-Zomboid/989d1212-0f15-49ba-a371-9ee134c38e7f/scratchpad/compat_v_manifest.txt (9 scripts) |
| Result | **8/9 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 13229 to 13239 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13238, 13239)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_loot_tabs.lua | lt | PASS | 1 |  |  |
| 3 | zedqa_compat_vehicles.lua | cv | PASS | 1 |  |  |
| 4 | zedqa_dash19.lua | dash | PASS | 92 | zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png |  |
| 5 | zedqa_car_radio_build.lua | rb | PASS | 33 | zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png |  |
| 6 | zedqa_world_pad_take.lua | wpt | WARN | 66 |  | 27 ERR line(s) |
| 7 | zedqa_messages.lua | msg | PASS | 10 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |
| 8 | zedqa_moodles.lua | mood | PASS | 16 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png |  |
| 9 | zedqa_belt_hands.lua | bh | PASS | 4 | zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13229 at 20:15:05

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_loot_tabs.lua (`ZEDQA lt`) - PASS, 1 s

- go 13230 at 20:15:09

```text
[ZeD.QA] windows reset (R)
ZEDQA lt start
[ZeD.QA] run #2 ok=true
ZEDQA lt Character loot drawer false | World loot drawer false
ZEDQA lt DONE
```

### 3. zedqa_compat_vehicles.lua (`ZEDQA cv`) - PASS, 1 s

- go 13231 at 20:15:14

```text
[ZeD.QA] windows reset (R)
ZEDQA cv modded vehicle scripts: 0 to try, from 0 Workshop items
ZEDQA cv start
[ZeD.QA] run #3 ok=true
ZEDQA cv 0 checks, 0 failed
ZEDQA cv all checks passed
ZEDQA cv DONE
```

### 4. zedqa_dash19.lua (`ZEDQA dash`) - PASS, 92 s

- go 13232 at 20:15:18
- screenshots: zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #4 ok=true
ZEDQA dash 01_luxury design=luxury rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 02_nyala design=nyala rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 03_cossette design=cossette rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 04_police design=police rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 05_d6 design=d6 rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 06_dashelite design=dashelite rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 07_primani design=primani rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 08_dart design=dart rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 09_horizon design=horizon rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 10_wagon design=wagon rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 11_suv design=suv rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 12_van design=van rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 13_bulldriver design=bulldriver rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 14_rancher design=rancher rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 15_taxi design=taxi rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 16_ambulance design=ambulance rect=1120,1804,1600,344 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 17_fire design=fire rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 18_ranger design=ranger rect=1120,1804,1600,344 running=true radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ERROR: General f:7396 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"   (x2)
ZEDQA dash 19_race design=race rect=1120,1804,1600,344 running=true radio=false heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash DONE
```

### 5. zedqa_car_radio_build.lua (`ZEDQA rb`) - PASS, 33 s

- go 13233 at 20:16:53
- screenshots: zqa_rb_d01_pickup_dash.png, zqa_rb_r01_premium_off.png, zqa_rb_r02_premium_on.png, zqa_rb_r03_premium_store.png, zqa_rb_r04_premium_hover_tune.png, zqa_rb_r05_premium_cd.png, zqa_rb_r06_premium_controller.png, zqa_rb_r07_premium_cdlist.png, zqa_rb_r08_valutech.png, zqa_rb_r09_makeshift.png, zqa_rb_r10_ham.png, zqa_rb_r11_ham_mic_off.png, zqa_rb_r12_ham_mem.png, zqa_rb_r13_army.png, zqa_rb_r14_hammake.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rb start
[ZeD.QA] run #5 ok=true
ZEDQA rb spawned Base.PickUpTruck beside the character
ZEDQA rb spawned Base.CarLightsPolice beside the character
ZEDQA rb Base.PickUpTruck radio=Base.RadioBlack
ZEDQA rb Base.ModernCarLightsMeadeSheriff radio=Base.HamRadio1
ZEDQA rb dash only kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=98000 vol=1 preset=2 name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=nil at nil,nil nilxnil vanilla window=false
ZEDQA rb premium off kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=98000 vol=1 preset=2 name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb premium power via vanilla's action ok=true canBePoweredHere=true battery=1
ZEDQA rb premium on kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=true media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=89.4 Hitz FM; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb store 4 -> 4
ZEDQA rb premium stored kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=true media=false playing=false title=nil flash=STORE 4 mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb cds carried: 0
ZEDQA rb insert ok=true
ZEDQA rb cd in kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=true media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb play ok=false
ZEDQA rb cd playing kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=true media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb eject ok=false
ZEDQA rb ejected kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=true media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb fit Base.RadioBlack ok=true nil
ZEDQA rb valutech kind=valutech item=Base.RadioBlack on=true switch=true powered=true ch=98000 vol=0.6000000238418579 preset=2 name=NNR Radio signal=true media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1548 880x244 vanilla window=false
ZEDQA rb fit Base.RadioMakeShift ok=true nil
ZEDQA rb makeshift kind=makeshift item=Base.RadioMakeShift on=true switch=true powered=true ch=89400 vol=0.6000000238418579 preset=nil name=Hitz FM signal=true media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=true at 1828,1536 880x256 vanilla window=false
ZEDQA rb fit Base.RadioBlack ok=true nil
ZEDQA rb pickup restored kind=valutech item=Base.RadioBlack on=false switch=false powered=true ch=101200 vol=0.6000000238418579 preset=3 name=KnoxTalk Radio signal=true media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=93.2 LBMW - Kentucky Radio; 2=98.0 NNR Radio; 3=101.2 KnoxTalk Radio; 4=101.2 KnoxTalk Radio; 5=94.2 USR]
ZEDQA rb prop visible=false at 1828,1536 880x256 vanilla window=false
ZEDQA rb ham power via vanilla's action ok=true canBePoweredHere=true battery=0.9990899562835693
ZEDQA rb ham kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=3 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=89.4 Hitz FM; 2=91.2 Civilian Radio; 3=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb ham mic off kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=98400 vol=1 preset=3 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=true
ZEDQA rb presets [1=89.4 Hitz FM; 2=91.2 Civilian Radio; 3=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=true at 1708,1480 1000x312 vanilla window=false
ZEDQA rb mem -> 4
ZEDQA rb ham mem kind=ham item=Base.HamRadio1 on=true switch=true powered=true ch=146600 vol=1 preset=4 name=nil signal=false media=false playing=false title=nil flash=CH 04 STORED mic=false
ZEDQA rb presets [1=89.4 Hitz FM; 2=91.2 Civilian Radio; 3=98.4 Automated Emergency Broadcast System; 4=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1512 1000x280 vanilla window=false
ZEDQA rb siren opened; radio still up = false
ZEDQA rb fit Base.HamRadio2 ok=true nil
ZEDQA rb army kind=army item=Base.HamRadio2 on=true switch=true powered=true ch=98400 vol=1 preset=3 name=Automated Emergency Broadcast System signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=89.4 Hitz FM; 2=91.2 Civilian Radio; 3=98.4 Automated Emergency Broadcast System; 4=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1492 1000x300 vanilla window=false
ZEDQA rb fit Base.HamRadioMakeShift ok=true nil
ZEDQA rb hammake kind=hammake item=Base.HamRadioMakeShift on=true switch=true powered=true ch=98000 vol=1 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=89.4 Hitz FM; 2=91.2 Civilian Radio; 3=98.4 Automated Emergency Broadcast System; 4=146.6 146.600 MHz]
ZEDQA rb prop visible=true at 1708,1516 1000x276 vanilla window=false
ZEDQA rb fit Base.HamRadio1 ok=true nil
ZEDQA rb police restored kind=ham item=Base.HamRadio1 on=false switch=false powered=true ch=98000 vol=1 preset=nil name=NNR Radio signal=false media=false playing=false title=nil flash=nil mic=false
ZEDQA rb presets [1=89.4 Hitz FM; 2=91.2 Civilian Radio; 3=98.4 Automated Emergency Broadcast System]
ZEDQA rb prop visible=false at 1708,1516 1000x276 vanilla window=false
ZEDQA rb DONE
```

### 6. zedqa_world_pad_take.lua (`ZEDQA wpt`) - WARN, 66 s

- go 13234 at 20:17:28
- 27 ERR line(s)

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #6 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt FAIL a crate was built beside the character
ZEDQA wpt containers 1:Ground | stops container:1@0
ZEDQA wpt FAIL the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldContainerStrip:container:1
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldContainerStrip:container:1
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:1
ZEDQA wpt PASS on the strip, focus is on the container on show (the ground)
ZEDQA wpt 2 Down x10: World worldCtl:worldCtl:take
ZEDQA wpt FAIL Down from the ground reaches the crate (10 presses)
ZEDQA wpt 2 after A on the crate: World worldCtl:worldCtl:take
ZEDQA wpt FAIL A on the crate puts focus on its first item, lit
ZEDQA wpt 2 Left: World worldContainerStrip:container:1
ZEDQA wpt FAIL Left from the list lands on the crate (the container on show)
ZEDQA wpt 2 Right: World worldCtl:worldCtl:take
ZEDQA wpt FAIL Right goes back to the same row
ZEDQA wpt 2 Left from a lower row: World worldContainerStrip:container:1
ZEDQA wpt FAIL Left from a lower row lands on the crate too
ZEDQA wpt FAIL and Right goes back to that row
ZEDQA wpt 3 A on the bandage: World worldCtl:worldCtl:take
ZEDQA wpt FAIL 3 A on the bandage: focus is on the card's primary action (nil)
ZEDQA wpt 3 Down in the card: World worldCtl:worldCtl:take
ZEDQA wpt FAIL Down moves to the card's next control
ZEDQA wpt 3 Up: World worldContainerStrip:container:1
ZEDQA wpt FAIL Up from inside the card is back on the primary action in one press
ZEDQA wpt 3 after B: World worldContainerStrip:container:1
ZEDQA wpt FAIL B closes the card and focus is back on the bandage row, lit
ZEDQA wpt 4 A on the nails: World worldContainerStrip:container:1
ZEDQA wpt FAIL 4 A on the nails: focus is on the card's primary action (nil)
ZEDQA wpt FAIL the nails' card offers Take as its primary action
ZEDQA wpt FAIL A on Take moved the nails into the bag (vanilla's transfer, 610 ticks)
ZEDQA wpt 4 after the take: World worldContainerStrip:container:1
ZEDQA wpt 5 no row in the World window's list: worldContainerStrip=1 worldMainInv(off)=0 worldTabContent(off)=0 worldItemCard(off)=0 worldTabBar=7 worldCtl=2; card false
ZEDQA wpt 5 before the padlock card: World worldContainerStrip:container:1
ZEDQA wpt 5 the padlock card: World worldContainerStrip:container:1
ZEDQA wpt FAIL the object card opens with focus on its main live verb (nil)
ZEDQA wpt FAIL A on it ran the verb (the padlock's code wheel shows)
ZEDQA wpt 5 after B: World worldContainerStrip:container:1
ZEDQA wpt FAIL B closes the object card and focus is back in the list, lit
ZEDQA wpt 6 Left from the World window's strip: Char charContainerStrip:container:1
ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
ZEDQA wpt 6 LB: Char charContainerStrip:container:1
ZEDQA wpt PASS LB lands in the Character window on a lit element
ZEDQA wpt 6 Right: World worldContainerStrip:container:1
ZEDQA wpt FAIL Right from a row lands on the bag on show
ZEDQA wpt FAIL Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
ZEDQA wpt FAIL 6 A on the nails: focus is on the card's primary action (nil)
ZEDQA wpt FAIL Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is nil; A runs it
ZEDQA wpt FAIL A on the card's primary action (Drop) moved the nails out of the bag (610 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (DROP)
ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt 8 no corkscrew row in the World window's list: worldContainerStrip=1 worldMainInv(off)=0 worldTabContent(off)=0 worldItemCard(off)=0 worldTabBar=7 worldCtl=2; card false
ZEDQA wpt FAIL 8 X on a row opens the context menu
ZEDQA wpt 8 after the menu's B: World worldContainerStrip:container:1
ZEDQA wpt FAIL 8 the menu closed: focus is back on the same row, lit
ZEDQA wpt 8 after hold A: World worldContainerStrip:container:1
ZEDQA wpt FAIL 8 hold A moved the hammer out of the crate
ZEDQA wpt 8 a moment later: World worldContainerStrip:container:1
ZEDQA wpt FAIL 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt 7 tabs: 12 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control equippart:Right Foot and it is in view (bottom 653 of 664)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 638 of 664)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control exercise:time:dec and it is in view (bottom 508 of 664)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 508 of 664)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 956 px in a 599 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control thermal:__gridscroll and it is in view (bottom 664 of 664)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 664 of 664)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control identity:__gridscroll and it is in view (bottom 664 of 664)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:__gridscroll is in view at the bottom (bottom 664 of 664)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control journal:group:6_1993 and it is in view (bottom 650 of 664)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 275 of 664)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control training:col1_Foraging and it is in view (bottom 664 of 664)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 648 of 664)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control craft:row:RemoveBattery and it is in view (bottom 228 of 664)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:row:RemoveBattery is in view at the bottom (bottom 228 of 664)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control build:section:all and it is in view (bottom 126 of 664)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:section:all is in view at the bottom (bottom 126 of 664)
ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control fur:mode:pickup and it is in view (bottom 121 of 664)
ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 121 of 664)
ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control map:canvas:cursor and it is in view (bottom 664 of 664)
ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 664 of 664)
ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control forage:disclosure and it is in view (bottom 348 of 664)
ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:disclosure is in view at the bottom (bottom 348 of 664)
ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control animals:createzone and it is in view (bottom 655 of 664)
ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 655 of 664)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control equippart:Right Foot and it is in view (bottom 636 of 654)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 626 of 654)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control exercise:time:dec and it is in view (bottom 580 of 654)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 580 of 654)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 980 px in a 580 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control thermal:__gridscroll and it is in view (bottom 654 of 654)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 654 of 654)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control identity:__gridscroll and it is in view (bottom 654 of 654)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:__gridscroll is in view at the bottom (bottom 654 of 654)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control journal:group:6_1993 and it is in view (bottom 638 of 654)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 212 of 654)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control training:col1_Foraging and it is in view (bottom 654 of 654)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 636 of 654)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control craft:row:RemoveBattery and it is in view (bottom 260 of 654)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:row:RemoveBattery is in view at the bottom (bottom 260 of 654)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control build:section:all and it is in view (bottom 144 of 654)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:section:all is in view at the bottom (bottom 144 of 654)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control fur:mode:pickup and it is in view (bottom 138 of 654)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 138 of 654)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control map:canvas:cursor and it is in view (bottom 654 of 654)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 654 of 654)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control forage:disclosure and it is in view (bottom 397 of 654)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:disclosure is in view at the bottom (bottom 397 of 654)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control animals:createzone and it is in view (bottom 644 of 654)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 644 of 654)
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 62 passed, 27 failed
ZEDQA wpt DONE
```

### 7. zedqa_messages.lua (`ZEDQA msg`) - PASS, 10 s

- go 13235 at 20:18:38
- 1 expected exception(s) ignored (expect=)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #7 ok=true
ZEDQA msg PASS nothing kept: no envelope on the belt
ZEDQA msg PASS the three notes are not on screen
ZEDQA msg PASS the three notes are kept in Messages
ZEDQA msg PASS the source has three messages (3)
ZEDQA msg PASS three are new (3)
ZEDQA msg PASS a toast names the mod
ZEDQA msg PASS the game runs on after the mod paused it for its note (speed 1)
ZEDQA msg PASS the envelope is on the belt
ZEDQA msg PASS a question still asks at once
ZEDQA msg PASS the mod got its answer (YES)
ZEDQA msg PASS a copy of the question, already read, is in Messages
ERROR: General f:16703 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:16703> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:99)
ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
ZEDQA msg PASS Messages opens on the mod
ZEDQA msg PASS opening it marks the mod's messages read
ZEDQA msg PASS four cards: three notes and the question (4)
ZEDQA msg PASS three OK buttons, one per note (3)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg PASS A on the next card's OK ran its callback
ZEDQA msg PASS the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (1446 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg PASS the last unanswered note got its OK as it left
ZEDQA msg all checks passed
ZEDQA msg DONE
```

### 8. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 16 s

- go 13236 at 20:18:51
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #8 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: HUNGRY | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (HUNGRY 2, STRESS 2, TIRED 2, THIRST 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,969 size 48, stack 222; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -500,33 442x98, trail right from -56,82
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS right: the trail ends at the moodle, level with it
ZEDQA mood left: 4 moodles on (HUNGRY 2, STRESS 2, TIRED 2, THIRST 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,969 size 48, stack 222; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 106,33 442x98, trail left from 104,82
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS left: the trail ends at the moodle, level with it
ZEDQA mood bottom: 4 moodles on (HUNGRY 2, STRESS 2, TIRED 2, THIRST 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1809,1972 222x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud -133,-156 442x98, trail down from 82,-56
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS bottom: the trail ends at the moodle, level with it
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 9. zedqa_belt_hands.lua (`ZEDQA bh`) - PASS, 4 s

- go 13237 at 20:19:11
- screenshots: zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bh start
[ZeD.QA] run #9 ok=true
ZEDQA bh PASS left wrist: the boxes run left to right (watch@0 OFF@102 #1@232 #2@328 #3@424 #4@667 MAIN@783)
ZEDQA bh PASS left wrist: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh PASS left wrist: the watch is left of the off hand
ZEDQA bh PASS left wrist: the full watch pops at the left end (left)
ZEDQA bh PASS pad: the belt starts on slot 1 (#1)
ZEDQA bh PASS pad: Left from slot 1 is the off hand (OFF)
ZEDQA bh PASS right wrist: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@565 MAIN@681 watch@786)
ZEDQA bh PASS right wrist: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh PASS right wrist: the watch is right of the main hand
ZEDQA bh PASS right wrist: the full watch pops at the right end (right)
ZEDQA bh PASS as worn: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@565 MAIN@681)
ZEDQA bh PASS as worn: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh all checks passed
ZEDQA bh DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    3x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
