# Builds the Compatibility thread v3 (first post + 6 replies) from old.json (extract.py)
# plus the grouping table below. Writes to ZeDUI/workshop/steam_threads/compat_v3/.
import json, os, re, sys
sys.stdout.reconfigure(encoding="utf-8")
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\workshop\steam_threads\compat_v3"
old = json.load(open(os.path.join(HERE, "old.json"), encoding="utf-8"))
U = "https://steamcommunity.com/sharedfiles/filedetails/?id="
DROP = {"3619862853"}  # ZombieBuddy: no plans to test Java mods

# Mods with ZeD support that were not in the old posts (QA'd Oct 26 with ZeD's tests for them)
NEW = {
    "2815560151": ("Share Annotations", "belette"),
    "3589548354": ("Improved Hair Menu", "duckduckquack and TwisTonFire"),
    "3760534563": ("NeatUI Hairstyler", "Gimmi"),
}

# Author fixes: old post's author wins; then mod.info; these map mod.info spellings
AUTHOR_FIX = {"Rocco, Afyrmo": "Rocco", "BitBraven": "Braven", "Cye's": "Cye", "KingEJ": "King EJ",
              "Devilzcore": "devilzcore", "AuthenticPeach": "Authentic Peach",
              "Chuckleberry Finn & Nurver": "Chuckleberry Finn and Nurver",
              "Akyet, Noir, Hx, Royadin, Alice": "Alice", "hehehemann, SP4RTAN": "hehehemann",
              "Dr. Lalaoz/Harrod200": "Dr. Lalaoz", "Dr. Lalaoz/Harrod200/Lenniitsch": "Dr. Lalaoz",
              "draxo & tealera": "tealera", "Horse team": "albion"}
NAME_FIX = {"2705655822": "U.S. M113 APC"}

T6 = "From ZeD-GUI 0.2.0-t6"
EXP = " [i](expected)[/i]"
RD = " [i](by reading its code)[/i]"

