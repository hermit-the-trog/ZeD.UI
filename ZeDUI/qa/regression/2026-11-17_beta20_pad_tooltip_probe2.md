# ZeD-UI regression - 2026-11-17 23:27 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 23:27:25 |
| Finished | 2026-11-17 23:29:32 (2 min 6 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\pad_tooltip.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 29186 to 29191 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29190, 29191)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | gallery_hidecon.lua | hcn | PASS | 1 |  |  |
| 4 | zedqa_pad_tooltip.lua | ptt | WARN | 23 | zqa_ptt_char_list.png, zqa_ptt_char_grid.png, zqa_ptt_world_list.png, zqa_ptt_world_grid.png, zqa_ptt_equip_rows.png, zqa_ptt_doll_boxes.png | 2 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29186 at 23:28:30

```text
[ZeD.QA] state #1 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre the Lua console was open: closed
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA layout pre default
ZEDQA pre layout char 1134,0 777x735 rolled false pinned true/true
ZEDQA pre layout world 1929,0 777x735 rolled false pinned true/true
ZEDQA pre ZeD version=0.3.0-beta20 dir=%USERPROFILE%\Zomboid\mods\ZeD-UI
ZEDQA pre tabs: Character loot | World loot
ZEDQA pre DONE
```

### 2. zedqa_pin_windows.lua (`ZEDQA pnw`) - PASS, 1 s

- go 29187 at 23:28:35

