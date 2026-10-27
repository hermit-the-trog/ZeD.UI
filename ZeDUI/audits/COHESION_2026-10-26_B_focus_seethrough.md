# ZeD-UI audit B: focus / hover / selection looks and background translucency

Read-only audit of `42/media/lua/client/ZeD/` and `shared/ZeD/Tokens.lua`. Nothing edited, nothing launched. File names are relative to `client/ZeD/` unless a folder is given. "Possibly" marks anything inferred rather than read.

## 0. Headline findings

1. **The established rule does not match the code.** GAMEPAD_SPEC rule 4 says the focus visual is the hover visual (0.55). In code, mouse hover is almost everywhere **0.22** (or the `T.hover` token: 0.20-0.22 dark, 0.15 light) and pad focus is **0.55**. Code comments say so openly ("hover 0.22 / controller focus 0.55": `ZeD_MainMenu.lua:874`, `ZeD_Prompt.lua:949`, `Molecules.lua:44`, `InventoryRenderer.lua:570,652`, `EquipDoll.lua:301`).
2. **The tab waterfalls do not look like the rule either.** Every tab id (all 15) has a lit pixel icon, so the live path is `ZeD_TabPx.lua:99-111`: active = a bevelled 0.85-shade accent panel (no 2px edge bar), hover and pad focus = a **0.30** accent wash. The 0.55 fill + 2px bar code at `ZeD_CharacterWindow.lua:2900-2906` and `ZeD_WorldWindow.lua:1766-1772` is dead for every shipped tab.
3. **Item card buttons use an outline, not a fill** (`ItemCard.lua:1550-1620`: two hairline accent rings, 1.0 and 0.5 alpha). That is the most-used controller surface after the item list.
4. **Cues are gated by zone, almost never by input mode**, and six tab files do not even check that their window is the focused one (details in section 2).
5. **Background:** one token table holds the whole see-through setting (`surf1-4` and `base`, alpha 0.92 dark / 0.97 light / 0.95 high contrast), and the window body is filled once. But about 40 child fills reuse `surfN.a` over the body and compound, and about 25 fills use literal alphas (1, 0.98, 0.95, 0.92) that ignore the token.

---

## Part 1. Focus, hover, selection, pressed, active

### 1.1 Table of distinct looks

Key: fill alpha is accent unless said. "Zone-gated" = tests the focused window and zone/element. "Pad-only" = gated on `Detector.getMode()=="gamepad"`. "Hover twin" = does mouse hover use the same look.

