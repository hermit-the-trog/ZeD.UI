# Session 123 Delta — Oct 12, 2026

Boot version: `0.1.1220305j` (last commit `85313e9a` — S122, May 3 2026)
Baseline commit: `85313e9a` — S122 ItemCard dynamic state layer + cancel + rename + 480w polish
Close version: TBD (first S123 commit bumps to `0.1.1231210c`)

> **Boot mode active.** Ambient capture as decisions land. Custodian flushes to canon at closeout.
> **NB:** The Oct 11 2026 doc reorg (STATE.md replaces PROJECT_STATE.md; retired docs → `archive/`) was never committed. Staged and committed as the first act of S123.

## Session target

S123 — stable-42 recovery. Fix the dead ItemCard verbs, run the mod on stable (42.20.2, vanilla Lua last touched Oct 6 2026) for the first time, fix what `console.txt` shows. Goal behind the goal: QA-ready for a long gamepad play session.

## Boot audit (code vs stable sources)

Every member the mod calls on the seven vanilla classes changed in the Oct 6 update was checked against `E:\...\media\lua`, including through the `local CM = ISInventoryPaneContextMenu` alias in ItemCard. Result: exactly five dead references, all in `ZeD_ItemCard:_dispatchHeaderVerb`:

| Dead (never existed in stable) | Stable name |
|---|---|
| `CM.onWear` | `onWearItems(items, player)` |
| `CM.onEquipWeapon`, `CM.onEquipPrimary` | `OnPrimaryWeapon(items, player)`, `OnTwoHandsEquip(items, player)`, `equipWeapon(weapon, primary, twoHands, player)` |
| `CM.OnReadBook`, `CM.OnRead` | `onLiteratureItems(items, player)`, `readItem(item, player)` |

Everything else resolves. Audit lesson: a plain `ISInventoryPaneContextMenu\.\w+` grep misses alias references — audit `local X = Class` aliases too.

## Milestones / shipped work

### Dead verbs fixed (ItemCard.lua `_dispatchHeaderVerb`) — pending live verify
- EQUIP clothing → `onWearItems`. EQUIP weapon → `OnTwoHandsEquip` when `isTwoHandWeapon()`, else `OnPrimaryWeapon`, fallback `equipWeapon`.
- UNEQUIP → `unequipItem` (extinguishes lit candle/lantern first), fallback raw `ISUnequipAction`.
- READ → `onLiteratureItems` (illiterate / skill-level / tag guards), fallback `readItem`.

### Verb cluster refresh after verb fires (S122 carryover) — pending live verify
New `ZeD_ItemCard:_effectiveContext()` re-derives sourceContext each render from item state: equipped → `"equipped"`; container is player inventory → `"inventory"`; container type `"floor"` → `"ground"`; other container → `"container"`; unreadable → stored stamp. `render()` passes it to `renderBody` instead of the stored stamp. Fixes "EQUIP still shows after equipping until re-select".

### Debug noise
`ZeD.ContextMenu.Registry.DEBUG_LOG_UNKNOWN_ICONS` → `false`.

## User decisions captured at boot

(none yet — target was pre-approved at S122 closeout)

## Engine quirks discovered

(populated as the live run surfaces them)

## Open questions / probes

- Context-menu mispositioning on keyboard RMB (S122 carryover): anchor code already uses `getMouseX/Y`; suspect `InputModeDetector.getMode()` reporting `"gamepad"` during a KBM right-click (Q99 oscillation). Verify live.
- Q125–Q128 cooking/insulation probes still pending.

## Deferred

(populated at closeout)
