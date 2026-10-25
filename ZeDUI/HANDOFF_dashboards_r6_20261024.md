# Handoff to Code: dashboards, round 6 (Oct 24 2026)

The director's round-6 changes to the 19 pixel-art dashboards, approved on Oct 24.

- **Art and data:** finished and checked in `ZeDUI/mockups/zed_dashboard_r6/src/`.
- **Pipeline:** not yet in `ZeDUI/tools/dashpx/`. They were kept out on purpose: an export before the Lua side is ready would hide the key.
- **Review sheets:** `ZeDUI/mockups/zed_dashboard_r6/dash_r6_details.png` (the parts up close), `dash_r6_balance_2x.png` (three dashes at 2x) and `dash_r6_before_after.png` (all 19).

## What changed (the director's words in quotes)

1. **Lower row.** "Trunk and lock on the side with light switch. Then wiper, cruise … and key on the right of cruise so key is right most. No left vents."
   - Left of the steering column (`COLUMN_X` = 250, the cluster's middle on every shell): lights, lock, trunk.
   - Right of it: a wiper rocker, cruise, then the key, always right-most.
   - Each side is spread with equal gaps.
   - The old fake vent at the right of the lower dash is gone, and no vent replaces it down here.
   - Curved dashes: the same order, with wiper and defrost rockers.
   - Ambulance: its EMERGENCY switch panel takes the cruise slot.
2. **The key turns.** "Key needs turning animation when starting." The key is three sprites, `src keyPos`, `when` = `"off"`, `"on"` or `"start"`. Details under A below.
3. **Vents.** "Make hvac vents larger in general and have more detail like realish vents." The console vents are 88 × 30 with:
   - a bezel;
   - horizontal louvers in front, one carrying the tab you push them by;
   - vertical vanes behind;
   - a knurled thumbwheel.
   The round ones are eyeball vents.
4. **Console.** "Stereos should align to the left edge of the console. Next to it on the right add an ash tray."
   - The radio sits against the left edge, with the ash tray and lighter to its right.
   - Spacing is balanced: 6 px between the parts across the console, and 7 px above and below the radio on the boxy consoles.
5. **Ash trays.** "Some should be open with butts sticking out … 2 to 6 butts, make em bigger, reasonable amount of ash."
   - Open trays are sprites: `src ashOpen` = 1, 2 or 3, for two, four or six butts. 0 means shut.
   - The taxi has only level 3.
6. **No smoking.** "The ambulance and emergency vehicles would have a no smoking sign there." Ambulance, police, fire and ranger get a NO SMOKING plate where the tray would be. It's on the plate itself, not a sprite.
7. **Hazards.** "Hazards switch under the ashtray when there is room." A red-triangle push button sits under the ash tray on the Lang 4000, Cossette, Dart, Rancher, Elite, Primani and All-Terrain. It's decorative: it has no hit area, and the game has no hazard lamps.
8. **Vans.** "Stickers only for businesses with ingame logo assets, otherwise no smoking for company work vans." The van's right side is plain vinyl, and the game shows one of three things there:
   - **The game's logo** (the sticker part, `match = "logo"`) for the vans in `VAN_LOGOS`:
     - `VanSpiffo` → `Buisness_SpiffosDECAL`
     - `VanFossoil` → `Buisness_FossoilDECAL`
     - `VanMccoy` and `VanJohnMcCoy` → `Buisness_McCoysDECAL`
   - **NO SMOKING** (`vanRight = "nosmoke"`) for any other company's van.
   - **An ash tray** (`vanRight = "ash"`, opening by `ashOpen` like any car's) for a private van.
9. **Taxi.**
   - **Meter:** "working meter". A bigger fare meter (FARE, five digits; EXTRAS, three) with a flag on an arm. The flag up reads FOR HIRE; pulled down, the meter runs. The flag is two sprites, `src meterOn` false or true, and the hit area is `meter`.
   - **Hula girl:** "hula bobble … too small". She's 25 × 35, three frames (`src hula` = 0, 1, 2), standing on the console's top lip. Her sprite has `y = -9`: she rises above the plate.
   - **License card:** "under hula needs a taxi license plaque". A riveted TAXI LICENSE card with the driver's photo, the cab's unit (a live badge, role `unit`, left-aligned: "TAXI - CAB 26") and NO 4417. It replaces the stencil badge.

## Pipeline steps

1. **Copy files** from `ZeDUI/mockups/zed_dashboard_r6/src/` into `ZeDUI/tools/dashpx/`:
   - `v6.py` (new)
   - `designs.py`
   - `build.py`
   - `live.py`

   Don't copy `stickers.py`: the trade stickers were dropped. `review_details.py` is optional; it builds the review sheet.
2. **Two fixes are in `live.py`:**
   - `heads[kind]` now returns three values, so the preview takes `[:2]`. This was broken before this round.
   - Sprites may sit above or left of the plate; they're clipped in previews.
3. **Decals for previews.** `build.py` reads the game's decals for the van previews from `ZED_DECALS`. Point it at `…/ProjectZomboid/media/textures/shirtdecals`. Without it, the previews just skip the decal.
4. **Build and check:**
   - Run `python build.py`: all 19 build with no placement warnings. Check that the export (`python export_lua.py <mod root>`) passes; it did in the workspace.
   - Then run `python luatest.py` and `python luatest.py hints` against the Lua once the parts below are in.
   - Run `nightsheet.py` for taxi, van and ambulance. The new materials (`ash`, `cork`, `paper`) have ramps, and the night pass handled them in the workspace.

## Lua (ZeD_Dashboard.lua, ZeD_Plate.lua)

### A. Sprites with a value, not just a flag
`ZeD_Plate` shows a sprite while `st[src]` matches `p.when` as true or false (line ~579). Make it compare values when `p.when` is a string or a number:

```lua
local ok
if type(p.when) == "string" or type(p.when) == "number" then ok = (st[p.src] == p.when)
else ok = ((st[p.src] and true or false) == (p.when ~= false)) end
```

This is needed for `keyPos`, `ashOpen`, `hula` and `vanRight`. `meterOn` and `lights` stay as they are.

### B. The key (`st.keyPos`)
- `nil` when there's no key in the lock (and while hotwired: no key sprite).
- `"off"` with the key in and the engine off.
- `"start"` while the engine cranks. Use vanilla's starting state, whatever `ISVehicleMenu.onStartEngine` sets (the engine's starting flag or timer).
- `"on"` while running.

The animation: on the start click, show `"on"` for about 120 ms, then `"start"` for as long as the engine cranks. Then show `"on"` if it caught, or step back through `"on"` (120 ms) to `"off"` if it didn't. Shutting off goes `"on"` (120 ms) → `"off"`.

### C. Ash trays (`st.ashOpen`, the `ash` hit)
- **Default per car:** shut on 6 in 10 cars. The other 4 open at level 1, 2 or 3, picked from a hash of the vehicle's id (`getId()` or its keyId), so a car always looks the same.
- **Taxi:** always 3, the only level it has.
- **Clicking `ash`** toggles open and shut. Store the choice in the vehicle's modData (`ZeD_ash`) so it stays put; reopening uses the car's level.
- **Prompt:** the hit's prompt is "Open ash tray" or "Close ash tray" (new strings, `UI_ZeD_Dash_AshOpen` and `UI_ZeD_Dash_AshClose`).
- **Not on:** emergency vehicles (they have no tray), or vans showing a logo or NO SMOKING.

### D. The van's right side (`st.vanRight`, `st.vanTray`)
- **Script in `VAN_LOGOS`:** `vanRight = nil`. The sticker part draws that decal on its die-cut backing; the Spiffo code already does this, so extend it from one decal to the map.
- **Any other van script that names a business:** `"nosmoke"`. That's anything but plain `Van`, `VanSeats` and `VanSeats_*`, and the burnt ones.
- **Plain `Van`, `VanSeats` and `VanSeats_*`:** `"ash"`, and the van uses C.
- **`st.vanTray`** = `(vanRight == "ash")`. The `ash` hit on the van `needs = "vanTray"`.

### E. The taxi meter (`st.meterOn`, `st.fare`, `st.fareExtra`, the `meter` hit)
- **The flag:** clicking `meter` pulls the flag down (`meterOn = true`), and clicking again puts it up. It only runs with the engine on. The key coming out puts the flag up and clears the meter.
- **Fare while `meterOn`:**
  - $1.50 when the flag drops, then $0.25 per 1/5 mile driven.
  - Waiting time of $0.25 per minute while stopped (under 5 km/h) with the flag down.
  - Use the existing per-vehicle trip distance (`t.fareMiles`, line ~536).
- **Extras:** $0.50 per passenger beyond the first. Count occupied seats other than the driver's.
- **Display:** both parts draw `st.fare` and `st.fareExtra` as `%.2f`. The new `digits` field on the `meter` part says how many cells to fill: 5 for the fare, 3 for the extras. Today's code assumes 5.
- **Flag up:** the meter shows dark ghost digits only, no number.

### F. The hula girl (`st.hula`)
- **Frame choice:**
  - 0 at rest.
  - 1 or 2 by the car's turning (the sign of its angular velocity) above 5 km/h.
  - A one-frame flick, 1 then 2, on a hard speed change or a bump.
  - Hold each frame at least 150 ms so she sways rather than flickers.
- **She's above the plate:** her sprite's `y` is −9 plate px. The dashboard element must let her draw above its top edge, either by drawing outside its bounds or by growing the element 10 × k px upward without moving the plate.
  - She sits at x 681–712, well right of the gamepad hint at the top edge (`hintRight` 486), so the hint's room is unaffected.

### G. Little ones
- **No new hits:** the wiper rocker and the hazard button are decorative.
- **Moved controls:** the `lights`, `lock`, `trunk`, `cruise` and `ignition` hits moved, but they're data-driven, so nothing to change.
- **The license card's unit line:** the existing badge `unit` role, left-aligned. Check that "TAXI - CAB 26" fits in 64 px; the badge code already fits text to width.

## In-game checks
1. **Every design at 1080p (k = 1) and 4K (k = 2):**
   - The lower row order.
   - The key: insert, start (watch OFF → ON → START → ON), a failed start, shut off.
2. **Ash trays:**
   - Open and close by click.
   - Is the same car still the same after a reload?
   - No tray on the ambulance, police, fire or ranger.
3. **Vans:** `VanSpiffo`, `VanFossoil` and `VanMccoy` show their logo. `VanMechanic` (or any business van) shows NO SMOKING. A plain `Van` shows a tray that opens.
4. **Taxi:**
   - Flag down: the fare climbs while driving and slowly while waiting.
   - A passenger adds $0.50.
   - Taking the key out clears the meter.
   - She sways in turns and is drawn above the dash's top edge.
   - The license card shows the unit.
5. **Night (lights on and off):** the new parts take the light map like any part, and the hula girl darkens with the dash.
6. **Gamepad hint lines:** run `luatest.py hints`. The top-edge room didn't change.
