# Outside review of 0.3.0-beta6: QA's check against our code (Nov 6 2026)

A code review and in-game QA of beta 6 by Claude on the director's Mac, under a different Claude account, run on 42.21 with no Steam. "The tester" below is that session; there's no one to credit. QA checked it against main at e3da245f and the 42.22.2 jar, reading code only: no game run.
Paths are under 42/media/lua. **Seen** = QA saw it in our code, jar or logs. **Reported** = line matches, but it rests on the tester's review.

## High
| # | Finding | Where | Our check | Fix |
|---|---|---|---|---|
| 1 | A dedicated server retries the font check for as long as it runs, and every try throws | shared/ZeD/Scale.lua:839-851, :416, :469 | **Seen in our own log**: zedqa_mp/Logs/2026-11-06_16-36_DebugLog-server.txt, about 3 exceptions a second once the server is up, still going when the log ends, 644 KB in 3 minutes (13 MB an hour). QA ran that log for beta 6 and did not read it for this. | Skip font work on a server: the OnTick, checkRoleFonts and the font part of applyTheme |
| 2 | Safehouse invitation notes vanish in 6 to 36 seconds; offline invitations never show | client/ZeD/ZeD_Claims.lua:309, :317, :332; server/ZeD/ZeD_ServerClaims.lua:89 | **Seen in the jar**: the id is made in the constructor from a timestamp, and SafeHouse.load calls the constructor without restoring it, so it differs by machine and by server restart | Key by getOnlineID() (from x,y). Also check ZeD_ServerClaims.lua:184, which keys the same way |

## Medium
| # | Finding | Where | Our check | Fix |
|---|---|---|---|---|
| 3 | Every armed hit on a zombie raises a Lua error; kills by weapon stay empty | client/ZeD/KillTracker.lua:56 | **Seen**: getCategories is gone from the 42.22.2 jar too, and the call is unguarded | isOfWeaponCategory / getSubCategory |
| 4 | "Others can't tow" fails on 42.21 | server/ZeD/ZeD_ServerExtras.lua:354 | **Differs**: 42.22.2 has the 3-argument call, so it works for us and fails for anyone on 42.21. Our regression can't see this. | a:breakConstraint(true, false): on 42.22.2 it passes straight to the 3-argument call with no player |
| 5 | Oversized ticket requests cost the server time before refusal; a refused one starts no limit | server/ZeD/ZeD_ServerTickets.lua:452 | **Seen**: text is cleaned before kind or length are checked. Needs a modified client. | Check type and raw length first; count refusals toward the limit |
| 6 | A muted player can still talk with /all, /s, /y, /w | client/ZeD/ZeD_Chat.lua:473 | **Seen**: the check waves through anything starting with / | Parse the stream first, apply the mute to chat streams |
| 7 | In safe mode, invitations can't be answered | client/ZeD/ZeD_Claims.lua:674-690 | **Seen**: the game's pop-ups are removed with no ZeD.Safe check, and guarded() calls the game's only on an error | In safe mode leave the game's handlers in place |
| 8 | "Check stats" on a Player card stacks copies of the card | client/ZeD/ZeD_AdminCards.lua:1201, ZeD_TicketCards.lua:1665 | **Seen** in the code path; not run | Open ISPlayerStatsUI directly from here |
| 9 | A ticket opened from a Player card wipes the first ticket card | client/ZeD/ZeD_TicketCards.lua:1580 | Reported, seen in the tester's game. C.card holds one card. | Keep the card per id, or refetch on Back |
| 10 | Pad, Hold + flick-release: a slice fires without being chosen | client/ZeD/ZeD_WheelGesture.lua:131 | **Seen** as designed: needCenter is off for Hold. Needs a real pad. | Keep needCenter for Hold + flick |
| 11 | Pad, Original preset: pulling RT to run closes a tap or toggle wheel | client/ZeD/ZeD_WheelGesture.lua:183, :545 | **Settled, no change**: the director, Nov 6: "if that's what they have run map to, it's fine." | None |
| 12 | Clothing cards show 0% bite, scratch and bullet protection | client/ZeD/ItemFactsPanel.lua:74-81 | **Seen, and wider**: the script item has only getInsulation. Neck, water and condition are lost the same way. Wind is getWindresistance on the instance, a name no probe here uses. | Read from the clothing item |
| 13 | Animals tab, Ranch page: no tab icons and no footer | client/ZeD/ZeD_WorldWindow.lua:4152, AnimalsTab.lua:1411, :1473-1474 | **Seen in game, 4K and Deck**, and worse than reported: the Ranch page, where the Animals tab opens, draws with no tab icons on the right and no footer line. Its draw ends with one clip more than it starts (count 1); Zone and Butcher end at 0 and draw both. In since f59ffdc8, Nov 5: beta 5 and beta 6 both have it. Picture: qa/animals_ranch_rail_deck_20261106.jpg. The script that sets an item card over the page proves nothing, as the card does not draw that way. | Run the cleanup at ZeD_WorldWindow.lua:4152 for every tab, or end the Ranch page level; Build's call |

