# ZeD-UI translation plan

*Written Oct 20 2026. The director's call (Oct 19): translation for the whole mod; cover what we can, and let the community translate the way it does for every other mod.*

## Status (Oct 20 2026)

Confirmed in game today: the mod's own `Translate/EN/UI.json` loads and merges with the game's, so translators can ship a file of the same name for their language.

- **Phase 1 (what was broken):** done. The first 28 phrases moved into `UI.json` and load. Context menu icons match by the game's keys instead of English wording. The pixel letters fall back to the regular face when a word has a letter they lack. The fonts carry the extra Latin letters.
- **Phase 2 (the sweep):** done for every window and screen. Every phrase ZeD draws now goes through `ZeD.tr` with a `UI_ZeD_` key: the HUD (belt, watch, dash, radio, action bar, seat chooser), the Character window and all its tabs, the World window and its tabs, the item and object cards, the wheels, prompts and context menus, the main menu and every screen under it, and Settings. `UI.json` holds 2,390 phrases. Wherever the game already had the word (item names, body parts, skills, moodles, context options, sandbox options) the code uses the game's own, so those come in every language for free. Numbers inside sentences are one phrase with `%1` markers, and "one" and "many" are separate phrases where the count shows.
- **The guard:** `ZeDUI/tools/qa/i18n_guard.py` runs outside the game. It checks that `UI.json` is valid, that every key the code asks for exists, that the number of values passed matches the markers, and that no new bare English phrase is drawn to screen. The few phrases left English on purpose (debug text, ids, painted art, art data) are in `i18n_allowlist.txt` with the reason. Run it with the other outside-the-game tests before a release.
- **Phase 4 (pixel letters):** the accented capitals for the Latin languages and the Cyrillic capitals are drawn in the pixel faces, and a word with a letter the faces still lack (Chinese, Japanese, Korean, Thai) draws in the regular face instead.
- **Phase 5 (translator kit):** done. `TRANSLATING.md` explains the job in plain terms and `ZeDUI/i18n/UI_ZeD.context.md` lists every phrase with its English, where it shows and how long it can be. The director's decision stands: contributed translations are included with credit, and translators' own mods work too.
- **Left English on purpose:** words painted into the art (watch, radio and dash plates), hardware marks (FM, MHz, CH), model and maker names, radio presets saved into the device, and the automatic action bar label for mods' unknown actions.
- **Still to do:**
  - Phase 3, the screenshot walk with the test language: turn it on, walk every screen, and fix whatever clips, overlaps or loses its brackets. The sweep made the phrases translatable; this proves the layouts hold when they get longer.
  - Contributed translations: none yet. The first ones will show which phrases are unclear and which limits are too tight.
  - A few size notes from the sweep to settle (two phrases are longer in English than the limit written for them), and removing the old unused stat builders in `ItemCard.lua`.

## The short version

Translating is the community's job, and that's normal for Project Zomboid. Making ZeD **translatable** is ours, and today it isn't. Once it is, a translator ships text files and nothing else: no fonts, no code.

## Where we stand (checked in the repo, Oct 19 2026)

- **Words in the code.** About 770 English phrases are written straight into the Lua across 103 files. Only 28 go through a translation file.
- **Those 28 may not load at all.** They sit in `Translate/EN/UI_ZeD.txt`. Build 42.15 moved translations from `.txt` to `.json`, and even under the old rules the file name had to be the category (`UI_EN.txt`), not `UI_ZeD.txt`. Confirm in game: if `getText("UI_ZeD_Search")` returns the key itself, they never loaded.
- **ZeD replaces the game's fonts.** `media/fonts/EN/fonts.txt` points vanilla's font slots (Small, Medium, Large, Code...) at our Fira bitmaps. Those carry ASCII plus Western European letters only (`generate_fonts.py`: 32-126, 160-255 and a few quotes and dashes).
  - Languages that use the game's English font set draw **all** their text, vanilla's included, in our fonts. Czech, Hungarian, Romanian and Turkish letters (ő, ș, ğ, ı) probably show as gaps. *To confirm by switching languages in game.*
  - Languages with their own font set (vanilla ships Chinese, Traditional Chinese, Japanese, Korean, Russian, Polish, Thai) most likely get the game's fonts inside ZeD's windows. That's readable, but not the ZeD look, and the sizes differ from what our layouts expect. *Which language uses which set is decided in the game's code; confirm in game.*
