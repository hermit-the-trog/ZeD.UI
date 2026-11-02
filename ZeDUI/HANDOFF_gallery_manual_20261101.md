# Handoff: the Workshop gallery as a worked-through 1993 manual (Nov 1 2026)

QA → Design, from the director's words in the QA session (Nov 1 2026, afternoon). The book stays; its pages change.

## What the director said

- The current pages read like a scrapbook: a picture or two pasted on a page with notes written around them. That came
  from his own instruction to drop the spine because stories overran it. He now thinks that was a mistake: "I think we
  can fit everything. Like two pages, a full spread."
- The reference he gave for how a mid-1993 instructional programming book uses fonts and lays out a page: Symantec C++
  for the Macintosh, The Basics (1993), vintageapple.org/macprogramming (a PDF; "not exactly, but you get the general
  idea"). Take from it the conventions, not the content: a printed serif body in a measured column, bold sans headings,
  monospace for anything typed, numbered figures with a printed caption under them, a wide outer margin, running heads
  and page numbers, tables set in the column.
- The page kinds he wants:
  1. **A manual page with screenshots taped over a paragraph.** The printed page is there underneath (body text,
     a heading, a figure caption); the kernel author's printed screenshots are taped on top of the paragraph they
     replace; a **sticky note at the bottom** says what the instructions are about, in his hand.
  2. **A page straight out of the manual, lightly edited.** When something needs more words, a table or a list, the page
     is printed as a manual page with only minimal marks from him, and it still explains the feature.
- So the mix per slide is a design call: where a screenshot carries it, the taped-on kind; where words or a table carry
  it, the manual kind. The four-colour pen stays his (blue explanations, red arrows, black and green jokes), the sticky
  note is new.

## What this changes for the build

- `workshop/gallery/book_shots.py` and `page_px.py` take the spread geometry (two facing pages, the spine in the
  middle, nothing crossing it unless the design says a figure may) and the two page kinds; `shots.json` keeps the
  captures, crops and points; `book_notes.json` keeps his words.
- The 24 full-height captures from Nov 1 are in `Screenshots/gallery_t14` (the old ones in `_before_nov1`), each with
  its window rect logged in `qa/regression/2026-11-01_gallery_nov1_*.md`; `workshop/gallery/REVIEW_20261101.md` has every
  page's faults and the wording fixes. Three captures still need a real pointer (23's pop-up and hover, 3's pop-up,
  15's help line).
- The two arrow numbers in `book_shots.py` are already changed on disk in the QA checkout (the head touches the point;
  a note within 10 px gets a short arrow), not committed; take or leave them with the rebuild.
- QA's re-point pass (new crops and points for every page) waits for the new page geometry, so it is done once.

## Open questions for the director (QA will ask)

1. One spread per slide at 1920x1080, or one page with a plain facing page?
2. Do the margin notes in his pen stay beside the sticky note, or does the sticky note replace them on the taped-on pages?
3. Who writes the printed body text: the description's own words (as the captions are now), or new manual prose?
