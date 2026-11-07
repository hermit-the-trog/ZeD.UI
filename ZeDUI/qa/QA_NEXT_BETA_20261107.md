# QA: the next beta's merges, Nov 7 2026 (overnight)

QA ZeD-GUI, on the QA save, ZEDQA_NOSTEAM=1. The reports are in `qa/regression/2026-11-07_*.md`; the pictures stay out of the repo, in QA's scratchpad.

## Merge 98, the survival guide ads (9f0c211b)

See `QA_GUIDE_ADS_20261107.md`.

- Placement passes on four readings at 4K 1.75x, at 1080p and in German.
- The house ad's line under the headline ran out of the frame. It is fixed in 44df3931, and checked below.

## Merge 1, the fixes (a60a0399)

| Item | Result | How |
|---|---|---|
| Kills: each weapon its own row | PASS | `zedqa_kills_kind.lua`: bat Blunt, axe Axe, knife SmallBlade, pistol Firearm, hammer SmallBlunt, bare hands Unarmed, each +1 |
| Only real explosives under Explosion | PASS | pipe bomb +1, aerosol bomb +1; Molotov went to Other, no explosion |
| No fire rows from reused zombies | PASS | 9 kills made 2 s apart, fire +0 (beta 6a: 3 fire rows) |
| Header = game count + fire | PASS | 341 = 327 + 14 |
| One-time save fix | PASS in part | It had already run when the save loaded: version 2, Explosion 3 → 0, header 332 = 318 + 14. The old Other count wasn't read beforehand, so the amount moved isn't proven. |
| Firearm facts, six guns | PASS | no error; "Ammo Type = 9x19mm Round" |
| Lock cards in the half card | PASS | locker (code), crate (key padlock), free crate: 385 px at 4K, 443 at 4K Large, 190 at Deck Large = 220 units; no clips left; pictures read at Deck Large |
| Book card Progress | PASS | the top row reads 110 / 220, as Reading Facts does |
| Tabs with a card open, then closed | PASS | Equip, Health, Skills, Identity, Journal (all five pages), Radio, Ranch: no clips left, 56 of 56 at 4K, 4K Large and Deck Large; Recipes keeps its list (no recipe was picked first) |
| Z menu version | PASS | 0.3.0-beta6a from the dev copy's mod.info |
| Mods screen: ZeD-GUI off and on with picks | PASS | with the shipped ZeD picks mod.info (require=\ZeD_UI) swapped in for the run; the installed copy is older and has no require line |
| Undo changes and Load after with a not-installed mod named | PASS | `QA_NotInstalled_Mod` in the load order; no error |
| Dates in 27 languages | PASS | placeholders kept; "5. Nov" (DE), "11月5日" (JP, CH, CN), "11월 5일" (KO). FR and HU keep a capital "Nov" (left for the native-speaker pass) |
| Spawn items lines, claims wait line | PASS | all 28 languages, translated, placeholders kept |
| Sims | PASS | all 19 on main, then Build's 20 |

### With two players on the local server (`batch_two_b7.ps1`, log `qa/two_players_b7.txt`; the admin's game in German, at the Deck's size)

