"""ZeDUI/tools/qa/belt_hand_icons_check.py (Nov 11 2026, punch list 155): the belt's empty hands as a right and a left
hand. The icons exist at every size, the left is the right mirrored, and the belt draws them in place of the words.
Run from the repo root: python3 ZeDUI/tools/qa/belt_hand_icons_check.py"""
import sys
from PIL import Image, ImageOps
fails = 0
def ok(c, m):
    global fails
    if not c: fails += 1; print("FAIL", m)
D = "42/media/textures/ZeD/wheel/"
for s in (16, 24, 32, 48):
    r = Image.open(f"{D}{s}/zw_hand_right.png").convert("RGBA"); l = Image.open(f"{D}{s}/zw_hand_left.png").convert("RGBA")
    h = Image.open(f"{D}{s}/zw_hand.png").convert("RGBA")
    ok(r.size == (s, s) and l.size == (s, s), f"{s}: both icons at {s}")
    ok(r.tobytes() == h.tobytes(), f"{s}: the right hand is the open hand")
    ok(l.tobytes() == ImageOps.mirror(r).tobytes(), f"{s}: the left hand is the right mirrored")
    a = r.getchannel("A"); w = a.size[0]
    left_px = sum(1 for x in range(w // 3) for y in range(w) if a.getpixel((x, y)) > 0)
    right_px = sum(1 for x in range(w - w // 3, w) for y in range(w) if a.getpixel((x, y)) > 0)
    ok(left_px > right_px * 0.5, f"{s}: the right hand's thumb is on the left (seen from its back)")
src = open("42/media/lua/client/ZeD/ZeD_Belt.lua", encoding="utf-8").read()
ok('local id = (b.which == "p") and "hand_right" or "hand_left"' in src, "the main hand is the right, the off hand the left")
ok("elseif o.icon then" in src and "ZeD.Atoms.drawPxIcon(self, o.icon" in src, "an empty hand draws its icon")
ok('"IGUI_health_Right_Hand"' in src and '"IGUI_health_Left_Hand"' in src, "the belt's hint names the hands in the game's words")
print(f"belt_hand_icons_check: {'PASS' if fails == 0 else str(fails) + ' failed'}")
sys.exit(1 if fails else 0)
