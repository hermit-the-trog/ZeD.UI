# Code flags from the comment pass (Nov 8 2026)

While rewriting every comment in 42/media/lua, the agents read each file in full and noted places where the code looked wrong, dead or risky. Nothing here was changed: the pass touched comments only. Each item names the file (and line where known). Items marked LIKELY BUG or POSSIBLE BUG are worth a test; the rest are dead code and small inconsistencies. Line numbers are as of the comment pass and may drift.

## Batch 30 (shared protos)
1. Tk.parse doc contradicted code: returns ANY all-caps bracketed word as kind, never checks isKind itself — callers must filter (sameTicket does). Doc fixed to match code.
2. Tk.FILE_FULL_TEXT=false disagrees with ZeDUI/MP_SERVER_PART_DESIGN.md E13 ("filed in full for now, as scoped"). Code ships the private stub. Doc stale or constant flipped — user to resolve.
3. canReply/canAnswer/canClose are three identical expressions behind one REPLY_AT_ANSWERED switch — flipping it changes player reply window AND both staff gates together.
4. Tk.name truncates by bytes (NAME_MAX=64); non-ASCII username could be cut mid-character. Cosmetic.
## Batch 05 (admin/animals/atoms)
1. AnimalsTab.lua GENE_LABELS (~line 1962): old comment claimed "vanilla's 19" but table holds 18 entries — one vanilla gene may be missing. Check against vanilla gene list.
2. AnimalsTab.lua: zoneName treated as stable ID but zone names aren't unique — poller keys zoneSummaries by name; a manual rename collision could show the wrong roster.
3. AnimalsTab.lua renderRanchZone: `local player = getSpecificPlayer(0)` declared twice (redundant shadow).
4. BuildingTab.lua gatherDetail: captured return `local containers = CC.gatherDetail(...)` never used — leftover.
## Batch 01 (Molecules.lua) — stale banners fixed in place; suspicions:
1. Molecule-ID numbering conflicts with GLOSSARY.md (file had title bar=M14, data row=M15, action strip=M16; glossary says M14=drawActionStrip, M15=drawDock; file also duplicated M15/M16). Aligned to glossary; design-inventory numbering needs an audit.
2. ZeD_TextInput is a visual-only stub (onKeyPress does nothing real); real input is ZeD_TextEntry/ZeD_SearchField — possibly dead code.
3. drawContextFloatingLabel may be dead since the balloon subsumed it — check callers.
4. drawWindowTitleBar stat-cluster boundary measures UNtruncated title (minX uses `title` not `displayTitle`) — stats can be dropped that would fit; likely unintended.
## Batch 22 (MainMenu Mods group)
1. REAL LATENT BUG: ZeD_MainMenuMods.lua ~2525 `local _wheel = MM.wheel` wrap has NO reload guard (unlike Mail's MM._mailWheelBase pattern) — and this screen triggers getCore():ResetLua on accept, so each accept stacks another wheel wrapper. Copy Mail's guarded pattern.
2. ZeD_MainMenuMods.lua ~208: CACHE_MS=150 never read (caches use SLOW_MS/PROB_MS/ROWS_MS) — dead constant.
3. ZeD_MainMenuModsOrder.lua ~99: orderSectionHook is a dead seam (nothing overrides; Seps wraps orderEntries wholesale).
4. ZeD_MainMenuModsOrder.lua ~216: orderStates has zero callers in repo — dead unless external mods use it.
5. ZeD_MainMenuMail.lua ~233: `local m, err = MS.queue(...)` ignores err; always shows "Outbox full" though queue can fail for to/subj/text — latent mislabel if putWhy drifts from Ml validators.
6. ZeD_MainMenuMail.lua 52: MM.mailWhen exported, no callers — possibly dead.
7. Minor: ZeD_MainMenuMods.lua drawList unused `local cb = T.checkboxSz`.
## Batch 14 (Overrides + misc)
1. Overrides/ContextMenu.lua is the ONE override without a reload guard: plain `local orig* = X` captures of ISContextMenu.get/clear/prerender/render + createMenu — a Lua reload double-wraps. Every other override guards this. (Same family as the Mods wheel-wrap flag.)
2. ProtectionTab.lua uses `ZeD.ProtectionTab = {}` not the reload-safe `... or {}` — harmless today, off-pattern.
3. QABridge.lua header says "safe to ship in Workshop builds" while its probe block says "dev only, never staged" — one is wrong about packaging; both behaviors -debug-gated.
4. QABridge.lua probe replaces GLOBAL pcall when armed (flag-file + -debug gated) — intentional but worth knowing.
5. Overrides/RadioWindow.lua cites vanilla source line numbers (ISRadioWindow.lua:412-413) — will drift with game patches.
## Batch 10 (journal/maps/mech)
1. JournalTab.lua ~544: _measureRecipeContent has NO callers and reads recipeData.groups/group.items — fields gatherRecipeData never produces. Dead + shape-mismatched; RCELL_SZ/RCELL_GAP only used by it.
2. MapsTab.lua: gpCursorStep + MAP_GP_STEP_PX/MAP_GP_STEP_MAX have no callers (D-pad map-cursor path retired; stick uses MAP_GP_STICK_*). Dead export.
3. MechFigs.lua: stated generator path ZeDUI/tools/mechanics/pixel_mech_figs.py doesn't exist in repo (script name kept, dir dropped) — generator lives outside the repo or moved.
## Batch 11 (mechanics + ModSupport part 1)
2. MechanicsTab.lua renderFooter ~1919: hovering a DISABLED footer verb still sets s.verb — the card silently swaps which verb's chance bar/pick list shows on a greyed hover. Deliberate-looking but worth a glance if hover flicker gets reported.
3. MenuNote.lua: data holds exactly 5 entries; menu reads at most 5 and cuts at 10 chars — a 6th line would be silently ignored, nothing warns.
4. MenuNote.lua: old header's "corkboard" claim was stale — the note draws on the desk's ruled yellow paper (NOTE_* constants). Fixed to "desk".
## Batch 18 (car radio/chat/claims/community)
1. CONFIRMED dead code (two agents independently): Molecules.lua drawContextFloatingLabel (~4159) and drawContextTargetCard (~4229) have no callers anywhere — ZeD_ContextMenu.lua draws strip+bumpers+one bubble now.
2. ZeD_ControllerMap.lua: onJoypadDown closes on A as well as B, but the footer prompt advertises only B — if A-to-close is unintended (A usually means "press"), that's a code question.
3. ZeD_ClaimCards.lua header said "four cards", code registers six — fixed in comments; worth knowing the header had drifted.
4. ZeD_Chat.lua readPlace: safe() returns only the first of five values, hence raw pcall there — pattern worth remembering.
## Batch 13 (object cards, Organisms, first overrides)
1. ObjectCardPreview.lua header taught the WRONG strength formula (old getHealth/getWoodHealth story); code uses script health + sandbox Construction Bonus Points multiplier + skill-based bonus. Comments now match code.
2. Organisms.lua JOYPAD DISPATCH banner claimed a no-op/"silently swallowed" — stale: Input/FocusManager.lua:1631 is a full dispatcher now.
3. Organisms.lua referenced WHAT_CODE_DID.md quirks #1-#3 in four places — file doesn't exist anywhere; the numbered quirk catalog is gone (quirk content now inlined in comments).
4. Organisms.lua:85 `o.clearStentil = true` — matches vanilla PZ's own misspelled engine field; nothing in ZeD reads it (engine side may). Only occurrence of that spelling.
5. Overrides/Belt.lua header's D-pad Left claim was stale (opens ZeD's Character wheel, not belt focus) — fixed.
## Batch 24 (main menu tail, messages, mod management)
1. ZeD_Messages.lua reportHeader (~532) says "ZeD-GUI <version>" — agent flagged as typo, BUT mod.info's display name IS "ZeD-GUI" (id=ZeD_UI), so likely deliberate branding. Decide which name is canonical.
2. ZeD_MainMenuTraits.lua drawRow (~435): XP-boost percent hardcoded (+75/+100/+125) — matches vanilla today, will silently drift if the game changes multipliers.
3. ZeD_MessagesWindow.lua update (~671): W.qaJoy test hook can force controller focus in production if ever left set.
## Batch 19 (dashboard/desk-notes/extras)
1. ZeD_Dashboard.lua ~941: split-screen odometer behavior was tagged "known issue Nov 7" in old comments but reads like working behavior — recent/undertested ambiguity worth a QA pass.
2. ZeD_Dashboard.lua: two ROADWORTHY HOOK integrations genuinely unwired (coolant/belt/oil/high-beam lamps; direct odometer read) — real TODOs kept in comments.
3. ZeD_FocusPaint.lua: FP.paint alias has zero callers — dead API surface kept for the old name.
4. ZeD_DeskNotes.lua header undersold the index read cap (code reads MAX*4+1 lines) — fixed to match code.
## Batch 02 (PhysPx.lua)
1. Plate `title` field is read by nothing under 42/media/lua — exporter-side metadata with inconsistent casing; if titles were meant to caption cards, that wiring doesn't exist.
2. Old header's inventory and width claims were substantially stale (missed watches/TVs/laundry/radios, wrong narrow-width generalization) — all corrected against consumers.
## Batch 12 (ModSupport part 2, object cards)
1. moodle_quarters.lua: comment claimed extent lives in "S.extent" — doesn't exist; code uses panel._zedExtent (QA script reads that). Fixed to match.
2. ObjectCardLaundry.lua cited "pad rule 1" where GAMEPAD_SPEC.md's current numbering has that behavior as focus rule 7 — stale citation, fixed.
3. modOn() duplicated near-verbatim across most ModSupport files — consolidation candidate (code untouched).
## Batch 17 (admin cards/tools, belt, body figure, bubbles)
1. ZeD_Belt.lua header's ASCII sketch showed the superseded hands-apart layout; code puts both hands at the left end — redrawn to match.
2. ZeD_Belt.lua:919 mini-watch fallback (44/46 * T.art) didn't fully reconcile with the comment's "92 px art, 84 px hands" at a glance — unproven, but worth a look if mini-watch sizing misbehaves.
3. ZeD_BodyFigure.lua path line named the wrong file (BodyFigure.lua) — fixed.
4. Tester username "tjk" removed from ZeD_AdminCards.lua comments (dev bookkeeping, not public credit).
## Batch 07 (equipment/foraging)
1. LIKELY BUG: EquipmentTab.gatherData's old comment said "first item wins = outermost layer", but EquipDoll.gather documents vanilla keeps worn items INNERMOST-first and compensates — so EquipmentTab's forward first-wins likely keeps the innermost item for a multi-location slot (sweater shown while a jacket is worn). One of the two files is wrong.
2. EquipDoll: whole `av` dataset in D.SLOTS + D.renderLines line/dot drawing are dead (D.draw always stamps win._equipDollLines = {}). Removal candidates.
3. EquipmentTab: _measureDefenseDashboard returns +pad, _drawDefenseDashboard returns +pad*2 — disagree (only measure matters today).
4. ForagingTab.onMouseWheel appears unwired — nothing calls it.
5. DashPx.lua is generated by ZeDUI/tools/dashpx/export_lua.py — regeneration will overwrite the new header unless the exporter template is updated. (Same likely applies to PhysPx.lua / export_phys.py, MechFigs, PixelFonts.)
## Batch 09 (inventory renderer, item card group) — resumed on Opus
1. ItemActionHooks reading fallback checks only the Character window's card when choosing among carried books; the cooking poll checks both windows' cards — inconsistent.
2. Dead rename leftovers in ItemCard: _commitRename never called, _renameInput never assigned, _renaming only ever set false — renderBody's rename branch can never run.
3. POSSIBLE BUG: ZeD_ItemCard:_toggleFold clamps scroll with _calcBodyH (old non-drawer layout), but every card is built in drawer mode (renderBody's _contentH). If the old height is smaller, folding a section can jump the scroll. calcHeight() has no callers.
4. ItemActionManager: a Lua reload resets _nextHandle to 1 but keeps _observers — a new observer could overwrite an old slot (nothing registers observers yet).
5. ItemFactsPanel: a reload rebuilds M._registry from scratch, dropping factories add-ons registered via M.register (reload-safety gap).
## Batch 23 (main-menu options/sandbox/saves) — resumed on Opus
1. Reload-wrap pattern again: Options and Sandbox wrap MM.wheel without keeping a base (unlike Notes/Mail/Docs) — single-file reload wraps the wrapper. Several main-menu files share this; same family as the Mods wheel and ContextMenu flags.
2. Options setConfirm("key") targets focus "confirm:yes", a button the key band doesn't have — focus falls back to first row. Low impact.
3. Options' openVanillaController never runs (OptionsSub always replaces it).
4. Several headers described old behavior (Notes save-question triggers, "Cancel or Discard" vs actual "Keep editing", nonexistent Accept, Space activation not handled, Players' Kick flow) — all fixed in comments.
## Batch 04 (ZeD_WorldWindow.lua) — resumed on Opus
1. LIKELY BUG: closeCardIfItemGone (~3262, content prerender) and _closeCardIfItemGone (~535, _focusRefresh, same frame) share and reset win._goneTick. The second always reaches 10 first and resets; it acts only with a controller — so "item gone -> card closes" never runs for mouse players.
2. POSSIBLE LOCK BYPASS: strip hold-A (onHoldActivate) has no locked check — opens a locked container as a column on Loot, or makes it the shown container elsewhere. Tap-A and mouse check the lock; toggleColumn doesn't.
3. Reload: `ZeD_WorldWindow = {}` wipes the module on reload; addTab-registered tabs (Admin) lost until their files reload.
4. Dead state: _tabUnder only set nil; _lastPinnedMCItem, _gpFocusedMCColIdx written never read (both windows); _extPending unused.
5. Overrides/ContextMenu.lua checks zone id worldLootMCColumns, which no longer exists (now worldMC1..N) — dead branch.
## Batch 26 (radio ops, reader, restock, sandbox, seats, server link, stats cards) — resumed on Opus
1. POSSIBLE PERMISSION GAP: ZeD_StatsCards.lua trait add/remove (and confirm steps) gate on the window's own check only, no AddXP capability — yet DO.addTrait/removeTrait call SyncXp. Header claimed AddXP gating; code doesn't.
2. ZeD_Restock.lua R.progress estimates walk time from x/y only, while routeTiles/route weight floor changes (6 / 20) — multi-floor time-left can undershoot the first estimate.
3. ZeD_SeatChooser.lua readSeats: doors get the per-car Y offset but not SeatOffsetX that seats get — doors may sit off the outline on cars with nonzero X offset (may copy vanilla).
## Batch 06 (containers, crafting) — resumed on Opus
1. CHECK: comments in ContainerControls, CraftingCore + 4 others say Kahlua has no next(), but ZeD_StepAside.lua:591 and WorldRoutes.lua:156 call next(). One side is wrong — if the comments are right, those two calls crash.
2. Dead: Registry.getMetaFor + Molecules.drawContextTargetCard (no callers; third confirmation), Registry.isPinned/togglePin never called.
3. CraftingCore "Recent" sort uses craft counts (same as Freq) — no timestamps stored; Sort: Recent == Freq order.
4. CraftingCore filterAndSort falls back to "ZeD_CraftCount" while everything else uses "ZeD_CraftCounts" (harmless today).
5. CC.startPickedCraft resets Craft-tab caches by hardcoded keys though pickIngredients can be on for other tabs.
6. Unused: CC.STRIP_H, CC.PANE_W_SOLO; journalKind field set, never read.
7. ContainerControls logs a gate's specs error on every row rebuild (unthrottled).
8. ContextMenuRegistry wraps onMouseMoveOutside + OnObjectHighlighted without keep-once (reload double-wrap family).
## Batch 21 (mail cards/store, main menu core) — resumed on Opus
1. ZeD_MailStore.lua: d.retN incremented by MS.returned, never read or saved — dead.
2. ZeD_MainMenu.lua ZeD_MMWindow:update: before/after theme check around ZeD_Window.update (saves ModOptions) is a leftover from the removed theme squares; likely never fires now.
3. MM.wheel bare wraps (no keep-once) in Credits, DescEdit, Join, JoinMore, Looks + others — the reload double-wrap family is widespread in main-menu files.
4. ZeD_MainMenuDescEdit.lua bodyH: `self.edit.font and T.fontF2 or T.fontF2` always T.fontF2 — probably meant the entry's own font.
5. SAFE_ANSWER rule copied into Host/Join/Looks didn't fit; in Looks the outfit-name question lands on Save (contradicts the rule) — comments fixed, behavior a design question.
## Batch 15 (radio, safe mode, settings, skills, station appliance) — resumed on Opus
1. LIKELY BUG: RadioTab.lua win._radioCDZones set only by the Premium chassis CD module, never cleared. Browsing Premium -> ValuTech (or CD module skipped for height) leaves live stale rects: clicks call _cdTransport (Start/StopPlayMedia) on the ValuTech radio; controller gets phantom cd:1..7 stops. Other chassis zones share the risk when a module is skipped.
2. RadioTab.lua _seekStep: channels are kHz (88000 = 88 MHz), but the >1,500,000 branch steps 100000 = 100 MHz — leftover from a Hz assumption.
3. ServerTab.lua reload-only: `local S = {}` new table per reload while the _zedOptions guard keeps the first panel wrapper — "See server options" then opens without the options card after a dev reload.
4. Dead: ZeD.Settings.cycleNext, ReadMarks.DOT_W/drawDot; SA.plateState "for QA probes" but no QA script calls it.
5. Settings vs SafeMode headers disagree on when ModOptions:load() runs relative to OnGameStart — unverified against vanilla.
## Batch 08 (health, identity, controller input layer) — resumed on Opus
1. ZeD_CharacterWindow.lua _buildIdentityFocusables: `focusables(win) or _buildIdentityGridScrollFocusable(win)` only falls back when the function is missing — an empty list is truthy, so a tab with no stops gets no pad scroll surface.
2. FocusManager debug overlay wraps ZeD_Window.render on each OnGameStart without keep-once (low risk).
3. Tokens.lua chordWindowMs has no reader; Tokens.lua triggerThresh comment still says abs(trigger) (code measures from rest).
4. Code strings still say "cone-nav" (F9 overlay text, load log) though SpatialNav replaced the cone.
5. Many FocusManager comments contradicted code (LB/RB absolute not swap; A-hold = padMark, X-hold = quick use; Y hold 400ms token) — all rewritten.
## Batch 03 (ZeD_CharacterWindow.lua) — resumed on Opus
1. openTab defined twice: Overrides/CharacterInfo.lua redefines ZeD_CharacterWindow.openTab (extra toggle arg) — this file's copy never runs.
2. Dead: togglePinSkill, _buildJournalDeleteFocusables never called; mcColumnEls computed/unused/always empty; `local alwaysRebuild = false` no-op; fields set never read (_mcPrevTab/_mcPrevDrawerMode/_mcPrevDrawerOpen, _journalSubTabZones, map toolbar fields, _containerSortByWT).
3. Low-confidence bug: clicking Loot while on Loot with columns open snaps to base width without exiting MC; width code then evicts columns that no longer fit.
4. Many comments contradicted code (hold A marks / hold X quick-use; equipment slot X opens context menu; ring order; tab strip 36 not 28; D-pad L/R toggles gone, A toggles) — rewritten. Old commented-out map code removed.
## Batch 28 (trade, watch, wheels, server files) — resumed on Opus
1. MP RISK: ZeD_WriteNoteAction.lua defines a timed action with complete() but lives in client/. Per CookingTab.lua's own note, a client-only action is unknown to the server and stops at once — writing a note in multiplayer may fail. Test on a server.
2. ZeD_ServerClaims.lua runsSafe takes no name, only returns the player's own safehouse — staff can't c_cancel someone else's safehouse (comment claimed they could). Possibly intended.
3. ZeD_ZoneList.lua is dead code (nothing creates one); _dockRect makes the whole dock clickable vs drawZoneRow saying only the button is; text-size change doesn't trigger height recalculation.
4. ZeD_Trade.lua: distance blocks the trade (and unblocks back in range), doesn't end it — comment fixed.
## Batch 16 (stations, thermal, two-way, watch plates, curtain, routes, action bar, admin) — resumed on Opus
1. WatchPlates.lua appears unused: nothing reads ZeD.WatchPlates (Watch draws from PhysPx.plates), nothing loads textures/ZeD/watch/*.png — yet both ship. Generator anchors2lua.pl would also overwrite the new header. Removal candidate (saves Workshop size).
2. Stations.lua: when a split-screen player slot disappears, the watchdog clears _bind[pn] without setUsingPlayer(nil) — station could read "In use" to everyone.
3. TestInventory.lua binds F6 with no debug check — repo/dev installs get the test window on F6 (Workshop staging excludes the file).
4. ThermalTab.lua: getThermalColor takes one arg but _drawBodyFigure passes (uiVal, viewIdx) — view index dropped.
5. StationPopout.lua zoomFor multiplies MAX_H_SHARE by another 0.6 (48% of screen, not 80%) — confirm intended.
6. StationMachine.lua Add only fills the first input resource while displayed capacity sums all inputs.
7. ZeD_Admin.lua dead: WATCH_IDLE_MS, M.seenAt, M.openInventory. WatchMini: glow field unread, bulbInk never set.
8. ZeDUI/tools/plates/render_watch_plates.sh hardcodes a personal machine path (cleanup/PII list).
## Batch 27 (survival guide, book, tab px, tickets) — resumed on Opus
1. CHECK BEFORE SHIP: author/publisher names "Stevie Whetstone" and "Doidbros and Buzzlord" appear in shipped guide strings (UI_ZeD_Guide_Book*/Copy*); title_spread.py calls them "the director's picks". If these are real handles, confirm they're fine to ship.
2. Thai line breaks: code still allows a break between "อี" and "ก" inside an over-long word — if the original bug was that break, it isn't fixed.
3. Book drawLine justification math is dead (extraN always 0; text is ragged-right).
4. Dead: TP._tones, W._rulesListRaw. TC.qaState is actually the general state accessor (used by AdminUsers, ExtrasCards) despite the QA name.
## Batch 25 (mod safety/scan, moodles, panel, plates, prompts, quick wheel) — resumed on Opus
1. LIKELY BUG: ZeD_Plate.lua local marquee() (~236) does math.floor(getTimestampMs()/320) % #loop — ~5e9 into %, the exact case the file's own clockStep comment says Kahlua gets wrong past 2^31. Radio-display scrolling text may scroll wrong. ZeD_RadioOps.marquee already uses clockStep — same fix applies.
2. ZeD_Moodles.lua: new/returning moodles start still and wiggle only on level change; if vanilla wiggles on appear, ZeD's bottom-row copy differs.
3. ZeD_QuickWheel.lua: Q.addGroups, Q.openGroup, local treat, MAX_ITEMS, BACK_TEX, centre — leftovers from the old D-pad Right wheel, no callers; Q.isWater exported unused.
4. ZeD_ModScan.lua: ws.fake checked but never set; MS.scanning() no callers. ZeD_QuickChords.lua Q.lastChord "for QA" read nowhere.
5. ZeD_MpLeftovers.lua: Sharing card button called "Done" in comments but shows getText("UI_btn_accept") — unverified naming mismatch.
## Batch 20 (form card, guide chapters, hair/beard, hint strip, journal, keyboard, lists, log, mail) — resumed on Opus
1. Stale QA script: ZeDUI/tools/qa/zedqa_hairbeard.lua calls HB.drawHead and HB.openPictures, which no longer exist.
2. ZeD_HintStrip.lua: the game's corner prompt hides whenever the strip is on for a controller player, even when the strip shows nothing (paused / menu holds the pad).
3. ZeD_JournalReaders.lua: J.refresh never called; rescan counter counts gather calls (~3/frame), so it rescans ~3x more often than "half a second".
4. Dead: FormCard U.IND; Mail fallbacks for S.onAgreed / Messages.notice almost never run now.
## Batch 29 (server log/mail/tickets, all shared) — resumed on Opus
1. BEHAVIOR CHECK: Adm.targetKind is also used on log-line targets (ZeD_ServerLog seenBy, ZeD_Log otherName) — a username shaped like an IP or a 17-digit Steam ID is treated as an address: hidden from staff without BanUnbanUser, no card offered.
2. Tokens.lua: OnZeDThemeChanged is triggered but never registered/listened — dead branch. Readerless tokens: focusRing*, prompt*, layout*, strip*, chordWindowMs, contextPadH/V/SafeM.
3. Generated files will lose new headers on regeneration unless templates update: ContextPxIcons.lua (ZeDUI/tools/wheelpx/export.py write_ctx_lua), plus DashPx, PhysPx, WatchPlates, MechFigs, PixelFonts noted earlier.
4. Dead: Cl.hoursLeft, O.ownerOf (outside its file).
5. Lg.stamp "UTC" label rests on OsLib reading UTC, unconfirmed in play.
6. PII (outside Lua): ZeDUI/tools/icon_matcher/02-build-catalog.ps1:1171 hardcodes a personal Windows user path.
