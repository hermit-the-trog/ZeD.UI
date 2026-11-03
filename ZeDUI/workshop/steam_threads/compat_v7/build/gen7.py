# Builds the Compatibility thread v7 (Nov 2 2026): v6's layout and words, in the director's order: Supported first (in the
# first post, under the index), then Works well, Compatible, vehicle packs, Not needed, and Does not work then Broken last
# (reply 14). How the mods were tested, the help and how to add a mod follow Works well in reply 1. (v6's header:) The
# same 559 mods, the same words, laid out to scan. An emoji marks each list; the long lists (Compatible,
# vehicle packs, Not needed) get a heading for each letter; a warning sign marks the notes that say part of a mod does
# not show. Writes the posts to ZeDUI/workshop/steam_threads/compat_v7/. Run: py -3 -I gen7.py, then py -3 -I check7.py.
import json, os, re, sys
from functools import lru_cache
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)
V5 = os.path.join(OUT, "..", "compat_v5", "build", "v5_mods.json")
LIMIT = 7800          # per post, counted as a web page counts text: an emoji beyond the basic plane is two
U = "https://steamcommunity.com/sharedfiles/filedetails/?id="
NREPLY = 14           # the thread has 14 replies; every list is edited into one of them, none added


def ulen(s): return len(s.encode("utf-16-le")) // 2


mods = json.load(open(V5, encoding="utf-8"))
E = dict(S="✅", W="⭐", C="👍", V="🚗", N="🤝", XZ="❌", X="🐛",
         where="📋", tested="🧪", help="🧰", add="📝", warn="⚠️")


def skey(m):
    n = m["name"]
    if m["list"] == "V": n = re.sub(r"^'\d\d ", "", n)
    n = re.sub(r"^(\[[^\]]*\]\s*)+", "", n)
    n = re.sub(r"^42\.21 \| ", "", n)
    return n.lstrip("'").lower()


def fl(m):
    c = skey(m)[0]
    return "0" if not c.isalpha() else c


def label(c): return "0-9 and symbols" if c == "0" else c.upper()


def credit_of(m):
    link, sup = m["cr"]
    if not link and m["author"]: link = m["author"]
    return link, sup


WARN = re.compile(r"^Part of it (does|may) not show")


def note_of(m):
    n = m["note"]
    return f"{E['warn']} {n}" if n and WARN.match(n) else n


def row(m, credits=False):
    s = f"[*][url={U}{m['id']}]{m['name']}[/url]"
    if credits:
        link, sup = credit_of(m)
        if link: s += f" by {link}"
        if m["note"]: s += ": " + note_of(m)
        if sup: s += f" Support: {sup}"
        return s
    if m["author"]: s += f" by {m['author']}"
    if m["note"]: s += ": " + note_of(m)
    return s


def by(lst): return sorted([m for m in mods.values() if m["list"] == lst], key=skey)


S, W, Cs, V, N, XZ, X = (by(l) for l in ("S", "W", "C", "V", "N", "XZ", "X"))


def L(ms, credits=False): return "[list]\n" + "\n".join(row(m, credits) for m in ms) + "\n[/list]"


def LL(ms, credits=False, cont=False):
    """A run of a long list, with a heading for each letter. cont: the run starts inside a letter begun in the reply before."""
    out, cur = [], None
    for m in ms:
        c = fl(m)
        if c != cur:
            if cur is not None: out.append("[/list]")
            out.append(f"[h3]{label(c)}{', continued' if cur is None and cont else ''}[/h3]")
            out.append("[list]")
            cur = c
        out.append(row(m, credits))
    out.append("[/list]")
    return "\n".join(out)


def split(ms, room, credits=False, letters=True):
    """The fewest parts that fit, then the fewest cuts inside a letter, then as even as can be (as v5 did).
    room(k): the characters part k's list may take. None when the list cannot be cut to fit."""
    n = len(ms)

    def mid(i): return 1 if 0 < i < n and fl(ms[i]) == fl(ms[i - 1]) else 0

    @lru_cache(None)
    def size(i, j):
        return ulen(LL(ms[i:j], credits, cont=bool(mid(i))) if letters else L(ms[i:j], credits))

    @lru_cache(None)
    def best(i, k=0):
        if size(i, n) <= room(k): return (1, 0, size(i, n), (n,))
        out = None
        for j in range(i + 1, n):
            if size(i, j) > room(k): break
            r = best(j, k + 1)
            if r is None: continue
            p, c, w, cs = r
            cand = (p + 1, c + mid(j), max(w, size(i, j)), (j,) + cs)
            if out is None or cand[:3] < out[:3]: out = cand
        return out

    b = best(0)
    if b is None: return None
    cs = (0,) + b[3]
    return [ms[cs[k]:cs[k + 1]] for k in range(len(cs) - 1)]


