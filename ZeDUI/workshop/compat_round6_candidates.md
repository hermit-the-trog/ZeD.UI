# Compatibility round 6: new popular Build 42 mods since Oct 29 2026

Survey date: Nov 7 2026, signed out, read-only.
- **Done set:** 999 Workshop ids from rounds 1 to 5 and the Compatibility thread files.
- **Pages read:** 16 browse pages:
  - 7-day trending, Build 42, pages 1-5;
  - 30-day trending, Build 42, pages 1-5;
  - most recent, Build 42 + Interface, pages 1-3;
  - most subscribed, Build 42 + Interface, pages 1-3.
- **Not tested before:** 263 of the mods listed. The most-subscribed Interface list held none: everything new is recent and small.
- **Detail pages:** 40 opened.

The mods were downloaded with SteamCMD's `workshop_download_item`, so the director's Workshop subscriptions don't change. No mod in the test sets ships Java (.jar, .dll or .class files checked).

**Where the copies are:** `C:\steamcmd\steamapps\workshop\content\108600\<id>\mods\<folder>`. Keep them. The seven mods to support (the director, Nov 7) are in these folders:
- 3835479468 `AutoHideHotbar`;
- 3832759095 `MaskFilterIndicator`;
- 3834708364 `ItemConditionRestored`;
- 3830103302 `BetterItemTransfer`;
- 3834856444 `Clear_SkillSheet`;
- 3834889317 `VIF_DualRender_B42` (Better Folders);
- 3834902827 `BetterModExperience`.

`batch_compat_r6.ps1` copies them into `Zomboid\mods` for a run and removes them after.

## Tested in game (round 6, `ZeDUI/tools/qa/batch_compat_r6.ps1`)

**Set A**, with a real following:

