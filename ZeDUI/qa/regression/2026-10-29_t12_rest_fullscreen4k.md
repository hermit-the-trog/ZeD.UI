# ZeD-UI regression - 2026-10-29 23:10 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 23:10:29 |
| Finished | 2026-10-29 23:27:48 (17 min 18 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/t12_rest.txt (23 scripts) |
| Result | **17/23 pass**, 0 warn, 1 fail, 0 timeout, 5 not run |
| Go numbers | 16231 to 16251 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_dash_green.lua: the game dropped to the main menu during this script
- quit: the game was still running after the quit (go 16249, 16250, 16251); close it by hand
- ZeD settings NOT put back (the game is still running): copy C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-10-29_t12_rest_fullscreen4k.md.modoptions.ini over C:\Users\danie\Zomboid\Lua\ModOptions.ini once it has closed

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_curtain.lua | cu | PASS | 141 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png |  |
| 3 | zedqa_px_icons.lua | px | PASS | 5 | zqa_px_panel.png, zqa_px_card.png, zqa_px_rows.png |  |
| 4 | zedqa_wheel_icons.lua | wi | PASS | 53 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png |  |
| 5 | zedqa_quick_chords.lua | qc | PASS | 23 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png |  |
| 6 | zedqa_two_widths.lua | tww | PASS | 70 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png |  |
| 7 | zedqa_plates_336.lua | p336 | PASS | 61 | zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png |  |
| 8 | zedqa_dash_props_smoke.lua | sm | PASS | 7 | zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png |  |
| 9 | zedqa_tm.lua | tm | PASS | 7 | zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png |  |
| 10 | zedqa_tour3.lua | t3 | PASS | 14 | zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png |  |
| 11 | zedqa_dash19.lua | dash | PASS | 71 | zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png |  |
| 12 | zedqa_dashpx.lua | dpx | PASS | 130 | zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png |  |
| 13 | zedqa_exinfo.lua | ex | PASS | 6 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png |  |
| 14 | zedqa_charinfo.lua | ci | PASS | 9 |  |  |
| 15 | zedqa_equipdrag.lua | eqd | PASS | 12 | zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png |  |
| 16 | zedqa_cazio_light.lua | czl | PASS | 33 | zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png |  |
| 17 | zedqa_dashnight.lua | dnt | PASS | 100 | zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png |  |
| 18 | zedqa_dash_green.lua | dgr | **FAIL** | 32 |  | 1 Java exception(s) in the log; no DONE; the game dropped to the main menu during this script |
| 19 | zedqa_dash_keys_edge.lua | dke | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 20 | zedqa_dash_brands.lua | dbr | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 21 | zedqa_testlang.lua | tlang | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 22 | zedqa_safemode.lua | safe | SKIP |  |  | not run: the game dropped to the main menu during this script |
| 23 | zedqa_soak.lua | soak | SKIP |  |  | not run: the game dropped to the main menu during this script |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 16231 at 23:11:42

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 830,13076,0 to the drag strip
ZEDQA pre clock 17.65 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:351 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:355 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_curtain.lua (`ZEDQA cu`) - PASS, 141 s

- go 16232 at 23:11:51
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #2 ok=true
ZEDQA cu loaded: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
ZEDQA cu scale 1.75 root 1.75 screen 3840x2160
ZEDQA cu reset: ZeD_Window.resetLayout
ZEDQA cu reset: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
ZEDQA cu before: x 1929 w 1617 title Ground + Maps button 244.94140625,11 23
ZEDQA cu rolled true: x 2643 w 903 (sum 3546 was 3546) rod 1929,0 714x46 content false title Maps
ZEDQA cu pad stops: worldContainerStrip:curtain:unroll
ZEDQA cu A on the tab
ZEDQA cu unrolled true: x 1929 w 1617 content true rod false
ZEDQA cu ok first roll World 1929,0 1617x735
ZEDQA cu rolled again true
ZEDQA cu tab closed: rolled false x 1929 w 777 content true drawer false
ZEDQA cu ok tab closed while rolled World 1929,0 777x735
ZEDQA cu World before: 1929,0 1617x735 (other 1134,0 777x735) drawer true tab tab maps
ZEDQA cu cycle1 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rollW 714
ZEDQA cu ok cycle1 rolled World rod flush at 1929,0 714x46
ZEDQA cu ok cycle1 rolled World 2643,0 903x735
ZEDQA cu ok cycle1 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle1 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 World 1929,0 1617x735
ZEDQA cu ok cycle1 other (Character) 1134,0 777x735
ZEDQA cu ok cycle1 World saved 1102.286,0.000 444.000x420.000
ZEDQA cu cycle2 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rollW 714
ZEDQA cu ok cycle2 rolled World rod flush at 1929,0 714x46
ZEDQA cu ok cycle2 rolled World 2643,0 903x735
ZEDQA cu ok cycle2 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle2 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 World 1929,0 1617x735
ZEDQA cu ok cycle2 other (Character) 1134,0 777x735
ZEDQA cu ok cycle2 World saved 1102.286,0.000 444.000x420.000
ZEDQA cu moved by rod World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rollW 714
ZEDQA cu ok moved by rod rolled World rod flush at 1929,0 714x46
ZEDQA cu ok moved by rod rolled World 2643,0 903x735
ZEDQA cu ok moved by rod while rolled: other Character 1134,0 777x735
ZEDQA cu moved by rod World moved by 200,200 (rod) to 2843,200 903x735
ZEDQA cu ok moved by rod moved World rod flush at 2129,200 714x46
ZEDQA cu moved by rod World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 903x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1617x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod World 2129,200 1617x735
ZEDQA cu ok moved by rod other (Character) 1134,0 777x735
ZEDQA cu ok moved by rod World saved 1216.571,114.286 444.000x420.000
ZEDQA cu moved by title World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1617x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 903x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rollW 714
ZEDQA cu ok moved by title rolled World rod flush at 2129,200 714x46
ZEDQA cu ok moved by title rolled World 2843,200 903x735
ZEDQA cu ok moved by title while rolled: other Character 1134,0 777x735
ZEDQA cu moved by title World moved by -200,200 (title) to 2643,400 903x735
ZEDQA cu ok moved by title moved World rod flush at 1929,400 714x46
ZEDQA cu moved by title World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title World 1929,400 1617x735
ZEDQA cu ok moved by title other (Character) 1134,0 777x735
ZEDQA cu ok moved by title World saved 1102.286,228.571 444.000x420.000
ZEDQA cu cycle5 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rollW 714
ZEDQA cu ok cycle5 rolled World rod flush at 1929,400 714x46
ZEDQA cu ok cycle5 rolled World 2643,400 903x735
ZEDQA cu ok cycle5 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle5 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 World 1929,400 1617x735
ZEDQA cu ok cycle5 other (Character) 1134,0 777x735
ZEDQA cu ok cycle5 World saved 1102.286,228.571 444.000x420.000
ZEDQA cu character health tab true
ZEDQA cu Character before: 294,0 1617x735 (other 1929,400 1617x735) drawer true tab tab health
ZEDQA cu cycle1 Character before roll: Character 294,0 1617x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rollW 714
ZEDQA cu ok cycle1 rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok cycle1 rolled Character 294,0 903x735
ZEDQA cu ok cycle1 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle1 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 Character 294,0 1617x735
ZEDQA cu ok cycle1 other (World) 1929,400 1617x735
ZEDQA cu ok cycle1 Character saved 648.000,0.000 444.000x420.000
ZEDQA cu cycle2 Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rollW 714
ZEDQA cu ok cycle2 rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok cycle2 rolled Character 294,0 903x735
ZEDQA cu ok cycle2 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle2 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 Character 294,0 1617x735
ZEDQA cu ok cycle2 other (World) 1929,400 1617x735
ZEDQA cu ok cycle2 Character saved 648.000,0.000 444.000x420.000
ZEDQA cu moved by rod Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rollW 714
ZEDQA cu ok moved by rod rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok moved by rod rolled Character 294,0 903x735
ZEDQA cu ok moved by rod while rolled: other World 1929,400 1617x735
ZEDQA cu moved by rod Character moved by 200,200 (rod) to 494,200 903x735
ZEDQA cu ok moved by rod moved Character rod flush at 1397,200 714x46
ZEDQA cu moved by rod Character rolled, before unroll: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character unrolled: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod Character 494,200 1617x735
ZEDQA cu ok moved by rod other (World) 1929,400 1617x735
ZEDQA cu ok moved by rod Character saved 762.286,114.286 444.000x420.000
ZEDQA cu moved by title Character before roll: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rolled: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rollW 714
ZEDQA cu ok moved by title rolled Character rod flush at 1397,200 714x46
ZEDQA cu ok moved by title rolled Character 494,200 903x735
ZEDQA cu ok moved by title while rolled: other World 1929,400 1617x735
ZEDQA cu moved by title Character moved by 200,200 (title) to 694,400 903x735
ZEDQA cu ok moved by title moved Character rod flush at 1597,400 714x46
ZEDQA cu moved by title Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title Character 694,400 1617x735
ZEDQA cu ok moved by title other (World) 1929,400 1617x735
ZEDQA cu ok moved by title Character saved 876.571,228.571 444.000x420.000
ZEDQA cu cycle5 Character before roll: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rollW 714
ZEDQA cu ok cycle5 rolled Character rod flush at 1597,400 714x46
ZEDQA cu ok cycle5 rolled Character 694,400 903x735
ZEDQA cu ok cycle5 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle5 Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 Character 694,400 1617x735
ZEDQA cu ok cycle5 other (World) 1929,400 1617x735
ZEDQA cu ok cycle5 Character saved 876.571,228.571 444.000x420.000
ZEDQA cu closed rolled (inventory key) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (inventory key) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (inventory key) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) World window closed
ZEDQA cu ok closed rolled (inventory key) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (inventory key) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (rod close box) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (rod close box) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (rod close box) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (rod close box) World window closed
ZEDQA cu ok closed rolled (rod close box) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (rod close box) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (rod close box) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (rod close box) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (controller Y hold) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (controller Y hold) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (controller Y hold) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) World window closed
ZEDQA cu ok closed rolled (controller Y hold) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (controller Y hold) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (inventory key) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (inventory key) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) Character window closed
ZEDQA cu ok closed rolled (inventory key) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (inventory key) reopened: other World 1929,400 777x735
ZEDQA cu closed rolled (close box) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (close box) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (close box) Character window closed
ZEDQA cu ok closed rolled (close box) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (close box) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (close box) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (close box) reopened: other World 1929,400 777x735
ZEDQA cu closed rolled (controller Y hold) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (controller Y hold) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) Character window closed
ZEDQA cu ok closed rolled (controller Y hold) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (controller Y hold) reopened: other World 1929,400 777x735
ZEDQA cu World tabs: on maps 1929,400 1617x735 (other 694,400 1617x735)
ZEDQA cu ok tab forage reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab forage World rolled before the press
ZEDQA cu ok tab forage World still rolled on the tab (tab forage)
ZEDQA cu ok tab forage rolled World 2643,400 903x735
ZEDQA cu ok tab forage World unrolled (rods in UI 0)
ZEDQA cu ok tab forage unrolled World 1929,400 1617x735
ZEDQA cu ok tab forage unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab forage back on maps World 1929,400 1617x735
ZEDQA cu ok tab craft reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab craft World rolled before the press
ZEDQA cu ok tab craft World still rolled on the tab (tab craft)
ZEDQA cu ok tab craft rolled World 2643,400 903x735
ZEDQA cu ok tab craft World unrolled (rods in UI 0)
ZEDQA cu ok tab craft unrolled World 1929,400 1617x735
ZEDQA cu ok tab craft unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab craft back on maps World 1929,400 1617x735
ZEDQA cu ok tab build reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab build World rolled before the press
ZEDQA cu ok tab build World still rolled on the tab (tab build)
ZEDQA cu ok tab build rolled World 2643,400 903x735
ZEDQA cu ok tab build World unrolled (rods in UI 0)
ZEDQA cu ok tab build unrolled World 1929,400 1617x735
ZEDQA cu ok tab build unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab build back on maps World 1929,400 1617x735
ZEDQA cu ok tab furniture reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab furniture World rolled before the press
ZEDQA cu ok tab furniture World still rolled on the tab (tab furniture)
ZEDQA cu ok tab furniture rolled World 2643,400 903x735
ZEDQA cu ok tab furniture World unrolled (rods in UI 0)
ZEDQA cu ok tab furniture unrolled World 1929,400 1617x735
ZEDQA cu ok tab furniture unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab furniture back on maps World 1929,400 1617x735
ZEDQA cu ok tab animals reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab animals World rolled before the press
ZEDQA cu ok tab animals World still rolled on the tab (tab animals)
ZEDQA cu ok tab animals rolled World 2643,400 903x735
ZEDQA cu ok tab animals World unrolled (rods in UI 0)
ZEDQA cu ok tab animals unrolled World 1929,400 1617x735
ZEDQA cu ok tab animals unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab animals back on maps World 1929,400 1617x735
ZEDQA cu tab radio World: not shown here, skipped
ZEDQA cu ok tab vehicle reference, back on maps World 1929,400 1617x735
ZEDQA cu ok tab vehicle World rolled before the press
ZEDQA cu ok tab vehicle World still rolled on the tab (tab vehicle)
ZEDQA cu ok tab vehicle rolled World 2643,400 903x735
ZEDQA cu ok tab vehicle World unrolled (rods in UI 0)
ZEDQA cu ok tab vehicle unrolled World 1929,400 1617x735
ZEDQA cu ok tab vehicle unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab vehicle back on maps World 1929,400 1617x735
ZEDQA cu ok forage and back World still rolled (tab maps)
ZEDQA cu ok forage and back rolled World 2643,400 903x735
ZEDQA cu ok forage and back, unrolled World 1929,400 1617x735
ZEDQA cu World Loot (unrolled) 1929,400 777x735
ZEDQA cu ok Loot reference, back on maps World 1929,400 1617x735
ZEDQA cu ok Loot World rolled before the press
ZEDQA cu ok Loot World side down with the press (rolled false tab loot rods in UI 0)
ZEDQA cu ok Loot while rolled World 1929,400 777x735
ZEDQA cu ok Loot while rolled: other Character 694,400 1617x735
ZEDQA cu ok Loot while rolled, back on maps World 1929,400 1617x735
ZEDQA cu ok maps again World rolled before the press
ZEDQA cu ok maps again World side down (rolled false)
ZEDQA cu ok maps pressed again while rolled World 1929,400 777x735
ZEDQA cu ok maps again, back on maps World 1929,400 1617x735
ZEDQA cu Character tabs: on health 694,400 1617x735 (other 1929,400 1617x735)
ZEDQA cu ok tab skills reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab skills Character rolled before the press
ZEDQA cu ok tab skills Character still rolled on the tab (tab skills)
ZEDQA cu ok tab skills rolled Character 694,400 903x735
ZEDQA cu ok tab skills Character unrolled (rods in UI 0)
ZEDQA cu ok tab skills unrolled Character 694,400 1617x735
ZEDQA cu ok tab skills unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab skills back on health Character 694,400 1617x735
ZEDQA cu ok tab equip reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab equip Character rolled before the press
ZEDQA cu ok tab equip Character still rolled on the tab (tab equip)
ZEDQA cu ok tab equip rolled Character 694,400 903x735
ZEDQA cu ok tab equip Character unrolled (rods in UI 0)
ZEDQA cu ok tab equip unrolled Character 694,400 1617x735
ZEDQA cu ok tab equip unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab equip back on health Character 694,400 1617x735
ZEDQA cu ok tab thermal reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab thermal Character rolled before the press
ZEDQA cu ok tab thermal Character still rolled on the tab (tab thermal)
ZEDQA cu ok tab thermal rolled Character 694,400 903x735
ZEDQA cu ok tab thermal Character unrolled (rods in UI 0)
ZEDQA cu ok tab thermal unrolled Character 694,400 1617x735
ZEDQA cu ok tab thermal unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab thermal back on health Character 694,400 1617x735
ZEDQA cu ok tab identity reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab identity Character rolled before the press
ZEDQA cu ok tab identity Character still rolled on the tab (tab identity)
ZEDQA cu ok tab identity rolled Character 694,400 903x735
ZEDQA cu ok tab identity Character unrolled (rods in UI 0)
ZEDQA cu ok tab identity unrolled Character 694,400 1617x735
ZEDQA cu ok tab identity unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab identity back on health Character 694,400 1617x735
ZEDQA cu ok tab journal reference, back on health Character 694,400 1617x735
ZEDQA cu ok tab journal Character rolled before the press
ZEDQA cu ok tab journal Character still rolled on the tab (tab journal)
ZEDQA cu ok tab journal rolled Character 694,400 903x735
ZEDQA cu ok tab journal Character unrolled (rods in UI 0)
ZEDQA cu ok tab journal unrolled Character 694,400 1617x735
ZEDQA cu ok tab journal unrolled: other World 1929,400 1617x735
ZEDQA cu ok tab journal back on health Character 694,400 1617x735
ZEDQA cu tab radio Character: not shown here, skipped
ZEDQA cu ok skills and back Character still rolled (tab health)
ZEDQA cu ok skills and back rolled Character 694,400 903x735
ZEDQA cu ok skills and back, unrolled Character 694,400 1617x735
ZEDQA cu Character Loot (unrolled) 1534,400 777x735
ZEDQA cu ok Loot reference, back on health Character 694,400 1617x735
ZEDQA cu ok Loot Character rolled before the press
ZEDQA cu ok Loot Character side down with the press (rolled false tab loot rods in UI 0)
ZEDQA cu ok Loot while rolled Character 1534,400 777x735
ZEDQA cu ok Loot while rolled: other World 1929,400 1617x735
ZEDQA cu ok Loot while rolled, back on health Character 694,400 1617x735
ZEDQA cu ok health again Character rolled before the press
ZEDQA cu ok health again Character side down (rolled false)
ZEDQA cu ok health pressed again while rolled Character 1534,400 777x735
ZEDQA cu ok health again, back on health Character 694,400 1617x735
ZEDQA cu geometry checks 222, differences 0
ZEDQA cu at quit, unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu at quit, rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu DONE
```

### 3. zedqa_px_icons.lua (`ZEDQA px`) - PASS, 5 s

- go 16233 at 23:14:15
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

### 4. zedqa_wheel_icons.lua (`ZEDQA wi`) - PASS, 53 s

- go 16234 at 23:14:23
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wi no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wi start car=BaseVehicle{ Name:null, ID:53 }
[ZeD.QA] run #4 ok=true
ZEDQA wi scene: screen 3840x2160, scale option 7, icon box 28 at rest, 42 pointed
ZEDQA wi PASS all 153 icons load at 16, 24, 32 and 48, each its own file (0 problems)
ZEDQA wi PASS the drawing for each box: the largest that fits, at its own size; under 16 the 16 scaled down
ZEDQA wi at this scale: box 28 draws the 24, box 42 draws the 32
ZEDQA wi PASS vanilla's words: 29 of 30 give their icon over vanilla's picture
ZEDQA wi NOTE no words in this language for ContextMenu_Vehicle_AttachVehicle (vanilla shows the key itself; nothing to match)
ZEDQA wi PASS vanilla's pictures by name, in order: 95 of 95
ZEDQA wi PASS items, traits and the controller's glyphs keep their pictures
ZEDQA wi PASS headlights on / a light source on share a picture and come out id:headlight_on / id:bulb_on
ZEDQA wi PASS headlights off / a light source off share a picture and come out id:headlight_off / id:bulb_off
ZEDQA wi PASS get in / change seats share a picture and come out id:car_enter / id:seat
ZEDQA wi PASS get out / a door share a picture and come out id:car_exit / id:car_door
ZEDQA wi PASS lock / unlock share a picture and come out id:padlock / id:padlock_open
ZEDQA wi PASS hitch / unhitch share a picture and come out id:link / id:unlink
ZEDQA wi PASS zoom in / plus share a picture and come out id:zoom_in / id:plus
ZEDQA wi PASS zoom out / minus share a picture and come out id:zoom_out / id:minus
ZEDQA wi PASS the tab icons, and every tab of both windows has one
ZEDQA wi PASS left: the wheel builds
ZEDQA wi PASS right: the wheel builds
ZEDQA wi PASS up: the wheel builds
ZEDQA wi PASS down: the wheel builds
ZEDQA wi PASS select: the wheel builds
ZEDQA wi PASS 140 slices on ZeD's five wheels, 124 with a wheel icon, the rest items, glyphs or colours
ZEDQA wi PASS the ZeD wheel's pickers give their choices the setting's icon
ZEDQA wi PASS the map's slices on ZeD's wheels: 80 with their icon
ZEDQA wi NOTE not on the wheels now (the state decides): the wounds (no wound now); character > Watch / UI_ZeD_Wheel_OpenWatch; character > Watch / UI_ZeD_Wheel_WatchLight; character > Watch / UI_ZeD_Wheel_WatchAlarm; character > Radio / UI_ZeD_Wheel_NextStation; world > Search / UI_disable_search_mode; world > Vehicle / IGUI_VehiclePartCatdashboard
ZEDQA wi PASS Crouch and Auto-walk show what the slice does now: sneak, autowalk
ZEDQA wi dpad_left: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left: 10 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_up: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Lighter/Turn on=bulb_on
ZEDQA wi PASS dpad_down: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_left_use: 5 slices | 1:Smoke=cigarette 2:Read=book 3:Watch/No watch on your wrist.=watch 4:Radio/No radio in your hands or on your back.=walkie
ZEDQA wi PASS dpad_left_use: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_speed: 5 slices | 1:Pause/In use=pause 2:FF x 1=ff1 3:FF x 2=ff2 4:FF x 3=wait
ZEDQA wi PASS dpad_down_speed: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_view: 5 slices | 1:Hide the interface/Until you take this again=eye_off 2:Reset windows/Both windows back to where they start=rotate 3:Text size=textsize 4:OPTIONS/Options, on ZeD's page=gears
ZEDQA wi PASS dpad_down_view: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select_theme: 4 slices | 1:Dark/In use=theme 2:Light=theme 3:High contrast=theme
ZEDQA wi PASS dpad_select_theme: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_friendly: 6 slices | 1:Wave Hi=wave 2:Bye=wave_bye 3:Clap=clap 4:Thumbs Up=thumbs_up 5:Thank You=bow
ZEDQA wi PASS emotes_friendly: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_hostile: 5 slices | 1:Insult=insult 2:Stop=hand 3:Surrender=surrender 4:Thumbs Down=thumbs_down
ZEDQA wi PASS emotes_hostile: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_group: 7 slices | 1:Follow Me=follow_me 2:Come Here=come_here 3:Yes=yes 4:No=no 5:Shrug=shrug 6:Undecided=undecided
ZEDQA wi PASS emotes_group: 6 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_signal: 9 slices | 1:Cease Fire=target_off 2:Ok=yes 3:Move Out=move_out 4:Freeze=freeze 5:Follow Behind=follow_behind 6:Fire=target 7:Come=come_here 8:Salute=salute
ZEDQA wi PASS emotes_signal: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi gun: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi light: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi stick: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi vanilla_back: 10 slices | 1:Player Info=heart 2:Crafting=craft 3:Building=bricks 4:Zoom 75%=zoom_in 5:Pause=pause 6:FF x 1=ff1 7:Zoom 125%=zoom_out 8:Move furniture=chair 9:Enable Search Mode=eye 10:Investigate This Area=magnifier
ZEDQA wi PASS vanilla_back: 10 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi vanilla_dright: 3 slices | 1:Show/Hide World Map=map 2:Designated Zones=fence 3:Toggle Survival Guide=guide
ZEDQA wi PASS vanilla_dright: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi car_outside: 3 slices | 1:Vehicle Mechanics=engine 2:Enter Vehicle=car_enter 3:Need a hose.=gas_siphon
ZEDQA wi PASS car_outside: 3 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Lock all doors=padlock 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 12 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi PASS vanilla's radials and ZeD's wheels, live: 124 slices, 122 wheel icons, 2 kept pictures
ZEDQA wi now at 1x (text size small): icon box 16 at rest, 24 pointed
ZEDQA wi dpad_left_1x: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left_1x: 9 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_right_1x: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_up_1x: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_down_1x: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down_1x: 8 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi dpad_select_1x: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select_1x: 11 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi light_1x: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 4 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi car_inside_1x: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Lock all doors=padlock 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 12 wheel icons drawn pixel for pixel at the box's size
ZEDQA wi scale back to option 7: icon box 28
ZEDQA wi 0 failed, 2 notes
ZEDQA wi DONE
```

