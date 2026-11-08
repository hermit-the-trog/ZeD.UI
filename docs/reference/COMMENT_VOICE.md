# ZeD-UI — Comment Voice

How comments are written in this codebase. One voice, everywhere: plain words
that let someone opening their first mod follow along, with the why-not-just-what
that a veteran actually wants. The two readers share every comment — the first
sentence tells a newcomer what a thing is; the next tells an old hand why it is
this way and not the obvious way.

This guide governs `42/media/lua/**`. Code is never changed to match a comment;
comments describe the code as it stands.

---

## The voice

- Plain words, short sentences, present tense. Write like you'd explain it to a
  friend at the next desk, not like a changelog and not like a textbook.
- Say what a thing is for before how it works. "The pause before any hover box
  shows" beats "HINT_MS constant (450)".
- The why earns its keep. When code dodges an engine trap, took the long way
  around, or keeps an old name on purpose — say so, in one line. That line is
  the comment a veteran came for.
- No filler. Never "simply", "just", "note that", "basically", "in order to".
  No restating the line below ("-- set width to 200").
- Concrete over abstract. "Joining is the dial-in: the client says p_dial, the
  waiting mail comes down in batches" — that is the house style at its best.

## What gets a comment

- **Every file: a header.** First line is the repo path
  (`-- ZeD-UI/42/media/lua/client/ZeD/Foo.lua`), then a banner block
  (`-- ===...===`, match the file's existing banner width): what this file is,
  where it sits (client / server / shared; token, atom, molecule, organism,
  or override), and the one thing to know before touching it. Four to ten
  lines. A file that is mostly a generated data table says so and stops.
- **Sections:** keep the `-- === BANNER ===` style for the file's big parts.
- **Public functions:** `---` doc lines above anything another file calls.
  What it does, and arguments/returns in words where they aren't obvious.
  Internal helpers get `--` only where a reader gains something.
- **Tricky lines:** inline `--` where the code can't speak for itself — engine
  quirks, magic numbers, deliberate no-ops.
- **Not every line, not every function.** Explain each part; don't narrate.

## What leaves

Comments written for the dev log, not the reader. Translate the information
out of them; drop the bookkeeping:

- Session numbers, punch-list numbers, ticket numbers, chat dates, quotes with
  attribution. Keep the insight, lose the minutes.
  - Before: `-- (punch list 104; the director, Nov 7 2026: "email back then,
    you would dial in to connect")`
  - After: `-- The model is early-90s email: dial in, mail moves both ways,
    hang up, read offline.`
- References to internal docs or past prototypes ("all 7 proven layers from
  TestInventory") — say what the layers do instead.
- Dead comments: commented-out code nobody will revive, stale notes that
  contradict the code. A stale comment is rewritten to match what the code
  does now; the discrepancy gets reported, not immortalized.

## What stays

- **Engine-version notes.** `B42.17 removed isJoypadPressed; JoypadButton:isDown
  replaces it` is exactly the kind of fact both audiences need. Keep build
  numbers; they are facts about the game, not bookkeeping.
- **Real TODO/FIXME**, rephrased plainly, no names or dates.
- **ASCII diagrams and layout sketches** — redraw only if wrong.
- The file's existing punctuation habits (em-dashes and arrows are fine; keep
  pure-ASCII files pure ASCII — shared/server files say so in their headers).

## House phrasings

Recurring idioms get the same explanation everywhere, worded once:

| Pattern | The line to use (adapt lightly) |
|---|---|
| `ZeD = ZeD or {}` | Reload-safe: loading this file twice reuses the table instead of wiping it. |
| pcall around Java calls | The game's Java side can throw; pcall turns a crash into a nil we can test. |
| reading `ZeD.T` in prerender | Read the palette fresh every frame, so a theme change shows up instantly — nothing is cached. |
| `prerender` / `render` | Runs every frame just before (prerender) or after (render) children draw. |
| client / server / shared | client: only on a player's machine. server: only on a dedicated server. shared: loads on both, so nothing client-only at file scope. |
| Overrides keeping `_zedOrig*` | Keep the vanilla function once, so a Lua reload never wraps the wrapper. |
| Atom / Molecule / Organism | Smallest draw helpers / reusable blocks built from atoms / full components with a lifecycle. (See GLOSSARY.md.) |
| hidden vanilla windows | ZeD never registers with Java's UIManager (that pairing can't be undone from Lua); vanilla windows are hidden behind ours instead. |

## Hard rules

1. Comments only. Code, strings (including every player-facing string), and
   behavior are untouched — byte-identical outside comments.
2. Never delete information you can't carry over; translate it.
3. No personal names, usernames, or machine paths from the project's own
   development — the team, QA, local machines. Public credit is different:
   a ModSupport header names the supported mod and its author as the
   Workshop lists them.
4. English only.
5. A comment that would need the project's chat history to make sense isn't
   done yet.
