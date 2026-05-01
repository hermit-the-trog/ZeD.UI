# CONTEXT_MENU_SPEC

**Status:** IMPLEMENTED (Session 88, April 14, 2026) — see deviations note below
**Locked:** Session 87, April 13, 2026
**Mockup:** `ZeDUI/mockups/zed_context_unified_v1.html`
**Supersedes:** `ZeDUI/mockups/zed_gamepad_context_linear_v1.html` (gamepad-only intermediate; kept as iteration archive)
**Implements:** Vanilla `ISContextManager` replacement for both mouse RMB and gamepad bound-button paths.

---

## S88 Implementation Deviations from Locked Design

The following deliberate departures were made during S88 CODE based on play-test feedback. The locked design above describes the AS-PLANNED state; this section describes the AS-SHIPPED state.

1. **Target card removed entirely.** Right-clicking already shows the player what they clicked on (cursor sits on/just below the click target). A separate "subject" card was redundant and pushed the strip away from the click point. Affects ACs 20–22 — the assembly stack now has no card layer.
2. **Floating label and balloon merged into one info bubble.** Instead of an absolute-positioned label tracking selected cell X above the strip and a separate static-centered balloon below the (now-removed) target card, S88 ships ONE bubble above the strip with a downward pointer at the strip's center. Affects ACs 13, 23 — label X tracking dropped; bubble centers stably on strip.
3. **Adaptive vertical flip.** When the cursor is too close to the top of the screen for the bubble to fit above, the assembly flips: strip below cursor, bubble below strip with upward-pointing tail. Not in original spec.
4. **Active cell uses theme accent color** (not full ink inversion). Affects AC 11 (cell states section §3) — active fill is `T.accent` instead of pure ink. Indicators (corner triangle, pin square) and back glyph still flip to paper to stay visible against the accent.
5. **Balloon chrome locked to System-7 light** (white bg + black ink + black text) regardless of active theme. Strip cells/bumpers/chevrons remain theme-driven for now.
6. **Bumpers and chevrons gated together on `truncating` (N>10).** Spec §3 had bumpers always visible; S88 hides both edges of chrome when the menu is short enough that group-jump and scroll affordances aren't useful. Bare strip for the common case.
7. **Vanilla "More" overflow submenus auto-flatten.** ZeD's strip handles overflow via truncation/carousel — vanilla's drill-down "More" bucket added unnecessary navigation. Children of any node named "More" are spliced into the parent list at the More entry's position.
8. **RMB always dismisses; LMB on dead-space dismisses.** Inside-panel right-clicks close the menu (two-click pattern for re-RMBing elsewhere). Inside-panel left-clicks that miss all action targets also dismiss.
9. **Hook point.** Implementation uses `ISContextMenu:prerender` override (not `addToUIManager` as the plan assumed) — vanilla's per-player cached singleton means `addToUIManager` only fires once at startup. See PZAPI-KB Q73-Q78 for the full set of engine quirks discovered.

---

## 1. PURPOSE

Replace vanilla Project Zomboid context menus (`ISContextMenu` + `ISContextManager` dropdown rendering) with a single ZeD-native horizontal icon strip that serves both mouse and gamepad input without mode switches. Preserves all vanilla actions collected via `OnFillWorldObjectContextMenu` / `OnFillInventoryObjectContextMenu` events — we wrap the collection, we do not replace the data model.

---

## 2. LOCKED DESIGN DECISIONS

