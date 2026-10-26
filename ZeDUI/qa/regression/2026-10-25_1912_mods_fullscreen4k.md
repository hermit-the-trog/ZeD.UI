# ZeD-UI regression - 2026-10-25 19:13 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-25 19:13:24 |
| Finished | 2026-10-25 19:26:10 (12 min 45 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/regression.txt (81 scripts) |
| Result | **13/81 pass**, 0 warn, 8 fail, 0 timeout, 60 not run |
| Go numbers | 13118 to 13140 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- console.txt restarted at 19:22:08 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- console.txt restarted at 19:22:38 (the game starts a new one when it grows large); anything between the last read and the restart is missing
- stopped after zedqa_furniture.lua: no DONE within 180 s; the script may still be running in the game
- quit: quit to the main menu, then to the desktop (go 13139, 13140)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 3 |  |  |
| 2 | suite_tabs.lua | tabs | **FAIL** | 9 |  | 120 Java exception(s) in the log |
| 3 | suite_verbs.lua | verbs | **FAIL** | 14 |  | 121 Java exception(s) in the log |
| 4 | suite_gamepad.lua | gp | PASS | 6 |  |  |
| 5 | suite_band.lua | band | **FAIL** | 2 |  | 121 Java exception(s) in the log |
| 6 | suite_perf.lua | perf | PASS | 24 |  |  |
| 7 | zedqa_audit_fixes.lua | af | PASS | 3 |  | 30 expected exception(s) ignored (expect=) |
| 8 | zedqa_card_pad.lua | cp | PASS | 4 | zqa_cp_card.png |  |
| 9 | zedqa_ctxlist.lua | cl | PASS | 4 | zqa_cl_1.png, zqa_cl_2.png |  |
| 10 | zedqa_onepath.lua | op | **FAIL** | 17 | zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png | 1 Java exception(s) in the log |
| 11 | zedqa_grid.lua | grid | PASS | 6 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 12 | zedqa_sort_groups.lua | sg | PASS | 45 | zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png |  |
| 13 | zedqa_doll.lua | doll | PASS | 7 | zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png |  |
| 14 | zedqa_large.lua | lg | PASS | 8 | zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png |  |
| 15 | zedqa_curtain.lua | cu | **FAIL** | 100 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png | 143 Java exception(s) in the log; 1 ERR line(s) |
| 16 | zedqa_curtain2.lua | cv | PASS | 10 | zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png |  |
| 17 | zedqa_navevents.lua | ev | PASS | 4 |  |  |
| 18 | zedqa_navmap.lua | nav | **FAIL** | 8 |  | 110 Java exception(s) in the log |
| 19 | zedqa_loot_tabs.lua | lt | PASS | 1 |  |  |
| 20 | zedqa_world_pad_take.lua | wpt | **FAIL** | 58 |  | 510 Java exception(s) in the log; 27 ERR line(s) |
| 21 | zedqa_furniture.lua | fu | **FAIL** | 181 |  | no '[ZeD.QA] run #' within 20 s, but the game was logging: not bumped again; 777 Java exception(s) in the log; no DONE within 180 s; the script may still be running in the game |
| 22 | zedqa_tabicons.lua | ti | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 23 | zedqa_tabs_lit.lua | tl | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 24 | zedqa_win.lua | win | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 25 | zedqa_rootchange.lua | rc | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 26 | zedqa_scalewalk.lua | sw | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 27 | zedqa_uiscale.lua | scale | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 28 | zedqa_mapshot.lua | ms | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 29 | zedqa_mapstyles.lua | mst | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 30 | zedqa_flyers.lua | fl | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 31 | zedqa_flyermap.lua | fm | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 32 | zedqa_mapnotes.lua | mnote | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 33 | zedqa_journal_refs.lua | jr | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 34 | zedqa_journal_readers.lua | jrd | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 35 | zedqa_reader.lua | rd | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 36 | zedqa_reader_refs.lua | rr | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 37 | zedqa_notebook.lua | nb | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 38 | zedqa_print_fit.lua | pf | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 39 | zedqa_print_typeset.lua | ts | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 40 | zedqa_prompts.lua | pr | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 41 | zedqa_fishing.lua | fi | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 42 | zedqa_props_plates.lua | props | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 43 | zedqa_belt_strap.lua | belt | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 44 | zedqa_straps.lua | straps | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 45 | zedqa_buckle.lua | bk | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 46 | zedqa_buckles.lua | bks | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 47 | zedqa_beltwatch.lua | bw | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 48 | zedqa_belt_hands.lua | bh | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 49 | zedqa_watches2.lua | watches | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 50 | zedqa_container_bottom.lua | cb | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 51 | zedqa_container_controls.lua | ct | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 52 | zedqa_container_controls_captures.lua | cc | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 53 | zedqa_button_case_game.lua | bg | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 54 | zedqa_wheel_sizes.lua | ws | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 55 | zedqa_wheels.lua | wh | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 56 | zedqa_dpad_wheels.lua | dw | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 57 | zedqa_pad_glyphs.lua | pg | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 58 | zedqa_quick_chords.lua | qc | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 59 | zedqa_put_back.lua | pb | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 60 | zedqa_food_verbs.lua | fv | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 61 | zedqa_messages.lua | msg | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 62 | zedqa_moodles.lua | mood | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 63 | zedqa_ring_squares.lua | rs | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 64 | zedqa_sandbox_ig.lua | sbx | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 65 | zedqa_twoway.lua | tw | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 66 | zedqa_appliances.lua | ap | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 67 | zedqa_seat_lightbar_vanilla.lua | sl | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 68 | zedqa_car_radio_build.lua | rb | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 69 | zedqa_car_radio_cd.lua | cd | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 70 | zedqa_dash_props_smoke.lua | sm | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 71 | zedqa_tm.lua | tm | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 72 | zedqa_tour3.lua | t3 | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 73 | zedqa_dash19.lua | dash | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 74 | zedqa_dashpx.lua | dpx | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 75 | zedqa_exinfo.lua | ex | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 76 | zedqa_equipdrag.lua | eqd | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 77 | zedqa_cazio_light.lua | czl | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 78 | zedqa_dashnight.lua | dnt | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 79 | zedqa_testlang.lua | tlang | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 80 | zedqa_safemode.lua | safe | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 81 | zedqa_soak.lua | soak | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 3 s

- go 13118 at 19:15:30

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. suite_tabs.lua (`ZEDQA tabs`) - FAIL, 9 s

- go 13119 at 19:15:37
- 120 Java exception(s) in the log

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
ZEDQA tabs armed
[ZeD.QA] run #2 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=31 {equipgroup=5 equippart=17 equipslot=7 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=2 {identity=2}
ZEDQA char tab=journal active=journal w=1617 focusables=8 {journal=4 jsub=4}
ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
ERROR: General f:1318> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1318> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1319> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1319> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1320> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1320> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1321> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1321> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1322> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1322> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1323> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1323> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1324> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1324> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1325> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1325> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1326> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1326> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1327> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1327> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1328> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1328> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1329> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1329> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1330> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1330> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1331> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1331> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1332> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1332> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1333> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1333> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1334> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1334> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1335> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1335> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1336> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1336> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1337> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1337> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1338> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1338> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1339> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1339> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1340> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1340> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1341> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1341> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1342> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1342> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1343> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1343> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1344> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
    RROR: General      f:1344 at KahluaThread.flushErrorMessage      > dumping Lua stack trace
ERROR: General f:1344> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1345> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1345> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1346> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1346> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1347> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1347> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1348> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1348> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:1349> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:1349> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
... (341 more lines; see console.txt)
```

### 3. suite_verbs.lua (`ZEDQA verbs`) - FAIL, 14 s

- go 13120 at 19:15:51
- 121 Java exception(s) in the log

```text
[ZeD.QA] windows reset (R)
ZEDQA verbs armed
[ZeD.QA] run #3 ok=true
ZEDQA worn=Belt ctx=equipped
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP pEq=false ctx=inventory (expect inventory)
ZEDQA fire EQUIP ok=true err=nil qhead=ISWearClothing
ZEDQA after EQUIP pEq=true ctx=equipped (expect equipped)
ERROR: General f:2737> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).start(fix_read_walking.lua:89)
    Lua(Vanilla).begin(ISBaseTimedAction.lua:88)
    Lua(Vanilla).addToQueue(ISTimedActionQueue.lua:16)
    Lua(Vanilla).add(ISTimedActionQueue.lua:199)
