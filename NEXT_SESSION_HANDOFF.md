# Next session handoff (written Nov 11 2026, after beta 11 shipped; refreshed late Nov 11)

Read this first, then STATE.md for what ships and ZeDUI/PUNCH_LIST.md for every open item with its check. The beta 12 plan is in this file (there is no separate plan document).

## Handoff to the other account (Nov 12 2026, midday)

The director moved Build to their other Claude account (this one at 99%). Same machine, same checkout; QA ZeD-GUI is its own session.

**Not merged yet (do this first):** console Phases 3 and 4 sit on local branch `worktree-agent-a0ec8d3558eb05602` (1af9bfbe Phase 3 autocomplete + Help page, 58b4a064 Phase 4 Commands page). All sims pass on the branch (console_complete 296, console_commands 278, debug_console 893, console_log 257, console_scratch 298). Merge only in one command gated on the lock: `[ "$(cat ../../Lua/zedqa.lock)" = free ] && ! tasklist //FI "IMAGENAME eq ProjectZomboid64.exe" | grep -qi zomboid && git merge --no-edit worktree-agent-a0ec8d3558eb05602`; UI.json / mt_notes / UI_ZeD.context.md conflicts are add/add: keep both sides (JSON needs the comma), then set UI_ZeD.context.md's "Total keys" line to its count of `| \`` rows; check all 28 UI.json parse; rerun the five console sims, kahlua_guard.py, i18n_guard.py; push.

