# Handoff, Design to Build and QA: the gallery book for 1.0 (Nov 17 2026)

The Workshop gallery gets rebuilt for 1.0: a five-picture pitch first, then the book in the order a run meets the UI,
with wider crops, a full-page picture on about one spread in five, and fewer notes. This handoff is the tooling and
the shot list. **The copy (dry text, captions, ink and sticky notes) is not in it**: Design drafts that next and the
director reviews it before any spread is finalized.

Nothing in the repo was changed to make this. Everything is in `ZeDUI/workshop/gallery/v1_plan/`.

## The director's calls (Nov 17 2026)

- "Look at the average progress a user makes through the UI ... What do we need to show them up front versus what do we
  need to show at the end?" Researched; the storyboard follows the answer.
- "I'd like to see the spreads have text and maybe one image on one side and a full image on the other page. Not
  everywhere. Say 1 and 5 is that."
- "The crops should show more of the screen around the window. They're too tight ... I don't think people know what
  they're looking at until they see it from the perspective they're seeing it in the game."
- "The sticky notes and the ink on paper notes contain a lot of the same words." Measured: 303 ink notes and 101 sticky
  notes in the 63 chapters; 58 stickies mostly repeat the ink or caption beside them.
- On the storyboard and the two test renders: "You're okay to continue. I believe those spreads should work." and
  "Excellent, excellent, excellent."
- From the morning plan, still standing: Angel's story is told only in the figure captions; all other printed text is
  dry; a contents spread after the title.

## Answered (the director, Nov 17 2026, to Build)

1. **Pitch before the menus: yes.** Five pitch pictures ahead of the cover, then cover, title, contents, then Part 1
   with the menu chapters.
