# ZeD visual noise audit, November 20 2026

Brief from the director: "Visual redundancy noise reduction. Simplify complexities."

Report only. No game code was changed, nothing was committed, the game was not launched.

## What was looked at

- The 28 beta 21 captures in `ZeDUI/qa/audits/shots_20261120/` (names starting `p_`). The windows in them were read again from full-size 4K crops, kept in `ZeDUI/qa/audits/shots_20261120/crops/`.
- All 71 gallery pictures in `ZeDUI/workshop/gallery/upload_v1/`. Three helper passes read every one and enlarged each window; I then checked their main claims myself on pictures 00c, 05, 10, 18, 36, 40, 47 and 60.
- `Settings.lua`, `ZeD_MainMenuOptionGroups.lua` and the English words in `UI.json`.

How to read a finding: the picture name comes first, then where to look, then the fix. The last line of each finding (starting "Code:") is for whoever builds it. Line numbers are close, not exact. A pointer marked "not checked" was guessed from a file name.

Two limits. The gallery pictures are book pages with small captures inside, so pixel boxes on them are approximate. And the gallery was shot before beta 21: where beta 21 already changed a surface (the six "Immersive or simple" rows are now one Style switch) I say so instead of reporting it.

## The short version

The same three habits cause most of the noise, on nearly every surface:

1. A fact is written in the title bar, again in the header under it and again in the foot strip. Counts, weights and tab names all do this.
2. A reading is drawn as a colored square, a bar and a number at once, row after row.
3. A plain card states a value, then repeats it as a label on the button that changes it.

Fixing habit 1 in the two inventory windows alone removes about ten repeated numbers and words from the screen the player looks at most.

---

## Visual bugs

