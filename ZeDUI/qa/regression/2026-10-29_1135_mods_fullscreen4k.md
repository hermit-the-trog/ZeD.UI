# ZeD-UI regression - 2026-10-29 11:35 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 11:35:57 |
| Finished | 2026-10-29 11:38:13 (2 min 16 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/dropnloot_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 15647 to 15650 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15649, 15650)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_dropnloot.lua | dnl | PASS | 9 | zqa_dnl_row.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 15647 at 11:37:25

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_dropnloot.lua (`ZEDQA dnl`) - PASS, 9 s

- go 15648 at 11:37:30
- screenshots: zqa_dnl_row.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dnl start
[ZeD.QA] run #2 ok=true
ZEDQA dnl providers 1 | mod functions: move function hideDrop function hideLoot function
ZEDQA dnl bed selected true
ZEDQA dnl your row: moves [xfer, same(off), near(off)] own [dnl:transfer]
ZEDQA dnl world row: moves [take, same(off), floor] own [dnl:loot]
ZEDQA dnl Transfer Category in your row: true label 'Transfer Category' help 'Transfer all items of the same category from your inventory to the current loot container.'
ZEDQA dnl Loot Category in the World row: true label 'Loot Category' help 'Loot all items of the same category from the current loot container to your inventory.'
ZEDQA dnl PASS both buttons present
ZEDQA dnl transfer: dnl:transfer present true enabled true | target holds [Container,Junk,Material,FirstAid] | should move 12
ZEDQA dnl press dnl:transfer (enabled true)
ZEDQA dnl transfer: moved 12 (expected 12), target gained 12, movable of a held category left behind 0
ZEDQA dnl PASS transfer
ZEDQA dnl beans still with you 1, in the bed 0 | nails in the bed 8, planks 0
ZEDQA dnl loot: dnl:loot present true enabled true | target holds [Clothing,Accessory,ProtectiveGear,Bag,MaterialWeapon,ToolWeapon,Household,VehicleMaintenance,Weapon,Literature,SportsWeapon,Food,Water,Entertainment,FireSource,Material] | should move 10
ZEDQA dnl press dnl:loot (enabled true)
ZEDQA dnl loot: moved 10 (expected 10), target gained 10, movable of a held category left behind 0
ZEDQA dnl PASS loot
ZEDQA dnl Loot Category afterwards: enabled false
ZEDQA dnl PASS disabled with nothing to take
ZEDQA dnl SKIP floor: it holds 16 things of its own (nothing foreign is moved)
ZEDQA dnl floor holds 16 after the drop; selected true
ZEDQA dnl world row on the floor: moves [take, same(off)] own [dnl:loot]
ZEDQA dnl loot from floor: dnl:loot present true enabled true | target holds [Clothing,Accessory,ProtectiveGear,Bag,MaterialWeapon,ToolWeapon,Household,VehicleMaintenance,Weapon,Literature,SportsWeapon,Food,Water,Entertainment,FireSource,Material] | should move 10
ZEDQA dnl press dnl:loot (enabled true)
ZEDQA dnl loot from floor: moved 10 (expected 10), target gained 10, movable of a held category left behind 0
ZEDQA dnl PASS loot from floor
ZEDQA dnl floor now holds 6
ZEDQA dnl your row with the floor on show: moves [xfer, same, near] own [dnl:transfer]
ZEDQA dnl transfer to floor: dnl:transfer present true enabled true | target holds [Material,Junk,WeaponImprovised] | should move 16
ZEDQA dnl press dnl:transfer (enabled true)
ZEDQA dnl transfer to floor: moved 16 (expected 16), target gained 16, movable of a held category left behind 0
ZEDQA dnl PASS transfer to floor
ZEDQA dnl floor after taking it all back: 0
ZEDQA dnl restored: bag 69 things, bed 2 things
ZEDQA dnl DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
