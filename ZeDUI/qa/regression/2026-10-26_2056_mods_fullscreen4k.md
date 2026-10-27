# ZeD-UI regression - 2026-10-26 20:56 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 20:56:57 |
| Finished | 2026-10-26 21:04:49 (7 min 51 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_F.txt (17 scripts) |
| Result | **13/17 pass**, 2 warn, 2 fail, 0 timeout |
| Go numbers | 13787 to 13805 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13804, 13805)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_r3_F.lua | r3F | **FAIL** | 43 | zqa_r3F_1_loot.png, zqa_r3F_2_menu_apple.png, zqa_r3F_3_menu_world.png, zqa_r3F_4_tip_shirt_zed.png, zqa_r3F_5_tip_shirt_safe.png, zqa_r3F_4_tip_book_zed.png, zqa_r3F_5_tip_book_safe.png, zqa_r3F_4_tip_vhs_zed.png, zqa_r3F_5_tip_vhs_safe.png, zqa_r3F_4_tip_seed_zed.png, zqa_r3F_5_tip_seed_safe.png, zqa_r3F_6_char_equip.png, zqa_r3F_6_char_health.png, zqa_r3F_6_char_skills.png, zqa_r3F_6_char_identity.png, zqa_r3F_7_world_craft.png, zqa_r3F_7_world_build.png, zqa_r3F_7_world_maps.png, zqa_r3F_8_clothing_radial.png, zqa_r3F_9_smart_radial.png, zqa_r3F_10_belt.png | 1 Java exception(s) in the log; 1 ERR line(s) |
| 3 | suite_tabs.lua | tabs | PASS | 11 |  |  |
| 4 | suite_verbs.lua | verbs | PASS | 17 |  |  |
| 5 | zedqa_ctxlist.lua | cl | PASS | 4 | zqa_cl_1.png, zqa_cl_2.png |  |
| 6 | zedqa_onepath.lua | op | **FAIL** | 17 | zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png | 1 Java exception(s) in the log; 1 ERR line(s) |
| 7 | zedqa_belt_hands.lua | bh | PASS | 4 | zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png |  |
| 8 | zedqa_buckle.lua | bk | PASS | 5 | zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png |  |
| 9 | zedqa_beltwatch.lua | bw | PASS | 12 | zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png |  |
| 10 | zedqa_belt_strap.lua | belt | PASS | 2 | zqa_belt_strap_1.png |  |
| 11 | zedqa_straps.lua | straps | PASS | 11 | zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png |  |
| 12 | zedqa_wheel_sizes.lua | ws | PASS | 15 | zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png |  |
| 13 | zedqa_wheels.lua | wh | PASS | 25 | zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png |  |
| 14 | zedqa_dpad_wheels.lua | dw | PASS | 45 | zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png |  |
| 15 | zedqa_quick_chords.lua | qc | WARN | 22 | zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png | 1 ERR line(s) |
| 16 | zedqa_put_back.lua | pb | PASS | 34 |  |  |
| 17 | zedqa_messages.lua | msg | WARN | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=); 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13787 at 20:58:39

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_F.lua (`ZEDQA r3F`) - FAIL, 43 s

- go 13788 at 20:58:43
- 1 Java exception(s) in the log
- 1 ERR line(s)
- screenshots: zqa_r3F_1_loot.png, zqa_r3F_2_menu_apple.png, zqa_r3F_3_menu_world.png, zqa_r3F_4_tip_shirt_zed.png, zqa_r3F_5_tip_shirt_safe.png, zqa_r3F_4_tip_book_zed.png, zqa_r3F_5_tip_book_safe.png, zqa_r3F_4_tip_vhs_zed.png, zqa_r3F_5_tip_vhs_safe.png, zqa_r3F_4_tip_seed_zed.png, zqa_r3F_5_tip_seed_safe.png, zqa_r3F_6_char_equip.png, zqa_r3F_6_char_health.png, zqa_r3F_6_char_skills.png, zqa_r3F_6_char_identity.png, zqa_r3F_7_world_craft.png, zqa_r3F_7_world_build.png, zqa_r3F_7_world_maps.png, zqa_r3F_8_clothing_radial.png, zqa_r3F_9_smart_radial.png, zqa_r3F_10_belt.png

