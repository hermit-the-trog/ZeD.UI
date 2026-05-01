# ZeD-UI Typography Research Report
## Font System for Dense Game UI — 220–800px × 400px Windows
**Version:** 1.0 | **Session:** Pre-22 | **Status:** Actionable for Code

---

## 1. The Constraint Landscape

Before evaluating any typeface, the hard constraints define the playing field.

### 1.1 Window Geometry
- **Width range:** 220px (minimum, narrow panel) → 800px (wide, stretched)
- **Height:** 400px (fixed reference)
- **Chrome overhead:** ~50px (title bar 22px + tab strip 22px + borders 3px)
- **Working content height:** ~350px usable
- **Target list density:** 20+ rows visible without scrolling in the primary content zone

From those numbers: **row height budget is ≤ 17px**. Font line height plus top/bottom padding must land inside that box. This is the single most restrictive constraint. Everything else follows.

### 1.2 The PZ Engine Font System

Project Zomboid renders all text via `getTextManager():drawText(font, text, x, y, r, g, b, a)` and its variants (`drawTextRight`, `drawTextCentre`). The `font` argument must be a member of the `UIFont` enum — **you cannot render arbitrary web fonts in-engine.** There is no way to load a custom TTF at runtime.

**Complete `UIFont` enum as found in Build 42.16 source:**

| Enum Value | Family Generation | Notes |
|---|---|---|
| `UIFont.Small` | Gen 1 bitmap | Default for ISButton. ~12px line height. |
| `UIFont.Medium` | Gen 1 bitmap | ~15px line height. |
| `UIFont.Large` | Gen 1 bitmap | Default for ISScrollingListBox. ~18px. |
| `UIFont.Normal` / `UIFont.normal` | Gen 1 alias | Same as Medium. Case inconsistency in vanilla source. |
| `UIFont.NewSmall` | Gen 2 refresh | Improved hinting vs Small. ~13px. |
| `UIFont.NewMedium` | Gen 2 refresh | ~16px. |
| `UIFont.NewLarge` | Gen 2 refresh | ~20px. |
| `UIFont.SdfRegular` | Gen 3 SDF (B42) | Vector, scales cleanly. ~16px at default scale. |
| `UIFont.SdfBold` | Gen 3 SDF (B42) | Bold weight. Same size as SdfRegular. |
| `UIFont.SdfBoldItalic` | Gen 3 SDF (B42) | Bold italic. |
| `UIFont.SdfOldBold` | Gen 3 SDF (B42) | Alternate bold, slightly different weight. |
| `UIFont.DebugConsole` | Special | Monospace. ~13px. Intended for debug overlays. |
| `UIFont.Handwritten` | Special | Map annotations. Not for UI chrome. |
| `UIFont.Cred1` | Special | Credits screen. Not for UI chrome. |

**Key API calls Code will use:**
```lua
-- Get actual line height of a UIFont value at runtime
local h = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()

-- Measure string width before drawing (critical for layout)
local w = getTextManager():MeasureStringX(UIFont.Small, "some text")

-- Draw text (x, y relative to parent panel)
self:drawText("label", x, y, r, g, b, a, UIFont.Small)
self:drawTextRight("value", x, y, r, g, b, a, UIFont.Small)
self:drawTextCentre("tab", x, y, r, g, b, a, UIFont.Small)
```

### 1.3 The Split Reality
ZeD-UI lives in two domains that must stay synchronized:

- **Mockup domain (HTML/CSS):** Web fonts. No engine constraint. Must approximate in-engine appearance as closely as possible to make mockups decision-useful.
- **Engine domain (Lua):** UIFont enum only. Font selection is constrained to what PZ ships.

This report covers both. The mockup stack drives visual decisions. The engine mapping drives code.

---

## 2. Small-Space Legibility: The Science

At 10–14px rendered size, not all fonts are equal. These are the measurable factors that separate functional from dysfunctional at our density target.

### 2.1 x-Height Ratio
x-height is the height of a lowercase 'x' relative to the cap height. At 12px total line height, a font with an x-height ratio of 0.45 gives you a 5.4px 'x' — essentially illegible. A ratio of 0.70 gives you 8.4px — readable. 

**Target:** x-height ratio ≥ 0.62 for any font used below 14px.

Practical examples at the extremes:
- Garamond: ~0.43 → collapses at small sizes
- Helvetica: ~0.52 → acceptable
- Inter: ~0.72 → excellent small-size legibility
- Geneva (original System 7): ~0.68 → excellent for its era

