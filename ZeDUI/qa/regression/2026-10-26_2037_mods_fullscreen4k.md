# ZeD-UI regression - 2026-10-26 20:38 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 20:38:00 |
| Finished | 2026-10-26 20:43:43 (5 min 43 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_E.txt (11 scripts) |
| Result | **11/11 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13765 to 13777 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13776, 13777)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_r3_E.lua | r3E | PASS | 48 | zqa_r3E_1_loot.png, zqa_r3E_2_menu_apple.png, zqa_r3E_3_menu_world.png, zqa_r3E_4_tip_shirt_zed.png, zqa_r3E_5_tip_shirt_safe.png, zqa_r3E_4_tip_book_zed.png, zqa_r3E_5_tip_book_safe.png, zqa_r3E_4_tip_vhs_zed.png, zqa_r3E_5_tip_vhs_safe.png, zqa_r3E_4_tip_seed_zed.png, zqa_r3E_5_tip_seed_safe.png, zqa_r3E_6_char_equip.png, zqa_r3E_6_char_health.png, zqa_r3E_6_char_skills.png, zqa_r3E_6_char_identity.png, zqa_r3E_7_world_craft.png, zqa_r3E_7_world_build.png, zqa_r3E_7_world_maps.png, zqa_r3E_8_showworldmap.png, zqa_r3E_9_morebuilds.png, zqa_r3E_10_rfm.png, zqa_r3E_11_world_radio.png |  |
| 3 | suite_tabs.lua | tabs | PASS | 13 |  |  |
| 4 | zedqa_mapshot.lua | ms | PASS | 4 | zqa_ms_1.png, zqa_ms_2.png |  |
| 5 | zedqa_mapstyles.lua | mst | PASS | 11 | zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png |  |
| 6 | zedqa_flyers.lua | fl | PASS | 5 | zqa_fl_1.png, zqa_fl_2.png |  |
| 7 | zedqa_flyermap.lua | fm | PASS | 11 | zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png |  |
| 8 | zedqa_mapnotes.lua | mnote | PASS | 7 | zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png |  |
| 9 | zedqa_journal_refs.lua | jr | PASS | 4 | zqa_jr_01_diary.png, zqa_jr_02_flyers.png |  |
| 10 | zedqa_twoway.lua | tw | PASS | 41 | zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png |  |
| 11 | zedqa_messages.lua | msg | PASS | 11 | zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png | 1 expected exception(s) ignored (expect=) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 13765 at 20:39:49

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. zedqa_r3_E.lua (`ZEDQA r3E`) - PASS, 48 s