## Low
**Seen in the 42.22.2 jar** (all fail silently):
- CraftingTab.lua:104, BuildingTab.lua:141: isNeedSurface; use isAnySurfaceCraft.
- JournalTab.lua:278: getDescription; use getTooltip.
- ItemFactsPanel.lua:295-297: getNumberOfPagesToRead, getNumberOfMappedRecipes and isAlreadyReadByPlayer are gone; getAlreadyReadPages exists.
- ContextMenuRegistry.lua:934: getConditionPercent is gone.
- ItemCard.lua:74: getKnockbackPower is gone.
- ContextMenuRegistry.lua:902, ItemCard.lua:119: getTranslatedFluidName; Fluid has getTranslatedName.
- ZeD_DpadWheels.lua:1407: IsoGridSquare:Is is gone; use has.
- AnimalsAlertPoller.lua:201: getWidth/getHeight; zones have getW/getH, so the roof percentage never runs.

**Seen in code:**
- Settings.lua:715: identityStyle was added to the Vanilla Access preset with no migration, so beta 5 players on it land on Custom with the Immersive card.

**Reported, lines match, not checked by QA:**
- Chat, Character window and logs: ZeD_Chat.lua:763, ZeD_CharacterWindow.lua:503, ZeD_LogCards.lua:135.
- Claims: ZeD_Claims.lua:131, :506, :404 (plausible).
- Extras: ZeD_Extras.lua:160.
- Admin: AdminTab.lua:391, ZeD_AdminCards.lua:1387.
- Context menus: ContextMenuRegistry.lua:583, :592 (plausible), ZeD_ContextList.lua:257.
- Tickets and notes, all plausible: ZeD_Tickets.lua:707, ZeD_TicketCards.lua:1019, :1609, ZeD_Messages.lua:262, ZeD_MessagesWindow.lua:486.
- Split-screen, plausible: ZeD_ServerLink.lua:38, ZeD_Claims.lua:195.
- Server: ZeD_ServerAdmin.lua:723, :750, ZeD_ServerTickets.lua:991, ZeD_ServerCommunity.lua:311.

## beta 5 items still open, as reported
ZeD_Restock.lua:871 (isJoypadPressed), non-atomic writes in ZeD_ModOrder.lua:141 and ZeD_QuickChords.lua:96, Death then Restart using the game's screens, no poster.png or icon.png, plus the rest of the tester's beta 5 list. Their Survival Guide and animal rain fixes are confirmed; the forced Lua reload on the Mods screen is refuted.

## What the tester covered that we have not
A real ticket round trip with two accounts through ZeD's windows on a server, and forged commands against the server part (no authorization or validation hole found). No second player online at once, no pad, no right-click menus and no Steam on their rig, so those findings rest on code review.
