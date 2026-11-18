# ZeD-UI regression - 2026-11-17 18:41 - fullscreen4k (3840x2160 fullscreen)

| | |
|---|---|
| Started | 2026-11-17 18:41:59 |
| Finished | 2026-11-17 18:44:11 (2 min 12 s) |
| Mode | fullscreen4k (3840x2160 fullscreen) |
| Display | fontSize=2 fullScreen=false height=2160 width=3840 |
| Game build | 42.22.2 3d39148846 |
| Mod version | 0.3.0-beta19 |
| Save | Saves/Sandbox/ZeD-QA |
| Manifest | .\overhead_pins.txt (2 scripts) |
| Result | **1/2 pass**, 1 warn, 0 fail, 0 timeout |
| Go numbers | 28666 to 28669 |

Screenshots are in `%USERPROFILE%/Zomboid/Screenshots` (the next run overwrites them). PASS: reached DONE with no ERR line and no Lua error. WARN: DONE with ERR lines of its own, or the script ran twice. FAIL: ok=false, a Java exception in the script's window (with -debug the game logs one even for an error a script catches) or the game lost. TIMEOUT: no DONE in time (the run stops there). Not run: after a timeout, a paused game or a lost game. "(expect ...)" prints are shown, not checked.

## Run notes

- ZeD settings: UI scale 1.75x (4K), additions Vanilla Plus (all on, Restock Casual) (the director's ModOptions.ini kept aside)
- font size: fontSize=2 for the run (was fontSize=3)
- pzrestorewin.ps1 (before a fullscreen run): no backup
- started ProjectZomboid64.exe -debug -nosteam (fullscreen, the director's options.ini)
- loaded; clicked the screen centre (1920,1080) to pass 'click to start'
- the bridge armed in game on Saves/Sandbox/ZeD-QA
- quit: quit to the main menu, then to the desktop (go 28668, 28669)
- font size: the director's line put back (fontSize=3)
- ZeD settings: the director's ModOptions.ini put back

## Results

| # | Script | Tag | Status | Seconds | Screenshots | Notes |
|---:|---|---|---|---:|---|---|
| 1 | zedqa_prelude.lua | pre | PASS | 2 |  |  |
| 2 | zedqa_overhead_pins.lua | ohp | WARN | 41 |  | 67 ERR line(s) |

## Scripts

### 1. zedqa_prelude.lua (`ZEDQA pre`) - PASS, 2 s

- go 28666 at 18:43:03

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

### 2. zedqa_overhead_pins.lua (`ZEDQA ohp`) - WARN, 41 s

- go 28667 at 18:43:08
- 67 ERR line(s)

```text
[ZeD.QA] state #2 speed=1 paused=false player=925,13040 grid=19 inCar=false vehicles=32 missing=get
[ZeD.QA] windows reset (R)
ZEDQA ohp start
[ZeD.QA] run #2 ok=true
ZEDQA ohp start: at 925,13040, theme light, safe option 1, search mode false, speed 1
ZEDQA ohp PASS ZeD's pin override is loaded (ISBaseIcon._zedOrigRenderPinIcon)
ZEDQA ohp PASS ZeD's eye is loaded (renderEye replaced, ZeD.Bubbles.drawEye)
ZEDQA ohp PASS safe mode is off at the start
ZEDQA ohp type mush: Base.MushroomGeneric1
ZEDQA ohp type poison: Base.MushroomGeneric2
ZEDQA ohp type berry: Base.BeautyBerry
ZEDQA ohp type insect: Base.AmericanLadyCaterpillar
ZEDQA ohp world item: a pencil at 923,13041 dropped
ZEDQA ohp PASS search mode is on (ISSearchManager.getManager(player):toggleSearchMode(true))
ZEDQA ohp forage zone: BirchMixForest
ZEDQA ohp mushroom: Base.MushroomGeneric1 at 927,13038, identified true, the game's isKnownPoison false
ZEDQA ohp berries: Base.BeautyBerry at 927,13040, identified true, the game's isKnownPoison false
ZEDQA ohp insect: Base.AmericanLadyCaterpillar at 925,13038, identified true, the game's isKnownPoison false
ZEDQA ohp unknown: Base.MushroomGeneric1 at 924,13041, identified false, the game's isKnownPoison false
ZEDQA ohp poison: Base.MushroomGeneric2 at 926,13043, identified true, the game's isKnownPoison false
ZEDQA ohp poison: the game did not count it as known poison: marked known by hand
ZEDQA ohp world: the game made the pencil's pin itself (ISWorldItemIcon zombie.iso.IsoGridSquare@73e8b5d9-Base.Pencil)
ZEDQA ohp theme dark (now dark)
ZEDQA ohp picture ohp_dark_pins.png
ZEDQA ohp dark mushroom: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_MushroomGeneric1(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.71, zoom 1.00
ZEDQA ohp CROP ohp_dark_pins x=2155 y=1029 w=42 h=57 (mushroom)
ZEDQA ohp FAIL dark mushroom: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL dark mushroom: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL dark mushroom: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS dark mushroom: the find (Item_MushroomGeneric1) on the lens: center 14.5,13.0 (want 14.5,13.0), 16.0 x 13.5 (at most 16.0)
ZEDQA ohp PASS dark mushroom: no poison mark
ZEDQA ohp PASS dark mushroom: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp dark berries: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_BeautyBerries(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_dark_pins x=2027 y=1042 w=42 h=57 (berries)
ZEDQA ohp FAIL dark berries: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL dark berries: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL dark berries: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS dark berries: the find (Item_BeautyBerries) on the lens: center 14.5,13.0 (want 14.5,13.0), 14.0 x 16.0 (at most 16.0)
ZEDQA ohp PASS dark berries: no poison mark
ZEDQA ohp PASS dark berries: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp dark insect: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_Insect_AmericanLadyCaterpillar(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_dark_pins x=2027 y=961 w=42 h=57 (insect)
ZEDQA ohp FAIL dark insect: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL dark insect: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL dark insect: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS dark insect: the find (Item_Insect_AmericanLadyCaterpillar) on the lens: center 14.5,13.0 (want 14.5,13.0), 14.5 x 15.5 (at most 16.0)
ZEDQA ohp PASS dark insect: no poison mark
ZEDQA ohp PASS dark insect: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp dark unknown: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_unknown(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_dark_pins x=1771 y=1029 w=42 h=57 (unknown)
ZEDQA ohp FAIL dark unknown: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL dark unknown: the frosted lens with the ? alone (pinB_unknown)
ZEDQA ohp PASS dark unknown: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp dark poison: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_MushroomGeneric2(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\poison_mark(item) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_dark_pins x=1771 y=1157 w=42 h=57 (poison)
ZEDQA ohp FAIL dark poison: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL dark poison: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL dark poison: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS dark poison: the find (Item_MushroomGeneric2) on the lens: center 14.5,13.0 (want 14.5,13.0), 16.0 x 13.5 (at most 16.0)
ZEDQA ohp FAIL dark poison: the green skull mark, 12 units at (42, 36) (not drawn)
ZEDQA ohp PASS dark poison: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp dark world: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_Pencil(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.78, zoom 1.00
ZEDQA ohp CROP ohp_dark_pins x=1707 y=1003 w=42 h=57 (world)
ZEDQA ohp FAIL dark world: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL dark world: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL dark world: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS dark world: the find (Item_Pencil) on the lens: center 14.5,13.0 (want 14.5,13.0), 8.5 x 14.5 (at most 16.0)
ZEDQA ohp PASS dark world: no poison mark
ZEDQA ohp PASS dark world: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp dark trace (frame:y/alpha): 1:y1036/a0.71 6:y1025/a0.71 11:y1016/a0.71 16:y1011/a0.71 21:y1013/a0.71 26:y1020/a0.71 31:y1031/a0.71 36:y1036/a0.71 41:y1036/a0.71 46:y1036/a0.71 51:y1036/a0.71 56:y1036/a0.71 61:y1132/a0.71 66:y1132/a0.49 71:y1132/a0.49 76:y1132/a0.49 81:y1132/a0.49 86:y1132/a0.49 91:y1132/a0.49 96:y1132/a0.49 101:y1132/a0.49 106:y1132/a0.49 111:y1132/a0.49 116:y1132/a0.49 121:y1036/a0.71 126:y1036/a0.71
ZEDQA ohp PASS dark: the pin bounces when spotted (25 px over the first 45 frames) and settles
ZEDQA ohp PASS dark: the pin fades with distance (0.71 near, 0.49 three tiles further)
ZEDQA ohp picture ohp_dark_eye.png
ZEDQA ohp PASS dark eye: the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS dark eye: the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS dark eye: the eye keeps the game's fade (note 1.00, the game's 1.00)
ZEDQA ohp dark eye: the halo note is in the stack
ZEDQA ohp dark eye: #1 note 'QA halo note' units x=-40 y=-43 w=81 h=17 a=1.00 | screen x=1840 y=931 w=162 h=34 (k 2)
ZEDQA ohp CROP ohp_dark_eye x=1886 y=963 w=68 h=50 (the eye)
ZEDQA ohp dark eye: #2 eye units x=-13 y=-23 w=26 h=17 a=1.00 | screen x=1894 y=971 w=52 h=34 (k 2)
ZEDQA ohp CROP ohp_dark_eye x=1832 y=923 w=182 h=96 (the whole over-head stack)
ZEDQA ohp PASS dark eye: no two over-head notes overlap (2 notes)
ZEDQA ff speed 2: time multiplier 5, true multiplier 5
ZEDQA ohp picture ohp_dark_eye_speed2.png
ZEDQA ohp PASS dark eye at speed 2: the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS dark eye at speed 2: the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS dark eye at speed 2: the eye keeps the game's fade (note 1.00, the game's 1.00)
ZEDQA ohp PASS dark eye at speed 2: the eye sits just above the speed bubble (eye #2, speed #3)
ZEDQA ohp dark eye at speed 2: the halo note is in the stack
ZEDQA ohp dark eye at speed 2: #1 note 'QA halo note' units x=-40 y=-63 w=81 h=17 a=1.00 | screen x=1840 y=891 w=162 h=34 (k 2)
ZEDQA ohp CROP ohp_dark_eye_speed2 x=1886 y=923 w=68 h=50 (the eye)
ZEDQA ohp dark eye at speed 2: #2 eye units x=-13 y=-43 w=26 h=17 a=1.00 | screen x=1894 y=931 w=52 h=34 (k 2)
ZEDQA ohp dark eye at speed 2: #3 speed2 units x=-9 y=-23 w=19 h=17 a=1.00 | screen x=1902 y=971 w=38 h=34 (k 2)
ZEDQA ohp CROP ohp_dark_eye_speed2 x=1832 y=883 w=182 h=136 (the whole over-head stack)
ZEDQA ohp PASS dark eye at speed 2: no two over-head notes overlap (3 notes)
ZEDQA ohp picture ohp_dark_eye_033.png
ZEDQA ohp PASS dark eye at 0.33 (something in view): the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS dark eye at 0.33 (something in view): the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS dark eye at 0.33 (something in view): the eye keeps the game's fade (note 0.33, the game's 0.33)
ZEDQA ohp PASS dark eye at 0.33 (something in view): the eye sits just above the speed bubble (eye #1, speed #2)
ZEDQA ohp dark eye at 0.33 (something in view): the halo note is NOT in the stack
ZEDQA ohp CROP ohp_dark_eye_033 x=1886 y=923 w=68 h=50 (the eye)
ZEDQA ohp dark eye at 0.33 (something in view): #1 eye units x=-13 y=-43 w=26 h=17 a=0.33 | screen x=1894 y=931 w=52 h=34 (k 2)
ZEDQA ohp dark eye at 0.33 (something in view): #2 speed2 units x=-9 y=-23 w=19 h=17 a=1.00 | screen x=1902 y=971 w=38 h=34 (k 2)
ZEDQA ohp CROP ohp_dark_eye_033 x=1886 y=923 w=72 h=96 (the whole over-head stack)
ZEDQA ohp PASS dark eye at 0.33 (something in view): no two over-head notes overlap (2 notes)
ZEDQA ohp theme light (now light)
ZEDQA ohp picture ohp_light_pins.png
ZEDQA ohp light mushroom: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_MushroomGeneric1(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.71, zoom 1.00
ZEDQA ohp CROP ohp_light_pins x=2155 y=1029 w=42 h=57 (mushroom)
ZEDQA ohp FAIL light mushroom: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL light mushroom: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL light mushroom: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS light mushroom: the find (Item_MushroomGeneric1) on the lens: center 14.5,13.0 (want 14.5,13.0), 16.0 x 13.5 (at most 16.0)
ZEDQA ohp PASS light mushroom: no poison mark
ZEDQA ohp PASS light mushroom: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp light berries: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_BeautyBerries(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_light_pins x=2027 y=1042 w=42 h=57 (berries)
ZEDQA ohp FAIL light berries: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL light berries: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL light berries: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS light berries: the find (Item_BeautyBerries) on the lens: center 14.5,13.0 (want 14.5,13.0), 14.0 x 16.0 (at most 16.0)
ZEDQA ohp PASS light berries: no poison mark
ZEDQA ohp PASS light berries: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp light insect: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_Insect_AmericanLadyCaterpillar(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_light_pins x=2027 y=961 w=42 h=57 (insect)
ZEDQA ohp FAIL light insect: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL light insect: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL light insect: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS light insect: the find (Item_Insect_AmericanLadyCaterpillar) on the lens: center 14.5,13.0 (want 14.5,13.0), 14.5 x 15.5 (at most 16.0)
ZEDQA ohp PASS light insect: no poison mark
ZEDQA ohp PASS light insect: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp light unknown: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_unknown(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_light_pins x=1771 y=1029 w=42 h=57 (unknown)
ZEDQA ohp FAIL light unknown: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL light unknown: the frosted lens with the ? alone (pinB_unknown)
ZEDQA ohp PASS light unknown: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp light poison: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_MushroomGeneric2(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\poison_mark(item) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_light_pins x=1771 y=1157 w=42 h=57 (poison)
ZEDQA ohp FAIL light poison: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL light poison: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL light poison: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS light poison: the find (Item_MushroomGeneric2) on the lens: center 14.5,13.0 (want 14.5,13.0), 16.0 x 13.5 (at most 16.0)
ZEDQA ohp FAIL light poison: the green skull mark, 12 units at (42, 36) (not drawn)
ZEDQA ohp PASS light poison: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp light world: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_Pencil(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.78, zoom 1.00
ZEDQA ohp CROP ohp_light_pins x=1707 y=1003 w=42 h=57 (world)
ZEDQA ohp FAIL light world: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL light world: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL light world: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS light world: the find (Item_Pencil) on the lens: center 14.5,13.0 (want 14.5,13.0), 8.5 x 14.5 (at most 16.0)
ZEDQA ohp PASS light world: no poison mark
ZEDQA ohp PASS light world: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp light trace (frame:y/alpha): 1:y1036/a0.71 6:y1023/a0.71 11:y1014/a0.71 16:y1010/a0.71 21:y1013/a0.71 26:y1020/a0.71 31:y1033/a0.71 36:y1036/a0.71 41:y1036/a0.71 46:y1036/a0.71 51:y1036/a0.71 56:y1036/a0.71 61:y1132/a0.71 66:y1132/a0.49 71:y1132/a0.49 76:y1132/a0.49 81:y1132/a0.49 86:y1132/a0.49 91:y1132/a0.49 96:y1132/a0.49 101:y1132/a0.49 106:y1132/a0.49 111:y1132/a0.49 116:y1132/a0.49 121:y1036/a0.49 126:y1036/a0.71
ZEDQA ohp PASS light: the pin bounces when spotted (25 px over the first 45 frames) and settles
ZEDQA ohp PASS light: the pin fades with distance (0.71 near, 0.49 three tiles further)
ZEDQA ohp picture ohp_light_eye.png
ZEDQA ohp PASS light eye: the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS light eye: the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS light eye: the eye keeps the game's fade (note 1.00, the game's 1.00)
ZEDQA ohp light eye: the halo note is in the stack
ZEDQA ohp light eye: #1 note 'QA halo note' units x=-40 y=-43 w=81 h=17 a=1.00 | screen x=1840 y=931 w=162 h=34 (k 2)
ZEDQA ohp CROP ohp_light_eye x=1886 y=963 w=68 h=50 (the eye)
ZEDQA ohp light eye: #2 eye units x=-13 y=-23 w=26 h=17 a=1.00 | screen x=1894 y=971 w=52 h=34 (k 2)
ZEDQA ohp CROP ohp_light_eye x=1832 y=923 w=182 h=96 (the whole over-head stack)
ZEDQA ohp PASS light eye: no two over-head notes overlap (2 notes)
ZEDQA ohp picture ohp_light_eye_speed2.png
ZEDQA ohp PASS light eye at speed 2: the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS light eye at speed 2: the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS light eye at speed 2: the eye keeps the game's fade (note 1.00, the game's 1.00)
ZEDQA ohp PASS light eye at speed 2: the eye sits just above the speed bubble (eye #2, speed #3)
ZEDQA ohp light eye at speed 2: the halo note is in the stack
ZEDQA ohp light eye at speed 2: #1 note 'QA halo note' units x=-40 y=-63 w=81 h=17 a=1.00 | screen x=1840 y=891 w=162 h=34 (k 2)
ZEDQA ohp CROP ohp_light_eye_speed2 x=1886 y=923 w=68 h=50 (the eye)
ZEDQA ohp light eye at speed 2: #2 eye units x=-13 y=-43 w=26 h=17 a=1.00 | screen x=1894 y=931 w=52 h=34 (k 2)
ZEDQA ohp light eye at speed 2: #3 speed2 units x=-9 y=-23 w=19 h=17 a=1.00 | screen x=1902 y=971 w=38 h=34 (k 2)
ZEDQA ohp CROP ohp_light_eye_speed2 x=1832 y=883 w=182 h=136 (the whole over-head stack)
ZEDQA ohp PASS light eye at speed 2: no two over-head notes overlap (3 notes)
ZEDQA ohp picture ohp_light_eye_033.png
ZEDQA ohp PASS light eye at 0.33 (something in view): the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS light eye at 0.33 (something in view): the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS light eye at 0.33 (something in view): the eye keeps the game's fade (note 0.33, the game's 0.33)
ZEDQA ohp PASS light eye at 0.33 (something in view): the eye sits just above the speed bubble (eye #1, speed #2)
ZEDQA ohp light eye at 0.33 (something in view): the halo note is NOT in the stack
ZEDQA ohp CROP ohp_light_eye_033 x=1886 y=923 w=68 h=50 (the eye)
ZEDQA ohp light eye at 0.33 (something in view): #1 eye units x=-13 y=-43 w=26 h=17 a=0.33 | screen x=1894 y=931 w=52 h=34 (k 2)
ZEDQA ohp light eye at 0.33 (something in view): #2 speed2 units x=-9 y=-23 w=19 h=17 a=1.00 | screen x=1902 y=971 w=38 h=34 (k 2)
ZEDQA ohp CROP ohp_light_eye_033 x=1886 y=923 w=72 h=96 (the whole over-head stack)
ZEDQA ohp PASS light eye at 0.33 (something in view): no two over-head notes overlap (2 notes)
ZEDQA ohp theme hicon (now hicon)
ZEDQA ohp picture ohp_hicon_pins.png
ZEDQA ohp hicon mushroom: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_MushroomGeneric1(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.71, zoom 1.00
ZEDQA ohp CROP ohp_hicon_pins x=2155 y=1029 w=42 h=57 (mushroom)
ZEDQA ohp FAIL hicon mushroom: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL hicon mushroom: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL hicon mushroom: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS hicon mushroom: the find (Item_MushroomGeneric1) on the lens: center 14.5,13.0 (want 14.5,13.0), 16.0 x 13.5 (at most 16.0)
ZEDQA ohp PASS hicon mushroom: no poison mark
ZEDQA ohp PASS hicon mushroom: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp hicon berries: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_BeautyBerries(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_hicon_pins x=2027 y=1042 w=42 h=57 (berries)
ZEDQA ohp FAIL hicon berries: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL hicon berries: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL hicon berries: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS hicon berries: the find (Item_BeautyBerries) on the lens: center 14.5,13.0 (want 14.5,13.0), 14.0 x 16.0 (at most 16.0)
ZEDQA ohp PASS hicon berries: no poison mark
ZEDQA ohp PASS hicon berries: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp hicon insect: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_Insect_AmericanLadyCaterpillar(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_hicon_pins x=2027 y=961 w=42 h=57 (insect)
ZEDQA ohp FAIL hicon insect: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL hicon insect: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL hicon insect: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS hicon insect: the find (Item_Insect_AmericanLadyCaterpillar) on the lens: center 14.5,13.0 (want 14.5,13.0), 14.5 x 15.5 (at most 16.0)
ZEDQA ohp PASS hicon insect: no poison mark
ZEDQA ohp PASS hicon insect: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp hicon unknown: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_unknown(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_hicon_pins x=1771 y=1029 w=42 h=57 (unknown)
ZEDQA ohp FAIL hicon unknown: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL hicon unknown: the frosted lens with the ? alone (pinB_unknown)
ZEDQA ohp PASS hicon unknown: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp hicon poison: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_MushroomGeneric2(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\poison_mark(item) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_hicon_pins x=1771 y=1157 w=42 h=57 (poison)
ZEDQA ohp FAIL hicon poison: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL hicon poison: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL hicon poison: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS hicon poison: the find (Item_MushroomGeneric2) on the lens: center 14.5,13.0 (want 14.5,13.0), 16.0 x 13.5 (at most 16.0)
ZEDQA ohp FAIL hicon poison: the green skull mark, 12 units at (42, 36) (not drawn)
ZEDQA ohp PASS hicon poison: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp hicon world: %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_back(item) + Item_Pencil(item) + %USERPROFILE%\Zomboid\mods\ZeD-UI\42\media\textures\ZeD\forage\pinB_glass(item) | pin 30.0 x 45.0, s=0.500, alpha 0.78, zoom 1.00
ZEDQA ohp CROP ohp_hicon_pins x=1707 y=1003 w=42 h=57 (world)
ZEDQA ohp FAIL hicon world: the glass covers the pin exactly (the lens rim is redrawn over the find)
ZEDQA ohp FAIL hicon world: Design's pin, none of the game's pin textures (0 Design, 0 game)
ZEDQA ohp FAIL hicon world: pinB_back, the find, then pinB_glass over it
ZEDQA ohp PASS hicon world: the find (Item_Pencil) on the lens: center 14.5,13.0 (want 14.5,13.0), 8.5 x 14.5 (at most 16.0)
ZEDQA ohp PASS hicon world: no poison mark
ZEDQA ohp PASS hicon world: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp hicon trace (frame:y/alpha): 1:y1036/a0.71 6:y1023/a0.71 11:y1014/a0.71 16:y1010/a0.71 21:y1014/a0.71 26:y1022/a0.71 31:y1033/a0.71 36:y1036/a0.71 41:y1036/a0.71 46:y1036/a0.71 51:y1036/a0.71 56:y1036/a0.71 61:y1132/a0.71 66:y1132/a0.49 71:y1132/a0.49 76:y1132/a0.49 81:y1132/a0.49 86:y1132/a0.49 91:y1132/a0.49 96:y1132/a0.49 101:y1132/a0.49 106:y1132/a0.49 111:y1132/a0.49 116:y1132/a0.49 121:y1036/a0.49 126:y1036/a0.71
ZEDQA ohp PASS hicon: the pin bounces when spotted (25 px over the first 45 frames) and settles
ZEDQA ohp PASS hicon: the pin fades with distance (0.71 near, 0.49 three tiles further)
ZEDQA ohp picture ohp_hicon_eye.png
ZEDQA ohp PASS hicon eye: the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS hicon eye: the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS hicon eye: the eye keeps the game's fade (note 1.00, the game's 1.00)
ZEDQA ohp hicon eye: the halo note is in the stack
ZEDQA ohp hicon eye: #1 note 'QA halo note' units x=-40 y=-43 w=81 h=17 a=1.00 | screen x=1840 y=931 w=162 h=34 (k 2)
ZEDQA ohp CROP ohp_hicon_eye x=1886 y=963 w=68 h=50 (the eye)
ZEDQA ohp hicon eye: #2 eye units x=-13 y=-23 w=26 h=17 a=1.00 | screen x=1894 y=971 w=52 h=34 (k 2)
ZEDQA ohp CROP ohp_hicon_eye x=1832 y=923 w=182 h=96 (the whole over-head stack)
ZEDQA ohp PASS hicon eye: no two over-head notes overlap (2 notes)
ZEDQA ohp picture ohp_hicon_eye_speed2.png
ZEDQA ohp PASS hicon eye at speed 2: the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS hicon eye at speed 2: the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS hicon eye at speed 2: the eye keeps the game's fade (note 1.00, the game's 1.00)
ZEDQA ohp PASS hicon eye at speed 2: the eye sits just above the speed bubble (eye #2, speed #3)
ZEDQA ohp hicon eye at speed 2: the halo note is in the stack
ZEDQA ohp hicon eye at speed 2: #1 note 'QA halo note' units x=-40 y=-63 w=81 h=17 a=1.00 | screen x=1840 y=891 w=162 h=34 (k 2)
ZEDQA ohp CROP ohp_hicon_eye_speed2 x=1886 y=923 w=68 h=50 (the eye)
ZEDQA ohp hicon eye at speed 2: #2 eye units x=-13 y=-43 w=26 h=17 a=1.00 | screen x=1894 y=931 w=52 h=34 (k 2)
ZEDQA ohp hicon eye at speed 2: #3 speed2 units x=-9 y=-23 w=19 h=17 a=1.00 | screen x=1902 y=971 w=38 h=34 (k 2)
ZEDQA ohp CROP ohp_hicon_eye_speed2 x=1832 y=883 w=182 h=136 (the whole over-head stack)
ZEDQA ohp PASS hicon eye at speed 2: no two over-head notes overlap (3 notes)
ZEDQA ohp picture ohp_hicon_eye_033.png
ZEDQA ohp PASS hicon eye at 0.33 (something in view): the eye is a note in ZeD's over-head stack
ZEDQA ohp PASS hicon eye at 0.33 (something in view): the game's own eye drew nothing (0 draws by the manager)
ZEDQA ohp PASS hicon eye at 0.33 (something in view): the eye keeps the game's fade (note 0.33, the game's 0.33)
ZEDQA ohp PASS hicon eye at 0.33 (something in view): the eye sits just above the speed bubble (eye #1, speed #2)
ZEDQA ohp hicon eye at 0.33 (something in view): the halo note is NOT in the stack
ZEDQA ohp CROP ohp_hicon_eye_033 x=1886 y=923 w=68 h=50 (the eye)
ZEDQA ohp hicon eye at 0.33 (something in view): #1 eye units x=-13 y=-43 w=26 h=17 a=0.33 | screen x=1894 y=931 w=52 h=34 (k 2)
ZEDQA ohp hicon eye at 0.33 (something in view): #2 speed2 units x=-9 y=-23 w=19 h=17 a=1.00 | screen x=1902 y=971 w=38 h=34 (k 2)
ZEDQA ohp CROP ohp_hicon_eye_033 x=1886 y=923 w=72 h=96 (the whole over-head stack)
ZEDQA ohp PASS hicon eye at 0.33 (something in view): no two over-head notes overlap (2 notes)
ZEDQA ohp PASS the pins draw the same layers in dark and light
ZEDQA ohp PASS the pins draw the same layers in dark and hicon
ZEDQA ohp PASS safe mode is on
ZEDQA ohp picture ohp_light_safe_pins.png
ZEDQA ohp safe mushroom: E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank(item) + Item_MushroomGeneric1(item) | pin 30.0 x 45.0, s=0.500, alpha 0.71, zoom 1.00
ZEDQA ohp CROP ohp_light_safe_pins x=2155 y=1029 w=42 h=57 (mushroom)
ZEDQA ohp FAIL safe mushroom: the game's pin, none of Design's textures (0 Design, 0 game)
ZEDQA ohp FAIL safe mushroom: the game's pin (pinIconBlank) then the find, got E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank
ZEDQA ohp PASS safe mushroom: no poison skull
ZEDQA ohp PASS safe mushroom: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp safe berries: E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank(item) + Item_BeautyBerries(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_light_safe_pins x=2027 y=1042 w=42 h=57 (berries)
ZEDQA ohp FAIL safe berries: the game's pin, none of Design's textures (0 Design, 0 game)
ZEDQA ohp FAIL safe berries: the game's pin (pinIconBlank) then the find, got E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank
ZEDQA ohp PASS safe berries: no poison skull
ZEDQA ohp PASS safe berries: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp safe insect: E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank(item) + Item_Insect_AmericanLadyCaterpillar(item) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_light_safe_pins x=2027 y=961 w=42 h=57 (insect)
ZEDQA ohp FAIL safe insect: the game's pin, none of Design's textures (0 Design, 0 game)
ZEDQA ohp FAIL safe insect: the game's pin (pinIconBlank) then the find, got E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank
ZEDQA ohp PASS safe insect: no poison skull
ZEDQA ohp PASS safe insect: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp safe unknown: E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconUnknown(item) | pin 30.0 x 45.0, s=0.500, alpha 0.84, zoom 1.00
ZEDQA ohp CROP ohp_light_safe_pins x=1771 y=1029 w=42 h=57 (unknown)
ZEDQA ohp FAIL safe unknown: the game's pin, none of Design's textures (0 Design, 0 game)
ZEDQA ohp FAIL safe unknown: the game's ? pin (pinIconUnknown), got E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconUnknown
ZEDQA ohp PASS safe unknown: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp safe poison: E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank(item) + Item_MushroomGeneric2(item) + SkullPoison(game) | pin 30.0 x 45.0, s=0.500, alpha 0.75, zoom 1.00
ZEDQA ohp CROP ohp_light_safe_pins x=1771 y=1157 w=42 h=57 (poison)
ZEDQA ohp PASS safe poison: the game's pin, none of Design's textures (0 Design, 1 game)
ZEDQA ohp FAIL safe poison: the game's pin (pinIconBlank) then the find, got E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank
ZEDQA ohp PASS safe poison: the game's poison skull (SkullPoison)
ZEDQA ohp PASS safe poison: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp safe world: E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank(item) + Item_Pencil(item) | pin 30.0 x 45.0, s=0.500, alpha 0.78, zoom 1.00
ZEDQA ohp CROP ohp_light_safe_pins x=1707 y=1003 w=42 h=57 (world)
ZEDQA ohp FAIL safe world: the game's pin, none of Design's textures (0 Design, 0 game)
ZEDQA ohp FAIL safe world: the game's pin (pinIconBlank) then the find, got E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\textures\Foraging\pinIconBlank
ZEDQA ohp PASS safe world: no poison skull
ZEDQA ohp PASS safe world: every layer drawn at the pin's own alpha (the game's fade)
ZEDQA ohp PASS safe: the game's own eye (eyeconOn) is drawn again (16 draws)
ZEDQA ohp safe eye: E:\Project Zomboid\SteamApps\common\ProjectZomboid\media\ui\foraging\eyeconOn at x=1885 y=957 70x39 alpha 1.00
ZEDQA ohp CROP ohp_light_safe_pins x=1877 y=949 w=86 h=55 (the game's eye)
ZEDQA ohp PASS safe: ZeD's over-head layer is hidden, so its eye note is not drawn
ZEDQA ohp SIZE the find (mushroom): Design's lens 16.0 x 13.5, the game's pin 21.3 x 18.0
ZEDQA ohp SIZE the find (berries): Design's lens 14.0 x 16.0, the game's pin 18.7 x 21.3
ZEDQA ohp SIZE the find (insect): Design's lens 14.5 x 15.5, the game's pin 19.3 x 20.7
ZEDQA ohp SIZE the find (world): Design's lens 8.5 x 14.5, the game's pin 11.3 x 19.3
ZEDQA ohp SIZE the find (poison): Design's lens 16.0 x 13.5, the game's pin 21.3 x 18.0
ZEDQA ohp PASS mushroom: Design's pin is the game's pin size (Design 30.0 x 45.0, the game 30.0 x 45.0)
ZEDQA ohp PASS berries: Design's pin is the game's pin size (Design 30.0 x 45.0, the game 30.0 x 45.0)
ZEDQA ohp PASS insect: Design's pin is the game's pin size (Design 30.0 x 45.0, the game 30.0 x 45.0)
ZEDQA ohp PASS world: Design's pin is the game's pin size (Design 30.0 x 45.0, the game 30.0 x 45.0)
ZEDQA ohp PASS unknown: Design's pin is the game's pin size (Design 30.0 x 45.0, the game 30.0 x 45.0)
ZEDQA ohp PASS poison: Design's pin is the game's pin size (Design 30.0 x 45.0, the game 30.0 x 45.0)
ZEDQA ohp safe trace (frame:y/alpha): 1:y1036/a0.71 6:y1017/a0.71 11:y1010/a0.71 16:y1020/a0.71 21:y1036/a0.71 26:y1036/a0.71 31:y1036/a0.71 36:y1036/a0.71 41:y1036/a0.71 46:y1036/a0.71 51:y1036/a0.71 56:y1036/a0.71 61:y1132/a0.71 66:y1132/a0.49 71:y1132/a0.49 76:y1132/a0.49 81:y1132/a0.49 86:y1132/a0.49 91:y1132/a0.49 96:y1132/a0.49 101:y1132/a0.49 106:y1132/a0.49 111:y1132/a0.49 116:y1132/a0.49 121:y1036/a0.49 126:y1036/a0.71
ZEDQA ohp PASS safe: the pin bounces when spotted (25 px over the first 45 frames) and settles
ZEDQA ohp PASS safe: the pin fades with distance (0.71 near, 0.49 three tiles further)
ZEDQA ohp PASS safe mode put back as found (option 1)
ZEDQA ohp FAIL out of safe mode, Design's pins are back (0 of 6)
ZEDQA ohp FAIL put back: the pencil is gone from the floor
ZEDQA ohp PASS put back: search mode false
ZEDQA ohp PASS put back: speed 1
ZEDQA ohp PASS put back: safe mode option 1
ZEDQA ohp put back: theme light
ZEDQA ohp 67 failed
ZEDQA ohp DONE
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
