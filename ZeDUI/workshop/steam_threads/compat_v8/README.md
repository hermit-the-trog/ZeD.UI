# Compatibility thread, version 8 (Nov 8 2026): the Mac retest

v7's posts plus the changes in `../compat_v8_mac_retest.md`, nothing else: the Mac retest line under each heading, the mark
(✔, 🚗✔ or "not retested") on each mod line, and the new Mac notes. Minimal Sidebar is not touched (it waits for beta 9).
`post00_first` replaces the first post, `post01` to `post14` replace replies 1 to 14.

## Size

Steam's limit is about 8,000 characters per post, counted on the body (the TITLE line left out, a newline as one character, in UTF-16 units as check7 does).
The full retest paragraph would push most replies over, so a reply uses the short retest line when the full one makes it go
over 8,000. Post 00 keeps the full paragraph.

| Post | Retest line | Characters |
|---|---|---|
| 00 first | full | 8,310 (over) |
| 01 | full | 6,320 |
| 02 | full | 6,706 |
| 03 | short | 8,190 (over) |
| 04 | short | 7,931 |
| 05 | full | 7,499 |
| 06 | short | 7,695 |
| 07 | short | 7,918 |
| 08 | full | 7,975 |
| 09 | full | 7,985 |
| 10 | short | 7,730 |
| 11 | full | 7,630 |
| 12 | short | 7,995 |
| 13 | full | 7,966 |
| 14 | full | 5,468 |

Posts 00 and 03 are over the limit, so they were not posted; they need trimming that does not cut a mod or a note.

## Posting

See the Posting status section below, written when the edits were made through the Steam client.
