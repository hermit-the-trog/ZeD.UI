# ZeD-UI regression - 2026-11-03 21:08 - windowed (1280x800 window)

| | |
|---|---|
| Started | 2026-11-03 21:08:55 |
| Finished | 2026-11-03 21:11:05 (2 min 10 s) |
| Mode | windowed (1280x800 window) |
| Display | fullScreen=false height=800 width=1280 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/book83_deck_final.txt (5 scripts) |
| Result | **4/5 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 20030 to 20036 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale Auto (1280x800 window), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzlaunchwin.ps1: launched windowed; clicked client centre (1929,1118) of 1280x800
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 20035, 20036)
- pzrestorewin.ps1: fullScreen=true height=2160 width=3840
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_textlarge.lua | txl | PASS | 1 |  |  |
| 3 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 4 | zedqa_book83_pause.lua | b8p | PASS | 3 | zqa_b8p_1280x800_1_open_loot.png, zqa_b8p_1280x800_2_closed_paused_by_hand.png |  |
| 5 | zedqa_book83.lua | b83 | WARN | 28 | zqa_b83_1280x800_spread_01.png, zqa_b83_1280x800_spread_02.png, zqa_b83_1280x800_spread_03.png, zqa_b83_1280x800_spread_04.png, zqa_b83_1280x800_spread_05.png, zqa_b83_1280x800_spread_06.png, zqa_b83_1280x800_spread_07.png, zqa_b83_1280x800_spread_08.png, zqa_b83_1280x800_spread_09.png, zqa_b83_1280x800_spread_10.png, zqa_b83_1280x800_spread_11.png, zqa_b83_1280x800_spread_12.png, zqa_b83_1280x800_spread_13.png, zqa_b83_1280x800_spread_14.png, zqa_b83_1280x800_spread_15.png, zqa_b83_1280x800_spread_16.png, zqa_b83_1280x800_spread_17.png, zqa_b83_1280x800_spread_18.png, zqa_b83_1280x800_spread_19.png, zqa_b83_1280x800_spread_20.png, zqa_b83_1280x800_spread_21.png, zqa_b83_1280x800_spread_22.png, zqa_b83_1280x800_spread_23.png, zqa_b83_1280x800_spread_24.png, zqa_b83_1280x800_spread_25.png, zqa_b83_1280x800_spread_26.png, zqa_b83_1280x800_spread_27.png, zqa_b83_1280x800_spread_28.png, zqa_b83_1280x800_spread_29.png, zqa_b83_1280x800_spread_30.png, zqa_b83_1280x800_spread_31.png, zqa_b83_1280x800_spread_32.png, zqa_b83_1280x800_spread_33.png, zqa_b83_1280x800_spread_34.png, zqa_b83_1280x800_spread_35.png, zqa_b83_1280x800_spread_36.png, zqa_b83_1280x800_spread_37.png, zqa_b83_1280x800_spread_38.png, zqa_b83_1280x800_spread_39.png, zqa_b83_1280x800_spread_40.png, zqa_b83_1280x800_spread_41.png, zqa_b83_1280x800_spread_42.png, zqa_b83_1280x800_spread_43.png, zqa_b83_1280x800_spread_44.png, zqa_b83_1280x800_D1_title.png, zqa_b83_1280x800_D2_contents_intro.png, zqa_b83_1280x800_D3_chapter_opener_clip.png, zqa_b83_1280x800_D4_skill_books_rules.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 20030 at 21:09:53

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=19 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_textlarge.lua (`ZEDQA txl`) - PASS, 1 s

- go 20031 at 21:09:58

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=19 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #2 ok=true
ZEDQA txl size large
ZEDQA txl DONE
```

### 3. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 20032 at 21:10:02

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=19 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #3 ok=true
ZEDQA hcn DONE
```

### 4. zedqa_book83_pause.lua (`ZEDQA b8p`) - PASS, 3 s

