# Handoff: multiplayer surfaces, design (Nov 5 2026)

For a design session with the director. Nothing here is built. Build writes the code once the answers come back; QA
checks it on the local server.

## Why

On a server, ZeD shows the game's own chat, server and admin windows, or nothing at all. They are the only parts of
the screen that are still the game's and not ZeD's. Players on servers need them, and The Indie Stone will see
them in the presentation.

The director asked on Nov 5, during QA's first multiplayer check, for four things:
- a **Client** window: the server, its players and your account;
- an **Admin** window;
- **chat** on the belt instead of parked in a corner, which the director never looks at;
- a **PvP** switch and a marker showing whether PvP is on.

## What the game has today (42.22)

- **Chat** (`client/Chat/ISChat.lua`): a box at the lower left with tabs (General, Say, Shout, Faction, Safehouse,
  Admin, Private), timestamps, a font size menu, fading when idle. ZeD's D-pad wheel only puts the cursor in it.
- **User panel** (`ISUI/UserPanel/ISUserPanelUI.lua`): Server info, Connection info, Factions (create, add a player,
  tag), Safehouse (members, add a player, release), Tickets (ask the admins) and the server options to read.
- **Admin panel** (`ISUI/AdminPanel/ISAdminPanelUI.lua`), admins only. 20 tools:
  - people: users, roles, admin powers, factions, safehouses;
  - the server: tickets, statistics, the mini scoreboard, the server options, the sandbox options, the PvP log;
  - the world: weather and climate, safe zones, non-PvP zones, the zone editor, the item list and editor, the loot
    log, build cheat on/off;
  - also "check your stats".
- **PvP**: the game's belt shows a safety button when the server's SafetySystem is on. It is red or green, has an
  outline inside a non-PvP zone, and shows a countdown while it switches (`ISUI/ISEquippedItem.lua:208ff`).
- **Scoreboard** (`OptionScreens/ISScoreboard.lua`): players on the server, opened from the pause menu.

To check first (QA): ZeD replaces the belt. On a server, can a player still reach the user panel, the admin panel
and the PvP button anywhere, for example from the pause menu? If not, these surfaces are missing outright, not just
unstyled.

## Questions for the director

Each has options, with Build's recommendation first.

**1. Where do they live?**
- a) A **Server** tab in the Character window, for you on this server: the server and its players, your safehouse,
  your faction, PvP, tickets. **Admin** is an admin-only tab in the World window, since it acts on the world.
  Both tabs show only on a server. (QA's suggestion; recommended. It follows "me and my stuff" and "the world and
  its stuff".)
- b) Both in one **Server** tab in the Character window, with Admin as a section only admins see.
- c) Their own windows, opened from the belt or the ZeD menu, outside the window pair.

**2. Chat**
- a) A **chat key on the belt** next to Messages, with an unread count. It opens a chat window you drag around and
  that stays where you put it, like the watch. Tabs as the game's (General, Faction, Safehouse, Private, Admin).
  Recommended.
- b) Chat inside the Messages window as its own group, so everything you read is in one place.
- c) a), plus new lines showing for a moment over the belt, like the overhead notes.

Also for chat: should it fade when idle, as the game's does, or stay put? And on a controller, does the chat key
open the pad keyboard at once?

**3. PvP**
- a) The switch in the Server tab; the marker on the **belt**, a small status dot with the words "PvP on" or
  "PvP off", plus an outline inside a non-PvP zone. Recommended: the belt is always on screen, the title bar isn't.
- b) The marker on the Character window's title bar.
- c) Both.

Also: while it switches (the game's countdown), does the marker show the seconds left?

**4. Admin scope for the first pass**
- a) The everyday tools: players (kick, ban, teleport to, admin powers), server messages, tickets, safehouses and
  factions. The rest stays the game's own windows, opened from the tab. Recommended: the tools an admin uses
  every session first.
- b) Everything the game's admin panel has, in one go.
- c) Players only.

**5. Simple version.** Every surface gets a Simple version alongside. Is a plain list with buttons enough for these,
or do any of them get an immersive look (a CB radio-style chat, a clipboard for the admin)?

**6. Era wording.** ZeD's frame is ZNIX, a prepper's kernel. Should the server surfaces keep the game's words
("Server", "Admin", "Chat"), or take ZNIX words ("Network", "Operator", "Talk")? Recommended: the game's words, by
the house rule that vanilla wording wins when the meaning matches.

## Ground rules any mockup follows
- The Visual Catalog v2.0 first, then System 7.1.2 chrome and the two Fira voices.
- Cards fit the drawer's full card width (480) at most.
- Help goes in the help band, never tooltips.
- Full controller parity.
- No scrolling inside scrolling.
- American spelling, and no middle dots.

## Answers back
Write the answers to `ZeDUI/MP_DECISIONS.md`, with any mockups under `ZeDUI/mockups/` (the name and version in
the file name). Then tell Build "read the multiplayer decisions". Build turns them into punch list items and builds
them in that order: the Server tab and the PvP marker, then chat, then Admin. QA checks each on the local server
(`ZeDUI/tools/qa/mp_server.ps1 -Start`, `zedqa_run.ps1 -Mp`).

## Related, already in hand
- Fixed: unequip on a server and the watch's speed keys (2e319d78); the container click (7e1a49c2); the speed
  controls hidden from the join (7e1a49c2).
- Open: Cooking's Make stops on a server. Waiting on QA's comparison with the game's own add-an-ingredient.
- Not tested: more than one player, a server on another machine, Steam joining, PvP, safehouses, factions.
