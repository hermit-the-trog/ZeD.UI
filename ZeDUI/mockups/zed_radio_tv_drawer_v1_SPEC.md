# ZeD-UI — Radio + TV Contextual Drawer Spec v1

**Sister file:** `zed_radio_tv_drawer_v1.html` (Lua-flat render preview, dark ZeD theme)
**Session:** S114b (April 30, 2026 — design only, no code)
**Target window:** ZeD_WorldWindow (LootWindow)
**Status:** Visual design LOCKED. Ready for Lua component breakdown + organism wiring.

---

## What this drawer is

Contextual tab drawer in the World Window. Radio and TV are TWO separate vertical tabs in the right-edge tab strip. They appear when at least one matching item is in player range, and the count badge shows how many instances are reachable. The drawer renders ONE instance at a time; the drawer's internal header has `[◀] N/M [▶]` browse buttons to cycle through reachable instances.

Same pattern can extend to other contextual drawers later (washing machine, generator, oven, sink — anything PZ has brand-tier variants of).

---

## Visual tier system — TWO BRANDS, locked

### Premium Technologies (silver Pioneer/AKAI-style hi-fi)
- Chassis fill: `#b8b8b8` solid silver, edge-to-edge in the drawer (no outer System 7 grey wrapping the unit — chassis IS the drawer body).
- Control zones recessed into chassis as **dark grey panels** `#5a5a5a` with 1px highlight (`#3a3a3a` top-left, `#757575` bottom-right). Used for: top control strip (power + seek + volume), preset bank row, CD player section.
- Buttons: flat silver `#c8c8c8` with single 1px `#888888` border. Dark glyph color.
- Display: **VFD-style cyan** — dark blue background `#050a14`, cyan text `#66ddff` (bright) / `#4499bb` (dim). Mono-color display, no green or red in the data field. Status chip pattern: `●` filled = on, `○` outlined = off. Bright cyan = on, dim cyan `#1a3a4a` = off.
- CD player module: separate brand badge silkscreened on the dark grey panel (`PT-CD200 ★ 1-BIT BITSTREAM ★ 8X OVERSAMPLING ★ ANTI-SKIP`). CD display is **green VFD** `#44ee44` on dark `#050a14` (different phosphor color than the main FM display, same mono-color rule).
- Brand bar at bottom: silver pill with `PREMIUM TECHNOLOGIES` + model number `PT-TX950 ★ AM/FM TUNER + CD` in dim grey.
- TV chassis frame: same silver, with the CRT glass set into a dark `#0a0a0a` bezel.

