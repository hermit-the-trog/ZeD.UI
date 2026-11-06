# ZeD-UI regression - 2026-11-06 08:14 - windowed (1280x720 window)

| | |
|---|---|
| Started | 2026-11-06 08:14:15 |
| Finished | 2026-11-06 08:24:03 (9 min 48 s) |
| Mode | windowed (1280x720 window) |
| Display | fullScreen=false height=720 width=1280 |
| Game build | 42.22.1 71e8410c42 attached (version.txt) |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mp_adm_cards_large.txt (7 scripts) |
| Result | **7/7 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 21777 to 21787 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x720 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; at the main menu
- multiplayer: at the main menu, joining 127.0.0.1:16261 as the test server's admin
- clicked again at 1929,1118 (the bridge had not armed in game after 30 s)
- clicked again at 1929,1118 (the bridge had not armed in game after 61 s)
- the bridge armed in game on the multiplayer server ()
- quit: quit to the main menu, then to the desktop (go 21786, 21787)
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
| 7 | mp_extras_cards.lua | mxc | PASS | 59 |  |  |

## Scripts

### 1. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 21779 at 08:15:48

```text
LOG : Lua f:287 st:134,146,759> [ZeD.QA] state #2 speed=1 paused=false player=10721,10630 grid=13 inCar=false vehicles=3 missing=get
LOG : Lua f:287 st:134,146,760> [ZeD.QA] windows reset (R)
LOG : Lua f:287 st:134,146,761> ZEDQA pnw pinned both windows
LOG : Lua f:287 st:134,146,762> [ZeD.QA] run #2 ok=true
LOG : Lua f:307 st:134,146,920> ZEDQA pnw DONE
```

### 2. zedqa_large_text.lua (`ZEDQA ltx`) - PASS, 1 s

- go 21780 at 08:15:53

```text
LOG : Lua f:797 st:134,151,008> [ZeD.QA] state #3 speed=1 paused=false player=10721,10630 grid=13 inCar=false vehicles=3 missing=get
LOG : Lua f:797 st:134,151,009> [ZeD.QA] windows reset (R)
LOG : Lua f:797 st:134,151,014> ZEDQA ltx text size now large
LOG : Lua f:797 st:134,151,015> [ZeD.QA] run #3 ok=true
LOG : Lua f:858 st:134,151,511> ZEDQA ltx DONE
```

### 3. mp_admin_cards.lua (`ZEDQA mac`) - PASS, 98 s

- go 21781 at 08:15:57

