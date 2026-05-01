# FORAGING TAB — Implementation Spec

**Session:** S70 (design) → S71 (code)
**Status:** APPROVED — Ready for Code
**Mockup:** `ZeDUI/mockups/zed-foraging-quiet-v5.html`
**Target file:** `42/media/lua/client/ZeD/ForagingTab.lua` (NEW)
**Insertion point:** World Window, group 2, after MapsTab

---

## WHAT THIS IS

A new World Window tab that replaces vanilla `ISSearchWindow.lua` with a ZeD-native foraging panel. Single 480px drawer width. System 7 chrome. Gameplay-neutral — surfaces only data vanilla already calculates; never reveals spawn locations or roll outcomes before discovery.

The tab consolidates six vanilla foraging concerns into one calm panel:
zone state, stance selection, focus category, modifier breakdown, categories in range, and a live recent-finds feed.

---

## LAYOUT — TOP TO BOTTOM

At 480px wide, the tab stacks into these bands (heights in px):

```
┌─ title bar (22) ─────────────────────────────┐
│ × FORAGE                     ● L4  2378 XP ◢│
├─ hero (flex ~112) ───────────────────────────┤
│ [scene 112]  Deep Forest        │   6.8    │
│              [Good][Walking]    │   TILES  │
│              [Autumn][Overcast] │   +22%   │
│                                 │   NET    │
├─ stance row (26) ────────────────────────────┤
│ [◉ SEARCHING] [▲ CROUCH] [◎ AIM]            │
├─ focus row (flex ~38) ───────────────────────┤
│ [ Mushrooms             ▾ ]   30–45%        │
├─ more detail disclosure (22) ────────────────┤
│ ▸ MORE DETAIL                                │
├─ [expanded only] more body ──────────────────┤
│   ─ CATEGORIES IN RANGE ─── 9 · 3 LOCKED    │
│   ● Mushroom  Peak  │ ● Berry     In        │
│   ● Medicinal In    │ ● Wild Plant In       │
│   ● Firewood +50%   │ ● Insect    Common    │
│   ● Stone    Common │ ● Forest R. Rare      │
│   ● Animal   L5     │ ● Crafting  L6        │
│   ─ MODIFIERS ─────────── +22% NET          │
│   ● Eagle Eyed +1.0 │ ● Herbalist +0.2      │
│   ● Hunger    +12%  │ ● Overcast  −10%      │
│   ● Fatigue   −5%   │ ● Hat       −18%      │
├─ finds column header (16) ───────────────────┤
│    DIST  NAME                           WT  │
├─ find rows (20 each) ────────────────────────┤
│ ◈  3T N  Morel Mushroom                 0.1 │
│ ●  2T E  Wild Garlic ×2                 0.1 │
│ ◉  4T W  Oak Branch                     1.0 │
│ ...                                          │
│ [OR empty state: "Recent finds will        │
│  appear here" centered, dim Lekton]         │
├─ footer (20) ────────────────────────────────┤
│ ● ○  A R                    END · Toggle    │
└──────────────────────────────────────────────┘
```


---

## COMPONENT BREAKDOWN

### 1. Hero (flex height, ~112px)

Three-cell horizontal strip with `border-bottom: 1px borderS`:

**Cell A — Terrain scene** (112px wide, flex height)
- Gradient background suggesting forest biome
- Later: swap to real in-game thumbnail or procedural mini-tile render
- Sun/moon indicator dot top-right reflecting time of day
- Right border: 1px var(--border)
- **For S71 first pass:** solid dark green radial gradient is fine. Procedural scene deferred.

**Cell B — Info** (flex, pad 12px)
- Zone name: `Chicago 12pt`, color `textHead`, 6px bottom margin
- Chip row (flex-wrap, 4px gap) at bottom:
  - `[Good]` — condition chip, `.on` accent style
  - `[Walking]` — neutral chip
  - `[Autumn]` — `.pos` positive style
  - `[Overcast]` — `.warn` warning style
- **Chips read weather and season from vanilla, NOT date/time.** Date/time explicitly removed.

**Cell C — Radius/Net** (88px wide, left border 1px)
- Big number `6.8` — K22 Xanthus 26pt, color `accentBri`
- `TILES` label — Lekton 10pt, color `textDim`, 6px bottom margin
- `+22%` — K22 Xanthus 11pt, color `positive`
- `NET` label — Lekton 10pt, color `textDim`

### 2. Stance row (26px)

Three equal-width buttons, no inter-button spacing, inherit from existing molecule pattern:
- `◉ SEARCHING` — active state (accent-bordered, accent text)
- `▲ CROUCH`
- `◎ AIM`

