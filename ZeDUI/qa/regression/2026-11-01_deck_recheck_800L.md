# ZeD-UI regression - 2026-11-01 13:10 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-01 13:10:18 |
| Finished | 2026-11-01 13:17:15 (6 min 56 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\deck_recheck_large_manifest.txt (12 scripts) |
| Result | **11/12 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 17948 to 17961 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 17960, 17961)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_textlarge.lua | txl | PASS | 1 |  |  |
| 3 | zedqa_two_widths.lua | tww | WARN | 72 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png | 2 ERR line(s) |
| 4 | zedqa_doll_v4.lua | dollv4 | PASS | 21 | zqa_dollv4_1280x800_wide.png, zqa_dollv4_1280x800_dpad.png, zqa_dollv4_1280x800_wide_pads.png, zqa_dollv4_1280x800_card.png, zqa_dollv4_1280x800_narrow.png, zqa_dollv4_1280x800_short.png |  |
| 5 | zedqa_mapnotes.lua | mnote | PASS | 3 | zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png |  |
| 6 | zedqa_twoway.lua | tw | PASS | 21 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 7 | zedqa_rtv.lua | rtv | PASS | 37 | zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_simple_card.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png |  |
| 8 | zedqa_appliances.lua | ap | PASS | 5 | zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png |  |
| 9 | zedqa_plates_336.lua | p336 | PASS | 54 | zqa_p336_scale075_oven.png, zqa_p336_scale075_microwave.png, zqa_p336_scale075_chrome.png, zqa_p336_scale075_generator.png, zqa_p336_scale075_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png |  |
| 10 | zedqa_wheel_icons.lua | wi | PASS | 17 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png |  |
| 11 | zedqa_world_pad_take.lua | wpt | PASS | 53 |  |  |
| 12 | zedqa_probe_skills_down.lua | pskd | PASS | 7 | zqa_pskd_pass2_large.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 17948 at 13:11:17

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 964,13078,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:415 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_textlarge.lua (`ZEDQA txl`) - PASS, 1 s

