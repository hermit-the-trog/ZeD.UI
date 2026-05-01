# ZeD-UI technical audit: Build 42.13–42.16 patch impact

**The three Steam Community discussion pages you provided are not traditional patch notes threads.** Thread `800092562772748901` is the "Balancing Time" companion discussion for Build 42.16.0; thread `800092562772761347` is the "Stable(41.78.19) + UNSTABLE(42.16.3) Hotfixes Released" discussion; and thread `800092562772770017` is confirmed as "Patching a Zero Day Exploit" covering a malicious mod incident on April 7–8, 2026. Direct fetching of these Steam Community URLs was blocked by the platform, but the actual patch notes content for all relevant builds (42.13.0 through 42.16.3) was recovered from the Steam allnews page, PatchBot, and multiple secondary sources. What follows is a complete extraction of every UI-relevant change and a full ZeD-UI cross-reference analysis.

---

## Build 42.13.0 — the MP release that reshapes everything

**Version:** 42.13.0 | **Date:** December 11, 2025

This is the largest single patch in the B42 cycle. It introduced multiplayer, overhauled the context menu system, refactored core Java classes to use a new registry/namespace system, and changed dozens of UI behaviors. Every section below is extracted verbatim or near-verbatim from the official notes.

### Inventory/object interaction changes (all items)

- Appropriate clothing and container items can be equipped while walking (hats, gloves, glasses, satchels, backpacks, etc.)
- If a character is walking while performing the unequip action for a clothing or container item that cannot be worn while walking, the unequip action will be cancelled
- **Added a new body location slot, "satchel."** Satchels, water bags, and cowboy canteens now use "satchel" instead of ammo_strap/back
- Double-clicking on items in inventory now performs non-destructive actions: bandages apply to injuries; literature/maps start reading; containers equip to secondary hand (then primary if secondary is full); lighters/walkie-talkies equip and turn on; flashlights equip-and-activate or unequip-and-deactivate; candles/lanterns auto-light and equip if player has a lighter; boxes/bundles/cartons unpack
- Players will no longer start eating food on double-click if the food is burned, rotten, dangerously uncooked, or poisoned
- Added item icons to "Destroy For Fuel" and "Light Fire" context menus
- Multiple items can be set/unset Unwanted when selected
- **Changed the loot-window "Take Same Type" text button to an image button**
- **Moved the loot-window container title leftward since it overlapped the weight**
- **Added a second button to the inventory window to transfer matching items to nearby containers**
- Context menu option will not display for a drinkable item being used by an action
- Items that can be turned on/off have "(On)" suffix in display names
- Items like Flashlights now turn off when not equipped
- When item is equipped from hotbar and isn't a weapon, placed in secondary slot (or primary if secondary is full)
- Added item icons to "Add Liquid from Item" context-menu options
- **Tidied up RMC context menu WIP — many options moved into submenus and have icons**
- Item tooltips displayed for items in the "Fill" context menu for water sources

### Crafting/building UI changes

- **Added more sub-categories/recipe groups in the Crafting Menu**
- **Shift+click on an input or output item to quickly search the exact type; can now search for Fluid**
- Picking up and replacing input items behaves the same whether using right-click or the crafting UI
- Searching for recipes shows all recipes with same characters
- Frozen food for evolved recipes now show/explain they cannot be used
- Added keybind "Sharpen Weapon" under Combat
- Added code to handle battery-based radio power in craft recipes
- **Locked the crafting panel by default so it doesn't go away when you walk**
- **Added a "show all recipe" tickbox in the handcraft panel; removed the cheat Recipe.SeeAll**
- **Moved Plastering, Wall Paper and Painting options to the Build Menu** (removed from RMB context menu with tooltip advising players of move, added new icons in Build Menu)
- Removed manual ingredients toggle for the build menu

### General UI/system changes

