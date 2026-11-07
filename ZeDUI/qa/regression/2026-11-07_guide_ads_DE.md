# ZeD-UI regression - 2026-11-07 03:20 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-07 03:20:15 |
| Finished | 2026-11-07 03:21:49 (1 min 33 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\guide_ads.txt (3 scripts) |
| Result | **2/3 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 22835 to 22839 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22838, 22839)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 3 | zedqa_guide_ads.lua | gad | WARN | 7 | zqa_gad_3840x2160_DE_p32.png, zqa_gad_3840x2160_DE_p9.png | 1 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22835 at 03:21:10

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 22836 at 03:21:15

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #2 ok=true
ZEDQA hcn DONE
```

### 3. zedqa_guide_ads.lua (`ZEDQA gad`) - WARN, 7 s

- go 22837 at 03:21:19
- 1 ERR line(s)
- screenshots: zqa_gad_3840x2160_DE_p32.png, zqa_gad_3840x2160_DE_p9.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA gad start
[ZeD.QA] run #3 ok=true
ZEDQA gad language DE, screen 3840x2160, UI scale 1.75
ZEDQA gad PASS F1 on Full opens the book
ZEDQA gad unit 1.75, seed 1371904780, pages 106
ZEDQA gad small_kb deal: 9:half:half_better_bed_than_dead 9:notes 13:third:third_hit_vids 14:third:third_rolling_fork_camp 19:notes 20:third:third_zippee_market 23:third:third_phils_pawn 24:pair:quarter_xray_specs+quarter_iron_mike 25:third:third_aa_ron_hunting 26:third:third_pioneer_girls 27:pair:quarter_kentucky_seed_co+quarter_learn_magic 29:third:third_maps_unlimited 30:third:third_salt_river_bait 31:third:third_west_point_range 32:full:house 33:third:third_nails_and_nuts 34:half:half_well_regulated_militia 36:full:full_greenes_grocery 37:third:third_knob_creek_hunting 38:half:half_body_chisel 39:third:third_time_4_sport 41:pair:quarter_brine_buddies+quarter_safari_club 41:notes 42:full:full_crossroads_mall 43:notes 44:notes 45:notes 47:notes 51:notes 53:half:half_pharmahug 53:notes 54:pair:quarter_wizards_keep+quarter_motorbikes_and_more 56:notes 59:notes 62:notes 63:notes 64:notes 65:notes 66:notes 68:notes 70:notes 72:notes 73:notes 76:notes 77:notes 79:notes 81:notes 82:notes 83:notes 84:notes 89:notes 102:notes 106:half:half_jamieton_army_surplus
ZEDQA gad small_kb count: ZeD guide ads (text x1.00, keyboard): full pages 3 (0 NOTES); 310 slots 9 (0 with no half or pair left); 205 slots 35 (23 with no third left); NOTES blocks 29; dealt full 3/4, half 5/7, quarter 8/12, third 12/12
ZEDQA gad PASS small_kb: no ad dealt twice
ZEDQA gad PASS small_kb: half and pair take turns down the book (5 halves, 4 pairs)
ZEDQA gad FAIL small_kb: the First Days checklist comes first on its filler page (no checklist page)
ZEDQA gad small_kb thirds: 205 slots asked 35, no third left 23, thirds dealt 12 of 12; NOTES blocks 29; full pages 3 (0 NOTES)
ZEDQA gad small_kb pair p27: tops 1022/1022, gutter 18 px
ZEDQA gad small_kb pair p41: tops 675/675, gutter 18 px
ZEDQA gad small_kb pair p54: tops 1022/1022, gutter 18 px
ZEDQA gad PASS small_kb: every spread's ads inside the text block, clear of the foot, at design size, level pairs, as dealt (53 spreads)
ZEDQA gad small_kb: 24 ad pictures drawn across the book
ZEDQA gad house ad on page 32, an English ad on page 9
ZEDQA gad PASS the house ad is one of the whole-page ads in DE
ZEDQA gad house ad head: Das ganze Regal
ZEDQA gad shot p32
ZEDQA gad shot p9
ZEDQA gad 5 passed, 1 failed
ZEDQA gad DONE
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
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
