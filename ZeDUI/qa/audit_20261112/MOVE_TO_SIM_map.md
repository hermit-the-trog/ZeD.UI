# MOVE TO SIM: which sim replaces which in-game script (Nov 12 2026)


Commits on top of a69794b63:
- 8d13d2670: moves eight in-game checks into the existing sims
- a21de5d52: adds one new small sim, mods_lists_sim.lua
- 4d402b094: adds four new sections to dash_odo_sim.lua

No mod code changed. Only files under ZeDUI/tools/qa were touched. I ran every touched sim and they all pass with 0 failed: dash_odo 333, vskdash 412, animals_quick 219, seg_bar_spread 32851, balloon_cjk 266, guide_ads 406, guide_lang 21, item_meter 41, strip_page 321, fix_shared_misc 58, mods_lists 59, mods_order 63, mods_files 76, console_complete 353, ctx_overlap 24. i18n_guard.py also passes.

Two places differ from the names in the brief:
- **Strip hover (zedqa_ctx_overlap.lua):** I put this in strip_page_sim.lua, not ctx_overlap_sim.lua. The strip style is ZeD_ContextMenu.lua, which strip_page_sim already loads. ctx_overlap_sim only loads the list style.
- **Kinsoku and the Simple look's no-ads check:** these went into guide_lang_sim.lua. It already cuts code from ZeD_SurvivalGuide.lua.

