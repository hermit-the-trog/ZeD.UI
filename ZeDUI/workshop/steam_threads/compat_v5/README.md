# Compatibility thread, version 5 (Nov 2 2026)

Workshop item 3824968485, thread "Compatibility with other mods" (id 574930338697167513).
Version 4 (`../compat_v4`, 512 mods) plus compatibility round 4 (`../../compat_round4_candidates.md`, the three
results sections, Oct 29 and Nov 2 2026), round 5 (the same file, "Round 5", Nov 2 2026: nine trending Build 42 mods)
and the support added in ZeD-GUI 0.2.0-t11 and 0.2.0-t15. 559 mods in all.

## Reply map

Every post is an edit in place: nothing is added to the thread or deleted from it. `post00_first.txt` replaces the
first post (its title line is not part of the post); posts 01 to 14 replace replies 1 to 14. Reply 14, the round 4
notes of Oct 29, becomes Not needed part 2 (those notes are folded into the lists). The Does not work lists move
into the first post, under its index, and the first post loses the old "fixed for 0.2.0-t7" section.

| File | Reply | What it holds | Mods |
|---|---|---|---|
| post00_first | first post | What the thread is, the index, Does not work (with ZeD 3, broken by themselves 11), how mods were tested, help for long mod lists, how to add a mod | 14 |
| post01 | reply 1 | Supported | 20 |
| post02 | reply 2 | Works well with ZeD | 13 |
| post03 to post11 | replies 3 to 11 | Compatible, 9 parts: 0-9 to Be, Be to C, D to F, G to K, L to M, N to P, Q to Sm, Sm to Tr, Tr to Z | 414 |
| post12 | reply 12 | Compatible, vehicle packs | 49 |
| post13 | reply 13 | Not needed with ZeD, part 1 of 2, with the donations paragraph and makers' credits | 25 |
| post14 | reply 14 | Not needed with ZeD, part 2 of 2 | 24 |

Counts per list: Supported 20, Works well 13, Compatible 414, vehicle packs 49, Not needed 49, Does not work
with ZeD 3, broken by themselves 11. Total 559 (512 from v4, 38 from round 4 and t15, 9 from round 5).

## What changed since v4

- Supported grows from 11 to 20: the seven of round 4 (Easy Drop'n'Loot, Moodle Quarters, Exp Recovery for Skill Books, Nested Containers, Evolving Traits World, Container Capacity Indicator, Wound Expansion), Immersive Searching (new, 0.2.0-t15) and [B42]Mod Folders (from Not needed, 0.2.0-t15, credit to FieClaussell).
- 38 mods added: 31 Compatible (among them the clothing dataset This Is Your Life needs), 3 Not needed (Mod Load Order Sorter Extension, Disable Welcome Message, More Simple Context Menu Icons), 3 Does not work with ZeD (Xen's Enhanced GUI; This Is Your Life and its Character Creator Overhaul), and Immersive Searching as Supported.
- Round 5 adds 9: 6 Compatible (Immersive Moodles, noted: each moodle shows twice; Light Belt; Bag Check; Hands-On Interactions; Cheat Menu 2.0 - Rax's Reborn, with its own error; Immersive Sleep) and 3 Not needed (Better Context Menu Icons; Paravel's Enhanced Inventory and Paravel's UI).
- Does not work is two lists now: it no longer says no mod clashes with ZeD-GUI.
- The Not needed reasons for Mod Load Order Sorter, [B42] Mod Manager and Mod Load Order Sorter Extension name t15's load order: Find, Load first / Load last, Load after... / Load before..., separators, folders.
- Supported is reply 1 alone and Works well is reply 2; Compatible needs a ninth part; Not needed moves to replies 15 to 17, after reply 14.
- Three notes lose a file name (Better Clothing Info Comparison, Voiced Radio and TVs, and the mod with the old translation format).

## Build

`build/gen5.py` reads `../compat_v4/build/v4_mods.json` and `build/r4notes.py` (round 4, round 5 and t15 notes,
list changes), writes the posts here and `build/v5_mods.json` / `build/v5_layout.json`. `build/check5.py` checks
every v4, round 4 and round 5 mod appears exactly once, under the list its data says, each list in alphabetical order across
its parts, each post under 7,800 characters, the first post's index and counts match the files, and no banned
text (middle dot, "open source", "Accessible", file names, test words, exclamation marks in our own words).
Run both with `py -3 -I` from anywhere; check5 ends `RESULT: PASS`.

Before posting: the support rows for Immersive Searching and Mod Folders say "From ZeD-GUI 0.2.0-t15"; post
once t15 is live on the Workshop. Mod Folders' Workshop page names FieClaussell, its mod info names Paltia; the
thread uses FieClaussell, as the t15 change note does.
