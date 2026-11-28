# Main menu desk: map for the gamut sweep (QA, Nov 27 2026)

A read-only map of ZeD's main menu desk (the pixel-art room, the CRT's menu bar and its pull-downs, the Project Zomboid window, the desktop's icons, the Pasties, the Trash and the small windows that hang on the desk: Desktop..., Credits, Terms of service, CletusWorks Notepad, Documents, ProtoPOP3 Mail, the Workshop uploader and its description editor) against the game's own MainScreen, CreditsScreen, ISTermsOfServiceUI and WorkshopSubmitScreen, written before the sweep scripts. New Game, Load, Join, Host, Options and Mods are mapped by other agents: here only the way the desk opens them. The pause window (in game) and the desk after a death (Overrides/Respawn.lua) share this code and are named only where the desk's code branches for them. Line refs are as read on Nov 27. Nothing was run.

**The desk is MainScreen's child.** Vanilla's MainScreen still builds and runs; OMM hooks its instantiate, prerender, render, joypad and key handlers (OMM:91-104, 181-282) and MM.attach hangs ZeD_MMDesk on it at the main menu (MM:2826-2854). Vanilla's labels stay alive, parked at x -20000 (MM:3012), so MM.act can fire vanilla's own items (MM:979-985). Each later window registers itself with MM.addView (MM:2940-2945) and MM.showView puts one view on the monitor at a time (MM:2876-2904). ZeD_MenuGuess.lua (in the brief) is the in-game context menu's best guess: nothing on the desk reads it (MG:1-21, 45-52); it is left out below.

Short names: MM ZeD_MainMenu.lua, OMM Overrides/MainMenu.lua, DT ZeD_MainMenuDesktop.lua, DP ZeD_MainMenuDesktopPick.lua, DS ZeD_MainMenuDesktops.lua, CR ZeD_MainMenuCredits.lua, TM ZeD_MainMenuTerms.lua, NT ZeD_MainMenuNotes.lua, DN ZeD_DeskNotes.lua, DC ZeD_MainMenuDocs.lua, ML ZeD_MainMenuMail.lua, MST ZeD_MailStore.lua, WS ZeD_MainMenuWorkshop.lua, DE ZeD_MainMenuDescEdit.lua, MG ZeD_MenuGuess.lua, SV ZeD_MainMenuSaves.lua (MM.ui, MM.wheel's base), SM SafeMode.lua, ST Settings.lua, ORG Organisms.lua (ZeD_Window), ZUI shared/Translate/EN/UI.json.
The game's files (media/lua/client): MS OptionScreens/MainScreen.lua, CS OptionScreens/CreditsScreen.lua, WSS OptionScreens/WorkshopSubmitScreen.lua, SWI OptionScreens/ServerWorkshopItemScreen.lua (the join's server items: mirrored by the Join agent's "wsitems" view, not the desk's), TOS ISUI/ISTermsOfServiceUI.lua, OSK ISUI/ISOnScreenKeyboard.lua.

## 1. What it does

**Getting there:**
- Boot: the engine reaches MainScreen; OMM's instantiate runs vanilla's (under pcall, OMM:185-186), re-reads Safe mode (OMM:189) and attaches the desk unless Safe mode is on (OMM:190-191). The first launch shows the Welcome view instead of the main window (ZeD_MainMenuWelcome.lua header, 1-17; not mapped here).
- Before the main menu, a terms change (TermsOfServiceState) shows ZeD's terms window on its own over black (TM:264-307), only when vanilla's own version test says so (TOS:173-181).
- Back from a game, after a Lua reload or a mod reload: the desk is built anew and the monitor switches on again (MM:641-650).
- After a death the same room comes back as ZeD_MMRespawnDesk with only the ZeD menu's About block and no power button (MM:1089, 1104; Overrides/Respawn.lua:90-126).
- Safe mode on: none of it; vanilla's own main screen (OMM:18-23, 226-282).

**The room and its frame (MM:12-24, 225-341):**
- One 480 x 270 picture at the largest whole multiple that keeps the CRT's 240 x 180 tube on screen (MM:230-247); ultrawide margins in the wall and desk colors per half (MM:427-436).
- Small life that does nothing: the hard disk light, the floppy light, the lamp dips, lightning in the painting (MM:357-416, 438-452).
- The change note on the corkboard: its heading from ZeD's version ("BETA 21C", "V1.0", else "DEV") and up to five lines of ZeD.MenuNote, each cut to 10 letters (MM:455-534, 85).
- The wallpaper inside the tube: the chosen desktop (MM:592-596, DS:239-262) or the game's painting or title video, dimmed (MM:602-621).
- The glass: scanlines and edge falloff over the tube (MM:624-639); a 100 ms dip to black when the framing changes (MM:319-341).
- The wake: the screen stays black until the desk, the wallpaper tiles, the icons and the Continue thumb are in, or 10 s pass (MM:2008-2064, 878-884, DT:83-86); then the monitor switches on, about 0.95 s, nothing answering while the picture opens (MM:651-708, 1634).
- Starting a game: every forceChangeState(LoadingQueueState) from the desk is held while the monitor switches off, 0.6 s, the disk light busy; a second start meanwhile is ignored; a start that never leaves brings the monitor back after 2 s (MM:718-758).
- The case's power button: Quit, with the game's "Exit" as its hint (MM:80, 1612-1615, 2181-2191).