| Mod | Id | Subs (Nov 7) | ZeD surface | Requires |
|---|---|---|---|---|
| Build Anything by Minidoracat | 3830045886 | 8,806 | Build menu | Minidoracat UI Library 3789836701 |
| NeatUI Mechanics | 3832114824 | 2,176 | Vehicle mechanics window | NeatUI Framework 3508537032 |
| MiniMap - Map Watch | 3816406671 | 1,782 | Minimap through a worn watch | MiniMap 3763913359, UI Library 3789836701 |
| Shift World - Smart Watch | 3829853258 | 574 | A watch with extra pages (ZeD has its own watch) | none |
| You Are Here: The 1993 Atlas | 3833987918 | 546 | Paper map that fills in (map tab) | none |
| Mask Filter Indicator | 3832759095 | 476 | HUD above the hotbar (ZeD's belt) | none |
| Better Item Transfer | 3830103302 | 469 | Inventory right-click transfer menu | none |
| Pass It Over! | 3829124374 | 458 | Hand an item to another player | none |
| Stockroom | 3830007154 | 272 | Container and vehicle context menus | none |
| Gamepad QoL Suite | 3829468590 | 158 | Controller: inventory multi-select, D-pad radials | Custom Gamepad UI 3001154607 |

**Set B**, new and small, but each changes something ZeD replaces:

| Mod | Id | Subs | ZeD surface |
|---|---|---|---|
| Auto-Hide Hotbar | 3835479468 | 10 | The hotbar (ZeD's belt) |
| No Vanilla Moodles | 3834570592 | 3 | The moodle column |
| Better Mod Experience | 3834902827 | 13 | The Mods screen |
| Clear Skill Sheet | 3834856444 | 8 | The skills page |
| Better Folders | 3834889317 | 5 | Inventory lists |
| Item Condition Restored | 3834708364 | 45 | Item icons' condition overlay |
| Deck Patch | 3833717583 | 10 | Steam Deck controls |

**Left out:** A-Life NPCs on Map (3809068618, 8,106 subs). It needs the whole Project A-Life NPC mod, which is outside what ZeD supports.

## Results (Nov 7 2026, 4K, QA save, ZeD last in the load order)

Set A and set B each ran compat_r5.txt's suite through `zedqa_mods_run.ps1`:
- the small-screen probe;
- every tab;
- the item grid;
- the right-click list;
- the card on a controller;
- the map;
- exercise info;
- the dash props;
- the map pictures;
- Messages.

| Set | Result | Report |
|---|---|---|
| A (10 mods + 4 requirements) | 10 of 11 pass; the right-click list check failed | `qa/regression/2026-11-07_1234_mods_fullscreen4k.md` |
| B (7 mods) | 11 of 11 pass | `qa/regression/2026-11-07_1239_mods_fullscreen4k.md` |

The right-click failure was narrowed down by running the right-click check alone on smaller and smaller groups:
- Minidoracat's mods and NeatUI: clean.
- The other eight mods: failed.
- Shift World watch, 1993 Atlas, Mask Filter Indicator, Better Item Transfer: failed.
- Pass It Over, Stockroom and the two Gamepad mods: clean.
- Each of the four alone: only **Better Item Transfer** fails.

The real menu with Better Item Transfer on, pictured in both ZeD styles (`zedqa_ctx_bit.lua`, `qa/Nov7_compat_r6/bit_style1.png` and `bit_style2.png`): **the menu is full and works in both.**
- The game's own menu holds Eat, Drop, Place, More, Save to loadout, Move to and Rename, as the mod rearranges it.
- ZeD's icon strip shows every action.
- ZeD's list shows Eat, Place, Favorite, Set Unwanted, Move to, Set to be Unusable in Recipes, Drop, Save to loadout and Rename, with their submenus.

What the check caught is narrower: with this mod on, the first right-click after switching ZeD's Context menu option to the list came up as the icon strip. It happened in all 4 runs with the mod and in none of the 16 runs without it. Better Item Transfer moves and removes rows in the game's own option table (`table.remove` / `table.insert` on `context.options`, and `removeOptionByName`) and wraps the menu's icon drawing. For Build to look at; not a broken menu.

**Grades:**
- **Compatible:** Build Anything, NeatUI Mechanics, MiniMap Map Watch, Shift World Smart Watch, You Are Here 1993 Atlas, Mask Filter Indicator, Pass It Over!, Stockroom, Gamepad QoL Suite (with Custom Gamepad UI), Auto-Hide Hotbar, No Vanilla Moodles, Better Mod Experience, Clear Skill Sheet, Better Folders, Item Condition Restored and Deck Patch. This means no errors and every ZeD check passing.
- **Compatible with a note:** Better Item Transfer (the first list-style right-click oddity above).

What these runs prove: no errors, and ZeD's own surfaces still work with each mod loaded. They don't prove each mod's own feature shows inside ZeD's windows. Several draw on surfaces ZeD replaces, so their feature may simply not appear with ZeD on:
- Auto-Hide Hotbar, Mask Filter Indicator and Item Condition Restored draw on the game's hotbar or item icons, which ZeD's belt and grid replace.
- Clear Skill Sheet and Better Folders change the game's skills page and inventory list.
- Better Mod Experience changes the game's Mods screen, which ZeD replaces.

Checking each of those by eye, and deciding whether ZeD should support any of them, is the "mods to support" part of the beta 9/10 list.

## Watch list (opened, not tested)

- Better Folders: an inventory folder system, tested in set B.
- Enhanced Chat 3834311841 (chat window).
- Vehicle Dashboard 3835303034 (no description yet).
- MyPhone 3834896463 and GlocOS 3833789388 (phone windows).
- EndofTheLivingMainMenu 3833539717 (a main menu).
- Tactical Telemetry HUD 3835417025.
- Immersive Held Map 3834832757.
- The roughly 25 add-ons for Project Viewpoint. Viewpoint itself waits on the test-machine question in `java_test_vm_research.md`.

## Skipped by the standing rules

- **Cheat and spawner mods:** Cheat Menu 2.0 - Rax's Reborn 3815818643, Project Zomboid Cheat Menu 3833837947, Cheat Menu! 3833580647, WorldEdit by Endri 3833539356.
- **Mods that need ZombieBuddy:** Tooltip Auto Wrap 3833495053, Gurg - Draw On Map Minimap Visibility 3833945217, Digital View 2000 3832084972.
- **Manages Java mods:** KJ Mod Manager 3834476323. It replaces the game's mod manager.

## Parallel overhauls

- No new full-UI overhaul turned up. Xen's Enhanced GUI (3819012597) remains the known one.
- Rising families: NeatUI (NeatUI Mechanics is new) and Minidoracat's UI Library (shared by Build Anything and Map Watch).
