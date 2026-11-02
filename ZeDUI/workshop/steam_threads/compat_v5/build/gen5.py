# Builds the Compatibility thread v5 (Nov 2 2026): the v4 lists (compat_v4/build/v4_mods.json, 512 mods)
# plus compatibility round 4 (Oct 29 and Nov 2 2026) and the support added in ZeD-GUI 0.2.0-t11 and t15
# (notes in r4notes.py). Writes the posts to ZeDUI/workshop/steam_threads/compat_v5/ and v5_mods.json here.
# Run: py -3 -I gen5.py (from anywhere).
import json, os, re, sys
from functools import lru_cache
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from r4notes import R4, CHANGED
OUT = os.path.dirname(HERE)
V4 = os.path.join(OUT, "..", "compat_v4", "build", "v4_mods.json")
LIMIT = 7800
U = "https://steamcommunity.com/sharedfiles/filedetails/?id="
NREPLY = 14         # the thread has 14 replies; every list is edited into one of them, none added

mods = json.load(open(V4, encoding="utf-8"))
for wid, ch in CHANGED.items():
    assert wid in mods, wid
    mods[wid].update(ch)
for wid, (name, author, lst, note, link) in R4.items():
    assert wid not in mods, wid
    mods[wid] = dict(id=wid, name=name, author=author, list=lst, note=note, cr=(link, None), r4=True)

def skey(m):
    n = m["name"]
    if m["list"] == "V": n = re.sub(r"^'\d\d ", "", n)
    n = re.sub(r"^(\[[^\]]*\]\s*)+", "", n)
    n = re.sub(r"^42\.21 \| ", "", n)
    return n.lstrip("'").lower()

def fl(m):
    c = skey(m)[0]
    return "0" if not c.isalpha() else c

def credit_of(m):
    link, sup = m["cr"]
    if not link and m["author"]: link = m["author"]
    return link, sup

def row(m, credits=False):
    s = f"[*][url={U}{m['id']}]{m['name']}[/url]"
    if credits:
        link, sup = credit_of(m)
        if link: s += f" by {link}"
        if m["note"]: s += ": " + m["note"]
        if sup: s += f" Support: {sup}"
        return s
    if m["author"]: s += f" by {m['author']}"
    if m["note"]: s += ": " + m["note"]
    return s

def by(lst): return sorted([m for m in mods.values() if m["list"] == lst], key=skey)
S, W, Cs, V, N, XZ, X = (by(l) for l in ("S", "W", "C", "V", "N", "XZ", "X"))
def L(ms, credits=False): return "[list]\n" + "\n".join(row(m, credits) for m in ms) + "\n[/list]"

# split a sorted list into the fewest parts that fit; then fewest cuts inside a letter; then as even as can be
def split(ms, room, credits=False):
    rm = room if callable(room) else (lambda k: room)
    ln = [len(row(m, credits)) + 1 for m in ms]
    pre = [0]
    for x in ln: pre.append(pre[-1] + x)
    n = len(ms)
    def mid(i): return 1 if 0 < i < n and fl(ms[i]) == fl(ms[i - 1]) else 0
    @lru_cache(None)
    def best(i, k=0):   # (parts, mid-letter cuts, worst size, cuts) for ms[i:], starting with part k
        if pre[n] - pre[i] <= rm(k): return (1, 0, pre[n] - pre[i], (n,))
        out = None
        for j in range(i + 1, n):
            if pre[j] - pre[i] > rm(k): break
            r = best(j, k + 1)
            if r is None: continue
            p, c, w, cs = r
            cand = (p + 1, c + mid(j), max(w, pre[j] - pre[i]), (j,) + cs)
            if out is None or cand[:3] < out[:3]: out = cand
        return out
    cs = (0,) + best(0)[3]
    return [ms[cs[k]:cs[k + 1]] for k in range(len(cs) - 1)]

def key2(m): return re.sub(r"[^a-z0-9]", "", skey(m))
CP = split(Cs, LIMIT - 650)
CR = []
for k, part in enumerate(CP):
    a, b = key2(part[0]), key2(part[-1])
    prev = key2(CP[k - 1][-1]) if k else ""
    nxt = key2(CP[k + 1][0]) if k + 1 < len(CP) else ""
    sa = a[0] if not prev or prev[0] != a[0] else a[:2]
    sb = b[0] if not nxt or nxt[0] != b[0] else b[:2]
    if k == 0 and sa.isdigit(): sa = "0-9"
    if k + 1 == len(CP): sb = "z"
    CR.append(f"{sa[0].upper() + sa[1:]} to {sb[0].upper() + sb[1:]}")
