# Compatibility thread, version 5 (Nov 2 2026)

Workshop item 3824968485, thread "Compatibility with other mods" (id 574930338697167513).
Version 4 (`../compat_v4`, 512 mods) plus compatibility round 4 (`../../compat_round4_candidates.md`, the three
results sections, Oct 29 and Nov 2 2026) and the support added in ZeD-GUI 0.2.0-t11 and 0.2.0-t15. 550 mods in all.

## Reply map

`post00_first.txt` replaces the first post (its title line is not part of the post). Posts 01 to 13 replace
replies 1 to 13 in place. **Reply 14, the round 4 post of Oct 29, stays as it is**: do not delete it (deleting it
would move every later reply up one and break the index). The first post's index names it as the Oct 29 notes,
with the lists current where the two differ. Posts 15 and 16 are new replies, posted in that order after reply 14.

| File | Reply | What it holds | Mods |
|---|---|---|---|
| post00_first | first post (replaces) | What the thread is, where each list is, how mods were tested (new lines for Oct 29 and Nov 2), the t7 fixes, help for long mod lists (t15 load order), how to add a mod | |
| post01 | reply 1 (replaces) | Supported | 20 |
| post02 | reply 2 (replaces) | Works well with ZeD | 13 |
| post03 to post11 | replies 3 to 11 (replace) | Compatible, 9 parts: 0-9 to Be, Be to C, D to F, G to K, L to M, N to P, Q to Sm, Sm to Tr, Tr to Z | 408 |
| post12 | reply 12 (replaces) | Compatible, vehicle packs | 49 |
| post13 | reply 13 (replaces) | Does not work: with ZeD (3), and broken on 42.21 or 42.22 by themselves (11) | 14 |
| (none) | reply 14 (stays) | Round 4 notes of Oct 29, as posted | |
| post15 | new reply 15, after 14 | Not needed with ZeD, part 1, with the donations paragraph and makers' credits | 23 |
| post16 | new reply 16, after 15 | Not needed with ZeD, part 2 | 23 |

Counts per list: Supported 20, Works well 13, Compatible 408, vehicle packs 49, Not needed 46, Does not work
with ZeD 3, broken by themselves 11. Total 550 (512 from v4, 38 new).

## What changed since v4

- Supported grows from 11 to 20: the seven of round 4 (Easy Drop'n'Loot, Moodle Quarters, Exp Recovery for Skill Books, Nested Containers, Evolving Traits World, Container Capacity Indicator, Wound Expansion), Immersive Searching (new, 0.2.0-t15) and [B42]Mod Folders (from Not needed, 0.2.0-t15, credit to FieClaussell).
- 38 mods added: 31 Compatible (among them the clothing dataset This Is Your Life needs), 3 Not needed (Mod Load Order Sorter Extension, Disable Welcome Message, More Simple Context Menu Icons), 3 Does not work with ZeD (Xen's Enhanced GUI; This Is Your Life and its Character Creator Overhaul), and Immersive Searching as Supported.
- Does not work is two lists now: it no longer says no mod clashes with ZeD-GUI.
- The Not needed reasons for Mod Load Order Sorter, [B42] Mod Manager and Mod Load Order Sorter Extension name t15's load order: Find, Load first / Load last, Load after... / Load before..., separators, folders.
- Supported is reply 1 alone and Works well is reply 2; Compatible needs a ninth part; Not needed moves to replies 15 and 16, after reply 14.
- Three notes lose a file name (Better Clothing Info Comparison, Voiced Radio and TVs, and the mod with the old translation format).

## Build

`build/gen5.py` reads `../compat_v4/build/v4_mods.json` and `build/r4notes.py` (round 4 and t15 notes, list
changes), writes the posts here and `build/v5_mods.json` / `build/v5_layout.json`. `build/check5.py` checks
every v4 and round 4 mod appears exactly once, under the list its data says, each list in alphabetical order across
its parts, each post under 7,800 characters, the first post's index and counts match the files, and no banned
text (middle dot, "open source", "Accessible", file names, test words, exclamation marks in our own words).
Run both with `py -3 -I` from anywhere; check5 ends `RESULT: PASS`.

Before posting: the support rows for Immersive Searching and Mod Folders say "From ZeD-GUI 0.2.0-t15"; post
once t15 is live on the Workshop. Mod Folders' Workshop page names FieClaussell, its mod info names Paltia; the
thread uses FieClaussell, as the t15 change note does.