- Character-info-window trait tooltips now show trait description in addition to name
- Escape and Enter keys activate Back/Next buttons in sandbox options screen
- Updated icons for siphoning and adding fuel to a vehicle
- Added accessibility option to auto-mark locations on world map when print media items are read
- Backpacks display blood level on 1–100 scale when right-clicking on sinks for washing
- "Wound" and "Zombie Damage" won't appear as clothing option categories in character creation when all clothing unlocked
- Added displaying labels when mousing over brochure/flier icons on in-game map
- Restored good-color halo text above character model when auto-learning craft recipes; added for growing season, mechanics, and generator recipes
- Added ISPanelJoypad logic for handling controller disconnecting at main menu, reverting to KB+M
- Reduced print-media and stash-map icon sizes on in-game map when zooming out
- Added Investigate Area window controls to Back button menu for gamepad support
- Disabled animated Endurance moodle indicator until edge-case issues can be addressed
- Updated debug RMC options to use same icon as debug button
- Walls no longer cutaway when player aims+hovers over buildings

### Balance changes (selected UI-adjacent items)

- Scale the inventory-window and loot-window image buttons to match height of text buttons
- Craft recipes to open sealed fluid containers now use Unseal input flag instead of onCreate code
- Craft recipes for lighting candles/lanterns use flags instead of OnCreate code
- Tooltips for fluid containers now display calories, proteins, lipids and carbohydrates for the current amount, not per 1000mL
- Added calorie/carbs values for some fluids; tooltip now displays values when they're zero
- Removed world inventory fluid container options from world RMC (still in inventory)
- Edible liquids' properties state calories per container instead of per liter

### Fixes with UI/mod implications

- Fixed ISInventoryPaneContextMenu Lua error when using a controller
- Fixed getAllTagEvalRecurse using incorrect identifier for CarBattery in ISWorldObjectContextMenu
- Fixed MainScreen.lua error when activating or deactivating a controller while in game
- Fixed skill tooltips interfering with mouse-wheel scrolling in Skills panel
- Fixed skill tooltips remaining visible after mouse-wheel scrolling in Skills panel
- Fixed inventory-window and loot-window container buttons disappearing temporarily after changing display options
- Fixed the "Make Up" UI handling of different font sizes
- Fixed Sidebar icons overlap the inventory window on Steam Deck
- Fixed "Vision" tooltip panel in ISSearchWindow not functioning when using gamepad
- **Fixed unused Event in ISSearchWindow**
- Fixed the game-version button and world-seed label not respecting screen resizing
- Fixed Bottom right div of handcraft window doesn't respond to gamepad buttons
- Fixed issues with the "saved builds" combobox in character creation profession UI
- Fixed profession and trait errors in ISPlayerStatsUI
- Fixed ISMoveableSpriteProps error placing streetlight sprites
- Fixed error when double-clicking on non-literature items
- **Fixed old font still being available in game**
- Fixed Empty textEntry string in modOptions prevents menu from loading
- Fixed Mod options passing nil as a string parameter if field is left empty
- Fixed "Error received when checking 'Show Craft / Build Recipes Used In' from item's RMC context menu"
- Fixed HandCraftWindow displayed recipe does not match list selection after crafting

### Tech/code/debug — the critical modding changes

