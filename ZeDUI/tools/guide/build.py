"""Builds ZeDUI/mockups/zed_survival_guide_v2.html from template.html and the game's own files (42.22)."""
import base64, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))   # template.html and clip.jpg sit beside this script
G = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media"
OUT = "C:/Users/you/Zomboid/mods/ZeD-UI/ZeDUI/mockups/zed_survival_guide_v2.html"

d = json.load(open(G + "/lua/shared/Translate/EN/SurvivalGuide.json", encoding="utf-8"))
vids = set(os.listdir(G + "/videos/survival_guide"))
short = {"movement": "Move", "inventory": "Loot", "interactable": "Use", "combat": "Fight", "food_and_water": "Food",
         "character": "Self", "crafting": "Craft", "vehicles": "Cars", "weather": "Sky", "foraging_mining": "Wild",
         "farming": "Farm", "ranching": "Ranch", "fishing": "Fish", "cleaning": "Clean", "multiplayer": "MP"}
secs, cur = [], None
for k in d:
    m = re.match(r"SurvivalGuide_(\w+)_title$", k)
    if not m:
        continue
    i = m.group(1)
    if "SurvivalGuide_%s_category_image" % i in d:
        cur = {"id": i, "title": d[k], "short": short.get(i, i[:5]), "topics": []}
        secs.append(cur)
        continue
    clip = "sg_%s.bik" % i
    cur["topics"].append({"id": i, "title": d[k], "text": d.get("SurvivalGuide_%s_description" % i, ""),
                          "clip": clip if clip in vids else None, "redo": i == "skill_books"})
new = [("zed", "ZeD", "ZeD", ["The Character window", "The World window", "Item cards", "The belt and hands",
                               "The action bar", "ZeD setup"]),
       ("first_days", "First Days", "Start", ["Water first", "Walk, don't run", "Curtains and windows",
                                              "Fight at doors and fences", "A bag and a weapon", "Two kinds of Infected"]),
       ("b41", "Build 41 Habits", "B41", ["Traits", "Carpentry", "Crafting and magazines", "Weapon wear"]),
       ("controls", "Your Controls", "Keys", ["Keyboard and mouse", "Controller"]),
       ("whatsnew", "What's New in ZeD", "New", ["0.3.0-beta2"])]
for sid, t, sh, ts in new:
    secs.append({"id": sid, "title": t, "short": sh, "zed": True,
                 "topics": [{"id": "%s_%d" % (sid, n), "title": x, "text": "", "clip": None, "redo": False}
                            for n, x in enumerate(ts)]})

lua = open(G + "/lua/server/XpSystem/XPSystem_SkillBook.lua", encoding="utf-8").read()
def mult(skill):
    return [re.search(r'SkillBook\["%s"\]\.maxMultiplier%d = ([\d.]+)' % (skill, n), lua).group(1) for n in range(1, 6)]
m1, m2 = mult("Carpentry"), mult("Aiming")
lit = open(G + "/scripts/generated/items/literature.txt", encoding="utf-8").read()
books = []
for v in range(1, 6):
    blk = re.search(r"item BookCarpentry%d\s*\{(.*?)\}" % v, lit, re.S).group(1)
    lo = int(re.search(r"LvlSkillTrained = (\d+)", blk).group(1))
    n = int(re.search(r"NumLevelsTrained = (\d+)", blk).group(1))
    books.append({"vol": v, "lo": lo, "hi": lo + n - 1, "m": m1[v - 1], "m2": m2[v - 1]})

ui = {}
for f in os.listdir(G + "/lua/shared/Translate/EN"):
    if f.endswith(".json"):
        try:
            ui.update(json.load(open(G + "/lua/shared/Translate/EN/" + f, encoding="utf-8")))
        except Exception:
            pass
data = {"sections": secs, "books": books, "showGuide": ui.get("IGUI_Tutorial_ShowGuide", "Show the guide on startup")}
clip = "data:image/jpeg;base64," + base64.b64encode(open(os.path.join(HERE, "clip.jpg"), "rb").read()).decode()
h = open(os.path.join(HERE, "template.html"), encoding="utf-8").read()
h = h.replace("__DATA__", json.dumps(data, ensure_ascii=False)).replace("__CLIP__", clip)
open(OUT, "w", encoding="utf-8").write(h)
print(len(secs), "sections", sum(len(s["topics"]) for s in secs), "topics", os.path.getsize(OUT), "bytes")