| Variant | Look (alpha, kind, token, text change) | Zone-gated | Pad-only | Hover twin | Where |
|---|---|---|---|---|---|
| Inventory list row focus | 0.55 `T.accent` fill drawn BEFORE the text; selection wash skipped while focused; all row text becomes `T.textOnFocus` (pure black or white, `Tokens.lua:742-747`) | yes (window + inv zone + element) | no | **no: list rows have no hover at all** | `InventoryRenderer.lua:1481-1503`, text via `focusTxt` 1482-1627 |
| Inventory list row selected | `T.selectionA` = 0.18 (0.25 only in High Contrast, `Tokens.lua:69,135,195`); name turns `toneHi` | n/a | n/a | n/a | `InventoryRenderer.lua:1486-1493,1529` |
| Grid cell | focus 0.55 over the icon; hover 0.22; selected 0.36 + icon tinted 0.7 | focus yes | no | no (0.22 vs 0.55) | `InventoryRenderer.lua:585,652-659` |
| List/Grid toggle | focus 0.55; hover 0.22 (not on the active half); on = solid accent + `textOnAccent` icon | yes (element id) | no | no | `InventoryRenderer.lua:552-562` |
| Column / category header hover | 0.04-0.06 neutral `T.text` wash (not accent) | n/a | n/a | n/a | `InventoryRenderer.lua:1350,1667` |
| Tab waterfall (live, lit icons) | active: 0.85-shaded solid accent panel with light top/left and dark bottom/right edges; hover **and** pad focus: 0.30 accent wash; icon tones, no text swap | window + `charTabBar`/`worldTabBar`; pad focus skips the active tab | no | same as focus (0.30) | `ZeD_TabPx.lua:99-111`; callers `ZeD_CharacterWindow.lua:2886-2895`, `ZeD_WorldWindow.lua:1755-1761` |
| Tab waterfall (fallback, dead) | active 0.55 + 2px side bar; hover/focus 0.55; icon `textOnFocus` | same | no | same | `ZeD_CharacterWindow.lua:2900-2911`, `ZeD_WorldWindow.lua:1766-1776` |
| Container strip, Character | main: active 0.55 + 2px right bar; non-main viewed/sole = `surf2` + bar; multi-selected 0.15 + bar; hover 0.04 white (main) or opaque `surf2` (others); pad focus 0.55 stacked on top, glyph/badge not recoloured | yes (window + `charContainerStrip`) | no | no | `ZeD_CharacterWindow.lua:3181-3193,3330-3352` |
| Container strip, World | any active/viewed/MC: 0.55 + 2px LEFT bar; hover 0.04 white; pad focus 0.55 (same alpha as "on", so invisible on an active container) | yes | no | no | `ZeD_WorldWindow.lua:2694-2709,2841-2861` |
| Sub-tab pills (Journal, Animals) | focus 0.55 over pill AND label (label stays `toneNorm`); active = surf1 + open-bottom border; **no hover look** | Journal: zone only (no window check); Animals: zone only | no | no hover | `JournalTab.lua:540-571`; `AnimalsTab.lua:66-74` |
| Tab-header disclosure (Health, Thermal, Skills, Identity, Equipment, Journal groups) | 0.55 wash behind `drawTabHeader`; title stays `textHead`, chevron `T.arrow` (60% alpha) | window + element | no | header has no hover | `HealthTab.lua:1320-1337`, `SkillsTab.lua:1151-1161`, `ThermalTab.lua:335`, `IdentityTab.lua:717`, `EquipmentTab.lua:1398-1407` |
| Item card header verbs (Eat, Take, Wear, Drop) | **no hover look**; primary = solid accent + `textOnAccent` + bevel; pad focus = 2-hairline accent OUTLINE (1.0 and 0.5) hugging the button, no fill | window + `charItemCard`/`worldItemCard` | no | no | `Molecules.lua:2166-2209`, `ItemCard.lua:1550-1620`, `ItemCardOrganism.lua:1257` |
| Item card icon strips (FAV, protect, verb icons, zone docks, name row) | hover `T.hover` (0.20-0.22 dark, 0.15 light) rounded fill; "on" = state colour at 0.2; pad focus = same outline as above | same | no | no | `Molecules.lua:1758-1783,1843-1863,1930-1941`; `ItemCard.lua:1550-1620` |
| Object card button (`UI.button`), also container-controls buttons | System 7 bevel button; pad focus = 0.55 wash drawn AFTER label (label under wash); no mouse hover in `UI.button` (container controls add 0.22) | gamepad mode + window + `worldItemCard` (the only fully gated cue) | **yes** | container controls: 0.22 | `ObjectCards.lua:235-266,731-745`; `ContainerControls.lua:758-768` |
| Object card rocker / knob | focus 0.55 rect 2 units larger than rocker; knob: 0.55 disc halo r+4 | same | yes | n/a | `ObjectCards.lua:653-666` |
| Craft / Build recipe row | selected 0.18 + **2px left bar**; hover `T.hover`; pad focus 0.55 drawn AFTER the row (text under wash, no swap) | zone only (no window check) | no | no | `Molecules.lua:2897-2910`; `CraftingCore.lua:1546-1549,2294-2307` |
| Craft alt-pick / section header / sort strip / station button | picked 0.16 + 3px bar; headers and sort buttons focus 0.55 after draw; station "Use" = primary button then 0.55 over it; BUILD button 0.15, hover 0.25, label in plain `T.accent` | zone only | no | no | `CraftingCore.lua:1488-1491,1313-1316,1642-1647,2072-2076`; `Molecules.lua:3363-3375` |
| Health exercise pills, Thermal view pills | focus 0.55 painted BEFORE `drawPillButton`, whose own `surf1` fill (0.92) then covers it; pill border 0.4 accent | window + element | no | hover 0.22 on Health only | `HealthTab.lua:890-891,912-913,937-945`; `AtomExtensions.lua:324-354`; `ThermalTab.lua:394-395` |
| Health injury rows, Thermal body parts, Skills training rows | 0.55 over/behind row; severity-coloured names unchanged | window + element | no | no | `HealthTab.lua:1266-1281`, `SkillsTab.lua:1126-1135` |
| Skills skill rows | **2px accent RING only**, no fill, no text change | window + element | no | no | `SkillsTab.lua:1085-1088`, `AtomExtensions.lua:128-139` |
| Identity trait chips | 30% trait colour chip; focus 0.55 + `textOnFocus`; hover shows description only | window + element | no | no | `IdentityTab.lua:490-517` |
| Equipment slot rows / doll boxes / group headers | row: `selectionA` selected, focus 0.55 + `textOnFocus`; no row hover. Doll box: hover 0.22, focus 0.55 over picture. Group header hover 0.06 | window + `charTabContent` | no | row: none; box: no | `EquipmentTab.lua:535-606`; `EquipDoll.lua:301-307,586-589` |
| Hair / Beard rows | selected = **solid 1.0 accent** + `textOnAccent`; focus 0.55 + `textOnFocus` **plus 2px `accentBright` ring**; hover 0.22; part toggle: selected solid, focus = ring only | window + element id | no (one `getMode` at 1280) | no | `ZeD_HairBeard.lua:1054-1061,1073-1076,1104-1110` |
| Traits tab (Traits as Skills) | same grammar as Hair rows; Find box focus = ring only | window + `el.tas` | no | no | `ModSupport/traitsAsSkills.lua:305-309,340-380,742-745` |
| Maps toolbar | focus 0.55 drawn first (icon on top); active tool 0.2 + 0.6 border; style pills active text `T.accent` on top of the wash; colour swatch focus = fat 0.55 halo, active swatch = 1px text ring; no hover look | window + element | `MapsTab.lua:1950` only for the pad cursor | no | `MapsTab.lua:1032-1049,1121-1253` |
| Map key (MapsTabKey) / map extension slider | 0.55 rects; slider focus = 0.55 wash behind track | window + element | no | n/a | `MapsTabKey.lua:98,127`; `MapsTabExt.lua:102-105,238` |
| Vehicle (Mechanics) / Furniture | one `stamp()`: 0.55 painted right after the element (text under it) | window + zone | no | no | `MechanicsTab.lua:733-745`, `FurnitureTab.lua:707` |
| Animals | cue "pre-painted" under content; zone check only, **no window check** | zone only | no | 0.22 on some | `AnimalsTab.lua:66-80` |
| Belt slots | focus = 0.55 halo extended 3 units outside the box (over the picture); hover only while dragging (0.22); `fitHover` double accent border | window | no | no | `ZeD_Belt.lua:1258-1263,1294-1297,1532,1940` |
| Dash / watch / radio plates | `PL.cue`: keys = rect 0.55 (hover 0.22); **knobs = RING 0.55 (hover 0.30)** | `joyfocus`/ring | partly | yes for keys | `ZeD_Plate.lua:718-725`; `ZeD_Dashboard.lua:653`; `TwoWayFace.lua:367-368`; `ZeD_CarRadio.lua:253-254`; `ZeD_SirenController.lua:175-176` |
| Context menu strip cell, wheel slice | pointed = **solid accent** cell + 1px `accentBright` border, `textOnAccent`; rest = locked paper/ink (theme-blind). Wheel grows the pointed cell and shows a balloon | n/a (own) | pad or mouse | yes (same state) | `Molecules.lua:3424-3429`; `ZeD_Wheel.lua:220-235,274-277` |
| Context list (menu rows) | selected = pointed = 0.55 + `textOnFocus`; open parent row 0.3 | own | pad or mouse | same | `ZeD_ContextList.lua:255-265` |
| Prompt, Keyboard, Reader, Journal readers | buttons through `drawButton`: focus fill 0.55 (+`textOnFocus`), hover 0.22; Keyboard hides hover while pad focus is on; swatches: focus halo 0.55, selected 1px accent border | own `joyfocus` | pad (`joyfocus`) | **no** (0.22 vs 0.55) | `ZeD_Prompt.lua:949-966,1005-1008,1031`; `ZeD_Keyboard.lua:372-384`; `ZeD_Reader.lua:345,371,391,749,858`; `ZeD_JournalReaders.lua:84-99,291-313` |
| Messages window | list: selected 0.35, selected+focus 0.55, hover 0.18; selected text = `textOnAccent` (ink) on the 0.35 wash; buttons hover 0.22 / focus 0.55 | own | pad (`joy`) | no | `ZeD_MessagesWindow.lua:259-281,317-350` |
| Main menu screens (outside FocusManager) | rows/cards: focus 0.55 (`gp and focusId==id`), selected **0.22 (same as hover)**; buttons: hover 0.22, focus 0.55 with label `T.text`; combo hover = `surf3`; slider thumb hover `accentBright`; swatch hover = 1px accent outline | own `focusId` | **yes (`gp`)** | no | `ZeD_MainMenu.lua:877-907`; `ZeD_MainMenuMods.lua:1180-1181`; `ZeD_MainMenuOptions.lua:1158-1265,1411` |
| Sandbox in game | inherits the main menu option rows | own | yes | no | `ZeD_SandboxInGame.lua` (shares MMOptions) |
| Footer scoped underline | 3px (4px `accentBright` when locked), alpha 1.0, at the **bottom edge of the window** over the zone's x-range, over the footer | window + zone with `uiRange` | **yes** | n/a | `Organisms.lua:544-567` |
| Checkbox, scrollbar parts | hover `T.hover` fill; on = solid accent + X (`textOnAccent`); scroll thumb drag 0.30, arrow active 0.20 | n/a | n/a | n/a | `Atoms.lua:351-385,651-690` |
| Text inputs | focus = accent caret only | n/a | n/a | n/a | `Molecules.lua:391-409` |
| Pressed | only `drawButton`'s 1px label nudge; nothing elsewhere | n/a | n/a | n/a | `Molecules.lua:117` |
| Disabled | `T.disabledAlpha` 0.42 in the token; literals 0.35 / 0.38 / 0.45 / 0.3 elsewhere | n/a | n/a | n/a | `ObjectCards.lua:243`, `Molecules.lua:2180,3438,1906`, `ZeD_MainMenu.lua:894`, `ItemCardOrganism.lua:212` |