These are plain faults, not taste. Crop boxes are x, y, width, height. For `p_` pictures the box is in the 4K source in `%USERPROFILE%\Zomboid\Screenshots\gallery_b21\` (same name without the `p_`, as .png). For gallery pictures the box is in the 1920 by 1080 picture.

**B1. The World window covers the Lite clock.** p_lite_04_appliance and p_map_light_25. With a side tab open (Crafting, Maps) the World window grows to the right and sits on top of the clock: the time, "Speed x1", Pause and the x1 button are under the window and only the date, the temperature, x2 and x3 show. Source `lite_04_appliance.png`, box 3340, 0, 500, 220. Either the window should stop short of the clock or the clock should step aside.

**B2. The Cat column cuts its two most common long names while the column beside it has room.** "Tool / ..." and "Fire So..." in every inventory capture, Lite and Full. An ellipsis right after a slash tells the player nothing. p_lite_01_world, source `lite_01_world.png`, box 1500, 250, 400, 220. Gallery: 00a (1130, 237, 60, 16), 00c (272, 237, 92, 22), 01_hero (1189, 152, 55, 12), 18 (1470, 388, 40, 60), 50 and 58.

**B3. The character's name is cut to "Ange..." while the pinned skill beside it keeps its full length.** 50_night_shift (1118, 250, 40, 10), 57_open_for_business (1085, 576, 40, 12). The note in the code says the pin should shorten before the name does; here it is the other way round. A second case: 24_stocking_shelves title bar cut to "2 co..." (392, 374, 42, 14).

**B4. A stack's parent row cuts its name while its children fit.** "Apple (Fr... (3)" over three rows of "Apple (Fresh)". 00a (1048, 78, 75, 16), 09 (1145, 389, 48, 10).

**B5. Help bands cut a line with a free line under it.** 03_options_menu "Default: Folded: a hint row you can ..." (1480, 637, 152, 14). 04_sandbox_ingame "Default: Base.Hat, Base.Glasses, Bas..." (1050, 811, 390, 14). 00d and 37_building "For the most advanced metal forging, includi..." (1548, 758, 305, 22 and 1473, 414, 160, 12).

**B6. Sandbox labels in the mod pane cut with empty room to their right.** 06_mod_settings (1232, 556, 178, 62).

**B7. Farm plot card: the lock tags sit on top of the bars.** "Farming 2" and "Farming 4" are drawn over the right end of the stage strip and the water bar. 47_farm (790, 778, 60, 12) and (790, 837, 60, 12). The stage words under the strip are also very small and dim.

**B8. Light theme: the icon beside the column title is a solid black blob.** 09_inventory_compare (1121, 358, 12, 12), 01_hero (1066, 57, 14, 14). In Dark it is blue-gray.

**B9. Mod list: the "2 conflicts" chip keeps a black backing on the selected row.** 05_mod_manager (1447, 433, 90, 18).

**B10. Radio tab name cut: "Premium Technologies Ham Ra...".** 49_two_way_radios (405, 420, 220, 22). All three tabs say "Ham Radio", which is what uses up the room.

**B11. Tire names cut: "Tire - Regular (Standard Ve...".** 41_fixing_the_car (628, 600, 205, 62). The cut part repeats what the card already says.

**B12. Crafting says two things at once.** 36_crafting: "Required (2/2)" with both rows green, yet Craft is dimmed and the recipe's square is amber (1587, 638, 60, 24). 37_building: "Show: Ready" is set but the list holds a structure at "Required (0/7)" (1205, 395, 225, 30). Either the filter or the marks are wrong. Worth one look in game.

**B13. Small ones.**
- Two-dot ellipsis in crafting and the action bar ("Bucket of Clay Ce..", "YONTEL THE SWO..") against three dots everywhere else. 00d (1100, 420, 300, 26), 21 (1098, 440, 160, 14), 37 (1453, 539, 105, 14).
- "View > OPTIONS" in capitals in a sentence-case list. 54_quick_actions (1058, 800, 70, 10).
- Item card: the "Kind" value drops to its own line and leaves "Kind" alone on a row. 10_item_cards (1270, 609, 150, 30).
- Fishing: the conditions line wraps and leaves "Wind: Unknown" alone on a second line. 48_fishing (533, 838, 360, 28).
- Hair and beard: "Grows over time" sits on the Color row, so it reads as a fact about the color. 31_old_job (1543, 605, 90, 12).
- Uploader: the description preview runs the heading into the first sentence. 63_uploader (390, 658, 410, 12).
- Foraging day arc: the end numbers "7" and "17" look as if they touch the tick marks. 38 (1055, 322, 85, 16). Not certain at this size.

Code for B1: ZeD_Watch.lua:ZeD_Watch:_plain and the World window's width in ZeD_WorldWindow.lua:updateDrawer. B2 and B4: InventoryRenderer.lua, the column layout near line 2603. B3: ZeD_CharacterWindow.lua:composeCharTitle (line 758). B7: ObjectCardFarm.lua:lockTag (line 360).

---

## Findings, biggest win for the least risk first

### 1. The inventory windows say the count three times and the weight twice

p_lite_01_world and p_full_10_same, both windows. Also every gallery picture with an inventory in it.

- Character window: title bar "11.4 / 18 kg", header "11.4 / 18 kg" with "8 items" under it, foot strip "2 of 8 picked | 3.0 kg" (or "8 items" when nothing is picked).
- World window: title bar "10 items", header "6.2 / 50 kg" with "10 items" under it, foot strip "10 items".
- The foot strip keeps counting the inventory when the window is showing something else: "9 items" under the Radio card (p_lite_03_radio), "8 items" under Health and Skills (p_tour_19, p_tour_21), "0 items" under Crafting and Maps.

Fix: the header keeps weight and count, since it sits on the list. The title bar drops both while the list is on screen. The foot strip shows only the picked line ("2 of 8 picked | 3.0 kg") and is blank otherwise. That removes five numbers from one screen and ends the count under the Radio and Health tabs.

Code: ZeD_CharacterWindow.lua:updateDrawer (title numbers near line 6298, foot near 6338 to 6370). ZeD_WorldWindow.lua:updateDrawer (near 4931 to 4972). InventoryRenderer.lua:renderMultiColumnContent (line 3396). InventoryFilter.lua:IF.countText. InventoryPicked.lua:P.line.

### 2. An empty container says "empty" four ways

p_lite_03_radio, p_lite_04_appliance, p_map_light_25 and every tour picture, Ground column. Gallery 01_hero, 00b, 50, 57. Title bar "0 items", header "0 items", "Nothing here." in the body, foot strip "0 items", and the column heads "Name Cat Status Wt" over no rows.

Fix: "Nothing here." alone. Hide the counts and the head row when a column is empty.

Code: InventoryRenderer.lua, the empty line near 3050 (UI_ZeD_Inv_Empty), plus the places in finding 1.

### 3. The tab's name is stacked two or three times at the top of the window

- p_tour_19: title bar "Angel Cross + Health", header "Health". p_tour_21: "+ Skills" over "Skills".
- p_lite_04_appliance: title bar "Ground + Crafting", header "Crafting", pop-up "Station: Microwave", band "Microwave". Four lines to say "microwave".
- p_map_light_25: "Ground + Maps" over "Maps".
- p_lite_03_radio: "Angel Cross + Radio" over the tab "Premium Technologies Radio".
- Gallery 32 and 51: title bar "Journal", header "Journal", first inner tab "Journal", inside 160 pixels. 62: "Erma Finn + Server" over "Server". 31: Identity and Skills the same.
- The lit icon on the side rail is one more cue on top of these.

On Crafting and Maps the header is a whole band that holds nothing but the one word.

Fix: say it once. The title bar already names the tab, so remove the header word, and remove the header band where the word is all it holds (Crafting, Maps, Health, Thermal, Identity). Where the header holds a real control (the Skills search box, the Journal search box) let the control have the row. In the Journal, name the first inner tab "Log": the same screen already calls it that ("Into: the log only").

Code: ZeD_CharacterWindow.lua:composeCharTitle. JournalTab.lua:drawHeader (line 1586). ThermalTab.lua near 365. Stations.lua:ST.renderViewHeader (line 863).

### 4. The plain appliance card repeats its own labels on its buttons

p_lite_04_appliance (Lite) and 27_ovens (Full). On the microwave, top to bottom: "Station: Microwave", then "Microwave 2 tiles | Appliance [dot] Off", then a readout "Timer -- / [dot] Off | Med" beside a large "Power level Med", then the rows "Power level Med [Power level]" and "Time cook -- [Time cook]". "Power level" three times, "Med" three times, "Off" twice, "Microwave" twice. "Appliance" restates "Microwave". "2 tiles" is the distance to it, yet the gallery book itself reads it as a size.

Fix: remove the band (the pop-up names the station, the state is in the readout). In the rows, let the button carry the value: "Power level [Med]", "Time cook [--]". Then the big readout and the rows no longer say the same thing twice. If the band stays, cut "Appliance" and write "2 tiles away".

Code: Stations.lua:ST.drawBand (line 719). StationAppliance.lua:readoutOf (line 747) and the row table near 551.

### 5. The plain radio card says the frequency twice and the power state three ways

p_lite_03_radio and 60_full_or_simple. Top block "Frequency / -- / Off". Then "Power  Off  (o) Off  ( ) On": the word and the radio button side by side. Then a second "Frequency -- [-] [+]" row. In the gallery capture with the radio on: "98.0 MHz" twice, "Presets 3" over keys 1 2 3 4 with 3 already lit, and a lone "[dot] On" under Battery.

Fix: put the [-] [+] keys in the top frequency block and delete the second Frequency row. The Power row keeps only the Off and On pair. Drop the "3" beside Presets and the lone "On".

Code: PlainFace.lua (presets near line 213). RadioTab.lua near 587 to 623.

### 6. The Lite clock: "Speed x1" sits right over a lit "x1" button

p_lite_01_world, top right (source `lite_01_world.png`, box 3340, 0, 500, 220). The panel reads "Speed x1" and directly under it are Pause, x1, x2, x3 with x1 lit green.

Fix: delete the "Speed x1" line. "Alarm off" can move up beside the temperature, which also saves a row.

Code: ZeD_Watch.lua:ZeD_Watch:_plain (the line near 642).

### 7. The Mods screen counts its mods three times, and explains folders that Lite does not have

p_lite_09_mods and p_folders_26. Title bar "[dot] 1 of 12 on", tabs "All 12 / On 1 / Off 11", foot strip "1 of 12 on". Under the Find box a two-line caption: "Collection  Every installed mod, on or off. Folders sort this list; they never change the load order." In Lite there are no folders on the screen at all.

Fix: the tabs already carry the counts, so drop the title bar count and the foot line. Hide the caption in Lite. In Full cut it to "Folders only sort this list." and drop the word "Collection".

Code: ZeD_MainMenuMods.lua:ZeD_MMMods:prerender (line 1126) and ZeD_MMMods:getStatusLine (line 1156). ZeD_MainMenuModsFolders.lua:ZeD_MMMods:listLine (line 82).

### 8. Question windows: an empty title bar, the title in the body and an empty strip under the buttons

p_lite_02_confirm (source `lite_02_confirm.png`, box 520, 900, 620, 320). Gallery 23_questions and the note in 00c. The title bar holds a close box and a window-menu box and no title. "Change Item Name" is a heading in the body. Under Cancel and OK is one more empty band. A yes or no question does not need the Theme and Accent menu, and the close box doubles Cancel.

Fix: put the heading in the title bar, drop the menu box and drop the foot band on questions and on the on-screen keyboard. A System 7 dialog is a title, the question and the buttons.

Code: ZeD_Prompt.lua:ZeD_Prompt:new and its layout. ZeD_Keyboard.lua (not checked).

### 9. The empty strip at the foot of every window

p_lite_08_desk, p_lite_07_setup, p_welcome_12, p_lite_02_confirm. Gallery 02_desk (Trash), 04 (Paused). Each window ends with a full-width strip that is blank most of the time. In the inventory windows the strip holds only the repeated count (finding 1).

Fix: collapse the strip when it has nothing to say. Controller hints and a help line bring it back.

Code: the status line each screen supplies (getStatusLine in the ZeD_MainMenu files) and the window frame that draws it.

### 10. Sliders show their value twice

p_lite_07_setup: See-through has "90%" at the right and a bold "90%" in the tick row. UI scale has "1.75x" twice. Gallery 03: "Wheel stick dead zone 0.35" twice.

Fix: where the ticks are labeled, drop the number at the right. Keep it only for Auto, where it tells the player what Auto came to.

Code: ZeD_MainMenuOptions.lua:scaleReadout (line 1018) and ZeD_MMOptions:drawControl (line 1231).

### 11. Vehicle parts: every row reads its condition three ways

40_vehicle_tab and 41_fixing_the_car. Each row has a colored square, a five-part bar and "100%". The car plan beside the list shows the same thing a fourth time in color. Over the list sit two heads, "Part" and "Cond", and the foot has "Sort: Category", so the heads are a second sort control as well.

Fix: square and percent, no bar. Drop the two heads.

Code: MechanicsTab.lua near 1595 (square), 1112 (bar), 1557 (heads).

### 12. Skills: the level is a number at the left and a bar at the right

p_tour_21, 30_skills, 31_old_job. Every row shows "0" and an empty ten-part bar, or "6" and six lit parts. On a new character that is 36 rows of a zero beside an empty bar.

Fix: let the bar show progress to the next level, which today only the hover line knows ("Long Blade - Lv.0 - 0/75"). Then the number and the bar say different things. Short of that, no bar on level 0 rows.

Code: SkillsTab.lua near 1396 to 1409.

### 13. The tour: two buttons that do the same thing on the last step, and balloons twice as long as they need to be

p_tour_25 (source `tour_25.png`, box 2150, 1760, 620, 330): "Stop tour" and "Done" side by side on step 12 of 12. p_tour_17: "The game's icons from the top left corner of the screen live here now, as tabs down the side of the window: Loot, Equipment, Health, Thermal, then ID, Journal and Skills. Click one to open it beside the window." p_tour_19 (Health) runs to 37 words and ends "as the game's own health panel offers them".

Fix: hide "Stop tour" on the last step. Suggested texts: "The tabs: the game's top-left icons live here. Click one to open it." and "Health: a wound shows on the body and in the list, worst first. Click it to treat it."

Code: ZeD_Tutorial.lua:show (line 265 picks Next or Done; the Stop button is drawn near 186). Words: UI_ZeD_Tut_Tabs_Text, UI_ZeD_Tut_Health_Text and their controller twins.

### 14. The first-launch window is half empty and explains its own preview

p_welcome_12 and p_welcome_13. The seven choices end halfway down; the lower half of the window is blank. "Skip / ZeD as it comes" is a choice at the top, and the foot line says "Skip gives you ZeD as it comes." again. The preview has a "PREVIEW" label over a box titled "Inventory" and a note under it: "The preview and the desk change as you pick." The row is named "Theme" here and "Base theme" in ZeD setup.

Fix: size the window to its rows. Drop the preview note and the first sentence of the foot line. Call it "Theme" in both places.

Code: ZeD_MainMenuWelcome.lua:ZeD_MMWelcome:prerender (lines 294, 321, 333).

### 15. Health tab: "healthy" said four ways, and the exercise named twice

p_tour_19. "[dot] Overall 100%", a full green bar, "OK", "[dot] No injuries". Lower down the pop-up reads "Exercise: Squats" and the text block is headed "Squats".

Fix: when nothing is wrong show the bar and "No injuries". The percent and "OK" come back when there is something to report. Drop the "Squats" heading over the description.

Code: HealthTab.lua:ZeD.HealthTab.drawOverall (line 602) and ZeD.HealthTab._renderHeader (line 836).

### 16. Part card: one instruction three times, and the title repeated as a row

40_vehicle_tab: "Rear Left Tire need to be uninstalled first", then a button "Rear Left Tire", then "With Basic Mechanics (recipe), Rear Left Tire (must be off) you could take the part off." 41_fixing_the_car: title "Front Left Tire" then the row "Location  Front Left Tire". "Standard" is at the tab's top right, in "Type  Standard" and inside each tire name, where it causes the cut in bug B11.

Fix: one line and the button: "Take off first: [Rear Left Tire]". Drop the Location row when it equals the title. Strip "(Standard Vehicle)" from tire names on a standard car. Writing ZeD's own line also removes the game's grammar slip ("need").

Code: MechanicsTab.lua, card body near 1780 to 1830 (Location at 1789).

### 17. Cooking: the dish and the pot are named in the pop-ups and again as headings right under them

26_cooking. "Dish: Stew" and "In: Cooking Pot", then the pane opens with "Stew" and "Cooking Pot".

Fix: drop the heading pair. The pane starts at "Ingredients 3 / 6".

Code: CookingTab.lua near 838 to 862.

### 18. The action bar shows progress three ways and cuts the title to make room

16_action_bar_compare, 21_bubbles, 35_barricading, 00c. "BARRICADING 2/3", "39%" and a bar with step marks. In 21 the percent costs the book its name: "YONTEL THE SWO.. 30%".

Fix: drop the percent and give the name the line. The Vehicle tab repeats the same job as a second bar and percent (41, "Installing Tire - Old 35%"); that one can lose its percent too.

Code: ZeD_ActionBar.lua:AB.drawVerboseBody (line 636).

### 19. The reader's side column repeats the title bar

29_reading_writing and 32_the_plan. "This piece / Kind Newspaper / Date July 1 1993 / Read [dot] Yes" beside a newspaper whose title bar reads "Knox Knews - July 1 1993" with "[dot] Read" at its end. For the flyer the place name is in the title bar and again under "Places". In the notebook, nine rows each say "Blank".

Fix: delete the "This piece" block. Blank pages show their number only, dimmed.

Code: ZeD_Reader.lua near 392 to 405 and 983. ZeD_JournalReaders.lua near 511 to 524.

### 20. Seat chooser: the key is shown three times

39_driving_in. The "1" on the seat, the note "Free. Press 1 to sit here." and the foot line "1-4 Sit  Esc Close".

Fix: the note reads "Free."

Code: ZeD_SeatPopout.lua lines 48 and 423 (UI_ZeD_Seat_FreeSit).

### 21. Every pop-out device carries the caption "Click a control.  Esc closes."

46_laundry (three times), 49_two_way_radios, 27_ovens. A dark band under a machine, explaining the obvious.

Fix: remove it.

Code: TwoWayFull.lua:ZeD_TwoWayFull:mouseLine (line 257), UI_ZeD_FacePop_Hint.

### 22. Two identical pin boxes in each title bar

p_lite_01_world and every other window capture: a pin after the close box and a second, identical pin before the menu box (source `lite_01_world.png`, box 745, 0, 1130, 45). One belongs to each half of the window.

Fix: one pin while the halves are joined. If the two must stay, they need different pictures.

Code: ZeD_CharacterWindow.lua:updateDrawer near line 6821.

### 23. The word "Dist" over the container strip, and strips of look-alike icons

p_lite_01_world, 18, 24_stocking_shelves. "Dist" sits over the strip of container buttons like a column head with nothing under it. It is a sort setting. In 24, with four columns open, each column has its own strip, about 16 near-identical shelf icons. In p_lite_01_world the three shelves are the same icon three times with nothing to tell them apart.

Fix: show the sort word only when the order is not the usual one (the code already knows). Hide a strip when every container in reach already has its own column.

Code: ZeD_CharacterWindow.lua:drawContainerStrip (line 3817). ZeD_WorldWindow.lua:drawWorldContainerStrip (line 3281).

### 24. Two main buttons on the Mods screen

p_lite_09_mods and p_folders_26. "Turn on" and "Accept" are both drawn as the main action (both green in Lite, both double-framed in Full). "Turn on" also does what the check box on the mod's row does, 300 pixels to its left.

Fix: Accept is the one main action. Draw "Turn on" plain, or drop it and let the check box do the job.

Code: ZeD_MainMenuMods.lua, the info pane buttons near line 1833.

### 25. Mod rows carry the mod's ID under every name

p_folders_26, 05, 08. "Camp Stove Plus / LC93DemoStove", "Dishes / Dishes". The pane beside the list has a "ModID" row. Lite already leaves the ID out and the list is half the height.

Fix: leave it out in Full too. Find can still match it.

Code: ZeD_MainMenuMods.lua, the list row.

### 26. Mod info pane: each problem stated twice, and a heading that repeats its tab

05_mod_manager: a banner "Needs SampleSoundLibrary" and under it the row "Needs / SampleSoundLibrary, not installed". "Made for another game version (42.99.0 to ?)" and under it "Game 42.99.0 to any". Tab "Conflicts 2" then the heading "Conflicts 2". 06: tab "Options 8" then "Options"; tab "Sandbox 4" then "Sandbox settings"; every file row ends "named after the mod". 07: three lines of small print before the verdict ("Saves keep their own mod lists, so this list changes new games only. In a save's own list...").

Fix: the banner gives the verdict, the row gives the detail, and both say "any". Drop the headings under tabs. Say "named after the mod" once. Open the turn-off text with "In a save that uses it:".

Code: ZeD_MainMenuMods.lua lines 377, 387, 1901, 1954, 2017. ZeD_MainMenuModsPanes.lua lines 316, 374, 487. UI_ZeD_Mods_OffForMain.

### 27. Load order: a green square on every row

08_load_order. Every row that is fine has a green square; only the red and yellow ones say anything. Beside it: "Your rules (0)" over "None yet."; the note "needs Enhanced Medical (10)" repeated as "Needs Enhanced Medical: it loads later, at 10." and again as "Fix the red rows (or press "Auto")". The button row mixes "Move Up" and "Move Down" with "Load first" and "Load last".

Fix: no mark on a row that is right. One sentence per problem. Sentence case on all four buttons.

Code: ZeD_MainMenuModsOrder.lua lines 999 and 1138.

### 28. Sandbox options in game: a tag on every row

04_sandbox_ingame. "Now" on most rows, "Fixed" on rows that are already grayed, and the help band repeats it as "On this save | Now".

Fix: tag only the exceptions ("Careful", "New places", "Can't undo").

Code: ZeD_SandboxInGame.lua lines 639 and 809.

### 29. Options: the same warning under each replaced setting, and a help band that repeats the choices

03_options_menu. "Context Menu Font / Does nothing with ZeD active", "Inventory Font / Does nothing with ZeD active", each with its own yellow square. Hidden actions offers "Folded: a hint row you can open", "Show all, grayed", "Hide", and the band under it explains the same three again.

Fix: hide the rows that do nothing while ZeD is on. One-word choices (Folded, Grayed, Hidden) and let the band explain.

Code: ZeD_MainMenuOptions.lua line 394 (UI_ZeD_Options_MootUnder).

### 30. Crafting and Building: a fold header that repeats the filter, and a badge on every row

36_crafting, 37_building, 00d. "Category: All" right over "All Recipes (3)". "Known" on every known recipe, when only "not known" is news. Two colored squares per ingredient row. A lone "-" or "<" at the end of each Required row. "Sort: Craftable" and "Show: Ready" cover the same ground. Building says "All Recipes" over a box that says "Search structures...". "Outputs (1)" heads one line that repeats the recipe's title.

Fix: show the fold header only when the list is split into groups. Badge only the unknown. One square per row. "All structures" in Building. Hide Outputs when it is the one thing named in the title.

Code: CraftingCore.lua lines 1981, 2631, 2742.

### 31. Farm plot card: "Ready" three times, "Farming N" five times

47_farm. Title "Farm Plot [dot] Ready", heading "Ready to harvest Tomato Vine" and "Ready" as a cell of the stage strip. Then "Your farming 0", "Farming 2", "Farming 6", "Farming 4", "Farming 3" on four mostly empty bars.

Fix: drop the chip in the title. One dim line ("More at Farming 2, 3, 4 and 6") and hide the locked bars. This also clears bug B7.

Code: ObjectCardFarm.lua:lockTag (line 360), body near 552 to 564.

### 32. Henhouse and pasture cards: the door, the count and "Empty" repeated

47_farm. Henhouse: title "[dot] Open", chips "[dot] Door open  [dot] Egg hatch open", buttons "Close Door" and "Close hatch". "9 eggs | 4 boxes" over four drawn boxes. "Grab Eggs", a "Grab" in each box and a "Grab" on each hen. Pasture: "11 animals" in the header, on the trough row and as "Animals (11)". The trough row says "Empty | 11 animals" and "Empty" again at its right. "[dot] Door open" sits against a button "Open" that means "open the card". A full-width band holds only the "<" back button. One building has three names: "Hutches", "Henhouse", "Coop Roosting".

Fix: drop the chip row (the two buttons say it). Drop "| 4 boxes", the header count and the right-hand "Empty". Call the row button "Card". Put "<" on the "Home Pasture" line. One name for the henhouse.

Code: ObjectCardHutch.lua body (line 424, chips at 436). AnimalsTab.lua lines 1900, 1914, 2052.

### 33. Fishing: two status bands for one state, and rows that say nothing

48_fishing. "[dot] Line in the water" directly over "[dot] Waiting for a bite  0:04 | Tight". "Line 100%, wearing while the tension is past the mark" and lower "Line  Fishing Line [bar] 100%". "Fish  Unknown until landed". "Held at the limit 0%" over an empty bar. A conditions line with six dots, two of them on place names and two on "Unknown".

Fix: one band. Hide a row until it has something to say. Hide unknown conditions.

Code: FishingTab.lua:drawLineBand (line 876), drawTension (line 634), rows at 663 and 671.

### 34. Item card beside its own row

p_full_10_same, p_lite_01_world, 10_item_cards, 58. The card's first rows ("Kind  Tool / Weapon", "Weight 1.5 kg", "Condition 10 / 10") repeat the lit row right beside it, and the row calls the same thing "Cat" where the card says "Kind" and the vehicle card says "Type". Full adds the word "Marked" before four icon buttons. The apple's card has "Fresh ... [dot] Fresh" under the name "Apple (Fresh)". The jacket shows "Zones 60%", a bar, then Upper, Lower and Back each with a bar and "60%": one number five times.

Fix: one word for kind across the list, the card and the vehicle card. Drop the word "Marked". Fold Zones shut when every zone equals the total. Bar or number, not both.

Code: ItemCardOrganism.lua near line 524 (the Kind row). Molecules.lua line 2755 ("Marked").

### 35. An open stack repeats itself

00a, 09. Parent row "Apple (Fr... (3)  Food  (0.6)" then three rows "Apple (Fresh)  Food  0.2".

Fix: child rows show only what can differ (weight, freshness, condition). This also ends bug B4.

Code: InventoryRenderer.lua, the row drawing near line 2787.

### 36. Grid view keeps the list's column heads

11_grid_view. "Name Cat Status Wt" squeezed over a grid of tiles that has no columns.

Fix: hide the head row in grid view. Sort from the filter button.

Code: InventoryRenderer.lua near line 2603.

### 37. Full style: the list or grid switch is the brightest thing in every column header

p_full_10_same (source `full_10_same.png`, box 1560, 40, 220, 80), 18, 24, 50, 56, 57, 58. A solid accent square in each header, up to four on screen, and it is a view switch, not an action.

Fix: draw it as an outline, like the filter button beside it. See also the Lite note on the same two buttons.

Code: InventoryRenderer.lua:drawViewToggle (line 1277).

### 38. A fold arrow whose only job is to hide the tab's one section

p_tour_19 ("v Health"), p_tour_21 ("v Skills"), 31 ("> Identity"), 33 ("v Thermal"). Its help text is "Show or hide the skills." The arrow also points right on Identity while its content shows and down on Skills.

Fix: no fold on a tab with one section. This goes with finding 3.

Code: ThermalTab.lua near 365. UI_ZeD_Skills_HelpHeader, UI_ZeD_Health_HelpHeader.

### 39. Messages window: the mod's name four times, three accent buttons

22_messages. With "Sample Radio Plus" picked in the list, each note's header repeats "[dot] Note  Sample Radio Plus | Day 19, 11:37". Two "Ok" buttons and "Mark all read" all carry the accent frame. On the belt, the unread count uses the same square badge as the slot numbers, so the belt reads "2, 3, 3".

Fix: the note header shows the day and time only. Accent on one button. A different shape for the unread count.

Code: ZeD_MessagesWindow.lua near line 473.

### 40. Identity tab: the hair facts twice

31_old_job, 59_hidden_actions. The card shows "Hair style Grungey", "Hair color Red", "Facial hair None"; 120 pixels lower "Hair and beard" repeats all three. "Beard  None  [empty bar]  None". "Now" and "After" caption two pictures already joined by ">". "Choose a row to see what it needs" beside a dimmed button.

Fix: the lower block keeps only the length bars. Drop "Now", "After" and the help line. No bar for a beard that is not there.

Code: ZeD_HairBeard.lua near 1338 to 1380 and 1728.

### 41. Thermal tab: two bars with no labels

33_thermal. "Core / Air / Wind", then a bar with no label that is the core temperature but sits under "Wind", then "Body Heat Generation  Normal" and a second bar that repeats "Normal". "Wind 20.1°F" is a temperature under the word Wind.

Fix: put the core bar under "Core" or drop it. Word or bar for body heat. Say "Wind chill".

Code: ThermalTab.lua near 414 to 428.

### 42. Loadouts and the Journal: the same number of days, the same month

25_loadouts: "2 days" in the stepper, in "Supplies for 2 days" and in "a day x 2, or fixed". "Machete / this one, main hand" with "to main hand" at the right. 32 and 51: group header "July, Year 1993 (1)" over "Day 7  Jul 23, 1993 - 10:05". Eight tag chips in six colors on a writing surface.

Fix: "Supplies", no cap line, one "main hand". Header "July 1993 (1)", entry "Day 7  Jul 23  10:05". Tags in one quiet color until picked.

Code: ZeD_EquipLoadout.lua lines 1091 and 1092. JournalTab.lua line 466 (UI_ZeD_Journal_GroupLabel).

### 43. Foraging and Furniture

38_foraging_furniture. "[dot] Fair Searching Winter Clear" is three tags behind one dot. Heads "Dist / Name / Wt" over three rows. The same teal square starts every row. "-1% Net" is cryptic. Furniture: the bench in the card is listed again under "On this tile (1)". "Tool needed  [dot] Ball-peen Hammer  + 3 more" reads as four tools needed.

Fix: separate the tags. Drop the "Name" head and the row squares. Hide "On this tile" when it holds only the piece in the card. "Tool", and "or 3 others" if they are alternatives.

Code: ForagingTab.lua lines 354 and 756. FurnitureTab.lua line 395.

### 44. Context list: a rule after almost every row

12_context_menus, list style. Ten actions and five rules; "Eat", "Drop", "Rename" each sit alone between rules. The strip style is clean.

Fix: three or four groups (use, move, mark, manage).

Code: ZeD_ContextList.lua line 82. Groups in ContextMenuRegistry.lua.

### 45. Equipment doll: about 35 empty dashed boxes

13_equip_doll. Small groups for ears, nose, elbows, wrists, belly button, rings, tail and more, nearly all empty. "Neck" and "Belt" each name both a large slot and a small group.

Fix: draw a small group only when it holds something or while an item is being dragged. Medium risk, since the boxes are drop targets.

Code: EquipDoll.lua:drawSmall (line 513), groupName (line 577).

### 46. Admin and Server tabs

62_multiplayer. "Tickets  0 open" then "No tickets match. Nothing open: good." A red box around "you: [admin]", the loudest mark on the tab and not an action. Server: heading "PvP", chip "[dot] PvP off", button "Turn PvP on".

Fix: "No open tickets." The role in plain dim text. One row: "PvP  Off  [Turn on]".

Code: ZeD_AdminCards.lua lines 612 and 779. ServerTab.lua.

### 47. Card labels are drawn in the accent color

40, 41, 47, 59, 60, 63 and p_lite_03_radio, p_lite_04_appliance. "Condition", "Type", "Frequency", "Power", "Timer" and the rest are in accent teal, so the brightest color on a card sits on its least important words and competes with the lit tab and the main button. The Fishing tab uses dim gray for the same job.

Fix: dim gray labels everywhere, as Fishing has them. This is the largest single calming change in the list, but it touches every card, so it ranks low on risk, not on worth.

Code: the label drawing in Atoms.lua and Molecules.lua (not checked which call).

### 48. The Maps tab carries three kinds of switch at once

p_map_light_25 and 34_the_route. A row of seven icon buttons, "Aa", five color squares and a full-screen button over the map. Under it, radio buttons "Survey / Color / Paper" and a key button. In 34 the key has framed tabs "Colors / Symbols", so "Colors" and "Color" sit 100 pixels apart and mean different things. The pin card ends "Click to read".

Fix: show the five color squares only while a drawing tool is picked. Name the key tab "Key". Drop "Click to read".

Code: MapsTab.lua, MapsTabKey.lua, FlyerMap.lua line 213.

### 49. The main menu offers the same five places three ways

p_lite_08_desk. New game, Load game, Join a server, Options and Mods are buttons in the window, icons on the desk beside it and items in the menu bar above it. A menu bar plus icons is the System 7 way, and the desk is the mod's signature, so this is a taste call. If one goes, it is the row of five full-width buttons: the window could be just the Continue card. Also "Tutorial (the game's own, without mods)" can be "Tutorial (no mods)".

Code: ZeD_MainMenu.lua and ZeD_MainMenuDesktop.lua.

---

## Lite against Full, picture by picture

**p_lite_01_world against p_full_10_same (the same moment).** Lite is simpler in four places: the belt has no strap or buckle, the card has no "Marked" row, the Character foot has one button where Full has three (the World foot two against three), and the watch is a plain panel. Lite is wordier in two: the header's two small icon buttons become word buttons, "Filter" and "List view", in every column, and the clock panel carries nine pieces of text where the watch face carries a time. "List view" also names the state, not what a click will do. Lite still carries all of Full's repeats: count three times, weight twice, both pin boxes, "Dist", the column heads, and the pinned skill in the title bar ("Long Blade - Lv.0 - 0/75"), which is an extra the game does not have. Verdict: a little simpler. The window chrome is untouched, and that is where the noise is.

**p_lite_02_confirm.** Same window as Full with a green OK and a red Cancel. No simpler. Finding 8 applies to both.

**p_lite_03_radio.** A plain card in place of the radio face. Easier to read at a glance than a drawn radio, but it has more repeats than the face does (finding 5). Simpler in kind, noisier in detail.

**p_lite_04_appliance.** The same story (finding 4), and the wide window covers the Lite clock (bug B1).

**p_lite_05_dash.** One drawn dashboard for every car. It is a prop and has no repeats. Fine as it is.

**p_lite_06_watch.** The plain clock. Simple, apart from "Speed x1" over the lit x1 (finding 6).

**p_lite_07_setup.** Lite hides the Additions group and the Quick actions rows, which removes about 30 rows. That is the largest real simplification Lite makes. The Look group is the same eleven rows in both.

**p_lite_08_desk.** The window is plain; the desk around it (monitor, posters, can, books) is all still there. That is the main menu's character and I would leave it, but it means Lite does not change the first screen a player sees.

**p_lite_09_mods against p_folders_26.** Lite is clearly simpler here: no folders, no IDs under names, no tabs in the info pane, four foot buttons against five. It still counts the mods three times and still shows the caption about folders (finding 7).

**Where Lite still carries Full's clutter, in one list:** the triple count and double weight, the stacked tab names, the two pin boxes, the empty foot strip, the "Dist" word, column heads over empty lists, the fold arrows on Health and Skills, the level number beside the level bar, and accent-colored labels on every plain card. Findings 1, 2, 3, 9, 12, 22, 23 and 38 would each make Lite and Full simpler together, because they are in the shared window frame.

---

## ZeD setup: every option, with a judgement

Source: Settings.lua and the page layout in ZeD_MainMenuOptionGroups.lua (G.ZED_GROUPS). The page has about 68 rows in Full (11 Look, 18 Additions, 7 Windows, 2 HUD, 8 Controls, 12 quick actions, 10 Troubleshooting) plus six mirrored game settings. The judgements below would bring it to about 45.

### Look

| Option | Judgement | Why |
|---|---|---|
| Style (Full, Lite) | Keep | The one switch that replaced eight. |
| Base theme | Keep, rename "Theme" | The first-launch window and every window menu already call it Theme. |
| Accent color | Keep | |
| Status colors (Standard, Color blind) | Merge with the game's Accessibility colors | Lite buttons already read the player's good and bad colors from the game. Bars and checks can read the same two and this row can go. |
| Map (Follows the theme, Always light) | Merge with the Maps tab | The map already has its own Survey, Color, Paper switch on it. A light-or-dark choice belongs beside that, not in setup. |
| Text size | Keep | |
| See-through | Keep | |
| Solid while in use | Drop the switch | Make it the rule: a window in use is solid. It is on by default and nobody needs the other way. |
| Blink the low-health pixel | Drop | A setting for one pixel. Pick solid red and be done. |
| Item-colored tiles | Drop | Off by default, grid view only. If it stays, let Full turn it on and Lite off. |
| UI scale | Keep | |

### Additions (hidden in Lite)

| Option | Judgement | Why |
|---|---|---|
| Preset (Vanilla, Vanilla Plus, Vanilla Access, Custom) | Keep | It is the simplifier. Consider showing the 17 switches under it only when Custom is picked. |
| Ammo on the belt | Keep | |
| Read marks in item lists | Keep, absorbs the next two | |
| Next level on skill books | Merge with Read marks | It is one more read mark. |
| Dim read items | Merge with Read marks | Same subject, same lists. One three-way: Off, Marks, Marks and dim. |
| Dashboard warning lamps | Keep | |
| Moodle notices | Keep | |
| Keep other mods' notes in Messages | Keep, absorbs the next | |
| Show a toast when one comes | Merge with the row above | It does nothing unless the row above is on. One three-way: As the game, In Messages, In Messages with a toast. |
| Overhead notes | Keep | |
| Hint strip | Keep | |
| Put things back after an action | Keep, halve the help | The help is about 50 words. "Puts back what an action took out, leftovers and hands too. Takes game time. Not after an interruption." |
| Sandbox options in game | Keep | Changes the stakes, so the player should choose it. |
| Hidden facts (Find first, Always) | Keep, absorbs the next | |
| Recipes skills teach | Merge with Hidden facts | Both reveal what the game keeps quiet. "Always" can include it. |
| Loadouts and outfits | Keep | |
| Restock (Hardcore, Casual, Access) | Keep, hide while Loadouts is off | Today it dims with a reason line; hiding is quieter. |
| Additional appliance support | Keep | Carries a real warning. |

### Windows

| Option | Judgement | Why |
|---|---|---|
| Inventory (List, Grid) | Drop from setup | Every column header has the view button and remembers it. |
| Context menu (Icon strip, List) | Keep | |
| Equipped items (list, doll) | Drop from setup | The Equip tab has its own switch for this. |
| Character window accent | Drop from setup | Each window's menu has Accent, and the help line says so. |
| World window accent | Drop from setup | Same. |
| UI sounds (Full, Quiet, Off) | Keep | |
| Hidden actions | Keep, one-word choices | "Folded", "Grayed", "Hidden" (finding 29). |

### HUD

| Option | Judgement | Why |
|---|---|---|
| Moodles (Right, Left, Above the belt) | Keep | |
| Watch (On the belt, Corner) | Keep, hide in Lite | Lite's clock is always in the corner. |

### Controls

| Option | Judgement | Why |
|---|---|---|
| Controller highlight | Keep | |
| Gamepad glyph display (seven choices) | Merge with the game's own controller button style | Auto already follows it. Keep at most "Auto" and "Letters". |
| Input mode lock | Keep, rename, move to Troubleshooting | The first-launch window asks the same thing as "Playing with: Mouse and keys, Controller". One name for both. |
| Wheel open (Tap, Hold) | Merge | These three are one choice. Toggle mode overrides the other two, which is why they dim. One pop-up: "Hold and flick", "Tap and flick", "Tap and click", "Toggle". |
| Wheel commit (Flick-release, Stick click) | Merge with Wheel open | |
| Wheel toggle mode | Merge with Wheel open | |
| Wheel stick dead zone | Keep | A drifting stick needs it. |
| Run button also sneaks | Keep, halve the help | The help is close to 80 words. |

### Quick actions (controller, hidden in Lite)

Twelve rows, one per chord. Keep. See the wording notes for the picker.

### Troubleshooting

| Option | Judgement | Why |
|---|---|---|
| Safe mode | Keep | |
| Safe mode: inventory windows, belt, watch, dashboard, moodles, quick wheels, character info | Merge into one folded row under Safe mode | Seven switches that share one sentence ("the game's own X, the rest of ZeD-GUI kept"). One row "Give back to the game:" with seven check boxes says it once. |
| Safe mode: Lua console | Show in debug mode only | It does nothing outside debug. |
| Test language (stretched text) | Show in debug mode only | A developer's tool on the player's page. |

### Game settings mirrored in ZeD setup

Font size, tooltip font, moodle size, 24-hour clock, temperature display and video effects appear in ZeD setup with an "Also in ..." note and again on their own pages of the same Options window. One control in two places in one window. Judgement: drop the mirrors. The Find box reaches them.

### Already retired in beta 21

Belt, Devices, Watch, Dashboard, Survival guide, Identity card and Mods screen (each "Immersive or simple") and Action bar ("Detailed or simple") no longer show; Style replaced them. Nothing to do. The gallery pictures 00h and 60 still show the old rows.

Code: Settings.lua (each option is one addComboBox call, lines 147 to 734). ZeD_MainMenuOptionGroups.lua (G.ZED_GROUPS near line 174, G.SETUP_GAME at line 140, G.RETIRED, G.LITE_HIDES).

---

## Words

### Two names for one thing

| Thing | Names in use | Suggest |
|---|---|---|
| An item's kind | "Cat" (list head), "Kind" (item card, reader), "Type" (vehicle card, sort menu), "Category" (crafting) | "Kind" on cards, "Cat" may stay as the short head |
| Condition | "Status" (list head), "Cond" (vehicle and equip heads), "Condition" (cards) | "Cond" for heads, "Condition" on cards; "Status" only where it also holds freshness |
| The theme | "Base theme" (setup), "Theme" (first launch, window menu) | "Theme" |
| The accent | "Accent color" (setup), "Accent" (window menu), "Same as Accent color" (menu item) | "Accent", and "Default" for the menu item |
| Input device | "Input mode lock" (setup), "Playing with" (first launch) | "Playing with" |
| The category pop-up | "Category: All" (Crafting, Building), "All categories" (Foraging) | one of them |
| Building's list | "All Recipes" over "Search structures..." | "All structures" |
| The Journal's first tab | "Journal" (tab), "the log" (on the same screen) | "Log" |
| The henhouse | "Hutches", "Henhouse", "Coop Roosting" | "Henhouse" |
| The flashlight | "Light" (chord row), "Flashlight" (picker) | check they are one action, then one word |
| Show and hide | "Toggle Survival Guide", "Show/Hide World Map" (same list) | one verb |
| Hunger on an apple | "Hunger reduction" (card), "Hunger" (balloon) | "Hunger" |
| Search | "Find:" (options, mods, saves), "Search..." (crafting), "Find a skill" | "Find" |

UI.json also holds the phrase "%1 of %2" under 23 different keys and "%1 items" under three. That is not visible to the player, but it is why wording drifts: each surface owns its own copy.

### Lines that can lose half their words

| Where | Now | Suggest |
|---|---|---|
| Guide bubble (22) | "New to Knox County? Check out this handy survival guide. Stop alt-tabbing for information: click this bubble or press F1 instead. You can dismiss this bubble at any time." | "New to Knox County? The survival guide: click here or press F1." |
| Keyboard map legend (p_kbmap_11) | "Lit: a key the game uses. In your warning color: one key, two jobs. Pick a key to see its jobs." | "Lit: in use. Warning color: two jobs. Pick a key to see them." |
| Keyboard map, while listening (p_kbmap_11) | The button says "Press a key" and the foot says "Interact: press the new key, or Escape to leave it as it was" | Foot: "Escape keeps the old key." |
| Server foot (62) | "Your faction and your safehouse, each a card. Pick one to see everything and change what's yours." | "Pick a card to see or change it." |
| Chat (62) | "Type here; /all for everyone, /w name for one player" over "Pick a line for what you can do about its sender." | "Type here" and no second line; the General and Private tabs do what the slash codes do |
| Uploader (63) | "Seen by everyone." under a lit "Public"; "What changed, for the item's change notes page."; "512 x 512: a size the game takes. It must stay under 1000 KB." | Show the first only for Unlisted and Hidden; drop the second; "512 x 512, OK" |
| Cooking (26) | "Press an ingredient on the left to add it." over "Cook it afterwards on a stove or a fire." | one line at a time |
| Wheel foot (53) | "(R) Point  (R) Let go: take  (B) Close" | "(R) Point, let go to take  (B) Close" |
| Window foot on a controller (53, 58) | "(A) Card  (A) Smoke (hold)" and seven hints in a row | "(A) Card, hold: Smoke"; mark hints only while something is marked |
| Quick action picker (54) | "Zoom: opens its wheel", "Zoom > Zoom 75%", "View > OPTIONS" | "Zoom ...", "Zoom > 75%", "View > Options" |
| Survival guide search (61) | every hit under its own heading with "(1)" | a flat list, the chapter as a dim word at the right |
| Style help (p_lite_07_setup) | 41 words | "Full: everything drawn ZeD's way, with its extras. Lite: plain buttons and faces, close to the game." |

---

## Clean, leave alone

The belt and the hand slots (p_lite_01_world, 14). The context strip (12, 35). The moodle note (17). The watch faces (19) and radio faces (28). The car dashboards and the car radio (43, 44, p_lite_05_dash). The controller map (52) and the controller highlight (55). The window menu (20, 57). The Survival Guide book and its rules table (61). The laundry machines apart from their caption (46). The item balloon (10, top row). The folder color menu (p_folders_26b_color_menu).

---

## If only one evening is spent on this

Findings 1, 2, 3, 6, 7, 8 and 10 are each a deletion in one or two files and are on screen in the first minute of play. Together they take about 20 repeated words and numbers off the two inventory windows, the clock, the Mods screen, the options page and every question. Findings 4 and 5 are the next step for Lite in particular, since the plain cards are where Lite is noisier than Full.
