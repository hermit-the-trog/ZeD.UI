# ZeD-UI regression - 2026-10-27 00:12 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-27 00:12:22 |
| Finished | 2026-10-27 00:36:46 (24 min 24 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/regression.txt (82 scripts) |
| Result | **36/82 pass**, 0 warn, 0 fail, 1 timeout, 45 not run |
| Go numbers | 13987 to 14026 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_notebook.lua: no DONE within 180 s; the script may still be running in the game
- quit: the game was still running after the quit (go 14024, 14025, 14026); close it by hand
- ZeD settings NOT put back (the game is still running): copy C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-10-27_0011_mods_fullscreen4k.md.modoptions.ini over C:\Users\danie\Zomboid\Lua\ModOptions.ini once it has closed

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 8 |  |  |
| 2 | suite_tabs.lua | tabs | PASS | 18 |  |  |
| 3 | suite_verbs.lua | verbs | PASS | 27 |  |  |
| 4 | suite_gamepad.lua | gp | PASS | 12 |  |  |
| 5 | suite_band.lua | band | PASS | 4 |  |  |
| 6 | suite_perf.lua | perf | PASS | 48 |  |  |
| 7 | zedqa_audit_fixes.lua | af | PASS | 5 |  | 60 expected exception(s) ignored (expect=) |
| 8 | zedqa_card_pad.lua | cp | PASS | 5 | zqa_cp_card.png |  |
| 9 | zedqa_ctxlist.lua | cl | PASS | 5 | zqa_cl_1.png, zqa_cl_2.png |  |
| 10 | zedqa_onepath.lua | op | PASS | 27 | zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png |  |
| 11 | zedqa_grid.lua | grid | PASS | 7 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 12 | zedqa_sort_groups.lua | sg | PASS | 46 | zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png |  |
| 13 | zedqa_doll.lua | doll | PASS | 9 | zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png |  |
| 14 | zedqa_large.lua | lg | PASS | 9 | zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png |  |
| 15 | zedqa_curtain.lua | cu | PASS | 237 | zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png |  |
| 16 | zedqa_curtain2.lua | cv | PASS | 15 | zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png |  |
| 17 | zedqa_navevents.lua | ev | PASS | 8 |  |  |
| 18 | zedqa_navmap.lua | nav | PASS | 16 |  |  |
| 19 | zedqa_loot_tabs.lua | lt | PASS | 1 |  |  |
| 20 | zedqa_world_pad_take.lua | wpt | PASS | 97 |  |  |
| 21 | zedqa_furniture.lua | fu | PASS | 3 |  |  |
| 22 | zedqa_tabicons.lua | ti | PASS | 3 | zqa_tabicons.png |  |
| 23 | zedqa_tabs_lit.lua | tl | PASS | 7 | zqa_tabs_1.png, zqa_tabs_2.png, zqa_tabs_3.png |  |
| 24 | zedqa_win.lua | win | PASS | 5 | zedqa_win_200.png, zedqa_win_100.png |  |
| 25 | zedqa_rootchange.lua | rc | PASS | 6 | zedqa_rc_100.png, zedqa_rc_200.png |  |
| 26 | zedqa_scalewalk.lua | sw | PASS | 55 | zedqa_sw_200_char_loot.png, zedqa_sw_200_char_equip.png, zedqa_sw_200_char_health.png, zedqa_sw_200_char_thermal.png, zedqa_sw_200_char_identity.png, zedqa_sw_200_char_journal.png, zedqa_sw_200_char_skills.png, zedqa_sw_200_world_loot.png, zedqa_sw_200_world_craft.png, zedqa_sw_200_world_build.png, zedqa_sw_200_world_furniture.png, zedqa_sw_200_world_maps.png, zedqa_sw_200_world_forage.png, zedqa_sw_200_world_animals.png, zedqa_sw_100_char_loot.png, zedqa_sw_100_char_equip.png, zedqa_sw_100_char_health.png, zedqa_sw_100_char_thermal.png, zedqa_sw_100_char_identity.png, zedqa_sw_100_char_journal.png, zedqa_sw_100_char_skills.png, zedqa_sw_100_world_loot.png, zedqa_sw_100_world_craft.png, zedqa_sw_100_world_build.png, zedqa_sw_100_world_furniture.png, zedqa_sw_100_world_maps.png, zedqa_sw_100_world_forage.png, zedqa_sw_100_world_animals.png |  |
| 27 | zedqa_uiscale.lua | scale | PASS | 14 | zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png |  |
| 28 | zedqa_mapshot.lua | ms | PASS | 5 | zqa_ms_1.png, zqa_ms_2.png |  |
| 29 | zedqa_mapstyles.lua | mst | PASS | 14 | zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png |  |
| 30 | zedqa_flyers.lua | fl | PASS | 7 | zqa_fl_1.png, zqa_fl_2.png |  |
| 31 | zedqa_flyermap.lua | fm | PASS | 12 | zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png |  |
| 32 | zedqa_mapnotes.lua | mnote | PASS | 9 | zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png |  |
| 33 | zedqa_journal_refs.lua | jr | PASS | 5 | zqa_jr_01_diary.png, zqa_jr_02_flyers.png |  |
| 34 | zedqa_journal_readers.lua | jrd | PASS | 22 | zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png |  |
| 35 | zedqa_reader.lua | rd | PASS | 11 | zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png |  |
| 36 | zedqa_reader_refs.lua | rr | PASS | 14 | zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png |  |
| 37 | zedqa_notebook.lua | nb | **TIMEOUT** | 181 |  | no DONE within 180 s; the script may still be running in the game |
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
| 76 | zedqa_charinfo.lua | ci | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 77 | zedqa_equipdrag.lua | eqd | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 78 | zedqa_cazio_light.lua | czl | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 79 | zedqa_dashnight.lua | dnt | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 80 | zedqa_testlang.lua | tlang | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 81 | zedqa_safemode.lua | safe | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |
| 82 | zedqa_soak.lua | soak | SKIP |  |  | not run: no DONE within 180 s; the script may still be running in the game |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 8 s

- go 13987 at 00:14:34

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. suite_tabs.lua (`ZEDQA tabs`) - PASS, 18 s

- go 13988 at 00:14:48

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
:	ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
:	ZEDQA tabs armed
:	[ZeD.QA] run #2 ok=true
:	ZEDQA char tab=loot active=loot w=777 focusables=0 {}
:	ZEDQA char tab=equip active=equip w=1617 focusables=31 {equipgroup=5 equippart=17 equipslot=7 equipview=2}
:	ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
:	ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
:	ZEDQA char tab=identity active=identity w=1617 focusables=55 {hb=26 identity=29}
:	ZEDQA char tab=journal active=journal w=1617 focusables=8 {journal=4 jsub=4}
:	ZEDQA char tab=skills active=skills w=1617 focusables=62 {skill=36 skills=1 training=25}
:	ZEDQA world tab=loot active=loot w=777 focusables=0 {}
:	ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
:	ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
:	ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
:	ZEDQA world tab=maps active=maps w=1682 focusables=19 {map=19}
:	ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
:	ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
:	ZEDQA tabs done
```

### 3. suite_verbs.lua (`ZEDQA verbs`) - PASS, 27 s

- go 13989 at 00:15:12

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA verbs armed
:	[ZeD.QA] run #3 ok=true
:	ZEDQA worn=Belt ctx=equipped
:	ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
:	ZEDQA after UNEQUIP pEq=false ctx=inventory (expect inventory)
:	ZEDQA fire EQUIP ok=true err=nil qhead=ISWearClothing
:	ZEDQA after EQUIP pEq=true ctx=equipped (expect equipped)
:	ZEDQA fire READ ok=true err=nil qhead=ISReadABook
:	ZEDQA after READ qhead=ISReadABook (expect ISReadABook)
:	ZEDQA fire EQUIP ok=true err=nil qhead=ISEquipWeaponAction
:	ZEDQA after EQUIP bat primary=Baseball Bat ctx=equipped (expect equipped)
:	ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
:	ZEDQA after UNEQUIP bat primary=nil (expect nil)
:	ZEDQA fire EAT ok=true err=nil qhead=ISEatFoodAction
:	ZEDQA after EAT qhead=ISEatFoodAction (expect ISEatFoodAction)
:	ZEDQA fire DROP ok=true err=nil qhead=ISInventoryTransferAction
:	ZEDQA after DROP cont=floor ctx=ground (expect floor/ground)
:	ZEDQA fire TAKE ok=true err=nil qhead=ISInventoryTransferAction
:	ZEDQA after TAKE inInv=true ctx=inventory (expect inventory)
:	ZEDQA verbs done
```

### 4. suite_gamepad.lua (`ZEDQA gp`) - PASS, 12 s

- go 13990 at 00:15:45

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA gp armed
:	[ZeD.QA] run #4 ok=true
:	ZEDQA gp claim zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp down zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp right zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp left zone=charMainInv el=invrow:2 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp loot charTabContent elements=0 (expect 0)
:	ZEDQA gp right after journal to loot (expect container strip, never jsub) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp after row2 onActivate (expect card open) zone=charContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp after row3 onActivate (expect live swap) zone=charItemCard el=hverb_1 tab=loot drawer=true item=Apple ctx=false
:	ZEDQA gp after row3 again (expect closed) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp after row2 onContextMenu (expect ctx=true) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=true
:	ZEDQA gp after ctx B (expect ctx=false) zone=charMainInv el=invrow:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp world claim zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp world right zone=worldCtl el=worldCtl:take tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp world craft down zone=worldCtl el=worldCtl:take tab=craft drawer=true item=nil ctx=false
:	ZEDQA gp world loot left (stale check) zone=worldContainerStrip el=container:1 tab=loot drawer=false item=nil ctx=false
:	ZEDQA gp done
```

### 5. suite_band.lua (`ZEDQA band`) - PASS, 4 s

- go 13991 at 00:16:03

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA band armed
:	[ZeD.QA] run #5 ok=true
:	ZEDQA band reading active=true kind=reading mode=nil label=READING pct=0.042567428201436996 time=nil (expect active reading)
:	ZEDQA band after cancel active=false kind=nil mode=nil label=nil pct=nil time=nil qlen=0 (expect inactive, 0)
:	ZEDQA band: no real stove within 20 tiles; cooking skipped
:	ZEDQA band done
```

### 6. suite_perf.lua (`ZEDQA perf`) - PASS, 48 s

- go 13992 at 00:16:13

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #6 ok=true
:	ZEDQA perf char loot avg=15.56ms/tick max=41ms
:	ZEDQA perf char equip avg=19.13ms/tick max=49ms
:	ZEDQA perf char health avg=18.75ms/tick max=62ms
:	ZEDQA perf char thermal avg=18.91ms/tick max=45ms
:	ZEDQA perf char identity avg=20.72ms/tick max=59ms
:	ZEDQA perf char journal avg=16.69ms/tick max=42ms
:	ZEDQA perf char skills avg=20.07ms/tick max=46ms
:	ZEDQA perf world craft avg=16.50ms/tick max=53ms
:	ZEDQA perf world build avg=15.82ms/tick max=45ms
:	ZEDQA perf world maps avg=16.44ms/tick max=42ms
:	ZEDQA perf world forage avg=17.19ms/tick max=42ms
:	ZEDQA perf world animals avg=14.51ms/tick max=35ms
:	ZEDQA perf world loot avg=14.89ms/tick max=27ms
:	ZEDQA perf world craft build: 10 elements, 0.00 ms per build
:	ZEDQA perf done
```

### 7. zedqa_audit_fixes.lua (`ZEDQA af`) - PASS, 5 s

- go 13993 at 00:17:07
- 60 expected exception(s) ignored (expect=)

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA af start
:	[ZeD.QA] run #7 ok=true
ERROR: General f:8476> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8477> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8478> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8479> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8480> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8481> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8482> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8483> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8484> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8485> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8486> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8487> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8488> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8489> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8490> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8491> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8492> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8493> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8494> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8495> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8496> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8497> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8498> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8499> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8500> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8501> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8502> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8503> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8504> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8505> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8506> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8507> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8508> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8509> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8510> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8511> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8512> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8513> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8514> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8515> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8516> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8517> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8518> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8519> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8520> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8521> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8522> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8523> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8524> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8525> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8526> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8527> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8528> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8529> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8530> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8531> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:8532> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
... (31 more lines; see console.txt)
```

### 8. zedqa_card_pad.lua (`ZEDQA cp`) - PASS, 5 s

- go 13994 at 00:17:18
- screenshots: zqa_cp_card.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cp start
:	[ZeD.QA] run #8 ok=true
:	ZEDQA cp selected the apple row 16
:	ZEDQA cp card open true | card buttons 7 {hverb_1,hverb_2,name_row,toggle_fav,toggle_protect,toggle_unwanted,verb_repair}
:	ZEDQA cp fav chip rect on the card (mouse): true
:	ZEDQA cp before left: zone=charItemCard el=hverb_1
:	ZEDQA cp after left (expect charItemCard): zone=charTabBar el=tab:loot
:	ZEDQA cp right 1: zone=charItemCard el=hverb_1
:	ZEDQA cp right 2: zone=charItemCard el=hverb_2
:	ZEDQA cp left: zone=charItemCard el=hverb_1
:	ZEDQA cp after B: card item nil (expect nil)
:	ZEDQA cp health: inv then left (expect charTabContent): zone=charTabContent el=health:__disclosure
:	ZEDQA cp health: right: zone=charMainInv el=invrow:1
:	ZEDQA cp DONE
```

### 9. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 5 s

- go 13995 at 00:17:29
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cl start
:	[ZeD.QA] run #9 ok=true
:	ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Adjust attachment position [DEV: hors slot PAR], Sandbox Control: delete item, Move to, |, Set to be Unusable in Recipes, ContextMenu_WhatCanICraft, |, Hide Equipped Items, |, Drop, |, Inspect item, |, Rename, Rename Stack, Rename
:	ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
:	ZEDQA cl down: sub sel 2
:	ZEDQA cl B: levels 1
:	ZEDQA cl B again: open false
:	ZEDQA cl strip back: class ZeD_ContextMenu
:	ZEDQA cl DONE
```

### 10. zedqa_onepath.lua (`ZEDQA op`) - PASS, 27 s

- go 13996 at 00:17:41
- screenshots: zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA op start
:	[ZeD.QA] run #10 ok=true
:	ZEDQA op crate ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@29a613ba] type crate
:	ZEDQA op world select crate true
:	ZEDQA op apple menu: Eat, |, Place Item, Favorite, Adjust attachment position [DEV: hors slot PAR], Sandbox Control: delete item, Move to, |, Set to be Unusable in Recipes, ContextMenu_WhatCanICraft, |, Hide Equipped Items, |, Drop, |, Inspect item, |, Rename, Rename Stack, Rename
:	ZEDQA op move to: Crate, Floor
:	ZEDQA op picked Crate
:	ZEDQA op apple now in crate
:	ZEDQA op hammer menu: Rin, Attach, Claw Hammer, Place Item, Favorite, Adjust attachment position [DEV: hors slot PAR], Sandbox Control: delete item, Move to, |, Craft, Set to be Unusable in Recipes, Show Build Recipes Used In, ContextMenu_WhatCanICraft, |, Equip Primary, Equip Secondary, Hide Equipped Items, |, Drop, |, Inspect item, Inspect weapon, |, Rename, Rename
:	ZEDQA op prompt true entry Claw Hammer
:	ZEDQA op hammer name: Old Faithful custom true
:	ZEDQA op card els: hverb_1, hverb_2, name_row, toggle_fav, toggle_protect, toggle_unwanted, verb_repair
:	ZEDQA op dbl: first false second true
:	ZEDQA op primary: true
:	ZEDQA op crate menu: Bandit Creator, Cheat Menu: Reloaded, |, Rin: Loot this, Rin, Civil Defense Sirens, [DGB] Bandit Map, [DGB] Remove All Bandits, [DGB] Show Brain, Search in tree, Gardening, Area Tasks, Sit on ground, Walk to, More Builds, Ban Music List, Sandbox Control, Debug Minigames, Reputation, Quest journal, Survivors, Roaming Survivors, Companion Dogs (debug), |, Disassemble, |, Take All, |, Spawn Bandit Clan
:	ZEDQA op take all pressed
:	ZEDQA op crate left: 0 apple home true
:	ZEDQA op bottle verbs: Drink, More
:	ZEDQA op knife maint: repair, sharpen sharp 0.4000000059604645
:	ZEDQA op nocraft on true off false
:	ZEDQA op DONE
```

### 11. zedqa_grid.lua (`ZEDQA grid`) - PASS, 7 s

- go 13997 at 00:18:13
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA grid start
:	[ZeD.QA] run #11 ok=true
:	ZEDQA grid grid on: cell 91 | cells placed 14 | toggle rects 2
:	ZEDQA grid first target: invrow:1 at 18,107 size 91x91
:	ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Angel Cross's Key Ring
:	ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Apple (Fresh)
:	ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:17 item=Fanny Pack
:	ZEDQA grid up: zone=charMainInv el=invrow:2 item=Apple (Fresh)
:	ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
:	ZEDQA grid card open true item Angel Cross's Key Ring
:	ZEDQA grid after A on List: grid false cell nil
:	ZEDQA grid DONE
```