- **Updated JRE to Java 25**
- **Introduced a namespaced resource system (ResourceLocation, Registry)** to unify resource management. Mods can register entries with their own namespaces.
- ResourceLocation represents namespace identifiers (namespace:path), with validation, parsing, equals/hashCode methods
- Registry\<T\> is a generic, namespace-aware registry supporting registration via ResourceLocation IDs, lookup by ID or string, iteration
- ResourceLocationPanel is a debug ImGui panel for viewing registry entries
- **Refactored ItemTag from an enum to a class with registry support**
- **Refactored ItemBodyLocation to include registry support**
- Refactored classes no longer use strings for identifiers; type-safe objects replace them
- **Added CharacterStat class for unified handling of character stats; uses a registry with static definitions**
- Refactored Stats.java to leverage CharacterStat
- **Replaced Drunkenness stat usage with CharacterStat.INTOXICATION**
- **Replaced StressFromCigarettes with CharacterStat.NICOTINE_WITHDRAWAL**
- **Consolidated BoredomLevel stat usage with CharacterStat.BOREDOM**
- **Removed legacy Fear stat**
- Added ConcurrentHashMap to support mods adding custom ItemBodyLocations
- Added BodyLocationGroup.getOrCreateLocation(String) which is needed by clothing mods
- Converted ItemBodyLocation enum to class
- All setExclusive() and setAltModel() calls in BodyLocations.lua should also use the ItemBodyLocation enum
- Lua debugger improvements: text filter in ObjectViewer, PREV button, KahluaTableImpl.toString() now shows "ISButton 0x12345678" for tables with Type field, displays \<metatable\> as element
- Added IsoGridSquare.canStand() and hasAdjacentCanStandSquare() functions
- Added IsoObject.hasAdjacentCanStandSquare()
- Updated AdjacentFreeTileFinder.lua to use IsoGridSquare.canStand
- Refactored code in ItemContainer and InventoryPage to handle occupied seats with reduced capacity
- Warn when you accidentally overwrite a method using a field in the Lua Exposer
- Converted class IsoPropertyType to enum (42.14.0)
- Converted sprite overlay styles from string to enums (42.14.0)
- Added IsoObjectChange enum to replace string for object change (42.14.0)
- Added missing IsoObjectType getter/setter (42.14.0)
- **"Ported more things to lua"** (42.14.0)
- Allow mods to fill registries
- Fixed incorrect modData values in ItemCodeOnCreate
- Removed needTobeLearn in CraftRecipeBuilder (now uses existing needToBeLearn)
- Added configRoomFade(seconds, percent) Lua command for room fade-to-black control

---

## Build 42.13.1 — December 18, 2025

Hotfix. Key UI-relevant fixes:

- Fixed Host Settings UI scaling issue on some resolutions
- Fixed not saving the lock status on the handcraft UI
- Fixed partially consumed food items still being displayed as full in the UI
- Fixed padding information not updating on unequipped clothing items
- Fixed disappearing favorite, unusable and unwanted tags
- Fixed the order of clothing layers for mod creators
- Fixed errors when double-clicking on empty containers in inventory

---

## Build 42.13.2 — January 19, 2026

Hotfix. Key UI-relevant:

- Fixed Favoriting recipes (Craft and Build menu) being reset after relogging
- Fixed seasoning ingredients not being displayed in tooltip
- Fixed wrong items being selected and captured from stack of items
- Fixed updates breaking setting the ZombieState FMOD parameter

---

## Build 42.14.0 — February 16, 2026

**UI section (labeled [UI] in official notes):**

- **RMC Inventory menu now displays appropriate available Crafting shortcuts when all crafting requirements met**
- **RMC Inventory "Craft" shortcut searches for all available Crafting recipes using item** — replaces "Show Craft Recipes Used In"; searches for item instead of string name for cleaner results
- **RMC Barricade Build shortcut added to Tile Window/Door menus when all building requirements met**
- **RMC Inventory and Tile actions re-ordered and consolidated for priority actions**
- **RMC Tile menus display appropriate interaction icon**
- **Added Item Inventory Tooltip when mousing over Equipped Item UI slots or Hotbar**
- When multiple inventory items are selected that can be Read, you can "Read All"
- Added "Wash Vehicle" to Vehicle Radial Menu
- Reorder in the debug context menu
- Updated the Media Info Panel to be more easy to use (VHS cover checking, etc.)

**Balance items with UI implications:**

- Game Option: Enable "Resume normal speed when timed actions complete" by default
- Added new item icons
- Changed display names of some firearm items
- Updated logos in the game

**Technical/Debug:**

- Converted class IsoPropertyType to enum
- Removed containers not used by mappers from Distributions
- Added missing IsoObjectType getter/setter
- Ported more things to Lua
- Converted sprite overlay styles from string to enums
- Added IsoObjectChange enum

---

## Build 42.14.1 — February 18, 2026

Small hotfix:

- Fixed player getting stuck trying to leave cars
- Fixed vehicles attracting zombies from far away
- Fixed errors when pressing Avatar rotate buttons
- Fixed being able to select "Deaf" and "Hard of Hearing" together
- Fixed not being able to drink tainted water from bottles, option was missing from context menu
- Fixed error with packet SyncItemFields when remote player equipped weapon in hotbar (MP)
- Fixed NullPointerException when Weapon Multi hit sandbox option is enabled (MP)
- Fixed muscle strain from combat not synced in multiplayer