- go 13766 at 20:39:54
- screenshots: zqa_r3E_1_loot.png, zqa_r3E_2_menu_apple.png, zqa_r3E_3_menu_world.png, zqa_r3E_4_tip_shirt_zed.png, zqa_r3E_5_tip_shirt_safe.png, zqa_r3E_4_tip_book_zed.png, zqa_r3E_5_tip_book_safe.png, zqa_r3E_4_tip_vhs_zed.png, zqa_r3E_5_tip_vhs_safe.png, zqa_r3E_4_tip_seed_zed.png, zqa_r3E_5_tip_seed_safe.png, zqa_r3E_6_char_equip.png, zqa_r3E_6_char_health.png, zqa_r3E_6_char_skills.png, zqa_r3E_6_char_identity.png, zqa_r3E_7_world_craft.png, zqa_r3E_7_world_build.png, zqa_r3E_7_world_maps.png, zqa_r3E_8_showworldmap.png, zqa_r3E_9_morebuilds.png, zqa_r3E_10_rfm.png, zqa_r3E_11_world_radio.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA r3E start
:	[ZeD.QA] run #2 ok=true
:	ZEDQA r3E shot zqa_r3E_1_loot.png
:	ZEDQA r3E ui loot: ZeD_ActionBarLayer@0,0,1x1 ; MoodlesUI@1862,-20000,48x2160 ; MoodlesUI@3782,-20000,48x2160 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,-20000,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,256x82 ; ReportWindow@1670,830,500x500 ; ISBriefingUI@0,0,3840x2160 ; DBD_XPGainBar@50,50,220x51 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; WIMC_ColorDock@1763,2128,628x32 ; ZeD_MessagesToasts@0,0,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA r3E vanilla loot: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3E menu apple: Eat, Drop, Place Item, More, Move to, Rename
:	ZEDQA r3E shot zqa_r3E_2_menu_apple.png
:	ZEDQA r3E menu shirt: Wear, Rip Clothing, Craft, Inspect, Drop, Place Item, More, Move to, Rename
:	ZEDQA r3E menu book: Equip Primary, Equip Secondary, Read, Craft, Drop, Place Item, More, Move to, Rename
:	ZEDQA r3E menu bag: Wear, Equip Primary, Equip Secondary, Drop, Place Item, More, Move to
:	ZEDQA r3E world menu: Cheat Menu: Reloaded, |, Civil Defense Sirens, Sit on ground, Walk to, More Builds, Ban Music List
:	ZEDQA r3E shot zqa_r3E_3_menu_world.png
:	ZEDQA r3E shot zqa_r3E_4_tip_shirt_zed.png
:	ZEDQA r3E tip shirt zed 238x96
:	ZEDQA r3E shot zqa_r3E_5_tip_shirt_safe.png
:	ZEDQA r3E tip shirt safe 238x147
:	ZEDQA r3E shot zqa_r3E_4_tip_book_zed.png
:	ZEDQA r3E tip book zed 297x79
:	ZEDQA r3E shot zqa_r3E_5_tip_book_safe.png
:	ZEDQA r3E tip book safe 297x96
:	ZEDQA r3E shot zqa_r3E_4_tip_vhs_zed.png
:	ZEDQA r3E tip vhs zed 189x45
:	ZEDQA r3E shot zqa_r3E_5_tip_vhs_safe.png
:	ZEDQA r3E tip vhs safe 189x62
:	ZEDQA r3E shot zqa_r3E_4_tip_seed_zed.png
:	ZEDQA r3E tip seed zed 202x79
:	ZEDQA r3E shot zqa_r3E_5_tip_seed_safe.png
:	ZEDQA r3E tip seed safe 202x96
:	ZEDQA r3E ui after safe mode: ZeD_ActionBarLayer@0,0,1x1 ; SpeedControls@3641,-4000,189x28 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,-20000,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ReportWindow@1670,830,500x500 ; DBD_XPGainBar@50,50,220x51 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; WIMC_ColorDock@1763,2128,628x32 ; ZeD_MessagesToasts@0,0,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA r3E vanilla after safe mode: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3E shot zqa_r3E_6_char_equip.png
:	ZEDQA r3E shot zqa_r3E_6_char_health.png
:	ZEDQA r3E shot zqa_r3E_6_char_skills.png
:	ZEDQA r3E shot zqa_r3E_6_char_identity.png
:	ZEDQA r3E shot zqa_r3E_7_world_craft.png
:	ZEDQA r3E shot zqa_r3E_7_world_build.png
:	ZEDQA r3E shot zqa_r3E_7_world_maps.png
:	ZEDQA r3E ui tabs walked: ZeD_ActionBarLayer@0,0,1x1 ; MoodlesUI@1862,-20000,48x2160 ; MoodlesUI@3782,-20000,48x2160 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,-20000,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ReportWindow@1670,830,500x500 ; DBD_XPGainBar@50,50,220x51 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; WIMC_ColorDock@1763,2128,628x32 ; ZeD_MessagesToasts@0,0,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA r3E vanilla tabs walked: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3E shot zqa_r3E_8_showworldmap.png
:	ZEDQA r3E ui after ShowWorldMap: ZeD_ActionBarLayer@0,0,1x1 ; MoodlesUI@1862,-20000,48x2160 ; MoodlesUI@3782,-20000,48x2160 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,-20000,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ReportWindow@1670,830,500x500 ; DBD_XPGainBar@50,50,220x51 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1682x735 ; ZeD_Window@538,238,2764x1684 ; WIMC_ColorDock@1763,2128,628x32 ; ZeD_MessagesToasts@0,0,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA r3E vanilla after ShowWorldMap: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3E shot zqa_r3E_9_morebuilds.png
:	ZEDQA r3E ui more builds: ZeD_ActionBarLayer@0,0,1x1 ; MoodlesUI@1862,-20000,48x2160 ; MoodlesUI@3782,-20000,48x2160 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,-20000,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ReportWindow@1670,830,500x500 ; DBD_XPGainBar@50,50,220x51 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1682x735 ; ZeD_Window@538,238,2764x1684 ; ISMoreBuildWindow@1330,720,1180x720 ; WIMC_ColorDock@1763,2128,628x32 ; ZeD_MessagesToasts@0,0,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA r3E vanilla more builds: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3E closed 1
:	ZEDQA r3E shot zqa_r3E_10_rfm.png
:	ZEDQA r3E ui rfm: ZeD_ActionBarLayer@0,0,1x1 ; MoodlesUI@1862,-20000,48x2160 ; MoodlesUI@3782,-20000,48x2160 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,-20000,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ReportWindow@1670,830,500x500 ; DBD_XPGainBar@50,50,220x51 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,1682x735 ; ZeD_Window@538,238,2764x1684 ; RadioFrequencyManagerUI@70,400,400x300 ; WIMC_ColorDock@1763,2128,628x32 ; ZeD_MessagesToasts@0,0,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA r3E vanilla rfm: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3E note: no world tab radio
:	ZEDQA r3E shot zqa_r3E_11_world_radio.png
:	ZEDQA r3E ui end: ZeD_ActionBarLayer@0,0,1x1 ; MoodlesUI@1862,-20000,48x2160 ; MoodlesUI@3782,-20000,48x2160 ; UIDebugConsole@20,1848,1280x292 ; MoodlesUI@3782,-20000,48x2160 ; ISButtonPrompt@0,0,1x1 ; ISEquippedItem@10,10,53x621 ; ISHotbar@-10000,-10000,292x82 ; ReportWindow@1670,830,500x500 ; DBD_XPGainBar@50,50,220x51 ; ZeD_BeltHUD@1438,2041,772x91 ; ZeD_MoodleLayer@3782,1080,48x2160 ; ZeD_Watch@3596,10,228x52 ; ZeD_Window@1134,0,777x735 ; ZeD_Window@1929,0,777x735 ; ZeD_Window@538,238,2764x1684 ; WIMC_ColorDock@1763,2128,628x32 ; ZeD_MessagesToasts@0,0,1x1 ; ISButton@3813,2051,22x22
:	ZEDQA r3E vanilla end: inventory page shown false, loot page shown false, info panel shown false
:	ZEDQA r3E DONE
```

### 3. suite_tabs.lua (`ZEDQA tabs`) - PASS, 13 s

- go 13767 at 20:40:46

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
:	ZEDQA char tab=skills active=skills w=1617 focusables=62 {skill=36 skills=1 training=25}
:	ZEDQA world tab=loot active=loot w=777 focusables=0 {}
:	ZEDQA world tab=craft active=craft w=1617 focusables=10 {craft=10}
:	ZEDQA world tab=build active=build w=1617 focusables=8 {build=8}
:	ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
:	ZEDQA world tab=maps active=maps w=1682 focusables=1 {map=1}
:	ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
:	ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
:	ZEDQA tabs done
```

