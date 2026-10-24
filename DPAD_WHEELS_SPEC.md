# DPAD_WHEELS_SPEC: the controller's D-pad wheels

**Status:** APPROVED (director, Oct 23 2026: "this solves a lot of quick action problems. Love it!"). Design decisions are settled; this file is the handoff to Code.
**Mockup:** `ZeDUI/mockups/zed_dpad_wheels_v2.html` (point with the mouse, click to take or open, arrow keys switch wheels; the scene buttons show what is live in a car, by an animal, on a server). Built by `ZeDUI/mockups/zed_dpad_wheels_v1/build_dpad_wheels.py`. v1 is kept for the record.
**Look:** the approved wheel (`zed_wheels_v1.html`, Oct 15; `ZeD_Wheel.lua`): nothing new to draw.
**Relation to GAMEPAD_SPEC:** the wheels only open when **no window has focus** (in the world), as the game's D-pad wheels do. With a window focused the D-pad keeps moving focus; nothing in GAMEPAD_SPEC changes. Add a "D-pad wheels" section there pointing here, and update HOOK_MAP row 29.

## 1. What it is

Four wheels, one per D-pad direction, in place of the game's four D-pad wheels:

| D-pad | Wheel | Premise |
|---|---|---|
| Left | **Character** | You: the Character window's things, one flick from the world |
| Right | **World** | The world around you: the World window's things and what's in reach |
| Up | **Social** | Gestures, shout, and on a server the chat, safety and player list |
| Down | **Here and now** | Stance and movement, time and view, help, the light you carry |

