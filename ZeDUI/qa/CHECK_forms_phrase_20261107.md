# Check: one phrase for the two forms (punch list 110, Nov 7 2026, Build)

## What changed
- ZeD setup's "Full or simple" section is now **Immersive or simple**: Belt, Devices, Watch, Dashboard, Survival guide,
  Identity card (moved in from Look). All six use UI_ZeD_Settings_Immersive; each help line reads "Immersive: ... Simple: ...".
- **Action bar** moved to HUD (after Watch); its rich choice reads **Detailed** (was Verbose).
- **Mods screen** moved to Windows; its rich choice reads **Detailed** (was Full; it now uses the ActionBarVerbose key).
- **Context menu** and **Equipped items** moved to Windows, right after Inventory (then Mods screen, the accents, Hidden actions).
- Strings, all 28 UI.json files (machine drafts, as the language files are labeled): ZedForms, Belt/Devices/WatchStyle/
  Dash/Guide/ActionBar/Mods tips, ActionBarVerbose, the guide's ZeD setup chapter title and text, the beta 3 what's-new line.
  Where a draft had translated Immersive as "Full" (AR, CH, CN, CS, FI, HU, PL, RU, UA), Immersive got its own word;
  DA, DE and NL got a "Detailed" word in place of their "Verbose" one. AR's guide tip was Arabic in a Spanish file:
  now the Spanish one.
- Saved choices: no option's items changed order or default; the presets are untouched (Vanilla Access still picks Simple).
- In-game script zedqa_menu_forms.lua: its expected row list follows the new section.

## Tests
- New ZeDUI/tools/qa/forms_phrase_sim.lua: 62 checks, 0 failed. On the old code: 23 failed.
- menus_b7_sim: 26 / 0 failed. spncc_fold_sim: 96 / 0 failed.
- i18n_guard.py: PASS.

## Not tested
- Nothing in the game: the rows drawn on screen, the Find box, the other languages' fit at Deck / 720p with Large text.
- zedqa_menu_forms.lua was edited, not run.
- The gallery spreads (12, 26, 31, 46, 48, 61) are design's and unchanged.
