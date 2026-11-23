# Handoff: Build to QA, the error box and the belt row (Nov 22 2026)

Merged in main at 0fb94f8ff (branch errbox, 2db43d57a). Code: `42/media/lua/client/ZeD/ZeD_ErrorBox.lua` (new),
`ZeD_Belt.lua`, `ZeD_MessagesWindow.lua`, `ZeD_Tutorial.lua`, `Settings.lua`, `ZeD_MainMenuOptionGroups.lua`. Sim:
`ZeDUI/tools/qa/error_box_sim.lua` (47 checks). Nothing below is seen in the game yet.

## What was built

- **The game's red box hidden** (Error Fixifier's trick): `E.postDraw` sets `setStencilRect(0,0,1,1)` on an off-screen
  ISUIElement's Java object, never cleared, as the last OnPostUIDraw handler (re-added at OnGameStart and on the first
  OnTick after). The clip is OFF (`E.hideWanted()` false) outside the in-game state, in safe mode, with the new
  "Error box" tick (screens row under Safe mode, `screenErrorBox`, default off = ZeD hides the box), while the game's
  FPS graph is up (`ISFPS.start`), with "Lock cursor to window" on and the offscreen UI off, and when
  `ZeD.ErrorBox.off = true` (a QA switch).
- **ZeD's notice in that corner** (`ZeD_ErrorNotice`, 38 units, 10 in from the bottom right edge): the paper note
  with the count badge; red only for ZeD's own errors, accent for notes, gray for other mods' or the game's errors
  (`B.lampTone`). Shows 6 s (`SHOW_MS`) after `E.arrivals()` rises, while anything is unread, while a Messages balloon
  is up, and while the pad is on it; shows and hides plainly. Hidden in safe mode and with no character. It stands left
  of the game's box when that box is given back, and left of the split-screen speed strip when it shows.
  `E.arrivals()`: each unread line counts 1, each error entry filed counts 1 more (from `M.readErrors`' count rise).
  Click: `E.press()` opens Messages. Messages' balloons come out of it (`W.noticeAnchor` uses `E.anchor` first).
- **The belt row:** bag button, one-icon gap, the belt, one-icon gap (where the note was), the speed keys, then chat
  and PvP on a server. The note is gone from the belt (its box, drawing, hint, click, pad and `B.noteAnchor`).
- **The speed keys** show always, watch or not, Full and Lite, never on a server (the director: "the same spot no
  matter what"). The driver (belt hidden, KISS #56) keeps a keys-only panel in the exact same spot
  (`keysOnly` / `_drawKeysOnly`). No watch draws speed keys now (simplewatch branch).
- **The buckle** (Full): a left click runs `ZeD_CharacterWindow.openTab(pn, "identity", true)` (the Info key's toggle):
  shut, opens on Info; on another tab, goes to Info; showing Info this click opened, closes. With ZeD's windows given
  back it toggles the game's own window on Info. Hover hint "Info" (`IGUI_XP_Info`). Not a pad stop. Lite: no buckle.
- **The bag menu** sets `ctx.zedKeepOrder = true` after `ISContextMenu.get` (order and own icons kept).

## The 11 in-game checks

1. Raise a Lua error in game with the default settings (offscreen UI ON): no red ERROR box, AND the whole UI still
   draws. This is the biggest risk: in offscreen mode the UI is copied to the screen after the box; if the clip is not
   reset before that copy, the whole UI would vanish. Repeat with offscreen UI OFF, and with "Lock cursor to window"
   on (the game's box should show then, and the pointer stays visible).
2. The main menu after an error: the game's box behaves as before there.
3. The Display FPS key: the graph shows (the red box may show while it is up).
4. Tick "Error box" under Safe mode: the game's box is back and ZeD's notice stands left of it. Full safe mode: no
   notice at all.
5. The notice: shows with a new error or note; gray badge for another mod's error, red for ZeD's own, accent for a
   note; stays while unread; hides about 6 s after all is read; a click opens Messages; balloons come out of it.
6. Pad: on the belt, Right past the last speed key lands on the notice (pad mark and hint), A opens Messages, Left goes
   back to the row, other directions or B leave.
7. Belt row in Full and Lite at 4K and the Deck: bag button, gap, belt, gap, speed keys; no note on the belt; keys shown
   with no watch; none on a server; chat and PvP after the keys on a server.
8. Driving: the five keys stay at the same screen spot and work; they don't overlap the dash. A passenger keeps the
   whole belt.
9. The buckle (Full): a click opens Info, a second click closes it; open on another tab, it switches to Info; "Info"
   on hover; nothing in Lite.
10. The tour's Guide step points at the corner notice.
11. Split screen: the notice sits left of the corner speed strip.

What the trick also hides (from IngameState.renderFrameUI and Core.EndFrameUI) and how it is handled: radio and TV
lines are drawn in the world before the UI (not affected; ZomboidRadio.render after it is debug text only); the FPS
graph (clip off while it is up); OnSleepingTick (vanilla draws nothing there; a mod drawing in it would be hidden);
ActiveMods.renderUI and JoypadManager.renderUI (debug options only; moodles, the game's controller focus and ZeD's pad
marks are UI elements drawn earlier); debug overlays (hidden while the trick is on; the Error box tick brings them
back); the game's own pointer under "Lock cursor to window" with offscreen UI off (clip off then); other mods'
OnPostUIDraw handlers added after the first tick would be clipped.

## Refits for QA's scripts (Build did not edit them)

- **rt_hud.lua** (about lines 318, 338, 798): uses the belt's `lamp` box (`S.boxIdx("lamp")`) and `Z.Belt.noteAnchor`.
  Use `ZeD.ErrorBox._note` (the notice panel), `ZeD.ErrorBox.anchor(0)` (where balloons come from) and
  `ZeD.ErrorBox.press()` (what a click does).
- **rt_tour.lua** (about line 282): looks for a `lamp` box. The Guide step now targets `ZeD.ErrorBox.rect()`.
- **vk4_belt.lua**: expects the speed keys left of the bag button and only with a watch, and reads the note. Now: the
  keys sit right of the belt, starting `B.ICON_GAP` past the belt's end, always (none on a server); no note box. Also
  (beltfix): `H.shownSet` should count `_containers[_viewedContainer or _activeContainer]` when `#_mcSelected == 0`,
  whatever `_mainVisible` is, as the window's draw does.
- **vk3_screen.lua**: the "speed keys beside the watch" check: the keys are at the belt's right end now.
- **zedqa_messages.lua** and other zedqa_* scripts that read the `lamp` box: the note is the corner notice
  (`ZeD.ErrorBox._note`, `ZeD.ErrorBox.press()`).
- **rt_lite.lua** (simplewatch): the Lite watch's `_hit` ids are exactly `alarmline fold`; no speed row on any watch.
- **zedqa_simple_watch.lua:146**: no watch worn gives no hits and width 0; `W.act("speedN")` still works.

## Open, for the director

- The dash still has its own Messages note (`ZeD_DashNote` in ZeD_MessagesWindow.lua), now a second notice beside the
  corner one.
- The full watch's SPEED and START pushers and the belt's mini watch's pushers still set the speed (they are the
  watch's own art); the split-view speed strip (ZeD_SplitSpeed.lua) still draws its own four buttons.
