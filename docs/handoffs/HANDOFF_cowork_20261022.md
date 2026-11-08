# Handoff from the Cowork session to Code (Oct 22 2026, afternoon)

Director: "move everything not design related back to code ... no more fighting each other."
Nothing of mine is running: no game, no regression, no scheduled checks. The QA lock is free.

## 1. Uncommitted work in the tree (mine): the gallery

`a51c4d0f` (Keeping count) rebuilt `shots.json` from `build_spec_v4.py`, which reads an Oct 21
scratch file, and that dropped what had been added since: Old job (tall Identity and Skills
crops), the route and customers balloon cuts, and the four cards Options, Mods, Profiles and
load order, Uploading (commit 3c447170). I put them back:

- `ZeDUI/workshop/shots/shots.json`: my 3c447170 list, minus `cleaning_up`, plus your
  `keeping_count` after `smoke_break` (checked: no other entry differed). Then, for "showcase all
  the work", five earlier cards added back: `equip_doll`, `health_compare`, `action_bar_compare`
  (from the v3 spec, sources in Screenshots/gallery_v3) and `controller`, `car_radio` (from the v2
  spec, sources made absolute to Screenshots/workshop_src). 31 cards. **Director, Oct 22: keep all five** ("yes. add five cards").
- `ZeDUI/workshop/shots/build_spec_v4.py`: now starts with `raise SystemExit(...)` (retired), so
  it can't wipe the list again. shots.json is the source; edit it directly.
- `out/` holds a 26-card build plus untracked 23-26; desc pictures and the page mockup were
  rebuilt for 26.

To finish (from the repo root):
1. `py -I ZeDUI/tools/release/make_shots.py ZeDUI/workshop/shots/shots.json` (31 cards; the
   numbering shifts, so `git rm` the stale `out/NN_*.jpg` names that no longer match).
2. Look at the five re-added cards against today's UI (they were shot Oct 20-21).
3. `py -I ZeDUI/tools/release/make_desc.py`, `py -I ZeDUI/tools/release/make_page_mockup.py`
   (and `--embed <path>` for a single-file preview), commit, push.

## 2. The tester build (0.2.0-t1): what's left before the director's Upload

Done and committed: mod.info (description and author from the director), tester description
(today's text), runner at real scale (fullscreen 3840x2160, ZeD UI scale 1.75x, the windows' R
pressed before every script, the director's ModOptions.ini put back after), the scale and CaZio
test fixes. Last full result: 62/63 then 44/44 from the scale script on (reports 0935, 1015),
**but that was before 180417d6 (curtain) and dba05151**, so:

1. Full regression on HEAD, game closed, lock free: `pwsh -File ZeDUI/tools/qa/zedqa_run.ps1`
   (about 50 min with the soak). Exit 0 required.
2. `pwsh -File ZeDUI/tools/release/stage_workshop.ps1 -Version 0.2.0-t1`. The summary must show
   no "uncommitted" warning; expect about 2,540 files, 36 MB, preview ok, dev tools left out.
3. The director uploads (RELEASE_CHECKLIST steps 7-18: Unlisted; tags Build 42, Interface, QoL,
   WIP; tester_description_0.2.0-t1.bbcode; tester_changenote_0.2.0-t1.txt). Claude never presses
   Upload.
4. After the upload, move `Zomboid/Workshop/ZeD-UI/Contents` out (it shadows the dev mod).

Old staged copy (had the curtain change uncommitted at the time): parked at
`Zomboid/zed_backups/staged_0.2.0-t1_with_uncommitted`; safe to delete.

## 3. Loose ends found today (not fixed)

- `x and nil or y` always takes y: `ItemFactsPanel.lua` 108 and 111 (insulation and wind
  resistance always "dim"), `MechanicsTab.lua` 500 (kicker always "recommended"). Same slip as the
  two upload-window bugs fixed in 8929f47a.
- `ZeDUI/qa/regression/*.modoptions.ini` from runs that were stopped (0929, 1204, 1208): copies
  of the director's ModOptions.ini; the current one is already back. Delete them; the untracked
  .md reports can be committed or dropped.
- Map order: the sample map mods (`Zomboid/zed_backups/gallery_samples_20261022`) weren't
  recognized as maps (empty map order), so map order isn't in the gallery.
- Description length: 6,854 characters with the IMG_BASE placeholder and 25 pictures; a long
  hosting address can push it past Steam's 8,000.
- Perf: PERF_2026-10-22.md's three leads (belt circles per pixel row, lists and rails rebuilt
  every frame, dashboard composed every frame). A 1080p run would show where most players sit.
