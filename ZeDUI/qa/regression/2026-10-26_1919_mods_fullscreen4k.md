# ZeD-UI regression - 2026-10-26 19:19 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 19:19:25 |
| Finished | 2026-10-26 19:26:23 (6 min 58 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_A.txt (16 scripts) |
| Result | **14/16 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 13688 to 13705 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13704, 13705)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_r3_A.lua | r3A | **FAIL** | 31 | zqa_r3A_1_loot.png, zqa_r3A_2_menu_apple.png, zqa_r3A_3_menu_world.png, zqa_r3A_4_tip_shirt.png, zqa_r3A_5_tip_book.png, zqa_r3A_6_char_equip.png, zqa_r3A_6_char_health.png, zqa_r3A_6_char_skills.png, zqa_r3A_6_char_identity.png, zqa_r3A_7_world_craft.png, zqa_r3A_7_world_build.png, zqa_r3A_7_world_maps.png, zqa_r3A_8_clothingui.png, zqa_r3A_9_tbyw.png, zqa_r3A_10_char_equip_after.png | 4 Java exception(s) in the log |
| 3 | suite_tabs.lua | tabs | PASS | 10 |  |  |
| 4 | suite_verbs.lua | verbs | PASS | 18 |  |  |
| 5 | zedqa_audit_fixes.lua | af | PASS | 3 |  | 35 expected exception(s) ignored (expect=) |
| 6 | zedqa_ctxlist.lua | cl | PASS | 4 | zqa_cl_1.png, zqa_cl_2.png |  |
| 7 | zedqa_onepath.lua | op | PASS | 19 | zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png |  |
| 8 | zedqa_grid.lua | grid | PASS | 6 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 9 | zedqa_sort_groups.lua | sg | PASS | 41 | zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png |  |
| 10 | zedqa_doll.lua | doll | PASS | 8 | zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png |  |
| 11 | zedqa_large.lua | lg | PASS | 8 | zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png |  |
| 12 | zedqa_container_bottom.lua | cb | PASS | 9 | zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png |  |
| 13 | zedqa_container_controls.lua | ct | PASS | 16 | zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png |  |
| 14 | zedqa_put_back.lua | pb | PASS | 33 |  |  |
| 15 | zedqa_food_verbs.lua | fv | PASS | 4 | zqa_fv_smoking.png |  |
| 16 | zedqa_messages.lua | msg | WARN | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=); 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13688 at 19:21:13

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_A.lua (`ZEDQA r3A`) - FAIL, 31 s

- go 13689 at 19:21:17
- 4 Java exception(s) in the log
- screenshots: zqa_r3A_1_loot.png, zqa_r3A_2_menu_apple.png, zqa_r3A_3_menu_world.png, zqa_r3A_4_tip_shirt.png, zqa_r3A_5_tip_book.png, zqa_r3A_6_char_equip.png, zqa_r3A_6_char_health.png, zqa_r3A_6_char_skills.png, zqa_r3A_6_char_identity.png, zqa_r3A_7_world_craft.png, zqa_r3A_7_world_build.png, zqa_r3A_7_world_maps.png, zqa_r3A_8_clothingui.png, zqa_r3A_9_tbyw.png, zqa_r3A_10_char_equip_after.png

