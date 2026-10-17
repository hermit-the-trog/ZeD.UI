"""The belt's per-slot strap materials, outside the game: the real ZeD_Belt.lua lays out loadouts of mocked worn
items (leather belt and holster; ALICE camo webbing, pack, bedroll, taped holster; rope belt and frame pack; the
breathing pack; nothing worn), finds each slot's provider and material, merges the runs and draws them; the picture
must equal the reference (d_straps / d_belt pieces laid on the same runs) pixel for pixel at 1x and 2x; the closure
must match the waist belt (buckle on leather or no belt, knot on rope with the strap cut under its eye, clip on webbing
and nylon) and sit between Belt L and Belt R. usage: python test_straps.py"""
import os, sys
import numpy as np
from PIL import Image
import lupa.luajit21 as lj
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); os.chdir(HERE)
import d_straps as S, d_belt as DB, d_closures as DC          # noqa: E402
ROOT = os.path.join(HERE, "out", "mod", "ZeD-UI")
S.export(ROOT); DB.export(ROOT); DC.export(ROOT)
_REPO = os.path.join(HERE, "..", "..", "..", "42", "media", "lua", "client", "ZeD", "ZeD_Belt.lua")
SRC = _REPO if os.path.exists(_REPO) else os.path.join(HERE, "..", "belt", "ZeD_Belt.lua")
FAILS = []
def check(what, ok, detail=""):
    print(("  ok   " if ok else "  FAIL ") + what + ("" if ok else "  " + str(detail)))
    if not ok: FAILS.append(what)

# loadouts: worn items (full type, attachments provided, bag on back) and the hotbar's slots in order
LOADOUTS = {
    "civilian": ([("Base.Belt2", ["SmallBeltLeft", "SmallBeltRight"], False), ("Base.HolsterSimple_Brown", ["HolsterRight"], False)],
                 ["Back", "SmallBeltLeft", "SmallBeltRight", "HolsterRight"], "leather", "buckle"),
    "military": ([("Base.Bag_ALICE_BeltSus_Camo", ["SmallBeltLeft", "SmallBeltRight", "WebbingRight", "WebbingLeft"], False),
                  ("Base.Bag_ALICEpack_Army", ["BedrollBottomALICE"], True), ("Base.Holster_DuctTape", ["HolsterRight"], False)],
                 ["Back", "SmallBeltLeft", "SmallBeltRight", "WebbingLeft", "WebbingRight", "BedrollBottomALICE", "HolsterRight"],
                 "webbing_camo", "clip_black"),
    "makeshift": ([("Base.RopeBelt", ["SmallBeltLeft"], False), ("Base.Bag_CraftedFramepack_Large", ["BedrollBottom"], True),
                   ("Base.Holster_Hide", ["HolsterRight"], False)],
                  ["Back", "SmallBeltLeft", "BedrollBottom", "HolsterRight"], "rope", "knot"),
    "firefighter": ([("Base.SCBA", ["SmallBeltLeft", "SmallBeltRight", "WebbingLeft"], False)],
                    ["Back", "SmallBeltLeft", "SmallBeltRight", "WebbingLeft"], "harness", "clip_black"),
    "nothing": ([], ["Back"], "leather", "buckle"),
    "modded": ([("Mod.FancyBelt", ["SmallBeltLeft", "SmallBeltRight"], False)], ["Back", "SmallBeltLeft", "SmallBeltRight"], "leather", "buckle"),
    "rightonly": ([("Mod.Sash", ["SmallBeltRight"], False), ("Base.HolsterSimple_Brown", ["HolsterRight"], False)],
                  ["Back", "SmallBeltRight", "HolsterRight"], "leather", "buckle"),
    "olive": ([("Base.Bag_ALICE_BeltSus", ["SmallBeltLeft", "SmallBeltRight", "WebbingRight", "WebbingLeft"], False)],
              ["Back", "SmallBeltLeft", "SmallBeltRight", "WebbingLeft", "WebbingRight"], "webbing_olive", "clip_brass"),
    "firstright": ([("Mod.Sash", ["SmallBeltRight"], False)], ["SmallBeltRight", "Back"], "leather", "buckle"),
}
WANT_MATS = {"civilian": ["sling", "leather", "leather", "holster_brown"],
             "military": ["webbing_olive", "webbing_camo", "webbing_camo", "webbing_camo", "webbing_camo", "webbing_olive", "holster_tape"],
             "makeshift": ["rope", "rope", "rope", "holster_hide"],
             "firefighter": ["harness", "harness", "harness", "harness"], "nothing": ["sling"], "modded": ["sling", "leather", "leather"],
             "rightonly": ["sling", "leather", "holster_brown"], "firstright": ["leather", "sling"],
             "olive": ["sling", "webbing_olive", "webbing_olive", "webbing_olive", "webbing_olive"]}
