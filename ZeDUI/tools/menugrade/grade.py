"""The main menu's colour grade (Oct 19 2026; director: "color grade our main menu graphic to match the game's
current vanilla main menu graphic. Want to make sure we are consistent on the eyes").

Vanilla Build 42's menu is its title video (media/videos/title_screen_background.bik): a low-key night room, deep
blacks, cool blue-teal shadows, warm orange only where the lamp falls. The desk picture is moved toward it in CIELAB:
its lightness, tint and colourfulness (each channel's mean and spread) toward the video's, by a strength k
(0 = as drawn, 1 = the video's statistics). The same transform goes on every desk texture, so they stay matched.

usage: py grade.py <frames dir> <strength> [out dir]
  frames dir: screenshots of the video (zqa_tv_1/2/4/5.png from ZeDUI/tools/qa/zedqa_titlevideo.lua; frame 3 is the
  lamp's flicker and is left out, the desk is drawn lamp-on)
  reads the ungraded art from ZeDUI/art/main_menu/v3, writes the graded textures to out dir (default: the mod's
  media/textures/ZeD/mainmenu) and prints the desk's measured margin colours, graded, for ZeD_MainMenu.lua."""
import json
import os
import sys

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "..", "art", "main_menu", "v3")
MOD_TEX = os.path.join(HERE, "..", "..", "..", "42", "media", "textures", "ZeD", "mainmenu")


# --- sRGB <-> CIELAB (D65) -----------------------------------------------------------------------------------------
def _lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _gam(c):
    c = np.where(c <= 0.0031308, c * 12.92, 1.055 * np.power(np.clip(c, 0, None), 1 / 2.4) - 0.055)
    return np.clip(np.round(c * 255.0), 0, 255)


M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
MI = np.linalg.inv(M)
WP = np.array([0.95047, 1.0, 1.08883])


def rgb2lab(rgb):
    xyz = _lin(rgb.astype(float)) @ M.T / WP
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def lab2rgb(lab):
    fy = (lab[..., 0] + 16) / 116
    fx, fz = fy + lab[..., 1] / 500, fy - lab[..., 2] / 200
    f = np.stack([fx, fy, fz], -1)
    xyz = np.where(f ** 3 > 0.008856, f ** 3, (f - 16 / 116) / 7.787) * WP
    return _gam(xyz @ MI.T)


def stats(lab, mask=None):
    v = lab.reshape(-1, 3) if mask is None else lab[mask]
    return v.mean(0), v.std(0)


def make_grade(src_mu, src_sd, dst_mu, dst_sd, k):
    """per channel: (x - mu_s) / sd_s * sd_t + mu_t, blended in by k (kept for reference: matching the
    statistics alone barely moved the desk; the look below is what the director sees)"""
    def grade(lab):
        out = (lab - src_mu) / src_sd * dst_sd + dst_mu
        return lab + k * (out - lab)
    return grade


# The look (what vanilla's night room does): exposure down with the shadows crushed by a curve, the shadows
# and mid-tones cooled toward blue-teal, mid-tone colour pulled back, and bright warm light (the lamp's pool,
# the bulb) keeping its warmth, as the video's lamp does. k = 0..1 strength.
LOOK = {"exposure": 0.62, "gamma": 1.35, "tint_a": -2.5, "tint_b": -9.0, "chroma": 0.62}


def make_look(k):
    e = 1 + k * (LOOK["exposure"] - 1)
    g = 1 + k * (LOOK["gamma"] - 1)
    ta, tb = k * LOOK["tint_a"], k * LOOK["tint_b"]
    cs = 1 + k * (LOOK["chroma"] - 1)

    def grade(lab):
        L, a, b = lab[..., 0], lab[..., 1], lab[..., 2]
        Ln = np.clip(L / 100.0, 0, 1)
        L2 = 100.0 * np.power(Ln, g) * e
        hi = np.clip((Ln - 0.45) / 0.4, 0, 1)                       # the highlights' weight
        warm = np.clip((a + b) / 40.0, 0, 1) * hi                     # bright warm light keeps its colour
        c = cs + (1 - cs) * warm
        shadow = 1 - hi
        a2 = a * c + ta * shadow
        b2 = b * c + tb * shadow
        return np.stack([L2, a2, b2], -1)
    return grade


def apply(img, grade):
    a = np.array(img.convert("RGBA")).astype(float)
    rgb, al = a[..., :3], a[..., 3:]
    g = lab2rgb(grade(rgb2lab(rgb)))
    return Image.fromarray(np.concatenate([g, al], -1).astype(np.uint8), "RGBA")


def video_stats(frames_dir):
    labs = []
    for n in (1, 2, 4, 5):
        p = os.path.join(frames_dir, "zqa_tv_%d.png" % n)
        if os.path.exists(p):
            labs.append(rgb2lab(np.array(Image.open(p).convert("RGB")).astype(float)).reshape(-1, 3))
    v = np.concatenate(labs)
    return v.mean(0), v.std(0)


def main():
    frames, k = sys.argv[1], float(sys.argv[2])
    out = sys.argv[3] if len(sys.argv) > 3 else MOD_TEX
    os.makedirs(out, exist_ok=True)
    dmu, dsd = video_stats(frames)
    desk = Image.open(os.path.join(ART, "desk.png")).convert("RGBA")
    dl = rgb2lab(np.array(desk)[..., :3].astype(float))
    alpha = np.array(desk)[..., 3] > 0
    smu, ssd = stats(dl, alpha)
    print("video  L a b mean %s sd %s" % (np.round(dmu, 1), np.round(dsd, 1)))
    print("desk   L a b mean %s sd %s" % (np.round(smu, 1), np.round(ssd, 1)))
    grade = make_look(k)
    for name in ("desk.png", "desk_lampdim.png", "dial_clean.png"):
        apply(Image.open(os.path.join(ART, name)), grade).save(os.path.join(out, name))
    # the margins and lens colours ZeD_MainMenu.lua draws itself, graded the same way
    info = {"WALL_L": "110907", "WALL_R": "1e140c", "DESK_L": "1f0d07", "DESK_R": "0d0503",
            "HDD_OFF": "1f1404", "FLOPPY_OFF": "0e1811", "NEEDLE_C": "7f2012"}
    for key, hx in info.items():
        c = np.array([[[int(hx[i:i + 2], 16) for i in (0, 2, 4)]]], float)
        g = lab2rgb(grade(rgb2lab(c)))[0, 0].astype(int)
        print("%-10s %s -> %02x%02x%02x" % (key, hx, *g))
    print("k", k, "->", out)


if __name__ == "__main__":
    main()