### 12. zedqa_sort_groups.lua (`ZEDQA sg`) - PASS, 46 s

- go 13998 at 00:18:26
- screenshots: zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA sg start
:	[ZeD.QA] run #12 ok=true
:	ZEDQA sg no pickup in the loaded cell; spawned one beside the character: true
:	ZEDQA sg pack worn at base:back: true
:	ZEDQA sg given: bag 23, pack 8, bed 19, floor 11
:	ZEDQA sg floor container things 11 | char window true world window true
:	ZEDQA sg columns at start: char 0 world 0
:	ZEDQA sg mode single:
:	ZEDQA sg single list cat char: columns 1 rows 31 headers 6 order ok pad 31 (charMainInv=31) grid false sort cat/true
:	ZEDQA sg single list cat world: columns 1 rows 9 headers 6 order ok pad 9 (worldMainInv=9) grid false sort cat/true
:	ZEDQA sg single list name char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/true
:	ZEDQA sg single list name world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort name/true
:	ZEDQA sg single list cond char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort cond/true
:	ZEDQA sg single list cond world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort cond/true
:	ZEDQA sg single list wt char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort wt/true
:	ZEDQA sg single list wt world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort wt/true
:	ZEDQA sg single list name rev char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/false
:	ZEDQA sg single list name rev world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort name/false
:	ZEDQA sg fold char: Accessory folded, rows 28 of 31, its header true
:	ZEDQA sg fold world: FirstAid folded, rows 8 of 9, its header true
:	ZEDQA sg fold char on Name: rows 31 headers 0
:	ZEDQA sg fold world on Name: rows 9 headers 0
:	ZEDQA sg fold char back on Category: still folded true rows 28
:	ZEDQA sg fold world back on Category: still folded true rows 8
:	ZEDQA sg stack char: Base.Apple x12 open, rows 42 of 31 (+11 expected), children follow true, headers 0
:	ZEDQA sg stack world: Base.Apple x2 open, rows 10 of 9 (+1 expected), children follow true, headers 0
:	ZEDQA sg single grid cat char: columns 1 rows 31 headers 5 order ok pad 31 (charMainInv=31) grid true sort cat/true
:	ZEDQA sg single grid cat world: columns 1 rows 9 headers 5 order ok pad 9 (worldMainInv=9) grid true sort cat/true
:	ZEDQA sg single grid name char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort name/true
:	ZEDQA sg single grid name world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort name/true
:	ZEDQA sg single grid cond char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort cond/true
:	ZEDQA sg single grid cond world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort cond/true
:	ZEDQA sg single grid wt char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort wt/true
:	ZEDQA sg single grid wt world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort wt/true
:	ZEDQA sg single grid name rev char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid true sort name/false
:	ZEDQA sg single grid name rev world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid true sort name/false
:	ZEDQA sg mode multi: char:true world:true
:	ZEDQA sg multi list cat char: columns 2 rows 8+31 headers 12 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cat/true
:	ZEDQA sg multi list cat world: columns 2 rows 15+9 headers 11 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort cat/true
:	ZEDQA sg multi list name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/true
:	ZEDQA sg multi list name world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort name/true
:	ZEDQA sg multi list cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cond/true
:	ZEDQA sg multi list cond world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort cond/true
:	ZEDQA sg multi list wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort wt/true
:	ZEDQA sg multi list wt world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort wt/true
:	ZEDQA sg multi list name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/false
:	ZEDQA sg multi list name rev world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid false sort name/false
:	ZEDQA sg multi grid cat char: columns 2 rows 8+31 headers 10 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cat/true
:	ZEDQA sg multi grid cat world: columns 2 rows 15+9 headers 10 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort cat/true
:	ZEDQA sg multi grid name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/true
:	ZEDQA sg multi grid name world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort name/true
:	ZEDQA sg multi grid cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cond/true
:	ZEDQA sg multi grid cond world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort cond/true
:	ZEDQA sg multi grid wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort wt/true
:	ZEDQA sg multi grid wt world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort wt/true
:	ZEDQA sg multi grid name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/false
:	ZEDQA sg multi grid name rev world: columns 2 rows 15+9 headers 0 order ok pad 24 (worldMC1=15,worldMainInv=9) grid true sort name/false
:	ZEDQA sg columns off: char:true world:true
:	ZEDQA sg restored: bag things 58 (were 58), bed 3, world things on the square 0, floor container 0
:	ZEDQA sg all checks held; DONE
```

### 13. zedqa_doll.lua (`ZEDQA doll`) - PASS, 9 s

- go 13999 at 00:19:18
- screenshots: zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA doll start
:	[ZeD.QA] run #13 ok=true
:	ZEDQA doll doll shown true | slots 6 {doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet} | belt empties 7 | photo 263,74 290x643 | lines 11 | model visible true | layer visible true
:	ZEDQA doll pad targets: equipslot:__disclosure,equipview:list,equipview:doll,equipslot:doll:torso,equipslot:doll:outer,equipslot:doll:hands,equipslot:doll:belt,equipslot:doll:legs,equipslot:doll:feet,equipbelt:1,equipbelt:2,equipbelt:3,equipbelt:4,equipbelt:5,equipbelt:6,equipbelt:7,equipslot:doll:head,equipslot:doll:eyes,equipslot:doll:neck,equipslot:doll:back,equipslot:doll:arms,equipslot:doll:main,equipslot:doll:off
:	ZEDQA doll focus torso: zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
:	ZEDQA doll card targets: equipcard:hverb_1,equipcard:hverb_2,equipcard:hverb_3,equipcard:name_row,equipcard:toggle_fav,equipcard:toggle_protect,equipcard:toggle_unwanted,equipcard:verb_repair_all,equipcard:verb_pad_all,equipcard:back,equipcard:__layer_1,equipcard:__layer_-1
:	ZEDQA doll card open: zone=charTabContent el=equipcard:hverb_1 sel=doll:torso layer=1
:	ZEDQA doll focus Inner: zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=1
:	ZEDQA doll after Inner (expect layer 2): zone=charTabContent el=equipcard:__layer_1 sel=doll:torso layer=2
:	ZEDQA doll after B (expect sel=nil, el=equipslot:doll:torso): zone=charTabContent el=equipslot:doll:torso sel=nil layer=1
:	ZEDQA doll head then down: zone=charTabContent el=equipslot:doll:eyes sel=nil layer=1
:	ZEDQA doll then right (expect back): zone=charTabContent el=equipslot:doll:back sel=nil layer=1
:	ZEDQA doll then down (expect belt): zone=charTabContent el=equipslot:doll:belt sel=nil layer=1
:	ZEDQA doll then left (expect neck): zone=charTabContent el=equipslot:doll:neck sel=nil layer=1
:	ZEDQA doll then left (leaves the doll): zone=charTabBar el=tab:equip sel=nil layer=1
:	ZEDQA doll view restored to list | DONE
```

### 14. zedqa_large.lua (`ZEDQA lg`) - PASS, 9 s