ZEDQA fire READ ok=true err=nil qhead=ISReadABook
ERROR: General f:2738> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2739> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2740> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2741> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2742> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2743> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2744> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2745> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2746> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2747> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2748> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2749> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2750> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2751> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2752> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2753> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2754> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2755> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2756> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2757> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2758> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2759> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2760> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2761> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2762> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2763> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2764> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2765> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2766> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2767> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2768> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2769> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2770> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2771> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2772> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2773> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2774> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2775> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2776> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2777> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2778> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2779> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2780> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2781> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2782> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2783> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2784> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2785> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2786> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2787> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2788> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2789> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2790> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2791> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2792> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2793> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2794> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2795> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2796> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2797> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ZEDQA after READ qhead=ISReadABook (expect ISReadABook)
ERROR: General f:2798> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2799> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2800> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2801> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2802> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2803> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2804> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2805> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2806> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2807> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2808> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2809> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2810> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2811> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2812> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2813> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2814> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2815> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2816> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2817> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2818> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2819> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2820> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2821> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2822> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2823> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2824> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2825> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2826> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2827> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2828> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2829> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2830> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2831> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2832> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:2833> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
... (108 more lines; see console.txt)
```

### 4. suite_gamepad.lua (`ZEDQA gp`) - PASS, 6 s

- go 13121 at 19:16:10

```text
[ZeD.QA] windows reset (R)
ZEDQA gp armed
[ZeD.QA] run #4 ok=true
ZEDQA gp claim zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp down zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp right zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp left zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
ZEDQA gp loot charTabContent elements=0 (expect 0)
ZEDQA gp right after journal to loot (expect container strip, never jsub) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row2 onActivate (expect card open) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row3 onActivate (expect live swap) zone=charItemCard el=hverb_1 tab=loot drawer=true item=Apple ctx=false
ZEDQA gp after row3 again (expect closed) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp after row2 onContextMenu (expect ctx=true) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=true
ZEDQA gp after ctx B (expect ctx=false) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp world claim zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp world right zone=worldCtl el=worldCtl:take tab=loot drawer=false item=nil ctx=false
ZEDQA gp world craft down zone=worldCtl el=worldCtl:take tab=craft drawer=true item=nil ctx=false
ZEDQA gp world loot left (stale check) zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
ZEDQA gp done
```

### 5. suite_band.lua (`ZEDQA band`) - FAIL, 2 s

- go 13122 at 19:16:21
- 121 Java exception(s) in the log

```text
[ZeD.QA] windows reset (R)
ZEDQA band armed
[ZeD.QA] run #5 ok=true
ERROR: General f:5722> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).start(fix_read_walking.lua:89)
    Lua(Vanilla).begin(ISBaseTimedAction.lua:88)
    Lua(Vanilla).addToQueue(ISTimedActionQueue.lua:16)
    Lua(Vanilla).add(ISTimedActionQueue.lua:199)
ERROR: General f:5723> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5724> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5725> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5726> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5727> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5728> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5729> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5730> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5731> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5732> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5733> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5734> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5735> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5736> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5737> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5738> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5739> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5740> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5741> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5742> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5743> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5744> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5745> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5746> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5747> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5748> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5749> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5750> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5751> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5752> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5753> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5754> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5755> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5756> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5757> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5758> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5759> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5760> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5761> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5762> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5763> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5764> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5765> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5766> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5767> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5768> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5769> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5770> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5771> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5772> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5773> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5774> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5775> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5776> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5777> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5778> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5779> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5780> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5781> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5782> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5783> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5784> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5785> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5786> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5787> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5788> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5789> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5790> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5791> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5792> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5793> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5794> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5795> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5796> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5797> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5798> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5799> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5800> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5801> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5802> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5803> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5804> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5805> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5806> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5807> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5808> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5809> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5810> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5811> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5812> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5813> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5814> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5815> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5816> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5817> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5818> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5819> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Read While Walking)).SetNewRadius(fix_read_walking.lua:56)
    Lua((MOD:Read While Walking)).update(fix_read_walking.lua:78)
ERROR: General f:5820> Lua((MOD:Read While Walking)).SetNewRadius> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in SetNewRadius at KahluaUtil.fail(KahluaUtil.java:100).
... (94 more lines; see console.txt)
```

### 6. suite_perf.lua (`ZEDQA perf`) - PASS, 24 s

- go 13123 at 19:16:27

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #6 ok=true
ZEDQA perf char loot avg=8.34ms/tick max=14ms
ZEDQA perf char equip avg=8.42ms/tick max=35ms
ZEDQA perf char health avg=8.33ms/tick max=14ms
ZEDQA perf char thermal avg=8.42ms/tick max=33ms
ZEDQA perf char identity avg=8.33ms/tick max=14ms
ZEDQA perf char journal avg=8.46ms/tick max=35ms
ZEDQA perf char skills avg=8.40ms/tick max=17ms
ZEDQA perf world craft avg=8.51ms/tick max=32ms
ZEDQA perf world build avg=8.33ms/tick max=12ms
ZEDQA perf world maps avg=8.51ms/tick max=32ms
ZEDQA perf world forage avg=8.34ms/tick max=13ms
ZEDQA perf world animals avg=8.34ms/tick max=14ms
ZEDQA perf world loot avg=8.33ms/tick max=13ms
ZEDQA perf world craft build: 10 elements, 0.00 ms per build
ZEDQA perf done
```

### 7. zedqa_audit_fixes.lua (`ZEDQA af`) - PASS, 3 s

- go 13124 at 19:16:55
- 30 expected exception(s) ignored (expect=)

```text
[ZeD.QA] windows reset (R)
ZEDQA af start
[ZeD.QA] run #7 ok=true
ERROR: General f:9907> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9909> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9911> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9913> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9915> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9917> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9919> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9921> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9923> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9925> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9927> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9929> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9931> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9933> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9935> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9937> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9939> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9941> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9943> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9945> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9947> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9949> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9951> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9953> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9955> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9957> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9959> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9961> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9963> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:9965> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4569)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ZEDQA af tab draws again: zones 4
ZEDQA af equip slots 6
ZEDQA af equip card shown on Equip: true
ZEDQA af equip card on Journal (expect false): false
ZEDQA af card item set: true mode item
ZEDQA af after the apple left: drawer item nil mode nil (expect nil, nil)
ZEDQA af weight 0
ZEDQA af DONE
```

### 8. zedqa_card_pad.lua (`ZEDQA cp`) - PASS, 4 s

- go 13125 at 19:17:03
- screenshots: zqa_cp_card.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cp start
[ZeD.QA] run #8 ok=true
ZEDQA cp selected the apple row 14
ZEDQA cp card open true | card buttons 7 {hverb_1,hverb_2,name_row,toggle_fav,toggle_protect,toggle_unwanted,verb_repair}
ZEDQA cp fav chip rect on the card (mouse): true
ZEDQA cp before left: zone=charItemCard el=hverb_1
ZEDQA cp after left (expect charItemCard): zone=charTabBar el=tab:loot
ZEDQA cp right 1: zone=charItemCard el=hverb_1
ZEDQA cp right 2: zone=charItemCard el=hverb_2
ZEDQA cp left: zone=charItemCard el=hverb_1
ZEDQA cp after B: card item nil (expect nil)
ZEDQA cp health: inv then left (expect charTabContent): zone=charTabContent el=health:__disclosure
ZEDQA cp health: right: zone=charMainInv el=invrow:1
ZEDQA cp DONE
```

### 9. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 4 s

- go 13126 at 19:17:11
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #9 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 10. zedqa_onepath.lua (`ZEDQA op`) - FAIL, 17 s

- go 13127 at 19:17:20
- 1 Java exception(s) in the log
- screenshots: zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png

```text
[ZeD.QA] windows reset (R)
ZEDQA op start
[ZeD.QA] run #10 ok=true
ZEDQA op crate ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@1c3c1e1b] type crate
ZEDQA op world select crate false
ZEDQA op apple menu: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Rename
ZEDQA op move to: Crate, Floor
ZEDQA op picked Crate
ZEDQA op apple now in crate
ZEDQA op hammer menu: Attach, Claw Hammer, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Move to, |, Craft, Set to be Unusable in Recipes, Show Build Recipes Used In, |, Equip Primary, Equip Secondary, |, Drop, |, Rename
ZEDQA op prompt true entry Claw Hammer
ZEDQA op hammer name: Old Faithful custom true
ZEDQA op card els: hverb_1, hverb_2, name_row, toggle_fav, toggle_protect, toggle_unwanted, verb_repair
ZEDQA op dbl: first false second true
ZEDQA op primary: true
ERROR: General f:12997> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua((MOD:Disassemble Container With Items)).fromObject(disassemble.lua:34)
    Lua(Vanilla).createMenu(ISDisassembleMenu.lua:10)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:209)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
