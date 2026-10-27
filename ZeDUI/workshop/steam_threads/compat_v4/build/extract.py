import sys; sys.stdout.reconfigure(encoding="utf-8")
import re, json, os, glob
D = r"C:\Users\danie\Zomboid\mods\ZeD-UI\ZeDUI\workshop\steam_threads"
FILES = ["2_compatibility.txt","2_compatibility_b_notes.txt","2_compatibility_c_grade_a_1.txt","2_compatibility_c_grade_a_2.txt","6_credits.txt","2_compatibility_round2.txt","2_compatibility_round2_vehicles.txt"]
WS = r"E:\Project Zomboid\SteamApps\workshop\content\108600"
pat = re.compile(r"\[url=https://steamcommunity\.com/sharedfiles/filedetails/\?id=(\d+)\](.*?)\[/url\](.*?)(?=\[url=https://steamcommunity\.com/sharedfiles|\n|$)")
out = {}
for f in FILES:
    txt = open(os.path.join(D,f), encoding="utf-8").read()
    for line in txt.split("\n"):
        g = re.match(r"\[\*\](?:\[b\]([A-FX])\[/b\] \| )?", line)
        grade = g.group(1) if g else None
        for m in pat.finditer(line):
            wid, name, rest = m.groups()
            e = out.setdefault(wid, {"id": wid, "name": name, "src": []})
            e["src"].append({"file": f, "grade": grade, "rest": rest.strip()})
def authors(wid):
    s = set()
    for p in glob.glob(os.path.join(WS, wid, "mods", "*", "**", "mod.info"), recursive=True):
        for l in open(p, encoding="utf-8", errors="replace"):
            if l.lower().startswith("author="):
                a = l.split("=",1)[1].strip()
                if a: s.add(a)
    return sorted(s)
for wid, e in out.items():
    e["modinfo_authors"] = authors(wid)
json.dump(out, open("old.json","w",encoding="utf-8"), ensure_ascii=False, indent=1)
print(len(out))
for wid, e in sorted(out.items(), key=lambda x: x[1]["name"].lower()):
    srcs = "; ".join(f"{s['file'][14:24]}:{s['grade']}:{s['rest'][:70]}" for s in e["src"])
    print(wid, "|", e["name"], "|", e["modinfo_authors"], "|", srcs)