### 5. zedqa_quick_chords.lua (`ZEDQA qc`) - PASS, 23 s

- go 16235 at 23:15:19
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
[ZeD.QA] windows reset (R)
ZEDQA qc start
[ZeD.QA] run #5 ok=true
ZEDQA qc the torch (added) and water, a cigarette, a lighter, an apple in the main inventory; hands: nil / nil
ZEDQA qc LB+A = character:3 (Character > Eat): Eat
ZEDQA qc PASS LB+A: the default names a slice
ZEDQA qc LB+B = character:4 (Character > Drink): Drink
ZEDQA qc PASS LB+B: the default names a slice
ZEDQA qc LB+X = now:8 (Here and now > Light): Flashlight
ZEDQA qc PASS LB+X: the default names a slice
ZEDQA qc LB+Y = character:8:1 (Character > Use > Smoke): Smoke
ZEDQA qc PASS LB+Y: the default names a slice
ZEDQA qc LB+L3 = now:1:1 (Here and now > Sit > Sit on ground): Sit on ground
ZEDQA qc PASS LB+L3: the default names a slice
ZEDQA qc LB+R3 = social:5 (Social > Shout): Shout
ZEDQA qc PASS LB+R3: the default names a slice
ZEDQA qc RB+A = character:5 (Character > Medicine and first aid): Medicine and first aid
ZEDQA qc PASS RB+A: the default names a slice
ZEDQA qc RB+B = character:2 (Character > Weapons): Weapons
ZEDQA qc PASS RB+B: the default names a slice
ZEDQA qc RB+X = character:8:2 (Character > Use > Read): Read
ZEDQA qc PASS RB+X: the default names a slice
ZEDQA qc RB+Y = world:2:1 (World > Map > Show/Hide World Map): Show/Hide World Map
ZEDQA qc PASS RB+Y: the default names a slice
ZEDQA qc RB+L3 = now:3 (Here and now > Auto-walk): Auto-walk
ZEDQA qc PASS RB+L3: the default names a slice
ZEDQA qc RB+R3 = now:2 (Here and now > Crouch): Crouch
ZEDQA qc PASS RB+R3: the default names a slice
ZEDQA qc LB + X queued: ISEquipWeaponAction
ZEDQA qc PASS LB + X: the game's prompts never saw X
ZEDQA qc PASS a light for LB + X
ZEDQA qc PASS LB + X: the light is in a hand
ZEDQA qc PASS LB + X: the light is on
ZEDQA qc PASS LB + X again: the light is off
ZEDQA qc LB + X from a bag queued: ISInventoryTransferAction, ISEquipWeaponAction
ZEDQA qc PASS LB + X from a bag: the light is out of the bag
ZEDQA qc PASS LB + X from a bag: the light is in a hand
ZEDQA qc PASS LB + X from a bag: the light is on
ZEDQA qc PASS stuffed: Eat says Too full to eat more.
ZEDQA qc LB + A (eat) queued: ISEatFoodAction
ZEDQA qc PASS LB + A (eat): the game queues its action
ZEDQA qc LB + B (drink) queued: ISDrinkFromBottle
ZEDQA qc PASS LB + B (drink): the game queues its action
ZEDQA qc LB + Y (smoke) queued: ISEatFoodAction, ISInventoryTransferAction
ZEDQA qc PASS LB + Y (smoke): the game queues its action
ZEDQA qc said: No QA Gone on you.
ZEDQA qc PASS a gone thing: the character says No QA Gone on you.
ZEDQA qc PASS the Here and now wheel is open
ZEDQA qc PASS RB + Y on Crouch: the chord reads now:2
ZEDQA qc the bubble's note: Now on RB + Y. It replaces Show/Hide World Map.
ZEDQA qc PASS the bubble says what it did
ZEDQA qc PASS opened again: Crouch shows RB + Y
ZEDQA qc PASS ZeD setup is open on the pause screen
ZEDQA qc PASS ZeD setup has the twelve chord rows (12)
ZEDQA qc PASS ZeD setup has Put things back
ZEDQA qc the list for LB+A: 89 items, 81 to choose
ZEDQA qc PASS the chord's list offers the wheels' actions
ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
ZEDQA qc PASS the chords are as they were
ZEDQA qc all checks passed
ZEDQA qc DONE
```

### 6. zedqa_two_widths.lua (`ZEDQA tww`) - PASS, 70 s

- go 16236 at 23:15:46
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #6 ok=true
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
ERROR: General f:25305 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:25316 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA tww PASS after the whole run both windows are where and as big as they were (1134,0 777x735 / 1929,0 777x735 -> 1134,0 777x735 / 1929,0 777x735)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card lock, World object card plant, World object card track, World object card trough
ZEDQA tww ALL PASS
ZEDQA tww DONE
```