Uses existing `drawButton` / `ZeD_Button` atoms. Active state = accentHov background + accentBri text.

### 3. Focus row (flex ~38px)

Padding 8px horizontal, 8px gap between elements.
- **No "Focus" label** — dropdown speaks for itself
- Dropdown (flex width): 22px tall, surf2 bg, borderS border. Value: Bahnschrift SBC 12pt. Arrow: 8px right-aligned.
- Chance readout: `30–45%` — K22 Xanthus 11pt, color `accent`, fixed right.


### 4. More Detail disclosure (22px)

Clean strip. NO stat chips, NO counts on the right edge.
- `▸` chevron 8px K22, left — rotates 90° when expanded
- `MORE DETAIL` — Lekton 10pt, color `textDim` (becomes `accent` when hovered or open)
- Clicking the full strip toggles `_moreDetailOpen` state on `win`
- Background: surf2, 1px border-bottom
- Hover: bg surf3, text color accent

### 5. More body (collapsed by default)

Only visible when `win._moreDetailOpen == true`. Contains two sub-sections, each with:

**Sub-header bar (16px):**
- Lekton 10pt label, color `accent`, pad 12px horizontal
- Right-aligned count — K22 for numbers, Lekton for word suffix, color `textDim`
- Background: surf2, 1px border top + bottom

**2-column stat grid:**
- CSS-grid style: 2 equal columns
- Each cell: 17px tall, pad 12px horizontal, 7px gap between dot/label/value
- Right border between columns (even children have no right border)
- Bottom border on all rows except the last 2
- Cell content: `[dot 6px] [LABEL flex Lekton 10pt] [VALUE K22 11pt]`

**Categories in Range** — 10 items (5 rows × 2 cols):
| Label | Value | Dot |
|---|---|---|
| Mushroom | Peak | `● acc` (glowing) |
| Berry | In | `● pos` |
| Medicinal | In | `● pos` |
| Wild Plant | In | `● pos` |
| Firewood | +50% | `● warn` |
| Insect | Common | `● dim` |
| Stone | Common | `● dim` |
| Forest Rare | Rare | `● info` |
| Animal | L5 | `● dim` + row `.dim` class (55% opacity) |
| Crafting | L6 | `● dim` + row `.dim` class |

**Modifiers** — 6 items (3 rows × 2 cols):
| Label | Value | Dot |
|---|---|---|
| Eagle Eyed | +1.0 | `● pos` |
| Herbalist | +0.2 | `● pos` |
| Hunger | +12% | `● pos` |
| Overcast | −10% | `● warn` |
| Fatigue | −5% | `● warn` |
| Hat | −18% | `● danger` |

**Critical rule:** Labels and values are NEUTRAL `text` color. Status dots carry ALL the color. Same dot language as S65 crafting tab status dots.


### 6. Recent Finds section

**NO title strip.** Column header goes directly below the More Detail disclosure (or below the expanded More body).

**Column header (16px):**
- Background surf2, 1px border top + bottom
- Pad 12px horizontal
- Lekton 10pt, color `textDim`, letter-spacing 42%, uppercase
- Columns: `[icon 20px gap] [DIST 48px] [NAME flex pad-left 6px] [WT 36px right-aligned]`
- **NO CAT column** — item name carries category information implicitly

**Find row (20px each):**
- Pad 12px horizontal, 1px border-bottom
- Icon: 14px × 14px, accent color, 6px right margin
- DIST: 48px, K22 11pt, accent color, left-aligned — values like `3T N`, `2T E`, `5T SE`
- NAME: flex, 6px left pad, Bahnschrift SBC 12pt, `text` color, ellipsis overflow
- WT: 36px, K22 11pt, `textDim` color, right-aligned
- Hover: bg surf3

**Empty state (when finds list is empty):**
- Centered vertical + horizontal flex, 24px padding
- Text: `"Recent finds will appear here"`
- Font: Lekton 10pt, 42% tracking, uppercase, color `textDim`, 60% opacity
- 1px border-bottom
- Column header still renders above the empty state so the UI structure is preserved

**Row data model (internal Lua table):**
```lua
{
  iconTex = Texture,         -- from ContextIcons / item fullType
  distance = 3,              -- integer tiles
  bearing = "N",             -- one of N/NE/E/SE/S/SW/W/NW
  name = "Morel Mushroom",   -- displayName (post-multiplier for stacks)
  weight = 0.1,              -- sum weight
  timestamp = 12345,         -- getGameTime():getWorldAgeHours() at find
  categoryName = "Mushroom", -- used for filtering, NOT displayed
}
```

