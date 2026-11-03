# ZeD-UI regression - 2026-11-03 10:32 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-03 10:32:52 |
| Finished | 2026-11-03 10:39:59 (7 min 7 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI\tools\qa\radio_review.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 19504 to 19507 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19506, 19507)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 4 |  |  |
| 2 | zedqa_radio_review.lua | rrv | PASS | 337 | zqa_rrv_0_50_radio_black@206_half.png, zqa_rrv_0_50_radio_red@206_half.png, zqa_rrv_0_50_radio_handbuilt@206_half.png, zqa_rrv_0_50_cd_player@206_half.png, zqa_rrv_0_50_walkie_toy_half.png, zqa_rrv_0_50_walkie_toy_full.png, zqa_rrv_0_50_walkie_valutech_half.png, zqa_rrv_0_50_walkie_valutech_full.png, zqa_rrv_0_50_walkie_premium_half.png, zqa_rrv_0_50_walkie_premium_full.png, zqa_rrv_0_50_walkie_tactical_half.png, zqa_rrv_0_50_walkie_tactical_full.png, zqa_rrv_0_50_walkie_army_half.png, zqa_rrv_0_50_walkie_army_full.png, zqa_rrv_0_50_walkie_makeshift_half.png, zqa_rrv_0_50_walkie_makeshift_full.png, zqa_rrv_0_50_walkie_manpack_half.png, zqa_rrv_0_50_walkie_manpack_full.png, zqa_rrv_0_50_ham_civilian_n_half.png, zqa_rrv_0_50_ham_civilian_n_full.png, zqa_rrv_0_50_ham_army_n_half.png, zqa_rrv_0_50_ham_army_n_full.png, zqa_rrv_0_50_ham_makeshift_n_half.png, zqa_rrv_0_50_ham_makeshift_n_full.png, zqa_rrv_0_75_radio_black@154_half.png, zqa_rrv_0_75_radio_red@154_half.png, zqa_rrv_0_75_radio_handbuilt@257_half.png, zqa_rrv_0_75_cd_player@154_half.png, zqa_rrv_0_75_walkie_toy@154_half.png, zqa_rrv_0_75_walkie_toy@154_full.png, zqa_rrv_0_75_walkie_valutech@154_half.png, zqa_rrv_0_75_walkie_valutech@154_full.png, zqa_rrv_0_75_walkie_premium@154_half.png, zqa_rrv_0_75_walkie_premium@154_full.png, zqa_rrv_0_75_walkie_tactical@154_half.png, zqa_rrv_0_75_walkie_tactical@154_full.png, zqa_rrv_0_75_walkie_army@154_half.png, zqa_rrv_0_75_walkie_army@154_full.png, zqa_rrv_0_75_walkie_makeshift@154_half.png, zqa_rrv_0_75_walkie_makeshift@154_full.png, zqa_rrv_0_75_walkie_manpack@154_half.png, zqa_rrv_0_75_walkie_manpack@154_full.png, zqa_rrv_0_75_ham_civilian_half.png, zqa_rrv_0_75_ham_civilian_full.png, zqa_rrv_0_75_ham_army_half.png, zqa_rrv_0_75_ham_army_full.png, zqa_rrv_0_75_ham_makeshift_half.png, zqa_rrv_0_75_ham_makeshift_full.png, zqa_rrv_1_00_radio_black@206_half.png, zqa_rrv_1_00_radio_red@206_half.png, zqa_rrv_1_00_radio_handbuilt@206_half.png, zqa_rrv_1_00_cd_player@206_half.png, zqa_rrv_1_00_walkie_toy@206_half.png, zqa_rrv_1_00_walkie_toy@206_full.png, zqa_rrv_1_00_walkie_valutech@206_half.png, zqa_rrv_1_00_walkie_valutech@206_full.png, zqa_rrv_1_00_walkie_premium@206_half.png, zqa_rrv_1_00_walkie_premium@206_full.png, zqa_rrv_1_00_walkie_tactical@206_half.png, zqa_rrv_1_00_walkie_tactical@206_full.png, zqa_rrv_1_00_walkie_army@206_half.png, zqa_rrv_1_00_walkie_army@206_full.png, zqa_rrv_1_00_walkie_makeshift@206_half.png, zqa_rrv_1_00_walkie_makeshift@206_full.png, zqa_rrv_1_00_walkie_manpack@206_half.png, zqa_rrv_1_00_walkie_manpack@206_full.png, zqa_rrv_1_00_ham_civilian@450_half.png, zqa_rrv_1_00_ham_civilian@450_full.png, zqa_rrv_1_00_ham_army@450_half.png, zqa_rrv_1_00_ham_army@450_full.png, zqa_rrv_1_00_ham_makeshift@450_half.png, zqa_rrv_1_00_ham_makeshift@450_full.png, zqa_rrv_1_25_radio_black@257_half.png, zqa_rrv_1_25_radio_red@257_half.png, zqa_rrv_1_25_radio_handbuilt@257_half.png, zqa_rrv_1_25_cd_player@257_half.png, zqa_rrv_1_25_walkie_toy@257_half.png, zqa_rrv_1_25_walkie_toy@257_full.png, zqa_rrv_1_25_walkie_valutech@257_half.png, zqa_rrv_1_25_walkie_valutech@257_full.png, zqa_rrv_1_25_walkie_premium@257_half.png, zqa_rrv_1_25_walkie_premium@257_full.png, zqa_rrv_1_25_walkie_tactical@257_half.png, zqa_rrv_1_25_walkie_tactical@257_full.png, zqa_rrv_1_25_walkie_army@257_half.png, zqa_rrv_1_25_walkie_army@257_full.png, zqa_rrv_1_25_walkie_makeshift@257_half.png, zqa_rrv_1_25_walkie_makeshift@257_full.png, zqa_rrv_1_25_walkie_manpack@257_half.png, zqa_rrv_1_25_walkie_manpack@257_full.png, zqa_rrv_1_25_ham_civilian@562_half.png, zqa_rrv_1_25_ham_civilian@562_full.png, zqa_rrv_1_25_ham_army@562_half.png, zqa_rrv_1_25_ham_army@562_full.png, zqa_rrv_1_25_ham_makeshift@562_half.png, zqa_rrv_1_25_ham_makeshift@562_full.png, zqa_rrv_1_50_radio_black@154_half.png, zqa_rrv_1_50_radio_red@154_half.png, zqa_rrv_1_50_radio_handbuilt@257_half.png, zqa_rrv_1_50_cd_player@154_half.png, zqa_rrv_1_50_walkie_toy@154_half.png, zqa_rrv_1_50_walkie_toy@154_full.png, zqa_rrv_1_50_walkie_valutech@154_half.png, zqa_rrv_1_50_walkie_valutech@154_full.png, zqa_rrv_1_50_walkie_premium@154_half.png, zqa_rrv_1_50_walkie_premium@154_full.png, zqa_rrv_1_50_walkie_tactical@154_half.png, zqa_rrv_1_50_walkie_tactical@154_full.png, zqa_rrv_1_50_walkie_army@154_half.png, zqa_rrv_1_50_walkie_army@154_full.png, zqa_rrv_1_50_walkie_makeshift@154_half.png, zqa_rrv_1_50_walkie_makeshift@154_full.png, zqa_rrv_1_50_walkie_manpack@154_half.png, zqa_rrv_1_50_walkie_manpack@154_full.png, zqa_rrv_1_50_ham_civilian_half.png, zqa_rrv_1_50_ham_civilian_full.png, zqa_rrv_1_50_ham_army_half.png, zqa_rrv_1_50_ham_army_full.png, zqa_rrv_1_50_ham_makeshift_half.png, zqa_rrv_1_50_ham_makeshift_full.png, zqa_rrv_1_75_radio_black_half.png, zqa_rrv_1_75_radio_red_half.png, zqa_rrv_1_75_radio_handbuilt_half.png, zqa_rrv_1_75_cd_player_half.png, zqa_rrv_1_75_walkie_toy@180_half.png, zqa_rrv_1_75_walkie_toy@180_full.png, zqa_rrv_1_75_walkie_valutech@180_half.png, zqa_rrv_1_75_walkie_valutech@180_full.png, zqa_rrv_1_75_walkie_premium@180_half.png, zqa_rrv_1_75_walkie_premium@180_full.png, zqa_rrv_1_75_walkie_tactical@180_half.png, zqa_rrv_1_75_walkie_tactical@180_full.png, zqa_rrv_1_75_walkie_army@180_half.png, zqa_rrv_1_75_walkie_army@180_full.png, zqa_rrv_1_75_walkie_makeshift@180_half.png, zqa_rrv_1_75_walkie_makeshift@180_full.png, zqa_rrv_1_75_walkie_manpack@180_half.png, zqa_rrv_1_75_walkie_manpack@180_full.png, zqa_rrv_1_75_ham_civilian@392_half.png, zqa_rrv_1_75_ham_civilian@392_full.png, zqa_rrv_1_75_ham_army@392_half.png, zqa_rrv_1_75_ham_army@392_full.png, zqa_rrv_1_75_ham_makeshift@392_half.png, zqa_rrv_1_75_ham_makeshift@392_full.png, zqa_rrv_2_00_radio_black@206_half.png, zqa_rrv_2_00_radio_red@206_half.png, zqa_rrv_2_00_radio_handbuilt@206_half.png, zqa_rrv_2_00_cd_player@206_half.png, zqa_rrv_2_00_walkie_toy@206_half.png, zqa_rrv_2_00_walkie_toy@206_full.png, zqa_rrv_2_00_walkie_valutech@206_half.png, zqa_rrv_2_00_walkie_valutech@206_full.png, zqa_rrv_2_00_walkie_premium@206_half.png, zqa_rrv_2_00_walkie_premium@206_full.png, zqa_rrv_2_00_walkie_tactical@206_half.png, zqa_rrv_2_00_walkie_tactical@206_full.png, zqa_rrv_2_00_walkie_army@206_half.png, zqa_rrv_2_00_walkie_army@206_full.png, zqa_rrv_2_00_walkie_makeshift@206_half.png, zqa_rrv_2_00_walkie_makeshift@206_full.png, zqa_rrv_2_00_walkie_manpack@206_half.png, zqa_rrv_2_00_walkie_manpack@206_full.png, zqa_rrv_2_00_ham_civilian@450_half.png, zqa_rrv_2_00_ham_civilian@450_full.png, zqa_rrv_2_00_ham_army@450_half.png, zqa_rrv_2_00_ham_army@450_full.png, zqa_rrv_2_00_ham_makeshift@450_half.png, zqa_rrv_2_00_ham_makeshift@450_full.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 4 s

