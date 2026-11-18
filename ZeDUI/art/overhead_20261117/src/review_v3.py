from PIL import Image, ImageDraw, ImageFont
import overhead_light as L, overhead as O
F = "/mnt/user-data/uploads/ZeD_design_refs/overhead_refs_20261115/fonts/"
f_h = ImageFont.truetype(F + "FiraSans-SemiBold.ttf", 22); f_s = ImageFont.truetype(F + "FiraMono-Regular.ttf", 14)
BG, CARD, TXT, DIM = (24, 24, 26), (122, 120, 114), (232, 230, 224), (160, 160, 160)
GAME = [("CarKey", "Car key: yes"), ("CarKey_none", "Car key: no"), ("eyeconOn", "Search mode on"), ("eyeconOff", "Search mode off"),
        ("Skull", "PvP on (MP)"), ("voiceon", "Talking (MP)"), ("voicemuted", "Muted (MP)"), ("ArrowUp", "XP up"), ("ArrowDown", "XP down")]
NEW = [("door_key", "Locked, have key"), ("door_nokey", "Locked, no key"), ("hotwire", "No key, can hotwire"), ("noise", "You made noise"),
       ("gun_empty", "Gun empty"), ("gun_jammed", "Gun jammed"), ("weapon_breaking", "Weapon nearly broken"), ("water_tainted", "Tainted water"),
       ("typing", "Typing (MP)"), ("spotted", "Zombie spotted you")]
K, CW, CH = 5, 190, 190
def row(S, d, y, items, src):
    for i, (n, lab) in enumerate(items):
        x = 12 + i * (CW + 8)
        d.rectangle([x, y, x + CW, y + CH], fill=CARD)
        im = Image.open(f"{src}/{n}.png"); im = im.resize((im.width * K, im.height * K), Image.NEAREST)
        S.alpha_composite(im, (x + (CW - im.width) // 2, y + (CH - im.height) // 2))
        d.text((x + 2, y + CH + 6), lab, font=f_s, fill=TXT)
W = 12 + 10 * (CW + 8)
big = Image.open("/mnt/user-data/uploads/ZeD_design_refs/overhead_refs_20261115/zqa_m79_3840x2160_t_SportsCar_card.png").convert("RGBA")
crop = (1560, 860, 2160, 1260); hx, hy = 1932 - crop[0], 1028 - crop[1]
def over(frame, n):
    b = Image.open(f"art/overhead_light/2x/{n}.png"); body_w = (b.width // 2 - 6)
    frame.alpha_composite(b, (hx - body_w - 2, hy - 6 - b.height + 12))
scenes = []
for n, lab in (("CarKey", "Walk up to a car: you have its key"), ("CarKey_none", "... you don't"), ("eyeconOn", "Search mode on")):
    fr = big.crop(crop); over(fr, n); scenes.append((fr, lab))
H = 40 + 2 * (CH + 70) + 50 + 400 + 60
S = Image.new("RGBA", (W + 12, H), BG); d = ImageDraw.Draw(S)
d.text((12, 8), "The game's icons, redrawn  (on the light balloon, Nov 17)", font=f_h, fill=TXT)
row(S, d, 44, GAME, "art/overhead_light/1x")
y2 = 44 + CH + 40
d.text((12, y2), "New ideas (concepts, the director's pick)", font=f_h, fill=TXT)
row(S, d, y2 + 36, NEW, "art/overhead_light/1x")
y3 = y2 + 36 + CH + 44
d.text((12, y3), "Actual size on a 4K screen", font=f_h, fill=TXT)
for i, (fr, lab) in enumerate(scenes):
    x = 12 + i * 612; S.alpha_composite(fr, (x, y3 + 36)); d.text((x, y3 + 36 + 404), lab, font=f_s, fill=DIM)
S.save("overhead_icons_review_v3_light.png"); print(S.size)
