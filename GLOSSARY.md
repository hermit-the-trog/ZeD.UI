# ZeD-UI — Glossary

A shared vocabulary for design direction and development. Organized by category.
Updated as new terms emerge. Ask Claude to update this file when needed.

---

## Component Hierarchy

How ZeD-UI's building blocks stack up, smallest to largest.

| Term | What it is | Example |
|---|---|---|
| **Token** | A single design value — color, font, spacing, dimension. The DNA. Lives in `Tokens.lua`, accessed via `ZeD.T`. | `ZeD.T.accent`, `ZeD.T.fontF2`, `ZeD.T.sp.md` |
| **Atom** | A low-level draw helper. One visual job. No state, no interactivity. Lives in `Atoms.lua`. | `drawBorder`, `drawFillBar`, `borderDoubleRounded` |
| **Molecule** | A reusable UI building block assembled from atoms. May have simple state (hover, active). Lives in `Molecules.lua`. | `drawStatRow`, `drawButton`, `drawDock`, `drawActionStrip` |
| **Organism** | A complete, self-contained UI component. Has its own lifecycle (create → update → render). A Lua class. | `ZeD_Window`, `ZeD_ScrollList`, `ZeD_ItemCard` |
| **Organism ID** | The O-number label for each organism in our design inventory. | O01 = ZeD_Window, O08 = ZeD_ItemCard |
| **Molecule ID** | The M-number label for each molecule. | M14 = drawActionStrip, M15 = drawDock |

---

## System 7 Visual Language

The Mac OS vocabulary ZeD-UI is built on.

| Term | What it is |
|---|---|
| **Chrome** | The structural frame around content — title bars, borders, scrollbars, grow boxes. "The chrome IS the design." Everything that isn't content. |
| **Title bar** | The top bar of a window. In ZeD-UI: striped pattern, close box on the left, window title text. |
| **Striped title bar** | Horizontal pinstripes filling the title bar background. Classic System 7 look. Active windows get stripes; inactive windows go blank. |
| **Close box** | The small square in the top-left corner of the title bar. Click to close the window. Our version of the ✕ button. |
| **Grow box** | The ridged triangle/square in the bottom-right corner of a resizable window. Drag to resize. System 7 uses diagonal ridges. |
| **WindowShade** | Double-click the title bar to collapse the window to just the title bar (like rolling up a window shade). Double-click again to expand. |
| **Groove** | A 1px recessed divider line. Used to separate sections (like between zone blocks in the detail zone). Not a border — a visual pause. |
| **Disclosure triangle** | A small triangle that rotates to show/hide content. ▶ = collapsed, ▼ = expanded. Progressive disclosure control. |
| **Double border** | Two concentric 1px borders (outer + inner) with a 1px gap, creating a raised/inset look. Drawn by `borderDoubleRounded`. Classic System 7 button treatment. |
| **Corner radius `{2, 1}`** | The two radii for double borders: outer border = 2px radius, inner border = 1px radius. Keeps the gap between borders consistent around corners. |

---

## Card Anatomy

The three strata of ZeD_ItemCard (O08) and their parts.

| Term | What it is |
|---|---|
| **Info Zone** | Top section of the card. Pure data readout — no interactive elements. Contains icon, item name, stat rows, category, weight, and overall condition bar. |
| **Action Strip** | Middle bar. Split layout: toggle buttons on the left, verb buttons on the right. The control panel. |
| **Detail Zone** | Bottom section. Only appears on items with body-part zones (clothing, armor). Per-zone inspection and repair interface. |
| **Zone block** | One body part's section inside the detail zone. Two lines: top line (stat + structural dock), bottom line (soiled flags). Separated by groove dividers. |
| **Stat row** | A single label→value line in the info zone. Drawn by `drawStatRow`. Label on the left (mono, caps, dim), value on the right (sans-serif, bright). |
| **Fill bar** | A horizontal bar showing a percentage. Used for condition, food values, etc. Drawn by `drawFillBar`. Can have segmented fills (multiple colors stacked). |
| **Condition bar** | The fill bar showing item condition (0–100%). Color graduates: green (>60%), amber (30–60%), red (<30%). |

---

## Button Types

Every pressable element on the card. All share: 22px height, 1px border, 4px icon padding, `borderDoubleRounded` `{2, 1}`.

| Term | What it is | Where it lives |
|---|---|---|
| **Toggle** | A square button that flips between on/off states. Icon changes color to show state. Hover gets accent shade. | Action strip, left side |
| **Verb** | A square button that triggers an action. Active or greyed. No accent shade on hover (distinguishes from toggles). | Action strip, right side |
| **Dock** | A button-with-flag: a text flag label docked flush to a 22px action button. The flag is the readout, the button is the action. Only the **structural** variant has a button. | Detail zone, top line |
| **Soiled flag** | A colored text label (NOT a button) showing a soiled percentage. Diagnostic only — no click action. | Detail zone, bottom line |
| **Padding button** | A standalone 22px square button for adding/removing fabric padding on a body zone. | Detail zone, bottom line |

---

## Dock Vocabulary

The M15 drawDock molecule and its variants.

| Term | What it is |
|---|---|
| **Flag** | The variable-width text label portion of a dock. Shows the zone's state (Torn, Worn, Leather, Denim, Ripped Sheets, or — for pristine). Drops its right border so it fuses visually with the button. |
| **Structural dock** | Flag + button. The actionable dock variant used for zone condition. Flag shows state, button triggers repair/remove/pad. |
| **Soiled flag** | Flag only, no button. Colored text showing blood/dirt/wet percentage. Non-interactive. |
| **Seamless junction** | Where the flag meets the button: flag has no right border, button has all four borders. They share the boundary so it looks like one element. |

