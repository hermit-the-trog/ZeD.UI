# Load order tools: Find, pins, load before / after (draft, Oct 31 2026)

Plain rules for the director before anything is built. Asked for by a player who keeps almost 1,500 mods (Workshop
comment, Oct 31 2026: searching the load order, load first / last, load before or after a chosen mod); the
director: "I want the mod manager to really shine, so let's try and accommodate their request."

This extends `docs/specs/MOD_FOLDERS_SPEC.md` (folders on the Mods page, separators on the Load order page; read it
first: its sections 7, 8 and 10 are assumed here). Mockup: `ZeDUI/mockups/zed_mod_folders_v2.html` (PNGs beside it;
it keeps v1's folder scenes and adds the load order scenes). Screen as built today:
`42/media/lua/client/ZeD/ZeD_MainMenuMods.lua`.

Designed from what a player with a very long list needs: find a mod's place, keep a few mods at the ends whatever
else changes, and put one mod next to another without dragging it past hundreds of rows.

## 0. What exists today (audit, Oct 31 2026, ZeD_MainMenuMods.lua as on main)

1. **Find** is on the Mods page only (plain text over name, mod id and Workshop number, cached while the tab, the text
   and the records stay the same). The Load order page hides it (`find:setVisible(false)` for every page but the
   list). The Find field has no controller stop on any page: it is reached by mouse only.
2. **Moving a mod** on the Load order page: one place at a time, by Move up / Move down in the right pane (mouse),
   Y / X on the pad. No drag, no "to the top / bottom", no keyboard move (Up / Down only move the focus). A on a row
   does nothing ("a row only picks"). The wheel scrolls; there is no scroll bar on this page.
3. **Auto** is vanilla's own sort (ModLoadOrderPanel's autoSort, rebuilt as `ruleOrder`): by mod id, each mod's
   loadAfter and requirements pulled in before it, its loadBefore after it.
4. **The order check** per row (`orderStates`): **bad** (red) when a mod it needs loads later or is not in the list;
   **soft** (yellow) when one of its own loadBefore / loadAfter wishes is not kept; **ok** (green) otherwise. Done is
   greyed while any row is red. The right pane lists the picked mod's needs / loads after / loads before.
5. **Load after a chosen mod** exists only as a fix, not as a tool: on the Mods page's Conflicts pane, when two mods
   ship the same Lua file, "Load <loser> after it" moves the losing mod to just after the winner (`loadAfter`, ~441),
   once. Nothing remembers it: Auto or a profile load can undo it.
6. **One hidden pin exists:** ZeD picks (the file-picks helper, `ZeD_Picks`) is moved to the end of the order every
   time picks are rebuilt (`helperLast`, ZeD_MainMenuModsPanes.lua).
7. **Saving:** the screen drives vanilla's model. Done writes the order through `correctAndSaveModOrder`, which also
   pulls every requirement in front of the mod that needs it (so the game's own save can never write a mod before
   what it needs). Accept (vanilla's `acceptChanges`) writes it: the main menu's list to the game's mods file
   (`saveModsFile`), a save's list to that save's mods.txt, Server settings' list back to the server's settings.
   ZeD profiles keep each profile's order in Zomboid/Lua/ZeD_modprofiles.txt (`[name]`, `order=id;id;...`, `saved=`,
   `used=`). Note: that file's writer keeps only those three keys and drops any other line it read.
8. **Cost per frame on this page:** the order check walks every mod's needs and wishes (Java lists turned into Lua
   tables) every frame, twice (the list and the band); the list makes a controller stop for every row every frame.
   Fine at 137 mods; at 1,500 it is the first thing to fix (section 5).

## 1. Find in the load order

**Recommendation: filter, with the real numbers kept and the gaps shown.** (Question 1 has the other option.)

1. When the Load order page opens, then a Find field sits over the list, as on the Mods page, empty. There are no
   tabs on this page (the load order is one list).
