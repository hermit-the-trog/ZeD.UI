# ZeD-UI regression - 2026-11-08 20:35 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-08 20:35:11 |
| Finished | 2026-11-08 20:38:04 (2 min 53 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.3.0-beta10 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b10_check_manifest.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 24227 to 24231 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 24230, 24231)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_b10_tooltips.lua | b10tt | PASS | 74 | zqa_b10tt_req_strip_dark_small.png, zqa_b10tt_req_list_dark_small.png, zqa_b10tt_req_strip_dark_large.png, zqa_b10tt_req_list_dark_large.png, zqa_b10tt_req_strip_light_small.png, zqa_b10tt_req_list_light_small.png, zqa_b10tt_req_strip_light_large.png, zqa_b10tt_req_list_light_large.png, zqa_b10tt_req_strip_hicon_small.png, zqa_b10tt_req_list_hicon_small.png, zqa_b10tt_req_strip_hicon_large.png, zqa_b10tt_req_list_hicon_large.png, zqa_b10tt_arrows_dark_red.png, zqa_b10tt_arrows_dark_orange.png, zqa_b10tt_arrows_dark_yellow.png, zqa_b10tt_arrows_dark_green.png, zqa_b10tt_arrows_dark_blue.png, zqa_b10tt_arrows_dark_teal.png, zqa_b10tt_arrows_dark_purple.png, zqa_b10tt_arrows_dark_pink.png, zqa_b10tt_arrows_dark_mono.png, zqa_b10tt_arrows_light_red.png, zqa_b10tt_arrows_light_orange.png, zqa_b10tt_arrows_light_yellow.png, zqa_b10tt_arrows_light_green.png, zqa_b10tt_arrows_light_blue.png, zqa_b10tt_arrows_light_teal.png, zqa_b10tt_arrows_light_purple.png, zqa_b10tt_arrows_light_pink.png, zqa_b10tt_arrows_light_mono.png, zqa_b10tt_arrows_hicon_red.png, zqa_b10tt_arrows_hicon_orange.png, zqa_b10tt_arrows_hicon_yellow.png, zqa_b10tt_arrows_hicon_green.png, zqa_b10tt_arrows_hicon_blue.png, zqa_b10tt_arrows_hicon_teal.png, zqa_b10tt_arrows_hicon_purple.png, zqa_b10tt_arrows_hicon_pink.png, zqa_b10tt_arrows_hicon_mono.png |  |
| 3 | zedqa_ctx_overlap.lua | ctxov | PASS | 10 | zqa_ctxov_list_natural.png, zqa_ctxov_list_overlap.png, zqa_ctxov_list_hover.png, zqa_ctxov_strip_drilled.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 24227 at 20:36:08

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 18.61 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_b10_tooltips.lua (`ZEDQA b10tt`) - PASS, 74 s

