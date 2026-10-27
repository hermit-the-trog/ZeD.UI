# ZeD-UI regression - 2026-10-26 22:25 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 22:25:29 |
| Finished | 2026-10-26 22:32:20 (6 min 51 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_H.txt (11 scripts) |
| Result | **8/11 pass**, 1 warn, 2 fail, 0 timeout |
| Go numbers | 13870 to 13882 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13881, 13882)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 48 |  |  |
| 2 | zedqa_r3_H.lua | r3H | **FAIL** | 49 | zqa_r3H_1_loot.png, zqa_r3H_2_menu_apple.png, zqa_r3H_3_menu_world.png, zqa_r3H_4_tip_shirt_zed.png, zqa_r3H_5_tip_shirt_safe.png, zqa_r3H_4_tip_book_zed.png, zqa_r3H_5_tip_book_safe.png, zqa_r3H_4_tip_vhs_zed.png, zqa_r3H_5_tip_vhs_safe.png, zqa_r3H_4_tip_seed_zed.png, zqa_r3H_5_tip_seed_safe.png, zqa_r3H_6_char_equip.png, zqa_r3H_6_char_health.png, zqa_r3H_6_char_skills.png, zqa_r3H_6_char_identity.png, zqa_r3H_7_world_craft.png, zqa_r3H_7_world_build.png, zqa_r3H_7_world_maps.png, zqa_r3H_8_charinfo_toggle.png, zqa_r3H_9_showworldmap.png, zqa_r3H_10_inventory_visible.png | 504 Java exception(s) in the log |
| 3 | suite_tabs.lua | tabs | PASS | 16 |  |  |
| 4 | suite_verbs.lua | verbs | PASS | 26 |  |  |
| 5 | zedqa_ctxlist.lua | cl | PASS | 4 | zqa_cl_1.png, zqa_cl_2.png |  |
| 6 | zedqa_grid.lua | grid | PASS | 6 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 7 | zedqa_doll.lua | doll | PASS | 8 | zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png |  |
| 8 | zedqa_mapshot.lua | ms | PASS | 4 | zqa_ms_1.png, zqa_ms_2.png |  |
| 9 | zedqa_moodles.lua | mood | WARN | 38 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png | 1 ERR line(s) |
| 10 | zedqa_charinfo.lua | ci | PASS | 9 |  |  |
| 11 | zedqa_messages.lua | msg | **FAIL** | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 2 Java exception(s) in the log; 1 expected exception(s) ignored (expect=); 14 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 48 s

- go 13870 at 22:27:20

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 0 ticks 33 frames 600
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_H.lua (`ZEDQA r3H`) - FAIL, 49 s

- go 13871 at 22:28:11
- 504 Java exception(s) in the log
- screenshots: zqa_r3H_1_loot.png, zqa_r3H_2_menu_apple.png, zqa_r3H_3_menu_world.png, zqa_r3H_4_tip_shirt_zed.png, zqa_r3H_5_tip_shirt_safe.png, zqa_r3H_4_tip_book_zed.png, zqa_r3H_5_tip_book_safe.png, zqa_r3H_4_tip_vhs_zed.png, zqa_r3H_5_tip_vhs_safe.png, zqa_r3H_4_tip_seed_zed.png, zqa_r3H_5_tip_seed_safe.png, zqa_r3H_6_char_equip.png, zqa_r3H_6_char_health.png, zqa_r3H_6_char_skills.png, zqa_r3H_6_char_identity.png, zqa_r3H_7_world_craft.png, zqa_r3H_7_world_build.png, zqa_r3H_7_world_maps.png, zqa_r3H_8_charinfo_toggle.png, zqa_r3H_9_showworldmap.png, zqa_r3H_10_inventory_visible.png

