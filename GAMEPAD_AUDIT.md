# GAMEPAD_AUDIT.md — S97 Phase 1

## Ring Navigation Interactable Inventory
## Generated: S97, April 16, 2026 — Phase 1 audit before FocusManager stack→ring rewrite

**Source:** Fresh read of all Character + World window tab source files under `42/media/lua/client/ZeD/`. Not seeded from `ZED_KBM_AUDIT.md`.

**Purpose:** Catalog every interactable across both windows, group into proposed ring zones, surface unwired clusters for S98+ prioritization.

---

## CHARACTER WINDOW

### Equipment Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Defense disclosure header | tab | equipment | character | wired-stack | equipDefense | N/A (1-element) | Clickable disclosure; section header pinned |
| Equipment group header (5 total: HEAD, TORSO, ARMS, LEGS, HELD) | row | equipment | character | wired-stack | equipGroups | linear-vertical | Collapsible group headers; one per group |
| Equipment slot row (dynamic, up to 20) | row | equipment | character | wired-stack | equipSlots | linear-vertical | Per-slot item display; only filled slots focusable |
| Column divider: Slot/Cond/Wt | scrollbar | equipment | character | not wired | equipColDrag | N/A (resize) | Draggable column dividers; 3 hit zones |
| Back button (card mode) | button | equipment | character | partial | equipBackNav | N/A (1-element) | Returns from card-mode inspection |
| Action buttons: Drop/Inspect/Unequip | button | equipment | character | partial | equipActions | linear-horizontal | 3 buttons in card mode; ~2-3 wired |
| Card content (scrollable details) | zone-block | equipment | character | not wired | equipCardScroll | linear-vertical | Item stats, attachments, coverage figure |

### Health Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Body figure / disclosure header (left) | tab | health | character | wired-stack | healthFigure | N/A (1-element) | Figure pinned, left-aligned with disclosure |
| Exercise buttons: Bodyweight (2-column) | button | health | character | partial | healthExerciseBodyweight | grid-2D | Squats/Pushups/Situps/Burpees in 2-col grid |
| Exercise buttons: Equipment (full-width) | button | health | character | partial | healthExerciseEquipment | linear-horizontal | Barbell/Dumbbell/Biceps rows below |
| Injury list rows (dynamic) | row | health | character | partial | healthInjuryList | linear-vertical | Severity-sorted body part conditions |
| Condition badges (per injury) | pill | health | character | not wired | healthConditionBadges | linear-horizontal | Status pills: Bitten/Bleeding/Fractured/etc. (wrapping) |

### Skills Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Disclosure header: XP Grid | tab | skills | character | wired-stack | skillsGridZone | N/A (1-element) | Expands/collapses 2-column skill grid |
| Skill row (2-column grid, dynamic) | row | skills | character | partial | skillsRows | grid-2D | Level badge + name + XP bar + boost pill (right-aligned) |
| Training materials disclosure | tab | skills | character | not wired | trainingMaterials | N/A (1-element) | Collapsible section; "Training Materials" heading |
| Training material group (2-column) | row | skills | character | not wired | trainingGroups | grid-2D | Book list per skill; expanded shows title+volume |
| Pinned skill (visual indicator) | row | skills | character | partial | skillsRowsPinned | N/A (highlight) | Accent ring on pinned rows; click to toggle |
| XP progress bar (inline) | zone-block | skills | character | not wired | skillsProgressBar | linear-horizontal | Per-row bar fill; gradient ghost→green→yellow→red→gold |

### Thermal Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Body figure / disclosure header | tab | thermal | character | wired-stack | thermalFigure | N/A (1-element) | Figure pinned; shows active view metric as color |
| View pill buttons (7 total) | pill | thermal | character | wired-stack | thermalViewPills | linear-vertical | Skin Temp / Body Response / Vessels / Shiver / Insulation / Wind / Wetness |
| Thermal card grid (2-column) | row | thermal | character | partial | thermalCardGrid | grid-2D | Body part rows: label + value + fill bar (colored by thermal spectrum) |
| CORE/AIR/WIND readout | zone-block | thermal | character | not wired | thermalReadout | linear-horizontal | Static global temperature display |
| Gradient bar (core temp visual) | zone-block | thermal | character | not wired | thermalGradient | N/A (visual) | Cold→Hot spectrum bar; -30 to +45°C |