- go 19504 at 10:33:50

```text
[ZeD.QA] state #1 speed=1 paused=false player=923,13036 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 923,13036,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_radio_review.lua (`ZEDQA rrv`) - PASS, 337 s

- go 19505 at 10:33:58
- screenshots: zqa_rrv_0_50_radio_black@206_half.png, zqa_rrv_0_50_radio_red@206_half.png, zqa_rrv_0_50_radio_handbuilt@206_half.png, zqa_rrv_0_50_cd_player@206_half.png, zqa_rrv_0_50_walkie_toy_half.png, zqa_rrv_0_50_walkie_toy_full.png, zqa_rrv_0_50_walkie_valutech_half.png, zqa_rrv_0_50_walkie_valutech_full.png, zqa_rrv_0_50_walkie_premium_half.png, zqa_rrv_0_50_walkie_premium_full.png, zqa_rrv_0_50_walkie_tactical_half.png, zqa_rrv_0_50_walkie_tactical_full.png, zqa_rrv_0_50_walkie_army_half.png, zqa_rrv_0_50_walkie_army_full.png, zqa_rrv_0_50_walkie_makeshift_half.png, zqa_rrv_0_50_walkie_makeshift_full.png, zqa_rrv_0_50_walkie_manpack_half.png, zqa_rrv_0_50_walkie_manpack_full.png, zqa_rrv_0_50_ham_civilian_n_half.png, zqa_rrv_0_50_ham_civilian_n_full.png, zqa_rrv_0_50_ham_army_n_half.png, zqa_rrv_0_50_ham_army_n_full.png, zqa_rrv_0_50_ham_makeshift_n_half.png, zqa_rrv_0_50_ham_makeshift_n_full.png, zqa_rrv_0_75_radio_black@154_half.png, zqa_rrv_0_75_radio_red@154_half.png, zqa_rrv_0_75_radio_handbuilt@257_half.png, zqa_rrv_0_75_cd_player@154_half.png, zqa_rrv_0_75_walkie_toy@154_half.png, zqa_rrv_0_75_walkie_toy@154_full.png, zqa_rrv_0_75_walkie_valutech@154_half.png, zqa_rrv_0_75_walkie_valutech@154_full.png, zqa_rrv_0_75_walkie_premium@154_half.png, zqa_rrv_0_75_walkie_premium@154_full.png, zqa_rrv_0_75_walkie_tactical@154_half.png, zqa_rrv_0_75_walkie_tactical@154_full.png, zqa_rrv_0_75_walkie_army@154_half.png, zqa_rrv_0_75_walkie_army@154_full.png, zqa_rrv_0_75_walkie_makeshift@154_half.png, zqa_rrv_0_75_walkie_makeshift@154_full.png, zqa_rrv_0_75_walkie_manpack@154_half.png, zqa_rrv_0_75_walkie_manpack@154_full.png, zqa_rrv_0_75_ham_civilian_half.png, zqa_rrv_0_75_ham_civilian_full.png, zqa_rrv_0_75_ham_army_half.png, zqa_rrv_0_75_ham_army_full.png, zqa_rrv_0_75_ham_makeshift_half.png, zqa_rrv_0_75_ham_makeshift_full.png, zqa_rrv_1_00_radio_black@206_half.png, zqa_rrv_1_00_radio_red@206_half.png, zqa_rrv_1_00_radio_handbuilt@206_half.png, zqa_rrv_1_00_cd_player@206_half.png, zqa_rrv_1_00_walkie_toy@206_half.png, zqa_rrv_1_00_walkie_toy@206_full.png, zqa_rrv_1_00_walkie_valutech@206_half.png, zqa_rrv_1_00_walkie_valutech@206_full.png, zqa_rrv_1_00_walkie_premium@206_half.png, zqa_rrv_1_00_walkie_premium@206_full.png, zqa_rrv_1_00_walkie_tactical@206_half.png, zqa_rrv_1_00_walkie_tactical@206_full.png, zqa_rrv_1_00_walkie_army@206_half.png, zqa_rrv_1_00_walkie_army@206_full.png, zqa_rrv_1_00_walkie_makeshift@206_half.png, zqa_rrv_1_00_walkie_makeshift@206_full.png, zqa_rrv_1_00_walkie_manpack@206_half.png, zqa_rrv_1_00_walkie_manpack@206_full.png, zqa_rrv_1_00_ham_civilian@450_half.png, zqa_rrv_1_00_ham_civilian@450_full.png, zqa_rrv_1_00_ham_army@450_half.png, zqa_rrv_1_00_ham_army@450_full.png, zqa_rrv_1_00_ham_makeshift@450_half.png, zqa_rrv_1_00_ham_makeshift@450_full.png, zqa_rrv_1_25_radio_black@257_half.png, zqa_rrv_1_25_radio_red@257_half.png, zqa_rrv_1_25_radio_handbuilt@257_half.png, zqa_rrv_1_25_cd_player@257_half.png, zqa_rrv_1_25_walkie_toy@257_half.png, zqa_rrv_1_25_walkie_toy@257_full.png, zqa_rrv_1_25_walkie_valutech@257_half.png, zqa_rrv_1_25_walkie_valutech@257_full.png, zqa_rrv_1_25_walkie_premium@257_half.png, zqa_rrv_1_25_walkie_premium@257_full.png, zqa_rrv_1_25_walkie_tactical@257_half.png, zqa_rrv_1_25_walkie_tactical@257_full.png, zqa_rrv_1_25_walkie_army@257_half.png, zqa_rrv_1_25_walkie_army@257_full.png, zqa_rrv_1_25_walkie_makeshift@257_half.png, zqa_rrv_1_25_walkie_makeshift@257_full.png, zqa_rrv_1_25_walkie_manpack@257_half.png, zqa_rrv_1_25_walkie_manpack@257_full.png, zqa_rrv_1_25_ham_civilian@562_half.png, zqa_rrv_1_25_ham_civilian@562_full.png, zqa_rrv_1_25_ham_army@562_half.png, zqa_rrv_1_25_ham_army@562_full.png, zqa_rrv_1_25_ham_makeshift@562_half.png, zqa_rrv_1_25_ham_makeshift@562_full.png, zqa_rrv_1_50_radio_black@154_half.png, zqa_rrv_1_50_radio_red@154_half.png, zqa_rrv_1_50_radio_handbuilt@257_half.png, zqa_rrv_1_50_cd_player@154_half.png, zqa_rrv_1_50_walkie_toy@154_half.png, zqa_rrv_1_50_walkie_toy@154_full.png, zqa_rrv_1_50_walkie_valutech@154_half.png, zqa_rrv_1_50_walkie_valutech@154_full.png, zqa_rrv_1_50_walkie_premium@154_half.png, zqa_rrv_1_50_walkie_premium@154_full.png, zqa_rrv_1_50_walkie_tactical@154_half.png, zqa_rrv_1_50_walkie_tactical@154_full.png, zqa_rrv_1_50_walkie_army@154_half.png, zqa_rrv_1_50_walkie_army@154_full.png, zqa_rrv_1_50_walkie_makeshift@154_half.png, zqa_rrv_1_50_walkie_makeshift@154_full.png, zqa_rrv_1_50_walkie_manpack@154_half.png, zqa_rrv_1_50_walkie_manpack@154_full.png, zqa_rrv_1_50_ham_civilian_half.png, zqa_rrv_1_50_ham_civilian_full.png, zqa_rrv_1_50_ham_army_half.png, zqa_rrv_1_50_ham_army_full.png, zqa_rrv_1_50_ham_makeshift_half.png, zqa_rrv_1_50_ham_makeshift_full.png, zqa_rrv_1_75_radio_black_half.png, zqa_rrv_1_75_radio_red_half.png, zqa_rrv_1_75_radio_handbuilt_half.png, zqa_rrv_1_75_cd_player_half.png, zqa_rrv_1_75_walkie_toy@180_half.png, zqa_rrv_1_75_walkie_toy@180_full.png, zqa_rrv_1_75_walkie_valutech@180_half.png, zqa_rrv_1_75_walkie_valutech@180_full.png, zqa_rrv_1_75_walkie_premium@180_half.png, zqa_rrv_1_75_walkie_premium@180_full.png, zqa_rrv_1_75_walkie_tactical@180_half.png, zqa_rrv_1_75_walkie_tactical@180_full.png, zqa_rrv_1_75_walkie_army@180_half.png, zqa_rrv_1_75_walkie_army@180_full.png, zqa_rrv_1_75_walkie_makeshift@180_half.png, zqa_rrv_1_75_walkie_makeshift@180_full.png, zqa_rrv_1_75_walkie_manpack@180_half.png, zqa_rrv_1_75_walkie_manpack@180_full.png, zqa_rrv_1_75_ham_civilian@392_half.png, zqa_rrv_1_75_ham_civilian@392_full.png, zqa_rrv_1_75_ham_army@392_half.png, zqa_rrv_1_75_ham_army@392_full.png, zqa_rrv_1_75_ham_makeshift@392_half.png, zqa_rrv_1_75_ham_makeshift@392_full.png, zqa_rrv_2_00_radio_black@206_half.png, zqa_rrv_2_00_radio_red@206_half.png, zqa_rrv_2_00_radio_handbuilt@206_half.png, zqa_rrv_2_00_cd_player@206_half.png, zqa_rrv_2_00_walkie_toy@206_half.png, zqa_rrv_2_00_walkie_toy@206_full.png, zqa_rrv_2_00_walkie_valutech@206_half.png, zqa_rrv_2_00_walkie_valutech@206_full.png, zqa_rrv_2_00_walkie_premium@206_half.png, zqa_rrv_2_00_walkie_premium@206_full.png, zqa_rrv_2_00_walkie_tactical@206_half.png, zqa_rrv_2_00_walkie_tactical@206_full.png, zqa_rrv_2_00_walkie_army@206_half.png, zqa_rrv_2_00_walkie_army@206_full.png, zqa_rrv_2_00_walkie_makeshift@206_half.png, zqa_rrv_2_00_walkie_makeshift@206_full.png, zqa_rrv_2_00_walkie_manpack@206_half.png, zqa_rrv_2_00_walkie_manpack@206_full.png, zqa_rrv_2_00_ham_civilian@450_half.png, zqa_rrv_2_00_ham_civilian@450_full.png, zqa_rrv_2_00_ham_army@450_half.png, zqa_rrv_2_00_ham_army@450_full.png, zqa_rrv_2_00_ham_makeshift@450_half.png, zqa_rrv_2_00_ham_makeshift@450_full.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rrv start
[ZeD.QA] run #2 ok=true
ZEDQA rrv scale 0.50: root 0.50
ZEDQA rrv rect zqa_rrv_0_50_radio_black@206_half 1455 0 462 210
ZEDQA rrv 0_50 Base.RadioBlack: face radio_black@206, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_radio_red@206_half 1455 0 462 210
ZEDQA rrv 0_50 Base.RadioRed: face radio_red@206, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_radio_handbuilt@206_half 1455 0 462 210
ZEDQA rrv 0_50 Base.RadioMakeShift: face radio_handbuilt@206, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_cd_player@206_half 1455 0 462 210
ZEDQA rrv 0_50 Base.CDplayer: face cd_player@206, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_toy_half 1455 0 462 210
ZEDQA rrv 0_50 Base.WalkieTalkie1: face walkie_toy, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_toy_full 2779 869 201 361
ZEDQA rrv rect zqa_rrv_0_50_walkie_valutech_half 1455 0 462 210
ZEDQA rrv 0_50 Base.WalkieTalkie2: face walkie_valutech, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_valutech_full 2779 869 201 361
ZEDQA rrv rect zqa_rrv_0_50_walkie_premium_half 1455 0 462 210
ZEDQA rrv 0_50 Base.WalkieTalkie3: face walkie_premium, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_premium_full 2779 869 201 361
ZEDQA rrv rect zqa_rrv_0_50_walkie_tactical_half 1455 0 462 210
ZEDQA rrv 0_50 Base.WalkieTalkie4: face walkie_tactical, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_tactical_full 2779 869 201 361
ZEDQA rrv rect zqa_rrv_0_50_walkie_army_half 1455 0 462 210
ZEDQA rrv 0_50 Base.WalkieTalkie5: face walkie_army, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_army_full 2779 869 201 361
ZEDQA rrv rect zqa_rrv_0_50_walkie_makeshift_half 1455 0 462 210
ZEDQA rrv 0_50 Base.WalkieTalkieMakeShift: face walkie_makeshift, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_makeshift_full 2779 869 201 361
ZEDQA rrv rect zqa_rrv_0_50_walkie_manpack_half 1455 0 462 210
ZEDQA rrv 0_50 Base.ManPackRadio: face walkie_manpack, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_walkie_manpack_full 2779 909 201 281
ZEDQA rrv rect zqa_rrv_0_50_ham_civilian_n_half 1923 0 462 210
ZEDQA rrv 0_50 Base.HamRadio1: face ham_civilian_n, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_ham_civilian_n_full 2711 963 337 173
ZEDQA rrv rect zqa_rrv_0_50_ham_army_n_half 1923 0 462 210
ZEDQA rrv 0_50 Base.HamRadio2: face ham_army_n, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_ham_army_n_full 2711 963 337 173
ZEDQA rrv rect zqa_rrv_0_50_ham_makeshift_n_half 1923 0 462 210
ZEDQA rrv 0_50 Base.HamRadioMakeShift: face ham_makeshift_n, card 240 px
ZEDQA rrv rect zqa_rrv_0_50_ham_makeshift_n_full 2711 963 337 173
ZEDQA rrv scale 0.75: root 0.75
ZEDQA rrv rect zqa_rrv_0_75_radio_black@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.RadioBlack: face radio_black@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_radio_red@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.RadioRed: face radio_red@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_radio_handbuilt@257_half 1223 0 693 315
ZEDQA rrv 0_75 Base.RadioMakeShift: face radio_handbuilt@257, card 360 px
ZEDQA rrv rect zqa_rrv_0_75_cd_player@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.CDplayer: face cd_player@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_toy@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.WalkieTalkie1: face walkie_toy@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_toy@154_full 2779 854 201 361
ZEDQA rrv rect zqa_rrv_0_75_walkie_valutech@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.WalkieTalkie2: face walkie_valutech@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_valutech@154_full 2779 854 201 361
ZEDQA rrv rect zqa_rrv_0_75_walkie_premium@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.WalkieTalkie3: face walkie_premium@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_premium@154_full 2779 854 201 361
ZEDQA rrv rect zqa_rrv_0_75_walkie_tactical@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.WalkieTalkie4: face walkie_tactical@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_tactical@154_full 2779 854 201 361
ZEDQA rrv rect zqa_rrv_0_75_walkie_army@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.WalkieTalkie5: face walkie_army@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_army@154_full 2779 854 201 361
ZEDQA rrv rect zqa_rrv_0_75_walkie_makeshift@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.WalkieTalkieMakeShift: face walkie_makeshift@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_makeshift@154_full 2779 854 201 361
ZEDQA rrv rect zqa_rrv_0_75_walkie_manpack@154_half 1418 0 498 315
ZEDQA rrv 0_75 Base.ManPackRadio: face walkie_manpack@154, card 165 px
ZEDQA rrv rect zqa_rrv_0_75_walkie_manpack@154_full 2779 894 201 281
ZEDQA rrv rect zqa_rrv_0_75_ham_civilian_half 1924 0 693 315
ZEDQA rrv 0_75 Base.HamRadio1: face ham_civilian, card 360 px
ZEDQA rrv rect zqa_rrv_0_75_ham_civilian_full 2711 948 337 173
ZEDQA rrv rect zqa_rrv_0_75_ham_army_half 1924 0 693 315
ZEDQA rrv 0_75 Base.HamRadio2: face ham_army, card 360 px
ZEDQA rrv rect zqa_rrv_0_75_ham_army_full 2711 948 337 173
ZEDQA rrv rect zqa_rrv_0_75_ham_makeshift_half 1924 0 693 315
ZEDQA rrv 0_75 Base.HamRadioMakeShift: face ham_makeshift, card 360 px
ZEDQA rrv rect zqa_rrv_0_75_ham_makeshift_full 2711 948 337 173
ZEDQA rrv scale 1.00: root 1.00
ZEDQA rrv rect zqa_rrv_1_00_radio_black@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.RadioBlack: face radio_black@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_radio_red@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.RadioRed: face radio_red@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_radio_handbuilt@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.RadioMakeShift: face radio_handbuilt@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_cd_player@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.CDplayer: face cd_player@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_toy@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.WalkieTalkie1: face walkie_toy@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_toy@206_full 2779 839 201 361
ZEDQA rrv rect zqa_rrv_1_00_walkie_valutech@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.WalkieTalkie2: face walkie_valutech@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_valutech@206_full 2779 839 201 361
ZEDQA rrv rect zqa_rrv_1_00_walkie_premium@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.WalkieTalkie3: face walkie_premium@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_premium@206_full 2779 839 201 361
ZEDQA rrv rect zqa_rrv_1_00_walkie_tactical@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.WalkieTalkie4: face walkie_tactical@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_tactical@206_full 2779 839 201 361
ZEDQA rrv rect zqa_rrv_1_00_walkie_army@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.WalkieTalkie5: face walkie_army@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_army@206_full 2779 839 201 361
ZEDQA rrv rect zqa_rrv_1_00_walkie_makeshift@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.WalkieTalkieMakeShift: face walkie_makeshift@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_makeshift@206_full 2779 839 201 361
ZEDQA rrv rect zqa_rrv_1_00_walkie_manpack@206_half 1251 0 664 420
ZEDQA rrv 1_00 Base.ManPackRadio: face walkie_manpack@206, card 220 px
ZEDQA rrv rect zqa_rrv_1_00_walkie_manpack@206_full 2779 879 201 281
ZEDQA rrv rect zqa_rrv_1_00_ham_civilian@450_half 1925 0 924 420
ZEDQA rrv 1_00 Base.HamRadio1: face ham_civilian@450, card 480 px
ZEDQA rrv rect zqa_rrv_1_00_ham_civilian@450_full 2711 933 337 173
ZEDQA rrv rect zqa_rrv_1_00_ham_army@450_half 1925 0 924 420
ZEDQA rrv 1_00 Base.HamRadio2: face ham_army@450, card 480 px
ZEDQA rrv rect zqa_rrv_1_00_ham_army@450_full 2711 933 337 173
ZEDQA rrv rect zqa_rrv_1_00_ham_makeshift@450_half 1925 0 924 420
ZEDQA rrv 1_00 Base.HamRadioMakeShift: face ham_makeshift@450, card 480 px
ZEDQA rrv rect zqa_rrv_1_00_ham_makeshift@450_full 2711 933 337 173
ZEDQA rrv scale 1.25: root 1.25
ZEDQA rrv rect zqa_rrv_1_25_radio_black@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.RadioBlack: face radio_black@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_radio_red@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.RadioRed: face radio_red@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_radio_handbuilt@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.RadioMakeShift: face radio_handbuilt@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_cd_player@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.CDplayer: face cd_player@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_toy@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.WalkieTalkie1: face walkie_toy@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_toy@257_full 2779 824 201 361
ZEDQA rrv rect zqa_rrv_1_25_walkie_valutech@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.WalkieTalkie2: face walkie_valutech@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_valutech@257_full 2779 824 201 361
ZEDQA rrv rect zqa_rrv_1_25_walkie_premium@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.WalkieTalkie3: face walkie_premium@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_premium@257_full 2779 824 201 361
ZEDQA rrv rect zqa_rrv_1_25_walkie_tactical@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.WalkieTalkie4: face walkie_tactical@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_tactical@257_full 2779 824 201 361
ZEDQA rrv rect zqa_rrv_1_25_walkie_army@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.WalkieTalkie5: face walkie_army@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_army@257_full 2779 824 201 361
ZEDQA rrv rect zqa_rrv_1_25_walkie_makeshift@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.WalkieTalkieMakeShift: face walkie_makeshift@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_makeshift@257_full 2779 824 201 361
ZEDQA rrv rect zqa_rrv_1_25_walkie_manpack@257_half 1084 0 830 525
ZEDQA rrv 1_25 Base.ManPackRadio: face walkie_manpack@257, card 275 px
ZEDQA rrv rect zqa_rrv_1_25_walkie_manpack@257_full 2779 864 201 281
ZEDQA rrv rect zqa_rrv_1_25_ham_civilian@562_half 1926 0 1155 525
ZEDQA rrv 1_25 Base.HamRadio1: face ham_civilian@562, card 600 px
ZEDQA rrv rect zqa_rrv_1_25_ham_civilian@562_full 2711 918 337 173
ZEDQA rrv rect zqa_rrv_1_25_ham_army@562_half 1926 0 1155 525
ZEDQA rrv 1_25 Base.HamRadio2: face ham_army@562, card 600 px
ZEDQA rrv rect zqa_rrv_1_25_ham_army@562_full 2711 918 337 173
ZEDQA rrv rect zqa_rrv_1_25_ham_makeshift@562_half 1926 0 1155 525
ZEDQA rrv 1_25 Base.HamRadioMakeShift: face ham_makeshift@562, card 600 px
ZEDQA rrv rect zqa_rrv_1_25_ham_makeshift@562_full 2711 918 337 173
ZEDQA rrv scale 1.50: root 1.50
ZEDQA rrv rect zqa_rrv_1_50_radio_black@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.RadioBlack: face radio_black@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_radio_red@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.RadioRed: face radio_red@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_radio_handbuilt@257_half 526 0 1386 630
ZEDQA rrv 1_50 Base.RadioMakeShift: face radio_handbuilt@257, card 720 px
ZEDQA rrv rect zqa_rrv_1_50_cd_player@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.CDplayer: face cd_player@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_toy@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.WalkieTalkie1: face walkie_toy@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_toy@154_full 2679 629 402 722
ZEDQA rrv rect zqa_rrv_1_50_walkie_valutech@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.WalkieTalkie2: face walkie_valutech@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_valutech@154_full 2679 629 402 722
ZEDQA rrv rect zqa_rrv_1_50_walkie_premium@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.WalkieTalkie3: face walkie_premium@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_premium@154_full 2679 629 402 722
ZEDQA rrv rect zqa_rrv_1_50_walkie_tactical@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.WalkieTalkie4: face walkie_tactical@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_tactical@154_full 2679 629 402 722
ZEDQA rrv rect zqa_rrv_1_50_walkie_army@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.WalkieTalkie5: face walkie_army@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_army@154_full 2679 629 402 722
ZEDQA rrv rect zqa_rrv_1_50_walkie_makeshift@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.WalkieTalkieMakeShift: face walkie_makeshift@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_makeshift@154_full 2679 629 402 722
ZEDQA rrv rect zqa_rrv_1_50_walkie_manpack@154_half 916 0 996 630
ZEDQA rrv 1_50 Base.ManPackRadio: face walkie_manpack@154, card 330 px
ZEDQA rrv rect zqa_rrv_1_50_walkie_manpack@154_full 2679 709 402 562
ZEDQA rrv rect zqa_rrv_1_50_ham_civilian_half 1928 0 1386 630
ZEDQA rrv 1_50 Base.HamRadio1: face ham_civilian, card 720 px
ZEDQA rrv rect zqa_rrv_1_50_ham_civilian_full 2543 817 674 346
ZEDQA rrv rect zqa_rrv_1_50_ham_army_half 1928 0 1386 630
ZEDQA rrv 1_50 Base.HamRadio2: face ham_army, card 720 px
ZEDQA rrv rect zqa_rrv_1_50_ham_army_full 2543 817 674 346
ZEDQA rrv rect zqa_rrv_1_50_ham_makeshift_half 1928 0 1386 630
ZEDQA rrv 1_50 Base.HamRadioMakeShift: face ham_makeshift, card 720 px
ZEDQA rrv rect zqa_rrv_1_50_ham_makeshift_full 2543 817 674 346
ZEDQA rrv scale 1.75: root 1.75
ZEDQA rrv rect zqa_rrv_1_75_radio_black_half 749 0 1162 735
ZEDQA rrv 1_75 Base.RadioBlack: face radio_black, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_radio_red_half 749 0 1162 735
ZEDQA rrv 1_75 Base.RadioRed: face radio_red, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_radio_handbuilt_half 749 0 1162 735
ZEDQA rrv 1_75 Base.RadioMakeShift: face radio_handbuilt, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_cd_player_half 749 0 1162 735
ZEDQA rrv 1_75 Base.CDplayer: face cd_player, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_toy@180_half 749 0 1162 735
ZEDQA rrv 1_75 Base.WalkieTalkie1: face walkie_toy@180, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_toy@180_full 2679 614 402 722
ZEDQA rrv rect zqa_rrv_1_75_walkie_valutech@180_half 749 0 1162 735
ZEDQA rrv 1_75 Base.WalkieTalkie2: face walkie_valutech@180, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_valutech@180_full 2679 614 402 722
ZEDQA rrv rect zqa_rrv_1_75_walkie_premium@180_half 749 0 1162 735
ZEDQA rrv 1_75 Base.WalkieTalkie3: face walkie_premium@180, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_premium@180_full 2679 614 402 722
ZEDQA rrv rect zqa_rrv_1_75_walkie_tactical@180_half 749 0 1162 735
ZEDQA rrv 1_75 Base.WalkieTalkie4: face walkie_tactical@180, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_tactical@180_full 2679 614 402 722
ZEDQA rrv rect zqa_rrv_1_75_walkie_army@180_half 749 0 1162 735
ZEDQA rrv 1_75 Base.WalkieTalkie5: face walkie_army@180, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_army@180_full 2679 614 402 722
ZEDQA rrv rect zqa_rrv_1_75_walkie_makeshift@180_half 749 0 1162 735
ZEDQA rrv 1_75 Base.WalkieTalkieMakeShift: face walkie_makeshift@180, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_makeshift@180_full 2679 614 402 722
ZEDQA rrv rect zqa_rrv_1_75_walkie_manpack@180_half 749 0 1162 735
ZEDQA rrv 1_75 Base.ManPackRadio: face walkie_manpack@180, card 385 px
ZEDQA rrv rect zqa_rrv_1_75_walkie_manpack@180_full 2679 694 402 562
ZEDQA rrv rect zqa_rrv_1_75_ham_civilian@392_half 1929 0 1617 735
ZEDQA rrv 1_75 Base.HamRadio1: face ham_civilian@392, card 840 px
ZEDQA rrv rect zqa_rrv_1_75_ham_civilian@392_full 2543 802 674 346
ZEDQA rrv rect zqa_rrv_1_75_ham_army@392_half 1929 0 1617 735
ZEDQA rrv 1_75 Base.HamRadio2: face ham_army@392, card 840 px
ZEDQA rrv rect zqa_rrv_1_75_ham_army@392_full 2543 802 674 346
ZEDQA rrv rect zqa_rrv_1_75_ham_makeshift@392_half 1929 0 1617 735
ZEDQA rrv 1_75 Base.HamRadioMakeShift: face ham_makeshift@392, card 840 px
ZEDQA rrv rect zqa_rrv_1_75_ham_makeshift@392_full 2543 802 674 346
ZEDQA rrv scale 2.00: root 2.00
ZEDQA rrv rect zqa_rrv_2_00_radio_black@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.RadioBlack: face radio_black@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_radio_red@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.RadioRed: face radio_red@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_radio_handbuilt@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.RadioMakeShift: face radio_handbuilt@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_cd_player@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.CDplayer: face cd_player@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_toy@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.WalkieTalkie1: face walkie_toy@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_toy@206_full 2679 599 402 722
ZEDQA rrv rect zqa_rrv_2_00_walkie_valutech@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.WalkieTalkie2: face walkie_valutech@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_valutech@206_full 2679 599 402 722
ZEDQA rrv rect zqa_rrv_2_00_walkie_premium@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.WalkieTalkie3: face walkie_premium@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_premium@206_full 2679 599 402 722
ZEDQA rrv rect zqa_rrv_2_00_walkie_tactical@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.WalkieTalkie4: face walkie_tactical@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_tactical@206_full 2679 599 402 722
ZEDQA rrv rect zqa_rrv_2_00_walkie_army@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.WalkieTalkie5: face walkie_army@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_army@206_full 2679 599 402 722
ZEDQA rrv rect zqa_rrv_2_00_walkie_makeshift@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.WalkieTalkieMakeShift: face walkie_makeshift@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_makeshift@206_full 2679 599 402 722
ZEDQA rrv rect zqa_rrv_2_00_walkie_manpack@206_half 582 0 1328 840
ZEDQA rrv 2_00 Base.ManPackRadio: face walkie_manpack@206, card 440 px
ZEDQA rrv rect zqa_rrv_2_00_walkie_manpack@206_full 2679 679 402 562
ZEDQA rrv rect zqa_rrv_2_00_ham_civilian@450_half 1930 0 1848 840
ZEDQA rrv 2_00 Base.HamRadio1: face ham_civilian@450, card 960 px
ZEDQA rrv rect zqa_rrv_2_00_ham_civilian@450_full 2543 787 674 346
ZEDQA rrv rect zqa_rrv_2_00_ham_army@450_half 1930 0 1848 840
ZEDQA rrv 2_00 Base.HamRadio2: face ham_army@450, card 960 px
ZEDQA rrv rect zqa_rrv_2_00_ham_army@450_full 2543 787 674 346
ZEDQA rrv rect zqa_rrv_2_00_ham_makeshift@450_half 1930 0 1848 840
ZEDQA rrv 2_00 Base.HamRadioMakeShift: face ham_makeshift@450, card 960 px
ZEDQA rrv rect zqa_rrv_2_00_ham_makeshift@450_full 2543 787 674 346
ZEDQA rrv put back: the scale, the hands; 77 items and 21 sets taken away
ZEDQA rrv DONE
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
