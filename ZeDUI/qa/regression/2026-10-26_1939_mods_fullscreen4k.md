# ZeD-UI regression - 2026-10-26 19:39 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 19:39:25 |
| Finished | 2026-10-26 19:46:12 (6 min 46 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_B.txt (13 scripts) |
| Result | **13/13 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13713 to 13727 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13726, 13727)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_r3_B.lua | r3B | PASS | 61 | zqa_r3B_1_loot.png, zqa_r3B_2_menu_apple.png, zqa_r3B_3_menu_world.png, zqa_r3B_4_tip_shirt_zed.png, zqa_r3B_5_tip_shirt_safe.png, zqa_r3B_4_tip_book_zed.png, zqa_r3B_5_tip_book_safe.png, zqa_r3B_4_tip_vhs_zed.png, zqa_r3B_5_tip_vhs_safe.png, zqa_r3B_4_tip_seed_zed.png, zqa_r3B_5_tip_seed_safe.png, zqa_r3B_6_char_equip.png, zqa_r3B_6_char_health.png, zqa_r3B_6_char_skills.png, zqa_r3B_6_char_identity.png, zqa_r3B_7_world_craft.png, zqa_r3B_7_world_build.png, zqa_r3B_7_world_maps.png, zqa_r3B_8_hud_open.png, zqa_r3B_9_hud_shut.png, zqa_r3B_10_health_wound.png, zqa_r3B_11_skills_xp.png |  |
| 3 | suite_tabs.lua | tabs | PASS | 19 |  |  |
| 4 | zedqa_moodles.lua | mood | PASS | 20 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 5 | zedqa_charinfo.lua | ci | PASS | 9 |  |  |
| 6 | zedqa_exinfo.lua | ex | PASS | 8 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png |  |
| 7 | suite_band.lua | band | PASS | 4 |  |  |
| 8 | zedqa_belt_hands.lua | bh | PASS | 5 | zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png |  |
| 9 | zedqa_beltwatch.lua | bw | PASS | 17 | zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png |  |
| 10 | zedqa_belt_strap.lua | belt | PASS | 2 | zqa_belt_strap_1.png |  |
| 11 | zedqa_ring_squares.lua | rs | PASS | 11 | zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png, zqa_rs_squares_on.png, zqa_rs_squares_off.png |  |
| 12 | zedqa_messages.lua | msg | PASS | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |
| 13 | suite_perf.lua | perf | PASS | 57 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 13713 at 19:41:04

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_B.lua (`ZEDQA r3B`) - PASS, 61 s

- go 13714 at 19:41:10
- screenshots: zqa_r3B_1_loot.png, zqa_r3B_2_menu_apple.png, zqa_r3B_3_menu_world.png, zqa_r3B_4_tip_shirt_zed.png, zqa_r3B_5_tip_shirt_safe.png, zqa_r3B_4_tip_book_zed.png, zqa_r3B_5_tip_book_safe.png, zqa_r3B_4_tip_vhs_zed.png, zqa_r3B_5_tip_vhs_safe.png, zqa_r3B_4_tip_seed_zed.png, zqa_r3B_5_tip_seed_safe.png, zqa_r3B_6_char_equip.png, zqa_r3B_6_char_health.png, zqa_r3B_6_char_skills.png, zqa_r3B_6_char_identity.png, zqa_r3B_7_world_craft.png, zqa_r3B_7_world_build.png, zqa_r3B_7_world_maps.png, zqa_r3B_8_hud_open.png, zqa_r3B_9_hud_shut.png, zqa_r3B_10_health_wound.png, zqa_r3B_11_skills_xp.png