# id -> (list, note). Lists: S supported, W works well, C compatible, V vehicle pack, N not needed, X does not work.
G = {
 # 1. Supported
 "2804531012": ("S", "Draw, Line and Erase on the Maps tab toolbar, with Thickness and Fill. Controller: hold A on the map cursor. From ZeD-GUI 0.2.0-t6."),
 "3589548354": ("S", "Its cuts, ties and trims are rows in the Identity tab's Hair and Beard section, and its picture menu opens from a Pictures button. From ZeD-GUI 0.2.0-t6."),
 "2734705913": ("S", "Its Symbol Size slider is in the Maps tab, beside the mark grid, and saves to the mod's own setting. From ZeD-GUI 0.2.0-t6."),
 "3760534563": ("S", "Its cuts, ties and trims are rows in the Identity tab's Hair and Beard section, and its picture menu opens from a Pictures button. From ZeD-GUI 0.2.0-t6."),
 "2879960936": ("S", "Other players' squares and names on the Maps tab, and a Players list. Multiplayer only. From ZeD-GUI 0.2.0-t6."),
 "2815560151": ("S", "Learned map notes in the Maps tab's side list, to show, hide or delete. A set hidden on the game's map can be shown again. From ZeD-GUI 0.2.0-t6."),
 "2503622437": ("S", "Its strip under each row of the Skills tab, a key line, and the numbers in a hover card. From ZeD-GUI 0.2.0-t6."),
 "3414634809": ("S", "Its faces and details are the Character window's Appearance tab and rows on the Looks screen for a new character; its window at game start opens that tab, paused, as the mod does. The mod's rules and saving are its own. From ZeD-GUI 0.2.0-t5."),
 "3041733782": ("S", "The styles it unlocks are rows in the Identity tab's Hair and Beard section, marked with its tag. From ZeD-GUI 0.2.0-t6."),
 "3784847437": ("S", "A Traits tab after Skills, its traits drawn like skills with ten steps. From ZeD-GUI 0.2.0-t6."),
 "3097650043": ("S", "The name of the area you are in, over the Maps tab. From ZeD-GUI 0.2.0-t6."),
 # 2. Works well with ZeD
 "3387539308": ("W", "Train mechanics, Uninstall all and Continue are in the part menu of ZeD's Vehicle tab (X or right-click on a part)." + RD),
 "3387957272": ("W", "Its longer trait and occupation texts show on ZeD's Traits screen and, from 0.2.0-t6, on hover in the Identity tab."),
 "2650547917": ("W", "Its container rules run from the container buttons in ZeD's windows."),
 "3470659758": ("W", "Its shortcut bar sits just above ZeD's belt."),
 "2757712197": ("W", "Its repairs (heater, lightbar, engine rebuild) are in the part menu of ZeD's Vehicle tab." + RD),
 # 3. Compatible, with a note
 "2335368829": ("C", "With its Backpacks+ add-on on as well, the two register the same clothing slots (their own error at load)."),
 "3268487204": ("C", "Its note at game start goes into ZeD's Messages."),
 "2313387159": ("C", "One error of its own at load on 42.21 (a drink with no item, BSdynamicCats). Not ZeD."),
 "3740052292": ("C", "Its note at game start goes into ZeD's Messages."),
 "2707905930": ("C", "One error of its own at load on 42.21 (a clothing slot named by text, which 42.21 no longer takes). Not ZeD."),
 "2896041179": ("C", "Keeps a copy of every error it shows. With a mod erroring every minute (Week One NPC), the game ran out of memory after about 35 minutes with 128 mods."),
 "3661336777": ("C", "Wants to be on in the main menu's mod list too, or it warns at game start that it was not loaded properly and pauses the game (its own check). The warning goes into ZeD's Messages and the game runs on."),
 "2866258937": ("C", "A click on it opens the game's own character window over ZeD's." + RD),
 "3451167732": ("C", "Its bars work; its layout menu opens from the game's Health button, which ZeD hides." + RD),
 "3396446795": ("C", "Part of it does not show where you set it: its extra moodles stay at the game's old place at the right edge, not where ZeD's Moodles setting puts them." + RD),
 "3508537032": ("C", "A library for Rocco's mods." + EXP),
 "3056481712": ("C", "Its alert at game start shows raw text keys on 42.21: its translations are in the old .txt format. Not ZeD."),
 "3540903327": ("C", "Moves watches to its own watch slot; ZeD's belt finds the watch there."),
 "3490188370": ("C", "Its button beside the game's Crafting button does not show; its window opens from the item menu." + RD),
 "2847184718": ("C", "Part of it does not show: its one container of everything nearby is added to the game's loot window. ZeD's World window shows each container in reach as its own column." + RD),
 "2901962885": ("C", "Part of it does not show: it orders the game's container buttons; ZeD's container strip keeps its own order." + EXP),
 "3290232938": ("C", "Part of it does not show: its names, pictures and colours go on the game's container buttons, which ZeD replaces." + EXP),
 "3420581050": ("C", "Part of it does not show: ZeD's radio tabs and car radio replace its radio screens. Its TV channels, ads and VHS are its own." + EXP),
 # 4. Not needed with ZeD
 "2894296454": ("N", "ZeD-GUI has Sandbox options in the pause window (Options, ZeD setup, Sandbox; off by default). The mod also has two errors of its own on 42.21, which ZeD-GUI works around. Use one."),
 "3461263912": ("N", "ZeD's belt shows the hands and hotbar with condition and key numbers, and replaces its drawing. Use one." + EXP),
 "3437629766": ("N", "Restyles the game's inventory and loot windows, the ones ZeD replaces. Use one." + EXP),
 "3306168142": ("N", f"{T6}, ZeD's dashboard gives the engine, battery, heater and headlight condition. The mod's text is on the game's dashboard, which ZeD replaces." + EXP),
 "2950902979": ("N", "ZeD's Equipment tab has a paper doll. Its \"hide equipped items\" button shows in ZeD's container buttons but does nothing in ZeD's lists. Use one."),
 "2544353492": ("N", f"{T6}, ZeD's item lists mark what you have read, part read or not read, and NEXT LEVEL on skill books. The mod's marks are on the game's inventory list, which ZeD replaces." + EXP),
 "2852309899": ("N", "ZeD shows condition on the belt and in every list. Its bars are drawn on the game's hotbar, which the belt replaces." + EXP),
 "3641048285": ("N", "ZeD shows condition in every list. Its bars are drawn on the game's inventory list, which ZeD replaces." + EXP),
 "2553809727": ("N", "ZeD's Journal tab counts kills by weapon type. Its tab is in the game's character window, which ZeD replaces." + EXP),
 "2710167561": ("N", f"{T6}, ZeD's Maps tab has a Key button with the game's own map key. The mod's button is on the game's map, which ZeD replaces." + EXP),
 "3642084851": ("N", "ZeD already hides the game's sidebar." + EXP),
 "3423660713": ("N", "ZeD's Mods screen has its own Auto sort. The mod's Sort button is on the game's Mods screen, which ZeD replaces." + EXP),
 "3536052310": ("N", "ZeD's World window has building. Use one." + EXP),
 "3502080466": ("N", "ZeD's World window has crafting at a bench or station near you. Use one." + EXP),
 "3635591071": ("N", "ZeD draws its own dashboard. Use one." + EXP),
 "2903771337": ("N", "ZeD's belt does this job. Its reordering does not show on the belt; ZeD keeps the game's hotbar hidden and takes the drawing back. Use one."),
 "2769706949": ("N", "Same job as ZeD's Put things back (off by default). With both on, Tidy Up Meister also puts things back after an interrupted action, which ZeD does not. Use one."),
 # 5. Does not work (broken on 42.21 by themselves)
 "2696986935": ("X", "Errors as new parts of the map load (it calls PropertyContainer.Is, which 42.21 removed). Not ZeD."),
 "2875848298": ("X", "Stops the world from loading: its recipes ask for a fluid, Alcohol, that 42.21 no longer has. Not ZeD."),
 "2835852387": ("X", "Replaces the game's furniture-moving code with an older copy that calls functions 42.21 removed, so picking up, placing and taking apart furniture error. Not ZeD."),
 "2737665235": ("X", "Its ladder code errors as the world loads (setLadderClimbingFlags). Not ZeD."),
 "2845952197": ("X", "Errors every frame while you read: it asks for fatigue in a way 42.21 removed (getFatigue). Not ZeD."),
 "3403180543": ("X", "Its scheduler errors once a game minute in an existing save (generateSchedule). Not ZeD."),
}