- **Context menu icons are matched by English wording.** `ContextIcons.lua` maps "Walk to", "Sit on ground"... In a Russian game the option reads in Russian and finds no icon.
- **The pixel letters (dash, watch, radio, belt, action bar) hold A-Z, digits and a few signs.** The action bar already turns accented letters into plain ones. Letters it doesn't have at all (Cyrillic, Chinese) are dropped, so a Russian player's item line comes out empty.
- **Some words are painted into the art** (the dash plates, the watch faces, the radio faces, the desk).

## How Project Zomboid does it (the standard we follow)

- Text lives in `media/lua/shared/Translate/<LANG>/` as JSON files named by category (`UI.json`, `IG_UI.json`, `ContextMenu.json`, `Tooltip.json`, `ItemName.json`, `Sandbox.json`...), saved as UTF-8 (since B42; older files were cp1252).
- Vanilla ships 29 languages: AR CA CH CN CS DA DE EN ES ES_CL ES_MX FI FR HU ID IT JP KO NL NO PL PT PTBR RO RU TH TR UA, plus one more folder (STREW).
- A mod's file merges with vanilla's file of the same category. `ItemName.json` already works that way for our Timez watch.
- Translators publish either a small mod of their own (`Translate/<LANG>/` only, requiring the main mod) or send their files to the author, who includes them. Both are common, which is why the Workshop is full of translation mods.
- The game ships the fonts for each alphabet and swaps them by language. Translators never touch fonts, and with this plan they won't have to for ZeD either.

## What we do

### Phase 0: the rule, starting now (no cost)

New text never goes straight into the code. It goes in `Translate/EN/UI.json` under a `UI_ZeD_` key, and the code calls `getText`. Every screen we build without this adds to the sweep.

Key naming: `UI_ZeD_<Area>_<What>`, e.g. `UI_ZeD_ActionBar_Reading`, `UI_ZeD_Card_Needs`, `UI_ZeD_Fluid_PourFrom`. Areas follow the files (Card, Char, World, Craft, Build, Map, Forage, Animals, Radio, Vehicle, Furniture, Fluid, Lock, Belt, Watch, Dash, Moodles, ActionBar, Prompt, Wheel, MainMenu, Mods, Workshop, Options, Settings).

### Phase 1: fix what's broken for players today (about half a session plus checks)

1. **Rebuild the fonts with more letters.** Fira Sans and Fira Mono already contain every Latin alphabet (Extended-A and -B), plus Greek and Cyrillic. Add those ranges to `generate_fonts.py`, regenerate every size (1x-4x), and check the atlas sizes.
2. **Give Russian and Ukrainian the ZeD look.** Ship `media/fonts/RU/` with the same slots in Fira Cyrillic, if the in-game check shows those languages use the RU set. Chinese, Japanese, Korean and Thai stay on the game's fonts, since Fira has none of those letters. Our layouts measure text rather than assuming widths, so they should hold; the stretch test (Phase 3) proves it.
3. **Context menu icons by key, not wording.** Regenerate `ContextIcons.lua` keyed by vanilla's translation keys (`ContextMenu_Walk_to`). At load, build the current language's map from `getText(key) -> icon`. The English-text fallbacks stay for options mods add without keys.
4. **The pixel letters fall back.** When a word has a letter the 5×7 or 3×5 face lacks, the whole word draws in the regular F1 face instead of losing letters. This covers the action bar's item line today, and the dash and watch legends later.
5. **Move the 28 existing keys** into `Translate/EN/UI.json` and confirm they load.

### Phase 2: the sweep (two to three sessions)

Move every visible English phrase into `UI.json`, window by window, most-seen first: the HUD (belt, watch, dash, moodles chip, action bar) → the Character window → the World window → the cards (item, object, fluid, lock, animal, trailer) → prompts and wheels → the main menu and its screens → Options and Settings.

- **Use vanilla's words wherever vanilla already says it.** Item names, body parts, moodles, skills, traits, recipe names, context options, sandbox options: those come translated into all 29 languages for free.
- **Words built from parts get one key with placeholders,** never glued pieces: `"UI_ZeD_Queue": "%1 of %2"`, not `"of"` between two numbers. Word order changes between languages.
- **Plurals:** a key per form where the count matters ("1 item" / "%1 items"). Languages with more forms (Polish, Russian) can write the plural form as the count's own phrase.
- **The guard:** a test in `ZeDUI/tools/qa/` scans the Lua for quoted English drawn to screen (`drawText("...")`, labels, button text) and fails on anything new. Runs with the other outside-the-game tests.
- **The action bar's 278 labels:** each becomes a key (`UI_ZeD_Act_ISReadABook = "READING"`). The automatic label for mods' actions stays English, by design.

