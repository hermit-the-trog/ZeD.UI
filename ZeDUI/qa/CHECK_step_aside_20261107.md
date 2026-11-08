# Stepping aside for a mod that takes a screen: check, Nov 7 2026

The director's ruling (Nov 7 2026): automatic. When a mod (in either load order, the director's later pick) has replaced a whole screen, ZeD hands that one screen back to the game and that mod, keeps the rest, and says so in Messages; ZeD setup lists it and the player can take it back, which sticks while that same mod is the one taking it. This closes the Workshop page's promise that ZeD steps aside for mods loaded after it.

## What was built
- `42/media/lua/client/ZeD/ZeD_StepAside.lua` (new). About 30 ticks into a game (once the game's Character Info window is built; at most 5 seconds) it checks the five ZeD screens that have a ZeD setup switch and Lua to replace: inventory windows, belt, character info, dashboard, quick wheels. The watch and the moodles are the game's Java, so there is nothing for a mod to replace there.
- The hand-back is the screen's own ZeD setup switch (Safe mode: ...), ticked and saved, so everything that already asks `ZeD.Safe.on(screen)` follows it. No new path through SafeMode.
- Notice: `ZeD.Messages.notice(head, text)` (new, in `ZeD_Messages.lua`): filed under "ZeD screens" in Messages, unread, with the toast out of the belt's Messages note. Text: "Wounds Overhaul [B42] has taken over a screen: character info. To turn ZeD's back on, go to ZeD setup and untick it under Safe mode."
- ZeD setup: the line under that switch reads "Taken by <mod>" while the mod has it (`ZeD_MainMenuOptions.lua` underLine, `ZeD_MainMenuOptionGroups.lua` rows carry `back`).
- Record: `Zomboid/Lua/ZeD_step_aside.txt` (the mod set, `set=` screens ZeD handed back, `kept=` screens the player took back).
- Eight new keys `UI_ZeD_StepAside_*` in all 28 languages (the screen nouns are the existing switch names' words).

## How "replaced" is decided (conservative, after the review of Nov 7 2026)
The rule: a mod that only adds must never cost a player a ZeD screen. Most mods add a tab or a button by copying one of the game's functions and editing it, so one replaced function is not evidence of a takeover.
1. **A page of the Character Info window** (unchanged): the game's window (`getPlayerInfoPanel`) holds, under one of the game's own page names (Info, Skills, Health, Protection, Temperature), a view that is not the game's class or one derived from it. The mod is the one whose file wrote that view's class (`getFilenameOfClosure`). This is how Wounds Overhaul is found, in either load order.
2. **Every core function of the screen's main class** replaced by one mod, none calling through (`SA.CORE`): inventory `ISInventoryPage` createChildren + prerender + render; belt `ISHotbar` render + update + refresh; character info `ISCharacterInfoWindow` createChildren + render; dashboard `ISVehicleDashboard` createChildren + prerender + render; wheels `ISRadialMenu` new + instantiate. All are functions the game's own media/lua defines (42.21).
3. **Anything less** (one copied function, a helper class, two of three) hands nothing back and says nothing to the player. One line goes to console.txt for QA: `[ZeD] Step aside: partial, ISInventoryPage:createChildren replaced by <mod id>; windows kept as ZeD's`.

Reading one function (`getModFileReader` on the file `getFilenameOfClosure` names): the body is found from the definition itself (`function Cls:method(` or `Cls.method = function`), so an inline function in its first statement is never taken for it; no definition found (a hook library, `c[n] = function`) counts as wrapping. A kept copy (`local orig = X.f`, `hooks = { render = X.render }`, `MyMod.vanilla.render = X.render`) that the body calls, with or without a dot before the call, is wrapping, as is a call to anything named orig, old, prev, super, base, wrapped, vanilla, og, default or `_<method>`. A read of the old function this cannot follow, a dynamic name or an unreadable file: wrapping. A plain definition with no copy kept and no call through is the only "replaced".

Load order does not matter (the director, Nov 7 2026: "Either order"). The game's own definitions sit in no mod's folder. Never counted: the game's own files, ZeD's own, a mod in ZeD's ModSupport list (`ZeD.StepAside.SUPPORTED`, the 25 MOD_IDs; `ZeD.StepAside.support(id)` adds one).

A take-back is kept by the taking mod's id (`kept=<screen>|<mod id>`): adding or removing other mods does not take the screen again. It ends only when that mod no longer takes the screen; if it comes back later, it is asked again.

`getFilenameOfClosure`, `getFirstLineOfClosure` and `getModFileReader(String, String, boolean)` were checked with javap on 42.21 (`LuaManager$GlobalObject`); the closure calls run only after `instanceof(fn, "LuaClosure")`. No `%f` patterns (Kahlua). No Kahlua debug.getinfo is used.

## Sim: `ZeDUI/tools/qa/step_aside_sim.lua` (276 checks, 0 failed)
Runs the real `SafeMode.lua`, `ZeD_Messages.lua`, `Overrides/CharacterInfo.lua` and `ZeD_StepAside.lua` on Lua 5.1 stubs of the game's classes, and the **real Lua** of Wounds Overhaul (64 files) and the seven mods, each from its Workshop folder in load order with the game's require (anything of the game they ask for that is not stubbed gets an inert stand-in; every file loads without error).
| Case | Result |
|---|---|
| WO after ZeD | WO's own code puts its examination in the Health page; exactly charinfo handed back (by IGUI_XP_Health); the switch ticked and saved; one notice naming WO and "character info", unread in Messages, toast; "Taken by Wounds Overhaul [B42]" under the switch only; the Health key now opens the game's window where before it went to ZeD's |
| WO before ZeD | the same hand-back; a fake inventory before ZeD gets the inventory; a wrapper before ZeD gets nothing |
| Next start, same mods | still handed back, no second notice, the line read from disk |
| Player unticks | ZeD's again, `kept=charinfo|WoundsOverhaul`, holds at the next start, holds when an unrelated mod is added; unticked mid-game is noted within a second |
| WO removed, then back | ZeD's again without a notice, the record forgets it; WO back asks again with a notice |
| Player's own tick | never unticked by ZeD, no line |
| The seven | nothing handed back, no notice |
| Fake inventory (all three core functions of ISInventoryPage) | only the inventory windows, notice names it |
| Fake wrapper of inventory and belt | nothing |
| All together | inventory windows and charinfo, two notices |
| ADDS (the review's false positives), each through the whole check | nothing handed back and no notice for: one copied createChildren (with the partial line for QA), a copy-edited ISCharacterInfoWindow:createChildren adding a tab (partial line), originals kept in a table, originals named vanilla / og / default (`MyMod.vanilla.createChildren`), a hook library, an inline function in each first statement |
| READ, one function at a time | wrapping: field copy called, helper's wrapped, dynamic name, unreadable file, inline function in the first statement, table-kept, MyMod.vanilla.render, og, hook library; replacing: `X.f = function` with no call, the wheel built another way, a copy kept and never called, `end` in long strings and quotes |

The previous commit's ZeD_StepAside.lua fails the new cases (an unrelated mod re-taking the screen, the single copied createChildren, the copy-edited tab, the vanilla/og/default names, the hook library, the inline function). The code before this work fails at the first check of `ZeD.StepAside`.

Other sims that load the touched files: admin_cards, claim_cards, claims, community_cards, extras_cards, log_cards, menus_b7, spncc_fold, ticket_cards: all 0 failed. i18n guard: PASS.

## Not tested (needs the game)
- In game on 42.21 / 42.22: the format of `getFilenameOfClosure` for a Workshop mod's file (expected the full path, as Messages already relies on for call frames) and `getModFileReader` with the path after `media/`. If the path were not what is expected, nothing is handed back (the safe side) rather than the wrong screen.
- That WO's Health swap has happened by the check (it runs in WO's createChildren once the translations answer; if they did not, WO waits for a prerender the hidden window never gets, and ZeD keeps the screen).
- The toast's look out of the belt's Messages note, and ZeD setup's "Taken by" line at Large text in every language.
- Main menu screens: the main menu has no ZeD setup switch of its own, so it is not part of this; a mod replacing the main menu is not detected.
- A core function ZeD itself later wraps or replaces (ISCharacterInfoWindow:createChildren, the belt's `ISHotbar:render`) shows ZeD's, so a mod before ZeD that replaced it cannot complete the core set; the Character Info page check does not have this gap. A whole-screen replacement on the belt by function is therefore unlikely to be seen.
- The partial line is in console.txt only (no ZeD notes file).
- Multiplayer (client side only; the server's mod list is the one checked).
