# ZeD-UI regression - 2026-11-16 18:54 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-16 18:54:12 |
| Finished | 2026-11-16 18:56:44 (2 min 31 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta18 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\r1b_icons.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28007 to 28010 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28009, 28010)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_r1b_icons.lua | r1b | PASS | 59 | zqa_r1b_dark_menu_bag.png, zqa_r1b_dark_menu_hammer.png, zqa_r1b_dark_menu_carrot.png, zqa_r1b_dark_menu_potato.png, zqa_r1b_dark_wheel_rest.png, zqa_r1b_dark_wheel_point_1.png, zqa_r1b_dark_wheel_point_2.png, zqa_r1b_dark_wheel_point_3.png, zqa_r1b_dark_wheel_point_4.png, zqa_r1b_dark_wheel_point_5.png, zqa_r1b_dark_wheel_point_6.png, zqa_r1b_dark_wheel_point_7.png, zqa_r1b_dark_wheel_point_8.png, zqa_r1b_dark_wheel_point_9.png, zqa_r1b_dark_wheel_point_10.png, zqa_r1b_light_menu_bag.png, zqa_r1b_light_menu_hammer.png, zqa_r1b_light_menu_carrot.png, zqa_r1b_light_menu_potato.png, zqa_r1b_light_wheel_rest.png, zqa_r1b_light_wheel_point_1.png, zqa_r1b_light_wheel_point_2.png, zqa_r1b_light_wheel_point_3.png, zqa_r1b_light_wheel_point_4.png, zqa_r1b_light_wheel_point_5.png, zqa_r1b_light_wheel_point_6.png, zqa_r1b_light_wheel_point_7.png, zqa_r1b_light_wheel_point_8.png, zqa_r1b_light_wheel_point_9.png, zqa_r1b_light_wheel_point_10.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28007 at 18:55:17

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
ZEDQA pre ZeD version=0.3.0-beta18 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_r1b_icons.lua (`ZEDQA r1b`) - PASS, 59 s

