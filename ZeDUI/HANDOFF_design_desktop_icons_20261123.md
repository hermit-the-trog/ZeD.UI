# Handoff: Design to Build, the desktop's Mail and Mod Uploader icons (Nov 23 2026)

Nothing in 42/ was touched, and nothing is committed: Build installs, commits and runs the checks. The two new
icons and the tool's diff are staged in `ZeDUI/art/desktop_icons_20261123/`, with two previews. The changed icon tool is
installed in `ZeDUI/tools/mainmenu/`.

**Made against main at `c11a7d341`, Nov 23 16:30.** The icon tool and the icons last changed in `c5a02743d`
(Pasties). The tool is installed in place, main's own copy with this handoff's changes, in main's working-tree line
endings (CRLF). If `git log c11a7d341..HEAD -- ZeDUI/tools/mainmenu/bake_desktop_icons.py` lists nothing, the
installed one stands. If it lists a commit, apply `tools/bake_desktop_icons.py.diff` to main's copy instead, with
`git apply --ignore-whitespace`.

## The director's calls

The notes, verbatim:

> (15:55) The desktop icons for upload mod and protopop3 email, the signal indicator on those icons cannot be read on
> the desktop or any dark surface. The email icon should just be an icon of a mailbox with a red flag up. And can mod
> upload be a satellite dish beaming a signal

> (16:12) Mailbox looks a little too much like an upside down taco. And the satellite just needs a fidelity pass.

> (16:54) Everything looks great. [...]

16:54 passed `preview/mail_uploader_as_passed.png`: each icon now and redrawn, on the desktop, a dark window and a
light one, at the desktop's 2x and at 4x.

## What the player sees

On the ZeD OS desktop:

- **ProtoPOP3 Mail is a rural mailbox, its red flag up,** in three-quarter view so its own shape shows.
  - The arched door faces you at the left, with its latch.
  - The round roof and the flat side go back to the round back.
  - The red flag stands up on the near side.
  - The box sits on a wooden post.

  It has no waves of its own, so there is nothing dark to lose on a dark ground.
- **The Mod Uploader is a satellite dish beaming.**
  - You see into the bowl: dark under its lit upper-left lip, lighter low at the right.
  - The feed horn sits on an arm out of its middle.
  - Three waves go out of the horn, white with a black edge, so they read on the desktop, a dark window and a light
    one.
  - The dish stands on a bracket, a pole and a foot.
- **The other twelve icons are unchanged.** The tool bakes them pixel for pixel as main has them.
- **Same names, same size:** `mail.png` and `uploader.png`, 32 x 32. The desktop draws them at a whole multiple (2 at
  4K) with nearest filtering, as before.

`preview/all_icons_now_and_staged.png` shows all fourteen icons, now and staged, on the three grounds.

## Build's work

1. **Install the art:**

       Copy-Item ZeDUI\art\desktop_icons_20261123\42\media\textures\ZeD\mainmenu\icons\*.png 42\media\textures\ZeD\mainmenu\icons\ -Force

   That is two PNGs, `mail.png` and `uploader.png`.

2. **The tool, `ZeDUI/tools/mainmenu/bake_desktop_icons.py`,** installed. Its diff is in the stage's `tools/`.
   - The docstring's list names the new pictures.
   - `GRID` (a letter for each color) and `from_grid()` make an icon from 32 rows of 32 letters.
   - `MAILBOX` and `DISH` are the two drawings, each with a note on what it shows and the calls behind it.
     `icon_mail()` and `icon_uploader()` draw them.
   - The old envelope and its waves are gone, and so are the old folder, its up arrow (`up_arrow`, `GN`, `GND`) and
     its waves. Nothing else used them.

3. **Run the checks.**
   - **Bake to a scratch folder and compare,** or bake in place and check `git status`:

         py ZeDUI\tools\mainmenu\bake_desktop_icons.py

     Only `mail.png` and `uploader.png` should change. Design baked all fourteen here: the other twelve match main's
     pixel for pixel. The bytes may differ with the Pillow version (this bake used Pillow 12.3.0), so if `git status`
     shows the other twelve as changed, check them with `git diff --stat` or restore them.
   - **QA's sims** name the icons by id (`desk_sim`, `mail_sim`, `code_flags_sim`, `respawn_sim`, `bx_menu`). None
     reads the pictures, so nothing there changes. `desk_sim` on main today: 199 checks, 0 failed.

## QA

At 4K with UI scale 1.75 and on the Steam Deck (1x):

- [ ] The Mail icon is a mailbox with its red flag up. It reads as a mailbox, not a taco.
- [ ] The Mod Uploader icon is a satellite dish with white waves. The waves read on the desktop, on a dark window
      behind them and on a light one.
- [ ] Both open their windows as before, by mouse and by pad, and their labels sit under them as before.
- [ ] The pixels stay square: the icons are 64 px at 4K.
- [ ] The other twelve icons look as they did.

## Files

| What | Where |
|---|---|
| The two icons | `ZeDUI/art/desktop_icons_20261123/42/media/textures/ZeD/mainmenu/icons/` |
| The tool's diff | `ZeDUI/art/desktop_icons_20261123/tools/bake_desktop_icons.py.diff` |
| The sheet as passed; all fourteen now and staged | `ZeDUI/art/desktop_icons_20261123/preview/` |
| Script | `ZeDUI/tools/mainmenu/bake_desktop_icons.py` (changed) |

To regenerate (change the drawing in the script, never the picture):

    py ZeDUI\tools\mainmenu\bake_desktop_icons.py