def mid_cut(prev_part, part): return bool(prev_part) and fl(prev_part[-1]) == fl(part[0])


# ---- the first post: S; the replies: W 1, Compatible 2 to 10, vehicle packs 11, Not needed 12 and 13, Does not work and Broken 14
NC = NREPLY - 5                                     # Compatible must fill nine replies
WHERE_V = 2 + NC
COMPAT_INTRO = ("Loaded with ZeD-GUI, no errors of their own, and ZeD-GUI's tests passed with them on. Nothing special to say "
                f"unless a note says so. A note that starts {E['warn']} \"Part of it does not show\" means the mod adds to a game "
                f"screen that ZeD-GUI replaces. The first post says which reply holds each part; vehicle packs are in reply {WHERE_V}.")
C_HEAD_MAX = ulen(f"[h2]{E['C']} Compatible, 0-9 to Xxx (part 10 of 10)[/h2]\n")
CP = split(Cs, lambda k: LIMIT - C_HEAD_MAX - ulen(COMPAT_INTRO) - 2)
assert CP and len(CP) == NC, ("Compatible must fit nine replies", CP and len(CP))


def key2(m): return re.sub(r"[^a-z0-9]", "", skey(m))


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
N_FIRST_REPLY = WHERE_V + 1
N_HEAD_MAX = ulen(f"[h2]{E['N']} Not needed with ZeD (part 9 of 9)[/h2]\n")
N_LETTERS = True
NP = split(N, lambda k: LIMIT - N_HEAD_MAX - (ulen(N_INTRO) if k == 0 else ulen(f"Part {k} is in reply {N_FIRST_REPLY + k - 1}.\n")) - 2,
           credits=True)
if not NP or len(NP) != 2:                           # the letters do not fit two replies: Not needed goes back to one plain list
    N_LETTERS = False
    NP = split(N, lambda k: LIMIT - N_HEAD_MAX - (ulen(N_INTRO) if k == 0 else 40) - 2, credits=True, letters=False)
assert NP and len(NP) == 2, ("Not needed must fit replies 13 and 14", NP and len(NP))

blocks = ["W"] + [("C", k) for k in range(len(CP))] + ["V"] + [("N", k) for k in range(len(NP))] + ["X"]
where, rep = {"S": 0}, 1
for b in blocks:
    if isinstance(b, tuple): where.setdefault(b[0], []).append(rep)
    else: where[b] = rep
    rep += 1
assert rep - 1 == NREPLY and where["V"] == WHERE_V and where["N"][0] == N_FIRST_REPLY and where["X"] == NREPLY, where


def rr(ns):
    if len(ns) == 1: return f"Reply {ns[0]}"
    if len(ns) == 2: return f"Replies {ns[0]} and {ns[1]}"
    return f"Replies {ns[0]} to {ns[-1]}"


cparts = ", ".join(f"{CR[k]} (reply {where['C'][k]})" for k in range(len(CP)))
posts = {}

XPOST = f"""[h2]{E['XZ']} Does not work with ZeD[/h2]
These do a job ZeD-GUI also does, in a way that clashes with it: both draw at once, or ZeD's screen replaces the one the mod changes. Run one or the other.
{L(XZ)}

[h2]{E['X']} Broken on 42.21 or 42.22 by themselves[/h2]
These are broken on Project Zomboid 42.21 or 42.22 by themselves, with or without ZeD-GUI. Found a mod that clashes with ZeD-GUI? Reply with its name, its Workshop link and what happened.
{L(X)}
""".rstrip()

