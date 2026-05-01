# ZeD-UI Typography Decision — Pairing D
**Decided:** Session 74 (April 10, 2026)
**Status:** Code-ready. Implement in S75 alongside tab strip icons + avatar work.

---

## The Decision

**Fira Mono + Fira Sans Condensed.** Both SIL OFL. Both on Google Fonts.

Chosen for density and legibility performance. 9/10 legibility at 12px, best-in-class condensed
density (~43 chars/line at the Extra Condensed micro tier). System 7 aesthetic score is 2/10 — the
tradeoff is accepted. Chrome carries the System 7 character through layout, borders, and stripes.
The text works.

---

## Five-Role System

This pass also renames all font tokens from the old semantic names (fontTitle/fontHead/fontSec/
fontBody/fontStat) to the new functional F-system (fontF1 through fontF5). Token names change.
Font content changes. Two things happening at once.

| Role | Token (new) | Token (old) | Font | Size S/L | UIFont slot |
|---|---|---|---|---|---|
| F1 Chrome | `T.fontF1` | `T.fontSec` | Fira Mono Bold | 11 / 13px | NewMedium / NewSmall |
| F2 Body | `T.fontF2` | `T.fontBody` | Fira Sans Cond. Regular | 12 / 14px | Small / Large |
| F3 Data | `T.fontF3` | `T.fontStat` | Fira Mono Regular | 11 / 13px | Medium / CodeMedium |
| F4 Heading | `T.fontF4` | `T.fontHead` | Fira Sans Cond. SemiBold | 13 / 15px | NewLarge / CodeLarge |
| F5 Micro | `T.fontF5` | `T.fontTitle` | Fira Sans Cond. Regular | 9 / 11px | Code / CodeSmall |

