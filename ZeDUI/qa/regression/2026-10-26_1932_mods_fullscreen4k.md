# ZeD-UI regression - 2026-10-26 19:33 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 19:33:13 |
| Finished | 2026-10-26 19:36:11 (2 min 57 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_A.txt (2 scripts) |
| Result | **1/2 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 13709 to 13712 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13711, 13712)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_r3_A.lua | r3A | **FAIL** | 42 | zqa_r3A_1_loot.png, zqa_r3A_2_menu_apple.png, zqa_r3A_3_menu_world.png, zqa_r3A_4_tip_shirt_zed.png, zqa_r3A_5_tip_shirt_safe.png, zqa_r3A_4_tip_book_zed.png, zqa_r3A_5_tip_book_safe.png, zqa_r3A_4_tip_vhs_zed.png, zqa_r3A_5_tip_vhs_safe.png, zqa_r3A_4_tip_seed_zed.png, zqa_r3A_5_tip_seed_safe.png, zqa_r3A_6_char_equip.png, zqa_r3A_6_char_health.png, zqa_r3A_6_char_skills.png, zqa_r3A_6_char_identity.png, zqa_r3A_7_world_craft.png, zqa_r3A_7_world_build.png, zqa_r3A_7_world_maps.png, zqa_r3A_8_clothingui.png, zqa_r3A_9_tbyw.png, zqa_r3A_10_char_equip_after.png | 22 Java exception(s) in the log |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13709 at 19:34:52

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_A.lua (`ZEDQA r3A`) - FAIL, 42 s

- go 13710 at 19:34:57
- 22 Java exception(s) in the log
- screenshots: zqa_r3A_1_loot.png, zqa_r3A_2_menu_apple.png, zqa_r3A_3_menu_world.png, zqa_r3A_4_tip_shirt_zed.png, zqa_r3A_5_tip_shirt_safe.png, zqa_r3A_4_tip_book_zed.png, zqa_r3A_5_tip_book_safe.png, zqa_r3A_4_tip_vhs_zed.png, zqa_r3A_5_tip_vhs_safe.png, zqa_r3A_4_tip_seed_zed.png, zqa_r3A_5_tip_seed_safe.png, zqa_r3A_6_char_equip.png, zqa_r3A_6_char_health.png, zqa_r3A_6_char_skills.png, zqa_r3A_6_char_identity.png, zqa_r3A_7_world_craft.png, zqa_r3A_7_world_build.png, zqa_r3A_7_world_maps.png, zqa_r3A_8_clothingui.png, zqa_r3A_9_tbyw.png, zqa_r3A_10_char_equip_after.png

```text
[ZeD.QA] windows reset (R)
ZEDQA r3A start
[ZeD.QA] run #2 ok=true
ZEDQA r3A shot zqa_r3A_1_loot.png
ZEDQA r3A ui loot: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@0,0,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3A vanilla loot: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A menu apple:
ZEDQA r3A shot zqa_r3A_2_menu_apple.png
ZEDQA r3A menu shirt:
ZEDQA r3A menu book:
ZEDQA r3A menu bag:
ZEDQA r3A world menu: Sit on ground, Walk to
ZEDQA r3A shot zqa_r3A_3_menu_world.png
ZEDQA r3A shot zqa_r3A_4_tip_shirt_zed.png
ZEDQA r3A tip shirt zed 245x96
ERROR: General f:1183> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1216> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1217> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1219> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1220> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1222> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1223> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1225> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1226> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1228> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1229> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1230> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1232> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1233> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1235> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1236> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1238> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1239> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1241> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1242> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1244> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ERROR: General f:1245> Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing> Exception thrown
    java.lang.RuntimeException: Object tried to call nil in DoTooltipClothing at KahluaUtil.fail(KahluaUtil.java:100).
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).DoTooltipClothing(bcic_TooltipClothing.lua:65)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_DoTooltip(bcic_Tooltip.lua:50)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).RenderTooltip(bcic_Tooltip.lua:167)
    Lua((MOD:Better Clothing Info Comparison (Build 41 and 42))).bcic_render(bcic_Tooltip.lua:224)
    Lua((MOD:[B42] Show VHS skills in tooltip)).render(SVSIT_main.lua:113)
ZEDQA r3A shot zqa_r3A_5_tip_shirt_safe.png
ZEDQA r3A tip shirt safe 0x0
ZEDQA r3A shot zqa_r3A_4_tip_book_zed.png
ZEDQA r3A tip book zed 297x79
ZEDQA r3A shot zqa_r3A_5_tip_book_safe.png
ZEDQA r3A tip book safe 297x76
ZEDQA r3A shot zqa_r3A_4_tip_vhs_zed.png
ZEDQA r3A tip vhs zed 189x45
ZEDQA r3A shot zqa_r3A_5_tip_vhs_safe.png
ZEDQA r3A tip vhs safe 189x42
ZEDQA r3A shot zqa_r3A_4_tip_seed_zed.png
ZEDQA r3A tip seed zed 202x79
ZEDQA r3A shot zqa_r3A_5_tip_seed_safe.png
ZEDQA r3A tip seed safe 252x144
ZEDQA r3A ui after safe mode: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@621,2,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla after safe mode: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A shot zqa_r3A_6_char_equip.png
ZEDQA r3A shot zqa_r3A_6_char_health.png
ZEDQA r3A shot zqa_r3A_6_char_skills.png
ZEDQA r3A shot zqa_r3A_6_char_identity.png
ZEDQA r3A shot zqa_r3A_7_world_craft.png
ZEDQA r3A shot zqa_r3A_7_world_build.png
ZEDQA r3A shot zqa_r3A_7_world_maps.png
ZEDQA r3A ui tabs walked: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@621,2,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A shot zqa_r3A_8_clothingui.png
ZEDQA r3A ui clothingui: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@621,2,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; myClothingUI@300,300,320x540 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla clothingui: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A shot zqa_r3A_9_tbyw.png
ZEDQA r3A ui tbyw: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@621,2,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; TBYW_Window@1450,760,988x640 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla tbyw: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A shot zqa_r3A_10_char_equip_after.png
ZEDQA r3A ui end: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; IconsInventory_Onboarding@100,477,550x254 ; NEQ_ToggleButton@621,2,0x16 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ContainerLabelsOverlay@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISPanel@500,500,50x50 ; ZeD_BeltHUD@1438,2041,853x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; P4AddictedToWeightSoundAlert@1567,1003,705x153 ; CTagsOverlay@0,0,0x0 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; CTagsPanel@20,670,40x40 ; NEQ_DragRenderer@0,0,0x0 ; ZeD_MessagesToasts@3122,263,1x1
ZEDQA r3A vanilla end: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3A DONE
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
