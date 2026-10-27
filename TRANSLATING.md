# Translating ZeD-UI

ZeD-UI ships its words in text files, so you can translate it without touching any code or fonts. This page is the short version.

## What you translate

Two files, both in `42/media/lua/shared/Translate/EN/`:

- `UI.json`: every word ZeD draws (about 2,400 phrases).
- `ItemName.json`: the name of the Timez watch (two lines; skip it if you like).

You do not need to translate item names, body parts, skills, traits, moodles or recipes. The game already has those in every language, and ZeD uses them.

## How

1. Copy the two files into a folder named for your language, next to `EN`: `Translate/FR/`, `Translate/DE/`, `Translate/RU/`... Use the same language codes the game uses (AR CA CH CN CS DA DE ES ES_CL ES_MX FI FR HU ID IT JP KO NL NO PL PT PTBR RO RU TH TR UA).
2. Open each file in a text editor. **Save as UTF-8.** Change only the right-hand side of each line. Never change the key on the left, and never remove the quotes or commas.
3. Keep the `%1`, `%2`, `%3`, `%4` markers. The game puts a number or a name there. You may move them to suit your grammar ("%1 of %2" can become "%2 / %1"). Keep markup such as `<LINE>` as written.
4. A phrase with no translation falls back to English, so you can send a partial file and finish it later.
5. A quote mark inside a phrase is written `\"`. A new line is `\n`. A percent sign is written `%%` ("cond %1%%" shows "cond 80%"), as in the game's own files; a single `%` breaks the phrase.

## What each phrase is for, and how long it can be

`ZeDUI/i18n/UI_ZeD.context.md` lists every key with its English, where it shows on screen, and the longest it should be. JSON cannot hold comments, so read that file alongside the JSON. If a key is hard to understand, the "Where it shows" column says which window and which control.

The tight spots (the context file has the exact number for each phrase):

| Where | Limit |
|---|---|
| Action bar over the character's head (the `UI_ZeD_Act_` keys) | 14 letters, capitals |
| Weekday on the watch face | 2 letters |
| Watch readouts, dash and radio panel marks | 4 to 12 letters, capitals |
| Buttons and small status chips | 10 to 16 letters |
| Tab names, column headings | 8 to 14 letters |
| Hover hints and notes | 24 to 60 letters |

Pixel-face text (the action bar, and the watch, dash and radio readouts) is drawn in capitals A to Z, digits and a few signs. Accented capitals work for the Latin alphabets, and Cyrillic capitals are drawn too. A word with a letter those faces lack (Chinese, Japanese, Korean, Thai) draws in the regular face instead, which is readable but not pixel-styled. Words painted into the art itself (watch faces, radio faces, dash plates) stay English, the same way the game's own signs and box art do.

Only the pixel-face words are capitals: the action bar labels and the marks on the dash, watch and radio. Everything else in English is sentence case, one capital at the start and the rest in lower case (Next level, Show survey, Delete all notes?), for headings, column heads, tags, buttons and status words alike. Write yours the way your language writes a heading or a button, not in capitals. Where a pixel-face word must be capitals but your language has letters the game cannot uppercase, write it in capitals yourself.

## Check your work

1. Switch the game's language in Options.
2. Start a game (or open the main menu) and look through the screens: the character window tabs, the world window, an item card, the main menu pages, Options.
3. To see where text is tight before you translate, turn on **Test language (stretched text)** in Options > Mods > ZeD-GUI. Every ZeD phrase then shows about 40% longer, accented and in square brackets. A phrase that is clipped, overlaps something, or loses its closing bracket is a spot that needs room. Turn it back to Off to play normally.
4. If a phrase shows as `UI_ZeD_Something` the key is misspelled in your file. If it shows in English, your file did not load: check the folder name, the file name and that the file is valid JSON (a missing comma is the usual cause).

## Publish it

Two ways, both welcome:

- **Your own mod.** Make a mod that holds only `Translate/<LANG>/UI.json` (under `42/media/lua/shared/`), with `require=ZeD_UI` in its `mod.info`, and list ZeD-UI as a required item on its Workshop page. The game merges your file with ZeD's. This is the way if you want to keep control of it.
- **Send it to us.** Send the finished `UI.json` and we include it in ZeD-UI itself, with your name in the credits, so players get the language automatically and it ships in step with updates. When we change a phrase, we will tell you which keys are new.

Either way, say which version of ZeD-UI you translated against. New releases add phrases; a missing phrase shows in English until it is translated.