### 7. zedqa_plates_336.lua (`ZEDQA p336`) - PASS, 61 s

- go 16237 at 23:16:59
- screenshots: zqa_p336_scale175_oven.png, zqa_p336_scale175_microwave.png, zqa_p336_scale175_chrome.png, zqa_p336_scale175_generator.png, zqa_p336_scale175_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png

```text
[ZeD.QA] windows reset (R)
ZEDQA p336 start
[ZeD.QA] run #7 ok=true
ZEDQA p336 indoors at 891,13010
ZEDQA p336 placed: oven true, microwave true, chrome true, generator true, grill true
ZEDQA p336 phase A: root 1.75 (the run's own scale)
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale175, root 1.75, zoom 2]: plate oven_modern, drawn oven_modern, tab 840 px (half 385, full 840); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the main face fits at the whole zoom, and is drawn (oven_modern)
ZEDQA p336 PASS oven: at the run's own scale the main face is drawn
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale175, root 1.75, zoom 2]: plate mw_white, drawn mw_white, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the main face fits at the whole zoom, and is drawn (mw_white)
ZEDQA p336 PASS microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale175, root 1.75, zoom 2]: plate mw_chrome, drawn mw_chrome, tab 840 px (half 385, full 840); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the main face fits at the whole zoom, and is drawn (mw_chrome)
ZEDQA p336 PASS chrome microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale175, root 1.75]: card 840 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale175, root 1.75]: card 840 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13011.5 (grill 893,13012)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 phase B: forced root 0.50
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale050, root 0.50, zoom 1]: plate oven_modern, drawn oven_modern_n, tab 240 px (half 110, full 240); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the main face does not fit, the narrow face is drawn (oven_modern_n)
ZEDQA p336 PASS oven: at the run's own scale the main face is drawn
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale050, root 0.50, zoom 1]: plate mw_white, drawn mw_white_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the main face does not fit, the narrow face is drawn (mw_white_n)
ZEDQA p336 PASS microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale050, root 0.50, zoom 1]: plate mw_chrome, drawn mw_chrome_n, tab 240 px (half 110, full 240); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the main face does not fit, the narrow face is drawn (mw_chrome_n)
ZEDQA p336 PASS chrome microwave: at the run's own scale the main face is drawn
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale050, root 0.50]: card 240 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale050, root 0.50]: card 240 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13011.5 (grill 893,13012)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 cleanup done: 5 things removed
ZEDQA p336 all checks passed
ZEDQA p336 DONE
```

