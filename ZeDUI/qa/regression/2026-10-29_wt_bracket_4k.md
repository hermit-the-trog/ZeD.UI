# ZeD-UI regression - 2026-10-29 09:29 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-29 09:29:50 |
| Finished | 2026-10-29 09:34:36 (4 min 45 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/wt_bracket.txt (6 scripts) |
| Result | **5/6 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 15463 to 15470 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 15469, 15470)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_wt_bracket.lua | wtb | WARN | 16 | zqa_wtb_small_list.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png | 14 ERR line(s) |
| 3 | zedqa_grid.lua | grid | PASS | 7 | zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png |  |
| 4 | zedqa_sort_groups.lua | sg | PASS | 49 | zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png |  |
| 5 | zedqa_large.lua | lg | PASS | 9 | zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png |  |
| 6 | suite_tabs.lua | tabs | PASS | 14 |  |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 15463 at 09:31:49

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_wt_bracket.lua (`ZEDQA wtb`) - WARN, 16 s

- go 15464 at 09:31:54
- 14 ERR line(s)
- screenshots: zqa_wtb_small_list.png, zqa_wtb_narrow_wt.png, zqa_wtb_small_grid.png, zqa_wtb_large_list.png, zqa_wtb_large_grid.png, zqa_wtb_two_columns.png, zqa_wtb_two_columns_large.png

```text
[ZeD.QA] windows reset (R)
ZEDQA wtb start
[ZeD.QA] run #2 ok=true
ZEDQA wtb given: bag 5 x Base.Orange + Base.Saucepan, ground 5 x Base.Apple + Base.Saucepan (6 / 6)
ZEDQA wtb the ground was not shown in the World window; toggled on: true
ZEDQA wtb columns: char 0 world 0
ZEDQA wtb FAIL small list char: the container is not shown
ZEDQA wtb FAIL small list world: the container is not shown
ZEDQA wtb char WT column 158 -> 81
ZEDQA wtb FAIL narrow WT char: the container is not shown
ZEDQA wtb FAIL small grid char: the container is not shown
ZEDQA wtb FAIL small grid world: the container is not shown
ZEDQA wtb FAIL large list char: the container is not shown
ZEDQA wtb FAIL large list world: the container is not shown
ZEDQA wtb FAIL large grid char: the container is not shown
ZEDQA wtb FAIL large grid world: the container is not shown
ZEDQA wtb pack column on: true
ZEDQA wtb char columns 1
ZEDQA wtb FAIL the pack's column did not open beside the bag
ZEDQA wtb FAIL two columns char stack: no weight drawn
ZEDQA wtb FAIL two columns char single: no weight drawn
ZEDQA wtb FAIL two columns large char stack: no weight drawn
ZEDQA wtb FAIL two columns large char single: no weight drawn
ZEDQA wtb size back to small | bag Base.Orange left 0
ZEDQA wtb 14 checks FAILED; DONE
```

### 3. zedqa_grid.lua (`ZEDQA grid`) - PASS, 7 s

- go 15465 at 09:32:13
- screenshots: zqa_grid_1.png, zqa_grid_2.png, zqa_grid_3.png

```text
[ZeD.QA] windows reset (R)
ZEDQA grid start
[ZeD.QA] run #3 ok=true
ZEDQA grid grid on: cell 91 | cells placed 30 | toggle rects 2
ZEDQA grid first target: invrow:1 at 18,107 size 91x91
ZEDQA grid first cell: zone=charMainInv el=invrow:1 item=Apple (Fresh)
ZEDQA grid right (expect the next cell): zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid down (expect the cell below): zone=charMainInv el=invrow:8 item=Cigarette
ZEDQA grid up: zone=charMainInv el=invrow:2 item=Baseball Bat
ZEDQA grid up again (expect the toggle): zone=charMainInv el=view:list:player item=nil
ZEDQA grid card open true item Baseball Cap
ZEDQA grid after A on List: grid false cell nil
ZEDQA grid DONE
```

### 4. zedqa_sort_groups.lua (`ZEDQA sg`) - PASS, 49 s

