# Mod Folders and load-order separators (draft, Oct 31 2026)

Plain rules for the director before anything is built. Decision: PUNCH_LIST item 37 ("both, kept apart").
Mockup: `ZeDUI/mockups/zed_mod_folders_v1.html` (PNGs beside it). Screen as built today:
`42/media/lua/client/ZeD/ZeD_MainMenuMods.lua` (Mods page, Load order page, Profiles page).

**Folders** sort the whole collection: every installed mod, on or off. They live in Zomboid/Lua/ModFolders.cfg,
the file of [B42]Mod Folders (Workshop 3779201168), so a player's layout shows in ZeD and stays the same without ZeD.
A folder never changes the load order.

**Separators** sort the load order (MO2-style): headings inside the list of mods that are on. A mod's place under a
separator is its place in the order. Saved with each ZeD profile. Turning a separator off turns off every mod under it.

A mod's folder and its separator never affect each other. One button links them: a profile can start its separators
from the folders.

## 1. Where they show, and which list you are in

1. When the Mods page opens, then the list is **the collection**: every installed mod, ticked or not, grouped under
   folder rows, with no numbers. The title reads "Project Zomboid + Mods". A line at the top of the list says
   "Every installed mod, on or off. Folders sort this list; they never change the load order."
2. When the Load order page opens, then the list is **the load order**: only mods that are on (plus the mods held
   under a separator that is off, see 5), every on mod numbered from 1 in the order the game loads them, separators
   as full-width heading lines between them. The title reads "Project Zomboid + Load order". The top line says
   "The mods that are on, top loads first. Separators belong to the profile in use: <name>." (or "...to this list"
   when no profile is in use).
3. The two never borrow each other's look: folder rows have a disclosure triangle, a folder picture and a count;
   separator rows are a ruled heading line with the name in the middle of the rule and no folder picture. Numbers
   appear only in the load order. Folders never show on the Load order page; separators never show on the Mods page.
4. When no folder exists, then the collection looks exactly as today (flat, A to Z, no "Unfiled" row). When no
   separator exists, then the load order looks exactly as today.
5. When folders exist, then they come first in their saved order, then **Unfiled** (every mod in no folder), as
   Mod Folders lays it out.

## 2. Tabs and Find on the collection

1. When a tab other than All is chosen (On, Starred, Maps, Problems, Conflicts), then rows stay inside their folders;
   a folder with no row in that tab is not drawn; each folder's count is for the tab ("Vehicles (3 of 12)").
2. The Workshop tab stays flat (it lists Steam items, not installed mods).
3. When Find has text, then every folder holding a match shows open, the rest are not drawn. This opening is for
   the moment only: it is never written to the file. When Find is cleared, then each folder is open or closed as saved.

## 3. Folders: make, rename, delete, collapse, reorder

