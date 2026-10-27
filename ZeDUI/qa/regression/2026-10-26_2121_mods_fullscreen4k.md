# ZeD-UI regression - 2026-10-26 21:22 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 21:22:07 |
| Finished | 2026-10-26 21:27:36 (5 min 29 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_G.txt (11 scripts) |
| Result | **9/11 pass**, 1 warn, 1 fail, 0 timeout |
| Go numbers | 13821 to 13833 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13832, 13833)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_r3_G.lua | r3G | **FAIL** | 47 | zqa_r3G_1_loot.png, zqa_r3G_2_menu_apple.png, zqa_r3G_3_menu_world.png, zqa_r3G_4_tip_shirt_zed.png, zqa_r3G_5_tip_shirt_safe.png, zqa_r3G_4_tip_book_zed.png, zqa_r3G_5_tip_book_safe.png, zqa_r3G_4_tip_vhs_zed.png, zqa_r3G_5_tip_vhs_safe.png, zqa_r3G_4_tip_seed_zed.png, zqa_r3G_5_tip_seed_safe.png, zqa_r3G_6_char_equip.png, zqa_r3G_6_char_health.png, zqa_r3G_6_char_skills.png, zqa_r3G_6_char_identity.png, zqa_r3G_7_world_craft.png, zqa_r3G_7_world_build.png, zqa_r3G_7_world_maps.png, zqa_r3G_8_palmpilot.png, zqa_r3G_9_sandboxcontrol.png, zqa_r3G_10_inspect.png, zqa_r3G_11_attachments.png, zqa_r3G_12_belt.png | 82 Java exception(s) in the log |
| 3 | suite_tabs.lua | tabs | PASS | 10 |  |  |
| 4 | suite_verbs.lua | verbs | PASS | 16 |  |  |
| 5 | zedqa_ctxlist.lua | cl | PASS | 4 | zqa_cl_1.png, zqa_cl_2.png |  |
| 6 | zedqa_doll.lua | doll | PASS | 7 | zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png |  |
| 7 | zedqa_belt_hands.lua | bh | PASS | 4 | zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png |  |
| 8 | zedqa_belt_strap.lua | belt | PASS | 2 | zqa_belt_strap_1.png |  |
| 9 | zedqa_straps.lua | straps | PASS | 12 | zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png |  |
| 10 | zedqa_food_verbs.lua | fv | PASS | 3 | zqa_fv_smoking.png |  |
| 11 | zedqa_messages.lua | msg | WARN | 10 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=); 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 13821 at 21:24:09

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. zedqa_r3_G.lua (`ZEDQA r3G`) - FAIL, 47 s

- go 13822 at 21:24:19
- 82 Java exception(s) in the log
- screenshots: zqa_r3G_1_loot.png, zqa_r3G_2_menu_apple.png, zqa_r3G_3_menu_world.png, zqa_r3G_4_tip_shirt_zed.png, zqa_r3G_5_tip_shirt_safe.png, zqa_r3G_4_tip_book_zed.png, zqa_r3G_5_tip_book_safe.png, zqa_r3G_4_tip_vhs_zed.png, zqa_r3G_5_tip_vhs_safe.png, zqa_r3G_4_tip_seed_zed.png, zqa_r3G_5_tip_seed_safe.png, zqa_r3G_6_char_equip.png, zqa_r3G_6_char_health.png, zqa_r3G_6_char_skills.png, zqa_r3G_6_char_identity.png, zqa_r3G_7_world_craft.png, zqa_r3G_7_world_build.png, zqa_r3G_7_world_maps.png, zqa_r3G_8_palmpilot.png, zqa_r3G_9_sandboxcontrol.png, zqa_r3G_10_inspect.png, zqa_r3G_11_attachments.png, zqa_r3G_12_belt.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA r3G start
:	[ZeD.QA] run #2 ok=true
:	ZEDQA r3G shot zqa_r3G_1_loot.png
:	ZEDQA r3G ui loot: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,380x82 ; WorldPingSystemOverlay@0,0,1x1 ; WaterMarkUI@3604,2127,226x22 ; ZeD_BeltHUD@1438,2041,1045x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; SidePanelManager@615,22,0x28 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; DragItemRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
:	ZEDQA r3G vanilla loot: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3G menu apple: Inspect item, Eat, Drop, Place Item, More, Sandbox Control: delete item, Move to, Rename
:	ZEDQA r3G shot zqa_r3G_2_menu_apple.png
:	ZEDQA r3G menu shirt: Inspect item, Wear, Rip Clothing, Craft, Inspect, Drop, Place Item, More, Sandbox Control: delete item, Change Appearance, Move to, Rename
:	ZEDQA r3G menu book: Inspect item, Equip Primary, Equip Secondary, Read, Craft, Drop, Place Item, More, Sandbox Control: delete item, Move to, Rename
:	ZEDQA r3G menu bag: Inspect item, Wear, Equip Primary, Equip Secondary, Drop, Place Item, More, Sandbox Control: delete item, Change Appearance, Move to
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
    Lua(Vanilla).createMenu(ISWorldObjectContextMenu.lua:213)
    Lua((MOD:ZeD-GUI)).createMenu(ContextMenu.lua:179)
    Lua(Vanilla).world menu(spawnpoints.lua:97)
