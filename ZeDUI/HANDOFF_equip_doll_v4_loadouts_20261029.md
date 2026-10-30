# Handoff: Equip doll v4, loadouts and outfits (Oct 29 2026)

The director asked for this handoff on the round 2 review (Oct 29 2026). His calls, in his words:

- "show more slots on the screen, there is room on the left and right side, watch slots and accessory slots can be smaller chips"
- "No character avatar frame/background. just the avatar on the panel." The grid box was offered as the other option: "no grid. too distracting."
- "move arms above belt"
- Restock: "1, 2 and 3. 3 being the accessible option, 1 being hardcore, and 2 being casual." Trip length: "Days number only". Outfits and loadouts: "Separate, mix freely".
- "Loadout lists should live in the journal tab. They can be applied/stocked in the equipment tab. Right click menu adds a save to loadout/outfit and menus populate based on the names of saved loadouts and outfits. item card also has a button on the mark for strip to add remove from loadout/outfit"
- "You can also save current inventory/equipped as a loadout/outfit to the lists can be compiled that way too"

Two points were built as drawn in the review, without a separate pick from the director:

- Arms and Belt swapped rows.
- A loadout is one list holding gear and supplies together.

If he changes either, part A2 or part B1 changes with it.

**The mockups.**
- `ZeDUI/mockups/zed_equip_doll_v4_loadouts_r2.html`: open it at 100% (true size). Ten screens, with the decisions list under them.
- `ZeDUI/mockups/zed_equip_doll_v4_loadouts/`: the review sheet and the ten frames (`r2_01` to `r2_10`).
- The screens are drawn on the window as the game draws it now (the Oct 27 and Oct 29 captures at 1080p and 4K), so only what is new changes.
- Item pictures are stand-ins for the game's icons. Amounts and weights are examples.

**Pixel icons still to come from Design:** an outfit (a hanger) and a loadout (a list). They serve the right-click menu, the mark strip, the Equip bar and the Journal page. Until they land, use the closest existing icon.

---

## Part A: the doll (`EquipDoll.lua`)

### A1. No frame behind the figure

- In `D.draw`, delete the photo frame: the `T.surf2` fill, the `T.border` outline and the character's name under it (the block after `-- the photo frame (the model draws over it, from CharacterWindow)`).
- Keep stamping `win._equipDollPhoto` with the same rectangle. `ZeD_CharacterWindow.lua` (around line 4571) still draws the 3D model into it, so the figure keeps its size and place.
- The model then stands straight on the panel like the slots around it. See `r2_01`.

### A2. Arms above Belt

The right column becomes Back (row 0), the gap (row 1), Arms (row 2), Belt (row 3), Legs (row 4), Feet (row 5).

- In `D.SLOTS`, set arms to `row = 2` and belt to `row = 3`, and order the table entries by row.
- Arms' `av` becomes `{ 322, 200, 230 }`. Its line meets the sleeve at elbow height (y 210) as a straight line. In the game, check that the dot sits on the sleeve; nudge x if it doesn't.
- Belt keeps `{ 292, 236, 236 }`. Its line now turns up from y 292 to the waist in the second right lane (404).
- Back takes the first lane (420) and Feet the third (388). No two lines cross.

### A3. Four kinds of worn things the doll drops today (fix these whatever else happens)

`D.gather` drops any location missing from the slots' lists. The game's item scripts use four that aren't listed, and one entry is misspelled:

| Location | What wears it | Goes to |
|---|---|---|
| `bellybutton` | belly button rings and studs | Torso (small slot Belly) |
| `scba`, `scbanotank` | the breathing apparatus' air tank | Back (small slot Air tank) |
| `tail` | costume tails | Back (small slot Tail) |
| `sportshoulderpadontop` | sport shoulder pads worn on top | Arms (small slot Shoulders). The arms list has `sportshoulderpaddontop`, one letter off, so these never show. |

