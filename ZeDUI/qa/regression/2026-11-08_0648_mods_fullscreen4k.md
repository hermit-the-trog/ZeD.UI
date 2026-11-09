# ZeD-UI regression - 2026-11-08 06:49 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-08 06:49:26 |
| Finished | 2026-11-08 06:51:59 (2 min 32 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.3.0-beta7 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b8_wo_manifest.txt (4 scripts) |
| Result | **4/4 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 23882 to 23887 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 23886, 23887)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 5 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_b8_stepaside.lua | b8sa | PASS | 14 | zqa_b8sa_healthkey.png, zqa_b8sa_bubble.png, zqa_b8sa_messages.png, zqa_b8sa_takenback.png |  |
| 4 | zedqa_b8_wounds.lua | b8wo | PASS | 31 | zqa_b8wo_tab_before.png, zqa_b8wo_menu_unexamined.png, zqa_b8wo_tab_after.png, zqa_b8wo_menu_examined.png, zqa_b8wo_bandaged.png, zqa_b8wo_suture.png, zqa_b8wo_head_fracture.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 5 s

- go 23882 at 06:50:34

```text
[ZeD.QA] state #1 speed=1 paused=false player=928,13041 grid=19 inCar=false vehicles=27 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre moved from 928,13041,0 to the drag strip
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 299 frames 300
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 23883 at 06:50:42

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_b8_stepaside.lua (`ZEDQA b8sa`) - PASS, 14 s

- go 23884 at 06:50:47
- screenshots: zqa_b8sa_healthkey.png, zqa_b8sa_bubble.png, zqa_b8sa_messages.png, zqa_b8sa_takenback.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8sa start
[ZeD.QA] run #3 ok=true
ZEDQA b8sa load order: ZeD first (ZeD_UI at 0, Wounds Overhaul at 1)
ZEDQA b8sa PASS Wounds Overhaul is on in this game
ZEDQA b8sa PASS Wounds Overhaul's Lua is loaded
ZEDQA b8sa PASS ZeD handed Character info back within ~10 s of the game's start (set=charinfo in the record)
ZEDQA b8sa PASS the record names Wounds Overhaul as the one that took Character info (WoundsOverhaul, Wounds Overhaul [B42])
ZEDQA b8sa PASS exactly one screen handed back (1)
ZEDQA b8sa PASS ZeD setup's Character info switch is ticked (value 2)
ZEDQA b8sa PASS no other screen switch is ticked ()
ZEDQA b8sa PASS ZeD.Safe.on(charinfo) is true
ZEDQA b8sa PASS ZeD_step_aside.txt has set=charinfo|WoundsOverhaul (set=charinfo|WoundsOverhaul|Wounds Overhaul [B42])
ZEDQA b8sa saved for the end: 3 file lines, switch 2
ZEDQA b8sa (expect [ZeD] Step aside: Wounds Overhaul [B42] took charinfo; handed back to the game)
ZEDQA b8sa PASS one notice under 'ZeD screens' in Messages (1)
ZEDQA b8sa PASS the notice is unread
ZEDQA b8sa PASS the notice names the mod and 'character info'
ZEDQA b8sa notice text: Wounds Overhaul [B42] has taken over a screen: character info. To turn ZeD's back on, go to ZeD setup and untick it under Safe mode.
ZEDQA b8sa PASS Messages counts unread notes (1)
ZEDQA b8sa PASS ZeD setup's line under the switch: 'Taken by Wounds Overhaul [B42]'
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
ZEDQA b8sa PASS within ~13 s the record notes the take-back (kept=charinfo)
ZEDQA b8sa PASS kept=charinfo|WoundsOverhaul, no set (nil)
ZEDQA b8sa PASS ZeD_step_aside.txt has kept=charinfo|WoundsOverhaul (kept=charinfo|WoundsOverhaul)
ZEDQA b8sa PASS and no set=charinfo line
ZEDQA b8sa PASS 'Taken by' is gone from ZeD setup
ZEDQA b8sa PASS ZeD.Safe.on(charinfo) is false again
ZEDQA b8sa PASS the take-back adds no notice (1)
ZEDQA b8sa PASS the Health key opens ZeD's Character window again
ZEDQA b8sa PASS the Health key is ZeD's again (tab health, game's window false, routed 1)
ZEDQA b8sa PASS a second StepAside.check() leaves it with the player (switch 1, kept WoundsOverhaul)
ZEDQA b8sa PASS and says nothing more (1 notices)
ZEDQA b8sa PASS put back: switch 2, record set=WoundsOverhaul, kept=nil
ZEDQA b8sa PASS ZeD_step_aside.txt is as it was at the start
ZEDQA b8sa all checks passed (ZeD first)
ZEDQA b8sa DONE
```

