"""Tests for zed_rcon_helper.py (Nov 7 2026). Python 3 standard library only; nothing to install, no game.

A fake RCON server on localhost speaks the game's protocol as RCONServer$ClientThread does (an empty type 0 then type 2 on
login, -1 for a wrong password, a type 0 answer with the command's id) and reads each command the way the game's CommandBase
does: the first word picks the command, then the tokens of ([^"]\\S*|".*?")\\s* with their quotes taken out. It answers with the
game's own strings. Covered: login, the allow-list, injection attempts refused with nothing sent, the answers file, tries,
the console being down and the password never printed.

Run:  python -I ZeDUI/server_helper/test_zed_rcon_helper.py      (exit 0 when every check passes)
"""
import contextlib
import importlib.util
import io
import os
import re
import socket
import socketserver
import struct
import sys
import tempfile
import threading

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("zed_rcon_helper", os.path.join(HERE, "zed_rcon_helper.py"))
H = importlib.util.module_from_spec(spec)
spec.loader.exec_module(H)

PASSWORD = "s3cret-Pa55word-not-for-logs"
checks = failed = 0


def check(name, ok, detail=None):
    global checks, failed
    checks += 1
    if not ok:
        failed += 1
        print("FAIL " + name + ("" if detail is None else " (%r)" % (detail,)))


# ---------------------------------------------------------------------------
# The fake game
# ---------------------------------------------------------------------------
TOKEN = re.compile(r'([^"]\S*|".*?")\s*')


class Game:
    def __init__(self):
        self.lock = threading.Lock()
        self.reset()

    def reset(self):
        self.commands = []          # every command line received
        self.parsed = []            # the tokens the game would read
        self.online = {"Kade", "Torch", "Big Sam"}
        self.banned = set()
        self.sids = set()
        self.protected = {"Owner"}
        self.logins = 0

    def run(self, line):
        with self.lock:
            self.commands.append(line)
            toks = [m.group(1).replace('"', "") for m in TOKEN.finditer(line)]
            self.parsed.append(toks)
            name, args = toks[0].lower(), toks[1:]
            if name == "kickuser":
                if not args or (len(args) not in (1, 3)) or (len(args) == 3 and args[1] != "-r"):
                    return "UI_command_arg_parse_failed"
                u = args[0]
                if u in self.protected:
                    return "This user can't be kicked."
                if u in self.online:
                    self.online.discard(u)
                    return "User %s kicked." % u
                return "User %s doesn't exist." % u
            if name == "banuser":
                if not args or (len(args) not in (1, 3)) or (len(args) == 3 and args[1] != "-r"):
                    return "UI_command_arg_parse_failed"
                u = args[0]
                if u in self.protected:
                    return "This user can't be banned."
                self.banned.add(u)
                self.online.discard(u)
                return "System banned user %s" % u
            if name == "unbanuser":
                self.banned.discard(args[0])
                return "System unbanned user %s" % args[0]
            if name == "banid":
                if not re.fullmatch(r"7656119\d{10}", args[0]):
                    return 'Expected SteamID but got "%s"' % args[0]
                self.sids.add(args[0])
                return "System banned SteamID %s(" % args[0]
            if name == "unbanid":
                self.sids.discard(args[0])
                return "SteamID %s is now unbanned" % args[0]
            return "Unknown command " + name


GAME = Game()


class Handler(socketserver.BaseRequestHandler):
    def recv_exact(self, n):
        buf = b""
        while len(buf) < n:
            c = self.request.recv(n - len(buf))
            if not c:
                raise ConnectionError
            buf += c
        return buf

    def send(self, pid, ptype, body):
        data = body.encode("utf-8")
        pkt = struct.pack("<ii", pid, ptype) + data + b"\x00\x00"
        self.request.sendall(struct.pack("<i", len(pkt)) + pkt)

    def handle(self):
        auth = False
        try:
            while True:
                (size,) = struct.unpack("<i", self.recv_exact(4))
                if size < 10 or size > 4096:
                    return
                data = self.recv_exact(size)
                pid, ptype = struct.unpack("<ii", data[:8])
                body = data[8:-2].decode("ascii")
                if ptype == 3:
                    auth = body == PASSWORD
                    with GAME.lock:
                        GAME.logins += 1
                    self.send(pid, 0, "")
                    self.send(pid if auth else -1, 2, "")
                    if not auth:
                        return
                elif ptype == 2 and auth:
                    self.send(pid, 0, GAME.run(body))
        except (ConnectionError, OSError, struct.error):
            return


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


