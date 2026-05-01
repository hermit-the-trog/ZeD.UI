# Protection Tab — Concept C: Dashboard + Drill-down
## Design Spec v1 — Session 33 Brainstorm Output

**Status:** Approved for implementation. Replaces current ProtectionTab.lua (S31-S32).
**Mockup:** `mockups/zed-protection-concepts.html` (tab C)

---

## Core Insight

The player's question is "how protected am I?" not "what does each garment do?"
Concept C answers the glance question immediately with a dashboard, then offers
garment-level drill-down for the 10% of the time you need the deep data.

---

## Layout: Three Zones

```
┌─────────────────────────────────────────────┐
│ ZONE A: DASHBOARD (fixed)                   │
│ ┌──────┐  Grade: D                          │
│ │ body │  Bite avg: 2%                      │
│ │figure│  Worst: Head (uncovered)           │
│ │ mini │  Best: L.Foot (10%)                │
│ │      │  Uncovered: [6 of 18]              │
│ │      │  Garments: 4 equipped              │
│ └──────┘                                    │
│─────────────────────────────────────────────│
│ ZONE B: UNCOVERED (fixed, conditional)      │
│ [Head] [Neck] [L.Forearm] [R.Forearm] ...   │
│─────────────────────────────────────────────│
│ ZONE C: GARMENTS (scrollable)               │
│ ▸ 👕 T-Shirt — Police      [████░░] 3%     │
│ ▸ 👖 Police Pants — Deputy  [░░░░░░] 0%     │
│ ▸ 👟 Shoes                  [█░░░░░] 10%    │
│ ▸ 🧦 Long Socks             [░░░░░░] 0%     │
└─────────────────────────────────────────────┘
```

---

## Zone A: Dashboard (fixed height)

### Mini Body Figure (left column, ~90px wide)

Reuses `BodyFigure.lua` from Thermal tab at reduced scale.
Color-coded by **best bite defense** across all garments covering that part.

| Defense      | Color          | Figure Treatment                   |
|-------------|----------------|-------------------------------------|
| Uncovered   | `T.danger`     | Hatched pattern (45° repeating)     |
| 0-4%        | danger @ 0.6   | Solid dim red                       |
| 5-19%       | `T.warning`    | Solid amber                         |
| 20-49%      | `T.info`       | Solid blue                          |
| 50%+        | `T.positive`   | Solid green                         |

Figure renders via `BodyFigure.drawAt()` with a custom color map —
same API as Thermal tab, different color source.

### Summary Stats (right column)

**Letter grade** — large mono font, danger/warning/info/positive colored.

| Grade | Avg Bite Defense | Color        |
|-------|-----------------|--------------|
| F     | 0%              | `T.danger`   |
| D     | 1–14%           | `T.danger`   |
| C     | 15–34%          | `T.warning`  |
| B     | 35–59%          | `T.info`     |
| A     | 60%+            | `T.positive` |

Calculation: average bite defense across all 18 body parts.
Uncovered parts count as 0%.

**Stat rows** (below grade, mono labels + sans values):

| Label       | Value                                        |
|-------------|----------------------------------------------|
| BITE AVG    | Overall average as percentage                |
| WORST ZONE  | Name of lowest-defense covered part or first uncovered. Danger-colored. |
| BEST ZONE   | Name of highest-defense part + percentage    |
| UNCOVERED   | `[X of 18]` as danger badge if X > 0         |
| GARMENTS    | Count of equipped clothing items             |

---

## Zone B: Uncovered Parts (fixed height, conditional)

Only rendered if uncovered parts exist. Hidden when fully covered.

Each uncovered body part rendered as a **danger pill**:
- `dangerDim` background, `danger` text, 1px `danger @ 0.3` border
- Mono font, 9px, uppercase
- Flex-wrap layout, 3px gap
- Same visual as mockup's `uncovered-pill` class

Abbreviated names for tight fit:
`Head`, `Neck`, `L. Forearm`, `R. Forearm`, `L. Hand`, `R. Hand`,
`U. Torso`, `L. Torso`, `Back`, `Groin`, `L. Thigh`, `R. Thigh`,
`L. Shin`, `R. Shin`, `L. Foot`, `R. Foot`, `L. UArm`, `R. UArm`

---

## Zone C: Garment List (scrollable, disclosure triangles)

### Collapsed Row (default state)

```
▸ [icon] Garment Name              [████░░] avg%
```

Components left to right:
1. **Disclosure triangle** — `▸` collapsed, `▾` expanded. Mono, textSec. Accent when expanded.
2. **Garment icon** — 22×22 box, surf1 bg, borderS border, item texture at 70% centered.
3. **Garment name** — sans, 11px, T.text. Ellipsis truncation if too long.
4. **Mini fill bar** — 50px wide, 3px tall. Fill = average bite defense across all zones.
5. **Average bite %** — mono, 10px, tier-colored. Right-aligned.

Whole row is a click target. Hover → surf1 bg.
1px bottom border (T.border) between rows.

### Expanded Detail (below collapsed row)

Slides open below the collapsed row. Indented 20px left. Surf1 background.
1px bottom border.

Per-zone rows inside:
```
ZONE NAME                    [████░░] bite%
```