```text
[ZeD.QA] windows reset (R)
ZEDQA r3H start
[ZeD.QA] run #2 ok=true
ZEDQA r3H shot zqa_r3H_1_loot.png
ZEDQA r3H ui loot: ISCDMoodleStack@0,0,0x0 ; ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x723 ; ISHotbar@-10000,-10000,318x82 ; WaterMarkUI@3604,2127,226x22 ; N3WOMapOverhaulNotify@0,0,0x0 ; ISUIElement@0,0,1x1 ; NR_ConfirmDialog@1413,1017,1013x126 ; ZeD_BeltHUD@1438,2041,868x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; SidePanelManager@624,22,0x698 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; NR_ModalRichText@1520,780,800x600 ; DragItemRenderer@0,0,0x0 ; DragItemRenderer@0,0,0x0 ; ZeD_MessagesToasts@0,0,1x1 ; NR_ConfirmDialog@1640,1010,1124x140
ZEDQA r3H vanilla loot: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3H menu apple: Eat, Drop, Place Item, More, Rename, Rename Stack, Extended 3D Placement, Move to, Rename, Tetris
ZEDQA r3H shot zqa_r3H_2_menu_apple.png
ZEDQA r3H menu shirt: Wear, Rip Clothing, Craft, Inspect, Drop, Place Item, More, Rename, Extended 3D Placement, Move to, Rename, Tetris
ZEDQA r3H menu book: Equip Primary, Equip Secondary, Read, Craft, Drop, Place Item, More, Rename, Extended 3D Placement, Move to, Rename, Tetris
ZEDQA r3H menu bag: Wear, Equip Primary, Equip Secondary, Drop, Place Item, More, Extended 3D Placement, Move to, Tetris
ZEDQA r3H world menu: Bandit Creator, |, Rin, [DGB] Bandit Map, [DGB] Remove All Bandits, Sit on ground, Walk to, Debug Minigames, Reputation, Quest journal, Survivors, Roaming Survivors, Companion Dogs (debug), |, Spawn Bandit Clan
ZEDQA r3H shot zqa_r3H_3_menu_world.png
ZEDQA r3H shot zqa_r3H_4_tip_shirt_zed.png
ZEDQA r3H tip shirt zed 238x96
ERROR: General f:870> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:870> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:871> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:871> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:872> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:872> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:873> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:873> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:874> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:874> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:875> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:875> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:876> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:876> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:877> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:877> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:878> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:878> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:879> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:879> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:880> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:880> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:881> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:881> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:882> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:882> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:883> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:883> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:884> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:884> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:885> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:885> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:886> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:886> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:887> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:887> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:888> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:888> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:889> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:889> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:890> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:890> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:891> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:891> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:892> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:892> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:893> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:893> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:894> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:894> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:895> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:895> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:896> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:896> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:897> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:897> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:898> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:898> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:899> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:899> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:900> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:900> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:901> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:901> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:902> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:902> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:903> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:903> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:904> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:904> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:905> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:905> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:906> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:906> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:907> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:907> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:908> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:908> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:909> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:909> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:910> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:910> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:911> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:911> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:912> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:912> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:913> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:913> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:914> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:914> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:915> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:915> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:916> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:916> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:917> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:917> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:918> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:918> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:919> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:919> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:920> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:920> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:921> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:921> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:922> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:922> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:923> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:923> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:924> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:924> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:925> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:925> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:926> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:926> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:927> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:927> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:928> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:928> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:929> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:929> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:930> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:930> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:931> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:931> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:932> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:932> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ZEDQA r3H shot zqa_r3H_5_tip_shirt_safe.png
ERROR: General f:933> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
ERROR: General f:933> Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in prerender at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:[R3 copy of 3775513231] Inventory Tetris)).prerender(GridContainerInfo.lua:71)
... (1164 more lines; see console.txt)
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 16 s

- go 13872 at 22:29:05

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
ZEDQA tabs armed
[ZeD.QA] run #3 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=31 {equipgroup=5 equippart=17 equipslot=7 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=55 {hb=26 identity=29}
ZEDQA char tab=journal active=journal w=1617 focusables=8 {journal=4 jsub=4}
ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=9 {craft=9}
ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1682 focusables=1 {map=1}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA tabs done
```

### 4. suite_verbs.lua (`ZEDQA verbs`) - PASS, 26 s

- go 13873 at 22:29:25