ZEDQA op crate menu: Sit on ground, Walk to, Configure Container, |, Take All
ZEDQA op take all pressed
ZEDQA op crate left: 1 apple home true
ZEDQA op bottle verbs: Drink, More
ZEDQA op knife maint: repair, sharpen sharp 0.4000000059604645
ZEDQA op nocraft on true off false
ZEDQA op DONE
```

### 11. zedqa_grid.lua (`ZEDQA grid`) - PASS, 6 s

- go 13128 at 19:17:41
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #11 ok=true
ZEDQA grid grid on: cell 91 | cells placed 14 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Angel Cross's Key Ring
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Apple (Fresh)
ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:15 item=Fanny Pack
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Apple (Fresh)
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Angel Cross's Key Ring
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 12. zedqa_sort_groups.lua (`ZEDQA sg`) - PASS, 45 s

- go 13129 at 19:17:51
- screenshots: zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sg start
[ZeD.QA] run #12 ok=true
ZEDQA sg no pickup in the loaded cell; spawned one beside the character: true
ZEDQA sg pack worn at base:back: true
ZEDQA sg given: bag 23, pack 8, bed 19, floor 11
ZEDQA sg floor container things 11 | char window true world window true
ZEDQA sg columns at start: char 0 world 0
ZEDQA sg mode single:
ZEDQA sg single list cat char: columns 1 rows 31 headers 6 order ok pad 31 (charMainInv=31) grid false sort cat/true
ZEDQA sg single list cat world: columns 1 rows 9 headers 7 order ok pad 9 (worldMainInv=9) grid false sort cat/true
ZEDQA sg single list name char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/true
ZEDQA sg single list name world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort name/true
ZEDQA sg single list cond char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort cond/true
ZEDQA sg single list cond world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort cond/true
ZEDQA sg single list wt char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort wt/true
ZEDQA sg single list wt world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort wt/true
ZEDQA sg single list name rev char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/false
ZEDQA sg single list name rev world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort name/false
ZEDQA sg fold char: ClothAcc folded, rows 29 of 31, its header true
ZEDQA sg fold world: CraftG folded, rows 8 of 9, its header true
ZEDQA sg fold char on Name: rows 31 headers 0
ZEDQA sg fold world on Name: rows 9 headers 0
ZEDQA sg fold char back on Category: still folded true rows 29
ZEDQA sg fold world back on Category: still folded true rows 8
ZEDQA sg stack char: Base.Apple x10 open, rows 40 of 31 (+9 expected), children follow true, headers 0
ZEDQA sg stack world: Base.Apple x2 open, rows 10 of 9 (+1 expected), children follow true, headers 0
ZEDQA sg single grid cat char: columns 1 rows 31 headers 5 order ok pad 31 (charMainInv=31) grid true sort cat/true
ZEDQA sg single grid cat world: columns 1 rows 9 headers 5 order ok pad 9 (worldMainInv=9) grid true sort cat/true
ZEDQA sg single grid name char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort name/true
ZEDQA sg single grid name world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort name/true
ZEDQA sg single grid cond char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort cond/true
ZEDQA sg single grid cond world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort cond/true
ZEDQA sg single grid wt char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort wt/true
ZEDQA sg single grid wt world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort wt/true
ZEDQA sg single grid name rev char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort name/false
ZEDQA sg single grid name rev world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort name/false
ZEDQA sg mode multi: char:true world:true
ZEDQA sg multi list cat char: columns 2 rows 8+31 headers 11 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cat/true
ZEDQA sg multi list cat world: columns 2 rows 15+9 headers 11 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort cat/true
ZEDQA sg multi list name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/true
ZEDQA sg multi list name world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort name/true
ZEDQA sg multi list cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cond/true
ZEDQA sg multi list cond world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort cond/true
ZEDQA sg multi list wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort wt/true
ZEDQA sg multi list wt world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort wt/true
ZEDQA sg multi list name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/false
ZEDQA sg multi list name rev world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort name/false
ZEDQA sg multi grid cat char: columns 2 rows 8+31 headers 10 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cat/true
ZEDQA sg multi grid cat world: columns 2 rows 15+9 headers 9 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort cat/true
ZEDQA sg multi grid name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/true
ZEDQA sg multi grid name world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort name/true
ZEDQA sg multi grid cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cond/true
ZEDQA sg multi grid cond world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort cond/true
ZEDQA sg multi grid wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort wt/true
ZEDQA sg multi grid wt world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort wt/true
ZEDQA sg multi grid name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/false
ZEDQA sg multi grid name rev world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort name/false
ZEDQA sg columns off: char:true world:true
ZEDQA sg restored: bag things 48 (were 48), bed 3, world things on the square 0, floor container 0
ZEDQA sg all checks held; DONE
```

### 13. zedqa_doll.lua (`ZEDQA doll`) - PASS, 7 s

- go 13130 at 19:18:41
- screenshots: zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA doll start
[ZeD.QA] run #13 ok=true
ZEDQA doll doll shown true | slots 6 {doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet} | belt empties 4 | photo 263,74 290x643 | lines 11 | model visible true | layer visible true
ZEDQA doll pad targets: equipslot:__disclosure,equipview:list,equipview:doll,equipslot:doll:torso,equipslot:doll:outer,equipslot:doll:hands,equipslot:doll:belt,equipslot:doll:legs,equipslot:doll:feet,equipbelt:1,equipbelt:2,equipbelt:3,equipbelt:4,equipslot:doll:head,equipslot:doll:eyes,equipslot:doll:neck,equipslot:doll:back,equipslot:doll:arms,equipslot:doll:main,equipslot:doll:off
ZEDQA doll focus torso: zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
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

### 14. zedqa_large.lua (`ZEDQA lg`) - PASS, 8 s

- go 13131 at 19:18:53
- screenshots: zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png

```text
[ZeD.QA] windows reset (R)
ZEDQA lg start
[ZeD.QA] run #14 ok=true
ZEDQA lg small: rowH 53 buttonH 46 titleBarH 46 | cat 151 wt 81 | equip slot col 140
ZEDQA lg large: rowH 60 buttonH 53 titleBarH 53 | cat 176 wt 93 | equip slot col 163
ZEDQA lg size back to small | DONE
```

### 15. zedqa_curtain.lua (`ZEDQA cu`) - FAIL, 100 s

