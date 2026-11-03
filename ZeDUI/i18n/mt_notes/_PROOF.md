# Proofreading a ZeD-GUI machine translation (shared rules for every proofreader)

ZeD-GUI is a complete interface mod for the game Project Zomboid (Build 42, set in Kentucky in 1993). In its fiction it
runs on ZNIX, a made-up operating system written by a paranoid doomsday prepper. Its words read like a technical
manual: plain, short, dry. A Sonnet model drafted this language; you are the second, careful pass. Native players will
check it later, so fix what is wrong, not what is merely a different good choice.

## Your files (in your language's folder)
- `pack_NN.txt`: one phrase per two lines. First `number | longest | where | English`, then `  = ` and the draft.
  `longest` is the most characters the phrase may take on screen (`-` = no limit); `where` says where it shows, and
  `^` means the same place as the line above.
- `glossary.txt`: the game's own interface words in this language (players know them; a listed word can be wrong for a
  given line).
- `notes.txt`: the drafter's own doubts. Look at those first.

## What to look for
1. Meaning: the draft says something other than the English (a wrong sense of a word, a lost negation, a mixed-up
   subject). Use `where` to understand the line.
2. Tone and politeness: one level of address throughout, the level the game's own menus use; buttons, tabs and
   headings in the form the game's menus use.
3. Consistency: the same English term rendered the same way across the whole file (keep a short list as you go).
4. Grammar: word endings and agreement, above all around %1 to %4 (a number or a name goes there).
5. Length: a line longer than `longest` must be shortened.
Keep %1 to %4, %%, markup like <LINE> and the two characters \n exactly as the draft has them.

## What you write
For each pack, `fix_NN.txt` in your folder, with ONLY the lines you change, one per line:
`number<TAB>corrected text<TAB>reason in a few English words`. A pack with nothing to change gets an empty file.
Read each pack whole (Read with allow_large: true), then Write its fix file whole. Keep tool calls few: one Read and
one Write per pack; do not read your own files back.

When all packs are done, reply in at most 8 lines: how many lines you changed per kind (meaning, tone, consistency,
grammar, length), the three most important fixes, and anything a native checker should still look at.

Do not edit anything outside your folder, do not commit, do not run anything but Read and Write, do not message other
sessions.
