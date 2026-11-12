# ZeD design and test-coverage audit (Nov 11 2026)

## Summary for the director

We went through every ZeD design source, from the March inventory mockups and the April "two windows" and roadmap pages through the specs, plans, handoffs, the Visual Catalog and the punch list, to the November tooltip, menu-mark and pointer designs. We then checked each designed feature against what the game actually draws. Out of 168 distinct designed features, 109 are built, 13 are partly built, 34 were never built and 12 were dropped on purpose by a decision we could find in writing. The Fishing tab is the clearest case of the gap you found, but it is not alone. The never-built list also includes a Filter button for the inventory lists (on every early mockup), search on the Skills and Equipment tabs, the Animals tab's Hunt mode and its quick Milk and Shear buttons, the Mods screen's Files tab for switching off one file of a mod, and the error manager's plain-words error cards. Several more were set aside by a later mockup or by code, but no document records the drop. On the testing side, 149 surfaces were checked. 121 have checks that test what they do, 19 are only photographed and 9 have no test at all: the animal-track, farm and fluid cards, the defense summary on the Equip tab, the hidden top-left buttons, combat zoom on the bumpers and three pieces of controller plumbing. Only about 45 surfaces are tested by the unattended run, and nothing added in beta 9, 10 or 11 has been added to it yet.

How to read this:

- **BUILT**: we found the code that draws it or does it, not just a matching name.
- **PARTLY**: some of it draws; the note says what is missing.
- **NOT BUILT**: designed, and nothing in the game does it.
- **DROPPED ON PURPOSE**: a spec, a later "decided" mockup, the punch list or (marked as such) a commit records the decision. A drop with no written record is listed as NOT BUILT or PARTLY.
- Paths: mockups are under `ZeDUI/mockups/`; Lua is under `42/media/lua/client/ZeD/` unless the path says otherwise; PL = `ZeDUI/PUNCH_LIST.md`. Line numbers are as of commit 1b94da69.
- Calibration: the World window Fishing tab comes out NOT BUILT. It is designed in `zed_two_windows_v1.html:714` and `:915` and in `zed-roadmap-s65.html:240`. `WORLD_TABS` (`ZeD_WorldWindow.lua:124-160`) has no fishing entry, and `Overrides/Fishing.lua` only redraws the game's tension meter as a rod.

## Table A: designed features against the code

### A1. Gaps (NOT BUILT, then PARTLY)

