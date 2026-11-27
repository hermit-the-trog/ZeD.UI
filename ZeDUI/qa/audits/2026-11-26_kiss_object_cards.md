# KISS test: the object cards (QA, Nov 26 2026)

The director, Nov 23 2026: "With every one of these micro QA passes, also do a KISS test." This covers the object cards sweep, Hermit's go on Nov 26.

Maps (in ZeDUI/qa/audits):
- 2026-11-26_map_cards_power_fluid_fire.md (PW, FL, FI)
- 2026-11-26_map_cards_farm_animals.md (FA, TG, HU, HK)
- 2026-11-26_map_cards_lock_medic_rest.md (OC host, LK, MD, LA, PL, TK, TD, PV)

Scripts (each manifest at both 4K and 1280x800): ocp_tab (ocp.txt), oca_tab (oca.txt), ocl_tab (ocl.txt).

## Where it stands (Nov 26 2026, main 6cf674e45)

| Sweep | 4K | 1280x800 | What still fails |
| --- | --- | --- | --- |
| Power, fluid, fire | 128 pass, 1 fail | 127 pass, 2 fail | FI1 (design call) |
| Farm, trough, hutch, hook | 186 pass, 5 fail | 213 pass, 5 fail | FA7, FA8, TG5 (design calls) |
| Host, lock, medic, laundry, placement, track, preview | 108 pass, 4 fail | 107 pass, 4 fail | LK5, OC4 (design calls); OC7 fixed in fix/oc7b (08879af3a) |

The skips are multiplayer cases, other languages and staging the game can't do in single player.

## Bugs found and fixed

All are fixed on main through fix/cards, fix/nov26batch, fix/cards3, fix/fluidvalid and fix/hu5focus.

Power:
- Indoor fumes warning on every way of starting a generator.
- The wheel picks the nearest generator.
- A broken generator can't be turned on.
- Disconnect needs no skill, as in the game.
- Add All for fuel.
- Info from far off walks there first.

Fluid:
- The Empty question names the container.
- Stop works during the walk.
- A busy gate stops a double pour.
- Far containers walk there.
- Seated, the game's own window opens.
- The well's hidden amount stays hidden.
- After a pour the card finds its container again, since rain collectors are rebuilt.

Fire:
- Lighting never burns a skill book or a map.
- All fuel takes only plain fuel.
- The wheel puts out the nearest fire.
- Take apart says what drops to the ground.
- The propane tank swaps in one step.
- The Light need names the missing lighter.

Farm:
- The water colours follow the crop's need.
- The pad never opens on Fertilize.
- "Dig up?" stays tied to its own plot.
- The shovel is checked at Yes.
- Missing translations are filled in.
- Garden labels are unique.
- "Destroyed" reads as the game words it.

Trough, hutch, hook:
- The Food tag follows the feed.
- The trough card comes back after a pour.
- Put in is greyed with the game's reason.
- B from a bird's page comes back to the hutch.
- The egg count uses the game's words.
- The hutch leash closes at 5.
- Remove corpse asks first.
- A part the animal never had reads "No".
- Add corpse waits for a valid body.

Lock, medic, laundry, placement, track, preview:
- The code dial freezes while the question asks, and Yes locks with the code shown.
- Padlock words say "main inventory".
- Loot columns stay open.
- The medic card shows no numbers to an untrained doctor and uses the game's wound words.
- B shuts the treatment menu first.
- Medic treatments sit beside the figure.
- Washer Power has a busy gate.
- The washer shows the clothes' real state.
- The washer door walks over from far off.
- Closing the window ends placement and hides the gizmo.
- The leash counts only the card's own actions.
- An old track isn't tagged green.
- The track card is a half card and follows a carried track.
- The build strength updates with skill.
- The preview opens while seated.
- The item card gets a border over a tab card.

## Design calls for the director (asked Nov 26 2026)

Option 1 is QA's pick in each. **Decided Nov 26 2026** (Hermit: "1 through 6, do 1, and 4, 7, do number 3, and number 8, do 2"): option 1 on calls 1 to 6, the Side by side fluid layout (option 3) and the washer's stepping lamps kept as dressing (option 2). Relayed to Build.
1. **FI1, an indoor campfire:** warn, as the generator does, or keep the game's silence.
2. **FA7, heavy aphids:** one press sprays what's needed, as the game does, or keep one use per press.
3. **FA8, watering:** pick the container, or keep the biggest automatically.
4. **TG5, the trough:** one press moves one, with an "all" row, or keep moving all.
5. **LK5, a wrong padlock code:** instant, as the game does, or keep the timed try.
6. **OC4, object cards at 1280 wide:** half card when the window is narrow, or keep full.
7. **The fluid card layout (mock-up v1):** stat rows, one list, or side by side.
8. **The washer's lamps:** real state only, as built, or bring the stepping WASH/RINSE/SPIN lamps back as dressing.

Also decided by Hermit on Nov 26 2026:
- The shown container takes the tabs' lit panel.
- The medic treatments go beside the figure.
- The tracks card is a half card.
- An item card over a tab card gets a border.
- Every object card's verbs go in the foot band (feat/card-foot-verbs).

## Not staged

- Multiplayer: claims, trades, two players at one object, the server's syncs.
- Split screen.
- Languages other than EN.
- A gas shutoff.
- A trailer hitch.