```text
LOG : Lua f:1307 st:134,155,257> [ZeD.QA] state #4 speed=1 paused=false player=10721,10630 grid=13 inCar=false vehicles=3 missing=get
LOG : Lua f:1307 st:134,155,262> [ZeD.QA] windows reset (R)
LOG : Lua f:1307 st:134,155,264> [ZeD.QA] run #4 ok=true
LOG : Lua f:1462 st:134,156,922> ZEDQA mac home: 59 stops
LOG : Lua f:1634 st:134,158,589> ZEDQA mac home-find: 52 stops
LOG : Lua f:1822 st:134,160,262> ZEDQA mac home-nobody: 51 stops
LOG : Lua f:2010 st:134,161,921> ZEDQA mac home-online: 57 stops
LOG : Lua f:2198 st:134,163,592> ZEDQA mac home-repeat: 59 stops
LOG : Lua f:2380 st:134,165,253> ZEDQA mac home-no-repeats: 58 stops
LOG : Lua f:2560 st:134,166,908> ZEDQA mac home-long: 119 stops
LOG : Lua f:2748 st:134,168,569> ZEDQA mac home-empty: 51 stops
LOG : Lua f:2933 st:134,170,224> ZEDQA mac home-moderator: 51 stops
LOG : Lua f:3116 st:134,171,879> ZEDQA mac home-gm: 59 stops
LOG : Lua f:3300 st:134,173,538> ZEDQA mac home-nothing: 51 stops
LOG : Lua f:3479 st:134,175,199> ZEDQA mac home-no-part: 58 stops
LOG : Lua f:3666 st:134,176,859> ZEDQA mac home-flash: 59 stops
LOG : Lua f:3851 st:134,178,512> ZEDQA mac tickets-screen: 12 stops
LOG : Lua f:4039 st:134,180,173> ZEDQA mac player: 25 stops
LOG : Lua f:4207 st:134,181,836> ZEDQA mac player-self: 13 stops
LOG : Lua f:4390 st:134,183,494> ZEDQA mac player-offline: 13 stops
LOG : Lua f:4576 st:134,185,156> ZEDQA mac player-banned: 10 stops
LOG : Lua f:4765 st:134,186,819> ZEDQA mac player-never-seen: 10 stops
LOG : Lua f:4953 st:134,188,478> ZEDQA mac player-moderator: 25 stops
LOG : Lua f:5141 st:134,190,138> ZEDQA mac player-nothing: 23 stops
LOG : Lua f:5329 st:134,191,794> ZEDQA mac player-no-part: 12 stops
LOG : Lua f:5517 st:134,193,448> ZEDQA mac player-muted: 25 stops
LOG : Lua f:5704 st:134,195,105> ZEDQA mac player-all-skills: 27 stops
LOG : Lua f:5891 st:134,196,765> ZEDQA mac player-kick: 28 stops
LOG : Lua f:6075 st:134,198,420> ZEDQA mac player-ban: 34 stops
LOG : Lua f:6262 st:134,200,078> ZEDQA mac player-ban-perm: 34 stops
LOG : Lua f:6448 st:134,201,736> ZEDQA mac player-warn: 30 stops
LOG : Lua f:6637 st:134,203,406> ZEDQA mac player-warn-max: 30 stops
LOG : Lua f:6828 st:134,205,078> ZEDQA mac player-role-powers: 29 stops
LOG : Lua f:7016 st:134,206,728> ZEDQA mac player-role-kept: 29 stops
LOG : Lua f:7207 st:134,208,394> ZEDQA mac player-role-down: 15 stops
LOG : Lua f:7397 st:134,210,053> ZEDQA mac player-flash: 25 stops
LOG : Lua f:7585 st:134,211,711> ZEDQA mac roles: 10 stops
LOG : Lua f:7774 st:134,213,369> ZEDQA mac roles-nothing: 10 stops
LOG : Lua f:7913 st:134,215,034> ZEDQA mac role-moderator: 120 stops
LOG : Lua f:8048 st:134,216,689> ZEDQA mac role-locked: 120 stops
LOG : Lua f:8233 st:134,218,348> ZEDQA mac role-user: 119 stops
LOG : Lua f:8365 st:134,220,016> ZEDQA mac role-read-only: 120 stops
LOG : Lua f:8466 st:134,221,685> ZEDQA mac role-changed: 120 stops
LOG : Lua f:8598 st:134,223,346> ZEDQA mac role-new: 117 stops
LOG : Lua f:8762 st:134,225,007> ZEDQA mac role-shut: 23 stops
LOG : Lua f:8948 st:134,226,681> ZEDQA mac role-confirm: 119 stops
LOG : Lua f:9130 st:134,228,336> ZEDQA mac bans: 11 stops
LOG : Lua f:9320 st:134,229,994> ZEDQA mac bans-none: 9 stops
LOG : Lua f:9508 st:134,231,649> ZEDQA mac bans-game: 13 stops
LOG : Lua f:9696 st:134,233,307> ZEDQA mac bans-stayed: 12 stops
LOG : Lua f:9885 st:134,234,961> ZEDQA mac bans-confirm: 13 stops
LOG : Lua f:10075 st:134,236,619> ZEDQA mac bans-no-power: 11 stops
LOG : Lua f:10263 st:134,238,274> ZEDQA mac bans-no-part: 11 stops
LOG : Lua f:10452 st:134,239,936> ZEDQA mac spawn: 24 stops
LOG : Lua f:10640 st:134,241,586> ZEDQA mac spawn-find: 3 stops
LOG : Lua f:10831 st:134,243,244> ZEDQA mac spawn-none: 2 stops
LOG : Lua f:11021 st:134,244,915> ZEDQA mac spawn-picked: 39 stops
LOG : Lua f:11211 st:134,246,586> ZEDQA mac spawn-page-2: 8 stops
LOG : Lua f:11398 st:134,248,254> ZEDQA mac spawn-to-player: 39 stops
LOG : Lua f:11575 st:134,249,906> ZEDQA mac spawn-no-part: 39 stops
LOG : Lua f:11759 st:134,251,562> ZEDQA mac spawn-max: 39 stops
LOG : Lua f:11802 st:134,252,061> ZEDQA mac DONE
```