```text
[ZeD.QA] windows reset (R)
ZEDQA r3B start
[ZeD.QA] run #2 ok=true
ZEDQA r3B shot zqa_r3B_1_loot.png
ZEDQA r3B ui loot: NeedsUI@3501,2081,324x64 ; EnduranceUI@15,2097,350x48 ; ZeD_ActionBarLayer@0,0,1x1 ; MoodleQuartersUI@3782,1080,48x0 ; UIDebugConsole@20,1848,1280x292 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,48x507 ; ISHotbar@-10000,-10000,488x64 ; ISHealthBarManager@0,0,1x1 ; CHStatusHUD_UI@20,120,200x403 ; ISGenericMiniDisplayBar@70,15,15x15 ; ISGenericMiniDisplayBar@70,30,15x150 ; ISGenericMiniDisplayBar@85,30,8x150 ; ISGenericMiniDisplayBar@93,30,8x150 ; ISGenericMiniDisplayBar@101,30,8x150 ; ISGenericMiniDisplayBar@109,30,8x150 ; ISGenericMiniDisplayBar@117,30,8x150 ; ISGenericMiniDisplayBar@133,30,8x150 ; ISGenericMiniDisplayBar@125,30,8x150 ; ISGenericMiniDisplayBar@141,30,8x150 ; ISGenericMiniDisplayBar@149,30,8x150 ; ISGenericMiniDisplayBar@157,30,8x150 ; ISGenericMiniDisplayBar@165,30,8x150 ; ISGenericMiniDisplayBar@173,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@189,30,8x150 ; TTF_MHP_MiniHealthPanel@1860,944,120x271 ; SSBar@20,630,157x463 ; WaterMarkUI@3630,2070,200x22 ; ISMoodlesInLua@0,0,0x0 ; PSIOverlay@0,0,1x1 ; ZeD_BeltHUD@1378,2024,864x104 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1022,0,888x840 ; ZeD_Window@1930,0,888x840 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3B vanilla loot: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3B menu apple:
ZEDQA r3B shot zqa_r3B_2_menu_apple.png
ZEDQA r3B menu shirt:
ZEDQA r3B menu book:
ZEDQA r3B menu bag:
ZEDQA r3B world menu: Sit on ground, Walk to
ZEDQA r3B shot zqa_r3B_3_menu_world.png
ZEDQA r3B shot zqa_r3B_4_tip_shirt_zed.png
ZEDQA r3B tip shirt zed 238x96
ZEDQA r3B shot zqa_r3B_5_tip_shirt_safe.png
ZEDQA r3B tip shirt safe 238x96
ZEDQA r3B shot zqa_r3B_4_tip_book_zed.png
ZEDQA r3B tip book zed 297x79
ZEDQA r3B shot zqa_r3B_5_tip_book_safe.png
ZEDQA r3B tip book safe 297x79
ZEDQA r3B shot zqa_r3B_4_tip_vhs_zed.png
ZEDQA r3B tip vhs zed 189x45
ZEDQA r3B shot zqa_r3B_5_tip_vhs_safe.png
ZEDQA r3B tip vhs safe 189x45
ZEDQA r3B shot zqa_r3B_4_tip_seed_zed.png
ZEDQA r3B tip seed zed 202x79
ZEDQA r3B shot zqa_r3B_5_tip_seed_safe.png
ZEDQA r3B tip seed safe 202x79
ZEDQA r3B ui after safe mode: NeedsUI@3501,2081,324x64 ; EnduranceUI@15,2097,350x48 ; ZeD_ActionBarLayer@0,0,1x1 ; MoodleQuartersUI@3782,1080,48x0 ; UIDebugConsole@20,1848,1280x292 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,48x507 ; ISHotbar@-10000,-10000,488x64 ; ISHealthBarManager@0,0,1x1 ; CHStatusHUD_UI@20,120,200x403 ; ISGenericMiniDisplayBar@70,15,15x15 ; ISGenericMiniDisplayBar@70,30,15x150 ; ISGenericMiniDisplayBar@85,30,8x150 ; ISGenericMiniDisplayBar@93,30,8x150 ; ISGenericMiniDisplayBar@101,30,8x150 ; ISGenericMiniDisplayBar@109,30,8x150 ; ISGenericMiniDisplayBar@117,30,8x150 ; ISGenericMiniDisplayBar@133,30,8x150 ; ISGenericMiniDisplayBar@125,30,8x150 ; ISGenericMiniDisplayBar@141,30,8x150 ; ISGenericMiniDisplayBar@149,30,8x150 ; ISGenericMiniDisplayBar@157,30,8x150 ; ISGenericMiniDisplayBar@165,30,8x150 ; ISGenericMiniDisplayBar@173,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@189,30,8x150 ; TTF_MHP_MiniHealthPanel@1860,944,120x271 ; SSBar@20,630,157x463 ; WaterMarkUI@3630,2070,200x22 ; ISMoodlesInLua@0,0,0x0 ; PSIOverlay@0,0,1x1 ; ZeD_BeltHUD@1378,2024,864x104 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3B vanilla after safe mode: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3B shot zqa_r3B_6_char_equip.png
ZEDQA r3B shot zqa_r3B_6_char_health.png
ZEDQA r3B shot zqa_r3B_6_char_skills.png
ZEDQA r3B shot zqa_r3B_6_char_identity.png
ZEDQA r3B shot zqa_r3B_7_world_craft.png
ZEDQA r3B shot zqa_r3B_7_world_build.png
ZEDQA r3B shot zqa_r3B_7_world_maps.png
ZEDQA r3B ui tabs walked: MoodleQuartersUI@3782,1080,48x0 ; ZeD_ActionBarLayer@0,0,1x1 ; EnduranceUI@15,2097,350x48 ; NeedsUI@3501,2081,324x64 ; UIDebugConsole@20,1848,1280x292 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,48x507 ; ISHotbar@-10000,-10000,488x64 ; ISHealthBarManager@0,0,1x1 ; CHStatusHUD_UI@20,120,200x403 ; ISGenericMiniDisplayBar@70,15,15x15 ; ISGenericMiniDisplayBar@70,30,15x150 ; ISGenericMiniDisplayBar@85,30,8x150 ; ISGenericMiniDisplayBar@93,30,8x150 ; ISGenericMiniDisplayBar@101,30,8x150 ; ISGenericMiniDisplayBar@109,30,8x150 ; ISGenericMiniDisplayBar@117,30,8x150 ; ISGenericMiniDisplayBar@133,30,8x150 ; ISGenericMiniDisplayBar@125,30,8x150 ; ISGenericMiniDisplayBar@141,30,8x150 ; ISGenericMiniDisplayBar@149,30,8x150 ; ISGenericMiniDisplayBar@157,30,8x150 ; ISGenericMiniDisplayBar@165,30,8x150 ; ISGenericMiniDisplayBar@173,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@189,30,8x150 ; TTF_MHP_MiniHealthPanel@1860,944,120x271 ; SSBar@20,630,157x463 ; WaterMarkUI@3630,2070,200x22 ; ISMoodlesInLua@0,0,0x0 ; PSIOverlay@0,0,1x1 ; ZeD_BeltHUD@1378,2024,864x104 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1022,0,888x840 ; ZeD_Window@1920,0,888x840 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3B vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3B ui moodles, windows open: NeedsUI@3501,2081,324x64 ; EnduranceUI@15,2097,350x48 ; ZeD_ActionBarLayer@0,0,1x1 ; MoodleQuartersUI@3782,1080,48x0 ; UIDebugConsole@20,1848,1280x292 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,48x507 ; ISHotbar@-10000,-10000,488x64 ; ISHealthBarManager@0,0,1x1 ; CHStatusHUD_UI@20,120,200x403 ; ISGenericMiniDisplayBar@70,15,15x15 ; ISGenericMiniDisplayBar@70,30,15x150 ; ISGenericMiniDisplayBar@85,30,8x150 ; ISGenericMiniDisplayBar@93,30,8x150 ; ISGenericMiniDisplayBar@101,30,8x150 ; ISGenericMiniDisplayBar@109,30,8x150 ; ISGenericMiniDisplayBar@117,30,8x150 ; ISGenericMiniDisplayBar@133,30,8x150 ; ISGenericMiniDisplayBar@125,30,8x150 ; ISGenericMiniDisplayBar@141,30,8x150 ; ISGenericMiniDisplayBar@149,30,8x150 ; ISGenericMiniDisplayBar@157,30,8x150 ; ISGenericMiniDisplayBar@165,30,8x150 ; ISGenericMiniDisplayBar@173,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@189,30,8x150 ; TTF_MHP_MiniHealthPanel@1860,944,120x271 ; SSBar@20,630,157x463 ; WaterMarkUI@3630,2070,200x22 ; ISMoodlesInLua@0,0,0x0 ; PSIOverlay@0,0,1x1 ; ZeD_BeltHUD@1378,2024,864x104 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1022,0,888x840 ; ZeD_Window@1920,0,888x840 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3B vanilla moodles, windows open: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3B shot zqa_r3B_8_hud_open.png
ZEDQA r3B shot zqa_r3B_9_hud_shut.png
ZEDQA r3B ui windows shut: NeedsUI@3501,2081,324x64 ; EnduranceUI@15,2097,350x48 ; ZeD_ActionBarLayer@0,0,1x1 ; MoodleQuartersUI@3782,1080,48x0 ; UIDebugConsole@20,1848,1280x292 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,48x507 ; ISHotbar@-10000,-10000,488x64 ; ISHealthBarManager@0,0,1x1 ; CHStatusHUD_UI@20,120,200x403 ; ISGenericMiniDisplayBar@70,15,15x15 ; ISGenericMiniDisplayBar@70,30,15x150 ; ISGenericMiniDisplayBar@85,30,8x150 ; ISGenericMiniDisplayBar@93,30,8x150 ; ISGenericMiniDisplayBar@101,30,8x150 ; ISGenericMiniDisplayBar@109,30,8x150 ; ISGenericMiniDisplayBar@117,30,8x150 ; ISGenericMiniDisplayBar@133,30,8x150 ; ISGenericMiniDisplayBar@125,30,8x150 ; ISGenericMiniDisplayBar@141,30,8x150 ; ISGenericMiniDisplayBar@149,30,8x150 ; ISGenericMiniDisplayBar@157,30,8x150 ; ISGenericMiniDisplayBar@165,30,8x150 ; ISGenericMiniDisplayBar@173,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@189,30,8x150 ; TTF_MHP_MiniHealthPanel@1860,944,120x271 ; SSBar@20,630,157x463 ; WaterMarkUI@3630,2070,200x22 ; ISMoodlesInLua@0,0,0x0 ; PSIOverlay@0,0,1x1 ; ZeD_BeltHUD@1378,2024,864x104 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3B vanilla windows shut: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3B shot zqa_r3B_10_health_wound.png
ZEDQA r3B shot zqa_r3B_11_skills_xp.png
ZEDQA r3B ui health: NeedsUI@3501,2081,324x64 ; EnduranceUI@15,2097,350x48 ; ZeD_ActionBarLayer@0,0,1x1 ; MoodleQuartersUI@3782,1080,48x0 ; UIDebugConsole@20,1848,1280x292 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,48x507 ; ISHotbar@-10000,-10000,488x64 ; ISHealthBarManager@0,0,1x1 ; CHStatusHUD_UI@20,120,200x403 ; ISGenericMiniDisplayBar@70,15,15x15 ; ISGenericMiniDisplayBar@70,30,15x150 ; ISGenericMiniDisplayBar@85,30,8x150 ; ISGenericMiniDisplayBar@93,30,8x150 ; ISGenericMiniDisplayBar@101,30,8x150 ; ISGenericMiniDisplayBar@109,30,8x150 ; ISGenericMiniDisplayBar@117,30,8x150 ; ISGenericMiniDisplayBar@133,30,8x150 ; ISGenericMiniDisplayBar@125,30,8x150 ; ISGenericMiniDisplayBar@141,30,8x150 ; ISGenericMiniDisplayBar@149,30,8x150 ; ISGenericMiniDisplayBar@157,30,8x150 ; ISGenericMiniDisplayBar@165,30,8x150 ; ISGenericMiniDisplayBar@173,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@189,30,8x150 ; TTF_MHP_MiniHealthPanel@1860,944,120x271 ; SSBar@20,630,157x463 ; WaterMarkUI@3630,2070,200x22 ; ISMoodlesInLua@0,0,0x0 ; PSIOverlay@0,0,1x1 ; ZeD_BeltHUD@1378,2024,864x104 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@62,0,1848x840 ; ZeD_Window@1920,0,888x840 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3B vanilla health: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3B ui end: NeedsUI@3501,2081,324x64 ; EnduranceUI@15,2097,350x48 ; ZeD_ActionBarLayer@0,0,1x1 ; MoodleQuartersUI@3782,1080,48x0 ; UIDebugConsole@20,1848,1280x292 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,48x507 ; ISHotbar@-10000,-10000,488x64 ; ISHealthBarManager@0,0,1x1 ; CHStatusHUD_UI@20,120,200x403 ; ISGenericMiniDisplayBar@70,15,15x15 ; ISGenericMiniDisplayBar@70,30,15x150 ; ISGenericMiniDisplayBar@85,30,8x150 ; ISGenericMiniDisplayBar@93,30,8x150 ; ISGenericMiniDisplayBar@101,30,8x150 ; ISGenericMiniDisplayBar@109,30,8x150 ; ISGenericMiniDisplayBar@117,30,8x150 ; ISGenericMiniDisplayBar@133,30,8x150 ; ISGenericMiniDisplayBar@125,30,8x150 ; ISGenericMiniDisplayBar@141,30,8x150 ; ISGenericMiniDisplayBar@149,30,8x150 ; ISGenericMiniDisplayBar@157,30,8x150 ; ISGenericMiniDisplayBar@165,30,8x150 ; ISGenericMiniDisplayBar@173,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@181,30,8x150 ; ISGenericMiniDisplayBar@189,30,8x150 ; TTF_MHP_MiniHealthPanel@1860,944,120x271 ; SSBar@20,630,157x463 ; WaterMarkUI@3630,2070,200x22 ; ISMoodlesInLua@0,0,0x0 ; PSIOverlay@0,0,1x1 ; ZeD_BeltHUD@1378,2024,864x104 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1022,0,888x840 ; ZeD_Window@1920,0,888x840 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3B vanilla end: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3B DONE
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 19 s

- go 13715 at 19:42:14

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
ZEDQA tabs armed
[ZeD.QA] run #3 ok=true
ZEDQA char tab=loot active=loot w=888 focusables=0 {}
ZEDQA char tab=equip active=equip w=1848 focusables=31 {equipgroup=5 equippart=17 equipslot=7 equipview=2}
ZEDQA char tab=health active=health w=1848 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1848 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1848 focusables=56 {hb=26 identity=30}
ZEDQA char tab=journal active=journal w=1848 focusables=8 {journal=4 jsub=4}
ZEDQA char tab=skills active=skills w=1848 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=888 focusables=0 {}
ZEDQA world tab=craft active=craft w=1848 focusables=10 {craft=10}
ZEDQA world tab=build active=build w=1848 focusables=8 {build=8}
ZEDQA world tab=furniture active=furniture w=1848 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1920 focusables=19 {map=19}
ZEDQA world tab=forage active=forage w=1846 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1846 focusables=3 {animals=3}
ZEDQA tabs done
```

