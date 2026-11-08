# ZeD host helper

An optional small program for people who run a Project Zomboid server with ZeD-GUI. It makes the bans, unbans, kicks,
voice bans and end-of-ban role restores ZeD owes the game through the server's own remote console (RCON), so ZeD's rules hold even when no staff member is online.

Without it nothing breaks: those calls wait for the next staff member to log in, and their game makes them.

## What it does, and what it never does

- ZeD's server part writes the calls it owes to `<Zomboid>/Lua/ZeD_helper/queue.txt`. The helper reads that file, makes
  each call through RCON and writes the result to `answers.txt` next to it. ZeD reads the result and checks for itself that
  the ban held.
- It sends only seven console commands: `kickuser`, `banuser`, `unbanuser`, `banid`, `unbanid`, `voiceban` (with `-true`
  only) and `setaccesslevel`. It checks every name and Steam ID against strict patterns first (names: 2 to 32 plain letters,
  digits, `_`, `-` or inner spaces, and for `voiceban` never starting with `-`; Steam IDs: 17 digits) and quotes names the
  way the console expects. Anything else is refused and left to a staff member.
- `setaccesslevel` is only for the end of a ban. The game's unban puts the account back to a plain user, so ZeD gives back
  the role the player had when banned (a moderator comes back a moderator). The helper takes only that one role call, marked
  as such by ZeD's server, with a role of 1 to 32 plain letters, digits or `_`. Any other role change is a staff member's own.
- IP bans are never the helper's: the game's IP ban needs the player's own connection, which only a staff member's game has.
- A mute's chat side is not the helper's. The server cannot reach the game's chat; ZeD's mute is kept by each player's ZeD.
  The helper makes only a mute's voice ban (the game's own `/voiceban`), which the game holds for one connection, so ZeD owes
  it each time a muted player comes on. An unmute is always a staff member's own call.
- It never prints or writes the RCON password.
- A call the console fails is tried again half a minute later, three times in all, then left to a staff member. ZeD writes
  one log line a minute at most about failures, with a count.

## Before you turn it on

- **Anything that can write the queue file can kick, ban, unban and set a role.** The helper trusts the file. Any other server-side Lua
  mod can write it, and so can client-side Lua from another server's mods if you also play on this machine from the same
  Zomboid folder. Start the server with its own folder (`-cachedir=...`, for example `-cachedir=C:\PZServer` or
  `-cachedir=/home/pzserver/pzdata`) and point `--zomboid` there.
- **One server per Zomboid folder.** Two servers sharing one folder share one queue, so one world's bans would run on the
  other's console.

## You need

- Python 3.8 or newer on the server machine. Nothing to install from the internet: it uses the standard library only.
- Access to the server's files (its Zomboid folder).

## Getting it

The helper is not part of the Workshop item (the game never loads it). Download `zed_rcon_helper.py` from the ZeD-GUI
repository, folder `ZeDUI/server_helper/`: https://github.com/hermit-the-trog/ZeD.UI/tree/main/ZeDUI/server_helper
Put it anywhere on the server machine.

## Setup

1. **Turn on RCON.** In the server's settings file, `<Zomboid>/Server/<servername>.ini`, set a port and a long random
   password, then restart the server:

   ```
   RCONPort=27015
   RCONPassword=pick-a-long-random-password
   ```

2. **Keep RCON on this machine only.** Add `-Drconlo=true` to the server's Java options and restart. With it the game
   listens for RCON on 127.0.0.1 only. Without it the game listens on every network address, so then make sure the RCON
   port is closed in your firewall and not forwarded on your router.
   - Windows: on the java line in `StartServer64.bat`, beside the other `-D` options.
   - Linux: in `ProjectZomboid64.json`, as one more entry in `"vmArgs"` (used by `start-server.sh`).

3. **Turn on the ZeD option.** In the server's sandbox settings, page ZeD-GUI, tick **Host Helper (RCON)**. In the file it is
   `<Zomboid>/Server/<servername>_SandboxVars.lua`, `ZeD = { ..., HostHelper = true, }`.

4. **Run the helper** next to the server. `--zomboid` is the server's Zomboid folder (the one holding `Server/` and `Lua/`;
   if you start the server with `-cachedir=...`, use that folder). `--server` is the server's name.

   Windows (PowerShell or Command Prompt):

   ```
   py -3 zed_rcon_helper.py --zomboid "C:\Users\you\Zomboid" --server servertest
   ```

   To start it with the machine, make a Task Scheduler task "At startup" running `py` with those arguments.

   Linux:

   ```
   python3 zed_rcon_helper.py --zomboid ~/Zomboid --server servertest
   ```

   To keep it running, a systemd service, for example `/etc/systemd/system/zed-helper.service`:

   ```
   [Unit]
   Description=ZeD host helper
   After=network.target

   [Service]
   User=pzserver
   ExecStart=/usr/bin/python3 /opt/zed/zed_rcon_helper.py --zomboid /home/pzserver/Zomboid --server servertest
   Restart=on-failure
   RestartSec=30

   [Install]
   WantedBy=multi-user.target
   ```

   then `sudo systemctl enable --now zed-helper`.

The password is read from the settings file. To keep it out of that process's view instead, set the environment variable
`ZED_RCON_PASSWORD` for the helper; it wins over the file.

## Checking it works

- The helper prints one line for each call it makes: the result and the console's answer.
- `answers.txt` is rewritten every two seconds. ZeD counts the helper as running while that file is under 30 seconds old;
  otherwise the calls go to staff as before.
- Ban someone timed on a test server, log out every staff account, wait for the end: the helper prints the unban.

Exit codes: 0 fine, 1 no RCON port or password found, 2 the console refused the password.

## Options

| Option | Default | What it is |
|---|---|---|
| `--zomboid` | your home folder's `Zomboid` | the server's Zomboid folder |
| `--server` | `servertest` | the server's name |
| `--host` | `127.0.0.1` | where RCON listens |
| `--port` | `RCONPort` from the settings | RCON's port |
| `--poll` | `2` | seconds between passes |
| `--timeout` | `5` | seconds to wait for the console |
| `--once` | off | one pass, then exit |

## For developers

`test_zed_rcon_helper.py` runs the helper against a fake RCON server on localhost that speaks the game's protocol and reads
commands the way the game does: `python -I test_zed_rcon_helper.py`. How ZeD's side works is in
`docs/specs/MP_SERVER_PART_DESIGN.md`, "Rules that hold".
