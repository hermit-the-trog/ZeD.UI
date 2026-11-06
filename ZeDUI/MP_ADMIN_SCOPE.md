# Multiplayer and admin: the full scope (Nov 5 2026)

The director, Nov 5 2026: "multiplayer, admin stuff, I want to solve for all these problems. This is trying to be a one
mod solution while also being compatible and supportive of other mods. But we have to include as many features as we
can so we have control over those features should a mod go unresponsive for a while and out of date."

Follows `MP_DECISIONS.md` (the first pass, built in 0.3.0-beta4). Design session, Cowork. Nothing here is built.

## The four calls (the director, Nov 5 2026; each was the recommendation)
1. **ZeD ships a server part.** ZeD already has to be on the server (it adds the watch), so it also runs server-side
   Lua, official API only, to keep its own records: ticket history with times and places, an action log, temp bans,
   claim timers. Everything degrades cleanly on a server without it: ZeD's screens fall back to what the game stores.
2. **Gameplay systems are built in, server opt-in, off by default.** Vehicle claims, extra safehouse protection, staff
   map teleport, a player economy: each a server setting, off unless the owner turns it on. Solo play and
   vanilla-rules servers are untouched, so "hardcore and builder safe" holds.
3. **Overlap with other mods: ours always works, and reads theirs too.** ZeD's feature never depends on another mod.
   Where another mod covers the same ground and its data can be read, ZeD shows it beside its own instead of fighting.
4. **Order: reports and tickets first**, then admin clarity, safehouses and factions, logs, community, the opt-in
   systems.

## What server people are mad at (research, Nov 5 2026)
- Their all-in-one admin mods are gone: bikinitools: Server Edition ("kept Multiplayer alive in b41") and Server
  Tweaker were removed from the Workshop and are marked incompatible; Server Tweaker's B42 port dropped most features.
- Griefing reports can't be answered from the game: who, where, when. Admins add Log Extender for it.
- The admin panel hides and doesn't explain: the button only with an admin tool, grayed buttons on custom roles with no
  reason, promotion silently turns on invisible / god / noclip, role names typed and case-sensitive, stale help text,
  an admin-powers toggle reported broken.
- Safehouses run on invisible rules: days survived, occupied, non-residential, spawn buildings, one per character,
  online-only invites, three conditions for respawn, real-hours expiry, protection off while the owner is online.
