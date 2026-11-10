# Next session handoff (written Nov 9 2026, evening)

Read this first, then STATE.md for what ships and ZeDUI/PUNCH_LIST.md for every open item with its check. This replaces the Nov 8 draft written around beta 8. The beta 11 plan is in this file (there is no separate plan document): the corkboard five, the punch list numbers below, and what waits for the Nov 13 reset.

## Where things stand

- **Live:** 0.3.0-beta10, uploaded Nov 9 2026 10:22 am, Workshop item 3824968485, tag `v0.3.0-beta10`. Built for Project Zomboid 42.22.2, which became the public stable build on Nov 9 (it was 42.21).
- **On main:** `42/mod.info` reads 0.3.0-beta11. The beta 11 cycle opened Nov 9.
- **Nov 10:** the director runs a second account's cloud session on ZeD this week (it writes the code and sends test zips; the Mac tests them in a local session). The Nov 13 reset below is the first account's limit only. Test builds so far: `0.3.0-beta11-test1` and `-test2`; the in-game checks are in `ZeDUI/qa/CHECK_b11_test1_20261110.md`.
- **Week:** a light week until the usage reset on Friday Nov 13, 4 am. Bug reports and minor updates only; long runs go to one Sonnet helper; no full regression per change. Bigger work is queued for after the reset (below).
- **Repository history was rewritten on Nov 9** to take personal information out (the owner's user folder, personal email and full name, plus a browser-printed roadmap PDF). Every commit and tag hash before then changed: use tag names, never old hashes. Any older clone must be re-cloned or reset onto origin/main; never merge an old-history branch back in. GitHub's "Protect main" ruleset is Active (no force-push, no deleting main, no bypass); a future rewrite needs the director to disable it for that one push.

## Beta 11 plan

The corkboard note (MenuNote.lua, approved by the director): NOTE FIXES / LIST SLIDE / WIN SPOT / DECK FIXES / REPORTS.

| Punch list | What | Status |
|---|---|---|
| 114 | The main menu desk's sticky note can be dragged and closed (NOTE FIXES) | **QA ok** (Mac, mouse); pad, 1.75x, Light and High contrast still to run |
| 126 | The Character list slides sideways for a quarter second when its drawer folds at Deck size (LIST SLIDE; also in beta 9) | QA (Mac): the fold ok (4 px once); fixed a stale debt after another tab (to recheck: fold, other tab, close, inventory back to 279); the director kept the narrow-while-folded version |
| 125 | Closing a tab while its window is rolled puts the window back 4 px off at Deck size (WIN SPOT) | **QA ok** (Mac, 1280 x 800) |
| 127 | PZ Teal is the default accent for a fresh install; a saved accent (Orange included) stays. Test: delete ZeD's accent from the options file or use a clean cachedir, expect Teal | **QA ok** (Mac, test 2, main menu); a window and a balloon not looked at |
| 130 | The Player card keeps the old role after a role change on an offline account, so Ban never shows the protected-role message; update the cached row from the change; test an online moderator too | **QA ok offline both ways** (Mac, test 2); online needs a second client |
| 131 | The belt's balloon draws over the "Right Click More" hint strip | **QA ok** (Mac): Back, Secondary, Primary |
| 133 | The context strip scrolls one icon per arrow click and cuts the edge icon: a page of whole icons per click | **QA ok at 1x** (Mac, test 2, paged from the harness); a hand click on the arrow to recheck |
| 134 | Custom Map Labels: no error now and its labels reach the map store, but none draw on ZeD's map; investigate layer, Paper's label hiding, unexplored cells | **not ZeD's**: QA (Mac) saw no labels on the game's own map with ZeD off either; closed for ZeD |
| 137 | Responsive Context Menus support: ZeD's Strip and List take the mod's live rebuilds in place; keep-open honored; Escape closes | **done, QA 30/30 at 4K** (regression/2026-11-09_1732_mods_fullscreen4k.md); add the change-note line and the Compatibility thread's Supported entry at ship |
| 138 | Menu marks: blue and red tell paired actions apart (add/remove, on/off, either way), plus new Eat, Sneak and Safehouse icons, the centered 24 badge and the screwdriver handle up. Design handoff: `ZeDUI/HANDOFF_design_menu_marks_eat_20261109.md` (the director put the marks in beta 11, Nov 10) | built Nov 10 (cloud session, branch `claude/keen-meitner-optdjj`, PR #3), sim passes; waiting on the Mac's in-game check; the list menu uses each theme's own shades (director approved Nov 10) |
| 141 | The fill bars' cells spread evenly, no two more than a pixel apart (director) | built Nov 10, seg_bar_spread_sim; waiting on the Mac |
| 142 | Pasties: the sticky note becomes an app, up to 8 notes made from an icon, thrown away on close (director) | built Nov 10; QA Nov 10 found four, all fixed (desk_sim 194/0); recheck on the Mac |
| 143 | Status bars take five cells, rounded up; one status color rule for bars and their readings (director) | built Nov 10; waiting on the Mac |
| 144 | Status colors: Standard or Color blind (blue, yellow, orange), in ZeD setup's Look (director) | built Nov 10, status_colors_sim; waiting on the Mac |
| 145 | The portrait studio: a near full-height figure, pull-down backdrops, Take photo; pauses the game (director) | ruled Nov 10: single player only, a camera button on the ID photo; step 1 next |
| 146 | Fast looting: the game's tooltip at once on hover; a box from empty space selects rows (director) | built Nov 10, fast_loot_sim; waiting on the Mac |
| 139 | The pointer says what a click or a drop will do (an idea from the director, Nov 10; mockup in ZeDUI/mockups/zed_pointer_hint_v1) | parked by the director (research later); not in beta 11 |
| 132 | Strip submenus open on rest | closed: the director chose click only; a note that mentions rest names the List only |

DECK FIXES and REPORTS are the umbrella for 125, 126, 130, 131 and 133 plus any new player reports before the upload.

**At the start of the next cycle** (right after beta 11 uploads), QA's first message to Build is the version bump and the five corkboard lines for the director's approval.

## Ship steps for beta 11

1. Every open item above done, each with its sim and QA's in-game check (4K, and Deck where it is a small-screen item).
2. Change note and page from `ZeDUI/workshop/tester_description_0.3.0-beta11.bbcode`. The page keeps the design system link after the GitHub paragraph (checklist 16c). The page is near Steam's 8,000-character limit (about 7,910), so trim something when adding. The note must not claim every hover box is a balloon (the held item's box is still the game's until 135).
3. QA's release pass on the freeze (release check, regression with pinned-window timings, the beta's own checks), then the true staged check from its own cachedir at 4K and Deck.
4. Upload on the director's own go. The director pastes in Terminal 1: `& 'C:\steamcmd\steamcmd.exe' +login <the Steam login> +workshop_build_item <the upload .vdf> +quit`. Running SteamCMD signs the Steam app out of the community; restart Steam afterwards before using its Workshop page.
5. After the upload: remove the staged Contents, tag `v0.3.0-beta11`, add Responsive Context Menus to the Compatibility thread, then the gallery retake in PZ Teal (129).

## After the Nov 13 reset

- **129** The whole gallery retaken in PZ Teal with the new title bars (a pin at each end, no roll boxes), plus **128** the running head's middle dot changed to a hyphen, in one full re-render. Recapture list: `ZeDUI/workshop/gallery/B10_RECAPTURE.md`. Tier 2 retakes need the list view and the gallery look's window places and blur.
- **135** The held item's box over the belt becomes a ZeD balloon (the director: "Balloon it too"), carrying the lines tooltip mods add; QA tests with a tooltip mod or two.
- **136** The bigger Lua console (debug mode only; the server command list is in): verify the 42.22 hooks, then the log with filters, search and export; a multi-line scratchpad with history and snippets; autocomplete and a Help page; the command list. A mockup first for each phase. Source: `docs/reference/RESEARCH_console_tooling_20261108.md`.
- **The design system** (https://claude.ai/artifact/CYvs9hqtbx1153ZooxhHkz, linked on the Workshop page): fill in every component in one pass (Molecules 01-24, atoms, window chrome, context menus, wheel, item cards, belt, focus styles). When beta 11 ships, its accent default changes to PZ Teal too.
- Still open from before: 107 split-screen windows per player (before Dec 1), 108 a drawn controller, 109 what players alt-tab for, 121 run and sneak on one pad button (an idea).

## Only the director can do these

- Approve the beta 11 corkboard, change note and page; give the upload go; paste the SteamCMD line.
- Gallery images on the Workshop page: Steam's Add/Edit Images page in the Steam app takes one file at a time and showed no confirmation when QA tried; the director uploads them by hand (same file name replaces the old picture in place).
- GitHub Support was asked on Nov 9 (by the director) to purge the old pull request refs after the history rewrite; the reply goes to the director's email. Nothing to do unless they ask something.

## How to work

- **Build and QA are partners.** Every fix goes on the punch list with its own check; nothing counts as done until QA has seen it in the game. QA writes findings and never fixes game code; the director decides design.
- **No personal information in the repo:** write `%USERPROFILE%`, `$env:USERPROFILE`, `~` or script-relative paths; reports too. The shared `.git/hooks/pre-commit` refuses the user folder, the personal email or the full name (it also reads .pdf and .ai through pdftotext): fix the file, never `--no-verify`. `.claude/` is ignored.
- **The checkout is shared:** `git fetch` and `git merge --ff-only`; never stash, check out or reset; stage only your own files.
- **Shared game:** check `Zomboid/Lua/zedqa.lock`, never launch while the game runs, never merge into the checkout while the lock is busy, close the game when done.
- **Long runs:** Start-Process with output to a file and WaitForExit (never pipe a command that starts the game or a server, never `-Wait`), with `stall_watch.ps1` beside it. A performance result counts only with the windows pinned.
- **Test a staged build from its own cachedir** (`ZomboidStaged`); the staged Workshop Contents does not shadow the dev mod.
- **Never kill a process the session did not start** (by PID only).
- **Words:** American spelling, no Oxford comma, never a middle dot; every new string in all 28 languages as labeled machine drafts. Code comments follow COMMENT_VOICE.md.
- **Gamepad rules** (the director): focus returns to its origin; directions match the screen; land on the primary action; common actions cost the fewest presses; the belt is never a trap.