1. When the player chooses **New folder...** (in the band of the Mods page, and in a row's menu), then the band
   asks for a name and the new folder appears at the end of the folders, open, empty. If it was made from a row's
   menu, then that row's mod (or every selected mod) moves into it.
2. When a name is empty, only spaces, or already used by another folder (the same letters, ignoring case), then
   the band says "There is already a folder called Vehicles." and keeps the field open. Names are trimmed.
3. When there are 99 folders, then **New folder...** is greyed with "New folder needs fewer than 99 folders."
   (Mod Folders' own limit, kept so its screen still takes the file.)
4. When the player chooses **Rename...** on a folder, then the band asks for the new name; the folder keeps its
   place and its mods.
5. When the player chooses **Delete folder** on a folder, then the band asks "Delete the folder Vehicles? Its 12 mods
   move to Unfiled; none turn off." with Cancel and Delete (danger). Only the folder goes; no mod changes.
6. When the player presses a folder's triangle (or its row with A), then it collapses or opens, and that state is
   saved to the file (Mod Folders keeps it there too). Unfiled's open state is ZeD's own and stays in ZeD's settings.
7. When the player drags a folder row (mouse) or chooses **Move up** / **Move down** in its menu (controller), then
   the folder and its mods move as one among the folders. Unfiled always stays last.
8. **Open all** / **Close all** sit in the folder rows' menu, not on the screen.

## 4. Putting a mod in a folder

1. **Mouse:** when the player drags a mod row onto a folder row or between two rows of a folder, then it joins that
   folder (rows in a folder sort A to Z, so where it lands inside does not matter). Dropped on Unfiled, it leaves its
   folder. Ctrl-click and Shift-click select several rows; dragging any of them carries all.
2. **Menu:** right-click a mod row (or several selected) for **Move to folder...**, a pop-up list of the folders plus
   "New folder..." and, when it is in one, **Take out of the folder**.
3. **Controller:** the row's menu (the pad's menu press) gives the same **Move to folder...** list; the D-pad picks a
   folder, A moves it, B leaves it where it was. Focus stays on the moved mod, now inside its new folder; if that
   folder is collapsed, focus lands on the folder row.
4. A mod is in one folder at most. Moving it to a second folder takes it out of the first.
5. If the mod's folder is deleted or renamed in another way while the pop-up is open (the file changed, see 9),
   then the move goes to the folder by its number; if that folder is gone, the band says "That folder is gone." and
   nothing moves.

## 5. A mod in no folder, and a mod that is uninstalled

1. When a mod is in no folder, then it is listed under Unfiled. Unfiled is not a folder: it has no on/off box, no
   rename, no delete, and it is never written to the file.
2. When a mod in a folder is uninstalled (unsubscribed, or its folder removed from disk), then its line in the file
   stays untouched; it is not shown in the folder and not counted. The folder's detail pane lists it under "Not
   installed (2)" so the player can see why the file holds more than the screen. When the mod comes back, then it is
   back in its folder.
3. A **Take out of the folder** on a not-installed entry (in the folder's detail) removes its line; nothing else does.

## 6. A folder's on/off box

1. Each folder row has a System 7 checkbox at its right: ticked when every installed mod in it is on, empty when none
   is, the mixed mark (a dash) when some are.
2. When the player clicks an empty or mixed box, then every installed mod in the folder turns on (Mod Folders does the
   same: mixed turns all on). When the player clicks a ticked box, then every mod in it turns off.
3. Turning on follows the game's own rules, as a single tick does today: requirements come along (even from other
   folders), a mod that cannot run (game version, a missing requirement not installed) stays off. The band says what
   happened: "Vehicles: 7 mods on, 2 more came along (Tsar's Common Library, Damn Lib). 1 cannot run: Old Truck needs
   build 41." Turning off says which mods outside the folder turn off with them because they need one.
4. Like every tick on this page, nothing reaches the game until Accept; Back offers Discard changes.
5. A folder never changes where its mods sit in the load order. Mods it turns on go where the game puts newly
   turned-on mods (see 7.4).
6. An empty folder's box is greyed: "Turning it on needs a mod in the folder."

## 7. Separators in the load order

1. When the player chooses **New separator...** (the Load order page's band, and a row's menu), then the band asks
   for a name and a separator is placed above the selected row (or at the end with nothing selected). Every mod below
   it, down to the next separator, is now under it.
2. **Rename...**, **Delete separator** (no question: the mods stay where they are, now under the separator above, and
   Back offers Discard changes) and collapse work as for folders. A collapsed separator keeps its count and the numbers
   jump past it ("12 to 19 hidden").
3. **Moving:** a separator moves with its mods as one block (drag, or Move up / Move down past the next block). A mod
   moves one place at a time; crossing a separator is one step, so Move up on the first mod under "Maps" puts it at the
   end of the section above. Dragging works as in the collection; dropping above the first separator puts it in no
   section (the top of the order).
4. When a mod is turned on (on the Mods page, by a folder's box, by a profile), then it goes where the game puts it:
   the end of the order, under the last separator. (See question 3.)
5. When a mod is turned off on the Mods page, then it leaves the load order. Its separator and place are remembered
   for this list; turned on again, it goes back to that place if the separator still exists.
6. **Auto** sorts by the mods' own rules within each section and never moves a mod across a separator. When a mod
   needs one that sits in a later section, then both rows stay red and the band says "Crafting Pack needs Crafting
   Core, which loads later under Maps. Move it up?" with **Move it up** (puts the needed mod at the end of the earlier
   section).
7. Duplicate separator names are allowed (they are only headings), but the band warns once: "There is already a
   separator called Maps."

## 8. A separator turned off

1. Each separator has a checkbox: ticked when its mods are on. When the player unticks it, then every mod under it
   turns off and stays in its place, dimmed (0.42), unnumbered, so the order of the rest closes up. Ticking it again
   turns them all back on in the same places.
2. The game follows its own rules: when a mod that something else needs turns off, then the band says which mods
   above or below turn off with it (they dim where they are, under their own separators, with a note on the row:
   "Off: needs Damn Lib").
3. When a mod is dragged under a separator that is off, then it turns off and dims; the band says "Sample Farm Map
   turns off: Maps is off." When a dimmed mod is dragged out from under an off separator into an on section, then it
   turns on.
4. When a single dimmed mod is ticked on its own, then it turns on and the separator's box shows the mixed mark.
5. As with every load order change, Done keeps it and Back asks. On/off changes made here are the same changes as on
   the Mods page and need Accept there.

## 9. ModFolders.cfg (from the mod's own code, Oct 31 2026)

Read from `ModFolders.lua` (Workshop 3779201168, mod id `ModFolders`, its `loadConfig` / `saveConfig`). The code
settles the format; one look at a file the mod itself wrote (a short run with ZeD off) is still worth doing before
build, to confirm the hex of a non-English name.

**Where:** Zomboid/Lua/ModFolders.cfg (the game's `getFileReader` / `getFileWriter` folder, as ZeD's own files).

**Lines** (one per line, no section heads, no comments):

| Line | Meaning |
|---|---|
| `version=2` | Format. Missing means version 1 (older encoding, below). The mod writes it first. |
| `next=<n>` | The number the next new folder gets. Folder numbers are never reused. If `next` is not above the highest folder number, the mod uses highest + 1. |
| `folder=<id>\|<0 or 1>\|<name>` | One folder. `<id>` its number (what members point to); `1` open, `0` collapsed; `<name>` encoded. **Folder order is the order of these lines.** |
| `member=<mod id>\|<folder id>` | One mod in one folder. The mod id is mod.info's `id=` (`modInfo:getId()`), encoded; **not** the Workshop number. One line per mod; a mod is in one folder at most. |

**Encoding (version 2):** each character as its character code in upper-case hex without padding, joined by commas:
"Cars" is `43,61,72,73`. Kahlua's `string.byte` gives the UTF-16 unit, so a Chinese name gives 4-digit codes
(`6A21,...`). ZeD encodes and decodes the same way (same engine, same functions). **Version 1** used %-escapes
(`%41`, with `%XXXX` for codes above 255); the mod reads it and rewrites as version 2 on its next load. ZeD reads
version 1 the same way and writes version 2.

**What the file does not hold:** no nesting (folders are one level), no colors, no on/off state of a folder (the box
is worked out from the mods), no load order, nothing about Unfiled. Names are unique (the mod checks exact matches;
ZeD also refuses a match ignoring case), trimmed, never empty. At most 99 folders (the mod refuses the 100th; it still
reads more).

**What Mod Folders does on write:** rewrites the whole file from memory on every change (create, rename, delete, move,
assign, collapse): `version`, `next`, folders in order, then members in no fixed order. It drops lines it does not
know and members whose folder is gone. It keeps members of mods that are not installed. It reads the file once per game
start.

**ZeD's rules for the file:**
1. When the Mods page opens, then ZeD reads the file (each time, so outside edits show).
2. ZeD writes only when the player changes folders (make, rename, delete, reorder, collapse or open, move a mod in or
   out). Never on open, never for Find's temporary opening, never to tidy up.
3. Every write: read the file again, apply the one change to what is there now, write it back. So an edit made outside
   the game (or by another tool) while the screen was open is kept.
4. ZeD keeps every line it does not understand, in place, and keeps members whose folder is gone and members of mods
   not installed. It adds nothing of its own to the file (ZeD-only state, such as Unfiled's open state, goes in ZeD's
   settings).
5. ZeD writes `version=2` first, then `next`, folders in the player's order, members sorted by mod id (stable for
   people who back the file up), then any unknown lines.