1. **One design, two inputs.** Identical chrome, identical state machine, identical layout. Input adapters feed the same selector.
2. **Horizontal linear icon strip.** Not radial. Not squaradial. Not grid.
3. **Compact cells: 22×22px with 16×16px icons, 1px gap.** Combat survivability priority — menu must not block situational awareness.
4. **Icon-only cells.** No text inside the cell. The icon IS the tile.
5. **Drill-down swaps strip contents in place.** Max 2 levels deep. Breadcrumb renders in the floating label.
6. **Back cell at position 0 of any submenu.** Accent-tinted ◂ glyph. Clickable (mouse) or cancel-button-reachable (gamepad/keyboard).
7. **Floating label above the selected cell** — shows name at top level, breadcrumb (`Parent › Child`) in submenus. Tracks selected cell horizontally.
8. **Target card sits BETWEEN strip and balloon.** Icon + item name + meta field. Static-centered in the assembly — the anchor that holds the whole stack together visually.
9. **Balloon Help below the target card** — category header, body description, state-aware reason. Static-centered (does NOT track selection horizontally — only its contents update). Triangle pointer on top points up at the target card.
10. **Reading order is action → subject → consequence.** Label (verb) · strip (verb icons) · target card (subject) · balloon (consequence). Top-down like a sentence. The strip literally points at the item it's operating on.
11. **Group-jump bumpers flank the strip.** Click (mouse) or press mapped button (gamepad) to skip to the next/previous category group.
12. **Button-hint rendering system is DEFERRED.** Bumpers currently show `«` / `»` placeholders.
13. **Top border of strip thickens from 1px to 2px when drilled into a submenu** — subtle visual cue for depth.
14. **Balloon category header tints accent red when in a submenu.**
15. **Linear loop (cycling selection).** Selection wraps past both ends. Same behavior whether truncating or not.
16. **Responsive width with 10-cell ceiling.** Strip renders only as wide as visible cells need: `innerW = N × 22 + (N−1) × 1`; housing = `innerW + 2`. Capped at N = 10 (housing = 231px). When N > 10, truncation chevrons appear flanking the strip; selection stays centered in the visible window. When N ≤ 10, chevrons hide entirely and the whole row compacts. Width transitions at 180ms `cubic-bezier(0.45, 0, 0.25, 1)`.
17. **Visual loop (infinite carousel) when truncating.** The track renders three copies of the items list concatenated: `[...items, ...items, ...items]`. Selection lives in the middle copy. Scrolling past the end shows the first copy's cells sliding in from the right; scrolling past the start shows the last copy's cells sliding in from the left — user sees the end to the left of the start and vice versa, no jump cut. After each animation settles (~200ms), the track silently teleports back to the middle copy with transitions disabled for one frame.

---

## 3. ANATOMY

### Assembly stack (top to bottom)

```
              [  Eat  ]          ← floating label (tracks selected cell X)
                 ▼
      « ◂ [🍴][🔓][✂][⚒][✋][🤚][➡▸][ℹ][↡][✕] ▸ »   ← strip row
                 │
         ┌───────┴──────────┐
         │ 🥫 Beans Canned  │    ← target card (static, centered)
         │    ×2 · Fresh    │
         └──────────────────┘
                 ▲
         ┌───────┴──────────┐
         │  USE    1 / 10   │    ← balloon (static centered, content updates)
         │ Eat this item... │
         │ ✓ 180 cal, Fresh │
         └──────────────────┘
```

Vertical rhythm at base text size: strip center → 28px up to label center · strip bottom → 10px down to target card top · target card bottom → 10px down to balloon top. Assembly total height ≈ 120px at max (with balloon body).

### Floating label (top of assembly)
- Position: **absolute**, centered on the selected cell's screen X. `top = stripTop − 28px`.
- Chrome: System 7 paper pill, 1px ink border, 2px stepped shadow, downward triangle pointer (outlined).
- Top level: action name (F2 Bold ~13px).
- Submenu: breadcrumb `Parent › Child` — parent muted, separator muted, current in full ink.
- Transitions at 180ms cubic-bezier.
- **Positioning:** in truncating mode selected is always centered in housing, so label centers on strip center. In non-truncating mode, label tracks the selected cell's actual screen position.

