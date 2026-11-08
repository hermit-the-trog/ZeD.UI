# Compatibility round 6: support for the menus' three (Nov 7 2026)

The director picked seven round 6 mods for support. This file covers three of them: Clear Skill Sheet, Better Folders and Better Mod Experience. Each was read from the SteamCMD copy (`C:\steamcmd\steamapps\workshop\content\108600\<id>\mods\<folder>`). No code or art was copied. Each support file is `42/media/lua/client/ZeD/ModSupport/<mod id>.lua` and does nothing when its mod is off.

## Clear Skill Sheet (Clear_SkillSheet, 3834856444, by m4as)

**What it adds:** the game's Skills view redrawn:
- two columns;
- the level as a number and a small bar (or the XP of the level with its "Show values" option);
- each skill's name colored by how fast it learns (gray below x1, green x1, blue x1.33, orange x1.66);
- a skill book's multiplier ("x3") after the name;
- "XP gain: x1.33" in the tooltip.

**With ZeD on, before:** nothing showed. ZeD's Skills tab replaces the game's Skills view, which is all the mod changes.

**Already covered by ZeD:** two columns, the level as a number (the badge), a bar (ten segments), the XP of the level (the help line and the card's head).

**Now:** the rate and the book show in ZeD's Skills tab.
- Each row gets a tag beside ZeD's boost tag (left of it; the director's ruling: beside it, not in its place) that reads "XP x1.33". It reads "XP x1.33, book x3" while a book runs. The tag's square is the mod's color.
- A row learning below x1 with no boost and no book has no tag, as before. Fitness, Strength and Sprinting never learn slower than x1, so they read "XP x1" with no boost.
- The row's card (mouse over the row, or the controller's focus) adds the mod's "XP gain" line and the game's "Multiplier" line.
- The mod's Enable option off: nothing is added; ZeD's boost tag stays either way.

**Not carried over:**
- The colored names. ZeD's rule is status squares and default text, so the color is on the tag's square.
- The abbreviated numbers. ZeD shows full numbers.

## Better Folders (VIF_DualRender_B42, 3834889317)

The mod.info names no author; credit it by name and Workshop id until the page gives one.

**What it adds:** folders the player names, in the game's inventory list of the character's own inventory.
- Things are filed one by one (dropped on a folder) or by type (from the item menu).
- Each folder is a row with its things under it, its weight and [+] / [-].
- A "+" button beside the list's header makes a folder.
- The folder's right-click renames, deletes (the things stay) or folds it.
- Kept in the character's modData.

**The task's note:** the brief mapped this mod to the Mods screen's folders and separators. It is an inventory mod, so it maps to ZeD's item lists. ZeD's own mod folders and separators are not involved.

**With ZeD on, before:** the folder rows and the "+" button never showed. ZeD's Character window replaces the game's inventory page. The mod's two item-menu lines did show and filed things into a list nobody saw.

**Now:**
- In the character's own inventory, sorted by Category, each folder is a folding group row before the categories, in the mod's order, with the player's name for it. A folder with nothing filed is a group row too, count 0, as an empty container (Build's call). The grid shows the same groups.
- In the other sorts the list stays flat and the category column names the folder.
- The item menu has Virtual folders: Create folder..., Rename... and Delete folder (keep items), in the mod's words. Names are typed in ZeD's prompt, with ZeD's keyboard on a controller.
- The mod's own filing lines stay. When the mod's menu can't answer (the game's hidden page holds another container), ZeD adds the same two lines.
- New hook for other mods: `ContainerGroups.lua`.

**Not carried over:**
- The folder's weight on its row. ZeD's group rows give the count.
- The mod's own fold state. ZeD keeps its own, as for categories.
- Dropping things on a folder row. Filing is from the item menu.

## Better Mod Experience (BetterModExperience, 3834902827, by coldfeudal)

**What it adds:**
- Sorts the active mod list on Accept (the game's auto sort), but not on a Back that changed nothing.
- Holds a game start back (New Game, Load, Continue, Host) for a duplicate, a missing mod, a missing requirement, a wrong order or two incompatible mods. The reason is in red over the button and the button is off.
- Folds each mod's section on Options > Mods, with the mod's icon.
- Fixes under the screens: ModOptions.ini records, no Lua reset for a list that was only sorted, local mods in Mod Load Order Sorter's server list and the "mods changed" pop-up marked seen.

**Already covered (works with ZeD as it is):**
- The sort on Accept. ZeD's Mods screen accepts through the game's own model, which the mod wraps.
- The ModOptions fixes, the no-op reset, the pop-up and the Mod Load Order Sorter fix. None of them draws anything.

**With ZeD on, before and now:**
- **Options > Mods was jumbled.** ZeD reads the game's options page to draw its own. The mod moves a shut section's controls up over the next section, so ZeD paired labels and controls across sections. Now ZeD reads the page with every control where the game put it. Each mod's heading is a ZeD fold head that opens and shuts the mod's own section, shut to begin with, as the mod has it. Find still searches every section. The mod's icons are not drawn (ZeD's section heads carry no icon).
- **Load and Continue started nothing, in silence.** The mod's red line was on the game's hidden Load screen. Now ZeD's Load screen shows the mod's first reason with the save's notes, and Play is off. Continue lands on Load when the mod holds it back.
- **New Game did the same.** Now Next opens ZeD's note with the mod's reasons, in the middle of the screen, with the main menu's controller on its OK (the menu gets the controller back after), and the game does not start.
- **Host.** The mod's first reason is the band's problem line, and Start is off.
- **Mods screen.** Back with no change made the mod sort the order (and could ask for a reload). Now Back and Discard changes with the order as it was do not sort, as the mod's own Back. The band's pending line says the mod sorts on Accept.

## Checks

- Sim: `ZeDUI/tools/qa/compat_r6_sim.lua`, 108 checks. It uses Better Folders' own `VIFState.lua` when the SteamCMD copy is there.
- In game: `ZeDUI/qa/CHECK_mods-menus_20261107.md`.
