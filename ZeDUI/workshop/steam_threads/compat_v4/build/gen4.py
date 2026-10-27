# Builds the Compatibility thread v4 (Oct 27 2026): the v3 lists (gen.py) plus compatibility round 3
# (302 mods, Oct 26 2026, r3.json from r3parse.py, notes in r3notes.py) and the fixes made after it (0.2.0-t7).
# Writes to ZeDUI/workshop/steam_threads/compat_v4/.
import json, os, re, sys
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(HERE)
exec(open(os.path.join(HERE, "gen.py"), encoding="utf-8").read().split("posts = {}")[0])
from r3notes import N3, T7
OUT = r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\workshop\steam_threads\compat_v4"
LIMIT = 7800

# v3 notes that changed with 0.2.0-t6 / t7
HAIR = "Its cuts, ties and trims are rows in the Identity tab's Hair and Beard section. From ZeD-GUI 0.2.0-t6."
mods["3589548354"]["note"] = HAIR
mods["3760534563"]["note"] = HAIR
mods["3378285185"]["note"] = f"Lines that mods add to the item tooltip through it show on ZeD's item tooltip from ZeD-GUI {T7}; in 0.2.0-t6 ZeD's tooltip leaves them out."

# round 3
r3 = json.load(open("r3.json", encoding="utf-8"))
creators = json.load(open("r3_creators.json", encoding="utf-8"))
item_authors = json.load(open("r3_item_authors.json", encoding="utf-8"))   # Steam's creators, by item
LIST = {"Compatible": "C", "Works well": "W", "Not needed": "N", "Does not work": "X"}
R3NAME = {}
for wid, r in r3.items():
    assert wid not in mods, wid
    lst, note = N3.get(wid, (LIST[r["list"]], ""))
    if wid not in N3: assert lst == "C", (wid, r["name"], r["list"])
    sid = creators.get(wid)
    a = item_authors.get(wid) or None
    link = f"[url=https://steamcommunity.com/profiles/{sid}]{a.split(' and ')[0] if a else 'the maker'}[/url]"
    mods[wid] = dict(id=wid, name=r["name"].strip(), author=a, list=lst, note=note, cr=(link, None), r3=True)
for wid in N3: assert wid in r3, wid

def by(lst): return sorted([m for m in mods.values() if m["list"] == lst], key=skey)
S, W, Cs, V, N, X = (by(l) for l in "SWCVNX")
def L(ms, credits=False): return "[list]\n" + "\n".join(row(m, credits) for m in ms) + "\n[/list]"

# split a sorted list into the fewest parts that fit; then fewest cuts inside a letter; then as even as can be
from functools import lru_cache
def split(ms, room, credits=False):
    ln = [len(row(m, credits)) + 1 for m in ms]
    pre = [0]
    for x in ln: pre.append(pre[-1] + x)
    n = len(ms)
    def mid(i): return 1 if 0 < i < n and fl(ms[i]) == fl(ms[i - 1]) else 0
    @lru_cache(None)
    def best(i):   # (parts, mid-letter cuts, worst size, cuts) for ms[i:]
        if pre[n] - pre[i] <= room: return (1, 0, pre[n] - pre[i], (n,))
        out = None
        for j in range(i + 1, n):
            if pre[j] - pre[i] > room: break
            p, c, w, cs = best(j)
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
NP = split(N, LIMIT - 760, credits=True)

# reply numbers
rep = 1
where = {"SW": rep}; rep += 1
where["C"] = list(range(rep, rep + len(CP))); rep += len(CP)
where["V"] = rep; rep += 1
where["N"] = list(range(rep, rep + len(NP))); rep += len(NP)
where["X"] = rep; rep += 1
NREPLIES = rep - 1
def rr(ns): return f"Reply {ns[0]}" if len(ns) == 1 else (f"Replies {ns[0]} and {ns[1]}" if len(ns) == 2 else f"Replies {ns[0]} to {ns[-1]}")
cparts = ", ".join(f"{CR[k]} (reply {where['C'][k]})" for k in range(len(CP)))

COMPAT_INTRO = "Loaded with ZeD-GUI, no errors of their own, and ZeD-GUI's tests passed with them on. Nothing special to say unless a note says so. A note that starts \"Part of it does not show\" means the mod adds to a game screen that ZeD-GUI replaces."