Also, `gorget` (the neck guard) moves from Outer to Neck.

### A4. The small slots

**The layout.**
- The doll grows from 520 to **744 units wide**: a band of 112 on each side.
- Every x in today's layout moves right by 112 when the bands show: `COL_L`, `COL_R`, `PHOTO.x`, the lanes, the `av` x values, `BELT_X0` and the row below.
- A small slot is **24 x 24**, at a step of 28, in three columns.
- The left band's columns start at x 16; the right band's start at x 648.
- A group's name sits at the y in the table, and its slots sit 14 below it. A row with no name continues the group above at the y given.
- Faint 1-unit rules divide the bands from the doll at x 108 and x 635 (white at 5%).

| Side | y | Name | Slots, left to right (their locations) |
|---|---|---|---|
| Left | 16 | Ears \| Nose | `ears`; `eartop`; `nose` |
| Left | 180 | Neck | `necklace`; `necklacelong`; `gorget` |
| Left | 262 | Belly | `bellybutton` |
| Left | 344 | Holster | `shoulderholster` |
| Left | 426 | Rings left | `leftmiddlefinger`; `leftringfinger` |
| Left | 467 | Rings right | `rightmiddlefinger`; `rightringfinger` |
| Right | 16 | Side bag | `satchel` |
| Right | 57 | Air tank \| Tail | `scba` + `scbanotank` (one slot, as layers); `tail` |
| Right | 98 | Shoulders | `shoulderpadleft` (L); `shoulderpadright` (R); `sportshoulderpad` + `sportshoulderpadontop` |
| Right | 139 | Elbows | `elbowleft` (L); `elbowright` (R) |
| Right | 180 | Wrists | `leftwrist` (L); `rightwrist` (R) |
| Right | 221 | Forearms | `forearmleft` (L); `forearmright` (R) |
| Right | 262 | Belt | `fannypackfront`; `fannypackback`; `webbing` |
| Right | 303 | (continues Belt) | `ammostrap`; `beltextra` (the belt holster) |
| Right | 344 | Knees | `kneeleft` (L); `kneeright` (R) |
| Right | 385 | Thighs | `thighleft` (L); `thighright` (R) |
| Right | 426 | Shins | `calfleft` + `calflefttexture` (L); `calfright` + `calfrighttexture` (R) |
| Right | 467 | Ankles | `gaiterleft` (L); `gaiterright` (R); `ankleholster` |

That makes 38 small slots.

**Drawing.** A small slot is drawn the way a big slot is, smaller:
- Filled: the `T.stripe` fill and a `T.borderS` frame. The item's texture at 18 units, centred 1 unit high. A 2-unit condition strip, inset 2 units, at the bottom.
- Empty: the dashed outline at `T.textDim` 0.35.
- A pair's empty slot shows a faint L or R in F5.
- A slot with several layers shows the count the way a big slot does.
- The group's name is F5, Title Case, in `T.textDim`.

**Behaviour.** Everything a big slot does:
- Hover gives the help line and the hint ("Wedding Ring | left ring finger"; empty: "Left ring finger").
- Selecting opens the item card. Stamp the zones as `doll:<slot id>`, and stamp empty ones as stops for the D-pad.
- Dropping an item that fits wears it there.

**The D-pad** (extend `D.dpad`):
- From a big slot, the direction toward its band steps into the nearest small slot in that band, by height.
- Inside a band, the four directions move between small slots by position.
- The direction back toward the figure returns to the nearest big slot.
- Right from the right band and left from the left band leave the doll, as Right from the right column and Left from the left column do today.

**The big slots keep** what isn't in a small slot:

| Slot | Locations |
|---|---|
| Head | hats, full hats, both full-suit heads, masks |
| Eyes | as today |
| Neck | `scarf`, `necktexture`, `neck` |
| Torso | as today |
| Outer | as today, without `gorget` and `shoulderholster` |
| Hands | `hands`, `handsleft`, `handsright` |
| Back | `back` |
| Arms | `leftarm`, `rightarm` |
| Belt | `belt` |
| Legs | the trousers, skirts, dresses, `underwearbottom`, `codpiece` |
| Feet | as today |

