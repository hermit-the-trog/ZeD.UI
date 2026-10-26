# ZeD-UI regression - 2026-10-26 11:05 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 11:05:27 |
| Finished | 2026-10-26 11:08:59 (3 min 32 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\mapmods_manifest.txt (9 scripts) |
| Result | **9/9 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13336 to 13346 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13345, 13346)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_srj.lua | srj | PASS | 8 | zqa_srj_none.png, zqa_srj_main.png, zqa_srj_card_pad.png, zqa_srj_card_none.png, zqa_srj_folded.png |  |
| 3 | zedqa_mapkey.lua | mk | PASS | 11 | zqa_mk_drawer_survey.png, zqa_mk_drawer_color.png, zqa_mk_drawer_paper.png, zqa_mk_pop_survey.png, zqa_mk_pop_color.png, zqa_mk_pop_paper.png |  |
| 4 | zedqa_mapmods.lua | mm | PASS | 17 | zqa_mm_draw_drawer.png, zqa_mm_erase_pad.png, zqa_mm_draw_pop.png, zqa_mm_size_drawer.png, zqa_mm_players_drawer.png, zqa_mm_players_drawer_hidden.png, zqa_mm_notes_drawer.png, zqa_mm_notes_ask.png, zqa_mm_all_pop_survey.png, zqa_mm_all_pop_color.png, zqa_mm_all_pop_paper.png, zqa_mm_all_drawer_survey.png |  |
| 5 | zedqa_mapshot.lua | ms | PASS | 4 | zqa_ms_1.png, zqa_ms_2.png |  |
| 6 | zedqa_mapstyles.lua | mst | PASS | 10 | zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png |  |
| 7 | zedqa_mapnotes.lua | mnote | PASS | 6 | zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png |  |
| 8 | zedqa_flyermap.lua | fm | PASS | 8 | zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png |  |
| 9 | zedqa_navevents.lua | ev | PASS | 4 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13336 at 11:06:54

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. zedqa_srj.lua (`ZEDQA srj`) - PASS, 8 s

