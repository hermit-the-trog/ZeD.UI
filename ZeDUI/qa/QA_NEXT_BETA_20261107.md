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

Not yet in game:

- **Claims with two players:** the second Accept, release then claim, an invitation during a join, the offline role box. Build's claim sims cover them; the two-player run is still due.
- **German on a dedicated server:** the Bans hint, the Player card names, 24-hour times.
- **The Admin and Server tab clips:** these need a server.

## Merge 2, the dashes and the house ad fit (44df3931)

Running when this was written: see the end of the night's report.
