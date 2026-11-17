# ZeD-UI regression - 2026-11-17 13:01 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 13:01:08 |
| Finished | 2026-11-17 13:07:31 (6 min 22 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\zedqa_b19_light_popups.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 28300 to 28305 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28304, 28305)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 3 | zedqa_b19_light_popups.lua | lpp | WARN | 253 |  | 60 ERR line(s); late output from unl (216 line(s), not counted) |
| 4 | gallery_reload.lua | rel | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28300 at 13:02:41

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
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 28301 at 13:02:47

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 50.0 of 8 kg, 117 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 60 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl pointer parked at 3837,1080 and hidden
[ZeD.QA] run #2 ok=true
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1
ZEDQA unl DONE
ZEDQA unl load 8.2 of 8 kg, 57 items, Heavy Load 1   (x3)
```

### 3. zedqa_b19_light_popups.lua (`ZEDQA lpp`) - WARN, 253 s

- go 28302 at 13:02:51
- 60 ERR line(s)
- late output from unl (216 line(s), not counted)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lpp start (249 steps)
[ZeD.QA] run #3 ok=true
ZEDQA lpp start: carried 8.2 of 8 kg
ZEDQA lpp theme dark / teal
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_left_note
ZEDQA lpp FAIL dark_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_left
ZEDQA lpp FAIL dark_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_bottom_note
ZEDQA lpp FAIL dark_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_bottom
ZEDQA lpp FAIL dark_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_right_note
ZEDQA lpp FAIL dark_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_right
ZEDQA lpp FAIL dark_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.2 of 17 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_simple_read
ZEDQA lpp FAIL dark_simple_read: the fill is the tooltips' light grey (0.05,0.06,0.06 (9540), 0.80,0.80,0.80 (7140), 0.76,0.76,0.76 (4000))
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_simple_stopped
ZEDQA lpp FAIL dark_simple_stopped: the fill is the tooltips' light grey (0.05,0.06,0.06 (9540), 0.80,0.80,0.80 (7140), 0.76,0.76,0.76 (4000))
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA lpp not run: dark_simple_rest (the bar's phase is nil, not work)
ZEDQA unl load 9.2 of 20 kg, 58 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.4 of 20 kg, 59 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 9.3 of 20 kg, 59 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_simple_done
ZEDQA lpp FAIL dark_simple_done: the fill is the tooltips' light grey (0.05,0.06,0.06 (553320), 0.80,0.80,0.80 (414120), 0.76,0.76,0.76 (232000))
ZEDQA unl load 9.3 of 20 kg, 59 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_dark_detailed_read
ZEDQA lpp PASS dark_detailed_read: the fill is the tooltips' light grey (0.80,0.80,0.80 (61460), 0.05,0.06,0.06 (9600), 0.26,0.26,0.26 (8480))
ZEDQA unl load 9.3 of 20 kg, 59 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_detailed_stopped
ZEDQA lpp PASS dark_detailed_stopped: the fill is the tooltips' light grey (0.80,0.80,0.80 (61460), 0.05,0.06,0.06 (9600), 0.26,0.26,0.26 (8480))
ZEDQA unl load 9.3 of 20 kg, 59 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA lpp not run: dark_detailed_rest (the bar's phase is nil, not work)
ZEDQA unl load 9.3 of 20 kg, 59 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp shot lpp_dark_detailed_done
ZEDQA lpp PASS dark_detailed_done: the fill is the tooltips' light grey (0.80,0.80,0.80 (2775880), 0.05,0.06,0.06 (417600), 0.26,0.26,0.26 (399040))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_dark_notice_mod
ZEDQA lpp FAIL dark_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.77,0.60,0.16 (2160))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_notice_mod_hover
ZEDQA lpp FAIL dark_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.77,0.60,0.16 (2160))
ZEDQA lpp PASS dark_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_dark_notice_guide
ZEDQA lpp FAIL dark_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (3060480), 0.80,0.80,0.80 (2961920), 0.77,0.60,0.16 (1440))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_notice_guide_hover
ZEDQA lpp FAIL dark_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (2295360), 0.80,0.80,0.80 (2221440), 0.77,0.60,0.16 (1080))
ZEDQA lpp PASS dark_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_speech
ZEDQA lpp FAIL dark_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (877280), 0.80,0.80,0.80 (825120))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA ff speed 2: time multiplier 5, true multiplier 5
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_speed
ZEDQA lpp FAIL dark_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (49760), 0.80,0.80,0.80 (38880), 0.05,0.05,0.05 (5120))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark pause: the queue still steps while paused (664 ms on, speed 0)
ZEDQA lpp shot lpp_dark_pause
ZEDQA lpp FAIL dark_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (41600), 0.80,0.80,0.80 (31680), 0.05,0.05,0.05 (4480))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_halo_red
ZEDQA lpp FAIL dark_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (166720), 0.80,0.80,0.80 (142080))
ZEDQA lpp FAIL dark_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_halo_green
ZEDQA lpp FAIL dark_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (316320), 0.80,0.80,0.80 (274080))
ZEDQA lpp FAIL dark_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp theme light / teal
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.5 of 17 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_mood_left_note
ZEDQA lpp FAIL light_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.5 of 17 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_left
ZEDQA lpp FAIL light_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.5 of 17 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_bottom_note
ZEDQA lpp FAIL light_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.5 of 17 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_bottom
ZEDQA lpp FAIL light_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.5 of 17 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_right_note
ZEDQA lpp FAIL light_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.5 of 17 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_right
ZEDQA lpp FAIL light_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.5 of 17 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_simple_read
ZEDQA lpp FAIL light_simple_read: the fill is the tooltips' light grey (0.72,0.75,0.75 (9540), 0.80,0.80,0.80 (7140), 0.76,0.76,0.76 (4000))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_simple_stopped
ZEDQA lpp FAIL light_simple_stopped: the fill is the tooltips' light grey (0.72,0.75,0.75 (9540), 0.80,0.80,0.80 (7140), 0.76,0.76,0.76 (4000))
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA lpp not run: light_simple_rest (the bar's phase is nil, not work)
ZEDQA unl load 9.5 of 20 kg, 60 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.7 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 9.6 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_simple_done
ZEDQA lpp FAIL light_simple_done: the fill is the tooltips' light grey (0.72,0.75,0.75 (553320), 0.80,0.80,0.80 (414120), 0.76,0.76,0.76 (232000))
ZEDQA unl load 9.6 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_light_detailed_read
ZEDQA lpp PASS light_detailed_read: the fill is the tooltips' light grey (0.80,0.80,0.80 (61460), 0.72,0.75,0.75 (9600), 0.26,0.26,0.26 (8480))
ZEDQA unl load 9.6 of 20 kg, 61 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_detailed_stopped
ZEDQA lpp PASS light_detailed_stopped: the fill is the tooltips' light grey (0.80,0.80,0.80 (61460), 0.72,0.75,0.75 (9600), 0.26,0.26,0.26 (8480))
ZEDQA unl load 9.6 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA lpp not run: light_detailed_rest (the bar's phase is nil, not work)
ZEDQA unl load 9.6 of 20 kg, 61 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp shot lpp_light_detailed_done
ZEDQA lpp PASS light_detailed_done: the fill is the tooltips' light grey (0.80,0.80,0.80 (2775880), 0.72,0.75,0.75 (417600), 0.26,0.26,0.26 (399040))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_light_notice_mod
ZEDQA lpp FAIL light_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.42,0.33,0.06 (2160))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_notice_mod_hover
ZEDQA lpp FAIL light_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 0.42,0.33,0.06 (2160))
ZEDQA lpp PASS light_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_light_notice_guide
ZEDQA lpp FAIL light_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (3060480), 0.80,0.80,0.80 (2961920), 0.42,0.33,0.06 (1440))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_notice_guide_hover
ZEDQA lpp FAIL light_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (2295360), 0.80,0.80,0.80 (2221440), 0.42,0.33,0.06 (1080))
ZEDQA lpp PASS light_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_speech
ZEDQA lpp FAIL light_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (877280), 0.80,0.80,0.80 (825120))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA lpp shot lpp_light_speed
ZEDQA lpp FAIL light_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (49760), 0.80,0.80,0.80 (38880), 0.05,0.05,0.05 (5120))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light pause: the queue still steps while paused (658 ms on, speed 0)
ZEDQA lpp shot lpp_light_pause
ZEDQA lpp FAIL light_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (41600), 0.80,0.80,0.80 (31680), 0.05,0.05,0.05 (4480))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_halo_red
ZEDQA lpp FAIL light_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (166720), 0.80,0.80,0.80 (142080))
ZEDQA lpp FAIL light_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_halo_green
ZEDQA lpp FAIL light_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (316320), 0.80,0.80,0.80 (274080))
ZEDQA lpp FAIL light_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp theme hicon / teal
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.8 of 17 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_mood_left_note
ZEDQA lpp FAIL hicon_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.8 of 17 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_left
ZEDQA lpp FAIL hicon_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.8 of 17 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_bottom_note
ZEDQA lpp FAIL hicon_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.8 of 17 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_bottom
ZEDQA lpp FAIL hicon_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.8 of 17 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_right_note
ZEDQA lpp FAIL hicon_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.8 of 17 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_right
ZEDQA lpp FAIL hicon_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 9.8 of 17 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_simple_read
ZEDQA lpp FAIL hicon_simple_read: the fill is the tooltips' light grey (0.03,0.04,0.04 (9540), 0.80,0.80,0.80 (7140), 0.76,0.76,0.76 (4000))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_simple_stopped
ZEDQA lpp FAIL hicon_simple_stopped: the fill is the tooltips' light grey (0.03,0.04,0.04 (9540), 0.80,0.80,0.80 (7140), 0.76,0.76,0.76 (4000))
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA lpp not run: hicon_simple_rest (the bar's phase is nil, not work)
ZEDQA unl load 9.8 of 20 kg, 62 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 10.0 of 20 kg, 63 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 9.9 of 20 kg, 63 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_simple_done
ZEDQA lpp FAIL hicon_simple_done: the fill is the tooltips' light grey (0.03,0.04,0.04 (553320), 0.80,0.80,0.80 (414120), 0.76,0.76,0.76 (232000))
ZEDQA unl load 9.9 of 20 kg, 63 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_hicon_detailed_read
ZEDQA lpp PASS hicon_detailed_read: the fill is the tooltips' light grey (0.80,0.80,0.80 (61460), 0.03,0.04,0.04 (9600), 0.26,0.26,0.26 (8480))
ZEDQA unl load 9.9 of 20 kg, 63 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_detailed_stopped
ZEDQA lpp PASS hicon_detailed_stopped: the fill is the tooltips' light grey (0.80,0.80,0.80 (61460), 0.03,0.04,0.04 (9600), 0.26,0.26,0.26 (8480))
ZEDQA unl load 9.9 of 20 kg, 63 items, Heavy Load 0   (late output from unl)   (x8)
ZEDQA lpp not run: hicon_detailed_rest (the bar's phase is nil, not work)
ZEDQA unl load 9.9 of 20 kg, 63 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp shot lpp_hicon_detailed_done
ZEDQA lpp PASS hicon_detailed_done: the fill is the tooltips' light grey (0.80,0.80,0.80 (2775880), 0.03,0.04,0.04 (417600), 0.26,0.26,0.26 (399040))
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_hicon_notice_mod
ZEDQA lpp FAIL hicon_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 1.00,0.80,0.13 (2160))
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_notice_mod_hover
ZEDQA lpp FAIL hicon_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (1074000), 0.80,0.80,0.80 (990240), 1.00,0.80,0.13 (2160))
ZEDQA lpp PASS hicon_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_hicon_notice_guide
ZEDQA lpp FAIL hicon_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (3060480), 0.80,0.80,0.80 (2961920), 1.00,0.80,0.13 (1440))
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_notice_guide_hover
ZEDQA lpp FAIL hicon_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (2295360), 0.80,0.80,0.80 (2221440), 1.00,0.80,0.13 (1080))
ZEDQA lpp PASS hicon_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_speech
ZEDQA lpp FAIL hicon_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (877280), 0.80,0.80,0.80 (825120))
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA lpp shot lpp_hicon_speed
ZEDQA lpp FAIL hicon_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (49760), 0.80,0.80,0.80 (38880), 0.05,0.05,0.05 (5120))
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon pause: the queue still steps while paused (664 ms on, speed 0)
ZEDQA lpp shot lpp_hicon_pause
ZEDQA lpp FAIL hicon_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (41600), 0.80,0.80,0.80 (31680), 0.05,0.05,0.05 (4480))
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_halo_red
ZEDQA lpp FAIL hicon_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (166720), 0.80,0.80,0.80 (142080))
ZEDQA lpp FAIL hicon_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_halo_green
ZEDQA lpp FAIL hicon_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (316320), 0.80,0.80,0.80 (274080))
ZEDQA lpp FAIL hicon_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA unl load 10.1 of 20 kg, 64 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)
ZEDQA lpp put back: theme light / teal, options, stats, actions, things, draws
ZEDQA lpp 15 passed, 60 failed
ZEDQA lpp DONE
ZEDQA unl load 8.2 of 20 kg, 57 items, Heavy Load 0   (late output from unl)   (x3)
```

### 4. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 28303 at 13:07:08

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.2 of 20 kg, 57 items, Heavy Load 0
ZEDQA rel put back 60 things; after: 50.0 of 20 kg, 117 items, Heavy Load 1 OVER
[ZeD.QA] run #4 ok=true
ZEDQA rel DONE
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