### ValuTech (cheap black plastic)
- Chassis fill: `#1a1a1a` solid black plastic, edge-to-edge.
- Control zones recessed: slightly darker black `#0a0a0a` with subtle highlight (`#050505` shadow / `#3a3a3a` edge highlight).
- Buttons: black plastic `#2a2a2a` with `#050505` border. Light grey `#e0e0e0` text.
- Display: **backlit amber LCD** — amber background `#d4881f`, dark text `#1a0500`. INVERSE color scheme from Premium's VFD. Status chips: dark digits `#1a0500` for on, dim brown `#5a3010` for off (segments not energized). BATT/VOL bars dark filled active, dim amber empty `#c47015` inactive.
- No CD player module (cheap units don't have one).
- Brand bar at bottom: plain black plastic with `VALUTECH ★ AM/FM PORTABLE` in light grey/dim.

The two tiers are visually opposite by design — Premium is "lit display on dark, silver chassis"; ValuTech is "dark digits on backlit amber, black plastic chassis." Read at-a-glance as different price points without a single label saying "expensive" or "cheap."

---

## Window chrome (ACTUAL game chrome, not the hybrid I had earlier)

### Single compact title bar
```
[X] [▣] Ground 7 ──────────────────────── • RADIO
```
- Close box, 12px square title-icon, container title with item count, big spacer, active-tab pill on right (dot + tab name in caps).
- Active-tab dot is **ZeD orange** `#d97a1f`.
- Striped pattern: 1px alternating `#000` / `#2a2a2a` (dark theme).

### NO sub-header, NO action-strip rows under the title bar
The earlier hybrid double-header is **dead**. All breadcrumb/action stuff that was floating across the whole window is now scoped to its panel.

### Body row (3 columns)
```
| inv-panel  | drawer-column         | tab-strip |
|  444px     | 480px                 | 28px      |
```

#### Inventory panel (left)
- Sub-header: `[▣] Ground` left, `7 items` right
- Column headers: `Dist | Name | Cat | Cond | Wt` (Name underlined as active sort, ZeD orange in dark theme)
- Categorized list: `▼ ITEM (3)` style headers + item rows
- Item row: 14px icon | name | cat label (truncated) | green/yellow/red condition bar | weight
- Selected row: **full ZeD orange** `#d97a1f` fill with dark text + 2px brighter `#ff9933` left edge

#### Drawer column (middle) — has its OWN internal header
```
[◀] 1/3 [▶] | Premium Technologies Radio  ────────  Warehouse
```
- Browse prev/next buttons + N/M counter on left
- Drawer subtitle (current instance brand+model name) in middle, separated by thin vertical 1px divider
- Spacer pushes location-tag (`Warehouse`, `Kitchen`, `Garage` etc.) to the right
- Location tag is the **ZeD orange pill** in dark theme (was System 7 yellow in light)
- Drawer content (the chassis) sits below this header and fills remaining height

#### Tab strip (right) — vertical 28px column
- 24x24 tab icons stacked top-to-bottom, 2px gap, dividers between functional groups
- Active tab gets the **orange accent bar firing rightward** off its right edge (`::after`-style, 2px wide × full tab height)
- Tab count badges sit at top-right corner of tab icon — orange `#d97a1f` background, dark text

### Footer
**Just a resize handle.** `#2a2a2a` background, 12px height, diagonal grip pattern in bottom-right corner. NO data displays in the footer — the resize handle owns that real estate. Status data lives on the chassis VFD/LCD where it belongs.

---

## Component breakdown for Lua

### Atoms needed (or reused)
- `solidRect(color)` — 1px border + solid fill, the foundation atom
- `recessedPanel(bgColor, depth)` — bg + 4-side 1px border (top-left dark / bottom-right light) for inset look
- `raisedPanel(bgColor)` — same but inverted bevel (bottom-right dark / top-left light)
- `silkScreenLabel(text, font, color)` — drawText with explicit font + color, no background (for chassis text labels like "SEEK", "VOL", "Power")
- `segmentedBar(segments, lit, color, bgColor)` — N segments with K lit, used for BATT (4 segs) and VOL (8 segs)
- `flatButton(text, color, bgColor, borderColor)` — 1px-bordered button, no bevel
- `transportBtn(glyph, color)` — flat button for ▶ ❚❚ ■ ◀◀ ▶▶ ▲ ●
- `statusChip(text, on, onColor, offColor)` — text-only chip with on/off color states (used in VFD chip rows)

### Molecules needed
- `radioControlStrip(brand, power, hasSeek, hasVol)` — recessed dark grey panel containing power button + spacer + SEEK zone (label/-/btn/btn/+) + VOL zone (label/-/btn/btn/+)
- `radioPresetBank(slot, count=8, hasAdd, hasRemove)` — recessed panel with N preset buttons + add/remove action buttons
- `radioMainDisplay(brand, freq, channel, signal, range, twoway, batt, vol, presetSlot)` — the VFD/LCD with status chip row + BATT/VOL row + main zone (freq + channel + data column) + signal wave (Premium only)
- `radioSignalWave(seed, width, height)` — 64-column sine-wave readout with center reference line + corner labels (SIG, +, −). Generated at draw time with 3-sine harmonic + small noise. Renders unconditionally regardless of power state.
- `cdPlayerModule(brand, inserted, track, time, playing)` — recessed dark grey panel with CD-Player+model header + 7-button transport grid + green-VFD CD display
- `tvConsoleRow(brand, screen, sideControls)` — flex row with 1:1 CRT screen-frame + 110px side-controls column (Power/Volume/Channel sections with dividers, channel ▲▼ in **Scientific Atlanta orange**, numpad 0-9)
- `tvScreen(power, channel, channelName, volume, vcrMode, vcrTime, tapeTime, recordSpeed, hasVCR, tapeInserted)` — blue CRT bg `#0a1a4a` with on-screen overlay (CH big, time, mode/counter/speed line, program name, VOL bar — all in **white** to match TV data)
- `vcrTransportRow(mode)` — 7-button transport grid `◀◀ | ▶ play | ▲ eject | ❚❚ pause | ■ stop | ▶▶ | ●` (eject sits next to play, NOT after rewind)
- `brandBar(brand, model)` — chassis-bottom brand strip (silver pill for Premium, plain black for ValuTech)
- `drawerInternalHeader(browse, currentName, locationTag)` — 22px header strip with browse buttons + N/M + drawer subtitle + spacer + location tag
- `inventoryPanel(items, selectedIdx)` — full inventory column (sub-header + col headers + categorized list)
- `inventoryRow(item, selected)` — single item row with icon/name/cat/cond/wt
- `categoryRow(name, count, expanded)` — `▼ ITEM (3)` disclosure row

### Organisms
- `O_RadioDrawer(radioInstance)` — full radio drawer, branches to `O_RadioPremium` or `O_RadioValutech` based on brand
- `O_RadioPremium(r)` — assembles: control strip + preset bank + main display (with signal wave) + CD module + brand bar
- `O_RadioValutech(r)` — assembles: control strip + preset bank + main display (no signal wave) + brand bar (no CD)
- `O_TVDrawer(tvInstance)` — branches to `O_TVPremium` or `O_TVValutech`
- `O_TVPremium(t)` — assembles: console row (screen + side controls) + VCR transport row (if hasVCR) + brand bar
- `O_TVValutech(t)` — assembles: console row (screen + side controls) + brand bar (no VCR row)
- `O_WorldRadioTab(window)` — tab content host. Manages: instance browsing state, active radio reference, dispatch into O_RadioDrawer
- `O_WorldTVTab(window)` — same pattern for TVs

---

## Hard rules (locked)

1. **NO custom drawRect/drawText blocks.** All visuals via Atoms/Molecules. If something doesn't fit, propose a new atom or molecule first.
2. **Mono-color displays only.** Cyan family for Premium VFD. Amber family for ValuTech LCD. Green family for the CD module. NEVER multi-color in a single display.
3. **Plastic labels are STATIC, displays are DYNAMIC.** Chassis silkscreen labels (SEEK, VOL, Power, Volume, Channel, brand bars, CD module model) never change at runtime. Only display values change.
4. **Window chrome stays System 7 / dark ZeD.** The chassis is its own design language; the chrome is its own. Do not mix.
5. **NO data in the footer.** Footer is the resize handle. SIG/BAT/CH lives on the VFD/LCD where the chassis put it.
6. **Drawer fills the whole drawer column.** The chassis IS the drawer. No outer System 7 grey ring.
7. **TV/VCR combos: VCR data overlays the CRT screen.** No separate VCR LCD strip on the chassis. Real combos showed mode/counter/speed/clock as on-screen overlays.
8. **Signal wave is always rendered.** Power state doesn't gate the waveform — when off, the wave still draws (just empty cyan noise floor); the rest of the display dims. Layout stays stable.
9. **TV on-screen overlays use white** `#ffffff` (active) and 15% white `rgba(255,255,255,0.15)` (inactive segments). NOT cyan — the TV is a CRT, not a VFD.
10. **Scientific Atlanta orange** `#d97a1f` is intentional for TV channel ▲/▼ buttons on both brands — it's the era-correct cable-remote visual cue.

---

## Tokens needed in `Tokens.lua`

These should already mostly exist or have close equivalents — confirm at code time:

```lua
-- Premium chassis
T.pt.chassisBg        = 0xFFB8B8B8   -- silver
T.pt.recessedBg       = 0xFF5A5A5A   -- dark grey panel
T.pt.recessedHi       = 0xFF3A3A3A   -- dark panel top-left
T.pt.recessedShadow   = 0xFF757575   -- dark panel bottom-right
T.pt.btnBg            = 0xFFC8C8C8   -- silver flat button
T.pt.btnBorder        = 0xFF888888
T.pt.btnText          = 0xFF1A1A1A
T.pt.brandBarBg       = 0xFFD0D0D0   -- brand strip silver
T.pt.silkScreen       = 0xFFD8D8D8   -- light grey chassis labels

-- VFD (Premium)
T.vfd.bg              = 0xFF050A14   -- dark blue
T.vfd.bright          = 0xFF66DDFF   -- cyan bright
T.vfd.dim             = 0xFF4499BB   -- cyan dim
T.vfd.off             = 0xFF1A3A4A   -- cyan very dim (off state)

-- CD VFD (green phosphor — separate from main display)
T.cd.bg               = 0xFF050A14   -- same dark blue
T.cd.bright           = 0xFF44EE44   -- green
T.cd.dim              = 0xFF1A3A1A

-- ValuTech chassis
T.vt.chassisBg        = 0xFF1A1A1A   -- black plastic
T.vt.recessedBg       = 0xFF0A0A0A   -- darker black
T.vt.btnBg            = 0xFF2A2A2A   -- black plastic button
T.vt.btnBorder        = 0xFF050505
T.vt.btnText          = 0xFFE0E0E0
T.vt.silkScreen       = 0xFF888888

-- ValuTech LCD (backlit amber, dark digits)
T.lcd.bg              = 0xFFD4881F   -- amber backlit
T.lcd.fg              = 0xFF1A0500   -- dark digits
T.lcd.fgDim           = 0xFF2A1505   -- dark digits dim (for keys)
T.lcd.segOn           = 0xFF1A0500   -- segment lit
T.lcd.segOff          = 0xFFC47015   -- segment unlit (subtle on amber bg)
T.lcd.chipOff         = 0xFF5A3010   -- status chip off

-- TV CRT
T.crt.bg              = 0xFF0A1A4A   -- blue CRT background
T.crt.bgOff           = 0xFF050505   -- powered off
T.crt.fg              = 0xFFFFFFFF   -- on-screen overlay text
T.crt.fgDim           = 0x26FFFFFF   -- 15% white = inactive segments

-- Existing accents (already in Tokens)
T.accent              = 0xFFD97A1F   -- ZeD orange
T.accentBright        = 0xFFFF9933   -- selection edge
T.scientificAtlanta   = 0xFFD97A1F   -- TV channel up/down (same as accent intentional)
```

---

## Deferred / open

- **Tab icons:** the mockup uses `RA / TV / GR / AN / CR / BL / FO / FI` as text placeholders. Actual icons need to come from ZeDIecon library — pick from existing electronics/media glyphs. Code-bud should propose specific picks when wiring up the tab strip.
- **Browse instance scoping:** does "1/3" cycle through ALL radios in range, or just radios in the current "primary container"? Decision: ALL in range (matches how Animal tab handles multi-instance). Confirm at code time.
- **Power off display state:** when chassis is power=off, what dims and what stays? Locked rules from this session: signal wave keeps rendering (noise floor). Status chips dim. Frequency/channel name still readable but in dim color. BATT/VOL bars empty. Ref the mockup's power-toggle state as the source of truth.
- **CD player presence flag:** Premium has hasCD as a boolean. Does the world model give us this directly per-radio, or do we always assume yes for Premium and no for ValuTech? Probably brand-derived but confirm against PZ's actual radio item models.
- **Volume granularity:** mockup uses 0–8 (8 segments). PZ vanilla radio volume is also discrete. Confirm step count matches engine.

---

## Reference mockup pages used

Premium reference: Pioneer SX/CT-series (silver chassis, dark grey recessed panels, cyan VFD), Sony CDP-990 (CD module), Kenwood KDC car decks (volume/preset banks). ValuTech reference: any cheap budget shelf system with amber backlit LCD (Aiwa NSX series, Magnavox/Phillips low-tier). TV/VCR reference: GE 9-7100, Scientific Atlanta cable boxes (orange channel ▲/▼).