- go 17949 at 13:11:26

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA txl size large
ZEDQA txl DONE
```

### 3. zedqa_two_widths.lua (`ZEDQA tww`) - WARN, 72 s

- go 17950 at 13:11:30
- 2 ERR line(s)
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #3 ok=true
ZEDQA tww screen 1280x800, root 0.75, half card 190 px, full card 414 px
ZEDQA tww to the deep run's home, 10608,11151
ZEDQA tww the pair at the start: Character 253,0 383x362, World 644,0 383x362
ZEDQA tww PASS the pair starts apart
ZEDQA tww 13 tab cases
ZEDQA tww Character equip: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character equip: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character equip: it is the full card (full)
ZEDQA tww PASS Character equip: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character equip: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character equip: both windows are on the screen
ZEDQA tww FAIL Character equip: closed, the window is back where and as wide as it was (253,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character equip: closed, the other window is where it was
ZEDQA tww Character health: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character health: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character health: it is the full card (full)
ZEDQA tww PASS Character health: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character health: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character health: both windows are on the screen
ZEDQA tww PASS Character health: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character health: closed, the other window is where it was
ZEDQA tww Character thermal: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character thermal: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character thermal: it is the full card (full)
ZEDQA tww PASS Character thermal: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character thermal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character thermal: both windows are on the screen
ZEDQA tww PASS Character thermal: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character thermal: closed, the other window is where it was
ZEDQA tww Character identity: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character identity: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character identity: it is the full card (full)
ZEDQA tww PASS Character identity: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character identity: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character identity: both windows are on the screen
ZEDQA tww PASS Character identity: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character identity: closed, the other window is where it was
ZEDQA tww Character journal: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character journal: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character journal: it is the full card (full)
ZEDQA tww PASS Character journal: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character journal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character journal: both windows are on the screen
ZEDQA tww PASS Character journal: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character journal: closed, the other window is where it was
ZEDQA tww Character skills: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character skills: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character skills: it is the full card (full)
ZEDQA tww PASS Character skills: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character skills: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character skills: both windows are on the screen
ZEDQA tww PASS Character skills: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character skills: closed, the other window is where it was
ZEDQA tww World craft: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World craft: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World craft: it is the full card (full)
ZEDQA tww PASS World craft: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World craft: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World craft: both windows are on the screen
ZEDQA tww PASS World craft: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World craft: closed, the other window is where it was
ZEDQA tww World build: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World build: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World build: it is the full card (full)
ZEDQA tww PASS World build: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World build: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World build: both windows are on the screen
ZEDQA tww PASS World build: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World build: closed, the other window is where it was
ZEDQA tww World furniture: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World furniture: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World furniture: it is the full card (full)
ZEDQA tww PASS World furniture: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World furniture: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World furniture: both windows are on the screen
ZEDQA tww PASS World furniture: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World furniture: closed, the other window is where it was
ZEDQA tww World maps: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World maps: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World maps: it is the full card (full)
ZEDQA tww PASS World maps: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World maps: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World maps: both windows are on the screen
ZEDQA tww PASS World maps: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World maps: closed, the other window is where it was
ZEDQA tww World forage: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World forage: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World forage: it is the full card (full)
ZEDQA tww PASS World forage: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World forage: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World forage: both windows are on the screen
ZEDQA tww PASS World forage: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World forage: closed, the other window is where it was
ZEDQA tww World animals: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World animals: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World animals: it is the full card (full)
ZEDQA tww PASS World animals: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World animals: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World animals: both windows are on the screen
ZEDQA tww PASS World animals: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World animals: closed, the other window is where it was
ZEDQA tww World vehicle: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World vehicle: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World vehicle: it is the full card (full)
ZEDQA tww PASS World vehicle: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World vehicle: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World vehicle: both windows are on the screen
ZEDQA tww PASS World vehicle: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World vehicle: closed, the other window is where it was
ZEDQA tww an oven placed: true
ZEDQA tww a generator placed: true
ZEDQA tww a ham set placed: true
ZEDQA tww 26 more cases
ZEDQA tww Character Equip to-do: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character Equip to-do: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character Equip to-do: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Equip to-do: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Equip to-do: both windows are on the screen
ZEDQA tww PASS Character Equip to-do: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Equip to-do: closed, the other window is where it was
ZEDQA tww Character Journal Loadouts page: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character Journal Loadouts page: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character Journal Loadouts page: it is the full card (full)
ZEDQA tww PASS Character Journal Loadouts page: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Journal Loadouts page: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal Loadouts page: both windows are on the screen
ZEDQA tww PASS Character Journal Loadouts page: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Journal Loadouts page: closed, the other window is where it was
ZEDQA tww Character Journal page 1: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character Journal page 1: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character Journal page 1: it is the full card (full)
ZEDQA tww PASS Character Journal page 1: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Journal page 1: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 1: both windows are on the screen
ZEDQA tww PASS Character Journal page 1: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Journal page 1: closed, the other window is where it was
ZEDQA tww Character Journal page 2: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character Journal page 2: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character Journal page 2: it is the full card (full)
ZEDQA tww PASS Character Journal page 2: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Journal page 2: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 2: both windows are on the screen
ZEDQA tww PASS Character Journal page 2: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Journal page 2: closed, the other window is where it was
ZEDQA tww Character Journal page 3: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character Journal page 3: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character Journal page 3: it is the full card (full)
ZEDQA tww PASS Character Journal page 3: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Journal page 3: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 3: both windows are on the screen
ZEDQA tww PASS Character Journal page 3: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Journal page 3: closed, the other window is where it was
ZEDQA tww Character Journal page 4: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character Journal page 4: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character Journal page 4: it is the full card (full)
ZEDQA tww PASS Character Journal page 4: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Journal page 4: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 4: both windows are on the screen
ZEDQA tww PASS Character Journal page 4: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Journal page 4: closed, the other window is where it was
ZEDQA tww Character Journal page 5: drawer 414 px = full | Character 0,0 640x362 | World 644,0 383x362
ZEDQA tww PASS Character Journal page 5: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS Character Journal page 5: it is the full card (full)
ZEDQA tww PASS Character Journal page 5: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Journal page 5: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 5: both windows are on the screen
ZEDQA tww PASS Character Journal page 5: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Journal page 5: closed, the other window is where it was
ZEDQA tww World item card: drawer 190 px = half | Character 257,0 383x362 | World 644,0 573x362
ZEDQA tww PASS World item card: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS World item card: it is the half card (half)
ZEDQA tww PASS World item card: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World item card: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS World item card: both windows are on the screen
ZEDQA tww PASS World item card: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World item card: closed, the other window is where it was
ZEDQA tww Character item card: drawer 190 px = half | Character 67,0 573x362 | World 644,0 383x362
ZEDQA tww PASS Character item card: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS Character item card: it is the half card (half)
ZEDQA tww PASS Character item card: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character item card: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character item card: both windows are on the screen
ZEDQA tww PASS Character item card: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character item card: closed, the other window is where it was
ZEDQA tww World object card fluid: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World object card fluid: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World object card fluid: it is the full card (full)
ZEDQA tww PASS World object card fluid: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World object card fluid: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World object card fluid: both windows are on the screen
ZEDQA tww PASS World object card fluid: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World object card fluid: closed, the other window is where it was
ZEDQA tww World object card generator: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World object card generator: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World object card generator: it is the full card (full)
ZEDQA tww PASS World object card generator: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World object card generator: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World object card generator: both windows are on the screen
ZEDQA tww PASS World object card generator: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World object card generator: closed, the other window is where it was
ZEDQA tww World object card place3d: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World object card place3d: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World object card place3d: it is the full card (full)
ZEDQA tww PASS World object card place3d: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World object card place3d: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World object card place3d: both windows are on the screen
ZEDQA tww PASS World object card place3d: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World object card place3d: closed, the other window is where it was
ZEDQA tww World Craft at an oven: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World Craft at an oven: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World Craft at an oven: it is the full card (full)
ZEDQA tww PASS World Craft at an oven: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World Craft at an oven: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Craft at an oven: both windows are on the screen
ZEDQA tww PASS World Craft at an oven: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World Craft at an oven: closed, the other window is where it was
ZEDQA tww World Craft (no station): drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World Craft (no station): the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World Craft (no station): it is the full card (full)
ZEDQA tww PASS World Craft (no station): the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World Craft (no station): the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Craft (no station): both windows are on the screen
ZEDQA tww PASS World Craft (no station): closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World Craft (no station): closed, the other window is where it was
ZEDQA tww Character Radio (a walkie): drawer 190 px = half | Character 67,0 573x362 | World 644,0 383x362
ZEDQA tww PASS Character Radio (a walkie): the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS Character Radio (a walkie): it is the half card (half)
ZEDQA tww PASS Character Radio (a walkie): the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS Character Radio (a walkie): the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Radio (a walkie): both windows are on the screen
ZEDQA tww PASS Character Radio (a walkie): closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS Character Radio (a walkie): closed, the other window is where it was
ZEDQA tww World Radio (a ham set): drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World Radio (a ham set): the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World Radio (a ham set): the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World Radio (a ham set): the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Radio (a ham set): both windows are on the screen
ZEDQA tww PASS World Radio (a ham set): closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World Radio (a ham set): closed, the other window is where it was
ZEDQA tww World Maps: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World Maps: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World Maps: it is the full card (full)
ZEDQA tww PASS World Maps: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World Maps: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Maps: both windows are on the screen
ZEDQA tww PASS World Maps: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World Maps: closed, the other window is where it was
ZEDQA tww World Maps pop-out: drawer 414 px = full | Character 257,0 383x362 | World 640,0 640x362
ZEDQA tww PASS World Maps pop-out: the drawer is the half card or the full card (414 px; half 190, full 414)
ZEDQA tww PASS World Maps pop-out: it is the full card (full)
ZEDQA tww PASS World Maps pop-out: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS World Maps pop-out: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Maps pop-out: both windows are on the screen
ZEDQA tww the pop-out 179,88 921x624: over the Character window true, over the World window true (it is a window of its own, centred)
ZEDQA tww PASS World Maps pop-out: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS World Maps pop-out: closed, the other window is where it was
ZEDQA tww 15 held-in cases
ZEDQA tww held in: Character equip: drawer 190 px = half | Character 147,0 493x362 | World 644,0 383x362
ZEDQA tww PASS held in: Character equip: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: Character equip: it is the half card (half)
ZEDQA tww PASS held in: Character equip: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: Character equip: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character equip: both windows are on the screen
ZEDQA tww PASS held in: Character equip: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: Character equip: closed, the other window is where it was
ZEDQA tww held in: Character health: drawer 190 px = half | Character 147,0 493x362 | World 644,0 383x362
ZEDQA tww PASS held in: Character health: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: Character health: it is the half card (half)
ZEDQA tww PASS held in: Character health: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: Character health: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character health: both windows are on the screen
ZEDQA tww PASS held in: Character health: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: Character health: closed, the other window is where it was
ZEDQA tww held in: Character thermal: drawer 190 px = half | Character 147,0 493x362 | World 644,0 383x362
ZEDQA tww PASS held in: Character thermal: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: Character thermal: it is the half card (half)
ZEDQA tww PASS held in: Character thermal: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: Character thermal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character thermal: both windows are on the screen
ZEDQA tww PASS held in: Character thermal: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: Character thermal: closed, the other window is where it was
ZEDQA tww held in: Character identity: drawer 190 px = half | Character 147,0 493x362 | World 644,0 383x362
ZEDQA tww PASS held in: Character identity: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: Character identity: it is the half card (half)
ZEDQA tww PASS held in: Character identity: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: Character identity: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character identity: both windows are on the screen
ZEDQA tww PASS held in: Character identity: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: Character identity: closed, the other window is where it was
ZEDQA tww held in: Character journal: drawer 190 px = half | Character 147,0 493x362 | World 644,0 383x362
ZEDQA tww PASS held in: Character journal: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: Character journal: it is the half card (half)
ZEDQA tww PASS held in: Character journal: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: Character journal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character journal: both windows are on the screen
ZEDQA tww PASS held in: Character journal: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: Character journal: closed, the other window is where it was
ZEDQA tww held in: Character skills: drawer 190 px = half | Character 147,0 493x362 | World 644,0 383x362
ZEDQA tww PASS held in: Character skills: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: Character skills: it is the half card (half)
ZEDQA tww PASS held in: Character skills: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: Character skills: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character skills: both windows are on the screen
ZEDQA tww PASS held in: Character skills: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: Character skills: closed, the other window is where it was
ZEDQA tww held in: Character radio: drawer 190 px = half | Character 147,0 493x362 | World 644,0 383x362
ZEDQA tww PASS held in: Character radio: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: Character radio: it is the half card (half)
ZEDQA tww PASS held in: Character radio: the other window did not move or change size (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: Character radio: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character radio: both windows are on the screen
ZEDQA tww PASS held in: Character radio: closed, the window is back where and as wide as it was (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: Character radio: closed, the other window is where it was
ZEDQA tww held in: World craft: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
ZEDQA tww PASS held in: World craft: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: World craft: it is the half card (half)
ZEDQA tww PASS held in: World craft: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World craft: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World craft: both windows are on the screen
ZEDQA tww PASS held in: World craft: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World craft: closed, the other window is where it was
ZEDQA tww held in: World build: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
ZEDQA tww PASS held in: World build: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: World build: it is the half card (half)
ZEDQA tww PASS held in: World build: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World build: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World build: both windows are on the screen
ZEDQA tww PASS held in: World build: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World build: closed, the other window is where it was
ZEDQA tww held in: World furniture: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
ZEDQA tww PASS held in: World furniture: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: World furniture: it is the half card (half)
ZEDQA tww PASS held in: World furniture: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World furniture: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World furniture: both windows are on the screen
ZEDQA tww PASS held in: World furniture: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World furniture: closed, the other window is where it was
ZEDQA tww held in: World maps: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
ZEDQA tww PASS held in: World maps: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: World maps: it is the half card (half)
ZEDQA tww PASS held in: World maps: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World maps: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World maps: both windows are on the screen
ZEDQA tww PASS held in: World maps: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World maps: closed, the other window is where it was
ZEDQA tww held in: World forage: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
ZEDQA tww PASS held in: World forage: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: World forage: it is the half card (half)
ZEDQA tww PASS held in: World forage: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World forage: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World forage: both windows are on the screen
ZEDQA tww PASS held in: World forage: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World forage: closed, the other window is where it was
ZEDQA tww held in: World animals: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
ZEDQA tww PASS held in: World animals: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: World animals: it is the half card (half)
ZEDQA tww PASS held in: World animals: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World animals: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World animals: both windows are on the screen
ZEDQA tww PASS held in: World animals: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World animals: closed, the other window is where it was
ZEDQA tww held in: World radio: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
ZEDQA tww PASS held in: World radio: the drawer is the half card or the full card (190 px; half 190, full 414)
ZEDQA tww PASS held in: World radio: it is the half card (half)
ZEDQA tww PASS held in: World radio: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World radio: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World radio: both windows are on the screen
ZEDQA tww PASS held in: World radio: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World radio: closed, the other window is where it was
ZEDQA tww held in: World vehicle: drawer 190 px = half | Character 257,0 383x362 | World 644,0 493x362
    LOG  : Lua          f:8506> ZEDQA tww PASS held in: World vehicle: the drawer is the half card or the full card (190 px; half 190, full 414)
    OG  : Lua          f:8506> ZEDQA tww PASS held in: World vehicle: it is the half card (half)
ZEDQA tww PASS held in: World vehicle: the other window did not move or change size (257,0 383x362 -> 257,0 383x362)
ZEDQA tww PASS held in: World vehicle: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World vehicle: both windows are on the screen
ZEDQA tww PASS held in: World vehicle: closed, the window is back where and as wide as it was (644,0 383x362 -> 644,0 383x362)
ZEDQA tww PASS held in: World vehicle: closed, the other window is where it was
ERROR: General f:8618 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:8629 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA tww FAIL after the whole run both windows are where and as big as they were (253,0 383x362 / 644,0 383x362 -> 257,0 383x362 / 644,0 383x362)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card laundry, World object card lock, World object card plant, World object card track, World object card trough
ZEDQA tww 2 FAILED
ZEDQA tww DONE
```

### 4. zedqa_doll_v4.lua (`ZEDQA dollv4`) - PASS, 21 s