### Strip row (middle of assembly, natural flow)
| Element | Width | Visibility | Notes |
|---|---|---|---|
| Left bumper | 28px min | Always | Paper block, System 7 chrome, clickable. Shows `«` placeholder. |
| Left chevron | 12px | **Only when truncating** (N > 10) | Black fill, paper glyph `◂`. |
| Strip housing | **Responsive:** `min(N, 10) × 22 + (min(N, 10) − 1) × 1 + 2` | Always | `overflow: hidden`. Width animates on content change. |
| Right chevron | 12px | **Only when truncating** | Mirror of left with `▸`. |
| Right bumper | 28px min | Always | Mirror of left with `»`. |

**Total assembly WIDTH (varies with visible cell count):**
| Visible cells | Strip housing | Total with bumpers | Chevrons |
|---|---|---|---|
| 1 | 24px | 86px | hidden |
| 4 | 93px | 155px | hidden |
| 8 | 183px | 245px | hidden |
| 10 | 231px | 293px | hidden |
| 11+ (capped, visual loop) | 231px | 323px | **visible** |

### Strip track (inside housing)
- `background: var(--ink)` — gap between cells renders as 1px black gridline.
- `transform: translateX()` animated at 180ms cubic-bezier.
- **Contents:**
  - **Non-truncating (N ≤ 10):** single copy of items, translateX = 0, all cells visible.
  - **Truncating (N > 10):** three copies of items concatenated — `[...items, ...items, ...items]`. Position anchor `pos` (see §4) indexes into the tripled track. Selection always renders centered in the visible 10-cell window via `translateX(visibleW / 2 − (pos × 23 + 11))`.
- **Settle rule:** after each navigation in truncating mode, a `settlePosAfterAnim` timer fires ~20ms after animation end (200ms total). If `pos` is outside the middle copy's range, track snaps silently (transition disabled for one frame) via `pos += ±N`. Selection value stays the same — only the visual index shifts.

### Cell (.lcell) — 22×22 states
| State | Visual |
|---|---|
| Default | Paper bg, ink glyph |
| Active | Full inversion (ink bg, paper glyph) — **only the cell at `pos` (truncating) or `selectedIdx` (non-truncating) is active, even though multiple copies of each item exist in truncating mode** |
| Disabled | Diagonal 45° stipple, dim glyph |
| Disabled + Active | Inverted with 0.7 alpha |
| Has submenu | 3×3 ink triangle bottom-right (inverts to paper on active) |
| Back cell | Glyph in accent color; background standard |
| Pinned | 3×3 accent square top-right (inverts to paper on active) |

### Target card (below strip, natural flow, static centered)
- Position: natural flow, `margin-top: 10px` from strip row.
- Chrome: System 7 — 1px ink border, 2px stepped shadow, paper fill.
- Contents (left to right):
  - 18×18 icon tile (1px border, neutral bg)
  - Name (F2 SemiBold, 11px)
  - Meta field (F5 muted, 9px mono, separated by 1px left border) — count, freshness, weight, or any short item attribute
- **Does not move.** Every navigation change keeps the target card in the same place. It's the fixed anchor of the assembly.

### Balloon (bottom of assembly, natural flow, static centered)
- Position: natural flow, `margin-top: 10px` from target card.
- 230px fixed width. 1px ink border, 2px stepped shadow, paper fill.
- **Upward-pointing triangle on top** (outlined) — points up at the target card directly above it. Signals "this explains what will happen to that item."
- **Does not track selection horizontally.** Only its CONTENT updates as selection changes.
- Header row (mono 9px uppercase): category name left, `N / Total` count right.
- Body (Fira Sans Condensed 11.5px): description of the selected action.
- State row (mono 9.5px muted, dashed top divider): prefixed with `✓` green or `✕` red; explains availability reason.
- In-submenu: category header tints accent red.

---

## 4. STATE MACHINE