- go 14000 at 00:19:34
- screenshots: zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA lg start
:	[ZeD.QA] run #14 ok=true
:	ZEDQA lg small: rowH 53 buttonH 46 titleBarH 46 | cat 151 wt 81 | equip slot col 140
:	ZEDQA lg large: rowH 60 buttonH 53 titleBarH 53 | cat 176 wt 93 | equip slot col 163
:	ZEDQA lg size back to small | DONE
```

### 15. zedqa_curtain.lua (`ZEDQA cu`) - PASS, 237 s

- go 14001 at 00:19:49
- screenshots: zqa_cu_0.png, zqa_cu_1.png, zqa_cu_2.png, zqa_cu_3.png, zqa_cu_4.png, zqa_cu_5.png, zqa_cu_6.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cu start
:	[ZeD.QA] run #15 ok=true
:	ZEDQA cu loaded: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
:	ZEDQA cu scale 1.75 root 1.75 screen 3840x2160
:	ZEDQA cu reset: ZeD_Window.resetLayout
:	ZEDQA cu reset: Character 1134,0 777x735 rolled nil (saved -) | World 1929,0 777x735 rolled nil (saved -)
:	ZEDQA cu before: x 1929 w 1682 title Ground 0 button 176.6640625,5 35
:	ZEDQA cu rolled true: x 2643 w 968 (sum 3611 was 3611) rod 1929,0 714x46 content false title Maps
:	ZEDQA cu pad stops: worldContainerStrip:curtain:unroll
:	ZEDQA cu A on the tab
:	ZEDQA cu unrolled true: x 1929 w 1682 content true rod false
:	ZEDQA cu ok first roll World 1929,0 1682x735
:	ZEDQA cu rolled again true
:	ZEDQA cu tab closed: rolled false x 1929 w 777 content true drawer false
:	ZEDQA cu ok tab closed while rolled World 1929,0 777x735
:	ZEDQA cu World before: 1929,0 1682x735 (other 1134,0 777x735) drawer true tab tab maps
:	ZEDQA cu cycle1 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1682x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle1 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 968x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle1 World rollW 714
:	ZEDQA cu ok cycle1 rolled World rod flush at 1929,0 714x46
:	ZEDQA cu ok cycle1 rolled World 2643,0 968x735
:	ZEDQA cu ok cycle1 while rolled: other Character 1134,0 777x735
:	ZEDQA cu cycle1 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 968x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle1 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1682x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok cycle1 World 1929,0 1682x735
:	ZEDQA cu ok cycle1 other (Character) 1134,0 777x735
:	ZEDQA cu ok cycle1 World saved 1102.286,0.000 444.000x420.000
:	ZEDQA cu cycle2 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1682x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle2 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 968x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle2 World rollW 714
:	ZEDQA cu ok cycle2 rolled World rod flush at 1929,0 714x46
:	ZEDQA cu ok cycle2 rolled World 2643,0 968x735
:	ZEDQA cu ok cycle2 while rolled: other Character 1134,0 777x735
:	ZEDQA cu cycle2 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 968x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle2 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1682x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok cycle2 World 1929,0 1682x735
:	ZEDQA cu ok cycle2 other (Character) 1134,0 777x735
:	ZEDQA cu ok cycle2 World saved 1102.286,0.000 444.000x420.000
:	ZEDQA cu moved by rod World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,0 1682x735 rolled false (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by rod World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,0 968x735 rolled true (saved 1102.286,0.000 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by rod World rollW 714
:	ZEDQA cu ok moved by rod rolled World rod flush at 1929,0 714x46
:	ZEDQA cu ok moved by rod rolled World 2643,0 968x735
:	ZEDQA cu ok moved by rod while rolled: other Character 1134,0 777x735
:	ZEDQA cu moved by rod World moved by 200,200 (rod) to 2843,200 968x735
:	ZEDQA cu ok moved by rod moved World rod flush at 2129,200 714x46
:	ZEDQA cu moved by rod World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 968x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by rod World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1682x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok moved by rod World 2129,200 1682x735
:	ZEDQA cu ok moved by rod other (Character) 1134,0 777x735
:	ZEDQA cu ok moved by rod World saved 1216.571,114.286 444.000x420.000
:	ZEDQA cu moved by title World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2129,200 1682x735 rolled false (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by title World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2843,200 968x735 rolled true (saved 1216.571,114.286 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by title World rollW 714
:	ZEDQA cu ok moved by title rolled World rod flush at 2129,200 714x46
:	ZEDQA cu ok moved by title rolled World 2843,200 968x735
:	ZEDQA cu ok moved by title while rolled: other Character 1134,0 777x735
:	ZEDQA cu moved by title World moved by -200,200 (title) to 2643,400 968x735
:	ZEDQA cu ok moved by title moved World rod flush at 1929,400 714x46
:	ZEDQA cu moved by title World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 968x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by title World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok moved by title World 1929,400 1682x735
:	ZEDQA cu ok moved by title other (Character) 1134,0 777x735
:	ZEDQA cu ok moved by title World saved 1102.286,228.571 444.000x420.000
:	ZEDQA cu cycle5 World before roll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle5 World rolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 968x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle5 World rollW 714
:	ZEDQA cu ok cycle5 rolled World rod flush at 1929,400 714x46
:	ZEDQA cu ok cycle5 rolled World 2643,400 968x735
:	ZEDQA cu ok cycle5 while rolled: other Character 1134,0 777x735
:	ZEDQA cu cycle5 World rolled, before unroll: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 2643,400 968x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle5 World unrolled: Character 1134,0 777x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab loot drawer false) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok cycle5 World 1929,400 1682x735
:	ZEDQA cu ok cycle5 other (Character) 1134,0 777x735
:	ZEDQA cu ok cycle5 World saved 1102.286,228.571 444.000x420.000
:	ZEDQA cu character health tab true
:	ZEDQA cu Character before: 294,0 1617x735 (other 1929,400 1682x735) drawer true tab tab health
:	ZEDQA cu cycle1 Character before roll: Character 294,0 1617x735 rolled nil (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle1 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle1 Character rollW 714
:	ZEDQA cu ok cycle1 rolled Character rod flush at 1197,0 714x46
:	ZEDQA cu ok cycle1 rolled Character 294,0 903x735
:	ZEDQA cu ok cycle1 while rolled: other World 1929,400 1682x735
:	ZEDQA cu cycle1 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle1 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok cycle1 Character 294,0 1617x735
:	ZEDQA cu ok cycle1 other (World) 1929,400 1682x735
:	ZEDQA cu ok cycle1 Character saved 648.000,0.000 444.000x420.000
:	ZEDQA cu cycle2 Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle2 Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle2 Character rollW 714
:	ZEDQA cu ok cycle2 rolled Character rod flush at 1197,0 714x46
:	ZEDQA cu ok cycle2 rolled Character 294,0 903x735
:	ZEDQA cu ok cycle2 while rolled: other World 1929,400 1682x735
:	ZEDQA cu cycle2 Character rolled, before unroll: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle2 Character unrolled: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok cycle2 Character 294,0 1617x735
:	ZEDQA cu ok cycle2 other (World) 1929,400 1682x735
:	ZEDQA cu ok cycle2 Character saved 648.000,0.000 444.000x420.000
:	ZEDQA cu moved by rod Character before roll: Character 294,0 1617x735 rolled false (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by rod Character rolled: Character 294,0 903x735 rolled true (saved 648.000,0.000 444.000x420.000 anchor 1092.000 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by rod Character rollW 714
:	ZEDQA cu ok moved by rod rolled Character rod flush at 1197,0 714x46
:	ZEDQA cu ok moved by rod rolled Character 294,0 903x735
:	ZEDQA cu ok moved by rod while rolled: other World 1929,400 1682x735
:	ZEDQA cu moved by rod Character moved by 200,200 (rod) to 494,200 903x735
:	ZEDQA cu ok moved by rod moved Character rod flush at 1397,200 714x46
:	ZEDQA cu moved by rod Character rolled, before unroll: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by rod Character unrolled: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok moved by rod Character 494,200 1617x735
:	ZEDQA cu ok moved by rod other (World) 1929,400 1682x735
:	ZEDQA cu ok moved by rod Character saved 762.286,114.286 444.000x420.000
:	ZEDQA cu moved by title Character before roll: Character 494,200 1617x735 rolled false (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by title Character rolled: Character 494,200 903x735 rolled true (saved 762.286,114.286 444.000x420.000 anchor 1206.286 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by title Character rollW 714
:	ZEDQA cu ok moved by title rolled Character rod flush at 1397,200 714x46
:	ZEDQA cu ok moved by title rolled Character 494,200 903x735
:	ZEDQA cu ok moved by title while rolled: other World 1929,400 1682x735
:	ZEDQA cu moved by title Character moved by 200,200 (title) to 694,400 903x735
:	ZEDQA cu ok moved by title moved Character rod flush at 1597,400 714x46
:	ZEDQA cu moved by title Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu moved by title Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok moved by title Character 694,400 1617x735
:	ZEDQA cu ok moved by title other (World) 1929,400 1682x735
:	ZEDQA cu ok moved by title Character saved 876.571,228.571 444.000x420.000
:	ZEDQA cu cycle5 Character before roll: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle5 Character rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle5 Character rollW 714
:	ZEDQA cu ok cycle5 rolled Character rod flush at 1597,400 714x46
:	ZEDQA cu ok cycle5 rolled Character 694,400 903x735
:	ZEDQA cu ok cycle5 while rolled: other World 1929,400 1682x735
:	ZEDQA cu cycle5 Character rolled, before unroll: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu cycle5 Character unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok cycle5 Character 694,400 1617x735
:	ZEDQA cu ok cycle5 other (World) 1929,400 1682x735
:	ZEDQA cu ok cycle5 Character saved 876.571,228.571 444.000x420.000
:	ZEDQA cu closed rolled (inventory key) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (inventory key) reference back on its tab World 1929,400 1682x735
:	ZEDQA cu closed rolled (inventory key) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok closed rolled (inventory key) World rolled (rods in UI 1)
:	ZEDQA cu ok closed rolled (inventory key) World window closed
:	ZEDQA cu ok closed rolled (inventory key) World rod gone (rod visible false, rods in UI 0)
:	ZEDQA cu closed rolled (inventory key) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (inventory key) World reopened unrolled (rolled nil, rods in UI 0)
:	ZEDQA cu ok closed rolled (inventory key) reopened as unrolled World 1929,400 777x735
:	ZEDQA cu ok closed rolled (inventory key) reopened: other Character 694,400 1617x735
:	ZEDQA cu closed rolled (rod close box) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (rod close box) reference back on its tab World 1929,400 1682x735
:	ZEDQA cu closed rolled (rod close box) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok closed rolled (rod close box) World rolled (rods in UI 1)
:	ZEDQA cu ok closed rolled (rod close box) World window closed
:	ZEDQA cu ok closed rolled (rod close box) World rod gone (rod visible false, rods in UI 0)
:	ZEDQA cu closed rolled (rod close box) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (rod close box) World reopened unrolled (rolled nil, rods in UI 0)
:	ZEDQA cu ok closed rolled (rod close box) reopened as unrolled World 1929,400 777x735
:	ZEDQA cu ok closed rolled (rod close box) reopened: other Character 694,400 1617x735
:	ZEDQA cu closed rolled (controller Y hold) World reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab World 1929,400 1682x735
:	ZEDQA cu closed rolled (controller Y hold) World before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu ok closed rolled (controller Y hold) World rolled (rods in UI 1)
:	ZEDQA cu ok closed rolled (controller Y hold) World window closed
:	ZEDQA cu ok closed rolled (controller Y hold) World rod gone (rod visible false, rods in UI 0)
:	ZEDQA cu closed rolled (controller Y hold) World reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (controller Y hold) World reopened unrolled (rolled nil, rods in UI 0)
:	ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled World 1929,400 777x735
:	ZEDQA cu ok closed rolled (controller Y hold) reopened: other Character 694,400 1617x735
:	ZEDQA cu closed rolled (inventory key) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (inventory key) reference back on its tab Character 694,400 1617x735
:	ZEDQA cu closed rolled (inventory key) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (inventory key) Character rolled (rods in UI 1)
:	ZEDQA cu ok closed rolled (inventory key) Character window closed
:	ZEDQA cu ok closed rolled (inventory key) Character rod gone (rod visible false, rods in UI 0)
:	ZEDQA cu closed rolled (inventory key) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (inventory key) Character reopened unrolled (rolled nil, rods in UI 0)
:	ZEDQA cu ok closed rolled (inventory key) reopened as unrolled Character 694,400 1617x735
:	ZEDQA cu ok closed rolled (inventory key) reopened: other World 1929,400 777x735
:	ZEDQA cu closed rolled (close box) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (close box) reference back on its tab Character 694,400 1617x735
:	ZEDQA cu closed rolled (close box) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (close box) Character rolled (rods in UI 1)
:	ZEDQA cu ok closed rolled (close box) Character window closed
:	ZEDQA cu ok closed rolled (close box) Character rod gone (rod visible false, rods in UI 0)
:	ZEDQA cu closed rolled (close box) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (close box) Character reopened unrolled (rolled nil, rods in UI 0)
:	ZEDQA cu ok closed rolled (close box) reopened as unrolled Character 694,400 1617x735
:	ZEDQA cu ok closed rolled (close box) reopened: other World 1929,400 777x735
:	ZEDQA cu closed rolled (controller Y hold) Character reference, closed and reopened unrolled: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (controller Y hold) reference back on its tab Character 694,400 1617x735
:	ZEDQA cu closed rolled (controller Y hold) Character before roll: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (controller Y hold) Character rolled (rods in UI 1)
:	ZEDQA cu ok closed rolled (controller Y hold) Character window closed
:	ZEDQA cu ok closed rolled (controller Y hold) Character rod gone (rod visible false, rods in UI 0)
:	ZEDQA cu closed rolled (controller Y hold) Character reopened: Character 694,400 1617x735 rolled nil (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 777x735 rolled nil (saved 1102.286,228.571 444.000x420.000 tab loot drawer false)
:	ZEDQA cu ok closed rolled (controller Y hold) Character reopened unrolled (rolled nil, rods in UI 0)
:	ZEDQA cu ok closed rolled (controller Y hold) reopened as unrolled Character 694,400 1617x735
:	ZEDQA cu ok closed rolled (controller Y hold) reopened: other World 1929,400 777x735
:	ZEDQA cu World tabs: on maps 1929,400 1682x735 (other 694,400 1617x735)
:	ZEDQA cu tab forage World: its own width, 1929,400 1617x735 (maps 1929,400 1682x735)
:	ZEDQA cu ok tab forage reference, back on maps World 1929,400 1682x735
:	ZEDQA cu ok tab forage World rolled before the press
:	ZEDQA cu ok tab forage World still rolled on the tab (tab forage)
:	ZEDQA cu ok tab forage rolled World 2643,400 903x735
:	ZEDQA cu ok tab forage World unrolled (rods in UI 0)
:	ZEDQA cu ok tab forage unrolled World 1929,400 1617x735
:	ZEDQA cu ok tab forage unrolled: other Character 694,400 1617x735
:	ZEDQA cu ok tab forage back on maps World 1929,400 1682x735
:	ZEDQA cu tab craft World: its own width, 1929,400 1617x735 (maps 1929,400 1682x735)
:	ZEDQA cu ok tab craft reference, back on maps World 1929,400 1682x735
:	ZEDQA cu ok tab craft World rolled before the press
:	ZEDQA cu ok tab craft World still rolled on the tab (tab craft)
:	ZEDQA cu ok tab craft rolled World 2643,400 903x735
:	ZEDQA cu ok tab craft World unrolled (rods in UI 0)
:	ZEDQA cu ok tab craft unrolled World 1929,400 1617x735
:	ZEDQA cu ok tab craft unrolled: other Character 694,400 1617x735
:	ZEDQA cu ok tab craft back on maps World 1929,400 1682x735
:	ZEDQA cu tab build World: its own width, 1929,400 1617x735 (maps 1929,400 1682x735)
:	ZEDQA cu ok tab build reference, back on maps World 1929,400 1682x735
:	ZEDQA cu ok tab build World rolled before the press
:	ZEDQA cu ok tab build World still rolled on the tab (tab build)
:	ZEDQA cu ok tab build rolled World 2643,400 903x735
:	ZEDQA cu ok tab build World unrolled (rods in UI 0)
:	ZEDQA cu ok tab build unrolled World 1929,400 1617x735
:	ZEDQA cu ok tab build unrolled: other Character 694,400 1617x735
:	ZEDQA cu ok tab build back on maps World 1929,400 1682x735
:	ZEDQA cu tab furniture World: its own width, 1929,400 1617x735 (maps 1929,400 1682x735)
:	ZEDQA cu ok tab furniture reference, back on maps World 1929,400 1682x735
:	ZEDQA cu ok tab furniture World rolled before the press
:	ZEDQA cu ok tab furniture World still rolled on the tab (tab furniture)
:	ZEDQA cu ok tab furniture rolled World 2643,400 903x735
:	ZEDQA cu ok tab furniture World unrolled (rods in UI 0)
:	ZEDQA cu ok tab furniture unrolled World 1929,400 1617x735
:	ZEDQA cu ok tab furniture unrolled: other Character 694,400 1617x735
:	ZEDQA cu ok tab furniture back on maps World 1929,400 1682x735
:	ZEDQA cu tab animals World: its own width, 1929,400 1617x735 (maps 1929,400 1682x735)
:	ZEDQA cu ok tab animals reference, back on maps World 1929,400 1682x735
:	ZEDQA cu ok tab animals World rolled before the press
:	ZEDQA cu ok tab animals World still rolled on the tab (tab animals)
:	ZEDQA cu ok tab animals rolled World 2643,400 903x735
:	ZEDQA cu ok tab animals World unrolled (rods in UI 0)
:	ZEDQA cu ok tab animals unrolled World 1929,400 1617x735
:	ZEDQA cu ok tab animals unrolled: other Character 694,400 1617x735
:	ZEDQA cu ok tab animals back on maps World 1929,400 1682x735
:	ZEDQA cu tab radio World: not shown here, skipped
:	ZEDQA cu tab vehicle World: not shown here, skipped
:	ZEDQA cu ok forage and back World still rolled (tab maps)
:	ZEDQA cu ok forage and back rolled World 2643,400 968x735
:	ZEDQA cu ok forage and back, unrolled World 1929,400 1682x735
:	ZEDQA cu World Loot (unrolled) 1929,400 777x735
:	ZEDQA cu ok Loot reference, back on maps World 1929,400 1682x735
:	ZEDQA cu ok Loot World rolled before the press
:	ZEDQA cu ok Loot World side down with the press (rolled false tab loot rods in UI 0)
:	ZEDQA cu ok Loot while rolled World 1929,400 777x735
:	ZEDQA cu ok Loot while rolled: other Character 694,400 1617x735
:	ZEDQA cu ok Loot while rolled, back on maps World 1929,400 1682x735
:	ZEDQA cu ok maps again World rolled before the press
:	ZEDQA cu ok maps again World side down (rolled false)
:	ZEDQA cu ok maps pressed again while rolled World 1929,400 777x735
:	ZEDQA cu ok maps again, back on maps World 1929,400 1682x735
:	ZEDQA cu Character tabs: on health 694,400 1617x735 (other 1929,400 1682x735)
:	ZEDQA cu ok tab skills reference, back on health Character 694,400 1617x735
:	ZEDQA cu ok tab skills Character rolled before the press
:	ZEDQA cu ok tab skills Character still rolled on the tab (tab skills)
:	ZEDQA cu ok tab skills rolled Character 694,400 903x735
:	ZEDQA cu ok tab skills Character unrolled (rods in UI 0)
:	ZEDQA cu ok tab skills unrolled Character 694,400 1617x735
:	ZEDQA cu ok tab skills unrolled: other World 1929,400 1682x735
:	ZEDQA cu ok tab skills back on health Character 694,400 1617x735
:	ZEDQA cu ok tab equip reference, back on health Character 694,400 1617x735
:	ZEDQA cu ok tab equip Character rolled before the press
:	ZEDQA cu ok tab equip Character still rolled on the tab (tab equip)
:	ZEDQA cu ok tab equip rolled Character 694,400 903x735
:	ZEDQA cu ok tab equip Character unrolled (rods in UI 0)
:	ZEDQA cu ok tab equip unrolled Character 694,400 1617x735
:	ZEDQA cu ok tab equip unrolled: other World 1929,400 1682x735
:	ZEDQA cu ok tab equip back on health Character 694,400 1617x735
:	ZEDQA cu ok tab thermal reference, back on health Character 694,400 1617x735
:	ZEDQA cu ok tab thermal Character rolled before the press
:	ZEDQA cu ok tab thermal Character still rolled on the tab (tab thermal)
:	ZEDQA cu ok tab thermal rolled Character 694,400 903x735
:	ZEDQA cu ok tab thermal Character unrolled (rods in UI 0)
:	ZEDQA cu ok tab thermal unrolled Character 694,400 1617x735
:	ZEDQA cu ok tab thermal unrolled: other World 1929,400 1682x735
:	ZEDQA cu ok tab thermal back on health Character 694,400 1617x735
:	ZEDQA cu ok tab identity reference, back on health Character 694,400 1617x735
:	ZEDQA cu ok tab identity Character rolled before the press
:	ZEDQA cu ok tab identity Character still rolled on the tab (tab identity)
:	ZEDQA cu ok tab identity rolled Character 694,400 903x735
:	ZEDQA cu ok tab identity Character unrolled (rods in UI 0)
:	ZEDQA cu ok tab identity unrolled Character 694,400 1617x735
:	ZEDQA cu ok tab identity unrolled: other World 1929,400 1682x735
:	ZEDQA cu ok tab identity back on health Character 694,400 1617x735
:	ZEDQA cu ok tab journal reference, back on health Character 694,400 1617x735
:	ZEDQA cu ok tab journal Character rolled before the press
:	ZEDQA cu ok tab journal Character still rolled on the tab (tab journal)
:	ZEDQA cu ok tab journal rolled Character 694,400 903x735
:	ZEDQA cu ok tab journal Character unrolled (rods in UI 0)
:	ZEDQA cu ok tab journal unrolled Character 694,400 1617x735
:	ZEDQA cu ok tab journal unrolled: other World 1929,400 1682x735
:	ZEDQA cu ok tab journal back on health Character 694,400 1617x735
:	ZEDQA cu tab radio Character: not shown here, skipped
:	ZEDQA cu ok skills and back Character still rolled (tab health)
:	ZEDQA cu ok skills and back rolled Character 694,400 903x735
:	ZEDQA cu ok skills and back, unrolled Character 694,400 1617x735
:	ZEDQA cu Character Loot (unrolled) 1534,400 777x735
:	ZEDQA cu ok Loot reference, back on health Character 694,400 1617x735
:	ZEDQA cu ok Loot Character rolled before the press
:	ZEDQA cu ok Loot Character side down with the press (rolled false tab loot rods in UI 0)
:	ZEDQA cu ok Loot while rolled Character 1534,400 777x735
:	ZEDQA cu ok Loot while rolled: other World 1929,400 1682x735
:	ZEDQA cu ok Loot while rolled, back on health Character 694,400 1617x735
:	ZEDQA cu ok health again Character rolled before the press
:	ZEDQA cu ok health again Character side down (rolled false)
:	ZEDQA cu ok health pressed again while rolled Character 1534,400 777x735
:	ZEDQA cu ok health again, back on health Character 694,400 1617x735
:	ZEDQA cu geometry checks 214, differences 0
:	ZEDQA cu at quit, unrolled: Character 694,400 1617x735 rolled false (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 1929,400 1682x735 rolled false (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu at quit, rolled: Character 694,400 903x735 rolled true (saved 876.571,228.571 444.000x420.000 anchor 1320.571 tab health drawer true) | World 2643,400 968x735 rolled true (saved 1102.286,228.571 444.000x420.000 tab maps drawer true)
:	ZEDQA cu DONE
```

