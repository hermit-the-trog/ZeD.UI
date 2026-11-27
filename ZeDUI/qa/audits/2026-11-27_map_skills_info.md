# Skills and Info tabs: map for the gamut sweep (QA, Nov 27 2026)

A read-only map of two Character window tabs against the game's own Character info window (B42): the Skills tab (tab id "skills", the game's Skills page ISCharacterInfo and its bars ISSkillProgressBar, plus the skill-book half of the game's Literature list) and the Info tab (tab id "identity", the game's Info page ISCharacterScreen: name, weight, traits, hair and beard, favorite weapon, kills, time survived). It also maps what the two tabs reach: the title bar's skill pins, the Find field, the row extras (RecipeIndex and the ModSupport files), the Hair and beard section and the portrait studio, only as far as the tabs reach them. Line refs are as read on Nov 27. Nothing was run.

**Both tabs are on the Character window**, declared in CHAR_TABS: "identity" (the game's IGUI_XP_Info, "Info", glyph I) and "skills" (IGUI_XP_Skills, glyph S), both group 2 (CW:859, 861). Both ask for the full card, 480 (CW:425-433), and drop to the half card, 220, when the inventory beside them would go under its minimum (CW:439-470). Their focus zone is charTabContent (CW:3462, 3466). The game's Character info window never shows while ZeD runs (CI:127-143, 165-206).

Short names: ST SkillsTab.lua, IT IdentityTab.lua, CW ZeD_CharacterWindow.lua, CI Overrides/CharacterInfo.lua, PN ZeD_Pins.lua, TF TabFind.lua, RI RecipeIndex.lua, HB ZeD_HairBeard.lua, MU ZeD_MakeUp.lua, KT KillTracker.lua, SE Settings.lua, PL ZeD_PausedLook.lua, BT ZeD_Belt.lua, DW ZeD_DpadWheels.lua, FM Input/FocusManager.lua, JT JournalTab.lua, ZUI shared/Translate/EN/UI.json (ZeD's words). All under 42/media/lua/client/ZeD/.
The game's files (media/lua unless noted): ISCI client/XpSystem/ISUI/ISCharacterInfo.lua, SPB client/XpSystem/ISUI/ISSkillProgressBar.lua, ISCS client/XpSystem/ISUI/ISCharacterScreen.lua, ICIW client/XpSystem/ISUI/ISCharacterInfoWindow.lua, LIT client/ISUI/ISLiteratureUI.lua, XPU server/XpSystem/XpUpdate.lua, SB server/XpSystem/XPSystem_SkillBook.lua, IN shared/Translate/EN/ItemName.json, LS media/scripts/generated/items/literature.txt.

FEATURE_MAP (ZeDUI/tools/qa/FEATURE_MAP.md; none at the repo root or in docs/) rows with stale refs:
- Row 215 (grid disclosure): the click is CW:6011-6020 (not 5661); the pad stop is built at CW:1682-1698 (not 1450).
- Row 216 (pin a skill): skillRowMenu is CW:4356 (not 4040), togglePinSkill CW:4349 (not 4033), ZeD.Pins.toggle PN:101 (not 71), drawer.onRightMouseUp CW:6133 (not 5767). Its note that the SkillsTab header comment is stale still holds (ST:8-9).
- Row 217 (training fold): the click is CW:6036-6046 (not 5687); gatherTrainingData :446 is right.
- Row 218 (Find, Skills): setText is TF:212 (not 211); skillOff :380 and trainOff :386 are right.
- Rows 219 and 1286 (extras): addExtras is ST:578 (not 566), stampStop ST:546 (not 534), onClick ST:562 (not 550).
- Row 226 (photo): IdentityTab.onClick is IT:1853 (not 1867), identityModel.onMouseUp CW:5178 (not 4836), onMouseWheel CW:5196 (not 4854). Its pad path names `"identity:__disclosure"`: that stop is dead, IT:1601 clears its zone every frame.
- Row 227 (studio): cameraZone is IT:1805 (not 1819). Row 1035: the studio stop is IT:1838 (not 1852); the camera is made at CW:6314-6317 and placed at CW:5150-5155 (not 5950).
- Row 230 (traits): focusables is IT:1829 (not 1843), drawTraitHint IT:1758 (not 1772); traitRowLayout :1438 is right.
- Row 64 and row 96: the dead copy of openTab is CW:4434 (not 4118); the live one is CI:61 (not 60). Row 1245: toggleView is CI:127 (not 111), openTab CI:61 (not 60).
- Rows 501-504 (pins): P.toggle is PN:101 (not 71), onFillInventory local PN:254 and P.onFillInventory PN:268 (not 213 and 198), P.kindOf PN:144 (local PN:131, not 111), P.skillMenu PN:272 (not 216), P.stats PN:194 (not 161); P.MAX :24 is right.
- The HB refs in row 228 and MU.open :209 in row 229 are right. The ModSupport rows (1312, 1317, 1329) were not checked.

## 1. What the tabs do

### Skills

**Getting there:**
- The tab strip, tab S (CW:861).
- The game's Skills key (Toggle Skill Panel): XPU:150-153 calls toggleView(xpSystemText.skills), hooked by CI:127-143, which maps the page name to "skills" (CI:37-58) and opens the windows on it (CI:61-122). The same key again closes the windows it opened, or only folds the drawer when they were already up (CI:79-90, KISS #25). The game's key does nothing while paused (XPU:128).
- The D-pad Character wheel's Tabs slice lists every Character tab (DW:1011-1027, 1101; run through H.charTab DW:796).
- Any other mod's `toggleView(getText("IGUI_XP_Skills"))` lands here too (CI:4-24).
- Safe mode (charinfo): the hook hands every call to the game (CI:128); safe mode ending hides a game window left open (CI:218-226).
- Split screen: another player's page is the game's own window (CI:64-65, ZeD.windowsFor).

**Data (ST):**
- Skills (gatherData ST:279-360, every 250 ms on the clock, ST:1113-1116, dueMs ST:32-51): every perk whose parent is not Perks.None, grouped by parent; per skill the level (getPerkLevel), progress in the level (getXP less getPreviousXpLvl, over getXpForLevel(level + 1), clamped 0 to 1, full at 10; ST:299-312, the game's own sums ported, SPB:254-296) and the boost (getPerkBoost, ST:314-317). Groups: passive first, then by name; skills by name (ST:329-340, plain Lua `<`).
- Pins (getPinData ST:250-272): the same sums, floored, for a skill by its shown name (getPerkByName ST:238-247, a name-to-perk table built once).
- Training materials (gatherTrainingData ST:446-507): the catalog is built once per Lua session (buildTMCatalog ST:370-426) from every literature script item whose SkillTrained is a SkillBook key (SB); titles sorted by name and given a roman numeral by that order; the skill id stripped off the front when it matches (ST:402-419). Status per book: read (pages read at or over the book's pages, or in getAlreadyReadBook), reading (some pages read), collected (the full type anywhere in the inventory, bags in bags walked, 200 containers at most, ST:449-469), else missing (ST:471-489). Groups sorted by the skill's shown name (ST:430-444, 504). First gather at once (ST:1206-1209), then every 500 ms only while the section is in the scroll view (ST:1492-1496).
- The cache drops on every tab switch (CW:4962-4964) and on the disclosure (CW:1694, 6017).

**The view (ST.render ST:1105-1575):**
- The pinned heading: the game's "Skills" with the disclosure triangle (ST:1524-1528); the Find field and its count at its right (ST:1530-1533, TF).
- Above the grid, the extras' head blocks (ST:1319-1330), only with an add-on that has one (Skill Recovery Journal's Transcribe key).
- The grid, two columns balanced by row count (ST:1187-1199), one column when two would cut the longest name (skillsOneColumn ST:168-179). A section head per group (ST:1360-1361).
- A row: alternating stripe; the accent wash when pinned (ST:1376-1384); the level badge, the number dim at 0 (drawLevelBadge ST:125-144); the name, cut with "..." clear of the tags and the bar (ST:1430-1434); the boost tag "+75% XP", "+100% XP" or "+125% XP" for boost 1, 2, 3 (boostText ST:224-230, ZUI:2638) and an extra's tag beside it (ST:673-690); the ten-segment bar at the right showing the way to the next level, green, yellow when pinned or at 10 (ST:1410-1424, levelBarColor ST:106-109). The bar gives room to the name down to ten 1-unit segments, then the badge closes in (skillRowFit ST:186-205).
- Help line: on a row "Right Click: pin Carpentry to the title bar." or "Unpin Carpentry from the title bar." (ST:1390-1394, ZUI:3788-3789); on the bar "Carpentry 3, 40% to level 4", "Carpentry 10" at the top (barHelp ST:112-116, ZUI:3790-3791); on the heading "Show or hide the skills." (ZUI:3787).
- The row's hover card (ST:1540-1574, skillCard ST:696-742): the skill's name, "Level 3, 120 / 300 XP to level 4" (ZUI:2639) or "Level 10", then the extras' lines. RecipeIndex always adds one (RI:373-375): for each level still to come the count of recipes that need it, the next level's first three by name (RI:338-371); with ZeD setup's autoLearn on, the recipes the skill teaches by itself too (RI:324-329). No card when no extra has lines. Hover after the card's pause; on the pad, once the focus rests.
- Training materials, under the grid (or right under the heading with the grid folded): the section head, a legend of Read, Reading, Collected, Not found (green, yellow, red, ghost; ST:775-780, 911-934), the skills in two plain halves (ST:936-946); a row is a triangle, the skill's shown name and one square per book (ST:992-1031); opened, one row per book: its square and "title Vol. N" (ST:1041-1086, ZUI:2646).
- Find (TF:307-320, 380-390): a typed text keeps a skill by its name or its group's name, a training row with its skill; the rest dim in place, never hidden; nothing kept shows the empty result with Clear (ST:1484-1489).

**Verbs:**
- Pin or unpin: right-click a row (CW:6133-6141), or A or X on its stop (CW:1709-1712), opens a one-line menu, Pin to title bar or Unpin from title bar (PN:272-283, CW:4356-4360). A plain click does not pin (CW:6035). Three pins at most of any kind; a fourth takes off the oldest and says so over the head (PN:101-121, ZUI:4634). The title bar shows "Carpentry - Lv.3 - 120/300" or "Carpentry - Lv.10", with shorter forms when room is short (PN:194-249, ZUI:541-542); refreshed each frame (CW:6673-6677, 935-940).
- Fold the grid: the heading, or A on `skills:__disclosure` (CW:6011-6020, 1682-1698).
- Fold a training row: a click on it (CW:6036-6046) or A on its stop (CW:1762-1767). A book row does nothing either way.
- Find: type in the field, its x box clears (TF).
- A head block's key (an add-on's): press or A runs it (ST:546-575, CW:1808-1818).
- Nothing in the tab queues a timed action.

**Pad (CW:1667-1830, zone charTabContent):**
- Order: `skills:__disclosure`, then the Find field `skills:find` (and `skills:findclear` with nothing matching), then the head keys `skills:stop:<id>`, then `skill:<name>` per row (only with the grid open; a dimmed row is no stop), then `training:<col>_<skill id>` per training row and `training:<col>_<skill id>#<n>` per book of an open row (CW:1802-1829, TF.skillsPadOrder TF:903).
- A on a row: the pin menu, focused (PN:278-282); X the same (CW:1742).
- One column: Left and Right do nothing (CW:1714-1717).
- The scroll follows the focus once per newly focused stop (ST:1269-1303); the help line's words show beside the focused row once the pad rests (ST:1401-1404).
- B: no stop has onCancel, so B stops the running action, if any (FM:1695-1704). The game's B closes the page (ISCI:330-333).

**Lite:** no branch in ST.

**Paused (PL:5-27):** a glass over the page takes every press and right press: no pin, no fold, no Find typing through the mouse; the wheel still scrolls; the pad's A and X do nothing there (PL.blocks).

### Info

**Getting there:**
- The tab strip, tab I (CW:859).
- The game's Info key (Toggle Info Panel, XPU:159-162), through the same hook (CI:127-143, "IGUI_XP_Info" to "identity"); the same key again closes what it opened.
- Full only: a click on the belt's profession buckle (BT:1171-1188); with ZeD's windows unable to open it calls the game's toggleView. Lite has no buckle.
- A make-up item's Make Up option opens the tab on Hair and beard's make-up part and scrolls to it (MU:209-220, HB:658-675, IT:1630-1633).
- The D-pad wheel's Tabs slice (DW:1011-1027).
- Safe mode and split screen: as Skills.

**Data (IT.gatherData IT:376-453, every 30 frames drawn, IT:1588-1594):**
- Name: the descriptor's surname and forename, "Unknown" when both are empty (IT:400-404, 430-439).
- Weight: math.floor(getNutrition():getWeight()) in kg (IT:407, ZUI:1329); trend "++" isIncWeightLot, "+" isIncWeight, "-" isDecWeight (IT:289-297).
- Sex: the game's IGUI_char_Female or IGUI_char_Male (IT:409).
- Profession: the definition's getUIName, each word's first letter upper and the rest lower (IT:349-367); the carry permit from the profession id: police officer, veteran, security guard, park ranger and burger flipper carry one, burglar's is revoked (IT:40-47).
- Hair style and beard: the game's IGUI_Hair_ and IGUI_Beard_ words; beard "N/A" for a woman, the game's IGUI_None with none (IT:201-225).
- Hair color: ZeD's own words from the color's brightness, the game's paint words where it has them (IT:178-199).
- Body hair: the index 0 to 4 in ZeD's words (IT:227-235).
- Favorite weapon: the modData key "Fav:<name>" with the highest count, the game's IGUI_None without one (IT:237-247).
- Zombies killed: KillTracker.total, the game's getZombieKills plus the fire kills KillTracker counts (IT:417, KT:24-27, 209-215).
- Survived: getTimeSurvived (IT:422-424).
- DL number: the surname's first letter and eight digits hashed from the name (IT:313-325). Issued and expires: the sandbox start date and four years on (IT:302-308).
- Traits: every known trait with a definition: label, description, cost, icon; cost 0 or more under Positive, below 0 under Negative, each sorted by label (IT:253-281).
- The cache drops on every tab switch (CW:4967-4968).

**The view (IT.render IT:1581-1754):** no heading (IT:1597-1601). One scroll: the card, Hair and beard, the traits.
- The card's style follows Lite: Full draws the Kentucky license, Lite the Simple card (useSimple IT:1558-1563, SE:738-744). Wide or narrow by the width (isTall IT:896-903: narrow when the wide card's field box is narrower than the widest label). QA hooks qaStyle, qaLayout, qaTrend, qaProf (IT:18-19).
- Wide license (IT:821-861): laminate, the blue band, the cream body; left the bust (120) with the seal and the permit stamp over it, or the full body (250) across the column; right the name "Surname, Forename" with the weight and its sign at the right, then Sex and Profession, Hair style and Body hair, Hair color and Facial hair, Survived for, Favorite weapon and Zombies killed (labels in the accent darkened, values dark).
- Narrow license (IT:1138-1180, tallMetrics IT:927-972): the photo (44% of the width, 3:4 up to 1:2) and beside it OPERATOR / CLASS D, the permit box (and REVOKED), DL NO, SURVIVED on its lines, ISS and EXP; then the surname big with the weight, the forename, the small rows SEX, HAIR, STYLE, FACIAL, BODY, PROF, KILLS, FAV (pairs side by side when they fit); the seal and the donor pill at the foot; the state watermark. Full body: the whole body under the band.
- Simple (IT:1360-1383): the photo box (bust 120 or full 230 wide; bust 88 or full 420 narrow), the name "Forename Surname" with the weight, then label and value rows: Sex, Profession, Hair style, Hair color, Facial hair, Body hair, Survived for, Favorite weapon, Zombies killed, and Carry permit when there is one (IT:1241-1266). English lowers the game's three title-case labels (IT:1204-1215).
- Help line: over the weight's sign "Gaining weight.", "Gaining weight fast." or "Losing weight." (IT:1691-1701, ZUI:1328-1331); over the photo "Pick the photo for the full body." or "Pick the photo again for the card." (IT:1717-1721, ZUI:4905-4906).
- The photo is the game's 3D model (ISUI3DModel), window-parented, placed each frame on the card's photo rect and cut at the view's edges (CW:5075-5088, 5121-5157). The studio's camera button sits in its corner, single player only (IT:1805-1814, CW:5150-5155, ZeD_Studio.lua:53).
- Hair and beard (HB, IT:1609-1613, 1726): a fold with a Hair, Beard (men only) and Make Up (with make-up carried or worn) switch, the Now and After figures, a row per choice the game's own hairMenu and beardMenu would offer (read through a stand-in screen, HB:1-34, 358-398), greyed choices folded under one row by Hidden actions (ZeD.Disclose), Cut (Stop while it runs).
- Traits (IT:1516-1551): the head "Traits" with the count, Positive (n) and Negative (n) groups, two columns wide and one narrow; a row is the game's icon (18) and the label; "No traits" when there are none. The description shows on hover after the pause and on pad rest (drawTraitHint IT:1758-1781, HB.hoverCard).

**Verbs:**
- Photo: a click (not a drag) on the model or its frame swaps bust and full body, resets the zoom and scrolls to the top (CW:5178-5193, IT:1853-1864); a drag turns the model; the wheel zooms while full body (CW:5196-5205); A on `identity:photo` (IT:1815-1819).
- Studio: the camera button or A on `identity:studio` opens the portrait room (IT:1820-1825).
- Hair and beard: pick a row, then Cut (or Apply, Remove for make-up): HB.run (HB:682-701) runs the game's handler or ZeD's copy of its steps: the hat comes off, scissors or razor to the hand, ISCutHair, ISTrimBeard or ISApplyMakeUp queued (HB:151-191). Stop clears the queue (HB:703-706). The part switch (HB.setPart HB:645-656).
- Traits: read only.

**Pad (IT:1829-1849, CW:3224-3233):** `identity:photo`, `identity:studio` (with the camera), the Hair and beard stops (`hb:part` with Left and Right switching, `hb:do`, `hb:row:<key>` where focus picks the row and A runs it then lands on `hb:do`, `hb:more`; HB:1855-1918), then `identity:trait:<label>` per trait (A does nothing). The scroll follows (IT:1784-1799). The grid-scroll fallback (CW:3195-3220) only runs if IdentityTab.focusables is missing. B: as Skills (stops the running action; a running cut is the likely one). The game's B closes the page (ISCS:713-719).

**Lite:** the Simple card (SE:742-744); no buckle (BT:1174).

**Paused:** the glass takes presses on the page (Cut, the part switch, the photo's frame); the model is its own element and may still take its click (not checked).

**Small screens:** the narrow license and one trait column below isTall's width; the half card stacks ISS and EXP, the small pairs and the bust's name lines (IT:920-972, 1319-1358).

## 2. Against the game

The game's Skills page (ISCI, SPB) and Info page (ISCS) are two tabs of ICIW, which also has Health, Protection and Temperature; each page can be popped out as its own window (ICIW:127-148, 237-282).

| Job | Game | ZeD | Kind |
| --- | --- | --- | --- |
| Open on Skills or Info | Its key, the page's tab | The same key, the tab strip, the wheel, the buckle (Info) | extra in ZeD |
| Open while paused | Nothing: the key handler returns at speed 0 (XPU:128) | PL:6-9 says the keys open the window alone while paused; no route found (bug list) | different rule |
| Close | The same key, or B on the page | The same key (what it opened); B stops a running action instead | different rule |
| Pop a page out as its own window | Yes (ICIW:237-282) | No | missing in ZeD |
| Skill groups | Each group folds on its own (ISCI:46-55, 222-234) | The whole grid folds; groups don't | different rule |
| Boost | The name tinted: grey 0, light grey 1, white 2, gold 3 (ISCI:136-152); the tooltip says "+75%" etc (SPB:85-94) | A "+75% XP" tag; the name untinted | different words |
| Book multiplier | Three arrows animate before the name (ISCI:155-167); the tooltip's Multiplier line (SPB:69-73) | Nothing (Clear Skill Sheet's add-on only) | missing in ZeD |
| Level and XP | Ten boxes: levels gained gold, the current one filled by XP, the rest dark (SPB:128-209); the tooltip "xp / needed" to two places | A level number, ten segments for the way to the next level; "40% to level 4" on the help line; floored XP in the card and pin | different numbers |
| Skill description | The perk's description and the hovered level's text (SPB:77-81) | None; the card lists recipes per level instead (RI) | missing in ZeD; extra in ZeD |
| Level-up | The bar flashes and fades (SPB:131-161) | Nothing in the tab | missing in ZeD |
| Watch one skill | No | Pin it to the title bar (three at most) | extra in ZeD |
| Find a skill | No | The Find field | extra in ZeD |
| Skill books read | Literature button on Info, its Skills list (LIT:77-127): white when read or when the skill already covers the book (LIT:92), hidden when MetaKnowledge hides unknown things (LIT:78, 124) | Training materials on Skills: four states, collected (carried) is ZeD's; no "known by level"; every title shown whatever MetaKnowledge | different rules |
| Recipe books, recipes, recorded media, seeds | The Literature window's other lists (LIT:287-344) | Recipes on the Journal's Recipes page (JT:122); the rest not on these tabs | missing on these tabs |
| Name | "Forename Surname", Medium (ISCS:84-87) | "Surname, Forename" on the wide license, surname over forename narrow, "Forename Surname" Simple | different words |
| Profession | Its icon, the name on hover (ISCS:89-98) | The name, title-cased; no icon on the tab (the belt's buckle has it) | different words |
| Weight | round(weight, 0) and an arrow for the trend (ISCS:117-129) | math.floor(weight) "kg" and +, ++ or -, with help words | different numbers |
| Sex | Not drawn (sexText unused) | Shown | extra in ZeD |
| Traits | Icons only, wrapped, label and description on hover; only traits with an icon (ISCS:133-157, 575-583, 608) | Icon and label rows in Positive and Negative; every known trait, icon or not | different rule |
| Hair style, beard | Each with a Change button and its menu; Change greyed with "no hair" (ISCS:161-208) | The Hair and beard section: rows, figures, Cut | different surface |
| Beard none | "IGUI_Beard_None" (ISCS:628) | the game's "IGUI_None"; "N/A" for a woman (the game hides the row) | different words |
| Hair color, body hair | No | ZeD's words | extra in ZeD |
| Favorite weapon | Only when there is one (ISCS:222-226) | Always; "None" without one | different rule |
| Zombies killed | getZombieKills (ISCS:228) | getZombieKills plus fire kills (KT) | different numbers |
| Survived for | Only while the clock shows its date (ISCS:237-240) | Always | different rule |
| Avatar | 128 x 256, whole body (ISCS:280-290) | The bust, or the whole body on a click; the wheel zooms; the studio | extra in ZeD |
| License facts | No | DL number, issued and expires dates, carry permit, CLASS D | extra in ZeD |

## 3. Cases

Staging is from the debug console or the QA scripts on the QA character in Saves/Sandbox/ZeD-QA. "Truth" is the game function to compare against.

### Skills

- **S1** The Skills key with both windows shut, then again. Staging: none. Read: `w._activeTab`, `w._drawerOpen`, ZeD.CharInfoRoute.last, the windows shut after the second press. Truth: XPU:150-153 calls toggleView(xpSystemText.skills); the game's window stays hidden (`getPlayerInfoPanel(0):getIsVisible()` false).
- **S2** The Skills key with the windows open on Loot, then again: the second press only folds the drawer. Truth: CI:79-90.
- **S3** The Skills key while paused (game speed 0). Read: does anything open. Truth: XPU:128 returns; PL:6-9 claims it opens.
- **S4** Tab strip S and the D-pad wheel's Tabs slice. Read: `_activeTab == "skills"`.
- **S5** Groups and rows. Staging: none. Read: each group's name and its skills in order from `w._skillsCache.categories`. Truth: ISCI.loadPerk (ISCI:265-285) and its sort (ISCI:33-44): the same perks, passive group first. Repeat in DE, FR, RU (the sort is Lua `<` in ZeD, the game's string.sort there).
- **S6** Level badge for every skill at 0, 1, 5, 9, 10 (LevelPerk / setPerkLevelDebug). Truth: `getPerkLevel(perk)`.
- **S7** Bar at 0%, 45%, 99% of a level (AddXP to Carpentry 3). Read: lit segments from `skill.xpProgress` and the help line. Truth: SPB.getPerkXp over getXpForLvl (SPB:254-296). Repeat with the sandbox XP multiplier at 0.5 and 5.
- **S8** Level 10: bar full and yellow, help "Carpentry 10", card "Level 10". Truth: getPerkLevel 10.
- **S9** Passive skills: Strength and Fitness at 5 losing XP (overweight timer or a debug AddXP of a negative amount): progress never under 0. Truth: SPB:181-185.
- **S10** Boost tags 0, 1, 2, 3 (a profession and traits that give them, or `getXp():setPerkBoost`). Read: rowTags. Truth: getPerkBoost and SPB:85-94 ("75%", "100%", "125%").
- **S11** A book multiplier: read half of Carpentry I so `getXp():getMultiplier(Perks.Woodwork)` > 0. Read: nothing on the row (gap). Truth: ISCI:155-167, SPB:69-73. Record only.
- **S12** Hover a row, the bar and the heading: the three help lines (ZUI:3787-3791). Hover a row until the card shows: the title, "Level 3, x / y XP to level 4" against getPinData, the recipe lines. Truth for x and y: SPB tooltip numbers (rounded there, floored here).
- **S13** Pin from the right-click menu: the title bar shows "Carpentry - Lv.3 - x/y", the row gets the wash and a yellow bar; Unpin takes both off. Read: `ZeD.Pins.isPinned`, `w.titleStats`. Truth: getPinData against S7's numbers.
- **S14** A fourth pin (three skills, then an item): the oldest goes, the note shows, `#ZeD_Pins == 3`.
- **S15** Pin Carpentry in EN, quit, restart in DE, load: is the pin still in the title bar and is the row marked (suspected bug 1).
- **S16** Pad: A on a row opens the menu focused; X the same; Pin from the pad. B on a row with a timed action running (eat something long), then with none.
- **S17** Grid disclosure by click and by A: rows and their stops go, training stays and moves up; open again.
- **S18** Find: "carp" (one skill lit, its training row lit), "combat" (the whole group), "zzz" (empty result, Clear, `skills:findclear`), clear. Pad: Down skips dimmed rows. Truth: none (ZeD only).
- **S19** One column: 1280x720, UI scale 2, Large text, inventory open (the half card). Read: `w._skillsOneCol`, names whole, Left and Right do nothing on a row.
- **S20** Scroll follow: Down from the disclosure to the last book of an open training row; each stop in view; then the wheel past the focus does not snap back.
- **S21** Training rows: one per skill with books (24 in vanilla), sorted by shown name, five squares each. Truth: SB keys with literature in LS; LIT.setLists (LIT:358-385).
- **S22** Book states. Staging: Carpentry I in the main inventory (collected), Carpentry II in a bag inside a bag (collected), setAlreadyReadPages of III to 50 (reading), IV read to its pages (read), V nothing (missing); a skill book in a crate next to him (missing). Truth: getAlreadyReadPages, getNumberOfPages, getAlreadyReadBook, the inventory.
- **S23** Known by level: Carpentry 10 with no Carpentry book read. Read: five Not found. Truth: LIT:92 marks all five known. Record (gap).
- **S24** Sandbox MetaKnowledge 3 (hide unknown). Read: the tab still lists every title. Truth: LIT:124 hides unknown ones. Record (gap, stakes).
- **S25** Open the training rows of Carpentry, Mechanics, Electrical, Agriculture, Long Blade in EN; Carpentry in DE, ES, FR, RU. Read the shown titles. Truth: IN titles and LS LvlSkillTrained (volume order). Suspected bug 3.
- **S26** Fold a training row by click and by A; a click and A on a book row do nothing.
- **S27** Right-click on the heading (and on the Find field) with the grid scrolled so a row sits under it. Read: does a pin menu open (suspected bug 7). Same with a left click right of the disclosure over a training row scrolled under the heading.
- **S28** While open: gain Carpentry XP (the bar moves within 250 ms), pick up a book (collected within 500 ms with the section in view; not while it is scrolled away).
- **S29** Level up while watching (AddXP over the line): the badge changes; no flash (gap, record).
- **S30** Paused: right-click, fold, disclosure and pad A do nothing; the wheel scrolls; the help line still reads.
- **S31** Safe mode on: the Skills key shows the game's window; off again: the game's window goes (CI:218-226).
- **S32** Add-ons (needs the mods): Skill Recovery Journal (lanes, head block, Transcribe key and its stop), Exp Recovery (lane and card), Clear Skill Sheet (tag beside the boost tag, card lines). A mod perk with a new parent: its group shows; a mod skill book whose SkillTrained is not a SkillBook key is left out (as the game).
- **S33** Layout and look: 4K at 26 px font, 1280x800 and 1280x720 at UI scale 1 and 2, Large text; Dark, Light, High contrast; the longest names in DE and RU.
- **S34** Split screen, the second player's Skills key (needs a second controller): the game's own window.
- **S35** Multiplayer (single player can't stage): XP from the server shows; pins survive a reconnect.

### Info

- **I1** Ways in: the Info key (shut, open elsewhere, again), the tab strip, the wheel, the buckle (Full; in Lite there is none), a lipstick's Make Up option (the tab on Hair and beard's make-up part, scrolled to it). Truth: XPU:159-162, CI.
- **I2** Name. Staging: descriptor names "Angel" "Cross"; one empty; both empty; a 30-letter surname. Read: data.nameComma, nameFull, the drawn cut. Truth: getDescriptor():getForename(), getSurname(); ISCS:84 joins "Forename Surname".
- **I3** Weight at 79.4, 79.6 and 80.0 (getNutrition():setWeight). Read: weightStr. Truth: round(getWeight(), 0) (ISCS:117). Suspected bug 2.
- **I4** Trend: setIncWeight, setIncWeightLot, setDecWeight (or qaTrend): "+", "++", "-" and the help line on hover. Truth: ISCS:118-129 picks the same three states.
- **I5** Sex for a man and a woman.
- **I6** Profession: every vanilla profession and unemployed (qaProf walks them). Read: the shown words. Truth: getUIName (ISCS:638-648). The carry permit for each: stamp (wide), box (narrow), the Carry permit row (Simple), REVOKED for burglar. Burger flipper's permit to confirm (bug list).
- **I7** Hair style and beard: bald, short, long, a tied style; a man with no beard and with a goatee; a woman. Truth: ISCS.loadBeardAndHairStyle (ISCS:618-636); beard none reads "IGUI_None" here, "IGUI_Beard_None" there.
- **I8** Hair color: black, dark brown, blonde, white, ginger, and a grey (0.6, 0.6, 0.6) through getHumanVisual():setHairColor. Read: hairColor. Truth: none (ZeD's words); suspected bug 11.
- **I9** Body hair index 0 to 4.
- **I10** Survived for, with a watch on and with none. Read: shown either way. Truth: ISCS:237-240 shows it only while UIManager.getClock():isDateVisible(). Record (rule gap, stakes).
- **I11** Favorite weapon: no Fav keys (ZeD "None", the game hides the row); modData "Fav:Axe" 5 and "Fav:Baseball Bat" 7. Truth: ISCS.loadFavouriteWeapon (ISCS:650-661).
- **I12** Kills: 10 by weapon, then one burned to death. Read: zKills. Truth: getZombieKills (ISCS:228) and KT's fire count; ZeD should read one more than the game after the fire kill.
- **I13** DL number: the same after close and reopen; a surname starting with a Cyrillic or accented letter (suspected bug 10).
- **I14** Dates: sandbox start 7/9 year 1 reads 07/09/1993 and 07/09/1997. Truth: SandboxVars StartMonth, StartDay, StartYear. In multiplayer (single player can't stage) the client's dates.
- **I15** Traits. Staging: a profession with free traits (cost 0), two positive, two negative traits; then none. Read: posTraits and negTraits, counts in the heads, order. Truth: getCharacterTraits():getKnownTraits(); ISCS.setDisplayedTraits shows only those with an icon. A mod trait without an icon (needs the mod): ZeD lists it, the game doesn't (suspected bug 5).
- **I16** Trait hover and pad rest: the card shows the description. Truth: ISCS:608 (label and description).
- **I17** Photo: a click swaps bust and full body and scrolls to the top; a drag turns it without swapping; the wheel on the full body zooms, on the bust does nothing and the tab does not scroll (suspected bug 8); A on `identity:photo`.
- **I18** Studio (single player only): the camera on the photo and A on `identity:studio` open the room; in multiplayer no camera (ZeD_Studio.lua:53).
- **I19** Layout: the drawer at 480 and 220; qaLayout wide and tall at each; Full and Lite switched while the tab is open (the card changes at once). Read: `w._idTall`, `w._idSimple`, nothing drawn past the card.
- **I20** Narrow license details at 220: REVOKED inside the permit box, ISS and EXP stacked, the small pairs one to a row, the survived lines stepped down to 16 px.
- **I21** Hair and beard against the game's menus: with scissors, with a razor, with neither; hair too short; a man and a woman. Read: HB rows and their greyed reasons. Truth: ISCharacterScreen:hairMenu and beardMenu options (ISCS:334-450, 479-535) and their tooltips. Cut queues ISCutHair (and the hat's unequip); Stop clears it; Trim queues ISTrimBeard.
- **I22** Hair and beard with Spongie's Hairstyle Unlocker or Improved Hair Menu loaded (needs the mods): their rows and tags.
- **I23** Make-up part: carried lipstick and a mirror; Apply queues ISApplyMakeUp; Remove is instant.
- **I24** Scroll and pad: Down from the photo through every Hair and beard stop and every trait; each in view; a fold opening under the focus does not jump the page (IT:1658-1667).
- **I25** While open: change weight, hair and a trait; the card follows within 30 frames.
- **I26** Paused: Cut and the part switch do nothing; does a click on the model still swap the photo (record).
- **I27** Safe mode: the Info key shows the game's page.
- **I28** Languages: EN (Simple's three labels lowered), DE (labels kept), RU (sex letter on the narrow card, profession case, the DL letter), JP. Truth: the game's keys IGUI_char_*.
- **I29** Themes and accents: the license keeps its cream in Dark, Light, High contrast; its colored words follow the accent; a window accent of its own.
- **I30** The game's Literature button (ISCS:211-213, 319-323, 452-472) has no place on the Info tab. Record the gap.
- **I31** Split screen, the second player's Info key (needs a second controller): the game's own page.
- **I32** B on any Info stop with a haircut running: the cut stops (FM:1700). The game's B closes the page.

## 4. Suspected bugs (no runs were done)

1. Suspected: a skill pin is keyed by the skill's translated name (PN:113 stores `perk:getName()` from the row, ST:1393, CW:4356-4360). After a language change getPerkByName (ST:238-247) finds nothing, so the pin drops out of the title bar (PN:208-218) yet still counts toward the three (PN:24, 114-118), and the row is no longer marked (ST:1377-1380).
2. Suspected: the weight is floored (IT:407) where the game rounds (ISCS:117): 79.6 kg reads 79 here and 80 there.
3. Suspected: a book's volume numeral comes from its place in an alphabetical sort of titles (ST:396-398), not its LvlSkillTrained (LS). The prefix strip matches the skill's id, not its shown name (ST:402-419): in English it fails for Blacksmith, Electrician, Farming, FlintKnapping, Husbandry, LongBlade, Mechanic and MetalWelding (IN:431, 461, 480, 498, 516, 522, 540, 546), and in DE, ES, FR, RU for every skill, so rows read like `Mechanics I: "Carzone's Repair Guide" Vol. I` or "Carpintería Vol. 1 Vol. I" (ST:1069-1071, ZUI:2646).
4. Suspected: Training materials shows every skill book's title whatever the sandbox's MetaKnowledge (ST:446-507; the game hides unknown ones, LIT:78, 124) and never counts a book the skill already covers as known (LIT:92). Against "keep vanilla stakes".
5. Suspected: the Info tab lists traits that have no icon (IT:253-281); the game shows only traits with one (ISCS:575-583), so a mod's hidden marker trait shows here.
6. Suspected: Survived for always shows (IT:422-424, 858, 1259); the game shows it only while the clock's date is visible (ISCS:237-240).
7. Suspected: the right-click pin menu (CW:6133-6141) and the training rows' click (CW:6036-6046) test the row zones without the scroll view, so a press on the pinned heading or the Find field over a row scrolled beneath it opens that row's menu or folds that training row. ZeD.SkillsTab.onClick does test the view (ST:569).
8. Suspected: the photo model swallows the wheel on the bust (CW:5196-5205 returns true without scrolling), so the tab can't be scrolled with the pointer on the photo; on the full body the zoom has no bounds.
9. Suspected: the "No traits" line is drawn (IT:1533-1535) but not measured (IT:1395-1417), so the content is one line short and the line can sit past the scroll's end.
10. Suspected: the narrow license's SEX letter (IT:442) and the DL number's first letter (IT:322) take the first byte of a UTF-8 string, which breaks a Cyrillic, accented or Japanese first letter.
11. Suspected: there is no grey in the hair color words (IT:178-199): a grey of 0.6 on all three channels reads "Light brown", a darker grey "Dark brown".
12. Suspected: PL:6-9 says the Skills, Health, Info and Protection keys open the Character window while paused. Their only route is XPU:125-131, which returns at game speed 0 (XPU:128); no ZeD key handler for them was found (CW:7901-7912 handles only Toggle Inventory). Either the claim is stale or a route is missing.
13. Suspected: the profession's title case lowers every letter after the first of each word (IT:362-365): a mod's "EMT" or "DJ" reads "Emt", "Dj".
14. To confirm: burger flipper carries a concealed carry permit (IT:45); the other five are the armed jobs and the burglar.
15. Suspected (cost): the Info tab gathers every 30 frames drawn (IT:1588-1594), not on the clock as Skills does (ST:32-51), so at 144 to 240 Hz it walks traits, kills and hair 5 to 8 times a second.
16. Stale comments: ST:4-5 and ST:98-104 (the bar is the way to the next level now, ST:1419-1422); ST:8-9 (a click pins; it doesn't, CW:6035); ST:511-513 ("nothing draws until an extra is added"; RecipeIndex always adds one, RI:373-375); IT:10-11 (identityStyle is retired; Simple follows Lite, SE:742-744, ZeD_MainMenuOptionGroups.lua:162); CW:1679-1681 (the disclosure's zone is stamped at the top of render, ST:1163-1176); CW:3162-3186 and CW:6021-6033 (the Identity heading's disclosure is gone, IT:1597-1601, so both are dead).

## Tests today

| Script | What it checks |
| --- | --- |
| rt_inventory (1281-1289) | openTab on Skills within 20 frames; with toggle it folds |
| rt_inventory (1456-1490) | Find (Skills): the skill typed stays lit, Clear |
| rt_inventory (1491-1530) | The license in forced Simple narrow and Immersive wide; the photo press swaps; the wheel zooms the full body |
| rt_hud (1579-1700) | Pin a skill from the Skills tab; the title bar shows level and XP from getPinData |
| rt_windows (631, 700-710, 1122-1139) | Tab steps on Skills and Info; one stop per trait; the window reopens on Skills |
| rt_media (1677-1720) | Hair and beard: the part switch, a row, Cut queues ISCutHair |
| rt_cards (1919) | The tab strip's press opens Skills |

No script compares a level, a bar, a boost, a book's state, the weight, the traits or the kills against the game's own functions; S5 to S11, S21 to S25 and I2 to I16 are new ground.
