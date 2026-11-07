#!/usr/bin/env python3
"""ZeD host helper (Nov 7 2026). Python 3 standard library only. Runs on the machine that runs the Project Zomboid server.

ZeD-GUI's server part keeps its rules (bans, timed bans, the join rules) itself, but server Lua cannot ban, unban or kick a
player: those are the game's own calls, made from a staff member's game. This helper makes them through the game's own remote
console (RCON) instead, so they land with no staff online. It is optional: turn on the sandbox option "Host Helper (RCON)"
(ZeD.HostHelper) and run this next to the server.

How the two talk (both files under <Zomboid>/Lua/ZeD_helper/, the server's own Lua folder):
  queue.txt    written by the server: "ZEDQ 1 <epoch>", then one call a line: id, try, act, target, reason (tab-separated)
  answers.txt  written here: "ZEDA 1 <epoch> <unix seconds>", then one answer a line: id, try, result, text

Security. The queue is only ever read as data. This helper sends nothing but a fixed allow-list of five console commands
(kickuser, banuser, unbanuser, banid, unbanid), each built here from a target it checks itself: a username of 2 to 32 ASCII
letters, digits, _ - or inner spaces, quoted as the console expects; a Steam ID of 17 digits. A ban's reason is cut to plain
printable ASCII with its double quotes turned to single ones, so it cannot end its own quotes. Anything else is refused and
answered "refused", and ZeD gives that call to a staff member's game instead. The RCON password is read from the server's
settings file or the ZED_RCON_PASSWORD environment variable and is never printed or written anywhere.

Usage:
  python3 zed_rcon_helper.py --zomboid ~/Zomboid --server servertest
  python3 zed_rcon_helper.py --once          (one pass, then exit: for a test or a scheduled task)
Exit codes: 0 fine, 1 bad setup (no RCON port or password), 2 the console refused the password.
"""
import argparse
import os
import re
import socket
import struct
import sys
import time

VERSION = "1"

# ---------------------------------------------------------------------------
# The allow-list: the only commands this program ever sends (zombie.commands.serverCommands, 42.22.2)
# ---------------------------------------------------------------------------
USER_RE = re.compile(r"[A-Za-z0-9_-][A-Za-z0-9_ -]{0,30}[A-Za-z0-9_-]", re.ASCII)
SID_RE = re.compile(r"7656119[0-9]{10}", re.ASCII)
EPOCH_RE = re.compile(r"[0-9A-Za-z-]{1,64}", re.ASCII)
NUM_RE = re.compile(r"[0-9]{1,9}", re.ASCII)
REASON_MAX = 200
QUEUE_MAX = 500          # lines read from the queue at most
TEXT_MAX = 200           # the console's answer, as written back


def clean_reason(reason):
    """Plain printable ASCII, no double quote, one line, at most REASON_MAX characters."""
    out = []
    for ch in str(reason):
        if ch == '"':
            out.append("'")
        elif " " <= ch <= "~":
            out.append(ch)
        else:
            out.append(" ")
    return " ".join("".join(out).split())[:REASON_MAX].strip()


def _quoted_user(target):
    if not isinstance(target, str) or not USER_RE.fullmatch(target):
        return None
    return '"' + target + '"'


def _sid(target):
    if not isinstance(target, str) or not SID_RE.fullmatch(target):
        return None
    return target


def _with_reason(cmd, reason):
    r = clean_reason(reason)
    return cmd + (' -r "' + r + '"' if r else "")


def build_command(act, target, reason=""):
    """The console line for an allowed call, or None when the call is not allowed or its target fails the patterns."""
    if act == "Kick":
        q = _quoted_user(target)
        return q and _with_reason("kickuser " + q, reason)
    if act == "Ban":
        q = _quoted_user(target)
        return q and _with_reason("banuser " + q, reason)
    if act == "UnBan":
        q = _quoted_user(target)
        return q and "unbanuser " + q
    if act == "BanSteamID":
        s = _sid(target)
        return s and "banid " + s
    if act == "UnBanSteamID":
        s = _sid(target)
        return s and "unbanid " + s
    return None


# what the game answers (the strings in BanSystem, KickUserCommand, UnbanSteamIDCommand)
_OK = {
    "Kick": re.compile(r"^User .+ kicked\.$"),
    "Ban": re.compile(r" banned user "),
    "UnBan": re.compile(r" unbanned user "),
    "BanSteamID": re.compile(r" banned SteamID "),
    "UnBanSteamID": re.compile(r"^SteamID [0-9]+ is now unbanned"),
}
_REFUSED = re.compile(r"can't be (?:kicked|banned)|don't have capability|not in Steam mode|Expected SteamID")