### 8. zedqa_dash_props_smoke.lua (`ZEDQA sm`) - PASS, 7 s

- go 16238 at 23:18:03
- screenshots: zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sm start
[ZeD.QA] run #8 ok=true
ZEDQA sm spawned Base.CarLightsPolice beside the character
ZEDQA sm pickup=true police=true
ZEDQA sm dash visible=true design=d6
ZEDQA sm radio up=true
ERROR: General f:31607 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:31612 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA sm siren up=true dash design=police
ZEDQA sm ham radio up=true
ZEDQA sm DONE
```

### 9. zedqa_tm.lua (`ZEDQA tm`) - PASS, 7 s

- go 16239 at 23:18:14
- screenshots: zedqa_tm_tooltips.png, zedqa_tm_maps.png, zedqa_tm_dash.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tm armed
[ZeD.QA] run #9 ok=true
ZEDQA tm root=1.75 proxy=true realTM=true
ZEDQA tm tip1 462.78125x223.7421875 at 300,300 desc=349.78125x136.59375 lines=4 font=MainMenu1
ZEDQA tm tip2 420x194.890625 at 300,620 desc=367x194.890625 lines=6 font=MainMenu1
ZEDQA tm watch family=nil size=228x52 at 3596,10
ZEDQA tm maps tab clicked maps
ZEDQA tm world tabs loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA tm maps shot active=maps win=1929,0 1617x735
ZEDQA tm dash design=horizon visible=true size=1600x356 at 1120,1804
ZEDQA tm done
```

