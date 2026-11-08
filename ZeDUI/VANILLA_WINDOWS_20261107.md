# Vanilla windows still reachable with ZeD on (Build, Nov 7 2026)

The director: "anything that opens a vanilla window, we need to work on." Three independent code sweeps (ZeD side, game side, the ledger), merged and settled in the code. Not opened in game yet: QA takes the in-game pass. Nothing is built from this without the director's pick.

The three sweeps merge into 52 rows below: 35 vanilla windows a player can still reach with ZeD on, 6 that ZeD opens itself only when its own screen can't open, and 11 kept vanilla on purpose. I checked each point where the sweeps disagreed against the code. Nothing was changed and the game was not launched.

Paths starting `ZeD/` are under `C:/Users/danie/Zomboid/mods/ZeD-UI/42/media/lua/client/ZeD/`. Paths starting `vanilla/` are under `E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/`.

**Where the sweeps disagreed, settled in the code**
1. **Server buttons on the left edge of the screen.** The header at `ZeD/Overrides/ScreenIcons.lua:9-13` says they are left alone, but that comment is out of date. On a server, `ZeD/Overrides/Belt.lua:73` and `:257-262` hide the Safety, Client and Admin buttons every frame. So the game's user panel, admin panel and its tickets window can't be reached from ZeD's screens. Only the debug button stays, and only in debug runs.
2. **Advanced game sounds.** ZeD only draws the game's own button. The game creates that button only when its advanced sound options are switched on (`vanilla/client/OptionScreens/MainOptions.lua:2125`), so this one is rare.
3. **Paper map items, Read label, make-up, Check zone, admin Edit item, the controller join list and the controller disconnected window.** Only Sweep B found these. A search of ZeD's code finds no reference to any of them, so all are still vanilla.
4. **Left-click on a nearby TV or radio.** Confirmed at `vanilla/server/ISObjectClickHandler.lua:230-233`, which calls the game's radio window directly.
5. **Heater key.** Confirmed at `vanilla/client/Vehicles/ISUI/ISVehicleMenu.lua:1667-1668`. The key opens the heater window as well as the wheel slice does.
6. **Respawn after death.** Sweep A missed it. Confirmed at `ZeD/Overrides/PostDeath.lua:302`: ZeD's Restart calls the game's respawn, and nothing in ZeD touches the game's second set of character creation screens.
7. **Character window while paused.** Confirmed at `ZeD/ZeD_CharacterWindow.lua:6853` and `:6887`. ZeD steps aside whenever the game speed is 0.
8. **Animal info.** The ledger lists it as owned, but no ZeD code hooks it. The only match in ZeD is the action bar label at `ZeD/ZeD_ActionBar.lua:148`.

Sizes: small is a single card or footer swap, medium is a new card or tab view, large is a new full screen or several views.

---

## A. Main menu and new game

