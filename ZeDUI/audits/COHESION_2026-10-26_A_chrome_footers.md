# ZeD-UI cohesion audit A: chrome, footers, headers, buttons, confirmations, NEEDS lines

Read-only audit. Nothing in the project was changed. "u" = design units (what `T.px(u)` scales). "F1..F5" = the five type roles (`T.fontF1` Fira Mono Bold, `F2` Fira Sans, `F3` Fira Mono Regular, `F4` Fira Sans Cond. SemiBold heading, `F5` Fira Sans Cond. micro). Paths are under `42/media/lua/client/ZeD/` unless shown. "Lib" = library molecule/atom, "Hand" = hand-rolled.

Headline: the in-game Character and World windows have only a 14u theme/prompt footer; every action footer is drawn by the surface itself, and there are at least 11 of them with different heights, fills, dividers, padding, alignment and button styles. Buttons come in four unrelated families. Confirmations are consistent in idea (footer swap) but not in wording, answer order or danger styling.

---

## 1. Window title bars

Library: `ZeD_Window:_drawFrame` (Organisms.lua:231-292) calls `M.drawWindowTitleBar` (Molecules.lua:1628-1695). Bar height `T.titleBarH` = 26u small / 30u Large (Tokens.lua:354,385; Large scales with root only). surf2 fill, 1u stripe every 4u starting at 2u (T.stripe), 1px `borderS` bottom line. Close box at x = `sp.sm` (10u), 13u/15u square (`Atoms.drawCloseBox`, AtomExtensions.lua:265; hover = `T.hover`, X in `textDim`). Title in **F3**, `textHead`, left at close box + `sp.md`, on a surf2 knockout box (`titleBoxPad` 3u) over the stripes, truncated for the stats. Stats: right-aligned, F3 `T.text`, with a 5x5 pixel dot to the LEFT of each text in `stat.color` (default `textDim`); a stat that would hit the title is dropped. `stat.icon` is ignored (Molecules.lua:1673-1693).

| Variant | Look | Where | Lib/Hand |
|---|---|---|---|
| Standard titled | as above, title sentence case, stats with live dot colour | Character `ZeD_CharacterWindow.lua:3576` (title = character or viewed bag name, then `"  +  Tab"` appended at 5912; stats = pinned skills, HP% coloured, weight 5546-5578); World `ZeD_WorldWindow.lua:3045` (title = `"<container>  <count>"` 4244; stats = active tab name in `textSec` 4678-4689); Map pop-out `MapsTab.lua:2058` ("Map"); Station pop-out `StationPopout.lua:92` (station name); Messages `ZeD_MessagesWindow.lua:241` ("Messages", count stat); Seat chooser `ZeD_SeatChooser.lua:425` (vanilla "Enter vehicle"/"Switch seat", vehicle-name stat); Reader `ZeD_Reader.lua:166` (`"Name  +  Paper title"`, "Read" stat) | Lib |
| Main-menu titled | same bar; title always `"Project Zomboid  +  <screen>"` (UI.json 600,740,1062,1160,1242,1280,1722,1830,2037,2051,2107,2191,2301,2602); pause = `"<name>  +  Paused"` (ZeD_MainMenu.lua:1598); stat is either a coloured dot (Mods 956, Traits 278, Options 802, Workshop 427, Paused 1599) or a plain count with the dot hidden by alpha 0 (Saves 478, Join 481, Looks 385, Sandbox 434, Server 506-508, Spawn 386, Desktop 280, SandboxInGame 541) | `ZeD_MMWindow` subclasses | Lib (hack for "no dot") |
| Untitled bar | stripes + close box, no knockout box, no stats | Prompt `ZeD_Prompt.lua:252`, Keyboard `ZeD_Keyboard.lua:85` | Lib |
| Curtain rod (rolled side) | bar with nil title, close box kept on the rod, bordered title chip with roll-down triangle (pressable, 0.22/0.55 accent) | `WindowCurtain.lua:96-150`; extra "roll" square after the title `WindowCurtain.lua:219-237` | Hand (reuses lib bar) |
| Black-and-white alert | no bar; pure black/white System 7 alert, 3px heavy frame, hard drop shadow, 0.5 dim behind; "Are you sure?" swaps in place | `Overrides/PostDeath.lua:213-413` | Hand, theme-independent |
| Station/Appliance plate, siren controller, car radio, two-way face | physical props, no bar (exempt) | `ZeD_SirenController.lua`, `ZeD_CarRadio.lua`, `TwoWayFull.lua` | n/a |
| Cards (Item, Object) | no title bar; a 37u "back bar" instead (section 3) | `ItemCardOrganism.lua:1143`, `ObjectCards.lua:807` | see 3 |

