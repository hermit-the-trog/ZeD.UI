# QA b12 release pass (Nov 13 2026)

Candidate: main at 9024e32b7 (HEAD contained it; the lock read free at the start). Everything ran with -debug -nosteam on the ZeD-QA save at 4K fullscreen (UI scale 1.75x) unless said otherwise. Pictures: Zomboid/Screenshots/b12_release_20261113/<part> (outside the repo).

## Part 1. The smoke run (release_check.ps1 -Manifest smoke.txt, 4K)

Ran once. Report: ZeDUI/qa/regression/2026-11-13_b12rel_smoke.md. Result: 12 of 12 pass, 0 warn, 0 fail. The release check's own line: `ZEDQA rel RESULT PASS: all 16 checks` (windows open, floor transfer there and back, pad A and B, the real right-click, the watch time).
- Car lines (one car in this run): `ZEDQA car dpx Base.CarNormal spawned on spot 11 (917,13030)`. Spot 11 passed.
- navmap, strict: `ZEDQA nav 14 tabs audited: 0 traps, 0 islands (strict: each one is a failing line)`. No FAIL line.
List A: none. List B: none. Not run: none.
