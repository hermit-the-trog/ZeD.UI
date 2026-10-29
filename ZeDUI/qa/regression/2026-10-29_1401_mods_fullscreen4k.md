# ZeD-UI regression - 2026-10-29 14:01 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 14:01:17 |
| Finished | 2026-10-29 14:05:31 (4 min 13 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/compat_r4b.txt (12 scripts) |
| Result | **11/12 pass**, 0 warn, 1 fail, 0 timeout |
| Go numbers | 15725 to 15738 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15737, 15738)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_small_probe.lua | sp | PASS | 4 | zqa_sp_bare.png, zqa_sp_pair.png |  |
| 3 | suite_tabs.lua | tabs | PASS | 11 |  |  |
| 4 | zedqa_grid.lua | grid | PASS | 7 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 5 | zedqa_ctxlist.lua | cl | **FAIL** | 5 | zqa_cl_1.png, zqa_cl_2.png | 1 Java exception(s) in the log |
| 6 | zedqa_card_pad.lua | cp | PASS | 4 | zqa_cp_card.png |  |
| 7 | zedqa_navmap.lua | nav | PASS | 10 |  |  |
| 8 | zedqa_exinfo.lua | ex | PASS | 7 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png |  |
| 9 | zedqa_dash_props_smoke.lua | sm | PASS | 9 | zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png |  |
| 10 | zedqa_mapshot.lua | ms | PASS | 4 | zqa_ms_1.png, zqa_ms_2.png |  |
| 11 | zedqa_moodles.lua | mood | PASS | 19 | zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png |  |
| 12 | zedqa_messages.lua | msg | PASS | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 15725 at 14:02:50

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_small_probe.lua (`ZEDQA sp`) - PASS, 4 s

- go 15726 at 14:02:55
- screenshots: zqa_sp_bare.png, zqa_sp_pair.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sp screen 3840x2160 root=1.750
ZEDQA sp vanilla char info: visible=false @2415,794 290x250 visibleOnStartup=false
ZEDQA sp ZeD Character @1134,0 777x735
ZEDQA sp ZeD World @1929,0 777x735
ZEDQA sp pair el ZeD_ActionBarLayer @0,0 1x1
ZEDQA sp pair el UIDebugConsole @20,1848 1280x292
ZEDQA sp pair el ISButtonPrompt @0,0 1x1
ZEDQA sp pair el ISEquippedItem @10,10 53x621
ZEDQA sp pair el ISHotbar @-10000,-10000 256x82
ZEDQA sp pair el XEGMiniHealth @19,1728 182x413
ZEDQA sp pair el XEGMoodleBar @3778,120 52x56
ZEDQA sp pair el WaterMarkUI @3600,2127 230x22
ZEDQA sp pair el XEGCompass @1641,12 558x97
ZEDQA sp pair el XEGHudPanel @0,0 351x131
ZEDQA sp pair el XEGHudPanel @0,0 421x131
ZEDQA sp pair el XEGHudPanel @-10000,0 10x10
ZEDQA sp pair el XEGHudMenuBtn @-10000,0 20x20
ZEDQA sp pair el XEGQuickAccess @0,0 1x1
ZEDQA sp pair el ZeD_BeltHUD @1439,2034 758x98
ZEDQA sp pair el ZeD_MoodleLayer @3782,1080 48x2160
ZEDQA sp pair el ZeD_Watch @3596,10 228x52
ZEDQA sp pair el ZeD_Window @1134,0 777x735
ZEDQA sp pair el ZeD_Window @1929,0 777x735
ZEDQA sp pair el XEGMoodleTip @-10,-10 1x1
ZEDQA sp pair el ZeD_MessagesToasts @0,0 1x1
ZEDQA sp pair visible elements with a size: 21
[ZeD.QA] run #2 ok=true
ZEDQA sp bare el ZeD_ActionBarLayer @0,0 1x1
ZEDQA sp bare el SpeedControls @3641,-4000 189x28
ZEDQA sp bare el UIDebugConsole @20,1848 1280x292
ZEDQA sp bare el ISButtonPrompt @0,0 1x1
ZEDQA sp bare el ISEquippedItem @10,10 53x621
ZEDQA sp bare el ISHotbar @-10000,-10000 256x82
ZEDQA sp bare el XEGMiniHealth @19,1728 182x413
ZEDQA sp bare el XEGMoodleBar @3778,120 52x56
ZEDQA sp bare el WaterMarkUI @3600,2127 230x22
ZEDQA sp bare el XEGCompass @1641,12 558x97
ZEDQA sp bare el XEGHudPanel @0,0 351x131
ZEDQA sp bare el XEGHudPanel @0,0 421x131
ZEDQA sp bare el XEGHudPanel @-10000,0 10x10
ZEDQA sp bare el XEGHudMenuBtn @-10000,0 20x20
ZEDQA sp bare el XEGQuickAccess @0,0 1x1
ZEDQA sp bare el ZeD_BeltHUD @1439,2034 758x98
ZEDQA sp bare el ZeD_MoodleLayer @3782,1080 48x2160
ZEDQA sp bare el ZeD_Watch @3596,10 228x52
ZEDQA sp bare el XEGMoodleTip @-10,-10 1x1
ZEDQA sp bare el ZeD_MessagesToasts @0,0 1x1
ZEDQA sp bare visible elements with a size: 20
ZEDQA sp shot zqa_sp_bare.png
ZEDQA sp shot zqa_sp_pair.png
ZEDQA sp DONE
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 11 s