```text
[ZeD.QA] windows reset (R)
ZEDQA r3F start
[ZeD.QA] run #2 ok=true
ZEDQA r3F shot zqa_r3F_1_loot.png
ZEDQA r3F ui loot: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,454x82 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3F vanilla loot: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3F menu apple: Eat, Drop, Place Item, More, ContextMenu_WhatCanICraft, Adjust attachment position [DEV: hors slot PAR], Hide Equipped Items, Move to, Rename
ZEDQA r3F shot zqa_r3F_2_menu_apple.png
ZEDQA r3F menu shirt: Auto Rip: Shirt - Formal, Auto Rip: everything within reach, Train Tailoring, Wear, Rip Clothing, Craft, Inspect, Drop, Place Item, More, ContextMenu_WhatCanICraft, Adjust attachment position [DEV: hors slot PAR], Rip Clothing, Hide Equipped Items, Move to, Rename
ZEDQA r3F menu book: Read Everything Automatically, Equip Primary, Equip Secondary, Read, Craft, Drop, Place Item, More, ContextMenu_WhatCanICraft, Adjust attachment position [DEV: hors slot PAR], Hide Equipped Items, Move to, Rename
ZEDQA r3F menu bag: Wear, Equip Primary, Equip Secondary, Drop, Place Item, More, ContextMenu_WhatCanICraft, Add Attachment Slot, Adjust attachment position [DEV: hors slot PAR], Hide Equipped Items, Move to
ZEDQA r3F world menu: Cheat Menu: PX, |, Area Tasks, Sit on ground, Walk to, Debug: alarm panel preview
ZEDQA r3F shot zqa_r3F_3_menu_world.png
ZEDQA r3F shot zqa_r3F_4_tip_shirt_zed.png
ZEDQA r3F tip shirt zed 238x96
ZEDQA r3F shot zqa_r3F_5_tip_shirt_safe.png
ZEDQA r3F tip shirt safe 238x93
ZEDQA r3F shot zqa_r3F_4_tip_book_zed.png
ZEDQA r3F tip book zed 297x79
ZEDQA r3F shot zqa_r3F_5_tip_book_safe.png
ZEDQA r3F tip book safe 297x76
ZEDQA r3F shot zqa_r3F_4_tip_vhs_zed.png
ZEDQA r3F tip vhs zed 189x45
ZEDQA r3F shot zqa_r3F_5_tip_vhs_safe.png
ZEDQA r3F tip vhs safe 189x42
ZEDQA r3F shot zqa_r3F_4_tip_seed_zed.png
ZEDQA r3F tip seed zed 202x79
ZEDQA r3F shot zqa_r3F_5_tip_seed_safe.png
ZEDQA r3F tip seed safe 202x76
ZEDQA r3F ui after safe mode: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,994x82 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3F vanilla after safe mode: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3F shot zqa_r3F_6_char_equip.png
ZEDQA r3F shot zqa_r3F_6_char_health.png
ZEDQA r3F shot zqa_r3F_6_char_skills.png
ZEDQA r3F shot zqa_r3F_6_char_identity.png
ZEDQA r3F shot zqa_r3F_7_world_craft.png
ZEDQA r3F shot zqa_r3F_7_world_build.png
ZEDQA r3F shot zqa_r3F_7_world_maps.png
ZEDQA r3F ui tabs walked: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,994x82 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3F vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3F note: CARadialMenu missing
ZEDQA r3F shot zqa_r3F_8_clothing_radial.png
ZEDQA r3F ui clothing radial: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,994x82 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3F vanilla clothing radial: inventory page shown false, loot page shown false, info panel shown false
ERROR: General f:2141> Lua((MOD:Smart Radial Menu)).getSliceTooltipUnderMouseFocus> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getSliceTooltipUnderMouseFocus at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Smart Radial Menu)).getSliceTooltipUnderMouseFocus(SRMOverlay.lua:420)
    Lua((MOD:Smart Radial Menu)).updateSelectedSlice(SRMOverlay.lua:870)
    Lua((MOD:Smart Radial Menu)).resetValues(SRMOverlay.lua:890)
    Lua((MOD:Smart Radial Menu)).display(SRMOverlay.lua:895)
    Lua((MOD:Smart Radial Menu)).addToUIManager(SRMMenuObject.lua:629)
ZEDQA r3F ERR step srm radial: Object tried to call nil in getSliceTooltipUnderMouseFocus java.lang.RuntimeException
ZEDQA r3F shot zqa_r3F_9_smart_radial.png
ZEDQA r3F ui smart radial: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,994x82 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; SRMMenuObject@1604,764,632x632 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3F vanilla smart radial: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3F ui belt items: ZeD_ActionBarLayer@1846,921,178x92 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1336,2040,955x92 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; SRMMenuObject@1604,764,632x632 ; ZeD_MessagesToasts@3122,263,595x53
ZEDQA r3F vanilla belt items: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3F shot zqa_r3F_10_belt.png
ZEDQA r3F ui end: ZeD_ActionBarLayer@1846,921,178x92 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; SRMMenuObject@1604,764,632x632 ; ZeD_MessagesToasts@3122,263,595x53
ZEDQA r3F vanilla end: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3F DONE
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 11 s

- go 13789 at 20:59:29

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
ZEDQA char tab=skills active=skills w=1617 focusables=62 {skill=36 skills=1 training=25}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1682 focusables=19 {map=19}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA tabs done
```