- Bans with no reason the player can see and no appeal path.
Sources are in the Nov 5 design session (pzfans admin panel and safehouse guides, the Steam discussions, the two mods'
Workshop pages, Supercraft's Log Extender page).

## Phase 1: reports and tickets
**The player: "Ask the admins" card** (Server tab), no pop-ups:
- Kind: Bug, Griefing, Stuck, Question, Appeal, Other (chips).
- "Include where I am" (ticked for Stuck and Griefing): the position, and the players within about 30 tiles.
- The message, in the card's own field.
- My tickets: each with its status (Sent, Seen, In progress, Answered, Closed) and the whole thread; a reply field
  while it is open. A note on the belt (Messages) when an admin answers.
**The admin: Tickets** (Admin tab), a queue of cards:
- Filters: status (Open by default; Answered and Closed are the history), kind, player, assigned to, text search.
  Newest or oldest first. A count of open tickets on the Admin tab's label.
- Each ticket: the kind as a colored label (and its word, never color alone), the player, the in-game day and the
  real date, the place with **Go there**, who was nearby, the thread.
- Answer in the card; several replies, not one; **Take it** (assign to me); internal admin notes the player never
  sees; **Close**. **Spam** (admins and moderators): the ticket leaves the queue for a Spam pile (its own filter, with
  a count); **Not spam** puts it back as Open; the player's own view just reads Closed. **Delete** for good: admins
  only, behind a footer confirm.
**Settled (the director, Nov 5 2026, on mockups/zed_tickets_v2.html):** the six kinds as above; "nearby" is 30 tiles;
Delete is for admins, moderators get Spam.
**Server part:** ZeD's ticket record in the server's global mod data (kind, times, place, nearby, status, assignee,
notes, thread), keyed to the game's own ticket, which ZeD still files (`addTicket`) so admins on the game's own window
see every ticket, the kind as a tag at the front of the message ("[GRIEF] ...").
**Without the server part:** the tag and place go in the message text; status is the game's answered / not.

## Phase 2: admin clarity, players and moderation
- **Every grayed control says why** in the help band: the capability it needs, and the role that has it.
- **Roles as picks, never typed:** a role list with each capability as a tick (the game's own role data); promote and
  demote from a player's card. Promotion shows the powers that just switched on (invisible, god, noclip), each with
  one-click off.
- **The player card** (Admin tab), one card for what the game spreads over ISUsersList, ISPlayerStatsUI and its seven
  pop-ups: account, role, warning points, stats, XP, profession, traits, inventory (manage), user log, suspicious
  activity; kick, ban, teleport to, bring here, spectate.
- **Bans with a reason and a length:** the reason the banned player sees, permanent or for hours or days (temp bans
  lift themselves: server part); the ban and unban lists (SteamID and IP, the game's own) in one card.
- **Admin powers** as ticks (built in beta 4), plus a plain "what each does".
- **Server messages:** one-off, and repeating announcements (server part).
- **Drawn Nov 5 2026:** `mockups/zed_admin_tools_v1.html`. The Admin tab: Tickets summary; one Players list (online
  and offline, role, last seen, warning points, a Find field); admin powers with a line on what each does; the server
  message typed in place with "Repeat every 15 / 30 / 60 / 120 min" and a Stop list; Roles, Bans, Spawn items; the
  game's remaining windows under More tools. The Player card: username, Steam name, role (a pick), where, warning
  points and kicks; Teleport, Teleport To You, Mute, Add Warning Points, Kick, Ban; Kick and Ban open in the card with
  a reason field (the player sees it), Ban with 1 hour / 1 day / 3 days / 1 week / Permanent and Ban IP too; a role
  change says what they'll be able to do and lists the powers the game switches on with it, off unless ticked;
  profession, traits, skills with Level Up / Level Down, Manage Inventory, User Logs, their tickets. Roles: each as
  ticks in five groups (players, tickets and chat, their own powers, world, server), name, description and color in
  place, Save in the foot, Delete role behind a foot confirm. Bans: ban someone offline by name, Steam ID or IP; each
  ban with reason, who, when, until; Unban behind a confirm; what the banned player sees. Spawn items: find, pick,
  how many (up to 100), to me / the ground / an online player; every spawn logged.

## Phase 3: safehouses and factions, all in cards (Server tab)
- **This server's rules in plain words:** claim after day N, residential only or not, trespass, loot, fire, respawn,
  expiry after N real hours away, protection while the owner is online; from the server's own options.
- **Claim checker:** standing in a building, "Can I claim this?" answers yes, or the exact reason no.
- **Safehouse card:** title, owner, members, pending invites, respawn here (with what it still needs), expiry countdown
  ("keep it by visiting within 3 days"), release and quit behind footer confirms.
- **Faction card:** create in the card (name, tag, color), members, invites, owner, faction PvP, disband / leave.
- **Wars** (the game's safehouse wars): their own card, accept, refuse, end, the countdowns.
- **Drawn Nov 5 2026:** `mockups/zed_safehouse_faction_v1.html`. The title, faction name and tag are the fields
  themselves (pick, type, Save in the foot; the pad keyboard under the field; the game's limits checked as you type:
  3-14 for a name, 1-4 for a tag, "already exists"). Invitations wait as a note in the Server tab with Decline and
  Accept, never a modal. Add Player is a drawer of who's online. Owner picks a member row for Change Owner or Remove.
  Release, Quit, Disband, Leave and Remove confirm in the card's foot, in the game's own words. No safehouse: "Can I
  claim this?" answers in the Server tab, with Claim Safehouse, and the new safehouse opens with its title ready to type.

## Phase 4: logs and accountability
- **ZeD's action log (server part):** claims and releases, faction changes, admin actions (kick, ban, teleport, powers,
  item spawns, role changes), PvP deaths, ticket events, and, opt-in, container takes inside safehouses. Each line: who,
  what, where, real time and in-game day. Written to the server's own logs too (writeLog), so outside tools see it.
- **The Log view** (Admin tab): filters by player, kind, place, time; **Go there**; from a ticket, "show the log around
  this place and time".
- **Reading others:** the game's PvP log in the same view; Log Extender's lines where the server part can read them
  (to check: the server's Lua file access may not reach Zomboid/Logs).

- **Drawn Nov 5 2026:** `mockups/zed_logs_v1.html`. The Log card in the Admin tab: kind chips (Admin, Safehouse,
  Faction, Vehicle, PvP, Ticket, Container when that opt-in is on), who, last hour / today / 3 days, Find; each line the
  real time and the in-game day, the kind as a word on a colored tag, who, what, where, and the source when it isn't
  ZeD's ("the game's PvP log"). Pick a line for Go there and the players' cards. From a ticket, "Around ticket #14":
  within 30 tiles, three hours before it was filed to half an hour after, with Add to ticket. Vehicle lines (window
  smashed, part removed, driven off, with the owner) are new to the log: they're what answer a griefing ticket.

## Phase 5: community
- **Server rules and a message of the day** on join, with "I agree" (the owner writes them in the Admin tab).
- **The ban and kick screen** shows the reason and the owner's appeal line (a Discord or a web address, as text).
- **From chat:** a name opens the player's card (admins) or Report / Mute (players). Mute is the player's own (client).
- **Announcements board** in the Server tab.

## Phase 6: opt-in systems (server settings, off by default)
- **Vehicle claims:** claim a vehicle; others can't take parts, drive or tow it (the settings say which).
- **Safehouse protection:** no dismantling or destroying inside a claim by non-members; claims cover the lot, not just
  the walls (from Server Tweaker's B42 list).
- **Staff map teleport:** click the map to go (roles that have teleport).
- **Economy:** a currency, shops, rewards for events: its own design session; last.
- **Drawn Nov 5 2026 (Phases 5 and 6):** `mockups/zed_community_v1.html`. Joining: the message of the day and the
  rules (a changed rule marked NEW), the appeal line, Leave and I agree. The Server tab: the message of the day, The
  rules, News (pinned first), this server's extras in plain words. Chat: pick a line for Report to the admins (the
  ticket opens with that player named and the chat around it), Mute (for you, nobody told); admins also get Player card
  and Teleport. Admin, Rules and news: the message of the day and each rule typed in place (move up, down, remove, add),
  the appeal line, "Ask everyone to agree when they join", "Ask again when the rules change", news posted with Pin.
  Admin, Server extras: Vehicle claims (others can't take parts / drive / tow; claims per player; lapse after N real
  days away), Safehouse protection (no dismantling, no destroying, claims cover the lot), Staff map teleport, Container
  log in safehouses (players told it's on), Economy grayed for later. All off by default; Save in the foot.

## The pop-ups: into the card, or a ZeD skin
Already ZeD's: every question, note and text box the game opens (ZeD_Prompt.lua; kick and ban reasons, server
messages, renames, confirmations).

**Names and short text go inline, never in a pop-up (the director, Nov 5 2026: "for things like factions, safe
houses, whatever needs a name, can that name be inline and not a pop-up?").** Anything typed in a card is a field in
that card: the faction's name and tag, the safehouse's title, a role's name, kick and ban reasons, warning-point
reasons, server messages, a ticket's message. The field sits where the value shows (the safehouse title is the field;
pick it and type), it saves with the card's own keycap (or on leaving the field where nothing else changes), and on a
controller the pad keyboard opens under it, as it does for text boxes now. ZeD's own Admin tab still opens a ZeD text
box for kick and ban reasons today (AdminTab.lua); those move into the player card with Phase 2. The ZeD text box
(ZeD_Prompt.lua) stays only as the fallback for a game or mod window ZeD hasn't rebuilt.

| The game's window | What it is | Plan |
|---|---|---|
| ISUserPanelUI | the player's server panel | replaced by the Server tab (beta 4) |
| ISCreateFactionUI | faction name | **into the card** (Phase 3) |
| ISFactionUI | faction: members, owner, tag, PvP, disband | **faction card** (Phase 3) |
| ISCreateFactionTagUI, ISColorPicker | tag, color | **fields in the faction card**; color as ZeD swatches |
| ISFactionAddPlayerUI, ISSafehouseAddPlayerUI | pick an online player | **a player picker in the card's drawer** |
| ISSafehouseUI | safehouse: members, title, respawn, release | **safehouse card** (Phase 3) |
| ISWarManagerUI | safehouse wars | **wars card** (Phase 3) |
| ISTicketsUI, ISAdminTicketsUI | tickets | **ticket cards** (Phase 1) |
| ISServerOptions, ISServerOptionsChange | server options | **read in a card** (all players); **edit in the card** (admins) |
| ISUsersList (+ banned IP / SteamID viewers) | accounts, bans | **player card and bans card** (Phase 2) |
| ISPlayerStatsUI (+ add XP, access level, profession, trait, inventory, user log, warning points) | a player's stats | **player card** (Phase 2) |
| ISRolesList, ISModalEditRole | roles | **roles card** (Phase 2) |
| ISMiniScoreboardUI, ISStatisticsUI | players, server stats | the Admin tab's players list; stats as a card |
| ISPVPLogToolUI | the PvP log | **the Log view** (Phase 4) |
| ISItemsListViewer | spawn items | **an item spawner card** (search, count, spawn to inventory or ground) (Phase 2) |
| ISServerSandboxOptionsUI | sandbox options, live | **ZeD skin** first (it is the game's whole sandbox screen; ZeD's Sandbox page list can follow) |
| ISAddSafeZoneUI, ISPvpZonePanel, ISAddNonPvpZoneUI | zones drawn on the map | **ZeD skin** first; a map-drawing card with Phase 6 |

**The ZeD skin:** for any game window ZeD has not rebuilt yet, a generic override gives it ZeD's chrome (the striped
title bar and close box, ZeD's colors, fonts and buttons) without touching what it does. Fallback for everything the
plan above has not reached, and for other mods' windows that open from ours.

## Ground rules
As in MP_DECISIONS.md: the Visual Catalog v2.0, System 7.1.2 chrome, the two Fira voices; cards at most 480; help in
the help band; full controller parity; no scrolling inside scrolling; the game's words (Server, Admin, Ticket ...);
every surface with its Simple version; American spelling, no middle dots. The server part's data is versioned, and a
server that drops ZeD keeps its world: ZeD's records sit in mod data the game ignores.

## Next
Design draws Phase 1 (the Ask the admins card, the Tickets queue and a ticket card) as a mockup for the director; Build
designs the server part's data and messages alongside; QA tests each phase on the local server, with two players for
tickets and invites.