### 4. mp_claim_cards.lua (`ZEDQA mcc`) - PASS, 140 s

- go 21782 at 08:17:38

```text
LOG : Lua f:12317 st:134,256,504> [ZeD.QA] state #5 speed=1 paused=false player=10721,10630 grid=13 inCar=false vehicles=3 missing=get
LOG : Lua f:12317 st:134,256,509> [ZeD.QA] windows reset (R)
LOG : Lua f:12317 st:134,256,510> [ZeD.QA] run #5 ok=true
LOG : Lua f:12483 st:134,258,275> ZEDQA mcc tab-owner: 6 stops
LOG : Lua f:12681 st:134,260,042> ZEDQA mcc tab-member: 6 stops
LOG : Lua f:12879 st:134,261,807> ZEDQA mcc tab-none: 14 stops
LOG : Lua f:13076 st:134,263,564> ZEDQA mcc tab-reasons: 14 stops
LOG : Lua f:13274 st:134,265,320> ZEDQA mcc tab-outdoors: 14 stops
LOG : Lua f:13470 st:134,267,094> ZEDQA mcc tab-taken: 14 stops
LOG : Lua f:13668 st:134,268,863> ZEDQA mcc tab-off: 14 stops
LOG : Lua f:13871 st:134,270,639> ZEDQA mcc tab-adminonly: 14 stops
LOG : Lua f:14071 st:134,272,398> ZEDQA mcc tab-faction-early: 14 stops
LOG : Lua f:14265 st:134,274,156> ZEDQA mcc tab-faction-off: 14 stops
LOG : Lua f:14463 st:134,275,917> ZEDQA mcc tab-note-faction: 16 stops
LOG : Lua f:14659 st:134,277,688> ZEDQA mcc tab-note-safe: 16 stops
LOG : Lua f:14858 st:134,279,444> ZEDQA mcc tab-note-two: 18 stops
LOG : Lua f:15058 st:134,281,214> ZEDQA mcc tab-keep-low: 6 stops
LOG : Lua f:15242 st:134,282,995> ZEDQA mcc tab-wars: 6 stops
LOG : Lua f:15422 st:134,284,750> ZEDQA mcc tab-wars-off: 5 stops
LOG : Lua f:15622 st:134,286,515> ZEDQA mcc tab-flash: 6 stops
LOG : Lua f:15823 st:134,288,281> ZEDQA mcc safe-owner: 16 stops
LOG : Lua f:16024 st:134,290,048> ZEDQA mcc safe-owner-keep: 16 stops
LOG : Lua f:16219 st:134,291,814> ZEDQA mcc safe-owner-keep-low: 16 stops
LOG : Lua f:16416 st:134,293,586> ZEDQA mcc safe-owner-keep-soon: 16 stops
LOG : Lua f:16616 st:134,295,344> ZEDQA mcc safe-member: 14 stops
LOG : Lua f:16815 st:134,297,098> ZEDQA mcc safe-respawn-off: 16 stops
LOG : Lua f:17015 st:134,298,865> ZEDQA mcc safe-respawn-unset: 16 stops
LOG : Lua f:17205 st:134,300,619> ZEDQA mcc safe-rules-loose: 16 stops
LOG : Lua f:17378 st:134,302,390> ZEDQA mcc safe-row: 18 stops
LOG : Lua f:17563 st:134,304,160> ZEDQA mcc safe-row-offline: 18 stops
LOG : Lua f:17748 st:134,305,934> ZEDQA mcc safe-pending: 17 stops
LOG : Lua f:17944 st:134,307,686> ZEDQA mcc safe-pending-nopart: 17 stops
LOG : Lua f:18142 st:134,309,455> ZEDQA mcc safe-drawer: 19 stops
LOG : Lua f:18325 st:134,311,212> ZEDQA mcc safe-drawer-empty: 16 stops
LOG : Lua f:18521 st:134,312,964> ZEDQA mcc safe-drawer-wait: 16 stops
LOG : Lua f:18720 st:134,314,720> ZEDQA mcc safe-edit: 17 stops
LOG : Lua f:18899 st:134,316,483> ZEDQA mcc safe-edit-empty: 17 stops
LOG : Lua f:19095 st:134,318,259> ZEDQA mcc safe-edit-long: 17 stops
LOG : Lua f:19286 st:134,320,020> ZEDQA mcc safe-confirm-release: 17 stops
LOG : Lua f:19480 st:134,321,775> ZEDQA mcc safe-confirm-quit: 15 stops
LOG : Lua f:19650 st:134,323,542> ZEDQA mcc safe-confirm-remove: 19 stops
LOG : Lua f:19850 st:134,325,311> ZEDQA mcc safe-confirm-owner: 19 stops
LOG : Lua f:20047 st:134,327,086> ZEDQA mcc safe-flash: 16 stops
LOG : Lua f:20244 st:134,328,843> ZEDQA mcc safe-many: 44 stops
LOG : Lua f:20445 st:134,330,611> ZEDQA mcc safe-long-words: 13 stops
LOG : Lua f:20635 st:134,332,384> ZEDQA mcc fac-owner: 18 stops
LOG : Lua f:20831 st:134,334,147> ZEDQA mcc fac-member: 7 stops
LOG : Lua f:21034 st:134,335,920> ZEDQA mcc fac-few: 7 stops
LOG : Lua f:21232 st:134,337,674> ZEDQA mcc fac-member-few: 6 stops
LOG : Lua f:21433 st:134,339,439> ZEDQA mcc fac-notag: 18 stops
LOG : Lua f:21636 st:134,341,211> ZEDQA mcc fac-tag-hidden: 18 stops
LOG : Lua f:21837 st:134,342,969> ZEDQA mcc fac-pvp: 18 stops
LOG : Lua f:22038 st:134,344,745> ZEDQA mcc fac-row: 20 stops
LOG : Lua f:22238 st:134,346,503> ZEDQA mcc fac-pending: 19 stops
LOG : Lua f:22438 st:134,348,261> ZEDQA mcc fac-drawer: 21 stops
LOG : Lua f:22616 st:134,350,017> ZEDQA mcc fac-edit-name: 19 stops
LOG : Lua f:22816 st:134,351,780> ZEDQA mcc fac-edit-short: 19 stops
LOG : Lua f:23017 st:134,353,536> ZEDQA mcc fac-edit-long: 19 stops
LOG : Lua f:23215 st:134,355,295> ZEDQA mcc fac-edit-taken: 19 stops
LOG : Lua f:23406 st:134,357,074> ZEDQA mcc fac-edit-tag: 19 stops
LOG : Lua f:23594 st:134,358,849> ZEDQA mcc fac-edit-tag-taken: 19 stops
LOG : Lua f:23787 st:134,360,612> ZEDQA mcc fac-edit-tag-long: 19 stops
LOG : Lua f:23978 st:134,362,369> ZEDQA mcc fac-confirm-disband: 19 stops
LOG : Lua f:24178 st:134,364,119> ZEDQA mcc fac-confirm-leave: 8 stops
LOG : Lua f:24373 st:134,365,883> ZEDQA mcc fac-confirm-remove: 21 stops
LOG : Lua f:24566 st:134,367,644> ZEDQA mcc fac-confirm-owner: 21 stops
LOG : Lua f:24758 st:134,369,415> ZEDQA mcc new-empty: 7 stops
LOG : Lua f:24956 st:134,371,179> ZEDQA mcc new-short: 7 stops
LOG : Lua f:25152 st:134,372,936> ZEDQA mcc new-typed: 7 stops
LOG : Lua f:25336 st:134,374,702> ZEDQA mcc new-taken: 7 stops
LOG : Lua f:25538 st:134,376,470> ZEDQA mcc new-nodays: 6 stops
LOG : Lua f:25737 st:134,378,241> ZEDQA mcc wars-none: 4 stops
LOG : Lua f:25939 st:134,380,006> ZEDQA mcc wars-off: 2 stops
LOG : Lua f:26142 st:134,381,771> ZEDQA mcc wars-defender: 6 stops
LOG : Lua f:26345 st:134,383,544> ZEDQA mcc wars-attacker: 5 stops
LOG : Lua f:26544 st:134,385,304> ZEDQA mcc wars-accepted: 4 stops
LOG : Lua f:26744 st:134,387,061> ZEDQA mcc wars-started: 4 stops
LOG : Lua f:26946 st:134,388,828> ZEDQA mcc wars-refused: 4 stops
LOG : Lua f:27147 st:134,390,589> ZEDQA mcc wars-admin: 5 stops
LOG : Lua f:27346 st:134,392,352> ZEDQA mcc wars-confirm-accept: 8 stops
LOG : Lua f:27542 st:134,394,119> ZEDQA mcc wars-confirm-end: 7 stops
LOG : Lua f:27738 st:134,395,880> ZEDQA mcc wars-several: 10 stops
LOG : Lua f:27789 st:134,396,387> ZEDQA mcc DONE
```

