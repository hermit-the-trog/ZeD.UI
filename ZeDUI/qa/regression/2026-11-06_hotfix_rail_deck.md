# ZeD-UI regression - 2026-11-06 20:45 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-06 20:45:28 |
| Finished | 2026-11-06 20:48:07 (2 min 39 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_admin_rail.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 22604 to 22610 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; at the main menu
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1929,1118 (the bridge had not armed in game after 30 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 22609, 22610)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | mp_open.lua | mop | PASS | 39 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | mp_admin_rail.lua | arl | PASS | 30 | zqa_arl_01_loot.png, zqa_arl_02_admin_home.png, zqa_arl_03_queue.png, zqa_arl_04_card.png, zqa_arl_05_card_closed.png, zqa_arl_06_item_over_admin.png, zqa_arl_07_item_closed.png, zqa_arl_12_tab_craft.png, zqa_arl_13_tab_build.png, zqa_arl_14_tab_furniture.png, zqa_arl_15_tab_maps.png, zqa_arl_16_tab_forage.png, zqa_arl_17_tab_animals.png, zqa_arl_19_tab_vehicle.png, zqa_arl_20_char_server.png |  |

## Scripts

### 1. mp_open.lua (`ZEDQA mop`) - PASS, 39 s

- go 22606 at 20:46:29

```text
LOG : Lua f:138 st:179,187,115> [ZeD.QA] state #2 speed=1 paused=false player=10600,9800 grid=15 inCar=false vehicles=8 missing=get
LOG : Lua f:138 st:179,187,117> [ZeD.QA] windows reset (R)
LOG : Lua f:138 st:179,187,118> [ZeD.QA] run #2 ok=true
LOG : General f:160 st:179,187,323> [06-11-26 20:46:29.484][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:160 st:179,187,326> [06-11-26 20:46:29.486][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:160 st:179,187,329> [06-11-26 20:46:29.491][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:214 st:179,187,800> [06-11-26 20:46:29.961][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:237 st:179,188,002> [06-11-26 20:46:30.163][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:307 st:179,188,642> [06-11-26 20:46:30.804][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:307 st:179,188,648> [06-11-26 20:46:30.808][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:364 st:179,189,137> [06-11-26 20:46:31.298][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:387 st:179,189,337> [06-11-26 20:46:31.499][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:387 st:179,189,342> [06-11-26 20:46:31.503][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:520 st:179,190,454> [06-11-26 20:46:32.615][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:543 st:179,190,647> [06-11-26 20:46:32.809][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:575 st:179,190,912> [06-11-26 20:46:33.072][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:596 st:179,191,089> [06-11-26 20:46:33.249][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:681 st:179,191,809> [06-11-26 20:46:33.970][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:701 st:179,191,980> [06-11-26 20:46:34.142][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:715 st:179,192,097> [06-11-26 20:46:34.258][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:732 st:179,192,238> [06-11-26 20:46:34.399][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:857 st:179,193,280> [06-11-26 20:46:35.441][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:860 st:179,193,305> [06-11-26 20:46:35.465][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:874 st:179,193,422> [06-11-26 20:46:35.583][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1004 st:179,194,506> [06-11-26 20:46:36.667][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1016 st:179,194,605> [06-11-26 20:46:36.767][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1020 st:179,194,639> [06-11-26 20:46:36.800][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1163 st:179,195,831> [06-11-26 20:46:37.992][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1174 st:179,195,931> [06-11-26 20:46:38.092][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1175 st:179,195,946> [06-11-26 20:46:38.107][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:1237 st:179,196,454> ZEDQA mop PASS god mode on
LOG : General f:1264 st:179,196,689> [06-11-26 20:46:38.851][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1332 st:179,197,256> [06-11-26 20:46:39.417][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1429 st:179,198,072> [06-11-26 20:46:40.234][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1585 st:179,199,465> [06-11-26 20:46:41.626][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1585 st:179,199,470> [06-11-26 20:46:41.631][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1619 st:179,199,757> [06-11-26 20:46:41.918][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1743 st:179,200,790> [06-11-26 20:46:42.952][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1743 st:179,200,796> [06-11-26 20:46:42.958][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:1895 st:179,202,054> ZEDQA mop at 10600,9799: outdoors and free true
LOG : General f:1901 st:179,202,115> [06-11-26 20:46:44.277][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1950 st:179,202,524> [06-11-26 20:46:44.686][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:1979 st:179,202,765> [06-11-26 20:46:44.926][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2060 st:179,203,440> [06-11-26 20:46:45.600][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2109 st:179,203,849> [06-11-26 20:46:46.010][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2138 st:179,204,093> [06-11-26 20:46:46.254][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2259 st:179,205,099> [06-11-26 20:46:47.260][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2268 st:179,205,174> [06-11-26 20:46:47.335][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2303 st:179,205,466> [06-11-26 20:46:47.628][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2418 st:179,206,426> [06-11-26 20:46:48.587][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2426 st:179,206,499> [06-11-26 20:46:48.660][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2491 st:179,207,041> [06-11-26 20:46:49.203][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2500 st:179,207,116> [06-11-26 20:46:49.278][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2576 st:179,207,751> [06-11-26 20:46:49.912][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2583 st:179,207,816> [06-11-26 20:46:49.976][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2648 st:179,208,360> [06-11-26 20:46:50.521][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2733 st:179,209,074> [06-11-26 20:46:51.236][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2742 st:179,209,150> [06-11-26 20:46:51.310][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2779 st:179,209,458> [06-11-26 20:46:51.619][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2783 st:179,209,491> [06-11-26 20:46:51.652][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2892 st:179,210,400> [06-11-26 20:46:52.561][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2906 st:179,210,516> [06-11-26 20:46:52.678][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2937 st:179,210,774> [06-11-26 20:46:52.936][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:2990 st:179,211,217> [06-11-26 20:46:53.378][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3051 st:179,211,724> [06-11-26 20:46:53.885][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3065 st:179,211,841> [06-11-26 20:46:54.003][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3097 st:179,212,108> [06-11-26 20:46:54.270][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3150 st:179,212,549> [06-11-26 20:46:54.710][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3210 st:179,213,050> [06-11-26 20:46:55.210][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3256 st:179,213,436> [06-11-26 20:46:55.596][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3308 st:179,213,874> [06-11-26 20:46:56.034][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3393 st:179,214,583> [06-11-26 20:46:56.743][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3398 st:179,214,624> [06-11-26 20:46:56.785][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3414 st:179,214,757> [06-11-26 20:46:56.919][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3553 st:179,215,916> [06-11-26 20:46:58.076][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3579 st:179,216,132> [06-11-26 20:46:58.294][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3590 st:179,216,225> [06-11-26 20:46:58.385][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3613 st:179,216,416> [06-11-26 20:46:58.576][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3712 st:179,217,241> [06-11-26 20:46:59.402][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3749 st:179,217,549> [06-11-26 20:46:59.710][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3806 st:179,218,025> [06-11-26 20:47:00.186][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3813 st:179,218,082> [06-11-26 20:47:00.243][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3871 st:179,218,566> [06-11-26 20:47:00.727][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3973 st:179,219,416> [06-11-26 20:47:01.578][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:3999 st:179,219,633> [06-11-26 20:47:01.795][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4032 st:179,219,909> [06-11-26 20:47:02.070][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4132 st:179,220,741> [06-11-26 20:47:02.902][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4189 st:179,221,224> [06-11-26 20:47:03.386][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4209 st:179,221,392> [06-11-26 20:47:03.552][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4290 st:179,222,066> [06-11-26 20:47:04.227][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4368 st:179,222,716> [06-11-26 20:47:04.877][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4379 st:179,222,809> [06-11-26 20:47:04.970][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4461 st:179,223,491> [06-11-26 20:47:05.651][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4575 st:179,224,442> [06-11-26 20:47:06.603][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4586 st:179,224,532> [06-11-26 20:47:06.694][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:4616 st:179,224,779> ZEDQA mop PASS open ground
LOG : Lua f:4616 st:179,224,780> ZEDQA mop DONE
LOG : General f:4621 st:179,224,832> [06-11-26 20:47:06.993][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4733 st:179,225,766> [06-11-26 20:47:07.927][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4744 st:179,225,858> [06-11-26 20:47:08.019][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4805 st:179,226,366> [06-11-26 20:47:08.528][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4892 st:179,227,091> [06-11-26 20:47:09.252][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:4903 st:179,227,183> [06-11-26 20:47:09.344][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5046 st:179,228,375> [06-11-26 20:47:10.536][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5051 st:179,228,416> [06-11-26 20:47:10.578][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 22607 at 20:47:11

```text
LOG : Lua f:5148 st:179,229,216> [ZeD.QA] state #3 speed=1 paused=false player=10600,9799 grid=15 inCar=false vehicles=8 missing=get
LOG : Lua f:5148 st:179,229,218> [ZeD.QA] windows reset (R)
LOG : Lua f:5148 st:179,229,218> ZEDQA pnw pinned both windows
LOG : Lua f:5148 st:179,229,219> [ZeD.QA] run #3 ok=true
LOG : Lua f:5168 st:179,229,379> ZEDQA pnw DONE
LOG : General f:5199 st:179,229,650> [06-11-26 20:47:11.811][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5210 st:179,229,741> [06-11-26 20:47:11.903][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5285 st:179,230,366> [06-11-26 20:47:12.527][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5369 st:179,231,066> [06-11-26 20:47:13.227][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5444 st:179,231,691> [06-11-26 20:47:13.852][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5467 st:179,231,883> [06-11-26 20:47:14.043][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5528 st:179,232,392> [06-11-26 20:47:14.553][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5567 st:179,232,717> [06-11-26 20:47:14.878][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
```

### 3. mp_admin_rail.lua (`ZEDQA arl`) - PASS, 30 s

- go 22608 at 20:47:15
- screenshots: zqa_arl_01_loot.png, zqa_arl_02_admin_home.png, zqa_arl_03_queue.png, zqa_arl_04_card.png, zqa_arl_05_card_closed.png, zqa_arl_06_item_over_admin.png, zqa_arl_07_item_closed.png, zqa_arl_12_tab_craft.png, zqa_arl_13_tab_build.png, zqa_arl_14_tab_furniture.png, zqa_arl_15_tab_maps.png, zqa_arl_16_tab_forage.png, zqa_arl_17_tab_animals.png, zqa_arl_19_tab_vehicle.png, zqa_arl_20_char_server.png

```text
LOG : Lua f:5658 st:179,233,472> [ZeD.QA] state #4 speed=1 paused=false player=10600,9799 grid=15 inCar=false vehicles=8 missing=get
LOG : Lua f:5658 st:179,233,474> [ZeD.QA] windows reset (R)
LOG : Lua f:5658 st:179,233,475> [ZeD.QA] run #4 ok=true
LOG : General f:5719 st:179,233,991> [06-11-26 20:47:16.151][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5777 st:179,234,483> [06-11-26 20:47:16.643][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5822 st:179,234,866> [06-11-26 20:47:17.027][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:5850 st:179,235,087> ZEDQA arl loot tab=loot mode=nil win 333x315 footer=17 strip x=306 vis=true zones=9
LOG : General f:5866 st:179,235,392> [06-11-26 20:47:17.552][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5871 st:179,235,606> [06-11-26 20:47:17.767][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5883 st:179,235,904> [06-11-26 20:47:18.065][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5948 st:179,236,458> [06-11-26 20:47:18.619][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5980 st:179,236,732> [06-11-26 20:47:18.893][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:5989 st:179,236,816> [06-11-26 20:47:18.977][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6034 st:179,237,202> ZEDQA arl admin home tab=admin mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:6034 st:179,237,356> [06-11-26 20:47:19.517][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6122 st:179,238,118> [06-11-26 20:47:20.279][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6131 st:179,238,202> [06-11-26 20:47:20.363][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6192 st:179,238,704> ZEDQA arl queue tab=admin mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:6271 st:179,239,525> [06-11-26 20:47:21.687][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6309 st:179,239,843> [06-11-26 20:47:22.005][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6330 st:179,240,016> [06-11-26 20:47:22.177][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6384 st:179,240,474> [06-11-26 20:47:22.634][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6390 st:179,240,512> ZEDQA arl card tab=admin mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:6418 st:179,240,923> [06-11-26 20:47:23.083][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6474 st:179,241,404> [06-11-26 20:47:23.566][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6528 st:179,241,877> [06-11-26 20:47:24.039][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6546 st:179,242,022> ZEDQA arl card closed tab=admin mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:6561 st:179,242,307> [06-11-26 20:47:24.469][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6564 st:179,242,333> ZEDQA arl item card over Admin: Belt
LOG : General f:6641 st:179,242,983> [06-11-26 20:47:25.144][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6674 st:179,243,272> [06-11-26 20:47:25.433][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6715 st:179,243,636> [06-11-26 20:47:25.797][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6739 st:179,243,836> ZEDQA arl item card tab=admin mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:6818 st:179,244,676> [06-11-26 20:47:26.838][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:6866 st:179,245,076> [06-11-26 20:47:27.238][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:6934 st:179,245,638> ZEDQA arl item card closed tab=admin mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : Lua f:6953 st:179,245,945> ZEDQA arl pressed the rail's Loot
LOG : General f:6966 st:179,246,066> [06-11-26 20:47:28.227][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7003 st:179,246,374> [06-11-26 20:47:28.535][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7097 st:179,247,146> ZEDQA arl after the rail press tab=loot mode=nil win 333x315 footer=17 strip x=306 vis=true zones=9
LOG : General f:7125 st:179,247,391> [06-11-26 20:47:29.552][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7133 st:179,247,487> [06-11-26 20:47:29.647][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7211 st:179,248,161> [06-11-26 20:47:30.322][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7275 st:179,248,726> [06-11-26 20:47:30.888][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7278 st:179,248,746> ZEDQA arl tab craft tab=craft mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:7290 st:179,248,999> [06-11-26 20:47:31.161][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7345 st:179,249,482> [06-11-26 20:47:31.643][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7345 st:179,249,489> [06-11-26 20:47:31.650][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7352 st:179,249,549> [06-11-26 20:47:31.711][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7416 st:179,250,092> [06-11-26 20:47:32.254][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7444 st:179,250,324> [06-11-26 20:47:32.485][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7448 st:179,250,346> ZEDQA arl tab build tab=build mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:7493 st:179,250,875> [06-11-26 20:47:33.036][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7540 st:179,251,274> [06-11-26 20:47:33.435][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7566 st:179,251,492> [06-11-26 20:47:33.654][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7591 st:179,251,708> [06-11-26 20:47:33.870][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7621 st:179,251,945> ZEDQA arl tab furniture tab=furniture mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:7644 st:179,252,540> [06-11-26 20:47:34.701][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7693 st:179,253,091> [06-11-26 20:47:35.251][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7729 st:179,253,400> [06-11-26 20:47:35.560][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7747 st:179,253,561> ZEDQA arl tab maps tab=maps mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:7752 st:179,253,757> [06-11-26 20:47:35.918][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7837 st:179,254,477> [06-11-26 20:47:36.638][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7872 st:179,254,774> [06-11-26 20:47:36.935][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:7908 st:179,255,075> [06-11-26 20:47:37.235][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:7920 st:179,255,162> ZEDQA arl tab forage tab=forage mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:7991 st:179,255,916> [06-11-26 20:47:38.078][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8022 st:179,256,174> [06-11-26 20:47:38.335][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8084 st:179,256,699> [06-11-26 20:47:38.861][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:8094 st:179,256,773> ZEDQA arl tab animals tab=animals mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:8140 st:179,257,316> [06-11-26 20:47:39.477][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8141 st:179,257,338> [06-11-26 20:47:39.500][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8166 st:179,257,561> [06-11-26 20:47:39.723][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8295 st:179,258,641> [06-11-26 20:47:40.801][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8296 st:179,258,654> [06-11-26 20:47:40.816][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8331 st:179,258,963> [06-11-26 20:47:41.123][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8450 st:179,259,962> [06-11-26 20:47:42.123][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8451 st:179,259,975> [06-11-26 20:47:42.135][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:8453 st:179,259,991> ZEDQA arl tab vehicle tab=vehicle mode=tab win 640x315 footer=17 strip x=613 vis=true zones=9
LOG : General f:8480 st:179,260,531> [06-11-26 20:47:42.693][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8546 st:179,261,335> [06-11-26 20:47:43.496][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8553 st:179,261,419> [06-11-26 20:47:43.580][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8553 st:179,261,426> [06-11-26 20:47:43.587][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : Lua f:8585 st:179,261,809> ZEDQA arl Character server tab: active=server footer=17
LOG : Lua f:8598 st:179,262,113> ZEDQA arl DONE
LOG : General f:8672 st:179,262,741> [06-11-26 20:47:44.902][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8678 st:179,262,808> [06-11-26 20:47:44.969][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8702 st:179,263,033> [06-11-26 20:47:45.193][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8760 st:179,263,541> [06-11-26 20:47:45.702][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8814 st:179,264,064> [06-11-26 20:47:46.224][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8823 st:179,264,152> [06-11-26 20:47:46.314][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8838 st:179,264,352> [06-11-26 20:47:46.514][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8958 st:179,265,382> [06-11-26 20:47:47.543][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
LOG : General f:8968 st:179,265,479> [06-11-26 20:47:47.640][info] Got message from server: ChatMessage{chat=Admin chat, author='Server', text='Combat: "zedqa" hit "zedqa" "zombie" -1.000000'}.
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
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: %USERPROFILE%\Zomboid\mods\ZeDQAShim\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