---

## Build 42.15.0 — March 9, 2026

**New features:**

- **New Game Mode Defaults**: Apocalypse (lore canon), Outbreak (accelerated), Extinction (hardcore/sprinters), Rising (cozy), Custom Sandbox. Each has corresponding Custom Sandbox preset.
- **New Firearms**: JS-14 Rifle (5.56), JS-3T Tactical Shotgun (12ga), L92 Carbine (.357), L94 Rifle (.30-30), MSR7T Tactical Rifle (7.62), Trapper Carbine (.45 ACP) — with magazines, loot distributions, repair recipes
- Character receives reading speed boost when sitting
- New gun store loot story prototype
- Added new map symbols for animals
- Basic aiming reticle handling for Gamepad — uses aim axis to place target reticle relative to player; added reticle slow-down on active target
- Added option to toggle Livestock Zone visual overlay on/off
- **Shift+Click allows user to select multiple items in workstation menus**
- Renamed Game Option "Pause when focus is lost" to be more clear, enabled by default

**Modding changes:**

- New modding guide/changelog
- Fixed COMMON/VERSION folders not being detected correctly in mod directory
- Fixed mod translation, modID, client-server files check logic
- Fixed translation loading order
- Added translation support for mod.info (title, description)
- Fixed ModID, WorkshopID logic
- Added .glb for model file watcher
- Improved error message when clients are missing a mod from server
- Fixed WorkshopItem description generation; added support for **512x512 mod image preview**
- **Localization clean-up: Translation files are now in JSON**

**Security:** Patched vulnerability reported by copiumsawsed.

---

## Build 42.15.1 — March 10, 2026

Single fix: Fixed game not loading when the username has non-ascii characters.

---

## Build 42.16.0 — March 31, 2026

**IMPORTANT: B42.15 and earlier saves NOT compatible with B42.16+.**

**UI updates:**

- **Added new Game Mode UI menu**
- Updated loading screen tips
- **Campfires, BBQ's, Fireplaces now supported in revamped RMC system**
- **New highlight added when mouse-over container with same highlight as moused-over "on ground" item in loot UI menu**
- **Changed default size of the various main screen UIs**
- **Anchor permanent Oven/Campfire/etc options to the lower-right of the loot UI to prevent conflicts with loot options**
- Improved context-menu handling of window frames without windows
- Vehicle Lightbar Control UI Panel can now be repositioned
- Transfer liquid UI defaults to maximum transfer amounts instead of 'none' when appropriate
- **Disabled Welcome Text Box**
- **New Container Highlight System: Hovering over items on floor or in bags auto-highlights identical items in open containers**

**Balance (UI-adjacent):**

- Occupation Balance Pass: rebalanced cost/skills for Police Officer, Park Ranger, Construction Worker, Security Guard, Carpenter, Chef, Rancher, Farmer, Electrician, Fishing Guide, Doctor, Nurse, Welder, Blacksmith, Mechanic. Renamed Fire Officer → Firefighter, Angler → Fishing Guide.
- Trait Balance Pass: New traits Tinkerer (+1 Maintenance), Target Shooter (+1 Aiming). Renamed Wilderness Knowledge → Bushcrafter. Various cost adjustments. Desensitized trait now provides immunity to Discomfort.
- Tailoring Rebalance: reworked recipe layout
- Game Mode Balance Pass: loot spawn adjustments, firearm spawn reductions, more fresh food, reduced world erosion speeds

**Fixes:**

- Ecocreck region removed from spawn locations (causes save incompatibility — key reason for save break)
- Fixed errors when writing in a notepad/diary placed on floor
- Hide version number if not on main screen while not in-game
- Various pathfinding and MP stability fixes

---

## Build 42.16.1–42.16.3 — April 2–9, 2026

