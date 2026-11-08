# Handoff: the survival guide's ads (Nov 6 2026)

From design, for Build and then QA. **After the beta 6 regression, not before:** nothing here touches `42/` yet. The
director, Nov 6: "And with that, the ads are done. We can build a handoff." The plan, every decision and every round
of the director's notes: `docs/plans/GUIDE_ADS_PLAN.md`. Punch list item 98.

## What it is

The Full look's book ("Survive the Apocalypse", Doidbros and Buzzlord, 1987) has left-over space: whole pages the
layout leaves over, and flow pages a third or more empty. Today every one of them draws the same publisher's house ad.
They become the back pages of a 1987 paperback: 34 ads for the shops a player loots on the map (real Knox County
businesses first, invented ones for the gaps), in four sizes, each ad at most once per book, the ruled NOTES block
when the ads run out.

- **Full look only.** The Simple look gets no ads (unchanged).
- **English only.** The words are part of the art; the rest of the book stays translated. The house ad stays as it is
  (drawn in Lua, translated) and joins the full-page rotation.
- **Evergreen copy.** A book sits on the shelf for years: no dates, no "this week", no season.

## The art

34 PNGs, ink on transparent, **drawn at 2x** (one design px is one screen px at 1080p, so the art is twice that):

| Size | Design px (the slot) | PNG | Count |
|---|---|---|---|
| full | 440 x 628 | 880 x 1256 | 3 (+ the house ad in Lua) |
| half | 440 x 310 | 880 x 620 | 7 |
| third | 440 x 205 | 880 x 410 | 12 |
| quarter | 215 x 310 | 430 x 620 | 12 |

**The ship set:** `Zomboid/ZeD_design_refs/ads/final/` holds all 34, current as of this handoff (the same files are
split by batch in `ads/batch1/` and `ads/batch2/`). Build copies them to `42/media/textures/ZeD/guide/ads/`, the file
name unchanged (`<size>_<name>.png`).

