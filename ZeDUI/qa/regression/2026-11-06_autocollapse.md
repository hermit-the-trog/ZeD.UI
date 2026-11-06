# ZeD-UI regression - 2026-11-06 11:33 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-06 11:33:41 |
| Finished | 2026-11-06 11:36:21 (2 min 39 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\autocollapse.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 22056 to 22061 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 22060, 22061)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 3 | zedqa_autocollapse.lua | acl | WARN | 69 | zqa_acl_3840x2160_1_both_rolled_up.png, zqa_acl_3840x2160_2_char_hovered_open.png, zqa_acl_3840x2160_3_pinned_stays_open.png, zqa_acl_3840x2160_4_unpinned_rolled.png | 6 ERR line(s) |
| 4 | zedqa_shade_probe.lua | shp | PASS | 1 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 22056 at 11:34:36

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=47 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre clock 1.00 -> 11.00 (daylight)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 22057 at 11:34:41

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=47 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #2 ok=true
ZEDQA hcn DONE
```

### 3. zedqa_autocollapse.lua (`ZEDQA acl`) - WARN, 69 s

- go 22058 at 11:34:45
- 6 ERR line(s)
- screenshots: zqa_acl_3840x2160_1_both_rolled_up.png, zqa_acl_3840x2160_2_char_hovered_open.png, zqa_acl_3840x2160_3_pinned_stays_open.png, zqa_acl_3840x2160_4_unpinned_rolled.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=47 missing=get
[ZeD.QA] windows reset (R)
ZEDQA acl start
[ZeD.QA] run #3 ok=true
ZEDQA acl autoCollapse char true, world true
ZEDQA acl PASS both windows have autoCollapse
ZEDQA acl FAIL 1 s after the pointer leaves: both still open
ZEDQA acl PASS after about 3 s away: both rolled up
ZEDQA acl rolled heights: char 46 (title 46), world 46 (title 46)
ZEDQA acl shown heights: char 46, world 46
ZEDQA acl PASS a rolled window shows its title bar only
ZEDQA acl shot 1_both_rolled_up
ZEDQA acl PASS the pointer where the body was is not over the window (the world gets it), and it stays rolled
ZEDQA acl FAIL pointer on the Character window's title bar: it rolls down, the World window stays up
ZEDQA acl char height after roll-down 46
ZEDQA acl FAIL it rolls down to its full height
ZEDQA acl shot 2_char_hovered_open
ZEDQA acl pin box at 695,11 23x23
ZEDQA acl FAIL a real click on the pin pins it, kept in the character's modData
ZEDQA acl FAIL pinned: stays open with the pointer away 3 s
ZEDQA acl shot 3_pinned_stays_open
ZEDQA acl FAIL the World window rolls down on hover
ZEDQA acl aiming false
ZEDQA acl PASS aiming: the World window rolls up at once when the pointer leaves
ZEDQA acl PASS a second click unpins it
ZEDQA acl PASS unpinned again: it rolls up after the wait
ZEDQA acl shot 4_unpinned_rolled
ZEDQA acl RESULT 7 pass, 6 fail
ZEDQA acl DONE
```

### 4. zedqa_shade_probe.lua (`ZEDQA shp`) - PASS, 1 s

- go 22059 at 11:35:58

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=47 missing=get
[ZeD.QA] windows reset (R)
ZEDQA shp before: height 735, title 46, minimumHeight 385, windowShaded false
ZEDQA shp right after setWindowShaded(true): height 46, self.height 46, minimumHeight 46
[ZeD.QA] run #4 ok=true
ZEDQA shp onResize: height 46 -> 46, minimumHeight 46 -> 46
ZEDQA shp frame 1: height 46, self.height 46, minimumHeight 46, windowShaded true
ZEDQA shp frame 2: height 46, self.height 46, minimumHeight 46, windowShaded true
ZEDQA shp frame 3: height 46, self.height 46, minimumHeight 46, windowShaded true
ZEDQA shp frame 4: height 46, self.height 46, minimumHeight 46, windowShaded true
ZEDQA shp frame 5: height 46, self.height 46, minimumHeight 46, windowShaded true
ZEDQA shp frame 6: height 46, self.height 46, minimumHeight 46, windowShaded true
ZEDQA shp done: Lua setHeight calls while rolled up 0; height after roll-down 735
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