```text
[ZeD.QA] windows reset (R)
ZEDQA r3A start
[ZeD.QA] run #2 ok=true
ZEDQA r3A shot zqa_r3A_1_loot.png
ZEDQA r3A ui loot: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@0,0,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3A vanilla loot: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A menu apple:
ZEDQA r3A shot zqa_r3A_2_menu_apple.png
ERROR: General f:774> Lua(Vanilla).closeAll> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in closeAll at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).closeAll(ISContextMenu.lua:276)
    Lua(Vanilla).pcall(spawnpoints.lua:48)
    Lua(Vanilla).closeMenu(spawnpoints.lua:48)
    Lua(Vanilla).label(spawnpoints.lua:85)
    Lua(Vanilla).onTick(spawnpoints.lua:132)
ZEDQA r3A menu shirt:
ERROR: General f:870> Lua(Vanilla).closeAll> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in closeAll at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).closeAll(ISContextMenu.lua:276)
    Lua(Vanilla).pcall(spawnpoints.lua:48)
    Lua(Vanilla).closeMenu(spawnpoints.lua:48)
    Lua(Vanilla).label(spawnpoints.lua:85)
    Lua(Vanilla).onTick(spawnpoints.lua:132)
ZEDQA r3A menu book:
ERROR: General f:966> Lua(Vanilla).closeAll> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in closeAll at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).closeAll(ISContextMenu.lua:276)
    Lua(Vanilla).pcall(spawnpoints.lua:48)
    Lua(Vanilla).closeMenu(spawnpoints.lua:48)
    Lua(Vanilla).label(spawnpoints.lua:85)
    Lua(Vanilla).onTick(spawnpoints.lua:132)
ZEDQA r3A menu bag:
ERROR: General f:1062> Lua(Vanilla).closeAll> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in closeAll at KahluaUtil.fail(KahluaUtil.java:100).
    Lua(Vanilla).closeAll(ISContextMenu.lua:276)
    Lua(Vanilla).pcall(spawnpoints.lua:48)
    Lua(Vanilla).closeMenu(spawnpoints.lua:48)
    Lua(Vanilla).label(spawnpoints.lua:85)
    Lua(Vanilla).onTick(spawnpoints.lua:132)
ZEDQA r3A world menu: Sit on ground, Walk to
ZEDQA r3A shot zqa_r3A_3_menu_world.png
ZEDQA r3A shot zqa_r3A_4_tip_shirt.png
ZEDQA r3A tip shirt 245x96
ZEDQA r3A shot zqa_r3A_5_tip_book.png
ZEDQA r3A tip book 297x79
ZEDQA r3A shot zqa_r3A_6_char_equip.png
ZEDQA r3A shot zqa_r3A_6_char_health.png
ZEDQA r3A shot zqa_r3A_6_char_skills.png
ZEDQA r3A shot zqa_r3A_6_char_identity.png
ZEDQA r3A shot zqa_r3A_7_world_craft.png
ZEDQA r3A shot zqa_r3A_7_world_build.png
ZEDQA r3A shot zqa_r3A_7_world_maps.png
ZEDQA r3A ui tabs walked: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@0,0,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A shot zqa_r3A_8_clothingui.png
ZEDQA r3A ui clothingui: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@0,0,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; myClothingUI@300,300,320x540 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla clothingui: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A shot zqa_r3A_9_tbyw.png
ZEDQA r3A ui tbyw: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@0,0,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; TBYW_Window@1450,760,988x640 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla tbyw: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A shot zqa_r3A_10_char_equip_after.png
ZEDQA r3A ui end: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@0,0,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla end: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A DONE
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 10 s

- go 13690 at 19:21:51

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
ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1682 focusables=19 {map=19}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA tabs done
```

### 4. suite_verbs.lua (`ZEDQA verbs`) - PASS, 18 s

- go 13691 at 19:22:05

```text
[ZeD.QA] windows reset (R)
ZEDQA verbs armed
[ZeD.QA] run #4 ok=true
ZEDQA worn=Belt ctx=equipped
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP pEq=false ctx=inventory (expect inventory)
ZEDQA fire EQUIP ok=true err=nil qhead=ISWearClothing
ZEDQA after EQUIP pEq=true ctx=equipped (expect equipped)
ZEDQA fire READ ok=true err=nil qhead=ISReadABook
ZEDQA after READ qhead=ISReadABook (expect ISReadABook)
ZEDQA fire EQUIP ok=true err=nil qhead=ISEquipWeaponAction
ZEDQA after EQUIP bat primary=Baseball Bat ctx=equipped (expect equipped)
ZEDQA fire UNEQUIP ok=true err=nil qhead=ISUnequipAction
ZEDQA after UNEQUIP bat primary=nil (expect nil)
ZEDQA fire EAT ok=true err=nil qhead=ISEatFoodAction
ZEDQA after EAT qhead=ISEatFoodAction (expect ISEatFoodAction)
ZEDQA fire DROP ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after DROP cont=floor ctx=ground (expect floor/ground)
ZEDQA fire TAKE ok=true err=nil qhead=ISInventoryTransferAction
ZEDQA after TAKE inInv=true ctx=inventory (expect inventory)
ZEDQA verbs done
```

