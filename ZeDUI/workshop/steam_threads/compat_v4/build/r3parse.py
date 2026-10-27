import sys, re, json, os, glob
sys.stdout.reconfigure(encoding="utf-8")
SRC = r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\workshop\compat_round3_results.md"
WS = r"E:\Project Zomboid\SteamApps\workshop\content\108600"
v3 = json.load(open("v3_mods.json", encoding="utf-8"))
rows, grp = {}, None
for l in open(SRC, encoding="utf-8"):
    m = re.match(r"### Group (\w)", l)
    if m: grp = m.group(1)
    m = re.match(r"\| (.*?) \| \[(\d+)\]\(.*?\) \| (\d) \| ([^|]+?) \| (.*) \|\s*$", l)
    if m:
        name, wid, tier, lst, ev = m.groups()
        if wid in rows: print("DUP in r3", wid)
        rows[wid] = dict(id=wid, name=name.strip(), group=grp, list=lst.strip(), ev=ev.strip())
def authors(wid):
    s = []
    for p in glob.glob(os.path.join(WS, wid, "mods", "*", "**", "mod.info"), recursive=True):
        for l in open(p, encoding="utf-8", errors="replace"):
            if l.lower().startswith("author="):
                a = l.split("=",1)[1].strip()
                if a and a not in s: s.append(a)
    return s
for wid, r in rows.items(): r["authors"] = authors(wid)
json.dump(rows, open("r3.json","w",encoding="utf-8"), ensure_ascii=False, indent=1)
from collections import Counter
print(len(rows), Counter(r["list"] for r in rows.values()), Counter(r["group"] for r in rows.values()))
ov = [w for w in rows if w in v3]
print("overlap with v3:", [(w, rows[w]["name"], rows[w]["list"], v3[w]["list"]) for w in ov])
print("no author:", [(w, rows[w]["name"]) for w in rows if not rows[w]["authors"]])
