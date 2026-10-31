# Workshop gallery: "Bitchin' znix Programs"

The gallery is a used 1993-style programming book, marked up by the man who wrote the kernel. The cover is pixel art
on the desk; every other slide is the camera close on one page of the book, with the slide's screenshots printed on
it and his notes written in the margins.

Rules (director, Oct 30 2026):

- 16:9, 1920 x 1080.
- Pixel art for the physical things: the desk and the book on a 480 x 270 grid at 4x. What is printed or written on
  the paper is 1-bit on a 2x grid, so a sentence stays readable. The screenshots are printed crisp.
- Nothing crosses the spine. The spine runs down one edge of the frame; slides alternate right-hand and left-hand
  pages.
- One plain heading per slide: the name, no eyebrows, accents or marks. The caption is printed under it, dry.
- His pen is a four-colour ballpoint: blue writes the explanations, red draws the arrows, black and green are for the
  director's own jokes and asides.
- No coffee or glass rings and no tabs on the interior pages. The cover stays as approved, ring included.
- The director writes the jokes and says where they go.

| What | File | Status |
|---|---|---|
| Cover | `znix_01_cover.png`, drawn by `cover_px.py` | approved Oct 30 2026 ("Party on") |
| Slides 1-56 | `book_shots.py` + `page_px.py`, from `../shots/shots.json` and `book_notes.json` | set Oct 30 2026, waiting on Code's retakes (`ZeDUI/HANDOFF_gallery_book_20261030.md`) |
| Upload set | `upload/`: `00_cover.jpg`, then `01_hero.jpg` to `56_loadouts.jpg`, each under Steam's 1 MB | upload in file order |

## Rebuilding the slides

```
python ZeDUI/workshop/gallery/book_shots.py ZeDUI/workshop/shots/shots.json ^
    --out ZeDUI/workshop/gallery/out_book --jpg ZeDUI/workshop/gallery/upload [--only id1,id2]
```

It lets `tools/release/make_shots.py` do the layout (where each crop goes, where each callout goes so it covers
nothing, the patches that hide the debug corner), then sets the result as the page. Fonts: make_shots' own from
`zed_backups/fonts_for_desc` (or `--fonts`); Caveat and Charter from `fonts/`. `out_book/` holds the PNG masters and is
not committed; `upload/` is.

It prints `CHECK` when a note is written over a picture, two notes overlap, or a note covers another note's point;
make_shots' own `WARN` lines come through too. Look at any slide that prints one.

## The director's notes: `book_notes.json`

Per slide id, a list of:

- `{"match": "<callout text in shots.json>", "text": "<his words>", "pen": "blu|red|blk|grn"}`, optionally with
  `"at": [x, y]` (top-left in the 1920 x 1080 layout) and `"maxw"` when the new words need their own spot
- `{"title": "<heading>"}` to keep a heading to the bare name

`shots.json` itself is never changed for the book, so make_shots' old-style cards still build. A note is matched by
the callout's exact words: if a callout is reworded in `shots.json`, its entry here stops matching and the slide
quietly falls back to the plain callout.

Scale on the cover's desk: the book is about 7.4 x 9.2 inches, about 27 art pixels to the inch; everything beside it
is sized from that.
