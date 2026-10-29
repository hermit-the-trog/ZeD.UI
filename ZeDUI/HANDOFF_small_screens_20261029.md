# Handoff: small screens, the main menu and the scale (Oct 29 2026)

The director's call (Oct 29 2026, "go with recs"). On a small screen the main view stays in the room and any other window leans in. Auto's floor rises to 1.0. A saved scale too big for the screen is capped.

Mockups and redlines: `ZeDUI/mockups/zed_small_screens_v1/`. Start with `spec_small_screens.png`; `review_small_screens.png` is what the director chose from.

## Why

- **The test run's main menu failure** (`qa/Oct29_small_screens.md`, "The main menu at 1280x800: not ready") was the director's saved scale.
  - His `ModOptions.ini` has `uiScale` 7, which is 1.75.
  - The regression run set that file aside; the menu walk did not.
  - At 1.75 the monitor of a 1280 x 800 window holds 411 x 309 design units, so nothing fit.
  - On Auto (0.75) the same monitor holds 960 x 720 units, which is the 1080p menu, and it fits.
  - That page's menu section needs a line saying so.
- **The real problem.** On Auto a Deck runs at 0.75, where ZeD's letters are 5 to 8 px tall.
  - Valve's rule for the Deck: no character under 9 px at 1280 x 800, 12 px recommended, readable at 30 cm ([Steamworks: Steam Deck compatibility](https://partner.steamgames.com/doc/steamdeck/compat)).
  - ZeD's type at 1.0 is set at 9 to 15 px (`Tokens.lua`, small text).
  - So a Deck runs at 1.0. The menu at 1.0 needs a 960 x 720 monitor; the whole room gives 720 x 540.

## 1. The scale (`shared/ZeD/Scale.lua`)

- **Auto's floor.** `S.MIN = 1.0` (was 0.75). Auto never draws below the design size. Screens under 1080 tall hold fewer design units: a Deck 1280 x 800, a 720p screen 1280 x 720.
- **The cap on a saved scale.**
  - `userScale` is capped at 1.5 x the screen's own scale, `max(1, h / 1080)`.
  - A Deck or a 720p screen tops out at 1.5, the largest the Oct 29 run passed on a Deck. So does 1080p. 1440p tops out at 2.0, and 4K never caps.
  - The font-size knob (`USER_MUL`) still multiplies Auto, as now.
- **The options row** (the UI scale slider, `scaleReadout` in `ZeD_MainMenuOptions.lua`) shows the scale in effect when the cap bites, e.g. "1.75 (1.5 on this screen)". This needs a new key in the style of `UI_ZeD_Options_ScaleAutoNow`.

## 2. The menu's scale

- While the main menu is up (no game loaded) the root scale is also capped at `sMax / 4`.
  - `sMax` is the largest whole multiple whose monitor (240 s x 180 s) fits the screen.
  - A Deck has `sMax` 4, so the menu runs at 1.0 at most. 1080p allows 1.5, and 4K allows 3.0.
- With the director's saved 1.75 on a Deck, the game runs at 1.5 (section 1) and the menu at 1.0.
- Call the menu's scale `m` below.

## 3. Two framings of the desk

- **The room:** `MM.layout()` as today, the largest whole multiple that covers the screen with the monitor on it.
- **Leaning in:**
  - The multiple: the smallest whole multiple whose monitor holds 960 m x 720 m. That is 4 on a Deck, at 720p and at 1366 x 768.
  - The monitor stays whole on screen, centred top to bottom.
  - Across, 10 desk px of the right bezel stay in view (10 s screen px) and the lamp side gets the rest.
  - If that leaves a screen edge uncovered, slide the picture back until it covers, with the monitor still on screen.
- Everything placed on the desk follows the framing in use: the lights, the needle, the dial, the power button, the margins and the hit areas. They already go through `L`.

## 4. Which framing