ERROR: General f:643> 9))).getAllEvalRecurse> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in getAllEvalRecurse at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Spear Traps (v0.0.9))).getAllEvalRecurse(SpearTraps_ContextMenu.lua:97)
    Lua((MOD:Spear Traps (v0.0.9))).onFillWorldObjectContextMenu(SpearTraps_ContextMenu.lua:95)
... (186 more lines; see console.txt)
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 10 s

- go 13823 at 21:25:11

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
:	ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
:	ZEDQA tabs armed
:	[ZeD.QA] run #3 ok=true
:	ZEDQA char tab=loot active=loot w=777 focusables=0 {}
:	ZEDQA char tab=equip active=equip w=1617 focusables=31 {equipgroup=5 equippart=17 equipslot=7 equipview=2}
:	ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
:	ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
:	ZEDQA char tab=identity active=identity w=1617 focusables=55 {hb=26 identity=29}
:	ZEDQA char tab=journal active=journal w=1617 focusables=8 {journal=4 jsub=4}
:	ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
:	ZEDQA world tab=loot active=loot w=777 focusables=0 {}
:	ZEDQA world tab=craft active=craft w=1617 focusables=11 {craft=11}
:	ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
:	ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
:	ZEDQA world tab=maps active=maps w=1682 focusables=19 {map=19}
:	ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
:	ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
:	ZEDQA tabs done
```

### 4. suite_verbs.lua (`ZEDQA verbs`) - PASS, 16 s

- go 13824 at 21:25:26

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA verbs armed
:	[ZeD.QA] run #4 ok=true
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

### 5. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 4 s

- go 13825 at 21:25:47
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA cl start
:	[ZeD.QA] run #5 ok=true
:	ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Sandbox Control: delete item, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Inspect item, |, Rename
:	ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
:	ZEDQA cl down: sub sel 2
:	ZEDQA cl B: levels 1
:	ZEDQA cl B again: open false
:	ZEDQA cl strip back: class ZeD_ContextMenu
:	ZEDQA cl DONE
```

### 6. zedqa_doll.lua (`ZEDQA doll`) - PASS, 7 s

- go 13826 at 21:25:56
- screenshots: zqa_doll_1.png, zqa_doll_2.png, zqa_doll_3.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA doll start
:	[ZeD.QA] run #6 ok=true
:	ZEDQA doll doll shown true | slots 6 {doll:torso,doll:outer,doll:hands,doll:belt,doll:legs,doll:feet} | belt empties 6 | photo 263,74 290x643 | lines 11 | model visible true | layer visible true
:	ZEDQA doll pad targets: equipslot:__disclosure,equipview:list,equipview:doll,equipslot:doll:torso,equipslot:doll:outer,equipslot:doll:hands,equipslot:doll:belt,equipslot:doll:legs,equipslot:doll:feet,equipbelt:1,equipbelt:2,equipbelt:3,equipbelt:4,equipbelt:5,equipbelt:6,equipslot:doll:head,equipslot:doll:eyes,equipslot:doll:neck,equipslot:doll:back,equipslot:doll:arms,equipslot:doll:main,equipslot:doll:off
:	ZEDQA doll focus torso: zone=charTabContent el=equipslot:doll:torso sel=nil layer=nil
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

