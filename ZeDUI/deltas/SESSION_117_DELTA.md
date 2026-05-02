# Session 117 Delta — May 2, 2026
Boot version: `0.1.1163004`

## Locked decisions
- **A toggles the inv item card** (gamepad). A on the focused inv item opens the card; A again on the same item closes it. Applied uniformly in 4 onActivate sites: Char invrow, Char MC, World invrow, World MC. Replaces the prior "D-pad LEFT/RIGHT to open/close" mental model — now A is the canonical "look at this item" button.
- **A-hold on radio seek arms full mouse-parity acceleration.** Hold past A_HOLD_MS (350ms) → onHoldActivate fires `_channelStep` once + arms `win._radioSeekHold` tagged `source = "gamepad"` with captured `jid`. Render loop's existing 4-tier curve (200/100/50/25 ms) drives auto-repeat. Disarm polls `JoypadButton.A:isDown(jid)`. Hold parity originally deferred per S117 plan; user requested it during live testing.
- **Item card stays interactive when overlaid on a tab drawer** (Char). Card-zone focusability gate flipped from `_drawerMode == "item"` to `_drawerItem ~= nil` — mirrors World's existing pattern. `_buildCardActionFocusables` got the same gate flip.
- **Stack-rep A-press flow confirmed.** A on a stack rep toggles expand/collapse; A on a child invrow runs the new card-toggle. Two-press intentional: expand, then select.

## Rejected approaches
- **Letting B dismiss the item card overlay.** Rejected during S117 mid-session — B is contextual `onCancel` only post-S113 (no shade-all fallback). User clarified that A-toggle is the dismissal path, not B.
- **Generalizing radio chassis layer prematurely.** Carried-forward from handoff: TV / shortwave / walkie-talkie chassis remain SEPARATE future sessions. Don't try to genericize the contextual-drawer layer until at least one more chassis exists to compare against.

## Engine quirks discovered
- None new this session. Q116–Q124 from S115 still cover the radio surface; no new patterns surfaced.

## Design rules added or updated
- **Gamepad scheme is S113 FLAT FREE-NAV, not S97 ring.** Captured to memory (`feedback_bumpers_window_toggle.md` rewritten as canonical scheme entry). LB → Character (absolute), RB → World (absolute), D-pad cone-navs all zones, A=LMB/toggle, X=RMB, B=onCancel-or-noop, Y=pair lifecycle. PROJECT_STATE.md prose still contains S97 ring references in older session entries — defer to ActionMap.lua + FocusManager.lua (lines 11–23) as the live source of truth.
- **Focus-cue overlay convention extended to contextual chassis.** Single 0.55α accent-fill rect on the focused control's stamped rect, painted AFTER the chassis molecules so it sits on top of button bgs. Gated on focused-window match + zone name (`charTabContent`/`worldTabContent`) + element id prefix. Matches `feedback_focus_paint_convention.md`. Pattern is reusable for future contextual drawers (TV/walkie/etc.).
- **Per-frame refresh allow-list must be updated whenever a tab uses chassis-stamped zones.** Symptom of omission: tab is visually rendered but its focusables stay empty / non-focusable forever, because `_syncRingZonesToActiveTab` fires once at tab-switch (before chassis render) and the per-frame catch-up doesn't pick up new tab IDs not in the allow-list. Char:4969, World:3782.

## Milestones / shipped work
- ✅ **Radio gamepad focusables wired both windows.** `ZeD.RadioTab.buildFocusables(win)` exports the chassis controls in click-router scan order. Per-window `_buildPanelFocusables` / `_buildWorldPanelFocusables` dispatch to it via guarded cross-module branch. Per-frame refresh extended to `"radio"` in both window allow-lists.
- ✅ **Focus-cue overlay paint** at the end of `ZeD.RadioTab.render`. Resolves focused element id → stamped zone rect via lookup table; paints 0.55α accent fill.
- ✅ **A-hold seek acceleration** wired to existing `_radioSeekHold` state machine. Generalized disarm check distinguishes gamepad (`JoypadButton.A:isDown(jid)`) from mouse (`isMouseButtonDown(0)`).
- ✅ **A-toggle for item card** across all 4 inv onActivate handlers (Char + World, main + MC).
- ✅ **Char card-zone gate parity with World.** `_buildCardActionFocusables` and the per-frame `charItemCard` refresh both gate on `_drawerItem ~= nil` now.
- ✅ **Memory cleanup pass** (out-of-band but session-related). Rewrote `feedback_bumpers_window_toggle.md`, `feedback_per_column_mc_zones.md`, `project_world_mirrored_layout.md`. Deleted stale `project_zedui_status.md`. Light edits on `feedback_no_confirm_for_no_chain.md`, `feedback_only_focused_zone_shows_active.md`. MEMORY.md index updated.

## Open questions parked
- **Hold-to-repeat on volume.** Currently single-fire on both mouse and gamepad. Mouse seek has 4-tier acceleration; volume doesn't. If volume rate feels too slow during testing, mirror the seek pattern. Defer until user feedback.
- **Card overlay UX on contextual-chassis tabs.** Card overlaying the radio chassis is now interactive (focus gate fixed) but visually crowds the chassis. Future option: suppress the card overlay entirely on contextual tabs (radio/TV/walkie/etc.) since their drawer IS the content; card has nowhere meaningful to live. Park until TV chassis lands and the pattern matters across multiple drawers.
- **Stale "four grey SEEK/VOL buttons TBD" entry in NEXT_SESSION_HANDOFF.md.** They turned out to already be wired to `_channelStep`/`_volStep`. The S116 handoff was written from outdated memory. Reminder for closeout: don't propagate the question into S118 handoff.

## Mockups touched
- None this session.

## Verification status
Pending in-session live testing. User reports each issue, I fix, user retests. Resolved so far:
- Initial radio-not-focusable on game-load → per-frame allow-list fix
- Stuck card on radio tab → root cause was the above
- No focus cue on radio chassis → overlay paint added
- A-hold on seek not accelerating → mouse-parity hold state machine wired
- Card unfocusable when overlaid on tab drawer → Char gate flipped to match World

## Files touched
- `42/media/lua/client/ZeD/RadioTab.lua` (buildFocusables, render-time empty-radios clear, focus-cue overlay, render seek-hold disarm generalization, seek onHoldActivate)
- `42/media/lua/client/ZeD/ZeD_CharacterWindow.lua` (radio dispatch branch, _gpFocusedRadioCtl clear, per-frame allow-list, A-toggle in 2 onActivate sites, card-zone gate fix in 2 places)
- `42/media/lua/client/ZeD/ZeD_WorldWindow.lua` (radio dispatch branch, _gpFocusedRadioCtl clear, per-frame allow-list, A-toggle in 2 onActivate sites)
