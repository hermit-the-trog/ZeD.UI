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
   the same faces. Request: `docs/handoffs/REQUEST_design_radio_tv_faces_20261030.md`. Washers and dryers
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
   Request: `docs/handoffs/REQUEST_design_plates_fill_20261030.md`. The test checks the right width loads
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
      (Casual) as if it applied. Screenshot: ZeDUI/qa/archive/Oct30_mouse_pass/qa18_additions_group.jpg.
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
    18's shot). Screenshot: ZeDUI/qa/archive/Oct30_mouse_pass/qa19_restock_dim.jpg.
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

    **Spec and mockup (build, Oct 31, 3f0b244):** docs/specs/MOD_FOLDERS_SPEC.md (ModFolders.cfg's format from the
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
    docs/specs/MODS_LOAD_ORDER_SPEC.md, mockup ZeDUI/mockups/zed_mod_folders_v2.html (7ee6ef4), together with item 37's
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
    **Stage 3 separators built (0afb1ac, 8f70121, b828ebb), QA to confirm.** Separators on the Load order
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
        laundry, the plates, the menus and the soak. Main-menu checks (ZeDUI/qa/archive/Nov1_main_menu/): the About menu ends
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

43. **Foraging finds: the compass letter is wrong (QA, Nov 1 2026, found while staging the gallery retake).** **[confirmed (QA, Nov 1 2026, the probe; header corrected Nov 2).]** open.
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
    **Rules pass (build, Nov 1 2026 evening, for the director's picks).** What exists: with the mouse a click selects one
    row, Ctrl-click adds or removes one, Shift-click takes the run between; the selection shows as the rows' wash,
    feeds a drag of all of them and the context menu over all of them (the game's own menu for several items: drop
    all, move all), and the card hides while more than one is selected. With the pad: tap A opens the row's card
    and makes it the one selected (Hard Rule 3), hold A is quick use (a double-click), tap X is the row's menu, hold
    X is drag mode, used today only by the container strip to reorder. Proposed rules:
    1. Tap A on a row: as today, its card, that row the one selected.
    2. Hold A on a row: MARK it (the row's wash, as Ctrl-click): a second mark on a marked row unmarks it. While
       A stays held, Up and Down mark the rows passed (Shift-click's run, painted); letting go ends the stroke.
    3. With marks on the list: the card hides (as with the mouse); the help line says "3 marked | X: menu | B: clear
       marks"; tap X opens the game's menu for all marked rows; the band's Take / Drop / Move act on all marked;
       the first B clears the marks and leaves the focus where it is; a stack header marks its whole stack.
    4. Hold X on a row: quick use (the double-click), the director's own trade; the container strip keeps hold X
       for reordering (another element, no clash).
    5. Marks belong to one list: picking another container or tab clears them, as the mouse does. The pattern is the
       same in the World window (parity).
    Questions: (a) tap A on a marked row: open its card and drop the marks (the plain click's way), or keep the marks
    and only move the focus? (b) the painted run while A is held: wanted, or marks one at a time only? (c) hold X as
    quick use on rows: yes, or leave hold X unused on rows for later?
    **The director's picks (Nov 1 2026 evening): (a) drop the marks, (b) paint the run, (c) quick use.** **built (build,
    Nov 1), QA to confirm.** InventoryRenderer: padMark / padPaint / padMarkedItems / padClearMarks / padMarkCount on the
    list's own selection (the main list's or a column's, as Ctrl-click uses); the four row builders (main and columns,
    both windows) give rows hold A = mark, onPaint, hold X = quick use, B = clear marks (its prompt and X's "Menu for
    marked" only while marks exist), and X's menu takes every marked row; FocusManager: a D-pad move while A is held past
    its hold lands as usual and the row landed on takes the stroke's mark (w._gpPaint; the release ends it), and an
    element with no drag may take a one-shot onHoldContext; the help line on a focused row reads "3 marked | X: menu
    for all | B: clear marks"; GAMEPAD_SPEC's A and X rows carry the rules. QA: with the pad on a crate's list, hold A
    on a row (its wash, the card hides), hold A again (unmarked), hold A and Down three rows (four marked), X (the
    game's menu for four: drop all, move all), B (marks gone, focus stays), tap A on a marked row (its card, marks
    gone), hold X on a crate's row (it comes to the main inventory), a stack header (the whole stack marked), the same
    in the Character window and in an extra column; the band's Take with marks takes them all.

    **QA's code read (Nov 1, late) and the fixes (build): six findings, all fixed, and the hook added.** (1) one controller
    mark opened the card (the drawer showed it for exactly one selected): the controller's marks set a flag on the list
    (_padMarks) and the drawer hides the card while it stands; a mouse press, a tap A or the marks going clear it. (2) the
    painted run collapsed because the card's follow-focus replaced the selection: it stays out while A paints (w._gpPaint),
    and the card is hidden anyway. (3)(4) B, its prompt and X's were set when the rows were built and went stale, and the
    footer draws prompts, not help words: the rows' onCancel, promptB, promptX and promptHold are functions the footer
    reads each frame (Organisms: a prompt may be a function; false hides it); B with no marks does nothing (no sound);
    X reads "Menu for 3 marked", hold A "Mark (hold)" or "Unmark (hold)"; the help line is gone. (5) tap A on a marked
    column row cleared the main list's selection: it clears every list's marks first (padClearMarks wipes in place; the
    column tables and the content's alias one another, so the tables stay and empty), and padMarkCount counts a table
    once. (6) the band's Take took everything: with marks the World band's Take is "Take marked" (the marked rows of
    every list) and the Character band's Transfer all is "Move marked", or "Drop marked" to the floor; the band rebuilds
    when the count changes. The hook: Focus.qaButton(name, true / false / nil) overrides a pad button's state, read by
    _btnDown in place of the raw isDown, and the Y / A / X holds run in _holdTicks before the no-pad return. Parsed
    (KCheck), i18n guard passes. QA: zedqa_pad_marks.lua (pmk) at 4K and Deck.
    - **QA, Nov 1 2026, late (zedqa_pad_marks.lua on d87f278 at 4K and the Deck; qa/regression/2026-11-01_t16_marks_4k.md,
      _800.md, the same at both; shots in Screenshots/t16_marks_4k, _800): 33 PASS, the two FAILs the script's own
      staging. The hold was the real one through Focus.qaButton (press, held 450 ms by the clock, release).** Confirmed
      in the Character window's main list: with no marks the hold-A prompt reads "Mark (hold)", B's prompt is hidden and
      B does nothing; hold A marks the row (the wash, count 1) and the card stays hidden; hold A again unmarks; a stack
      header marks its three; held A with Down x3 marks the four rows passed and letting go ends the stroke (the next
      Down leaves the four); with marks the prompts read "Unmark (hold)", "Menu for 4 marked", "Clear marks"; X opens the
      game's menu (11 options) and its Drop holds all 4; B clears the marks with the focus on the same row, B's prompt
      gone, a second B nothing; tap A on a marked row opens its card and the other marks go. World: hold X on a crate
      row is the quick use (the tweezers came to the main inventory); with marks the band's Take reads "Take marked"
      (hint "Take the 3 marked"), moves only the marked rows (2 of 2, the apple left) and clears the marks; the Character
      band's Transfer all reads "Move marked" (hint "Move the 3 marked") and moves only the marked (the corkscrews
      stay), marks cleared. **Not yet run: the column checks** (marks apart between a column and the main list, tap A
      on a column row): the script's second crate did not open as a column (the window already showed it) and the
      World list had no four single rows in a row for the painted run; the staging is being fixed for one more short
      run on the Deck.
    - **QA, Nov 1 2026, later (the staging fix, the Deck; 2026-11-01_t16_marks_800_b.md): 56 PASS, 1 FAIL (staging).**
      The World list now had its four single rows (Apple, Banana, Bandage, Cabbage) and every World check passed as the
      Character ones had: the painted run of four, letting go, the card hidden, the prompts, X's menu with Drop for all,
      B clearing with the focus kept, tap A. Still not reached: the column checks (marks apart, tap A on a column row):
      the column the script opened was not crate B's ("crate B as a column: true" then "no column for crate B (1
      columns)"), with crate A on show. A rig matter for the next session. 44 is confirmed on every rule the director
      picked except the one-list rule for a column, which no run has exercised yet.
45. **Reset windows leaves the old tab's pad stops behind (QA, Nov 1 2026, the 720 short run; build's cause).** **[confirmed (QA, Nov 1 2026; header corrected Nov 2).]**
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

46. **The saved window place keeps the engine's push (QA, Nov 1 2026, the 720 wpt run's cu, first cycle only).** **[confirmed (QA, Nov 2 2026; header corrected Nov 2).]** open,
    not a t15 blocker. cu straight after the prelude: "cycle1 World saved: got 853.333 want 858.667" (5.3 px at 720;
    the two 720 runs with cu after tww passed it). Cause (build): the World window's layout is also saved about once a
    second while it is open (saveWorldStateThrottled), and while a full-card tab holds the window against the
    screen's edge the saved x is the pushed one (640 px), not the window's own place (644). The window itself comes
    back right (items 42 e. and 45), but a Save and Quit with such a tab open reopens the window 4 px left of
    where it was. Fix: saveWorldState (and saveCharState) write the unpushed x, as they already write the unrolled
    x for a rolled side: x + the cap push for the World window, the anchor's x for the Character window. A line
    each; QA re-reads cu's saved lines after. For t16 unless the director says otherwise.
    **Fixed (build, Nov 2 2026), QA to confirm.** saveWorldState writes x + the cap push (the window's own place without
    the engine's push), still less the roll for a rolled side. The Character window needed nothing: it saves from its
    anchor, which a push never moves (the push is kept apart, _drawerCapPush, and the anchor is set less it). QA: the
    720 wpt run's cu straight after the prelude, the World window's saved x the window's own (858.667 at 720), with a
    full-card tab open while the save is written.
    **QA, Nov 2 2026: confirmed at 436dabb (2026-11-02_pl46_pgi_720.md: the prelude then cu at 1280x720).** cycle1 World
    saved 858.667,0 with the Maps card open in the drawer (the window held at 640 by the push); cycle2 858.667 too; the
    Character window 404,0 from its anchor. cu passes.

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
    **Build, Nov 2 2026: the prints and the guard are in (rig files only).** zedqa_prelude.lua defines ZEDQA_VPROBE(tag, sq,
    v); the eleven vehicle scripts (sl, rb, sm, tm, t3, dash, dpx, dnt, dgr, dke, dbr) call it on the line after their one
    spawn, guarded so a script run alone skips it. One line each, grep "ZEDQA vp": the character's x,y, the chunk grid
    (chunks and tiles across, from the chunk map's own width) and the tiles it covers, the spawn square's x,y, its
    distance from the character, whether it has a chunk and whether it lies in the chunk map, the car's script, place
    and distance, and the cell's vehicle count (cars left behind by earlier scripts show as a growing count). rst prints
    the same line at its fixture step (the square at 892,13040), and a fixture not found (no grandstand, no clear floor,
    or an incomplete build, whose pieces are removed) now ends the script with one ERR line and DONE instead of an error
    in every later step. Parsed (KCheck). Ready for the 35-minute 720 slot.
    **QA, Nov 2 2026: run (2026-11-02_pl47_bisect_720.md: prelude + scripts 42-80 + sl at 1280x720, 40 / 41).** Scripts
    42-80 all pass; sl fails as in the full passes (vanilla's "onEnterVehicle: isDriver of non-table: null" for the police
    car and the van, physics=false at the enter). The probe rules out the cars falling outside the simulated grid:
    "player=964,13078 grid=13 chunks (104 tiles) loaded x 912-1016 y 13024-13128 sq=968,13078 dist=4.1 chunk=true
    inMap=true car=Base.CarLightsPolice ... vehicles=8" (the van the same at 6.0 tiles). Each car is a few tiles from the
    character, on a loaded square in the chunk map; the cell holds 8 vehicles, so earlier scripts left cars behind
    (only sl prints, so where the count grows is not seen). Next: what scripts 42-80 leave that keeps a fresh car's
    physics asleep (the cars left behind, or a vehicle or seat state on the character); a halving of 42-80 at 720
    (about 15 min each) with the probe in a few of them, or a probe line at the start of each script.
    **QA, Nov 2 2026, later: the state line at 242d3a0 errors before every script (2026-11-02_pl47_state_720.md).** Each
    reads "[ZeD.QA] state #n ERR Object tried to call nil in pcall"; Kahlua logs the caught error as a Java exception, so
    the runner marks all 41 scripts FAIL and the run has no state data. sl's own lines unchanged (cars on loaded squares,
    vehicles=8, physics=false). Back to build: which call is nil; QA reruns when it is pushed.
    **QA, Nov 2 2026, later still: the cause found (2026-11-02_pl47_state2_720.md at 22319df, 40 / 41;
    2026-11-02_pl47_moved_sl_720.md).** The state line works; its "missing=get" is the call that broke the run before
    (the cell's vehicle list's get is not reachable as o[m]), so each car's physics is still unseen. Nothing piles up:
    vehicles=8 at the start, 10 or 11 mid-run, 8 again at sl; speed 1, not paused, not in a car. What moves is the
    character: 925,13040 after the prelude, 965,13081 after script 57 (cb), 968,13081 after 61 (bg), 964,13079 after 63
    (ws), there to sl (the save keeps it, so a run also starts there). Decisive: prelude, a move to 964.5,13078.5,0
    (zedqa_move_to.lua), then sl fails exactly as in the full pass. That square is indoors (a room, not outside): sl's
    cars spawn inside a building and their physics never wakes. Not the 13-chunk grid, not leftovers. For build: the
    vehicle scripts start from the drag strip, or the scripts that walk the character away put it back. Not tested:
    why the 1080p full pass passes sl from the same place.
    **QA, Nov 2 2026, evening: the full 720 pass at 3d485cc, 95 / 99, 0 fail (was 86 / 99; 2026-11-02_pl47_full_720.md).**
    Every vehicle script passes: sl, rb, sm, tm, t3, dash, dpx, dnt, dke, dbr, each starting with its "moved ... to the
    drag strip" line. Four warnings: dgr's fire truck never reached 64 km/h (max 0.0; the old drag-strip note under Test
    process); wpt "hold A moved the hammer out of the crate" (the old Eraser-position note); jrd "Too dark to write" (the
    time of day, noted before); and rst, moved from 964,13081 to the strip, then at once "no grandstand building near
    892,13040" and its clean stop. rst's fixture is looked for right after the move, likely before the grandstand's
    cells load (the prelude waits 300 frames after its move). For build: rst waits after ZEDQA_HOME moves it. The vehicle
    part of 47 is done; rst is what is left.
    **QA, Nov 2 2026, evening: rst's wait at afbc5a2 works, its fixture still fails (2026-11-02_pl47_moved_rst_720.md:
    prelude, the move to 964,13078, rst at 720).** "moved from 964,13078,0 to the drag strip", then "the grandstand is
    loaded", then "no clear 9x3 floor in the grandstand" and the clean stop. Earlier at 720 (bisect b, Nov 1) rst straight
    after the prelude found its floor. Either something now stands on the floor (the QA save keeps what runs leave), or
    the floor check differs after a move. For build: name what blocks the floor in the ERR line.
    **QA, Nov 2 2026, evening: what blocks it (f838593, 2026-11-02_pl47_moved_rst2_720.md).** The right building
    (875,12964, x 875-893 y 12964-13122); its footprint tallies "no square" 2829, clear 103, two or three objects 49, not
    free 8, another building or outside 32; the nearest 9x3 (885,13040) is blocked first at 884,13039 by "no square".
    Nothing stands on the floor: most of it is not loaded yet when rst looks. Its wait ends when any one square from 880
    to 892 has its building; the 9x3 it needs loads later. For build: wait until the nearest 9x3's squares all exist (or
    the prelude's 300 frames after a move).
    **QA, Nov 2 2026, evening: rst passes from the moved place (17cb7c7, 2026-11-02_pl47_moved_rst3_720.md, 3 / 3).**
    Moved home, waited for the whole floor patch, fixture found (standing at 885,13029), built, stocked and its checks
    passed. With the full 720 pass at 3d485cc (95 / 99, every vehicle script passing), 47 is done; the three warnings
    left there (dgr, wpt, jrd) are the old rig notes under Test process. Not checked: why the 1080p pass passed sl from
    the same place (the state line at 1080p would show it, if it ever matters).
    **Build's call (Nov 2 2026): the probe, not the halving.** QABridge.lua prints one line before every script it runs,
    grep "[ZeD.QA] state #": the game speed and pause, the character's place and car, the chunk grid, and each vehicle the
    cell holds (up to 12) with its distance, physics on or off, and "remote" if this game does not simulate it. One
    720 run of prelude + 42-80 + sl shows where the vehicle count first grows, whether an old car keeps its physics on
    and whether a fresh car is marked as simulated elsewhere; a halving follows only if that points nowhere. (The
    physics world's own offset, WorldSimulation, is not reachable from Lua, so a stale offset can only be inferred: cars
    on loaded squares, physics off, nothing else wrong.)
    **Cause found (QA, Nov 2 2026) and the fix (build, Nov 2).** QA's state lines and a moved-sl run: scripts 57, 61 and 63
    (cb, bg, ws) leave the character in the grandstand at about 964,13079, indoors; the vehicle scripts spawn their cars a
    few squares from the character, so the cars stand in the building and their physics never wakes ("isDriver of
    non-table" at the enter). Not the 13-chunk grid, not cars left behind (the count stays 8 to 11). At 720 the
    grandstand's west end (892) also falls outside the loaded grid from there, which is rst's "fixture not found". The
    first state line's missing= named the cell vehicle list's get as the call Lua cannot reach (the earlier failure).
    Fix, rig only: zedqa_prelude.lua defines ZEDQA_HOME(tag), the prelude's own move to the drag strip (out of any car,
    when more than 3 squares away, one "ZEDQA home" line when it moves); the eleven vehicle scripts and rst call it first,
    guarded. Parsed. QA: the 720 full pass (vehicle scripts and rst expected to pass); why the 1080p pass passed sl from
    the same place is still open (the state line at 1080p would show where it stands).

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
      (ZeDUI/qa/archive/Nov1_main_menu/README.md, lean/, the game consoles in qa/regression/2026-11-01_menu_lean_*): **47 / 47
      at Normal and 48 / 48 at Large, each size, 0 FAIL.** Root 1.0 at the menu, the game's 0.75 beside it. Normal:
      the main view in the room (desk 3x, monitor 720x540, the window's right edge 750 against the icon block at 764),
      Options, New game with Spawn, Sandbox, Traits and Looks, Mods, Load, Workshop and Credits each lean in (desk 4x,
      monitor 960x720 whole on screen, 40 px = 10 desk px of the right bezel), Back leans out, one dip each way; the
      frame caught 108 / 116 ms into the first dip is black (darkness 0.92 at 800, 0.84 at 720), never the wrong
      framing. Large: the main view leans in too and nothing dips. The 1080p desk after the change: every pixel
      outside the monitor's screen is identical to this afternoon's capture (the differences lie inside
      498-1425 x 129-762, the menu window's own content: the save thumbnail, the Last played time, the clock).
49. **Build and Craft: see what you get before you commit (the director, Nov 1 2026; for t16).** **[confirmed (QA, Nov 1 2026; header corrected Nov 2).]** open, the
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
    **Third pass (build, Nov 1, on the 4K and Deck runs):** the card opened, closed and focused right; its data threw.
    (a) The engine's build object: BuildLogic.getSelectedBuildObject reads a recipe-to-entity lookup that only
    getAllBuildableRecipes fills; the card now fills it once per card. (b) The craft output: the drawer's pre-bake asks
    a script item for getFullType, which it lacks, so the output types were empty and no item was instanced; the card
    reads the full type as module.name and, for an output written through a mapper (nails on a bat), the mapper's
    results, picking the one whose pattern you carry and comparing against that item. QA re-runs pvc at both sizes.
    **Fourth pass (build, Nov 1, on the second run, 982ac42, where the card read right at both sizes):** the facing
    wraps at the press itself (< from the first face lands on the last, never on 0 between frames); a zero skill part
    reads "200 (200 + more with your Carpentry)" with the skill named (the recipe's highest relevant skill, else its
    first required one, else carpentry: at level 0 the game names none); a thing that is not thumpable (the plank
    barricade) has no strength line. QA to confirm those three; the rest of 49 read right on the second run.

    - **QA, Nov 1 2026, late (zedqa_preview_card.lua at 4K on 4593e3d, then on the Deck at 1e947e2; qa/regression/
      2026-11-01_t16_cards_4k.md, _800.md; shots in Screenshots/t16_cards_4k, _800): FAIL, the card's data path throws.**
      What passes at both: Build tab, the big metal pole fence picked by name; the header's icon is a stop (build:icon)
      with the focus; A opens the preview as the half card over the drawer (Deck: 893,20 165x278, drawer 360), the list
      behind; the focus goes into the card; the game's own words from the Tooltip; the verb Build, folded with its
      need ("a higher skill"); B closes it with the focus back on the icon; A opens it again; picking another recipe
      closes it; the craft tab the same with the spiked bat (craft:icon, A opens). tww unchanged at both.
      **The fault:** every refresh of the card throws, 20 times a run: java.lang.NullPointerException "Cannot invoke
      CraftRecipeComponentScript.getParent() because craftRecipeComponentScript is null" at
      BuildLogic.getSelectedBuildObject(BuildLogic.java:82), from ObjectCards.lua:55 call <- ObjectCardPreview.lua:60
      buildData <- :199 refresh (plus 3x "getScript of non-table", 2x "getName of non-table", 1x "tried to call nil in
      pcall"). So the card has no strength line at all ("Strength nil"), the metal fence shows one face and no Facing
      row, the double gate (DoubleFenceGate, 'Double Tall Metal Pole Gate') shows 1 tile on 1 square, and the craft
      card for the spiked bat has 0 facts in What you get and nothing in What changes; "or one of N others" reads 0.
      Same at 4K on the first pass and on the Deck on the second (1e947e2), so the second pass did not reach it: the
      BuildLogic the card makes has no recipe component set when getSelectedBuildObject runs. Wording: the skill reads
      "Skill Welding 3" (the perk's getName), not "Metalworking"; the test now accepts the game's name. The QA script
      reads the strength against the game's formula (base + bonus x the sandbox multiplier + skill x skill base) and
      prints the parts. Re-run (both sizes, about 10 min each) when the fix is on main.
    - **QA, Nov 1 2026, later (third pass 982ac42, at 4K and the Deck; qa/regression/2026-11-01_t16_cards_4k_b.md,
      _800_b.md; shots in Screenshots/t16_cards_4k_b, _800_b): mostly there, three product points left.** Now right at
      both sizes: the metal pole fence shows two faces with the Facing row, > turns it and < turns it back; "Strength
      500 (450 + 50 from your Welding)" against the game's formula (health 450 + Welding 1 x 50); the double gate shows
      4 tiles on 4 squares, 4x1 facing north and 1x4 facing west; the spiked bat's What you get has 6 facts (Damage
      1.2 - 1.9, Speed, Range, Crit, Tree dmg, Condition 10; weight 2.5) and What changes against the carried Baseball
      Bat reads Damage 0.8 - 1.1 -> 1.2 - 1.9 (+50%), Range 1.2 -> 1.3 (+8%), Condition 15 -> 10 (-33%), Weight 2.0 ->
      2.5; the nail-spiked weapon says "or one of 7 others". Left (product): (1) **< from the first face still lands on
      face 0, "No picture for this one"** at both sizes (the by-hand wrap did not take). (2) **A zero skill part is
      shown with an empty name:** the log fence at Carpentry 0 reads "Strength 200 (200 + 0 from your )"; the log gate
      (health -1, skill base 300) reads "Strength 0" at Carpentry 0, true to the formula but worth a design look (name
      the skill it would grow with, or hide a zero part). (3) **The plank barricade shows "Strength 0"** instead of no
      line. The three Java exceptions left in the run (2x "getName of non-table: null", 1x "tried to call nil in
      pcall") look like the empty perk at level 0. The test now accepts the game's perk name ("Welding"), reads the
      card's own count of other results, and notes rather than fails a zero part.
    - **QA, Nov 1 2026, last run (fourth pass 638baa7, pvc alone on the Deck; qa/regression/2026-11-01_t16_pvc_800_c.md):
      every check of the script passes.** < from the first face lands on the last with its picture; the plank
      barricade has no strength line; the log fence at Carpentry 0 reads "Strength 200 (200 + more with your )" and the
      log gate "Strength 0 (more with your )": **the skill's name is still empty** at level 0 on the Deck (the card's
      fallback to the recipe's first required skill, then carpentry, gave ""; Build to look at ObjectCardPreview.lua
      116-124 with a LogFence at Carpentry 0). The runner's FAIL on the run was three exceptions the test itself logged
      inside pcall under -debug (its own getName on a nil perk twice, a nil getOutputs once); both guarded now, so the
      next run is clean on the rig side. One more pvc-alone run after the name fix closes 49.
    - **QA, Nov 1 2026: confirmed (2f65396, pvc alone on the Deck; qa/regression/2026-11-01_t16_pvc_800_d.md).** Every
      check passes: the metal pole fence "Strength 500 (450 + 50 from your Welding)", the log fence "Strength 200 (200 +
      more with your Carpentry)", the log gate "Strength 0 (more with your Carpentry)", the plank barricade no line, <
      from the first face round to the last, the double gate's four tiles, the spiked bat's What you get and What
      changes, "or one of 7 others". The run's one logged exception is the test's own (a nil call inside its "several
      results" pcall under -debug), fixed on the rig side. 49 closed on the product side.
50. **Notebook paper: the lines were not ruled like paper (the director, Nov 1 2026, with four pictures of the real
    sheet).** **[confirmed (QA, Nov 1 2026; header corrected Nov 2).]** fixed (build, Nov 1), QA to confirm. The Notebooks page (the small page in the Journal's Notebooks
    sub-tab) and the full page in the reader drew their blue rules only to the right of the red margin, from the
    very top, the margin close to the edge, and the full page ran a red line across the head. Now, as the real
    sheet: the rules run edge to edge through the margin, the red margin runs the page's full height about a
    seventh of the width in (104 of 760 units on the full page), a blank band sits above the first rule (one rule
    tall on the small page; the head band with the name and page number on the full page, closed by the first
    rule), nothing red runs across, the binder holes stay. QA: the Notebooks sub-tab's small page with and without
    writing, and Open full, at 4K and on the Deck.

    - **QA, Nov 1 2026, late: confirmed by the pictures (zedqa_notebook_paper.lua at 4K and the Deck; shots
      zqa_nbp_small_blank / _written, zqa_nbp_full_blank / _written in Screenshots/t16_cards_4k, _800).** The full page on
      the Deck: the blue rules run edge to edge through the red margin, 16 rules at a 17 px pitch, the first rule 53 px
      below the page's top with the title and "Page 1 of 10" in that band, the red margin the page's full height about
      0.137 of the width in (a seventh is 0.143), no red line across, three holes at the left; the small page the same
      without holes (by design). The two quick-note lines sit on the rules. The script's own measure (a wrapped drawRect /
      drawText for a few ticks) saw none of the paper's draws, so its four "the paper was drawn" lines are the test, not
      the paper: the paper is drawn by another call; QA fixes the measure next time.
    - **QA, Nov 1 2026, later: confirmed by measure at both sizes (the measure hooks the drawer panel and the reader
      window now; 2026-11-01_t16_cards_800_b.md).** Small page: the paper 335 x 103 units, 5 rules at a 17.5 px pitch,
      the first 1.4 pitches below the top, every rule edge to edge through the margin, the red margin 1 px wide at 0.137
      of the width and the page's full height, nothing red across, both quick-note lines on a rule and right of the
      margin, no holes (by design). Full page: 570 x 339, 16 rules at 17 px, the first 53 px (3.1 pitches) below the
      top with "Page 1 of 10" in that band (y +23), the margin 2 px at 0.137 (the code's 104 of 760) full height, three
      binder holes at x +11 left of the margin, nothing red across; the line counter sits at the foot below the rules
      (y +316), by design. The test's two "sits in the head band" lines were its own (a screen y against a page y).
51. **AI-drafted translations for players to check (the director, Nov 2 2026, from the Workshop comments).** **[superseded by 62.]** open, an
    idea for Build and the director to talk through; nothing started. Turk asked "Bro please add turkish" (Nov 2).
    The director can't read the languages players ask for, so a translation can't be checked here. The idea: ZeD drafts
    the missing languages with AI and posts them in the Translations thread, so a native speaker fixes the phrases the
    draft gets wrong instead of translating all 2,400 from nothing. QA's notes for the talk:
    - The saving is in typing, not reading: a reviewer still reads every phrase to find the wrong ones. Say so in the ask.
    - Drafts stay out of the mod until a speaker signs off (an unchecked language would ship under ZeD's name). They
      live in a drafts folder in the public repo, linked from the Translations thread (Steam threads hold no files).
    - Label them as AI drafts up front; some players feel strongly about AI.
    - Each draft is checked before it is posted: every phrase against its length limit in ZeDUI/i18n/UI_ZeD.context.md,
      the guard test, a look in game with the language on, and the pixel face's capitals for that language's letters
      (Turkish needs Ş, Ğ and İ on the watch, dash and action bar; not checked yet).
    - New phrases in later builds get drafted alone, so reviewers check a short list.
    - Drafts are strongest for the big languages (Turkish, Russian, Chinese, Portuguese, Spanish, German, French, Polish,
      Japanese, Korean) and weaker for the small ones. A pilot with Turkish and Simplified Chinese (the two asked for)
      would show whether reviewers turn up before all 28 are drafted.
    - Reply to Turk is waiting on this (drafts with the director: ask for translators, or also offer an AI draft).

52. **The Sandbox page list does not scroll (a Workshop bug report by Kable, Nov 1 2026; the director, Nov 2: "Sandbox scroll
    fix").** **[confirmed (QA, Nov 2 2026; header corrected Nov 2).]** fixed (build, Nov 2), QA to confirm. Kable's picture showed the Sandbox page list cut off; QA confirmed it
    overnight: with 150 mods the Sandbox step has 42 pages, 22 fall below the list and 10 below the screen even at 4K,
    the wheel does nothing, and the bumpers reach the last page but draw it off screen. For a 1,500-mod list most pages
    could not be reached by mouse. Cause: the page list under Find (one function, ZeD_MMOptions.drawPages, shared by
    Options, the main menu's Sandbox step and the Sandbox window in game) drew every page top to bottom with no box,
    no scroll and no wheel; the wheel handler only listened over the settings rows. The server settings screen had its
    own list that did scroll, but its bumpers did not bring the picked page into view either. Fix: the shared list
    clips to its box, scrolls by the wheel over it (two rows a notch) and by a bar that drags, takes clicks only where
    a row shows, and brings the picked page into view whenever it changes (a bumper, a page opened from elsewhere);
    the in-game Sandbox's change marks ride with their rows; the server list follows the picked page the same way. QA:
    the 150-mod rig at 4K and on the Deck: the wheel over the page list moves it to the last page; the bar drags; RB
    from the first page to the last keeps the picked page in view at every step and LB wraps back to the top; a click on
    a half-hidden row at the box's edge picks it, a click on the Find box above it does not pick a page; the in-game
    Sandbox window the same, its change marks on the right rows after a scroll; Options with many mod pages; the
    server settings' bumpers. Reply to Kable drafted in the Nov 2 morning note (post after the build ships, with the
    director's yes).
    **QA, Nov 2 2026: confirmed at 3050a0d (the 150-mod rig, the main menu at 4K and on the Deck; the in-game window at
    720; new checks zedqa_menu_pagelist.lua and zedqa_sandbox_ig_pages.lua on zedqa_pagelist_lib.lua).** The Sandbox step,
    42 pages: 26 / 26 at 4K (box 1101 px, 21 rows shown) and 26 / 26 on the Deck (box 528 px, 18 rows shown). Every drawn
    row inside the box and the box on screen; a bar when the pages overflow; the wheel over the list reaches the last
    page whole (11 notches at 4K, 13 on the Deck) without changing the picked page, and back up to the first; the bar
    pressed at its end, middle (half way) and top; RB from page 1 to 42 keeps the picked row whole in view at all 41
    steps, RB on the last wraps to the first and LB on the first to the last, both in view; a click on a row cut by the
    box's top or bottom edge picks it, 2 px past either edge picks no page, a click on Find picks none. Pictures: the
    rows clip cleanly at both edges. Options, 9 pages: they fit at both sizes (no bar), bumpers and wraps pass. The
    Sandbox window in game (720): its 12 pages fit, bumpers and wraps pass; a changed setting's mark sits on its page's
    row inside the box, and Undo clears it. Not covered: the wheel by a real mouse (the test points the game's mouse
    reading at the list for each notch: the game reads the desktop cursor every frame; QA's control of the game window
    was not granted with nobody at the PC); the in-game window with a list long enough to scroll, so its marks riding a
    scroll (the in-game run with the 150 mods opened the save without them: one script load instead of three; to look
    at); the server settings' bumpers (no server settings file on this machine). Reports: 2026-11-02_pgl_4k.console.txt,
    2026-11-02_pgl_deck.console.txt, 2026-11-02_pl46_pgi_720.md.
    **QA, Nov 2 2026, later: the real mouse wheel too (Deck, 27 / 27).** The run held at the Sandbox step and QA turned
    the desktop's wheel over the page list (SetCursorPos + mouse_event from PowerShell, the game in front): the list
    scrolled 60 px a notch, 4 s into the hold. The main menu's gap is closed; the in-game scroll with marks and the
    server bumpers stay uncovered.

53. **Immersive Moodles support (QA's compat round 5, Nov 2 2026; the director, Nov 2: "Immersive Moodles").** **[confirmed (QA, Nov 2 2026; header corrected Nov 2).]** built
    (build, Nov 2), QA to confirm. Immersive Moodles (Workshop 3830422267, mod id ImmersiveMoodles, by Krovenox, about
    2,100 subscribers) draws an animated moodle column of its own and parks the game's column off screen every frame;
    ZeD placed the game's column every frame too, so each moodle showed twice, the game's with ZeD's hover note
    (qa/archive/Nov2_compat_r4c/immersive_moodles_twice.png). The Moodle Quarters way (ZeD moves the mod's panel to ZeD's place)
    does not fit: the mod's column wraps to the screen's height, draws bars beside each tile, has its own side and top
    options and its own hover text, and cannot lie in ZeD's row above the belt. So ZeD leaves the moodles to it:
    ModSupport/ImmersiveMoodles.lua tells ZeD_Moodles it draws them in whole (setStandIn, whole = true) while its HUD is
    on for the player, and ZeD then places nothing, draws no row and no note. With the mod's "Show Immersive HUD" off,
    or in ZeD's safe mode, ZeD works as without it. One addition: the mod starts its column below the game's clock,
    which ZeD's watch hides and draws in its place, so on the right its top offset is read as at least the corner
    watch's bottom + 10 (the player's own offset wins when lower). ZeD's Moodles place option (right, left, row) has no
    effect while the mod draws; the mod's own options decide. QA: with the mod on, one set of moodles (the mod's), no
    ZeD note on hover (the mod's own), the game's column nowhere, with ZeD's place at right, left and bottom; the corner
    watch on (a worn watch) with the mod on the right: the first moodle below the watch; the mod's Show Immersive HUD
    off (a new game or reload): ZeD's moodles and note as usual; safe mode on and off; the Compatibility thread's entry
    moves from "Compatible, with a note" to Supported once confirmed.
    **QA, Nov 2 2026: confirmed at e535b7b (2026-11-02_1227_mods_fullscreen4k.md, 47 / 47, at 4K with Immersive
    Moodles alone; new check zedqa_immersive_moodles.lua; pictures in qa/archive/Nov2_pl53).** console.txt: "[ImmersiveMoodles]
    main loaded", "[ZeD] ImmersiveMoodles: support loaded (wrapped true)". Four moodles up (god mode off for the test).
    At ZeD's place right, left and bottom: ZeD's layer hidden, M.rect nil, the game's column at -20000,-20000, the mod's
    HUD on, no ZeD note drawn, and after a hunger level change none either; one column on screen, the mod's, and no row
    above the belt at Bottom. The corner watch (worn, Corner) with the mod on the right: its top offset set 96, read 380,
    the watch's bottom + 10 = 380, and the picture shows the first tile under the watch. Safe mode on: the game's clock
    back, the mod's column under it, no ZeD note; off: as before. The mod's HUD off (simulated as its option does at
    load: hudOff true, its HUD panel removed): ZeD's moodles back on screen with ZeD's note ("Agitated") on a level change;
    HUD back on: ZeD steps aside again. Not covered: the option itself through a real reload (the state was set by the
    test), and a controller. Ready for the Compatibility thread to list Immersive Moodles as Supported (the director's
    call when the build ships).

54. **Hair and beard: a Kahlua error with round 5's nine mods on (QA's compat round 5, Nov 2 2026; the director, Nov 2:
    "Yes, hair and beard").** **[parked: a known issue for the beta (68), still being worked on.]** fixed (build, Nov 2), QA to confirm. On the Identity tab, Hair and beard's tool lookup
    (ZeD_HairBeard.lua tools(), from refresh() from layout(), every few frames) asked the game five times for the first
    razor, scissors, gel, spray and hairdo item through getFirstEvalRecurse, handing it a Lua test that the game calls
    back for every item. With the nine mods of round 5 on together the game's Lua engine threw "NullPointerException:
    Cannot assign field callFrame because a is null at ReturnValues.put" twice a run; the pcall caught it (so a tool was
    likely just not found), but -debug logged it as a Java exception. Each half of the set alone was clean, so no single
    mod is to blame. Fix: one walk over the inventory in Lua (the container's own items first, then each bag's, as the
    game's search goes), each item tested for all five tools; no call back from the game, and one pass instead of five.
    KB Q275. Other ZeD code still hands tests to the game's searches (object cards, the quick wheel, the trailer): none
    has shown the error; they move to the same walk if one does. QA: the nine mods of round 5 on, the nav map
    (zedqa_navmap.lua) over the Identity tab: no "callFrame" lines in console.txt; Hair and beard's tool lines read right
    with a razor in a bag, scissors in the main inventory, gel and spray, and none.
    **QA, Nov 2 2026: not fixed yet (fa00b9c; 2026-11-02_1234_mods_fullscreen4k.md, round 5's nine mods with compat_r5).**
    The callFrame error still comes twice over the Identity tab, now from vanilla: "Lua(Vanilla).hairMenu (ISCharacterScreen
    .lua:410) < harvest (ZeD_HairBeard.lua:255) < buildRows (341) < refresh (478) < layout (972)". ZeD's harvest calls
    vanilla's hairMenu under its pcall to gather the styles, and hairMenu asks containsEvalRecurse(predicateRazor /
    predicateScissors / predicateDoHairdo): the same Java-to-Lua predicate call the fix took out of tools(), one call site
    further on (beardMenu likely the same). The new tools() walk itself logs nothing. Tool lines not checked yet (waits
    for this). Same run: zedqa_moodles fails at "right: the column ... x -20000" and the rest, as expected now: Immersive
    Moodles is one of the nine and ZeD leaves it the moodles (item 53); the compat round 5 manifest should drop mood or
    run it without that mod.
    **QA, Nov 2 2026, second pass at d1dec5a (2026-11-02_1243 and _1248_mods_fullscreen4k.md, the nine mods on).** The
    Identity tab's reading is clean: no callFrame from harvest or tools(). The tool lines read right
    (zedqa_hairbeard_tools.lua): none finds nothing and allows nothing; a razor in a bag allows a shave and a beard trim,
    not a cut; scissors allow a cut and a shave; gel and spray allow the gel / spray styles. But a pick fails: the trim
    and the cut picked from the list throw the same error in vanilla's click path, "onTrimBeard (ISCharacterScreen.lua:539)
    < reason (ZeD_HairBeard.lua:459) < run (588)" and "onCutHair (557) < reason (436) < run (588)" (its
    getFirstEvalRecurse), so no action starts. With these nine mods the same error also hits vanilla code with no ZeD in
    the chain (ProfessionVehicles CheckSwap at a car spawn, corpseStorageCheck) and the QA test's own getAllEvalRecurse:
    one of the nine seems to break Java-to-Lua predicate calls for everyone (each half alone did not, Nov 2 overnight).
    For build: the click path through the same walker (find the tool in Lua and start the game's ISCutHair /
    ISTrimBeard with it). Worth a note in the Compatibility thread once the mod is found (a bisect of the nine with a
    one-line predicate probe).
    **QA, Nov 2 2026, third pass at 3e51a37: still open, and not the cheat menu.** Round 5 without RaxCheatMenu (now out of
    compat_r5_mods.txt, the director's rule) still logs the callFrame error 5 times (2026-11-02_1304_mods_fullscreen4k.md);
    without ImmersiveSleep the same (_1309). The trim picked from the list queues the razor's move out of the bag
    (ISInventoryTransferAction) and HB.run returns false: the error is at vanilla ISBaseTimedAction:begin line 88
    (self.character:StartAction, Java calling the action's Lua back) < ISTimedActionQueue.add < ZeD_PutBack.lua:152 add <
    transferIfNeeded / ZeD_HairBeard cutHair (145, 157). Every failing chain runs through ZeD's Put back wrapper of
    ISTimedActionQueue.add. A plain predicate search in a pcall passes with all nine (zedqa_pred_probe.lua, _1301), so the
    trigger is the action start through that wrapper with these mods on, not searches as such. The tool lines are right
    (16 / 17 in zedqa_hairbeard_tools.lua). The bisect stopped on the director's word; the remaining suspects are ZeD's
    wrapper with the other eight.
    **QA, Nov 2 2026, Build's begin probe (zedqa_begin_probe.lua, round 5 minus the cheat menu; parked until after t16).**
    With the eight mods the trim fails, with ZeD alone it starts (no callFrame line). At ISBaseTimedAction.begin the
    character is an IsoPlayer and self.action a LuaTimedActionNew, for the transfer, the equip and the trim alike; the
    transfer and equip start fine. Inside the trim's start every call is fine: setActionAnim(CharacterActionAnims.Shave),
    getStaticModel ("Base.Razor_Ground"), setOverrideHandModels; its isValid (true), its waitToStart (false) and its
    update (setMetabolicTarget) are fine too. Yet begin still throws the masked NPE after the trim's start returns, and
    the action then throws again every tick while it stays queued (268 lines in one run). So the bad call is in what
    StartAction / LuaTimedActionNew.start does after the Lua start (javap: setWaitForFinished, ActionManager
    .createNetTimedAction, the debug trace), or in a wrapper around it (ZeD_ActionBar wraps ISBaseTimedAction.create,
    perform and stop). None of the eight mods touches ISTrimBeard, CharacterActionAnims, waitToStart or isValid.
    **Second pass (build, Nov 2 2026), after QA's run at fa00b9c.** The tools walk was clean, but the same error came
    from the game's own hairMenu (ISCharacterScreen.lua:410), which ZeD runs to read the styles (harvest, from
    buildRows): per style it asks player:getInventory():containsEvalRecurse(predicateRazor / Scissors / DoHairdo), the
    same call back; beardMenu does too. Now the menu is read with a stand-in character: its getInventory answers
    containsEvalRecurse and getFirstEvalRecurse (and the non-recursive pair) from one Lua walk of the inventory and its
    bags, the calls the game's menus make on the character are written out (getHumanVisual, getVisual, isFemale,
    getPlayerNum, getJoypadBind), anything else a hair mod's menu asks is forwarded to the real character. After the
    read every option's target and params (and a picture mod's lists one level in) get the real character back, so a
    picked style runs on the player as before. The game's own onCutHair / onTrimBeard, run when a style is picked,
    still search the real inventory once, as the game does. QA: the same nine-mod run, no callFrame lines; the tool
    lines; cut, tie, untie and trim a beard from Hair and beard (the actions run on the player).
    **Third pass (build, Nov 2 2026), after QA's d1dec5a run (reading clean, tool lines right, picks failing).** QA
    found the call back failing for everyone with the nine on, ZeD or not (vanilla's car spawn CheckSwap and
    corpseStorageCheck too), so one of the nine breaks the game's Java-to-Lua predicate calls; each half alone is clean.
    The game's onCutHair / onTrimBeard find the tool that way and stop before the action is queued, so a pick did
    nothing. ZeD now does those same steps itself with the tool from its own walk (HB.cutHair: the hat off, the tool in
    hand by the game's rules, ISCutHair; HB.trimBeard: razor or scissors in hand, ISTrimBeard), but only in place of
    the game's own handlers (kept as the file loads): a hair mod that put its own handler in place keeps it. QA: the
    nine-mod run, cut, tie, untie, bald and a beard trim from Hair and beard each start their action with the right
    tool; then the bisect of the nine (QA's one-line predicate probe) to name the mod that breaks the call back, for the
    Compatibility thread (the director's call to post) and a note to its maker.
    **The director, Nov 2 2026: no compat or support work for cheat mods, item or vehicle spawners, or mods that break
    gameplay ("I don't want to waste my credits or resources on things that allow people to cheat ... Those people can
    use their own UI").** The bisect of the nine is cancelled: the set holds Rax's Cheat Menu 2.0 (RaxCheatMenu, whose
    server file fails to compile under -debug), the likely cause, and naming it serves only that mod. What was built
    stays (ZeD finds its own tools and starts its own cut and trim: sound for ZeD on its own). The last check of the
    pick path, if run, uses round 5 without RaxCheatMenu; with no failure there, 54 closes.
    **Build, Nov 2 2026, after QA's 1304 / 1309 runs (still failing without RaxCheatMenu or ImmersiveSleep; every
    failing chain through ZeD_PutBack's ISTimedActionQueue.add wrapper, at ISBaseTimedAction:begin line 88).** The NPE
    is Kahlua masking the real error: LuaJavaInvoker checks a call's self and arguments in prepareCall, and when that
    check fails its cleanup calls ReturnValues.put with a ReturnValues never set (put(null)), which throws "callFrame
    ... a is null". So a Java method is being called from Lua with the wrong self or a wrong argument type: at line 88,
    self.character:StartAction(self.action). QA's next probe prints the action's type, its character's and its
    action's types at begin, to name which (Hands-On Interactions wraps the transfer action's new and start; Immersive
    Sleep wraps the queue's add and adjustMaxTime).

55. **ZeD steps aside instead of a modular release (the director, Nov 2 2026).** **[confirmed (QA, Nov 2 2026; header corrected Nov 2).]** open, an idea for the design pass.
    A player asked for ZeD to be modular (to use only some of it). The director: "instead of doing a modular release,
    just allow our mod to step aside." What exists: every added feature can be switched off (item 18, the Additions
    presets), and ZeD steps aside by itself for one mod today (Immersive Moodles, item 53: while that mod draws the
    moodles, ZeD places none). What does not: ZeD's own screens (the main menu, the Character and World windows, the
    watch, belt, dashboard, moodle placing, the item card) cannot be handed back to the game. To settle with the
    director: whether stepping aside is the player's switch per screen in ZeD setup, automatic when another mod owns
    that screen (as for Immersive Moodles), or both; and which screens come first. One upload either way.
    The comment (LZV-R5, Workshop, Nov 2 2026): "Just one suggestion; Could be a modular selection? Maybe desable the hot
    bar but keep inventory and cars ui, etc." So the ask is per screen: the belt off (the game's hotbar back), the
    windows and the dashboard kept. Build's note: each ZeD screen already has its own hand-back step, the one safe mode
    runs (ZeD.Safe.register: the belt gives back the game's hotbar, the watch the game's clock, the moodles the game's
    column, and so on); a per-screen switch in ZeD setup would run that one screen's step and leave the rest, so the
    work is mostly the switches and their words, not new hand-backs. Reply to LZV-R5 waits until it ships.
    **The director, Nov 2 2026: seven switches ("I'm okay with that"); built (build, Nov 2), QA to confirm, the last
    code for t16.** ZeD setup has a ZeD screens group: Inventory windows, Belt, Watch, Dashboard, Moodle placing, Quick
    wheels, Character info, each a checkbox, On (ZeD's) by default; Off hands that one screen back to the game's own,
    the step safe mode takes for all of them. SafeMode.lua: ZeD.Safe.on(name) is true while safe mode holds or that
    screen is switched off; each hook follows its own switch (sync keeps a per-screen state); every check in the
    seven screens' files names its screen (35 lines). Not additions: the presets leave them alone. QA: each switch off
    and on in game (the game's own screen comes back at once and ZeD's goes; on again, ZeD's returns), two off
    together, safe mode on with switches mixed (everything the game's), and a restart keeps the picks. If Inventory
    windows off shows a fault that is not a quick fix, its row is hidden for t16 rather than fixed late.
    **Moved under Safe mode (the director, Nov 2 2026: "put the switches in the safe mode area. So they read more like,
    yeah, you can turn it off. But why would you want to? In safety").** The seven rows sit in Troubleshooting right
    under Safe mode and read as it does: ticked is the game's own, unticked (the default) is ZeD's. Names "Safe mode:
    belt" and so on, each with a line under it ("The game's own hotbar"). The ZeD screens group is gone.
    **QA, Nov 2 2026: confirmed at d751c3f (2026-11-02_pl55_screens_4k.md, 77 / 79, zedqa_screens.lua; pictures
    qa/archive/Nov2_t16/screens_six.png).** Each of the seven switches ticked: ZeD.Safe.on(name) true and every other screen stays
    ZeD's; the belt gives the game's hotbar back (the picture shows it), the watch the game's clock (y 10, visible), the
    moodles the game's column, the windows close; unticked, each is ZeD's again (the clock parked at y -4000). The console
    says "[ZeD] Screens: <name> handed back to the game" and "is ZeD's again" for all seven. Belt and watch ticked together:
    both the game's. Safe mode on over them: every screen the game's; off again: belt and watch stay the game's (their
    ticks), moodles and windows ZeD's. The ticks are saved: ModOptions.ini holds screenBelt|2 and screenWatch|2. The two
    FAILs are the test's (it reopened ZeD's windows in the same tick the switch went off; the switch is read every half
    second; the later step reopened them fine). Not covered: the game's own inventory windows opened by the I key with
    the windows switch on, the dashboard (no car in the test), the quick wheels and the game's character info by their
    keys; those three were checked by their switch state and console lines only.
56. **A simple belt (the director, Nov 2 2026: "I want to add simple belt for T16").** **[confirmed (QA, Nov 2 2026; header corrected Nov 2).]** Behind the Workshop ask to turn the belt
    off (item 55): give it a simple form, as ZeD already pairs a full and a simple version (the progress bar; the context
    menu strip and the classic menu): one for immersion, one plain. Options and a mockup for the director first.
    **Built (build, Nov 2 2026), QA to confirm.** ZeD setup's HUD group has "Belt: Full | Simple" beside the action
    bar (Full the default). Simple keeps everything the belt does (both hands, every slot in key order, the ammo tab,
    the wrist watch, the Messages note, drag in and out, keys, the controller) and drops the decoration: no leather
    strap, no buckle, the slots evenly spaced (6 units) after the hands, the belt centred on its own width. A change
    applies at once (the layout cache follows the option). QA: Full and Simple at 4K and on the Deck, with 0, 1, 4 and
    the most slots; a gun (the ammo tab), a worn watch on each wrist, the Messages note; drag an item onto a slot and
    off; the number keys; the controller's belt focus; moodles placed at the bottom sit above it.
    **QA, Nov 2 2026: confirmed at 361d0b6 (2026-11-02_pl56_belt_4k.md and _deck.md, 16 / 17 each,
    zedqa_simple_belt.lua; pictures qa/archive/Nov2_t16/simple_belt_rows.png).** Full: strap and buckle. Simple at 4K and on the
    Deck: no strap, buckle, runs or closure; both hands; all 3 slots in key order, 6 units apart, the belt centred
    (4K 1692 + 457 wide, Deck 542 + 197); a pistol in hand shows the ammo tab; a watch on the left and on the right
    wrist shows on the belt; a knife goes onto free slot 2 and off again (B.attach / B.detach, the drag's calls) and slot
    2's key puts it in hand; moodles at Bottom sit above the belt (4K bottom 2013 < 2034; Deck 737 < 746). The one FAIL is
    the test's: the Messages lamp shows only with messages, Full has none either. Not covered: slot counts other than 3
    (0, 1, 4, the most), a real mouse drag, the controller's belt focus under Simple.

## Beta (0.3.0-beta1)

The director, Nov 2 2026 (docs/specs/BETA_DECISIONS.md, from the Cowork session; the questions in
docs/handoffs/HANDOFF_cowork_beta_20261102.md): the build after t16 is the beta. Every item below is chosen. Each carries its
own check, and nothing is done until QA confirms it in the game. QA works in two passes: after each build, only what
that build changed plus the five-minute release check; before a release, the full checklist (rewritten for the beta,
item 74, reviewed by the director first). Regular testing runs at one resolution (4K); Deck and 720p only where an
item says so.

57. **The beta's name, page and thumbnail (the director, Nov 2 2026).** chosen.
    - The version is 0.3.0-beta1 (1.0 is the release). It is the same Workshop item (3824968485), retitled from
      "ZeD-GUI [TEST BUILD]" to "ZeD-GUI [BETA]", and it stays public.
    - A Known issues section sits front and centre on the beta's description. The Hair and beard error with the
      eight-mod set is listed if it is still unsolved (item 68).
    - Thumbnail: find why ours shows a margin and make it fill the whole square. The beta swaps the test build's red
      border and strip for yellow. Red is a test build, yellow the beta, green the release.
    - **Check (QA, at staging):** the staged mod.info reads 0.3.0-beta1; workshop.txt's title reads "ZeD-GUI
      [BETA]"; the description opens with Known issues; preview.png is 256 x 256 with no margin and yellow trim.
    **Thumbnail (build, Nov 2 2026 evening).**
    - The director: "change our preview thumbnail to the bitchin' ZNIX programs book with the ZGUI ... this would
      never be featured in a magazine like that", and "make this clear that this is a total UI rebuild ... a
      complete UI for Project Zomboid". The old monitor picture "doesn't look like our interface at all".
    - Built (759bb9e, 0cdfcbb): ZeDUI/workshop/gallery/thumb_px.py cuts the title card's book (cover_px.py) to 256 x
      256 at 1x. The cover's bullets now read THE WHOLE UI REBUILT | FOR PROJECT ZOMBOID B42 | PAD AND MOUSE. Its
      monitor shows ZeD as it plays: two dark windows with accent tab strips over grey ground, the character and the
      belt with the green ring. The title card (znix_01_cover.png) is redrawn with the same changes; the gallery's
      00_cover on Steam is still the old one until QA replaces it.
    - Two marks to choose from (thumb_compare_beta.png): a yellow BETA strip across the foot (thumb_256_beta.png),
      or a yellow BETA price sticker on the cover (thumb_256_beta_sticker.png). **The director, Nov 2 2026: "the yellow
      strip at the bottom."** thumb_256_beta.png is now ZeDUI/tools/release/preview.png (staging's default), and QA
      replaces the gallery's 00_cover on Steam with the redrawn title card.
    - The margin, found: Steam's item page asks for the preview at 268 x 268 in letterbox mode with a black fill
      (`?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000`), and the game's uploader insists on exactly
      256 x 256 ("The preview.png file must be exactly 256x256 pixels in size"), so Steam pads every side with 6 px of
      black. It can't be filled from the game. The book's dark desk edges blend with that black; the old cream
      magazine made it stand out.
58. **UI scale: the 0.5 step is still offered (the director, Nov 2: keep the 0.75 cap on the Deck and at 720p; 0.5 was
    dropped because it did not look right; bring it back after the beta).** chosen.
    - Build found it is not gone: ZeD setup's scale list still holds 0.5x (Settings.lua scaleKeys).
    - Fix: 0.5x is not offered in the beta (the slider, the Mods page's drop-down and the controller's ZeD wheel).
      A saved 0.5 draws at 0.75 and reads "0.5x (0.75x here)", as a capped step does. The saved position is kept,
      because combos save by position.
    - **Check (QA, 4K):** no 0.5 step can be picked by mouse or pad; a saved 0.5 draws 0.75 and reads as said.
    **QA, Nov 2 2026, at 4K (zedqa_beta_ig.lua in game, zedqa_menu_beta.lua at the main menu): confirmed but one
    readout.** ZeD setup's slider: Left presses reach Auto; A on Auto steps to 0.75x; Left from 0.75x goes back to Auto
    past 0.5x; Right from Auto lands on 0.75x. The 0.5x step stays in the list (saves keep their place). In game the
    scale wheel reads Auto, 0.75x, 1x, 1.25x, 1.5x, 1.75x, 2x (no 0.5x); with 0.5 saved it draws at 0.75 and the wheel
    shows 0.5x dimmed, "Not offered in this build: it draws at 0.75x.", no pick. **The readout:** at the main menu a
    saved 0.5 reads "0.5x (1x here)", not "0.5x (0.75x here)" (shot mbt_scale_05_saved): scaleReadout prints the main
    menu's own root (1 there), while the game draws it at 0.75. For build: say 0.75x for a retired step, or the game's
    scale.
    **QA, Nov 2 2026, after Build's readout fix: confirmed (2026-11-02_beta_menu_4k_b.md, 11 / 11).** With 0.5 saved
    the main menu row reads "0.5x (0.75x here)".
59. **Every dimmed row loses its hover highlight (the director, Nov 2: "Yes").** chosen. Item 20's rule now covers
    the game's own greyed-out settings too: the ones that do nothing while ZeD runs.
    - **Check (QA, 4K, real mouse):** a greyed game setting and the dimmed Restock row light up for neither the
      mouse nor the pad; the help line still says why.
    **QA, Nov 2 2026: confirmed at 4K for the game's do-nothing settings (zedqa_menu_beta.lua).** The pointer held over
    "Cycle Container Key" (Controls, a game setting that does nothing with ZeD) gives it no hover wash (MM.rowLook's hot
    argument false for that row) and it is not a controller stop; a live row on the same page under the pointer does
    take the wash (the check sees one). Picture mbt_dim_moot_hover for the help line. Not covered yet: the Restock row
    with Loadouts off and a greyed Sandbox option.
60. **Simple versions of every immersive surface (the director, Nov 2: "the beta release is gonna have our vision
    and then a more simplified vision").** chosen.
    - The machines' simple cards from item 17 are in the beta: radios, TVs, walkie-talkies, ham sets, ovens,
      microwaves, the fryer, the grill and generators.
    - Build also lists every other place ZeD shows something in a more immersive or graphic way and proposes a
      simple version for each.
    - Build brings the layout rules and that list to the director before building anything.
    - **Check (QA, after it is built):** the ZeD setup switch flips every listed surface between its two forms, live;
      each simple card does everything its face does, with the mouse and the pad.
    **Proposal and answers (docs/plans/SIMPLE_VERSIONS_PROPOSAL.md; the director, Nov 2 2026: "the rules are right.
    Watch and dashboard go into the beta. Fictional pieces stay simple"):** the six rules stand (nothing lost, ZeD's
    plain parts, one device-card layout, the pad in the face's order, one "Look" group in ZeD setup with a Full /
    Simple row per family and Vanilla Access picking Simple, Full the default). In the beta: group A, the devices
    (radios and TVs, walkies and ham sets, the car radio, ovens / microwaves / fryer, the grill, generators, washers
    and dryers), and group B, the watch and the dashboard with the taxi meter and the siren. Group C keeps its plain
    way in; group D (ID card, notebook paper, balloons, the main menu desk, sleep clock, fishing reel, death alert,
    seat chooser, map pins, the Messages note) stays as it is, with no simple version (build's reading of "stay
    simple"). First: the radio's simple card as a picture for the director, then the rest in that layout.
    **QA, Nov 2 2026: ZeD setup's "Full or simple" group confirmed (zedqa_menu_forms.lua, main menu, 10 / 10).** Right
    after Look; Belt, Action bar, Context menu, Equip view, Devices, Watch, Dashboard in that order; no other group
    shows them; Vanilla Access sets Devices, Watch and Dashboard to Simple, Vanilla Plus to Full; each of the three
    picked by hand makes the Preset read Custom; Discard put everything back.
    **QA, Nov 2 2026: the Simple watch at 4K (zedqa_simple_watch.lua, 20 / 23; pictures for the director in
    qa/archive/Nov2_beta/pl60_simple_watch.png).** Worn, the corner box: the time large with seconds, "WE 21", 79°F, Speed x1,
    Alarm off; Pause / Start pauses and runs the game, Speed steps x2 and x3, Alarm sets and clears the alarm (Alarm
    15:00 with the dot). No watch: Game speed with Pause, x1, x2, x3, each setting the speed. On the belt: the plain
    time box, and the plain watch pops above it. Full brings the watch's art back at once. + and - follow the watch's
    rules (+ with the alarm off arms it at 0:00; - from 0 turns it off). **Three faults, sent to build:** (1) in set
    mode "On/off" leaves set mode instead of switching the alarm (it sends the watch's alarm press, the back press in
    set mode); (2) the buttons' words run past their buttons at 4K ("Pause", "Speed", "Alarm", "On/off"); (3) the set
    mode's help line "Set the alarm hour with ..." runs out of the box (not wrapped).
    **QA, Nov 2 2026, after cb8447cc: the three watch faults are fixed (23 / 23 at 4K and 23 / 23 on the Deck with
    Large text; 2026-11-02_pl60_watch_4k_b.md, _800L.md; the director's picture retaken,
    qa/archive/Nov2_beta/pl60_simple_watch.png).** Every button holds its word (4K box 476 x 212, set mode 518 x 176; Deck
    Large 234 x 103); the set mode's help line wraps in F2 inside the box; On/off ("alarmtoggle") switches the alarm
    and stays in set mode, Done leaves. Note for build: on the Deck the corner box sits over the World window's
    top-right corner (its tab strip's edge).
    **QA, Nov 2 2026: the plain device cards at 4K (zedqa_plain_cards.lua through pl60_plain_run.ps1, 35 / 36; pictures
    for the director in qa/archive/Nov2_beta/pl60_plain_cards.png).** Black radio, red radio, Tactical walkie in the hand: the
    plain card drawn; power switch; the volume stepper's right half raises, left half lowers; the wheel over the
    frequency turns it and a fast spin goes further (2400 against 200 a notch; once in five runs it did not speed up);
    a held preset (right-click) stores and the key recalls; battery and headphones keys queue the game's action; the
    disc key opens the disc list; Play plays a disc put in; MEM pressed stores and held opens the naming box; the
    controller starts on power and the footer is the card's last stop; Devices back to Full gives the face back at
    once. Notes: at 4K the Character window's opening height is shorter than a radio's card (789 in a 585 view), so
    the card scrolls; the test grows the window. The TV and the army ham pictures come from the radio and two-way
    tests run on Simple (the TV is off the air on the QA save's day 6: snow, no programme; the ham was off). **For
    build:** (1) Stop: a second Play press leaves the disc playing; the game's own StopPlayMedia() also leaves
    isPlayingMedia() true straight after, so it is the shared play/stop or the game, not the plain card (no face
    test ever checked Stop); (2) the black radio on NNR Radio reads "Signal None"; (3) the red radio's disc time reads
    0:00 while it plays. Still to do: the Deck pass with Large text, and a TV with a programme on (needs an earlier
    day).
    **QA, Nov 2 2026, after build's radio fixes: all 36 pass at 4K (2026-11-02_pl60_plain_4k_b.md).** Stop stops the
    disc (read through ZeD's own O.playingNow; the game's isPlayingMedia lags by design); the black radio on 98.0 NNR
    reads "Signal Poor", not None; the disc's time runs (0:06 five seconds in). Not yet checked: Stop while the game is
    paused. The fast wheel spin missed its speed-up in two of about seven runs (black radio): intermittent, sent to
    build.
    **QA, Nov 2 2026, after the speed-up fix: 36 / 36 (2026-11-02_recheck_60_77_4k_b.md).** Twelve quick notches after a
    pause give 6400 against 200 a notch: the speed-up starts at the 8th notch (7 at 1x, 5 at 5x), one notch sooner than
    build described; told build.
    **QA, Nov 2 2026: the Simple dashboard on every design at 4K (dash19 with Dashboard on Simple,
    2026-11-02_pl60_dash_4k.md; pictures for the director qa/archive/Nov2_beta/pl60_simple_dash.png).** All 19 cars draw the
    plain strip (1400 x 430 to 483 at 4K, bottom centre): Speed, RPM, Fuel, Volts, Temperature, Oil, Gear, Odometer,
    Clock, Climate; the lamps as status dots; Car, Climate and Radio rows of buttons with the radio's presets; the taxi
    adds Fare, Extras and Meter; the police car Lightbar and Siren. The police car and the Primani did not start in
    this run (the strip read Ignition: Start); the clicks, the meter, the siren card, the pad, a passenger and safe
    mode are still to be checked.
    **QA, Nov 2 2026: the plain appliance, machine-plate and laundry cards (Devices on Simple; zedqa_appliances 22 / 22,
    zedqa_plates_336 and zedqa_laundry run on Simple, 2026-11-02_pl60_devices2_4k.md).** The plain oven card: the
    temperature and timer readouts, the number keys, Bake, Timer, Broil; the plain washer: its cycle (Wash), power,
    "On the water pipes", Inside with Open; no game errors in the run. The face-only checks (face size, zoom, the
    water meter's art) fail there by design. Item 76: seated in a pickup, every World strip button (both seats, the
    glove box, the ground) has the game's own picture; none needed the box (2026-11-02_pl76_strips_4k.md).
    **QA, Nov 2 2026: the car radio on Simple at 4K (pl60_carradio.txt, 4 / 4 PASS; 2026-11-02_pl60_carradio_4k.md).**
    The plain ValuTech card over the dash: frequency and station name, Power, Volume, Seek, Mute, the six presets with
    their names, Frequency, Signal; power, a stored preset (STORE 4) and the ValuTech, makeshift, ham and army sets all
    fit and report. The old CD step made its own disc, which the radio does not count ("No CDs on you"), so insert,
    play and eject did not run here; the plain cards test already plays and stops the character's own CD. No game
    errors from ZeD (the two "Vehicles.Init.Radio" lines are the game's own).
61. **The Vehicle tab on small screens (the director, Nov 2: undecided, must be decided before the beta).** open.
    - Beside the car figure, Type, Distance and Key show only their labels at small sizes.
    - **QA first:** one small-screen screenshot of the Vehicle tab with the hood open (1280x720 or the Deck,
      Normal text). The director picks the fix from it.
    **QA, Nov 2 2026 (6515c6e, qa/archive/Nov2_beta/pl61_*):** at 720 Normal, 720 Large and the Deck Large, UI scale Auto,
    Type, Distance and Key show their values ("Standard", "3 tiles", "On you"); the labels-only look came at UI scale
    2.0, item 35's stress setting. The tight spot at 720 is the parts list under the figure: with the hood open only
    "Under Hood (4)" shows above Close Hood. QA told the director that "leave it" now matches what a player sees.
    - **QA, Nov 2 2026: the pictures are in (zedqa_vehicle_small.lua; qa/archive/Nov2_beta/pl61_*; reports
      2026-11-02_pl61_vehicle_720.md, _720L.md, _800L.md).** At 1280x720 Normal, 1280x720 Large and the Deck (1280x800)
      Large, UI scale Auto, both windows open: before the hood is opened, Type, Distance and Key each show their value
      ("Standard", "3 tiles", "On you"); with the hood open the summary (Engine, Quality, Loudness, Weight, Fuel,
      Battery, Key) shows every value. The labels-only look was seen Oct 31 at UI scale 2.0 (item 35's stress
      setting) and at the Deck before the scale cap; at today's real settings it does not happen. What is tight at
      720 is the parts list under the figure: with the hood open one heading row ("Under Hood (4)") shows before the
      Close Hood button, the rest by scrolling. For the director: (c) "leave it" now matches what a player sees.
62. **Machine translations for every language the game supports (the director, Nov 2).** chosen; replaces item 51.
    - AI drafts ship inside the mod. Each is labelled as a machine translation in the language list.
    - Order: Turkish, Simplified Chinese and Brazilian Portuguese first. Russian, Ukrainian, Latin American
      Spanish, Chinese and Japanese are the next big audiences, then the rest.
    - A plain post says these are machine translations and that ZeD wants players to check and correct them before
      the release. One discussion thread collects corrections. Steam comments cap near 8,000 characters, so
      translations never go in comments.
    - **Check (QA, 4K):** each drafted language loads with no missing keys (the i18n guard); its label shows in the
      language list; the Turkish capitals Ş, Ğ and İ and the Chinese faces draw whole on ZeD's text and pixel faces.
    **Built (build, Nov 2 2026):** ZeDUI/tools/i18n/mt.py splits the English with each phrase's context and length,
    checks a draft (placeholders, %%, markup) and merges it. Turkish (TR), Simplified Chinese (CN) and Brazilian
    Portuguese (PTBR) drafts are in Translate/<code>/ (UI, Sandbox, ItemName; every key, 0 check errors; commits
    2d1bc44, 10150ed, 7dd3d7f). ZeD.MACHINE_LANGS in shared/ZeD/Tr.lua marks them, and ZeD's Options language list
    draws "(machine translation, ZeD-GUI)" after their names (the option text stays the game's). Still to do: the other
    24 languages, the plain post asking players to check them, and the corrections thread. Unsure choices the drafts
    flagged (for a checker): Loadouts / Outfits / Restock / Unpack have no game word in any of the three; TR "Etüt" for
    Survey, PTBR "Kits" / "Trajes", CN 配装 / 穿搭.
    **QA, Nov 2 2026: TR, CN and PTBR in game at 4K (lang_run.ps1; 2026-11-02_pl62_lang_TR.md, _CN.md, _PTBR.md; 5 / 5
    each).** The game in each language: the list names it a ZeD machine draft (Türkçe and the others); every ZeD key
    has text (0 with none, 4255 to 4256 keys); the windows, Health, Skills, the belt and the watch draw in the
    language (Turkish İ, ı, Ş, Ç in the windows; the watch's weekday "ÇA" in its LCD letters). These runs started just
    before f37b8b01 (the 141 newest phrases), so 71 to 78 newest keys still read English here; the full pass reruns
    all three on the frozen code. Note: the hand circles' Turkish labels are cut short ("İkincil Do.", "Birincil
    Dona."). Offline: every %1..%4 placeholder matches English in all three.
    **QA, Nov 2 2026: the gallery for 0.3.0-beta1, in Screenshots/gallery_t14 (the old copies in _before_beta).** At 4K:
    the laundry trio indoors (59), the messages toast and radio window (34), the two-way radio pages (37, retaken with
    the debug console hidden: gallery_console_off.lua), and eight new pages: gb_cmap_window, gb_bugreport_wheel,
    gb_bugreport_dialog, gb_simple_watch, gb_simple_belt, gb_plain_radio, gb_forms_setup, gb_plain_dash
    (2026-11-02_gallery_beta_4k.md, _gallery_tw_retake_4k.md). The main menu (gallery_menus_run.ps1, every script
    DONE, everything put back): desk_02, desk_04, desk_05 (46/47) and mm4_01, mm4_02 (48). The one FAIL in the
    first run was the test's own tidy-up asking a washer for radio data (guarded now); its pictures were fine.
    **QA, Nov 3 2026: the first new drafts in game at 4K (lang_run.ps1, now taking every game language; reports
    2026-11-03_pl62_lang_RU/UA/JP/KO/CH/PT/ES.md): all 5 PASS in each.** Each is named a ZeD machine draft in the list,
    every key has text, 6 to 20 lines the same as English (units, button letters, the mod's name). Russian and Ukrainian
    draw in the pixel capitals (action bar ЕДА / ЯБЛОКО, ХАРЧУВАННЯ / ЯБЛУКО; Є, І, Ї and Ґ did not come up in the
    pictures); Korean, Japanese and Traditional Chinese windows draw whole in the game's fonts, and the action bar falls
    back to the regular face as planned. The first Japanese run showed one key with no text: it ran while the Fable
    proofread was being written into the shared checkout; rerun on 9f475791, 5 / 5 (zedqa_lang.lua now names any key
    with no text). RU and UA ran before their proofreads (28a3e944, 83e668e0), which change words only.
    Found: UI_ZeD_MainMenu_Clock12 (021f78b9) is in EN, CN, CH, JP and KO only, so 14 languages show the English time
    pattern; the Spain Spanish off-hand label is cut to "Secundari." (as PTBR's was before "Secund."); in the 5-row
    pixel face Ã reads as a plain A (the tilde merges with the apex: PT and PTBR "MAÇA" for Maçã).
    Build answered (1c3d7e04): the 12-hour clock stays in every language (the 1993 desk's way; a native checker can ask
    for 24-hour); the hand circles now read "Secund." (ES, AR, ES_MX, ES_CL, CA) and "Princip." / "Second." (FR, IT).
    **QA, Nov 3 2026: TH, FR, DE, IT, CA, ES_MX, AR, ES_CL in game at 4K, all 5 PASS each**
    (2026-11-03_pl62_lang_*.md; every key has text, 12 to 28 the same as English). Thai draws in the windows and falls
    back to the regular face on the action bar. Offline, every capital the action-bar lines use in every Latin and
    Cyrillic language (É, Ä, Ö, Ü, Ç, Ñ, À, Ì, l·l, the Cyrillic set) is in both pixel sizes; CJK and Thai have none
    by design (they fall back). Found: the German off-hand circle reads "Nebenhan." (Nebenhand, 9 letters, does not fit
    the smaller off-hand circle; the 9-letter limit holds for the main hand only).
    - **Open (low priority, off the beta path): accented pixel capitals read poorly.** In the 5-row face Ã and Â read as
      a plain A (PT and PTBR "MAÇA" for Maçã, RO "MANCAT" for Mâncat); in the 7-row face the base letter shrinks to make
      room for the accent, so Ö, Í and É read as small letters beside full capitals (FI "SYöMINEN", CS "JEDENí", HU
      "EVéS"). A tweak to ZeDUI/tools/i18n/pixel_glyphs_gen.py; likely Õ, Ñ and the rest of the accented set too.
      **Built (build, Nov 3 2026, 0e8cfcaf): a "57t" face with tall accented capitals for the action bar's first line
      only** (the mark in two rows above the line, a cedilla one row below). **QA, Nov 3 2026: FI, CS, HU, RO rerun at
      4K, 5 / 5 each: SYÖMINEN, JEDENÍ, EVÉS, MÂNCAT read as full capitals, the marks inside the box**
      (2026-11-03_pl62_lang_*_accents.md; picture ZeDUI/qa/review_20261103/action_bar_accents.png). Still open: the
      second line (the item name: RO MĂR, PT MAÇÃ) has one free row, so tall marks there need the action bar 2 px
      taller in every language: the director's call.
      **The director, Nov 3 2026: "Yes, 2 px taller."** Build makes the action bar 2 px taller in every language so the
      second line takes the tall accented capitals too; QA checks it at 4K (PT, RO, DE, EN, and the Simple bar).
      **Built (build, d6f38241): line 2 in "35t", the bar 2 units lower, the box 24 + bar, the bubble 36.** **QA, Nov 3
      2026: PT, RO, DE and EN at 4K** (2026-11-03_pl62_lang_*_taller.md; picture review_20261103/action_bar_taller.png;
      EN's language checks fail by design, it is not a draft). PT reads MAÇÃ whole; DE APFEL and EN APPLE sit with the
      extra row between the lines; the bar clears line 2. Found: RO MĂR reads as MÄR, because the small face's breve is
      the same "101" row as the umlaut dots, which to a Romanian reader is the wrong letter. Not seen: the thought bubble
      (the run uses the plain box) and the Simple bar (its own size, unchanged).
      **QA, Nov 3 2026: the breve fix (a072865c) and the thought bubble at 4K, RO, PT, DE, EN**
      (2026-11-03_pl62_lang_*_bubble.md; picture review_20261103/action_bar_bubble.png). (Correction: the earlier runs did
      show the thought bubble, Verbose being the default; the crops cut its tail.) The bubble is the same in all four: its
      height, the trail of dots and its gap to the head; line 1's marks (MÂNCAT) stay clear of its top edge. RO MĂR now
      reads as Ă (a U one row up, a clear row under line 1). Note: PT Ã's tilde in the small tall face is a flat bar, so
      it reads closer to a macron (Ā) than a wave; readable in context.
      Build (db3512d9): a 3-wide two-row tilde draws as a slash (Ã would read as Á), so Ã and Õ keep the one-row bar;
      Ñ, 4 wide, gets a two-row wave. Not run (no Spanish word with Ñ in the check); closed.
    **Built (build, Nov 3 2026): the other 24 languages drafted (Sonnet), JP/KO/TH/CH/RU/UA proofread (Fable), all in
    ZeD.MACHINE_LANGS; notes for checkers in ZeDUI/i18n/mt_notes/; the main-menu clock is a translatable pattern
    (UI_ZeD_MainMenu_Clock12).** Not in the uploaded beta; ships with the next build. Hand-circle labels fit (off hand 8
    letters: Nebenh., Secund., Másodl.; 958488c3).
    **QA, Nov 3 2026: NL, DA, NO, ID, PL, FI, CS, RO, HU in game at 4K, all 5 PASS each; DE rerun on 958488c3 reads
    "Nebenh."** (2026-11-03_pl62_lang_*.md). All 27 of the game's languages now pass the language check. Norwegian's
    setup script was logged DONE but the runner read the line torn (a TIMEOUT for the prelude only; its checks ran).
    Danish and Norwegian "Sekundær" fills the off-hand circle edge to edge (fits, tight). The Translations thread's 24
    "translate" replies wait for the next upload before they become "check the machine draft" (the beta has none).
63. **Ente's Auto Sorter (the director, Nov 2).** chosen. A note in the Compatibility thread: its button bar sits over
    ZeD's belt, so drag its bar aside. It is not popular enough to special-case. QA adds the line at the next thread
    edit.
64. **This Is Your Life (the director, Nov 2).** open. Build takes a short read of what it adds: hometown postcards,
    Origin Traits and scripted starts, all switchable in sandbox. It reports to the director, who decides.
    **Read (build, Nov 2 2026): ZeDUI/workshop/TIYL_read_20261102.md.** Workshop 3773911887. It overrides the game's
    creator screens in place (TIYLFlow.lua: SandboxOptionsScreen, CharacterCreationProfession, CharacterCreationMain and
    MapSpawnSelect setVisible at class level; TIYLAppearanceSkin replaces CharacterCreationMain's prerender) and adds
    its own postcard and map-board panels, so under ZeD's Spawn, Occupation and Looks windows nothing of it shows and no
    origin is set. Support option (a), about a day: a ZeD hometown picker over `TIYL.Origins` that calls
    `TIYL.Flow.completeOrigin(id)` after Spawn; the in-game parts (origin trait, map reveal, journal, milestones) then
    run as written. The poster stories hand out a weapon, food and in two a repaired car (`addVehicle` + "repair"),
    against the standing rules unless the director says otherwise. Untested: whether ZeD's Spawn window lists its
    hidden "This Is Your Life" region. Waiting: the director's pick, (a) support the hometowns or (b) leave it.
    **Chosen (the director, Nov 2 2026): support it, scripted starts and poster stories included.** "Adding a car at
    the start, that's not really cheating. That's just a backstory or a scenario. What I think of as cheating is like
    spawners." Build: a ZeD hometown picker (the 11 towns with their origin trait and blurb) that hands the pick to the
    mod (`TIYL.Flow.completeOrigin`), the partner start passed through, and the poster stories as a second picker
    (`TIYL.Flow.completePosterStory`); ZeD keeps its own Occupation, Traits and Looks pages. Build brings the pickers'
    layout to the director first. **Check (QA, 4K, the mod on):** a new game through ZeD's creator with a hometown
    spawns there with its origin trait and map reveal; a poster story starts as the mod writes it; with the mod off,
    nothing of it shows; multiplayer is a separate pass.
    **Built (build, Nov 2 2026, feda927; the director: "go with your plan"):** ModSupport/ThisIsYourLife.lua. The mod's
    hidden town "This Is Your Life" stays in ZeD's Spawn list, described; its Next opens the Hometown page
    (ZeD_MMHometown, ZeD's Spawn window subclassed: the 11 hometowns with the origin trait under each blurb, Knox Country
    as Random, then the five poster stories, single player only; the map frames each town's houses and plays its town
    video). Next selects the mod's region and calls TIYL.Flow.completeOrigin / completePosterStory, then vanilla's
    clickNext. A hometown carries on through ZeD's Sandbox, Occupation, Traits and Looks; as Occupation comes up the pick
    is handed over again (the partner start ticked in Sandbox counts). A story lets the mod's own occupation and looks
    screens run (MM.redirectPass, a new hook in MM.redirect): they fill in the name, job and look and press Play. Back
    drops the pick (TIYL.Flow.abandon); any other town drops it too. Not tried in the game yet.
65. **ZeD's version in About (the director, Nov 2: "Yes").** chosen. The desk's About adds a ZeD-GUI row beside the
    game's build, read from ZeD's own mod.info.
    - **Check (QA, 4K):** About reads ZeD-GUI with the staged version and Game with the game's build.
    **QA, Nov 2 2026: confirmed at 4K (zedqa_menu_beta.lua, main menu, ZeD only).** The ZeD menu's About lists
    "ZeD-GUI 0.1.1242300k" above "Game Build 42.22.0" (shot mbt_about); MM.zedVersion equals mod.info's modversion. The
    staged copy's stamped version is checked at the next staging.
66. **Bug reports in two presses (the director, Nov 2).** chosen.
    - Error capture exists: Messages files each mod's errors (12 kept per mod) and has "Copy for a bug report" per
      source.
    - Still to build:
      - Every error gets its own copy.
      - Every copied report starts with ZeD's version, the game's build and the mod list, ready to paste into a
        Workshop thread or a paste site.
      - A Bug report entry in the ZeD menu, where the style options are, copies every error with that header. It
        then says the errors are copied and can be pasted into a Workshop thread or sent to Hermit. No digging
        through files or the console.
    - **Check (QA, 4K):** force an error from a test mod; Messages files it; each copy and the menu's Bug report put
      the expected text on the clipboard (read back); with no errors, Bug report says so.
    **QA, Nov 2 2026 (zedqa_beta_ig.lua, 4K):** confirmed but one fault: the older error's Copy carried the newer
    error's separator and "attempted index" head. Cause: the game writes each error as a separator with its message,
    then the Lua stack, then the exception entry, and readErrors added every non-exception entry to the last error.
    **fixed (build, Nov 2 2026):** a separator entry opens the next error; its head and stack wait and go in front of
    that error's exception. QA to re-check with two errors in a row. (The "at game start" tag on both cards is by
    design: it marks anything in the first real minute after the game loads.)
    **QA, Nov 2 2026, at 4K (zedqa_beta_ig.lua, 31 / 32): confirmed but one fault.** No errors: Bug report counts 0,
    says so, and copies the header plus "No errors were caught this session.". Two errors: the summary card's button is
    "Copy all for a bug report"; the error cards read "1 of 2 kept" then "2 of 2 kept", newest first, each with its own
    Copy; every copy starts "ZeD-GUI 0.1.1242300k | Project Zomboid 42.22.0 ...", "Mods on (1):", a mod a line; Copy
    all holds both; the wheel's Bug report counts 2 and says "2 errors are copied, with ZeD-GUI's version and your mod
    list. Paste them into a thread on ZeD-GUI's Workshop page, or send them to Hermit." (shot zqa_big_bugreport_two);
    the ZeD wheel has Bug report (bullhorn) right after Messages. **The fault:** the older error's Copy also carries the
    newer error's head (its separator lines and "attempted index: qaBetaErrorTwo of non-table: null"): M.readErrors adds
    every entry without "Exception" to the last error, and the game writes the next error's head before its exception
    entry. The newest card's copy is clean. Asked: both cards' heads read "at game start" for errors a minute into play.
    **QA, Nov 2 2026, after 30e99e8: the fault is fixed (2026-11-02_beta_ig_4k_b.md, 32 / 32).** Two errors in a row:
    the older card's Copy holds only its own error (its separator, "attempted index: qaBetaErrorOne ...", its
    java.lang.RuntimeException and stack); the newer error's head is no longer on it. Everything else as above.
67. **The controller map (the director, Nov 2: "has to have it").** chosen. The quick wheel's "Controller map"
    entry ("Coming later.") opens a page showing what each button does in ZeD.
    - Build brings its layout to the director first, and it covers both pad glyph sets.
    - **Layout approved (the director, Nov 2 2026: "The controller map layout is right"):** the gallery's chapter 42
      page brought into a ZeD window: the pixel pad (ZeDUI/workshop/controller_map/pixel_pad.py) with its callouts, the
      button table under it, drawn in the player's chosen button pictures.
    - **Check (QA, 4K):** the wheel opens it; B closes it and focus returns; every role on the page matches the
      gamepad spec; no "coming later" text is left anywhere in ZeD.
    **QA, Nov 2 2026: confirmed (zedqa_cmap.lua through cmap_run.ps1; 32 / 32 at 4K, 32 / 32 at the Deck Large,
    37 / 37 at 720 Large).** The wheel's entry runs the map (no "Coming later."). With Xbox, PlayStation, Deck,
    Nintendo and Off: the full card wide (840 at 4K, 414 at the small sizes), centred, 12 rows, each set's own button
    pictures in the table, Off's names in faint boxes. B, A, Escape and a real click on the close box each close it,
    and no controller focus is left on it. At 4K and at the Deck Large the body fits with no scroll; at 720 Large it
    runs 30 px past: it opens at the top, D-pad Down scrolls to the end and Up back, the wheel scrolls it, the footer
    offers "D-pad: Scroll". Notes sent to build: the window was see-through (build makes it solid); the pad art is
    the same Xbox-lettered pad in every set (by design; the director's call).
    **The director, Nov 2 2026, evening: the bumpers lengthened, straight.** From the director's two sketches: LB and
    RB run out straight until their outer ends meet the start of the curve of the pad's body (the second sketch: no
    bending down over the shoulders); the triggers (with their LT / RT labels) sit above them, nudged 3 art pixels in toward the middle (the director's third ask). The red "ZeD" on the pad is replaced by the computer's maker, the Kentucky Instruments mark (the state and
    "KI", as gen_desk.py draws it on the desk's computer), one art pixel per desk pixel, in the pad's dark trim colour
    (ZeDUI/tools/icons/pad_ki_logo.py; the director's fourth ask). Drawn by QA (ZeDUI/tools/icons/bumpers_long.py,
    from the original art: the bumper's own columns, LB's rounded light end moved out for LB, LB's shaded end with its
    outline and shadow for RB) into controller_map.png; before and after in qa/archive/Nov2_beta/pl67_bumpers_before_after.png.
68. **Hair and beard with the eight-mod set (the director, Nov 2: the beta can ship with it as a known issue; keep
    working on it).** Item 54 continues. If it is unsolved at staging, it goes on item 57's Known issues.
69. **Oct 30's band calls and the radio faces (the director, Nov 2).**
    - The four band calls are kept as built: Craft's Show pop-up, "Save loadout" and "Save outfit", no number beside
      Craft's amount, and an exercise you can't do stays listed with Start greyed and the reason shown. Closes
      item 21's open question.
    - The walkie-talkie and ham radio faces lose their printed foot (the brand and "2-WAY PORTABLE"); the brand is
      already on the graphic. chosen.
    - The Nov 1 About paragraph was the director's edit, and it is kept. Closes item 42's question.
    - **Check (QA, 4K):** the walkie and ham faces at the half and the full card show no printed foot and nothing
      else moved.
    **QA, Nov 2 2026: the radio faces confirmed at 4K (twoway.txt at e4e48d7, 192 / 192;
    qa/regression/2026-11-02_pl69_twoway_4k.md).** Every walkie and ham face is drawn with no printed foot (no brand
    bar, no "2-WAY PORTABLE"); each is still its own face, centred in its panel, the walkies on the half card where a
    width fits, the hams across the drawer, every control on the face, full view and the controller as before (shots
    zqa_tw_*).
70. **The release check and the staging step (beta definition, point 5).** chosen.
    - Release check: the five-minute check before every upload. Right-click opens the menu, both windows open, an
      item moves, the controller works, the watch reads the time.
    - Staging: stage_workshop.ps1 takes the version and writes that build's page text into workshop.txt by itself,
      so the t16 slip can't recur.
    - **Check (QA):** the release check runs and passes on the current build; a dry staging shows the version and the
      new page text.
    **Staging step built (build, Nov 2 2026).** stage_workshop.ps1 takes -Description (bbcode written into
    workshop.txt's description= lines, id, tags and visibility kept; refused past 8,000 - 58 characters; warned when it
    doesn't name -Version), -ChangeNote (written into Zomboid/Lua/ZeD_workshop.txt as the upload window reads it),
    -Title and -Preview. With -Version but no -Description or -ChangeNote it warns that the old text stays. Tested for
    real with the t16 files (lock set busy, files backed up): workshop.txt byte-identical, the change note round-trips;
    Contents removed and the files and lock put back after. The release check is still to build.
    **QA, Nov 2 2026: the five-minute release check is built and passes at 4K (16 / 16, about two minutes from launch
    to quit).** Run: `pwsh -File ZeDUI/tools/qa/release_check.ps1` (it starts release_check_mouse.ps1, runs
    release_check.txt through zedqa_run.ps1 at 4K, stops the helper, prints RESULT). zedqa_release_check.lua checks:
    1 both windows open by the inventory key's call; 2 a test item goes to the floor by the game's transfer, the World
    window lists it, it comes back and the Character window lists it; 4 the controller's focus on its row, A opens its
    card on the primary action (charItemCard:hverb_1), B goes back to the row; 3 a REAL right-click (the helper moves
    the desktop cursor to the row and presses the right button) opens the item menu, and the menu was made for that
    item; 5 a worn watch shows and its face reads the game's hour and minute. It uses the screen while it runs. Part
    of every per-build pass from now on.
    **QA, Nov 3 2026: the release check on the staged 0.3.0-beta1 copy (director: "do what's still open"). All 16 PASS**
    at 4K (ZeDUI/qa/regression/2026-11-03_rc_staged_release_check.md). The staged copy leaves out the QA bridge, so
    QABridge.lua was copied in for the run and taken out after; the staged folder's 4,363 files hash the same before
    and after. The runner refuses a staged copy as before; `release_check.ps1 -Staged` lets it run on one, and only
    while the bridge is in it.
    **QA, Nov 3 2026: the restaged 0.3.0-beta1 (f95db51f): the release check, all 16 PASS at 4K, plus Build's two**
    **changes.** The context menu: options with no icon show Qa, Op, Wx (a capital, then a small letter), drawn by
    ZeD, all 4 PASS (zedqa_ctx_letters.lua). Turkish not settled: names with letters past A-Z typed into the test
    script showed Ek and 0i, but the script file itself may be read in the wrong encoding, so this says nothing about
    the game's real Turkish text; no Turkish run was made. Build settled it from the game's code: Kahlua's %w is
    Java's isLowerCase / isUpperCase / isDigit, so Ç and İ survive the strip, and ZeD.upper handles the Turkish i. The Workshop page on ZeD-UI: the 512 x 512 picture, a green
    dot and "512 x 512: a size the game takes. It must stay under 1000 KB.", nothing blocking the upload, all 5 PASS
    (zedqa_ws_preview.lua through ws_preview_run.ps1; Upload never pressed). The change note box is off the form's
    first screen (the long note makes it tall; it shows once the form is scrolled), as designed. Bridge copied in for
    the runs and taken out; the staged folder's 4,363 files hash the same before and after. Pictures kept local
    (4K): ZeDUI/qa/regression/2026-11-03_rc2_shots.
71. **Loose ends from older notes (beta definition, point 8).** chosen; build looks at each, then QA checks what was
    fixed.
    - The oven's object card drawn behind its Craft tab (Oct 29-30 notes).
    - The oven tab at UI scale 0.5. This is moot once 0.5 goes (item 58); build checks that nothing else at small
      scales shares the cause.
    - The plate export shifting pixels on a re-run (a tool, not the mod).
    - Hair and beard: clicking a picked row should un-pick it, but it stays picked (ZeD_HairBeard.lua near line
      1656, `x and nil or y`). Found by build, Nov 2.
    - The ZeD style menu's hover flicker (item 7), cause unchecked.
    **QA, Nov 2 2026, Hair and beard's un-pick: confirmed at 4K (zedqa_beta_ig.lua).** A click picks a row, a second
    click on it un-picks it (sel nil), a third picks it again. At 4K the Hair and beard rows sit below the ID card in
    the Character window's opening size, so the click went through HB.onClick on a stand-in row zone.
72. **The t16 test gaps (beta definition, point 4).** QA.
    - The game's own inventory opened by its key with the Safe mode windows switch on; the dashboard, the quick
      wheels and the game's character info by their keys.
    - The Simple belt with 0, 1, 4 and the most slots, a real mouse drag and the controller.
    - The load order tools by hand (right-click menus, Ctrl and Shift-click, Page Up and Down, the pad on folder and
      separator rows, drag) and with 1,500 mods.
    - The marks with a container column (item 44's one-list rule).
73. **Fixes built but never confirmed (beta definition, point 2).** QA confirms or reopens each:
    - 1: right-click on an inventory row (the release check covers it).
    - 6: the item card's X.
    - 7: the window box and close box hover.
    - 26: a laundry card's first opening.
    - 28: the Craft amount box at its smallest, with a recipe whose most is 1 and one of 10 or more.
    - 29: Equip names at the half card.
    - 35: the one-column Skills grid, and a wide card keeping two.
    - 36: the portrait ID card, with a screenshot for the director, and the Maps ink in use.
    - 38: the controller stops while a drawer fills the window.
    - 42: the main menu's leave-with-changes question and the pad A on the Workshop form.
    - 43: a forage find staged east reads E.

    The small-screen ones (28, 29, 35, 36, 38) are checked at the Deck size: they exist only there.
    **QA, Nov 2 2026: the Deck pass at 1280x800 with Large text (pl73_deck.txt, 5 / 5 PASS;
    2026-11-02_pl73_deck_800L.md).** Every Character and World tab, the item cards, the object cards, the oven and
    radio cards and the five Journal pages: the two windows never overlap (Character ends at 636 or 640, World starts
    at 640 or 644); Skills opens by its button; the Equip names and the Skills grid fit.
74. **QA's checklist rewritten for the beta (the director, Nov 2).** QA.
    - QA rewrites items 4 to 16 and its regression list in the two-pass shape: a per-build pass of only what changed
      plus the release check, and a full pre-release checklist.
    - The director reviews the full checklist before testing starts, and both sessions refresh it after every build.
    **QA, Nov 2 2026: the draft is written for the director's review: docs/plans/QA_CHECKLIST_BETA.md.** Pass 1 after each
    build: the release check, the build's own checks, and the scripts that cover what changed (a table by area). Pass 2
    before a release: the release check, the full run at 4K, the simple versions, the old items 4 to 16 (each mapped
    to how it is checked now), small screens once, the main menu, the languages, the upload. Three checks are still to
    build (the disclosure walk, the button census, save and reload); QA builds them once the director approves.
    **The director, Nov 2 2026: approved ("thumbs up").** QA builds the three missing checks next (the disclosure walk,
    the button census, save and reload); both sessions refresh the list after every build.
    **QA, Nov 2-3 2026: the full pre-release pass (Pass 2) for 0.3.0-beta1, on the frozen code (b20818cb, then Build's
    two fixes from it: 4dbefe69 the Simple belt, 3abae4c1 the Portuguese hand label). Reports 2026-11-02_rc_*.**
    - A. The release check: 16 / 16 at 4K (2026-11-02_release_check.md); 16 / 16 at the Deck size (_rc_release_800).
    - B. The full run, all 99 scripts at 4K: 97 pass, 2 warn, 0 fail (_rc_full_4k). Both warnings as at t16 and
      test-side: wpt "hold A moved the hammer" (the test expects the old quick use); dke one car's key-start timing
      (race here, dart at t16). No ZeD errors in the log.
    - C. Everything on Simple (zedqa_all_simple.lua, simple_pass.txt; _rc_simple_4k): one finding, the Simple belt's
      slot 1 moved 32 px when the off hand filled; Build fixed it (4dbefe69) and hands_together now passes on Full and
      on Simple (_rc_belt_full, _rc_belt_simple). Test-side: the face-only checks of rtv, tw and ldy on plain cards;
      sbl's Messages lamp (shows only while Messages keeps something) and its "belt is centred" (the fix centres the
      slots, as designed).
    - D. The three new checks: the disclosure walk (zedqa_disclosure_walk.lua) 63 / 67, the 4 misses seen open and
      closed in their pictures (Zombies Killed, the 1993 group, Build's empty All recipes, the ID card; the test's
      layout reading only sees controller stops); the button census (zedqa_button_census.lua) 481 stops, 0 dead,
      45 / 45 (_rc_census); save and reload (reload_run.ps1) 7 / 7: two settings, the Character window's place and
      tab, a loadout, all back after a quit (_rc_reload_a, _rc_reload_b).
    - E. Small screens: the short pass at 1280x800 and 1280x720, 4 / 5 each, the one warning wpt's as above.
    - F. The main menu (zedqa_menu_mods_run.ps1): About DONE; the Full or simple group 10 / 10; the beta menu checks
      11 / 11; Mod folders with compat_r4 36 / 36; the page lists with the long list 26 / 26 at 4K; sandbox pages
      4 / 5, the miss test-side (the mouse never reached the list: it read 1922,1081; the page-list run's wheel
      checks pass). Logs 2026-11-02_rc_menu_*.log.
    - G. Languages on the frozen code: TR, CN, PTBR 5 / 5 each, 4256 keys, 0 with no text. The hand circles: Turkish
      Birincil / İkincil and Chinese fit; Portuguese read "Secundári.", Build shortened it to "Secund." (3abae4c1).
    - The gallery: mm4_03_options_hidden.png (ZeD setup at Windows, the Hidden actions pop-up open) for page 48.
    - QA, Nov 3 2026: Portuguese again on 3abae4c1, 5 / 5; the belt reads "Secund." and "Principal", both whole
      (2026-11-03_rc_lang_PTBR_3abae4c1.md). The pass is complete; Build stages.
75. **Punch list housekeeping (build).**
    - Item headers that still say open or fixed although a later QA paragraph confirms them get their state
      corrected.
    - Confirmed items move under "## Confirmed".
    - The text lost in item 41 near its Stage 3 note is restored from git history.
76. **No letters in the container strips (the director, Nov 2 2026: a container with no icon "just has a letter ... That
    just takes me to modern day, and it throws me out of the immersive 1993").** fixed (build, Nov 2 2026).
    - Cause 1: a car's containers looked their icon up by the part's category, which matched nothing in the game's
      table, so every trunk, truck bed, seat and glove box showed a letter. The game keys its car art by the
      container's own type (TruckBed, GloveBox, SeatFrontLeft ...); ZeD now does the same, then the part id, then the
      category.
    - Cause 2: a container type the game has no picture for drew its first letter; the game itself shows a default.
      Now every strip button with no picture of its own (World and Character windows, the floor and the main
      inventory) shows the game's own box (its cardboard box / crate icon, ZeD.genericContainerTex). The column
      headers already leave the icon out rather than draw a letter.
    - **Check (QA, 4K):** in a car (a trunk, a truck bed, the glove box, the seats) every strip button has the game's
      picture; a container the game has no icon for (a mod's, or one of the rare types) shows the box; no letter
      anywhere in either strip.
    - Related, for the director: the right-click strip draws two letters for an action ZeD has no icon for
      (Molecules drawContextCell's fallback), the same modern tell.
77. **The laundry faces redrawn (design, Cowork; the director, Nov 2 2026: "These are great. I love them.").** built
    (258dc431, 2817d3f1; docs/handoffs/HANDOFF_laundry_redesign_20261102.md). The game model's proportions; the washer a
    top-loader seen from above (backsplash console, lid up, basket and agitator, the load round it, soapy water rising
    through it at the 5 levels: `washer*_soak1..5` with clothes, `washer*_water1..5` without, from ObjectCardLaundry's
    new `waterLoad` / `waterBare` states); the dryer under the matching console; the washer-dryer still a front-loader
    with new clothes and water. PhysPx.lua changed in its 15 laundry entries only (checked).
    - **Check (QA, in game, at a couple of UI scales):** each machine empty and with clothes; the washer at every water
      level with and without clothes; power off and the running lamps; the lid / door click opens the contents; nothing
      cut off, the controls line up with the art. Retake the laundry QA captures, and the gallery's laundry spread (59)
      when convenient.
    - **Build note (design's warning):** export_rtv.py rebuilds every machine plate, and the committed oven, generator,
      grill, ham, walkie and microwave textures and six oven / ham entries in PhysPx.lua are newer than what the tools
      make today. Running it straight into the mod would put older art back; design exported to a scratch folder and
      copied the laundry files only. Build to bring the tools level with the committed art (or guard the exporter to
      named plates) before anyone exports again.
    **QA, Nov 2 2026: confirmed at 4K and on the Deck with Large text (zedqa_laundry.lua, 202 / 202 at each;
    2026-11-02_pl77_laundry_4k.md, _800L.md; pictures for the director qa/archive/Nov2_beta/pl77_laundry_4k.png and
    pl77_washer_soak3_deck.png).** The washer, dryer and washer-dryer through the gears button: the face that fills the
    card at a whole zoom (washer@392 at both sizes), power the primary stop, no power (red lamp, the band says so), no
    water (FILL), running (one phase lamp lit, the cycle dial moving, the next phase later), stopped (lamps dark), the
    door opens the contents, the washer-dryer's WASH and DRY. The washer at every water level as the card reads it:
    water1..5 in the empty tub, soak1..5 among the clothes; the washer-dryer's water1..5. The console controls (cycle
    dial, power, the water meter, the phase lamps) sit on the art; nothing is cut off once the window shows the whole
    face (the test grows it: at 4K the opening height scrolls the face, as the radios do). The levels are given to the
    card's reading: a machine on piped water reports 10000 (always five), and one off the supply would not take water
    from a script. **For build:** (1) a machine on the house supply reads "Water 10000.0 of 10000 L"; (2) the dryer
    shows a "Water 0.0 L" row though it holds none; (3) once in two 4K runs the dryer's card opened blank (the face
    not drawn) for its first picture; it drew in the other run and on the Deck. One test-timing slip: "stopped again:
    lamps dark" read too soon after the stop once (the washer one run, the dryer another).
    **QA, Nov 2 2026, after build's two row fixes (2026-11-02_recheck_60_77_4k.md, 201 / 202).** The plain dryer has
    no Water row now (only Inside): confirmed. The piped washer still reads "Water 10000.0 of 10000 L": the test's
    machine has setUsesExternalWaterSource(false) (the script's own water switch) yet reports 10000, so the
    both-flags rule does not catch it; sent back to build. The dryer's first 4K picture was blank again (the face not
    drawn when the card had just opened); a picture a second later is to be added to tell loading from a fault.
    **QA, Nov 2 2026, after the piped fix: 202 / 202, both row fixes confirmed (2026-11-02_recheck_60_77_4k_b.md).** The
    piped washer reads "Water: On the water pipes"; the plain dryer shows only Inside. The dryer card blank on its first
    4K frame draws its face a second later (its pictures loading, item 26 rule): not a fault.
78. **The main menu desk v5: the joystick ports and the KI pad (design, Cowork; the director, Nov 2 2026: "Desk is
    approved").** chosen, staged, not installed (docs/handoffs/HANDOFF_main_menu_pad_20261102.md). Two 9-pin joystick ports on
    the case front, 1 and 2, the Kentucky Instruments pad's plug pushed into 1 (its cable out of the back and down), 2
    empty with its pins; the pad lying flat on the desk at the bottom right, beige, Super NES thick, edges rounded.
    The art is in ZeDUI/art/main_menu/v5 (gen_desk.py; grade.py reads v5); no code change, the contract is unchanged.
    - **Build:** `py grade.py none 1.0` in ZeDUI/tools/menugrade, check that only desk.png and desk_lampdim.png
      change under 42/media/textures/ZeD/mainmenu, commit with the staged files.
    - **Check (QA):** the menu at 1080p against previews/main_menu_v5_4x.png, the lights blink in place, the lamp
      flicker shows the pad; how much of the pad shows at 1280x800 and 720 (the lean-in) and on ultrawide.
79. **The Vehicle tab in two columns (the director, Nov 2-3 2026: in the beta, "we're just refining the features that
    we already offer").** chosen. Spec: docs/specs/VEHICLE_TAB_SPEC.md. The tab becomes Crafting's layout: the part list on
    the left (By section, a part under the one that comes off first; By condition, greyed until Mechanics level 4 with
    "Mechanics Level 4" from words already translated); the car diagram on the right, lighting the part the pointer or
    the pad's focus is on, clickable; a click or A puts the part's card in its place, the same row again or B brings
    the diagram back; no back arrow, no second screen. Missing parts keep their rows; the card adds the step before
    (with a button to that part), spares and tools in reach, tire pressure / battery / fuel, and where the work is
    done; the footer's verbs lit or greyed with the reason, as on every card.
    - **Build:** MechanicsTab.lua on CraftingCore's split, measures and pad paths; ship with today's baked figures.
    - **Design:** the 13 body diagrams (327 layers) redrawn in ZeD pixel art, same shapes, through MechFigs; they drop
      in when done and do not hold up the build.
    - **QA:** the spec's section 8; QA_CHECKLIST_BETA.md has the Vehicle tab row in its pass 1 table.
    - **Design, Nov 3 2026: the diagrams are redrawn and staged** (the director: "The vehicle mockup looks
      awesome"). All 13 bodies, 314 layers, the same texture names and anchors form: ZeDUI/art/mech_pixel/, from
      tools/mechanics/pixel_mech_figs.py. Build: install per docs/handoffs/HANDOFF_vehicle_diagrams_20261103.md (copy the
      textures and MechFigs.lua; draw the figure at a whole multiple so the pixels stay crisp). QA: its checks there.
    **Built (build, Nov 3 2026, 2cb35519): MechanicsTab.lua on CraftingCore's split (list 240u left, diagram or card
    right, footer with Sort and the part's verbs). By section uses the parts' own install tables: requireUninstalled
    puts a brake or suspension under its tire, a window sits under its door, and the engine bay under the hood. By
    condition is earned at Mechanics 4 (UI_ZeD_Craft_SkillLevel + IGUI_perks_Mechanics). The step before uses
    Tooltip_vehicle_require*, and the work place uses IGUI_AttachedItems_Location. No new words. The diagrams are
    today's baked figures.** Untested in game at the time.
    **QA, Nov 3 2026: section 8 in game, 31 of 33 at 4K, the Deck and 720p (Large text at the two small sizes)**
    (zedqa_mech79.lua through release_check.ps1 -Manifest, the real cursor for hover; reports
    2026-11-03_pl79_*.md; pictures ZeDUI/qa/review_20261103/pl79). Pass: By section (a brake and a suspension under
    their tire, a window under its door), the missing tire keeps its row, every row inside the list column; By
    condition greyed at Mechanics 3 (a press does nothing) and usable at 4; hover on a row lights the part and never
    opens the card; a click opens the card, the same row closes it, another swaps it; no back arrow; the wheel keeps the
    card; a click on the diagram picks a part; a real Uninstall and Install of a tire from the footer, the card staying
    on it; A opens and B closes through the controller's elements; the trailer's animal rows fit the list column. At
    720p with Large text the tire's footer holds Sort, Deflate and Uninstall (the main verb lit).
    - **Fail: no step before on a brake.** The rear left brake (recipe known, Mechanics 4 of 3, tools in the bag, its
      tire still on) shows no Uninstall: the card folds every verb that cannot be done yet into the "With ..." row, and
      the step before is looked for among the shown verbs only, so the line and its button never appear.
    - **Check: the folded row says "With Basic Mechanics (recipe), ..."** though isRecipeKnown is true after
      learnRecipe; the needs use isRecipeActuallyKnown. Whether a learned recipe counts there needs a look.
    - **Cut text:** the folded row ("With Basic Mechanics (recipe), ...", "With Tire Pump you could pum...") is cut at
      every size; "Right Headlig..." in the list at 4K and 1.75x.
    - **Colourblind:** in greyscale the lit Muffler (a thin strip) is the same grey as its neighbours; the outline does
      not make a small part stand out.
    **QA, Nov 3 2026: the fixes (aec72d19) and the pixel-art diagrams (291ed0dd), all 45 PASS at 4K, the Deck and
    720p (Large text at both small sizes)** (2026-11-03_pl79b_*.md; pictures ZeDUI/qa/review_20261103/pl79). The step
    before shows on the brake and its button opens the tire's card; the folded "With ..." row wraps ("With Tire Pump
    you could pump up the tire."); Right Headlight fits the list; in greyscale the lit part's box stands out. A pickup,
    a van, a sports car and a trailer: each inspected, hover on a row lights its part, a click on the diagram picks a
    part; the figures are crisp at 4K and 1.75 (no uneven pixel widths to the eye); a missing headlight shows its hollow
    red mark and "Missing" in the list. Not settled: the recipe line. Reading Laine's Auto Manual in the run did not
    make isRecipeActuallyKnown true within the minute waited, so whether the line is right for a real reader is
    unchecked. The test save is back as it was (recipe unknown, the magazine unread; an earlier run had left it
    marked read, cleared). Build: the recipe line stays the game's own rule (vanilla's doMenuTooltip uses the same
    isRecipeActuallyKnown). **QA, Nov 3 2026: item cards' folded row at 4K and the Deck with Large text**
    (zedqa_morerow.lua; 2026-11-03_morerow_*.md; picture ZeDUI/qa/review_20261103/pl79/item_card_folded_row.png): a
    blunt kitchen knife's card wraps "With a whetstone or a file in your bags you could sharpen it." over three lines,
    the triangle beside the first, nothing over it below. A worn bat and hammer show no folded row (their repair is
    not offered here). A tin of beans, a log and a cigarette pack have none either (their verbs are not care verbs).
80. **A Cooking tab: cook dishes the second way (the director, Nov 3 2026).** chosen; after the beta, before the release
    (it adds a feature, so it stays off the beta code freeze).
    - The rule behind it (the director): "I want to give people two ways to do everything." The right-click menu is
      one way; this tab is the other for the pot and pan dishes, which today are right-click only (the game's
      ingredient-by-ingredient dishes: stews, soups, stir fries, salads, sandwiches, pies, cereal bowls). QA read of the
      code, Nov 3: ZeD's Crafting tab runs the game's craft recipes; these dishes are outside the game's crafting
      system and ZeD keeps the game's right-click options for them.
    - Where: a tab in the Character window that shows up when a cooking vessel (pot, pan, bowl and the like) is in the
      inventory and ingredients are in reach.
    - What: built like ZeD's Crafting tab, the same two-column layout and the same way of working, so it is consistent
      and predictable: it lists the ingredients, and a dish is built from scratch there.
    - Saved recipes: a dish can be saved there to make again.
    - Making several (the director, Nov 3 2026): any dish can be made in multiples, saved or not. Once the
      ingredients are picked, the tab checks what is in the inventory and in reach; when there is enough for more than
      one (ingredients and vessels: e.g. four bowls), a minus and plus button and a count show beside Build, set 3, Build
      ("Otherwise, people will just ask for it anyway"). The count goes no higher than what is there allows, and each
      dish is made by the game's own steps (the same as the Crafting tab's batch count).
    - Sorting: by ingredient, and by kind (condiments and spices and the like).
    - The game's rules stay: the same ingredient limits per pot, pan, bowl and dish, the same results as adding them by
      hand (no conveniences that remove the game's stakes).
    - Design source: ZeD's own Crafting tab only. The director knows other cooking mods exist and wants none of their
      design carried over.
    - Next: Build designs it from the Crafting tab and brings any design questions to the director before building.
    - **QA, Nov 3 2026: built and tested (Build's 8d3b20d8 to 5a59ca55). 47 / 47 at 4K and at the Deck with Large
      text, no Cooking tab errors in the game's log** (qa/regression/2026-11-03_cook80_4k_r6.md, _1280x800L.md;
      zedqa_cook80.lua). The tab comes with a pot of water and vegetables on the character and goes with the pot; a
      stew of three made with Make is one pot holding all three, as by hand (a cabbage is more than one dish takes:
      the game uses part and leaves the rest); two pots and enough for two show the count, it stops at 2, Make 2 gives
      two stews; a stir-fry stops at 4 (Ingredients 4 / 4); saved dishes save, head the Dish list, load, offer Use
      <same kind> for a missing one (none with nothing of its kind), keep Make greyed while one is missing, and Forget;
      the controller's A adds, takes out, opens a list and picks, B shuts it, and only the list's choices and the
      boxes are stops while it is open. At the Deck with Large text the header (Dish, the pot) and the band (Sort,
      the count, Save, Make) fit. Pictures (not committed): qa/review_20261103/pl80/.
    - Found and fixed on the way (Build): Make made extra half stews (the game finishes each added ingredient after
      the next has started; each now takes the dish as it finishes); the count missed items the game lists once; the
      stir-fry was listed three times (one per pan); every vegetable was read as seasoning, so no limit held; an
      error printed at quit.
    - For the director's tuning (the game's own rules, the same as by hand): the tab goes away after Make (the pot
      is now a dish, and only an empty pot or pan starts one); seasoning is not offered for a dish not yet begun;
      frozen food is not listed at all.
    - **QA, Nov 3 2026, the staged 0.3.0-beta2 (0860bd72): the release check 16 / 16, Cooking 47 / 47, the Vehicle
      tab 45 / 45, no errors in the log (qa/regression/2026-11-03_beta2_staged.md). One fault found in the gallery
      pass, open, blocks the upload: the Cooking tab's open lists (Dish, Sort) are hidden behind its two columns;
      only a sliver of each list's frame shows (zedqa_cook_popup.lua; Screenshots/zqa_ckp_3840x2160_*.png). The
      tab's state is right (open, rows placed, a click on a row works blind), so the checks passed: a picture
      caught it.** Sent to Build.
      **Fixed in 9c021c35 (the drawer's clip laid again after each column's own), restaged: both lists draw over
      the columns (zqa_ckp_*_r2 pictures), the release check 16 / 16 and Cooking 47 / 47 on the restaged copy, no errors
      in the log (2026-11-03_cook_popup_r2.md, _beta2_staged_r2.md, _gallery_beta2_cook_r2.md). Beta 2 is ready for the
      director's sign-off.** Gallery pictures for the beta 2 spreads: Screenshots/gallery_beta2/ (not committed).
81. **The Workshop thumbnail: "The year is 1993, and so is the user interface. All of it." (the director, Nov 3 2026:
    "That's the one that goes with the next upload").** done (design). A 1993 window on a dithered desktop, 1993 huge,
    ALL in the heavy face, BETA on pixel caution tape along the foot. It is now `ZeDUI/tools/release/preview.png`
    (what stage_workshop.ps1 copies into the item), `workshop/thumbnail/preview.png` (the page mockup's) and the
    Workshop folder's preview.png; sources and the 1024 in `ZeDUI/workshop/thumbnail/` (src_1993_*.py,
    year_1993_*.png). The desk picture and the book cover are kept as backups beside them.
    - **Build:** do not run `make_preview.py` for a release (it would draw the old desk preview over this one). When
      the beta ends, drop the tape (the last block of card() in src_1993_year2.py) and re-export.
    - **The animated version (the director: "That is banging. Love it.")**: `ZeDUI/workshop/thumbnail/year_1993_animated.gif`
      (512 x 512, 88 frames, about 8 s, 651 KB, under Steam's 1 MB; frame 1 is the still, pixel for pixel; drawn by
      src_1993_anim.py). The game's uploader takes only the PNG, so: upload as usual, then set the GIF as the item's
      preview with SteamCMD (a VDF with appid 108600, publishedfileid, previewfile = the GIF; `workshop_build_item`).
      Logging into SteamCMD logs the Steam client out on that PC. Check the item page, the Workshop grid and the app.
    - **The step (director, Nov 3 2026: "Yes. Write that up"):** `ZeDUI/tools/release/set_preview_gif.ps1`, release
      checklist step 16b, after every Upload (each Upload puts the still back). Item id from workshop.txt, the GIF
      checked (a GIF, square, under 1 MB), a SteamCMD item file with the preview only. The director runs it, or build
      on his word (he signs off every upload). Needs SteamCMD installed at C:\steamcmd and logged in once by hand
      (not done yet). Dry run checked Nov 3 (item 3824968485, 512 x 512, 652 KB).
    - **QA:** the first run on the unlisted test item: the GIF plays on the item page, the grid and the Steam app;
      the item's files, size, title and description are unchanged; then the same on the real item.

82. **The survival guide (F1), the Simple look (the director, Nov 3 2026: "You are go for build").** built, QA to
    check (b641524e). Design: docs/plans/SURVIVAL_GUIDE_DRAFT.md; mockup ZeDUI/mockups/zed_survival_guide_v7.html. Code:
    42/media/lua/client/ZeD/ZeD_SurvivalGuide.lua (HOOK_MAP row 18). A ZeD window in place of the game's guide: the
    game's 15 sections and their topics on the left (Find at the top, sections fold), the topic on the right (the game's
    clip, the game's text, The Rules in Numbers for Skill Books), a band (the game's "Show the guide on startup",
    Previous, Next) and the help line. The game's behaviour kept: F1 and the Help wheel toggle it, it opens by itself on
    a new game while that box is ticked, the game pauses while it is open, the forage window's "?" opens Foraging.
    F1 opens on the active tab's topic (Skills: Skill Books; Health: Health & First Aid; Craft: Crafting Menu; Build;
    Forage; Maps; Vehicle: Mechanics Menu; Animals; Cooking; Thermal: Clothing & Temperature). English text only so far.
    The Full look (the book, "Survive the Apocalypse") comes after this passes.
    - **QA:** F1 opens and closes it (Escape and the close box close it too); the game is paused while it is open and
      runs again after; Find narrows the list ("vault", "book") and clears; sections fold and open; Previous and Next
      walk every topic in order and wrap; each section's clips play (video effects on) and show a still (off);
      long topics scroll (wheel and bar); The Rules in Numbers on Skill Books shows five volumes, their levels
      (1 to 2 ... 9 to 10), x3 to x16, and a last column naming Aiming, Reloading and Long Blade (x1.5 to x8);
      the start-up box saves (a new game opens the guide when ticked, not when cleared); F1 from the Skills tab opens
      Skill Books, from Craft opens Crafting Menu; the controller: Help wheel opens it, D-pad up and down walk the list,
      A opens a section or a topic, Right into the text and up/down scroll it, Down to the band, LB/RB turn topics,
      B closes and gives the controller back; at the Deck with Large text the window fits; no errors in the log.
    - **QA, Nov 3 2026, first run (b641524e): 54 / 57 at 4K and at the Deck with Large text** (qa/regression/
      2026-11-03_guide82_4k.md, _1280x800L.md; zedqa_guide82.lua). Passing: the hooks (the game's guide never opens);
      F1 opens and closes it, Escape and ZeD's Escape taker close it, the Help wheel and the forage window's entry open
      it (on Foraging); the game pauses while it is open and runs after; 15 sections and 81 topics read from the game;
      Find narrows ("vault": Vaulting; "book": 2) and clears; sections fold and open; Next walks all 81 in order and
      wraps; 14 sections' clips play; long topics scroll with a bar; Skill Books' rules (Volume, Levels 1 to 2 ... 9 to
      10, x3 to x16, Aiming, Long Blade, Reloading x1.5 to x8, three notes); the start-up box sets and clears the
      game's option; F1 on Skills opens Skill Books, on Craft Crafting Menu; the pad's D-pad, A, LB / RB, the band and B.
      The window fits at the Deck with Large text. Pictures: qa/review_20261103/pl82/.
    - Found: (1) **Previous on the first topic throws** (ZeD_SurvivalGuide.lua:226, `(at - 1 + d) % #flat` is -1 in
      Kahlua: its % keeps the sign; flat[0] is nil); LB there too. (2) **No still with video effects off**: the game
      ships no stills for its guide clips (media/videos/survival_guide has only .bik), and the topic's thumbnail path
      (media/ui/playstyleIcons/...) loads nothing, so the clip box is an empty black box. The director's game has video
      effects off. (3) Turning video effects on with a topic open keeps the old state until another topic is chosen.
      (4) Notes: the window is see-through (the ZeD option), so the inventory behind shows faintly through the list;
      at the Deck the game's "Game Paused" sits over the guide's title line.
    - **QA, Nov 3 2026, the fixes (40ca0191, e87c0f62): 58 / 59 at 4K, then the stills 4 / 4, no errors in the log.**
      Previous and LB wrap from the first topic to the last; the clip follows the Video effects option at once; with
      it off every one of the 81 topics shows its still (Skill Books: the reading chair), on swaps to the clip and off
      back at once (qa/regression/2026-11-03_guide82_4k_r2.md, _guide82_stills.md; zedqa_guide82_stills.lua). The
      director's pictures, clean, in the gallery look: Zomboid/Screenshots/guide_director/ (Skill Books with its still,
      with the clip playing, scrolled to the whole rules table; Barricading mid-clip; Find narrowed to "book").
      Left open: the Deck with Large text after the stills (the layout did not change).
    - **QA, Nov 3 2026: done (e225e3f9).** At 4K and at the Deck with Large text: g82 60 / 60, the pictures in the
      text 8 / 8 (mouse 21 / 21, controller 22 / 22), the stills 4 / 4, the measure 8 / 8 (351 lines, at most 71
      letters, the longest tenth from 66; no line past the measure; the head line, the clip, the rules table with its
      long headings on two lines, and the band fit; the window fits the screen), no errors in the log (qa/regression/
      2026-11-03_guide82_final_4k.md, _final_1280x800L.md). The director's pictures: Zomboid/Screenshots/
      guide_director/ (Skill Books with its still, with the clip, scrolled to the rules; Barricading mid-clip; Find
      "book"; the Map topic's controller text with its button picture).

83. **The survival guide's Full look: the book, "Survive the Apocalypse" (the director, Nov 3 2026: "The book look").**
    built, QA to check (b1fae517). Mockup ZeDUI/mockups/zed_survival_guide_v7.html (the look settled with the director:
    the 1983 bookstore guide's chapter openers, the 1990 magazine's grey bar, no marks, no drop caps). Code:
    42/media/lua/client/ZeD/ZeD_SurvivalGuideBook.lua; ZeD_SurvivalGuide.lua opens it while ZeD setup's new Full or
    simple row "Survival guide" is Full (the default; the Access preset picks Simple). Chinese, Japanese, Korean, Thai
    and Arabic keep the window. The game's own faces at any size (Old Standard TT, Roberto Sans Bold Italic, Open Sans),
    drawn as the print pages are. One topic a page; a chapter's first topic opens with "Chapter n", the chapter in heavy
    italic capitals, the clip (or its still), an italic caption, a bold Title Case line; a topic with rules has them on
    the next page; a long topic runs on. Front: the title page, the contents (page numbers, dotted leaders) facing the
    introduction with the author's photo (its four paragraphs are Build's placeholder for the director to rewrite).
    - **QA:** F1 opens the book (Full) and the window (Simple), both ways, and closes it; a new game with the start-up
      box ticked opens the book on its title page; F1 from Skills opens the spread with Skill Books and its rules page;
      the strip's Previous page, Contents, Next page and start-up box work; a click on the left page turns back, on the
      right page on; the wheel, the arrow keys, Page Up/Down and Home work; the contents rows and the thumb index jump to
      their chapters and their page numbers match the folios; every chapter opener and topic fits its page (nothing over
      the folio; a run-on page reads "(continued)"); clips play on the page, and the stills show with effects off;
      the Skill Books rules page draws the grey bar, the chart (headings wrap, nothing cut) and the notes; the title
      page and the introduction (photo, text beside it then under it, the signature); the controller (LB/RB turn, Y
      contents, Down to the strip, A presses, B closes); the book fits the Deck with Large text; Russian shows the book
      in Cyrillic; Japanese shows the window; no errors in the log. Pictures for the director: the title page, the
      contents and introduction, a chapter opener mid-clip, Skill Books with its rules page.
    - **QA, Nov 3 2026: passes (da1a99cf).** At 4K and at the Deck with Large text: the book 40 / 40 at both (88 pages,
      44 spreads; F1 on Skills opens Skill Books facing its rules), the real-mouse checks 9 / 9 (a contents row, clicks
      over the text on both pages, a thumb, the strip's Next and start-up box all land through the words), no errors in
      the log; the words crisp on the paper after several reopens (the game's own text atoms, drawn by the book); Aiming
      plays; nothing left on screen after closing; frame time the same as the window look (8.3 ms, 120 fps). The Deck:
      the book fills the screen (unit 1.0), Large text makes the type larger. Found on the way and fixed (Build): the
      chapter decks' Title Case threw (Kahlua's empty capture), ZeD's font lists had no Sdf faces (every one drew as
      Small), the Sdf type drew soft with a halo, the atoms sat under the pages after a reopen, Skill Books' rules
      overleaf. Open, small: at the Deck the game's "Game Paused" box sits over the top of the gutter; justified lines
      spread whole spaces, so some gaps look doubled. Not run: Russian and Japanese. The director's pictures:
      Zomboid/Screenshots/guide_book_director/ (title, contents and introduction, a chapter opener, Skill Books and its
      rules).
    - **QA, Nov 4 2026, the flow pages and translations (5c4a44a0, d085a6fc, 9e0089b5): PASS.** 4K 46/46: 62 pages,
      26 shared by two or more topics, 1 run-on; 15 chapter openers' clips full width, 66 topic clips two-thirds,
      centred (the director: QA found no page was ever shared with full-width clips). Deck Large 46/46: 74 pages, 18
      shared, 4 run-ons, the pause box hidden. Russian and Spanish open the book fully translated (title, introduction,
      rules; names kept); Japanese opens the window translated. Thai: no line past the measure in 81 topics. Japanese
      line breaking (a full stop started a line) fixed in d085a6fc. **Kinsoku, QA Nov 4: PASS** (zedqa_kinsoku.lua,
      every topic in the window): Japanese 314 lines and Chinese (CH) 224 CJK lines, none starting with a closing
      mark, long-vowel mark or small kana, none ending with an opening mark; no line past the measure in either.
      (g8m's "letters per line" count reads 35 in Japanese: it counts characters, and a CJK character is about two
      Latin widths, so that line is not a fault.) The director's pictures retaken on 5c4a44a0 at 4K into
      Zomboid/Screenshots/guide_book_director/ (1 to 4, plus 5_shared_page; Nov 3's set moved to nov3/).

84. **The Mods screen's readability (the director, Nov 4 2026, from FAIV's request in the Suggestions thread; promised
    for the next beta).** Mockup ZeDUI/mockups/zed_mods_readability_v1.html, QA notes
    ZeDUI/qa/archive/2026-11-04_mods_readability.md. Built in 133c0dc4: on rows on a solid band darker than the list, off
    rows' names and icons dimmed; an Off tab; Hide incompatible by Find (with the count); the tab and the box kept
    between visits (ZeD_modsview.txt); a Simple view (ZeD setup, Full or simple: Mods screen); System 7's seven Finder
    labels for folders (the picture tinted; ZeD_modfolders.txt) and separators (name and rules; ZeD_modprofiles.txt),
    picked from a swatch row with None first. No edge stripe (the director: too modern). Open: QA at 4K and the Deck
    Large in every theme, the labels' contrast in every theme and accent; the other 27 languages' 16 new keys.
    - **QA, Nov 4 2026 (133c0dc4): PASS, 33 / 33 at 4K and 33 / 33 at the Deck (1280x800, Large text).**
      zedqa_mods_read.lua (part A, 30) and zedqa_mods_read2.lua (part B after a restart, 3), with compat_r4_mods.txt
      (395 installed, 11 on, 24 off with a problem).
      - **Band and dim:** on rows draw the band and bright names; off names draw dimmed.
      - **Off tab:** 384 rows, all off.
      - **Hide incompatible:** takes out exactly the 24 off mods with a problem; all 11 on mods stay; "24 hidden"
        beside it; the pad stop is there.
      - **Simple:** 30u rows; tabs All / On / Off / Problems; Conflicts falls back to All; no folders; Full again
        after.
      - **Folder labels:** set and None; the folders file byte for byte the same; kept in ZeD_modfolders.txt.
      - **Separator labels:** set; Undo takes it back; the pane's eight swatch stops; Done writes "|cool".
      - **After a restart:** Off, Hide incompatible, the folder label and the separator label all come back.
      - **Files:** the player's ModFolders.cfg untouched.
      - **Contrast:** all seven labels at 4.5:1 or more on the window, the rows and the band in dark, light and high
        contrast, each with orange and blue (worst 6.27:1).
      - **The band against the window:** 1.14 to 1.22:1 as colours. In the pictures (the window is see-through over
        the desk) it reads clearly in dark and high contrast, softer in light.
      - Pictures: Screenshots/zqa_mrd_3840x2160_*, zqa_mrd_1280x800_*, zqa_mrd_themes_sheet.png,
        zqa_mrd_labels_sheet.png.
      - **Design note for the director:** the labels are lifted to 4.6:1 as if they were text, so in dark and high
        contrast they come out pastel: Hot reads pink (#F5BAB9), Personal lavender, Project 2 beige. Swatches, the
        folder picture and the separator's rules are graphics (WCAG asks 3:1), so they could keep System 7's strong
        colours, with only the separator's name lifted.
      - **Small (QA):**
        - Simple's info pane still offers "Move to folder..." though Simple has no folders.
        - At the Deck with Large text the info pane's tab strip runs out (Conflicts cut to "Conf"); not checked
          whether that is new.
    - **QA, Nov 4 2026, other languages (067a0361) at the Deck with Large text: Hungarian, Dutch, Danish**
      (zedqa_mods_lang.lua; pictures Screenshots/zqa_mlg_*, zqa_mlg_strips.png).
      - **FAIL, Hungarian Simple:** Find shrinks to 69 px and its field is drawn over the Hide incompatible box and the
        start of its label ("...zeférhetetlenek elrejtése"). Simple's list column is narrower; the box, label and
        "24 elrejtve" leave Find no room.
      - **Dutch and Danish Simple:** Find is small (69 and 111 px) but nothing overlaps.
      - **Dutch Full:** the tab strip runs past the list (Workshop cut to "Workshop 29"). The Off tab adds to an
        older squeeze.
      - **Dutch Full:** the pane's "Naar map verplaatsen..." button runs past the pane's right edge.
      - **All three:** the box's help line is longer than the band and ends in "..."; the end of the sentence is
        lost.
      - **Hungarian and Danish Full** fit.
    - **QA, Nov 4 2026, recheck on 498ed7ee + f01b8ae8 at the Deck with Large text (English, Dutch, Hungarian,
      Danish): PASS, 8 / 8.**
      - Find keeps 158 px or more in every language, Simple and Full; nothing overlaps.
      - Hungarian Simple shortens the box's label to "Összeférhetetlene..." and drops the count.
      - The list's tabs drop their counts to fit in Dutch.
      - The info pane's four tabs fit in all four.
      - "Move to folder..." sits on its own line in Dutch and Hungarian, and is gone from Simple.
      - The help lines fit in one line.
      - Picture: Screenshots/zqa_mlg_recheck2.png.
    - **QA, Nov 4 2026, strong label colours (09343999, the director: "I think they use strong colors"): PASS, 36 / 36
      at 4K plus 3 / 3 after a restart.**
      - The marks (swatches, folder picture, separator rules) reach 3:1 or more, and the separator names reach 4.5:1
        or more, in dark, light and hicon, each with orange and blue. The worst mark is 4.18:1 (light/orange
        Essential on the band).
      - On dark, Essential, Cool and In Progress stay as System 7 drew them, and Hot moves only a little. Personal,
        Project 1 and Project 2 lift to lavender, sage and tan, as they must to read on black.
      - Picture: Screenshots/zqa_mrd_labels_sheet_strong.png.
    - **QA, Nov 4 2026, ZeD's accent colours as labels (ec4d450c, the director: "we are not System 7"): PASS, 35 / 36
      at 4K plus 3 / 3 after a restart.** The one FAIL was QA's script still looking for "|cool" in the profile file
      (fixed). Part B read "teal" back from that file after the restart.
      - Nine swatch stops in the folder pane and in the separator pane (None and eight colours).
      - Marks reach 3:1 or more, and separator names 4.5:1 or more, in dark, light and hicon with orange and blue.
        The worst mark is 4.19:1 (light/orange teal on the band).
      - Folder red and separator teal both survive a restart.
      - Small: the teal label is named "PZ Teal" (the accent setting's own name, UI_ZeD_Accent_Teal), while the rest
        are plain colour names ("Red", "Pink").
      - Picture: Screenshots/zqa_mrd_labels_sheet_accents.png.
85. **Overhead notes (the director, Nov 4 2026: the game's red and green lines over the head go into ZeD's bubble, and
    every line into Messages; beta 3).** Built in cfd52083 (ZeD_HaloText.lua; ZeD setup: Overhead notes).
    - **QA, Nov 4 2026: PASS at 4K and at the Deck with Large text** (zedqa_halo_notes.lua, halo_notes.txt,
      halo_notes_deck.txt; probe f24a1517). 9 / 10 and 8 / 10; every miss was the test's own (its fade timing counts
      ticks, not seconds; it expected XP before the game's multiplier).
      - A real game line (ISReadABook:doHaloText, "I don't get it...") and a good line ("Learned Make Plank") show in
        ZeD's bubble with their status squares, stacked above the speech bubble. They're gone after the hold.
      - The same line three times is one bubble, and one Messages card reading "3 times".
      - Messages: "From the game" > "Over your head", with Good and Bad tags. The cards are read, so there's no
        unread count.
      - XP (AddXP with the game's halo flag): the game's own green "Carpentry XP" still draws, and Messages keeps one
        summed card, "Carpentry +5.0 XP". It isn't in ZeD's bubble.
      - A level up is logged ("Cooking: level 1").
      - Switched off: nothing goes to the bubble or to Messages.
      - Note: the bubbles are world text, so at the Deck an open World window covers them (the game's own text
        behaves the same).
      - Test note: B42's Carpentry perk is Perks.Woodwork (Perks.Carpentry is nil and threw in AddXP).
      - Pictures: Screenshots/zqa_hln_*, zqa_hln_sheet.png.
86. **The change note on the main menu's corkboard (the director, Nov 5 2026: "one long note, yellow paper, and it's
    the change notes. At the top, it lists the current beta number").** chosen; staged, not installed
    (docs/handoffs/HANDOFF_main_menu_note_20261105.md). A sheet of yellow legal paper replaces the sticky note and the photo
    beside Princess Quest 3. The paper is in the art (ZeDUI/art/main_menu/v6, grade.py reads v6); the menu writes the
    words: the beta from the mod's version in the 5 x 7 face, five short lines from MenuNote.lua in the 3 x 5 face, in
    the note's ink (lit and dimmed).
    - **Build:** grade v6 in, then ZeD_MainMenu.lua writes the heading and the lines per the handoff's contract; add
      MenuNote.lua with beta 4's lines (SERVER TAB, PVP MARKER, CHAT, ADMIN TAB, BOX FIX).
    - **QA:** the handoff's checks (1080p against the preview, the lamp dip, 4K, the lean-in sizes, ultrawide, DEV,
      a long line cut).
    - **Every release:** the five lines updated (release checklist step 4b).
87. **Multiplayer and admin, the full scope (the director, Nov 5 2026: "I want to solve for all these problems ...
    I would rather just have it included").** chosen; design first. docs/specs/MP_ADMIN_SCOPE.md: ZeD ships a server part
    (official Lua); six phases (reports and tickets; admin clarity, players and moderation; safehouses and factions in
    cards; logs; community; opt-in systems off by default); every game pop-up the server surfaces open either moves
    into a card or gets the ZeD skin (the table there).
    - **Design:** Phase 1 mockup (Ask the admins, the Tickets queue, a ticket card) for the director.
      Drawn Nov 5: `mockups/zed_tickets_v1.html`, then `_v2` with the director's word: the six kinds stand,
      "nearby" is 30 tiles, Delete is admins only, moderators (and admins) mark Spam. Also settled Nov 5: names and
      short text are inline fields in the cards, never pop-ups (MP_ADMIN_SCOPE.md, the pop-ups section).
      Phase 3 drawn Nov 5: `mockups/zed_safehouse_faction_v1.html` (safehouse and faction cards, names inline).
      Phase 2 drawn Nov 5: `mockups/zed_admin_tools_v1.html` (Players, the Player card, Roles, Bans, Spawn items).
      Phase 4 drawn Nov 5: `mockups/zed_logs_v1.html`. Phases 5 and 6: `mockups/zed_community_v1.html`. All six
      phases now have a mockup; the director's "looks good, continue" on Phase 2 (Nov 5).
      Held from Build until beta 5 ships (the director, Nov 5).
    - **Build:** the server part's data and messages for tickets, after the mockup is approved.
    - **QA:** each phase on the local server, two players for tickets and invites.
    - **Settled by the director, Nov 5 (the design's E12, E13, E7):** a ticket stays open for replies after it's answered,
      and a player's reply moves it back to In progress. The game's own ticket holds only a stub ("[GRIEF #14] see the
      Tickets queue"), so reports stay private. Timed bans are ZeD's own ban; permanent bans are the game's.
    - **QA on the real server, Nov 5 (settled E5, E6, E11, E14):** dates are UTC, labeled so. Past about 1 MB the game's
      getTickets never replies: any client can cause that with raw addTicket calls (a game fault; ZeD's own filing can't, it
      files stubs). ZeD's queue keeps working, the link to the game's list stops. **To do:** a line for staff when the
      game's list stops answering; add it to the notes for The Indie Stone. Known cost of the stub: a ticket lost in a crash
      with no save comes back with its kind but the words "see the Tickets queue".
    - **E2 settled on the real server, Nov 6:** a wrapped complete runs by the class, no fallback, so refusals work.
      **To do after the regression:** Lo.tap drops any logger whose plain name holds "zed", so "ZedTracker" never shows:
      match the exact plain name instead.

88. **The male skeleton's right arm (the director, Nov 5 2026: the lower arm, the wrist, the forearm, where the
    elbow joint is, "it's either dislocated or very broken. A doctor would probably want to get that person into
    surgery").** The body figure's `m-skeleton.png` (and the `m-bicep-r`, `m-wrist-r`, `m-hand-r` part layers drawn
    from the same bones), made by `tools/physpx/d_skeleton.py`.
    - **What's wrong:** below the elbow the forearm leaves the upper arm at a kink, stepping out sideways instead of
      carrying on from the joint, and the wrist bends out again under it. The code's "r" is the character's right,
      the viewer's left (x < 110); that side is the worst. The other arm has a smaller step at its elbow; fix both
      to one rule so they match.
    - **The fix:** one straight line from the elbow knob through the forearm (radius and ulna side by side) to the
      wrist, the slight outward carry angle only, the elbow a joint the two bones meet at, not an offset. Then the
      wrist and hand on the forearm's line. Check the female figure for the same fault while there.
    - **Design:** redraw in `d_skeleton.py`, export to scratch, copy only the `m-` (and if needed `f-`) body files
      and `ZeD_BodyLayout.lua`'s arm rectangles (the tools may have drifted from the committed art).
    - **QA:** the Health, Thermal and Equipment tabs, both sexes, tinted parts still land on the right bones.
    - **Done in design, Nov 5 2026 (not installed: beta 5 is being assembled).** The cause: the forearm was drawn
      to fill the flesh outline, which bows out at the elbow, so it started off the upper arm's end. Now
      `d_skeleton.py` draws it straight from the elbow joint to the wrist (the ulna toward the body, the radius
      outside; one bone where the arm is too slim). Both arms, both sexes (hers had a smaller step). Only the arm
      layers change, pixel-checked against the committed art: m/f `-skeleton`, `-bicep-l/r`, `-wrist-l/r`, `-hand-l`.
      Staged in `ZeDUI/art/skeleton_arms_88/` with `_layout.lua.txt`.
    - **Build, after beta 5 ships:** copy the 12 PNGs into `42/media/textures/ZeD/body/` and the arm rows of
      `_layout.lua.txt` (the `bicep-r`, `wrist-r`, `wrist-l`, `hand-l` rects and the two hit maps) into
      ZeD_BodyFigure.lua's `M_HITS` / `F_HITS` / `M_HITMAP` / `F_HITMAP`. Don't rerun the whole export into 42/.
    - **Change note (the director's words, Nov 5 2026):** "Both male and female skeletons have had their elbows
      surgically repaired. Both are expected to make full recoveries."
    - **Installed Nov 5 (5876172f). QA PASS:** both figures at 3x, tinted parts on their own bones, the hit walk down each
      arm clean. The tabs ran on the male figure only and the Equip doll wasn't pictured; both draw the same parts.

89. **The Identity tab, Immersive and Simple (the director, Nov 5 2026: "Everything is either immersive or simple").**
    Immersive is the license, Simple is ZeD components (called License and Plain in the notes below and in v1). Design:
    `mockups/zed_identity_v2.html` (v1 before it); the art in `ZeDUI/art/identity/` from `tools/identity/ky_header.py`.
    **Approved as drawn (the director, Nov 5 2026, 6:28 pm: "No changes").** Held from Build until beta 5 ships.
    - **Weight** (the director: "as large as the name ... a plus or minus, depending on if it's going up or down. Both
      cards"): on every card the weight is the name's size and weight, at the name row's right (the narrow license:
      beside the surname; WGT leaves the small rows), then + gaining, ++ gaining fast, - losing, nothing steady, from the
      game's own Nutrition (isIncWeightLot, isIncWeight, isDecWeight), the sign in the accent.
    - **The header, in pixel art** ("the old art style"): 24 art pixels tall, two pieces pinned to the band's ends
      (`ky_head_left.png`: the state, COMMONWEALTH OF / KENTUCKY / OPERATOR'S LICENSE; `ky_head_right.png`: CLASS D and
      the BRAIN DONOR pill, the director's joke kept: "it's a zombie game, not heart donor"), drawn at a whole-number
      scale (the band's height / 24) with nearest filtering (`Atoms` nearest loader), the band filled with KY.blue with a
      lighter top rule and a shade bottom rule. Replaces `Kentucky-dl-head.png`.
    - **The narrow card stays a license**, laid out like Tennessee's vertical card (the director's reference, Nov 5):
      `ky_head_tall.png` (the three lines stacked); a 3:4 photo with OPERATOR / CLASS D, the permit, DL NO, SURVIVED big,
      ISS (the game's start date) and EXP (four years on) beside it; the name big (surname over forename); small rows
      (SEX, WGT, HAIR, STYLE, FACIAL, BODY, PROF, KILLS, FAV); the faded seal and `ky_donor.png` at the foot;
      `ky_bg_tile.png` behind the fields and `ky_watermark.png` (the state, large and faint). Picking the photo fills the
      whole card under the header with the full body; picking it again brings the card back.
    - **Accent** (the director): every colored word on the license, wide and narrow (the labels, the CLASS box, the
      permit, the weight's sign), is the player's accent, darkened for the cream card (62% accent, 38% black) so pale
      accents read. Values stay black, Survived For's and EXP's too (the director, Nov 5: the colored survived value
      "looks weird").
    - **Carry permit by profession** (the director: "veteran, police officer, maybe throw in a couple surprises. Not
      teacher."): Police Officer, Veteran, Security Guard, Park Ranger, Burger Flipper; Burglar's is stamped REVOKED.
      Wide: a rubber stamp over the seal; narrow: a filled box under CLASS D; Plain: a "Carry permit" row. (Kentucky
      only began issuing them in October 1996.)
    - **Plain** (the director: "no graphic, just ZeD components, for vertical and wide"): the avatar on the theme's
      surface, the name and weight, label / value rows (labels in the accent), no rules; a ZeD setup choice (Look,
      Identity card: License / Plain).
    - **Build, after beta 5:** IdentityTab.lua's two card layouts redrawn to the mockup; the tall layout's fields and
      photo replaced; the setting added; the permit table in one place.
    - **QA:** both styles at both widths, 1x and 2x and 1.75x at 4K, all nine accents and the three themes, the full
      body both ways, a long name, each permit profession.
    - **Built Nov 5 (e6188ce4, e453aab6). QA PASS in game:** both styles and widths, the half card at the Deck, weights,
      permits, real mouse on model and sky, the server's ISS. Build added: the photo holds still on this tab (idles off),
      the Equip doll keeps them (not yet seen by QA). For the director's eye: the half card, trait icons gone, the row in Look.

90. **American spelling everywhere players read (the director, Nov 5 2026: "spell color C-O-L-O-R and leave the U over
    in Europe").** color, gray, center, favorite, license, behavior. Design fixed its Nov 5 files (the MP mockups,
    MP_ADMIN_SCOPE.md, VEHICLE_TAB_SPEC.md, ky_header.py). Left for Build after beta 5: five lines in
    `42/media/lua/shared/Translate/EN/UI.json` ("Greyed" twice in UI_ZeD_Order_PickNone*, "colours" in
    UI_ZeD_Mods_HelpLabel, "colour" in UI_ZeD_GCh_zed_look_Text and UI_ZeD_GCh_whatsnew_beta3_Text), and
    `ZeDUI/workshop/license_block.bbcode` ("[h2]Licence[/h2]"; the live page already says License). The game's own
    keys (IGUI_char_Favourite_Weapon) stay as they are. Every change note and description from here on: American.
    **Done Nov 5 (5876172f). QA PASS:** the five keys read American as the game loads them; the license block too.

91. **The radial wheels redesign, for beta 6 (the director, Nov 5 2026, through QA: "Yes, add it").** The spec is the Claude
    doc "ZeD-GUI Radial Wheels: Build & QA Handoff" (https://claude.ai/artifact/4HtFjQfJExmaMQaQcJ8Yj3). Tap a D-pad
    direction to open, the left stick keeps walking, the right stick picks by angle, flick-release takes, the same
    direction or B cancels, four settings (Wheel open, Wheel commit, Wheel toggle mode, Wheel stick dead zone).
    - **Settled by the director, Nov 5:** Left and Right keep today's wheels (same slices, inner wheels, Tabs first),
      only the gesture changes, so chords and spread 44 stand. Stick click ships as an exception to the rule: it counts
      only with a wheel open and that setting chosen. Aim or attack with a wheel up closes the wheel, takes nothing, and
      the attack happens; the bumpers close it and open the windows.
    - **Inner wheels under the new gesture (Build's call):** a flick onto a slice with a corner triangle opens that ring
      in place; a flick there takes; B backs out one level; the same D-pad direction closes all of it.
    - **Read against what's built, Nov 5 (Build).**
      - The doc's "October mapping" is not what shipped. Shipped: GAMEPAD_SPEC (A left click, X right click, B back, Y
        windows, LB and RB the windows). The doc's QA line "A left-clicks, B right-clicks" and its paste-in section get
        corrected to that. "S119 lock" means the same current map.
      - Left and Right are the windows' tabs in the doc. Built: the action wheels of DPAD_WHEELS_SPEC (Character: Tabs,
        Weapons, Eat, Drink, Medicine, Sleep, Clothing, Use; World: Tabs, Map, Vehicle, Animal, Craft and build, Search,
        Lights and power, Zones). Those wheels are the only controller way to much of this: entering a vehicle among it.
      - Tabs do not fit eight slots: Character has 10 (8 + Cooking + Server on a server), World 10 (9 + Admin).
      - "No nesting" removes today's inner wheels: all of Social's gestures, Sit, Game speed, Zoom, View, Help, and every
        list of carried things.
      - Quick action chords (spread 44, QUICK_CHORDS_SPEC.md) find their action by wheel and place ("character:3" is
        Eat), and the default twelve use those places; players' saved chords in ZeD_chords.txt too.
      - Here and Now's open question is already answered by what's built: "Places never move" (DPAD_WHEELS_SPEC 2.6):
        every slice always there, off with its reason when it can't be done.
      - Hold is today's behavior; the setting keeps today's code path.
      - Haptics can't be done: the game has no rumble call and no haptics setting (checked in the game's code).
      - "Stick click" as a commit touches the standing rule that nothing in the world binds to L3 or R3.
      - The Select (ZeD) wheel is not in the doc: it follows the same settings (Build's call).
      - Walking with a wheel up: not yet known if the game itself stops the left stick while a wheel holds the pad.
        QA to settle on a pad. If it does, the wheel stops taking the pad and reads the stick itself.
      - The look isn't changing (the approved wheel, ZeD_Wheel.lua, stays, so mods that add slices keep working), so the
        doc's "mockup before code" step is skipped; the constants get a debug block for tuning on a real pad.
    - **QA:** the doc's checklist, corrected; then spreads 43 and 44 and the controller map if they change. Toggle mode
      goes on the Workshop page's Access list.
    - **Built Nov 5 (merged 5ee11292). QA PASS, scripted:** zedqa_dpad_wheels 147 pass, 0 fail, and ws, wi, wh, pg, qc. No
      real pad yet: the first real tap, walking with a wheel up, cruise control and flick feel are the director's to try.

92. **The dashes for Roadworthy: the missing lamps, an odometer and a trip odometer (the director, Nov 6 2026, from
    Neonvolt's request; QA's `HANDOFF_design_dash_indicators_20261106.md`).** For the next beta, not beta 6. Design done
    in `tools/dashpx/` (build.py clean, 19 dashes); `export_lua.py` not run, so nothing is in `42/` yet. The spec is
    `HANDOFF_design_dash_roadworthy_20261106.md`.
    - **Settled by the director:** a belt lamp on every road car; the race car gets OIL and WATER jewels only; the Dart
      gets a temperature gauge in its empty dial; miles on the plate, the player's units on the Simple dash. Design's
      call: lamps with nothing to show stay dark but for the key-on bulb check.
    - **Drawn:** belt on 7 dashes, hot on 11, oil on 4, the Dart's gauge; mechanical drums (odometer and trip, the
      tenths turning over) on every dial dash with a stem to zero the trip; the VFD and LCD odometers on cossette,
      luxury and dashelite, switching ODO / TRIP.
    - **Build:** export; the `drums` part; the `tripReset` and `odoButton` verbs; `odo` and `trip` on the car's modData
      with a starting mileage for found cars; the hot lamp in the bulb check; the Simple dash's Trip cell; later,
      the lamps wired to Roadworthy's states once QA has it running.
    - **The LCD glass at night (the director, Nov 6: "When it's in the dark, it's glowing white still").** Live today
      on the Dash Elite: its odometer and climate LCDs are redrawn in day gray at night with the key on. Fixed in the
      tools (night.py bakes a dimmer backlight in the bulbs' color; it lights only with the panel lights). Build:
      re-export, and `L.lit` added to the glass condition in ZeD_Plate.lua (the handoff's Night section). Can ship
      ahead of the rest.
    - **QA:** the handoff's nine steps; for the glass, the Dash Elite at night with the lights on and off.
93. **Police radar, a future build (the director, Nov 6 2026: "Cops and robbers. Cops and speeders.").** The police and
    sheriff dashes read the speed of a car in a narrow cone off the hood, for multiplayer roleplay. Nothing built, not for
    beta 6. Read from the game's code, not tested: the car's forward vector and every loaded car are there; time how far
    the target moved between two reads rather than trust getCurrentSpeedKmHour on a car this client doesn't drive. Range
    is capped by the loaded chunks, which shrink with the window, so set one fixed range below that. Check line of sight
    yourself: the game won't stop a reading through a building. Proposed: cars within sight and a short fixed range only
    (the director hasn't ruled on it; reaching past what the player sees would remove the game's stakes). The director
    still decides where the readout sits (on the dash or above the siren controls). Needs two players on a server.
94. **The Dash Elite odometer's unlit figures, after beta 6 (the director, Nov 6 2026: "That's a little problem"; okay
    for this release, no QA round for it now).** At night with the panel lights off, the window's unlit marks read as what
    looks like an E, a single quote, two half pipes, another single quote and another E, in the dark. The director wants
    that fixed; the unlit marks should be four 8s, and QA's picture (ZeDUI/qa/archive/dash_elite_odometer_b_20261106.jpg) shows
    five figure spaces. Look at it with item 92's Dash Elite LCD odometer, which draws six figures, so the figure count
    is settled once.
95. **After beta 6: German cards and clips left over (QA, Nov 6 2026, 101 pictures, no layout breakage).** "Sent as #16.
    You'll see when an admin opens it." is untranslated; "1 x Axe an du" should be "an dich"; the item search says
    "Keine passenden Tickets"; the Bans heading "Jemanden offline bannen" runs into its hint; the player card shows
    English occupation, trait and skill names; dates stay "Nov, 9:14 PM". Also: the Server tab and the ticket cards end
    their draw with one clip more than they start, as the Admin tab did (AdminTab.lua:337-343, ZeD_TicketCards.lua:2331-2339,
    ServerTab.lua:285-316). The World window now clears it for added tabs; move the clear to the tabs themselves and find
    out why the Character window survives it.
    **Build, Nov 7 2026: the clip half is done, for QA (the German half is still open).** The Admin tab, the Server tab and
    the ticket cards each clear their last clip at the end of their draw, and so do the Evolving Traits World, Appearance
    (SPNCC) and Traits as Skills tabs; the join screen's extra clear after a card is gone. The Evolving Traits World and
    Traits as Skills details set one clip, not a second one inside the first, when they scroll. The World window's clear
    after every tab stays as a safety net. Why the Character window got by: the inventory list it draws after the drawer
    starts with one clear of its own, which took off one leftover clip; two would have hidden it (see 97). QA reads, at 4K
    1.75x and Deck 1280x800 Auto: World window > Admin tab (home list, Tickets, an open ticket, a player-list pop-up) and
    Character window > Server tab (list, an open ticket, typing in a card's field), each with and without an item card
    open, for the tab icons on the right, the help line, the inventory list and the footer; the join screen's community
    card, its scrollbar and buttons; in the compat rig, the Evolving Traits World, Appearance and Traits as Skills tabs
    with a row whose details scroll (tab header, Find mark, both scrollbars, tab strip, footer); the Ranch page as a
    regression check. Sims: ticket_cards_sim (every Admin and Server frame ends with the clips it began with),
    tab_drain_sim.

96. **After beta 6: a code review and in-game QA of beta 6 (Claude on the director's Mac, on 42.21, another account,
    Nov 6 2026).** Every finding, with file, line, QA's check and a fix idea: qa/archive/REVIEW_BETA6_EXTERNAL_20261106.md. QA read
    the code and the 42.22.2 jar, no game run. The director's order for the next build, Nov 6: the first seven below. A
    dedicated server throws a font exception about three times a second for as long as it runs (in our own server log);
    safehouse invitations vanish, as the game's safehouse id differs by machine; every armed hit logs a Lua error; muted
    players still talk with /all, /s, /y and /w; safe mode leaves invitations with no answer; clothing cards read 0%
    protection. "Others can't tow" works on 42.22.2 and fails on 42.21: the two-argument call suits both. Any fix must run
    on both versions. Wheel RT: the director is fine with it, no change. Animals tab, confirmed in game at 4K and Deck: the
    Ranch page has no tab icons and no footer, the Admin bug again, since f59ffdc8 (beta 5 and 6). ZeD_WorldWindow.lua:4152
    clears extra clips for added tabs only. Picture: qa/archive/animals_ranch_rail_deck_20261106.jpg.

97. **After the beta 6a hot fix: what the outside review left (Build, Nov 6 2026).** All of 96 went in on main at a60c4472 except these. Too big for a hot fix: split-screen positioning and per-player server state; Death then Restart on ZeD's own windows; the getTextManager proxy. Narrowed: the Steam ID check still lets about 15 neighbors through. Code nothing calls: formatWeaponMeta and formatFluidMeta in ContextMenuRegistry. Small follow-ups: the Character window has coverClear and no drain, so Journal > Recipes under a card may lose its list; send every correctAndSaveModOrder through one filtered helper (Undo changes and Load after throw with an uninstalled mod listed, as in beta 6); clear KillTracker deadLog once a weapon kill counts, as a reused zombie can read as a fire kill; RADIAL_WHEELS_SPEC.md line 58 needs the centered start for Hold with Flick-release. Second-player checks are in the merge note to QA. Build, Nov 7 2026, for QA: the Character window now clears what a tab leaves on after it draws, as the World window does, counting the clips an item card's cover puts back. The fault was real: under a card, Journal > Recipes with a recipe picked left two clips on and the inventory list's one clear took off only one, so the list and all drawn after it would vanish. tab_drain_sim runs both windows' real drain over tabs with 0 to 3 clip pairs, a leftover clip and a throw, with and without a card. QA reads, at 4K 1.75x and Deck 1280x800 Auto: Character window > Journal > Recipes with a recipe picked and an item card open, category dropdown open too (inventory list, container strip and card stay); then Health, Skills, the Journal sub-tabs, Identity, Equip, Radio and Cooking with a card open (nothing beside the drawer flickers or stays gone).

98. **After beta 6: the survival guide's ads (the director, Nov 6 2026: "And with that, the ads are done. We can build
    a handoff").** 34 ads for the Full look's left-over pages and fillers (3 full, 7 half, 12 third, 12 quarter; the
    house ad joins the full-page rotation), each at most once per book, the NOTES block when they run out; Simple gets
    none. The handoff: HANDOFF_design_guide_ads_20261106.md (the Lua list, the slot changes in
    ZeD_SurvivalGuideBook.lua, the seeded deal, QA). The art: ZeD_design_refs/ads/final/ (2x PNGs, ink on
    transparent), to 42/media/textures/ZeD/guide/ads/. The plan and every round of notes: GUIDE_ADS_PLAN.md. Open for
    QA: whether 34 ads cover every slot at each text size.

99. **For the next beta: two small faults (the director, Nov 6 2026: "Wait for the next one. I really want to get this thing uploaded").** Not in beta 6a, as either would want a regression. Locks: padlocks and combination locks open in a full card; they should open in a half card. The Z menu: on the main menu, Z in the toolbar still shows version 0.1.1-something; it should show the current version.

100. **For later: EquipPacket in the server log (QA, Nov 6 2026).** "Wrong player connection index" repeats during multiplayer runs: 505 lines in one beta 6a run, mostly while teleporting, 302 in one run on Nov 5, so it predates the hot fix. See qa/archive/QA_BETA6A_20261106.md. Build, Nov 7, from the logs and the 42.22.2 jar: the client log has a matching "EquipPacket.set get invalid arguments" warning for each server line (217 each in the 22:56 run), starting seconds after the kit's /teleport. The client builds an equip message without a player (setData wants one IsoPlayer), so the server reads index -1 and drops the packet. ZeD never sends one: no sendEquip or equip packet anywhere in 42/; sendEquip does nothing on a client; the game's own hand update sends only for a local player with the right arguments. So the sender is game code we haven't pinned (IsoGameCharacter.tryPerformDropHeldItem is the one left in the classes read). Proof it isn't ZeD: the same teleport run with ZeD off; if it stays, it's the game's, for the TIS report.

## Test process

- **QA, Nov 2 2026, the t16 pre-upload pass (the mod code at 361d0b6; nothing in 42/ changed after it).** Full 4K
  regression 97 / 99, 0 fail, 0 timeout (qa/regression/2026-11-02_t16_4k.md). Two warnings, both seen before: wpt
  "8 hold A moved the hammer out of the crate" (hold A marks rows now, so the test expects the old quick use), and
  dke's dart "key reads start with the key in, engine off" with "the key never read START" (the same slip hit primani
  and race in t15pre_800L; a timing slip in the test, not the dash). Short 720 and Deck passes 4 / 5 each, the one
  warning the same wpt line (2026-11-02_t16_720_short.md, _800_short.md). Staged with stage_workshop.ps1 into
  Workshop/ZeD-UI (item 3824968485, QABridge and TestInventory left out). The staged Contents folder shadows the dev
  mod: remove it after the upload. **Uploaded Nov 2 2026 (the director); tag v0.2.0-t16 at 6ab5413 (game code as tested at 361d0b6), backup D:\ZeD-UI backup\2026-11-02-t16 (QA save, zed_backups, workshop.txt + preview.png), Contents removed by the build session.** Restaged by the build session with -Version 0.2.0-t16 (the mod list
  read 0.1.1242300k before), and the description's version line now says "shown in Mods" only: the desk's About
  row shows the game's build, not ZeD's. Every upload: stage with -Version 0.2.0-tN, and write that build's
  tester_description into Workshop/ZeD-UI/workshop.txt (staging keeps the old one).
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

Items QA has confirmed in the game in full (their history stays in place above; Nov 2 2026, build's tidy, item 75):
2, 3 (one gap: the ham at 1.5), 18, 19, 21, 22, 23, 24, 25, 27, 28, 30, 31, 32, 33, 34, 35, 36 (its first fixes), 37 and
41 (by script; hand checks open), 39, 40, 42 (its a-f), 43, 44 (but the column rule), 45, 46, 48, 49, 50, 52, 53, 55, 56,
65, 67, 69, 70, 77. The beta items' states are on each item under "## Beta".

101. **After beta 6a: the second outside review (QA, Nov 7 2026; qa/REVIEW_BETA6A_EXTERNAL_20261107.md).** Medium: every weapon
    kill filed as an explosion and the Journal header counting it twice (KillTracker.lua:154, JournalTab.lua:393; checked by
    bytecode on 42.22.2). Low: firearm facts throw in formatFirearm (ItemCard.lua:86, AmmoType object); ZeD picks left off
    when ZeD-GUI is switched off and on; a held second Accept says the invitation is gone; a release plus re-claim logged as
    an owner change. Design for the director: Check stats and the Admin tab's other game windows are still the game's UI.
    The director, Nov 7 2026: "Next beta" (no beta 6b for these).

102. **The next beta, built overnight Nov 7 2026 (Build, while the director slept; QA testing each merge).** On main:
    the ads (98) at 9f0c211b; the fixes at a60a0399 (101 in full, 99, 97's leftovers, 95, the book card's Progress row from
    QA); the dashes (92, 94) and the house ad fit at 44df3931. Each part reviewed by separate reviewers; all 20 sims pass.
    Not built: Check stats on a ZeD card (the director's call), police radar (93), Roadworthy wiring (QA hasn't run it).
    - **For the director:** (1) the guide's thirds run short: 19 to 30 third-size feet per book get NOTES, and at Large
      text some halves and quarters go unused and two whole pages get NOTES (QA's counts, 4K, Nov 7): more thirds, or
      let the smaller feet take halves or quarters? (2) The First Days checklist never prints at Small text (no First
      Days page has a third free), as before the ads. (3) Old characters' Explosion kill count (mostly mis-filed melee and
      gun kills from beta 6a) moves to Other once; easy to drop before upload if not wanted. (4) The Identity tab shows the
      game's own kill count (as vanilla's Character Info), which leaves out fire kills; the Journal adds them. (5) The dashes draw the key at OFF while it sits in the lock, but a key in the lock powers the
      electrics (the game has no separate ON), so every lamp lights in the bulb check with the key drawn at OFF (QA, Nov 7):
      draw the key at ON whenever it powers the dash?
    - **The director's answers (Nov 7, morning):** (1) "Sure, use more third size ads": 32 more thirds, lineup in
      GUIDE_ADS_PLAN.md (Batch 5); whole pages with no full ad left now take a half or quarters and a third before NOTES.
      The director also asked whether the contents page runs too long or needs more than one page (measured, see below).
      (2) "I want the text to print": the First Days checklist prints once at every text size. (3) "Do the most
      accurate thing" on old Explosion counts. (4) Identity and Journal kill counts "should match". (5) The key in
      the lock, engine off, is in accessory mode: an ACC position to the left of OFF, the key drawn there; ON when
      running.
    - **Built and on main (Nov 7, 352d9df3), each reviewed twice, all sims pass:** the thirds' pictures wait for
      another day (the director: "Gaps can print as notes as before"). The First Days checklist prints once (a filler
      with room, else its own block at the chapter's end); whole pages past the full ads take a half or pair and a
      third. The contents runs onto as many pages as it needs ("2-3 pages, however many pages it needs"), whole rows,
      long blurbs wrap; with an even count the page before the introduction is the publisher's house ad (the
      director's pick), never dealt again. One total (KillTracker.total) for the Identity tab, the Journal and the
      death screen; old saves' rows rebuilt from the game's count (the old weapon rows were hits, not kills) so they
      add up to it. ACC on all 18 key dashes, the key at ACC with the engine off, ON running, START cranking; the
      Simple dash says ACC (the race car's switch still says Off). The offline card's role row wraps (296d3a91).
      Gallery spread 46 needs a new capture (the contents spread changed). Not yet run in game.
    - **Known gaps:** ZeD picks come back only when ZeD-GUI is turned on by its own row, not through a folder or
      separator box or Turn all off; split-screen's second player doesn't save dash miles on a server; on a server the
      dash ash tray is per player and session; FR and HU month words keep a capital (shared Journal keys; native pass).

103. **The survival guide's copyright page (the director, Nov 7 2026: "I want to do a similar for the survival guide, make
    sure the writing style is the same").** Like the znix manual's title spread: the copyright page left of the title
    page, in the blank's place, the small print set low, line for line the znix page's text with the guide's names;
    "Publications LLC both" (the division gets LLC on the copyright page and the title page); first edition 1984
    ("Copyright © 1984, 1987"). The text, keys and layout: HANDOFF_design_guide_copyright_20261107.md. Open: whether the
    house ad's coupon address takes the LLC too.
104. **The desk's notes and mail (the director, Nov 7 2026, for later, not beta 7).** Two apps on the main menu's desk
    computer. (1) **Notes:** a sticky note on the desktop the player can edit, or text files they make that save on the
    desktop. Doable in Lua alone: ZeD already writes its own files under Zomboid/Lua (getFileWriter), so notes would
    live there, per player, and survive updates. Uses: server addresses and passwords' hints, seeds and sandbox picks,
    mod lists, a run's plan. (2) **Mail, for multiplayer:** players and admins write to each other outside a world.
    Engine limit: Lua has no network of its own, and at the main menu the game is connected to no server, so nothing
    can be sent or fetched from the desk itself. What can work: mail kept on the server, sent from inside the world
    (also to offline players) and handed over when they join; the desk shows the mail last received from each server
    (a copy saved on the player's PC) and queues replies that go out on the next join. Nobody found doing either
    (Build's search, Nov 7: nearest are in-world note mods, a mod-update alert on the main menu, an answering-machine
    mod); design is the director's own either way. The director's picks (Nov 7): notes as both, one sticky note
    always on the desktop plus a notepad whose files sit as icons on the desktop; mail as described (server-kept,
    read on the desk, replies sent on the next join). The director: "email back then, you would dial in to connect,
    to send and receive. So most of it was done offline." So joining a server is the dial-in: the outbox goes and the
    inbox comes on connect (a modem-style send/receive moment is the design's to decide); reading and writing are
    offline on the desk. The notepad's name (the director, Nov 7): **CletusWorks**, after ClarisWorks (1991, the
    all-in-one on every school Mac in 1993): the desktop icon reads CletusWorks with a page-with-writing picture, the
    window title "CletusWorks Notepad", so the joke is there for those who know and the plain word for everyone.
105. **The gallery for beta 7 (the director, Nov 7 2026: "Anything out of date there we should update before we upload
    the next beta at 1pm PST"; "Why alt tab to a wiki when you could F1 to live rules and data? That needs to be on the
    46 survival guide").** Before the upload (design, not committed): 52's two arrows that missed since the Nov 6 retake
    now land on Ask the admins and Turn PvP on, its paragraph follows the Server tab's order, and both figure captions
    clear the prints; 46's right-hand sticky is the director's line, and Figure 46-2's caption clears its tape. After
    the upload, QA's retakes: 36 (the taxi with ACC, the odometer and trip), 61 (the Simple dash's Trip cell and ACC),
    05 and 14 (optional), 46 (two pages with ads; the copyright spread once 103 is built), and about 15 captures for new
    multiplayer spreads (tickets, the Player card, the join rules, the safehouse and faction cards, invitations, the
    Log, chat report and mute). Where the new spreads go is the director's call. HANDOFF_gallery_beta7_20261107.md.
106. **The debug Lua console in ZeD's own parts (the director, Nov 7 2026; next in the queue after the current one
    merges).** The game's debug-mode console (only with -debug: run Lua, read errors and output) rebuilt from ZeD's
    atoms and molecules as a ZeD window: the typed line, history, the output and error list, controller parity (the
    pad keyboard), safe mode hands back the game's own. Find the game's console class and what it offers first.
107. **Split-screen: ZeD's own windows for every local player (the director, Nov 7 2026: next, before Dec 1).** The Nov 8
    build gives player 2+ the game's own windows (no sharing) and a belt and dash each. Next: FocusManager,
    BumperChord and InputModeDetector per player, then one Character and World window per player placed with
    getPlayerScreen*(pn), then the ~105 no-argument getters; the player-1 map is in the known-issues branch report.
108. **A drawn controller for Options > Controls (the director, Nov 7 2026).** The Nov 8 build ships the controller map and
    live test with a plain System 7 box pad; design draws a proper pad in ZeD's pixel art to replace it.
109. **What players leave the game to look up, and what ZeD still owes (the director, Nov 7 2026: "Put the gaps on the
    punch list. This is awesome.").** From the director's research report, RESEARCH_alt_tab_lookups_20261107.md: players
    alt-tab mostly for crafting and the map, then the exact numbers behind the character (moodles, XP, what a skill
    level unlocks), then what the game hides on purpose (the TV schedule, infection odds, loot). Its split is ZeD's
    rule: what the game shows badly, ZeD shows well; what it hides on purpose stays the game's to give. Already done:
    the crafting card names most of Build 42's gates (Known or Unknown with How to learn, Needs, skill level, Use
    station, the Surface badge), skill cards show exact XP, sandbox settings say what a change does, and the guide reads
    its rules live.
    - **What can I make with this,** on the item card: the recipes that use the item. Design found no such list in the
      strings or the client code; Build confirms. It is the feature behind Craft Helper and Neat Crafting, the two
      biggest information mods.
    - **What each skill level unlocks,** on the skill card or a rules page.
    - **Moodle thresholds,** a rules page of the game's own numbers.
    - **The hidden facts open with a find (the director, 6:00 PM):** "I can show you the TV schedule, but you have to
      find the TV magazine first." The guide says what more it could show and what to find for it. The game already has
      the magazine: Magazine: TV Monthly (Base.TVMagazine), on side tables, desks and counters, in closets and bags. By
      preset (the director: "It's the difference between hardcore vanilla and vanilla access"; 6:05 PM: "Vanilla plus
      gates them. Only vanilla access. Vanilla access is a mode with less mechanical barriers and more automation." and
      "It's like accessibility and all access behind the scenes all in one."): Vanilla and Vanilla Plus keep the facts
      behind the find; only Vanilla Access shows them without it; a ZeD setup addition holds the choice for Custom.
      Build finds where the game keeps the schedule (its broadcast scripts) so the page reads it live, like the rules
      pages. Open: whether the find is reading the magazine (as with recipe magazines) or carrying it; which find opens
      the infection odds (prefer what the game already spawns: a new item adds loot, a systems change). Never a live
      "you are infected". Design proposes the same split for where a recipe is learned: Vanilla and Vanilla Plus say
      "Find recipe magazine or schematic", as now; Vanilla Access names the magazine.
    - **The map:** the Maps tab and paper maps keep the game's own reveals; later map work stays to the look, the key
      and readability.
    - **Pause when the window loses focus** (characters die while their player reads the wiki): Build checks whether Lua
      can see the game window's focus; if it can, an opt-in single-player setting in ZeD setup.
    - **For the Workshop page:** on a controller, alt-tabbing means putting the pad down for the mouse, so an in-game
      answer is worth more to pad players. Pairs with spread 46's sticky, "Why Alt-Tab to a wiki when you could F1 to
      live rules and data?"
    - **QA:** the Full-look guide at 1366 x 768 (small screens were the first casualties of the vanilla crafting
      window).
110. **One phrase for the two forms (the director, Nov 7 2026: "can we come up with a common phrase? It seems like each
    has a different word. Some of them have the same, but I think that could confuse some players.").** Today ZeD
    setup's *Full or simple* rows say Full (Belt, Devices, Watch, Dashboard, Survival guide, Mods screen) and Verbose
    (Action bar), the Identity card says Immersive in Look, and Context menu (Icon strip / List) and Equipped items
    (List / Doll) sit in the section too. The director's picks:
    - **Immersive / Simple** on every row drawn either as the thing itself or as a plain card, and the section renamed
      *Immersive or simple*: Belt, Devices, Watch, Dashboard, Survival guide, and the Identity card, moved in from Look.
      All six take the one key UI_ZeD_Settings_Immersive (five borrow UI_ZeD_Settings_BeltFull today), and each help
      line reads "Immersive: ... Simple: ...".
    - **Detailed / Simple** for the two rows whose rich side is more information, not a thing drawn, and both move out:
      the Action bar to HUD (Verbose becomes Detailed), the Mods screen to Windows (Full becomes Detailed).
    - **Context menu and Equipped items** move to Windows, next to Inventory (List / Grid): they choose a layout, not a
      form.
    - **Strings:** UI_ZeD_Options_ZedForms; the Belt, Devices, WatchStyle, Dash, Guide, ActionBar and Mods tips;
      ActionBarVerbose; the guide's ZeD setup chapter (UI_ZeD_GCh_zed_setup_Title and _Text) and the beta 3 what's-new
      line. Every language, as the project's labeled AI drafts. Saved choices keep their values: no option changes its
      place in its list. The presets don't change (Vanilla Access still picks Simple).
    - **Then the gallery (design):** 12, 26 and 31 say Verbose; 46 says Full; 48 lists the sections; 61 is the whole
      spread, with a new capture of the section.
111. **Minimal Sidebar works with ZeD's belt (the director, Nov 8 2026: "Make it work"; after the light week).** QA's
    test of Belisar's three mods (ZeDUI/qa/COMPAT_BELISAR_20261108.md): no errors, nothing handed back, but Minimal
    Sidebar has no effect: ZeD's belt wraps the sidebar render, so the mod's fade never hooks a button (0 of 14). Give
    the belt a hook so the mod's fade (and its settings) apply to ZeD's belt; HOOK_MAP row and a QA script with the
    mod on.
112. **Dual pinning: each half of the Character and World windows rolls up and pins on its own (the director, Nov 8
    2026, from FAIV's report on pinned windows in combat; build now).** "Each window needs to have dual pinning. So each
    half rolls up independently, and each half can be pinned independently on each window. Clicking on a tab, or
    clicking on the inventory tab still folds the tabs in, though." Rulings: a pinned half stays exactly as it is (no
    aim or click override); the inventory side and the tab drawer side each auto-roll with the pointer (2 s after it
    leaves, or on aim) unless that half is pinned; one pin per half, each in its own part of the title bar; on aim the
    unpinned half rolls and the pinned half stays; on a pad both pins are stops in the focus ring, A toggles. Example
    that must work: the World window with the map tab pinned open while its inventory side and the Character window
    roll with the pointer.
113. **Beta 9: the rest of the Mac rig's outside review of beta 8 (the director, Nov 8 2026: "Hotfix the two, then add the
    rest to b9").** ZeDUI/qa/REVIEW_BETA8_EXTERNAL_20261108.md items #3-#18 and its review-only list; #1 and #2 ship
    as hotfix 0.3.0-beta8a. #9 stays (the Nov 7 ruling). #14: Follow Metric (the odometer and trip show km with KM/H;
    display only). Being built on a branch off main.
114. **The main menu desk's sticky note can be dragged and closed (the director, Nov 8 2026, beta 9).** "Being able to
    drag the note around to other spots on the desktop or close it would be nice." Drag it anywhere on the desktop with
    its place kept, a way to close it, and a way to bring it back. Design questions (where the close sits, how it comes
    back, controller) go to the director as multiple choice before building. Ruled Nov 8: a small X close box in the
    note's corner (System 7 style); a 'Show note' item in the desk's menu bar brings it back where it last was; on a
    pad the note is a stop, A picks it up, the D-pad moves it, A puts it down, Y closes it.
115. **Bug reports hide the player's account name (the director, Nov 8 2026: "Hopefully yes"; beta 9).** ZeD_Messages.lua
    reportHeader / report / reportOne / reportAll and the Messages window's Copy / Copy all replace the Windows user
    folder (C:\Users\<name>\ and the forward-slash form -> ~\) and the Zomboid folder (getMyDocumentFolder -> ~/Zomboid)
    before copying. Ruled wording ("Plainer"), shown in both places, the copied report's last line and beside Copy:
    "Your user name is taken out of this report. Files like console.txt still have it: look them over before you post
    them." Every language as the project's labeled drafts.
116. **Ellie's Tattoo Parlor V4 with ZeD's Make Up rows (Mac rig compat retest, Nov 8 2026; beta 10 unless the director
    says sooner).** ZeD's Make Up rows read the mirror rule through the game's make-up menu; the mod's patch of that menu
    (ETPMakeUpUIFix.lua:9) errors on ZeD's stand-in item, so ZeD falls back to "needs a mirror". From code reading. Give
    the stand-in what the mod's patch reads, or read the mirror rule without the patched menu.
117. **[B42] Custom Map Labels reads the game's map at start (Mac rig compat retest, Nov 8 2026; beta 10).** One error at
    game start (CustomMapLabels.lua:93): it opens the game's map to read labels, ZeD opens its own map instead, so the
    labels are never read. Let the game's map object exist for a mod that asks, or guard, and show its labels in ZeD's
    map if possible.
118. **Context menu tooltips on brand and sized to their text (the director, Nov 8 2026; beta 10).** "Tooltips in the
    context menu are not on brand. They look like modern web stuff. That and text does not fit in the box." The hover
    tooltips on menu rows (ZeD's strip and list styles, and the game's option tooltips as ZeD draws them) follow System
    7.1.2 Balloon Help per the Visual Catalog v2.0, and the box is sized to the wrapped text measured at the current
    scale and text size, never spilling. Read the Visual Catalog first; a before/after mockup to the director before
    building. QA: every theme, Large text, 4K and 1280x800, long DE and RU strings. Design's before/after mockup and spec (Nov 8): mockups/zed_tooltips_balloon_v1.html, it covers 119 too. Approved by the director Nov 8 ("That's the one") with text-safe status colors (new tokens), the tooltip picture in and a 10-cell tail: HANDOFF_design_tooltips_balloon_20261108.md. Must-fix part (the director, Nov 8:
    "Beta 10, not beta 9"): the requirement tooltip on a greyed-out option (World menu > Disassemble) keeps the game's
    red/green per requirement and its two columns, and shows the list once (ZeD drew it colorless, columns collapsed,
    twice). A fix is prepared on its own branch; it merges after beta 9 ships.
119. **The context menu strip's overflow arrow boxes in the accent color (the director, Nov 8 2026; beta 10).** "The
    color behind those arrows is always black, and it's hard to see. Let's make that box ... the accent color." Both
    end boxes fill with the accent; the arrow is drawn in a contrasting color, readable in every theme and accent.
120. **The heavy drawers draw as cheaply as Loot (the director, Nov 8 2026: "Equipment, thermal, identity, skills,
    twice as long to draw as loot? We should address that. In beta 10.").** At 4K 1.75x with pinned windows they read
    about 16-18 ms per tick against Loot's 9-10 (since about Nov 2). Target: near Loot's ms, measured with pnw before
    and after on the same manifest (ZeDUI/tools/qa/b9_perf.txt). A suite_perf run without pnw is invalid.