### 5. zedqa_audit_fixes.lua (`ZEDQA af`) - PASS, 3 s

- go 13692 at 19:22:27
- 35 expected exception(s) ignored (expect=)

```text
[ZeD.QA] windows reset (R)
ZEDQA af start
[ZeD.QA] run #5 ok=true
ERROR: General f:5584> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5586> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5587> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5588> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5590> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5592> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5594> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5596> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5597> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5599> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5601> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5603> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5605> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5607> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5609> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5611> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5613> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5615> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5617> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5619> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5621> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5623> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5625> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5627> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5628> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5630> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5631> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5632> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5634> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5635> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5637> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5639> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5640> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5641> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
    Lua((MOD:ZeD-GUI)).guard(SafeMode.lua:283)
    Lua((MOD:ZeD-GUI)).prerender(ZeD_Panel.lua:78)
ERROR: General f:5642> Lua(Vanilla).renderPapers> Exception thrown   (expected)
    se.krka.kahlua.vm.KahluaException: QA: a tab that throws at BaseLib.error(BaseLib.java:307).
    Lua(Vanilla).renderPapers(worldmap-annotations.lua:27)
    Lua((MOD:ZeD-GUI)).render(JournalTab.lua:1076)
    Lua((MOD:ZeD-GUI))._onPrerender(ZeD_CharacterWindow.lua:4577)
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

### 6. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 4 s

- go 13693 at 19:22:33
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #6 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Auto Loot Item Type, Move to, |, Craft, Set to be Unusable in Recipes, |, Drop all (Category), Drop all on the floor (Category), Drop, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 7. zedqa_onepath.lua (`ZEDQA op`) - PASS, 19 s

- go 13694 at 19:22:41
- screenshots: zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png

```text
[ZeD.QA] windows reset (R)
ZEDQA op start
[ZeD.QA] run #7 ok=true
ZEDQA op crate ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@b20f3d7] type crate
ZEDQA op world select crate true
ZEDQA op apple menu: Eat, |, Place Item, Favorite, Set Unwanted, Auto Loot Item Type, Move to, |, Craft, Set to be Unusable in Recipes, |, Drop all (Category), Drop all on the floor (Category), Drop, |, Rename
ZEDQA op move to: Crate, Floor
ZEDQA op picked Crate
ZEDQA op apple now in crate
ZEDQA op hammer menu: Attach, Claw Hammer, Place Item, Put in Container (Crate), Favorite, Set Unwanted, Auto Loot Item Type, Move to, |, Craft, Set to be Unusable in Recipes, Show Build Recipes Used In, |, Equip Primary, Equip Secondary, |, Drop all (Category), Drop all on the floor (Category), Drop, |, Rename
ZEDQA op prompt true entry Claw Hammer
ZEDQA op hammer name: Old Faithful custom true
ZEDQA op card els: hverb_1, hverb_2, name_row, toggle_fav, toggle_protect, toggle_unwanted, verb_repair
ZEDQA op dbl: first false second true
ZEDQA op primary: true
ZEDQA op crate menu: Crate, Gardening, Sit on ground, Walk to, Container Options, Container Auto Loot Active, |, Disassemble, |, Take All
ZEDQA op take all pressed
ZEDQA op crate left: 0 apple home true
ZEDQA op bottle verbs: Drink, More
ZEDQA op knife maint: repair, sharpen sharp 0.4000000059604645
ZEDQA op nocraft on true off false
ZEDQA op DONE
```

### 8. zedqa_grid.lua (`ZEDQA grid`) - PASS, 6 s

- go 13695 at 19:23:04
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #8 ok=true
ZEDQA grid grid on: cell 91 | cells placed 14 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Angel Cross's Key Ring
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Apple (Fresh)
ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:8 item=Fanny Pack
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Apple (Fresh)
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Angel Cross's Key Ring
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 9. zedqa_sort_groups.lua (`ZEDQA sg`) - PASS, 41 s

- go 13696 at 19:23:13
- screenshots: zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sg start
[ZeD.QA] run #9 ok=true
ZEDQA sg no pickup in the loaded cell; spawned one beside the character: true
ZEDQA sg pack worn at base:back: true
ZEDQA sg given: bag 23, pack 8, bed 19, floor 11
ZEDQA sg floor container things 11 | char window true world window true
ZEDQA sg columns at start: char 0 world 0
ZEDQA sg mode single:
ZEDQA sg single list cat char: columns 1 rows 31 headers 8 order ok pad 31 (charMainInv=31) grid false sort cat/true
ZEDQA sg single list cat world: columns 1 rows 9 headers 8 order ok pad 9 (worldMainInv=9) grid false sort cat/true
ZEDQA sg single list name char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/true
ZEDQA sg single list name world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort name/true
ZEDQA sg single list cond char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort cond/true
ZEDQA sg single list cond world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort cond/true
ZEDQA sg single list wt char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort wt/true
ZEDQA sg single list wt world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort wt/true
ZEDQA sg single list name rev char: columns 1 rows 31 headers 0 order ok pad 31 (charMainInv=31) grid false sort name/false
ZEDQA sg single list name rev world: columns 1 rows 9 headers 0 order ok pad 9 (worldMainInv=9) grid false sort name/false
ZEDQA sg fold char: Accessory folded, rows 30 of 31, its header true
ZEDQA sg fold world: BeverageWater folded, rows 8 of 9, its header true
ZEDQA sg fold char on Name: rows 31 headers 0
ZEDQA sg fold world on Name: rows 9 headers 0
ZEDQA sg fold char back on Category: still folded true rows 30
ZEDQA sg fold world back on Category: still folded true rows 8
ZEDQA sg stack char: Base.Apple x12 open, rows 42 of 31 (+11 expected), children follow true, headers 0
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
ZEDQA sg multi list cat char: columns 2 rows 8+31 headers 16 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cat/true
ZEDQA sg multi list cat world: columns 2 rows 14+9 headers 14 order ok pad 23 (worldMC1=14,worldMainInv=9) grid false sort cat/true
ZEDQA sg multi list name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/true
ZEDQA sg multi list name world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid false sort name/true
ZEDQA sg multi list cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort cond/true
ZEDQA sg multi list cond world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid false sort cond/true
ZEDQA sg multi list wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort wt/true
ZEDQA sg multi list wt world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid false sort wt/true
ZEDQA sg multi list name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid false sort name/false
ZEDQA sg multi list name rev world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid false sort name/false
ZEDQA sg multi grid cat char: columns 2 rows 8+31 headers 10 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cat/true
ZEDQA sg multi grid cat world: columns 2 rows 14+9 headers 10 order ok pad 23 (worldMC1=14,worldMainInv=9) grid true sort cat/true
ZEDQA sg multi grid name char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/true
ZEDQA sg multi grid name world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid true sort name/true
ZEDQA sg multi grid cond char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort cond/true
ZEDQA sg multi grid cond world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid true sort cond/true
ZEDQA sg multi grid wt char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort wt/true
ZEDQA sg multi grid wt world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid true sort wt/true
ZEDQA sg multi grid name rev char: columns 2 rows 8+31 headers 0 order ok pad 39 (charMC1=8,charMainInv=31) grid true sort name/false
ZEDQA sg multi grid name rev world: columns 2 rows 14+9 headers 0 order ok pad 23 (worldMC1=14,worldMainInv=9) grid true sort name/false
ZEDQA sg columns off: char:true world:true
ZEDQA sg restored: bag things 57 (were 57), bed 2, world things on the square 0, floor container 0
ZEDQA sg all checks held; DONE
```

