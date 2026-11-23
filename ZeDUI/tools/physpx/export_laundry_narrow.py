"""Re-bakes only the laundry machines' narrow faces (washer_n, dryer_n, washer_dryer_n) and splices their entries into
PhysPx.lua, leaving every other plate as committed (export_rtv.py rewrites them all, and the committed oven, generator,
grill, ham, walkie and microwave art is newer than the tools make). (Narrow washer, the director, Nov 22 2026)

usage: python export_laundry_narrow.py <mod root> [--check]
  --check  build and compare with the committed pictures and entries, writing nothing"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import rtv_plates as RP              # noqa: E402,F401  (registers the laundry faces and their narrow ones)
import export_phys as EX             # noqa: E402
from export_lua import to_lua        # noqa: E402

PIDS = ("washer_n", "dryer_n", "washer_dryer_n")


def entry_span(src, pid):
    """the text of `    <pid> = { ... },` in PhysPx.lua: from its line to the matching close at the same indent"""
    head = f"\n    {pid} = {{\n"
    i = src.index(head) + 1
    j = src.index("\n    },\n", i) + len("\n    },\n")
    return i, j


def lua_entry(pid, data):
    body = to_lua(data)                          # "{\n  w = ...,\n}" at indent 0
    lines = body.split("\n")
    out = [f"    {pid} = " + lines[0]] + ["    " + ln for ln in lines[1:]]
    return "\n".join(out) + ",\n"


def main(root, check=False):
    tex = os.path.join(root, "42", *EX.TEXDIR.strip("/").split("/"))
    lua = os.path.join(root, "42", "media", "lua", "client", "ZeD", "PhysPx.lua")
    src = open(lua, encoding="utf-8").read()
    for pid in PIDS:
        data, base, sprites = EX.build_plate(pid)
        pics = {pid: base, **sprites}
        new = lua_entry(pid, data)
        i, j = entry_span(src, pid)
        same = src[i:j] == new
        diff = 0
        for name, im in pics.items():
            path = os.path.join(tex, f"{name}.png")
            if check:
                old = np.array(Image.open(path).convert("RGBA")) if os.path.exists(path) else None
                if old is None or old.shape != np.array(im).shape or (old != np.array(im.convert("RGBA"))).any(): diff += 1
            else:
                im.save(path)
        print(f"{pid:16s} {data['w']}x{data['h']} sprites {len(sprites)}; entry {'same' if same else 'changed'}"
              + (f"; pictures differing {diff}" if check else ""))
        if not check: src = src[:i] + new + src[j:]
    if not check:
        with open(lua, "w", newline="\n", encoding="utf-8") as f: f.write(src)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(args[0], check="--check" in sys.argv)