def post_author(e):
    for s in e["src"]:
        m = re.match(r"by (?:\[url=[^\]]*\])?(.+?)(?:\[/url\])?(?::|$| \|)", s["rest"])
        if m and s["file"] != "6_credits.txt":
            return m.group(1).strip()
    return None

def credit(e):
    for s in e["src"]:
        if s["file"] == "6_credits.txt":
            m = re.match(r"by (\[url=[^\]]*\][^\[]*\[/url\])(?: \| support: (.*))?$", s["rest"])
            if m: return m.group(1), m.group(2)
    return None, None

# Makers of newly listed Not needed mods: same maker links as the credits list where it is the same person
EXTRA_CREDIT = {"2544353492": ("[url=https://steamcommunity.com/profiles/76561199151439614]PePePePePeil[/url]",
                               "[url=https://ko-fi.com/pepepepepeil]ko-fi.com/pepepepepeil[/url]")}

mods = {}
for wid, e in old.items():
    if wid in DROP: continue
    a = post_author(e)
    if not a:
        mi = [AUTHOR_FIX.get(x, x) for x in e["modinfo_authors"]]
        a = mi[0] if mi else None
    a = AUTHOR_FIX.get(a, a) if a else None
    if a and a.lower() == "spongie": a = "Spongie"
    name = NAME_FIX.get(wid, e["name"])
    vehicle = any(s["file"] == "2_compatibility_round2_vehicles.txt" for s in e["src"]) or wid in ("3614034284", "2969343830")
    lst, note = G.get(wid, ("V" if vehicle else "C", ""))
    mods[wid] = dict(id=wid, name=name, author=a, list=lst, note=note, cr=credit(e))
for wid, (n, a) in NEW.items():
    lst, note = G[wid]
    mods[wid] = dict(id=wid, name=n, author=a, list=lst, note=note, cr=(None, None))
for wid in G: assert wid in mods, wid

def skey(m):
    n = m["name"]
    if m["list"] == "V":
        n = re.sub(r"^'\d\d ", "", n)
    n = re.sub(r"^(\[[^\]]*\]\s*)+", "", n)
    n = re.sub(r"^42\.21 \| ", "", n)
    n = n.lstrip("'")
    return n.lower()