They gather the quick actions that today are spread over the game's D-pad wheels, ZeD's quick-use slices on D-pad Right, the stick-click wheel (unreachable: ZeD never binds the stick clicks, Hard Rule #11) and the Back button's wheel.

## 2. How it works (settled)

1. **Open:** hold the D-pad direction (left thumb). The wheel appears at the centre of that player's screen (split screen: `getPlayerScreenLeft/Top/Width/Height`, as vanilla).
2. **Point with the right stick** (director: "RS to point. PS dpad is on the left, would be very difficult to do both with one hand."). `ZeD.Wheel.sliceFromJoypad` already reads the aiming axis (`getJoypadAimingAxisX/Y`), so this is today's behaviour. On open call `setJoypadIgnoreAimUntilCentered(true)`; while a wheel is open the right stick neither aims nor hides the windows.
3. **Take:** let go of the D-pad. The pointed slice runs (vanilla's `setHideWhenButtonReleased(Joypad.DPad*)` model). Nothing pointed: the wheel closes.
4. **Wheels inside:** letting go on a slice with the corner triangle swaps the ring in place to its wheel and **keeps it open**; there the right stick points, **A** takes, **B** backs out one level (from the top level, B closes). Back is the inner wheel's **last slice**, where vanilla's emote wheel puts it. The breadcrumb under the ring reads `CHARACTER › WEAPONS`. (ZeD_QuickWheel already refills the same wheel with items plus a Back slice; reuse that pattern.)
5. **Footer prompts:** top level `[dir] hold · RS point · let go of [dir]: take · B close`; inside `RS point · A take · B back`.
6. **Places never move.** Every top-level slice is always added, in the order below. One that can't be done right now is added **off** (stippled) and the bubble gives the reason with the red dot, e.g. "Nothing to drink on you.", "No vehicle in reach.", "On a server only.", "Not tired enough to sleep." Inside wheels, items that can't be used are off with vanilla's own reason where vanilla has one ("Canned Corn: needs a can opener.").
7. **Eight slices on every top level.** Slice 1 at 12 o'clock, clockwise, 360/8 each (the engine's geometry, ZeD_Wheel). The director looked at the 12-slice variant and kept 8.
8. **Things you carry** fill the inner wheel one slice per kind (full type), the best first, "x4" when there are more, as ZeD_QuickWheel does today: food spoiling soonest first (rotten last), water before drinks with a downside, weapons by condition. If a kind list passes 11 slices, show the best 11 (Back is the 12th); paging is out of scope for v1.
9. **Every pick runs the game's own action** (the context menu verbs, the timed actions), with its rules: items come out of bags first, masks come off, lighters are found.
10. **Paused game:** vanilla's Left and Down return while paused. Keep that for Left, Right and Up; **Down opens while paused** so Game speed, Play is reachable.
11. **Keyboard and mouse:** unchanged. These are the controller's wheels; V, Q, M, F, R keep their wheels.

## 3. The four wheels

Order is clockwise from 12 o'clock. ▸ = opens an inner wheel. "Live when" = otherwise added off with the reason shown.

### Left: Character

| # | Slice | Live when / reason | Inside, or what it does |
|---|---|---|---|
| 1 | Tabs ▸ | always | Loot, Equipment, Health, Thermal, ID, Journal, Skills, Radio: open the pair on that Character tab |
| 2 | Weapons ▸ | a weapon with condition > 0 ("No weapon on you.") | each weapon (vanilla `onDisplayLeft`'s list, ZeD_Belt.lua 530 has it), equip with `ISDPadWheels.onEquipPrimary`; last slice **Hands free** (unequip both). The light moves to Down. |
| 3 | Eat ▸ | something edible ("Nothing to eat on you.") | ZeD_QuickWheel's Eat list |
| 4 | Drink ▸ | something drinkable ("Nothing to drink on you.") | ZeD_QuickWheel's Drink list |
| 5 | Medicine and first aid ▸ | pills or a wound to treat ("Nothing to treat, no medicine on you.") | pills (QuickWheel's Take pills list), then one slice per treatment the game offers for your wounds (bandage the left hand, disinfect, splint, remove glass...; vanilla's health panel actions), last **Health tab** |
| 6 | Sleep | vanilla's sleep rules ("Not tired enough to sleep.", the vehicle wheel already has this slice) | vanilla's sleep, from where you stand / sit |
| 7 | Clothing ▸ | something worn with an option | the clothing extra options (hood up / down, open / close and the like: `getClothingItemExtraOption`, `ISClothingExtraAction`), take off headwear, mask, glasses; last **Equipment tab** |
| 8 | Use ▸ | always (its inner slices go off) | **Smoke ▸** (QuickWheel's list; off without a flame), **Read ▸** (QuickWheel's list; off when too dark), **Watch ▸** (open the full watch, Light, Alarm, Stopwatch: ZeD.Watch; off with no watch worn), **Radio ▸** (a carried radio: on / off, channel, Radio tab; off with none) |

### Right: World

| # | Slice | Live when / reason | Inside, or what it does |
|---|---|---|---|
| 1 | Tabs ▸ | always | Loot, Crafting, Building, Furniture, Maps, Foraging, Animals, Radio, Vehicle: open the pair on that World tab |
| 2 | Map ▸ | always | World map (`ISWorldMap.ToggleWorldMap`, which already lands on the Maps tab), Mini-map show / hide (`ISMiniMap.ToggleMiniMap`), Mini-map centre on you (`ISMiniMap.FocusMiniMap`) |
| 3 | Vehicle ▸ | in or next to a vehicle ("No vehicle in reach.") | vanilla's vehicle wheel slices, as they are (`ISVehicleMenu.showRadialMenu` fills it: inside, seat / engine / lights / heater / horn / radio / mechanics / exit; outside, enter / gas / doors / trunk / mechanics). Settled: a World slice, not a separate wheel while seated. In the driver's seat ZeD adds **Dashboard** after the game's slices (vanilla's word, `IGUI_VehiclePartCatdashboard`; second line "The D-pad on its controls. B lets go."): the pad goes to the dash's controls until B (director, Oct 24 2026: the dash no longer takes the D-pad when you sit down, so the wheels open at once). |
| 4 | Animal ▸ | a tame animal in reach ("No tame animal in reach.") | vanilla's animal wheel slices (`AnimalContextMenu.showRadialMenu`) |
| 5 | Craft and build ▸ | always | Crafting (at the nearest station, named: "Workbench, 2 tiles"), Building, Move furniture: open the World tab |
| 6 | Search ▸ | always | Search mode on / off (the Back wheel's ForageMode command), Investigate area (Foraging tab), Pick up (a found item, when there is one) |
| 7 | Lights and power ▸ | a switch in reach ("No lights or power in reach.") | the room's lights, a generator, a campfire: each on / off with vanilla's action; off with the reason when not in reach |
| 8 | Zones and rooms ▸ | always | Designated zones (`ISDPadWheels.showAnimalZoneUI`, routed to Animals already), Rooms editor (`showBuildingRoomsEditor`, where vanilla offers it) |

### Up: Social

| # | Slice | Live when / reason | Inside, or what it does |
|---|---|---|---|
| 1 | Friendly ▸ | always | vanilla's emote group (`ISEmoteRadialMenu.defaultMenu`) |
| 2 | Hostile ▸ | always | same |
| 3 | Group ▸ | always | same |
| 4 | Signal ▸ | always | same |
| 5 | Shout | always | `ISDPadWheels.onShout` |
| 6 | Chat | on a server ("On a server only.") | focus the chat box to type |
| 7 | Safety | on a server where it applies ("On a server only.") | toggle the safety against other players (vanilla's safety toggle) |
| 8 | Players | on a server ("On a server only.") | vanilla's player list |

Emote pictures stay vanilla's (they are the gestures).

### Down: Here and now

| # | Slice | Live when / reason | Inside, or what it does |
|---|---|---|---|
| 1 | Sit ▸ | not in a vehicle ("In a vehicle.") | Sit on the ground (the stick-click wheel's Toggle Sit), Sit on the nearest seat, named ("Sit on: Office Chair", vanilla's sit-on-furniture action), Lie down (a bed in reach; "No bed in reach.") |
| 2 | Crouch | not in a vehicle | toggle crouch (the stick-click wheel's Toggle Crouch) |
| 3 | Auto-walk | not in a vehicle | toggle auto-walk (the stick-click wheel's Toggle Auto-Walk) |
| 4 | Game speed ▸ | single player ("On a server the server sets the time.") | Pause / Play, Fast forward, Wait (the Back wheel's Pause and FastForward commands) |
| 5 | Zoom ▸ | always | Zoom in, Zoom out, with the next level in the line under the name (the Back wheel's Zoom command, `getCore():getNextZoom`) |
| 6 | View ▸ | always | Hide the interface (until pressed again), Reset windows (`ZeD_Window.resetLayout`, the footer's R), Text size (ZeD's Small / Large option), Options (on ZeD setup) |
| 7 | Help ▸ | always | Survival guide (`ISDPadWheels.showSurvGuide`), Controller map (see section 6) |
| 8 | Light | a light you carry ("No light on you.") | the brightest light you carry, on / off: vanilla `onDisplayLeft`'s best-light rule (an equipped or attached one first), `ISDPadWheels.onToggleLight`. Settled (director: "light toggle"). |

### Select: ZeD (director, Oct 23 2026: "Can select become the zed manager, like theme, accent, text size, reset")

The Select (Back) button's wheel becomes ZeD's own wheel. Hold Select, point with the right stick, let go to take, as the D-pad wheels do. Everything the game's Select wheel offered is on the D-pad wheels already (Player info: Character, Tabs; Crafting, Building, Move furniture: World, Craft and build; Search mode, Pick up, Investigate: World, Search; Zoom, Game speed: Here and now). The Last Stand mode's button moves to Here and now, added only in Last Stand. It opens while paused, as the game's Select wheel does.

Nine slices (director chose Safe mode as the ninth):

| # | Slice | Inside, or what it does |
|---|---|---|
| 1 | Theme ▸ | Dark, Light, High contrast; the current one marked |
| 2 | Accent ▸ | the nine accent colors, each slice its swatch; the current one marked |
| 3 | Text size ▸ | Small, Large |
| 4 | UI scale ▸ | Auto and the scale steps |
| 5 | Moodles ▸ | Right edge, Left edge, Bottom |
| 6 | Action bar ▸ | the action bar's styles |
| 7 | Reset windows | `ZeD_Window.resetLayout` (the footer's R) |
| 8 | ZeD setup | Options on the ZeD setup page |
| 9 | Safe mode | behind a ZeD prompt that says what it does and how to turn it off again (Options, ZeD setup, Safe mode); while it is on, Select is the game's wheel again |

Here and now's View keeps Reset windows and Text size too (director: keep both places).

## 4. What replaces what (hooks)

| Today | Becomes |
|---|---|
| `ISDPadWheels.onDisplayLeft` (weapons, best light); ZeD wraps it in `Overrides/Belt.lua` 177 to show the belt's lists | **Character**. Retire the Belt wrap of D-pad Left; Weapons covers the belt's weapons. Keep the belt's own lists reachable where else they open (hotbar keys). |
| `ISDPadWheels.onDisplayRight` (map, mini-map, zones, rooms editor, survival guide); ZeD_QuickWheel wraps it to add Eat, Drink, Smoke, Take pills, Read, Treat wounds | **World**. Retire QuickWheel's wrap of D-pad Right; keep its item pickers and its Back pattern and call them from Character. |
| `ISDPadWheels.onDisplayUp` (vehicle, else animal) | **Social**. Vehicle and Animal move to World 3 and 4. |
| `ISDPadWheels.onDisplayDown` (emotes) | **Here and now**. Emotes move to Social. |
| Stick-click wheel (Toggle Crouch, Sit, Auto-Walk) | Down 1 to 3 (still never bound to a stick click) |
| Back button wheel | **the ZeD wheel** (the Select section above, Oct 23 2026). Its game speed and zoom are on Down; crafting, building, furniture and search are on World; Player info is Character, Tabs; Last Stand moves to Down. |

Wrap the four `onDisplay*` functions in one new file (`ZeD_DpadWheels.lua`, HOOK_MAP row 29) with the guard-flag pattern the overrides use (`ISDPadWheels._zedDpad`). Fill the shared `getPlayerRadialMenu(playerIndex)` (ZeD_Wheel already draws it), so mods that add slices to these wheels see vanilla's object API unchanged. Where the game fills a wheel itself (vehicle, animal, emote groups), call vanilla's filler for the inner wheel and add ZeD's Back slice last.

## 5. Words and pictures

- Every ZeD string through `ZeD.tr` (`UI_ZeD_Wheel_*` keys in `translate/en/UI.json`); vanilla's own words where vanilla has them (emotes, `IGUI_*`, the vehicle and animal slices, the off reasons it gives).
- Pictures: ZeD's icon set (the mockup's choices: `TabIcons/*-white`, and `icons/` apple-whole, water-045-drink, bandage-wound, smoking, book-open-reader, bed, clock, survival-077-radio, fi-br-shirt-long-sleeve, hood-cloak, face-mask, sitting-ground, chair, lightbulb-on, settings, info-guide, question, text-box-dots, handshake, backpack for Hands free); vanilla's pictures where they say more (the gestures, crouch, sit, auto-walk, zoom, game speed, items in inner wheels show the item's own texture).
- The bubble's second line carries the useful detail: "Belt, slot 3", "Fresh · eat first", "0.6 L · water", "1 tile away", "Workbench, 2 tiles".

## 6. Open, small

Built Oct 23 2026 (`ZeD_DpadWheels.lua`). What the build found and settled:

- **Controller map** (Help 2): left off as "Coming later." in v1.
- **Rooms editor** (World 8): the game has no way in on 42.21 (vanilla's slice is `if false`, its function is defined nowhere, the editor is a Java debug tool). World's eighth slice is **Designated zones** itself.
- **Stopwatch** (Use, Watch): ZeD's watch has none (light, alarm, speed, start only). Watch offers Open the watch, Light, Alarm. The watch is player one's only.
- **Lie down** (Sit): the game has no lie-down verb outside sleeping. Sit offers Sit on the ground (Get up while sitting) and Sit on: the nearest seat (vanilla's Rest).
- **Medicine and first aid**: the treatments are exactly what the Health panel would offer for each part that wants care (its own menu builder, recorded), the part on the second line.
- **Sleep**: the game's rules in its order (the vehicle wheel's), its own reasons.
- **Lights and power**: Light fire opens the fire's card (lighting needs a method; the card lists them); Put out fire is direct.
- **Chat, Safety, Players**: the game's own calls (chat focus, the safety toggle, the pause screen's Players), not tried on a server.
- Driving with X held keeps D-pad Up and Down for cruise control, as the game does.

- **Controller map** (Help 2): there is no screen for it yet. Either a simple ZeD window listing GAMEPAD_SPEC's button table, or leave the slice off ("Coming later.") for v1. Code's call; tell the director which.
- Inner wheels past 11 kinds: best 11 for v1 (section 2.8).

## 7. Done means (GAMEPAD_SPEC parity, plus)

- Each wheel opens from its direction with no window focused, points with the right stick, takes on release, opens inner wheels in place, B backs out, A takes inside.
- Every slice in section 3 present in its place in every scene; off ones show the right reason.
- Nothing the game's D-pad wheels offered is lost (section 4's table; the mockup's parity table).
- Readable at both text sizes, in all three themes, at 1080p and at 4K 1.75x.
- Split screen: each player's wheel on their own screen.
- QA: a bridge script `zedqa_dpad_wheels.lua` (no physical pad: call the four `onDisplay*` with `{ player = 0, id = <joypad id or nil> }` and the fill functions directly, the way suite_gamepad does): log each wheel's slice names and live / off state on foot, in a car, by an animal; open one inner wheel per wheel; take one safe slice per wheel (Tabs ▸ Health, Map ▸ Mini-map, Shout, Zoom in) and check the result; screenshots of all four at 4K 1.75x with the windows reset. Add it to `regression.txt`.
- Then the gallery's "On a controller" card gets a reshoot with the new wheels (design side, the director's call).
- And the gallery's **Controller** map card (`shots.json` id `controller_map`) gets two balloon texts changed in the same commit as the wheels: D-pad: "In a window: move from control to control. No window open: hold for a wheel: Character, World, Social, Here and now." Right stick: "Aim. Hides both windows; Y brings them back. In a wheel: point." Then rebuild with make_shots `--only controller_map`, make_desc and the page mockup. The Steam description's Controller list gets the same line.