- go 17951 at 13:12:46
- screenshots: zqa_dollv4_1280x800_wide.png, zqa_dollv4_1280x800_dpad.png, zqa_dollv4_1280x800_wide_pads.png, zqa_dollv4_1280x800_card.png, zqa_dollv4_1280x800_narrow.png, zqa_dollv4_1280x800_short.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dollv4 start
[ZeD.QA] run #4 ok=true
ZEDQA dollv4 round 1: wearing 21 of 21
ZEDQA dollv4 PASS 38 small slots defined | 38
ZEDQA dollv4 PASS wide: bands show | drawer 414px = 480 units, screen 1280x800
ZEDQA dollv4 PASS wide: 49 slot boxes (11 big + 38 small) | 49
ZEDQA dollv4 PASS wide: no slot overlaps another
ZEDQA dollv4 PASS wide: every box inside the drawer's width | 414
ZEDQA dollv4 PASS wide: the drawer is no wider than the full card (480 units) | 480.3 units
ZEDQA dollv4 PASS wide: a small slot is 14 units or more on screen | 13.9 units
ZEDQA dollv4 PASS wide: no leader lines | 0 lines
ZEDQA dollv4 PASS wide: Back at the top right above Belt, Arms on the left with Head | 289,42 132 289,190
ZEDQA dollv4 PASS every group name and place name has its words |
ZEDQA dollv4 PASS round 1 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 1 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 1 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 PASS belly button ring, air tank, tail in their small slots
ZEDQA dollv4 empties 25, slots with things 27
ZEDQA dollv4 PASS charTabContent zone exists with the doll's stops | 82
ZEDQA dollv4 PASS Left from Neck steps into the left band | doll:padsport
ZEDQA dollv4 PASS Right from the band's inner edge returns to a big slot | doll:neck
ZEDQA dollv4 PASS Right from Belt steps into the right band | doll:fpfront
ZEDQA dollv4 PASS Left from the right band's inner edge returns to a big slot | doll:belt
ZEDQA dollv4 PASS the doll's moves reach all 38 small slots | 38 missed
ZEDQA dollv4 PASS and all 11 big slots (Up / Down in a column are the cone's) | 11 missed
ZEDQA dollv4 PASS the outer edge of each band row leaves the doll (18 rows)
ZEDQA dollv4 dispatch Right from belt -> equipslot:doll:fpfront
ZEDQA dollv4 then Down -> equipslot:doll:ammo
ZEDQA dollv4 dispatch Left from the left band's outer edge -> tab:equip
ZEDQA dollv4 PASS the real Left at the outer edge does not land on another doll slot | tab:equip
ZEDQA dollv4 round 2: wearing 1 of 1
ZEDQA dollv4 PASS round 2 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS the sport pads worn on top show in their small slot
ZEDQA dollv4 PASS the air tank is gone from its slot
ZEDQA dollv4 PASS a second layer shows as a count (2) | 2
ZEDQA dollv4 PASS pad stop for the filled small slot
ZEDQA dollv4 PASS A opens the small slot's card (outermost first) | doll:padsport item Shoulderpads_FootballOnTop layer 1/2
ZEDQA dollv4 PASS its outermost layer is the pair worn on top | Shoulderpads_FootballOnTop
ZEDQA dollv4 PASS Inner steps to layer 2 | 2
ZEDQA dollv4 round 3: wearing 1 of 1
ZEDQA dollv4 PASS round 3 wide: every worn thing lands in its small slot (20 on) |
ZEDQA dollv4 PASS round 3 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 3 folded (data): every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 round 4: wearing 2 of 2
ZEDQA dollv4 PASS round 4 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 4 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 4 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 round 5: wearing 1 of 1
ZEDQA dollv4 PASS round 5 wide: every worn thing lands in its small slot (20 on) |
ZEDQA dollv4 PASS round 5 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 5 folded (data): every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS a cap dropped on Head is taken | rect 79,32 31x31 clip 0,32 402x288 | loc base:hat
ZEDQA dollv4 PASS a cap dropped on a small slot that is not its place is refused
ZEDQA dollv4 PASS a ring dropped on the wrong small slot is refused
ZEDQA dollv4 PASS a ring dropped on its slot is taken | rect 1,281 12x12 clip 0,32 402x288
ZEDQA dollv4 PASS the ring was put on (vanilla's wear action ran)
ZEDQA dollv4 PASS the cap was put on
ZEDQA dollv4 PASS narrow: bands folded | drawer 190px = 220 units, screen 1280x800
ZEDQA dollv4 PASS narrow: 11 big slot boxes, no small ones | 11
ZEDQA dollv4 PASS narrow: no slot overlaps another
ZEDQA dollv4 PASS narrow: every box inside the drawer's width | 190
ZEDQA dollv4 PASS narrow: the drawer is no wider than the full card (480 units) | 220.4 units
ZEDQA dollv4 PASS narrow: no leader lines | 0 lines
ZEDQA dollv4 PASS narrow: Back, Arms, Belt in that order down the right | 32,122,167
ZEDQA dollv4 PASS narrow: every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS narrow: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS narrow: no small-slot zone left | 0
ZEDQA dollv4 narrow: Arms layers 3, Back 2, Legs 5, Belt 4, Hands 4
ZEDQA dollv4 PASS narrow: Back's card shows the folded layers (tail, satchel) | layers 2
ZEDQA dollv4 short: window 362 -> 555 px (view 288, doll at full size 602)
ZEDQA dollv4 PASS short: the bands still show
ZEDQA dollv4 PASS short: the small slots shrank (under 18 units, 14 or more) | 16.2 units
ZEDQA dollv4 PASS short: the doll fits its view, no scrolling to reach it | 481 in 481
ZEDQA dollv4 PASS short: no slot overlaps another
ZEDQA dollv4 PASS short: 49 slot boxes | 49
ZEDQA dollv4 passed 62, failed 0 | DONE
```

### 5. zedqa_mapnotes.lua (`ZEDQA mnote`) - PASS, 3 s

- go 17952 at 13:13:10
- screenshots: zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mnote start
[ZeD.QA] run #5 ok=true
ZEDQA mnote gave 2 (pencil / eraser)
ZEDQA mnote map bound to the world map item: true
ZEDQA mnote before: store marks 8 | vanilla api marks 8 of 71 symbols (the rest are the map's own labels)
ZEDQA mnote text tool armed: true
ZEDQA mnote after note: store 8 -> 9 | vanilla api 8 -> 9 | found in store true | found by vanilla api true
ZEDQA mnote note ink 1 rgb 0.200 0.200 0.200 scale 0.6660000085830688 layer text-note
ZEDQA mnote star tool armed: true
ZEDQA mnote star as vanilla's Star: true ink 1 | store 10
ZEDQA mnote migration: first run added 2 (10 -> 12), second 0 (12), flag cleared 0 (12)
ZEDQA mnote migrated note ink 4 (want 4) | star ink 3 (want 3) | done flag true
ZEDQA mnote cursor finds the note: true
ZEDQA mnote cursor ui 207,128 | engine hit note 'ZEDQA note 64553' at world 865.5,12987.0 ui 207,139 | found note 'ZEDQA note 64553' at world 865.5,12987.0 ui 207,139 | the note note 'ZEDQA note 64553' at world 865.5,12987.0 ui 207,139
ZEDQA mnote menu: delete true | edit note true | change colour true | share false (multiplayer false)
ZEDQA mnote after delete: store 12 -> 11 | vanilla api 12 -> 11 | still found false / false
ZEDQA mnote removal: made a note true and a star true | store 11 -> 13
ZEDQA mnote removal: note true (13 -> 12), star true (-> 11), stale note again false (-> 11)
ZEDQA mnote style paper: map style paper | label layers 8 | strongest label alpha 0 | note hand alpha 255
ZEDQA mnote style survey: map style survey | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style color: map style color | label layers 8 | strongest label alpha 255 | note hand alpha 255
ZEDQA mnote style back to color
ZEDQA mnote cleanup: removed 3 marks | store 8 (started 8) | modData back
ZEDQA mnote DONE
```

### 6. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 21 s

- go 17953 at 13:13:16
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tw start
[ZeD.QA] run #6 ok=true
ZEDQA tw screen 1280x800, root scale 0.75, plate zoom 1
ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech@154)
ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS walkie_valutech: centred in its panel (x 22, want 22)
ZEDQA tw PASS walkie_valutech: the width that fills the half card (want walkie_valutech@154, got walkie_valutech@154)
ZEDQA tw PASS walkie_valutech: the tab is the half card where a width fits (190 px; panel 154, card 190)
ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
ZEDQA tw PASS walkie_valutech: the full view button in the header
ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
ZEDQA tw PASS walkie_valutech: the display reads while on
ZEDQA tw walkie_valutech: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
ZEDQA tw valutech: body 288 px tall, the face's body needs 399 (window 362)
ZEDQA tw PASS valutech: at the default height the body scrolls
ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
ZEDQA tw PASS TUNE: a click on its right half tunes up a step (98400 -> 98600)
ZEDQA tw PASS TUNE: its left half tunes down a step
ZEDQA tw PASS TUNE: a right-click turns it down
ZEDQA tw PASS MEM: stores the frequency as channel 01 (1 stored)
ZEDQA tw PASS the display shows CH 01 (01)
ZEDQA tw PASS MEM: a second channel stored
ZEDQA tw PASS CH down walks to channel 01
ZEDQA tw PASS CH up walks to channel 02
ZEDQA tw PASS the mic starts muted
ZEDQA tw PASS the TX lamp is dark while the mic is muted
ZEDQA tw PASS PUSH TO TALK latches the mic live
ZEDQA tw PASS the TX lamp lights and the display says TX OK (TX OK)
ZEDQA tw PASS pressed again it mutes the mic (MIC OFF)
ZEDQA tw PASS MEM held (right-click): the naming box opens
ZEDQA tw PASS naming it: channel 02 is QA Farm
ZEDQA tw PASS the header button opens full view on the radio
ZEDQA tw PASS full view is the face alone, no window frame
ZEDQA tw PASS full view is the plate at the plate scale, room for its 1u hard shadow (201x361)
ZEDQA tw PASS the first time it sits centre right of the play area (centre x 959.5)
ZEDQA tw PASS every control is on it (6)
ZEDQA tw PASS a control in full view works (CH down)
ZEDQA tw PASS MEM held in full view opens the naming box
ZEDQA tw PASS the face's edge is not a control
ZEDQA tw PASS dragging the face moves full view (859 -> 459)
ZEDQA tw PASS the place is kept on the character
ZEDQA tw PASS the header button closes full view
ZEDQA tw PASS the point between the knobs is no control
ZEDQA tw PASS a click on the face away from the controls opens full view
ZEDQA tw PASS it opens where it was dragged to
ZEDQA tw PASS B closes full view
ZEDQA tw PASS Escape closes full view
ZEDQA tw PASS full view closes when the radio leaves the hands
ZEDQA tw PASS pad: the face's VOL is a stop in the tab
ZEDQA tw PASS pad: up on VOL turns it up
ZEDQA tw PASS pad: right from VOL walks to TUNE (radio:tw:tune)
ZEDQA tw PASS pad: A on CH up steps the channel
ZEDQA tw PASS pad: X on MEM opens the naming box
ZEDQA tw PASS pad: A on the full view button opens it
ZEDQA tw PASS pad: full view shows its controller strip
ZEDQA tw PASS pad: full view lands on a control (vol)
ZEDQA tw PASS pad: down on VOL in full view turns it down
ZEDQA tw PASS pad: right walks to TUNE in full view (tune)
ZEDQA tw PASS pad: A on PUSH TO TALK in full view latches the mic
ZEDQA tw PASS pad: B closes full view
ZEDQA tw PASS walkie_toy: the Character window's Radio tab opens
ZEDQA tw PASS walkie_toy: its own face, walkie_toy (got walkie_toy@154)
ZEDQA tw PASS walkie_toy: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS walkie_toy: centred in its panel (x 28, want 28)
ZEDQA tw PASS walkie_toy: the width that fills the half card (want walkie_toy@154, got walkie_toy@154)
ZEDQA tw PASS walkie_toy: the tab is the half card where a width fits (190 px; panel 154, card 190)
ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
ZEDQA tw PASS walkie_toy: the full view button in the header
ZEDQA tw PASS walkie_toy: VOL pressed turns it on
ZEDQA tw PASS walkie_toy: the display reads while on
ZEDQA tw walkie_toy: display 107.00 MHZ | nil | nil nil
ZEDQA tw PASS toy: no memories, its TALK button
ZEDQA tw PASS toy: the drum shows the frequency
ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium@154)
ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS walkie_premium: centred in its panel (x 28, want 28)
ZEDQA tw PASS walkie_premium: the width that fills the half card (want walkie_premium@154, got walkie_premium@154)
ZEDQA tw PASS walkie_premium: the tab is the half card where a width fits (190 px; panel 154, card 190)
ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
ZEDQA tw PASS walkie_premium: the full view button in the header
ZEDQA tw PASS walkie_premium: VOL pressed turns it on
ZEDQA tw PASS walkie_premium: the display reads while on
ZEDQA tw walkie_premium: display 098.000 | NNR RADIO | BAT 3
ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical@154)
ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS walkie_tactical: centred in its panel (x 28, want 28)
ZEDQA tw PASS walkie_tactical: the width that fills the half card (want walkie_tactical@154, got walkie_tactical@154)
ZEDQA tw PASS walkie_tactical: the tab is the half card where a width fits (190 px; panel 154, card 190)
ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
ZEDQA tw PASS walkie_tactical: the full view button in the header
ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
ZEDQA tw PASS walkie_tactical: the display reads while on
ZEDQA tw walkie_tactical: display 114.600 | | BAT 3
ZEDQA tw PASS walkie_tactical: BAT with 3 bars at 60% charge
ZEDQA tw PASS Tactical: MUTE silences it
ZEDQA tw PASS Tactical: MUTE again gives the sound back
ZEDQA tw PASS Tactical: SCAN runs
ZEDQA tw PASS Tactical: SCAN again stops it
ZEDQA tw PASS Tactical: LAMP lights the display
ZEDQA tw PASS Tactical: the lamp goes out after 5 s
ZEDQA tw PASS walkie_army: the Character window's Radio tab opens
ZEDQA tw PASS walkie_army: its own face, walkie_army (got walkie_army@154)
ZEDQA tw PASS walkie_army: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS walkie_army: centred in its panel (x 28, want 28)
ZEDQA tw PASS walkie_army: the width that fills the half card (want walkie_army@154, got walkie_army@154)
ZEDQA tw PASS walkie_army: the tab is the half card where a width fits (190 px; panel 154, card 190)
ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
ZEDQA tw PASS walkie_army: the full view button in the header
ZEDQA tw PASS walkie_army: VOL pressed turns it on
ZEDQA tw PASS walkie_army: the display reads while on
ZEDQA tw walkie_army: display 089.400 | HITZ FM | BAT 3
ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift@154)
ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS walkie_makeshift: centred in its panel (x 28, want 28)
ZEDQA tw PASS walkie_makeshift: the width that fills the half card (want walkie_makeshift@154, got walkie_makeshift@154)
ZEDQA tw PASS walkie_makeshift: the tab is the half card where a width fits (190 px; panel 154, card 190)
ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
ZEDQA tw PASS walkie_makeshift: the full view button in the header
ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
ZEDQA tw PASS walkie_makeshift: the display reads while on
ZEDQA tw walkie_makeshift: display CH-- 102.20 | | nil nil
ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 102.20)
ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack@154)
ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS walkie_manpack: centred in its panel (x 28, want 28)
ZEDQA tw PASS walkie_manpack: the width that fills the half card (want walkie_manpack@154, got walkie_manpack@154)
ZEDQA tw PASS walkie_manpack: the tab is the half card where a width fits (190 px; panel 154, card 190)
ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
ZEDQA tw PASS walkie_manpack: the full view button in the header
ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
ZEDQA tw PASS walkie_manpack: the display reads while on
ZEDQA tw walkie_manpack: display 093.200 | LBMW - KENTUCKY RADIO | BAT 3
ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
ZEDQA tw PASS ManPack: on the back
ZEDQA tw PASS an AM/FM radio with faces off shows the chassis (the simple card)
ZEDQA tw 8 free squares in reach
ZEDQA tw placed 3 ham sets
ZEDQA tw PASS the World window's Radio tab opens on the placed sets
ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian@392)
ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS ham_civilian: centred across the drawer (x 11, want 11)
ZEDQA tw PASS ham_civilian: the drawer holds the whole set (414 px for 392)
ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
ZEDQA tw PASS ham_civilian: the full view button in the header
ZEDQA tw PASS ham_civilian: VOL pressed turns it on
ZEDQA tw ham_civilian: display 308.400 | | range RANGE 7.5 KM
ZEDQA tw PASS ham_civilian: the display reads while on
ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (12 sets, 12 clears)
ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
ZEDQA tw PASS civilian ham: the band marker follows the frequency up (0.6089795918367347 -> 0.7110204081632653)
ZEDQA tw PASS civilian ham: full view opens
ZEDQA tw PASS ham_civilian on a small screen: its narrow face (ham_civilian_n)
ZEDQA tw PASS ham_civilian: the tab is the half card (190 px, want 190)
ZEDQA tw PASS ham_civilian: the narrow face at a whole zoom that fits the half card (1 of the screen's 1)
ZEDQA tw PASS ham_civilian: every control of the wide set on the narrow face (8)
ZEDQA tw PASS ham_civilian: VOL on the narrow face turns it on
ZEDQA tw PASS ham_civilian: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_civilian: the narrow face's display reads
ZEDQA tw PASS ham_army on a small screen: its narrow face (ham_army_n)
ZEDQA tw PASS ham_army: the tab is the half card (190 px, want 190)
ZEDQA tw PASS ham_army: the narrow face at a whole zoom that fits the half card (1 of the screen's 1)
ZEDQA tw PASS ham_army: every control of the wide set on the narrow face (14)
ZEDQA tw PASS ham_army: VOL on the narrow face turns it on
ZEDQA tw PASS ham_army: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_army: the narrow face's display reads
ZEDQA tw PASS ham_makeshift on a small screen: its narrow face (ham_makeshift_n)
ZEDQA tw PASS ham_makeshift: the tab is the half card (190 px, want 190)
ZEDQA tw PASS ham_makeshift: the narrow face at a whole zoom that fits the half card (1 of the screen's 1)
ZEDQA tw PASS ham_makeshift: every control of the wide set on the narrow face (7)
ZEDQA tw PASS ham_makeshift: VOL on the narrow face turns it on
ZEDQA tw PASS ham_makeshift: TUNE on the narrow face tunes up a step
ZEDQA tw PASS ham_makeshift: the narrow face's display reads
ZEDQA tw PASS narrow makeshift ham: TALK / LISTEN flips with the mic
ZEDQA tw PASS with room again the wide set is back
ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army@392)
ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS ham_army: centred across the drawer (x 11, want 11)
ZEDQA tw PASS ham_army: the drawer holds the whole set (414 px for 392)
ZEDQA tw PASS ham_army: all 14 controls on the face (14)
ZEDQA tw PASS ham_army: the full view button in the header
ZEDQA tw PASS ham_army: VOL pressed turns it on
ZEDQA tw ham_army: display 098.600 | | range RANGE 20 KM
ZEDQA tw PASS ham_army: the display reads while on
ZEDQA tw PASS army ham: tuned away
ZEDQA tw PASS army ham: 1 goes straight to memory 1
ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift@392)
ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 1 (got 1)
ZEDQA tw PASS ham_makeshift: centred across the drawer (x 11, want 11)
ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (414 px for 392)
ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
ZEDQA tw PASS ham_makeshift: the full view button in the header
ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
ZEDQA tw ham_makeshift: display CH-- 101.400 MHZ | | range RANGE 6 KM
ZEDQA tw PASS ham_makeshift: the display reads while on
ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
ZEDQA tw PASS makeshift ham: full view opens
ZEDQA tw PASS full view closes when the set is taken away
ZEDQA tw cleanup: 3 sets and 8 items taken away
ZEDQA tw 192 passed, 0 failed
ZEDQA tw all checks passed
ZEDQA tw DONE
```

### 7. zedqa_rtv.lua (`ZEDQA rtv`) - PASS, 37 s

- go 17954 at 13:13:41
- screenshots: zqa_rtv_1_radio_black.png, zqa_rtv_1_radio_red.png, zqa_rtv_1b_radio_red_list.png, zqa_rtv_1_radio_handbuilt.png, zqa_rtv_1_cd_player.png, zqa_rtv_1b_cd_player_list.png, zqa_rtv_2_pad_cd_player_battery_list.png, zqa_rtv_2_pad_cd_player_phones_list.png, zqa_rtv_2_pad_cd_player_disc_list.png, zqa_rtv_3_simple_card.png, zqa_rtv_4a_radio_red_placed.png, zqa_rtv_4c_tv_black_standby.png, zqa_rtv_4d_tv_black_triple_n_standby.png, zqa_rtv_4d_tv_black_turbo_standby.png, zqa_rtv_4c_tv_black_bars.png, zqa_rtv_4e_tv_black_no_power.png, zqa_rtv_2_pad_tv_black_tape_list.png, zqa_rtv_2_pad_tv_black_phones_list.png, zqa_rtv_4c_tv_widescreen_standby.png, zqa_rtv_4d_tv_widescreen_triple_n_standby.png, zqa_rtv_4d_tv_widescreen_turbo_standby.png, zqa_rtv_4c_tv_widescreen_bars.png, zqa_rtv_4e_tv_widescreen_no_power.png, zqa_rtv_4c_tv_antique_standby.png, zqa_rtv_4d_tv_antique_triple_n_standby.png, zqa_rtv_4d_tv_antique_turbo_standby.png, zqa_rtv_4c_tv_antique_bars.png, zqa_rtv_4e_tv_antique_no_power.png, zqa_rtv_5_house_bare.png, zqa_rtv_5_house_ci_radio.png, zqa_rtv_5_house_ci_tv.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rtv start
[ZeD.QA] run #7 ok=true
ZEDQA rtv screen 1280x800, root scale 0.75, plate zoom 1
ZEDQA rtv PASS radio_black: the Character window's Radio tab opens
ZEDQA rtv PASS radio_black: its own face, radio_black (got radio_black@154)
ZEDQA rtv PASS radio_black: the half card where a width fits, else the full (190 px, want 190)
ZEDQA rtv PASS radio_black: the width that fills the half card (radio_black@154, got radio_black@154)
ZEDQA rtv PASS radio_black: centred, its margins its own (x 28, want 28)
ZEDQA rtv PASS radio_black: no full view button (a two-way set's)
ZEDQA rtv PASS radio_black: every control on the face (11 of 11)
ZEDQA rtv PASS radio_black: POWER turns it on
ZEDQA rtv PASS radio_black: the display reads and the lamp lights while on
ZEDQA rtv radio_black: display 98.0 | NNR RADIO | batt 3
ZEDQA rtv PASS radio_black: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_black: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_black: tuned away
ZEDQA rtv PASS radio_black: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_black: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_black: the headphone jack queues vanilla's action
ZEDQA rtv PASS radio_red: the Character window's Radio tab opens
ZEDQA rtv PASS radio_red: its own face, radio_red (got radio_red@154)
ZEDQA rtv PASS radio_red: the half card where a width fits, else the full (190 px, want 190)
ZEDQA rtv PASS radio_red: the width that fills the half card (radio_red@154, got radio_red@154)
ZEDQA rtv PASS radio_red: centred, its margins its own (x 28, want 28)
ZEDQA rtv PASS radio_red: no full view button (a two-way set's)
ZEDQA rtv PASS radio_red: every control on the face (14 of 14)
ZEDQA rtv PASS radio_red: POWER turns it on
ZEDQA rtv PASS radio_red: the display reads and the lamp lights while on
ZEDQA rtv radio_red: display 98.0 | NNR RADIO | batt 3
ZEDQA rtv PASS radio_red: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_red: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_red: tuned away
ZEDQA rtv PASS radio_red: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_red: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_red: the slot opens the list of discs carried
ZEDQA rtv PASS radio_red: the headphone jack queues vanilla's action
ZEDQA rtv PASS radio_handbuilt: the Character window's Radio tab opens
ZEDQA rtv PASS radio_handbuilt: its own face, radio_handbuilt (got radio_handbuilt@257)
ZEDQA rtv PASS radio_handbuilt: the half card where a width fits, else the full (414 px, want 414)
ZEDQA rtv PASS radio_handbuilt: centred, its margins its own (x 88, want 88)
ZEDQA rtv PASS radio_handbuilt: no full view button (a two-way set's)
ZEDQA rtv PASS radio_handbuilt: every control on the face (10 of 10)
ZEDQA rtv PASS radio_handbuilt: POWER turns it on
ZEDQA rtv PASS radio_handbuilt: the display reads and the lamp lights while on
ZEDQA rtv radio_handbuilt: display FM 98.0 MHZ | NNR RADIO | batt 3
ZEDQA rtv PASS radio_handbuilt: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS radio_handbuilt: TUNE's right half tunes up a step
ZEDQA rtv PASS radio_handbuilt: tuned away
ZEDQA rtv PASS radio_handbuilt: P1 pressed goes back to the stored station
ZEDQA rtv PASS radio_handbuilt: the battery key queues vanilla's battery action
ZEDQA rtv PASS radio_handbuilt: the headphone jack queues vanilla's action
ZEDQA rtv PASS cd_player: the Character window's Radio tab opens
ZEDQA rtv PASS cd_player: its own face, cd_player (got cd_player@154)
ZEDQA rtv PASS cd_player: the half card where a width fits, else the full (190 px, want 190)
ZEDQA rtv PASS cd_player: the width that fills the half card (cd_player@154, got cd_player@154)
ZEDQA rtv PASS cd_player: centred, its margins its own (x 28, want 28)
ZEDQA rtv PASS cd_player: no full view button (a two-way set's)
ZEDQA rtv PASS cd_player: every control on the face (9 of 9)
ZEDQA rtv PASS cd_player: POWER turns it on
ZEDQA rtv PASS cd_player: the display reads and the lamp lights while on
ZEDQA rtv cd_player: display -:-- | NO DISC | batt 3
ZEDQA rtv PASS cd_player: the volume goes up (0.50 -> 0.60)
ZEDQA rtv PASS cd_player: the battery key queues vanilla's battery action
ZEDQA rtv PASS cd_player: the slot opens the list of discs carried
ZEDQA rtv PASS cd_player: the headphone jack queues vanilla's action
ZEDQA rtv PASS controller: POWER is the first stop on the face (got radio:tw:power)
ZEDQA rtv PASS controller: every control is a stop (9)
ZEDQA rtv PASS cd_player: the pad lands on power when it enters the tab (radio:tw:power)
ZEDQA rtv PASS cd_player: the pad's A on battery opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on battery (radio:tw:battery)
ZEDQA rtv PASS cd_player: the pad's A on phones opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on phones (radio:tw:phones)
ZEDQA rtv PASS cd_player: the pad's A on slot opens its list
ZEDQA rtv PASS cd_player: the list closed: the pad is back on slot (radio:tw:slot)
ZEDQA rtv PASS faces off: the simple card (the chassis) through drawSimple
ZEDQA rtv PASS faces on again: the face is back
ZEDQA rtv indoors at 892,13007 (5 free room squares round it)
ZEDQA rtv grid: world power true, this square haveElectricity false, hasGridPower true, in a room true
ZEDQA rtv PASS the staging square has grid power
ZEDQA rtv placed 4 sets (round the character, on their squares)
ZEDQA rtv PASS the World window lists the placed sets (4)
ZEDQA rtv PASS the World window's Radio tab opens on the placed sets
ZEDQA rtv PASS radio_red (placed, by its tile): its own face, radio_red (got radio_red@154)
ZEDQA rtv PASS radio_red (placed, by its tile): the half card where a width fits, else the full (190 px, want 190)
ZEDQA rtv PASS radio_red (placed, by its tile): the width that fills the half card (radio_red@154, got radio_red@154)
ZEDQA rtv PASS radio_red (placed, by its tile): centred, its margins its own (x 28, want 28)
ZEDQA rtv PASS radio_red (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS radio_red (placed, by its tile): every control on the face (14 of 14)
ZEDQA rtv PASS tv_black (placed, by its tile): its own face, tv_black (got tv_black@392)
ZEDQA rtv PASS tv_black (placed, by its tile): the full card (414 px)
ZEDQA rtv PASS tv_black (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS tv_black (placed, by its tile): every control on the face (10 of 10)
ZEDQA rtv PASS tv_black: the set has grid power (true)
ZEDQA rtv PASS tv_black: NO POWER dark on the grid
ZEDQA rtv PASS tv_black: off to start with
ZEDQA rtv PASS tv_black: power turns it on
ZEDQA rtv PASS tv_black: the power lamp lights
ZEDQA rtv PASS tv_black: the channel display reads (07)
ZEDQA rtv PASS tv_black: on the first stop (1)
ZEDQA rtv PASS tv_black: CH up: the second stop (2)
ZEDQA rtv PASS tv_black: CH down: back to the first (1)
ZEDQA rtv PASS tv_black: CH down from the first wraps to the twelfth (12)
ZEDQA rtv PASS tv_black: CH up from the twelfth wraps to the first (1)
ZEDQA rtv PASS tv_black: VOL up raises the volume
ZEDQA rtv PASS tv_black: VOL down lowers it again
ZEDQA rtv PASS tv_black: just changed channel: snow (snow)
ZEDQA rtv tv_black: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_black: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_black: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_black: channel 12: the display reads it
ZEDQA rtv tv_black: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_black: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_black: channel 13: the display reads it
ZEDQA rtv PASS tv_black: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_black: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_black: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_black: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_black: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_black: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_black: power again turns it off
ZEDQA rtv PASS tv_black: with the grid off the set reports no power
ZEDQA rtv PASS tv_black: NO POWER lit without the grid
ZEDQA rtv PASS tv_black: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_black: the grid back on: the set has power again
ZEDQA rtv PASS tv_black: the pad lands on power when it enters the tab (radio:tw:power)
ZEDQA rtv PASS tv_black: the pad's A on slot opens its list
ZEDQA rtv PASS tv_black: the list closed: the pad is back on slot (radio:tw:slot)
ZEDQA rtv PASS tv_black: the pad's A on phones opens its list
ZEDQA rtv PASS tv_black: the list closed: the pad is back on phones (radio:tw:phones)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): its own face, tv_widescreen (got tv_widescreen@392)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): the full card (414 px)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS tv_widescreen (placed, by its tile): every control on the face (10 of 10)
ZEDQA rtv PASS tv_widescreen: the set has grid power (true)
ZEDQA rtv PASS tv_widescreen: NO POWER dark on the grid
ZEDQA rtv PASS tv_widescreen: off to start with
ZEDQA rtv PASS tv_widescreen: power turns it on
ZEDQA rtv PASS tv_widescreen: the power lamp lights
ZEDQA rtv PASS tv_widescreen: the channel display reads (03)
ZEDQA rtv PASS tv_widescreen: on the first stop (1)
ZEDQA rtv PASS tv_widescreen: CH up: the second stop (2)
ZEDQA rtv PASS tv_widescreen: CH down: back to the first (1)
ZEDQA rtv PASS tv_widescreen: CH down from the first wraps to the twelfth (12)
ZEDQA rtv PASS tv_widescreen: CH up from the twelfth wraps to the first (1)
ZEDQA rtv PASS tv_widescreen: VOL up raises the volume
ZEDQA rtv PASS tv_widescreen: VOL down lowers it again
ZEDQA rtv PASS tv_widescreen: just changed channel: snow (snow)
ZEDQA rtv tv_widescreen: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_widescreen: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_widescreen: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_widescreen: channel 12: the display reads it
ZEDQA rtv tv_widescreen: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_widescreen: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_widescreen: channel 13: the display reads it
ZEDQA rtv PASS tv_widescreen: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_widescreen: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_widescreen: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_widescreen: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_widescreen: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_widescreen: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_widescreen: power again turns it off
ZEDQA rtv PASS tv_widescreen: with the grid off the set reports no power
ZEDQA rtv PASS tv_widescreen: NO POWER lit without the grid
ZEDQA rtv PASS tv_widescreen: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_widescreen: the grid back on: the set has power again
ZEDQA rtv PASS tv_antique (placed, by its tile): its own face, tv_antique (got tv_antique@392)
ZEDQA rtv PASS tv_antique (placed, by its tile): the full card (414 px)
ZEDQA rtv PASS tv_antique (placed, by its tile): no full view button (a two-way set's)
ZEDQA rtv PASS tv_antique (placed, by its tile): every control on the face (4 of 4)
ZEDQA rtv PASS tv_antique: the volume knob is one control (volpwr), the channel dial another
ZEDQA rtv PASS tv_antique: the set has grid power (true)
ZEDQA rtv PASS tv_antique: NO POWER dark on the grid
ZEDQA rtv PASS tv_antique: off to start with
ZEDQA rtv PASS tv_antique: power turns it on
ZEDQA rtv PASS tv_antique: the power lamp lights
ZEDQA rtv PASS tv_antique: the channel display reads (08)
ZEDQA rtv PASS tv_antique: eleven clicks up the dial: the twelfth stop (12)
ZEDQA rtv PASS tv_antique: the dial's pointer is on the twelfth mark (11)
ZEDQA rtv PASS tv_antique: the dial stops at its upper end (12)
ZEDQA rtv PASS tv_antique: eleven clicks down: the first stop (1)
ZEDQA rtv PASS tv_antique: the dial stops at its lower end (1)
ZEDQA rtv PASS tv_antique: a click on the dial's right half: up a stop (2)
ZEDQA rtv PASS tv_antique: its left half: down a stop (1)
ZEDQA rtv PASS tv_antique: the knob turned: the volume rises
ZEDQA rtv PASS tv_antique: the knob turned: still on
ZEDQA rtv PASS tv_antique: the knob pulled: off
ZEDQA rtv PASS tv_antique: the knob pushed: on again
ZEDQA rtv PASS tv_antique: just changed channel: snow (snow)
ZEDQA rtv tv_antique: channel 2 (triple_n): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 3 (wbln): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 4 (life): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 5 (turbo): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 6 (paws): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 7 (kpa): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 8 (mvc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 9 (nst): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 10 (bmc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 11 (gbc): standby, signal bad/fair/good true/false/false
ZEDQA rtv tv_antique: channel 12 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_antique: channel 12: the signal light bad on the bars
ZEDQA rtv PASS tv_antique: channel 12: the display reads it
ZEDQA rtv tv_antique: channel 13 (nil): bars, signal bad/fair/good true/false/false
ZEDQA rtv PASS tv_antique: channel 13: the signal light bad on the bars
ZEDQA rtv PASS tv_antique: channel 13: the display reads it
ZEDQA rtv PASS tv_antique: 12 and 13 have no station: the bars (bars, bars)
ZEDQA rtv PASS tv_antique: the ten stations each show picture, sign-off or standby (10 of 10)
ZEDQA rtv tv_antique: screens seen across the dial: snow x0, bars x2, picture x0, signoff x0, standby x10
ZEDQA rtv tv_antique: NOT REACHED at this hour: picture (the game's broadcast clock decides)
ZEDQA rtv tv_antique: NOT REACHED at this hour: signoff (the game's broadcast clock decides)
ZEDQA rtv PASS tv_antique: a frequency off the dial: snow (snow)
ZEDQA rtv PASS tv_antique: power again turns it off
ZEDQA rtv PASS tv_antique: with the grid off the set reports no power
ZEDQA rtv PASS tv_antique: NO POWER lit without the grid
ZEDQA rtv PASS tv_antique: the power key without the grid leaves the screen dark
ZEDQA rtv PASS tv_antique: the grid back on: the set has power again
ZEDQA rtv PASS tv_antique: the pad lands on power when it enters the tab (radio:tw:volpwr)
ZEDQA rtv PASS tv_antique: pad: A on the knob powers it
ZEDQA rtv PASS tv_antique: pad: up on the knob turns the volume, the set stays on
ZEDQA rtv PASS tv_antique: pad: up on the dial: a stop up (4)
ZEDQA rtv PASS tv_antique: pad: A on the knob again: off
ZEDQA rtv PASS every off-air screen's texture loads (0 missing)
ZEDQA rtv PASS the game's own logo loads: triple_n
ZEDQA rtv PASS the game's own logo loads: turbo
ZEDQA rtv PASS controller: the set's power is the first stop (radio:tw:volpwr)
ZEDQA rtv house tiles: bare radio appliances_radio_01_20; CustomItem radio appliances_radio_01_3 (radio_black); CustomItem TV appliances_television_01_3 (tv_widescreen)
ZEDQA rtv PASS house radio tile appliances_radio_01_20: no face of its own without a dropped item
ZEDQA rtv PASS house radio dropped as an item (RadioItemID): the item's face (radio_black)
ZEDQA rtv PASS house radio tile appliances_radio_01_3 (CustomItem): radio_black (radio_black)
ZEDQA rtv PASS house TV tile appliances_television_01_3 (CustomItem): tv_widescreen (tv_widescreen)
ZEDQA rtv PASS the World window lists the house sets (3)
ZEDQA rtv PASS house_bare in the Radio tab: its own face, radio_black (got radio_black@154)
ZEDQA rtv PASS house_bare in the Radio tab: the half card where a width fits, else the full (190 px, want 190)
ZEDQA rtv PASS house_bare in the Radio tab: the width that fills the half card (radio_black@154, got radio_black@154)
ZEDQA rtv PASS house_bare in the Radio tab: centred, its margins its own (x 28, want 28)
ZEDQA rtv PASS house_bare in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_bare in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_bare: on the grid (true)
ZEDQA rtv PASS house_ci_radio in the Radio tab: its own face, radio_black (got radio_black@154)
ZEDQA rtv PASS house_ci_radio in the Radio tab: the half card where a width fits, else the full (190 px, want 190)
ZEDQA rtv PASS house_ci_radio in the Radio tab: the width that fills the half card (radio_black@154, got radio_black@154)
ZEDQA rtv PASS house_ci_radio in the Radio tab: centred, its margins its own (x 28, want 28)
ZEDQA rtv PASS house_ci_radio in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_ci_radio in the Radio tab: every control on the face (11 of 11)
ZEDQA rtv PASS house_ci_radio: on the grid (true)
ZEDQA rtv PASS house_ci_tv in the Radio tab: its own face, tv_widescreen (got tv_widescreen@392)
ZEDQA rtv PASS house_ci_tv in the Radio tab: the full card (414 px)
ZEDQA rtv PASS house_ci_tv in the Radio tab: no full view button (a two-way set's)
ZEDQA rtv PASS house_ci_tv in the Radio tab: every control on the face (10 of 10)
ZEDQA rtv PASS house_ci_tv: on the grid (true)
ZEDQA rtv cleanup: sets, house sets and 7 items taken away
ZEDQA rtv back at 925,13040
ZEDQA rtv 211 passed, 0 failed
ZEDQA rtv all checks passed
ZEDQA rtv DONE
ERROR: General f:17185 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:17194 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 8. zedqa_appliances.lua (`ZEDQA ap`) - PASS, 5 s

- go 17955 at 13:14:21
- screenshots: zqa_ap_1_tab_stove.png, zqa_ap_2_popout_stove.png, zqa_ap_2b_popout_stove_on.png, zqa_ap_3_tab_microwave.png, zqa_ap_4_popout_microwave.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ap start
[ZeD.QA] run #8 ok=true
ZEDQA ap indoors at 891,13006
ZEDQA ap placed: stove true, microwave true
ZEDQA ap PASS the stove opens in the Craft tab
ZEDQA ap stove powered true (grid power on the square true, object index 4, world power true)
ZEDQA ap PASS stove: the station is the one opened
ZEDQA ap PASS stove: the World window is on its Craft tab
ZEDQA ap stove: plate oven_modern@392 392x136, tab 414 px, zoom in the tab 1 (the screen's 1)
ZEDQA ap PASS stove: the tab is the full card
ZEDQA ap PASS stove: the plate draws at a whole zoom that fits the card
ZEDQA ap PASS stove: the tab has the pop-out button
ZEDQA ap PASS the pop-out window is up
ZEDQA ap pop-out 458,267 364x265, zoom 1 (the screen's 1)
ZEDQA ap PASS the pop-out is centred on the screen
ZEDQA ap PASS the pop-out's plate is at least the tab's size
ZEDQA ap PASS the pop-out is on screen
ZEDQA ap PASS the pop-out has the plate's controls (15)
ZEDQA ap PASS the tab says it is in its own window and offers it back
ZEDQA ap pressed broil
ZEDQA ap stove heat 200 -> 300
ZEDQA ap PASS a control pressed in the pop-out moves the stove's own setting
ZEDQA ap PASS Bring it back closes the window
ZEDQA ap PASS the plate is back in the tab
ZEDQA ap PASS the microwave opens in the Craft tab
ZEDQA ap PASS microwave: the station is the one opened
ZEDQA ap PASS microwave: the World window is on its Craft tab
ZEDQA ap microwave: plate mw_white@392 392x168, tab 414 px, zoom in the tab 1 (the screen's 1)
ZEDQA ap PASS microwave: the tab is the full card
ZEDQA ap PASS microwave: the plate draws at a whole zoom that fits the card
ZEDQA ap PASS microwave: the tab has the pop-out button
ZEDQA ap PASS the microwave pops out too
ZEDQA ap cleanup: 2 appliances removed, station released
ZEDQA ap back at 925,13040
ZEDQA ap all checks passed
ZEDQA ap DONE
ERROR: General f:18038 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:18046 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 9. zedqa_plates_336.lua (`ZEDQA p336`) - PASS, 54 s

- go 17956 at 13:14:29
- screenshots: zqa_p336_scale075_oven.png, zqa_p336_scale075_microwave.png, zqa_p336_scale075_chrome.png, zqa_p336_scale075_generator.png, zqa_p336_scale075_grill.png, zqa_p336_scale050_oven.png, zqa_p336_scale050_microwave.png, zqa_p336_scale050_chrome.png, zqa_p336_scale050_generator.png, zqa_p336_scale050_grill.png

```text
[ZeD.QA] windows reset (R)
ZEDQA p336 start
[ZeD.QA] run #9 ok=true
ZEDQA p336 indoors at 891,13006
ZEDQA p336 placed: oven true, microwave true, chrome true, generator true, grill true
ZEDQA p336 phase A: root 0.75 (the run's own scale)
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale075, root 0.75, zoom 1]: plate oven_modern, drawn oven_modern@392, tab 414 px (half 190, full 414); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the face that fills the card is drawn (want oven_modern@392, drawn oven_modern@392)
ZEDQA p336 PASS oven: it sits inside the card at the whole zoom (392 of 402 px)
ZEDQA p336 PASS oven: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale075, root 0.75, zoom 1]: plate mw_white, drawn mw_white@392, tab 414 px (half 190, full 414); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the face that fills the card is drawn (want mw_white@392, drawn mw_white@392)
ZEDQA p336 PASS microwave: it sits inside the card at the whole zoom (392 of 402 px)
ZEDQA p336 PASS microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale075, root 0.75, zoom 1]: plate mw_chrome, drawn mw_chrome@392, tab 414 px (half 190, full 414); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the face that fills the card is drawn (want mw_chrome@392, drawn mw_chrome@392)
ZEDQA p336 PASS chrome microwave: it sits inside the card at the whole zoom (392 of 402 px)
ZEDQA p336 PASS chrome microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale075, root 0.75]: card 414 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 generator: plate room 396 px, the face for it gen_red@392
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale075, root 0.75]: card 414 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 grill: plate room 396 px, the face for it grill_propane@392
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13007.5 (grill 893,13008)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 phase B: forced root 0.50
ZEDQA p336 PASS oven opens in the Craft tab
ZEDQA p336 PASS oven: the station is the one opened
ZEDQA p336 oven [scale050, root 0.50, zoom 1]: plate oven_modern, drawn oven_modern_n, tab 276 px (half 126, full 276); controls bake d1 d2 d3 d4 d5 timer broil d6 d7 d8 d9 d0 cancel start
ZEDQA p336 PASS oven: the tab is the half card or the full card
ZEDQA p336 PASS oven: the face has its controls (15)
ZEDQA p336 PASS oven: the face that fills the card is drawn (want oven_modern_n, drawn oven_modern_n)
ZEDQA p336 PASS oven: it sits inside the card at the whole zoom (200 of 268 px)
ZEDQA p336 PASS oven: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS oven: BAKE 175 START heats it and runs it (on true, 100)
ZEDQA p336 PASS oven: TIMER 0:30 START sets the timer (1800)
ZEDQA p336 PASS oven: CANCEL turns it off
ZEDQA p336 PASS microwave opens in the Craft tab
ZEDQA p336 PASS microwave: the station is the one opened
ZEDQA p336 microwave [scale050, root 0.50, zoom 1]: plate mw_white, drawn mw_white_n, tab 276 px (half 126, full 276); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS microwave: the tab is the half card or the full card
ZEDQA p336 PASS microwave: the face has its controls (14)
ZEDQA p336 PASS microwave: the face that fills the card is drawn (want mw_white_n, drawn mw_white_n)
ZEDQA p336 PASS microwave: it sits inside the card at the whole zoom (200 of 268 px)
ZEDQA p336 PASS microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS microwave: STOP twice turns it off
ZEDQA p336 PASS chrome microwave opens in the Craft tab
ZEDQA p336 PASS chrome microwave: the station is the one opened
ZEDQA p336 chrome microwave [scale050, root 0.50, zoom 1]: plate mw_chrome, drawn mw_chrome_n, tab 276 px (half 126, full 276); controls power timecook d1 d2 d3 d4 d5 d6 d7 d8 d9 stop d0 start
ZEDQA p336 PASS chrome microwave: the tab is the half card or the full card
ZEDQA p336 PASS chrome microwave: the face has its controls (14)
ZEDQA p336 PASS chrome microwave: the face that fills the card is drawn (want mw_chrome_n, drawn mw_chrome_n)
ZEDQA p336 PASS chrome microwave: it sits inside the card at the whole zoom (200 of 268 px)
ZEDQA p336 PASS chrome microwave: at the run's own scale a full face is drawn, not the narrow one
ZEDQA p336 PASS chrome microwave: TIMECOOK 1:00 START runs it (on true, timer 60)
ZEDQA p336 PASS chrome microwave: STOP twice turns it off
ZEDQA p336 generator [scale050, root 0.50]: card 276 px wide; controls gen:engine gen:outlet
ZEDQA p336 PASS generator: the card is the full card
ZEDQA p336 generator: plate room 264 px, the face for it gen_red_n
ZEDQA p336 PASS generator: the face has its controls
ZEDQA p336 PASS generator: the engine switch starts it (it runs)
ZEDQA p336 PASS generator: the engine switch stops it
ZEDQA p336 grill [scale050, root 0.50]: card 276 px wide; controls bbq:tank bbq:burner bbq:ignite
ZEDQA p336 PASS grill: the card is the full card
ZEDQA p336 grill: plate room 264 px, the face for it grill_propane_n
ZEDQA p336 PASS grill: the face has its controls
ZEDQA p336 PASS grill: the tank part puts a tank in
ZEDQA p336 grill: before the burner knob: fuel 20, hasFuel true, tank true, lit false, an action running false, character at 894.5,13007.5 (grill 893,13008)
ZEDQA p336 PASS grill: the burner knob lights it (lit)
ZEDQA p336 cleanup done: 5 things removed
ZEDQA p336 all checks passed
ZEDQA p336 DONE
ERROR: General f:24503 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:24511 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```

### 10. zedqa_wheel_icons.lua (`ZEDQA wi`) - PASS, 17 s

- go 17957 at 13:15:26
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wi no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wi start car=BaseVehicle{ Name:null, ID:207 }
[ZeD.QA] run #10 ok=true
ZEDQA wi scene: screen 1280x800, scale option 1, icon box 14 at rest, 21 pointed
ZEDQA wi PASS all 153 icons load at 16, 24, 32 and 48, each its own file (0 problems)
ZEDQA wi PASS the drawing for each box: the largest that fits, at its own size; under 16 the 16 scaled down
ZEDQA wi at this scale: box 14 draws the 14, box 21 draws the 16
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
ZEDQA wi PASS dpad_left: 10 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Light/No light on you.=bulb_on
ZEDQA wi PASS dpad_down: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select: 12 slices | 1:Base theme/Dark=theme 3:Text size/Large=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select: 11 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_left_use: 5 slices | 1:Smoke/Nothing to smoke, or nothing to light it.=cigarette 2:Read=book 3:Watch/No watch on your wrist.=watch 4:Radio/No radio in your hands or on your back.=walkie
ZEDQA wi PASS dpad_left_use: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_speed: 5 slices | 1:Pause/In use=pause 2:FF x 1=ff1 3:FF x 2=ff2 4:FF x 3=wait
ZEDQA wi PASS dpad_down_speed: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_view: 5 slices | 1:Hide the interface/Until you take this again=eye_off 2:Reset windows/Both windows back to where they start=rotate 3:Text size=textsize 4:OPTIONS/Options, on ZeD's page=gears
ZEDQA wi PASS dpad_down_view: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select_theme: 4 slices | 1:Dark/In use=theme 2:Light=theme 3:High contrast=theme
ZEDQA wi PASS dpad_select_theme: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_friendly: 6 slices | 1:Wave Hi=wave 2:Bye=wave_bye 3:Clap=clap 4:Thumbs Up=thumbs_up 5:Thank You=bow
ZEDQA wi PASS emotes_friendly: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_hostile: 5 slices | 1:Insult=insult 2:Stop=hand 3:Surrender=surrender 4:Thumbs Down=thumbs_down
ZEDQA wi PASS emotes_hostile: 4 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_group: 7 slices | 1:Follow Me=follow_me 2:Come Here=come_here 3:Yes=yes 4:No=no 5:Shrug=shrug 6:Undecided=undecided
ZEDQA wi PASS emotes_group: 6 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_signal: 9 slices | 1:Cease Fire=target_off 2:Ok=yes 3:Move Out=move_out 4:Freeze=freeze 5:Follow Behind=follow_behind 6:Fire=target 7:Come=come_here 8:Salute=salute
ZEDQA wi PASS emotes_signal: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi gun: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi light: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi stick: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi vanilla_back: 10 slices | 1:Player Info=heart 2:Crafting=craft 3:Building=bricks 4:Zoom 75%=zoom_in 5:Pause=pause 6:FF x 1=ff1 7:Zoom 125%=zoom_out 8:Move furniture=chair 9:Enable Search Mode=eye 10:Investigate This Area=magnifier
ZEDQA wi PASS vanilla_back: 10 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi vanilla_dright: 3 slices | 1:Show/Hide World Map=map 2:Designated Zones=fence 3:Toggle Survival Guide=guide
ZEDQA wi PASS vanilla_dright: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi car_outside: 0 slices |
ZEDQA wi NOTE car_outside: the wheel is empty here
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Lock all doors=padlock 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 13 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi PASS vanilla's radials and ZeD's wheels, live: 121 slices, 119 wheel icons, 2 kept pictures
ZEDQA wi now at 1x (text size large): icon box 14 at rest, 21 pointed
ZEDQA wi dpad_left_1x: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left_1x: 9 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right_1x: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up_1x: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_1x: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select_1x: 12 slices | 1:Base theme/Dark=theme 3:Text size/Large=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select_1x: 11 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi light_1x: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi car_inside_1x: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Lock all doors=padlock 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi scale back to option 1: icon box 14
ZEDQA wi 0 failed, 3 notes
ZEDQA wi DONE
```

