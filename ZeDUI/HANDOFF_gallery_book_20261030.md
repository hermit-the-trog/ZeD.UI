# Handoff: the Workshop gallery as a book (Oct 30 2026)

Design → Code. The gallery is now "Bitchin' znix Programs", a used programming book marked up by the kernel's
author: the cover, then the 56 existing slides set as book pages. Everything about it is in
`ZeDUI/workshop/gallery/README.md`.

> **Status:** the cover is approved. The 56 slides are set and checked; the director wants the retakes below before
> the set goes up. The director signs off every upload and does it himself; nobody presses Upload.

## What's in this commit (Design's files only)

| File | What |
|---|---|
| `workshop/gallery/book_shots.py`, `page_px.py` | set every slide in `shots/shots.json` as a book page; `--jpg` writes the upload copies |
| `workshop/gallery/book_notes.json` | the director's own words over the callouts, and his ink (two on slide 11, one moved note on 28, the heading on 56) |
| `workshop/gallery/fonts/` | Charter added (the printed type); licences in `FONTS.md` |
| `workshop/gallery/upload/` | the set as it stands: `00_cover.jpg`, then `01_hero.jpg` … `56_loadouts.jpg`, all under 1 MB |
| `workshop/gallery/README.md` | the gallery's rules and how to rebuild |

Nothing in `shots/shots.json`, `tools/release/` or the mod is touched.

## What Code needs to do

### 1. Retake every screenshot on the current build

The slides use the t13 captures (`Screenshots/gallery_t13`) and older t8 ones (`Screenshots/workshop_src_t8`). The
build is at 0.2.0-t14. Retake them all with the gallery script (`tools/qa/make_staged.py` →
`zedqa_gallery_staged.lua`, as on Oct 21) so the slides show what ships.

Every capture: 4K, no debug overlay, no QA text, the default theme (dark, orange) except where a slide is about a
theme or accent (`open_for_business`, `night_shift`, `themes`, `see_through`, `controller_highlight`), same saves and
staging as before.

Known faults in the current captures, to fix in the retake:

| Slide | Fault |
|---|---|
| 46 `wallpapers`, 47 `desk` | the desk's menu bar shows **Debug** (the game was run with -debug) |
| 1 `hero`, 11 `customers`, 38 `ovens` | the debug position readout in the bottom right; hidden for now by the shot list's `patches`, which a clean capture makes unnecessary |

Keep the crop boxes and anchors in `shots.json` matching the new captures (`make_shots.py --debug` draws them). If a
callout's words change, tell Design: `book_notes.json` matches the director's notes by the callout's exact words
(slide 11: "Customers queue at the counter." and "The watch you wear, at the left end of the belt."; slide 28: "Show:
Ready is on, so the list holds only what you can build now. Nothing is ready yet.").

### 2. Slides for what has been built since t13

None of these have a slide yet. Each needs wiring in game first (the handoffs are in `ZeDUI/`), then a capture and a
`shots.json` entry written the way the others are (a plain title, a dry caption, crops, callouts that say what a
thing does):

| Feature | Handoff | Slide |
|---|---|---|
| The two radios, the hand-built radio, the CD player | `HANDOFF_radio_tv_laundry_20261030.md` | one slide: the four faces in the radio tab |
| The three TVs, with the off-air screens | same | one slide: the faces, one showing a station, one showing snow or a sign-off card |
| The washer, the dryer, the washer-dryer | same | one slide: the three faces, one running |
| The machine plates (336) | `HANDOFF_plates_336_20261029.md`, `HANDOFF_plates_fill_20261030.md` | one slide: two or three plates in the full card |

Number the new slides after 56, or slot them where they belong and renumber (`n` in `shots.json`); the upload set
follows `n`.

### 3. Rebuild and send

```
python ZeDUI/workshop/gallery/book_shots.py ZeDUI/workshop/shots/shots.json ^
    --out ZeDUI/workshop/gallery/out_book --jpg ZeDUI/workshop/gallery/upload
```

Look at every slide that prints `CHECK` or `WARN`. Then send Design the slides (or the contact sheet) for review
before they go to the director. The director then adds his jokes to `book_notes.json`, and Design re-runs.

## Checked

All 56 build clean on the t13 captures. The only warnings are make_shots' own two, from the old layout
(`every_window`, `building`), and both slides read correctly on the page. Every upload JPEG is under 1 MB (largest
811 KB). Charter (Type 1 `.pfb`) loads in Windows' `py -3` (Pillow 12.2) as well as Linux (Pillow 12.3).