- go 13132 at 19:19:05
- 143 Java exception(s) in the log
- 1 ERR line(s)
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cu start
[ZeD.QA] run #15 ok=true
ZEDQA cu loaded: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
ZEDQA cu scale 1.75 root 1.75 screen 3840x2160
ZEDQA cu reset: ZeD_Window.resetLayout
ZEDQA cu reset: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
ZEDQA cu before: x 1929 w 1617 title Ground 0 button 176.6640625,5 35
ZEDQA cu rolled true: x 2643 w 903 (sum 3546 was 3546) rod 1929,0 714x46 content false title Maps
ZEDQA cu pad stops: worldContainerStrip:curtain:unroll
ZEDQA cu A on the tab
ZEDQA cu unrolled true: x 1929 w 1617 content true rod false
ZEDQA cu ok first roll World 1929,0 1617x735
ZEDQA cu rolled again true
ZEDQA cu tab closed: rolled false x 1929 w 777 content true drawer false
ZEDQA cu ok tab closed while rolled World 1929,0 777x735
ZEDQA cu World before: 1929,0 1617x735 (other 1134,0 777x735) drawer true tab tab maps
ZEDQA cu cycle1 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World rollW 714
ZEDQA cu ok cycle1 rolled World rod flush at 1929,0 714x46
ZEDQA cu ok cycle1 rolled World 2643,0 903x735
ZEDQA cu ok cycle1 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle1 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 World 1929,0 1617x735
ZEDQA cu ok cycle1 other (Character) 1134,0 777x735
ZEDQA cu ok cycle1 World saved 1102.286,0.000 444.000x420.000
ZEDQA cu cycle2 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World rollW 714
ZEDQA cu ok cycle2 rolled World rod flush at 1929,0 714x46
ZEDQA cu ok cycle2 rolled World 2643,0 903x735
ZEDQA cu ok cycle2 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle2 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 World 1929,0 1617x735
ZEDQA cu ok cycle2 other (Character) 1134,0 777x735
ZEDQA cu ok cycle2 World saved 1102.286,0.000 444.000x420.000
ZEDQA cu moved by rod World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1617x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 903x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World rollW 714
ZEDQA cu ok moved by rod rolled World rod flush at 1929,0 714x46
ZEDQA cu ok moved by rod rolled World 2643,0 903x735
ZEDQA cu ok moved by rod while rolled: other Character 1134,0 777x735
ZEDQA cu moved by rod World moved by 200,200 (rod) to 2843,200 903x735
ZEDQA cu ok moved by rod moved World rod flush at 2129,200 714x46
ZEDQA cu moved by rod World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 903x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1617x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod World 2129,200 1617x735
ZEDQA cu ok moved by rod other (Character) 1134,0 777x735
ZEDQA cu ok moved by rod World saved 1216.571,114.286 444.000x420.000
ZEDQA cu moved by title World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1617x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 903x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World rollW 714
ZEDQA cu ok moved by title rolled World rod flush at 2129,200 714x46
ZEDQA cu ok moved by title rolled World 2843,200 903x735
ZEDQA cu ok moved by title while rolled: other Character 1134,0 777x735
ZEDQA cu moved by title World moved by -200,200 (title) to 2643,400 903x735
ZEDQA cu ok moved by title moved World rod flush at 1929,400 714x46
ZEDQA cu moved by title World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title World 1929,400 1617x735
ZEDQA cu ok moved by title other (Character) 1134,0 777x735
ZEDQA cu ok moved by title World saved 1102.286,228.571 444.000x420.000
ZEDQA cu cycle5 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World rollW 714
ZEDQA cu ok cycle5 rolled World rod flush at 1929,400 714x46
ZEDQA cu ok cycle5 rolled World 2643,400 903x735
ZEDQA cu ok cycle5 while rolled: other Character 1134,0 777x735
ZEDQA cu cycle5 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 903x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 World 1929,400 1617x735
ZEDQA cu ok cycle5 other (Character) 1134,0 777x735
ZEDQA cu ok cycle5 World saved 1102.286,228.571 444.000x420.000
ZEDQA cu character health tab true
ZEDQA cu Character before: 294,0 1617x735 (other 1929,400 1617x735) drawer true tab tab health
ZEDQA cu cycle1 Character before roll: Character 294,0 1617x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character rollW 714
ZEDQA cu ok cycle1 rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok cycle1 rolled Character 294,0 903x735
ZEDQA cu ok cycle1 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle1 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle1 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle1 Character 294,0 1617x735
ZEDQA cu ok cycle1 other (World) 1929,400 1617x735
ZEDQA cu ok cycle1 Character saved 648.000,0.000 444.000x420.000
ZEDQA cu cycle2 Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character rollW 714
ZEDQA cu ok cycle2 rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok cycle2 rolled Character 294,0 903x735
ZEDQA cu ok cycle2 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle2 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle2 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle2 Character 294,0 1617x735
ZEDQA cu ok cycle2 other (World) 1929,400 1617x735
ZEDQA cu ok cycle2 Character saved 648.000,0.000 444.000x420.000
ZEDQA cu moved by rod Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character rollW 714
ZEDQA cu ok moved by rod rolled Character rod flush at 1197,0 714x46
ZEDQA cu ok moved by rod rolled Character 294,0 903x735
ZEDQA cu ok moved by rod while rolled: other World 1929,400 1617x735
ZEDQA cu moved by rod Character moved by 200,200 (rod) to 494,200 903x735
ZEDQA cu ok moved by rod moved Character rod flush at 1397,200 714x46
ZEDQA cu moved by rod Character rolled, before unroll: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by rod Character unrolled: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by rod Character 494,200 1617x735
ZEDQA cu ok moved by rod other (World) 1929,400 1617x735
ZEDQA cu ok moved by rod Character saved 762.286,114.286 444.000x420.000
ZEDQA cu moved by title Character before roll: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rolled: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character rollW 714
ZEDQA cu ok moved by title rolled Character rod flush at 1397,200 714x46
ZEDQA cu ok moved by title rolled Character 494,200 903x735
ZEDQA cu ok moved by title while rolled: other World 1929,400 1617x735
ZEDQA cu moved by title Character moved by 200,200 (title) to 694,400 903x735
ZEDQA cu ok moved by title moved Character rod flush at 1597,400 714x46
ZEDQA cu moved by title Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu moved by title Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok moved by title Character 694,400 1617x735
ZEDQA cu ok moved by title other (World) 1929,400 1617x735
ZEDQA cu ok moved by title Character saved 876.571,228.571 444.000x420.000
ZEDQA cu cycle5 Character before roll: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character rollW 714
ZEDQA cu ok cycle5 rolled Character rod flush at 1597,400 714x46
ZEDQA cu ok cycle5 rolled Character 694,400 903x735
ZEDQA cu ok cycle5 while rolled: other World 1929,400 1617x735
ZEDQA cu cycle5 Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu cycle5 Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok cycle5 Character 694,400 1617x735
ZEDQA cu ok cycle5 other (World) 1929,400 1617x735
ZEDQA cu ok cycle5 Character saved 876.571,228.571 444.000x420.000
ZEDQA cu closed rolled (inventory key) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (inventory key) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (inventory key) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) World window closed
ZEDQA cu ok closed rolled (inventory key) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (inventory key) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (rod close box) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (rod close box) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (rod close box) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (rod close box) World window closed
ZEDQA cu ok closed rolled (rod close box) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (rod close box) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (rod close box) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (rod close box) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (rod close box) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (controller Y hold) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab World 1929,400 1617x735
ZEDQA cu closed rolled (controller Y hold) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1617x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
ZEDQA cu ok closed rolled (controller Y hold) World rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) World window closed
ZEDQA cu ok closed rolled (controller Y hold) World rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) World reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled World 1929,400 777x735
ZEDQA cu ok closed rolled (controller Y hold) reopened: other Character 694,400 1617x735
ZEDQA cu closed rolled (inventory key) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (inventory key) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (inventory key) Character window closed
ZEDQA cu ok closed rolled (inventory key) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (inventory key) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (inventory key) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (inventory key) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (inventory key) reopened: other World 1929,400 777x735
ZEDQA cu closed rolled (close box) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (close box) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (close box) Character window closed
ZEDQA cu ok closed rolled (close box) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (close box) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (close box) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (close box) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (close box) reopened: other World 1929,400 777x735
ZEDQA cu closed rolled (controller Y hold) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab Character 694,400 1617x735
ZEDQA cu closed rolled (controller Y hold) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character rolled (rods in UI 1)
ZEDQA cu ok closed rolled (controller Y hold) Character window closed
ZEDQA cu ok closed rolled (controller Y hold) Character rod gone (rod visible false, rods in UI 0)
ZEDQA cu closed rolled (controller Y hold) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
ZEDQA cu ok closed rolled (controller Y hold) Character reopened unrolled (rolled nil, rods in UI 0)
ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled Character 694,400 1617x735
ZEDQA cu ok closed rolled (controller Y hold) reopened: other World 1929,400 777x735
ZEDQA cu World tabs: on maps 1929,400 1617x735 (other 694,400 1617x735)
ZEDQA cu ok tab forage World rolled before the press
ZEDQA cu ok tab forage World still rolled on the tab (tab forage)
ZEDQA cu ok tab forage rolled World 2643,400 903x735
ZEDQA cu ok tab forage World unrolled (rods in UI 0)
ZEDQA cu ok tab forage unrolled World 1929,400 1617x735
ZEDQA cu ok tab forage unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab forage back on maps World 1929,400 1617x735
ZEDQA cu ok tab craft World rolled before the press
ZEDQA cu ok tab craft World still rolled on the tab (tab craft)
ZEDQA cu ok tab craft rolled World 2643,400 903x735
ZEDQA cu ok tab craft World unrolled (rods in UI 0)
ZEDQA cu ok tab craft unrolled World 1929,400 1617x735
ZEDQA cu ok tab craft unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab craft back on maps World 1929,400 1617x735
ZEDQA cu ok tab build World rolled before the press
ZEDQA cu ok tab build World still rolled on the tab (tab build)
ZEDQA cu ok tab build rolled World 2643,400 903x735
ZEDQA cu ok tab build World unrolled (rods in UI 0)
ZEDQA cu ok tab build unrolled World 1929,400 1617x735
ZEDQA cu ok tab build unrolled: other Character 694,400 1617x735
ZEDQA cu ok tab build back on maps World 1929,400 1617x735
ZEDQA cu ok tab furniture World rolled before the press
ERROR: General f:24288> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24289> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24290> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24291> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24292> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24293> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24294> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24295> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24296> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24297> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24298> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24299> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24300> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24301> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24302> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24303> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24304> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24305> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24306> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24307> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24308> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24309> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24310> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24311> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24312> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24313> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24314> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24315> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24316> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:24317> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
... (762 more lines; see console.txt)
```

### 16. zedqa_curtain2.lua (`ZEDQA cv`) - PASS, 10 s

- go 13133 at 19:20:50
- screenshots: zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cv start
[ZeD.QA] run #16 ok=true
ZEDQA cv health tab true
ZEDQA cv char before rolled false x 294 w 1617 right 1911 tab health content true rod - button true
ZEDQA cv roll true
ZEDQA cv char rolled rolled true x 294 w 903 right 1197 tab health content false rod 1197+714
ZEDQA cv skills tab true
ZEDQA cv char after switch rolled true x 294 w 903 right 1197 tab skills content false rod 1197+714
ZEDQA cv A on the tab (charContainerStrip)
ZEDQA cv char unrolled rolled false x 294 w 1617 right 1911 tab skills content true rod - (was x 294 w 1617)
ZEDQA cv world roll true
ZEDQA cv world rolled rolled true x 2643 w 903 right 3546 tab maps content false rod 1929+714
ZEDQA cv world after switch rolled true x 2643 w 903 right 3546 tab forage content false rod 1929+714
ZEDQA cv world unrolled rolled false x 1929 w 1617 right 3546 tab forage content true rod -
ZEDQA cv DONE
```