### 4. suite_verbs.lua (`ZEDQA verbs`) - PASS, 17 s

- go 13790 at 20:59:44

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

### 5. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 4 s

- go 13791 at 21:00:05
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #5 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Adjust attachment position [DEV: hors slot PAR], Move to, |, Set to be Unusable in Recipes, ContextMenu_WhatCanICraft, |, Hide Equipped Items, |, Drop, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 6. zedqa_onepath.lua (`ZEDQA op`) - FAIL, 17 s

- go 13792 at 21:00:12
- 1 Java exception(s) in the log
- 1 ERR line(s)
- screenshots: zqa_op_1.png, zqa_op_2.png, zqa_op_3.png, zqa_op_4.png

```text
[ZeD.QA] windows reset (R)
ZEDQA op start
[ZeD.QA] run #6 ok=true
ZEDQA op crate ItemContainer:[type:crate, parent:null:carpentry_01_16:carpentry_01_16:zombie.iso.IsoObject@765bdf95] type crate
ZEDQA op world select crate false
ZEDQA op apple menu: Eat, |, Place Item, Favorite, Adjust attachment position [DEV: hors slot PAR], Move to, |, Set to be Unusable in Recipes, ContextMenu_WhatCanICraft, |, Hide Equipped Items, |, Drop, |, Rename
ZEDQA op move to: Crate, Floor
ZEDQA op picked Crate
ZEDQA op apple now in crate
ZEDQA op hammer menu: Attach, Claw Hammer, Place Item, Favorite, Adjust attachment position [DEV: hors slot PAR], Move to, |, Craft, Set to be Unusable in Recipes, Show Build Recipes Used In, ContextMenu_WhatCanICraft, |, Equip Primary, Equip Secondary, Hide Equipped Items, |, Drop, |, Rename
ZEDQA op prompt true entry Claw Hammer
ZEDQA op hammer name: Old Faithful custom true
ZEDQA op card els: hverb_1, hverb_2, name_row, toggle_fav, toggle_protect, toggle_unwanted, verb_repair
ERROR: General f:7346> 8))).doContextualDblClick> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in doContextualDblClick at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Quick Item Action (v0.0.8))).doContextualDblClick(QuickItemAction.lua:140)
    Lua((MOD:ZeD-GUI)).quickUse(InventoryRenderer.lua:442)
    Lua((MOD:ZeD-GUI)).doubleClick(InventoryRenderer.lua:429)
    Lua(Vanilla).at(worldmap-annotations.lua:109)
    Lua(Vanilla).onTick(worldmap-annotations.lua:161)
ZEDQA op ERR 530 Object tried to call nil in doContextualDblClick java.lang.RuntimeException
ZEDQA op primary: false
ZEDQA op crate menu:
ZEDQA op crate left: 3 apple home false
ZEDQA op bottle verbs: Drink, More
ZEDQA op knife maint: repair, sharpen sharp 0.4000000059604645
ZEDQA op nocraft on true off false
ZEDQA op DONE
```

### 7. zedqa_belt_hands.lua (`ZEDQA bh`) - PASS, 4 s