posts = {}
posts["post00_first"] = f"""TITLE: Compatibility with other mods

This thread lists the {len(mods)} mods tested with ZeD-GUI, sorted into five lists. Each list is in alphabetical order. Last updated Oct 27 2026.

[h2]Where each list is[/h2]
Steam cannot link to a reply, so count the replies from the top of the thread.
[list]
[*][b]Reply {where['SW']}: Supported, and Works well with ZeD.[/b] Supported: ZeD-GUI has its own support for the mod, so its features show in ZeD's windows ({len(S)} mods). Works well: the mod fills a gap or shows well in ZeD's windows; worth having ({len(W)}).
[*][b]{rr(where['C'])}: Compatible[/b], in {len(CP)} parts: {cparts}. Loads and works with ZeD-GUI, nothing special ({len(Cs)}).
[*][b]Reply {where['V']}: Compatible, vehicle packs[/b] ({len(V)}).
[*][b]{rr(where['N'])}: Not needed with ZeD.[/b] ZeD-GUI already does the job, so use one of the two; the makers are credited there ({len(N)}).
[*][b]Reply {where['X']}: Does not work.[/b] No mod tested so far clashes with ZeD-GUI; these are broken on 42.21 by themselves ({len(X)}).
[/list]

[h2]How the mods were tested[/h2]
[list]
[*]Project Zomboid 42.21, single player, ZeD-GUI loaded after the other mods. Every error in the game's log was checked for the mod that made it, with ZeD-GUI off as well when it might be ZeD's.
[*]Oct 24 2026, ZeD-GUI 0.2.0-t3 and t4, a 1920x1080 window: 124 Workshop items (128 mods) on at once, then ZeD-GUI's own tests; 62 of the 66 that ran passed as they do without other mods.
[*]Oct 25 2026, ZeD-GUI 0.2.0-t5, 3840x2160 at UI scale 1.75: 48 more mods on at once with ZeD-GUI's whole test run, and 37 vehicle packs, their cars spawned and driven one by one.
[*]Oct 26 2026, ZeD-GUI 0.2.0-t6, 3840x2160: each mod ZeD-GUI supports, on by itself, with ZeD-GUI's tests for that support. Then 302 more mods in eight groups of 26 to 42, each group on at once with ZeD-GUI's tests for the screens it touches; the group's own windows opened, the item tooltip compared with and without ZeD-GUI, and new vehicle packs driven. Last, ZeD-GUI's whole test run with that round's Compatible and Works well mods, about 150 at a time.
[*]Each mod's own features were [b]not[/b] tried one by one. A note marked [i](expected)[/i] comes from how the mod works, and one marked [i](by reading its code)[/i] from its code, not from a test.
[/list]

[h2]Found in the Oct 26 tests, fixed for ZeD-GUI {T7}[/h2]
[list]
[*]Lines other mods add to the item tooltip (Starlit Library, More Item Information, Show Sowing Season, This Is Me, Brita's Armor Pack) were left out of ZeD's tooltip. They show now.
[*]A mod that adds its own page to the game's Options (True Music Jukebox, Combat Text) emptied ZeD setup of ZeD's own options. ZeD setup is whole again, and the mod's page is listed after the game's Mods page.
[*]Smart Radial Menu errored and drew no wheel. A mod's own wheel now stays the game's; the game's own wheels stay ZeD's.
[*]A mod's belt slot (Brita's) showed its raw id, running out of its box. The belt uses the slot's own name, cut to fit.
[*]With Neat Rocco's UI on, other mods' notes stayed on screen instead of going to Messages. They go to Messages again (the two mods still do the same job: use one).
[/list]
Not ZeD-GUI's: with Project Writing on, the game seemed to hang after writing in a notebook. The mod pauses the game while its notebook is open (its own option), and a quit waits until the notebook is closed.

[h2]Help in ZeD-GUI for long mod lists[/h2]
[list]
[*]Notes and errors other mods show at game start go into ZeD-GUI's Messages window instead of covering the game.
[*]In Mods, a mod's About tab says what turning it off does to a save. In a save's own mod list, turning off a mod that is not safe asks first.
[*]When two mods ship the same code file, the Conflicts tab can pick whose copy the game runs, file by file (single player).
[/list]

[h2]To add a mod to the list[/h2]
Reply with the mod's name, its Workshop link, the ZeD-GUI version, and what happened: it works, part of it does not show (say which), or it does not work. For an error, the Bug reports thread says what to include.
"""

posts["post01"] = f"""[h2]Supported[/h2]
ZeD-GUI has its own support for these mods: their features show in ZeD's windows. Each support turns on only while that mod is on.
{L(S)}

[h2]Works well with ZeD[/h2]
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
    intro = """ZeD-GUI already does the job of these mods, so use one of the two. Most still load with ZeD-GUI on; the part that does the same job does not show.

ZeD-GUI does not take donations. If ZeD-GUI does the job of a mod you used and you want to give something back, give it to the person who made that mod. They worked these problems out first, and some of them do this to put food on the table. Where no support link is listed, the maker's Steam page is linked where known; many keep theirs there.
""" if k == 0 else f"Part {k} is in reply {where['N'][k - 1]}.\n"
    posts[f"post{where['N'][k]:02d}"] = head + intro + L(part, credits=True) + "\n"

posts[f"post{where['X']:02d}"] = f"""[h2]Does not work[/h2]
No mod tested so far clashes with ZeD-GUI (something happening twice, or one undoing the other). These are broken on Project Zomboid 42.21 by themselves, with or without ZeD-GUI. Found a mod that clashes? Reply with its name, its Workshop link and what happened.
{L(X)}
"""

os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    if f.startswith("post"): os.remove(os.path.join(OUT, f))
for k, v in posts.items():
    open(os.path.join(OUT, k + ".txt"), "w", encoding="utf-8", newline="\n").write(v.rstrip("\n") + "\n")
json.dump(mods, open(os.path.join(HERE, "v4_mods.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("compatible parts", CR, [len(x) for x in CP], "not needed parts", [len(x) for x in NP], "replies", NREPLIES)
print({l: sum(1 for m in mods.values() if m["list"] == l) for l in "SWCVNX"}, "total", len(mods))
print("no author:", sum(1 for m in mods.values() if not m["author"]))
for k, v in sorted(posts.items()):
    body = v.split("\n", 1)[1].lstrip("\n") if k == "post00_first" else v
    print(k, len(body.rstrip("\n")))
