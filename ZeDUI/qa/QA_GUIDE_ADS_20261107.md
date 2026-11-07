# QA: the survival guide's ads (punch list 98), Nov 7 2026

Build's 9f0c211b, on the QA save. Checked with `ZeDUI/tools/qa/zedqa_guide_ads.lua` (`batch_guide_ads.ps1`, manifest `guide_ads.txt`).
Reports: `qa/regression/2026-11-07_guide_ads_4k.md`, `_DE.md` (the `_1080.md` from this run is a second 4K pass, since the windowed mode was missing; the 1080p pass is still to run).

## How it was checked

The book on Full, read four ways: Small and Large text, keyboard and pad wording. For each reading:

- the deal as planned;
- then every spread turned to, and every drawn ad measured from the book panel's own draw calls:
  - inside the text block's sides;
  - below its top and above the foot and folio;
  - at its design size times the page unit, on whole pixels;
  - full ads at the block's top left;
  - a pair's quarters level, with the gutter measured;
  - and the ads drawn on each page the same as the ads dealt to it.

Pictures were taken of every spread with an ad or NOTES block, at Small and Large keyboard.

## Results, 4K 1.75x

| Check | Small kb | Small pad | Large kb | Large pad | German Small |
|---|---|---|---|---|---|
| No ad dealt twice | PASS | PASS | PASS | PASS | PASS |
| Half and pair take turns | PASS (7 halves, 6 pairs) | PASS | PASS (4, 3) | PASS (3, 3) | PASS (5, 4) |
| Every spread: inside the block, clear of the foot, design size, whole pixels, level pairs (18 px gutter), as dealt | PASS, 53 spreads | PASS, 53 | PASS, 59 | PASS, 59 | PASS, 53 |
| First Days checklist first on its page | none printed | none printed | PASS, p. 111 | PASS, p. 110 | none printed |
| Ad pictures drawn | 34 of 34 | 34 | 22 | 21 | 24 |

- Close and reopen gives the same ads on the same pages. PASS.
- Another character, or another save, deals another order. PASS (checked by seed).
- Text size and pad wording keep each size's order. PASS.
- Spoilers:
  - Both hidden rules pages are dealt only NOTES at their feet: page 25, The Infection in This World, and page 35, This World's Settings.
  - "No ad until shown" holds, but there was no ad to show.
  - Showing the numbers changed no other page. PASS.
- Simple look: F1 opens the window and no book. PASS.
- In German the shop ads stay English and the house ad is translated, as one of the whole pages (page 33). PASS.
- Sharpness at 4K 1.75x: the bats' labels on Time 4 Sport and Phil's pawn checks box read cleanly (`guide_ads_20261107/sharp_4k_bats_pawn.png`).

## The thirds count (the open question for the director)

Third-size slots that got NOTES because no third was left:

| Reading | Third-size slots | NOTES instead |
|---|---|---|
| Small keyboard | 31 | 19 |
| Small pad | 34 | 22 |
| Large keyboard | 38 | 26 |
| Large pad | 42 | 30 |
| German Small | 35 | 23 |

- At Large, halves (4 of 7) and quarters (6 of 12) go unused while the thirds run out.
- Large pad has 6 whole pages but only 4 full ads, so 2 whole pages are ruled NOTES.
- From Crafting on (Small text) most feet are NOTES only.

## Faults

1. **The house ad's line under the headline runs out of the frame.**
   - The line is "Every manual a household needs before the lights go out."
   - English: at Large text.
   - German: already at Small.
   - At Large the price box ("ONLY $4.95 EACH") is filled edge to edge.
   - The line is one centered line with no wrap. It came in with the house ad on Nov 4, not in 9f0c211b.
   - Crops: `guide_ads_20261107/house_ad_EN_large.png`, `house_ad_DE_small_deck.png`.
   - Sent to Build.
2. **At Small text the First Days checklist never prints.**
   - No First Days page has a third left empty.
   - The same rule was there before the ads (fe104314), so it is not a regression.
   - Sent to Build.

## QA's own faults on the way

- The first run hung. The open book pauses the game, and the script counted game ticks, so it never moved on. It now counts render frames.
- When the run timed out, the batch tried to put the save back while the game still held it. The full copy landed inside the save folder.
  - It was moved back and matches the Nov 6 D: backup file for file.
  - The director's ZeD settings were restored.
  - Both batches now refuse to touch the save while the game is open.
