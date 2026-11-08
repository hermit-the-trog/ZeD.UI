# ZeD-UI — Crafting / Building Spec
## Version 1.0 · Locked April 12, 2026 (Session 81)

Canonical design for the unified Crafting + Building tab system. Applies equally to `CraftingTab.lua` and `BuildingTab.lua` — shared architecture, shared components, data providers differ.

---

## 1. Architecture

**Total drawer width: 480px. Never expands. Single-layer depth.**

```
┌─ 480w ──────────────────────────────────────┐
│ [Category: ▾] ·················· dropdown   │ ← static, always visible
│ [🔍 Search recipes..........................] │ ← static, always visible
├────────────────────────────────────────────┤
│ [Sort: Name · Freq · Recent]    [☐ All]     │ ← contextual strip
├────────────────────────────────────────────┤
│ recipe list fills 480w when no recipe       │
│                                              │
│                                              │
│ OR split 240 / 240 when recipe selected:    │
│                                              │
│ │ recipes │   craft card                   │
│ │  240w   │      240w                      │
└────────────────────────────────────────────┘
```

### Panes Behavior

| State | Left pane | Right pane |
|---|---|---|
| No recipe selected | Recipe list (full 480w) | Hidden |
| Recipe selected | Recipe list (240w) | Craft card (240w) |
| Recipe selected + slot w/ alts clicked | **Alt list** for that slot (240w) | Craft card stays (240w) |

### Transitions

- **Select recipe**: split animates open (`0 → 240w` on craft pane, list shrinks from `100% → 240w`)
- **Click same recipe**: toggle → split closes
- **Click different recipe**: card swaps in place, split stays
- **Click slot w/ alts**: left pane flips to alt mode (no width change)
- **Click same slot or [◀ Back]**: left pane reverts to recipe list
- **Close craft**: alt mode auto-exits with craft close

Animation: 280ms `cubic-bezier(0.4, 0, 0.2, 1)` on `flex` / `width`.

---

## 2. Static Header (480w, always visible)

### Row 1 — Category selector

```
[Category]  [-- All --                    ▾]
```

- Left: label `Category` in F1/Micro, `textSec` color
- Right: ZeD_Dropdown trigger, full-width after label
- Trigger click opens dropdown list below (absolute-positioned, max-height 260px, scrolls)
- Active category shows `✓` suffix in the list
- **In alt mode:** label → `Compatible`, trigger freezes (`cursor: default`, accent-tinted bg, no arrow), value → slot name

### Row 2 — Search box

```
[🔍 Search recipes...]                   [×]
```

- Magnifying glass icon + text input + clear button (hidden when empty)
- Placeholder: `Search recipes...` in list mode, `Filter alternatives...` in alt mode
- Search state persists **per-mode** (recipe search preserved when entering alt mode; alt search preserved only within a single alt session)
- Focus border: accent color

---

## 3. Contextual Strip (24px)

### List mode

```
Sort  [Name] [Freq] [Recent]          [☐ All]
```

- `Sort` label in F1/Micro textSec
- Three underline-tabs: Name / Freq / Recent — active mode gets accent color + 1px bottom border
- Right-aligned `All` checkbox toggle — status dot style (ZeD drawStatusDot)

### Alt mode

```
[◀ Recipes]  2/28 owned          [☐ Owned only]
```

- Left: back affordance, accent-colored, clickable
- Middle: read-only stat `N/total owned`
- Right: Owned-only filter toggle
- Strip bg: accent-tinted (`rgba(accent, 0.08)`) with 1px accent bottom border — visually signals "you are in alt mode"

---

## 4. Recipe List (240w when split, 480w when solo)

### Sections (in order, sticky headers)

1. **Pinned** — user-starred recipes. Accent-colored header.
2. **Frequently Used** — top 5 by craft count, warning-colored header. Pinned recipes excluded from this section (no double-listing).
3. **All Recipes** — everything else, neutral header. Renamed to `Results` when search is active.

Each section is collapsible via its header (disclosure arrow).

### Row anatomy

