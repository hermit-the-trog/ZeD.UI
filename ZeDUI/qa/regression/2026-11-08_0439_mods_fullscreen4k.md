# ZeD-UI regression - 2026-11-08 04:39 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-08 04:39:44 |
| Finished | 2026-11-08 04:42:32 (2 min 48 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.21.0 4a0e9546ec |
| Mod version | 0.3.0-beta7 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\b8_seven_manifest.txt (6 scripts) |
| Result | **6/6 pass**, 0 warn, 0 fail, 0 timeout |
| Go numbers | 23825 to 23832 |

Screenshots are in `C:/Users/danie/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 23831, 23832)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 6 |  |  |
| 2 | zedqa_pin_windows.lua | pnw | PASS | 1 |  |  |
| 3 | zedqa_b8_seven_hud.lua | b8hud | PASS | 26 | zqa_b8hud_belt_meters.png, zqa_b8hud_belt_mask.png, zqa_b8hud_mask_menu.png, zqa_b8hud_belt_scba.png, zqa_b8hud_ahb_shown.png, zqa_b8hud_ahb_hidden.png, zqa_b8hud_ahb_windows_open.png |  |
| 4 | zedqa_b8_seven_menus.lua | b8menu | PASS | 15 | zqa_b8menu_bit_strip.png, zqa_b8menu_bit_list.png, zqa_b8menu_skills_tab.png, zqa_b8menu_folders_menu.png, zqa_b8menu_folders_inventory.png |  |
| 5 | zedqa_ctxlist.lua | cl | PASS | 5 | zqa_cl_1.png, zqa_cl_2.png |  |
| 6 | zedqa_ctx_bit.lua | cbt | PASS | 5 | zqa_cbt_style1.png, zqa_cbt_style2.png |  |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 6 s

- go 23825 at 04:40:53

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

- go 23826 at 04:41:03

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pnw pinned both windows
[ZeD.QA] run #2 ok=true
ZEDQA pnw DONE
```

### 3. zedqa_b8_seven_hud.lua (`ZEDQA b8hud`) - PASS, 26 s

- go 23827 at 04:41:07
- screenshots: zqa_b8hud_belt_meters.png, zqa_b8hud_belt_mask.png, zqa_b8hud_mask_menu.png, zqa_b8hud_belt_scba.png, zqa_b8hud_ahb_shown.png, zqa_b8hud_ahb_hidden.png, zqa_b8hud_ahb_windows_open.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8hud start
[ZeD.QA] run #3 ok=true
ZEDQA b8hud PASS all seven mods are on in this game
ZEDQA b8hud PASS each mod's ModSupport file answered
ZEDQA b8hud PASS ZeD's step-aside check has run (within ~10 s of the game's start)
ZEDQA b8hud PASS step aside found nothing to take over with the seven (a mod that only ADDS to a screen does not trip it)
ZEDQA b8hud PASS nothing was handed back (set= entries: 0)
ZEDQA b8hud PASS no ZeD screen switch is ticked ()
ZEDQA b8hud PASS no 'ZeD screens' notice in Messages (0)
ZEDQA b8hud PASS ZeD_step_aside.txt has no set= line
ZEDQA b8hud (expect no '[ZeD] Step aside: ... took' line in the console; a 'partial' line, if any, is the check being careful)
ZEDQA b8hud belt slots filled: 1 of 2 (knife, lighter)
ZEDQA b8hud PASS Item Condition Restored's tables are loaded
ZEDQA b8hud PASS the knife's strip is its condition (0.6, kind nil)
ZEDQA b8hud PASS the lighter's strip is its uses left (0.40625, kind nil)
ZEDQA b8hud PASS the pot's ring is its water, in the info color (0.5, kind fluid)
ZEDQA b8hud PASS the radio's ring is its charge (0.699999988079071, kind nil)
ZEDQA b8hud PASS style None: the knife's strip is ZeD's own condition (0.6)
ZEDQA b8hud PASS a one-color style: the knife's strip is flat, the theme's positive green (kind flat)
ZEDQA b8hud PASS the multicolor style: the graduated condition colors (kind nil)
ZEDQA b8hud PASS Mask Filter Indicator has a state for the worn gas mask
ZEDQA b8hud PASS the filter is fitted with some left (0.04100000113248825)
ZEDQA b8hud PASS two spare filters: the badge reads +2 (spares 2, badge +2)
ZEDQA b8hud hint: Gas Mask | 4% left | spares: 2
ZEDQA b8hud PASS the hint names the mask, its filter and the spares
ZEDQA b8hud PASS the mask's box is on the belt
ZEDQA b8hud PASS after the last slot
ZEDQA b8hud PASS before the Messages note
ZEDQA b8hud PASS a slot's size (77 vs 77)
ZEDQA b8hud PASS the mod's own strip is parked while the belt is in charge
ZEDQA b8hud the mod's menu from the box: Take off mask | Replace filter
ZEDQA b8hud PASS the mod's menu opens from the box (2 entries)
ZEDQA b8hud PASS the SCBA is a tank box (tank true, has true)
ZEDQA b8hud SCBA hint: SCBA | 94% left | No spare oxygen tank
ZEDQA b8hud PASS mask off: the box goes and the belt closes up
ZEDQA b8hud PASS Auto-Hide Hotbar's API is there
ZEDQA b8hud PASS the belt is attached through the mod's call
ZEDQA b8hud PASS the hover reveal is switched off for the hide check (put back after)
ZEDQA b8hud PASS revealed: the slots are shown (visibility 1)
ZEDQA b8hud PASS the belt hides after the delay (visibility under 0.1)
ZEDQA b8hud PASS the belt element itself is still there (only the slots fade)
ZEDQA b8hud PASS and comes back on reveal (visibility 0.9988159999999999)
ZEDQA b8hud PASS after the slide the belt sits exactly where it was (1535,2034 vs 1535,2034)
ZEDQA b8hud PASS hidden again before the windows check
ZEDQA b8hud PASS the inventory is open: the belt stays shown past the hide delay (visibility 1, keep true)
ZEDQA b8hud PASS windows shut: the belt hides again
ZEDQA b8hud all checks passed
ZEDQA b8hud DONE
```

### 4. zedqa_b8_seven_menus.lua (`ZEDQA b8menu`) - PASS, 15 s

- go 23828 at 04:41:36
- screenshots: zqa_b8menu_bit_strip.png, zqa_b8menu_bit_list.png, zqa_b8menu_skills_tab.png, zqa_b8menu_folders_menu.png, zqa_b8menu_folders_inventory.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA b8menu start
[ZeD.QA] run #4 ok=true
ZEDQA b8menu PASS Better Item Transfer's options were read at the game's start (primed true)
ZEDQA b8menu the mod's showIcons option reads true (ok true)
ZEDQA b8menu style strip: strip, 8 entries: Eat, Drop, Place, More, Save to loadout, Virtual folders, Move to, Rename
ZEDQA b8menu PASS the strip style: the right-click opens the icon strip (strip)
ZEDQA b8menu PASS with the mod's entries in it (8)
ZEDQA b8menu style list: list, 8 entries: Eat, Drop, Place, More, Save to loadout, Virtual folders, Move to, Rename
ZEDQA b8menu PASS the list style on the FIRST right-click after the switch (list)
ZEDQA b8menu PASS and the mod's entries are all in it (8)
ZEDQA b8menu PASS switched back: the next right-click is the strip (strip)
ZEDQA b8menu PASS Clear Skill Sheet's support answered
ZEDQA b8menu PASS Fitness learns at x1 with no boost (1)
ZEDQA b8menu PASS Fitness's tag reads 'XP x1' (XP x1)
ZEDQA b8menu Axe learns at x0.33 (the character's own traits)
ZEDQA b8menu PASS a boosted skill has a tag ('XP x0.33')
ZEDQA b8menu PASS the card holds the 'XP gain' line (XP gain: x0.33)
ZEDQA b8menu PASS a maxed skill has no XP gain line (0)
ZEDQA b8menu PASS the extra is registered on ZeD's Skills tab
ZEDQA b8menu boosted skills: Fitness boost 3 -> XP x1; Strength boost 3 -> XP x1
ZEDQA b8menu PASS Better Folders: the mod's state for the character is there
ZEDQA b8menu PASS a folder made through the mod's call (manual:1)
ZEDQA b8menu PASS the empty folder is listed in ZeD's groups (1 folders)
ZEDQA b8menu PASS and has a place in the order (rank 1)
ZEDQA b8menu PASS the axe is filed in the folder by type
ZEDQA b8menu PASS ZeD's group key for the axe is the folder's (vif:0:manual:1)
ZEDQA b8menu the axe's menu: Equip in Both Hands | Equip Primary | Equip Secondary | Attach | Research Craft | Craft | Drop | Place | More | Remove from folder | Move all items of this type to folder | Save to loadout | Virtual folders | Move to | Rename | Pin to title bar
ZEDQA b8menu PASS the item menu has 'Virtual folders'
ZEDQA b8menu PASS the rename shows at once (b8 Kit)
ZEDQA b8menu PASS 'remove from folder' puts the axe back under its category
ZEDQA b8menu PASS and the empty folder stays as an empty group row
ZEDQA b8menu PASS delete takes the folder away; nothing left the inventory (axe still carried: true)
ZEDQA b8menu PASS Better Mod Experience's support answered
ZEDQA b8menu PASS the mod's sorting table (BetterModExperience.Sorting.preview) is there
ZEDQA b8menu the mod's name as the game lists it: Better Mod Experience
ZEDQA b8menu PASS the mod's preview of the current list (8 mods) holds nothing back
ZEDQA b8menu (manual: Options > Mods folds, Load / Continue / New Game / Host notes and the Mods screen are main-menu screens)
ZEDQA b8menu PASS still no 'ZeD screens' notice after all of it
ZEDQA b8menu PASS and no ZeD screen switch ticked ()
ZEDQA b8menu all checks passed
ZEDQA b8menu DONE
```