2. **The plain-place pictures: retake all of them** somewhere lived-in, not only Parts 2 and 3. QA has the list (the
   chapters marked "re-crop" with a QA test-place backdrop: 30 by Build's count of storyboard_v1.json).
4. **The title spread: cover, title, contents** (79 pictures).
5. **Window settings stay last**, in "Your way", as storyboarded. The storyboard's order comes from the research on
   how players progress through the UI. It supersedes the morning plan's "right after the inventory", which came before
   that research.

## Still open (do not build on this until the director answers)

3. **The fact page (pitch picture 5).** Build range, single player and multiplayer, adding to and removing from a save,
   conflicts with other UI mods, languages: the director supplies these. Do not write them from memory.

## What is in `v1_plan/`

| File | What it is |
|---|---|
| `storyboard.html` | The storyboard page (also published to the director): every picture in upload order, the spread sketched, what the capture must show, re-crop or retake. Open it in a browser. |
| `storyboard_v1.json` | The same data: per picture its kind, title, status, shot note, figures, notes and the captures it uses. |
| `sb.py` | Builds both from `spreads/`. Design's script; the per-chapter judgments are tables at its top. |
| `order_v2.json` | The order: seven parts, chapters by spread id, the scene that opens each part. |
| `reorder.py` | The order tool (below). |
| `REORDER.md`, `BREAKS.py` | Its output for `order_v2.json`: old chapter to new, and the scene list for `make_v1.py`. |
| `test/` | Two test spreads and their renders: `01_t_feature` (Stocking Shelves as a feature spread) and `02_t_standard` (Equipment Tab at the wide crop). Rough, for the look only. |

## For Build

### 1. The order tool (written, run on a copy, not applied)

`py reorder.py order_v2.json spreads <new empty folder>` writes the re-numbered spreads; `py reorder.py --check <folder>`
only checks. It sets `n`, `pages` (2n+20, 2n+21), the chapter block, every figure and table label and every
"Chapter N", "Figure N-M", "Table N-M" in printed and handwritten text, and names the file `NN_<id>.json`. It never
touches `seed` (it adds `seed` = the old `n` where one is missing), so no page's paper or tape changes. It refuses a
folder that already holds spreads.

Checked here on a copy of the 63 spreads: 63 chapters, 131 figures and tables, 0 broken references, before and after.
It also lists every reference to another chapter for the editor; after the reorder all 17 "Chapter N" mentions still
read correctly (they renumber), though several sit in paragraphs the dry rewrite will replace.

To do: review it, move it beside `spread.py`, and apply it to `spreads/` **after** the copy is approved, in one commit
with the renders, so the live book and its files never disagree. Introduction is chapter 1 and sits ahead of Part 1 in
the book; the tool lists it under Part 1 only because it numbers straight through.

### 2. `spread.py`: three additions

- **A full-page print.** A print that fills its page edge to edge (912 x 1012 at the page's corner), no tape, drawn over
  the running head, exempt from "runs off its page". The test fakes it with `"cross": true`, `"tape": []` and
  `"at": [960, 28]`; give it a real flag (say `"full": true`) and let `at` default to the page corner. Its crop is half
  the 4K frame at full height: 1946 x 2160 at scale 0.4686. Notes may sit on it: the sticky does in the test.
- **A caption must clear its print.** In both tests the caption block printed under the picture (see `test/*.png`).
  Either flow the caption below the print that carries its figure number or add a CHECK line for a caption a print
  covers.
- **Three new CHECK lines**, so the rules hold as spreads change: a print whose crop is under 45% of the frame's width
  and is not marked `"closer": true`; more than four ink notes on a page; a sticky that shares most of its words with
  an ink note or caption on the same page (sb.py's test: 60% of its words, stop words dropped).

### 3. Layout rules for every spread

- **Standard spread:** up to two wide pictures (crop at least 45% of the frame wide, window plus the game around it,
  character in the crop, printed up to 800 px wide) and up to two small closer looks (`"closer": true`). Chapters that
  hold more pictures today are flagged on their storyboard cards; Design picks which stay.
- **Feature spread** (13 chapters: Introduction, The Desk, Customers, Moodles, Stocking Shelves, Cooking, The Route, Driving In, Pumping Gas, Fishing, Night Shift, On a Controller, Open for Business): text and at most one small picture on one page, a
  full-page print on the other.
- **Notes:** caption says what the figure is; ink points at one detail, four a page at most; one sticky a page at most,
  never repeating the ink. The words are Design's and the director's. Do not write or trim them.
- **Marks keep working:** a mark's `to` is in the capture's own pixels, so re-cropping does not move arrows off their
  targets.

Build's part here is the renderer and re-fitting each spread's `prints` once Design supplies the copy. Design can draft
the print boxes per spread if that is quicker; say which you prefer.

### 4. New pages

- **Pitch pictures 1 to 5** (`00a` to `00e`): layouts on the storyboard. 1 and 2 are nearly all screenshot, the book as
  a frame only. Picture 1 must still read at 116 x 65, the size of a Workshop gallery thumbnail.
- **Contents spread:** printed, in `spread.py`'s page style, parts and chapters with page numbers read from the
  spreads, so it cannot go stale.

### 5. `make_v1.py` (copy of `make_b19.py`)

Builds `upload_v1`. File-name order is upload order: `00a` to `00e` the pitch, then cover, title, contents, then
`01_` to `63_` with a scene **before** each of Parts 2 to 7 (`BREAKS.py`: `08b_scene_part2` ... `55b_scene_part7`),
`63b_break_close`, `69_the_end`. One scene is new (`cin_pad_wheel`); the rest are framed already in `cinema/`. Keep the
contact sheet and an `ORDER.md`. Each picture under 1 MB. Never write `upload_b13` or `upload_b19`.

## For QA: the shot list

Standard as B19_RECAPTURE.md (4K, UI scale 1.75x, Dark + PZ Teal, list view, font 19px) unless the card says otherwise.
Story chapters: Angel Cross, Light + Blue (Dark + Blue at night), the Fossoil, West Point.

**The one new rule for every capture from now on:** the window being shown sits to one side or along the top, and the
character and the place stay uncovered beside it. A window over the character cannot be re-cropped wide.

| # | Picture | | What it must show |
|---|---|---|---|
| 01 | Before and after | retake | One moment, one place, split down the spine: the game's own inventory and loot on the left page, ZeD-GUI on the right. Same character, same container, same items. The screenshots fill the pages; the book shows only as a frame. Must still read at 116 x 65.  |
| 04 | Crafting and building | new | The B42 crafting window as the game draws it, left; the Crafting tab on the same recipe, right. Under them, the Building tab with a recipe open.  |
| 05 | Before you install | new | A printed manual page, no story: the build it runs on, single player and multiplayer, adding to and removing from a save, turning parts off, other UI mods, controller and Steam Deck, languages. Right page: ZeD setup, so the reader sees the switches. The facts are the director's to confirm; none are filled in here.  |
| 07 | Contents | new | New printed spread: the seven parts and their chapters with page numbers. No capture needed.  |
| 08 | Introduction | retake | The whole screen in play: both windows on their first tabs, the belt, Angel standing in the Fossoil forecourt in daylight. Nothing else open. A feature spread fills a page with this place. Retake somewhere lived-in. |
| 17 | Inventory and Loot | retake | Same character, same spot, same container, same items in both shots: vanilla first, then ZeD. One open stack. This pair also feeds pitch image 1, so take it wide and clean.  |
| 21 | Equipment Tab | retake | Re-crop the beta 19 capture wide. Check it at the 1.0 sweep for old icons, dark pop-ups or an older layout. The tall window covers the character and the street. Retake with the window to one side and the character standing clear. |
| 25 | Moodles | retake | Three or more moodles showing, one balloon open with its tail on the moodle. Feeds pitch image 3. A feature spread fills a page with this place. Retake somewhere lived-in. |
| 26 | Health Tab | retake | Same wound in vanilla and ZeD (a bandaged scratch reads best). Feeds pitch image 3. The tall Health window covers the character. Retake with the character clear beside it, a visible wound. |
| 35 | Cooking | retake | Re-crop the beta 19 capture wide. Check it at the 1.0 sweep for old icons, dark pop-ups or an older layout. A feature spread fills a page with this place. Retake somewhere lived-in. |
| 39 | Skills | retake | Re-crop the beta 19 capture wide. Check it at the 1.0 sweep for old icons, dark pop-ups or an older layout. Uses the same two tall captures as Old Job: retake once, use in both. |
| 40 | Old Job | retake | Re-crop the beta 19 capture wide. Check it at the 1.0 sweep for old icons, dark pop-ups or an older layout. Both tall panels cover the middle of the screen. Retake each with Angel clear beside the window, the Fossoil behind. |
| 46 | Crafting | retake | A recipe open with ingredients partly missing, so the have/need marks show. Take the vanilla B42 crafting window on the same recipe too (new), for pitch image 4.  |
| 59 | Fishing | retake | Re-crop the beta 19 capture wide. Check it at the 1.0 sweep for old icons, dark pop-ups or an older layout. The line is cast on mowed grass. Retake at water. A feature spread fills a page with this place. Retake somewhere lived-in. |
| 63 | Part 6 opener | new | Full-bleed movie frame, no book, no notes. NEW: a survivor mid-street, pad connected, the Here and now wheel open, no windows.  |
| 65 | On a Controller | retake | Pad connected: the Character wheel with the Belt slice; a window's help line showing pad prompts. Feeds pitch image 2. A feature spread fills a page with this place. Retake somewhere lived-in. |
| 75 | Playing on a Server | retake | Server tab with other players listed; chat open. Names must be QA's own test names. Backdrop now: half the captures are a black void with one tile lit. Retake in a street with other players in view. |

Everything else re-crops from the beta 19 captures. The 31 marked "re-crop, plain place" wait on the
director's answer (open item 2); they are listed on the storyboard under that filter.

## Not in this handoff

- The dry text rewrite, the Angel captions and the note cuts: Design, next, reviewed by the director in one document.
- Step 0 of the morning plan, the action bar: done by Build, a8753ff12 and QA's four fixes in c3cd0421d (sims clean).
- Build's part of this handoff (Nov 17): reorder.py checked (now writes LF), spread.py's "full" print, caption-cover
  CHECK and the --v1 checks, contents_spread.py: ade8ae707.
- The Workshop upload: only on the director's go; the director uploads by hand.

## Check before calling it done

- `py reorder.py --check spreads` reports 0 broken.
- `spread.py` renders every spread with no CHECK lines, the three new ones included.
- The contact sheet is in storyboard order and the director has looked at it.
