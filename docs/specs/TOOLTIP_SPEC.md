# ZeD_ItemCard — Design Spec (v11 — Revised Dock + Soiled Flags)

## Reference
Mac System 7.1.2 "About This Macintosh" panel layout.
Two-column data sheet. The card is both diagnostic readout AND workbench.

## Interaction Model — Three Tiers of Attention

### Tier 1: Balloon Tooltip (hover)
- Name + optional one-line description. That's it.
- Already handled by Overrides/Tooltip.lua — NOT part of this spec.

### Tier 2: Item Card Drawer (click/select in inventory)
- Full About This Macintosh layout (icon, name, stats, bars).
- INFO ZONE + ACTION STRIP. No detail zone, no editable name.
- Chromeless panel — no window chrome, no title bar.
- Anchored to inventory window edges.

### Tier 3: Inspect Window (right-click → "Inspect Item")
- Same info zone + action strip + DETAIL ZONE + editable name field.
- Full ZeD_Window chrome: striped title bar, close box, grow box.
- Draggable, resizable, persistent. Finder "Get Info" crossed with a workbench.

## Card Architecture (revised v11)

Three strata, top to bottom. Pure data above, pure interaction below.

```
┌─ TITLE BAR (window chrome) ─────────────────┐
│ [×] Item Name                                │
├─ INFO ZONE (stat lines) ────────────────────┤
│                        :                     │
│ [icon] Item Name       : STAT LABEL   Value  │
│        (wraps if long) : STAT LABEL   Value  │
│        "Custom Name"   : STAT LABEL   Value  │
│                        :                     │
│ CATEGORY    Type       : WEIGHT       X.X kg │
│─────────────────────────────────────────────│
│ CONDITION      72%     : [██████████░░░░░░]  │
├─ ACTION STRIP (toggles left, verbs right) ──┤
│ [★] [⊘] [✕]              [Wash] [Dry] [Pad] │
├─ DETAIL ZONE (per-zone inspection) ─────────┤
│ TORSO        82%  [Leather]🪡 :              │
│ 🩸5% 🟤2%                    :              │
│─────────────────────────────────────────────│
│ L. SLEEVE    20%  [Torn──]🪡 :              │
│ 🩸15% 🟤23% 💧8%             :              │
│─────────────────────────────────────────────│
│ R. SLEEVE   100%  [——————]✓  :              │
│                               :              │
│─────────────────────────────────────────────│
│ COLLAR       60%  [Worn──]🪡 :              │
│ 🟤12%                        :              │
└─ FOOTER [grow box] ─────────────────────────┘
```

## The Three Strata

### 1. Info Zone — pure readout
50/50 two-column grid. Left: icon + name + category. Right: stats + weight.
Below the rule: overall condition label + fill bar.
NO interactive elements in the info zone. Data only.
Item name wraps to multiple lines if too long (calcHeight adjusts).

### 2. Action Strip — item-level controls
Split layout: toggles left-aligned, verb icons right-aligned.
- **Left:** [★ Favorite] [⊘ Protect] [✕ Unwanted] — state toggles
- **Right:** Context-sensitive batch verbs, depends on item type:
  - Clothing with detail zone: [Wash] [Dry] [Repair All] [Pad All]
  - Weapon without detail zone: [Repair] [Sharpen]
  - Food: [Eat] [Cook]
  - Literature: [Read]
  - Drainable: [Refill]
  - Generic: whatever's applicable
- All buttons: 22px × 22px, 1px border, 4px icon padding, `borderDoubleRounded` `{2, 1}` radius
- Verb buttons: no accent shade on hover (differentiated from toggles)

**Rule:** Items with a detail zone put per-zone structural actions there. Batch actions (Repair All, Pad All, Wash, Dry) go in the strip. Items without a detail zone put all their verbs in the strip.

### 3. Detail Zone — per-zone inspection + action (clothing only for now)
Only appears on items with zone data (clothing, armor, maybe vehicles later).
Items without zones (knife, book, food) end at the action strip.

Each body part is a **zone block** with two lines:

**Top line (stat + structural dock):**
```
| ZONE NAME    Pct%  [Flag──]🔧 |
```
- Zone name (mono, uppercase, textSec) + percentage
- Structural dock: flag label (state) + action button (repair/remove/pad)