```
│ ▍ · 🪨 Stone Block · · · · · · · ·  ★ │
  ^  ^ ^  ^                          ^
  |  | |  name (ellipsis, F2 12px)   star (hover-appear, on=accent)
  |  | icon (14px, filter:saturate 0.85)
  |  status dot (6px, can/miss/unk)
  selection edge (2px accent bar when row is selected)
```

- Row height: **24px**
- Background: alternating stripe (even rows `rgba(255,255,255,0.022)`)
- Missing-ingredients rows get a red whisper bg (`rgba(danger, 0.06)`)
- Unknown (not learned) rows: italic name, dim color
- Selected: accent bg + 2px accent left edge
- Star: appears at 50% opacity on hover, on=accent full opacity
- Frequently Used section adds a freq badge `×47` inline beside name (warning color)

### Row click behavior

- Click row (not star) → `handleRecipeClick(id)` → toggle selection
- Click star → toggle pinned state, persists in modData (no selection change)

### Status dot meaning

| Color | Meaning |
|---|---|
| Green glow | Craftable now — all inputs present |
| Red glow | Missing ingredients |
| Dim grey | Recipe not yet learned |

---

## 5. Craft Card (240w)

Top-to-bottom:

### 5a. Header block

```
┌────────────────────────────────┐
│ [🔥]  Advanced Forge           │
│       For the most advanced... │
└────────────────────────────────┘
```

- Icon 36×36 in 1px bordered box
- Name: F2 13px, SemiBold, accent color
- Description: F2 10px, textSec, `line-height: 1.3`
- No close button. Click selected recipe row in list to toggle, or select different recipe to swap.

### 5b. Chip row