### 1.2 Outliers (one line each)

- `ItemCard.lua:1612-1619` pad focus on card verbs/strip/name row/docks is an OUTLINE (two hairline rings). Breaks "never an outline".
- `SkillsTab.lua:1085-1088` skill-row focus is a 2px ring only (no fill, no text swap).
- `ZeD_HairBeard.lua:1107`, `ModSupport/traitsAsSkills.lua:379` rows get 0.55 fill **plus** a 2px `accentBright` ring; `HairBeard:1061`, `traitsAsSkills:309` toggles and `traitsAsSkills:744` Find box use ring only.
- `ZeD_TabPx.lua:110` tab hover/focus is 0.30, not 0.55; `:103-108` active tab is a bevelled panel, not a 2px edge bar; comment at `ZeD_CharacterWindow.lua:2848-2851` still says "outline".
- `ZeD_CharacterWindow.lua:2886`, `ZeD_WorldWindow.lua:1755` (`and not isActive`): pad focus on the active tab paints nothing.
- Selected = same alpha as focus on container strips: `ZeD_WorldWindow.lua:2694-2709,2841-2861`, `ZeD_CharacterWindow.lua:3182-3192` (focus on an active container is invisible). Character and World strips use different "selected" looks for the same role (`ZeD_CharacterWindow.lua:3330-3341` vs `ZeD_WorldWindow.lua:2841-2848`; the second `elseif isOn` branch is a duplicate of the first).
- Container strip hover is a 0.04 white wash or opaque `surf2`, not accent: `ZeD_CharacterWindow.lua:3185,3343`, `ZeD_WorldWindow.lua:2700,2853`.
- Inventory list rows, equipment rows, Journal sub-tab pills, card header verbs, map toolbar buttons have **no mouse hover look**: `InventoryRenderer.lua:1456-1643`, `EquipmentTab.lua:562-606`, `JournalTab.lua:540-575`, `Molecules.lua:2166-2209`.
- Hover token vs literal: `T.hover` (0.15 in the light theme, `Tokens.lua:241,246...`) in `Molecules.lua:1768,1851,1933`, `Organisms.lua:1169`; literal 0.22 in most newer code. In the light theme the two differ by about a third.
- Selected has ten looks: 0.18 `InventoryRenderer.lua:1488`; 0.36 + dim icon `:585,594`; 0.18 + 2px bar `Molecules.lua:2899-2909`; 0.16 + 3px bar `CraftingCore.lua:1642-1643`; solid 1.0 `ZeD_HairBeard.lua:1104`, `traitsAsSkills.lua:368`; 0.35 `ZeD_MessagesWindow.lua:266`; 0.22 (=hover) `ZeD_MainMenuMods.lua:1181` and 8 more menu files; 0.2 + 0.6 border `MapsTab.lua:1044-1045`; 0.15 + 0.6 border `AtomExtensions.lua:333-336`; surf2 + bar `ZeD_CharacterWindow.lua:3333-3337`.
- Text sits UNDER the wash (cue drawn after the content) in `CraftingCore.lua:1490,1548,1646,2075`, `JournalTab.lua:570,763,826,859,932`, `MapsTab.lua:1230,1253`, `ObjectCards.lua:261-264`, `EquipDoll.lua:304`, `MechanicsTab.lua:742`, `StationMachine.lua`, `Stations.lua:495,588`. Only 16 of the ~60 files that paint a 0.55 fill use `textOnFocus`.
- Accent text on the accent wash: `MapsTab.lua:1238` (style pill `on` text is `T.accent`), `:1160` ("Aa"), `JournalTab.lua:870` (`toneLo` label), `:765` (`toneHi`), `HealthTab.lua:1283-1286` (severity colours), `ZeD_CharacterWindow.lua:3205,3217` (container glyph and badge in `T.accent` on the 0.55 fill). Estimate: about 2:1 in dark and light (accent text is legible against the surface, not against its own wash).
- Messages selected text is `textOnAccent` (ink in the dark theme) on a 0.35 wash: `ZeD_MessagesWindow.lua:277`. Possibly about 1.6:1 in the dark theme.
- Primary/accent-filled button + 0.55 accent overlay changes almost nothing: `ObjectCards.lua:244,261-264` (also every `ContainerControls` button).
- Health/Thermal pills: cue painted first, then a 0.92 `surf1` pill fill: `HealthTab.lua:890-891,912-913,937-945`, `ThermalTab.lua:394-395`. Visible cue is about 4% accent. Possibly invisible.
- No window check on the cue (a remembered zone in the unfocused window stays lit; `Focus.getFocusedZone(w)` returns `w._focusRing[w._focusIdx]` whether or not `w` is focused, `FocusManager.lua:388-400`): `AnimalsTab.lua:66-74`, `CraftingCore.lua:2294-2307` (Craft, Build, Journal recipes), `JournalTab.lua:633-640`; possibly also `ForagingTab.lua:113`, `Stations.lua`, `ZeD_JournalReaders.lua`.
- No input-mode gate: only `ObjectCards.lua:737`, `MapsTab.lua:1950`, `HairBeard.lua:1280`, `Dashboard`, and the footer (`Organisms.lua:550-552`) test the mode. Switching to mouse never releases focus (`FocusManager.lua:1806-1813` only re-opens the pair; `releaseFocus` only on hide/close, `:1315,1330,1391`), so the last 0.55 stays lit while the mouse hovers elsewhere. The comment at `InventoryRenderer.lua:1382-1392` says the detector flickers, which is why mode gates were avoided.
- Dead or stale design pieces: `Atoms.drawFocusRing` (dashed ring, `Atoms.lua:732`, no callers), `ZeD.Gp.focusRingW/Pad/FillA` (`Tokens.lua:519-521`, no readers), Visual Catalog A11 (2px outline, `ZeD-UI Visual Catalog v2.0.htm:306`), catalog `.list-row.sel` solid accent (line 89) and button hover (line 57), GAMEPAD_SPEC rule 4 ("2px accent underline in the title bar"; code draws 3px at the bottom edge).
- Main menu button labels use `T.text` on the focus wash, not `textOnFocus`: `ZeD_MainMenu.lua:905`, option rows keep `T.text` `ZeD_MainMenuOptions.lua:1411,1420`.
- "No shadows" is not followed: hard 2px black offset shadows at `Atoms.lua:618` (hint layer), `ZeD_ContextList.lua:228,310`, `ZeD_Wheel.lua:228`, `Molecules.lua:3524,3669,3727,3913`, five main-menu popups (`ZeD_MainMenu.lua:1229,1485`, `ModsPanes:161`, `Options:1597`, `Spawn:615`), `ZeD_Bubbles.lua:399`, `ZeD_Moodles.lua:375`, `ZeD_SeatChooser.lua:391`. These are System 7 "stepped shadows" by design but contradict the rule.
- Legacy-looking paths still called: green `T.positive` hover on the XFER strip and a 0.15 accent + 0.6 border "selected" on the container bar (`InventoryRenderer.lua:1778-1781,1889-1897`, called at `:2013,2118,2122`). Possibly unused in the two windows; not verified.
- Disabled alpha is not one value (listed in the table).

