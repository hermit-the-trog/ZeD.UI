# ZeD release test (Nov 18 2026)

The director, Nov 18 2026: "We're not releasing the next beta until you build a new test." This replaces the old main
run (ZeDUI/tools/qa/main_run.txt), which grew one feature at a time since October: 26 of its 85 scripts checked
nothing, and a script's own FAIL lines scored only as warnings, so real faults passed as "11 warn, 0 fail".

## The rules

- Every script is new, built on `ZeDUI/tools/qa/rt_kit.lua` (the global RT). Every check prints `PASS` or `FAIL`.
  Any FAIL makes the script's verdict line `VERDICT FAIL n`, and `zedqa_run.ps1` scores that as the script's FAIL.
- It checks what ZeD ships, the way a player reaches it: the mouse handlers, and FocusManager's pad path where ZeD
  has one. Nothing checks a window the game draws itself. No pictures (the gallery runs take pictures).
- Every surface a script opens is measured: `RT.bounds` fails any ZeD window, card or pop-up that is not fully on
  screen. The whole test runs twice: 4K at 1.75x, and a true 1280x800 window (the Deck).
- Each script puts back what it changes and takes back what it gives.
- A check that cannot run on this save says SKIP with the reason (a farm, a server); a SKIP is listed in the report.

## The features and their checks

| Script | Features | What PASS means |
|---|---|---|
| rt_windows.lua | Character and World windows, every tab on both strips, drawers (half and full width), curtains, window places | Each window opens and closes by mouse and by the pad's Y; every tab on each strip opens, draws, and holds no error; a drawer is 220/260 or 480 wide, nothing between; a curtain rolls and unrolls back to the same box; each tab on screen |
| rt_inventory.lua | Inventory list and grid, sort, filter, stacks and their weight, moving things, container buttons, box select | List and grid both draw every item; each sort key orders as named; the filter hides and shows; a stack opens and shows its total "(n)"; an item moves between containers by drag and by Move To, and the counts agree; Loot all and Drop all do what they say |
| rt_cards.lua | Item cards and their verbs, the facts, object cards, stations | A card opens from a row (mouse) and from A (pad), half or full width; Eat, Equip, Read and Drop act through the game's own actions; the facts show weight and condition; the object cards for a stove, fridge, generator, laundry machine and fire open and show their state; a station opens its card |
| rt_menus.lua | The right-click menu (strip and list), its icons and submenus | The menu opens on an item, in both styles; every row has its icon; a submenu opens; a pick runs the game's own option; the menu stays on screen |
| rt_hud.lua | Belt, hands, watch (mini and full), action bar, moodles' places, bubbles, the "+XP" note, foraging pins, the guide bubble, the hint strip | Each HUD piece draws in its place and is on screen; the watch opens full from the mini; the action bar follows a real timed action and clears; moodles sit in each of the three places; a bubble shows and fades; the foraging pin and its hand show over a find |
| rt_vehicles.lua | Dashboard, car radio, seat chooser, siren, the Vehicle tab | In a car with the key in: the dash draws its gauges and lamps; the radio turns on and tunes; the seat chooser lists the seats; the siren plate in a police car; the Vehicle tab lists the parts |
| rt_media.lua | Radio tab, two-way, TV, CD player, Maps tab (styles, notes), Journal (lists, readers), the reader, writing a note | Each radio face turns on and tunes; the Maps tab draws each style and a note is added and removed; the Journal lists flyers and notebooks; the reader opens a notebook; a written note keeps its text |
| rt_pad.lua | Focus, D-pad wheels, quick chords, quick wheel, put back, the pad's item card, placing an item by pad, the pad figure | Focus lands on the first item and moves by the D-pad; each wheel opens and a pick acts; a chord acts; the pad card follows the focused item with no stale frame; an item is placed by pad; the button map page draws the pad |
| rt_system.lua | ZeD setup (options), UI scale, themes and accents, safe mode, step-aside, Messages, translation, a short soak | Each ZeD setup group opens and a change saves and comes back; each UI scale step and each theme draws; safe mode trips, hands back to the game's own pages, and recovers; Messages keeps another mod's note; every UI key ZeD reads has text; ten minutes with no error and no growth in memory |
| rt_addon.lua | The add-on hooks (grid layout provider version 2) | A stand-in provider's shapes are drawn as shapes, its drag ghost is its mask, and its labels sit on the picture's square |

Out of the in-game test, with their own runs: the main menu (zedqa_menu_mods_run.ps1), multiplayer (the server kit),
animals (no farm on the save), the compat set with other mods.

## So it never drifts back (the director, Nov 18 2026)

"We're not going to go through a QA session 2 weeks from now, and I'll be like, well, there's that test again." The
rules are in the tools, not only in notes:
- The old list is retired: `ZeDUI/tools/qa/retired/main_run_retired_20261118.txt`. Nothing runs it.
- `zedqa_run.ps1` fails any release-test script that prints no PASS or FAIL line ("checks nothing"), and any script
  whose own checks failed ("VERDICT FAIL"). A picture-only script cannot pass.
- A new feature's check goes into the rt_ script for its area, on the kit, with PASS / FAIL. Never a new picture
  script, never a check of a window the game draws itself.
- A check that turns out wrong is fixed in place or removed, the same day, with the reason in its comment.

## Running it

    pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Manifest ZeDUI/tools/qa/release_test.txt -Mode fullscreen4k -Report release_test_4k
    pwsh -File ZeDUI/tools/qa/zedqa_run.ps1 -Manifest ZeDUI/tools/qa/release_test.txt -Mode windowed -Width 1280 -Height 800 -Report release_test_deck

A beta goes out only when both runs are all PASS.
