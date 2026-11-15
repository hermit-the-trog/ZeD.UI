# Handoff: pop-outs, the faces and the seat picker without a window (Nov 15 2026)

From design, for Build. Three things:

1. Every machine face pops out on its own, with no window frame, the way the two-way radio's full view already does.
2. The seat picker becomes a pop-out: just the cabin, in pixel art.
3. A new ZeD setup switch, **Additional appliance support**, starting with a working espresso machine.

The director, Nov 15:
- The seat picker: "Does it have to be a window? Or can we do something like we do with the walkie-talkie pop-outs, where there's just no window frame?" Then, on the mockup: "That is awesome. That is super awesome."
- The faces: "if you click on a TV in the world or press A with a controller when aimed at a TV, or you click on an oven face or a microwave ... should the face just pop up without a window? I think so. It should be easy to dismiss and easy to use, though." Then: "Yes, mock it up. Just do all of them ... get it all mocked up and hand off for build."
- The switch: "Could we add a setting that is for additional appliance support with a note saying that using this setting makes removing this mod from a save riskier." On the default: "Go with your recommendation there."

Nothing here is in `42/`. Wait for QA to be clear before writing there.

## 1. Faces as pop-outs

**Template:** the two-way radio's full view, which passed QA on Oct 26: the face alone, no frame, at the plate scale; dragging it moves it; the place is kept on the character; B and Escape close it; on a controller, focus lands on a control and the controller strip shows under it. Build each machine's pop-out on that code; don't start a new one.

**Which faces.** Every device that has a face in a card today (punch list 17), plus the laundry, which now has faces too:

| Family | Plates (the full-card picks, `@336/392/450/562`) |
|---|---|
| TVs | `tv_black`, `tv_widescreen`, `tv_antique` |
| Radios | `radio_black`, `radio_red`, `radio_handbuilt` (round 5 full card), and `cd_player`. The CD player has no full-card face, so it uses its widest half-card face (`@257`). |
| Ham radios | `ham_civilian`, `ham_army`, `ham_makeshift` |
| Two-way radios | already done (the full view). Unchanged. |
| Ovens | `oven_green`, `oven_red`, `oven_grey`, `oven_modern`, `oven_large`, `oven_industrial` |
| Microwaves, fryer | `mw_white`, `mw_chrome`, `fryer` |
| Grill, generators | `grill_propane`, `gen_red`, `gen_yellow`, `gen_blue`, `gen_old` |
| Laundry | `washer`, `dryer`, `washer_dryer` |

Not in this pass: the car radio, the siren and the dashboard (they live on the dashboard), and the watches (punch list 17 leaves them out of the cards too).

**No new art.** The pop-out is the same plate the full card draws, at the same width pick and the same size, with the same live parts (screens, digits, needles, lamps, state sprites).

**What it looks like.** See `face_popouts_ingame_v1.png` and `face_popouts_all_v1.png`.
- The face, then System 7's hard shadow: 1u right and 1u down, black at 0.5, on the face's own shape (COHESION_SPEC section 1, item 4: things that pop up over the game get it).
- No title bar, close box or frame.
- Under the face, after a 3u gap, the strip: the radio full view's strip, at the face's width.
  - Controller: the focused control's prompt (A + its name; the up/down picture + its name on a knob), then B Close.
  - Mouse: the help line, meaning the help for the control under the pointer, else "Click a control.  Esc closes."
- The controller highlight (pointing hand by default) sits on the focused control, as in the cards.

**Opening it.** It opens in each of these cases, all in the Immersive style:
- A left-click on the machine in the world. Not while aiming, and not when the click does something else in vanilla.
- Pressing A on a controller while aimed at the machine.
- The machine's own context-menu row that opens its controls today, for example the radio and TV's device options.
- A click on the face in a World window card away from its controls, or the card's header button. This is the radio's full view rule; it toggles the pop-out.

Handheld radios and the CD player get the walkie's header button and face click too.

**Where it opens.** The first time, beside the player, on the side with more room, never covering the player or the machine. After a drag it opens where it was dragged: one place for all face pop-outs, kept on the character like the radio full view's place.

**One at a time.** Opening another face replaces the one that's open. The two-way radio's full view counts as one of them.

**Using it.**
- The game keeps running, and the face stays live.
- Controller:
  - Focus lands on the machine's main control, the same first stop the cards use (POWER on radios and TVs).
  - The D-pad walks the controls in the face's focus order; up and down turn a knob; A presses; B closes.
  - The left stick still walks the character.