### 1.3 Current overall focus model as a player sees it

Controller focus is mostly "the thing goes accent". The standard cue is a **flat accent wash at 0.55** across the whole rect, with the label flipping to pure black or white where the code remembers to (`textOnFocus`). Concretely:

- **Item row:** the full-width row turns solid-looking accent, icon stays, every word turns black/white. Grid: a square accent wash over the cell. The selected wash (0.18) vanishes while focused. No mouse twin; the mouse shows nothing on list rows.
- **Tabs (waterfalls):** a soft 0.30 wash on the focused tab. The active tab is a raised accent block, and focus on it shows nothing extra.
- **Containers (side strips):** active container = accent block with a 2px bar on the outer edge; focus is the same 0.55, so focus on the active one is indistinguishable (the World strip), or a stack (the Character strip).
- **Card verbs and strip icons:** no fill. A thin accent frame (two hairlines) hugs the button. Object-card buttons instead get a 0.55 wash over the button (label dimmed under it).
- **Disclosure headers, recipe rows, journal rows, map toolbar, pills:** 0.55 wash with unchanged text.
- **Skills rows:** a 2px accent frame. **Hair and Trait rows:** fill and frame together.
- **Slider:** main-menu sliders are lit as a whole row (0.55). Map slider: a wash behind the track. Knob: a halo disc or ring (0.55). Rocker: a bigger 0.55 plate.
- **Wheel slice and context cell:** the pointed cell grows, goes solid accent with a bright 1px border, with a paper-and-ink balloon naming it.
- **Window level:** a 3px accent bar along the bottom edge under the focused zone's width (4px bright when the window is "locked" by Y-hold), plus the button-glyph legend in the footer.