6. New folder: number = `next` (or highest + 1), then `next` goes up by one. Renaming keeps the number.
7. If the file cannot be read (bad line), then the lines that parse are used, the rest are kept as unknown lines,
   and the help line says "ModFolders.cfg has 2 lines ZeD could not read; they are kept as they are."
8. If the file is missing, then there are no folders; the first New folder creates it.
9. If the file cannot be written, then the change is undone on screen and the band says so.

## 10. Separators in profiles

1. Separators (name, place, on/off, collapsed) belong to the load order in use and are kept in ZeD's own profile
   file (Zomboid/Lua/ZeD_modprofiles.txt), never in the game's files or in ModFolders.cfg. The load order the game
   reads stays a plain list of mods.
2. When a profile is saved (New... or Update...), then its separators are saved with it. When a profile is loaded,
   then its separators come back with its order; the mods held under an off separator stay off.
3. The Profiles page's detail lists a profile's load order under its separators ("Maps (4, off)").
4. A separator holding a mod that is not installed keeps it (dimmed, "not installed"), as profiles do today.
5. Vanilla's share text ("name:id;id;") carries no separators. A profile loaded from pasted text has none.

## 11. "Start separators from folders"

1. Shown on the Profiles page's detail for the selected profile, and in the Load order page's band, as **Start
   separators from folders** while the list has no separators and at least one folder exists.
