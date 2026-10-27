# ZeD-UI regression - 2026-10-26 20:10 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 20:10:04 |
| Finished | 2026-10-26 20:14:40 (4 min 36 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_C.txt (8 scripts) |
| Result | **8/8 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13739 to 13748 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13747, 13748)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_r3_C.lua | r3C | PASS | 42 | zqa_r3C_1_loot.png, zqa_r3C_2_menu_apple.png, zqa_r3C_3_menu_world.png, zqa_r3C_4_tip_shirt_zed.png, zqa_r3C_5_tip_shirt_safe.png, zqa_r3C_4_tip_book_zed.png, zqa_r3C_5_tip_book_safe.png, zqa_r3C_4_tip_vhs_zed.png, zqa_r3C_5_tip_vhs_safe.png, zqa_r3C_4_tip_seed_zed.png, zqa_r3C_5_tip_seed_safe.png, zqa_r3C_6_char_equip.png, zqa_r3C_6_char_health.png, zqa_r3C_6_char_skills.png, zqa_r3C_6_char_identity.png, zqa_r3C_7_world_craft.png, zqa_r3C_7_world_build.png, zqa_r3C_7_world_maps.png, zqa_r3C_8_skills_xp.png, zqa_r3C_9_char_traits.png, zqa_r3C_10_rpgtree.png |  |
| 3 | zedqa_traits.lua | tas | PASS | 24 | zqa_tas_tab.png, zqa_tas_details.png, zqa_tas_step_hover.png, zqa_tas_with_trait.png, zqa_tas_folded.png, zqa_tas_find.png, zqa_tas_pad_row.png, zqa_tas_new.png, zqa_tas_large.png, zqa_tas_light.png |  |
| 4 | suite_tabs.lua | tabs | PASS | 11 |  |  |
| 5 | zedqa_exinfo.lua | ex | PASS | 6 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png |  |
| 6 | zedqa_charinfo.lua | ci | PASS | 9 |  |  |
| 7 | zedqa_moodles.lua | mood | PASS | 18 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 8 | zedqa_messages.lua | msg | PASS | 10 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13739 at 20:11:41

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_r3_C.lua (`ZEDQA r3C`) - PASS, 42 s

- go 13740 at 20:11:46
- screenshots: zqa_r3C_1_loot.png, zqa_r3C_2_menu_apple.png, zqa_r3C_3_menu_world.png, zqa_r3C_4_tip_shirt_zed.png, zqa_r3C_5_tip_shirt_safe.png, zqa_r3C_4_tip_book_zed.png, zqa_r3C_5_tip_book_safe.png, zqa_r3C_4_tip_vhs_zed.png, zqa_r3C_5_tip_vhs_safe.png, zqa_r3C_4_tip_seed_zed.png, zqa_r3C_5_tip_seed_safe.png, zqa_r3C_6_char_equip.png, zqa_r3C_6_char_health.png, zqa_r3C_6_char_skills.png, zqa_r3C_6_char_identity.png, zqa_r3C_7_world_craft.png, zqa_r3C_7_world_build.png, zqa_r3C_7_world_maps.png, zqa_r3C_8_skills_xp.png, zqa_r3C_9_char_traits.png, zqa_r3C_10_rpgtree.png