### 2.2 Aperture Openness
Apertures are the openings in letters like 'c', 'e', 'a', 'g', 's'. At small sizes, closed or partially-closed apertures cause those letters to look like blobs. Open apertures stay distinct.

- Futura: nearly closed 'e' aperture → falls apart below 11px
- Frutiger / Myriad: open → stays legible at 9px
- Geneva: deliberately open apertures (Kare's intent)

**Test sequence:** Set a candidate at 11px and read "ecoast" at arm's length. If 'e' reads as 'o', the apertures are too closed.

### 2.3 Stroke Contrast
High-contrast fonts (thick downstrokes, thin cross-strokes — Bodoni, Didot) are designed for large display sizes where the contrast creates elegance. At 11px, the thin strokes vanish or alias into mush. 

**Target:** Low stroke contrast (monolinear or near-monolinear) for all sub-14px roles.

Condensed humanist sans-serifs (Fira Sans, Fira Sans) are nearly monolinear — this is why they work so well at small sizes despite being optically narrow.

### 2.4 Condensed Width vs. Legibility
The obvious move for a 220px minimum panel width is condensed typefaces. The risk: condensed letterforms can collapse legibility. The safe path:

- **Humanist condensed** (Fira Sans, Fira Sans) → Based on humanist letterforms with normal apertures, just narrowed. Legibility survives condensing.
- **Geometric condensed** (Oswald, Gothic A1 Condensed) → Geometric purity at cost of aperture openness. Risky below 12px.
- **Grotesque condensed** (Trade Gothic Condensed, Bebas Neue) → Display-oriented, low x-height ratios. Avoid for body text.

### 2.5 Tabular Figures
For any numerical data — condition percentages, weight values, stack counts, skill XP — you need **tabular (monospaced) figures**. In tabular figures, every numeral is the same advance width, so columns align without any tricks. In proportional figures, '1' is narrower than '8', and right-aligned columns jump around visually.

Most monospaced fonts have tabular figures by default. Many variable or OpenType sans-serifs offer tabular figures as a `tnum` feature flag (`font-feature-settings: "tnum"`). In the PZ engine, you cannot use CSS feature flags — which means for numerical data, a true monospace UIFont is the reliable path.

### 2.6 Hinting Quality
Screen hinting is the set of instructions baked into a font that tells a renderer how to snap vector outlines to the pixel grid. Good hinting is the difference between 11px text that looks sharp and 11px text that looks fuzzy.

- Bitmap fonts (Gen 1/2 PZ UIFonts): No hinting needed — they're drawn pixel-by-pixel. Perfect at their designed size, ugly if scaled.
- SDF fonts (Gen 3): Anti-aliased, scale-independent, but the PZ engine doesn't expose size control through UIFont — you get whatever size the engine uses.
- Web fonts: Hinting quality varies. Google Fonts runs auto-hinting on non-hinted fonts. Fira Mono and Fira Sans have excellent built-in hinting.

---

## 3. The Five-Role Hierarchy

Five slots. Each slot defined by function, not aesthetics. The aesthetic is System 7.1.2 — the font selection serves that aesthetic, not the other way around.

### Role F1: CHROME
**Function:** Title bar text, tab labels, button labels, window control labels, section divider labels.  
**Character:** The most "designed" role. This is the voice of the chrome. Must feel like Mac System 7 — geometric, authoritative, machine-precise. Uppercase or title-case. High legibility at 11px. Consistent letter-spacing matters more than reading speed.  
**Competing requirements:** Narrow enough to fit multi-word labels in 22px-tall chrome without truncation. Heavy enough to read against the striped title bar pattern.

### Role F2: BODY
**Function:** List row labels, item names in lists, crafting recipe names, description text, general content.  
**Character:** The workhorse. Maximum legibility at 12px. Condensed to survive the 220px minimum width. Must handle both short labels ("Jacket") and longer strings ("Ripped Sheets of Fabric"). The reading speed font — users scan many rows quickly.  
**Competing requirements:** Must not steal visual hierarchy from F4 Heading. Must not feel lightweight against dark backgrounds.

### Role F3: DATA
**Function:** Numeric values — condition percentages, weight, temperature, skill levels, stack counts, XP bars, condition bars, stat readouts.  
**Character:** Monospaced. Tabular figures required. Aligns in columns. Can be the same typeface as F1 Chrome (they're both monospace) at a smaller or equal size. Feels computational, not decorative.  
**Competing requirements:** Must align vertically when right-justified next to variable-width labels. Must read at 10px (the smallest data label).

### Role F4: HEADING
**Function:** Item card names (the primary title), section group headers, modal dialog titles, active tab label.  
**Character:** Heavier or larger than F2 Body. Provides the top of the in-panel hierarchy. Not a display font — it still needs to be legible at 13–14px. One notch above Body in visual weight.  
**Competing requirements:** Must distinguish itself from F2 without requiring a size jump so large it breaks the 17px row budget.

### Role F5: MICRO
**Function:** Metadata labels ("weight", "condition"), filter chip text, badge text, category tags, timestamp text, secondary descriptors, moodle label text.  
**Character:** The smallest readable text in the system. 9–10px. Must hold its legibility with particularly open apertures and a tall x-height. Uppercase with tracking works well here — it counteracts the size reduction by adding air between letters.  
**Competing requirements:** Cannot be just a smaller F2 Body if F2 Body's apertures don't hold at 9px. May need its own family selection.

---

## 4. Typeface Evaluation Matrix

Candidates evaluated for each role. Scored 1–5 on each criterion.

### 4.1 Monospace Candidates (F1 Chrome + F3 Data)

| Typeface | x-Height | Aperture | Hinting | Density | System 7 Feel | Total |
|---|---|---|---|---|---|---|
| **Fira Mono** | 5 | 5 | 5 | 4 | 4 | **23/25** |
| Fira Mono | 5 | 4 | 4 | 4 | 4 | 21/25 |
| Fira Code | 4 | 4 | 4 | 3 | 3 | 18/25 |
| Roboto Mono | 4 | 3 | 4 | 4 | 3 | 18/25 |
| Space Mono | 3 | 4 | 3 | 2 | 5 | 17/25 |
| Courier New | 2 | 3 | 3 | 2 | 4 | 14/25 |
| Inconsolata | 4 | 4 | 4 | 4 | 3 | 19/25 |

**Winner: Fira Mono**  
Rationale: Engineered specifically for small-size screen legibility. Exceptionally open apertures — the 'r', 'a', 'e', 'c' letterforms were designed to prevent ambiguity at code-editor sizes (8–14px). Tall x-height (0.70+). Available on Google Fonts. Already established in ZeD-UI mockups (v10 item card). The only monospaced font in this list that scores 5 on both x-height and aperture simultaneously.

**Runner-up: Fira Mono** — Vercel's newer mono, clean, slightly more geometric. Lacks Fira Mono's hinting depth. Good alternative if Fira Mono needs to be swapped for any reason.

**Rejected: Space Mono** — despite the highest System 7 visual match (it looks like it fell out of an Apple IIe), the x-height is low and it gets squinty at 10px. Great for display use in mockups, wrong for body/data.

### 4.2 Sans-Serif Candidates (F2 Body + F4 Heading + F5 Micro)

| Typeface | x-Height | Aperture | Condensed | Hinting | Density | Total |
|---|---|---|---|---|---|---|
| **Fira Sans** | 5 | 5 | 5 | 5 | 5 | **25/25** |
| Fira Sans | 4 | 4 | 5 | 4 | 5 | 22/25 |
| Roboto Condensed | 4 | 3 | 4 | 5 | 5 | 21/25 |
| Source Sans Pro (Condensed) | 4 | 4 | 4 | 4 | 4 | 20/25 |
| Inter (not condensed) | 5 | 5 | 2 | 5 | 3 | 20/25 |
| Noto Sans Condensed | 4 | 4 | 4 | 4 | 5 | 21/25 |
| DM Sans | 4 | 4 | 2 | 4 | 3 | 17/25 |

**Winner: Fira Sans**  
Rationale: Fira was designed specifically for UI applications in software interfaces. The condensed cut has an extremely high x-height and open apertures that survive into the 9–10px range. The technical/corporate heritage maps directly onto System 7's personality — this is the font a 1992 Fira workstation would have shipped with, and it feels completely at home next to a striped title bar. Available on Google Fonts. Already established in ZeD-UI mockups (v10 item card). Weights available: 100, 200, 300, 400, 500, 600 — covering Body through Heading without switching families.

**Runner-up: Fira Sans** — more geometric, slightly more "modern" feel. Good if Fira Sans ever feels too corporate.

**Rejected: Inter** — exceptional legibility, wrong width for our constraints. Inter is a standard-width font. At 220px panel width with 24px left padding and 14px scrollbar, you have ~182px of usable text space. Standard-width sans-serifs truncate. Condensed wins this constraint.

**Rejected: Roboto Condensed** — partially closed 'e' aperture visible at 11px on dark backgrounds. The letters start to blob in the lower size range.

---

## 5. Recommended Font Stack

Two typeface families. Five roles. Maximum coherence, minimum complexity.

```
Family A: Fira Mono     → F1 Chrome, F3 Data
Family B: Fira Sans → F2 Body, F4 Heading, F5 Micro
```

This maps directly onto the System 7 tri-family model:
```
Monaco    → Fira Mono        (monospace, precision, alignment)
Geneva    → Fira Sans   (content, reading, information)
Chicago   → Fira Mono Bold   (chrome, authority, interface voice)
```

---

## 6. Size and Spacing Specification

All values are design targets for mockups. Engine values (UIFont enum) in Section 7.

### 6.1 Role Specifications

| Role | Family | Weight | CSS Size | Letter-spacing | Line Height | Uppercase? | Use Case |
|---|---|---|---|---|---|---|---|
| F1 Chrome | Fira Mono | 700 (Bold) | 11px | 0.5px | 14px | YES | Title bars, tab labels, button text |
| F2 Body | Fira Sans | 400 | 12px | 0px | 16px | NO | List rows, content, descriptions |
| F3 Data | Fira Mono | 400 | 10px | 0px | 14px | NO | Numbers, percentages, counts, stats |
| F4 Heading | Fira Sans | 600 | 13px | 0px | 16px | NO | Item card names, section headers |
| F5 Micro | Fira Sans | 400 | 9px | 0.8px | 12px | YES | Chips, metadata, badges, micro labels |

### 6.2 Row Height Budget Verification

With the 17px row budget constraint:

- **F2 Body list row:** 12px font + 2px top pad + 2px bottom pad = 16px row. ✓ Fits budget, 1px margin.
- **F1 Chrome tab:** 11px font + 5.5px top pad + 5.5px bottom pad = 22px. ✓ Matches tab strip height.
- **F5 Micro chip:** 9px font + 2px top pad + 2px bottom pad = 13px. ✓ Fits inside 22px button height with room.

### 6.3 Minimum Width Budget Verification

In a 220px panel, with 8px left margin + 14px scrollbar + 8px right margin = 30px overhead:
- **Available text width: 190px**
- At 12px Fira Sans, average character width ≈ 6.5px
- Characters per line: ~29 characters before truncation
- "Ripped Sheets of Fabric" = 24 characters. Fits. ✓
- "Improvised Hand Sanitizer" = 25 characters. Fits. ✓
- "Thick Padding (Leather)" = 22 characters. Fits. ✓

At 11px Fira Mono (monospace, ~7px per char):
- Characters per line: ~27 characters
- "EQUIPPED ITEMS" = 14 characters in chrome. Fits easily. ✓

---

## 7. Engine Mapping — UIFont Enum Assignments

How the five design roles map to actual PZ `UIFont` enum values.

### 7.1 Primary Assignments

| Design Role | UIFont Enum | Actual Family | Line Height (est.) | Notes |
|---|---|---|---|---|
| F1 Chrome | `UIFont.Small` | PZ bundled sans | ~12px | Vanilla button default. Closest match to 11px chrome target. |
| F2 Body | `UIFont.NewSmall` | PZ bundled sans refresh | ~13px | Cleaner hinting than Small. Preferred for list rows. |
| F3 Data | `UIFont.DebugConsole` | Monospace | ~13px | The only true monospace in the enum. Use for all numeric values. |
| F4 Heading | `UIFont.Medium` | PZ bundled sans | ~15px | One size step above Small for heading hierarchy. |
| F5 Micro | `UIFont.Small` | PZ bundled sans | ~12px | Same as Chrome — differentiate through context (uppercase + color only). |

### 7.2 Critical Engine Notes

**Verify line heights at runtime.** Do not hardcode assumed pixel values. At session open, run this diagnostic:
```lua
local function logFontHeights()
    local fonts = {
        "Small", "Medium", "Large",
        "NewSmall", "NewMedium", "NewLarge",
        "SdfRegular", "SdfBold", "DebugConsole"
    }
    for _, name in ipairs(fonts) do
        local f = UIFont[name]
        if f then
            local h = getTextManager():getFontFromEnum(f):getLineHeight()
            print("UIFont." .. name .. " lineHeight = " .. tostring(h))
        end
    end
end
```

**UIFont.DebugConsole is the only true monospace.** It was intended for the debug overlay console. It may have visual quirks at non-debug usage contexts (different background expectation, etc). Test it against both dark and light ZeD themes before committing.

**SDF fonts do not respect the "small" instruction.** The SDF family renders at a fixed pixel size determined by the engine. You cannot scale them down. They are vector-clean at their native size but that native size is approximately 16px line height — too tall for dense list rows. Reserve SDF for heading-equivalent text in wide-window contexts only.

**UIFont.Normal and UIFont.normal are the same.** Vanilla source has a case inconsistency. Always use `UIFont.Medium` explicitly rather than either Normal alias to avoid ambiguity.

**Measure before you draw.** Never assume a string width in a fixed-width column. Always `getTextManager():MeasureStringX(font, str)` before deciding whether to truncate.

---

## 8. CSS Token Definitions (Mockup Domain)

Copy-paste ready for HTML mockup CSS. Matches existing v10 item card foundation.

```css
/* ============================================================
   ZeD-UI TYPOGRAPHY TOKENS
   Google Fonts import required:
   @import url('https://fonts.googleapis.com/css2?
     family=Fira+Mono:wght@400;700
     &family=Fira+Sans:wght@400;500;600
     &display=swap');
   ============================================================ */

:root {
    /* ── Font Families ── */
    --font-mono: 'Fira Mono', 'Fira Mono', 'Courier New', monospace;
    --font-sans: 'Fira Sans', 'Fira Sans', sans-serif;

    /* ── F1: Chrome ── title bars, tabs, buttons */
    --f1-family:   var(--font-mono);
    --f1-weight:   700;
    --f1-size:     11px;
    --f1-lh:       14px;
    --f1-tracking: 0.5px;
    --f1-case:     uppercase;

    /* ── F2: Body ── list rows, content, descriptions */
    --f2-family:   var(--font-sans);
    --f2-weight:   400;
    --f2-size:     12px;
    --f2-lh:       16px;
    --f2-tracking: 0px;
    --f2-case:     none;

    /* ── F3: Data ── numbers, percentages, stats */
    --f3-family:   var(--font-mono);
    --f3-weight:   400;
    --f3-size:     10px;
    --f3-lh:       14px;
    --f3-tracking: 0px;
    --f3-case:     none;

    /* ── F4: Heading ── item names, section titles */
    --f4-family:   var(--font-sans);
    --f4-weight:   600;
    --f4-size:     13px;
    --f4-lh:       16px;
    --f4-tracking: 0px;
    --f4-case:     none;

    /* ── F5: Micro ── chips, badges, metadata labels */
    --f5-family:   var(--font-sans);
    --f5-weight:   400;
    --f5-size:     9px;
    --f5-lh:       12px;
    --f5-tracking: 0.8px;
    --f5-case:     uppercase;
}

/* ── Utility Classes ── */
.zed-chrome   { font-family: var(--f1-family); font-weight: var(--f1-weight); font-size: var(--f1-size); line-height: var(--f1-lh); letter-spacing: var(--f1-tracking); text-transform: var(--f1-case); }
.zed-body     { font-family: var(--f2-family); font-weight: var(--f2-weight); font-size: var(--f2-size); line-height: var(--f2-lh); letter-spacing: var(--f2-tracking); }
.zed-data     { font-family: var(--f3-family); font-weight: var(--f3-weight); font-size: var(--f3-size); line-height: var(--f3-lh); letter-spacing: var(--f3-tracking); font-variant-numeric: tabular-nums; }
.zed-heading  { font-family: var(--f4-family); font-weight: var(--f4-weight); font-size: var(--f4-size); line-height: var(--f4-lh); letter-spacing: var(--f4-tracking); }
.zed-micro    { font-family: var(--f5-family); font-weight: var(--f5-weight); font-size: var(--f5-size); line-height: var(--f5-lh); letter-spacing: var(--f5-tracking); text-transform: var(--f5-case); }
```

---

## 9. Lua Token Definitions (Engine Domain)

The single source of truth for engine font values. Lives in `Tokens.lua`.

```lua
-- ============================================================
-- ZeD Typography Tokens
-- Map design roles to UIFont enum values.
-- Actual line heights must be verified at runtime via:
--   getTextManager():getFontFromEnum(f):getLineHeight()
-- ============================================================

ZeD.T.Font = {
    -- F1: Chrome — title bars, tabs, button labels
    Chrome  = UIFont.Small,

    -- F2: Body — list rows, content, general UI text
    Body    = UIFont.NewSmall,

    -- F3: Data — numbers, stats, percentages (monospace)
    Data    = UIFont.DebugConsole,

    -- F4: Heading — item names, section headers
    Heading = UIFont.Medium,

    -- F5: Micro — chips, badges, smallest labels
    -- Shares enum with Chrome; differentiated by context + color only
    Micro   = UIFont.Small,
}

-- Cached line heights (call ZeD.Typography.init() on UIManager load)
ZeD.T.FontHeight = {}

ZeD.Typography = {}
function ZeD.Typography.init()
    for role, font in pairs(ZeD.T.Font) do
        ZeD.T.FontHeight[role] = getTextManager():getFontFromEnum(font):getLineHeight()
    end
end

-- Convenience: measure string width for a given role
function ZeD.Typography.measureWidth(role, str)
    return getTextManager():MeasureStringX(ZeD.T.Font[role], str)
end

-- Convenience: draw text using role token
function ZeD.Typography.draw(panel, role, str, x, y, r, g, b, a)
    panel:drawText(str, x, y, r, g, b, a, ZeD.T.Font[role])
end
```

---

## 10. Known Constraints and Landmines for Code

These are not opinions. These are behaviors confirmed or highly probable in the PZ engine.

**Landmine 1: Font heights are not what you think.** The line height returned by `getLineHeight()` includes internal leading — it is not the glyph cap height. The visual gap between your baseline and the next row's top is approximately `lineHeight - capHeight`. Do not use lineHeight as the row height unless you want double-spaced rows. Use `lineHeight - 2` to `lineHeight - 4` as your practical row height budget.

**Landmine 2: `UIFont.DebugConsole` may render with different color expectations.** Test it against ZeD dark and light themes before locking it in for F3 Data. It was designed for the debug overlay which has its own background. It may render with unexpected hinting or subpixel behavior on the ZeD surface alpha.

**Landmine 3: SDF fonts have no small-size variant.** Do not use `UIFont.SdfRegular` or `UIFont.SdfBold` in dense list rows expecting them to be smaller than their native ~16px line height. They will blow your row budget immediately.

**Landmine 4: `MeasureStringX` does not account for trailing whitespace.** Strip strings before measuring if they may have trailing spaces. `string.trim()` before any measurement call.

**Landmine 5: Font rendering varies by scale setting.** PZ supports UI scale (accessible via options). A player running 125% UI scale will see all font elements proportionally larger, which can cause overflow on elements sized to exact pixel budgets. Use relative sizing where possible and cap text truncation by measured width, not character count.

**Landmine 6: Uppercase via code.** The PZ engine does not expose CSS-equivalent `text-transform`. F1 Chrome and F5 Micro use uppercase — this must be done at the data level (`string.upper(label)`) before passing to `drawText`. Establish a convention: pass raw case-neutral strings through the Typography utility, and apply casing transformation inside the draw call for roles that require it.

---

## 11. Mapping Coherence Check

Final sanity pass: do the five roles communicate a clear hierarchy when assembled?

```
WINDOW TITLE BAR ─── F1 Chrome ─── Fira Mono Bold 11px UPPER ─── UIFont.Small
  Tab: EQUIPMENT ──── F1 Chrome ─── Fira Mono Bold 11px UPPER ─── UIFont.Small

  ┌── Section header: Torso ─── F4 Heading ─── Fira Sans 600 13px ─── UIFont.Medium
  │
  │   Row: Jacket (Leather) ─── F2 Body ─── Fira Sans 400 12px ─── UIFont.NewSmall
  │   Row: Work Shirt ──────── F2 Body ─── Fira Sans 400 12px ─── UIFont.NewSmall
  │
  │   Stat label: CONDITION ── F5 Micro ─── Fira Sans 400 9px UPPER ─── UIFont.Small
  │   Stat value: 87% ──────── F3 Data ─── Fira Mono 400 10px ────── UIFont.DebugConsole
  │
  └── Chip: LEATHER ────────── F5 Micro ─── Fira Sans 400 9px UPPER ─── UIFont.Small
```

Three clear tiers:
1. **F4 Heading** anchors section entries — heaviest weight, slightly larger
2. **F1 Chrome + F2 Body** occupy the mid tier — differentiated by case and family (mono vs sans)
3. **F3 Data + F5 Micro** are subordinate information — smallest, quietest

The mono/sans split does hierarchy work that weight alone cannot. You can read the chrome vs. the content before your brain processes weight or size. That's the System 7 principle: **the chrome IS the information.** The typeface choice communicates function before content.

---

*End of report. Version 1.0. Ready for design review and Code implementation.*