- go 13793 at 21:00:33
- screenshots: zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bh start
[ZeD.QA] run #7 ok=true
ZEDQA bh PASS left wrist: the boxes run left to right (watch@0 OFF@102 #1@232 #2@328 #3@424 #4@667 MAIN@783 lamp@888)
ZEDQA bh PASS left wrist: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh PASS left wrist: the Messages note is last on the right
ZEDQA bh PASS left wrist: the watch is left of the off hand
ZEDQA bh PASS left wrist: the full watch pops at the left end (left)
ZEDQA bh PASS pad: the belt starts on slot 1 (#1)
ZEDQA bh PASS pad: Left from slot 1 is the off hand (OFF)
ZEDQA bh PASS right wrist: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@565 MAIN@681 watch@786 lamp@888)
ZEDQA bh PASS right wrist: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh PASS right wrist: the Messages note is last on the right
ZEDQA bh PASS right wrist: the watch is right of the main hand
ZEDQA bh PASS right wrist: the full watch pops at the right end (right)
ZEDQA bh PASS as worn: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@565 MAIN@681 lamp@786)
ZEDQA bh PASS as worn: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh PASS as worn: the Messages note is last on the right
ZEDQA bh all checks passed
ZEDQA bh DONE
```

### 8. zedqa_buckle.lua (`ZEDQA bk`) - PASS, 5 s

- go 13794 at 21:00:41
- screenshots: zqa_bk_1.png, zqa_bk_2.png, zqa_bk_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bk start
[ZeD.QA] run #8 ok=true
ZEDQA bk centre 1920 vs screen 1920 | belt x 1438 w 853 | delta 0 | bare watch none
ZEDQA bk worn zwatchslots:leftwatch
ZEDQA bk centre 1920 vs screen 1920 | belt x 1336 w 955 | delta 0 | cazio watch digital_black wrist left
ZEDQA bk worn zwatchslots:rightwatch
ZEDQA bk centre 1920 vs screen 1920 | belt x 1438 w 955 | delta 0 | timez watch timez_easy wrist right
ZEDQA bk DONE
```

### 9. zedqa_beltwatch.lua (`ZEDQA bw`) - PASS, 12 s

- go 13795 at 21:00:49
- screenshots: zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bw start
[ZeD.QA] run #9 ok=true
ZEDQA bw worn zwatchslots:leftwatch
ZEDQA bw box digital_black wrist left x 0 w 88 | hands s@102 p@783 | belt w 955
ZEDQA bw full watch tucked: 0x0
ZEDQA bw popped true at 1336,1674 248x352 | mini at 1336,2040
ZEDQA bw dragged to 1500,500 saved 857.1428571428571,285.7142857142857
ZEDQA bw after idle: popped true size 248
ZEDQA bw right wrist: timez_easy wrist right x 786 | hands s@0 p@681
ZEDQA bw corner: box false full watch 3524,10 300x352
ZEDQA bw DONE
```

### 10. zedqa_belt_strap.lua (`ZEDQA belt`) - PASS, 2 s

- go 13796 at 21:01:05
- screenshots: zqa_belt_strap_1.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #10 ok=true
ZEDQA belt textures true
ZEDQA belt shot; DONE
```

### 11. zedqa_straps.lua (`ZEDQA straps`) - PASS, 11 s

- go 13797 at 21:01:10
- screenshots: zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #11 ok=true
ZEDQA straps put aside 2
ZEDQA straps civilian worn HolsterSimple_Brown,Belt2,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim
ZEDQA straps civilian slots Back=sling HolsterRight=holster_brown SmallBeltLeft=leather SmallBeltRight=leather | waist=leather closure=buckle
ZEDQA straps civilian shot
ZEDQA straps military worn Holster_DuctTape,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus_Camo,Bag_ALICEpack_Army
ZEDQA straps military slots Back=webbing_olive HolsterRight=holster_tape SmallBeltLeft=webbing_camo SmallBeltRight=webbing_camo WebbingRight=webbing_camo WebbingLeft=webbing_camo BedrollBottomALICE=webbing_olive | waist=webbing_camo closure=clip_black
ZEDQA straps military shot
ZEDQA straps makeshift worn Holster_Hide,RopeBelt,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_CraftedFramepack_Large
ZEDQA straps makeshift slots Back=rope HolsterRight=holster_hide SmallBeltLeft=rope BedrollBottom=rope | waist=rope closure=knot
ZEDQA straps makeshift shot
ZEDQA straps firefighter worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,SCBA
ZEDQA straps firefighter slots Back=harness SmallBeltLeft=harness SmallBeltRight=harness WebbingLeft=harness | waist=harness closure=clip_black
ZEDQA straps firefighter shot
ZEDQA straps olive worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus
ZEDQA straps olive slots Back=sling SmallBeltLeft=webbing_olive SmallBeltRight=webbing_olive WebbingLeft=webbing_olive WebbingRight=webbing_olive | waist=webbing_olive closure=clip_brass
ZEDQA straps olive shot
ZEDQA straps restored; DONE
```

### 12. zedqa_wheel_sizes.lua (`ZEDQA ws`) - PASS, 15 s

- go 13798 at 21:01:25
- screenshots: zqa_ws_a_gun3.png, zqa_ws_b_dright3.png, zqa_ws_c_emotes5.png, zqa_ws_d_signal9.png, zqa_ws_e_back10.png, zqa_ws_g_car11.png, zqa_ws_h_car11pt.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ws no pickup within 20 tiles; spawned one beside the character: true
[ZeD.QA] run #12 ok=true
ZEDQA ws a_gun3 n=3 r=49 w=600
ZEDQA ws b_dright3 n=3 r=49 w=600
ZEDQA ws c_emotes5 n=6 r=57 w=616
ZEDQA ws d_signal9 n=9 r=83 w=668
ZEDQA ws e_back10 n=10 r=92 w=686
ZEDQA ws g_car11 n=11 r=101 w=704
ZEDQA ws h_car11pt n=11 r=101 w=704
ZEDQA ws done
```