---

## State & Status Terms

| Term | What it is |
|---|---|
| **Active** | A button/dock that can be clicked. Icon is visible, border is full opacity. |
| **Greyed** | A button/dock that can't be clicked right now (nothing to do, missing materials, etc.). Rendered at 0.45 opacity. |
| **Hover** | Mouse is over the element. Toggles get accent shade fill; verbs and docks do not. |
| **Status alert** | A colored badge below the item name in the info zone. Shows item state: Broken, Wet, Rotten, Burnt, Frozen, etc. |
| **Danger pulse** | A flashing red fill on danger buttons (sine wave, alpha 0.08–0.25). Used for destructive actions. |

---

## Theme System Terms

| Term | What it is |
|---|---|
| **ZeD.T** | The active theme table. Every component reads from this every frame. Contains all tokens: colors, fonts, dimensions, spacing. |
| **Base theme** | The foundation palette: Dark, Light, or High Contrast. Sets surface colors, border colors, text colors. |
| **Accent** | The highlight color overlaid on the base theme. 9 options: Red, Orange, Yellow, Green, Blue, PZ Teal, Purple, Pink, Mono. |
| **Surface** | A background color layer. `surf1` through `surf4` go from darkest to lightest (in dark theme) or lightest to darkest (in light theme). `base` is the deepest background. |
| **colorSync** | Utility function that mutates a color table in-place to match a source color. Zero allocation. Used in `prerender()` to keep colors fresh without creating garbage. |
| **colorAlpha** | Utility that returns a new color table with a modified alpha value. Used when you need a transparent version of a token color. |
| **Theme reactivity** | The pattern where every component reads ZeD.T fresh in `prerender()` every frame. Means theme changes apply instantly — no stale data, no manual refresh. |

---

## Typography

| Term | What it is |
|---|---|
| **Chrome voice** | Monospace font (Fira Mono). Used for labels, categories, zone names — anything that's structural UI. Always uppercase. |
| **Content voice** | Condensed sans-serif font (Fira Sans Condensed). Used for values, item names, descriptions — anything that's data or user content. Mixed case. |
| **5 Typography Roles** | F-system (S75): F1 Chrome (Fira Mono Bold 11px), F2 Body (Fira Sans Condensed Regular 12px), F3 Data (Fira Mono Regular 11px), F4 Heading (Fira Sans Condensed SemiBold 13px), F5 Micro (Fira Sans Condensed Regular 9px). Each role wired to a T.fontFX token, not a raw font name. |
| **T.fontF1** | Chrome role. Fira Mono Bold 11px. Title bars, tab labels, button text, chrome labels. UIFont.NewMedium (small preset) / UIFont.NewSmall (large preset). |
| **T.fontF2** | Body role. Fira Sans Condensed Regular 12px. List rows, item names, descriptions, general content. UIFont.Small / UIFont.Large. |
| **T.fontF3** | Data role. Fira Mono Regular 11px. Stat values, percentages, counts, numerical data. UIFont.Medium / UIFont.CodeMedium. |
| **T.fontF4** | Heading role. Fira Sans Condensed SemiBold 13px. Section headers, item card names, group labels. UIFont.NewLarge / UIFont.CodeLarge. |
| **T.fontF5** | Micro role. Fira Sans Condensed Regular 9px. Chips, badges, metadata labels, smallest UI text. UIFont.Code / UIFont.CodeSmall. (Repurposed from old title/display slot.) |
| **textSec** | The secondary text color token. Dimmer than `text`. Used for labels, chrome text, less important values. |
| **textHead** | The heading text color. Typically the accent color. Used for item names, section titles. |

---

## Window Zones

| Term | What it is |
|---|---|
| **Waterfall** | A vertical tab strip on the edge of a window. Named for the top-to-bottom button flow. Four types exist: **character waterfall** (left edge of character window — E,H,S,P,T,J,I), **container waterfall** (right edge of character window — main inv pinned, equipped bags), **world container waterfall** (left edge of world window — floor pinned top, nearby containers below), **world interaction waterfall** (right edge of world window — L,C,B action tabs, WORLD_TAB_RENDERERS dispatch). |
| **Accordion** | Side-by-side inventory columns that expand into the drawer space when multiple containers are toggled. Each column shows one container's items in compact mode (NAME + WT only). Separated by XFER strips. Max 3 total (main + 2 toggled). |
| **XFER strip** | A 32px vertical strip between accordion columns. Contains destination buttons (arrow + icon + badge number). Clicking transfers selected items from the active column to the target container. |
| **Container info header** | The 37px header at the top of each inventory column. Shows container icon + truncated name (left), weight/capacity stats (right), divider line, then sort column strip below. Same layout in single-column and accordion modes. |
| **MC mode** | Multi-container mode. Active when `#win._mcSelected > 0`. Container waterfall toggles containers (click-to-toggle, no modifier). Drawer expands for column space. Content panel spans drawer+content area. Exits when all extras deselected or tab clicked. Works in both Character and World windows. |
| **Per-window accent** | Each ZeD_Window can have its own `_accentKey`. ZeD_Window:prerender() swaps 5 ZeD.T accent fields for the render cycle; render() restores. Footer accent dot button cycles per-window. Persisted in ZeD_WinState modData. |
| **Placeholder card** | Stub content rendered by `renderPlaceholder()` when a WORLD_TAB_RENDERERS entry is nil. Shows tab heading + groove + "Coming soon". Replaced when real tab content registers (S49+). |
| **Snap-back** | Drawer mode restoration via `_tabUnder`. When a non-loot tab is active and user clicks an item, drawer swaps to ItemCard and saves the tab id. When item is deselected, drawer snaps back to tab content. |
| **Tab visibility predicate** | S72 system. A generic function per tab that returns true/false for whether the tab should appear in the strip. Used for contextual World Window tabs (Foraging only visible when conditions met). |
| **ITEM.DRAWER** | S68 overlay panel added as LAST child of both windows. Ensures item cards always render on top of tab content regardless of drawer/content Z-order. |
| **Sun/moon arc** | S72 semicircular gauge in ForagingTab hero band. Tracks game time with season-aware dawn/dusk from ClimateManager. Replaces Cell A placeholder. |

