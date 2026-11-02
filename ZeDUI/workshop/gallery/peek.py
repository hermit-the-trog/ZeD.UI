"""Look closely at part of a picture, with its own coordinates written on it.

    py peek.py <image> <x0> <y0> <x1> <y1> <out.png> [--w 1100] [--grid 50]

Crops the box from the image (a 4K capture, or a rendered spread), scales it to about --w pixels wide, and draws a
grid every --grid source pixels with the source coordinates at the edges. Read crop boxes and arrow points off it,
in the source picture's own pixels."""
import argparse

from PIL import Image, ImageDraw, ImageFont

ap = argparse.ArgumentParser()
ap.add_argument("image")
ap.add_argument("x0", type=int); ap.add_argument("y0", type=int)
ap.add_argument("x1", type=int); ap.add_argument("y1", type=int)
ap.add_argument("out")
ap.add_argument("--w", type=int, default=1100)
ap.add_argument("--grid", type=int, default=50)
a = ap.parse_args()
im = Image.open(a.image).convert("RGB").crop((a.x0, a.y0, a.x1, a.y1))
s = a.w / im.width
im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS if s < 1 else Image.NEAREST)
pad = 34
out = Image.new("RGB", (im.width + pad, im.height + pad), (255, 255, 255))
out.paste(im, (pad, pad))
d = ImageDraw.Draw(out)
f = ImageFont.load_default()
g0x = (a.x0 + a.grid - 1) // a.grid * a.grid
for X in range(g0x, a.x1 + 1, a.grid):
    x = pad + (X - a.x0) * s
    major = X % (a.grid * 2) == 0
    d.line((x, pad, x, out.height), fill=(255, 0, 255) if major else (0, 200, 255), width=1)
    if major: d.text((x + 2, 2), str(X), fill=(0, 0, 0), font=f)
g0y = (a.y0 + a.grid - 1) // a.grid * a.grid
for Y in range(g0y, a.y1 + 1, a.grid):
    y = pad + (Y - a.y0) * s
    major = Y % (a.grid * 2) == 0
    d.line((pad, y, out.width, y), fill=(255, 0, 255) if major else (0, 200, 255), width=1)
    if major: d.text((2, y + 2), str(Y), fill=(0, 0, 0), font=f)
out.save(a.out)
print("wrote", a.out, "scale %.3f" % s)