Mapping, in-game script -> sim (checks added):
- zedqa_animals_list.lua -> animals_quick_sim.lua, ZONES (+2): a 600-animal herd counted against a 75-square walk of the player's floor (fractional z, wild ones left out), and one refresh under 8 ms.
- zedqa_dash_keys_edge.lua + archive/zedqa_dash_r6_keys.lua -> dash_odo_sim.lua, KEYS (+15): ACC with the key in, the start sequence acc-off-on-start-on, ON while running, shut-off on-off-acc, the dry start back to ACC, no key drawn with it out, steps 90 to 400 ms, the dash flush on the screen's bottom edge, the ash tray click and back, and no tray on the police, fire, ambulance or ranger dashes.
- zedqa_dash_brands.lua -> dash_odo_sim.lua, BRANDS (+44): 14 cars named as in the game's IG_UI.json, each checked for its design, its mark and the mark's sprite; the Step Van on the van dash with the Chevalier mark and STEP VAN; a Ford Bronco through D._badges gets the plaque.
- zedqa_dashnight.lua -> dash_odo_sim.lua, NIGHT (+7): light to nightness 0, 4 and 8 eighths; the dark plate with lights off, the lit plate with them on; the lit plate draws brighter; the D.qaNight override.
- zedqa_dash_r6_parts.lua -> dash_odo_sim.lua, PARTS (+14): flag drop 1.50 by a click, a minute's wait to 1.75, the sandbox flag drop of 2.00 read live, a fifth of a mile adding its rate, extras at 0.50, 1.00 and 0, the key out clearing the meter, the hula girl at rest and swaying both ways, the TAXI - CAB nn unit line, and the van's decal, NO SMOKING or ash tray.
- zedqa_ctx_overlap.lua (STRIP part) -> strip_page_sim.lua, DRILL (+7): after drilling into Eat, hovering each cell through the real update() keeps the drill-down and selects that cell.
- zedqa_segbars.lua -> seg_bar_spread_sim.lua, FILL (+27): lit counts at 64, 4, 100, 0, 70, 30 and 99.9 %, always ten cells; ten distinct cells at fillBarMinW inside the frame; a skill at level 5 lights 5; the Skills help words (barHelp cut from SkillsTab.lua); the hover help line with and without a label; the stat bar row's help (cut from Molecules.lua); nothing when the pointer is off the bar.
- zedqa_sc_font.lua -> balloon_cjk_sim.lua, COUNT (+22, 11 each in EN and CN): "map" and "simplified Chinese" swap to ZeD's face; Cafe with e-acute and kana do not; "map" measures about twice its first letter; a "(2)" after each string lands after it; map(2) draws in one face with all its letters.
- zedqa_button_case_game.lua -> fix_shared_misc_sim.lua, CASE (+9): drawButton puts its words through ZeD.btnCase and keeps them as given with keepCase. Source checks that the card's verbs, verb strip and flags, tabs, buttonW and tags reach the case rule, and that no in-game tab file uses keepCase.
- zedqa_guide_ads.lua -> guide_ads_sim.lua (+1) and guide_lang_sim.lua (+1): close and reopen (B.open keeps the player's book and lays it out again), and the Simple look's window has no ads. Pair level, gutter and "showing spoilers deals nothing again" were already in guide_ads_sim.
- zedqa_console_complete.lua -> none added. The sims already cover the logic; the Kahlua pairs over _G, Java reflection and the real text box keys stay in game.
- zedqa_files_after.lua -> none added. This stays as one by-hand or release check, since the engine really running the helper's copy can't be shown outside the game.
- zedqa_lang.lua -> i18n_guard.py, check 5 (+1, covering all 27 languages): keys missing from each language plus keys identical to English must stay under 8%. Today the highest is NL at 5.2%. Missing keys are also listed as a warning.
- zedqa_kinsoku.lua -> guide_lang_sim.lua, KINSOKU (+5): the real wrapRuns cut from ZeD_SurvivalGuide.lua, on 60 Japanese and Chinese paragraphs at 6 widths. No line starts with a closing mark, long-vowel mark or small kana, none ends with an opening mark, and every letter is kept in order. I broke the rule in the mod file on purpose once to confirm the sim fails, then restored it.
- zedqa_b11_notes.lua (162) -> item_meter_sim.lua, STACK (+4): four bottles in both Cond sort orders read the empty one; opened rows each read their own bottle; only the stack's head row gets the stack.
- zedqa_mods_order.lua -> mods_lists_sim.lua, ORDER (+9).
- zedqa_mods_folders.lua -> mods_lists_sim.lua, FOLDERS (+28): includes folderBox cut from ZeD_MainMenuModsFolders.lua.
- zedqa_mods_separators.lua -> mods_lists_sim.lua, SEPS (+21): includes sepFromFolders cut from ZeD_MainMenuModsSeps.lua.

mods_lists_sim also has one load check, for 59 checks in all. It runs the real ZeD_ModOrder.lua and ZeD_ModFolders.lua on an in-memory file system, with Kahlua's UTF-16 strings stood in.

Parts of the three mods scripts are still in game only, because they need the live Mods screen. The brief said order parts 1, 2 and 5 already ran on made-up mods; in the script itself, only 3, 4, 5 and 6 do, so 1 and 2 could not port directly.
- **mods_order:** part 1 (ModOrder.stats over 60 idle frames), part 2 (Find with its place numbers and Show in full list), and the screen's Undo of pins and profile-load steps 4d to 4f.
- **mods_folders:** 4b to 4d (Unfiled listed last in the folder view).
- **mods_separators:** the screen moves and box in parts 1g to 1i, 2b to 2e and 3, and 4f to 4k (Done, the profile load and Auto through the screen).

QA can archive the in-game scripts as above, except: keep zedqa_console_complete.lua and zedqa_files_after.lua as by-hand checks, and keep the screen-only parts of zedqa_mods_order, zedqa_mods_folders and zedqa_mods_separators listed above, or drop them by choice.

- mods_lists_sim.lua (new)
- dash_odo_sim.lua
- animals_quick_sim.lua
- seg_bar_spread_sim.lua
- balloon_cjk_sim.lua
- guide_ads_sim.lua
- guide_lang_sim.lua
- item_meter_sim.lua
- strip_page_sim.lua
- fix_shared_misc_sim.lua
- i18n_guard.py