2. When Find has text, then the list shows only the matching mods, each with **its real place number** (the number it
   loads at, not its place among the matches). Between two matches that are not neighbours, a thin gap line says how
   many are between: "38 more". Matching is plain text over the mod's name, mod id and Workshop number, ignoring case,
   as on the Mods page.
3. When Find has text, then a separator shows only when it holds a match, as its heading line with the count of
   matches: "Radio (2 of 14)". A separator whose own name matches shows too, with its count, and its mods show as
   well (looking up "maps" should give the Maps section). A collapsed separator holding a match opens for the moment,
   never saved (as Find opens folders, MOD_FOLDERS_SPEC 2.3).
4. When Find has text, then the pinned blocks (section 2) show their heading only when they hold a match.
5. When nothing matches, then the list says "No mod in the load order matches \"radoi\"." and the band's Done still
   works (Find never changes the order).
6. When the player presses A / Return / double-clicks a match, then Find is cleared and the full list shows with that
   mod picked, scrolled to the middle of the list, focus on it. This is the "where does it sit" answer.
7. If the player moves a match meanwhile (Move up / Move down, a pin, Load after...), then the move acts on the real
   order, one real place for Move up / Move down; the row stays in the filtered list with its new number and the gap
   counts change. Dragging is off while Find has text (dropping between gaps is ambiguous); the help line says
   "Clear Find to drag."
8. When the page is left (Done or Back), then Find is cleared. Find's text is never saved.
9. The order check's marks (red / yellow / green) show on matches as on the full list. The band keeps its order
   status for the whole list, not only the matches: "2 red rows (not shown: clear Find)" when red rows are hidden.

## 2. Pin to load first / load last

A pin is a kept wish: "this mod goes at the top (or the bottom), whatever else changes."

1. When the player chooses **Load first** on a mod (its menu), then it moves into the **Load first** block at the top
   of the order, after any mod already pinned first. **Load last** puts it in the **Load last** block at the bottom,
   after any mod already pinned last.
2. The blocks are not separators: each is a heading line in its own look (the words LOAD FIRST / LOAD LAST in the
   small caps the headings use, no checkbox, no triangle, no rename), shown only while it holds a mod. A pinned row
   carries a tag, "First" or "Last", with the accent square. Numbers run through the blocks as through everything
   else (the first pinned mod is 1).
3. Inside a block, the player orders the pinned mods with Move up / Move down (or drag); a pinned mod never leaves its
   block that way. Auto sorts inside each block by the mods' own rules, as inside a section.
4. **A pin never breaks a requirement.** When a mod pinned first needs other mods, then they come into the block above
   it, tagged "Carried" (dim) with "needed by Mod Options" in the help line; they are not pinned, and when the pin goes
   they go back where they were. When a mod needs a mod pinned last, then it comes into the Load last block below it,
   tagged "Carried". This is the same rule the game's own save applies (section 0.7), shown before Done.
5. **Pins against each other.** When a mod pinned last is needed by a mod pinned first, then the requirement wins: it
   is carried up into the Load first block, its pin stays saved but is not kept, its row is yellow and its detail says
   "Pinned last, but Mod Options (pinned first) needs it, so it loads first." Removing either pin clears it.
6. **Pins against the mods' own wishes.** A pin beats a mod's own loadBefore / loadAfter (they are wishes, the game
   loads either way). The row is not marked yellow for a wish the pin overrides; the detail lists it: "Its own wish
   (load after Damn Lib) is overridden by your pin."
7. **ZeD picks** stays after every pinned-last mod, with the tag "Kept last by ZeD"; it has no Unpin and cannot be
   moved (its copies must win).
8. When the player chooses **Unpin**, then the mod leaves the block and stays at the nearest place outside it: the
   first place under the block for Load first, the last place above it for Load last (inside whatever section is
   there). Moving or dragging a pinned row out of its block also unpins it; the band says "Mod Options is no longer
   pinned first." with **Undo**.
