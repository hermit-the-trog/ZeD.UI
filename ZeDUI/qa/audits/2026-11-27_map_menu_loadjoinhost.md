# Load, Join and Host: map for the gamut sweep (QA, Nov 27 2026)

A read-only map of the main menu's Load game, Join (the saved and public server lists, the server and account forms, the password questions, Connecting, the server's Workshop items, a Steam invite and the Connect to form) and Host (the co-op host screen and the server settings editor it opens, with its Mods, Map, Spawn Regions, spawn points, Steam Workshop and preset pages) against the game's own screens for the same jobs, written before the sweep scripts. Line refs are as read on Nov 27. Nothing was run.

**Every window here is a desk view over a vanilla screen that stays the engine.** Load is the "load" view (MM:2848, MM:2920); vanilla's LoadGameScreen is redirected (its setVisible(true) lands on the view, MM:2858-2872). Join is "join" over MultiplayerUI (redirected, JN:1212). Connecting ("connect"), Workshop items ("wsitems"), the invite ("bootstrap"), Connect to ("srvform") and Host ("host") are mirrors: the vanilla screen stays "visible" at x -20000 so it keeps following its events; the view follows its visibility (MM:2952-2968; JN:1213, JM:594-596, HO:376). Server settings is "srvset", redirected (SS:1257). No file here has a Lite branch (grep: none in SV, JN, JM, HO or SS).