```text
[ZeD.QA] windows reset (R)
ZEDQA r3C start
[ZeD.QA] run #2 ok=true
ZEDQA r3C shot zqa_r3C_1_loot.png
ZEDQA r3C ui loot: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla loot: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C shot zqa_r3C_2_menu_apple.png
ZEDQA r3C world menu: Sit on ground, Walk to
ZEDQA r3C shot zqa_r3C_3_menu_world.png
ZEDQA r3C shot zqa_r3C_4_tip_shirt_zed.png
ZEDQA r3C tip shirt zed 238x96
ZEDQA r3C shot zqa_r3C_5_tip_shirt_safe.png
ZEDQA r3C tip shirt safe 238x93
ZEDQA r3C shot zqa_r3C_4_tip_book_zed.png
ZEDQA r3C tip book zed 297x79
ZEDQA r3C shot zqa_r3C_5_tip_book_safe.png
ZEDQA r3C tip book safe 297x76
ZEDQA r3C shot zqa_r3C_4_tip_vhs_zed.png
ZEDQA r3C tip vhs zed 189x45
ZEDQA r3C shot zqa_r3C_5_tip_vhs_safe.png
ZEDQA r3C tip vhs safe 189x42
ZEDQA r3C shot zqa_r3C_4_tip_seed_zed.png
ZEDQA r3C tip seed zed 202x79
ZEDQA r3C shot zqa_r3C_5_tip_seed_safe.png
ZEDQA r3C tip seed safe 202x76
ZEDQA r3C ui after safe mode: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla after safe mode: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C shot zqa_r3C_6_char_equip.png
ZEDQA r3C shot zqa_r3C_6_char_health.png
ZEDQA r3C shot zqa_r3C_6_char_skills.png
ZEDQA r3C shot zqa_r3C_6_char_identity.png
ZEDQA r3C shot zqa_r3C_7_world_craft.png
ZEDQA r3C shot zqa_r3C_7_world_build.png
ZEDQA r3C shot zqa_r3C_7_world_maps.png
ZEDQA r3C ui tabs walked: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C shot zqa_r3C_8_skills_xp.png
ZEDQA r3C shot zqa_r3C_9_char_traits.png
ZEDQA r3C shot zqa_r3C_10_rpgtree.png
ZEDQA r3C note: the game was paused after rpg tree (unpaused)
ZEDQA r3C ui rpg tree: ZeD_ActionBarLayer@0,0,1x1 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_Window@294,0,1617x735 ; ZeD_Window@1929,0,777x735 ; RPGSkillTreeUI@0,0,3840x2160 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla rpg tree: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C closed 1
ZEDQA r3C ui end: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,1080,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ISXPBar@1770,2080,300x20 ; ISExpBar@3440,200,155x38 ; ListenModeRender@0,0,0x0 ; WaterMarkUI@3604,2127,226x22 ; ISMoodlesInLua@0,0,0x0 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; PK42FrenzyMoodleUI@0,0,1x1 ; ISButton@10,646,48x36 ; ISMoodles@3782,120,48x48 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_MessagesToasts@0,0,1x1
ZEDQA r3C vanilla end: inventory page shown false, loot page shown false, info panel shown false
ZEDQA r3C DONE
```

### 3. zedqa_traits.lua (`ZEDQA tas`) - PASS, 24 s

- go 13741 at 20:12:31
- screenshots: zqa_tas_tab.png, zqa_tas_details.png, zqa_tas_step_hover.png, zqa_tas_with_trait.png, zqa_tas_folded.png, zqa_tas_find.png, zqa_tas_pad_row.png, zqa_tas_new.png, zqa_tas_large.png, zqa_tas_light.png