9. **A pinned mod turned off** (on the Mods page, by a folder, a separator, a profile) leaves the load order like any
   other; its pin stays saved. Its row on the Mods page says "Pinned: load first" in the detail. Turned on again, it
   goes back into its block, at its place among the pins.
10. **Saving:** pins belong to the load order in use, like separators (MOD_FOLDERS_SPEC 10): kept with the profile in
    ZeD_modprofiles.txt, and with the list itself when no profile is in use (section 7). The game's files get only the
    resulting order, so without ZeD the mods still load in the order last written.
11. Every change here is held until Done, as every move on this page; Back offers Discard changes.

## 3. Load before / after a chosen mod

**Recommendation: a kept rule.** (Question 2 has the one-time move.) A move alone is undone by the next Auto, profile
load or folder start; the player who asked has to redo it each time. A rule is what they meant: "this one after that
one."

1. When the player chooses **Load after...** (or **Load before...**) on a mod, then a picker opens over the list: a
   framed window titled "Load Pirate Radio FM after", a Find field (focused), then every mod in the load order in
   load order, with numbers, under its separators' names, the picked mod itself not listed. Buttons: Cancel and
   **Load after** (primary, greyed until a mod is picked).
2. The picker's list greys the mods the rule cannot use, with the reason in the help line when one is pointed at:
   a mod that needs this one ("Knox Radio Plus needs Pirate Radio FM, so it cannot load first"), a mod this one needs
   for Load before ("It needs Damn Lib, so Damn Lib loads first"), and a choice that would close a circle of your
   rules (section 6.1).
3. When the player picks a mod and presses Load after, then the mod moves to just after the chosen one, now, into the
   chosen one's section (or block), and the rule "Pirate Radio FM after Knox Radio Plus" is kept. The band says
   "Pirate Radio FM loads after Knox Radio Plus (your rule)." with **Undo**.
4. One mod can have several rules. A second rule on the same pair replaces the first (after then before: before wins).
5. **How a kept rule acts later.** Every time the order is laid out again (Auto, a profile load, a mod turned on,
   Start separators from folders, a pin), your rules are kept after requirements and pins (section 4). Auto sorts
   inside each section and never moves a mod across a separator; when a rule names a mod in another section and is
   not met, the row is yellow and the detail offers **Move it** (puts it after the named mod again).
6. **Rules and the order check.** A rule not kept makes the row yellow ("Your rule: after Knox Radio Plus, not kept").
   A rule that reverses one of the mod's own wishes overrides it: no yellow for that wish; the detail lists it as
   overridden. A rule can never make a row red: a choice that would put a mod before what it needs is greyed in the
   picker (1.2) and refused when laid out (section 4).
7. **A manual move that breaks a rule** (Move up / Move down, drag) is the player's latest word: the move happens,
   the rule goes, and the band says "Moved: your rule (after Knox Radio Plus) is removed." with **Undo**.
8. **Rules and pins.** Load after a mod pinned first puts this one at the first place under the Load first block (it
   is not pinned by this). Load before a mod pinned first cannot be kept unless this one is pinned too: the picker
   shows that mod with "Pinned first: pin this first too?" and choosing it offers **Pin first and load before**.
   The same, mirrored, for Load last.
9. **Rules and separators.** A rule moves the mod into the named mod's section when made. A separator turned off holds
   its mods off in place (MOD_FOLDERS_SPEC 8): a rule naming an off mod is kept but does nothing until it is on.
10. The detail pane of a mod lists its rules under **Your rules** with **Remove** on each, under its own rules (needs,
    loads after, loads before). The mod's row shows a small tag "Rule" while it has any.
11. Saved with pins (section 7): per profile, and with the list when no profile is in use.

## 4. Laying out the order: who wins

When ZeD lays out the order (Done, Auto, a profile load, a mod turned on, a pin or a rule made), then it applies, the
strongest first:

