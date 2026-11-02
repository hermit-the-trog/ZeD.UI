# Checks the Compatibility thread v5: every v4 mod and every round 4 mod appears exactly once, in the list
# its data says, each list in alphabetical order; each post body under 7,800 characters; the first post's
# index and counts match the replies; no banned text, no test jargon, no exclamation mark in our own words.
# Run: py -3 -I check5.py (from anywhere). Exit code 0 = PASS.
import os, re, sys, json
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from r4notes import R4
NEW = os.path.dirname(HERE)
V4 = os.path.join(NEW, "..", "compat_v4", "build", "v4_mods.json")
LIMIT = 7800
ID = re.compile(r"sharedfiles/filedetails/\?id=(\d+)")
v4 = set(json.load(open(V4, encoding="utf-8")))
r4 = set(R4)
mods = json.load(open(os.path.join(HERE, "v5_mods.json"), encoding="utf-8"))
ok = True
def fail(msg):
    global ok
    ok = False
    print("  FAIL:", msg)

HEAD = {"Supported": "S", "Works well with ZeD": "W", "Compatible": "C", "Compatible: vehicle packs": "V",
        "Not needed with ZeD": "N", "Does not work with ZeD": "XZ", "Broken on 42.21 or 42.22 by themselves": "X"}
def head_list(h):
    if h.startswith("Compatible:"): return HEAD.get(h)
    if h.startswith("Compatible,"): return "C"
    return HEAD.get(re.sub(r" \(part \d+ of \d+\)$", "", h))

def skey(m):
    n = m["name"]
    if m["list"] == "V": n = re.sub(r"^'\d\d ", "", n)
    n = re.sub(r"^(\[[^\]]*\]\s*)+", "", n)
    n = re.sub(r"^42\.21 \| ", "", n)
    return n.lstrip("'").lower()

BANNED = ["·", "ZombieBuddy", "Java", "census", ".png", ".jpg", ".lua", ".cfg", ".txt", "zedqa", "ZeD bug",
          "(seen", "QA", "regression", "padmap", "Accessible", "accessible"]
files = sorted(f for f in os.listdir(NEW) if f.startswith("post"))
count, seq, heads = {}, {}, {}
for f in files:
    t = open(os.path.join(NEW, f), encoding="utf-8").read()
    body = (t.split("\n", 1)[1].lstrip("\n") if f.startswith("post00") else t).rstrip("\n")
    n = len(body)
    ids = ID.findall(body)
    print(f"{f:18} {n:5} chars  {len(ids):3} mods  {'OK' if n < LIMIT else 'TOO LONG'}")
    if n >= LIMIT: fail(f"{f} is {n} characters")
    for bad in BANNED:
        if bad in t: fail(f"banned text in {f}: {bad!r}")
    if re.search(r"\bscripts?\b", t, re.I): fail(f"'script' in {f}")
    if re.search(r"open[ -]source", t, re.I): fail(f"'open source' in {f}")
    for tag in ("list", "url", "b", "i", "h2"):
        if len(re.findall(r"\[%s[\]=]" % tag, t)) != t.count(f"[/{tag}]"): fail(f"unbalanced [{tag}] in {f}")
    # our own words: drop link texts, makers and mod names, then look for "!"
    prose = re.sub(r"\[url=[^\]]*\][^\[]*\[/url\]", "", t)
    for m in mods.values():
        for s in (m["name"], m["author"] or ""):
            if s: prose = prose.replace(s, "")
    if "!" in prose: fail(f"exclamation mark in {f}")
    # sections: which list each row is in
    cur = None
    for line in t.split("\n"):
        h = re.match(r"\[h2\](.*)\[/h2\]", line)
        if h:
            cur = head_list(h.group(1))
            if not f.startswith("post00"): heads.setdefault(f, []).append(cur)
            continue
        for i in ID.findall(line):
            count[i] = count.get(i, 0) + 1
            if f.startswith("post00"): fail(f"mod {i} listed in the first post"); continue
            if cur is None: fail(f"{f}: mod {i} outside a list heading"); continue
            if i in mods and mods[i]["list"] != cur: fail(f"{f}: {mods[i]['name']} is under {cur}, its data says {mods[i]['list']}")
            seq.setdefault(cur, []).append(i)