**F5 slot note:** The old title/titleLg slots (UIFont.Code / UIFont.CodeSmall) carried Bahnschrift
Bold at 16/18px. Those same UIFont enum values are repurposed for F5 Micro at 9/11px. No changes
to fonts.txt — the .fnt files get regenerated with new content. The old display-weight title role
is absorbed into F4 Heading (Fira Sans Condensed SemiBold at 13/15px is the new top of the
hierarchy — this is intentional, we don't need a separate 16px display tier for this UI).

---

## Step 1 — Download and Install Fonts

**Fira Sans Condensed** — https://fonts.google.com/specimen/Fira+Sans+Condensed
Install (right-click -> Install for all users):
- FiraSans-CondensedRegular.ttf
- FiraSans-CondensedSemiBold.ttf

**Fira Mono** — https://fonts.google.com/specimen/Fira+Mono
Install:
- FiraMono-Regular.ttf
- FiraMono-Bold.ttf

Verify: open Word or Notepad, font picker, confirm "Fira Sans Condensed" and "Fira Mono" appear.

---

## Step 2 — Edit generate_fonts.py

### 2a. Replace font path variables

**Remove:**
```python
_BAHN = _find_font("bahnschrift.ttf")
_CHIC = _find_font("ChicagoFLF.ttf")
_LEKT = _find_font("Lekton-Bold.ttf")
_K22  = _find_font("K22 Xanthus.otf")
```

**Replace with:**
```python
_FIRA_SANS_SEMI  = _find_font("FiraSans-CondensedSemiBold.ttf")
_FIRA_SANS_REG   = _find_font("FiraSans-CondensedRegular.ttf")
_FIRA_MONO_BOLD  = _find_font("FiraMono-Bold.ttf")
_FIRA_MONO_REG   = _find_font("FiraMono-Regular.ttf")
# Reserved slots still use Chicago + Lekton until those roles are specced
_CHIC = _find_font("ChicagoFLF.ttf")
_LEKT = _find_font("Lekton-Bold.ttf")
```

### 2b. Replace FONT_SIZES dict

**Remove the entire FONT_SIZES dict and replace:**
```python
FONT_SIZES = {
    # 5 roles x 2 size presets = 10 active slots
    "sec":      11,   # F1 Chrome — Fira Mono Bold @ small
    "secLg":    13,   # F1 Chrome — Fira Mono Bold @ large
    "body":     12,   # F2 Body — Fira Sans Condensed Regular @ small
    "bodyLg":   14,   # F2 Body — Fira Sans Condensed Regular @ large
    "stat":     11,   # F3 Data — Fira Mono Regular @ small
    "statLg":   13,   # F3 Data — Fira Mono Regular @ large
    "head":     13,   # F4 Heading — Fira Sans Condensed SemiBold @ small
    "headLg":   15,   # F4 Heading — Fira Sans Condensed SemiBold @ large
    "title":     9,   # F5 Micro — Fira Sans Condensed Regular @ small (repurposed slot)
    "titleLg":  11,   # F5 Micro — Fira Sans Condensed Regular @ large (repurposed slot)
    # 4 reserved (placeholders — unchanged)
    "rsv1":     20,
    "rsv2":     24,
    "rsv3":     16,
    "rsv4":     20,
}
```

### 2c. Replace FONTS dict

**Remove the entire FONTS dict and replace:**
```python
FONTS = {
    # F1 Chrome — Fira Mono Bold (title bars, tabs, button labels)
    "sec":     (_FIRA_MONO_BOLD, "Fira Mono", 1, 0, None),
    "secLg":   (_FIRA_MONO_BOLD, "Fira Mono", 1, 0, None),
    # F2 Body — Fira Sans Condensed Regular (list rows, content text)
    "body":    (_FIRA_SANS_REG,  "Fira Sans Condensed", 0, 0, None),
    "bodyLg":  (_FIRA_SANS_REG,  "Fira Sans Condensed", 0, 0, None),
    # F3 Data — Fira Mono Regular (numbers, percentages, stat values)
    "stat":    (_FIRA_MONO_REG,  "Fira Mono", 0, 0, None),
    "statLg":  (_FIRA_MONO_REG,  "Fira Mono", 0, 0, None),
    # F4 Heading — Fira Sans Condensed SemiBold (section headers, item names)
    "head":    (_FIRA_SANS_SEMI, "Fira Sans Condensed", 0, 0, None),
    "headLg":  (_FIRA_SANS_SEMI, "Fira Sans Condensed", 0, 0, None),
    # F5 Micro — Fira Sans Condensed Regular (chips, badges, metadata labels)
    # Repurposed from old title/display slot. UIFont.Code / CodeSmall.
    "title":   (_FIRA_SANS_REG,  "Fira Sans Condensed", 0, 0, None),
    "titleLg": (_FIRA_SANS_REG,  "Fira Sans Condensed", 0, 0, None),
    # Reserved (unchanged)
    "rsv1":    (_CHIC, "Chicago", 0, 0, None),
    "rsv2":    (_CHIC, "Chicago", 0, 0, None),
    "rsv3":    (_LEKT, "Lekton",  1, 0, None),
    "rsv4":    (_LEKT, "Lekton",  1, 0, None),
}
```

### 2d. Replace TRACKING dict

**Remove:**
```python
TRACKING = {
    "title": 2, "titleLg": 2,
    "body": 2,  "bodyLg": 2,
    "sec": 2,   "secLg": 2,
    "stat": 3,  "statLg": 3,
}
```

**Replace with:**
```python
TRACKING = {
    # Fira Mono: small tracking on chrome labels for uppercase readability.
    # All Fira Sans Condensed slots: 0 (tight natural spacing, no extra needed).
    # F5 Micro: small tracking at 9px for chip/badge legibility.
    "sec":   1, "secLg":   1,   # F1 Chrome
    "title": 1, "titleLg": 1,   # F5 Micro
}
```

### 2e. Replace UPPERCASE_ONLY set

**Remove:**
```python
UPPERCASE_ONLY = {"stat", "statLg", "rsv3"}
```

**Replace with:**
```python
# K22 Xanthus was all-caps by design. Fira Mono has real lowercase — no override.
# rsv3 (Lekton) stays uppercase-only since it is still Lekton.
UPPERCASE_ONLY = {"rsv3"}
```

### 2f. Replace YOFF_ADJUST dict

**Remove:**
```python
YOFF_ADJUST = {
    "stat": 1, "statLg": 1,
}
```

**Replace with:**
```python
# K22 Xanthus baseline quirk gone. Start at 0 for all Fira fonts.
# Add adjustments here after first regen if visual baseline mismatch found.
YOFF_ADJUST = {}
```

### 2g. Update the docstring

Replace the role/font/slot table in the module docstring to reflect the new assignments.

---

## Step 3 — Run the Generator

```bash
cd C:\Users\danie\Zomboid\mods\ZeD-UI\42\media\fonts
python generate_fonts.py
```

Expected: 56 files (14 slots x 4 scales). Any `ERROR: TTF not found` means the filename from
the Google Fonts zip doesn't match exactly — check the actual filename and update _find_font().

---

## Step 4 — Edit Tokens.lua

Two changes: (a) rename the internal ZeD.TextSizes keys, (b) rename the T. assignments.

### 4a. In ZeD.TextSizes (the size preset tables — search for "fontTitle")

**Find all occurrences of these keys and rename:**
```
fontTitle  ->  fontF5
fontHead   ->  fontF4
fontSec    ->  fontF1
fontBody   ->  fontF2
fontStat   ->  fontF3
```

This applies inside both the "small" and "large" preset tables.

### 4b. In applyTheme() — the T. assignments block

**Find and replace this block:**
```lua
T.fontTitle  = size.fontTitle.font
T.fontHead   = size.fontHead.font
T.fontSec    = size.fontSec.font
T.fontBody   = size.fontBody.font
T.fontStat   = size.fontStat.font
if getTextManager then
    local tm = getTextManager()
    T.fontTitleH = tm:getFontHeight(T.fontTitle)
    T.fontHeadH  = tm:getFontHeight(T.fontHead)
    T.fontSecH   = tm:getFontHeight(T.fontSec)
    T.fontBodyH  = tm:getFontHeight(T.fontBody)
    T.fontStatH  = tm:getFontHeight(T.fontStat)
end
```

**Replace with:**
```lua
T.fontF1  = size.fontF1.font
T.fontF2  = size.fontF2.font
T.fontF3  = size.fontF3.font
T.fontF4  = size.fontF4.font
T.fontF5  = size.fontF5.font
if getTextManager then
    local tm = getTextManager()
    T.fontF1H = tm:getFontHeight(T.fontF1)
    T.fontF2H = tm:getFontHeight(T.fontF2)
    T.fontF3H = tm:getFontHeight(T.fontF3)
    T.fontF4H = tm:getFontHeight(T.fontF4)
    T.fontF5H = tm:getFontHeight(T.fontF5)
end
```

---

## Step 5 — Project-Wide Find-and-Replace

After Tokens.lua is updated, all component files need their token references updated.
Run these as global find-and-replace across the entire client/ZeD/ directory.

**Font object references (in drawText calls etc.):**
```
T.fontTitle  ->  T.fontF5
T.fontHead   ->  T.fontF4
T.fontSec    ->  T.fontF1
T.fontBody   ->  T.fontF2
T.fontStat   ->  T.fontF3
```

**Height cache references:**
```
T.fontTitleH  ->  T.fontF5H
T.fontHeadH   ->  T.fontF4H
T.fontSecH    ->  T.fontF1H
T.fontBodyH   ->  T.fontF2H
T.fontStatH   ->  T.fontF3H
```

**Files confirmed to contain these references (from session history):**
ZeD_CharacterWindow.lua, ZeD_WorldWindow.lua, ItemCard.lua, InventoryRenderer.lua,
EquipmentTab.lua, HealthTab.lua, SkillsTab.lua, ProtectionTab.lua, ThermalTab.lua,
JournalTab.lua, IdentityTab.lua, CraftingTab.lua, BuildingTab.lua, ForagingTab.lua,
MapsTab.lua, Atoms.lua, AtomExtensions.lua, Molecules.lua, Organisms.lua, Settings.lua

Run find-and-replace, then do a grep for any remaining "fontTitle\|fontHead\|fontSec\|fontBody\|fontStat"
to catch stragglers before launching.

---

## Step 6 — In-Game Verification Checklist

- [ ] Title bar text (T.fontF1 = Fira Mono Bold 11px) — monospaced, chrome-like, uppercase tabs
- [ ] Button labels (T.fontF1) — EQUIP / DROP / INSPECT in item card action strip
- [ ] List rows (T.fontF2 = Fira Sans Condensed Regular 12px) — equipment, inventory, recipe lists
- [ ] Stat values (T.fontF3 = Fira Mono Regular 11px) — percentages, weights, XP values align in columns
- [ ] Section headers (T.fontF4 = Fira Sans Condensed SemiBold 13px) — "Torso", "Legs", "Worn Items"
- [ ] Item card name (T.fontF4) — "Leather Jacket" in amber at heading weight
- [ ] Chip/badge text (T.fontF5 = Fira Sans Condensed Regular 9px) — "LEATHER", "OUTER", condition chips
- [ ] Micro stat labels (T.fontF5) — "CONDITION", "WEIGHT" beside values in item card
- [ ] Skills tab XP grid — heading vs. body hierarchy clear
- [ ] All three themes (Dark / Light / High Contrast) — no bleed or contrast failures

**Known adjustment likely needed:** Baseline alignment between Fira Mono and Fira Sans Condensed
on the same row (e.g. stat label F5 + stat value F3 side by side). If Fira Mono sits visually
high or low, adjust YOFF_ADJUST["stat"] / ["statLg"] by +/-1 and regen.

---

## CSS Tokens for Mockups

Drop into any new mockup HTML. This is the authoritative mockup stack going forward.

```css
@import url('https://fonts.googleapis.com/css2?family=Fira+Mono:wght@400;700&family=Fira+Sans+Condensed:ital,wght@0,400;0,500;0,600;0,700;1,400&display=swap');

:root {
    --font-mono: 'Fira Mono', 'Consolas', monospace;
    --font-sans: 'Fira Sans Condensed', 'Arial Narrow', sans-serif;

    /* F1 Chrome */
    --f1-family:   var(--font-mono);
    --f1-weight:   700;
    --f1-size:     11px;
    --f1-lh:       14px;
    --f1-tracking: 0.5px;
    --f1-case:     uppercase;

    /* F2 Body */
    --f2-family:   var(--font-sans);
    --f2-weight:   400;
    --f2-size:     12px;
    --f2-lh:       16px;
    --f2-tracking: 0px;
    --f2-case:     none;

    /* F3 Data */
    --f3-family:   var(--font-mono);
    --f3-weight:   400;
    --f3-size:     10px;
    --f3-lh:       14px;
    --f3-tracking: 0px;
    --f3-case:     none;

    /* F4 Heading */
    --f4-family:   var(--font-sans);
    --f4-weight:   600;
    --f4-size:     13px;
    --f4-lh:       16px;
    --f4-tracking: 0px;
    --f4-case:     none;

    /* F5 Micro */
    --f5-family:   var(--font-sans);
    --f5-weight:   400;
    --f5-size:     9px;
    --f5-lh:       12px;
    --f5-tracking: 0.8px;
    --f5-case:     uppercase;
}

.f1 { font-family: var(--f1-family); font-weight: var(--f1-weight); font-size: var(--f1-size); line-height: var(--f1-lh); letter-spacing: var(--f1-tracking); text-transform: var(--f1-case); }
.f2 { font-family: var(--f2-family); font-weight: var(--f2-weight); font-size: var(--f2-size); line-height: var(--f2-lh); letter-spacing: var(--f2-tracking); }
.f3 { font-family: var(--f3-family); font-weight: var(--f3-weight); font-size: var(--f3-size); line-height: var(--f3-lh); letter-spacing: var(--f3-tracking); font-variant-numeric: tabular-nums; }
.f4 { font-family: var(--f4-family); font-weight: var(--f4-weight); font-size: var(--f4-size); line-height: var(--f4-lh); letter-spacing: var(--f4-tracking); }
.f5 { font-family: var(--f5-family); font-weight: var(--f5-weight); font-size: var(--f5-size); line-height: var(--f5-lh); letter-spacing: var(--f5-tracking); text-transform: var(--f5-case); }
```

---

## UIFont Slot Reference (read-only — do not change)

fonts.txt does not change. The UIFont enum values are fixed by the PZ engine.
This table is for reference only so Code knows which enum value each role uses.

| Role | Token | UIFont (small preset) | UIFont (large preset) | .fnt file |
|---|---|---|---|---|
| F1 Chrome | T.fontF1 | UIFont.NewMedium | UIFont.NewSmall | sec.fnt / secLg.fnt |
| F2 Body | T.fontF2 | UIFont.Small | UIFont.Large | body.fnt / bodyLg.fnt |
| F3 Data | T.fontF3 | UIFont.Medium | UIFont.CodeMedium | stat.fnt / statLg.fnt |
| F4 Heading | T.fontF4 | UIFont.NewLarge | UIFont.CodeLarge | head.fnt / headLg.fnt |
| F5 Micro | T.fontF5 | UIFont.Code | UIFont.CodeSmall | title.fnt / titleLg.fnt |

---

## What Does NOT Change

- fonts.txt — no edits needed (UIFont slot names and .fnt filenames stay the same)
- Reserved slots rsv1-rsv4 — left on Chicago/Lekton until those roles are specced
- Font sizes for F1-F4 — all current px values preserved
- The pattern of two size presets (small/large) — unchanged

---

## Execution Order for S75

1. Download + install Fira fonts
2. Edit generate_fonts.py (Steps 2a-2g)
3. Run generator, confirm 56 files output, no errors
4. Edit Tokens.lua (Step 4a-4b)
5. Global find-and-replace across client/ZeD/ (Step 5)
6. Grep for straggler references — must return zero hits
7. Launch PZ, verify checklist (Step 6)
8. Tune YOFF_ADJUST if baseline misalignment found, regen if needed

---

*Decision locked. Two deliverables: generate_fonts.py edits + Tokens.lua rename + project-wide
find-and-replace. No architectural changes. No new files.*
