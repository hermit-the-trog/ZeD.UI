# ZeD-UI regression - 2026-11-06 08:03 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-06 08:03:38 |
| Finished | 2026-11-06 08:13:28 (9 min 50 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_adm_cards_large.txt (7 scripts) |
| Result | **7/7 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21766 to 21776 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; at the main menu
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1929,1118 (the bridge had not armed in game after 30 s)
- clicked again at 1929,1118 (the bridge had not armed in game after 61 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21775, 21776)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 2 | zedqa_large_text.lua | ltx | PASS | 1 |  |  |
| 3 | mp_admin_cards.lua | mac | PASS | 98 |  |  |
| 4 | mp_claim_cards.lua | mcc | PASS | 140 |  |  |
| 5 | mp_log_cards.lua | mlc | PASS | 84 |  |  |
| 6 | mp_community_cards.lua | mcm | PASS | 69 |  |  |
| 7 | mp_extras_cards.lua | mxc | PASS | 60 |  |  |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21768 at 08:05:10

```text
LOG : Lua f:249 st:133,508,329> [ZeD.QA] state #2 speed=1 paused=false player=10721,10630 grid=15 inCar=false vehicles=3 missing=get
LOG : Lua f:249 st:133,508,331> [ZeD.QA] windows reset (R)
LOG : Lua f:249 st:133,508,333> ZEDQA pnw pinned both windows
LOG : Lua f:249 st:133,508,334> [ZeD.QA] run #2 ok=true
LOG : Lua f:269 st:133,508,494> ZEDQA pnw DONE
```

### 2. zedqa_large_text.lua (`ZEDQA ltx`) - PASS, 1 s

- go 21769 at 08:05:14

```text
LOG : Lua f:759 st:133,512,612> [ZeD.QA] state #3 speed=1 paused=false player=10721,10630 grid=15 inCar=false vehicles=3 missing=get
LOG : Lua f:759 st:133,512,613> [ZeD.QA] windows reset (R)
LOG : Lua f:759 st:133,512,620> ZEDQA ltx text size now large
LOG : Lua f:759 st:133,512,621> [ZeD.QA] run #3 ok=true
LOG : Lua f:820 st:133,513,124> ZEDQA ltx DONE
```

### 3. mp_admin_cards.lua (`ZEDQA mac`) - PASS, 98 s

- go 21770 at 08:05:18

```text
LOG : Lua f:1269 st:133,516,870> [ZeD.QA] state #4 speed=1 paused=false player=10721,10630 grid=15 inCar=false vehicles=3 missing=get
LOG : Lua f:1269 st:133,516,873> [ZeD.QA] windows reset (R)
LOG : Lua f:1269 st:133,516,874> [ZeD.QA] run #4 ok=true
LOG : Lua f:1413 st:133,518,571> ZEDQA mac home: 59 stops
LOG : Lua f:1597 st:133,520,238> ZEDQA mac home-find: 52 stops
LOG : Lua f:1783 st:133,521,908> ZEDQA mac home-nobody: 51 stops
LOG : Lua f:1966 st:133,523,569> ZEDQA mac home-online: 57 stops
LOG : Lua f:2152 st:133,525,232> ZEDQA mac home-repeat: 59 stops
LOG : Lua f:2337 st:133,526,882> ZEDQA mac home-no-repeats: 58 stops
LOG : Lua f:2520 st:133,528,542> ZEDQA mac home-long: 119 stops
LOG : Lua f:2706 st:133,530,207> ZEDQA mac home-empty: 51 stops
LOG : Lua f:2892 st:133,531,862> ZEDQA mac home-moderator: 51 stops
LOG : Lua f:3079 st:133,533,515> ZEDQA mac home-gm: 59 stops
LOG : Lua f:3262 st:133,535,169> ZEDQA mac home-nothing: 51 stops
LOG : Lua f:3449 st:133,536,827> ZEDQA mac home-no-part: 58 stops
LOG : Lua f:3634 st:133,538,482> ZEDQA mac home-flash: 59 stops
LOG : Lua f:3822 st:133,540,140> ZEDQA mac tickets-screen: 12 stops
LOG : Lua f:4011 st:133,541,808> ZEDQA mac player: 25 stops
LOG : Lua f:4198 st:133,543,457> ZEDQA mac player-self: 13 stops
LOG : Lua f:4387 st:133,545,115> ZEDQA mac player-offline: 13 stops
LOG : Lua f:4574 st:133,546,774> ZEDQA mac player-banned: 10 stops
LOG : Lua f:4761 st:133,548,424> ZEDQA mac player-never-seen: 10 stops
LOG : Lua f:4949 st:133,550,082> ZEDQA mac player-moderator: 25 stops
LOG : Lua f:5136 st:133,551,744> ZEDQA mac player-nothing: 23 stops
LOG : Lua f:5326 st:133,553,410> ZEDQA mac player-no-part: 12 stops
LOG : Lua f:5515 st:133,555,069> ZEDQA mac player-muted: 25 stops
LOG : Lua f:5704 st:133,556,727> ZEDQA mac player-all-skills: 27 stops
LOG : Lua f:5894 st:133,558,390> ZEDQA mac player-kick: 28 stops
LOG : Lua f:6082 st:133,560,053> ZEDQA mac player-ban: 34 stops
LOG : Lua f:6270 st:133,561,716> ZEDQA mac player-ban-perm: 34 stops
LOG : Lua f:6459 st:133,563,382> ZEDQA mac player-warn: 30 stops
LOG : Lua f:6647 st:133,565,041> ZEDQA mac player-warn-max: 30 stops
LOG : Lua f:6835 st:133,566,691> ZEDQA mac player-role-powers: 29 stops
LOG : Lua f:7025 st:133,568,358> ZEDQA mac player-role-kept: 29 stops
LOG : Lua f:7212 st:133,570,015> ZEDQA mac player-role-down: 15 stops
LOG : Lua f:7401 st:133,571,675> ZEDQA mac player-flash: 25 stops
LOG : Lua f:7589 st:133,573,324> ZEDQA mac roles: 10 stops
LOG : Lua f:7776 st:133,574,983> ZEDQA mac roles-nothing: 10 stops
LOG : Lua f:7928 st:133,576,643> ZEDQA mac role-moderator: 120 stops
LOG : Lua f:8076 st:133,578,305> ZEDQA mac role-locked: 120 stops
LOG : Lua f:8254 st:133,579,967> ZEDQA mac role-user: 119 stops
LOG : Lua f:8401 st:133,581,633> ZEDQA mac role-read-only: 120 stops
LOG : Lua f:8543 st:133,583,296> ZEDQA mac role-changed: 120 stops
LOG : Lua f:8695 st:133,584,966> ZEDQA mac role-new: 117 stops
LOG : Lua f:8878 st:133,586,625> ZEDQA mac role-shut: 23 stops
LOG : Lua f:9061 st:133,588,285> ZEDQA mac role-confirm: 119 stops
LOG : Lua f:9247 st:133,589,957> ZEDQA mac bans: 11 stops
LOG : Lua f:9435 st:133,591,609> ZEDQA mac bans-none: 9 stops
LOG : Lua f:9601 st:133,593,278> ZEDQA mac bans-game: 13 stops
LOG : Lua f:9787 st:133,594,934> ZEDQA mac bans-stayed: 12 stops
LOG : Lua f:9975 st:133,596,599> ZEDQA mac bans-confirm: 13 stops
LOG : Lua f:10164 st:133,598,257> ZEDQA mac bans-no-power: 11 stops
LOG : Lua f:10352 st:133,599,907> ZEDQA mac bans-no-part: 11 stops
LOG : Lua f:10540 st:133,601,557> ZEDQA mac spawn: 24 stops
LOG : Lua f:10730 st:133,603,224> ZEDQA mac spawn-find: 3 stops
LOG : Lua f:10919 st:133,604,882> ZEDQA mac spawn-none: 2 stops
LOG : Lua f:11107 st:133,606,545> ZEDQA mac spawn-picked: 39 stops
LOG : Lua f:11296 st:133,608,207> ZEDQA mac spawn-page-2: 8 stops
LOG : Lua f:11484 st:133,609,866> ZEDQA mac spawn-to-player: 39 stops
LOG : Lua f:11670 st:133,611,533> ZEDQA mac spawn-no-part: 39 stops
LOG : Lua f:11855 st:133,613,186> ZEDQA mac spawn-max: 39 stops
LOG : Lua f:11905 st:133,613,694> ZEDQA mac DONE
```

### 4. mp_claim_cards.lua (`ZEDQA mcc`) - PASS, 140 s

- go 21771 at 08:06:59

```text
LOG : Lua f:12369 st:133,617,711> [ZeD.QA] state #5 speed=1 paused=false player=10721,10630 grid=15 inCar=false vehicles=3 missing=get
LOG : Lua f:12369 st:133,617,716> [ZeD.QA] windows reset (R)
LOG : Lua f:12369 st:133,617,717> [ZeD.QA] run #5 ok=true
LOG : Lua f:12549 st:133,619,483> ZEDQA mcc tab-owner: 6 stops
LOG : Lua f:12735 st:133,621,257> ZEDQA mcc tab-member: 6 stops
LOG : Lua f:12919 st:133,623,018> ZEDQA mcc tab-none: 14 stops
LOG : Lua f:13098 st:133,624,788> ZEDQA mcc tab-reasons: 14 stops
LOG : Lua f:13284 st:133,626,556> ZEDQA mcc tab-outdoors: 14 stops
LOG : Lua f:13471 st:133,628,321> ZEDQA mcc tab-taken: 14 stops
LOG : Lua f:13659 st:133,630,092> ZEDQA mcc tab-off: 14 stops
LOG : Lua f:13840 st:133,631,861> ZEDQA mcc tab-adminonly: 14 stops
LOG : Lua f:14027 st:133,633,627> ZEDQA mcc tab-faction-early: 14 stops
LOG : Lua f:14222 st:133,635,382> ZEDQA mcc tab-faction-off: 14 stops
LOG : Lua f:14396 st:133,637,144> ZEDQA mcc tab-note-faction: 16 stops
LOG : Lua f:14589 st:133,638,901> ZEDQA mcc tab-note-safe: 16 stops
LOG : Lua f:14778 st:133,640,669> ZEDQA mcc tab-note-two: 18 stops
LOG : Lua f:14966 st:133,642,432> ZEDQA mcc tab-keep-low: 6 stops
LOG : Lua f:15162 st:133,644,193> ZEDQA mcc tab-wars: 6 stops
LOG : Lua f:15356 st:133,645,960> ZEDQA mcc tab-wars-off: 5 stops
LOG : Lua f:15546 st:133,647,723> ZEDQA mcc tab-flash: 6 stops
LOG : Lua f:15738 st:133,649,477> ZEDQA mcc safe-owner: 16 stops
LOG : Lua f:15933 st:133,651,252> ZEDQA mcc safe-owner-keep: 16 stops
LOG : Lua f:16128 st:133,653,015> ZEDQA mcc safe-owner-keep-low: 16 stops
LOG : Lua f:16316 st:133,654,773> ZEDQA mcc safe-owner-keep-soon: 16 stops
LOG : Lua f:16511 st:133,656,545> ZEDQA mcc safe-member: 14 stops
LOG : Lua f:16705 st:133,658,312> ZEDQA mcc safe-respawn-off: 16 stops
LOG : Lua f:16892 st:133,660,079> ZEDQA mcc safe-respawn-unset: 16 stops
LOG : Lua f:17081 st:133,661,851> ZEDQA mcc safe-rules-loose: 16 stops
LOG : Lua f:17276 st:133,663,607> ZEDQA mcc safe-row: 18 stops
LOG : Lua f:17468 st:133,665,358> ZEDQA mcc safe-row-offline: 18 stops
LOG : Lua f:17652 st:133,667,133> ZEDQA mcc safe-pending: 17 stops
LOG : Lua f:17843 st:133,668,899> ZEDQA mcc safe-pending-nopart: 17 stops
LOG : Lua f:18033 st:133,670,655> ZEDQA mcc safe-drawer: 19 stops
LOG : Lua f:18232 st:133,672,418> ZEDQA mcc safe-drawer-empty: 16 stops
LOG : Lua f:18423 st:133,674,182> ZEDQA mcc safe-drawer-wait: 16 stops
LOG : Lua f:18620 st:133,675,942> ZEDQA mcc safe-edit: 17 stops
LOG : Lua f:18814 st:133,677,702> ZEDQA mcc safe-edit-empty: 17 stops
LOG : Lua f:19009 st:133,679,477> ZEDQA mcc safe-edit-long: 17 stops
LOG : Lua f:19200 st:133,681,257> ZEDQA mcc safe-confirm-release: 17 stops
LOG : Lua f:19398 st:133,683,029> ZEDQA mcc safe-confirm-quit: 15 stops
LOG : Lua f:19590 st:133,684,796> ZEDQA mcc safe-confirm-remove: 19 stops
LOG : Lua f:19788 st:133,686,552> ZEDQA mcc safe-confirm-owner: 19 stops
LOG : Lua f:19968 st:133,688,315> ZEDQA mcc safe-flash: 16 stops
LOG : Lua f:20150 st:133,690,074> ZEDQA mcc safe-many: 44 stops
LOG : Lua f:20338 st:133,691,828> ZEDQA mcc safe-long-words: 13 stops
LOG : Lua f:20526 st:133,693,590> ZEDQA mcc fac-owner: 18 stops
LOG : Lua f:20721 st:133,695,359> ZEDQA mcc fac-member: 7 stops
LOG : Lua f:20914 st:133,697,128> ZEDQA mcc fac-few: 7 stops
LOG : Lua f:21110 st:133,698,885> ZEDQA mcc fac-member-few: 6 stops
LOG : Lua f:21296 st:133,700,644> ZEDQA mcc fac-notag: 18 stops
LOG : Lua f:21486 st:133,702,404> ZEDQA mcc fac-tag-hidden: 18 stops
LOG : Lua f:21675 st:133,704,167> ZEDQA mcc fac-pvp: 18 stops
LOG : Lua f:21875 st:133,705,923> ZEDQA mcc fac-row: 20 stops
LOG : Lua f:22056 st:133,707,690> ZEDQA mcc fac-pending: 19 stops
LOG : Lua f:22242 st:133,709,457> ZEDQA mcc fac-drawer: 21 stops
LOG : Lua f:22431 st:133,711,212> ZEDQA mcc fac-edit-name: 19 stops
LOG : Lua f:22622 st:133,712,977> ZEDQA mcc fac-edit-short: 19 stops
LOG : Lua f:22817 st:133,714,732> ZEDQA mcc fac-edit-long: 19 stops
LOG : Lua f:23011 st:133,716,493> ZEDQA mcc fac-edit-taken: 19 stops
LOG : Lua f:23203 st:133,718,262> ZEDQA mcc fac-edit-tag: 19 stops
LOG : Lua f:23391 st:133,720,024> ZEDQA mcc fac-edit-tag-taken: 19 stops
LOG : Lua f:23531 st:133,721,804> ZEDQA mcc fac-edit-tag-long: 19 stops
LOG : Lua f:23729 st:133,723,560> ZEDQA mcc fac-confirm-disband: 19 stops
LOG : Lua f:23927 st:133,725,326> ZEDQA mcc fac-confirm-leave: 8 stops
LOG : Lua f:24129 st:133,727,094> ZEDQA mcc fac-confirm-remove: 21 stops
LOG : Lua f:24326 st:133,728,856> ZEDQA mcc fac-confirm-owner: 21 stops
LOG : Lua f:24525 st:133,730,615> ZEDQA mcc new-empty: 7 stops
LOG : Lua f:24724 st:133,732,385> ZEDQA mcc new-short: 7 stops
LOG : Lua f:24924 st:133,734,153> ZEDQA mcc new-typed: 7 stops
LOG : Lua f:25125 st:133,735,930> ZEDQA mcc new-taken: 7 stops
LOG : Lua f:25328 st:133,737,707> ZEDQA mcc new-nodays: 6 stops
LOG : Lua f:25526 st:133,739,460> ZEDQA mcc wars-none: 4 stops
LOG : Lua f:25725 st:133,741,229> ZEDQA mcc wars-off: 2 stops
LOG : Lua f:25922 st:133,742,990> ZEDQA mcc wars-defender: 6 stops
LOG : Lua f:26118 st:133,744,743> ZEDQA mcc wars-attacker: 5 stops
LOG : Lua f:26318 st:133,746,503> ZEDQA mcc wars-accepted: 4 stops
LOG : Lua f:26518 st:133,748,268> ZEDQA mcc wars-started: 4 stops
LOG : Lua f:26719 st:133,750,040> ZEDQA mcc wars-refused: 4 stops
LOG : Lua f:26917 st:133,751,800> ZEDQA mcc wars-admin: 5 stops
LOG : Lua f:27119 st:133,753,567> ZEDQA mcc wars-confirm-accept: 8 stops
LOG : Lua f:27319 st:133,755,332> ZEDQA mcc wars-confirm-end: 7 stops
LOG : Lua f:27517 st:133,757,087> ZEDQA mcc wars-several: 10 stops
LOG : Lua f:27567 st:133,757,587> ZEDQA mcc DONE
```

### 5. mp_log_cards.lua (`ZEDQA mlc`) - PASS, 84 s

- go 21772 at 08:09:23

```text
LOG : Lua f:28029 st:133,761,452> [ZeD.QA] state #6 speed=1 paused=false player=10721,10630 grid=15 inCar=false vehicles=3 missing=get
LOG : Lua f:28029 st:133,761,459> [ZeD.QA] windows reset (R)
LOG : Lua f:28029 st:133,761,460> [ZeD.QA] run #6 ok=true
LOG : Lua f:28237 st:133,763,237> ZEDQA mlc home-row: 44 stops
LOG : Lua f:28426 st:133,765,008> ZEDQA mlc home-no-part: 44 stops
LOG : Lua f:28608 st:133,766,775> ZEDQA mlc home-no-part-no-power: 44 stops
LOG : Lua f:28792 st:133,768,537> ZEDQA mlc home-no-power: 44 stops
LOG : Lua f:28982 st:133,770,304> ZEDQA mlc log: 28 stops
LOG : Lua f:29178 st:133,772,066> ZEDQA mlc log-waiting: 14 stops
LOG : Lua f:29377 st:133,773,846> ZEDQA mlc log-kind-admin: 18 stops
LOG : Lua f:29575 st:133,775,609> ZEDQA mlc log-kind-safehouse: 16 stops
LOG : Lua f:29768 st:133,777,365> ZEDQA mlc log-kind-faction: 15 stops
LOG : Lua f:29961 st:133,779,130> ZEDQA mlc log-kind-vehicle: 17 stops
LOG : Lua f:30158 st:133,780,884> ZEDQA mlc log-kind-pvp: 15 stops
LOG : Lua f:30355 st:133,782,653> ZEDQA mlc log-kind-ticket: 17 stops
LOG : Lua f:30552 st:133,784,428> ZEDQA mlc log-who: 28 stops
LOG : Lua f:30750 st:133,786,191> ZEDQA mlc log-who-long: 28 stops
LOG : Lua f:30931 st:133,787,948> ZEDQA mlc log-hour: 28 stops
LOG : Lua f:31112 st:133,789,730> ZEDQA mlc log-3days: 28 stops
LOG : Lua f:31306 st:133,791,499> ZEDQA mlc log-find: 28 stops
LOG : Lua f:31502 st:133,793,268> ZEDQA mlc log-nothing: 14 stops
LOG : Lua f:31703 st:133,795,024> ZEDQA mlc log-one-line: 15 stops
LOG : Lua f:31900 st:133,796,785> ZEDQA mlc log-container-on: 30 stops
LOG : Lua f:32065 st:133,798,548> ZEDQA mlc log-who-pick: 7 stops
LOG : Lua f:32258 st:133,800,315> ZEDQA mlc log-flash: 28 stops
LOG : Lua f:32455 st:133,802,077> ZEDQA mlc log-pages: 41 stops
LOG : Lua f:32643 st:133,803,841> ZEDQA mlc log-first-page: 30 stops
LOG : Lua f:32839 st:133,805,611> ZEDQA mlc log-long-words: 19 stops
LOG : Lua f:33033 st:133,807,379> ZEDQA mlc line-vehicle: 31 stops
LOG : Lua f:33213 st:133,809,161> ZEDQA mlc line-pvp: 31 stops
LOG : Lua f:33413 st:133,810,932> ZEDQA mlc line-ticket: 30 stops
LOG : Lua f:33603 st:133,812,693> ZEDQA mlc line-no-place: 30 stops
LOG : Lua f:33798 st:133,814,460> ZEDQA mlc line-server: 17 stops
LOG : Lua f:34000 st:133,816,234> ZEDQA mlc line-hidden-place: 17 stops
LOG : Lua f:34192 st:133,817,999> ZEDQA mlc line-tap: 16 stops
LOG : Lua f:34377 st:133,819,757> ZEDQA mlc line-no-teleport: 31 stops
LOG : Lua f:34565 st:133,821,519> ZEDQA mlc line-no-stats: 31 stops
LOG : Lua f:34761 st:133,823,282> ZEDQA mlc around: 17 stops
LOG : Lua f:34952 st:133,825,051> ZEDQA mlc around-nobody-missed: 17 stops
LOG : Lua f:35150 st:133,826,817> ZEDQA mlc around-three-missed: 17 stops
LOG : Lua f:35349 st:133,828,582> ZEDQA mlc around-waiting: 12 stops
LOG : Lua f:35540 st:133,830,351> ZEDQA mlc around-nothing: 12 stops
LOG : Lua f:35735 st:133,832,123> ZEDQA mlc around-line: 21 stops
LOG : Lua f:35930 st:133,833,890> ZEDQA mlc around-added: 21 stops
LOG : Lua f:36124 st:133,835,659> ZEDQA mlc around-cleared: 19 stops
LOG : Lua f:36319 st:133,837,428> ZEDQA mlc around-busy: 21 stops
LOG : Lua f:36514 st:133,839,190> ZEDQA mlc ticket-around: 13 stops
LOG : Lua f:36711 st:133,840,946> ZEDQA mlc ticket-no-place: 12 stops
LOG : Lua f:36897 st:133,842,711> ZEDQA mlc ticket-no-log: 13 stops
LOG : Lua f:37094 st:133,844,479> ZEDQA mlc queue-silent: 12 stops
LOG : Lua f:37143 st:133,844,982> ZEDQA mlc DONE
```

### 6. mp_community_cards.lua (`ZEDQA mcm`) - PASS, 69 s

- go 21773 at 08:10:51

```text
LOG : Lua f:37629 st:133,849,134> [ZeD.QA] state #7 speed=1 paused=false player=10721,10630 grid=15 inCar=false vehicles=3 missing=get
LOG : Lua f:37629 st:133,849,139> [ZeD.QA] windows reset (R)
LOG : Lua f:37629 st:133,849,139> [ZeD.QA] run #7 ok=true
LOG : Lua f:37833 st:133,851,000> ZEDQA mcm tab
LOG : Lua f:38021 st:133,852,760> ZEDQA mcm tab-no-news
LOG : Lua f:38203 st:133,854,508> ZEDQA mcm tab-no-motd
LOG : Lua f:38394 st:133,856,270> ZEDQA mcm tab-no-rules
LOG : Lua f:38593 st:133,858,023> ZEDQA mcm tab-empty
LOG : Lua f:38748 st:133,859,798> ZEDQA mcm tab-many-posts
LOG : Lua f:38889 st:133,861,588> ZEDQA mcm tab-long-motd
LOG : Lua f:39066 st:133,863,341> ZEDQA mcm tab-no-part
LOG : Lua f:39250 st:133,865,105> ZEDQA mcm rules
LOG : Lua f:39448 st:133,866,873> ZEDQA mcm rules-no-appeal
LOG : Lua f:39647 st:133,868,614> ZEDQA mcm rules-no-motd
LOG : Lua f:39847 st:133,870,392> ZEDQA mcm rules-many
LOG : Lua f:40039 st:133,872,154> ZEDQA mcm join-first
LOG : Lua f:40230 st:133,873,927> ZEDQA mcm join-new
LOG : Lua f:40427 st:133,875,703> ZEDQA mcm join-new-many
LOG : Lua f:40628 st:133,877,467> ZEDQA mcm join-no-appeal
LOG : Lua f:40827 st:133,879,243> ZEDQA mcm join-no-motd
LOG : Lua f:41024 st:133,881,009> ZEDQA mcm join-long
LOG : Lua f:41221 st:133,882,759> ZEDQA mcm ask-report
LOG : Lua f:41411 st:133,884,542> ZEDQA mcm ask-report-no-part
LOG : Lua f:41574 st:133,886,309> ZEDQA mcm admin-row
LOG : Lua f:41758 st:133,888,091> ZEDQA mcm admin-row-no-part
LOG : Lua f:41943 st:133,889,856> ZEDQA mcm admin-row-gray
LOG : Lua f:42058 st:133,891,636> ZEDQA mcm edit
LOG : Lua f:42137 st:133,893,439> ZEDQA mcm edit-dirty
LOG : Lua f:42214 st:133,895,249> ZEDQA mcm edit-empty-rule
LOG : Lua f:42283 st:133,897,035> ZEDQA mcm edit-long-rule
LOG : Lua f:42354 st:133,898,832> ZEDQA mcm edit-stale
LOG : Lua f:42418 st:133,900,634> ZEDQA mcm edit-ask-off
LOG : Lua f:42553 st:133,902,424> ZEDQA mcm edit-no-rules
LOG : Lua f:42634 st:133,904,253> ZEDQA mcm edit-rules-full
LOG : Lua f:42694 st:133,906,212> ZEDQA mcm edit-no-news
LOG : Lua f:42751 st:133,908,074> ZEDQA mcm edit-many-posts
LOG : Lua f:42807 st:133,909,887> ZEDQA mcm edit-post-typed
LOG : Lua f:42900 st:133,911,688> ZEDQA mcm edit-confirm-delete
LOG : Lua f:43078 st:133,913,459> ZEDQA mcm edit-moderator
LOG : Lua f:43199 st:133,915,252> ZEDQA mcm edit-rules-only
LOG : Lua f:43305 st:133,917,045> ZEDQA mcm edit-frozen
LOG : Lua f:43337 st:133,917,472> ZEDQA mcm DONE
```

### 7. mp_extras_cards.lua (`ZEDQA mxc`) - PASS, 60 s

- go 21774 at 08:12:03

```text
LOG : Lua f:43689 st:133,921,713> [ZeD.QA] state #8 speed=1 paused=false player=10721,10630 grid=15 inCar=false vehicles=3 missing=get
LOG : Lua f:43689 st:133,921,718> [ZeD.QA] windows reset (R)
LOG : Lua f:43689 st:133,921,719> [ZeD.QA] run #8 ok=true
LOG : Lua f:43844 st:133,923,386> ZEDQA mxc admin-home
LOG : Lua f:43995 st:133,925,052> ZEDQA mxc admin-home-some-on
LOG : Lua f:44152 st:133,926,707> ZEDQA mxc admin-home-no-part
LOG : Lua f:44329 st:133,928,381> ZEDQA mxc extras-all-off
LOG : Lua f:44503 st:133,930,040> ZEDQA mxc extras-claims
LOG : Lua f:44673 st:133,931,705> ZEDQA mxc extras-claims-tow-1-30
LOG : Lua f:44839 st:133,933,368> ZEDQA mxc extras-claims-5-1
LOG : Lua f:45008 st:133,935,055> ZEDQA mxc extras-protection
LOG : Lua f:45187 st:133,936,709> ZEDQA mxc extras-protection-no-lot
LOG : Lua f:45371 st:133,938,370> ZEDQA mxc extras-teleport
LOG : Lua f:45550 st:133,940,032> ZEDQA mxc extras-teleport-no-role
LOG : Lua f:45734 st:133,941,684> ZEDQA mxc extras-log
LOG : Lua f:45916 st:133,943,340> ZEDQA mxc extras-all-on
LOG : Lua f:46090 st:133,945,007> ZEDQA mxc extras-not-saved
LOG : Lua f:46274 st:133,946,676> ZEDQA mxc extras-all-on-not-saved
LOG : Lua f:46439 st:133,948,334> ZEDQA mxc extras-saving
LOG : Lua f:46616 st:133,949,996> ZEDQA mxc extras-no-power
LOG : Lua f:46796 st:133,951,652> ZEDQA mxc extras-no-power-off
LOG : Lua f:46982 st:133,953,324> ZEDQA mxc extras-frozen
LOG : Lua f:47163 st:133,954,984> ZEDQA mxc extras-link-lost
LOG : Lua f:47327 st:133,956,637> ZEDQA mxc tab-all-off
LOG : Lua f:47512 st:133,958,293> ZEDQA mxc tab-claims
LOG : Lua f:47668 st:133,959,959> ZEDQA mxc tab-claims-all-ticks
LOG : Lua f:47727 st:133,961,684> ZEDQA mxc tab-claims-no-ticks
LOG : Lua f:47767 st:133,963,422> ZEDQA mxc tab-protection-lot
LOG : Lua f:47815 st:133,965,116> ZEDQA mxc tab-protection-walls
LOG : Lua f:47861 st:133,966,845> ZEDQA mxc tab-protection-dismantle
LOG : Lua f:47904 st:133,968,510> ZEDQA mxc tab-log
LOG : Lua f:47951 st:133,970,205> ZEDQA mxc tab-all-on
LOG : Lua f:48000 st:133,971,916> ZEDQA mxc tab-no-part
LOG : Lua f:48049 st:133,973,624> ZEDQA mxc claims-wait
LOG : Lua f:48096 st:133,975,331> ZEDQA mxc claims-none
LOG : Lua f:48144 st:133,977,038> ZEDQA mxc claims-two
LOG : Lua f:48192 st:133,978,749> ZEDQA mxc claims-unknown-car
LOG : Lua f:48241 st:133,980,431> ZEDQA mxc claims-release-ask
LOG : Lua f:48278 st:133,980,935> ZEDQA mxc DONE
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
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\common\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\common\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\42\media\AnimSets at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0> AdvancedAnimator$1.visitFileFailed> Exception thrown  :: java.nio.file.NoSuchFileException: C:\Users\danie\Zomboid\mods\ZeDQAShim\42\media\actiongroups at WindowsException.translateToIOException(null:-1).
    1x ERROR: General f:N st:0 at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N st:0 at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N st:0 at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
```
