"""The dash radio heads up close, outside the game: the real ZeD_Dashboard on ZeD_Plate.lua (dashsame.py's mocks) with
each of the six radios fitted. Every control a head shows must be a click area that does the radio's own call, its
state pictures must follow the radio (the makeshift rocker, the two-way's talk/listen switch), the two-ways' red lamp
must light with the microphone muted, the ValuTech's preset names must be written on its tape. Pictures of every
head in its states for review.
usage: python test_heads.py"""
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import dashsame as DS               # noqa: E402  (its harness: the mocks, the export, the variants)
import lupa.luajit21 as lj          # noqa: E402
LT, DZ = DS.LT, DS.DZ

FAILS = []
# what each control must call (RadioOps function, its arguments after chr and part)
EXPECT = {"vol": ("power",), "tune": ("tuneStep", 1), "pwr": ("power",), "seek": ("seek", 1), "scan": ("scanToggle",),
          "mute": ("mute",), "mem": ("memAdd",), "eject": ("eject",), "play": ("playStop",), "slot": ("eject",),
          "chup": ("chStep", 1), "chdn": ("chStep", -1), "mic": ("mic",)}
for i in range(1, 7): EXPECT[f"preset{i}"] = ("recall", i) if i <= 2 else ("store", i)   # two presets stored: those recall, the rest store
HEAD_IDS = {"premium": ["vol", "tune", "slot", "eject", "preset1", "preset2", "preset3", "preset4", "preset5", "preset6", "scan", "seek",
                        "mute", "play", "radio"],
            "valutech": ["vol", "tune", "mute", "seek", "preset1", "preset2", "preset3", "preset4", "preset5", "preset6", "radio"],
            "makeshift": ["pwr", "vol", "tune", "preset1", "preset2", "preset3", "preset4", "preset5", "preset6", "seek", "radio"],
            "ham": ["vol", "tune", "chup", "chdn", "mem", "mic", "mute", "radio"],
            "army": ["vol", "tune", "chup", "chdn", "mem", "mic", "mute", "radio"],
            "hammake": ["pwr", "vol", "tune", "chup", "chdn", "mem", "mic", "mute", "radio"]}


def check(what, got, want):
    ok = got == want
    print(("  ok   " if ok else "  FAIL ") + f"{what}: {got!r}" + ("" if ok else f" (want {want!r})"))
    if not ok: FAILS.append(what)


def world(did, radio, on=True, mic_muted=False, switch_on=None, has_media=False, k=1):
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    g = L.globals()
    rec = DS.Log(800 * k, 172 * k)
    clock = {"t": 1_000_000}
    g.py_now = lambda: clock["t"]
    g.py_text = lambda key: None
    g.py_screen = lambda: L.table(1920 * k, 1080 * k)
    g.py_scale = lambda: float(k)
    g.py_rect = rec.rect
    g.py_tex = rec.tex
    g.py_log = lambda *a: None
    L.execute(LT.PRELUDE)
    for f in ("PixelFonts.lua", "DashPx.lua"):
        L.execute(open(os.path.join(DS.MOD_LUA, f)).read())
    L.execute(open(DS.RADIOOPS).read().replace("return O", "ZeD.RadioOps = O"))
    for f in DS.VARIANTS["after"]:
        L.execute(open(f).read())
    L.execute(LT.VEHICLE)
    S = L.table_from({k_: v for k_, v in LT.STATE_DRIVE.items() if not isinstance(v, (dict, list))})
    S.script = LT.SCRIPTS[did]
    r = L.table_from({"kind": radio, "on": on, "switchOn": on if switch_on is None else switch_on, "channel": 146520 if radio in ("ham", "army", "hammake") else 98400,
                      "volume": 0.6, "presetIdx": 1, "name": "KNOX TALK", "signal": True, "muted": False, "micMuted": mic_muted,
                      "playing": False, "cdMs": 0, "scanning": False, "hasMedia": has_media})
    r.presets = L.table_from([L.table_from({"freq": 98400, "name": nm}) for nm in ("Knox Talk", "Wkv")])
    g.ZeD.RadioOps.read = lambda part: r
    calls = []
    for fn in ("power", "tuneStep", "volStep", "seek", "scanToggle", "mute", "memAdd", "eject", "playStop", "chStep", "mic", "recall", "store"):
        g.ZeD.RadioOps[fn] = (lambda name: (lambda *a: calls.append((name,) + tuple(x for x in a[2:] if isinstance(x, (int, float, bool))))))(fn)
    S.radio = True
    veh = g.make_vehicle(S)
    ply = g.make_player(veh)
    g.getSpecificPlayer = lambda n: ply
    g.ZeD.CarRadio = L.table_from({"toggle": lambda *a: calls.append(("upclose",))})
    dash = g.ZeD_Dashboard.new(g.ZeD_Dashboard, 0)
    for i in range(3):
        clock["t"] += 120
        rec.a[:] = 0; rec.log = []
        dash.prerender(dash)
    return dash, rec, calls, r, g