- 42.16.1: Server browser IP addresses hidden by default; toggle checkbox to reveal. Fixed Park Ranger herbalist exploit.
- 42.16.2: **Right-click no longer toggles forceAim conflicting with RMC menu; now waits slightly longer before engaging.** Controller users can now move/perform actions while inventory is open. Vehicle radial menu not interrupted by player aim. Switching seats no longer makes player exit vehicle.
- 42.16.3: Fixed server browser exception + security vulnerability update. Related to the "Patching a Zero Day Exploit" incident (14 malicious Workshop mods disguised as music add-ons; only affected B42 branches).

---

## ZeD-UI cross-reference impact analysis

### 🔴 Critical breaking changes

**1. RMC/context menu system overhaul — BREAKS ISContextMenu monkey-patching**

The right-click menu system has been progressively restructured across 42.13.0, 42.14.0, and 42.16.0. In 42.13.0, "many options are now moved into submenus and have icons." In 42.14.0, the "Craft" shortcut replaced "Show Craft Recipes Used In" and searches by item object instead of string name. RMC actions were re-ordered and consolidated. In 42.16.0, campfires/BBQs/fireplaces were integrated into the "revamped RMC system." In 42.16.2, right-click timing was changed to avoid forceAim conflicts. **ZeD-UI's ISContextMenu monkey-patching and hooks into OnFillInventoryObjectContextMenu / OnFillWorldObjectContextMenu need comprehensive testing against the new menu structure, submenu hierarchy, and icon integration.** Any code that assumes specific option ordering, parent/child relationships, or the old "Show Craft Recipes Used In" entry will break.

**2. ItemTag refactored from enum to class with Registry support**

If ZeD-UI references `ItemTag` anywhere (e.g., for filtering items in the ZoneList, ItemCard, or context menus), the transition from enum to class with `ResourceLocation`-based identifiers will break direct enum comparisons. ZeD-UI must update to use the new registry lookup API.

**3. CharacterStat refactoring — stat name changes break direct lookups**

`Drunkenness` → `CharacterStat.INTOXICATION`, `StressFromCigarettes` → `CharacterStat.NICOTINE_WITHDRAWAL`, `BoredomLevel` → `CharacterStat.BOREDOM`, and **Fear stat removed entirely**. If ZeD-UI's Health, Moodle bar, or Character Window tabs read these stats by old names, they will fail. The new `CharacterStat` class uses a registry with static definitions.

**4. ItemBodyLocation converted from enum to class**

The new "satchel" body location was added. `ItemBodyLocation` now uses registry support with `ConcurrentHashMap` for custom locations. ZeD-UI's Equipment tab, which likely references body locations for the character model/slot display, must adapt to the new class-based API. Any `BodyLocations.lua` references using the old enum approach need updating.

**5. Font system change**

"Fixed old font still being available in game" (42.13.0). If ZeD-UI's Mac System 7 aesthetic relies on any legacy font that was previously "still available," **it may now be gone**. This is critical for a pixel-precise 1px-border UI that depends on specific font metrics.

**6. ISInventoryPaneContextMenu Lua error fix + restructuring**

A direct Lua error in `ISInventoryPaneContextMenu` was fixed in 42.13.0 when using a controller. The function `getAllTagEvalRecurse` had an incorrect identifier for CarBattery in `ISWorldObjectContextMenu`. Since ZeD-UI replaces `ISInventoryPaneContextMenu` and hooks into `OnFillInventoryObjectContextMenu`, any fixes to the underlying function signatures or parameters may invalidate ZeD-UI's replacement logic.

**7. ResourceLocation/Registry namespace system**

This is a foundational change. Identifiers throughout the engine now use `namespace:path` format (`ResourceLocation`). `Registry<T>` provides generic namespace-aware registration. While this primarily affects Java-side code, it propagates to Lua through `ItemTag`, `ItemBodyLocation`, and potentially future systems. ZeD-UI should begin adopting namespaced identifiers for forward compatibility.

### 🟡 Requires attention/update

**8. Inventory window layout changes**

Multiple layout changes across patches: loot-window "Take Same Type" changed from text button to image button (42.13.0); container title moved leftward (42.13.0); new "transfer matching items to nearby containers" button added (42.13.0); inventory/loot image buttons scaled to match text button height (42.13.0); **new Container Highlight System in 42.16.0** auto-highlights identical items in open containers. Sidebar icon overlap on Steam Deck was fixed. Since ZeD-UI replaces `ISInventoryPane`, these vanilla layout changes don't directly break ZeD-UI, but ZeD-UI should replicate equivalent functionality (especially the Container Highlight System) or users will lose features.

