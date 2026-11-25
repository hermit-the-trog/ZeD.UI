# Thermal tab: map for the gamut sweep (QA, Nov 24 2026)

A read-only map of ZeD's Thermal ("Temperature") tab against the game, written before the th_ sweep scripts. Line refs are as of 64fa2e606; the game's numbers come from javap of projectzomboid.jar (Thermoregulator, Moodles.Moodle, MoodleStat).
Short names: TT ThermalTab.lua, CW ZeD_CharacterWindow.lua, TF ZeD_TabFill.lua.

## 1. What the tab shows

**Where it lives:** tab "thermal", named with the game's word IGUI_XP_ClothingIns (CW:858). The game's toggleView(ClothingIns) is routed here (Overrides/CharacterInfo.lua:44). It uses the 480 card, or the 220 card on a small screen.

**Data:** gatherData (TT:158-213) runs every 15 frames; the cache is cleared on a tab switch (CW:1317, 4933). The unit is read every frame (TT:243). useCelsius (TT:87-95) reads getCore():getOptionDisplayAsCelsius(), then isCelsius(), then true. tempText (TT:100-107) prints %.1f, "37.0°C" or "98.6°F".

**Readings (TT:410-433).** All values are in the neutral tone.

| Row | Source | Shown as |
| --- | --- | --- |
| Core | thermoregulator:getCoreCelcius() (TT:170), clamped 20..42 by the game | tempText |
| Core meter | (core-30)/12 (TT:423) | 10 segments, at least 1 always lit; colour from getThermalColor (TT:144-152, cuts at fifths) |
| Air | getTemperatureAir() (TT:171) | tempText |
| Wind chill | getTemperatureAirAndWind() (TT:172) | tempText; a felt temperature |
| Body heat | getHeatGenerationUI (TT:202) | Low below 1/3, Normal, High above 2/3 (TF scaleWord 357-363) |

The meter's colour bands: cold below 32.4, cool below 34.8, normal below 37.2, warm below 39.6, hot from 39.6 on.

**View pop-up (TT:490-564).** Seven views (TT:43-51): Skin temperature, Body response, Blood vessels, Shiver / sweat, Insulation, Wind resistance, Wetness. Each reads its ...UI getter.

**Figure (TT:581-621).** 17 parts are tinted at 0.65 with the same 5-stop colours for every view; getThermalColor ignores its viewIdx. The part under the pointer or the pad focus shows white.

**Grid (TT:635-727).** "%1 by region" heads 2 x 17 cells. The skin view shows tempText of the raw skin temperature; every other view shows %.2f of the 0..1 UI value. Each cell has a 10-segment bar; a click or A picks the cell (_thermalPick, default Upper Torso).

**Picked block (TT:748-781).** It shows the hovered cell, else the hovered or focused part, else the pick. Eight rows (TT:56-73): the seven views plus clothing wetness. Each row has a value (tempText for skin, else a rounded %), a bar and the game's word, split at thirds. The wetness rows split at halves (Dry below 0.5, else Soaked).

**Themes (Tokens.lua 120-125, 205-210, 281-286):** Dark; Light (darker versions of the same colours); High contrast, which is identical to Dark.

**Lite:** no branch.

**Pad (CW:2991-3142):**
- Stops in order: thermal:__disclosure (A folds the figure); thermalpart:<name> (focus swaps the block; A does nothing); TabFill stops (cells, where A picks; the block head, where A folds; the 8 rows, read only); thermal:__gridscroll (dead, TT:359); the band box thermal:view (A opens the list, whose rows A picks and B shuts, then the focus returns to the box).
- ZeD.Popups shuts the list on an outside press, on hiding, on a queued action or on walking.

**Small screens:** figureFrame stacks on the 220 card (Molecules.lua:2004-2057). drawStatRow drops a value with no room (2105-2111). Grid labels are cut to fit, and dropped at room 0 (2224-2228). Picked rows keep 40 px for the label (TF:154).

## 2. Against the game

The game's tab is ISClothingInsPanel, inside the Character Info window. No key opens it: press a key for another tab, then click (2 steps); click a part for its details (3).
- **Core:** a gradient bar of getCoreTemperatureUI (piecewise: 20 to 0, 37 to 0.5, 42 to 1), with the words Cold, Normal and Hot. It shows a number only in debug.
- **Body heat:** a bar with Low, Normal and High.
- **Views:** Simple (skin, body response, insulation) and Advanced (skin, blood vessels, shiver, body wetness, clothing wetness, insulation, wind resistance).
- **Wetness colours:** the two wetness views use their own scheme, green when dry and blue when soaked.
- **Raw values:** insulation and wind resistance print their raw value (2 decimals).
- **Air:** shown only in debug, and on the HUD clock with a watch.

