# Build notes on Design's over-head and foraging handoff (Nov 17 2026)

These are Build's replies to `HANDOFF_design_overhead_icons_pins_20261117.md`. They're kept apart from it because
Design is still editing that file and its art folder (`ZeDUI/art/overhead_20261117/`) in the repo. Twice, Build's
notes added to the handoff were lost when Design saved over them. Design: read these, and fold in what you want.

## Built (commit 7d7421a17, and the pointer after it)

- **A, the pins:**
  - `42/media/lua/client/ZeD/Overrides/ForagePins.lua` replaces `ISBaseIcon:renderPinIcon` as specified: the back,
    the item at its own size up to 32 on the lens at (29, 26), the glass, and the poison mark at (42, 36). A find
    that isn't identified shows the frosted `?` lens. The game's alpha and colour apply to every layer.
  - Textures are in `42/media/textures/ZeD/forage/` (`pinB_back`, `pinB_glass`, `pinB_unknown`, `poison_mark`).
    `pinB_hint` isn't shipped, since it has no use yet.
  - The game's own pin comes back in safe mode, and for any frame where ZeD's fails.
- **A2, the pointer to a find:** built, but not the way the handoff proposed. The handoff assumed the game's arrow
  sits on a ring at the feet, and that ZeD must draw the hand itself.
  - **How the game places it:** its Java (`WorldMarkers$PlayerHomingPoint`, read from 42.21's jar) puts it 130 px out
    from the character. While the find is on screen and within 20 tiles, it puts it by the find itself instead. It
    eases the arrow along, turns it, fades it in fog and keeps it on the screen.
  - **What Lua can reach:** Lua can't read where the arrow is. It can change the arrow's picture (`setTexture`, which
    takes a name under `media/textures/highlights/`) and its size.
  - **What ZeD does:** it keeps the game's marker and all that behaviour, and dresses it as the hand: white at full
    alpha, 44 x 77.
  - **Thumb on top:** there are two upright hands. `zed_forage_hand_up_a` is Design's right-pointing hand turned to
    point up, thumb at its left; it's used for a find to the right on screen. `zed_forage_hand_up_b` is its mirror,
    for a find to the left. Turned to point, each keeps its thumb on top. This was checked by turning the pictures,
    and in `forage_pins_sim`.
  - **Not controllable from Lua:** the game's filtering when it turns the picture. The stepped edges Design asked for
    may come out soft while the hand turns. QA will look.
- **B, the eye:**
  - The game's `renderEye` draws nothing while ZeD is on.
  - The eye is a note in ZeD's over-head stack (`ZeD_Bubbles.lua`, the eye note), just above the speed bubble, in
    ZeD's own light balloon, with the game's fade.
  - It's drawn from `overhead/icons/eyeconOn.png` pixel by pixel, as the speed glyph is, so it stays sharp at every
    scale. It isn't the baked 2x badge; that way the palette and scale stay live, as the handoff allows.
- **Test:** `ZeDUI/tools/qa/forage_pins_sim.lua`, 35 checks.

## C, the Java-drawn icons: a test, not shipped

- **How the game draws them:** its Java puts these pictures in the text of the character's name over the head:
  `[img=media/ui/CarKey.png]`, `CarKey_none.png`, `voiceon.png`, `voicemuted.png`, and **two** PvP skulls,
  `Skull1.png` and `Skull2.png` (`IsoGameCharacter`; there is no `Skull.png`).
- **The test:** a dev-only test mod, `ZeDUI/tools/qa/fixtures/ZeDQAOverheadTex`, puts Design's `CarKey` at 1x and
  `CarKey_none` at 2x in `media/ui/`. Walking up to a car shows whether the game takes a mod's file over its packed
  one, and at what size it draws it. ZeD ships C only after that.
- **For Design:** PvP needs two skulls, `Skull1` and `Skull2` (the two states `checkPVP` shows). Only one `Skull`
  was drawn.

## C2, the XP arrows: skipped

`media/ui/ArrowUp.png` and `ArrowDown.png` are also the game's combo box and context menu scroll arrows. ZeD's own
windows don't use them, but other mods' windows and the game's screens in safe mode do. A green up arrow would land
in those, so the XP arrows stay the game's.

## For Design: the pin's size (QA's catch, confirmed in the game's code)

- **The mismatch:** the pin textures are 60 x 90, but the game draws every pin at 30 x 45 at zoom 1
  (`ISBaseIcon:new`: width 30, height 45; `updatePinIconSize` divides by zoom).
- **What Build does:** it follows the handoff's canvas math against the pin's real width (s = width / 60). The find
  sits in the lens exactly as on the review sheet, but at half the size the handoff assumed: a 32-pixel item draws
  16 pixels wide on a 30-pixel pin.
- **Why it can't magnify:** the game drew the item at 21 pixels (32 / 1.5), larger than the lens can hold. So "the
  lens is meant to magnify it" can't happen at the game's pin size. Build keeps the find inside the lens.
- **Design's call:** for a bigger find, the choices are a bigger pin (the size code is the game's) or a find that
  overflows the rim.

## Still open, the director's

- D, the ten new ideas.
- The Simple style: the pins, pointer and eye have no Simple version, and are built as Immersive only.
- The hint pin.

## QA results (Nov 17 2026)

- **A, the pins:** good by eye at 4K: the magnifier with the find in the lens, the frosted `?` lens, the bounce and
  fade as the game's, finds centred. **For Design:** the poison mark reads tiny at 4K (12 units on a 30-pixel pin);
  it may want to be bigger.
- **B, the eye:** in a light balloon in ZeD's stack, no overlap; the game's own eye draws nothing.
- **C, the car key: the replacement does not take.** The game's car key is packed in `media/texturepacks/UI2.pack`.
  With the test mod's `media/ui/CarKey.png` (same path) loaded, the game still drew its own key: textures loaded at
  28 x 26 and 30 x 28, not the mod's 31 x 30 and 62 x 60. As the handoff says, these stay the game's, and ZeD does
  not hook the Java. That's the car key, the voice icons and the PvP skulls. Design's C art stays in the folder,
  unused.
- **A2, the pointer:** its check runs next.