**9. Crafting panel behavior changes**

The crafting panel is now **locked by default** so it doesn't disappear when walking (42.13.0). A "show all recipe" tickbox was added, replacing the `Recipe.SeeAll` cheat. More sub-categories/recipe groups were added. Shift+click now searches for exact type and fluid. In 42.15.0, Shift+Click allows selecting multiple items in workstation menus. ZeD-UI's World Window Crafting tab must account for these behavioral changes — especially the lock-by-default behavior and the new recipe display options.

**10. Build Menu absorbs Plastering/Wallpaper/Painting**

These were moved from the RMC context menu to the Build Menu in 42.13.0, with new icons. ZeD-UI's World Window Building tab needs to include these categories. The removal from the RMC with a tooltip advising players means ZeD-UI's context menu hooks should also not show these options.

**11. Double-click behavior overhaul**

Extensive new double-click semantics were added in 42.13.0 for bandages, literature, containers, lighters, flashlights, candles, boxes/bundles. ZeD-UI's custom `ISScrollingListBox`-based ZoneList and `ISPanel`-based ItemCard must support these new double-click behaviors if they present inventory items.

**12. Tooltip system changes — conflicts with custom drawer/detail surface**

New tooltips for equipped item UI slots and hotbar (42.14.0), fluid container calorie/nutrient display (42.13.0), item tooltips in Fill context menu (42.13.0), and Media Info Panel update (42.14.0). Since ZeD-UI replaces vanilla tooltips with a custom drawer/detail surface, these new tooltip data sources should be surfaced through ZeD-UI's custom system instead. Skill tooltips were also fixed for mouse-wheel scrolling interference in the Skills panel — relevant to ZeD-UI's Skills tab.

**13. Moodle system partially disabled**

"Disabled animated Endurance moodle indicator until edge-case issues can be addressed" (42.13.0). ZeD-UI's planned horizontal Moodle bar on the Character Window should note that the Endurance moodle animation is currently disabled upstream. The `CharacterStat` refactoring also changes how moodle-related stats are accessed.

**14. Main menu and screen state changes**

`ISPanelJoypad` got new logic for controller disconnect handling at main menu (42.13.0). `MainScreen.lua` had an error fixed for controller activation/deactivation. New Game Mode UI menu added in 42.16.0. Default sizes of main screen UIs changed (42.16.0). Welcome Text Box disabled (42.16.0). If ZeD-UI's CaZio watch/HUD system or any component interacts with screen state transitions, these changes need verification.

**15. Game-version button and world-seed label screen resizing fix**

Fixed in 42.13.0. ZeD-UI's pixel-precise layout should verify that its own positioning respects screen resizing properly, especially given the related fix.

**16. Character creation UI changes**

Fixed issues with the "saved builds" combobox in character creation profession UI (42.13.0). Fixed profession/trait errors in `ISPlayerStatsUI`. New traits added (Tinkerer, Target Shooter, Motion Sensitive) and existing ones renamed (Wilderness Knowledge → Bushcrafter, Fire Officer → Firefighter, Angler → Fishing Guide). ZeD-UI's Identity tab must update its trait/profession display for these additions and renames.

**17. Occupation/trait rebalancing in 42.16.0**

Extensive rebalancing of ~15 occupations and multiple traits. Doctor starts with First Aid 6. New traits Tinkerer and Target Shooter. Desensitized now provides Discomfort immunity. ZeD-UI's Identity tab, any character stat display, and skill-level-dependent UI elements need updating.

**18. New body location "satchel"**

ZeD-UI's Equipment tab must display this new slot. Previous items that used ammo_strap or back body locations (satchels, water bags, cowboy canteens) now use "satchel."

**19. Mod translation system changed to JSON**

"Localization clean-up. Translation files are now in json" (42.15.0). If ZeD-UI uses the old translation file format, it must migrate.

