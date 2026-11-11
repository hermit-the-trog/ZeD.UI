# The gallery as a worked-through 1993 manual (spreads)

Director's brief: `docs/handoffs/HANDOFF_gallery_manual_20261101.md`. Approved sample (Nov 1 2026, "Nailed it!"):
`spreads/21_item_cards.json`, rendered `out_spread/21_item_cards.png`. Match it.

## The fiction

The book is "Bitchin' znix Programs", written by **Ann Sibyl**, published by **Doidbros & Buzzlord Division of
Informatics Publishing LLC** (1993). Everything *printed* is the publisher's: a very dry, descriptive manual for
operating ZNIX and its windows, in the register of a 1993 computer manual. Everything *on top* is the reader's, the man
who wrote the ZeD kernel (Hermit): his own printed screenshots taped over the paragraphs they replace, his sticky notes,
his four-colour Bic. He never types; the publisher never jokes.

## The picture

One slide = one open spread, 1920 x 1080. Chapter number = the slide number n. Pages: left 2n+20, right 2n+21.

| | x | notes |
|---|---|---|
| left page | 48 to 960 | outer margin x 48-258 (his notes), column x 258-890 |
| right page | 960 to 1872 | column x 1030-1662, outer margin x 1662-1872 (his notes) |
| spine | 960 | nothing crosses it, except a print marked `"cross": true` (a big scene photo, rarely) |
| height | y 28 to 1040 | running head baseline y 78 with a rule under it; blocks start at y 156; keep print above y 1016 |

Notes in the outer margin are about 184-200 px wide. Notes can also go in any clear paper (below prints, between
them) as long as they cover no print, no printed text they would make unreadable, and no other note.

## The two page kinds (choose per page)

- **manual**: the printed page carries it: a chapter opener, paragraphs, a numbered procedure, a bulleted list, a
  table, a Note. His marks are light: a green circle, an underline, at most one or two short blue notes. A manual page
  may carry the publisher's own printed figure (`"printed": true`: framed by a rule, no tape, a caption under it).
- **taped**: his printouts taped on the printed page, covering the paragraph they replace. Some printed text shows
  around them (a heading, the paragraph's first lines, its edges, the figure caption below). His blue notes in the
  outer margin with red arrows to the exact things; green circles; one **sticky note at the bottom** (black pen) saying
  what the page is about.

Typical spread: left manual (chapter opener + text/table), right taped (the screenshots). When the screenshots need
more room, both pages are taped (the chapter opener still prints at the top of the left page, above the prints).
When words carry it (a long list, a table of buttons), both pages may be manual.

## The printed page (the publisher's)

- Left page starts with `{"chapter": ["<n>", "<Title>"]}`. Title = the slide's title from shots.json, Title Case. The
  three untitled photo slides: 1 "Introduction", 11 "Customers", 47 "The Desk".
- Running heads: left `"Bitchin' znix Programs - Doidbros & Buzzlord"` (a hyphen, never a middle dot: punch list 128), right = the chapter title (short).
- Voice: dry, plain, present tense, second person. "To open the card for an item, click the item." "The card
  opens in the drawer at the left of the window." No jokes, no hype, no exclamation marks, no "you'll love".
  *Bold* for names on the screen (buttons, tabs, menu items, window names): `*Equip*`. `` `Mono` `` only for anything
  typed. Figures and tables numbered by chapter: Figure 21-1, Table 21-1, referred to in the text (a figure on a
  taped page is the exception: the paragraph that cited it is under his tape).
- House style (settled in the Nov 1 review): the publisher calls the system **ZNIX** ("This book describes ZNIX and
  the windows it draws"); "ZeD" appears only inside screen names (*ZeD setup*, the ZeD wheel, ZeD picks, the *ZeD*
  menu) and in his notes. *Click* for anything on the screen, *press* for keys and pad buttons. The pad's buttons by
  the names in Table 42-1 (*View*, not Select). American spelling: gray, color. Names exactly as the screen shows
  them: the *Crafting* tab, *Zombies Killed*, *TAKING FUEL*, ValuTech. Captions are plain (no bold) and say where
  each picture is: top, bottom, left, right.
- Story chapters (2-14) are a tutorial walkthrough: the chapter follows Angel Cross through the game (the shot's
  caption), and the printed text explains the windows and controls the step uses, still dry.
- Every fact must come from: the slide's caption and callouts in `../shots/shots.json`, the corrections in
  `REVIEW_20261101.md`, the specs in the repo root (`*_SPEC.md`), or what the capture plainly shows. Never invent
  behaviour. If unsure, leave it out. Apply every wording fix the review lists for the slide, and never describe
  what the picture does not show in his notes (the printed manual may describe more, plainly, as manuals do).
- Fill the page like a real manual: about 18-30 printed lines on a manual page; no big empty holes. Text under
  the prints may be cut off by them; that is the point.

## His marks

- **Blue** (`"pen": "blu"`): explanations. Use the slide's callouts from shots.json (with the review's fixes), shortened
  to fit if needed but keeping their meaning. Where `book_notes.json` gives his own words for a callout, use those
  words exactly, in his pen.
