# Session 116 Delta — April 30, 2026
Boot version: `0.1.1153004ax`
Closing version: `0.1.1163004`

> First session run under the rewritten `zed-session-docs` skill. Captured retroactively at closeout because the skill itself is what got built tonight — couldn't run ambiently before it existed.

## Locked decisions

- **Adopt git for ZeD-UI version control.** End-of-session ritual is now `git add . && git commit -m "S[N]: ..." && git push`. Code AND docs ship in the same commit.
- **GitHub repo `hermit-the-trog/ZeD.UI` is the canonical mirror.** Private — paid asset libraries (Smashicons EPS) live inside.
- **`zed-session-docs` skill rewritten end-to-end.** Three modes: BOOT (drift check vs git), AMBIENT (default — capture as decisions happen), CLOSEOUT (flush delta to canon, commit, push). The cliff at end-of-session is gone — capture is distributed across the session.
- **`SESSION_NN_DELTA.md` is a new doc class.** Lives at `ZeDUI/deltas/`. Created at boot, written ambiently, distributed to canon at closeout, archived in repo via the closing commit.
- **Git is ground truth for the WHAT.** PROJECT_STATE.md no longer hand-tracks file-structure changes. Docs carry only the WHY.
- **GitHub MCP connector enabled in Claude.** Future sessions can read repo state directly — git log lookups, file diffs, drift reconciliation no longer require copy-paste from PowerShell.

## Rejected approaches

- **NotebookLM as closeout aid.** Read-side tool. Closeout is a write problem, not a read problem. Would add another platform to feed for zero saved minutes at closeout. Could still serve as a session-transcript museum down the road — separate question, not this answer.
- **End-of-session reconstruction model.** Squeezing 90 minutes of session into a 20-minute writeup IS the closeout pain. Killed in favor of ambient capture.

## Engine quirks discovered

- None. Tooling session — no Lua / Java touched.

## Design rules added or updated

- None UI-side. Workflow rules added (above) but no design system changes.

## Milestones / shipped work

- Git initialized at mod root. Initial commit: 55,307 objects, 787.15 MiB pushed at ~47.50 MiB/s.
- Private GitHub repo `hermit-the-trog/ZeD.UI` created and synced.
- Resolved unrelated-histories merge (GitHub-side README commit + local initial commit) via `git pull origin main --allow-unrelated-histories`.
- `.gitignore` written with conservative defaults (`*.log`, `*.bak`, `.vscode/`, `.DS_Store`, `Thumbs.db`).
- New `zed-session-docs/SKILL.md` drafted (delivered at `/mnt/user-data/outputs/SKILL.md` for install on Dude's skill location).
- GitHub MCP connector enabled inside Claude.

## Open questions parked

- **`ZeDUI/tools/icon_matcher/Smashicons/zips/`** (~500 MB+ of paid asset zips) is currently tracked in git. Should be added to `.gitignore` and stripped from history with `git filter-repo` or BFG. Defer to S118 housekeeping pass — not blocking S117.
- **No `README.md` at repo root.** Anyone landing on the repo cold (including future-Claude via GitHub MCP) gets no orientation. Worth ~10 minutes when there's a lull.
- **S115c radio gamepad focusables work** queued in S115 closeout is still pending. Punted to S117 (now the proper main-quest target).

## Mockups touched

- None.