Hard-to-see cases: focus on an already-active container (World), on the active tab, on a primary accent button, on a selected Hair/Trait row (ring only, fill is solid), on pill buttons that cover their own cue (Health/Thermal), text-heavy rows with accent-coloured text, container glyphs and badges (accent on accent). Light theme (inferred from tokens): `T.hover` 0.15 and `selectionA` 0.18 of a dark accent over light grey are close to indistinguishable, while the 0.55 focus is strong, so hover/selected/focus read as "nothing, nothing, loud". Accent-coloured text (`accentText`, `toneLo`) over the 0.55 wash is about 2:1 in either theme. Mono accent keeps contrast but loses all hue cueing. The tooltip plate is forced dark on the light theme because the engine draws white text (`Overrides/Tooltip.lua:144-153`).

---

## Part 2. Backgrounds and translucency

### 2.1 Where the alpha lives

- `shared/ZeD/Tokens.lua:36-43,107-112,171-175`: `base`, `surf1`..`surf4` carry alpha: **0.92** dark, **0.97** light, **0.95** high contrast. `border`/`borderS`/`text` carry their own alphas (1.0 / 0.9 etc.). Also `drawerBg` (black 0.15, white 0.12 light), `modalOverlayA` 0.50/0.35/0.60, `stripe` 0.04-0.05, `selectionA`, `badgeBgA`.
- `ZeD.applyTheme` copies them to `ZeD.T` (`Tokens.lua:812-816`), then accent-tints them with `colorBlend`, which **keeps alpha** (`:1075`, `:887-890`), then runs `ZeD.deriveReadable`.
- `ZeD.deriveReadable` (`Tokens.lua:706-764`) already solves every readable text colour against the surfaces **as translucent** over a worst-case black or white world (`flatOver(world, s)` uses `s.a`). So changing surface alpha before it runs automatically moves `accentText`, `toneLo`, `textSec`, `textDim`, `textOnFocus`. By my arithmetic the 4.6:1 target stays reachable only down to about 0.6 alpha over a pure white world (dark theme) or about 0.64 (light theme); below that, even pure white or black text fails on the worst-case backdrop.
- A second copy of the palette: `Organisms.lua:192-229` `windowAccentPalette` rebuilds `surf1-4` from `BaseThemes` for windows with their own accent, and **caches** per base|accent (`accentPalettes`), so it must be invalidated on a change.
- `_drawFrame` swaps these into `T` for the render cycle and restores (`Organisms.lua:231-258,574-589`), so any new alpha field must be in `READABLE_KEYS` or the swap list.