def row(m, credits=False):
    s = f"[*][url={U}{m['id']}]{m['name']}[/url]"
    if credits:
        link, sup = credit_of(m)
        s += f" by {link}" if link else ""
        if m["note"]: s += ": " + m["note"]
        if sup: s += f" Support: {sup}"
        return s
    if m["author"]: s += f" by {m['author']}"
    if m["note"]: s += ": " + m["note"]
    return s

def credit_of(m):
    link, sup = m["cr"]
    if not link and m["id"] in EXTRA_CREDIT: link, sup = EXTRA_CREDIT[m["id"]]
    if not link and m["author"]: link = m["author"]
    return link, sup

def rows(lst, credits=False, filt=None):
    ms = sorted([m for m in mods.values() if m["list"] == lst and (filt is None or filt(m))], key=skey)
    return ms, "[list]\n" + "\n".join(row(m, credits) for m in ms) + "\n[/list]"

S, rs = rows("S"); W, rw = rows("W")
Cs = sorted([m for m in mods.values() if m["list"] == "C"], key=skey)
# split Compatible into three replies at first-letter boundaries, balancing their length
def fl(m):
    c = skey(m)[0]
    return "0" if not c.isalpha() else c
L = [len(row(m)) + 1 for m in Cs]
cuts = [i for i in range(1, len(Cs)) if fl(Cs[i]) != fl(Cs[i-1])]
best = None
for i in cuts:
    for j in cuts:
        if j <= i: continue
        parts = (sum(L[:i]), sum(L[i:j]), sum(L[j:]))
        if best is None or max(parts) < best[0]: best = (max(parts), i, j)
_, I, J = best
CP = [Cs[:I], Cs[I:J], Cs[J:]]
def rng(ms):
    a, b = fl(ms[0]), fl(ms[-1])
    a = "0-9 and A" if a == "0" else a.upper()
    return f"{a} to {b.upper()}"
starts = [fl(x[0]) for x in CP]
def lab(c): return "0-9 and A" if c == "0" else c.upper()
R = [f"{lab(starts[k])} to {(chr(ord(starts[k + 1]) - 1).upper() if k < 2 else 'Z')}" for k in range(3)]
V, rv = rows("V"); N, rn = rows("N", credits=True); X, rx = rows("X")
def lst(ms): return "[list]\n" + "\n".join(row(m) for m in ms) + "\n[/list]"

COMPAT_INTRO = "Loaded with ZeD-GUI, no errors of their own, and ZeD-GUI's tests passed with them on. Nothing special to say unless a note says so. A note that starts \"Part of it does not show\" means the mod adds to a game screen that ZeD-GUI replaces."

