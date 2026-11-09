# Beta 9: the host helper restores a banned player's role (QA, Nov 8 2026)

Verdict: PASS for the restore, with one deviation: a moderator cannot be banned through ZeD (see below), so the role used was gm.

## Setup
- Test server (zedqa_mp) with RCONPort 27015, a random RCONPassword (never printed or kept), DoLuaChecksum=false, sandbox HostHelper = true. Helper `zed_rcon_helper.py --zomboid %USERPROFILE%\Zomboid\zedqa_mp --server zedqa`, output in `ZeDUI/tools/qa/b9_hr_helper.log`.
- Admin client (zedqa, windowed 1280x800) and a second client logged in as the new account b9_mod (the account must have been on the server once: ZeD takes a timed ban only for a name it has seen).
- Script `zedqa_b9_helper_role.lua` (tag b9hr), driver `b9_helper_role_run.ps1`, log `b9_hr_run.log`.

## Steps and evidence (second run, gm)
1. Admin gave b9_mod the gm role through ZeD's own call (a_role): PASS, the game's list read gm.
2. ZeD timed ban, shortened to 210 s on the server (ZeDQA shortban): accepted, row ends in 210 s, the game's ban followed (role read banned). 9 passed, 0 failed.
3. Both clients quit, so no staff online. Helper log:
   - `18:17:46 ok Ban b9_mod: System banned user b9_mod`
   - `18:21:05 ok UnBan b9_mod: System unbanned user b9_mod`
   - `18:21:09 ok SetRole b9_mod: User b9_mod is now gm`
   - queue.txt line seen: `3 | 1 | SetRole | b9_mod | gm | restore` (the role the ban recorded, with the restore mark)
   - the server's db afterward: `('b9_mod', 5, 'gm')`, so the role is back (it would read banned/user without the restore).
4. A hand-added five-field line `9001 SetRole b9_mod admin` in queue.txt: refused (`refused call 9001: SetRole`, answers.txt `refused`), db role unchanged.
5. Not run: a plain user's timed ban ending with no SetRole (needed a third login cycle; undoGame skips user and banned by code, and the helper's unit tests cover it).

## Findings
- A moderator cannot be timed-banned by an admin through ZeD: the first run answered `protected` (moderator and admin hold CantBeBannedByUser). Not a helper fault. The restore was proven with gm, a role without that protection (record: `b9_hr_run_attempt3_moderator.log`, 5 passed 3 failed, expected).
- Test-rig notes: do not delete queue.txt after the server is up (ZeD writes it only when its text changes, so the helper never saw an epoch); the second client's "click to start" needs the two game windows apart (the driver now moves them).

## Cleanup
Helper stopped by PID, server stopped by mp_server.ps1 -Stop, server ini, sandbox file and db put back from copies, Workshop Contents back, lock free.