### Core state
```lua
win._ctx = {
  open       = false,
  anchor     = { x, y },     -- screen position of assembly's top-left (label top)
  anchorMode = "cursor",     -- "cursor" (mouse) | "dock" (gamepad)
  target     = itemOrObject, -- rendered in target card
  path       = {},           -- array of parent indices; empty = top level
  selected   = 1,            -- Lua-1-based index into currentItems()
  pos        = 1,            -- Lua-1-based index into tripled track (truncating only)
  actions    = { ... },      -- full ActionDef tree
}
```

### Visible items
- Top level: `win._ctx.actions`
- Submenu: `{ backCell, ...parent.children }` (`backCell` is synthetic)

### Selection transitions (all LOOP with wraparound)
- `next()` — `selected = (selected % N) + 1`. If truncating, also `pos = pos + 1`, schedule settle.
- `prev()` — `selected = ((selected - 2 + N) % N) + 1`. If truncating, also `pos = pos - 1`, schedule settle.
- `nextGroup()` — skip to first item of next category; wraps. If truncating, `pos += step` (positive delta).
- `prevGroup()` — skip to first item of previous category; wraps. If truncating, `pos` moves by signed negative delta (short-way-around).
- `confirm()`:
  - Back cell → pop path, selected reverts to `exitingParentIdx + 1` (Lua 1-based offset for back cell)
  - Disabled → no-op
  - Has children → push path, selected = 2 (skip back cell), reset pos to middle copy
  - Leaf → invoke `onFire(target)`, close menu
- `cancel()` — if path empty, close; else pop, reset pos.

### Settle rule (truncating mode only)
After any navigation action, schedule timer at `animMs + 20`:
1. Check if `pos < N + 1` or `pos > 2N`. If either, carousel wrapped into a clone.
2. Disable track CSS transition for one frame.
3. `pos = ((pos - 1) mod N) + N + 1` (normalize into middle copy).
4. Re-apply track translateX. Selection unchanged — only visual index shifts.
5. Force reflow, re-enable transition.

### Layout recalc (every frame or on state change)
1. `visibleCount = min(N, 10)`
2. `truncating = N > 10`
3. `stripInnerW = visibleCount × 22 + (visibleCount − 1) × 1`
4. Chevron visibility = `truncating`
5. Track contents: 1 copy if `!truncating`, 3 copies if `truncating`
6. Track translation: `translateX(0)` if `!truncating`, else `translateX(stripInnerW/2 − ((pos − 1) × 23 + 11))`
7. Label X: selected cell's screen-center X (strip center in truncating mode)
8. **Target card and balloon: no X calculation needed — CSS flex-center handles them**

---

## 5. INPUT MODEL

| Input | Action |
|---|---|
| RMB on world object or inventory item | Open menu anchored at cursor |
| Gamepad bound button (TBD binding) | Open menu anchored at docked position |
| Mouse hover on cell | Select that cell (no activate). In truncating mode also updates `pos` to hovered DOM index. |
| Mouse left-click on cell | Select + activate |
| Mouse left-click on bumper | `prevGroup` / `nextGroup` |
| Mouse click outside menu | Cancel (close) |
| Gamepad left stick / D-pad left or right | `prev` / `next` |
| Gamepad LB / RB (bound) | `prevGroup` / `nextGroup` |
| Gamepad confirm (A / Cross) | `confirm` |
| Gamepad cancel (B / Circle) | `cancel` |
| Keyboard ← / → | `prev` / `next` |
| Keyboard Tab / Shift+Tab | `nextGroup` / `prevGroup` |
| Keyboard Enter | `confirm` |
| Keyboard Esc / Backspace | `cancel` |

All directional inputs loop with wraparound. Truncating wraps show the visual carousel (end to left of start, start to right of end).

---

## 6. ACTION REGISTRY ARCHITECTURE