### 10. zedqa_tour3.lua (`ZEDQA t3`) - PASS, 14 s

- go 16240 at 23:18:24
- screenshots: zedqa_t3_SmallCar02.png, zedqa_t3_ModernCar.png, zedqa_t3_ModernCar02.png, zedqa_t3_SUV.png, zedqa_t3_Van.png, zedqa_t3_PickUpVan.png, zedqa_t3_OffRoad.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #10 ok=true
ZEDQA t3 SmallCar02 design=horizon visible=true hits=25 badge=nil/nil cluster=nil
ZEDQA t3 ModernCar design=dashelite visible=true hits=29 badge=nil/nil cluster=nil
ZEDQA t3 ModernCar02 design=primani visible=true hits=26 badge=nil/nil cluster=nil
ZEDQA t3 SUV design=suv visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA t3 Van design=van visible=true hits=21 badge=nil/nil cluster=nil
ZEDQA t3 PickUpVan design=bulldriver visible=true hits=22 badge=nil/nil cluster=nil
ZEDQA t3 OffRoad design=rancher visible=true hits=25 badge=nil/nil cluster=nil
ZEDQA t3 done
```

### 11. zedqa_dash19.lua (`ZEDQA dash`) - PASS, 71 s

- go 16241 at 23:18:42
- screenshots: zqa_dash_01_luxury.png, zqa_dash_02_nyala.png, zqa_dash_03_cossette.png, zqa_dash_04_police.png, zqa_dash_05_d6.png, zqa_dash_06_dashelite.png, zqa_dash_07_primani.png, zqa_dash_08_dart.png, zqa_dash_09_horizon.png, zqa_dash_10_wagon.png, zqa_dash_11_suv.png, zqa_dash_12_van.png, zqa_dash_13_bulldriver.png, zqa_dash_14_rancher.png, zqa_dash_15_taxi.png, zqa_dash_16_ambulance.png, zqa_dash_17_fire.png, zqa_dash_18_ranger.png, zqa_dash_19_race.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #11 ok=true
ZEDQA dash 01_luxury design=luxury rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 02_nyala design=nyala rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 03_cossette design=cossette rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 04_police design=police rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 05_d6 car not ready in 36 ticks; removed, next square
ZEDQA dash 05_d6 design=d6 rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 06_dashelite design=dashelite rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 07_primani design=primani rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 08_dart car not ready in 36 ticks; removed, next square
ZEDQA dash 08_dart design=dart rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 09_horizon design=horizon rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 10_wagon design=wagon rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 11_suv design=suv rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 12_van car not ready in 36 ticks; removed, next square
ZEDQA dash 12_van design=van rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 13_bulldriver design=bulldriver rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 14_rancher design=rancher rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 15_taxi car not ready in 36 ticks; removed, next square   (x2)
ZEDQA dash 15_taxi design=taxi rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 16_ambulance design=ambulance rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 17_fire design=fire rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash 18_ranger car not ready in 36 ticks; removed, next square
ZEDQA dash 18_ranger design=ranger rect=1120,1804,1600,356 running=false radio=true heat=true lights=true badge=nil/nil screen=3840x2160
ERROR: General f:39549 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:39552 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dash 19_race design=race rect=1120,1804,1600,356 running=false radio=false heat=true lights=true badge=nil/nil screen=3840x2160
ZEDQA dash DONE
```

### 12. zedqa_dashpx.lua (`ZEDQA dpx`) - PASS, 130 s