srv = Server(("127.0.0.1", 0), Handler)
PORT = srv.server_address[1]
threading.Thread(target=srv.serve_forever, daemon=True).start()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def queue(folder, epoch, rows):
    with open(os.path.join(folder, "queue.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("ZEDQ 1 %s\n" % epoch)
        for r in rows:
            f.write("\t".join(str(x) for x in r) + "\n")
        f.write("ZEDQ end\n")


def answers(folder):
    with open(os.path.join(folder, "answers.txt"), encoding="utf-8") as f:
        return f.read()


def run(folder, password=PASSWORD, port=None, now=1793913240):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        made = H.run_once(folder, "127.0.0.1", port or PORT, password, timeout=2.0, now=now)
    return made, out.getvalue()


EPOCH = "11111111-2222-3333-4444-000000000003"

# ---------------------------------------------------------------------------
# Login, and the five calls
# ---------------------------------------------------------------------------
with tempfile.TemporaryDirectory() as d:
    GAME.reset()
    queue(d, EPOCH, [
        (1, 1, "Ban", "Kade", "Griefing the farm"),
        (2, 1, "BanSteamID", "76561198000000321", "alt"),
        (3, 1, "Kick", "Torch", ""),
        (4, 1, "UnBan", "Mags", ""),
        (5, 1, "UnBanSteamID", "76561198000000322", ""),
        (6, 1, "Kick", "Big Sam", "spam"),
    ])
    made, out = run(d)
    check("the five calls go as the console expects", GAME.commands == [
        'banuser "Kade" -r "Griefing the farm"', "banid 76561198000000321", 'kickuser "Torch"', 'unbanuser "Mags"',
        "unbanid 76561198000000322", 'kickuser "Big Sam" -r "spam"'], GAME.commands)
    check("the game reads each as intended", GAME.parsed[0] == ["banuser", "Kade", "-r", "Griefing the farm"] and GAME.parsed[5] == ["kickuser", "Big Sam", "-r", "spam"], GAME.parsed)
    check("each one confirmed", all(made[(i, 1)][0] == "ok" for i in range(1, 7)), made)
    a = answers(d)
    check("the answers name the world and the time", a.startswith("ZEDA 1 %s 1793913240\n" % EPOCH), a)
    check("one line an answer: id, try, result, text", "1\t1\tok\tSystem banned user Kade\n" in a and "3\t1\tok\tUser Torch kicked.\n" in a, a)
    check("one login for a pass", GAME.logins == 1, GAME.logins)
    # a second pass: nothing made twice
    GAME.commands = []
    made, out = run(d)
    check("an answered call is never made again", GAME.commands == [] and made == {}, GAME.commands)
    check("the answers file is kept fresh", "1\t1\tok" in answers(d))
    # a new try of the same call is made again
    queue(d, EPOCH, [(1, 2, "Ban", "Kade", "Griefing the farm")])
    made, out = run(d)
    check("a new try is made", GAME.commands == ['banuser "Kade" -r "Griefing the farm"'] and made[(1, 2)][0] == "ok", GAME.commands)
    check("answers for calls gone from the queue are dropped", "\n3\t1\t" not in answers(d), answers(d))

# ---------------------------------------------------------------------------
# The allow-list, and injection
# ---------------------------------------------------------------------------
with tempfile.TemporaryDirectory() as d:
    GAME.reset()
    bad = [
        (10, 1, "BanIP", "Kade", "x"),                       # not on the list (needs the player's connection)
        (11, 1, "quit", "Kade", ""),
        (12, 1, "ServerMessage", "hello", ""),
        (13, 1, "Ban", 'Kade" -ip -r "x', "x"),              # a quote to break out of the name
        (14, 1, "Ban", "Kade\x00quit", "x"),
        (15, 1, "Kick", "a;b", ""),
        (16, 1, "Kick", "Näme", ""),                     # outside the ASCII patterns: a staff game makes it
        (17, 1, "Kick", "x", ""),                             # too short
        (18, 1, "Kick", "y" * 33, ""),                        # too long
        (19, 1, "Kick", " Kade", ""),                         # an outer space
        (20, 1, "BanSteamID", "7656119800000032x", ""),
        (21, 1, "BanSteamID", "76561198000000321 ; quit", ""),
        (22, 1, "UnBanSteamID", "1234", ""),
        (23, 1, "Ban", "Kade -ip", ""),                       # a flag hidden in a name with a space is still quoted as a name
    ]
    queue(d, EPOCH, bad[:13])
    made, out = run(d)
    check("nothing off the list or outside the patterns reaches the console", GAME.commands == [], GAME.commands)
    check("each is answered refused", all(made[(r[0], 1)][0] == "refused" for r in bad[:13]), made)
    check("so nobody logs in for them", GAME.logins == 0, GAME.logins)
    queue(d, EPOCH, [bad[13]])
    made, out = run(d)
    check("a name that looks like a flag stays one quoted name", GAME.parsed == [["banuser", "Kade -ip"]], GAME.parsed)
    # a line break can only end a queue line: what follows it is not a call
    GAME.reset()
    with open(os.path.join(d, "queue.txt"), "w", encoding="utf-8", newline="\n") as f:
        f.write("ZEDQ 1 %s\n90\t1\tKick\tTorch\t\nquit\tx\n91\t1\tBan\tKade\t\r\nZEDQ end\n" % EPOCH)
    made, out = run(d)
    check("a broken line is not obeyed", GAME.commands == ['kickuser "Torch"', 'banuser "Kade"'], GAME.commands)
    for t in ["Kade\nquit", "Kade\rquit", "Kade\x00", "Kade\tx", 'Ka"de', "Ka\\de", "Kade;quit", "", None, 5]:
        check("build_command refuses %r" % (t,), H.build_command("Ban", t, "x") is None and H.build_command("Kick", t) is None)
    for t in ["7656119800000032\n", "76561198000000321\x00", " 76561198000000321", "+76561198000000321"]:
        check("build_command refuses the Steam ID %r" % (t,), H.build_command("BanSteamID", t) is None)
    check("the reason can never close its quotes", '"' not in H.clean_reason('a"b"c')[0:] and H.clean_reason("\x00\n\t") == "")
    # reasons: quotes, line breaks, tabs, wide characters and length are cleaned, never refused
    GAME.reset()
    queue(d, EPOCH, [(30, 1, "Ban", "Torch", 'he said "x" -ip -r "y"\r and more ' + "z" * 300)])
    made, out = run(d)
    check("a reason with quotes is one token", len(GAME.parsed) == 1 and len(GAME.parsed[0]) == 4 and GAME.parsed[0][2] == "-r", GAME.parsed)
    check("its quotes are single ones, its length capped", "\"" not in GAME.parsed[0][3] and len(GAME.parsed[0][3]) <= 200 and "'x'" in GAME.parsed[0][3], GAME.parsed[0][3])
    check("only the allowed words reach the console", GAME.commands[0].startswith('banuser "Torch" -r "'), GAME.commands)
    # the queue as data: a bad header or a bad line is skipped, not obeyed
    GAME.reset()
    with open(os.path.join(d, "queue.txt"), "w", encoding="utf-8") as f:
        f.write("ZEDQ 1 ../../etc\n1\t1\tBan\tKade\tx\nZEDQ end\n")
    made, out = run(d)
    check("a queue with a bad header is not read", made == {} and GAME.commands == [])
    queue(d, EPOCH, [("1x", 1, "Ban", "Kade", "x"), (40, 1, "Ban")])
    made, out = run(d)
    check("lines that are not calls are skipped", made == {} and GAME.commands == [], made)

# ---------------------------------------------------------------------------
# A queue read while the server writes it (the game's writer sends it in pieces, in place)
# ---------------------------------------------------------------------------
with tempfile.TemporaryDirectory() as d:
    GAME.reset()
    whole = "ZEDQ 1 %s\n7\t1\tKick\tTorch\t\n8\t1\tKick\tDaniel\t\nZEDQ end\n" % EPOCH
    cut_at = whole.index("Daniel") + 3              # the reader lands inside "Daniel"
    for name, text in [("cut inside a name", whole[:cut_at]), ("cut after a whole line", whole[:whole.index("8\t")]),
                       ("empty, just truncated", ""), ("the end line without its line break", whole[:-1]),
                       ("only the head", "ZEDQ 1 %s\n" % EPOCH)]:
        with open(os.path.join(d, "queue.txt"), "w", encoding="utf-8", newline="") as f:
            f.write(text)
        made, out = run(d)
        check("a queue %s is left for the next pass" % name, made == {} and GAME.commands == [], (made, GAME.commands))
    # a cut line can never be made as a shorter name, even with an end line after it: every call has exactly five fields
    with open(os.path.join(d, "queue.txt"), "w", encoding="utf-8", newline="") as f:
        f.write("ZEDQ 1 %s\n8\t1\tKick\tDan\nZEDQ end\n" % EPOCH)
    made, out = run(d)
    check("a call line of four fields is never made", made == {} and GAME.commands == [], (made, GAME.commands))
    with open(os.path.join(d, "queue.txt"), "w", encoding="utf-8", newline="") as f:
        f.write(whole)
    made, out = run(d)
    check("the whole queue: both made", GAME.commands == ['kickuser "Torch"', 'kickuser "Daniel"'], GAME.commands)

# ---------------------------------------------------------------------------
# Tries: only the newest of each call is kept, so a call that keeps failing never grows the answers file
# ---------------------------------------------------------------------------
with tempfile.TemporaryDirectory() as d:
    GAME.reset()
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    dead = s.getsockname()[1]
    s.close()
    for t in range(1, 6):
        queue(d, EPOCH, [(60, t, "Ban", "Kade", "x"), (61, t, "Kick", "Torch", "")])
        run(d, port=dead)
    a = answers(d)
    check("one line a call, its newest try", a.count("\n60\t") == 1 and "\n60\t5\tfailed\t" in a and a.count("\n61\t") == 1, a)
    check("latest_tries keeps the highest try", H.latest_tries({(1, 1): ("failed", ""), (1, 3): ("ok", ""), (1, 2): ("failed", ""), (2, 1): ("ok", "")}) == {(1, 3): ("ok", ""), (2, 1): ("ok", "")})

# ---------------------------------------------------------------------------
# What the game says no to, and a console that is down
# ---------------------------------------------------------------------------
with tempfile.TemporaryDirectory() as d:
    GAME.reset()
    queue(d, EPOCH, [(50, 1, "Ban", "Owner", "x"), (51, 1, "Kick", "Nobody", ""), (52, 1, "Kick", "Owner", "")])
    made, out = run(d)
    check("the game refuses a protected role: refused", made[(50, 1)][0] == "refused" and made[(52, 1)][0] == "refused", made)
    check("a Kick on someone not on: gone", made[(51, 1)][0] == "gone", made)
    # down: every pending call fails, and is answered so ZeD hands it to a staff game
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    dead = s.getsockname()[1]
    s.close()
    queue(d, EPOCH, [(60, 1, "Ban", "Kade", "x")])
    made, out = run(d, port=dead)
    check("the console down: failed, written", made[(60, 1)][0] == "failed" and "60\t1\tfailed\t" in answers(d), made)

# ---------------------------------------------------------------------------
# The password
# ---------------------------------------------------------------------------
with tempfile.TemporaryDirectory() as d:
    GAME.reset()
    queue(d, EPOCH, [(70, 1, "Ban", "Kade", "x")])
    err = None
    out = io.StringIO()
    try:
        with contextlib.redirect_stdout(out):
            H.run_once(d, "127.0.0.1", PORT, "wrong-" + PASSWORD, timeout=2.0)
    except H.AuthError as e:
        err = e
    check("a wrong password is refused by the console", err is not None and GAME.commands == [])
    check("and the message never holds it", err is not None and PASSWORD not in str(err) and PASSWORD not in out.getvalue())
    # main(): settings read from the server's file, the password never printed, exit 2 on a wrong one
    zom = os.path.join(d, "Zomboid")
    os.makedirs(os.path.join(zom, "Server"))
    os.makedirs(os.path.join(zom, "Lua", "ZeD_helper"))
    with open(os.path.join(zom, "Server", "test.ini"), "w") as f:
        f.write("RCONPort=%d\nRCONPassword=%s\n" % (PORT, PASSWORD))
    queue(os.path.join(zom, "Lua", "ZeD_helper"), EPOCH, [(80, 1, "Kick", "Kade", "")])
    out = io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
        code = H.main(["--zomboid", zom, "--server", "test", "--once"])
    check("main: one pass from the server's own settings", code == 0 and GAME.commands[-1] == 'kickuser "Kade"', (code, GAME.commands))
    check("main: the password is never printed", PASSWORD not in out.getvalue(), out.getvalue())
    check("main: nor written", PASSWORD not in answers(os.path.join(zom, "Lua", "ZeD_helper")))
    with open(os.path.join(zom, "Server", "test.ini"), "w") as f:
        f.write("RCONPort=%d\nRCONPassword=nope\n" % PORT)
    queue(os.path.join(zom, "Lua", "ZeD_helper"), EPOCH, [(81, 1, "Kick", "Torch", "")])
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = H.main(["--zomboid", zom, "--server", "test", "--once"])
    check("main: a wrong password exits 2", code == 2, code)
    with open(os.path.join(zom, "Server", "test.ini"), "w") as f:
        f.write("RCONPort=0\n")
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        code = H.main(["--zomboid", zom, "--server", "test", "--once"])
    check("main: no RCON set up exits 1", code == 1, code)

srv.shutdown()
print("zed_rcon_helper test: %d checks, %d failed" % (checks, failed))
sys.exit(1 if failed else 0)