---

## Layout Terms

| Term | What it is |
|---|---|
| **50/50 layout** | The About This Macintosh two-column split. Left column and right column each get half the card width, with a gap between. |
| **Edge flags** | Booleans that control which sides of a border get drawn: `{top=false, right=true, bottom=true, left=true}`. Used to prevent double-thick lines where a card meets a title bar. |
| **calcHeight()** | Function that measures how tall the card content will be — counts stat rows, zone blocks, action strip height, text wrapping, etc. Used to set the window size. |
| **Stencil clipping** | PZ's built-in rectangle clipping. `setStencilRect` / `clearStencilRect`. Anything drawn outside the stencil rectangle is invisible. Used for scroll panels. |
| **Progressive disclosure** | Showing only what's relevant now, revealing more on demand. Disclosure triangles, detail zones that only appear on clothing, zone blocks that only show soiled flags when soiled. |

---

## PZ Engine Terms

Terms from Project Zomboid's Lua UI framework that come up in our work.

| Term | What it is |
|---|---|
| **ISPanel** | PZ's base UI panel class. Everything inherits from this. Has lifecycle methods: `initialise()`, `prerender()`, `render()`, `update()`. |
| **ISCollapsableWindow** | PZ's window class with title bar, close button, resize widget. We replace this with ZeD_Window but sometimes hook into it. |
| **prerender()** | Called every frame BEFORE children render. Where we sync theme colors, draw backgrounds, set up clipping. Runs top-down (parent before children). |
| **render()** | Called every frame AFTER prerender. Where we draw foreground elements, text, icons. Also runs top-down. |
| **update()** | Called every frame for logic. Mouse hit testing, state updates, animation ticks. Not a draw call. |
| **initialise()** | Called once when a panel is created. Sets up children, dimensions, initial state. Must call parent's initialise. NEVER call twice. |
| **addChild()** | Adds a child panel. Triggers the child's `instantiate()`. Set anchors BEFORE calling this. |
| **Timed action** | PZ's system for actions that take time (repairing clothing, cooking, reading). Player plays an animation, progress bar shows, action completes or is interrupted. We wire dock buttons to these. |
| **safeGet()** | Our wrapper for calling Java methods on items. Not all items have all methods — calling a nil method crashes. `safeGet(item, "methodName")` returns nil instead of crashing. |
| **instanceof** | PZ's type-checking function. `instanceof(item, "HandWeapon")` returns true if the item is that Java class. Used in category detection. |
| **getFluidContainer()** | Returns the fluid container object on items that hold liquids (bottles, cans, cartons). Must check this BEFORE checking food category — fluid items may not be categorized as food. |
| **ModOptions** | PZ's mod settings API. `getValue()` returns an integer index, not a string. Colon syntax required. |

---

## File & Build Terms

| Term | What it is |
|---|---|
| **Atoms.lua** | The file containing all atom-level draw helpers. Namespace: `ZeD.Atoms` (aliased to `A` in most files). |
| **AtomExtensions.lua** | Extended atom helpers including `borderDoubleRounded`. |
| **Molecules.lua** | The file containing all molecule-level components. Namespace: `ZeD.Molecules`. |
| **Organisms.lua** | The file containing organism classes (ZeD_Window, ZeD_ScrollList, etc.). Global classes. |
| **Tokens.lua** | The theme engine. Builds `ZeD.T` from base theme + accent + text size + color blind mode. Lives in `shared/`. Contains `ZeD.Font` rich atomics and `T.scale`. |
| **InspectHook.lua** | The hook that adds "Inspect Item" to the right-click context menu and opens a ZeD_ItemCard in a ZeD_Window. |
| **ZeD_Panel.lua** | Base class for all ZeD panels. `ISPanel:derive("ZeD_Panel")` — one hop from vanilla, last vanilla touch. Theme-reactive prerender, `_hitZones`, `_onPrerender` hook. |
| **ZeD_CharacterWindow.lua** | The Character Window organism. Tabs, drawer, containers, keybind takeover, visibility gate. F7 keybind (also responds to vanilla inventory toggle). |
| **TestInventory.lua** | F6 key opens the inventory test window. Shared `ZeD.InventoryRenderer` module. Proving ground for incremental build. |
| **HealthTab.lua** | Character Window Health tab. Body damage aggregation, severity badges. |
| **SkillsTab.lua** | Character Window Skills tab. 2-column XP grid, color-coded progress bars, boost pills. |
| **Settings.lua** | ModOptions for base theme, accent, text size. F9/F10/F11 cycling hotkeys. |
| **F6 / F7** | F6 = TestInventory.lua test window. F7 = ZeD_CharacterWindow. |
| **F9 / F10 / F11** | Theme cycling hotkeys. F9 = base theme, F10 = accent, F11 = text size. |

---

## Design Principles (quick reference)