### 10. zedqa_doll.lua (`ZEDQA doll`) - PASS, 8 s

- go 13697 at 19:23:58
- screenshots: zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA doll start
[ZeD.QA] run #10 ok=true
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

### 11. zedqa_large.lua (`ZEDQA lg`) - PASS, 8 s

- go 13698 at 19:24:09
- screenshots: zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png

```text
[ZeD.QA] windows reset (R)
ZEDQA lg start
[ZeD.QA] run #11 ok=true
ZEDQA lg small: rowH 53 buttonH 46 titleBarH 46 | cat 151 wt 81 | equip slot col 140
ZEDQA lg large: rowH 60 buttonH 53 titleBarH 53 | cat 176 wt 93 | equip slot col 163
ZEDQA lg size back to small | DONE
```

### 12. zedqa_container_bottom.lua (`ZEDQA cb`) - PASS, 9 s

- go 13699 at 19:24:21
- screenshots: zqa_cb_01_rows_at_bottom.png, zqa_cb_02_list_end.png, zqa_cb_03_pad_take_all.png, zqa_cb_04_campfire_ribbon.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cb start
[ZeD.QA] run #12 ok=true
ZEDQA cb no pickup in the loaded cell; spawned one beside the character: true
ZEDQA cb bed selected true
ZEDQA cb world list 651x664, row 49 at y 615
ZEDQA cb campfire selected true
ZEDQA cb DONE
```

### 13. zedqa_container_controls.lua (`ZEDQA ct`) - PASS, 16 s

- go 13700 at 19:24:34
- screenshots: zqa_ct_01_rows.png, zqa_ct_02_pad_same_type.png, zqa_ct_03_after_take_all.png, zqa_ct_04_floor_row.png, zqa_ct_05_campfire_row.png, zqa_ct_06_add_fuel_card.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ct start
[ZeD.QA] run #13 ok=true
ZEDQA ct no pickup in the loaded cell; spawned one beside the character: true
ZEDQA ct pickup true
ZEDQA ct bed selected true
ZEDQA ct your row: Transfer all, Same type, Same type, all nearby, |, Auto Loot OFF, Store All
ZEDQA ct world row: Take all, Same type, To floor
ZEDQA ct start: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct focused worldCtl:same prompt Take the kinds you already carry
ZEDQA ct marked rows (things) 7
ZEDQA ct no button Same type
ZEDQA ct after Same type (take): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct no button Same type
ZEDQA ct after Same type (back): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct no button Take all
ZEDQA ct after Take all: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct no button Transfer all
ZEDQA ct after Transfer all: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct no button To floor
ZEDQA ct after To floor: bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct floor selected true
ZEDQA ct floor row: Take all(off), Same type(off)
ZEDQA ct no button Take all
ZEDQA ct after Take all (floor): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct no button Transfer all
ZEDQA ct after Transfer all (back to the bed): bag nails 2 planks 1 | bed nails 3 planks 4 beans 2, 25 things | floor 0
ZEDQA ct campfire placed true true
ZEDQA ct campfire container true selected true
ZEDQA ct campfire row: Take all(off), Same type(off), To floor(off), |, Take apart, Light, Add fuel
ZEDQA ct no button Add fuel
ZEDQA ct after Add fuel: object card false jump nil
ZEDQA ct no button Take apart
ZEDQA ct after Take apart: campfire still there true
ZEDQA ct restored: bag nails 0 planks 0 | bed nails 0 planks 0 beans 0, 14 things | floor 0
ZEDQA ct DONE
```