```text
[ZeD.QA] state #2 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. gallery_hidecon.lua (`ZEDQA hcn`) - PASS, 1 s

- go 29188 at 23:28:40

```text
[ZeD.QA] state #3 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA hcn the debug console kept hidden
[ZeD.QA] run #3 ok=true
ZEDQA hcn DONE
```

### 4. zedqa_pad_tooltip.lua (`ZEDQA ptt`) - WARN, 23 s

- go 29189 at 23:28:44
- 2 ERR line(s)
- screenshots: zqa_ptt_char_list.png, zqa_ptt_char_grid.png, zqa_ptt_world_list.png, zqa_ptt_world_grid.png, zqa_ptt_equip_rows.png, zqa_ptt_doll_boxes.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ptt start
[ZeD.QA] run #4 ok=true
ZEDQA ptt start at 926,13037; floor things 11; input lock was nil; pad bound false; Focus.PAD_TIP_MS 400
ZEDQA ptt char list: the pad on charMainInv, first stop invrow:1 (placed by Focus.focusWhere, which fires the stop's onFocus; every move after is a D-pad press through Focus.dispatchJoypadDir, ZeD's own pad path: cues, then the spatial move, the stop's onDpadDir and onFocus)
ZEDQA ptt char list move 1 (down) to invrow:2: card at frame 1 showing Bleach (landed on Bleach)
ZEDQA ptt char list move 2 (down) to invrow:3: card at frame 1 showing Book: "American Sports Compendium 1992", by Frederic Houle (landed on Book: "American Sports Compendium 1992", by Frederic Houle)
ZEDQA ptt char list move 3 (down) to invrow:4: card at frame 1 showing CD (landed on CD)
ZEDQA ptt char list move 4 (down) to invrow:5: card at frame 1 showing Chest Rig (landed on Chest Rig)
ZEDQA ptt char list move 5 (down) to invrow:6: card at frame 1 showing Cigarette (landed on Cigarette)
ZEDQA ptt shot zqa_ptt_char_list
ZEDQA ptt char list move 6 (down) to invrow:7: card at frame 1 showing Cigarette Pack (landed on Cigarette Pack)
ZEDQA ptt char list move 7 (down) to invrow:8: card at frame 1 showing Claw Hammer (landed on Claw Hammer)
ZEDQA ptt char list move 8 (down) to invrow:9: card at frame 1 showing Digital Watch (landed on Digital Watch)
ZEDQA ptt char list move 9 (down) to invrow:10: card at frame 1 showing Dish Towel (landed on Dish Towel)
ZEDQA ptt char list move 10 (down) to invrow:11: card at frame 1 showing Gas Can (landed on Gas Can)
ZEDQA ptt char list move 11 (down) to invrow:12: card at frame 1 showing Fanny Pack (landed on Fanny Pack)
ZEDQA ptt char list move 12 (down) to invrow:13: card at frame 1 showing Flier: Drag Racing Track: Fossoil (West Point) (landed on Flier: Drag Racing Track: Fossoil (West Point))
ZEDQA ptt PASS char list: the card on the landed item by frame 2 on every move, no item before, no flicker (12 moves)
ZEDQA ptt char grid: the pad on charMainInv, first stop invrow:1 (placed by Focus.focusWhere, which fires the stop's onFocus; every move after is a D-pad press through Focus.dispatchJoypadDir, ZeD's own pad path: cues, then the spatial move, the stop's onDpadDir and onFocus)
ZEDQA ptt char grid move 1 (right) to invrow:2: card at frame 1 showing Bleach (landed on Bleach)
ZEDQA ptt char grid move 2 (right) to invrow:3: card at frame 1 showing Book: "American Sports Compendium 1992", by Frederic Houle (landed on Book: "American Sports Compendium 1992", by Frederic Houle)
ZEDQA ptt char grid move 3 (right) to invrow:4: card at frame 1 showing CD (landed on CD)
ZEDQA ptt char grid move 4 (down) to invrow:10: card at frame 1 showing Dish Towel (landed on Dish Towel)
ZEDQA ptt char grid move 5 (left) to invrow:9: card at frame 1 showing Digital Watch (landed on Digital Watch)
ZEDQA ptt shot zqa_ptt_char_grid
ZEDQA ptt char grid move 6 (left) to invrow:8: card at frame 1 showing Claw Hammer (landed on Claw Hammer)
ZEDQA ptt char grid move 7 (left) to invrow:7: card at frame 1 showing Cigarette Pack (landed on Cigarette Pack)
ZEDQA ptt char grid move 8 (down) to invrow:13: card at frame 1 showing Flier: Drag Racing Track: Fossoil (West Point) (landed on Flier: Drag Racing Track: Fossoil (West Point))
ZEDQA ptt char grid move 9 (right) to invrow:14: card at frame 1 showing Holster (landed on Holster)
ZEDQA ptt char grid move 10 (right) to invrow:15: card at frame 1 showing Hunting Knife (landed on Hunting Knife)
ZEDQA ptt char grid move 11 (right) to invrow:16: card at frame 1 showing Hunting Vest - Khaki (landed on Hunting Vest - Khaki)
ZEDQA ptt char grid move 12 (down) to invrow:22: card at frame 1 showing Lighter (landed on Lighter)
ZEDQA ptt PASS char grid: the card on the landed item by frame 2 on every move, no item before, no flicker (12 moves)
ZEDQA ptt world list: the pad on worldMainInv, first stop invrow:1 (placed by Focus.focusWhere, which fires the stop's onFocus; every move after is a D-pad press through Focus.dispatchJoypadDir, ZeD's own pad path: cues, then the spatial move, the stop's onDpadDir and onFocus)
ZEDQA ptt world list move 1 (down) to invrow:2: card at frame 1 showing Banana (landed on Banana)
ZEDQA ptt world list move 2 (down) to invrow:3: card at frame 1 showing Bandage (landed on Bandage)
ZEDQA ptt world list move 3 (down) to invrow:4: card at frame 1 showing Battery (landed on Battery)
ZEDQA ptt world list move 4 (down) to invrow:5: card at frame 1 showing Eraser (landed on Eraser)
ZEDQA ptt world list move 5 (down) to invrow:6: card at frame 1 showing Fork (landed on Fork)
ZEDQA ptt shot zqa_ptt_world_list
ZEDQA ptt world list move 6 (down) to invrow:7: card at frame 1 showing Key Ring (landed on Key Ring)
ZEDQA ptt world list move 7 (down) to invrow:8: card at frame 1 showing Matchbook (landed on Matchbook)
ZEDQA ptt world list move 8 (down) to invrow:9: card at frame 1 showing Paperclip (landed on Paperclip)
ZEDQA ptt world list move 9 (down) to invrow:10: card at frame 1 showing Pen - Black (landed on Pen - Black)
ZEDQA ptt world list move 10 (down) to invrow:11: card at frame 1 showing Pencil (landed on Pencil)
ZEDQA ptt world list move 11 (down) to invrow:12: card at frame 1 showing Spoon (landed on Spoon)
ZEDQA ptt world list move 12 (down) to invrow:13: card at frame 1 showing Vehicle Key - Chevalier D6 (landed on Vehicle Key - Chevalier D6)
ZEDQA ptt PASS world list: the card on the landed item by frame 2 on every move, no item before, no flicker (12 moves)
ZEDQA ptt world grid: the pad on worldMainInv, first stop invrow:1 (placed by Focus.focusWhere, which fires the stop's onFocus; every move after is a D-pad press through Focus.dispatchJoypadDir, ZeD's own pad path: cues, then the spatial move, the stop's onDpadDir and onFocus)
ZEDQA ptt world grid move 1 (right) to invrow:2: card at frame 1 showing Banana (landed on Banana)
ZEDQA ptt world grid move 2 (right) to invrow:3: card at frame 1 showing Bandage (landed on Bandage)
ZEDQA ptt world grid move 3 (right) to invrow:4: card at frame 1 showing Battery (landed on Battery)
ZEDQA ptt world grid move 4 (down) to invrow:10: card at frame 1 showing Pen - Black (landed on Pen - Black)
ZEDQA ptt world grid move 5 (left) to invrow:9: card at frame 1 showing Paperclip (landed on Paperclip)
ZEDQA ptt shot zqa_ptt_world_grid
ZEDQA ptt world grid move 6 (left) to invrow:8: card at frame 1 showing Matchbook (landed on Matchbook)
ZEDQA ptt world grid move 7 (left) to invrow:7: card at frame 1 showing Key Ring (landed on Key Ring)
ZEDQA ptt world grid move 8 (down) to invrow:13: card at frame 1 showing Vehicle Key - Chevalier D6 (landed on Vehicle Key - Chevalier D6)
ZEDQA ptt world grid move 9: the focus left worldMainInv for worldTabBar; back to its first stop
ZEDQA ptt world grid move 9 (right) to invrow:1: card at frame 1 showing Apple (landed on Apple)
ZEDQA ptt world grid move 10 (right) to invrow:2: card at frame 1 showing Banana (landed on Banana)
ZEDQA ptt world grid move 11 (right) to invrow:3: card at frame 1 showing Bandage (landed on Bandage)
ZEDQA ptt world grid move 12 (down) to invrow:9: card at frame 1 showing Paperclip (landed on Paperclip)
ZEDQA ptt PASS world grid: the card on the landed item by frame 2 on every move, no item before, no flicker (12 moves)
ZEDQA ptt PROBE on for the equip rows run (ZeD.InvTip.want wrapped)
ZEDQA ptt PROBE draw on nil: el.item nothing | el.zone.item nothing | groupId nil | the request: item Paperclip, frame 1472, pad false, owner ZeD_Panel | IT._frame 1472 | _gpFocusedEquipSlot __disclosure
ZEDQA ptt PROBE el fields:
ZEDQA ptt PROBE draw on nil: el.item nothing | el.zone.item nothing | groupId nil | the request: item Paperclip, frame 1473, pad false, owner ZeD_Panel | IT._frame 1473 | _gpFocusedEquipSlot __disclosure
ZEDQA ptt PROBE el fields:
ZEDQA ptt PROBE draw on nil: el.item nothing | el.zone.item nothing | groupId nil | the request: item Paperclip, frame 1474, pad false, owner ZeD_Panel | IT._frame 1474 | _gpFocusedEquipSlot __disclosure
ZEDQA ptt PROBE el fields:
ZEDQA ptt equip rows: the pad on charTabContent, first stop equipslot:INR (placed by Focus.focusWhere, which fires the stop's onFocus; every move after is a D-pad press through Focus.dispatchJoypadDir, ZeD's own pad path: cues, then the spatial move, the stop's onDpadDir and onFocus)
ZEDQA ptt PROBE draw on equipgroup:arms: el.item nothing | el.zone.item nothing | groupId arms | the request: item Shirt - Lumberjack, frame 1512, pad false, owner ZeD_Panel | IT._frame 1513 | _gpFocusedEquipSlot __group_arms
ZEDQA ptt PROBE el fields: groupId=arms, h=45.96484375, id=equipgroup:arms, slotType=__group_arms, w=815, x=0, y=244.9296875
ZEDQA ptt equip rows move 1 (down) to equipgroup:arms: card at frame 1 showing Shirt - Lumberjack (an empty stop)
ZEDQA ptt equip rows move 2 (down) to equipslot:GLV: card at frame 1 showing Leather Gloves (landed on Leather Gloves)
ZEDQA ptt PROBE draw on equipgroup:legs: el.item nothing | el.zone.item nothing | groupId legs | the request: item Leather Gloves, frame 1518, pad false, owner ZeD_Panel | IT._frame 1519 | _gpFocusedEquipSlot __group_legs
ZEDQA ptt PROBE el fields: groupId=legs, h=45.96484375, id=equipgroup:legs, slotType=__group_legs, w=815, x=0, y=343.89453125
ZEDQA ptt equip rows move 3 (down) to equipgroup:legs: card at frame 1 showing Leather Gloves (an empty stop), SHOWED THE ITEM BEFORE
ZEDQA ptt equip rows move 4 (down) to equipslot:PNT: card at frame 1 showing Jeans (landed on Jeans)
ZEDQA ptt equip rows move 5 (down) to equipslot:SOC: card at frame 1 showing Socks - Heavy (landed on Socks - Heavy)
ZEDQA ptt shot zqa_ptt_equip_rows
ZEDQA ptt equip rows move 6 (down) to equipslot:BOT: card at frame 1 showing Military Boots (landed on Military Boots)
ZEDQA ptt PROBE draw on equipgroup:held: el.item nothing | el.zone.item nothing | groupId held | the request: item Military Boots, frame 1530, pad false, owner ZeD_Panel | IT._frame 1531 | _gpFocusedEquipSlot __group_held
ZEDQA ptt PROBE el fields: groupId=held, h=45.96484375, id=equipgroup:held, slotType=__group_held, w=815, x=0, y=548.859375
ZEDQA ptt equip rows move 7 (down) to equipgroup:held: card at frame 1 showing Military Boots (an empty stop), SHOWED THE ITEM BEFORE
ZEDQA ptt equip rows move 8 (down) to equipslot:PRI: card at frame 1 showing Lug Wrench (landed on Lug Wrench)
ZEDQA ptt equip rows move 9 (down) to equipslot:BLT: card at frame 1 showing Belt (landed on Belt)
ZEDQA ptt equip rows move 10 (down) to equipbelt:1: card at frame 1 showing JS-2000 Shotgun (an empty stop)
ZEDQA ptt PROBE draw on el:fold: el.item nothing | el.zone.item nothing | groupId nil | the request: item JS-2000 Shotgun, frame 1542, pad false, owner ZeD_Panel | IT._frame 1543 | _gpFocusedEquipSlot el:fold
ZEDQA ptt PROBE el fields: h=35, id=el:fold, slotType=el:fold, w=815, x=0, y=597.7890625
ZEDQA ptt equip rows move 11 (down) to el:fold: card at frame 1 showing JS-2000 Shotgun (an empty stop)
ZEDQA ptt equip rows move 12 (down) to equippart:Head: card at frame - showing nothing (an empty stop)
ZEDQA ptt FAIL equip rows: the card on the landed item by frame 2 on every move, no item before, no flicker (12 moves)
ZEDQA ptt PROBE stays on for the doll boxes
ZEDQA ptt doll boxes: the pad on charTabContent, first stop equipslot:doll:torso (placed by Focus.focusWhere, which fires the stop's onFocus; every move after is a D-pad press through Focus.dispatchJoypadDir, ZeD's own pad path: cues, then the spatial move, the stop's onDpadDir and onFocus)
ZEDQA ptt PROBE draw on equipslot:doll:outer: el.item nothing | el.zone.item nothing | groupId nil | the request: item Shirt - Lumberjack, frame 1613, pad false, owner ZeD_Panel | IT._frame 1614 | _gpFocusedEquipSlot doll:outer
ZEDQA ptt PROBE el fields: dpadExits=true, h=64, id=equipslot:doll:outer, slotType=doll:outer, w=64, x=267, y=90
ZEDQA ptt doll boxes move 1 (right) to equipslot:doll:outer: card at frame 1 showing Shirt - Lumberjack (an empty stop)
ZEDQA ptt doll boxes move 2 (down) to equipslot:doll:off: card at frame - showing nothing (an empty stop)
ZEDQA ptt doll boxes move 3 (right) to equipslot:doll:belt1: card at frame 1 showing JS-2000 Shotgun (landed on JS-2000 Shotgun)
ZEDQA ptt PROBE draw on el:fold: el.item nothing | el.zone.item nothing | groupId nil | the request: item JS-2000 Shotgun, frame 1622, pad false, owner ZeD_Panel | IT._frame 1623 | _gpFocusedEquipSlot el:fold
ZEDQA ptt PROBE el fields: h=35, id=el:fold, slotType=el:fold, w=815, x=0, y=531
ZEDQA ptt doll boxes move 4 (down) to el:fold: card at frame 1 showing JS-2000 Shotgun (an empty stop), SHOWED THE ITEM BEFORE
ZEDQA ptt doll boxes move 5: the focus left charTabContent for charMainInv; back to its first stop
ZEDQA ptt doll boxes move 5 (right) to equipslot:doll:torso: card at frame 1 showing Shirt - Lumberjack (landed on Shirt - Lumberjack)
ZEDQA ptt shot zqa_ptt_doll_boxes
ZEDQA ptt doll boxes move 6 (down) to equipslot:doll:hands: card at frame 1 showing Leather Gloves (landed on Leather Gloves)
ZEDQA ptt PROBE draw on equipslot:doll:outer: el.item nothing | el.zone.item nothing | groupId nil | the request: item Leather Gloves, frame 1631, pad false, owner ZeD_Panel | IT._frame 1632 | _gpFocusedEquipSlot doll:outer
ZEDQA ptt PROBE el fields: dpadExits=true, h=64, id=equipslot:doll:outer, slotType=doll:outer, w=64, x=267, y=90
ZEDQA ptt doll boxes move 7 (right) to equipslot:doll:outer: card at frame 1 showing Leather Gloves (an empty stop), SHOWED THE ITEM BEFORE
ZEDQA ptt doll boxes move 8 (down) to equipslot:doll:off: card at frame - showing nothing (an empty stop)
ZEDQA ptt doll boxes move 9 (right) to equipslot:doll:belt1: card at frame 1 showing JS-2000 Shotgun (landed on JS-2000 Shotgun)
ZEDQA ptt PROBE draw on el:fold: el.item nothing | el.zone.item nothing | groupId nil | the request: item JS-2000 Shotgun, frame 1640, pad false, owner ZeD_Panel | IT._frame 1641 | _gpFocusedEquipSlot el:fold
ZEDQA ptt PROBE el fields: h=35, id=el:fold, slotType=el:fold, w=815, x=0, y=531
ZEDQA ptt doll boxes move 10 (down) to el:fold: card at frame 1 showing JS-2000 Shotgun (an empty stop), SHOWED THE ITEM BEFORE
ZEDQA ptt doll boxes move 11: the focus left charTabContent for charMainInv; back to its first stop
ZEDQA ptt doll boxes move 11 (right) to equipslot:doll:torso: card at frame 1 showing Shirt - Lumberjack (landed on Shirt - Lumberjack)
ZEDQA ptt doll boxes move 12 (down) to equipslot:doll:hands: card at frame 1 showing Leather Gloves (landed on Leather Gloves)
ZEDQA ptt FAIL doll boxes: the card on the landed item by frame 2 on every move, no item before, no flicker (12 moves)
ZEDQA ptt PROBE off
ZEDQA ptt help: the pad on the tab strip's invrow:1
ZEDQA ptt not run: help balloon (none drawn on invrow:1 in 120 frames: that stop has no help words)
ZEDQA ptt not run: the pointer's card (Mouse.setXY did not hold: the pointer reads 1922,1081, wanted 1372,278)
ZEDQA ptt 2 failed, 4 passed
ZEDQA ptt put back: floor things gone, views and equipment view, tabs, focus, input lock nil, Balloon.draw, pointer
ZEDQA ptt DONE
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
