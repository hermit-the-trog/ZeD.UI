# Next Session Handoff
Generated: April 30, 2026 — Session 116 closing, S117 booting.

## Target
**S117 — RADIO GAMEPAD FOCUSABLES** (originally queued as S115c, displaced by the S116 tooling session). Wire radio chassis controls into the gamepad ring system: build a focusable element list returning chassis controls in scan order (browse_prev, browse_next, power, seek_btn[1..2], vol_btn[1..2], preset[1..N], preset_add, cd_btn[1..7]) and dispatch `onActivate` to existing action functions in `RadioTab.lua`. Per `feedback_gamepad_pattern_parity.md`, focusable list MUST replicate identically across both windows (Char + World).

## Current state
Version `0.1.1163004` (S116 shipped, tooling session — no Lua touched). Git is now live on the mod, mirrored to private GitHub repo `hermit-the-trog/ZeD.UI`. New `zed-session-docs` skill installed with ambient capture + boot drift detection + flush-style closeout. Radio contextual drawer (S115) is fully clickable in both Char + World windows; gamepad path is the missing piece.

## Open decisions
- **The four grey SEEK/VOL buttons** still consume clicks but no-op — need user spec on their behavior. Candidates: preset prev/next, scan-up/scan-down, mute/max, split-step. USER DECISION REQUIRED before wiring activation.
- **Right-click "Use" world-radio path** still calls vanilla `ISRadioWindow.activate(...)`. Suppress when ZeD context-menu route is wired (deferred, not S117-blocking).
- **Smashicons EPS source zips** (~500 MB+) currently in git. Should be `.gitignored` and stripped from history. Defer to S118 housekeeping pass.

## Known blockers
None for the gamepad-focusables work itself. The four-grey-button behavior question can be deferred — paint focus rings + dispatch their `onActivate` to no-op functions for now, fill in later.

## Warm context
- **Click router lives at** `42/media/lua/client/ZeD/RadioTab.lua` — `ZeD.RadioTab.onClick(win, x, y)` is dispatch entry. Action functions to call from gamepad `onActivate`: `_browsePrev(win)`, `_browseNext(win)`, `_powerToggle(dd)`, `_channelStep(dd, dir)`, `_volStep(dd, dir)`, `_presetApply(dd, slotIdx)`, `_presetToggleAssign(win)`, `_presetStore(dd, slotIdx)`, `_cdTransport(dd, btnIdx)`. All file-locals — gamepad builder lives in same module so it has access without exporting.
- **Click zones already stamped per render** by chassis molecules: `win._radioBrowsePrevZone`, `win._radioBrowseNextZone`, `win._radioPwrZone`, `win._radioSeekBtnZones[1..2]`, `win._radioVolBtnZones[1..2]`, `win._radioPresetZones[1..N]`, `win._radioPresetAddZone`, `win._radioCDZones[1..7]`. The gamepad builder reads the SAME stamped rects — element bounds already coord-translated panel-local.
- **Pattern reference for focusable builders:** `_buildEquipmentFocusables(win)` in `ZeD_CharacterWindow.lua` (S100/S101 equipment slot focusable system, post-disclosure-refactor). Returns flat element array `{x, y, w, h, id, onFocus, onActivate}` per element. Per-frame seed-stomp gating already known (memory: `feedback_seed_stomp_race.md` — set `_gpFocusedRadioCtl = elements[1].id` only when nil so D-pad onFocus writes don't get clobbered next frame).
- **Window dispatch hook:** in `ZeD_CharacterWindow.lua` and `ZeD_WorldWindow.lua`, the per-tab `_buildPanelFocusables` function returns the focusable list. Add `if tabId == "radio" then return ZeD.RadioTab.buildFocusables(win) end` branch. No new ring zone needed — uses existing `worldTabContent` / `charTabContent` zones.
- **Critical PZAPI-KB quirks for radio (Q116–Q124):** `getPower()` is 0..1 float; channel = MHz×1000; `zomboidRadio` is NOT a global (use `getZomboidRadio()`); Kahlua `pcall` STILL logs caught errors (use field-probe pattern); `ArrayList:get(N)` for N >= size() throws; `local function name` after `local name` SHADOWS not assigns (use `name = function`); mutate-in-place token tables preserve identity across reload; Fira font lacks Unicode bullet glyphs (use `drawRect`/`drawRectBorder`); `ISRadioWindow.onEquip` removed at OnGameBoot to suppress vanilla popup.

## Don't forget
- **NEW BOOT STEP (mandatory under rewritten skill):** first action at S117 boot is `git log --oneline | head -30` cross-checked against PROJECT_STATE.md latest version (`0.1.1163004`). If they disagree → halt, reconcile drift before any work proceeds. This prevented 90+ messages of confusion this session.
- **Pre-flight every test cycle:** grep `C:\Users\danie\Zomboid\Logs\<latest>\*DebugLog.txt` for `ERROR|Kahlua|RadioTab|attempt to call.*nil|Tried to call nil` before claiming the radio drawer is clean. Q119 / Q120 / Q121 patterns are EASY to reintroduce.
- **Hot-reload unreliable; full PZ restart for every test cycle.**
- **Version bump format:** `0.1.[session][DDMM]<suffix>`. S117 starts at `0.1.117DDMM`. Suffix walks `b→c→…→z→aa→ab→...` if the session iterates many cycles.
- **Preset interaction model** (locked, don't undo): orange "+" enters assign mode, click slot to store. NO "-" remove button. Slot buttons always show slot number — NEVER the stored frequency (1993 hardware aesthetic ruling).
- **Off-state visual contract** (locked): bg shifts to grey-green LCD / near-black VFD; bars+chips dim 35%; freq → "---.- MHz"; station name suppressed; SIG → "-"; chips fill+dim. Text colors UNCHANGED. Frequency Y-position FROZEN.
- **Effective-power gate** is anti-exploit: a dead-battery radio MUST read as off regardless of switch state. Don't loosen this gate when adding gamepad — focus path should respect the same effective-power state.
- **TV / shortwave / walkie-talkie chassis are SEPARATE future sessions.** Don't try to genericize the radio chassis layer until at least one more contextual drawer exists to compare against.
- **End-of-session ritual:** `git add . && git commit -m "S117: ..." && git push`. Code AND docs in same commit. PROJECT_STATE.md no longer hand-tracks file-structure changes — git owns the WHAT, docs own the WHY.