**Outliers**
- `ZeD_CharacterWindow.lua:5912` puts the active tab in the **title** (`Name  +  Tab`); `ZeD_WorldWindow.lua:4681` puts it in the **stats**. Same idea, two places.
- `ZeD_CharacterWindow.lua:5616` replaces the character name with the bag name when a bag is viewed; the player's name vanishes from the bar.
- `ZeD_CharacterWindow.lua:5572,5577` set `stat.icon` (heart, pack icons); `Molecules.lua:1673-1693` never draws it. Dead data.
- Alpha-0 dot hack (list above) still reserves 5u + 4u + `sp.md` for an invisible dot, so counts sit further left than the Messages/Seat stats, which draw a `textDim` dot.
- Seat chooser title uses the vanilla string ("Enter Vehicle" casing may differ from ZeD's sentence case, possibly).
- Prompt/Keyboard have an untitled striped bar while every other window has a title; the Station pop-out's title is only the station's own name.

**Proposed standard:** the library bar as is; title = what the window is about, stats = status only (tab name belongs to one place, preferably the title as `Name  +  Tab`); drop the alpha-0 dot trick in favour of a `noDot` flag. Call sites that change: Character/World tab-name placement (5912, 4681), the 8 main-menu stats using alpha 0, the dead `icon` field.

---

## 2. Window footer and every other footer

### 2A. `ZeD_Window:_drawFooter` (Organisms.lua:362-571), exactly

Which footer a window gets is decided by `footerHeight()` (152-165): `footerToggles` (dead, see below) > `resizable or themeFooter` > none.

| Item | Detail |
|---|---|
| Height | `resizeWidgetHeight()` = `T.sp.scrollbarW` = 14u (scaled by T.px, so 16px at 1.15) |
| Fill | surf2, inset 1px each side (406); top divider `A.drawDividerH(... false)` = weak `T.border`, 1 hairline (407) |
| Squares | 14u x 14u each, 4u gap, flush at x=0 (the fill itself is inset); bg surf2, hover surf4, 1px `borderS` border (427-428). 1 Theme: 5x5 pixel dot in the NEXT theme's colour (419-436). 2 Accent: dot in current accent (441-449). 3 Text size: letter "A" in F5 `toneNorm` (453-461). 4 Reset: letter "R" in F5 (466-477). No hover hint or label on any square; mouse only (851-906) |
| `windowSquaresOn` | Settings.lua:259-264, default on; off hides squares 1-3 (Organisms.lua:415-416) but R and the bar stay |
| Prompts | gamepad mode only (Organisms.lua:495-538). Right-aligned, ending `sp.sm` before the grow box; per item: pad glyph picture (or boxed letter, box = 14u-4u) + 3u gap + F5 label in `textDim`; items 20u apart (`sp.sm*2`); drawn right to left and the **leftmost are dropped** when `px - total < minX` (minX = after the squares + 12u). L3/R3 prompts are inserted first so they drop first (330-337). Labels derive from the focused element's callbacks (339-360) or `self:getFooterPrompts()` (main menu, 501) |
| Grow box | 14u square at the right when `resizable` (541), surf2 + `borderS` + 3 ridge pairs (AtomExtensions.lua:249) |
| Focus underline | gamepad only: 3u accent bar (4u `accentBright` when Y-locked) along the bottom edge over the focused zone's `uiRange` (550-567) |
| Dead path | `footerToggles` + `ZeD.ActionStrip.TOGGLE_DEFS` footer (375-392: surf2, **groove** top, `drawActionStrip` icons) is never enabled; the only reference is `win.footerToggles = false` at ZeD_WorldWindow.lua:3052 (its comment "No theme controls on world window" is false: the World window does draw them). `cardOwnsActionStrip` is read (375,844) and never set anywhere |

Flags per window kind:

| Window | resizable | themeFooter | noResetControl | Footer shows |
|---|---|---|---|---|
| Character `ZeD_CharacterWindow.lua:3576` | default true | nil | nil | Theme, Accent (per-window), A, R, pad prompts, grow box |
| World `ZeD_WorldWindow.lua:3045` | default true | nil | nil | same |
| Map pop-out `MapsTab.lua:2058` | default true | nil | nil | same; body = window minus bar minus footer |
| All 18 main-menu windows (`ZeD_MMWindow` and subclasses, ZeD_MainMenu.lua:1503-1506; SandboxInGame inherits) | false | true | `kind=="main"`, and every subclass sets true (e.g. ZeD_MainMenuOptions.lua:438) so R is shown on no window in practice | Theme, global Accent (`globalAccentControl`, 1506), A, pad prompts from `getFooterPrompts` (ZeD_MainMenu.lua:1830 plus 15 overrides; the desktop icons' returns nil); **no** `getFooterPrompts` on Workshop or DescEdit, so no prompts there; no grow box |
| Prompt `ZeD_Prompt.lua:254`, Keyboard `ZeD_Keyboard.lua:86`, Messages `ZeD_MessagesWindow.lua:68`, Reader `ZeD_Reader.lua:55`, Seat chooser `ZeD_SeatChooser.lua:104`, Station pop-out `StationPopout.lua:33` | false | false | n/a | **Nothing**: no squares (theme/text size cannot be changed there), no grow box; each draws its own footer (2B) |
| Test inventory (dev) | true | nil | nil | like Character |

### 2B. Every other footer

| Surface | Height / padding | Background + divider | Buttons | Alignment, confirmation | Where |
|---|---|---|---|---|---|
| Prompt | foot 40u, pad 12u; strip 14u under it only when a pad is active | surf2, weak `drawDividerH` | Lib `drawButton`, 24u, min 78u, pad 12u, gap 12u, F3; hover 0.22 / focus 0.55 accent fill; disabled = whole button faded 0.38 | right-aligned, main answer last, "danger" for costly questions; this window IS the confirmation (+ stop-sign mark) | ZeD_Prompt.lua:42-53,871-884,951-969,1101-1119 |
| Messages | foot 40u, pad 10u; help line 26u above; strip 14u below always (shows "ESC Close" even on mouse) | surf2, weak divider (help line has its own divider) | Lib, 24u, min 70u, pad 12u, gap **6u**; left: checkbox "Show popups" | Clear (default) + Mark all read (primary) right | ZeD_MessagesWindow.lua:31-36,202-221,330-356,359-364 |
| Seat chooser | foot 40u, pad 12u; strip 14u always | surf2, weak | Lib, 24u, min 78u; one Cancel button | right | ZeD_SeatChooser.lua:46-47,275-281,326-329,482-494 |
| Reader | strip 40u, pad 10u, gap 8u; **no pad strip at all** | surf2, weak, edge x=1 not px(1) | Lib, 24u, pad 10u | left cluster (Back, Paper/Words), zoom right; notebook mode: Back/Erase page/Lock left, pager centred, Done right; confirm swap with a question in F2 and Keep it / Erase (danger) | ZeD_Reader.lua:37,144-148,379-410,845-894 |
| Main-menu windows (action strip) | 46u (30u buttons + 8u pad x2), pad-x 10u, gap 8u; theme footer 14u beneath | surf2 + **1px `borderS` hand-drawn** (not `drawDividerH`) | Lib via `MM.drawBtn` (ZeD_MainMenu.lua:877-907), 30u, pad 16u, F3; disabled = 0.38 fade; hover 0.22 / focus 0.55 | Back/secondary left, primary right; confirm = question text F2 left + Cancel + verb right | ZeD_MainMenu.lua:77-85,1631-1678,1942-1949; shared `stripSpecs` ZeD_MainMenuSaves.lua:46-103 |
| Animals tab | `FOOTER_H` 32u, pad 6u | **no fill**, weak divider only | Hand `drawBtn`: single rounded outline in variant colour, F5, 22u, width text+16px, hover = 0.1 tint, neutral = dim text; no disabled state | left-aligned + F3 hint text; confirm: Yes (green) No (red) [Cancel] + "Remove zone?" | AnimalsTab.lua:100,387-428,911-954,3166-3231 |
| Mechanics tab | `FOOTER_H` 32u, pad 8u | no fill (red 0.12 wash only while confirming), weak divider | Lib `drawButton` via `footerButton`, 22u, F3, width text+18px; labels passed upper-cased; no hover fill | left-aligned; status line = dot + text after the buttons; confirm: Yes (danger) / No + dot question | MechanicsTab.lua:48-49,893-900,1285-1304,1600-1642 |
| Object cards | 32u status or confirm (grows to 2 lines) | surf2 + **1px `borderS` hand-drawn**; red 0.12 wash on alarm/confirm | Hand `UI.button`, flat bevel, square, F1, 22u, pad 8u; no hover fill | confirm buttons right (Cancel, then verb as **primary**); status = dot + F2 line (only the Lock card uses `def.status`) | ObjectCards.lua:896-911,960-1002 |
| Item card verb strip | bottom band `22u + 2 x max(8u, 0.7 x F1)` | surf1 band, **no divider** | Lib `drawCardVerbStrip`: surf2 + 1px `T.border` rect, square, F1, 22u, pad 10u, optional glyph | right-aligned; no confirmations | ItemCardOrganism.lua:1204-1251; Molecules.lua:2328-2381 |
| Craft/Build action strip | 42u | strong divider on top, **no fill** | stepper (rounded 1px, F3, 22u) + max readout + full-width CTA: accent 0.15 wash + rounded 1px accent border, **F4**; disabled = dim border | qty left, CTA fills the rest | Molecules.lua:3325-3390; CraftingCore.lua:2226-2243 |
| Container controls row | 28u, pad 7u, gap 5u | surf2 + strong divider | `UI.button` (bevel), 20u, icon or text; hover 0.22 accent added by the row | scrolling ribbon; confirm = row swap: red 6u **square** dot + "Delete all N items for good?" + Cancel + Remove all (danger) | ContainerControls.lua:46-51,685-691,793-814 |
| Map side-list ask | 14u + lines + 28u | surf2 + 1px `borderS` | Lib `drawButton` 22u, pad 20px: Cancel + Delete (danger) | right | MapsTabExt.lua:445-469 |
| Car radio / siren / two-way (pad strip) | 14u, only when a pad is active | surf2 + **full 4-side `drawRectBorder`** | none; `drawGlyphPrompts` left-aligned | n/a (props) | ZeD_CarRadio.lua:258-271; ZeD_SirenController.lua:180-187; TwoWayFull.lua:141-153 |
| Two-way face footer | hardware brand bar | chassis colours | none | prop (exempt) | TwoWayFace.lua:423-452 |
| Wheel prompt chip | 24u in a bordered chip | surf1 0.92 + `A.drawBorder` | none | centred under the wheel | ZeD_Wheel.lua:340-350 |

**Observations for the footer mockup**
- Three prompt placements: window footer right-aligned with squares (Organisms.lua:495), separate 14u strip left-aligned (`drawGlyphPrompts`, Molecules.lua:4159), or none (Reader, Station pop-out, Keyboard, Workshop, DescEdit).
- Strip presence: always (Messages, Seat chooser), pad-only (Prompt, radios), absent (Reader).
- Divider: weak `drawDividerH` (Window, Prompt, Messages, Seat, Reader, Animals, Mechanics), strong `borderS` by hand (MM strip, ObjectCards), strong `drawDividerH` (Craft, ContainerControls), none (Item card strip). The groove is used by no live footer (only the dead path).
- Fill: surf2 (most), none (Animals, Mechanics, Craft strip), surf1 (Item card strip).
- Button height 20/22/24/26/30u; pad 6-16u; gap 6-12u; font F1/F3/F4/F5.

**Proposed standard:** the Prompt/Messages/Seat shape (40u surf2 band, weak divider, 24u library buttons, secondary left of main, main last at the right) plus the window's 14u theme/prompt bar below it. Call sites that would change: MM action strip (46u/30u buttons, hand border), Animals, Mechanics, ObjectCards confirm/status, ContainerControls row, Craft strip, Item card verb strip, Reader strip (add prompts), Station pop-out and Keyboard (squares), map side ask, radio strips (border style).

---

## 3. Headers inside content

| Variant | Look | Where | Lib/Hand |
|---|---|---|---|
| Pinned tab header | 37u, **F4** `textHead`, triangle atom, no fill (drawer bg), strong divider full width | Health 1337, Thermal 341, Identity 726, Skills 1161, Equipment "Equipped" EquipmentTab.lua:1414, Traits `ModSupport/traitsAsSkills.lua:739`, SPNCC.lua:948 (no arrow), pause "Paused" ZeD_MainMenu.lua:1850 (here with a surf2 band painted first) | Lib `drawTabHeader` Molecules.lua:1331 |
| Tab-top look-alikes at 37u | Crafting/Building static header (dropdown + search, strong divider, no title) CraftingCore.lua:1126-1235; Maps toolbar 37u (chevron + icon buttons) MapsTab.lua:1078-1269; Radio and Mechanics drawer header (browse arrows + accent pill + sans subtitle) Molecules.lua:4051-4146; Object card header (back, icon, F4 name, pill, browse) ObjectCards.lua:807-845; Item card back bar 37u/30u Molecules.lua:2126 | Hand/Lib mix |
| Section header (library) | strip surf2, strong divider, F1 `textHead`, triangle, count right (`accentDim`) or inline; default height `rowH` 30u | Crafting categories 15u inline count (CraftingCore.lua:1484,1878,2090,2131,2186), Appliance 15u (StationAppliance.lua:614), Mechanics/MechTrailer 22u (MechanicsTab.lua:1443), MM Saves 22u (ZeD_MainMenuSaves.lua:568), Server 24u, Options/Traits 26u, Animals roster 30u **F4** (AnimalsTab.lua:3075), Equipment defense 37u F4 (EquipmentTab.lua:427, body-only path) | Lib `drawSectionHeader` Molecules.lua:1252 |
| Category row "v NAME (n)" | 15u, surf2, F1 `toneLo`, text "v "/"> " (not the triangle atom), weak divider | InventoryRenderer.lua:1660-1670 and grid 766, Equipment group EquipmentTab.lua:520-560, Animals `drawCatHeader` AnimalsTab.lua:1123-1155 (20u) | Hand x3 |
| Hand-rolled disclosure | Foraging "More detail" 22u, 6u triangle, F1 `toneNorm`, weak divider, hover surf2 (ForagingTab.lua:890-938); Foraging sub-headers 16u top+bottom weak dividers, F1 `toneLo`, count F3 (1005-1031); Journal kills disclosure on a stat row (JournalTab.lua:750-778); Journal month group header `max(F1+10, 26u)`, F1 `toneLo`, count `(n)` F3 `textCat`, thin divider (840-880); Animals "Alerts/Totals" per its own comment | Hand |
| Sub-tab strip (System 6 tabs) | `T.tabH` 24u/28u, F1, active = surf1 fill + open bottom, **active and inactive text both `toneNorm`** | Journal JournalTab.lua:512-616, Animals AnimalsTab.lua:1013-1071 (copy of the same code); library `M.drawTab` (Molecules.lua:288, F2, accent text when active) and `ZeD_TabPanel` (Organisms.lua:1302, F5) are unused | Hand x2, Lib unused |
| Sub-view pills | A.drawPillButton F1 (AtomExtensions.lua:324), square-ended map style pills (MapsTab.lua:1214-1244), joined icon pair List/Doll 26x20u (EquipDoll.lua:565) and List/Grid 22x18u (InventoryRenderer.lua:540) | mixed |
| Breadcrumb / back | Animals breadcrumb: left triangle in accent + F5 label, 20u (AnimalsTab.lua:1077-1114); Crafting alt-back strip: 20u accent-tinted, triangle + "Recipes" + centred count + dot toggle (Molecules.lua:2809-2861); sort strip 20u (2727-2800) with dot toggle; Item card "<" bevel button 22u (2143-2159); Object card "<" via `UI.button` 22u (ObjectCards.lua:812); MM windows: "Back" library button in the strip | mixed |

**Outliers**
- Three "v NAME (n)" copies draw `"v "` text instead of `A.drawTriangleDown` and use F1 `toneLo`, while `drawSectionHeader` uses triangle + `textHead`: the same disclosure reads differently in Inventory/Equipment/Animals vs Crafting/Mechanics (hover is also inconsistent: `T.text` 0.06 in Inventory/Animals vs `T.hover` RGB at 0.06 in Equipment, EquipmentTab.lua:535-536).
- Heights in use for "a heading row": 15, 16, 20, 22, 24, 26, 30, 37u.
- `drawTabHeader`'s `hovered` argument is accepted and ignored (Molecules.lua:1331-1366): no hover on any pinned header.
- `drawDrawerInternalHeader`'s comment says 22u but draws 37u (Molecules.lua:4023 vs 4059); its browse buttons are `flat` square buttons (4100-4117), unlike the bevelled `<` `>` on Item and Object cards.

**Proposed standard:** `drawTabHeader` for pinned 37u heads; `drawSectionHeader` for every collapsible row, with one category height (15u) and F1; make the inventory-style "v NAME (n)" a molecule built on the same atom triangle. Call sites that change: InventoryRenderer, EquipmentTab group rows, AnimalsTab `drawCatHeader`, Foraging disclosure and sub-headers, Journal group/kills, Journal and Animals sub-tab strips (move to `M.drawTab`), Object card header (use `drawCardBackBar`).

---

## 4. Buttons and pressable controls

### 4A. Button drawers

| Family | Look | Where | Lib/Hand |
|---|---|---|---|
| **A. Double rounded outline** | `A.borderDoubleRounded` (corner rows 2u,1u), transparent inside, F3 centred, `btnCase` at draw. default = `borderS`/`text`; primary = accent border + `accentText`; danger = red border/`dangerText` **plus pulsing red fill**; optional `colors.fill` (0.22 hover / 0.55 focus) and `keepCase`; "flat" variant = hardware square. **No disabled state** (callers fake it) | Molecules.lua:48-119. Callers: Prompt 951, Messages 321/349, Reader 370/393/860, SeatChooser 489, Main menu `MM.drawBtn` ZeD_MainMenu.lua:877, JournalReaders.lua:85, Hair 1300, EquipmentTab 832, StationMachine 419/460/498, StationAppliance 525, CraftingCore 2072, Mechanics `footerButton`, MechTrailer `smallBtn`, Keyboard 386, map side ask, `ZeD_Button` child (Journal Save, ZeD_CharacterWindow.lua:4081) | Lib |
| **B. Flat bevel, square** | filled rect (surf3/surf2; accent when primary), 1px light top-left (surf4/accentBright) and dark bottom-right (`borderS`), F1, 22u (card back bar 20u compact), pad 8u, danger = pulsing red fill with `T.danger` text (ObjectCards) or `dangerText` (card bar), disabled = 0.35 alpha, focus = 0.55 accent over everything, **no hover fill** | `UI.button` ObjectCards.lua:235-266 (Object cards, Furniture FurnitureTab.lua:442,510,603, ContainerControls 758, EquipDoll layer strip 628); `drawCardBackBar` verbs Molecules.lua:2166-2210 (Item card, Mechanics part card 1404, MechTrailer 1074) | Lib, two copies of the same look |
| **C. Flat 1px border, square** | surf2 fill, `T.border` (weak) 1px border, F1, 22u, pad 10u, optional glyph, 0.35 under progress | `drawCardVerbStrip` Molecules.lua:2328-2381 | Lib |
| **D. Single rounded outline in colour** | `A.borderRounded` (1px), border and text in variant colour (accent/positive/danger/neutral), F5, 22u, hover 0.1 tint, **no disabled**, no double outline | `drawBtn` AnimalsTab.lua:389-428; Qty stepper Molecules.lua:3269-3314; Craft CTA Molecules.lua:3363-3374 (accent 0.15 wash, **F4**) | Hand x2 + Lib |
| **E. Square ghost buttons** | 1px `T.border` at 0.3 alpha (0.6 accent + 0.2 wash when on), F1/icon, 20u, dim wash 0.6-0.65 when unavailable, **no hover** | MapsTab `_drawIconBtn` 1032-1076, "Aa" 1145-1167, style pills 1227-1241, unfold 1248-1269; MapsTabExt `drawBtn` 114-151 (also 45% border) | Hand |
| **F. Pill (1px-cut rounded)** | surf1 base, accent 0.10/0.15 wash + 0.4/0.6 border, **text left-aligned at `sp.sm`**, disabled = `borderS` + `toneLo`; `+` `-` squares use the same pill so their glyph is off-centre (possibly) | `A.drawPillButton` AtomExtensions.lua:324-354; HealthTab 891,913,938,945; ThermalTab 395; JournalReaders.lua:287,758 | Lib |
| G. Joined icon pair | two squares sharing an edge, selected = accent fill + `accentBright` border + `textOnAccent` icon | EquipDoll.lua:565-601 (26x20u, 13u icon); InventoryRenderer.lua:540-567 (22x18u, 11u icon) | Hand x2 |
| H. Icon square | 22u surf2 0.92 + `borderS`, 14u icon, hover wash + a **hand-rolled hint** | StationAppliance.lua:582-604 (pop-out) | Hand |
| I. Black/white default button | white fill, black cut-corner 1px outline, heavy ring on the default, F2, pure B/W | PostDeath.lua:223-260 | Hand, deliberate |
| J. Header pill/arrows | 24u `flat` arrows + accent solid pill | Molecules.lua:4098-4117 | Lib using A's flat |
| K. Status tags (not pressable) | `A.drawBadge` tinted fill + border, uppercase, F3 (Atoms.lua:400); `UI.tag` border only, 16u, F1 (ObjectCards.lua:274-285); `drawStatusChip`, `drawDock`, `drawFlagChip` | mixed |

Label case: everything in A-F goes through `ZeD.btnCase` at draw (Molecules.lua:78, 2173, 2346, AtomExtensions.lua:327, ObjectCards.lua:238, AnimalsTab.lua:394). Widths are measured inconsistently: Mechanics `footerButton` measures the **upper-cased** label before `btnCase` (MechanicsTab.lua:895; all its callers pass `upper(...)`), so its buttons are wider than the sentence-case text (possibly visible).

Fills: library = caller-supplied 0.22 hover / 0.55 focus (Prompt, Messages, Reader, MM, Seat, JournalReaders); B has focus only; D 0.1 hover; E none; Mechanics `footerButton` focus only (MechanicsTab.lua:733-743). The 0.55 focus wash is painted UNDER the button with the label switched to `textOnFocus` in the library (Molecules.lua:102-107) but OVER the finished button with the old label colour in Mechanics, ObjectCards (263), Appliance (StationAppliance.lua:526) and the map toolbar, so the label dims differently.

Disabled looks (11): 0.38 fade by swapping `T.borderS/T.text` (ZeD_MainMenu.lua:892-898, ZeD_Prompt.lua:953-959); 0.35 alpha (B, C); 0.6 surf2 wash over a primary (Hair 1302); flat transparent + dim text 0.5 (MechTrailer.lua:541-545); pill `borderS`/`toneLo`; Craft CTA dim border 0.5; JournalReaders text `textDim` only (ZeD_JournalReaders.lua:93-95); 0.65 surf1 wash (MapsTab.lua:1024); 0.6 wash (MapsTabExt.lua:143); stepper border 0.3; Black/white GREY.

### 4B. Toggles, switches, steppers, sliders

| Control | Look | Where |
|---|---|---|
| Checkbox | accent filled square with X when on, else surf2/hover; 13u/15u; `borderS`/accent border | Lib `A.drawCheckbox` Atoms.lua:351: Prompt 1058, Messages 345, MM Options 1204, Mods 1186/1286, Join 526, SPNCC 673/786 |
| Checkbox look-alike | 12u hollow square, inner 6u `accentBright`, no X | MapsTabExt.lua:395-403 |
| Dot toggle | 6u status dot + label, positive/accent when on | Molecules.lua:2784-2796, 2845-2858 (Crafting strips) |
| On/off switch | square-ended track with sliding knob + "ON"/"OFF" word, 44u-ish | ZeD_MainMenuOptions.lua:1105-1122 (ZeD setup only) |
| Segmented / swatch chips | accent chips with name | ZeD_MainMenuOptions.lua:1040-1056 |
| Stepped slider | 6u track, 12x18u thumb, ticks, labels under steps | ZeD_MainMenuOptions.lua:1058-1103 |
| Map slider | 4u track, 8x12u accent thumb with black border, default tick | MapsTabExt.lua:231-261; ModSupport/MapSymbolSizeSlider.lua |
| Fluid/Placement sliders | card sliders (hardware-ish) | ObjectCardFluid.lua:527-571; ObjectCardPlacement.lua:157 |
| Stepper | `[-] n [+]` rounded 1px, accent-wash readout, 22u (Molecules.lua:3269); Prompt `-`/`+` are library buttons (ZeD_Prompt.lua:1052); Health minutes use pills (HealthTab.lua:938-945) |
| Dropdown | lib `ZeD_Dropdown` (Molecules.lua:1021); Crafting category = hand surf2 box + 5u triangle `textSec` (CraftingCore.lua:1204-1223); station selects `ST.drawSelect` (Stations.lua); MM combos 8u triangle `textDim` (ZeD_MainMenuOptions.lua:1177,1192, Host 190, Looks 219, Sandbox 396, Saves 745) |

**Proposed standard:** Family A for every text button; Family B only inside card back bars/verb bars (and give it a hover fill and a `disabled` look equal to A's), retire C and D (Animals, Craft CTA, qty stepper to A/"primary"), E becomes an icon-button molecule with hover, F gets a centred label for square use. Call sites that change: AnimalsTab (all `drawBtn`), Craft strip, ObjectCards/Furniture/ContainerControls/EquipDoll (add hover), Mechanics `footerButton` (no upper-case, add hover), HealthTab/ThermalTab pills, MapsTab toolbar, Hair disabled overlay, MapsTabExt checkbox, one dropdown look.

---

## 5. Confirmations and destructive actions

| Pattern | Question wording | Answers | Danger styling | Where |
|---|---|---|---|---|
| Footer swap, question left | "Delete %1? It cannot be undone.", "Quit Project Zomboid?", "Delete the preset %1?", "Keep the changes to your mods?" | Cancel + verb (Delete/Reset/Exit = `danger`; Save/Rename/Keep/Discard-on-Options = `primary`) | Delete/Reset/Exit/Remove = danger; Save/Rename/Keep/Load/Upload/Connect = primary; Discard is **primary** at ZeD_MainMenuOptions.lua:1702,1708 and **danger** at ZeD_MainMenuServer.lua:1112; SandboxInGame "Undo changes" primary at ZeD_SandboxInGame.lua:509 | main-menu windows, e.g. ZeD_MainMenuSaves.lua:497-523, Host 315-324, Join 896-918, Looks 522-535 |
| Footer swap in game | "Remove zone?", "Create this zone?" | **Yes (green) / No (red)** [Cancel] | positive/danger colours inverted | AnimalsTab.lua:3201-3210, 928-939 |
| Footer swap | "Smash the %1? The glass is lost.", "Take engine parts? ..." | Yes (danger) / No on a red 0.12 footer | pulse | MechanicsTab.lua:1600-1620 |
| Footer swap, card | "Dig up the %1? The crop is lost.", "Take the campfire apart? ...", "Pour %1 of %2 out ...?" | Cancel + the verb label as **primary** (not danger) on a red 0.12 wash and red dot | the verb button that starts it is danger; the confirm is not | ObjectCards.lua:896-903,960-991; verbs ObjectCardFire.lua:264, Farm 300, Fluid 313, Trough 204 |
| Footer swap, Reader | "Erase page N? Its words cannot be brought back." | Keep it / Erase (danger) | pulse | ZeD_Reader.lua:865-875 |
| Row swap | "Delete all N items for good?" | Cancel + Remove all (danger) | pulse; square red dot | ContainerControls.lua:685-691,803-812 |
| Side-list footer | "Delete the notes %1?..." | Cancel + Delete (danger) | pulse | MapsTabExt.lua:445-469 (the "x" row button is a 16u hand box) |
| Pop-up window | any vanilla question; 14 "costly" ones get the stop sign + red answer | No / Yes (Yes = `danger` if costly) | pulse | ZeD_Prompt.lua:104-119,1106-1112 |
| In-place alert | "Are you sure?" | Cancel / Shut down (default ring) | none | PostDeath.lua:344-399 |
| Unused modal | overlay + title bar + 90u buttons | `ZeD_Modal.show` has **no callers** | danger variant | Organisms.lua:1546-1659 |
| None | JournalTab "x" deletes an entry instantly | n/a | text-only "x" | JournalTab.lua:924-940; ZeD_CharacterWindow.lua:2587,4857 |

Negative answer words in use: Cancel (most), No (Prompt, Animals, Mechanics), Keep it (Reader), Back (SandboxInGame, ZeD_SandboxInGame.lua:498), Keep editing / Go back (Options 1701,1714), Discard (DescEdit 454, Workshop 720). Order: negative then positive at the right everywhere except Animals zone-create (Yes, No, Cancel left to right).

**Proposed standard:** footer swap with the 40u band; "<Verb> <thing>?" question in F2 with one dot, `Cancel` + the verb as the only two answers, `danger` whenever the action cannot be undone (the pulse), `primary` otherwise. Call sites that change: Animals (positive/negative colours and Yes/No), ObjectCards confirm button, Mechanics (Yes/No to Cancel + verb), Options/Sandbox Discard variants, Journal "x" (add a swap), the map "x" button.

---

## 6. NEEDS lines and disabled reasons

| Surface | How an unmet requirement shows | Where |
|---|---|---|
| Object cards | hollow ring + F1 `textDim` paragraph under the verbs, e.g. "Sow: needs seeds \| ..." (UI.needs); the unmet verb is also drawn faded 0.35 | ObjectCards.lua:456-462; ObjectCardFarm.lua:253-315,544; Fire 197,347; Hook 423; Power 307 |
| Lock card | `UI.section` header "NEEDS \| LOCK" (F1 `textDim`, rule under) + dot rows | ObjectCardLock.lua:629-640 |
| Mechanics tab | section "NEEDS \| <verb>" with dot rows (positive/warning/danger) and right-aligned kicker + value, a success/failure bar, plus the footer line "Can't <verb>: <blocker>" in `danger` | MechanicsTab.lua:1533-1569,1600-1642 |
| Mechanics/Trailer rows | disabled `smallBtn` still takes focus, reason beside it | MechTrailer.lua:533-550 |
| Crafting/Journal recipe | red **badge** "NEEDS <station>" in the chip row + an accent-tinted box (sentence text, nearest distance, inline "Use <station>" library button) | CraftingCore.lua:2042-2075; Stations.lua:324-326 |
| Item card | button stays live; pressing it makes the character say the reason (halo note) | ItemCard.lua:340-361 |
| Map | tools greyed 0.65 and the reason as a halo "bad text" on press | MapsTab.lua:144-156,1024-1027 |
| Hair and Beard | disabled primary button (0.6 wash) with a dot/ring row and the reason in F5 beside it, rows folded under "Out of reach" | ZeD_HairBeard.lua:1295-1319 |
| Notebook | grey button + inline message under the field | ZeD_JournalReaders.lua:812-815 |
| Main menu Saves/Mods/Host | faded button; the reason appears in the details pane (possibly also in the strip) | ZeD_MainMenuSaves.lua:276,494,752 |
| Foraging | locked categories dimmed 0.45 with a "locked" count | ForagingTab.lua:957-958 |

Wording: "needs X" (Farm/Fire/Power lowercase, verb-prefixed), "NEEDS X" (Fire tag, Lock, Veh, Craft badge), "Needs a X." (Stations), "Can't X". Glyphs: hollow ring, dot rows, red badge, box, halo.

**Proposed standard:** the Object-card "NEEDS | thing" ring line under the verbs, wording `NEEDS | <thing>` only; the faded verb carries it. Call sites that change: Mechanics NEEDS section and footer text, Lock card section, Crafting badge + box, Hair row, Item card halo-only, Map halo-only.

---

## 7. Top 15 cohesion problems (most visible first)

1. Four unrelated button families (double-rounded outline, flat bevel, single rounded colour outline, square ghost): Molecules.lua:48, ObjectCards.lua:235, AnimalsTab.lua:389, MapsTab.lua:1032.
2. "Primary" means different things: outline (Molecules.lua:89-91), solid accent bevel (Molecules.lua:2181, ObjectCards.lua:244), tinted rounded (Molecules.lua:3363), solid pill (Molecules.lua:4105).
3. No common action footer: heights 14/32/40/42/46u, three fills, four dividers: Organisms.lua:152, AnimalsTab.lua:100, MechanicsTab.lua:48, ZeD_Prompt.lua:47, ZeD_MainMenu.lua:1632, Molecules.lua:3325.
4. Controller prompts in three places, always-on vs pad-only vs missing: Organisms.lua:495, ZeD_MessagesWindow.lua:133, ZeD_Prompt.lua:713, ZeD_Reader.lua (none), StationPopout.lua (none).
5. Windows without the theme/accent/text-size squares: Prompt, Keyboard, Messages, Reader, Seat chooser, Station pop-out (themeFooter false at ZeD_Prompt.lua:255 etc.).
6. Confirmation answers and danger styling differ per surface (primary vs danger Discard, green/red Yes/No, verb-as-primary on cards): AnimalsTab.lua:3203-3205, ObjectCards.lua:973, ZeD_MainMenuOptions.lua:1702 vs ZeD_MainMenuServer.lua:1112.
7. Journal entries delete with no confirm while map notes, containers and zones do: ZeD_CharacterWindow.lua:2587,4857 vs MapsTabExt.lua:424, ContainerControls.lua:685, AnimalsTab.lua:3201.
8. Hover feedback exists on library buttons but not on Object-card, Furniture, Item card, Mechanics-footer or map-toolbar buttons: ObjectCards.lua:235-266, Molecules.lua:2166-2210, MechanicsTab.lua:893, MapsTab.lua:1032.
9. Eleven disabled looks (fade, wash, flat, dim border): ZeD_MainMenu.lua:892, ZeD_HairBeard.lua:1302, MechTrailer.lua:541, MapsTab.lua:1024, Molecules.lua:3379.
10. Heading rows in eight heights/looks; "v NAME (n)" text vs triangle section header: InventoryRenderer.lua:766, EquipmentTab.lua:554, AnimalsTab.lua:1142, Molecules.lua:1252, ForagingTab.lua:890-1031, JournalTab.lua:840-880.
11. Back/browse affordances: bevel "<" (Molecules.lua:2143, ObjectCards.lua:812), triangle+text (AnimalsTab.lua:1090, Molecules.lua:2830), flat arrows (Molecules.lua:4098), text "Back" buttons (ZeD_MainMenu.lua:1662).
12. Title bar content: tab name in title (Character) vs stats (World); character name replaced by bag name; ignored `icon`; alpha-0 dot hack: ZeD_CharacterWindow.lua:5912,5616,5572; ZeD_WorldWindow.lua:4681; ZeD_MainMenuSaves.lua:478.
13. NEEDS shown six different ways (ring paragraph, section header, red badge + box, footer line, halo, faded button): ObjectCards.lua:456, ObjectCardLock.lua:630, MechanicsTab.lua:1536, CraftingCore.lua:2044, ItemCard.lua:361, MapsTab.lua:145.
14. Four hover-hint implementations, two with a 2px black drop shadow and 450 ms delay, one stepped, one none: Atoms.lua:589-624, ContainerControls.lua:820-845, StationAppliance.lua:595-602, ZeD_MainMenu.lua:1485; plus `ZeD_Tooltip` (Atoms.lua:500) unused.
15. On/off controls: library checkbox, hand checkbox, ZeD-setup switch, dot toggle, pills, joined icon pair at two sizes: Atoms.lua:351, MapsTabExt.lua:395, ZeD_MainMenuOptions.lua:1105, Molecules.lua:2784, EquipDoll.lua:565 vs InventoryRenderer.lua:540.

Dead or unused library pieces worth deciding on: `ZeD_Modal` (Organisms.lua:1546), `ZeD_TabPanel` (1302), `M.drawTab` (Molecules.lua:288), `ZeD_Tooltip` (Atoms.lua:500), the `footerToggles` footer (Organisms.lua:375), `M.drawVerbStrip` (Molecules.lua:1832, no callers) and `M.drawActionStrip` (1747, only the dead footer), `ZeD_ItemGrid`/`ZeD_ScrollList`/`ZeD_ScrollPanel` (only Organisms.lua and the TextScale.lua class list reference them).

Shadows (rule says none): System 7 hard stepped shadow is used on menus/balloons/combo lists/wheel cells (AtomExtensions.lua:391; Molecules.lua:3524,3669,3727,3913; ZeD_MainMenu.lua:1229,1485; ZeD_Wheel.lua:228; ZeD_SeatChooser.lua:391; ZeD_MainMenuOptions.lua:1597) and a flat 2px 0.5-black shadow on hover hints (Atoms.lua:618, ContainerControls.lua:841); decide which of the two is the rule.

HUD props (belt chips, moodle thought bubbles, watch, dashboards) were not compared beyond a note: the belt uses a ZeD chip box (ZeD_Belt.lua:1448-1470), the moodle notice a thought bubble (ZeD_Moodles.lua:326); they differ from each other and from the window hints.