### 16. zedqa_curtain2.lua (`ZEDQA cv`) - PASS, 15 s

- go 14002 at 00:23:52
- screenshots: zqa_cv_1.png, zqa_cv_2.png, zqa_cv_3.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cv start
:	[ZeD.QA] run #16 ok=true
:	ZEDQA cv health tab true
:	ZEDQA cv char before rolled false x 294 w 1617 right 1911 tab health content true rod - button true
:	ZEDQA cv roll true
:	ZEDQA cv char rolled rolled true x 294 w 903 right 1197 tab health content false rod 1197+714
:	ZEDQA cv skills tab true
:	ZEDQA cv char after switch rolled true x 294 w 903 right 1197 tab skills content false rod 1197+714
:	ZEDQA cv A on the tab (charContainerStrip)
:	ZEDQA cv char unrolled rolled false x 294 w 1617 right 1911 tab skills content true rod - (was x 294 w 1617)
:	ZEDQA cv world roll true
:	ZEDQA cv world rolled rolled true x 2643 w 968 right 3611 tab maps content false rod 1929+714
:	ZEDQA cv world after switch rolled true x 2643 w 903 right 3546 tab forage content false rod 1929+714
:	ZEDQA cv world unrolled rolled false x 1929 w 1617 right 3546 tab forage content true rod -
:	ZEDQA cv DONE
```

### 17. zedqa_navevents.lua (`ZEDQA ev`) - PASS, 8 s

- go 14003 at 00:24:14

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ev start
:	[ZeD.QA] run #17 ok=true
:	ZEDQA ev 1 on the hammer row: Char charMainInv:invrow:7 (Claw Hammer)
:	ZEDQA ev 1 after A (expect the card's primary action): Char charItemCard:hverb_1
:	ZEDQA ev 1 after B (expect back on the hammer row): Char charMainInv:invrow:7 (Claw Hammer)
:	ZEDQA ev 2 Right (expect the strip): Char charTabContent:skill:Cooking
:	ZEDQA ev 2 Left (expect back on the hammer row): Char charMainInv:invrow:7 (Claw Hammer)
:	ZEDQA ev 3 on the screwdriver: Char charMainInv:invrow:14 (Screwdriver)
:	ZEDQA ev 3 Left (expect the active tab): Char charTabBar:tab:loot
:	ZEDQA ev 3 Down: Char charTabBar:tab:equip
:	ZEDQA ev 3 A on: Char charTabBar:tab:equip
:	ZEDQA ev 3 after A on the tab (expect still on it): Char charTabBar:tab:equip
:	ZEDQA ev 3 Right (expect the tab's first control): Char charTabContent:equipgroup:head
:	ZEDQA ev 3 Left (expect back on the tab): Char charTabBar:tab:equip
:	ZEDQA ev 4 on the screwdriver: Char charMainInv:invrow:14 (Screwdriver)
:	ZEDQA ev 4 after RB (World): World worldTabBar:tab:loot
:	ZEDQA ev 4 after LB (expect back on the screwdriver): Char charMainInv:invrow:14 (Screwdriver)
:	ZEDQA ev 5 on the hammer: Char charMainInv:invrow:7 (Claw Hammer)
:	ZEDQA ev 5 after the hammer went (expect a neighbouring row): Char charMainInv:invrow:7 (Digital Watch)
:	ZEDQA ev 6 on the star tool: World worldTabContent:map:tool:star
:	ZEDQA ev 6 Down (expect the map): World worldTabContent:map:canvas:cursor
:	ZEDQA ev 6 Up (expect back on the star tool): World worldTabContent:map:tool:star
:	ZEDQA ev 6 Down, Left: World worldCtl:worldCtl:same
:	ZEDQA ev 6 Right (expect back on the map): World worldTabContent:map:canvas:cursor
:	ZEDQA ev 6 Right again: World worldTabBar:tab:maps
:	ZEDQA ev 7 on unfold: World worldTabContent:map:popout
:	ZEDQA ev 7 after unfold (expect the big map's window): Map popMapContent:map:canvas:cursor
:	ZEDQA ev 7 after B (expect the World window's map or unfold): World worldTabContent:map:popout
:	ZEDQA ev DONE
```