**Bottom line (soiled flags):**
```
| 🩸15% 🟤23% 💧8%              |
```
- Soiled flags: colored text labels only (NO buttons)
- Blood = red text, Dirt = brown text, Wet = blue text
- Purely diagnostic — wash/dry are batch operations in the action strip

Zone blocks separated by 1px groove dividers.

## M15: Dock — Button-with-Flag Molecule (revised v11)

A fixed-size action button with a variable-width flag label docked to its left edge. The flag is the readout, the button is the action. Two elements that read as one unit.

```
┌────────────┐┌──┐
│  Leather   ││🪡│   ← flag (variable width) + button (fixed 22px square)
└────────────┘└──┘
```

**Redesigned in Session 15:** Original v10 spec was "pill+button pair" with both soiled and structural variants having buttons. Final implementation is "button-with-flag" — flag docks to button's left edge. Soiled indicators became flag-only (no button).

### Component Anatomy
- **Flag portion:** variable width, same 22px height as button
  - 1px border (no right border — shares with button)
  - Background: transparent
  - Label: zone state text (Torn/Worn/Leather/Denim/—), colored by semantic meaning
  - No fill bar in flag (pure text label)
- **Button portion:** fixed 22px × 22px square
  - `borderDoubleRounded` with `{2, 1}` radius
  - 4px icon padding
  - Icon inside: context-sensitive
  - Same active/greyed/hover behavior as all other buttons
  - No accent shade on hover (verb behavior)
  - Tooltip on hover explains the action

### Structural Dock (condition — the only dock variant with a button)

Used on the top line of each zone block. Shows zone structural state + action.

- Flag label shows zone state:
  - **TORN** — danger red text. Hole present.
  - **WORN** — warning amber text. Degraded, not torn.
  - **Ripped Sheets** — white text (dark theme) / black (light theme). Patched with fabric.
  - **Denim** — #5b8abf indigo blue text. Patched with denim.
  - **Leather** — #b08a5e tan text. Patched with leather.
  - **—** (dash) — textSec. Pristine, no damage, no patch.
- Button icon changes based on zone state:
  - Hole present → needle (repair)
  - Padded, no hole → scissors (remove padding)
  - Pristine → checkmark (greyed, nothing to do)
- Tooltip: "Repair hole — Ripped Sheets ×1" or "Remove leather padding"

### Soiled Flags (NO button — flag-only indicators)

Used on the bottom line of each zone block. Diagnostic readout only.

- Colored text labels showing percentage:
  - **Blood:** #ff6b6b red text — "🩸15%"
  - **Dirt:** #c89860 brown text — "🟤23%"
  - **Wet:** #60b0e8 blue text — "💧8%"
- No button, no border, no fill bar
- Wash and dry are batch operations surfaced as verb buttons in the action strip
- Rationale: soiled state is item-level, not per-zone actionable. Per-zone blood levels are diagnostic info, not individual action targets.

### States
- **Active:** clickable, icon in textSec, hover highlights (no accent shade for verbs)
- **Greyed:** opacity 0.45, pointer-events none, border dimmed

### Dock Styling Rules
- Same height as ALL buttons on the card: 22px (T.buttonH)
- `borderDoubleRounded` with `{2, 1}` radius
- 4px icon padding on button
- Flag drops right border, button keeps all four → seamless junction
- Hover highlights button only (not flag)
- Greyed dims the entire dock

## Zone Flag Colors

Flags are text labels colored by semantic meaning (inside the structural dock flag portion):

### Damage Flags
- **TORN** — var(--danger) red. Means hole present.
- **WORN** — var(--warning) amber. Means degraded, not torn.

### Patch Material Flags
- **Ripped Sheets** — rgba(255,255,255,0.75) (white in dark, black in light theme)
- **Denim** — #5b8abf (indigo blue)
- **Leather** — #b08a5e (tan brown, dark brown in light theme)

### Soiled Flag Colors (standalone text, not inside dock)
- **Blood** — #ff6b6b red
- **Dirt** — #c89860 brown
- **Wet** — #60b0e8 blue

