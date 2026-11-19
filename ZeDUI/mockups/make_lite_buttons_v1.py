"""Lite mode buttons, mockup v1 (Nov 18 2026, beta 21): today's buttons beside the Lite ones, in Dark and Light.
The director: "more basic buttons (not the double border, maybe bolder, full color)... the positive and negative
choice that the user makes in the accessibility menu." Lite: one 2-unit line, filled, and Yes/OK in the game's
good color, No/Cancel/Delete in its bad color (as vanilla's accept and cancel buttons: 0.25 fill, full line).
Run from the repo root; writes ZeDUI/mockups/zed_lite_buttons_v1.png."""
import os
from PIL import Image, ImageDraw, ImageFont

FONTS = os.path.join("ZeDUI", "workshop", "gallery", "fonts")
S = 3  # drawn at 3x, like ZeD at 4K


def font(n):
    return ImageFont.truetype(os.path.join(FONTS, "FiraMono-Regular.ttf"), n * S)


THEMES = {
    "Dark": dict(bg=(26, 26, 30), surf=(42, 42, 46), text=(212, 212, 216), line=(110, 110, 116), accent=(212, 146, 42)),
    "Light": dict(bg=(226, 226, 222), surf=(240, 240, 236), text=(30, 30, 34), line=(120, 120, 124), accent=(176, 112, 20)),
}
GOOD, BAD = (51, 204, 77), (230, 64, 64)   # the game's defaults; each player's own from Accessibility


def mix(a, b, t):
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def rr(d, box, r, **kw):
    d.rounded_rectangle([v * S for v in box], radius=r * S, **kw)


def button(d, x, y, w, label, th, kind, lite):
    h = 22
    if not lite:
        # today: one thin line; the default answer two (System 7)
        col = th["accent"] if kind == "default" else th["line"]
        rr(d, (x, y, x + w, y + h), 4, fill=th["surf"], outline=col, width=S)
        if kind == "default":
            rr(d, (x + 3, y + 3, x + w - 3, y + h - 3), 2, outline=col, width=S)
        tc = th["accent"] if kind == "default" else th["text"]
    else:
        col = {"good": GOOD, "bad": BAD}.get(kind, th["line"])
        fill = mix(th["surf"], col, 0.25) if kind in ("good", "bad") else th["surf"]
        rr(d, (x, y, x + w, y + h), 4, fill=fill, outline=col, width=2 * S)
        tc = th["text"]
    f = font(10)
    l, t, r, b = d.textbbox((0, 0), label, font=f)
    d.text(((x + w / 2) * S - (r - l) / 2 - l, (y + h / 2) * S - (b - t) / 2 - t), label, font=f, fill=tc)


def panel(th, name):
    W, H = 330, 150
    im = Image.new("RGB", (W * S, H * S), th["bg"])
    d = ImageDraw.Draw(im)
    d.text((10 * S, 8 * S), name.upper(), font=font(9), fill=th["text"])
    for row, (title, lite) in enumerate([("TODAY", False), ("LITE", True)]):
        y = 34 + row * 56
        d.text((10 * S, y * S), title, font=font(9), fill=th["accent"])
        y += 16
        button(d, 10, y, 60, "Back", th, "plain", lite)
        button(d, 78, y, 70, "Cancel", th, "bad" if lite else "plain", lite)
        button(d, 156, y, 70, "Delete", th, "bad" if lite else "plain", lite)
        button(d, 234, y, 86, "OK", th, "good" if lite else "default", lite)
    return im


def main():
    ims = [panel(THEMES[n], n) for n in ("Dark", "Light")]
    out = Image.new("RGB", (ims[0].width, sum(i.height for i in ims)))
    y = 0
    for i in ims:
        out.paste(i, (0, y))
        y += i.height
    p = os.path.join("ZeDUI", "mockups", "zed_lite_buttons_v1.png")
    out.save(p)
    print(p, out.size)


if __name__ == "__main__":
    main()
