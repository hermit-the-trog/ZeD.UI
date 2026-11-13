"""Kahlua guard (Nov 8 2026): the game's Lua (Kahlua) lacks functions real Lua 5.1 has, so a sim on real Lua can pass
code that fails in game. Beta 8 shipped three next() calls to QA that way. This scans ZeD's game Lua for calls to
globals Kahlua does not have and exits 1 if any are found. Run it with the sims: python -I kahlua_guard.py
--path DIR scans another folder of game Lua instead (the mods built from ZeD-GUI's files, products/<mod>/42/media/lua),
relative to the current folder or absolute."""
import os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "42", "media", "lua")
if "--path" in sys.argv:
    i = sys.argv.index("--path")
    if i + 1 >= len(sys.argv):
        print("kahlua_guard: --path needs a folder")
        sys.exit(2)
    ROOT = os.path.abspath(sys.argv[i + 1])
    if not os.path.isdir(ROOT):
        print("kahlua_guard: no folder %s" % ROOT)
        sys.exit(2)
MISSING = ["next"]   # add others as they are found (verify against the game first)
pat = re.compile(r"(?<![\w.:])(%s)\s*\(" % "|".join(MISSING))
bad = []
for d, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith(".lua"):
            continue
        p = os.path.join(d, f)
        for n, line in enumerate(open(p, encoding="utf-8", errors="replace"), 1):
            code = line.split("--", 1)[0]
            if pat.search(code):
                bad.append("%s:%d: %s" % (os.path.relpath(p, ROOT), n, line.strip()))
for b in bad:
    print("KAHLUA:", b)
print("RESULT:", "FAIL" if bad else "PASS")
sys.exit(1 if bad else 0)
