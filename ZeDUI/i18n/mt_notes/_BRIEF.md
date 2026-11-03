# Translating ZeD-GUI's interface text (shared rules for every translator)

ZeD-GUI is a complete interface mod for the game Project Zomboid (Build 42, set in Kentucky in 1993). In its fiction it
runs on ZNIX, a made-up operating system written by a paranoid doomsday prepper; the look is Macintosh System 6/7, DOS
and the TI-99/4A. The words are a technical manual's: plain, short, dry, no marketing, no exclamation marks.

## Your files (in your language's folder)
- `pack_NN.txt`: the English, one line per phrase: `number | longest | where | English`.
  - `longest`: the most characters the phrase may take on screen (`-` = no limit). Stay within it; shorten naturally
    (a common abbreviation, a shorter word) when you must.
  - `where`: where it shows. `^` means the same place as the line above.
  - A line may be followed by `  = text`: this language's current text (variants and Chinese only, see your task).
- `glossary.txt`: the game's own interface words in your language. Where the meaning matches, use the game's word
  (players know them). A listed word can be wrong for a given line ("game" can be meat): judge by meaning.
- `index.json`: leave it alone.

## What you write
For each `pack_NN.txt`, write `out_NN.txt` in the same folder: one line per phrase, `number<TAB>translation`, every
number of that pack in order (unless your task says to write only changed lines). One real TAB character between the
number and the text; nothing else on the line. Read a pack whole (Read with allow_large: true), then Write its out file
whole. Do the packs in order, and keep your own word choices the same from pack to pack.
Keep tool calls few (credits): one Read and one Write per pack is the aim. Do not read your out files back to proofread them, and do not read the glossary twice; the check in the last step finds the mechanical slips.

## Rules for every line
- Keep `%1` `%2` `%3` `%4` exactly (you may move them where your grammar needs them), keep `%%` (a percent sign), keep
  markup such as `<LINE>` `<RGB:1,0,0>` `<SIZE:small>` untouched, and keep `\n` as the two characters backslash and n.
- Where the English is ALL CAPITALS (pixel faces, headings, the action bar), write capitals too, when your script has them.
- Keep these as written: ZeD, ZeD-GUI, ZNIX, ZeD setup's preset names when the English capitalises them as names,
  Kentucky Instruments, Steam, mod names, file names (preview.png, UI.json), controller button letters (A, B, X, Y, LB,
  RB, LT, RT), key names (Esc, Shift, Ctrl), units and numbers as the English writes them.
- Keep separators as the English has them: " | " stays " | ". Never use the middle dot.
- Buttons in sentence case as the English has them; headings keep their capitals.
- Address the player the way the game's own interface does in your language (formal or informal: look at the glossary,
  or grep the game's file for a word: E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/shared/Translate/<LANG>/UI.json;
  grep for a word, never read the game's files whole).
- A phrase that is the same in your language (a name, "OK") may stay as the English.
- ZeD's own terms with no game word (flag your choice in notes.txt): Loadouts, Outfits, Restock, Unpack, Survey, Full /
  Simple (two ways to draw a surface: the real thing or a plain card), the belt (the HUD strip), the drawer, the card
  (an item's details panel), the wheel (a radial menu), Safe mode.

## When the packs are done
1. Run, with this Python (it is already installed; install nothing):
   `C:/Users/you/Documents/ComfyUI/.venv/Scripts/python.exe -I C:/Users/you/Zomboid/mods/ZeD-UI/ZeDUI/tools/i18n/mt.py unpack <your folder> <your folder>/parts`
   (add `--base <LANG>` only if your task says so), then for each file in `<your folder>/parts`:
   `... mt.py check <that file>`. Fix every FAIL line in your out file and run both again until there are none. "same as
   English" notes are fine where the word really is the same.
2. Write `notes.txt` in your folder: at most 15 short lines, the choices a native checker should look at first (the
   terms above, anything you were unsure of).
3. Reply in at most 6 lines: the language, lines written, the check result, the three most doubtful choices.

Do not edit anything outside your folder, do not commit, do not run the game, do not message other sessions.
