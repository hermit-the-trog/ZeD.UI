# Bug 158 probe: Chinese characters missing from the speech balloon (Nov 12 2026)

Single player, ZeD-QA save, `-debug -nosteam`, 4K fullscreen. The player said the line below. The probe ran as a QA chunk through the QA bridge (`zedqa.lua`, a temporary file outside the repo) rather than ZeD's console or a client drop-in; it printed to console.txt. The string was built with `string.char` from its UTF-8 bytes, because Kahlua drops the high bytes of non-ASCII literals in a .lua file.

Line said: `getPlayer():Say("搜刮状态")`, bytes `E6 90 9C  E5 88 AE  E7 8A B6  E6 80 81` (12 bytes: 搜 刮 状 态).

Run twice: once with the game's language English (the QA default) and once with `language=CN` in options.ini (Simplified Chinese), put back to EN afterward.

## Values

| What | EN | CN |
|---|---|---|
| input | len=12, `E6 90 9C E5 88 AE E7 8A B6 E6 80 81` | same |
| `p:getSayLine()` at tick 12 | len=0 (the hook had already taken it from the engine) | len=0 |
| `ZeD.Bubbles._sp[0].text` | len=12, `E6 90 9C E5 88 AE E7 8A B6 E6 80 81` (all four characters) | same |
| `_sp[0].lines` (1 entry) | `[1]` len=12, `E6 90 9C E5 88 AE E7 8A B6 E6 80 81` | same |
| `_sp[0].sideLines[1]` | len=12, same bytes | same |
| `getTextManager():MeasureStringX(UIFont.Cred1, "状")` | 36 | 25 |
| `...MeasureStringX(UIFont.Cred1, "搜")` | 28 | 24 |
| `...MeasureStringX(UIFont.Cred1, whole line)` | 137 | 120 |
| `ZeD.Text.scriptFont("搜刮状态")` | `false` (type boolean; not nil, not a table) | `false` |
| `ZeD.Text._scriptFonts` | ready=true, nfonts=2, zedFont=MainMenu1 | ready=true, nfonts=0, zedFont=nil |

## What the balloon shows

In both languages the balloon draws mojibake, not Chinese: the line's bytes drawn one by one as Latin-1 characters (visible glyphs `æ å ® ç ¶ æ`; the bytes 0x80 to 0x9F draw nothing). Screenshots, not committed, in the QA scratch folder (`%TEMP%\claude\...\scratchpad`):

- `zqa_158_balloon.png` and `zqa_158_crop.png` (English)
- `zqa_158_balloon_CN.png` and `zqa_158_crop_CN.png` (Chinese)

## Verdict

`.text` already holds all four characters (the 12 bytes arrive whole), and the Cred1 measures are above 0. The cut is not before the balloon: it is in the draw. The line is drawn byte by byte, so the Chinese glyphs never appear (in this build the symptom was garbled Latin-1 glyphs, with the bytes 0x80 to 0x9F invisible, rather than only 状态 missing).

A lead (read from the code, not proven by this probe): `ZeD.Text.scriptFont` answers `false`, so the script swap that would draw the line in a face that has the glyphs never runs. `sfScan` (Scale.lua) tests each byte with `MeasureStringX(font, string.sub(str, i, i))`, and a lone UTF-8 byte measures above 0 as a Latin-1 character, so the check reads as "ZeD's face has every glyph" (`miss == 0` returns false). Under CN the cause differs: the swap has no fonts (`nfonts=0`, `zedFont=nil`), so it returns false at once.