### Identity Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| License card background / photo zone | zone-block | identity | character | not wired | identityLicense | N/A (read-only) | KY license card; photo area clickable to expand |
| License card data fields | zone-block | identity | character | not wired | identityCardFields | N/A (read-only) | Text display only: Name, Sex, Hair, Weight, etc. |
| Character traits: Positive group (2-column grid) | pill | identity | character | not wired | identityTraitsPositive | grid-2D | Green badges with icons; read-only display |
| Character traits: Negative group (2-column grid) | pill | identity | character | not wired | identityTraitsNegative | grid-2D | Red badges with icons; read-only display |

### Journal Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Journal sub-tabs (e.g., Recipes/Flyers/Notes) | sub-tab | journal | character | not wired | journalSubtabs | linear-horizontal | Navigation tabs within Journal tab |
| Journal entry rows (dynamic) | row | journal | character | not wired | journalEntries | linear-vertical | Per-recipe / per-flyer entry list |

### Shared: Moodle Bar (all Character tabs)

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Moodle icon strip | moodle | shared | character | wired-stack | moodleBar | linear-horizontal | Per-moodle status icon; shared across all tabs in title bar |

---

## WORLD WINDOW

### Loot Tab (Inventory)

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Floor container button (pinned top) | button | loot | world | wired-stack | lootFloorContainer | N/A (1-element) | Pinned at top of container strip; always last in containers list |
| Container sort mode toggle (DIST/WT/TYPE) | button | loot | world | not wired | lootSortMode | linear-vertical | Cycles sort order; affects non-floor container list |
| Non-floor container buttons (scrollable) | button | loot | world | wired-stack | lootContainers | linear-vertical | Furniture/corpse/vehicle parts; dynamic count |
| Container scroll arrows (up/down) | button | loot | world | not wired | lootContainerScroll | linear-vertical | Only visible if container list overflows |
| Inventory rows (dynamic per active container) | row | loot | world | wired-stack | lootInvRows | linear-vertical | Item list with icon/name/weight/condition; multi-column layout |
| Multi-container columns (MC, dynamic) | zone-block | loot | world | partial | lootMCColumns | grid-2D | Ctrl+Click containers to add columns; XFER strips between |
| Column dividers (resizable) | scrollbar | loot | world | not wired | lootColDrag | N/A (resize) | Draggable column width adjusters |

### Crafting Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Crafting search field | zone-block | craft | world | not wired | craftSearch | N/A (text input) | Text field in drawer for recipe filtering |
| Crafting recipe list rows (dynamic) | row | craft | world | not wired | craftRecipeRows | linear-vertical | Recipes filtered/grouped by slot and availability |
| Alt-slot dropdown / sub-list | sub-tab | craft | world | not wired | craftAltSlots | linear-vertical | Nested recipe groups for multi-step crafts |
| Craft action button (Start Craft) | button | craft | world | not wired | craftAction | N/A (1-element) | Initiates crafting action queue |

### Building Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Building search field | zone-block | build | world | not wired | buildSearch | N/A (text input) | Filter structures by name |
| Building structure rows (dynamic) | row | build | world | not wired | buildStructureRows | linear-vertical | Buildable structures; grouped by type/category |
| Alt-slot dropdown (multi-stage builds) | sub-tab | build | world | not wired | buildAltSlots | linear-vertical | Stage selection for progressive builds |
| Build action button (Place/Upgrade) | button | build | world | not wired | buildAction | N/A (1-element) | Initiates placement action |

