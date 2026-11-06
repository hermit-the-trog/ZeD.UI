"""The SteamCMD upload file for a build (Nov 5 2026, QA): page text and change note from ZeDUI/workshop, quotes and backslashes
escaped. usage: py make_vdf.py 0.3.0-beta5   Writes %TEMP%/zed_upload_3824968485.vdf; the director runs SteamCMD with it."""
import os
import sys

v = sys.argv[1]
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
w = os.path.join(root, "workshop")
BS, Q = chr(92), chr(34)


def read(name):
    return open(os.path.join(w, name), encoding="utf8").read().replace("\r\n", "\n").strip()


def esc(s):
    return s.replace(BS, BS + BS).replace(Q, BS + Q)


d = read("tester_description_%s.bbcode" % v)
c = read("tester_changenote_%s.txt" % v)
rows = [("appid", "108600"), ("publishedfileid", "3824968485"),
        ("contentfolder", "C:/Users/danie/Zomboid/Workshop/ZeD-UI/Contents"),
        ("previewfile", "C:/Users/danie/Zomboid/mods/ZeD-UI/ZeDUI/workshop/thumbnail/year_1993_animated.gif"),
        ("description", esc(d)), ("changenote", esc(c))]
out = Q + "workshopitem" + Q + "\n{\n" + "".join("\t%s%s%s\t\t%s%s%s\n" % (Q, k, Q, Q, val, Q) for k, val in rows) + "}\n"
p = os.path.join(os.environ["TEMP"], "zed_upload_3824968485.vdf")
open(p, "w", encoding="utf8", newline="\n").write(out)
print("description", len(d), "escaped", len(esc(d)), "changenote", len(c), "->", p)
