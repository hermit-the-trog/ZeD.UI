# ZeD-UI regression - 2026-11-02 23:53 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-02 23:53:52 |
| Finished | 2026-11-02 23:55:57 (2 min 4 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fullScreen=true height=2160 width=3840 |
| Game build | 42.22.0 e013dbb529 |
| Mod version | 0.1.1242300k |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | ZeDUI/tools/qa/belt_fix_check.txt (4 scripts) |
| Result | **3/4 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 19350 to 19355 |

Screenshots are in `C:/Users/you/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 19354, 19355)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 1 |  |  |
| 2 | zedqa_all_simple.lua | asp | PASS | 1 |  |  |
| 3 | zedqa_hands_together.lua | ht | PASS | 18 | zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png |  |
| 4 | zedqa_simple_belt.lua | sbl | WARN | 13 | zqa_sbl_full_3840x2160.png, zqa_sbl_simple_3840x2160.png, zqa_sbl_simple_pistol_3840x2160.png, zqa_sbl_simple_watch_left_3840x2160.png, zqa_sbl_simple_watch_right_3840x2160.png, zqa_sbl_simple_moodles_bottom_3840x2160.png | 3 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 1 s

- go 19350 at 23:54:49

```text
[ZeD.QA] state #1 speed=1 paused=false player=927,13039 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA pre start
[ZeD.QA] run #1 ok=true
ZEDQA pre char true world true speed 1 ticks 60 frames 61
ZEDQA pre search overlay: enabled false, override false, manager false
ZEDQA pre DONE
```

### 2. zedqa_all_simple.lua (`ZEDQA asp`) - PASS, 1 s

- go 19351 at 23:54:53

```text
[ZeD.QA] state #2 speed=1 paused=false player=927,13039 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA asp beltStyleOption = 2
ZEDQA asp actionBarOption = 2
ZEDQA asp contextStyleOption = 2
ZEDQA asp equipViewOption = 1
ZEDQA asp devicesStyleOption = 2
ZEDQA asp watchStyleOption = 2
ZEDQA asp dashStyleOption = 2
[ZeD.QA] run #2 ok=true
ZEDQA asp DONE
```

### 3. zedqa_hands_together.lua (`ZEDQA ht`) - PASS, 18 s

- go 19352 at 23:54:58
- screenshots: zqa_ht_01_two.png, zqa_ht_02_both.png, zqa_ht_03_both_hicon.png, zqa_ht_04_both_large.png, zqa_ht_05_leftwatch_both.png, zqa_ht_06_rightwatch_pistol.png, zqa_ht_08_pistol_empty.png, zqa_ht_09_shotgun_both.png, zqa_ht_07_pad_peek.png

```text
[ZeD.QA] state #3 speed=1 paused=false player=927,13039 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ht start
[ZeD.QA] run #3 ok=true
ZEDQA ht 01 two items | OFF@0/77 MAIN@88/98 #1@204/77 #2@292/77 #3@380/77 | dark small | belt x1590 y2034 w457 h98
ZEDQA ht PASS 01 two items: both hands are on the belt
ZEDQA ht PASS 01 two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 01 two items: the off hand comes before the main hand
ZEDQA ht PASS 01 two items: the hands sit before the slots (the left end)
ZEDQA ht PASS 01 two items: the boxes run left to right
ZEDQA ht PASS 01 two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS 01 two items: a click at the off hand's right edge finds the off hand
ZEDQA ht 02 both hands | off(peek)@0/77 MAIN@25/98 #1@141/77 #2@229/77 #3@317/77 | dark small | belt x1653 y2034 w394 h98
ZEDQA ht PASS 02 both hands: both hands are on the belt
ZEDQA ht PASS 02 both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 02 both hands: the off hand comes before the main hand
ZEDQA ht PASS 02 both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 02 both hands: the boxes run left to right
ZEDQA ht PASS 02 both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 02 both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 02 both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 02 both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 02 both hands: slot 1 stays in place on screen (1794, was 1794)
ZEDQA ht 03 both, high contrast | off(peek)@0/77 MAIN@25/98 #1@141/77 #2@229/77 #3@317/77 | hicon small | belt x1653 y2034 w394 h98
ZEDQA ht PASS 03 both, high contrast: both hands are on the belt
ZEDQA ht PASS 03 both, high contrast: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 03 both, high contrast: the off hand comes before the main hand
ZEDQA ht PASS 03 both, high contrast: the hands sit before the slots (the left end)
ZEDQA ht PASS 03 both, high contrast: the boxes run left to right
ZEDQA ht PASS 03 both, high contrast: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 03 both, high contrast: the crescent's mark is 44 px wide
ZEDQA ht PASS 03 both, high contrast: a click at the crescent finds the off hand
ZEDQA ht PASS 03 both, high contrast: a click where the two overlap finds the main hand
ZEDQA ht 04 both, large | off(peek)@0/89 MAIN@28/113 #1@161/89 #2@262/89 #3@363/89 | dark large | belt x1614 y2015 w452 h113
ZEDQA ht PASS 04 both, large: both hands are on the belt
ZEDQA ht PASS 04 both, large: the main hand is 56 units, the off hand 44 (113, 89 px; 56u = 113)
ZEDQA ht PASS 04 both, large: the off hand comes before the main hand
ZEDQA ht PASS 04 both, large: the hands sit before the slots (the left end)
ZEDQA ht PASS 04 both, large: the boxes run left to right
ZEDQA ht PASS 04 both, large: the off hand peeks 14 units from under the main hand (28 px)
ZEDQA ht PASS 04 both, large: the crescent's mark is 50 px wide
ZEDQA ht PASS 04 both, large: a click at the crescent finds the off hand
ZEDQA ht PASS 04 both, large: a click where the two overlap finds the main hand
ZEDQA ht pad two items | OFF@0/77 MAIN@88/98 #1@204/77 #2@292/77 #3@380/77 | dark small | belt x1590 y2034 w457 h98
ZEDQA ht PASS pad two items: both hands are on the belt
ZEDQA ht PASS pad two items: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS pad two items: the off hand comes before the main hand
ZEDQA ht PASS pad two items: the hands sit before the slots (the left end)
ZEDQA ht PASS pad two items: the boxes run left to right
ZEDQA ht PASS pad two items: the hands are 6 units apart (11 px)
ZEDQA ht PASS pad two items: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS pad: the belt starts on slot 1 (#1)
ZEDQA ht PASS pad: Left from slot 1 is the main hand (MAIN)
ZEDQA ht PASS pad: Left again is the off hand (OFF)
ZEDQA ht 05 left wrist, both hands | watch@0/88 off(peek)@102/77 MAIN@127/98 #1@243/77 #2@331/77 #3@419/77 | dark small | belt x1551 y2034 w496 h98
ZEDQA ht PASS 05 left wrist, both hands: both hands are on the belt
ZEDQA ht PASS 05 left wrist, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 05 left wrist, both hands: the off hand comes before the main hand
ZEDQA ht PASS 05 left wrist, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 05 left wrist, both hands: the boxes run left to right
ZEDQA ht PASS 05 left wrist, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 05 left wrist, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 05 left wrist, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 05 left wrist, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 05 left wrist, both hands: slot 1 stays in place on screen (1794, was 1794)
ZEDQA ht PASS 05: the left-wrist watch sits beside the peeking off hand
ZEDQA ht 06 right wrist, pistol | OFF@0/77 MAIN@88/98 ammo@137/255 watch@406/88 #1@512/77 #2@600/77 #3@688/77 | dark small | belt x1282 y2034 w765 h98
ZEDQA ht PASS 06 right wrist, pistol: both hands are on the belt
ZEDQA ht PASS 06 right wrist, pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 06 right wrist, pistol: the off hand comes before the main hand
ZEDQA ht PASS 06 right wrist, pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 06 right wrist, pistol: the boxes run left to right
ZEDQA ht PASS 06 right wrist, pistol: the hands are 6 units apart (11 px)
ZEDQA ht PASS 06 right wrist, pistol: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS 06: the ammo tab comes after the main hand
ZEDQA ht PASS 06: the tab starts under the main hand's middle, its words at the circle's edge (x137 cx186)
ZEDQA ht PASS 06: no strap under the ammo tab
ZEDQA ht PASS 06: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 06: a click on the tab's words finds the tab
ZEDQA ht PASS 06: the right-wrist watch is outside the tab, before the strap
ZEDQA ht PASS 06: the full watch opens to the right of the small one (left)
ZEDQA ht 06 ammo 12/15 chambered true | 12+1
ZEDQA ht 08 empty pistol | OFF@0/77 MAIN@88/98 ammo@137/255 #1@410/77 #2@498/77 #3@586/77 | dark small | belt x1384 y2034 w663 h98
ZEDQA ht PASS 08 empty pistol: both hands are on the belt
ZEDQA ht PASS 08 empty pistol: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 08 empty pistol: the off hand comes before the main hand
ZEDQA ht PASS 08 empty pistol: the hands sit before the slots (the left end)
ZEDQA ht PASS 08 empty pistol: the boxes run left to right
ZEDQA ht PASS 08 empty pistol: the hands are 6 units apart (11 px)
ZEDQA ht PASS 08 empty pistol: a click at the off hand's right edge finds the off hand
ZEDQA ht PASS 08: the ammo tab comes after the main hand
ZEDQA ht PASS 08: the tab starts under the main hand's middle, its words at the circle's edge (x137 cx186)
ZEDQA ht PASS 08: no strap under the ammo tab
ZEDQA ht PASS 08: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 08: a click on the tab's words finds the tab
ZEDQA ht 09 shotgun, both hands | off(peek)@0/77 MAIN@25/98 ammo@74/255 #1@347/77 #2@435/77 #3@523/77 | dark small | belt x1447 y2034 w600 h98
ZEDQA ht PASS 09 shotgun, both hands: both hands are on the belt
ZEDQA ht PASS 09 shotgun, both hands: the main hand is 56 units, the off hand 44 (98, 77 px; 56u = 98)
ZEDQA ht PASS 09 shotgun, both hands: the off hand comes before the main hand
ZEDQA ht PASS 09 shotgun, both hands: the hands sit before the slots (the left end)
ZEDQA ht PASS 09 shotgun, both hands: the boxes run left to right
ZEDQA ht PASS 09 shotgun, both hands: the off hand peeks 14 units from under the main hand (25 px)
ZEDQA ht PASS 09 shotgun, both hands: the crescent's mark is 44 px wide
ZEDQA ht PASS 09 shotgun, both hands: a click at the crescent finds the off hand
ZEDQA ht PASS 09 shotgun, both hands: a click where the two overlap finds the main hand
ZEDQA ht PASS 09 shotgun, both hands: slot 1 stays in place on screen (1794, was 1794)
ZEDQA ht PASS 09: the ammo tab comes after the main hand
ZEDQA ht PASS 09: the tab starts under the main hand's middle, its words at the circle's edge (x74 cx123)
ZEDQA ht PASS 09: no strap under the ammo tab
ZEDQA ht PASS 09: a click on the circle over the tab finds the main hand
ZEDQA ht PASS 09: a click on the tab's words finds the tab
ZEDQA ht 07 off hand x1653 y2044 s77 peekW 44
ZEDQA ht all checks passed
ZEDQA ht DONE
```

### 4. zedqa_simple_belt.lua (`ZEDQA sbl`) - WARN, 13 s

- go 19353 at 23:55:19
- 3 ERR line(s)
- screenshots: zqa_sbl_full_3840x2160.png, zqa_sbl_simple_3840x2160.png, zqa_sbl_simple_pistol_3840x2160.png, zqa_sbl_simple_watch_left_3840x2160.png, zqa_sbl_simple_watch_right_3840x2160.png, zqa_sbl_simple_moodles_bottom_3840x2160.png

```text
[ZeD.QA] state #4 speed=1 paused=false player=927,13039 grid=19 inCar=false vehicles=43 missing=get
[ZeD.QA] windows reset (R)
ZEDQA sbl start
[ZeD.QA] run #4 ok=true
ZEDQA sbl Full: belt 1535,2034 662x98 | hands 2 | slots 3 (1@225 2@468 3@564) of 3 | ammo 0 | watch 0 | lamp 0 | strap true buckle true
ZEDQA sbl PASS Full: the strap and buckle are drawn
ZEDQA sbl Simple: belt 1590,2034 457x98 | hands 2 | slots 3 (1@204 2@292 3@380) of 3 | ammo 0 | watch 0 | lamp 0 | strap false buckle false
ZEDQA sbl PASS Simple is on (B.simple)
ZEDQA sbl PASS Simple: no strap, buckle, runs or closure
ZEDQA sbl PASS Simple: both hands (2)
ZEDQA sbl PASS Simple: a box for every slot (3 of 3)
ZEDQA sbl PASS Simple: the slots run in key order, left to right
ZEDQA sbl PASS Simple: slots 11 px apart (6 units): 11,11
ZEDQA sbl FAIL Simple: the belt is centred (1818 of 1920)
ZEDQA sbl FAIL Simple: the Messages lamp is there
ZEDQA sbl Simple, pistol in hand: belt 1384,2034 663x98 | hands 2 | slots 3 (1@410 2@498 3@586) of 3 | ammo 1 | watch 0 | lamp 0 | strap false buckle false
ZEDQA sbl PASS Simple: a pistol in hand shows the ammo tab
ZEDQA sbl Simple, watch left: belt 1488,2034 559x98 | hands 2 | slots 3 (1@306 2@394 3@482) of 3 | ammo 0 | watch 1 | lamp 0 | strap false buckle false
ZEDQA sbl PASS Simple: a watch on the left wrist shows on the belt (left)
ZEDQA sbl Simple, watch right: belt 1488,2034 559x98 | hands 2 | slots 3 (1@306 2@394 3@482) of 3 | ammo 0 | watch 1 | lamp 0 | strap false buckle false
ZEDQA sbl PASS Simple: a watch on the right wrist shows on the belt (right)
ZEDQA sbl knife onto slot 2
ZEDQA sbl PASS Simple: a knife goes onto a free slot (the drag's call)
ZEDQA sbl PASS Simple: slot 2 holds the knife
ZEDQA sbl Simple, knife on: belt 1590,2034 457x98 | hands 2 | slots 3 (1@204 2@292 3@380) of 3 | ammo 0 | watch 0 | lamp 0 | strap false buckle false
ZEDQA sbl PASS Simple: slot 2's key puts the knife in hand (Base.HuntingKnife:zombie.inventory.types.HandWeapon@60f6e793)
ZEDQA sbl PASS Simple: the knife comes off the slot (the drag out)
ZEDQA sbl moodles at Bottom: rect 1838,1965 164x48 | belt top 2034
ZEDQA sbl PASS Simple: the moodles at Bottom sit above the belt
ZEDQA sbl put back: belt 1590,2034 457x98 | hands 2 | slots 3 (1@204 2@292 3@380) of 3 | ammo 0 | watch 0 | lamp 0 | strap false buckle false
ZEDQA sbl summary: 15 PASS, 2 FAIL
ZEDQA sbl DONE
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
    2x ERROR: General f:N at LuaManager.getFunctionObject > no such function "Vehicles.Init.Radio"
```