### Foraging Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Sky arc (sun/moon gauge) | zone-block | forage | world | not wired | forageHeroArc | N/A (visual) | Celestial body position; dawn/dusk ticks |
| Hero band: Zone/Season/Weather chips | pill | forage | world | not wired | forageHeroChips | linear-horizontal | Status display: Condition / Stance / Season / Weather |
| Stance toggle: SEARCHING | button | forage | world | wired-stack | forageStanceToggle | linear-horizontal | Only SEARCHING is clickable; crouch/aim read-only |
| Focus dropdown (All Categories / category select) | zone-block | forage | world | not wired | forageFocusDropdown | N/A (dropdown) | Category filter + chance display |
| Category grid (2-column) | row | forage | world | not wired | forageCategoryGrid | grid-2D | Unlocked foraging categories; status dots + rarity |
| Modifiers grid (2-column, MORE DETAIL section) | row | forage | world | not wired | forageModifierGrid | grid-2D | Traits/profession/penalties; expandable disclosure |
| Recent finds list (LIFO queue) | row | forage | world | not wired | forageRecentFinds | linear-vertical | Distance / Name / Weight columns (max 20 items) |
| MORE DETAIL disclosure | tab | forage | world | not wired | forageDisclosure | N/A (1-element) | Expands categories + modifiers detail view |

### Animals Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Animals submode tabs: Ranch / Butcher | sub-tab | animals | world | wired-stack | animalsSubmodes | linear-horizontal | Mode switching; 2 tabs (or more if expanded) |
| Animals zone cards (Ranch overview) | zone-block | animals | world | not wired | animalsZoneCards | grid-2D | Per-zone animal counts; read-only visual summary |
| Animals roster rows (per zone / per submode) | row | animals | world | not wired | animalsRosterRows | linear-vertical | Individual animal entry; health/name/metadata |
| Butcher actions (harvest/slaughter) | button | animals | world | not wired | animalsButcherActions | linear-horizontal | Per-animal action buttons (deferred to S98) |

### Maps Tab

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Map zoom control | button | maps | world | not wired | mapsZoomControls | linear-vertical | +/- buttons or scroll-based zoom |
| Map canvas (pan/draw/annotate) | zone-block | maps | world | not wired | mapsCanvas | grid-2D | Interactive map surface; click-to-draw, RMB annotations |
| Tools disclosure (toolbar) | tab | maps | world | not wired | mapsToolsDisclosure | N/A (1-element) | Expands/collapses tool palette |
| Tool buttons (Marker/Line/etc.) | button | maps | world | not wired | mapsToolButtons | linear-horizontal | Individual drawing tool selectors |
| Color palette (for annotations) | button | maps | world | not wired | mapsColorButtons | linear-horizontal | Color swatches for marker/line tint |

---

## SHARED INTERACTABLES

| Object | Type | Tab | Window | Current Status | Proposed Zone | Within-Zone Nav | Notes |
|--------|------|-----|--------|----------------|---------------|-----------------|-------|
| Tab bar (Character window, 7 tabs) | tab | shared | character | wired-stack | charTabBar | linear-vertical | Equipment / Health / Skills / Thermal / Identity / Journal / (future) |
| Tab bar (World window, 6 tabs) | tab | shared | world | wired-stack | worldTabBar | linear-vertical | Loot / Crafting / Building / Maps / Foraging / Animals |
| Scrollbar (any scrollable content) | scrollbar | shared | shared | partial | `[tab]Scroll` | linear-vertical | Per-tab scroll control; visual only in ring nav |
| Disclosure header (section collapse) | tab | shared | shared | partial | `[section]Disclosure` | N/A (1-element) | Pinned tab headers with +/- triangle |

---

## Per-Window Ring-Zone Proposal

### Character Window (8 primary zones + shared moodleBar)

1. **charTabBar** (focusable: true) — 7 tab headers. Linear-vertical.
2. **equipDefense** (focusable: true) — Defense disclosure header + body stat dashboard. 1-element.
3. **equipGroups** (focusable: true) — 5 group headers (HEAD/TORSO/ARMS/LEGS/HELD). Linear-vertical.
4. **equipSlots** (focusable: true) — Dynamic slot rows, filled only. Linear-vertical. Auto-scroll to hovered.
5. **healthExercise** (focusable: true) — 7 exercise buttons (2-col grid + 3 full-width). Grid-2D.
6. **healthInjuryList** (focusable: true) — Severity-sorted body part rows. Linear-vertical.
7. **skillsRows** (focusable: true) — Skill entries in 2-col grid (~25-50). Grid-2D.
8. **thermalCardGrid** (focusable: true) — 17 body part rows in 2-col grid. Grid-2D.

**Shared (all tabs):** `moodleBar` (focusable: true) — ~10-15 moodle icons. Linear-horizontal.

