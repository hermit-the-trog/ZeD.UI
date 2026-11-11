# Build to QA, Nov 11 2026: test 14, then the gallery shoot

Branch `claude/keen-meitner-optdjj` (PR #5), tip of the branch (after the placeholder and notebook fixes). `42/mod.info` stays 0.3.0-beta11; the test pack names itself
0.3.0-beta11-test14. Beta 11 ships Nov 12 (the director); everything below is in it. Run in PZ Teal at the game's
Font Size 19px (`fontSize=2`).

## 1. Test 14 first: `qa/CHECK_b11_test14_20261111.md`
The director's Nov 10 notes (punch list 155 to 160, 162), all new code, not seen in the game yet:
- 155 the belt's empty hands: a right hand icon in the large ring, a left in the small one; the hint reads Right Hand /
  Left Hand.
- 156 the Loot tab's "Coming soon" half card is gone; a Loot drawer with no card folds.
- 157 an empty list says "Nothing here." (English only).
- 158 speech balloons, head notes and notices in lowercase Fira Mono, as said (CJK through the game's faces; RtvFace's
  screens keep the pixel face).
- 160 Dark: body text opaque, labels (textSec) at 7 : 1, dim text (hints, slot names) at about 5.9 : 1, a step apart.
- 162 a stack's bar is its emptiest item's.
Report each as ok, wrong (with a picture) or not run, plus the release check and any ZeD Lua errors.

Added after QA stopped the shoot (Nov 11):
- The Character window's Loot placeholder ("Tab content - placeholder") is gone; its drawer folds as the World
  window's does.
- 164, the notebook's grey box: the reader's flyer page (zedqa_reader runs just before) stayed placed, and its paper
  tone drew over the notebook. Fixed; the reader's tone draws only on a print.
The notebook window over the World window in that picture: tell Build if it's still there after the fix (159).

## 2. Then the gallery: `workshop/gallery/B11_RECAPTURE.md`
Changed since you last read it:
- Capture conditions: the game's Font Size 19px. On Windows, `zedqa_run.ps1` pins it for each run and puts the
  director's line back (not yet run on Windows).
- The four vanilla pictures (van_01, van_11, van_20, van_32) are retaken at 19px with ZeD off (the director).
- Hero shots 01 and 19: one source open. Two sources side by side draw the compact Name and Wt layout, so there is no
  Cond / Amt column there (by design).
- "What changed" lists 155 to 158; rows 11, 30, 31 and 34 say what to look for (hand icons, lowercase balloons).
- A folded Loot drawer makes the World window narrower than its old twin: intended, not one of 159's jumps.
- Your question on 06, 62 and 63: all three are already in a retake tier, so they are retaken at 19px either way.
- Your MainOptions finding (6 = Scale with window height) is recorded; the old gallery_t14 set has the oversized text.

## 3. Item 159, windows jumping and overlapping
Still yours to compare first: new captures against their old twins once the old set is on the Mac. Tell Build which
captures, which windows and at what scale. Expected changes that are not jumps: the Loot fold above, and the narrower
inventory at 1280 wide and 1366 x 768 (beta 11).

## Settled by the director today
A plus B for secondary text, dim text the faintest, a stack's bar its emptiest item, the belt only for left and right
hands, the change note and the Workshop description reframed around readability and access (approved change note;
the description waits on the director's read).