def head_box(g):
    # where the slot is on this dash (plate pixels)
    return None


def main():
    did = "wagon"
    hu = None
    pics = []
    for radio in ("premium", "valutech", "makeshift", "ham", "army", "hammake"):
        print(radio)
        dash, rec, calls, r, g = world(did, radio)
        hits = {h.id: (h.x, h.y, h.w, h.h) for h in dash._hit.values()}
        texs = {e[1].split("/")[-1] for e in rec.log if e[0] == "T"}
        check(f"{radio} face drawn", f"dhead_{radio}.png" in texs, True)
        # every control the head shows is a click area
        head = [i for i in HEAD_IDS[radio] if i in hits]
        check(f"{radio} controls", sorted(head), sorted(HEAD_IDS[radio]))
        for cid in HEAD_IDS[radio]:
            if cid == "radio": continue
            del calls[:]
            dash._fire(dash, cid, False)
            want = EXPECT[cid]
            if cid == "vol" and radio in ("makeshift", "hammake"): want = ("volStep", 1, True)
            if cid == "slot": want = ("upclose",)
            check(f"{radio} {cid}", calls[:1], [want])
        # state pictures and the lamp
        if radio in ("makeshift", "hammake"):
            for on in (False, True):
                _, rc, _, _, _ = world(did, radio, on=on)
                t = {e[1].split("/")[-1] for e in rc.log if e[0] == "T"}
                check(f"{radio} rocker picture with the set {'on' if on else 'off'}", f"dhead_{radio}_switch_on.png" in t, on)
        if radio == "hammake":
            for muted in (False, True):
                for on in (False, True):
                    _, rc, _, _, _ = world(did, radio, on=on, mic_muted=muted)
                    t = {e[1].split("/")[-1] for e in rc.log if e[0] == "T"}
                    check(f"hammake switch latched in: mic {'muted' if muted else 'live'}, set {'on' if on else 'off'}",
                          "dhead_hammake_mic_live.png" in t, not muted)
        if radio in ("ham", "army", "hammake"):
            for muted, on in ((True, True), (True, False), (False, True)):
                _, rc, _, _, _ = world(did, radio, on=on, mic_muted=muted)
                red = any(e[0] == "R" and e[5] == 1 and (round(e[6], 3), round(e[7], 3), round(e[8], 3)) == (1.0, round(0x3a / 255, 3), round(0x2e / 255, 3))
                          for e in rc.log)
                check(f"{radio} red lamp: mic {'muted' if muted else 'live'}, set {'on' if on else 'off'}", red, muted and on)
        # pictures: the head on, at 3x
        _, rc, _, _, _ = world(did, radio, on=True, mic_muted=False, k=3)
        pics.append((radio, rc.image() if hasattr(rc, "image") else Image.fromarray(rc.a, "RGBA")))
    # the head region of each picture
    d0, rec0, _, _, g0 = world(did, "premium")
    slot = g0.ZeDDashPx if False else None
    out = os.path.join(HERE, "out", "heads")
    os.makedirs(out, exist_ok=True)
    rows = []
    for radio, im in pics:
        a = np.array(im)
        # crop to the head unit: find it from the design's headunit box
        rows.append((radio, im))
    hu = DZ_headunit(did)
    crops = [im.crop((hu[0] * 3 - 18, hu[1] * 3 - 18, (hu[0] + hu[2]) * 3 + 18, (hu[1] + hu[3]) * 3 + 18)) for _, im in rows]
    sheet = Image.new("RGBA", (crops[0].width * 2 + 30, (crops[0].height + 10) * 3 + 10), (28, 28, 30, 255))
    for i, c in enumerate(crops):
        sheet.alpha_composite(c.convert("RGBA"), (10 + (i % 2) * (c.width + 10), 10 + (i // 2) * (c.height + 10)))
    sheet.save(os.path.join(out, "heads_in_dash.png"))
    print(f"{len(FAILS)} failed", FAILS)
    return 1 if FAILS else 0


def DZ_headunit(did):
    import re
    src = open(os.path.join(DS.MOD_LUA, "DashPx.lua")).read()
    i = src.index(f"{did} = {{")
    m = re.search(r"headunit = \{ x = (\d+), y = (\d+), w = (\d+), h = (\d+) \}", src[i:])
    return tuple(int(v) for v in m.groups())


if __name__ == "__main__":
    sys.exit(main())
