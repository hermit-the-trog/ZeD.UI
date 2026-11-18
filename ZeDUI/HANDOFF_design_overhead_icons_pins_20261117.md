# Handoff, Design to Build and QA: over-head icons, foraging pins and the pointer to a find (Nov 17 2026)

Two sets Design drew on Nov 15 and never handed off (the pop-out handoff went out that day without them), and one
the director asked for on Nov 17:

1. **Over-head icons:** the icons the game puts over your head (the car key, search mode, PvP, voice, the XP arrows),
   redrawn as small ZeD balloons, plus ten new ideas the director has not picked yet.
2. **Foraging pins:** the pins that mark a find in search mode, redrawn as a magnifying glass with the find in its lens.
3. **The pointer to a find** (added Nov 17): what sits at the character's feet and points at each find. The director
   picked the hand from the cloud.

Since Nov 15 the director made every bubble light (8d331a08f, "any tooltips, any bubbles"). The over-head icons are
redrawn here on the light balloon. The pins are world markers, not bubbles, and are unchanged from their Nov 15 review.

Art: `ZeDUI/art/overhead_20261117/`. Nothing in `42/` was touched.

## The director's calls

- Nov 15: the game's icons over the head (search mode, the car key and the rest) in ZeD's own art, one family with the
  over-head bubbles.
- Nov 15, the pins: "look similar to what they look like in the game, just more to match our look ... the icon showing
  what the item discovered is, or showing a hint ... behind a magnifying glass." Of the two pins Design drew, the
  magnifier went forward, and "more pronounced glass" thinned its rim (`review/foraging_pins_review_v2.png`).
- Nov 17: every bubble is light.
- Nov 17, on the light review sheet: "Fix the sword handle and the bones. The bones need joints." The PvP skull's
  crossbones now cross behind the skull with a knobbed joint at each end. The nearly-broken weapon has a real hilt:
  a brass crossguard square to the blade, a wrapped grip and a pommel. Both are in this set (`src/fix_icons.py`).
