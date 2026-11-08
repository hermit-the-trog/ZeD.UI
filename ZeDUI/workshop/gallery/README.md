# Workshop gallery: "Bitchin' znix Programs"

The gallery is a used 1993 manual, worked through by the man who wrote the kernel. The cover is the book on the desk,
in pixel art. After it come the title spread and then 60 open spreads, one per chapter. On each spread the
publisher's dry, printed manual sits underneath. On top are his marks: his own printed screenshots taped over the
paragraphs they replace, his four-colour Bic in the margins, and a sticky note.

How a spread is laid out, and the JSON that describes it: `SPREADS.md`. The director's brief:
`docs/handoffs/HANDOFF_gallery_manual_20261101.md`. Where the set stands, what to retake and what the director still writes:
`docs/handoffs/HANDOFF_gallery_spreads_20261101.md`.

| What | File | Status |
|---|---|---|
| Cover | `znix_01_cover.png`, drawn by `cover_px.py` | approved Oct 30 2026 ("Party on"); the struck-through credit line reads D&B DOCS GROUP since Nov 1 |
| Title spread | `out_spread/00_title.png`, drawn by `title_spread.py` | copyright page left, title page right (Nov 1 2026) |
| Spreads 1-60 | `spreads/NN_id.json`, drawn by `spread.py` into `out_spread/NN_id.png` | sample (21) approved Nov 1 2026 ("Nailed it!"); all 60 laid out Nov 1 2026 |
| Upload set | `upload/`: `00_cover.jpg`, `00_title.jpg`, then `01_hero.jpg` to `60_machine_plates.jpg` | upload in file order; each under Steam's 1 MB |

## Rebuilding

    cd ZeDUI/workshop/gallery
    py spread.py spreads out_spread [--only id1,id2]     the spreads; prints CHECK lines
    py title_spread.py out_spread/00_title.png           the title spread
    py cover_px.py znix_01_cover.png                     the cover (and znix_01_cover_1x.png)
    py make_upload.py                                    out_spread + the cover -> upload/*.jpg

`spread.py` prints a `CHECK` line for anything that needs a look: a note over a print or over printed text, two
notes touching, a note off its page, a sticky's writing running past its foot or (on a manual page) hiding print,
an arrow pointing at something under tape. The set is clean when a full render prints none.

`make_upload.py` keeps every JPEG under 1 MB at full colour resolution (4:4:4), so the red and blue ink stays sharp.
It renders nothing: run the three renderers first. `spread.py --jpg <folder>` also writes JPEGs, but at 4:2:0.

`out_spread/` holds the PNG masters and is not committed; `upload/` is.

## The folder

| File | What it is |
|---|---|
| `SPREADS.md` | the rules for a spread and its JSON |
| `spreads/` | one JSON per spread, `NN_id.json` |
| `spread.py` | draws a spread: the printed page, the prints, his marks, the checks |
| `title_spread.py`, `cover_px.py` | the title spread and the cover |
| `page_px.py` | the shared pixel work: the desk and the open book at 4x, 1-bit print on a 2x grid, the ballpoint |
| `make_upload.py` | the upload set |
| `watch.html`, `watch.py` | the layout desk: open `watch.html` in a browser and every render lands there as it is drawn, with its CHECK lines and every earlier draft (kept in `out_spread/_watch/`, which git ignores) |
| `peek.py` | a zoomed crop with its own coordinates on it, for reading crop boxes and arrow points |
| `review_tools.py` | `words`: every printed word, note and sticky as text; `sheet`: the spreads tiled at a third of their size |
| `REVIEW_20261101.md` | QA's review of the Oct 30 book: each page's faults, the wording fixes, the retake status |
| `book_notes.json` | his own words for some callouts; a spread uses them exactly |
| `fonts/` | the fonts, with their licences in `fonts/FONTS.md` |
| `book_shots.py`, `out_book/` | the Oct 30 single-page book, replaced by the spreads on Nov 1; kept for reference |

The captures are in `C:/Users/danie/Zomboid/Screenshots/gallery_t14` (4K), and `../shots/shots.json` names them,
with their crops, points, captions and callouts. A spread's `src` names the capture it prints.

Scale on the cover's desk: the book is about 7.4 x 9.2 inches, about 27 art pixels to the inch; everything beside it
is sized from that.
