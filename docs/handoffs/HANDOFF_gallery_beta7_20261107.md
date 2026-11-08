# Handoff: the gallery for beta 7, today's changes and the retakes (Nov 7 2026)

From design, for QA and the director. The director, Nov 7, before the 1pm beta 7 upload: "do we need to update the
Bitchin guide with multiplayer stuff? Anything out of date there we should update before we upload the next beta at
1pm PST", then "Yes. Yes, please." to fixing 52 now and writing up the retakes for after the upload. At 11:25: "Why alt
tab to a wiki when you could F1 to live rules and data? That needs to be on the 46 survival guide." Punch list item 105.

## In the upload set now (design, Nov 7; not committed)

**52 Playing on a Server** (`spreads/52_multiplayer.json`, `upload/52_multiplayer.jpg`, same captures):

- Two arrows had missed since `mps_01` was retaken (Nov 6, 4:08 PM). "Ask the admins opens a ticket." now lands on
  *Ask the admins* (it read "Faction, safehouse and tickets: Ask the admins." and pointed at *Players online*).
  "PvP is off. The button turns it on." now lands on *Turn PvP on* (it pointed at *Tickets*).
- The paragraph lists the *Server* tab in the order `ServerTab.lua` builds it: the server's name, the players online
  and your role, then the server's extras, your tickets, your faction, your safehouse and the server's rules for
  safehouses, PvP and the player list.
- Both figure captions now clear the prints (they had sat under them since Nov 5). Left: `mps_02` at y 572, the belt at
  862, cropped to 2138 (only black below the belt), its lower-left tape moved to the left side. Right: `mps_11` at 432,
  cropped to 616 (drops the half-cut *Climate control* row), the sticky at 668, the two chat prints at 732.

**46 The Survival Guide** (`spreads/46_survival_guide.json`, `upload/46_survival_guide.jpg`), on top of QA's 11:26
commit (349bdf17, the new contents capture `gb_2_contents_p1p2.png`):

- The right page's sticky is the director's line, written "Why Alt-Tab to a wiki when you could F1 to live rules and
  data?" It replaces "The rules come from the game itself.", which said the same thing. Three lines, so the sticky
  moved up to y 880 (h 150), and the Full-and-Simple note above it to y 790. Keep this sticky when 46 is rebuilt.
- Figure 46-2's caption sat under the lower-left tape of the *Simple* rules print; that tape moved to the print's
  left side.

Both render with no CHECK lines; both JPEGs are under 1 MB (616,224 and 644,333 bytes). Nothing else in the upload
set changes. The gallery images go up apart from the mod's files, so everything below can follow the upload.

## Still out of date

| Spread | Since | What | Needs |
|---|---|---|---|
| 36 Dashboards | beta 7 | the taxi's key has no ACC; the odometer is outside the crop; Table 36-1 and the red note say "OFF, ON and START" | retake 1, then the text |
| 61 Full or Simple | beta 7 | the Simple dash has no *Trip* cell and no ACC | retake 2 |
| 05 Driving In, 14 Night Shift | beta 7 | the station wagon's key has no ACC mark (05's "The key turns from *OFF* to *ON* and *START*." is still true) | optional, retake 3 |
| 46 The Survival Guide | beta 7 | no ads anywhere in the gallery | captures 4 |
| 52 (and new spreads) | beta 6 | tickets, the Player card, the safehouse, faction and war cards, the Log, the join rules, chat report and mute are not shown | captures 5 |

Current: 02 (Identity, retaken Nov 6), 13 (its kill rows add up to the heading, as beta 7 now makes them do for old
saves), 21 (item cards), 42 and 43 (controller), 62 to 66.

## For QA: the retakes

As before: 4K fullscreen (3840 x 2160), ZeD scale 1.75x, the same look as the captures they replace, saved under new
names in `Screenshots/gallery_t14` (the spreads print the old files until design swaps them). Only QA accounts in
frame: no Steam names or IDs, no folder paths, no e-mail (the Nov 1 privacy check). Keep the debug text at the lower
right out of the part that matters, or turn it off. Design re-reads every crop and point with `peek.py`.

