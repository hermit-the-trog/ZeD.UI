# Checks the Compatibility thread v7 (v6 in the director's order: Supported in the first post, Does not work and Broken
# in reply 14) against v5's data: every mod appears exactly once, in the list its data says,
# each list in alphabetical order across its parts, each row under the heading of its own letter, each post under
# 7,800 characters as a web page counts them, the first post's index and counts match the replies, the tags balance,
# the lists in the order S, W, C, V, N, XZ, X, the words v6's (line for line, the index aside),
# and no banned text or exclamation mark in our own words. Run: py -3 -I check7.py. Exit code 0 = PASS.
import json, os, re, sys
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
NEW = os.path.dirname(HERE)
LIMIT = 7800
ID = re.compile(r"sharedfiles/filedetails/\?id=(\d+)")
mods = json.load(open(os.path.join(NEW, "..", "compat_v5", "build", "v5_mods.json"), encoding="utf-8"))
ok = True


def fail(msg):
    global ok
    ok = False
    print("  FAIL:", msg)


def ulen(s): return len(s.encode("utf-16-le")) // 2


EMOJI = re.compile(r"^[^\w\[(]+\s")          # an emoji (and its variation selector) and a space, before a heading or index item
HEAD = {"Supported": "S", "Works well with ZeD": "W", "Compatible: vehicle packs": "V", "Not needed with ZeD": "N",
        "Does not work with ZeD": "XZ", "Broken on 42.21 or 42.22 by themselves": "X"}


def head_list(h):
    h = EMOJI.sub("", h)
    if h.startswith("Compatible,"): return "C"
    return HEAD.get(re.sub(r" \(part \d+ of \d+\)$", "", h), "other")


def skey(m):
    n = m["name"]
    if m["list"] == "V": n = re.sub(r"^'\d\d ", "", n)
    n = re.sub(r"^(\[[^\]]*\]\s*)+", "", n)
    n = re.sub(r"^42\.21 \| ", "", n)
    return n.lstrip("'").lower()


def letter(m):
    c = skey(m)[0]
    return "0-9 and symbols" if not c.isalpha() else c.upper()


BANNED = ["·", "ZombieBuddy", "Java", "census", ".png", ".jpg", ".lua", ".cfg", ".txt", "zedqa", "ZeD bug",
          "(seen", "QA", "regression", "padmap", "Accessible", "accessible"]
files = sorted(f for f in os.listdir(NEW) if f.startswith("post"))
count, seq, heads, order = {}, {}, {}, []
for f in files:
    t = open(os.path.join(NEW, f), encoding="utf-8").read()
    body = (t.split("\n", 1)[1].lstrip("\n") if f.startswith("post00") else t).rstrip("\n")
    n = ulen(body)
    ids = ID.findall(body)
    print(f"{f:18} {n:5} chars  {len(ids):3} mods  {'OK' if n < LIMIT else 'TOO LONG'}")
    if n >= LIMIT: fail(f"{f} is {n} characters")
    for bad in BANNED:
        if bad in t: fail(f"banned text in {f}: {bad!r}")
    if re.search(r"\bscripts?\b", t, re.I): fail(f"'script' in {f}")
    if re.search(r"open[ -]source", t, re.I): fail(f"'open source' in {f}")
    for tag in ("list", "url", "b", "i", "h2", "h3"):
        if len(re.findall(r"\[%s[\]=]" % tag, t)) != t.count(f"[/{tag}]"): fail(f"unbalanced [{tag}] in {f}")
    if re.search(r"\[list\]\s*\[/list\]", t): fail(f"an empty list in {f}")
    prose = re.sub(r"\[url=[^\]]*\][^\[]*\[/url\]", "", t)
    for m in mods.values():
        for s in (m["name"], m["author"] or ""):
            if s: prose = prose.replace(s, "")
    if "!" in prose: fail(f"exclamation mark in {f}")
    cur, let = None, None
    for line in t.split("\n"):
        h = re.match(r"\[h2\](.*)\[/h2\]", line)
        if h:
            cur, let = head_list(h.group(1)), None
            if cur != "other":
                heads.setdefault(f, []).append(cur)
                if not order or order[-1] != cur: order.append(cur)
            continue
        h3 = re.match(r"\[h3\](.*)\[/h3\]", line)
        if h3:
            let = re.sub(r", continued$", "", h3.group(1))
            continue
        for i in ID.findall(line):
            count[i] = count.get(i, 0) + 1
            if i not in mods: fail(f"{f}: mod {i} is not in v5's data"); continue
            if f.startswith("post00") and cur != "S": fail(f"mod {i} in the first post outside Supported"); continue
            if cur in (None, "other"): fail(f"{f}: mod {i} outside a list heading"); continue
            if mods[i]["list"] != cur: fail(f"{f}: {mods[i]['name']} is under {cur}, its data says {mods[i]['list']}")
            if let is not None and letter(mods[i]) != let: fail(f"{f}: {mods[i]['name']} is under the letter {let}")
            seq.setdefault(cur, []).append(i)

