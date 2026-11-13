# Beta 12: ready for your go (Nov 13 2026)

Beta 12 (0.3.0-beta12) is staged for Workshop item 3824968485. **Nothing is uploaded or posted.** It goes up when you say so.

## What's in it

The change note is `ZeDUI/workshop/tester_changenote_0.3.0-beta12.txt`. The Workshop description is `ZeDUI/workshop/tester_description_0.3.0-beta12.bbcode`. The headlines:

- **Console:** a bigger Lua console with a Log page, Scratchpad, name suggestions, Commands and Help. The same console also ships as its own mod, Lua Console 93 Professional Edition.
- **Split view groundwork:** ZeD keeps its windows per player. Players 2 to 4 still get the game's windows.
- **Pad map:** your controller drawn in Options, with a live button test.
- **Run+sneak:** in ZeD setup, off by default. Run also sneaks.
- **Bug fixes:** Simplified Chinese, defense math, recipe skills, Health's Overall and the moodles, plus small ones.
- **One set of rules:** the design review rulings. "Unread", "Label: Value", the Status column, tab titles, sub-page tab strips, solid Light and High Contrast windows and shared row sizes.
- **New:** Filter, the Fishing tab, animal quick actions, Journal tags, saved position and the Mods Files tab.
- **Cars:** three cabin colors. **Main menu:** a new poster. **Mods:** Summer Car and Skill Recovery Journal.

## What QA found overnight, and what was fixed

QA ran the full release pass. It found one blocker and four smaller real bugs, and all five are fixed:

1. **Blocker:** the Vehicle tab threw an error on every frame once a car was in view. It came from the new per-vehicle tabs, and it is fixed.
2. A print showed as two rows in both consoles. Fixed.
3. The item card cut off a long Kind ("Household / ..."). It now wraps to a second line.
4. On a long recipe list, a click on Category, Sort or Show opened a hidden recipe instead. Fixed.
5. A click on the left edge of the radio's Full view button did nothing. Fixed.

QA reran everything those bugs touched and all of it passed. There were no errors in the game's log. Summer Car works in full: the engine window opens beside the Vehicle tab and stays put.

**No real bug is open against this build.** The last check, hovering a Vehicle tab parts row to light the part on the diagram, works. It only failed inside the long runs because an earlier test left the controller as the last input.

**Needs your hands, not checked by QA:** the real controller on the drawn pad and run+sneak, Shift+Enter in the scratchpad on a real keyboard, and Lua Console 93's suggestions while typing. Chat dimming in Light needs a server. Animals are still parked.

## Your choices

1. **Upload beta 12?** Yes now / Hold.
2. **Dashboard lettering:** QA found some small dash words hard to read. These include pale captions on the grey police dash, light text on the tan cabins and the "D-PAD RIGHT" hint. Darker ink now / Leave for design next cycle.
3. **Strip under the title bar at Small text:** Keep Small as is / Make Small shorter.
4. **Focus look:** the default pointing hand shows only a faint wash on the row. Keep the faint wash / Add the full accent fill.
5. **Reading status words:** "Read: Not yet" / "Unread".
6. **Lua Console 93 box art:** design still needs to re-export the box with hyphens in place of the middle dots. Its Workshop page also waits for your approval. Ship Lua Console 93 with beta 12 / Next day.

## The upload, when you say go

Paste the usual SteamCMD line in Terminal 1, using your saved login, with the upload file Build already wrote:
`$env:TEMP\zed_upload_3824968485.vdf`.

Then Build tags v0.3.0-beta12, and the beta 13 cycle opens with its corkboard note.