- go 24228 at 20:36:13
- screenshots: zqa_b10tt_req_strip_dark_small.png, zqa_b10tt_req_list_dark_small.png, zqa_b10tt_req_strip_dark_large.png, zqa_b10tt_req_list_dark_large.png, zqa_b10tt_req_strip_light_small.png, zqa_b10tt_req_list_light_small.png, zqa_b10tt_req_strip_light_large.png, zqa_b10tt_req_list_light_large.png, zqa_b10tt_req_strip_hicon_small.png, zqa_b10tt_req_list_hicon_small.png, zqa_b10tt_req_strip_hicon_large.png, zqa_b10tt_req_list_hicon_large.png, zqa_b10tt_arrows_dark_red.png, zqa_b10tt_arrows_dark_orange.png, zqa_b10tt_arrows_dark_yellow.png, zqa_b10tt_arrows_dark_green.png, zqa_b10tt_arrows_dark_blue.png, zqa_b10tt_arrows_dark_teal.png, zqa_b10tt_arrows_dark_purple.png, zqa_b10tt_arrows_dark_pink.png, zqa_b10tt_arrows_dark_mono.png, zqa_b10tt_arrows_light_red.png, zqa_b10tt_arrows_light_orange.png, zqa_b10tt_arrows_light_yellow.png, zqa_b10tt_arrows_light_green.png, zqa_b10tt_arrows_light_blue.png, zqa_b10tt_arrows_light_teal.png, zqa_b10tt_arrows_light_purple.png, zqa_b10tt_arrows_light_pink.png, zqa_b10tt_arrows_light_mono.png, zqa_b10tt_arrows_hicon_red.png, zqa_b10tt_arrows_hicon_orange.png, zqa_b10tt_arrows_hicon_yellow.png, zqa_b10tt_arrows_hicon_green.png, zqa_b10tt_arrows_hicon_blue.png, zqa_b10tt_arrows_hicon_teal.png, zqa_b10tt_arrows_hicon_purple.png, zqa_b10tt_arrows_hicon_pink.png, zqa_b10tt_arrows_hicon_mono.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b10tt screen 3840x2160 | ZeD scale 1.75 | language EN
ZEDQA b10tt start
[ZeD.QA] run #2 ok=true
ZEDQA b10tt PASS a drawers piece with an apple in it beside the character: Metal Cabinet
ZEDQA b10tt PASS dark: positiveText 9.30 : 1, dangerText 9.50 : 1 on surface 2
ZEDQA b10tt PASS light: positiveText 7.66 : 1, dangerText 7.51 : 1 on surface 2
ZEDQA b10tt PASS hicon: positiveText 9.77 : 1, dangerText 9.36 : 1 on surface 2
ZEDQA b10tt PASS strip dark small: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS strip dark small: the row is disabled
ZEDQA b10tt PASS strip dark small: the requirement list was read (rows and marks)
ZEDQA b10tt PASS strip dark small: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS strip dark small: no Name row (Skill)
ZEDQA b10tt PASS strip dark small: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS strip dark small: a met row (1)
ZEDQA b10tt PASS strip dark small: the saws and the full container missing (4)
ZEDQA b10tt PASS strip dark small: the condition row (1)
ZEDQA b10tt PASS strip dark small: the balloon is up
ZEDQA b10tt PASS strip dark small: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS strip dark small: the balloon is inside the screen (1932,751 511x255)
ZEDQA b10tt PASS strip dark small: the tail's tip is on the selected cell
ZEDQA b10tt PASS strip dark small: the balloon does not cover the strip
ZEDQA b10tt PASS strip dark small: Escape does not hide a menu's balloon
ZEDQA b10tt PASS list dark small: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS list dark small: the row is disabled
ZEDQA b10tt PASS list dark small: the requirement list was read (rows and marks)
ZEDQA b10tt PASS list dark small: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS list dark small: no Name row (Skill)
ZEDQA b10tt PASS list dark small: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS list dark small: a met row (1)
ZEDQA b10tt PASS list dark small: the saws and the full container missing (4)
ZEDQA b10tt PASS list dark small: the condition row (1)
ZEDQA b10tt PASS list dark small: the balloon is up
ZEDQA b10tt PASS list dark small: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS list dark small: the balloon is inside the screen (2647,1286 511x255)
ZEDQA b10tt PASS list dark small: beside the row (right)
ZEDQA b10tt PASS list dark small: the tail's tip at the row's height
ZEDQA b10tt PASS list dark small: Escape does not hide a menu's balloon
ZEDQA b10tt PASS strip dark large: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS strip dark large: the row is disabled
ZEDQA b10tt PASS strip dark large: the requirement list was read (rows and marks)
ZEDQA b10tt PASS strip dark large: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS strip dark large: no Name row (Skill)
ZEDQA b10tt PASS strip dark large: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS strip dark large: a met row (1)
ZEDQA b10tt PASS strip dark large: the saws and the full container missing (4)
ZEDQA b10tt PASS strip dark large: the condition row (1)
ZEDQA b10tt PASS strip dark large: the balloon is up
ZEDQA b10tt PASS strip dark large: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS strip dark large: the balloon is inside the screen (1933,710 586x290)
ZEDQA b10tt PASS strip dark large: the tail's tip is on the selected cell
ZEDQA b10tt PASS strip dark large: the balloon does not cover the strip
ZEDQA b10tt PASS strip dark large: Escape does not hide a menu's balloon
ZEDQA b10tt PASS list dark large: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS list dark large: the row is disabled
ZEDQA b10tt PASS list dark large: the requirement list was read (rows and marks)
ZEDQA b10tt PASS list dark large: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS list dark large: no Name row (Skill)
ZEDQA b10tt PASS list dark large: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS list dark large: a met row (1)
ZEDQA b10tt PASS list dark large: the saws and the full container missing (4)
ZEDQA b10tt PASS list dark large: the condition row (1)
ZEDQA b10tt PASS list dark large: the balloon is up
ZEDQA b10tt PASS list dark large: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS list dark large: the balloon is inside the screen (2753,1315 586x290)
ZEDQA b10tt PASS list dark large: beside the row (right)
ZEDQA b10tt PASS list dark large: the tail's tip at the row's height
ZEDQA b10tt PASS list dark large: Escape does not hide a menu's balloon
ZEDQA b10tt PASS strip light small: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS strip light small: the row is disabled
ZEDQA b10tt PASS strip light small: the requirement list was read (rows and marks)
ZEDQA b10tt PASS strip light small: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS strip light small: no Name row (Skill)
ZEDQA b10tt PASS strip light small: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS strip light small: a met row (1)
ZEDQA b10tt PASS strip light small: the saws and the full container missing (4)
ZEDQA b10tt PASS strip light small: the condition row (1)
ZEDQA b10tt PASS strip light small: the balloon is up
ZEDQA b10tt PASS strip light small: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS strip light small: the balloon is inside the screen (1932,751 511x255)
ZEDQA b10tt PASS strip light small: the tail's tip is on the selected cell
ZEDQA b10tt PASS strip light small: the balloon does not cover the strip
ZEDQA b10tt PASS strip light small: Escape does not hide a menu's balloon
ZEDQA b10tt PASS list light small: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS list light small: the row is disabled
ZEDQA b10tt PASS list light small: the requirement list was read (rows and marks)
ZEDQA b10tt PASS list light small: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS list light small: no Name row (Skill)
ZEDQA b10tt PASS list light small: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS list light small: a met row (1)
ZEDQA b10tt PASS list light small: the saws and the full container missing (4)
ZEDQA b10tt PASS list light small: the condition row (1)
ZEDQA b10tt PASS list light small: the balloon is up
ZEDQA b10tt PASS list light small: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS list light small: the balloon is inside the screen (2647,1286 511x255)
ZEDQA b10tt PASS list light small: beside the row (right)
ZEDQA b10tt PASS list light small: the tail's tip at the row's height
ZEDQA b10tt PASS list light small: Escape does not hide a menu's balloon
ZEDQA b10tt PASS strip light large: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS strip light large: the row is disabled
ZEDQA b10tt PASS strip light large: the requirement list was read (rows and marks)
ZEDQA b10tt PASS strip light large: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS strip light large: no Name row (Skill)
ZEDQA b10tt PASS strip light large: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS strip light large: a met row (1)
ZEDQA b10tt PASS strip light large: the saws and the full container missing (4)
ZEDQA b10tt PASS strip light large: the condition row (1)
ZEDQA b10tt PASS strip light large: the balloon is up
ZEDQA b10tt PASS strip light large: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS strip light large: the balloon is inside the screen (1933,710 586x290)
ZEDQA b10tt PASS strip light large: the tail's tip is on the selected cell
ZEDQA b10tt PASS strip light large: the balloon does not cover the strip
ZEDQA b10tt PASS strip light large: Escape does not hide a menu's balloon
ZEDQA b10tt PASS list light large: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS list light large: the row is disabled
ZEDQA b10tt PASS list light large: the requirement list was read (rows and marks)
ZEDQA b10tt PASS list light large: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS list light large: no Name row (Skill)
ZEDQA b10tt PASS list light large: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS list light large: a met row (1)
ZEDQA b10tt PASS list light large: the saws and the full container missing (4)
ZEDQA b10tt PASS list light large: the condition row (1)
ZEDQA b10tt PASS list light large: the balloon is up
ZEDQA b10tt PASS list light large: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS list light large: the balloon is inside the screen (2753,1315 586x290)
ZEDQA b10tt PASS list light large: beside the row (right)
ZEDQA b10tt PASS list light large: the tail's tip at the row's height
ZEDQA b10tt PASS list light large: Escape does not hide a menu's balloon
ZEDQA b10tt PASS strip hicon small: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS strip hicon small: the row is disabled
ZEDQA b10tt PASS strip hicon small: the requirement list was read (rows and marks)
ZEDQA b10tt PASS strip hicon small: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS strip hicon small: no Name row (Skill)
ZEDQA b10tt PASS strip hicon small: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS strip hicon small: a met row (1)
ZEDQA b10tt PASS strip hicon small: the saws and the full container missing (4)
ZEDQA b10tt PASS strip hicon small: the condition row (1)
ZEDQA b10tt PASS strip hicon small: the balloon is up
ZEDQA b10tt PASS strip hicon small: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS strip hicon small: the balloon is inside the screen (1932,751 511x255)
ZEDQA b10tt PASS strip hicon small: the tail's tip is on the selected cell
ZEDQA b10tt PASS strip hicon small: the balloon does not cover the strip
ZEDQA b10tt PASS strip hicon small: Escape does not hide a menu's balloon
ZEDQA b10tt PASS list hicon small: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS list hicon small: the row is disabled
ZEDQA b10tt PASS list hicon small: the requirement list was read (rows and marks)
ZEDQA b10tt PASS list hicon small: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS list hicon small: no Name row (Skill)
ZEDQA b10tt PASS list hicon small: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS list hicon small: a met row (1)
ZEDQA b10tt PASS list hicon small: the saws and the full container missing (4)
ZEDQA b10tt PASS list hicon small: the condition row (1)
ZEDQA b10tt PASS list hicon small: the balloon is up
ZEDQA b10tt PASS list hicon small: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS list hicon small: the balloon is inside the screen (2647,1286 511x255)
ZEDQA b10tt PASS list hicon small: beside the row (right)
ZEDQA b10tt PASS list hicon small: the tail's tip at the row's height
ZEDQA b10tt PASS list hicon small: Escape does not hide a menu's balloon
ZEDQA b10tt PASS strip hicon large: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS strip hicon large: the row is disabled
ZEDQA b10tt PASS strip hicon large: the requirement list was read (rows and marks)
ZEDQA b10tt PASS strip hicon large: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS strip hicon large: no Name row (Skill)
ZEDQA b10tt PASS strip hicon large: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS strip hicon large: a met row (1)
ZEDQA b10tt PASS strip hicon large: the saws and the full container missing (4)
ZEDQA b10tt PASS strip hicon large: the condition row (1)
ZEDQA b10tt PASS strip hicon large: the balloon is up
ZEDQA b10tt PASS strip hicon large: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS strip hicon large: the balloon is inside the screen (1933,710 586x290)
ZEDQA b10tt PASS strip hicon large: the tail's tip is on the selected cell
ZEDQA b10tt PASS strip hicon large: the balloon does not cover the strip
ZEDQA b10tt PASS strip hicon large: Escape does not hide a menu's balloon
ZEDQA b10tt PASS list hicon large: Disassemble > Metal Cabinet is in the menu
ZEDQA b10tt PASS list hicon large: the row is disabled
ZEDQA b10tt PASS list hicon large: the requirement list was read (rows and marks)
ZEDQA b10tt PASS list hicon large: no Name row (SCRIPT NAME)
ZEDQA b10tt PASS list hicon large: no Name row (Skill)
ZEDQA b10tt PASS list hicon large: no Name row (Tool needed)   (x2)
ZEDQA b10tt PASS list hicon large: a met row (1)
ZEDQA b10tt PASS list hicon large: the saws and the full container missing (4)
ZEDQA b10tt PASS list hicon large: the condition row (1)
ZEDQA b10tt PASS list hicon large: the balloon is up
ZEDQA b10tt PASS list hicon large: it is the menu's balloon (one at a time, the menu first)
ZEDQA b10tt PASS list hicon large: the balloon is inside the screen (2753,1315 586x290)
ZEDQA b10tt PASS list hicon large: beside the row (right)
ZEDQA b10tt PASS list hicon large: the tail's tip at the row's height
ZEDQA b10tt PASS list hicon large: Escape does not hide a menu's balloon
ZEDQA b10tt PASS dark red: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark red: the arrow on the accent 4.48 : 1
ZEDQA b10tt PASS dark orange: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark orange: the arrow on the accent 7.40 : 1
ZEDQA b10tt PASS dark yellow: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark yellow: the arrow on the accent 8.70 : 1
ZEDQA b10tt PASS dark green: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark green: the arrow on the accent 6.59 : 1
ZEDQA b10tt PASS dark blue: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark blue: the arrow on the accent 5.25 : 1
ZEDQA b10tt PASS dark teal: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark teal: the arrow on the accent 6.28 : 1
ZEDQA b10tt PASS dark purple: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark purple: the arrow on the accent 4.54 : 1
ZEDQA b10tt PASS dark pink: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark pink: the arrow on the accent 5.34 : 1
ZEDQA b10tt PASS dark mono: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS dark mono: the arrow on the accent 5.52 : 1
ZEDQA b10tt PASS light red: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light red: the arrow on the accent 9.27 : 1
ZEDQA b10tt PASS light orange: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light orange: the arrow on the accent 6.19 : 1
ZEDQA b10tt PASS light yellow: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light yellow: the arrow on the accent 5.65 : 1
ZEDQA b10tt PASS light green: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light green: the arrow on the accent 7.89 : 1
ZEDQA b10tt PASS light blue: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light blue: the arrow on the accent 8.63 : 1
ZEDQA b10tt PASS light teal: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light teal: the arrow on the accent 6.00 : 1
ZEDQA b10tt PASS light purple: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light purple: the arrow on the accent 10.65 : 1
ZEDQA b10tt PASS light pink: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light pink: the arrow on the accent 7.82 : 1
ZEDQA b10tt PASS light mono: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS light mono: the arrow on the accent 9.99 : 1
ZEDQA b10tt PASS hicon red: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon red: the arrow on the accent 4.48 : 1
ZEDQA b10tt PASS hicon orange: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon orange: the arrow on the accent 7.40 : 1
ZEDQA b10tt PASS hicon yellow: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon yellow: the arrow on the accent 8.70 : 1
ZEDQA b10tt PASS hicon green: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon green: the arrow on the accent 6.59 : 1
ZEDQA b10tt PASS hicon blue: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon blue: the arrow on the accent 5.25 : 1
ZEDQA b10tt PASS hicon teal: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon teal: the arrow on the accent 6.28 : 1
ZEDQA b10tt PASS hicon purple: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon purple: the arrow on the accent 4.54 : 1
ZEDQA b10tt PASS hicon pink: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon pink: the arrow on the accent 5.34 : 1
ZEDQA b10tt PASS hicon mono: the strip scrolls (its end boxes show)
ZEDQA b10tt PASS hicon mono: the arrow on the accent 5.52 : 1
ZEDQA b10tt RESULT 250 pass, 0 fail
ZEDQA b10tt DONE
```

### 3. zedqa_ctx_overlap.lua (`ZEDQA ctxov`) - PASS, 10 s

- go 24229 at 20:37:30
- screenshots: zqa_ctxov_list_natural.png, zqa_ctxov_list_overlap.png, zqa_ctxov_list_hover.png, zqa_ctxov_strip_drilled.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ctxov screen 3840x2160 | ZeD scale 1.75
ZEDQA ctxov start
[ZeD.QA] run #3 ok=true
ZEDQA ctxov PASS LIST an apple to right-click
ZEDQA ctxov PASS LIST the list style opened (class ZeD_ContextList)
ZEDQA ctxov LIST top level x=3406.1640625 w=419.8359375 | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA ctxov PASS LIST an Eat row
ZEDQA ctxov PASS LIST a pointer perfectly still on Eat opens its submenu (302 ms; nav mouse, hoverRow 1:1, hoverLi nil, sel 1)
ZEDQA ctxov PASS LIST the Eat submenu opened on hover
ZEDQA ctxov LIST submenu x=3060.1640625 w=350 (left of the parent) | rows: All, 1/2, 1/4
ZEDQA ctxov PASS LIST the submenu covers a good part of its parent (350 of 419.8359375 design pixels)
ZEDQA ctxov PASS LIST row 1 is also inside the parent's box
ZEDQA ctxov PASS LIST hovering submenu row 1 keeps the submenu open (levels 2)
ZEDQA ctxov PASS LIST submenu row 1 is the selection (1)
ZEDQA ctxov PASS LIST the parent stays on Eat (Eat)
ZEDQA ctxov PASS LIST row 2 is also inside the parent's box
ZEDQA ctxov PASS LIST hovering submenu row 2 keeps the submenu open (levels 2)
ZEDQA ctxov PASS LIST submenu row 2 is the selection (2)
ZEDQA ctxov PASS LIST the parent stays on Eat (Eat)
ZEDQA ctxov PASS LIST row 3 is also inside the parent's box
ZEDQA ctxov PASS LIST hovering submenu row 3 keeps the submenu open (levels 2)
ZEDQA ctxov PASS LIST submenu row 3 is the selection (3)
ZEDQA ctxov PASS LIST the parent stays on Eat (Eat)
ZEDQA ctxov PASS LIST after a run of moves the submenu is still open
ZEDQA ctxov PASS LIST a press on the overlap runs the submenu's row (levels before 2)
ZEDQA ctxov PASS STRIP the strip style opened (class ZeD_ContextMenu)
ZEDQA ctxov PASS STRIP an Eat cell with children
ZEDQA ctxov PASS STRIP Eat drilled in (path 1)
ZEDQA ctxov PASS STRIP hovering cell 1 keeps the drill-down (path 1)
ZEDQA ctxov PASS STRIP cell 1 is the selection (1)
ZEDQA ctxov PASS STRIP hovering cell 2 keeps the drill-down (path 1)
ZEDQA ctxov PASS STRIP cell 2 is the selection (2)
ZEDQA ctxov PASS STRIP hovering cell 3 keeps the drill-down (path 1)
ZEDQA ctxov PASS STRIP cell 3 is the selection (3)
ZEDQA ctxov ALL PASS
ZEDQA ctxov DONE
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