- go 15466 at 09:32:24
- screenshots: zqa_sg_single_list_cat.png, zqa_sg_single_list_name.png, zqa_sg_single_list_cond.png, zqa_sg_single_list_wt.png, zqa_sg_single_list_name_rev.png, zqa_sg_fold_cat.png, zqa_sg_fold_name.png, zqa_sg_fold_back.png, zqa_sg_stack_open.png, zqa_sg_single_grid_cat.png, zqa_sg_single_grid_name.png, zqa_sg_single_grid_cond.png, zqa_sg_single_grid_wt.png, zqa_sg_single_grid_name_rev.png, zqa_sg_multi_list_cat.png, zqa_sg_multi_list_name.png, zqa_sg_multi_list_cond.png, zqa_sg_multi_list_wt.png, zqa_sg_multi_list_name_rev.png, zqa_sg_multi_grid_cat.png, zqa_sg_multi_grid_name.png, zqa_sg_multi_grid_cond.png, zqa_sg_multi_grid_wt.png, zqa_sg_multi_grid_name_rev.png

```text
[ZeD.QA] windows reset (R)
ZEDQA sg start
[ZeD.QA] run #4 ok=true
ZEDQA sg pack worn at base:back: true
ZEDQA sg given: bag 23, pack 8, bed 19, floor 11
ZEDQA sg floor container things 27 | char window true world window true
ZEDQA sg columns at start: char 0 world 0
ZEDQA sg mode single:
ZEDQA sg single list cat char: columns 1 rows 44 headers 3 order ok pad 44 (charMC1=0,charMainInv=44) grid false sort cat/true
ZEDQA sg single list cat world: columns 1 rows 14 headers 5 order ok pad 14 (worldMainInv=14) grid false sort cat/true
ZEDQA sg single list name char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid false sort name/true
ZEDQA sg single list name world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid false sort name/true
ZEDQA sg single list cond char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid false sort cond/true
ZEDQA sg single list cond world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid false sort cond/true
ZEDQA sg single list wt char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid false sort wt/true
ZEDQA sg single list wt world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid false sort wt/true
ZEDQA sg single list name rev char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid false sort name/false
ZEDQA sg single list name rev world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid false sort name/false
ZEDQA sg fold char: Accessory folded, rows 41 of 44, its header true
ZEDQA sg fold world: FirstAid folded, rows 13 of 14, its header true
ZEDQA sg fold char on Name: rows 44 headers 0
ZEDQA sg fold world on Name: rows 14 headers 0
ZEDQA sg fold char back on Category: still folded true rows 41
ZEDQA sg fold world back on Category: still folded true rows 13
ZEDQA sg stack char: Base.Apple x6 open, rows 49 of 44 (+5 expected), children follow true, headers 0
ZEDQA sg stack world: Base.Apple x2 open, rows 15 of 14 (+1 expected), children follow true, headers 0
ZEDQA sg single grid cat char: columns 1 rows 44 headers 5 order ok pad 44 (charMC1=0,charMainInv=44) grid true sort cat/true
ZEDQA sg single grid cat world: columns 1 rows 14 headers 5 order ok pad 14 (worldMainInv=14) grid true sort cat/true
ZEDQA sg single grid name char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid true sort name/true
ZEDQA sg single grid name world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid true sort name/true
ZEDQA sg single grid cond char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid true sort cond/true
ZEDQA sg single grid cond world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid true sort cond/true
ZEDQA sg single grid wt char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid true sort wt/true
ZEDQA sg single grid wt world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid true sort wt/true
ZEDQA sg single grid name rev char: columns 1 rows 44 headers 0 order ok pad 44 (charMC1=0,charMainInv=44) grid true sort name/false
ZEDQA sg single grid name rev world: columns 1 rows 14 headers 0 order ok pad 14 (worldMainInv=14) grid true sort name/false
ZEDQA sg mode multi: char:true world:true
ZEDQA sg multi list cat char: columns 2 rows 8+44 headers 9 order ok pad 52 (charMC1=8,charMainInv=44) grid false sort cat/true
ZEDQA sg multi list cat world: columns 2 rows 14+14 headers 9 order ok pad 28 (worldMC1=14,worldMainInv=14) grid false sort cat/true
ZEDQA sg multi list name char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid false sort name/true
ZEDQA sg multi list name world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid false sort name/true
ZEDQA sg multi list cond char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid false sort cond/true
ZEDQA sg multi list cond world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid false sort cond/true
ZEDQA sg multi list wt char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid false sort wt/true
ZEDQA sg multi list wt world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid false sort wt/true
ZEDQA sg multi list name rev char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid false sort name/false
ZEDQA sg multi list name rev world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid false sort name/false
ZEDQA sg multi grid cat char: columns 2 rows 8+44 headers 10 order ok pad 52 (charMC1=8,charMainInv=44) grid true sort cat/true
ZEDQA sg multi grid cat world: columns 2 rows 14+14 headers 10 order ok pad 28 (worldMC1=14,worldMainInv=14) grid true sort cat/true
ZEDQA sg multi grid name char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid true sort name/true
ZEDQA sg multi grid name world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid true sort name/true
ZEDQA sg multi grid cond char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid true sort cond/true
ZEDQA sg multi grid cond world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid true sort cond/true
ZEDQA sg multi grid wt char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid true sort wt/true
ZEDQA sg multi grid wt world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid true sort wt/true
ZEDQA sg multi grid name rev char: columns 2 rows 8+44 headers 0 order ok pad 52 (charMC1=8,charMainInv=44) grid true sort name/false
ZEDQA sg multi grid name rev world: columns 2 rows 14+14 headers 0 order ok pad 28 (worldMC1=14,worldMainInv=14) grid true sort name/false
ZEDQA sg columns off: char:true world:true
ZEDQA sg restored: bag things 64 (were 64), bed 2, world things on the square 0, floor container 16
ZEDQA sg all checks held; DONE
```

