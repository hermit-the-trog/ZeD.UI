# The survival guide's ads (design, Nov 6 2026)

The director, by voice, Nov 6: the Full look's blank spaces show the same house ad over and over. Fill them with ads for
the shops a player loots on the map: survival, guns, food, fishing, hardware, gyms, everything that fits a survival
guide. **Real Knox County businesses first; invented ones only to fill gaps.** Don't use the game's flyers or
newspapers (players should still find those, no spoilers): names only, our own copy.

## Settled (the director, Nov 6)

- **The look:** black and white, the back pages of a 1987 paperback: rules, coupons with dashed edges, clip art,
  halftone dots, phone numbers, "Est. 1962". The book is printed in 1987 by Doidbros and Buzzlord, Division of
  Survival Emergency Publications, so nothing a shop couldn't have had in 1987.
- **Four sizes:** quarter, third, half, full page.
- **No repeats:** each ad once per book. More slots than ads: the slot takes the ruled NOTES block, never a repeat.
- **Jokes:** in, here and there ("Veterans get a free box of rounds with the purchase of a box of rounds").
- **Simple look:** no ads.
- **English only:** the words are part of the art (PNGs); other languages keep the rest of the book translated.
- **Evergreen copy (the director, Nov 6: "These can't be weekly specials or monthly specials, because this is a
  published book, not a magazine or quarterly").** A book sits on the shelf for years, so its ads sell the store, not
  this week: standing offers only ("every day", "always", layaway, senior discount Tuesdays, a coupon "good at any
  location" with no expiry date). No sale dates, no "this week only", no "now through", no season's schedule.
- **Phone numbers:** area code 502 (all of this part of Kentucky in 1987; 270 split off in 1999), exchange 555.
- **Copy lines to work in:** layaway, installment plans, Visa and MasterCard, senior discount Tuesdays, clip this
  coupon, free estimates, open 7 days, call for directions.
- **Mail-order ads** (the back of Boys' Life and the comics): X-ray specs, magic, instant pets, the muscle course,
  sell seeds and win prizes.

## The slots today (measured in ZeD_SurvivalGuideBook.lua, design px = screen px at 1080p)

The page is 520 x 690, margins 40 at the sides, 30 at the top, 26 at the foot: a text block 440 wide.

| Slot | Size | Where in the code |
|---|---|---|
| Full page | 440 x 628 | `drawAdPage`: a page the layout leaves over (before a topic that faces its rules page, and the last page) |
| Half page | 440 x 330 | `drawFiller` -> `drawHalfAd`: a flow page a third or more empty |
| "Quarter" | 440 x 186 | `drawFiller`: the boxed house ad, when the half doesn't fit |
| Third | none yet | |

Every one draws the same publisher's house ad (UI_ZeD_Guide_Ad1_*).

### Proposed four sizes

| Size | Design px | Art (2x PNG) | Notes |
|---|---|---|---|
| Full | 440 x 628 | 880 x 1256 | the left-over pages |
| Half | 440 x 310 | 880 x 620 | a horizontal half; 310 so two quarters fill the same hole |
| Third | 440 x 205 | 880 x 410 | a horizontal strip; replaces today's 186 box |
| Quarter | 215 x 310 | 430 x 620 | a vertical quarter, two side by side (a 10 px gutter) where a half fits |

Where a half fits, the book alternates: a half ad, then two quarters, so both get used. PNGs are ink on transparent
(the ink color #232a3a), so they lie on the book's own paper; drawn at the book's scale like its clips.

### How many slots

Not counted yet: it moves with the text size (Small / Large), keyboard or pad wording, and the language. QA logs it
after the beta 6 regression (full / half / third / quarter, each text size, pad and keyboard). The first batch
(34 ads) is meant to cover it; the count says whether we need more.

## The businesses

From the game's own lists: the key and business-card names (IG_UI.json, IGUI_*), the town blurbs on the spawn
screen, and the radio commercials. Flyers and newspapers were only checked for overlap: "flyers" below means the name
also appears there (the name is fine, nothing of their content is used).

### Full page (4)

| Ad | Real? | Where | The pitch |
|---|---|---|---|
| Ready Prep | real (radio ads; flyers) | survival store | "Freeze-dried meals with a 25-year shelf life. You'll thank us later." Generators, water barrels, ask about our installment plan |
| Greene's Grocery | real (radio: Frank Greene; flyers) | grocer | the store, not a sale: "Every day low prices" on the staples a survivor stocks (canned goods, rice, beans, flour, bottled water) by the case, "Lasts forever, just like our low prices"; case discounts, we deliver, a coupon with no expiry date |
| Crossroads Mall | real (flyers) | Valley Station | a mall directory: 60 stores under one roof, open 7 days, a few real stores on the list |
| Doidbros and Buzzlord | the publisher | | the house ad, kept as is |

### Half page (7)

| Ad | Real? | Where | The pitch |
|---|---|---|---|
| Well Regulated Militia | real (Irvington blurb) | gun store, Irvington | veterans: a free box of rounds with the purchase of a box of rounds; layaway (**sample drawn**) |
| Better Bed Than Dead | real (flyers) | mattress store | "Why settle for an uncomfortable cot when you can sleep like a king on the Survival King 2000, the bed of tomorrow. Maybe." Layaway |
| Zac's Hardware | real | hardware | "Plywood, nails and padlocks. Stock up before the next big storm." Free key cutting |
| Body Chisel Gym and Fitness | real | gym | "Get in shape for summer! Our members can outrun anything." |
| Jamieton Army Surplus | real | surplus | "Just because it's U.S. surplus doesn't mean it's surplus to us." Gas masks, canteens, cots, ponchos |
| McCoy's Lumber | real (Muldraugh's "huge lumberyard") | lumberyard | "For those that like to lay some wood, we cut it, stack it, and bring it to you." Free estimates, contractor prices, "we deliver" |
| Pharmahug | real brand (flyers) | pharmacy | "Ask about our new 24-hour prescription line. Feeling feverish? We're here for you." |

### Third page (12)

| Ad | Real? | Where | The pitch |
|---|---|---|---|
| Knob Creek Hunting | real | hunting | camo, tree stands, deer season (text only since round 2) |
| A.A. Ron Hunting Supplies | real | hunting | the name says it twice |
| West Point Gun Range and Hunting Center | real | West Point | lanes by the hour, ladies' night |
| Nails & Nuts | real (flyers) | hardware | the second hardware store |
| Time 4 Sport | real (flyers) | sporting goods | Louisville Slugger-style bats, "for the big game" |
| Salt River Bait & Tackle | **invented** (no bait shop in the game) | fishing | "Live bait, open 24 hours. The worms never sleep, and neither do we." |
| Zippee Market | real (radio, flyers) | convenience | ice, batteries, open late |
| Knox County Pioneer Girls, Troop 502 | **invented** (the game has Scout Cookies but no troop) | cookies | "Cookies by the case! Shelf-stable for months." (502) 555-0126 |
| Maps Unlimited | real | maps | "Know every road out of town." |
| Phil's Fine & Fair Pawn Shop | real (radio) | Louisville | checks cashed: payroll, cashier's, and personal checks with a major credit card |
| Hit Vids | real (March Ridge blurb; flyers) | video rental | rent two, get one free; be kind, rewind |
| Rolling Fork Camp & Trail | **invented** (the game has camping stores, none named; the Rolling Fork is the river at West Point) | camping | the director's lines: "It's not a fanny pack. It ain't a purse. This is a professional survival kit. You gotta have man muscles just to buckle this thing. Not for you milk drinkers out there." (502) 555-0139 |

### Quarter page (12)

| Ad | Real? | The pitch |
|---|---|---|
| X-Ray Specs | **invented** brand | "See through walls! Know what's waiting in the next room!" $1.98 plus postage |
| Learn Magic | **invented** | "Make your enemies disappear!" A vanishing coin trick free |
| Brine Buddies | **invented** (instant pets) | "Instant pets that never get sick!" |
| Iron Mike's Muscle Method | **invented** (the muscle course) | "Tired of getting sand kicked in your face? Or getting bitten?" |
| Kentucky Seed Co. | **invented** | "Sell seeds, win prizes!" and "Grow your own. You may need to." |
| The Kentucky Gentlemen's Safari Club | **invented** | "For the sportsman who has hunted everything. The ultimate quarry. Membership by referral only. Discretion assured." A phone number, no address |
| Kitten Knives | real brand (radio) | mail-order knives, "as heard on the radio" |
| Purrfect Barkner Pet Supplies | real | the director's copy: "Big bags for big dogs." 50-pound bags of dog food, cat food by the caseload, leashes, collars, and chains. "Not just for Sparky. They help put a spark in the bedroom too." |
| Motorbikes and More | real | "Beat the traffic" (text only since round 2: the game has no motorcycles) |
| Wizard's Keep | real (Irvington blurb; flyers) | games and dice, "Roll for initiative" |
| Juke Box Bowling | real | league nights all year, shoe rental, "Strike up some fun" |
| Seat Yourself Furniture | real (flyers) | "The best seat in the bunker." Recliners, layaway, free delivery, free haul away |

## Type

The game's newspapers and flyers use its own distance-field faces (media/fonts/*.fnt): Open Sans (four weights),
Old Standard TT (four), Roberto Sans Bold Italic and Caveat. Open Sans, Old Standard TT and Caveat are OFL faces, so
the PNGs are set from their font files (Fontsource), the same faces as the game's print. Roberto Sans has no font
file, only the game's atlas; the book's headings use it, so the ads using other type reads right (real ads never
matched the editorial type).

## Batch 1 (Nov 6, drawn)

The director, Nov 6: "Go for your next move" (the proposed four sizes and the lineup taken as given; the game's
faces plus a few 1987 display faces for variety). Twelve ads, all four sizes, in `tools/guide_ads/src/`; PNGs in
`Zomboid/ZeD_design_refs/ads/batch1/`, laid out on book pages in `Guide_ads_batch1.png`.

- Full: Ready Prep.
- Half: Well Regulated Militia, Better Bed Than Dead, Zac's Hardware, Body Chisel Gym and Fitness.
- Third: Salt River Bait & Tackle, Knox County Pioneer Girls Troop 502, Maps Unlimited.
- Quarter: X-Ray Specs, Iron Mike's Muscle Method, the Kentucky Gentlemen's Safari Club, Brine Buddies.

Pictures (the director, Nov 6: "any of the images need to use our pixel art"; batch 1's vector clip art was the storyboard): every picture is drawn in ZeD's pixel art, the dashes' engine (tools/guide_ads/adpx.py on tools/dashpx/engine.py: height field, material ramps, lit, shadowed, no blending), printed in the book's one ink: each ramp runs from the paper to the ink. One art pixel = one design pixel.

One view (the director, Nov 6: "get all the perspectives right"; two rounds of revision): every picture is seen from the front and a little from above, the same for all. A level circle (a lid, a ripple, a brim, a crown's band, a cookie) is an ellipse 0.26 as tall as it is wide (`VIEW` in adpx.py); print, bands and ribs on a round surface bow down through the middle and close up toward the sides; print on a flat face lies in that face's plane; parts that stand together touch (the lantern's tubes, cap and bail). Round 1: the lantern's round parts, the bed and crown in three-quarter view, the padlock's top, the dumbbell turned so its plates are discs, the ripples, the cookies, the compass case's depth, the specs' temples, the helmet's band, the fishbowl's rim, water and foot. Round 2: the mattress's top lit and its side a step darker, the nails lying on the ground, shorter temples, and the layouts the bigger pictures pushed (Body Chisel, Brine Buddies).

Round 3, the director's notes (Nov 6): kept as they were: the rifle, the hat, the X-ray specs, the Pioneer cookies, the fish tank. Changed: the bed redrawn in the cookie box's three-quarter axes (one set for every part) with a real pillow; Zac's Hardware is the padlock alone, bigger (no hammer, no nails); Iron Mike's arm rebuilt from its muscles as one smooth body; the tank holds sea monkeys (brine shrimp, flat ink silhouettes), not fish; the bait shop's picture is a hook lying on its side with its line, a bobber and a split shot; the compass's glint is gone (it covered the N); the dumbbell is square to us with the collars outside the plates they hold; the crown's band is in front of its points.

Round 4 (Nov 6): the Survival Mattress 2000 is ten layers deep (the director: "10 layers of high quality mix of compressed foam cushioning and 1 million rub tested fabric"; a cot is "a stick and some legs"); its bullets say so, with a handwritten "10 layers!". Iron Mike's arm: fingers curling into the fist, the thumb across, no shadow at the wrist, fuller muscle under the biceps.

Next, Iron Mike's picture becomes the game's own avatar (the director, Nov 6, from a photo: a man in a fitted white T-shirt curling a dumbbell, three-quarter view, head bowed, the dumbbell up by his face, lit hard from one side against black): the player character in a white T-shirt doing the game's dumbbell curl, framed close at the top of the lift, lit from the side at night, captured in game, then printed in the book's ink (the paper-to-ink ramps). The photo is reference only (ZeD_design_refs/ads/ref_iron_mike_curl.png); nothing of it is copied. Waiting for the beta 6 regression to finish (the game is QA's until then), Iron Mike only.

Round 5 (Nov 6, evening): Iron Mike's picture is the game's own man. The director: use Spongie's Character Customisation's
muscle texture ("there's like a muscle body texture in there") and give him a dumbbell. Captured at 4K through the QA bridge
(`tools/qa/zedqa_iron_mike2.lua`, run with `zedqa_mods_run.ps1 -ModList iron_mike_mods.txt`, SPNCC copied into
`Zomboid/mods` for the -nosteam launch; the ZeD-QA save is put back from its snapshot): a male stand-in on the UI model, the
"player" anim set, the fitness state with ExerciseType = bicepscurl, a white tee, jeans and Base.M_Muscle at texture choice 5
(M_MuscleStrong01). The frame used: `zqa_mike2_sw_01.png` (the top of the lift, side on, the fist by his face). A UI model holds
nothing in its hands (round 3, `zedqa_iron_mike3.lua`: the real curl in the world does carry the dumbbell, but from above,
small, among the cows), so the game's dumbbell is drawn into his fist (`tools/guide_ads/dumbbell.py`: chrome bar, two black
plates a side seen near edge-on, chrome collars). `tools/guide_ads/mike_ink.py` keys the capture, cuts it to 112 x 104 and
prints each material on its own ramp (tee on "w", skin "m", hair "k", denim "d"), lit hard from the left, an ink line where
he meets the paper. The old drawn arm is kept as `px/iron_mike_arm_drawn.png`. Touched up (the director: "Check the
wrist ... it looks weird in a photo"; then, of a first try that also rounded the fist: "All I did was close in the
triangle from the hand to the wrist"): the game's low-poly hand leaves a notch on the lit side between the fist and the
forearm; `mike_ink.py` fills that triangle, the edge running straight from the fist down to the forearm, and changes
nothing else (the fist keeps its shape).

`render.js` fix (Nov 6): the final pass only changed the URL's hash, which does not reload the page, so every
`out/final/*.png` came out on paper instead of transparent. It now loads about:blank first; all twelve finals re-rendered
(ZeD_design_refs/ads/batch1).

Ready Prep (the director, Nov 6): the 55-gallon drum is now a white plastic water cube in a steel cage on a wooden pallet,
its label "WATER / 55 GAL / SEALED WITH BPA" (the chemical 2000s bottles bragged about being free of); the price line reads
"Water cubes, sealed with BPA for longevity $39.95".

## Batches 2 to 4 (Nov 6, drawn: the rest of the lineup)

The director: "continue with generating the rest of the ads." Twenty-one more, the same way as batch 1 (a pixel picture in
`adpx.py`, a page in `src/`), so all 33 of the lineup are drawn (the publisher's house ad stays as it is). PNGs (ink on
transparent, 2x) in `ZeD_design_refs/ads/batch2/`; review sheets `Guide_ads_batch2.png`, `_batch3.png`, `_batch4.png`
(`sheet2.py` makes them).

- Full: Greene's Grocery (a grocery sack with a loaf, a box of rice and two cans; case prices on the staples; a $1 coupon
  that "never expires. Neither do our beans."), Crossroads Mall (a crossroads signpost; a store directory with five of the
  lineup's stores and invented ones for the rest, no real chains: Shoe Corral, Radio Hut, Gem Gallery, Lucky Panda...;
  "Plenty of exits").
- Half: Jamieton Army Surplus (a G.I. gas mask), McCoy's Lumber (a stack of 2x4s and a hand saw), Pharmahug (a prescription
  bottle with its push-down cap, tablets).
- Third: Knob Creek Hunting (a buck's rack on a plaque), A.A. Ron Hunting Supplies (a duck decoy; "It's pronounced
  'Aaron.'"; redrawn after the director's three photos of old carved decoys: a low loaf body with a flat bottom and the
  tail rising behind, the round head set down on the chest with no neck, the bill straight out, a glass eye, worn dark
  paint with the white flank, a wing patch, carved feather scallops and chips showing the wood; no stand), West Point Gun Range (a silhouette target with a tight group), Nails & Nuts (a nut, a bolt, two nails), Time 4
  Sport (a bat and ball), Zippee Market (a flashlight and two D cells), Phil's Pawn (the three brass balls), Hit Vids (a VHS
  cassette, "Be kind, rewind"; redrawn after the director's reference photo: the ribbed hinged door across the top with
  its arrow, the ribbed shell, the two side windows round on their outer ends, the full reel left and the near-empty one
  right, the label between them; a second pass, "Take another pass at vhs", sets the proportions measured off the photo:
  the door 23% of the height, windows 47%, the band below 22%; windows a fifth of the width each, round-cornered on their
  outer ends, the label 40% between them; one arrow and the latch notch on the door).
- Quarter: Learn Magic (a top hat, wand and coin), Kentucky Seed Co. (a tomato seed packet and a sprout), Kitten Knives (a
  hunting knife), Purrfect Barkner (a 50-lb sack and a bowl), Motorbikes and More (a full-face helmet), Wizard's Keep (a d20
  and a d6), Juke Box Bowling (a pin and a ball), Seat Yourself Furniture (a recliner with its footrest out).

Phone numbers all (502) 555-01xx, each its own. Copy is evergreen (no dates, no "this week").

The director's notes on batches 2 to 4 (Nov 6), all redrawn (review sheet `Guide_ads_notes_round.png`):
- West Point: "the shooting target is weird": now white paper on two binder clips from the range's wire, a black bust
  (head, neck, sloping shoulders), the scoring rings as white ovals with their numbers, a tight group in the ten.
- Knob Creek: "the hunting trophy needs another pass": the beams sweep out, up and in from the burrs; the tines rise
  straight up off them; a leather-covered skull plate on a routed shield plaque.
- Zippee: "the flashlight needs just a little bit of cleanup": a clean barrel, knurling on the grip only, the switch,
  the bell and an edge-on bezel and lens, the tail cap.
- Phil's Pawn: "I'm not sure what that pawn shop thing is supposed to be": the three balls gave way to a gold pocket
  watch with Phil's pawn ticket tied to its bow.
- Learn Magic: "The magic wand is going through the hat": the hat sits upside down with a rabbit's ears out of it; the
  wand lies on the table in front.
- Kentucky Seed Co.: "not in a pot ... just in a cylinder of dirt": a tapered clay pot with a rolled rim, soil, a seedling.
- Kitten Knives: refined: a ground edge bevel the length of the blade, the clip and swedge, a choil, a little cat's head
  after the etched name, stacked leather with spacers, an aluminum pommel.
- Purrfect Barkner: the bowl "very full but not overflowing" (a heap of kibble piece by piece above the rim); the bag
  "flabby": slumped and rounder at the foot, the top rolled and stitched, creases where it settles.
- Motorbikes and More: "what the hell is that?": a motorcycle side on (spoked wheels, fenders, fork, headlamp, tank,
  seat, finned engine, exhaust, kickstand) in place of the helmet.
- Wizard's Keep: "I'd like to see you roll anything other than a 20 with that d20": a true icosahedron, one face toward
  us, the three faces sharing its edges and six round the rim each lit by its own slope; 20 among 2, 8 and 14.
- Juke Box Bowling: the mark below the thumb hole is gone.
- Seat Yourself: "you're not going to be seating yourself in that furniture until you put it together": side on, the
  padded arm panel to the floor with its rolled top and scroll, the back leaning back behind it, the seat over the arm,
  the footrest out in front on its scissor linkage.
- Jamieton: the gas mask again: a faceblank wide at the eyes narrowing to the chin, its edge seal, big eyepieces in
  rings, a small raised nose, the voicemitter on the chin, the canister on the cheek, a head harness with buckles.

The director's notes, round 2 (Nov 6; review sheet `Guide_ads_notes_round2.png`, 9 ads):
- Motorbikes and More: text only ("we don't have to have a photo on all of them ... ditch the motorcycle, because
  there's not really motorcycles in the game ... just fill it up with text instead"): BEAT THE TRAFFIC. set big, "Two
  wheels go where four can't. Up to 100 miles to the gallon.", and an "And the more" list (helmets and leathers;
  gloves, goggles and boots; tires, chains and batteries; tune-ups while you wait; we buy used bikes).
- Knob Creek Hunting: text only, the antlers gone ("Just fill it up with more text"): the name across the top, two
  lists (on the shelves, at the counter), the deer-processing burst, and "Ask the fellas at the counter where they
  hunt. They won't tell you."
- West Point: the target's silhouette is the game's own man ("Use one of the character outlines from one of the
  avatars"): ZeD's equipment doll in a ball cap and vest, arms down (`g5_equip_doll.png`), keyed off the panel, the
  slung rifle cut away, cut level at the hips (`tools/guide_ads/target_outline.py` makes `refs/avatar_outline.png`).
  Rings on the chest, a ring on the head, the group in the ten, a flier, and one in the head.
- Seat Yourself: redrawn from the director's photo (`ZeD_design_refs/ads/refs/recliner_ref.png`), every point traced
  from it: the back leaning well back, its padded outer panel and the head pillow; the arm a box with its back corner
  cut on the slant and a roll along the top; the release handle near the front; the thin footrest pad a little below
  the arm on a black steel linkage running from under the pad down to the chair's front, every bar pinned at both
  ends; a black steel base on two feet, one at the back and one at the front ("Just put one in the back, one in the
  front"). The headline is the director's, "The best seat in the bunker." (in place of "Recliners that put your feet
  up for you", "kind of boring"), over "Recliners, sofas, dinettes & bedroom sets. Free delivery, free haul away."
  The LAYAWAY burst stays (the director: "I love the layaway joke").
- Jamieton: the gas mask redrawn from the director's photo (`ZeD_design_refs/ads/refs/gasmask_ref.jpg`), traced the
  same way: the black rubber faceblank up to the harness tabs, two big round-cornered lenses in thick rims, the
  perforated voicemitter drum on the chin, the canister drum on its silver ring on the left cheek, six harness straps
  cut short with their buckles. The headline is the director's: "Genuine U.S. surplus, not surplus to us."
- Purrfect Barkner: the director's copy: "Big bags for big dogs." 50-pound bags of dog food, cat food by the
  caseload, leashes, collars, and chains; "Not just for your pets. Get one for your husband, too."
- Phil's Pawn: a "Checks cashed" box (payroll, cashier's, and personal checks with a major credit card) where the
  personal-checks note was; the ticket off the watch ("Remove the tag from the pocket watch") and under it, in Caveat,
  "Great money for great grandpappy's watch."
- New, third page: Rolling Fork Camp & Trail (invented: the game has camping stores, none named; the Rolling Fork is
  the river at West Point), (502) 555-0139. The director's lines word for word: "It's not a fanny pack. It ain't a
  purse. This is a professional survival kit. You gotta have man muscles just to buckle this thing. Not for you milk
  drinkers out there." The picture: the game's fanny pack (Base.Bag_FannyPackFront) laid out flat: a two-tone pouch,
  two zippers with their pulls, a PRO patch, the webbing out to both sides, a slider, and the side-release buckle.
- The lineup is now 35 ads (34 drawn plus the house ad): 4 full, 7 half, 12 third, 12 quarter.
- All 34 on the book's pages (`tools/guide_ads/allpages.py`): `Guide_ads_all_1.png` (the full and half pages) and
  `Guide_ads_all_2.png` (the third and quarter pages), 14 pages at 2x.
- A plain `python adpx.py` now skips Iron Mike (`CAPTURED` in adpx.py): his picture is the in-game capture
  (`mike_ink.py`), and the old drawn design would overwrite it.

The director's notes, round 3 (Nov 6; review sheet `Guide_ads_notes_round3.png`; `Guide_ads_all_1.png` and `_2.png`
redone):
- Ready Prep: the water cube is an IBC tote, after the director's two photos ("water tank pallet":
  `ZeD_design_refs/ads/refs/ibc_ref_1.jpg`, `_2.jpg`): the white tank in a cage of steel tube (rings at five heights,
  uprights on each face, the top rim), its fill cap on top, the drain valve low on the front, on a wooden pallet with
  its fork openings; the label plate on the cage reads WATER, 275 GAL (an IBC's size; the old drum's 55 GAL went with
  the drum), SEALED WITH BPA.
- Crossroads Mall: the signpost's four boards, each pointing its own way: BONES, THUGS, HARMONIES, MEET YOU THERE.
- Zac's: "The actual hook is not connected ... It's sitting behind it": the shackle's legs now run down into two
  holes in the body's top, each hole's front lip across the leg's foot.
- McCoy's: "just the lumber is fine. Just get rid of that saw": the stack of 2x4s alone (the picture 160 x 84).
- Better Bed: the Survival Mattress 2000 is the Survival King 2000 ("Since we have a crown in it, might as well take
  advantage of that").
- Time 4 Sport: "the head of the baseball bat is the wrong perspective. The ball is too big": four bats in rows, side
  on (the knob a flange edge-on, the barrel rounding off at its end), each with its model on the barrel: SUPER
  SLUGGER (dark), WOOD SLUGGER, ALUMINUM SLUGGER (grip tape), YOUTH SLUGGER (shorter); one ball at true size.

The director's notes, round 4 (Nov 6; review sheet `Guide_ads_notes_round4.png`; the all-ads sheets redone):
- Crossroads Mall: "Can the text on the Crossroads Mall signs be larger and ... align perpendicular with the board
  that it's written on?": the lettering is the 5 x 7 face, centered on each board's center line, every column riding
  the board's slope; the arrow tips now sit on the center line carried out (they had bent back toward level).
- Better Bed: a comma after the name, so it reads on: "SURVIVAL KING 2000, THE BED OF TOMORROW".
- McCoy's: the headline is the director's: "For those that like to lay some wood, we cut it, stack it, and bring it to
  you." The list moved down under it, the WE DELIVER! burst down to the lower right, clear of the list.

Round 5 (Nov 6; `Guide_ads_notes_round5.png`):
- Crossroads Mall: the handwritten line is "Meet you at the Crossroads!" (the director: "just like the Bone Thugs and
  Harmony song"), in place of "Meet you by the fountain!".
- Better Bed: "SURVIVAL KING 2000, THE BED OF TOMORROW. MAYBE." (the director: "Like, maybe if you survive until
  tomorrow"); the small line's letter-spacing 2.6 px so it stays clear of LAYAWAY.
- Jamieton: the headline is the director's, on two lines: "JUST BECAUSE IT'S U.S. SURPLUS / DOESN'T MEAN IT'S
  SURPLUS TO US." The picture, list, burst and note moved down 14 px under it.
- Purrfect Barkner: the last line is the director's: "Not just for Sparky. They help put a spark in the bedroom
  too." (in place of "Get one for your husband, too"), italic 11.5 px so it stays two lines.

Type: Old Standard TT, Open Sans, Caveat (the game's print faces) with Oswald (condensed gothic), Alfa Slab One,
Rye (woodtype) and Yellowtail (brush script). Clip art in SVG, shading in halftone dots.

## Building it

**Done (the director, Nov 6: "And with that, the ads are done. We can build a handoff").** The handoff:
`HANDOFF_design_guide_ads_20261106.md` (punch list item 98); the ship set, all 34 current: `ZeD_design_refs/ads/final/`.

- Each ad an HTML page drawn at 2x with Playwright (`tools/guide_ads/`), ink on transparent, into
  `42/media/textures/ZeD/guide/ads/`. Clip art drawn in SVG; shading in halftone dots.
- Build: the four slots in `ZeD_SurvivalGuideBook.lua`, an ad list (file, size), a deal per book with no repeats
  (seeded so a book reads the same each time it opens), the NOTES block when the list runs out, Simple untouched.
- Not before the beta 6 regression is done; nothing in 42/ until then.

## Batch 5: 32 more thirds (Nov 7, lineup)

The director, Nov 7: "Sure, use more third size ads." QA counted up to 30 third-size spaces a book that fall back to the
ruled NOTES block once the 12 thirds run out (`qa/QA_GUIDE_ADS_20261107.md`); 32 more thirds cover every reading. Lineup and
copy only, nothing drawn yet. Same rules as above: names from the game's lists, our own copy, 1987, evergreen, no flyer or
newspaper text ("flyers" below means the name also appears there). 27 real, 5 invented.

| Ad | Real? | Where | The pitch | Picture | Phone |
|---|---|---|---|---|---|
| Gas-2-Go | real (IGUI_Gas2GoKey (IG_UI.json); radio commercial (RadioData.json)) | gas station | Never let the needle touch E: fill the tank, then fill the cans. | A 5-gallon steel jerry can standing upright, its flat side toward us with the stamped X, the three handles across the top, the spout cap at the near top corner; a funnel lying on its side in front (its mouth an ellipse 0.26). | (502) 555-0103 |
| Nolan's Used Cars | real (IGUI_NolansUsedCars and IGUI_NolansUsedCarsKey (IG_UI.json); radio commercial (RadioData.json); name also on flyers) | used car lot | Every car on the lot starts. Most of them stop, too. | A car key on a split ring with a round paper price tag tied to the ring by a string, the tag lying a little turned with AS IS handwritten on it. | (502) 555-0104 |
| Car Fix-ation | real (IGUI_CarFixation (IG_UI.json); name also on flyers) | garage and towing | If it rolls in, it drives out. If it was towed in, we'll talk. | A four-way lug wrench lying flat on the ground, seen a little from above so its cross is foreshortened front to back, a spark plug lying across in front of it. | (502) 555-0106 |
| Louisville Motorshop | real (IGUI_VehicleNameStepVan_LouisvilleMotorShop (IG_UI.json, the shop's step van)) | auto parts | Batteries tested free; cars never die at a good time, so keep a spare. | A 12-volt car battery, its top seen a little from above with the two terminal posts and the row of six fill caps, a carry strap across; a pair of jumper-cable clamps lying in front. | (502) 555-0107 |
| Echo Creek Feed & Seed | **invented** (invented: the game has Farming Store keys (IGUI_FarmingStoreKey, IG_UI.json) but no name; Echo Creek's spawn blurb (Echo Creek, KY.json) says its people farm) | farm and feed store | Baby chicks by the dozen: a good hen lays most days and doesn't care what the news says. | A galvanized chicken feeder: a round hopper with a cone top over a round pan (the pan's rim an ellipse 0.26), a few grains of scratch scattered on the ground in front. | (502) 555-0109 |
| Brott Cattle Farm | real (the Irvington spawn blurb (Irvington, KY.json); name also in flyers and newspapers) | freezer beef and cattle | Freezer beef by the quarter or the side, cut and wrapped to order. | A cowbell hanging from its leather strap and buckle, front-on, its mouth an ellipse 0.26 with the clapper showing inside. | (502) 555-0110 |
| Thumbs of Green | real (IGUI_ThumbsofGreen (IG_UI.json); name also on flyers) | garden center and canning supply | Grow it, put it up, eat it later. We sell everything but the patience. | A galvanized watering can side-on, the spout and its rose out to the right, the fill opening on top an ellipse 0.26; a Mason jar with its ring lid standing beside it. | (502) 555-0111 |
| Five Alarm Firehouse Chili | real (the Brandenburg spawn blurb (Brandenburg, KY.json); name also on flyers) | chili restaurant | The old fire chief's recipe, hot enough to call the trucks; take a gallon home. | A cast-iron pot on three stubby legs, its rim an ellipse 0.26, a ladle standing in the chili, the lid leaning against the pot's side, a wisp of steam rising. | (502) 555-0114 |
| Mendy's Eatery | real (IGUI_MendysEatery (IG_UI.json)) | diner | Bottomless coffee: in thirty years nobody has found the bottom. | A thick diner mug on its saucer, handle to the right, the coffee inside (the mug's mouth and the saucer's rim ellipses 0.26), a curl of steam. | (502) 555-0116 |
| Knox Distillery | real (IGUI_VehicleNameKnoxDistillery and IGUI_VehicleNameVan_KnoxDisti (IG_UI.json, the distillery's van)) | bourbon distillery and liquor | Sip it slow; in a pinch it cleans a cut, starts a fire and steadies a hand. | A bourbon bottle with a wax-dipped neck running down in drips and a paper label reading KNOX, a short rocks glass with a finger of whiskey beside it (the glass's rim an ellipse 0.26). | (502) 555-0117 |
| First Baptist Chapel | real (IGUI_FirstBaptistChapelKey (IG_UI.json)) | church bake sale | Bake sale after every Sunday service: pray for us and we'll pray for you; the pie is extra. | A lattice-top pie in a fluted tin, its top an ellipse 0.26 with the lattice strips following it, a pie server lying in front. | (502) 555-0118 |
| The Rusty Rifle | real (IGUI_RustyRifleKey (IG_UI.json); name also on flyers) | gun shop and gunsmith | Our name is a joke. Our gunsmithing is not. | A cardboard box of rifle cartridges with its lid open and propped behind, the rounds standing in rows (their tips small ellipses), two loose rounds lying in front. | (502) 555-0121 |
| Invisible Sledgehammer Corp | real (IGUI_InvisibleSledgehammerCorp (IG_UI.json, the game's company names)) | striking tools (sold through hardware stores) | Pictured: our best-selling sledgehammer. Please do not misplace it. | A sledgehammer lying on its side drawn only as a dashed outline (head and long handle), nothing filled in, with its shadow printed solid on the ground under it. | (502) 555-0122 |
| Electron House | real (IGUI_ElectronHouse (IG_UI.json); name also on flyers) | electronics and radio | CB, scanners and shortwave: hear the news before it's news. | A walkie-talkie standing upright facing us: the antenna up, the speaker grille, the channel knob on top, the talk button on the side; its twin lying on its back behind it. | (502) 555-0123 |
| Plugged In Electrics | real (IGUI_VehicleNameVanPluggedInElectrics (IG_UI.json, the electrician's van)) | electrician and generators | When the lines go down, the lights stay on: generators sold and wired in. | A portable gas generator in its steel-tube frame, front-on and a little from above: the fuel tank on top with its round cap (an ellipse 0.26), the engine and pull-start at one side, the outlet panel facing us. | (502) 555-0124 |
| Worm of Books | real (IGUI_WormofBooks (IG_UI.json)) | used books | Bring two, take one. Books work without batteries. | A stack of three hardback books lying flat, a little askew, their tops seen from a little above, a ribbon bookmark hanging out of the top one. | (502) 555-0127 |
| Awl Work and Sew Play | real (IGUI_AwlWorkandSewPlay (IG_UI.json); name also on flyers) | fabric, sewing and leather | A stitch in time saves nine; a stitch in a jacket saves the jacket. | A wooden spool of thread standing on end (its flanges ellipses 0.26), a needle stuck through the wound thread, a stitching awl lying in front. | (502) 555-0129 |
| Barg-N-Clothes | real (radio commercial (RadioData.json)) | workwear and clothing | Boots that last, coveralls that take a beating; a clip-out coupon for boots. | A pair of leather work boots side by side, laced high, seen front-on and a little from above, the near boot a step ahead of the other. | (502) 555-0130 |
| Optima Eyes | real (IGUI_OptimaEyes (IG_UI.json); name also on flyers) | optician | See them before they see you; keep a spare pair in the glove box. | An eye chart card on a small easel stand, front-on: the big E at the top, rows of letters getting smaller below. | (502) 555-0132 |
| Family Dentistry | real (IGUI_FamilyDentistry (IG_UI.json)) | dentist | Gentle care for the whole family; we ask our patients only one thing: no biting. | A big molar standing up, its crown on top and its two roots below, a toothbrush lying in front of it. | (502) 555-0134 |
| Pet Health Pawmise | real (IGUI_PetHealthPawmise (IG_UI.json)) | veterinarian | Dogs, cats, horses and cattle; if your dog won't stop barking at the window, it may know something. | A dog bone lying flat with a stethoscope coiled around it, the chest piece in front (its disc an ellipse 0.26). | (502) 555-0135 |
| Pony Roam-O | real (IGUI_PonyRoamO and IGUI_PonyKey (IG_UI.json); radio commercial (RadioData.json); name also on flyers) | riding stable | A horse never runs out of gas. It does eat, but so do you. | A horseshoe hanging open-end up on a nail, its nail holes along it, a lead rope looped over the same nail and hanging beside it. | (502) 555-0136 |
| ABCDriving School | real (IGUI_ABCDrivingSchool (IG_UI.json)) | driving school | Learn to drive in ten lessons; our graduates can get anywhere, some of them very quickly. | A three-spoke steering wheel standing up and facing us (a near circle), the horn pad in the middle, a little of the column showing below. | (502) 555-0138 |
| Rosewood Fire Department: First Aid & CPR Classes | real (the Rosewood spawn blurb (Rosewood, KY.json: its fire department); IGUI_FireDeptKey (IG_UI.json)) | first aid and CPR classes | Free classes: learn to stop bleeding and start a heart; better here than on the job. | A closed metal first aid box seen front-on and a little from above, the carry handle on top, the latch, FIRST AID stenciled on the lid (no cross emblem); a roll of gauze in front. | (502) 555-0142 |
| Muldraugh Karate & Self-Defense | **invented** (invented: no martial arts school in the game (only a Boxing Ring key, IGUI_BoxingKey, IG_UI.json); Muldraugh from its spawn blurb (Muldraugh, KY.json)) | self-defense classes | Lesson one is running. Lesson two is breaking a grip. | A black belt tied in its square knot, laid flat and seen a little from above, the two ends hanging down from the knot. | (502) 555-0143 |
| MindPeace Insurance | real (IGUI_MindPeaceInsurance (IG_UI.json); radio commercial (RadioData.json)) | insurance | Ask about our coverage for acts of God. We have a form for each. | A small house with a pitched roof, an open umbrella over it, the umbrella's shaft planted in the ground beside the house. | (502) 555-0145 |
| Homeward Real Estate | real (IGUI_HomewardRealEstate (IG_UI.json)) | realtor | Wells, woodstoves and root cellars a specialty; ask about our listings with no neighbors. | A yard sign on a wooden post with its crossarm, the sign hanging from two hooks and reading FOR SALE, a small SOLD rider on top of it. | (502) 555-0146 |
| U-Store It | real (IGUI_UStoreItKey (IG_UI.json); name also on flyers) | storage units | Store what you can't carry: fenced, lit and gated, your lock and your key. | Three cardboard moving boxes, two on the bottom and one on top, taped shut, the top box's flaps open, seen front-on and a little from above. | (502) 555-0148 |
| Old Mill Water Company | real (IGUI_VehicleNameVanOldMill (IG_UI.json, the company's van); name also on flyers) | well drilling and pumps | When the city water stops, yours won't: wells drilled, hand pumps fitted. | A cast-iron pitcher pump on a short pipe stand: the handle up, the spout out toward us, the round cap on top (an ellipse 0.26), a tin cup under the spout. | (502) 555-0153 |
| Restwell & Sons Funeral Home | **invented** (invented: no funeral home is named in the game) | funeral home | Burial or cremation. We recommend cremation. | A round flower wreath on its three-legged wire stand, front-on, a ribbon sash across it. | (502) 555-0156 |
| Knox Lock & Key | **invented** (invented: the game's business cards include a Locksmith (IGUI_Locksmith, IG_UI.json) with no shop name) | locksmith | We get you in and keep them out. | A key ring with five keys fanned out below it, one an old skeleton key among the house and car keys. | (502) 555-0161 |
| Throw Your Voice! (Vocal-O Novelty Co.) | **invented** (invented: a comic-book mail-order ad (the plan's mail-order set)) | mail-order novelty | Make your voice come from the next room. Send them the other way. | A small booklet standing upright, its cover printed THROW YOUR VOICE over a few sound-wave lines, the little round tin voice thrower lying in front of it. | (502) 555-0164 |

The copy, as printed (bar line, deck, list line, foot):

- `third_gas_2_go` Gas-2-Go: BAR: GAS / DIESEL / KEROSENE DECK: Never let the needle touch E. Fill the tank, then fill the cans. We check your oil while you wait. LIST: GAS CANS / MOTOR OIL / ANTIFREEZE / ICE / ROAD MAPS / CLEAN RESTROOMS FOOT: OPEN 7 DAYS. WE ACCEPT VISA & MASTERCARD. (502) 555-0103
- `third_nolans_used_cars` Nolan's Used Cars: BAR: EVERY CAR ON THE LOT STARTS DECK: Most of them stop, too. Cash, trade-ins or easy installment plans. Bad credit, no credit, let's talk. LIST: PICKUPS / WAGONS / VANS / 4x4s / A FULL TANK WITH EVERY CAR FOOT: ON THE DIXIE HIGHWAY. CALL FOR DIRECTIONS. (502) 555-0104
- `third_car_fixation` Car Fix-ation: BAR: BRAKES / TUNE-UPS / TOWING DECK: Honest work at honest prices. If it rolls in, it drives out. If it was towed in, we'll talk. LIST: OIL CHANGES / MUFFLERS / RADIATORS / TIRES / ALIGNMENT / 24-HOUR TOWING FOOT: FREE ESTIMATES. VISA & MASTERCARD. (502) 555-0106
- `third_louisville_motorshop` Louisville Motorshop: BAR: AUTO PARTS FOR THE DO-IT-YOURSELFER DECK: Batteries tested free while you wait. Keep a spare. A car never dies at a good time. LIST: BATTERIES / BELTS & HOSES / FILTERS / SPARK PLUGS / JACKS / JUMPER CABLES FOOT: OPEN 7 DAYS. VISA & MASTERCARD. (502) 555-0107
- `third_echo_creek_feed_seed` Echo Creek Feed & Seed: BAR: FEED / SEED / FENCING / BABY CHICKS DECK: Chicks by the dozen. A good hen lays most days and doesn't care what the news says. LIST: LAYER FEED / SCRATCH / HAY & STRAW / FENCE WIRE / T-POSTS / SALT BLOCKS FOOT: CHARGE ACCOUNTS FOR FARMERS. (502) 555-0109
- `third_brott_cattle_farm` Brott Cattle Farm: BAR: FREEZER BEEF BY THE QUARTER OR THE SIDE DECK: Raised on Irvington grass, cut and wrapped to your order. A side fills a chest freezer and feeds a family for a year. LIST: SIDES / QUARTERS / GROUND BEEF BY THE 10 LB / JERKY / FEEDER CALVES / HAY FOOT: INSTALLMENT PLANS. CALL FOR DIRECTIONS. (502) 555-0110
- `third_thumbs_of_green` Thumbs of Green: BAR: GARDEN CENTER & CANNING SUPPLY DECK: Grow it, put it up, eat it later. We sell everything but the patience. LIST: VEGETABLE STARTS / HOES & RAKES / MASON JARS / LIDS & RINGS / PRESSURE CANNERS / FERTILIZER FOOT: SENIOR DISCOUNT TUESDAYS. (502) 555-0111
- `third_five_alarm_chili` Five Alarm Firehouse Chili: BAR: THE OLD FIRE CHIEF'S RECIPE DECK: Hot enough to call the trucks. Take a gallon home: it keeps in the freezer, if you can wait. LIST: BOWLS / CHILI DOGS / CORNBREAD / BY THE QUART OR THE GALLON / CATERING FOOT: OPEN 7 DAYS. IN BRANDENBURG. (502) 555-0114
- `third_mendys_eatery` Mendy's Eatery: BAR: BREAKFAST SERVED ALL DAY DECK: Bottomless coffee. In thirty years nobody has found the bottom. LIST: EGGS ANY STYLE / BISCUITS & GRAVY / MEAT LOAF / PIE BY THE SLICE / BLUE PLATE SPECIAL FOOT: OPEN 7 DAYS, 6 AM TO 10 PM. (502) 555-0116
- `third_knox_distillery` Knox Distillery: BAR: KENTUCKY STRAIGHT BOURBON DECK: Aged in charred oak. Sip it slow. In a pinch it cleans a cut, starts a fire and steadies a hand. LIST: TOURS / TASTING ROOM / GIFT SHOP / BY THE BOTTLE OR THE CASE FOOT: YOU MUST BE 21. CALL FOR DIRECTIONS. (502) 555-0117
- `third_first_baptist_bake_sale` First Baptist Chapel: BAR: BAKE SALE AFTER EVERY SUNDAY SERVICE DECK: Pies, cakes and the ladies' auxiliary's preserves. Pray for us and we'll pray for you. The pie is extra. LIST: PIES / CAKES / COOKIES / JAMS & PRESERVES / QUILTS / COFFEE FOOT: ALL ARE WELCOME. CALL FOR DIRECTIONS. (502) 555-0118
- `third_rusty_rifle` The Rusty Rifle: BAR: BUY / SELL / TRADE / REPAIR DECK: Our name is a joke. Our gunsmithing is not. Bring in grandpa's shotgun and we'll make it shoot again. LIST: RIFLES / SHOTGUNS / HANDGUNS / AMMUNITION / SCOPES / CLEANING KITS FOOT: LAYAWAY. VISA & MASTERCARD. (502) 555-0121
- `third_invisible_sledgehammer` Invisible Sledgehammer Corp: BAR: STRIKING TOOLS SINCE 1949 DECK: Pictured: our best-selling sledgehammer. Lifetime guarantee. Please do not misplace it. LIST: SLEDGES / MAULS / SPLITTING WEDGES / PRY BARS / FRAMING HAMMERS / AXES FOOT: AT FINE HARDWARE STORES. FREE CATALOG: (502) 555-0122
- `third_electron_house` Electron House: BAR: CB / SCANNERS / SHORTWAVE DECK: Hear the news before it's news. Walkie-talkies by the pair, batteries by the box. LIST: CB RADIOS / POLICE SCANNERS / WALKIE-TALKIES / ANTENNAS / BATTERIES / REPAIRS FOOT: INSTALLMENT PLANS. VISA & MASTERCARD. (502) 555-0123
- `third_plugged_in_electrics` Plugged In Electrics: BAR: GENERATORS SOLD AND INSTALLED DECK: When the lines go down, the lights stay on. Transfer switches wired to code. LIST: PORTABLE GENERATORS / TRANSFER SWITCHES / WIRING / PANELS / SERVICE CALLS FOOT: FREE ESTIMATES. LICENSED & INSURED. (502) 555-0124
- `third_worm_of_books` Worm of Books: BAR: USED BOOKS BOUGHT, SOLD & TRADED DECK: Bring two, take one. Books work without batteries. LIST: HOW-TO / COOKING / FIRST AID / WESTERNS / MYSTERIES / PAPERBACKS 3 FOR $1 FOOT: OPEN 7 DAYS. (502) 555-0127
- `third_awl_work_sew_play` Awl Work and Sew Play: BAR: FABRIC / NOTIONS / LEATHER DECK: A stitch in time saves nine. A stitch in a jacket saves the jacket. Classes for beginners. LIST: THREAD / NEEDLES / PATCHES / DENIM / CANVAS / LEATHER & AWLS / MACHINE REPAIR FOOT: LAYAWAY ON SEWING MACHINES. (502) 555-0129
- `third_barg_n_clothes` Barg-N-Clothes: BAR: WORKWEAR FOR THE WHOLE FAMILY DECK: Boots that last, coveralls that take a beating, flannel by the stack. Dress for the work you've got. LIST: STEEL TOE BOOTS / COVERALLS / FLANNEL / RAIN GEAR / WOOL SOCKS / WORK GLOVES FOOT: CLIP THIS COUPON: $5 OFF ANY BOOTS. (502) 555-0130
- `third_optima_eyes` Optima Eyes: BAR: EYE EXAMS / GLASSES IN ABOUT AN HOUR DECK: See them before they see you. Keep a spare pair in the glove box. LIST: EYE EXAMS / FRAMES / LENSES / SUNGLASSES / REPAIRS / SPARE PAIRS HALF PRICE FOOT: VISA & MASTERCARD. (502) 555-0132
- `third_family_dentistry` Family Dentistry: BAR: GENTLE CARE FOR THE WHOLE FAMILY DECK: Healthy teeth for life. We ask only one thing of our patients: no biting. LIST: CLEANINGS / FILLINGS / EXTRACTIONS / DENTURES / EMERGENCIES SEEN SAME DAY FOOT: NEW PATIENTS WELCOME. MOST INSURANCE ACCEPTED. (502) 555-0134
- `third_pet_health_pawmise` Pet Health Pawmise: BAR: ANIMAL HOSPITAL / FARM CALLS DECK: Dogs, cats, horses and cattle. If your dog won't stop barking at the window, it may know something. LIST: SHOTS / CHECKUPS / SURGERY / BOARDING / FARM CALLS / EMERGENCIES FOOT: INSTALLMENT PLANS. CALL ANY HOUR. (502) 555-0135
- `third_pony_roam_o` Pony Roam-O: BAR: RIDING LESSONS / BOARDING / TACK DECK: A horse never runs out of gas. It does eat, but so do you. LIST: LESSONS FOR ALL AGES / TRAIL RIDES / BOARDING / SADDLES & BRIDLES / FEED & HAY FOOT: CALL FOR DIRECTIONS. (502) 555-0136
- `third_abc_driving_school` ABCDriving School: BAR: LEARN TO DRIVE IN TEN LESSONS DECK: Teens and grown-ups. Our graduates can get anywhere. Some of them very quickly. LIST: PERMIT PREP / ROAD TEST / HIGHWAY / NIGHT DRIVING / STICK SHIFT / DUAL-BRAKE CARS FOOT: INSTALLMENT PLANS. FREE PICKUP. (502) 555-0138
- `third_rosewood_fire_first_aid` Rosewood Fire Department: First Aid & CPR Classes: BAR: FREE CLASSES FOR ANY COUNTY RESIDENT DECK: Learn to stop bleeding, set a splint and start a heart. Better to learn it here than on the job. LIST: FIRST AID / CPR / BURNS / SPLINTS / CHOKING / HOME FIRE SAFETY FOOT: CALL TO SIGN UP. (502) 555-0142
- `third_muldraugh_karate` Muldraugh Karate & Self-Defense: BAR: SELF-DEFENSE FOR MEN, WOMEN & CHILDREN DECK: Lesson one is running. Lesson two is breaking a grip. Black belts take longer. LIST: KARATE / LADIES' SELF-DEFENSE / KIDS' CLASSES / FIRST LESSON FREE FOOT: OPEN 7 DAYS. (502) 555-0143
- `third_mindpeace_insurance` MindPeace Insurance: BAR: HOME / AUTO / LIFE / FARM DECK: Fire, flood, theft and twister. Ask about our coverage for acts of God. We have a form for each. LIST: HOMEOWNERS / AUTO / LIFE / FARM / BUSINESS / FREE QUOTES BY PHONE FOOT: MONTHLY INSTALLMENT PLANS. (502) 555-0145
- `third_homeward_real_estate` Homeward Real Estate: BAR: COUNTRY HOMES / FARMS / LAND DECK: Wells, woodstoves and root cellars a specialty. Ask about our listings with no neighbors. LIST: FARMS / ACREAGE / CABINS / STARTER HOMES / FREE MARKET APPRAISALS FOOT: CALL FOR DIRECTIONS TO ANY LISTING. (502) 555-0146
- `third_u_store_it` U-Store It: BAR: SELF STORAGE / YOUR LOCK / YOUR KEY DECK: Store what you can't carry. Fenced, lit and gated. Nobody gets in but you. LIST: 5x5 TO 10x30 UNITS / BOXES & TAPE / TRUCK RENTAL / MONTH TO MONTH FOOT: CLIP THIS COUPON: FIRST MONTH HALF OFF. (502) 555-0148
- `third_old_mill_water` Old Mill Water Company: BAR: WELLS DRILLED / PUMPS / WATER TESTING DECK: When the city water stops, yours won't. Ask about a hand pump for when the power's out. LIST: WELL DRILLING / PUMP REPAIR / HAND PUMPS / CISTERNS / FILTERS / WATER TESTS FOOT: FREE ESTIMATES. INSTALLMENT PLANS. (502) 555-0153
- `third_restwell_funeral_home` Restwell & Sons Funeral Home: BAR: SERVING KNOX COUNTY SINCE 1921 DECK: Burial or cremation. We recommend cremation. Pre-need plans on easy installments. LIST: CHAPEL / CASKETS / CREMATION / PRE-NEED PLANS / MONUMENTS FOOT: OPEN 7 DAYS, ANY HOUR. (502) 555-0156
- `third_knox_lock_key` Knox Lock & Key: BAR: LOCKSMITH / SAFES / DEADBOLTS DECK: We get you in and keep them out. Deadbolts installed on any door. LIST: DEADBOLTS / REKEYING / SAFES / CAR KEYS / LOCKOUTS / KEYS CUT FOOT: 24-HOUR LOCKOUT SERVICE. (502) 555-0161
- `third_throw_your_voice` Throw Your Voice! (Vocal-O Novelty Co.): BAR: FOOL YOUR FRIENDS! AMAZE YOUR TEACHER! DECK: Make your voice come from a closet, a trunk or the next room. Send them the other way. Only $1.25 plus postage. LIST: VOICE THROWER + 32-PAGE BOOKLET + MONEY-BACK GUARANTEE FOOT: VOCAL-O NOVELTY CO., DEPT. 87, BOX 1102, LOUISVILLE, KY. OR CALL (502) 555-0164

Picture briefs follow the one view (front and a little from above, a level circle an ellipse 0.26 as tall as wide),
about 120 x 118, one ink, no people, no real logos. Phones checked against every `src/*.html` (29 in use).
