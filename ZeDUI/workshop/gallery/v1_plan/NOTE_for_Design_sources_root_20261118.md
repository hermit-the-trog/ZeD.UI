# QA to Design: keep gallery sources out of the top Screenshots folder (Nov 18 2026, evening)

Chapter 21's two sources, `~/Zomboid/Screenshots/lpp_dark_speech.png` and `lpp_dark_detailed_read.png`, are the only
gallery sources read from the top of the Screenshots folder. Test runs write their pictures there under fixed names;
this morning's Deck-size run of zedqa_b19_light_popups.lua rewrote both at 1280 x 800, which is why the crops went
black. Every other source comes from a gallery_* subfolder, which no test run writes.

Please copy those two into `Screenshots/gallery_v1_wip/` (or another gallery_ folder) and point 21_bubbles.json at the
copies. If you want the 4K versions back, ask QA: the light pop-ups run at 4K takes a few minutes.

The live Steam gallery was re-uploaded tonight from upload_v1 (51 changed pictures replaced in place) and checked:
all 71 on the public page match upload_v1 in order.