- go 28008 at 18:55:22
- screenshots: zqa_r1b_dark_menu_bag.png, zqa_r1b_dark_menu_hammer.png, zqa_r1b_dark_menu_carrot.png, zqa_r1b_dark_menu_potato.png, zqa_r1b_dark_wheel_rest.png, zqa_r1b_dark_wheel_point_1.png, zqa_r1b_dark_wheel_point_2.png, zqa_r1b_dark_wheel_point_3.png, zqa_r1b_dark_wheel_point_4.png, zqa_r1b_dark_wheel_point_5.png, zqa_r1b_dark_wheel_point_6.png, zqa_r1b_dark_wheel_point_7.png, zqa_r1b_dark_wheel_point_8.png, zqa_r1b_dark_wheel_point_9.png, zqa_r1b_dark_wheel_point_10.png, zqa_r1b_light_menu_bag.png, zqa_r1b_light_menu_hammer.png, zqa_r1b_light_menu_carrot.png, zqa_r1b_light_menu_potato.png, zqa_r1b_light_wheel_rest.png, zqa_r1b_light_wheel_point_1.png, zqa_r1b_light_wheel_point_2.png, zqa_r1b_light_wheel_point_3.png, zqa_r1b_light_wheel_point_4.png, zqa_r1b_light_wheel_point_5.png, zqa_r1b_light_wheel_point_6.png, zqa_r1b_light_wheel_point_7.png, zqa_r1b_light_wheel_point_8.png, zqa_r1b_light_wheel_point_9.png, zqa_r1b_light_wheel_point_10.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA r1b start
[ZeD.QA] run #2 ok=true
ZEDQA r1b given: bag true, hammer true, carrot true, potato true
ZEDQA r1b theme dark
ZEDQA r1b dark bag options: Wear | Equip Primary | Equip Secondary | Drop | Place Item | More | Save to loadout | Move to
ZEDQA r1b shot zqa_r1b_dark_menu_bag
ZEDQA r1b dark hammer options: Equip Primary | Equip Secondary | Attach | Craft | Drop | Place Item | More | Save to loadout | Move to | Rename | Pin to title bar
ZEDQA r1b shot zqa_r1b_dark_menu_hammer
ZEDQA r1b dark carrot options: Eat | Craft | Drop | Place Item | More | Save to loadout | Move to | Rename
ZEDQA r1b shot zqa_r1b_dark_menu_carrot
ZEDQA r1b dark potato options: Equip Primary | Equip Secondary | Eat | Craft | Drop | Place Item | More | Save to loadout | Move to | Rename
ZEDQA r1b shot zqa_r1b_dark_menu_potato
ZEDQA r1b dark Character wheel slices: 1:Tabs Character window 2:Weapons 3:Eat 4:Drink 5:Medicine and first aid Nothing to treat, no medicine on you. 6:Sleep Not tired enough to sleep. 7:Clothing Nothing you wear can change. 8:Use Smoke | Read | Watch | Radio 9:Loadouts Restock a saved loadout 10:Belt
ZEDQA r1b shot zqa_r1b_dark_wheel_rest
ZEDQA r1b shot zqa_r1b_dark_wheel_point_1
ZEDQA r1b shot zqa_r1b_dark_wheel_point_2
ZEDQA r1b shot zqa_r1b_dark_wheel_point_3
ZEDQA r1b shot zqa_r1b_dark_wheel_point_4
ZEDQA r1b shot zqa_r1b_dark_wheel_point_5
ZEDQA r1b shot zqa_r1b_dark_wheel_point_6
ZEDQA r1b shot zqa_r1b_dark_wheel_point_7
ZEDQA r1b shot zqa_r1b_dark_wheel_point_8
ZEDQA r1b shot zqa_r1b_dark_wheel_point_9
ZEDQA r1b shot zqa_r1b_dark_wheel_point_10
ZEDQA r1b theme light
ZEDQA r1b light bag options: Wear | Equip Primary | Equip Secondary | Drop | Place Item | More | Save to loadout | Move to
ZEDQA r1b shot zqa_r1b_light_menu_bag
ZEDQA r1b light hammer options: Equip Primary | Equip Secondary | Attach | Craft | Drop | Place Item | More | Save to loadout | Move to | Rename | Pin to title bar
ZEDQA r1b shot zqa_r1b_light_menu_hammer
ZEDQA r1b light carrot options: Eat | Craft | Drop | Place Item | More | Save to loadout | Move to | Rename
ZEDQA r1b shot zqa_r1b_light_menu_carrot
ZEDQA r1b light potato options: Equip Primary | Equip Secondary | Eat | Craft | Drop | Place Item | More | Save to loadout | Move to | Rename
ZEDQA r1b shot zqa_r1b_light_menu_potato
ZEDQA r1b light Character wheel slices: 1:Tabs Character window 2:Weapons 3:Eat 4:Drink 5:Medicine and first aid Nothing to treat, no medicine on you. 6:Sleep Not tired enough to sleep. 7:Clothing Nothing you wear can change. 8:Use Smoke | Read | Watch | Radio 9:Loadouts Restock a saved loadout 10:Belt
ZEDQA r1b shot zqa_r1b_light_wheel_rest
ZEDQA r1b shot zqa_r1b_light_wheel_point_1
ZEDQA r1b shot zqa_r1b_light_wheel_point_2
ZEDQA r1b shot zqa_r1b_light_wheel_point_3
ZEDQA r1b shot zqa_r1b_light_wheel_point_4
ZEDQA r1b shot zqa_r1b_light_wheel_point_5
ZEDQA r1b shot zqa_r1b_light_wheel_point_6
ZEDQA r1b shot zqa_r1b_light_wheel_point_7
ZEDQA r1b shot zqa_r1b_light_wheel_point_8
ZEDQA r1b shot zqa_r1b_light_wheel_point_9
ZEDQA r1b shot zqa_r1b_light_wheel_point_10
ZEDQA r1b put back: theme light/teal/small, given things removed
ZEDQA r1b DONE
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
