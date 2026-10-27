# ZeD-UI cohesion spec (Oct 26 2026)

The contract for the cohesion pass. Mockup: `ZeDUI/mockups/zed_cohesion_v1.html` (published as
https://claude.ai/artifact/CUT7j5FYBYxyNu3pfAEJRt). Audits with file:line for every finding:
`ZeDUI/audits/COHESION_2026-10-26_A_chrome_footers.md`, `..._B_focus_seethrough.md`, `..._C_content_newest.md`.
"u" = design units (`T.px(u)`; 1 px at 1080p). Every length goes through `T.px` / `T.sp` / a token, never a raw pixel.

## Director's picks (Oct 26 2026, verbatim)

- Window footer: A | Help line + window box
- Controller highlight: make each an option
- See-through: setting, default 90%, solid while in use as option, 100-60 as a slider option, and menu option under Text size
- Buttons: A | Push buttons everywhere, keys only on the hardware
- Where actions live: A | Verbs under the name, answers at the foot
- Status tags: A | Outlined, status as a dot
- Shadows: A | Keep the System 7 one on pop-ups
- Everything marked FOLLOWS YOUR RULES: as proposed
- "Status dot make status square. Trying to keep this 1993 and to keep ALL common AI contemporary web design standards
  out--those are out of brand. All caps in some places is still present and is out of brand. Line work on windows needs
  work too. A consistent border presentation is important. Some places the border is lighter or behind, some it's on top
  and clear, some might even be missing, leaving openings in the window frame."

## 1. 1993 rules (apply everywhere)

1. **No all caps in the windows.** Headings, section heads, category rows ("v Weapons (4)"), column heads ("Name",
   "Cat", "Cond", "Wt"), stat labels ("Kind", "Weight"), tags ("Lighter", "Out"), status words ("Empty", "Thirsty",
   "Next level", "In hand"), empty lines, help text: sentence case. Keep: initialisms and units as written (OK, HP, ZeD,
   CD, FM, AM, VHS, kg, mph, °F); vanilla's own strings shown as vanilla writes them (item names, its questions); text
   printed on the hardware props (dash, radio faces, watch, siren, generator faceplate, oven panel), and anything drawn
   in the HUD pixel faces that only have capitals (action bar, dash 3x5 / 5x7). Remove `string.upper` / `:upper()` calls
   on UI text and fix caps strings in `42/media/lua/shared/Translate/EN/UI.json` (keys never change). `ZeD.btnCase`
   stays for buttons; add one `ZeD.textCase` (same rules) for any caps string that arrives at draw time.
2. **Status marks are squares.** `A.drawStatusDot` draws a filled 6u square (no round dots anywhere in the UI); hollow
   marks (NEEDS, unread) are 6u squares with a 1u border. One size everywhere: 6u (the title bar's stat marks too).
3. **No contemporary web patterns.** No pills, segmented controls, sliding switches, chips with tinted fills, round
   status dots, left accent bars, breadcrumbs, soft shadows. Choices use System 7 controls: **checkbox** (square with X,
   `A.drawCheckbox`) for on/off; **radio buttons** (System 7 round radio) for one of a few; **pop-up menu**
   (`ZeD_Dropdown`) for one of many; **push buttons** for actions. The ZeD setup on/off switch becomes a checkbox; Hair
   and beard's two-way switch, the Traits "All / With a trait" pair and the map's Survey / Color / Paper pills become
   radio buttons; the List / Grid and List / Doll pairs become two separate icon buttons (4u apart, the active one solid
   accent). Round radio buttons and round knobs on hardware are fine: they are real 1993 parts.
4. **Shadows:** only System 7's hard shadow, 1u right and 1u down, black 0.5, and only on things that pop up over the
   game (menus, context lists, hover boxes, balloons, wheel cells, dropdown lists). Nothing else casts one; the 2u flat
   hint shadow goes.

## 2. Window frame and line work

1. **The frame is one continuous rectangle**, 1u `T.borderS` (2u on High Contrast), around the whole window, drawn
   **last** in the window's render, after every child, so nothing covers it. Fills run under it; nothing is inset to
   make room for it (drop the `T.px(1)` insets on footer and body fills).
2. **Two line weights only.** Structure lines, 1u `T.borderS`: under the title bar, between panes, the top of every band
   and of the footer, pane header bottoms, the tab waterfall's inner edge, the container strip's inner edge. They run
   edge to edge and meet the frame (no gap, no overshoot past it). Content lines, 1u `T.border`: under section heads
   and column heads, between groups. The groove only for a major break inside a card.
3. Children never paint over the frame or leave a hole in it: drawers, cards (also while sliding), scroll lists,
   scrollbars (the track's outer edge is the frame), the grow box, waterfalls, strips, maps, the curtain. Pop-ups use the
   same 1u `T.borderS` frame plus the hard shadow.
4. Same on every window kind: Character, World, map pop-out, station pop-out, Messages, Reader, Seat chooser, prompts,
   keyboard, every main menu window, the pause window, the curtain. Check both text sizes, all three themes, fractional
   scales (1.75x at 4K: hairline rounding) and drawer slides.

## 3. Window chrome

1. **Window box** at the right end of the title bar (where System 7 kept its window controls): a box the size of the
   close box (`T.closeBoxSz`), same look, holding three 1u lines. It opens a System 7 pull-down (the ZeD context list
   look): **Theme** (Dark, Light, High contrast) | **Accent** (the nine) | **Text size** (Small, Large) | **See-through**
   (100%, 90%, 80%, 70%, 60%, and "Solid while in use" with a check) | line | **Reset this window** (| **Reset both
   windows** on the Character / World pair) | line | **ZeD setup...**. Title stats move left of it. Every ZeD window
   gets it. The four footer squares and the `windowSquaresOn` setting go.
2. **Footer = help line**, 22u (`T.px(22)`), surface 2, structure line on top. Mouse: the plain-words help for what the
   pointer is over (an element's `help` text; else the window's own status line, e.g. "9 items | 6.3 of 20 kg"), F2 in
   `T.textDim`, one line, ellipsis. Controller: the prompts for what has focus, the pad pictures (`ZeD_PadGlyphs`) at 14u
   with F2 labels in `T.text`, left-aligned from 10u, 8u between prompts; the lock state (Y held) shows as a "Locked"
   prompt. Resizable windows end it with a 22u grow box. **Every** ZeD window gets the line, the small ones too
   (prompts, keyboard, Messages, Reader, seat chooser, station pop-out, main menu windows, map pop-out).
3. The bottom-edge zone underline goes (the focus mark replaces it).
3a. **Rolled-up side and window shade.** The help line belongs to the window's body: when a side rolls up under its
   rod (`WindowCurtain.lua`), the window narrows to the open side and the help line narrows with it (help text ends in
   an ellipsis; prompts drop the least important first). The rod has no footer of its own: pointing at its tab puts the
   tab's help in the line ("Inventory, 9 items: press to roll it down, or drop things on it") and a controller on the tab
   shows "Roll down". Shaded to the title bar (double-click), the window shows no footer at all.
3b. **Resizing (director, Oct 26 2026).** Every resizable window resizes from the bottom edge (height only), the bottom-left
   corner (width from the left, the right edge stays, and height) and the bottom-right corner (the grow box). Hit zones
   inside the window: the bottom 6u across the width, 22u squares at both bottom corners. A press drags at once. The
   handle shows only after the pointer has rested about 350 ms in a zone with no button down, so a sweep across the
   edges never flickers: the bottom edge shows a centred ridged grip (~40u) and the frame's bottom line in the accent;
   a corner shows the grow box's ridges in the accent (a ridged box appears at the bottom-left while shown). It stays lit
   while dragging. Minimum sizes as today.
   **Left and right edges too** (director: "Add the left and right edges too, width only."): width only, the left edge
   keeping the right edge in place; the outer 4u on each side below the title bar. The tab waterfalls, container strips
   and the right scrollbar sit there, so a side edge arms only after the rest shows its handle (a centred vertical ridged
   grip, ~40u, and the side's frame line in the accent); before that a press goes to the content as today.
4. Title bar: the tab name lives in the title on both windows ("Angel Cross  +  Loot", "Crate  +  Craft"); stats are
   status only; drop the dead `stat.icon` field and the alpha-0 "no dot" trick (a `noMark` flag instead).

## 4. Settings (ZeD setup, Select wheel, window box)

- **Controller highlight** (`focusStyle`): Pointing hand (default) | Corner marks | One wash | Marching ants. The player
  chooses it on the ZeD setup page (with a live sample row beside the choice, `ZeD.Focus.drawSample`), in the window
  box's menu (after See-through) and on the Select ZeD wheel.
- **See-through** (`seeThrough`): slider 100 to 60 in steps of 10, default 90. **Solid while in use** (`solidInUse`):
  checkbox, default off. Both also in the window box's See-through submenu (under Text size).
- Saved with the other ZeD settings; translated labels in UI.json.

## 5. States (one look each, every surface)

| State | Look |
|---|---|
| Mouse hover | `T.hover` wash (theme-tuned: 0.20-0.22 dark, 0.15 light) on every row, button, tab, slot, toggle and header that can be pressed. List rows and card buttons gain it. |
| Selected | one accent wash at `T.selectionA` = **0.30** in all three themes. No side bars, no solid fill, no border. |
| Active (current tab, current tool, an icon toggle that is on) | solid accent, contents in `T.textOnAccent`. The tab waterfall keeps its lit bevelled panel. |
| Controller focus | the `focusStyle` mark (section 6), only in the focused window, on the focused element of the focused zone, only in gamepad mode; it clears when the mouse is used (the remembered element is kept for the next pad press). |
| Pressed | the library's 1u label nudge. |
| Disabled | the whole control at `T.disabledAlpha` (0.42); still focusable where it explains why (NEEDS). |

Words on any wash of 0.5 or more switch to `T.textOnFocus`. Cues are drawn **under** the words, never over them.

## 6. Controller highlight styles (one function, `ZeD.Focus.paint`)

All four draw in an overlay pass after the window's content (so neighbours never cover the mark) and may cross the
window's edge. "Solid" = the element is already solid accent (primary key, active tab, selected solid thing).

- **Pointing hand** (default): the hover wash under the element (none on solid ones) plus a pixel pointing hand at the
  element's left, fingertip touching its left edge, vertically centred. Art (16 x 11, `#` black, `.` white), one art
  pixel = k screen pixels with k the whole multiple of the root scale (as `ZeD_TabPx.k()`), plus a 1-pixel 0.45 black
  shadow down-right:
  ```
     ####
    #....#########
   #.............#
  #..............#
  #.....#########
  #......#
  #.....##
  #......#
  #.....##
   #....#
    ####
  ```
- **Corner marks:** the hover wash plus four L marks 3u outside the element's corners, each arm 6u long and 2u thick,
  `T.accentBright` with a 1u black edge.
- **One wash:** 0.55 accent wash under the element, words in `T.textOnFocus`; on solid elements a 2u inset ring in
  `T.textOnFocus` instead.
- **Marching ants:** the hover wash plus a 1u rectangle 2u outside the element, 2u black / 2u white dashes, moving 8u a
  second.
- Gating fixes from audit B: check the focused **window** as well as the zone (Craft, Build, Journal recipes, Journal,
  Animals, Foraging, Stations, JournalReaders); hide the mark in mouse mode. The old ring / outline / ring+fill focus in
  ItemCard, Skills, Hair and beard, Traits, map toolbar, plates' keys move to `ZeD.Focus.paint` (hardware knobs keep
  their ring; it is the knob's own light).

## 7. Buttons

- **Push button** (`M.drawButton`, double rounded outline) for every pressed word: default, **primary** (accent outline,
  `T.accentText`), **danger** (red outline, `T.dangerText`, the slow pulse), disabled (0.42). Height `T.buttonH`
  (26 / 30 Large); inside a list row `T.buttonH - T.px(4)`. Label F3, sentence case through `ZeD.btnCase`, measured
  after casing. Hover = `T.hover` fill; focus per section 6.
- **Icon button**: square `T.buttonH`, the push button's rounded outline (single), 16u icon centred, hover wash, a hint
  after 450 ms. Replaces map toolbar ghost squares, container control icons, the strip icons.
- **Keys (bevel)** stay only on hardware (dash, radio, siren, watch, appliance faceplates, generator). Retire: ObjectCards
  `UI.button` bevel, `drawCardBackBar` bevel verbs and back key, `drawCardVerbStrip`, Animals `drawBtn`, Craft CTA and qty
  stepper (to push buttons; the stepper is two push buttons around a readout), map ghost buttons, `A.drawPillButton`
  uses (Health exercises, Thermal views, Journal readers: push buttons or radio buttons by meaning).
- Back: an icon button with a left triangle, the same on every card and drawer.

## 8. Where actions live, and the band

- **Verbs for a thing sit under its name** (item card back bar, object card verb row): push buttons, primary first.
- **The band at the foot of a pane** holds the screen's own actions (Create zone, Mark all read, Cut, Transfer all...)
  and every answer to a question. One molecule `M.drawBand`: height `T.buttonH + 2 * T.px(5)`, surface 2 (no stacking,
  section 10), structure line on top. Left: a status or question line (square mark + F2). Right: answers, the main one
  last, `T.px(8)` between, `T.px(8)` from the edges. Icon actions left-aligned when the band carries them. Used by: item
  and object cards, Animals, Vehicle, Hair and beard, Craft / Build, container controls, Messages, Reader, seat chooser,
  prompts, every main menu screen (their 46u strip becomes the band), the map side list.

## 9. Questions, NEEDS, tags, headings, hover, empty

- **Question before the irreversible:** "<Verb> the <thing>? <What is lost>." with a red square mark, then **Cancel**
  and the verb's own word (danger if it can't be undone, primary otherwise), as a band swap. Journal entries ask too.
  Animals' green Yes / red No and Vehicle's Yes / No become Cancel + the verb. "Discard changes" is danger everywhere.
  Vanilla's own questions (ZeD_Prompt) keep vanilla's words.
- **NEEDS:** one line per greyed verb under the verb row: a hollow 6u square, then "<Verb> needs <what>." in F2
  (`T.text`), e.g. "Light needs a lighter or matches in your bags." The verb is greyed (0.42) and still says it in a
  halo if pressed. Retire the NEEDS section headers, red badge + box, footer "Can't X" line.
- **Tags:** one look: 16u tall, 1u `T.borderS` outline, F1, sentence case, 5u side padding; a status adds its 6u square
  mark inside before the word. No tinted fills, no coloured words. The grid's tiny corner badges keep solid squares.
  `A.drawBadge`, `UI.tag`, `drawStatusChip`, `drawFlagChip`, Belt / Equipment IN HAND move to it.
- **Headings, three kinds:** tab head 37u (`M.drawTabHeader`, F4, triangle when it folds, structure line under);
  section head 20u (`M.drawSectionHeader`, triangle atom, F1 sentence case, count "(4)" in `T.textDim`, content line
  under); category row 15u ("v Weapons (4)" built on the triangle atom, F1 `T.toneLo`). Column heads 20u F5 sentence
  case. One sub-tab strip (`M.drawTab`) for Journal and Animals.
- **Hover boxes, two:** hint (one line F2, icon-only buttons) and detail card (title F4, lines F2 / F3). Both surface 1,
  1u `T.borderS`, the hard 1u shadow, after one shared 450 ms delay (`ZeD.HINT_DELAY_MS`), placed below-right of the
  pointer, flipped to stay on screen. The belt chip, skill card, hair balloon, read-mark box, dash lamp chip, map list,
  Messages hover move to these (the moodle thought bubble stays: it is the moodle's own voice).
- **Empty lists:** one F2 line in `T.textDim`, left-aligned at the list's text inset, 8u below its header, a full
  sentence ("No animal zones yet."). A fix, when there is one, is a button in the band.

## 9b. Status bars (director, Oct 26 2026)

"One other drift happened to status bars. They are supposed to be a more chunky strip than a glowing line... We lost
the look a while ago" (reference: System 7.5's About This Macintosh memory bar). Every condition, progress and amount
bar is `ZeD.Atoms.drawFillBar(panel, x, y, w, percent, graduated, fillColor, h)`: a framed strip (1u `T.borderS`, 2u
High Contrast), a solid dark well (`T.base`), a flat solid fill (status colour when graduated, else accent or the
caller's), no glow, no gradient, no half-alpha. Height `T.fillBarH` (13 / 15 Large); in list rows
`ZeD.Atoms.fillBarCompactH()` (8u), centred. No 1-5u lines anywhere. Segmented meters (`A.drawSegBar`) are framed and at
least 8u tall. Props' printed gauges (dash, generator needle, tanks) keep their art. The belt's slot condition lines and
the ammo pouch's gauge become the same strip too (director: "Yes, make the belt's slot condition lines and the ammo
pouch's gauge the same chunky framed strip."): slots get the compact strip inside their bottom edge; the pouch keeps one
segment per round inside the framed strip. Oct 27 (director: "Make the belt hands' condition ring and the action bar's
progress line the same chunky framed strip as the other status bars."): the hands keep a ring (their Oct 24 note: a bar
looks odd in the circle) drawn as the strip bent round, 1u in from the outline and 6u across (1u frame each side, the
`T.base` well, a flat fill clockwise from twelve in the strip's graduated colours); the action bar's verbose line is a
6-unit framed strip in its pixel grid with the queue's steps as frame-coloured dividers (its thought bubble 4 units
taller). The Simple mode's ten segments stay as they are.

## 9a. Conditional disclosure (director, Oct 26 2026)

Fewer things on screen: an action shows only when it can be done.
- **Shown:** it can be done now, or after a step ZeD takes for you (walking over, a hat coming off).
- **Hidden:** it needs something the character lacks (a tool, an ingredient, parts, a skill level).
- **Gone:** it makes no sense in the current state ("Put out" on a dead fire). Never hinted.
- A band, footer or verb row with nothing left in it is not drawn.
- **Setting "Hidden actions"** (`hiddenActions`, ZeD setup only, no first-run question: "Interruptions in this game can
  quickly get you killed"): **Folded** (default) | **Show all** (greyed, each with its NEEDS line) | **Hide** (no hint).
- **Folded row** (`M.drawMoreRow`): one quiet row after the verbs with a closed System 7 disclosure triangle, F2
  `T.textDim`. One hidden action: the row is the hint ("With scissors you could cut your hair."). Several: "3 more with
  the right things". Opening it shows the hidden actions greyed with their NEEDS lines. A focus stop (A opens). Open /
  closed is remembered per card or tab for the session.
- **No spoilers:** a hint names only what the game itself would show (known recipes, the game's own menu entries);
  never an unlearned recipe or an unread magazine's teaching, even in Show all.
- First surfaces: item cards, object cards, Vehicle part cards, Hair and beard (its "Out of reach" fold moves onto the
  folded row), Animals, the tab bands. Context strip and Craft's recipe list keep their own filters for now.
- Helper: `ZeD.Disclose.split(verbs, setting)` with per-verb `canDo`, `needs`, `sensible`, `hint`.

## 10. See-through

- One value for every window surface: the setting replaces the base themes' surface alpha (0.92 / 0.97 / 0.95) in
  `ZeD.applyTheme` before `deriveReadable` (which already re-solves text colours against the world), and in
  `Organisms.lua windowAccentPalette` (clear its cache on change).
- **No stacking:** a band, header or card drawn over the window body must not add opacity; at 60% the window must not
  look striped. Fills that use literal alphas (item card drawer 0.98, Messages panes 1, wheel strips 0.92, chips 0.95)
  follow the value instead. Words, lines, pictures and controls stay solid.
- Stay solid regardless: HUD props (belt, ammo pouch, dash, watch, radios), tooltips and hover boxes, context menus and
  lists, wheels, dropdown lists, the window box's menu.
- **Solid while in use:** 1.0 while the pointer is over the window or the controller is in it, back to the value over
  200 ms when it leaves.

## 11. Words

One word per act, the game's own where it has one: Delete (permanent, for things ZeD made: notes, presets, journal
entries, messages), Remove (take off or out; also zones, the game's own word in its zone panel), Undo changes, Discard changes (danger), Choose. Sentence case on every button
("Show survey"). US spelling (Favorite, color). Never the button's letter in running text: name the act or use the pad
picture. "Out of reach" only for distance; "Not available here" for anything else.

## 12. Newest pieces (designs stay as approved; only the parts change)

Hair and beard (`ZeD_HairBeard.lua`): section head, 15u group rows, rows at the list row height, selected wash, library
meter (`A.drawSegBar`) and busy bar (`A.drawProgressBand`), radio buttons for the two-way switch, push button at
`T.buttonH`, the detail hover card, prose in F2. Traits (`ModSupport/traitsAsSkills.lua`): Skills' row rhythm and fills,
section head, "Positive / Negative" wording like Identity, radio buttons, a detail panel that wraps instead of dropping
lines. Ammo pouch: count in F3 with a status square, not coloured heading type. Map (`MapsTab*.lua`, `ModSupport/` map
mods): icon buttons, checkbox, a scrollbar on the side list, "Delete" push button, F2 prose. Read marks (`ReadMarks.lua`):
square marks (full, half = left half filled, hollow), the hover card. ZeD setup (`Settings.lua`,
`ZeD_MainMenuOptions.lua`): checkboxes, one wording pattern for option names. Skill Recovery Journal strip: the hover
card, the library legend swatch. Messages, Sandbox in game: tokens not alpha for dim text, one tag look, one revert word.

**Belt hands together (director, Oct 27 2026; mockup `zed_belt_hands_together_v1`, v3).** "I think the hands should move
together on the belt" (replaces the Oct 25 hands-at-both-ends layout). "Can primary be a little bigger than secondary, the
way the vanilla game does it?": the main hand 56 units, the off hand 44 (a slot's size, a 28-unit picture; vanilla's off
hand is three quarters of the main), 6 apart, the belt 4 units taller. "I think keeping the primary the circle, and having
the secondary peeking from behind when an item is in both hands": the main hand keeps its circle, picture and condition
ring; the off hand slides in under it and shows 14 units, empty (no picture, no ring, no words); clicks on the crescent
reach the off hand. "Put the hands together at the left end": `[left-wrist watch][off][MAIN][ammo tab][right-wrist
watch] ==strap with the slots and buckle== [Messages note]`. The belt is placed by its buckle, so the slots never move;
the hands move left when the ammo tab or a right-wrist watch appears between them and the strap. "I think the ammo
should peek out from the gun/primary icon, rather than be on a belt. So it looks part of the gun. Right now it looks
like a clip attached to the belt, which would give the wrong impression.": the ammo is a tab a slot's height out from
under the main hand (its end under the circle's middle, drawn first so the circle covers it, the hands' two-unit
outline, no strap under it); its words and rounds start at the circle's edge. A gun in both hands: the off hand peeks
left, the ammo right. The controller starts
on slot 1; Left reaches the main hand, then the off hand. QA `ZeDUI/tools/qa/hands_together.txt`.

## 13. Under the hood

Delete dead paths in live files (the `footerToggles` footer, `cardOwnsActionStrip`, `Atoms.drawFocusRing`,
`ZeD.Gp.focusRing*`, the dead 0.55 + bar waterfall branch, `A.drawStatusLabel`). Leave unused library classes in place.
Bring `GAMEPAD_SPEC.md` rule 4, `GLOSSARY.md` and the rules in `STATE.md` in line at the end.

## 14. Builder rules

- Work only in `C:\Users\danie\ZeD-cohesion` (branch `cohesion`). Never touch `C:\Users\danie\Zomboid\mods\ZeD-UI` (the
  game loads that copy; a compatibility run is using it). Never launch the game. Never commit (the session commits).
- Stay in the files you are given; ask the session before touching another file.
- Read `ZeD.T` fresh each frame; no `Tokens.lua` mutation at draw time; Kahlua: at most ~150 locals per function (the
  `-debug` limit is 200), hoist forward declarations before closures that use them.
- Parse every edited Lua file with the game's own compiler: compile `ZeDUI/tools/qa/KCheck.java` once with
  `C:/Program Files/Java/jdk-19/bin/javac.exe -cp "E:/Project Zomboid/steamapps/common/ProjectZomboid/projectzomboid.jar"`
  into a scratch folder, then `"E:/Project Zomboid/steamapps/common/ProjectZomboid/jre64/bin/java.exe" -cp
  "<scratch>;E:/Project Zomboid/steamapps/common/ProjectZomboid/projectzomboid.jar" KCheck <file.lua>`.
- Run `ZeDUI/tools/qa/i18n_guard.py` (Python: `C:/Users/danie/Documents/ComfyUI/.venv/Scripts/python.exe`) after any
  string change. New strings go through `ZeD.tr` with UI.json keys.
- Comments match the surrounding code: plain English, the why, no session numbers.