### 13. zedqa_wheels.lua (`ZEDQA wh`) - PASS, 25 s

- go 13799 at 21:01:43
- screenshots: zqa_wh_01_outside.png, zqa_wh_02_inside.png, zqa_wh_03_inside_point.png, zqa_wh_04_inside_off.png, zqa_wh_05_emotes.png, zqa_wh_06_signal.png, zqa_wh_07_signal_point.png, zqa_wh_08_gun.png, zqa_wh_09_light.png, zqa_wh_10_back.png, zqa_wh_11_dright.png, zqa_wh_12_zone_route.png, zqa_wh_13_search_route.png, zqa_wh_14_playerinfo_route.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wh no pickup within 20 tiles; spawned one beside the character: true
ZEDQA wh start car=BaseVehicle{ Name:null, ID:6 } pistol=nil torch=Base.HandTorch:zombie.inventory.types.DrainableComboItem@2edb7536
[ZeD.QA] run #13 ok=true
ZEDQA wh outside zed=true java=UIElement n=0 x=1568 y=728 w=704 vis=false point=-1 title=nil |
ZEDQA wh inside zed=true java=UIElement n=11 x=1568 y=728 w=704 vis=false point=-1 title=nil | 1:Switch Seat 2:No key. You need/Electrical level 1 and/Mechanics level 2/to hotwire.[off] 3:Turn Headlights on 4:Turn AC/Heater on 5:Horn 6:Device Options 7:Open Window 8:Lock all doors 9:Vehicle Mechanics 10:Not tired enough to sleep.[off] 11:Exit Vehicle
ZEDQA wh pick test slice3 from mouse -> 3
ZEDQA wh emotes zed=true java=UIElement n=6 x=1612 y=772 w=616 vis=false point=-1 title=nil | 1:Friendly 2:Hostile 3:Group 4:Signal 5:Shout 6:Dance
ZEDQA wh press towards 4 (Signal)
ZEDQA wh signal zed=true java=UIElement n=9 x=1586 y=746 w=668 vis=true point=-1 title=Signal | 1:Cease Fire 2:Ok 3:Move Out 4:Freeze 5:Follow Behind 6:Fire 7:Come 8:Salute 9:Back
ZEDQA wh gun zed=true java=UIElement n=0 x=1586 y=746 w=668 vis=false point=-1 title=nil |
ZEDQA wh light zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=-1 title=nil | 1:Flashlight/Unequip 2:Flashlight/Turn on
ZEDQA wh back zed=true java=UIElement n=10 x=1577 y=737 w=686 vis=false point=-1 title=nil | 1:Base theme/Dark 2:Accent color/Purple 3:Text size/Small 4:UI scale 5:Moodles/Right edge 6:Action bar/Verbose 7:Messages/1 new 8:Reset windows/Both windows, as the footer's R 9:ZeD setup/Options, on ZeD's page 10:Safe mode/The game's own interface
ZEDQA wh dright zed=true java=UIElement n=2 x=1620 y=780 w=600 vis=false point=2 title=nil | 1:Flashlight/Unequip 2:Flashlight/Turn on
ZEDQA wh zone route: world=true vanillaZone=false
ZEDQA wh zone tab showing=true
ZEDQA wh search route: forage showing=true vanillaSearch=false
ZEDQA wh player info route: char=true vanillaInfo=false
ZEDQA wh DONE
```

### 14. zedqa_dpad_wheels.lua (`ZEDQA dw`) - PASS, 45 s

- go 13800 at 21:02:12
- screenshots: zqa_dw_foot_left.png, zqa_dw_inner_left.png, zqa_dw_foot_right.png, zqa_dw_inner_right.png, zqa_dw_foot_up.png, zqa_dw_inner_up.png, zqa_dw_foot_down.png, zqa_dw_inner_down.png, zqa_dw_foot_select.png, zqa_dw_inner_select.png, zqa_dw_look_dark_small_down.png, zqa_dw_look_dark_small_accent.png, zqa_dw_look_dark_large_down.png, zqa_dw_look_dark_large_accent.png, zqa_dw_look_light_small_down.png, zqa_dw_look_light_small_accent.png, zqa_dw_look_light_large_down.png, zqa_dw_look_light_large_accent.png, zqa_dw_look_hicon_small_down.png, zqa_dw_look_hicon_small_accent.png, zqa_dw_look_hicon_large_down.png, zqa_dw_look_hicon_large_accent.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dw start
[ZeD.QA] run #14 ok=true
ZEDQA dw scene: at 12045,11754, in a car false, health 100
ZEDQA dw foot left: 8 slices, crumb Character, visible false | 1:Tabs / Character window [>] 2:Weapons [>] 3:Eat [>] 4:Drink / Nothing to drink on you. [off] 5:Medicine and first aid / Nothing to treat, no medicine on you. [off] 6:Sleep / Not tired enough to sleep. [off] 7:Clothing / Nothing you wear can change. [off] 8:Use / Smoke | Read | Watch | Radio [>]
ZEDQA dw PASS left: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS left: the slice 'Tabs' is there
ZEDQA dw inner left: 9 slices, crumb Character › Tabs, visible true | 1:Loot 2:Equipment 3:Health 4:Thermal 5:Identity 6:Journal 7:Skills 8:Radio / No radio in your hands or on your back. [off] 9:Back
ZEDQA dw PASS left: the inner wheel ends with Back
ZEDQA dw PASS left: the breadcrumb names the inner wheel
ZEDQA dw PASS left: B from the inner wheel is back on the top level
ZEDQA dw PASS left: B on the top level closes the wheel
ZEDQA dw foot right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal / No tame animal in reach. [off] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
ZEDQA dw PASS right: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS right: the slice 'Map' is there
ZEDQA dw inner right: 4 slices, crumb World › Map, visible true | 1:Show/Hide World Map 2:Show/Hide Mini-Map / The mini-map is off in this game. [off] 3:Focus Mini Map / The mini-map is off in this game. [off] 4:Back
ZEDQA dw PASS right: the inner wheel ends with Back
ZEDQA dw PASS right: the breadcrumb names the inner wheel
ZEDQA dw PASS right: B from the inner wheel is back on the top level
ZEDQA dw PASS right: B on the top level closes the wheel
ZEDQA dw foot up: 8 slices, crumb Social, visible false | 1:Friendly [>] 2:Hostile [>] 3:Group [>] 4:Signal [>] 5:Shout 6:Chat / On a server only. [off] 7:Safety / On a server only. [off] 8:Players / On a server only. [off]
ZEDQA dw PASS up: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS up: the slice 'Friendly' is there
ZEDQA dw inner up: 6 slices, crumb Social › Friendly, visible true | 1:Wave Hi 2:Bye 3:Clap 4:Thumbs Up 5:Thank You 6:Back
ZEDQA dw PASS up: the inner wheel ends with Back
ZEDQA dw PASS up: the breadcrumb names the inner wheel
ZEDQA dw PASS up: B from the inner wheel is back on the top level
ZEDQA dw PASS up: B on the top level closes the wheel
ZEDQA dw foot down: 8 slices, crumb Here and now, visible false | 1:Sit [>] 2:Crouch / Off 3:Auto-walk / Off 4:Game speed [>] 5:Zoom [>] 6:View / Interface and windows [>] 7:Help [>] 8:Flashlight / Turn on
ZEDQA dw PASS down: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS down: the slice 'Zoom' is there
ZEDQA dw inner down: 3 slices, crumb Here and now › Zoom, visible true | 1:Zoom 75% 2:Zoom 125% 3:Back
ZEDQA dw PASS down: the inner wheel ends with Back
ZEDQA dw PASS down: the breadcrumb names the inner wheel
ZEDQA dw PASS down: B from the inner wheel is back on the top level
ZEDQA dw PASS down: B on the top level closes the wheel
ZEDQA dw foot select: 10 slices, crumb ZeD, visible false | 1:Base theme / Dark [>] 2:Accent color / Purple [>] 3:Text size / Small [>] 4:UI scale [>] 5:Moodles / Right edge [>] 6:Action bar / Verbose [>] 7:Messages / 1 new 8:Reset windows / Both windows, as the footer's R 9:ZeD setup / Options, on ZeD's page 10:Safe mode / The game's own interface
ZEDQA dw PASS select: the top level has its slices (8, 9 on ZeD)
ZEDQA dw PASS select: the slice 'Base theme' is there
ZEDQA dw inner select: 4 slices, crumb ZeD › Base theme, visible true | 1:Dark / In use 2:Light 3:High contrast 4:Back
ZEDQA dw PASS select: the inner wheel ends with Back
ZEDQA dw PASS select: the breadcrumb names the inner wheel
ZEDQA dw PASS select: B from the inner wheel is back on the top level
ZEDQA dw PASS select: B on the top level closes the wheel
ZEDQA dw look back to dark / purple / small
ZEDQA dw PASS Character > Tabs has Health
ZEDQA dw PASS Character > Tabs > Health opened the Character window on Health
ZEDQA dw World > Map > Mini-map is off: The mini-map is off in this game.
ZEDQA dw no mini-map in this game (sandbox): the slice is off, as it should be
ZEDQA dw PASS Social > Shout is live
ZEDQA dw PASS Here and now > Zoom > in changed the zoom (1.00 -> 0.75)
ZEDQA dw PASS ZeD > Text size marks the size in use
ZEDQA dw PASS ZeD > Text size > the size in use keeps it (small)
ZEDQA dw PASS the game pauses for the paused checks
ZEDQA dw PASS paused: left stays closed
ZEDQA dw PASS paused: right stays closed
ZEDQA dw PASS paused: up stays closed
ZEDQA dw PASS paused: down opens
ZEDQA dw PASS paused: select opens
ZEDQA dw PASS the game runs again after the paused checks
ZEDQA dw PASS with a window holding the pad, D-pad Left stays in the window (no wheel)
ZEDQA dw PASS L3 steps the sort (name, cat, cond)
ZEDQA dw PASS R3 flips the bag between List and Grid (false -> true)
ZEDQA dw PASS R3 again flips it back
ZEDQA dw PASS the footer names L3 and R3 while the pad is on the list
ZEDQA dw no deep-run car within 8 tiles: the car scene is skipped
ZEDQA dw 0 animals in the cell, none tame within 15 tiles: a tame cow spawned beside the character (true)
ZEDQA dw beside a tame animal (2.0 tiles away before)
ZEDQA dw the game's usable animal: nil
ZEDQA dw animal right: 8 slices, crumb World, visible false | 1:Tabs / World window [>] 2:Map [>] 3:Vehicle / No vehicle in reach. [off] 4:Animal [>] 5:Craft and build [>] 6:Search [>] 7:Lights and power / No lights or power in reach. [off] 8:Designated Zones / Animals
ZEDQA dw PASS beside a tame animal: World > Animal is live
ZEDQA dw animal wheel: 5 slices, crumb World › Animal, visible false | 1:Kill Animal 2:Pick up Angus Cow 3:Pet 4:Animal Info 5:Back
ZEDQA dw PASS the animal wheel ends with Back
ZEDQA dw 0 failed
ZEDQA dw DONE
```