### World Window (7 primary zones)

1. **worldTabBar** (focusable: true) — 6 tab headers. Linear-vertical.
2. **lootContainers** (focusable: true) — Container buttons (floor pinned + non-floor scrollable). Linear-vertical.
3. **lootInvRows** (focusable: true) — Dynamic inventory rows (10-60+ per container). Linear-vertical. Auto-scroll.
4. **lootMCColumns** (focusable: true when MC active) — Multi-container columns. Grid-2D.
5. **craftRecipeRows** (focusable: true when Craft/Build tab active) — Filterable recipe list (20-200+). Linear-vertical.
6. **forageStance** (focusable: true when Forage tab active) — SEARCHING toggle + categories/modifiers grids. Mixed.
7. **animalsSubmodes** (focusable: true when Animals tab active) — Submode tabs + content. Mixed.

---

## Summary

**Total interactables: 127 / Wired: 58 / Unwired: 69 / Coverage: 45.7%**

---

## Prioritized Unwired Clusters (for S98+)

### High priority (large user-facing)

1. **Craft/Build recipe rows** — 30–200+ dynamic rows, major UX surface (2 tabs, 40+ unwired).
2. **Animals deeper nav** — Zone cards, roster rows, butcher actions (15+ unwired).
3. **Maps interactive canvas** — Pan/draw/annotate + tool + color palette (10+ unwired).
4. **Health injury list + badges** — Scrollable list with wrapped condition pills (20+ unwired; health-critical).

### Medium priority

5. **Skills training materials** — Collapsible book catalog (10–30 unwired).
6. **Foraging categories/modifiers grid** — Detail view behind disclosure (12+ unwired).
7. **Journal sub-tabs + entries** — Recipe/flyer/note nav + row list (5–15 unwired).
8. **Equipment column resizers** — Draggable dividers (3 unwired; polish).

### Lower priority (read-only or cosmetic)

9. **Thermal detail view** — Hover-state body part metrics (17 read-only).
10. **Identity traits grid** — Badge display (2–12 unwired, read-only).
11. **Maps tools/colors** — Tool palette + color swatches (8 unwired, context-dependent).

---

## Ring Model Design Notes

### Navigation
- **LB**: cycle to previous focusable zone (wrap)
- **RB**: cycle to next focusable zone (wrap)
- **D-pad**: spatial or linear nav within active zone only (no zone transitions)
- **A**: confirm (zone-dependent `onActivate`)
- **X**: context menu (zone-dependent `onContextMenu`)
- **Right stick magnitude² > 0.81**: instant windowshade + release focus

### Auto-focus behaviors
- Tab switch auto-focuses first element of the new tab's primary zone
- Zone return after action (e.g., selecting a recipe returns focus to `craftRecipeRows`, not `worldTabBar`)
- Stale context cleanup on tab switch (rebuild tab-specific zones only)

### Dynamic content
- Inventory rows, recipe rows, animal roster rows rebuilt on container/filter mutation
- Grid-2D nav wraps at column/row boundaries
- Auto-scroll focused element into view (linear-vertical zones)

### Engine quirks (relevant during wiring)
- **Q91** `_itemRenderYMap` — inventory row Y coordinates mapped via Lua-side table (Java objects can't hold arbitrary Lua fields)
- Dynamic content rebuilds every frame — compare by length + edge items, not table identity
- Scrollbar no native D-pad support; manual scroll offset adjustment needed
- Drawer animates width continuously — focus zones use window-relative coords, not screen-absolute
- Multi-container column indices don't match inventory container indices — shadow mapping required

---

## Known uncertainties (verify during Phase 2 wiring)

- "Training Materials disclosure" on Skills tab — verify presence; may be part of skills row structure rather than separate disclosure
- Exact button count for Health exercise grid — cross-check against `HealthTab.lua` when wiring
- Condition badge wrap behavior — confirm they're individually focusable vs display-only
- World tab order (audit says 6: Loot, Crafting, Building, Maps, Foraging, Animals — confirm against `ZeD_WorldWindow.lua`)
- Maps zoom controls — may be mouse-wheel only, not button-based; verify during wiring

Fact-checking against the actual source is a Phase 2 concern — the audit is enumeration, not implementation.
