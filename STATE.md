Draft, Nov 8 2026: needs the director's check before it is trusted.

# ZeD-UI — STATE

One page. What is true right now. Rewritten at every closeout, never appended to.
History lives in `docs/archive/PROJECT_STATE.md` (through S122), `ZeDUI/deltas/`, PUNCH_LIST.md and the change notes in `ZeDUI/workshop/`.

**Version:** work is on **0.3.0-beta8** (the director, Nov 8 2026). `42/mod.info` still reads 0.3.0-beta7 and needs bumping before staging; beta 7 never went up, so beta 8 carries everything since beta6a.
**Live on the Workshop:** 0.3.0-beta6a (live Nov 6 2026), item 3824968485 [check that nothing went up since]. Beta 7 was staged and passed the release check on Nov 7, but the director's evening plan was no upload Nov 7, the next one by noon Nov 8 (VANILLA_WINDOWS_20261107.md). Gallery spread 46 already went up for beta 7, since gallery images go up apart from the mod's files.
**Full release:** Dec 1 2026 (the director's release plan, Nov 7). The page says the release will be a separate Workshop item.
**Game:** Build 42 stable 42.21. The director switched the game to 42.21 on Nov 7 and the release check runs there; code checks also read the 42.22.2 jar. The page says tested on 42.21 and 42.22. `versionMin=42.17.0`.
**Last code change on main:** Nov 7 2026, the second wave for the Nov 8 upload (merge 435e394). A comments-only pass is running on a branch on Nov 8 [check].
**Next:** QA in the game on both waves, then the change note and page rewritten for what really ships, then the upload. See NEXT_SESSION_HANDOFF.md.

## The beta line since Oct 13

From the change notes (`tester_changenote_<version>.txt`). Upload dates other than t16 (Nov 2) and beta6a (Nov 6) are not in these sources [check].

- **0.2.0-t11 to t16:** tester builds, the last uploaded Nov 2 2026 (tag v0.2.0-t16). t16 brought the small-screen main menu, a look at what a recipe makes before you make it, controller multi-select, the Simple belt and Safe mode one screen at a time.
- **0.3.0-beta1:** the beta. Full or simple in ZeD setup, the controller map, Bug report in the ZeD wheel, machine drafts of Turkish, Simplified Chinese and Brazilian Portuguese, This Is Your Life support, ZeD's version in About, 0.5x scale gone.
- **beta2:** machine drafts of every language the game has (28 with English), the Cooking tab, the Vehicle tab in two columns with pixel-art car diagrams.
- **beta3 / 3a:** the survival guide on F1 (the 1987 book or a plain window), the hint strip, overhead notes into ZeD's bubble and Messages, title-bar pins, the Mods screen's readability; 3a: the windows roll up like the game's inventory.
- **beta4:** multiplayer: the Server tab, the PvP marker, ZeD's chat, the Admin tab.
- **beta5:** ZeD's scroll bar everywhere, one-line buttons, the corkboard change note, the Animals tab's lag fixed.
- **beta6 / 6a:** ZeD's server part (official Lua), tickets, the Player card, bans, safehouse and faction cards, the Log, join rules; the radial wheels redesign (tap to open, toggle mode); the Identity tab redrawn, Immersive and Simple. 6a: the outside review's server and card fixes.
- **beta7 (staged Nov 7, not uploaded):** survival guide ads, a contents that runs onto more pages, odometers and trip odometers, the ACC key position, one kill count everywhere, padlocks in the half card, the Z menu's version, the clip fix for tabs and cards.

## On main for beta 8, beyond the beta 7 change note

Built Nov 7, each part reviewed and passing its sim. Most commits say "not run in game"; each part has an in-game list `CHECK_<part>_20261107.md` in `ZeDUI/qa/` [check which have been run].

- **Wave 1** (merge 5caf70f): the survival guide's copyright page (punch list 103) and 32 more third-size ads (66 ads in all); multiplayer rules that hold against a modified game, with an optional host helper; respawn back to the desk in ZeD's Spawn, Traits and Looks windows; TV, radio and animal windows to ZeD's cards; Read Map opens ZeD's map on that paper; km/h on the digital dashes and the Simple dash with Metric; seven more supported mods (Auto-Hide Hotbar, Mask Filter Indicator, Item Condition Restored, Better Item Transfer's menu fix, Clear Skill Sheet, Better Folders, Better Mod Experience; compat round 6).
- **Wave 2** (merge 435e394): the last main menu screens as ZeD's (server Workshop items on join, Steam invites, world select, terms of service, the controller button map and test, advanced game sounds; Tutorial labeled as the game's own); trading and the medical check of another player as World window cards; admin tools as ZeD cards (player stats, inventory, other players' claims, users, statistics, PvP log, climate, zones, server sandbox options); the multiplayer windows the game still opened (Players, Invite, server options, saving, map sharing, Edit item, admin notes, the kicked screen); the debug Lua console as a ZeD window; Wounds Overhaul support; step aside (a mod that replaces a whole ZeD screen gets it, with a notice in Messages); the desk's notes (sticky note, CletusWorks Notepad, Documents) and ProtoPOP3 Mail, dial-up style, held on the server; everyday leftovers (heater on the dash, no mini-map in the wheels, make-up in Hair and beard, the Character window while paused, notices out of the belt's Messages note, a general station card).
- **Known issues fixed since the beta 7 note was written:** ZeD picks comes back whichever way ZeD-GUI goes off and on; a second split-screen player gets the game's own windows, a belt and a dash, and keeps dash miles on a server; Death then Restart goes to ZeD's desk; FR and HU months in lower case; the dash ash tray is the car's on a server.

## What ships (the surfaces)

- **Character window:** Loot | Equip | Health | Thermal | Identity (Immersive license or Simple; Hair and beard with make-up) | Journal | Skills | Traits (with Traits As Skills) | Cooking (contextual) | Radio (contextual) | Server (on a server) [check the tab order]. The drawer is the universal detail surface; ItemCard with Progress Band.
- **World window:** Loot | Craft | Build | Furniture | Maps | Forage | Animals | Radio | Vehicle (two columns) | Admin (staff) [check the tab order]. Object cards in the card drawer: stations and machines, fires, generator, farm plots, hutch, trough, hook, tracks, padlocks, fluids, placement, trade, medical check, the admin cards.
- **HUD:** the belt (hands, hotbar, buckle; Simple belt), the watch, the dashboards (19 designs, odometer and trip, ACC; Simple strip), moodles in three places, ZeD's action bar, the hint strip, overhead notes, the PvP marker and chat on a server.
- **Main menu:** the pixel-art desk; every screen behind it a ZeD window on the monitor, now including the join, invite, world select, terms and kicked screens; the corkboard change note; the desk's notes and mail.
- **Controller:** full parity as the floor; the redesigned radial wheels and D-pad wheels; the controller map and live button test; button pictures for Xbox, PlayStation, Steam Deck and Nintendo.
- **ZeD setup:** Look, Full or simple, HUD, Controls, Safe mode one screen at a time, presets (Vanilla, Vanilla Plus, Vanilla Access, Custom). Punch list 110 renames Full or simple to Immersive or simple; it is on a branch, not on main [check].
- **Survival guide (F1):** the book or the plain window, the game's rules read live, ZeD's own chapters, the ads, the copyright page.
- **Multiplayer:** ZeD's server part, tickets, the Admin tab and cards, safehouses, factions, the Log, join rules, mail. Server extras are off by default.
- **Languages:** 28, every one but English a labeled machine draft. Fonts: Fira Sans and Fira Mono, Noto Sans SC for Simplified Chinese.
- **Theme:** dark, light, high contrast; nine accents; two text sizes; see-through windows.
- **Dev:** `QABridge.lua` (`-debug` only) runs bridge suites from `ZeDUI/tools/qa/`; sims run outside the game; `release_check.ps1` is the release check; HOOK_MAP.md lists every vanilla UI entry point.

## Known issues (for the Nov 8 page)

From the beta 7 change note and page, less what wave 2 fixed [check the final list before upload]:

- Hands-On Interactions (Isometric): a haircut or beard trim can stop with a game error. The note to its author and the report to The Indie Stone are drafts, not sent [check].
- Join rules and timed bans are enforced by the player's own game; a modified game can get past them. Wave 1 adds server-side rules that hold; the page's wording may need to change [check].
- ZeD picks only came back by ZeD-GUI's own row; fixed in wave 2, so this line comes off the page if QA confirms it.
- Split-screen: player 2 and later get the game's own windows. ZeD windows for every local player is punch list 107, before Dec 1.
- Survival guide clips show the game's own screens.
- Multiplayer tested on a local server with two players.
- The EquipPacket lines in the server log are not ZeD's as far as the code shows; the proof run with ZeD off is open (punch list 100).

## Gamepad model

D-pad navigates inside a window (left-biased, U/D stays in the panel, L/R crosses). A = left mouse, X = right mouse / context menu (hold = drag), B = contextual cancel, Y = window-pair toggle (hold = close both), LB = Character window, RB = World window. Tabs switch on A. Focus paints like hover. With no window holding the pad, the D-pad opens the wheels (tap to open since beta 6; toggle mode needs no held input and no stick). L3 / R3 only inside a window (L3 sorts, R3 flips List / Grid), never in the world. Full spec: GAMEPAD_SPEC.md, RADIAL_WHEELS_SPEC.md, DPAD_WHEELS_SPEC.md. The director's first hands-on pad test fed the Oct 23 gamepad pass; the redesigned wheels have not been on a real pad yet (MORNING_BETA6_20261106.md) [check]. Until the director's last controller pass, the pad is simulated through the bridge.

## Rules that bind every session

No `border-radius`. 1px borders (2px on High Contrast). No soft shadows, no blur: System 7's hard 1u shadow, on pop-ups only. No all caps in the windows; status marks are 6u squares; no web patterns (pills, switches, segmented pairs). Fira only (Noto Sans SC for Chinese). No emoji. American spelling. Atoms → Molecules → Organisms; read `ZeD.T` fresh each frame; no `Tokens.lua` mutation. Never skin vanilla: any vanilla script that shows UI gets hooked at its entry point and designed for (HOOK_MAP.md). Every added feature can be turned off. Every fix goes on PUNCH_LIST.md with its check, and nothing is done until QA has seen it in the game. QA only in the zombie-free QA save; on 42.21 that is the Oct 27 copy, since the 42.22 save stalls at the convert prompt [check the save's name]. Code comments follow COMMENT_VOICE.md. Full rule set: GLOSSARY.md and the design-rule sections in `docs/archive/PROJECT_STATE.md`.

## Where things are

`42/media/lua/client/ZeD/` code (`Overrides/` = vanilla hooks, `ModSupport/` = one file per supported mod) | `shared/ZeD/Tokens.lua` tokens | HOOK_MAP.md vanilla UI ledger | PZAPI-KNOWLEDGE-BANK.md engine quirks | KAHLUA-JAVA-BACKEND.md | PUNCH_LIST.md the build / QA handoff | QA_CHECKLIST_BETA.md the two QA passes | BETA_DECISIONS.md | VANILLA_WINDOWS_20261107.md the last vanilla windows and the release plan | MP_ADMIN_SCOPE.md | specs by name: GAMEPAD_SPEC.md, RADIAL_WHEELS_SPEC.md, DPAD_WHEELS_SPEC.md, VEHICLE_TAB_SPEC.md, COHESION_SPEC.md, CONTEXT_MENU_SPEC.md, TOOLTIP_SPEC.md, CRAFTING_SPEC.md, DASHBOARD_WATCH_SPEC.md, MESSAGES_SPEC.md | TRANSLATING.md | RELEASE_CHECKLIST.md | `ZeDUI/workshop/` change notes, page text, compat rounds, Steam threads | `ZeDUI/mockups/` | `ZeDUI/qa/` check lists, reports, captures | `archive/` retired docs.