### 5. zedqa_ctxlist.lua (`ZEDQA cl`) - PASS, 5 s

- go 23829 at 04:41:55
- screenshots: zqa_cl_1.png, zqa_cl_2.png

```text
[ZeD.QA] state #5 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
ZEDQA cl start
[ZeD.QA] run #5 ok=true
ZEDQA cl class ZeD_ContextList | rows: Eat, |, Place, Favorite, Set Unwanted, Virtual folders, Move to, |, Set to be Unusable in Recipes, |, Drop, |, Save to loadout, |, Rename
ZEDQA cl levels 2 | submenu: All, 1/2, 1/4
ZEDQA cl down: sub sel 2
ZEDQA cl B: levels 1
ZEDQA cl B again: open false
ZEDQA cl strip back: class ZeD_ContextMenu
ZEDQA cl DONE
```

### 6. zedqa_ctx_bit.lua (`ZEDQA cbt`) - PASS, 5 s

- go 23830 at 04:42:04
- screenshots: zqa_cbt_style1.png, zqa_cbt_style2.png

```text
[ZeD.QA] state #6 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=38 missing=get
[ZeD.QA] windows reset (R)
[ZeD.QA] run #6 ok=true
ZEDQA cbt style 1 (icon strip): the game's menu 8 options (numOptions 9) visible true: Eat, Drop, Place, More, Save to loadout, Virtual folders, Move to, Rename
ZEDQA cbt style 1 (icon strip): ZeD's menu ZeD_ContextMenu, tree nil, failed false, levels nil
ZEDQA cbt style 2 (list): the game's menu 8 options (numOptions 9) visible true: Eat, Drop, Place, More, Save to loadout, Virtual folders, Move to, Rename
ZEDQA cbt style 2 (list): ZeD's menu ZeD_ContextList, tree nil, failed false, levels 1
ZEDQA cbt style put back to 1
ZEDQA cbt DONE
```

