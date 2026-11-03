# Handoff from Code to Cowork: the road to the beta (Nov 2 2026, evening)

The director, Nov 2 2026: "the next build is going to be the beta. So we're moving out a test into beta. And with all
of these fixes, confirmations, checks, tests, decisions that need to be made, after all this is done, that's our beta
build." The director wants the decisions talked through here in Cowork, then a handoff back to the build session in
Claude Code with the answers and instructions.

**What this Cowork conversation is for:** go through the questions in section 3 with the director, one or a few at a
time, and agree what "beta" means (section 4). Then write the handback (section 5). No code here.

## 1. Who does what, and the director's working rules

- **The director (Hermit)** is ZeD-GUI's design lead and not a coder. They decide design and scope only. Claude makes
  every technical call itself and never asks the director a technical question.
- **The build session (Claude Code, "ZeD build")** writes the code.
- **The QA session (Claude Code, "QA ZeD-GUI")** runs every check in the game and records results in
  `ZeDUI/PUNCH_LIST.md`. That file is the shared ledger: findings, causes, options, the director's choice, then
  fixed and confirmed.
- **Writing to the director:**
  - Plain language, prose first.
  - No spec codes, punch list numbers, commit hashes or session numbers.
  - No Oxford comma.
  - Never the middle dot; use " | ".
  - Honest recommendations, findings and options before fixes.
  - Copy in a tech-manual tone, never marketing.
- **Standing product rules** that bear on these questions:
  - ZeD supports the game as it is built: no work for cheat mods, spawners, gameplay-breaking or Java mods.
  - Keep vanilla's stakes.
  - The look is a 1993 flashback, with no web tropes.
  - Every added feature can be turned off.
  - Handheld screens are a release priority: the Steam Deck at 1280x800 and 720p.

## 2. Where things stand

- **t16:**
  - It is staged and passed every pre-upload check. The full 4K run passed 97 of 99, and the short Deck and 720p
    runs passed 4 of 5 each.
  - The only warnings are two known slips in the tests, not the mod.
  - The version reads 0.2.0-t16 in the mod list, and the page text is the t16 copy.
  - The director's new name and look wording is in the mod description, the README, the Workshop text and the
    GitHub blurb.
  - **Not uploaded yet**: the director presses Upload. After it, the build session tags the build, backs it up to
    D:, pushes and removes the staged copy.
- **The Compatibility thread** was posted today, with Immersive Moodles listed as Supported from t16.
- **The punch list's state, item by item:** see section 6, written from a full audit tonight.

## 3. Questions for the director

Each question has its options and Claude's recommendation. The director's answer can be one of the options, their own
idea, "you decide" (the build session picks) or "after the beta".

**3.1 UI scale on the Steam Deck and at 720p.**
On small screens the UI scale stops at the largest step where a window still fits beside the other. On the Deck and
at 720p that is 0.75, even with Normal text, so 1x can't be picked there.
- (a) Keep the cap. Large text is the way to bigger reading on a small screen; every window stays usable.
- (b) Allow 1x there. The windows then overlap or one covers the other, and some tabs' content cuts.
- (c) Allow 1x only when one window is open at a time.

**Recommendation: (a).** QA's small-screen passes were all built and checked at 0.75 with Normal and Large text.

**3.2 Dimmed rows in ZeD setup.**
A row that does nothing right now, like Restock while Loadouts is off, is dimmed and no longer lights up under the
pointer. Should the game's own greyed-out settings, the ones that do nothing while ZeD runs, also lose their
highlight? **Recommendation: yes,** so every dimmed row behaves the same.

**3.3 Simple cards for machines.**
On Oct 30 the director chose one switch in ZeD setup: device faces by default, or simple cards for radios, TVs,
walkie-talkies, ham sets, ovens, microwaves, the fryer, the grill and generators. Only the radio's simple card exists.
This is the largest piece of new work left.
- (a) In the beta. The build session brings the simple cards' layout rules for approval first.
- (b) After the beta.

**Recommendation: (a)**, because a beta should be the point where features stop being added.

