# ZeD-UI regression - 2026-10-26 21:30 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 21:30:36 |
| Finished | 2026-10-26 21:32:52 (2 min 15 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\compat_r3_H.txt (11 scripts) |
| Result | **0/11 pass**, 0 warn, 1 fail, 0 timeout, 10 not run |
| Go numbers | 13834 to 13834 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- stopped after zedqa_prelude.lua: the game closed during this script
- quit: the game was not running
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | **FAIL** | 1 |  | no DONE; the game closed during this script |
| 2 | zedqa_r3_H.lua | r3H | SKIP |  |  | not run: the game closed during this script |
| 3 | suite_tabs.lua | tabs | SKIP |  |  | not run: the game closed during this script |
| 4 | suite_verbs.lua | verbs | SKIP |  |  | not run: the game closed during this script |
| 5 | zedqa_ctxlist.lua | cl | SKIP |  |  | not run: the game closed during this script |
| 6 | zedqa_grid.lua | grid | SKIP |  |  | not run: the game closed during this script |
| 7 | zedqa_doll.lua | doll | SKIP |  |  | not run: the game closed during this script |
| 8 | zedqa_mapshot.lua | ms | SKIP |  |  | not run: the game closed during this script |
| 9 | zedqa_moodles.lua | mood | SKIP |  |  | not run: the game closed during this script |
| 10 | zedqa_charinfo.lua | ci | SKIP |  |  | not run: the game closed during this script |
| 11 | zedqa_messages.lua | msg | SKIP |  |  | not run: the game closed during this script |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - FAIL, 1 s

- go 13834 at 21:32:50
- no DONE
- the game closed during this script

### 2. zedqa_r3_H.lua (`ZEDQA r3H`) - SKIP, not run

- not run: the game closed during this script

### 3. suite_tabs.lua (`ZEDQA tabs`) - SKIP, not run

- not run: the game closed during this script

### 4. suite_verbs.lua (`ZEDQA verbs`) - SKIP, not run

- not run: the game closed during this script

### 5. zedqa_ctxlist.lua (`ZEDQA cl`) - SKIP, not run

- not run: the game closed during this script

### 6. zedqa_grid.lua (`ZEDQA grid`) - SKIP, not run

- not run: the game closed during this script

### 7. zedqa_doll.lua (`ZEDQA doll`) - SKIP, not run

- not run: the game closed during this script

### 8. zedqa_mapshot.lua (`ZEDQA ms`) - SKIP, not run

- not run: the game closed during this script

### 9. zedqa_moodles.lua (`ZEDQA mood`) - SKIP, not run

- not run: the game closed during this script

### 10. zedqa_charinfo.lua (`ZEDQA ci`) - SKIP, not run

- not run: the game closed during this script

### 11. zedqa_messages.lua (`ZEDQA msg`) - SKIP, not run

- not run: the game closed during this script

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
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefPropertyStrings> tiledef fileNumber 575 used by more than one mod
    1x ERROR: Mod f:N at ZomboidFileSystem.loadModTileDefs > tiledef fileNumber 575 used by more than one mod
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at GameWindow.uncaughtException > Unhandled java.lang.StackOverflowError thrown by thread MainThread.
    1x ERROR: General f:N> GameWindow.uncaughtException> Exception thrown  :: java.lang.StackOverflowError at ThreadLocal.get(null:-1). Message: Unhandled java.lang.StackOverflowError thrown by thread MainThread.
    1x ERROR: General f:N at MainThread.uncaughtException > Notifying InvokeOnMainQueue...
```