### 2.2 Census of fills

"Once" = one fill per window; "per element" = drawn again on top of something translucent (compounds: effective alpha = 1 - (1 - a)^2).

| Layer | Token / literal | Alpha today | Once or per element | Text on it | Where |
|---|---|---|---|---|---|
| Window body (all `ZeD_Window` kinds: Character, World, map pop-out, Messages, Prompt, Reader, Keyboard, Seat chooser, Station pop-out, main-menu windows) | `drawBodyBg(...,"surf1")` | token (0.92/0.97/0.95) | **once** per window | all tab content, rows, cards | `Organisms.lua:278-280`; `WindowCurtain.lua:114` (rolled-up fabric) |
| Title bar | `surf2` + 4% white stripes | token | once; plus a second `surf2` box behind the title text | title, stats | `Molecules.lua:1635,1658` |
| Footer bar / theme squares / prompt legend | `surf2` over the body | token | **per element (stacks on body)** | glyph prompts, labels | `Organisms.lua:379,406` |
| Sort row, column header, category headers, container bar, equipment headers, text-note input, Maps toolbar | `surf2` / `surf1` at `.a` over the body | token | **per element** | headings, buttons | `ZeD_CharacterWindow.lua:3244`, `ZeD_WorldWindow.lua:2765`, `InventoryRenderer.lua:1279,1669,1851`, `EquipmentTab.lua:535,869`, `MapsTab.lua:1327,1421,1478` |
| Tab drawer scrim | `T.drawerBg` black 0.15 / white 0.12 | token (separate) | once, over the body | tab content | `ZeD_CharacterWindow.lua:4566-4567`, `ZeD_WorldWindow.lua:3778` |
| Item card drawer | `surf1` at **literal 0.98** | literal | once, over the body | the whole item card | `ZeD_CharacterWindow.lua:4250-4253`, `ZeD_WorldWindow.lua:3568-3571` |
| Item card parts | `surf1`/`surf2` at `.a` (name row, bars, verb strip) | token | per element over the 0.98 drawer | name, stats, verbs | `ItemCardOrganism.lua:185,289,354,886,1160,1247` |
| Tab content panels | none (`ZeD_Panel.drawBg` is false everywhere except `TestInventory.lua:64`) | n/a | n/a | n/a | `ZeD_Panel.lua:35,62` |
| Row / cell fills | stripe 4-5%, `surf3` bars, wash alphas | tokens and literals | per element, small | row text | `InventoryRenderer.lua:1472,1605`, grid chips at literal 0.92 `:608,617` |
| Text input | `surf1` at `.a` | token | per element over the body | typed text | `Molecules.lua:370-371` |
| Dropdown popup | `surf1` at **literal 1.0** under `surf2` rows | literal | once, opaque by design ("blocks underlying content bleeding through") | option labels | `Molecules.lua:1106-1120` |
| Messages window panes | `surf1` at **literal 1** (list, cards, band) | literal | per element | message text | `ZeD_MessagesWindow.lua:257,293`; `ZeD_SeatChooser.lua:438` |
| Hover hint layer (icon-only hints) | `surf2` at **literal 1** + 0.5 black offset shadow | literal | once | hint text | `Atoms.lua:617-621` |
| Atoms tooltip (`ZeD_Tooltip`) | `surf2` token | token | once | tooltip lines | `Atoms.lua:547` |
| Game tooltips (`ISToolTip` override) | `T.base`/`surf2.a` dark and high contrast; fixed near-black `0.09` at 0.95 on the light theme; description wash 0.4 | mixed | once | engine-drawn WHITE text | `Overrides/Tooltip.lua:144-153,354-380` |
| Radio / appliance / dash hover chips | `surf1` literal 0.95 | literal | once | chip text | `RadioTab.lua:1330`, `StationAppliance.lua:599`, `ZeD_Dashboard.lua:1100` |
| Context menu strip / context list / balloons | strip: locked paper (0.95 grey) + ink on all themes; list: `surf1` at literal 1; balloon: `surf2` literal 1 + shadow | literal | once | menu words | `Molecules.lua:3415-3427`; `ZeD_ContextList.lua:228-229,309-312` |
| Wheels | cells locked paper/ink; breadcrumb and prompt strips `surf1` at literal 0.92 ("surface nearly opaque") | literal | once | wheel balloons, prompts | `ZeD_Wheel.lua:326-349` |
| Prompt / keyboard / modal scrims | modal scrim black `modalOverlayA`; prompt/keyboard children use `T.base` literal 1 for the typed line | mixed | once | typed text | `Organisms.lua:1589`; `ZeD_Keyboard.lua:345-348`; `ZeD_Reader.lua:363`; `ZeD_Prompt.lua:258` (`backgroundColor` 0.8, probably overridden by `ZeD_Window.prerender`) |
| Main menu windows on the CRT | same `ZeD_Window` body; wallpaper dimmed by `WALL_DIM` 0.55; menu bar `surf2`; icon labels on `surf1` | token | once | window text | `ZeD_MainMenu.lua:64,1051,1228,1843`; `ZeD_MainMenuDesktop.lua:175-197` |
| Map pop-out | a `ZeD_Window` (body as above) plus map `surf1` at `.a` behind the map | token | per element | toolbar | `MapsTab.lua:2058,1478` |
| HUD props: belt, ammo pouch, lamp | `surf1`/`surf2` at literal 0.92-0.96 and 1 | literal | once | slot labels, counts | `ZeD_Belt.lua:1176,1272,1477,1930-1932` |
| Dash, watch, siren, car radio, two-way | own plate palettes (pixel art) | n/a | n/a | hardware lettering | `ZeD_Plate.lua`, `DashPx.lua`, `PhysPx.lua` |
| Action bar thought bubbles, moodles | `surf1` at the fade alpha `a` | animated | once | bubble text | `ZeD_Bubbles.lua:409-434` |