- go 15727 at 14:03:03

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA tabs armed
[ZeD.QA] run #3 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=34 {equipbelt=1 equipgroup=5 equippart=17 equipslot=9 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=13 {hb=2 identity=11}
ZEDQA char tab=journal active=journal w=1617 focusables=6 {journal=2 jsub=4}
ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=12 {craft=12}
ZEDQA world tab=build active=build w=1617 focusables=15 {build=15}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1694 focusables=17 {map=17}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA world tab=vehicle active=vehicle w=1617 focusables=1 {mech=1}
ZEDQA tabs done
```

### 4. zedqa_grid.lua (`ZEDQA grid`) - PASS, 7 s

- go 15728 at 14:03:17
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #4 ok=true
ZEDQA grid grid on: cell 91 | cells placed 30 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Apple (Fresh)
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:8 item=Cigarette
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Baseball Cap
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 5. zedqa_ctxlist.lua (`ZEDQA cl`) - FAIL, 5 s

- go 15729 at 14:03:27
- 1 Java exception(s) in the log
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #5 ok=true
WARN : General f:3355> Translator.reportMissingArgumentsFromPastAbuse> Exception thrown java.util.MissingFormatArgumentException: Format specifier '%s' at Formatter.format(null:-1). Message: ERROR: Missing arguments for "IGUI_XEG_fbb6ca3a"
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Add to Quick Access, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 6. zedqa_card_pad.lua (`ZEDQA cp`) - PASS, 4 s

- go 15730 at 14:03:36
- screenshots: zqa_cp_card.png

```text
[ZeD.QA] windows reset (R)
ZEDQA cp start
[ZeD.QA] run #6 ok=true
ZEDQA cp card open false | card buttons 0 {}
ZEDQA cp fav chip rect on the card (mouse): false
ZEDQA cp before left: zone=charMainInv el=view:list:player
ZEDQA cp after left (expect charItemCard): zone=charTabBar el=tab:loot
ZEDQA cp right 1: zone=charMainInv el=view:list:player
ZEDQA cp right 2: zone=charMainInv el=view:grid:player
ZEDQA cp left: zone=charMainInv el=view:list:player
ZEDQA cp after B: card item nil (expect nil)
ZEDQA cp health: inv then left (expect charTabContent): zone=charTabContent el=bodypart:Head
ZEDQA cp health: right: zone=charMainInv el=invrow:1
ZEDQA cp DONE
```

### 7. zedqa_navmap.lua (`ZEDQA nav`) - PASS, 10 s

- go 15731 at 14:03:43

```text
[ZeD.QA] windows reset (R)
ZEDQA nav start
[ZeD.QA] run #7 ok=true
ZEDQA nav char loot: 44 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char loot STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:30(D) view:list:player(U) view:grid:player(U) container:1(U)
ZEDQA nav char loot charTabBar:tab:loot U>- D>tab:equip L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charMainInv:invrow:1
ZEDQA nav char loot charTabBar:tab:skills U>tab:journal D>charMainInv:invrow:7~ L>- R>charMainInv:invrow:1
ZEDQA nav char loot charMainInv:invrow:1 U>view:list:player~ D>invrow:2 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabBar:tab:loot R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:14 U>invrow:13 D>invrow:15 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:15 U>invrow:14 D>invrow:16 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:16 U>invrow:15 D>invrow:17 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:17 U>invrow:16 D>invrow:18 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:18 U>invrow:17 D>invrow:19 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:19 U>invrow:18 D>invrow:20 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:20 U>invrow:19 D>invrow:21 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:21 U>invrow:20 D>invrow:22 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:22 U>invrow:21 D>invrow:23 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:23 U>invrow:22 D>invrow:24 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:24 U>invrow:23 D>invrow:25 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:25 U>invrow:24 D>invrow:26 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:26 U>invrow:25 D>invrow:27 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:27 U>invrow:26 D>invrow:28 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:28 U>invrow:27 D>invrow:29 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:29 U>invrow:28 D>invrow:30 L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:invrow:30 U>invrow:29 D>- L>charTabBar:tab:loot~ R>charContainerStrip:container:1
ZEDQA nav char loot charMainInv:view:list:player U>- D>invrow:1~ L>charTabBar:tab:loot R>view:grid:player
ZEDQA nav char loot charMainInv:view:grid:player U>- D>invrow:1~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char loot charContainerStrip:container:1 U>- D>container:2 L>charMainInv:view:grid:player R>window:World
ZEDQA nav char loot charContainerStrip:container:2 U>container:1 D>charMainInv:invrow:2~ L>charMainInv:invrow:1 R>window:World
ZEDQA nav char loot charCtl:charCtl:xfer U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charTabBar:tab:loot~ R>charMainInv:invrow:10
ZEDQA nav char loot charCtl:charCtl:same U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:xfer R>charMainInv:invrow:10
ZEDQA nav char loot charCtl:charCtl:near U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:same R>charMainInv:invrow:10
ZEDQA nav char equip: 78 targets | TRAP 8 {equipslot:INR,equipslot:GLV,equipslot:PNT,equipslot:SOC,equipslot:BOT,equipslot:KNE,equipslot:BAG,equipslot:BLT} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char equip STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) equipview:list(U) equipview:doll(U) invrow:30(D) view:list:player(U) view:grid:player(U) container:1(U)
ZEDQA nav char equip charTabBar:tab:loot U>- D>tab:equip L>- R>charTabContent:equipslot:__disclosure
ZEDQA nav char equip charTabBar:tab:equip U>tab:loot D>tab:health L>- R>charTabContent:equipgroup:head
ZEDQA nav char equip charTabBar:tab:health U>tab:equip D>tab:thermal L>- R>charTabContent:equipgroup:torso
ZEDQA nav char equip charTabBar:tab:thermal U>tab:health D>tab:identity L>- R>charTabContent:equipgroup:arms
ZEDQA nav char equip charTabBar:tab:identity U>tab:thermal D>tab:journal L>- R>charTabContent:equipgroup:legs
ZEDQA nav char equip charTabBar:tab:journal U>tab:identity D>tab:skills L>- R>charTabContent:equipslot:PNT
ZEDQA nav char equip charTabBar:tab:skills U>tab:journal D>charTabContent:equipslot:BOT~ L>- R>charTabContent:equipslot:SOC
ZEDQA nav char equip charTabContent:equipslot:__disclosure U>charTabBar:tab:equip~ D>equipgroup:head L>charTabBar:tab:equip R>equipview:list
ZEDQA nav char equip charTabContent:equipview:list U>- D>equipgroup:head L>equipslot:__disclosure R>equipview:doll
ZEDQA nav char equip charTabContent:equipview:doll U>- D>equipgroup:head L>equipslot:__disclosure R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equippart:Head U>equipbelt:1 D>equippart:Neck L>equippart:Neck R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equippart:Neck U>equippart:Head D>equippart:Upper Torso L>charTabBar:tab:equip~ R>equippart:Head
ZEDQA nav char equip charTabContent:equippart:Upper Torso U>equippart:Neck D>equippart:Lower Torso L>equippart:Right Upper Arm R>equippart:Left Upper Arm
ZEDQA nav char equip charTabContent:equippart:Right Upper Arm U>equippart:Upper Torso D>equippart:Right Forearm L>equippart:Right Forearm R>equippart:Upper Torso
ZEDQA nav char equip charTabContent:equippart:Left Upper Arm U>equippart:Upper Torso D>equippart:Left Forearm L>equippart:Upper Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Lower Torso U>equippart:Upper Torso D>equippart:Groin L>equippart:Right Upper Arm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Right Forearm U>equippart:Right Upper Arm D>equippart:Right Hand L>equippart:Right Hand R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Forearm U>equippart:Left Upper Arm D>equippart:Left Hand L>equippart:Groin R>equippart:Left Hand
ZEDQA nav char equip charTabContent:equippart:Groin U>equippart:Lower Torso D>equippart:Right Upper Leg L>equippart:Lower Torso R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Hand U>equippart:Right Forearm D>equippart:Right Upper Leg~ L>charTabBar:tab:equip~ R>equippart:Right Forearm
ZEDQA nav char equip charTabContent:equippart:Left Hand U>equippart:Left Forearm D>equippart:Left Upper Leg~ L>equippart:Left Forearm R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equippart:Right Upper Leg U>equippart:Groin D>equippart:Right Lower Leg L>equippart:Right Forearm R>equippart:Groin
ZEDQA nav char equip charTabContent:equippart:Left Upper Leg U>equippart:Groin D>equippart:Left Lower Leg L>equippart:Groin R>equippart:Left Forearm
ZEDQA nav char equip charTabContent:equippart:Right Lower Leg U>equippart:Right Upper Leg D>equippart:Right Foot L>equippart:Right Foot R>equippart:Right Upper Leg
ZEDQA nav char equip charTabContent:equippart:Left Lower Leg U>equippart:Left Upper Leg D>equippart:Left Foot L>equippart:Left Upper Leg R>equippart:Left Foot
ZEDQA nav char equip charTabContent:equippart:Right Foot U>equippart:Right Lower Leg D>charMainInv:invrow:23~ L>charTabBar:tab:equip~ R>equippart:Right Lower Leg
ZEDQA nav char equip charTabContent:equippart:Left Foot U>equippart:Left Lower Leg D>charMainInv:invrow:23~ L>equippart:Left Lower Leg R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:head U>equipslot:__disclosure D>equipgroup:torso L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:torso U>equipgroup:head D>equipslot:INR L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:arms U>equipslot:INR D>equipslot:GLV L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:legs U>equipslot:GLV D>equipslot:PNT L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipgroup:held U>equipslot:KNE D>equipslot:BAG L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:INR [OWN D-PAD] U>equipgroup:torso D>equipgroup:arms L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:GLV [OWN D-PAD] U>equipgroup:arms D>equipgroup:legs L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:PNT [OWN D-PAD] U>equipgroup:legs D>equipslot:SOC L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:SOC [OWN D-PAD] U>equipslot:PNT D>equipslot:BOT L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:BOT [OWN D-PAD] U>equipslot:SOC D>equipslot:KNE L>charTabBar:tab:equip R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:KNE [OWN D-PAD] U>equipslot:BOT D>equipgroup:held L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:BAG [OWN D-PAD] U>equipgroup:held D>equipslot:BLT L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipslot:BLT [OWN D-PAD] U>equipslot:BAG D>equipbelt:1 L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charTabContent:equipbelt:1 U>equipslot:BLT D>equippart:Head L>charTabBar:tab:equip~ R>charMainInv:invrow:1
ZEDQA nav char equip charMainInv:invrow:1 U>view:list:player~ D>invrow:2 L>charTabContent:equipgroup:torso R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:2 U>invrow:1 D>invrow:3 L>charTabContent:equipslot:INR R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:3 U>invrow:2 D>invrow:4 L>charTabContent:equipgroup:arms R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:4 U>invrow:3 D>invrow:5 L>charTabContent:equipgroup:legs R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:5 U>invrow:4 D>invrow:6 L>charTabContent:equipslot:PNT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:6 U>invrow:5 D>invrow:7 L>charTabContent:equipslot:SOC R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:7 U>invrow:6 D>invrow:8 L>charTabContent:equipslot:BOT R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:8 U>invrow:7 D>invrow:9 L>charTabContent:equipslot:KNE R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:9 U>invrow:8 D>invrow:10 L>charTabContent:equipgroup:held R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:10 U>invrow:9 D>invrow:11 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:11 U>invrow:10 D>invrow:12 L>charCtl:charCtl:xfer R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:12 U>invrow:11 D>invrow:13 L>charTabContent:equipbelt:1 R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:13 U>invrow:12 D>invrow:14 L>charTabContent:equipbelt:1 R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:14 U>invrow:13 D>invrow:15 L>charTabContent:equippart:Head R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:15 U>invrow:14 D>invrow:16 L>charTabContent:equippart:Left Upper Arm R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:16 U>invrow:15 D>invrow:17 L>charTabContent:equippart:Left Upper Arm R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:17 U>invrow:16 D>invrow:18 L>charTabContent:equippart:Left Forearm R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:18 U>invrow:17 D>invrow:19 L>charTabContent:equippart:Left Forearm R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:19 U>invrow:18 D>invrow:20 L>charTabContent:equippart:Left Hand R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:20 U>invrow:19 D>invrow:21 L>charTabContent:equippart:Left Upper Leg R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:21 U>invrow:20 D>invrow:22 L>charTabContent:equippart:Left Lower Leg R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:22 U>invrow:21 D>invrow:23 L>charTabContent:equippart:Left Foot R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:23 U>invrow:22 D>invrow:24 L>charTabContent:equippart:Left Foot R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:24 U>invrow:23 D>invrow:25 L>charTabContent:equippart:Left Foot~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:25 U>invrow:24 D>invrow:26 L>charTabContent:equippart:Left Foot~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:26 U>invrow:25 D>invrow:27 L>charTabContent:equippart:Left Foot~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:27 U>invrow:26 D>invrow:28 L>charTabContent:equippart:Left Foot~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:28 U>invrow:27 D>invrow:29 L>charTabContent:equippart:Left Foot~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:29 U>invrow:28 D>invrow:30 L>charTabContent:equippart:Left Foot~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:invrow:30 U>invrow:29 D>- L>charTabContent:equippart:Left Foot~ R>charContainerStrip:container:1
ZEDQA nav char equip charMainInv:view:list:player U>- D>invrow:1~ L>charTabContent:equipslot:__disclosure R>view:grid:player
ZEDQA nav char equip charMainInv:view:grid:player U>- D>invrow:1~ L>view:list:player R>charContainerStrip:container:1
ZEDQA nav char equip charContainerStrip:container:1 U>- D>container:2 L>charMainInv:view:grid:player R>window:World
ZEDQA nav char equip charContainerStrip:container:2 U>container:1 D>charMainInv:invrow:2~ L>charMainInv:invrow:1 R>window:World
ZEDQA nav char equip charCtl:charCtl:xfer U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charTabContent:equipslot:BLT R>charMainInv:invrow:10
ZEDQA nav char equip charCtl:charCtl:same U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:xfer R>charMainInv:invrow:10
ZEDQA nav char equip charCtl:charCtl:near U>charMainInv:invrow:10 D>charMainInv:invrow:11 L>charCtl:same R>charMainInv:invrow:10
ZEDQA nav char health: 71 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char health STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:30(D) view:list:player(U) view:grid:player(U) container:1(U)
ZEDQA nav char thermal: 70 targets | TRAP 1 {thermal:__gridscroll} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char thermal STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:30(D) view:list:player(U) view:grid:player(U) container:1(U)
ZEDQA nav char identity: 57 targets | TRAP 1 {hb:part} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char identity STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:30(D) view:list:player(U) view:grid:player(U) container:1(U)
ZEDQA nav char journal: 50 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char journal STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) invrow:30(D) view:list:player(U) view:grid:player(U) container:1(U)
ZEDQA nav char skills: 104 targets | TRAP 0 {} | ISLAND 1 {charCtl:charCtl:near}
ZEDQA nav char skills STUCK: tab:loot(UL) tab:equip(L) tab:health(L) tab:thermal(L) tab:identity(L) tab:journal(L) tab:skills(L) training:col1_Foraging(D) training:col2_Trapping(D) view:list:player(U) view:grid:player(U) container:1(U)
ZEDQA nav world loot: 11 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world loot STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world loot worldContainerStrip:container:1 U>- D>worldCtl:worldCtl:take~ L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world loot worldTabBar:tab:loot U>- D>tab:craft L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:craft U>tab:loot D>tab:build L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldCtl:worldCtl:same R>-
ZEDQA nav world loot worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldTabBar:tab:vehicle U>tab:animals D>worldCtl:worldCtl:same~ L>worldCtl:worldCtl:same~ R>-
ZEDQA nav world loot worldCtl:worldCtl:take U>worldContainerStrip:container:1 D>- L>worldContainerStrip:container:1 R>worldCtl:same
ZEDQA nav world loot worldCtl:worldCtl:same U>worldContainerStrip:container:1 D>- L>worldCtl:take R>worldTabBar:tab:loot~
ZEDQA nav world craft: 23 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world craft STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world build: 26 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world build STUCK: container:1(U) build:catDrop(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world furniture: 16 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world furniture STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps: 28 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world maps STUCK: container:1(U) map:tool:house(U) map:tool:target(U) map:tool:skull(U) map:tool:star(U) map:tool:cross(U) map:tool:checkmark(U) map:tool:text(U) map:style:menu(U) map:popout(U) map:ext:key(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world maps worldContainerStrip:container:1 U>- D>worldCtl:worldCtl:take~ L>window:Character R>worldCtl:worldCtl:take
ZEDQA nav world maps worldTabContent:map:disclosure U>worldContainerStrip:container:1 D>map:canvas:cursor L>worldCtl:worldCtl:same R>map:tool:house
ZEDQA nav world maps worldTabContent:map:tool:house U>- D>map:canvas:cursor L>map:disclosure R>map:tool:target
ZEDQA nav world maps worldTabContent:map:tool:target U>- D>map:canvas:cursor L>map:tool:house R>map:tool:skull
ZEDQA nav world maps worldTabContent:map:tool:skull U>- D>map:canvas:cursor L>map:tool:target R>map:tool:star
ZEDQA nav world maps worldTabContent:map:tool:star U>- D>map:canvas:cursor L>map:tool:skull R>map:tool:cross
ZEDQA nav world maps worldTabContent:map:tool:cross U>- D>map:canvas:cursor L>map:tool:star R>map:tool:checkmark
ZEDQA nav world maps worldTabContent:map:tool:checkmark U>- D>map:canvas:cursor L>map:tool:cross R>map:tool:text
ZEDQA nav world maps worldTabContent:map:tool:text U>- D>map:canvas:cursor L>map:tool:checkmark R>map:color:1
ZEDQA nav world maps worldTabContent:map:color:1 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:tool:text R>map:color:2
ZEDQA nav world maps worldTabContent:map:color:2 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:1 R>map:color:3
ZEDQA nav world maps worldTabContent:map:color:3 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:2 R>map:color:4
ZEDQA nav world maps worldTabContent:map:color:4 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:3 R>map:color:5
ZEDQA nav world maps worldTabContent:map:color:5 U>worldTabBar:tab:maps~ D>map:canvas:cursor L>map:color:4 R>map:ext:key
ZEDQA nav world maps worldTabContent:map:style:menu U>- D>map:canvas:cursor L>map:ext:key R>map:popout
ZEDQA nav world maps worldTabContent:map:popout U>- D>map:canvas:cursor L>map:style:menu R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabContent:map:ext:key U>- D>map:canvas:cursor L>map:color:5 R>map:style:menu
ZEDQA nav world maps worldTabContent:map:canvas:cursor U>map:disclosure D>worldTabBar:tab:maps~ L>worldCtl:worldCtl:same R>worldTabBar:tab:maps
ZEDQA nav world maps worldTabBar:tab:loot U>- D>tab:craft L>worldTabContent:map:popout R>-
ZEDQA nav world maps worldTabBar:tab:craft U>tab:loot D>tab:build L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:build U>tab:craft D>tab:furniture L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:furniture U>tab:build D>tab:maps L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:maps U>tab:furniture D>tab:forage L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:forage U>tab:maps D>tab:animals L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:animals U>tab:forage D>tab:vehicle L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldTabBar:tab:vehicle U>tab:animals D>worldCtl:worldCtl:same~ L>worldTabContent:map:canvas:cursor R>-
ZEDQA nav world maps worldCtl:worldCtl:take U>worldContainerStrip:container:1 D>- L>worldContainerStrip:container:1 R>worldCtl:same
ZEDQA nav world maps worldCtl:worldCtl:same U>worldContainerStrip:container:1 D>- L>worldCtl:take R>worldTabContent:map:canvas:cursor
ZEDQA nav world forage: 14 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world forage STUCK: container:1(U) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world animals: 14 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world animals STUCK: container:1(U) animals:createzone(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav world vehicle: 12 targets | TRAP 0 {} | ISLAND 0 {}
ZEDQA nav world vehicle STUCK: container:1(U) mech:inspect(D) tab:loot(UR) tab:craft(R) tab:build(R) tab:furniture(R) tab:maps(R) tab:forage(R) tab:animals(R) tab:vehicle(R) worldCtl:take(D) worldCtl:same(D)
ZEDQA nav DONE
```

### 8. zedqa_exinfo.lua (`ZEDQA ex`) - PASS, 7 s

- go 15732 at 14:03:56
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_burpees.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #8 ok=true
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
ZEDQA ex tab health true | shown squats | reserved 434.44921875 used 290.85546875 w 329
ZEDQA ex ok block follows the focused pill (squats)
ZEDQA ex ok room reserved
ZEDQA ex ok block follows the focused pill (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex ok time buttons keep the last started exercise
ZEDQA ex ok time buttons start nothing and change no choice
ZEDQA ex ok block follows the focused pill (burpees)
ZEDQA ex DONE
```

### 9. zedqa_dash_props_smoke.lua (`ZEDQA sm`) - PASS, 9 s

- go 15733 at 14:04:07
- screenshots: zqa_sm_01_pickup_radio.png, zqa_sm_02_police_siren.png, zqa_sm_03_police_radio.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sm start
[ZeD.QA] run #9 ok=true
ZEDQA sm spawned Base.CarLightsPolice beside the character
ZEDQA sm pickup=true police=true
ZEDQA sm dash visible=true design=d6
ZEDQA sm radio up=true
ERROR: General f:6711 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:6715 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA sm siren up=true dash design=police
ZEDQA sm ham radio up=true
ZEDQA sm DONE
```

### 10. zedqa_mapshot.lua (`ZEDQA ms`) - PASS, 4 s

- go 15734 at 14:04:19
- screenshots: zqa_ms_1.png, zqa_ms_2.png

```text
[ZeD.QA] windows reset (R)
ZEDQA ms start
[ZeD.QA] run #10 ok=true
ZEDQA ms world 1929,0 1694x735 tab maps
ZEDQA ms DONE
```

### 11. zedqa_moodles.lua (`ZEDQA mood`) - PASS, 19 s

- go 15735 at 14:04:26
- screenshots: zqa_mood_right.png, zqa_mood_right_hover.png, zqa_mood_left.png, zqa_mood_left_hover.png, zqa_mood_bottom.png, zqa_mood_bottom_hover.png, zqa_mood_notices_off.png

```text
[ZeD.QA] windows reset (R)
ZEDQA mood start
[ZeD.QA] run #11 ok=true
ZEDQA mood set: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god true; moodles on 0
ZEDQA mood 90 frames on: HUNGER 0.00, THIRST 0.00, FATIGUE 0.00, BOREDOM 0.00, STRESS 0.00; god true; moodles on 0
ZEDQA mood 180 frames on: HUNGER 0.45, THIRST 0.45, FATIGUE 0.75, BOREDOM 0.60, STRESS 0.60; god false; moodles on 4
ZEDQA mood box by itself: STRESS | waiting 3
ZEDQA mood PASS a moodle that came on shows its box by itself, with no pointer on it
ZEDQA mood right: 4 moodles on (STRESS 2, THIRST 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS right: the place is in effect
ZEDQA mood PASS right: at least three moodles are on
ZEDQA mood PASS right: the moodles are shown (layer)
ZEDQA mood right column at 3782,969 size 48, stack 222; visible true
ZEDQA mood PASS right: vanilla's column is visible
ZEDQA mood PASS right: every moodle is on screen
ZEDQA mood PASS right: the column is on the right edge (x 3782)
ZEDQA mood PASS right: ZeD's hover layer lies over the column
ZEDQA mood right bubble: moodle 2, cloud -500,33 442x98, trail right from -56,82
ZEDQA mood PASS right: the bubble is for the moodle under the pointer
ZEDQA mood PASS right: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS right: the trail ends at the moodle, level with it
ZEDQA mood left: 4 moodles on (STRESS 2, THIRST 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS left: the place is in effect
ZEDQA mood PASS left: at least three moodles are on
ZEDQA mood PASS left: the moodles are shown (layer)
ZEDQA mood left column at 10,969 size 48, stack 222; visible true
ZEDQA mood PASS left: vanilla's column is visible
ZEDQA mood PASS left: every moodle is on screen
ZEDQA mood PASS left: the column is on the left edge (x 10)
ZEDQA mood PASS left: ZeD's hover layer lies over the column
ZEDQA mood left bubble: moodle 2, cloud 106,33 442x98, trail left from 104,82
ZEDQA mood PASS left: the bubble is for the moodle under the pointer
ZEDQA mood PASS left: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS left: the trail ends at the moodle, level with it
ZEDQA mood bottom: 4 moodles on (STRESS 2, THIRST 2, HUNGRY 2, TIRED 2)
ZEDQA mood PASS bottom: the place is in effect
ZEDQA mood PASS bottom: at least three moodles are on
ZEDQA mood PASS bottom: the moodles are shown (layer)
ZEDQA mood bottom row at 1809,1965 222x48; vanilla's column y -10000
ZEDQA mood PASS bottom: the row is on screen
ZEDQA mood PASS bottom: the row is centred (middle 1920 of 3840)
ZEDQA mood PASS bottom: the row sits above the belt
ZEDQA mood PASS bottom: one slot per moodle
ZEDQA mood PASS bottom: vanilla's column is out of sight (no double)
ZEDQA mood bottom bubble: moodle 2, cloud -133,-156 442x98, trail down from 82,-56
ZEDQA mood PASS bottom: the bubble is for the moodle under the pointer
ZEDQA mood PASS bottom: the trail leaves the cloud on the moodle's side
ZEDQA mood PASS bottom: the trail ends at the moodle, level with it
ZEDQA mood PASS with nothing changing the box goes by itself (nil)
ZEDQA mood notices off: box nil | waiting 2
ZEDQA mood PASS Moodle notices off: a moodle that changes shows no box by itself
ZEDQA mood all checks passed
ZEDQA mood DONE
```

### 12. zedqa_messages.lua (`ZEDQA msg`) - PASS, 11 s

- go 15736 at 14:04:49
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
ERROR: General f:9396 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:9396> Lua(Vanilla).boom> Exception thrown   (expected)
    java.lang.RuntimeException: attempted index: qaMessagesError of non-table: null at KahluaThread.tableget(KahluaThread.java:1430).
    Lua(Vanilla).boom(worldmap-annotations.lua:103)
ZEDQA msg PASS the one error is filed in Messages, counted once (0 -> 1)
ZEDQA msg PASS Messages opens on the mod
ZEDQA msg PASS opening it marks the mod's messages read
ZEDQA msg PASS four cards: three notes and the question (4)
ZEDQA msg PASS three OK buttons, one per note (3)
ZEDQA msg PASS OK ran that mod's callback once (1/0/0)
ZEDQA msg PASS A on the next card's OK ran its callback
ZEDQA msg PASS the controller is in the cards
ZEDQA msg PASS the window lists an error source
ZEDQA msg PASS the bug report text names the errors (1447 characters)
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
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N> Lua((MOD:Xen's Enhanced GUI)).hollow> Exception thrown  :: java.lang.RuntimeException: Object tried to call nil in hollow at KahluaUtil.fail(KahluaUtil.java:100).
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
