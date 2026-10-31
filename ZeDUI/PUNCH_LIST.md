# ZeD-GUI punch list

The handoff between the QA session and the build session (director, Oct 30 2026, "ZeD-GUI QA
overhaul and punch list"). QA writes findings here and never fixes them; the build session works
from it; the director sees everything and decides. The director's notes go here at any time,
even while a check is running. Nothing is dropped: an idea lands here.

Each finding: what is wrong, where, how it was found; the cause in plain words; the ways to fix
it with their trade-offs; then the director's choice. A fix waits for that choice (a "put it
back to spec" for something already locked still waits for a yes).

States: **open** (found, no choice yet), **chosen** (the director picked a fix: build may start),
**fixed** (build says done; QA to confirm), **confirmed** (QA checked it in game).

## Open

1. **Right-click broken in t12.** fixed (t13, staged Oct 30) - QA to confirm on the uploaded build.
   How it got through: no script ever right-clicked an inventory row; 19 build the menu by calling
   the game's menu code directly, so the path from the mouse to the row was never used.
2. **The radio drawer is full width; it was designed half width.** fixed (build, Oct 30, 8abb840): a
   walkie tab is the half card at every scale from 0.75 to 2.0 (full only at about 0.64); QA to confirm.
   Write every panel's designed width (half or full) where the tests can measure it in game.
   Cause (build, Oct 30): a walkie's 220 px panel, at a whole zoom plus the scrollbar, is wider
   than the half card at every scale (about 265 units at 1.75 against 220). Since the two-widths
   rule (Oct 29) a drawer is exactly half or full, so it rounds up to the full card; before, it
   opened at the walkie's own width, a third width. Choice: the walkie goes to Design with item 3,
   drawn to fill the half card at every scale (panels 154 / 180 / 206 / 257 px); it stays full
   width until then. Ordinary radios, the CD player and TVs (chosen Oct 30): their own faces from
   Design, radios and the CD player in the half card, TVs in the full card, house radios and TVs on
   the same faces. Request: `ZeDUI/REQUEST_design_radio_tv_faces_20261030.md`. Washers and dryers
   next; then the pocket watch, alarm clock, timer, remote and pager (ideas, not yet asked for).
   **QA, Oct 30 (in game, 4K, 3ed5369, the director's yes):** passed. A ValuTech walkie in the hand: the
   Radio tab is the half card at 0.75, 1.0, 1.25, 1.5, 1.75 and 2.0 (its 154 / 206 / 257 / 154 / 180 / 206
   face), VOL powers it at each. Equipping it leaves the window on Loot; the Radio tab appears (3ed5369's
   rule). The two-way test (all walkies, ham sets, full view, the controller) passed at 1.75. Ordinary
   radios and the CD player (zedqa_rtv, 90 checks): own face, the half card, power, volume, tuning,
   presets, battery, headphones and the disc list by mouse, POWER the controller's first stop, the simple
   card with faces off; placed sets picked by their tiles, TVs in the full card. Not covered yet: the TVs'
   power, channels, the antique's dial and knob and the screen states (the test set them down outdoors,
   no grid, so it skipped them); a house radio and TV found in the world; the lists with the controller.
3. **Plates at every scale (design first).** fixed (build, Oct 30, 8abb840; Design's
   HANDOFF_plates_fill_20261030.md); QA to confirm, the `@` textures loading first. At 4K on 1.75 the 336
   pixel plates sit small in their cards. Rule: scale scales everything. Choice: each plate re-laid
   at four widths that fill the full card, 336 (0.75, 1.5), 392 (1.75), 450 (1.0, 2.0 and up), 562
   (1.25); the game draws the widest that fits (85-100% between the listed scales); 0.5 dropped;
   the 200 pixel narrow faces stay for Auto on 720 or 800 high screens with the smallest font.
   Request: `ZeDUI/REQUEST_design_plates_fill_20261030.md`. The test checks the right width loads
   and fills its card, crisp, at every scale.
   **QA, Oct 30 (in game, 4K, 3ed5369, the director's yes; zedqa_plates_fill.lua):** passed but for one
   check. All 142 `<pid>@<W>` textures load. At 0.75, 1.0, 1.25, 1.5, 1.75 and 2.0 the range, both
   microwaves, the generator and the grill draw the face that fills the card (336 at 0.75 and 1.5, 450 at
   1.0 and 2.0, 562 at 1.25, 392 at 1.75) and every press acts: the oven's BAKE 175 START, TIMER 0:30,
   CANCEL; both microwaves' TIMECOOK 1:00 START and STOP; the generator's switch on and off; the grill's
   tank and burner. At 0.64 the narrow faces are drawn and the same presses act. The ham set draws the
   width that fills the drawer at 0.75, 1.0, 1.25, 1.75 and 2.0 and its narrow face at 0.64; at 1.5 the
   World window's Radio tab did not open within the test's wait, so 1.5 is not confirmed for the ham (a
   test timing question, re-run). Not covered: an object card with and without its scrollbar; ham tuning
   and memories at scales other than 1.75. Shots: Screenshots/zqa_pfill_scale<NNN>_<what>.png.
4. **Disclosures:** every one opens and closes properly. open.
5. **Screenshots show everything open:** disclosures expanded (Foraging especially). open.
6. **Buttons:** every button clicked, its result checked; a list of every button and its expected
   result. The item card's back key: fixed in t13 (now an X); the rest open.
7. **Hover flicker:** hints and tooltips settle and hold. The window box and close box: fixed in
   t13 (their help was stamped in an update that runs every 100 ms). The ZeD style menu: open,
   cause not yet checked.
8. **Controller only:** every button and tab reachable, focus never lost or stuck. open.
9. **Keyboard:** shortcuts, Escape closes things, typing in fields doesn't trigger game keys. open.
10. **Save and reload:** settings, window positions, themes survive a restart. open.
11. **Themes:** every screen in dark, light and high contrast, no unreadable text. open.
12. **Edge cases:** empty containers, hundreds of items, long names, broken items, full items. open.
13. **Resizing:** windows at their smallest and largest. open.
14. **Errors:** no new console errors after a run. open.
15. **Performance:** no stutter opening big containers. open.
16. **Other mods:** a short run with a few popular mods on. open.
17. **Faces or simple cards (director, Oct 30).** chosen. One switch in ZeD setup, faces by default,
    for the devices shown in cards: radios, TVs, walkie-talkies, ham sets, ovens, microwaves, fryer,
    grill, generators (not the car radio, siren, dashboard or watch). Simple cards exist only for the
    radio tab today; the machines' simple cards are new. Build to write the plain rules and the
    simple cards' layout for the director before building.
18. **Every added feature can be turned off; off by default for a vanilla run (director, Oct 30).**
    chosen. Three presets touch only the additions (never the look: theme, accent, text, scale,
    see-through, hidden actions):
    - **Vanilla** (a new player's start): every addition off.
    - **Vanilla Plus:** every addition on, Restock Casual, faces.
    - **Vanilla Access** (was Accessible; director, Oct 30: "everyone needs access controls"): every addition on, Restock Access, simple cards (item 17, when built).
    - The additions: ammo on the belt, read marks, next level on skill books, dim read items,
      dashboard lamps, moodle notices, Messages (keep notes, toast), put things back, sandbox options
      in game, Loadouts and outfits with Journal lists (new switch). Restock follows Loadouts.
    - Rules: picking a preset sets every addition; changing one by hand makes it Custom; Custom keeps
      the hand picks, so it can be gone back to; Loadouts off hides saved loadouts and outfits,
      never deletes them. Existing players keep their saved settings.
    - **fixed (build, Oct 30, 872b207)** - QA to confirm in game (with the director's yes). Check: the
      four preset words fit as radio buttons in ZeD setup's new Additions group; each preset moves the
      switches, a hand change flips to Custom; Custom brings the hand picks back after Apply and a
      restart (`Zomboid/Lua/ZeD_custom_additions.txt`); a fresh ModOptions.ini starts on Vanilla, all
      off; Loadouts off hides the Equip fold, pickers, Journal tab, item card's Lists mark and menu,
      the wheel's Loadouts ring, restock and its pin, and on brings them back unchanged; the game's
      Mods page stays consistent after Apply. The runner now sets Vanilla Plus for every run.
    - **QA, Oct 30 (in game, 4K, the director's yes):** passed. The four presets fit in one row
      (Vanilla | Plus | Accessible | Custom); Vanilla turns every addition off, Plus every one on with
      Restock Casual, Accessible with Restock Accessible; a hand change (read marks off) reads Custom;
      Vanilla then Custom brings the hand picks back; Apply stores Custom and writes the set to
      ZeD_custom_additions.txt; after a restart the main menu still reads Custom with the same values,
      and Custom comes back from the file with nothing held; a fresh ModOptions.ini starts on Vanilla,
      all off. Loadouts off: the Equip fold, the Loadouts ring and Save to loadout are gone, Restock
      doesn't start and a running one is stopped; on again, all three are back. The settings file and
      the screen agree after every Apply (the game's own Mods page itself was not opened).
      Two notes for the director, not failures: the preset buttons read "Plus" and "Accessible", not
      "Vanilla Plus" / "Vanilla Accessible"; with Loadouts off the Restock row still shows its choice
      (Casual) as if it applied. Screenshot: ZeDUI/qa/Oct30_mouse_pass/qa18_additions_group.jpg.
19. **The Restock row dims while Loadouts is off (director, Oct 30: "Yes, dim it").** chosen.
    Found by QA in item 18's check: with Loadouts and outfits off, ZeD setup's Restock row still shows
    its choice (Casual) as if it applied, though Restock does nothing then. Choice: dim the row while
    Loadouts is off (live, as the Loadouts switch is ticked on the screen); its choice is kept and
    comes back when Loadouts is on. Build to write the plain rule (when it dims, whether it can still
    be changed while dim) before building. Still open: the preset buttons read "Plus" and
    "Accessible" rather than the full names (no choice yet).
    Rule (director, Oct 30: "a"): while the Loadouts switch's pick on the screen is Off (before
    Apply too), the Restock row is dimmed and inert: clicks and presses do nothing, the controller
    passes over it, and the help line reads "Turn on Loadouts and outfits to use Restock." Its pick
    is kept; Loadouts on brightens it with that pick. Presets follow the same rule.
    **fixed (build, Oct 30)** - QA to confirm: untick Loadouts, the row dims at once, clicks and
    the controller skip it, the help line shows; tick it, the row comes back with its pick.
    **QA, Oct 30 (main menu Options, ZeD setup, real mouse clicks at 4K, the director's yes):** passed.
    Unticking Loadouts dims the Restock row at once; a click on its Hardcore while dim leaves it on
    Casual; with the pointer on the row the help line reads "Turn on Loadouts and outfits to use
    Restock."; ticking Loadouts brings the row back bright, still Casual. The controller passing over
    it was checked in the code (the pad's row handlers return early for it), not with a pad in game.
    Notes for the director: the dimmed row still lights up under the pointer although it takes no
    click; Restock's third button reads "Access" at this window width (it read "Accessible" in item
    18's shot). Screenshot: ZeDUI/qa/Oct30_mouse_pass/qa19_restock_dim.jpg.
    **QA recheck, Oct 30 at 3ed5369 (in game, items 18 and 19):** the presets, Custom, Apply and Loadouts off /
    on passed again (20 checks); the words now read Vanilla | Vanilla Plus | Vanilla Access and Restock
    Hardcore | Casual | Access. The dimmed row was not in this run's shots (it scrolled past); unchanged
    since item 19's check.
20. **A dimmed row takes no hover highlight (director, Oct 30: "Yes, no highlight").** chosen.
    Found by QA in item 19's check: with Loadouts off, the dimmed Restock row still lights up under
    the pointer although it takes no click. Choice: no hover highlight on a dimmed, inert row (the
    help line still says why when the pointer rests on it). Build to say whether the same goes for the
    other dimmed rows (settings that do nothing with ZeD active). Still open: Restock's "Access" cut
    short at some window widths; the preset buttons' short names (no choice yet).
    Build's note (Oct 30): "Access" is the director's rename (it replaced "Accessible", which was cut
    short), not a cut; the short names were read as kept (Vanilla | Plus | Access | Custom). Waiting:
    the director's pick on whether every dimmed row (the greyed game settings too) loses its highlight.
21. **One header strip and one footer band for every tab card (director, Oct 30).** chosen (every
    tab decided, below). Goal: the same strip sizes and layouts on every tab, actions in a consistent place.
    Draft rule (build): a header strip of one fixed height on every card (left: what the card is, its
    name, browse arrows or sub-tabs; right: tools for its content, search, filters, view switches);
    a footer band of the same height at the card's foot (left: view and mode choices; right: actions,
    the main one last). Decided: a tab with nothing to show or do there has no footer band ("nothing
    to show or do, nothing there"). Today (sheets in ZeDUI/qa/Oct30_tab_strips/, from the short-window
    walk): tops range from none to three rows (Craft: two drop-downs, search, sort strip; Maps: two
    toolbar rows; Furniture: title and five mode buttons); bands only on Craft and Build (recipe pane
    only), Animals, Vehicle and the inventory lists. Next: a clean capture of every tab for the
    review (QA: tall windows, English, the stocked character, the card cropped; about 20 minutes on
    the second screen, the director's yes first), then go through the tabs one by one, Maps first.
    Clean capture done (QA, ZeDUI/qa/Oct30_tab_strips_clean/, measurements.md): the standard header is
    65 px at 1.75, the window's help line 39 px, a card's band 64 px above it.
    - **Maps (director, Oct 30):** header strip: the fold arrow, the six stamps, Aa, the inks, full view
      at the far right; nothing else at the top. Footer band: Survey | Color | Paper on the left, the
      marks list on the right. The second toolbar row goes; the map runs from header to band.
    - **Craft and Build (director, Oct 30):** header strip, one row: Station, Category, Search (Build:
      Category, Search). Footer band, full width: Sort as a pop-up menu ("Sort: Craftable") and Show:
      Ready on the left; the amount (- 1 +) and Craft / Build, last, on the right, shown greyed until a
      recipe is picked so the band never changes shape. The search and sort rows go.
    - **Furniture (director, Oct 30):** the five modes (Pick up, Place, Rotate, Disassemble, Repair) become
      sub-tabs in the header strip, as Animals' Ranch | Butcher; the title line goes. No band (the
      actions are on each piece in the list).
    - **Forage (director, Oct 30):** header strip: the place name left, the category drop-down right.
      The day arc and its readings stay at the top of the body. Footer band: Crouch and Aim on the left
      (read-only status), Searching on the right as the main action (a button: Search / Stop searching).
    - **Radio (director, Oct 30):** header as it is (browse arrows, where, name); the brand strip at the
      bottom goes with the new faces (the brand is on the face). No band.
    - **Rule added (director, Oct 30):** a fold inside a card keeps its own controls; the card's band is
      for actions on the whole card.
    - **Equip (director, Oct 30):** header as it is (Equipped, List | Doll on the right). The Loadouts
      fold keeps its controls inside it. No band.
    - **Health (director, Oct 30):** the body keeps the figure, the injuries and the picked exercise's
      description. Footer band: the exercise as a pop-up menu and Time (- 10 +) on the left, Start on the
      right (pick, then act, as Craft); the seven exercise buttons go.
    - **Thermal (director, Oct 30):** the seven view radio buttons become a pop-up menu in the footer
      band, left ("View: Skin temperature"); the Core / Air / Wind readings move up beside the figure.
    - **Identity (director, Oct 30):** Cut moves into the Hair and beard fold beside Hair | Beard (the
      fold keeps its own controls). No band.
    - **Journal (director, Oct 30):** the five pages become a pop-up menu on the header's left ("Page:
      Journal"), Search on the right: one row, as Craft. Each page's own controls go to the band:
      Journal: Save on the right (the write box stays in the body); Papers: Show (All, News, Flyers,
      On map) as a pop-up on the left; Recipes: Category, Sort and Show on the left, as Craft;
      Loadouts: its buttons on the right.
    - **Skills (director, Oct 30):** no header or band change; its bars follow item 22.
    - **Inventory and Ground (director, Oct 30):** done as they are (container name and List | Grid in the
      header, the container buttons in the band). Animals and Vehicle already follow the rule.
    - **All tabs decided (Oct 30): chosen, ready to build** after the face jobs (they share files).
22. **Segmented bars everywhere (director, Oct 30: "keeping it 93; the segments help info at a
    glance").** chosen. Every fill bar (the shared fill bar: list condition, Health, Protection, animal
    food and water, fuel, item cards, Skills ...) becomes a row of 10 separate segments, lit or dark,
    never part-lit. Skills: one segment per level. Rounding is strict: a segment lights only when its
    whole tenth is reached (4% shows none). Pointing at a bar puts the exact value in the help line
    ("Condition 64%", "Fitness 5, 40% to level 6"). Not changed: Thermal's temperature scale with its
    needle, the dash gauges, and progress bands (the action bar, crafting, uploads) stay smooth.
    **QA, Oct 30 (in game, 4K, 1355c3f, the director's yes):** the lit counts pass (64% lights 6, 4% 0,
    100% 10, 0 0, 70% 7, 30% 3, 99.9% 9), ten distinct cells at the narrowest bar (42 px), a skill at 5
    lights 5, the Skills help words ("Fitness 5, 40% to level 6"). The help line under the pointer was
    skipped (the controller's cues were showing). Shots: Skills, the Equip list and doll, Health,
    Thermal (zqa_bars_*.png). Speed: no stutter. Every tab costs what it did at t13 (8.3 to 11.5 ms a
    tick; Thermal 11.5 against 9.7, Equip 10.5 against 12.4); 400 tools on the ground 10.6 ms still and
    10.9 ms scrolling against 8.5 ms empty. The tools stacked into 10 rows of 40, so a list of hundreds
    of separate rows is still to try. The animal pen's bars were not shown (the pen did not register in
    time).
23. **A TV's channel buttons stop at the ends: CH down on channel 1 and CH up on 12 throw an error.**
    chosen (director, Oct 30: "Yes, first options"): (a), wrap round. Found by QA, Oct 30 (zedqa_rtv at 1355c3f): on the black and the widescreen TV, CH down from the
    first channel and CH up from the twelfth do nothing, and the game logs an error in the mod
    (RtvFace.lua, the channel step: "attempted index: freq of non-table"). Cause: the step works out the
    next channel with a remainder, and the game's Lua gives a negative remainder for a negative number
    (other Lua gives a positive one), so "one below the first" comes out as channel 0, which does not
    exist. Options: (a) wrap round, as the test and the design expect (CH down on 1 goes to 12, CH up on
    12 goes to 1); (b) stop at the ends without an error, as the antique's dial does.
24. **The laundry card opens at half width with the small face.** chosen (director, Oct 30: "Yes, first options"): the card opens full width
    (the face that fills it follows) and the water amount goes after its label. Found by QA, Oct 30
    (zedqa_laundry at 1355c3f): the gears button opens the card, but at the half card (about 430 px at
    4K, 1.75) with the washer's, dryer's and washer-dryer's narrow faces, not the full card with the
    392 face; the header's name is cut to "Whi..."; under the face the water amount ("10000.0 of 10000
    L") is written over its own "Water" label. With no power the meter is dark and the drum still shows
    its water, as asked. The test's power-switch checks fail on all three machines though each is
    seen running afterwards: not yet clear whether that is the test or the switch. Shots:
    zqa_ldy_*_1_open.png. Options: the card opened full width, as the handoff says (the face that fills
    it follows); the value placed after its label.
25. **The Character window shows a "Tab content - placeholder" drawer.** chosen (director, Oct 30: "Yes, first options"): when the Radio tab goes
    away, the window goes back to Loot with the drawer shut. Found by QA, Oct 30 (a
    zedqa_rtv shot, zqa_rtv_4d_tv_black_triple_n_standby.png): after the radio left the hand while
    its Radio tab was open, the Character window's drawer stayed open with "Loot" and "Tab content -
    placeholder" in it. Cause not checked. Options: the window goes back to Loot with the drawer shut
    when the Radio tab goes away (the rule when a tab's thing leaves); or it stays on an empty Radio tab
    until the player moves.

## Test process

- The release check (before every upload, about 5 minutes, pass or fail): right-click opens the
  menu, both windows open, an item moves, the controller works, the watch reads the time. Not
  built yet.
- The full pass's own problems (found in the t13 run, Oct 30): world_pad_take depends on where
  the Eraser sits in the QA character's bag; two_widths depends on the test before it leaving a
  card open; dash_green's fire truck won't pass 2 km/h at the drag strip; px_icons has a first-run
  fluke. The dashboards take 15 of the pass's 57 minutes. The QA save drifts between runs.
- Washers and dryers (zedqa_laundry, Oct 30 at 3ed5369): not checked. The test sets the machines down two
  squares from the character, outside the World window's reach, so they never appear in its container
  list (the shot shows only Ground) and every check after the first few fails on that. The test needs
  the machines within one square. The game's own messages also show Java errors when a set is placed
  before it has a square (zedqa_rtv; test order, not the mod).
- The QA character has lost its deep-run state (Skills mostly 0, 11 days survived, light bags).
- The QA save's grid (Oct 30 at 1355c3f): ElecShutModifier reads 99999 and the world's power flag reads on
  both before the first script and after the last (zedqa_power_probe.lua, pw0 / pw1). The scripts put back
  what they found, but what they found was already raised: an earlier run left it so, or the save was made
  that way. The save is not at no grid. Restore it from the D: backup's QA save, or set it back once by hand.
- The second pass at 1355c3f: zedqa_laundry and zedqa_rtv now reach their machines and sets (indoors, on
  the grid). rtv: the antique's dial, knob push / pull and the controller pass; the house radio and TV
  resolve to their faces; the battery, headphone and disc / tape lists by controller open and return
  focus. Still not seen: a picture, a sign-off and the station logos (every station was between
  broadcasts at that hour: standby on 2 to 11, bars on 12 and 13). Its 19 Java NullPointers are still
  vanilla's (a set given its device data before it is on a square). zedqa_segbars finishes before the
  bridge logs its run line, so the runner never sees its DONE and stops (a TIMEOUT that is not one).

## Confirmed

(none yet)
