# Next Session Handoff
Generated: May 2, 2026 — Session 117 closing, S118 booting.

## Target
**S118 — pick one with user at brainstorm gate.** Strong candidates surfaced during S117:

1. **Item card detail zone for clothing** (TOOLTIP_SPEC.md v11 ⏳) — per-zone structural docks (TORN/WORN/Leather/Denim flag + repair/remove button) and soiled flags (🩸/🟤/💧 colored % text). Lands all the M15 dock-molecule wiring that's been waiting since S115.
2. **Action strip verb side wiring** (TOOLTIP_SPEC.md v11 ⏳) — Wash / Dry / Repair All / Pad All for clothing; Repair / Sharpen for weapons; Eat / Cook for food; Read for books; Refill for drainables. Verb side is mostly empty today.
3. **Item rename / inspect window** — editable name field + full ZeD_Window chrome inspect mode (right-click → Inspect path). Spec locked, code ⏳.

## Current state
Version `0.1.1170205g` (S117 shipped). Radio tab is fully gamepad-functional in both Character + World windows: D-pad cone-navs the chassis, A activates / toggles assign mode / fires CD transport, A-hold on seek does mouse-parity 4-tier accelerating tune. Item card now A-toggles on inv items (was D-pad LEFT/RIGHT). Card stays interactive when overlaid on a tab drawer (was: focusable only in pure item-mode). Memory cleanup pass landed: gamepad-scheme entry now reflects the live S113 FLAT FREE-NAV model, not the retired S97 ring.

## Open decisions
- **Volume hold-acceleration parity.** Currently single-fire on both mouse and gamepad. Mouse seek has 4-tier acceleration; volume doesn't. Decide if volume should match seek or stay single-fire — defer until live testing flags it.
- **Card overlay UX on contextual-chassis tabs.** Card overlaying the radio chassis is interactive (S117 fix) but visually crowds. Future option: suppress card overlay entirely on contextual tabs (radio/TV/walkie/etc.) since the drawer IS the content. Park until TV chassis exists.
- **Smashicons EPS source zips** (~500 MB+) still in git history — should be `.gitignore`d and stripped. Defer to a housekeeping pass.

## Known blockers
None for the candidate targets above.

## Warm context
- **Gamepad scheme is S113 FLAT FREE-NAV.** LB→Character (absolute), RB→World (absolute), D-pad cone-nav, A=LMB / toggle for inv card, X=RMB, B=`el.onCancel` or no-op, Y-tap pair-toggle / Y-hold close-pair. PROJECT_STATE.md older session entries still contain S97 ring prose — DEFER TO `42/media/lua/client/ZeD/Input/ActionMap.lua` and `FocusManager.lua` header lines 11–23 as live source of truth.
- **A toggles inv item card** (S117). Mouse click still single-shot select. Stack reps still expand on A; A on a child runs the toggle.
- **Card overlay focusability gates on `_drawerItem ~= nil`** in BOTH windows now (Char was on `_drawerMode == "item"` until S117 — fixed). Future card-related builders should follow this pattern.
- **Per-frame refresh allow-list pattern.** Tabs that stamp focusable rects DURING render (radio, maps) need their tab id added to the per-frame refresh allow-list in BOTH windows (Char:4969, World:3782). Without this, focusables stay empty past initial tab-switch.
- **Radio chassis click zones** (mouse + gamepad share): `win._radioBrowsePrevZone`, `_radioBrowseNextZone`, `_radioPwrZone`, `_radioSeekBtnZones[1..2]`, `_radioVolBtnZones[1..2]`, `_radioPresetZones[1..N]`, `_radioPresetAddZone`, `_radioCDZones[1..7]` (Premium-only — nil on ValuTech).
- **`_radioSeekHold` state machine** is shared between mouse and gamepad. Mouse arms with no `source` field; gamepad arms with `source = "gamepad"` + captured `jid`. Render-loop disarm check distinguishes via `if hold.source == "gamepad"` and polls `JoypadButton.A:isDown(hold.jid)`.
- **PZAPI-KB Q116–Q124 (S115) still apply** to any radio work: getPower 0..1 float, channel = MHz×1000, `getZomboidRadio()` not bare global, Kahlua pcall log spam → field-probe pattern, ArrayList:get bounds, forward-decl shadow trap, mutate-in-place tokens, Fira font no bullet glyphs, ISRadioWindow auto-open suppression.

## Don't forget
- **BOOT ritual (mandatory):** first action at S118 boot is `git log --oneline | head -30` cross-checked against PROJECT_STATE.md `Current: 0.1.1170205g`. Drift = halt and reconcile.
- **Pre-flight every test cycle:** grep `C:\Users\danie\Zomboid\Logs\<latest>\*DebugLog.txt` for `ERROR|Kahlua|RadioTab|attempt to call.*nil|attempt to index.*nil` before claiming clean. Engine `ERROR: ModelManager` / `ERROR: Translation` are baseline noise — ignore.
- **Hot-reload unreliable; full PZ restart for every test cycle.**
- **Version bump format:** `0.1.[session][DDMM]<suffix>`. S118 starts at `0.1.118MMDD`. Suffix walks `c→d→…→z→aa→ab→...` if iterating.
- **End-of-session ritual:** `git add . && git commit -m "S[N]: ..." && git push`. Code AND docs in same commit.
- **Custodian capture is AMBIENT now.** Decisions land in `ZeDUI/deltas/SESSION_NN_DELTA.md` as they happen, not at closeout.