- Mouse: the controls work directly, as in the card.

**Dismissing it, all of these:**
- B or Escape. Escape closes the pop-out before the pause menu opens.
- A click, or A, on the same machine again.
- Walking out of reach. Use the distance the game uses to keep a machine's panel open; vanilla's is `ISEntityUI.isoPanelWalkToDist = 3`.
- The machine being picked up, destroyed or losing its tile.
- Opening another pop-out.

**The Simple style.** With faces off (punch list 17's switch), nothing pops out. The machine's card opens in the World window, as today: the plain card once it's built, the face card until then.

## 2. The seat picker as a pop-out

Replaces `ZeD_SeatChooser` (a `ZeD_Window`) in the Immersive style. **The Simple style keeps today's window until the director says otherwise** (asked, not yet answered).

Every rule and action stays vanilla's, as now: `canSwitchSeat`, `moveItemsFromSeat`, `isExitBlocked`, `onSwitchSeat`, `onEnter` and `onExit`, the keys, the reasons. Only the drawing and placement change. Reviews: `seat_picker_popout_v1.png`, then the cabin itself in `seat_picker_review_v5.png`.

**What it draws.**
- The cabin: interior only, no windshield, doors or roof. The floor, the dashboard and the seats, in the vehicle's own interior color.
- Under it, the strip: the seat's name (vanilla's), its status square and vanilla's reason (`reason()` today), then the prompts or the help line.
- Keycaps on the seats, the pointing hand outside the cabin at the focused seat's side, and get-out cells beside the cabin at the doors.
- No frame, no title bar, no Cancel button. B or Escape closes it.

**The cabin's art** is baked: `ZeDUI/tools/seats/bake_seat_popout.py` writes `textures/ZeD/seats/popout/` and `layout.json` (which has every number below).
- Draw it at a whole number of screen px per art px, nearest filtering: `max(1, floor(T.px(2) + 0.5))`. That's 4 at 4K at 1.75, and 2 at 1080p at 1.0.
- Lay the parts on in this order: floor, dashboard, seats, console, dummies, bag then box, wheel. Each part has a 1 px margin for its outline; `layout.json` says where each one goes.

| Part | Files | Notes |
|---|---|---|
| Floor | `floor/<cabin>_<rows>.png`, 1 to 5 rows | The tub (rim) and carpet in that interior color. The box grows a row at a time. |
| Dashboard | `dash/<design>__<cabin>.png`, 106 x 12 | The vehicle's own ZeD dashboard at the cabin's pixel size: the cluster in front of the wheel, the stereo stack centered over the console, the glove box and a vent on the passenger's side. 44 files, one per design and interior color in `colors.py`. |
| Seats | `seat/<cabin>_bucket.png`, `_bench.png` (split seam), `_half.png` | In the dashboard's own vinyl. |
| People | `dummy_you.png` (accent), `dummy_other.png` (grey) | A crash test dummy from above; the knees stick out past the cushion's front edge. |
| Things | `bag.png`, then `box.png` on top | A seat with items. |
| Console, wheel | `console.png` (front buckets only), `wheel.png` | The wheel only while the driver's seat is fitted. |

**Rows.**
- Group the seats by vanilla's `inside` position offsets (z), front row first. Within a row, left and right go by x.
- The front row is two buckets with the console between them, except a front bench on the pickups: the dashboards with the BED key, `bulldriver` and `d6`.
- Every row behind the front is a bench. When one place in a bench row isn't fitted, draw the fitted side's half bench, and draw the empty place as a dashed outline.
- A row with only one seat gets only that side.

**Which dashboard and color.** The same design and interior color the vehicle's dashboard uses: `ZeD_Dashboard`'s pick, per the Nov 12 interior colors handoff. A vehicle with no ZeD dashboard falls back to `van__v_navy`. Check it in game; this is not checked here.

**Seat states**, using the same keys as today:

| State | How it's drawn |
|---|---|
| Free | The seat's keycap. |
| You | The accent dummy. |
| Someone else | The grey dummy. |
| Items | The bag with the box on top, plus the keycap. |
| Can't be reached from here | 50% black stipple over the seat, dim keycap. |
| Not fitted | A dashed outline where the seat would be, dim keycap. |

The focused seat's keycap turns the accent color, and the pointing hand sits outside the cabin at that seat's side (mirrored on the right).

**Keycaps** are the keycap atom, bigger than the window's: 26 x 24u, radius 6, label 16u, centered on the seat at (seat x + w/2, seat y + 12 art px).

