# ZeD-UI regression - 2026-10-26 10:47 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 10:47:15 |
| Finished | 2026-10-26 10:52:13 (4 min 58 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/hairbeard_manifest.txt (2 scripts) |
| Result | **0/2 pass**, 0 warn, 2 fail, 0 timeout |
| Go numbers | 13306 to 13316 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_hairbeard.lua: the game dropped to the main menu during this script
- quit: the game was still running after the quit (go 13312, 13315, 13316); close it by hand
- ZeD settings NOT put back (the game is still running): copy C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-10-26_1047_mods_fullscreen4k.md.modoptions.ini over C:\Users\danie\Zomboid\Lua\ModOptions.ini once it has closed

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | **FAIL** | 1 |  | 1 Java exception(s) in the log; the script ran twice (re-bump) |
| 2 | zedqa_hairbeard.lua | hb | **FAIL** | 59 |  | 6 Java exception(s) in the log; 1 ERR line(s); the script ran twice (re-bump); no DONE; the game dropped to the main menu during this script |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - FAIL, 1 s

- go 13306 at 10:48:59
- 1 Java exception(s) in the log
- the script ran twice (re-bump)

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #2 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
ERROR: General f:634> PlayerDB.updateWorldStreamer> Exception thrown
    org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
```

### 2. zedqa_hairbeard.lua (`ZEDQA hb`) - FAIL, 59 s

- go 13308 at 10:49:04
- 6 Java exception(s) in the log
- 1 ERR line(s)
- the script ran twice (re-bump)
- no DONE
- the game dropped to the main menu during this script

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA srj start
:	[ZeD.QA] run #3 ok=true
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
ERROR: General f:908> PlayerDB.updateWorldStreamer> Exception thrown
    org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
:	ZEDQA srj journal added: Bound Journal
:	ZEDQA srj key line: journal Inventory by nil
:	ZEDQA srj in a bag: Inventory (no bag worn)
:	ZEDQA srj focus on Aiming true
:	ZEDQA srj card Aiming: Starting Level (0)=0; Untranscribed XP=75; Total XP=75 | 75 XP not yet written. Transcribe Into Journal on the Bound Journal keeps it.
:	ZEDQA srj pad card: mode gamepad focused window is Character true element Aiming card up Aiming why true/Aiming/Aiming
ERROR: General f:1033> PlayerDB.updateWorldStreamer> Exception thrown
    org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
:	ZEDQA srj DONE
:	[ZeD.QA] windows reset (R)
:	ZEDQA mm start
:	[ZeD.QA] run #4 ok=true
:	ZEDQA mm mods: draw=true size=true pom=true blt=true where=true
:	ZEDQA mm had: pen false eraser false
:	ZEDQA mm marks at start 69
:	ZEDQA mm draw row open true | tools true,true,true sliders true,true
:	ZEDQA mm erase without an eraser -> tool nil (want nil)
:	ZEDQA mm draw armed true
:	ZEDQA mm before the stroke: centre 11626,11556 zoom 17.00 size 989x543 player at 494,271
:	ZEDQA mm pressed at 613,217 -> world 11692,11526 dot c at 11692,11526
:	ZEDQA mm mouse stroke added 299
:	ZEDQA mm pad stroke added 116
:	ZEDQA mm line armed line
:	ZEDQA mm line added 137
:	ZEDQA mm thickness by click 2.5 -> 25
:	ZEDQA mm fill by the D-pad 1 -> 0.9000000000000001
:	ZEDQA mm at the picture: centre 11626,11556 zoom 17.00 first dot on screen at 612,216
:	ZEDQA mm erase armed erase
ERROR: General f:1755> PlayerDB.updateWorldStreamer> Exception thrown
    org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
:	ZEDQA mm pad eraser took off 0
:	ZEDQA mm FAIL the eraser took nothing off
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
ERROR: General f:2092> PlayerDB.updateWorldStreamer> Exception thrown
    org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
:	ZEDQA mm pop-out docked side w 413
:	ZEDQA mm strokes taken off 552 | marks now 69 (start 69)
:	ZEDQA mm DONE
:	[ZeD.QA] run #5 ok=true
ERROR: General f:2798> PlayerDB.updateWorldStreamer> Exception thrown
    org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
ERROR: General f:2798> PlayerDB.updateWorldStreamer> Exception thrown
    org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
[ZeD.QA] bridge armed (main menu, poll every 30 ticks)
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    2x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    2x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N> PlayerDB.updateWorldStreamer> Exception thrown  :: org.sqlite.SQLiteException: [SQLITE_BUSY] The database file is locked (database is locked) at DB.newSQLException(DB.java:1179).
```
