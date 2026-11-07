"""Every ad on the book's pages, as the guide would print them (2x): a full fills a page; two halves, three thirds or
four quarters share one. Two sheets: the full and half pages, then the third and quarter pages.
python allpages.py  ->  Guide_ads_all_1.png, Guide_ads_all_2.png"""
from PIL import Image

PAPER = (245, 236, 210)
S = 2                                   # the previews are 2x
PW, PH = 440 * S, 628 * S               # a page's ad area
M, G = 40, 30                           # the page margin round the ads, the gutter between pages
FULL = ["full_ready_prep", "full_greenes_grocery", "full_crossroads_mall"]
HALF = ["half_well_regulated_militia", "half_better_bed_than_dead", "half_zacs_hardware", "half_body_chisel",
        "half_jamieton_army_surplus", "half_mccoys_lumber", "half_pharmahug"]
THIRD = ["third_maps_unlimited", "third_salt_river_bait", "third_pioneer_girls", "third_knob_creek_hunting",
         "third_aa_ron_hunting", "third_west_point_range", "third_nails_and_nuts", "third_time_4_sport",
         "third_zippee_market", "third_phils_pawn", "third_hit_vids", "third_rolling_fork_camp"]
QUARTER = ["quarter_xray_specs", "quarter_iron_mike", "quarter_safari_club", "quarter_brine_buddies",
           "quarter_learn_magic", "quarter_kentucky_seed_co", "quarter_kitten_knives", "quarter_purrfect_barkner",
           "quarter_motorbikes_and_more", "quarter_wizards_keep", "quarter_juke_box_bowling",
           "quarter_seat_yourself_furniture"]
SLOTS = {"full": [(0, 0)], "half": [(0, 0), (0, 318 * S)], "third": [(0, 0), (0, 423), (0, 846)],
         "quarter": [(0, 0), (225 * S, 0), (0, 318 * S), (225 * S, 318 * S)]}


def pages(names, kind):
    out = []
    n = len(SLOTS[kind])
    for i in range(0, len(names), n):
        pg = Image.new("RGB", (PW + 2 * M, PH + 2 * M), PAPER)
        for name, (x, y) in zip(names[i:i + n], SLOTS[kind]):
            pg.paste(Image.open("out/preview/%s.png" % name).convert("RGB"), (M + x, M + y))
        out.append(pg)
    return out


def sheet(pgs, path, cols=4):
    rows = (len(pgs) + cols - 1) // cols
    w, h = pgs[0].size
    sh = Image.new("RGB", (cols * w + (cols + 1) * G, rows * h + (rows + 1) * G), (70, 70, 70))
    for i, pg in enumerate(pgs):
        sh.paste(pg, (G + (i % cols) * (w + G), G + (i // cols) * (h + G)))
    sh.save(path, optimize=True)
    print(path, sh.size, len(pgs), "pages")


sheet(pages(FULL, "full") + pages(HALF, "half"), "Guide_ads_all_1.png")
sheet(pages(THIRD, "third") + pages(QUARTER, "quarter"), "Guide_ads_all_2.png")
