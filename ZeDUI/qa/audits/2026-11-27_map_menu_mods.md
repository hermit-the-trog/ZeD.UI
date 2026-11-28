# Mod manager: map for the gamut sweep (QA, Nov 27 2026)

A read-only map of ZeD's mod manager main window (the main menu's Mods screen on the desk's monitor: its filter tabs and counts, the mod list, turning mods on and off, requirements and incompatibilities, the detail pane and its tabs, Find, Hide incompatible, Profiles, the Workshop state, the safety question for a save's mods, Back, Accept, Undo changes, Reload and the About mods nag) against the game's own ModSelector for the same jobs, written before the sweep scripts. Folders, separators, the Load order page and the Map order page are mapped by another agent and appear here only where this window hands off to them. Line refs are as read on Nov 27. Nothing was run.

**One window, four lists.** The game's ModSelector stays built and never shows: its setVisible(true) is redirected to the "mods" view (MN:2849, 2858-2871), so the main menu's Mods (MD:2568-2580), Load's Choose mods (SV:433-441), New game's Choose mods (SV:995-1003) and the server settings' mods (the game's ServerSettingsScreen.lua:3079) all land on ZeD_MMMods. Every rule is the game's: the window drives ModSelector.instance.model (MD:58), so the cascade, presets file, load order and acceptChanges are vanilla's. Which list is open is the model's flags: loadGameFolder (a save), isNewGame, isServerSettingsMods, else the player's own list "default" (MSM:226-234). The title says which (MD:1128-1133).

