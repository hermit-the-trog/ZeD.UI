"""Stage Lua Console 93 Professional Edition for the Workshop and write its SteamCMD upload file (Nov 13 2026).

usage: python -I ZeDUI/tools/release/stage_luaconsole93.py [--item ID] [--note "text"]

What it does:
  1. checks products/LuaConsole93 is what the sources build (build_luaconsole93.py --check), and stops if not;
  2. copies products/LuaConsole93/42 to ~/Zomboid/Workshop/LuaConsole93/Contents/mods/LuaConsole93/42, with an
     empty-but-present common/ beside it (Build 42 wants both folders; Steam skips empty ones, so a placeholder);
  3. writes %TEMP%/lc93_upload.vdf: page text from products/LuaConsole93/workshop_description.bbcode, the box art
     preview, and visibility.

The first upload has no item yet: publishedfileid "0" makes SteamCMD create a new item and write its new id back
into the .vdf. Keep that id: pass it as --item on every later upload, and record it here in ITEM_ID.
The item starts hidden (visibility 2, private) so the page can be checked before anyone sees it; the director
makes it public in Steam's page settings. The upload itself is the director's go, never Build's.
"""
import argparse
import os
import shutil
import subprocess
import sys

ITEM_ID = "0"          # set to the new item's id after the first upload
APPID = "108600"
MOD_ID = "LuaConsole93"
TITLE = "Lua Console 93 Professional Edition"

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
PRODUCT = os.path.join(REPO, "products", MOD_ID)
WORKSHOP = os.path.join(os.path.expanduser("~"), "Zomboid", "Workshop", MOD_ID)
Q = chr(34)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--item", default=ITEM_ID, help="the Workshop item id (0 = create a new item)")
    ap.add_argument("--note", default="1.0.0: first release.", help="the change note")
    ap.add_argument("--visibility", default="2", help="0 public, 1 friends, 2 private, 3 unlisted")
    a = ap.parse_args()

    r = subprocess.run([sys.executable, "-I", os.path.join(REPO, "ZeDUI", "tools", "products", "build_luaconsole93.py"),
                        "--check"], capture_output=True, text=True)
    print(r.stdout.strip().splitlines()[-1] if r.stdout.strip() else r.stderr.strip())
    if r.returncode != 0:
        sys.exit("STOP: products/LuaConsole93 is not what the sources build; run build_luaconsole93.py first")

    dest = os.path.join(WORKSHOP, "Contents", "mods", MOD_ID)
    if os.path.isdir(os.path.join(WORKSHOP, "Contents")):
        shutil.rmtree(os.path.join(WORKSHOP, "Contents"))   # only the staging copy this tool made
    shutil.copytree(os.path.join(PRODUCT, "42"), os.path.join(dest, "42"))
    os.makedirs(os.path.join(dest, "common"), exist_ok=True)
    open(os.path.join(dest, "common", "placeholder.txt"), "w").write("Build 42 mods carry a common folder.\n")
    n = sum(len(f) for _, _, f in os.walk(dest))
    size = sum(os.path.getsize(os.path.join(p, x)) for p, _, f in os.walk(dest) for x in f)
    print("STAGED %d files, %.2f MB -> %s" % (n, size / 1e6, dest))

    desc = open(os.path.join(PRODUCT, "workshop_description.bbcode"), encoding="utf8").read().replace("\r\n", "\n").strip()
    desc = desc.replace(Q, "'")        # SteamCMD reads no escapes: a double quote would end the field
    note = a.note.replace(Q, "'")
    preview = os.path.join(PRODUCT, "workshop", "preview.png")
    rows = [("appid", APPID), ("publishedfileid", a.item),
            ("contentfolder", os.path.join(WORKSHOP, "Contents").replace(chr(92), "/")),
            ("previewfile", preview.replace(chr(92), "/")),
            ("visibility", a.visibility), ("title", TITLE),
            ("description", desc), ("changenote", note)]
    if a.item != "0":
        rows = [r for r in rows if r[0] not in ("visibility",)]   # keep whatever the director set on the page
    out = Q + "workshopitem" + Q + "\n{\n" + "".join("\t%s%s%s\t\t%s%s%s\n" % (Q, k, Q, Q, v, Q) for k, v in rows) + "}\n"
    p = os.path.join(os.environ["TEMP"], "lc93_upload.vdf")
    open(p, "w", encoding="utf8", newline="\n").write(out)
    print("VDF item %s, visibility %s, description %d chars -> %s" % (a.item, a.visibility if a.item == "0" else "kept", len(desc), p))


if __name__ == "__main__":
    main()