- Zone name: mono, 9px, uppercase, textSec
- Fill bar: 40px wide, 3px tall, tier-colored
- Bite %: mono, 9px, tier-colored, right-aligned

**Scratch and bullet** — not shown by default. Available via hover tooltip
on the zone row: "Scratch: X% | Bullet: X%". Keeps the default view
focused on the survival-critical stat (bite defense).

### Garment Sort Order

Sort by average bite defense ascending (worst first — vulnerable garments
float to top, encouraging the player to upgrade them). Tie-break by name.

---

## Interaction Model

### State

```
_expandedGarments = {}   -- garmentIndex → true/false
```

- Click garment row → toggle `_expandedGarments[i]`
- Disclosure triangle rotates on toggle
- Content height recalculates for scroll
- Multiple garments can be expanded simultaneously

### Scroll

Zone A + Zone B are fixed (outside scroll region).
Zone C scrolls independently using existing `_protectionScroll` (ZeD_ScrollbarState).

---

## Data Model Changes

### gatherData() returns enhanced structure:

```lua
{
  garments = {
    {
      name = "T-Shirt — Police",
      condition = 100,
      conditionMax = 100,
      tex = <texture>,
      avgBiteDef = 3,          -- NEW: average bite % across all zones
      parts = {
        { name = "Upper Torso", biteDef = 5, scratchDef = 0, bulletDef = 0 },
        { name = "Back",        biteDef = 2, scratchDef = 0, bulletDef = 0 },
        ...
      },
    },
    ...
  },
  uncoveredParts = { "Head", "Neck", ... },
  bestPart  = { name = "L. Foot", biteDef = 10 },   -- NEW
  worstPart = { name = "Head",    biteDef = -1 },    -- NEW (-1 = uncovered)
  avgBiteDef = 2,                                     -- NEW: global average
  grade = "D",                                        -- NEW
  totalGarments = 4,
  totalParts = 18,                                    -- constant
}
```

### Per-body-part defense aggregation (for figure + grade)

Build a `partDefense` map: for each of the 18 body parts, find the
**maximum** bite defense across all garments covering that part.
Parts with no garment = -1 (uncovered).

```lua
partDefense = {}   -- partStr → max bite def (or -1)
for _, partStr in ipairs(ALL_PARTS) do
    partDefense[partStr] = -1
end
for _, garment in ipairs(garments) do
    for _, zone in ipairs(garment.parts) do
        local cur = partDefense[zone.partStr] or -1
        partDefense[zone.partStr] = math.max(cur, zone.biteDef)
    end
end
```

Grade calculation:
```lua
local sum = 0
for _, partStr in ipairs(ALL_PARTS) do
    sum = sum + math.max(0, partDefense[partStr])
end
local avg = sum / #ALL_PARTS
```

---

## What Changes from Current ProtectionTab.lua

| Current (S32)                    | New (Concept C)                         |
|---------------------------------|------------------------------------------|
| Garment-centric layout          | Dashboard-first, garment drill-down      |
| All zones visible immediately   | Collapsed by default, expand on click    |
| 2-col zone pairs                | Single-col zone list in expanded detail  |
| S:0 B:0 cryptic notation        | Bite-only default, scratch/bullet hover  |
| No summary / no figure          | Grade + figure + stats dashboard         |
| Comma-dump uncovered list       | Danger pills, flex-wrap                  |
| Green condition bars dominate   | Condition removed — bite defense is hero |
| No color coding on zones        | Tier-colored everything                  |

---

## Reuse & Dependencies

- **BodyFigure.lua** — reuse `drawAt()` with a protection-specific color map.
  New function: `BodyFigure.makeProtectionColorMap(partDefense)` returns
  color table keyed by partStr, using the tier color table above.
- **drawFillBar** — existing atom, used for garment avg bar + zone bars.
- **drawStatRow** — existing molecule, not used (dashboard has custom layout).
- **drawHeading** — existing atom for section headers.
- **drawGroove** — existing atom for dividers.
- **ZeD_ScrollbarState** — existing molecule for Zone C scroll.
- **tierColor()** — existing in ProtectionTab.lua, keep as-is.

### New atoms/molecules needed: none.

Everything composes from existing primitives. The dashboard layout is
custom draw calls in the render function — no new reusable components
needed unless we later want to extract the "grade display" as a molecule.

---

## Drawer Width

Keep at **480px** (same as current Protection tab and Skills tab).
The dashboard + garment list fits comfortably at this width.

---

## Open Questions (resolve before coding)

1. **Garment condition** — currently shown as a green bar. Concept C removes it
   entirely. Is that right, or should condition appear somewhere (maybe in
   expanded detail as a small text note)?

2. **Worst zone tiebreaker** — when multiple parts are uncovered, which one
   shows as "worst"? Proposal: head-to-toe order (Head first = worst callout
   since head bites are lethal).

3. **Figure click interaction** — should clicking a body part on the figure
   expand/scroll to the garment covering that part? Nice-to-have but adds
   complexity. Could defer to a later session.

---

*Spec written: Session 33, April 2, 2026.*
*Mockup: mockups/zed-protection-concepts.html (Concept C tab)*