- go 13337 at 11:06:58
- screenshots: zqa_srj_none.png, zqa_srj_main.png, zqa_srj_card_pad.png, zqa_srj_card_none.png, zqa_srj_folded.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA srj start
:	[ZeD.QA] run #2 ok=true
:	ZEDQA srj extras 1 | mod support true
:	ZEDQA srj journal carried at start: false
:	ZEDQA srj Axe lv7: start 0 (0) unrec 0 rec 0 notwritten 10275 total 10275
:	ZEDQA srj Long Blunt lv3: start 0 (0) unrec 0 rec 0 notwritten 525 total 525
:	ZEDQA srj Short Blunt lv10: start 0 (0) unrec 0 rec 0 notwritten 32775 total 32775
:	ZEDQA srj Long Blade lv6: start 0 (0) unrec 0 rec 0 notwritten 5775 total 5775
:	ZEDQA srj Short Blade lv2: start 0 (0) unrec 0 rec 0 notwritten 225 total 225
:	ZEDQA srj Spear lv9: start 0 (0) unrec 0 rec 0 notwritten 23775 total 23775
:	ZEDQA srj Maintenance lv5: start 1 (75) unrec 0 rec 0 notwritten 2700 total 2775
:	ZEDQA srj Aiming lv1: start 0 (0) unrec 0 rec 0 notwritten 75 total 75
:	ZEDQA srj Reloading lv8: start 0 (0) unrec 0 rec 0 notwritten 16275 total 16275
:	ZEDQA srj Carpentry lv4: start 1 (75) unrec 0 rec 0 notwritten 1200 total 1275
:	ZEDQA srj Cooking lv7: start 0 (0) unrec 0 rec 0 notwritten 10275 total 10275
:	ZEDQA srj Electrical lv3: start 0 (0) unrec 0 rec 0 notwritten 525 total 525
:	ZEDQA srj First Aid lv10: start 0 (0) unrec 0 rec 0 notwritten 32775 total 32775
:	ZEDQA srj Glassmaking lv6: start 0 (0) unrec 0 rec 0 notwritten 5775 total 5775
:	ZEDQA srj Knapping lv2: start 0 (0) unrec 0 rec 0 notwritten 225 total 225
:	ZEDQA srj Masonry lv9: start 1 (75) unrec 0 rec 0 notwritten 23700 total 23775
:	ZEDQA srj Blacksmithing lv5: start 0 (0) unrec 0 rec 0 notwritten 2775 total 2775
:	ZEDQA srj Mechanics lv1: start 0 (0) unrec 0 rec 0 notwritten 75 total 75
:	ZEDQA srj Pottery lv8: start 0 (0) unrec 0 rec 0 notwritten 16275 total 16275
:	ZEDQA srj Tailoring lv4: start 0 (0) unrec 0 rec 0 notwritten 1275 total 1275
:	ZEDQA srj Fishing lv7: start 0 (0) unrec 0 rec 0 notwritten 10275 total 10275
:	ZEDQA srj Foraging lv3: start 0 (0) unrec 0 rec 0 notwritten 525 total 525
:	ZEDQA srj Tracking lv10: start 0 (0) unrec 0 rec 0 notwritten 32775 total 32775
:	ZEDQA srj Trapping lv6: start 0 (0) unrec 0 rec 0 notwritten 5775 total 5775
:	ZEDQA srj Fitness: not recorded by the mod (no strip)
:	ZEDQA srj Strength: not recorded by the mod (no strip)
:	ZEDQA srj Lightfooted lv5: start 0 (0) unrec 0 rec 0 notwritten 2775 total 2775
:	ZEDQA srj Nimble lv1: start 0 (0) unrec 0 rec 0 notwritten 75 total 75
:	ZEDQA srj Running lv9: start 0 (0) unrec 0 rec 0 notwritten 31718 total 31718
:	ZEDQA srj Sneaking lv4: start 0 (0) unrec 0 rec 0 notwritten 1275 total 1275
:	ZEDQA srj Animal Care lv7: start 0 (0) unrec 0 rec 0 notwritten 10275 total 10275
:	ZEDQA srj Butchering lv3: start 0 (0) unrec 0 rec 0 notwritten 525 total 525
:	ZEDQA srj skills with a strip 30, with red 30
:	ZEDQA srj rows 35 row height 45.96484375
:	ZEDQA srj journal added: Bound Journal
:	ZEDQA srj key line: journal Inventory by nil
:	ZEDQA srj in a bag: Inventory (no bag worn)
:	ZEDQA srj focus on Aiming true
:	ZEDQA srj card Aiming: Starting Level (0)=0; Untranscribed XP=75; Total XP=75 | 75 XP not yet written. Transcribe Into Journal on the Bound Journal keeps it.
:	ZEDQA srj pad card: mode gamepad focused window is Character true element Aiming card up Aiming
:	ZEDQA srj DONE
```

### 3. zedqa_mapkey.lua (`ZEDQA mk`) - PASS, 11 s

- go 13338 at 11:07:09
- screenshots: zqa_mk_drawer_survey.png, zqa_mk_drawer_color.png, zqa_mk_drawer_paper.png, zqa_mk_pop_survey.png, zqa_mk_pop_color.png, zqa_mk_pop_paper.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mk start
:	[ZeD.QA] run #3 ok=true
:	ZEDQA mk extensions: 6 | zones: map:ext:key,map:ext:draw
:	ZEDQA mk drawer key button 35x35 hint=Map key
:	ZEDQA mk key open (mouse): true
:	ZEDQA mk color: survey button true
:	ZEDQA mk Show Survey -> style survey
:	ZEDQA mk closed by the pad's close stop: true
:	ZEDQA mk opened by the pad's Key stop: true
:	ZEDQA mk pop-out key button 88.890625x35 | zones: map:key:close,map:key:panel,map:ext:key,map:ext:draw
:	ZEDQA mk pop-out Show Survey (pad) -> survey
:	ZEDQA mk DONE
```

### 4. zedqa_mapmods.lua (`ZEDQA mm`) - PASS, 17 s