**ZeD shows, the game doesn't:** the core number, Air, Wind chill, the skin temperature per part, a number in each cell, and all 8 detail rows at once.

**The game shows, ZeD doesn't:**
- a clothing-wetness figure view;
- raw insulation and wind values;
- a Body heat bar;
- a core bar on the game's 20..42 scale.

## 3. The game's thresholds and what to sweep

| Core °C | Moodle | ZeD meter |
| --- | --- | --- |
| 37.0 | none | normal |
| 37.2-37.5 | none | warm |
| above 37.5 | Hyperthermia 1 | warm |
| above 39 | Hyperthermia 2 | warm, then hot at 39.6 |
| above 40 | Hyperthermia 3 | hot |
| above 41 | Hyperthermia 4 | hot |
| below 36.5 (intoxication 30 or less) | Hypothermia 1 | normal |
| below 35 (intoxication 70 or less) | Hypothermia 2 | cool, then cold below 34.8 |
| below 30 | Hypothermia 3 | 1 segment |
| below 25 | Hypothermia 4 | 1 segment |

Other states to sweep:
- **Skin:** the colours flip at 25.2, 30.4, 33.9 and 35.7 °C; the words read Cold below 28.7 and Hot above 34.5.
- **Wet:** the WET moodle fires at 15, 40, 70 and 90 (of 100). Sweep dry, damp (0.3-0.5, which ZeD calls Dry) and soaked; wet clothes on a dry body.
- **Wind:** WINDCHILL from getWindChillAmountForPlayer at 5, 10, 15 and 20; indoors Wind chill should equal Air.
- **Clothes:** naked, fully layered (do values cap at 100%?), one bare part.
- **Units:** C and F, toggled with the tab open; the oven's own isCelsius set opposite (Thermal must follow the display option).
- **Themes:** Dark, Light and High contrast.
- **Places:** indoors, outdoors, a car heater at -25, 0 and +25, next to a fire.
- **Exertion:** sprinting (High, Perspiring), sleeping (Low).
- **Layout:** the 220 and 480 cards at 1280x800 and 4K; Large text; a long-word language.
- **Pad:** walk every stop; the list shuts on walking; fold the figure with a part focused.

## 4. What the tests check already

| Script | What it checks |
| --- | --- |
| rt_windows (574-627) | the figure heading folds; the View list has 7 rows; a pick sets _thermalView and shuts the list; tempText follows the option |
| rt_media (1603-1663) | a cell click sets _thermalPick; bounds |
| rt_strain, hg_tint (Dark only) | no strain tint on the figure |
| rt_system | the soak cycles the tab |
| bx_health (1015-1040) | the core matches getCoreCelcius, which is the same call, so this check can't fail |

**Gaps:**
- No value is checked against the game: Air, Wind chill, Body heat, per-part numbers, % against the 0..1 value.
- No colour or word checked against the moodle levels.
- No clothes, wet, wind or car states.
- No Light or High contrast pass.
- No pad walk.
- No 220 layout.
- No Lite pass.
- No unit change while the tab is open.

FEATURE_MAP rows 191-198 have stale lines, and row 196 says the figure picks, which it doesn't.

## 5. Suspicions (to prove in the game)

- **T1:** the core meter's bands don't match the moodles. Hypothermia 1 shows green, 37.2-37.5 shows warm with no moodle, and Hypothermia 3 and 4 both pin at 1 segment.
- **T2:** wetness uses the temperature colours: dry reads blue (cold) and soaked reads red (hot).
- **T3:** the same reading shows in two units: a cell shows 0.xx and the picked row shows %. Neither matches the game's raw insulation and wind numbers.
- **T4:** the wetness word reads Dry up to 0.49, while the WET moodle fires from 15/100.
- **T5:** the skin scale is skewed in the game's own getSkinCelciusUI (the upper branch lacks x0.5), so Hot shows from 34.5 °C.
- **T6:** the comment at TT:85 says the oven reads the same unit; it reads isCelsius, a separate setting.
- **T7:** on the 220 card the grid cells may lose their names, and the picked rows may overflow (DE/RU).
- **T8:** a stale hover sticks after the figure is folded by the pad.
- **T9:** a part scrolled under the pinned header can still be hovered.
- **T10:** the figure can't pick a part (click or A), unlike the game's; FEATURE_MAP row 196 implies it can.
- **T11:** dead code: thermal:__gridscroll; _gpFocusedThermalPart is never read.
- **T12:** gatherData calls every detail getter twice (about 510 Java calls every 15 frames).
- **T13:** the bx_health core check can't fail.
- **T14:** gatherData doesn't guard a nil _playerObj (TT:159).
