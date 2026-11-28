# Options and the welcome: map for the gamut sweep (QA, Nov 27 2026)

A read-only map of ZeD's Options window (the desk's Options at the main menu and its copy over the dimmed world from the pause window), its two sub-pages (Button map and test, Advanced game sounds) and the first-launch welcome, against the game's own Options screen (MainOptions with its eight pages, its dialogs, ISSetKeybindDialog, ISGameSounds, the controller page) and PZAPI.ModOptions, written before the sweep scripts. ZeD's keyboard map and the Mods screen's info pane are mapped only where they touch the same settings. Line refs are as read on Nov 27. Nothing was run.

**The window is a reader of the game's screen.** MainOptions stays the engine: its pages and controls are built (hidden) as always, ZeD reads them every two seconds (or when a page's mark changes), draws each row with ZeD parts and changes a value on the game's control as a click would (MO:9-24, 341-357, 607-618). Apply is the game's MainOptions:apply (MO:771-780); the game's two dialogs (keep screen settings, restart to apply) and its close come to the window as band states (MO:2256-2296). Safe mode hands the whole thing back to the game (OMM:122-165).

Short names: MO ZeD_MainMenuOptions.lua, SUB ZeD_MainMenuOptionsSub.lua, OG ZeD_MainMenuOptionGroups.lua, WL ZeD_MainMenuWelcome.lua, ST Settings.lua, KM ZeD_KeyboardMap.lua, MS ZeD_ModSettings.lua, ZMM ZeD_MainMenu.lua, OMM Overrides/MainMenu.lua, SM SafeMode.lua, DW ZeD_DpadWheels.lua, ZUI shared/Translate/EN/UI.json (ZeD's words). All ZeD files under 42/media/lua/client/ZeD/ unless noted.
The game's files (media/lua/client): VMO OptionScreens/MainOptions.lua, GO OptionScreens/GameOption.lua, IGS OptionScreens/ISGameSounds.lua, VMS OptionScreens/MainScreen.lua, SKD ISUI/ISSetKeybindDialog.lua, PMO PZAPI/ModOptions.lua, GCT ISUI/Gamepad/GameOptionControllerTab.lua, VMV ISUI/ISMegaVolumeControl.lua.

Stage marks used in section 3: **[S]** can be staged by a Lua script at the main menu, **[G]** only in game (a QA save), **[H]** by hand or not at all. Every staged change must be put back (Discard where it can, else the old value set and Apply again), and the files Apply writes backed up first: Zomboid/options.ini, Zomboid/Lua/keysB42.ini, Zomboid/Lua/ModOptions.ini, Zomboid/Lua/ZeD_custom_additions.txt; for the welcome Zomboid/Lua/ZeD_setup_seen.txt, ZeD_tutorial.txt, ZeD_setup.txt. **No test touches Display mode, Fullscreen, Borderless, Resolution or VSync**, and none applies Pause on focus loss or Map view pause at the main menu (they raise the screen-settings question, whose No path calls setResolutionAndFullScreen and a Lua reset: VMO:613-625, 2474-2486, 3379-3401). Apply of a "reset Lua" option at the main menu (Language, Font size, Good and Bad highlight colors, Colorblind patterns, Dyslexic font, Lightning) resets Lua and ends the script (VMO:3778-3781): those are [H].

## 1. What it does

**Getting there:**
- At the main menu: Options in the desk's Settings menu (ZMM:1121) and the game's own OPTIONS item, routed to ZeD's (MO:2300-2317). Refused while the desk fades in (m.delay > 0, MO:2243, 2310). It is the "options" view on the desk's monitor (MO:952, ZMM:2876-2906).
- In game: the pause window's Options, centered, 1000 by 700 design units capped to the screen less 40 (MO:55, 951-961); MM.pauseView "options" (MO:2245-2248). The D-pad ZeD wheel's setup slice opens the pause screen and then Options on ZeD setup (DW:1818-1826).
- The game asking its screen to show (setVisible true: a Lua reset after Apply, the Advanced sounds screen coming back) opens ZeD's instead (MO:2287-2295); "optionsChangedApplied" after a reset reopens it through the OPTIONS item (VMS:1925-1928).
- Every open runs the game's toUI (Core to controls, live values stored), reconciles the additions' preset, clears Find, the question and the scroll, then takes the snapshot the changed dots compare with (MO:677-690). The page picked is kept between opens; only the D-pad slice resets it to 1.
- Safe mode: the desk, the pause window's Options and the hooks on MainOptions are handed back; the game's own screen shows (OMM:122-165, 182-191, 195-201). Safe mode is read from the stored value (SM:88-93), so it takes effect after Apply, within half a second (SM:126-139).

**The window:**
- Title "Project Zomboid  +  Options" (ZUI:2198); "Changed" in the title stats and the footer status while the game's changed flag is set (MO:975, 1001-1004).
- Left column (PAGES_W 210): "Find:" and its field (MO:1015-1034), then the pages in their own scroll box, 30 units a row, wheel and bar, the picked page kept in view (MO:1038-1074).
- Right: the rows (name column 44 percent, the control after it), one scroll (MO:1566-1717); the help band at the foot, three lines of the body font, at least 54 units (MO:1573, 1722-1761); the band of buttons under it (MO:2017-2085).
- The pages (OG:57-110), each re-filed from the game's pages by option name (OG:661-746):
  - **ZeD setup** (built by OG:495-659; table below).
  - **Display**, Screen: displayMode, fullscreen, borderless, resolution, framerate, vsync, focusloss, lockCursorToWindow.
  - **Graphics**: Textures (texcompress, maxTextureSize, maxVehicleTextureSize, simpleClothingTex, simpleWeaponTex, highResPlacedItems, perf_3Ditems); World (lightingFPS, fogQuality, waterQuality, perf_puddles, puddlesQuality, precipOption, precipitationSpeedMultiplier, perf_reflections, perf_skybox, bloodDecals, corpseShadows); Effects (screenFilter, doVideoEffects, doWindSpriteEffects, doDoorSpriteEffects, viewConeOpacity, searchModeOverlayEffect, usePhysicsHitReaction, maxActiveRagdolls, zombieUpdateOpt).
  - **Audio**: Volume (soundVolume, musicVolume, jumpscareVolume, vehicleEngineVolume); Music (musicLibrary, the Advanced or debug Reload button, musicActionStyle); Voice chat (voiceEnable, voiceRecordDevice, voiceMode, voiceVADMode, voiceAGCMode, voiceVolumeMic, voiceVolumePlayers; the two Mega controls run 0 to 11, MO:359, VMV:110-117); Streaming (streamerMode).
  - **Controls**: Movement (toggleToRun, dblTapRunToSprint, toggleToSprint, toggleToAim, autoProneAtk: the key page's toggles); Menus (radialMenuKeyToggle, reloadRadialInstant, enableLeftJoystickRadialMenu, singleContextMenu); Mouse (ignoreMouseWheelAcceleration, mapHorizontalMouseWheelToVertical); Controller (the game's whole controller page: the preset, button style, controllers in use, the dead zone stepper, one "Button map and test" row, MO:125-161, 221, 232-240); Key bindings (the game's groups, each bind a key button, MO:261-308).
  - **Gameplay**: Camera (zoom, zoomLevels, autoZoom, panCameraWhileAiming, panCameraWhileDriving); Aiming (reticleMode and the eleven reticle and crosshair rows, targetColor, noTargetColor); Cursor (iso_cursor, showCursorWhileAiming, meleeOutline); On its own (autoDrink, keyInIgnition, autoWalkContainer, timedActionGameSpeedReset, mapViewPause, dropItemsOnSquareCenter, autoRevealPrintMediaMapLocations); Multiplayer (showUsername, mpTextColor, populateServerListOnStart).
  - **Interface**: Text (fontSize, tooltipFont); HUD (moodleSize, sidebarSize, actionProgressBarSize); Clock (clock24hour, temperatureDisplay); Highlights (doContainerOutline, objHighColor, worldItemHighlightColor); Help (showItemModInfo, showSurvivalGuide); Rendering (UIFBO, UIRenderFPS); Language (language, comlang).
  - **Accessibility**: Colors (goodHighColor, badHighColor, colorblindPatterns); Reading (enableDyslexicFont); Weather (disableLightningDuringStorms).
  - **Mods**: the game's Mods page whole (every mod's PZAPI.ModOptions, ZeD-GUI's own drop-downs among them), then each page a mod added with MainOptions:addPage under its title (OG:109, 680-690).
  - An option no table names lands in its old page's group under "Other" (OG:112-114, 724-743). As of Nov 27 every game option name is filed (the three controller-page names come with from = "controller").
- Each game control drawn as ZeD's: drop-down box with a pop-up list (open with the pick in view, MO:1387-1395, 1768-1784); tick boxes, wrapping (MO:1396-1413); volume bar with its number, drag (MO:1414-1427); slider with thumb and value, drag (MO:1428-1449); color swatch opening an 84-color palette, 14 by 6 (MO:61-69, 1450-1457, 1818-1914); key button (MO:1458-1466); button (MO:1467-1474); text field edited in the band (MO:1475-1482, 893-912); dead zone stepper (MO:1483-1507); "Open controller setup" (MO:1508-1515). A label too long for its column takes two lines (MO:493-504).

**ZeD setup (ZeD's own options; each still a combo saved by item number, ST:23-28):**

| Group | Row (option id) | Control | Items | Default | Takes effect |
| --- | --- | --- | --- | --- | --- |
| Look | Style (lookStyle) | radio | Full, Lite | Full (Defaults leaves it, OG:516) | Look at Apply (ST:649-652); the additions' controls at once (ST:1044-1065) |
| Look | Theme (baseTheme) | radio | Dark, Light, High contrast | Dark | Live (ST:1254-1264) |
| Look | Accent color (accentColor) | 9 wells | red to mono (ST:34-36) | ZeD.DEFAULT_ACCENT (teal) | Live |
| Look | Status colors (statusColors) | radio | Standard, Color blind | Standard | Live (ST:1267) |
| Look | Text size (textSize) | radio | Small, Large | Large under 1080 tall, else Small, fixed at file load (ST:163-172) | Live |
| Look | See-through (seeThrough) | stepped slider | 100, 90, 80, 70, 60 | 90 | Live; dimmed outside Dark (MO:396-399) |
| Look | UI scale (uiScale) | stepped slider | Auto, 0.5x (retired), 0.75x to 2x | Auto | Live (ST:193-205); steps too big dimmed (ST:210-230) |
| Additions | Preset (additionsPreset) | radio | Vanilla, Plus, Access, Custom | Vanilla | Sets the additions live (ST:1001-1018) |
| Additions | Ammo on the belt, Dashboard lamps, Moodle notices, Overhead notes (haloBubble), Put things back, Sandbox options in game (under "A line in the pause window"), Additional appliance support, Attach looted tools and weapons | checkbox | Off, On | Off | At Apply (read by getValue) |
| Additions | Read marks (merged: readMarks, readNext, dimRead) | radio | Off, Marks, Marks and dim | Off | At Apply |
| Additions | Other mods' notes (merged: messagesCatch, messagesToast) | radio | As the game, In Messages, In Messages with a toast | As the game | At Apply |
| Additions | Hint strip (hintStrip) | radio | Always, First hours, Off | Always (not in the presets) | At Apply |
| Additions | Hidden facts (merged: hiddenFacts, autoLearn) | radio | Find first, Always | Find first | At Apply |
| Windows | Context menu (contextStyle) | radio | Strip, List | List | At Apply |
| Windows | Menu guess (menuGuess) | checkbox | Off, On | On | At Apply |
| Windows | Worn in list (wornInList) | radio | Top of the list, Equipment tab only | Top | At Apply |
| Windows | UI sounds (uiSounds) | radio | Full, Quiet, Off | Full | Live (ST:789) |
| Windows | Hidden actions (hiddenActions) | radio | Folded, All, Hide | Folded | Live read (ST:566-569) |
| HUD | Moodles (moodlePlace) | radio | Right, Left, Above the belt | Right | At Apply |
| HUD | Watch (watchPlace), Full only | radio | Belt, Corner | Belt | At Apply |
| Controls | Controller highlight (focusStyle) | pop-up with a live sample | Hand, Corners, Wash, Ants | Hand | Live (ST:527-530, MO:1395) |
| Controls | Button pictures (merged: glyphDisplay) | radio | Auto (1), Letters (6) | Auto | Live (ST:340-343) |
| Controls | Wheels (merged: wheelOpen, wheelCommit, wheelToggle) | pop-up | Hold and flick, Tap and flick, Tap and click, Toggle | Tap and flick | Live (ST:552-555) |
| Controls | Wheel dead zone (wheelDeadZone) | stepped slider | 0.20 to 0.60 by 0.05 | 0.35 | Live |
| Controls | Run button also sneaks (runSneak) | checkbox | Off, On | Off | Live (ST:777) |
| Quick actions (controller) | twelve chord rows (ZeD_QuickChords) | pop-up of the wheels' actions | None, then each wheel's actions | the chord's start | At once, no Apply (MO:1789-1815, 2009) |
| Troubleshooting | Safe mode (safeMode), under "The game's own interface" | checkbox | Off, On | Off | At Apply, within 0.5 s |
| Troubleshooting | Give back to the game (merged ticks: screenWindows, screenBelt, screenWatch, screenDashboard, screenMoodles, screenWheels, screenCharInfo, screenErrorBox) | 8 tick boxes | ticked is the game's own | all unticked | At Apply (SM:103-120) |
| Troubleshooting | Playing with (inputModeLock) | radio | Auto, Mouse and keys, Controller | Auto | Live (ST:1338-1353) |
| Troubleshooting | Lua console (screenConsole), debug only | checkbox | Off, On | Off | At Apply |
| Troubleshooting | Test language (testLanguage), debug only | checkbox | Off, On | Off | Tr.lua's half-second read |

- Kept and saved but with no row (OG:223-225): mapLight, solidInUse (always solid now, ST:492), healthBlink (always solid red, ST:503), gridTint (follows Style, ST:513-516), inventoryView, equipView, charAccent, worldAccent and the merged rows' own options. Retired and never shown on ZeD setup (OG:162): beltStyle, devicesStyle, watchStyle, dashStyle, guideStyle, identityStyle, modsStyle, actionBar. A new ZeD option no table names lands under "Other" as a drop-down (OG:643-648). An add-on's group or rows join through ZeD.Options.addGroup and addRows (OG:356-382, 444-488, 531-549): ZeD-GUI: Loadouts puts Loadouts and outfits and Restock after Hidden facts.
- A ZeD control too wide for its room (Large text, a long language, the test language) is drawn as the drop-down instead (MO:1147-1169, 1355).
- The first-run note (UI_ZeD_Options_FirstRunNote, MO:654-658) only shows when win.firstRun is set, which only the old first-run path set (OG:796-803); with the welcome in place it never shows.

**Live preview against Apply:** a pick on any control is held on the control until Apply (the game keeps it there); ZeD's theme, scale, accents, input lock and the options read through liveIdx show at once (ST:469-472, 1220-1268). Apply (MO:771-780) runs the game's apply: saveKeys (every bind to keysB42.ini, VMO:3701-3710), each option's apply, each mod's options:apply() (ZeD's sets the preset and writes ZeD_custom_additions.txt when Custom, ST:1068-1074), getCore():saveOptions() (options.ini), PZAPI.ModOptions:save() (ModOptions.ini), toUI, then the screen-settings or restart question (VMO:3741-3782). Apply keeps the window open; the snapshot is taken again. Return applies (not within 400 ms of Enter in a field, MO:2207-2213); Y on a pad (MO:2159).

**The band's states (MO:2017-2085):**
- Normal: Back, Reset to defaults (ZeD setup only, while Find is empty; grey when every ZeD option is at its start, MO:2078-2080, 1992-2000), Discard changes and Apply (grey with nothing changed).
- Back with changes: "Discard n changes?" with Keep editing, Discard changes, Apply (pad lands on Apply, MO:932); Apply there applies and closes. Footer Discard: the same question with two answers, landing on Keep editing.
- Screen settings: "Keep these screen settings? Going back in n seconds." Cancel, Keep; 20 s, counted in update() too so a hidden window still reverts (MO:2035-2041, 2089-2093); Back, B, Escape and leaving answer No (MO:715-717, 727-731, 2144-2152, 2198-2205); the D-pad stays on the answers (MO:2118-2130).
- Restart: the game's "restart to apply" with OK (MO:2042-2044).
- Key: "Press a key or mouse button for <action>." with No key, Default, Cancel (MO:2045-2051).
- Duplicate: "<key> is already <other action>." with Cancel, Keep both (the game's "Keep"), Take it (MO:2052-2060).
- Text: "Value:" with the field, Cancel, Set (MO:2061-2072).

**Discard (MO:738-769):** the game's restoreOriginalValues, the changed flag cleared, loadKeys, every game bind in keyText put back from MainOptions.keys, toUI; then ST's wrap re-applies the stored scale, theme, window accents and input lock and forgets the held Custom set (ST:1434-1460). The footer's Discard stays in the window; Back's closes it.

**Reset to defaults (MO:2001-2014):** every ZeD setup row not on its start item set back as a click would (pending until Apply), Style left alone; the merged tick row's eight give-backs unticked; every chord reset at once; the options with no row (hidden, Lite-hidden, debug-only) put back too; Lite's kept picks forgotten.

**Find (MO:972, 985-992; OG:752-769):** lower case, plain substring of the row's name, ZeD's name key and its help text, across every group, each group's hits under its title. ZeD's own options are found only on ZeD setup (their Mods page drop-downs left out). A page click or a bumper clears it (MO:1065, 2169). "No option matches" (MO:1718-1720). The pad reaches the field through its stop, A opens the pad keyboard (MO:1034).

**The help band (MO:414-464, 1722-1761):** the row under the pointer, the pad's row or the row being edited. Game rows: the game's tooltip (a combo's per-choice tooltip where it has one). ZeD rows: UI_ZeD_Settings_<name>Tip, merged rows their own tips (ZUI:2201-2219); an add-on row its tip key or its option's tooltip. Key rows: "Click the key, then press the new one (or a mouse button)." (ZUI:2146). The dead zone: ZUI:2145. Button map row: ZUI:1361. A chord: its two buttons and the action's path. ONLY rows append their note (Dyslexic font "Replaces ZeD's text fonts", Sidebar size "Multiplayer only", Tooltip font "Item and ZeD tooltips", ZUI:2167-2172). UI scale appends "Too big for this screen: X and up." (ZUI:2619). A changed row with no help: "Changed: Apply to keep it." ZeD rows show "Default: X" in a 240-unit column at the right, wrapped (MO:1730-1752). At most three lines; the rest is not drawn (MO:1757).

**Settings that do nothing with ZeD active (OG:116-128):** Inventory font, Context menu font, Container size (inventoryContainerSize), Clock size, Clock format, Show crafting XP, Shoulder buttons (shoulderButtonContainerSwitch) and Cycle container key. Since the visual noise audit (Nov 20) they are **not grayed but hidden**: marked used before any section is filled, so no group, no Other and no Find hit shows them (OG:672-675); the gray "Does nothing with ZeD active" drawing (MO:447, 468, 1632-1707; ZUI:2153-2164) is now reached by nothing. No ZeD Lua calls getOption on any of the eight (grep, Nov 27), so with every screen ZeD's they truly do nothing. They matter again for a screen given back: the game's inventory (fonts, container size, cycle key, shoulder buttons) with Inventory windows ticked, the game's clock (size, format) with Watch ticked; all of them in safe mode, where the game's own screen shows them.

**Key binding (MO:506-544, 806-890):** a click or A on a key button starts the catcher: an always-on-top element that takes every key and the extra mouse events, with the game's Lua key presses off (MO:815). A key release binds: one modifier (Shift over Ctrl over Alt), a modifier alone is the key (MO:528-538); a mouse button anywhere off the band's buttons binds that button (MO:540-544). The same key with the same modifiers on another action asks Cancel, Keep both or Take it (Take it clears every other, MO:862-870). No key binds 0; Default takes the game's keyBinding key (a mod bind its defaultKeyCode) through the same duplicate check (MO:879-890). Cancel or B stops. Each change sets the game's changed flag and runs its onKeybindChanged (the toggles' words follow Run, Aim and Sprint, VMO:3829-3849). Mod binds (PZAPI keybind options) show on the Mods page as key rows, not under Key bindings (MO:165, 303).

**Files written under %USERPROFILE%\Zomboid:**
- options.ini: getCore():saveOptions() at Apply and on the screen-settings No (VMO:3756, 3393).
- Lua/keysB42.ini: every bind at Apply (VMO:3701-3710); KM writes it at once from the keyboard map (KM:244-285).
- Lua/ModOptions.ini: at Apply (VMO:3757; PMO:259-290); ZeD also saves it from the window box menu and wheels (ST:86-90), on a preset reconcile (ST:1116-1124), on the welcome's Done, Skip or Load (WL:149) and on loadSetup (ST:1572); the Mods screen's info pane saves per change (MS:139-147).
- Lua/ZeD_custom_additions.txt: the Custom set at Apply or reconcile (ST:880, 944-957).
- Lua/ZeD_setup_seen.txt: "1" on the welcome's Done, Skip or Load (WL:146); its presence stops the first-run welcome (OG:791-792).
- Lua/ZeD_tutorial.txt: "1", "pad" or "0" (WL:147, 162).
- Lua/ZeD_setup.txt: Save setup (ST:1522-1535).
- Lua/ZeD_presetRepair.txt and Lua/ZeD_style_carry.txt: one-time marks (ST:627-646, 1079-1094).
- sounds.ini: the Advanced sounds page's volumes (GameSounds.saveINI, SUB:198, 806-809).
- The pad presets (gamepadBinding:saveAll at Apply, GCT:326-331).

**Pad path (MO:2113-2234):** D-pad up and down walk the rows (the view follows), left and right change a value in place (a combo steps, off UI scale steps skipped, stops at the ends; volume and slider a step; a tick row walks its ticks; the stepper steps; MO:1949-1973); A does the row's main job (a ZeD control's next choice, wrapping; a drop-down or palette opens; a tick flips; a key starts binding; MO:1920-1945); X clears a chord, else asks Discard; Y applies; LB and RB walk the pages, wrapping, clearing Find; B goes back (answers a question No first). Dimmed rows are no stops. The palette is a grid for the D-pad, starting on the color in use (MO:1818-1847). Footer prompts per row (MO:2173-2196).

**Lite:** Additions and Quick actions groups hidden (OG:163), the Additions group kept while the stored additions are off Vanilla (OG:568-579, ST:938-940); the Watch row hidden (OG:203, 597); a Style pick of Lite sets the additions' controls to Vanilla, Full again puts back what Lite took if they still read Vanilla (ST:1044-1065); Defaults leaves Style.

**Safe mode:** On at Apply: within half a second the desk and ZeD's Options vanish and the game's main menu and Options return (OMM:122-165); Off again from the game's Mods page, ZeD's desk comes back (OMM:166-177). The welcome's first run needs ZeD's desk (OG:785), so it waits.

**Small screens and Large text:** at the menu the window sits on the desk's monitor (UI.placeOnTube, MO:952); in game 1000 by 700 capped to the screen less 40. The page list scrolls in its own box; two-line row names; ZeD's radios fall back to drop-downs; the UI scale track loses step names where they would touch (MO:1265-1286); the help band grows to three lines of Large text; the button map's labels cut each game line to 2, then 1 (SUB:579-586).

**Button map and test (SUB:1-38, 222-745):** opened by "Open controller setup" on Controls (MO:1508-1515, SUB:208). The test's controller pick (the game's combo) at the top; while testing, "hold A and Y to exit" and the pad is the test's (SUB:645-676); the pad figure in the set the glyph option picks, thirteen labels with leaders: ZeD's job for the part, under it the game's actions on it; held buttons and pulled triggers light (SUB:262-276, 571-637). A label opens its element's actions with the bound ones ticked (a stick or the D-pad first asks which element); a pick adds or removes the action and runs the game editor's hand-off (SUB:146-154, 702-745). Band: Back, Apply (SUB:238-242).

**Advanced game sounds (SUB:750-899, 1003-1013):** only while the game offers its Advanced button (SystemDisabler.getEnableAdvancedSoundOptions, VMO:2125-2130). Categories down the left (click or LB, RB), each sound with a 0 to 200 percent slider in steps of 5 and Play or Stop (stops the menu music at the menu). Volumes saved at most once a second while changing and on leaving (SUB:806-809, 196-199). Band: Back only.

**The welcome (WL):** opened by itself once (OG:777-811: OnMainMenuEnter, after 120 FE ticks, not on a QA autoload, only on the desk's main view, only without ZeD_setup_seen.txt), and from the desk's Settings menu "ZeD setup: pick, save or load" (ZMM:1124, ZUI:4977). "Welcome to ZeD-GUI", "How do you want it? You can change any of this later in ZeD setup." (ZUI:4941-4942).
- Three cards: Pick your own ("With a live preview"), Load a setup ("From a file you saved before"), Skip ("ZeD as it comes") (WL:235-255).
- Pick your own's rows, dimmed for the other two ways (WL:63-72, 257-325): Style (Full, Lite, with the Style tip under it), Theme (Dark, Light, High contrast), Text size (Small, Large), Playing with (Mouse and keys, Controller; starts on the device in use), Moodles (Right, Left, Above the belt), Tutorial (Show me around, No thanks), Accent (nine swatches). Each pick sets the stored option at once and puts the theme on screen (WL:90-111); Lite also sets the additions to Vanilla.
- The preview: a small Inventory window (Apple, Hunting Knife, Lighter, Drop, Eat) in the picked theme and accent (WL:327-353).
- Band: Save setup (Pick your own only) and Accept, or Load (grey with no file) or Skip; the line "Nothing here starts a game." (else "No setup to load: put ZeD_setup.txt in Zomboid/Lua first." or the save note) (WL:356-373).
- Done keeps the picks (tutorial file "1", or "pad" with Controller); Load reads the file then closes; Skip, Escape and B put back every option as it was when the window opened; the close box keeps the picks with Pick your own, else skips; Return accepts, Y accepts (WL:145-186, 381-393).

## 2. What the game does for the same jobs

| Job | Game (MainOptions) | ZeD Options |
| --- | --- | --- |
| Find a setting | Eight tabs; no search | Nine groups re-filed by kind; Find across all of them |
| Know what a setting does | Tooltip on hover | Help band (pointer or pad), ZeD rows with their default |
| See what changed | Nothing until Back asks | Dot on each changed row, Changed in the title |
| Apply and stay | Apply (SAVE) | Apply |
| Apply and leave | Accept; Return (VMO:4089-4098) | Back, then Apply in its question; Return applies and stays |
| Leave with changes | Modal "Apply changes?" Yes or No (VMO:3319-3355) | Band: Keep editing, Discard changes, Apply |
| Throw changes away and stay | None | Discard changes in the footer, or X |
| Discard keys | No keeps edited keys for the next Apply | Game binds put back from the file (mod binds not, OP49) |
| Keep screen settings | Modal, 20 s (VMO:3357-3401) | Band, 20 s, revert on leave, B or Escape |
| Restart needed | Modal OK (VMO:3403-3427) | Band OK |
| Bind a key | Modal: press a key or mouse button; Clear, Default, Cancel; duplicate modal (SKD:9-120, VMO:3794-3827) | Band: the same choices; duplicate in the band with Keep both or Take it |
| Pick a color | ISColorPicker beside the button, live core call for highlights (VMO:3227-3239) | 84-swatch palette pop-up, held until Apply |
| Controller bindings | The controller page's editor and test panels | Button map and test: drawn pad, labels, pull-downs, the same edits |
| Per-sound volumes | ISGameSounds: tabs, sliders, play, Close; debug Reload (IGS:266-284) | Advanced game sounds: categories, sliders, Play or Stop; no Reload |
| Mod options | Mods tab, built from PZAPI.ModOptions | Mods group (the same rows); ZeD's and add-ons' own on ZeD setup |
| Defaults | None | Reset to defaults for ZeD's own only |
| First launch | Nothing | Welcome: pick, load or skip, preview, tutorial offer |
| Carry settings | Copy the ini files by hand | Save setup and Load a setup (ZeD's options only) |

ZeD has, the game doesn't: Find; changed dots; the help band with defaults; Discard that stays; ZeD setup's own controls (radios, wells, stepped sliders) with presets, merged rows and Defaults; the drawn button map with a live test; the welcome and setup files; screen-by-screen give-back.

The game has, ZeD loses or mislabels:
- The eight moot settings are unreachable in ZeD's window even where they still act (a screen given back), see OP7.
- Accept as one press; Return means Apply and leave in the game, Apply and stay in ZeD.
- The game's live highlight color preview (setObjectHighlitedColor, setWorldItemHighlightColor) and a mod color option's live onChange (VMO:3241-3249) are skipped by pickColor (MO:1865-1874).
- The Advanced sounds screen's debug Reload button (IGS:272-284).
- A mod key bind's own tooltip (replaced by ZeD's generic key help, MO:441).
- The Advanced or Reload sound button keeps no name in ZeD's row (OP5).
- Pause on focus loss and Map view pause raise "Keep these screen settings?" in both (the game's own flag, VMO:622, 2482); ZeD's band words say screen settings too.
- ZeD's sub-pages show no question: a screen-settings or restart answer raised from the Button map page is invisible until Back (OP44).

## 3. Gaps and risks (OP1 to OP80)

Kinds: **bug** (suspected, to prove), **design** (a call for the director), **check** (a plain check). Stage marks as in the intro.

**Ways in and pages**
- **OP1.** Each way in lands where it should: desk Options, the game's OPTIONS item, the pause window's Options, the D-pad setup slice (page 1); reopening keeps the last page (onShow keeps pageIdx). MO:677-690, 2241-2252, 2300-2317; DW:1818-1826. check [S, G for the slice]
- **OP2.** Options pressed while the desk fades in does nothing and gives no sound or note. MO:2243, 2310. check [H]
- **OP3.** The nine groups in order, titles in the player's language; a mod page added with MainOptions:addPage shows under Mods with its title. OG:57-110, 680-690. check [S]
- **OP4.** No game option lands under Other today; a new one would, in its old page's group. Read every group's rows against VMO's GameOption names (125 in VMO). OG:112-114, 724-743. check [S]
- **OP5.** The Advanced (or debug Reload) sound button under Audio > Music has an empty name: it is placed by __audioButton with label "" (the title naming runs only for Other rows) and Advanced has no tooltip, so the band is blank too. OG:72, 669, 730; VMO:2125-2138. bug, low [S]
- **OP6.** The eight moot settings are hidden, not grayed as the director's brief says; the gray drawing and its words are dead code. OG:672-675; MO:447, 468, 1632-1707. design [S]
- **OP7.** With Inventory windows or Watch given back, the game's inventory and clock use Inventory font, Context menu font, Container size, Cycle container key, Shoulder buttons, Clock size and Clock format again, but ZeD's Options still hides them. OG:119-128, 272-278; SM:103-139. bug or design [S to read rows; G to see the effect]
- **OP8.** The three ONLY rows show their line and help note; Tooltip font really sizes ZeD's tooltips (Overrides/Tooltip.lua) and Sidebar size is honored in multiplayer only. OG:132-136; MO:456, 480. check [S]
- **OP9.** The Mods group lists all of ZeD-GUI's options as plain drop-downs, the eight retired styles and the three no-ops (solidInUse, healthBlink, gridTint) included, with no mark that they do nothing. ST:492, 503, 513-516, 671-744; OG:109, 709. design [S]
- **OP10.** Group and section titles borrowed from the game's keys (IGUI_RadioVolume, Sandbox_WorldOptions, UI_btn_help, SurvivalGuide_weather_title and the rest) read sensibly as titles in EN, DE, FR, ES, RU, JP. OG:45-53, 59-108. check [S]

**ZeD setup**
- **OP11.** Every row against the table in section 1: control, item count, default in the band ("Default: X"), the live or Apply column. MO:1171-1315, 1730-1752; ST:144-805. check [S]
- **OP12.** Radios too wide fall back to drop-downs: Preset (4), Hint strip, Moodles, Playing with, in Large text and DE; and with the test language (debug). MO:1147-1169, 1355. check [S]
- **OP13.** UI scale: a click picks the nearest step, a dimmed step takes no pick and gives no sound or word; Auto's readout "Auto (1.5x here)"; a saved step above the cap reads "X (Y here)"; 0.5x dimmed. Put the scale back. MO:1116-1136, 1255-1303, 341-345; ST:210-230. check [S]
- **OP14.** UI scale on the pad: left and right skip off steps and stop at the ends; A wraps to Auto past the last step that fits. MO:330-339, 1928, 1954. check [S]
- **OP15.** See-through dims in Light and High contrast with its tip as the reason; in Dark the five steps change the windows at once. MO:396-399, 448; ST:477-483, 1236-1241. check [S]
- **OP16.** Accent wells: hover names the color, the pick is framed, the name beside the wells only when there is room. MO:1202-1253. check [S]
- **OP17.** Preset: a preset sets every addition live; a hand change reads Custom; Custom with no held set falls back to ZeD_custom_additions.txt; with neither it changes nothing and snaps back to the preset the values make. ST:943-1018. check [S]
- **OP18.** Merged rows set every option under them as clicks would (the changed flag set, each onChange run): Read marks, Other mods' notes, Hidden facts (autoLearn with it), Button pictures, Wheels, Give back. OG:234-279, 295-352. check [S]
- **OP19.** A merged row's option changed alone on the Mods page (readNext only, say) shows on ZeD setup as another choice of the trio; Find and the changed dot follow it. OG:239-242; MO:368-389. check [S]
- **OP20.** Button pictures: a player on a forced set (Xbox, PlayStation, Deck, Nintendo) reads Auto; a press of Auto rewrites 1 and drops the forced set; Keyboard/mouse (6) and Off (7) both read Letters. OG:255-259; ST:56-57. design [S]
- **OP21.** Give back: each tick waits for Apply; after it the screen goes to the game within half a second; the first screen a mod took is named under the row. OG:272-278; MO:473-478; SM:103-120. check [S to tick, G for the effect]
- **OP22.** Safe mode On then Apply at the menu: ZeD's window vanishes mid-use and the game's menu returns; turn it Off in the game's Mods page and ZeD's desk is back. OMM:122-177; SM:126-139. check [H]
- **OP23.** Lua console and Test language rows only with -debug; Defaults resets them outside debug too. OG:216-217, 597-600. check [S]
- **OP24.** Quick action chords at the main menu offer only None (actions need a player); a pick or X saves at once and is not counted as a change; Discard does not bring it back. MO:1789-1815, 2154-2156, 2009. design [S for None, G for picks]
- **OP25.** Controller highlight's sample beside the drop-down follows the pick before Apply. MO:1319-1330, 1395; ST:527-530. check [S]
- **OP26.** Lite: Additions and Quick actions groups and the Watch row hidden; the Additions group stays while the stored additions are off Vanilla. OG:163, 203, 568-579; ST:938-940. check [S]
- **OP27.** Style Lite then Full before Apply puts the additions back; Lite, Apply, then Full leaves them all Off (liteFrom cleared at Apply). ST:1044-1074. design [S]
- **OP28.** Reset to defaults: grey when nothing differs, hidden while Find has words, leaves Style, resets the hidden options, the Lite-hidden groups and the debug rows, resets chords at once and the rest on Apply; Text size goes to the screen-height default taken at file load. MO:1977-2014, 2078-2080; ST:163-172, 856-859. check [S]
- **OP29.** One press of Reset to defaults also turns Safe mode Off, Playing with to Auto and all eight give-backs back to ZeD's: a player who gave the belt back gets it again on the next Apply. MO:2006-2013; OG:213-215. design [S]
- **OP30.** Every ZeD row's help reads a real tip (all UI_ZeD_Settings_<name>Tip keys are in EN, Nov 27); Sandbox_Custom, a game key, through ZeD.tr. MO:429, 1139-1144; OG:186. check [S]
- **OP31.** The help band draws three lines and drops the rest with no mark: Safe mode's tip, Other mods' notes and Wheels run longer in Large text. MO:1573, 1753-1760; ZUI:2205, 2213, 2614. bug, low [S]

**The game's rows**
- **OP32.** Each control does what the game's would: combo onChange, tick changeOptionMethod, volume 0 to 10 (Mega 0 to 11), slider, text, button, with the game's flag set and its live preview (sound volume). MO:341-359, 1387-1482; VMV:110-117. check [S]
- **OP33.** Color rows: a stored color not on the 84 swatches shows no frame and the pad starts on swatch 1; picks skip the game's live highlight call and a mod color option's onChange. MO:61-69, 1818-1830, 1865-1874; VMO:3227-3249. bug, low [S]
- **OP34.** A tick row with several boxes (Controllers) wraps; the pad's left and right walk the boxes and A flips the one walked to. MO:1396-1413, 1934-1936, 1964-1966. check [H pad]
- **OP35.** Dead zone: "Choose a Test Controller below" until one is picked; the value read live; each step applies at once and Discard leaves it. MO:1483-1507; ZUI:2174. check [H pad]
- **OP36.** A mod's text option edits in the band: Enter sets, Escape cancels, the pad opens its keyboard on the field. MO:893-912, 586-590, 2061-2072. check [S with such a mod]
- **OP37.** The language list marks ZeD's machine-drafted languages "(machine translation, ZeD-GUI)" without changing the game's option text. MO:313-320. check [S to read; H to apply]
- **OP38.** Restart-needed options (texcompress, texture sizes, puddles, reflections, skybox, borderless): Apply shows the warning band with OK only. Stage with texcompress, then put it back and Apply again. MO:794-802, 2042-2044; GO:65-73. check [S]
- **OP39.** A reset-Lua option applied at the menu (Language, Font size, highlight colors, Colorblind patterns, Dyslexic, Lightning) brings Options back on ZeD setup, not the page used. VMO:3778-3781; VMS:1925-1928; MO:570. design [H]
- **OP40.** Pause on focus loss and Map view pause raise "Keep these screen settings?": Keep does nothing more, Cancel resets the display to the same values (and at the menu resets Lua) and the setting stays changed either way. VMO:613-625, 2474-2486, 3379-3401. design (the game's) [G with Keep only]
- **OP41.** The screen-settings band: 20 s count, B, Escape, Back and leaving answer No; the D-pad stays on the answers; A off an answer lands on Cancel. MO:715-717, 727-731, 1850-1863, 2035-2041, 2089-2093, 2118-2152. check [H]
- **OP42.** While "Keep these screen settings?" is up the mouse still works on the rows (MM.pointer has no question block): a click on a key button (setConfirm("key")) or Open controller setup (openSub, setConfirm(false)) drops the question unanswered, so the 20 s revert never runs and, at the menu, the game's Lua reset never comes. MO:806-808, 933-946, 2092; SUB:176-180; ZMM:208-223. bug [H]
- **OP43.** The same for every question: under Back's ask, Discard's, the restart OK, the duplicate and the text field, rows and pages stay live to the mouse; a change made under Back's ask is discarded or applied with no recount. MO:1566-1717, 2017-2085. bug, low [S with Back's ask]
- **OP44.** Apply on the Button map page with a restart (or screen) change pending from another page: the question is set but SUB's band draws only Back and Apply, so nothing shows until Back. Stage with texcompress, then put it back. SUB:222-252, 239-241; MO:794-797. bug, low [S]

**Changes, Apply, Discard**
- **OP45.** A change set back by hand clears its dot but leaves the game's flag, so Changed, Discard and Apply stay lit. MO:703-711, 975, 2075-2083. check [S]
- **OP46.** With the flag on and no row changed, Back asks "Discard 1 changes?" (AskDiscardMany with max(n, 1)). MO:2023-2024; ZUI:2120-2121. bug, low [S]
- **OP47.** Back with changes asks three answers landing on Apply; the footer's Discard asks two landing on Keep editing; X asks the footer's. MO:932, 2021-2034, 2154-2158. check [S]
- **OP48.** Discard puts back the live previews: theme, accent, text size, see-through, status colors, UI scale, window accents, input lock, the held Custom set. ST:1434-1460. check [S]
- **OP49.** A mod's key bind changed then discarded keeps the new key: Discard restores keyText only from MainOptions.keys (game binds), a mod bind has no GameOption for toUI; ModOptions:save takes element.keyCode at the next Apply. MO:744-753; VMO:2982-3017; PMO:276-279. bug [S with a mod that has addKeyBind; ZeD has none]
- **OP50.** Button map edits act on the pad's bindings at once; Discard and Back do not undo them (the game's editor the same). SUB:146-154; GCT:348-359. check [H pad]
- **OP51.** Apply keeps the window, clears the dots, writes the files listed in section 1; Return applies only with changes and not just after Enter in a field; Y on a pad. MO:771-780, 2159, 2207-2213; VMO:3741-3782. check [S with backups]

**Find**
- **OP52.** Find searches the help text too: "key" or "click" returns every key binding (their help says "Click the key"), "the" most rows. MO:987-990; ZUI:2146. design [S]
- **OP53.** Find shows each ZeD option once, on ZeD setup; section titles and current values are not searched; a word with an accent typed in DE or FR finds its row in mixed case (string.lower on non-ASCII). OG:752-769; MO:972. check [S]
- **OP54.** Frame time with one letter in Find: every group is read and help() is built for every row each frame. MO:963-998. check [S]
- **OP55.** A page click or a bumper clears Find; Reset to defaults is hidden while it has words; "No option matches". MO:1065, 1718-1720, 2078, 2169. check [S]

**Key binding**
- **OP56.** Bind: the band asks with the action's name; Shift, Ctrl or Alt held binds one modifier (Shift wins); a modifier alone binds itself. Stage through win:startCapture(e) and win:gotKey(...), then Discard. MO:528-538, 834-849. check [S]
- **OP57.** Escape and Enter while the band asks are bound like any key (the catcher takes every key; the game's dialog the same); the only ways out are Cancel and B. MO:527-538. check [S]
- **OP58.** A click anywhere off the band's three buttons binds that mouse button, left click included. MO:540-544, 823-829, 1009. check [H]
- **OP59.** Duplicate: only the first other action is named; Take it clears every other; the pad lands on Take it, so one A clears another action's key. MO:862-870, 932, 944, 2052-2060. design [S]
- **OP60.** Default drops a default modifier (keyBinding's shift or ctrl) and can raise the duplicate question; a mod bind uses defaultKeyCode. MO:879-890; SKD:58-80. check [S]
- **OP61.** On the pad the key band's focus is set to confirm:yes, which that band does not have (No key, Default, Cancel): where does the hand land, and does A do anything? MO:932, 944, 2045-2051. bug, low [S]
- **OP62.** A key band left up turns the game's Lua key presses off; finish turns them back on, but in game the menu going down hides the Options window (afterPrerender) without finish. Unlike KM there is no tick safety. MO:806-821, 715-724; ZMM:2994-2995; KM:628-638. bug, suspected [G]
- **OP63.** Mod key binds sit on the Mods page as key rows with ZeD's generic help; modifiers set there show on the button but ModOptions saves the key only. MO:165, 214-216, 303, 441; PMO:182-205, 276-279. check [S with such a mod]
- **OP64.** A key set in the keyboard map (in game) shows at once in Options' key list with no changed dot, its modifiers cleared, with no duplicate question (only the clash color). KM:224-266, 119-160. check [G]

**Button map and test**
- **OP65.** Controls > Controller > "Open controller setup" opens it; Back, B and Escape return to the same scroll and row; the help band names the row's job. MO:1508-1515; SUB:176-205, 930-934, 976-981. check [S]
- **OP66.** Pick a test controller: the pad is the test's until A and Y are held (the footer says only that); mouse Back ends it too. SUB:645-676, 960-962, 195. check [H pad]
- **OP67.** A label's pull-down ticks the bound actions; the first edit on a built-in preset spawns a new preset and leaves the changed flag off, so Apply stays grey. SUB:146-154, 727-745; GCT:348-359. check [H pad]
- **OP68.** At 1280 by 720 and in Large text the labels fit by cutting game lines to 2, then 1; the pull-down still lists every action. SUB:579-586, 399-450. check [S]

**Advanced game sounds**
- **OP69.** The categories are drawn only while they fit the box (no scroll): past the bottom they cannot be seen or clicked, LB and RB still reach them. SUB:815-825, 936-945. bug, low [S where the game offers the button]
- **OP70.** Volumes 0 to 200 percent in fives, kept once a second and on leaving; Play stops the menu music; no debug Reload (the game's has it). SUB:777-809, 786-796; IGS:266-284. check [S]

**The welcome**
- **OP71.** It opens only without ZeD_setup_seen.txt, never on a QA autoload, on the main view after the desk settles; a seen file from before beta 21 (this machine has one) means an upgrader never sees it. Stage by calling MM.openWelcome(). OG:777-811. design [S]
- **OP72.** Picks set the stored options at once and the desk changes; Skip, Escape and B put the snapshot back, the close box keeps the picks: on a pad, B (the usual way back) throws every pick away and writes the seen file. WL:90-111, 165-186, 381, 389. design [S]
- **OP73.** Playing with sets nothing but the tutorial's words: no input lock, no button pictures. WL:69, 76, 91, 162. design [S]
- **OP74.** Reopened from the Settings menu, Tutorial starts on "Show me around" again, so Accept re-arms the tutorial (ZeD_tutorial.txt "1"). WL:122, 162; ZMM:1124. bug [S, restore the file]
- **OP75.** Load a setup takes every option in the file, Safe mode, Test language, the give-backs and UI scale included, but re-applies only the theme: UI scale, input lock, window accents and the additions' preset wait for the next menu or game start. ST:1545-1574, 1434-1444. bug [S with a staged file]
- **OP76.** An empty or all-invalid setup file loads 0 options, which counts as success: the window closes with nothing changed and no note. WL:156-159; ST:1548, 1573. bug, low [S]
- **OP77.** Save setup writes ZeD_setup.txt with every ZeD option, retired ones too, then says where; grey unless Pick your own. ST:1522-1535; WL:174-178, 370. check [S with a backup]
- **OP78.** Layout: the label column is a fixed 120 units and the choices are not kept out of the preview: "Playing with", Theme's three words and Large text, DE or the test language may run into the preview; the window is capped to the desk with no scroll. WL:205, 215-217, 259-289. check [S]
- **OP79.** Style Lite then Full in the welcome leaves the additions at Vanilla (no kept picks here); only Skip brings them back. WL:100-109, 165-172. design [S]

**Screens**
- **OP80.** At the screens QA already runs (1280 by 720 and 800, 4K at font 26 px), never changing the resolution: the page list scroll, two-line names, lines under names, three-line help, the 240-unit default column, the in-game window's cap, Large text. MO:951-961, 1015-1075, 493-504, 1573, 1735. check [S, G]

**Tests that touch it now:** none read here (this map read only the files listed); QA's rt_ and zedqa scripts that open Options (zedqa_scale.lua and zedqa_scalewalk.lua drive UI scale through ZeD.Settings.uiScaleOption, ST:206) are QA's to list. Not covered by anything seen: the questions under the mouse (OP42 to OP44), mod key binds on Discard, the welcome's reopen, Load a setup's partial apply, the sounds page's categories.
