# Handoff: the survival guide's copyright page (Nov 7 2026)

From design, for Build and then QA. The director, Nov 7: "can you give me the text on the inside cover, the publisher
note and info? I want to do a similar for the survival guide, make sure the writing style is the same." The model is
the znix manual's title spread (`ZeDUI/workshop/gallery/title_spread.py`): the copyright page on the left, the title
page on the right, in the publisher's dry register. Punch list item 103.

## The director's calls (Nov 7)

1. A copyright page like the znix manual's, line for line, in the same voice (no jokes in the small print).
2. **"Publications LLC both":** the division is "Division of Survival Emergency Publications LLC", on the copyright
   page and on the title page.
3. **The first edition is 1984:** the copyright line carries both years, "1984, 1987".

Still open (asked, not answered): the house ad's coupon names the division as a mailing address
(`UI_ZeD_Guide_Ad1_Coupon`: "mail this page to Division of Survival Emergency Publications, Muldraugh, Kentucky").
Leave it as it is unless the director says.

## Where it goes

The Full look's first spread today is a blank left page facing the title page
(`ZeD_SurvivalGuideBook.lua` ~536: `{ { kind = "blank" }, { kind = "title" }, { kind = "contents" }, { kind = "intro" } }`).
The copyright page takes the blank's place: copyright left, title right, as in the znix manual. One page for one page,
so nothing after it moves (the contents pages, the house ad before the introduction, the page numbers).

The sepia frontispiece that was to face the title page (SURVIVAL_GUIDE_DRAFT.md, "waits on a capture") would have
used that spot. It was never made, so nothing is lost now; if the director still wants one, it needs another place.

## The text

The first three lines come from keys the title page already has, so they follow its translations:

```
<UI_ZeD_Guide_BookTitle>: <UI_ZeD_Guide_BookSub1> <UI_ZeD_Guide_BookSub2>
<UI_ZeD_Guide_BookEdition>
<UI_ZeD_Guide_CopyBy>
```

In English: "Survive the Apocalypse: Survive an Outbreak Like It's a Vacation" / "Second Edition" / "by Stevie
Whetstone".

New keys (EN `UI.json`; every other language as the project's labeled AI drafts, the names left as they are):

```json
"UI_ZeD_Guide_CopyBy": "by Stevie Whetstone",
"UI_ZeD_Guide_Copy1": "Copyright © 1984, 1987 by Doidbros and Buzzlord Division of Survival Emergency Publications LLC. All rights reserved. No part of this book may be reproduced, stored in a retrieval system or transmitted in any form or by any means, electronic, mechanical, photocopying, recording or otherwise, without the prior written permission of the publisher.",
"UI_ZeD_Guide_Copy2": "Brand names in this book are trademarks of their respective holders and are used for identification only.",
"UI_ZeD_Guide_Copy3": "Limits of liability and disclaimer of warranty: the author and the publisher have used their best efforts in preparing this book and the methods in it. They make no warranty of any kind, expressed or implied, with regard to the methods or the advice in this book. The first aid in this book is no substitute for a doctor's care.",
"UI_ZeD_Guide_Copy4": "Technical review: the Doidbros and Buzzlord Field Testing Group.",
"UI_ZeD_Guide_Copy5": "Printed in the United States of America",
```

The printing line, `10 9 8 7 6 5 4 3 2 1`, is not a key (the title page draws its "1987" the same way).

Changed key, every language: `UI_ZeD_Guide_BookDivision` gets " LLC" after its name (EN: "Division of Survival
Emergency Publications LLC"). The title page's "1987" stays: it is the second edition's year.

Line for line against the znix page: its trademark line names ZNIX and Pears Software, this one has no product to
name; its disclaimer covers "the programs", this one "the methods", with the one sentence a survival book of the time
carried and the znix book doesn't (first aid); its "Technical review: the Doidbros & Buzzlord Docs Group" is this
book's Field Testing Group (the house ad sells "plain, tested manuals"). The guide spells the company "Doidbros and
Buzzlord" with "and", as its title page does; the znix manual keeps its "&".

## Layout (the znix page's way)

- The small print sits low on the page, as copyright pages set it: one block, bottom-aligned to the text block's
  foot (`U.PH - U.FOOT`), so Large text grows it upward and never past the foot. Measure the block, then draw.
- The book's body face (`F.text`, Old Standard) a step under the body size (about `U.CAP` = 10 at Small), left
  aligned and ragged (the znix page doesn't justify it), the full text-block width, wrapped with `wrapWords`.
- Spacing, from the znix page at 1080p: a 9 px gap after the "by" line, 7 px between paragraphs, 4 px more before
  "Printed in", and the printing line straight under it.
- No folio, like the title page (`drawPage` returns before `folio` for it).
- The © is in all of the book's faces (char 169 in `SdfOldRegular.fnt` and the rest), so it can be typed as is.

## QA

1. The first spread: copyright left, title right; the title page reads "Division of Survival Emergency Publications
   LLC" under DOIDBROS AND BUZZLORD.
2. At 1080p and 4K, Small and Large text: the block sits low, nothing past the foot, nothing clipped at the sides.
3. The © draws (not a box or a question mark).
4. Another language: the copyright page translated, the names as they are.
5. Nothing else moved: the contents, the introduction, the house ad before it, the page numbers.

## Files

- The model: `ZeDUI/workshop/gallery/title_spread.py` (the znix manual's copyright page and title page).
- The book: `42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua` (`pages` ~536, `drawTitlePage` ~1150, `drawPage`
  ~1691); the strings: `42/media/lua/shared/Translate/<lang>/UI.json`.