- **When the room's monitor holds 960 m x 720 m**, everything stays in the room. That covers every desktop size on Auto, and nothing changes from today: 1080p and 4K must stay pixel-identical.
- **When it doesn't** (a Deck, 720p or 1366 x 768 at 1.0, or a big saved scale):
  - `main` and `desktop` stay in the room, in the small layout (section 5), if it fits.
  - Every other view leans in: `load`, `newgame` and its steps (spawn, sandbox, traits, looks), `mods`, `options`, and every view registered in `MM.views` (join, host, server, workshop, credits, trash, the description editor).
  - The pop-ups over the main view stay with it: the quit question and the File, Multiplayer, Settings and Debug menus.

## 5. The small layout: the main view in the room's 720 x 540 monitor

The numbers below are at m = 1.0, in design units; see `spec_room_1280x800.png`.

- **The desktop icons.** No change. `cells()` in `ZeD_MainMenuDesktop.lua` already wraps them into two columns at this height: five on the right, then Mods and Mod Uploader on the left, with the Trash under the right column. The block is 104 + 14 + 104 = 222 wide.
- **The main window** narrows to the room left of the icon block and moves to the left edge.
  - Its width: `w = L.tw - EDGE - blockW - GAP - EDGE`, which is 456 at 1.0 (was 660).
  - Its position: `x = L.tx + EDGE` (14). It stays at `WIN_TOP` below the bar, as now.
  - In `ZeD_MMWindow:build()` this is the `w = math.min(T.px(MAIN_W), L.tw - T.px(24))` line. In the placement, it is `x = L.tx + math.floor((L.tw - w) / 2)`.
- **The window's content** already takes its width.
  - At 456 the save card's text column is 270 units, room for "Last played Oct 28 2026, 1:21 PM".
  - The band's five buttons need about 360.
  - Check the longest translation of the band; if it doesn't fit, lean the main view in.
- **The fallback.** The window is 471 tall at small text and must end inside the monitor. If the window or the icon block doesn't fit, the main view leans in too. Large text, more icons and a long translation are the likely causes.

## 6. The move between framings

- A 200 ms dip: 100 ms down to black over everything, switch the framing at the bottom, then 100 ms back up.
- The desk is never drawn at a fraction of a multiple.
- Leaning out (back to the main view or the desktop) is the same dip.
- Power-on, power-off and the wake use the framing of the view they start in.
- If the dip fights the engine, a plain cut is acceptable.

## 7. Checks for the test run

- 1920 x 1080 and 4K on Auto: pixel-identical to today, with no leaning in.
- 1280 x 800, 1280 x 720 and 1366 x 768 on Auto:
  - The game and the menu run at 1.0.
  - The main view stays in the room in the small layout, with nothing past the monitor.
  - Every window opens leaned in and fits the monitor; Back leans out.
  - The dip never flashes the wrong framing.
- 1280 x 800 with the director's saved 1.75: the game runs at 1.5 and the menu at 1.0, and the options row reads "1.75 (1.5 on this screen)".
- In the game at 1.0 on 1280 x 720 and 1366 x 768 (not run yet): the tab walk, the windows at their default heights, the belt, the moodles and the D-pad wheels.
- Large text at 1280 x 800: if the small layout doesn't fit, the main view leans in.
- A real Deck, when a tester has one: the type at arm's length.

## The mockups

| File | What it is |
|---|---|
| `spec_small_screens.png` | The two framings with redlines, and the rules. |
| `spec_room_1280x800.png`, `spec_lean_1280x800.png` | The same, at the Deck's real pixels. |
| `review_small_screens.png` | The review the director chose from: what the test run saw, the three ways, a full-size window, 720p, and the type at 0.75 and 1.0. |
| `review_type_on_deck.png` | ZeD's five type roles as a Deck draws them, at 0.75 and 1.0, with Valve's 9 px and 12 px marks. |
| `review_A_auto_075`, `review_B_lean_in`, `review_C_room` (`_1280x800.png`) | The review's main views at real size. |

The review's menu frames were resampled from a 4K capture at 1.75. They draw the menu about 14% smaller than the game will, and the C frame shows a wider window with one icon column. The spec's numbers come from the code: `MAIN_W` 660, `BAR_H` 24, `WIN_TOP` 20, and the icon cells (`CELL_W` 104, `EDGE` 14, `GAP` 14, cell 58.7 tall).