### 17. zedqa_navevents.lua (`ZEDQA ev`) - PASS, 4 s

- go 13134 at 19:21:05

```text
[ZeD.QA] windows reset (R)
ZEDQA ev start
[ZeD.QA] run #17 ok=true
ZEDQA ev 1 on the hammer row: Char charMainInv:invrow:7 (Claw Hammer)
ZEDQA ev 1 after A (expect the card's primary action): Char charItemCard:hverb_1
ZEDQA ev 1 after B (expect back on the hammer row): Char charMainInv:invrow:7 (Claw Hammer)
ZEDQA ev 2 Right (expect the strip): Char charTabContent:skill:Cooking
ZEDQA ev 2 Left (expect back on the hammer row): Char charMainInv:invrow:7 (Claw Hammer)
ZEDQA ev 3 on the screwdriver: Char charMainInv:invrow:14 (Screwdriver)
ZEDQA ev 3 Left (expect the active tab): Char charTabBar:tab:loot
ZEDQA ev 3 Down: Char charTabBar:tab:equip
ZEDQA ev 3 A on: Char charTabBar:tab:equip
ZEDQA ev 3 after A on the tab (expect still on it): Char charTabBar:tab:equip
ZEDQA ev 3 Right (expect the tab's first control): Char charTabContent:equipgroup:head
ZEDQA ev 3 Left (expect back on the tab): Char charTabBar:tab:equip
ZEDQA ev 4 on the screwdriver: Char charMainInv:invrow:14 (Screwdriver)
ZEDQA ev 4 after RB (World): World worldTabBar:tab:loot
ZEDQA ev 4 after LB (expect back on the screwdriver): Char charMainInv:invrow:14 (Screwdriver)
ZEDQA ev 5 on the hammer: Char charMainInv:invrow:7 (Claw Hammer)
ZEDQA ev 5 after the hammer went (expect a neighbouring row): Char charMainInv:invrow:7 (Digital Watch)
ZEDQA ev 6 on the star tool: World worldTabContent:map:tool:star
ZEDQA ev 6 Down (expect the map): World worldTabContent:map:canvas:cursor
ZEDQA ev 6 Up (expect back on the star tool): World worldTabContent:map:tool:star
ZEDQA ev 6 Down, Left: World worldCtl:worldCtl:same
ZEDQA ev 6 Right (expect back on the map): World worldTabContent:map:canvas:cursor
ZEDQA ev 6 Right again: World worldTabBar:tab:maps
ZEDQA ev 7 on unfold: World worldTabContent:map:popout
ZEDQA ev 7 after unfold (expect the big map's window): Map popMapContent:map:canvas:cursor
ZEDQA ev 7 after B (expect the World window's map or unfold): World worldTabContent:map:popout
ZEDQA ev DONE
```

### 18. zedqa_navmap.lua (`ZEDQA nav`) - FAIL, 8 s

- go 13135 at 19:21:14
- 110 Java exception(s) in the log