- **Red**: arrows only, made by `"to"` on a note. The head must land ON the thing the note names (a button, a row,
  a mark), never on a border, the paper, or empty space. Verify every one with peek.py.
- **Green**: circles round things (`circle`), on a print or round a printed word.
- **Black**: the sticky note, one per taped page, at the bottom. Its words are the director's to write: draft a
  plain one-line summary from the slide's caption (no jokes) and list it in your report as a placeholder.
- No jokes anywhere unless they are already in book_notes.json.

## Prints (his screenshots)

- Captures: `C:/Users/you/Zomboid/Screenshots/gallery_t14` (4K, 3840 x 2160); the slide's `src`/crops in shots.json
  name them. The newest retakes and their window rects are in `ZeDUI/qa/regression/2026-11-01_gallery_nov1_*.md`
  and in the review's "Retake status". Use the freshest capture of each thing.
- Crop to show the whole of what the notes name, nothing cut mid-row. Scale so the UI reads: about 0.5-0.65 for a
  4K window capture; a full 4K scene at about 0.2-0.24 fills a page.
- Tape: `"tape"` corners from tl, tr, bl, br, t, b, l, r. Two strips per print, varied between prints.
- Points (`"to"`) and circle boxes are in the capture's own pixels; the renderer maps them onto the print.
- Prints are scaled with Lanczos; at a whole-number scale of 2 or more the pixels are simply doubled, so a small UI
  crop stays crisp. `"resample": "nearest"` or `"lanczos"` on a print overrides either way.
- An arrow leaves its note from the side nearest its point. `"from"` on the note moves the start: a side of the note
  (`"left"`, `"right"`, `"top"`, `"bottom"`) or a point `[x, y]` on the spread; a list sets each arrow of the note.

## The JSON (one file per spread: `spreads/NN_id.json`)

    {"id", "n", "pages": [2n+20, 2n+21],
     "left"/"right": {"kind": "manual"|"taped", "head",
       "blocks": [{"chapter": [n, title]}, {"h2": text}, {"p": text}, {"list": [..], "numbered": bool},
                  {"code": [lines]}, {"table": {"label", "title", "cols": [fractions], "head": [..], "rows": [[..]]}},
                  {"note": text}, {"caption": ["Figure n-k", text]}, {"gap": px}, {"at": y}],
       "prints": [{"src", "box": [x0,y0,x1,y1], "scale", "at": [x,y], "tape": [..], "printed": false, "cross": false, "resample"}],
       "marks": [{"text", "pen", "at": [x, y|null], "maxw", "to": [print, X, Y] or [[..],[..]], "from", "bend" (or a list, one per arrow)},
                 {"circle": {"print": i, "box": [X0,Y0,X1,Y1]}}, {"circle": {"word": w, "nth": 0}}, {"underline": w}],
       "sticky": {"at": [x,y], "w", "h", "text"}}}   (leave "h" out and the sticky fits its writing)

Print indexes count across the spread: the left page's prints first, then the right page's. A note with `"at":
[x, null]` stacks itself down that margin column next to its point.

## Build and check

    cd C:/Users/you/Zomboid/mods/ZeD-UI/ZeDUI/workshop/gallery
    py spread.py spreads out_spread --only <id>
    py peek.py out_spread/<file>.png x0 y0 x1 y1 C:/Temp/<you>/look.png --w 1100 --grid 20
    py peek.py <capture> x0 y0 x1 y1 C:/Temp/<you>/cap.png --w 1100 --grid 50

Read every CHECK line and fix it. The renderer checks, besides overlaps and edges: writing over printed text,
a sticky's writing running past its foot or hiding print on a manual page, and an arrow pointing at something under
tape. Then look at the whole spread, and zoom on every arrow head and every note. Do not
edit spread.py, page_px.py, shots.json or book_notes.json; if the renderer lacks something, say so in your report.

Open `watch.html` (this folder) in a browser to watch each render land; every draft is kept in
`out_spread/_watch/`, which git ignores.