**20. RMC timing change in 42.16.2**

"Right-click no longer toggles forceAim conflicting with RMC menu. Now waits slightly longer before engaging, so that RMC menu doesn't pop up." This changes the timing relationship between right-click and menu appearance. ZeD-UI's ISContextMenu monkey-patching must account for this delay.

### 🟢 Useful new capabilities

**21. Registry system for mod namespace registration**

ZeD-UI can register its own namespace (e.g., `zedui:`) for custom items, body locations, stats, and tags using the `ResourceLocation` and `Registry<T>` system. This provides formal engine support for mod-specific identifiers.

**22. ConcurrentHashMap for custom ItemBodyLocations**

ZeD-UI could register a custom body location for the CaZio watch system using `BodyLocationGroup.getOrCreateLocation(String)`.

**23. configRoomFade(seconds, percent) Lua command**

New Lua API for controlling room fade-to-black timing and intensity. Could be useful for ZeD-UI's visual rendering if it interacts with room lighting states.

**24. IsoGridSquare.canStand() and hasAdjacentCanStandSquare()**

New Java functions exposed to Lua. Useful for any ZeD-UI world-interaction features (e.g., contextual tabs that depend on player position validity).

**25. LightFilter properties for curtains**

`LightFilterR/G/B`, `LightFilterIntensity`, `LightFilterMix` properties available for modders/mappers. Not directly UI, but potentially useful for environmental theming.

**26. Lua debugger now shows ISButton class names**

`KahluaTableImpl.toString()` changed from "table 0x12345678" to "ISButton 0x12345678" for tables with a Type field. Directly useful for debugging ZeD-UI's custom UI components. The ObjectViewer also now has a text filter and \<metatable\> display.

**27. "Ported more things to lua" (42.14.0)**

Vague but important — more Java functionality is now accessible from Lua. Worth investigating what new API surface is available for ZeD-UI.

**28. New item icons across multiple patches**

42.13.0 added context menu icons (siphoning, fuel, debug, build menu). 42.14.0 added new item icons and updated logos. 42.15.0 added map symbols for animals. These are potential additions to the ZeDIecon library if vanilla icons are being wrapped.

**29. 512x512 mod image preview support (42.15.0)**

ZeD-UI can now use higher-resolution Workshop preview images.

**30. Shift+Click multi-select in workstation menus (42.15.0)**

New interaction pattern that ZeD-UI's crafting interface should support or replicate.

---

## Engine quirks cross-reference (Q1–Q43)

Without the full list of Q1–Q43 quirks, the following patch notes **confirm or inform** known engine behaviors:

- **ISCollapsableWindow/ISPanel resizing**: The fix for "game-version button and world-seed label not respecting screen resizing" (42.13.0) confirms that vanilla UI elements had screen-resize bugs, supporting any known quirks about panel positioning during resize.
- **ISScrollingListBox mouse-wheel**: The fix for "skill tooltips interfering with mouse-wheel scrolling in the Skills panel" confirms known quirk of tooltip rendering intercepting scroll events on `ISScrollingListBox`.
- **ISContextMenu timing**: The 42.16.2 change where "right-click no longer toggles forceAim conflicting with RMC menu" confirms the known timing issue between right-click events and context menu display.
- **Gamepad/ISPanelJoypad**: Multiple fixes across patches confirm persistent issues with controller handling in IS* panels, including "Bottom right div of handcraft window doesn't respond to gamepad buttons."
- **Font rendering**: "Fixed the 'Make Up' ui handling of different font sizes" and "Fixed old font still being available in game" confirm font-system instability.
- **Container button disappearing**: "Fixed inventory-window and loot-window container buttons disappearing temporarily after changing display options" confirms a render-invalidation quirk in inventory panels.
- **modOptions nil string**: "Fixed Empty textEntry string in modOptions prevents menu from loading" and "Fixed Mod options passing nil as a string parameter" confirm modOptions string handling quirks.

---

## New Events.* hooks and IS* class changes

**Events changes identified:**

