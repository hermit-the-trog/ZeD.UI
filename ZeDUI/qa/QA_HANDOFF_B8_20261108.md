# Build to QA: everything for the Nov 8 upload (main at 0646e07d)

The director's ruling: QA tests the whole queue at once. Every piece below passed an independent code review and its own sim; all 44 sims, the i18n guard and KCheck pass on main; every Java call was checked against the installed 42.21 jar. Nothing has run in the game. Version to stage: 0.3.0-beta8.

Each piece has its own in-game checklist (what to open, how, what should show, 4K and Deck, mouse and pad):

| Piece | Checklist |
|---|---|
| The guide's copyright page, 32 new third-size ads (director-approved) | the guide sims; look at the book's first spread and the ads |
| Multiplayer rules hold: timed bans as the game's ban, join rules gate and kick, host helper (RCON), the game's unban wins, offline voice mute | docs/specs/MP_SERVER_PART_DESIGN.md, E21-E27; ZeDUI/server_helper/README.md |
| Outside review fixes: card band, Craft check, dash km/h, sandbox preset, name prompts, Options Find, offline Mute, whisper | ZeDUI/qa/REVIEW_BETA7_EXTERNAL_20261107.md items |
| Respawn to the desk | CHECK_respawn_20261107.md |
| TV and radio, animal info, check zone | CHECK_world_devices_20261107.md |
| Paper maps in ZeD's map | CHECK_paper-map_20261107.md |
| Seven mods | CHECK_belt_mods / CHECK_mods-menus (the hotbar, icon and menu mods) |
| Main menu windows (mod download, invites, world select, terms, controller map, advanced sounds, Tutorial label) | CHECK_mainmenu_vanilla_20261107.md |
| Everyday leftovers (heater to dash, mini-map, labels, make-up in hair, controller notices, every notice as a Messages bubble, paused look-only, station card) | CHECK_everyday_leftovers_20261107.md |
| Trading and the medical check | CHECK_trade_medic_20261107.md |
| Admin: player stats, inventory, claims | CHECK_admin_player_claims_20261107.md |
| Admin tools: users (masked password, bans through ZeD), stats, PvP log, climate, server sandbox, zones | CHECK_admin_tools_20261107.md |
| Multiplayer windows and the kicked screen | CHECK_mp_leftovers_20261107.md |
| Debug Lua console (-debug) | CHECK_debug_console_20261107.md |
| Known issues: picks, split-screen belts and dashes, ash tray, FR/HU months | CHECK_known_issues_20261107.md |
| Wounds Overhaul | CHECK_wounds_overhaul_20261107.md |
| Stepping aside for UI mods | CHECK_step_aside_20261107.md |
| Desk notes (CletusWorks, Documents) and ProtoPOP3 Mail | CHECK_desk_notes_mail_20261107.md |
| One phrase for the forms (110) | CHECK_forms_phrase_20261107.md |
| Used to make, skill levels, the game's focus pause restored, recipes skills teach (109) | CHECK_alt_tab_gaps_20261107.md |
| Hidden facts: TV schedule, infection odds (109) | CHECK_hidden_facts_20261107.md |

Watch for: the guide's pages shifted (copyright page, contents, a Television/Radio rules page), so gallery spreads 46 and later may need retakes (punch list 105); every game station opens its own window once (butcher hook, log bench and friends keep the game's); a real controller in the paused windows; getFilenameOfClosure's path form for Workshop mods (step aside).
