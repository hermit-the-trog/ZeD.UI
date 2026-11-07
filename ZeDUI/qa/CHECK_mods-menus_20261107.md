# In-game check: mod support for Clear Skill Sheet, Better Folders, Better Mod Experience (Nov 7 2026)

What changed, in plain words:
- With Clear Skill Sheet on, the Skills tab shows how fast each skill learns and any skill book's multiplier.
- With Better Folders on, the folders show in ZeD's own inventory list, and the item menu makes, renames and deletes them.
- With Better Mod Experience on:
  - ZeD's Options > Mods reads right and folds per mod;
  - Load, Continue, New Game and Host say why the mod holds a start back;
  - Back on the Mods screen no longer sorts the list.

The mods are in the SteamCMD copies (`C:\steamcmd\steamapps\workshop\content\108600\<id>\mods\<folder>`; `batch_compat_r6.ps1` copies them into `Zomboid\mods` and removes them after):
- Clear Skill Sheet: `3834856444\mods\Clear_SkillSheet`.
- Better Folders: `3834889317\mods\VIF_DualRender_B42`.
- Better Mod Experience: `3834902827\mods\BetterModExperience`.

Turn on all three with ZeD (ZeD last). QA save `Saves/Sandbox/ZeD-QA`, at the drag strip.

Run each part twice:
- 4K (3840x2160, UI scale 1.75);
- Deck size (1280x800, Auto scale, Normal text, then Large text).

Each part runs once with the mouse and once with the pad.

Before the game: the sim `lua51 ZeDUI/tools/qa/compat_r6_sim.lua` reads `83 checks, 0 failed`.

## 1. Clear Skill Sheet: the Skills tab

Open the Character window (I), Skills tab. The QA character needs a profession or traits with boosts; give one skill a book (read the first page of a skill book).

| Step | Should show |
|---|---|
| Look at a boosted skill (profession skill) | A tag before the level bar: "XP x1.33" (boost 2) or "XP x1.66" (boost 3), its square blue or orange. No "+100% XP" boost tag beside it. |
| A skill at boost 1 | "XP x1" with a green square. |
| A skill with no boost (most of them) | No tag, as before. |
| The skill with the book running | "XP x0.25, book x3" (or whatever its rate is), the square gray when the rate is below 1. |
| Mouse over any row, wait for the card | The card: the skill's name, its level line, then "XP gain: x1.33" and, for the book skill, "Multiplier: 3". |
| A maxed skill (10) | No "XP gain" line; no card unless a book or another mod adds one. |
| Pad: D-pad onto a skill row | The same card under the row at once. LB/RB leave as usual; B returns focus as before. |
| Options > Mods > Clear Skill Sheet > Enable off, Apply, back to the tab | The tags and the card lines are gone; the "+100% XP" boost tags are back. Turn it on again. |
| Deck size, Large text | The tag fits the row; the name shortens before the tag and bar overlap ("A..." at worst). No row taller than its neighbors. |

With Skill Recovery Journal or Exp Recovery on too: their card comes first and the rate lines sit under it.

## 2. Better Folders: the inventory

Open the Character window, Inventory, the character's own main inventory. Set the list's sort to Category.

| Step | Should show |
|---|---|
| Right-click (or pad A, then the menu) a thing in the main inventory | A "Virtual folders" line with a submenu: "Create folder...". |
| Create folder..., type "Tools", OK | ZeD's prompt (not the game's text box); on a pad, ZeD's keyboard. Nothing in the list changes yet (an empty folder isn't listed). |
| Right-click an axe: "Move all items of this type to folder" > Tools | A "Tools" group row at the top of the list, before every category, with the axe in it and a count of 1. |
| Make a second folder "Food" and file apples by type | "Tools" then "Food" at the top, in the order made; every apple under Food. |
| Fold "Tools" (click its row, or pad A on it) | It folds like a category row; open again. |
| Sort by Name, then by Weight | One flat list; the category column of the axe reads "Tools". |
| Grid view (the list/grid toggle), sorted by Category | The same groups, folders first. |
| Right-click the axe again: Virtual folders > Rename..., "Kit" | The group row reads "Kit" at once. |
| Virtual folders > Delete folder (keep items) | The group goes; the axe is back under its category. Nothing left the inventory. |
| "Remove from folder" on an apple | The apples go back to their category. |
| A thing in a worn bag, and the World window's loot | No folders there; no "Virtual folders" line in a bag item's menu. |
| Equip the axe while filed | It leaves the list (Equip tab) as before; unequip and it is back under its folder. |
| Save, quit, load | The folders and the filing come back (the mod keeps them in the character's modData). |
| Safe mode (if it trips) | The game's own inventory with the mod's own folder rows and "+" button. |

## 3. Better Mod Experience: main menu

### Options > Mods

From the desk: Options, the Mods page.

| Step | Should show |
|---|---|
| Open the Mods page | One section per mod with options, each heading a fold head, shut, with a count. No labels paired with the wrong control, no overlapping rows. |
| Open "ZeD-GUI" (click, or pad A) | Its options in order under it. Open another: both open. Shut one again. |
| The ZeD setup page | ZeD's own options all there, whatever the Mods page folds show. |
| Type in Find a word from a shut section | It is found. |
| Change an option inside a section, Apply, reopen Options | Saved, and the page still reads in order (whether the section is open or shut). |
| Deck size, Large text | Heads and rows fit; the scroll reaches the last section. |
| Pad: D-pad down through the page | Each fold head is a stop; A opens and shuts it; LB/RB change page. |

### Load, Continue, New Game and Host

Make a bad list on purpose. Turn on a mod that needs another, without the one it needs. Or use a save whose mod list names a mod that is not installed.

| Step | Should show |
|---|---|
| Load, select that save | The save's notes: a red square, the game's "cannot be loaded" words and the mod's reason, e.g. "X requires Y". Play is off. |
| A save with a clean list | Plays. |
| The desk's Continue on that save | Nothing starts. The Load screen opens with the reason on the save. |
| New Game with the bad list as the game's mods (Choose Mods) | Next opens ZeD's prompt: "Not started: Better Mod Experience found a problem with the mod list." and the reasons. OK closes it; the game did not start. Pad: A on OK. |
| Fix the list, Next | The game starts as usual. |
| Host with a server whose Mods line holds the bad mod | The band's problem line names the mod's reason; Start is off. Fix the server's mods: Start is on. |

### The Mods screen

| Step | Should show |
|---|---|
| Open Mods, change nothing, Back | No load order change, no reload. |
| Move a mod up in Load order, Back, Discard changes | No sort, no reload. |
| Turn a mod on | The band's line ends with "Better Mod Experience sorts the load order on Accept." |
| Accept | The list is sorted and the game reloads Lua as usual. |

Close the game when done (QA lock).