- "Fixed unused Event in ISSearchWindow" — an event that was connected in `ISSearchWindow` has been cleaned up. If ZeD-UI was relying on this event, verify it still exists.
- No explicitly **new** `Events.*` hooks were announced in any of the patch notes. However, the registry system (`ResourceLocation`, `Registry<T>`) provides new infrastructure that future hooks could use.

**IS* class changes confirmed:**

| Class | Change | Build |
|-------|--------|-------|
| `ISInventoryPaneContextMenu` | Lua error fix with controller; "Craft" shortcut replaces "Show Craft Recipes Used In" | 42.13.0, 42.14.0 |
| `ISWorldObjectContextMenu` | getAllTagEvalRecurse CarBattery identifier fix; RMC campfire/BBQ/fireplace integration | 42.13.0, 42.16.0 |
| `ISSearchWindow` | Removed unused Event; fixed Vision tooltip with gamepad | 42.13.0 |
| `ISPanelJoypad` | Controller disconnect handling at main menu | 42.13.0 |
| `ISPlayerStatsUI` | Fixed profession and trait errors | 42.13.0 |
| `ISMoveableSpriteProps` | Fixed error placing streetlight sprites | 42.13.0 |
| `ISCollapsableWindow` (inferred) | Inventory/loot window button scaling, container title repositioning | 42.13.0 |
| `MainScreen` | Lua error fix for controller; new Game Mode UI; default UI sizes changed | 42.13.0, 42.16.0 |
| `HandCraftWindow` | Fixed recipe display mismatch after crafting; lock status saving; locked by default | 42.13.0, 42.13.1 |

**New Java classes/methods exposed to Lua:**

- `CharacterStat` class with registry-based static definitions
- `ResourceLocation` and `Registry<T>` for namespace management
- `IsoGridSquare.canStand()` and `hasAdjacentCanStandSquare()`
- `IsoObject.hasAdjacentCanStandSquare()`
- `configRoomFade(seconds, percent)` Lua command
- `IsoObjectType` getter/setter
- `IsoPropertyType` (converted to enum)
- `IsoObjectChange` enum

---

## Prioritized action items for ZeD-UI v0.1.21

The highest-priority rework items, ordered by severity and effort:

1. 🔴 **Audit and rebuild ISContextMenu monkey-patching** against the new RMC structure. The submenu hierarchy, icon integration, option ordering, and timing changes across four patches make this the most urgent task. Test against `OnFillInventoryObjectContextMenu` and `OnFillWorldObjectContextMenu` with the new "Craft" shortcut behavior specifically.

2. 🔴 **Update all CharacterStat references** from old names (Drunkenness, StressFromCigarettes, BoredomLevel, Fear) to new `CharacterStat.*` constants. This affects the Health tab, the planned Moodle bar, and any stat display in the Character Window.

3. 🔴 **Verify font compatibility** after the old font removal. Test all ZeD-UI text rendering at target resolution with the current B42 font set. If the Mac System 7 aesthetic depended on a specific legacy font, a replacement must be sourced.

4. 🟡 **Adapt to ItemTag class (from enum)** and ItemBodyLocation class changes. Update any code that compares ItemTag values directly; adopt registry lookup pattern. Add "satchel" body location to Equipment tab.

5. 🟡 **Replicate new inventory features** in ZeD-UI's replacement panels: Container Highlight System, double-click behaviors, Transfer Matching Items button, image-style Take Same Type button. Users switching to ZeD-UI should not lose these QoL features.

6. 🟡 **Update Crafting tab** for lock-by-default behavior, show-all-recipe tickbox, new sub-categories, shift+click search, and shift+click multi-select (42.15.0). Plastering/Wallpaper/Painting now in Build Menu.

7. 🟡 **Update Identity tab** for renamed traits/professions and new traits (Tinkerer, Target Shooter, Motion Sensitive). Account for Desensitized's new Discomfort immunity.

8. 🟡 **Migrate translation files to JSON** format per 42.15.0 localization changes.

9. 🟢 **Adopt ResourceLocation namespace** (`zedui:`) for forward compatibility with the registry system.

10. 🟢 **Evaluate new ZeDIecon entries** for vanilla context menu icons added across patches (fuel, siphoning, build menu, debug, RMC tile interaction icons).