## Console errors outside scripts

ERROR lines from launch to quit that fall in no script's window, once each (count first).

```text
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/mainfont2_0.png
    1x ERROR: General f:N at AngelCodeFont.parseFnt > AngelCodeFont failed to load page 0 texture E:/Project Zomboid/SteamApps/common/ProjectZomboid/media/fonts/zomboidDialogue.bmfc_0.png
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Large Bucket', name may not contain whitespaces.
    3x ERROR: General f:N at FluidContainerScript.load > Sanitizing container name 'Fuel Pump', name may not contain whitespaces.
    2x ERROR: General f:N> Lua(Vanilla).addModOptionsPanel> Exception thrown  :: java.util.UnknownFormatConversionException: Conversion = ')' at Formatter.parse(null:-1).
    2x ERROR: General f:N> Lua(Vanilla).addModOptionsPanel> Exception thrown  :: java.util.IllegalFormatConversionException: o != zombie.debug.LogSeverity at Formatter$FormatSpecifier.failConversion(null:-1).
   44x ERROR: General f:N> Lua(Vanilla).addModOptionsPanel> Exception thrown  :: java.util.UnknownFormatConversionException: Conversion = '"' at Formatter.parse(null:-1).
    1x ERROR: General f:N at CraftRecipeComponentScript.getIconTexture> CraftRecipeComponentScript: Recipe Piano missing UiConfigScript - falling back to SpriteConfigScript first world object face for recipe icon.
    1x ERROR: Lua f:N at Lua(Vanilla).handleMannequinZone > ERROR: Mannequin zone missing properties in media/maps/Muldraugh, KY/objects.lua coords: 13583, 1299, 0
    1x ERROR: General f:N at Basements.mergeRoomsOntoMetaCell > duplicate RoomDef.metaID for room at 10707,9484,0
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #231 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327914 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #327911 in cell 25,33 while reading map_meta.bin
    1x ERROR: General f:N at IsoMetaGrid.load > invalid room metaID #655594 in cell 25,33 while reading map_meta.bin
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