1. **36, the taxi** (today: `zqa_r6p_taxi_extras.png`, Oct 28; print box 1880,1775 to 2700,2150):
   - `zqa_b7_taxi_acc.png`: engine off, the key in at *ACC*, the meter showing a fare and *EXTRAS*, the ash tray open,
     the hula girl in frame.
   - `zqa_b7_taxi_run.png`: engine running (key at *ON*) after a short drive, so the odometer and the trip read real
     figures (trip not zero), and the trip's reset in frame.
   - The odometer sits in the speedometer, left of today's crop (about x 1580 to 1630, y 1980 in the old capture), so
     design widens the crop or adds a small print of the speedometer. Then the text, drafted from item 102: Key row,
     "Insert it, start the engine and stop it. The key sits at *ACC* while the engine is off and at *ON* while it runs,
     and turns to *START* while the engine cranks."; the odometer and trip worded from what the capture shows.
2. **61, the Simple dash** (today: `gb_plain_dash.png`, Nov 6; box 1214,1636 to 2626,2118): engine off with the key
   at *ACC*, the *Trip* cell showing a figure. `gb_b7_plain_dash.png`.
3. **05 and 14, optional:** the station wagon at the old rects. `story_04a_dash_low_fuel.png`: fuel on *E*, engine
   off, key at *ACC*. `story_12b_dash_night.png`: night, driving, the *HI* lamp lit. 05's key sentence gets ACC with it.
4. **46, the ads:** the Full look, Small text, keyboard, English, the book window as in `gb_1` to `gb_3`.
   - Already taken (QA, Nov 7): `gb_2_contents_p1p2.png` (in the spread now) and `gb_2b_house_intro.png`.
   - Wanted, `gb_b7_ads_1.png` and `_2.png`: a whole page with a full ad other than the house ad (Ready Prep,
     Greene's or Crossroads Mall), and a flow page with a half and a third, or a pair of quarters. QA's deal log for
     small_kb is in `qa/regression/2026-11-07_b7f_book.md`; its `zqa_gad_*` captures are gone from `Screenshots`,
     but if a copy was kept, it may do.
   - After item 103 (the copyright page) is built: the first spread again, copyright left and title right.
   - Design then reworks 46 around the ads and the two-page contents, and asks the director whether the ads get a
     spread of their own.
5. **The multiplayer spreads:** on the local QA server, the admin (`zedqa`) and a second QA account on a second
   client, window captures at 4K, named on from `mps_20` (`mps_01` to `mps_14` exist). Optional ones are marked.
   - Tickets: `mps_20_ask_admins_card` (filled in: a kind picked, the place, a line typed, before *Send*);
     `mps_21_ticket_thread` (the player's ticket with a staff reply); `mps_22_ticket_queue` (staff, two or three
     tickets, one taken); `mps_23_ticket_staff_card` (the thread, a staff note, *Take it*, *Spam*, *Close*).
   - Players: `mps_24_players_list` (both accounts, one offline, as a role with See every account);
     `mps_25_player_card` (the second account: kick, ban, warning points, role, skills, and a grayed control's reason
     in the help line); optional `mps_26_roles_bans` (*Roles* as ticks, *Bans* with a timed ban and its reason).
   - Joining: `mps_27_join_rules` (the rules and the message of the day, with *I agree*, on the second client);
     optional `mps_28_ban_screen` (the banned account's screen with the reason and the appeal line).
   - Safehouses and factions: `mps_29_can_i_claim` (the game's answer, on a server that allows claims);
     `mps_30_safehouse_card`; `mps_31_faction_card`; `mps_32_invitation_note` (waiting in the *Server* tab with
     *Decline* and *Accept*, on the second client); optional `mps_33_wars_card`.
   - The Log: `mps_34_log_card` (mixed lines: admin, safehouse, faction, PvP, ticket; *Go there* showing; a claim
     released and claimed again as two lines, from beta 7); optional `mps_35_log_around_ticket`.
   - Chat: `mps_36_chat_report_mute` (a picked line with its report and mute buttons).
   - Optional: `mps_37_extras_card` (one server extra on, its card saying what it can't stop).
   - Design proposes three spreads from these (Tickets; Players and the Log; Safehouses and Factions), next to 52.
     Where they go in the order (after 52, renumbering 53 onward, or at the end before 69) is the director's call.

## Files

- Changed today: `workshop/gallery/spreads/52_multiplayer.json` and `46_survival_guide.json`, their JPEGs in
  `upload/` and PNGs in `out_spread/`.
- Before-versions and the edit scripts: `Zomboid/ZeD_design_refs/ads/_stage/gallery/` (`52_multiplayer.before.json`,
  `46_survival_guide.before.json`, `fix52.py`, `fix52b.py`, `fix46.py`).
- House style and the renderer: `workshop/gallery/SPREADS.md`, `spread.py`; the captures: `Screenshots/gallery_t14`.