### 2.3 Answers

**(a) Hook points for a single opacity multiplier.** One input, three places that must agree:
1. `Tokens.lua:applyTheme` right after the `T.surf1-4` / `T.base` copy (`:812-816`), **before** `deriveReadable` (`:911`). Scaling `.a` there fixes every fill that draws `surfN.a` and moves the derived text colours to match. (Setting it on `BaseThemes` also works but touches 3 themes x 5 values.)
2. `Organisms.lua:windowAccentPalette` (`:192-229`): same scale, and clear the `accentPalettes` cache when the setting changes.
3. `ZeD_Window:_drawFrame` and `_drawFooter` need nothing if (1) and (2) are done: the body is `drawBodyBg(...,"surf1")` using `surf.a` (`Molecules.lua:1607-1612`).
`drawBodyBg` is also the choke point for title bar, footer, tooltips and the curtain (13 call sites), so an `alphaOverride` policy per layer role would live there.

**(b) Layers that double up and look patchy.** Anything that draws `surf1/surf2` at `.a` over the window body compounds: footer (`Organisms.lua:379,406`), sort row, column and category headers, container bar, equipment headers, Maps toolbar, text inputs, item card name row and verb strip, the title text box over the title bar, the tab drawer scrim. At 0.92 it is invisible (0.99 effective); at 0.5 the body is 0.5 and every header band is 0.75, so the window reads as striped. The item card drawer (literal 0.98) and all `surf1` at literal 1 (Messages panes, dropdowns, hint layer, context list, balloons) would stay opaque islands in a see-through window. The hard-shadow rects (`ContextList.lua:228`, `Atoms.lua:618`) draw behind a surface and would show through it if that surface became translucent.

**(c) Where text loses contrast first.** Text drawn directly on the window body (all tab content, inventory rows, Skills, Journal, Health, the whole item card drawer once it follows the token) is backed by the body alpha only. Engine-drawn white text (game tooltips, rich-text descriptions) assumes a dark plate (`Overrides/Tooltip.lua:139-143`), so tooltips must keep a floor. Small F1/F5 grey text (`textDim`, `toneLo`, footer prompt legend, column headers) is already at the 4.6 limit. Bubbles and moodle text sit near the world with only a fade alpha.

