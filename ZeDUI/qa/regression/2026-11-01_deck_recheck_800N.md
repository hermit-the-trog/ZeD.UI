# ZeD-UI regression - 2026-11-01 13:17 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-01 13:17:31 |
| Finished | 2026-11-01 13:24:01 (6 min 30 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\deck_recheck_normal_manifest.txt (7 scripts) |
| Result | **3/7 pass**, 2 warn, 0 fail, 1 timeout, 1 not run |
| Go numbers | 17962 to 17969 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_dke_only_race_primani.lua: no DONE within 30 s; the script may still be running in the game
- quit: quit to the main menu, then to the desktop (go 17968, 17969)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_two_widths.lua | tww | WARN | 74 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png | 2 ERR line(s) |
| 3 | zedqa_curtain.lua | cu | WARN | 112 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png | 1 ERR line(s) |
| 4 | zedqa_wheel_icons.lua | wi | PASS | 17 | zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png |  |
| 5 | zedqa_world_pad_take.lua | wpt | PASS | 50 |  |  |
| 6 | zedqa_dke_only_race_primani.lua | dko | **TIMEOUT** | 30 |  | no DONE within 30 s; the script may still be running in the game |
| 7 | zedqa_dash_keys_edge.lua | dke | SKIP |  |  | not run: no DONE within 30 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 17962 at 13:18:31

```text
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 920,13040,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_two_widths.lua (`ZEDQA tww`) - WARN, 74 s

- go 17963 at 13:18:40
- 2 ERR line(s)
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #2 ok=true
ZEDQA tww screen 1280x800, root 0.75, half card 165 px, full card 360 px
ZEDQA tww to the deep run's home, 10608,11151
ZEDQA tww the pair at the start: Character 303,0 333x315, World 644,0 333x315
ZEDQA tww PASS the pair starts apart
ZEDQA tww 13 tab cases
ZEDQA tww Character equip: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character equip: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character equip: it is the full card (full)
ZEDQA tww PASS Character equip: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character equip: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character equip: both windows are on the screen
ZEDQA tww FAIL Character equip: closed, the window is back where and as wide as it was (303,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character equip: closed, the other window is where it was
ZEDQA tww Character health: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character health: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character health: it is the full card (full)
ZEDQA tww PASS Character health: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character health: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character health: both windows are on the screen
ZEDQA tww PASS Character health: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character health: closed, the other window is where it was
ZEDQA tww Character thermal: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character thermal: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character thermal: it is the full card (full)
ZEDQA tww PASS Character thermal: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character thermal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character thermal: both windows are on the screen
ZEDQA tww PASS Character thermal: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character thermal: closed, the other window is where it was
ZEDQA tww Character identity: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character identity: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character identity: it is the full card (full)
ZEDQA tww PASS Character identity: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character identity: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character identity: both windows are on the screen
ZEDQA tww PASS Character identity: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character identity: closed, the other window is where it was
ZEDQA tww Character journal: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character journal: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character journal: it is the full card (full)
ZEDQA tww PASS Character journal: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character journal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character journal: both windows are on the screen
ZEDQA tww PASS Character journal: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character journal: closed, the other window is where it was
ZEDQA tww Character skills: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character skills: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character skills: it is the full card (full)
ZEDQA tww PASS Character skills: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character skills: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character skills: both windows are on the screen
ZEDQA tww PASS Character skills: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character skills: closed, the other window is where it was
ZEDQA tww World craft: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World craft: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World craft: it is the full card (full)
ZEDQA tww PASS World craft: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World craft: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World craft: both windows are on the screen
ZEDQA tww PASS World craft: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World craft: closed, the other window is where it was
ZEDQA tww World build: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World build: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World build: it is the full card (full)
ZEDQA tww PASS World build: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World build: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World build: both windows are on the screen
ZEDQA tww PASS World build: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World build: closed, the other window is where it was
ZEDQA tww World furniture: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World furniture: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World furniture: it is the full card (full)
ZEDQA tww PASS World furniture: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World furniture: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World furniture: both windows are on the screen
ZEDQA tww PASS World furniture: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World furniture: closed, the other window is where it was
ZEDQA tww World maps: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World maps: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World maps: it is the full card (full)
ZEDQA tww PASS World maps: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World maps: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World maps: both windows are on the screen
ZEDQA tww PASS World maps: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World maps: closed, the other window is where it was
ZEDQA tww World forage: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World forage: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World forage: it is the full card (full)
ZEDQA tww PASS World forage: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World forage: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World forage: both windows are on the screen
ZEDQA tww PASS World forage: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World forage: closed, the other window is where it was
ZEDQA tww World animals: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World animals: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World animals: it is the full card (full)
ZEDQA tww PASS World animals: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World animals: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World animals: both windows are on the screen
ZEDQA tww PASS World animals: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World animals: closed, the other window is where it was
ZEDQA tww World vehicle: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World vehicle: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World vehicle: it is the full card (full)
ZEDQA tww PASS World vehicle: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World vehicle: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World vehicle: both windows are on the screen
ZEDQA tww PASS World vehicle: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World vehicle: closed, the other window is where it was
ZEDQA tww an oven placed: true
ZEDQA tww a generator placed: true
ZEDQA tww a ham set placed: true
ZEDQA tww 26 more cases
ZEDQA tww Character Equip to-do: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character Equip to-do: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character Equip to-do: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Equip to-do: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Equip to-do: both windows are on the screen
ZEDQA tww PASS Character Equip to-do: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Equip to-do: closed, the other window is where it was
ZEDQA tww Character Journal Loadouts page: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character Journal Loadouts page: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character Journal Loadouts page: it is the full card (full)
ZEDQA tww PASS Character Journal Loadouts page: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Journal Loadouts page: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal Loadouts page: both windows are on the screen
ZEDQA tww PASS Character Journal Loadouts page: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Journal Loadouts page: closed, the other window is where it was
ZEDQA tww Character Journal page 1: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character Journal page 1: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character Journal page 1: it is the full card (full)
ZEDQA tww PASS Character Journal page 1: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Journal page 1: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 1: both windows are on the screen
ZEDQA tww PASS Character Journal page 1: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Journal page 1: closed, the other window is where it was
ZEDQA tww Character Journal page 2: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character Journal page 2: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character Journal page 2: it is the full card (full)
ZEDQA tww PASS Character Journal page 2: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Journal page 2: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 2: both windows are on the screen
ZEDQA tww PASS Character Journal page 2: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Journal page 2: closed, the other window is where it was
ZEDQA tww Character Journal page 3: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character Journal page 3: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character Journal page 3: it is the full card (full)
ZEDQA tww PASS Character Journal page 3: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Journal page 3: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 3: both windows are on the screen
ZEDQA tww PASS Character Journal page 3: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Journal page 3: closed, the other window is where it was
ZEDQA tww Character Journal page 4: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character Journal page 4: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character Journal page 4: it is the full card (full)
ZEDQA tww PASS Character Journal page 4: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Journal page 4: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 4: both windows are on the screen
ZEDQA tww PASS Character Journal page 4: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Journal page 4: closed, the other window is where it was
ZEDQA tww Character Journal page 5: drawer 360 px = full | Character 0,0 640x315 | World 644,0 333x315
ZEDQA tww PASS Character Journal page 5: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS Character Journal page 5: it is the full card (full)
ZEDQA tww PASS Character Journal page 5: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Journal page 5: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Journal page 5: both windows are on the screen
ZEDQA tww PASS Character Journal page 5: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Journal page 5: closed, the other window is where it was
ZEDQA tww World item card: drawer 165 px = half | Character 307,0 333x315 | World 644,0 498x315
ZEDQA tww PASS World item card: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS World item card: it is the half card (half)
ZEDQA tww PASS World item card: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World item card: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS World item card: both windows are on the screen
ZEDQA tww PASS World item card: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World item card: closed, the other window is where it was
ZEDQA tww Character item card: drawer 165 px = half | Character 142,0 498x315 | World 644,0 333x315
ZEDQA tww PASS Character item card: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS Character item card: it is the half card (half)
ZEDQA tww PASS Character item card: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character item card: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character item card: both windows are on the screen
ZEDQA tww PASS Character item card: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character item card: closed, the other window is where it was
ZEDQA tww World object card fluid: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World object card fluid: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World object card fluid: it is the full card (full)
ZEDQA tww PASS World object card fluid: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World object card fluid: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World object card fluid: both windows are on the screen
ZEDQA tww PASS World object card fluid: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World object card fluid: closed, the other window is where it was
ZEDQA tww World object card generator: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World object card generator: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World object card generator: it is the full card (full)
ZEDQA tww PASS World object card generator: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World object card generator: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World object card generator: both windows are on the screen
ZEDQA tww PASS World object card generator: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World object card generator: closed, the other window is where it was
ZEDQA tww World object card place3d: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World object card place3d: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World object card place3d: it is the full card (full)
ZEDQA tww PASS World object card place3d: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World object card place3d: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World object card place3d: both windows are on the screen
ZEDQA tww PASS World object card place3d: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World object card place3d: closed, the other window is where it was
ZEDQA tww World Craft at an oven: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World Craft at an oven: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World Craft at an oven: it is the full card (full)
ZEDQA tww PASS World Craft at an oven: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World Craft at an oven: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Craft at an oven: both windows are on the screen
ZEDQA tww PASS World Craft at an oven: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World Craft at an oven: closed, the other window is where it was
ZEDQA tww World Craft (no station): drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World Craft (no station): the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World Craft (no station): it is the full card (full)
ZEDQA tww PASS World Craft (no station): the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World Craft (no station): the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Craft (no station): both windows are on the screen
ZEDQA tww PASS World Craft (no station): closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World Craft (no station): closed, the other window is where it was
ZEDQA tww Character Radio (a walkie): drawer 165 px = half | Character 142,0 498x315 | World 644,0 333x315
ZEDQA tww PASS Character Radio (a walkie): the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS Character Radio (a walkie): it is the half card (half)
ZEDQA tww PASS Character Radio (a walkie): the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS Character Radio (a walkie): the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS Character Radio (a walkie): both windows are on the screen
ZEDQA tww PASS Character Radio (a walkie): closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS Character Radio (a walkie): closed, the other window is where it was
ZEDQA tww World Radio (a ham set): drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World Radio (a ham set): the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World Radio (a ham set): the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World Radio (a ham set): the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Radio (a ham set): both windows are on the screen
ZEDQA tww PASS World Radio (a ham set): closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World Radio (a ham set): closed, the other window is where it was
ZEDQA tww World Maps: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World Maps: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World Maps: it is the full card (full)
ZEDQA tww PASS World Maps: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World Maps: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Maps: both windows are on the screen
ZEDQA tww PASS World Maps: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World Maps: closed, the other window is where it was
ZEDQA tww World Maps pop-out: drawer 360 px = full | Character 307,0 333x315 | World 640,0 640x315
ZEDQA tww PASS World Maps pop-out: the drawer is the half card or the full card (360 px; half 165, full 360)
ZEDQA tww PASS World Maps pop-out: it is the full card (full)
ZEDQA tww PASS World Maps pop-out: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS World Maps pop-out: the windows do not overlap (Character ends at 640, World starts at 640)
ZEDQA tww PASS World Maps pop-out: both windows are on the screen
ZEDQA tww the pop-out 179,88 921x624: over the Character window true, over the World window true (it is a window of its own, centred)
ZEDQA tww PASS World Maps pop-out: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS World Maps pop-out: closed, the other window is where it was
ZEDQA tww 15 held-in cases
ZEDQA tww held in: Character equip: drawer 165 px = half | Character 211,0 429x315 | World 644,0 333x315
ZEDQA tww PASS held in: Character equip: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: Character equip: it is the half card (half)
ZEDQA tww PASS held in: Character equip: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: Character equip: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character equip: both windows are on the screen
ZEDQA tww PASS held in: Character equip: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: Character equip: closed, the other window is where it was
ZEDQA tww held in: Character health: drawer 165 px = half | Character 211,0 429x315 | World 644,0 333x315
ZEDQA tww PASS held in: Character health: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: Character health: it is the half card (half)
ZEDQA tww PASS held in: Character health: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: Character health: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character health: both windows are on the screen
ZEDQA tww PASS held in: Character health: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: Character health: closed, the other window is where it was
ZEDQA tww held in: Character thermal: drawer 165 px = half | Character 211,0 429x315 | World 644,0 333x315
ZEDQA tww PASS held in: Character thermal: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: Character thermal: it is the half card (half)
ZEDQA tww PASS held in: Character thermal: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: Character thermal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character thermal: both windows are on the screen
ZEDQA tww PASS held in: Character thermal: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: Character thermal: closed, the other window is where it was
ZEDQA tww held in: Character identity: drawer 165 px = half | Character 211,0 429x315 | World 644,0 333x315
ZEDQA tww PASS held in: Character identity: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: Character identity: it is the half card (half)
ZEDQA tww PASS held in: Character identity: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: Character identity: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character identity: both windows are on the screen
ZEDQA tww PASS held in: Character identity: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: Character identity: closed, the other window is where it was
ZEDQA tww held in: Character journal: drawer 165 px = half | Character 211,0 429x315 | World 644,0 333x315
ZEDQA tww PASS held in: Character journal: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: Character journal: it is the half card (half)
ZEDQA tww PASS held in: Character journal: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: Character journal: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character journal: both windows are on the screen
ZEDQA tww PASS held in: Character journal: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: Character journal: closed, the other window is where it was
ZEDQA tww held in: Character skills: drawer 165 px = half | Character 211,0 429x315 | World 644,0 333x315
ZEDQA tww PASS held in: Character skills: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: Character skills: it is the half card (half)
ZEDQA tww PASS held in: Character skills: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: Character skills: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character skills: both windows are on the screen
ZEDQA tww PASS held in: Character skills: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: Character skills: closed, the other window is where it was
ZEDQA tww held in: Character radio: drawer 165 px = half | Character 211,0 429x315 | World 644,0 333x315
ZEDQA tww PASS held in: Character radio: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: Character radio: it is the half card (half)
ZEDQA tww PASS held in: Character radio: the other window did not move or change size (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: Character radio: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: Character radio: both windows are on the screen
ZEDQA tww PASS held in: Character radio: closed, the window is back where and as wide as it was (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: Character radio: closed, the other window is where it was
ZEDQA tww held in: World craft: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World craft: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World craft: it is the half card (half)
ZEDQA tww PASS held in: World craft: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World craft: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World craft: both windows are on the screen
ZEDQA tww PASS held in: World craft: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World craft: closed, the other window is where it was
ZEDQA tww held in: World build: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World build: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World build: it is the half card (half)
ZEDQA tww PASS held in: World build: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World build: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World build: both windows are on the screen
ZEDQA tww PASS held in: World build: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World build: closed, the other window is where it was
ZEDQA tww held in: World furniture: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World furniture: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World furniture: it is the half card (half)
ZEDQA tww PASS held in: World furniture: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World furniture: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World furniture: both windows are on the screen
ZEDQA tww PASS held in: World furniture: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World furniture: closed, the other window is where it was
ZEDQA tww held in: World maps: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World maps: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World maps: it is the half card (half)
ZEDQA tww PASS held in: World maps: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World maps: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World maps: both windows are on the screen
ZEDQA tww PASS held in: World maps: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World maps: closed, the other window is where it was
ZEDQA tww held in: World forage: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World forage: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World forage: it is the half card (half)
ZEDQA tww PASS held in: World forage: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World forage: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World forage: both windows are on the screen
ZEDQA tww PASS held in: World forage: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World forage: closed, the other window is where it was
ZEDQA tww held in: World animals: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World animals: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World animals: it is the half card (half)
ZEDQA tww PASS held in: World animals: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World animals: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World animals: both windows are on the screen
ZEDQA tww PASS held in: World animals: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World animals: closed, the other window is where it was
ZEDQA tww held in: World radio: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World radio: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World radio: it is the half card (half)
ZEDQA tww PASS held in: World radio: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World radio: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World radio: both windows are on the screen
ZEDQA tww PASS held in: World radio: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World radio: closed, the other window is where it was
ZEDQA tww held in: World vehicle: drawer 165 px = half | Character 307,0 333x315 | World 644,0 429x315
ZEDQA tww PASS held in: World vehicle: the drawer is the half card or the full card (165 px; half 165, full 360)
ZEDQA tww PASS held in: World vehicle: it is the half card (half)
ZEDQA tww PASS held in: World vehicle: the other window did not move or change size (307,0 333x315 -> 307,0 333x315)
ZEDQA tww PASS held in: World vehicle: the windows do not overlap (Character ends at 640, World starts at 644)
ZEDQA tww PASS held in: World vehicle: both windows are on the screen
ZEDQA tww PASS held in: World vehicle: closed, the window is back where and as wide as it was (644,0 333x315 -> 644,0 333x315)
ZEDQA tww PASS held in: World vehicle: closed, the other window is where it was
ERROR: General f:7965 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:7974 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA tww FAIL after the whole run both windows are where and as big as they were (303,0 333x315 / 644,0 333x315 -> 307,0 333x315 / 644,0 333x315)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card laundry, World object card lock, World object card plant, World object card track, World object card trough
ZEDQA tww 2 FAILED
ZEDQA tww DONE
```

### 3. zedqa_curtain.lua (`ZEDQA cu`) - WARN, 112 s

- go 17964 at 13:19:57
- 1 ERR line(s)
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #3 ok=true
ZEDQA cu loaded: Character 303,0 333x315 rolled nil (saved -) | World 644,0 333x315 rolled nil (saved -)
ZEDQA cu scale 0.75 root 0.75 screen 1280x800
ZEDQA cu reset: ZeD_Window.resetLayout
ZEDQA cu reset: Character 303,0 333x315 rolled nil (saved -) | World 644,0 333x315 rolled nil (saved -)
ZEDQA cu before: x 640 w 640 title Ground + Maps button 105.83203125,5 10
ZEDQA cu rolled true: x 893 w 387 (sum 1280 was 1280) rod 640,0 253x20 content false title Maps
ZEDQA cu pad stops: worldContainerStrip:curtain:unroll
ZEDQA cu A on the tab
ZEDQA cu unrolled true: x 640 w 640 content true rod false
ZEDQA cu ok first roll World 640,0 640x315
ZEDQA cu rolled again true
ZEDQA cu tab closed: rolled false x 644 w 333 content true drawer false
ZEDQA cu ok tab closed while rolled World 644,0 333x315
ZEDQA cu World before: 640,0 640x315 (other 303,0 333x315) drawer true tab tab maps
ZEDQA cu cycle1 World before roll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rollW 253
ZEDQA cu ok cycle1 rolled World rod flush at 640,0 253x20
ZEDQA cu ok cycle1 rolled World 893,0 387x315
ZEDQA cu ok cycle1 while rolled: other Character 303,0 333x315
ZEDQA cu cycle1 World rolled, before unroll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World unrolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 World 640,0 640x315
ZEDQA cu ok cycle1 other (Character) 303,0 333x315
ZEDQA cu ok cycle1 World saved 853.333,0.000 444.000x420.000
ZEDQA cu cycle2 World before roll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rollW 253
ZEDQA cu ok cycle2 rolled World rod flush at 640,0 253x20
ZEDQA cu ok cycle2 rolled World 893,0 387x315
ZEDQA cu ok cycle2 while rolled: other Character 303,0 333x315
ZEDQA cu cycle2 World rolled, before unroll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World unrolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 World 640,0 640x315
ZEDQA cu ok cycle2 other (Character) 303,0 333x315
ZEDQA cu ok cycle2 World saved 853.333,0.000 444.000x420.000
ZEDQA cu moved by rod World before roll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,0 640x315 rolled false (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,0 387x315 rolled true (saved 853.333,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rollW 253
ZEDQA cu ok moved by rod rolled World rod flush at 640,0 253x20
ZEDQA cu ok moved by rod rolled World 893,0 387x315
ZEDQA cu ok moved by rod while rolled: other Character 303,0 333x315
ZEDQA cu moved by rod World moved by -200,200 (rod) to 693,200 387x315
ZEDQA cu ok moved by rod moved World rod flush at 440,200 253x20
ZEDQA cu moved by rod World rolled, before unroll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 693,200 387x315 rolled true (saved 586.667,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World unrolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 440,200 640x315 rolled false (saved 586.667,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod World 440,200 640x315
ZEDQA cu ok moved by rod other (Character) 303,0 333x315
ZEDQA cu ok moved by rod World saved 586.667,266.667 444.000x420.000
ZEDQA cu moved by title World before roll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 440,200 640x315 rolled false (saved 586.667,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 693,200 387x315 rolled true (saved 586.667,266.667 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rollW 253
ZEDQA cu ok moved by title rolled World rod flush at 440,200 253x20
ZEDQA cu ok moved by title rolled World 693,200 387x315
ZEDQA cu ok moved by title while rolled: other Character 303,0 333x315
ZEDQA cu moved by title World moved by 200,200 (title) to 893,400 387x315
ZEDQA cu ok moved by title moved World rod flush at 640,400 253x20
ZEDQA cu moved by title World rolled, before unroll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,400 387x315 rolled true (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World unrolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title World 640,400 640x315
ZEDQA cu ok moved by title other (Character) 303,0 333x315
ZEDQA cu ok moved by title World saved 853.333,533.333 444.000x420.000
ZEDQA cu cycle5 World before roll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,400 387x315 rolled true (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rollW 253
ZEDQA cu ok cycle5 rolled World rod flush at 640,400 253x20
ZEDQA cu ok cycle5 rolled World 893,400 387x315
ZEDQA cu ok cycle5 while rolled: other Character 303,0 333x315
ZEDQA cu cycle5 World rolled, before unroll: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 893,400 387x315 rolled true (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World unrolled: Character 303,0 333x315 rolled nil (saved 404.000,0.000 444.000x420.000 anchor 848.000 tab loot drawer false) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 World 640,400 640x315
ZEDQA cu ok cycle5 other (Character) 303,0 333x315
ZEDQA cu ok cycle5 World saved 853.333,533.333 444.000x420.000
ZEDQA cu character health tab true
ZEDQA cu Character before: 0,0 640x315 (other 640,400 640x315) drawer true tab tab health
ZEDQA cu cycle1 Character before roll: Character 0,0 640x315 rolled nil (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rolled: Character 0,0 387x315 rolled true (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rollW 253
ZEDQA cu ok cycle1 rolled Character rod flush at 387,0 253x20
ZEDQA cu ok cycle1 rolled Character 0,0 387x315
ZEDQA cu ok cycle1 while rolled: other World 640,400 640x315
ZEDQA cu cycle1 Character rolled, before unroll: Character 0,0 387x315 rolled true (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character unrolled: Character 0,0 640x315 rolled false (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 Character 0,0 640x315
ZEDQA cu ok cycle1 other (World) 640,400 640x315
ZEDQA cu ok cycle1 Character saved 409.333,0.000 444.000x420.000
ZEDQA cu cycle2 Character before roll: Character 0,0 640x315 rolled false (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rolled: Character 0,0 387x315 rolled true (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rollW 253
ZEDQA cu ok cycle2 rolled Character rod flush at 387,0 253x20
ZEDQA cu ok cycle2 rolled Character 0,0 387x315
ZEDQA cu ok cycle2 while rolled: other World 640,400 640x315
ZEDQA cu cycle2 Character rolled, before unroll: Character 0,0 387x315 rolled true (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character unrolled: Character 0,0 640x315 rolled false (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 Character 0,0 640x315
ZEDQA cu ok cycle2 other (World) 640,400 640x315
ZEDQA cu ok cycle2 Character saved 409.333,0.000 444.000x420.000
ZEDQA cu moved by rod Character before roll: Character 0,0 640x315 rolled false (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rolled: Character 0,0 387x315 rolled true (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rollW 253
ZEDQA cu ok moved by rod rolled Character rod flush at 387,0 253x20
ZEDQA cu ok moved by rod rolled Character 0,0 387x315
ZEDQA cu ok moved by rod while rolled: other World 640,400 640x315
ZEDQA cu moved by rod Character moved by 200,200 (rod) to 200,200 387x315
ZEDQA cu ok moved by rod moved Character rod flush at 587,200 253x20
ZEDQA cu moved by rod Character rolled, before unroll: Character 200,200 387x315 rolled true (saved 409.333,0.000 444.000x420.000 anchor 853.333 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character unrolled: Character 200,200 640x315 rolled false (saved 676.000,266.667 444.000x420.000 anchor 1120.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod Character 200,200 640x315
ZEDQA cu ok moved by rod other (World) 640,400 640x315
ZEDQA cu ok moved by rod Character saved 676.000,266.667 444.000x420.000
ZEDQA cu moved by title Character before roll: Character 200,200 640x315 rolled false (saved 676.000,266.667 444.000x420.000 anchor 1120.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rolled: Character 200,200 387x315 rolled true (saved 676.000,266.667 444.000x420.000 anchor 1120.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rollW 253
ZEDQA cu ok moved by title rolled Character rod flush at 587,200 253x20
ZEDQA cu ok moved by title rolled Character 200,200 387x315
ZEDQA cu ok moved by title while rolled: other World 640,400 640x315
ZEDQA cu moved by title Character moved by 200,200 (title) to 400,400 387x315
ZEDQA cu ok moved by title moved Character rod flush at 787,400 253x20
ZEDQA cu moved by title Character rolled, before unroll: Character 400,400 387x315 rolled true (saved 676.000,266.667 444.000x420.000 anchor 1120.000 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character unrolled: Character 400,400 640x315 rolled false (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title Character 400,400 640x315
ZEDQA cu ok moved by title other (World) 640,400 640x315
ZEDQA cu ok moved by title Character saved 942.667,533.333 444.000x420.000
ZEDQA cu cycle5 Character before roll: Character 400,400 640x315 rolled false (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rolled: Character 400,400 387x315 rolled true (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rollW 253
ZEDQA cu ok cycle5 rolled Character rod flush at 787,400 253x20
ZEDQA cu ok cycle5 rolled Character 400,400 387x315
ZEDQA cu ok cycle5 while rolled: other World 640,400 640x315
ZEDQA cu cycle5 Character rolled, before unroll: Character 400,400 387x315 rolled true (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character unrolled: Character 400,400 640x315 rolled false (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 Character 400,400 640x315
ZEDQA cu ok cycle5 other (World) 640,400 640x315
ZEDQA cu ok cycle5 Character saved 942.667,533.333 444.000x420.000
ZEDQA cu closed rolled (inventory key) World reference, closed and reopened unrolled: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab World 640,400 640x315
ZEDQA cu closed rolled (inventory key) World before roll: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (inventory key) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) World window closed
ZEDQA cu ok closed rolled (inventory key) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) World reopened: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled World 640,400 333x315
ZEDQA cu ok closed rolled (inventory key) reopened: other Character 400,400 640x315
ZEDQA cu closed rolled (rod close box) World reference, closed and reopened unrolled: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) reference back on its tab World 640,400 640x315
ZEDQA cu closed rolled (rod close box) World before roll: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (rod close box) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (rod close box) World window closed
ZEDQA cu ok closed rolled (rod close box) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (rod close box) World reopened: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (rod close box) reopened as unrolled World 640,400 333x315
ZEDQA cu ok closed rolled (rod close box) reopened: other Character 400,400 640x315
ZEDQA cu closed rolled (controller Y hold) World reference, closed and reopened unrolled: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab World 640,400 640x315
ZEDQA cu closed rolled (controller Y hold) World before roll: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (controller Y hold) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) World window closed
ZEDQA cu ok closed rolled (controller Y hold) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) World reopened: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled World 640,400 333x315
ZEDQA cu ok closed rolled (controller Y hold) reopened: other Character 400,400 640x315
ZEDQA cu closed rolled (inventory key) Character reference, closed and reopened unrolled: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab Character 400,400 640x315
ZEDQA cu closed rolled (inventory key) Character before roll: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) Character window closed
ZEDQA cu ok closed rolled (inventory key) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) Character reopened: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled Character 400,400 640x315
ZEDQA cu ok closed rolled (inventory key) reopened: other World 640,400 333x315
ZEDQA cu closed rolled (close box) Character reference, closed and reopened unrolled: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) reference back on its tab Character 400,400 640x315
ZEDQA cu closed rolled (close box) Character before roll: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (close box) Character window closed
ZEDQA cu ok closed rolled (close box) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (close box) Character reopened: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (close box) reopened as unrolled Character 400,400 640x315
ZEDQA cu ok closed rolled (close box) reopened: other World 640,400 333x315
ZEDQA cu closed rolled (controller Y hold) Character reference, closed and reopened unrolled: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab Character 400,400 640x315
ZEDQA cu closed rolled (controller Y hold) Character before roll: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) Character window closed
ZEDQA cu ok closed rolled (controller Y hold) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) Character reopened: Character 400,400 640x315 rolled nil (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 333x315 rolled nil (saved 853.333,533.333 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled Character 400,400 640x315
ZEDQA cu ok closed rolled (controller Y hold) reopened: other World 640,400 333x315
ZEDQA cu World tabs: on maps 640,400 640x315 (other 400,400 640x315)
ZEDQA cu ok tab forage reference, back on maps World 640,400 640x315
ZEDQA cu ok tab forage World rolled before the press
ZEDQA cu ok tab forage World still rolled on the tab (tab forage)
ZEDQA cu ok tab forage rolled World 893,400 387x315
ZEDQA cu ok tab forage World unrolled (rods in UI 0)
ZEDQA cu ok tab forage unrolled World 640,400 640x315
ZEDQA cu ok tab forage unrolled: other Character 400,400 640x315
ZEDQA cu ok tab forage back on maps World 640,400 640x315
ZEDQA cu ok tab craft reference, back on maps World 640,400 640x315
ZEDQA cu ok tab craft World rolled before the press
ZEDQA cu ok tab craft World still rolled on the tab (tab craft)
ZEDQA cu ok tab craft rolled World 893,400 387x315
ZEDQA cu ok tab craft World unrolled (rods in UI 0)
ZEDQA cu ok tab craft unrolled World 640,400 640x315
ZEDQA cu ok tab craft unrolled: other Character 400,400 640x315
ZEDQA cu ok tab craft back on maps World 640,400 640x315
ZEDQA cu ok tab build reference, back on maps World 640,400 640x315
ZEDQA cu ok tab build World rolled before the press
ZEDQA cu ok tab build World still rolled on the tab (tab build)
ZEDQA cu ok tab build rolled World 893,400 387x315
ZEDQA cu ok tab build World unrolled (rods in UI 0)
ZEDQA cu ok tab build unrolled World 640,400 640x315
ZEDQA cu ok tab build unrolled: other Character 400,400 640x315
ZEDQA cu ok tab build back on maps World 640,400 640x315
ZEDQA cu ok tab furniture reference, back on maps World 640,400 640x315
ZEDQA cu ok tab furniture World rolled before the press
ZEDQA cu ok tab furniture World still rolled on the tab (tab furniture)
ZEDQA cu ok tab furniture rolled World 893,400 387x315
ZEDQA cu ok tab furniture World unrolled (rods in UI 0)
ZEDQA cu ok tab furniture unrolled World 640,400 640x315
ZEDQA cu ok tab furniture unrolled: other Character 400,400 640x315
ZEDQA cu ok tab furniture back on maps World 640,400 640x315
ZEDQA cu ok tab animals reference, back on maps World 640,400 640x315
ZEDQA cu ok tab animals World rolled before the press
ZEDQA cu ok tab animals World still rolled on the tab (tab animals)
ZEDQA cu ok tab animals rolled World 893,400 387x315
ZEDQA cu ok tab animals World unrolled (rods in UI 0)
ZEDQA cu ok tab animals unrolled World 640,400 640x315
ZEDQA cu ok tab animals unrolled: other Character 400,400 640x315
ZEDQA cu ok tab animals back on maps World 640,400 640x315
ZEDQA cu tab radio World: not shown here, skipped
ZEDQA cu ok tab vehicle reference, back on maps World 640,400 640x315
ZEDQA cu ok tab vehicle World rolled before the press
ZEDQA cu ok tab vehicle World still rolled on the tab (tab vehicle)
ZEDQA cu ok tab vehicle rolled World 893,400 387x315
ZEDQA cu ok tab vehicle World unrolled (rods in UI 0)
ZEDQA cu ok tab vehicle unrolled World 640,400 640x315
ZEDQA cu ok tab vehicle unrolled: other Character 400,400 640x315
ZEDQA cu ok tab vehicle back on maps World 640,400 640x315
ZEDQA cu ok forage and back World still rolled (tab maps)
ZEDQA cu ok forage and back rolled World 893,400 387x315
ZEDQA cu ok forage and back, unrolled World 640,400 640x315
ZEDQA cu World Loot (unrolled) 640,400 333x315
ZEDQA cu ok Loot reference, back on maps World 640,400 640x315
ZEDQA cu ok Loot World rolled before the press
ZEDQA cu FAIL Loot World side down with the press: rolled false tab loot rods in UI 1
ZEDQA cu ok Loot while rolled World 640,400 333x315
ZEDQA cu ok Loot while rolled: other Character 400,400 640x315
ZEDQA cu ok Loot while rolled, back on maps World 640,400 640x315
ZEDQA cu ok maps again World rolled before the press
ZEDQA cu ok maps again World side down (rolled false)
ZEDQA cu ok maps pressed again while rolled World 640,400 333x315
ZEDQA cu ok maps again, back on maps World 640,400 640x315
ZEDQA cu Character tabs: on health 400,400 640x315 (other 640,400 640x315)
ZEDQA cu ok tab skills reference, back on health Character 400,400 640x315
ZEDQA cu ok tab skills Character rolled before the press
ZEDQA cu ok tab skills Character still rolled on the tab (tab skills)
ZEDQA cu ok tab skills rolled Character 400,400 387x315
ZEDQA cu ok tab skills Character unrolled (rods in UI 0)
ZEDQA cu ok tab skills unrolled Character 400,400 640x315
ZEDQA cu ok tab skills unrolled: other World 640,400 640x315
ZEDQA cu ok tab skills back on health Character 400,400 640x315
ZEDQA cu ok tab equip reference, back on health Character 400,400 640x315
ZEDQA cu ok tab equip Character rolled before the press
ZEDQA cu ok tab equip Character still rolled on the tab (tab equip)
ZEDQA cu ok tab equip rolled Character 400,400 387x315
ZEDQA cu ok tab equip Character unrolled (rods in UI 0)
ZEDQA cu ok tab equip unrolled Character 400,400 640x315
ZEDQA cu ok tab equip unrolled: other World 640,400 640x315
ZEDQA cu ok tab equip back on health Character 400,400 640x315
ZEDQA cu ok tab thermal reference, back on health Character 400,400 640x315
ZEDQA cu ok tab thermal Character rolled before the press
ZEDQA cu ok tab thermal Character still rolled on the tab (tab thermal)
ZEDQA cu ok tab thermal rolled Character 400,400 387x315
ZEDQA cu ok tab thermal Character unrolled (rods in UI 0)
ZEDQA cu ok tab thermal unrolled Character 400,400 640x315
ZEDQA cu ok tab thermal unrolled: other World 640,400 640x315
ZEDQA cu ok tab thermal back on health Character 400,400 640x315
ZEDQA cu ok tab identity reference, back on health Character 400,400 640x315
ZEDQA cu ok tab identity Character rolled before the press
ZEDQA cu ok tab identity Character still rolled on the tab (tab identity)
ZEDQA cu ok tab identity rolled Character 400,400 387x315
ZEDQA cu ok tab identity Character unrolled (rods in UI 0)
ZEDQA cu ok tab identity unrolled Character 400,400 640x315
ZEDQA cu ok tab identity unrolled: other World 640,400 640x315
ZEDQA cu ok tab identity back on health Character 400,400 640x315
ZEDQA cu ok tab journal reference, back on health Character 400,400 640x315
ZEDQA cu ok tab journal Character rolled before the press
ZEDQA cu ok tab journal Character still rolled on the tab (tab journal)
ZEDQA cu ok tab journal rolled Character 400,400 387x315
ZEDQA cu ok tab journal Character unrolled (rods in UI 0)
ZEDQA cu ok tab journal unrolled Character 400,400 640x315
ZEDQA cu ok tab journal unrolled: other World 640,400 640x315
ZEDQA cu ok tab journal back on health Character 400,400 640x315
ZEDQA cu tab radio Character: not shown here, skipped
ZEDQA cu ok skills and back Character still rolled (tab health)
ZEDQA cu ok skills and back rolled Character 400,400 387x315
ZEDQA cu ok skills and back, unrolled Character 400,400 640x315
ZEDQA cu Character Loot (unrolled) 707,400 333x315
ZEDQA cu ok Loot reference, back on health Character 400,400 640x315
ZEDQA cu ok Loot Character rolled before the press
ZEDQA cu ok Loot Character side down with the press (rolled false tab loot rods in UI 0)
ZEDQA cu ok Loot while rolled Character 707,400 333x315
ZEDQA cu ok Loot while rolled: other World 640,400 640x315
ZEDQA cu ok Loot while rolled, back on health Character 400,400 640x315
ZEDQA cu ok health again Character rolled before the press
ZEDQA cu ok health again Character side down (rolled false)
ZEDQA cu ok health pressed again while rolled Character 707,400 333x315
ZEDQA cu ok health again, back on health Character 400,400 640x315
ZEDQA cu geometry checks 222, differences 1
ZEDQA cu at quit, unrolled: Character 400,400 640x315 rolled false (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 640,400 640x315 rolled false (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu at quit, rolled: Character 400,400 387x315 rolled true (saved 942.667,533.333 444.000x420.000 anchor 1386.667 tab health drawer true) | World 893,400 387x315 rolled true (saved 853.333,533.333 444.000x420.000 tab maps drawer true)
ZEDQA cu DONE
```

### 4. zedqa_wheel_icons.lua (`ZEDQA wi`) - PASS, 17 s

- go 17965 at 13:21:53
- screenshots: zqa_wi_dpad_left.png, zqa_wi_dpad_right.png, zqa_wi_dpad_up.png, zqa_wi_dpad_down.png, zqa_wi_dpad_select.png, zqa_wi_dpad_left_use.png, zqa_wi_dpad_down_speed.png, zqa_wi_dpad_down_view.png, zqa_wi_dpad_select_theme.png, zqa_wi_emotes.png, zqa_wi_emotes_friendly.png, zqa_wi_emotes_hostile.png, zqa_wi_emotes_group.png, zqa_wi_emotes_signal.png, zqa_wi_gun.png, zqa_wi_light.png, zqa_wi_stick.png, zqa_wi_vanilla_back.png, zqa_wi_vanilla_dright.png, zqa_wi_car_outside.png, zqa_wi_car_inside.png, zqa_wi_dpad_left_1x.png, zqa_wi_dpad_right_1x.png, zqa_wi_dpad_up_1x.png, zqa_wi_dpad_down_1x.png, zqa_wi_dpad_select_1x.png, zqa_wi_emotes_1x.png, zqa_wi_gun_1x.png, zqa_wi_light_1x.png, zqa_wi_stick_1x.png, zqa_wi_car_inside_1x.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wi no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wi start car=BaseVehicle{ Name:null, ID:109 }
[ZeD.QA] run #4 ok=true
ZEDQA wi scene: screen 1280x800, scale option 1, icon box 12 at rest, 18 pointed
ZEDQA wi PASS all 153 icons load at 16, 24, 32 and 48, each its own file (0 problems)
ZEDQA wi PASS the drawing for each box: the largest that fits, at its own size; under 16 the 16 scaled down
ZEDQA wi at this scale: box 12 draws the 12, box 18 draws the 16
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
ZEDQA wi PASS dpad_left: 9 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Light/No light on you.=bulb_on
ZEDQA wi PASS dpad_down: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
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
ZEDQA wi car_outside: 3 slices | 1:Vehicle Mechanics=engine 2:Enter Vehicle=car_enter 3:Need a hose.=gas_siphon
ZEDQA wi PASS car_outside: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi PASS in the car: the dashboard slice has the gauge (gauge)
ZEDQA wi car_inside: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside: 13 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi PASS vanilla's radials and ZeD's wheels, live: 124 slices, 122 wheel icons, 2 kept pictures
ZEDQA wi now at 1x (text size small): icon box 12 at rest, 18 pointed
ZEDQA wi dpad_left_1x: 9 slices | 1:Tabs/Character window=crate 2:Weapons=knife 3:Eat=apple 4:Drink/Nothing to drink on you.=glass 5:Medicine and first aid=medkit 6:Sleep/Not tired enough to sleep.=bed 7:Clothing/Nothing you wear can change.=shirt 8:Use/Smoke | Read | Watch | Radio=backpack 9:Loadouts/No loadouts saved=view_list
ZEDQA wi PASS dpad_left_1x: 9 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_right_1x: 8 slices | 1:Tabs/World window=craft 2:Map=map 3:Vehicle/No vehicle in reach.=car 4:Animal/No tame animal in reach.=cow 5:Craft and build=toolbox 6:Search=magnifier 7:Lights and power/No lights or power in reach.=bulb_on 8:Designated Zones/Animals=fence
ZEDQA wi PASS dpad_right_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_up_1x: 8 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn 6:Chat/On a server only.=chat 7:Safety/On a server only.=padlock 8:Players/On a server only.=group
ZEDQA wi PASS dpad_up_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_down_1x: 8 slices | 1:Sit=sit_ground 2:Crouch/Off=sneak 3:Auto-walk/Off=autowalk 4:Game speed=ff1 5:Zoom=zoom_in 6:View/Interface and windows=eye 7:Help=help 8:Flashlight/Turn on=bulb_on
ZEDQA wi PASS dpad_down_1x: 8 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi dpad_select_1x: 12 slices | 1:Base theme/Dark=theme 3:Text size/Small=textsize 4:See-through/90%=seethrough 5:Controller highlight/Pointing hand=focus 6:UI scale=scale 7:Moodles/Right edge=smiley 8:Action bar/Verbose=progress 9:Messages/No messages.=inbox 10:Reset windows/Both windows back to where they start=rotate 11:ZeD setup/Options, on ZeD's page=gears 12:Safe mode/The game's own interface=safemode
ZEDQA wi PASS dpad_select_1x: 11 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi emotes_1x: 5 slices | 1:Friendly=thumbs_up 2:Hostile=thumbs_down 3:Group=group 4:Signal=move_out 5:Shout=bullhorn
ZEDQA wi PASS emotes_1x: 5 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi gun_1x: 3 slices | 1:Insert Magazine/(0 / 15)=mag_in 2:Load Bullets into/Spare Magazine/(0 / 15)=rounds_mag
ZEDQA wi PASS gun_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi light_1x: 4 slices | 1:Lighter/Equip Primary=keep?item_lighter 2:Lighter/Equip Secondary=keep?item_lighter 3:Flashlight/Unequip=minus 4:Flashlight/Turn on=bulb_on
ZEDQA wi PASS light_1x: 2 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi stick_1x: 3 slices | 1:Toggle Crouch=sneak 2:Toggle Sit=sit_ground 3:Toggle Auto-Walk=autowalk
ZEDQA wi PASS stick_1x: 3 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi car_inside_1x: 12 slices | 1:Switch Seat=seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.=hotwire_off 3:Turn Headlights on=headlight_on 4:Turn AC/Heater on=heat 5:Horn=horn 6:Device Options=speaker 7:Open Window=window_open 8:Unlock all doors=padlock_open 9:Vehicle Mechanics=engine 10:Not tired enough to sleep.=bed 11:Exit Vehicle=car_exit 12:Dashboard/The D-pad on its controls. Back lets go.=gauge
ZEDQA wi PASS car_inside_1x: 12 wheel icons drawn pixel for pixel at the box's size (under 16, the 16 scaled down)
ZEDQA wi scale back to option 1: icon box 12
ZEDQA wi 0 failed, 2 notes
ZEDQA wi DONE
```

### 5. zedqa_world_pad_take.lua (`ZEDQA wpt`) - PASS, 50 s

- go 17966 at 13:22:13

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #5 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ZEDQA wpt PASS a crate was built beside the character
ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@43
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
ZEDQA wpt 7 tabs: 12 at small and large
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
ZEDQA wpt cleanup: crate gone true, size small
ZEDQA wpt 89 passed, 0 failed
ZEDQA wpt DONE
```

### 6. zedqa_dke_only_race_primani.lua (`ZEDQA dko`) - TIMEOUT, 30 s

- go 17967 at 13:23:06
- no DONE within 30 s; the script may still be running in the game

```text
[ZeD.QA] windows reset (R)
ZEDQA dko dke limited to race and primani | DONE
[ZeD.QA] run #6 ok=true
```

### 7. zedqa_dash_keys_edge.lua (`ZEDQA dke`) - SKIP, not run

- not run: no DONE within 30 s; the script may still be running in the game

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
