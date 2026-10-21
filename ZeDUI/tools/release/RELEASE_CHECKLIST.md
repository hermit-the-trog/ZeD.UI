# ZeD UI: hidden Workshop upload for testers

The director signs off every upload, the first one and every update. Claude can stage and check, but never presses Upload.

Run the commands below from `Zomboid/mods/ZeD-UI`.

## Before the upload

1. **Run the regression in both modes.** Check `Zomboid/Lua/zedqa.lock` says free and the game is not running (other sessions use the same game). Then:
   - `pwsh -File ZeDUI/tools/qa/zedqa_run.ps1` (a 1080p window)
   - `pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Mode fullscreen4k`
   
   Both must end with exit code 0 (no FAIL, TIMEOUT or SKIP). The reports land in `ZeDUI/qa/regression/`.
2. **Commit what should go up.** The stage script copies the files as they are on disk and warns about uncommitted changes. Another session's unfinished work goes up too unless it is committed or set aside first.
3. **Pick the version testers will quote.** The first tester build is `0.2.0-t1` (director, Oct 20 2026); later tester builds count up (`0.2.0-t2`). Either change `modversion=` in `42/mod.info` and commit it, or pass it to the stage script (`-Version`), which changes only the staged copy.
4. **Stage.**
   - `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -DryRun` lists what would go up and what is left out.
   - `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -Version 0.2.0-t1` builds `Zomboid/Workshop/ZeD-UI/`.
   
   Check the summary: about 2,480 files and 35 MB (the fonts carry extended Latin, Greek and Cyrillic since Oct 20 2026), the version, the preview passing, and the Workshop item id once there is one.
   
   Never delete `Zomboid/Workshop/ZeD-UI/workshop.txt`. After the first upload it holds the item's id. Without it, the next Upload creates a second item.
5. **New preview picture (optional).** `py -I ZeDUI/tools/release/make_preview.py` (see `--help` to swap the art), then stage again.

## The upload

6. Start Steam, then start the game normally (no `-debug`) and wait for the main menu. The Workshop item only appears while Steam is running.
7. Open **WORKSHOP** in the action strip (or **Settings > Workshop** in the menu bar).
8. Pick the **ZeD-UI** folder on the left. The checks on the right must all pass, including what goes up and the preview.
9. **Who can see it:** **Unlisted** (anyone with the link; the director chose it for the tester builds). Never Public until the director says so.
10. **Tags:** Build 42, Interface, QoL, WIP.
11. **Description:** paste ZeDUI/workshop/tester_description_0.2.0-t1.bbcode into ZeD's description editor (later builds: copy it and change the version line). It says it is a test build, which version, and where to report.
12. **Change note:** ZeDUI/workshop/tester_changenote_0.2.0-t1.txt for the first build; after that, what changed since the last tester build.
13. **Save**, then **Upload**, and confirm in the strip. Wait for the result. The first time, Steam may ask you to accept the Workshop agreement on the item's page before anyone else can see it.
14. Open the item in Steam and check that it is still hidden and the size is about 35 MB. Don't subscribe on this computer: the copy in `Zomboid/mods` is already there, and two copies of the same mod clash.
15. Remove `Zomboid/Workshop/ZeD-UI/Contents` after the upload and the check in step 14 (`workshop.txt` and `preview.png` stay). The staged copy has the same mod id as the dev mod, and the game loads the Workshop folder first, so it would shadow the dev mod with a copy that has no QA bridge. Stage again right before the next upload.

16. **Pin a discussion** on the item page called "Bug reports" (Discussions > Start a new discussion, then Pin), and link it at the top of the description.
17. **Add the gallery images.** The game uploads only preview.png. On the item page in Steam (the browser or the Steam client), choose Add/edit images & videos and add the JPGs from ZeDUI/workshop/shots/out in their numbered order (each is under 1 MB). Do this once per build that changes the screenshots.

## What to send testers

- **The link:** `https://steamcommunity.com/sharedfiles/filedetails/?id=<item id>`. The id is in ZeD's Workshop window and in `workshop.txt`. Friends-only items only open for people on the uploader's friends list.
- **How to install:** open the link while signed in to Steam and press Subscribe. Start Project Zomboid (Build 42), open Mods on the main menu, turn on ZeD UI and accept. Start a new game, or play a copy of a save. To remove it, turn it off in Mods or unsubscribe.
- **How to report:**
  - Say what you did, what you expected and what happened. Include the ZeD UI version shown in Mods, and add a screenshot if you can.
  - Send `console.txt`: `C:\Users\<you>\Zomboid\console.txt` on Windows, `~/Zomboid/console.txt` on Linux and macOS. The game replaces it every time it starts, so copy it before you restart. Earlier sessions are in `Zomboid/Logs`.
  - **Safe mode:** if ZeD stops you from playing, turn on Options > Mods > ZeD UI > Safe mode, keep playing, and mention it in your report.
  - **-debug:** play without the `-debug` launch option unless we ask for it. With it, the game stops on every Lua error (other mods' errors too) and checks some code more strictly. If you used it, say so.
  - Where to send reports: the pinned discussion "Bug reports" on the Workshop page. Post one report per problem.