- go 20033 at 21:10:06
- screenshots: zqa_b8p_1280x800_1_open_loot.png, zqa_b8p_1280x800_2_closed_paused_by_hand.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=19 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8p start
[ZeD.QA] run #4 ok=true
ZEDQA b8p before: paused message true
ZEDQA b8p PASS the paused message is off while the book is open (false)
ZEDQA b8p shot 1_open_loot
ZEDQA b8p PASS it is put back on close (true)
ZEDQA b8p shot 2_closed_paused_by_hand
ZEDQA b8p RESULT 2 pass, 0 fail
ZEDQA b8p DONE
```

### 5. zedqa_book83.lua (`ZEDQA b83`) - WARN, 28 s

- go 20034 at 21:10:12
- 1 ERR line(s)
- screenshots: zqa_b83_1280x800_spread_01.png, zqa_b83_1280x800_spread_02.png, zqa_b83_1280x800_spread_03.png, zqa_b83_1280x800_spread_04.png, zqa_b83_1280x800_spread_05.png, zqa_b83_1280x800_spread_06.png, zqa_b83_1280x800_spread_07.png, zqa_b83_1280x800_spread_08.png, zqa_b83_1280x800_spread_09.png, zqa_b83_1280x800_spread_10.png, zqa_b83_1280x800_spread_11.png, zqa_b83_1280x800_spread_12.png, zqa_b83_1280x800_spread_13.png, zqa_b83_1280x800_spread_14.png, zqa_b83_1280x800_spread_15.png, zqa_b83_1280x800_spread_16.png, zqa_b83_1280x800_spread_17.png, zqa_b83_1280x800_spread_18.png, zqa_b83_1280x800_spread_19.png, zqa_b83_1280x800_spread_20.png, zqa_b83_1280x800_spread_21.png, zqa_b83_1280x800_spread_22.png, zqa_b83_1280x800_spread_23.png, zqa_b83_1280x800_spread_24.png, zqa_b83_1280x800_spread_25.png, zqa_b83_1280x800_spread_26.png, zqa_b83_1280x800_spread_27.png, zqa_b83_1280x800_spread_28.png, zqa_b83_1280x800_spread_29.png, zqa_b83_1280x800_spread_30.png, zqa_b83_1280x800_spread_31.png, zqa_b83_1280x800_spread_32.png, zqa_b83_1280x800_spread_33.png, zqa_b83_1280x800_spread_34.png, zqa_b83_1280x800_spread_35.png, zqa_b83_1280x800_spread_36.png, zqa_b83_1280x800_spread_37.png, zqa_b83_1280x800_spread_38.png, zqa_b83_1280x800_spread_39.png, zqa_b83_1280x800_spread_40.png, zqa_b83_1280x800_spread_41.png, zqa_b83_1280x800_spread_42.png, zqa_b83_1280x800_spread_43.png, zqa_b83_1280x800_spread_44.png, zqa_b83_1280x800_D1_title.png, zqa_b83_1280x800_D2_contents_intro.png, zqa_b83_1280x800_D3_chapter_opener_clip.png, zqa_b83_1280x800_D4_skill_books_rules.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=15 inCar=false vehicles=19 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b83 start
[ZeD.QA] run #5 ok=true
ZEDQA b83 before: guide look 1, start-up box false, video effects false
ZEDQA b83 PASS ZeD setup's Survival guide row reads Full (the default)
ZEDQA b83 PASS F1 opens the book (Full), not the window
ZEDQA b83 PASS the game is paused while the book is open
ZEDQA b83 pages 88 (44 spreads): 81 flow, 0 pages shared by 2+ topics, 0 run-on pages, 1 rules; unit 1.000
ZEDQA b83 PASS every topic has its place, and the rules page is there (81 of 81)
ZEDQA b83 FAIL topics share pages (0 pages with two or more)
ZEDQA b83 PASS every chapter opener begins its own page (15 of 15)
ZEDQA b83 PASS nothing past the folio
ZEDQA b83 PASS no item overlaps the one before it
ZEDQA b83 PASS F1 with no tab opens on the title page (blank+title)
ZEDQA b83 PASS F1 again closes it, the game runs
ZEDQA b83 PASS ZeD's Escape taker closes the book
ZEDQA b83 PASS closed
ZEDQA b83 PASS Escape closes the book
ZEDQA b83 PASS Simple: F1 opens the window
ZEDQA b83 PASS Next page: the contents facing the introduction (contents+intro)
ZEDQA b83 PASS Previous page turns back
ZEDQA b83 PASS the right arrow turns on
ZEDQA b83 PASS the left arrow turns back
ZEDQA b83 PASS Page Down turns on
ZEDQA b83 PASS Page Up turns back
ZEDQA b83 PASS Home goes to the contents
ZEDQA b83 PASS the wheel turns on
ZEDQA b83 PASS and back
ZEDQA b83 PASS Contents goes to the contents
ZEDQA b83 PASS the last spread stops the turning
ZEDQA b83 PASS the first spread stops it back
ZEDQA b83 PASS a click on the right page turns on
ZEDQA b83 PASS a click on the left page turns back
ZEDQA b83 PASS the start-up box sets the game's option
ZEDQA b83 PASS and clears it
ZEDQA b83 PASS every contents row opens its chapter's first page (15 of 15)
ZEDQA b83 PASS every thumb opens its chapter (15 of 15)
ZEDQA b83 PASS RB turns on
ZEDQA b83 PASS LB turns back
ZEDQA b83 PASS Y goes to the contents
ZEDQA b83 PASS D-pad right turns on
ZEDQA b83 PASS Down goes to the strip (Next page)
ZEDQA b83 PASS left walks the strip
ZEDQA b83 PASS A presses Contents
ZEDQA b83 PASS Up goes back to the book
ZEDQA b83 PASS B closes the book and the game runs
ZEDQA b83 Skills -> flow SurvivalGuide_skill_books_title | rules SurvivalGuide_skill_books_title
ZEDQA b83 PASS F1 on Skills opens Skill Books facing its rules page
ZEDQA b83 PASS effects on: the clip plays on the page (2)
ZEDQA b83 PASS effects off: the still shows (2)
ZEDQA b83 spreads 44
ZEDQA b83 chapter opener: Combat
ZEDQA b83 put back: guide look 1, start-up box, video effects false
ZEDQA b83 RESULT 43 pass, 1 fail
ZEDQA b83 DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