### 18. zedqa_navmap.lua (`ZEDQA nav`) - PASS, 16 s

- go 14004 at 00:24:28

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA nav start
:	[ZeD.QA] run #18 ok=true
:	ZEDQA nav char loot: 28 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
:	ZEDQA nav char loot STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) invrow:14(D)
:	ZEDQA nav char loot charTabBar:tab:loot U>charMainInv:invrow:2~ D>tab:equip L>- R>charMainInv:invrow:7
:	ZEDQA nav char loot charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charMainInv:invrow:7
:	ZEDQA nav char loot charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charMainInv:invrow:7
:	ZEDQA nav char loot charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charMainInv:invrow:7
:	ZEDQA nav char loot charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charMainInv:invrow:7
:	ZEDQA nav char loot charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charMainInv:invrow:7
:	ZEDQA nav char loot charTabBar:tab:skills U>tab:journal D>charMainInv:invrow:10~ L>- R>charMainInv:invrow:7
:	ZEDQA nav char loot charMainInv:invrow:1 U>- D>invrow:2 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabBar:tab:loot R>view:list:player
:	ZEDQA nav char loot charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabBar:tab:loot R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:invrow:14 U>invrow:13 D>- L>charCtl:charCtl:xfer R>charContainerStrip:container:1
:	ZEDQA nav char loot charMainInv:view:list:player U>invrow:2~ D>invrow:3~ L>invrow:2 R>view:grid:player
:	ZEDQA nav char loot charMainInv:view:grid:player U>invrow:2~ D>invrow:3~ L>view:list:player R>charContainerStrip:container:1
:	ZEDQA nav char loot charContainerStrip:container:1 U>charMainInv:invrow:2~ D>container:2 L>charMainInv:view:grid:player R>window:World
:	ZEDQA nav char loot charContainerStrip:container:2 U>container:1 D>charMainInv:invrow:5~ L>charMainInv:invrow:4 R>window:World
:	ZEDQA nav char loot charCtl:charCtl:xfer U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charTabBar:tab:loot~ R>charMainInv:invrow:14
:	ZEDQA nav char loot charCtl:charCtl:same U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:xfer R>charMainInv:invrow:14
:	ZEDQA nav char loot charCtl:charCtl:near U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:same R>charMainInv:invrow:14
:	ZEDQA nav char equip: 59 targets | TRAP 6 {equipslot:INR,equipslot:GLV,equipslot:PNT,equipslot:SOC,equipslot:BOT,equipslot:BLT} | ISLAND 1 {charCtl:charCtl:near}
:	ZEDQA nav char equip STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) equippart:Right Foot(D) equippart:Left Foot(D) invrow:1(U)
:	ZEDQA nav char equip charTabBar:tab:loot U>charMainInv:invrow:2~ D>tab:equip L>- R>charTabContent:equipslot:__disclosure
:	ZEDQA nav char equip charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charTabContent:equipgroup:head
:	ZEDQA nav char equip charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charTabContent:equipgroup:torso
:	ZEDQA nav char equip charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charTabContent:equipgroup:arms
:	ZEDQA nav char equip charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charTabContent:equipgroup:legs
:	ZEDQA nav char equip charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charTabContent:equipslot:PNT
:	ZEDQA nav char equip charTabBar:tab:skills U>tab:journal D>charTabContent:equipslot:BOT~ L>- R>charTabContent:equipslot:SOC
:	ZEDQA nav char equip charTabContent:equipslot:__disclosure U>charTabBar:tab:equip~ D>equipgroup:head L>charTabBar:tab:equip R>equipview:list
:	ZEDQA nav char equip charTabContent:equipview:list U>charMainInv:invrow:2~ D>equipgroup:head L>equipslot:__disclosure R>equipview:doll
:	ZEDQA nav char equip charTabContent:equipview:doll U>charMainInv:invrow:2~ D>equipgroup:head L>equipslot:__disclosure R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equippart:Head U>equipslot:BLT D>equippart:Neck L>equippart:Neck R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equippart:Neck U>equippart:Head D>equippart:Upper Torso L>charTabBar:tab:equip~ R>equippart:Head
:	ZEDQA nav char equip charTabContent:equippart:Upper Torso U>equippart:Neck D>equippart:Lower Torso L>equippart:Right Upper Arm R>equippart:Left Upper Arm
:	ZEDQA nav char equip charTabContent:equippart:Right Upper Arm U>equippart:Upper Torso D>equippart:Right Forearm L>equippart:Right Forearm R>equippart:Upper Torso
:	ZEDQA nav char equip charTabContent:equippart:Left Upper Arm U>equippart:Upper Torso D>equippart:Left Forearm L>equippart:Upper Torso R>equippart:Left Forearm
:	ZEDQA nav char equip charTabContent:equippart:Lower Torso U>equippart:Upper Torso D>equippart:Groin L>equippart:Right Upper Arm R>equippart:Groin
:	ZEDQA nav char equip charTabContent:equippart:Right Forearm U>equippart:Right Upper Arm D>equippart:Right Hand L>equippart:Right Hand R>equippart:Right Upper Leg
:	ZEDQA nav char equip charTabContent:equippart:Left Forearm U>equippart:Left Upper Arm D>equippart:Left Hand L>equippart:Groin R>equippart:Left Hand
:	ZEDQA nav char equip charTabContent:equippart:Groin U>equippart:Lower Torso D>equippart:Right Upper Leg L>equippart:Lower Torso R>equippart:Left Forearm
:	ZEDQA nav char equip charTabContent:equippart:Right Hand U>equippart:Right Forearm D>equippart:Right Upper Leg~ L>charTabBar:tab:equip~ R>equippart:Right Forearm
:	ZEDQA nav char equip charTabContent:equippart:Left Hand U>equippart:Left Forearm D>equippart:Left Upper Leg~ L>equippart:Left Forearm R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equippart:Right Upper Leg U>equippart:Groin D>equippart:Right Lower Leg L>equippart:Right Forearm R>equippart:Groin
:	ZEDQA nav char equip charTabContent:equippart:Left Upper Leg U>equippart:Groin D>equippart:Left Lower Leg L>equippart:Groin R>equippart:Left Forearm
:	ZEDQA nav char equip charTabContent:equippart:Right Lower Leg U>equippart:Right Upper Leg D>equippart:Right Foot L>equippart:Right Foot R>equippart:Right Upper Leg
:	ZEDQA nav char equip charTabContent:equippart:Left Lower Leg U>equippart:Left Upper Leg D>equippart:Left Foot L>equippart:Left Upper Leg R>equippart:Left Foot
:	ZEDQA nav char equip charTabContent:equippart:Right Foot U>equippart:Right Lower Leg D>- L>charTabBar:tab:equip~ R>equippart:Right Lower Leg
:	ZEDQA nav char equip charTabContent:equippart:Left Foot U>equippart:Left Lower Leg D>- L>equippart:Left Lower Leg R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipgroup:head U>equipslot:__disclosure D>equipgroup:torso L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipgroup:torso U>equipgroup:head D>equipslot:INR L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipgroup:arms U>equipslot:INR D>equipslot:GLV L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipgroup:legs U>equipslot:GLV D>equipslot:PNT L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipgroup:held U>equipslot:BOT D>equipslot:BLT L>charTabBar:tab:equip~ R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipslot:INR [OWN D-PAD] U>equipgroup:torso D>equipgroup:arms L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipslot:GLV [OWN D-PAD] U>equipgroup:arms D>equipgroup:legs L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipslot:PNT [OWN D-PAD] U>equipgroup:legs D>equipslot:SOC L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipslot:SOC [OWN D-PAD] U>equipslot:PNT D>equipslot:BOT L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipslot:BOT [OWN D-PAD] U>equipslot:SOC D>equipgroup:held L>charTabBar:tab:equip R>charMainInv:invrow:7
:	ZEDQA nav char equip charTabContent:equipslot:BLT [OWN D-PAD] U>equipgroup:held D>equippart:Head L>charTabBar:tab:equip~ R>charMainInv:invrow:7
:	ZEDQA nav char equip charMainInv:invrow:1 U>- D>invrow:2 L>charTabContent:equipslot:__disclosure~ R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabContent:equipslot:__disclosure R>view:list:player
:	ZEDQA nav char equip charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabContent:equipslot:__disclosure R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabContent:equipgroup:torso R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabContent:equipslot:INR R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabContent:equipgroup:arms R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabContent:equipgroup:legs R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabContent:equipslot:PNT R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabContent:equipslot:SOC R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charTabContent:equipslot:BOT R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charTabContent:equipslot:BLT R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabContent:equipslot:BLT R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:invrow:14 U>invrow:13 D>charTabContent:equippart:Left Upper Arm~ L>charCtl:charCtl:xfer R>charContainerStrip:container:1
:	ZEDQA nav char equip charMainInv:view:list:player U>invrow:2~ D>invrow:3~ L>invrow:2 R>view:grid:player
:	ZEDQA nav char equip charMainInv:view:grid:player U>invrow:2~ D>invrow:3~ L>view:list:player R>charContainerStrip:container:1
:	ZEDQA nav char equip charContainerStrip:container:1 U>charMainInv:invrow:2~ D>container:2 L>charMainInv:view:grid:player R>window:World
:	ZEDQA nav char equip charContainerStrip:container:2 U>container:1 D>charMainInv:invrow:5~ L>charMainInv:invrow:4 R>window:World
:	ZEDQA nav char equip charCtl:charCtl:xfer U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charTabContent:equippart:Head R>charMainInv:invrow:14
:	ZEDQA nav char equip charCtl:charCtl:same U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:xfer R>charMainInv:invrow:14
:	ZEDQA nav char equip charCtl:charCtl:near U>charMainInv:invrow:13 D>charMainInv:invrow:14 L>charCtl:same R>charMainInv:invrow:14
:	ZEDQA nav char health: 55 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
:	ZEDQA nav char health STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) invrow:14(D)
:	ZEDQA nav char thermal: 54 targets | TRAP 1 {thermal:__gridscroll} | ISLAND 1 {charCtl:charCtl:near}
:	ZEDQA nav char thermal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:1(U) invrow:14(D)
:	ZEDQA nav char identity: 83 targets | TRAP 1 {hb:part} | ISLAND 1 {charCtl:charCtl:near}
:	ZEDQA nav char identity STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) identity:trait:Weak Stomach(D) invrow:1(U)
:	ZEDQA nav char journal: 36 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
:	ZEDQA nav char journal STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) journal:group:6_1993(D) invrow:1(U)
:	ZEDQA nav char skills: 90 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
:	ZEDQA nav char skills STUCK: tab:loot(L) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) training:col1_Glassmaking(D) invrow:1(U)
:	ZEDQA nav world loot: 10 targets | TRAP 0 {} | ISLAND 0 {}
:	ZEDQA nav world loot STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
:	ZEDQA nav world loot worldContainerStrip:container:1 U>- D>worldCtl:worldCtl:take~ L>window:Character R>worldCtl:worldCtl:take
:	ZEDQA nav world loot worldTabBar:tab:loot U>- D>tab:craft L>worldCtl:worldCtl:same R>-
:	ZEDQA nav world loot worldTabBar:tab:craft U>tab:loot D>tab:build L>worldCtl:worldCtl:same R>-
:	ZEDQA nav world loot worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldCtl:worldCtl:same R>-
:	ZEDQA nav world loot worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldCtl:worldCtl:same R>-
:	ZEDQA nav world loot worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldCtl:worldCtl:same R>-
:	ZEDQA nav world loot worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldCtl:worldCtl:same~ R>-
:	ZEDQA nav world loot worldTabBar:tab:animals U>tab:forage D>worldCtl:worldCtl:same~ L>worldCtl:worldCtl:same~ R>-
:	ZEDQA nav world loot worldCtl:worldCtl:take U>worldContainerStrip:container:1 D>- L>worldContainerStrip:container:1 R>worldCtl:same
:	ZEDQA nav world loot worldCtl:worldCtl:same U>worldContainerStrip:container:1 D>- L>worldCtl:take R>worldTabBar:tab:loot~
:	ZEDQA nav world craft: 20 targets | TRAP 0 {} | ISLAND 0 {}
:	ZEDQA nav world craft STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
:	ZEDQA nav world build: 18 targets | TRAP 0 {} | ISLAND 0 {}
:	ZEDQA nav world build STUCK: container:1(U) build:catDrop(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
:	ZEDQA nav world furniture: 15 targets | TRAP 0 {} | ISLAND 0 {}
:	ZEDQA nav world furniture STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
:	ZEDQA nav world maps: 29 targets | TRAP 0 {} | ISLAND 0 {}
:	ZEDQA nav world maps STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
:	ZEDQA nav world maps worldContainerStrip:container:1 U>- D>worldCtl:worldCtl:take~ L>window:Character R>worldCtl:worldCtl:take
:	ZEDQA nav world maps worldTabContent:map:disclosure U>worldContainerStrip:container:1 D>map:canvas:cursor L>worldCtl:worldCtl:same R>map:tool:house
:	ZEDQA nav world maps worldTabContent:map:tool:house U>worldContainerStrip:container:1 D>map:canvas:cursor L>map:disclosure R>map:tool:target
:	ZEDQA nav world maps worldTabContent:map:tool:target U>worldContainerStrip:container:1 D>map:canvas:cursor L>map:tool:house R>map:tool:skull
:	ZEDQA nav world maps worldTabContent:map:tool:skull U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:target R>map:tool:star
:	ZEDQA nav world maps worldTabContent:map:tool:star U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:skull R>map:tool:cross
:	ZEDQA nav world maps worldTabContent:map:tool:cross U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:star R>map:tool:checkmark
:	ZEDQA nav world maps worldTabContent:map:tool:checkmark U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:cross R>map:tool:text
:	ZEDQA nav world maps worldTabContent:map:tool:text U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:checkmark R>map:color:1
:	ZEDQA nav world maps worldTabContent:map:color:1 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:text R>map:color:2
:	ZEDQA nav world maps worldTabContent:map:color:2 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:1 R>map:color:3
:	ZEDQA nav world maps worldTabContent:map:color:3 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:2 R>map:color:4
:	ZEDQA nav world maps worldTabContent:map:color:4 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:3 R>map:color:5
:	ZEDQA nav world maps worldTabContent:map:color:5 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:4 R>map:ext:key
:	ZEDQA nav world maps worldTabContent:map:style:survey U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:ext:key R>map:style:color
:	ZEDQA nav world maps worldTabContent:map:style:color U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:style:survey R>map:style:paper
:	ZEDQA nav world maps worldTabContent:map:style:paper U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:style:color R>map:popout
:	ZEDQA nav world maps worldTabContent:map:popout U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:style:paper R>worldTabBar:tab:maps
:	ZEDQA nav world maps worldTabContent:map:ext:key U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:5 R>map:style:survey
:	ZEDQA nav world maps worldTabContent:map:canvas:cursor U>map:disclosure D>worldTabBar:tab:maps~ L>worldCtl:worldCtl:same R>worldTabBar:tab:maps
:	ZEDQA nav world maps worldTabBar:tab:loot U>- D>tab:craft L>worldTabContent:map:popout R>-
:	ZEDQA nav world maps worldTabBar:tab:craft U>tab:loot D>tab:build L>worldTabContent:map:canvas:cursor R>-
:	ZEDQA nav world maps worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldTabContent:map:canvas:cursor R>-
:	ZEDQA nav world maps worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldTabContent:map:canvas:cursor R>-
:	ZEDQA nav world maps worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldTabContent:map:canvas:cursor R>-
:	ZEDQA nav world maps worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldTabContent:map:canvas:cursor R>-
:	ZEDQA nav world maps worldTabBar:tab:animals U>tab:forage D>worldCtl:worldCtl:same~ L>worldTabContent:map:canvas:cursor R>-
:	ZEDQA nav world maps worldCtl:worldCtl:take U>worldContainerStrip:container:1 D>- L>worldContainerStrip:container:1 R>worldCtl:same
:	ZEDQA nav world maps worldCtl:worldCtl:same U>worldContainerStrip:container:1 D>- L>worldCtl:take R>worldTabContent:map:canvas:cursor
:	ZEDQA nav world forage: 13 targets | TRAP 0 {} | ISLAND 0 {}
:	ZEDQA nav world forage STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
:	ZEDQA nav world animals: 13 targets | TRAP 0 {} | ISLAND 0 {}
:	ZEDQA nav world animals STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) worldCtl:take(D) worldCtl:same(D)
:	ZEDQA nav DONE
```

### 19. zedqa_loot_tabs.lua (`ZEDQA lt`) - PASS, 1 s

- go 14005 at 00:24:50

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA lt start
:	[ZeD.QA] run #19 ok=true
:	ZEDQA lt Character loot drawer false | World loot drawer false
:	ZEDQA lt DONE
```