**Ordering:** newest first (LIFO). Cap at 20 rows; older rows drop off.

**Bearing calculation:** compute from `(findX - playerX, findY - playerY)`, map angle to 8-compass cardinal. Vanilla `ISSearchManager` doesn't track this — we compute it at the moment of discovery using `player:getX()`, `player:getY()` and the spawned square's `x/y`.


---

## DATA SOURCES (all vanilla)

### Radius calculation
- `player:getPerkLevel(Perks.PlantScavenging)` — base foraging level
- Base radius per level: `3 + 0.7 * level` tiles (B42 formula, see PZAPI Q33)
- Max radius: `10 + traitBonuses` tiles
- Modifier stack from `forageSystem.lua` → effective radius calculation

### Conditions (weather + season)
- `ClimateManager.getInstance():getWeatherPeriod()` — overcast/rain/storm/clear
- `GameTime.getInstance():getNightsSurvived()` + month lookup → season (Spring/Summer/Autumn/Winter)
- `getCell():getEnvironmentInfo()` for zone type classification

### Zone detection
- `getCell():getGridSquare(x,y,z):getZone()` — returns vegetation biome
- Map to friendly name: ForestDeep → "Deep Forest", Vegitation → "Wild Plants", etc.

### Focus category
- Read/write `ISSearchManager.instance.searchFocus` — vanilla already has this
- Replacement chance range hardcoded per vanilla: 25–45% (Park Ranger higher)

### Categories in range
- `forageDefinitions.categories` — master category list
- Filter by current zone via `forageDefinitions.getCategoriesForZone(zoneType)`
- Per-category availability: check season, weather, skill level lock
- Status resolution: Peak / In / Common / Rare / Locked — derived from vanilla category flags

### Modifiers
- Iterate all vanilla modifier sources:
  - Traits: `player:HasTrait("EagleEyed")`, `player:HasTrait("Herbalist")`, Park Ranger profession
  - Body condition: `player:getStats():getHunger()`, `getFatigue()`, `getPanic()`
  - Weather penalty: `ClimateManager:getRainIntensity()`, darkness level
  - Gear: iterate worn items, check for head/face coverage penalty on PlantScavenging
- Sum into composite `+22% NET` displayed in hero right-cell

### Recent finds hook
- Hook `ISSearchManager.addIcon()` or `forageSystem.pickUpItem()` (whichever fires on discovery)
- On each call: compute bearing from player→square, push to `win._recentFinds` LIFO queue
- Queue cap: 20 items

---

## GAMEPLAY-NEUTRAL DATA CONTRACT

