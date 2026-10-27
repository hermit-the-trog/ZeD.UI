# ZeD-UI regression - 2026-10-26 10:54 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-26 10:54:19 |
| Finished | 2026-10-26 10:57:25 (3 min 5 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/tools/qa/hairbeard_manifest.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 13317 to 13320 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 13319, 13320)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_hairbeard.lua | hb | PASS | 53 | zqa_hb_no_tools.png, zqa_hb_greyed_hover.png, zqa_hb_ready.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_mod_rows.png, zqa_hb_pictures.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 13317 at 10:55:53

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_hairbeard.lua (`ZEDQA hb`) - PASS, 53 s

- go 13318 at 10:55:58
- screenshots: zqa_hb_no_tools.png, zqa_hb_greyed_hover.png, zqa_hb_ready.png, zqa_hb_cutting.png, zqa_hb_done.png, zqa_hb_tied.png, zqa_hb_pad_beard_greyed.png, zqa_hb_pad_beard.png, zqa_hb_out_of_reach.png, zqa_hb_trait_focus.png, zqa_hb_trait_hover.png, zqa_hb_large.png, zqa_hb_mod_rows.png, zqa_hb_pictures.png

```text
[ZeD.QA] windows reset (R)
ZEDQA hb start
[ZeD.QA] run #2 ok=true
ZEDQA hb tools taken away for the test: 0 | female false | was Grungey /
ZEDQA hb PASS the Character window is on Identity
ZEDQA hb PASS hair rows from the game's menu: 34
ZEDQA hb groups: tie 1 shave 1 cut 25 style 7
ZEDQA hb PASS Tie and Cut groups
ZEDQA hb PASS a cut with no scissors is greyed with the game's reason: Requires Scissors.
ZEDQA hb PASS tying needs no tool
ZEDQA hb PASS a style with no gel or spray is greyed: Requires Hair Spray.
ZEDQA hb PASS no debug rows
ZEDQA hb PASS Out of reach holds what the hair cannot become: 3
ZEDQA hb shot zqa_hb_no_tools.png
ZEDQA hb PASS the cut row has a click zone
ZEDQA hb PASS a click picks the row
ZEDQA hb PASS the strip's button is greyed for a greyed row
ZEDQA hb PASS pressing the greyed button does nothing
ZEDQA hb PASS the mouse is over a row (its hint shows)
ZEDQA hb shot zqa_hb_greyed_hover.png
ZEDQA hb PASS with scissors the cut can be done: Cut Hair into Short
ZEDQA hb head item: Baseball Cap
ZEDQA hb shot zqa_hb_ready.png
ZEDQA hb PASS the strip's button is live
ZEDQA hb PASS the cut is running
ZEDQA hb PASS the game's ISCutHair is queued
ZEDQA hb shot zqa_hb_cutting.png
ZEDQA hb PASS the cut ends
ZEDQA hb PASS the hair is now Short: Short
ZEDQA hb PASS the strip says done: Done: hair is now Short
ZEDQA hb PASS the cap came off first
ZEDQA hb PASS the license's Hair style line follows: Short
ZEDQA hb shot zqa_hb_done.png
ZEDQA hb PASS a tie row after growing it back
ZEDQA hb PASS the tie row is a controller stop
ZEDQA hb PASS the tie ends
ZEDQA hb PASS tied: the loose style is kept (Fabian)
ZEDQA hb PASS tied: Untie Hair is the only row (1)
ZEDQA hb shot zqa_hb_tied.png
ZEDQA hb PASS the untie ends
ZEDQA hb PASS untied: back to Fabian (Fabian)
ZEDQA hb PASS focus on the tab's disclosure
ZEDQA hb PASS down from the disclosure lands on the Hair | Beard switch (hb:part)
ZEDQA hb PASS right flips to Beard and stays on the switch
ZEDQA hb PASS down walks into the beard rows (hb:row:b:)
ZEDQA hb PASS the strip follows focus with no press
ZEDQA hb PASS greyed with the game's reason: Requires a Razor or Scissors.
ZEDQA hb PASS A on a greyed row does nothing
ZEDQA hb shot zqa_hb_pad_beard_greyed.png
ZEDQA hb PASS with scissors the trim can be done: Trim Beard into Mustache
ZEDQA hb shot zqa_hb_pad_beard.png
ZEDQA hb PASS the trim ends
ZEDQA hb PASS the beard is now Moustache: Moustache
ZEDQA hb PASS Out of reach is a stop
ZEDQA hb PASS A folds Out of reach open
ZEDQA hb PASS an out-of-reach row can be focused and says why
ZEDQA hb shot zqa_hb_out_of_reach.png
ZEDQA hb PASS a trait is a controller stop: identity:trait:Brave
ZEDQA hb PASS focus shows the description at once (no hover timer)
ZEDQA hb shot zqa_hb_trait_focus.png
ZEDQA hb PASS trait zones are kept for hover
ZEDQA hb PASS hover on a trait shows its description
ZEDQA hb shot zqa_hb_trait_hover.png
ZEDQA hb shot zqa_hb_large.png
ZEDQA hb Spongie's Hairstyle Unlocker on: false
ZEDQA hb PASS the picture mod's lists are read into rows (34 rows)
ZEDQA hb PASS Pictures is a controller stop
ZEDQA hb PASS no Traits tab without Traits As Skills
ZEDQA hb shot zqa_hb_mod_rows.png
ZEDQA hb PASS Pictures opens the mod's own window
ZEDQA hb shot zqa_hb_pictures.png
ZEDQA hb PASS its window closes
ZEDQA hb put back: Grungey / , 0 tools returned
ZEDQA hb all checks passed
ZEDQA hb DONE
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
```
