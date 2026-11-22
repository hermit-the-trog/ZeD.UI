# Handoff: Design to Build, ZeD OS desktops (Nov 22 2026)

Nothing in 42/ was touched. The art is staged in `ZeDUI/art/desktops_20261122/`. The script that draws it is
`ZeDUI/tools/desktops/desktops.py`, with its check, `check_reference.py`, beside it. Nothing is committed: Build
installs, commits and runs the checks.

The board is the "ZeD Desktops" design canvas (https://claude.ai/artifact/Ac1jAfwEUY53ahdGNeW6Un). It has every
option, the color rule, the desk at 1080p, and a working picker: click its swatches, and use its Tweaks to set the
color and the window theme.

## The director's calls

The ask, verbatim (Nov 21, 19:20):

> I would like to create or have some options available other than the two desktop backgrounds, both the Game Art
> desktops. If we could do, I want to say they had like patterns and colors for desktops in '93. Something on brand.
> Some simple options to create less noise. And some other just fun ones.

Nov 22, 11:05:

> The desktop backgrounds, they need to be the same for dark or light mode. So somewhere in the middle of bright and
> dark.

Nov 22, 11:50:

> What if the background color before the pattern overlay was what they select for their container highlight color?
> That lets them have control over that color, and it also matches. It just eliminates creating an extra color picker
> option. And then for patterns, we're missing camo, obviously. And there needs to be a American flag or USA
> background option. Also a Commonwealth of Kentucky background option. Stars can go back to being a very dark
> midnight navy blue. Maybe a pattern similar to the jazz cups.

Nov 22, 12:21, on the Kentucky seal:

> The Kentucky flag looks like Rock'em Sock'em Robots, and it looks like the guy on the left is punching the guy on
> the right's head off. Instead, their hands are supposed to be down at their waist shaking. Two hands shaking two
> hands.

What came of them:

- **One desktop for every theme.** Every desktop sits in the middle tones, so a Dark window and a Light one both
  stand off it. Dark, Light and High contrast change only the windows. Stars is the one dark desktop, by his call.
- **The player's color, no new setting.** A pattern's ground is the game's own **Color of Highlighted Container**
  (options.ini `objHighlightColor`; Options, Highlights in ZeD), brought to the middle tone. The pattern is a
  see-through overlay laid over it.
- **New:** Camo, Squiggle, USA and Kentucky.
  - Squiggle answers "similar to the jazz cups". It is an original early-90s brush-and-squiggle pattern, not Solo's
    Jazz design, so it can ship.
- **Kentucky** follows the state flag (KRS 2.030) and seal (KRS 2.020), except the handshake: both men's hands are
  down at the waist, all four clasped.

## 1. What the player sees

### The Settings menu

The two wallpaper rows at the foot of Settings (Original wallpaper, New wallpaper) become one row, **Desktop...**,
which opens the Desktop window.

### The Desktop window

- **The window.** A ZeD window titled Desktop, 660 units wide, opening where ZeD opens a new window. On the board it
  sits at x 150, y 44 of a 960 x 720 tube at UI scale 1.
- **Four groups.** Each is a heading (F1 chrome, text-sec) over a grid of 8 columns:
  - Game art: 2 swatches.
  - Patterns: 10, in two rows.
  - Quiet: 5.
  - Fun: 8.
- **A swatch** is 64 x 48 units in a 1-hair `border-s` frame, with the option's name under it (F2, text). It shows the
  desktop itself at its own dot size, through `D.drawChip`:
  - **Patterns:** in the player's color.
  - **USA and Kentucky:** a small copy of the flag.
  - **Painting and Title video:** the game's own picture. The painting comes from its own tiles, as
    `MM.drawWallpaper` draws it. The video shows its frame, or the painting when video effects are off.
- **The desktop in use** has its swatch ringed in the accent (2 hairs, 1 hair out) and its name in accent-text.
  Hover gives the accent-hover wash.
- **Picking a swatch** sets the desktop at once and keeps it, as the wallpaper rows do now. There is no Apply.
- **The help band** shows "Name: note" (section 7) for the swatch under the pointer or the controller's focus. With
  neither, it shows the desktop in use.
- **The foot band:**
  - On the left: "Patterns take your Color of Highlighted Container from Options." The color's name is the game's own
    string, so it matches the Options label in every language.
  - On the right: **Done**, the default keycap, which closes the window.
- **Controller:**
  - The D-pad walks the swatches (left and right along a row; up and down between rows and groups) and on to Done.
  - A sets the focused swatch; B closes the window.
  - The focus mark is the player's Controller highlight (the pointing hand by default).
  - Nothing is bound to L3 or R3.

### The options

| Group | Id | Name | Kind |
|---|---|---|---|
| Game art | `painting` | Painting | the game's old title painting, as now |
| | `video` | Title video | Build 42's title video, as now |
| Patterns | `classic` | Classic | overlay on your color |
| | `weave` | Weave | overlay |
| | `bricks` | Bricks | overlay |
| | `diagonal` | Diagonal | overlay |
| | `grid` | Graph | overlay |
| | `dots` | Dots | overlay |
| | `zeds` | Zeds | overlay |
| | `disks` | Disks | overlay |
| | `camo` | Camo | overlay, three depths |
| | `squiggle` | Squiggle | overlay: light dabs, dark squiggles |
| Quiet | `solid` | Solid | your color, flat |
| | `accent` | Accent | the theme's accent, flat |
| | `slate` | Slate | #5B6474, flat |
| | `fine` | Fine | overlay, faint |
| | `pinstripe` | Pinstripe | overlay, faint |
| Fun | `topo` | Topo | art tile |
| | `carpet` | Carpet | art tile |
| | `paneling` | Paneling | art tile |
| | `flannel` | Flannel | art tile |
| | `stars` | Stars | art tile (midnight navy) |
| | `tally` | Tally | art tile |
| | `usa` | USA | picture, fills the tube |
| | `kentucky` | Kentucky | picture, fills the tube |

**Every theme draws the same desktop.** Nothing in a desktop reads the base theme, High contrast or a colorblind
mode. Accent takes the accent's Dark value whatever the theme.

## 2. The color

- **Read it** with `getCore():getObjectHighlitedColor()`: a ColorInfo, read with `getR()`, `getG()`, `getB()` (0..1).
  The game's default is 0.98, 0.56, 0.11, an orange.
- **Bring it to the middle tone** with `D.tone`:
  - It works in OKLab, whose lightness looks even across hues.
  - The hue is kept, and the lightness set to the middle grey's (#6B6760, L 0.5152).
  - The strength is held to 0.09, about Windows 95's teal. Where the screen can't show that hue that strong at that
    lightness, a bisection lowers it until it fits.
- **Examples:**

| Picked | Comes out as |
|---|---|
| The default orange, #FA8F1C | #8D5A2E, a rust |
| Green, 0.25 0.80 0.25 | #477544 |
| Blue, 0.25 0.50 1.00 | #4B679B |
| White | #676767, grey |
| Accent, PZ Teal (Dark value #47A18C) | #187865 |

- **Options can change the color in play**, so it is read every frame (one call) and compared. `D.ground` re-tones it
  only when it changes, and `D.accentGround` does the same for the accent.

## 3. How a desktop draws

Everything draws into the tube, `L.tx, L.ty, L.tw, L.th`, in this order:

1. **The ground.** `drawRect` over the tube:
   - patterns, Solid, Fine and Pinstripe: the toned container color;
   - Accent: the toned accent;
   - Slate: #5B6474.
2. **The overlay or art tile**, tiled from the tube's top left corner at the dot zoom and clipped with
   `setStencilRect`.
   - The dot zoom is the desktop icons' own whole zoom (`ZeD_MainMenuDesktop.lua`):
     `max(1, floor(T.scale + 0.5))`. That is 1 at 1080p and 2 at 4K with UI scale 1.75, so a pattern's dot is an
     icon's pixel.
   - The blending is plain alpha: an overlay's black dots darken the ground by their alpha (0.10 to 0.64), and
     Squiggle's white dabs lighten it (0.20).
3. **The pictures** (USA, Kentucky): the 960 x 720 picture drawn to fill the tube. Both are 4:3.
4. **No dimming** on the new desktops: they are made at the middle tone. Painting and Title video keep
   `WALL_DIM` 0.55, exactly as now.
5. **The glass**, `MM.drawGlass`, over everything, as now.

Notes:

- **Filtering.** Textures load nearest, `Texture.getSharedTexture(path, 3)`, as `ZeD_MainMenu.lua`'s `tex()` loads
  the desk. The exceptions are the flags' `chip_*.png`, which load smooth.
- **Draws.** The textures come repeated to about 128 dots a side. A tube takes about 50 draws at 1080p or at 4K
  with UI scale 1.75, and about 180 at 4K with UI scale 1.
- **Both callers of `MM.drawWallpaper`** get the new desktops: the main menu's prerender (`ZeD_MainMenu.lua`) and
  the left screen's (`ZeD_LeftScreen.lua`, `ZeD_LeftDesk:prerender`).

## 4. The choice

- `Zomboid/Lua/ZeD_wallpaper.txt` keeps one line: the option's id.
- The old words still read (`D.idOf`): "original" opens on the painting, "new" on the title video. Anything else, or
  no file, gives the painting.
- **The default stays the Painting**, as now.

## 5. The stage

`ZeDUI/art/desktops_20261122/`:

- **`42/media/textures/ZeD/mainmenu/desktops/`**, 22 PNGs (140 KB):
  - `ov_*.png` (12): the overlays. RGBA, black (or white) dots with alpha, 120 to 128 dots a side.
  - `art_*.png` (6): the Fun tiles, opaque.
  - `pic_usa.png`, `pic_kentucky.png`: 960 x 720, opaque.
  - `chip_usa.png`, `chip_kentucky.png`: 128 x 96, the flags small, for the swatches.
- **`_desktops.lua.txt`**, the reference module:
  - the options: `D.GROUPS`, `D.OPT`, `D.nameKey`, `D.noteKey`;
  - the choice: `D.idOf`;
  - the color: `D.tone`, `D.ground`, `D.accentGround`;
  - the drawing: `D.zoom`, `D.draw`, `D.drawChip`.
- **`preview/`**:
  - `all_options.png`: each desktop by the icons at 4K;
  - `follows_the_color.png`: three patterns over four picks;
  - `on_the_desk_1080p.png`: four desktops across the whole room;
  - `kentucky_handshake_4x.png`: the seal's men, close up.

## 6. Build's work

1. **Install the art:**

       Copy-Item ZeDUI\art\desktops_20261122\42\media\textures\ZeD\mainmenu\desktops 42\media\textures\ZeD\mainmenu\ -Recurse -Force

2. **Add the module.** Make the reference into a file that `ZeD_MainMenu.lua` requires, for example
   `ZeD_MainMenuDesktops.lua`, or fold it into `ZeD_MainMenu.lua`.
3. **The choice.** `MM.wallpaper()` and `MM.setWallpaper(which)` (lines 533–553) become `MM.desktop()` and
   `MM.setDesktop(id)`. The read goes through `D.idOf`, and the file keeps the id.
4. **`MM.drawWallpaper(p, L, t)`** (line 585):
   - `"video"`: today's "new" branch, unchanged, falling back to the painting as now.
   - `"painting"`: today's painting branch, unchanged.
   - Anything else: `D.draw(p, id, L.tx, L.ty, L.tw, L.th)` and return, with no `WALL_DIM`.
5. **The Settings menu** (`MM.menuItems`, `"settings"`, lines 1109–1112): replace the two wallpaper rows with one,
   `{ text = ZeD.tr("UI_ZeD_MainMenu_Desktop"), fn = <open the Desktop window> }`, after the same separator.
6. **The Desktop window** (section 1). Build it from ZeD's own window, buttons, help band and Controller highlight.
   The swatches draw through `D.drawChip`, and the two game-art swatches draw the game's own picture.
7. **The strings** (section 7):
   - Add them to EN `UI.json`, and the other languages as Build does them.
   - Retire `UI_ZeD_MainMenu_WallpaperOriginal` and `UI_ZeD_MainMenu_WallpaperNew`.
8. **Optional: re-run Design's check** where lupa, numpy and Pillow are installed:

       python ZeDUI\tools\desktops\check_reference.py ZeDUI\art\desktops_20261122 ZeDUI\tools\desktops\desktops.py

   It checks the reference against the art, not the game.

## 7. Strings (EN)

| Key | Text |
|---|---|
| `UI_ZeD_MainMenu_Desktop` | Desktop... |
| `UI_ZeD_Desktop_Title` | Desktop |
| `UI_ZeD_Desktop_GroupGameArt` | Game art |
| `UI_ZeD_Desktop_GroupPatterns` | Patterns |
| `UI_ZeD_Desktop_GroupQuiet` | Quiet |
| `UI_ZeD_Desktop_GroupFun` | Fun |
| `UI_ZeD_Desktop_Help` | %1: %2 |
| `UI_ZeD_Desktop_Foot` | Patterns take your %1 from Options. |
| `UI_ZeD_Desktop_Done` | Done |

- In `UI_ZeD_Desktop_Help`, `%1` is the name and `%2` the note.
- In `UI_ZeD_Desktop_Foot`, `%1` is `getText("UI_optionscreen_objHighlightColor")`, the game's own "Color of
  Highlighted Container".

Each option's name is `D.nameKey(id)` and its note `D.noteKey(id)`: for example `UI_ZeD_Desktop_Classic` and
`UI_ZeD_Desktop_Classic_Note`. A note follows the name after a colon, so it starts lowercase unless it starts with a
name.

| Id | Name | Note |
|---|---|---|
| `painting` | Painting | the game's old title painting, dimmed behind the windows. |
| `video` | Title video | Build 42's title video, playing on the monitor. |
| `classic` | Classic | the checkerboard of 1993, in your color. |
| `weave` | Weave | basket weave, two over two. |
| `bricks` | Bricks | running bond, a mortar line between rows. |
| `diagonal` | Diagonal | a hairline every four dots, up to the right. |
| `grid` | Graph | graph paper, a line every eight dots. |
| `dots` | Dots | polka dots, every other row set over. |
| `zeds` | Zeds | ZeD's own Z, every other row set over. |
| `disks` | Disks | the ZeD-GUI disk, every other row set over. |
| `camo` | Camo | woodland camo in four tones of your color. |
| `squiggle` | Squiggle | brush dabs and squiggles, straight off a 1993 party aisle. |
| `solid` | Solid | your color alone, at a middle tone. |
| `accent` | Accent | flat, your theme's accent at a middle tone. |
| `slate` | Slate | flat, a cool blue-grey. |
| `fine` | Fine | one dot in sixteen, barely there. |
| `pinstripe` | Pinstripe | a faint line every four dots, as on a title bar. |
| `topo` | Topo | Knox County from the air: contour lines, a creek in the valley. |
| `carpet` | Carpet | the arcade's carpet, confetti on indigo. |
| `paneling` | Paneling | the den's pecan wall boards. |
| `flannel` | Flannel | plaid, red over maroon. It is 1993. |
| `stars` | Stars | a clear night, no lights for miles. |
| `tally` | Tally | days counted in pencil on the plaster. |
| `usa` | USA | the Stars and Stripes, faded by a few summers on the porch. |
| `kentucky` | Kentucky | the Commonwealth's flag: the seal, its motto, goldenrod in bloom. |

The words on the Kentucky flag (COMMONWEALTH OF KENTUCKY, UNITED WE STAND, DIVIDED WE FALL) are part of the picture
and are not translated: they are the flag's own.

## 8. QA

Test on the PC, with the gamepad first: fullscreen 4K at UI scale 1.75, then 1080p. Reset the layout (R) before each
run.

**The menu and window**

- Settings shows **Desktop...** where the two wallpaper rows were. It opens the Desktop window, and Done or B closes
  it.
- Each of the 25 swatches sets its desktop at once: the ring moves and the help band reads its note.
- The choice survives a restart.
- An old `ZeD_wallpaper.txt` holding "original" or "new" opens on Painting or Title video.

**The patterns**

- They are crisp: a dot is an icon's pixel (2 px at 4K with UI scale 1.75).
- No seam shows where tiles meet, and the glass's scanlines lie over them.

**The color**

- Change the Color of Highlighted Container in Options with the menu open. The patterns, Solid, Fine and Pinstripe
  follow at once.
- White gives grey, and a loud pick stays calm.
- Accent follows the theme's accent.
- Slate, the Fun set and the flags don't move.

**The themes**

- Dark, Light, High contrast and each colorblind mode: the desktop doesn't change.

**The flags**

- USA: the union is at the tube's top left, under the left-hand icons, and the stripes run the tube's height.
- Kentucky: the seal is in the middle. With the main window open, its foot and the goldenrod show under it.
- Both fill the tube at 1080p, 1440p and 4K.

**Unchanged**

- Painting and Title video look exactly as now: dimmed, and with video effects off the video falls back to the
  painting.

**Elsewhere**

- The left screen (a lost connection) shows the chosen desktop too.

**The controller**

- The D-pad reaches every swatch and Done, A sets, and the Controller highlight shows.
- Nothing is bound to L3 or R3.

## 9. Checked in Design's sandbox

`check_reference.py`:

- **The color:** the reference Lua's `D.tone` against `desktops.py`'s `tone()` over 510 colors. The largest
  difference is 0.000008 of 255.
- **The drawing:** every desktop drawn by the reference (`D.draw`), rasterized from its draw calls with the staged
  textures, against the script's own tube.
  - 23 desktops in 2 colors, at 960 x 720 (zoom 1) and at 1920 x 1440 (zoom 2).
  - 0 pixels differ.

The canvas's boards and these previews come from the same script.

## Open, for the director

- **Kentucky's seal sits behind the main window** while it is open; only its foot and the goldenrod show. The seal
  can drop below the window instead, if he would rather see it.
- **The default stays the Painting** unless he names another.
