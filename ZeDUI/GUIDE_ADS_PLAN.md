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