### 4. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 20 s

- go 13716 at 19:42:37
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #4 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: THIRST | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 5 moodles on (THIRST 2, PANIC 1, STRESS 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,940 size 48, stack 280; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -562,12 504x140, trail right from -56,82
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS right: the trail ends at the moodle, level with it
ZEDQA mood left: 5 moodles on (THIRST 2, PANIC 1, STRESS 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,940 size 48, stack 280; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 106,12 504x140, trail left from 104,82
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS left: the trail ends at the moodle, level with it
ZEDQA mood bottom: 5 moodles on (THIRST 2, PANIC 1, STRESS 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1780,1952 280x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud -164,-198 504x140, trail down from 82,-56
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS bottom: the trail ends at the moodle, level with it
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 5. zedqa_charinfo.lua (`ZEDQA ci`) - PASS, 9 s

- go 13717 at 19:43:01

```text
[ZeD.QA] windows reset (R)
ZEDQA ci start
[ZeD.QA] run #5 ok=true
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

### 6. zedqa_exinfo.lua (`ZEDQA ex`) - PASS, 8 s

- go 13718 at 19:43:13
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #6 ok=true
ZEDQA ex ok squats desc is vanilla's tooltip
ZEDQA ex ok squats legs line
ZEDQA ex ok pushups: arms line only (chest has none)
ZEDQA ex ok burpees: legs and arms
ZEDQA ex ok situp abs line
ZEDQA ex ok regularity in 0..1
ZEDQA ex regularity squats 0
ZEDQA ex ok barbell curl without a barbell warns '(Requires Barbell)'
ZEDQA ex ok squats has no item warning
ZEDQA ex ok with a barbell the warning clears
ZEDQA ex ok unknown exercise gives nil
ZEDQA ex ok sitonground shows Stand up before exercising
ZEDQA ex ok reason gone after standing
ZEDQA ex tab health true | shown squats | reserved 398.6875 used 279.53125 w 440
ZEDQA ex ok block follows the focused pill (squats)
ZEDQA ex ok room reserved
ZEDQA ex ok block follows the focused pill (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex ok time buttons keep the last started exercise
ZEDQA ex ok time buttons start nothing and change no choice
ZEDQA ex ok block follows the focused pill (burpees)
ZEDQA ex DONE
```

### 7. suite_band.lua (`ZEDQA band`) - PASS, 4 s

- go 13719 at 19:43:25

```text
[ZeD.QA] windows reset (R)
ZEDQA band armed
[ZeD.QA] run #7 ok=true
ZEDQA band reading active=true kind=reading mode=nil label=READING pct=0.0466625802218914 time=nil (expect active reading)
ZEDQA band after cancel active=false kind=nil mode=nil label=nil pct=nil time=nil qlen=0 (expect inactive, 0)
ZEDQA band: no real stove within 20 tiles; cooking skipped
ZEDQA band done
```

### 8. zedqa_belt_hands.lua (`ZEDQA bh`) - PASS, 5 s

- go 13720 at 19:43:32
- screenshots: zqa_bh_1_left_wrist.png, zqa_bh_2_right_wrist.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bh start
[ZeD.QA] run #8 ok=true
ZEDQA bh PASS left wrist: the boxes run left to right (watch@0 OFF@104 #1@252 #2@362 #3@472 #4@732 MAIN@864)
ZEDQA bh PASS left wrist: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh PASS left wrist: the watch is left of the off hand
ZEDQA bh PASS left wrist: the full watch pops at the left end (left)
ZEDQA bh PASS pad: the belt starts on slot 1 (#1)
ZEDQA bh PASS pad: Left from slot 1 is the off hand (OFF)
ZEDQA bh PASS right wrist: the boxes run left to right (OFF@0 #1@148 #2@258 #3@368 #4@628 MAIN@760 watch@880)
ZEDQA bh PASS right wrist: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh PASS right wrist: the watch is right of the main hand
ZEDQA bh PASS right wrist: the full watch pops at the right end (right)
ZEDQA bh PASS as worn: the boxes run left to right (OFF@0 #1@148 #2@258 #3@368 #4@628 MAIN@760)
ZEDQA bh PASS as worn: the off hand at the left end, the main hand at the right, the slots between
ZEDQA bh all checks passed
ZEDQA bh DONE
```

### 9. zedqa_beltwatch.lua (`ZEDQA bw`) - PASS, 17 s

- go 13721 at 19:43:40
- screenshots: zqa_bw_1.png, zqa_bw_2.png, zqa_bw_3.png, zqa_bw_4.png, zqa_bw_5.png

```text
[ZeD.QA] windows reset (R)
ZEDQA bw start
[ZeD.QA] run #9 ok=true
ZEDQA bw worn base:leftwrist
ZEDQA bw box digital_black wrist left x 0 w 88 | hands s@104 p@864 | belt w 968
ZEDQA bw full watch tucked: 0x0
ZEDQA bw popped true at 1274,1662 248x352 | mini at 1274,2030
ZEDQA bw dragged to 1500,500 saved 750,250
ZEDQA bw after idle: popped false size 0
ZEDQA bw right wrist: timez_easy wrist right x 880 | hands s@0 p@760
ZEDQA bw corner: box false full watch 3524,10 300x352
ZEDQA bw DONE
```

### 10. zedqa_belt_strap.lua (`ZEDQA belt`) - PASS, 2 s

- go 13722 at 19:44:01
- screenshots: zqa_belt_strap_1.png

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #10 ok=true
ZEDQA belt textures true
ZEDQA belt shot; DONE
```

### 11. zedqa_ring_squares.lua (`ZEDQA rs`) - PASS, 11 s

- go 13723 at 19:44:06
- screenshots: zqa_rs_belt_full.png, zqa_rs_belt_70_45.png, zqa_rs_belt_15.png, zqa_rs_squares_on.png, zqa_rs_squares_off.png

```text
[ZeD.QA] windows reset (R)
ZEDQA rs start
[ZeD.QA] run #11 ok=true
ZEDQA rs belt at 1378,2024, hands: s 0,0 104 | p 760,0 104
ZEDQA rs PASS full: both hands on the belt
ZEDQA rs PASS full: the conditions read 1.00 / 1.00
ZEDQA rs belt at 1378,2024, hands: s 0,0 104 | p 760,0 104
ZEDQA rs PASS 70_45: both hands on the belt
ZEDQA rs PASS 70_45: the conditions read 0.70 / 0.50
ZEDQA rs belt at 1378,2024, hands: s 0,0 104 | p 760,0 104
ZEDQA rs PASS 15: both hands on the belt
ZEDQA rs PASS 15: the conditions read 0.20 / 0.20
ZEDQA rs window at 1022,0 888x840
ZEDQA rs PASS on: theme, accent, text and R squares in the footer
ZEDQA rs PASS off: the switch reads off
ZEDQA rs PASS off: no theme, accent or text square
ZEDQA rs PASS off: R stays, at the left where the theme square was
ZEDQA rs PASS off: the pointer over R lights R (hover 4)
ZEDQA rs PASS off: a press on R puts the windows back (1 press)
ZEDQA rs PASS on: the pointer over the theme square lights it (hover 1)
ZEDQA rs all checks passed
ZEDQA rs DONE
```

### 12. zedqa_messages.lua (`ZEDQA msg`) - PASS, 11 s

- go 13724 at 19:44:21
- 1 expected exception(s) ignored (expect=)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #12 ok=true
ZEDQA msg PASS nothing kept: no envelope on the belt
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
ERROR: General f:8243 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:8243> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:99)
ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
ZEDQA msg PASS Messages opens on the mod
    LOG  : Lua          f:8474> ZEDQA msg PASS opening it marks the mod's messages read
    OG  : Lua          f:8474> ZEDQA msg PASS four cards: three notes and the question (4)
ZEDQA msg PASS three OK buttons, one per note (3)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg PASS A on the next card's OK ran its callback
ZEDQA msg PASS the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (1446 characters)
ZEDQA msg PASS with the switch on, the mod's note shows as a pop-up
ZEDQA msg PASS Clear removes the mod's messages
ZEDQA msg PASS the last unanswered note got its OK as it left
ZEDQA msg all checks passed
ZEDQA msg DONE
```

### 13. suite_perf.lua (`ZEDQA perf`) - PASS, 57 s

- go 13725 at 19:44:35

```text
[ZeD.QA] windows reset (R)
[ZeD.QA] run #13 ok=true
ZEDQA perf char loot avg=18.24ms/tick max=39ms
ZEDQA perf char equip avg=22.14ms/tick max=58ms
ZEDQA perf char health avg=20.95ms/tick max=78ms
ZEDQA perf char thermal avg=23.72ms/tick max=71ms
ZEDQA perf char identity avg=19.64ms/tick max=45ms
ZEDQA perf char journal avg=19.13ms/tick max=52ms
ZEDQA perf char skills avg=23.91ms/tick max=57ms
ZEDQA perf world craft avg=19.74ms/tick max=46ms
ZEDQA perf world build avg=18.61ms/tick max=54ms
ZEDQA perf world maps avg=21.00ms/tick max=50ms
ZEDQA perf world forage avg=22.14ms/tick max=44ms
ZEDQA perf world animals avg=19.58ms/tick max=57ms
ZEDQA perf world loot avg=16.83ms/tick max=44ms
ZEDQA perf world craft build: 10 elements, 0.07 ms per build
ZEDQA perf done
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
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
