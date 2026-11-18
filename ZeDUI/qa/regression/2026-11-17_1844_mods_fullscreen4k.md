# ZeD-UI regression - 2026-11-17 18:45 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 18:45:06 |
| Finished | 2026-11-17 18:47:00 (1 min 53 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\carkey_tex.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28670 to 28673 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28672, 28673)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_carkey_tex.lua | ckt | PASS | 14 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28670 at 18:46:18

```text
[ZeD.QA] state #1 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta19 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_carkey_tex.lua (`ZEDQA ckt`) - PASS, 14 s

- go 28671 at 18:46:23

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ckt start
[ZeD.QA] run #2 ok=true
ZEDQA ckt PASS the dev-only fixture ZeDQAOverheadTex is active (run with carkey_tex_mods.txt)
ZEDQA ckt PASS the prelude's car helpers are here
ZEDQA ckt texture media/ui/CarKey.png: name CarKey, 28 x 26
ZEDQA ckt texture media/ui/CarKey_none.png: name CarKey_none, 30 x 28
ZEDQA ckt RESULT CarKey: 28 x 26, neither the mod's (31 x 30) nor 32 x 32: look at the pictures
ZEDQA ckt RESULT CarKey_none: 30 x 28, neither the mod's (62 x 60) nor 32 x 32: look at the pictures
ZEDQA ckt TextDrawObject: 'QA' 18 x 17; 'QA' + key 46 x 26; the key line alone 29 x 26; a space 1 wide; the no-key line 23 x 21
ZEDQA ckt RESULT CarKey drawn size: about 28 x 26 (the key line less a space; 0.75 of the texture would be 21 x 19)
ZEDQA ckt RESULT CarKey_none drawn size: about 22 x 21 (0.75 of the texture would be 22 x 21)
ZEDQA vp ckt player=925,13040 grid=19 chunks (152 tiles) loaded x 848-1000 y 12968-13120 sq=917,13030 dist=13.5 chunk=true inMap=true car=Base.CarNormal at 917.0,13030.0 dist=13.5 vehicles=32
ZEDQA car ckt Base.CarNormal spawned on spot 11 (917,13030)
ZEDQA ckt PASS a sedan on the drag strip
ZEDQA ckt PASS its key is in the inventory
ZEDQA ckt car at 917.0,13030.0
ZEDQA ckt far: near vehicle false (this car false), its key in the inventory true, hotwired false, keys in ignition false, sandbox easy use false, name line height 0
ZEDQA ckt far: head on screen 1920,1017, zoom 1.00
ZEDQA ckt CROP ckt_far x=1830 y=907 w=180 h=130 (over the head: the name line and its key)
ZEDQA ckt CROP ckt_far x=1880 y=947 w=80 h=70 (tight, for measuring the key)
ZEDQA ckt PASS 6 tiles off, the car is not 'near' (no key expected over the head)
ZEDQA ckt picture ckt_far.png
ZEDQA ckt beside it at offset -2.5,0.5
ZEDQA ckt key: near vehicle true (this car true), its key in the inventory true, hotwired false, keys in ignition false, sandbox easy use false, name line height 0
ZEDQA ckt key: head on screen 1920,1017, zoom 1.00
ZEDQA ckt CROP ckt_key x=1830 y=907 w=180 h=130 (over the head: the name line and its key)
ZEDQA ckt CROP ckt_key x=1880 y=947 w=80 h=70 (tight, for measuring the key)
ZEDQA ckt PASS beside it, the game counts the car as near (getNearVehicle)
ZEDQA ckt PASS with its key in the inventory (haveThisKeyId): the game draws CarKey over the head
ZEDQA ckt picture ckt_key.png
ZEDQA ckt nokey: near vehicle true (this car true), its key in the inventory false, hotwired false, keys in ignition false, sandbox easy use false, name line height 0
ZEDQA ckt nokey: head on screen 1920,1017, zoom 1.00
ZEDQA ckt CROP ckt_nokey x=1830 y=907 w=180 h=130 (over the head: the name line and its key)
ZEDQA ckt CROP ckt_nokey x=1880 y=947 w=80 h=70 (tight, for measuring the key)
ZEDQA ckt PASS still beside it, the key out of the inventory (no key expected over the head)
ZEDQA ckt picture ckt_nokey.png
ZEDQA ckt in the driver's seat, no key: tryStartEngine called
ZEDQA ckt the say line over the head: ''
ZEDQA ckt ZeD's speech bubble holds: 'nil'
ZEDQA ckt nokey_start: near vehicle false (this car false), its key in the inventory false, hotwired false, keys in ignition false, sandbox easy use false, name line height 0
ZEDQA ckt nokey_start: head on screen 1920,1038, zoom 1.00
ZEDQA ckt CROP ckt_nokey_start x=1830 y=928 w=180 h=130 (over the head: the name line and its key)
ZEDQA ckt CROP ckt_nokey_start x=1880 y=968 w=80 h=70 (tight, for measuring the key)
ZEDQA ckt picture ckt_nokey_start.png
ZEDQA ckt picture ckt_nokey_start_late.png
ZEDQA ckt PASS put back: the character is out of the car
ZEDQA ckt PASS put back: the car is removed
ZEDQA ckt all checks passed
ZEDQA ckt DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