```text
[ZeD.QA] windows reset (R)
ZEDQA tas start
[ZeD.QA] run #3 ok=true
ZEDQA tas tabs: loot,equip,health,thermal,identity,journal,skills,traits,radio
ZEDQA tas PASS the Traits tab sits right after Skills
ZEDQA tas PASS the Traits tab is on the strip
ZEDQA tas PASS it has the lit pixel-art icon
ZEDQA tas PASS the Character window is on Traits
ZEDQA tas PASS one row per ladder in the mod's registry: 43 / 43
ZEDQA tas categories: inteligencia,physical,behavior,social,skills
ZEDQA tas PASS Mind first
ZEDQA tas PASS Skills last
ZEDQA tas ladders with a trait now: 22
ZEDQA tas PASS the Find box shows in the heading
ZEDQA tas shot zqa_tas_tab.png
ZEDQA tas PASS a row has a click zone
ZEDQA tas PASS a click picks the row for the details: TAS.Courage
ZEDQA tas shot zqa_tas_details.png
ZEDQA tas PASS hovering a step names its trait and level
ZEDQA tas shot zqa_tas_step_hover.png
ZEDQA tas PASS With a trait
ZEDQA tas PASS only ladders that give a trait are listed
ZEDQA tas shot zqa_tas_with_trait.png
ZEDQA tas PASS All again
ZEDQA tas PASS a click folds the category
ZEDQA tas shot zqa_tas_folded.png
ZEDQA tas PASS Find takes the typed text: read
ZEDQA tas PASS Find narrows the list (1 rows)
ZEDQA tas shot zqa_tas_find.png
ZEDQA tas PASS focus on the Traits tab in the strip
ZEDQA tas into the tab from the strip: tas:row:TAS.Reading
ZEDQA tas PASS the D-pad goes into the tab
ZEDQA tas PASS Find is a stop
ZEDQA tas PASS down from Find: All | With a trait (tas:only)
ZEDQA tas PASS right picks With a trait
ZEDQA tas PASS left picks All
ZEDQA tas PASS down: the first category (tas:cat:inteligencia)
ZEDQA tas PASS A folds the category
ZEDQA tas PASS down: a row (tas:row:TAS.Courage)
ZEDQA tas PASS the details follow focus with no press
ZEDQA tas PASS walking rows moves the details: tas:row:TAS.Learning
ZEDQA tas PASS A on a row does nothing
ZEDQA tas shot zqa_tas_pad_row.png
ZEDQA tas addXP Reading: true true
ZEDQA tas Reading now level 9, traits thisisme:geek,thisisme:booklover,thisisme:leisurewriter,FAST_READER
ZEDQA tas PASS a trait gained since the last visit carries NEW
ZEDQA tas shot zqa_tas_new.png
ZEDQA tas shot zqa_tas_large.png
ZEDQA tas shot zqa_tas_light.png
ZEDQA tas all checks passed
ZEDQA tas DONE
```

### 4. suite_tabs.lua (`ZEDQA tabs`) - PASS, 11 s

- go 13742 at 20:12:59

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills,traits
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals
ZEDQA tabs armed
[ZeD.QA] run #4 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=32 {equipgroup=5 equippart=17 equipslot=8 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=68 {hb=33 identity=35}
ZEDQA char tab=journal active=journal w=1617 focusables=8 {journal=4 jsub=4}
ZEDQA char tab=skills active=skills w=1617 focusables=77 {skill=39 skills=1 training=37}
ZEDQA char tab=traits active=traits w=1617 focusables=50 {tas=50}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1682 focusables=19 {map=19}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA tabs done
```

### 5. zedqa_exinfo.lua (`ZEDQA ex`) - PASS, 6 s

- go 13743 at 20:13:14
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #5 ok=true
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
ZEDQA ex tab health true | shown squats | reserved 450.86328125 used 282.48828125 w 329
ZEDQA ex ok block follows the focused pill (squats)
ZEDQA ex ok room reserved
ZEDQA ex ok block follows the focused pill (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex ok time buttons keep the last started exercise
ZEDQA ex ok time buttons start nothing and change no choice
ZEDQA ex ok block follows the focused pill (burpees)
ZEDQA ex DONE
```

### 6. zedqa_charinfo.lua (`ZEDQA ci`) - PASS, 9 s

- go 13744 at 20:13:23

```text
[ZeD.QA] windows reset (R)
ZEDQA ci start
[ZeD.QA] run #6 ok=true
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

### 7. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 18 s

- go 13745 at 20:13:36
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #7 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: STRESS | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (STRESS 2, TIRED 2, HUNGRY 2, THIRST 2)
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
ZEDQA mood left: 4 moodles on (STRESS 2, TIRED 2, HUNGRY 2, THIRST 2)
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
ZEDQA mood bottom: 4 moodles on (STRESS 2, TIRED 2, HUNGRY 2, THIRST 2)
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
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 8. zedqa_messages.lua (`ZEDQA msg`) - PASS, 10 s

- go 13746 at 20:13:58
- 1 expected exception(s) ignored (expect=)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
[ZeD.QA] windows reset (R)
ZEDQA msg start
[ZeD.QA] run #8 ok=true
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
ERROR: General f:9105 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:9105> Lua(Vanilla).boom> Exception thrown   (expected)
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
ZEDQA msg all checks passed
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
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: General f:N at InputScript.OnPostWorldDictionaryInit> MakeBoneForearmArmor item not found: LabItems.LabSmallRandomHumanBones. line: item 5 [Base.SmallAnimalBone;LabItems.LabSmallRandomHumanBones] flags[Prop2]
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
