# Vehicle tab: two columns (spec, Nov 3 2026)

The director, talked through by voice on Nov 2 2026 and approved for the beta on Nov 3 ("draw up the vehicle tab
spec, and then send it over to build"). It is a refinement of a screen ZeD already ships, not a new feature, so it
goes in the beta (punch list 79).

Today's tab (MechanicsTab.lua, mockup zed_vehicle_mechanics_v1, Oct 13) is the game's mechanics window stacked
vertically: the car figure and a summary, the part list under it, and a part opening as a full card with a back
arrow. The new tab works like Crafting and Building: one screen, two columns, the list on the left, the picture or
the chosen part on the right, actions in the footer. Players already know that layout from those two tabs, so
nothing here needs teaching.

## 1. The layout

- The World window's Vehicle tab, the full card, split in two the way CraftingCore splits Crafting and Building
  (CC.PANE_W_SPLIT, the same header strip, the same sort strip, the same footer). Follow CraftingCore's measures and
  its pad paths rather than inventing new ones.
- **Header:** as now: the vehicle's name, the vehicle switcher when several are in reach, the overall condition,
  the key state. Before an inspection, as now: only what shows from outside, and INSPECT.
- **Left column:** the part list (2).
- **Right column:** the car diagram when no part is chosen (3), the chosen part's card when one is (4).
- No second screen and no back arrow. Choosing another part swaps the card in place.

## 2. The part list (left)

- One row per part slot: the part's name, its condition as the mini bar and percent (as now), and its state words
  where they matter (Missing, Smashed, Locked).
- **Missing parts keep their row.** A pulled tire, an empty battery slot or a smashed window that is gone still has
  a row, reading Missing, so the player can choose it and install something there.
- **The sort pop-up** (the band's pop-up, the same control as Crafting's sort):
  - **By section** (the default): parts grouped by where they are on the car, and a part sits under the part that
    has to come off first. The front left wheel's group is the tire with the brake and the suspension under it; a
    door's group is the door with its window under it; the engine bay has the hood with the engine, battery and the
    rest under it. Take the "comes off first" order from the game's own install table for each part
    (`requireUninstalled` / `requireInstalled` in the part's install table), so modded cars group correctly
    too. Parts with no such link group by their corner or area (front, rear, the four corners, inside).
  - **By condition:** worst first, all sections mixed, so a mechanic sees at a glance what needs work.
- **By condition is earned: Mechanics level 4.** Under level 4 the choice is in the pop-up but grayed, followed by
  the level it needs, built from words the game and ZeD already have translated (`IGUI_perks_Mechanics` through
  `UI_ZeD_Craft_SkillLevel`, "%1 Level %2": "Mechanics Level 4"), so translators get no new words. The Cond column
  heading, which sorts today, follows the same rule (under level 4 it is a heading, not a sort). This changes no
  rule of the game: every player still reads each part's condition exactly as now. It is a shortcut that comes with
  experience: "oh, I just reached level four. So now I can just look at the car and I can quickly tell, yep, those
  five parts are bad right there" (the director).
- Sections fold and unfold as today's area groups do.

## 3. The car diagram (right, no part chosen)

- The car seen from above, as the game's parts catalogue picture, with every part drawn in its condition color as
  today's figure does.
- **Hover lights the part.** The pointer over a row, or the controller's focus on a row, lights that part on the
  diagram in its condition color. Hover never changes the right column otherwise.
- **The diagram is clickable.** Clicking a part on the picture chooses it, as clicking its row does (the game's own
  window works this way, and players will try it). Hovering a part on the picture marks its row in the list.
- The condition colors come from the theme's condition tokens, so the colourblind modes recolour them; the lit part
  also gets its outline, so the highlight never rests on color alone.
- **New art (Design):** the diagrams are redrawn in ZeD's pixel style, same shapes as the game's, one layer per part
  as now, for all 13 body shapes (4door, smallcar, sportscar, racecar, stationwagon, suv, offroad, van, truck and the
  four trailers; 327 layers). They drop in through MechFigs: same layer names and anchors. **Build does not wait for
  them:** ship the layout with today's baked figures; the new art replaces the textures when it is done. Modded cars
  keep what they show today.

## 4. The part card (right, a part chosen)

- **Opening it:** a click on the row, A on the controller, or a click on the part in the diagram. **Closing it:**
  click the chosen row again, or B on the controller; the diagram comes back. Scrolling the list with the mouse wheel
  never closes it; the controller's focus moving down the list never opens or closes it (only A does). Choosing
  another part swaps the card.
- **After an action** the card stays on that part and shows its new state (a repair or an install often leads to
  the next step on the same part). This was not settled out loud; it is the predictable choice, and the director
  may change it.
- **What it holds:** what today's card holds, in the narrower column: the progress band, the stat grid, the install
  pick list or the repair recipes, the NEEDS checklist for the chosen verb, the part's own info text. Plus:
  1. **The step before.** When a part cannot be worked on until another comes off (brakes behind the tire), the
     card says so first ("Uninstall the Front Left Tire first", from the game's words where it has them) and offers
     a button that chooses that part.
  2. **Spares and tools in reach.** The compatible parts and the tools the player has in reach, and where each is
     (as the install list and NEEDS do now), so the player knows before pressing.
  3. **The values beyond condition** on their own parts: tire pressure, battery charge, fuel in the tank, a light's
     bulb (whatever the part carries; the game's own words).
  4. **Where the work is done.** The game walks the character to the part (the hood, a wheel, a door); the card
     names the place so the walk is not a surprise.
- **The footer:** the verbs, the same buttons and the same rules as every other card: lit when they can be done,
  grayed with the reason when not (skill, tool, part, the step before). Destructive verbs confirm in the footer as
  now. X / right-click on a part still opens the game's own part menu.

## 5. The controller

- Focus walks the list; the diagram lights the focused part. A opens the card; B closes it (B on the list with no
  card open leaves the tab as it does today). From the list, right moves into the card's verbs and left comes back,
  as in Crafting.
- The focus lands where Crafting's does after the same steps (card opened: its first lit verb; card closed: its row).

## 6. Unchanged

The inspection flow and its six tiles; reach; the vehicle switcher; the trailer's animal page (MechTrailer.lua); the
game's part menu on X / right-click; the walk-and-queue of the game's own handlers; the success and failure flash.

## 7. Words

Reuse before adding. Known reuses: `IGUI_perks_Mechanics` with `UI_ZeD_Craft_SkillLevel` (the level gate), the
game's `IGUI_VehiclePart*` names, `IGUI_Missing`, Crafting's sort words where they fit. New keys only where nothing
says it; list them in the build note so the translation guard and the three shipped languages get them.

## 8. Checks (QA)

- Both sorts; By condition grayed under Mechanics 4 with "Mechanics Level 4", usable from 4 (set the level in the
  test); the Cond heading follows it.
- By section: the brake under its tire, the window under its door, a modded car's parts grouped by its own install
  table (one of the Supported vehicle packs).
- A missing part keeps its row and installs from it.
- Hover (mouse) and focus (pad) light the part on the diagram; a click on the diagram chooses the part; hover never
  swaps the right column; the mouse wheel never closes the card.
- Click / A opens the card, the same row again / B closes it, another row swaps it; no back arrow anywhere.
- The step-before line and its button; spares and tools with where they are; tire pressure, battery charge, fuel.
- Every verb lit or grayed with its reason, an install and an uninstall done for real (zedqa_mech, zedqa_mech2), the
  card staying on the part after.
- Colourblind modes: the lit part reads by its outline as well as its color.
- At 4K, the Steam Deck and 720p (the narrower column); the trailer page still works (zedqa_trailer).