# how many slots sit left of the closure: after Belt L, else before Belt R, else the middle
WANT_K = {"civilian": 2, "military": 2, "makeshift": 2, "firefighter": 2, "nothing": 1, "modded": 2, "rightonly": 1,
          "firstright": 0, "olive": 2}


def ref_runs(strapX, strapW, boxes, mats, waist, k, gap, hole=None):
    n = len(boxes); half = gap // 2
    runs = []
    for i, (bx, bw) in enumerate(boxes):
        x0 = strapX if (i == 0 and k >= 1) else bx - half
        x1 = (strapX + strapW) if (i == n - 1 and k < n) else bx + bw + half
        runs.append([x0, x1, mats[i]])
    lx0 = runs[k - 1][1] if k >= 1 else strapX
    lx1 = runs[k][0] if k < n else strapX + strapW
    out = []
    for r in runs[:k] + [[lx0, lx1, waist]] + runs[k:]:
        if r[1] > r[0]:
            if out and out[-1][2] == r[2] and out[-1][1] >= r[0] - 1: out[-1][1] = r[1]
            else: out.append(list(r))
    if hole:
        cut = []
        for r in out:
            if r[0] < hole[1] and r[1] > hole[0]:
                if hole[0] > r[0]: cut.append([r[0], hole[0], r[2]])
                if r[1] > hole[1]: cut.append([hole[1], r[1], r[2]])
            else: cut.append(r)
        out = cut
    return out


_pc = {}
def ref_picture(runs, w, k):
    out = Image.new("RGBA", (w, 30 * k), (0, 0, 0, 0))
    for x0, x1, mat in runs:
        key = (mat, x1 - x0, k)
        if key not in _pc:
            _pc[key] = DB.assemble(x1 - x0, k) if mat == "leather" else S.assemble(mat, x1 - x0, k)
        out.alpha_composite(_pc[key], (x0, 0))
    return np.array(out)


class Paint:
    def __init__(s, w, h): s.a = np.zeros((h, w, 4), np.uint8); s.clip = None; s.cache = {}; s.textures = []
    def tex(s, path, x, y, w, h):
        s.textures.append(path)
        if path not in s.cache: s.cache[path] = Image.open(os.path.join(ROOT, "42", path)).convert("RGBA")
        im = np.array(s.cache[path].resize((int(w), int(h)), Image.NEAREST))
        x, y = int(x), int(y); x0, y0, x1, y1 = x, y, x + im.shape[1], y + im.shape[0]
        if s.clip:
            cx, cy, cw, ch = s.clip; x0, y0, x1, y1 = max(x0, cx), max(y0, cy), min(x1, cx + cw), min(y1, cy + ch)
        x0, y0 = max(0, x0), max(0, y0); x1, y1 = min(s.a.shape[1], x1), min(s.a.shape[0], y1)
        if x1 <= x0 or y1 <= y0: return
        sub = im[y0 - y:y1 - y, x0 - x:x1 - x]; m = sub[..., 3] > 0
        s.a[y0:y1, x0:x1][m] = sub[m]