TESTED = """[list]
[*]Project Zomboid 42.21 (42.22 from Oct 29), single player, ZeD-GUI loaded after the other mods. Every error in the game's log was checked for the mod that made it, with ZeD-GUI off as well when it might be ZeD's.
[*]Oct 24 2026, ZeD-GUI 0.2.0-t3 and t4, a 1920x1080 window: 124 Workshop items (128 mods) on at once, then ZeD-GUI's own tests; 62 of the 66 that ran passed as they do without other mods.
[*]Oct 25 2026, ZeD-GUI 0.2.0-t5, 3840x2160 at UI scale 1.75: 48 more mods on at once with ZeD-GUI's whole test run, and 37 vehicle packs, their cars spawned and driven one by one.
[*]Oct 26 2026, ZeD-GUI 0.2.0-t6, 3840x2160: each mod ZeD-GUI supports, on by itself, with ZeD-GUI's tests for that support. Then 302 more mods in eight groups of 26 to 42, each group on at once with ZeD-GUI's tests for the screens it touches; the group's own windows opened, the item tooltip compared with and without ZeD-GUI, and new vehicle packs driven. Last, ZeD-GUI's whole test run with that round's Compatible and Works well mods, about 150 at a time.
[*]Oct 29 2026, ZeD-GUI 0.2.0-t11, 3840x2160 at UI scale 1.75: 34 popular Build 42 mods not yet on the list were picked, and the first of them tested in groups, each group on at once with ZeD-GUI's tests for every window, the item menu, the controller, the dashboard, the map and the moodles. The seven mods that ZeD-GUI 0.2.0-t11 supports were each tested with a check of that support in ZeD's windows.
[*]Nov 2 2026, ZeD-GUI 0.2.0-t15, 3840x2160: the rest of those mods, 20 on at once with the same tests, and the main menu walked through Mods, Options, Spawn, Sandbox, Traits and Looks.
[*]Nov 2 2026, ZeD-GUI 0.2.0-t15: nine more mods from the Workshop's trending Build 42 lists since Oct 29, on at once with the same tests, twice.
[*]Each mod's own features were [b]not[/b] tried one by one. A note marked [i](expected)[/i] comes from how the mod works, and one marked [i](by reading its code)[/i] from its code, not from a test.
[/list]"""

HELP = """[list]
[*]Notes and errors other mods show at game start go into ZeD-GUI's Messages window instead of covering the game.
[*]In Mods, a mod's About tab says what turning it off does to a save. In a save's own mod list, turning off a mod that is not safe asks first.
[*]When two mods ship the same code file, the Conflicts tab can pick whose copy the game runs, file by file (single player).
[*]From 0.2.0-t15 the load order has Find, Load first and Load last, and Load after... and Load before... rules that Auto keeps; separators name and fold a block of mods. The Mods page has folders, shared with [B42]Mod Folders.
[/list]"""

LETTERS_LINE = " The long lists have a heading for each letter." if N_LETTERS else " The Compatible lists have a heading for each letter."


def first_post(letters_line):
    return f"""TITLE: Compatibility with other mods

This thread lists the {len(mods)} mods tested with ZeD-GUI, sorted into five lists. Each list is in alphabetical order.{letters_line} Last updated Nov 2 2026.

[h2]{E['where']} Where each list is[/h2]
Steam cannot link to a reply, so count the replies from the top of the thread.
[list]
[*]{E['S']} [b]This post, below: Supported.[/b] ZeD-GUI has its own support for the mod, so its features show in ZeD's windows ({len(S)} mods).
[*]{E['W']} [b]Reply {where['W']}: Works well with ZeD.[/b] The mod fills a gap or shows well in ZeD's windows; worth having ({len(W)}). After it: how the mods were tested, help for long mod lists, and how to add a mod.
[*]{E['C']} [b]{rr(where['C'])}: Compatible[/b], in {len(CP)} parts: {cparts}. Loads and works with ZeD-GUI, nothing special ({len(Cs)}).
[*]{E['V']} [b]Reply {where['V']}: Compatible, vehicle packs[/b] ({len(V)}).
[*]{E['N']} [b]{rr(where['N'])}: Not needed with ZeD.[/b] ZeD-GUI already does the job, so use one of the two; the makers are credited there ({len(N)}).
[*]{E['XZ']} [b]Reply {where['X']}: Does not work.[/b] Two lists: mods that do not work with ZeD-GUI, with why ({len(XZ)}), and mods broken on 42.21 or 42.22 by themselves ({len(X)}).
[/list]

{SPOST}
"""