### 7. zedqa_belt_hands.lua (`ZEDQA bh`) - PASS, 4 s

- go 13827 at 21:26:08
- screenshots: zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA bh start
:	[ZeD.QA] run #7 ok=true
:	ZEDQA bh PASS left wrist: the boxes run left to right (watch@0 OFF@102 #1@232 #2@328 #3@424 #4@667 #5@763 #6@859 MAIN@975 lamp@1080)
:	ZEDQA bh PASS left wrist: the off hand at the left end, the main hand at the right, the slots between
:	ZEDQA bh PASS left wrist: the Messages note is last on the right
:	ZEDQA bh PASS left wrist: the watch is left of the off hand
:	ZEDQA bh PASS left wrist: the full watch pops at the left end (left)
:	ZEDQA bh PASS pad: the belt starts on slot 1 (#1)
:	ZEDQA bh PASS pad: Left from slot 1 is the off hand (OFF)
:	ZEDQA bh PASS right wrist: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@565 #5@661 #6@757 MAIN@873 watch@978 lamp@1080)
:	ZEDQA bh PASS right wrist: the off hand at the left end, the main hand at the right, the slots between
:	ZEDQA bh PASS right wrist: the Messages note is last on the right
:	ZEDQA bh PASS right wrist: the watch is right of the main hand
:	ZEDQA bh PASS right wrist: the full watch pops at the right end (right)
:	ZEDQA bh PASS as worn: the boxes run left to right (OFF@0 #1@130 #2@226 #3@322 #4@565 #5@661 #6@757 MAIN@873 lamp@978)
:	ZEDQA bh PASS as worn: the off hand at the left end, the main hand at the right, the slots between
:	ZEDQA bh PASS as worn: the Messages note is last on the right
:	ZEDQA bh all checks passed
:	ZEDQA bh DONE
```

### 8. zedqa_belt_strap.lua (`ZEDQA belt`) - PASS, 2 s

- go 13828 at 21:26:17
- screenshots: zqa_belt_strap_1.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #8 ok=true
:	ZEDQA belt textures true
:	ZEDQA belt shot; DONE
```

### 9. zedqa_straps.lua (`ZEDQA straps`) - PASS, 12 s

- go 13829 at 21:26:23
- screenshots: zqa_straps_civilian.png, zqa_straps_military.png, zqa_straps_makeshift.png, zqa_straps_firefighter.png, zqa_straps_olive.png

```text
:	[ZeD.QA] windows reset (R)
:	[ZeD.QA] run #9 ok=true
:	ZEDQA straps put aside 2
:	ZEDQA straps civilian worn HolsterSimple_Brown,Belt2,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim
:	ZEDQA straps civilian slots Back=sling HolsterRight=holster_brown SmallBeltLeft=leather SmallBeltRight=leather BritaBeltFront=leather BritaBeltBack=leather | waist=leather closure=buckle
:	ZEDQA straps civilian shot
:	ZEDQA straps military worn Holster_DuctTape,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICEpack_Army,Bag_ALICE_BeltSus_Camo
:	ZEDQA straps military slots Back=webbing_olive HolsterRight=holster_tape SmallBeltLeft=webbing_camo SmallBeltRight=webbing_camo BedrollBottomALICE=webbing_olive WebbingRight=webbing_camo WebbingLeft=webbing_camo | waist=webbing_camo closure=clip_black
:	ZEDQA straps military shot
:	ZEDQA straps makeshift worn Holster_Hide,RopeBelt,Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_CraftedFramepack_Large
:	ZEDQA straps makeshift slots Back=rope HolsterRight=holster_hide SmallBeltLeft=rope BedrollBottom=rope | waist=rope closure=knot
:	ZEDQA straps makeshift shot
:	ZEDQA straps firefighter worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,SCBA
:	ZEDQA straps firefighter slots Back=harness SmallBeltLeft=harness SmallBeltRight=harness WebbingLeft=harness | waist=harness closure=clip_black
:	ZEDQA straps firefighter shot
:	ZEDQA straps olive worn Vest_DefaultTEXTURE_TINT,Tshirt_DefaultTEXTURE,Gloves_LeatherGloves,Socks_Ankle,Shoes_ArmyBoots,Trousers_Denim,Bag_ALICE_BeltSus
:	ZEDQA straps olive slots Back=sling SmallBeltLeft=webbing_olive SmallBeltRight=webbing_olive WebbingLeft=webbing_olive WebbingRight=webbing_olive | waist=webbing_olive closure=clip_brass
:	ZEDQA straps olive shot
:	ZEDQA straps restored; DONE
```

### 10. zedqa_food_verbs.lua (`ZEDQA fv`) - PASS, 3 s

- go 13830 at 21:26:40
- screenshots: zqa_fv_smoking.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fv start
:	[ZeD.QA] run #10 ok=true
:	ZEDQA fv Cigarette: the card's main button reads Smoke (id EAT)
:	ZEDQA fv PASS Cigarette: the card says Smoke
:	ZEDQA fv Apple: the card's main button reads Eat (id EAT)
:	ZEDQA fv PASS Apple: the card says Eat
:	ZEDQA fv Canned Evaporated Milk (Open): the card's main button reads Drink (id EAT)
:	ZEDQA fv PASS Canned Evaporated Milk (Open): the card says Drink
:	ZEDQA fv smoking: the action is ISEatFoodAction, the bar reads SMOKING
:	ZEDQA fv PASS smoking: the bar says SMOKING
:	ZEDQA fv eating: the action is ISEatFoodAction, the bar reads EATING
:	ZEDQA fv PASS an apple: the bar still says EATING
:	ZEDQA fv all checks passed
:	ZEDQA fv DONE
```

### 11. zedqa_messages.lua (`ZEDQA msg`) - WARN, 10 s

- go 13831 at 21:26:48
- 1 expected exception(s) ignored (expect=)
- 1 ERR line(s)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA msg start
:	[ZeD.QA] run #11 ok=true
:	ZEDQA msg FAIL nothing kept: no envelope on the belt
:	ZEDQA msg PASS the three notes are not on screen
:	ZEDQA msg PASS the three notes are kept in Messages
:	ZEDQA msg PASS the source has three messages (3)
:	ZEDQA msg PASS three are new (3)
:	ZEDQA msg PASS a toast names the mod
:	ZEDQA msg PASS the game runs on after the mod paused it for its note (speed 1)
:	ZEDQA msg PASS the envelope is on the belt
:	ZEDQA msg PASS a question still asks at once
:	ZEDQA msg PASS the mod got its answer (YES)
:	ZEDQA msg PASS a copy of the question, already read, is in Messages
ERROR: General f:10753 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:10753> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:99)
:	ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
:	ZEDQA msg PASS Messages opens on the mod
:	ZEDQA msg PASS opening it marks the mod's messages read
:	ZEDQA msg PASS four cards: three notes and the question (4)
:	ZEDQA msg PASS three OK buttons, one per note (3)
:	ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
:	ZEDQA msg PASS A on the next card's OK ran its callback
:	ZEDQA msg PASS the controller is in the cards
:	ZEDQA msg PASS the window lists an error source
:	ZEDQA msg PASS the bug report text names the errors (1446 characters)
:	ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
:	ZEDQA msg PASS Clear removes the mod's messages
:	ZEDQA msg PASS the last unanswered note got its OK as it left
:	ZEDQA msg 1 failed
:	ZEDQA msg DONE
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
    1x ERROR: General f:N> Lua((MOD:They Knew [B42])).TheyKnew_BodyLocations.lua> Exception thrown  :: java.lang.RuntimeException: expected argument of type ItemBodyLocation, got String at MethodArguments.assertValid(MethodArguments.java:128).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Cube"
    2x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "MP5_Rack.X_Dummy01"
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Root"
    1x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "MP5_Aim_Rack.X_Dummy01"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Root"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Prop2_end"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Bip01_Prop1_end"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "HLPR=RemapSpace"
  622x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "HLPR-ChestTransform"
    2x ERROR: General f:N at ImportedSkeleton.collectBoneFrames > Could not find bone index for node name: "Body"
```
