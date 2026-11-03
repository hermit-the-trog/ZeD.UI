# Compatibility thread, version 7 (Nov 2 2026)

Version 6 (Build's scan layout: emoji on each list, letter headings) in the director's order: Supported first,
Compatible, then Does not work and Broken last. The same 559 mods and the same words.

- The first post: the index, then Supported (21).
- Reply 1: Works well with ZeD (13), then How the mods were tested, Help for long mod lists, To add a mod.
- Replies 2 to 10: Compatible (413, 9 parts). Reply 11: vehicle packs (49). Replies 12 and 13: Not needed (49).
- Reply 14: Does not work with ZeD (3), then Broken on 42.21 or 42.22 by themselves (11).

`post00_first` replaces the first post, `post01` to `post14` replace replies 1 to 14; nothing added or deleted.

## Build

`build/gen7.py` is gen6 with the new order (it reads `../compat_v5/build/v5_mods.json`). `build/check7.py` is check6
with the new order checked, and the words compared line for line with v6 (the index lines and reply numbers aside).
Run both with `py -3 -I`; check7 ends `RESULT: PASS`. When v5's data changes: gen5/check5, gen6/check6, gen7/check7.

Posted Nov 2 2026 (QA, through the Steam client): the first post and replies 1 to 14 edited in place, each checked by its
first line after the paste. Nothing added or deleted; the thread still shows 14 replies.
