# Main menu checks, Nov 1 2026 (QA; HANDOFF_main_menu_book_20261101.md)

Taken through `tools/qa/zedqa_menu_about_run.ps1` (a windowed main menu with no save, the look scripts around it).

- `mm_about_1280x720.png`, `mm_about_1280x800.png`: the ZeD menu pulled down with the rewritten About paragraph
  (t15). **Both pass:** the menu ends inside the monitor's glass with room under it (at 720 the drop ends about a
  quarter of the glass above its bottom edge; at 800 about the same). No hotfix.
- `mm_desk_v4_1920x1080.png` (lit), `mm_desk_v4_1920x1080_dim.png` (a lamp dim beat forced): the v4 desk as the mod
  draws it. **Matches `tools/mainmenu/previews/main_menu_v4_4x.png`:** the book spine out on the monitor's right
  with THE SIMZ turned beside it; everything left of the monitor as v3; the dial and needle untouched; on the dim
  beat the lamp's side of the desk drops as before.
