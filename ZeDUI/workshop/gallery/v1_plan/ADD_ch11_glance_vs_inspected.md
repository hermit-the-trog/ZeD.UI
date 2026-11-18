# Gallery 1.0 addition: item cards at a glance versus inspected (chapter "Item Cards", Nov 17 2026)

**The director's call (Nov 17 2026):** "Yes, add it. It should be with the other item info card showing different
types of info cards at a glance versus inspected."

**Why:** the book shows only the full card in the drawer (chapter 11 today: an apple and a machete). It never shows
the at-a-glance card, the light balloon beside a row that appears as the pointer or the controller lands on it (the
loot card, `ZeD_InvTip.lua`). The Workshop page promises "A card for every item, by the pointer as you loot", and no
picture backs it.

**Where:** the Item Cards chapter (spread id `item_cards`), with its cards. Design places it in the 1.0 layout and
writes its words. The printed text stays dry; the Angel line goes in the caption. Build and QA don't write copy.

## What the pictures must show

Three item types, each as a pair: **at a glance**, then the same item **inspected**.

| Type | Item | At a glance | Inspected |
|---|---|---|---|
| Food | the apple (as today) | the light balloon beside its row while looting, nothing else open | its full card in the drawer, with the nutrition label |
| Weapon | the machete (as today) | the balloon beside its row | its full card: condition and the combat facts |
| Clothing | a jacket or a shirt with some wear | the balloon beside its row | its full card: protection, insulation and wear |

For each pair, use the same item, the same place and the same moment: hover (or land the controller on) the row and
take the glance, then click it and take the inspected one.

**Capture rules (QA):**
- Standard as B19_RECAPTURE.md (4K, UI scale 1.75x, Dark + PZ Teal, list view, font 19px) and the gallery capture
  rules (under the weight limit, no debug lines, default windows).
- **The pointer:** hidden for the inspected pictures. For the glance pictures, the balloon is the subject, so show
  where the pointer sits, or use the controller: the balloon stands beside the focused row.
- The 1.0 rule: the window to one side or along the top, with the character and a lived-in place uncovered.
- The balloon is light in every theme (Nov 17), so it must read light here.

**Captures:** `zed_11g_food_glance`, `zed_11i_food_card`, `zed_11g_weapon_glance`, `zed_11i_weapon_card`,
`zed_11g_clothing_glance`, `zed_11i_clothing_card`. The food and weapon cards are retaken alongside their glances,
so each pair matches. They replace `zed_18_card_food` and `zed_19_card_weapon` in this chapter.