```text
[ZeD.QA] windows reset (R)
ZEDQA verbs armed
[ZeD.QA] run #4 ok=true
ZEDQA worn=Belt ctx=equipped
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP pEq=false ctx=inventory (expect inventory)
ZEDQA fire EQUIP ok=true err=nil qhead=ISWearClothing
ZEDQA after EQUIP pEq=true ctx=equipped (expect equipped)
ZEDQA fire READ ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after READ qhead=ISReadABook (expect ISReadABook)
ZEDQA fire EQUIP ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after EQUIP bat primary=Baseball Bat ctx=equipped (expect equipped)
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP bat primary=nil (expect nil)
ZEDQA fire EAT ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after EAT qhead=ISEatFoodAction (expect ISEatFoodAction)
ZEDQA fire DROP ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after DROP cont=floor ctx=ground (expect floor/ground)
ZEDQA fire TAKE ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after TAKE inInv=false ctx=ground (expect inventory)
ZEDQA verbs done
```

### 5. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 4 s

- go 13874 at 22:29:55
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #5 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, Tetris, |, Set to be Unusable in Recipes, |, Drop, |, Rename, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 6. zedqa_grid.lua (`ZEDQA grid`) - PASS, 6 s

- go 13875 at 22:30:03
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #6 ok=true
ZEDQA grid grid on: cell 91 | cells placed 6 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Belt
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Digital Watch
ZEDQA grid down (expect the cell below): zone=charCtl el=charCtl:near item=nil
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Digital Watch
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Belt
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 7. zedqa_doll.lua (`ZEDQA doll`) - PASS, 8 s

- go 13876 at 22:30:13
- screenshots: zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA doll start
[ZeD.QA] run #7 ok=true
ZEDQA doll doll shown true | slots 6 {doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet} | belt empties 5 | photo 263,74 290x643 | lines 11 | model visible true | layer visible true
ZEDQA doll pad targets: equipslot:__disclosure,equipview:list,equipview:doll,equipslot:doll:torso,equipslot:doll:outer,equipslot:doll:hands,equipslot:doll:belt,equipslot:doll:legs,equipslot:doll:feet,equipbelt:1,equipbelt:2,equipbelt:3,equipbelt:4,equipbelt:5,equipslot:doll:head,equipslot:doll:eyes,equipslot:doll:neck,equipslot:doll:back,equipslot:doll:arms,equipslot:doll:main,equipslot:doll:off
ZEDQA doll focus torso: zone=charTabContent el=equipslot:doll:torso sel=nil layer=nil
ZEDQA doll card targets: equipcard:hverb_1,equipcard:hverb_2,equipcard:hverb_3,equipcard:name_row,equipcard:toggle_fav,equipcard:toggle_protect,equipcard:toggle_unwanted,equipcard:verb_repair_all,equipcard:verb_pad_all,equipcard:back,equipcard:__layer_1,equipcard:__layer_-1
ZEDQA doll card open: zone=charTabContent el=equipcard:hverb_1 sel=doll:torso layer=1
ZEDQA doll focus Inner: zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=1
ZEDQA doll after Inner (expect layer 2): zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=2
ZEDQA doll after B (expect sel=nil, el=equipslot:doll:torso): zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
ZEDQA doll head then down: zone=charTabContent el=equipslot:doll:eyes sel=nil layer=1
ZEDQA doll then right (expect back): zone=charTabContent el=equipslot:doll:back sel=nil layer=1
ZEDQA doll then down (expect belt): zone=charTabContent el=equipslot:doll:belt sel=nil layer=1
ZEDQA doll then left (expect neck): zone=charTabContent el=equipslot:doll:neck sel=nil layer=1
ZEDQA doll then left (leaves the doll): zone=charTabBar el=tab:equip sel=nil layer=1
ZEDQA doll view restored to list | DONE
```

### 8. zedqa_mapshot.lua (`ZEDQA ms`) - PASS, 4 s

- go 13877 at 22:30:25
- screenshots: zqa_ms_1.png, zqa_ms_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ms start
[ZeD.QA] run #8 ok=true
ZEDQA ms world 1929,0 1682x735 tab maps
ZEDQA ms DONE
```

### 9. zedqa_moodles.lua (`ZEDQA mood`) - WARN, 38 s