### 5. zedqa_large.lua (`ZEDQA lg`) - PASS, 9 s

- go 15467 at 09:33:16
- screenshots: zqa_lg_small_loot.png, zqa_lg_small_equip.png, zqa_lg_large_loot.png, zqa_lg_large_equip.png

```text
[ZeD.QA] windows reset (R)
ZEDQA lg start
[ZeD.QA] run #5 ok=true
ZEDQA lg small: rowH 53 buttonH 46 titleBarH 46 | cat 151 wt 158 | equip slot col 140
ZEDQA lg large: rowH 60 buttonH 53 titleBarH 53 | cat 176 wt 184 | equip slot col 163
ZEDQA lg size back to small | DONE
```

### 6. suite_tabs.lua (`ZEDQA tabs`) - PASS, 14 s

- go 15468 at 09:33:28

```text
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA tabs armed
[ZeD.QA] run #6 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=1617 focusables=34 {equipbelt=1 equipgroup=5 equippart=17 equipslot=9 equipview=2}
ZEDQA char tab=health active=health w=1617 focusables=27 {bodypart=17 exercise=9 health=1}
ZEDQA char tab=thermal active=thermal w=1617 focusables=26 {thermal=9 thermalpart=17}
ZEDQA char tab=identity active=identity w=1617 focusables=13 {hb=2 identity=11}
ZEDQA char tab=journal active=journal w=1617 focusables=6 {journal=2 jsub=4}
ZEDQA char tab=skills active=skills w=1617 focusables=60 {skill=35 skills=1 training=24}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=1617 focusables=12 {craft=12}
ZEDQA world tab=build active=build w=1617 focusables=15 {build=15}
ZEDQA world tab=furniture active=furniture w=1617 focusables=5 {fur=5}
ZEDQA world tab=maps active=maps w=1694 focusables=17 {map=17}
ZEDQA world tab=forage active=forage w=1617 focusables=3 {forage=3}
ZEDQA world tab=animals active=animals w=1617 focusables=3 {animals=3}
ZEDQA world tab=vehicle active=vehicle w=1617 focusables=1 {mech=1}
ZEDQA tabs done
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
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