**The Project Zomboid window ("main", MM:2194-2415):**
- The Continue card when vanilla shows Continue (MM:852-873, 2294-2305): the save's picture, the character (a red square when dead), the save's name ("Sandbox, Oct 12", "(crash)" kept, MM:810-820), mode and map ("Knox Country" for the whole county, MM:824-828), "Last played ..." (MM:839-849), and the Continue button.
- Five wide buttons: New Game, Load Game (greyed with no saves), Join a server, Host a game, Tutorial (no mods) (MM:2306-2318). New Game is primary when there is no Continue.
- The band: Options, Mods (n), Workshop (only with vanilla's workshopOption), Credits, Quit (greyed during the quit cooldown) (MM:2378-2383). Quit swaps the band for "Quit Project Zomboid?" with Cancel and Exit (danger) (MM:2372-2375).
- The close box closes the window to the bare desktop (MM:2774-2779). The window never moves or resizes (MM:2205, 2731-2732) and draws solid on the desk whatever See-through says (MM:2240-2246).

**The menu bar (MM:1087-1141, 1659-1704):** titles left to right, the clock at the right (12 or 24 hour from the game's option, MM:937-949).
- ZeD (the logo): the About block (Zero Day OS, the owner's rough paragraph, Encryption, Phone taps, Uptime since boot, Display (screen size, scale), ZeD version, Game build; MM:1723-1761), then CletusWorks Notepad, Pasties (grey at 8), ProtoPOP3 Mail (NT:606-626), then Credits, Terms of service, Report a bug (MM:1105-1109).
- File: Continue (grey without one), New Game, Load Game (grey without saves), Tutorial (no mods), then Exit (asks) (MM:1110-1117).
- Multiplayer: Join a server, Host a game (MM:1118-1119).
- Settings: Options, Mods (n on), Workshop (with workshopOption), the first-launch setup again (not in game), then Desktop... (MM:1120-1129).
- Debug (debug mode only): Reset Lua, Scenarios (while DebugScenarios.instance lives), the Lua console (while it exists) (MM:1096, 1130-1138).
- After a death: the ZeD title alone, its About block alone (MM:1089, 1104).

**What each row does (MM.act, MM:987-1056):**
- Continue: vanilla's LATESTSAVE item (MM:988, MS:1326-1328). New Game: copies the default mods into currentGame and shows the "newgame" view (MM:991-998, cf. MS:1381-1385). Load Game: the "load" view when there are saves and vanilla's boot delay is over (MM:999-1005). Tutorial: vanilla's TUTORIAL item (MM:1012, MS:1417-1419).
- Join: the "join" view (MM:1006). Host: vanilla's onlineCoopScreen aboutToShow and setVisible, which lands on the "host" view (MM:1007-1011).
- Options: MM.openOptions (MM:1013). Mods: MM.openMods (MM:1014). Workshop: the "workshop" view, or vanilla's item when that screen is missing (MM:1016). Credits: the "credits" view (MM:1017). Terms: the "terms" view, else vanilla's dialog (MM:1019-1024). Report a bug: vanilla's onClickReportBug, TIS's forum in the Steam overlay or the browser (MM:1025, MS:1515-1522).
- Exit (File, the band's Quit, the power button, the Trash): askQuit brings the main window up and asks in its band (MM:1035-1041); Exit runs vanilla's quitToDesktop unless cooling (MM:1042-1045, MS:1486-1491).
- Reset Lua: getCore():ResetLua at once (MM:1026). Scenarios: shows or hides vanilla's list above the desk (MM:1027-1033).
- Desktop...: the "desktopPick" view (DP:212-215).

**The desktop (DT:1-27, 88-169, 175-355):**
- The right column, top down: Project Zomboid (the main window), New Game, Load Game (grey without saves), Join a server, Options, Mods, Mod Uploader (the Workshop, only with workshopOption); the Trash in the bottom corner (DT:54-69). A column that would reach the Trash starts another to its left (DT:104-110).
- The left column (none in Lite): Pasties, CletusWorks, ProtoPOP3 Mail (with its unread count, ML:73-84), Documents, then the Pasties' notes where they were put (NT:586-603). A column that would run into the right block stops the list (DT:121-150).
- A click selects (name in accent, picture darkened), a second within 450 ms opens; double-clicks are counted every frame, not every 100 ms (DT:258-291, 321-339). Icons lie under every window and do not answer through one (MM:1156-1160).
- Pasties: the icon (or the ZeD menu row) sticks a new note beside it, up to eight, placed off the open window and the icons when it can (NT:466-562). A note: pale yellow on every theme, a top strip to drag it, a close box at the strip's end (asks "Throw away" or "Keep" when it has words), words typed in place, saved 800 ms after the typing stops or when it lets go of the keys (NT:80-401, 420-464).

**The Trash (DT:586-681):** a small window with one file, the Computer, 40 MB. Close, Empty trash; Empty asks "Quit Project Zomboid?" in its band, Cancel or Exit (DT:654-664).

**Desktop... (DP, DS):** 25 desktops in four groups (Game art: the painting, the title video; Patterns: 10; Quiet: 5; Fun: 8; DS:30-37) as 64 x 48 swatches in 8 columns. A pick sets and keeps it at once, there is no Apply (DP:52-63). The in-use one has the accent ring and accent name (DP:114-123). The help line: "Name: note" for the swatch under the pointer or focus (DP:65-74). The band: where the patterns' color comes from (the game's "Color of Highlighted Container"), and Done (DP:179-184). The patterns and Solid take that color at the middle tone (DS:102-187); Accent takes the accent's Dark value in every theme (DS:189-197); the video falls back to the painting while the game's video effects are off (MM:604-617).

**Credits (CR):** the game's credits (credits_start and its logo, every CreditsRoleGroup with its logo, roles and names, the translators sorted by language, the Spiffo URL; CR:32-71) rolling up a framed box, faded at its edges (CR:140-207). The band: Back, <<, Pause or Play, >> (CR:209-214). Rewind runs at 3x back, fast at 6x; a second press on << or >> plays again; the roll stops paused with the last line halfway up (CR:22-23, 92-101, 160-167). The wheel anywhere on the desk rolls it (CR:251-263).

**Terms of service (TM):** the game's prompt (and the browser note without the Steam overlay) in a scrolling box (TM:37-50, 118-160). On the desk: Back, Quit, View terms of service, View privacy policy, Accept (TM:161-168). At boot: the same without Back, centered over black, its own pointer (TM:105-116, 212-259). Every answer is vanilla's function: Accept stores the terms version and saves the options (TM:52-58, 87-99, TOS:105-116), the View buttons open the overlay or the browser (TOS:87-103), Quit quits at once (TM:103, TOS:118-120).

**CletusWorks Notepad (NT:628-1000):** one page in an inset box, at most 20,000 characters (DN:44). The band: New, Open (goes to Documents), Rename (a field in the band), Delete (only a saved note), Save (primary); the left line says Saved, Not saved, Recovered, the page full or a write that failed (NT:927-944). Leaving a page with unsaved words by the close box, B, Escape, New or Open asks "Save changes?": Discard changes, Cancel, Save (NT:686-695, 901-907). Any other way out keeps the words as a draft, and the notepad opens with it next time (NT:698-720, 850-863, 989-998).

**Documents (DC):** every note, newest saved first, with its date (DC:24-36, 65-74); the band: Rename, Delete (asks), Open (primary), the count against 24 (DC:216-221). A second click within 450 ms or Return opens (DC:182-188, 244-247). Opened from CletusWorks' Open it closes back there (DC:38-44, 129-133).

**ProtoPOP3 Mail (ML):** offline mail kept by MST: one mailbox per server and name joined with (a pop-up when there are several), the folder tabs Inbox, Outbox and Sent with counts, the letters, and the letter or a new one (To, Subject, the letter) (ML:288-517). The band: New letter, Reply ("Re: ", the letter quoted with "> "), Delete (asks), and the last dial-in and the Outbox count; while writing Cancel (asks when changed) and Put in Outbox (greyed with its reason) (ML:519-555). Nobody has dialed in: how mail comes (ML:322-334).

**The Workshop uploader (WS) and the description editor (DE):**
- The folders in Zomboid/Workshop on the left, each with its title, its Workshop number or "not on the Workshop" and "not saved" (WS:459-525). The form on the right: Title, Who can see it (Public, Friends only, Unlisted, Hidden as radio buttons), Tags (the game's allowed tags), the preview picture (square 256 or 512, checked), the description (three lines of it, its count against the room left), Edit description, Copy codes, the change note (3 to 8 lines), What goes up (vanilla's validateContents in its words), the Workshop item and Open in Steam (WS:572-750).
- The band: Back, Save (greyed until edited), Upload or Upload update (greyed with its reason as the band's line) (WS:802-813). Upload asks "Upload "<title>" for everyone to see?" (its words follow the visibility, WS:38), then create (new items) and submitUpdate with progress in the band, Back greyed (WS:338-406, 779-782, 816-852). Back with unsaved edits asks: Keep editing, Discard changes, Save (WS:315-323, 789-801).
- The description editor ("wsdesc"): a palette of blocks and sections, the picked block edited in place with bold, italic, underline, strike and link codes at the cursor, blocks moved and removed, the Steam preview or the codes, undo and redo, the count against the room (DE:1-24, 462-487). Leaving with changes asks: Cancel, Discard changes, Keep (DE:198-205, 465-471).

**Data each reads:**
- The window: vanilla's latestSaveOption, MainScreen.latestSaveGameMode and latestSaveWorld, getSaveInfo, getLastPlayedDate and the save's thumb.png (MM:852-873); vanilla's hasSaveFiles (MM:887); getActivatedMods (MM:889-892); isQuitCooldown (MM:2370).
- The bar and About: the real clock and the game's 12 or 24 hour option (MM:937-949); boot time, screen size, UI scale, ZeD's mod.info version (id ZeD_UI), the game's build (MM:914-933, 1747-1754).
- The desktop: vanilla's workshopOption and hasSaveFiles (DT:59, 66); the note files and the mail store (NT:586-603). Desktops: ZeD_wallpaper.txt (MM:536-550), the game's objHighlightColor (DS:176-179), ZeD's accent (DS:190-197), getOptionDoVideoEffects (MM:604).
- Credits: CreditsRoleGroup, CreditsRole.getTranslatorCredits (CR:42-67). Terms: UI_TermsOfService_Prompt1 and 2, isSteamOverlayEnabled (TM:38-50).
- Workshop: getSteamWorkshopStagedItems, each item's title, description, tags, visibility, change note, preview image, ID, validateContents, getSubmitDescription (WS:120-226, 148-162); ZeD_workshop.txt (WS:52-71).

**Files it writes under %USERPROFILE%\Zomboid\Lua (getFileWriter is rooted there):**
- ZeD_wallpaper.txt: the desktop's id, one line, on every pick (MM:552-559).
- ZeD_desk_pasties.txt ("id|fx|fy" a line), ZeD_desk_pastie_1.txt to _8.txt (a note's words; emptied when thrown away), ZeD_desk_sticky.txt (emptied once when the old sticky moves into Pastie 1) (DN:298-426).
- ZeD_desk_notes.txt (header, then "id|modified|name"), ZeD_desk_note_1.txt to _24.txt (emptied on Delete), ZeD_desk_draft.txt ("id|name", then the words) (DN:36-46, 143-271, 431-462).
- ZeD_mail_boxes.txt and ZeD_mail_<n>.txt: on reading a letter, queueing, deleting (MST:32, 165, 230-372).
- ZeD_workshop.txt: the folder picked last and each folder's change note until it goes up (WS:52-87, 301, 392-395).
- Outside Zomboid\Lua: a folder's workshop.txt in Zomboid\Workshop (vanilla's writeWorkshopTxt, WS:263-269); options.ini through the terms' Accept (TOS:107-108) and ZeD's mod options when the theme, accent or text size changes during a desk window's update (MM:2784-2790).

**The pad (no FocusManager on the desk: each window keeps its own focusId, MM:1305-1308):**
- OMM hands A, B, X, Y, the bumpers and the D-pad to MM.joyDown and MM.joyDir while the desk is up (OMM:242-276, MM:3141-3209). An open pull-down takes them first: Up and Down wrap its live rows, Left and Right walk the bar's titles, A picks (and hands the pad back to the window), B shuts or goes back to the pull-down it came from (MM:3141-3158, 3178-3201).
- In a window the D-pad moves by place (ZeD.SpatialNav), the old row grid only where controls have no rectangles (MM:2499-2557); A presses (MM:2559-2565); B answers No, closes a desk window with nothing left to back out of, never closes the main window (MM:2567-2578). The footer prompts: A Select and Y Legal on the main window, A Exit and B Cancel in its question (MM:2580-2586). Y on the main window opens the terms (MM:3167-3171).
- The desk as one screen: Up past the window's top goes to the menu bar, Left or Right past its side (or from a wide button at once) to the icons on that side (MM:3034-3111, 2511-2518, DT:191-230). On the bar Left and Right walk the titles, A opens, Down or B goes back (MM:3096-3127). On the icons the D-pad moves, A opens, pushing toward the window or B returns (DT:475-507, MM:3129-3137).
- The bare desktop (window closed): the icons take the pad and the keys, with their prompts along the screen's foot (DT:232-237, 344-354, 457-472).
- A Pastie: A picks it up, the D-pad moves it 16 units a step, A puts it down, B puts it back, X writes on it (the game's on-screen keyboard), Y throws it away (asking when it has words) (DT:363-367, 475-564, NT:62-75).
- Fields: Notes, Documents and Mail open the game's OnScreenKeyboard on A (NT:62-75); the Workshop's title and change note, and the description editor's cards, focus the field directly (WS:568, DE:397, 400, 402).
- Credits: A pause or play, X fast, Y rewind, B back, Up and Down move the roll (CR:222-239). Terms: the D-pad's Up and Down scroll, Left and Right walk the band, B back (TM:176-198); at boot its own joypad handlers (TM:241-251).

**Keys (MM.keyRelease, MM:3218-3231):** Escape shuts an open menu, then the window's own keyEscape, then a question; otherwise vanilla's onKeyRelease runs (OMM:278-282). Other keys go to the window's keyOther: Return opens on the desktop and in Documents, accepts in the terms, plays and pauses in Credits, closes the Desktop window; the arrows move the desktop icons and Credits' speed (DT:572-584, DC:244-247, TM:188-191, CR:242-247, DP:203-206).

**Lite (ZeD.Settings.lite, ST:648-652):** the desk's left column (Pasties, CletusWorks, Mail, Documents, the notes) and the ZeD menu's Notepad, Pasties and Mail rows go; the notes keep their files (NT:582-587, 611). Everything else stays: the room, the right icons, the Trash, Desktop..., the About block, Credits, Terms, the Workshop. The band's buttons take Lite's good and bad colors through the library (Molecules.lua:148-158).

**Safe mode (ZeD.Safe, SM:1-48):** with it on as the menu builds, no desk (OMM:189-191); every MainScreen hook runs vanilla's alone (OMM:226-282); vanilla's OPTIONS and CREDITS items are vanilla's (OMM:194-202). Turned on at the desk: the desk hides and MM.root goes, so the redirected screens show as vanilla's; the bottom panel, extras, Scenarios and mirrored screens come back; vanilla's Options loses ZeD's hooks (OMM:115-163). Turned off: the same desk returns, or a menu built in safe mode gets one (OMM:165-179). The boot terms window checks it too (TM:268-272).

**Small screens:** the room is the only framing where its tube holds 960 x 720 design units (MM:118-128, 249-253, 299-307). Where it does not (1280 x 720, 1366 x 768, a Steam Deck), the main window and the bare desktop stay in the room in the small layout (the window narrowed to the room left of the icon block, at the tube's left edge, MM:286-297, 2277-2283, DT:159-169) and every other view leans in: the desk at a bigger multiple with the whole tube and 10 desk pixels of the right bezel in view (MM:255-284), with a 100 ms dip between (MM:316-332). Pop-ups are kept inside the tube (MM:1788-1799, 1868-1892). The menu's scale is at least 1.0 while the desk is up (MM:343-349).

**Tests that name the desk (by file, ZeDUI/tools/qa):** desk_sim, desk_notes_sim, desk_pad_sim, desk_stub, desktops_sim, bx_desktop, bx_menu, rt_menus, rt_lite, zedqa_menu_nav, zedqa_menu_lite, zedqa_power_on, zedqa_workshop_upload, zedqa_workshop_room, zedqa_ws_preview, mainmenu_vanilla_sim, respawn_sim, popups_close_sim, scrollbar_edge_sim. Their coverage was not read for this map.

## 2. What the game does for the same jobs

The game's main menu is the logo and one column of labels (MS:404-528, 744-765): Continue (only with a save whose player is not a dead "A Really CD DA" one, MS:437-447), Load, Tutorial, Solo, Multiplayer, Co-op, Options, Mods, Workshop (with Steam or WorkshopSubmitScreen.TEST, MS:511-519), Credits, Exit; at the corner Report Bug, Terms of Service, Reset Lua (debug); the version button at the foot, which copies the build's git sha (MS:612-669, 767-769). Every label runs onMenuItemMouseDownMainMenu (MS:1301-1443), which first removes the debug scenario list and any terms dialog, then refuses while the boot delay, the tutorial prompt or a save check is up (MS:1308-1324).

| Job | Game | ZeD desk |
| --- | --- | --- |
| Continue the last save | The Continue label (MS:440-447, 1326-1328) | The Continue card with picture, character, save, mode, map, last played; the File row (MM:2294-2305, 1111) |
| Start a new game | Solo: default mods copied, soloScreen opened on its first panel (MS:1381-1385) | New Game button, File row or icon: default mods copied, the "newgame" view (MM:991-998) |
| Load a save | Load label, only with saves (MS:450-459, 1386-1389) | Button, File row or icon, greyed without saves (MM:999-1005, 2308, DT:59) |
| Multiplayer | Multiplayer and Co-op labels (MS:1363-1372) | Join a server and Host a game: buttons, the Multiplayer menu, Join's icon (MM:1006-1011) |
| Tutorial | Tutorial label | "Tutorial (no mods)", button and File row; vanilla's own item (MM:1012) |
| Options, Mods | Labels (MS:1377-1380, 1390-1396) | The band, the Settings menu, icons (MM:1013-1014) |
| Upload a mod | Workshop label, a ten-page wizard: pick a folder, the fields, new or existing ID, enter an ID, change note and publish with the legal link, edit text, the upload log, errors, an overlay hub (WSS Page1-Page10) | The band, Settings or the Mod Uploader icon: one window with the folders and the whole form, Save, Upload; a description editor (WS, DE) |
| Credits | Full-screen rich text rolling up; > speed (normal, fast, rewind), Pause; pad A closes, X speed, Y pause (CS:26-35, 50-61, 107-118) | A window with the same lists as end titles; Back, <<, Pause or Play, >>; pad A pause, X fast, Y rewind, B back (CR) |
| Terms of service | The judge window: View terms, View privacy, Accept, Quit; pad Y from the menu (TOS:37-67, MS:1493-1513, 1898-1903) | A window in the band: Back, Quit, View terms, View privacy, Accept; Y on the main window (TM:161-168, MM:3167-3171) |
| Report a bug | Report Bug button, TIS's forum (MS:612-620, 1515-1522) | ZeD menu > Report a bug, the same page (MM:1025) |
| Quit | Exit label, the game's modal "Are you sure?" (MS:1337-1350, 1445-1475) | Quit in the band, File > Exit, the power button, Empty trash: the question in the window's band (MM:1035-1045, DT:618-619) |
| See the build | The version button at the foot; a click copies the git sha (MS:660-669, 767-769) | The ZeD menu's About block: Game build and ZeD version; nothing copies (MM:1753-1754, 2979) |
| Reset Lua, debug scenarios | Reset Lua button; the scenario list over the menu (MS:410-420, 762-764) | Debug menu: Reset Lua, Scenarios, the Lua console (MM:1130-1138) |
| Choose the background | None (the title video, or the painting with video effects off) | Desktop...: 25 desktops, kept in ZeD_wallpaper.txt (DP, DS) |
| Notes, mail, sticky notes | None | Pasties, CletusWorks, Documents, ProtoPOP3 Mail (NT, DC, ML) |

ZeD has, the game doesn't: a save card for Continue; every entry three ways (a window button or band, a menu bar row, a desktop icon); the desk's notes, notepad, documents and offline mail; 25 desktops; the Workshop as one page with every check before Upload, the change note kept across sessions, a block editor for the description with its room counted; credits with rewind; the pad off the window's edges to the bar and the icons.

The game has, ZeD doesn't: the version button's copy of the git sha; the Workshop wizard's "existing item: enter its ID" path (WSS Page3, Page4, 411-697) and its overlay hub (Open the Workshop, my items, subscriptions, WSS Page9, 1255-1340); the upload log (WSS Page7, 1150-1153); the Credits pad's A to close; a quit question in its own modal that takes the pad (MS:1457-1474); the terms' Quit is unguarded in both.

## 3. Gaps and risks (DK1 to DK70)

Each line: what to check, the evidence, and the call (bug: looks like a fault; director: a design call; check: just to confirm). **Lua:** a script at the main menu can stage it through MM, N.io, MS.io, MM.forceGamepad, MM.joyDown(MainScreen.instance, Joypad.AButton), MM.keyRelease and MM.showView; **No Lua:** needs the real thing (real Steam, a real Workshop upload, quitting, a relaunch, a browser).

**Boot, frame and modes**
- **DK1.** The wake holds the screen black until the desk, the wallpaper tiles, the icons and the Continue thumb are in, giving up at 10 s; back from a game it steps aside at once (MM:2008, 2042-2064, 2018-2028, 878-884, DT:83-86). Check. No Lua for the cold boot; Lua for the readyChecks (make one return false).
- **DK2.** Nothing answers while the monitor switches on (MM:656-660, 1634, 2114): a click and a pad A in the first 0.47 s do nothing, then work. Check. Lua (MM.powerOn = { t0 = getTimestampMs() }).
- **DK3.** A start pressed twice during the switch-off starts once (MM:726); a start that never leaves the menu brings the monitor back after 2 s (MM:755-757). Check. Lua for the run path (MM.switchOff({ run = fn })); No Lua for a real load.
- **DK4.** Safe mode turned on in Options at the desk: vanilla's menu, labels, extras and Scenarios back, ZeD's Options hooks off (OMM:122-163); turned off again: the same desk, and MM.view as it was left (OMM:165-177, MM.view untouched): does the monitor come back on Options or on the main window? Check. Lua (ZeD.Safe option, Safe.reread).
- **DK5.** With the Safe mode option On, a terms change at boot still shows ZeD's terms window: Safe reads Off before the main menu (SM:44-48) and the boot check reads it then (TM:268-273). Director (or bug, low). No Lua (needs getCore():setTermsOfServiceVersion(0) and a relaunch).
- **DK6.** The desk's windows draw with no ZeD.Safe.guard or pcall (MM:1595-1616, 2588-2723): a Lua error in a desk window's prerender repeats every frame; check whether the watchdog trips (SM:10-17) or the desk just breaks. Check. Lua (a stub that throws in a view's prerender).
- **DK7.** The Continue card appears exactly when vanilla's Continue would: not for a dead "A Really CD DA" save, not without saves (MM:855, MS:437-447, 745-747); the dead character gets the red square (MM:2669-2673). Check. Lua (saves in Saves/Sandbox/ZeD-QA).
- **DK8.** The card's words: a date-named folder reads "<Mode>, <Mon> <D>", a "_crash" copy keeps "(crash)", a multi-map list reads Knox Country (MM:810-828); a long character name is cut with "..." (MM:2674-2679). Check, in EN, DE, JP, KO (the clock's AM and PM order, MM:830-836). Lua.

**The window, its band and the question**
- **DK9.** Load Game is greyed in all three places with no saves: the window (MM:2308), File (MM:1113), the icon with no hit (DT:59, 337-339); and pad focus skips it (MM:2422). Check. Lua (MainScreen.instance.hasSaveFiles).
- **DK10.** New Game copies the default mods (MM:996) but does not run vanilla's soloScreen:onItemClick(panels[1]) (MS:1384): confirm the "newgame" view starts on the same first step and mods as vanilla's Solo. Check. Lua.
- **DK11.** Host runs aboutToShow and setVisible without vanilla's bottom panel hide (MM:1007-1011 vs MS:1368-1372); Join shows its view without vanilla's requestServerList (MM:1006 vs MS:1366). Confirm both land on their views and the list fills (the Join agent's map covers the rest). Check. Lua for Host; Join's list needs the network.
- **DK12.** The band's Mods (n) counts getActivatedMods (MM:889-892, 2380) where the game's label has no count; after a change in Mods the count matches on return. Check. Lua.
- **DK13.** The quit question puts the pad on Exit (MM:2256) and the Trash's does too (DT:607-610); the Notepad, Documents and Mail land on Cancel (NT:830, DC:123, ML:272) and the Workshop on the answer that stays (WS:325-336). Pad A, A quits from the band. Director. Lua (stage only; do not press Exit).
- **DK14.** The question's footer says "A Exit" even when the pad has moved to Cancel (MM:2582, DT:675). Bug (low). Lua (MM.forceGamepad).
- **DK15.** The question's Exit is never greyed by isQuitCooldown though the band's Quit is (MM:2374-2375 vs 2383); quit() then returns silently (MM:1043). At the main menu the cooldown is probably never on: confirm isQuitCooldown() there. Check. Lua (read only).
- **DK16.** The close box takes the main window down to the bare desktop (MM:2774-2779), B never closes it (MM:2577), and the Project Zomboid icon brings it back on the same focus. Check. Lua.
- **DK17.** Return on the main window does nothing (no keyOther; MM:3229, OMM:280-281) though the key section's comment says "Return plays / goes on" (MM:3218-3219); the arrow keys move nothing outside the bare desktop (DT:579-582) and the Desktop window (DP:203-206 has Return only). Director (keyboard play) and drift. Lua (MM.keyRelease).
- **DK18.** The power button's hint never points at the button: the glass reads its own _hits[1] (MM:2185), which nothing sets; the power hit lives on the desk (MM:1613-1615), so the hint falls back to the pointer's place (MM:2189). Bug (cosmetic). Lua (MM.ctx.hot = "power", screenshot).
- **DK19.** The power button, File > Exit and the menu bar's rows leave any view with MM.showView, past the view's own leave question: Options' "back" question (Options:727-734), the Workshop's (WS:315-323), the description editor's (DE:199-205). Confirm what each keeps; see DK58 and DK59. Bug or director. Lua.

**The menu bar and its pull-downs**
- **DK20.** Every title and row as listed in section 1, in debug and not, with and without Steam, with Lite on and off (MM:1087-1141, NT:606-626); the Debug title only with -debug (MM:1096). Check. Lua (read MM.menus and MM.menuItems).
- **DK21.** A menu bar pull-down is never cut to the monitor or scrolled: the room and scroll logic runs for pop-ups only (MM:1868-1885 "if not pos"), so the ZeD menu with its About block (MM:1847-1849) can run past the tube's foot at 1280 x 720 or with Large text. Bug (small screens). Lua (open "zed", read MM.root.drop's bottom against the layout's ty + th).
- **DK22.** The bar's clock is always English in 12-hour mode (SimpleDateFormat with Locale.ENGLISH, MM:942-945) while Last played uses the translated AM and PM in the language's order (MM:830-836). Bug (low). Lua (language and Clock24Hour off).
- **DK23.** The About block: Uptime counts from the file's load (MM:174, 1748), so it resets on Reset Lua; Display reads the screen and scale; ZeD version is "?" if the mod's id is not ZeD_UI (MM:924-933). Check. Lua.
- **DK24.** Report a bug sends a ZeD player to TIS's bug forum (MM:1025, MS:1515-1522); ZeD's own report path is not on the desk. Director. No Lua (opens a browser).
- **DK25.** Debug > Scenarios disappears for the session once any vanilla item fires (MS:1308-1311 sets DebugScenarios.instance to nil; MM:1132). Check (debug only). Lua.
- **DK26.** Debug > Reset Lua has no question (MM:1026), as the game's button (MS:411). Check. Lua (do not press in a sweep that must keep state).
- **DK27.** The pointer: a press on a title opens, the open title shuts, another title under the pointer switches, a press-drag from a title to a row picks it, a press outside only shuts (MM:1178-1199). Check. Lua (MM.ctx and ZeD.MouseTick stubs) or by hand.
- **DK28.** The pad on the bar: Up off the window's top, Left and Right walk titles, A opens on row 1, Left and Right inside a pull-down change title, A on a row hands the pad back to the window, B from a bar reached from the icons returns to the icons (MM:3048-3068, 3114-3127, 3141-3201). Check. Lua (MM.joyDir, MM.joyDown with MM.forceGamepad).

**Desktop and icons**
- **DK29.** No icon for Continue, Host, Tutorial or Credits (DT:54-68), while the header says "the icons open everything the menus can" (DT:6-9). Director. Lua (read DT cells).
- **DK30.** The left column stops at the first item that would run into the right block, and `full` then drops every later item, Mail, Documents and every Pastie note, moved ones included (DT:121-150, 124, 139-141); the comment says "the rest are in the notepad's Open list", true only of notes. At UI scale 2, Large text or a narrow tube a note can vanish from the desk with its words kept. Bug. Lua (T.scale and text size, count MM._deskCells(MM.layout())).
- **DK31.** Selecting and opening: one click selects, a second within 450 ms opens, a frame-counted double-click opens once, not twice (DT:258-291); Return and A open the selected icon (DT:508-540, 575-577); a greyed icon has no hit (DT:337-339). Check. Lua for keys and pad; by hand for the double-click.
- **DK32.** The pad off the window's sides: from New Game to Tutorial Left or Right leaves at once (MM:2511-2518); only icons on that side and not under the window are reachable (DT:211-230, 495-506); pushing back toward the window returns. Check, in the room and the small layout. Lua.
- **DK33.** The bare desktop's pad prompts sit at the tube's foot on the left and change with the selection (Open; Pick up, Write, Close; Put down, Cancel; Throw away, Keep) (DT:344-354, 457-472). Check. Lua (MM.forceGamepad).

**Pasties**
- **DK34.** Up to eight notes: the ninth press does nothing, the icon and the ZeD menu row grey (NT:468-470, 564, 619, DN:352-357); a new note goes beside the icon, stepped, off the open window and the icons, else under the window without the caret (NT:466-562). Check. Lua (N.io swapped to a sim's files).
- **DK35.** A note saves 800 ms after the typing stops, on Escape, and on a press elsewhere (NT:105-108, 181-196); its file holds at most 600 characters and 12 lines (NT:43-45, DN:46, 301). Check. Lua (N.io).
- **DK36.** Closing a note with words asks Throw away or Keep on the paper; an empty one goes at once; the slot's file is emptied and its id reused (NT:407-418, 440-452, DN:413-426). Check. Lua.
- **DK37.** Notes in a pile: the one under another shows its words drawn by the icon layer and wakes on a press (NT:155-179, 287-334, 396-400); a press on a note under a window goes to the window (NT:231-235). Check. By hand (pointer) or Lua (MM.entryUnder).
- **DK38.** The old sticky's move: no ZeD_desk_pasties.txt and words in ZeD_desk_sticky.txt become Pastie 1 at its old place, and the sticky file is emptied (DN:327-341). Check. Lua (write the files, N.reset()).
- **DK39.** The pad on a note: A picks it up (shadow longer), the D-pad steps 16 units inside its room, A drops, B puts it back, X writes with the game's on-screen keyboard, Y throws away (asks first) (DT:475-564, NT:62-75, 342-346). Check. Lua (MM.forceGamepad; the keyboard needs a real pad).

**Trash and Desktop...**
- **DK40.** The Trash opens on Close; Empty trash asks Quit in the band, Cancel goes back to Empty, B and Escape cancel then close (DT:600-619, 672-678). Check. Lua (stop before Exit). No Lua for the quit itself.
- **DK41.** A pick writes ZeD_wallpaper.txt at once (MM:552-559) and the file is read once a Lua session (MM:539-550); the old words "original" and "new" read as the painting and the video, anything else as the painting (DS:93-100). Check. Lua (write the file, MM._wall = nil).
- **DK42.** The title video needs the game's video effects on; off, the painting stands in on the tube and the swatch (MM:604-617, DP:110-112); the swatch's frame moves only while the tube shows another desktop. Check. Lua (getCore option) or by hand.
- **DK43.** The patterns follow the game's Color of Highlighted Container at the middle tone, re-toned when it changes (DS:161-179); Accent is the accent's Dark value in Light and High contrast too (DS:189-197). Check across themes and accents. Lua.
- **DK44.** The Desktop window's height is cut to the tube with no scroll (DP:142-144) while its groups always draw in full (DP:161-177): with Large text or a short tube the last rows run under the band. Bug (small screens). Lua (text size, read the last swatch's y against the band's).
- **DK45.** Done, Escape, Return and the close box always land on the main window (DP:47-50, 202-205), even when the Desktop window was opened from the bare desktop's menu bar. Director (low). Lua.

**Credits and Terms**
- **DK46.** The credits lines are read once a session (CR:85, 144): change the language and reopen, the old words stay. Check. Lua.
- **DK47.** The transport: << and >> are toggles (a second press plays), the roll stops paused at the end and rewinds to the top then plays (CR:92-101, 160-167); the wheel rolls it from anywhere on the desk (CR:257-263). Pad mapping differs from the game's (A pause, not close; CR:222-233 vs CS:107-118). Check and director. Lua.
- **DK48.** On the desk the terms' Quit quits at once with no question (TM:103, TOS:118-120), the same as the game's, while every other quit on the desk asks (MM:1035-1041); Return accepts at once (TM:188-191) and Accept saves options.ini again (TOS:105-108). Director. Lua for Return; No Lua for Quit.
- **DK49.** The boot terms window takes no keys (ZeD_Window has no key handler, ORG:1788-1849; keyOther is reached only through MM.keyRelease, MM:3229): Escape and Return do nothing at boot; the pad lands on View terms (TM:75-79, 241). Check. No Lua (needs a terms change and a relaunch).
- **DK50.** View terms and View privacy open the Steam overlay or the browser (TOS:87-103). Do not press in an automated run. Check. No Lua.

**CletusWorks, Documents and Mail**
- **DK51.** A game started from the menu bar (File > Continue) does not pass MM.showView (MM:979-988), so the notepad's draft has only its timed write, at most every 1.5 s while dirty (NT:46, 850-863); the last second or so of typing can be lost, against "a game started from the menu bar loses nothing" (NT:23-26, DN:16-18). Bug (low). Lua (type, MM.act.continue stubbed, read ZeD_desk_draft.txt); No Lua for a real load.
- **DK52.** Every notepad question lands on Cancel; Save changes? then runs what was asked (New, Open, close) after Save or Discard; a failed Save closes the question and does nothing else (NT:820-846). Check. Lua (N.io).
- **DK53.** The caps: 24 notes ("full" on the 25th Save), 20,000 characters (the page-full line), 32-letter names, no "|" or control characters, names unique without case (DN:43-46, 121-137, 187-193, 213-216, NT:927-935). Check, with accented and CJK names round trip. Lua.
- **DK54.** Documents: a note deleted or renamed while it is open in CletusWorks (NT:715-716): the page becomes "not on the desktop" or takes the new name on return; Delete in Documents clears a draft for that note (DN:264-265). Check. Lua.
- **DK55.** Mail: reading an Inbox letter writes its box file at once (ML:164-169, MST:359-364); Put in Outbox's reasons (no box, Outbox full at 20, no To, subject too long, no text, too long) each grey the button with its words (ML:212-224, MST:37). Check. Lua (MS.io swapped).
- **DK56.** A letter being written lives only in memory: a game start or Reset Lua drops it (ML:98, 187-196); the notepad keeps a draft, Mail does not. Director. Lua.
- **DK57.** The pad's keyboard on the desk is two keyboards: the Notes, Documents and Mail fields open the game's OnScreenKeyboard (NT:62-75, OSK:653-670), the windows built on SV's typeIn open ZeD's pad keyboard (SV:128-147). Director (one keyboard) and check that B and RT come back to the desk from the game's. Lua (MM.forceGamepad); the keys need a real pad.

**Workshop uploader and description editor**
- **DK58.** Leaving the Workshop by the menu bar, an icon, the pad off the window's edge or the power button during an upload, then coming back: onShow sets busy to nil and reads the folders again (WS:120-131), so Steam's answer is dropped (WS:375-406 return when not busy), the change note is not cleared and Upload lights again for a second send. Bug. Lua (set busy = { stage = "send" }, MM.showView("main"), MM.showView("workshop"), call onUpdated); No Lua for a real upload.
- **DK59.** Unsaved Workshop edits are lost with no question when the view is left any way but Back (DK19): onShow rebuilds the items from getSteamWorkshopStagedItems and reloads the form (WS:120-138); the same for a description being edited (DE:188-205; only finish sets _fromEditor, WS:122). Bug. Lua.
- **DK60.** Pad A on the Workshop's Title and Change note focuses the field with no pad keyboard (WS:567-568); the description editor's cards too (DE:397, 400, 402). The other desk windows open a keyboard (NT:62-75, SV:131-147). Bug (pad). Lua (MM.forceGamepad; the typing needs a real pad).
- **DK61.** A folder whose workshop.txt has no ID always creates a new Workshop item (WS:358-364); the game asks "new item or existing item" and takes an ID (WSS:411-540, 554-697). On a new machine this can make a duplicate item. Director. No Lua (real Steam).
- **DK62.** The description's room is Steam's 8,000 less the lines the game adds (blank line, Workshop ID, a Mod ID and a Map Folder line each), with 6 more for a new item's ID (WS:144-162); over it, Upload greys with the count and the editor's count turns red (WS:306-313, DE:472-477). Check against a real submit length. Lua for the count; No Lua for Steam's answer.
- **DK63.** The preview: a preview.png added while the window is open is found within a few seconds (fresh spellings up to 120, WS:180-202); the size check accepts only square 256 or 512 (WS:681-688) but the game's 1000 KB rule (WS:680 comment) is not checked. Check. Lua (copy a file into a Workshop folder).
- **DK64.** ZeD_workshop.txt keeps the folder picked last and each folder's change note until Steam says it went up (WS:50-93, 263-269, 388-397); a note with lines starting "|" or "note " round trips (WS:62-66, 84). Check. Lua (write and read the file).
- **DK65.** The Workshop exists only with vanilla's workshopOption (Steam on or WSS.TEST, MS:511-519): no band button, no Settings row, no Mod Uploader icon in the no-Steam QA runs (MM:1122, 2381, DT:65-66), and Steam's events are registered only if Steam was on at load (WS:408-415). Check. Lua (read MainScreen.instance.workshopOption); No Lua for Steam.

**Lite, small screens, words and drift**
- **DK66.** Lite keeps the desk's right icons, the Trash joke, Desktop..., the wallpapers, the About block and the corkboard note, and drops only the left column and its menu rows (NT:582-587, 611); "if vanilla does it, so does Lite" (NT:582) would drop more. Director. Lua (ZeD setup's Style).
- **DK67.** Small screens: at 1280 x 720, 1280 x 800, 1366 x 768 and a Steam Deck, the main window and the desktop stay in the room (MM:299-307, 286-297), every other view leans in with the dip (MM:255-284, 316-332), the power button and the corkboard may be off screen while leaning (MM:80, 270-279), pop-ups stay on the tube (MM:1791-1799), the Continue card's lines cut cleanly (MM:2676-2696), Large text and UI scale 2. Check (DK21, DK30, DK44 are the suspects). Lua (screen size through the QA kit) or by hand.
- **DK68.** The corkboard note reads "V1.0" only for a version with no "-" (MM:462-469): "1.0.0" gives V1.0, "1.0.0-hotfix" gives DEV; each line is cut to 10 letters with no sign (MM:85, 519). Check for the Dec 1 build. Lua (MM.noteHeading).
- **DK69.** Hard-coded English on the desk: "Project Zomboid" (the icon and the window frame), "Zero Day OS", "40 MB", the Debug menu's "Debug", "Reset Lua" and "Scenarios" (DT:57, MM:1739, 2203, DT:592, MM:1096, 1131-1132); every UI_ZeD_ key the desk files use is in ZUI, the 25 desktops' names and notes included (checked by grep). Director (names) and check (other languages fall back to EN).
- **DK70.** Drift in comments: "Show note in the ZeD menu brings it back" (DT:366, no such row since Pasties), "one sticky note always on the desktop" (NT:3), DN's list naming ZeD_desk_sticky.txt as current (DN:9); EXTRAS hides versionBtn but SAFE_EXTRAS does not give it back (OMM:118 vs MM:2979; the game's render shows it again anyway, MS:772). Check (no behavior).