- go 13878 at 22:30:33
- 1 ERR line(s)
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #9 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: HUNGRY | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (HUNGRY 2, TIRED 2, STRESS 2, THIRST 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,969 size 48, stack 222; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -500,19 442x126, trail right from -56,82
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS right: the trail ends at the moodle, level with it
ZEDQA mood left: 4 moodles on (HUNGRY 3, TIRED 2, STRESS 2, THIRST 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,969 size 48, stack 222; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 106,19 442x126, trail left from 104,82
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS left: the trail ends at the moodle, level with it
ZEDQA mood bottom: 4 moodles on (HUNGRY 3, TIRED 2, STRESS 2, THIRST 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1809,1972 222x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud -133,-184 442x126, trail down from 82,-56
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS bottom: the trail ends at the moodle, level with it
ZEDQA mood FAIL with nothing changing the box goes by itself (HUNGRY)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood 1 failed
ZEDQA mood DONE
```

### 10. zedqa_charinfo.lua (`ZEDQA ci`) - PASS, 9 s

- go 13879 at 22:31:15

```text
[ZeD.QA] windows reset (R)
ZEDQA ci start
[ZeD.QA] run #10 ok=true
ZEDQA ci ZeD's Character window hook on: true | Mini Health Panel on: false
ZEDQA ci PASS the game's TOGGLE_HEALTH_PANEL key opens ZeD's health tab (tab health, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_SKILL_PANEL key opens ZeD's skills tab (tab skills, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_INFO_PANEL key opens ZeD's identity tab (tab identity, the game's window shown false)
ZEDQA ci PASS the game's TOGGLE_CLOTHING_PROTECTION_PANEL key opens ZeD's equip tab (tab equip, the game's window shown false)
ZEDQA ci PASS the same key again folds the tab (tab loot)
ZEDQA ci Mini Health Panel is off: its click is not checked
ZEDQA ci PASS with the windows shut, the click opens them on Health
ZEDQA ci PASS the windows are still
ZEDQA ci all checks passed
ZEDQA ci DONE
```

### 11. zedqa_messages.lua (`ZEDQA msg`) - FAIL, 11 s

- go 13880 at 22:31:28
- 2 Java exception(s) in the log
- 1 expected exception(s) ignored (expect=)
- 14 ERR line(s)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #11 ok=true
ZEDQA msg FAIL nothing kept: no envelope on the belt
ZEDQA msg FAIL the three notes are not on screen
ZEDQA msg FAIL the three notes are kept in Messages
ZEDQA msg FAIL the source has three messages (1)
ZEDQA msg FAIL three are new (1)
ZEDQA msg PASS a toast names the mod
ZEDQA msg PASS the game runs on after the mod paused it for its note (speed 1)
ZEDQA msg PASS the envelope is on the belt
ZEDQA msg PASS a question still asks at once
ERROR: General f:12104> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in step at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).step(worldmap-annotations.lua:85)
    Lua(Vanilla).tick(worldmap-annotations.lua:198)
ZEDQA msg ERR step 6: Object tried to call nil in step java.lang.RuntimeException
ZEDQA msg FAIL the mod got its answer (YES)
ZEDQA msg FAIL a copy of the question, already read, is in Messages
ERROR: General f:12123 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:12123> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:99)
ZEDQA msg PASS the one error is filed in Messages, counted once (1 -> 2)
ZEDQA msg PASS Messages opens on the mod
ZEDQA msg PASS opening it marks the mod's messages read
ZEDQA msg FAIL four cards: three notes and the question (1)
ZEDQA msg FAIL three OK buttons, one per note (1)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg FAIL A on the next card's OK ran its callback
ZEDQA msg FAIL the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (3677 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ERROR: General f:12500> Lua(Vanilla).step> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in step at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).step(worldmap-annotations.lua:161)
    Lua(Vanilla).tick(worldmap-annotations.lua:198)
ZEDQA msg ERR step 17: Object tried to call nil in step java.lang.RuntimeException
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg FAIL the last unanswered note got its OK as it left
ZEDQA msg 12 failed
ZEDQA msg DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    4x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefPropertyStrings> tiledef fileNumber 575 used by more than one mod
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefs > tiledef fileNumber 575 used by more than one mod
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