### 14. zedqa_put_back.lua (`ZEDQA pb`) - PASS, 33 s

- go 13701 at 19:24:53

```text
[ZeD.QA] windows reset (R)
ZEDQA pb start
[ZeD.QA] run #14 ok=true
ZEDQA pb PASS the switch is on
ZEDQA pb the bag: Fanny Pack; hands: nil / nil
ZEDQA pb PASS a worn bag to take things from
ZEDQA pb apple: queue empty true, the apple is in bag; put back queued 0
ZEDQA pb PASS half an apple: the rest went back into the bag
ZEDQA pb PASS half an apple: the game put it back itself, ZeD moved nothing twice
ZEDQA pb smoke: queue empty true, the lighter is in bag, the cigarette in nowhere
ZEDQA pb PASS a cigarette: the lighter went back into the bag
ZEDQA pb drink: thirst 0.40, the bottle holds 0.80
ZEDQA pb drink look 1: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 2: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 3: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 4: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 5: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 6: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 7: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink look 8: ISDrinkFromBottle; the bottle in main, holds 0.80
ZEDQA pb drink: queue empty true, the bottle is in bag
ZEDQA pb PASS a drink: the bottle went back into the bag
ZEDQA pb no deep-run car within 10 tiles: the tire scene is skipped
ZEDQA pb stopped: the apple is in main
ZEDQA pb PASS stopped halfway: the apple stays on you
ZEDQA pb switch off: the bottle is in main
ZEDQA pb PASS the switch off: the bottle stays on you
ZEDQA pb put back: the switch 1 (was 1)
ZEDQA pb all checks passed
ZEDQA pb DONE
```