## PZ Garment API (confirmed from source — ISGarmentUI.lua)

### Per-Zone Data
```lua
clothing:getCoveredParts()                    -- list of BloodBodyPartType
clothing:getVisual():getHole(part)            -- > 0 means torn
clothing:getPatchType(part)                   -- nil or patch material
clothing:getDefForPart(part, isBite, isBullet) -- defense % per type
clothing:getBloodlevelForPart(part)           -- blood level per zone
clothing:canFullyRestore(playerObj, part, fabric) -- can repair fully?
```

### Materials Required
```lua
thread = inventory:getItemFromType("Thread", true, true)
        or inventory:getItemFromTag(ItemTag.THREAD, true, true)
needle = inventory:getItemFromType("Needle", true, true)
        or inventory:getFirstTagRecurse(ItemTag.SEWING_NEEDLE)
fabric1 = inventory:getItemFromType("RippedSheets", true, true)
fabric2 = inventory:getItemFromType("DenimStrips", true, true)
fabric3 = inventory:getItemFromType("LeatherStrips", true, true)
```

### Repair Actions (existing PZ timed actions)
```lua
ISRepairClothing:new(player, clothing, part, fabric, thread, needle)
ISRemovePatch:new(player, clothing, part, needle)
ISInventoryPaneContextMenu.repairAllClothing(player, clothing, parts, fabric, thread, needle, onlyHoles)
```

### Soiled Data
```lua
clothing:getBloodlevelForPart(part)   -- blood (per zone)
clothing:hasDirt()                    -- dirt (item level, not per-zone)
clothing:getWetness()                 -- wetness (item level)
```

## Button Vocabulary (unified across entire card — revised v11)

All buttons: 22px height, 1px border, 4px icon padding, `borderDoubleRounded` `{2, 1}`. Same visual family.

| Button Type | Location | Shape | Content | Hover |
|---|---|---|---|---|
| Toggle | Action strip left | 22×22 square | Icon, on/off state color | Accent shade |
| Verb | Action strip right | 22×22 square | Icon, active/greyed | No accent shade |
| Dock (structural) | Detail zone top line | Flag + 22×22 button | State label + action icon | No accent shade |
| Padding | Detail zone bot line | 22×22 square | Fabric icon, active/greyed | No accent shade |

Soiled indicators are **text flags, not buttons** — colored percentage labels on the bottom line.

## Item Name Wrapping (added v11)
- Item name in info zone wraps to multiple lines if wider than available column
- calcHeight() accounts for wrapped line count
- No truncation on name — full name always visible
- Long names push stat rows down

## Corner Radius (revised v11)
- All pressable elements: `{2, 1}` radius (outer, inner for double border)
- Structural containers: 0px (hard corners)
- `borderDoubleRounded` atom handles the System 7 double border rendering

## Item Rename System
(unchanged from v9 — see previous spec)

## Typography Rules (unchanged from v9)
- ALL labels: monospace, uppercase, textSec
- ALL values: sans-serif, T.text unless semantic override
- Item name: sans-serif, accent color
- No font size differentiation — hierarchy through caps and color

## Implementation Order (revised v11)

1. ✅ M11 drawStatRow molecule
2. ✅ M12 drawFillBar molecule
3. ✅ M13 drawBodyBg molecule
4. ✅ M14 drawActionStrip + updateActionStrip molecules
5. ✅ ZeD_ItemCard organism — 10 category formatters
6. ✅ InspectHook.lua — context menu → inspect window
7. ✅ Action strip toggles (fav/protect/unwanted) + window footer
8. ✅ M15 drawDock molecule — button-with-flag + soiled flags + borderDoubleRounded
9. ⏳ **Detail zone** for clothing — per-zone structural docks + soiled flags
10. ⏳ Action strip verb side — batch actions (Wash, Dry, Repair All, Pad All)
11. ⏳ Wire structural docks to repair/remove-patch timed actions
12. ⏳ Wire batch verbs to wash/dry timed actions
13. ⏳ Editable rename (ZeD_TextInput in inspect window)
14. ⏳ Item card drawer (inventory selection hook)
15. ⏳ Panel replacements: inventory → crafting → character info → HUD