| Shorthand | Full meaning |
|---|---|
| **"The chrome IS the design"** | Window frames, borders, scrollbars aren't decoration — they're the visual identity. System 7's chrome is what makes it look like System 7. |
| **"The problem IS the solution"** | Diagnostic data doubles as the action button. A "Torn" flag is also the repair button. Clicking the damage fixes the damage. |
| **"No half-baked"** | Every feature ships 100% working or doesn't ship at all. No placeholder UI, no "we'll fix it later." |
| **"Fresh every frame"** | Components read theme tokens every frame in prerender(). Theme changes are instant, no manual refresh needed. |
| **"Two voices"** | Monospace for chrome (labels, categories, structure). Sans-serif for content (values, names, descriptions). Never mix them in the same role. |
| **"Hierarchy through caps and color"** | We don't make headings bigger. We make them UPPERCASE and accent-colored. Same font size throughout. |

---

## Unified Interaction Layer (Session 87)

Context menu system — one gesture (mouse RMB or gamepad bound button) routes to one horizontal icon strip.

| Term | What it is |
|---|---|
| **Unified Interaction Layer** | The S87 paradigm. One context menu serves both mouse and gamepad with identical chrome and state machine. Replaces vanilla `ISContextMenu` dropdown rendering. Core paradigm alongside Two Windows, Turducken, and Drawer System. |
| **Context menu (ZeD)** | The horizontal icon strip that appears on RMB or gamepad bound button. NOT vanilla PZ's dropdown — this is our replacement. Preserves vanilla actions via event interception. |
| **Assembly stack** | The vertical stack of the context menu, top to bottom: floating label → strip row → target card → balloon. Reading order is action → subject → consequence. |
| **Action → Subject → Consequence** | The reading-order principle of the assembly stack. Label names the verb, target card names the subject (item being acted on), balloon describes the outcome. Menu reads like a sentence. |
| **Strip row** | The middle band of the assembly: left bumper · left chevron · cells · right chevron · right bumper. Chevrons only render when truncating. |
| **Target card** | Static-centered card between the strip and the balloon. Shows the item being acted on — icon + name + meta field. Does NOT track selection horizontally. This is the visual anchor the whole assembly hangs from. |
| **Floating label** | Absolute-positioned paper pill ABOVE the strip. Shows the selected action's name (or breadcrumb in submenu). The ONLY element that tracks selection horizontally. |
| **Balloon** | Static-centered card BELOW the target card. Shows category header, body description, state row (✓/✕). Triangle on top points UP at the target card. Does NOT track horizontally — only contents update. |
| **Floating label vs balloon** | Label sits above the strip and moves with selection. Balloon sits below the target card and stays put — only its contents update. Only ONE element tracks selection horizontally. |
| **ActionDef** | The schema for a single action in the context menu: `{ id, name, icon, category, body, state, stateKind, disabled, pinned, children, onFire }`. The `state`/`stateKind`/`disabled` fields are functions resolved every frame. |
| **Action registry** | The `ZeD.ContextMenu.Registry` module that translates vanilla `ISContextMenu.options` into ActionDef trees. Handles categorization, pin hoisting, state-function wrapping. |
| **Category strip** | Rejected concept (S87 research). Tried grouping actions into category headers — read like a table of contents, wrong mental model. Abandoned early. |
| **Round radial** | Rejected concept (S87). Breaks System 7 rectangular vocabulary. Caps at 8 slots (modded PZ has 20+ actions per item). |
| **Squaradial** | Rejected hybrid concept (S87). Still too lossy for high action counts. |
| **Linear loop** | Selection wraps past both ends of the item list. Applies to both truncating and non-truncating modes. |
| **Visual loop** | The triple-render carousel pattern used when truncating. Track renders `[...items, ...items, ...items]`. Selection lives in the middle copy. Scrolling past the end shows the first copy sliding in from the right — no jump cut. |
| **Triple-render carousel** | The implementation of visual loop. Items concatenated three times in the track. Selection visually slides through the boundary and the track silently teleports back to the middle copy after a settle timer fires. |
| **pos anchor** | The index into the tripled track (truncating mode only). Distinct from `selectedIdx` which indexes into the actual items. Only the cell at `pos` renders active, even though items appear in triplicate. |
| **Settle timer** | The post-animation timer that fires ~20ms after animation end (total 200ms). Checks if `pos` has crossed into a clone copy; if so, disables transitions for one frame, snaps `pos` back into the middle copy, re-enables transitions. Invisible to the eye. |
| **Back cell** | The synthetic cell at position 0 of any submenu. Accent-tinted ◂ glyph. Confirming on it pops one level of `path`. |
| **Group-jump bumpers** | The paper blocks flanking the strip. Click (mouse) or press mapped button (gamepad) to skip to the next/previous category group. Currently show `«` / `»` placeholders — button-hint rendering is deferred. |
| **Responsive width (10-cell cap)** | Strip housing only renders as wide as needed up to 10 visible cells. Housing width = `min(N,10) × 22 + (min(N,10)−1) × 1 + 2`. At N ≤ 10: chevrons hidden, row compacts. At N > 10: capped, chevrons appear. |
| **Drilled border** | When in a submenu, the strip's top border thickens from 1px to 2px. Subtle depth cue. |
| **Button-hint rendering** | DEFERRED system for swapping bumper/chevron glyphs based on active input device. Will show shoulder icons for gamepad, keyboard shortcut text for keyboard, blank for mouse-only. Currently all bumpers show `«` / `»`. |
| **CONTEXT_MENU_SPEC.md** | The canonical spec doc at mod root. 12 sections, 26 acceptance criteria. Written S87, IMPLEMENTED S88 with deviations addendum. |
| **zed_context_unified_v1.html** | The locked S87 interactive mockup at `ZeDUI/mockups/`. Test buttons cycle 3/5/8/10/14/20 action counts. NOTE: shows AS-PLANNED (with target card + separate label/balloon); S88 ships AS-SHIPPED (no card, merged bubble). |

