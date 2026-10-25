# MESSAGES_SPEC: other mods' pop-ups, caught and kept in one window

**Status:** APPROVED (director, Oct 24 2026: "notification center works for me"). Mockup `ZeDUI/mockups/zed_messages_v1.html` (picture `zed_messages_v1_window.png`).
**Asked for (director, Oct 24 2026, watching the 128-mod test run):** "Can we make a popup message catcher, and somehow fold those messages into a formatted notification center?"
**Why:** with a long mod list, several mods open a note at game start (Horse Mod's "not properly loaded" warning, Companion Dogs' "enabled on a save that already existed"). They cover the screen, pause the game and take the controller, one after another.
**Relation to other specs:** the prompts are ZeD's (HOOK_MAP row 28, `Overrides/Prompts.lua`, `ZeD_Prompt.lua`); the lamp is a belt box (HOOK_MAP rows 5 + 6, `ZeD_Belt.lua`); the toasts are the Visual Catalog's O12, the count its A12, the dots A14, the window frame its window frame.

## 1. What is caught (phase 1, this build)

1. **A note opened by another mod**: a pop-up with one answer (OK), built with the game's own classes: `ISModalDialog` (yesno false), `ISModalRichText` (yesno false), `ISCollapsableModalRichText` (Horse Mod's warning uses it). It goes into Messages and is **not** shown, unless that mod's "Show this mod's notes as pop-ups" is on.
2. **Who opened it:** the first Lua file on the call stack that belongs to another mod (`getCurrentCoroutine`, `getCallframeTop`, `getCoroutineCallframeStack`, `getFilenameOfCallframe`; the path names the mod folder, the mod's name comes from its mod.info). Opened by the game itself or by ZeD: never caught, shown as now.
3. **Questions are not caught:** Yes / No, a text box, Set Alarm and the rest ask at once, as ZeD prompts. After the answer, a copy goes into Messages ("ANSWERED: Yes").
4. **Errors:** the game's own error list (`getLuaDebuggerErrors`, `getLuaDebuggerErrorCount`), read every two seconds; each new error is filed under the mod named in its first `(MOD:...)` frame, ZeD's own included (honest: ZeD-GUI is listed when ZeD is the one). "Copy for a bug report" puts that mod's errors on the clipboard.
5. **Not caught:** ZeD's own prompts, the game's tutorial and death screens, halo text over the character.

## 2. Phase 2 (after this build, not in it)

- **Mod windows** that are notes in all but name (a mod's own panel with an OK button): a "Send to Messages" box in their title bar; ZeD then catches that mod's window every time.
- **News** windows that mods show at the main menu (changelog windows).

## 3. The window

- Title **Messages**, the ZeD window frame. Left: the sources, grouped **From mods** and **Errors**, a dot (unread accent / read hollow / error red) and a count. Right: the source's messages, newest first; each a card: kind tag (NOTE, ANSWERED, ERROR), the source, the game time it came, its text (rich text as the mod wrote it), and **the mod's own buttons**, which still run the mod's callbacks.
- Help line: "A mod's notes and errors land here instead of on top of the game. Questions still ask at once."
- Footer: "Show this mod's notes as pop-ups" (per mod, remembered), "Copy for a bug report" (errors), "Clear", "Mark all read" (primary).
- Opens from: **the paper note on the belt** (the map flyer's note without its pin, Oct 25 2026) (at the belt's right end; a count when something is new, red when an error is new), the ZeD wheel's **Messages** slice on a controller, the desk's ZeD menu.
- Controller: the window takes the pad like every ZeD window; D-pad between the source list, the cards' buttons and the footer; B closes.

## 4. Arrival

- A **toast** (O12) under the moodles for six seconds: `MOD | Horse Mod | a note`, `ERROR | Common Sense | 3 errors`. Click it: Messages opens on that source.
- The belt note's count goes up.
- Nothing pauses the game, nothing takes the controller.

## 5. Settings (ZeD setup, Messages)

- Catch other mods' notes (on).
- Show a toast when one arrives (on).
- Per mod: show as pop-ups (in the window's footer), kept in `Zomboid/Lua/ZeD_messages.txt`.
- Safe mode: nothing is caught, every pop-up is the game's.

## 6. As built (Oct 24 2026)

- **Kept:** `ISModalDialog` and `ISModalRichText` notes (they were already ZeD prompts, row 28) and `ISCollapsableModalRichText` notes (built as a ZeD prompt only when Messages keeps them; every other use stays vanilla's window). Each prompt carries `_zedSource`, the calling mod's name; `ZeD_Prompt:addToUIManager` files a kept note instead of showing it. A kept note's OK closes it quietly (no paused message, speed or pad focus to give back) and runs the mod's callback.
- **The pause:** a mod that pauses the game right after opening its note (Horse Mod calls `setGameSpeed(0)`) is undone three frames later, unless the pause menu is up.
- **Errors:** one error is several entries in `getLuaDebuggerErrors` (a separator, "dumping Lua stack trace", the exception, the stack dumps); the entry naming an Exception counts, the others go into its record. Named by the first `(MOD:...)` in it; none named: "Project Zomboid". Errors from before the game started stay in the game's log.
- **The note** (differs from the mockup, which showed it always): it is on the belt, last on the right, after the main hand (and a right-wrist watch; the hands swapped ends Oct 25 2026), only while Messages keeps anything, so a game with nothing kept looks as before. The count is the new ones; red when an error is new.
- **The toasts:** at the right of the screen, 150 units down, three at most, six seconds; one per mod (an error toast counts up while it shows).
- **The ZeD wheel:** a Messages slice after Action bar; "No messages." while nothing is kept.
- **Not in this build:** notes at the main menu (still shown), the desk's ZeD menu entry, mod windows (Send to Messages) and news windows (phase 2).
- **QA:** `zedqa_messages.lua` (in regression.txt, `expect=qaMessagesError` for its one error made on purpose); the 128-mod load check (`zedqa_modload_run.ps1`) lists what Messages kept.

## 7. Build notes (written before the build)

- `ZeD_Messages.lua`: the store (sources, messages, unread, per-mod pop-up list), the caller lookup, the error reader, the toast queue.
- `Overrides/Prompts.lua`: before a note is built for another mod, `ZeD.Messages.catch(...)`; a caught note returns a prompt object that is never shown (vanilla's contract: same fields) so the mod's code keeps working.
- `ZeD_MessagesWindow.lua`: the window (library molecules: title bar, list rows, cards, footer buttons).
- The belt: one more box, the lamp (drawn with the belt, hit-tested by it).
- QA `zedqa_messages.lua`: a note from a test source (the lookup takes `ZeD.Messages.qaSource`), a question, an error; the window, the buttons, the per-mod switch, the toast, the count.