1. **Requirements** (the game's rule): a needed mod loads earlier. Never broken; this is also what the game's own save
   does.
2. **ZeD picks last** (ZeD's rule for its helper).
3. **Pins:** the Load first block at the top, the Load last block at the bottom (with carried mods, 2.4).
4. **Your rules** (load before / after a chosen mod).
5. **Separators:** a mod stays in its section unless a rule made now moves it (3.3).
6. **The mods' own wishes** (loadBefore / loadAfter), inside each section, by Auto only.
7. **The player's own place** for everything else (a manual move is never redone by layout, except by Auto).

A mod newly turned on goes to the end of the order (the director's pick, MOD_FOLDERS_SPEC 13.3): above the Load last
block when it exists, under the last separator.

## 5. 1,500 mods

1. Nothing walks the whole list per frame. The order check, the place numbers, the gap counts and each section's count
   are worked out once per change (a move, a pin, a rule, Find's text, on / off) and kept until the next change.
2. Each mod's needs and wishes are read from the game once when the page opens (into Lua tables), not per row per
   frame.
3. Find: each mod's search text (name, id, Workshop number, lower case) is made once when the page opens; a keystroke
   runs one plain match over 1,500 short strings, then the filtered list is kept. Typing never redraws more than the
   rows on screen.
4. The list draws only the rows on screen; controller stops are made for the rows on screen plus the focused one, and
   the pad's jumps (section 8) work on place numbers, not on stops.
5. The picker reuses the page's search text and lists; it opens at once.
6. Laying out (section 4) is one pass over the list per change; Move up / Move down is a swap and never lays out.
7. A rule or pin naming a mod that is not installed costs nothing at layout (it is skipped, section 6).

## 6. Edge cases

1. **Circles.** When a new rule would close a circle (A after B, B after C, C after A), then the picker greys the
   choice, and pointing at it says "Circle: Knox Radio Plus already loads after Pirate Radio FM (your rule)." Rules
   with requirements are checked too (A before B when B needs A is greyed, 3.2). A circle that comes in from a profile
   or an old file is laid out by keeping the older rules and marking the newest one yellow, "Not kept: circle with
   Knox Radio Plus", with **Remove**.
2. **A rule or pin naming a mod that is not installed** is kept, does nothing, and shows in the mod's detail dimmed:
   "after Old Radio (not installed)". It never makes a row yellow. Remove takes it out; nothing else does (as folders
   keep members not installed).
3. **A rule naming a mod that is off** is kept and does nothing until that mod is on; the detail says "(off)".
4. **A pinned mod that cannot run** (wrong game version, a missing requirement) is off like any other; its pin stays.
5. **Every mod pinned:** allowed; the blocks then hold the whole order and Auto sorts inside them.
6. **ZeD picks named in a rule:** Load before ZeD picks is the same as no rule (it is last anyway); Load after ZeD
   picks is greyed: "ZeD picks always loads last."
7. **Server settings and New game's Choose mods** use the same page: pins and rules there belong to that list.
8. **Map order** (its own page) gets none of this: it is a list of map folders with its own rule.
9. **Pasted share text** ("name:id;id;") carries no pins or rules, as it carries no separators.
10. **An older ZeD reading the profile file** drops the new lines when it next writes it (0.7). Nothing can fix older
    builds; the release notes say to update before saving profiles.

## 7. Saving pins and rules

1. In Zomboid/Lua/ZeD_modprofiles.txt, under the profile's `[name]`, beside `order=`:
   `first=<id>;<id>` (pinned first, in order), `last=<id>;<id>` (pinned last, in order),
   `rule=<id>|after|<id>` or `rule=<id>|before|<id>` (one line per rule, oldest first), with separators as
   MOD_FOLDERS_SPEC 10 gives them.
2. When no profile is in use, then the list keeps them under a section of its own that no profile name can take:
   `[@list main menu]`, `[@list save <folder>]`, `[@list server <name>]` (profile names cannot start with "@").
3. Update... saves the list's pins and rules into the profile; New... starts with the list's.
4. The writer keeps every line it does not know (fixes 0.7 for later keys).
5. The game's own files hold only the resulting order.

## 8. Controller and keyboard

Same page, same stops as today, plus these. Every path below also has a mouse path (the menu by right-click, drag).

**The row's menu** (System 7 pop-up list): Load first / Load last (or Unpin), Load after..., Load before..., a line,
Move to top of section, Move to end of section, a line, Remove rules (only when it has any).

| Do | Controller | Keyboard | Mouse |
|---|---|---|---|
| Open the row's menu | A on a row | Shift+F10 or the menu key | Right-click the row |
| Move one place | Y up / X down (as today) | Ctrl+Up / Ctrl+Down | Move up / Move down, drag |
| Top / end of section | the menu | Ctrl+Home / Ctrl+End | the menu, drag |
| Jump section to section | LB / RB (the focus goes to the next heading) | Page Up / Page Down move a page; Ctrl+Page Up / Down a section | wheel, scroll bar |
| Reach Find | D-pad Up from the first row, then A (the text needs a keyboard: Steam's own on the Deck) | Ctrl+F | click |
| Leave Find | B (the text stays, the list stays filtered) | Esc (first press leaves, second clears) | click the list |
| Clear Find | the Clear button at the field's end (a stop) | Esc twice | Clear |
| Go to a match in the full list | A on the match | Return | double-click |
| Picker: pick and place | D-pad, A on a mod, then A on Load after | Up / Down, Return | click, then Load after |
| Picker: leave | B | Esc | Cancel |
| Undo the last move, pin or rule | the band's Undo (a stop) | Ctrl+Z | Undo |
| Done / Back | as today (the band's Done, B) | Return / Esc as today | Done / Back |

Inside the picker the pad has the same LB / RB section jumps; its Find works without a keyboard by not typing:
the list is the load order itself, so jumping by section and paging is the pad's way.

## 9. Words (all into UI.json)

Menu: "Load first", "Load last", "Unpin", "Load after...", "Load before...", "Move to top of section", "Move to end
of section", "Remove rules". Tags: "First", "Last", "Carried", "Rule", "Kept last by ZeD". Headings: LOAD FIRST,
LOAD LAST. Picker title: "Load %1 after" / "Load %1 before". Band: "%1 loads after %2 (your rule).", "%1 is no longer
pinned first.", "Moved: your rule (after %1) is removed." Find: "No mod in the load order matches \"%1\".", "%1 more".

## 10. Questions for the director

1. **Find in the load order: filter or highlight?** (a) Filter to the matches, real numbers kept, gaps shown ("38
   more"), A jumps to the match in the full list. (b) Keep the full list and mark the matches; Return / A jumps to the
   next one ("3 of 6"). (c) Both, a switch beside the field. **Recommend (a):** with 1,500 mods, six matches spread
   over the list are easier to read on one screen than to hop between, and the numbers still say where each sits.
2. **Load after a chosen mod: a kept rule or a one-time move?** (a) A kept rule, shown on the row and in the detail,
   kept by Auto and profile loads, dropped by a manual move. (b) A one-time move (as the Conflicts pane's fix today);
   nothing remembered. (c) The picker has a tick "Keep this as a rule", on by default. **Recommend (a):** the player
   who asked re-sorts often; (c) adds a choice every time for little gain.
3. **Who wins between a pin and a mod's own load-after wish?** (a) The pin, no yellow mark, the detail says it is
   overridden. (b) The pin, and the row stays yellow as a reminder. **Recommend (a):** the player chose it on purpose;
   yellow should mean something to look at.
4. **Pins without a profile: kept with the list, or only in profiles?** (a) Kept with the list in use too (section
   7.2), so they work for a player who never makes a profile. (b) Only in profiles; with none in use, the pin menu
   items are greyed "Save a profile to keep pins". **Recommend (a).**
