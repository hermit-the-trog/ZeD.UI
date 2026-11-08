# ZeD-UI regression - 2026-11-01 13:56 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-01 13:56:01 |
| Finished | 2026-11-01 14:01:30 (5 min 29 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\AppData\Local\Temp\claude\C--Users-danie--claude-spares-spare-8vLpAQ\8d4042f4-6e83-4cb6-9f64-0a1e0b9a2dae\scratchpad\pair4k_manifest.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 17984 to 17988 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 17987, 17988)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_two_widths.lua | tww | PASS | 87 | zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png |  |
| 3 | zedqa_curtain.lua | cu | PASS | 151 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 17984 at 13:56:59

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_two_widths.lua (`ZEDQA tww`) - PASS, 87 s

- go 17985 at 13:57:05
- screenshots: zqa_tww_after_oven.png, zqa_tww_after_walkie.png, zqa_tww_after_ham.png, zqa_tww_after_maps.png, zqa_tww_after_maps_popout.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tww start
[ZeD.QA] run #2 ok=true
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
ZEDQA tww 26 more cases
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
ZEDQA tww Character Radio (a walkie): drawer 385 px = half | Character 749,0 1162x735 | World 1929,0 777x735
ZEDQA tww PASS Character Radio (a walkie): the drawer is the half card or the full card (385 px; half 385, full 840)
ZEDQA tww PASS Character Radio (a walkie): it is the half card (half)
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
ERROR: General f:7688 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:7696 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA tww PASS after the whole run both windows are where and as big as they were (1134,0 777x735 / 1929,0 777x735 -> 1134,0 777x735 / 1929,0 777x735)
ZEDQA tww skipped, the thing was not there to open: World object card fire, World object card hook, World object card hutch, World object card laundry, World object card lock, World object card plant, World object card track, World object card trough
ZEDQA tww ALL PASS
ZEDQA tww DONE
```

### 3. zedqa_curtain.lua (`ZEDQA cu`) - PASS, 151 s

- go 17986 at 13:58:35
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #3 ok=true
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