**3.4 The Vehicle tab's summary on small screens.**
Beside the car figure, Type, Distance and Key show only their labels, because the values have no room.
- (a) Each value goes under its label.
- (b) The summary moves under the car figure, at full width.
- (c) Leave it as it is.

**Recommendation: (a).**

**3.5 Translations.**
Players ask for languages the director can't read; the most recent is a Turkish player.
- (a) Ask players to volunteer translations only.
- (b) Publish AI-drafted translations marked as drafts for players to check and correct. Start with Turkish and
  Simplified Chinese, the two asked for, and see whether checkers turn up before drafting the other 26.
- (c) After the beta.

**Recommendation: (b) as a small pilot.** The reply to the Turkish player waits on this answer.

**3.6 Three other mods** (QA's round-five notes).
- **Ente's Auto Sorter** puts its button bar over ZeD's belt.
  - (a) The belt moves up for it.
  - (b) The Compatibility thread notes it ("drag its bar aside").

  **Recommendation: (b).** Moving ZeD's belt for one mod's bar is special-casing.
- **This Is Your Life** (14,000+ subscribers) changes the game's character creator, which ZeD's Looks screen
  replaces, so it does not work with ZeD.
  - (a) The build session reads what it adds, then the director decides.
  - (b) Leave it listed as not working.

  **Recommendation: (a)**, a short read only.
- **The context menu icon mods** draw icons that never show in ZeD's menus, because ZeD draws its own.
  - (a) ZeD shows a mod's icon where ZeD has none for that action.
  - (b) Leave it.

  **Recommendation: (b).** ZeD's icons are part of its look.

**3.7 ZeD's version in its About screen.**
About shows only the game's build. ZeD's own version shows only in the Mods screen, so a player reporting a bug has to
find it there. **Recommendation: yes,** add ZeD's version to About.

**3.8 The controller map.**
The controller's quick wheel has a "Controller map" entry that says "Coming later."
- (a) Build it: one page showing what each button does in ZeD.
- (b) Remove the entry for the beta.

**Recommendation: (a).** The controller is a headline feature, and a beta shouldn't show placeholders.

**3.9 The Hair and beard error with one mod set.**
With eight particular mods on together, a haircut or beard trim started from ZeD's Hair and beard fails with a game
error. ZeD alone works. It is parked until after t16, and the cause sits in how one of those mods changes the game's
actions.
- (a) The beta waits until it's solved.
- (b) The beta can ship with it listed as a known issue if it isn't solved in time.

**Recommendation: (b).** The build session keeps working on it either way.

**3.10 The beta itself.**
- **Name:** for example 0.3.0-beta1, or 1.0.0-beta1.
  **Recommendation: 0.3.0-beta1.** 1.0 is the release.
- **Where it goes:**
  - (a) The same Workshop item, renamed from "ZeD-GUI [TEST BUILD]" to "ZeD-GUI [BETA]", which keeps every
    subscriber.
  - (b) A new item.

  Separately, is it public or unlisted? **Recommendation: (a),** with going public as the director's call on the day.
- **What must be true before it is called beta:** see section 4.

**3.11 Three small confirmations.** Each one shipped or happened already; a yes keeps it as it is.
- Oct 30's band work made four calls without the director's sign-off:
  - Craft's Show is a pop-up (Ready, Known, All).
  - The Loadouts band reads "Save loadout" and "Save outfit".
  - The number beside Craft's amount is gone.
  - An exercise you can't do stays in the list, with Start greyed and the reason shown.
- The walkie-talkie and ham radio faces keep their printed foot: the brand and "2-WAY PORTABLE".
- The About paragraph in ZeD's desk menu was changed on Nov 1, not by the build session. Was that the director's
  edit, and is it kept?

**3.12 Replies waiting to be posted** (after the t16 upload; the director approves each one before it is posted).
- **Kable** (the Sandbox page list): "Thanks for the report and the picture. Confirmed: with a long mod list the
  Sandbox page list ran past the window and the wheel did not scroll it. Fixed in 0.2.0-t16: the list scrolls with the
  wheel and follows the controller's page."
- **LZV-R5** (asked for a modular ZeD): "Thanks, and good idea. In 0.2.0-t16, Safe mode in ZeD setup can hand one
  screen at a time back to the game: the inventory windows, the belt, the watch, the dashboard, the moodles, the quick
  wheels and character info, each with its own switch, the rest of ZeD-GUI kept. And if it was the belt's look you
  wanted gone, the HUD settings now have a Simple belt: the same slots with no strap or buckle."
- **Turk** (asked for Turkish): waits on question 3.5.
- **The Discord note** for t16: the change note, ask first.

## 4. What "beta" means: Claude's proposed definition (for the director to agree or change)

1. **Every design question above is answered.** Every item the director said yes to is built and confirmed in the
   game by QA.
2. **No fix waits on a check.** Everything marked fixed or built on the punch list is confirmed by QA, or reopened
   and fixed again.
3. **The old QA checklist is done.** It was set up Oct 30 and only partly covered since:
   - disclosures
   - every button
   - controller only
   - keyboard
   - save and reload
   - themes
   - edge cases
   - resizing
   - console errors
   - speed
   - other mods
4. **Today's test gaps are closed:**
   - The game's own inventory opened by its key while Safe mode has the windows.
   - The Simple belt with other slot counts, a real mouse drag and the controller.
   - The load order tools by hand, and with 1,500 mods.
   - The marks with a container column.
5. **The five-minute release check exists and passes**: right-click opens the menu, both windows open, an item moves,
   the controller works, the watch reads the time. Staging sets the version and writes the build's page text by
   itself, so today's version slip can't recur.
6. **No placeholders or "coming later" anywhere.**
7. **Three runs pass with no new faults:**
   - a full run at 4K
   - a full run on the Deck
   - a short run at 720p
8. **The open loose ends from older notes are checked and fixed or closed** (section 6).

## 5. The handback to Code

When the conversation is done, write `ZeDUI/BETA_DECISIONS.md` in the repo
(`C:\Users\you\Zomboid\mods\ZeD-UI`). It needs:
- each question's answer, in the director's words where possible, with the date
- the agreed beta definition
- anything the director added
- which replies may be posted

Then commit only that file and push. The checkout is shared with the build and QA sessions, so never stash, check
out, pull with autostash or touch other files.

The director then tells the build session "read the beta decisions." The build session turns them into punch list
items, works through the build side, and hands QA its checks.

## 6. Status of every punch list item (audit, Nov 2 2026 evening)

Item numbers are kept here for the build and QA sessions. Don't read them out to the director.

### Buttoned up: confirmed in the game by QA

Over 40 items and parts are confirmed:
- the radio drawer and plates
- the additions presets and Restock dimming
- the header and footer bands on every tab
- the segmented bars
- the TV channels and the laundry cards
- every break-it fix from Oct 31: tabs in reach, pop-up boxes, window sizes, the rename box, the flyer reader, the
  window title, TV snow, small-screen overlaps, the ID card, the Maps header and the Furniture strip
- the UI scale cap and Immersive Searching
- the Mod Folders and separators and load order tools (scripted checks), and the Chinese font
- the t15 fixes, the compass letter, controller multi-select, Reset windows and the saved window place
- the main menu on the Deck and at 720p
- the Build and Craft preview card and the notebook paper
- the Sandbox page list, Immersive Moodles, the per-screen Safe mode switches and the Simple belt

The 720p vehicle test rig is fixed too.

### Built but never checked in the game (QA)

- **1** Right-click on an inventory row. The fix landed in t13 and was never checked by hand. The release check would
  cover it.
- **7** The window box and close box no longer flicker on hover.
- **6** The item card's back key (now an X).
- **26** A laundry card's first opening. The face now waits for its picture; the wait was never timed by eye.
- **28** The Craft amount in one box on the smallest screens (13d56ca). Re-check with a recipe whose most is 1 and
  one of 10 or more.
- **29** Equip names at the half card (c88ee8d).
- **35** The Skills grid goes to one column when narrow (e33e972). Also check that a wide card keeps two columns.
- **36** The portrait ID card (4c58d89). QA captures a screenshot for the director before it ships.
- **36** The Maps header keeps the ink in use when stamps fold (5d972bb). Only the fold arrow was checked.
- **38** Controller stops while a tab drawer fills the window. Re-run the probe at 720 2x Large.
- **42** The main menu's leave-with-changes question and the pad A on the Workshop form. mmq was not re-run.
- **43** A forage find staged east of the character reads E. The probe passed; a real find was not staged.

### Waiting on the director (section 3)

- The UI scale at 720p and on the Deck (3.1).
- Dimmed rows (3.2).
- Simple machine cards (3.3).
- The Vehicle summary (3.4).
- Translations (3.5).
- The three other mods (3.6).
- ZeD's version in About (3.7).
- The controller map (3.8).
- The Hair and beard error (3.9).
- The beta's name and place (3.10).
- The replies (3.12).
- Three small confirmations (3.11).

### Build work known now (before the director's answers add more)

- **Hair and beard, the mod-set error (54).** Parked until after t16. The next step is the begin probe that names the
  action's types, then a fix in ZeD's own path.
- **Hair and beard, the picked row (new, found tonight).** Clicking a picked row should un-pick it, but it stays
  picked. In `ZeD_HairBeard.lua` near line 1656, `x and nil or y` always gives y. One line.
- **From the Oct 29-30 notes, never logged on the punch list, to re-check:**
  - The oven's object card draws behind its Craft tab.
  - The oven tab misbehaves at UI scale 0.5, because the click skips the viewport check.
  - The plate export shifts pixels on a re-run.
- **The hover flicker in the ZeD style menu (7).** Its cause was never looked at.
- **Housekeeping on the punch list:**
  - Many item headers still say "open" or "fixed" although a later QA paragraph confirms them.
  - The Confirmed section is empty.
  - Some text was lost in item 41, around line 748, where the Stage 3 note starts mid-sentence.
  - The build session tidies these when the beta items go in.
- **The release check and a staging step** that sets the version and writes the build's page text. Neither is built.

### Test gaps on confirmed work (QA)

- **The old checklist (items 4 to 16).**
  - Never started: disclosures, screenshots with every disclosure open, a button-by-button sweep, themes.
  - Partly covered by the Oct 31 break-it pass: controller presses, typing, edge cases, resizing, errors, speed with
    400 rows.
  - Still missing:
    - a controller reach-and-stuck sweep
    - Escape closing things
    - themes surviving a restart
    - 1,500 mods at frame rate
    - a tidy other-mods sign-off
- **Gaps recorded on confirmed items:**
  - 2: the TV picture, sign-off and station logos.
  - 3: the ham set at 1.5 scale, and an object card with and without its scrollbar.
  - 18: the game's own Mods page.
  - 19: the dimmed row skipped by a real pad.
  - 21: Crouch and Aim following the character, Loadouts off while on the Journal, Craft's alternatives mode, the
    help line's words under each band.
  - 22: the bar's help line under the pointer.
  - 30 and 39: a resolution change while the game runs.
  - 37 and 41: the hand checks (right-click menus, Ctrl and Shift-click, Page Up and Down, the pad on folder and
    separator rows, drag), 1,500 mods, the look against mockup v2.
  - 44: the one-list rule for a container column.
  - 49: the preview card at 4K on the last build.
  - 51: the Turkish capitals on the pixel face.
  - 52: the in-game Sandbox window with a long list and its change marks, and the server settings' bumpers.
  - 53: Immersive Moodles' option through a real reload, and the controller.
  - 55: the game's inventory by its key with the windows switch on, the dashboard, the quick wheels and character
    info by their keys.
  - 56: the Simple belt with 0, 1, 4 and the most slots, a real mouse drag and the controller.

### The test rig (QA, not the mod)

- **wpt** still expects the old quick use on hold A.
- **dke**'s key reading slips now and then.
- **dgr**'s fire truck won't pass 2 km/h at the drag strip.
- **two_widths** is an order flake.
- **jrd** reads "too dark to write" at some hours.
- **card_pad** runs twice at Large text.
- **zedqa_bars_look** should pick tools and weapons only.
- **The QA character** lost its deep-run state (skills, bags).
- **zedqa_mods_hold.lua** waits for a hand session with the real mouse.
- **Why the 1080p pass passed sl** from the old place is unexplained. It's low priority.