### 5. mp_log_cards.lua (`ZEDQA mlc`) - PASS, 84 s

- go 21783 at 08:20:02

```text
LOG : Lua f:28217 st:134,400,137> [ZeD.QA] state #6 speed=1 paused=false player=10721,10630 grid=13 inCar=false vehicles=3 missing=get
LOG : Lua f:28217 st:134,400,143> [ZeD.QA] windows reset (R)
LOG : Lua f:28217 st:134,400,143> [ZeD.QA] run #6 ok=true
LOG : Lua f:28418 st:134,401,909> ZEDQA mlc home-row: 44 stops
LOG : Lua f:28609 st:134,403,674> ZEDQA mlc home-no-part: 44 stops
LOG : Lua f:28748 st:134,405,448> ZEDQA mlc home-no-part-no-power: 44 stops
LOG : Lua f:28889 st:134,407,222> ZEDQA mlc home-no-power: 44 stops
LOG : Lua f:29048 st:134,408,987> ZEDQA mlc log: 28 stops
LOG : Lua f:29243 st:134,410,744> ZEDQA mlc log-waiting: 14 stops
LOG : Lua f:29440 st:134,412,511> ZEDQA mlc log-kind-admin: 18 stops
LOG : Lua f:29636 st:134,414,272> ZEDQA mlc log-kind-safehouse: 16 stops
LOG : Lua f:29837 st:134,416,028> ZEDQA mlc log-kind-faction: 15 stops
LOG : Lua f:30036 st:134,417,786> ZEDQA mlc log-kind-vehicle: 17 stops
LOG : Lua f:30229 st:134,419,545> ZEDQA mlc log-kind-pvp: 15 stops
LOG : Lua f:30424 st:134,421,302> ZEDQA mlc log-kind-ticket: 17 stops
LOG : Lua f:30625 st:134,423,061> ZEDQA mlc log-who: 28 stops
LOG : Lua f:30821 st:134,424,835> ZEDQA mlc log-who-long: 28 stops
LOG : Lua f:31018 st:134,426,591> ZEDQA mlc log-hour: 28 stops
LOG : Lua f:31215 st:134,428,353> ZEDQA mlc log-3days: 28 stops
LOG : Lua f:31413 st:134,430,113> ZEDQA mlc log-find: 28 stops
LOG : Lua f:31612 st:134,431,893> ZEDQA mlc log-nothing: 14 stops
LOG : Lua f:31814 st:134,433,665> ZEDQA mlc log-one-line: 15 stops
LOG : Lua f:32015 st:134,435,428> ZEDQA mlc log-container-on: 30 stops
LOG : Lua f:32210 st:134,437,198> ZEDQA mlc log-who-pick: 7 stops
LOG : Lua f:32404 st:134,438,971> ZEDQA mlc log-flash: 28 stops
LOG : Lua f:32589 st:134,440,728> ZEDQA mlc log-pages: 41 stops
LOG : Lua f:32767 st:134,442,502> ZEDQA mlc log-first-page: 30 stops
LOG : Lua f:32952 st:134,444,278> ZEDQA mlc log-long-words: 19 stops
LOG : Lua f:33137 st:134,446,045> ZEDQA mlc line-vehicle: 31 stops
LOG : Lua f:33336 st:134,447,803> ZEDQA mlc line-pvp: 31 stops
LOG : Lua f:33531 st:134,449,579> ZEDQA mlc line-ticket: 30 stops
LOG : Lua f:33727 st:134,451,347> ZEDQA mlc line-no-place: 30 stops
LOG : Lua f:33925 st:134,453,116> ZEDQA mlc line-server: 17 stops
LOG : Lua f:34116 st:134,454,878> ZEDQA mlc line-hidden-place: 17 stops
LOG : Lua f:34304 st:134,456,646> ZEDQA mlc line-tap: 16 stops
LOG : Lua f:34501 st:134,458,422> ZEDQA mlc line-no-teleport: 31 stops
LOG : Lua f:34696 st:134,460,183> ZEDQA mlc line-no-stats: 31 stops
LOG : Lua f:34890 st:134,461,954> ZEDQA mlc around: 17 stops
LOG : Lua f:35088 st:134,463,711> ZEDQA mlc around-nobody-missed: 17 stops
LOG : Lua f:35282 st:134,465,473> ZEDQA mlc around-three-missed: 17 stops
LOG : Lua f:35482 st:134,467,246> ZEDQA mlc around-waiting: 12 stops
LOG : Lua f:35684 st:134,469,013> ZEDQA mlc around-nothing: 12 stops
LOG : Lua f:35884 st:134,470,769> ZEDQA mlc around-line: 21 stops
LOG : Lua f:36083 st:134,472,536> ZEDQA mlc around-added: 21 stops
LOG : Lua f:36284 st:134,474,305> ZEDQA mlc around-cleared: 19 stops
LOG : Lua f:36483 st:134,476,057> ZEDQA mlc around-busy: 21 stops
LOG : Lua f:36682 st:134,477,812> ZEDQA mlc ticket-around: 13 stops
LOG : Lua f:36877 st:134,479,582> ZEDQA mlc ticket-no-place: 12 stops
LOG : Lua f:37078 st:134,481,349> ZEDQA mlc ticket-no-log: 13 stops
LOG : Lua f:37278 st:134,483,111> ZEDQA mlc queue-silent: 12 stops
LOG : Lua f:37327 st:134,483,618> ZEDQA mlc DONE
```