### A5. Narrow drawers: the bands fold away

- `fit()` works from the width the doll needs.
- The bands show while the 744-unit doll fits at `MIN_FIT` (0.7) or more: `w >= 744 * 0.7` units.
- Below that, draw today's 520-unit doll with no bands. The small slots' locations fold back into their big slot as layers: ears, eartop and nose to Head; the necklaces and gorget to Neck; and so on, following the table above. The four locations from A3 still go to their big slot.
- Nothing is lost at any width.

---

## Part B: loadouts and outfits

### B1. What they are and where they're kept

- **A loadout is what you carry.**
  - Gear: the bag, the weapons and tools, in a place (main hand, off hand, a belt slot, a worn bag or holster, the bag).
  - Supplies: water, food, medicine, ammunition, batteries, light.
- **An outfit is what you wear.**
  - Everything worn that isn't a container, jewelry included.
  - Worn containers (bags, fanny packs, webbing, holsters) belong to loadouts, because they carry the gear.
- **They're kept with the character**, in the player's mod data (for example `player:getModData().ZeD_Lists`), so they save with the character and every player in multiplayer has their own.
- **Each line is a recipe, not a snapshot.** It has:
  - Its place.
  - **Any** (a full type, or a kind by item tag, with a minimum condition or fill) or **this one** (that exact item by its item number, `getID()`, falling back to its full type if the item is gone).
  - An amount (a count, litres of water, or calories of food).
  - For loadout supplies, **a day** or **fixed**.
- **Applying them:** you apply one outfit and one loadout, mixed freely, plus a number of days. The days multiply the per-day lines.

### B2. The Journal's Loadouts page (`JournalTab.lua`)

See `r2_08`.

- Add a fifth page, Loadouts, after Recipes. The Character window reads the pages by index (1 to 4), so it goes on the end.
- It follows the Recipes page's own pattern:
  - A filter ("-- ALL --", Loadouts, Outfits) and a search over list names and line names.
  - A row of buttons: **Save what I carry as a loadout**, **Save what I wear as an outfit**, **New list**. Each asks for a name.
  - Two panes under them, 250 units for the lists:
    - **The lists:** sections Loadouts (n) and Outfits (n), each row an icon, the name and its line count, the chosen row in the selection wash.
    - **The chosen list:** its name (F4), "loadout | 9 lines", then Rename, **Add what I carry** (an outfit: Add what I wear) and Delete (a danger button).
- **Loadout lines** come in two sections:
  - Gear, with an Any | This one switch.
  - Supplies, with an A day | Fixed switch and the amount.
