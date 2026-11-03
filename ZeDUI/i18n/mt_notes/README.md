# Notes for native checkers of ZeD-GUI's machine drafts (punch list 62)

Every language here was drafted by a Sonnet model from the English with each phrase's place and length limit
(ZeDUI/i18n/UI_ZeD.context.md) and the game's own interface words for that language (mt.py glossary). `<LANG>.txt` is
the drafter's own list of doubtful choices, the first things to read. ES_MX, AR, ES_CL were made from the Spain
draft (only the lines that differ), PT from PTBR, CH from the English with CN as a guide.

JP, KO, TH, CH, RU and UA had a second pass by a Fable model (the director, Nov 3 2026) that changed only lines it
found wrong; what it left for a native checker is at the end of those files. `_BRIEF.md` and `_PROOF.md` are the
instructions both passes worked from. Tools: ZeDUI/tools/i18n/mt.py (pack, glossary, unpack, check, merge).