Abbreviated status chips (240w can't fit full words):

| Chip | Meaning | Color |
|---|---|---|
| `LRN` / `UNK` | Learned / Unknown | positive / danger |
| `SFC` | Requires surface | warning |
| `LIT` | Requires light | warning |
| `N.Ns` | Craft time in seconds | neutral |

### 5c. Required Items section

```
┌────────────────────────────────┐
│ REQUIRED · 4 miss · 3/7        │ ← section header
│ ▍ 🪨 Stone Block  30/30  🗑    │ ← slot rows (24px)
│ ▍ 🔨 Sharp Knife ▾26  3/1  ↩  │   <- tag indicates 26 alts
│ ▍ 🪣 Clay Cement 1USE  1  ↩    │
│ ▍ ⚒️ Anvil       0/1  ↩       │
│ ...                            │
└────────────────────────────────┘
```

Slot row grid: `2px · 18px · flex · auto · 12px` = edge · icon · name+tag · count · consumable-flag

- **Status background**: missing slots get red whisper, selected slot gets accent bg + edge
- **Tag inline with name**:
  - Specific-item slot: text tag like `TOOL` or `1 USE`
  - Alt-backed slot: `▾N` tag where N is count of alternatives (orange bordered, clickable affordance)
- **Consumable flag** (right corner): trash icon = consumed, left-arrow = returned to inventory
- **Cursor**: only slots with alts are clickable (`cursor: pointer`), specific-item slots use `cursor: default`

### 5d. Outputs section

```
│ OUTPUTS · 1                     │
│ [blank] 🏭 Advanced Forge  ×1   │
```

Mirrors slot row grid, yield count right-aligned in accent.

### 5e. Action strip (pinned bottom)

```
│ [+][1][−]  3  [────── BUILD ─────]  │
```

- Stepper: `[+]` increment · readout (accent bg, F1 13px) · `[−]` decrement
- Max readout: bare number, F1 14px, `text` color (danger color when zero)
- Build button: accent outline + light accent fill; disabled grey when max=0 or recipe unlearned
- Build button on click: 800ms pulse animation, then timed-action fires in game

Action strip is `margin-top: auto` so it's always bottom-pinned even on recipes with few rows.

---

## 6. Alt Mode (Available Ingredients)

### Trigger

Click any slot row in the craft card that has `.alts` defined. Specific-item slots do nothing on click.

### Left pane swap

Same scroll container as the recipe list, different content:

```
┌──── Compatible with Sharp Knife ──┐
│ ✓ OWNED · 2                        │ ← section header, positive green
│ ▍ · 🔪 Kitchen Knife          1/1  │
│ ▍ · 🔪 Scrap Metal Large Knife 2/1 │
│ OTHER COMPATIBLE · 24              │ ← section header, textHead
│ · 🔪 Butterfly Knife          0/1  │
│ · 🗡️ Fighting Knife           0/1  │
│ · 🔪 Fillet Knife             0/1  │
│ ... (sorted alphabetically)        │
└────────────────────────────────────┘
```

### Alt row anatomy

Grid: `2px · 12px · 16px · flex · auto` = edge · dot · icon · name · count

- Row height: 24px (matches recipe list for visual consistency)
- Owned rows: `positive` left edge + positive-tint bg
- Other rows: no edge, dim text + dim count
- No star column (alts aren't pinnable)
- Non-interactive — alt rows are informational. No click action.

### Sort + filter

- **Sort**: Owned first (`have ≥ need`), then alphabetical within each group
- **Search** (in static header search box): filters alt list by name, live
- **Owned-only toggle** (in strip): hides the `Other Compatible` section when on

### Exit alt mode

- Click the same slot again in the craft card
- Click `[◀ Recipes]` button in strip
- Close the craft (X or toggle)
- Select a different recipe (alt mode auto-exits, craft swaps)

---

## 7. Data Providers

### HandcraftLogic integration

```lua
local logic = HandcraftLogic.new(player, craftBench, isoObject)
logic:setManualSelectInputs(true)

-- Event listeners drive UI refresh
logic:addEventListener("onUpdateRecipeList", self.onRecipeListChanged, self)
logic:addEventListener("onRecipeChanged", self.onRecipeChanged, self)
logic:addEventListener("onInputsChanged", self.onInputsChanged, self)
logic:addEventListener("onStartCraft", self.onCraftStart, self)
logic:addEventListener("onStopCraft", self.onCraftStop, self)

-- Recipe selection
logic:setRecipe(craftRecipe)

-- Enumerate buildable
local list = logic:getAllBuildableRecipes()
-- element:getCraftRecipe() → craftRecipe
-- recipe:getTranslationName(), :getIconTexture(), :getCategory() (lowercase — capitalize)
```

### Pinned / Frequent / modData

| Data | Source | Storage |
|---|---|---|
| Pinned recipes | User star toggle | `player:getModData().ZeD_PinnedRecipes[]` (list of recipe IDs) |
| Craft count (Frequent) | PZ `recipe:getNumberOfTimesCrafted()` — Java-native | Engine-side |
| Recent (TBD) | Timestamp at craft success | `player:getModData().ZeD_RecentCrafts[]` (LIFO queue, cap 20) |

### Alternative resolution

For a recipe input slot whose requirement is tag-based (e.g., `ItemTag.SharpKnife`):
1. Query `ScriptManager.instance:getAllItemsWithTag(tag)` → list of all script items
2. For each script item: `count = player:getInventory():getItemCount(fullType)`
3. Build alts list with `{name, icon, have, need}`
4. Specific-item slots (non-tag) have no alts — skip the click-to-flip affordance.

Script API to confirm at implementation:
- `CraftRecipeInput:getItems()` — direct item requirements
- `CraftRecipeInput:getItemTags()` — tag-based
- `CraftRecipeInput:getCategory()` — category filter

---

## 8. Layout Widths (frozen constants)

```lua
DRAWER_W        = 480    -- total drawer width
PANE_W_SOLO     = 480    -- recipes pane when solo
PANE_W_SPLIT    = 240    -- each pane when split
CRAFT_PANE_W    = 240    -- same as PANE_W_SPLIT, named for clarity
ROW_H           = 24     -- all list rows (recipe, alt, slot, output)
ACT_STRIP_H     = 42     -- action strip at bottom of card
HEADER_CAT_H    = 26     -- category row in static header
HEADER_SEARCH_H = 34     -- search row (6 top pad + 22 input + 6 bottom)
STRIP_H         = 24     -- contextual strip
```

---

## 9. Animation + Transition Rules

- **Pane split**: `transition: flex 0.28s cubic-bezier(0.4, 0, 0.2, 1)` on recipes pane, `transition: width 0.28s ...` on craft pane
- **Alt mode flip**: instant swap (no animation — flipping content of same container, instant feels right)
- **Build button pulse**: `animation: pulse 0.8s infinite` while timed action runs
- **Rule**: no nested scrolling — the outer pane scrolls, its children do not have independent scroll containers (Rule #9 from PROJECT_STATE)

---

## 10. Decisions Locked (Session 81)

1. **Full unification** — Craft + Build share sidebar + list + card. Data provider differs; UI identical.
2. **List style for required items** — no grid, no tiles. Spec-sheet rows with state-tinted bg.
3. **Slot have/need inline** — counts live in the slot row. No separate "Available Ingredients" right rail.
4. **Left pane flip for alternatives** — click slot with alts, left pane becomes the alt list for that slot. Rule #9 compliant. Vanilla's "Available Ingredients" concept, relocated.
5. **Category as dropdown** — vertical sidebar doesn't fit 480w. Dropdown in static header.
6. **Sort split** — list-affecting sorts (Name/Freq/Recent + All toggle) in the strip. Card-level reads (Learned, Surface, Light, Time, Yield) on the card as chips.
7. **Qty stepper + max readout in action strip** — `[+][qty][−]  max  [BUILD]`. No label on max (just the number).
8. **No close button on craft card** — click-toggle is the pattern. Selected recipe row in list deselects to close; different recipe swaps in place.
9. **Scroll-capped inline expand rejected** — would violate Rule #9 (scrolling inside scrolling).
10. **Three sections in list** — Pinned (deliberate), Frequently Used (emergent from craft count), All Recipes (everything). Each collapsible.

### Deferred to post-MVP

- Recent section (as section) vs. Recent (as sort mode) — currently Recent is a sort mode only. If demand emerges, add as third section.
- Per-character vs. global pinned — assumption is per-character (modData on IsoPlayer).
- Favorite star placement — currently hover-appears on list rows. Could add to craft card header too if requested.

---

## 11. Reference Mockup

Final interactive prototype at `ZeDUI/mockups/zed-crafting-unified-v1.html`. Three historical iterations preserved to show evolution:
- Grid vs. list comparison (`zed-craft-card-compare.html`)
- Three list prototypes (`zed-craft-card-3variants.html`)
- Refined Prototype 1 (`zed-craft-card-p1-refined.html`)
- Dual-column expansion attempt — rejected (`zed-craft-dualcol.html`)
- 480w internal split — adopted (`zed-craft-480split.html`)
- **Final: left-pane flip** (`zed-crafting-unified-v1.html`)

---

## 12. Implementation Priorities for S82

1. **New molecules** (add to `Molecules.lua`):
   - `drawCatDropdown` — compact dropdown, already have ZeD_Dropdown to extend
   - `drawSearchField` — if not already a reusable molecule
   - `drawSortStrip` — three-mode underline tabs + right-aligned toggle
   - `drawAltBackStrip` — alt mode contextual strip
   - `drawRecipeRow` — 24px row with dot + icon + name + star
   - `drawAltRow` — 24px alt row, owned-first variant
   - `drawSlotRow` — 24px craft slot row with alts-indicator tag
   - `drawQtyStepper` — `[+][qty][−]` group with disabled states
   - `drawCraftActionStrip` — stepper + max + build button

2. **Rewrite `CraftingTab.lua`** to the new architecture:
   - Static header (cat + search) in fixed top region
   - Contextual strip below
   - Panes container (flex) with recipes + craft child panes
   - HandcraftLogic wired to onRecipeChanged / onInputsChanged
   - Pinned persistence via `ZeD_PinnedRecipes` modData
   - Alt mode state machine (enterAltMode / exitAltMode / currentSlot)

3. **Rewrite `BuildingTab.lua`** to share the same architecture:
   - Replace HandcraftLogic with whatever the build-recipe equivalent is (script-defined buildables)
   - Pass different data provider into the shared rendering code
   - Everything downstream of data is identical

4. **Shared module** — Extract the common logic to `CraftingCore.lua` or `RecipeListRenderer.lua` module that both tabs require.

5. **Visual parity audit** — After code lands, verify against the mockup for: row heights (24px everywhere), status dot colors, accent tinting in alt mode, pane split animation timing, chip abbreviation casing.

---

End of spec v1.0
