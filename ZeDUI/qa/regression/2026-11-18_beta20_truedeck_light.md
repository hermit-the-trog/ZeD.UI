# ZeD-UI regression - 2026-11-18 10:21 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-18 10:21:48 |
| Finished | 2026-11-18 10:26:36 (4 min 48 s) |
| Mode | windowed (1280x800 window) |
| Display | fontSize=2 fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\zedqa_b19_light_popups.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 29403 to 29408 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800; pointer parked at (2565,1514)
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29407, 29408)
- pzrestorewin.ps1: fullScreen=false height=2160 width=3840
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_unload.lua | unl | PASS | 1 |  |  |
| 3 | zedqa_b19_light_popups.lua | lpp | WARN | 188 |  | 45 ERR line(s); late output from unl (196 line(s), not counted) |
| 4 | gallery_reload.lua | rel | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29403 at 10:22:52

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 360,0 276x315 rolled false pinned true/true
ZEDQA pre layout world 644,0 276x315 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. gallery_unload.lua (`ZEDQA unl`) - PASS, 1 s

- go 29404 at 10:22:58

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA unl before: 38.2 of 8 kg, 56 items, Heavy Load 1 OVER
ZEDQA unl taken out of the inventory for the run: 34 things (kept in GAL_UNLOAD.stash)
ZEDQA unl after: 8.3 of 8 kg, 22 items, Heavy Load 0
ZEDQA unl pointer parked at 1277,400 and hidden
[ZeD.QA] run #2 ok=true
ZEDQA unl load 8.3 of 8 kg, 22 items, Heavy Load 0
ZEDQA unl DONE
ZEDQA unl load 8.3 of 8 kg, 22 items, Heavy Load 0   (x3)
```

### 3. zedqa_b19_light_popups.lua (`ZEDQA lpp`) - WARN, 188 s

- go 29405 at 10:23:02
- 45 ERR line(s)
- late output from unl (196 line(s), not counted)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA lpp start (309 steps)
[ZeD.QA] run #3 ok=true
ZEDQA lpp start: carried 0.0 of 8 kg
ZEDQA lpp theme dark / teal
ZEDQA unl load 8.3 of 18 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.3 of 16 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.3 of 15 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_mood_left_note
ZEDQA lpp FAIL dark_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.3 of 16 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_mood_left
ZEDQA lpp FAIL dark_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.3 of 16 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 8.3 of 15 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_mood_bottom_note
ZEDQA lpp FAIL dark_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.3 of 16 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_mood_bottom
ZEDQA lpp FAIL dark_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.3 of 16 kg, 22 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_mood_right_note
ZEDQA lpp FAIL dark_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.3 of 16 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_mood_right
ZEDQA lpp FAIL dark_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 8.3 of 16 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.3 of 18 kg, 23 items, Heavy Load 0   (late output from unl)
ZEDQA ff speed 3: time multiplier 20, true multiplier 20
ZEDQA lpp dark_simple_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.32, 1 queued
ZEDQA lpp shot lpp_dark_simple_read
ZEDQA lpp dark_simple_read: colors drawn, most area first: 0.26,0.26,0.26 (43650), 0.10,0.10,0.12 (17850), 0.80,0.80,0.80 (15900), 0.20,0.20,0.22 (10000), 0.05,0.05,0.05 (2400), 0.28,0.63,0.55 (1100)
ZEDQA lpp progress 0.42 (wanted 0.40)
ZEDQA lpp dark_simple_stopped: stopped at progress 0.42
ZEDQA lpp dark_simple_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_simple_stopped
ZEDQA lpp dark_simple_stopped: colors drawn, most area first: 0.26,0.26,0.26 (2385), 0.10,0.10,0.12 (1785), 0.20,0.20,0.22 (1000), 0.54,0.54,0.56 (400)
ZEDQA unl load 9.3 of 18 kg, 23 items, Heavy Load 0   (late output from unl)   (x6)
ZEDQA lpp dark_simple_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_dark_simple_rest
ZEDQA lpp dark_simple_rest: colors drawn, most area first: none caught
ZEDQA unl load 9.3 of 18 kg, 23 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_simple_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_dark_simple_walk
ZEDQA lpp dark_simple_walk: colors drawn, most area first: none caught
ZEDQA unl load 9.3 of 18 kg, 23 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 9.9 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_simple_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.52, 3 queued
ZEDQA lpp shot lpp_dark_simple_queue
ZEDQA lpp dark_simple_queue: colors drawn, most area first: 0.26,0.26,0.26 (13095), 0.10,0.10,0.12 (5355), 0.80,0.80,0.80 (4770), 0.20,0.20,0.22 (3000), 0.05,0.05,0.05 (720), 0.28,0.63,0.55 (120)
ZEDQA unl load 9.8 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_simple_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.35, 2 queued
ZEDQA lpp shot lpp_dark_simple_queue2
ZEDQA lpp dark_simple_queue2: colors drawn, most area first: 0.26,0.26,0.26 (21825), 0.10,0.10,0.12 (8925), 0.80,0.80,0.80 (7950), 0.20,0.20,0.22 (5000), 0.28,0.63,0.55 (1280), 0.05,0.05,0.05 (1200)
ZEDQA unl load 9.8 of 18 kg, 26 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.0 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 9.9 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_simple_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_simple_done
ZEDQA lpp dark_simple_done: colors drawn, most area first: 0.26,0.26,0.26 (138330), 0.10,0.10,0.12 (103530), 0.20,0.20,0.22 (58000), 0.28,0.63,0.55 (26140), 0.36,0.77,0.67 (5228), 0.12,0.49,0.13 (200)
ZEDQA unl load 9.9 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_detailed_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.31, 1 queued
ZEDQA lpp shot lpp_dark_detailed_read
ZEDQA lpp dark_detailed_read: colors drawn, most area first: 0.80,0.80,0.80 (151949), 0.26,0.26,0.26 (36824), 0.10,0.10,0.12 (21486), 0.28,0.63,0.55 (7453), 0.05,0.05,0.05 (2160)
ZEDQA unl load 9.9 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.41 (wanted 0.40)
ZEDQA lpp dark_detailed_stopped: stopped at progress 0.41
ZEDQA lpp dark_detailed_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_detailed_stopped
ZEDQA lpp dark_detailed_stopped: colors drawn, most area first: 0.80,0.80,0.80 (15535), 0.10,0.10,0.12 (2430), 0.26,0.26,0.26 (2140), 0.54,0.54,0.56 (640)
ZEDQA unl load 9.9 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp dark_detailed_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_dark_detailed_rest
ZEDQA lpp dark_detailed_rest: colors drawn, most area first: none caught
ZEDQA unl load 9.9 of 18 kg, 27 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp dark_detailed_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_dark_detailed_walk
ZEDQA lpp dark_detailed_walk: colors drawn, most area first: 0.80,0.80,0.80 (13325), 0.26,0.26,0.26 (1160)
ZEDQA unl load 9.9 of 18 kg, 27 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.5 of 18 kg, 30 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_detailed_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.52, 3 queued
ZEDQA lpp shot lpp_dark_detailed_queue
ZEDQA lpp dark_detailed_queue: colors drawn, most area first: 0.80,0.80,0.80 (40665), 0.26,0.26,0.26 (11100), 0.10,0.10,0.12 (5400), 0.28,0.63,0.55 (1676), 0.05,0.05,0.05 (1200), 0.20,0.20,0.22 (120)
ZEDQA lpp dark_detailed_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.38, 2 queued
ZEDQA lpp shot lpp_dark_detailed_queue2
ZEDQA lpp dark_detailed_queue2: colors drawn, most area first: 0.80,0.80,0.80 (67775), 0.26,0.26,0.26 (18500), 0.10,0.10,0.12 (9000), 0.28,0.63,0.55 (4136), 0.05,0.05,0.05 (2055), 0.20,0.20,0.22 (200)
ZEDQA unl load 10.5 of 18 kg, 30 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 10.7 of 18 kg, 31 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark_detailed_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_dark_detailed_done
ZEDQA lpp dark_detailed_done: colors drawn, most area first: 0.80,0.80,0.80 (693970), 0.10,0.10,0.12 (104400), 0.26,0.26,0.26 (99760), 0.28,0.63,0.55 (60372), 0.12,0.49,0.13 (301)
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_notice_mod
ZEDQA lpp FAIL dark_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (268500), 0.80,0.80,0.80 (247560), 0.77,0.60,0.16 (540))
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_notice_mod_hover
ZEDQA lpp FAIL dark_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (268500), 0.80,0.80,0.80 (247560), 0.77,0.60,0.16 (540))
ZEDQA lpp PASS dark_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_notice_guide
ZEDQA lpp FAIL dark_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (765120), 0.80,0.80,0.80 (740480), 0.77,0.60,0.16 (360))
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_notice_guide_hover
ZEDQA lpp FAIL dark_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (573840), 0.80,0.80,0.80 (555360), 0.77,0.60,0.16 (270))
ZEDQA lpp PASS dark_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_speech
ZEDQA lpp FAIL dark_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (219320), 0.80,0.80,0.80 (206280))
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp shot lpp_dark_speed
ZEDQA lpp FAIL dark_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (12440), 0.80,0.80,0.80 (9720), 0.05,0.05,0.05 (1280))
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp dark pause: the queue still steps while paused (657 ms on, speed 0)
ZEDQA lpp shot lpp_dark_pause
ZEDQA lpp FAIL dark_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (10400), 0.80,0.80,0.80 (7920), 0.05,0.05,0.05 (1120))
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_dark_halo_red
ZEDQA lpp FAIL dark_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (45760), 0.80,0.80,0.80 (39120), 0.75,0.11,0.11 (360))
ZEDQA lpp PASS dark_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_dark_halo_green
ZEDQA lpp FAIL dark_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (83160), 0.80,0.80,0.80 (72120), 0.12,0.49,0.13 (360))
ZEDQA lpp PASS dark_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA lpp theme light / teal
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 10.6 of 15 kg, 31 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_left_note
ZEDQA lpp FAIL light_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.6 of 15 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_mood_left
ZEDQA lpp FAIL light_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.6 of 15 kg, 31 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_bottom_note
ZEDQA lpp FAIL light_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.6 of 15 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_mood_bottom
ZEDQA lpp FAIL light_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.6 of 15 kg, 31 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_light_mood_right_note
ZEDQA lpp FAIL light_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.6 of 15 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_mood_right
ZEDQA lpp FAIL light_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 10.6 of 15 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_simple_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.32, 1 queued
ZEDQA lpp shot lpp_light_simple_read
ZEDQA lpp light_simple_read: colors drawn, most area first: 0.26,0.26,0.26 (43650), 0.10,0.10,0.12 (17850), 0.80,0.80,0.80 (15900), 0.20,0.20,0.22 (10000), 0.05,0.05,0.05 (2400), 0.28,0.63,0.55 (1080)
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.42 (wanted 0.40)
ZEDQA lpp light_simple_stopped: stopped at progress 0.42
ZEDQA lpp light_simple_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_simple_stopped
ZEDQA lpp light_simple_stopped: colors drawn, most area first: 0.26,0.26,0.26 (2385), 0.10,0.10,0.12 (1785), 0.20,0.20,0.22 (1000), 0.54,0.54,0.56 (400)
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp light_simple_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_light_simple_rest
ZEDQA lpp light_simple_rest: colors drawn, most area first: none caught
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp light_simple_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_light_simple_walk
ZEDQA lpp light_simple_walk: colors drawn, most area first: none caught
ZEDQA unl load 10.6 of 18 kg, 31 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 11.2 of 18 kg, 34 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_simple_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.52, 3 queued
ZEDQA lpp shot lpp_light_simple_queue
ZEDQA lpp light_simple_queue: colors drawn, most area first: 0.26,0.26,0.26 (13095), 0.10,0.10,0.12 (5355), 0.80,0.80,0.80 (4770), 0.20,0.20,0.22 (3000), 0.05,0.05,0.05 (720), 0.28,0.63,0.55 (120)
ZEDQA lpp light_simple_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.41, 2 queued
ZEDQA lpp shot lpp_light_simple_queue2
ZEDQA lpp light_simple_queue2: colors drawn, most area first: 0.26,0.26,0.26 (21825), 0.10,0.10,0.12 (8925), 0.80,0.80,0.80 (7950), 0.20,0.20,0.22 (5000), 0.28,0.63,0.55 (1360), 0.05,0.05,0.05 (1200)
ZEDQA unl load 11.1 of 18 kg, 34 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA unl load 11.3 of 18 kg, 35 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp light_simple_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_simple_done
ZEDQA lpp light_simple_done: colors drawn, most area first: 0.26,0.26,0.26 (138330), 0.10,0.10,0.12 (103530), 0.20,0.20,0.22 (58000), 0.28,0.63,0.55 (26200), 0.36,0.77,0.67 (5240), 0.12,0.49,0.13 (200)
ZEDQA unl load 11.3 of 18 kg, 35 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp light_detailed_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.32, 1 queued
ZEDQA lpp shot lpp_light_detailed_read
ZEDQA lpp light_detailed_read: colors drawn, most area first: 0.80,0.80,0.80 (169074), 0.26,0.26,0.26 (40944), 0.10,0.10,0.12 (23916), 0.10,0.40,0.33 (5850), 0.28,0.63,0.55 (2492), 0.05,0.05,0.05 (2400)
ZEDQA unl load 11.3 of 18 kg, 35 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.42 (wanted 0.40)
ZEDQA lpp light_detailed_stopped: stopped at progress 0.42
ZEDQA lpp light_detailed_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_detailed_stopped
ZEDQA lpp light_detailed_stopped: colors drawn, most area first: 0.80,0.80,0.80 (15535), 0.10,0.10,0.12 (2430), 0.26,0.26,0.26 (2140), 0.54,0.54,0.56 (640)
ZEDQA unl load 11.3 of 18 kg, 35 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp light_detailed_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_light_detailed_rest
ZEDQA lpp light_detailed_rest: colors drawn, most area first: none caught
ZEDQA unl load 11.3 of 18 kg, 35 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp light_detailed_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_light_detailed_walk
ZEDQA lpp light_detailed_walk: colors drawn, most area first: 0.80,0.80,0.80 (13325), 0.26,0.26,0.26 (1160)
ZEDQA unl load 11.3 of 18 kg, 35 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 11.9 of 18 kg, 38 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_detailed_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.52, 3 queued
ZEDQA lpp shot lpp_light_detailed_queue
ZEDQA lpp light_detailed_queue: colors drawn, most area first: 0.80,0.80,0.80 (40665), 0.26,0.26,0.26 (11100), 0.10,0.10,0.12 (5400), 0.10,0.40,0.33 (1380), 0.05,0.05,0.05 (1200), 0.28,0.63,0.55 (296)
ZEDQA unl load 11.8 of 18 kg, 38 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light_detailed_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.38, 2 queued
ZEDQA lpp shot lpp_light_detailed_queue2
ZEDQA lpp light_detailed_queue2: colors drawn, most area first: 0.80,0.80,0.80 (67775), 0.26,0.26,0.26 (18500), 0.10,0.10,0.12 (9000), 0.10,0.40,0.33 (2300), 0.05,0.05,0.05 (2055), 0.28,0.63,0.55 (1836)
ZEDQA unl load 11.8 of 18 kg, 38 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp light_detailed_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_light_detailed_done
ZEDQA lpp light_detailed_done: colors drawn, most area first: 0.80,0.80,0.80 (693970), 0.10,0.10,0.12 (104400), 0.26,0.26,0.26 (99760), 0.28,0.63,0.55 (33784), 0.10,0.40,0.33 (26588), 0.12,0.49,0.13 (301)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_light_notice_mod
ZEDQA lpp FAIL light_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (268500), 0.80,0.80,0.80 (247560), 0.42,0.33,0.06 (540))
ZEDQA lpp shot lpp_light_notice_mod_hover
ZEDQA lpp FAIL light_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (268500), 0.80,0.80,0.80 (247560), 0.42,0.33,0.06 (540))
ZEDQA lpp PASS light_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)   (x3)
ZEDQA lpp shot lpp_light_notice_guide
ZEDQA lpp FAIL light_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (765120), 0.80,0.80,0.80 (740480), 0.42,0.33,0.06 (360))
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_notice_guide_hover
ZEDQA lpp FAIL light_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (573840), 0.80,0.80,0.80 (555360), 0.42,0.33,0.06 (270))
ZEDQA lpp PASS light_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_speech
ZEDQA lpp FAIL light_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (219320), 0.80,0.80,0.80 (206280))
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp shot lpp_light_speed
ZEDQA lpp FAIL light_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (12440), 0.80,0.80,0.80 (9720), 0.05,0.05,0.05 (1280))
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp light pause: the queue still steps while paused (656 ms on, speed 0)
ZEDQA lpp shot lpp_light_pause
ZEDQA lpp FAIL light_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (10400), 0.80,0.80,0.80 (7920), 0.05,0.05,0.05 (1120))
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_halo_red
ZEDQA lpp FAIL light_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (45760), 0.80,0.80,0.80 (39120), 0.75,0.11,0.11 (360))
ZEDQA lpp PASS light_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_light_halo_green
ZEDQA lpp FAIL light_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (83160), 0.80,0.80,0.80 (72120), 0.12,0.49,0.13 (360))
ZEDQA lpp PASS light_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp theme hicon / teal
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.0 of 15 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_mood_left_note
ZEDQA lpp FAIL hicon_mood_left_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 12.0 of 15 kg, 39 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_left
ZEDQA lpp FAIL hicon_mood_left: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 12.0 of 15 kg, 39 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_bottom_note
ZEDQA lpp FAIL hicon_mood_bottom_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 12.0 of 15 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_mood_bottom
ZEDQA lpp FAIL hicon_mood_bottom: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 12.0 of 15 kg, 39 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_mood_right_note
ZEDQA lpp FAIL hicon_mood_right_note: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 12.0 of 15 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_mood_right
ZEDQA lpp FAIL hicon_mood_right: nothing was drawn by the light draws (no fill caught)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_simple_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.32, 1 queued
ZEDQA lpp shot lpp_hicon_simple_read
ZEDQA lpp hicon_simple_read: colors drawn, most area first: 0.26,0.26,0.26 (43650), 0.10,0.10,0.12 (17850), 0.80,0.80,0.80 (15900), 0.20,0.20,0.22 (10000), 0.05,0.05,0.05 (2400), 0.28,0.63,0.55 (1080)
ZEDQA lpp progress 0.41 (wanted 0.40)
ZEDQA lpp hicon_simple_stopped: stopped at progress 0.41
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_simple_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_hicon_simple_stopped
ZEDQA lpp hicon_simple_stopped: colors drawn, most area first: 0.26,0.26,0.26 (2385), 0.10,0.10,0.12 (1785), 0.20,0.20,0.22 (1000), 0.54,0.54,0.56 (400)
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp hicon_simple_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_hicon_simple_rest
ZEDQA lpp hicon_simple_rest: colors drawn, most area first: none caught
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp hicon_simple_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_hicon_simple_walk
ZEDQA lpp hicon_simple_walk: colors drawn, most area first: none caught
ZEDQA unl load 12.0 of 18 kg, 39 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.6 of 18 kg, 42 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_simple_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.52, 3 queued
ZEDQA lpp shot lpp_hicon_simple_queue
ZEDQA lpp hicon_simple_queue: colors drawn, most area first: 0.26,0.26,0.26 (13095), 0.10,0.10,0.12 (5355), 0.80,0.80,0.80 (4770), 0.20,0.20,0.22 (3000), 0.05,0.05,0.05 (720), 0.28,0.63,0.55 (120)
ZEDQA unl load 12.5 of 18 kg, 42 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_simple_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.38, 2 queued
ZEDQA lpp shot lpp_hicon_simple_queue2
ZEDQA lpp hicon_simple_queue2: colors drawn, most area first: 0.26,0.26,0.26 (21825), 0.10,0.10,0.12 (8925), 0.80,0.80,0.80 (7950), 0.20,0.20,0.22 (5000), 0.28,0.63,0.55 (1340), 0.05,0.05,0.05 (1200)
ZEDQA unl load 12.5 of 18 kg, 42 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 12.7 of 18 kg, 43 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp hicon_simple_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_hicon_simple_done
ZEDQA lpp hicon_simple_done: colors drawn, most area first: 0.26,0.26,0.26 (138330), 0.10,0.10,0.12 (103530), 0.20,0.20,0.22 (58000), 0.28,0.63,0.55 (26200), 0.36,0.77,0.67 (5240), 0.12,0.49,0.13 (200)
ZEDQA unl load 12.7 of 18 kg, 43 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp hicon_detailed_read: the bar reads phase work, noend false, bar queue 0/1, progress 0.32, 1 queued
ZEDQA lpp shot lpp_hicon_detailed_read
ZEDQA lpp hicon_detailed_read: colors drawn, most area first: 0.80,0.80,0.80 (169074), 0.26,0.26,0.26 (40944), 0.10,0.10,0.12 (23916), 0.28,0.63,0.55 (8342), 0.05,0.05,0.05 (2400)
ZEDQA unl load 12.7 of 18 kg, 43 items, Heavy Load 0   (late output from unl)
ZEDQA lpp progress 0.42 (wanted 0.40)
ZEDQA lpp hicon_detailed_stopped: stopped at progress 0.42
ZEDQA lpp hicon_detailed_stopped: the bar reads phase stopped, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_hicon_detailed_stopped
ZEDQA lpp hicon_detailed_stopped: colors drawn, most area first: 0.80,0.80,0.80 (15535), 0.10,0.10,0.12 (2430), 0.26,0.26,0.26 (2140), 0.54,0.54,0.56 (640)
ZEDQA unl load 12.7 of 18 kg, 43 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp hicon_detailed_rest: the bar reads phase nil, noend nil, bar queue nil/nil, progress -1.00, 0 queued (taken anyway)
ZEDQA lpp shot lpp_hicon_detailed_rest
ZEDQA lpp hicon_detailed_rest: colors drawn, most area first: none caught
ZEDQA unl load 12.7 of 18 kg, 43 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp hicon_detailed_walk: the bar reads phase walk, noend true, bar queue 0/1, progress 0.00, 2 queued
ZEDQA lpp shot lpp_hicon_detailed_walk
ZEDQA lpp hicon_detailed_walk: colors drawn, most area first: 0.80,0.80,0.80 (13325), 0.26,0.26,0.26 (1160)
ZEDQA unl load 12.7 of 18 kg, 43 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.3 of 18 kg, 46 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_detailed_queue: the bar reads phase work, noend false, bar queue 0/3, progress 0.52, 3 queued
ZEDQA lpp shot lpp_hicon_detailed_queue
ZEDQA lpp hicon_detailed_queue: colors drawn, most area first: 0.80,0.80,0.80 (40665), 0.26,0.26,0.26 (11100), 0.10,0.10,0.12 (5400), 0.28,0.63,0.55 (1676), 0.05,0.05,0.05 (1200), 0.20,0.20,0.22 (120)
ZEDQA unl load 13.2 of 18 kg, 46 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_detailed_queue2: the bar reads phase work, noend false, bar queue 1/3, progress 0.38, 2 queued
ZEDQA lpp shot lpp_hicon_detailed_queue2
ZEDQA lpp hicon_detailed_queue2: colors drawn, most area first: 0.80,0.80,0.80 (67775), 0.26,0.26,0.26 (18500), 0.10,0.10,0.12 (9000), 0.28,0.63,0.55 (4136), 0.05,0.05,0.05 (2055), 0.20,0.20,0.22 (200)
ZEDQA unl load 13.2 of 18 kg, 46 items, Heavy Load 0   (late output from unl)
ZEDQA unl load 13.4 of 18 kg, 47 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon_detailed_done: the bar reads phase done, noend false, bar queue 0/1, progress -1.00, 0 queued
ZEDQA lpp shot lpp_hicon_detailed_done
ZEDQA lpp hicon_detailed_done: colors drawn, most area first: 0.80,0.80,0.80 (693970), 0.10,0.10,0.12 (104400), 0.26,0.26,0.26 (99760), 0.28,0.63,0.55 (60048), 0.12,0.49,0.13 (602)
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_notice_mod
ZEDQA lpp FAIL hicon_notice_mod: the fill is the tooltips' light grey (0.26,0.26,0.26 (268500), 0.80,0.80,0.80 (247560), 1.00,0.80,0.13 (540))
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_notice_mod_hover
ZEDQA lpp FAIL hicon_notice_mod_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (268500), 0.80,0.80,0.80 (247560), 1.00,0.80,0.13 (540))
ZEDQA lpp PASS hicon_notice_mod_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_notice_guide
ZEDQA lpp FAIL hicon_notice_guide: the fill is the tooltips' light grey (0.26,0.26,0.26 (765120), 0.80,0.80,0.80 (740480), 1.00,0.80,0.13 (360))
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_notice_guide_hover
ZEDQA lpp FAIL hicon_notice_guide_hover: the fill is the tooltips' light grey (0.26,0.26,0.26 (573840), 0.80,0.80,0.80 (555360), 1.00,0.80,0.13 (270))
ZEDQA lpp PASS hicon_notice_guide_hover: the hover wash is the light palette's faint dark line (30 rects)
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_speech
ZEDQA lpp FAIL hicon_speech: the fill is the tooltips' light grey (0.26,0.26,0.26 (219320), 0.80,0.80,0.80 (206280))
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)   (x5)
ZEDQA lpp shot lpp_hicon_speed
ZEDQA lpp FAIL hicon_speed: the fill is the tooltips' light grey (0.26,0.26,0.26 (12440), 0.80,0.80,0.80 (9720), 0.05,0.05,0.05 (1280))
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)
ZEDQA lpp hicon pause: the queue still steps while paused (650 ms on, speed 0)
ZEDQA lpp shot lpp_hicon_pause
ZEDQA lpp FAIL hicon_pause: the fill is the tooltips' light grey (0.26,0.26,0.26 (10400), 0.80,0.80,0.80 (7920), 0.05,0.05,0.05 (1120))
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)   (x2)
ZEDQA lpp shot lpp_hicon_halo_red
ZEDQA lpp FAIL hicon_halo_red: the fill is the tooltips' light grey (0.26,0.26,0.26 (45760), 0.80,0.80,0.80 (39120), 0.75,0.11,0.11 (360))
ZEDQA lpp PASS hicon_halo_red: the red note keeps its color (0.75,0.11,0.11 drawn)
ZEDQA unl load 13.3 of 18 kg, 47 items, Heavy Load 0   (late output from unl)
ZEDQA lpp shot lpp_hicon_halo_green
ZEDQA lpp FAIL hicon_halo_green: the fill is the tooltips' light grey (0.26,0.26,0.26 (83160), 0.80,0.80,0.80 (72120), 0.12,0.49,0.13 (360))
ZEDQA lpp PASS hicon_halo_green: the green note keeps its color (0.12,0.49,0.13 drawn)
ZEDQA unl load 8.3 of 18 kg, 22 items, Heavy Load 0   (late output from unl)
ZEDQA lpp put back: theme light / teal, options, stats, actions, things, draws
ZEDQA lpp 12 passed, 45 failed
ZEDQA lpp DONE
ZEDQA unl load 8.3 of 18 kg, 22 items, Heavy Load 0   (late output from unl)   (x3)
```

### 4. gallery_reload.lua (`ZEDQA rel`) - PASS, 1 s

- go 29406 at 10:26:13

```text
[ZeD.QA] state #4 speed=1 paused=false player=926,13040 grid=15 inCar=false vehicles=9 missing=get
[ZeD.QA] windows reset (R)
ZEDQA rel before: 8.3 of 18 kg, 22 items, Heavy Load 0
ZEDQA rel put back 34 things; after: 38.2 of 18 kg, 56 items, Heavy Load 1 OVER
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
