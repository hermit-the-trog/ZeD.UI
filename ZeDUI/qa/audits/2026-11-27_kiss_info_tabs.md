# KISS test: the info tabs (QA, Nov 27 2026)

The director, Nov 23 2026: "With every one of these micro QA passes, also do a KISS test." This covers the info tabs sweep (Skills and Info, Journal, Radio, Maps), Hermit's go on Nov 27 ("1").

Maps (in ZeDUI/qa/audits):
- 2026-11-27_map_skills_info.md (S1-S35, I1-I32)
- 2026-11-27_map_journal.md (J1-J52)
- 2026-11-27_map_radio.md (R1-R56)
- 2026-11-27_map_maps.md (MP1-MP66)

Scripts (each manifest at 4K and 1280x800): sk_tab (sk.txt), jn_tab (jn.txt), rd_tab (rd.txt), mz_tab (mz.txt).

## Where it stands (Nov 27 2026: every tab fails only its design calls)

| Sweep | 4K | 1280x800 | What still fails |
| --- | --- | --- | --- |
| Skills and Info | 353 pass, 1 fail | 353 pass, 1 fail | S3 (call 1) |
| Journal | 336 pass, 2 fail | 336 pass, 2 fail | J1, J32 (calls 5 and 6) |
| Radio | 322 pass, 2 fail | 322 pass, 2 fail | R6, R51 (call 4) |
| Maps | 343 pass, 1 fail | 340 pass, 1 fail | MP33 (call 7) |

The skips are multiplayer cases, split screen, other languages and staging the game can't do in single player.

## Bugs found and fixed

Built in fix/skillsinfo, fix/radio, fix/journal, fix/infotabs2 (Journal, Survived for, Maps), fix/rtvbattery, fix/journal2, fix/survived2, fix/jn41, fix/twoway and fix/radio6.

Skills and Info:
- Skill pins are kept by the perk's id, so a language change no longer loses them.
- A book counts as known by level, as the game's Literature list does (level + 1).
- The sandbox's MetaKnowledge hides unknown books, as in the game.
- Book titles lose their own volume head, and the volumes follow the book's level.
- A right-click on the pinned heading no longer reaches the row scrolled under it.
- The weight is rounded, as the game rounds it.
- Professions use the game's own names ("DIY Expert").
- Grey hair reads "Gray".
- The No traits line is counted in the scroll.
- The wheel over the photo scrolls the tab, and the full-body zoom has bounds.
- Survived for shows only when the worn watch shows the date, as the game does.
- The Info tab refreshes on the clock (500 ms), not every 30 frames.

Radio:
- Walkies and ham sets have a battery control and take headphones.
- A TV takes no headphones.
- A CD player shows no channel, heard or frequency rows.
- A walkie's pop-out stays open while the walkie is in a bag.
- The pad lands on VOL on a two-way set.
- The Character window's empty line reads "No radio on you".
- Lite has Add, Edit and Remove preset.
- A battery pressed on the radio's tab goes into the radio, not a TV on its square.
- Turning a set off stops its disc at once.
- The pad's stops follow the walkie shown (LAMP, MEM and MIC hit the right set).
- Device Options on a car's radio shows the World window whole, and a car's built-in ham gets the plain card.

Journal:
- Blank text saves nothing.
- The delete question holds the log still and drops when the tab is left.
- The kills fold answers only on its head.
- Old entries count their day on the real calendar.
- A write-once item locks after a quick note.
- Enter in the quick note writes it.
- The half card's page bar fits.
- Save is ignored while a write runs.
- The stripe covers the whole entry.
- A written notebook stays in his main inventory.
- The pad walks every row of a long log, tags or not.

Maps:
- M folds ZeD's map while paused.
- The pad can type a note.
- The drawer's wheel leaves the unfolded map alone.
- Read Map takes the game's 30-tick read.
- The side list's delete buttons are no pad stops.
- The light is checked when the map opens, not while it is open.
- A failed map build is tried again.
- A map read from the floor stays on him.

## Test faults found (QA's side)

These were test faults, not product bugs:
- The Character window is built again on every open, so draw wrappers must follow the new drawer.
- The game's item definitions call it getLevelSkillTrained (the book's own getter is getLvlSkillTrained).
- AddXPNoMultiplier still divides by 4 at boost 0.
- The Pencil carries the eraser tag.
- A car's radio part keeps the FM band whatever item is put in it.
- ZeD's prompts replace the game's text box every tick.
- The D-pad moves by screen position, not list order.
- The QA world has MetaKnowledge 3.

## Design calls for the director (asked Nov 27 2026)

Option 1 is QA's pick in each.

Hermit's picks (Nov 27 2026): "1(1); 2(2); 3(1); 4(1); 5(1); 6(1); 7(1); 8(2)".
1. S3: the Skills key while paused opens the Character window. To build.
2. The burger flipper keeps the permit. No change; the I6 note becomes a check.
3. Survived for shows "--". Already built.
4. B3: walk to the TV first, and be in the car for a car radio. To build (R6, R51).
5. J1: the Journal keeps its page for the session. To build.
6. J32: B stops the reading. To build.
7. MP33: a pen before a pencil, the game's order. To build.
8. Put things back sends a read map or a written notebook back to its bag. To build (this undoes the "stays on him" fixes for the notebook and the floor map's bag case).

The calls as asked:
1. **S3, the Skills key while paused:** it opens the Character window, as ZeD_PausedLook promises; or keep the game's rule and drop the promise.
2. **The burger flipper's concealed carry permit** (IdentityTab.lua:45): remove it, or keep it.
3. **Survived for on the license when the watch shows no date:** "--" (built), or drop the line.
4. **B3, a TV across the room or a car radio from outside the car:** walk to the set first and need him in the car, as the game does; or keep ZeD's remote use.
5. **J1, the Journal's page when the window reopens:** keep the page for the session, or always open on the Log.
6. **J32, B while reading a paper:** B stops the reading, or B only goes back (today).
7. **MP33, the map's first ink with no color chosen:** the game's order (a pen before a pencil), or keep the pencil.
8. **Put things back, with a read map or a written notebook:** it stays on him, as the game does (built); or it goes back to its bag.

## Not staged

- Multiplayer: server channels, two-way talk, shared map notes, server-side stash and battery actions (two sets on one square re-read from the square on a server).
- Split screen.
- Languages other than EN.
- A real night dark enough in the debug world (B12 and MP13 use a staged "too dark").
