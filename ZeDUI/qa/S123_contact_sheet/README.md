# S123 contact sheet — stable 42.20.2, QA save, Oct 12 2026

Captured from the live game at 3840×2160 through the QA bridge (tab switches) and the desktop screenshot tool (zoomed crops). Dark base, default accent, Elma Forman (new Sandbox character, zombie population None). Every surface shown loaded and switched with zero Lua errors in this session.

| # | Frame | Notes |
|---|---|---|
| 01 | Character Equipment + World Loot | Equipped list by body group; container strip shows Inventory, Key Ring, Small Backpack |
| 02 | Character Health | Body figure, Overall 100%, exercise buttons |
| 03 | Character Thermal | Core/Avg/Wind readout, skin temperature by region grid |
| 04 | Character Identity | ID-card readout |
| 05 | Journal — Journal sub-tab | Zombies-killed disclosure, note field, SAVE |
| 06 | Journal — Flyers detail | Opened thumb 1 ("No preview available"), BACK |
| 07 | Character Skills | Training materials, legend, per-skill disclosures |
| 08 | Character Radio (contextual, radio equipped) | Primary (1), presets 1–8, band display |
| 11 | Both windows on Loot | Baseline pair |
| 12 | ItemCard with live Progress Band | QA Book (renamed in-session), READING band — **new in S123** |
| 13 | World Craft | All Recipes, selected row + recipe card (required items, CRAFT) |
| 14 | World Build | All Recipes list |
| 15 | World Maps | Toolbar, colour chips, map canvas |
| 16 | World Animals | Ranch/Butcher sub-modes, zone cards, totals, CREATE ZONE |
| 17 | Journal — Recipes sub-tab | Category dropdown, sort pills, recipe rows (scroll-keyed focusables, S123 perf fix) |
| 18 | World Forage | Time-of-day scrubber, weather chips, zone, categories, recent finds |

Not pictured: multi-container columns (verified by script), context-menu strip (verified by script), Progress Band cooking danger state (verified by script on a real stove).
| 19–22 | Theme sweep | dark/large, light/large, light/small, high-contrast/large — every base × size applied live via `ZeD.applyTheme`, zero errors; restored to dark/small |
| 23 | Health figure after the S123 fix | Female atlas fitted to the box; no more oversized silhouette |
| 24–25 | Map pop-out (S123) | Unfolded map window, drawer shows the fold-back placeholder; same toolbar, gamepad cursor, B folds |
| 26–27 | Map pop-out opened through the vanilla Map toggle (`Overrides/WorldMap.lua`) | New character, new spawn; toolbar with the UNFOLD/FOLD button at the right end |

## Loop 2 frames (13:05-13:25) - dashboard interior variants + CaZio watch faces
All captured live on the QA save at 4K through the bridge: each vehicle spawned with `addVehicleDebug`, entered as driver, key created, tank filled, engine started from the dashboard tiles themselves.

| # | Frame | What it proves |
|---|---|---|
| 28 | dashboard Chevalier Nyala, slate cloth, key in | first cut: paint trim (grey paint -> accent fallback), 8 tiles, FUEL/BATT live with the key in |
| 29 | watch CaZio DigitalBlack | green LCD, 24H suffix, date line, Java clock parked |
| 30 | dashboard police Nyala, patrol cabin, lightbar on | 10 tiles / 5 columns (622 px), striped livery band, LIGHTBAR tile value "1" |
| 31 | watch Expensive | ivory dial, hands, date window, gold readout |
| 32 | scene with the lightbar lit | the LIGHTBAR tile drives the real lightbar |
| 33 | dashboard Mercia Lang 4000, saddle leather | luxury cabin, gold trim fallback, FUEL 0% in danger (empty debug tank) |
| 34 | watch ClassicGold | analog gold face |
| 35 | dashboard Cerise Wagon, walnut, engine running | RPM bar + gear letter live |
| 36 | watch ClassicMilitary | 24h HRS readout |
| 37 | dashboard Ambulance, medic white, lightbar + siren tiles | light cabin keeps text readable, striped band |
| 38 | watch CaZio DigitalRed | red LCD |
| 39 | dashboard Chevalier Cossette, red leather | sport: gold speed digits; trim band from the blue paint |
| 40 | watch ClassicBrown | brown dial |
| 41 | dashboard Taxi, black vinyl | yellow piping from the cabin accent |
| 42 | watch CaZio DigitalDress | cool white LCD |
| 43 | dashboard Chevalier D6 pickup, cocoa | 7 tiles (open bed = no TRUNK tile), 4 columns |
| 44 | watch ClassicBlack | black dial |
| 45 | dashboard with gamepad focus (pair closed) | 0.55 alpha accent cue on the focused tile + A/B hint in the footer |
