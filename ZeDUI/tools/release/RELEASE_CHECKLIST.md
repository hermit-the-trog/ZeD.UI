# ZeD UI: hidden Workshop upload for testers

The director signs off every upload, the first one and every update. Claude can stage and check, but never presses Upload.

Run the commands below from `Zomboid/mods/ZeD-UI`.

## Before the upload

1. **Run the regression at real play scale.** Check `Zomboid/Lua/zedqa.lock` says free and the game is not running (other sessions use the same game). Then `pwsh -File ZeDUI/tools/qa/zedqa_run.ps1`: fullscreen 3840x2160 (the default since Oct 22 2026), with ZeD's UI scale at 1.75x and both windows reset to their default spread (the footer's R) before every script; the runner puts the director's own settings back afterwards. It must end with exit code 0 (no FAIL, TIMEOUT or SKIP). The report lands in `ZeDUI/qa/regression/`. The 1080p window (`-Mode windowed`) is optional.
2. **Commit what should go up.** The stage script copies the files as they are on disk and warns about uncommitted changes. Another session's unfinished work goes up too unless it is committed or set aside first.
3. **Update `42/mod.info` before every upload** (director, Oct 22 2026). The game's mod list shows it, so testers read it. Check each line: `name=ZeD-GUI`; `description=` says what this build is (Oct 22: "Inspired by Apple System 7, Unix and Windows operating systems from the era. Built for controller and keyboard and mouse as equals."); `author=Hermit the Trog`; `url=` the Workshop page once the item has an id (`https://steamcommunity.com/sharedfiles/filedetails/?id=<item id>`); `versionMin=` the oldest build tested. Commit it.
4. **Pick the version testers will quote.** The first tester build is `0.2.0-t1` (director, Oct 20 2026); later tester builds count up (`0.2.0-t2`). Either change `modversion=` in `42/mod.info` and commit it, or pass it to the stage script (`-Version`), which changes only the staged copy.
4b. **The note on the main menu's corkboard** (director, Nov 5 2026). Build drafts five short lines from this
   build's change note, ten characters each at most, in capitals ("SERVER TAB", "CHAT"); the director approves
   them with the page text; they go in `42/media/lua/client/ZeD/MenuNote.lua` and are committed. The beta number
   at the top comes from the version by itself.
