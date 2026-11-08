# Handoff: the comment pass, the docs move, and what comes after beta 8 (Nov 8 2026)

For the Claude working on main. This session ran on branch `claude/pensive-ritchie-gyopr4`, PR
hermit-the-trog/ZeD.UI#1 (draft). Nothing on that branch changes how the mod plays.

## What PR #1 holds

1. **One comment voice across all shipping Lua.** All 304 files in `42/media/lua`, rewritten to the rules in
   `docs/reference/COMMENT_VOICE.md`. Session tags, punch-list and ticket numbers, dates and quotes leave; the
   facts they carried stay as plain present tense. Engine facts, real TODOs, ASCII diagrams, HOOK_MAP row refs and
   third-party mod credits stay. Stale comments that contradicted the code were rewritten to match the code.
2. **Docs move into `docs/`.** 97 files, history kept: `docs/specs`, `docs/reference`, `docs/plans`,
   `docs/handoffs`, `docs/archive` (see `docs/README.md`). The root keeps README, DEVELOPING, TRANSLATING,
   WATCH_ADDON_GUIDE, LICENSE, SUCCESSORS, STATE and NEXT_SESSION_HANDOFF. `ZeDUI/PUNCH_LIST.md` stays where it is.
   The old top-level `archive/` and `reference/` folders are gone. Every path reference in the repo was updated; none
   was functional (comments and docstrings only), so no QA script breaks on the move.
3. **Draft `STATE.md` and `NEXT_SESSION_HANDOFF.md`** (written before beta 8 shipped). Each opens with a draft line
   and marks unconfirmed claims `[check]`. They need a refresh for "beta 8 shipped" before they are trusted.
4. **`.gitignore`**: raw `zqa_`/`zedqa_` QA captures and the gallery's PNG master folders are no longer committed.
   Already-tracked files stay tracked.
5. `ZeDUI/tools/qa/lua_comment_guard.py`: the checker used for every commit (below).

## State right now

- The branch has main merged in at a495a007 (beta 8 shipped). 13 files conflicted; every conflict took main's code.
- **All 304 Lua files on the branch are byte-identical to main's code outside comments**, checked with
  `GUARD_REF=origin/main`. It can merge cleanly as it stands.
- Not done yet: beta 8's own new comments (about 750 lines across 50 files; `ZeD_HiddenFacts.lua` is all new) are
  still in the old style. Deliberately held until the nine speed builds land, so the follow-up pass is done once.

## Merge order (the director's call)

1. The speed builds merge into main first.
2. This branch merges main once more. **On any Lua conflict, take main's side** (the branch only changes comments,
   so main's code is always right). Then run the checker against main; it must print OK.
3. A follow-up comment pass over the lines main added since the pass (`git diff e727aef origin/main -- <file>`).
4. The director merges PR #1. Only the director merges.

## The checker

```
python3 -I ZeDUI/tools/qa/lua_comment_guard.py . <file.lua> ...           # vs HEAD
GUARD_REF=origin/main python3 -I ZeDUI/tools/qa/lua_comment_guard.py . --changed   # vs main
```

It strips comments (string-aware, long brackets included), collapses whitespace in code but never inside
strings, and compares. Any code or string difference fails with the first diverging line. Until PR #1 merges, read it
from the branch: `git show origin/claude/pensive-ritchie-gyopr4:ZeDUI/tools/qa/lua_comment_guard.py`.

## After PR #1 merges

1. **The director updates three synced skills** (zed-session-docs, zed-project-bible, zed-orchestrator) for the
   new doc paths. The project bible and the orchestrator still start sessions from `PROJECT_STATE.md`; the live file
   is `STATE.md` (the old one is `docs/archive/PROJECT_STATE.md`).
2. **136 tool scripts hardcode the director's Windows user folder** (99 ps1, 18 py, 11 json, 7 lua, 1 sh, mostly
   under `ZeDUI/tools`). They switch to `$env:USERPROFILE` / `os.path.expanduser('~')` in a normal PR. Held until
   after beta 8 because they are the QA tools. This must come before step 3.
3. **History rewrite (planned, not run).** The full clone packs to about 1,018 MB. The recommended cut (gallery
   PNG masters and raw zqa captures everywhere, plus old replaced versions of images under workshop/, mockups/ and
   qa/) leaves about 603 MB; also dropping every QA evidence picture leaves about 373 MB, the director's call. It
   also scrubs the user-folder path from every old version. It needs: every branch merged or deleted (fix/admin-clip,
   fix/ctx-highlight, fix/mac-report, fix/odo-night, i18n/beta6, plus any local ones), a push freeze, a mirror
   backup, a force push, and everyone re-cloning. GitHub Support has to purge the old PR refs. The step-by-step plan
   lives with the comment-pass session (it spells out the path it scrubs, so it is kept out of the repo); ask the
   director for it.

## Already on main

`docs/plans/PERF_REVIEW_20261108.md` (performance findings, ranked) and `docs/plans/CODE_FLAGS_20261108.md` (bugs
and dead code the comment agents found). The director has already sent the confirmed bugs into beta 8 and to the
speed builders.

## Small open items

- `42/mod.info` on main still reads `0.3.0-beta7` although beta 8 shipped.
- `docs/plans/COHESION_LIBRARY_FIXES.md` has three items still open (a shared popup box, a slider molecule, a
  wrapping question band): carry them into the punch list or drop them.
- Generated Lua tables (PhysPx, DashPx, ContextPxIcons, WatchPlates, MechFigs, PixelFonts) got new headers; their
  generator templates still write the old ones, so a regeneration will undo the headers until the templates change.