### 20. zedqa_world_pad_take.lua (`ZEDQA wpt`) - PASS, 97 s

- go 14006 at 00:24:57

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA wpt start
:	[ZeD.QA] run #20 ok=true
:	ZEDQA wpt scene: 1 zombies removed, save ZeD-QA
:	ZEDQA wpt PASS a crate was built beside the character
:	ZEDQA wpt containers 1:Crate(ours), 2:Ground | stops container:2@0, container:1@100
:	ZEDQA wpt PASS the crate has a stop in the World window's container strip (stops follow the list)
:	ZEDQA wpt 1 after RB: World worldTabBar:tab:maps
:	ZEDQA wpt PASS RB lands in the World window on a lit element
:	ZEDQA wpt 1 on the Character window's strip: Char charContainerStrip:container:1
:	ZEDQA wpt 1 Right from the Character window's right edge: World worldTabBar:tab:maps
:	ZEDQA wpt PASS the D-pad across from the Character window lands in the World window, lit
:	ZEDQA wpt 2 strip: World worldContainerStrip:container:2
:	ZEDQA wpt PASS on the strip, focus is on the container on show (the ground)
:	ZEDQA wpt 2 Down x1: World worldContainerStrip:container:1
:	ZEDQA wpt PASS Down from the ground reaches the crate (1 presses)
:	ZEDQA wpt 2 after A on the crate: World worldMainInv:invrow:1 (Apple (Fresh))
:	ZEDQA wpt PASS A on the crate puts focus on its first item, lit
:	ZEDQA wpt 2 Left: World worldContainerStrip:container:1
:	ZEDQA wpt PASS Left from the list lands on the crate (the container on show)
:	ZEDQA wpt 2 Right: World worldMainInv:invrow:1 (Apple (Fresh))
:	ZEDQA wpt PASS Right goes back to the same row
:	ZEDQA wpt 2 Left from a lower row: World worldContainerStrip:container:1
:	ZEDQA wpt PASS Left from a lower row lands on the crate too
:	ZEDQA wpt PASS and Right goes back to that row
:	ZEDQA wpt 3 A on the bandage: World worldItemCard:hverb_1
:	ZEDQA wpt PASS 3 A on the bandage: focus is on the card's primary action (TAKE)
:	ZEDQA wpt 3 Down in the card: World worldItemCard:name_row
:	ZEDQA wpt PASS Down moves to the card's next control
:	ZEDQA wpt 3 Up: World worldItemCard:hverb_1
:	ZEDQA wpt PASS Up from inside the card is back on the primary action in one press
:	ZEDQA wpt 3 after B: World worldMainInv:invrow:4 (Tweezers)
:	ZEDQA wpt PASS B closes the card and focus is back on the bandage row, lit
:	ZEDQA wpt 4 A on the nails: World worldItemCard:hverb_1
:	ZEDQA wpt PASS 4 A on the nails: focus is on the card's primary action (TAKE)
:	ZEDQA wpt PASS the nails' card offers Take as its primary action
:	ZEDQA wpt PASS A on Take moved the nails into the bag (vanilla's transfer, 10 ticks)
:	ZEDQA wpt 4 after the take: World worldMainInv:invrow:3 (Tweezers)
:	ZEDQA wpt 5 before the padlock card: World worldMainInv:invrow:1 (Apple (Fresh))
:	ZEDQA wpt 5 the padlock card: World worldItemCard:oc:verb:usecombo
:	ZEDQA wpt PASS the object card opens with focus on its main live verb (oc:verb:usecombo)
:	ZEDQA wpt PASS A on it ran the verb (the padlock's code wheel shows)
:	ZEDQA wpt 5 after B: World worldMainInv:invrow:1 (Apple (Fresh))
:	ZEDQA wpt PASS B closes the object card and focus is back in the list, lit
:	ZEDQA wpt 6 Left from the World window's strip: Char charContainerStrip:container:1
:	ZEDQA wpt PASS the D-pad across from the World window lands in the Character window, lit
:	ZEDQA wpt 6 LB: Char charContainerStrip:container:1
:	ZEDQA wpt PASS LB lands in the Character window on a lit element
:	ZEDQA wpt 6 Right: Char charContainerStrip:container:1
:	ZEDQA wpt PASS Right from a row lands on the bag on show
:	ZEDQA wpt PASS Left goes back to the same row
:	ZEDQA wpt 6 A on the nails: Char charItemCard:hverb_1
:	ZEDQA wpt PASS 6 A on the nails: focus is on the card's primary action (DROP)
:	ZEDQA wpt PASS Down then Up in the Character window's card is back on its primary action
:	ZEDQA wpt 6 primary is DROP; A runs it
:	ZEDQA wpt PASS A on the card's primary action (Drop) moved the nails out of the bag (10 ticks)
:	ZEDQA wpt 6 A on a row: Char charItemCard:hverb_1
:	ZEDQA wpt PASS 6 A on a row: focus is on the card's primary action (DROP)
:	ZEDQA wpt 6 after B: Char charMainInv:invrow:1 (Angel Cross's Key Ring)
:	ZEDQA wpt PASS B on the Character window's card goes back to the row
:	ZEDQA wpt PASS 8 X on a row opens the context menu
:	ZEDQA wpt 8 after the menu's B: World worldMainInv:invrow:2 (Corkscrew)
:	ZEDQA wpt PASS 8 the menu closed: focus is back on the same row, lit
:	ZEDQA wpt 8 after hold A: World worldMainInv:invrow:2 (Tweezers)
:	ZEDQA wpt PASS 8 hold A moved the hammer out of the crate
:	ZEDQA wpt 8 a moment later: World worldMainInv:invrow:2 (Tweezers)
:	ZEDQA wpt PASS 8 after the transfer focus is on a neighbour in the same panel, lit
:	ZEDQA wpt PASS 8 a stray Left with a window open stays in the window (no way into the belt)
:	ZEDQA wpt PASS 8 with the windows put away, Left opens the Character wheel (not the belt)
:	ZEDQA wpt PASS 8 B leaves the belt in one press
:	ZEDQA wpt PASS 8 Right past the belt's last box leaves it
:	ZEDQA wpt PASS 8 Down (the screen's edge) leaves the belt
:	ZEDQA wpt 7 tabs: 12 at small and large
:	ZEDQA wpt PASS 7 Char equip small pad: Down reaches the lowest control equippart:Right Foot and it is in view (bottom 653 of 664)
:	ZEDQA wpt PASS 7 Char equip small wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 638 of 664)
:	ZEDQA wpt PASS 7 Char health small pad: Down reaches the lowest control exercise:time:dec and it is in view (bottom 508 of 664)
:	ZEDQA wpt PASS 7 Char health small wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 508 of 664)
:	ZEDQA wpt PASS 7 Char health small Health: scrolled to the end, drawn 956 px in a 599 px view
:	ZEDQA wpt PASS 7 Char thermal small pad: Down reaches the lowest control thermal:__gridscroll and it is in view (bottom 664 of 664)
:	ZEDQA wpt PASS 7 Char thermal small wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 664 of 664)
:	ZEDQA wpt PASS 7 Char identity small pad: Down reaches the lowest control identity:trait:Weak Stomach and it is in view (bottom 554 of 664)
:	ZEDQA wpt PASS 7 Char identity small wheel: the lowest control identity:trait:Weak Stomach is in view at the bottom (bottom 554 of 664)
:	ZEDQA wpt PASS 7 Char journal small pad: Down reaches the lowest control journal:group:6_1993 and it is in view (bottom 650 of 664)
:	ZEDQA wpt PASS 7 Char journal small wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 275 of 664)
:	ZEDQA wpt PASS 7 Char skills small pad: Down reaches the lowest control training:col1_Glassmaking and it is in view (bottom 664 of 664)
:	ZEDQA wpt PASS 7 Char skills small wheel: the lowest control training:col1_Glassmaking is in view at the bottom (bottom 648 of 664)
:	ZEDQA wpt PASS 7 World craft small pad: Down reaches the lowest control craft:row:RemoveBattery and it is in view (bottom 228 of 664)
:	ZEDQA wpt PASS 7 World craft small wheel: the lowest control craft:row:RemoveBattery is in view at the bottom (bottom 228 of 664)
:	ZEDQA wpt PASS 7 World build small pad: Down reaches the lowest control build:section:all and it is in view (bottom 126 of 664)
:	ZEDQA wpt PASS 7 World build small wheel: the lowest control build:section:all is in view at the bottom (bottom 126 of 664)
:	ZEDQA wpt PASS 7 World furniture small pad: Down reaches the lowest control fur:mode:pickup and it is in view (bottom 121 of 664)
:	ZEDQA wpt PASS 7 World furniture small wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 121 of 664)
:	ZEDQA wpt PASS 7 World maps small pad: Down reaches the lowest control map:canvas:cursor and it is in view (bottom 664 of 664)
:	ZEDQA wpt PASS 7 World maps small wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 664 of 664)
:	ZEDQA wpt PASS 7 World forage small pad: Down reaches the lowest control forage:disclosure and it is in view (bottom 348 of 664)
:	ZEDQA wpt PASS 7 World forage small wheel: the lowest control forage:disclosure is in view at the bottom (bottom 348 of 664)
:	ZEDQA wpt PASS 7 World animals small pad: Down reaches the lowest control animals:createzone and it is in view (bottom 655 of 664)
:	ZEDQA wpt PASS 7 World animals small wheel: the lowest control animals:createzone is in view at the bottom (bottom 655 of 664)
:	ZEDQA wpt PASS 7 Char equip large pad: Down reaches the lowest control equippart:Right Foot and it is in view (bottom 636 of 654)
:	ZEDQA wpt PASS 7 Char equip large wheel: the lowest control equippart:Right Foot is in view at the bottom (bottom 626 of 654)
:	ZEDQA wpt PASS 7 Char health large pad: Down reaches the lowest control exercise:time:dec and it is in view (bottom 580 of 654)
:	ZEDQA wpt PASS 7 Char health large wheel: the lowest control exercise:time:dec is in view at the bottom (bottom 580 of 654)
:	ZEDQA wpt PASS 7 Char health large Health: scrolled to the end, drawn 980 px in a 580 px view
:	ZEDQA wpt PASS 7 Char thermal large pad: Down reaches the lowest control thermal:__gridscroll and it is in view (bottom 654 of 654)
:	ZEDQA wpt PASS 7 Char thermal large wheel: the lowest control thermal:__gridscroll is in view at the bottom (bottom 654 of 654)
:	ZEDQA wpt PASS 7 Char identity large pad: Down reaches the lowest control identity:trait:Weak Stomach and it is in view (bottom 529 of 654)
:	ZEDQA wpt PASS 7 Char identity large wheel: the lowest control identity:trait:Weak Stomach is in view at the bottom (bottom 529 of 654)
:	ZEDQA wpt PASS 7 Char journal large pad: Down reaches the lowest control journal:group:6_1993 and it is in view (bottom 638 of 654)
:	ZEDQA wpt PASS 7 Char journal large wheel: the lowest control journal:group:6_1993 is in view at the bottom (bottom 212 of 654)
:	ZEDQA wpt PASS 7 Char skills large pad: Down reaches the lowest control training:col1_Glassmaking and it is in view (bottom 654 of 654)
:	ZEDQA wpt PASS 7 Char skills large wheel: the lowest control training:col1_Glassmaking is in view at the bottom (bottom 636 of 654)
:	ZEDQA wpt PASS 7 World craft large pad: Down reaches the lowest control craft:row:RemoveBattery and it is in view (bottom 260 of 654)
:	ZEDQA wpt PASS 7 World craft large wheel: the lowest control craft:row:RemoveBattery is in view at the bottom (bottom 260 of 654)
:	ZEDQA wpt PASS 7 World build large pad: Down reaches the lowest control build:section:all and it is in view (bottom 144 of 654)
:	ZEDQA wpt PASS 7 World build large wheel: the lowest control build:section:all is in view at the bottom (bottom 144 of 654)
:	ZEDQA wpt PASS 7 World furniture large pad: Down reaches the lowest control fur:mode:pickup and it is in view (bottom 138 of 654)
:	ZEDQA wpt PASS 7 World furniture large wheel: the lowest control fur:mode:pickup is in view at the bottom (bottom 138 of 654)
:	ZEDQA wpt PASS 7 World maps large pad: Down reaches the lowest control map:canvas:cursor and it is in view (bottom 654 of 654)
:	ZEDQA wpt PASS 7 World maps large wheel: the lowest control map:canvas:cursor is in view at the bottom (bottom 654 of 654)
:	ZEDQA wpt PASS 7 World forage large pad: Down reaches the lowest control forage:disclosure and it is in view (bottom 397 of 654)
:	ZEDQA wpt PASS 7 World forage large wheel: the lowest control forage:disclosure is in view at the bottom (bottom 397 of 654)
:	ZEDQA wpt PASS 7 World animals large pad: Down reaches the lowest control animals:createzone and it is in view (bottom 644 of 654)
:	ZEDQA wpt PASS 7 World animals large wheel: the lowest control animals:createzone is in view at the bottom (bottom 644 of 654)
:	ZEDQA wpt cleanup: crate gone true, size small
:	ZEDQA wpt 89 passed, 0 failed
:	ZEDQA wpt DONE
```

### 21. zedqa_furniture.lua (`ZEDQA fu`) - PASS, 3 s

- go 14007 at 00:26:41

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #21 ok=true
:	ZEDQA fu tab=true cursor=true mode=pickup
:	ZEDQA fu furniture square=12050,11756
:	ZEDQA fu pickup capture name=nil can=false facts=nil notes=nil
:	ZEDQA fu mode place -> cursor mode=place target=false can=false
:	ZEDQA fu mode rotate -> cursor mode=rotate target=false can=false
:	ZEDQA fu mode scrap -> cursor mode=scrap target=false can=false
:	ZEDQA fu mode repair -> cursor mode=repair target=false can=false
:	ZEDQA fu mode pickup -> cursor mode=pickup target=false can=false
:	ZEDQA fu zones fur:mode:pickup,fur:mode:place,fur:mode:rotate,fur:mode:scrap,fur:mode:repair
:	ZEDQA fu after leaving tab=false cursor=false active=false
```