- **Outfit lines** are one section, Worn, with Any | This one and the place.
- **Editing a line:** pressing its amount gives a stepper. Right-click (or the pad's menu) removes it.
- **Narrow drawers:** under about 560 units, the panes stack, with the lists above the lines.

**"Save what I carry"** takes:
- The hands, the belt slots and the worn containers.
- Their contents and the inventory's, grouped by type.
- Food, drink, medicine, ammunition, batteries and light sources become supply lines (fixed, at the amount carried).
- The rest become gear lines. Gear in the hands or on the belt starts as **this one**; the rest starts as **any** of its type.

**"Save what I wear"** takes every worn item that isn't a container, as **any** of its type at its location.

### B3. Adding an item to a list by name

**The right-click menu** (`ContextMenuRegistry.lua`, both looks). See `r2_09`.
- Add **Save to outfit** (worn and wearable things only) and **Save to loadout** (anything you can carry).
- Each opens the saved lists of that kind **by name**:
  - A check on the ones the item is already in. Picking a checked list takes the item out.
  - A rule, then **New outfit…** or **New loadout…**, which makes a list with the item in it.
- In the list look, the submenu cascades. In the icon strip, it drills into the same names.

**The item card's mark strip** (`ItemCardOrganism.lua`, `ZeD.Atoms.FLAG_ICON`). See `r2_10`.
- A fourth button after Favorite, No crafting and Dispose: **Lists**.
- It's lit in the accent when the item is in any list, and its hint names them.
- Pressing it opens a pop-up with the same lists and checkboxes, and New. The Outfits section only shows for things you wear.
- The card gains an **In lists** section (each list, with the line's place and rule) when the item is in any.

### B4. Applying them in the Equip tab (`EquipmentTab.lua`, `EquipDoll.lua`)

See `r2_01`, `r2_03` and `r2_04`.

**The bar under Equipped** (both views, 38 units, surface 2), left to right:
- The outfit drop-down, with a check when every piece is worn.
- The loadout drop-down.
- The days stepper (1 to 30).
- **ready 4 of 9**: the loadout's lines that are already on you, in their place. Underlined; it opens the to-do.
- **Restock**, the default button, with the total time.
- **Save**, a menu: Save what I wear as an outfit, Save what I carry as a loadout.
- With nothing picked, the bar reads "No outfit", "No loadout" and a dim line: "lists from the Journal, to restock before you head out".
- In a narrow drawer, it wraps to two rows.

**What's missing shows where it goes.**
- Each unmet line with a place on the doll (a worn location's big or small slot, a hand, a belt slot) draws its item's texture at 36% alpha in a dashed accent box.
- For an **any** line, use the item restock would pick, or the type's icon.

**The to-do opens in the drawer**, where the item card opens, with the card's back button. See `r2_04`.
- Its buttons: **Restock** (default), **Open in Journal** (the Loadouts page, that list chosen), Unpack (dim until you're home).
- The title: the loadout's name, "loadout | 9 lines", and < 1 of 3 > through the loadouts.
- Left column:
  - **Applied**: the two drop-downs, the days, and "Outfit worn 7 of 7".
  - **Load after restock**: a bar of worn and gear, supplies, and room for loot against what you can carry. Use the game's own carried weight, with the bags' weight reduction, against `getMaxWeight()`. A marker shows the limit.
  - The restock way in use.
- Right column, **To do**: one line per list line, in one of five states, each with its place or rule and where:
  - on you (green check)
  - take from a container (accent arrow, the container's name)
  - fill at a tap (blue drop)
  - ask first (yellow question mark: the last one in the building)
  - none in the building (red cross)

**Long trips** (see `r2_05`).
- The supplies show as a table (What, Rule, Need, Have) above the gear.
- When the load after restock is over the limit, a warning says:
  - by how much
  - which supply is heaviest
  - the most days that fit
- It also offers **Make it N days**.

### B5. Restock

**The setting.** A new ZeD setting, **Restock**, is a combo box in `Settings.lua` like the others: Hardcore, Casual (the default), Accessible. See `r2_06`.

**Hardcore** takes only from the containers in reach now, the loot window's. The rest stay on the to-do, "not in reach", with where they are.

**Casual:**
- The to-do pins as a small list at the edge of the screen.
- Each time the containers in reach change, it queues the takes from them, with a one-line notice ("Bandage x2 from the Bathroom Cabinet").
- It's done when the list is empty.

**Accessible:**
- It plans the shortest route over the containers holding the picks (nearest first is fine).
- It walks it with the game's pathfinding walk, takes at each stop, and returns to where you pressed.
- The pinned list reads "Walking to 2 of 3 | 0:40 left".

**What all three share:**
- **The game's own timed actions** at their own speed, queued: take, wear, equip, attach to a belt slot, fill at a tap. The button's time is their total.
- **Where it looks:** the building you're in, or only what's in reach outside one. It uses containers you could open yourself; never a locked one, and never one another player's safehouse or claim keeps you out of. The loot window already makes these checks.
- **It asks before taking the last of anything in the building.** That line waits in the ask state until confirmed.
- **It stops** (cancel the queue) for any key or button, a zombie coming into view, or getting hurt.
- **Smart picks:**
  - the food that spoils first
  - the tool or weapon in the best condition
  - the fullest bottle
  - the lightest thing that meets the line
- **An outfit piece in the way** comes off and goes where the new one came from.

### B6. Unpack

See `r2_07`.

- **Home** is the building where you last restocked.
- On the way back in, the bar's button becomes **Unpack** and the card has three sections:
  - **Loot** (what you didn't leave with) goes where its kind already lives: the container in the building holding most of that type or category. A kind with no home yet asks once, and the choice is kept for that building.
  - **Leftovers**: supplies stay packed for the next run, except food that would spoil within 2 days, which goes back where food lives.
  - **Stays on you**: the gear and the outfit.
- It runs the same three ways as Restock.
- `ZeD_PutBack.lua` already remembers where things came from, which may help.

### B7. On a controller

- The D-pad wheel (`ZeD_Wheel.lua`, `ZeD_DpadWheels.lua`) gets a **Loadouts** ring: one entry per saved loadout. Picking one sets it in the bar and opens the to-do.
- In the to-do, A restocks and B goes back. The bar and the Journal page are on the usual D-pad path.

### B8. Strings (English; keys in ZeD's own style)

- **The Journal page:**
  - The page name: Loadouts.
  - The filter: Loadouts, Outfits.
  - The buttons: Save what I carry as a loadout; Save what I wear as an outfit; New list; Rename; Add what I carry; Add what I wear.
  - The sections and switches: Gear; Supplies; Worn; Any; This one; A day; Fixed.
- **The Equip tab:** No outfit; No loadout; "lists from the Journal, to restock before you head out"; ready %1 of %2; Restock; Save; Unpack; Open in Journal.
- **The to-do:** Applied; Outfit worn %1 of %2; Load after restock; To do; on you; take from %1; fill at %1; ask; none in the building; not in reach; Make it %1 days.
- **The Restock setting:** Restock; Hardcore; Casual; Accessible.
- **The right-click menu and the card:** Save to outfit; Save to loadout; New outfit…; New loadout…; Lists; In lists.
- **The small slots:**
  - Group names: Ears | Nose; Neck; Belly; Holster; Rings left; Rings right; Side bag; Air tank | Tail; Shoulders; Elbows; Wrists; Forearms; Belt; Knees; Thighs; Shins; Ankles.
  - Each slot's place, for its hint.

---

## Part C: checks for the test run

- **1920 x 1080 and 4K at 1.75**, at a window wide enough for the 744-unit doll:
  - The figure with no frame.
  - Arms above Belt.
  - No leader lines crossing.
  - All 38 small slots in place.
  - A character wearing a belly button ring, an air tank, a tail and sport shoulder pads on top shows each one.
- **A narrow window:** below 0.7 of 744 the bands fold away and every small-slot item shows as a layer in its big slot.
- **The D-pad** walks into and out of both bands and leaves the doll at the outer edges.
- **The Journal's Loadouts page** saves what you carry and what you wear, edits and deletes lines, and keeps the lists across a save and reload.
- **Lists are added to and taken from** in all three ways: right-click, by name, both looks; the mark strip; and the Save buttons. The checks match.
- **Restock in each of the three ways** in a stocked house:
  - the time on the button matches what it takes
  - it never takes from a locked container
  - it asks before the last bandage
  - it stops on a key press, a zombie in view, and being hurt
- **Over the limit:** a 5-day loadout that's too heavy warns, names the heaviest supply, and **Make it N days** fits.
- **Unpack** puts loot with its kind, keeps leftovers packed, and asks once for a kind with no home.
- **Multiplayer:** each player has their own lists, and restock skips containers another player's safehouse keeps you out of.
