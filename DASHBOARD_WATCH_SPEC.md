# DASHBOARD + CAZIO WATCH — spec v1 (S123, Oct 12 2026)

**Sister files:** `ZeDUI/mockups/zed_dashboard_v1.html`, `ZeDUI/mockups/zed_cazio_watch_v1.html` (Lua-flat previews) · code `42/media/lua/client/ZeD/ZeD_Dashboard.lua`, `ZeD_Watch.lua` · hook rows HOOK_MAP.md #2 and #7.
**Status:** first cut shipped and verified by script on stable 42.20.2. Visual direction OPEN for the director (brand names, variant palette, whether analog hands stay).

---

## Vehicle dashboard

### What it is
A single bottom-centre HUD strip (560×92 at 1×, scaled by `T.scale`) that replaces `ISVehicleDashboard` while the local player drives. The vanilla dashboard object is kept (Java still calls it through vanilla's enter/exit handlers) and parked invisible every frame.

### Layout — one organism, never re-arranged
- **Trim band** (3 px, top): colour derived from the vehicle paint (`getColorHue/Saturation/Value` → RGB, saturation boosted, value floored). Grey / white / black paints fall back to the family colour so the band never vanishes. Emergency vehicles get the livery stripe (paint colour alternating with danger red).
- **Cluster** (left 300 px): speed in F4 digits + gear chip (transmission letter when running, `P` otherwise) + a unit line that doubles as the ignition state (`KM/H - 2400 RPM`, `KEY IN`, `HOTWIRED`, `NO KEY`). Three bars: RPM (text colour), FUEL (positive / warning < 35 % / danger < 15 %), BATT (positive / warning < 50 % / danger < 20 %). Fuel and battery read `--` unless the key is in or the engine runs (vanilla rule).
- **Toggles** (right): ENGINE, KEY, LIGHTS, DOORS, TRUNK (only with a `TruckBed` part), HEATER (only with a `Heater` part), RADIO, CRUISE. Each = status dot + name (F5) + optional value. Dot: green on / grey off / yellow partial (starting, hotwired, some doors locked, engine condition < 40 %) / red fault (no key, lights on but dead, no radio with key in). Fault tiles get the danger tint + border. CRUISE is a real toggle (loop 2, pass 3): enabled while the engine runs; A mirrors vanilla `ISVehicleRegulator` (off if on, else set the regulator to `getCurrentSpeedForRegulator()` when moving at 5+). The tile shows the regulator speed.
- **Footer**: brand text right (script name prettified — real brand names are a director decision), gamepad hint left in gamepad mode.

### Interior variants (loop 2) - the cabin colour tints the strip
The game carries no interior colour data, so every vanilla model is assigned the cabin it would have had in 1993 Kentucky (`INTERIORS` + `MODEL_INTERIOR` in `ZeD_Dashboard.lua`, mockup section 4). Chassis and tiles are the theme surfaces blended 35 % toward the cabin colour, so light and dark presets both work; the 2 px piping line along the bottom is the cabin accent; the trim band on top stays the exterior paint. Livery words (police, sheriff, trooper, swat, kst, pd, ambulance, hosp, fire, ranger, taxi, race) override the model.

| Cabin | Models |
|---|---|
| slate cloth | Chevalier Nyala (CarNormal, CarLights) |
| navy cloth | Chevalier Dart (SmallCar) |
| burgundy velour | Masterson Horizon (SmallCar02) |
| walnut + tan | Chevalier Cerise Wagon (CarStationWagon, 2) |
| saddle leather | Mercia Lang 4000 (CarLuxury) |
| charcoal | Dash Elite (ModernCar), Franklin All-Terrain (SUV) |
| beige cloth | Chevalier Primani (ModernCar02) |
| khaki vinyl | Dash Rancher (OffRoad), ranger liveries |
| cocoa vinyl | Chevalier D6 (PickUpTruck) |
| tan vinyl | Dash Bulldriver (PickUpVan) |
| fleet grey | Franklin Valuline (Van), Chevalier Step Van |
| blue velour | Valuline passenger (VanSeats) |
| red leather | Chevalier Cossette (SportsCar) |
| black vinyl + yellow | Taxi |
| medic white | Ambulance |
| fire red | fire department liveries |
| patrol black + blue | police, sheriff, state trooper, SWAT |
| roll cage | Race Car |

**Brand text** is the game`s own vehicle name through `IGUI_VehicleName*` (CHEVALIER NYALA, MERCIA LANG 4000 ...), the same lookup `ISVehicleMechanics` uses; burnt wrecks resolve to the unburnt name.

**Lightbar vehicles** (`vehicle:hasLightbar()`) get two extra tiles: LIGHTBAR (cycles the lights knob 0-3) and SIREN (standby / yelp / wail / alarm), sent as the same `vehicle` client commands `ISLightbarUI` uses. The strip keeps two rows and widens per vehicle: 3 columns (498 px) without trunk or heater, 4 (560 px) for the usual 8 tiles, 5 (622 px) with lightbar + siren.

### Family emphasis (trim + text only)
| Family | Script name match | Trim fallback | Extra |
|---|---|---|---|
| normal | default | accent | — |
| sport | `sport`, `race` | danger red | speed digits in gold |
| utility | `pickup`, `van`, `truck`, `suv`, `trailer` | info blue | — |
| emergency | `police`, `ambulance`, `fire`, `ranger`, `lights` | info blue | striped livery band |
| luxury | `luxury`, `limo` | warning gold | warm chassis + tile fills |

### Behaviour
- Actions reuse vanilla verbs exactly: `ISVehicleMenu.onStartEngine / onShutOff / onToggleHeadlights / onToggleTrunkLocked / onToggleHeater`, `ISVehiclePartMenu.onLockDoors`, `setKeysInIgnition`, radio device on/off. Same game-speed guards as vanilla (no action while paused; fast-forward drops to 1×).
- Mouse: click a tile. Gamepad: on OnEnterVehicle / OnSwitchVehicleSeat as driver the strip registers with FocusManager and claims focus **only if no ZeD window owns it**; D-pad cone-nav across tiles, A toggles (prompt labels per tile: Start / Shut off, Insert key / Remove key, Lights on/off, Lock / Unlock, …), B releases focus back to driving. OnExitVehicle hides and unregisters. Re-focus path after B: re-enter the seat (S124: consider a chord).
- Passengers (any seat) see the strip read-only: every tile disabled, no focus claim, footer `<brand> - PASSENGER` (vanilla shows its dashboard to all occupants).
- Split-screen: player 0 only in v1 (`ZeD_Dashboard:new(playerNum)` is ready for more).

### Verified (bridge, S123)
Hot-loaded; `addVehicleDebug("Base.CarNormal")`, `vehicle:enter(0, player)`, `OnEnterVehicle` → strip visible at bottom-centre (1640,2060 on 4K), vanilla dashboard invisible, 8 tiles, 6 enabled (KEY disabled: debug car has no key; CRUISE display-only), focus stayed with the open World window as designed.

### Open for the director
Brand names per vehicle; whether the gear chip should be a dial; the paint-derived trim vs a fixed per-family palette; tile order; adding a lightbar/siren tile for emergency vehicles (`ISLightbarUI`); a horn/alarm indicator.

---

## CaZio watch

### What it is
The HUD clock, redrawn in ZeD language in the Java clock's footprint and position (`UIManager.getClock()`, 156×62 top-right on this rig). The Java clock is parked (`setVisible(false)` each frame). Drawn **only while a wrist watch is worn** — the vanilla rule — found by scanning worn items for `AlarmClockClothing` on a wrist location.

### Faces (from the worn item type)
| Item | Kind | Face | Brand text |
|---|---|---|---|
| `WristWatch_*_DigitalBlack` | digital | green LCD on dark | CAZIO |
| `WristWatch_*_DigitalRed` | digital | red LCD | CAZIO |
| `WristWatch_*_DigitalDress` | digital | cool white LCD | CAZIO |
| `WristWatch_*_ClassicBlack / Brown / Gold / Military` | analog | tinted dial, 4 ticks, hour (2 px) + minute (1 px) hands drawn as rect runs | TIMEKS (placeholder) |
| `WristWatch_*_Expensive` | analog | ivory dial, date window, gold readout | ROLLEX (placeholder) |
| unknown watch (mods) | digital if `isDigital()` else classic | black | — |

Digital: time in F4 + `24H` / `AM` / `PM` per `getOptionClock24Hour()`; date order per `getOptionClockFormat()` (1 = Month/Day -> `WED JUN 09 1993`, 2 = Day/Month -> `WED 09 JUN 1993`); date line `WED 09 JUN 1993` (day-of-week via Zeller); red square when the item alarm is set. Analog: readout to the right of the dial (`20:31`, military `2031 HRS - WED`), date line on the expensive face only (parity with `isDateVisible`).

### Open for the director
Brand names (CaZio is locked); whether the analog readout should be hidden (dial only); LCD colours; a 12 h option on the dial; alarm indicator treatment.

---

## Resolution note
Both organisms use `T.scale` for geometry and the token fonts for text, so they will follow the UI scale axis when it lands (STATE.md item 3).

---

## Redesign track (Oct 12 2026, after the director's review) - v2 to v4 mockups

The S123 first cuts above are superseded in look. The director: the Visual Catalog v2.0 already had the designs (O22 vehicle controls, O23 CaZio case, O24 classic watch, M38-M42 hardware molecules); HUD objects are physical items, not information panels; decoration, shape and era expression matter; stereos, temp/fan dials and AC belong in the dash; analog watches get their own controls; the Cossette is a Corvette (sporty, digital).

Mockup lineage: `zed_dashboard_v2_cluster.html` (first instrument cluster) -> `zed_dashboard_v3_physical.html` (hood, chrome rings, tell-tale block, centre stack, head unit, HVAC, ignition cylinder, badge) -> `zed_dashboard_v4_binnacle.html` (arched binnacle with rounded corners, visor shadows, C4 and Cadillac digital dialects, four real head units: GM-grey cassette, black deck, sport amber with signal ladder, dial-scale with needle). Watch: `zed_cazio_watch_v2_case.html` -> `zed_cazio_watch_v3_physical.html` (straps, lugs, crown, champagne gold) -> `zed_cazio_watch_v4_casio.html` (A120-style front keys on digitals, ana-digi side pushers + dial LCD window on classics, chrono crown and pushers on Expensive, plain speed strip when no watch).

Control contract (every watch family): play/pause, speed step (1x 2x 3x), alarm on/off, alarm set. Digital keys: ALARM, SET, SPEED, START/STOP (merges the catalog's four speed keys). The watch replaces the Java clock and the Java speed controls together.

Dashboard contract: tell-tales are icon lamps; ignition is one cylinder (insert, start, stop; X removes the key); lights knob, lock rocker, trunk and cruise buttons; head unit drives the radio drawer verbs (power, volume, tune, browse, presets); TEMP knob = heater temperature, FAN = heater 0-3, A/C and HEAT push buttons; lightbar/siren as an accessory box on emergency cars. Static art ships as PNG plates drawn from the mockups; needles, lamps, digits and pointers draw live.

Open for the director after v4: analog vs digital per model; positive vs negative LCD per digital item; square vs round classic cases; merged speed keys vs four explicit keys.

### v5 (Oct 12 2026, director decisions applied)
- Decisions: round classic watch cases; positive and negative LCDs varied across the digital items; merged speed keys (SPEED steps 1x 2x 3x, START/STOP pauses) with the active speed shown in every LCD (segments + multiplier, PAUSE flag) and a lit mark on the SPEED key; dash pad and cluster hood molded on one curve (pad material runs to the hood edge, seam follows the hood, rounded shoulders), with square (fleet, truck) and trapezoid (Dash Elite) hoods for models that would not have curves; one badge per model (chrome plate, oval emblem, script plate with red stripe, stencil, stamped letters, brushed decal); one console per model with its own climate hardware (luxury digital VFD + rocker keys, sedan sliders, sport knobs + round vents, fleet siren controller + sliders, truck cable levers + dial radio, modern push-button panel with grey LCD).
- Mockups: `zed_dashboard_v5_molded.html`, `zed_cazio_watch_v5_round.html`. Audit (text overlap / out-of-frame / rect overflow) clean; 3x renders inspected.
- Lua notes for the build: mockup silkscreen at 3-5 px maps to F5 or is dropped (abbreviate, never shrink); static plates (hood shape, dial faces, rings, grain, vents, head-unit fascia) as PNG; needles, lamps, digits, knob pointers, slider knobs, lever knobs live.

### v5 build + live QA (Oct 12 2026, evening)
- Shipped: plate pipeline (`ZeDUI/tools/plates/`), 22 dash plates + 9 watch plates, generated anchor modules, `ZeD_Dashboard.lua` / `ZeD_Watch.lua` rewritten on the plates. Details in `ZeDUI/deltas/SESSION_123_DELTA.md` (loop 2, pass 4); crops in `ZeDUI/qa/S123_contact_sheet/`.
- Verified live: 16 designs on real vehicles, every control through its vanilla verb, all 8 watch faces + no-watch strip, alarm set / ALM / speed bars / PAUSE, gamepad claim + cue + hint + cone-nav + B release, passenger view.
- Badge wording contract (from the mockups): oval and stamped badges carry the MAKE (model on the cluster face or the stamped sub plate); script badges carry the MODEL plus the design sub (5.0); stencil badges are fleet markings "POLICE - UNIT nn" / "TAXI - CAB nn" / "AMBULANCE - UNIT nn" with a middle dot (nn from the vehicle id); chrome and decal badges carry the full name. Labels that do not fit the plate drop trailing words, then characters with a dot.
- Climate contract on one engine number: sign = side (A/C below zero, heat above), magnitude = blower (8 / 17 / 25 -> FAN 1-3); HEAT and A/C buttons keep the blower and pick the side (pressing the lit one switches off); TEMP steps +/-8; DEF = heat 25; OFF.
- Java clock + speed controls are parked off-screen (B42 ignores `setVisible(false)`); the watch anchors to the clock's old Y. The vanilla temperature readout that lived in the clock is gone - a design question.
- Decided Oct 13 2026: DigitalDress is GOLD (`W.dressVariant` = "gold"); the digital LCDs carry a thermo readout (air temperature as the vanilla clock showed it, bottom-left under the speed indicator, anchor `lcd.thermo`). Classic and expensive faces stay without it.
- Still open: fire / ranger / race designs unseen live, signal ladder fixed at 5-of-8, physical-controller pass for the A tap resolver, HUD size on the UI scale axis.
