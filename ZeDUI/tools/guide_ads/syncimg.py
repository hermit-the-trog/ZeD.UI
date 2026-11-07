# keep each ad's <img> the size of its picture
import re, glob
from PIL import Image
for f in glob.glob('src/*.html'):
    s = open(f).read()
    def fix(m):
        n = m.group(1); w, h = Image.open(f'px/{n}.png').size
        st = re.sub(r'width:\d+px;height:\d+px', f'width:{w}px;height:{h}px', m.group(2))
        return f'src="../px/{n}.png" style="{st}"'
    s2 = re.sub(r'src="\.\./px/(\w+)\.png" style="([^"]*)"', fix, s)
    if s2 != s: open(f, 'w').write(s2); print('sized', f)