2. When pressed, then for each folder (in folder order) that holds at least one mod that is on, a separator with the
   folder's name is made and that folder's on mods go under it, then a separator "Unfiled" for the rest. Within each
   section the mods keep their current relative order, then Auto runs inside each section. Mods that are off stay off;
   nothing turns on or off.
3. The band then says what moved and anything left red: "7 separators from your folders. 2 mods now load before what
   they need." with **Move it up** as in 7.6.
4. When the list already has separators, then the button reads **Replace separators with folders** and asks first:
   "Replace the 4 separators in Crafting run? Your mods stay on; their order follows the folders." with Cancel and
   Replace (danger: the old separators and order are lost once Done / Update is pressed).
5. After that the separators and folders are independent again: renaming a folder does not rename its separator.

## 12. Edge cases

1. **Empty folder:** shown with "(0)", its box greyed; it can be renamed, deleted, moved, and mods dropped in.
2. **500 mods:** the list draws only the rows on screen (as today); folder counts are worked out once per change, not
   per frame. Collapsing a folder of 300 mods is instant. Moving 200 selected mods is one write.
3. **Long names:** folder and separator names are cut with "..." at the row's width; pointing at the row puts the
   whole name in the help line. Typing stops at 48 characters (Mod Folders has no limit; longer names from the file
   are shown cut, never changed).
4. **Two folders with the same name** (only by editing the file): both show, in file order; both work; renaming one
   to a free name fixes it. ZeD never merges them.
5. **The file edited outside the game while the screen is open:** the next write merges (9.3). When the page is
   reopened, then the new layout shows. If the mod the player was moving pointed to a folder that is now gone, then
   see 4.5.
6. **Mod Folders also on:** its screen never shows (ZeD replaces the Mods screen); its code may still migrate a
   version 1 file at start. Both write the same format, so either one's change survives.
7. **Server settings' mod list and New game's Choose mods** use the same screen: folders and separators show there
   too; separators there belong to that list.
8. **Controller in a 300-row folder:** the pad's page-jump (whatever long main menu lists use today; check
   GAMEPAD_SPEC before build) jumps folder row to folder row, and separator to separator on the Load order page.
9. **Translation:** every string goes into UI.json; folder and separator names are the player's and are never
   translated.

## 13. Questions for the director

1. **The folder box on a mixed or full folder: ask first, or act?** (a) Act at once, the band says what changed, and
   nothing applies before Accept anyway (Back offers Discard). (b) Ask in the band first, as Mod Folders does
   ("Turn on the 9 mods in Vehicles?"). **Recommend (a):** ZeD already holds every change until Accept.
2. **Grouping in the collection when folders exist.** (a) Always grouped (the layout the player made in Mod Folders).
   (b) Two radio buttons over the list, "By folder" and "A to Z", remembered. **Recommend (a)**; Find already
   flattens to the matches.
3. **Where a newly turned-on mod goes when separators exist.** (a) The end of the order, under the last separator
   (the game's own place and MO2's habit). (b) Under the separator named after its folder when one exists, else the
   end. **Recommend (a):** it keeps folders and separators independent, as decided; (b) quietly links them.
4. **Start separators from folders: which mods count.** (a) Only the mods that are on (separators are part of the load
   order). (b) Also hold the off mods under their folder's separator, dimmed, ready to tick. **Recommend (a)**: the load
   order stays the list of what loads.