**Where beta 12 stands:**
- Console (136): Phases 1-2 on main (f8439e5b), 3-4 on the branch above. Phase 0 probe (con0) run 1 in -debug: loadstring works, reflection works (getNumClassFunctions etc.; getMethodName is not a global), SendCommandToServer exists (single player gives no reply), console.txt unreadable, .log export works. Runs 2-3 (normal launch, reload) were in progress at QA. Still to check in game: conlog, console_scratch, console_complete, console_commands (all -debug single player, ZEDQA_NOSTEAM=1); the server send by hand (steps in zedqa_console_commands.lua's header). Director rulings in PUNCH_LIST 136.
- Next after the console, by the director: Summer Car support (Workshop 3790160840, reported by Hershtak): ZeD's Overrides/VehicleMechanics.lua never shows ISVehicleMechanics (the Vehicle tab instead), so the mod's engine-components window that lives beside it closes at once. QA is to download the mod (SteamCMD knocks Steam offline: after the console runs) and send the mod's hook (file and function). Fix choice: a ModSupport file keeping its window beside the Vehicle tab, or the game's mechanics window when such a mod is on.
- Gallery beta 12: complete, 80 pictures in ZeDUI/workshop/gallery/upload_b12 (0ed90541), built by make_b12.py from plan v2 (PLAN_ALTERNATE_20261111.md, director-approved). Uploads with beta 12 on the director's go; Steam's image page appends, so clear and re-upload in order. Angel's closer has two small leftovers (time controls top right, three moodles at the right edge): director not asked yet.
- Animals (169): round three on main (296cfbc7) plus the milk/shear alert fix (8ac9609d); QA's rerun after the console runs (zedqa_animals_restore.lua first).
- Merged Nov 11-12 and passed in game: footer picked count, health status pixel + "Blink the low-health pixel" option, single List/Grid view button, search magnifier, tags as square + word, LMB/RMB hints, Journal tags, saved window positions, tab fill, the director's picture-review fixes.
- Open questions to bring the director (multiple choice): which headline item after the console and Summer Car (split-screen 107 with a Dec 1 target, run+sneak 121, drawn controller 108); sorting the Nov 11 audit's not-built list (ZeDUI/qa/AUDIT_DESIGN_AND_COVERAGE_20261111.md) into beta 12 / after release / drop.

**QA's handoff (QA ZeD-GUI moves to the other account too, Nov 12 midday):**
- **Check first, before any launch:**
  - The old account's QA helper may have been cut off mid-run. Make sure ProjectZomboid64 isn't running; if it is, ask the director to close it.
  - Make sure `Zomboid/Lua/zedqa.lock` reads free.
  - Make sure options.ini is fullScreen=true, 3840x2160, fontSize=2.
  - Make sure ModOptions.ini has see-through 90 and hint strip Always.
  - Make sure `Zomboid/Lua/zedqa.autoload` reads 0.
  - Delete the con0 drop-in `42/media/lua/client/zzz_zedqa_con0.lua` if it's still there (untracked; it must never be committed).
- **con0 results:**
  - Run 1 (-debug) is done. All lines went to Build; the report is ZeDUI/qa/QA_con0_run1_20261112.md (or run1_report.md if the helper didn't rename it).
  - Its FAIL is only the probe's four deliberate exceptions (chunks `boom`, `con0_runtime`): widen console_probe.txt's expect=.
  - Runs 2 and 3 (normal launch, then the reload in -debug, per ZeDUI/qa/CHECK_pl136_phase0.md) were running. If QA_con0_normal_20261112.txt and QA_con0_debug_reload_20261112.txt aren't in ZeDUI/qa, redo them. The answer Build wants most is `q1.reload`.
- **Queue, in order:**
  1. con0 runs 2-3, if missing.
  2. conlog then console_scratch (-debug, ZEDQA_NOSTEAM=1). The four things only the game shows: Kahlua's error wording, whether print joins its arguments with a tab (otherwise rows show twice), Shift+Enter by hand in the scratchpad, the window at Deck size.
  3. console_complete and console_commands, once Build merges Phases 3-4.
  4. Summer Car: download 3790160840 and send Build the hook.
  5. The Animals rerun: zedqa_animals_restore first, then zedqa_animals_quick + aq2 at 4K, Deck and German.
  6. The Mods Files tab error cards (Bandits2 + BanditsWeekOne).
  7. The split-screen probe: the director plugs in a pad and presses A.
  8. The beta 12 gallery upload, on the director's go.
- **QA rules worth repeating:**
  - Every helper brief that runs zedqa_run.ps1 must set `$env:ZEDQA_NOSTEAM = "1"`. Without it the game sits at the main menu with no bridge, which looks like a code bug. The tell is "zomboid.steam=1" in the DebugLog.
  - If the director is using the PC, ask before taking the screen (fullscreen runs stall behind other windows).
  - Background waits get a time limit. On Nov 11, 14 stuck waits ran for 13 hours.
  - Kills by PID only, for processes QA started; the safety check blocks killing some.

**Habits that bit this cycle:** never merge into 42/ while the lock reads busy (a finished background wait is stale: gate in the same command); QA's runs need ZEDQA_NOSTEAM=1 or Steam's beta 11 copy shadows the dev mod; Bash heredocs eat double backslashes (write scripts with the Write tool).

## Where things stand

- **Live:** 0.3.0-beta11, uploaded Nov 11 2026 12:27 pm, Workshop item 3824968485, tag `v0.3.0-beta11` (on 3de432df). Built for Project Zomboid 42.22.2, the public stable build.
- **Beta 11 held:** fast looting and the loot card (135, 146), the portrait studio (145), Pasties (142), the COND / AMT column (152), status colors and Color blind (143, 144), menu marks (138), the Deck fixes (125, 126, 131, 133), the Player card role (130), Responsive Context Menus support (137), PZ Teal as the default accent for new installs (127), and the director's Nov 10 notes (155 to 164: belt hand icons, the Loot drawer folding, "Nothing here.", lowercase Fira Mono balloons, Dark's text steps, a stack's bar at its emptiest, the notebook's grey box). Its release pass: release check 2/2, regression 97/101 with the 4 WARNs proven to be stale scripts (sg, wi, tw, hln; fixed in d7ef3b41), perf even or better than beta 10 with pinned windows, the true staged check at 4K and Deck clean apart from b11n's own timing (punch list 165).
- **On main:** `42/mod.info` reads 0.3.0-beta12. The beta 12 cycle opened Nov 11 (b3e58284).
- **Accounts:** the director ran a second account's cloud session on ZeD Nov 10 and 11 (beta 11's code, PRs #3 to #5, all merged). Work moved back to this account Nov 11. The light week was lifted Nov 11 (the director: "forget the Friday thing"; a spare reset or the other account covers usage): beta 12's bigger items go ahead now.
- **Repository history was rewritten on Nov 9** to take personal information out (the owner's user folder, personal email and full name, plus a browser-printed roadmap PDF). Every commit and tag hash before then changed: use tag names, never old hashes. Any older clone must be re-cloned or reset onto origin/main; never merge an old-history branch back in. GitHub's "Protect main" ruleset is Active (no force-push, no deleting main, no bypass); a future rewrite needs the director to disable it for that one push. Old pull request #2 (the Nov 8 tools change) is still open and superseded; leave it until GitHub Support answers the purge request.

## Beta 12 plan

The corkboard note (MenuNote.lua, approved by the director Nov 11): CONSOLE / SPLIT VIEW / PAD MAP / RUN+SNEAK / BUG FIXES.

| Punch list | What | Status |
|---|---|---|
| 136 | The bigger Lua console (debug mode only; the server command list is in). Phase 0: verify on 42.22 (getLuaDebuggerErrors in and out of debug and on reload, loadstring, DebugLog routing, a chat-path send, reflection helpers, console.txt reach). Phase 1: one log of output and F11 errors, filters by mod, file and kind, search, Export .log. Later phases: multi-line scratchpad with history and snippets, autocomplete and Help, the command list. A mockup first for each phase. Source: `docs/reference/RESEARCH_console_tooling_20261108.md` | open (CONSOLE) |
| 107 | Split-screen: ZeD's own windows for every local player (the director: before Dec 1) | open (SPLIT VIEW) |
| 108 | A drawn controller for Options > Controls | open (PAD MAP) |
| 121 | Controller: run and sneak on one button, by how far the stick is pushed (modeled on a Skyrim mod; see the punch list entry) | open (RUN+SNEAK) |
| 166-172 | Drag chip cascade (166), Fishing tab and trophy wall (167), inventory Filter (168), Animals quick actions and Feed picker (169), Mods Files tab (170), Skills/Equipment Find (171), SRJ Transcribe (172) | built and merged Nov 11. QA PASS in game: 167, 168, 171, 172. 169: three fix rounds, round three on main (296cfbc7), QA rerun pending (restore script first). 170: main menu PASS; in-game error cards need Bandits2 + BanditsWeekOne on |
| Nov 11 extras | Journal entry tags; saved window positions; tab fill (Health, Thermal, Radios, Notebooks, Loadouts); the director's 50-picture review fixes; LMB/RMB in short hints; tags as square + word everywhere (Atoms.drawTag); search magnifier; one List/Grid view button; footer "3 of 48 picked / 4.2 kg"; health status pixel by the name + "Blink the low-health pixel" option | all merged; QA PASS in game except what is noted in the punch list |
| 165 | b11n's test timing: wait for the Character window to show before 156's tab-mode check; 155's off-ring peek read too early; 162's list reveal doesn't scroll (scroll the list explicitly) | open, test side (BUG FIXES) |
| 139 | The pointer says what a click or a drop will do | parked by the director (research later) |

BUG FIXES is the umbrella for 165 and any player reports before the upload.

**Next (late Nov 11):** the director asked which headline item to start next (split-screen, console, run and sneak, drawn controller) and went to bed before answering: ask again first thing (multiple choice). Gallery beta 12: plan v2 approved (`ZeDUI/workshop/gallery/PLAN_ALTERNATE_20261111.md`), `make_b12.py` builds `upload_b12/` (76 of 80 on main 68b54e5a); missing QA breaks: cin_ang_open, cin_ang_close (Light + Blue, new script), cin_mck_kitchen, cin_lau_lake (Light + Teal). The live beta 11 fishing break (40b) is off Laura's look until beta 12 replaces it.


**Not mod changes, also after the reset:**
- **129 and 128** The whole gallery retaken in PZ Teal by QA from `ZeDUI/workshop/gallery/B11_RECAPTURE.md` (19px game font, pinned by `zedqa_run.ps1`; the vanilla four at 19px with ZeD off; hero shots with one source open), then one full re-render of all pictures (the running head's hyphen is already in the spreads).
- **The design system** (https://claude.ai/artifact/CYvs9hqtbx1153ZooxhHkz, linked on the Workshop page): fill in every component in one pass (Molecules 01-24, atoms, window chrome, context menus, wheel, item cards, belt, focus styles), with PZ Teal as the default accent.
- **Compatibility thread:** Responsive Context Menus under Supported (QA is asking the director).
- Still open from before: 109 what players alt-tab for.

## Ship steps for beta 12

1. Every item above done, each with its sim and QA's in-game check (4K, and Deck where it is a small-screen item).
2. Change note `ZeDUI/workshop/tester_changenote_0.3.0-beta12.txt` and page `tester_description_0.3.0-beta12.bbcode`, started from beta 11's. The page keeps the design system link after the GitHub paragraph (checklist 16c) and From the Hermit at the very end with the director's closing line. Beta 11's page is 7,776 + 58 of 8,000 characters, so trim something when adding.
3. QA's release pass on the freeze (release check, regression with pinned-window timings, the beta's own checks), then the true staged check from its own cachedir (`ZomboidStaged`) at 4K and Deck.
4. Upload on the director's own go. The director pastes in Terminal 1: `& 'C:\steamcmd\steamcmd.exe' +login <the Steam login> +workshop_build_item <the upload .vdf> +quit`. Running SteamCMD signs the Steam app out of the community; restart Steam afterwards before using its Workshop page.
5. After the upload: remove the staged Contents, tag `v0.3.0-beta12`, and start the next cycle (QA's first message to Build: the version bump and five corkboard lines for the director's approval).

## Only the director can do these

- Approve the corkboard, change note and page; give the upload go; paste the SteamCMD line.
- Gallery images on the Workshop page: Steam's Add/Edit Images page takes one file at a time; the director uploads them by hand (the same file name replaces the old picture in place).
- GitHub Support was asked on Nov 9 (by the director) to purge the old pull request refs after the history rewrite; the reply goes to the director's email. Nothing to do unless they ask something.

## How to work

- **Build and QA are partners.** Every fix goes on the punch list with its own check; nothing counts as done until QA has seen it in the game. QA writes findings and never fixes game code; the director decides design.
- **Only one session asks the director a given question.** If QA is asking, Build doesn't (and the other way round); a skipped duplicate is not "no preference".
- **No personal information in the repo:** write `%USERPROFILE%`, `$env:USERPROFILE`, `~` or script-relative paths; reports too. The shared `.git/hooks/pre-commit` refuses the user folder, the personal email or the full name (it also reads .pdf and .ai through pdftotext): fix the file, never `--no-verify`. `.claude/` is ignored. A cloud session or another PC has no guard: check by hand before pushing there.
- **The checkout is shared:** `git fetch` and `git merge --ff-only`; never stash, check out or reset; stage only your own files.
- **Shared game:** check `Zomboid/Lua/zedqa.lock`, never launch while the game runs, never merge into the checkout while the lock is busy, close the game when done.
- **Long runs:** Start-Process with output to a file and WaitForExit (never pipe a command that starts the game or a server, never `-Wait`), with `stall_watch.ps1` beside it. A performance result counts only with the windows pinned. Waits in QA scripts run on real time, not frame counts (the Deck draws faster).
- **Test a staged build from its own cachedir** (`ZomboidStaged`); the staged Workshop Contents does not shadow the dev mod.
- **Never kill a process the session did not start** (by PID only).
- **Words:** American spelling, no Oxford comma, never a middle dot; every new string in all 28 languages as labeled machine drafts. `AR` is Argentine Spanish (the game's "Español (Argentina)"), never Arabic: write its new strings in Spanish with voseo (podés, Elegí), as `ZeDUI/i18n/mt_notes/AR.txt` describes; `mt.py check` fails Arabic letters in it. Code comments follow COMMENT_VOICE.md.
- **Gamepad rules** (the director): focus returns to its origin; directions match the screen; land on the primary action; common actions cost the fewest presses; the belt is never a trap.