The pictures' light tints are mixed against the book's paper (#f5ecd2) and its ink (#232a3a): if either color changes,
re-render (below), don't tint the PNGs.

## The list (for Lua)

```lua
-- the guide's ads (design, Nov 6 2026): media/textures/ZeD/guide/ads/<name>.png, 2x art; sizes in design px
ZeD.GuideAds = {
    size = { full = { 440, 628 }, half = { 440, 310 }, third = { 440, 205 }, quarter = { 215, 310 } },
    full = { "full_ready_prep", "full_greenes_grocery", "full_crossroads_mall" },
    half = { "half_well_regulated_militia", "half_better_bed_than_dead", "half_zacs_hardware", "half_body_chisel",
             "half_jamieton_army_surplus", "half_mccoys_lumber", "half_pharmahug" },
    third = { "third_maps_unlimited", "third_salt_river_bait", "third_pioneer_girls", "third_knob_creek_hunting",
              "third_aa_ron_hunting", "third_west_point_range", "third_nails_and_nuts", "third_time_4_sport",
              "third_zippee_market", "third_phils_pawn", "third_hit_vids", "third_rolling_fork_camp" },
    quarter = { "quarter_xray_specs", "quarter_iron_mike", "quarter_safari_club", "quarter_brine_buddies",
                "quarter_learn_magic", "quarter_kentucky_seed_co", "quarter_kitten_knives",
                "quarter_purrfect_barkner", "quarter_motorbikes_and_more", "quarter_wizards_keep",
                "quarter_juke_box_bowling", "quarter_seat_yourself_furniture" },
}
```

## The slots today (`42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua`, line numbers as of Nov 6)

| Slot | Today | Becomes |
|---|---|---|
| A whole page (`kind = "ad"`, added at ~365 before a topic that faces its rules page, and ~446 to even the last spread) | `drawAdPage` (~930): the house ad | the next **full** ad; the house ad is one of the rotation; when they run out, the NOTES block over the whole text block (the filler's NOTES code, from the top) |
| A flow page a third or more empty (`k = "filler"` item at ~443; the rules pages' foot at ~721) | `drawFiller` (~798): `drawHalfAd` at 330 tall, then the 186 box, then NOTES | the largest that fits, below |

`drawFiller`, new order (u = the book's scale):
1. The First Days checklist first, when it fits (unchanged).
2. Room for 310u (today's `halfH = 330 * u` becomes 310, the art's height): a **half**, or a **pair of quarters** side by side (215 + 10 gutter + 215 = 440). The book
   alternates (a half, then a pair) so both sizes get used; when one list is empty it takes the other. A pair needs two
   quarters left; with one, take a half; with neither, go on.
3. Room for 205u: a **third** (it replaces the 186 box).
4. Whatever is left: the ruled NOTES block (unchanged).

Gaps: 18u after each ad, as today. A slot that has room but no ad left falls through to the next step, never a repeat.

## The deal

- **Each ad at most once per book.** Deal once, when the pages are laid out (`bk.pages` is built), and store the
  chosen ad on the page (`p.ad`) or the filler item (`it.ads`). Not at draw time: flipping pages must not reshuffle.
- **The same book reads the same each time it opens:** shuffle each size's list with a seeded generator. The seed is
  Build's call; it must be stable for a given book (for instance the item's ID, kept in its modData) and differ
  between books, so two copies don't print the same back pages.
- The house ad takes a place in the full-page shuffle like the three full ads.
- If the text size, pad or keyboard wording, or the language changes the layout, re-deal with the same seed: the
  order stays, only how far down the lists the book gets moves.

## Drawing

- `drawTextureScaled(tex, x, y, w * u, h * u, 1, 1, 1, 1)` with the design size from `ZeD.GuideAds.size`; at 4K
  (u = 2) that is the PNG's own pixels. The pixel pictures inside are drawn one art pixel to one design pixel, so
  they want whole-number scales; at a scale like 1.75 they soften a little under linear filtering. Point filtering for
  these textures, if the engine allows it per texture, keeps them crisp; Build's call.
- Load each texture when its page is first drawn, not all 34 at once (all 34 at 2x are about 60 MB as RGBA once
  loaded).
- Placement: full ads at the text block (x + M, top MT); fillers at the text block's left edge (`tx`), width 440u.

## QA

1. The Full look at 1080p and at 4K (ZeD scale 1.75x), Small and Large text, pad and keyboard wording: page through
   the whole book and log each slot: full / half / pair / third / NOTES. **The count is the open question:** whether
   34 ads cover every slot (the plan's "How many slots"), or the book shows NOTES and wants more ads.
2. No ad twice in one book; no ad clipped by a page edge or the folio; a pair's two quarters level.
3. Close and reopen: the same ads on the same pages. A second book (a different item): a different order.
4. Simple look: no ads. Another language: the ads in English, everything else translated, the house ad translated.
5. Pixel pictures crisp at 4K; at 1080p and 1.75x, readable (the small print in the bats' labels and the pawn box is
   the finest).

## Re-rendering (if an ad changes)

In `ZeDUI/tools/guide_ads/` (Python 3 with numpy and Pillow; Node with Playwright):
- `python adpx.py [name ...]`: the pictures, into `px/` (the pixel engine, `tools/dashpx/engine.py`). A plain run skips
  Iron Mike: his picture is the in-game capture made by `mike_ink.py` (with `dumbbell.py`), and the old drawn design
  would overwrite it.
- `python syncimg.py`: sizes each ad's `<img>` to its picture. `node render.js [name ...]`: every ad (or the ones
  named) into `out/preview/` (on paper) and `out/final/` (transparent), 2x.
- `python allpages.py`: every ad on the book's pages, `Guide_ads_all_1.png` and `_2.png`.
- West Point's target is the outline of ZeD's equipment doll (`target_outline.py` makes `refs/avatar_outline.png`).
- The layouts are `src/*.html` with `ad.css` and `ad.js`; the faces are OFL (Fontsource) in `fonts/`.

## Notes for whoever touches the copy

- Phone numbers: all (502) 555-01xx, each its own (29 numbers; the mail-order ads have addresses instead).
- No real brands: the dog food bag says DOG FOOD, the bats are Super / Wood / Aluminum / Youth Slugger, the mall's
  stores are invented. Kitten Knives is the game's own brand. The Crossroads signpost (BONES / THUGS / HARMONIES /
  MEET YOU THERE) and "Meet you at the Crossroads!" are the director's nod to Bone Thugs-n-Harmony; no lyrics.
- Two ads both offer a Tuesday senior discount (Zac's Hardware, Pharmahug); the director has seen both and kept them.
- Rolling Fork Camp & Trail is invented (the game has camping stores, none named); Motorbikes and More and Knob Creek
  Hunting are text only (the game has no motorcycles).

## Files

- Ship set: `Zomboid/ZeD_design_refs/ads/final/` (34). By batch: `ads/batch1/` (12), `ads/batch2/` (22).
- The whole set on the book's pages: `Zomboid/ZeD_design_refs/ads/Guide_ads_all_1.png`, `_2.png`.
- The director's reference photos: `ZeD_design_refs/ads/refs/` (recliner, gas mask, IBC tote).
- Sources: `ZeDUI/tools/guide_ads/`. Plan and history: `docs/plans/GUIDE_ADS_PLAN.md`.
