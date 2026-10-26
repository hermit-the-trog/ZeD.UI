# ZeD-UI regression - 2026-10-26 11:16 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 11:16:20 |
| Finished | 2026-10-26 11:18:36 (2 min 15 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\srj_only_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13366 to 13369 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13368, 13369)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_srj.lua | srj | PASS | 9 | zqa_srj_none.png, zqa_srj_main.png, zqa_srj_card_pad.png, zqa_srj_card_none.png, zqa_srj_folded.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 13366 at 11:17:51

```text
:	[ZeD.QA] windows reset (R)
:	ZEDQA pre start
:	[ZeD.QA] run #1 ok=true
:	ZEDQA pre char true world true speed 1 ticks 60 frames 61
:	ZEDQA pre search overlay: enabled false, override false, manager false
:	ZEDQA pre DONE
```

### 2. zedqa_srj.lua (`ZEDQA srj`) - PASS, 9 s

- go 13367 at 11:17:56
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