| Feature | Designed | Status | Built evidence | Note |
|---|---|---|---|---|
| World window **Fishing** tab (contextual: rod, line, bait and count, skill, catch log, Cast) | zed_two_windows_v1.html:714, :915; zed-roadmap-s65.html:240; PL:4221 (#167) | NOT BUILT | No fishing entry in WORLD_TABS (ZeD_WorldWindow.lua:124-160) | Only the rod tension prop exists (Overrides/Fishing.lua:9-24). Queued for beta 12, mockup first. |
| Inventory **Filter** button, both windows | zed_two_windows_v1.html:660, :724; zed_inventory_equipped_v4 and zed_loot_multicontainer_v4 control rows; Visual Catalog v2.0 M12, O07 | NOT BUILT | No filter or search in InventoryRenderer.lua; no filter key in the English UI text | Sort and List/Grid from the same row were built. No drop record found. |
| Search or filter on the **Skills** and **Equipment** tabs | zed-roadmap-s65.html:249 | NOT BUILT | None in SkillsTab.lua or EquipmentTab.lua | Not in the punch list. |
| Animals tab: **Hunt** sub-mode | zed-animals-v2-fira.html, Frame 1 sub-tabs | NOT BUILT | AnimalsTab.lua:31 says "A Hunt sub-mode is planned but not built yet"; only Ranch and Butcher at :973-976 | Not in the punch list. |
| Animals: quick buttons on alerts (Milk, Shear, Go to) | zed-animals-v2-fira.html, Frame 1 "Needs Attention" | NOT BUILT | AnimalsTab.lua:1066-1068: "A readout: an alert is not pressed." | The mockup notes say "kept them". |
| Animals: roster bulk select ("all hungry", "all milkable") | zed-animals-v2-fira.html, Frame 2 | NOT BUILT | None in AnimalsTab.lua | Roster sort is built (:2264). |
| Animals: "Map view" from the overview | zed-animals-v2-fira.html, Frame 1 footer | NOT BUILT | None in AnimalsTab.lua | "Create zone" is built. |
| Mods info pane: **Files** tab (a mod's code files, each with an on/off switch, grouped, Find) | zed_mods_file_switches_v1.html, RECOMMEND 1 | NOT BUILT | ZeD_MainMenuMods.lua:113: the pane's tabs are about, options, sandbox, conflicts only | No drop record. |
| Files tab extras: "Used by N" before switching off, errors shown on their file, "1 file off" on the row, "Turn all back on" | zed_mods_file_switches_v1.html, RECOMMEND 2, 3, 5 | NOT BUILT | None | Depends on the Files tab. |
| "Find the file behind a problem" (switch half off, narrow it down) | zed_mods_file_switches_v1.html, RECOMMEND 4 | NOT BUILT | None | Was a "your call" item. |
| Error manager: error in plain words plus "What this usually means" | zed_errors_v1.html, RECOMMEND 2-3 | NOT BUILT | None found in ZeD_Messages.lua or ZeD_MessagesWindow.lua | |
| Error manager: "Open in Mods" (to the Files tab at the file) | zed_errors_v1.html, RECOMMEND 5 | NOT BUILT | None | Blocked by the Files tab. |
| Error manager: errors from loading marked "while loading" | zed_errors_v1.html, YOUR CALL | NOT BUILT | None found | Unsure: a recommendation, not a settled decision. |
| Messages at the desk (ZeD menu entry) and catching notes at the main menu | zed_messages_v1.html "Where it opens"; docs/specs/MESSAGES_SPEC.md:26, :50 | NOT BUILT | No Messages entry in ZeD_MainMenu*.lua | Deferred to "phase 2" in the spec, not dropped. |
| Messages: "Send to Messages" button on other mods' windows | zed_messages_v1.html "What is caught"; MESSAGES_SPEC.md:20-23 | NOT BUILT | None | Deferred to phase 2. |
| Messages: catching mods' main-menu news and changelog windows | zed_messages_v1.html; MESSAGES_SPEC.md:20-23 | NOT BUILT | None | Deferred to phase 2. |
| Split screen: ZeD's own windows for every local player | PL:2951 (#107) | NOT BUILT | ZeD_CharacterWindow.lua:3858 and ZeD_WorldWindow.lua:5872 hand players 2+ the game's windows | Players 2+ do get their own belt and dash. |
| Drawn pixel-art controller in Options, Controls | PL:2955 (#108) | NOT BUILT | ZeD_MainMenuOptionsSub.lua:271 drawPadDiagram draws plain boxes | Waiting on the art. The quick-wheel Controller map does use pixel art (ZeD_ControllerMap.lua:147). |
| Bigger Lua console, phases 1-4 (filtered log and export, scratchpad, autocomplete, server commands) | PL:3391 (#136) | NOT BUILT | ZeD_DebugConsole.lua has none of the four | Scheduled after the Nov 13 reset. The base console (#106) is built. |
| Police radar on police and sheriff dashes | PL:2758 (#93) | NOT BUILT | No "radar" in the code | Marked a future build. |
| Run and sneak on one pad button | PL:3097 (#121) | NOT BUILT | None | Design questions still open. |
| Moodle thresholds page in the guide's rules | PL:2969 (#109) | NOT BUILT | Rules pages in ZeD_SurvivalGuide.lua:526-778 cover books, food, sowing, water and attacks only | Unsure. Other #109 parts are built. |
| Pause when the game window loses focus (opt-in) | PL:2984 (#109) | NOT BUILT | None | Build was first to check whether Lua can see focus. |
| One-line "how you feel" summary | Visual Catalog v2.0 M29; zed_moodles_v1 "one-line summary (YOUR CALL)" | NOT BUILT | None | Low priority. |
| Item comparison card | Visual Catalog v2.0 O13 | NOT BUILT | None | Catalog only. |
| Reduced-motion setting | Visual Catalog v2.0 S02 | NOT BUILT | No such option in Settings.lua | |
| Tooltip hover delay and sticky mode setting | Visual Catalog v2.0 S03 | NOT BUILT | No such option | A shared hover pause exists (ZeD_Moodles.lua:20) with no setting. |
| Padlock remembers the code you set | zed_padlock_codes_v1.html, YOUR CALL | NOT BUILT | None in ObjectCardLock.lua | Optional item. |
| Themes from other mods (ZeD.Themes.register) | docs/archive/WORKSHOP_PLAN.md:137 | NOT BUILT | Only ZeD.BaseThemes (shared/ZeD/Tokens.lua:41) | Tabs are open to mods (addTab); themes are not. |
| Context-menu icon API for add-on makers | docs/specs/BETA_DECISIONS.md ("after the beta") | NOT BUILT | No register function in shared/ZeD/ContextIcons.lua | Marked for after the beta. |
| A generic ZeD look for game windows ZeD has not rebuilt | docs/specs/MP_ADMIN_SCOPE.md:168 | NOT BUILT | None; ZeD_MpLeftovers.lua rebuilds four specific windows instead | Unsure: most windows in that table got full cards instead. |
| Economy (currency, shops) | MP_ADMIN_SCOPE.md:124 | NOT BUILT | ZeD_ExtrasCards.lua:12 shows it grayed with its reason | Deferred in the spec to "its own design session". |
| Immersive chat (CB radio) | docs/specs/MP_DECISIONS.md:50 | NOT BUILT | ZeD_Chat.lua is the plain window only | Deferred in the spec to a later design pass. |
| Skill journal: Transcribe button in the key line | zed_skill_journal_v1.html, YOUR CALL | NOT BUILT | ModSupport/SkillRecoveryJournal.lua:24 says the mod keeps it on the item | Decided in a code comment only. |
| Contextual tabs as a set (Fishing, Forage, Animal) | zed-roadmap-s65.html:240 | PARTLY | Forage and Animals in WORLD_TABS (ZeD_WorldWindow.lua:141-144) | Forage is always shown (`visible` returns true, :142), Animals has no test, Fishing is missing. |
| Action strip with batch verbs under the list (Equip to region, Inspect, Mark unwanted, Transfer, Drop) | zed-roadmap-s65.html:236; zed_inventory_equipped_v4 bottom strip | PARTLY | Marks and multi-select, box select (ZeD_BoxSelect.lua:2), container moves (ContainerControls.lua:9-17) | No standing verb strip; per-item verbs live on the item card. |
| Resize dividers between container columns | zed-roadmap-s65.html:235 | PARTLY | Extra containers open as columns (ZeD_CharacterWindow.lua:362-383); dividers only between list columns (:6636, :6889) | Unsure. |
| Animals detail action strip (Grab, Milk, Pet, Rope, Rename) and 3D avatar | zed-animals-v2-fira.html, Frame 3 | PARTLY | Rename only (AnimalsTab.lua:3153); a 48px portrait (:2361-2373) | Vitals, production, breeding, genetics and family are built (:2657-2721). |
| Fishing rod prop: crafted-rod variant (no dial) and final art | zed_fish_sleep_DESIGN_BRIEF.md "Still to come"; zed_fish_sleep_death_v5 | PARTLY | Overrides/Fishing.lua:17-24 draws one store-rod strip (stand-in art) | No crafted-rod branch. |
| Journal Flyers as a collection (every flyer ever read, progress count) | zed-journal-polish-s65.html (Flyers); roadmap S65 | PARTLY | ZeD_JournalReaders.lua:6-12 lists carried papers only, with read and unread | No "ever read" list or counter. zed_reader_v1 left it a "your call". |
| Error manager: one card per place (file and line) with a repeat count | zed_errors_v1.html, RECOMMEND 1 | PARTLY | ZeD_Messages.lua:489 groups per mod and keeps 5 heads; count at ZeD_MessagesWindow.lua:162 | Grouped per mod, not per file and line. |
| Foraging stance row (Search, Crouch, Aim set the stance both ways) | docs/specs/FORAGING_SPEC.md:94, :479 | PARTLY | Search toggles (ForagingTab.lua:1227); Crouch and Aim are read-only words (:841-851) | The S71 decision said a click calls the setter. |
| Server options edited in a card | MP_ADMIN_SCOPE.md:158 | PARTLY | Read-only card (ServerTab.lua:178); AdminTab.lua:101 sends editors to the game's window | |
| Item card batch verbs (Wash, Dry, Repair all, Pad all) | docs/specs/TOOLTIP_SPEC.md:268; ZeDUI/deltas/SESSION_118_DELTA.md:70 | PARTLY | ItemCard.lua:297 repair_all, :320 pad_all, :425 wash | No Dry verb found. |
| Recipe preview card in the Journal's Recipes page | PL:1365 (#49) | PARTLY | ObjectCardPreview.lua serves Craft and Build only | The punch list notes the Journal part is not built. |
| Desk joystick ports and pad art (v5); corkboard change-note art (v6) | PL:2266 (#78); PL:2588 (#86) | PARTLY | MenuNote.lua writes the note's words | Both art sets are staged, not installed. |
| Color-blind palettes, one per kind of color blindness | Visual Catalog v2.0 S01 | PARTLY | Settings.lua:165-171: one safe set for all three kinds | One set instead of three; acceptable. |

### A2. Dropped on purpose

| Feature | Designed | Status | Built evidence | Where the decision is written |
|---|---|---|---|---|
| Moodles inside the Character window, with a click opening the linked tab | zed_two_windows_v1.html:594, :652; roadmap:238; zed_moodles_v1 | DROPPED ON PURPOSE | ZeD_Moodles.lua:3-25 places the game's moodles on the HUD; clicks pass through | zed_moodles_v2.html marked DECIDED: three HUD places, "Everything else stays vanilla". Matches the standing rule that moodles stay vanilla. |
| Moodles v1 ZeD boxes (pips, worst first) | zed_moodles_v1.html | DROPPED ON PURPOSE | ZeD_Moodles.lua:13-17 draws the game's art in the game's order | Same zed_moodles_v2 decision. |
| Separate Protection tab (Concept C) | zed_two_windows_v1 (shield tab); zed-protection-concept-c.html | DROPPED ON PURPOSE (merged) | EquipmentTab.lua:522-722 draws the defense summary in the Equip tab | docs/specs/PROTECTION_SPEC.md:4. The per-garment drill-down was not confirmed. |
| Context menu target card between strip and balloon | zed_context_unified_v1.html | DROPPED ON PURPOSE | ZeD_ContextMenu.lua:406-408 | docs/specs/CONTEXT_MENU_SPEC.md:15-16 "Target card removed entirely". |
| Item card separate Inspect window | TOOLTIP_SPEC.md:19 | DROPPED ON PURPOSE | ItemCard.lua:1934 "there is no separate inspect window" | docs/archive/PROJECT_STATE.md:14 (S118). |
| Crafting "Voltron" icon grid, category bar, pin strip with ghost slots | "ZeD-UI Crafting Tab — Final_ Voltron.htm" | DROPPED ON PURPOSE (superseded) | CraftingCore.lua:1819-1890 list with Pinned and Frequent sections | docs/specs/CRAFTING_SPEC.md:1-30 locked the list layout (S81). |
| Journal Recipes 43x43 icon grid and detail card | zed-journal-polish-s65.html | DROPPED ON PURPOSE (superseded) | JournalTab.lua:3-13 read-only recipe list | CRAFTING_SPEC.md list layout. |
| Wheel slices for the rooms editor, stopwatch, lie down; mini-map slices | docs/specs/DPAD_WHEELS_SPEC.md:59, :139-141 | DROPPED ON PURPOSE | None | Same spec: no game API; mini-map removed by the director Nov 7. |
| Simple versions for group D (notebook, balloons, desk, sleep clock, fishing reel, death alert, seat chooser, map pins, Messages note) | docs/plans/SIMPLE_VERSIONS_PROPOSAL.md:57-71 | DROPPED ON PURPOSE | None | PL:1810 (#60). The ID card later got its Simple form (#89). |
| Vehicle tab fix on small screens | PL:1889 (#61) | DROPPED ON PURPOSE | None | Director chose "leave it". |
| Pointer set (ZeD hand, drop pointers) and the pointer hint badge | zed_pointer_v1/, zed_pointer_hint_v1/; Visual Catalog v2.0 A19 cursor set | DROPPED ON PURPOSE (parked) | Probe scripts only | PL:4095-4150 (#139): the pointer cannot be swapped on the Mac; "research it later". |
| Equip doll leader lines from slot to body | zed_equip_doll_v3 "Chosen"; zed_equip_doll_v4_loadouts_r2 | DROPPED ON PURPOSE (commit only) | EquipDoll.lua header: "No leader lines point at the body" | Only commit ee3aa381 records it (director, Oct 30). Worth a punch-list line. |

### A3. Built (code confirmed)

| Feature | Designed | Status | Built evidence |
|---|---|---|---|
| Two windows: Character ("me and my stuff") and World | zed_two_windows_v1.html header | BUILT | ZeD_CharacterWindow.lua, ZeD_WorldWindow.lua |
| Character tabs: Loot, Equip, Health, Thermal, Identity, Journal, Skills, contextual Radio | zed_two_windows_v1 tab icons; roadmap matrix | BUILT | CHAR_TABS, ZeD_CharacterWindow.lua:689-708 |
| World tabs: Loot, Craft, Build, Furniture, Maps, Forage, Animals, Radio, Vehicle | zed_two_windows_v1 | BUILT | WORLD_TABS, ZeD_WorldWindow.lua:124-160 |
| List and Grid view, remembered per container | zed_two_windows_v1.html:664; zed_inventory_grid_v1 | BUILT | InventoryRenderer.lua:329, :361-448, :751-755 |
| Grid cells (icon, count, weight, condition), drag, card, D-pad cell to cell | zed_inventory_grid_v1 RECOMMEND 2-7 | BUILT | InventoryRenderer.lua grid section; Input/FocusManager.lua:41 |
| Sort by column; folding category groups | zed_inventory_token_reference; Catalog M11 | BUILT | InventoryRenderer.lua:1015, :1207, :1297 |
| One COND / AMT column | PL:3990 (#152) | BUILT | InventoryRenderer.lua:62, :1487, :1564 |
| Take all, Transfer all, Same type, To floor, Drop all | zed_two_windows_v1.html:666; zed_container_controls_v2 | BUILT | ContainerControls.lua:9-17, :234-296 |
| Container's own buttons (fire, stove power, washer, trunk, Delete all) with hover hints | zed_loot_multicontainer_v4; zed_container_controls_v2 | BUILT | ContainerControls.lua:11-29, :609, :774-1024 (kept in the bottom row, per its comment :4-6) |
| Container strip and multi-container columns | zed_loot_multicontainer_v4 | BUILT | ZeD_CharacterWindow.lua:362-383 |
| Cross-window drag and drop; several chips when dragging several items | roadmap:239; PL:4211 (#166) | BUILT | InventoryRenderer.lua:2730; Molecules.lua:1209-1271 |
| Window shade (collapse to title); window curtains (a side rolls up, map as minimap) | zed_two_windows_v1.html:740; zed_curtains_v1 | BUILT | ZeD_CharacterWindow.lua:3865; WindowCurtain.lua:51, :254-279 |
| Dual pinning, title-bar pins (three at most) | PL:3015 (#112); zed_title_pins_v1 | BUILT | WindowHalves.lua; ZeD_Pins.lua; ZeD_CharacterWindow.lua:3772-3780 |
| Controller multi-select in the inventory | PL:1127 (#44) | BUILT | ZeD_CharacterWindow.lua:430; ZeD_WorldWindow.lua:2129 |
| Fast looting: hover stats, box select | PL:3758 (#146) | BUILT | ZeD_InvTip.lua; ZeD_BoxSelect.lua |
| Item card in the drawer: sticky head, folds that persist, nutrition label, zones | ZeD_ItemCard_220w_Hybrid.jsx | BUILT | ItemCard.lua:708, :1041, :1178-1190; ItemCardOrganism.lua:64-69 |
| Item card at 220 and 480 wide across item types (Facts panels) | equipment_card_redesign_v15 | BUILT | ItemFactsPanel.lua:1-20; ItemCardOrganism.lua:242 |
| Item card marks (Favorite, Protect, Unwanted) and the Lists button | equipment_card_redesign_v9; zed_equip_doll_v4_loadouts_r2 | BUILT | ItemCard.lua:1327, :1608, :1843 |
| Item card progress band with danger and cancel | equipment_card_redesign_v16 | BUILT | ItemCard.lua:843, :1273; ItemCardOrganism.lua:659, :830 |
| Item card rename, soiled flags, zone detail | TOOLTIP_SPEC.md; docs/archive/NEXT_SESSION_HANDOFF_20260503.md | BUILT | ItemCard.lua:630-838 |
| "Used to make" on the item card | PL #109, #153 | BUILT | ItemCard.lua:1873 |
| Defense summary (letter grade, worst and best zone, garments) | zed-protection-concept-c.html | BUILT | EquipmentTab.lua:668-722 |
| Equip doll: list/doll toggle, 38 small slots, condition bars, drop to wear | zed_equip_doll_v3; v4_loadouts_r2 | BUILT | EquipDoll.lua:122-146, :604 |
| Body figure hit test, attachment slots | roadmap:234 | BUILT | ZeD_BodyFigure.lua; EquipDoll.lua:7-16 |
| Loadouts page in the Journal; Equip loadouts bar; missing items drawn faint; days to-do | zed_equip_doll_v4_loadouts_r2 | BUILT | ZeD_JournalLists.lua:797; ZeD_EquipLoadout.lua:431 |
| Restock three ways; unpack at home; save to loadout or outfit from the menu | v4_loadouts_r2 | BUILT | ZeD_Restock.lua:26, :971; ZeD_EquipLoadout.lua:906; ZeD_ListsMenu.lua:133 |
| Themes (Dark, Light, High contrast) with nine accents and text sizes, changed live | zed_inventory_token_reference; roadmap:248, :250 | BUILT | shared/ZeD/Tokens.lua:43-310; Settings.lua:127-147 |
| 15-tone type scale | zed_15tone_list.html | BUILT | Tokens toneNorm and toneLo, e.g. EquipmentTab.lua:683-690 |
| Atom and molecule library | ZeD-UI_Visual_Catalog_v3.jsx; Visual Catalog v2.0 | BUILT | Atoms.lua, AtomExtensions.lua, Molecules.lua (not checked atom by atom) |
| Secondary text dimmer than body text in Dark | zed_textsec_v1/ | BUILT | Tokens.lua (PL #160) |
| Paper toned down to 70% | paper_tone/ | BUILT | PL:3133-3137 (#124) |
| Color-blind status colors | PL:3561 (#144) | BUILT | Settings.lua; ZeD_MainMenuOptionGroups.lua |
| Context menu as an icon strip with bumpers and a balloon; list style offered | zed_context_unified_v1; zed_gamepad_context_linear_v1; CONTEXT_MENU_SPEC.md | BUILT | ZeD_ContextMenu.lua:1-19, :87, :226; ZeD_ContextList.lua |
| Tooltips as Balloon Help (tail, anchored, requirement balloon, list-side balloon, moodle hover) | zed_tooltips_balloon_v1; ZeDUI/HANDOFF_design_tooltips_balloon_20261108.md | BUILT | Balloon.lua:33-37, :142-181, :391, :436-532; RichTip.lua; ZeD_Moodles.lua:554-559 |
| Strip end arrows in the accent | zed_tooltips_balloon_v1 section 5 | BUILT | AtomExtensions.lua:557-566 (accent fill unsure) |
| Menu marks on paired actions; new Eat, Sneak, Safehouse icons | ZeDUI/HANDOFF_design_menu_marks_eat_20261109.md; zed_menu_marks_v1/ | BUILT | Atoms.lua:330-338; shared/ZeD/ContextPxIcons.lua:183, :402-464 |
| Menu, strip, list and wheel icon sets | zed_menu_icons_v1/, zed_strip_icons_v1/, zed_list_icons_v1/, zed_wheel_icons_v1/ | BUILT | textures/ZeD/wheel; shared/ZeD/ContextPxIcons.lua |
| Crafting: one Craft/Build core, search, alternatives pane, owned only, quantity, sort, craft card | zed-crafting-unified-v1.html; CRAFTING_SPEC.md | BUILT | CraftingCore.lua:872, :1127, :1232, :1269-1289, :2308, :2429 |
| Crafting pins and Frequently used (as list sections) | Voltron; Catalog O08, O09 | BUILT | CraftingCore.lua:558-629, :1854-1890 |
| Stations in the Craft tab (band, machine panel, oven, "Needs a station") | zed_stations_v1 | BUILT | Stations.lua; StationMachine.lua:6-18; StationAppliance.lua:3-9 |
| Build and Craft preview card | PL:1365 (#49) | BUILT | ObjectCardPreview.lua |
| Cooking tab: dish and base, ingredients, count, Make, saved dishes, swap a missing ingredient | docs/plans/COOKING_TAB_DRAFT.md; PL #80 | BUILT | CookingTab.lua:45, :301-328, :492-602, :774-800, :886 |
| Animals Ranch overview, zone roster, animal detail, Butcher | zed-animals-v2-fira Frames 1-4 | BUILT | AnimalsTab.lua:10-28, :975, :1130-1589, :2657-2721 |
| Animal cards: hutch, trough, butcher hook, tracks with compass | zed_animal_cards_v1 | BUILT | ObjectCardHutch, ObjectCardTrough, ObjectCardHook, ObjectCardTrack.lua; Overrides/Animals.lua |
| Trailer animals page | zed_trailer_animals_v1 | BUILT | MechTrailer.lua:5-11, :443 |
| Foraging tab: hero, More detail, categories, modifiers, focus drop-down, recent finds with bearing | zed-foraging-quiet-v5 (tokens only); FORAGING_SPEC.md | BUILT | ForagingTab.lua:25-46, :101-137, :226-405 |
| Furniture tab (modes, may yield, cursor chip, placement card) | zed_furniture_v1 | BUILT | FurnitureTab.lua:18, :942-944; ObjectCardPlacement.lua |
| Maps tab: annotation toolbar, inks, notes, stash and flyer dots | roadmap S65 Maps | BUILT | MapsTab.lua:3-7 |
| Map key (incl. Paper style), drawing, symbol size, other players, learned notes, area name | zed_map_overlays_v1 | BUILT | MapsTabKey.lua:33-66; MapsTab.lua:389, :1155; ModSupport/DRAW_ON_MAP, MapSymbolSizeSlider, POM, BLTAnnotations, BB_WhereAmI |
| Vehicle tab: list and diagram columns, sort gated at Mechanics 4, missing parts kept, diagram lights and clicks, part card | zed_vehicle_mechanics_v1; docs/specs/VEHICLE_TAB_SPEC.md | BUILT | MechanicsTab.lua:317-326, :1155, :1490, :1551, :2038-2156 |
| Pixel-art car diagrams (13 shapes) | VEHICLE_TAB_SPEC.md section 3 | BUILT | MechFigs.lua |
| Radio and TV drawer (faces, presets, signal, CD, TV, VCR) | zed_radio_tv_drawer_v1 + SPEC; zed_radio_tv_v1/ | BUILT | RadioTab.lua:1-37, :227, :745; RtvFace.lua:9-52, :635 |
| Two-way radios: walkie and ham faces, full view, narrow ham | zed_twoway_v1/; zed_ham_narrow_v1 | BUILT | TwoWayFace.lua:142, :380; TwoWayFull.lua |
| Car radio up close | zed_car_radio_v1 | BUILT | ZeD_CarRadio.lua:79-87; Overrides/CarRadio.lua |
| CaZio, Timez and Rollex watches; mini watch on the belt | zed_cazio_watch_v1..v5; zed_belt_watch_v1 | BUILT | ZeD_Watch.lua:9-28, :476; WatchMini.lua:173 |
| Vehicle dashboards, round 6, Oct 29 fixes; lamps, odometer, trip on all 19; Roadworthy | zed_dashboard_v1..v5, zed_dashboard_r6/; HANDOFF_design_dash_indicators and _roadworthy | BUILT | ZeD_Dashboard.lua:69-93, :292, :875; DashPx.lua:79-80; ModSupport/VSKDash.lua |
| Seat chooser and siren controller | zed_seats_lightbar_v1 | BUILT | ZeD_SeatChooser.lua:3-6; ZeD_SirenController.lua |
| Machine plates at four widths, 336 and fill | zed_plates_336_v1, plates_fill/; docs/specs/PLATE_SIZES_SPEC.md | BUILT | textures/ZeD/physpx (PL #3) |
| Fluid card | zed_fluids_v1 | BUILT | ObjectCardFluid.lua; Overrides/Fluids.lua |
| Info cards: generator, fires, farm plot | zed_info_cards_v1 | BUILT | ObjectCardPower.lua, ObjectCardFire.lua, ObjectCardFarm.lua |
| Laundry faces | zed_laundry_v1/ | BUILT | ObjectCardLaundry.lua |
| Padlock card | zed_padlock_codes_v1 | BUILT | ObjectCardLock.lua; Overrides/Padlocks.lua |
| Belt: slots round the buckle, hands at the ends, condition rings in segments, hand icons, hands together | zed_hands_belt_v1..v3; zed_belt_hands_together_v1; PL #149, #155 | BUILT | ZeD_Belt.lua:63-67, :621, :1014-1033, :2141 |
| Ammo box on the belt; dash lamps only for worn parts | zed_belt_ammo_dash_v1 | BUILT | ZeD_Belt.lua:649; ZeD_Dashboard.lua:292 |
| Action bar, Simple and Verbose | zed_action_bar_v2 | BUILT | ZeD_ActionBar.lua:469-501 |
| Prompts and dialogs; ZeD keyboard | zed_dialogs_v1 | BUILT | ZeD_Prompt.lua:9-81; ZeD_Keyboard.lua |
| Radial wheels as strip cells on a ring | zed_wheels_v1 | BUILT | ZeD_Wheel.lua:96-124; Overrides/Wheels.lua |
| D-pad wheels (Character, World, Social, Here and now, ZeD), gestures, wheel settings, Loadouts ring | zed_dpad_wheels_v2; DPAD_WHEELS_SPEC.md; RADIAL_WHEELS_SPEC.md | BUILT | ZeD_DpadWheels.lua:942-979, :1514; ZeD_WheelGesture.lua:77-113; Settings.lua:485-498 |
| Quick chords (12), ZeD button pictures, put things back | zed_quick_chords_v1; QUICK_CHORDS_SPEC.md | BUILT | ZeD_QuickChords.lua; ZeD_PadGlyphs.lua; ZeD_PutBack.lua |
| Controller map page | PL:2058 (#67) | BUILT | ZeD_ControllerMap.lua |
| Gamepad flat free navigation; controller highlight style | GAMEPAD_SPEC.md; zed_cohesion_v1 | BUILT | Input/FocusManager.lua; Input/SpatialNav.lua; ZeD_FocusPaint.lua:217 |
| Cohesion: see-through slider, "solid while in use", hidden actions | zed_cohesion_v1; COHESION_SPEC.md | BUILT | Organisms.lua:64, :378; Molecules.lua:4961 |
| Sleep clock radio; death alert | zed_fish_sleep_death_v5 | BUILT | Overrides/Sleeping.lua; Overrides/PostDeath.lua:9-13 |
| Fishing rod tension prop (store rod) | zed_fish_sleep_death_v5 | BUILT | Overrides/Fishing.lua:83, :140-147 (stand-in art) |
| Reader: full window, Paper and Words, Show on map, notebook page, locked notebook | zed_reader_v1, zed_reader_v2 | BUILT | ZeD_Reader.lua:199, :424-434, :547 |
| Journal: diary, Papers and Notebooks sub-tabs, quick note | zed-journal-polish-s65; zed_reader_v2 | BUILT | JournalTab.lua:74-123; ZeD_JournalReaders.lua:619 |
| Read marks | zed_read_marks_v1 | BUILT | ReadMarks.lua:280 |
| Skill Recovery Journal strip; Traits tab for Traits As Skills | zed_skill_journal_v1; zed_traits_tab_v1 | BUILT | ModSupport/SkillRecoveryJournal.lua:211; ModSupport/traitsAsSkills.lua:756 |
| Spongie's appearance tab and Looks rows | zed_spongie_appearance_v1 | BUILT | ModSupport/SPNCC.lua:994; ZeD_MainMenuLooks.lua:171 |
| Identity: license wide and narrow, Simple, weight trend, permit; hair and beard | zed_identity_v2; zed_hair_beard_v1; PL #89 | BUILT | IdentityTab.lua:405-1521; ZeD_HairBeard.lua:1048 |
| Portrait studio | PL:3580 (#145) | BUILT | ZeD_Studio.lua |
| Simple versions: belt, devices, walkies and hams, car radio, appliances, grill and generator, laundry, watch, dash, siren, guide, mods, identity, in one "Full or simple" group | SIMPLE_VERSIONS_PROPOSAL.md; PL #17, #56, #60, #110 | BUILT | Settings.lua:567-643; PlainFace.lua; StationAppliance.lua:531; ObjectCardLaundry.lua:373; ZeD_Watch.lua:473; ZeD_Dashboard.lua:1380 |
| Survival guide, Simple and Full (book) looks, new chapters, spoiler bars, ads, copyright page, opening bubble, hidden facts | zed_survival_guide_v7; SURVIVAL_GUIDE_CHAPTERS.md; GUIDE_ADS_PLAN.md; PL #82, #83, #98, #103, #109, #122 | BUILT | ZeD_SurvivalGuide.lua:483-976; ZeD_SurvivalGuideBook.lua:14, :922; ZeD_GuideChapters.lua; ZeD_GuideBubble.lua; ZeD_HiddenFacts.lua |
| Messages window, toasts, belt envelope, per-mod error count, bug report in two presses | zed_messages_v1; MESSAGES_SPEC.md; zed_errors_v1 RECOMMEND 4; PL #66 | BUILT | ZeD_MessagesWindow.lua:197, :350; ZeD_Messages.lua:26-84, :549-676 |
| Overhead speech bubbles; overhead notes into Messages | zed_bubbles_v1/; PL #85 | BUILT | ZeD_Bubbles.lua:339; ZeD_HaloText.lua |
| ZeD setup in groups, switches, swatches, scale slider, changed marks, start from defaults | zed_settings_v2 | BUILT | ZeD_MainMenuOptionGroups.lua; ZeD_MainMenuOptions.lua:595, :1023-1171, :1860 |
| Sandbox options in game (pages, tags, Apply, History, Undo, Find) | zed_sandbox_ingame_v1; SANDBOX_INGAME_SPEC.md | BUILT | ZeD_SandboxInGame.lua:16-153, :418-428, :565; ZeD_SandboxNotes.lua |
| Main menu desk, pause menu, saves with footer Delete | zed-main-menu-crt-v7_1; zed_main_menu_v9 | BUILT | ZeD_MainMenu.lua:3-25; ZeD_MainMenuSaves.lua:16-21, :158-171 |
| Desk notes, Pasties, Mail apps; Mod Uploader icon; soda can | PL #104, #114, #142; zed_mod_uploader_icon_v1; zed_orange_soda_can_v1 | BUILT | ZeD_DeskNotes.lua; ZeD_MainMenuNotes.lua; ZeD_MainMenuMail.lua; ZeD_MainMenuDesktop.lua:63-65 |
| Small-screen menu lean-in | zed_small_screens_v1/ | BUILT | Overrides/TextScale.lua:207 |
| Mod manager (Conflicts, Workshop state, upload screen, description editor) | zed_mod_manager_v1 | BUILT | ZeD_MainMenuMods.lua:31-34, :1582; ZeD_MainMenuWorkshop.lua; ZeD_MainMenuDescEdit.lua |
| Mods info pane tabs (About, Options, Sandbox, Conflicts); file picks with Undo | zed_mods_settings_picks_v1 | BUILT | ZeD_MainMenuModsPanes.lua:284, :474, :614, :700 |
| Mod folders, separators, Find, load first and last pins, load-after rules | zed_mod_folders_v2; MOD_FOLDERS_SPEC.md; MODS_LOAD_ORDER_SPEC.md | BUILT | ZeD_ModFolders.lua; ZeD_MainMenuModsSeps.lua:3-24; ZeD_ModOrder.lua:7-20, :711 |
| Mods readability: on/off rows, Off tab, hide incompatible, Simple view, folder colors | zed_mods_readability_v1; PL #84 | BUILT | ZeD_MainMenuMods.lua:106, :183, :1273; Settings.lua:628-632 |
| Workshop page with the real gallery | zed_workshop_page_v3 | BUILT | ZeDUI/tools/release (outside the game) |
| Tickets, player side and admin queue | zed_tickets_v2; MP_ADMIN_SCOPE.md:34-49 | BUILT | ZeD_Tickets.lua:272-330; ZeD_TicketCards.lua:322-386 |
| Admin tab: players, player card, roles, bans, spawn items, repeating messages, grayed reasons, more tools | zed_admin_tools_v1; MP_ADMIN_SCOPE.md:57-81 | BUILT | AdminTab.lua:96-111, :517; ZeD_AdminCards.lua:87-1794; ZeD_AdminTools.lua; ZeD_AdminZones.lua:141 |
| Safehouse, faction and wars cards; can-I-claim; rules in plain words; invitations as notes | zed_safehouse_faction_v1; MP_ADMIN_SCOPE.md:82-96 | BUILT | ZeD_ClaimCards.lua:3-12; ZeD_Claims.lua; ServerTab.lua |
| Log card, Around ticket, PvP log | zed_logs_v1; MP_ADMIN_SCOPE.md:97-111 | BUILT | ZeD_LogCards.lua:5-9; ZeD_Log.lua |
| Join screen (message of the day, rules, appeal line); rules and news editor; Server tab news | zed_community_v1; MP_ADMIN_SCOPE.md:113-125 | BUILT | ZeD_CommunityCards.lua; ZeD_Community.lua; ServerTab.lua |
| Ban and kick screen with reason | MP_ADMIN_SCOPE.md:115 | BUILT | ZeD_AdminCards.lua:542-601 |
| Chat window, chat key and PvP marker on the belt, report and mute from a line; Server tab | HANDOFF_design_multiplayer_20261105.md; MP_DECISIONS.md | BUILT | ZeD_Chat.lua:3-14, :658; ZeD_Belt.lua:507, :920; ServerTab.lua:107-125, :574 |
| Server extras (vehicle claims, safehouse protection, staff teleport, container log) | zed_community_v1; MP_ADMIN_SCOPE.md Phase 6 | BUILT | ZeD_Extras.lua:9-160; ZeD_ExtrasCards.lua:430 |
| Mark sharing, edit item, server-saving notice | MP_ADMIN_SCOPE.md pop-up table | BUILT | ZeD_MpLeftovers.lua |
| Step aside for a mod that takes a screen | PL:1691 (#55) | BUILT | ZeD_StepAside.lua |
| Mod support: This Is Your Life, Immersive Searching, Minimal Sidebar | PL #64, #40, #111 | BUILT | ModSupport/ThisIsYourLife.lua, ImmersiveSearching.lua, MinimalSidebar.lua |
| Machine translations for every language | PL:1905 (#62) | BUILT | 28 folders in shared/Translate |
| Loot tab's placeholder card removed | PL:4162 (#156) | BUILT | ZeD_WorldWindow.lua:92 |
| Skill unlocks on the skill card | PL:2968 (#109) | BUILT | RecipeIndex.lua:374 |

## Table B: test coverage by surface

How each surface was graded:

- **COVERED**: at least one QA script prints pass or fail, or makes several value checks of its own, for that surface.
- **SHOT ONLY**: scripts only take pictures, print values for a person to read, or catch Lua errors.
- **NOT COVERED**: no script names it.
- Checks that run offline against stand-ins are marked "sim"; they count as covered but never ran in the game.
- **[R]** means the script is in `ZeDUI/tools/qa/regression.txt`, the unattended run (101 scripts, 42 with real checks; last changed Nov 8).
- The main menu is outside the unattended run by design.

### B1. Gaps (NOT COVERED, then SHOT ONLY)

| Surface | Code | Coverage | Scripts | Note |
|---|---|---|---|---|
| Object card: animal tracks | ObjectCardTrack.lua:155 | NOT COVERED | none (zedqa_deep_run only stages objects) | |
| Object card: farm plot | ObjectCardFarm.lua:640 | NOT COVERED | gallery_farm_ranch (picture), zedqa_deep_run (setup) | |
| Object card: fluid container | ObjectCardFluid.lua:376 | NOT COVERED | zedqa_two_widths [R] may reach it in passing | #151 checked only on the loot card (fast_loot_sim). |
| Defense summary in the Equip tab | EquipmentTab.lua:523; ProtectionTab.lua | NOT COVERED | drawer_tabs_perf_sim, perf_throttles_sim (speed only) | Nothing checks what it shows. |
| Game's top-left buttons hidden | Overrides/ScreenIcons.lua:32 | NOT COVERED | none | |
| Pad bumpers: combat zoom | Input/BumperChord.lua:263 | NOT COVERED | none | |
| Pad action map | Input/ActionMap.lua:275 | NOT COVERED | none directly | |
| Input mode detector (mouse or pad) | Input/InputModeDetector.lua:276 | NOT COVERED | stubbed in community_cards_sim only | |
| Text scale override | Overrides/TextScale.lua | NOT COVERED | perf_now, perf_census (measurements) | |
| World Furniture tab (pick up, place, rotate, scrap, repair) | FurnitureTab.lua:37 | SHOT ONLY | zedqa_furniture [R], zedqa_testlang [R] | No mode checks. |
| Object card: placement | ObjectCardPlacement.lua:106 | SHOT ONLY | zedqa_furniture [R], zedqa_padmap | |
| Object cards: hutch and trough | ObjectCardHutch.lua:287; ObjectCardTrough.lua:322 | SHOT ONLY | gallery_farm_ranch, zedqa_b8_animals (manual step) | |
| Object card: campfire | ObjectCardFire.lua:554 | SHOT ONLY | zedqa_container_controls [R], zedqa_container_bottom [R] | |
| Container buttons (Same type, Take all, Transfer all, To floor) | ContainerControls.lua:200 | SHOT ONLY | zedqa_container_controls [R], zedqa_container_bottom [R], zedqa_container_controls_captures [R] | |
| Journal: diary | JournalTab.lua:113 | SHOT ONLY | zedqa_journal_refs [R], zedqa_visual_audit | |
| Journal: Recipes | JournalTab.lua:117 | SHOT ONLY | zedqa_testlang [R], zedqa_uncovered21 (Page pop-up only) | |
| Clock-radio and rod plates | RadioPlates.lua:195 | SHOT ONLY | zedqa_props_plates [R] | |
| Siren controller | ZeD_SirenController.lua:55; SirenPlate.lua | SHOT ONLY | zedqa_dash_props_smoke [R], zedqa_seats_build | |
| Car radio (close view, CD deck) | ZeD_CarRadio.lua:112 | SHOT ONLY | zedqa_car_radio_build [R], zedqa_car_radio_cd [R] | |
| Seat chooser and lightbar | ZeD_SeatChooser.lua:102; Overrides/Seats.lua:23 | SHOT ONLY | zedqa_seat_lightbar_vanilla [R], zedqa_seats_build | |
| Fishing rod prop | Overrides/Fishing.lua:68 | SHOT ONLY | zedqa_fishing [R] | The Fishing tab is not built. |
| Sleep clock | Overrides/Sleeping.lua:44 | SHOT ONLY | zedqa_prompts [R], zedqa_death_sleep (never unattended) | |
| Newspaper fit and typesetting | ZeD_PrintPage.lua:294; Overrides/PrintMedia.lua:22 | SHOT ONLY | zedqa_print_fit [R], zedqa_print_typeset [R] | |
| Corkboard change note | ZeD_MainMenu.lua:533; MenuNote.lua | SHOT ONLY | zedqa_menu_note, zedqa_menunote_shot | Beta 11 and 12 headings never checked. |
| Workshop description editor | ZeD_MainMenuDescEdit.lua:48 | SHOT ONLY | gallery_v4_menus, zedqa_workshop_upload (never unattended) | |
| Garment override | Overrides/Garment.lua | SHOT ONLY | zedqa_button_case_game [R] | |
| Belt art: strap, buckles | ZeD_Belt.lua:877 | SHOT ONLY | zedqa_belt_strap [R], zedqa_straps [R], zedqa_buckles [R] | |
| Window tab-strip icons | ZeD_TabPx.lua:41 | SHOT ONLY | zedqa_tabicons [R], zedqa_tabs_lit [R] | |

### B2. Covered

| Surface | Code | Coverage | Scripts | Newer parts no check reaches / note |
|---|---|---|---|---|
| Character Loot tab (list, sort, weights) | ZeD_CharacterWindow.lua:692 | COVERED | zedqa_sort_groups [R], zedqa_wt_bracket [R], zedqa_two_widths [R] | #156, #157 only in zedqa_b11_notes (not [R]). |
| Loot grid view | InventoryRenderer.lua:41 | COVERED | zedqa_grid [R], zedqa_sort_groups [R] | #162 stack bar: b11_notes and sim only. |
| COND/AMT column, item meter | ItemMeter.lua; ItemFactsPanel.lua | COVERED (sim) | item_meter_sim, inv_model_sort_sim, zedqa_b11_notes | #152 not in [R]. |
| Fast looting: hover card, box select, Ctrl+A | ZeD_BoxSelect.lua:85; ZeD_InvTip.lua:81 | COVERED (sim) | fast_loot_sim, belt_mods_sim | #146 has no in-game check. |
| Drag chips | Molecules.lua:1267 | COVERED (sim) | drag_cascade_sim | #166 (beta 12). |
| Equip tab and doll | EquipmentTab.lua:1662; EquipDoll.lua | COVERED | zedqa_doll_v4 [R], zedqa_equipdrag [R], zedqa_b9a_5 | |
| Equip belt rows | EquipmentTab.lua:870 | COVERED | zedqa_world_pad_take [R], zedqa_b9a_5 | |
| Loadouts, restock, restock pin | ZeD_EquipLoadout.lua:255; ZeD_Restock.lua:250; ZeD_RestockPin.lua:46 | COVERED | zedqa_restock [R], zedqa_lists [R], restock_scan_sim | |
| Lists and list menu | ZeD_Lists.lua:156; ZeD_ListsMenu.lua:65; ZeD_JournalLists.lua:797 | COVERED | zedqa_lists [R], menu_marks_sim | #140 outfit and loadout icons: sim only. |
| Health tab | HealthTab.lua:1684 | COVERED | zedqa_charinfo [R], zedqa_exinfo [R], zedqa_b8_wounds | #148 (percent cut at the drawer edge): no check. |
| Health: exercise | HealthTab.lua:802 | COVERED | zedqa_exinfo [R], zedqa_uncovered21 | |
| Health: click to treat | HealthTab.lua:623 | COVERED | woundsov_sim, zedqa_b8_wounds, zedqa_card_pad [R] (smoke) | Not checked in [R]. |
| Thermal tab (7 views) | ThermalTab.lua:39 | COVERED | zedqa_uncovered21, zedqa_testlang [R], drawer_tabs_perf_sim | No view values checked in [R]. |
| Identity tab (license, traits) | IdentityTab.lua:722, :888, :1401 | COVERED | zedqa_identity, zedqa_identity2, zedqa_identity_half | Not in [R]; #147 permit stamp spacing: no check. |
| Identity: hair and beard | ZeD_HairBeard.lua:657 | COVERED | zedqa_hairbeard, zedqa_hairbeard_tools | Not in [R]. |
| Portrait studio | ZeD_Studio.lua:57 | COVERED (sim) | studio_sim | #145: no in-game check. |
| Journal: Notebooks and Papers | ZeD_JournalReaders.lua:619 | COVERED | zedqa_journal_readers [R], zedqa_notebook_paper | #164 gray box: sim only. |
| Journal: Loadouts | JournalTab.lua:119 | COVERED | zedqa_lists [R] | |
| Kill tracker | KillTracker.lua | COVERED | kills_sim, zedqa_kills_kind, zedqa_kills_match | Not in [R]. |
| Skills tab | SkillsTab.lua:1434 | COVERED | zedqa_segbars [R], zedqa_srj, zedqa_exprecovery | #141, #143 segments: sim only; zedqa_segbars predates #143 and may be stale. |
| Skills: training materials | SkillsTab.lua:355 | COVERED | zedqa_b8_recipes, zedqa_guide82 | Not in [R]. |
| Radio tab: two-way and radio/TV faces | RadioTab.lua:1087; TwoWayFace.lua:380; RtvFace.lua:635 | COVERED | zedqa_twoway [R], zedqa_rtv [R] | #140 preset "+" in the accent: no check. |
| Simple device cards | PlainFace.lua:757 | COVERED | zedqa_plain_cards | Not in [R]. |
| Cooking tab | CookingTab.lua:1148 | COVERED | zedqa_cook80, tab_drain_sim, mp_cook | Not in [R]. |
| Server tab | ServerTab.lua:574 | COVERED | mp_srvtab, mp_srvtab2, ticket_cards_sim | Multiplayer only. |
| Traits tabs (Evolving Traits World, Traits As Skills) | ModSupport/EvolvingTraitsWorld.lua:1588; traitsAsSkills.lua:1012 | COVERED | zedqa_etw, zedqa_traits | Need their own mod lists. |
| Spongie's tab | ModSupport/SPNCC.lua:1171 | COVERED | zedqa_spncc, zedqa_spncc_looks | Own mod list. |
| Craft tab | CraftingTab.lua:639 | COVERED | zedqa_appliances [R], zedqa_preview_card, zedqa_b8_recipes | #153: sim only. |
| Build tab | BuildingTab.lua:451 | COVERED | zedqa_preview_card, craft_rows_perf_sim | Only pictures in [R]. |
| Recipe preview card | ObjectCardPreview.lua:420 | COVERED | zedqa_preview_card, zedqa_ws_preview | Not in [R]. |
| Maps tab (styles, notes, pop-out) | MapsTab.lua:286, :2258 | COVERED | zedqa_mapnotes [R], zedqa_two_widths [R], zedqa_mapkey | #134 Custom Map Labels: probe only, unresolved. |
| Map key, map-mod hooks | MapsTabKey.lua; MapsTabExt.lua | COVERED | zedqa_mapkey, zedqa_mapmods | |
| Paper map | PaperMap.lua:54 | COVERED | paper_map_sim, zedqa_b8_paper_map | Not in [R]. |
| Flyer map and flyers | FlyerMap.lua:159 | COVERED | zedqa_flyerclip; zedqa_flyermap [R] and zedqa_flyers [R] are pictures | Checks are outside [R]. |
| Forage tab | ForagingTab.lua:1286 | COVERED | zedqa_probe_compass, zedqa_uncovered21, zedqa_curtain [R] (tab switch) | |
| Animals tab (ranch, butcher, zones) | AnimalsTab.lua:973; ZeD_ZoneList.lua:31 | COVERED | zedqa_animals_page, zedqa_animals_list, zedqa_b8_animals | Not in [R] (setup cannot run unattended). |
| Vehicle tab | MechanicsTab.lua | COVERED | zedqa_mech79, world_refresh_sim, zedqa_r3_D_cars | Not in [R]. |
| Trailer animals | MechTrailer.lua:97 | COVERED | zedqa_mech79, zedqa_compat_vehicles | |
| Admin tab and admin screens | AdminTab.lua:517; ZeD_Admin*.lua | COVERED | admin_sim, admin_cards_sim, mp_admin | #130, #123: sims only. |
| Item card | ItemCard.lua:694 | COVERED | zedqa_world_pad_take [R], card_model_sim, zedqa_b9a_7 | suite_verbs [R] prints values only. |
| Object cards frame | ObjectCards.lua:148 | COVERED | zedqa_laundry [R], zedqa_plates_336 [R] | |
| Laundry card | ObjectCardLaundry.lua:189 | COVERED | zedqa_laundry [R] | |
| Generator card | ObjectCardPower.lua:689 | COVERED | zedqa_plates_336 [R], zedqa_plates_fill | |
| Padlock card | ObjectCardLock.lua:307 | COVERED | zedqa_world_pad_take [R], zedqa_m1_cards | |
| Medic card; trade card and window | ObjectCardMedic.lua:48; ObjectCardTrade.lua:66; ZeD_Trade.lua:83 | COVERED | trade_medic_sim, zedqa_b8_mp_medic, zedqa_b8_mp_trade | Multiplayer. |
| Butcher-hook card | ObjectCardHook.lua:55 | COVERED | zedqa_b8_station | Not in [R]. |
| Stations | Stations.lua:507; StationPopout.lua:35 | COVERED | zedqa_plates_336 [R], zedqa_appliances [R] | |
| Loot card | ZeD_LootCard.lua:289 | COVERED (sim) | fast_loot_sim, belt_mods_sim | #135, #146, #151: no in-game check. |
| Form card | ZeD_FormCard.lua:52 | COVERED (sim) | mp_leftovers_sim, zedqa_b8_mp_leftovers | |
| Belt and hands | ZeD_Belt.lua:877 | COVERED | zedqa_hands_together [R], zedqa_ring_squares [R], zedqa_b11_notes | #155 hand icons: b11_notes only; #149 rings: sim only. |
| Action bar | ZeD_ActionBar.lua:501 | COVERED | zedqa_food_verbs [R], action_bar_name_sim | |
| Dashboards (incl. pixel art) | ZeD_Dashboard.lua:720; DashPx.lua:1876 | COVERED | zedqa_dash_keys_edge [R], zedqa_dash_brands [R], zedqa_dash_green [R], dash_odo_sim | |
| Roadworthy dash | ModSupport/VSKDash.lua:96 | COVERED | zedqa_roadworthy, vskdash_sim | Own mod list. |
| Watches, mini watch, watch plates | ZeD_Watch.lua:400; WatchMini.lua:173; WatchPlates.lua:806 | COVERED | zedqa_watches2 [R], zedqa_cazio_light [R] | |
| Moodles | ZeD_Moodles.lua:234 | COVERED | zedqa_moodles [R], zedqa_moodle_quarters | |
| Main menu: desk | ZeD_MainMenuDesktop.lua:177 | COVERED | desk_sim, zedqa_menu_lean, zedqa_desktop_uploader | |
| Main menu: saves | ZeD_MainMenuSaves.lua:151 | COVERED | zedqa_menu_bars, zedqa_menu_questions | |
| Main menu: host, server settings | ZeD_MainMenuHost.lua:53; ZeD_MainMenuServer.lua:168 | COVERED | zedqa_menu_questions, zedqa_menu_pagelist | |
| Main menu: join | ZeD_MainMenuJoin.lua:72; ZeD_MainMenuJoinMore.lua:102 | COVERED | zedqa_menu_bars, mainmenu_vanilla_sim | |
| Main menu: mods, folders, order, separators | ZeD_MainMenuMods*.lua; ZeD_ModFolders.lua; ZeD_ModOrder.lua | COVERED | zedqa_mods_hand, zedqa_mods_folders, zedqa_mods_order, zedqa_mods_separators, mods_order_sim | Main-menu harness only. |
| Mod safety, scan, reset; mod settings | ZeD_ModSafety.lua:58; ZeD_ModScan.lua:67; ZeD_ModReset.lua:167; ZeD_ModSettings.lua:332 | COVERED (sim) | mods_order_sim | Thin. |
| Main menu: options | ZeD_MainMenuOptions.lua:137 | COVERED | zedqa_menu_pagelist, zedqa_b8_forms, menus_b7_sim | #144: sim only. |
| Main menu: sandbox, world, spawn, traits, looks | ZeD_MainMenuSandbox.lua:60 and neighbors | COVERED | zedqa_menu_sandbox_pages, zedqa_menu_lean, zedqa_belisar_menu, zedqa_tiyl_menu | |
| Main menu: workshop, credits, terms | ZeD_MainMenuWorkshop.lua:98; Credits.lua:76; Terms.lua:38 | COVERED | zedqa_workshop_room, zedqa_b8_mainmenu, mainmenu_vanilla_sim | Credits thin. |
| Desk apps: notes, Pasties, docs, mail | ZeD_MainMenuNotes.lua:84; ZeD_DeskNotes.lua:213; ZeD_MainMenuMail.lua:56 | COVERED (sim) | desk_sim, desk_notes_sim, mail_sim | #114, #142: no in-game check. |
| Main menu: players | ZeD_MainMenuPlayers.lua:61 | COVERED (sim) | mp_leftovers_sim | |
| ZeD setup and in-game options | Settings.lua:1226 | COVERED | zedqa_menu_zed_switches, zedqa_b8_forms | #127 PZ Teal default: sim only. |
| Layout picks | ZeD_ModPicks.lua:217 | COVERED | zedqa_picks_check, zedqa_picks_recheck | |
| Right-click strip and icons | ZeD_ContextMenu.lua:42 | COVERED | zedqa_ctx_icons [R], zedqa_wheel_icons [R] | #133 paging: sim only. |
| Right-click list | ZeD_ContextList.lua:40 | COVERED | zedqa_ctx_overlap, ctx_list_still_sim | zedqa_ctxlist [R] is smoke. |
| Menu marks | ContextMenuRegistry.lua:871 | COVERED (sim) | menu_marks_sim, zedqa_wheel_icons [R] (icons) | #138 colors: sim only. |
| D-pad wheels; radial wheels | ZeD_DpadWheels.lua:379; ZeD_Wheel.lua:345 | COVERED | zedqa_dpad_wheels [R], zedqa_wheel_icons [R] | |
| Quick chords, put back | ZeD_QuickChords.lua:402; ZeD_PutBack.lua:181 | COVERED | zedqa_quick_chords [R], zedqa_put_back [R] | |
| Survival guide (both looks), ads | ZeD_SurvivalGuide.lua:512; ZeD_SurvivalGuideBook.lua:815 | COVERED | zedqa_book83, zedqa_guide82, zedqa_guide_ads | Not in [R]; #154 Argentine Spanish: sim only. |
| Guide bubble; hidden facts | ZeD_GuideBubble.lua:85; ZeD_HiddenFacts.lua:473 | COVERED | zedqa_guide_bubble, zedqa_b8_hidden | Not in [R]. |
| Messages | ZeD_Messages.lua:722; ZeD_MessagesWindow.lua:77 | COVERED | zedqa_messages [R], messages_scrub_sim | #115 scrub: sim only. |
| Speech bubbles | ZeD_Bubbles.lua:339 | COVERED | zedqa_moodles [R], zedqa_bubbles | #158 mono: sim only. |
| Balloon tooltips | Balloon.lua:477; RichTip.lua:207 | COVERED | zedqa_b10_tooltips, balloon_b10_sim | #118, #119 not in [R]. |
| Hint strip; overhead notes | ZeD_HintStrip.lua:173; ZeD_HaloText.lua:146 | COVERED | zedqa_hint_strip, zedqa_halo_notes, zedqa_quick_chords [R] | #131: sim only. |
| Reader and notebook writing | ZeD_Reader.lua:68; Overrides/WriteNote.lua:25 | COVERED | zedqa_journal_readers [R], reader_notebook_tone_sim | #124 paper tone: sim only. |
| Death screen, In Memoriam, respawn | Overrides/PostDeath.lua:62; Overrides/Respawn.lua:92 | COVERED | respawn_sim, zedqa_b9_respawn_mp, zedqa_b8_respawn_smoke | |
| Tickets, community, claims, log, mail, chat | ZeD_Tickets.lua:330; ZeD_Community.lua:164; ZeD_Claims.lua:746; ZeD_Log.lua:159; ZeD_Mail.lua:302; ZeD_Chat.lua:531 | COVERED | tickets_sim, community_sim, claims_sim, log_sim, mail_sim, mp_* scripts | Multiplayer; no MP run since #123 and #130. |
| Server link, extras and stats cards, MP leftovers | ZeD_ServerLink.lua:144; ZeD_Extras.lua:278; ZeD_MpLeftovers.lua | COVERED | admin_sim, extras_sim, mp_leftovers_sim, mp_extras_cards | |
| Sandbox options in game | ZeD_SandboxInGame.lua:87 | COVERED | zedqa_sandbox_ig [R] | |
| Step aside | ZeD_StepAside.lua:602 | COVERED | step_aside_sim, zedqa_b8_stepaside | Not in [R]. |
| Safe mode | SafeMode.lua:410 | COVERED | zedqa_safemode [R] | |
| Pins | ZeD_Pins.lua:71 | COVERED | zedqa_pins, zedqa_b9a_8 | Not in [R]. |
| Window halves, curtain, dual pin | WindowHalves.lua:109; WindowCurtain.lua:51 | COVERED | zedqa_curtain [R], zedqa_dual_pin | #125, #126, #150 list slide and Deck: sims only; #113 needs the real mouse. |
| Two widths and scale | Scale.lua; ZeD_WorldWindow.lua:1663 | COVERED | zedqa_two_widths [R] | #159 windows jumping: no check. |
| Prompts; on-screen keyboard | ZeD_Prompt.lua:247; ZeD_Keyboard.lua:93 | COVERED | zedqa_messages [R], zedqa_sandbox_ig [R], menus_b7_sim | |
| Debug console | ZeD_DebugConsole.lua:410 | COVERED | zedqa_b8_console, debug_console_sim | |
| Paused look, make-up, heater, minimap, media labels, window menu | ZeD_PausedLook.lua:66; ZeD_MakeUp.lua:209; Overrides/Heater.lua:22; ZeD_WindowMenu.lua:57 | COVERED | zedqa_b8_everyday_a, zedqa_b8_everyday_b, zedqa_etp, zedqa_cohesion_walk | |
| Read marks | ReadMarks.lua:280 | COVERED | zedqa_read_marks, zedqa_menu_zed_switches | |
| Gamepad focus | Input/FocusManager.lua:331; Input/SpatialNav.lua:36 | COVERED | zedqa_world_pad_take [R], zedqa_navmap [R] | suite_gamepad [R] prints values only. |
| Pad glyphs, controller map, focus marks | ZeD_PadGlyphs.lua:273; ZeD_ControllerMap.lua:49; ZeD_FocusPaint.lua | COVERED | zedqa_pad_glyphs [R], zedqa_cmap, zedqa_pad_marks | |
| Mod support: Immersive Searching | ModSupport/ImmersiveSearching.lua:168 | COVERED | zedqa_immersive_searching [R] | |
| Mod support: map mods, Custom Map Labels, Responsive Context Menus | ModSupport/*.lua | COVERED | zedqa_mapmods, zedqa_cml, zedqa_responsiveui | Own mod lists; #134 unresolved. |
| Mod support: wound mods, skill recovery mods | ModSupport/WoundsOverhaul.lua:155 and others | COVERED | zedqa_b8_wounds, zedqa_woundexp, zedqa_exprecovery, zedqa_srj | |
| Mod support: HUD seven, Minimal Sidebar, moodle mods, container mods, This Is Your Life | ModSupport/*.lua | COVERED | zedqa_b8_seven_hud, zedqa_minsidebar, zedqa_moodle_quarters, zedqa_nested, zedqa_capacity, zedqa_tiyl_menu | Own mod lists. |

Counts (149 surfaces before merging rows above): NOT COVERED 9, SHOT ONLY 19, COVERED 121. About 20 of the covered ones rest only on offline sims. About 45 are reached by a checking script in the unattended run.

### B3. Beta 9 to 11 additions no check reaches

- **No check at all:** #147 permit stamp spacing; #148 Health percent cut at the drawer edge; #159 windows jumping; #140 radio preset "+" in the accent; the beta 11 and 12 corkboard headings (pictures only); #134 Custom Map Labels on ZeD's map (probe only).
- **Offline sim only, never checked in the game:** #114 and #142 desk notes and Pasties; #115 report scrub; #124 paper tone; #125, #126 and #150 list slide, cap push and Deck narrowing; #127 PZ Teal default; #131 hint strip; #133 strip paging; #135, #146 and #151 fast looting and the loot card; #138 menu-mark colors; #141 and #143 segment bars (zedqa_segbars [R] dates from Oct 30); #144 color-blind option; #145 portrait studio; #149 belt rings; #153 "Used to make" alignment; #154 Argentine Spanish guide; #158 mono bubbles; #164 notebook gray box; #166 drag chips.
- **Checked in the game, but not in the unattended run:** zedqa_b11_notes (#155, #156, #157, #160, #162; its first run after load fails at times, #165); zedqa_b9a_1 to _9 (#113, real mouse); zedqa_dual_pin (#112); zedqa_b10_tooltips (#118, #119); zedqa_guide_bubble (#122); zedqa_guide_ads (#98); the mod-list checks for #92, #116, #117 and #137.
- The unattended manifest has not changed since Nov 8.

## Suggested next

By player impact:

1. **Build the World window Fishing tab** (#167, beta 12). It is the designed tab players reach most often, and the rod prop is already in place.
2. **Decide on the inventory Filter button.** It is on every early inventory mockup and players use it in every loot session. Build it, or write the drop down.
3. **Build the Animals quick actions** (Milk, Shear and Go to on alerts, then bulk select), then decide whether Hunt is still planned. The code says it is; the punch list does not have it.
4. **Build the Mods Files tab and the error manager's plain-words cards.** They are the designed answer to "a mod broke my game". Right now players get a bug report but no way to act on it.
5. **Put the beta 9 to 11 checks into the unattended run.** At minimum: zedqa_b11_notes once its first-run flake (#165) is fixed, zedqa_b10_tooltips, zedqa_dual_pin and zedqa_guide_bubble. Rerun zedqa_segbars against #143.
6. **Add real checks for the untested cards:** fluid, farm plot, animal tracks, hutch and trough, campfire. Also add checks for the Furniture tab modes and the Equip defense summary. Players open these every session and today they are only photographed or not reached at all.
7. **Write down the unrecorded drops in the punch list:** doll leader lines, the Skill journal Transcribe button and the container buttons kept in the bottom row. Also say whether Search/Filter on Skills and Equipment, the batch verb strip and the Foraging Crouch/Aim buttons are dropped or still wanted.
8. **Smaller gaps, in order:** the Journal Flyers collection with its progress count; Crouch and Aim as working buttons in Foraging; the item card Dry verb; the Messages desk entry (phase 2).