### 6. mp_community_cards.lua (`ZEDQA mcm`) - PASS, 69 s

- go 21784 at 08:21:29

```text
LOG : Lua f:37817 st:134,487,780> [ZeD.QA] state #7 speed=1 paused=false player=10721,10630 grid=13 inCar=false vehicles=3 missing=get
LOG : Lua f:37817 st:134,487,784> [ZeD.QA] windows reset (R)
LOG : Lua f:37817 st:134,487,785> [ZeD.QA] run #7 ok=true
LOG : Lua f:38028 st:134,489,621> ZEDQA mcm tab
LOG : Lua f:38228 st:134,491,377> ZEDQA mcm tab-no-news
LOG : Lua f:38429 st:134,493,137> ZEDQA mcm tab-no-motd
LOG : Lua f:38631 st:134,494,907> ZEDQA mcm tab-no-rules
LOG : Lua f:38832 st:134,496,681> ZEDQA mcm tab-empty
LOG : Lua f:39020 st:134,498,450> ZEDQA mcm tab-many-posts
LOG : Lua f:39212 st:134,500,213> ZEDQA mcm tab-long-motd
LOG : Lua f:39413 st:134,501,996> ZEDQA mcm tab-no-part
LOG : Lua f:39613 st:134,503,762> ZEDQA mcm rules
LOG : Lua f:39813 st:134,505,534> ZEDQA mcm rules-no-appeal
LOG : Lua f:40012 st:134,507,280> ZEDQA mcm rules-no-motd
LOG : Lua f:40202 st:134,509,054> ZEDQA mcm rules-many
LOG : Lua f:40402 st:134,510,807> ZEDQA mcm join-first
LOG : Lua f:40601 st:134,512,561> ZEDQA mcm join-new
LOG : Lua f:40802 st:134,514,321> ZEDQA mcm join-new-many
LOG : Lua f:41004 st:134,516,080> ZEDQA mcm join-no-appeal
LOG : Lua f:41204 st:134,517,837> ZEDQA mcm join-no-motd
LOG : Lua f:41403 st:134,519,606> ZEDQA mcm join-long
LOG : Lua f:41606 st:134,521,372> ZEDQA mcm ask-report
LOG : Lua f:41796 st:134,523,145> ZEDQA mcm ask-report-no-part
LOG : Lua f:41990 st:134,524,920> ZEDQA mcm admin-row
LOG : Lua f:42174 st:134,526,683> ZEDQA mcm admin-row-no-part
LOG : Lua f:42374 st:134,528,445> ZEDQA mcm admin-row-gray
LOG : Lua f:42489 st:134,530,225> ZEDQA mcm edit
LOG : Lua f:42572 st:134,532,015> ZEDQA mcm edit-dirty
LOG : Lua f:42654 st:134,533,818> ZEDQA mcm edit-empty-rule
LOG : Lua f:42727 st:134,535,618> ZEDQA mcm edit-long-rule
LOG : Lua f:42806 st:134,537,430> ZEDQA mcm edit-stale
LOG : Lua f:42887 st:134,539,206> ZEDQA mcm edit-ask-off
LOG : Lua f:43028 st:134,540,997> ZEDQA mcm edit-no-rules
LOG : Lua f:43122 st:134,542,838> ZEDQA mcm edit-rules-full
LOG : Lua f:43183 st:134,544,708> ZEDQA mcm edit-no-news
LOG : Lua f:43245 st:134,546,521> ZEDQA mcm edit-many-posts
LOG : Lua f:43311 st:134,548,340> ZEDQA mcm edit-post-typed
LOG : Lua f:43439 st:134,550,099> ZEDQA mcm edit-confirm-delete
LOG : Lua f:43616 st:134,551,871> ZEDQA mcm edit-moderator
LOG : Lua f:43741 st:134,553,644> ZEDQA mcm edit-rules-only
LOG : Lua f:43863 st:134,555,442> ZEDQA mcm edit-frozen
LOG : Lua f:43895 st:134,555,853> ZEDQA mcm DONE
```