Short names: SV ZeD_MainMenuSaves.lua, JN ZeD_MainMenuJoin.lua, JM ZeD_MainMenuJoinMore.lua, HO ZeD_MainMenuHost.lua, SS ZeD_MainMenuServer.lua, MM ZeD_MainMenu.lua, OMM Overrides/MainMenu.lua, BME ModSupport/BetterModExperience.lua, TR shared/ZeD/Tr.lua, ZUI shared/Translate/EN/UI.json (ZeD's words).
The game's files (media/lua/client): LGS OptionScreens/LoadGameScreen.lua, MPUI OptionScreens/MultiplayerUI.lua, CTS OptionScreens/ConnectToServer.lua, SCP OptionScreens/ServerConnectPopup.lua, BCP OptionScreens/BootstrapConnectPopup.lua, SWI OptionScreens/ServerWorkshopItemScreen.lua, COS OptionScreens/CoopOptionsScreen.lua, SSS OptionScreens/ServerSettingsScreen.lua, MS OptionScreens/MainScreen.lua, EA ISUI/ISMPEditAccount.lua, ES ISUI/ISMPEditServer.lua, EP ISUI/ISMPEnterPassword.lua, CUN OptionScreens/CoopUserName.lua, STB OptionScreens/ServerToolbox.lua, IF OptionScreens/InviteFriends.lua.

## 1. What it does

**Getting there:**
- The desk's big buttons: Load game (greyed with no saves), Join a server, Host a game (MM:2306-2311).
- The menu bar: File > Load game (MM:1113), Multiplayer > Join a server and Host a game (MM:1117-1118).
- MM.act.load needs saves and m.delay 0 (MM:999-1005); act.join only shows the view (MM:1006); act.host runs vanilla's aboutToShow and setVisible without vanilla's menu hide (MM:1007-1011).
- Any vanilla way back to Load (the mod list's return, a challenge's Back) lands on the view (MM:2846-2853).
- Server settings opens only from Host's Edit settings (HO:106-111 calls COS:352-359).
- An invite or +connect launch shows Bootstrap or Connect to (MS:2056-2075, BCP:58-93); a server with Workshop mods missing shows Workshop items (SWI:154-171, Steam only, MS:164-172).
- The menu bar stays live in every view (MM:1636, the bar is in MM.pointer's list; MM.menuItems has no busy guard, MM:1102-1119).
- Safe mode: MM.root goes (OMM:122-129), the redirects and mirrors pass every call to vanilla (MM:2862, MM:2955) and a mirrored screen parked off the screen comes back (OMM:150-154).

**Load game (ZeD_MMLoad, SV:188-894):**
- Data: readSaves on every open (SV:216-235, onShow SV:288-299): getFullSaveDirectoryTable, getSaveInfo for each (a save whose info throws or is not a table is left out, SV:220-221), getLastPlayedDate shown as "Oct 14 2026, 7:52 PM" (MM:839-850); the character is player 1 (sqlID 1) if alive, else the first alive one, else the first; s.dead is info.playerAlive == false (SV:238-250).
- Title "Project Zomboid  +  Load game" with "n saves" (SV:523-525, ZUI:2476-2487).
- Left, the list (43 percent, SV:35): "Find:" field (SV:590-601), then the saves grouped under mode heads (the game's IGUI_Gametime_ words, MM:803-806) in the order each mode first appears, with counts; a head folds by mouse (SV:619-631). A row: thumbnail (thumb.png, SV:645-651), the character's name (a red square and "<name>, dead" when dead, SV:661-666, ZUI:2484), then "<save title> | <map>" (SV:667-668). A date-named save reads "<Mode>, <Mon> <D>", a _crash copy adds "(crash)" (MM:810-820). The map is the first map or "Knox Country" when the list holds Muldraugh (MM:824-828).
- Find matches title, save name, character, mode word and map, any case (SV:254-258).
- Right, the preview (SV:699-814): the picture cropped to a band, the character large, the save title under it, then Mode, Map, Played, Mods (names; "n not found" when only missing ones; "None"), Version (the world version number), PLAYING AS (a drop box, only with more than one choice, SV:783-796), then red-square notes: "Save cannot be loaded" with the reason and "Mods not found: ..." (SV:797-813). No scroll; lines past the box are cut (SV:807).
- What may be played (whyNot SV:304-319, wrapped by BME:227-238): no version or map, version 0 corrupt, newer than the game, 200 or older, a map not found (vanilla's checkMapsAvailable, cached on the row), a dead CDDA character.
- The band (SV:539-567): Back | Delete, More, Play. Delete asks in the band ("Delete <title>? It cannot be undone.", Cancel first, ZUI:2474); More is a pop-up: Rename file..., New player (greyed for CDDA), Choose mods, then Open file location when the desktop supports it (SV:450-463). Rename puts a field in the band with the name preselected; Rename greys while the name is invalid, taken or the same (SV:549-560, 382-394).
- Verbs: Play (MainScreen.continueLatestSave, SV:329-334); a click picks, a second click within 450 ms plays (SV:685-697); Delete (deleteSave on the save the question opened on, then Continue and Load kept in step, New game when none are left, SV:349-372); Rename (renameSavefile, the save kept chosen, Continue refreshed when it was the latest, SV:407-420); New player (setSavefilePlayer1 -1 then Play, SV:423-428); Choose mods (the mod manager for this save, back to Load, SV:431-443); Open file location (showFolderInDesktop, SV:445-448); Playing as (setSavefilePlayer1 with the sqlID, info re-read, SV:484-489).
- A question freezes the rows, the folds, Find and up or down (SV:598, 628, 686, 821; QA B6-1, beast W51).
- Keys: Return plays (renames, deletes under a question), Delete asks, Up and Down walk, Escape leaves the field, then the question, then Load (SV:852-882). The wheel scrolls the list (SV:887-894).

**Join (ZeD_MMJoin, JN:70-1058):**
- Engine: MultiplayerUI built at the menu (MS:708, created MPUI:319); opening Join refreshes its saved list and asks for the public list (JN:112-123). Its accountList and internetList are read every frame (JN:134-162); its sort runs from ZeD's prerender (JN:509).
- Title "Join a server" with "n saved servers" (JN:510-513, ZUI:1446-1451).
- Left: tabs Saved and Public; Streamer mode at the right (vanilla's tick: getCore():setOptionStreamerMode and saveOptions, JN:592-600, MPUI:383-386).
  - Saved: each server (a green square once it answered), its accounts under it with tree lines ("name  (First Last)", "n min played | last on ..."), "Add account...", then "Add server..." (JN:134-151, 728-782).
  - Public: "Find:" (into vanilla's filter, JN:125-131), six show filters wrapping (Same version, Empty, Full, Password, Whitelist, Modded, JN:62-65, 614-639), Name, Players and Ping heads (a click sorts, again reverses, JN:694-717), then the servers: name, players, ping, address, version and what it asks (JN:735-760). "No servers to show." when empty (JN:679-681).
- Right, the chosen server (JN:785-854): name, Address, Port, Players, Ping, Map, Version, Password and Whitelist (yes or no once it answered), Last wipe, the description (tags stripped), Mods.
- Forms replace the list (JN:863-917): Add or Edit server (Server name, IP or domain, Port 16261 by default, Server password masked) with red-square reasons under each (JN:411-418); Add or Edit account (Login, Password masked, "Leave it empty to keep the saved one." when one is saved, Remember password, Use Steam relay on Steam, vanilla's address warning) with reasons (too short, bad word, taken, no password for a new one, JN:420-437).
- The band (JN:921-999): Saved: Back | Edit, Remove, Add account... (a server); Edit, Delete (an account); Add server... (otherwise); Connect (an account or a server with exactly one). Public: Back | Refresh (with the wait, "Refresh (n)"), Save server or Remove, Connect. Forms: Cancel | Save (Connect for a public server's new account). Questions: Remove a server, Delete an account (Cancel first, JN:356, 949-960); a password ("Password for <name>:", a masked field in the band, Connect) and a server password (OK), each greyed while empty (JN:937-948).
- Verbs: pick (vanilla's onSelectInternetServer, its Steam details request, JN:171-183); connect (an account: setAccountUsed, the password question when not saved, else vanilla's connectToServer, JN:259-271; a typed password goes to ConnectToServer with doHash true, JN:274-286; a public server: its password first if locked and not saved, then the saved server's one account, the Saved tab on that server or a new account form that connects and is not kept, JN:224-256, 289-318); Save server (vanilla's addServerToAccountList, password first, JN:321-331); Remove (deleteServerToAccountList, JN:333-341); Delete account (JN:343-350); Save server form (updateServerToAccountList or addServerToAccountList, JN:440-460); Save account form (encryptPwd, remember, relay, authType 1, JN:463-499); Refresh (requestServerList, JN:203-208); Back (release the Steam request, resetLuaIfNeeded, JN:186-192).
- Keys and pad: Return connects or saves the form; Escape leaves the question, a field, then Join (JN:1027-1046). Pad: the D-pad picks rows, A on an account or public row connects (JN:667, 689-691), LB and RB switch tabs, Y refreshes on Public, B backs out (JN:1003-1025); every form field and the band's password field are pad stops (JN:105-109, 558-559, 935).

**Connecting (ZeD_MMConnect, JN:1063-1197):** mirrors ConnectToServer: the title, the server name (or its IP), "as <user>", the status with a square (blinking while it tries, red once it failed: not connecting and the button reads Back, JN:1127-1130), the owner's appeal line after a ban (as text, read once per try, JN:1141-1153), the authenticator code field and Send when the server asks (JN:1155-1167, 1176), vanilla's reminder text and Abort or Back (CTS:197-216). B and Escape back out (JN:1185-1186).

**Workshop items (ZeD_MMWsItems, JM:100-336):** each mod with its title (or its ID), size, state square (installed green, downloading the accent and blinking, error red) and while downloading a bar with "n of N MB" (JM:117-138, 213-251); vanilla's prompt or its error above (JM:141-145, 184-198). Band: Disconnect | Install (greyed until Steam has the details and once pressed, JM:256-268). Y installs, B or Escape disconnects, Return installs (JM:293-300). On success: back to Connecting when the join came from Join, else the view stays saying "Connecting" (JM:325-336).

**Steam invite (ZeD_MMBootstrap, JM:341-398):** "host : port" as the heading, a square (blinking while it asks) and vanilla's words; Cancel while asking (it clears vanilla's connecting flag), Back once it failed (JM:352-358, 380-383).

**Connect to (ZeD_MMSrvForm, JM:403-581):** "ip : port", Server password, Username, Password (filled from vanilla's fields, which setServer filled from the saved server on that address, JM:431-439, SCP:147-168), Use Steam relay on Steam; Connect greyed with "Username required" style reason while the name is empty (JM:441-445, 555-556). Connect copies the fields into vanilla's and presses its CONNECT (JM:448-458); Cancel presses its CANCEL (JM:460-466). A on a field opens the game's on-screen keyboard (JM:469-481).

**Host (ZeD_MMHost, HO:51-372):**
- Idle (HO:214-288): Account (a field outside Steam, the Steam name on Steam), Server settings (a pop-up of the settings files), Edit settings, Memory (a pop-up, 0.75 to 16 GB, COS:173-180), then The world: Reset, Delete world, Delete player (each greyed as vanilla's buttons are, HO:243-253). A question shows vanilla's whole explanation in the body and a short line in the band, Cancel first (HO:257-275, 327-339). What keeps Start back shows as a red-square line: a bad account name, checkServerName, vanilla's save-version text, BME's reasons (HO:139-147, BME:325-334).
- Starting (HO:289-317): the settings name, vanilla's status with a blinking square, the progress bar, the reset bar during a soft reset. Band: Back (greyed) | Abort, Start (greyed).
- Verbs (all vanilla's): Start (COS:494-547), Abort (COS:549-552), Back (COS:482-492), Edit settings (COS:352-359), Reset (onSoftResetStep2: a soft reset launch, COS:401-409), Delete world (deleteDatabase and the two folders, COS:432-446), Delete player (deletePlayerFromDatabase and the player folder, COS:468-480). Return starts (HO:365-370); Escape answers Cancel, leaves the field, then Back (HO:359-364).
- Pad: the combos, Edit settings and the world buttons are stops; the account field is a stop (A: ZeD's pad keyboard, HO:227); B cancels a question or backs out (HO:350-353).

**Server settings (ZeD_MMServer, SS:166-1254, on the Sandbox window's rows):**
- It follows whichever vanilla page is visible (mode SS:214-225): list (Page1: the settings files with their files beside them; New, Duplicate, Rename, Delete, Edit; a double click edits, SS:860-884, 1133-1140); new, duplicate, rename (a name field with vanilla's rules plus ZeD's: no \ / : * ? " < > | and not the same name; the files it makes, copies or becomes, SS:906-949); delete (the files that go, asked in the band, SS:951-961, 1146-1150); mods (the server's mods, Choose mods opens the mod manager in server mode, Next, SS:963-972, 1151-1154); edit (Page3: the pages list with Server and Sandbox heads, a Find across pages, rows from the Sandbox window, a dot on each changed row and "n changed" in the title, the INI Password row as stars, SS:266-415, 504-591); points (Page7: occupations and their points, SS:975-1053).
- The special pages (SS:704-830): Mods (read only); Map (order, Move up and Move down, Remove, Add installed, a folder typed then Return); Spawn Regions (name and file typed into the region, Add, Remove, Edit spawn points (only for a plain file ending spawnpoints.lua), the fixed spawn point); Steam Workshop (Remove, Add installed, an ID typed then Return, "not a Workshop ID" under it); Presets (the game's five and the player's own, Apply).
- Leaving the edit page with changes asks "Keep editing" or "Discard changes" (SS:1093, 1127-1132). Return edits on the list, saves on the edit and points pages, goes on elsewhere, never deletes (SS:1215-1228). Bumpers turn pages; B and Escape end a cell, a question, a field, then back (SS:1166-1213).
- The mods step's Next skips vanilla's Lua reload when ZeD is the only difference (SS:53-80); any other difference reloads and the editor is vanilla's until Save or Cancel reloads back (SSS:3086-3125, 4065-4100).

**Data written (under Zomboid, %USERPROFILE%\Zomboid):**
- Load: Saves\<mode>\<save> deleted (deleteSave) or renamed (renameSavefile); the save's player 1 set (setSavefilePlayer1: Playing as, New player); its mods.txt through the mod manager (Choose mods). latestSave.ini is read again (getLatestSave).
- Join: db\ServerList.db (db\ServerListSteam.db on Steam) for every saved server and account change (add, update and delete, plus updateAccountToAccountList with the last logon on each connect, JN:276-277); options.ini for Streamer mode.
- Host: Lua\host.ini on Back, Edit settings and Start (COS:574-580); Saves\Multiplayer\<server> and <server>_player removed by Delete world; the player's row and folder by Delete player; Server\<name>.ini and the rest of its files made at Start for a new name (COS:501-511).
- Server settings: Server\<name> plus each suffix getServerSettingsManager():getSuffixes() lists (SS:887-903) on Save, Duplicate, Rename and Delete; a region's spawn points file the moment its page is saved (SSS:3872-3880).

**Small screens:** Load's preview cuts its notes at the box's foot (SV:807); Join's list takes 56 percent and the public filters wrap to more lines (JN:40, 614-623); Connecting is 330 units, Bootstrap 330, Connect to 470, each set by placeOnTube with no clamp to the room (JN:1099-1100, JM:44, 364, 487, SV:167-183); Server settings' pages list is 210 units (SS:41); the points page and the Mods page set list heights with no floor (SS:1003, 727), the Map, Regions and Workshop pages floor at 90 (SS:735, 755, 803).

**Tests that touch it now:** zedqa_menu_audit.lua:63-74 and zedqa_menu_nav.lua:27-35 (open load, join, host, srvset, srvset New and Back), zedqa_menu_case.lua:22-23 (Load's More), zedqa_button_case_menu.lua:21 (button case on load, srvset, host, join), sb_menu.lua (every main-menu screen), bx_menu.lua:655-657 (Load and Join visits), vx_menu.lua:897-1027 (W51: Rename keeps the save it opened on). Not covered: delete or rename on a staged copy, Playing as, New player, the Join forms and questions, streamer mode, the invite and Connect to views, Host's questions and status, the server settings special pages, the pad on any of it, small screens.

## 2. What the game does for the same jobs

- **Load (LGS):** a search on the save name only (LGS:596-605); the list with a dead moodle icon (LGS:620-646); the info panel lists every map by its title with missing ones red, every mod with missing ones red, "no mods.txt" apart from "no mods", the world version against the game's (LGS:37-112); Config holds Choose mods, Player 1 (a pad-reachable combo), New player, Browse files, Rename and in debug a Delete selected files combo (LGS:173-269); Delete asks in a modal (LGS:709-716) and, with none left, goes to New game (LGS:764-769); Play hides the screen first (LGS:731-751); Up and Down wrap (LGS:986-1000); Escape backs and Return plays (LGS:943-952). ZeD lacks: the per-map and full mods lists, the version pair, the debug file delete, wrap-around.
- **Join (MPUI, EA, ES, EP):** the same lists, Edit, Delete and Connect buttons on each account row (MPUI:858-933); a public server already saved opens an account picker (ISMPSelectAccount, MPUI:1480-1489); a new account for a public server is not kept and asks for the password again on connect (EA:246-264, MPUI:834-843); an empty account password is allowed (EA:248-257); each password field has a show toggle (EA:212-215, ES:104-107, EP:51-54); in streamer mode the address and port fields are masked (ES:28, 38); the refresh label waits 5 s in debug but requestServerList still waits 60 s (MPUI:936, 1103-1115). ZeD lacks: the account picker, the show toggles, the masking.
- **Connecting (CTS):** the arrows animation, the server name or IP, the user; Abort calls backToSinglePlayer (CTS:197-201); OnConnected moves to map or spawn select or character creation (CTS:270-302).
- **Workshop items (SWI):** Install as A, Disconnect; on success it only hides itself, leaving the screen behind it hidden (SWI:242-244); an error before it shows fails the connection (SWI:228-238).
- **Invite (BCP, SCP, MS):** Back is disabled while Steam is asked (BCP:46); vanilla refuses an invite unless its main menu is up (MS:2061-2063); Connect to fills from the saved server, password included (SCP:150-168) and connects with doHash true (SCP:205-206).
- **Host (COS):** the same controls; questions as modals; the status line always drawn, the stop reason included (COS:260, 689); setting errors at Start are vanilla modals (COS:503-520, 528-533). ZeD keeps those modals (they are vanilla's own).
- **Server settings (SSS):** the same seven pages; the edit page's Find (SSS:2459); Page7 passes occupation names where B42 needs objects (ZeD replaces the lookup, SS:99-153); no ask on Cancel with changes (SSS:2929-2937).
- **Not on this surface:** CoopUserName is the split-screen co-op name prompt (CUN, reached from CoopCharacterCreation); InviteFriends is in game only (MS:200); ServerToolbox is not referenced anywhere (STB).

## 3. Gaps and risks (LJ1 to LJ70)

Staging tags: **[script]** a Lua script at the main menu can do it with no save loaded and nothing joined or started; **[stub]** only with in-memory stand-ins (a fake info table, a stubbed play or connect, a vanilla screen shown without its network call); **[copy]** on a staged copy of a save folder the script made; **[db]** writes the saved-server list (back up Zomboid\db\ServerList.db and remove what the script added); **[manual]** by hand (opens Explorer, resets Lua); **[no]** cannot be staged (loads a save, joins or starts a server or needs Steam).

**Ways in, leaving, safe mode**
- **LJ1.** Ways in: desk buttons, File and Multiplayer menus; Load greyed with no saves (MM:2306-2311, 1110-1118, 999-1005). Plain check. [script]
- **LJ2.** Leaving a busy view by the menu bar: the bar is live in every view and nothing stops File > Load game during Host's launch or Connecting (MM:1636, 1102-1119); the vanilla screen keeps running at x -20000 (MM:2961) and can still connect and load. Bug (likely). [script] for idle Host: read CoopOptionsScreen.instance:getIsVisible() and getX() after the switch; [no] for the launching case.
- **LJ3.** Invites mid-flow: vanilla refuses an invite unless its bottom panel shows (MS:2061-2063); ZeD shows the bottom panel on every view (MM:2903), so an invite lands over Load, Host or Connecting. Design call. [script] under -nosteam: MainScreen.onAcceptInvite("+connect 127.0.0.1:16261") with Load up, then Cancel.
- **LJ4.** Safe mode with Host open: the parked screen comes back on screen and vanilla's Host shows (OMM:150-154, MM:2955). Plain check. [script]

**Load**
- **LJ5.** The rows equal getFullSaveDirectoryTable, grouped by mode in first-seen order, counts on the heads, "n saves" in the title (SV:216-235, 253-279, 525). Plain check. [script]
- **LJ6.** A save whose getSaveInfo throws or is not a table is silently left out (SV:220-221), where vanilla lists it (LGS:449-463). Plain check. [stub] (wrap getSaveInfo to throw for one key)
- **LJ7.** Find matches title, save name, character, mode word and map (SV:257), vanilla only the save name (LGS:600); try the German mode word. Plain check. [script]
- **LJ8.** Find with a folded group: the pick moves to the first shown save; folds survive reopening Load (SV:197, 267, 273-278, 288-297). Plain check. [script]
- **LJ9.** A living name marked dead: with player 1 dead and another character alive, s.dead is true and s.who is the living one, so the row and preview read "<living name>, dead" (SV:240-249, 661-666, 731-736). Bug (likely). [stub] (fake info.players in loadWin.saves)
- **LJ10.** Playing as has no pad stop: the drop box is a mouse hit only (SV:790-794), vanilla's combo is a pad button (LGS:263). Bug. [stub] (two living players in memory; list the pad stops)
- **LJ11.** Playing as writes setSavefilePlayer1 and re-reads the info (SV:484-489); the preview and row update. Plain check. [copy]
- **LJ12.** New player on an unplayable save: setSavefilePlayer1(-1) runs, then play() refuses in silence, leaving the save set to a new character under the old preview (SV:423-428, 329-331); New player is not greyed for a whyNot reason (SV:454); vanilla refreshes the panel (LGS:390-401). Bug. [copy] with a missing map
- **LJ13.** Can't-load reasons and order match vanilla: no version, 0 corrupt, newer, 200 or older, map missing, dead CDDA (SV:304-319; LGS:895-919, 96-108). Plain check. [stub] (worldVersion and mapName values)
- **LJ14.** A missing map is not named and only the first map shows, or "Knox Country" when Muldraugh is in the list (SV:765, MM:824-828); vanilla lists each map, missing ones red (LGS:50-63). Design call. [stub]
- **LJ15.** Mods: one truncated line; no mods.txt and no mods both read "None" (SV:768-781, 801; LGS:67-90). Design call. [stub]
- **LJ16.** "Version" goes through ZeD.tr as a bare word, not a key, so it stays English when no such key exists (SV:782, TR:452). Bug (low). [script] in DE
- **LJ17.** Preview at 1280x720 and Large text: the can't-load note comes last and is the first line cut, with no scroll (SV:797-813). Design call. [stub] (an unplayable save in memory)
- **LJ18.** One click plays after a key move: _lastClick is not cleared by keys or pad, so a click within 450 ms of an earlier click lands as a double (SV:685-697, 876-878). Bug (low). [stub] (replace loadWin.play with a counter)
- **LJ19.** Delete: the band names the save it opened on, the pad lands on Cancel, Delete removes that folder only (SV:336-372, 512). Plain check. [copy]
- **LJ20.** Delete failing says nothing: pcall(deleteSave) with no line (SV:352). Plain check. [copy] (hold a file open in the copy) or [manual]
- **LJ21.** Last save deleted: act.newGame returns early while m.delay > 0 and the Load window keeps the gone row (SV:363-366, MM:991-993). Plain check. [no] (needs every real save gone)
- **LJ22.** After Delete or Rename, Continue matches getLatestSave; m.continueDisabled for a dead CDDA latest is never updated (SV:355-362, 415; MS:437-438). Plain check. [copy]
- **LJ23.** Rename: vanilla's validateSavefileName plus same-name refusal (SV:382-394; LGS:334-346); the renamed save stays chosen only if mode..getFileSeparator()..name matches the folder key's separator (SV:414). Plain check. [copy]
- **LJ24.** Rename with a pad: the band field has no fieldStop and focus lands on Cancel, so the pad keyboard never opens on it (SV:401-404, 512-513, 549-560); Join's band field has one (JN:935). Bug. [script] (open the field, read the stops, Cancel)
- **LJ25.** Rename's field and Join's password field have no click-to-focus hit (SV:549-560 against SV:597; JN:926-936 against JN:556): once a click lands elsewhere, a click on the field does nothing. Bug (suspected). [script] for Rename (open, click the band, click the field, Cancel)
- **LJ26.** Choose mods returns to Load with the mods re-read (SV:431-443, MM:2848); Accept writes the save's mods.txt. Plain check. [copy]
- **LJ27.** Open file location only when isDesktopOpenSupported, and it opens Explorer on that folder (SV:445-448, 457-461). Plain check. [manual]
- **LJ28.** Play calls continueLatestSave with Load still up (SV:329-334; LGS:731-751 hides first); the older-save conversion modal (MS:1199-1218) shows over the desk. Plain check. [no]
- **LJ29.** Pad: A plays, X asks delete, Y More, B back; up and down frozen under a question; no wrap at the ends (SV:819-849; LGS:986-1000 wraps). Plain check. [script] (pad emulation, never A on a row)
- **LJ30.** Mode heads fold by mouse only; no pad stop folds (SV:626-630). Design call. [script]
- **LJ31.** whyNot runs twice a frame (SV:541, 799) and BME adds S.errors to each (BME:227-238). Plain check (perf). [script]

**Join**
- **LJ32.** Opening Join refreshes the saved list and asks for the public one; under -nosteam the master list is fetched (JN:112-123; MPUI:949-961). Plain check. [script]
- **LJ33.** Remove and Delete follow the pick: the band reads the chosen row each frame (JN:949-960) and pick and joyDir have no question guard (JN:171-183, 1003-1013), so a click on another row while asking swaps what Remove removes; Load fixed the same (SV:339, 686, 821). Bug (likely). [db] (two throwaway saved servers)
- **LJ34.** Under the password question the rows stay live: a double click on another row connects it (JN:171-183, 937-942). Bug. [stub] (replace m.connectToServer and ConnectToServer.instance.connect with recorders)
- **LJ35.** Streamer mode: the server form's address and port are plain (JN:95, 381-382) where vanilla masks them (ES:28, 38); the invite view's heading prints host : port (JM:377-379), vanilla's shows no address. Bug. [script] (Add server form, no Save; Bootstrap under -nosteam with a Steam ID host, LJ52)
- **LJ36.** The pad can't reach: the Public filters, the sort heads, Streamer mode, Remember password and Use Steam relay (all mouse hits only, JN:563-574, 596-599, 631-635, 713-714, 900, 903). Bug. [script] (list the pad stops on Public and on the account form)
- **LJ37.** A new account must have a password (JN:435); vanilla allows none (EA:248-257). Design call. [script] (form only)
- **LJ38.** Edit account: an empty password keeps the saved one, Remember off clears it, authType set to 1 (JN:470-478; EA:228-245). Plain check. [db]
- **LJ39.** A public server's account form shows Remember password though the account is never kept (JN:254-256, 478, 487, 900). Design call. [script] (form only, Cancel)
- **LJ40.** A saved server with several accounts, from Public: Connect jumps to Saved with no picker and no word why; with none, the same (JN:244-253; MPUI:1480-1489). Design call. [db]
- **LJ41.** Pad A on a saved server only picks; a mouse double click connects when it has one account (JN:667, 689-691, 182, 230-233). Plain check. [db] with the connect stubbed
- **LJ42.** In debug the label counts 5 s and Refresh turns live, but requestServerList waits 60 s and the press does nothing (JN:211-215, 974; MPUI:936). Bug (vanilla's too). [script] in debug
- **LJ43.** Port: no range check, 16261 shown by default, 16262 as the save's fallback (JN:382, 416, 445; ES:33, 113). Plain check. [script] (form only)
- **LJ44.** Two saved servers on one address share the row key s:ip:port, so the pick and getServerFeatured land on the first (JN:59, 141, 165; MPUI:691-696). Plain check. [db]
- **LJ45.** getServerList() runs twice a frame (JN:512, 541); vanilla reads it on refresh only (MPUI:869). Plain check (perf). [script]
- **LJ46.** Details: Password and Whitelist "-" until the server answers, last wipe in days, tags stripped, mods listed (JN:785-854). Plain check. [stub] (a Server.new() with fields set, never connected)
- **LJ47.** A locked public server asks its password first, then saves or connects (JN:289-318, 321-331). Plain check. [stub] for the save path, [no] for connect

**Connecting, Workshop items, invite, Connect to**
- **LJ48.** Connecting: square blinking then red, Abort turns Back, the appeal line after a ban, B backs out to Join (JN:1095-1178, 1185). Plain check. [stub] (previousScreen = multiplayer, setVisible(true), OnConnectFailed with a message, no serverConnect)
- **LJ49.** The authenticator code field takes the keyboard when it shows and has no pad stop (JN:1155-1167); every other menu field has one (SV:153-163). Bug. [stub] (googleAuthPopup:setVisible(true) on the stubbed Connecting; never Send)
- **LJ50.** Abort while connecting calls backToSinglePlayer (CTS:197-201). Plain check. [no]
- **LJ51.** Workshop items: Steam only; after success from Host's path the view stays on "Connecting" with only Disconnect (JM:325-336, 187-188, 265-268); Disconnect chains back to Connecting then Join (JM:155-166; SWI:148-152; CTS:318-320). Plain check. [no] (draw only with a stub screen)
- **LJ52.** Invite: Cancel works while Steam is asked (vanilla disables it, BCP:46); the -nosteam Steam-ID case leaves connecting nil and draws the red square with Back (JM:380-382; BCP:80-86). Plain check. [script] BootstrapConnectPopup.instance:connect("76561197960287930", "16261", "")
- **LJ53.** Connect to fills Password from the saved server (a stored hash) and vanilla connects with doHash true (SCP:150-168, 205-206; JM:435-437), so a saved account's password fails. Plain check (vanilla's). [script] setServer then setVisible; read the fields, Cancel
- **LJ54.** Connect to's fields open the game's on-screen keyboard, not ZeD's pad keyboard the other fields use (JM:469-481; SV:131-146). Design call. [script]
- **LJ55.** Connect to is 470 units tall and placeOnTube does not clamp it; check 1280x720 and 1280x800 (JM:44, 487; SV:174-176). Plain check. [script]

**Host**
- **LJ56.** No stop reason: when the server stops, vanilla's status says why (COS:689) and vanilla always draws it (COS:260); ZeD's idle form never draws c.serverStatus (HO:214-288). Bug (likely). [stub] (set c.serverStatus at idle, read the window)
- **LJ57.** Folder paths break at a backslash-n: unescape turns any "\n" in the path into a line break (HO:40-49, 259-264); vanilla escapes the path for the reset prompt (COS:383). Bug. [script] (a settings name starting with n, setConfirm("deleteWorld"), read, Cancel)
- **LJ58.** Return starts the server (HO:365-370) and Reset launches it (HO:118, COS:401-409), while Reset's help says only "start the server's world over" (ZUI:3835); the body repeats the band's question (HO:259, ZUI:1274). Design call. [no]
- **LJ59.** Start's gate: account name outside Steam, checkServerName, vanilla's save-version text, BME's reasons (HO:139-147; BME:325-334; COS:278-317). Plain check. [script]
- **LJ60.** On Steam, Delete player names and deletes the hidden account entry's name, not the Steam name (HO:263; COS:273-276, 468-479, 566). Plain check (vanilla's). [no]
- **LJ61.** Back and Edit settings rewrite Lua\host.ini (COS:482-483, 352-353, 574-580). Plain check. [script]
- **LJ62.** The settings and memory pop-ups mark the chosen row with the guillemet and open scrolled to it; the 62 memory sizes scroll (HO:151-164; COS:173-180). Plain check. [script]

**Server settings**
- **LJ63.** The list shows each settings' files by checking serverFileExists for every suffix every frame (SS:887-903). Plain check (perf). [script]
- **LJ64.** Name rules: ZeD refuses \ / : * ? " < > | and the same name on top of vanilla's (SS:906-921; SSS:2202-2220). Plain check. [script] (type only, Back)
- **LJ65.** Mods step Next: ZeD-only difference skips the reload; any other resets Lua into vanilla's editor and back on Save or Cancel (SS:53-80; SSS:3086-3125, 2929-2951, 4065-4100). Plain check. [manual]
- **LJ66.** Edit: a dot on each changed row, "n changed" in the title, the discard question on Back, preset Apply counted (SS:349-372, 523-525, 1093, 825-826). Plain check. [script] on a throwaway settings name, deleted after
- **LJ67.** Return on the edit page saves every file at once with no ask (SS:1220-1224). Design call. [script] throwaway name
- **LJ68.** Spawn points Save writes its file at once, and the edit page's Cancel does not take it back (SS:1098; SSS:3872-3880). Design call. [script] throwaway name
- **LJ69.** At small heights the points page and the Mods page compute list heights with no floor and can go negative (SS:1003, 727); the Map, Regions and Workshop pages floor at 90 (SS:735, 755, 803). Bug (suspected). [script] at 1280x720, Large text
- **LJ70.** The INI Password row shows one star per character, so its length shows (SS:397-415). Design call. [script]

**FEATURE_MAP.md (ZeDUI/tools/qa/FEATURE_MAP.md) rows with stale refs:**
- Row 1231: ZeD_MMLoad:delete is SV:349 (askDelete SV:336; not 341), :rename SV:407 (not 391), :chooseMods SV:431 (not 415); :play SV:329 is right.
- Row 1232: ZeD_MMNewGame:next is SV:956 (not 932).
- Row 1241: says "main menu, Steam", but Host works outside Steam with its own account name (HO:217-228).
- Rows 1238, 1239, 1240 and 1242 are right (JN:224, 203, 440, 463, 1086; JM:147, 448; SS:229, 1040, 1056).