- go 16242 at 23:19:56
- screenshots: zqa_dashpx_01_luxury_keyon.png, zqa_dashpx_01_luxury.png, zqa_dashpx_02_nyala_keyon.png, zqa_dashpx_02_nyala.png, zqa_dashpx_03_cossette_keyon.png, zqa_dashpx_03_cossette.png, zqa_dashpx_04_police_keyon.png, zqa_dashpx_04_police.png, zqa_dashpx_05_d6_keyon.png, zqa_dashpx_05_d6.png, zqa_dashpx_06_dashelite_keyon.png, zqa_dashpx_06_dashelite.png, zqa_dashpx_07_primani_keyon.png, zqa_dashpx_07_primani.png, zqa_dashpx_08_dart_keyon.png, zqa_dashpx_08_dart.png, zqa_dashpx_09_horizon_keyon.png, zqa_dashpx_09_horizon.png, zqa_dashpx_10_wagon_keyon.png, zqa_dashpx_10_wagon.png, zqa_dashpx_11_suv_keyon.png, zqa_dashpx_11_suv.png, zqa_dashpx_12_van_keyon.png, zqa_dashpx_12_van.png, zqa_dashpx_13_bulldriver_keyon.png, zqa_dashpx_13_bulldriver.png, zqa_dashpx_14_rancher_keyon.png, zqa_dashpx_14_rancher.png, zqa_dashpx_15_taxi_keyon.png, zqa_dashpx_15_taxi.png, zqa_dashpx_16_ambulance_keyon.png, zqa_dashpx_16_ambulance.png, zqa_dashpx_17_fire_keyon.png, zqa_dashpx_17_fire.png, zqa_dashpx_18_ranger_keyon.png, zqa_dashpx_18_ranger.png, zqa_dashpx_19_race_keyon.png, zqa_dashpx_19_race.png, zqa_dashpx_20_knoxvan_keyon.png, zqa_dashpx_20_knoxvan.png, zqa_dashpx_21_fossoild6_keyon.png, zqa_dashpx_21_fossoild6.png, zqa_dashpx_23_meadesheriff_keyon.png, zqa_dashpx_23_meadesheriff.png, zqa_dashpx_24_lcpd_keyon.png, zqa_dashpx_24_lcpd.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #12 ok=true
ZEDQA dpx 01_luxury design=luxury rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=MERCIA LANG 4000 livery= make=MERCIA model=LANG 4000 unit=MERCIA - UNIT 80 hits=27 screen=3840x2160
ZEDQA dpx 02_nyala car not ready in 36 ticks; removed, next square
ZEDQA dpx 02_nyala design=nyala rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER NYALA livery= make=CHEVALIER model=NYALA unit=CHEVALIER - UNIT 80 hits=22 screen=3840x2160
ZEDQA dpx 03_cossette design=cossette rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER COSSETTE livery= make=CHEVALIER model=COSSETTE unit=CHEVALIER - UNIT 80 hits=22 screen=3840x2160
ZEDQA dpx 04_police design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=STATE TROOPER CHEVALIER NYALA livery=STATE TROOPER make=CHEVALIER model=NYALA unit=TROOPER - UNIT 80 hits=19 screen=3840x2160
ZEDQA dpx 05_d6 design=d6 rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 80 hits=22 screen=3840x2160
ZEDQA dpx 06_dashelite car not ready in 36 ticks; removed, next square
ZEDQA dpx 06_dashelite design=dashelite rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=DASH ELITE livery= make=DASH model=ELITE unit=DASH - UNIT 80 hits=29 screen=3840x2160
ZEDQA dpx 07_primani design=primani rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=CHEVALIER PRIMANI livery= make=CHEVALIER model=PRIMANI unit=CHEVALIER - UNIT 80 hits=26 screen=3840x2160
ZEDQA dpx 08_dart design=dart rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER DART livery= make=CHEVALIER model=DART unit=CHEVALIER - UNIT 80 hits=21 screen=3840x2160
ZEDQA dpx 09_horizon car not ready in 36 ticks; removed, next square
ZEDQA dpx 09_horizon design=horizon rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=MASTERSON HORIZON livery= make=MASTERSON model=HORIZON unit=MASTERSON - UNIT 80 hits=21 screen=3840x2160
ZEDQA dpx 10_wagon design=wagon rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=CHEVALIER CERISE WAGON livery= make=CHEVALIER model=CERISE WAGON unit=CHEVALIER - UNIT 80 hits=22 screen=3840x2160
ZEDQA dpx 11_suv design=suv rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=FRANKLIN ALL-TERRAIN livery= make=FRANKLIN model=ALL-TERRAIN unit=FRANKLIN - UNIT 80 hits=26 screen=3840x2160
ZEDQA dpx 12_van car not ready in 36 ticks; removed, next square   (x2)
ZEDQA dpx 12_van design=van rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=SPIFFO VAN livery=SPIFFO VAN make=FRANKLIN model=VALULINE unit=SPIFFO - UNIT 80 hits=21 screen=3840x2160
ZEDQA dpx 13_bulldriver design=bulldriver rect=1120,1804,1600,356 k=2 running=true radio=true/premium heat=true lights=true name=DASH BULLDRIVER livery= make=DASH model=BULLDRIVER unit=DASH - UNIT 80 hits=26 screen=3840x2160
ZEDQA dpx 14_rancher design=rancher rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=DASH RANCHER livery= make=DASH model=RANCHER unit=DASH - UNIT 80 hits=21 screen=3840x2160
ZEDQA dpx 15_taxi car not ready in 36 ticks; removed, next square   (x2)
ZEDQA dpx 15_taxi design=taxi rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=TAXI livery=TAXI make=CHEVALIER model=NYALA unit=TAXI - CAB 80 hits=22 screen=3840x2160
ZEDQA dpx 16_ambulance design=ambulance rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=AMBULANCE livery=AMBULANCE make=FRANKLIN model=VALULINE unit=AMBULANCE - UNIT 80 hits=19 screen=3840x2160
ZEDQA dpx 17_fire design=fire rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=FIRE DEPARTMENT CHEVALIER D6 livery=FIRE DEPARTMENT make=CHEVALIER model=D6 unit=FIRE - ENGINE 80 hits=19 screen=3840x2160
ZEDQA dpx 18_ranger car not ready in 36 ticks; removed, next square
ZEDQA dpx 18_ranger design=ranger rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=RANGER CHEVALIER NYALA livery=RANGER make=CHEVALIER model=NYALA unit=RANGER - UNIT 80 hits=19 screen=3840x2160
ERROR: General f:47199 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:47202 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dpx 19_race design=race rect=1120,1804,1600,356 k=2 running=true radio=false/nil heat=true lights=true name=RACE CAR livery=RACE CAR make=RACE model=CAR unit=RACE - UNIT 80 hits=5 screen=3840x2160
ZEDQA dpx 20_knoxvan design=van rect=1120,1804,1600,356 k=2 running=true radio=true/valutech heat=true lights=true name=KNOX DISTILLERY FRANKLIN VALULINE livery=KNOX DISTILLERY make=FRANKLIN model=VALULINE unit=KNOX - UNIT 80 hits=21 screen=3840x2160
ZEDQA dpx 21_fossoild6 car not ready in 36 ticks; removed, next square   (x2)
ZEDQA dpx 21_fossoild6 design=d6 rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=CHEVALIER D6 livery= make=CHEVALIER model=D6 unit=CHEVALIER - UNIT 80 hits=19 screen=3840x2160
ZEDQA dpx 22_wreckednyala could not enter Base.CarNormalSmashedFront (enter=false seat0 installed=false)
ZEDQA dpx 23_meadesheriff design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=MEADE SHERIFF DASH ELITE livery=MEADE SHERIFF make=DASH model=ELITE unit=SHERIFF - UNIT 35 hits=19 screen=3840x2160
ZEDQA dpx 24_lcpd design=police rect=1120,1804,1600,356 k=2 running=true radio=true/ham heat=true lights=true name=LCPD CHEVALIER NYALA livery=LCPD make=CHEVALIER model=NYALA unit=LCPD - UNIT 35 hits=19 screen=3840x2160
ZEDQA dpx DONE
```

### 13. zedqa_exinfo.lua (`ZEDQA ex`) - PASS, 6 s

- go 16243 at 23:22:09
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #13 ok=true
ZEDQA ex ok squats desc is vanilla's tooltip
ZEDQA ex ok squats legs line
ZEDQA ex ok pushups: arms line only (chest has none)
ZEDQA ex ok burpees: legs and arms
ZEDQA ex ok situp abs line
ZEDQA ex ok regularity in 0..1
ZEDQA ex regularity squats 0
ZEDQA ex ok barbell curl without a barbell warns '(Requires Barbell)'
ZEDQA ex ok squats has no item warning
ZEDQA ex ok with a barbell the warning clears
ZEDQA ex ok unknown exercise gives nil
ZEDQA ex ok sitonground shows Stand up before exercising
ZEDQA ex ok reason gone after standing
ZEDQA ex tab health true | shown squats | reserved 434.44921875 used 290.85546875 w 329
ZEDQA ex ok block follows the focused pill (squats)
ZEDQA ex ok room reserved
ZEDQA ex ok block follows the focused pill (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex ok time buttons keep the last started exercise
ZEDQA ex ok time buttons start nothing and change no choice
ZEDQA ex ok block follows the focused pill (burpees)
ZEDQA ex DONE
```

