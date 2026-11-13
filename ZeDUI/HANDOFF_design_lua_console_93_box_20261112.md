# Handoff: Lua Console 93 Professional Edition, the box art (Nov 12 2026)

From design, for Build. Punch list item 176b (art for the standalone mod, version 1.0, no beta wording, no ZeD-GUI
dependency). The director, Nov 12: Code's first square (beige computer, striped band, teal 93) "was not quite the
direction"; of four box directions he picked the third, the shelf screamer ("Three all the way"), named the publisher,
and approved it ("Awesome. Wrap that up for build to use.").

## For the generator (`build_luaconsole93.py`): copy these three, do not draw them

| File | Size | Goes to |
|---|---|---|
| `preview.png` | 512 x 512 | `products/LuaConsole93/workshop/preview.png` |
| `poster.png` | 512 x 512 (the same picture) | `products/LuaConsole93/42/poster.png` |
| `icon.png` | 64 x 64 ("LUA 93" on the box's cream) | `products/LuaConsole93/42/icon.png` |

`console_slice.png` (64 x 64, the wheel slice) is yours to decide: `icon.png` works there if you want one picture.

## The files (`ZeDUI/art/lua_console_93/`)

| File | Size | What |
|---|---|---|
| `lua_console_93_square_512.png` | 512 x 512 | the box on a blue ground (= `preview.png`, `poster.png`) |
| `lua_console_93_square_1024.png` | 1024 x 1024 | the same, larger |
| `lua_console_93_box.png` | 1180 x 1400, transparent | the box alone, front and spine, with its shadow |
| `lua_console_93_front.png` | 960 x 1240 | the front panel, flat |
| `lua_console_93_back.png` | 960 x 1240 | the back panel, flat |
| `lua_console_93_icon_512.png` | 512 x 512 | the icon, large |
| `lua_console_93_sheet.png` | 3920 x 1800 | all of it on one sheet, for reference |
| `lua_console_93_box.html`, `export.js` | | the source and the exporter: `node export.js lua_console_93_box.html <out-dir>` (Playwright) |

The art is smooth vector, not pixel art, on purpose: it is a printed 1993 retail box. Scale it down with a smooth
filter (not nearest). The front and back panels and the transparent box are for the Workshop gallery (176d).

## What is on it (keep these words)

- **Name:** Lua Console 93, *Professional Edition*.
- **Publisher:** DOIDBRO & BUZZLORD SOFTWARE / DIVISION OF LANGUAGE PROTOCOLS LLC (the director's wording: one word
  each, an ampersand, no comma before LLC). ZNIX is not on the box.
- **Front:** "78 SERVER COMMANDS INSIDE!", "NEW! SCRATCHPAD", "Log, Scratchpad, Suggestions, Snippets, Export,
  Controller", a price sticker "$149.95 FREE on the Workshop", foot "Version 1.0, Build 42, debug mode | 3.5" HD, ages 13 and up".
- **Back:** "Stop squinting at console.txt. / Everything your mod says, in one window."; The Log, The Scratchpad, The
  Commands; 78 server commands, 5,000 log rows kept, 200 runs of history, 2 letters to a suggestion; "It printed." and
  "I found the error. It was mine."; system requirements ("Project Zomboid Build 42", "The game started with -debug",
  "An error. Yours will do.", "Nothing else. Stands alone.").

## Checked against item 176

- Version 1.0 on the box; no BETA, no tape, no ZeD-GUI named anywhere on it.
- 78 commands, 5,000 rows, 200 runs, suggestions after two letters, past 256 characters: from punch list 136 and the
  Phase 1 and 2 build notes.
- The commands on the back's third screen (/additem, /addkey, /godmode, /servermsg) are primary names in
  `ZeD_ConsoleCommands.lua`.

## Open

1. **The mark** beside the publisher is a boxed "D", a stand-in; there is no Doidbro & Buzzlord logo yet.
2. If a number changes (commands, rows, runs), change it in the HTML and export again.
3. The page text (176c) can borrow the back's lines: "Stop squinting at console.txt." and the four numbers.