def classify(act, response):
    """ok, gone (a Kick on someone not on), refused (the game said no) or failed."""
    text = (response or "").strip()
    if act in _OK and _OK[act].search(text):
        return "ok"
    if act == "Kick" and "doesn't exist" in text:
        return "gone"
    if _REFUSED.search(text):
        return "refused"
    return "failed"


def one_line(text):
    return " ".join(str(text).replace("\t", " ").split())[:TEXT_MAX]


# ---------------------------------------------------------------------------
# Source RCON over TCP, as the game's RCONServer speaks it: little-endian size, id, type, body, two zero bytes.
# Auth is type 3; the server answers an empty type 0, then type 2 with our id (or -1 for a wrong password). A command is type
# 2; its answer is type 0 with the same id.
# ---------------------------------------------------------------------------
SERVERDATA_AUTH = 3
SERVERDATA_AUTH_RESPONSE = 2
SERVERDATA_EXECCOMMAND = 2
SERVERDATA_RESPONSE_VALUE = 0


class AuthError(Exception):
    pass


class Rcon:
    def __init__(self, host, port, password, timeout=5.0):
        self.host, self.port, self._password, self.timeout = host, port, password, timeout
        self.sock = None
        self.next_id = 100

    def __enter__(self):
        self.sock = socket.create_connection((self.host, self.port), timeout=self.timeout)
        self.sock.settimeout(self.timeout)
        self._auth()
        return self

    def __exit__(self, *exc):
        try:
            self.sock.close()
        except OSError:
            pass
        return False

    def _send(self, pid, ptype, body):
        data = body.encode("ascii", "replace")
        if len(data) > 4000:
            raise ValueError("command too long")
        packet = struct.pack("<ii", pid, ptype) + data + b"\x00\x00"
        self.sock.sendall(struct.pack("<i", len(packet)) + packet)

    def _recv_exact(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.sock.recv(n - len(buf))
            if not chunk:
                raise ConnectionError("the console closed the connection")
            buf += chunk
        return buf

    def _recv(self):
        (size,) = struct.unpack("<i", self._recv_exact(4))
        if size < 10 or size > 4110:
            raise ConnectionError("a packet of a size the console never sends")
        data = self._recv_exact(size)
        pid, ptype = struct.unpack("<ii", data[:8])
        return pid, ptype, data[8:-2].decode("utf-8", "replace")

    def _auth(self):
        pid = self.next_id
        self.next_id += 1
        self._send(pid, SERVERDATA_AUTH, self._password)
        for _ in range(4):
            rid, rtype, _ = self._recv()
            if rtype == SERVERDATA_AUTH_RESPONSE:
                if rid == -1:
                    raise AuthError("the console refused the password (check RCONPassword in the server's settings)")
                return
        raise ConnectionError("the console never answered the login")

    def command(self, line):
        pid = self.next_id
        self.next_id += 1
        self._send(pid, SERVERDATA_EXECCOMMAND, line)
        for _ in range(8):
            rid, rtype, body = self._recv()
            if rid == pid and rtype == SERVERDATA_RESPONSE_VALUE:
                return body
        raise ConnectionError("no answer to the command")


# ---------------------------------------------------------------------------
# The two files
# ---------------------------------------------------------------------------
def read_queue(path):
    """(epoch, [call]) or (None, []) when there is no good queue. Each call: id, try, act, target, reason."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace", newline="") as f:
            lines = f.read().split("\n")
    except OSError:
        return None, []
    head = lines[0].strip() if lines else ""
    parts = head.split(" ")
    if len(parts) != 3 or parts[0] != "ZEDQ" or parts[1] != "1" or not EPOCH_RE.fullmatch(parts[2]):
        return None, []
    calls = []
    for raw in lines[1:QUEUE_MAX + 1]:
        line = raw.rstrip("\r")
        if not line:
            continue
        f = line.split("\t")
        if len(f) < 4 or not NUM_RE.fullmatch(f[0]) or not NUM_RE.fullmatch(f[1]):
            continue
        calls.append({"id": int(f[0]), "try": int(f[1]), "act": f[2], "target": f[3], "reason": f[4] if len(f) > 4 else ""})
    return parts[2], calls


def read_answers(path, epoch):
    """{(id, try): (result, text)} from an answers file of this epoch."""
    out = {}
    try:
        with open(path, "r", encoding="utf-8", errors="replace", newline="") as f:
            lines = f.read().split("\n")
    except OSError:
        return out
    head = lines[0].split(" ") if lines else []
    if len(head) != 4 or head[0] != "ZEDA" or head[2] != epoch:
        return out
    for raw in lines[1:QUEUE_MAX + 1]:
        f = raw.rstrip("\r").split("\t")
        if len(f) >= 3 and NUM_RE.fullmatch(f[0]) and NUM_RE.fullmatch(f[1]):
            out[(int(f[0]), int(f[1]))] = (f[2], f[3] if len(f) > 3 else "")
    return out


def write_answers(path, epoch, answers, now=None):
    """The whole file at once, through a temporary file, so the server never reads half of it."""
    lines = ["ZEDA 1 %s %d" % (epoch, int(now if now is not None else time.time()))]
    for (cid, ctry), (res, text) in sorted(answers.items()):
        lines.append("%d\t%d\t%s\t%s" % (cid, ctry, res, one_line(text)))
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, path)


# ---------------------------------------------------------------------------
# One pass
# ---------------------------------------------------------------------------
def log(msg):
    print(time.strftime("%Y-%m-%d %H:%M:%S ") + msg, flush=True)


def run_once(folder, host, port, password, timeout=5.0, now=None):
    """Reads the queue, makes every call not yet answered, writes the answers. Returns the answers made this pass."""
    queue = os.path.join(folder, "queue.txt")
    answers_path = os.path.join(folder, "answers.txt")
    epoch, calls = read_queue(queue)
    if epoch is None:
        return {}
    old = read_answers(answers_path, epoch)
    in_queue = set(c["id"] for c in calls)
    keep = {k: v for k, v in old.items() if k[0] in in_queue}
    todo = []
    made = {}
    for c in calls:
        key = (c["id"], c["try"])
        if key in keep:
            continue
        line = build_command(c["act"], c["target"], c["reason"])
        if line is None:
            made[key] = ("refused", "not on the helper's allow-list, or a target outside its patterns")
            log("refused call %d: %s" % (c["id"], one_line(c["act"])[:40]))
        else:
            todo.append((key, c, line))
    if todo:
        try:
            with Rcon(host, port, password, timeout) as rc:
                for key, c, line in todo:
                    try:
                        resp = rc.command(line)
                    except (OSError, ConnectionError, ValueError) as e:
                        made[key] = ("failed", "no answer from the console: %s" % e)
                        continue
                    res = classify(c["act"], resp)
                    made[key] = (res, resp)
                    log("%s %s %s: %s" % (res, c["act"], c["target"], one_line(resp)))
        except AuthError:
            raise
        except (OSError, ConnectionError) as e:
            for key, c, line in todo:
                if key not in made:
                    made[key] = ("failed", "the console could not be reached: %s" % e)
            log("the console could not be reached at %s:%d (%s)" % (host, port, e))
    keep.update(made)
    write_answers(answers_path, epoch, keep, now)
    return made


# ---------------------------------------------------------------------------
# Setup: the server's settings file
# ---------------------------------------------------------------------------
def read_ini(path):
    out = {}
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                if "=" in line and not line.lstrip().startswith("#"):
                    k, v = line.split("=", 1)
                    out[k.strip()] = v.strip()
    except OSError:
        pass
    return out


def main(argv=None):
    ap = argparse.ArgumentParser(description="ZeD host helper: makes ZeD's owed bans, unbans and kicks through the server's RCON.")
    ap.add_argument("--zomboid", default=os.path.join(os.path.expanduser("~"), "Zomboid"),
                    help="the server's Zomboid folder (the one holding Server/ and Lua/; the -cachedir if you set one)")
    ap.add_argument("--server", default="servertest", help="the server's name: its settings are Server/<name>.ini")
    ap.add_argument("--host", default="127.0.0.1", help="where the console listens (default 127.0.0.1)")
    ap.add_argument("--port", type=int, default=0, help="the console's port (default: RCONPort from the settings)")
    ap.add_argument("--poll", type=float, default=2.0, help="seconds between passes")
    ap.add_argument("--timeout", type=float, default=5.0, help="seconds to wait for the console")
    ap.add_argument("--once", action="store_true", help="one pass, then exit")
    a = ap.parse_args(argv)

    ini = read_ini(os.path.join(a.zomboid, "Server", a.server + ".ini"))
    port = a.port or int(ini.get("RCONPort", "0") or 0)
    password = os.environ.get("ZED_RCON_PASSWORD") or ini.get("RCONPassword", "")
    if not port or not password:
        log("no RCON port or password: set RCONPort and RCONPassword in %s, or ZED_RCON_PASSWORD"
            % os.path.join(a.zomboid, "Server", a.server + ".ini"))
        return 1
    folder = os.path.join(a.zomboid, "Lua", "ZeD_helper")
    os.makedirs(folder, exist_ok=True)
    log("ZeD host helper %s: %s, console %s:%d (password from %s)"
        % (VERSION, folder, a.host, port, "ZED_RCON_PASSWORD" if os.environ.get("ZED_RCON_PASSWORD") else "the settings file"))
    while True:
        try:
            run_once(folder, a.host, port, password, a.timeout)
        except AuthError as e:
            log(str(e))
            return 2
        except OSError as e:
            log("could not use %s: %s" % (folder, e))
        if a.once:
            return 0
        time.sleep(a.poll)


if __name__ == "__main__":
    sys.exit(main())
