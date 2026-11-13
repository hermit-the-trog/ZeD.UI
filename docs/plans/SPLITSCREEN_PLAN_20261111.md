# Split-screen: ZeD's own windows for every local player (punch list 107)

Plan written Nov 11 2026 (read-only survey of `42/media/lua/client/ZeD`). The director wants it before Dec 1 2026.

## Where it stands

- One gate keeps player 2+ off ZeD's windows: `ZeD.windowsFor(pn)` (Atoms.lua:1685, true only for pn nil or 0), called
  at about 30 entry points (CharacterWindow 3832/3858/3902/7054/7097, WorldWindow 3371/5876/5898/6028, DpadWheels
  366/412/428/668/694, QuickWheel 208, Overrides WorldMap, Garment, CharacterInfo, Wheels, SPNCC).
- Already one per player, the pattern to copy: belts (`ZeD_Belt.lua:2653`, `B._huds[pn]`), dashes
  (`ZeD_Dashboard.lua:2354`, `D._instances[pn]`; the dash's pad controller is still player 1 only), the hint strip,
  moodles. Context menus (ContextMenu:987 uses `getPlayerScreen*(self.player)`), prompts (Prompt:69, :1461) and
  balloons are player-aware already.
- Not found: the "known-issues branch report" the punch list names. The nearest record is commit 5f599d03 and
  `ZeDUI/qa/CHECK_known_issues_20261107.md` section 2 (line 60: "Not done (needs the pad focus made per player first)").

## Inventory (client/ZeD)

| System | Player-1 assumption | Count / files |
|---|---|---|
| Windows | `_charWin` (CharacterWindow:58) and the World window's; no-argument `getWindow/isOpen/getObjectCard/close/getInstance()` | 132 calls in about 40 files (FocusManager 8, PaperMap 6, Organisms 4, Settings 4, WorldMap 4, DpadWheels 4) |
| Window sizing | `getCore():getScreenWidth/Height` (`fitCharToScreen`, CharacterWindow:214) | 110 reads (WorldWindow 13, CharacterWindow 12, Organisms 5, FormCard 5) |
| Drawer and tabs | `getSpecificPlayer(0)` | AnimalsTab 11, MechanicsTab 4 and InventoryRenderer 4 (fall back to `win._playerObj`), CraftingCore 1, CookingTab 1, KillTracker 3 |
| Drawer and tabs | module-level caches | Journal 5, Crafting 4, Building 4, Skills 2, Equipment 2 |
| Focus and pad input | FocusManager module-level locals (145-303); BumperChord 75-104 and `getJoypadData(0)` at :116; InputModeDetector 60-150 | 3 files; 405 `Focus.*` calls across 57 files stay, the state under them changes |
| Multiplayer account parts (`getPlayer()`) | Claims 18, MpLeftovers 6, Chat 6, Tickets/Admin about 20 | about 55 of 78 calls; probably fine (account or connection), check in game |
| Item cards | `getPlayer()` in ItemCardOrganism 2, ItemFactsPanel 1, InventoryRenderer 1 | 4 to fix |
| Main menu, desk, options, theme (`ZeD.currentSize`, Tokens.lua:910) | single player by nature | fine as is (MainMenu 12 screen-size reads) |

## Architecture

- **Windows:** a map per window kind (`_charWins[pn]`, `_worldWins[pn]`); `getWindow(pn)` treats a missing pn as 0,
  so the 132 callers keep working until converted. Each window carries `win.playerNum` (already set at creation);
  code reads it with `ZeD.playerNumOf(w)` (Atoms:1673). Helpers take `win` or `pn`, never nothing.
- **Screen space:** `ZeD.playerRect(pn)` returns `getPlayerScreenLeft/Top/Width/Height(pn)`; fitting, opening,
  dragging and the drawer slide clamp to it; the width cap is half the player's width, not half the screen. Fit
  again when a player joins or leaves (player 1's rectangle shrinks when player 2 joins).
- **Input:** FocusManager keeps a state table per player (`_st[pn]`) and routes by `joypadData.player`; BumperChord
  and InputModeDetector keep state per joypad. Only player 0 has mouse and keyboard, so input mode for pn > 0 is pad.
- **Shared:** `ZeD.T`, the theme, the text size and the scale root (Scale.lua `computeGame`), since the game does
  not rescale for split-screen either; windows fit their rectangle instead. Layouts are already saved per player in
  the character's modData (CharacterWindow:176).

## Engine facts to check on 42.22 first (QA)

1. The `getPlayerScreen*` rectangles for 2, 3 and 4 players, and whether player 0's change when someone joins
   (`OnCreatePlayer`).
2. Whether `getJoypadData(n)` takes a player number or a pad index; how `JoypadState.players[pn+1].id` maps; whether
   player 0 can be on a pad while the mouse is idle.
3. Whether `setJoypadFocus(pn, panel)` and `onJoypadDown` on a focused panel get the right `joypadData.player`.
4. Whether one player's UIManager windows are clipped at another player's viewport (probably not).
5. Whether `getPlayerInventory(pn)` and `getPlayerLoot(pn)` exist for every local player, and whether player numbers
   are reused after a player dies or drops out.
6. In multiplayer split-screen: what `getPlayer()` returns; whether chat, tickets and claims belong to the connection
   or to each player.

## Stages (each ships on its own; player 1 behaves identically throughout)

| Stage | What | Files | Risk | Size |
|---|---|---|---|---|
| S0 | `ZeD.playerRect`, `getWindow(pn)`/`isOpen(pn)` with pn defaulting to 0, the window maps; gate unchanged | Atoms, CharacterWindow, WorldWindow | low | ~1 day |
| S1 | Focus, chord and input-mode state per player; gate still player 0 | Input/* (~3,000 lines) | high | 4-5 days |
| S2 | Per-player windows sized to their rectangle, behind a QA flag (`ZeD.splitWindows`, off by default) | CharacterWindow, WorldWindow, Organisms | medium | 3 days |
| S3 | Convert the 132 no-argument calls and 25 `getSpecificPlayer(0)` (not Settings, MainMenu, SafeMode); tab caches keyed by window | ~40 files, AnimalsTab heaviest | medium, mechanical | 4-5 days |
| S4 | Wheels, QuickWheel, PaperMap, WorldMap, Garment, CharacterInfo and the dash controller per player; `windowsFor` gates drop when the flag is on | Overrides/*, DpadWheels, QuickWheel | medium | 2-3 days |
| S5 | Flag on; QA at 2, 3 and 4 players and on the Deck | | | 2 days |

About 16-19 days; fits before Dec 1 if S1 starts this week. Each stage extends `ZeDUI/tools/qa/known_issues_sim.lua`
with stub pn 0/1 `getPlayerScreen*` (failing on the old code first) and runs the single-player pad regression plus
`CHECK_known_issues` section 2 steps 1-6.

## Risks and what waits

- Biggest risks: the FocusManager rewrite (one shared timer or latch left behind leaks one player's presses into the
  other's); half-screen windows at 4K 1.75x and on the Deck hitting minimum sizes (check the drawer at half width).
- Later: a theme or text size per player; multiplayer split-screen chat, tickets and admin parts; the debug console,
  Studio and the survival guide book (one window is enough); dragging items between players' windows; players 3 and 4
  beyond fitting their rectangle.

Critical files: Input/FocusManager.lua, ZeD_CharacterWindow.lua, ZeD_WorldWindow.lua, Atoms.lua, Organisms.lua.

## S0 as built (Nov 12 2026)

Player 1 behaves identically: every change below reads the whole screen at origin 0, 0 exactly as before, and the gate
`ZeD.windowsFor` (Atoms.lua:1708) is word for word as it was, so player 2+ still get the game's own windows.

### What S0 added

- `ZeD.playerRect(pn)` (Atoms.lua:1687): left, top, width, height of a local player's part of the screen from
  `getPlayerScreenLeft/Top/Width/Height(pn)`; pn nil is player 0; the whole screen when the game can't answer (a call
  that throws or is missing, a part with no width or height). Nothing calls it yet.
- `ZeD.screenOf(w)` (Organisms.lua:1350): the one helper the window code reads its screen through. Returns width,
  height, left, top (size first: most callers want only that, and it keeps the big functions from growing locals).
  `w` is the window, or the player number while the window is being built. S0 body: the whole screen, `0, 0`.
- The window maps: `_charWins[pn]` (ZeD_CharacterWindow.lua:61) and `_worldWins[pn]` (ZeD_WorldWindow.lua:1768)
  replace the single refs. Every window still sets `win.playerNum` at creation (CW:4055, WW:3461).
- An optional trailing `pn` (missing means 0) on: CW `getInstance` (67), `isOpen` (3940), `getWindow` (3953),
  `toggleColumn` (7399); WW `isOpen` (3319), `getWindow` (3331), `inReach` (3343), `isTabShowing` (5947),
  `closeObjectCard` (5982), `getObjectCard` (6014), `selectContainer` (6025, third argument), `close` (6137),
  `forceClose` (6147), `toggleColumn` (6186); `ZeD_Window.resetLayout(which, pn)` (Organisms.lua:1441). The 115
  no-argument calls in 42 files keep working unchanged.

### Every place S0 changed

| File:line | What |
|---|---|
| CW:61-69, 3940, 3953, 7399 | the map and its lookups |
| CW:3962-3966 | `openTab` reads its player's window |
| CW:4007-4017 | `toggle` closes its player's window |
| CW:4031-4047 | `toggle` opens through `ZeD.screenOf(playerNum)`; position `screenL + half - width - gap`, y `screenT` |
| CW:4056, 4084 | the new window goes in under its player; its close box clears only `_charWins[self.playerNum or 0]` |
| CW:7176-7219 | `toggleBothPaired` / `ensureBothOpenForGamepad` pass their `playerNum` to `isOpen` / `close` |
| CW:7229-7237 | death closes the dead player's own windows (`getWindow(pn)`, `close(pn)`) |
| CW:7315-7319 | safe mode closes player 0's (the only one that can open) |
| CW:7335, 7340 | resolution change and save run over every open window (`pairs`) |
| CW:7349 | the theme's saved accent stays player 0's |
| CW:224-242 `fitCharToScreen` | size, origin-aware clamp |
| CW:246-277 `applyCharState` | size, origin-aware clamps; fitInvW room is `anchor - screenL` |
| CW:354, 5859, 5970 | the half-screen cap fallback |
| CW:384-386 `getMcCapacity` | room to the right edge `screenL + screenW - x` |
| CW:408, 656 | multi-column width caps (size only) |
| CW:4824 | the drawer slide's width model (size only) |
| WW:1768, 3319, 3331, 3343, 5947-6030, 6137-6152, 6186 | the map and its lookups |
| WW:3413-3414 | `_closeWorldWindow` clears only its own player's entry |
| WW:3427-3428, 3441-3453, 3463 | `toggle`: close its player's, open through `ZeD.screenOf(playerNum)`, keep it under its player |
| WW:5941, 5959-5963, 6090-6102 | `open`, `openObjectCard`, `openTab` read their player's window |
| WW:6164, 6169, 6175 | save, resolution change, container update over every open window |
| WW:6217, 6269-6270 | the game's loot page hands off to player 0's window (the page is player 0's) |
| WW:2040, 3798 | the half-screen cap fallback |
| WW:2075 `settleCapPush` | size only |
| WW:2111, 2134, 2332 | multi-column room to the right edge, origin-aware |
| WW:2515-2527 `fitWorldToScreen`, 2531-2552 `applyWorldState` | size, origin-aware clamps; fitInvW room `screenL + screenW - x` |
| WW:4047, 4093 | the drawer slide (size only; the give-back room reuses the frame's `screenW`) |
| Organisms:1203 `_resizeStep` | the resize drag stops at `screenT + screenH` |
| Organisms:1363-1409 `resetChar` / `resetWorld` | the spread at `screenL + half`, y `screenT` |
| Organisms:1441-1468 `resetLayout` | `ZeD.screenOf(pn or 0)`, `getWindow(pn)` |
| ZeD_WindowPlaces:182-192 `goPlain` | size, origin-aware clamp |
| ZeD_WindowPlaces:205 `goPair` | the half-screen cap |
| WindowCurtain:358-359 `restore`, 401-404 `C.sync` | origin-aware clamps |
| WindowHalves:339 `snapShut` | size only |

### Proof that player 1 is unchanged

- Every sim that loads or cuts the window files, 51 of them, before and after: identical counts, 0 failed, except
  `fold_slide_sim` (41 -> 42: it now cuts the real `ZeD.screenOf` out of Organisms.lua, and its `getCore` stub
  gained `getScreenHeight`) and `known_issues_sim` (57 -> 88, the new S0 section). Two harnesses follow the new
  shapes with their checks untouched: `fold_slide_sim` (above) and `paper_map_sim` (126, 0 failed: it cuts
  `close(pn)` / `forceClose(pn)` and keeps the map `_worldWins`). `search_icon_sim` fails 1 both before and after
  (ZeD_ConsolePages.lua draws "/"; not S0).
- `known_issues_sim` S0 section: 31 checks (a two-player vertical split stubbed: `playerRect` per player, fallbacks,
  `screenOf` the whole screen for both, the window code reads the screen only through it, `getWindow()` is
  `getWindow(0)`, closing player 2's World window leaves player 1's, toggle keeps a new window under its player, the
  gate unchanged). On the old files 19 of them fail.
- A side-by-side run (not in the repo) of the old and new `fitCharToScreen`, `applyCharState`, both `getMcCapacity`,
  both multi-column targets, `fitWorldToScreen`, `applyWorldState`, `settleCapPush`, `goPlain`, `snapShut`, the
  curtain's `restore` and `sync`, and 25 frames of the Character drawer's width model on 4,000 random windows, screens
  (800x600 to 4K) and scales (0.75 to 2): 152,000 comparisons, every field identical. With a 7, 3 origin forced into
  `screenOf` the same run differs 26,694 times, so it does see the origin.
- `kahlua_guard.py` PASS; no new non-ASCII; no `next()`; declared locals rise by 2 or 3 at most per function (the
  two `toggle`s 50 -> 52 and 52 -> 54); the drawer-slide closures (85 and 70) and the main chunks are unchanged.

### Left for S2 (per-player windows behind `ZeD.splitWindows`)

- Organisms.lua:1350 `ZeD.screenOf`: with the flag on, return `ZeD.playerRect` (as width, height, left, top) for the
  Character and World windows. Read the player from `w.playerNum` (a number argument is the player itself), not
  `ZeD.playerNumOf`: the World window's restore (`applyWorldState`, WW:3472) runs before `win._playerObj` is set
  (WW:3489). Every other ZeD window (guide, Messages, Studio, console, plain `goPlain` places) keeps the whole screen.
- The engine's own pins at the whole screen's left edge, which a player's part does not have: CW:4856 and CW:4903
  (`if newX < 0`), WindowHalves.lua:351 (`if x < 0`). The right-edge rooms read size only: WW:2075, WW:4058
  (`screenW - win:getX()`), WW:4093, CW:4835. Clamp these to the player's part.
- Refit on a player joining or leaving (player 1's part shrinks): today `fitCharToScreen` / `fitWorldToScreen` run on
  `OnResolutionChange` only (CW:7335, WW:6169); add `OnCreatePlayer` and the player's removal.
- `_floorContainer` (WW:1796) is one for the module; any World window's close clears it.
- `ZeD_Window:pairKey` (Organisms:1471-1474) knows a window as "char" or "world" only by player 0's `getWindow()`;
  another player's pair would get no window menu resets until it asks `getWindow(self.playerNum)`.
- Player 0 only, by design until S4: `_hideVanilla` (CW:3899), `_closeForSafeMode` (CW:7313) and `forceClose()`'s
  default, the respawn layout carry `ZeD._winStateCarry` (CW:7249, 7263), the vanilla-page hiding retry (CW:7388), the
  loot-page watch (WW:6214, 6238, 6247).
- `ZeD_Modal.show` (Organisms:2222) covers the whole screen, every player's part; decide before the flag goes on.

### Left for S3 (callers)

- The 115 no-argument `getWindow/isOpen/getObjectCard/close/getInstance` calls (42 files) and 47
  `getSpecificPlayer(0)` outside Settings, MainMenu and SafeMode.
- `resetLayout` callers pass no pn: Organisms:1502 (`resetWindow`, has `self`), ZeD_DpadWheels:598,
  ZeD_WindowMenu:224.
- The loops over `{ CW.getWindow, WW.getWindow }` called with no player: Organisms:181, WindowCurtain:60 and 430,
  WindowHalves:584; Settings:1051 (`setWindowAccent`).
- The new optional `pn` arguments, unused so far: InventoryRenderer:2796 (`inReach`), FishingTab:1108 and
  FurnitureTab:279 (`isTabShowing`), MechTrailer:423, ObjectCardLaundry:153, ObjectCardLock:171 (`selectContainer`),
  ObjectCardHutch:132 (`closeObjectCard`).

## S1 as built (Nov 12 2026)

Player 1 behaves identically: every press, hold, repeat, chord, mode switch and log line of player 1 is the one from
before (the golden run below, 186 lines, word for word), and the gate `ZeD.windowsFor` (Atoms.lua:1708) is untouched,
so players 2-4 still get the game's own windows. What changed is underneath: focus, chord and input-mode state are kept
per local player and every press is worked on the record of the player it belongs to, so player 2's pad no longer
reaches player 1's focus, holds, chord or input mode. Built on main at `feed35cbd` (the chord directions as swapped in
`3f1b86412`: Hold LB + tap RB zooms in, Hold RB + tap LB zooms out). `Input/RunSneak.lua` is not on main; nothing here
touches it.

### What S1 added

- FocusManager keeps one record a local player, `_st[pn]` (FocusManager.lua:188-210, `Focus._st` for QA and the
  sims): the focused window, the D-pad repeat, the Y / A / X holds, the unfocused Y's last level, the aiming latch and
  grace, the focus marks, QA's held buttons (`qa`, `qaN`) and `away`. Player 1's record is made at load and never
  replaced (`_st0`, :210). Whose a press or call is: `_pnOf(w, joypadData)` (:255), the pad's `joypadData.player`, else
  the window's `w.playerNum`, else player 1. No "current player" variable: the player number or the record travels as
  an argument.
- New FocusManager helpers: `_who(pn)` (:263, "" for player 1 so the logs read as before, " (player N)" for the
  others), `_modeOf(pn)` (:269), `_ownsWindows(pn)` (:278, player 1 always; the others by `ZeD.windowsFor`, read at
  call time), `_countOf` / `_lastOf` (:285, :292), `_pressPn` (:1821, drops a press from another player's pad),
  `_xDragMove` (:1360), `_dropHolds` (:2080), `_padOf` (:2092), `_resume` (:2104), `_aimMagSq` (:2238), `_tickPlayer`
  (:2263), `_playing` (:2354), `_forget` (:2414).
- Optional trailing `pn` (missing or not a number = player 1) on `Focus.getFocusedWindow`, `releaseFocus`,
  `cuesVisible`, `reclaimEngineFocus`, `openSide`, `qaButton`; `Chord.setEnabled`, `getState`, `isActive`;
  `Detector.getMode` (players 2-4: always "gamepad"). New `Detector.padOwner(i)` (InputModeDetector.lua:186): the local
  player on controller i, or nil; a pad in character creation for a new player counts as that player's already.
  `ZeD_FocusChanged` carries the player as its third argument.
- BumperChord keeps one chord record a player, `_rec[pn]` (BumperChord.lua:96), each read from that player's pad and
  zooming that player's view. Players 2-4 poll only while `ZeD.windowsFor(pn)` (false today) and they are playing.

### The critics' points (all twelve addressed)

1. A dead player's slot is not "playing": FocusManager (:2354) and BumperChord (:159) tick players 2-4 only while
   `JoypadState.players[pn+1].player == pn` and `getSpecificPlayer(pn)` is alive. A record that sat out (`away`) or
   was reset starts from the pad as it is: Y's last level seeded (`_resume`, :2104), the bumpers' too (`_seed`,
   BumperChord:145), so a button held through the post-death screen or `OnCreatePlayer` is no new press.
2. `Detector.padOwner` returns `CoopCharacterCreation.instance.playerIndex` for the creation pad (playerIndex not 0), so
   the mode and player 1's aim scan both skip a pad still in character creation.
3. A pad gone mid-hold (id -1 or `isControllerConnected(id)` false) drops the holds and the D-pad repeat without
   firing (`_padOf` + `_dropHolds`, :2092, :2080); the holds run with no pad only while QA's hook holds a button
   (`qaN > 0`).
4. `OnCreatePlayer(0)` drops player 1's holds and seeds Y (`_forget(0)` -> `_resume`), keeping the window, the marks
   and `qa`; BumperChord's `onSeatChanged(0)` (:383) resets the chord to IDLE with the bumpers seeded and keeps the kill
   switch. The load-time `OnCreatePlayer(0)` finds everything idle, so the golden run is unchanged.
5. Nothing depends on file order at a death: `unregisterWindow` (:431) neither hands focus on nor pushes the engine
   focus for a player 2-4 who is dead or gone, and `_forget` clears `aWin._gpPaint`. Checked with the Character
   window's death handler run first.
6. ZeD_QuickChords.lua:409-411 drops a pad's held chord buttons on `OnGamepadDisconnect`.
7. Re-baselined on `feed35cbd`; the golden run is taken on it, with the swapped zoom directions.
8. `ZeD_Window:_inUse` and `ZeD_Window:_footerPrompts` are added to the list for S3 below.
9. The quick chords' release reads the same key as the press, the controller's `joypadData.id`
   (ZeD_QuickChords.lua:396), so zedqa_quick_chords.lua's fake controller (no `id` of its own) pairs up as before.
10. BumperChord's new registrations and its players-2-4 loop are guarded (`Events.OnCreatePlayer` /
    `OnPlayerDeath` may be missing, `ZeD.windowsFor` and `JoypadState` are read guarded); coverage_bugs_sim (159) keeps
    its count and BumperChord stays free of the `%` operator.
11. inventory_filter_sim's FocusManager cut gets stand-ins of the new shape (`_st0`, `_st`, `_S`, `_pnOf`).
12. `Focus.liveZone` (:620) keeps player 1's fast path: one comparison against `_st0.win`, any other window one table
    read, no record made.

### Every place S1 changed

| File:line | What |
|---|---|
| FocusManager.lua:1-117 | header: the per-player record, the routing rule, the new signatures, the event's third argument |
| FocusManager.lua:150-210 | the state block: `_windowRegistry`, `A_HOLD_MS` / `X_HOLD_MS`, `_st`, `_S`, `_st0` (the 21 file locals gone) |
| FocusManager.lua:243-328 | `_pnOf`, `_who`, `_modeOf`, `_ownsWindows`, `_countOf`, `_lastOf`; `_pushEngineFocus(control, pn)`, `_maybeIgnoreAim(pn)`, `_setBumperChordEnabled(flag, pn)` |
| FocusManager.lua:370-406 | the marks: `_showCues(s)` (only player 1's moves the mouse anchor), `_hideCues(s)`, `_watchCueMouse` on `_st0`, `cuesVisible(pn)` |
| FocusManager.lua:418-552 | `registerWindow` (count of that player's windows), `unregisterWindow` (hand-off within the player, nothing pushed for a dead player 2-4), `claimFocus`, `releaseFocus(pn)`, `getFocusedWindow(pn)` |
| FocusManager.lua:620 | `liveZone` fast path |
| FocusManager.lua:731 | `reclaimEngineFocus(pn)` on that player's slot |
| FocusManager.lua:1095, 2476 | the F9 overlay and its render patch read `_st0.win` |
| FocusManager.lua:1171-1222 | `_focusWindow(side, pn)`, `openSide(side, pn)` |
| FocusManager.lua:1260, 1273 | `_handleBContextual(pn)`; `_windowThatWay` keeps to w's player |
| FocusManager.lua:1350, 1428, 1501, 1676 | the list and spatial log lines end with `_who` |
| FocusManager.lua:1360, 1684 | the X-hold drag and the painted run read w's player's record |
| FocusManager.lua:1699-1811 | `_hideAllWindows(reason, pn)`, `_closeAllWindows(pn)`, `_handleYTap(pn)`, `_handleYHold(pn)`: that player's windows only |
| FocusManager.lua:1821-1905 | `_pressPn`; `dispatchJoypadDown` on the press's player's record, another player's pad dropped |
| FocusManager.lua:1940 | `stopsMayWait`: another player's window never waits; player 1's marks from `_st0` |
| FocusManager.lua:2014 | `dispatchJoypadDir` the same; the wrong "initial press only" comment fixed (the engine repeats too) |
| FocusManager.lua:2064-2235 | `qaButton(name, down, pn)`, `_btnDown(name, jid, s)`, `_dropHolds`, `_padOf`, `_resume`, `_holdTicks(s, jid, pn)` (the unfocused Y opens the pair only where `_ownsWindows`) |
| FocusManager.lua:2238-2405 | `_aimMagSq`, `_tickPlayer` (the old `_onTick` step for step), `_playing`, the new `_onTick` (player 1, then 2-4 under pcall) |
| FocusManager.lua:2408-2451 | `_forget` on `OnCreatePlayer` / `OnPlayerDeath`; `_onModeChanged` hides `_st0`'s marks |
| BumperChord.lua:33-55 | header |
| BumperChord.lua:78-160 | `_rec` / `_C`, `_who`, `_padIdx(pn)`, `_seed`, `_playing` |
| BumperChord.lua:169-305 | `_transition(c, s)`, `_reset(c)`, `_fire(c, dir)` (`doZoomScroll(c.pn, dir)`), `_tickPad(c)` (the old machine on the record) |
| BumperChord.lua:307-366 | `onTick` (player 1, then 2-4 behind the gate), `setEnabled` / `getState` / `isActive` with pn |
| BumperChord.lua:371-431 | `onModeChanged` resets player 1's; `onSeatChanged`, guarded registrations |
| InputModeDetector.lua:18-29 | header |
| InputModeDetector.lua:186-224 | `padOwner`, `othersPad`; `anyGamepadActive` skips other players' pads |
| InputModeDetector.lua:312 | `getMode(pn)` |
| InputModeDetector.lua:415-427 | `onGamepadDisconnect` falls back to kbm when only other players' pads remain |
| ZeD_QuickChords.lua:343, 368-370, 394-401, 409-411 | `consumed` per pad, the focused-window test for the pressing player, the release keyed like the press, the disconnect drop |
| ZeD_ContextMenu.lua:164, ZeD_ContextList.lua:173 | `reclaimEngineFocus(self.player)` |
| ZeD_MpLeftovers.lua:241, MapsTab.lua:719 | `reclaimEngineFocus(pn)` |
| ZeD_Panel.lua:165-212 | the dash's five stubs gate on `getFocusedWindow(joypadData and joypadData.player)` |
| world_refresh_sim.lua:411-421, inventory_filter_sim.lua:552-555 | harness stand-ins for the new shape; checks untouched |
| known_issues_sim.lua:419 | the S1 section |

Leaks closed: player 2's stick, trigger or button flipping player 1 to the pad (and opening their pair); player 2's pad
keeping player 1 in pad mode after player 1's pad left; player 2 aiming rolling up player 1's windows; player 2
closing a menu pulling player 1's pad back; player 1's slot with id -1 reading player 2's Y; player 2's quick chord
swallowing player 1's release; any pad whose engine focus reached a ZeD window driving player 1's holds (now dropped in
`dispatchJoypad*` whatever the stub's gate says); player 1's focused window blocking player 2's quick chords.

### Proof that player 1 is unchanged

- known_issues_sim S1 section (66 checks): T1 runs player 1 alone through every pad feature (mouse first, the pad
  switching in, both Y taps, D-pad tap and held repeat, the hop to the World window, LB / RB, A tap, A hold with the
  painted run, X tap, X hold drag, B, the aiming escape, both zoom chords, the engine focus reclaimed, Y hold closing
  the pair, the mouse taking over) and compares player 1's 186 lines with GOLDEN, taken from the files before S1
  (`ZEDQA_S1_DUMP=1` prints the run). T2 adds player 2 on pad 2 doing everything a pad does (stick, trigger, buttons,
  aim, a quick chord held across player 1's Y release, a reclaim, LB+RB, the pad unplugged) and T3 gives player 2 ZeD
  windows of their own at the same moments (gate opened in the sim only): player 1's lines equal GOLDEN in both. On
  the old files 29 of the 54 checks that run there fail (the join-and-death game stops at its first harness step).
- Every sim, 111, before and after: identical counts and the same failures, except known_issues_sim (88 -> 154, the
  new section). `action_bar_name_sim` fails 1 before and after (not S1). Two harnesses follow the new shapes with their
  checks untouched: world_refresh_sim (9430) gains `_st0` / `_pnOf` stand-ins and its marks setter feeds both shapes
  (it still passes on the old FocusManager); inventory_filter_sim (127) gains `_st0`, `_st`, `_S`, `_pnOf`.
- `kahlua_guard.py` PASS, `i18n_guard.py` PASS, KCheck (the game Kahlua compiler, on the game JRE) parses all nine touched game files, no `next()`, no new non-ASCII (FocusManager 226 -> 220 high bytes,
  BumperChord 54 -> 48, the rest equal). Declared locals: FocusManager's main chunk 84 -> 81, `_handleSpatialNav`
  128 -> 128 (the drag check moved into `_xDragMove`), `_tickPlayer` 12, `_holdTicks` 16, `_aimMagSq` 16,
  `dispatchJoypadDown` 13, the new `_onTick` 9; BumperChord's main chunk 14 -> 16, `_tickPad` 9;
  InputModeDetector's main chunk 29 -> 30; QuickChords' `Q.onPress` 9 -> 10. Upvalues at most 16.

### Left for S2 (per-player windows behind `ZeD.splitWindows`)

- Organisms.lua:1726-1759, the window's five joypad stubs (a held file in this stage): gate on
  `ZeD.Input.Focus.getFocusedWindow(joypadData and joypadData.player) == self`, as ZeD_Panel's do. Until then player 2's
  presses never reach their own Character or World window (FocusManager already drops another player's press, so
  player 1 is safe either way). known_issues_sim's opened-gate games apply this change to their copy.
- The balloon slot is one for the game: player 2's B dismisses player 1's balloon (FocusManager.lua:1842).
- `ZeD_Modal.show` covers every player's part.
- Check in game that the post-death screen keeps its pad focus for players 2-4 when the windows' death handler closes
  their windows (FocusManager no longer pushes anything there).
- The dash heater (ZeD_Dashboard.lua `D.heater`) can claim player 2's dash: that now goes to player 2's slot, not
  player 1's.

### Left for S3 (callers)

- Player 1's mode, marks or focused window read for another player's surface, one argument each: `ZeD_Window:_inUse`
  (Organisms.lua:385, `getFocusedWindow(self.playerNum)` and `getMode(self.playerNum)`), `ZeD_Window:_footerPrompts`
  (Organisms.lua:919, the same), Overrides/ContextMenu.lua:53-60 and :92-115, ZeD_ContextList.lua:152-153 and 528-529,
  ZeD_Dashboard.lua:2155-2159 and 2198-2199, ZeD_FocusPaint.lua:230-238, ZeD_Belt.lua:1604, ZeD_Reader.lua:722.
- MapsTab's pad tick (`_mapPadTick`), RadioTab's `getJoypadData(0)`, MapsTab's pop-out with no `playerNum` (reads as
  player 1).
- ZeD_Keyboard.lua:538 and :541 read `isJoypadLT/RTPressed(jd.id)` with an id that can be -1 (any pad).

### Left for S4

- Open the gate. The unfocused Y and the zoom chord of players 2-4 already wait on it and need nothing more.
- The wheel and belt routes still name player 1: ZeD_DpadWheels.lua:366-371, ZeD_WheelGesture.lua:317-319 (pass the
  wheel's player to `Focus.openSide(side, pn)`), ZeD_Belt.lua:2487-2490, ModSupport/SPNCC.lua:1190-1207,
  WorldRoutes.lua:90; the dash's pad controller is player 1's (ZeD_Dashboard `canTakePad`).
- Rewrite the comment above `ZeD.windowsFor` (Atoms.lua:1701-1707).