**(d) What should stay opaque (or keep a floor).** HUD props (belt, ammo, lamp, dash, watch, radio plates: physical objects; belt `0.95` literals are fine). Tooltips, hover chips and balloons (transient, small, white engine text). Context menu strip and list, wheel cells and wheel prompt strips (locked palette, `ZeD_Wheel.lua:326` already says "nearly opaque"). Dropdown popups. The item card drawer and the footer prompt legend are the text-densest areas: a floor (for example 0.85) rather than the full range. Title bar: keep at least the body value, since it carries the close box and drag handle; the stripes can go. The modal scrim is already its own token.

**(e) Vanilla.** Vanilla has **no global UI opacity setting**. Windows use fixed constructor alphas: `ISCollapsableWindow.lua:374` and `ISInventoryPage.lua:1953` black 0.8, `ISPanel.lua:105` 0.5, `ISContextMenu.lua:1139` grey 0.7, `ISToolTip.lua:351,364` 0 and 0.3. Only the **multiplayer chat window** is adjustable: `ISChat.lua:21-50,363-400` keeps a min and max percentage (`getOptionMinChatOpaque`, `getOptionMaxChatOpaque`, `getOptionChatOpaqueOnFocus`, `getOptionChatFadeTime`), set from the chat gear menu (`ISChat.lua:274-298,685-704`), not the Options screen. It fades between min (mouse away) and max (hover/focus) over the fade time, scales **background** over 0 to 1, but gives **text** a floor of 0.8, controls a floor of 0.5 and the text entry its own range (`ISChat.lua:21-26,371-400`). Useful precedent: text opacity follows a higher floor than the background. Other transparency strings in vanilla are the view-cone opacity (a world effect, `MainOptions.lua:1090`) and the credits fade.

---

## Top 12 cohesion problems, most visible first

1. Pad focus (0.55) and mouse hover (0.22 / `T.hover`) are not the same look, against the stated rule, and the most-used list has no hover at all: `InventoryRenderer.lua:1456-1643`, `GAMEPAD_SPEC.md:28`.
2. Tab waterfalls: live look is 0.30 wash + bevelled solid active panel (no 2px bar), and pad focus on the active tab shows nothing: `ZeD_TabPx.lua:99-111`, `ZeD_CharacterWindow.lua:2886`, `ZeD_WorldWindow.lua:1755`; the 0.55 code beside it is dead.
3. Item card buttons are the only place with an OUTLINE focus, and the main verbs have no hover: `ItemCard.lua:1550-1620`, `Molecules.lua:2166-2209`.
4. Text drawn under the 0.55 wash (and accent text on accent) in Craft/Build, Journal, Health, Thermal, Skills, Maps, Animals, object cards: `CraftingCore.lua:1546-1549`, `JournalTab.lua:757-764,857-860`, `MapsTab.lua:1160,1238`, `ObjectCards.lua:261-264`.
5. Container strips: Character and World show "selected" differently; World selected = focus alpha so focus on the active container is invisible; hover is a 0.04 white wash: `ZeD_WorldWindow.lua:2694-2709,2841-2861`, `ZeD_CharacterWindow.lua:3182-3192,3330-3352`.
6. Cues linger: no window check in Craft/Build/Journal recipes, Journal, Animals (the other window or mouse mode keeps a row lit): `CraftingCore.lua:2294-2307`, `JournalTab.lua:633-640`, `AnimalsTab.lua:66-74`; no mode gate anywhere else: `FocusManager.lua:1806-1813`.
7. Ring and ring+fill focus in Skills, Hair, Traits instead of fill: `SkillsTab.lua:1085-1088`, `ZeD_HairBeard.lua:1061,1107`, `traitsAsSkills.lua:309,379,744`.
8. Primary accent buttons and the Health/Thermal pills hide their own focus (accent over accent; cue painted under a 0.92 fill): `ObjectCards.lua:244,261-264`, `HealthTab.lua:890-891`, `ThermalTab.lua:394-395`.
9. Ten different "selected" looks (0.15 to solid 1.0, with or without a bar or border): `InventoryRenderer.lua:1488`, `Molecules.lua:2899-2909`, `ZeD_HairBeard.lua:1104`, `ZeD_MessagesWindow.lua:266`, `ZeD_MainMenuMods.lua:1181`.
10. Opacity setting will not be even: about 40 child fills compound on the body, about 25 literal-alpha fills ignore the token: `Organisms.lua:379,406`, `ZeD_CharacterWindow.lua:4253`, `ZeD_MessagesWindow.lua:257,293`, `Atoms.lua:619`.
11. Hover strength is theme-dependent for token users (0.15 in the light theme) but fixed 0.22 for literal users, and selected (0.18) sits between: `Tokens.lua:241-281`, `Molecules.lua:1768`.
12. System 7 hard shadows and locked paper/ink palettes (context strip, wheels, balloons, hint layer, main-menu popups) against "no shadows" and theme-aware fills; dead focus-ring code and a stale Visual Catalog A11: `Atoms.lua:618,732`, `ZeD_ContextList.lua:228,310`, `Tokens.lua:519-521`.
