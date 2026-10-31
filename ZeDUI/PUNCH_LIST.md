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
