# QA checklist for the beta (0.3.0-beta1)

Approved by the director, Nov 2 2026 (punch list 74). QA runs it, and both sessions refresh it after every build.

Testing runs at 4K, the director's own screen. The Steam Deck and 720p are checked only where an item says so, and once in the full pass. "Done" means QA has seen it work in the game.

There are two passes.

---

## Pass 1: after each build (about 15 to 30 minutes)

Only what the build changed, plus the release check.

1. **The release check** (about 2 minutes, pass or fail): `pwsh -File ZeDUI/tools/qa/release_check.ps1`
   - Both windows open.
   - An item moves to the floor and back, and both windows list it.
   - A real right-click on an inventory row opens the item's menu.
   - The controller: A on a row opens its card, and B goes back to the row.
   - A worn watch reads the game's time.
2. **The build's own checks.** Build lists them with each build. QA writes each result under its punch list item, with pictures where the director has to look.
3. **The scripts that cover what changed.** One run of the areas the build touched (the table below), not the whole list.

| The build changed | QA runs |
|---|---|
| The windows, tabs or lists | the tabs, grid and sort scripts and the two widths |
| Item cards or menus | the card verbs, the menu and its icons, and the one-path fixes |
| The controller | the pad map, the focus landings, the World window pad pass and the marks |
| The belt, watch, moodles or action bar | the belt, watch, hands, moodles and Simple belt scripts |
| Radios, TVs, appliances or laundry | the radio, two-way, appliance and laundry scripts, with faces and with plain cards |
| Cars or dashboards | the dashboard scripts with Full and with the Simple strip, and the car radio |
| The Vehicle tab (mechanics) | zedqa_mech79 (release_check.ps1 -Manifest mech79.txt; VEHICLE_TAB_SPEC.md section 8, punch list 79) |
| The Cooking tab | zedqa_cook80 (punch list 80) |
| The wheels or quick actions | the wheels, D-pad wheels and chords scripts and the controller map |
| The main menu, Options, Mods or Sandbox | the main menu scripts (About, Options, page lists, Mods) |
| Words or translations | the translation guard, plus the test language on the changed screens |
| Settings, safe mode or scale | ZeD setup, safe mode and screens, and the scale steps |

---

## Pass 2: before a release (about 3 to 4 hours, top to bottom)

Run when the director is ready to push a release. Every line passes. A failure is either fixed and checked again, or the director accepts it as a known issue for the page's Known issues section.

### A. The release check
The five-minute check above.

### B. The full run at 4K
All 99 scripts in `regression.txt`, in one run. Done means no new failure since the last full run, with every warning explained. The groups:

- the windows and tabs (every tab, the curtains, the two widths, the scale steps);
- item cards, menus, the grid and sorting, the doll and loadouts;
- the controller (every tab's paths, the focus after every action, the World window pass);
- the belt, buckles, straps, watches, hands, moodles and Messages;
- maps, flyers, the Journal, the reader and notebooks;
- radios, TVs, two-way sets, appliances and laundry, as faces;
- cars: the dashboards (all designs), car radios, seats and the lightbar;
- the wheels, D-pad wheels, button pictures and quick chords;
- safe mode, the test language, and the soak (every tab for 12 rounds at full speed).

### C. The simple versions
The same areas with every Full or simple row on Simple: Belt, Action bar, Context menu, Equip view, Devices, Watch, Dashboard. Each simple form does what its full form does. Switching back is instant.

### D. The old checklist (items 4 to 16)

| Old item | How it's checked now |
|---|---|
| 4. Disclosures open and close | **new script to write:** every disclosure in every tab, opened and closed, with a picture of each open |
| 5. Pictures with everything open | the gallery pass at release, disclosures open |
| 6. Every button does what it says | **new script to write:** a census of every button in both windows and its result |
| 7. Hover holds steady | the real-mouse pass (hover on each kind of control, a recording checked for flicker) |
| 8. Controller only | covered by B (pad map, focus landings, World window pass) plus the controller map |
| 9. Keyboard | the break-it keys and typing pass: Escape closes things, typing in a field never moves the character |
| 10. Save and reload | **new script to write:** settings, window places, theme and loadouts survive a quit and reload |
| 11. Themes | the visual audit in dark, light and high contrast with every accent, Normal and Large text |
| 12. Odd cases | the stocked deep-run character (hundreds of items, long names, broken and full things) plus the break-it edges |
| 13. Window sizes | the window edges pass: smallest and largest, both windows |
| 14. Errors | the console report of the full run: no new errors from ZeD |
| 15. Speed | the speed suite and benchmark: no tab slower than the last release |
| 16. Other mods | the Supported and Works well mods on together, with the covering scripts |

### E. Small screens, once
- The short pass at the Steam Deck size and at 720p.
- The release check at the Deck size.
- Any screen changed since the last release, at the Deck size with Large text.

### F. The main menu
About shows ZeD's version. Options and ZeD setup work, including the Full or simple group and the presets. Mods works with 1,500 mods: folders, separators, find, load order rules and page lists. Sandbox and the in-game Sandbox page list work.

### G. Languages
For each language ZeD ships (Turkish, Simplified Chinese, Brazilian Portuguese), with the game set to that language:
- no raw word keys anywhere;
- the language list marks it as a machine translation;
- the pixel faces draw its letters.

The language goes back to English after.

### H. The upload
- Staging sets the version, writes the page text and change note, and puts the preview in place.
- The staged copy matches the tested code.
- The release check passes on the staged copy, the last thing before Upload.

---

**Still to build before testing starts:** the disclosure walk (old item 4), the button census (old item 6) and the save-and-reload check (old item 10). QA builds them once the director approves this list.
