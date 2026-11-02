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
    - **fixed (build, Oct 30, 656d9f5, merged 5bf1e90)** - QA to confirm, mouse and pad, 4K and 1280x800:
      every pop-up opens (in a band, upward), picks and returns focus to its box; Craft/Build band with
      and without a recipe, alternatives mode, focus stays on Craft after crafting; Maps header row,
      the delete question in the band, down from the map reaches the band; Forage Search toggles, Crouch
      and Aim follow the character, the pad enters on Search; Health Start, greyed with a reason when
      blocked; Identity Cut right after Hair | Beard; Journal pages, Loadouts off while on that page,
      the Delete question; Furniture's five sub-tabs; no dead stops, nothing wider than the card, the
      help line under every band. A new shared control: the pop-up menu (Molecules drawPopupMenu).
      Build's calls, for the director: Craft's Show is a pop-up (Ready / Known / All) rather than the
      old checkbox; the Loadouts band reads "Save loadout" / "Save outfit"; the max beside Craft's
      amount is gone; an exercise you can't do stays in the list and Start greys with the reason;
      Maps' band holds both the Key and the players-and-notes list on the right. Open: the walkie and
      ham faces keep their printed foot (brand, "2-WAY PORTABLE"), part of the face art.
    - **built (Oct 30), not yet seen in game.** Maps, Craft and Build, Furniture, Forage, Health, Thermal,
      Identity and Journal as decided; Radio's drawn chassis lost its brand strip. Not exactly as decided:
      Craft's Show is a pop-up (Ready / Known / All) rather than the old cycling box; the Loadouts band
      uses short words ("Save loadout", "Save outfit": the long ones do not fit the full card); the
      number beside Craft's amount is gone; an exercise you cannot do stays in the list, Start greyed
      with the reason. Open question: the walkies' and ham sets' faces still have their 22u foot with
      the brand and "2-WAY PORTABLE".
    - **QA, Oct 30 (in game at 4c8d951, 4K at 1.75 and 1280x800, the controller simulated; the director's
      yes; zedqa_bands_probe.lua):** passed: every tab's card is the half or the full card at both sizes;
      Craft's and Build's Sort and Show pop-ups (with and without a recipe) open on A, a row picks, the
      list shuts and the focus is back on the box; the Journal's page pop-up the same on its first pages;
      Furniture's five sub-tabs are stops; Identity's Cut comes right after Hair | Beard; the tab and
      controller suites pass. Found (not yet chosen):
      a. Health's exercise list and Thermal's View list (4K): Down from the open list's first row leaves the
         list for the body figure (bodypart:Head / thermalpart:Head), and the list stays open. At 1280x800
         they were right.
      b. The Journal's page list on the Loadouts page (both sizes): the focus starts on the last row; Down
         leaves the open list for the tab strip (tab:journal), and the list stays open.
      c. Health at 1280x800 with Large text: Down from the figure stops on Right Foot; the band (Exercise,
         time, Start) is not reached by Down (at 4K it is: the foot, then the Exercise box).
      d. Identity: Cut's controller stop is not where its button draws (zedqa_hairbeard, both sizes).
      e. The exercise list shuts itself when the tab has not drawn for 300 ms (a hitch, or a screenshot):
         zedqa_exinfo's pop-up checks fail at 4K for that reason and pass at 1280x800.
      f. At 1280x800 the game's own Character Info panel ("Discovered Recipes and Media", "Zombies Killed")
         shows under the ZeD windows in every shot of the run; cause not checked (a script may open it).
      Not covered: the pop-ups with the mouse; the Maps delete question; Forage's Search toggle and Crouch /
      Aim following the character; Start greyed with a reason; the Journal's Delete question and Loadouts
      turned off while on its page; the focus after a craft; alternatives mode; the help line's words under
      each band.
      **Chosen (director, Oct 30: "Fix first"): a to f fixed before t14 goes up.** Build to write the plain
      rules first (an open list keeps the controller inside it until a pick or B; Down from the figure
      reaches the band at every size; Cut's stop on its button; an open list shuts only on a pick, B, a
      click elsewhere or leaving the tab; f: find what opens the game's Character Info panel). Then QA
      checks a to f and the parts not covered, and t14 is staged.
      **fixed (build, Oct 30), a to f, QA to confirm.** The rules built: an open pop-up list holds the
      controller (Up / Down stop at its ends, Left / Right do nothing; A picks, B shuts it; either way
      back on its box), on every pop-up list (Craft and Build's Sort and Show, the Journal's Page list
      and its pages' lists, Health's exercises, Thermal's views, the map's Survey / Color / Paper); a
      list opens on the row chosen now; a list shuts only on a pick, B, a click outside it or leaving
      its tab (the drawer folding or an item card over it counts as leaving), never because a draw
      came late. a, e: the late-draw rule was what shut Health's and Thermal's lists; it is gone. c:
      the body's stops now follow its scroll (Health, Thermal, and Forage's fold too), a stop hidden
      under the band is no stop, and the lowest one shown scrolls the body on, so Down always ends in
      the band. d: Cut's stop is its button, where it is laid out, scrolled or not. f: the game set
      its window showing from the saved layout after ZeD had cleared the start-up flag; now it is
      hidden after that, kept hidden over a game's first seconds, and its saved layout says hidden
      while ZeD is on (layout.ini itself not touched). Scripts updated: zedqa_bands_probe,
      zedqa_exinfo, zedqa_health_padprobe, zedqa_hairbeard, zedqa_charinfo.
      **QA re-check, Oct 30 at ae4b30d (4K, the director's yes): stopped, a blocker. g. Opening the Thermal
      tab throws an error every frame and ZeD's safe mode steps aside ("ZeD-GUI stepped aside (tab
      thermal)"; the game's own interface comes back). Cause: ae4b30d keeps the Thermal body's scroll area
      in win._thermalView (ThermalTab.lua 271), the name that already holds the chosen view (1 to 7), so
      the figure then looks up a view by a table (ThermalTab.lua 549, "attempted index: id of non-table").
      Options: the scroll area under a name of its own (the view keeps its number). Not run after it: the
      1280x800 pass, hairbeard, charinfo, the uncovered parts (zedqa_uncovered21.lua); t14 not staged.**
      **g chosen (director, Oct 30: "Yes, fix it"): the scroll area under a name of its own.** Then QA's
      re-check (asking for the screen), and t14 staged if it passes.
      **QA re-check at fcf5854 (Oct 30, 4K and 1280x800): passed.** a to g hold: the pop-ups hold the
      controller and give the focus back (Health, Thermal, Journal on every page, Craft, Build); Down from the
      Health figure reaches the band at 1280x800 with Large text; Cut's stop on its button; the exercise list
      stays open; the game's Character Info window stays hidden at 1280x800; Thermal draws. And what the
      first check left out: the mouse on the pop-ups (Health, Thermal, Journal, Craft) opens, picks, shuts;
      the Maps delete question is in the band with Cancel and Delete; Forage's Search turns search mode on
      and off; Start sitting down is greyed with "Stand up before exercising."; the Journal's Delete asks in
      the band and Cancel puts it away; the focus stays on the craft key after a craft.
      **The full pass before t14 (fcf5854, 4K; 2026-10-30_t14_fullscreen4k.md): t14 not staged.** Two new
      failures since t13:
      h. Radios and TVs by controller (zedqa_rtv, 19 of 214 fail; all passed at c5090f6): the faces'
         battery, headphone and disc / tape keys are no longer controller stops (the CD player, the black
         TV), and on the antique TV A on the knob and Up on the knob or the dial do nothing. Likely from
         ae4b30d's controller changes; cause not yet checked.
      i. A bag inside a bag (zedqa_wt_bracket): "the pack's column did not open beside the bag" (passed at
         t13). Cause not checked.
      The rest as at t13 (world_pad_take, px_icons, dash_green: the known flakes; restock's lines are the
      game's own "Vehicles.Init.Radio" messages).
      **h and i chosen (director, Oct 30: "Yes, fix both"):** the radio and TV faces' controls are controller
      stops again (A opens their lists, the antique's knob and dial answer), and a bag's pack opens its column
      beside the bag. Then QA re-runs zedqa_rtv and zedqa_wt_bracket and the full pass, and stages t14.
      **QA, Oct 30 at c10d755:** both were the tests (build's notes above); the full pass
      (2026-10-30_t14b_fullscreen4k.md): zedqa_rtv 192 passed, 0 failed (its FAIL mark is the game's own
      NullPointers when a set is placed); zedqa_wt_bracket "char columns 2", held. Two warnings new since t13
      (plates_336's generator start, dash_keys_edge's Cossette key) passed on a re-run alone
      (2026-10-30_2240_fullscreen4k.md). **t14 staged from 75a2e64** (4,277 files, 42.83 MB; 24 untracked
      wheel icons another session made at 23:01, used by nothing yet, taken out of the staged copy);
      description 7,929 + 58; change note in ZeD_workshop.txt; zedqa.lock busy until the upload.
      **h fixed (build, Oct 30): cause in the test, not the game.** zedqa_rtv handed its pad steps the window as
      it stood when the script loaded (zedqa_rtv.lua 318-321, 713-716). In the full pass zedqa_sandbox_ig shuts
      both windows before it and the script opens them in its own steps, so the window was nothing: the step that
      enters the tab threw ("_focusEntryZone of non-table", step 51/131/276), the pad never reached the face, and
      the slot / phones / battery and antique knob checks failed after it. The short runs that passed had the
      windows open already. The pad steps now ask for the window when they run. Nothing in the game changed:
      the stops were there (the same run's "every control is a stop (9)" passed).
      **i fixed (build, Oct 30): cause in the test, not the game.** The Character window reads its bags again
      every 30 of its own frames (ZeD_CharacterWindow.lua 3226, drawn at the UI's rate, uiRenderFPS=60), and the
      test asked for the pack's column a fixed 30 game ticks (up to 120 a second) after putting the pack on: about
      half the wait, so it passed or failed by luck (the run's own capture a moment later shows the pack in the
      strip). zedqa_wt_bracket now waits until the window lists the pack (up to 3 seconds). QA to confirm both.
      **g fixed (build, Oct 30):** the scroll area is win._thermalBodyRect; win._thermalView is the view
      number again. Every field ae4b30d sets was checked against its earlier use: the others
      (_focusIdx, _focusPendingEntry, _navLast) keep their meaning; _thermalPinned is new. QA to confirm.
      Test-side: zedqa_two_widths sees both windows 4 px off after closing a card at 1280x800 (the
      known order flake); zedqa_laundry's dryer dial check failed once at 1280x800; the band probe opened the
      Maps pop-out (not a list) and left it open. Shots: Screenshots/zqa_band_*.png (the 1280x800 run's).
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
    **fixed (build, Oct 30):** the step adds the stop count before the remainder, so it wraps both ways.
    **confirmed (QA, Oct 30, c5090f6, in game):** on the black and the widescreen TV, CH down on 1 goes to
    12 and CH up on 12 goes to 1, no error (zedqa_rtv: 212 passed, 0 failed).
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
    **fixed (build, Oct 30). Cause of the "half card": the test.** The card opens at the full card; the
    test measured it, and took the _1_open shots, while the drawer was still sliding open (each frame
    picks the face that fits the room it has then; the later _2_running shots show the full card and
    the 392 face). The test now waits for the drawer to finish. The overlap was real: a card's
    label-and-value pair right-aligned the value with no regard for its label, and a piped machine's
    "10000.0 of 10000 L" ran over "Water". Now a value is cut short before its label (every object
    card), and the laundry card puts Water and Inside on a row each. The power switch is fine: the test
    read the card's buttons from the frame before (just after a power change it saw the old state),
    and it expected DRY to act while already in dryer mode; both fixed in the test.
    **confirmed (QA, Oct 30, c5090f6, in game):** zedqa_laundry passes whole: the full card on the washer,
    the dryer and the washer-dryer, the switch acts with power (and water), not without, WASH / DRY, the
    lamps, the dial, the drum. One new thing, item 26.
25. **The Character window shows a "Tab content - placeholder" drawer.** chosen (director, Oct 30: "Yes, first options"): when the Radio tab goes
    away, the window goes back to Loot with the drawer shut. Found by QA, Oct 30 (a
    zedqa_rtv shot, zqa_rtv_4d_tv_black_triple_n_standby.png): after the radio left the hand while
    its Radio tab was open, the Character window's drawer stayed open with "Loot" and "Tab content -
    placeholder" in it. Cause not checked. Options: the window goes back to Loot with the drawer shut
    when the Radio tab goes away (the rule when a tab's thing leaves); or it stays on an empty Radio tab
    until the player moves.
    **fixed (build, Oct 30). Cause:** when the active tab vanished, the window set the tab to Loot but
    left the drawer open in tab mode, and the drawer drew Loot's missing tab card as the placeholder.
    Now it goes back to Loot exactly as pressing Loot does (drawer shut); an item card stays.
    **confirmed (QA, Oct 30, c5090f6, in game):** the same moment in zedqa_rtv (the radio leaves the hand on
    its Radio tab) now leaves the Character window on Loot with the drawer shut; no placeholder.
26. **On first opening, a laundry card shows only its moving parts for a moment.** open. Found by QA, Oct
    30 (zqa_ldy_washer_1_open.png at c5090f6, taken once the drawer had finished opening): the full card
    shows the water in the drum, the water meter, the drum's mark and the cycle needle, but not the
    machine's body (the white case, the blue panel, the door). A few seconds later (_2_running) the whole
    face is there. Cause not checked: perhaps the face's picture loads a little after the card first
    draws. Not yet known how long it lasts to the eye.
    **QA, Oct 30 (at 4c8d951, 4K):** as chosen: on the first opening the card shows nothing until the face's
    picture is there, then the whole face (zqa_ldy_washer_1_open.png: an empty card, no lit parts alone);
    the next shot, a few seconds on, has the whole face. The wait to the eye was not timed.
    Chosen (director, Oct 30): (b), the face waits for its picture and then appears whole.
    **fixed (build, Oct 30, 80094e3):** every plate face (machines, laundry, radios, TVs, walkies, car radio,
    siren) asks the game whether its picture has finished loading and draws nothing until it has. QA to
    confirm on a first opening, and to see how long the wait is to the eye.
27. **Tabs out of reach at 1280x720, UI scale 2.0, Large text.** Found by QA, Oct 31 (the break-it run):
    both tab columns are taller than the window; Journal, Skills, Radio (Character) and Forage, Animals,
    Radio, Vehicle (World) never came up. Cause: the columns did scroll (the arrow row at their foot, the
    wheel), but nothing brought a tab out of sight into view, so a controller moving down focused tabs
    hidden under the arrow row; the test clicked tabs by position and never scrolled.
    **fixed (build, Oct 31, 37b7af0):** a scrolling column brings the controller's focused tab (else the
    active tab) into view whenever it changes; the arrows and the wheel still look anywhere. The test
    now wheels a hidden tab into view first. QA to confirm with the pad and the mouse.
28. **Pop-up boxes cut to nothing at the same setting.** Found by QA, Oct 31: Health's exercise box read
    "E...", Craft's station box "Station ..". Cause: the words were cut from the end, so the label stayed
    and the choice went. **fixed (build, Oct 31, abd84b2 and 2769824):** when "Exercise: Squats" does not
    fit, the box shows "Squats" (cut short only if even that does not fit), on every pop-up box (Health,
    Thermal's view, Journal's page, Craft and Build's Sort and Show, the lists, the papers); the station
    box leaves out "Station" before the station's name. QA to confirm.
    **Re-run (QA, Oct 31):** Health's box still read "S...", Craft's band Sort and Show were empty (the
    arrow alone) and Craft's Category read "-- A...". Cause: the boxes were narrower than their choice.
    The band shrank Sort and Show by one share of their longest words until neither had room for any
    word; Health's box got only what the time keys left; the header split its row in equal thirds.
    **fixed (build, Oct 31, 3fcdcf7):** a box keeps at least its choice and its arrow ("Squats" v):
    Health drops the time's label, then closes up its spaces; Craft and Build's band closes up its
    spaces and the amount's readout; the header's Station and Category are at least their value
    wide, the search giving the room. Where even that is not enough (Craft's band at this setting),
    each box keeps its first letters and its arrow ("Cr" v, "R" v): nothing empty, nothing
    overlapping. QA to confirm at 1280x720, 2.0, Large text.
    **Question for the director:** at 1280x720, UI scale 2.0, Large text Craft's band cannot hold
    Sort, Show, the amount and Craft in one row with whole words (Sort and Show get about 150 px
    between them; their choices want about 300). Which? (a) at that setting the band wraps to a
    second row (Sort and Show above, the amount and Craft below); (b) Sort and Show become one pop-up
    ("Craftable | Ready", the list holding both choices); (c) the amount's - / + shrink to one
    stepper (a single box with the number, up / down inside it).
29. **The Equip list's names cut short at the same setting ("T-shi... Inner", "Leat... Gloves").** open,
    a design question. Found by QA, Oct 31. Cause: at the half card the list's columns do not fit: the
    name gets its 40-unit minimum, the slot column is as wide as the longest slot name of all, the
    condition bar is half cut and the protection and weight columns are past the card's edge. Which
    gives way at narrow widths? (a) the slot column first (its words cut, "Inn..."); (b) the protection
    and weight columns drop and the name takes their room; (c) the slot column drops (the group heading
    already says where), the name takes its room.
30. **Windows accept any size from code.** Found by QA, Oct 31: a window set to 1920x4320 on a 2160
    screen hung off the bottom; a drag is clamped. A layout saved on a bigger screen, or a screen made
    smaller, could do the same. **fixed (build, Oct 31, 7bf30e1):** after a saved layout is restored and
    on a resolution change, both windows are kept on the screen (no taller than it, no wider, wholly on
    it; the saved width capped at half the screen). A size set by a script mid-game is still taken as
    given. QA to confirm with a resolution change in game.
31. **The item card's "Name this item" box outlived its card.** Found by QA, Oct 31 (the break-it run,
    zqa_bclk_w_vehicle.png): a double click on the card's name opened the box, and it stayed top-left
    through every later tab of both windows, shut cards and a layout reset. Cause: nothing tied the box
    to the card; it went only on OK or Cancel, and a second click opened a second box.
    **fixed (build, Oct 31, b0e9df1):** one rename box at a time (a new one cancels the old), and a box
    opened from a card goes, as Cancel, when that card shuts, shows another item, or its drawer or
    window folds. The item menu's Rename (no card) still waits for OK or Cancel. QA to confirm.
32. **The flyer's full-page reader sat behind both windows.** Found by QA, Oct 31 (zqa_bclk_c_health.png
    onward): a double click in the Loot grid read the Fossoil flyer; the reader opened, then stayed half
    hidden under the Character and World windows until the run quit. Cause: the reader came up on top,
    but each later press on a window raised that window over it.
    **fixed (build, Oct 31, f096c43):** while open, the reader stays over both windows (a menu or prompt
    a window opens still shows over the reader); it already takes the controller, and B or Escape close
    it. QA to confirm, with the mouse and the pad.
    **Question for the director:** should the reader also close when the card (or the Papers page) it was
    opened from closes, or stay open until B, Escape or its close box?
33. **The Character window's title named the wrong tab.** Found by QA, Oct 31 (the break-it run at
    1280x720, UI scale 2.0, Large text): the title read "Angel Cross  +  Equipment" on every tab after
    Equip, Health and Skills included; right at 4K. Cause: the title was written by the inventory side
    of the window, and that side is hidden while a tab card takes the whole window, so the title kept
    the tab open when the side last showed. The World window was built the same way.
    **fixed (build, Oct 31, d59a72e):** both windows write their title themselves every frame (the
    inventory side gives only its part: the bag, the columns, the container), so a click on the
    strip, LB / RB, the D-pad and a script all show. QA to confirm at 1280x720, 2.0, Large text, both
    windows, every tab.
34. **The black TV's screen stayed a plain dark colour (no picture).** Found by QA, Oct 31 (gallery slide
    58, g14_tv_black, and the zedqa_rtv shots). Not the black set itself: its screens, its table entries
    and its pictures on disk are all in order (it drew "Please stand by" in zqa_rtv_4d_tv_black_turbo).
    Cause: the snow between channels, and off the dial, never drew on any TV. The snow picks one of three
    frames from the clock, and the game's Lua gets the remainder wrong on numbers that large, so it asked
    for "snow_7652706499" and found nothing. Every black-set shot happened to land on snow (the gallery
    tunes it off the dial on purpose; the rtv shots caught the next channel change). The same slip kept a
    radio's preset readout from blinking. **fixed (build, Oct 31, 3f1be87):** the frame is worked out
    without that remainder. QA to confirm: zedqa_rtv's tv_black states (snow now moves, three frames),
    and retake slide 58 (g14_tv_black should show snow, not a flat screen).
35. **Skills and Vehicle text run into each other at 1280x720, UI scale 2.0, Large text.** Found by QA,
    Oct 31 (the break-it run, zqa_brk_scale200_large_c_skills / _w_vehicle shots).
    **fixed (build, Oct 31, fa77922, e322052, 5fbb1ba):** a section heading is cut to its own column
    (Skills read "Combat - FirearCombat - Melee"); a label's value is cut to the room after its label,
    never drawn over it (Vehicle read "4Distance"); a header's cut name ends "..." (Vehicle read "Che&":
    the one-character ellipsis drew as "&"); "Not inspected" is cut to the card's edge. Seen the same at the
    Steam Deck's setting (1280x800, UI scale Auto 0.75, Large text, zqa_brk_auto_large_*); the cuts follow
    the room, not the scale, so both settings take them. QA to confirm at both. Note: at both, the Vehicle
    summary column beside the figure is so narrow that Type / Distance / Key keep only their labels (the
    values have no room left and are not drawn); a layout question if it matters.
    **Question for the director:** the Skills rows still cut each skill's name to one letter ("A...") at
    that setting: the level bar and the level number take the room. Which gives way? (a) the bar shrinks
    to its smallest before the name is cut; (b) below a width the bar hides and the level number alone
    shows; (c) at that width the grid goes to one column. Today's look stays until you choose.
36. **Inventory, ID card, Maps and Furniture overlap at 1280x720, UI scale 2.0, Large text (and the
    Deck's 1280x800, Auto, Large).** Found by QA, Oct 31 (break-it E4-E7).
    - Inventory: the heading's "20.4/8kg" sat on the title bar's "20.39 / 8". Cause: the heading's weight
      and item count did not fit its row at that text size, and, centred, ran up over the title bar.
      **fixed (build, Oct 31, 0d8dfa6):** the count goes when both lines do not fit, then the weight; the
      window's foot line still says both.
    - ID card: "Sex" sat on "Male", "Profession" on "Mechanic", the name cut to "Cro". Cause: the rows were
      spaced for smaller text, and nothing kept a field to its column. **fixed (build, Oct 31, 54b9701):**
      every label and value is cut with "..." to its own box, the rows follow the text size, the name ends
      in "...", the weight pill steps aside for the name.
      **Question for the director:** at this setting the photo column leaves the text about 20 units, so
      the fields now read "..." or nothing. Which? (a) the photo shrinks with the card; (b) at narrow
      widths the fields move under the photo, full width; (c) the photo hides at narrow widths.
    - ID card photo: the figure drew below the card, over the window's status line, when the card was
      scrolled or taller than the view. Cause: the figure draws on its own and only its top was kept
      under the tab header. **fixed (build, Oct 31, 93bb7ad):** its top and bottom both stay inside the
      card's view (as the Equip doll's do); it hides when scrolled out.
    - Maps: the header's last stamps, "Aa" and the inks ran under full view. **fixed (build, Oct 31,
      122c060):** nothing passes full view: the stamps close up first, then pinned stamps fold away from
      the end (each is still in the full set under the fold arrow), then inks from the end, then "Aa".
      **Question for the director:** is that the order? At this setting the inks and the note may go
      too, and the ink in use is then not shown on the header. Other choices: (a) the inks become one
      swatch that opens a pop-up of inks; (b) the header keeps only the fold arrow, the note and the
      inks, the stamps all in the fold; (c) a second header row at narrow widths.
    - Furniture: Disassemble and Repair were past the card's edge, out of reach. **fixed (build, Oct 31,
      4603c1f):** the tabs close up, then take the small words; if still too wide the strip scrolls with
      left and right arrows (mouse and pad), the pad's focus and a mode change bring their tab into view.
    QA to re-check all four at both settings, and Furniture's strip with the pad (right past Rotate to
    the arrow, A until the strip ends, focus lands on Repair).