### 11. zedqa_world_pad_take.lua (`ZEDQA wpt`) - PASS, 53 s

- go 17958 at 13:15:47

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #11 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@49
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
ZEDQA wpt 6 Right: Char charContainerStrip:container:1
ZEDQA wpt PASS Right from a row lands on the bag on show
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
ZEDQA wpt 7 tabs: 13 at large and large
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 315 of 320)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 307 of 320)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control health:exercise is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 301 px in a 257 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:view is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 315 of 320)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 309 of 320)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:__save is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 320 of 320)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 312 of 320)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:sortMenu is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 32 of 320)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 32 of 320)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:style:survey is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:search is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World vehicle large pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World vehicle large wheel: the lowest control mech:inspect is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control of its column equippart:Right Foot and it is in view (bottom 315 of 320)
ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 307 of 320)
ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control of its column health:exercise and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 Char health large wheel: the lowest control health:exercise is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 301 px in a 257 px view
ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control of its column thermal:view and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:view is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control of its column identity:trait:Smoker and it is in view (bottom 315 of 320)
ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Smoker is in view at the bottom (bottom 309 of 320)
ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control of its column journal:__save and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:__save is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control of its column training:col1_Foraging and it is in view (bottom 320 of 320)
ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 312 of 320)
ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control of its column craft:showMenu and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:sortMenu is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control of its column build:showMenu and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World build large wheel: the lowest control build:sortMenu is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control of its column fur:mode:pickup and it is in view (bottom 32 of 320)
ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 32 of 320)
ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control of its column map:style:paper and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:style:survey is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control of its column forage:search and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:search is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control of its column animals:createzone and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 316 of 320)
ZEDQA wpt PASS 7 World vehicle large pad: Down reaches the lowest control of its column mech:inspect and it is in view (bottom 316 of 320)
ZEDQA wpt PASS 7 World vehicle large wheel: the lowest control mech:inspect is in view at the bottom (bottom 316 of 320)
ZEDQA wpt cleanup: crate gone true, size large
ZEDQA wpt 93 passed, 0 failed
ZEDQA wpt DONE
```

### 12. zedqa_probe_skills_down.lua (`ZEDQA pskd`) - PASS, 7 s

- go 17959 at 13:16:43
- screenshots: zqa_pskd_pass2_large.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #12 ok=true
ZEDQA pskd ---- pass1: large text, screen 1280x800, root 0.750
ZEDQA pskd view h 320 | scroll 0.000 | one column false | drawer 414 px
ZEDQA pskd training stops in the ring: 24 of 60 stops in charTabContent
ZEDQA pskd focus on the first col1 training stop: table 0x1372785046{ x=7, y=657.890625, w=189, h=22, id=training:col1_Aiming, trainingId=col1_Aiming, onFocus=closure 0x501219483, onActivate=closure 0x222708006 } -> training:col1_Aiming x 7 y 657.890625 w 189 h 22
ZEDQA pskd Down 1 -> training:col1_Blacksmith x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.617 | one column false | drawer 414 px
ZEDQA pskd Down 2 -> training:col1_Butchering x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.654 | one column false | drawer 414 px
ZEDQA pskd Down 3 -> training:col1_Carpentry x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.691 | one column false | drawer 414 px
ZEDQA pskd Down 4 -> training:col1_Carving x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.728 | one column false | drawer 414 px
ZEDQA pskd Down 5 -> training:col1_Cooking x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.765 | one column false | drawer 414 px
ZEDQA pskd Down 6 -> training:col1_Electricity x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.802 | one column false | drawer 414 px
ZEDQA pskd Down 7 -> training:col1_Farming x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.839 | one column false | drawer 414 px
ZEDQA pskd Down 8 -> training:col1_FirstAid x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.876 | one column false | drawer 414 px
ZEDQA pskd Down 9 -> training:col1_Fishing x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.913 | one column false | drawer 414 px
ZEDQA pskd Down 10 -> training:col1_FlintKnapping x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.950 | one column false | drawer 414 px
ZEDQA pskd Down 11 -> training:col1_Foraging x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 12 -> nil | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 13 -> nil | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 14 -> nil | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd ended on nil | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd text size -> large
ZEDQA pskd ---- pass2_large: large text, screen 1280x800, root 0.750
ZEDQA pskd view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd training stops in the ring: 24 of 60 stops in charTabContent
ZEDQA pskd focus on the first col1 training stop: table 0x1513657541{ x=7, y=45.890625, w=189, h=22, id=training:col1_Aiming, trainingId=col1_Aiming, onFocus=closure 0x881622320, onActivate=closure 0x1687784442 } -> training:col1_Aiming x 7 y 45.890625 w 189 h 22
ZEDQA pskd Down 1 -> training:col1_Blacksmith x 7 y 68.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 2 -> training:col1_Butchering x 7 y 91.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 3 -> training:col1_Carpentry x 7 y 114.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 4 -> training:col1_Carving x 7 y 137.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 5 -> training:col1_Cooking x 7 y 160.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 6 -> training:col1_Electricity x 7 y 183.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 7 -> training:col1_Farming x 7 y 206.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 8 -> training:col1_FirstAid x 7 y 229.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 9 -> training:col1_Fishing x 7 y 252.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 10 -> training:col1_FlintKnapping x 7 y 275.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 11 -> training:col1_Foraging x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 12 -> training:col1_Foraging x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd Down 13 -> training:col1_Foraging x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd ended on training:col1_Foraging x 7 y 298.890625 w 189 h 22 | view h 320 | scroll 0.987 | one column false | drawer 414 px
ZEDQA pskd training stops below the last one: 0
ZEDQA pskd dry run of Down: nil:nil (nil)
ZEDQA pskd stamped training zones this frame: 24 | the first col1_Aiming x 7 y 45.890625 w 189 h 22 | the last col2_Trapping x 205 y 298.890625 w 189 h 22
ZEDQA pskd text size back to large | DONE
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