N_INTRO = """ZeD-GUI already does the job of these mods, so use one of the two. Most still load with ZeD-GUI on; the part that does the same job does not show.

ZeD-GUI does not take donations. If ZeD-GUI does the job of a mod you used and you want to give something back, give it to the person who made that mod. They worked these problems out first, and some of them do this to put food on the table. Where no support link is listed, the maker's Steam page is linked where known.
"""
NP = split(N, lambda k: LIMIT - len(N_INTRO) - 64 if k == 0 else LIMIT - 86, credits=True)   # only part 1 carries the long intro

# reply numbers: the lists fill replies 1 to 14 in place; Does not work sits in the first post
blocks = ["S", "W"] + [("C", k) for k in range(len(CP))] + ["V"] + [("N", k) for k in range(len(NP))]
where, rep = {}, 1
for b in blocks:
    if isinstance(b, tuple): where.setdefault(b[0], []).append(rep)
    else: where[b] = rep
    rep += 1
NREPLIES = rep - 1
assert NREPLIES == NREPLY, ("the lists must fill exactly the 14 replies", NREPLIES, where)
def rr(ns):
    if len(ns) == 1: return f"Reply {ns[0]}"
    if len(ns) == 2: return f"Replies {ns[0]} and {ns[1]}"
    return f"Replies {ns[0]} to {ns[-1]}"
cparts = ", ".join(f"{CR[k]} (reply {where['C'][k]})" for k in range(len(CP)))

COMPAT_INTRO = "Loaded with ZeD-GUI, no errors of their own, and ZeD-GUI's tests passed with them on. Nothing special to say unless a note says so. A note that starts \"Part of it does not show\" means the mod adds to a game screen that ZeD-GUI replaces."

posts = {}
XPOST = f"""[h2]Does not work with ZeD[/h2]
These do a job ZeD-GUI also does, in a way that clashes with it: both draw at once, or ZeD's screen replaces the one the mod changes. Run one or the other.
{L(XZ)}

[h2]Broken on 42.21 or 42.22 by themselves[/h2]
These are broken on Project Zomboid 42.21 or 42.22 by themselves, with or without ZeD-GUI. Found a mod that clashes with ZeD-GUI? Reply with its name, its Workshop link and what happened.
{L(X)}
""".rstrip()
posts["post00_first"] = f"""TITLE: Compatibility with other mods

This thread lists the {len(mods)} mods tested with ZeD-GUI, sorted into five lists. Each list is in alphabetical order. Last updated Nov 2 2026.

[h2]Where each list is[/h2]
Steam cannot link to a reply, so count the replies from the top of the thread.
[list]
[*][b]Reply {where['S']}: Supported.[/b] ZeD-GUI has its own support for the mod, so its features show in ZeD's windows ({len(S)} mods).
[*][b]Reply {where['W']}: Works well with ZeD.[/b] The mod fills a gap or shows well in ZeD's windows; worth having ({len(W)}).
[*][b]{rr(where['C'])}: Compatible[/b], in {len(CP)} parts: {cparts}. Loads and works with ZeD-GUI, nothing special ({len(Cs)}).
[*][b]Reply {where['V']}: Compatible, vehicle packs[/b] ({len(V)}).
[*][b]{rr(where['N'])}: Not needed with ZeD.[/b] ZeD-GUI already does the job, so use one of the two; the makers are credited there ({len(N)}).
[*][b]This post, below: Does not work.[/b] Two lists: mods that do not work with ZeD-GUI, with why ({len(XZ)}), and mods broken on 42.21 or 42.22 by themselves ({len(X)}).
[/list]

{XPOST}

[h2]How the mods were tested[/h2]
[list]
[*]Project Zomboid 42.21 (42.22 from Oct 29), single player, ZeD-GUI loaded after the other mods. Every error in the game's log was checked for the mod that made it, with ZeD-GUI off as well when it might be ZeD's.
[*]Oct 24 2026, ZeD-GUI 0.2.0-t3 and t4, a 1920x1080 window: 124 Workshop items (128 mods) on at once, then ZeD-GUI's own tests; 62 of the 66 that ran passed as they do without other mods.
[*]Oct 25 2026, ZeD-GUI 0.2.0-t5, 3840x2160 at UI scale 1.75: 48 more mods on at once with ZeD-GUI's whole test run, and 37 vehicle packs, their cars spawned and driven one by one.
[*]Oct 26 2026, ZeD-GUI 0.2.0-t6, 3840x2160: each mod ZeD-GUI supports, on by itself, with ZeD-GUI's tests for that support. Then 302 more mods in eight groups of 26 to 42, each group on at once with ZeD-GUI's tests for the screens it touches; the group's own windows opened, the item tooltip compared with and without ZeD-GUI, and new vehicle packs driven. Last, ZeD-GUI's whole test run with that round's Compatible and Works well mods, about 150 at a time.
[*]Oct 29 2026, ZeD-GUI 0.2.0-t11, 3840x2160 at UI scale 1.75: 34 popular Build 42 mods not yet on the list were picked, and the first of them tested in groups, each group on at once with ZeD-GUI's tests for every window, the item menu, the controller, the dashboard, the map and the moodles. The seven mods that ZeD-GUI 0.2.0-t11 supports were each tested with a check of that support in ZeD's windows.
[*]Nov 2 2026, ZeD-GUI 0.2.0-t15, 3840x2160: the rest of those mods, 20 on at once with the same tests, and the main menu walked through Mods, Options, Spawn, Sandbox, Traits and Looks.
[*]Nov 2 2026, ZeD-GUI 0.2.0-t15: nine more mods from the Workshop's trending Build 42 lists since Oct 29, on at once with the same tests, twice.
[*]Each mod's own features were [b]not[/b] tried one by one. A note marked [i](expected)[/i] comes from how the mod works, and one marked [i](by reading its code)[/i] from its code, not from a test.
[/list]

[h2]Help in ZeD-GUI for long mod lists[/h2]
[list]
[*]Notes and errors other mods show at game start go into ZeD-GUI's Messages window instead of covering the game.
[*]In Mods, a mod's About tab says what turning it off does to a save. In a save's own mod list, turning off a mod that is not safe asks first.
[*]When two mods ship the same code file, the Conflicts tab can pick whose copy the game runs, file by file (single player).
[*]From 0.2.0-t15 the load order has Find, Load first and Load last, and Load after... and Load before... rules that Auto keeps; separators name and fold a block of mods. The Mods page has folders, shared with [B42]Mod Folders.
[/list]

[h2]To add a mod to the list[/h2]
Reply with the mod's name, its Workshop link, the ZeD-GUI version, and what happened: it works, part of it does not show (say which), or it does not work. For an error, the Bug reports thread says what to include.
"""