### 14. zedqa_charinfo.lua (`ZEDQA ci`) - PASS, 9 s

- go 16244 at 23:22:18

```text
[ZeD.QA] windows reset (R)
ZEDQA ci start
[ZeD.QA] run #14 ok=true
ZEDQA ci ZeD's Character window hook on: true | Mini Health Panel on: false
ZEDQA ci PASS the game's TOGGLE_HEALTH_PANEL key opens ZeD's health tab (tab health, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_SKILL_PANEL key opens ZeD's skills tab (tab skills, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_INFO_PANEL key opens ZeD's identity tab (tab identity, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_CLOTHING_PROTECTION_PANEL key opens ZeD's equip tab (tab equip, the game's window shown false)
ZEDQA ci PASS the same key again folds the tab (tab loot)
ZEDQA ci Mini Health Panel is off: its click is not checked
ZEDQA ci PASS with the windows shut, the click opens them on Health
ZEDQA ci PASS the windows are still
ZEDQA ci all checks passed
ZEDQA ci DONE
```

### 15. zedqa_equipdrag.lua (`ZEDQA eqd`) - PASS, 12 s

- go 16245 at 23:22:31
- screenshots: zqa_eqd_1.png, zqa_eqd_2.png, zqa_eqd_3.png, zqa_eqd_4.png

```text
[ZeD.QA] windows reset (R)
ZEDQA eqd start
[ZeD.QA] run #15 ok=true
ZEDQA eqd list slots {HAT,OUT,INR,GLV,PNT,SOC,BOT,PRI,BLT}
ZEDQA eqd worn {base:belt=Belt2,base:hat=Hat_BaseballCapBlue,base:tshirt=Tshirt_DefaultTEXTURE_TINT,base:hands=Gloves_LeatherGlovesBlack,base:socks=Socks_Heavy,base:shoes=Shoes_ArmyBoots,base:pants=Trousers_Denim,base:jacket=Jacket_Varsity} cap Clothing{ clothingItemName="Hat_BaseballCapBlue" } jacket Clothing{ clothingItemName="Jacket_Varsity" } pri Base.Hammer:zombie.inventory.types.HandWeapon@537b30b6 | tab equip listExp true view list
ZEDQA eqd PASS rows for cap, jacket, hammer
ZEDQA eqd PASS press waits (pending, nothing selected yet)
ZEDQA eqd PASS click selects the row | HAT
ZEDQA eqd PASS moved press is the drag
ZEDQA eqd PASS ISMouseDrag carries the item
ZEDQA eqd PASS draggedItem names it
ZEDQA eqd PASS release on the Equip tab: drag over, nothing queued, cap still worn | queue 0
ZEDQA eqd PASS drag started on the jacket
ZEDQA eqd PASS right press cancels it
ZEDQA eqd doll slots {doll:head,doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet,doll:main,doll:belt1}
ZEDQA eqd PASS doll slots for the cap and the hammer
ZEDQA eqd PASS doll click selects the slot | doll:head
ZEDQA eqd PASS doll slot drags
ZEDQA eqd PASS doll drag cancelled
ZEDQA eqd PASS cap release queued vanilla's transfer | queue 1
ZEDQA eqd PASS cap in the bag and off the head
ZEDQA eqd PASS hammer release queued | queue 1
ZEDQA eqd PASS hammer in the bag and out of the hand
ZEDQA eqd PASS jacket onto its own container does nothing | queue 0
ZEDQA eqd PASS floor release queued vanilla's drop | queue 2
ZEDQA eqd PASS jacket on the floor and off the body
ZEDQA eqd PASS jacket picked back up
ZEDQA eqd DONE
```

### 16. zedqa_cazio_light.lua (`ZEDQA czl`) - PASS, 33 s

- go 16246 at 23:22:46
- screenshots: zqa_cl_day_DigitalBlack.png, zqa_cl_daylit_DigitalBlack.png, zqa_cl_night_DigitalBlack.png, zqa_cl_nightlit_DigitalBlack.png, zqa_cl_day_DigitalDress.png, zqa_cl_daylit_DigitalDress.png, zqa_cl_night_DigitalDress.png, zqa_cl_nightlit_DigitalDress.png, zqa_cl_day_ClassicBlack.png, zqa_cl_daylit_ClassicBlack.png, zqa_cl_night_ClassicBlack.png, zqa_cl_nightlit_ClassicBlack.png, zqa_cl_day_ClassicGold.png, zqa_cl_daylit_ClassicGold.png, zqa_cl_night_ClassicGold.png, zqa_cl_nightlit_ClassicGold.png, zqa_cl_belt_night.png, zqa_cl_belt_nightlit.png, zqa_cl_belt_day.png, zqa_cl_belt_daylit.png

```text
[ZeD.QA] windows reset (R)
ZEDQA czl start
[ZeD.QA] run #16 ok=true
ZEDQA czl own watch nil at base:leftwrist
ZEDQA czl DigitalBlack plate digital_black light at 0,76 lit=false bulb=false dark=false
ZEDQA czl DigitalBlack day pressed: lit=false bulb=true dark=false
ZEDQA czl DigitalBlack night: lit=false bulb=false dark=true
ZEDQA czl DigitalBlack night pressed: lit=false bulb=true dark=true
ZEDQA czl DigitalDress plate digital_gold light at 0,76 lit=false bulb=false dark=false
ZEDQA czl DigitalDress day pressed: lit=false bulb=true dark=false
ZEDQA czl DigitalDress night: lit=false bulb=false dark=true
ZEDQA czl DigitalDress night pressed: lit=false bulb=true dark=true
ZEDQA czl ClassicBlack plate classic_black light at 24,160 lit=false bulb=false dark=false
ZEDQA czl ClassicBlack day pressed: lit=false bulb=true dark=false
ZEDQA czl ClassicBlack night: lit=false bulb=false dark=true
ZEDQA czl ClassicBlack night pressed: lit=false bulb=true dark=true
ZEDQA czl ClassicGold plate classic_gold light at 24,160 lit=false bulb=false dark=false
ZEDQA czl ClassicGold day pressed: lit=false bulb=true dark=false
ZEDQA czl ClassicGold night: lit=false bulb=false dark=true
ZEDQA czl ClassicGold night pressed: lit=false bulb=true dark=true
ZEDQA czl timer pressed at 1793341390033
ZEDQA czl light out after 3011 ms; lit=false bulb=false dark=true
ZEDQA czl Expensive light control false
ZEDQA czl Expensive after a stray light press: lit=false bulb=false dark=true
ZEDQA czl belt watch box 1
ZEDQA czl belt mini after Y: lit=true night=true dark=false
ZEDQA czl restored own watch nil
ZEDQA czl DONE
```

### 17. zedqa_dashnight.lua (`ZEDQA dnt`) - PASS, 100 s