### 22. zedqa_tabicons.lua (`ZEDQA ti`) - PASS, 3 s

- go 14008 at 00:26:50
- screenshots: zqa_tabicons.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #22 ok=true
:	ZEDQA ti DONE
```

### 23. zedqa_tabs_lit.lua (`ZEDQA tl`) - PASS, 7 s

- go 14009 at 00:26:59
- screenshots: zqa_tabs_1.png, zqa_tabs_2.png, zqa_tabs_3.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #23 ok=true
:	ZEDQA tl char true world true TabPx true
:	ZEDQA tl active loot / loot
:	ZEDQA tl restored; DONE
```

### 24. zedqa_win.lua (`ZEDQA win`) - PASS, 5 s

- go 14010 at 00:27:12
- screenshots: zedqa_win_200.png, zedqa_win_100.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #24 ok=true
:	ZEDQA win natural root=1.75 T.scale=1.75 rowH=53 sp.md=25 F2H=29.1484375 char=true 1134,0 777x735 world=true 1929,0 777x735
:	ZEDQA win forced1 root=1 T.scale=1 rowH=30 sp.md=14 F2H=16.65625 char=true 1134,0 777x735 world=true 1929,0 777x735
:	ZEDQA win done root=1.75
```

### 25. zedqa_rootchange.lua (`ZEDQA rc`) - PASS, 6 s

- go 14011 at 00:27:23
- screenshots: zedqa_rc_100.png, zedqa_rc_200.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #25 ok=true
:	ZEDQA rc open at natural root=1.75 applied=1.75 char=true 777x735 at 1134,0 world=true 777x735 rowH=53
:	ZEDQA rc after override 1.0 root=1 applied=1 char=true 444x420 at 648,0 world=true 444x420 rowH=30
:	ZEDQA rc after override cleared root=1.75 applied=1.75 char=true 777x735 at 1134,0 world=true 777x735 rowH=53
:	ZEDQA rc done
```

### 26. zedqa_scalewalk.lua (`ZEDQA sw`) - PASS, 55 s

- go 14012 at 00:27:35
- screenshots: zedqa_sw_200_char_loot.png, zedqa_sw_200_char_equip.png, zedqa_sw_200_char_health.png, zedqa_sw_200_char_thermal.png, zedqa_sw_200_char_identity.png, zedqa_sw_200_char_journal.png, zedqa_sw_200_char_skills.png, zedqa_sw_200_world_loot.png, zedqa_sw_200_world_craft.png, zedqa_sw_200_world_build.png, zedqa_sw_200_world_furniture.png, zedqa_sw_200_world_maps.png, zedqa_sw_200_world_forage.png, zedqa_sw_200_world_animals.png, zedqa_sw_100_char_loot.png, zedqa_sw_100_char_equip.png, zedqa_sw_100_char_health.png, zedqa_sw_100_char_thermal.png, zedqa_sw_100_char_identity.png, zedqa_sw_100_char_journal.png, zedqa_sw_100_char_skills.png, zedqa_sw_100_world_loot.png, zedqa_sw_100_world_craft.png, zedqa_sw_100_world_build.png, zedqa_sw_100_world_furniture.png, zedqa_sw_100_world_maps.png, zedqa_sw_100_world_forage.png, zedqa_sw_100_world_animals.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA sw armed
:	[ZeD.QA] run #26 ok=true
:	ZEDQA sw char tabs loot,equip,health,thermal,identity,journal,skills
:	ZEDQA sw shot 200 char loot active=loot win=1134,0 777x735
:	ZEDQA sw shot 200 char equip active=equip win=294,0 1617x735
:	ZEDQA sw fit 200 equip: strip ends 63, drawer 63-903, inventory starts 903
:	ZEDQA sw shot 200 char health active=health win=294,0 1617x735
:	ZEDQA sw fit 200 health: strip ends 63, drawer 63-903, inventory starts 903
:	ZEDQA sw shot 200 char thermal active=thermal win=294,0 1617x735
:	ZEDQA sw fit 200 thermal: strip ends 63, drawer 63-903, inventory starts 903
:	ZEDQA sw shot 200 char identity active=identity win=294,0 1617x735
:	ZEDQA sw fit 200 identity: strip ends 63, drawer 63-903, inventory starts 903
:	ZEDQA sw shot 200 char journal active=journal win=294,0 1617x735
:	ZEDQA sw fit 200 journal: strip ends 63, drawer 63-903, inventory starts 903
:	ZEDQA sw shot 200 char skills active=skills win=294,0 1617x735
:	ZEDQA sw fit 200 skills: strip ends 63, drawer 63-903, inventory starts 903
:	ZEDQA sw world tabs loot,craft,build,furniture,maps,forage,animals
:	ZEDQA sw shot 200 world loot active=loot win=1929,0 777x735
:	ZEDQA sw fit 200 loot: container strip ends 63, list starts 63, drawer 714-714, tab strip 714-777, window 777
:	ZEDQA sw shot 200 world craft active=craft win=1929,0 1617x735
:	ZEDQA sw fit 200 craft: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
:	ZEDQA sw shot 200 world build active=build win=1929,0 1617x735
:	ZEDQA sw fit 200 build: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
:	ZEDQA sw shot 200 world furniture active=furniture win=1929,0 1617x735
:	ZEDQA sw fit 200 furniture: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
:	ZEDQA sw shot 200 world maps active=maps win=1929,0 1682x735
:	ZEDQA sw fit 200 maps: container strip ends 63, list starts 63, drawer 714-1619, tab strip 1619-1682, window 1682
:	ZEDQA sw shot 200 world forage active=forage win=1929,0 1617x735
:	ZEDQA sw fit 200 forage: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
:	ZEDQA sw shot 200 world animals active=animals win=1929,0 1617x735
:	ZEDQA sw fit 200 animals: container strip ends 63, list starts 63, drawer 714-1554, tab strip 1554-1617, window 1617
:	ZEDQA sw char tabs loot,equip,health,thermal,identity,journal,skills
:	ZEDQA sw shot 100 char loot active=loot win=1134,0 777x735
:	ZEDQA sw shot 100 char equip active=equip win=654,0 1257x735
:	ZEDQA sw fit 100 equip: strip ends 36, drawer 36-516, inventory starts 516
:	ZEDQA sw shot 100 char health active=health win=654,0 1257x735
:	ZEDQA sw fit 100 health: strip ends 36, drawer 36-516, inventory starts 516
:	ZEDQA sw shot 100 char thermal active=thermal win=654,0 1257x735
:	ZEDQA sw fit 100 thermal: strip ends 36, drawer 36-516, inventory starts 516
:	ZEDQA sw shot 100 char identity active=identity win=654,0 1257x735
:	ZEDQA sw fit 100 identity: strip ends 36, drawer 36-516, inventory starts 516
:	ZEDQA sw shot 100 char journal active=journal win=654,0 1257x735
:	ZEDQA sw fit 100 journal: strip ends 36, drawer 36-516, inventory starts 516
:	ZEDQA sw shot 100 char skills active=skills win=654,0 1257x735
:	ZEDQA sw fit 100 skills: strip ends 36, drawer 36-516, inventory starts 516
:	ZEDQA sw world tabs loot,craft,build,furniture,maps,forage,animals
:	ZEDQA sw shot 100 world loot active=loot win=1929,0 777x735
:	ZEDQA sw fit 100 loot: container strip ends 36, list starts 36, drawer 741-741, tab strip 741-777, window 777
:	ZEDQA sw shot 100 world craft active=craft win=1929,0 1257x735
:	ZEDQA sw fit 100 craft: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
:	ZEDQA sw shot 100 world build active=build win=1929,0 1257x735
:	ZEDQA sw fit 100 build: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
:	ZEDQA sw shot 100 world furniture active=furniture win=1929,0 1257x735
:	ZEDQA sw fit 100 furniture: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
:	ZEDQA sw shot 100 world maps active=maps win=1929,0 1294x735
:	ZEDQA sw fit 100 maps: container strip ends 36, list starts 36, drawer 741-1258, tab strip 1258-1294, window 1294
:	ZEDQA sw shot 100 world forage active=forage win=1929,0 1257x735
:	ZEDQA sw fit 100 forage: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
:	ZEDQA sw shot 100 world animals active=animals win=1929,0 1257x735
:	ZEDQA sw fit 100 animals: container strip ends 36, list starts 36, drawer 741-1221, tab strip 1221-1257, window 1257
:	ZEDQA sw done root=1.75
```

### 27. zedqa_uiscale.lua (`ZEDQA scale`) - PASS, 14 s

- go 14013 at 00:28:36
- screenshots: zedqa_scale_auto.png, zedqa_scale_x150.png, zedqa_scale_x100.png, zedqa_scale_auto_back.png, zedqa_scale_restored.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA scale armed
:	[ZeD.QA] run #27 ok=true
:	ZEDQA scale auto option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=28x28 char=777x735 world=777x735
:	ZEDQA scale x150 option=6 userScale=1.5 root=1.5 iconDrawn=24 iconTex=24x24 char=666x630 world=666x630
:	ZEDQA scale x100 option=4 userScale=1 root=1 iconDrawn=16 iconTex=16x16 char=444x420 world=444x420
:	ZEDQA scale auto_back option=1 userScale=nil root=2 iconDrawn=32 iconTex=32x32 char=888x840 world=888x840
:	ZEDQA scale restored option=7 userScale=1.75 root=1.75 iconDrawn=28 iconTex=28x28 char=777x735 world=777x735
:	ZEDQA scale done
```