5. **Stage.**
   - Before staging, check the corkboard note is this build's: `git diff <last tag> -- 42/media/lua/client/ZeD/MenuNote.lua`
     must not be empty (beta 8 shipped with beta 7's note), and `42/mod.info`'s modversion must already be the new
     version, so the note's heading reads it in QA's checks and pictures, not only in the staged copy.
   - `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -DryRun` lists what would go up and what is left out.
   - `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -Version 0.2.0-t1` builds `Zomboid/Workshop/ZeD-UI/`.
   
   Check the summary: about 3,000 files and 37.3 MB (0.2.0-t6: 2,998 files, Oct 26 2026; the fonts carry extended Latin, Greek and Cyrillic since Oct 20 2026), the version, the preview passing, and the Workshop item id once there is one.
   
   Never delete `Zomboid/Workshop/ZeD-UI/workshop.txt`. After the first upload it holds the item's id. Without it, the next Upload creates a second item.
6. **The preview picture** is the dark 1993 thumbnail (director, Nov 11 2026: "The year is 1993. So is your user
   interface. All of it.", BETA on caution tape), in place as `ZeDUI/tools/release/preview.png` (512 x 512). Stage
   without `-Preview` so that is the one that goes up. Its sources are in `ZeDUI/workshop/thumbnail/` (src_1993_dark.py, eagle_build.py,
   year_1993_dark_*.png); when the beta ends, drop the tape (tape_draw() in src_1993_dark.py) and re-export.
   Don't run `make_preview.py` (the old desk picture) or `pixel_znix.py` (the old ZNIX USER cover): either would
   overwrite it. The animated version goes on after the Upload (step 16b).

## The upload

7. Start Steam, then start the game normally (no `-debug`) and wait for the main menu. The Workshop item only appears while Steam is running.
8. Open **WORKSHOP** in the action strip (or **Settings > Workshop** in the menu bar).
9. The window opens on the folder picked last (ZeD-UI). The checks on the right must all pass, including what goes up and the preview.
10. **Who can see it:** **Unlisted** (anyone with the link; the director chose it for the tester builds). Never Public until the director says so.
11. **Tags:** Build 42, Interface, QoL, WIP.
12. **Description:** Claude fills it in before the upload (director, Oct 24 2026: "set it up so I can just press upload"): the `description=` lines of `Zomboid/Workshop/ZeD-UI/workshop.txt` become the build's `ZeDUI/workshop/tester_description_<version>.bbcode`, one line each, with `version=`, `id=`, `title=`, `tags=` and `visibility=` kept. It says it is a test build, which version, and where to report. Steam refuses a description over 8,000 characters, and the game adds a blank line, "Workshop ID: <id>" and a "Mod ID:" line per mod (58 characters for ZeD_UI + ZeD_Picks): keep the description (lines joined by one newline) under 7,942. Trim old lines to make room for new ones (t5 went up at 7,861, t6 is 7,842).
13. **Change note:** Claude fills it in too, from `ZeDUI/workshop/tester_changenote_<version>.txt` (what changed since the last tester build): `Zomboid/Lua/ZeD_workshop.txt` holds `picked=ZeD-UI`, then `note ZeD-UI`, then each line of the note after a `|`. The window shows it in the change note box, and clears it once Steam says the upload went through.
14. **Upload**, then **Upload** again to confirm in the strip. Wait for the result. The first time, Steam may ask you to accept the Workshop agreement on the item's page before anyone else can see it.
15. Open the item in Steam and check that it is still hidden and the size is about 35 MB. Don't subscribe on this computer: the copy in `Zomboid/mods` is already there, and two copies of the same mod clash.
16. Remove `Zomboid/Workshop/ZeD-UI/Contents` after the upload and the check in step 15 (`workshop.txt` and `preview.png` stay). Then tag the staging commit (`git tag -a v<version> <commit> -m "Tester build <version>, uploaded <date>"`, `git push origin v<version>`) and refresh the backup: a new dated folder under `D:\ZeD-UI backup\` with `zed_backups`, the Workshop item folder and the QA save (standing rule, director, Oct 28 2026). Push main at the end of every session. The dev copy in `Zomboid/mods` wins over the staged copy (same mod id), so a normal game run tests the dev mod: test the stage from its own `-cachedir` (ZomboidStaged). Stage again right before the next upload.

16b. **The animated thumbnail** (director, Nov 3 2026; punch list 81). The Upload put the still back as the
    thumbnail; this sets the animated one (`ZeDUI/workshop/thumbnail/year_1993_dark_animated.gif`, frame 1 is the still).
    The director runs it, or build on his word, last thing, with nobody in the game: SteamCMD's login signs the
    Steam client out on this PC.
    - Once: install SteamCMD to `C:\steamcmd` and log in by hand (the script's header has the steps).
    - `pwsh -File ZeDUI/tools/release/set_preview_gif.ps1 -SteamUser <account> -DryRun`, then without `-DryRun`. It
      reads the item id from workshop.txt and sends the preview only (no files, no page text).
    - The first time, on the unlisted test item (`-ItemId <id>`), checking its files and page text are untouched.
    - Check the item page, the Workshop grid and the Steam app show it moving; sign the Steam client back in.

16c. **Start the next cycle** (director, Nov 8 2026: "create that note at the beginning of each build cycle instead
    of doing it at the end ... when I open up the app, I can see the notes"). Right after the upload and the tag,
    QA's first message to Build starts the next build:
    - bump `42/mod.info`'s modversion to the next version (the corkboard heading reads it);
    - set `42/media/lua/client/ZeD/MenuNote.lua`'s five lines (ten characters each, capitals) from the punch list and
      the director's plan for that build, shown to the director for approval before they're committed.
    - copy the last tester_description into the new version's file, keeping the line right after the GitHub
      paragraph: [url=https://claude.ai/artifact/CYvs9hqtbx1153ZooxhHkz]ZeD-GUI's design system[/url]. (director,
      Nov 9 2026: the design system link stays next to GitHub in every update.)
    The note can change during the cycle if the plan does; step 5's pre-staging check and the release check's picture
    still confirm it before staging.

17. **Pin a discussion** on the item page called "Bug reports" (Discussions > Start a new discussion, then Pin), and link it at the top of the description.
18. **Add the gallery images.** The game uploads only preview.png. On the item page in Steam (the browser or the Steam client), choose Add/edit images & videos and add the JPGs from ZeDUI/workshop/shots/out in their numbered order (each is under 1 MB). Do this once per build that changes the screenshots.

## Opening the test item to the public for a window (director, Oct 28 2026)

The test item keeps its id; the full release will be a separate item, so nothing rated or posted on the test item reaches the release. Before the visibility changes, on the item page (owner controls, right side):

1. **The item says it is a test.** The title reads `ZeD-GUI [TEST BUILD]`, the first paragraph says it is the test build and not the release (the full release comes as a separate item once the tests confirm it works well and meets the project's goals and quality standards), and the cover carries the red TEST BUILD band (the upload's preview.png, `pixel_znix.py --test`). An upload puts the title and description back from `workshop.txt`, so check them after the upload, not before.
2. **Leave Allow Comments on.** The director found (Nov 3 2026) that with comments off nobody can post in the
   discussions either, so Bug reports, Suggestions and the rest go dead. The page says comments are fine too: he
   reads them.
3. **Bug reports is pinned** at the top of Discussions; Compatibility and Add-on makers sit beside it.
4. **Change Visibility** to Public. Note the time: the door is meant to stay open about a day. Anyone who subscribes keeps access after it closes (unlisted only hides the item from search), and the item shows in Steam's recent lists while it is public.
5. **Close the door:** Change Visibility back to Unlisted. The title, the paragraph and the band stay as they are; they are true of the test item for good. Comments stay on.

## What to send testers

- **The link:** `https://steamcommunity.com/sharedfiles/filedetails/?id=<item id>`. The id is in ZeD's Workshop window and in `workshop.txt`. Friends-only items only open for people on the uploader's friends list.
- **How to install:** open the link while signed in to Steam and press Subscribe. Start Project Zomboid (Build 42), open Mods on the main menu, turn on ZeD UI and accept. Start a new game, or play a copy of a save. To remove it, turn it off in Mods or unsubscribe.
- **How to report:**
  - Say what you did, what you expected and what happened. Include the ZeD UI version shown in Mods, and add a screenshot if you can.
  - Send `console.txt`: `C:\Users\<you>\Zomboid\console.txt` on Windows, `~/Zomboid/console.txt` on Linux and macOS. The game replaces it every time it starts, so copy it before you restart. Earlier sessions are in `Zomboid/Logs`.
  - **Safe mode:** if ZeD stops you from playing, turn on Options > ZeD setup > Safe mode, keep playing, and mention it in your report.
  - **-debug:** play without the `-debug` launch option unless we ask for it. With it, the game stops on every Lua error (other mods' errors too) and checks some code more strictly. If you used it, say so.
  - Where to send reports: the pinned discussion "Bug reports" on the Workshop page. Post one report per problem.
