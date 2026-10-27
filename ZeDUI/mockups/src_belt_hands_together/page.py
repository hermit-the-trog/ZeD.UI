"""Builds the hands-together mockup page: the panel pictures (PNG files) embedded as data URIs."""
import base64, sys, os
D = os.path.dirname(os.path.abspath(__file__))
def img(name, alt):
    b = base64.b64encode(open(os.path.join(D, name), "rb").read()).decode()
    return '<img class="belt" src="data:image/png;base64,%s" alt="%s">' % (b, alt)

PANELS = []
def panel(tag, title, desc, rows):
    PANELS.append((tag, title, desc, rows))

exec(open(os.path.join(D, "content.py"), encoding="utf-8").read())

css = open(os.path.join(D, "page.css"), encoding="utf-8").read()
out = ['<title>Belt hands together</title>',
       '<meta name="claude:viewport-fit-sides" content="cover">',
       '<link rel="preconnect" href="https://fonts.googleapis.com">',
       '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fira+Mono:wght@400;500&family=Fira+Sans:wght@400;500;600&family=Fira+Sans+Condensed:wght@500;600&display=swap">',
       '<style>' + css + '</style>', '<main>', HEAD]
for tag, title, desc, rows in PANELS:
    out.append('<section class="opt"><header><span class="tag %s">%s</span><h2>%s</h2></header><p>%s</p>' % (tag[0], tag[1], title, desc))
    for cap, file, alt in rows:
        out.append('<figure><div class="frame">%s</div><figcaption>%s</figcaption></figure>' % (img(file, alt), cap))
    out.append('</section>')
out.append(FOOT)
out.append('</main>')
open(sys.argv[1], "w", encoding="utf-8").write("\n".join(out))
