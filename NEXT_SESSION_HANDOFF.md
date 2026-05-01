# Next Session Handoff
Generated: April 30, 2026 — Session 115 closeout

## Target
**S115c — RADIO GAMEPAD FOCUSABLES.** Wire the chassis controls into the gamepad ring system: build a focusable element list returning chassis controls in scan order (browse_prev, browse_next, power, seek_btn[1..2], vol_btn[1..2], preset[1..N], preset_add, cd_btn[1..7]) and dispatch `onActivate` to the existing action functions in `RadioTab.lua`. Per `feedback_gamepad_pattern_parity.md`, the focusable list MUST replicate identically across both windows (Char + World).

## Current state
Version `0.1.1153004ax` (S115a + S115b shipped). Radio contextual drawer fully clickable in both windows: equipped radios in Char window, IsoWaveSignal radios in 3x3 player range in World window. Browse arrows cycle reachable radios with location-pill `(idx)` indicator. Power button toggles `setIsTurnedOn`. SEEK +/- buttons step 0.1 MHz (raw step = 100) with hold-to-repeat acceleration (250ms→200→100→50→25ms). VOL +/- step 1/8. Preset slots apply stored frequency; "+" assign-mode toggle stores current frequency to chosen slot N (gap-fills with freq=0 placeholder). Both Premium silver + ValuTech black chassis tiers render. Vanilla `ISRadioWindow` popup suppressed; on-equip auto-tab-switch flips Char window to Radio tab.

## Open decisions
- **The four grey SEEK/VOL buttons** currently consume clicks but no-op — need user spec on their behavior. Candidates: preset prev/next, scan-up/scan-down (auto-seek to next station with signal), mute/max, split-step (e.g., 0.5 MHz jump). USER DECISION REQUIRED before wiring activation in S115c.
- **Right-click "Use" world-radio path** still calls vanilla `ISRadioWindow.activate(...)` (`ISWorldObjectContextMenu.lua:222`). Suppress when ZeD context-menu route is wired (deferred, not S115c-blocking).

## Known blockers
None for the gamepad-focusables work itself. The four grey buttons block can be deferred — paint focus rings + dispatch their `onActivate` to no-op functions for now, fill in later.

## Warm context
- **Radio click router lives at** `42/media/lua/client/ZeD/RadioTab.lua` — `ZeD.RadioTab.onClick(win, x, y)` is the dispatch entry. Action functions to call from gamepad `onActivate`: `_browsePrev(win)`, `_browseNext(win)`, `_powerToggle(dd)`, `_channelStep(dd, dir)`, `_volStep(dd, dir)`, `_presetApply(dd, slotIdx)`, `_presetToggleAssign(win)`, `_presetStore(dd, slotIdx)`, `_cdTransport(dd, btnIdx)`. All are file-locals; the gamepad builder lives in the same module so it has access without exporting.
- **Click zones already stamped per render** by chassis molecules: `win._radioBrowsePrevZone`, `win._radioBrowseNextZone`, `win._radioPwrZone`, `win._radioSeekBtnZones[1..2]`, `win._radioVolBtnZones[1..2]`, `win._radioPresetZones[1..N]`, `win._radioPresetAddZone`, `win._radioCDZones[1..7]`. The gamepad builder reads the SAME stamped rects — element bounds are already coord-translated panel-local.
- **Pattern reference for focusable builders:** `_buildEquipmentFocusables(win)` in `ZeD_CharacterWindow.lua` (S100/S101 equipment slot focusable system, post-disclosure-refactor). Returns flat element array with `{x, y, w, h, id, onFocus, onActivate}` per element. Per-frame seed-stomp gating already known (memory: `feedback_seed_stomp_race.md` — set `_gpFocusedRadioCtl = elements[1].id` only when nil so D-pad onFocus writes don't get clobbered next frame).
- **Window dispatch hook:** in `ZeD_CharacterWindow.lua` and `ZeD_WorldWindow.lua`, the per-tab `_buildPanelFocusables` function returns the focusable list. Add `if tabId == "radio" then return ZeD.RadioTab.buildFocusables(win) end` branch. No new ring zone needed — uses existing `worldTabContent` / `charTabContent` zones.
- **Critical engine quirks for next session (from PZAPI-KB Q116-Q124):** `getPower()` is 0..1 float; channel = MHz×1000; `zomboidRadio` is NOT a global (use `getZomboidRadio()`); Kahlua `pcall` STILL logs caught errors (use field-probe pattern); `ArrayList:get(N)` for N >= size() throws; `local function name` after `local name` SHADOWS not assigns (use `name = function`); mutate-in-place token tables preserve identity across reload; Fira font lacks Unicode bullet glyphs (use drawRect/drawRectBorder); `ISRadioWindow.onEquip` removed at OnGameBoot to suppress vanilla popup.
- **New canonical token:** `T.sp.tabHeaderH = 37` — single source of truth for drawer-header strip height, sourced by Molecules / RadioTab / MapsTab / EquipmentTab / CraftingCore. Tune in one place.
- **drawTabHeader rewrite:** now paints disclosure arrow + title + 1px bottom rule, NO bg fill. Inherits parent panel surface (project rule: avoid redundant bgs). `drawSectionHeader` UNTOUCHED so ItemCard / AnimalsTab / CraftingCore inline disclosures retain their bg behavior.
- **Equipment tab disclosure semantics flipped:** pinned header now reads "Equipped" (not "Defense"); `win._equipListExpanded` toggles slot list visibility; defense body always at bottom. Field name `_equipDefenseZone` retained for backward compat with click + gamepad routing — same hit zone, different content.

## Don't forget
- **Pre-flight every test cycle:** grep `C:\Users\danie\Zomboid\Logs\<latest>\*DebugLog.txt` for `ERROR|Kahlua|RadioTab|attempt to call.*nil|Tried to call nil` before claiming the radio drawer is clean. Q119 / Q120 / Q121 patterns are EASY to reintroduce.
- **Hot-reload unreliable; full PZ restart for every test cycle.**
- **Version bump format:** `0.1.[session][DDMM]<suffix>`. S115c starts at `0.1.115DDMMc`. Suffix walks `c→d→…→z→aa→ab→...` if the session iterates many cycles (S115 walked to `ax`).
- **Preset interaction model** (locked, don't undo): orange "+" enters assign mode, click slot to store. NO "-" remove button. Slot buttons always show slot number — NEVER the stored frequency (1993 hardware aesthetic ruling).
- **Off-state visual contract** (locked): bg shifts to grey-green LCD / near-black VFD; bars+chips dim 35%; freq → "---.- MHz"; station name suppressed; SIG → "-"; chips fill+dim. Text colors UNCHANGED. Frequency Y-position FROZEN.
- **Effective-power gate** is anti-exploit: a dead-battery radio MUST read as off regardless of switch state. Don't loosen this gate when adding gamepad — the focus path should respect the same effective-power state.
- **TV / shortwave / walkie-talkie chassis are SEPARATE future sessions.** Don't try to genericize the radio chassis layer until at least one more contextual drawer exists to compare against.
