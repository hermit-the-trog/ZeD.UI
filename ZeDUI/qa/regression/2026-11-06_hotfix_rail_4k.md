# ZeD-UI regression - 2026-11-06 20:41 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 20:41:47 |
| Finished | 2026-11-06 20:44:46 (2 min 59 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\you\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_admin_rail.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 22597 to 22603 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1920,1080 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 22602, 22603)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | mp_open.lua | mop | PASS | 39 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | mp_admin_rail.lua | arl | PASS | 44 | zqa_arl_01_loot.png, zqa_arl_02_admin_home.png, zqa_arl_03_queue.png, zqa_arl_04_card.png, zqa_arl_05_card_closed.png, zqa_arl_06_item_over_admin.png, zqa_arl_07_item_closed.png, zqa_arl_12_tab_craft.png, zqa_arl_13_tab_build.png, zqa_arl_14_tab_furniture.png, zqa_arl_15_tab_maps.png, zqa_arl_16_tab_forage.png, zqa_arl_17_tab_animals.png, zqa_arl_19_tab_vehicle.png, zqa_arl_20_char_server.png |  |

## Scripts

### 1. mp_open.lua (`ZEDQA mop`) - PASS, 39 s

- go 22599 at 20:42:53

```text
LOG : Lua f:47 st:178,971,749> [ZeD.QA] state #2 speed=1 paused=false player=10600,9799 grid=19 inCar=false vehicles=9 missing=get
LOG : Lua f:47 st:178,971,750> [ZeD.QA] windows reset (R)
LOG : Lua f:47 st:178,971,751> [ZeD.QA] run #2 ok=true
LOG : Lua f:1085 st:178,981,081> ZEDQA mop PASS god mode on
LOG : General f:1387 st:178,983,824> [06-11-26 20:43:05.987][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1387 st:178,983,827> [06-11-26 20:43:05.991][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1407 st:178,984,079> [06-11-26 20:43:06.242][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1456 st:178,984,487> [06-11-26 20:43:06.651][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1535 st:178,985,155> [06-11-26 20:43:07.318][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1563 st:178,985,396> [06-11-26 20:43:07.560][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1644 st:178,986,079> [06-11-26 20:43:08.243][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1692 st:178,986,479> [06-11-26 20:43:08.643][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:1719 st:178,986,697> ZEDQA mop at 10600,9800: outdoors and free true
LOG : General f:1750 st:178,986,963> [06-11-26 20:43:09.127][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1803 st:178,987,408> [06-11-26 20:43:09.570][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1851 st:178,987,805> [06-11-26 20:43:09.969][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1909 st:178,988,288> [06-11-26 20:43:10.452][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1962 st:178,988,730> [06-11-26 20:43:10.893][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1962 st:178,988,733> [06-11-26 20:43:10.896][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2010 st:178,989,130> [06-11-26 20:43:11.293][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2121 st:178,990,056> [06-11-26 20:43:12.219][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2121 st:178,990,060> [06-11-26 20:43:12.223][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2279 st:178,991,381> [06-11-26 20:43:13.545][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2312 st:178,991,656> [06-11-26 20:43:13.818][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2313 st:178,991,669> [06-11-26 20:43:13.831][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2347 st:178,991,956> [06-11-26 20:43:14.119][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2411 st:178,992,489> [06-11-26 20:43:14.653][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2437 st:178,992,706> [06-11-26 20:43:14.868][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2471 st:178,992,992> [06-11-26 20:43:15.154][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2495 st:178,993,190> [06-11-26 20:43:15.353][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2595 st:178,994,039> [06-11-26 20:43:16.203][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2626 st:178,994,304> [06-11-26 20:43:16.467][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2626 st:178,994,312> [06-11-26 20:43:16.475][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2747 st:178,995,348> [06-11-26 20:43:17.512][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2782 st:178,995,640> [06-11-26 20:43:17.803][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2841 st:178,996,145> [06-11-26 20:43:18.309][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2894 st:178,996,615> [06-11-26 20:43:18.779][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2937 st:178,996,988> [06-11-26 20:43:19.152][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3046 st:178,997,950> [06-11-26 20:43:20.114][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3082 st:178,998,266> [06-11-26 20:43:20.429][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3141 st:178,998,774> [06-11-26 20:43:20.938][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3199 st:178,999,280> [06-11-26 20:43:21.443][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3234 st:178,999,582> [06-11-26 20:43:21.745][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3263 st:178,999,825> [06-11-26 20:43:21.989][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3393 st:179,000,916> [06-11-26 20:43:23.080][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3399 st:179,000,966> [06-11-26 20:43:23.130][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3420 st:179,001,146> [06-11-26 20:43:23.309][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3518 st:179,001,967> [06-11-26 20:43:24.131][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3524 st:179,002,017> [06-11-26 20:43:24.181][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3676 st:179,003,292> [06-11-26 20:43:25.455][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3711 st:179,003,585> [06-11-26 20:43:25.748][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3741 st:179,003,834> [06-11-26 20:43:25.997][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3811 st:179,004,426> [06-11-26 20:43:26.590][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3869 st:179,004,909> [06-11-26 20:43:27.073][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3898 st:179,005,151> [06-11-26 20:43:27.314][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4028 st:179,006,234> [06-11-26 20:43:28.396][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4048 st:179,006,400> [06-11-26 20:43:28.564][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4101 st:179,006,850> [06-11-26 20:43:29.013][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4186 st:179,007,559> [06-11-26 20:43:29.723][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4205 st:179,007,726> [06-11-26 20:43:29.889][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4309 st:179,008,595> [06-11-26 20:43:30.758][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4344 st:179,008,884> [06-11-26 20:43:31.048][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:4408 st:179,009,413> ZEDQA mop PASS open ground
LOG : Lua f:4408 st:179,009,414> ZEDQA mop DONE
LOG : General f:4467 st:179,009,917> [06-11-26 20:43:32.081][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4468 st:179,009,933> [06-11-26 20:43:32.096][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4507 st:179,010,259> [06-11-26 20:43:32.423][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4625 st:179,011,242> [06-11-26 20:43:33.405][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4626 st:179,011,256> [06-11-26 20:43:33.419][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4719 st:179,012,034> [06-11-26 20:43:34.198][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4783 st:179,012,567> [06-11-26 20:43:34.730][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4858 st:179,013,203> [06-11-26 20:43:35.367][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 22600 at 20:43:35

```text
LOG : Lua f:4937 st:179,013,868> [ZeD.QA] state #3 speed=1 paused=false player=10600,9800 grid=19 inCar=false vehicles=10 missing=get
LOG : Lua f:4937 st:179,013,870> [ZeD.QA] windows reset (R)
LOG : Lua f:4937 st:179,013,871> ZEDQA pnw pinned both windows
LOG : Lua f:4937 st:179,013,872> [ZeD.QA] run #3 ok=true
LOG : Lua f:4957 st:179,014,030> ZEDQA pnw DONE
LOG : General f:5034 st:179,014,684> [06-11-26 20:43:36.847][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5049 st:179,014,809> [06-11-26 20:43:36.973][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5115 st:179,015,359> [06-11-26 20:43:37.522][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5193 st:179,016,009> [06-11-26 20:43:38.172][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5196 st:179,016,039> [06-11-26 20:43:38.203][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5303 st:179,016,934> [06-11-26 20:43:39.097][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5351 st:179,017,334> [06-11-26 20:43:39.496][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5377 st:179,017,552> [06-11-26 20:43:39.716][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
```

### 3. mp_admin_rail.lua (`ZEDQA arl`) - PASS, 44 s

- go 22601 at 20:43:40
- screenshots: zqa_arl_01_loot.png, zqa_arl_02_admin_home.png, zqa_arl_03_queue.png, zqa_arl_04_card.png, zqa_arl_05_card_closed.png, zqa_arl_06_item_over_admin.png, zqa_arl_07_item_closed.png, zqa_arl_12_tab_craft.png, zqa_arl_13_tab_build.png, zqa_arl_14_tab_furniture.png, zqa_arl_15_tab_maps.png, zqa_arl_16_tab_forage.png, zqa_arl_17_tab_animals.png, zqa_arl_19_tab_vehicle.png, zqa_arl_20_char_server.png

```text
LOG : Lua f:5477 st:179,018,384> [ZeD.QA] state #4 speed=1 paused=false player=10600,9800 grid=19 inCar=false vehicles=10 missing=get
LOG : Lua f:5477 st:179,018,385> [ZeD.QA] windows reset (R)
LOG : Lua f:5477 st:179,018,386> [ZeD.QA] run #4 ok=true
LOG : General f:5509 st:179,018,659> [06-11-26 20:43:40.822][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5547 st:179,018,984> [06-11-26 20:43:41.148][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5664 st:179,019,985> [06-11-26 20:43:42.148][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:5665 st:179,019,989> ZEDQA arl loot tab=loot mode=nil win 777x735 footer=39 strip x=714 vis=true zones=9
LOG : General f:5667 st:179,021,363> [06-11-26 20:43:43.527][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5700 st:179,022,105> [06-11-26 20:43:44.268][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5716 st:179,022,326> [06-11-26 20:43:44.489][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:5778 st:179,023,050> ZEDQA arl admin home tab=admin mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:5782 st:179,024,558> [06-11-26 20:43:46.721][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5810 st:179,024,801> [06-11-26 20:43:46.964][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5812 st:179,024,832> [06-11-26 20:43:46.996][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:5916 st:179,025,721> ZEDQA arl queue tab=admin mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:5922 st:179,027,031> [06-11-26 20:43:49.195][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5950 st:179,027,285> [06-11-26 20:43:49.448][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6034 st:179,028,016> [06-11-26 20:43:50.180][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6074 st:179,028,369> [06-11-26 20:43:50.532][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6085 st:179,028,466> ZEDQA arl card tab=admin mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:6169 st:179,030,529> [06-11-26 20:43:52.693][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6177 st:179,030,625> [06-11-26 20:43:52.789][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6211 st:179,030,935> ZEDQA arl card closed tab=admin mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : Lua f:6212 st:179,032,193> ZEDQA arl item card over Admin: Belt
LOG : General f:6247 st:179,032,558> [06-11-26 20:43:54.721][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6307 st:179,033,185> [06-11-26 20:43:55.348][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6327 st:179,033,401> [06-11-26 20:43:55.565][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6357 st:179,033,704> ZEDQA arl item card tab=admin mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:6364 st:179,035,052> [06-11-26 20:43:57.215][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6376 st:179,035,247> [06-11-26 20:43:57.410][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6442 st:179,035,901> [06-11-26 20:43:58.064][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6467 st:179,036,184> [06-11-26 20:43:58.348][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6497 st:179,036,448> ZEDQA arl item card closed tab=admin mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : Lua f:6498 st:179,037,743> ZEDQA arl pressed the rail's Loot
LOG : General f:6502 st:179,037,789> [06-11-26 20:43:59.953][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6504 st:179,037,817> [06-11-26 20:43:59.981][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6584 st:179,038,501> [06-11-26 20:44:00.664][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6639 st:179,038,947> ZEDQA arl after the rail press tab=loot mode=nil win 777x735 footer=39 strip x=714 vis=true zones=9
LOG : General f:6655 st:179,039,098> [06-11-26 20:44:01.262][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6724 st:179,039,772> [06-11-26 20:44:01.936][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6730 st:179,039,855> [06-11-26 20:44:02.017][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6752 st:179,040,066> [06-11-26 20:44:02.229][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6801 st:179,040,551> ZEDQA arl tab craft tab=craft mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:6848 st:179,042,249> [06-11-26 20:44:04.413][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6868 st:179,042,420> [06-11-26 20:44:04.584][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6924 st:179,042,904> [06-11-26 20:44:05.067][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6949 st:179,043,117> [06-11-26 20:44:05.281][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6951 st:179,043,126> ZEDQA arl tab build tab=build mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:7012 st:179,045,012> [06-11-26 20:44:07.176][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7055 st:179,045,430> [06-11-26 20:44:07.594][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7086 st:179,045,709> ZEDQA arl tab furniture tab=furniture mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:7134 st:179,047,833> [06-11-26 20:44:09.996][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7137 st:179,047,871> [06-11-26 20:44:10.034][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7186 st:179,048,298> ZEDQA arl tab maps tab=maps mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:7190 st:179,049,587> [06-11-26 20:44:11.751][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7193 st:179,049,626> [06-11-26 20:44:11.789][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7269 st:179,050,350> [06-11-26 20:44:12.514][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7322 st:179,050,838> ZEDQA arl tab forage tab=forage mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:7326 st:179,052,162> [06-11-26 20:44:14.326][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7362 st:179,052,468> [06-11-26 20:44:14.631][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7388 st:179,052,694> [06-11-26 20:44:14.858][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7407 st:179,052,864> [06-11-26 20:44:15.028][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7474 st:179,053,424> ZEDQA arl tab animals tab=animals mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:7543 st:179,055,307> [06-11-26 20:44:17.470][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7544 st:179,055,324> [06-11-26 20:44:17.487][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7550 st:179,055,394> [06-11-26 20:44:17.557][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7651 st:179,056,260> [06-11-26 20:44:18.424][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7690 st:179,056,627> [06-11-26 20:44:18.789][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7693 st:179,056,662> [06-11-26 20:44:18.825][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7790 st:179,057,590> [06-11-26 20:44:19.754][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7797 st:179,057,640> ZEDQA arl tab vehicle tab=vehicle mode=tab win 1617x735 footer=39 strip x=1554 vis=true zones=9
LOG : General f:7809 st:179,059,209> [06-11-26 20:44:21.372][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7854 st:179,059,994> [06-11-26 20:44:22.157][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7873 st:179,060,292> [06-11-26 20:44:22.455][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7882 st:179,060,441> [06-11-26 20:44:22.605][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7883 st:179,060,446> ZEDQA arl Character server tab: active=server footer=39
LOG : Lua f:7884 st:179,061,755> ZEDQA arl DONE
LOG : General f:7934 st:179,062,353> [06-11-26 20:44:24.517][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7947 st:179,062,540> [06-11-26 20:44:24.703][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7967 st:179,062,859> [06-11-26 20:44:25.022][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8034 st:179,063,689> [06-11-26 20:44:25.852][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8049 st:179,063,897> [06-11-26 20:44:26.060][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8097 st:179,064,432> [06-11-26 20:44:26.595][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8122 st:179,064,700> [06-11-26 20:44:26.862][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N st:0 at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N st:0 at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeD-UI\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeD-UI\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeD-UI\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeD-UI\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeDQAShim\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeDQAShim\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeDQAShim\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\you\Zomboid\mods\ZeDQAShim\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
