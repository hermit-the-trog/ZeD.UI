# Check: the stats, inventory and staff claim cards (C6, C7, C8), Nov 7 2026

What changed: the game's Player Stats window, its Manage Inventory and its safehouse and faction windows for staff are now ZeD cards in the Admin tab (`ZeD_StatsCards.lua`, `ZeD_ClaimCards.lua` kinds `osafe` and `ofac`). The sims pass; nothing below has been seen in the game yet.

## Setup

- Local server kit: `pwsh -File ZeDUI/tools/qa/mp_server.ps1 -Start -Mods "ZeD_UI;ZeDQAShim"`, two real players (`batch_two_b7`): A is admin, B is a plain user. Zombies off. Stand A and B within loading range of each other.
- B claims a safehouse and makes a faction (with a second member if the tag needs one).
- Run each section with the mouse, then again with a controller. Run at 4K (1.75x) and at Deck 1280x800 Auto, Normal and Large text.
- Picture states with no server: `zedqa_run -Mp -Manifest mp_admin_cards.txt` now also walks `stats-*` and `inv-*`.

## C6: stats card

1. A: Admin tab > Players > B > Check stats. The stats card opens over the Player card; Back returns to it.
2. Each Change (display name, forename, surname, weight, profession, role) opens in the card; the foot has Cancel and Save or Change. Save is gray with a reason for an empty or same name, a weight outside 30 to 130, nothing picked.
3. Save a forename. B's name changes for both players within a few seconds.
4. Profession and role: pick a row, the foot asks, Change. Check B's role on the Player card and in the Players list.
5. Traits: Add trait, Good and Bad chips, Find, pick, Add. Remove a trait: the foot asks first. B's traits change for B too.
6. Skills: + and - on a skill; Add XP with and without multipliers. Compare B's own skill page.
7. Warning points: Add, a reason, the count goes up. User logs: Add log, Remove a log behind the ask.
8. Gates: give A a role without CanModifyPlayerStatsInThePlayerStatsUI: every Change is gray and says the capability. Put B in a role above A's: gray with the rank reason. B far away (out of loading range): the card says to go closer; logs stay.
9. More tools > Check your stats: your own card. A ticket's Player card without the server part and a chat line's Player card open this card.

## C7: inventory card

1. From the Player card's Inventory row or the stats card's: B's things arrive, weapons first, containers' things marked.
2. Pick a thing: Take and Remove light. Remove asks in the foot; after it B no longer has it. Take a stack and a single thing; they land in A's inventory.
3. Add item opens Spawn items aimed at B; Back returns to the inventory.
4. Your own inventory: Take and Add are gray with the reason. B logged off: the card says so and gray.

## C8: someone else's claim

1. A: Admin tab > Safehouses > B's > Open. Its card here, B as owner. No respawn tick for A.
2. Rename it (foot Save), Add Player (B's online friend; A is not in the list), change owner, remove a member (both behind the foot's ask), Release. Watch for a kick: there must be none.
3. Factions > B's > Open: rename, tag, Disband. No Show tag or PvP ticks for A.
4. Your own safehouse and faction from those lists still open in the Server tab.
5. A role without CanSetupSafehouses or FactionCheat does not see the lists.

## Not covered by the sims

The game's own answers (does setRole through `sendPlayerStatsChange` stick on the server; does `InvMngGetItem` move or copy), the anti-cheat on staff safehouse packets, real fonts, focus landing and the keyboard.