### 15. zedqa_quick_chords.lua (`ZEDQA qc`) - WARN, 22 s

- go 13801 at 21:03:00
- 1 ERR line(s)
- screenshots: zqa_qc_light_on.png, zqa_qc_chord_LBA.png, zqa_qc_chord_LBB.png, zqa_qc_chord_LBY.png, zqa_qc_gone_halo.png, zqa_qc_wheel_assigned.png, zqa_qc_wheel_chord_shown.png, zqa_qc_setup_chords.png, zqa_qc_setup_picker.png

```text
[ZeD.QA] windows reset (R)
ZEDQA qc start
[ZeD.QA] run #15 ok=true
ZEDQA qc the torch (added) and water, a cigarette, a lighter, an apple in the main inventory; hands: nil / nil
ZEDQA qc LB + X picks Base.HandTorch in none (brighter than the torch): that light is checked
ZEDQA qc LB+A = character:3 (Character > Eat): Eat
ZEDQA qc PASS LB+A: the default names a slice
ZEDQA qc LB+B = character:4 (Character > Drink): Drink
ZEDQA qc PASS LB+B: the default names a slice
ZEDQA qc LB+X = now:8 (Here and now > Light): Flashlight
ZEDQA qc PASS LB+X: the default names a slice
ZEDQA qc LB+Y = character:8:1 (Character > Use > Smoke): Smoke
ZEDQA qc PASS LB+Y: the default names a slice
ZEDQA qc LB+L3 = now:1:1 (Here and now > Sit > Sit on ground): Sit on ground
ZEDQA qc PASS LB+L3: the default names a slice
ZEDQA qc LB+R3 = social:5 (Social > Shout): Shout
ZEDQA qc PASS LB+R3: the default names a slice
ZEDQA qc RB+A = character:5 (Character > Medicine and first aid): Medicine and first aid [off: Nothing to treat, no medicine on you.]
ZEDQA qc PASS RB+A: the default names a slice
ZEDQA qc RB+B = character:2 (Character > Weapons): Weapons
ZEDQA qc PASS RB+B: the default names a slice
ZEDQA qc RB+X = character:8:2 (Character > Use > Read): Read
ZEDQA qc PASS RB+X: the default names a slice
ZEDQA qc RB+Y = world:2:1 (World > Map > Show/Hide World Map): Show/Hide World Map
ZEDQA qc PASS RB+Y: the default names a slice
ZEDQA qc RB+L3 = now:3 (Here and now > Auto-walk): Auto-walk
ZEDQA qc PASS RB+L3: the default names a slice
ZEDQA qc RB+R3 = now:2 (Here and now > Crouch): Crouch
ZEDQA qc PASS RB+R3: the default names a slice
ZEDQA qc LB + X queued: ISEquipWeaponAction
ZEDQA qc PASS LB + X: the game's prompts never saw X
ZEDQA qc PASS a light for LB + X
ZEDQA qc PASS LB + X: the light is in a hand
ZEDQA qc PASS LB + X: the light is on
ZEDQA qc PASS LB + X again: the light is off
ZEDQA qc LB + X from a bag: skipped, LB + X picks Base.HandTorch in a hand or on the belt first
ZEDQA qc PASS stuffed: Eat says Too full to eat more.
ZEDQA qc LB + A (eat) queued: ISEatFoodAction
ZEDQA qc PASS LB + A (eat): the game queues its action
ZEDQA qc LB + B (drink) queued: ISDrinkFromBottle
ZEDQA qc PASS LB + B (drink): the game queues its action
ZEDQA qc LB + Y (smoke) queued: ISEatFoodAction, ISInventoryTransferAction
ZEDQA qc PASS LB + Y (smoke): the game queues its action
ZEDQA qc said: No QA Gone on you.
ZEDQA qc PASS a gone thing: the character says No QA Gone on you.
ZEDQA qc PASS the Here and now wheel is open
ZEDQA qc PASS RB + Y on Crouch: the chord reads now:2
ZEDQA qc the bubble's note: Now on RB + Y. It replaces Show/Hide World Map.
ZEDQA qc PASS the bubble says what it did
ZEDQA qc PASS opened again: Crouch shows RB + Y
ZEDQA qc PASS ZeD setup is open on the pause screen
ZEDQA qc PASS ZeD setup has the twelve chord rows (12)
ZEDQA qc FAIL ZeD setup has Put things back
ZEDQA qc the list for LB+A: 87 items, 79 to choose
ZEDQA qc PASS the chord's list offers the wheels' actions
ZEDQA qc put back: the chords file as it was; RB + Y reads world:2:1 (was world:2:1)
ZEDQA qc PASS the chords are as they were
ZEDQA qc 1 failed
ZEDQA qc DONE
```

### 16. zedqa_put_back.lua (`ZEDQA pb`) - PASS, 34 s

- go 13802 at 21:03:26

```text
[ZeD.QA] windows reset (R)
ZEDQA pb start
[ZeD.QA] run #16 ok=true
ZEDQA pb PASS the switch is on
ZEDQA pb the bag: Small Backpack; hands: nil / nil
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

### 17. zedqa_messages.lua (`ZEDQA msg`) - WARN, 11 s

- go 13803 at 21:04:03
- 1 expected exception(s) ignored (expect=)
- 1 ERR line(s)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #17 ok=true
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
ERROR: General f:21538 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:21538> Lua(Vanilla).boom> Exception thrown   (expected)
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
    1x ERROR: General f:N at KahluaThread.flushErrorMessage > expected argument of type ItemBodyLocation, got String
    1x ERROR: General f:N> Lua((MOD:[B42] Noir's Rifle Slings)).Sling_BodyLocations.lua> Exception thrown  :: java.lang.RuntimeException: expected argument of type ItemBodyLocation, got String at MethodArguments.assertValid(MethodArguments.java:128).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
