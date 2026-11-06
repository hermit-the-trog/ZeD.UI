# Multiplayer surfaces: the director's decisions (Nov 5 2026)

Answers to `HANDOFF_design_multiplayer_20261105.md`, taken with the director in a design session on Nov 5 2026. He
picked Build's recommendation on every question. Build turns these into punch list items and builds them in this
order: the Server tab and the PvP marker, then chat, then Admin. QA checks each on the local server
(`ZeDUI/tools/qa/mp_server.ps1 -Start`, `zedqa_run.ps1 -Mp`).

No mockups yet: the layouts follow the existing tabs and cards (below). Design draws a mockup for any of them on
request.

## 1. Where they live
- **Server tab in the Character window**: you on this server. The server and its players, your account and
  connection, your faction, your safehouse, tickets (ask the admins), the server options to read, and the PvP switch.
- **Admin tab in the World window**, admins only: it acts on the world ("me and my stuff" / "the world and its
  stuff").
- Both tabs show only on a server; in single player they are not there at all.

## 2. Chat
- A **chat key on the belt**, next to Messages, with an unread count.
- It opens a **chat window** you drag, which stays where you put it, like the watch. Tabs as the game's: General,
  Faction, Safehouse, Private, Admin.
- **When idle it dims**, staying where it is, and a new line brings it back to full strength. It does not fade out
  the way the game's chat does.
- **On a controller**, the chat key opens chat to read. The pad keyboard opens only when you pick the input line
  (A on it), since most of the time you are just reading.
- Not chosen: chat inside Messages; new lines popping over the belt.

## 3. PvP
- The **switch** is in the Server tab.
- The **marker is on the belt**, always on screen: a status dot with the words "PvP on" or "PvP off", an outline
  while inside a non-PvP zone, and the seconds left while it switches (the game's countdown).
- It shows only when the server's safety system is on, as the game's own button does
  (`ISUI/ISEquippedItem.lua:208ff`).
- Not on the window's title bar.

## 4. Admin, first pass
- **The everyday tools**, redrawn in the Admin tab:
  - players: kick, ban, teleport to, admin powers;
  - server messages;
  - tickets;
  - safehouses and factions.
- **The rest** of the game's 20 admin tools stay the game's own windows, opened from the Admin tab: roles, statistics,
  the mini scoreboard, the server and sandbox options, the PvP log, weather and climate, safe and non-PvP zones, the
  zone editor, the item list and editor, the loot log, the build cheat, check your stats.
- Later passes can redraw more of them, the ones admins use most first.

## 5. Full and Simple
- **Plain now, immersive later.** The Full versions are ZeD's own lists and cards, in the house style. The Simple
  versions are the plain cards, as for every other surface.
- An immersive chat (a CB radio fits the world) is a later Design pass, not this one.

## 6. Wording
- **The game's words**: Server, Admin, Chat, Faction, Safehouse, Ticket, PvP. That is the house rule (vanilla wording
  wins when the meaning matches), and it is what players and server guides already say. No ZNIX words here.

## Ground rules (from the handoff)
The Visual Catalog v2.0 first, then System 7.1.2 chrome and the two Fira voices. Cards at most the drawer's full card
width (480). Help in the help band, never tooltips. Full controller parity. No scrolling inside scrolling. American
spelling, no middle dots.

## First, for QA
The handoff's open check still comes first: on a server, with ZeD's belt replacing the game's, can a player reach the
user panel, the admin panel and the PvP button anywhere today (the pause menu, for example)? If not, those are missing
outright until the Server and Admin tabs land, and that goes on the beta's known issues.

## Round two (Nov 5 2026): the full scope
The director: solve all of the multiplayer and admin problems in ZeD itself. The plan is `MP_ADMIN_SCOPE.md`: a server
part (official Lua), gameplay systems as server settings off by default, ZeD's features always working on their own
while reading other mods' data where it can, and reports and tickets first.
