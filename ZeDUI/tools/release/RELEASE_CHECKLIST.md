# ZeD UI: hidden Workshop upload for testers

The director signs off every upload, the first one and every update. Claude can stage and check, but never presses Upload.

Run the commands below from `Zomboid/mods/ZeD-UI`.

## Before the upload

1. **Run the regression at real play scale.** Check `Zomboid/Lua/zedqa.lock` says free and the game is not running (other sessions use the same game). Then `pwsh -File ZeDUI/tools/qa/zedqa_run.ps1`: fullscreen 3840x2160 (the default since Oct 22 2026), with ZeD's UI scale at 1.75x and both windows reset to their default spread (the footer's R) before every script; the runner puts the director's own settings back afterwards. It must end with exit code 0 (no FAIL, TIMEOUT or SKIP). The report lands in `ZeDUI/qa/regression/`. The 1080p window (`-Mode windowed`) is optional.
2. **Commit what should go up.** The stage script copies the files as they are on disk and warns about uncommitted changes. Another session's unfinished work goes up too unless it is committed or set aside first.
3. **Update `42/mod.info` before every upload** (director, Oct 22 2026). The game's mod list shows it, so testers read it. Check each line: `name=ZeD-GUI`; `description=` says what this build is (Oct 22: "Inspired by Apple System 7, Unix and Windows operating systems from the era. Built for controller and keyboard and mouse as equals."); `author=Hermit the Trog`; `url=` the Workshop page once the item has an id (`https://steamcommunity.com/sharedfiles/filedetails/?id=<item id>`); `versionMin=` the oldest build tested. Commit it.
4. **Pick the version testers will quote.** The first tester build is `0.2.0-t1` (director, Oct 20 2026); later tester builds count up (`0.2.0-t2`). Either change `modversion=` in `42/mod.info` and commit it, or pass it to the stage script (`-Version`), which changes only the staged copy.
5. **Stage.**
   - `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -DryRun` lists what would go up and what is left out.
   - `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -Version 0.2.0-t1` builds `Zomboid/Workshop/ZeD-UI/`.
   
   Check the summary: about 2,825 files and 36 MB (0.2.0-t2, Oct 23 2026; the fonts carry extended Latin, Greek and Cyrillic since Oct 20 2026), the version, the preview passing, and the Workshop item id once there is one.
   
   Never delete `Zomboid/Workshop/ZeD-UI/workshop.txt`. After the first upload it holds the item's id. Without it, the next Upload creates a second item.
6. **The preview picture** is the ZNIX USER cover (Oct 21 2026), already in place as `ZeDUI/tools/release/preview.png`. To change it, edit and run `py -I ZeDUI/workshop/thumbnail/pixel_znix.py`, copy its `znix_256.png` over `ZeDUI/tools/release/preview.png`, then stage again. Don't run `make_preview.py`: it draws the old desk-crop picture and would overwrite the cover.

## The upload

7. Start Steam, then start the game normally (no `-debug`) and wait for the main menu. The Workshop item only appears while Steam is running.
8. Open **WORKSHOP** in the action strip (or **Settings > Workshop** in the menu bar).
9. Pick the **ZeD-UI** folder on the left. The checks on the right must all pass, including what goes up and the preview.
10. **Who can see it:** **Unlisted** (anyone with the link; the director chose it for the tester builds). Never Public until the director says so.
11. **Tags:** Build 42, Interface, QoL, WIP.
12. **Description:** paste ZeDUI/workshop/tester_description_0.2.0-t1.bbcode into ZeD's description editor (later builds: copy it and change the version line). It says it is a test build, which version, and where to report.
13. **Change note:** ZeDUI/workshop/tester_changenote_0.2.0-t1.txt for the first build; after that, what changed since the last tester build.
14. **Save**, then **Upload**, and confirm in the strip. Wait for the result. The first time, Steam may ask you to accept the Workshop agreement on the item's page before anyone else can see it.
15. Open the item in Steam and check that it is still hidden and the size is about 35 MB. Don't subscribe on this computer: the copy in `Zomboid/mods` is already there, and two copies of the same mod clash.
16. Remove `Zomboid/Workshop/ZeD-UI/Contents` after the upload and the check in step 15 (`workshop.txt` and `preview.png` stay). The staged copy has the same mod id as the dev mod, and the game loads the Workshop folder first, so it would shadow the dev mod with a copy that has no QA bridge. Stage again right before the next upload.

17. **Pin a discussion** on the item page called "Bug reports" (Discussions > Start a new discussion, then Pin), and link it at the top of the description.
18. **Add the gallery images.** The game uploads only preview.png. On the item page in Steam (the browser or the Steam client), choose Add/edit images & videos and add the JPGs from ZeDUI/workshop/shots/out in their numbered order (each is under 1 MB). Do this once per build that changes the screenshots.

## What to send testers

- **The link:** `https://steamcommunity.com/sharedfiles/filedetails/?id=<item id>`. The id is in ZeD's Workshop window and in `workshop.txt`. Friends-only items only open for people on the uploader's friends list.
- **How to install:** open the link while signed in to Steam and press Subscribe. Start Project Zomboid (Build 42), open Mods on the main menu, turn on ZeD UI and accept. Start a new game, or play a copy of a save. To remove it, turn it off in Mods or unsubscribe.
- **How to report:**
  - Say what you did, what you expected and what happened. Include the ZeD UI version shown in Mods, and add a screenshot if you can.
  - Send `console.txt`: `C:\Users\<you>\Zomboid\console.txt` on Windows, `~/Zomboid/console.txt` on Linux and macOS. The game replaces it every time it starts, so copy it before you restart. Earlier sessions are in `Zomboid/Logs`.
  - **Safe mode:** if ZeD stops you from playing, turn on Options > ZeD setup > Safe mode, keep playing, and mention it in your report.
  - **-debug:** play without the `-debug` launch option unless we ask for it. With it, the game stops on every Lua error (other mods' errors too) and checks some code more strictly. If you used it, say so.
  - Where to send reports: the pinned discussion "Bug reports" on the Workshop page. Post one report per problem.