```text
[ZeD.QA] windows reset (R)
ZEDQA nav start
[ZeD.QA] run #18 ok=true
ZEDQA nav char loot: 28 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char loot STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) invrow:14(D)
ZEDQA nav char loot charTabBar:tab:loot U>charMainInv:invrow:2~ D>tab:equip L>- R>charMainInv:invrow:7
ZEDQA nav char loot charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charMainInv:invrow:7
ZEDQA nav char loot charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charMainInv:invrow:7
ZEDQA nav char loot charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charMainInv:invrow:7
ZEDQA nav char loot charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charMainInv:invrow:7
ZEDQA nav char loot charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charMainInv:invrow:7
ZEDQA nav char loot charTabBar:tab:skills U>tab:journal D>charMainInv:invrow:10~ L>- R>charMainInv:invrow:7
ZEDQA nav char loot charMainInv:invrow:1 U>- D>invrow:2 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabBar:tab:loot R>view:list:player
ZEDQA nav char loot charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:14 U>invrow:13 D>- L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:view:list:player U>invrow:2~ D>invrow:3~ L>invrow:2 R>view:grid:player
ZEDQA nav char loot charMainInv:view:grid:player U>invrow:2~ D>invrow:3~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char loot charContainerStrip:container:1 U>charMainInv:invrow:2~ D>container:2 L>charMainInv:view:grid:player R>window:World
ZEDQA nav char loot charContainerStrip:container:2 U>container:1 D>charMainInv:invrow:5~ L>charMainInv:invrow:4 R>window:World
ZEDQA nav char loot charCtl:charCtl:xfer U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charTabBar:tab:loot~ R>charMainInv:invrow:14
ZEDQA nav char loot charCtl:charCtl:same U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:xfer R>charMainInv:invrow:14
ZEDQA nav char loot charCtl:charCtl:near U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:same R>charMainInv:invrow:14
ZEDQA nav char equip: 59 targets | TRAP 6 {equipslot:INR,equipslot:GLV,equipslot:PNT,equipslot:SOC,equipslot:BOT,equipslot:BLT} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char equip STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) equippart:Right Foot(D) equippart:Left Foot(D) invrow:1(U)
ZEDQA nav char equip charTabBar:tab:loot U>charMainInv:invrow:2~ D>tab:equip L>- R>charTabContent:equipslot:__disclosure
ZEDQA nav char equip charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charTabContent:equipgroup:head
ZEDQA nav char equip charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charTabContent:equipgroup:torso
ZEDQA nav char equip charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charTabContent:equipgroup:arms
ZEDQA nav char equip charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charTabContent:equipgroup:legs
ZEDQA nav char equip charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charTabContent:equipslot:PNT
ZEDQA nav char equip charTabBar:tab:skills U>tab:journal D>charTabContent:equipslot:BOT~ L>- R>charTabContent:equipslot:SOC
ZEDQA nav char equip charTabContent:equipslot:__disclosure U>charTabBar:tab:equip~ D>equipgroup:head L>charTabBar:tab:equip R>equipview:list
ZEDQA nav char equip charTabContent:equipview:list U>charMainInv:invrow:2~ D>equipgroup:head L>equipslot:__disclosure R>equipview:doll
ZEDQA nav char equip charTabContent:equipview:doll U>charMainInv:invrow:2~ D>equipgroup:head L>equipslot:__disclosure R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equippart:Head U>equipslot:BLT D>equippart:Neck L>equippart:Neck R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equippart:Neck U>equippart:Head D>equippart:Upper Torso L>charTabBar:tab:equip~ R>equippart:Head
ZEDQA nav char equip charTabContent:equippart:Upper Torso U>equippart:Neck D>equippart:Lower Torso L>equippart:Right Upper Arm R>equippart:Left Upper Arm
ZEDQA nav char equip charTabContent:equippart:Right Upper Arm U>equippart:Upper Torso D>equippart:Right Forearm L>equippart:Right Forearm R>equippart:Upper Torso
ZEDQA nav char equip charTabContent:equippart:Left Upper Arm U>equippart:Upper Torso D>equippart:Left Forearm L>equippart:Upper Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Lower Torso U>equippart:Upper Torso D>equippart:Groin L>equippart:Right Upper Arm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Right Forearm U>equippart:Right Upper Arm D>equippart:Right Hand L>equippart:Right Hand R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Forearm U>equippart:Left Upper Arm D>equippart:Left Hand L>equippart:Groin R>equippart:Left Hand
ZEDQA nav char equip charTabContent:equippart:Groin U>equippart:Lower Torso D>equippart:Right Upper Leg L>equippart:Lower Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Hand U>equippart:Right Forearm D>equippart:Right Upper Leg~ L>charTabBar:tab:equip~ R>equippart:Right Forearm
ZEDQA nav char equip charTabContent:equippart:Left Hand U>equippart:Left Forearm D>equippart:Left Upper Leg~ L>equippart:Left Forearm R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equippart:Right Upper Leg U>equippart:Groin D>equippart:Right Lower Leg L>equippart:Right Forearm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Left Upper Leg U>equippart:Groin D>equippart:Left Lower Leg L>equippart:Groin R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Lower Leg U>equippart:Right Upper Leg D>equippart:Right Foot L>equippart:Right Foot R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Lower Leg U>equippart:Left Upper Leg D>equippart:Left Foot L>equippart:Left Upper Leg R>equippart:Left Foot
ZEDQA nav char equip charTabContent:equippart:Right Foot U>equippart:Right Lower Leg D>- L>charTabBar:tab:equip~ R>equippart:Right Lower Leg
ZEDQA nav char equip charTabContent:equippart:Left Foot U>equippart:Left Lower Leg D>- L>equippart:Left Lower Leg R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipgroup:head U>equipslot:__disclosure D>equipgroup:torso L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipgroup:torso U>equipgroup:head D>equipslot:INR L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipgroup:arms U>equipslot:INR D>equipslot:GLV L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipgroup:legs U>equipslot:GLV D>equipslot:PNT L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipgroup:held U>equipslot:BOT D>equipslot:BLT L>charTabBar:tab:equip~ R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipslot:INR [OWN D-PAD] U>equipgroup:torso D>equipgroup:arms L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipslot:GLV [OWN D-PAD] U>equipgroup:arms D>equipgroup:legs L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipslot:PNT [OWN D-PAD] U>equipgroup:legs D>equipslot:SOC L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipslot:SOC [OWN D-PAD] U>equipslot:PNT D>equipslot:BOT L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipslot:BOT [OWN D-PAD] U>equipslot:SOC D>equipgroup:held L>charTabBar:tab:equip R>charMainInv:invrow:7
ZEDQA nav char equip charTabContent:equipslot:BLT [OWN D-PAD] U>equipgroup:held D>equippart:Head L>charTabBar:tab:equip~ R>charMainInv:invrow:7
ZEDQA nav char equip charMainInv:invrow:1 U>- D>invrow:2 L>charTabContent:equipslot:__disclosure~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabContent:equipslot:__disclosure R>view:list:player
ZEDQA nav char equip charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabContent:equipslot:__disclosure R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabContent:equipgroup:torso R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabContent:equipslot:INR R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabContent:equipgroup:arms R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabContent:equipgroup:legs R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabContent:equipslot:PNT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabContent:equipslot:SOC R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabContent:equipslot:BOT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabContent:equipslot:BLT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabContent:equipslot:BLT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:14 U>invrow:13 D>charTabContent:equippart:Left Upper Arm~ L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:view:list:player U>invrow:2~ D>invrow:3~ L>invrow:2 R>view:grid:player
ZEDQA nav char equip charMainInv:view:grid:player U>invrow:2~ D>invrow:3~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char equip charContainerStrip:container:1 U>charMainInv:invrow:2~ D>container:2 L>charMainInv:view:grid:player R>window:World
ZEDQA nav char equip charContainerStrip:container:2 U>container:1 D>charMainInv:invrow:5~ L>charMainInv:invrow:4 R>window:World
ZEDQA nav char equip charCtl:charCtl:xfer U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charTabContent:equippart:Head R>charMainInv:invrow:14
ZEDQA nav char equip charCtl:charCtl:same U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:xfer R>charMainInv:invrow:14
ZEDQA nav char equip charCtl:charCtl:near U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:same R>charMainInv:invrow:14
ZEDQA nav char health: 55 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char health STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) invrow:14(D)
ZEDQA nav char thermal: 54 targets | TRAP 1 {thermal:__gridscroll} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char thermal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) invrow:14(D)
ZEDQA nav char identity: 30 targets | TRAP 1 {identity:__gridscroll} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char identity STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) invrow:14(D)
ZEDQA nav char journal: 36 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char journal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) journal:group:6_1993(D) invrow:1(U)
ZEDQA nav char skills: 88 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char skills STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) training:col1_Foraging(D) training:col2_Trapping(D) invrow:1(U)
ZEDQA nav world loot: 10 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world loot STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world loot worldContainerStrip:container:1 U>- D>worldCtl:worldCtl:take~ L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world loot worldTabBar:tab:loot U>- D>tab:craft L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:craft U>tab:loot D>tab:build L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldTabBar:tab:animals U>tab:forage D>worldCtl:worldCtl:same~ L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldCtl:worldCtl:take U>worldContainerStrip:container:1 D>- L>worldContainerStrip:container:1 R>worldCtl:same
ZEDQA nav world loot worldCtl:worldCtl:same U>worldContainerStrip:container:1 D>- L>worldCtl:take R>worldTabBar:tab:loot~
ZEDQA nav world craft: 20 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world craft STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world build: 18 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world build STUCK: container:1(U) build:catDrop(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
ERROR: General f:31758> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31758> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31759> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31759> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31760> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31760> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31761> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31761> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31762> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31762> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31763> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31763> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31764> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31764> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31765> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31765> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31766> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31766> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31767> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31767> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31768> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31768> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31769> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31769> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31770> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31770> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31771> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31771> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31772> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31772> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31773> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31773> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31774> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31774> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31775> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31775> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31776> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31776> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31777> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31777> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31778> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31778> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31779> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31779> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31780> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:31780> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:31781> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
... (417 more lines; see console.txt)
```

