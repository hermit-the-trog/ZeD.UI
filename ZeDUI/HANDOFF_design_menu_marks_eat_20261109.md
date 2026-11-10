# Handoff: colored marks for paired actions on the menu icons; new Eat, Sneak and Safehouse icons (Nov 9 2026)

From design, for Build and then QA. The director approved it all on Nov 9: "The blue for add, red for remove", the
player's side deciding which is which, Dispose's lid red; then the wider rule, "I want color to distinguish the
difference ... when there's an A action and a B action", with all three groups of pairs in ("All three"). Also the Eat
figure with a three-tined fork, Sneak, and the boarded-up Safehouse.

- **Sheets and sources:** `ZeDUI/mockups/zed_menu_marks_v1/`
  - `ctx_marks_final.png`: the approved set, every icon that gets a color.
  - `ctx_cvd_test.png`, `ctx_teal_red_test.png`: why blue and red (they hold apart under all three kinds of color
    blindness; teal and red, and green and red, don't).
  - `pairs_v1.png`, `pairs.py`: the pairs added after (plain plus and minus, on and off, either way).
  - `eat_fork_v2.png`, `zw_eat_16.png`, `zw_eat_24.png`, `fork.py`: the Eat icon and the script that draws it.

## 1. The marks

**The rule: color marks the difference between the two actions of a pair.** The icons stay ink; only the mark that
tells the pair apart takes a color: a plus or minus, an in or out arrow, the strike or x of an "off". The first of the
pair (add, on, in, up, open, enter) is blue; the second (remove, off, out, down, close, exit) is red. The shape still
carries the meaning, so a player who can't see the color loses nothing.

| | Color | |
|---|---|---|
| First | `#0B63B0` (5.5 : 1 on the paper) | add, take, load, in, open, up, enter |
| Second | `#C2410C` (4.6 : 1 on the paper) | remove, put, drop, unload, out, off, close, down, exit |

Both are literals, like the paper and ink they sit on (`#F2F2F2`, `#141414`); suggest them as `ZeD.Ctx.markAdd` and
`ZeD.Ctx.markRemove` next to the paper and ink, not in the themes.

**Which icons** (the 16 and 24 of each, and the 32 and 48 doubled from them):

*Add and remove*

| Blue | Red |
|---|---|
| `plus`, the whole glyph (every "Add ..." row, and the recipe's "and" / "with") | `minus`, the whole glyph (every "Remove ..." row) |
| `equip` (plus) | `unequip` (minus) |
| `tray_out` Take (the arrow) | `tray_in` Put in (the arrow) |
| `mag_in` Load, `rounds_in` (the arrow) | `mag_out` Unload, `rounds_out` (the arrow) |
| `battery_in` (plus) | `battery_out` (minus) |
| `fill` (the arrow) | `empty` (the arrow) |
| `safehouse_claim` (plus) | `safehouse_release` (minus) |
| | `to_floor` Drop (the arrow; the floor dots stay ink) |
| | `bandage_off`, `unplug`, `bulb_remove` (minus) |
| | `trash` Dispose (the lid, rows 1-3 at 16) |

*On and off*: the "off" twin's strike (`kit.slash`) or x badge goes red; the "on" stays ink, it has no mark.
`alarm_off`, `ammo_off`, `bulb_off`, `craft_off`, `eye_off`, `headlight_off`, `hotwire_off`, `key_off`,
`magnifier_off`, `star_off`, `target_off`, `sit_ground_off`, `sneak_off`, `autowalk_off`; and `autowalk`'s plus is
blue.

*Either way*: the arrow or badge that tells them apart, blue on the first, red on the second.

| Blue | Red |
|---|---|
| `car_enter` | `car_exit` |
| `window_open` | `window_close` |
| `zoom_in` | `zoom_out` |
| `move_up` | `move_down` |
| `box_up` | `box_down` |

**Stays ink:** arrows that say where, with no twin to tell apart (`hand_main`, `hand_off` the off hand, `holster`,
`holster_left`, `holster_right`, `tent_down`, the figures' arrows); pairs told apart by a changed shape, not a mark
(`padlock` / `padlock_open`, `link` / `unlink`); the window controls (`expand` / `contract`, `pop_out`); emotes
(`thumbs_up` / `thumbs_down`, `yes` / `no`); and the check. The list icons' plus and minus (`outfit_*`, `loadout_*`)
aren't in the menu; leave them for now.

**When it's unclear which is first** (the director's call: the player's side decides): a plus or an in-arrow is blue,
a minus or an out-arrow is red, except the container pair, where Take is blue and Put in is red whatever way the arrow
points. Load is blue and Unload red. A new pair follows the same rule.

**How to build it** (a suggestion; your call):
- In `wheelpx`, let an `@icon` mark the pixels that carry the color (`kit.badge` and `kit.slash` already know their own; the arrow
  icons in `i_row.py` and `i_gun.py` need theirs marked by hand). `export.py` writes a second picture per colored icon,
  `zw_<id>_mk.png`, holding only those pixels, and a table `ZeD.PxIconMark = { equip = "add", ... }` into
  `ContextPxIcons.lua` (or beside it).
- `ZeD.Atoms.drawPxIcon` draws the icon in ink as today, then the mark picture over it in the mark's color, only when
  the caller asks for marks and the icon has one.
- Ask for marks in the strip, the list menu and the wheels **at rest only**. A pointed cell or row draws the whole
  icon in the accent's text color, marks included, as today. The paper is locked, so no theme changes the colors.

**Check (QA):** at UI scale 1 the plus and minus are 1-pixel lines; they read as color at 1.75x and up, and only as
shape below that. That's expected. Check the 24s in the wheels, the pointed state (no color left on the accent cell),
that the strikes read red at 1.75x and up (they're 1-pixel lines too), and that nothing outside the tables took a
color.

## 2. Eat

A new icon, `eat`: the doll's figure (`fig16.py`'s template, shifted two columns left), the free arm hanging, the other
holding up a three-tined fork with a neck under the bar so it reads fork, not trident. The 16 and 24 are drawn by hand
in `fork.py` (the pixel sets `f16` and `f24`); the white-on-clear PNGs are beside it.

- Move it into `wheelpx` as an `@icon("eat", "ctx2", ...)` in `i_ctx2.py` (food and cooking), from those pixel sets.
- In `map.py` CTX, `user-eating` goes from `apple` to `eat`. That covers Eat, and Eat all, half and quarter.
- Run `export.py --game`. The apple stays for the things that are apples.
- No color on it: eating isn't add or remove.

## 3. Sneak

The director picked option A of four (`sneak_options_v1.png`): a hunched figure creeping on its toes, paws up in front.
It replaces the crouch picture for sneaking; the crouch stays wherever it means crouch alone.

- `sneakA.py` draws the 16 (by hand, the grid `A16`) and the 24 (`A24`, the 16 at one and a half times with the doll's 7 disc for a head); `sneak_A_v2.png` shows both,
  true size and pointed. White-on-clear PNGs beside it: `zw_sneak_16/24.png`, `zw_sneak_off_16/24.png`.
- **Stop sneaking** takes the x, **top left**, not top right: the head fills the top right corner, and the doll's rule
  puts a figure's badge where the figure isn't. The figure doesn't move.
- Move both into `i_fig.py` as `sneak` and `sneak_off` (the ids `map.py` already uses for `emotes/crouch_on` /
  `crouch_off` and the wheel's Crouch slice), then run `export.py --game`. No color on either: not add or remove.

## 4. Safehouse

The director picked option A of four (`safehouse_options_v1.png`): a house with its window boarded up, the two planks
sticking out past the walls so they read as boards nailed on, not a vent. It replaces the three shields.

| Menu option | Today | New id | Mark |
|---|---|---|---|
| `ContextMenu_ViewSafehouse` | `shield_plain` | `safehouse` | none |
| `ContextMenu_SafehouseClaim` | `shield-plus` → `reinforce` | `safehouse_claim` | plus, blue (add) |
| `ContextMenu_SafehouseRelease` | `shield_minus` | `safehouse_release` | minus, red (remove) |

- `safeA.py` draws all three at 16 and 24; `safehouse_A_v2.png` shows them, true size and pointed. White-on-clear PNGs
  beside it (`zw_safehouse*_16/24.png`), and for the two with marks, the mark alone (`*_mk.png`), the shape section 1's
  export would write.
- The badge sits bottom right, cut clear of the house as `kit.badge` does.
- **The 24's plus is off centre everywhere, not just here** (director, Nov 9: "it's not centered"). `kit.badge` draws
  a 7-wide badge at 24 with 2 px bars, and a 2 px bar can't sit in the middle of 7: today's `zw_equip` 24 has two
  rows above the bar and three below. `safeA.py` uses an 8-wide badge at 24, so the bars sit dead centre. Make
  `kit.badge` do the same at 24 (`b = 5 if n == 16 else 8`; check the four arrows and the x still draw well at 8), and
  re-export: every 24 badge moves by a pixel.
- Move them into `i_ctx6.py` beside the shields and export. The three menu rows share their picture names with other
  options (`shield-plus` is also Reinforce's, `shield` and `shield-minus` may be used by mods), so give the three rows
  in `ContextIcons.lua` picture names of their own (`safehouse`, `safehouse-claim`, `safehouse-release`) and map
  those in `map.py` CTX, rather than remapping the shields. The shield icons stay for everything else.