| Item | Result | How |
|---|---|---|
| A release then another player's claim of the same building | PASS | The admin stepped out and released. Bob, inside, claimed 92 ms later. The server's ZeD log reads `release / zedqa` then `claim / bob`, two lines at 05:08:40.697. |
| A second Accept while the first is on its way | PASS | It came back "wait" with the message in German ("Deine Antwort ist unterwegs. Warte einen Moment."). The first Accept joined the admin to bob's house (`member in`). No kick. |
| The Admin and ticket cards' clips | PASS | 20,814 frames at Normal text and 11,690 at Large: none ended with a clip left, in either window |
| German: Spawn items | PASS | "5 x Axe an dich"; an empty search reads "Keine passenden Items." |
| German: the Bans hint at Deck size with Large text | PASS | "ein Benutzername, eine Steam-ID oder eine IP" sits under "Jemanden offline bannen" |
| German: ticket dates and times | PASS | "Tag 12, 5. Nov, 21:14 UTC" (the game's 24-hour option on) |
| German: Player card names | PASS by its parts | The test cards' players carry no ids, so they show the server's English, as designed. A German client turns the server's ids into German names (`zedqa_de_names.lua`): base:farmer = Bauer, base:strong = Stark. |

Two notes from the claims runs:

- The game won't let anyone claim a building with another player inside it ("Occupied building").
- So a release then a claim by the other player needs the first player to step out.

Not checked in game:

- **Claims:** an invitation that arrives during a join in safe mode, and the offline Player card's grayed role box with the server's refusal. Build's sims cover both.
- **The Character window's Server tab:** checked only through the clip counts above, with no pictures.

## Merge 2, the dashes and the house ad fit (44df3931)

| Item | Result | How |
|---|---|---|
| The odometer counts the distance driven | PASS | `zedqa_dash_odo.lua` on the drag strip. Nyala (drum dash): 150.9 squares = 0.0938 mi, odometer +0.0946 (101%). Dash Elite: 19.3 squares, +0.0120 (100%). The trip counts with it. |
| The stem zeroes the trip (drum dash) | PASS | |
| Dash Elite: A switches ODO / TRIP, the second verb zeroes the trip only while TRIP shows | PASS | |
| A starting mileage stable for a car, higher for a wreck | PASS | 72046.2 twice; a wreck 126046.2 |
| Quit and relaunch: the odometer, the trip and ODO / TRIP kept | PASS | `zedqa_dash_odo_reload.lua`, 5 of 5; the dash reads them on sitting down |
| The Simple dash in mi and km | PASS | Odometer 22180 mi, Trip 0.0 mi; 35695 km, 0.0 km |
| The bulb check on all 19 designs | PASS | `zedqa_dash_keys_edge.lua` pictures: every lamp lit at START and dark running. The race car's OIL and WATER jewels dim when it runs. The Dart has its temperature gauge. |
| Night, the Dash Elite's LCD | PASS in part | With the panel lights off, whole unlit 8s; with them on, the green backlight. The "lights on, key out" case wasn't shot; it waits on the director's look at the key. |
| The house ad's line inside its frame | PASS | EN at Large, DE and FR at Small and Large: the line wraps, and the price box has room. EN at Small now wraps into two even lines (Build: fine). Thai can't be judged in the book, whose fonts have no Thai; that's why F1 sends Thai to the window. |

Two notes from the dash runs:

- The lamps are lit whenever a key is in, even with the key drawn at OFF. That's by design: a key in the lock feeds the electrics. Build's punch list 102 puts the key's look to the director.
- Both test cars started at 22180.0 because the second car took the first one's vehicle id. That's an artifact of the test, not a fault.

Not checked in game:

- **The dash with two or three players:** the passenger's figures, a third player getting nothing per tenth, and another mod's key on the car surviving a drive. Build's dash_odo_sim covers the traffic.
- **The pad route to the stem and the window:** only the mouse path was pressed.

## The three two-player cases, run on the director's word (Nov 7, morning)

`batch_two_b7_rest.ps1` on the local test server, the admin and bob at 1280x800. Logs: `qa/two_players_b7_rest_run1.txt` (all three), `_run2.txt` and `two_players_b7_rest.txt` (the role box again). The server's database, its ini and both clients' ZeD settings were put back after each run.

| Item | Result | How |
|---|---|---|
| A safehouse invitation arriving while bob's yes is on its way, safe mode switched on in that moment | PASS, 9 of 9 | `mp_b7_safe_join.lua`. Bob pressed Accept in ZeD's note; in the same frame Safe mode went on and two more invitations came through the game's own event, one taken by ZeD's note and one whose note failed (made to throw). Bob had no house yet, so before the fix the game's pop-up would have shown. Both waited, the yes landed in 39 ms, no game pop-up showed at any moment, no note was left, and bob was still on the server and a member 25 s later. |
| The dash: a player outside the car gets nothing | PASS | `mp_b7_dash_bob.lua` watch: bob 5 squares from the car as the admin drove off, 0 figures to him and 0 sends from him; no dash on his screen. |
| The dash: a passenger sitting down | PASS | His dash asked once, the server answered, and his copy and his dash read the server's figures (55993.1608). He sent no figures. |
| The dash: a passenger on the drive | PASS | Two sends reached him, one at each figure the server took. After the engine stopped, his copy was the server's, 55993.1749. |
| Another mod's key kept on the server's copy of the car | PASS | The shim wrote `QA_otherMod` into the server's copy only. It was there after both drives and the engine-off send, and on bob's copy after that send. |
| The driver's odometer, two players | PASS | Up the strip, 98.1 squares = 0.0610 mi; the odometer counted 0.0610 (100%). Back in reverse, 0.0141 against 0.0139 (99%); the check called it short only because that drive ran under its 0.02 mi floor. |
| The server's figure once the car stopped | as designed | After the reverse drive the server held 0.0034 mi less than the dash until the engine went off. That's the dash's rule: a stop sends only once 0.01 mi has gone by since the last send. The engine-off send brought the server level with the dash. |
| The offline Player card, a role that changes roles but cannot see every account | PASS, 16 of 16 | `mp_b7_role_setup.lua` made qa_nosee the game's way: the moderator's powers without SeeNetworkUsers. None of the game's own roles has the one power without the other. `/adduser` made carl, an account never on. `mp_b7_closed_card.lua`: for carl and for nobody_qa (no account), the server kept the card closed. The role box, Status, profession and skills each name the power, never "user" or "never seen". The role box is grayed with that reason, a press opens no pick, and a role change sent past the card is refused "perm" for both names alike. The admin, who has the power, gets carl's card open. |
| The role box's look on a closed card | FAULT, small | At 1280x800, Normal text, the grayed role box with the power's sentence runs past the card's right edge, under the scroll bar, and its text is cut at "capability." See `two_b7_rest_20261107/closed_card_carl.png`. |

Notes from the runs:

- The first two role runs failed for test reasons, not faults. In run 1 the second card wasn't asked for; in run 2 the World window rolled itself up because no mouse was over it (the hover close). The third run held the window down and passed.
- Bob's new character opens the survival guide on startup, over everything, so the scripts close it first.
- The server's world keeps a car and its passenger across a restart. Bob sat down again in the third run, and his passenger dash read 55993 at once (`passenger_dash_after_restart.png`).
- On a closed card, Ban stays live for a role with the ban power (qa_nosee has the moderator's). That follows the server's rule, which shows a ban only to a role that reads the bans. It is not a QA call.