- go 13339 at 11:07:24
- screenshots: zqa_mm_draw_drawer.png, zqa_mm_erase_pad.png, zqa_mm_draw_pop.png, zqa_mm_size_drawer.png, zqa_mm_players_drawer.png, zqa_mm_players_drawer_hidden.png, zqa_mm_notes_drawer.png, zqa_mm_notes_ask.png, zqa_mm_all_pop_survey.png, zqa_mm_all_pop_color.png, zqa_mm_all_pop_paper.png, zqa_mm_all_drawer_survey.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mm start
:	[ZeD.QA] run #4 ok=true
:	ZEDQA mm mods: draw=true size=true pom=true blt=true where=true
:	ZEDQA mm had: pen false eraser false
:	ZEDQA mm marks at start 69
:	ZEDQA mm draw row open true | tools true,true,true sliders true,true
:	ZEDQA mm erase without an eraser -> tool nil (want nil)
:	ZEDQA mm draw armed true
:	ZEDQA mm before the stroke: centre 11626,11556 zoom 18.00 size 989x543 player at 494,271
:	ZEDQA mm pressed at 613,217 -> world 11659,11541 dot c at 11659,11541
:	ZEDQA mm mouse stroke added 155
:	ZEDQA mm pad stroke added 62
:	ZEDQA mm line armed line
:	ZEDQA mm line added 69
:	ZEDQA mm thickness by click 2.5 -> 25
:	ZEDQA mm fill by the D-pad 1 -> 0.9
:	ZEDQA mm at the picture: centre 11626,11556 zoom 18.00 first dot on screen at 613,216
:	ZEDQA mm erase armed erase
:	ZEDQA mm pad eraser took off 19
:	ZEDQA mm pop-out: draw row true | label button w 101.22265625
:	ZEDQA mm size by click: ISMap.SCALE 2.266 saved 2.266
:	ZEDQA mm size by the D-pad: 2.166
:	ZEDQA mm Reset -> 0.666 (game's 0.666)
:	ZEDQA mm side list: true list button true
:	ZEDQA mm Rook_85 row true
:	ZEDQA mm centred on Rook_85: 11666,11511
:	ZEDQA mm list button (pad) -> side open false
:	ZEDQA mm hidden on open: B visible false (want false), A visible true
:	ZEDQA mm learned rows: A true B true
:	ZEDQA mm B shown by its tick: true hidden flag nil
:	ZEDQA mm asked: Delete the notes By QA Tester, July 9th 1993 at 14:20? Its 1 place goes from your map.
:	ZEDQA mm A deleted: set true mark gone true
:	ZEDQA mm where: Kentucky, USA
:	ZEDQA mm pop-out docked side w 413
:	ZEDQA mm strokes taken off 267 | marks now 69 (start 69)
:	ZEDQA mm DONE
```

### 5. zedqa_mapshot.lua (`ZEDQA ms`) - PASS, 4 s

- go 13340 at 11:07:44
- screenshots: zqa_ms_1.png, zqa_ms_2.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ms start
:	[ZeD.QA] run #5 ok=true
:	ZEDQA ms world 1929,0 1766x735 tab maps
:	ZEDQA ms DONE
```

### 6. zedqa_mapstyles.lua (`ZEDQA mst`) - PASS, 10 s

- go 13341 at 11:07:52
- screenshots: zqa_ms_survey_13.png, zqa_ms_survey_17.png, zqa_ms_color_13.png, zqa_ms_color_17.png, zqa_ms_paper_13.png, zqa_ms_paper_17.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mst start
:	[ZeD.QA] run #6 ok=true
:	ZEDQA mst survey: style survey zoom 13 images 2
:	ZEDQA mst color: style color zoom 13 images 2
:	ZEDQA mst paper: style paper zoom 13 images 1
:	ZEDQA mst DONE
```

### 7. zedqa_mapnotes.lua (`ZEDQA mnote`) - PASS, 6 s

- go 13342 at 11:08:05
- screenshots: zqa_mnote_placed.png, zqa_mnote_menu.png, zqa_mnote_deleted.png, zqa_mnote_paper_labels.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA mnote start
:	[ZeD.QA] run #7 ok=true
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
:	ZEDQA mnote cursor ui 494,299 | engine hit note 'ZEDQA note 59590' at world 11566.0,11502.6 ui 493,321 | found note 'ZEDQA note 59590' at world 11566.0,11502.6 ui 493,321 | the note note 'ZEDQA note 59590' at world 11566.0,11502.6 ui 493,321
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

### 8. zedqa_flyermap.lua (`ZEDQA fm`) - PASS, 8 s

- go 13343 at 11:08:14
- screenshots: zqa_fm_paper.png, zqa_fm_survey.png, zqa_fm_card.png, zqa_fm_reader.png, zqa_fm_flash.png

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA fm start
:	[ZeD.QA] run #8 ok=true
:	ZEDQA fm read 16 (added 2)
:	ZEDQA fm tracker ticked the test place: false
:	ZEDQA fm pins on paper: muldraughbakesale, fossoil1(done), ustoreitmuldraugh, sunstarmotel
:	ZEDQA fm hover: sunstarmotel
:	ZEDQA fm reader open true media sunstarmotel title Angel Cross + Sunstar Motel
:	ZEDQA fm flash true
:	ZEDQA fm read back to 14
:	ZEDQA fm DONE
```

### 9. zedqa_navevents.lua (`ZEDQA ev`) - PASS, 4 s

- go 13344 at 11:08:26

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA ev start
:	[ZeD.QA] run #9 ok=true
:	ZEDQA ev 1 on the hammer row: Char charMainInv:invrow:7 (Claw Hammer)
:	ZEDQA ev 1 after A (expect the card's primary action): Char charItemCard:hverb_1
:	ZEDQA ev 1 after B (expect back on the hammer row): Char charMainInv:invrow:7 (Claw Hammer)
:	ZEDQA ev 2 Right (expect the strip): Char charContainerStrip:container:1
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
```
