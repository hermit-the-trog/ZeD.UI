"""Exports every plate with the 336 px machine faces and their narrow faces (plates_336.py) through export_phys.py,
then adds the `narrow` table (machine plate -> its narrow face) to PhysPx.lua.
usage: python export_336.py [mod root]   (default: ./out/mod/ZeD-UI, the mod is left alone)"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import plates_336 as P336            # noqa: E402  (lays the new designs over the registry first)
import export_phys as EX             # noqa: E402
from export_lua import to_lua        # noqa: E402

NOTE = ("-- narrow: each machine plate's 200 px narrow face (design session Oct 29 2026, PLATE_SIZES_SPEC.md): drawn\n"
        "-- where the full card is narrower than the main face at the plates' whole zoom (fixed UI scale 0.5, Auto at\n"
        "-- 720/800 with the 16 px font). Same click areas and live parts as the main face.\n")


def export(root, only=None):
    out, pictures = EX.export(root, only)
    out["narrow"] = dict(P336.NARROW)
    path = os.path.join(root, "42", "media", "lua", "client", "ZeD", "PhysPx.lua")
    head = open(path, encoding="utf-8").read().split("ZeD = ZeD or {}\n")[0]
    with open(path, "w", newline="\n", encoding="utf-8") as f:
        f.write(head + NOTE + "ZeD = ZeD or {}\n" + "ZeD.PhysPx = " + to_lua(out) + "\nreturn ZeD.PhysPx\n")
    print("narrow table:", len(out["narrow"]), "plates")
    return out, pictures


if __name__ == "__main__":
    export(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "out", "mod", "ZeD-UI"))
