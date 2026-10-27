# Audit C: cohesion of content conventions

Read-only code audit of `...\42\media\lua\client\ZeD\` (172 Lua files found on disk), `UI.json`, and the vanilla EN strings under `E:\Project Zomboid`. Nothing was rendered: "looks" are read from draw code, and I say "possibly" where a runtime value decides. Counts come from perl scans (scripts in the scratchpad), so treat them as about plus or minus 10%. All paths below are under `client/ZeD/` unless marked `UI.json` (`shared/Translate/EN/UI.json`).

**Headline.** The mod is clean on raw pixels, middle dots, literal fonts and translation keys. The drift is in small components: every new feature drew its own hover box, its own tag, its own segmented control, its own empty message and its own section head. The newest files also stopped using the `T.sp.*` rhythm tokens that Health, Thermal, Equipment, Skills and Identity use.

---

# Part 1: newest additions vs the established surfaces

## 1.1 Hair and beard (`ZeD_HairBeard.lua`) vs `IdentityTab.lua` and `EquipmentTab.lua`

Differs from Identity's Traits section and Equipment's group rows:

- **Section head.** Groove above, then F1 toneLo caps "HAIR AND BEARD" (862-865, 1176-1179). The next section on the same drawer, Traits, is an F4 toneNorm heading with the groove below it (`IdentityTab.lua` 554-559); Skills "Training materials" does the same (`SkillsTab.lua` 655-661). HairBeard used the style of Identity's sub-labels ("POSITIVE (n)", `UI.json` 1105-1106, F1 toneLo, `IdentityTab.lua` 525) as a section head.
- **Spacing.** Opens with `T.px(12)` / `T.px(8)` / `T.px(10)` (861-870); Identity uses `T.sp.beforeHead` / `headGap` / `afterGroove` (555-559). `T.sp.` count: HairBeard 3, Health 41, Thermal 26, Equipment 24, Identity 14.
- **Group header "CUT | Scissors | 3".** 22 units tall (`GH_H`, line 40), F5 toneLo caps (1066-1094). Equip group header is 15 units (`GROUP_H`, `EquipmentTab.lua` 89), F1 toneLo, `"v NAME (n)"` text prefix (552-556). The "Out of reach" header uses `drawTriangleDown/Right` at 5 units (1080-1085); Equip's inventory dialect uses the text glyphs.
- **Row.** 54 units tall with a 42-unit 3D figure (40-41); Equip rows are `T.rowH` (30 small, 34 Large, `Tokens.lua` 355/386). Selected row is a solid accent fill (1104); Equip's selection is `T.selectionA` 0.25 (`EquipmentTab.lua` 590). Hover 0.22 and focus 0.55 match the rest.
- **Tool dot.** Dot or ring at 8 units, dot to the left of the tool word (1125-1129). Correct pattern (dot + default text); size differs from the 6-unit dots on Equip rows (`EquipmentTab.lua` 667) and the 7-unit `A.drawStatusDot` default (`Atoms.lua` 454).
- **Mod tag.** F5 caps, outline in borderS, 14 high, text dim (1132-1141). The word is the first word of the mod's name uppercased (`modName(...):match("^(%a+)")`), not a translated string. Does not match any of the existing tags (see 2.4).
- **Greyed rows.** Name alpha literal 0.45 (1111) plus a veil (`AV_DIM`); the token is `T.disabledAlpha` 0.42 (`Tokens.lua` 59).
- **"Now > After" heads.** Captions "Now"/"After" are F5 toneLo, not caps (972-977), with a plain `">"` text glyph between the frames (979-980).
- **Current-state rows.** Label F1 sentence case ("Hair", "Color"), value F2 left-aligned at a 56-unit column (1005-1035). The stat role is a caps F1 label with an F3 right-aligned value (`M.drawStatRow`, `Molecules.lua` 1428-1478).
- **Length meter.** Three hand-drawn boxes (940-949); `A.drawSegBar` exists (`Atoms.lua` 322).
- **Hair (n) | Beard (n) switch.** Hand-rolled segmented control, F1, solid accent when active (1044-1064). A twin is hand-rolled in Traits (`traitsAsSkills.lua` 294-313, F5), the Maps style pills (`MapsTab.lua` 1212-1244, F1), and the Options "seg" (`ZeD_MainMenuOptions.lua` 964-985, F2). The library atom is `A.drawPillButton` (`AtomExtensions.lua` 324, used by Health, Thermal, JournalReaders).
- **Empty state.** Two sentences with a colon, F2 toneLo, wrapped (872-877, 1184-1188; `UI.json` 978-979). Identity's own is the one-label "No traits", F1 textDim (`IdentityTab.lua` 564).
- **Footnote under the list.** Wrapped F1 Mono sentences (916-918, 1192-1196; `UI.json` 998-999). Prose in the chrome font.
- **Action strip (1249-1330).** Busy bar is a hand-rolled 4-unit rect (1321-1326); the library has `A.drawProgressBand` (`Atoms.lua` 808, 7 callers). Button is `M.drawButton` at a fixed `T.px(26)` (1297), min 64; `T.buttonH` is 26 small and 30 Large (`Tokens.lua` 356/387), so it stays small in Large text. Second line is F5. "Hover a row for the game's hint." and "Focus a row: it shows here. A does it." (`UI.json` 988-989) are captions the rules would drop; the pad line hard-codes "A" while the glyph set is user-selectable.
- **Hover balloon `HB.balloon` (1336-1371).** Comment calls it "the ZeD hint style", but it is pad 8x5, F2 title in textHead, max 280. The hint box is pad 10x4 (`Atoms.lua` 609) and `ZeD_Tooltip` is pad 10x6 with F4/F2/F1 lines, max 250 (`Atoms.lua` 489-572). It waits 450 ms for hair rows (1374-1378) and trait rows (`IdentityTab.lua` 755) but has no wait when Traits-as-Skills calls it (see 1.2).

## 1.2 Traits tab (`ModSupport/traitsAsSkills.lua`) vs `SkillsTab.lua`

- **Row rhythm.** Row 26 units plus a 2-unit gap, fixed (56, 252-254). Skills rows are `F1 height + 8` with `T.sp.rowGap` 6 (`SkillsTab.lua` 848-851, 1090), so Skills rows grow with Large text and these do not.
- **Group header.** Collapsible row: triangle atom 5 units, F2 sentence-case toneLo, F1 "(n)", hover 0.22, rule beneath (340-358). Skills groups are non-collapsible, a caps name (made caps at `SkillsTab.lua` 180) in F2 toneLo with a 1-unit rule (1011-1020). Inventory dialect would be `"v NAME (n)"` F1 caps (`EquipmentTab.lua` 552-556).
- **Level square.** surf3 alpha 0.6 (selected: black 0.15) (382-387) vs Skills 0.25 / 0.12 (`SkillsTab.lua` 80-96). Level 0 uses toneLo (386) vs textDim x0.7 (90).
- **Progress fill.** Alpha 0.32 (376) vs Skills 0.45 (59-68). Same thresholds (0.4 amber, 0.75 red), but maxed is warning at 0.32 here and warning 0.55 full-row there (`SkillsTab.lua` 51-55, 1043). Both use red/amber/green for "how far", which is status colour on a fill (allowed).
- **Selection.** Solid accent (368); Skills marks a pin at 0.12 (1038).
- **Right side.** Status dot 8 + F2 trait text (447-451); "No trait" with ring (419-425); "NEW" F5 accent outline tag, 13 high (453-461). Skills' own mark is `A.drawBadge` F5 positive fill (`SkillsTab.lua` 103-120).
- **Top block.** Credit line "%1 by %2" in F5 toneLo (282-290) and an "All | With a trait" segmented control (294-313), then a summary "3 good, 2 bad, 4 with no trait" with 8-unit dots/ring (316-338). Skills has none of this. Polarity words differ inside one Character window: "good / bad" here, "POSITIVE / NEGATIVE" on Identity (`UI.json` 2232, 2240 vs 1105-1106).
- **Header.** `M.drawTabHeader` with no arrow and a Find field in the header (739-745); Skills' header is the fold disclosure (`SkillsTab.lua` 1161).
- **Detail panel (547-657).** Fixed 218 units: F4 name, F1 "Level n of 10" and "Category: x", ladder with F5 labels, F5 caps keys, F2 values, a hand-rolled 5-unit bar (626-627). When text does not fit, lines are dropped silently (613-619); there is no scroll. This is a second reading surface Skills does not have (it uses a hover card).
- **Wording.** "(the game gives this trait no description)" (`UI.json` 2250) is a chatty placeholder; "none" / "None" / "No trait" / "No trait at this level." (2251-2256) are four empties on one tab.
- **Hover.** Step balloon through `HB.balloon` with no delay (747-761).

## 1.3 Belt ammo pouch (`ZeD_Belt.lua`) vs the rest of the belt

- **Count font.** The rounds count is F4 Heading (1401-1403); EMPTY is F1. The stat role is F3.
- **Coloured text.** `B.ammoInk` sets the count to `dangerText` / `warningText` when low (1359-1366). Segments may carry colour; the number should be default text with a dot.
- **Words.** "2 MAG", "30 RDS", "+1 BOX" (`UI.json` 2839-2842) are caps abbreviations in F5 textDim (1404-1410); "RDS" is not the game's word. Slots show an F5 textDim slot name when empty (1189-1192), so the F5 grey is consistent.
- **Frame.** Shares `frameBox` with the slots (1142-1159, 1412); fill is always surf2 at 0.95 (1386) while slots go surf1 when empty (1170).
- **Meters.** Pouch = art-pixel segments, spent rounds hollow (1370-1443); slot condition = 3-unit bar (1227-1234); hands = ring. Three meter languages on one strap.
- **Hover.** `_chip2` (1448-1467): F1 accentText sentence ("9mm | 12 in the magazine") over an F3 sentence ("Carried: ..."), pad 6x3, surf1 0.95, no shadow, no delay. `_chip` (1470-1481) is one line of caps F1 accentText. Same chip family, caps in one and sentences in the other, with the data font for prose.
- **IN HAND / BOTH.** Plain F5 accentText with no frame (1221-1226) vs the outlined F1 IN HAND tag on the Equipment belt rows (`EquipmentTab.lua` 719-729, 833-836).
- **Messages note** on the same belt has a filled count badge F1 with `T.base` ink (1283-1293); nothing else on the belt has a count badge.

## 1.4 Maps: `MapsTabKey.lua`, `MapsTabExt.lua`, the map mods vs `MapsTab.lua`

- **Buttons.** Key panel "Show Survey" is hand-rolled, 20 units, F1, outline (`MapsTabKey.lua` 122-130); `Ctx:button` is 20 (`MapsTabExt.lua` 222); the delete-confirm Yes/No are `M.drawButton` at 22 (455-466); library `T.buttonH` is 26/30. "Show Survey" is Title Case; `btnCase` only converts all-caps (`Tokens.lua` 1107-1109), so it passes through (`UI.json` 1345).
- **Toolbar look.** Extension buttons: border alpha 0.45, text alpha 0.8/0.95 (`MapsTabExt.lua` 130, 141). Map's own icon buttons and style pills: border 0.3, pill text 0.7/0.9 (`MapsTab.lua` 1048, 1236-1239). Active state (0.2 fill, 0.6 border) matches.
- **Hint rule.** Key has a text label and a hint (`MapsTabKey.lua` 43-44; `MapsTabExt.lua` 147), so in the unfolded window a labelled button hints. The map's own icon-only pop-out and tool buttons have no hint at all (`MapsTab.lua` 1032-1076, 1246-1269), while the Radio drawer's identical button does (`RadioTab.lua` 1116-1121), with a different icon pair (`expand/contract` 1069 vs `crafting-game-037-map/compress` `MapsTab.lua` 1258-1259).
- **Key panel.** Hand-built mini window (stripes, close box, surf1 0.94, `MapsTabKey.lua` 65-100) instead of `ZeD_Window` chrome; its explanatory text is wrapped F1 Mono (72, 119; `UI.json` 1332-1333).
- **Side list (`MapsTabExt.lua` 346-444).** Section head F5 accent caps with an F1 textSec count (383-386); row dot is an 8-unit square with a raw dark-green border `0,0.2,0` (405-411); checkbox hand-drawn 12 units (396-402) instead of `A.drawCheckbox`; delete is an outlined 16-unit box with a lowercase "x" that turns danger-red on hover (420-431); row separator uses raw `0.09` grey (432); a `warn` line in `T.warning` text (418); the ask footer is wrapped F1 prose (361, 445-468). It scrolls by wheel only: no scrollbar drawn (377-379, 568-576).
- **POM.** Square marks in raw `{0,1,0}` and grey, names in black on grey (`POM.lua` 63-64, 143-147). Intentional to match the mod, but theme-blind.
- **Banner** (area name) is F3 on surf1 0.85 (`MapsTabExt.lua` 496-503); no other surface puts F3 on a title.
- **Empty.** "No learned notes. Use %1 on a paper..." F1 textSec wrapped (372, 435-441).

## 1.5 Skills extras and Skill Recovery Journal vs the skill rows

- **Lane.** 3-unit strip under each row, row grows 4 (`SkillRecoveryJournal.lua` 160-163; `SkillsTab.lua` 849-850, 427-448). Colours are the mod's raw RGB (`SkillRecoveryJournal.lua` 43-48), not tokens; possibly weak in Light and High contrast.
- **Key block.** F5 accent caps "SKILL JOURNAL" (210), a 7-unit square drawn with `drawRect` (218-223), swatches 10x4 flat bars (245). The Skills tab's own training legend uses `A.drawLegendSwatch` 8x14 blocks (`SkillsTab.lua` 676, 734, 764). A groove closes the block (251).
- **Hover card (`SkillsTab.lua` 453-518).** surf2 0.98, shadow, w 250, pad 10; title in **F3**, F1 level line, a **groove inside a card** (495), F5 accent caps label (498), 10x4 colour bars (505-508), F2 lines, F1 values and note. No delay. A third hover look next to the balloon and the hint box.

## 1.6 Read marks (`ReadMarks.lua`) vs other row marks

- **Dot.** Own 7-art-pixel dot with three fills: ring, half, full (228-231, 275-281). Elsewhere the dot atoms draw a round dot or a ring at `T.px(6-8)` (`Atoms.lua` 453-501); the half-filled dot exists only here.
- **Colour meaning.** Unread and part-read use accentText, read uses positive (270-273). Accent elsewhere means selected/active; a row at accent 0.36 selection with an accent dot is possibly hard to read.
- **List.** In the COND column: dot + F3 sentence-case word ("Not watched", `InventoryRenderer.lua` 840-854); the column otherwise holds the 3-unit condition bar (1597-1620).
- **Tags.** NEXT LEVEL in lists is the same outlined accentText F1 tag as BELT n (`InventoryRenderer.lua` 1555-1584; `EquipmentTab.lua` 719-729): consistent. In the grid, BELT n is a solid accent F5 square (621-632) while NEXT LEVEL is a 5x4 pixel arrow with raw black outline (`ReadMarks.lua` 283-291); list and grid disagree.
- **Hover (`InventoryRenderer.lua` 807-836).** surf1, shadow, pad 8x4, F1 title and F3 prose lines. The grid's plain name hint sits 50 lines below in the same file as surf2, F2, pad 10x4 (873-884).
- **Dim read items.** Alpha 0.5 (595, 1516) vs `disabledAlpha` 0.42.

## 1.7 ZeD setup switches (`Settings.lua`) vs the Options screen

- All five new switches share `onSwitch` (`Settings.lua` 360-380) and draw as the existing ZeD switch: square track, sliding knob, caps "ON"/"OFF" in **F2** (`ZeD_MainMenuOptions.lua` 1105-1123). Vanilla options keep checkboxes (1194-1211), the Messages footer has a checkbox (`ZeD_MessagesWindow.lua` 345), and the in-game Sandbox shows "On"/"Off" sentence case (`ZeD_SandboxInGame.lua` 248). Three on/off forms and two spellings.
- Safe mode paints "ON" in `T.danger` text (`ZeD_MainMenuOptions.lua` 1120-1121): coloured status text.
- Names: mixed grammar, noun phrases ("Safe mode", "Ammo on the belt") and verb phrases ("Show a toast when one comes", "Put things back after an action"); "NEXT LEVEL on skill books" puts a caps tag mid-sentence (`UI.json` 2879); "Same as Accent" (Options 1813) vs "Same as Accent color" (Settings 2153).

## 1.8 Messages, Sandbox in game, two-way radio, Character info, dashboard chip

- **Messages window (`ZeD_MessagesWindow.lua`).** List section heads F1 accent caps (259-262). Row dot: accent for unread, danger for errors, hollow *square* for read (270-274). Kind tag: outlined F1 in danger/warning/info text (296-302). Secondary text is T.text at alpha 0.7-0.8, not a token (280, 284, 304, 312, 327, 333). Help line is an F1 sentence (333) and the empty text near-duplicates it (`UI.json` 1703 vs 1711). Cards scroll by wheel only (440); no scrollbar. Buttons are `BTN_H` 24 (34) and drawn by `M.drawButton`. Toasts: surf-base 0.92 with a status-coloured border and a status-coloured F1 head (580-615).
- **Sandbox in game (`ZeD_SandboxInGame.lua`).** Row tags use `A.drawBadge` with F1 (619-631): seven fill colours across five WHEN and two RISK words on one settings screen (`UI.json` 2667-2672, 2685). Help band heads accent F1 caps (676) with coloured warn lines in F2 (687, 753-754). Page-change dot is 7 (585) while Messages/HairBeard use 8. Revert has three names on the same screen: "Put back", "Undo changes" (`UI.json` 2656, 2664), and "Discard" (Options).
- **Two-way radio.** Footer is hardware F1, consistent with the AM/FM bar (`TwoWayFace.lua` 423-452). Its Full view button copies the map's pop-out size but shows a hint in the belt-chip style: F1, surf1 0.95, pad 6x3, no shadow, no delay (`RadioTab.lua` 1327-1333). Brand text is truncated by hand with "..." (`TwoWayFace.lua` 444-447) instead of `A.truncateText`.
- **`Overrides/CharacterInfo.lua`.** Pure routing (page names to tabs, 33-47; `toggleView` hook, 97-117): it draws nothing, so nothing to drift. Only check: it matches pages by translated game name, which is fine in any language the game translates.
- **Dashboard lamp chip (`ZeD_Dashboard.lua` 1074-1106).** Belt-chip family (surf1 0.95, F1, pad 6x3, no delay), but the colour roles are reversed: part name in text, detail in accentText; the belt's `_chip2` puts the headline in accentText and the detail in text. Doubles its border in High contrast (1103); the belt chips do not.

---

# Part 2: whole-UI census

## 2.1 Raw pixel literals

Result: very clean. Scanning draw/layout lines for integer `+/-` literals outside `T.px`/`T.line`/`T.sp`, excluding the pixel-art engines (Plate, Bubbles, RadioOps, WatchMini, PrintPage, ActionBar, Fishing, Sleeping, which work in art-pixel units on purpose): **225 hits in 50 files, of which 217 are 1-2 unit insets** (`w - 2`, `x + 1`: a border drawn one hairline in) and only **8 are larger**. 31 `drawRect` calls pass a bare integer width or height (mostly 1) (14 in the FocusManager debug HUD, 8 in `Atoms.lua` hairline helpers). The insets stay 1-2 screen px at root scale 2 instead of growing; low visibility.

| Rank | File | Hits | Sample |
|---|---|---|---|
| 1 | `ZeD_MainMenuOptions.lua` | 26 inset | 850, 867, 868 (`w - 2`); 1126-1127 `T.px` fine |
| 2 | `ZeD_Reader.lua` | 16 inset | 177, 186, 258; raw RGB `0.035,0.043,0.039` at 175, 764 (possibly paper, intentional) |
| 3 | `ZeD_Belt.lua` | 15 | 1153, 1156 (`frameBox` `o = 1`), 1262 |
| 4 | `ZeD_MainMenuMods.lua` | 12 | 1127, 1140, 1374 |
| 5 | `ObjectCards.lua` | 10 | 513, 615, 639 |
| 6 | `ModSupport/SPNCC.lua` | 10 | 628, 639, 678 |
| 7 | `ZeD_MainMenuModsPanes.lua` | 10 | 103, 170, 494 |
| 8 | `ZeD_MainMenuWorkshop.lua` | 9 | 469, 470, 517 |
| 9 | `MapsTab.lua` | 8 | 1056, 1185, 1197 |
| 10 | `Atoms.lua` | 8 | 116, 237, 706 |
| 11 | `Overrides/Tooltip.lua` | 4 larger | 206, 207, 322 (`+ 60` pad-mode offset), 313 |
| 12 | `Input/FocusManager.lua` | 6 | 852-853 (`cx - 4`, bare 8x1 cross), RGB literals |
| 13 | `ZeD_MainMenuLooks.lua` | 6 | 256, 257, 286 |
| 14 | `ObjectCardFarm.lua` | 5 | 357, 410, 478 |
| 15 | `ZeD_HairBeard.lua` | 4 | 820, 954-957 |

Other larger literals: `ZeD_Moodles.lua` 496 (`+ 120`), `Overrides/PostDeath.lua` 65 (`- 40`). Raw RGB in draw calls is rare (about 37 lines; top: `ObjectCardLock.lua` 9, `FocusManager.lua` 6, `ZeD_Reader.lua` 4, `Overrides/Fishing.lua` 4, `IdentityTab.lua` 3 for the licence ink). Spacing tokens: `T.sp.card*` are read only by `ItemCard.lua` (11 uses, in the height pre-measure); the live card (`ItemCardOrganism.lua`) uses 54 `T.px(n)` and 0 tokens; `T.sp.textLineGap` is unused. Button heights: library `T.buttonH` in 16 places, but fixed 20/22/24/26 in `MapsTabExt.lua` 222/455, `SPNCC.lua` 514, `ZeD_MessagesWindow.lua` 34, `ZeD_HairBeard.lua` 1297, `Molecules.lua` 2334, `CraftingCore.lua` 2070.

## 2.2 Font roles

Literal `UIFont.*` outside `PixelFonts.lua`: 21 uses, all legitimate (print-page paper fonts, entry-box fallbacks, debug HUD, `Overrides/TextScale.lua`). No action.

| Outlier | Used | Should be | Where |
|---|---|---|---|
| Rounds count | F4 | F3 | `ZeD_Belt.lua` 1401-1403 |
| Skill group names (caps) | F2 Sans | F1 Mono | `SkillsTab.lua` 996, 1011-1014 |
| Options switch word ON/OFF | F2 caps | F1 | `ZeD_MainMenuOptions.lua` 1119-1121 |
| Skill hover card title | F3 | F4 | `SkillsTab.lua` 491 |
| Read-hint lines, belt chip line 2 | F3 prose | F2 | `InventoryRenderer.lua` 812-813; `ZeD_Belt.lua` 1465 |
| Map area banner | F3 | F4 | `MapsTabExt.lua` 496-503 |
| Wrapped prose in F1 Mono | F1 | F2 | `ZeD_HairBeard.lua` 916, 1195; `MapsTabKey.lua` 72, 119; `MapsTabExt.lua` 361, 372, 452; `ZeD_MessagesWindow.lua` 333; `HealthTab.lua` 689; `ObjectCardLock.lua` 599; `SkillsTab.lua` 478-516 |
| Animals tab uses F4 as an all-purpose font (buttons, hints, badges, labels, empty) | F4 | F3 / F2 / F1 | `AnimalsTab.lua` 393, 889, 1209, 1221, 1398, 3040 |
| Button labels: F1 (Maps pills, Ext buttons, Key button), F3 (`M.drawButton`), F5 (Traits filter), F2 (Options seg) | mixed | F3 | `MapsTab.lua` 1239; `MapsTabExt.lua` 141; `traitsAsSkills.lua` 295; `ZeD_MainMenuOptions.lua` 975 |
| `A.drawBadge` default font F3, but callers pass F1, F4 or F5 | mixed | one font | see 2.4 |

F1 vs F5 as "small caps label": Equip column headers F5 toneNorm (`EquipmentTab.lua` 874-893), inventory category rows F1 toneLo, Messages/Sandbox heads F1 accent, Maps side/SRJ F5 accent, HairBeard group F5 toneLo. No one rule decides; the new surfaces split roughly evenly. Hard-coded English in drawing code: only `AnimalsTab.lua` 2059-2063 ("GENOME", "Animal cheats", possibly a cheat/debug panel); `RadioTab.lua` 914/925 are brand hardware. `ItemCard.lua` 48-160 holds about 80 English labels ("Broken", "Damage", "Raw!"), but they only feed the height pre-measure (`ItemCard.lua` 971-1016; `renderBody` draws, 1339), so likely invisible. All `UI_ZeD_*` keys used in code exist in `UI.json` or a `trDefaults` block; only constructed-prefix keys differ.

## 2.3 Coloured status text (should be default text + dot)

Verified sites (draw code reads a status token as text colour):

- `ZeD_Belt.lua` 1359-1366 rounds count (danger/warning text).
- `AnimalsTab.lua` 840-841, 845-846 (zone width/height red), 2670 ("Yes" in info), 2686-2688 (season positive), 2696-2706 (trust 3-colour), 2059-2062 ("GENOME" info).
- `ForagingTab.lua` 667-672 (net modifier green/red).
- `MechanicsTab.lua` 1558-1568 (success/failure % in positive/danger).
- `FurnitureTab.lua` 838-840 (line in danger).
- `Molecules.lua` 3147-3186 (missing ingredient name red), 3349-3352 (max qty 0 red), 3091-3093 (owned count green), 2986 (freq "xN" amber).
- `ObjectCards.lua` 394-397 (gain value green), 515 (danger).
- `StationAppliance.lua` 608-610 (warning line), 634-640 (coloured outline tag).
- `ZeD_MainMenuOptions.lua` 1120-1121 (Safe mode ON), 1447-1449 (moot note in warning).
- `MapsTabExt.lua` 418 (warn line), 427-428 (x turns danger).
- `ModSupport/SPNCC.lua` 750-756 (banner title).
- `ZeD_SandboxInGame.lua` 687, 753-754 (warn lines).
- `ZeD_MessagesWindow.lua` 296-302 (kind tag), 601-608 (toast head).
- `Organisms.lua` 1605-1610 (modal title in danger).
- `Atoms.lua` / `AtomExtensions.lua` 288: `drawStatusLabel(text, colour)` is a ready-made coloured-status-text atom with **no callers** (dead).

Correct examples to copy: `M.drawStatRowDot` (`Molecules.lua` 1489), moodle bubble (`ZeD_Moodles.lua` 379-383), HairBeard tool dots (1125-1129).

## 2.4 Badges, tags, chips: every look

| Variant | Look | Where |
|---|---|---|
| `A.drawBadge` | tinted fill + border + variant text, caps, default F3 (callers pass F1 / F4 / F5), padding 9x3 | `Atoms.lua` 400-445; `CraftingCore.lua` 2019-2046 (F3); `HealthTab.lua` 514, 1292 (F3); `SkillsTab.lua` 119 (F5); `ZeD_SandboxInGame.lua` 625-629 (F1); `MechanicsTab.lua` 1224 (F1); `AnimalsTab.lua` 1226, 1364... (F4/F5, caps-off) |
| State "pill": status-coloured outline, coloured text, 16 high, dot in front | F1 | `ObjectCards.lua` 274-285 (GROWING, EMPTY, FULL, UNLOCKED, KEY LOCK) |
| Accent outline marker, 1-unit border, pad 4, height F1+2 | F1 accentText | BELT n / NEXT LEVEL `InventoryRenderer.lua` 1555-1584; IN HAND `EquipmentTab.lua` 719-729 |
| IN HAND / BOTH on belt box | F5 accentText, no frame | `ZeD_Belt.lua` 1221-1226 |
| Key square: solid accent | F5 (grid), F1 (belt box and Equip rows), outlined dim "-" past slot 8 | `InventoryRenderer.lua` 621-632; `ZeD_Belt.lua` 1237-1246; `EquipmentTab.lua` 768-782 |
| Message kind tag: coloured outline + coloured text | F1, pad 4 | `ZeD_MessagesWindow.lua` 296-302 |
| NEW tag: accent outline, 13 high | F5 | `traitsAsSkills.lua` 453-461 |
| Hair mod tag: borderS outline, dim, 14 high | F5 caps | `ZeD_HairBeard.lua` 1132-1141 |
| Station tag: coloured outline, 14 high | F1 | `StationAppliance.lua` 634-640 |
| Count badge on the Messages note: solid accent/danger | F1, `T.base` ink | `ZeD_Belt.lua` 1283-1293 |
| Weight chip / "x2" count chip: surf1 0.92 | F5 accentText / F1 text | `InventoryRenderer.lua` 604-620 |
| Flag chips Fav / No-craft / Dispose (toggle, glyph) | 18 high | `Atoms.lua` 929; `Molecules.lua` 2242-2290 |
| Read mark: art dot + F3 word | | `InventoryRenderer.lua` 840-854 |

That is twelve looks for "a small word that names a state". DEAD and THIRSTY are plain uppercase text in summaries (`UI.json` 834 THIRSTY; "Hook_DeadNearby" 1040 is a section head), not tags. OUT OF REACH exists only as a HairBeard group head (`UI.json` 1001) and means "not available now"; the same words mean distance in Stations (`UI.json` 2195, 2207 "WITHIN REACH"). EQUIPPED as a badge exists only in the unused `ItemCard.lua` list (57). Casing: Animals tags are sentence case ("Door open", "Udder URGENT" mixed, `UI.json` 295-398), object-card pills are caps. Dot sizes: 4 (context), 6 (stat rows, Equip, Furniture, most object cards), 7 (the `A.drawStatusDot` default, SPNCC, main menu), 8 (HairBeard, Traits, Messages, Maps side list), 9 (main-menu large). Shapes: round (atom), square `drawRect` (`SkillRecoveryJournal.lua` 223, `MapsTabExt.lua` 408, Messages read state 274).

## 2.5 Empty states and placeholders

| Text | Case | Style | Where |
|---|---|---|---|
| INVENTORY EMPTY | caps | F1 textSec, centred | `InventoryRenderer.lua` 1705 |
| RECENT FINDS WILL APPEAR HERE | caps | F1 toneLo, centred | `ForagingTab.lua` 1110 |
| NONE NEARBY / NOTHING WITHIN REACH | caps | F1 textDim right / list head | `MechanicsTab.lua` 1475; `Stations.lua` 505 |
| No traits | sentence | F1 textDim | `IdentityTab.lua` 564 |
| No radio in range | sentence | F2 textSec, centred | `RadioTab.lua` 1260 |
| Coming soon | sentence | F1 textDim | `ZeD_WorldWindow.lua` 1902 |
| Coming later. | sentence + period | wheel item sub | `ZeD_DpadWheels.lua` 1070 |
| Nothing to place / Point at... | sentence | **F4** textDim | `FurnitureTab.lua` 372-377 |
| Nothing to read on you / None of these on you | sentence | F1 textDim | `ZeD_JournalReaders.lua` 301-302 |
| No mods match | sentence | F2 textDim | `ZeD_MainMenuMods.lua` 1166-1170 |
| No messages. / Notes and errors... land here. | sentence + period | F2 text at alpha 0.7 | `ZeD_MessagesWindow.lua` 284, 327 |
| Nothing to cut: ... It grows back over time. | 2 sentences | F2 toneLo wrapped | `ZeD_HairBeard.lua` 1184-1188 |
| Nothing matches "x". / Pick a row... | sentence | F2 toneLo | `traitsAsSkills.lua` 716, 558-560 |
| No learned notes. Use... | sentence | F1 textSec wrapped | `MapsTabExt.lua` 372 |
| "---" (empty slot), Empty (belt slot), Empty (appliance) | | F2 textDim | `EquipmentTab.lua` 626, 813; `StationAppliance.lua` 618 |
| (empty) | parentheses | | `UI.json` 2652 |
| Nothing to eat on you. etc. (wheel, 9 lines) | sentence + period | | `UI.json` 2493-2511 |

**Proposed pattern.** One line, sentence case, F2 Body in `T.textDim` (or toneLo; pick one), left at `T.sp.sm` inside the list, centred only when the whole pane is empty. State what is missing, no caps, no "(parentheses)", no period for a bare state ("No messages") and a period only when a second clause explains why. Hardware panels keep their caps.

## 2.6 Hover chips, balloons, tooltips

| Look | Frame / fonts / pad | Delay | Placement | Where |
|---|---|---|---|---|
| **Hint box** (the standard) | surf2, borderS, 2-unit shadow 0.5, F2, pad 10x4 | 450 ms | beside/above control | `Atoms.lua` 587-622; `ContainerControls.lua` 820-845; `InventoryRenderer.lua` 873-884; `MapsTabExt.lua` 519-537; `EquipDoll.lua` 52 |
| `ZeD_Tooltip` panel | surf2, borderS, no shadow, F4/F2/F1 lines, pad 10x6, max 250 | n/a | at mouse | `Atoms.lua` 489-572 |
| Row balloon `HB.balloon` | surf2, shadow, F2 title + F2, pad 8x5, max 280 | 450 (rows) / **0** (Traits step) | below, flips above | `ZeD_HairBeard.lua` 1336-1371; `traitsAsSkills.lua` 747-761 |
| Skill row card | surf2 0.98, shadow, F3 title, F1, groove, F5 accent, F2, pad 10, w 250 | 0 | beside row | `SkillsTab.lua` 453-518 |
| Read hint | surf1, shadow, F1 title + F3 lines, pad 8x4 | 450 | below row / above cell | `InventoryRenderer.lua` 807-836 |
| Belt chips | surf1 0.95, no shadow, F1 caps accentText (1 line) / F1 + F3 (2 lines), pad 6x3 | 0 | 6 above box | `ZeD_Belt.lua` 1448-1481 |
| Dashboard lamp chip | as belt, name text / detail accent, HC doubled border | 0 | above lamp | `ZeD_Dashboard.lua` 1074-1106 |
| Radio full-view hint | surf1 0.95, F1 text, pad 6x3, no shadow | 0 | below button | `RadioTab.lua` 1327-1333 |
| Moodle thought bubble | pixel cloud, dot + F4 name + F2 textDim desc, w 252 | 0 on hover, 4 s auto | trail to moodle | `ZeD_Moodles.lua` 326-390 |
| Toast | base 0.92, status border, F1 head | n/a | top right | `ZeD_MessagesWindow.lua` 580-615 |
| Item tooltip | bg token, borderS, F2 name accentText, F1 note | vanilla | follows mouse | `Overrides/Tooltip.lua` 150-250 |

Eleven looks, three timings. The 450 constant is declared six times (`Atoms.lua` 587, `ContainerControls.lua` 621, `EquipDoll.lua` 52, `InventoryRenderer.lua` 302, `ZeD_HairBeard.lua` 42, `ZeD_MainMenuDescEdit.lua` 33). Proposed: two classes, "hint box" (icon names) and "detail card" (rows; ZeD_Tooltip look); HUD chips over the world may keep the belt chip but share one pad/shadow/colour order.

## 2.7 Bars and meters

Library callers: `A.drawFillBar` 8, `M.drawFillBar` 4, `drawStatBarRow` 4, `drawSegBar` 5, `drawProgressBand` 7. Hand-rolled: the condition line exists at **2** (grid, `InventoryRenderer.lua` 645-650), **3** (list 1597-1620, Equip 642-661 and 821-831, belt slot `ZeD_Belt.lua` 1227-1234) units, HairBeard busy bar **4** (1321-1326), Traits detail bar **5** (626-627), plus Maps slider (`MapsTabExt.lua` 228-261), Skills lane (`SkillsTab.lua` 427-448), ammo segments and hands ring (`ZeD_Belt.lua`), HairBeard length boxes (940-949). Standard to move to: an `A.drawCondLine` shared atom (does not exist yet) for the five 2-3 unit sites, `drawSegBar` for the length boxes, `drawProgressBand` for the busy bar.

Scrollbars outside the library: `FurnitureTab.lua` 700-705 (thin rect thumb); no scrollbar drawn for `MapsTabExt.lua` side list, `ZeD_MessagesWindow.lua` cards, and the Traits detail panel clips (`traitsAsSkills.lua` 613-619). `AnimalsTab.lua` uses `drawScrollThumb` correctly.

## 2.8 Dividers

Groove (major break) used where a line is meant: between list rows `Organisms.lua` 1170-1175 and `ZeD_ZoneList.lua` 160-164; inside a hover card `SkillsTab.lua` 495; closing the SRJ key block `SkillRecoveryJournal.lua` 251. HairBeard places its groove above the heading (862) where Identity/Skills place it below (558, 660). Groove under container bar and footer top are fine (`InventoryRenderer.lua` 1935, `Organisms.lua` 382). Lines used for the SkillsTab group rule (1019) and the Traits category rows are correct.

## 2.9 Wording

- **Title Case that `btnCase` cannot fix:** "Show Survey" (`UI.json` 1345; `MapsTabKey.lua` 122). `btnCase` converts only all-caps strings with 2+ capitals (`Tokens.lua` 1107-1109). Other ZeD-authored Title Case are headings or vanilla names ("Training Materials", "Combat Facts", "All Recipes"), allowed.
- **Caps that are buttons:** none found in ZeD-authored buttons; all-caps strings are fixed by `btnCase` (EquipmentTab belt verbs, `UI.json` 784, 802).
- **Middle dot:** none in any Lua or JSON (searched for U+00B7, escaped forms, U+2022). Separators are " | ". Two real "…" characters where the library uses "...": `Molecules.lua` 4130, `RadioTab.lua` 531.
- **Same thing, different words.** Remove data: Delete (maps notes, profiles, presets, builds, saves), Remove (Join server `UI.json` 1127, zone 370), Forget (Join 1141), Clear (Messages 1695, chords 555). Revert: Undo (DescEdit 742, Sandbox 2664, Mods 1591), Put back (Sandbox 2656), Reset (Host 1060, Mods 1544, wheel 2527), Defaults (Options 1770), Discard (Options 1771, 1756). "Put back" also names the belt verb (`UI.json` 802) and the Settings feature (2148). Choose/Select/Pick: Select (1304, 1923), Choose (1694, 2298, 1721), Pick (1004, 2258, 876). Vanilla uses Grab for moving items (`ContextMenu_Grab`); ZeD uses Take (2525, 1561). Trait polarity good/bad (TAS) vs positive/negative (Identity). Out of reach / Within reach / In range / Nearby for distance (`UI.json` 490, 1953, 2195, 2372, 2383, 2493-2513). Back / Go back / Close.
- **Spelling.** "Favourite" (`UI.json` 1398, 1453, 1517) and "colour" (2796) vs vanilla and the rest of ZeD (Favorite `IGUI_CraftUI_Favorite`, Color). "ZeD-GUI" is the real name (`mod.info`, `UI.json` 2625) so that is consistent.
- **Button letters in running text:** "A does it." (`UI.json` 989), "A or click here to fold it back" (1330), "A to read" (894), "A chooses an action." (548), against the Glyphs setting (Xbox / PlayStation / Nintendo).
- **Mixed-case prompts:** "D-PAD Move", "D-PAD Move / Step" (1699, 1909, 1971).
- **Captions** that fail "no unhelpful captions": Hair hover/pad lines (988-989), "(the game gives this trait no description)" (2250), Messages duplicate caption (1703 and 1711).

## 2.10 Era violations

- **Left accent bars:** `ModSupport/SPNCC.lua` 755 (4 units, banner); `CraftingCore.lua` 1643 (3 units, picked alternative); `Molecules.lua` 2909, 3049, 3134 (2-unit selection/owned edges on recipe, alt and slot rows).
- **Breadcrumb:** `AnimalsTab.lua` 1077-1114 (back triangle + accent label bar named `drawBreadcrumb`, F5 accent, plus gamepad zone); `Molecules.lua` 3643-3648 builds a `Parent > Child` trail in the context label.
- **Chevron rows:** none; `ZeD_ContextList.lua` 278 draws a submenu triangle at row end (the standard menu mark).
- **Pills where a dot works:** the object-card state pills (`ObjectCards.lua` 274-285) pair a dot with a coloured outline; coloured outline + coloured text + dot is triple-coding. Hair mod tag, NEW and Messages kind tags are outline tags where plain text or a dot would do. `A.drawPillButton` is used only for real selectors.

---

# Top 20 cohesion problems, most visible to a player first

1. Eleven different hover boxes and three timings (instant chips, 450 ms hint boxes, row cards): `Atoms.lua` 587-622 vs `ZeD_Belt.lua` 1448-1481, `SkillsTab.lua` 453-518, `ZeD_HairBeard.lua` 1336-1371, `InventoryRenderer.lua` 807-836.
2. Identity drawer: Hair and beard head is F1 caps with the groove above, Traits is F4 with the groove below: `ZeD_HairBeard.lua` 862-865 vs `IdentityTab.lua` 554-559.
3. Twelve kinds of small state tag (2.4), e.g. BELT n outline vs grid solid square vs IN HAND plain text: `InventoryRenderer.lua` 621-632, 1569-1584; `ZeD_Belt.lua` 1221-1226; `EquipmentTab.lua` 719-729.
4. Coloured status text instead of dot + default text, 30+ sites; most seen: ammo count `ZeD_Belt.lua` 1359-1366, craft missing ingredient `Molecules.lua` 3147-3186, Animals trust `AnimalsTab.lua` 2696-2706, Options Safe mode `ZeD_MainMenuOptions.lua` 1120-1121.
5. Traits tab row rhythm and colours differ from Skills (26+2 vs F1+8 and 6; fill 0.32 vs 0.45; square 0.6 vs 0.25): `traitsAsSkills.lua` 56, 376, 384 vs `SkillsTab.lua` 59-68, 80-96, 848-851.
6. Selection fill: solid accent in HairBeard and Traits vs translucent 0.25-0.36 elsewhere: `ZeD_HairBeard.lua` 1104, `traitsAsSkills.lua` 368 vs `EquipmentTab.lua` 590, `InventoryRenderer.lua` 585.
7. Group header rows: 15 (Equip), 20 (Animals), 22 (Hair), 26 (Traits) units; text prefix vs triangle atom; F1 vs F5 vs F2: `EquipmentTab.lua` 518-560, `ZeD_HairBeard.lua` 1066-1094, `traitsAsSkills.lua` 340-358.
8. Status dot size 6 / 7 / 8 and round vs square: `EquipmentTab.lua` 667, `Atoms.lua` 454, `ZeD_HairBeard.lua` 1125, `MapsTabExt.lua` 408, `SkillRecoveryJournal.lua` 223.
9. Four hand-rolled segmented controls with four fonts: `ZeD_HairBeard.lua` 1044-1064, `traitsAsSkills.lua` 294-313, `MapsTab.lua` 1212-1244, `ZeD_MainMenuOptions.lua` 964-985.
10. Same icon-only button, different icons, one hinted and one not: `MapsTab.lua` 1246-1269 vs `RadioTab.lua` 1102-1123.
11. Empty states in 15 styles (caps vs sentence, F1/F2/F4, centred vs left): 2.5 table.
12. Prose set in the Mono chrome font (hair footnote, key panel, side list, Messages help): `ZeD_HairBeard.lua` 916, `MapsTabKey.lua` 72, `MapsTabExt.lua` 361, `ZeD_MessagesWindow.lua` 333.
13. Button heights 20 / 22 / 24 / 26 and non-growing in Large text: `MapsTabExt.lua` 222, `ZeD_MessagesWindow.lua` 34, `ZeD_HairBeard.lua` 1297 vs `Tokens.lua` 356/387.
14. Heading/data font role slips: ammo count F4 `ZeD_Belt.lua` 1401, skill-card title F3 `SkillsTab.lua` 491, map banner F3 `MapsTabExt.lua` 496, Animals tab F4 everywhere `AnimalsTab.lua` 393, 889, 1221.
15. Scrolling lists with no scrollbar or silent clipping: `MapsTabExt.lua` 377-379, `ZeD_MessagesWindow.lua` 440, `traitsAsSkills.lua` 613-619; hand-rolled bar `FurnitureTab.lua` 700-705.
16. Left accent bars and a breadcrumb bar still shipping: `SPNCC.lua` 755, `CraftingCore.lua` 1643, `Molecules.lua` 2909/3049/3134, `AnimalsTab.lua` 1077-1114.
17. Hand-rolled bars at 2/3/4/5 units where `drawFillBar` / `drawSegBar` / `drawProgressBand` exist: `ZeD_HairBeard.lua` 940-949, 1321-1326, `traitsAsSkills.lua` 626-627, `InventoryRenderer.lua` 645-650.
18. Wording drift: Delete/Remove/Forget/Clear, Undo/Put back/Reset/Discard, Choose/Select/Pick, "Show Survey" Title Case, "Favourite": `UI.json` 1345, 1398, 2656, 2664, 1141, 1695.
19. "A" in running text despite glyph setting and "Out of reach" meaning "not available": `UI.json` 989, 1330, 1001.
20. Secondary text dimmed by alpha 0.7-0.8 instead of tokens, and ad hoc disabled alphas 0.35-0.5 instead of `disabledAlpha` 0.42: `ZeD_MessagesWindow.lua` 280-333, `ZeD_HairBeard.lua` 1111, `InventoryRenderer.lua` 595.