| # | Window | How it's reached | Vanilla class | Entry point (file:line) | ZeD size and approach | Director decision? |
|---|---|---|---|---|---|---|
| A1 | Server mod download on join | Joining a modded server whose Workshop mods you don't have | ServerWorkshopItemScreen | Game event OnServerWorkshopItems; no ZeD reference (`ZeD/ZeD_MainMenuJoin.lua` has nothing for it) | Medium. A ZeD Join sub-view: a list of mods with progress bars, and Cancel in the footer band. Keep the game's screen alive off-screen, the way Connecting is done now. | No |
| A2 | Steam invite and command-line connect pop-ups | Accepting a Steam invite, joining a friend, launching with a connect address | BootstrapConnectPopup, ServerConnectPopup | No ZeD reference | Small. Show it on ZeD's Connecting view, with Cancel in the footer. | No |
| A3 | World select (choosing a map group) | New Game > Sandbox > Next when map mods make more than one map group; Sandbox Back can land on it too | WorldSelect | `ZeD/ZeD_MainMenuSaves.lua:881` (hand-off to `NewGameScreen.clickPlay`); `ZeD/ZeD_MainMenuSandbox.lua:244`; vanilla `client/OptionScreens/NewGameScreen.lua:429` | Small to medium. A New Game step drawn like the save cards, one card per map group. | No |
| A4 | Terms of service | Desk menu bar > ZeD logo menu > Terms of service; also first run, or when the terms change | ISTermsOfServiceUI | `ZeD/ZeD_MainMenu.lua:965`, `:1016` | Small. A ZeD window with scrolling text and Accept in the footer. | No |
| A5 | Controller button map and controller test | Options > Controls > button map or test row | MainOptions controller page (ISControllerBindingsEditorPanel, ISControllerTestPanel) | `ZeD/ZeD_MainMenuOptions.lua:785-792` | Medium. A ZeD Options sub-page: a list of bindings plus a pad diagram for the live test. | Yes. The pad diagram look. |
| A6 | Advanced game sounds (rare) | Options > sound page > Advanced, only when the game's advanced sound options are on | ISGameSounds | `ZeD/ZeD_MainMenuOptions.lua:1323-1329`; vanilla `MainOptions.lua:2125` | Medium. A ZeD Options sub-page with a category list and volume sliders. Low priority. | No |
| A7 | Server settings editor for a server that runs other mods | Host > edit a server whose mod list reloads Lua | ServerSettingsScreen | `ZeD/ZeD_MainMenuServer.lua:52-56` | Not buildable as things stand: the game's Lua reload drops ZeD until Save or Cancel. A technical fallback that stays. | No |

## B. In game, everyday (most used first)