### S88 AS-SHIPPED additions / changes

| Term | What it is |
|---|---|
| **Info bubble** | The combined chrome above the icon strip (S88). Replaces both the floating label AND the balloon from the S87 spec — ONE piece of chrome with adaptive sections: action name (always), body description (when present and distinct from label), state row with status dot (when action is gated). Bubble centers on the strip horizontally — does NOT track selection X. |
| **Adaptive vertical flip** | When the cursor is too high on screen for the bubble to fit above, the assembly inverts: strip below cursor, bubble below strip with upward-pointing tail. Decision made once per RMB based on `cursor.Y vs bubbleReserve + stripH + cursorGap`. |
| **Cursor-anchor strip** | S88 positioning rule: strip's bottom edge sits 6px above the cursor (or top edge sits 6px below in flipped mode). The click target stays visible right under the cursor. Replaces S87's "menu centered on cursor" approach. |
| **Accent hover / active cell** | S88 deviation. Active/selected cell's background uses `T.accent` (the theme's chosen accent color) instead of the spec's "full ink inversion." Indicators (corner triangle, pin square, back glyph) flip to paper when on accent so they stay visible. Inactive cells stay paper. |
| **Locked light balloon chrome** | S88 deviation. The info bubble uses pure white fill + pure black border + black text + mid-grey separators regardless of active theme. Strip cells/bumpers stay theme-driven for now (S89 may align). |
| **Bare strip (small menu)** | When the menu has ≤ 10 items, both bumpers AND chevrons hide entirely. Only the strip itself (and its info bubble) renders. S87 spec had bumpers always-on; S88 hides for combat-survivable density on short menus. |
| **More flatten** | Vanilla `ISInventoryPaneContextMenu.lua:4659` packs Rename/Show Build Recipes/etc. into a `getText("ContextMenu_More")` submenu. ZeD's `flattenMoreSubmenus(tree)` detects any node named "More" and splices its children up to the parent list. Strip handles the resulting overflow via truncation. |
| **Combined bubble pointer flip** | The bubble's pointer tail switches direction based on flip state: down-pointing in normal orientation, up-pointing when flipped. Implemented via `state.pointerDir = "up" \| "down"` on the molecule call. |
| **Two-click RMB dismiss** | S88 UX pattern. Right-clicking on the ZeD menu's panel area dismisses the menu (does NOT pop submenu — that's keyboard Esc / gamepad B). User then re-RMBs at the new spot to open a new menu. Single-click redirect was attempted but no clean Lua entry exists for synthesizing a fresh world RMB. |
| **Hook-via-prerender** | S88 implementation note. Vanilla `ISContextMenu` is a per-player cached singleton — `addToUIManager` only fires once at startup. The reliable per-RMB intercept point is `ISContextMenu:prerender` (with `clear()` as the per-RMB reset signal). See PZAPI-KB Q73-Q75. |
| **vanillaRef** | Field on each ActionDef that points back to the original vanilla `ISContextMenu.options[i]` entry. Preserved so the organism can dispatch `vanillaRef.onHighlight(vanillaRef, true/false)` on selection change — some mods use that callback for server-side gating. |

---

## HARD RULES (S87, S89)

These are non-negotiable enforcement rules. Violating them is a bug, not a style preference.