### 4. zedqa_mapshot.lua (`ZEDQA ms`) - PASS, 4 s

- go 13768 at 20:41:02
- screenshots: zqa_ms_1.png, zqa_ms_2.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ms start
:	[ZeD.QA] run #4 ok=true
:	ZEDQA ms world 1929,0 1682x735 tab maps
:	ZEDQA ms DONE
```

### 5. zedqa_mapstyles.lua (`ZEDQA mst`) - PASS, 11 s

- go 13769 at 20:41:10
- screenshots: zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mst start
:	[ZeD.QA] run #5 ok=true
:	ZEDQA mst survey: style survey zoom 13 images 2
:	ZEDQA mst color: style color zoom 13 images 2
:	ZEDQA mst paper: style paper zoom 13 images 1
:	ZEDQA mst DONE
```

### 6. zedqa_flyers.lua (`ZEDQA fl`) - PASS, 5 s

- go 13770 at 20:41:25
- screenshots: zqa_fl_1.png, zqa_fl_2.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fl start
:	[ZeD.QA] run #6 ok=true
:	ZEDQA fl read pieces: 14
:	ZEDQA fl piece mccoyloggingcorp
:	ZEDQA fl read now: 15
:	ZEDQA fl forgot true read 14
:	ZEDQA fl DONE
```

### 7. zedqa_flyermap.lua (`ZEDQA fm`) - PASS, 11 s

- go 13771 at 20:41:33
- screenshots: zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fm start
:	[ZeD.QA] run #7 ok=true
:	ZEDQA fm read 16 (added 2)
:	ZEDQA fm tracker ticked the test place: true
:	ZEDQA fm pins on paper: muldraughbakesale, fossoil1(done), ustoreitmuldraugh, sunstarmotel
:	ZEDQA fm hover: sunstarmotel
:	ZEDQA fm reader open true media sunstarmotel title Angel Cross + Sunstar Motel
:	ZEDQA fm flash true
:	ZEDQA fm read back to 14
:	ZEDQA fm DONE
```