| # | Window | How it's reached | Vanilla class | Entry point (file:line) | ZeD size and approach | Director decision? |
|---|---|---|---|---|---|---|
| B1 | TV and radio Device Options | Right-click Device Options on a TV, house radio or carried radio; left-click a TV or radio within 1.5 tiles; the controller Interact prompt; the vehicle part menu; any car device part that isn't the radio | ISRadioWindow | vanilla `server/ISObjectClickHandler.lua:232`; `client/ISUI/ISRadioAndTvMenu.lua` (openTvPanel, openRadioPanel); `ISInventoryPaneContextMenu.lua:897`; `Vehicles/ISUI/ISVehiclePartMenu.lua:321`. ZeD covers only the open-on-equip (`ZeD/Overrides/RadioWindow.lua`) and the car radio part (`ZeD/Overrides/CarRadio.lua:29-37`) | Medium. One hook on `ISRadioWindow.activate` sending every route to the faces that already exist (`RadioTab.lua`, `RtvFace.lua`, `TwoWayFace.lua`), in a World window card. | Yes. The TV and house radio faces were requested from design and are still open (punch list item 2). |
| B2 | Paper map items (Check Map or Read Map on a map or stash map), with the map's own symbol tools and note pop-ups | Inventory right-click Check Map; double-click a map item | ISMap, ISMapWrapper (inside: ISWorldMapSymbols, ISTextBoxMap, ISMapSymbolDialog) | vanilla `shared/TimedActions/ISReadMapItem.lua:49`; no ZeD reference | Medium. Hook the read action's open step and show ZeD's map on that item. MapsTab and MapNotes already hold the tools. | Yes. Should a paper map be a prop page (like the print reader) or ZeD's map view? |
| B3 | Respawn as a new character after death, and a split-screen second player (name, spawn, looks, occupation) | Death screen Restart; a second controller's "Add new player" | CoopCharacterCreation (CoopUserName, CoopMapSpawnSelect, CoopCharacterCreationMain, CoopCharacterCreationProfession) | `ZeD/Overrides/PostDeath.lua:302` (calls the game's respawn); a known issue in the beta 7 changenote, punch list item 97 | Large. Point ZeD's Looks, Traits and Spawn views at the second set of screens, shown inside the game world rather than on the desk. | Yes. Respawn layout in the world (no desk behind it). |
| B4 | Animal info | Right-click an animal > Info; the animal wheel's Info slice, reached from ZeD's own D-pad Animal wheel; the trailer and zone windows | ISAnimalUI | vanilla `client/ISUI/Animal/ISAnimalContextMenu.lua:982-984`, `:1222`; ZeD route `ZeD/ZeD_DpadWheels.lua:1063-1064`. No hook in ZeD | Small. Wrap the game's animal info function and its timed action, open the existing Animals tab view on that animal. Also fix the wrong ledger row. | No |
| B5 | Check zone on a livestock zone, and its first-time note | Right-click inside a designated zone > Check zone | ISDesignationZoneAnimalZoneUI, ISAnimalZoneFirstInfo | vanilla `ISAnimalContextMenu.lua:1068`; `ZeD/Overrides/Wheels.lua:247-264` covers only the panel toggle and the D-pad route | Small. Send it to the Animals tab's zone view, as those two routes already do. | No |
| B6 | Vehicle heater and air conditioning | Heater key; the vehicle wheel's Heater slice (from ZeD's D-pad Vehicle wheel and the V wheel) | ISVehicleACUI | vanilla `Vehicles/ISUI/ISVehicleMenu.lua:1143`, `:1667`; `ZeD/ZeD_DpadWheels.lua:1061` | Small. Wrap the heater toggle so it sets the heater and shows ZeD's dash controls. | Yes. Ledger row 4 says the heater stays vanilla because the dash owns the controls, but the game's window still opens. Confirm the key and the slice should go to the dash. |
| B7 | Mini-map and its options panel | ZeD's own D-pad World wheel > Map > Toggle mini-map, Focus mini-map; the game's map wheel | ISMiniMapOuter, ISMiniMapTitleBar, ISMiniMapOptionsPanel | `ZeD/ZeD_DpadWheels.lua:1007-1008`; no ledger row | Medium. Either a ZeD mini-map frame (window chrome on the game's map drawing) or remove the slices. | Yes. Keep a mini-map in ZeD at all? |
| B8 | Read label on a CD or VHS tape | Inventory right-click Read label | ISMediaInfo | vanilla `ISInventoryPaneContextMenu.lua` (onMediaText); no ZeD reference, though ledger row 13 claims it | Small. A reader page or item card showing the label text. | No |
| B9 | Make-up | Inventory right-click on a make-up item | ISMakeUpUI | vanilla `ISInventoryPaneContextMenu.lua:4162` | Medium. A card with the avatar, a list of make-up spots, and Apply or Remove in the footer. | Yes. How the look is shown (avatar on the card or in the Character window). |
| B10 | Trading with another player | Right-click a player > Trade; accepting a trade request | ISTradingUI | vanilla `ISWorldObjectContextMenu.lua:861`, `ISTradingUI.lua:855`; ledger 18b says pass-through "for now" | Medium to large. A two-sided World window card (your offer and theirs), with Accept and Cancel in the footer. | Yes. Pass-through or build it? |
| B11 | Medical check of another player | Right-click a player > Medical Check | ISHealthPanel in a game window (ISMedicalCheckAction) | ledger row 17, no hook | Medium. Reuse HealthTab on the other player, in a World window card. | Yes. Ledger row 17 keeps it pass-through. |
| B12 | Controller join list (take over, add new player, add saved player) | Pressing a button on an unassigned controller in game | ISJoypadListBox | vanilla `client/JoyPad/JoyPadSetup.lua:380` | Small. A ZeD prompt with a list. | No |
| B13 | Controller disconnected | Unplugging a controller in game | ISJoypadDisconnectedUI | vanilla `JoyPadSetup.lua:1089` | Small. A ZeD note-style prompt. | No |
| B14 | The game's Character info window while the game is paused | Skills, Health, Info or Protection key while paused; the Back wheel Player Info while paused; a page another mod added that has no ZeD tab of the same name | ISCharacterInfoWindow | `ZeD/ZeD_CharacterWindow.lua:6853`, `:6887`; `ZeD/Overrides/CharacterInfo.lua:33-52`, `:103-118` | Small. Let the Character window open while paused (read-only), or do nothing until unpaused. A dead character can stay as it is. | Yes. Should ZeD open while paused? |
| B15 | Crafting stations other than benches, drying racks and stoves | Right-click or Interact on such an entity (modded only in 42.22) | ISEntityUI.OpenWindow, ISEntityWindow | `ZeD/Overrides/Stations.lua:71-84`; `ZeD/Stations.lua:56-68` | Medium. A general station card for unknown craft logic. Low priority, since only mods add these. | No |

## C. Multiplayer and admin (most used first)

| # | Window | How it's reached | Vanilla class | Entry point (file:line) | ZeD size and approach | Director decision? |
|---|---|---|---|---|---|---|
| C1 | Players list (scoreboard) | Pause window > Players; D-pad Up social wheel > Players | ISScoreboard | `ZeD/ZeD_MainMenu.lua:989`, `:2101`; `ZeD/ZeD_DpadWheels.lua:1567-1573` | Small to medium. A pause window sub-view listing players, reusing the Admin player rows. | No |
| C2 | Server options, read-only, for players | Character window > Server tab > See server options; Admin tab > More tools | ISServerOptions | `ZeD/ServerTab.lua:121-125` (button at `:166`); `ZeD/AdminTab.lua:88-89` | Small. A read-only card in the Server tab, a list of option and value rows. | No |
| C3 | Invite friends | Pause window > Invite (Steam co-op host) | InviteFriends | `ZeD/ZeD_MainMenu.lua:990`, `:2102` | Small. A pause sub-view with a friends list and Invite in the footer. | No |
| C4 | Server saving pop-up | Server starts saving | ISServerSavingMessage | Game event OnServerStartSaving; not caught by ZeD's prompt hook | Small. A ZeD note or a line in the ZeD status strip. | No |
| C5 | Map mark sharing | Maps tab on a server > right-click or X on your own mark > Sharing | ISWorldMapSharing | `ZeD/MapsTab.lua:701` (option at `:765-766`) | Small. A card in the map's drawer: share with faction, safehouse or everyone. | No |
| C6 | Another player's stats editor (add XP, traits, profession, names, warning points, logs), plus your own | Admin tab > Player card > Stats; a ticket or chat line's Player card on a server without ZeD's server part; More tools > Check your stats; the game's admin right-click Check Stats (not hooked) | ISPlayerStatsUI and its sub-windows | `ZeD/ZeD_AdminCards.lua:1283-1288`; `ZeD/ZeD_TicketCards.lua:1704-1721`; `ZeD/ZeD_Chat.lua:292-311`; `ZeD/AdminTab.lua:105-106`; vanilla `ISWorldObjectContextMenu.lua:877` | Large. Extend the Player card with sections for XP, traits and profession, edits as footer swaps, and route the right-click to it. | Yes. A scope call: the beta 6a outside review finding 2 asks for it. |
| C7 | Manage another player's inventory | Admin tab > Player card > Inventory row | ISPlayerStatsManageInvUI | `ZeD/ZeD_Admin.lua:409-419`; row at `ZeD/ZeD_AdminCards.lua:1289-1291` | Medium. Show the World window inventory view on that player, with Remove in the footer. | Bundles with C6 |
| C8 | Someone else's safehouse or faction (staff), with their add-player and tag pop-ups | Admin tab > Safehouses or Factions > a row that isn't yours; right-click View safehouse on someone else's | ISSafehouseUI, ISFactionUI (and their add-player and tag windows) | `ZeD/AdminTab.lua:71-85`; `ZeD/ZeD_ClaimCards.lua:1441-1454` | Small to medium. Open ZeD's own safehouse and faction cards on the other claim, with staff buttons. | Yes. Ledger 18b keeps this vanilla on purpose. Lift it? |
| C9 | Users list (accounts, passwords, whitelist, banned IPs and Steam IDs, suspicion and warning points) | Admin tab > More tools > See users | ISUsersList and its sub-windows | `ZeD/AdminTab.lua:102-104` (code comment: "until cards hold them") | Large. An Admin tab Users section: list cards, a ban list, password reset as a footer swap. | Yes. Scope. |
| C10 | PvP log tool | Admin tab > More tools; the Admin tab LOG row on a server without ZeD's server part | ISPVPLogToolUI | `ZeD/AdminTab.lua:92-93`; `ZeD/ZeD_LogCards.lua:513-530` | Medium. A log card using the existing log card style. | Yes. The ledger keeps it under More tools. |
| C11 | Server sandbox options (multiplayer) | Admin tab > More tools > Sandbox options | ISServerSandboxOptionsUI | `ZeD/AdminTab.lua:90-91` | Medium. Reuse ZeD's in-game sandbox window with a send-to-server step. | No |
| C12 | Climate control | Admin tab > More tools | ISAdminWeather | `ZeD/AdminTab.lua:107-108` | Medium. An admin card with sliders and Apply in the footer. | No |
| C13 | Server statistics | Admin tab > More tools | ISStatisticsUI | `ZeD/AdminTab.lua:100-101` | Small. A read-only stats card. | No |
| C14 | Zone editor, Non-PvP zones, Add safe zone | Admin tab > More tools (three rows) | ISMultiplayerZoneEditor, ISPvpZonePanel (with ISAddNonPvpZoneUI), ISAddSafeZoneUI | `ZeD/AdminTab.lua:94-99` | Large. A zone section on ZeD's map with drag-to-pick areas, like the livestock zone view. | Yes. Scope. |
| C15 | Admin Edit item | Admin inventory right-click Edit item | ISItemEditorUI | vanilla `ISInventoryPaneContextMenu.lua:3979` | Medium. An item card in edit mode with field rows and Apply in the footer. | No |
| C16 | Admin message pop-up | Any admin message other than ZeD's ticket note for staff, and ticket notes for observers and moderators | ISAdminMessage | `ZeD/ZeD_Tickets.lua:864-875`, `:881-883` | Small. A ZeD note. | No |
| C17 | Kicked or disconnected screen | Kicked from or losing a server | ISServerDisconnectUI (the reason text is drawn by the game's Java) | `ZeD/ZeD_CommunityCards.lua:976-990` | Small to medium. A ZeD desk screen with the reason and the appeal line, if the reason can be read from Lua. | Yes. The ledger keeps this vanilla on purpose. |
| C18 | War manager | The HUD war icon when the Server tab cannot open | ISWarManagerUI | `ZeD/ZeD_ClaimCards.lua:1462-1474` | None. A fallback; ZeD's wars card covers it. | No |
| C19 | The game's tickets, user panel and admin panel | No route from ZeD's screens (the buttons are hidden on a server; see point 1 at the top); only another mod could open them | ISTicketsUI, ISUserPanelUI, ISAdminPanelUI | `ZeD/Overrides/Belt.lua:73`, `:257-262` | None. Fix the out-of-date ScreenIcons comment. | No |

## D. Rare

| # | Window | How it's reached | Vanilla class | Entry point (file:line) | ZeD size and approach | Director decision? |
|---|---|---|---|---|---|---|
| D1 | The whole Tutorial | Desk > File > Tutorial | Tutorial game mode | `ZeD/ZeD_MainMenu.lua:958`, `:1022` | Not possible: the Tutorial loads no mods. | Yes. Keep the menu item, or label it as the game's? |
| D2 | This Is Your Life mod's poster stories | New Game with that mod > a poster story | CharacterCreationProfession, CharacterCreationMain | `ZeD/ModSupport/ThisIsYourLife.lua:217-229` | Hand-off on purpose, so that mod's own screens run. | No |
| D3 | Debug scenarios and debug windows (Modify Genome, animal behavior, butchering, vehicle debug, debug menu button) | Debug builds, debug or cheat right-click options | DebugScenarios, ISDebugMenu, ISAnimalGenomeUI and others | `ZeD/ZeD_MainMenu.lua:967-973`, `:1037`; vanilla `ISAnimalContextMenu.lua:516`, `:745` | None. Developer tools. The Genome right-click could go to the Animals tab section that already exists. | No |

## Fallbacks: game windows that open only when ZeD's own screen can't

These don't need new designs. Each one opens the game's window if ZeD's version fails or its parent window is closed.
- World map pop-out, when there is no World window: `ZeD/Overrides/WorldMap.lua:93-121`.
- Seats, lightbar, garment, print media, journal writing, padlock, placement, info cards, fluids, mechanics and trailer animals: see the override files Sweep A listed.
- Car device parts that aren't the radio (folded into B1).
- Invitation pop-ups when ZeD's note fails: `ZeD/ZeD_Claims.lua:760-821`.
- The new-ticket modal and the base prompts.

## Kept vanilla on purpose (no work)

- **Safe mode** and an automatic safe-mode trip: everything vanilla comes back (`ZeD/SafeMode.lua:94-170`). The "stepped aside" note is the game's own dialog by design (`ZeD/SafeMode.lua:207-225`).
- **The seven per-screen switches** (windows, belt, watch, dashboard, moodles, wheels, charinfo): `ZeD/Settings.lua:529-549`. The tooltip on the windows switch needs fixing. While that switch is on, ZeD's World window won't open, so every World window card falls back to the game's window, and invitations go vanilla too. The tooltip says only the inventory and loot windows change.
- **Moodles**: they stay vanilla by project rule. ZeD only places them and draws their hover text.
- **The game loading screen**: drawn by the game's Java and can't be replaced from Lua. ZeD adds the CRT switch-off before it.
- **The game's chat box**: it comes back only in safe mode (`ZeD/ZeD_DpadWheels.lua:1551-1557`).
- **Never reached in 42.22**: the emote wheel setup, the sleep dialog, the literature list, and the map's note pop-ups outside safe mode.

## HOOK_MAP corrections to make

- The "Animals" row under Owned today claims Animal info, but nothing hooks it.
- Row 13 claims the CD and VHS label reader, but nothing hooks it.
- Row 4 doesn't say the heater window still opens.
- The radio row covers only the open-on-equip.
- The World map row's "key not yet captured" is out of date.
- Missing rows: paper map items, the second set of character creation screens, make-up, the two controller windows, the mini-map, the server mod download, the connect pop-ups, World select, server saving, Players and Invite, Terms of service, Edit item, Check zone, the More tools windows, server options from the Server tab, the controller and sounds hand-offs, and ZeD's chat.

## Director questions, in one place

1. The TV and house radio faces (B1).
2. A paper map as a prop page or as ZeD's map (B2).
3. The respawn layout without the desk behind it (B3).
4. Send the heater key and wheel slice to the dash (B6).
5. Keep a mini-map (B7).
6. How make-up is shown (B9).
7. Build trading or keep it vanilla (B10).
8. Build the medical check of another player or keep it vanilla (B11).
9. Should ZeD open while paused (B14).
10. Admin scope: player stats and inventory, other players' claims, users, PvP log and zones (C6 to C10, C14).
11. Should the kicked screen become ZeD's (C17).
12. What to do with the Tutorial menu item (D1).

## The director's decisions (Nov 7 2026, multiple choice)

- Start with everyday play (group B).
- B3 respawn after death: back to the desk; the next survivor is built in ZeD's own Looks, Traits and Spawn screens, as a new game.
- B2 paper map: opens ZeD's map view on the area that paper map shows, with ZeD's marking tools.
- B1 TV and house radio: every route opens ZeD's existing radio card now; the dedicated TV and house radio faces come when design draws them.
- Bans: when staff lift a ban with the game's own admin panel, the game's unban wins; ZeD closes its row and logs who did it.
- Mod support next: Auto-Hide Hotbar, Mask Filter Indicator, Item Condition Restored, the Better Item Transfer menu-style fix, Clear Skill Sheet, Better Folders, Better Mod Experience.

## More of the director's decisions (Nov 7 2026, evening; multiple choice)

- B6 heater and air conditioning: the key and the wheel slice go to the dash's own climate controls.
- B7 mini-map: removed from ZeD's wheels; the World window's map is the map.
- B10 trading and B11 the medical check of another player: build both as World window cards.
- B14 paused: the Character window opens while paused, read-only (actions grayed until unpaused).
- B9 make-up: a card with the character's 3D figure, the make-up spots as a list, Apply or Remove in the footer.
- C6 to C14 admin tools: all of them become ZeD cards (player stats and inventory, other players' claims, the users list, PvP log, zones, weather, server stats, server sandbox options).
- C17 kicked or disconnected: ZeD's desk screen with the reason and, for a ban, the appeal line.
- D1 Tutorial: kept on the desk menu, labeled as the game's own, without mods.
- Release plan: no upload Nov 7; the next upload by noon Nov 8, packed with as much as can be fixed; full release Dec 1 2026.
