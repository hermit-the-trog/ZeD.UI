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
2. **The radio drawer is full width; it was designed half width.** chosen (Oct 30): with item 3.
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
3. **Plates at every scale (design first).** chosen (Oct 30), with Design. At 4K on 1.75 the 336
   pixel plates sit small in their cards. Rule: scale scales everything. Choice: each plate re-laid
   at four widths that fill the full card, 336 (0.75, 1.5), 392 (1.75), 450 (1.0, 2.0 and up), 562
   (1.25); the game draws the widest that fits (85-100% between the listed scales); 0.5 dropped;
   the 200 pixel narrow faces stay for Auto on 720 or 800 high screens with the smallest font.
   Request: `ZeDUI/REQUEST_design_plates_fill_20261030.md`. The test checks the right width loads
   and fills its card, crisp, at every scale.
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
20. **A dimmed row takes no hover highlight (director, Oct 30: "Yes, no highlight").** chosen.
    Found by QA in item 19's check: with Loadouts off, the dimmed Restock row still lights up under
    the pointer although it takes no click. Choice: no hover highlight on a dimmed, inert row (the
    help line still says why when the pointer rests on it). Build to say whether the same goes for the
    other dimmed rows (settings that do nothing with ZeD active). Still open: Restock's "Access" cut
    short at some window widths; the preset buttons' short names (no choice yet).

## Test process

- The release check (before every upload, about 5 minutes, pass or fail): right-click opens the
  menu, both windows open, an item moves, the controller works, the watch reads the time. Not
  built yet.
- The full pass's own problems (found in the t13 run, Oct 30): world_pad_take depends on where
  the Eraser sits in the QA character's bag; two_widths depends on the test before it leaving a
  card open; dash_green's fire truck won't pass 2 km/h at the drag strip; px_icons has a first-run
  fluke. The dashboards take 15 of the pass's 57 minutes. The QA save drifts between runs.

## Confirmed

(none yet)