Short names (ZeD, media/lua/client/ZeD unless noted): MD ZeD_MainMenuMods.lua, PN ZeD_MainMenuModsPanes.lua, FT ZeD_MainMenuModsFiles.lua, PK ZeD_ModPicks.lua, RS ZeD_ModReset.lua, SF ZeD_ModSafety.lua, SC ZeD_ModScan.lua, ST ZeD_ModSettings.lua, FL ZeD_ModFiles.lua, MO ZeD_ModOrder.lua, FO ZeD_ModFolders.lua, OR ZeD_MainMenuModsOrder.lua, MN ZeD_MainMenu.lua, SV ZeD_MainMenuSaves.lua, PR Overrides/Prompts.lua, OMM Overrides/MainMenu.lua, SET Settings.lua, BME ModSupport/BetterModExperience.lua, ZUI shared/Translate/EN/UI.json (ZeD's words).
The game's files (media/lua/client/OptionScreens, ModSelector/ unless noted): MS ModSelector.lua, MSM ModSelectorModel.lua, MLP ModListPanel.lua, MLB ModListBox.lua, MPR ModListPresets.lua, MIP ModInfoPanel.lua, MIPP ModInfoPanelParam.lua, MIPI ModInfoPanelInteractionParam.lua, MIPT ModInfoPanelThumbnail.lua, HELP ISModsHelpPanel.lua, MISS MissedModsPanel.lua, NAG OptionScreens/ISModsNagPanel.lua, MMI OptionScreens/ModMoreInfo.lua, PML ISUI/ISPauseModListUI.lua.

## 1. What it does

**Getting there and leaving:**
- Main menu Mods (menu, desktop icon, File menu): MM.openMods clears the save, new game and server flags, shows the view, reloads the mods, asks for the nag, sets returnToUI (MD:2568-2580). Ignored while the main screen's delay runs (MD:2571).
- Load's Choose mods: setExistingSavefile copies the save's list into "currentGame" (SV:437, MSM:33-37). New game's: setNewGame (SV:999). Server settings: setServerSettingsMods fills "serversettings" (MSM:39-49).
- Each visit (onShow MD:133-170): page list, no question, Find empty, nothing picked, note gone; the tab and Hide incompatible come back from Zomboid/Lua/ZeD_modsview.txt once a Lua session (MD:71-89, 144-148); the info pane's settings, safety grades, picks texts and reset reads are dropped (ST:338-341, SF:140, PK:195, RS:346); ZeD picks' copies are rebuilt for the running list (MD:158-160); an Open in Mods jump is taken (MD:165-169, FL:399-410).
- Leaving: Back (MD:714-718), Accept or Reload (MD:597-639), the close box (MD:2537, runs back()), Escape (MD:2491-2500), B (MD:2421-2429). Accept on a save's list goes back to Load, on a new game's to New game, on a server's to its settings (MSM:249-277, MD:637).
- The nag: ModSelector.showNagPanel is replaced by a ZeD note with vanilla's title and words, once per run (core:isModsPopupDone), the main menu's controller held and returned (PR:203-233); vanilla's panel when the prompt can't be built, in debug with UI.DisableWelcomeMessage or before ZeD is ready (PR:208-211, 230-232).
- Safe mode: the desk never attaches at the main menu (OMM:188-191) and the hooks go back (OMM:157-179), so the game's own ModSelector runs.
- Steam downloads while the screen is up: OnModsModified reloads the model (MD:2593-2600).

**The layout (prerender MD:1117-1163):** the list on the left (48 percent, widened up to 62 percent so its tabs fit, MD:1146-1148), the detail pane on the right, the band at the foot (MD:1178-1278). Other pages share the window: profiles, picks (the file picker), order and maps (OR). The title is "Mods: <section>", the profile in use as a stat in the title bar (MD:1133-1138).

**The filter tabs (tabList MD:1300-1316, drawn MD:1323-1389):**
- All n and On n always; Off n, Starred n, Maps n, Problems n, Conflicts n, Workshop n only while they hold something or are open (MD:1311).
- Counts (counts MD:224-243, kept a second): All every installed mod; On isActive; Off all minus on; Starred favorite; Maps category "map"; Problems every mod problem() names (MD:356-408); Conflicts the mods with at least one shown conflict (SC:348-362, same-text and picked ones not counted); Workshop every subscribed item Steam reported (SC:370-416), collections and items not installed included.
- Tight room: padding then gaps shrink, then tabs not open drop their numbers, then the row slides so the open tab shows, clipped to the list (MD:1329-1389).
- Rows per tab (rows MD:176-213, kept 500 ms): On, Off, Starred, Maps, Problems, Conflicts by the same tests as the counts.

**Find and Hide incompatible (MD:1391-1404, 1475-1527; the field OR:584-614):**
- Find: name, mod ID and Workshop ID, lower case, plain text (MD:199-208); Clear when it holds text (OR:601-603); Ctrl+F (MD:2514); Return or B leaves the field (MD:123, 2423, 2509).
- Hide incompatible: a box at Find's right; ticked, a mod that is off and has a problem leaves the list (MD:194), "n hidden" beside it when room (MD:1481-1491); kept in ZeD_modsview.txt (MD:1400-1404).

**The mod row (drawModRow MD:1532-1616):**
- Full: a darker band when on (MD:1542-1545), a folder tint (folders' agent), the box (disabled look for an off mod that cannot run, MD:1555), the icon (mod's or category's, dim when off, MD:1575-1579), the name (dim when off), a second line with a red dot and the problem only when there is one (MD:1593-1603), tags at the right (rowChips MD:269-295: "n conflicts", "Picked", "Same text", "n files off", "n errors", ZeD picks' "n files", then Steam's Updated, Update, Downloading, Queued), the star when a favorite or under the pointer (MD:1608-1610).
- Lite (Simple): 30 units, the box, the name and a red dot when wrong; no icon, tags or star (MD:1559-1573).
- Mouse: a click picks, a second click within 450 ms turns it on or off (MD:1732-1743); the box turns it at once (MD:1613); the star stars it (MD:1614). Keys: Space turns the picked one (MD:2523), Up and Down step (MD:2524-2533).

**What can't run (problemRun MD:370-393, problemNow MD:395-408):** "Made for game x to y" (an open end "any") from isAvailableSelf and the version range; "Needs a, b" for requirements not installed (by id) or not available (by name); "Cannot run" otherwise; for an off mod an incompatible mod that is on gives "Conflicts with <names>". A mod that is on is never a problem by conflict.

**Turning mods on and off:**
- One mod (toggle MD:544-574): an off mod with a problem only plays the hover sound (MD:548); a save's list asks first for a mod that is not safe to turn off (MD:550, PN:987-1006); the template mod asks (MD:551, 1190-1194); then vanilla's forceActivateMods (requirements cascade on, dependants off, MSM:397-428); ZeD picks follows ZeD-GUI off and back (MD:427-465, 554-562); the note says which others came along (MD:567-573, ZUI:1716).
- Many (modsOnBatch MD:471-513, applyOnSet MD:519-532): every mod that can run goes on at once, then requirements; a player's own earlier set (exact: a profile, Undo, Discard) comes back exactly, two mods that conflict included; otherwise the first wins.
- Turn every mod on (More on Profiles, MD:1023, setAll MD:804-821): the template stays off (MD:482). No mods: every mod off (MD:830-834).
- Favorites: model:setFavorite (MD:576-582), saved only when the model writes pz_modlist_settings.cfg (MSM:344-365).

**The detail pane (drawDetail MD:1745-1871), one scroll:**
- A note band at the top for 6 s (MD:52, 585, 1753-1768).
- Poster 1 (MD:1792-1798), the name in the heading font (two lines), "by <author>", the verbs: Turn on or Turn off (greyed for an off mod that can't run), Favourite or Unfavourite, Move to folder... (Full, not the Workshop tab), Open in Steam (a Workshop ID), Homepage (a URL, opened at once) (MD:1846-1853).
- The tabs (PN:58-139): About, Options n, Sandbox n, Conflicts n, Files n; one with nothing greyed; Lite shows About only (PN:90).
- About (MD:1874-1993): the verdict line, "Pinned first/last" (MD:1899-1905), Version, Game, ModID, Workshop (state, updated, size), WorkshopID, Load order n of N (on only), Type, Replaces (the game's scripts it overrides, SC:522-534), the Steam "updated while it ran" note, If you turn it off (PN:951-984: the grade, each finding, the mods that go with it; not in a new game's or server's list), Needs and Cannot run with (dots: green on, red not installed or on when it can't run with it, dim off), the description as plain text.
- Options (PN:291-350): ZeD-GUI's own sends you to Options (PN:295-298); a mod off or not loaded says why and offers Turn on (PN:299-309); else the mod's PZAPI options as the Options window's rows, changed in place and kept on mouse up (PN:224-234, ST:139-147), a changed dot (PN:255-259), keys and typed values only shown (PN:265-276); then its settings files and Reset settings, Open in Options (greyed with changes waiting, PN:347). A help band at the pane's foot (PN:548-589). The colour palette (PN:156-221).
- Sandbox (PN:488-545): read from media/sandbox-options.txt with its labels (ST:247-316), where it is set (pages), each default; read only.
- Conflicts (MD:2029-2099, PN:598-645): each conflict ZeD_ModScan found (same Lua file: load order decides; same item, recipe, vehicle, building or model: file-name order decides, SC:9-21), who wins and why, Load after... (MD:700-712), Pick files... (PN:651-663), Fine, hide this (SC:125-130); same-text copies as a grey note; picked ones with Change picks and Undo picks; hidden count with Show again.
- Files (FT): each code file with a switch (another agent may cover it in depth; this map only notes where it meets the window).
- Workshop item without a mod (MD:2103-2150): its title, Open in Steam, state, updated, size, ID and why it brought no mod.

**Profiles (MD:720-1063, page MD:2153-2345):** the game's presets (pz_modlist_settings.cfg) plus ZeD's order, saved and last-loaded stamps, pins and rules in Zomboid/Lua/ZeD_modprofiles.txt (MO:48-95).
- Left: No mods, then each profile by name; a dot (accent in use, red missing or can't run), "n mods", "n mods, on now", "n missing" (MD:2170-2201).
- Right: name, counts, separators, saved, last loaded; Loading it: turns on, turns off, not installed, can't run; the load order it keeps or "sorted by the mods' rules" (MD:2209-2345).
- Band: Back, New..., Update... (greyed for No mods or the one in use), More (Rename, Duplicate, Copy as text, Paste a profile, Turn every mod on, Delete), Load (greyed when nothing would change) (MD:1228-1238, 1014-1029).
- Load (MD:824-869): exactly its mods, its order (else the rules'), its pins and rules become the list's, the note names what changed and what is not installed. New (MD:905-911), Update (MD:913-920), Rename (MD:922-937), Duplicate (MD:939-956), Delete (MD:958-972), Copy as text "name:id;id;" in order (MD:975-986), Paste (vanilla's addSharedPreset, MD:989-1012). Name rules (MD:897-903).
- Click picks, a second click loads (MD:2348-2360); the pad's A on a row loads (MD:2174).

**The band (buildStrip MD:1178-1278):**
- List page: Back; New folder... (Full, not Workshop tab); Profiles and Load order (always, MD:1259); Map order (only while maps clash, vanilla's checkMapConflicts, MD:1244-1263); Open Workshop (Workshop tab); with changes waiting on the player's own list: the pending line, Undo changes (when on/off or order changed), Reload, Quit to restart (Steam updated a running mod); else Accept (MD:1266-1276).
- The pending line (pendingNow MD:308-345): "n turned on, n off", "Load order changed", Steam updated <names> (restart), else files switched, picks changed, a reset (ZUI:1778-1779, 1962). Never in a save's, new game's or server's list (MD:1267).
- Questions in the band: back (Keep editing, Discard changes, Keep, MD:1183-1189), template, turnoff, reset, delete, update, the name and paste fields (MD:1190-1227). SAFE_ANSWER puts the controller on the answer that keeps work (MD:1084-1085).

**Back, Accept, Undo (MD:588-697):**
- Back: on/off changes ask; otherwise Accept (MD:714-718). Discard changes: every mod back as it loaded, favorites too, then Accept (MD:649-658). Undo changes: the mods and the load order back, the screen stays (MD:683-697).
- Accept (MD:597-639): rebuild ZeD picks' copies for the list about to run (player's own list only), force the reload vanilla would skip when a running mod was updated by Steam, picks changed or a reset ran (MD:613-633), ZeD picks last (PN:710-723), then vanilla's acceptChanges (MSM:240-302).

**Data read:** getModDirectoryTable and each ModInfo (MSM:61-78), the active lists (MSM:226-234), getActivatedMods (the running list, SC:158, 456), getLoadedLua and script bodies (the conflict scan, SC:157-295), Steam's item IDs and details (SC:421-443), PZAPI options (ST:74-108), each mod's files through getModFileReader (ST:228-240), Zomboid/Lua listings (RS:87-98), ZeD_error_places.txt (FL:351-382).

**Files written under %USERPROFILE%\Zomboid:**
- mods/default.txt: vanilla's saveModsFile on every Accept of the player's own list (MSM:279).
- Saves/<mode>/<save>/mods.txt: on every Accept or Back of a save's list (MSM:249-252).
- Lua/pz_modlist_settings.cfg: favorites and presets, on Accept and every profile change (MSM:344-365; MD:885, 928, 946, 964, 996).
- Lua/ZeD_modsview.txt: tab and Hide incompatible (MD:71-89).
- Lua/ZeD_modprofiles.txt and ZeD_modprofiles_spare.txt (MO:48-95).
- Lua/ZeD_picks.txt (PK:53, 81-95) and the ZeD picks mod's own folder through getModFileWriter (PK:309-311; held paths are never removed, PK:19-24).
- Lua/ZeD_modconflicts_hidden.txt (SC:51, 112-117).
- Lua/ModOptions.ini (ST:143, 173); Lua/ZeD_reset/<mod>/<stamp>/... and the mod's own files emptied (RS:368-435).
- Lua/ZeD_mods_jump.txt emptied when taken (FL:399-410).
- The clipboard on Copy as text (MD:984).

**Pad path (MD:2364-2560):** D-pad is spatial (MN:2498-2545); a press into the list lands on its chosen row (MN:2538-2541). List: A on or off, X favourite, Y Profiles, LB and RB walk the tabs, B back (MD:2430-2454, 2482-2487). Pane stops scroll the pane to show them (MD:2382-2390); left and right change an option row in place (MD:2371-2377). Find, its Clear and Hide incompatible are one row (OR:600-603, MD:1502-1504). Profiles: A load, Y new, X more, B back (MD:2461-2465). While a profile question or field is open only left and right move (MD:2366-2369). Palette and questions take B first (MD:2421-2424).

**Lite branches:** modsSimple is Lite (SET:732-733). Tabs All, On, Off, Problems (MD:74, 1305-1309); one-line rows (MD:1559-1573); About only (PN:90); no folders or Move to folder (MD:1256, 1849); Profiles and Load order stay (MD:1257-1262).

**Small screens:** tabs fit (MD:1329-1389); Find keeps 140 units, then the hidden count goes, then the label is cut (MD:1483-1496); verbs wrap under the poster (MD:1824-1843); the detail tabs shrink padding and gaps only (PN:91-105); the reset question drops its file names when narrow (PN:428-433).

## 2. What the game does for the same jobs

- **List and filters (MLP:84-135, MLB:172-241):** a category combo (map, vehicle, features, modpack), a search box (Lua patterns, not plain text, MSM:192-198), "Show enabled mods" and a Favorites button. The row: tick, red cross when it can't run, icon, name colored by state, an orange name with an "Incompatible with" tooltip, star. ZeD has a Maps tab but no vehicle, features or modpack filter.
- **On and off (MLB:34-60, 262-276):** forceActivateMods on click, A, X for favorite; the template mod asks in a modal. Enable all skips the template; Disable all (MPR:223-237).
- **Info pane (MIP:5-94):** Status, Version, Author, Homepage (asks before opening, MIPP:28-35), Path (the local folder or the Workshop URL), ModID, WorkshopID, Source, ZomboidVersion ("**" open), Dependencies and Incompatible with as links that open that mod in the pane (MIPI:10-77), posters 2..N as thumbnails (MIPT:42-58).
- **Presets (MPR:124-290):** a combo with Choose, Disable all, Enable all and the saved presets; Save (ISTextBox, isValidPresetName), Del (no question), Share (clipboard, a modal), Add (paste). Choosing a preset applies it at once, saves its order by requirements (correctAndSaveModOrder) and opens the Missed mods window listing each missing mod as a button to its Steam page (MISS:19-35). No order of its own, no compare, no rename or duplicate.
- **Back (MS:160-180, 234-249):** on/off changes ask YES (keep) or NO (revert on/off and favorites, then accept). No Undo that stays on the screen.
- **Accept (MSM:240-302):** the same acceptChanges ZeD calls.
- **Help (MS:181-196, HELP:24-29):** a Help panel with six sections (B41 mods, filters, presets and sharing, load order, map order). ZeD has no Help page; its hover help is per control (ZUI:3877, 4606).
- **The nag (MS:322-344, NAG):** a 650x400 panel once per run.
- **Mods changed by Steam (MS:346-351):** reload while visible, the same as ZeD.
- **Load order and map order (MS:197-231):** separate panels; ZeD's pages are the other agent's.
- **In game (PML:6-40):** a plain list with Not found, Not available and ERRORS; ZeD's pause window has its own Mods page (MN:2332-2350, 894-905), outside this map.
- **ModMoreInfo (MMI):** dead in 42 (nothing opens it).
- **What ZeD adds that the game lacks:** tabs with counts, Problems and Conflicts, Hide incompatible, the reason line, the Workshop tab and states, Options, Sandbox, Conflicts and Files tabs, Reset settings, profiles with order and compare, the safety question for a save, Undo changes, the pending line and forced reloads.
- **What the game has that ZeD lacks:** Help; category filters past maps; Missed mods' Steam buttons; clickable dependencies; the Path and Source lines; extra posters; the URL question.

## 3. Gaps and risks

Each check: what to look at, evidence, kind. **[S]** a main-menu Lua script can stage it (any change to a mods list undone before the script ends; nothing sent to Steam); **[H]** by hand or not at all (it reloads Lua, needs a save, a server screen, a real Steam change or writes that can't be undone).

**Opening and leaving**
- **MM1** Each opener lands here with the right list and title: main menu, a save, a new game, server settings (MD:1128-1133, 2568-2580; SV:433-441, 995-1003; MN:2858-2871). Plain check. [S] main list and new game; [H] save (QA save in Saves/Sandbox/ZeD-QA only) and server.
- **MM2** Leaving by any route but Back or Accept (the desk's menu bar, a desktop icon, Quit to restart) skips the Back question: showView has no guard (MN:2878-2905), Quit to restart is askQuit, which shows the main window (MD:1271, MN:1035-1041). The on/off changes stay in the in-memory list, unsaved (default.txt is written only by acceptChanges, MSM:279); quitting drops them, and the next MM.openMods takes them as the baseline (defaultActive, MSM:71), so Back no longer asks. Bug (suspected). [S] toggle, MN.showView("main"), reopen, read changed(), then put the mod back.
- **MM3** ZeD-GUI's own Options tab offers Open in Options with no greying (PN:295-298); every other mod's is greyed while changes wait (PN:347). It leaves the window as in MM2. Bug. [S]
- **MM4** The close box on the Profiles page calls back(), which treats any page but list as an order page: leaveOrder(false) (MD:2537, 716; OR:144-171). A rename, duplicate or delete question open there is never closed (leaveOrder does not touch confirm), so it follows onto the list page's band with its field; Find is set to a stale _listFind (OR:166). Bug (suspected). [S]
- **MM5** A reload need is forgotten when you leave and come back: onShow drops _resetPending and _filesChanged and recomputes _picksRefreshed from a sync that now writes nothing (MD:155-163). Reset settings or a file switched off, then Open in Options (PN:347, 474-482) and back: the band says nothing and Accept forces no reload (MD:622-626), so the old code keeps running. Bug (suspected). [H] (the reload itself), the band state is [S].
- **MM6** The nag: ZeD's note once per run, over the Mods window, the pad holding it and returning to the window, not the menu (PR:203-233). Vanilla's panel in safe mode. Plain check. [S] setModsPopupDone(false) first, then restore it.
- **MM7** A Workshop download while the window is up reloads the model (MD:2593-2600, MSM:56-86): stars set this visit are wiped (favs reread from the file, MSM:305-306) and the changed set becomes the baseline (Back stops asking, Undo and Discard return to it). The game does the same (MS:346-351). Design call. [S] if the script may fire OnModsModified; else [H].

**Tabs, counts, Find, Hide incompatible**
- **MM8** Every tab's count against its rows, with and without Find: All, On, Off, Starred, Maps, Problems, Conflicts, Workshop (MD:224-243, 176-213). Conflicts counts mods, not conflicts; Workshop counts Steam items, collections and items not installed included (MD:240). Plain check. [S] (MS.ws.fake for Workshop, SC:423).
- **MM9** Hide incompatible runs before the tab test (MD:194 then 197): ticked, the Problems tab lists only the broken mods that are on, while its count still counts every problem (MD:234-237); All and Off do not drop either. Design call (counts say one thing, rows another). [S]
- **MM10** A tab with nothing hides unless open (MD:1311): unstar the last starred mod on Starred, leave, the tab goes; a tab restored from ZeD_modsview.txt with nothing in it still opens. Plain check. [S]
- **MM11** The tab row at 1280x720 and 1280x800, Large text, Dutch and Hungarian: shrink, numbers drop, the row slides, no tab cut by the pane (MD:1329-1389). Small screens. [S]
- **MM12** LB and RB stop at the ends, no wrap; the fallback order without a drawn frame lacks Off and Workshop (MD:2446). Plain check. [S]
- **MM13** Lite forces a Full-only tab to All and saves tab=all, so going back to Full loses the tab (MD:1305-1306, 1400-1404). Design call. [S]
- **MM14** Find as plain text: "%", "(", ".", a Workshop number, a mod ID (MD:199-208); the game's search breaks on those (MSM:192-198). Plain check. [S]
- **MM15** Ctrl+F, Return leaves Find and is not taken as Accept (MD:123, 2503), B leaves it keeping the text (MD:2423), Clear (OR:601-603), Find empty on each visit (MD:137). Plain check. [S]
- **MM16** The picked mod hidden by Find, a tab or Hide incompatible stays picked and keeps the pane (MD:1414 sets sel only when there is none); an empty tab shows its empty line beside a full pane. Design call. [S]

**Rows, on and off, requirements, incompatibilities**
- **MM17** Row looks on, off, can't run, with tags and a star, selected and focused (tags drawn on the fill, MD:1292-1295), hover star (MD:1608). Plain check. [S]
- **MM18** Click picks, a second click within 450 ms toggles, the box toggles at once, the star toggles, Space toggles (MD:1613-1614, 1732-1743, 2523). Plain check. [S]
- **MM19** Turning on a mod that can't run only plays the hover sound; nothing says why beyond the row's line (MD:548). Design call (the game is silent too, MSM:404). [S]
- **MM20** The cascade note lists what came along on and off, for 6 s (MD:567-573, 585): a mod with two needs, a mod others need. Plain check. [S]
- **MM21** A requirement that conflicts with a mod that is on stays off while its dependant goes on (forceActivateMods MSM:404 from MD:505, 553); the dependant shows no problem (problemRun reads isAvailable only, MD:382). Vanilla parity, likely a real gap. [S] with two QA test mods.
- **MM22** Two mods that declare each other incompatible can both be on (exact sets, MD:481-486, 530); neither row shows a problem (problemNow is for off mods only, MD:399) and Problems does not count them; only About's Cannot run with dot is red (MD:1965). Design call. [S]
- **MM23** The template question lands the controller on Turn on, not Cancel: "template" is not in SAFE_ANSWER (MD:1084-1085, 1111). Design call. [S]
- **MM24** Turn every mod on: the template stays off, the first in name order wins each conflict, the note "Every mod that can run is on" (MD:482-486, 1023, ZUI:1822). Plain check. [S]
- **MM25** No mods and Turn every mod off include ZeD-GUI; nothing says the next reload drops ZeD (MD:804-821, 830-834). Design call. [S] read only (count what would go off; do not accept).
- **MM26** Version text: a B41-only mod reads "Made for game x to y" with "any" for an open end, About gives the verdict over the Game row (MD:370-381, 1882-1887, 1923). Plain check. [S]
- **MM27** "Needs a, b": ids for mods not installed, names for installed ones that can't run (MD:382-391). Plain check. [S]
- **MM28** Frame cost with the 1,500-mod library: rows 500 ms, counts and problems a second, row stops only in sight (MD:175-243, 355-366, 1432-1464). Plain check (perf baseline). [S]

**The detail pane**
- **MM29** About against the game's pane: no Path or Source line, poster 1 only (MD:1792; MIP:9, MIPP:73-88, MIPT:42-58). Design call. [S]
- **MM30** Needs and Cannot run with are text; the game's are links that open that mod in the pane (MIPI:21-25). Design call. [S]
- **MM31** Homepage opens the mod's own URL with no question (MD:1853); the game asks first (MIPP:31-35). Design call. [H] (opens a browser).
- **MM32** The verbs wrap under the poster at Large text in long languages, none past the pane (MD:1824-1843). Small screens. [S]
- **MM33** Detail tabs: five with counts (About, Options n, Sandbox n, Conflicts n, Files n) only shrink padding and gaps; with no slide or number drop they can run past the pane on the Deck at Large text (PN:91-105; the list's tabs do more, MD:1344-1376). Bug (suspected, small screens). [S]
- **MM34** Options tab: a change kept on mouse up, the dot, Open in Options greyed with changes waiting, key and text rows read only (PN:224-309, 347); ModOptions.ini written at once (ST:143). Plain check. [S] with a QA test mod, then put the value back.
- **MM35** Left and right on a combo or slider row change it in place (MD:2371-2377), the help band follows the pad (PN:254, 548-589). Plain check. [S]
- **MM36** Colour row: the palette, click outside or B shuts it (PN:214-221, MD:2422); the pick is only kept when watchOption next sees the row with the button up (PN:173-180, 230), so check a colour picked and the tab left at once is still kept. Plain check. [S]
- **MM37** Reset settings: the files listed are the mod's own only (whole-word id, other mods' longer ids, own-words list, the game's files and ZeD's never, RS:60-81, 230-322); the question names them and the backup folder (PN:421-452); copies land in Lua/ZeD_reset/<id>/<stamp>/ (RS:368-394). Plain check. [H] (writes that can't be removed from Lua, RS:28-35; a QA test mod only).
- **MM38** A reset of options only says "back to defaults" and flags no reload even for a running mod (reload needs files > 0, RS:432; PN:462-468). Plain check. [H]
- **MM39** Sandbox tab for a mod that is off: its own translation file, its pages, defaults, booleans as greyed boxes (ST:247-316, PN:488-545). Plain check. [S]
- **MM40** Conflicts tab: titles, who wins, Load after... only for a file conflict this mod loses, not a patch and not fixed (MD:2084-2086), Pick files... only when both are on and loaded and ZeD picks is installed (PN:598-604), Fine, hide this, Show again (MD:2094-2098). Plain check. [S] read only; Hide writes a file, undo with Show again.
- **MM41** Hide is keyed by kind and the two mods (SC:143): a file the pair later shares is hidden too. Design call. [S]
- **MM42** Conflicts and their chips come from the running list, not the list on screen (SC:157-158, MD:2032-2033): a save's or new game's list shows the main list's conflicts. Design call. [S] new game list.
- **MM43** Load after... saves the order and says reload; the conflict then reads "loads after it once you reload" (MD:700-712, 2079-2081). Plain check. [S] then put the order back.
- **MM44** Pick files page: cards, the excerpt, Use these picks greyed until a change, Cancel (PN:651-935); it writes ZeD_picks.txt and copies into the ZeD picks mod's folder, turns picks on and last (PN:685-723, PK:286-319). Held copies never go away (PK:19-24). Plain check. [H] (lasting writes into a mod folder).
- **MM45** A file switched off in a save's list changes the one set every list uses (keyed by path, PK:119-137; FT:128-152). Design call. [H]
- **MM46** Open in Mods: the jump file is read once and emptied, the mod picked on its Files tab with the tab set to All, given up after 300 frames (FL:399-410, FT:175-192). Plain check. [S] write the jump file, open, read state.

**A save's mods: the safety question**
- **MM47** Turning off a mod in a save's list asks unless it is safe; the controller lands on Cancel; the words name the mod and the save (PN:987-1006, MD:1085; ZUI:1991-1993). Plain check. [H] (a QA save only).
- **MM48** Only the row, box and Turn off verb ask (MD:550): loading a profile, No mods, Turn every mod on with conflicts and Discard turn mods off in a save's list with no question (applyOnSet MD:519-532; MD:804-869). Bug (suspected) or design call. [H]
- **MM49** Grades read the running list: a mod on only in the save is always "not checked" for items and asks (SF:73-85); its dependants come from the save's list (SF:98-113). Plain check. [H]
- **MM50** About's If you turn it off shows for the main list too, "for your main list" (PN:951-963), but nothing asks there. Design call. [S]

**Profiles**
- **MM51** Rows, dots, counts and the right pane's lists against the mods on now; the load order lines with separators (MD:2153-2345). Plain check. [S] with a QA profile, deleted at the end.
- **MM52** Load and Update are greyed when the mods match the ones on (MD:1230-1238, 788-789): a profile with the same mods in another order can't be loaded to get its order back or updated with the new one. Design call (likely a real gap). [S]
- **MM53** Paste a share text whose name is an existing profile: vanilla's addSharedPreset replaces that profile (MSM:387-392), ZeD saves it at once (MD:995-996), finds no new name and says "Nothing to add: the text is not a profile" (MD:998-1011, ZUI:1832). The pasted name never meets nameFree either: "No mods", an "@" name (ZeD's list sections, MO:174) or an invalid name gets in (MD:897-903; the band checks only for ":", MD:1217). Bug. [S] with QA names only, then delete.
- **MM54** New, Rename and Duplicate names: invalid characters, "No mods" and its translation, "@", a taken name, Save or Rename greyed while invalid, "Copy of" offered (MD:897-903, 1098-1105, 1214-1222). Plain check. [S]
- **MM55** Delete asks and acts on the profile it was opened on, also from the Delete key (MD:958-972, 1096-1097, 2522). Plain check. [S]
- **MM56** Copy as text then Paste round trip keeps the order (MD:975-1012). Plain check. [S] (the clipboard is touched; restore is not possible, say so).
- **MM57** A mod id with a leading backslash (the B42 "\ModId" form) is dropped by presetIds and by Paste's order (tostring(k):match("^[^\\]+") gives nil, MD:742, 1002). Plain check. [S] paste a text with "\" ids, read the profile, delete it.
- **MM58** A profile with mods not installed: the note lists ids (MD:866); there is no way to their Steam pages as the game's Missed mods window gives (MPR:271-289, MISS:19-35). Design call. [S]
- **MM59** The profile in use in the title; two profiles with the same mods: the last loaded or saved wins (MD:794-801, 1137-1138). Plain check. [S]
- **MM60** pz_modlist_settings.cfg stays readable by the game's own screen (safe mode): its presets, favorites first line (MSM:304-365); ZeD's extra data survives the game rewriting it. Plain check. [H] (safe mode).

**The band: Back, Accept, Undo, Reload, Quit to restart**
- **MM61** Up to nine buttons on the list page's band (Back, New folder, Profiles, Load order, Map order, Open Workshop, Undo changes, Reload, Quit to restart; MD:1250-1276) at 1280x720 Large text. Small screens. [S] (MS.ws.fake for the restart case is not enough: it needs updatedNow, set by hand in the script).
- **MM62** The pending line's words for each case (MD:308-345, ZUI:1778-1779, 1962) and none in a save's, new game's or server's list (MD:1267). Plain check. [S]
- **MM63** Back asks only for on/off changes (MD:588-594): a star or an order-only change goes straight to Accept and a reload. The game is the same (MS:164-180). Plain check. [S] up to the question; the answer reloads, so [H] past it.
- **MM64** Discard changes leaves the load order changed (MD:649-658), while Undo changes puts it back (MD:688-693); the help says Discard throws away "what you changed since this window opened" (ZUI:3830). File switches, picks, option changes and resets are kept by both. Bug (suspected). [S] for Undo; Discard ends in Accept, so [H].
- **MM65** Accept forces the reload vanilla would skip (Steam update, picks, reset) on the player's list only (MD:608-633). Plain check. [H] (it reloads Lua).
- **MM66** Accept writes default.txt every time; Back or Accept on a save's list rewrites its mods.txt even with nothing changed (MSM:249-252, 279). Plain check: no real save is opened by QA. [H]
- **MM67** After Reload the Steam memory is gone (MS.ws is rebuilt with the Lua, SC:373): no Updated tag, no restart note, no Quit to restart, though the pictures are still old (MD:1943-1953). Design call. [H]
- **MM68** "Updated while the game ran" needs the change after the window's first poll this Lua session (SC:408-410): an update finished at the menu before the first visit reads as up to date and asks no reload. Plain check. [H] (a real Steam update).

**Workshop**
- **MM69** Workshop tab: states, ago, size, collections, boxes only on items with a mod, the empty lines (Steam off, asking, nothing), polled every 10 s and only on the list page (MD:1626-1714, 1119; SC:418-443). Plain check. [S] with MS.ws.fake and a filled MS.ws.order; never Open in Steam or Open Workshop.
- **MM70** A Workshop row without a mod: a second click or A opens Steam (MD:1670, 1717-1723); its pane says why there is no mod (MD:2138-2143). Plain check. [H] for the open (Steam overlay); the pane is [S].

**Pad**
- **MM71** Prompts per stop: list, Workshop row, Profiles, a question, option rows (MD:2456-2489); B from each question returns to the stop that asked (MD:1089-1112). Plain check. [S]
- **MM72** Up and down are blocked under a profile question but not under back, template, turnoff or reset (MD:2366-2369): check a pad press can't pick another row under those. Plain check. [S]
- **MM73** Pane stops scroll the pane to show them; Hide incompatible reached from Find (MD:2382-2390, 1502-1504). Plain check. [S]

**Lite, safe mode, server, the game's extras**
- **MM74** Lite rows have no star or Starred tab, yet the pane still offers Favourite and X still stars (MD:1559-1573, 1847, 2434). Design call. [S]
- **MM75** The Lite test at MD:1259 (not simple or lite()) is always true, since modsSimple is lite (SET:732-733). Drift, not behavior.
- **MM76** Safe mode: the game's ModSelector, Back modal, presets and Help all work on the same files (OMM:157-191). Plain check. [H]
- **MM77** Server settings' list: Accept goes back to the settings (MD:603, 637; MSM:267-277), ZeD picks never added to it (PN:685-694), the Files tab says why it can't switch (FT:251). Plain check. [H]
- **MM78** The game's Help panel and its category filters (vehicle, features, modpack) have no ZeD counterpart (MS:181-196, HELP:24-29, MLP:88-93). Design call.

**Staging notes.** A main-menu script can open the window (MM.openMods), set filter, hideInc and the Find text, pick rows, toggle through the window's own calls, read counts(), rows(), problem(), pending(), profileDiff() and the band's specs, and must end with the list as it found it (applyOnSet(defaultOnSet(), true) and the saved order, MD:642-646, 683-697) and without Accept (it writes default.txt and may reload Lua, which ends the script). Profile checks use QA-only names and delete them; Hide uses Show again; star changes are undone before Back. Workshop states come from MS.ws.fake (SC:423), never a Steam call or the overlay. Picks, file switches and Reset settings leave lasting writes Lua can't remove (PK:19-24, RS:28-35): by hand, with a QA test mod or not at all. A save's list only with the QA save under Saves/Sandbox/ZeD-QA (MM1, MM47-MM49, MM66).