**Doors** are today's context-strip cells, pixel art at the cabin's own scale (the cell 13 art px square):
- Left and right cells sit beside the row of each seat you could leave by.
- The rear door gets a cell under the cabin.
- The focused exit cell gets the accent double ring.

**The strip:**
- Line 1: the seat name (Fira Sans SemiBold 14u).
- Line 2: the status square and the reason (12u).
- Line 3: the prompts, today's `getFooterPrompts()`: D-pad Move, A Sit, X Get out here (only when inside), B. Label B Close, as the radio's strip does, not Cancel. With a mouse it's the help line instead: "1-n Sit   Shift+1-n Get out there   Esc Close".

**Where it opens.** Beside the vehicle, on the player's side, never over the player. Vanilla re-centers its window every frame; drop that. Dragging moves it, and the place is kept on the character, separate from the faces' place.

**Closing.** B, Escape, the seat key again, walking away, or taking a seat (as now).

## 3. ZeD setup: Additional appliance support

A new switch with the other additions in `Settings.lua` (next to Restock).

| | |
|---|---|
| Name | Additional appliance support |
| Presets | **Off in every preset, Vanilla Plus included** (the director, Nov 15: "Go with your recommendation"). A player only gets it by switching it on. |
| Help line | "Makes more of the game's appliances work, starting with the espresso machine. With this on, taking ZeD out of a save is riskier: things these appliances hold or made can be lost." |

**The first appliance: the espresso machine** (`Mov_Espresso`, tile `appliances_cooking_01_61`). The game has it as furniture only; the toaster and coffee maker beside it work.
- With the switch on, the machine gets a "Make espresso" action: from its context menu, from A at it, and from its face once Design draws one.
- The action needs power, water, coffee and a mug, and makes the game's own coffee. Build: find the coffee maker's recipe or fluid and reuse it. Add no new item types and don't turn the tile into a container, so a save stays sound if the switch or ZeD goes away.
- If another mod already makes the espresso machine work, ZeD's action stays out of the way. Check the popular appliance mods; Functional Appliances 2's page doesn't list it.

## Coming from Design next (not in this handoff)

New faces, for the director's review first: the **toaster** and the **coffee maker** (both power on in Build 42), and the **vending machines** (pop and snack). Those are plain containers in the game, so their faces show what's really inside: each button or spiral shows the item and how many are left, and pressing one takes one.

The director, Nov 15, on dishwashers: a **separate mod** (dirty dishes: used plates, bowls, pots and pans come back dirty; dirty ones can't be used until washed; the dishwasher loads and runs like the washing machine). ZeD supports it and Design draws its face. It is not a ZeD feature.

## Files

- `ZeDUI/art/popouts_20261115/`
  - Review sheets: `face_popouts_ingame_v1.png`, `face_popouts_all_v1.png`, `seat_picker_popout_v1.png`, `seat_picker_review_v5.png`, `minidash_all.png`.
  - `seat_popout_art.zip`: the bake's output, `textures/ZeD/seats/popout/` and `layout.json`. Copy the textures under `42/media/` when QA is clear.
- `ZeDUI/tools/seats/`
  - `bake_seat_popout.py`: writes the art.
  - `seat_cabin.py`: the cabin's parts and the reference compositor `cabin(rows, states, dash, k)`.
  - `minidash.py`: the mini dashboards, the passenger side and the end cap drawn the dashboards' way.
  - These need `ZeDUI/tools/dashpx` beside them (or `ZED_DASHPX`). With `ZED_DASH_PLATES` pointing at a folder of `colors.py` plates they use those; otherwise they render each plate (about a minute for all 44).

## Checked, and not

- Checked:
  - Every face renders as a pop-out from the game's own pictures, and its first control and prompt come from `PhysPx.lua`.
  - The TV and the washer, as live faces taken from QA's shots, laid into their own scenes.
  - The bake runs clean: 44 mini dashboards, 13 interior colors x (5 floors + 3 seats), and the 6 shared parts.
- Not checked:
  - Anything in game.
  - Front-bench and row detection on every vehicle, including mods' vehicles.
  - The dashboard and color pick for the seat picker.
  - Reach distances.
  - Which context-menu rows open each machine today.
  - The espresso action.
  - The keycap atom at 26 x 24u.
- Known and left:
  - The black interiors (fleet cars, `l_black`, `v_black`) make very dark mini dashboards.
  - On light brown and beige seats, the cardboard box is close to the seat color; its outline keeps it readable.
