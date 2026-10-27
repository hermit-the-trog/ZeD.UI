# Checks the Compatibility thread v4: every v3 mod and every round 3 mod appears exactly once,
# each post body is under 7,800 characters, and no banned text is left.
import os, re, sys, json
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
NEW = r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\workshop\steam_threads\compat_v4"
LIMIT = 7800
ID = re.compile(r"sharedfiles/filedetails/\?id=(\d+)")
v3 = set(json.load(open(os.path.join(HERE, "v3_mods.json"), encoding="utf-8")))
r3 = set(json.load(open(os.path.join(HERE, "r3.json"), encoding="utf-8")))
files = sorted(f for f in os.listdir(NEW) if f.startswith("post"))
count, ok = {}, True
for f in files:
    t = open(os.path.join(NEW, f), encoding="utf-8").read()
    body = (t.split("\n", 1)[1].lstrip("\n") if f.startswith("post00") else t).rstrip("\n")
    n = len(body)
    ids = ID.findall(body)
    print(f"{f:18} {n:5} chars  {len(ids):3} mods  {'OK' if n < LIMIT else 'TOO LONG'}")
    if n >= LIMIT: ok = False
    for bad in ("\u00b7", "ZombieBuddy", "Java", "census", ".png", ".jpg", "zedqa", "ZeD bug", "(seen"):
        if bad in t: print("  banned text in", f, repr(bad)); ok = False
    if t.count("[list]") != t.count("[/list]") or t.count("[url=") != t.count("[/url]"): print("  unbalanced tags in", f); ok = False
    for i in ids: count[i] = count.get(i, 0) + 1
want = v3 | r3
missing = sorted(want - set(count)); dupes = sorted(i for i, c in count.items() if c > 1); extra = sorted(set(count) - want)
print(f"expected {len(want)} mods ({len(v3)} from v3, {len(r3)} from round 3); found {len(count)} in {len(files)} posts")
print("missing:", missing or "none"); print("twice or more:", dupes or "none"); print("not expected:", extra or "none")
if missing or dupes or extra: ok = False
print("RESULT:", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