- go 16247 at 23:23:22
- screenshots: zqa_dashnight_wagon_real.png, zqa_dashnight_wagon_day.png, zqa_dashnight_wagon_dusk.png, zqa_dashnight_wagon_night.png, zqa_dashnight_wagon_nightoff.png, zqa_dashnight_wagon_real_noon.png, zqa_dashnight_wagon_real_back_on.png, zqa_dashnight_wagon_real_back_off.png, zqa_dashnight_nyala_real.png, zqa_dashnight_nyala_day.png, zqa_dashnight_nyala_dusk.png, zqa_dashnight_nyala_night.png, zqa_dashnight_nyala_nightoff.png, zqa_dashnight_dashelite_real.png, zqa_dashnight_dashelite_day.png, zqa_dashnight_dashelite_dusk.png, zqa_dashnight_dashelite_night.png, zqa_dashnight_dashelite_nightoff.png, zqa_dashnight_luxury_real.png, zqa_dashnight_luxury_day.png, zqa_dashnight_luxury_dusk.png, zqa_dashnight_luxury_night.png, zqa_dashnight_luxury_nightoff.png, zqa_dashnight_ambulance_real.png, zqa_dashnight_ambulance_day.png, zqa_dashnight_ambulance_dusk.png, zqa_dashnight_ambulance_night.png, zqa_dashnight_ambulance_nightoff.png, zqa_dashnight_race_real.png, zqa_dashnight_race_day.png, zqa_dashnight_race_dusk.png, zqa_dashnight_race_night.png, zqa_dashnight_race_nightoff.png, zqa_dashnight_d6_real.png, zqa_dashnight_d6_day.png, zqa_dashnight_d6_dusk.png, zqa_dashnight_d6_night.png, zqa_dashnight_d6_nightoff.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #17 ok=true
ZEDQA dnt wagon real design=wagon lux=0.000 smooth=0.038 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.22
ZEDQA dnt wagon day design=wagon lux=0.000 smooth=0.021 n8=0 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.22
ZEDQA dnt wagon dusk design=wagon lux=0.000 smooth=0.011 n8=4 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.22
ZEDQA dnt wagon night design=wagon lux=0.000 smooth=0.006 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.23
ZEDQA dnt wagon nightoff design=wagon lux=0.000 smooth=0.003 n8=8 lit=false over=dash_wagon_dark lights=true dashLit=true k=2 hour=13.23
ZEDQA dnt wagon real_noon design=wagon lux=0.000 smooth=0.000 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.02
ZEDQA dnt wagon real_back_on design=wagon lux=0.000 smooth=0.000 n8=8 lit=true over=dash_wagon_night lights=true dashLit=true k=2 hour=13.22
ZEDQA dnt wagon real_back_off design=wagon lux=0.000 smooth=0.000 n8=8 lit=false over=dash_wagon_dark lights=false dashLit=false k=2 hour=13.23
ZEDQA dnt nyala car not ready (square=true chunk=true physics=false dist=5.5); removed, next square
ZEDQA dnt nyala car not ready (square=true chunk=true physics=false dist=7.7); removed, next square
ZEDQA dnt nyala real design=nyala lux=1.000 smooth=0.938 n8=0 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=13.25
ZEDQA dnt nyala day design=nyala lux=1.000 smooth=0.968 n8=0 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=13.25
ZEDQA dnt nyala dusk design=nyala lux=1.000 smooth=0.982 n8=4 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=13.25
ZEDQA dnt nyala night design=nyala lux=1.000 smooth=0.990 n8=8 lit=true over=dash_nyala_night lights=true dashLit=true k=2 hour=13.26
ZEDQA dnt nyala nightoff design=nyala lux=1.000 smooth=0.995 n8=8 lit=false over=dash_nyala_dark lights=true dashLit=true k=2 hour=13.26
ZEDQA dnt dashelite real design=dashelite lux=1.000 smooth=1.000 n8=0 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=13.28
ZEDQA dnt dashelite day design=dashelite lux=1.000 smooth=1.000 n8=0 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=13.28
ZEDQA dnt dashelite dusk design=dashelite lux=1.000 smooth=1.000 n8=4 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=13.28
ZEDQA dnt dashelite night design=dashelite lux=1.000 smooth=1.000 n8=8 lit=true over=dash_dashelite_night lights=true dashLit=true k=2 hour=13.29
ZEDQA dnt dashelite nightoff design=dashelite lux=1.000 smooth=1.000 n8=8 lit=false over=dash_dashelite_dark lights=true dashLit=true k=2 hour=13.29
ZEDQA dnt luxury real design=luxury lux=1.000 smooth=1.000 n8=0 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=13.31
ZEDQA dnt luxury day design=luxury lux=1.000 smooth=1.000 n8=0 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=13.31
ZEDQA dnt luxury dusk design=luxury lux=1.000 smooth=1.000 n8=4 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=13.31
ZEDQA dnt luxury night design=luxury lux=1.000 smooth=1.000 n8=8 lit=true over=dash_luxury_night lights=true dashLit=true k=2 hour=13.31
ZEDQA dnt luxury nightoff design=luxury lux=1.000 smooth=1.000 n8=8 lit=false over=dash_luxury_dark lights=true dashLit=true k=2 hour=13.32
ZEDQA dnt ambulance car not ready (square=true chunk=true physics=false dist=6.0); removed, next square
ZEDQA dnt ambulance car not ready (square=true chunk=true physics=false dist=7.5); removed, next square
ZEDQA dnt ambulance real design=ambulance lux=1.000 smooth=1.000 n8=0 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=13.34
ZEDQA dnt ambulance day design=ambulance lux=1.000 smooth=1.000 n8=0 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=13.34
ZEDQA dnt ambulance dusk design=ambulance lux=1.000 smooth=1.000 n8=4 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=13.34
ZEDQA dnt ambulance night design=ambulance lux=1.000 smooth=1.000 n8=8 lit=true over=dash_ambulance_night lights=true dashLit=true k=2 hour=13.34
ZEDQA dnt ambulance nightoff design=ambulance lux=1.000 smooth=1.000 n8=8 lit=false over=dash_ambulance_dark lights=true dashLit=true k=2 hour=13.35
ERROR: General f:59374 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:59377 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA dnt race real design=race lux=1.000 smooth=1.000 n8=0 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=13.37
ZEDQA dnt race day design=race lux=1.000 smooth=1.000 n8=0 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=13.37
ZEDQA dnt race dusk design=race lux=1.000 smooth=1.000 n8=4 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=13.37
ZEDQA dnt race night design=race lux=1.000 smooth=1.000 n8=8 lit=true over=dash_race_night lights=true dashLit=true k=2 hour=13.38
ZEDQA dnt race nightoff design=race lux=1.000 smooth=1.000 n8=8 lit=false over=dash_race_dark lights=true dashLit=true k=2 hour=13.38
ZEDQA dnt d6 real design=d6 lux=1.000 smooth=1.000 n8=0 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=13.40
ZEDQA dnt d6 day design=d6 lux=1.000 smooth=1.000 n8=0 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=13.40
ZEDQA dnt d6 dusk design=d6 lux=1.000 smooth=1.000 n8=4 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=13.40
ZEDQA dnt d6 night design=d6 lux=1.000 smooth=1.000 n8=8 lit=true over=dash_d6_night lights=true dashLit=true k=2 hour=13.41
ZEDQA dnt d6 nightoff design=d6 lux=1.000 smooth=1.000 n8=8 lit=false over=dash_d6_dark lights=true dashLit=true k=2 hour=13.41
ZEDQA dnt DONE
```

### 18. zedqa_dash_green.lua (`ZEDQA dgr`) - FAIL, 32 s

- go 16248 at 23:25:05
- 1 Java exception(s) in the log
- no DONE
- the game dropped to the main menu during this script

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #18 ok=true
ERROR: General f:61757> IngameState.updateInternal> Exception thrown
    java.lang.NullPointerException: Cannot invoke "zombie.core.physics.CarController.update()" because "this.physics" is null at BaseVehicle.updatePhysics(BaseVehicle.java:4974).
[ZeD.QA] bridge armed (main menu, poll every 30 ticks)
[ZeD.QA] autoload: continuing the latest save
```

### 19. zedqa_dash_keys_edge.lua (`ZEDQA dke`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 20. zedqa_dash_brands.lua (`ZEDQA dbr`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 21. zedqa_testlang.lua (`ZEDQA tlang`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 22. zedqa_safemode.lua (`ZEDQA safe`) - SKIP, not run

- not run: the game dropped to the main menu during this script

### 23. zedqa_soak.lua (`ZEDQA soak`) - SKIP, not run

- not run: the game dropped to the main menu during this script

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    1x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    2x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    2x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    2x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
