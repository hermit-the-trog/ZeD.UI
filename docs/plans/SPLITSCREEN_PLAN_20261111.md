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
