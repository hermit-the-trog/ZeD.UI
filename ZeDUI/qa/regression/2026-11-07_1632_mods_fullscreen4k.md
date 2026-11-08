# ZeD-UI regression - 2026-11-07 16:33 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-07 16:33:04 |
| Finished | 2026-11-07 16:35:32 (2 min 28 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.3.0-beta7 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\woundsov_manifest.txt (6 scripts) |
| Result | **4/6 pass**, 2 warn, 0 fail, 0 timeout |
| Go numbers | 23115 to 23122 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 23121, 23122)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | suite_tabs.lua | tabs | PASS | 8 |  |  |
| 3 | zedqa_health_padprobe.lua | hp | WARN | 3 |  | 2 ERR line(s) |
| 4 | zedqa_ctxlist.lua | cl | PASS | 4 | zqa_cl_1.png, zqa_cl_2.png |  |
| 5 | zedqa_card_pad.lua | cp | PASS | 4 | zqa_cp_card.png |  |
| 6 | zedqa_exinfo.lua | ex | WARN | 8 | zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_menu.png, zqa_ex_situp.png | 23 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 23115 at 16:34:21

```text
[ZeD.QA] state #1 speed=1 paused=false player=10608,11151 grid=19 inCar=false vehicles=66 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 10608,11151,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ERROR: General f:380 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ERROR: General f:388 at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. suite_tabs.lua (`ZEDQA tabs`) - PASS, 8 s

- go 23116 at 16:34:29

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA char tabs: loot,equip,health,thermal,identity,journal,skills
ZEDQA world tabs: loot,craft,build,furniture,maps,forage,animals,vehicle
ZEDQA tabs armed
[ZeD.QA] run #2 ok=true
ZEDQA char tab=loot active=loot w=777 focusables=0 {}
ZEDQA char tab=equip active=equip w=777 focusables=0 {}
ZEDQA char tab=health active=health w=777 focusables=0 {}
ZEDQA char tab=thermal active=thermal w=777 focusables=0 {}
ZEDQA char tab=identity active=identity w=777 focusables=0 {}
ZEDQA char tab=journal active=journal w=777 focusables=0 {}
ZEDQA char tab=skills active=skills w=777 focusables=0 {}
ZEDQA world tab=loot active=loot w=777 focusables=0 {}
ZEDQA world tab=craft active=craft w=777 focusables=0 {}
ZEDQA world tab=build active=build w=777 focusables=0 {}
ZEDQA world tab=furniture active=furniture w=777 focusables=0 {}
ZEDQA world tab=maps active=maps w=777 focusables=0 {}
ZEDQA world tab=forage active=forage w=777 focusables=0 {}
ZEDQA world tab=animals active=animals w=777 focusables=0 {}
ZEDQA world tab=vehicle active=vehicle w=777 focusables=0 {}
ZEDQA tabs done
```

### 3. zedqa_health_padprobe.lua (`ZEDQA hp`) - WARN, 3 s

