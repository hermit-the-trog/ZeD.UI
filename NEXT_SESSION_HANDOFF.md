Draft, Nov 8 2026: needs the director's check before it is trusted.

# Next session handoff (written Nov 8 2026)

Read this first, then STATE.md for what ships and PUNCH_LIST.md for every open item with its check. This replaces the Oct 23 and Oct 29 handoffs; their lessons that still hold are under "How to work".

## Where things stand (Nov 8 2026, morning)

- **Live:** 0.3.0-beta6a (live Nov 6 2026), Workshop item 3824968485, public [check that nothing went up since].
- **On main:** `42/mod.info` reads 0.3.0-beta7. Beta 7 was staged on Nov 7 and passed the release check on a true copy (16 of 16), but the director's evening plan was no upload Nov 7 and the next upload by noon Nov 8, "packed with as much as can be fixed" (VANILLA_WINDOWS_20261107.md). Since then two waves merged on top of beta 7:
  - wave 1 (5caf70f): copyright page, 32 more ads, rules enforcement, outside review fixes, respawn, devices, paper map, seven mods;
  - wave 2 (435e394): vanilla windows, trade and medic, admin, multiplayer, console, known issues, Wounds Overhaul, step aside, notes and mail, everyday leftovers.
- **QA state of the waves:** every part passes its sim and was reviewed; most were not opened in the game. Each has an in-game list, `CHECK_<part>_20261107.md` in `ZeDUI/qa/` [check which, if any, have been run].
- **Game:** stable 42.21 (the director switched on Nov 7). The 42.22 QA save stalls at the convert prompt; the Oct 27 42.21 copy loads.
- **In flight on Nov 8:** a comments-only pass on a branch (code byte-identical by its guard) and punch list 110's one-phrase rename on a branch [check both; other sessions are editing `42/`].

## Before the Nov 8 upload, in order

1. **Bump the version to 0.3.0-beta8.** The director settled it: work is on beta 8. `mod.info` still says 0.3.0-beta7, and the beta 7 change note and page become the beta 8 ones (beta 7 never went up).
2. **QA in the game on the waves**, Pass 1 of QA_CHECKLIST_BETA.md: the release check plus each `CHECK_*_20261107.md` list for what the build changed. Multiplayer parts need two players on a local server; QA built a two-player kit for merge 1 (commit 2619829) [check where it lives].
3. **Rewrite the change note and the page.** `tester_changenote_0.3.0-beta7.txt` covers only the Nov 7 morning fixes. Add waves 1 and 2, and take off the known issues they fixed (ZeD picks every way, split-screen dash miles, Death then Restart) once QA confirms them. Reword split-screen to "player 2 and later get the game's own windows". Both need the director's approval.
4. **Stage and check:** stage with the version, write the build's page text into `workshop.txt`, run the release check on the staged copy as the last thing before Upload (RELEASE_CHECKLIST.md). The director presses Upload.
5. **After the upload:** remove the staged Contents folder (it shadows the dev mod); tag the build; QA's gallery retakes from HANDOFF_gallery_beta7_20261107.md (36, 61, 46 with the copyright spread, about 15 new multiplayer captures; where the new spreads go is the director's call); the animated thumbnail (release checklist 16b) [check that step is still wanted].

## Open after the upload (PUNCH_LIST.md)

- **107 Split-screen:** ZeD's own windows for every local player, before Dec 1.
- **108:** a drawn controller in ZeD's pixel art for Options > Controls (design), in place of the plain box pad.
- **109:** what players alt-tab for: "what can I make with this" on the item card, what each skill level unlocks, moodle thresholds, hidden facts opened by a find (the TV schedule behind the TV magazine, by preset), pause when the window loses focus (if Lua can see it).
- **110:** one phrase, Immersive / Simple and Detailed / Simple, with the rows moved; then the gallery spreads that name the old words.
- **95:** the German half is still open.
- **92:** the dash lamps wired to Roadworthy's states once QA has Roadworthy running.
- **100:** the EquipPacket run with ZeD off, then the report to The Indie Stone if it stays.
- **93:** police radar, a future build; range and line of sight not ruled on.
- **Pass 2** of QA_CHECKLIST_BETA.md, the full checklist, before the Dec 1 release; its disclosure walk, button census and save-and-reload scripts were still to build [check].
- Many item headers lag their last paragraph (for example 86 says "staged, not installed" while beta 5 shipped the corkboard note). Trust the newest paragraph and the Confirmed list, and ask build to tidy the headers (item 75).

## Only the director can do these

From MORNING_BETA6_20261106.md [check which are done]:

- Accept the Terms of Service on the second game copy, so QA can test a plain player, invitations, wars and the "nearby" list.
- Host a server once: file a ticket, answer it, quit, host again and check it is still there.
- The wheels on a real pad: the first tap, walking with a wheel up, cruise control, the flick.
- Send the note to Hands-On Interactions' author and the bug report to The Indie Stone (both drafts).
- Approve the change note and page; press Upload.

## How to work

- **Build and QA are partners.** Every fix goes on PUNCH_LIST.md with its own check; nothing counts as done until QA has seen it in the game (BETA_DECISIONS.md). QA writes findings and never fixes them; the director decides.
- **Two QA passes:** after each build, only what changed plus the release check; before a release, the full checklist.
- **The checkout is shared:** never stash, check out, pull with autostash or touch other sessions' files. Other sessions may be editing `42/`.
- **QA setup:** 4K fullscreen at ZeD scale 1.75x on the stocked deep-run character; Deck 1280x800 only where an item asks. Small-screen shots only when needed.
- **One complete brief per agent and per game run.** Collect new feedback for the next run instead of messaging a running one, unless it is going wrong. A fresh agent per task.
- **Never kill a process the session did not start** (by PID only).
- **Shared game:** check the lock, never launch while the game runs, close it when done.
- **Captures:** wait until the windows are still; a "cut off" in a capture is a timing suspect first.
- **"The bridge never armed in game":** check the QA save's `mods.txt` lists ZeD_UI.
- **The Workshop upload window publishes:** QA never presses it. A real upload needs the director.
- **Gamepad rules** (the director): focus returns to its origin; directions match the screen; land on the primary action; common actions cost the fewest presses; the belt is never a trap.
- **Words:** American spelling; every new string in all 28 languages as labeled machine drafts; the i18n guard passes. Code comments follow COMMENT_VOICE.md.
