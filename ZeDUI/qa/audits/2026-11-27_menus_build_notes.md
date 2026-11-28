# Menus sweep: Build's notes for QA (Nov 27 2026)

Branch fix/menus (worktree %USERPROFILE%\ZeD-menus), off main b4b2d94d3. Six area branches merged in: fix/menu-desk,
fix/menu-newgame, fix/menu-ljh, fix/menu-options, fix/menu-mods, fix/menu-order. Not run in the game.
Checks: KCheck all parsed, kahlua_guard PASS, i18n_guard PASS (DA and FR got the 15 new keys), 241 sims clean
(6 new: desk_, newgame_, ljh_, options_, mods_, order_menu_fixes_sim.lua; mainmenu_vanilla_sim A2 fitted for LJ35).

Held (design calls): DK13, DK48, OP72, OP29, OP24, MM25, MM31, MO40, LJ37.

## Fixed, by id (not fixed: none)
Desk: DK59, DK19, DK58, DK51, DK14, DK2, DK18, DK21, DK30, DK44; Mods leave route MM2, MM3, MM5.
New game: NG34, NG50, NG51, NG39, NG12, NG30, NG23, NG62, NG4, NG61.
Load/Join/Host: LJ10, LJ24, LJ25, LJ36, LJ49, LJ30, LJ33, LJ34, LJ18, LJ12, LJ9, LJ35, LJ56, LJ57, LJ2, LJ16, LJ43, LJ44, LJ40.
Options: OP43, OP44, OP46, OP61, OP74, OP75, OP76, OP33, OP5, OP31, Find frame cost.
Mods: MM53, MM57, MM4, MM64. Folders and order: MO5, MO8, MO9, MO12, MO13, MO32, MO33, MO43.

## Known gaps and judgment calls
- NG23/NG62: turning safe mode off while the desk is on Spawn or Looks shows an empty map or figure box until reopened.
- NG4: in the capped New game window the description now shows whole (touches the NG5 design call).
- NG39: load prefers the user's file over a built-in of the same name (the game allows the name).
- LJ35: the invite view no longer shows host : port in any mode (one line to keep it outside Streamer mode).
- LJ30: keyboard arrows step over the mode heads; save rows now share row numbers with the heads.
- LJ40: a new account made from Connect on a public server is not kept on a saved server.
- LJ43: no range check on the port, as before.
- OP43: the Find text box can still take focus under a question.
- MM53: a pasted name that cannot be a profile ("No mods", "@...") is turned away with its own line.
- English meaning changed in UI_ZeD_MMHelp_WorldNext, UI_ZeD_Folders_SayMovedMany, UI_ZeD_Folders_SayOutMany and
  UI_ZeD_Seps_HelpFromFolders; the other languages keep the old meaning until the next translation pass.

## mu_ checks whose reads change (QA's to refit)
- mu_desk 1757-1769 DK59: MM.showView("main") with an edited description now opens the editor's question; done stays 0
  and the question stays open.
- mu_mods X.revisit("MM2") 1150-1155: showView("main") opens Back's question and MM.openMods returns early on the
  player's own list; any revisit with a change waiting meets the question.
- mu_mods MM53: pastePreset() over an existing name now asks; the replace needs w:pastePreset(true).
- mu_new ~1594-1597 NG51: saving again under the same name asks; w:saveBuild(true) is the Replace answer.
- mu_new ~469-493 NG4: should read w.bodyScroll and w._body, or count only cells in view.
- mu_new ~1535-1552 NG50: the band is no longer a fixed 54 units; use w:helpHeight(w._cols, w.width - 2*pad, pts).
- mu_ljh LJ16: the label is now the game's UI_servers_version, not "Version".
- mu_ljh LJ44: real rows give the second server "s:ip:port#2"; the check builds plain keys.
- mu_ljh new pad ids: "players", "field:rename", "load:rename", "tick:<id>", "sort:<col>", "field:code",
  "join:f:band", "head:<mode>". Load and Join also track _lastClickKey.
- mu_opt 1491-1496 OP46: Back with nothing changed now closes Options; the walk must reopen it.
- mu_opt 920-934 OP31: judge against the grown band (w:helpLinesFor) and accept the ellipsis.
- mu_opt 788-801 OP33: check w._palette.at equals w._palette.near.
- mu_opt 2094 and 2108 OP75, OP76: the fix is in the welcome's done(), not St.loadSetup.
- mu_order MO8: SayMovedMany's text changed (should pass).