- go 23117 at 16:34:41
- 2 ERR line(s)

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #3 ok=true
ZEDQA hp screen 3840x2160 drawer 0x689 size large
ZEDQA hp PASS large: no body stop under the band (0)
ZEDQA hp down 00 -> charMainInv invrow:1 x0 y100 w350 h53
ZEDQA hp FAIL large: Down from the figure reaches the band (ended on invrow:1)
ZEDQA hp PASS large: every body stop the walk landed on was whole in view (0 not)
ZEDQA hp screen 3840x2160 drawer 0x689 size small
ZEDQA hp PASS small: no body stop under the band (0)
ZEDQA hp down 00 -> charMainInv invrow:1 x0 y100 w350 h53
ZEDQA hp FAIL small: Down from the figure reaches the band (ended on invrow:1)
ZEDQA hp PASS small: every body stop the walk landed on was whole in view (0 not)
ZEDQA hp 2 failed
ZEDQA hp DONE
```

### 4. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 4 s

- go 23118 at 16:34:47
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #4 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place Item, Favorite, Set Unwanted, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 5. zedqa_card_pad.lua (`ZEDQA cp`) - PASS, 4 s

- go 23119 at 16:34:54
- screenshots: zqa_cp_card.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cp start
[ZeD.QA] run #5 ok=true
ZEDQA cp card open false | card buttons 0 {}
ZEDQA cp before left: zone=charMainInv el=invrow:1
ZEDQA cp after left (expect charItemCard): zone=charTabBar el=tab:loot
ZEDQA cp right 1: zone=charMainInv el=invrow:1
ZEDQA cp right 2: zone=charContainerStrip el=container:1
ZEDQA cp left: zone=charMainInv el=invrow:1
ZEDQA cp after B: card item nil (expect nil)
ZEDQA cp health: inv then left (expect charTabContent): zone=charTabBar el=tab:health
ZEDQA cp health: right: zone=charMainInv el=invrow:1
ZEDQA cp DONE
```

### 6. zedqa_exinfo.lua (`ZEDQA ex`) - WARN, 8 s

- go 23120 at 16:35:02
- 23 ERR line(s)
- screenshots: zqa_ex_squats.png, zqa_ex_barbellcurl.png, zqa_ex_menu.png, zqa_ex_situp.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=35 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ex start
[ZeD.QA] run #6 ok=true
ZEDQA ex ok squats desc is vanilla's tooltip
ZEDQA ex ok squats legs line
ZEDQA ex ok pushups: arms line only (chest has none)
ZEDQA ex ok burpees: legs and arms
ZEDQA ex ok situp abs line
ZEDQA ex ok regularity in 0..1
ZEDQA ex regularity squats 0
ZEDQA ex ok barbell curl without a barbell warns '(Requires Barbell)'
ZEDQA ex ok squats has no item warning
ZEDQA ex ok with a barbell the warning clears
ZEDQA ex ok unknown exercise gives nil
ZEDQA ex ok sitonground shows Stand up before exercising
ZEDQA ex ok reason gone after standing
ZEDQA ex tab health true | shown nil | reserved nil used nil w nil
ZEDQA ex FAIL block describes the picked exercise (squats)
ZEDQA ex FAIL room reserved
ZEDQA ex FAIL block follows the pick (barbell curl)
ZEDQA ex ok same reserved height for another exercise
ZEDQA ex FAIL band stops: exercise box
ZEDQA ex FAIL band stops: - and +
ZEDQA ex FAIL band stops: Start
ZEDQA ex ok no exercise-button stops left
ZEDQA ex FAIL pop-up open
ZEDQA ex FAIL pop-up lists the seven exercises
ZEDQA ex FAIL rows are the stops while open
ZEDQA ex FAIL the list opens on the chosen row (barbell curl; on invrow:1)
ZEDQA ex FAIL the list outlives the screenshot
ZEDQA ex FAIL the open list is modal (its rows alone, marked)
ZEDQA ex FAIL Up stops on the first row (view:list:player)
ZEDQA ex FAIL Down stops on the last row, the list still open (charCtl:near)
ZEDQA ex FAIL Left and Right do nothing in the list
ZEDQA ex ok nothing below the last row (the preview stays in the list)
ZEDQA ex ok B shuts the list, the choice unchanged
ZEDQA ex FAIL B: the focus is back on the box (charCtl:near)
ZEDQA ex FAIL open again
ZEDQA ex FAIL pick shut the list and changed the choice
ZEDQA ex FAIL focus is back on the box
ZEDQA ex FAIL block follows the pick (burpees)
ZEDQA ex FAIL + steps the time by 10
ZEDQA ex ok - steps it back
ZEDQA ex FAIL time keys change no choice
ZEDQA ex FAIL block follows the pick (situp)
ZEDQA ex DONE
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
```