### Phase 3: layouts that stretch (one to two sessions)

German runs about a third longer than English; Russian is often longer still.

- **A test language.** A hidden setting makes `getText` return every ZeD phrase 40% longer, accented and bracketed (`[Ŕéàďìñĝ ŕéàďìñĝ]`). The QA bridge walks every screen and screenshots it, the way the earlier sweeps did. Anything clipped, overlapping or missing its brackets shows at a glance, without waiting for real translations.
- **Layout rules for the fixes.** Buttons and pills size to their words. Labels that can't grow end in "…" with the full text in the hover hint. Headings never shrink their font to fit (no shrink-to-fit anywhere; it reads as broken).

### Phase 4: the pixel letters (one session, part design)

- **Accented capitals for every Latin language**, drawn in the 5×7 and 3×5 faces: À Á Â Ä Ã Å Ç È É Ê Ë Ì Í Î Ï Ñ Ò Ó Ô Ö Õ Ø Ù Ú Û Ü Ý Ÿ, plus Polish, Czech, Hungarian, Romanian and Turkish (Ą Ć Ę Ł Ń Ś Ź Ż Č Ď Ě Ň Ř Š Ť Ů Ž Ő Ű Ș Ț Ğ İ Ş). About 50 glyphs per face. The faces are rows of 0s and 1s in `PixelFonts.lua`, so it's a drawing job, not a code job.
- **Cyrillic (33 capitals per face)** is optional. With the fallback in Phase 1, Russian already reads in F1; drawing Cyrillic makes it read in pixels.
- **Words painted into the art stay English**, the same way vanilla's own signs, posters and box art do. That covers the dash plates, the watch faces, the radio faces and the desk. Live text drawn over the art (readouts, the action bar, the moodle row) follows the language.

### Phase 5: the translator kit (half a session)

`TRANSLATING.md` in the repo, linked from the Workshop page:

- **Which files:** `Translate/EN/UI.json` (all of ZeD's own words) and `ItemName.json`. Copy them into `Translate/<LANG>/`, translate the right-hand side, save as UTF-8.
- **What each phrase is for.** JSON can't hold comments, so a companion `UI_ZeD.context.md` lists every key with where it shows and how long it may be. Pixel-face text has hard limits, e.g. "action bar label: 14 letters".
- **How to check your work:** switch the game's language, open the screens; the test language shows where space is tight.
- **How to publish:** your own mod (a `Translate/<LANG>/` folder, `require=ZeD_UI`, ZeD as a required item on the Workshop), or send it to us and we include it with credit.
- **Credits:** translators named on the Workshop page and in the About block.

## What translators ship

Only `Translate/<LANG>/UI.json` (and `ItemName.json` if they translate the watch's name). Fonts only if their alphabet is in neither ZeD's fonts nor the game's, and after Phase 1 none of the game's 29 languages fall in that gap.

## Effort

| Phase | What | Rough size |
|---|---|---|
| 0 | The rule | Now, no cost |
| 1 | Fonts, icons by key, pixel fallback, the 28 keys | Half a session, plus the in-game language checks |
| 2 | The sweep, with its guard test | Two to three sessions |
| 3 | Test language and layout fixes | One to two sessions |
| 4 | Accented pixel capitals (Cyrillic optional) | One session, part drawing |
| 5 | Translator kit | Half a session |

## To confirm in game before Phase 1

1. Whether the 28 existing keys load today (expected: no).
2. Which font set each language uses: switch to Czech, Turkish, Russian, Ukrainian and Polish, and screenshot a ZeD window and a vanilla tooltip in each.
3. That a mod's `Translate/EN/UI.json` merges with vanilla's `UI.json` (expected: yes, as `ItemName.json` does).

## Decisions for the director

1. **Include contributed translations in ZeD itself, or leave them as separate mods?** Including them means players get their language automatically and translations ship in step with updates. Separate mods take no work from us but fall behind whenever we change text. I'd include them and accept translators' own mods too; the game merges both.
2. **Draw Cyrillic pixel letters, or let Russian and Ukrainian fall back to F1?**
3. **Where translators send files:** a pinned Workshop discussion, a public repo, or both. This ties into the Workshop plan.
