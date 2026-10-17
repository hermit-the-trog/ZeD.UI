# Brief for Design: the fishing rod and the clock radio plates

Director, Oct 16 2026: the final art for both props comes from the plate pipeline (physpx / dashpx style). The game side is built and verified with stand-in art exported from the approved mockup (`zed_fish_sleep_death_v5.html`, scenes "Fishing" and "Sleep"). Replace the stand-in PNGs with the pipeline's own, keeping the sizes and anchors below, and both props pick them up with no code change. If an anchor moves, send the new numbers (or the table) and the code follows.

## The rod in hand (`Overrides/Fishing.lua`, HOOK_MAP row 10)

Shown while the line is out, at the bottom of the screen above the belt, at 2 screen pixels per plate pixel at 1080p (4 at 4K).

- **What it is:** a 1980s pistol-grip baitcasting rod, as in the director's photo of their own tackle (Daiwa Magforce / PT33P reels on All Star rods): cork rear grip, pistol trigger under a black seat, cork fore grip, a brown graphite blank with chrome guides on top, a low-profile black baitcaster with two paddle handles and a star drag. Parody brand: DAIZO. The reel's side plate has the round dial: a chrome rim, black face, cream ticks from 0 round to MAX, the last three ticks red, "MAX" printed in red.
- **Plate:** 360 x 200 plate pixels, transparent background, the butt at the bottom left, the line leaving the plate at its bottom right edge (359, 197).
- **17 frames by tension**, `media/textures/ZeD/props/rod_00.png` .. `rod_16.png`: frame i is tension i / 16 (0 = no load; frame 0 is also slack). Per frame:
  - the blank's bend: none at 0, a deep bow at 16 (mostly in the top half of the blank);
  - the **eight thread wraps** (two above the fore grip, one at each guide) are a meter: all white at 0, then lit one by one from the reel toward the tip, `ceil(i / 2)` of them: wraps 1-4 gold, 5-6 orange, 7-8 red. All lit is the limit.
  - **not** drawn on the frames: the line, the dial's pointer and hub (drawn live).
- **Anchors per frame** (plate pixels; the current table is `F.ANCH` in `Overrides/Fishing.lua`): `tip` (the tip top), `start` (where the line leaves the reel), `guides` (the six guide rings, the line runs through each), `dial` (centre x, y and radius of the dial face), `max` (x, y, w, h of the MAX printing, lit near the limit).
- **Live, drawn by the code:** the line (reel to each guide to the tip, then off to the water: a sag when slack, straight under load, pale red at 0.9 and up), the dial's red pointer (from 0 at -135 degrees round to the red at +135), the chrome hub, a red glow over MAX at 0.85 and up.
- **Still to come:** a crafted rod (a stick, twine, a wooden reel) without the dial, for when that rod is in hand: the bend and the wraps only (the director: show all three reads where the rod has them).

## The clock radio (`Overrides/Sleeping.lua`, HOOK_MAP row 16)

Shown in the middle of the dark while the character sleeps, at 3 screen pixels per plate pixel at 1080p (6 at 4K).

- **What it is:** a woodgrain-topped clock radio with a chrome bezel and smoked glass (the director's reference: a GE woodgrain clock radio). Parody brand: GENERIC ELECTRIC with a "GE" roundel; the AM / FM dial on the right with its red needle.
- **Plate:** `media/textures/ZeD/props/clock_radio.png`, 330 x 84 plate pixels, transparent background, every segment drawn **dark** (unlit) and the AM / PM dots, colon and ALARM lamp unlit.
- **Live, drawn by the code** (plate pixels): four seven-segment digits with their top left at x = 36 + (0, 22, 52, 74), y = 26, each 16 x 34 with a 3-pixel stroke (the leading hour digit blank below 10); the colon at (80, 35) and (80, 48), 3 x 3; the AM dot at (25, 29) and the PM dot at (25, 54), 3 x 3; the ALARM lamp at (132, 54), 3 x 3. Lit red #ff3322 with a #5a120c glow one pixel round.