### 4. zedqa_b8_wounds.lua (`ZEDQA b8wo`) - PASS, 31 s

- go 23885 at 06:51:04
- screenshots: zqa_b8wo_tab_before.png, zqa_b8wo_menu_unexamined.png, zqa_b8wo_tab_after.png, zqa_b8wo_menu_examined.png, zqa_b8wo_bandaged.png, zqa_b8wo_suture.png, zqa_b8wo_head_fracture.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8wo start
[ZeD.QA] run #4 ok=true
ZEDQA b8wo PASS god mode is off for the run
ZEDQA b8wo Wounds.examineMode() = 1 (strictest: the held-back checks run)
ZEDQA b8wo left forearm: held true | Something is wrong here.
ZEDQA b8wo right hand: held true | Something is wrong here.
ZEDQA b8wo neck: held false | Bleeding, Deep Wound (Severe)
ZEDQA b8wo PASS WO holds the forearm cut and the hand scratch back until examined
ZEDQA b8wo PASS the forearm row reads 'Something is wrong here.' and names no cut or bleeding
ZEDQA b8wo PASS the hand row reads the mod's line and does not say Scratch
ZEDQA b8wo PASS the neck's deep wound is named (the mod never holds the neck back)
ZEDQA b8wo the forearm's menu (ok true): Examine | Something is wrong here.
ZEDQA b8wo PASS the held-back forearm's menu has Examine
ZEDQA b8wo PASS and the mod's gray line
ZEDQA b8wo PASS and no treatment before the look
ZEDQA b8wo PASS Examine runs the mod's examination from the menu entry
ZEDQA b8wo PASS the examination is queued (queue 0 -> 1)
ZEDQA b8wo PASS a second Examine while it runs adds nothing (1)
ZEDQA b8wo PASS the examination finishes (the forearm is not held back any more; ~12 s at First Aid 0)
ZEDQA b8wo left forearm after the look: Bleeding, Laceration (Severe)
ZEDQA b8wo PASS 'Something is wrong here.' is gone from the forearm row and the wound is named
ZEDQA b8wo PASS the cut or its bleeding is named
ZEDQA b8wo the forearm's menu after the look: Bandage | Disinfect | Cheat | Press on the wound | Tie a tourniquet above it | Trim the wound edges | Wounds Overhaul
ZEDQA b8wo PASS the examined forearm opens a menu (7 entries)
ZEDQA b8wo PASS and it has no Examine
ZEDQA b8wo PASS and the game's Bandage is there (Bandage)
ZEDQA b8wo Bandage entry fields: id=number name=string subOption=number; notAvailable nil; subOption 1
ZEDQA b8wo Bandage picked from the menu: true
ZEDQA b8wo PASS the bandage goes on the forearm (~10 s)
ZEDQA b8wo the forearm's menu with a deep wound: Disinfect | Stitch | Cheat | Press on the wound | Tie a tourniquet above it | Trim the wound edges | Wounds Overhaul
ZEDQA b8wo PASS Stitch is in the menu on the examined deep wound (Stitch)
ZEDQA b8wo Stitch picked: true
ZEDQA b8wo PASS the mod's suture window opened over ZeD (constructor called 1x)
ZEDQA b8wo examining the head: true
ZEDQA b8wo PASS the head's examination finishes
ZEDQA b8wo bareAxialFracture(head) = true
ZEDQA b8wo PASS a skull fracture alone offers no menu (entries: Disinfect | Stitch | Cheat | Press on the wound | Tie a tourniquet above it | Trim the wound edges | Wounds Overhaul)
ZEDQA b8wo PASS the healed forearm leaves the injury list
ZEDQA b8wo forearm cut again: held true | Something is wrong here.
ZEDQA b8wo PASS cut again: held back again (the old look went with the old wound)
ZEDQA b8wo PASS and the menu offers Examine again
ZEDQA b8wo PASS god mode is back to true
ZEDQA b8wo all checks passed
ZEDQA b8wo DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