want = v4 | r4
missing = sorted(want - set(count)); dupes = sorted(i for i, c in count.items() if c > 1); extra = sorted(set(count) - want)
print(f"expected {len(want)} mods ({len(v4)} from v4, {len(r4)} new in round 4 and 0.2.0-t15); found {len(count)} in {len(files)} posts")
print("missing:", missing or "none"); print("twice or more:", dupes or "none"); print("not expected:", extra or "none")
if missing or dupes or extra: fail("mods missing, doubled or unexpected")

# alphabetical order inside each list, across its parts too (files are read in reply order)
for lst, ids in seq.items():
    keys = [skey(mods[i]) for i in ids]
    if keys != sorted(keys): fail(f"list {lst} is not in alphabetical order")
counts = {l: len(v) for l, v in seq.items()}
print("rows per list:", counts, "total", sum(counts.values()))

# round 4 verdicts that must hold
must = {"S": ["2871469707", "2854030563", "2923554542", "3410947298", "2914075159", "3789660055", "3819438691", "3760450908", "3779201168"],
        "XZ": ["3819012597", "3773911887", "3796139100"],
        "N": ["3423660713", "3567084868", "3809995878"]}
for l, ids in must.items():
    for i in ids:
        if mods[i]["list"] != l: fail(f"{mods[i]['name']} should be on {l}")
for i in ("3423660713", "3567084868", "3809995878"):
    if "Load before" not in mods[i]["note"]: fail(f"{mods[i]['name']}: Not needed reason lacks 0.2.0-t15's load order")
if "FieClaussell" not in open(os.path.join(NEW, "post01.txt"), encoding="utf-8").read(): fail("Mod Folders' maker not credited")

# first post: index, counts and dates
first = open(os.path.join(NEW, "post00_first.txt"), encoding="utf-8").read()
for s in ("Last updated Nov 2 2026", "Oct 29 2026, ZeD-GUI 0.2.0-t11", "Nov 2 2026, ZeD-GUI 0.2.0-t15", "To add a mod to the list", f"lists the {len(want)} mods"):
    if s not in first: fail(f"first post lacks {s!r}")
rep = {}
for f, hs in heads.items():
    rep[int(re.match(r"post(\d+)", f).group(1))] = hs
if 14 in rep: fail("a list file for reply 14, which stays as posted")
def nums(label):
    m = re.search(r"\[\*\]\[b\](Repl(?:y|ies) [^:]*): " + re.escape(label), first)
    if not m: fail(f"index lacks {label}"); return []
    return [int(x) for x in re.findall(r"\d+", m.group(1))]
for label, code in (("Supported", "S"), ("Works well with ZeD", "W"), ("Compatible[/b]", "C"), ("Compatible, vehicle packs", "V"),
                    ("Does not work", "XZ"), ("Not needed with ZeD", "N")):
    ns = nums(label)
    m = re.search(r"\[\*\]\[b\](Repl(?:y|ies) [^:]*): " + re.escape(label), first)
    if m and " to " in m.group(1): ns = list(range(ns[0], ns[-1] + 1))
    for r in ns:
        if code not in rep.get(r, []): fail(f"index says reply {r} holds {label}; it holds {rep.get(r)}")
    have = sorted(r for r, hs in rep.items() if code in hs)
    if have != sorted(ns): fail(f"{label}: index says replies {ns}, the files are {have}")
for code, label in (("S", "Supported"), ("W", "Works well"), ("C", "nothing special"), ("V", "vehicle packs"), ("N", "makers are credited there")):
    m = re.search(re.escape(label) + r"[^\n]*?\((\d+)(?: mods)?\)", first)
    if not m or int(m.group(1)) != counts.get(code): fail(f"first post count for {code}: {m and m.group(1)} vs {counts.get(code)}")
m = re.search(r"with why \((\d+)\), and mods broken on 42\.21 or 42\.22 by themselves \((\d+)\)", first)
if not m or (int(m.group(1)), int(m.group(2))) != (counts.get("XZ"), counts.get("X")): fail("first post counts for Does not work")
for r in range(1, max(rep) + 1):
    if r != 14 and r not in rep: fail(f"no file for reply {r}")
print("RESULT:", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
