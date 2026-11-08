# Handoff: design, Nov 5 2026 (Cowork, the design session)

**For Build and QA. Start after beta 5 ships** (the director, Nov 5: beta 5 is being QA'd and assembled; nothing here
touches it). Every piece below is approved by the director and written up in full on the punch list; this sheet is
the order and the pointers. American spelling in everything players read (item 90).

## What's in it

| Item | What | Approved | The full write-up |
|---|---|---|---|
| 87 | Multiplayer and admin, all six phases, as mockups | Phase 1 decisions settled; Phase 2 "looks good, continue"; the rest "very, very good" | `MP_ADMIN_SCOPE.md` (each phase ends with a **Drawn Nov 5** paragraph) |
| 88 | The skeletons' elbows (both sexes, both arms) | "Both are expected to make full recoveries" | PUNCH_LIST 88 |
| 89 | The Identity tab: Immersive (the license) and Simple, wide and narrow | "No changes" | PUNCH_LIST 89 |
| 90 | American spelling: five UI.json lines and `license_block.bbcode` | | PUNCH_LIST 90 |

## The order

1. **Item 90 and item 88** first: small, art and text only.
   - 88: copy the 12 PNGs from `ZeDUI/art/skeleton_arms_88/` into `42/media/textures/ZeD/body/`; the arm rows of its
     `_layout.lua.txt` into ZeD_BodyFigure.lua's `M_HITS` / `F_HITS` / `M_HITMAP` / `F_HITMAP`. Don't rerun
     `d_skeleton.py`'s whole export into 42/ (it reproduces the committed art exactly today, but copy only these).
2. **Item 89, the Identity tab.** `mockups/zed_identity_v2.html` is the spec to match (switches: style, width, photo,
   weight, profession, accent, theme, scale). The art is in `ZeDUI/art/identity/`, drawn by
   `tools/identity/ky_header.py` (24 art pixels tall; draw at whole-number scale with the nearest loader). What the
   card reads from the game: the weight trend (Nutrition: isIncWeightLot / isIncWeight / isDecWeight), the game's
   start date (ISS; EXP four years on), a DL number made stable from the character's name, the carry-permit table by
   profession (Police Officer, Veteran, Security Guard, Park Ranger, Burger Flipper; Burglar REVOKED). The setting:
   ZeD setup, Look, Identity card: Immersive / Simple.
3. **Item 87, multiplayer and admin**, phase by phase. Build designs the server part first (official Lua: the data
   in global mod data, the client / server messages), starting with Phase 1, tickets. The mockups, one per phase:

   | Phase | Mockup | Settled |
   |---|---|---|
   | 1 Tickets | `mockups/zed_tickets_v2.html` | six kinds (Bug, Griefing, Stuck, Question, Appeal, Other); "nearby" is 30 tiles; Delete is admins only; moderators and admins mark Spam (a Spam pile, Not spam puts it back; the player sees Closed) |
   | 2 Admin tools | `mockups/zed_admin_tools_v1.html` | the Players list, the Player card (kick and ban with a reason in the card, ban lengths, a role change lists the powers the game switches on, off unless ticked), Roles as ticks, Bans, Spawn items, server messages with Repeat |
   | 3 Safehouses, factions | `mockups/zed_safehouse_faction_v1.html` | every name inline, never a pop-up (rule in MP_ADMIN_SCOPE.md, the pop-ups section); invitations wait in the Server tab |
   | 4 Logs | `mockups/zed_logs_v1.html` | the Log card; "around this ticket" (30 tiles, 3 hours before to half an hour after); vehicle lines (window smashed, part removed, driven off) |
   | 5 Community | `mockups/zed_community_v1.html` | rules and the message of the day on joining, with I agree; News; chat names: Report to the admins, Mute (yours alone) |
   | 6 Extras | `mockups/zed_community_v1.html`, Server extras | all off by default: vehicle claims, safehouse protection, staff map teleport, container log in safehouses; economy later |

   **Questions for Build to answer before Phase 4:** can the server part's Lua read `Zomboid/Logs` (for Log
   Extender's lines)? Which events give us a vehicle's window smashed, a part removed and a vehicle driven off by
   someone who isn't its last driver, without a performance cost?

## Uncommitted design files (Build commits them with the first of this work)

`ZeDUI/HANDOFF_design_20261105.md` (this), `PUNCH_LIST.md` (items 87 to 90), `MP_ADMIN_SCOPE.md`,
`MP_DECISIONS.md`, `VEHICLE_TAB_SPEC.md` (spelling only), `mockups/zed_tickets_v1.html`, `_v2`,
`zed_safehouse_faction_v1.html`, `zed_admin_tools_v1.html`, `zed_logs_v1.html`, `zed_community_v1.html`,
`zed_identity_v1.html`, `_v2`, `art/skeleton_arms_88/`, `art/identity/`, `tools/identity/ky_header.py`,
`tools/physpx/d_skeleton.py` (the straight forearm). Not design's: `tools/qa/i18n_allowlist.txt` and the untracked
`qa/` captures are QA's.

## QA, once each lands

- **88:** the Health, Thermal and Equipment tabs, both sexes: the arms straight at the elbow, tinted parts on the
  right bones, clicks on the forearms land on the wrist parts.
- **89:** both styles at both widths; 1x, 2x and 1.75x at 4K; the nine accents and three themes (pale accents
  readable on the cream card); the photo to full body and back on each; a long name; the weight steady, gaining,
  gaining fast and losing; each permit profession and one without.
- **90:** the five lines read American in game (the Mods screen's load-order picker and label help, the survival
  guide's Look chapter and beta 3 What's new).
- **87:** each phase on the local server with two players (tickets, invites, bans, the log around a ticket).