posts[f"post{where['S']:02d}"] = f"""[h2]Supported[/h2]
ZeD-GUI has its own support for these mods: their features show in ZeD's windows. Each support turns on only while that mod is on; ZeD's folders, which share [B42]Mod Folders' file, are always there.
{L(S)}
"""

posts[f"post{where['W']:02d}"] = f"""[h2]Works well with ZeD[/h2]
These fill a gap or show well in ZeD's windows. ZeD-GUI has no code of its own for them.
{L(W)}
"""

for k, part in enumerate(CP):
    posts[f"post{where['C'][k]:02d}"] = f"""[h2]Compatible, {CR[k]} (part {k + 1} of {len(CP)})[/h2]
{COMPAT_INTRO} The first post says which reply holds each part; vehicle packs are in reply {where['V']}.
{L(part)}
"""

posts[f"post{where['V']:02d}"] = f"""[h2]Compatible: vehicle packs[/h2]
Sorted by make, then model. Each pack's cars were spawned and driven one by one: ZeD's dashboard shows on each (a generic design, as for any car ZeD has no drawing of) and its Vehicle tab lists every part. The '85 Chevrolet Step-Van and the '93 Elgin Street Sweeper were on in the Oct 24 test and not driven. U.S. M113 APC: its Vehicle tab works; its dashboard was not checked (the test could not seat a driver in it).
{L(V)}
"""

for k, part in enumerate(NP):
    head = f"[h2]Not needed with ZeD (part {k + 1} of {len(NP)})[/h2]\n" if len(NP) > 1 else "[h2]Not needed with ZeD[/h2]\n"
    intro = N_INTRO if k == 0 else f"Part {k} is in reply {where['N'][k - 1]}.\n"
    posts[f"post{where['N'][k]:02d}"] = head + intro + L(part, credits=True) + "\n"


os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    if f.startswith("post"): os.remove(os.path.join(OUT, f))
for k, v in posts.items():
    open(os.path.join(OUT, k + ".txt"), "w", encoding="utf-8", newline="\n").write(v.rstrip("\n") + "\n")
json.dump(mods, open(os.path.join(HERE, "v5_mods.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
json.dump(dict(where=where, replies=NREPLIES, compatible_parts=CR), open(os.path.join(HERE, "v5_layout.json"), "w", encoding="utf-8"), indent=1)
print("compatible parts", CR, [len(x) for x in CP], "not needed parts", [len(x) for x in NP], "replies", NREPLIES)
print("where", where)
print({l: sum(1 for m in mods.values() if m["list"] == l) for l in ("S", "W", "C", "V", "N", "XZ", "X")}, "total", len(mods))
for k, v in sorted(posts.items()):
    body = v.split("\n", 1)[1].lstrip("\n") if k == "post00_first" else v
    print(k, len(body.rstrip("\n")))
