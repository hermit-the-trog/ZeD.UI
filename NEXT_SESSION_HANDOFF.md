# Next session handoff (written Nov 11 2026, after beta 11 shipped)

Read this first, then STATE.md for what ships and ZeDUI/PUNCH_LIST.md for every open item with its check. The beta 12 plan is in this file (there is no separate plan document).

## Where things stand

- **Live:** 0.3.0-beta11, uploaded Nov 11 2026 12:27 pm, Workshop item 3824968485, tag `v0.3.0-beta11` (on 3de432df). Built for Project Zomboid 42.22.2, the public stable build.
- **Beta 11 held:** fast looting and the loot card (135, 146), the portrait studio (145), Pasties (142), the COND / AMT column (152), status colors and Color blind (143, 144), menu marks (138), the Deck fixes (125, 126, 131, 133), the Player card role (130), Responsive Context Menus support (137), PZ Teal as the default accent for new installs (127), and the director's Nov 10 notes (155 to 164: belt hand icons, the Loot drawer folding, "Nothing here.", lowercase Fira Mono balloons, Dark's text steps, a stack's bar at its emptiest, the notebook's grey box). Its release pass: release check 2/2, regression 97/101 with the 4 WARNs proven to be stale scripts (sg, wi, tw, hln; fixed in d7ef3b41), perf even or better than beta 10 with pinned windows, the true staged check at 4K and Deck clean apart from b11n's own timing (punch list 165).
- **On main:** `42/mod.info` reads 0.3.0-beta12. The beta 12 cycle opened Nov 11 (b3e58284).
- **Accounts:** the director ran a second account's cloud session on ZeD Nov 10 and 11 (beta 11's code, PRs #3 to #5, all merged). Work moved back to this account Nov 11. The light week ends with this account's usage reset on Friday Nov 13, 4 am: until then bug fixes and small updates only; after it, beta 12's bigger items.
- **Repository history was rewritten on Nov 9** to take personal information out (the owner's user folder, personal email and full name, plus a browser-printed roadmap PDF). Every commit and tag hash before then changed: use tag names, never old hashes. Any older clone must be re-cloned or reset onto origin/main; never merge an old-history branch back in. GitHub's "Protect main" ruleset is Active (no force-push, no deleting main, no bypass); a future rewrite needs the director to disable it for that one push. Old pull request #2 (the Nov 8 tools change) is still open and superseded; leave it until GitHub Support answers the purge request.

## Beta 12 plan

The corkboard note (MenuNote.lua, approved by the director Nov 11): CONSOLE / SPLIT VIEW / PAD MAP / RUN+SNEAK / BUG FIXES.

| Punch list | What | Status |
|---|---|---|
| 136 | The bigger Lua console (debug mode only; the server command list is in). Phase 0: verify on 42.22 (getLuaDebuggerErrors in and out of debug and on reload, loadstring, DebugLog routing, a chat-path send, reflection helpers, console.txt reach). Phase 1: one log of output and F11 errors, filters by mod, file and kind, search, Export .log. Later phases: multi-line scratchpad with history and snippets, autocomplete and Help, the command list. A mockup first for each phase. Source: `docs/reference/RESEARCH_console_tooling_20261108.md` | open (CONSOLE) |
| 107 | Split-screen: ZeD's own windows for every local player (the director: before Dec 1) | open (SPLIT VIEW) |
| 108 | A drawn controller for Options > Controls | open (PAD MAP) |
| 121 | Controller: run and sneak on one button, by how far the stick is pushed (modeled on a Skyrim mod; see the punch list entry) | open (RUN+SNEAK) |
| 167 | The World window's Fishing tab with the trophy wall (director-approved mockup `ZeDUI/mockups/zed_fishing_tab_v2.html`; rulings in the punch list entry) | approved, build after the reset |
| 165 | b11n's test timing: wait for the Character window to show before 156's tab-mode check; 155's off-ring peek read too early; 162's list reveal doesn't scroll (scroll the list explicitly) | open, test side (BUG FIXES) |
| 139 | The pointer says what a click or a drop will do | parked by the director (research later) |

BUG FIXES is the umbrella for 165 and any player reports before the upload.

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