posts = {}
posts["post0_first"] = f"""TITLE: Compatibility with other mods

This thread lists the mods tested with ZeD-GUI, sorted into five lists. Each list is in alphabetical order. Last updated Oct 26 2026.

[h2]Where each list is[/h2]
Steam cannot link to a reply, so count the replies from the top of the thread.
[list]
[*][b]Reply 1: Supported, and Works well with ZeD.[/b] Supported: ZeD-GUI has its own support for the mod, so its features show in ZeD's windows ({len(S)} mods). Works well: the mod fills a gap or shows well in ZeD's windows; worth having ({len(W)}).
[*][b]Replies 2, 3 and 4: Compatible[/b], in three parts: {R[0]}, {R[1]}, {R[2]}. Loads and works with ZeD-GUI, nothing special ({len(Cs)}).
[*][b]Reply 5: Compatible, vehicle packs[/b] ({len(V)}).
[*][b]Reply 6: Not needed with ZeD, then Does not work.[/b] Not needed: ZeD-GUI already does the job, so use one of the two; the makers are credited there ({len(N)}). Does not work: no mod tested so far clashes with ZeD-GUI; these are broken on 42.21 by themselves ({len(X)}).
[/list]

[h2]How the mods were tested[/h2]
[list]
[*]Project Zomboid 42.21, single player, ZeD-GUI loaded after the other mods. Every error in the game's log was checked for the mod that made it.
[*]Oct 24 2026, ZeD-GUI 0.2.0-t3 and t4, a 1920x1080 window: 124 Workshop items (128 mods) on at once. A save loaded with all of them, then ZeD-GUI's own tests ran (66 of 73 before the game ran out of memory); 62 of the 66 passed as they do without other mods.
[*]Oct 25 2026, ZeD-GUI 0.2.0-t5, 3840x2160 at UI scale 1.75: 48 more mods on at once with ZeD-GUI's whole test run (80 tests, passing as they do without other mods), and 37 vehicle packs, 76 of their cars spawned and driven one by one.
[*]Oct 26 2026: each mod ZeD-GUI 0.2.0-t6 supports, on by itself, with ZeD-GUI's tests for that support.
[*]Each mod's own features were [b]not[/b] tried one by one. A note marked [i](expected)[/i] comes from how the mod works, and one marked [i](by reading its code)[/i] from its code, not from a test.
[/list]

[h2]Help in ZeD-GUI for long mod lists[/h2]
[list]
[*]Notes and errors other mods show at game start go into ZeD-GUI's Messages window instead of covering the game, and a mod that pauses the game for its note no longer leaves it paused.
[*]In Mods, a mod's About tab says what turning it off does to a save (safe, careful or not safe, and why). In a save's own mod list, turning off a mod that is not safe asks first.
[*]When two mods ship the same code file, the Conflicts tab can pick whose copy the game runs, file by file (single player). For example, GaelGunStore-Firearms and Modern Firearms System share 13 files.
[/list]

[h2]To add a mod to the list[/h2]
Reply with the mod's name, its Workshop link, the ZeD-GUI version, and what happened: it works, part of it does not show (say which), or it does not work. For an error, the Bug reports thread says what to include.
"""

posts["post1"] = f"""[h2]Supported[/h2]
ZeD-GUI has its own support for these mods: their features show in ZeD's windows. Each support turns on only while that mod is on.
{rs}

[h2]Works well with ZeD[/h2]
These fill a gap or show well in ZeD's windows. ZeD-GUI has no code of its own for them.
{rw}
"""

for k in range(3):
    other = [f"{R[j]} is in reply {j + 2}" for j in range(3) if j != k]
    posts[f"post{k + 2}"] = f"""[h2]Compatible, {R[k]} (part {k + 1} of 3)[/h2]
{COMPAT_INTRO} {other[0]}, {other[1]}; vehicle packs are in reply 5.
{lst(CP[k])}
"""

posts["post5"] = f"""[h2]Compatible: vehicle packs[/h2]
Sorted by make, then model. The Oct 25 packs were driven car by car: ZeD's dashboard shows on each (a generic design, as for any car ZeD has no drawing of) and its Vehicle tab lists every part. The '85 Chevrolet Step-Van and the '93 Elgin Street Sweeper were on in the Oct 24 test and not driven. U.S. M113 APC: its Vehicle tab works; its dashboard was not checked (the test could not seat a driver in it).
{rv}
"""

posts["post6"] = f"""[h2]Not needed with ZeD[/h2]
ZeD-GUI already does the job of these mods, so use one of the two. Most still load with ZeD-GUI on; the part that does the same job does not show.

ZeD-GUI does not take donations. If ZeD-GUI does the job of a mod you used and you want to give something back, give it to the person who made that mod. They worked these problems out first, and some of them do this to put food on the table. Where no support link is listed, the maker's Steam page is linked where known; many keep theirs there.
{rn}

[h2]Does not work[/h2]
No mod tested so far clashes with ZeD-GUI (something happening twice, or one undoing the other). These are broken on Project Zomboid 42.21 by themselves, with or without ZeD-GUI. Found a mod that clashes? Reply with its name, its Workshop link and what happened.
{rx}
"""

os.makedirs(OUT, exist_ok=True)
for k, v in posts.items():
    v = v.rstrip("\n") + "\n"
    open(os.path.join(OUT, k + ".txt"), "w", encoding="utf-8", newline="\n").write(v)
json.dump({k: v for k, v in mods.items()}, open(os.path.join(HERE, "v3_mods.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
print("ranges", R, [len(x) for x in CP])
print({l: sum(1 for m in mods.values() if m["list"] == l) for l in "SWCVNX"}, "total", len(mods))
for k, v in posts.items():
    body = v.split("\n", 1)[1] if k == "post0_first" else v
    print(k, len(body.rstrip("\n")))
