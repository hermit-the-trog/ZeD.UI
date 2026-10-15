# Session 125 delta — animals in trailers (Oct 14 2026)

Director: "trailers next, start with the mockup", then "go with your recommendations, build it". Mockup `ZeDUI/mockups/zed_trailer_animals_v1.html` (commit 6225039f), every recommendation accepted, including the animal list staying readable with the lid shut while every verb waits for it.

### Built
- **The trailer's page in the Vehicle tab** (`MechTrailer.lua`, called from `MechanicsTab.lua`; helpers shared through `MechanicsTab._h`, both files hot-reload alone). For any vehicle with `getAnimalTrailerSize() > 0` (Livestock Trailer, Horse trailer):
  - **Summary** beside the figure: SPACE `used of 500 · left` and the floor bar (one segment per animal in list order, its kind's colour from a theme palette, 1px seams, a key of kinds with their totals; over the limit the bar spans what is used, a red cap mark and red hatching past it, the value with a red dot and `over`); TRUNK LID (dot + Open / Shut, CLOSE / OPEN walks into the lid's area then vanilla's `onCloseDoor` / `onOpenDoor`); FOOD and EGGS (most common item and count or `N eggs`, a fill bar, weight of capacity, OPEN); THIRSTY (`2 of 5 · no water inside`); TOWED BY / TOWING; with an inspection, OVERALL. Hovering a part on an inspected trailer still swaps in the part's readout.
  - **ANIMALS** (collapsible): portrait (a carcass by its mod data), name (`Dead %1` for a dead one), health / hunger / thirst dots, species, sex, age, tags (DEAD; THIRSTY and HUNGRY past vanilla's 10%, red past 50%; STRESSED past 50), space taken. A row opens the animal's card. "Trunk door is closed." above it with the lid shut.
  - **LOAD FROM HERE** (lid open): vanilla's doAnimalSubMenu list — the animal or carcass in your hands, then animals and carcasses in vanilla's 12x12 box — with size, `IN YOUR HANDS` / `AT THE BACK` / `N TILES FROM THE BACK`, PUT IN (vanilla's `onAddAnimalFromHandsInTrailer` / `onAddAnimalInTrailer`) or vanilla's reason ("Too far from back of the trailer." past 3 tiles, 5 on your leash; "Not enough room in the trailer."). Held first, then what fits, nearest first; scanned at most every half second.
  - **PARTS** waits for an inspection (`> PARTS (n) · INSPECT TO READ`, INSPECT in the footer); inspected, the usual part list follows the animals.
  - **The animal's card** (`view = "animal"`): back, name, REMOVE / GRAB / INFO (a carcass: REMOVE as the call to action, GRAB); vanilla's `ISVehicleAnimal3DModel` as a child of the tab panel with the trailer framing from `AnimalAvatarDefinition` (hidden when scrolled out of view, on another view or tab); HEALTH / HUNGER / THIRST / STRESS words with bars, WEIGHT when Animal Care allows it, SPACE; GIVE WATER (your water sources with amounts, WATER -> `AnimalContextMenu.onGiveWater`) past 10% thirst; FEED (what it eats from your bags, vanilla's filter, grouped with counts, FEED -> `onFeedAnimalFood`) past 10% hunger; NEEDS (`Trunk lid open · TO REACH IN`; `GRAB: Animal is too heavy to be picked up.` with the weight); footer OPEN LID when shut and the state in a line. The progress band (`PUTTING IN`, `TAKING OUT`, `GRABBING`, `GIVING WATER`, `FEEDING`, the lid, `WALKING TO THE BACK`) with the cancel X runs on the page and the card.
- **Hooks** (`Overrides/TrailerAnimals.lua`): `ISCheckAnimalInsideTrailer:perform` -> `MechanicsTab.openTrailer` (opens the World window and the Vehicle tab on the trailer, pins it to six tiles, scrolls just enough to show the animals, gamepad focus on the first animal); `ISVehicleMenu.onCheckAnimalInside` skips vanilla's walk inside the tab's 4.5-tile reach. Vanilla fixes: the world menu's Remove Animal from Trailer now passes the animal; `doAnimalSubMenu` counts a carcass in the hands so Put Animal in Trailer stays.
- **Vehicle tab**: a car and the trailer it tows come as a pair in the vehicle list; any towing / towed vehicle shows the TOWING / TOWED BY row (with the trailer's animal count); `MechanicsTab.pin`, `MechanicsTab.inReach`; disabled zones click without the button sound.
- **World window**: `ZeD_WorldWindow.selectContainer(inv, tries)` shows a container in the Loot pane (exits multi-select, reopens the inventory column, retries while you walk into reach); vehicle containers in the Loot strip carry vanilla's names (`IGUI_VehiclePart<type>`: Food Container, Egg Container, Trunk) instead of the part category ("bodywork").
- **Fix found in QA**: `ZeD.AnimalsData.getHealth` returned the engine's 0-1 health while every caller reads 0-100, so the Animals tab drew healthy animals with a red health dot and a "1%" HEALTH bar. It returns 0-100 now.

### Verified live (QA save, scene from `ZeDUI/tools/qa/zedqa_trailer.lua`; captures in `ZeDUI/qa/S125_trailer/`)
- Check Animal(s) in Trailer from 7.8 tiles (vanilla's walk, then the tab) and from 1.9 tiles (no walk); the page scrolled to the animals; clean boot after a restart (all three files load, no errors, no translator warnings).
- Summary: floor bar and key, lid, FOOD (hay) and EGGS (3 eggs), THIRSTY; over the limit (a cow forced in: 618 of 500 · 118 over, hatched); lid shut (OPEN as the call to action, OPEN buttons dim, the reason line, LOAD FROM HERE hidden, card verbs dim but INFO, footer OPEN LID opened it).
- Card: WATER (thirst 0.61 -> 0 with the band), FEED (hunger 0.40 -> 0.04, one hay used), GRAB a hen (in both hands, the card closed to the page), PUT IN from the hands, REMOVE and PUT IN from the ground, vanilla's world-menu Remove (fixed) on the lamb, INFO (the Animals tab on Dolly; the 3D figure hid itself), a hen killed in the trailer (DEAD, REMOVE dropped the carcass, PUT IN the carcass, GRAB the carcass, PUT IN from the hands), the cow's GRAB refused with vanilla's words.
- Towing: the trailer and a pickup linked; one press each way between the two pages; FOOD OPEN walked into the area and showed the Food Container in the Loot pane.
- Controller logic: opening lands on the first animal row; B on a card returns to the page with focus on that animal's row.

### Not seen live
- A physical controller; a real hitch (the QA link set the tow fields without physics); a Horse trailer; a birth inside a moving trailer (the over-full state was forced); the doAnimalSubMenu fix alone (other animals were always near the QA trailer).

## Padlock codes (HOOK_MAP row 25)

Director: "keypad codes next, start with the mockup", then "go with your recommendations, build it. If vanilla keeps no record we don't save the code. Got to appeal to the hardcore players too." Mockup `ZeDUI/mockups/zed_padlock_codes_v1.html` (commit 1f357f7e); decision 6 (remember the code) declined.

### Built
- **The lock card** (`ObjectCardLock.lua`, kind `lock`, leash 4) for an `IsoThumpable` that takes a padlock:
  - Header: the object's own name (`getEntityDisplayName`: "Wooden Crate (Basic)", "Small Metal Locker (Basic)"; `getName` is the entity id), its tile icon, a pill: SETTING A CODE / CODE LOCK / KEY LOCK / UNLOCKED.
  - The padlock, drawn: steel shackle (up while setting a code), a dark combination body with three cream number wheels (the set digit, its neighbours rolling away) and ▲ / ▼ keys, or a brass key padlock with a keyway; "NO PADLOCK ON IT" when there is none. Input: ▲ / ▼, the mouse wheel over a wheel, the number keys and Backspace while the pointer is on the card (left to right, a bar under the wheel the next digit lands on), D-pad up / down on the focused wheel (A presses the card's verb, left / right move between wheels; while an action runs the D-pad moves on to STOP).
  - LOCK (setting a code): vanilla's onSetDigitalCode (walk next to it, `ISPadlockByCodeAction` lock); NEEDS: a Combination Padlock in the main inventory (vanilla finds and removes it there), a code other than 000; the line "Locked to everyone, you included, until the code takes the padlock off"; the wheels return to 0 0 0 once it is locked.
  - REMOVE PADLOCK (code lock): every try is vanilla's `ISPadlockByCodeAction` unlock (20 ticks), which only acts on the right code; the card marks its action and, once it has run with the object still locked, says "Wrong code: 3 1 9. The padlock stays on." (a cancelled try says nothing). Turning a wheel clears it. Right: the padlock back in the inventory, the container selected in the Loot pane, "Padlock off. It shows in the Loot pane."
  - Key padlocks: REMOVE PADLOCK (vanilla's `onRemovePadlock`, needs the key), USE PADLOCK on a free object (vanilla's `onPutPadlock`, needs a Padlock with keys); USE COMBINATION PADLOCK switches the card to setting a code.
  - The progress band (TRYING 3 1 9 / LOCKING / PUTTING THE PADLOCK ON / REMOVING THE PADLOCK / WALKING OVER) with STOP; the footer states readiness or the reason.
  - WHAT IT LOCKS: the container (items and weight, or "hidden while locked"), the padlock, the key.
- **Hooks** (`Overrides/Padlocks.lua`): `ISWorldObjectContextMenu.onPutDigitalPadlock`, `onRemoveDigitalPadlock` (the Java world menu resolves them by name when it builds) and both `...WalkToComplete` functions open the card (`OC.openNear`: the walk only past the leash). `ISDigitalCode` never shows, so its bugs go with it (the removal pop-up titled "Set your Code", B pressing OK, closing resetting the game speed, two digits in one box).
- **Loot strip** (`ZeD_WorldWindow.lua`): a locked container's button gets a small red padlock mark; clicking it (or A on it) opens its lock card instead of doing nothing (A used to show its contents to a controller player).
- **Card framework** (`ObjectCards.lua`): `def.status(t)` footer state line (alarm tint for failures), `zone.wheel(del)`, `zone.nofocus`, `def.onKey(t, key, card, act)` with `OC.armKeys` (the World window asks UIManager for key events and passes them to the open card while the pointer is on it; the key is consumed only then).

### Verified live (QA save, `ZeDUI/tools/qa/zedqa_padlock.lua`; captures `ZeDUI/qa/S125_padlock/`)
- Vanilla's Use Combination Padlock opened the card in setting mode; 0 0 0 refused with the reason; wheels by ▲ / ▼; LOCK ran vanilla's action (the crate locked, a padlock left the inventory, the card turned to CODE LOCK).
- A wrong try (3 1 9) ran the band and said "Wrong code"; the right code took the padlock off, returned it and selected the crate in the Loot pane.
- Real input: a click on the key-locked crate's strip button opened its card; a click on the locker's opened its code card; 3 1 9 typed on the keyboard with the pointer on the card (the game never saw those keys; a key pressed away from the card reached the game); the mouse wheel turned a wheel 5 -> 7; a real click on REMOVE PADLOCK opened the locker (5 items in the Loot pane).
- Key padlock: REMOVE PADLOCK with its key (the padlock returned), USE PADLOCK on the free crate (KEY LOCK, key carried).
- Controller logic: the focus list is back, the verb and the three wheels (the ▲ / ▼ keys skipped); D-pad up / down turned a wheel (0 -> 1 -> 0 -> 9), left / right passed on.
- Found and fixed in QA: Kahlua's `%` keeps the sign (`-1 % 10` is -1), so a wheel turned below 0 read -1 and a crate locked with 407; the status line no longer lower-cases the name.

### Not seen live
- A physical controller; a multiplayer server (the actions are vanilla's own); a bar element or counter (same object class as the crates and lockers tested).

## The belt: hands + hotbar (HOOK_MAP rows 5 + 6)

Director: "hands and hotbar next, start with the mockup"; "hotbar also shows condition of equipped"; v1 (a physical belt-and-gloves prop) rejected: "this should be more UI like... keep it ZeD-GUI like not an object"; then the sketch `[Main Hand] ==[3]=[4]={buckle}=[5]=[6]== [secondary hand]` with the boxes a little taller than a subtle strap. Mockups v1-v3 (`ZeDUI/mockups/zed_hands_belt_v3.html` approved). "Go with your recommendations, build it" - the round counter (a recommendation question) left out: vanilla keeps no ammo readout on the hotbar.

### Built (commit 74d4837e)
- **`ZeD_Belt.lua`**: `ZeD.Belt` (slots with key / short name / provider / condition, `fits`, `activate`, `attach`, `detach`, `equipHand`, `slotMenu`, `rightMenu`, `takeDrop`, `focus`, `boxScreen`) and `ZeD_BeltHUD`, a top-level panel at the bottom centre: the hands as end squares, the slots in key order split either side of a brass buckle (`ceil(n/2)` left), a six-band leather strap with stitching behind them. Each box: icon, condition bar, key badge, lamp dot for a light that is on, IN HAND (dashed accent, faded icon), BOTH ghost in the off hand for a two-handed weapon, empty slots named (BELT L, HOLSTER...). Hover: a chip (BELT LEFT · KEY 2) and vanilla's item tooltip standing above the box. Click draws (vanilla `activateSlot`); drag a box off onto a hand (equip) or into a ZeD list (detach); a ZeD list drag lights the boxes that take it, dims the rest and shows REPLACE <item>; right-click = vanilla's slot menu (`ISHotbar:doMenu`; while paused the item's menu or the slot's list). Hidden when dead, in a vehicle, UI toggled off, or in the tutorial.
- **`Overrides/Belt.lua`**: ISHotbar keeps its data model and key handlers but its render / prerender are empty and it is parked off-screen; holding a hotbar key >500 ms opens the slot's list above the box and the release does not draw; D-pad Left (`ISDPadWheels.onDisplayLeft`) focuses the belt (D-pad L/R along it, A draw / unequip, X slot list or item menu, Up into IN YOUR BAGS = the rest of vanilla's wheel, B leaves); ISEquippedItem's hand slots hidden (the whole column in single player without -debug).
- **Equip tab**: HELD + BELT gains THE BELT · KEYS rows: key badge, icon, item over "SLOT · FROM THE <worn item>" (ALWAYS THERE for the back), the condition bar level with the name, IN HAND, DETACH / PUT BACK / ATTACH (the slot's list at the button). Buttons act on release. Right-click = the slot menu; controller ring elements `equipbelt:i` (A = the button, X = item menu or the slot's list at the row). Folded group shows only filled slots. Inventory rows show a BELT n tag after the name.
- **Context menus not under the cursor** (the director's Equip tab report), two causes:
  1. `Events.OnMouseDown` misses UI clicks and every right-click (KB Q175), so after any controller (or bridge) input the detector stayed in controller mode and the menu anchored at the item's inventory row or the screen bottom. The detector now polls mouse buttons every render frame; a menu opened within 1.5 s of a mouse press is the mouse's.
  2. A menu built straight on `ISContextMenu.get` (vanilla's hotbar menu, the Journal and Maps menus, the belt's lists) kept the previous menu's anchor and target. `ISContextMenu.get` now resets them to the asked point.
  Also: in controller mode an inventory menu goes where the caller names (X on an Equip row, belt row or belt box); 0, 0 still asks for the focused inventory row.

### Verified live (QA save; `ZeDUI/tools/qa/zedqa_belt.lua`; captures `ZeDUI/qa/S125_belt/`)
- Real mouse: click a box draws it (pistol in, bat back on its slot); a ZeD inventory drag onto Belt Left replaced the hammer with the trowel; a box dragged onto the main hand drew the knife; right-click on an empty box opened Attach at the box and attached the hammer; tap 2 drew the hammer; holding 3 opened Belt Right's list above it and a pick attached the knife without drawing on release; tooltip and chip above the box; drop states (fit / no / REPLACE) with a dragged knife.
- Equip tab, real mouse: DETACH, ATTACH (list stays open, bat picked), PUT BACK; right-click on a belt row and on an Equip slot row open at the cursor, also with controller mode forced on.
- Controller logic (no pad attached; methods called through the bridge): the ring holds the four belt rows, X on a row opens its menu at the row; the belt takes focus, D-pad right moves, A drew the trowel, B left; IN YOUR BAGS lists the loose weapons and the best light.
- Found and fixed in QA: the parked vanilla bar sat at the top-left (keepOnScreen clamps top-level panels) where it still caught clicks; a click on the belt never drew (press and release compared boxes from different frames); the ATTACH list closed on the click's own release; the belt's right-click menu opened where the last menu had been.

### Not seen live
- A physical controller; a vehicle seat (the belt hides when `getVehicle()` is set); multiplayer (the left column's server buttons stay); more than eight slots (keys past 8 show "-").

## Moodles: mockup v1 (HOOK_MAP row 7)

Director: "moodles next, start with the mockup" (also: run live QA in a 1080p window, or close the game; saved as a memory). Mockup `ZeDUI/mockups/zed_moodles_v1.html` (whole-screen stage; scenes: at a glance, after a fight, cold rain, hover, just got worse, well fed, Health tab, in a car; Where / Art / Summary / Input / Base / Accent / Zoom controls).

### Research
- Java `zombie.ui.MoodlesUI` (one per player, right edge under the old clock; today the CaZio watch covers its top). `Moodles` (Lua-public): `getMoodleLevel(type)`, `getGoodBadNeutral(type)`, `getMoodleDisplayString(type)`, `getMoodleDescriptionString(type)`, `isMaxMoodleLevel(type)`; the `Moodle` objects (chevrons) are private. 26 `MoodleType`s: ENDURANCE, TIRED, HUNGRY, PANIC, SICK, BORED, UNHAPPY, BLEEDING, WET, HAS_A_COLD, ANGRY, STRESS, THIRST, INJURED, PAIN, HEAVY_LOAD, DRUNK, DEAD, ZOMBIE, HYPERTHERMIA, HYPOTHERMIA, WINDCHILL, CANT_SPRINT, UNCOMFORTABLE, NOXIOUS_SMELL, FOOD_EATEN.
- Art: loose PNGs `media/ui/Moodles/<32|48|64|80|96|128>/` ("Mood_" faces and "Status_" icons, `_Moodles_BGsolid` / `_BGoutline` backings). `MoodleTextureSet` maps ENDURANCE -> Status_DifficultyBreathing, TIRED -> Mood_Sleepy, HUNGRY and FOOD_EATEN -> Status_Hunger, PANIC -> Mood_Panicked, SICK -> Mood_Nauseous, HAS_A_COLD -> Mood_Ill, INJURED -> Status_InjuredMinor, PAIN -> Mood_Pained, CANT_SPRINT -> Status_MovementRestricted, UNCOMFORTABLE -> Mood_Discomfort, the rest by name.
- Vanilla draws: backing tinted grey -> green / red by level, a pulse, a wiggle on change, hover title + description; its percentage fill is switched off in 42.20 (`isPercentageBackground` returns false). Chevrons only on HYPERTHERMIA / HYPOTHERMIA, from `Thermoregulator.thermalChevronUp()` / `thermalChevronCount()` (Lua-public).
- Earlier ZeD threads: Visual Catalog M27 Moodle icon, M29 Compound feeling, the workshop plan's "moodle bar with smart gravity", the two-windows plan's "Moodle opens linked tab", GAMEPAD_SPEC's reserved moodleBar slot.

### Recommendations in the mockup
Under the watch; worst on top; vanilla art in ZeD boxes (level = pips + border, pulse at 4, green for good); vanilla's temperature chevrons; hover chip in vanilla's words (no hidden numbers); click opens Thermal (Wet, Overheated, Cold, Windchill), Equip (Weighed Down, Restricted Movement, Uncomfortable) or the Health tab's new HOW YOU FEEL list (controller reading); vanilla's Moodle size option still steps the box size. Your call: the one-line summary (M29), recommended off.

### v1 rejected, v2 (same day)
Director: "moodles are the one thing we really aren't touching other than moving them around. options to put bottom of screen above hot bar, or left or right vertical", then "we do our own hover text". Saved as memory `feedback_moodles_vanilla`.

Mockup `ZeDUI/mockups/zed_moodles_v2.html`: vanilla's moodles as `MoodlesUI` draws them (art, round backing lerped grey -> Good / Bad highlight colour by level/4, outline ring, vanilla order, wiggle, chevrons, Moodle size option), in three places: right column under the watch (recommended: vanilla's own column, just moved), left column starting below the Character / World windows, or a row above the belt (above the dashboard in a car; needs a ZeD copy of vanilla's drawing). Hover text: a ZeD chip (status dot, vanilla's name and description, the chevrons in words).

Engine facts: `MoodlesUI` sets x = screen width - 10, y = 120 in its constructor and its `update()` never moves it (position comes from outside; the build re-applies it each frame as the watch does for the clock). It lays slots out vertically only (`slotsPos` on Y, spacing = size + 10). Its hover text box is drawn to the LEFT of the column (x = -10 - text width - 6), so on the left edge it would be off-screen. Size: `getOptionMoodleSize()` 1-6 -> 32/48/64/80/96/128 px (7 = by font size); the director's is 2 (48 px). Backing colours: `Core.getGoodHighlitedColor()` / `getBadHighlitedColor()` (options.ini goodHighlightColor 0,1,0, badHighlightColor 1,0,0).

Director on v2: "options would be best. each of the three placements are good for different users." All three ship as a setting: Options > Mods > ZeD-UI > Moodles (Right, under the watch = default / Left edge / Bottom, above the belt), applied live; recorded in the v2 mockup notes.

### Built (commit 25553f77): moodles in three places
- `ZeD_Moodles.lua`: `ZeD_MoodleLayer` per local player (top-level, transparent). Placement from the new option (Options > Mods > ZeD-UI > Moodles, read live each frame): Right, under the watch (default; vanilla's column moved to the watch's bottom + 10) / Left edge (vanilla's column at x 10, below where the windows open) / Bottom, above the belt (vanilla's column parked off-screen; ZeD draws the copy as a row above the belt, above the dashboard in a car, centred on the player's screen). Placement runs in `OnPreUIDraw` (engine resets the column's x every frame before drawing, KB Q198). The layer lies over the moodles, returns true from onMouseMove (vanilla's own hover text never draws, Q200), lets clicks through, and draws the ZeD chip: status dot (good green, bad amber / red from level 3), vanilla's display name and description, beside the column (left of it on the right edge, right of it on the left edge, above the row). Vanilla's order reproduced from hash codes (Q199); Well Fed from level 3.
- `Settings.lua`: the Moodles combo (`ZeD.Settings.moodlePlaceOption`), a display preference (mod options, not the save).
- `QABridge.lua`: dev-only autoload of the latest save (flag file `Zomboid/Lua/zedqa.autoload` = "1", cleared before it fires) for windowed launches; `UIManager.setShowLuaDebuggerOnError(false)` when it arms. `ZeDUI/tools/qa/pzlaunchwin.ps1` (backup options.ini, 1920x1080 window, autoload, click to start) and `pzrestorewin.ps1` (put the display settings back after the game has closed).
- Corrected from the mockups: vanilla 42.20 draws no temperature chevrons, so neither the copy nor the chip shows a trend.

### Verified live (1080p window, QA save; captures `ZeDUI/qa/S125_moodles/`)
- Right: vanilla's column under the watch (y 243), real hover on the third moodle gave "Tense / On edge." for the Stressed moodle; vanilla's text never showed.
- Left: vanilla's column on the left edge (after the OnPreUIDraw fix); real hover gave the Hungry chip to the right.
- Bottom: the copy row above the belt (Weighed Down, Hungry, Stressed, Injured, Drowsy, vanilla's order this launch); a hunger rise to level 3 redrew the backing and wiggled; real hover put the chip above; vanilla's column gone.
- Toggle UI (the real `toggleUI` path) hides the belt and the moodles and brings them back.
- Found in QA: the layer, as tall as the screen, was clamped onto it (keepOnScreen); the column's x never reached the screen (OnPreUIDraw fix); vanilla's order is not registration order (hash order); a caught script error halted the game in the debugger (break-on-error now off for the bridge); god mode reset the test needs.

### Not seen live
- A vehicle seat for the bottom row (logic: above the dashboard panel when it shows); split screen; multiplayer (the vanilla left column keeps its server buttons and could meet a Left-edge moodle column); the tutorial's blinking moodle in the copy (vanilla only).

## Main menu: mockups v8 -> v9 (approved)

Director: "main menu next, start with the mockup"; "ITEM SCALE. Scale is so bad right now" (v8's props were dollhouse-size against the monitor; redrawn at real size, then superseded); the director then drew the desk themselves (`ZeDUI/art/main_menu/zed-desk-crt.svg`, pixel art 480 x 270, one-point perspective, a SCREEN CANVAS slot, later enlarged to 240 x 180 = 960 x 720 at 1080p, and the props rescaled by the director); "rebuild the mockup on this desk"; "pause menu needs to look like a ZeD window. window frame, buttons..."; "ew, remove the default AI style on the new game selection, is that left bar part of our lifeforms? This should be a flashback to the era. I don't want current design leaking in too much" (saved as memory `feedback_era_not_modern`); "this is correct".

Approved: `ZeDUI/mockups/zed_main_menu_v9.html` (HOOK_MAP row 26). The desk drawn at whole multiples (4x at 1080p, 8x at 4K; 6x with edge trim at 1440p); the menu bar and ZeD windows on the monitor built on the live frame (pinstriped title bar with close box and "name + section", Molecules.drawButton double-outline buttons, action strip, footer squares): Project Zomboid (Continue card + five ZeD buttons + Options / Mods / Workshop / Credits / Quit), Load Game (saves by mode under inventory category headers, Find field, preview with PLAYING AS, BACK / DELETE / MORE / PLAY, footer delete confirm), New Game (System 7 icon view of vanilla's `media/ui/playstyleIcons/*.png`, vanilla's descriptions, BACK / CHOOSE MODS / NEXT); the pause window (Resume, Options, Players and Invite in MP; Quit to Desktop / Save and Quit in the action strip). Also the belt buckle lost its middle bar (director: "doesnt work like that").

Director then: "build it, motion is fine. I was hoping to use the new main menu background as the game loading screen, leave the old one as the background for the main menu PC though. So yes to motion on this screen, but this is not the loading screen, just menus". Reading: the "new background" is 42's illustrated scene the engine draws behind vanilla's screens; the "old one" is the title painting, which stays on the monitor. The loading screen is HOOK_MAP row 27, not started.

## Main menu: built, phase 1 (HOOK_MAP row 26)

Built: `ZeD_MainMenu.lua` (the desk, the menu bar and its pull-downs, the Project Zomboid window, the pause window, pointer and controller), `Overrides/MainMenu.lua` (hooks on vanilla's `MainScreen`), textures in `media/textures/ZeD/mainmenu/` (`desk.png` 480 x 270; `lamp_dim.png`, `dial_clean.png` motion patches; `wallpaper.png` / `wallpaper_lightning.png`: the old title painting and its lightning frame cropped to 4:3, own copies because the mod blanks vanilla's `media/ui/Title*.png`). `Organisms.lua`: `ZeD_Window` gained `themeFooter` (footer squares on a fixed-size window, no grow box), `noResetControl`, `globalAccentControl`, `getFooterPrompts()`. `Settings.lua` applies the mod options at the main menu; `QABridge.lua` arms at the main menu (OnFETick) and polls on OnRenderTick in game (OnTick stops while paused). `ZeDUI/tools/qa/pzlaunchwin.ps1 -MainMenu` launches windowed to the menu without autoload.

Director mid-build: "can load game lead with the character name large, then the save name in a medium heading" — done on the Continue card (character large, save as an F4 heading, then mode and map, last played; a dead character gets a red status dot); carried into Load Game for phase 2.

Departures from the mockup, all small: MODS (n) is a button in the pause window (vanilla's in-game Mods list had no other home); R (reset the Character / World windows) is only in the pause window's footer (nothing to reset at the menu); the ZeD menu also holds Terms of Service and Report a Bug, and Debug holds Scenarios (vanilla's debug scenario list sat over the old logo); a save's map reads "Knox Country" when it spans the county.

### Verified live (1080p window, QA save, real mouse and keys; controller through the bridge)

- Desk at 4x with nearest filtering (first build drew it smoothed: `getTexture` loads mod textures linear, KB Q205), the painting on the monitor, a held lightning flash measured (the lightning frame lights the room's window and the figures); the lights, needle and lamp run on timers.
- Menu bar: File and ZeD pull-downs open, highlight on hover, close on an outside click; Settings > Mods (1 on) opened vanilla's Mods screen, Escape came back to the desk.
- Window: hover fill, LOAD GAME opened vanilla's Load screen and Escape returned; QUIT asks in the strip (CANCEL hovered, QUIT red) and Escape cancels; the power button shows "Quit" on hover; controller focus moves through the rows and the strip with A / Y prompts in the footer.
- CONTINUE loaded the QA save. Pause: Escape opens the ZeD window (vanilla's logo no longer drawn over it), hover, QUIT TO DESKTOP asks and CANCEL returns (the question also survives a frame stall and resets when the menu reopens), OPTIONS opened vanilla's options and BACK returned, controller D-pad and A ran SAVE AND QUIT back to the desk, which refreshed the Continue card.
- Fixed during QA: a Kahlua and/or bug made the menu's "is it up" check return a table in game (KB Q206); a menu title click could not close its own menu; the pause question was reset by a frame stall (now reset on vanilla's `onEnterFromGame`, KB Q209).

### Not seen live

- A real controller (the bridge drove the handlers; the main-menu joypad focus is vanilla's).
- 1440p (6x with edge trim) and ultrawide margins; 4K (8x) is the director's rig.
- Multiplayer: PLAYERS / INVITE FRIENDS and the server name in the pause title; Host / Join beyond opening vanilla's screens.
- Tutorial, Workshop, Credits, Terms of Service, Report a Bug (opens a browser), Reset Lua and Quit itself (only the question and CANCEL were pressed).

### Next

Phase 2: Load Game and New Game on the monitor (mockup v9), Load Game leading with the character. Then map / spawn, character creation, Options and Mods each get a mockup. The game loading screen is row 27.

## Main menu phase 2: Load Game + New Game on the monitor

Director, after phase 1: "Things are looking really great! you think you could /loop until you have a solid version of all menus and a more robust mod manager? Settings menu is obviously the biggest mess after mod management, maybe bigger. I am confident at this point in letting you steer decisions making for the rest of menus and settings. Look for ways to improve UX while staying true to ZeD UI foundation." Then: "I dont need mockups". From here the front-end screens are designed in the build; decisions are listed per section for review.

Built: `ZeD_MainMenuSaves.lua` (ZeD_MMLoad, ZeD_MMNewGame), views on the desk (`MM.showView`, one window at a time), pop-up menus at buttons (`MM.openPopup`, controller walks them), and redirects: vanilla's `soloScreen` / `loadScreen` `setVisible(true)` shows our window instead, so every vanilla way back (map / spawn BACK, character creation BACK, the mod list's return, a challenge's BACK) lands on the monitor.

Decisions:
- Load Game rows and preview lead with the character (director's note), the save's name under it; the game's own copies read "Sandbox, Oct 12 (crash)" / "(backup)".
- Saves grouped by mode under inventory category headers (click to fold), newest mode first; "Find:" filters on character, save, mode and map.
- Preview: the save's picture as a cropped band, then the facts grid (MODE, MAP, PLAYED, MODS, VERSION); PLAYING AS only when the save has a choice of character; what stops a save loading and mods not found as red-dot lines (vanilla's words).
- MORE holds vanilla's Rename File (a field in the action strip, vanilla's name rules), New Player, Choose Mods, Open File Location. DELETE asks in the strip; deleting the last save goes to New Game as vanilla does and the main window's Continue follows.
- New Game: vanilla's six playstyles as a 1993 icon view (chosen icon darkened, its name highlighted), vanilla's description; CHALLENGES opens vanilla's challenges in the same view (wide screenshots sit on their labels). NEXT runs vanilla's NewGameScreen.clickPlay.
- Keys: Escape leaves a field, then a question, then the window; Return plays / goes on; Delete asks; arrows walk the saves / icons. Controller: list rows then the strip; Load: A play, X delete, Y more, B back; New Game: A next, Y choose mods, B back.

Verified live (1080p window): list, wheel scroll, row click, Find with real typing, a dead character's dot, MORE pop-up, delete question, controller focus with scroll-follow and footer prompts, Choose Mods round trip (selection kept), New Game icon view, Custom Sandbox NEXT into vanilla's spawn screen and its BACK onto the monitor, challenges view and back.
Not seen live: PLAY from Load Game (CONTINUE uses the same vanilla call), Rename on disk, New Player, deleting a save (the QA saves were left alone), PLAYING AS with two characters (no such save here).