### 19. zedqa_loot_tabs.lua (`ZEDQA lt`) - PASS, 1 s

- go 13136 at 19:21:27

```text
[ZeD.QA] windows reset (R)
ZEDQA lt start
[ZeD.QA] run #19 ok=true
ZEDQA lt Character loot drawer false | World loot drawer false
ZEDQA lt DONE
```

### 20. zedqa_world_pad_take.lua (`ZEDQA wpt`) - FAIL, 58 s

- go 13137 at 19:21:32
- 510 Java exception(s) in the log
- 27 ERR line(s)

```text
[ZeD.QA] windows reset (R)
ZEDQA wpt start
[ZeD.QA] run #20 ok=true
ZEDQA wpt scene: 0 zombies removed, save ZeD-QA
ERROR: General f:33309> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).setInfo(ISBuildIsoEntity.lua:673)
    Lua(Vanilla).create(ISBuildIsoEntity.lua:588)
    Lua(Vanilla).pcall(worldmap-annotations.lua:133)
    Lua(Vanilla).buildCrate(worldmap-annotations.lua:133)
ZEDQA wpt FAIL a crate was built beside the character
ZEDQA wpt containers 1:Ground | stops container:1@0
ZEDQA wpt FAIL the crate has a stop in the World window's container strip (stops follow the list)
ZEDQA wpt 1 after RB: World worldTabBar:tab:maps
ZEDQA wpt PASS RB lands in the World window on a lit element
ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
ZEDQA wpt 1 Right from the Character window's right edge: World worldTabBar:tab:maps
ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
ZEDQA wpt 2 strip: World worldContainerStrip:container:1
ZEDQA wpt PASS on the strip, focus is on the container on show (the ground)
ZEDQA wpt 2 Down x10: World worldCtl:worldCtl:take
ZEDQA wpt FAIL Down from the ground reaches the crate (10 presses)
ZEDQA wpt 2 after A on the crate: World worldCtl:worldCtl:take
ZEDQA wpt FAIL A on the crate puts focus on its first item, lit
ZEDQA wpt 2 Left: World worldContainerStrip:container:1
ZEDQA wpt FAIL Left from the list lands on the crate (the container on show)
ZEDQA wpt 2 Right: World worldCtl:worldCtl:take
ZEDQA wpt FAIL Right goes back to the same row
ZEDQA wpt 2 Left from a lower row: World worldContainerStrip:container:1
ZEDQA wpt FAIL Left from a lower row lands on the crate too
ZEDQA wpt FAIL and Right goes back to that row
ZEDQA wpt 3 A on the bandage: World worldCtl:worldCtl:take
ZEDQA wpt FAIL 3 A on the bandage: focus is on the card's primary action (nil)
ZEDQA wpt 3 Down in the card: World worldCtl:worldCtl:take
ZEDQA wpt FAIL Down moves to the card's next control
ZEDQA wpt 3 Up: World worldContainerStrip:container:1
ZEDQA wpt FAIL Up from inside the card is back on the primary action in one press
ZEDQA wpt 3 after B: World worldContainerStrip:container:1
ZEDQA wpt FAIL B closes the card and focus is back on the bandage row, lit
ZEDQA wpt 4 A on the nails: World worldContainerStrip:container:1
ZEDQA wpt FAIL 4 A on the nails: focus is on the card's primary action (nil)
ZEDQA wpt FAIL the nails' card offers Take as its primary action
ZEDQA wpt FAIL A on Take moved the nails into the bag (vanilla's transfer, 610 ticks)
ZEDQA wpt 4 after the take: World worldContainerStrip:container:1
ZEDQA wpt 5 no row in the World window's list: worldContainerStrip=1 worldMainInv(off)=0 worldTabContent(off)=0 worldItemCard(off)=0 worldTabBar=7 worldCtl=2; card false
ZEDQA wpt 5 before the padlock card: World worldContainerStrip:container:1
ZEDQA wpt 5 the padlock card: World worldContainerStrip:container:1
ZEDQA wpt FAIL the object card opens with focus on its main live verb (nil)
ZEDQA wpt FAIL A on it ran the verb (the padlock's code wheel shows)
ZEDQA wpt 5 after B: World worldContainerStrip:container:1
ZEDQA wpt FAIL B closes the object card and focus is back in the list, lit
ZEDQA wpt 6 Left from the World window's strip: Char charContainerStrip:container:1
ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
ZEDQA wpt 6 LB: Char charContainerStrip:container:1
    LOG  : Lua          f:34372> ZEDQA wpt PASS LB lands in the Character window on a lit element
    OG  : Lua          f:34372> [ZeD.Input] Focus: spatial right -> window World
ZEDQA wpt 6 Right: World worldContainerStrip:container:1
ZEDQA wpt FAIL Right from a row lands on the bag on show
ZEDQA wpt FAIL Left goes back to the same row
ZEDQA wpt 6 A on the nails: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
ZEDQA wpt FAIL 6 A on the nails: focus is on the card's primary action (nil)
ZEDQA wpt FAIL Down then Up in the Character window's card is back on its primary action
ZEDQA wpt 6 primary is nil; A runs it
ZEDQA wpt FAIL A on the card's primary action (Drop) moved the nails out of the bag (610 ticks)
ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (DROP)
ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
ZEDQA wpt PASS B on the Character window's card goes back to the row
ZEDQA wpt 8 no corkscrew row in the World window's list: worldContainerStrip=1 worldMainInv(off)=0 worldTabContent(off)=0 worldItemCard(off)=0 worldTabBar=7 worldCtl=2; card false
ZEDQA wpt FAIL 8 X on a row opens the context menu
ZEDQA wpt 8 after the menu's B: World worldContainerStrip:container:1
ZEDQA wpt FAIL 8 the menu closed: focus is back on the same row, lit
ZEDQA wpt 8 after hold A: World worldContainerStrip:container:1
ZEDQA wpt FAIL 8 hold A moved the hammer out of the crate
ZEDQA wpt 8 a moment later: World worldContainerStrip:container:1
ZEDQA wpt FAIL 8 after the transfer focus is on a neighbour in the same panel, lit
ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
ZEDQA wpt PASS 8 B leaves the belt in one press
ZEDQA wpt PASS 8 Right past the belt's last box leaves it
ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
ZEDQA wpt 7 tabs: 12 at small and large
ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control equippart:Right Foot and it is in view (bottom 653 of 664)
ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 638 of 664)
ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control exercise:time:dec and it is in view (bottom 508 of 664)
ZEDQA wpt PASS 7 Char health small wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 508 of 664)
ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 956 px in a 599 px view
ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control thermal:__gridscroll and it is in view (bottom 664 of 664)
ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 664 of 664)
ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control identity:__gridscroll and it is in view (bottom 664 of 664)
ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:__gridscroll is in view at the bottom (bottom 664 of 664)
ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control journal:group:6_1993 and it is in view (bottom 650 of 664)
ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 275 of 664)
ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control training:col1_Foraging and it is in view (bottom 664 of 664)
ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Foraging is in view at the bottom (bottom 648 of 664)
ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control craft:row:RemoveBattery and it is in view (bottom 228 of 664)
ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:row:RemoveBattery is in view at the bottom (bottom 228 of 664)
ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control build:section:all and it is in view (bottom 126 of 664)
ZEDQA wpt PASS 7 World build small wheel: the lowest control build:section:all is in view at the bottom (bottom 126 of 664)
    se.krka.kahlua.vm.KahluaUtil.fail(KahluaUtil.java:96)
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
    se.krka.kahlua.vm.KahluaThread.luaMainloop(KahluaThread.java:763)
    se.krka.kahlua.vm.KahluaThread.call(KahluaThread.java:162)
    se.krka.kahlua.vm.KahluaThread.pcall(KahluaThread.java:1740)
    se.krka.kahlua.vm.KahluaThread.pcallvoid(KahluaThread.java:1572)
    se.krka.kahlua.integration.LuaCaller.pcallvoid(LuaCaller.java:60)
    se.krka.kahlua.integration.LuaCaller.protectedCallVoid(LuaCaller.java:131)
    zombie.Lua.Event.trigger(Event.java:55)
    zombie.Lua.LuaEventManager.triggerEvent(LuaEventManager.java:474)
    zombie.iso.IsoCell.doBuildingInternal(IsoCell.java:3105)
    zombie.iso.IsoCell.DoBuilding(IsoCell.java:3082)
    zombie.iso.fboRenderChunk.FBORenderCell.renderInternal(FBORenderCell.java:430)
    zombie.iso.IsoCell.render(IsoCell.java:4144)
    zombie.iso.IsoWorld.renderInternal(IsoWorld.java:3092)
    zombie.iso.IsoWorld.render(IsoWorld.java:3062)
    zombie.gameStates.IngameState.renderFrameInternal(IngameState.java:1232)
    zombie.gameStates.IngameState.renderframe(IngameState.java:1210)
    zombie.gameStates.IngameState.renderInternal(IngameState.java:1342)
    zombie.gameStates.IngameState.render(IngameState.java:1322)
    zombie.gameStates.GameStateMachine.render(GameStateMachine.java:24)
    zombie.GameWindow.renderInternal(GameWindow.java:459)
    zombie.GameWindow.frameStep(GameWindow.java:812)
    zombie.GameWindow.mainThreadStep(GameWindow.java:568)
    zombie.MainThread.mainLoop(MainThread.java:69)
    java.base/java.lang.Thread.run(Unknown Source)
ERROR: General f:37334> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37335> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37335> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37336> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37336> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37337> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37337> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37338> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37338> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37339> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37339> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37340> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37340> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37341> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37341> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37342> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37342> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37343> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37343> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37344> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37344> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37345> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37345> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37346> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37346> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37347> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37347> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37348> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37348> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37349> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37349> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37350> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37350> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37351> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37351> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37352> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37352> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37353> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37353> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37354> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37354> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37355> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37355> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37356> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).beforeWorldRender(ISMoveableCursor.lua:324)
ERROR: General f:37356> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).isValid(ISMoveableCursor.lua:525)
    Lua(Vanilla).DoTileBuilding(ISBuildingObject.lua:144)
ERROR: General f:37357> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
... (2819 more lines; see console.txt)
```

