# a review sheet: the fulls in a row, the halves, thirds and quarters after (any of them)
import sys
from PIL import Image
names = sys.argv[2:]; out = sys.argv[1]
ims = [(n, Image.open('out/preview/%s.png' % n).convert('RGB')) for n in names]
cols = 3; pad = 20
rows = []; cur = []; w = 0
for n, im in ims:
    if cur and w + im.width + pad > 2700: rows.append(cur); cur = []; w = 0
    cur.append(im); w += im.width + pad
if cur: rows.append(cur)
W = max(sum(i.width + pad for i in r) for r in rows) + pad
H = sum(max(i.height for i in r) + pad for r in rows) + pad
S = Image.new('RGB', (W, H), (70, 70, 70)); y = pad
for r in rows:
    x = pad
    for i in r: S.paste(i, (x, y)); x += i.width + pad
    y += max(i.height for i in r) + pad
S = S.resize((S.width // 2, S.height // 2), Image.LANCZOS); S.save(out); print(S.size)
