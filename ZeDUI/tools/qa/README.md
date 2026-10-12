# ZeD QA bridge — how to run tests inside the game without a restart

Requires the game launched with `-debug` (Steam launch option). `42/media/lua/client/ZeD/QABridge.lua` arms itself at world load and polls two files in the Zomboid user folder's `Lua/` directory every 30 ticks:

- `Lua/zedqa.lua` — the script to run (plain Lua chunk, full game API, `print` goes to `console.txt` as `LOG : Lua`).
- `Lua/zedqa.go` — the trigger. Any change to its first line runs `zedqa.lua` once.

Workflow from a shell:

```bash
cp ZeDUI/tools/qa/suite_verbs.lua "$ZOMBOID/Lua/zedqa.lua" && date +%s > "$ZOMBOID/Lua/zedqa.go"
tr -d '\000' < "$ZOMBOID/console.txt" | grep ZEDQA
```

(`tr -d '\000'` because a second game instance once truncated the log under the first.) Both ZeD windows must be open (`i`, game unpaused) for window scripts; scripts call `setGameSpeed(1)` when paused. Scripts schedule follow-up checks with an `Events.OnTick` counter (`at(n, fn)` pattern) so one trigger covers a whole sequence of timed actions.

Scripts in this folder were all run and passed on stable 42.20.2 in S123 (see `ZeDUI/deltas/SESSION_123_DELTA.md`). Gamepad A/X cannot be resolved without a physical controller (`getJoypadData(0)` is nil), so scripts call element callbacks (`onActivate`, `onContextMenu`) directly, which is exactly what the FocusManager resolver calls.

| File | Covers |
|---|---|
| `suite_verbs.lua` | ItemCard header verbs through `_dispatchHeaderVerb`: UNEQUIP/EQUIP clothing, READ, EQUIP 2H weapon, EAT, DROP, TAKE + `_effectiveContext` after each |
| `suite_tabs.lua` | Walk every tab in both windows via the real strip click handlers; focusable census per tab |
| `suite_gamepad.lua` | Simulated D-pad through `Focus.dispatchJoypadDir`, row callbacks (card open / live-swap / close, context menu, B), stale-zone check after a mouse Loot switch |
| `suite_band.lua` | Progress Band: reading via the queue poll, cancel via the card, cooking on a real stove with the danger state |
| `suite_perf.lua` | ms/tick per tab + builder cost of the recipe lists |