- Nov 17, the noise icon (Design's sound arcs did not read): "What about a twig breaking? Just snapping in half with an
  exclamation point rising from the snapping point. And then, of course, all the other lines showing that it is
  broken." And: "You stepped on it, not kicked it upward." Drawn that way (`src/twig.py`): the break pushed down,
  the two halves rising from it in a V, splintered pale ends, a ! rising from the snap and a snap line out to each
  side. Then: "Diagonal lines are too close to exclamation point. Make exclamation point red." The ! is the light
  balloon's danger red (C01C1C) and the snap lines sit two pixels clear of it. Its badge is 36 x 33, a little larger
  than the rest.
- Nov 17: "Can I get the handoff ... for all the new icons for like foraging and I think the overhead icons and such?"
  Design reads that as the go for the redraws and the pins. **The ten new ideas stay unbuilt until the director picks.**

## What to build

| Set | What | How | Status |
|---|---|---|---|
| A | Foraging pins | Lua: replace `ISBaseIcon:renderPinIcon` | Build |
| A2 | The pointer from the character to a find: the hand from the cloud | ZeD draws it (Lua) | Build |
| B | Search-mode eye | Lua: replace `ISSearchManager:renderEye` | Build |
| C | Car key, PvP skull, voice | Texture replacement (the game draws these in Java) | Build: test one first |
| C2 | XP arrows | Texture replacement, but the same files are the game's combo box and scroll arrows | Build: check, likely skip |
| D | Ten new ideas | ZeD code per trigger, drawn with ZeD's balloon | The director's pick first |

All of it is off in safe mode, like the rest of ZeD.

### A. Foraging pins

The game draws every pin through one function, `ISBaseIcon:renderPinIcon()` (`media/lua/client/Foraging/ISBaseIcon.lua`,
line 179): forage finds, world items in search mode and stash icons all inherit it. Replace that one function.

Today it draws the category pin, then the item at two thirds of its size near the top, then the poison skull; or the
`?` pin when the item is not identified. ZeD's pin is three layers on the same 60 x 90 canvas, so the game's size and
position code (`updatePinIconSize`, `updatePinIconPosition`) stays as it is.

In canvas units, with `s = self.width / 60` (the pin is 60 x 90 at zoom 1):

1. `pins/pinB_back.png` at (0, 0), `self.width` x `self.height`.
2. If `self.itemTexture and self.identified and self.renderItemTexture` (the game's own test):
   - the item, centered on the lens at (29, 26), at its own size up to 32 units. A larger texture is fitted to 32 on
     its longer side, never stretched up. The game drew it at 67%; the lens is meant to magnify it.
   - then `pins/pinB_glass.png` over everything. It redraws the ring, so an item's corners never show past the rim.
   - if `self.isKnownPoison`: `pins/poison_mark.png`, 12 x 12, at (42, 36).
3. Otherwise `pins/pinB_unknown.png` (the frosted lens with the `?`), no item.

Every layer keeps the game's `self:getAlpha()` and `self.textureColor`, so the fade and the bounce behave as before.

`pins/pinB_hint.png` (half frost, the item showing through out of focus) is drawn but has **no use yet**. The game has
two states, identified or not; showing a blurred item before the game identifies it would tell the player more than
the game does. Leave it unused unless the director names a state for it.

### A2. The pointer to a find

When a find is near, seen and forageable, the game puts an arrowhead on a ring round the character's feet, turned
toward it (`ISBaseIcon:updateWorldMarker`, line 613). `ISBaseIcon:addWorldMarker` (line 590) makes it:
`getWorldMarkers():addPlayerHomingPoint(self.character, x, y, 0.8, 0.8, 0.8, 1)`. The Java draws and turns it.

The director asked for it on Nov 17, tried four, and picked one: **the hand from the cloud** ("I like the hand of God,
going with that one, until I decide that I want something else"). Build that one. The other three stay in the folder
in case he changes his mind. Reviews: `review/forage_hands_review.png` (both hands, in game, over QA's
`zed_51_forage` capture with the ZeD pins in place) and `review/forage_arrow_review.png` (the arrows).

- **`hand/forage_godhand_right.png` and `forage_godhand_left.png`, the pick** (after the director's reference, Monty
  Python's hand of God): Design's own take on the old hand from the clouds, not a copy of that picture. A painted
  hand, lit from above, the index finger out, a draped red sleeve, coming out of a small cloud. 72 x 40.
  Its build follows the director's anatomy references (Nov 17): the thumb lies forward under the index finger, thick
  at its root, its tip with its nail resting on the first curled finger; the three curled fingers show their nails at
  the back, where their tips tuck into the palm ("Draw the thumb until you get it right ... right now it looks like
  little mini sausages").

The alternates:


- `arrow/forage_arrow_glass.png`: a chrome rim with the pin's dark glass in it, in the magnifier's family.
- `arrow/forage_arrow_solid.png`: solid chrome. Brighter; the stronger of the two at night.
- `hand/forage_hand_right.png` and `forage_hand_left.png`: the printer's fist (the director: "What about pointing
  fingers? ... Maybe it has a little arm attached to it", then an old engraving as its guide): black and white like
  a woodcut, a black cuff with its button, the same hand as the pick. 72 x 40.

The arrows are 32 x 32 with the tip up, like the game's. All four are drawn smooth (not pixel-doubled), because the
game turns them to any angle.

If the director goes back to an arrow:

1. Replace `addWorldMarker` so it passes white (1, 1, 1, 1), not the game's 0.8 grey, which would dim the chrome.
2. The picture: Design matched the game's arrow to `media/textures/highlights/arrow_triangle.png` by eye; Build
   confirms which of the six `arrow_triangle` files the homing point draws. If `addPlayerHomingPoint` has an overload
   that takes a texture, pass ZeD's. If not, a file at the same path replaces it, and with it every homing arrow in
   the game (the tutorial's, other mods'). Tell Design which way it went.

For the hand (the pick), the game's homing point will not do: it only turns its picture, so a hand pointing left
would hang upside down with its thumb underneath. ZeD draws it instead:

1. Replace `addWorldMarker`, `setWorldMarkerPosition` and `removeWorldMarker` so the game makes no homing point;
   keep ZeD's own list of finds to point at (the same finds, at the same moments, as the game's `updateWorldMarker`).
2. Each frame, for each find: the angle from the character's feet to the find, on screen. Draw the hand on the same
   ring round the feet as the game's arrow, its fingertip outward: `forage_godhand_right` when the find is to the
   right of the character on screen, `forage_godhand_left` when it is to the left, turned by the angle within 90
   degrees either way, so the thumb is always on top. The picture is 72 x 40, drawn at 1 picture pixel a screen
   pixel at 4K, the pivot at its middle.
3. Keep the game's look otherwise: white, full alpha, gone when the find is picked up or out of range.

### B. Search-mode eye

`ISSearchManager` (`media/lua/client/Foraging/ISSearchManager.lua`) draws `media/ui/foraging/eyeconOn.png` over the
head in `renderEye()` (line 125), at the texture's own pixel size, 140/zoom above the head, fading by
`textureColor.a` (0.33 when something is in view).

Replace `renderEye` instead of the texture file. The same file is also the eye in the game's search window
(`ISZoneDisplay.lua`, line 8).

- Draw `overhead/2x/eyeconOn.png`, scaled with the over-head bubbles: 2 art pixels per pixel at 4K, as ZeD_Bubbles
  scales.
- Keep the game's fade.
- Place it in the over-head stack the way the speed bubble sits (ZeD_Bubbles, near line 531), so the eye and the
  over-head notes never overlap. Build picks the order; Design suggests the eye just above the speed bubble.

`eyeconOff` is in the set for completeness. The game's over-head code never draws it.

### C. The game's Java-drawn icons

The car key (`CarKey`, `CarKey_none`), the PvP skull (`Skull`) and the voice icons (`voiceon`, `voicemuted`) are not
in the game's Lua. They come from `UI.pack` and the Java draws them. A texture replacement is the only way to change
them, and it may not take for a packed texture.

| Texture | The game's size | ZeD's 1x | ZeD's 2x |
|---|---|---|---|
| CarKey, CarKey_none | 32 x 32 | 31 x 30 | 62 x 60 |
| Skull | 16 x 16 | 32 x 32 | 64 x 64 |
| voiceon, voicemuted | 18 x 18 | 29 x 30 | 58 x 60 |
| ArrowUp, ArrowDown | 13 x 13 | 13 x 13 | 26 x 26 |

1. Test with `CarKey` first: put ZeD's file at `media/ui/CarKey.png` and see whether the game uses it over the pack
   entry, and at what size it draws it (its own texture size or a fixed 32).
2. If the game uses the texture's own size, ship 2x. If it draws at a fixed size, ship the bake nearest that size.
   Tell Design: a 16 x 16 skull may need its own drawing, since 32 x 32 scaled to 16 turns to mush.
3. If the replacement does not take, these stay the game's. Do not hook the Java for them.

**C2, the XP arrows:** the XP note ("+5 Carpentry") is still drawn by the game's Java (ZeD_HaloText.lua, header), with
the 13 x 13 `ArrowUp` and `ArrowDown`. The same names, `media/ui/ArrowUp.png` and `ArrowDown.png`, are the game's
combo box arrow (`ISComboBox.lua`, line 616) and the context menu's scroll arrows (`ISContextMenu.lua`, line 1159).
Replacing them changes those too. Ship the arrows only if no game window ZeD leaves on screen still uses them;
otherwise skip C2 and tell Design.

### D. The ten new ideas (the director's pick; build none yet)

Each needs ZeD code to decide when to show it. Draw them with ZeD's own balloon (the over-head note's body, light
palette, the status mark ZeD_Bubbles already draws) and the icon alone from `overhead/icons/`, not the baked badge,
so palette and scale stay live. The triggers are Design's proposal, for the director to confirm.

| Icon | Shows when | Design's flag |
|---|---|---|
| door_key | You face a locked door and carry its key | |
| door_nokey | You face a locked door without its key | |
| hotwire | You sit in a driver's seat without the key and can hotwire | |
| noise (the snapping twig) | You make a loud noise (a shot, breaking glass) | |
| gun_empty | You pull the trigger on an empty gun | |
| gun_jammed | Your gun jams | |
| weapon_breaking | Your weapon's condition falls low | The threshold is the director's |
| water_tainted | You handle water the game already shows as tainted | Never for water the character does not know is tainted |
| typing | Another player is typing (multiplayer) | The game may not send typing to other players; Build checks before promising it |
| spotted | A zombie notices you | The game does not tell you this. Showing it changes the game's balance; Design suggests dropping it, or keeping it to the Vanilla Access preset |

## Still open

1. **The ten new ideas:** which to build (D).
2. **Simple style:** every ZeD surface is Immersive or Simple, and neither set has a Simple version drawn. Design's
   proposal: the over-head badges are already flat and serve both styles; the pins' Simple style is the game's own
   pins. The director's call.
3. **The hint pin:** a use for it, or drop it (A).
4. **The pointer to a find:** decided, the hand from the cloud (A2), "until I decide that I want something else".

## Files: `ZeDUI/art/overhead_20261117/`

| Folder | What |
|---|---|
| `overhead/1x/` | The 17 badges at 1 art pixel a pixel (light balloon, status square, shadow), plus the two XP arrows. |
| `overhead/2x/` | The same, doubled (nearest neighbor), for 4K. |
| `overhead/icons/` | The icons alone, ink on clear, for balloons ZeD draws itself (D, and B if Build draws the eye's balloon in code). |
| `arrow/` | `forage_arrow_glass.png`, `forage_arrow_solid.png`, 32 x 32, tip up. |
| `hand/` | `forage_godhand_right.png`, `forage_godhand_left.png` (the hand from the cloud, the pick), and `forage_hand_right.png`, `forage_hand_left.png` (the printer's fist, the alternate). 72 x 40, pointing sideways; each left is its right mirrored. |
| `pins/` | `pinB_back`, `pinB_glass`, `pinB_unknown`, `pinB_hint`, `poison_mark`. 60 x 90 like the game's pins; the mark 12 x 12. |
| `review/` | `overhead_icons_review_v3_light.png` (this set), `overhead_icons_review_v2.png` (the Nov 15 dark one, superseded), `foraging_pins_review_v2.png`, `forage_hands_review.png`, `forage_arrow_review.png`. |
| `src/` | `overhead.py` (the shapes), `fix_icons.py` (the Nov 17 skull and sword), `twig.py` (the Nov 17 noise icon), `manicule.py` (both hands, one build: `painted()` and `engraved()`), `arrow.py` and `arrow_mock.py` (the pointer to a find), `overhead_light.py` (this export), `pins.py` (needs `tools/dashpx`, or `ZED_DASHPX`), `compose_pins.py`, `review_v3.py`, `ingame.py`. |

Colors are ZeD.Balloon.LIGHT (Balloon.lua): body CCCCCC, line 424242, near-black ink, marks 1E7D22 and C01C1C. The
warning square is B57F00, the round 1b light gold (white `!` on it, 3.5:1). If the palette changes, rerun
`python overhead_light.py` from `src/`.

## For QA, once built

At 4K and Deck, in Dark, Light and High Contrast (the pins and balloons look the same in all three; check that they do):

- **Pins:** a found mushroom, berries and an insect; an unidentified find (the `?`); a known poisonous mushroom (the
  mark); a world item in search mode; a stash icon from a map. Each fades and bounces as the game's did.
- **The pointer to a find:** one find and several at once, by day and at night, on grass, road and snow; the hand
  turns smoothly as the character walks round a find, thumb on top all the way round, flipping sides cleanly when the
  find crosses straight ahead or behind; it is gone once the find is picked up.
- **Search mode:** the eye over the head, faded when something is in view, never on top of an over-head note or the
  speed bubble.
- **C:** whatever Build shipped: the key walking up to a car with and without its key; PvP and voice on a server.
  If C2 shipped, a combo box and a long context menu's scroll arrows still look right.

**For Design, the pin's size (QA, Nov 17, confirmed in the game's code):** the pin textures are 60 x 90, but the game
draws every pin at 30 x 45 at zoom 1 (`ISBaseIcon:new`: width 30, height 45; `updatePinIconSize` divides by zoom).
Build follows the handoff's canvas math against the pin's real width (s = width / 60), so the find sits in the lens
exactly as on the review sheet, at half the size the handoff assumed: a 32-pixel item draws 16 pixels wide on a
30-pixel pin. The game drew it at 21 (32 / 1.5), larger than the lens can hold, so "the lens is meant to magnify it"
cannot happen at the game's pin size. Build keeps the find inside the lens. If Design wants a bigger find, the choices
are a bigger pin (the size code is the game's) or a find that overflows the rim. Design's call.