### 7. mp_extras_cards.lua (`ZEDQA mxc`) - PASS, 59 s

- go 21785 at 08:22:42

```text
LOG : Lua f:44387 st:134,560,288> [ZeD.QA] state #8 speed=1 paused=false player=10721,10630 grid=13 inCar=false vehicles=3 missing=get
LOG : Lua f:44387 st:134,560,292> [ZeD.QA] windows reset (R)
LOG : Lua f:44387 st:134,560,293> [ZeD.QA] run #8 ok=true
LOG : Lua f:44580 st:134,561,953> ZEDQA mxc admin-home
LOG : Lua f:44754 st:134,563,607> ZEDQA mxc admin-home-some-on
LOG : Lua f:44931 st:134,565,264> ZEDQA mxc admin-home-no-part
LOG : Lua f:45115 st:134,566,932> ZEDQA mxc extras-all-off
LOG : Lua f:45291 st:134,568,588> ZEDQA mxc extras-claims
LOG : Lua f:45477 st:134,570,249> ZEDQA mxc extras-claims-tow-1-30
LOG : Lua f:45664 st:134,571,908> ZEDQA mxc extras-claims-5-1
LOG : Lua f:45850 st:134,573,570> ZEDQA mxc extras-protection
LOG : Lua f:46037 st:134,575,227> ZEDQA mxc extras-protection-no-lot
LOG : Lua f:46225 st:134,576,889> ZEDQA mxc extras-teleport
LOG : Lua f:46412 st:134,578,552> ZEDQA mxc extras-teleport-no-role
LOG : Lua f:46601 st:134,580,213> ZEDQA mxc extras-log
LOG : Lua f:46787 st:134,581,875> ZEDQA mxc extras-all-on
LOG : Lua f:46975 st:134,583,532> ZEDQA mxc extras-not-saved
LOG : Lua f:47163 st:134,585,197> ZEDQA mxc extras-all-on-not-saved
LOG : Lua f:47350 st:134,586,852> ZEDQA mxc extras-saving
LOG : Lua f:47536 st:134,588,514> ZEDQA mxc extras-no-power
LOG : Lua f:47724 st:134,590,179> ZEDQA mxc extras-no-power-off
LOG : Lua f:47912 st:134,591,834> ZEDQA mxc extras-frozen
LOG : Lua f:48098 st:134,593,499> ZEDQA mxc extras-link-lost
LOG : Lua f:48264 st:134,595,163> ZEDQA mxc tab-all-off
LOG : Lua f:48442 st:134,596,819> ZEDQA mxc tab-claims
LOG : Lua f:48615 st:134,598,477> ZEDQA mxc tab-claims-all-ticks
LOG : Lua f:48789 st:134,600,139> ZEDQA mxc tab-claims-no-ticks
LOG : Lua f:48958 st:134,601,794> ZEDQA mxc tab-protection-lot
LOG : Lua f:49142 st:134,603,452> ZEDQA mxc tab-protection-walls
LOG : Lua f:49301 st:134,605,107> ZEDQA mxc tab-protection-dismantle
LOG : Lua f:49470 st:134,606,769> ZEDQA mxc tab-log
LOG : Lua f:49639 st:134,608,420> ZEDQA mxc tab-all-on
LOG : Lua f:49807 st:134,610,091> ZEDQA mxc tab-no-part
LOG : Lua f:49992 st:134,611,759> ZEDQA mxc claims-wait
LOG : Lua f:50180 st:134,613,417> ZEDQA mxc claims-none
LOG : Lua f:50364 st:134,615,080> ZEDQA mxc claims-two
LOG : Lua f:50549 st:134,616,741> ZEDQA mxc claims-unknown-car
LOG : Lua f:50733 st:134,618,414> ZEDQA mxc claims-release-ask
LOG : Lua f:50780 st:134,618,921> ZEDQA mxc DONE
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