### ActionDef schema
```lua
{
  id         = "eat",
  name       = "Eat",
  icon       = textureOrGlyphKey,    -- 16×16
  category   = "USE",
  body       = "Eat this item...",
  state      = function(target) ... end,
  stateKind  = function(target) ... end,
  disabled   = function(target) ... end,
  pinned     = false,
  children   = { ... },
  onFire     = function(target) ... end,
}
```

`state` / `stateKind` / `disabled` are resolved every frame while the menu is open.

### Population flow
1. Vanilla event fires.
2. Vanilla mods populate vanilla `ISContextMenu`.
3. Intercept — read `ISContextMenu.options`.
4. Translate each option to ActionDef.
5. Categorize via keyword lookup.
6. Sort by category order, preserve in-category order.
7. Hoist pinned actions.
8. Hand tree to `ZeD_ContextMenu`.

### Category order (tentative)
`USE → ACTION → CRAFT → EQUIP → TRANSFER → INFO → ADMIN`

---

## 7. INTEGRATION POINTS

- **World RMB:** Hook `ISContextManager.createWorldMenu` (Build 42.16+ convergence point).
- **Inventory RMB:** Override `ISInventoryPane.onRightMouseUp`.
- **Gamepad bound button:** `JoyPadSetup` new binding.
- **Vanilla events:** do NOT block `OnFillWorldObjectContextMenu` / `OnFillInventoryObjectContextMenu`.

### Files to create
- `42/media/lua/client/ZeD/ZeD_ContextMenu.lua` — Organism.
- `42/media/lua/client/ZeD/ContextMenuRegistry.lua` — Module.

### Files to edit
- `42/media/lua/client/ZeD/Overrides/ContextMenu.lua` — existing stub; becomes hook setup.
- `42/media/lua/client/ZeD/Molecules.lua` — new molecules.
- `42/media/lua/client/ZeD/AtomExtensions.lua` — new atoms.
- `42/media/lua/shared/ZeD/Tokens.lua` — `T.ctx` group.

---

## 8. NEW COMPONENTS

### Atoms
- `A.drawBumper(x, y, w, h, label, isPressed)`
- `A.drawTruncChevron(x, y, direction)` — conditional, only when truncating
- `A.drawSubmenuIndicator(x, y, inverted)`
- `A.drawBackGlyph(x, y, w, h, isActive)`

### Molecules
- `M.drawContextCell(x, y, def, isActive, win)`
- `M.drawContextStrip(x, y, items, pos, path, win)` — renders 1 or 3 copies. Computes translateX from `pos`. Handles drilled border-top.
- `M.drawContextBumpers(x, y, truncating, win)`
- `M.drawContextFloatingLabel(x, y, items, selected, path)` — tracks X on selected cell
- `M.drawContextTargetCard(x, y, target, win)` — static centered; no per-frame selection dependency
- `M.drawContextBalloon(x, y, items, selected, parent)` — static centered; triangle on top points up at target card

### Organism
- `ZeD_ContextMenu.lua` — owns render + input routing + open/close lifecycle + settle-timer management. Parents to UIManager top layer. Lays out children in stack: label (absolute, X from selected) · strip row (flow) · target card (flow, centered) · balloon (flow, centered).

### Module
- `ZeD.ContextMenu.Registry` — `buildActionsFromVanilla`, `categorize`, `applyPins`, `getPinnedIds`, `togglePin`.

---

## 9. NEW TOKENS

```lua
T.ctx = {
  cellW = 22, cellH = 22,
  iconPx = 16,
  gap = 1,
  maxVisible = 10,
  bumperMinW = 28,
  chevW = 12,
  gutter = 3,                  -- gap between bumper/chev/strip/chev/bumper
  balloonW = 230,
  pinDotSz = 3,
  submenuTriSz = 3,
  labelMarginV = 28,           -- strip top to label center (label above strip)
  targetCardMarginV = 10,      -- strip bottom to target card top
  balloonMarginV = 10,         -- target card bottom to balloon top
  targetIconPx = 18,           -- target card icon tile
  animMs = 180,
  settleDelayMs = 200,
  drilledBorderTop = 2,
}
```