### 15. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 4 s

- go 13702 at 19:25:30
- screenshots: zqa_fv_smoking.png

```text
[ZeD.QA] windows reset (R)
ZEDQA fv start
[ZeD.QA] run #15 ok=true
ZEDQA fv Cigarette: the card's main button reads Smoke (id EAT)
ZEDQA fv PASS Cigarette: the card says Smoke
ZEDQA fv Apple: the card's main button reads Eat (id EAT)
ZEDQA fv PASS Apple: the card says Eat
ZEDQA fv Canned Evaporated Milk (Open): the card's main button reads Drink (id EAT)
ZEDQA fv PASS Canned Evaporated Milk (Open): the card says Drink
ZEDQA fv smoking: the action is ISEatFoodAction, the bar reads SMOKING
ZEDQA fv PASS smoking: the bar says SMOKING
ZEDQA fv eating: the action is ISEatFoodAction, the bar reads EATING
ZEDQA fv PASS an apple: the bar still says EATING
ZEDQA fv all checks passed
ZEDQA fv DONE
```

### 16. zedqa_messages.lua (`ZEDQA msg`) - WARN, 11 s

- go 13703 at 19:25:37
- 1 expected exception(s) ignored (expect=)
- 1 ERR line(s)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #16 ok=true
ZEDQA msg FAIL nothing kept: no envelope on the belt
ZEDQA msg PASS the three notes are not on screen
ZEDQA msg PASS the three notes are kept in Messages
ZEDQA msg PASS the source has three messages (3)
ZEDQA msg PASS three are new (3)
ZEDQA msg PASS a toast names the mod
ZEDQA msg PASS the game runs on after the mod paused it for its note (speed 1)
ZEDQA msg PASS the envelope is on the belt
ZEDQA msg PASS a question still asks at once
ZEDQA msg PASS the mod got its answer (YES)
ZEDQA msg PASS a copy of the question, already read, is in Messages
ERROR: General f:17596 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:17596> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:99)
ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
ZEDQA msg PASS Messages opens on the mod
ZEDQA msg PASS opening it marks the mod's messages read
ZEDQA msg PASS four cards: three notes and the question (4)
ZEDQA msg PASS three OK buttons, one per note (3)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg PASS A on the next card's OK ran its callback
ZEDQA msg PASS the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (1446 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg PASS the last unanswered note got its OK as it left
ZEDQA msg 1 failed
ZEDQA msg DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Wooden Barrel', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fermentation Pot', name may not contain whitespaces.
    2x ERROR: General f:N> Lua(Vanilla).addModOptionsPanel> Exception thrown  :: java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
