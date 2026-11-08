# Belisar's three mods with ZeD (beta 8), Nov 8 2026

Game: Project Zomboid Stable 42.21, ZeD 0.3.0-beta8 (main at 5ac83525), 4K at 1.75x, `-nosteam`. The mods came from SteamCMD (no subscription), were copied into Zomboid\mods for the runs and removed after. None ships Java (.jar/.dll/.class) and none is a cheat or spawner. All three loaded together with ZeD last: no Lua error from any of them in console.txt.

Scripts: `ZeDUI/tools/qa/batch_belisar.ps1` (runs), `zedqa_belisar_menu.lua` (tag belm, main menu), `zedqa_belisar.lua` (tag bel, in game), lists `belisar_mods.txt` / `belisar_mods_nozed.txt`, manifests `belisar_manifest*.txt`. Console extracts: `belisar_console_menu.txt`, `belisar_console_game.txt`, `belisar_console_base.txt`; step aside records: `belisar_step_aside_*.txt`. Pictures (small copies of the 4K shots): `belisar_shots/`. `zedqa_mods_run.ps1` gained a `-NoZeD` switch for the baseline (ZeD off, the QA shim's bridge instead).

## Step aside (all three together, ZeD last)

`ZeD.StepAside.found` is empty, `detect()` finds 0 screens, nothing handed back, no notice, no set= line in ZeD_step_aside.txt (the file was restored). None of the three replaces a whole ZeD screen, so step aside correctly stays out. (A caution: Stay With Me's design screen is not one of the screens step aside watches, see 1.)

## 1. Stay With Me (Albrecht, id `Bridge`, 0.6.2.1): WORKS, but its screen is the game's look, not ZeD's

What it does: a companion NPC. Its "design your companion" screen is a full-screen panel it adds to the main menu. It wraps `CharacterCreationMain.onOptionMouseDown` and the Play button's click, so that Next/Play on the last character step opens its own screen first (`BridgePregame.intercept`), hides the character creation view and, when done, finishes the game's own Play. The screen has its own saved-looks list ("Select to load", `BridgeLooks`), Save/Del, name, skin, hair, beard, make-up, clothing, behavior options. In game it also wraps `ISInventoryPage.refreshBackpacks`, `update`, `canPutIn` and `ISHotbar.doMenuFromInventory`, and adds radial and context entries.

With ZeD (main menu, new Sandbox game, ZeD's Looks window, Play): ZeD's Play sends the game's NEXT, the mod's wrapper catches it and its screen opens at 3840x2160 over the whole menu. ZeD's desk is hidden under it. The mod's presets list was there, held "As I found him", and picking it ran without error (`zqa_belm_3_preset_picked.png`). The mod's Back returned to ZeD's Looks window (ZeD view "looks", mod inactive). So nothing is broken in what Belisar describes, but what he sees is the mod's own screen in the game's default look (flat dark panel, small default text), which is what "reverts to the game's default" most likely means: ZeD does not skin another mod's screen, and a mod that opens its own full screen is never handed back by step aside (it replaces no ZeD screen, it adds one). On "lose the ability to select a preset": the mod's own list works in this test; ZeD's own Presets... button (the game's saved outfits) exists only on ZeD's Looks window, which is hidden while the mod's screen is up. Not tested by hand with a real mouse click on the mod's list (the script called its handler), and only with one built-in preset (no saved looks of my own), so a click problem or a missing saved look cannot be ruled out; worth asking Belisar which preset he means.

Evidence: `belisar_shots/menu_1_zed_looks.jpg` (ZeD's window just before Play), `menu_2_companion_design.jpg` (the mod's screen), `belisar_console_menu.txt`.

Verdict: works / handed back not needed. Support to make it look like ZeD: LARGE (rebuild the companion design screen as a ZeD window on its own controls: about 3,000 lines of the mod's screen logic in BridgePregame.lua and BridgeAppearance.lua, and it changes with every mod update). SMALL option: a one-line note in the mod page and ZeD's Looks Play unchanged.

## 2. NeatUI Equipment (Gimmi, id `NeatUI_Equipment` 1.0.2, needs NeatUI Framework): NOT SHOWN (loads, does nothing visible)

What it does: attaches an equipment panel (3D character, slots, hotbar slots, Wardrobe of saved outfits, a chain button to undock) to the game's inventory window (`ISInventoryPage:createChildren`, pin handling on its mouse handlers) with a small toggle button on the window's edge, plus a key (comma) and a controller button. It is built to sit beside CleanUI.

With ZeD: ZeD's Inventory window replaces the game's inventory page, which stays hidden. The mod's panel exists (`NEQ_InventoryPage.getPanel(0)`) but is hidden, its toggle button has zero width at (0,0), and `togglePanel` (what the button and the key call) leaves it hidden ("toggled: false -> false"), because everything hangs off the hidden page. So the gear presets (Wardrobe outfits) cannot be reached. Baseline with ZeD off and the game's inventory shown: panel visible, toggle button 34x34 at the window edge, toggle works. No errors either way.

Evidence: `belisar_shots/game_neq_zed.jpg` (ZeD, no panel), `base_neq_zedoff.jpg` (ZeD off, panel beside inventory), `belisar_console_game.txt` / `_base.txt`.

Verdict: not shown, not broken. Support: LARGE for real parity (an outfit/Wardrobe feature in ZeD's Character window that reads and writes the mod's saved outfits, `NEQ_Outfit.lua` / `NEQ_Dresser.lua`, plus its 3D preview), MEDIUM for a minimal bridge (parent the mod's panel to ZeD's Inventory window and a button on it, but its docking math follows the game's page geometry and its drag/drop slots assume the game's inventory and hotbar). ZeD's own equipment and outfit features overlap the mod's purpose, so the director may prefer to leave it.

## 3. Minimal Sidebar (Devilzcore, id `MinimalSidebar` 1.4.1): PARTLY WORKS (the fade is mostly moot)

What it does: replaces `ISEquippedItem.prerender` and `render` (captured at load) to fade the left sidebar column and its buttons out until the pointer is near, keeping equipped hand items visible. Also fades `ISSafetyUI`.

With ZeD: ZeD's belt wraps the same two functions after it (ZeD loads last). ZeD's `render` does not call the one it wrapped (it draws no hand items, the belt does), so the mod's `render` never runs: the per-button fade hook (`_minimalFadeHook`) is on 0 of 14 buttons, versus 14 of 14 with ZeD off. The mod's `prerender` still runs through ZeD's, so the column's frame fades (fadeAlpha 0), but the buttons are not faded by the mod. In practice the sidebar is ZeD's: ZeD hides the column unless `-debug` is on (QA runs with it on, so the small icons at the left edge in the picture are the debug column) and the belt is the HUD. Which means a normal player sees the belt, not the mod, and "stopped working" is accurate: the mod's fade has nothing to act on. The belt is unchanged and the mod's options still exist.

Evidence: `belisar_shots/game_sidebar_zed.jpg` (ZeD: belt at the bottom, icons not faded), `base_sidebar_zedoff.jpg` (ZeD off: column faded away until hover); console lines "sidebar buttons carrying the mod's fade hook: 0 of 14" (ZeD) and "14 of 14" (off).

Verdict: not shown / no effect (by design: ZeD's belt is the sidebar). Support: SMALL if wanted: an auto-hide option for ZeD's belt (Auto-Hide Hotbar is already supported by ModSupport, so the belt already fades with that mod), and a one-line ModSupport file for MinimalSidebar that says "ZeD's belt replaces the sidebar" so it is not listed as broken.

## Not done

ZeD-off baseline for Stay With Me's menu screen (the menu script drives ZeD's windows). Real mouse and controller clicks on the mod's screens. The mod's companion in game was not spawned.