want = set(mods)
missing = sorted(want - set(count)); dupes = sorted(i for i, c in count.items() if c > 1); extra = sorted(set(count) - want)
print(f"expected {len(want)} mods; found {len(count)} in {len(files)} posts")
print("missing:", missing or "none"); print("twice or more:", dupes or "none"); print("not expected:", extra or "none")
if missing or dupes or extra: fail("mods missing, doubled or unexpected")
for lst, ids in seq.items():
    keys = [skey(mods[i]) for i in ids]
    if keys != sorted(keys): fail(f"list {lst} is not in alphabetical order")
counts = {l: len(v) for l, v in seq.items()}
print("rows per list:", counts, "total", sum(counts.values()))

# each letter heading appears once per list (a letter cut between replies is marked continued), in order
for f in files:
    t = open(os.path.join(NEW, f), encoding="utf-8").read()
    hs = re.findall(r"\[h3\](.*?)\[/h3\]", t)
    plain = [re.sub(r", continued$", "", h) for h in hs]
    if len(plain) != len(set(plain)): fail(f"{f}: a letter heading twice")
    if any(h.endswith(", continued") for h in hs[1:]): fail(f"{f}: 'continued' on a heading that is not the first")

first = open(os.path.join(NEW, "post00_first.txt"), encoding="utf-8").read()
notes = open(os.path.join(NEW, "post01.txt"), encoding="utf-8").read()     # (the notes follow Works well in reply 1)
for s in ("Last updated Nov 2 2026", f"lists the {len(want)} mods"):
    if s not in first: fail(f"first post lacks {s!r}")
for s in ("Oct 29 2026, ZeD-GUI 0.2.0-t11", "Nov 2 2026, ZeD-GUI 0.2.0-t15", "To add a mod to the list"):
    if s not in notes: fail(f"reply 1 lacks {s!r}")
rep = {int(re.match(r"post(\d+)", f).group(1)): hs for f, hs in heads.items()}
if sorted(rep) != list(range(0, 15)): fail(f"the lists must fill the first post and replies 1 to 14 exactly, they fill {sorted(rep)}")
print("order:", order)
if order != ["S", "W", "C", "V", "N", "XZ", "X"]: fail(f"the lists run {order}")
if rep.get(0) != ["S"] or rep.get(14) != ["XZ", "X"]: fail(f"first post {rep.get(0)}, reply 14 {rep.get(14)}")
if "[b]This post, below: Supported.[/b]" not in first: fail("index lacks Supported in this post")
if "[b]Reply 14: Does not work.[/b]" not in first: fail("index lacks Does not work in reply 14")
IDX = r"\[\*\](?:[^\[\n]+ )?\[b\](Repl(?:y|ies) [^:]*): "
for label, code in (("Works well with ZeD", "W"), ("Compatible[/b]", "C"), ("Compatible, vehicle packs", "V"),
                    ("Not needed with ZeD", "N")):
    m = re.search(IDX + re.escape(label), first)
    if not m: fail(f"index lacks {label}"); continue
    ns = [int(x) for x in re.findall(r"\d+", m.group(1))]
    if " to " in m.group(1): ns = list(range(ns[0], ns[-1] + 1))
    have = sorted(r for r, hs in rep.items() if code in hs)
    if have != sorted(ns): fail(f"{label}: index says replies {ns}, the files are {have}")
for code, label in (("S", "Supported"), ("W", "Works well"), ("C", "nothing special"), ("V", "vehicle packs"), ("N", "makers are credited there")):
    m = re.search(re.escape(label) + r"[^\n]*?\((\d+)(?: mods)?\)", first)
    if not m or int(m.group(1)) != counts.get(code): fail(f"first post count for {code}: {m and m.group(1)} vs {counts.get(code)}")
m = re.search(r"with why \((\d+)\), and mods broken on 42\.21 or 42\.22 by themselves \((\d+)\)", first)
if not m or (int(m.group(1)), int(m.group(2))) != (counts.get("XZ"), counts.get("X")): fail("first post counts for Does not work")
from collections import Counter
v6 = os.path.join(NEW, "..", "compat_v6")
def lines(d):
    c = Counter()
    for f in sorted(x for x in os.listdir(d) if x.startswith("post")):
        for l in open(os.path.join(d, f), encoding="utf-8").read().split(chr(10)):
            if not l.strip() or re.match(r"^\[\*\]\S+ \[b\]", l): continue
            l = re.sub(r"(?i)\b(repl(?:y|ies)) \d+", "reply N", l).replace(" The Compatible lists have a heading for each letter.", "")
            c[l] += 1
    return c
a, b = lines(NEW), lines(v6)
gone, new = b - a, a - b
print("lines only in v6:", sum(gone.values()), "| only in v7:", sum(new.values()))
for l in gone: print("  v6:", l[:150])
for l in new: print("  v7:", l[:150])
if sum(gone.values()) or sum(new.values()): fail("the words differ from v6's outside the index")
print("RESULT:", "PASS" if ok else "FAIL")
sys.exit(0 if ok else 1)