def run(name, k):
    worn, slots, want_waist, want_closure = LOADOUTS[name]
    L = lj.LuaRuntime(unpack_returned_tuples=True)
    L.execute('''require = function() end
        Texture = { getSharedTexture = function(path, f) return { path = path } end }
        getTimestampMs = function() return 0 end
        local function derive(base, name) local c = {}; c.__index = c; setmetatable(c, { __index = base }); c.derive = derive; return c end
        ZeD_Panel = { derive = derive }
        Events = setmetatable({}, { __index = function(t, k) local e = { Add = function() end, Remove = function() end }; rawset(t, k, e); return e end })
        print = function() end
        ZeD = {}''')
    L.execute(f"ZeD.T = {{ scale = {k}, px = function(v) return math.floor(v * {k} + 0.5) end }}")
    L.execute(open(SRC, "rb").read())
    g = L.globals()
    # the worn items and the slots
    L.execute('''function make_item(ft, provided, bag)
        local ap = { size = function() return #provided end, get = function(_, i) return provided[i + 1] end }
        return { getFullType = function() return ft end, getAttachmentsProvided = function() return #provided > 0 and ap or nil end,
                 getAttachmentReplacement = function() return bag and "Bag" or nil end }
    end''')
    items = [g.make_item(ft, L.table_from(ap), bag) for ft, ap, bag in worn]
    g.WORN = L.table_from(items)
    L.execute('''CHR = { getWornItems = function() return { size = function() return #WORN end, getItemByIndex = function(_, i) return WORN[i + 1] end } end,
                         isHandItem = function() return false end }''')
    sl = L.table_from([L.table_from({"s": L.table_from({"slot": L.table_from({"slotType": t})})}) for t in slots])
    g.SLOTS = sl
    p = Paint(2000 * k, 60 * k)
    g.py_tex = lambda path, x, y, ww, hh: p.tex(path, x, y, ww, hh)
    g.py_clip = lambda x, y, ww, hh: setattr(p, "clip", (int(x), int(y), int(ww), int(hh)))
    g.py_unclip = lambda: setattr(p, "clip", None)
    L.execute('''local slots = {}
        for i, s in ipairs(SLOTS) do slots[i] = { slot = s.s.slot, item = nil } end
        O = setmetatable({}, { __index = ZeD_BeltHUD })
        function O:player() return CHR end
        function O:drawTextureScaled(t, x, y, w, h) py_tex(t.path, x, y, w, h) end
        function O:drawTextureScaledAspect(t, x, y, w, h) py_tex(t.path, x, y, w, h) end
        function O:setStencilRect(x, y, w, h) py_clip(x, y, w, h) end
        function O:clearStencilRect() py_unclip() end
        function O:drawRect() end
        function O:drawRectBorder() end
        O.playerNum = 0
        W_, H_ = O:_layout(slots)
        O:_drawStrap()''')
    O = g.O
    runs = [[int(r[1]), int(r[2]), r[3]] for r in O._runs.values()]
    st = O._strap
    boxes = [(int(b.x), int(b.w)) for b in O._boxes.values() if b.kind == "slot"]
    mats = [r for r in WANT_MATS[name]]
    kk = WANT_K[name]
    # the closure between box kk and kk+1 (or at the strap's end), its art centred in the 58 x 40 place
    bk = O._buckle
    left_ok = kk == 0 or int(bk.x) >= boxes[kk - 1][0] + boxes[kk - 1][1]
    right_ok = kk == len(boxes) or int(bk.x) + int(bk.w) <= boxes[kk][0]
    check(f"{k}x {name}: closure after slot {kk}", left_ok and right_ok, (int(bk.x), boxes))
    cx = int(bk.x) + (int(bk.w) - 58 * k) // 2
    hole = [cx + DC.KNOT_CUT[0] * k, cx + DC.KNOT_CUT[1] * k] if want_closure == "knot" else None
    want = ref_runs(int(st.x), int(st.w), boxes, mats, want_waist, kk, int(g.ZeD.T.px(11)), hole)
    check(f"{k}x {name}: runs", runs == want, f"{runs} vs {want}")
    check(f"{k}x {name}: waist {want_waist}", O._waist == want_waist, O._waist)
    y = int(st.y) + (int(st.h) - 30 * k) // 2
    got = p.a[y:y + 30 * k, int(st.x):int(st.x) + int(st.w)]
    ref = ref_picture([[r[0] - int(st.x), r[1] - int(st.x), r[2]] for r in want], int(st.w), k)
    check(f"{k}x {name}: picture", np.array_equal(got, ref))
    p.textures = []
    L.execute("O:_drawBuckle()")
    got_c = "buckle" if any("buckles" in t for t in p.textures) else None
    for t in p.textures:
        if "closure_" in t: got_c = t.rsplit("closure_", 1)[1][:-4]
    check(f"{k}x {name}: closure {want_closure}", got_c == want_closure, got_c)
    if want_closure != "buckle":
        # the closure's picture where it was drawn
        src = Image.open(os.path.join(ROOT, "42", "media", "textures", "ZeD", "belt", f"closure_{want_closure}.png")).convert("RGBA")
        ch = src.height                     # the knot stands 52 tall, the clips 40; both centred on the buckle's place
        art = np.array(src.resize((58 * k, ch * k), Image.NEAREST))
        cy = int(bk.y) + (int(bk.h) - ch * k) // 2
        reg = p.a[max(0, cy):cy + ch * k, cx:cx + 58 * k]
        art = art[max(0, -cy):]
        m = art[..., 3] > 0
        check(f"{k}x {name}: {want_closure} drawn in place", np.array_equal(reg[m], art[m]))
    return Image.fromarray(p.a[:, :int(g.W_) + 10])


if __name__ == "__main__":
    shots = []
    for k in (1, 2):
        for name in LOADOUTS: shots.append(run(name, k) if k == 1 else run(name, k))
    print(f"{len(FAILS)} failed", FAILS)
    sys.exit(1 if FAILS else 0)