| Rule | What it means |
|---|---|
| **No custom draw (#10)** | Every draw call goes through an existing atom, molecule, or template. Inline `drawRect` / `drawText` / `drawTexture` / `drawRectBorder` blocks that duplicate what a molecule does are forbidden. If nothing fits, define a new atomic FIRST. If unclear whether an atomic covers the need, ASK before writing any draw code. Codifies `feedback_system_over_custom.md` from S85. Added to PROJECT_STATE.md DESIGN RULES as Rule #10. |
| **Ask, don't guess** | When draw instructions aren't explicit and no atomic clearly covers the job, Claude stops and asks how to draw it or whether a new atomic is needed. Assumptions about visual details are forbidden — the design director owns that. |
| **No L3/R3 state-changing bindings (#11)** | Stick clicks (left stick button, right stick button) are reserved for non-destructive, non-state-changing actions only — or unbound. Accidental triggers under combat tension are unacceptable. Applies to ALL ZeD-UI features now and forever. Added S89. Amended Oct 23 2026 (director): view-only toggles while a ZeD window has the pad are allowed (L3 sorts the focused list, R3 flips List / Grid); in the world the stick clicks stay unbound. |

---

## Unified Input Layer (Session 89)

Gamepad system — input method as a transport layer, not a UX tier. See GAMEPAD_SPEC.md for full spec.

| Term | What it is |
|---|---|
| **Unified Input Layer** | The S89 paradigm. Gamepad and KBM are equal transport layers feeding the same UI. No "controller mode" UX tier. Movement never blocked. Built on 6 layers. Core paradigm alongside Two Windows, Turducken, Drawer System, and Unified Interaction Layer. |
| **InputModeDetector** | Layer 1. Singleton polling raw input every tick. Emits `ZeD_InputModeChanged` event. Uses the Jibb Smart rule: mouse movement alone never triggers a switch. 0.20 stick threshold, 0.15 trigger threshold, 200ms cooldown. |
| **Jibb Smart rule** | Mouse movement alone should NEVER trigger a switch to KBM mode. Only keyboard key presses or mouse button clicks count. Named after Fortnite input developer Jibb Smart. Eliminates prompt flickering from idle mouse sensors, Steam Deck trackpads, vibrating surfaces. |
| **BumperChord** | Layer 2. Native combat zoom chord handler. Hold LB + tap RB = zoom in. Hold RB + tap LB = zoom out. Single taps consumed silently. 250ms chord detection window. Sits above FocusManager so bumpers never reach any UI handler. Disabled during Layout Mode. |
| **FocusManager** | Layer 3. Routes joypad input to focused ZeD window. Single-window-focus model (no ring). Per-window focus stack (A push, B pop, max depth 3). D-pad spatial nav with cone algorithm. Windowshade-on-LS/RS/LT detection. Sets `joypadData.focus` on the active ZeD_Panel. |
| **Focus stack** | Per-window stack of navigation contexts, max depth 3: tab bar (root) → panel content → drawer/item card. A pushes deeper, B pops. B at root closes the window. Previously-selected element restored on pop. |
| **Cone navigation** | Spatial navigation algorithm for D-pad. From the focused element's center, filter candidates within a 90° cone in the pressed direction (axis-aligned bias), pick the closest by weighted distance. Used inside panel content and drawer. |
| **Windowshade dismiss** | Any LS/RS movement (> 0.20 magnitude) or LT press instantly collapses the focused ZeD window to its title bar and releases joypad focus. Gameplay resumes in the same frame. D-pad is excluded (intentional UI nav). Bumpers are excluded (zoom chord). |
| **GlyphManager** | Layer 4. Renders correct button prompt glyphs for the active controller type. Three sprite sets: Xbox, PlayStation, Nintendo. Hot-swaps in 1 frame on input mode change. Manual override via ModOption. |
| **LayoutPersistence** | Layer 5. Replaces vanilla `layout.ini` with `zed_layout.ini` containing separate `[kbm.*]` and `[gamepad.*]` sections per window. On input mode change, saves active section and loads the other. Vanilla layout.ini never touched. |
| **ActionMap** | Layer 6. Maps logical actions ("confirm", "cancel", "layout_mode") to raw input bindings for both KBM and gamepad. UI components reference actions, never raw button IDs. Foundation for future button remapping. |
| **Layout Mode** | Modal toggle entered via View/Share/Select button. Focused window highlights with inverted title bar and accent border. D-pad moves window 8px/tap, LT/RT resize width, LB/RB resize height. A confirms + saves, B cancels + reverts. BumperChord disabled during mode. |
| **Window-focus model** | Single-window focus. Most-recently-opened (or keybind-claimed) ZeD window holds `joypadData.focus`. No ring cycling. To switch focus: press the other window's open keybind. When focused window closes/shades, focus passes to next-most-recently-touched window or releases entirely. |
| **Hold threshold** | 400ms for both Y-hold (windowshade individual window) and B-hold (close both windows). Below 400ms = tap gesture. |
| **D-pad strip menus** | When no ZeD windows are open, D-pad directions invoke strip menus (reusing S88 context menu organism chrome). Up=Hotbar/Weapon Swap, Down=Social/Emotes, Left=Vehicle OR Animal (contextual, mutually exclusive), Right=Favorites/Special (TBD). |
| **Duck-typed dispatch** | PZ's joypad system. `joypadData.focus:onJoypadDown(button, joypadData)` calls whatever method exists on the focused object — no instanceof check. ZeD_Panel doesn't need ISPanelJoypad inheritance; just implement the method signatures. |

---

## Gamepad Nav Model (Session 95)

Vocabulary for the D-pad section model and focus chrome shipped in S95. See PROJECT_STATE S95 entry + FocusManager.lua.

| Term | What it is |
|---|---|
| **Section** | A navigable column of cells within a focused window. Character Window sections: `[tabs][drawer][inventory][container]` when all expanded; Loot collapses drawer so it's `[tabs][inventory][container]`. MC mode replaces `inventory` with multiple container columns. D-pad L/R moves between sections; D-pad U/D cycles within the active section. |
| **Section model** | The S95 v3 redesign. Replaced S94's focus-stack-as-depth with focus-stack-as-sections. Push = move right, pop = move left. No more drill-down hierarchy. Flat horizontal navigation across columns. |
| **D-pad section rule** | D-pad Left/Right moves between sections. D-pad Up/Down cycles cells within the active section (wrap). A = enter next section (same as D-pad right). B = back out. Tabs and containers auto-preview on focus move (no A needed); skill rows just show an accent ring cursor. |
| **Active tab / active container** | The tab or container the gamepad cursor is on. Rendered as accent fill at 0.55 alpha so it's clearly readable at a glance. D-pad onto the cell automatically sets it as active (onFocus auto-activate). |
| **Focus chrome v3** | Visual indicator of which ZeD window has joypad focus. Accent-colored stripes overlaid on the title bar (replacing the default grey stripes at 0.55 alpha) plus a solid accent bar along the top edge. System 7 "active window" look. Only renders when input mode is `gamepad`. |
| **Windowshade lock** | Y-hold toggles `_wsLocked` on the FocusManager. When locked, stick/trigger windowshade is disabled — UI stays open even when the player moves or aims. Locked state shows as brighter accent tint + thicker top bar on the focus chrome. Y-hold again to unlock. |
| **Windowshade grace period** | 600ms after any `claimFocus`, windowshade polling is suppressed. Prevents pressure-sensitive triggers (Q83) or stick drift from re-shading windows the instant they open. Clock resets on every focus claim. |
| **Windowshade latch (`_wsLatched`)** | Rising-edge flag on the windowshade poll. Once a trigger/stick is above threshold, shade fires ONCE and latch stays true until all triggers drop below threshold. Prevents re-fire while the user holds a trigger or leaves a stick pushed. |
| **`_zedLabel`** | Per-window stable label used by FocusManager for log output. Set once at window creation (`win._zedLabel = "Character"` / `"World"`). Read preferentially over `win.title` in logs because `title` mutates mid-session to the character's display name or active container name. |
| **`_gpFocusedSkill`** | Field on the Character Window that tracks which skill row the gamepad cursor is on. Set by the Skills panel focusable's `onFocus` callback. `SkillsTab.lua` reads it per-frame and draws an accent ring around the matching row. |
| **`_pushEngineFocus`** | FocusManager helper that calls the global `setJoypadFocus(0, control)` to push focus to PZ's engine-level `joypadData.focus`. Called from `claimFocus` / `releaseFocus` / `unregisterWindow` transfer path. Without this, mod-local focus state is invisible to the engine and `onJoypad*` dispatch never fires. Q87. |
| **Atomic focus transfer** | When `unregisterWindow` closes a focused window while another ZeD window remains in the registry, focus transfers to the survivor in a single `ZeD_FocusChanged(new, old)` event — no intermediate `(nil, old)` then `(new, nil)` event pair. S94 refactor from S93. |
| **Hold-timer mutex** | Shared B/Y hold-timer state in FocusManager. Only one button can be armed at a time (first-down wins); second button silently dropped until first releases. 400ms threshold, `_holdButton` / `_holdStartMs` / `_holdConsumed` state. Tap fires on release-before-threshold; hold fires once at threshold-while-held. |

---

## Per-Column MC Ring Zones (Session 108)

S108 paradigm shift: each MC selection becomes its OWN ring zone (vs the previous single zone with cone-nav between columns). Bumpers cycle MC columns one-by-one as standard ring zones; D-pad U/D for rows; D-pad L/R reserved for card flow.

| Term | What it is |
|---|---|
| **Per-column MC zone** | One ring zone per `_mcSelected` entry. Naming: `worldMC1, worldMC2, ..., worldMCN` (World) and `charMC1, charMC2, ..., charMCN` (Char). Inserted dynamically into the ring on MC state change via `_rebuildWorldMCRingZones` / `_rebuildCharMCRingZones`. Replaces the old single `worldLootMCColumns` / `charLootMCColumns` zones. |
| **MC ring restructuring** | The S108 rebuild flow. On MC toggle: remove existing `worldMC%d+$` / `charMC%d+$` zones from `win._focusRing` (regex match), find insertion point (before mainInv), insert N new zones with per-slot uiRange + element list. Focus restored by zone NAME (not index, since indices shift). Called from `_syncWorldRingZones` / `_syncRingZonesToActiveTab` AND from FIFO-eviction paths. |
| **MC slot** | The 1-based index into `_mcSelected` that identifies which container an MC zone covers. `slot=1` → `_mcSelected[1]` → `colStates[1]`. The MC builder takes `slot` as a param: `_buildWorldMCColumnFocusables(win, slot)`. Closures inside the builder capture `slot` via `local capturedSlot = slot` to avoid loop-variable issues. |
| **MC empty placeholder** | When an MC column's container has 0 items, the builder emits a single element with `isPlaceholder = true` and no-op activate/hold/contextMenu callbacks. Keeps the zone focusable so bumper doesn't skip empty containers. Same pattern applies to `worldMainInv` when MC is active + main col empty (Char's mainInv = player inv = effectively always populated, doesn't need it). |
| **Card source tracking** | `win._cardSrcZone` (string, e.g. "worldMC2") + `win._cardSrcElIdx` (int). Set by the inv-zone D-pad dispatch when opening the card (LEFT in Char, RIGHT in World). Read by the card zone's edge-exit dispatch (RIGHT-past-rightmost in Char, LEFT-past-leftmost in World) to return focus to the inv item that opened the card. |
| **Atomic card open + jump** | The S108 dispatch pattern: `updateDrawer()` → synchronous `_buildCardActionFocusables(win)` → `Focus.setRingZoneElements(card, els)` + `setZoneFocusable(true)` → `_jumpToZone("*ItemCard")`. All in one frame. Without the sync refresh, the per-frame card zone refresh runs NEXT frame and the first jump fails. |
| **Card-open inv-shrink mode** | The S108 window-expansion gate: `if mcActive and win._drawerMode == "item" then` — DON'T expand window. Inv area shrinks when card opens (drawer width subtracted from invW), FIFO evicts oldest MC col if perCol drops below MIN_COL_W. Tab drawer opens still expand window (pre-existing behavior). |
| **MC main badge** | The `#_mcSelected + 1` number drawn at bottom-left of the floor (World) or main player inv (Char) container button when MC is active and main is visible. Marks main as the (K+1)-th column in the displayed MC layout. Floor itself never enters `_mcSelected` (toggle = visibility, not membership), so badge is computed from position-in-colSel rather than `_mcSelected` lookup. |
| **MainInv duplicate guard** | World-only condition: when `colN <= mcN` (every colSel entry is covered by a `worldMC<n>` zone, no extra "main" column appended), `worldMainInv` is forced non-focusable so it doesn't duplicate the last MC zone. Bumper from rightmost MC goes directly to next focusable zone (typically tabBar) instead of stopping on a duplicate mainInv. Char never hits this case because Char always appends `containers[1]` (player inv, hardcoded), which never enters `_mcSelected`. |

## Contextual Drawer Vocabulary (Session 115)

Radio is the first instance of a "contextual drawer" — a tab whose visibility is gated on whether at least one matching engine entity is reachable from the player. The chassis-style visual language is reusable across future contextual drawers (washer, generator, oven, sink, anything with brand-tier variants).

| Term | What it is |
|---|---|
| **Contextual drawer** | A tab in the Char/World window whose `visible(win)` predicate returns true only when player has matching items in scope. Differs from informational tabs (Foraging always-visible) — these come and go with player context. Radio = equipped radios (Char) / IsoWaveSignal radios in 3x3 player range (World). |
| **Chassis** | The full visual surface a contextual drawer paints, edge-to-edge inside the drawer column. Replaces System 7 grey panel framing. Each tier (Premium silver, ValuTech black plastic) has its own chassis identity. |
| **Brand tier** | Visual variant within a chassis category. Discriminator at runtime via engine getter (radio: `getIsHighTier()`). Premium = luxury/hi-fi look (silver Pioneer-style + cyan VFD); ValuTech = budget look (black plastic + amber LCD, INVERSE display palette). |
| **Recessed panel** | 4-edge bevel atom (`AtomExtensions.recessedPanel`) — top+left dark, bottom+right light. Inset look. Used for control strip + preset bank + CD module backgrounds inside chassis. Sibling: `raisedPanel` (inverted bevel, outset). |
| **Silkscreen label** | Static chassis text rendered straight on the chassis surface with `panel:drawText` using the tier's `silkScreen` color token (e.g., `T.radio.pt.silkScreen` = `#D8D8D8` light grey on silver). Plastic labels NEVER change at runtime. Used for SEEK / VOL / Power / brand bars / CD module model number. |
| **Chassis molecule** | Domain-specific molecule that lives in the contextual drawer's own module file (NOT in `Molecules.lua`). Examples: `radioMainDisplay`, `radioControlStrip`, `radioPresetBank`, `cdPlayerModule`, `brandBar`, `radioSignalWave`. They consume Atoms + general Molecules but encode chassis-specific layout. |
| **Drawer-internal header** | Generic 37px strip at the top of a contextual drawer's tab content. Format: `[<] [pill: Location (idx)] [>] | subtitle`. Returns `prevZone, nextZone` rect pairs to caller for hit-testing. NO bg paint — inherits parent panel surface. Reusable for ANY future contextual drawer. Lives in `Molecules.lua`. |
| **Browse state** | Per-window state for cycling among multiple matching entities. `win._<kind>Idx` (1-based), wraps via `_browsePrev` / `_browseNext`. The `(idx)` suffix on the location pill shows which entity is current. |
| **Effective power** | The "is the device really running" gate, combining user-on-switch with usable-power. Pattern: `userOn AND (hasBattery+charge>0 OR canBePoweredHere)`. Mirrors vanilla `ISRadioAction:isReallyRunning`. Anti-exploit: prevents dead-battery readout exploits where the player would otherwise see live frequency / station / signal data through an "off" device. |
| **Off-state visual contract** | (S115 ruling) When effective power is false, conveyed via: bg color shift (LCD grey-green olive `#8E8F72` / VFD near-black `#1A1A1A`), bar/chip dim to 35% alpha, dynamic data replaced with placeholders (`---.- MHz`, suppressed station name, SIG dashes), chips fill+dim (LCD ghost-segment look), text colors UNCHANGED. Frequency Y-position frozen across power states. |
| **Cache key** | Stable per-entry identifier stamped at discovery time. Equipped radios use slot tag (`"eq:Primary"` / `"eq:Secondary"` / `"eq:Back"`); world radios use `string.format("w:%d,%d,%d", floor(x), floor(y), floor(z))`. Avoids `getID()` log spam (Q119/Q121 patterns) by computing identity from already-known coordinates. |
| **Wave cache** | Per-window dict `win._<kind>WaveCache[cacheKey] = {col1, col2, ..., col64}`. Stable harmonic sine generated once per cacheKey from a deterministic seed (cacheKey hash). Pruned in 30-frame refresh against the new cacheKey set. Spec hard rule #8: signal wave ALWAYS renders, even when off — power state only modulates line color alpha. |
| **Assign mode** | (Preset interaction model, S115) Click "+" → `win._radioPresetAssignMode = true` → "+" button pulses to bright accent → next click on a numbered slot stores the current frequency in that slot. Browse cancels assign mode. NO separate "-" remove button. The same "+" button toggles back out of assign mode if clicked twice. |
| **Hold-to-repeat seek** | (S115) Press a SEEK button → fires once + arms `win._radioSeekHold = { dir, startMs, lastFireMs }`. Per-frame `render()` checks `isMouseButtonDown(0)`; while held + past 250ms initial delay, fires `_channelStep(dd, dir)` at an accelerating interval (200ms → 100ms → 50ms → 25ms across 1s/2.5s/5s thresholds). Released the moment mouse-up is detected. |
| **Equipped disclosure** | (S115 Equipment tab refactor) Pinned header now reads "Equipped" (was "Defense"); disclosure toggles the equipped slot list visibility via `win._equipListExpanded`. Defense body (figure + stats) is unconditionally rendered at the bottom of the tab regardless of disclosure state. `T.sp.figurePadTop` (12px) gap between list and body. |
| **`T.sp.tabHeaderH`** | (S115) Single source of truth for drawer-header strip height (37px). Sourced by `Molecules.TAB_HEADER_H`, `Molecules.drawDrawerInternalHeader.stripH`, `RadioTab.render.headerH`, `MapsTab.MAP_TOOLBAR_ROW_H`, `EquipmentTab.headerH`, `CraftingCore.HEADER_H`. Tune in one place, all consumers update. |