**The break-it pass and t14 (QA, Oct 31 2026, overnight; the director: "Before t14 uploads lets find and fix
the errors. Try to break things ... Unless it involves design input please fix it.")** Found and fixed by build,
each confirmed in game by QA: 27 (tabs out of reach), 28 (pop-up boxes cut; one design question), 30 (window sizes),
31 (the rename box), 32 (the reader behind the windows; one design question), 33 (the title), 34 (TV snow and every
clock-driven blink), 35 and 36 (overlaps at small sizes; design questions). Clean, no errors: windows at 1x1 and
twice the screen; UI scale 0.5 and 2.0, both text sizes; the windows, the tabs and an item card switched every tick;
a real-mouse double-click storm over every tab; 150 random controller presses on every tab; 400 game keys; typing
in the Journal entry, Journal search and Craft search (no game key fires: item 9 for those fields); 300 different
items, a 200-letter name, broken / rotten / full / empty cards, things removed under their open card or column, an
empty inventory. Full pass at 99d3372: 93/97, the rest known (rtv's vanilla NullPointers, px, restock's vanilla
lines, the curtain order fluke, PASS alone). **t14 re-staged from 1e64f9f (game code as 99d3372)**: 4,253 files,
42.8 MB; description 7,929 + 58; change note with tonight's fixes; zedqa.lock busy until the upload.


    **Director's picks (Oct 31 2026, answered in the build session):**
    - **28 (Craft band, smallest screens):** the amount's - / + collapse into one amount control to free room. **built (674ef9f), QA to confirm** (Oct 31 2026, punch list 28/29/35/36): short of room the amount is one box, "< 3 >" (a press on a half, the wheel, or the pad's Left / Right steps it; A steps up, from the most back to 1); normal widths keep - 1 +. QA (Oct 31, 720 2x Large and the Deck Large): Sort and Show still read "Cra..." / "Rea" (720), "Cra..." / "R..." (Deck), and at 720 the box had no pad stop with a most of 1. **fixed again (711fa45):** cause: Craft kept its 60u least and 14u pads, the box, the band's margins and the boxes' pads their usual sizes, so the whole words needed ~576 px of a 508 px band at 720. Short of room now Sort and Show show the choice alone in tight boxes (4u pads), Craft / Build is as wide as its word, the box as its digits, the band's margins and spaces 4u: by the code, 486 of 508 px at 720 with "1" (501 with "10"), 177 of 191 px on the Deck. The missing stop: the World window rebuilt Craft's stops only when their count, ends or scroll changed, and a band changing shape could keep those; the band's shape and the recipe now key it. At a most of 1 the box stays a stop, A changes nothing (Left / Right move on, as at its ends), the help line says "Amount: no more than one can be made now". QA to re-check both settings, with a recipe whose most is 1 and one of 10 or more. QA re-check (c0e43ef): the words fit at both settings; at 720 2x Large the box (AddMotionSensorV3ToBomb, most 1) still had no stop, and the help words read nil on onFocus. **fixed again (98b240d):** cause: 711fa45 keyed the stops' rebuild on state.selected, which changes the moment a recipe is picked, a frame before the draw makes the new zones; that rebuild got the old zones, and the next frame's stops could match the old count and ends. The key is now stamped by the band's draw itself (its shape and the recipe it drew). onFocus puts the help words on the help line when the most is 1. QA to re-check at 720 2x Large. QA re-check (fc3740b): the Deck right; at 720 worldTabContent held only the list's 10 stops, none of the card's or band's. **fixed again (13d56ca):** cause: the World window refreshes the controller's stops in its item list's prerender, and at 720 2x Large the tab drawer takes the whole window, the list is hidden and its prerender never runs, so the stops stayed as they were when Craft opened. The refresh is now a function of its own that the drawer runs while the list is hidden (the 98b240d key was not the cause).
    - **29 (Equip list, half card):** the slot column's words shorten first (e.g. "Gloves" to "Glv"); names stay readable. **built (31441dc), QA to confirm:** Hat, Eyes, Mask, Ears, Scrf, Out, Inr, Vest, Und, Neck, Glv, Wrst, Ring, Arms, Shld, Pnts, Sock, Shoe, Knee, Pri, Sec, Bag, Belt, when the worn names lack room; a width the player dragged stays theirs. QA (Oct 31): the slot words shortened but the names still read "T-shi...", "Leat...", "Sock...", "Milit...". **fixed again (9a50a16):** cause: the columns right of the name (84u condition, three 32u protection, 40u weight, 10u margin) wanted ~270u of the ~205u half card, so the name stayed at its 40u least whatever the slot words freed, and protection and weight drew past the card's edge, unseen. Now in turn: short slot words, the condition bar at its least, protection and weight as narrow as what they hold, then the name keeps its room and the columns that do not fit inside the card are left out from the right. By the code the name gets ~105u at 720 2x Large and ~98u on the Deck (Leather Gloves, Military Boots, JS-2000 Shotgun whole); protection and weight do not show at the half card (they did not before either). A name over ~98u (Deck) still cuts. QA re-check (c0e43ef): names whole at both settings; on the Deck the belt section's heading ran over itself and Detach sat over "JS-2000 Sho... / Back | ...". **fixed again (c88ee8d):** cause: the two heads were drawn at full width from either side, and a belt row's name stopped only at the COND column while the button starts left of it at the half card. The heads are now cut in their own shares; the row's text stops 8u before the button; the condition strip is left out when the button needs its room.
    - **32 (the reader):** it stays open when its card or Papers page closes; it closes only on B, Escape or its close box (as built, no change).
    - **35 (Skills, narrow):** the level bar shrinks to its minimum before the name is cut; the level number stays. **built (e56bc67), QA to confirm.** QA (Oct 31, Deck Large): names read "Ai...", "Rel..."; the bars looked full. **fixed again (85ad16b):** cause: the narrowing works (the shot's bars are 21 px, the least; full is 35 px; Axe's is 28 px); the two ~96u columns leave a name ~36u after the badge, spaces and margin. When even the bar at its least leaves the longest name short, the grid now closes up (badge to its number, 3u spaces, 2u margin): names get 40 of 83 px a column on the Deck (Aiming, Carving, Cooking whole; Reloading 48 px, Maintenance 61 px still cut) and 122 of 221 px at 720 2x Large (Carpentry 126, Maintenance 164 still cut). Whole names for every skill need ~71u a column: one column below a width would do it, a design question for the director. QA to re-check at both settings (the 720 run's Skills shot showed the Equip tab). **Director's pick (Oct 31): one column when narrow. built (e33e972):** when a two-column column (usual spacing, bar at its least) is narrower than the longest name needs (Maintenance; about 130u a column, a card under about 280u), the grid is one column with every name and full bar, and scrolls; the training materials keep two columns. Pad: Down / Up through the column, Left / Right do nothing on a skill row. QA to confirm at 720 2x Large and the Deck, and that a wide card keeps two columns.
    - **36 (ID card):** "make a vertical version of the ID": below a width the card switches to a portrait layout (photo on top, fields below). Build shows the director a screenshot before it ships. **built (4c58d89), QA to confirm and capture for the director:** the portrait card when the side-by-side card's field boxes are narrower than the widest label (content width under about 424 units, about 460 with Large text); ZeD.IdentityTab.qaLayout = "tall" / "wide" forces one.
    - **36 (Maps):** the stamps fold first; the inks stay so the ink in use always shows. **built (5d972bb), QA to confirm:** stamps close up, pinned stamps fold, then Aa (it then leads the full set under the fold arrow), the inks last from the end; the ink in use never folds while one ink fits.
37. **A player asks for Mod Folders support (the first Workshop comment, Oct 31 2026).** open. The comment asks
    for "[B42]模组文件夹" ([B42]Mod Folders by FieClaussell, Workshop 3779201168, about 78,000 subscribers): it adds
    folders to the game's own mod list (up to 99 named folders, collapse, drag to reorder, enable or disable a whole
    folder, multi-select and move), kept in Zomboid/Lua/ModFolders.cfg. ZeD's Mods screen replaces the game's, so
    that mod's folders never show while ZeD is on. Compat round 3 graded it "not needed" (ZeD's categories, search
    and profiles), but a player who already sorted hundreds of mods into folders loses that layout in ZeD.
    Options: (a) ZeD's Mods screen reads ModFolders.cfg and shows the player's folders as groups in the list, and
    folder changes made in ZeD are written back to the same file, so the layout is the same with or without ZeD;
    (b) keep it as it is and answer in the Compatibility thread with what ZeD's Mods screen offers; (c) a folder
    feature of ZeD's own, separate from that file. Credit the maker either way.
    **chosen (director, Oct 31: "Do both? Separators for organizing lists. and folders for organizing mods outside
    of lists." then "Yes, record it"): both, kept apart.**
    - Folders sort the collection: every installed mod, on or off. They read and write Zomboid/Lua/ModFolders.cfg,
      so a player's Mod Folders layout shows in ZeD and stays the same without ZeD. A folder never changes what is on
      or the load order; its on / off button turns its mods on or off, as Mod Folders' own does.
    - Separators sort the load order (MO2-style): headings inside the list of mods that are on, where a mod's place
      under a separator is its place in the order. Saved with each ZeD profile. Turning a separator off turns off
      every mod under it.
    - A mod's folder and its separator are independent; the screen must make clear which list you are in.
    - A new profile can start its separators from the folders with one button.
    - Build to write the plain rules and a mockup for the director before building; credit FieClaussell in the
      Compatibility thread.

    **Spec and mockup (build, Oct 31, 3f0b244):** ZeDUI/MOD_FOLDERS_SPEC.md (ModFolders.cfg's format from the
    mod's own code, section 9), ZeDUI/mockups/zed_mod_folders_v1.html + PNGs, credit draft
    ZeDUI/workshop/compat_modfolders_draft.txt (not posted; the Workshop page says FieClaussell, the mod's
    info says Paltia: check before posting). **Director's picks (Oct 31):** a folder's on/off acts at once (Accept
    is the commit); the collection is always grouped by folder once one exists; a newly turned-on mod goes to the
    end of the load order; "Start separators from folders" places only mods that are on. Still worth one short
    run with ZeD off to see how a non-English folder name is written (done: QA ran the mod's own save code in game,
    c8a237b, ZeDUI/ModFolders_sample.cfg; one hex code per UTF-16 unit, 地图 = "5730,56FE", Café = "43,61,66,E9",
    round trips hold; MOD_FOLDERS_SPEC.md section 9 updated). Next: build, after the director's OK.
    **Stage 2 folders built (9b07ada, ced521a, d4a2fc0), QA to confirm.** ZeD_ModFolders.lua keeps
    ModFolders.cfg as its lines: a line ZeD does not change is written back as read (an unchanged file
    round-trips byte for byte, unknown lines stay in place); every change reads the file again first.
    Calls the spec left open: lines ZeD adds go after the last line of their kind (new members by mod id),
    existing lines keep their place rather than the whole file being re-sorted (spec 9.5), so the round
    trip holds; Unfiled's open state is in Lua/ZeD_modfolders.txt; the controller reaches Move to folder
    through Move to folder... in the mod's pane (the main menu's pad has no menu button), X on a folder row
    is its box, A opens / closes; folder drag and Move up / down by drag are not built (stage 1 added no
    drag to the Mods list): Move up / Move down are in the folder's menu and pane; the Load order page's
    "which list" line shows only while folders exist; in a save's own list the folder box leaves on the
    mods the save may hold (their own row asks). QA: zedqa_mods_folders.lua (tag mfo), then by hand:
    right-click menus, Ctrl / Shift-click, Page Up / Down folder to folder, the pad on a folder row and
    the pane's Move to folder..., 1,500 mods with folders (frame rate), Large text and 1280x720.
    - QA, Nov 1 2026: zedqa_mods_folders.lua **36 passed, 0 failed** at 4K (1.75x) and on the Deck (1280x800,
      Auto, Large text) with compat_r4_mods.txt. (The first 4K run failed 9a: the test's outside line was a
      folder named QA and the test then made a second QA, refused as a duplicate; the test now makes "QA new".)
      ZeD off: ZeDUI/tools/qa/modfolders_crossread.lua runs ZeD_ModFolders.lua as shipped and then the mod's own
      loadConfig (copied unchanged) on what ZeD wrote, outside the game (Lua 5.1): **10 passed, 0 failed**
      (folders in order, open / closed, names with & , é, members, next id). Not covered: the mod's own screen
      drawing them.
      **Found (shot zqa_mfo_01_grouped.png, both sizes):** (a) the Chinese folder name 地图 draws "??" (ZeD's Fira
      fonts have no CJK; the first commenter writes Chinese, and Chinese mod names will do the same); (b) the
      count after a name with those letters is drawn over the name ("?? Café(2 | 0 on)", "??(0)"): the name's
      width is measured short; (c) the footer says "1 lines" (one line).
      - (a) and (b) fixed (e93b22b): Fira has no CJK and the engine draws a letter past a font's table as "?"
        and measures it 0 wide. ZeD's font lists now put the game's own Chinese and Japanese faces on two spare
        slots (Cred1, DebugConsole); ZeD.Text.scriptFont (shared/ZeD/Scale.lua) picks, once per string, the face
        that draws its letters, and every ZeD draw and measure of a role font goes through it, so the count lands
        after the name. Limits: the game's Chinese face is a traditional set and lacks some simplified letters
        (图 of 地图 among them: that letter draws blank); Korean and Thai have no free slot. Typed text in ZeD's
        boxes is not covered. Full coverage would need ZeD to ship an open-licence Chinese font (director's call).
      - (c) fixed (96d2beb): one / many keys for the help line and the folder and separator counts.
      Not done yet (needs the screen again): right-click menus, Ctrl / Shift-click, Page Up / Down, the pad on a
      folder row, frame rate with 1,500 mods, 1280x720.
    **Stage 3 separators built (0afb1ac, 8f70121, b828ebb), QA to confirm.** See item 41's note.
    **Simplified Chinese font, director Nov 1 2026: built, QA to confirm.** The director approved shipping Noto Sans
    SC Regular (Google / Adobe, SIL Open Font License 1.1; from github.com/notofonts/noto-cjk,
    Sans/SubsetOTF/SC/NotoSansSC-Regular.otf, 8,331,336 bytes; the OTF is not in the repo). Baked by
    ZeDUI/tools/fonts/bake_sdf_sc.py into the role faces' format (distance field, `type = sdf`) at a 32 px face,
    spread 1.5: 42/media/fonts/sdf/notoSC.fnt + notoSC1-5.png, 4,171 glyphs (ASCII, Latin-1, the 3,755 GB2312
    level-1 letters, GB2312 punctuation and full-width rows, CJK Symbols and Punctuation; no kana), 3.4 MB.
    The EN / PL / RU font lists put it on Cred1 in place of the game's traditional face; ZeD.Text.scriptFont's
    first Cred1 row (em 32, base 38, probe U+56FE) takes it, the game's face row stays as a fallback for a list
    that still names it. Japanese keeps the game's face (DebugConsole). Limit: one face draws a whole string, so
    a letter outside the set (rare or traditional) draws blank unless the Japanese face draws more of that
    string. Licence: 42/media/fonts/sdf/NotoSansSC_OFL.txt; credit in LICENSE section 6, README, the t14
    description's Fonts line. QA: zedqa_sc_font.lua (tag scf, in regression.txt): 地图 / 简体中文 / Café widths,
    the count after the name, kana on the Japanese face, shot zqa_scf_draw.png; and look again at
    zqa_mfo_01_grouped.png's folders (地图 whole, the count after it) at 1080p and 4K.
    - QA, Nov 1 2026: **confirmed.** scf 15 passed, 0 failed at 4K (1.75x) and at 1920x1080 (Auto) (reports
      qa/regression/2026-11-01_0738_fullscreen4k.md, _0739_windowed.md); the drawn sample reads 地图(2), 简体中文(2),
      Café(2) whole, each count right after its name (zqa_scf_draw.png, zqa_scf_draw_2160.png). The Mods page's
      folders at 1080p and 4K (mfo 36 / 0 each; zqa_mfo_01_grouped_1080.png, _2160.png): 地图 whole, "(2 | 0 on)"
      after it, Café and Weapons as before.
38. **Pad stops not refreshed while the drawer fills the window.** Found by QA, Oct 31 2026 (1280x720, UI scale
    2.0, Large text; zedqa_picks_recheck.lua and zedqa_bands_probe.lua, 2026-10-31_2040 / _2049): the World
    window's open recipe had no card, amount box or Craft stops; the Character window's Health, Thermal, Identity,
    Skills and every Journal page had 0 stops (Equip had 33). Cause: each window refreshed its controller stops in
    the inventory list's prerender, and at that size the tab drawer takes the whole window, the list is hidden
    (setVisible(invW > 0)) and its prerender never runs; the stops stayed as the tab-switch sync left them (Equip's
    zone tables were left over from earlier frames, the others were empty). **fixed:** the refresh is a function of
    its own (content._focusRefresh) that the list's prerender runs as before and the drawer's prerender runs while
    the list is hidden, every frame, whatever changed the drawer: World 13d56ca, Character f1ad35e. The probe's
    w_forage reading Maps' 14 stops was not this fault: its shot's title reads "Ground + Maps", so the Forage tab
    never opened (its strip button scrolled out of reach at 720, item 27; the probe clicks the button only). QA to
    re-run the probe at 720 2x Large, opening a tab by setting it when its button is out of reach.
39. **The UI scale stops at what fits the screen.** The director, Oct 31 2026: "NO ONE IS EVER GOING TO PLAY AT
    2X on 720p. It's way too big to fit more than 5 words." **chosen: cap the UI scale to what fits.** On small
    screens ZeD setup's UI scale slider stops at the largest step whose windows still fit; Auto stays the default.
    - Fits: at that step times the text size (Large 1.15), one window at its narrowest useful width (tab strip 36 +
      inventory minimum 200 + full card 480 + container strip 36 = 752 units) fits in half the screen's width, and
      the screen's height holds the title bar + a tab strip of 6 tabs + the help line. Never below the step under
      what Auto picks there, never below 0.5x. (The fixed steps take no engine font-size multiplier, so none is
      applied to them.)
    - The slider, the Mods page's drop-down and the controller's ZeD wheel offer steps up to the cap; the ones above
      are dimmed and inert, the help line saying "Too big for this screen: 1x and up." A saved step above the cap
      (picked on a bigger monitor) draws at the cap ("2x (0.75x here)") and stays saved, so the big monitor gets it
      back. Auto is never capped (it fits everywhere but 1280 wide with Large text, 9 px over: the half card takes
      that already). The QA override is not capped either.
    - Live: from the screen size and the text size every half second and on a resolution change.
    - Cap, Normal / Large text: 1280x720 0.75 / 0.75; 1280x800 0.75 / 0.75; 1920x1080 1.25 / 1; 2560x1440
      1.5 / 1.25; 3840x2160 2 / 2. The 720 2x QA manifests are now marked stress probes only.
    **built (9a3fd5c), QA to confirm.**
    - QA, Oct 31 2026 evening (ZeDUI/tools/qa/zedqa_scalecap.lua, scalecap_manifest.txt; windowed 1280x720,
      1280x800, 1920x1080, fullscreen 4K): **all passed.** The caps match the table at every size and text size. The
      ZeD setup slider and the wheel dim exactly the steps above the cap, and no dimmed wheel step can be picked. The
      help line reads "Too big for this screen: 1x and up." (1.5x at 1080p Normal, 1.25x with Large). A saved 2x stays
      saved: it draws 0.75 at 720 and the Deck, 1.25 at 1080p and 2 at 4K, and the row reads "2x (0.75x here)" /
      "2x (1.25x here)". The cap follows the text size at once (1080p 1.25 -> 1); the drawn scale had updated within
      30 frames. 4K offers every step. Put back afterwards each time. Shots: Zomboid/Screenshots/zqa_cap_<height>_setup_saved2x.png.
      Not covered: a resolution change while the game is running (each run starts at its size), and the Mods page's
      drop-down was only checked by the shared rule (Settings.scaleStepOff), not by a shot.
    - Open with the director: at 720 and the Deck the cap is 0.75 even with Normal text, so 1x can't be picked there.
40. **Immersive Searching support (a Workshop comment by Kable; director, Oct 31 2026: "immersive searching is pretty cool.
    not seen it before. would like to support that one too").** Workshop 3760450908, "Immersive Searching [B42MP]" by
    キツネユキ (yuckyfox), mod ids ImmersiveSearching and OpenAllContainersISCompat (an add-on for Open All Containers),
    ~3,400 subscribers, B42.18+, single and multiplayer. Its page asks that the mod not be altered without permission;
    support goes in ZeD's own code. Subscribed Oct 31 (ledger).
    - What it adds: a container's contents stay hidden until the character searches it, a timed action (rummage sound,
      loot animation, about 1-3 s; longer in the dark, faster with Dextrous, slower with All Thumbs; optional Foraging XP).
      Things appear one by one, heaviest first, from 20% of the way in. A search is remembered per container and per
      player (mod data). Unsearched container buttons get a dark icon with a "?". Its sandbox has a "Search all" key and
      controller button (off by default), a darkness penalty, a weight limit, and which containers to skip.
    - What it hooks: ISInventoryPane:refreshContainer (the list shows only revealed things); ISInventoryPage:selectContainer
      (picking a container starts the search) and :onJoypadDown (search all); the open/close sounds;
      ISInventoryPaneContextMenu.getContainers; shouldBeVisible on the loot window handlers (Take all, Transfer all,
      Move to floor, Remove all, mannequin); OnRefreshInventoryWindowContainers (the "?" icons); clicking a container in
      the world (OnObjectLeftMouseButtonDown) also starts a search. Java-side: InventoryContainer DoTooltip (a bag's
      tooltip shows it empty), ItemContainer hasRoomFor (nothing goes into an unsearched container) and
      getCapacityWeight (0 until searched).
    - QA, Oct 31 2026 (ZeDUI/tools/qa/zedqa_isearch.lua, isearch_manifest.txt; a duffel bag with 6 things put on the
      floor; ZeD on at 4K, report qa/regression/2026-10-31_2323_mods_fullscreen4k.md; ZeD off,
      qa/modload/2026-10-31_2327_is_console.txt). **No errors either way.** ZeD off: the mod works as described
      (0 things listed until the search, 6 after, the "?" icon on the bag's button until then).
      **ZeD on, the mod is bypassed:**
      1. Picking the bag in ZeD's World window starts no search (ZeD sets its own active container and never calls
         ISInventoryPage:selectContainer).
      2. ZeD's list shows all 6 things before and during the search (it reads the container's items itself, not
         through refreshContainer). Shot: zqa_is_zed_3_mid.png.
      3. The footer reads "6 items | 0.0 of 18 kg" while the things are listed (the mod's weight hiding still applies).
      4. No "?" mark: ZeD's container strip doesn't use the vanilla buttons.
      5. Still working with ZeD: a search started the vanilla way (or by clicking the container in the world) runs and
         marks the bag searched, and the "?" goes away on the vanilla buttons. Take all / Transfer all report visible
         after the search. Not checked: that they hide before it in ZeD's row, and that dropping into an unsearched
         container is refused in ZeD.
    - Hooks the build can use: ImmersiveSearching.isSearched(player, container); ImmersiveSearching.Items[container]
      .Searched[itemID] (what is revealed so far, while a search runs); the action ImmersiveSearching_ISSearch:new(player,
      playerNum, object, container, weight, capacity, dark) (its startSearch is local); ImmersiveSearching_isBusy while
      one runs; or press the hidden vanilla loot page's button for the container (selectContainer) so the mod starts its own.
    - For the director (design): how an unsearched container looks in ZeD's strip, what its list shows before and
      while it is searched, and whether "Search all" gets a place on the pad.
    **Director's picks (Nov 1 2026):** an unsearched container shows a small "?" badge on its own pixel icon in
    ZeD's strip (gone once searched); before a search the list reads "Not searched" with a Search button, and during
    one a progress bar runs in the band while items appear in the list as the mod reveals them (heaviest first);
    "Search all" (every container in reach) is a button in the container band, reachable by the pad. Support lives in
    ZeD's own code (the mod's page asks that it not be altered).
    **Built (1c8806e, e31ae4c), QA to confirm.** ModSupport/ImmersiveSearching.lua through a new general hook, ContainerGates.lua
    (a mod's rule on what a container lists, its band and what goes into it; a "container picked" hook). The "?" chip
    on unsearched buttons in both strips; the list shows exactly what the mod has revealed (its Items[container]
    .Searched), "Not searched." before, the weight line "Not searched" / "Searching..." / "Waiting to search"; the band
    leaves the moves out (Take all, Same type, To floor; Transfer all on your side), as the mod hides the game's, and
    shows the bar and Search (main); moves and drops into a container never searched are refused (its hasRoomFor rule).
    A container a ZeD list starts showing starts the search through the game's own page (selectContainer with its
    button, which the mod wraps); a window opening, or a list coming back from under a tab, does not. Search all is in
    the World band for any container on show while one in reach is unsearched, but only when the mod's sandbox
    "Search all" allows it (off by default: no button), corpses only when set so. QA zedqa_immersive_searching.lua
    (tag iss; in regression.txt it checks the mod-off case; with the mod: isearch_manifest.txt + isearch_mods.txt).
    - QA, Nov 1 2026, 4K: **confirmed.** Mod on: iss 28 passed, 0 failed (report qa/regression/2026-11-01_0723_mods_
      fullscreen4k.md; shots zqa_iss_on_*: the ? on the three bags, "Nothing found yet.", "Searching..." with the bar).
      The first run failed "Search all pressed: B and C searches queued": the mod's startSearch queues its
      ISWaitWhileGettingUp first and the search after it, and the later check (both searched) passed; the check now
      accepts either. Mod off (iss_off_manifest.txt): 9 passed, nothing registered, A lists six, picking queues nothing.
      No errors either way.
41. **Load order tools for big mod lists (a Workshop comment by Kable, ~1,500 mods; director, Oct 31 2026: "I want
    the mod manager to really shine, so let's try and accommodate their request").** chosen. Rules
    ZeDUI/MODS_LOAD_ORDER_SPEC.md, mockup ZeDUI/mockups/zed_mod_folders_v2.html (7ee6ef4), together with item 37's
    folders and separators as one Mods screen. Director's picks: Find in the load order shows only the matches, with
    their real place numbers and the gaps counted; "Load after..." is kept as a rule (survives Auto and profiles,
    shown on the row, removable); a pin or rule wins over a mod's own load-after wish with no yellow mark
    (requirements are never overridden); pins and rules are kept with the list being edited, profiles or not.
    Audit: Find is on the Mods page only and the pad can't reach it; moves are one place at a time; load-after
    only as a one-time Conflicts fix; ZeD picks is a hidden pin last; the order check runs over the whole list twice
    a frame (fix first for 1,500 mods); the profile writer drops lines it doesn't know.
    **Stage 1 built (d8277fe, 8961de3, 9e587b4), QA to confirm.** Speed: the order check, place numbers and rows
    are worked out once per change and kept; every list draws and makes controller stops only for the rows in sight
    (the Workshop tab also walked every mod for every item every frame: fixed). Find on the Load order page (place
    numbers, gaps, Show in the full list; a controller stop on both pages, Ctrl+F); Load first / Load last with
    carried mods, ZeD picks shown as kept last by ZeD; Load after... / Load before... picker (greyed choices with
    reasons), rules kept through Auto and profile loads, shown on the row, removable; Move to top / bottom, drag,
    keyboard moves, Undo. Pins and rules are kept with the list being edited ([@list ...] sections in
    ZeD_modprofiles.txt), go into a profile with New... / Update... and come back with a load; the profile writer
    keeps lines it does not know. QA: zedqa_mods_order.lua (tag mlo, compat_r4_mods.txt). Calls made where the spec
    was silent: Move up / Move down at a block's edge unpins a pinned mod (spec 2.8) and refuses an unpinned or
    carried one; Move to top / bottom work inside the block until sections exist; LB / RB and Page Up / Down move
    a page; a choice that needs a pin is greyed ("pin it first too") instead of offering Pin first and load
    before; New game's Choose mods keeps its own list ([@list new game]).
    - QA, Nov 1 2026: zedqa_mods_order.lua **24 passed, 0 failed** at 4K (1.75x) and on the Deck (1280x800, Auto,
      Large text). The first run skipped parts 2-5: the compat_r4 mods had been unsubscribed; QA subscribed the 8
      (ledger). Idle: 0 order checks, 0 list builds, 0 layouts over 60 frames.
      **Found (shot zqa_mlo_06_circle.png):** (a) the Load after... picker shows the word "nil" in every row's second
      column, at both sizes (over the end of long names at 4K: "Mod Display" + "nil"); (b) on the Deck with Large
      text the picker is too short: its explanation ("Puts ... just after Knox Packs ... Auto and profile loads keep
      it there.") is drawn over the list's last rows and over its own last line; (c) the picker's top edge leaves
      the list behind it showing through above its title.
      - (a) and (b) fixed (2c26b97): the picker's row stops lacked listRow, so the window drew each as a button
        with no text ("nil"), over the names and below the list over the explanation; the column now shows only
        the short reason on a greyed row (Needs it, Circle, Pinned), and the name is cut before it. (c) fixed
        (2c26b97): the list under the picker is covered edge to edge.
      Not done yet (needs the screen again): the pad and keyboard paths, drag, the right-click menu, the look
      against mockup v2, scrolling 1,500 mods.
    page (ZeD_MainMenuModsSeps.lua): box, collapse, New separator... / Rename... / Delete separator / Move
    up / Move down with its mods, mods cross a separator one step at a time, Move to separator... in the
    row's menu, a separator off turns its mods off (kept in place, dimmed, back on in place; Undo and Back
    put them back), Find shows separators holding a match, Move it up for a need under a later separator,
    Start separators from folders (asks before replacing); kept with the list and each profile as sep= /
    top= lines in ZeD_modprofiles.txt; the Profiles page lists them. Auto sorts inside each section only.
    Calls the spec left open: Start separators from folders is in the Load order band (while there are none)
    and in a separator's menu and pane as Replace separators with folders, not on the Profiles page (Update
    saves the result); Move it up puts the needed mod at the end of the section above (just above the mod
    when the section above is off or there is none); a rule made toward a mod in another section moves the
    mod into that section only when the rule has to move it; a separator is not dragged (Move up / Move
    down, Ctrl+Up / Down, Y / X); a mod new to the list goes under the last separator even when it is off
    (the box then shows the dash); deleting a separator that is off keeps its mods off, dimmed under the
    one above. QA: zedqa_mods_separators.lua (tag msp), then by hand: right-click and A on a separator,
    LB / RB and Ctrl+Page Up / Down separator to separator, a drag across a heading, Find with a
    collapsed separator, 1,500 mods with separators (frame rate), Large text and 1280x720.
    - QA, Nov 1 2026: zedqa_mods_separators.lua **38 passed, 1 failed** at 4K, on the Deck and at 1280x720 (Auto,
      Large text). **Fails 3d: a separator turned off and on again leaves The Only Cure+ (TheOnlyCurePlus) off and out
      of the list**; its requirement The Only Cure, just above it under the same separator, comes back on ("still
      off [TheOnlyCurePlus]; under it now TheOnlyCure;BB_KilometersPerHour;KnoxPacks;ZeD_UI"). The check now prints
      that detail line. Stages 1 and 2 at 1280x720 Large: 24 / 0 and 36 / 0 (as the Deck).
      **Seen at 1280x720 Large (zqa_mfo_04_ask_delete_720L.png):** the Mods page's last tab, Workshop, is cut off
      by the right pane, and the "Changes discarded" note is drawn over it.
      - 3d fixed (1ceb12b): not a requirement. The Only Cure+ declares The Only Cure incompatible; both were on, and
        turning the separator on one mod at a time put The Only Cure on first, so the game refused the other, which
        was then hidden (off under a separator that is on). Turning a separator on is now one batch; mods it turned
        off come back together even if they conflict; otherwise the first in the list wins and the other shows
        dimmed with the reason. A folder's box keeps one at a time (it names the refused mod in the band).
      - Tabs at 720 Large fixed (9e7b950): the tabs tighten to the list's width and, if still too wide, the row
        slides to show the open tab; the note is in the pane's own band and no longer meets the tabs.
      Not done: the checks by hand. The director declined QA control of the game window (Nov 1), so right-click,
      drag, Ctrl / Shift-click, Page Up / Down and the pad wait for the director or another way to drive them;
      frame rate at 1,500 mods also waits (the rig has ~280 mods). Hold script for a by-hand session:
      zedqa_mods_hold.lua (tag mho; opens the Mods page on a test folders file, ends when Lua/zedqa_release.txt
      has text).
    - QA, Nov 1 2026, after the fixes (2c26b97, 96d2beb, e93b22b, 1ceb12b, 9e7b950): **mlo 24 / 0, mfo 36 / 0, msp
      39 / 0 at 4K and on the Deck (Large); mfo 36 / 0 at 1280x720 Large.** Seen fixed: 地图 draws whole (图 too) with
      its count placed after it, at every size; the picker has no "nil", its explanation clear of the rows, nothing
      showing above its title (4K and Deck); the Mods tabs fit at 720 Large (Workshop 273 whole); msp 3d passes (The
      Only Cure+ back on with its separator). Mods-screen text looked normal with the font switch (menu bar, tabs, panes).
      Still open: the scripted hand checks with the handlers the build sent (right-click, keys, clicks, pad), and
      1,500 mods; drag needs the real mouse.

42. **t15 pre-upload fixes (the 4K regression of Nov 1 2026, 95 / 99, and the hand check mhd).** built, waiting for QA.
    - rtv FAIL (product): a mains set with no square (a house tile's CustomItem, a TV item on the floor or in a
      bag) reached DeviceData:canBePoweredHere, which asks its parent's square: a Java NPE every frame (logged
      under -debug even inside pcall). RadioOps.canBePoweredHere / poweredHere guard it (batteries and car parts
      keep vanilla's path); the TV, two-way and old radio displays, the power key and ToggleOnOff use them. The
      antique's "snow (standby)" was the test: its dial test left it on stop 1, so tuning to stop 1 was no change
      (no snow, rightly); the screens pass now starts off the first stop. 312317d
    - p336 WARN (test): no ZeD code on the generator path changed since t14; the staging spot moved (876,13018,
      t14 876,13003) and the generator two squares up could sit across a wall, so the walk to it never ended.
      The spot now needs both steps in reach; a start that never finishes prints the queue. da81d77
    - rst WARN (test): the QA character's load grows run over run (12.5 of 18 at t12, 32.3 at t15: books, CDs);
      all three fails began the run it went over the limit. The test sets aside what is loose and in the worn
      bags for the run. fe7d473
    - px WARN (test): the card step took the first item isEquipped did not count, a worn one, with the Character
      window closed. It now opens the window, uses its own loose screwdriver and checks the card shows it. d94dde2
    - Mods page pad (product): B on the leave question left the focus on nothing (back() named no button).
      setConfirm keeps the stop a question came from; the same on Sandbox, Options, Looks, Traits, Server, Host
      and Workshop. 7bca987
    - mhd (product): Undo after a separator went off lost The Only Cure+ (one mod at a time, the msp 3d cause by
      another path). One shared batch (modsOnBatch / applyOnSet) for the separator box, Undo and Back, the
      folder box, Discard and Undo changes, All on / No mods and loading a profile (exactly). 9133b08
    - rst, second look (product; the 09:17 re-run still had "the Fedora worn" and "casual: done"). Not the
      load: since the additions presets (t14) the regression runs with Put things back on, which noted
      Restock's queue as a run (the hat's move in, then the wear as its main action) and, once the hat was on,
      took it off and back to the crate; Casual kept that job and never finished. Restock queues as ZeD's own
      moves; Put things back leaves on what a run put on or hung on the belt; Casual ends with a reason instead
      of waiting ("Stopped: you carry all you can", "Stopped: the rest in reach could not be taken"). The
      capacity 8.0: god mode skips the game's own working out of it (BodyDamage.UpdateStrength), so a session
      in god mode from the load keeps the starting 8; the test works it out at the fixture (18) and checks a
      Casual run over a lowered limit ends "full". 4509a28
    - px, second look (test): the card opened and drew; the test looked for it at w._drawerPanel._itemCard
      (it is win._itemCard). Its row is selected as a click or A does, and the three mark chips checked on
      the card. b440d12
    - Main menu questions land on the answer that stays (the director's pick, Nov 1): leave-with-changes
      questions (Options, Server, Workshop, Mods, Sandbox's preset load) open on "Keep editing"; Host's Reset /
      Delete, the deletes, Replace profile, Upload and Server's delete page on Cancel. Discard and Save need a
      deliberate move. mmq expects the stay answer. 957474a
    - Traits (product, latent): the column clamp and inStrip() took any id starting with "c" ("confirm:yes",
      "clear") for a column stop; now "^c%d+:". c2f98a9
    - Main menu (product): answers that cleared the question with self.confirm = false left _backFocus stale
      (Sandbox load, Options apply / finish / monitor / restart, Server Save / Back, Workshop Save / Discard /
      Upload); all through setConfirm(false); Mods' profile page changes clear it. fa2b894
    - Workshop pad A dead (product): "__lt not defined" in focusRows' sort; the form's title and note fields
      (and the description editor's blocks and view tabs) were stops with no row. They have rows now, and
      focusRows sorts a missing row or column last instead of throwing. 3de956d
    - Re-run: rtv, p336, rst, px, mhd, msp, mfo, mlo; a pad pass on the main-menu pages' questions.
    - QA, Nov 1 2026 (where things stand, before the director's account switch):
      - Confirmed at 4K: rtv, p336 (2026-11-01_0917); rst, px on 4509a28 / b440d12 (2026-11-01_0950); mhd 78 / 0,
        msp 39 / 0, mfo 36 / 0, mlo 24 / 0. mmq (zedqa_menu_questions.lua, new) at 4K before 957474a: Options,
        Sandbox, Traits, Looks pass; Workshop failed on the pad-A error (since fixed, 3de956d); Server and Host's
        world question SKIP on this rig. **Not yet re-run on 957474a / c2f98a9 / fa2b894 / 3de956d:** rst, px, mmq
        (with its safe-answer expectations) and pad A on the Workshop form.
      - Small screens, full regression on code before 957474a (reports qa/regression/2026-11-01_t15pre_800N,
        _800L; 720N stopped at script 67 of 99 for the account switch, 720L not run): Deck Normal 94 / 99, 5 WARN;
        Deck Large 90 / 100, 10 WARN; no FAIL. Found:
        a. **Deck, Large text: the drawer is 190 px where the full card needs 200.** The ham radios ("the drawer
           holds the whole set (190 px for 200)"), the handbuilt radio and the house TV (half card, "190 px, want
           414"), the microwave and stove ("the tab is the full card" fails; the chrome microwave's full face 200 of
           178 px), and every World tab tww expects as the full card (vehicle, maps, furniture, forage, craft, build,
           animals, Maps pop-out: half). A realistic setting: a layout call for the director (what the full-card
           surfaces do when the full card doesn't fit), then the tests' expectations.
        b. Deck Large: dollv4 pad fails ("A opens the small slot's card (outermost first) | nil item nil layer",
           "Inner steps to layer 2", "Left from Neck steps into the left band"); mnote: "no toolbar button star"
           (the Maps header folds its stamps first: is the star meant to fold away, and where does it go?).
        c. Both Deck runs: wpt "7 Char skills large pad: Down reaches the lowest control ... training:col1_Fishing and
           it is in view" (bottom 250 of 273 Normal, 297 of 320 Large): the last Skills row's stop sits partly
           below the view.
        d. Both Deck runs: wi, every wheel's icons drawn at 12 px (Normal) / 14 px (Large) from 16 px drawings, so
           not pixel for pixel. The pixel icons at Auto 0.75 scale: a design call (a 12 px set, or 16 px with a
           smaller wheel) or the test's expectation.
        e. Deck Normal: tww / cu, the World window comes back 4 to 12 px off where it was after a tab or card
           closes (644 -> 640, 656 vs 644); dke "race / primani key reads start with the key in, engine off; want
           off" (also 800L).
      - Next QA: re-run rst, px, mmq and Workshop pad A on main; the Deck / 720 Normal and Large passes again
        after a.–e.; then stage t15 (drafts ready: tester_changenote_0.2.0-t15.txt; tester_description_0.2.0-t15
        .bbcode at 7,890 + 58).

      - **Build, Nov 1 2026 (causes and the ways to fix a.-e., the director to pick):**
        a. **Cause.** The window is capped at half the screen (640 px on the Deck). A tab gets the full card only
           when the full card, the inventory's 200-unit minimum and the two strips fit inside that cap; otherwise
           the half card, never a width between. With Large text every unit is 0.8625 px on the Deck: full card 414,
           strips 31 + 31, inventory minimum 173 = 649 px, 9 px (about 10 units) over the cap. Normal text (0.75 px
           a unit) needs 585 and fits. So every full-card tab drops to the half card (190 px), and everything built
           for the full card goes with it: the doll's narrow layout without the bands (b., most of the dollv4
           fails), the radios' and machines' narrow faces, the Maps header folding its stamps (b., the star).
           Ways to fix: (1) the inventory gives way first: beside a full card it may go down to 180 units when
           the half screen leaves it no more (it scrolls anyway); below that, the half card as today. The Deck with
           Large text gets the full card everywhere with a 190-unit inventory (164 px); both windows stay side by
           side at half the screen each; the rule is one sentence for the tests. (2) the window may grow past half
           the screen by what the full card needs (649 of 1280 px): with a full card open in both, they overlap by
           18 px. (3) leave it: the Deck with Large text is a half-card experience, the tests learn that. A fourth
           way, a narrower full card, is a third width and is not offered. Build's pick: (1).
        b. The doll (dollv4) and the Maps star (mnote) follow a.: with the full card back the bands show and the
           header has room for all six stamps. The star is not lost when the header is narrow: stamps that fold
           away sit under the fold arrow in the full set (the Oct 31 rule), so the test should click through the
           arrow when the button is not on the strip. The doll's "short" check (a 380 px tall window) is re-run
           after a. before any change.
        c. **Skills, Down stops short (both Deck runs).** Every training row registers its pad stop whether or not
           it is in view (the Oct 29 drawing pass left the stops in), and the pad's move takes every stop in the
           column, so the cause is not a missing stop. The walk stops at the Fishing row while a row below it is
           partly under the view's bottom edge; why Down does not land on it needs the game: a one-minute probe
           on the Deck window printing the Skills column's stops and what Down picks from Fishing. Build writes
           the probe; QA runs it when the director says. Not a design call.
        d. **Wheel icons under 16 px.** The wheel's icon box is 16 units: 12 px on the Deck at Normal text, 14 at
           Large. The icons exist at 16, 24, 32 and 48 px; under 16 the 16 is drawn smaller with nearest
           filtering (the library rule since Oct 27). Ways: (1) Design draws a 12 px set (376 icons; and a 14 px
           set for Large text, or Large uses the 12 too); (2) the wheel never draws under 16: at small scales the
           cell holds the 16 px icon (the cell at rest is 16.5 px on the Deck, so the icon fills it edge to edge;
           pointed, 25 px, the 24 fits); (3) keep the scaled 16 and tell the test so (the enlarged shots from the
           720 run are with the director to judge). Build's pick: (3) for t15, (1) later if the look is not good
           enough on a Deck in the hand.
        e. **World window 4 to 12 px off after a close (cause found).** Opening a full-card tab widens the window
           to the cap; on the Deck the World window sits 4 px right of centre, so the engine pushes it 4 px left to
           keep it on screen. The drawer code remembers that push and gives it back while the drawer animates
           shut. Closing by going to Loot snaps the width in one step and never runs that path, so the push is
           kept (640, not 644) and the remembered amount stays owed: the next animated close pays it out (the
           item card check saw 640 -> 644), and roll / unroll cycles add to it (656). Fix: every snap to Loot
           settles the owed push the same way the animated close does (both windows; the Character window has no
           such counter today because its anchor is its right edge). No design call.
           dke (race, primani: the key read START with the key in): the dash shows START for 0.6 s after an
           ignition press and the test waits 1.2 s, so a START after that means the press cranked the engine (the
           key was already in when the test clicked). A fixture state, not the Deck; QA re-runs the two cars alone
           (ZeD_QA_DKE_ONLY) before anything is changed.
        f. 720 Normal leftovers (stopped at script 67): rst failed at the start ("no grandstand building near
           892,13040", the fixture incomplete): the character was not at the QA home, a prelude question for QA.
           jrd "Too dark to write": the time of day. cu "Loot Character side down with the press" (720 only):
           not looked at yet; it goes with the e. fix's re-run.

      - **Build, Nov 1 2026, the director's picks ("Yes, go") built:**
        a. **fixed (build, Nov 1).** Beside a full card the inventory gives way first, from 200 units down to 180
           (`INV_MIN_BESIDE_CARD` in both windows; the UI scale cap's fit rule, `ZeD.Scale.FIT_W_UNITS`, uses the
           same 180). Alone, the inventory keeps 200. The Deck with Large text now fits the full card by 1 px of
           margin (414 + 31 + 31 + 155 = 631 of 640). QA to confirm: tww, tw, rtv, ap, p336 and dollv4 on the
           Deck at Large text; and that 4K, 1080p and the Deck at Normal text draw exactly what they did (the
           rule only moves the line where a tab drops to the half card).
        b. **follows a.**; QA re-runs dollv4 (the bands, the 49 slots, the "short" check) and mnote on the Deck
           at Large text. zedqa_mapnotes.lua now reaches a stamp folded off a narrow header through the fold
           arrow (the star's step is its own tick, at(80)) and shuts the fold after.
        c. **probe written:** `ZeDUI/tools/qa/zedqa_probe_skills_down.lua` (tag pskd, about a minute, no game
           change). Manifest line: `zedqa_probe_skills_down.lua | pskd | timeout=120`, on the Deck window (1280x800)
           after the prelude; it walks Down through the Skills training rows at the run's text size and at Large,
           prints each landing with the view and scroll, then every training stop below the last one with the
           pad's own cost verdict and the focus manager's dry run of a Down. QA runs it when the director says;
           build reads the print and fixes from it.
        d. **test (build, Nov 1):** zedqa_wheel_icons.lua accepts the 16 px drawing scaled down for a box under
           16 (the Deck's 12 and 14), the library rule since Oct 27. Design may draw a 12 px set later if the
           director does not like the look on a Deck in the hand (the enlarged shots were sent Nov 1).
        e. **fixed (build, Nov 1).** Every snap to Loot in the World window settles the cap push the animated
           close used to give back (`settleCapPush`): the window goes back right by what the engine pushed it,
           and the counters start clean. QA to confirm: tww and cu on the Deck at Normal text (644 stays 644; the
           rolled close lands where it started), and the 4K pair unchanged. dke: QA re-runs race and primani alone
           (ZeD_QA_DKE_ONLY) before anything is changed.
        f. for QA: rst at 720 needs the character at the QA home first; jrd needs daylight; the cu "Loot side
           down" at 720 goes with e.'s re-run.

      - **QA, Nov 1 2026, 1:10 pm (the two Deck re-checks on 645d716 / 0884a2b; reports
        qa/regression/2026-11-01_deck_recheck_800L.md, 11 / 12, and _800N.md, 3 / 7 with 2 warn, 1 timeout, 1 not run):**
        a. **confirmed.** Deck at Large text: every full-card tab is the full card (tww: 414 px on all 13 tab cases,
           the object cards, Craft at an oven and without, the ham set, Maps and its pop-out; the item cards and the
           walkie stay the half card, 190, as designed). tw 21 shots, rtv 31, ap 5, p336 10 pass. Deck at Normal text
           draws what it did (tww: full card 360 px on the same cases, none moved to the half card).
        b. **confirmed.** dollv4 passes at Large (the wide, D-pad, pads, card, narrow and short checks; shot
           zqa_dollv4_1280x800_wide shows the left bands and the slots). mnote passes at Large, the star reached through
           the fold arrow.
        c. wpt passes at both sizes (the Skills Down check included). **Probe print:** the whole "ZEDQA pskd" block is
           the last script in 2026-11-01_deck_recheck_800L.md (section 12). In short: both passes ran at Large (the
           manifest set Large before it, so pass 1 is not a Normal pass; a Normal print needs the probe in the Normal
           manifest). Down walks all 11 col1 rows to Foraging, the last (y 298.9, h 22, view 320: 0.9 px under the
           edge); "training stops below the last one: 0"; the dry run of Down from it is nil. Pass 1 (scrolling as it
           went, 0.617 -> 0.987): **Down 12, 13, 14 from Foraging landed on nil, the focus lost.** Pass 2 (already at
           the bottom): Down 12, 13 stay on Foraging. So on the Deck the last row is reached; the open fault is a Down
           past it that drops the focus when the view was still scrolling, not when it was already at the bottom.
        d. **confirmed (test).** wi passes at both sizes, 31 shots each.
        e. **confirmed, World side.** tww at Normal: the World window is back at 644 after every tab and card (the
           t15pre run had 640 after craft and the oven, 644 after the item card); cu: "tab closed while rolled World
           644,0" (was 656). **New, the Character side, both text sizes:** the first full-card open pushes the
           Character window 4 px right and it keeps it: tww "Character equip: closed, the window is back where and as
           wide as it was (303,0 -> 307,0 at Normal; 253,0 -> 257,0 at Large)", then the end-of-run check. The pair
           starts with the Character's right edge at 636 (the 8 px gap centred on 640); the full card wants 640 wide
           anchored on that edge, so x would be -4 and the engine pushes it to 0; closed, it lands at 307 / 257. Latent
           before today: the t15pre 800N run started tww with the Character already at 307 (an earlier test had pushed
           it), and at Large the full card never opened. Same cause as e., the side Build said has no counter. Ways:
           (1) settle the push on the Character window as the World one does now (a mirrored counter on the right-edge
           anchor); (2) start the pair with the Character's right edge at 640 (no gap on that side, nothing to push);
           (3) leave it, 4 px once per session, not visible in play; the test learns it. Build's call.
           **dke not run:** zedqa_dke_only_race_primani.lua prints its DONE in the same tick the bridge starts it, before
           the "run #6" line, and the runner ignores a DONE that comes before that line (the Oct 23 rule); 30 s TIMEOUT,
           dke skipped. Build: delay the DONE a tick (the deep run does this), then QA re-runs dko + dke alone (the two
           cars, a few minutes, needs the screen).
        f. cu at 800 Normal: **"Loot World side down with the press: rolled false tab loot rods in UI 1"** (one
           curtain rod still in the UI after the press; the roll itself ended and Loot is the tab). The t15pre 800N run
           passed this line on both sides and 720N failed it on the Character side, so it moves between sides and
           runs: a timing suspect (the rod's removal a tick behind the press) before a layout one. Build to look.
           Not run this time: rst at 720, jrd (not in these manifests).
        Next QA (needs the screen): dko + dke alone at 800 Normal after the DONE fix; the 4K pair (tww, cu, about
        5 min fullscreen) to confirm a. and e. changed nothing at 4K; 720 Normal and Large passes when Build says.

      - **Build, Nov 1 2026, afternoon (the second round, on QA's 1:10 pm note):**
        e. **Character side fixed (build, Nov 1; way 1).** The Character window's drawer grows leftwards from its
           anchored right edge; where that would put the window past the screen's left edge the engine pins it at 0,
           and the code read that pin as a drag and moved the anchor 4 px. The pin is now remembered as a push
           (`_drawerCapPush`, the mirror of the World window's counter): the anchor stays, the at-rest anchor is the
           right edge less the push, and a closed drawer owes nothing. QA to confirm: tww at Normal (303 stays 303)
           and at Large (253 stays 253); the end-of-run check.
           **dko fixed:** zedqa_dke_only_race_primani.lua prints its DONE three ticks in (the runner's "run #" rule).
        f. **fixed (build, Nov 1).** Cause (engine, PZAPI Q273): `UIManager.AddUI` and `RemoveElement` are queued and
           applied a frame late, and an add cancels a queued remove of the same element while adding it again, so a
           roll right after an unroll put the curtain rod in the UI list twice and the next unroll took one copy away
           (the sides and runs it showed on depend on whether a roll landed inside that frame). The rod now joins the UI
           manager once (`rod._inUI`) and only hides between rolls; it leaves with its window (C.drop).
           zedqa_curtain.lua counts the rods showing, not the rods in the list. QA to confirm: cu at 800 Normal and
           Large, and at 720.
        c. **probe improved (build, Nov 1):** zedqa_probe_skills_down.lua's pass 1 is Normal text whatever the manifest
           set before it (pass 2 Large), and a Down that lands on "nil" now names the window, the zone and the stop
           the focus went to. The 1:10 print showed the focus leaving the Skills content on Down 12 to 14 from the
           last row in pass 1 only; with the zone named the next print says where it went. Then the fix.
        Manifests: `deck_followup_normal_manifest.txt` (prelude, tww, cu, dko, dke, pskd; -Width 1280 -Height 800)
        and `deck_followup_large_manifest.txt` (prelude, Large, tww, cu). The 4K pair (tww, cu) and the 720 passes as
        QA planned.

      - **QA, Nov 1 2026, 2:00 pm (round two on d118520; reports qa/regression/2026-11-01_deck_followup_800N.md 6 / 6,
        _800L.md 4 / 4, 2026-11-01_pair4k_after_deck.md 3 / 3):**
        e. **confirmed, Character side, both text sizes.** tww: the pair ends where it started (303,0 / 644,0 at
           Normal; 253,0 / 644,0 at Large); cu "tab closed while rolled World 644,0" at both. **dke confirmed:** dko
           passes (1 s), race and primani read off, start, then on with the engine running (6 shots).
        f. **confirmed.** cu: "Loot World side down with the press" and the Character side both "rods in UI 0" at
           Normal and at Large.
        c. **Probe print (Normal pass) in deck_followup_800N.md, section 6:** at Normal text (view 278, row h 20)
           Down walks all 11 col1 rows to Foraging (y 258.98, 0.98 px under the edge); the next Down leaves the
           Skills content: "nil: focus in Char zone charMainInv on invrow:11 (x 0 y 227 w 150 h 23)", then invrow:12,
           13 on the Downs after. At Large (pass 2, view 273, drawer 414) Down past Foraging stays on Foraging. So the
           fault is the Down past the last row at Normal text crossing into the main inventory list, not a row out of
           reach.
        4K unchanged: tww's 47 case lines (every width and both windows' positions) are identical to the last 4K run
        with it (2026-10-31_t14c); cu passes (222 ok). Pskd print at Large unchanged from 1:10 pm.
        Left for QA: the 720 passes at Normal and Large (about an hour each, on request); the Skills fix's re-check
        when Build has it (pskd + wpt on the Deck at Normal).

      - **Build, Nov 1 2026, 2:10 pm (c., the Skills row: cause found, a rule for the director):**
        c. **Cause.** The probe at Normal text: Down walks every training row to the last one, Foraging; the next
           Down leaves the Skills content and lands on the eleventh row of the main inventory list, to the right of
           the drawer. The pad's move looks first in the zone it is in, then in the rest of the window, and in the
           rest of the window it takes a stop that is lower on the screen even when it is off to the side (the
           "half" tier the cone rule allows inside a zone, so that a direction is never blocked). At Normal text an
           inventory row sits a little lower than the last Skills row, so Down goes sideways into the list; at
           Large text none does, and Down stays. The t15pre walk met the same jump one row earlier (Fishing), which
           is why that run read as "a row out of reach". A pad-rules matter (GAMEPAD_SPEC), not a layout one.
           **The rule proposed:** Up and Down leave a zone only for a stop directly above or below (one that lines
           up across), never for one off to the side; inside a zone nothing changes; Left and Right do not change.
           At the end of a column Down does nothing (the director's "directions match the screen"). Edge cases:
           Up from the first inventory row still reaches the container row above it (lined up); Down from the last
           tab in a tab strip stays there (Right takes it into the content, as today); the pad map tool
           (padmap.py) gets the same rule, so the next pad map may list a few expected moves to re-read. Waits
           for the director's yes.

      - **Build, Nov 1 2026, 2:20 pm: c. fixed (the director's yes to the rule).** Up and Down, when they look
        beyond their own zone (the rest of the panel, then the rest of the window), take only a stop lined up
        directly above or below; the "half" tier (off to the side) stays inside a zone and for Left and Right.
        FocusManager's live move and its preview path, the pad map tool (padmap.py) and GAMEPAD_SPEC's D-pad row
        carry the rule. QA to confirm on the Deck at Normal text: pskd (Down past Foraging stays on Foraging,
        no landing in the inventory) and wpt; the pad map at its next run (a few expected moves may read
        differently: a Down that used to leave a column sideways now stays).

      - **QA, Nov 1 2026, 3:25 pm (before staging; reports qa/regression/2026-11-01_deck_skills_compass_800N.md and
        2026-11-01_t15_720_short.md):**
        c. **confirmed (f5e10d0).** Deck at Normal: Down past Foraging stays on Foraging at both text sizes; nothing lands
           in the inventory list. wpt passed its Skills check. (wpt's one warning there, "Right from a row lands on the bag
           on show" with the focus on charTabContent training:col1_Foraging, came right after the probe and looks like the
           probe leaving the Skills tab open: test order.)
        43 **confirmed (0bb6f48):** zedqa_probe_compass.lua (tag cmp): 8 of 8 headings right (E, N, W, S, NE, NW, SW, SE).
        720 short (Build's deck_720_short_manifest, Normal): tww, cu, dollv4 PASS; the pair ends where it started and the
        rolled close lands at 644. **wpt at 720 FAIL (product suspect, new today):** "Right from the Character window's
        right edge: Char charTabContent:health:start" with the window on Loot, so the D-pad never crossed to the World
        window and the 22 checks after it failed with it. This morning's 720N run (older code) and today's 800N run
        (f5e10d0) pass that line. Suspect: "every tab keeps its stops while the tab drawer fills the window": at 720 a closed
        tab's stops (Health's Start) stay live in charTabContent while Loot shows. Build to look; staging waits on it and
        on the About line in UI.json (changed on disk at 3:11 pm, not Build's; the director to say).

      - **QA, Nov 1 2026, 3:50 pm: t15 staged.** 45 **confirmed (e78ddcd):** wpt after cu at 720 Normal passes (the D-pad
        crosses to the World window; 2026-11-01_t15_720_wpt.md). One new line in that run's cu, first cycle only: "cycle1
        World saved: got 853.333,0 want 858.667,0" (5.3 px, 720, cu straight after the prelude; the two earlier 720 runs
        today had cu after tww and passed it). Build to judge; not held for. **Staged from d66f07e:** 4,267 files, 46.45 MB,
        modversion 0.2.0-t15; description 7,889 (+ the game's 58) into workshop.txt, the 37-line change note into
        Lua/ZeD_workshop.txt; zedqa.lock busy until Contents is removed after the upload (the staged copy shadows the dev mod).
        **Uploaded 3:55 pm** (the director; the window consumed the change note). Build tags v0.2.0-t15 on d66f07e, refreshes the D: backup and removes Contents.
        Not run before t15: the full 720 Normal and Large passes (the director: "Short 720, then stage"); they run after
        the upload.

      - **QA, Nov 1 2026, evening: the full 720 passes after the upload** (qa/regression/2026-11-01_t15_720N.md 86 / 99,
        2026-11-01_t15_720L.md 86 / 100). The same thirteen scripts miss at both text sizes; nothing else:
        - **Every vehicle script, one cause (eleven scripts):** cars never settle at 1280x720. sl, rb, sm, tm, t3 FAIL on
          vanilla's onEnterVehicle ("attempted index: isDriver of non-table: null", the vehicle nil at the enter); dash19
          and dpx "car not ready in 90 ticks (not entered)" on every car; dnt "spawn failed ... no ready car" for all seven;
          dgr, dke, dbr "car not settled at the seat step ... square true, chunk true, 7.0 away, physics false" for every
          car. All of them PASS at 4K (t14c) and dke passed at 1280x800 this afternoon. **Build's reading:** the scripts
          wait in ticks for things that happen in wall time (a spawned car's physics, the chunks after the prelude's
          move); a 720 window runs many more ticks a second than 4K, so the waits run out first. A rig fault, not the mod.
          **Probe written** (zedqa_probe_car_ticks.lua, tag pct: one car, wall ms at ticks 30-300 next to its physics)
          to run at 720, 800 and 4K; if 90 ticks is a fraction of a second at 720 and seconds at 4K, the vehicle scripts
          and the prelude move to wall-clock waits (as dke's steps already do).
        - rst FAIL ("no grandstand building near 892,13040; the fixture is incomplete", then ready 0 of 0, ghosts, 14
          Java exceptions): the same cause suspect (the building not streamed in when the fixture looks).
        - jrd WARN "Too dark to write": the time of day. Large only: card_pad "ran twice (re-bump)", the runner.
        Passed at 720 at both sizes: everything else, including tww, cu, wpt, dollv4, the pad suites, the radios, TVs,
        laundry, the plates, the menus and the soak. Main-menu checks (ZeDUI/qa/Nov1_main_menu/): the About menu ends
        inside the glass at 720 and 800; the v4 desk at 1080p lit and dimmed matches Design's preview.

      - **QA, Nov 1 2026, late: the 720 vehicle cluster, two probes.** (1) zedqa_probe_car_ticks.lua at 720, 800 and 4K
        (qa/regression/2026-11-01_car_ticks_*.md): a tick is 8.5-9.3 ms at 720, 8.5-9.1 at 800, 9.4-10.4 at 4K; a car
        spawned beside the character has its physics awake at tick 1 at every size and asleep by tick 180. **The
        tick-against-wall-time reading is out.** (2) Bisect at 720 (2026-11-01_bisect_a_720.md, _b_720.md): prelude + sl
        alone PASS; prelude + rst + sl PASS, and rst itself passed this time with its fixture found. **So neither the 720
        window alone nor rst's failure makes the cluster; it takes more of the full pass's state** (something in scripts
        42-80, or what eighty scripts leave behind: cars not removed, chunk churn) at 720 and not at 4K. Known from
        Build (PZAPI Q274): the loaded chunk grid is 13 across at 720, 15 at 800, 19 at 1080p and 4K, and the vehicle
        simulation follows it. Note: in both passing sl runs the police car entered with physics=false at 8.3-8.5 tiles
        and the lightbar still opened, so "physics false" alone is not the fault; the full pass's "isDriver of
        non-table: null" (the vehicle nil at the enter) is. Next, for the rig, not t15: a longer bisect (prelude + 42-80 +
        sl at 720, about 35 min) or Build's prints (character x,y at the fixture step, chunkGridWidth, each spawned
        car's distance and chunk) in the vehicle scripts, then the rst fixture guarded so a missing building ends the
        script cleanly. The game is closed and the lock free.

43. **Foraging finds: the compass letter is wrong (QA, Nov 1 2026, found while staging the gallery retake).** open.
    `ForagingTab.lua`: `angleToBearing` takes a maths angle (0 = east, 90 = north) and reads the COMPASS table from
    N at index 1, so a find due east is labelled N, north-east NE, due north E, and the ring runs the wrong way round
    (N, NE, E, SE... as the angle turns anticlockwise). Seen by reading the code (lines 126-131 and 1302-1304), not yet
    in a capture. A find's "12 tiles NE" in the list would send the player the wrong way. Ways: (1) map the maths angle
    to the compass index (north = 0 at the top, clockwise: index = floor(((90 - deg) mod 360 + 22.5) / 45) + 1); (2)
    drop the letter and keep the distance. Build's call; a QA check can stage a find at a known square after.
    **fixed (build, Nov 1 2026, the director: "fix the letter").** The angle is turned into a heading (north 0, east
    90, clockwise) before the table is read; the eight headings checked by hand (east E, north N, north-east NE,
    south S), the modulo kept positive for Kahlua. QA to confirm: a find staged at a known square (east of the
    character reads E, north reads N).

44. **Controller multi-select in the inventory (the director, Nov 1 2026; for build 16).** open, an idea in his
    words: "I'm thinking about multi-select for inventory with a gamepad. X opens the context menu. What if we hold
    down X and that selects an item, and then you can hold down X on the next item. So holding down the X is what
    allows you to select multiple items. Because if I remember right, holding down A uses the item. But if A selects
    the item, then holding down A should be multi-select. And if X opens the context menu, then holding X should
    use the item. That makes more sense to me." Today (GAMEPAD_SPEC): tap A opens the row's card (focus on Take),
    hold A does what a double-click does (quick use), tap X opens the context menu, hold X is drag mode (the D-pad
    moves the held thing; the container strip uses it). Questions for the design pass: what tap A means on a row
    once "select" exists (open the card, or select with the card on another press); what hold X's drag mode moves
    to; how a multi-selection shows (the list's selection wash) and what acts on it (the context menu, Take, drop);
    how it clears (B, or a tap elsewhere). Not for t15.

45. **Reset windows leaves the old tab's pad stops behind (QA, Nov 1 2026, the 720 short run; build's cause).**
    open. wpt at 1280x720 Normal, right after cu: with the Character window on Loot, Right from the container
    strip landed on a Health tab stop ("health:start", the exercise Start button) instead of crossing to the World
    window, and the 22 lines after it fell with it. Cause (build): the runner resets both windows before each
    script (Reset windows, the same as the Select wheel's and the window menu's), and the reset sets the tab to
    Loot and the drawer shut without rebuilding the controller's stops; the stops of the tab that was showing
    (Health, where cu ended) stay registered in the content zone until the next tab change. Latent since the
    reset exists; this morning's 720 run passed because another script ran between cu and wpt and left Loot
    showing; 800 passed today because the script before wpt ended on Loot. A player with a pad meets it after
    Reset windows from a tab other than Loot: a Right from the strip lands on a stop that is not drawn. Fix: the
    reset rebuilds each window's stops for Loot (both windows expose their ring sync; ZeD_Window.resetLayout
    calls it after the geometry). A few lines, no design call. Build asks the director whether it goes in t15.
    **fixed (build, Nov 1 2026, the director: "Yes, both"; e78ddcd).** ZeD_CharacterWindow.syncRing and
    ZeD_WorldWindow.syncRing rebuild the stops for the tab on show; ZeD_Window.resetLayout calls both after placing
    the windows. QA to confirm: wpt after cu at 720 Normal (Right from the strip crosses to the World window, lit).

46. **The saved window place keeps the engine's push (QA, Nov 1 2026, the 720 wpt run's cu, first cycle only).** open,
    not a t15 blocker. cu straight after the prelude: "cycle1 World saved: got 853.333 want 858.667" (5.3 px at 720;
    the two 720 runs with cu after tww passed it). Cause (build): the World window's layout is also saved about once a
    second while it is open (saveWorldStateThrottled), and while a full-card tab holds the window against the
    screen's edge the saved x is the pushed one (640 px), not the window's own place (644). The window itself comes
    back right (items 42 e. and 45), but a Save and Quit with such a tab open reopens the window 4 px left of
    where it was. Fix: saveWorldState (and saveCharState) write the unpushed x, as they already write the unrolled
    x for a rolled side: x + the cap push for the World window, the anchor's x for the Character window. A line
    each; QA re-reads cu's saved lines after. For t16 unless the director says otherwise.

      - **0.2.0-t15 uploaded Nov 1 2026, 3:55 pm (the director: "Uploaded").** Tag v0.2.0-t15 at d66f07e pushed;
        backup D:\ZeD-UI backup\2026-11-01-t15 (zed_backups, workshop.txt + preview.png, the QA save); Contents
        removed; zedqa.lock free. Next: the full 720 Normal and Large passes (QA, when the director gives the screen),
        the Discord note (ask first), items 44 and 46 for build 16.

47. **The test rig at 1280x720: every vehicle script fails in the full pass, and passes alone (QA, Nov 1 2026).** open,
    rig only, not the mod. In both full 720 passes (Normal 86 / 99, Large 86 / 100) the thirteen same scripts fell:
    every vehicle script (sl, rb, sm, tm, t3 with vanilla's "onEnterVehicle: isDriver of non-table: null", the
    vehicle nil at the enter; dash19, dpx, dnt, dgr, dke, dbr with cars never settling) and rst (its fixture not
    found). Ruled out: frame timing (a tick is 8.5 to 10 ms at every size; a fresh car's physics is awake on tick 1
    at 720, probe pct); 720 alone and rst's failure (bisects a and b at 720: prelude + sl pass, prelude + rst + sl
    pass with the fixture found). Known (PZAPI Q274): the loaded chunk grid is sized from the screen, 13 chunks
    across at 720 against 19 at 1080p and 4K, and the vehicle simulation follows it. What is left: the state eighty
    scripts leave behind at a 13-chunk grid (cars not removed, chunk churn) puts spawned cars outside what the game
    simulates by script 81. Next (a screen slot, about 35 min): prelude + scripts 42-80 + sl at 720, with two prints
    in the vehicle scripts (the character's x,y and IsoChunkMap.chunkGridWidth at the spawn; each car's distance and
    whether its square has a chunk), and rst's fixture guarded so a missing building ends the script cleanly instead
    of 14 exceptions. Build writes the prints and the guard before the next slot.

48. **The main menu on a Steam Deck and at 720p: readable type, the desk leans in (t16; the director, Nov 1 2026).**
    built (build, Nov 1), QA to confirm. The Oct 29 overflow was the saved 1.75 scale, now held at 0.75 by item 39, so
    the 1080p menu fits the room's monitor at Auto; what was left was the type, 5 to 8 px at 0.75, under Valve's 9 px
    floor. The director's pick ("2" of three): the menu at 1.0 with Design's lean-in (HANDOFF_small_screens_20261029,
    sections 2 to 6), the game staying at 0.75 so the Deck keeps the full card (item 42 a). Built: (1) the menu's
    scale: while the desk is up and no game is loaded the root is at least 1.0 and at most sMax / 4 (4 on a Deck or at
    720p, 6 at 1080p, 12 at 4K: no change at 1080p and up); the game's scale and its fit cap are untouched.
    (2) Two framings behind MM.layout(): the room (as today) and leaning in (the desk at the smallest whole multiple
    whose monitor holds 960 x 720 units, the monitor whole on screen and centred, 10 desk px of the right bezel in
    view). The room is the only framing wherever its monitor holds the menu (every desktop size). Where it does not,
    the main view and the desktop stay in the room in the small layout (the window narrows to the room left of the
    icon block, 456 units on a Deck, and sits at the left edge) and every other view leans in: Load, New game and
    its steps, Mods, Options, and every registered view. If the small layout does not fit (Large text), the main view
    leans in too. (3) The move between framings is a 200 ms dip to black and back; none starts while the power-on,
    the power-off or the wake runs. Section 1 of the handoff (Auto's floor 1.0 in the game, a 1.5x cap, the
    options row text) is superseded by item 39 and not built. QA: at 1280x800 and 1280x720, Auto, Normal and Large:
    the main view in the small layout with nothing past the monitor (Normal), the main view leaned in (Large), every
    page (Options, Spawn, Sandbox, Traits, Looks, Mods, Load, Workshop, Credits) leaned in and fitting the monitor,
    Back leaning out, the dip once each way and never the wrong framing; 1920x1080 and 4K pixel-identical to the
    Nov 1 desk captures (mm_desk_v4). The in-game scale on the Deck unchanged (0.75).

    - **QA, Nov 1 2026, evening: confirmed.** zedqa_menu_lean.lua at 1280x800 and 1280x720, Normal then Large
      (ZeDUI/qa/Nov1_main_menu/README.md, lean/, the game consoles in qa/regression/2026-11-01_menu_lean_*): **47 / 47
      at Normal and 48 / 48 at Large, each size, 0 FAIL.** Root 1.0 at the menu, the game's 0.75 beside it. Normal:
      the main view in the room (desk 3x, monitor 720x540, the window's right edge 750 against the icon block at 764),
      Options, New game with Spawn, Sandbox, Traits and Looks, Mods, Load, Workshop and Credits each lean in (desk 4x,
      monitor 960x720 whole on screen, 40 px = 10 desk px of the right bezel), Back leans out, one dip each way; the
      frame caught 108 / 116 ms into the first dip is black (darkness 0.92 at 800, 0.84 at 720), never the wrong
      framing. Large: the main view leans in too and nothing dips. The 1080p desk after the change: every pixel
      outside the monitor's screen is identical to this afternoon's capture (the differences lie inside
      498-1425 x 129-762, the menu window's own content: the save thumbnail, the Last played time, the clock).
49. **Build and Craft: see what you get before you commit (the director, Nov 1 2026; for t16).** open, the
    director's words: on the Build tab, clicking the picked recipe's icon in the header could show "a preview of the
    tile in-game, and a short description, if there is something like that"; "item stats, like if I'm going to put a
    fence up or a metal fence up, which one can withstand more damage"; "the same would go for crafting: if I add
    barbed wire to a bat, I want to see what that upgrade will do before I commit". What the game has (build, by
    reading): every built thing has its tile pictures per face (the sprite rows in its SpriteConfig; loadable as
    textures by name, as the object cards already do) and a strength: a fixed health (big metal fence 450, wire fence
    400, log wall 500, brick wall 500 / 800, metal wall 700 / 800, metal frame 100) or a skill-based one (base + the
    character's carpentry through buildUtil.getWoodHealth: log and stick fences 200 + skill; gates 300 skill-based),
    and 135 of the 189 recipes carry a Tooltip key with real words (the big metal fence: "At least you'll see the
    horde before they break in. Pointy weapons can attack through this."). Barricades carry no number in their
    scripts (their strength is in the barricade code). Craft recipes name their output items, and the item card
    already reads a weapon's damage, range, crit chance, tree damage and condition, so an upgrade can show the
    output beside the input with the change. Today the Build header has a description slot that stays empty
    (it reads a method the game does not have; getTooltip is the one). Ways: (1) the header fills in: the
    description under the name, a strength line for the character as they are ("Strength 450" / "Strength 200,
    + your carpentry"), and for a craft the output's key facts; (2) a click on the header's icon opens a preview
    card in the drawer: the tile at twice its size, the face you would build with its rotation, the words, the
    strength, the skill and time, and for a craft the output item's card with the change against the item it
    upgrades ("Damage 0.8 to 1.2 -> 1.0 to 1.5"); (3) hover on the icon, a tooltip with the same. Build's pick: 1
    always on, and 2 for the click. Waits for the director.
    **The director, Nov 1 2026: "2", the preview card on the icon's click.** The header's description slot is fixed
    on the way (build, Nov 1: Build and Craft read the recipe's Tooltip through getText; a plain bug since the slot
    was drawn). **The card's rules, for the director's yes before the build:**
    - Opens on a click on the picked recipe's icon in the header, or A on it with a controller (the icon is a
      stop). It is a card in the drawer, the half card, over the recipe list, the way an item card opens; the list
      stays behind it. B, Back, a click on the icon again or picking another recipe closes it, and the focus goes
      back to the icon.
    - A build recipe's card: the thing's picture at twice its tile size, facing north; where it has four faces,
      Left and Right turn it, and a thing built on several squares (a double gate) shows whole. Under it the
      name, the game's words, then Strength as a number for your character as they stand: a fixed one plain
      ("Strength 450"), a wooden one as its parts ("Strength 200 + 150 from your carpentry": the game gives 50 a
      level and 100 more for Handy), barricades with no number (their strength is each plank's). Then the skill
      it needs and the time. The band at the foot: Build and Back; Build greyed with the reason when you cannot
      yet (the hidden-actions rule as the object cards keep it).
    - A craft recipe's card: the thing you would get, shown as its item card would show it (damage, range, crit,
      condition, weight, and the food label where it is food). When the recipe upgrades one of your own items
      (the input that matches the output's kind, a bat into a spiked bat), a Change strip under the facts: each
      fact that changes, old to new, with the step ("Damage 0.8 to 1.2 -> 1.0 to 1.5, +25%"). The band: Craft
      and Back.
    - Reading is free: the card opens for a recipe you cannot make yet or do not know; only the button at the
      foot says no. A recipe whose result is one of several (a random one) shows the first with "or one of N".
    - The pad: Up and Down walk the card's stops (the facing turn, the band); the card's own Craft or Build
      presses the same as the drawer's; the rest of the drawer is out of reach while the card is up (as with an
      item card). Pattern parity: the same card and rules on the Character window's Journal recipes where a
      recipe shows there.
    **built (build, Nov 1 2026, the director: "Build"), QA to confirm.** ObjectCardPreview.lua, a half-width object card
    kind over the Build or Craft drawer (the World window's object cards learned a half width for it); the header's
    icon is a click and a controller stop (prefix:icon) in CraftingCore; ZeD.itemFacts exports the item card's facts.
    Not built: the Journal's recipes (the Character window has no card drawer of its own). QA, at 4K and on the Deck:
    Build, pick the big metal fence, click the icon: the card with the tiles, Facing with < and > turning it, the
    words, "Strength 450", "Skill Metalworking 3", the Build verb (folded with its need when the parts are not
    in reach); a log fence: "Strength 200 + N from your carpentry"; a plank barricade: no strength line; B closes
    and the focus is back on the icon; picking another recipe closes it. Craft, with a baseball bat carried, pick
    the spiked bat: What you get with the facts, and What changes against the bat (damage, condition, weight); a
    recipe with several possible results shows "or one of N others". The 1080p pair unchanged elsewhere.
    **Second pass (build, Nov 1, on QA's five points from reading the code):** (1, 2) the strength is now the number the
    game sets when the thing is built (ISBuildIsoEntity: the script's health + its bonus at the sandbox's Construction
    Bonus Points multiplier + the highest relevant skill level x the skill base health), shown as the total with its
    parts: "600 (450 + 150 from your Metalworking)"; a log fence reads "200 + N from your Carpentry" through the same
    rule; barricades still none. (3) Condition (the maximum) is a fact on the card and in What changes. (4) The facing
    wraps by hand (Kahlua's % keeps the sign). (5) What changes skips inputs the recipe keeps (tools), so a hammer never
    stands in for the bat. The small page draws no holes, by design. The punch list's expected lines above read as the
    first pass wrote them; QA's scripts (pvc, nbp) carry the second.

50. **Notebook paper: the lines were not ruled like paper (the director, Nov 1 2026, with four pictures of the real
    sheet).** fixed (build, Nov 1), QA to confirm. The Notebooks page (the small page in the Journal's Notebooks
    sub-tab) and the full page in the reader drew their blue rules only to the right of the red margin, from the
    very top, the margin close to the edge, and the full page ran a red line across the head. Now, as the real
    sheet: the rules run edge to edge through the margin, the red margin runs the page's full height about a
    seventh of the width in (104 of 760 units on the full page), a blank band sits above the first rule (one rule
    tall on the small page; the head band with the name and page number on the full page, closed by the first
    rule), nothing red runs across, the binder holes stay. QA: the Notebooks sub-tab's small page with and without
    writing, and Open full, at 4K and on the Deck.

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
  Fixed (c5090f6): it now passes.
- The third pass at c5090f6: the segmented bars with 400 different things on the ground (400 rows):
  11.2 ms a tick still, 11.9 ms scrolling, against 8.4 ms empty; one 45 ms frame, no stutter. The
  pen registered this time: its food and water bars are in zqa_bars_animals_zone.png (the pen's
  overview). The 400 included things the game itself cannot draw on the ground (551 of the game's own
  errors while they lay there; zedqa_bars_look should pick tools and weapons only). The grid still reads
  raised at the start and end (ElecShutModifier 99999, power on).
- The QA save's grid switched off (director, Oct 30: "switch it off"; zedqa_grid_off.lua): every backup
  since Oct 28 had ElecShutModifier 99999 (power never shut). Now 0 and the world's power flag off; read
  back after a restart (0, off). Tests that need power raise both for their run and put back "off". The
  D: backup of Oct 30 refreshed with it.

## Confirmed

(none yet)
