# ZeD-UI regression - 2026-11-17 23:29 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 23:29:33 |
| Finished | 2026-11-17 23:31:54 (2 min 21 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta20 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | %USERPROFILE%\Zomboid\mods\ZeD-UI\ZeDUI\tools\qa\forage_pointer.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 29192 to 29195 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 29194, 29195)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_forage_pointer.lua | fpt | WARN | 50 |  | 4 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 29192 at 23:30:37

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

### 2. zedqa_forage_pointer.lua (`ZEDQA fpt`) - WARN, 50 s

- go 29193 at 23:30:42
- 4 ERR line(s)

```text
[ZeD.QA] state #2 speed=1 paused=false player=926,13037 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA fpt start
[ZeD.QA] run #2 ok=true
ZEDQA fpt start: at 926,13037, 3840x2160, time 13.23, safe option 1, search mode false, speed 1
ZEDQA fpt PASS ZeD's pointer override is loaded (ForagePins.lua A2)
ZEDQA fpt PASS safe mode is off at the start
ZEDQA fpt PASS both hand pictures load
ZEDQA fpt PASS the load is under the limit (0.0 of 50.0 kg)
ZEDQA fpt type: Base.MushroomGeneric1
ZEDQA fpt PASS search mode is on
ZEDQA fpt forage zone: BirchMixForest
ZEDQA fpt one: Base.MushroomGeneric1 at 929,13036, the game's checkIsForageable error false (held true)
ZEDQA fpt one find at rest: no pointer
ZEDQA fpt FAIL one find: the pointer is up
ZEDQA fpt picture fpt_one_rest.png
ZEDQA fpt CROP fpt_one_rest x=2105 y=1000 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_one_rest x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt picture fpt_by_find.png
ZEDQA fpt CROP fpt_by_find x=2105 y=1000 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_by_find x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt walk step 0: the find left on screen (dx-dy -3.00), zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 249.4 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt picture fpt_walk_rest.png
ZEDQA fpt CROP fpt_walk_rest x=1618 y=870 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_walk_rest x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt walk step 1: the find left on screen (dx-dy -1.62), zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 225.8 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 2: the find left on screen (dx-dy -0.00), zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 180.0 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 2: the find is straight ahead (above) on screen
ZEDQA fpt mid-turn (step 3): zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 134.4 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true (a soft picture here is fine)
ZEDQA fpt picture fpt_mid_turn.png
ZEDQA fpt CROP fpt_mid_turn x=1914 y=841 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_mid_turn x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt walk step 3: the find right on screen (dx-dy 1.62), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 134.4 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 4: the find right on screen (dx-dy 3.00), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 110.6 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 5: the find right on screen (dx-dy 3.92), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 96.2 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 6: the find right on screen (dx-dy 4.24), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 84.9 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 7: the find right on screen (dx-dy 3.92), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 73.1 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 8: the find right on screen (dx-dy 3.00), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 58.0 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 9: the find right on screen (dx-dy 1.62), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 34.5 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 10: the find right on screen (dx-dy 0.00), zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 0.0 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 10: the find is straight behind (below) on screen
ZEDQA fpt walk step 11: the find left on screen (dx-dy -1.62), zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 325.3 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 12: the find left on screen (dx-dy -3.00), no pointer
ZEDQA fpt walk step 13: the find left on screen (dx-dy -3.92), zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 286.8 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 14: the find left on screen (dx-dy -4.24), zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 275.0 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk step 15: the find left on screen (dx-dy -3.92), zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 263.9 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt walk frames (597): no pointer x5 | zed_forage_hand_up_b x112 | zed_forage_hand_up_a x297 | zed_forage_hand_up_b x42 | no pointer x37 | zed_forage_hand_up_b x104
ZEDQA fpt PASS as the game's behaviour (the marker only while the find is seen): walk: the pointer stayed up at every step (1 without)
ZEDQA fpt PASS walk: at every step with a pointer the hand is the side's, so the thumb is on top (0 wrong)
ZEDQA fpt PASS walk: the hand flips once per side change, straight ahead and straight behind (2 flips, 2 side changes)
ZEDQA fpt facing step 0: facing W, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 250.0 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt picture fpt_facing_left.png
ZEDQA fpt CROP fpt_facing_left x=1621 y=873 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_facing_left x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt facing step 1: facing NW, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 225.3 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 2: facing NW, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 180.5 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 3: facing NW, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 134.2 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt picture fpt_facing_right.png
ZEDQA fpt CROP fpt_facing_right x=1913 y=842 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_facing_right x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt facing step 4: facing N, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 110.5 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 5: facing NE, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 96.2 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 6: facing NE, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 84.9 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 7: facing E, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 73.0 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 8: facing E, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 57.7 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 9: facing E, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 34.7 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 10: facing SE, the find right on screen, zed_forage_hand_up_a, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 0.0 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 11: facing SE, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 325.1 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 12: facing S, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 302.1 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 13: facing SW, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 286.9 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 14: facing SW, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 275.1 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing step 15: facing SW, the find left on screen, zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 263.8 (lerp 0.25, move 0.25), x 929 y 13036, active true, find in view true
ZEDQA fpt facing frames (549): no pointer x4 | zed_forage_hand_up_b x106 | zed_forage_hand_up_a x268 | zed_forage_hand_up_b x171
ZEDQA fpt PASS facing: every step's hand is the side's, thumb on top (0 wrong)
ZEDQA fpt PASS facing: the hand seen on both sides (left true, right true)
ZEDQA fpt PASS facing: the hand flips from one side to the other (2 flips, 2 side changes)
ZEDQA fpt PASS facing: a pointer at every step (0 without)
ZEDQA fpt two: Base.MushroomGeneric1 at 924,13039, the game's checkIsForageable error false (held true)
ZEDQA fpt three: Base.MushroomGeneric1 at 927,13040, the game's checkIsForageable error false (held true)
ZEDQA fpt four: Base.MushroomGeneric1 at 923,13035, the game's checkIsForageable error false (held true)
ZEDQA fpt several, find 1 (right): no pointer
ZEDQA fpt several, find 2 (left): zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 268.4 (lerp 0.25, move 0.25), x 924 y 13039, active true, find in view true
ZEDQA fpt PASS several, find 2: the hand for its side
ZEDQA fpt several, find 3 (left): zed_forage_hand_up_b, 44 x 77, rgba 1.00 1.00 1.00 1.00, angle 323.9 (lerp 0.25, move 0.25), x 927 y 13040, active true, find in view true
ZEDQA fpt PASS several, find 3: the hand for its side
ZEDQA fpt several, find 4 (left): no pointer
ZEDQA fpt PASS as the game's behaviour (the marker only while the find is seen): several: a pointer for each find (2 of 4)
ZEDQA fpt PASS several: more than one pointer at once (2)
ZEDQA fpt picture fpt_several.png
ZEDQA fpt night (23.01): no pointer
ZEDQA fpt night: no pointer (the game shows none for a find it cannot see in the dark; not ZeD's)
ZEDQA fpt picture fpt_night.png
ZEDQA fpt CROP fpt_night x=2105 y=1000 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_night x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt picture fpt_day.png
ZEDQA fpt day: no pointer
ZEDQA fpt PASS 13 tiles off: the pointer is gone
ZEDQA fpt picture fpt_out_of_range.png
ZEDQA fpt out of range and back frames (120): no pointer x120
ZEDQA fpt FAIL back in range: the pointer is up again
ZEDQA fpt PASS picked up: its pointer is gone
ZEDQA fpt picture fpt_picked_up.png
ZEDQA fpt PASS safe mode is on
ZEDQA fpt safe: no pointer
ZEDQA fpt FAIL safe: the game's own arrow (texture arrow_triangle, its own size, not ZeD's hand)
ZEDQA fpt picture fpt_safe.png
ZEDQA fpt CROP fpt_safe x=2102 y=1001 w=220 h=230 (the find, its pin and the hand by it)
ZEDQA fpt CROP fpt_safe x=1760 y=936 w=320 h=330 (the character and 130 px round it)
ZEDQA fpt PASS safe mode put back as found
ZEDQA fpt FAIL out of safe mode: the hand is back (no pointer)
ZEDQA fpt PASS put back: no pointer left (0)
ZEDQA fpt PASS put back: search mode false
ZEDQA fpt PASS put back: safe mode option 1
ZEDQA fpt put back: time 13.23 (was 13.23), speed 1
ZEDQA fpt 4 failed
ZEDQA fpt DONE
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
