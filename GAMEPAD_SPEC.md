# GAMEPAD_SPEC — flat free-nav

**Status:** LOCKED (S113, April 26 2026 — design director). Reconfirmed in words Oct 11 2026: "D-pad is the most accurate way to navigate to items. A/B are left and right mouse. X/Y are E/F and Tab/I. Chords are excellent. Predictable and logical."
**Supersedes:** the ring model (S97–S112; see `archive/GAMEPAD_SPEC.md`) and the stack model before it.
**Source of truth in code:** `Input/ActionMap.lua` (bindings), `Input/FocusManager.lua` (cone-nav, tap/hold timers, F9 overlay), `Input/BumperChord.lua` (zoom chord when no window is focused), `Input/InputModeDetector.lua`.
**Principle:** the gamepad is a mouse with a thumb. Every focusable element has the same callbacks for both input modes; focus paints exactly like hover; there is no gamepad-only state.

## Buttons

| Button | Meaning | Mouse / keyboard twin | Notes |
|---|---|---|---|
| D-pad | Move focus (cone-nav) | arrow keys | Up/Down never leave the current panel; Left/Right cross panels. Off-axis cost is left-biased ("like reading"). Landing on a tab strip from elsewhere lands on the active tab. |
| A | Activate | left mouse | Tap = click (`onActivate`). Hold 350 ms = `onHold` where an element defines one (seek acceleration, card toggle). |
| B | Cancel | Escape | Fires the focused element's `onCancel` only. If none, nothing happens. No shade-all, no hold variant. |
| X | Context | right mouse (E) | Tap = `onContextMenu` or `onReset`, never both. Hold 350 ms = drag mode: D-pad moves the held element (`onHoldContextDrag`), release = `onHoldContextRelease`. First consumer: container-strip reorder. |
| Y | Windows | Tab / I | Tap: open the pair · hide the pair · unhide the pair, by state. Hold 400 ms: close both. Gamepad-only. |
| LB · RB | Character · World | — | Absolute, not toggle. Both windows always open as a pair on gamepad. With no window focused, LB+RB chord = combat zoom (hold one, tap the other). |
| Back / View | Layout mode | — | Modal toggle on the focused window. |
| Right stick | Aim | mouse look | Magnitude past threshold hides the pair and returns to gameplay. |
| L3 · R3 | **never bound** | — | Hard Rule #11. |

## Focus rules

1. Tabs switch on **A**, never on focus. Sub-tab pills (Journal, Animals) still live-switch on focus — open item, should match.
2. Disclosures, stack chevrons, card open/close and grid scroll are **A on the element**; there are no window-level D-pad intercepts. Pseudo-focusable surfaces (maps cursor, animals zone cursor, grid-scroll regions) take `onDpadDir(w, el, dir)` first and `return false` to fall through to cone-nav.
3. **A on an inventory row toggles the card**: open · live-swap to another row · close.
4. Focus visual = the hover visual: 0.55α accent fill on the focused rect. Active tab adds a 2px side strip. No outlines, no glow, no drop shadow. The only extra cue is the 2px accent scoped underline in the title bar over the focused zone's x-range.
5. Scroll-follow fires on focus **change** (delta gate), never on input mode, because `InputModeDetector.getMode()` oscillates between frames (Q99).
6. Zones (`charTabBar`, `charContainerStrip`, `charMainInv`, `charTabContent`, `charItemCard` and the World mirrors) are storage only; dispatch flattens them. Builders keep calling `setRingZoneElements(win, zone, elements)`.
7. (Oct 23 2026, the director's first hands-on pad test.) **Entering a window** (LB, RB, Y, or Left / Right past a window's edge toward the other window) lands on the last focused element while it exists, else the item list's first row (`Focus.ensureEntry`, the window's `_focusEntryZone`); never on nothing lit. **Landing on a column from the side** lands on what it shows: a tab strip on the active tab, a container strip on the container on show, the item list on the row focus last had (`zone.landOn`). **A on a container** shows it and moves focus to its first item. **A on a row** opens the card with focus on its primary action (`isPrimary`: the card's CTA); in the card Up goes to the action strip in one press, Down to the next control, then reads on; B closes and returns to the row. **After an action** (card closed, menu closed, item moved) focus returns to the start, else its neighbour in the same panel. **The belt** is never entered from an open window; on the belt a direction with nowhere to go leaves it, as B does.

## Chords

Allowed where the result is predictable and both halves already mean something on their own. Shipped: LB+RB zoom (no window focused); X-hold + D-pad drag. Candidates: none locked — propose in a brainstorm session, not in code.

## What "parity" means for QA

For every surface in both windows: reach it by D-pad · see focus on it · A does what left-click does · X does what right-click does · B backs out of anything that has a back · the result is readable at both text sizes in all three themes. A surface that fails any of these is not done.

## Open (carried)

Sub-tab pills A-press parity · grid-scroll surfaces as real row focusables · hold-X drag visual (halo + dim siblings) · F9 overlay gated off in mouse mode · left-bias ratio tuning if it bites · rotary menu for the most-used verbs (design, post-floor).