### 21. zedqa_furniture.lua (`ZEDQA fu`) - FAIL, 181 s

- go 13138 at 19:22:37
- no '[ZeD.QA] run #' within 20 s, but the game was logging: not bumped again
- 777 Java exception(s) in the log
- no DONE within 180 s; the script may still be running in the game

```text
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
    Lua(Vanilla).furnitureSquare(worldmap-annotations.lua:24)
    Lua(Vanilla).tick(worldmap-annotations.lua:41)
ERROR: General f:40757> Lua((MOD:Disassemble Container With Items)).new> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in new at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Disassemble Container With Items)).new(disassemble.lua:89)
    Lua(Vanilla).getObjectList(ISMoveableCursor.lua:957)
... (4270 more lines; see console.txt)
```

### 22. zedqa_tabicons.lua (`ZEDQA ti`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 23. zedqa_tabs_lit.lua (`ZEDQA tl`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 24. zedqa_win.lua (`ZEDQA win`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 25. zedqa_rootchange.lua (`ZEDQA rc`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 26. zedqa_scalewalk.lua (`ZEDQA sw`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 27. zedqa_uiscale.lua (`ZEDQA scale`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 28. zedqa_mapshot.lua (`ZEDQA ms`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 29. zedqa_mapstyles.lua (`ZEDQA mst`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 30. zedqa_flyers.lua (`ZEDQA fl`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 31. zedqa_flyermap.lua (`ZEDQA fm`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 32. zedqa_mapnotes.lua (`ZEDQA mnote`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 33. zedqa_journal_refs.lua (`ZEDQA jr`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 34. zedqa_journal_readers.lua (`ZEDQA jrd`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 35. zedqa_reader.lua (`ZEDQA rd`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 36. zedqa_reader_refs.lua (`ZEDQA rr`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 37. zedqa_notebook.lua (`ZEDQA nb`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 38. zedqa_print_fit.lua (`ZEDQA pf`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 39. zedqa_print_typeset.lua (`ZEDQA ts`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 40. zedqa_prompts.lua (`ZEDQA pr`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 41. zedqa_fishing.lua (`ZEDQA fi`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 42. zedqa_props_plates.lua (`ZEDQA props`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 43. zedqa_belt_strap.lua (`ZEDQA belt`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 44. zedqa_straps.lua (`ZEDQA straps`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 45. zedqa_buckle.lua (`ZEDQA bk`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 46. zedqa_buckles.lua (`ZEDQA bks`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 47. zedqa_beltwatch.lua (`ZEDQA bw`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 48. zedqa_belt_hands.lua (`ZEDQA bh`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 49. zedqa_watches2.lua (`ZEDQA watches`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 50. zedqa_container_bottom.lua (`ZEDQA cb`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 51. zedqa_container_controls.lua (`ZEDQA ct`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 52. zedqa_container_controls_captures.lua (`ZEDQA cc`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 53. zedqa_button_case_game.lua (`ZEDQA bg`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 54. zedqa_wheel_sizes.lua (`ZEDQA ws`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 55. zedqa_wheels.lua (`ZEDQA wh`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 56. zedqa_dpad_wheels.lua (`ZEDQA dw`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 57. zedqa_pad_glyphs.lua (`ZEDQA pg`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 58. zedqa_quick_chords.lua (`ZEDQA qc`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 59. zedqa_put_back.lua (`ZEDQA pb`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 60. zedqa_food_verbs.lua (`ZEDQA fv`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 61. zedqa_messages.lua (`ZEDQA msg`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 62. zedqa_moodles.lua (`ZEDQA mood`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 63. zedqa_ring_squares.lua (`ZEDQA rs`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 64. zedqa_sandbox_ig.lua (`ZEDQA sbx`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 65. zedqa_twoway.lua (`ZEDQA tw`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 66. zedqa_appliances.lua (`ZEDQA ap`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 67. zedqa_seat_lightbar_vanilla.lua (`ZEDQA sl`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 68. zedqa_car_radio_build.lua (`ZEDQA rb`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 69. zedqa_car_radio_cd.lua (`ZEDQA cd`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 70. zedqa_dash_props_smoke.lua (`ZEDQA sm`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 71. zedqa_tm.lua (`ZEDQA tm`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 72. zedqa_tour3.lua (`ZEDQA t3`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 73. zedqa_dash19.lua (`ZEDQA dash`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 74. zedqa_dashpx.lua (`ZEDQA dpx`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 75. zedqa_exinfo.lua (`ZEDQA ex`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 76. zedqa_equipdrag.lua (`ZEDQA eqd`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 77. zedqa_cazio_light.lua (`ZEDQA czl`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 78. zedqa_dashnight.lua (`ZEDQA dnt`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 79. zedqa_testlang.lua (`ZEDQA tlang`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 80. zedqa_safemode.lua (`ZEDQA safe`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 81. zedqa_soak.lua (`ZEDQA soak`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at KahluaThread.flushErrorMessage > expected argument of type ItemBodyLocation, got String
    1x ERROR: General f:N> Lua((MOD:Cosplay商店(B42))).CosShopBodyLocations.lua> Exception thrown  :: java.lang.RuntimeException: expected argument of type ItemBodyLocation, got String at MethodArguments.assertValid(MethodArguments.java:128).
    6x ERROR: General f:N> Lua((MOD:Better Sorting)).BSdynamicCats> Exception thrown  :: java.lang.NullPointerException: Cannot invoke "zombie.inventory.InventoryItem.setAlcoholPower(float)" because "item" is null at Item.InstanceItem(Item.java:1849).
    4x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateWeaponWithStock"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateM4"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateM9"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreate1911"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateDEagle"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateM16"
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "SpecialLootSpawns.OnCreateAKM"
    1x ERROR: General f:N at KahluaThread.flushErrorMessage > -------------------------------------------------------------  :: attempted index: setAutoFixModOrder of non-table: null
    1x ERROR: General f:N> Lua((MOD:ZombieBuddy)).applySettings> Exception thrown  :: java.lang.RuntimeException: attempted index: setAutoFixModOrder of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    3x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