### 28. zedqa_mapshot.lua (`ZEDQA ms`) - PASS, 5 s

- go 14014 at 00:28:57
- screenshots: zqa_ms_1.png, zqa_ms_2.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ms start
:	[ZeD.QA] run #28 ok=true
:	ZEDQA ms world 1929,0 1682x735 tab maps
:	ZEDQA ms DONE
```

### 29. zedqa_mapstyles.lua (`ZEDQA mst`) - PASS, 14 s

- go 14015 at 00:29:08
- screenshots: zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mst start
:	[ZeD.QA] run #29 ok=true
:	ZEDQA mst survey: style survey zoom 13 images 2
:	ZEDQA mst color: style color zoom 13 images 2
:	ZEDQA mst paper: style paper zoom 13 images 1
:	ZEDQA mst DONE
```

### 30. zedqa_flyers.lua (`ZEDQA fl`) - PASS, 7 s

- go 14016 at 00:29:28
- screenshots: zqa_fl_1.png, zqa_fl_2.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fl start
:	[ZeD.QA] run #30 ok=true
:	ZEDQA fl read pieces: 14
:	ZEDQA fl piece mccoyloggingcorp
:	ZEDQA fl read now: 15
:	ZEDQA fl forgot true read 14
:	ZEDQA fl DONE
```

### 31. zedqa_flyermap.lua (`ZEDQA fm`) - PASS, 12 s

- go 14017 at 00:29:41
- screenshots: zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fm start
:	[ZeD.QA] run #31 ok=true
:	ZEDQA fm read 16 (added 2)
:	ZEDQA fm tracker ticked the test place: true
:	ZEDQA fm pins on paper: muldraughbakesale, fossoil1(done), ustoreitmuldraugh, sunstarmotel
:	ZEDQA fm hover: sunstarmotel
:	ZEDQA fm reader open true media sunstarmotel title Angel Cross + Sunstar Motel
:	ZEDQA fm flash true
:	ZEDQA fm read back to 14
:	ZEDQA fm DONE
```

### 32. zedqa_mapnotes.lua (`ZEDQA mnote`) - PASS, 9 s

- go 14018 at 00:29:59
- screenshots: zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mnote start
:	[ZeD.QA] run #32 ok=true
:	ZEDQA mnote gave 2 (pencil / eraser)
:	ZEDQA mnote map bound to the world map item: true
:	ZEDQA mnote before: store marks 6 | vanilla api marks 6 of 69 symbols (the rest are the map's own labels)
:	ZEDQA mnote text tool armed: true
:	ZEDQA mnote after note: store 6 -> 7 | vanilla api 6 -> 7 | found in store true | found by vanilla api true
:	ZEDQA mnote note ink 1 rgb 0.200 0.200 0.200 scale 0.6660000085830688 layer text-note
:	ZEDQA mnote star tool armed: true
:	ZEDQA mnote star as vanilla's Star: true ink 1 | store 8
:	ZEDQA mnote migration: first run added 2 (8 -> 10), second 0 (10), flag cleared 0 (10)
:	ZEDQA mnote migrated note ink 4 (want 4) | star ink 3 (want 3) | done flag true
:	ZEDQA mnote cursor finds the note: true
:	ZEDQA mnote cursor ui 452,299 | engine hit note 'ZEDQA note 45930' at world 11991.7,11702.8 ui 451,321 | found note 'ZEDQA note 45930' at world 11991.7,11702.8 ui 451,321 | the note note 'ZEDQA note 45930' at world 11991.7,11702.8 ui 451,321
:	ZEDQA mnote menu: delete true | edit note true | change colour true | share false (multiplayer false)
:	ZEDQA mnote after delete: store 10 -> 9 | vanilla api 10 -> 9 | still found false / false
:	ZEDQA mnote removal: made a note true and a star true | store 9 -> 11
:	ZEDQA mnote removal: note true (11 -> 10), star true (-> 9), stale note again false (-> 9)
:	ZEDQA mnote style paper: map style paper | label layers 8 | strongest label alpha 0 | note hand alpha 255
:	ZEDQA mnote style survey: map style survey | label layers 8 | strongest label alpha 255 | note hand alpha 255
:	ZEDQA mnote style color: map style color | label layers 8 | strongest label alpha 255 | note hand alpha 255
:	ZEDQA mnote style back to survey
:	ZEDQA mnote cleanup: removed 3 marks | store 6 (started 6) | modData back
:	ZEDQA mnote DONE
```

### 33. zedqa_journal_refs.lua (`ZEDQA jr`) - PASS, 5 s

- go 14019 at 00:30:15
- screenshots: zqa_jr_01_diary.png, zqa_jr_02_flyers.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA jr start
:	[ZeD.QA] run #33 ok=true
:	ZEDQA jr DONE
```

### 34. zedqa_journal_readers.lua (`ZEDQA jrd`) - PASS, 22 s

- go 14020 at 00:30:26
- screenshots: zqa_jr_01_papers.png, zqa_jr_02_unread_look.png, zqa_jr_03_read_look.png, zqa_jr_04_notebooks.png, zqa_jr_05_written.png, zqa_jr_06_into.png, zqa_jr_07_logged.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA jrd start
:	[ZeD.QA] run #34 ok=true
:	ZEDQA jrd papers 2 books 1 zones 6
:	ZEDQA jrd unread look zones back,read
:	ZEDQA jrd read look zones back,full,place:1,words
:	ZEDQA jrd note field true page 1
:	ZEDQA jrd light after 1 ticks: tooDark false
:	ZEDQA jrd ok written line on page 1
:	ZEDQA jrd log entry saw 3 of them by the gas station around noon | source Supply runs p1
:	ZEDQA jrd book p1 now day 3. truck still wont start. tried the battery / from the van on 31W, nothing. maybe its the starter / fossoil on the flyer too. go round back / saw 3 of them by the gas station around noon
:	ZEDQA jrd DONE (newspaper had been read before: false)
```

### 35. zedqa_reader.lua (`ZEDQA rd`) - PASS, 11 s

- go 14021 at 00:30:54
- screenshots: zqa_rd_01_paper.png, zqa_rd_02_words.png, zqa_rd_03_story2.png, zqa_rd_04_zoomed.png, zqa_rd_05_flier.png, zqa_rd_06_map.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA rd start
:	[ZeD.QA] run #35 ok=true
:	ZEDQA rd light after 3 ticks: tooDark false
:	ZEDQA rd open true view paper body 27.884615384615387
:	ZEDQA rd words blocks 12
:	ZEDQA rd flier places 1
:	ZEDQA rd map centre 10687,9831
:	ZEDQA rd DONE
```

### 36. zedqa_reader_refs.lua (`ZEDQA rr`) - PASS, 14 s

- go 14022 at 00:31:12
- screenshots: zqa_rr_01_journal_flyers.png, zqa_rr_02_news_card.png, zqa_rr_03_vanilla_news_paper.png, zqa_rr_04_vanilla_news_words.png, zqa_rr_05_vanilla_flier_paper.png, zqa_rr_06_vanilla_flier_words.png, zqa_rr_07_vanilla_journal.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA rr start
:	[ZeD.QA] run #36 ok=true
:	ZEDQA rr items Base.Newspaper:zombie.inventory.types.Literature@587dad26 Base.Flier:zombie.inventory.types.Literature@5d81bfdd Base.Notebook:zombie.inventory.types.Literature@4abaf81a
:	ZEDQA rr DONE
```

### 37. zedqa_notebook.lua (`ZEDQA nb`) - TIMEOUT, 181 s

- go 14023 at 00:31:32
- no DONE within 180 s; the script may still be running in the game

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA nb start
:	[ZeD.QA] run #37 ok=true
:	ZEDQA nb light after 3 ticks: tooDark false
```

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

### 76. zedqa_charinfo.lua (`ZEDQA ci`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 77. zedqa_equipdrag.lua (`ZEDQA eqd`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 78. zedqa_cazio_light.lua (`ZEDQA czl`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 79. zedqa_dashnight.lua (`ZEDQA dnt`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 80. zedqa_testlang.lua (`ZEDQA tlang`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 81. zedqa_safemode.lua (`ZEDQA safe`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

### 82. zedqa_soak.lua (`ZEDQA soak`) - SKIP, not run

- not run: no DONE within 180 s; the script may still be running in the game

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at KahluaThread.flushErrorMessage > expected argument of type ItemBodyLocation, got String
    1x ERROR: General f:N> Lua((MOD:They Knew [B42])).TheyKnew_BodyLocations.lua> Exception thrown  :: java.lang.RuntimeException: expected argument of type ItemBodyLocation, got String at MethodArguments.assertValid(MethodArguments.java:128).
    1x ERROR: General f:N> 20 | 贝雷塔护甲全修复版)).verifyValue> Exception thrown  :: java.lang.RuntimeException: Object tried to call nil in verifyValue at KahluaUtil.fail(KahluaUtil.java:100).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefPropertyStrings> tiledef fileNumber 575 used by more than one mod
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefs > tiledef fileNumber 575 used by more than one mod
    1x ERROR: General f:N> Lua((MOD:Voiced Radio and Tvs)).Init> Exception thrown  :: java.lang.RuntimeException: Object tried to call nil in Init at KahluaUtil.fail(KahluaUtil.java:100).
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "MP5_Aim_Rack.X_Dummy01"
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Cube"
    2x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "MP5_Rack.X_Dummy01"
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Root"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Root"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Prop2_end"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Prop1_end"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "HLPR=RemapSpace"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "HLPR-ChestTransform"
    2x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
