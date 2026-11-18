# ZeD-UI regression - 2026-11-17 18:39 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 18:39:03 |
| Finished | 2026-11-17 18:41:01 (1 min 58 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\b8_takeshealth_manifest.txt (3 scripts) |
| Result | **3/3 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 28661 to 28665 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28664, 28665)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_b8_stepaside.lua | b8sa | PASS | 14 | zqa_b8sa_healthkey.png, zqa_b8sa_bubble.png, zqa_b8sa_messages.png, zqa_b8sa_takenback.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28661 at 18:40:15

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

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 28662 at 18:40:20

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_b8_stepaside.lua (`ZEDQA b8sa`) - PASS, 14 s

- go 28663 at 18:40:25
- screenshots: zqa_b8sa_healthkey.png, zqa_b8sa_bubble.png, zqa_b8sa_messages.png, zqa_b8sa_takenback.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8sa start
[ZeD.QA] run #3 ok=true
ZEDQA b8sa load order: ZeD last (ZeD_UI at 1, ZeD QA Takes Health (dev only) at 0)
ZEDQA b8sa PASS ZeD QA Takes Health (dev only) is on in this game
ZEDQA b8sa PASS ZeD QA Takes Health (dev only)'s Lua is loaded
ZEDQA b8sa PASS ZeD handed Character info back within ~10 s of the game's start (set=charinfo in the record)
ZEDQA b8sa PASS the record names Wounds Overhaul as the one that took Character info (ZeDQATakesHealth, ZeD QA Takes Health (dev only))
ZEDQA b8sa PASS exactly one screen handed back (1)
ZEDQA b8sa PASS ZeD setup's Character info switch is ticked (value 2)
ZEDQA b8sa PASS no other screen switch is ticked ()
ZEDQA b8sa PASS ZeD.Safe.on(charinfo) is true
ZEDQA b8sa PASS ZeD_step_aside.txt has set=charinfo|ZeDQATakesHealth (set=charinfo|ZeDQATakesHealth|ZeD QA Takes Health (dev only))
ZEDQA b8sa saved for the end: 3 file lines, switch 2
ZEDQA b8sa (expect [ZeD] Step aside: ZeD QA Takes Health (dev only) took charinfo; handed back to the game)
ZEDQA b8sa PASS one notice under 'ZeD screens' in Messages (1)
ZEDQA b8sa PASS the notice is unread
ZEDQA b8sa PASS the notice names the mod and 'character info'
ZEDQA b8sa notice text: ZeD QA Takes Health (dev only) has taken over a screen: character info. To turn ZeD's back on, go to ZeD setup and untick it under Safe mode.
ZEDQA b8sa PASS Messages counts unread notes (1)
ZEDQA b8sa PASS ZeD setup's line under the switch: 'Taken by ZeD QA Takes Health (dev only)'
ZEDQA b8sa (manual: ZeD setup is a main-menu screen; its 'Taken by' line is pictured by hand)
ZEDQA b8sa PASS the Health key is bound
ZEDQA b8sa PASS the game's Character Info window shows after the Health key
ZEDQA b8sa PASS the Health key opened the GAME's window, not ZeD's (game's window true, ZeD's open false, routed 0)
ZEDQA b8sa the game's window is on the page 'Health'
ZEDQA b8sa PASS a second Health key shuts the game's window
ZEDQA b8sa the first toast had gone: replayed for the picture
ZEDQA b8sa MW.open returned a window: true, really visible at once: false
ZEDQA b8sa PASS the Messages window opens on 'ZeD screens'
ZEDQA b8sa ticked off by the script (the player's untick)
[ZeD] Step aside: charinfo taken back from ZeDQATakesHealth by the player
ZEDQA b8sa PASS within ~13 s the record notes the take-back (kept=charinfo)
ZEDQA b8sa PASS kept=charinfo|ZeDQATakesHealth, no set (nil)
ZEDQA b8sa PASS ZeD_step_aside.txt has kept=charinfo|ZeDQATakesHealth (kept=charinfo|ZeDQATakesHealth)
ZEDQA b8sa PASS and no set=charinfo line
ZEDQA b8sa PASS 'Taken by' is gone from ZeD setup
ZEDQA b8sa PASS ZeD.Safe.on(charinfo) is false again
ZEDQA b8sa PASS the take-back adds no notice (1)
ZEDQA b8sa PASS the Health key opens ZeD's Character window again
ZEDQA b8sa PASS the Health key is ZeD's again (tab health, game's window false, routed 1)
ZEDQA b8sa PASS a second StepAside.check() leaves it with the player (switch 1, kept ZeDQATakesHealth)
ZEDQA b8sa PASS and says nothing more (1 notices)
ZEDQA b8sa PASS put back: switch 2, record set=ZeDQATakesHealth, kept=nil
ZEDQA b8sa PASS ZeD_step_aside.txt is as it was at the start
ZEDQA b8sa all checks passed (ZeD last)
ZEDQA b8sa DONE
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