def body_of(name, text): return (text.split("\n", 1)[1].lstrip("\n") if name == "post00_first" else text).rstrip("\n")


SPOST = f"""[h2]{E['S']} Supported[/h2]
ZeD-GUI has its own support for these mods: their features show in ZeD's windows. Each support turns on only while that mod is on; ZeD's folders, which share [B42]Mod Folders' file, are always there.
{L(S)}"""
NOTES = f"""[h2]{E['tested']} How the mods were tested[/h2]
{TESTED}

[h2]{E['help']} Help in ZeD-GUI for long mod lists[/h2]
{HELP}

[h2]{E['add']} To add a mod to the list[/h2]
Reply with the mod's name, its Workshop link, the ZeD-GUI version, and what happened: it works, part of it does not show (say which), or it does not work. For an error, the Bug reports thread says what to include."""
posts["post00_first"] = first_post(LETTERS_LINE)
if ulen(body_of("post00_first", posts["post00_first"])) >= LIMIT:     # no room for the sentence: the headings speak for themselves
    posts["post00_first"] = first_post("")


posts[f"post{where['W']:02d}"] = f"""[h2]{E['W']} Works well with ZeD[/h2]
These fill a gap or show well in ZeD's windows. ZeD-GUI has no code of its own for them.
{L(W)}

{NOTES}
"""

for k, part in enumerate(CP):
    cont = mid_cut(CP[k - 1] if k else None, part)
    posts[f"post{where['C'][k]:02d}"] = f"""[h2]{E['C']} Compatible, {CR[k]} (part {k + 1} of {len(CP)})[/h2]
{COMPAT_INTRO}
{LL(part, cont=cont)}
"""

V_INTRO = ("Sorted by make, then model. Each pack's cars were spawned and driven one by one: ZeD's dashboard shows on each (a generic "
           "design, as for any car ZeD has no drawing of) and its Vehicle tab lists every part. The '85 Chevrolet Step-Van and the '93 "
           "Elgin Street Sweeper were on in the Oct 24 test and not driven. U.S. M113 APC: its Vehicle tab works; its dashboard was not "
           "checked (the test could not seat a driver in it).")
vpost = f"[h2]{E['V']} Compatible: vehicle packs[/h2]\n{V_INTRO}\n{LL(V)}\n"
V_LETTERS = ulen(vpost.rstrip("\n")) < LIMIT
posts[f"post{where['V']:02d}"] = vpost if V_LETTERS else f"[h2]{E['V']} Compatible: vehicle packs[/h2]\n{V_INTRO}\n{L(V)}\n"

for k, part in enumerate(NP):
    head = f"[h2]{E['N']} Not needed with ZeD (part {k + 1} of {len(NP)})[/h2]\n"
    intro = N_INTRO if k == 0 else f"Part {k} is in reply {where['N'][k - 1]}.\n"
    lst = LL(part, credits=True, cont=mid_cut(NP[k - 1] if k else None, part)) if N_LETTERS else L(part, credits=True)
    posts[f"post{where['N'][k]:02d}"] = head + intro + lst + "\n"

posts[f"post{where['X']:02d}"] = XPOST + chr(10)

bad = {k: ulen(body_of(k, v)) for k, v in posts.items() if ulen(body_of(k, v)) >= LIMIT}
assert not bad, ("posts over the limit", bad)

os.makedirs(OUT, exist_ok=True)
for f in os.listdir(OUT):
    if f.startswith("post"): os.remove(os.path.join(OUT, f))
for k, v in posts.items():
    open(os.path.join(OUT, k + ".txt"), "w", encoding="utf-8", newline="\n").write(v.rstrip("\n") + "\n")
json.dump(dict(where=where, replies=NREPLY, compatible_parts=CR, letters=dict(C=True, V=V_LETTERS, N=N_LETTERS)),
          open(os.path.join(HERE, "v7_layout.json"), "w", encoding="utf-8"), indent=1)
print("compatible parts", CR, [len(x) for x in CP], "not needed parts", [len(x) for x in NP])
print("letter headings: Compatible yes, vehicle packs", "yes" if V_LETTERS else "no", ", Not needed", "yes" if N_LETTERS else "no",
      "; first post sentence:", "yes" if LETTERS_LINE.strip() in posts["post00_first"] else "no")
for k, v in sorted(posts.items()):
    print(k, ulen(body_of(k, v)))
