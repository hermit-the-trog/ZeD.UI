# Stepping aside for a mod that takes a screen: check, Nov 7 2026

The director's ruling (Nov 7 2026): automatic. When a mod loaded after ZeD has replaced a whole screen, ZeD hands that one screen back to the game and that mod, keeps the rest, and says so in Messages; ZeD setup lists it and the player can take it back, which sticks until the mod set changes. This closes the Workshop page's promise that ZeD steps aside for mods loaded after it.

## What was built
- `42/media/lua/client/ZeD/ZeD_StepAside.lua` (new). About 30 ticks into a game (once the game's Character Info window is built; at most 5 seconds) it checks the five ZeD screens that have a ZeD setup switch and Lua to replace: inventory windows, belt, character info, dashboard, quick wheels. The watch and the moodles are the game's Java, so there is nothing for a mod to replace there.
- The hand-back is the screen's own ZeD setup switch (Safe mode: ...), ticked and saved, so everything that already asks `ZeD.Safe.on(screen)` follows it. No new path through SafeMode.
- Notice: `ZeD.Messages.notice(head, text)` (new, in `ZeD_Messages.lua`): filed under "ZeD screens" in Messages, unread, with the toast out of the belt's Messages note. Text: "Wounds Overhaul [B42] has taken over a screen: character info. To turn ZeD's back on, go to ZeD setup and untick it under Safe mode."
- ZeD setup: the line under that switch reads "Taken by <mod>" while the mod has it (`ZeD_MainMenuOptions.lua` underLine, `ZeD_MainMenuOptionGroups.lua` rows carry `back`).
- Record: `Zomboid/Lua/ZeD_step_aside.txt` (the mod set, `set=` screens ZeD handed back, `kept=` screens the player took back).
- Eight new keys `UI_ZeD_StepAside_*` in all 28 languages (the screen nouns are the existing switch names' words).

## How "replaced" is decided (strict)
1. **A page of the Character Info window**: the game's window (`getPlayerInfoPanel`) holds, under one of the game's own page names (Info, Skills, Health, Protection, Temperature), a view that is not the game's class or one derived from it. The mod is the one whose file wrote that view's class (`getFilenameOfClosure` on its functions). This is how Wounds Overhaul is found: its examination sits in Health's slot under Health's name.
2. **A function a screen is built from** (`ISInventoryPage`, `ISInventoryPane`, `ISHotbar`, `ISEquippedItem`, the Character Info classes, `ISVehicleDashboard`, `ISRadialMenu:instantiate`; only functions the game itself has): the current one comes from a mod's file, and that file, read with `getModFileReader`, shows the function never calls the one it replaced. A copy of the old function kept (`local orig = X.f`, `T.old = X.f`) and called in the body (`orig(self)`, `if orig then orig(self) end`, `pcall(orig, ...)`) is wrapping. A dynamic name (`X[name] = ...`), a read this cannot follow, a file it cannot read, or a call to something named orig/old/prev/super/base/wrapped all count as wrapping: when unsure, ZeD keeps its screen.

Never counted: the game's own files, ZeD's own, a mod loaded **before** ZeD (load order is the player's way to keep ZeD's), a mod in ZeD's ModSupport list (`ZeD.StepAside.SUPPORTED`, the 25 MOD_IDs; `ZeD.StepAside.support(id)` adds one), and anything that only adds (menu options, buttons, tabs under new names, wrapped functions, functions the game never had).

`getFilenameOfClosure`, `getFirstLineOfClosure` and `getModFileReader(String, String, boolean)` were checked with javap on 42.21 (`LuaManager$GlobalObject`); the closure calls run only after `instanceof(fn, "LuaClosure")`. No `%f` patterns (Kahlua). No Kahlua debug.getinfo is used.

## Sim: `ZeDUI/tools/qa/step_aside_sim.lua` (184 checks, 0 failed)
Runs the real `SafeMode.lua`, `ZeD_Messages.lua`, `Overrides/CharacterInfo.lua` and `ZeD_StepAside.lua` on Lua 5.1 stubs of the game's classes, and the **real Lua** of Wounds Overhaul (64 files) and the seven mods, each from its Workshop folder in load order with the game's require (anything of the game they ask for that is not stubbed gets an inert stand-in; every file loads without error).
| Case | Result |
|---|---|
| WO after ZeD | WO's own code puts its examination in the Health page; exactly charinfo handed back (found by IGUI_XP_Health; WO's wrapped health functions do not count); the switch ticked and saved; one notice naming WO and "character info", unread in Messages, toast; "Taken by Wounds Overhaul [B42]" under the switch only; the Health key now opens the game's window (WO's page reachable) where before it went to ZeD's |
| Next start, same mods | still handed back, no second notice, the line read from disk |
| Player unticks | ZeD's again, `kept=` written, holds at the next start; unticked mid-game is noted within a second |
| Mod set changes | handed back again with a notice |
| WO removed | the switch goes back to ZeD's, the record forgets it, no notice |
| Player's own tick | never unticked by ZeD, no line |
| WO before ZeD | nothing handed back |
| The seven | nothing handed back, no notice (with the supported list emptied the reading still finds nothing in them: what they replace reads as calling through) |
| Fake mod replacing `ISInventoryPage:createChildren` | only the inventory windows, notice names it |
| Fake mod wrapping inventory and belt with the originals called | nothing |
| All together | inventory windows and charinfo, two notices |
| File reading shapes | field copy called, `X.f = function` with no call, the wheel built another way, a copy kept and never called, a dynamic name, `end` in long strings and quotes, an unreadable file, a function the game never had: each as expected |

On the code before this work the sim stops at its first check of `ZeD.StepAside` (it does not exist), exit 1.

Other sims that load the touched files: admin_cards, claim_cards, claims, community_cards, extras_cards, log_cards, menus_b7, spncc_fold, ticket_cards: all 0 failed. i18n guard: PASS.

## Not tested (needs the game)
- In game on 42.21 / 42.22: the format of `getFilenameOfClosure` for a Workshop mod's file (expected the full path, as Messages already relies on for call frames) and `getModFileReader` with the path after `media/`. If the path were not what is expected, nothing is handed back (the safe side) rather than the wrong screen.
- That WO's Health swap has happened by the check (it runs in WO's createChildren once the translations answer; if they did not, WO waits for a prerender the hidden window never gets, and ZeD keeps the screen).
- The toast's look out of the belt's Messages note, and ZeD setup's "Taken by" line at Large text in every language.
- Main menu screens: the main menu has no ZeD setup switch of its own, so it is not part of this; a mod replacing the main menu is not detected.
- Multiplayer (client side only; the server's mod list is the one checked).
