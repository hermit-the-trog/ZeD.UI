# ZeD-UI regression - 2026-11-13 00:05 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-13 00:05:08 |
| Finished | 2026-11-13 00:10:16 (5 min 8 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI\tools\qa\summercar_manifest.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 26166 to 26169 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 26168, 26169)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_summercar.lua | sc | **FAIL** | 216 | zqa_sc_C_stays.png, zqa_sc_D_folded.png, zqa_sc_E_shut.png, zqa_sc_F_menu.png, zqa_sc_G_footer.png, zqa_sc_H_hood_closed.png, zqa_sc_L_tile.png, zqa_sc_N_lift_menu.png | 112 Java exception(s) in the log; 21 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 26166 at 00:06:12

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
ZEDQA pre ZeD version=0.3.0-beta12 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_summercar.lua (`ZEDQA sc`) - FAIL, 216 s

- go 26167 at 00:06:18
- 112 Java exception(s) in the log
- 21 ERR line(s)
- screenshots: zqa_sc_C_stays.png, zqa_sc_D_folded.png, zqa_sc_E_shut.png, zqa_sc_F_menu.png, zqa_sc_G_footer.png, zqa_sc_H_hood_closed.png, zqa_sc_L_tile.png, zqa_sc_N_lift_menu.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sc start (89 steps)
[ZeD.QA] run #2 ok=true
ZEDQA sc startup line ok=true
ZEDQA sc cars true true
ERROR: General f:1076> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1077> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1078> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1079> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1080> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1081> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1082> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1083> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1084> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1085> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1086> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1087> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1088> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1089> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1090> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1091> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1092> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1093> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1094> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1095> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1096> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1097> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1098> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1099> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1100> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1101> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1102> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1103> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1105> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1106> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1107> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1108> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1109> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1110> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1111> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1113> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1114> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1115> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1116> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1117> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1118> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1120> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1121> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1123> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1124> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1125> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1126> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1127> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1128> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1129> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1130> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1131> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1132> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1133> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1134> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1135> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:ZeD-GUI)).vehicleName(MechanicsTab.lua:400)
    Lua((MOD:ZeD-GUI)).vehicleTabItems(MechanicsTab.lua:922)
    Lua((MOD:ZeD-GUI)).renderSplit(MechanicsTab.lua:2105)
    Lua((MOD:ZeD-GUI)).render(MechanicsTab.lua:2245)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_WorldWindow.lua:4318)
ERROR: General f:1136> Lua((MOD:ZeD-GUI)).vehicleName> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in vehicleName at KahluaUtil.fail(KahluaUtil.java:100).
... (442 more lines; see console.txt)
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
