# Handoff: main menu desk v5, the joystick ports and the KI pad (Nov 2 2026), ready to install

Director approved ("Desk is approved"), Cowork design session. Staged, not installed: nothing under 42/ has changed.

## What's new on the desk
- **Joystick ports** on the computer case's front, between the vents and the 5.25" drive: two 9-pin ports, 1 and 2
  printed over them. Port 2 is empty, its 5-over-4 pins showing. Port 1 has the pad's plug pushed straight in (beige
  like the pad, ridged grips, two thumbscrews); the cable comes out of the plug's back through a round strain-relief
  boot and sags down off the bottom of the picture (director: "you push forward to plug in. So the cord hangs out,
  not down").
- **The Kentucky Instruments pad** (the controller map's pad) lying flat on the desk at the bottom right, in front of
  the game boxes: beige like the computer, about as thick as a Super NES pad (director), the D-pad, both sticks, VIEW
  and MENU, Y X B A in their colours, the shoulders at the back edge, edges rounded (director: "a little softer").
  Seen from a little above the room's eye line so it reads; its right end runs a few pixels off the picture; it
  covers the bottom of the three boxes (the book and its PEARS chip stay clear).
- The story (director): it is Hermit's desk, where ZeD-GUI got written; every prop is there because he asked for it.

## Files (uncommitted)
- `ZeDUI/tools/mainmenu/gen_desk.py`: JOYSTICK PORTS and THE KENTUCKY INSTRUMENTS PAD at the end of
  `build_objects()`; four new materials `pad_y / pad_x / pad_b / pad_a` (the buttons) in their own palette group
  `FRESH_PAD` (12 entries), like the can's and the book's, so no other object's pixels change.
- `ZeDUI/art/main_menu/v5/`: desk.png, desk_lampdim.png, lamp_dim.png, dial_clean.png, desk_info.json (ungraded),
  byte-identical to the render the director approved.
- `ZeDUI/tools/menugrade/grade.py`: reads v5 now (was v4).
- `ZeDUI/tools/mainmenu/previews/main_menu_v5_4x.png` (graded, as the game shows it at 1080p) and
  `pad_v5_10x_brightened.png` (the pad up close).

## Install (no code change)
The contract is unchanged: the tube, both blinking lights, the dial and needle, the power button, the lamp box and
the desk edge row are where they were, and desk_info.json's colours are v4's (the margins measured the same).
1. `cd ZeDUI/tools/menugrade` and `py grade.py none 1.0`: grades v5 into `42/media/textures/ZeD/mainmenu/`.
2. `git status -- 42/media/textures/ZeD/mainmenu`: only desk.png and desk_lampdim.png should change (lamp_dim.png
   and dial_clean.png are cut from areas the pad doesn't touch; if they show as changed, compare the pixels).
3. Commit the files above with the two textures.

## QA
- The main menu at 1920x1080: the ports and the pad as in the preview; the hard disk and floppy lights still blink in
  place; the lamp flicker (desk_lampdim) shows the pad too.
- Small screens (1280x800 and 720, Normal and Large): the lean-in may crop the pad at the bottom right; note how
  much shows. Ultrawide: the pad's cut right end meets the right margin colour.
- Retake the main menu captures used by the gallery when convenient.