### 8. zedqa_mapnotes.lua (`ZEDQA mnote`) - PASS, 7 s

- go 13772 at 20:41:48
- screenshots: zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mnote start
:	[ZeD.QA] run #8 ok=true
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
:	ZEDQA mnote cursor ui 452,299 | engine hit note 'ZEDQA note 49979' at world 11997.5,11702.4 ui 451,321 | found note 'ZEDQA note 49979' at world 11997.5,11702.4 ui 451,321 | the note note 'ZEDQA note 49979' at world 11997.5,11702.4 ui 451,321
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

### 9. zedqa_journal_refs.lua (`ZEDQA jr`) - PASS, 4 s

- go 13773 at 20:41:58
- screenshots: zqa_jr_01_diary.png, zqa_jr_02_flyers.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA jr start
:	[ZeD.QA] run #9 ok=true
:	ZEDQA jr DONE
```

### 10. zedqa_twoway.lua (`ZEDQA tw`) - PASS, 41 s

- go 13774 at 20:42:06
- screenshots: zqa_tw_1a_valutech_default_height.png, zqa_tw_1b_valutech_tab.png, zqa_tw_3a_valutech_full_view.png, zqa_tw_4a_pad_tab_vol.png, zqa_tw_4b_pad_full_view.png, zqa_tw_1c_walkie_toy.png, zqa_tw_1c_walkie_premium.png, zqa_tw_1c_walkie_tactical.png, zqa_tw_2_tactical_lamp.png, zqa_tw_1c_walkie_army.png, zqa_tw_1c_walkie_makeshift.png, zqa_tw_1c_walkie_manpack.png, zqa_tw_5_ham_civilian_tab.png, zqa_tw_5b_ham_civilian_full_view.png, zqa_tw_5n_ham_civilian_n.png, zqa_tw_5n_ham_army_n.png, zqa_tw_5n_ham_makeshift_n.png, zqa_tw_5_ham_army_tab.png, zqa_tw_5c_ham_army_tab.png, zqa_tw_5_ham_makeshift_tab.png, zqa_tw_5d_ham_makeshift_tab.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA tw start
:	[ZeD.QA] run #10 ok=true
:	ZEDQA tw screen 3840x2160, root scale 1.75, plate zoom 2
:	ZEDQA tw PASS walkie_valutech: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_valutech: its own face, walkie_valutech (got walkie_valutech)
:	ZEDQA tw PASS walkie_valutech: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_valutech: centred in its panel (x 20, want 20)
:	ZEDQA tw PASS walkie_valutech: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_valutech: all 6 controls on the face (6)
:	ZEDQA tw PASS walkie_valutech: the full view button in the header
:	ZEDQA tw PASS walkie_valutech: VOL pressed turns it on
:	ZEDQA tw PASS walkie_valutech: the display reads while on
:	ZEDQA tw walkie_valutech: display 093.200 | LBMW - KENTUCKY RADIO | BAT 3
:	ZEDQA tw PASS walkie_valutech: BAT with 3 bars at 60% charge
:	ZEDQA tw valutech: body 599 px tall, the face's body needs 799 (window 735)
:	ZEDQA tw PASS valutech: at the default height the body scrolls
:	ZEDQA tw PASS valutech: the wheel off the knobs scrolls the body (0 -> 0.05)
:	ZEDQA tw PASS valutech: the grown window shows the whole face, no scrollbar
:	ZEDQA tw PASS VOL: the wheel turns the volume up (0.50 -> 0.60)
:	ZEDQA tw PASS TUNE: a click on its right half tunes up a step (93200 -> 93400)
:	ZEDQA tw PASS TUNE: its left half tunes down a step
:	ZEDQA tw PASS TUNE: a right-click turns it down
:	ZEDQA tw PASS MEM: stores the frequency as channel 01 (1 stored)
:	ZEDQA tw PASS the display shows CH 01 (01)
:	ZEDQA tw PASS MEM: a second channel stored
:	ZEDQA tw PASS CH down walks to channel 01
:	ZEDQA tw PASS CH up walks to channel 02
:	ZEDQA tw PASS the mic starts muted
:	ZEDQA tw PASS the TX lamp is dark while the mic is muted
:	ZEDQA tw PASS PUSH TO TALK latches the mic live
:	ZEDQA tw PASS the TX lamp lights and the display says TX OK (TX OK)
:	ZEDQA tw PASS pressed again it mutes the mic (MIC OFF)
:	ZEDQA tw PASS MEM held (right-click): the naming box opens
:	ZEDQA tw PASS naming it: channel 02 is QA Farm
:	ZEDQA tw PASS the header button opens full view on the radio
:	ZEDQA tw PASS full view is the face alone, no window frame
:	ZEDQA tw PASS full view is the plate at the plate scale (408x728)
:	ZEDQA tw PASS the first time it sits centre right of the play area (centre x 2880)
:	ZEDQA tw PASS every control is on it (6)
:	ZEDQA tw PASS a control in full view works (CH down)
:	ZEDQA tw PASS MEM held in full view opens the naming box
:	ZEDQA tw PASS the face's edge is not a control
:	ZEDQA tw PASS dragging the face moves full view (2676 -> 2276)
:	ZEDQA tw PASS the place is kept on the character
:	ZEDQA tw PASS the header button closes full view
:	ZEDQA tw PASS the point between the knobs is no control
:	ZEDQA tw PASS a click on the face away from the controls opens full view
:	ZEDQA tw PASS it opens where it was dragged to
:	ZEDQA tw PASS B closes full view
:	ZEDQA tw PASS Escape closes full view
:	ZEDQA tw PASS full view closes when the radio leaves the hands
:	ZEDQA tw PASS pad: the face's VOL is a stop in the tab
:	ZEDQA tw PASS pad: up on VOL turns it up
:	ZEDQA tw PASS pad: right from VOL walks to TUNE (radio:tw:tune)
:	ZEDQA tw PASS pad: A on CH up steps the channel
:	ZEDQA tw PASS pad: X on MEM opens the naming box
:	ZEDQA tw PASS pad: A on the full view button opens it
:	ZEDQA tw PASS pad: full view shows its controller strip
:	ZEDQA tw PASS pad: full view lands on a control (vol)
:	ZEDQA tw PASS pad: down on VOL in full view turns it down
:	ZEDQA tw PASS pad: right walks to TUNE in full view (tune)
:	ZEDQA tw PASS pad: A on PUSH TO TALK in full view latches the mic
:	ZEDQA tw PASS pad: B closes full view
:	ZEDQA tw PASS walkie_toy: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_toy: its own face, walkie_toy (got walkie_toy)
:	ZEDQA tw PASS walkie_toy: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_toy: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_toy: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_toy: all 3 controls on the face (3)
:	ZEDQA tw PASS walkie_toy: the full view button in the header
:	ZEDQA tw PASS walkie_toy: VOL pressed turns it on
:	ZEDQA tw PASS walkie_toy: the display reads while on
:	ZEDQA tw walkie_toy: display 93.20 MHZ | nil | nil nil
:	ZEDQA tw PASS toy: no memories, its TALK button
:	ZEDQA tw PASS toy: the drum shows the frequency
:	ZEDQA tw PASS walkie_premium: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_premium: its own face, walkie_premium (got walkie_premium)
:	ZEDQA tw PASS walkie_premium: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_premium: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_premium: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_premium: all 6 controls on the face (6)
:	ZEDQA tw PASS walkie_premium: the full view button in the header
:	ZEDQA tw PASS walkie_premium: VOL pressed turns it on
:	ZEDQA tw PASS walkie_premium: the display reads while on
:	ZEDQA tw walkie_premium: display 093.200 | LBMW - KENTUCKY RADIO | BAT 3
:	ZEDQA tw PASS walkie_premium: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS walkie_tactical: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_tactical: its own face, walkie_tactical (got walkie_tactical)
:	ZEDQA tw PASS walkie_tactical: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_tactical: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_tactical: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_tactical: all 9 controls on the face (9)
:	ZEDQA tw PASS walkie_tactical: the full view button in the header
:	ZEDQA tw PASS walkie_tactical: VOL pressed turns it on
:	ZEDQA tw PASS walkie_tactical: the display reads while on
:	ZEDQA tw walkie_tactical: display 107.600 | | BAT 3
:	ZEDQA tw PASS walkie_tactical: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS Tactical: MUTE silences it
:	ZEDQA tw PASS Tactical: MUTE again gives the sound back
:	ZEDQA tw PASS Tactical: SCAN runs
:	ZEDQA tw PASS Tactical: SCAN again stops it
:	ZEDQA tw PASS Tactical: LAMP lights the display
:	ZEDQA tw PASS Tactical: the lamp goes out after 5 s
:	ZEDQA tw PASS walkie_army: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_army: its own face, walkie_army (got walkie_army)
:	ZEDQA tw PASS walkie_army: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_army: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_army: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_army: all 9 controls on the face (9)
:	ZEDQA tw PASS walkie_army: the full view button in the header
:	ZEDQA tw PASS walkie_army: VOL pressed turns it on
:	ZEDQA tw PASS walkie_army: the display reads while on
:	ZEDQA tw walkie_army: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
:	ZEDQA tw PASS walkie_army: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS walkie_makeshift: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_makeshift: its own face, walkie_makeshift (got walkie_makeshift)
:	ZEDQA tw PASS walkie_makeshift: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_makeshift: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_makeshift: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_makeshift: all 6 controls on the face (6)
:	ZEDQA tw PASS walkie_makeshift: the full view button in the header
:	ZEDQA tw PASS walkie_makeshift: VOL pressed turns it on
:	ZEDQA tw PASS walkie_makeshift: the display reads while on
:	ZEDQA tw walkie_makeshift: display CH-- 91.20 | CIVILIAN RADIO | nil nil
:	ZEDQA tw PASS makeshift: its character display reads CH.. (CH-- 91.20)
:	ZEDQA tw PASS walkie_manpack: the Character window's Radio tab opens
:	ZEDQA tw PASS walkie_manpack: its own face, walkie_manpack (got walkie_manpack)
:	ZEDQA tw PASS walkie_manpack: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS walkie_manpack: centred in its panel (x 32, want 32)
:	ZEDQA tw PASS walkie_manpack: the tab is only as wide as the face's 220 panel (465 px; panel and scrollbar 465)
:	ZEDQA tw PASS walkie_manpack: all 7 controls on the face (7)
:	ZEDQA tw PASS walkie_manpack: the full view button in the header
:	ZEDQA tw PASS walkie_manpack: VOL pressed turns it on
:	ZEDQA tw PASS walkie_manpack: the display reads while on
:	ZEDQA tw walkie_manpack: display 098.400 | AUTOMATED EMERGENCY BROADCAST SYSTEM | BAT 3
:	ZEDQA tw PASS walkie_manpack: BAT with 3 bars at 60% charge
:	ZEDQA tw PASS ManPack: on the back
:	ZEDQA tw PASS an AM/FM radio still shows the chassis
:	ZEDQA tw 5 free squares in reach
:	ZEDQA tw placed 3 ham sets
:	ZEDQA tw PASS the World window's Radio tab opens on the placed sets
:	ZEDQA tw PASS ham_civilian: its own face, ham_civilian (got ham_civilian)
:	ZEDQA tw PASS ham_civilian: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_civilian: centred across the drawer (x 20, want 20)
:	ZEDQA tw PASS ham_civilian: the drawer holds the whole set (840 px for 800)
:	ZEDQA tw PASS ham_civilian: all 8 controls on the face (8)
:	ZEDQA tw PASS ham_civilian: the full view button in the header
:	ZEDQA tw PASS ham_civilian: VOL pressed turns it on
:	ZEDQA tw ham_civilian: display 089.400 | HITZ FM | range RANGE 7.5 KM
:	ZEDQA tw PASS ham_civilian: the display reads while on
:	ZEDQA tw PASS the drawer's clip is set and cleared in pairs with a ham showing (16 sets, 16 clears)
:	ZEDQA tw PASS civilian ham: RANGE matches its transmit range (RANGE 7.5 KM)
:	ZEDQA tw PASS civilian ham: the band marker follows the frequency up
:	ZEDQA tw PASS civilian ham: full view opens
:	ZEDQA tw PASS ham_civilian on a small screen: its narrow face (ham_civilian_n)
:	ZEDQA tw PASS ham_civilian: the tab is a walkie's width (465 px, want 465)
:	ZEDQA tw PASS ham_civilian: the narrow face at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_civilian: every control of the wide set on the narrow face (8)
:	ZEDQA tw PASS ham_civilian: VOL on the narrow face turns it on
:	ZEDQA tw PASS ham_civilian: TUNE on the narrow face tunes up a step
:	ZEDQA tw PASS ham_civilian: the narrow face's display reads
:	ZEDQA tw PASS ham_army on a small screen: its narrow face (ham_army_n)
:	ZEDQA tw PASS ham_army: the tab is a walkie's width (465 px, want 465)
:	ZEDQA tw PASS ham_army: the narrow face at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_army: every control of the wide set on the narrow face (14)
:	ZEDQA tw PASS ham_army: VOL on the narrow face turns it on
:	ZEDQA tw PASS ham_army: TUNE on the narrow face tunes up a step
:	ZEDQA tw PASS ham_army: the narrow face's display reads
:	ZEDQA tw PASS ham_makeshift on a small screen: its narrow face (ham_makeshift_n)
:	ZEDQA tw PASS ham_makeshift: the tab is a walkie's width (465 px, want 465)
:	ZEDQA tw PASS ham_makeshift: the narrow face at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_makeshift: every control of the wide set on the narrow face (7)
:	ZEDQA tw PASS ham_makeshift: VOL on the narrow face turns it on
:	ZEDQA tw PASS ham_makeshift: TUNE on the narrow face tunes up a step
:	ZEDQA tw PASS ham_makeshift: the narrow face's display reads
:	ZEDQA tw PASS narrow makeshift ham: TALK / LISTEN flips with the mic
:	ZEDQA tw PASS with room again the wide set is back
:	ZEDQA tw PASS ham_army: its own face, ham_army (got ham_army)
:	ZEDQA tw PASS ham_army: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_army: centred across the drawer (x 20, want 20)
:	ZEDQA tw PASS ham_army: the drawer holds the whole set (840 px for 800)
:	ZEDQA tw PASS ham_army: all 14 controls on the face (14)
:	ZEDQA tw PASS ham_army: the full view button in the header
:	ZEDQA tw PASS ham_army: VOL pressed turns it on
:	ZEDQA tw ham_army: display 093.400 | | range RANGE 20 KM
:	ZEDQA tw PASS ham_army: the display reads while on
:	ZEDQA tw PASS army ham: tuned away
:	ZEDQA tw PASS army ham: 1 goes straight to memory 1
:	ZEDQA tw PASS army ham on the grid: AC, the bars dark (AC)
:	ZEDQA tw PASS ham_makeshift: its own face, ham_makeshift (got ham_makeshift)
:	ZEDQA tw PASS ham_makeshift: drawn at the plates' whole zoom 2 (got 2)
:	ZEDQA tw PASS ham_makeshift: centred across the drawer (x 20, want 20)
:	ZEDQA tw PASS ham_makeshift: the drawer holds the whole set (840 px for 800)
:	ZEDQA tw PASS ham_makeshift: all 7 controls on the face (7)
:	ZEDQA tw PASS ham_makeshift: the full view button in the header
:	ZEDQA tw PASS ham_makeshift: VOL pressed turns it on
:	ZEDQA tw ham_makeshift: display CH-- 453.400 MHZ | | range RANGE 6 KM
:	ZEDQA tw PASS ham_makeshift: the display reads while on
:	ZEDQA tw PASS makeshift ham: the TALK / LISTEN toggle flips with the mic
:	ZEDQA tw PASS makeshift ham: full view opens
:	ZEDQA tw PASS full view closes when the set is taken away
:	ZEDQA tw cleanup: 3 sets and 8 items taken away
:	ZEDQA tw 185 passed, 0 failed
:	ZEDQA tw all checks passed
:	ZEDQA tw DONE
```

### 11. zedqa_messages.lua (`ZEDQA msg`) - PASS, 11 s

- go 13775 at 20:42:50
- 1 expected exception(s) ignored (expect=)
- screenshots: zqa_msg_belt_toast.png, zqa_msg_window_mod.png, zqa_msg_window_error.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA msg start
:	[ZeD.QA] run #11 ok=true
:	ZEDQA msg PASS nothing kept: no envelope on the belt
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
ERROR: General f:9531 at KahluaThread.flushErrorMessage > -------------------------------------------------------------   (expected)
    attempted index: qaMessagesError of non-table: null
ERROR: General f:9531> Lua(Vanilla).boom> Exception thrown   (expected)
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
:	ZEDQA msg all checks passed
:	ZEDQA msg DONE
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
    1x ERROR: General f:N> Lua((MOD:Voiced Radio and Tvs)).Init> Exception thrown  :: java.lang.RuntimeException: Object tried to call nil in Init at KahluaUtil.fail(KahluaUtil.java:100).
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
```
