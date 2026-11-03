# Good morning: the beta, 0.3.0-beta1

Written by the build session overnight, Nov 2 to Nov 3 2026. Plain summary first, then what is left for you.

## Where it stands

The beta is built and frozen. Every change you asked for on Nov 2 is in: Full or simple for the belt, the action bar,
the context menu, the Equip view, the devices, the watch and the dashboard; the controller map in the quick wheel; Bug
report in the ZeD wheel; the machine translations for Turkish, Simplified Chinese and Brazilian Portuguese; This Is Your
Life with its hometowns and poster stories; container pictures instead of letters; the redrawn washer, dryer and
washer-dryer; desk v5 with the Kentucky Instruments pad; ZeD-GUI's version in About; 0.5x gone from UI scale.

QA's full pre-release pass, on the frozen build: the five-minute release check passed all 16 checks, and the full
4K run passed 97 of 99 scripts with no failures and no ZeD errors in the game's log. The two warnings are the same two
as at t16, and both are faults in the tests, not in ZeD: one still expects the old quick use on a held A, and one
times a car's key start a little differently each run. The rest of the pass was clean too: every page on Simple, save
and reload, the Steam Deck and 720p, the three new languages, the main menu, and a census of all 481 controller stops
with no dead buttons. It found two real faults, both fixed and checked again in the game before staging: the Simple
belt slid every slot sideways when a second item went into the off hand, and in Brazilian Portuguese the off-hand
circle cut its word short ("Secundári."; it now reads "Secund.").

**The release candidate is staged and ready to upload**, at the build QA passed. Nothing has gone up.

The gallery is ready: 63 pictures in `ZeDUI/workshop/gallery/upload/`, the cover, the title page and 61 chapters.

## What is new or changed in the gallery

Upload these to the Workshop item's images (the rest are unchanged from what is up now):

- **61_full_or_simple.jpg** (new chapter): ZeD setup's Full or simple rows, the plain watch and belt, a plain radio
  and the plain dashboard.
- **59_laundry.jpg**: the new washer, dryer and washer-dryer, with the notes moved onto them.
- **37_two_way_radios.jpg**: the walkie-talkie without its brand foot.
- **34_messages.jpg**: errors in Messages and the Bug report line.
- **42_controller_map.jpg**: the sticky points to the quick wheel's Help.
- **46_wallpapers.jpg** and **47_desk.jpg**: the desk with the KI pad.
- **48_options_menu.jpg**: Full or simple named in the list of sections.
- **00_cover.jpg**: the cover's monitor shows ZeD's own layout.

The handwritten notes on chapter 61 are mine, drafted for you to change: the stickies say "The real thing, or a plain
card." and "Same buttons, plainer drawing."; the blue notes say what the arrows point at. Tell me any wording and I
redraw it.

## What is left for you

1. **Say yes to the upload.** Nothing goes up without you.
2. **Upload** from the desk's Mod Uploader. It is staged under the new title "ZeD-GUI [BETA]" with
   the yellow-strip book as the thumbnail, the beta page text and the change note, and the item is already set to
   **Public**. Until the upload, the game loads the staged copy; it is the same build, so playing is fine.
3. **The gallery pictures** listed above, on the item's page.
4. **Post the translations announcement** in the Translations thread: the text is ready in
   `ZeDUI/workshop/steam_threads/translations_beta_post.txt` (a new top section for the first post, and a reply).
5. **One decision still open:** the Vehicle tab on small screens. QA's pictures at 720p and the Deck, at the real
   settings, show every value; only the parts list under the car is tight (one heading shows before Close Hood, the
   rest scrolls). My recommendation: leave it as it is for the beta.
6. **One question you never answered (no rush):** in the context menu's icon strip, an option with no icon of its
   own shows two letters. Keep the letters, or something else?

After you upload, I tag the build, refresh the D: backup and clear the staged copy.

## Known issues on the page

Hair and beard with some large mod lists can stop with a game error; multiplayer is untested; This Is Your Life
is new and not yet played through with that mod on; the three new languages are machine drafts. These are listed first on the beta's page.

## Not seen in the game yet

- **This Is Your Life with the mod itself turned on:** ZeD's hometown and poster-story pages are built, but nobody has
  started a new game through them with that mod running. With the mod off nothing of it shows. I added a line about it
  under Known issues on the page, so testers who use it know to report.
- **Multiplayer:** not tested (it is on the page as a known issue).
- A few of QA's own tests still miss things a picture shows are fine (four folding sections, one sandbox page); QA
  looked at each picture.
