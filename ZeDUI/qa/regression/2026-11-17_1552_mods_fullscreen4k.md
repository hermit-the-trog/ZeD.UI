# ZeD-UI regression - 2026-11-17 15:53 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 15:53:02 |
| Finished | 2026-11-17 15:55:33 (2 min 30 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\b8_sa_only.txt (3 scripts) |
| Result | **2/3 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 28379 to 28383 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28382, 28383)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_b8_stepaside.lua | b8sa | WARN | 44 | zqa_b8sa_healthkey.png, zqa_b8sa_bubble.png, zqa_b8sa_messages.png, zqa_b8sa_takenback.png | 22 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28379 at 15:54:15

```text
[ZeD.QA] state #1 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
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

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 28380 at 15:54:20

```text
[ZeD.QA] state #2 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_b8_stepaside.lua (`ZEDQA b8sa`) - WARN, 44 s

- go 28381 at 15:54:25
- 22 ERR line(s)
- screenshots: zqa_b8sa_healthkey.png, zqa_b8sa_bubble.png, zqa_b8sa_messages.png, zqa_b8sa_takenback.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=926,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8sa start
[ZeD.QA] run #3 ok=true
ZEDQA b8sa load order: ? (ZeD_UI at 0, Wounds Overhaul at nil)
ZEDQA b8sa FAIL Wounds Overhaul is on in this game
ZEDQA b8sa FAIL Wounds Overhaul's Lua is loaded
ZEDQA b8sa FAIL timed out: ZeD handed Character info back within ~10 s of the game's start (set=charinfo in the record)
ZEDQA b8sa FAIL the record names Wounds Overhaul as the one that took Character info (nil, nil)
ZEDQA b8sa FAIL exactly one screen handed back (0)
ZEDQA b8sa FAIL ZeD setup's Character info switch is ticked (value 1)
ZEDQA b8sa PASS no other screen switch is ticked ()
ZEDQA b8sa FAIL ZeD.Safe.on(charinfo) is true
ZEDQA b8sa FAIL ZeD_step_aside.txt has set=charinfo|WoundsOverhaul (nil)
ZEDQA b8sa saved for the end: 2 file lines, switch 1
ZEDQA b8sa (expect [ZeD] Step aside: Wounds Overhaul [B42] took charinfo; handed back to the game)
ZEDQA b8sa FAIL one notice under 'ZeD screens' in Messages (0)
ZEDQA b8sa FAIL the notice is unread
ZEDQA b8sa FAIL the notice names the mod and 'character info'
ZEDQA b8sa notice text:
ZEDQA b8sa FAIL Messages counts unread notes (0)
ZEDQA b8sa FAIL ZeD setup's line under the switch: 'nil'
ZEDQA b8sa (manual: ZeD setup is a main-menu screen; its 'Taken by' line is pictured by hand)
ZEDQA b8sa PASS the Health key is bound
ZEDQA b8sa FAIL timed out: the game's Character Info window shows after the Health key
ZEDQA b8sa FAIL the Health key opened the GAME's window, not ZeD's (game's window false, ZeD's open true, routed 1)
ZEDQA b8sa the game's window is on the page 'Info'
ZEDQA b8sa PASS a second Health key shuts the game's window
ZEDQA b8sa the first toast had gone: replayed for the picture
ZEDQA b8sa MW.open returned a window: true, really visible at once: false
ZEDQA b8sa PASS the Messages window opens on 'ZeD screens'
ZEDQA b8sa ticked off by the script (the player's untick)
ZEDQA b8sa FAIL timed out: within ~13 s the record notes the take-back (kept=charinfo)
ZEDQA b8sa FAIL kept=charinfo|nil, no set (nil)
ZEDQA b8sa FAIL ZeD_step_aside.txt has kept=charinfo|WoundsOverhaul (nil)
ZEDQA b8sa PASS and no set=charinfo line
ZEDQA b8sa PASS 'Taken by' is gone from ZeD setup
ZEDQA b8sa PASS ZeD.Safe.on(charinfo) is false again
ZEDQA b8sa FAIL the take-back adds no notice (nil)
ZEDQA b8sa PASS the Health key opens ZeD's Character window again
ZEDQA b8sa PASS the Health key is ZeD's again (tab health, game's window false, routed 1)
ZEDQA b8sa FAIL a second StepAside.check() leaves it with the player (switch 1, kept nil)
ZEDQA b8sa FAIL and says nothing more (nil notices)
ZEDQA b8sa PASS put back: switch 1, record set=nil, kept=nil
ZEDQA b8sa FAIL ZeD_step_aside.txt is as it was at the start
ZEDQA b8sa 22 failed (?)
ZEDQA b8sa DONE
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