Reuse existing: `T.fontF1`, `T.fontF2`, `T.fontF4`, `T.fontF5`, `T.accent`, `T.accentDim`, `T.toneHi`, `T.toneLo`, `T.surf1`, `T.ink`.

---

## 10. OPEN QUESTIONS (for Code session)

1. **Button-hint rendering system.** Deferred.
2. **Final category keyword map.** Enumeration pass during implementation.
3. **Docked anchor position for gamepad.** Likely bottom-center; verify against moodle bar / combat UI.
4. **Pinned action persistence.** Match existing pin infrastructure.
5. **Gamepad button binding.** Check `JoyPadSetup` for collision.
6. **Back cell glyph color.** Accent for now; may revisit.
7. **Triple-render performance in Lua.** Trivial at 60fps / 30 cells max; profile during implementation.
8. **Target card meta field.** What goes in the meta slot for different item types? Canned food → "×2 · Fresh". Weapon → "condition: 90% · reload: 6/10". Clothing → "wetness: 20% · protection: 3". TBD per target type; implement a registry of meta formatters.

---

## 11. ACCEPTANCE CRITERIA

1. Right-click any world object → ZeD strip appears at cursor, vanilla `ISContextMenu` does not render.
2. Right-click any inventory item → same strip at cursor.
3. Gamepad bound button → strip appears docked.
4. All vanilla options from `OnFillWorld/InventoryObjectContextMenu` events appear as cells.
5. Mouse hover selects; left-click activates; click outside closes.
6. Gamepad stick/dpad selects; confirm activates; cancel closes or pops submenu.
7. Group-jump wraps through categories.
8. Arrow / stick selection loops past both ends.
9. **Visual loop works when truncating:** scrolling past last cell shows first cells sliding in from right; scrolling past first shows last cells sliding in from left. No jump cut.
10. **After each wrap, track silently settles back to the middle copy** — no visual artifact.
11. Disabled options render stippled with reason in state row.
12. Submenu parents render with corner ▾; confirm drills in place; cancel pops back.
13. Floating label updates with breadcrumb in submenu.
14. Balloon category header tints accent red in submenu.
15. Strip top border thickens when drilled in.
16. Strip width is responsive — only as wide as visible cells need, up to 10-cell cap.
17. Chevrons appear only when `#items > 10`.
18. Strip width animates at 180ms when content changes.
19. Pinned actions hoist to front of their category.
20. **Assembly stack renders in order: label (top) · strip · target card · balloon (bottom).** Target card sits between strip and balloon.
21. **Target card stays static-centered** — does not move across navigation.
22. **Balloon stays static-centered** — only its contents update across navigation. Balloon triangle points up at target card.
23. **Floating label tracks selected cell horizontally** — this is the only element whose X position changes with selection.
24. Menu renders above both ZeD windows and any vanilla UI.
25. Menu closes cleanly on action fire, cancel, or outside click.
26. Keyboard navigation works (arrows, Tab/Shift+Tab, Enter, Esc).

---

## 12. REFERENCE

- **Locked mockup:** `ZeDUI/mockups/zed_context_unified_v1.html` — interactive. Exercises:
  - **New vertical stack** — label · strip · target card · balloon
  - Drill-down (Eat / Craft / Transfer → submenus)
  - Back cell, disabled state with reason
  - Linear loop (cycling selection)
  - Responsive width with 10-cell cap — test buttons cycle 3/5/8/10/14/20 action counts
  - Visual loop (infinite carousel) at 14 and 20 action counts
  - Group-jump bumpers
- **Iteration archive:** `zed_gamepad_context_linear_v1.html` (superseded).
- **Research:** Session 87 chat covers vanilla Build 42 architecture, community pain points, UX science, mod landscape.
