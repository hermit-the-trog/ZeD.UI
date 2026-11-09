"""Builds the base drawer_tabs_perf_sim compares against for punch list 120: the files the sim loads as they are on
origin/main, less the first round of the punch list 120 work (dc9aa53b..bc07ecf8: the kept draws), which QA measured
slower in the game. Everyone else's changes to those files stay in, so a frame that differs is this work's.
usage (from the repo root):  python -I ZeDUI/tools/qa/p120_base.py <out dir> [main-rev]
then:                        lua51 ZeDUI/tools/qa/drawer_tabs_perf_sim.lua <out dir>
"""
import os
import subprocess
import sys

FILES = [
    "42/media/lua/shared/ZeD/Scale.lua", "42/media/lua/shared/ZeD/Tokens.lua", "42/media/lua/shared/ZeD/Tr.lua",
    "42/media/lua/client/ZeD/Atoms.lua", "42/media/lua/client/ZeD/AtomExtensions.lua",
    "42/media/lua/client/ZeD/Molecules.lua", "42/media/lua/client/ZeD/ZeD_BodyFigure.lua",
    "42/media/lua/client/ZeD/ProtectionTab.lua", "42/media/lua/client/ZeD/EquipDoll.lua",
    "42/media/lua/client/ZeD/EquipmentTab.lua", "42/media/lua/client/ZeD/ThermalTab.lua",
    "42/media/lua/client/ZeD/IdentityTab.lua", "42/media/lua/client/ZeD/SkillsTab.lua",
]
ROUND1 = ("dc9aa53b", "bc07ecf8")


def git(*args):
    return subprocess.run(["git"] + list(args), check=True, capture_output=True).stdout


def main():
    out = sys.argv[1]
    rev = sys.argv[2] if len(sys.argv) > 2 else "origin/main"
    for f in FILES:
        p = os.path.join(out, f)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as fh:
            fh.write(git("show", rev + ":" + f).replace(b"\r\n", b"\n"))
    diff = git("diff", ROUND1[0], ROUND1[1], "--", *FILES).replace(b"\r\n", b"\n")
    r = subprocess.run(["patch", "-R", "-p1", "-d", out, "--no-backup-if-mismatch"], input=diff, capture_output=True)
    sys.stdout.write(r.stdout.decode("utf-8", "replace"))
    sys.stderr.write(r.stderr.decode("utf-8", "replace"))
    # the one hunk another change sits next to (render's first lines: win._equipPanel came in beside the epoch):
    # its two lines come out by hand
    eq = os.path.join(out, "42/media/lua/client/ZeD/EquipmentTab.lua")
    with open(eq, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    lines = [l for l in lines if "win._eqEpoch = ZeD.DrawMemo.epoch()" not in l
             and "the state the kept draws hang on (ZeD.DrawMemo.epoch)" not in l]
    with open(eq, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines))
    for f in FILES:
        rej = os.path.join(out, f + ".rej")
        if os.path.exists(rej):
            os.remove(rej)
        with open(os.path.join(out, f), encoding="utf-8") as fh:
            if "DrawMemo" in fh.read():
                sys.exit("p120_base: the first round did not come out cleanly (" + f + ")")
    print("p120_base: wrote", out)


if __name__ == "__main__":
    main()
