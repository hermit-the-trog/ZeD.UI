# ZeD-UI regression - 2026-11-12 21:28 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-12 21:28:51 |
| Finished | 2026-11-12 21:32:59 (4 min 7 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=true height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta12 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI\tools\qa\summercar_manifest.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 26035 to 26038 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=2)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 26037, 26038)
- font size: the director's line put back (fontSize=2)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_summercar.lua | sc | WARN | 155 | zqa_sc_B_opened.png, zqa_sc_C_stays.png, zqa_sc_D_folded.png, zqa_sc_E_shut.png, zqa_sc_F_menu.png, zqa_sc_G_footer.png, zqa_sc_H_hood_closed.png, zqa_sc_L_tile.png, zqa_sc_N_lift_menu.png | 5 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 26035 at 21:29:56

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
ZEDQA pre ZeD version=0.3.0-beta12 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_summercar.lua (`ZEDQA sc`) - WARN, 155 s

- go 26036 at 21:30:01
- 5 ERR line(s)
- screenshots: zqa_sc_B_opened.png, zqa_sc_C_stays.png, zqa_sc_D_folded.png, zqa_sc_E_shut.png, zqa_sc_F_menu.png, zqa_sc_G_footer.png, zqa_sc_H_hood_closed.png, zqa_sc_L_tile.png, zqa_sc_N_lift_menu.png

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sc start (89 steps)
[ZeD.QA] run #2 ok=true
ZEDQA sc startup line ok=true
ZEDQA sc cars true true
ZEDQA sc ERR step 'B wait inspected' timed out
ZEDQA sc engine window false 62987 ms after the inspection
ZEDQA sc B opened: no engine window
ZEDQA sc shot B_opened
ZEDQA sc ERR B: the World window not moved (1929)
ZEDQA sc B saved x now 1102.2857142857142
ZEDQA sc ERR C: still open 5 s later
ZEDQA sc C: no engine window
ZEDQA sc shot C_stays
ZEDQA sc ERR D: the pointer on the engine window holds the tab
ZEDQA sc D after 3.5 s in the world: tab showing true engine window false
ZEDQA sc PASS D: the engine window went with the tab
ZEDQA sc shot D_folded
ZEDQA sc PASS D: a fold's close is not the player's: it comes back with the tab
ZEDQA sc PASS E: closed by the player and still shut 2 s later
ZEDQA sc ERR E: Loot and back: still shut (the player's close lasts)
ZEDQA sc shot E_shut
ZEDQA sc F engine row true
ZEDQA sc F ZeD's cells: DBG: ISVehicleMechanics.cheat=true | Remove engine at lift | Inspect engine components
ZEDQA sc PASS F: Inspect engine components
ZEDQA sc PASS F: no Take engine parts / Repair engine
ZEDQA sc PASS F: the option points at the anchor, no pad grab
ZEDQA sc shot F_menu
ZEDQA sc PASS F: picking it opens beside, anchored
ZEDQA sc PASS F: no horizontal overlap with the World window, the mod's gap (1419+500 vs 1929+1617)
ZEDQA sc PASS F: top level with the World window (10)
ZEDQA sc PASS F: on screen
ZEDQA sc PASS F: and stays 5 s
ZEDQA sc PASS G: the footer holds Inspect engine components
ZEDQA sc PASS G: and not Repair engine / Take engine parts
ZEDQA sc shot G_footer
ZEDQA sc PASS G: the footer verb opens it beside
ZEDQA sc PASS G: no horizontal overlap with the World window, the mod's gap (1419+500 vs 1929+1617)
ZEDQA sc PASS G: top level with the World window (10)
ZEDQA sc PASS G: on screen
ZEDQA sc PASS H: the hood shut closes the engine window
ZEDQA sc PASS H: the verb's line is the mod's sentence (The hood must be open to inspect engine components.)
ZEDQA sc shot H_hood_closed
ZEDQA sc PASS H: the hood open again: it opens again by itself
ZEDQA sc PASS I: one window, for the second car
ZEDQA sc I: engine window 1419,10 500x631 anchored=true vehicle=v2 | World window 2643,0 903x735
ZEDQA sc PASS J: rolled: the engine window closes
ZEDQA sc PASS J: unrolled: back by itself
ZEDQA sc PASS K: the World window closed: the engine window closes
ZEDQA sc PASS K: reopened on the Vehicle tab: back
ZEDQA sc L the World window to x=1111
ZEDQA sc L: engine window 2738,10 500x631 anchored=true vehicle=v2 | World window 1111,0 1617x735
ZEDQA sc PASS L: ZeD's window stays where it was put (1111)
ZEDQA sc PASS L: beside, or 420 wide at x 10 over the inventory side
ZEDQA sc shot L_tile
ZEDQA sc M outside wheel:
ZEDQA sc N lift staged ok=true
ZEDQA sc N ZeD's cells: DBG: ISVehicleMechanics.cheat=true | Remove engine at lift | Inspect engine components
ZEDQA sc shot N_lift_menu
ZEDQA sc O skipped: no pad (the sim proves the hand-back)
ZEDQA sc put back; Summer Car notes 0
ZEDQA sc DONE
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
