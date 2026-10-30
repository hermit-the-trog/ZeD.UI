# ZeD-UI regression - 2026-10-30 09:55 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-10-30 09:55:13 |
| Finished | 2026-10-30 09:56:58 (1 min 44 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | doll_v4_only.txt (2 scripts) |
| Result | **2/2 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 16415 to 16416 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- -KeepOpen: the game was left running
- -KeepOpen: ZeD settings are still the test's; the director's file is C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\qa\regression\2026-10-30_doll_split_fullscreen4k.md.modoptions.ini

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_doll_v4.lua | dollv4 | PASS | 29 | zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png, zqa_dollv4_3840x2160_short.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 16415 at 09:56:21

```text
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_doll_v4.lua (`ZEDQA dollv4`) - PASS, 29 s

- go 16416 at 09:56:26
- screenshots: zqa_dollv4_3840x2160_wide.png, zqa_dollv4_3840x2160_dpad.png, zqa_dollv4_3840x2160_wide_pads.png, zqa_dollv4_3840x2160_card.png, zqa_dollv4_3840x2160_narrow.png, zqa_dollv4_3840x2160_short.png

```text
[ZeD.QA] windows reset (R)
ZEDQA dollv4 start
[ZeD.QA] run #2 ok=true
ZEDQA dollv4 round 1: wearing 21 of 21
ZEDQA dollv4 PASS 38 small slots defined | 38
ZEDQA dollv4 PASS wide: bands show | drawer 840px = 480 units, screen 3840x2160
ZEDQA dollv4 PASS wide: 49 slot boxes (11 big + 38 small) | 49
ZEDQA dollv4 PASS wide: no slot overlaps another
ZEDQA dollv4 PASS wide: every box inside the drawer's width | 840
ZEDQA dollv4 PASS wide: the drawer is no wider than the full card (480 units) | 480.0 units
ZEDQA dollv4 PASS wide: a small slot is 14 units or more on screen | 14.3 units
ZEDQA dollv4 PASS wide: no leader lines | 0 lines
ZEDQA dollv4 PASS wide: Back at the top right above Belt, Arms on the left with Head | 588,85 267 588,386
ZEDQA dollv4 PASS every group name and place name has its words |
ZEDQA dollv4 PASS round 1 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 1 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 1 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 PASS belly button ring, air tank, tail in their small slots
ZEDQA dollv4 empties 25, slots with things 27
ZEDQA dollv4 PASS charTabContent zone exists with the doll's stops | 78
ZEDQA dollv4 PASS Left from Neck steps into the left band | doll:padsport
ZEDQA dollv4 PASS Right from the band's inner edge returns to a big slot | doll:neck
ZEDQA dollv4 PASS Right from Belt steps into the right band | doll:fpfront
ZEDQA dollv4 PASS Left from the right band's inner edge returns to a big slot | doll:belt
ZEDQA dollv4 PASS the doll's moves reach all 38 small slots | 38 missed
ZEDQA dollv4 PASS and all 11 big slots (Up / Down in a column are the cone's) | 11 missed
ZEDQA dollv4 PASS the outer edge of each band row leaves the doll (18 rows)
ZEDQA dollv4 dispatch Right from belt -> equipslot:doll:fpfront
ZEDQA dollv4 then Down -> equipslot:doll:ammo
ZEDQA dollv4 dispatch Left from the left band's outer edge -> tab:equip
ZEDQA dollv4 PASS the real Left at the outer edge does not land on another doll slot | tab:equip
ZEDQA dollv4 round 2: wearing 1 of 1
ZEDQA dollv4 PASS round 2 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS the sport pads worn on top show in their small slot
ZEDQA dollv4 PASS the air tank is gone from its slot
ZEDQA dollv4 PASS a second layer shows as a count (2) | 2
ZEDQA dollv4 PASS pad stop for the filled small slot
ZEDQA dollv4 PASS A opens the small slot's card (outermost first) | doll:padsport item Shoulderpads_FootballOnTop layer 1/2
ZEDQA dollv4 PASS its outermost layer is the pair worn on top | Shoulderpads_FootballOnTop
ZEDQA dollv4 PASS Inner steps to layer 2 | 2
ZEDQA dollv4 round 3: wearing 1 of 1
ZEDQA dollv4 PASS round 3 wide: every worn thing lands in its small slot (20 on) |
ZEDQA dollv4 PASS round 3 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 3 folded (data): every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 round 4: wearing 2 of 2
ZEDQA dollv4 PASS round 4 wide: every worn thing lands in its small slot (21 on) |
ZEDQA dollv4 PASS round 4 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 4 folded (data): every worn thing lands in its big slot (21 on) |
ZEDQA dollv4 round 5: wearing 1 of 1
ZEDQA dollv4 PASS round 5 wide: every worn thing lands in its small slot (20 on) |
ZEDQA dollv4 PASS round 5 wide: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS round 5 folded (data): every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS a cap dropped on Head is taken | rect 161,65 64x64 clip 0,65 815x585 | loc base:hat
ZEDQA dollv4 PASS a cap dropped on a small slot that is not its place is refused
ZEDQA dollv4 PASS a ring dropped on the wrong small slot is refused
ZEDQA dollv4 PASS a ring dropped on its slot is taken | rect 2,571 25x25 clip 0,65 815x585
ZEDQA dollv4 PASS the ring was put on (vanilla's wear action ran)
ZEDQA dollv4 PASS the cap was put on
ZEDQA dollv4 PASS narrow: bands folded | drawer 385px = 220 units, screen 3840x2160
ZEDQA dollv4 PASS narrow: 11 big slot boxes, no small ones | 11
ZEDQA dollv4 PASS narrow: no slot overlaps another
ZEDQA dollv4 PASS narrow: every box inside the drawer's width | 385
ZEDQA dollv4 PASS narrow: the drawer is no wider than the full card (480 units) | 220.0 units
ZEDQA dollv4 PASS narrow: no leader lines | 0 lines
ZEDQA dollv4 PASS narrow: Back, Arms, Belt in that order down the right | 65,247,338
ZEDQA dollv4 PASS narrow: every worn thing lands in its big slot (20 on) |
ZEDQA dollv4 PASS narrow: each has a card zone doll:<slot> |
ZEDQA dollv4 PASS narrow: no small-slot zone left | 0
ZEDQA dollv4 narrow: Arms layers 3, Back 2, Legs 5, Belt 4, Hands 4
ZEDQA dollv4 PASS narrow: Back's card shows the folded layers (tail, satchel) | layers 2
ZEDQA dollv4 short: window 735 -> 1126 px (view 585, doll at full size 1221)
ZEDQA dollv4 PASS short: the bands still show
ZEDQA dollv4 PASS short: the small slots shrank (under 18 units, 14 or more) | 16.0 units
ZEDQA dollv4 PASS short: the doll fits its view, no scrolling to reach it | 976 in 976
ZEDQA dollv4 PASS short: no slot overlaps another
ZEDQA dollv4 PASS short: 49 slot boxes | 49
ZEDQA dollv4 passed 62, failed 0 | DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    1x ERROR: Mod f:N at ChooseGameInfo.readModInfoAux > tiledef=SupportCorps 8900 file number must be from 100 to 8189
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    1x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