**MUST surface:**
- Current zone (post-discovery)
- Current radius
- Current modifiers (what's helping/hurting me)
- Categories in range (what types of things exist here)
- Recent finds (what I already picked up)

**MUST NOT surface:**
- Spawn locations of undiscovered items (no preview before pickup)
- Exact roll percentages for individual items
- Specific item spawns before the vanilla discovery event fires
- "Look over there for X" hints

This is an information surface, not a cheat menu. Every datum shown is data vanilla already knows and already calculates.


---

## INTEGRATION WITH WORLD WINDOW

### File: `42/media/lua/client/ZeD/ForagingTab.lua` (NEW)

Follow the MapsTab pattern exactly. Module shape:

```lua
require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"

ZeD = ZeD or {}
ZeD.ForagingTab = {}

-- render(win, x, y, w, h) → draws the entire tab content area
function ZeD.ForagingTab.render(win, x, y, w, h)
    -- 1. read fresh data (zone, radius, conditions, mods, finds)
    -- 2. draw hero (112px tall, 3-cell layout)
    -- 3. draw stance row (26px, 3 equal buttons)
    -- 4. draw focus row (~38px, dropdown + chance)
    -- 5. draw more-detail disclosure (22px, toggleable)
    -- 6. draw more-detail body IF expanded (variable height)
    -- 7. draw finds column header (16px)
    -- 8. draw find rows OR empty state
end

-- Mouse handlers — match MapsTab pattern
function ZeD.ForagingTab.onMouseDown(win, x, y)  end
function ZeD.ForagingTab.onRightClick(win, x, y) end
function ZeD.ForagingTab.onMouseWheel(win, dir)  end

-- State init on window open — called by ZeD_WorldWindow
function ZeD.ForagingTab.init(win)
    win._foragingStance = "searching"  -- searching|crouch|aim
    win._foragingFocus = nil            -- nil = no focus
    win._moreDetailOpen = false
    win._recentFinds = {}               -- LIFO, cap 20
end

-- Registration hook
function ZeD.ForagingTab.register(dispatchTable)
    dispatchTable["forage"] = ZeD.ForagingTab.render
end
```

### File: `42/media/lua/client/ZeD/ZeD_WorldWindow.lua` (EDIT)

Three surgical changes:

**1. Add require at top (after `require "ZeD/MapsTab"`):**
```lua
require "ZeD/ForagingTab"
```

**2. Extend `WORLD_TABS` — insert after maps entry:**
```lua
local WORLD_TABS = {
    { id = "loot",   label = "Loot",     group = 1, glyph = "L" },
    { id = "craft",  label = "Crafting", group = 1, glyph = "C" },
    { id = "build",  label = "Building", group = 1, glyph = "B" },
    { id = "maps",   label = "Maps",     group = 2, glyph = "M" },
    { id = "forage", label = "Foraging", group = 2, glyph = "F" },  -- NEW
}
```

**3. Extend `WORLD_TAB_DRAWER_WIDTHS`:**
```lua
local WORLD_TAB_DRAWER_WIDTHS = {
    craft  = TAB_DRAWER_W,
    build  = TAB_DRAWER_W,
    maps   = TAB_DRAWER_W,
    forage = TAB_DRAWER_W,  -- NEW
}
```

**4. Add registration call (after `ZeD.MapsTab.register`):**
```lua
ZeD.ForagingTab.register(WORLD_TAB_RENDERERS)
```

That's the entire World Window integration. Everything else (drawer state, tab strip rendering, MC capacity, snap-back) is already in place and tab-agnostic.


---

## CONTEXTUAL TAB BEHAVIOR

Per the master architecture (S21), foraging is a **contextual** tab. It appears/disappears based on world state:

**Show the Forage tab when:**
- `ISSearchManager` is active for the player
- OR player has used the "Investigate Area" or similar vanilla forage trigger
- OR player is holding/equipped a foraging tool and standing in a vegetation zone

**Hide when:**
- Player exits forage mode
- Player leaves all vegetation zones (urban, indoor, water)

**Implementation:** Add a `visible(player)` predicate to the WORLD_TABS entry and filter in `drawActionTabStrip`. MapsTab is always visible (group 2 decorative); Forage is the first truly contextual tab so this pattern needs a small extension.

**Deferred for first pass:** For S71, ship with the Forage tab ALWAYS visible in group 2. Wire the contextual visibility predicate in S72 once the static panel is working. This lets us test the UI without wrestling ISSearchManager state machine in the same session.

---

## ENGINE QUIRKS TO REMEMBER

From PZAPI-KNOWLEDGE-BANK.md (abbreviated):

- **Q12:** Every component reads `ZeD.T` fresh each frame in `prerender()`. Zero stale data.
- **Q17:** No `ISResizeWidget` — custom grow box on window chrome only. Tab content has no resizers.
- **Q19:** No `ISScrollingListBox` — use `ZeD_ScrollList` for recent finds if list grows beyond visible area.
- **Q22:** No scrolling inside scrolling. If the More Detail body + finds list overflows at small window heights, the OUTER tab content scrolls, not an inner scrollable region.
- **Q27:** For gamepad input: `player:setJoypadIgnoreAimUntilCentered(true)` when stance buttons receive focus.
- **Q31:** Split-screen safety: use `getPlayerScreenLeft/Top/Width/Height(playerNum)` for any screen-space bounds checks.

---

## VISUAL TOKEN REFERENCE

All colors, fonts, spacing via `ZeD.T`. Do not hardcode.

**Fonts:**
- `ZeD.Font.fontTitle` — window title bar (Bahnschrift Bold 16)
- `ZeD.Font.fontHead` — zone name (Chicago 12)
- `ZeD.Font.fontSec` — labels, subheads, categories, chip text, button verbs (Lekton Bold 11/13)
- `ZeD.Font.fontBody` — find names, focus dropdown value (Bahnschrift SBC 13/15)
- `ZeD.Font.fontStat` — ALL numbers, bearings, XP, percentages, weights (K22 Xanthus 11/13)

**Colors:**
- `T.text`, `T.textDim`, `T.textHead` — neutral text tiers
- `T.accent`, `T.accentBri`, `T.accentHov` — brand green
- `T.positive` — positive status dots
- `T.warning` — amber status dots
- `T.danger` — red-orange status dots
- `T.info` — blue status dots (rare tier)
- `T.surf1`, `T.surf2`, `T.surf3` — layered backgrounds
- `T.border`, `T.borderS` — divider strokes
- `T.iconWhite` — neutral icon tint

**Atoms needed (all exist):**
- `A.drawRect`, `A.drawRectBorder`, `A.drawText`
- `A.drawStatusDot` — status dots (S69: glowing via shadow param)
- `A.drawTexture` — find icons from ContextIcons
- `A.drawHeading` — sub-section headers in More Detail

**Molecules needed (all exist):**
- `M.drawButton` — stance buttons, More Detail toggle
- `M.drawSectionHeader` — can be reused for sub-hdr strips
- `M.drawStatRow` — could reuse for stat grid cells, but custom 2-col grid may be cleaner
- `M.drawWindowTitleBar` — reused from ZeD_Window chrome

**New molecules? Probably not needed.** Everything should compose from existing atoms + molecules. If a new helper emerges during implementation (e.g. `drawStatGridRow`), document it and add to Molecules.lua rather than inlining.


---

## ACCEPTANCE CRITERIA

Code session S71 is DONE when:

1. ✅ `ForagingTab.lua` exists at `42/media/lua/client/ZeD/ForagingTab.lua`
2. ✅ World Window shows a new `F` tab in group 2 after Maps
3. ✅ Clicking the Forage tab opens the 480px drawer with the new panel content
4. ✅ Hero shows zone name, weather/season chips, radius value, net modifier — all reading live vanilla data
5. ✅ Stance buttons render and toggle active state on click (visual only for now — wiring to `player:setSneaking()` etc. can defer)
6. ✅ Focus dropdown renders with placeholder value; click opens a simple category picker
7. ✅ More Detail disclosure toggles open/closed, persists in `_moreDetailOpen` window state
8. ✅ When expanded, Categories in Range renders as 2-col grid with status dots — 10 entries visible
9. ✅ When expanded, Modifiers renders as 2-col grid with status dots — 6 entries visible
10. ✅ Recent Finds column header renders with `DIST · NAME · WT` layout
11. ✅ Find rows render with bearing + name + weight (use mock data for first pass)
12. ✅ Empty state renders when `_recentFinds` is empty
13. ✅ Zero console errors on tab open/close/switch
14. ✅ No crashes on drawer width transitions
15. ✅ Respects T.scale (text size preset works)
16. ✅ All 3 base themes (Dark/Light/HC) render without color bleeding

**Deferred to S72:**
- Hooking real `ISSearchManager` data into recent finds
- Bearing computation on real discoveries
- Contextual tab visibility predicate
- Focus dropdown functional wiring to vanilla `searchFocus`
- Real modifier enumeration from trait/gear/weather sources

---

## FILE CHECKLIST

**NEW:**
- `42/media/lua/client/ZeD/ForagingTab.lua`

**EDITED:**
- `42/media/lua/client/ZeD/ZeD_WorldWindow.lua` (require, WORLD_TABS, WORLD_TAB_DRAWER_WIDTHS, register call)

**REFERENCE:**
- `ZeDUI/mockups/zed-foraging-quiet-v5.html` — design canon
- `42/media/lua/client/ZeD/MapsTab.lua` — closest architectural twin

**NO CHANGES:**
- Tokens.lua (all required tokens exist)
- Atoms.lua / AtomExtensions.lua / Molecules.lua / Organisms.lua (all required helpers exist)
- ContextIcons.lua (existing foraging items already mapped)

---

## OPEN QUESTIONS FOR S71

1. **Stance button wiring** — Should clicking "Crouch" actually call `player:setSneaking(true)`, or is it purely a visual indicator of current state read from the player? **Decision:** Read from player state, clicking the button calls the setter. Bidirectional sync.

2. **Dropdown implementation** — Does ZeD-UI have a dropdown molecule already? If not, what's the simplest one we can stand up for this panel (and reuse elsewhere)? **Decision:** Check Molecules.lua first. If not, build a minimal `drawDropdown` atom + click-to-open popup. Low priority for first pass — can stub with a plain button that cycles values.

3. **Scrolling** — If the recent finds list grows past the visible area, should it scroll inside the finds section, or should the whole tab content scroll? **Decision:** Whole tab scrolls (Q22). Finds list is the last band — overflow pushes nothing.

4. **Icon mapping** — Forage items need `ContextIcons.lua` mappings. Audit coverage before S71.

---

**APPROVED BY:** Dude / Hermit — S70 design session, April 8, 2026
**HANDOFF TO:** Code session S71
**MOCKUP:** `ZeDUI/mockups/zed-foraging-quiet-v5.html`
