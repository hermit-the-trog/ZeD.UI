# Survival guide (F1): design draft (Nov 3 2026)

The director, Nov 3 2026: "The ingame survival guide is next. Let's start on it. F1 guide..." Today ZeD passes the
game's guide through untouched (HOOK_MAP row 18). Nothing is built yet.

## The director's answers (Nov 3 2026)

1. **Both looks:** the ZNIX manual book (Full) and the plain ZeD window (Simple).
2. **More than the game's guide:** "Yes, in addition to the vanilla guide and whatever else we can add. Make F1
   useful for noobs and vets alike." A ZeD section, plus more (see "What else" below).
3. **New clips:** "Can we make new clips with our UI instead of Vanilla?" Yes (below).
4. **First run:** "Keep it the vanilla mechanic": it opens by itself on a new game, with the Show guide tick box.
   This is the one exception to the no-pop-ups rule.

## New clips: how

The game plays clips a mod brings (VideoTexture.getOrCreate looks through the mods' media folders), in the game's
own video format (Bink). Two ways to make them:
- **RAD Video Tools** (the maker's free Bink encoder): real video, smooth, light on memory. A new program on this PC:
  needs the director's OK (the no-installs rule). QA records with Windows' own recorder (Xbox Game Bar), the encoder
  turns it into a clip.
- **Flipbooks** (QA's screenshots played as frames, no new program): choppier, and heavy on memory past a few
  seconds. Only for a short loop.
Build's pick: RAD Video Tools. Remake only the clips that show the game's menus; the ones that show moves (walking,
vaulting, aiming) stay as they are.

**Installed Nov 3 2026 (the director: "Yes, install it"):** C:\RADVideoTools (radvideo64.exe, binkplay.exe), unpacked
from the maker's RADTools.7z (sha1 93d2ec21, signed by Epic Games), no installer run. The game's guide clips are
Bink 1 ("BIKi"), 960 x 480, 15 frames a second. Encode from PowerShell (from Git Bash it hangs):
`Start-Process C:/RADVideoTools/radvideo64.exe -ArgumentList 'Bink','"<dir>/f???.png*0-95"','"<out>.bik"','/Bink1','/F15','/O','/#'`.
A 24-frame test gave the same header as sg_aiming.bik. Not yet played in the game (QA's job).

## What the game's guide is

- A window on F1 (and on the controller's Help wheel). A list on the left, a video clip and its text on the right,
  a "Show guide" tick box at the foot.
- **15 sections, about 80 topics:** Movement, Loot, Interactables, Combat, Food & Water, Character, Crafting and
  Building, Vehicles, Weather, Foraging & Mining, Farming, Ranching, Fishing, Cleaning, Multiplayer.
- **82 short video clips** (media/videos/survival_guide), one per topic, shown by the game's own player.
- Each section opens on a Spiffo picture; each topic's text names your keys (or your controller's buttons).
- It opens by itself at the start of a new game until the tick box is cleared.
- The topics come from the game (SurvivalGuideEntry), so new ones arrive with game updates.

## Proposal

A ZeD window on F1, laid out like the Crafting, Vehicle and Cooking tabs: topics on the left by section (folding as
the Vehicle tab's sections do), the clip and its text on the right, the band at the foot.

- **The game's content, the game's words:** every section, topic, clip and line of text is the game's own, read
  from the game, so updates and translations come for free. Keys and buttons are drawn as ZeD's key caps and button
  pictures instead of the game's words in brackets.
- **No Spiffo pictures:** a section's first page is its topics as a list (or the first topic), in ZeD's look.
- **Never opens by itself** (no first-run pop-ups): F1 and the Help wheel only. The tick box goes.
- **Search** in the band: type a word, the list keeps the topics that have it.
- **Controller:** the same paths as the other split tabs (list, then clip, B back).

## What else (for new players and old hands)

The director's research thread (Nov 3 2026, pasted into the build session) ranked what new players get stuck on
and what experienced players leave the game to look up. Its main finding: the gap is **numbers the game keeps
hidden**, not the basics the game's guide already covers. Top of each list:
- **New players:** the Knox infection (a wound's "Infected" is not the zombie infection; a scratch can kill), fighting
  groups in the open, sprinting into exhaustion and strain, noise (guns, alarms), the unannounced water shutoff,
  wound care, moodles, curtains and windows, looting by instinct, weapons and bags, car keys and hotwiring, the
  helicopter, Build 41 habits that no longer work, food and water, reading and TV.
- **Old hands:** the map, skill XP and book multipliers, recipe magazines, trait and occupation costs, weapon stats,
  infection timing, sandbox defaults, the helicopter, moodle thresholds, foraging, farming, smithing stations,
  animals, vehicles and generators, carpentry.

### The line: the game's rules, never your world's secrets

**Agreed by the director, Nov 3 2026: "Yes, that's the line."**

ZeD's rule is to say the game's rules out loud but never reveal what it keeps from you. The research makes that line
the main design question. Build's proposal:
- **Yes, the rules, as plain numbers:** the infection odds by wound, what each skill book multiplies, the XP each
  level takes, the moodle steps, the hotwire levels, the shutoff and helicopter windows **as sandbox ranges**. They
  apply to everyone, every vet knows them, and new players lose characters for not knowing them.
- **Never your world's or your character's secrets:** whether you are infected, the day your water goes off, the
  helicopter's day, where loot or keys are, the map beyond what you have seen, what a magazine teaches before you
  read it.
- **Read from the game, not from fan sites:** every number the guide shows is read from the installed game's own
  files or this world's sandbox settings, so it is right for this version and these settings, and a game update
  changes it with no work. Where a number cannot be read that way, it is left out.

### Proposed sections beyond the game's own

1. **ZeD:** each window and tab, cut down from the gallery book.
2. **The rules in numbers** (one page per game section, beside its topics): infection, moodles, skills and books,
   hotwiring, shutoffs and the helicopter as your sandbox's ranges.
3. **First days:** a short path for a new character, built from the new-player list (water early, walk don't run,
   curtains, fight at doors and fences, a bag and a weapon first, the infection explained).
4. **Build 41 habits:** what changed in Build 42 (traits, carpentry, crafting, magazines, weapon wear), for players
   coming back.
5. **F1 opens on where you are**, **your controls**, **what's new in ZeD** (as before).

## Decided

All five sections (the director, Nov 3 2026: "All five"). Next: a mockup of both looks on one topic.

Mockup v1 (Nov 3 2026): ZeDUI/mockups/zed_survival_guide_v1.html (built by ZeDUI/tools/guide/build.py from the game's
files), published privately at https://claude.ai/artifact/97moJBEid53AxPt7zSHbMY. Both looks on Character > Skill Books.

The director on mockup v1 (Nov 3 2026):
1. The Simple window reads as one of ZeD's tabs: yes.
2. The manual: "printed, this is a different book from Bitch'n Guide... So it has its own look and is an unmodified
   manual with no marks or custom notes. Just bought from the bookstore. Book Naked." No handwriting, tape, stickies
   or the gallery book's running head; its own printed look; the clip as a printed figure.
3. F1 opens on what you are doing (from the Skills tab, Skill Books): yes.

Mockup v2 (Nov 3 2026): ZeDUI/mockups/zed_survival_guide_v2.html, same link. The Full look is a clean printed manual: running
head "The Survival Guide", black and one red ink, numbered chapters (the game's section order), the clip as a numbered
figure, the rules as a numbered table, a printed thumb index on the right page edge. Open: the book's name; the ink.

The director on v2 (Nov 3 2026): "Looks too modern, AI web standards. This is the look", with a scan of a November 1990
newsstand survival magazine (Downloads; kept out of the repo, it is someone else's magazine: its look only, never its
name, logo or pages). Mockup v3 (same link): a kicker over a heavy bracketed-serif headline, an italic deck between two
rules, two justified columns with indents and a drop cap, the clip as a boxed halftone with a bold sans caption,
grey-tint bars in heavy display caps, spec tables in a tinted box, cream newsprint, navy-black ink, folios at the foot.
Open: the book's name; whether each topic gets a deck line. The PDF renders here with Windows' own PDF engine
(scratchpad render.ps1, Windows.Data.Pdf from Windows PowerShell 5.1).

Second reference (Nov 3 2026): the same magazine's January 1990 issue (a zip of page scans in Downloads; also kept out
of the repo). Mockup v4 (same link) adds what it shows: a byline line ("Staff Report") between rules under the deck,
the drop cap followed by the first word in capitals, bold run-in subheads ("Reading Part of a Book -- ..."), and
charts in a ruled box with a bold caption centred inside at the foot. Its how-to pages (snares) use labelled line
drawings in the same ruled box: the model for any diagram the guide needs.

Third reference (Nov 3 2026): FEMA's "Protection in the Nuclear Age" (H-20, June 1985, 42 pages; Downloads). A US
government pamphlet: centred PART heads in bold sans caps, typewriter body, checklists with empty tick boxes under bold
headings, figures in round-cornered ruled frames with all-caps hand-lettered labels, numbered STEP blocks beside
technical drawings with TOOLS AND MATERIALS lists, two-tone pictograms, "Page n" folios. What the magazine look does
not have: checklists and step-by-step build pages. How the director wants it used is open (Build's suggestion: the
First Days section and any build-it pages printed as a civil-defence pamphlet tucked into the guide).

Fourth reference (Nov 3 2026): "The Complete Survival Guide" (DBI Books, 1983; archive.org
completesurvival0000unse; the free preview stops after the contents, the rest needs a borrow). The bookstore book the
director means: a title page and chapter heads in heavy italic display caps, a contents page with numbered chapters in
bold sans caps, a line on each and dotted leaders to the page, a sepia photo facing the title page. Mockup v5 (same
link) adds a title page and a contents spread ("Full: contents"): F1 with nothing to jump to opens there. Chapter 1's
first spread (pages 6-7) the director opened in the browser pane.

The director: "look at chapter 1 first spread" (pages 6-7, the tents). Mockup v6 (same link) sets the manual's pages on
it: a chapter's first topic opens with "Chapter n" in bold sans, the chapter name in heavy italic caps, a borderless
halftone photo with an italic sans caption, a bold sans Title Case line under it, serif columns with a two-line drop
cap and the first words in capitals; later topics carry their own title in the same italic face; the foot has the
page number in the outer corner and the book's name in small sans caps. Keys print as outline keys in ink. The rules
pages keep the 1990 magazine's grey bar, run-ins and ruled chart.

The director on v6 (Nov 3 2026): "No drop caps though. Translation nightmare and hard to read." Removed, with the
first word in capitals that went with them. A paragraph opens plainly.

The book's name (the director, Nov 3 2026): "Survive the Apocalypse. Survive an Outbreak like it's a Vacation. By
Stevie Whetstone, Doidbros and Buzzlord Division of Survival Emergency Publications 1987." On the title page as
title, subtitle, byline and imprint (Doidbros and Buzzlord / Division of Survival Emergency Publications / 1987);
"Survive the Apocalypse" is the running foot. The Simple window keeps the game's title, Survival Guide.

The director: "the book is 87. A bit newer. Could be 2nd edition." The title page says Second Edition; the 1983 book is a
layout reference only, and the author photo can look late 1980s.

The author photo (Nov 3 2026): QA's in-game bust (Screenshots/guide_author/zqa_author_S_16.png: short dark hair,
moustache, horn-rimmed glasses, lumberjack shirt; ZeDUI/tools/qa/zedqa_author_portrait.lua), straight on as in the
director's reference, turned black and white from the red channel so the plaid shows, then a 45-degree dot screen
(ZeDUI/tools/guide/author.png). Mockup v7 (same link): "Full: title page" is the title page alone; "Full: contents" is
the contents (left) facing the Introduction (right) with the photo set into the text and Stevie Whetstone's name and
town (Muldraugh) under it. The introduction's four paragraphs are Build's draft for the director to rewrite. A sepia
frontispiece facing the title page (as in the 1983 book) waits on a capture with no UI in it.

The author photo, redone (Nov 3 2026): QA's second set to the director's reference (brown hair parted to the side,
horn-rimmed square glasses, moustache, flannel). Used zqa_author2_key_a_z15.png (grey plaid; QA's pick), keyed off
its green, set on a blurred, lightened crop of the Fossoil store plate (zqa_author2_interior_store.png) for the room
behind him, then black and white with the face held in the mid greys and a 45-degree dot screen sized by area.

(QA, Nov 3 2026: the first-round originals, zqa_author_S_16.png among them, are deleted; ZeDUI/tools/qa/author_portrait.txt
remakes them. The book uses the second set; its script commit is ecf5610a.)

The rules page (the director, Nov 3 2026: "Gray bar, gray bar."): it keeps the 1990 magazine's grey-tint bar, bold run-ins and
ruled chart. The Full look is settled; the introduction's text stays Build's placeholder for the director.
