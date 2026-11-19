"""make_beta_report.py - the director's visual report before a beta's final release test (Nov 19 2026).

The director: "When you have a beta ready for full release test ... a full visual report of all of the changes, full
screenshots, so I can zoom in ... a visual mock-up of the new description and the new gallery ... and a report on what
you will be testing ... what you removed from tests and what you have added." And: "Whenever we make a change, just take
a screenshot of it ... when a release is ready ... create a gallery of images with those visual changes."

Reads a report spec (JSON: version, changes with their shots and words, tests added / changed / removed, gallery notes),
the shots folder (QA's full-screen PNGs, Zomboid/Screenshots/<version>_report/) and the Workshop description bbcode;
writes <out>/index.html and <out>/shots/<name>.jpg (full 4K, JPEG 88, each well under the artifact's 15 MB a file), ready
to publish as one artifact with its shots as files.

Run from the repo root:  python ZeDUI/tools/release/make_beta_report.py <spec.json> <out folder>
"""
import html
import json
import os
import re
import sys

from PIL import Image


def bb_to_html(bb):
    """Steam's BBCode, the parts the description uses, as HTML in Steam's classes' look."""
    s = html.escape(bb.replace('\r\n', '\n'))
    s = re.sub(r'\[h1\](.*?)\[/h1\]', r'<div class="bb-h1">\1</div>', s, flags=re.S)
    s = re.sub(r'\[h2\](.*?)\[/h2\]', r'<div class="bb-h2">\1</div>', s, flags=re.S)
    s = re.sub(r'\[h3\](.*?)\[/h3\]', r'<div class="bb-h3">\1</div>', s, flags=re.S)
    s = re.sub(r'\[b\](.*?)\[/b\]', r'<b>\1</b>', s, flags=re.S)
    s = re.sub(r'\[i\](.*?)\[/i\]', r'<i>\1</i>', s, flags=re.S)
    s = re.sub(r'\[url=(.*?)\](.*?)\[/url\]', r'<a href="\1" rel="noopener" target="_blank">\2</a>', s, flags=re.S)
    s = re.sub(r'\[img\](.*?)\[/img\]', r'<img src="\1" alt="" loading="lazy">', s)
    s = re.sub(r'\[list\]\s*', '<ul>', s)
    s = re.sub(r'\s*\[/list\]', '</ul>', s)
    s = re.sub(r'\[\*\](.*?)(?=\n|<\/ul>)', r'<li>\1</li>', s)
    s = s.replace('\n', '<br>')
    s = re.sub(r'(<br>)*(<ul>|</ul>|<div class="bb-h[123]">)', r'\2', s)
    s = re.sub(r'(</div>|</ul>|<li>.*?</li>)<br>', r'\1', s)
    return s


def shot_jpg(src, dst):
    im = Image.open(src).convert('RGB')
    im.save(dst, 'JPEG', quality=88, optimize=True, progressive=True)
    return im.size


CSS = r"""
:root{--bg:#141518;--panel:#1d1f23;--panel2:#26292e;--line:#3a3d44;--fg:#e4e2dc;--dim:#9a9890;--acc:#3fb6a8;--warn:#e0a83a;--bad:#e05a4f;--good:#5fbf73;
--steam:#1b2838;--steam2:#16202d;--steamfg:#acb2b8;--steamh:#66c0f4;
--mono:"Fira Mono",ui-monospace,monospace;--sans:"Fira Sans","Segoe UI",system-ui,sans-serif;color-scheme:dark}
@media (prefers-color-scheme: light){:root:not([data-theme="dark"]){--bg:#f1efe9;--panel:#ffffff;--panel2:#ebe8e0;--line:#cfcbc0;--fg:#1d1e20;--dim:#5f5d57;--acc:#1f7f74;color-scheme:light}}
:root[data-theme="light"]{--bg:#f1efe9;--panel:#ffffff;--panel2:#ebe8e0;--line:#cfcbc0;--fg:#1d1e20;--dim:#5f5d57;--acc:#1f7f74;color-scheme:light}
body{background:var(--bg);color:var(--fg);font:15px/1.55 var(--sans);padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
.wrap{max-width:1240px;margin:0 auto;padding-block:28px 80px}
header h1{font:600 30px/1.2 var(--mono);margin:0 0 6px;text-wrap:balance}
header p{color:var(--dim);margin:0;max-width:70ch}
nav{display:flex;flex-wrap:wrap;gap:8px;margin:18px 0 6px}
nav a{font:13px var(--mono);color:var(--fg);text-decoration:none;border:1px solid var(--line);padding:5px 10px;border-radius:3px;background:var(--panel)}
nav a:hover,nav a:focus-visible{border-color:var(--acc);outline:none}
h2{font:600 20px/1.3 var(--mono);margin:46px 0 4px;letter-spacing:.02em}
h2+p.lead{color:var(--dim);margin:0 0 16px;max-width:75ch}
.group{margin:28px 0 8px;font:600 13px var(--mono);text-transform:uppercase;letter-spacing:.08em;color:var(--acc)}
figure{margin:0 0 30px;background:var(--panel);border:1px solid var(--line);border-radius:4px;overflow:hidden}
figure a{display:block;line-height:0}
figure img{width:100%;height:auto;display:block}
figcaption{padding:12px 14px;display:grid;gap:4px}
figcaption b{font:600 15px var(--mono)}
figcaption span{color:var(--dim);max-width:90ch}
figcaption .look{color:var(--fg)}
.missing{padding:40px 16px;text-align:center;color:var(--dim);font:13px var(--mono);border-bottom:1px dashed var(--line)}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:12px}
@media (max-width:760px){.pair{grid-template-columns:1fr}}
.steam{background:var(--steam);color:var(--steamfg);border-radius:4px;padding:22px clamp(14px,4vw,40px);max-width:700px;font:14px/1.6 Arial,Helvetica,sans-serif}
.steam img{max-width:100%;height:auto;display:block;margin:8px 0}
.steam .bb-h1{color:var(--steamh);font-size:22px;margin:4px 0 8px}
.steam .bb-h2{color:var(--steamh);font-size:18px;margin:18px 0 6px}
.steam .bb-h3{color:var(--steamh);font-size:16px;margin:14px 0 4px}
.steam ul{margin:4px 0 10px;padding-left:22px}
.steam a{color:var(--steamh)}
.steam .lbl{font:12px var(--mono);color:#8f98a0;text-transform:uppercase;letter-spacing:.08em;margin-bottom:10px}
.note{background:var(--panel);border:1px solid var(--line);border-left:3px solid var(--warn);padding:10px 14px;border-radius:3px;margin:10px 0;max-width:90ch}
.tablewrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;min-width:620px;font-size:14px}
th,td{border-bottom:1px solid var(--line);padding:8px 10px;text-align:left;vertical-align:top}
th{font:600 12px var(--mono);text-transform:uppercase;letter-spacing:.06em;color:var(--dim)}
td.n{font-variant-numeric:tabular-nums;white-space:nowrap}
.tag{font:600 11px var(--mono);padding:2px 6px;border-radius:3px;white-space:nowrap}
.tag.add{background:color-mix(in srgb,var(--good) 22%,transparent);color:var(--good)}
.tag.chg{background:color-mix(in srgb,var(--warn) 22%,transparent);color:var(--warn)}
.tag.del{background:color-mix(in srgb,var(--bad) 22%,transparent);color:var(--bad)}
pre.change{white-space:pre-wrap;background:var(--panel);border:1px solid var(--line);padding:14px;border-radius:4px;font:13px/1.55 var(--mono);max-width:100ch}
"""


def main():
    spec = json.load(open(sys.argv[1], encoding='utf-8'))
    out = sys.argv[2]
    os.makedirs(os.path.join(out, 'shots'), exist_ok=True)
    shots_dir = os.path.expanduser(spec['shots'])
    files = {}
    parts = []
    esc = html.escape
    v = spec['version']
    parts.append('<title>ZeD-GUI %s Review</title>\n<meta name="claude:viewport-fit-sides" content="cover">' % esc(v.split('-')[-1].capitalize()))
    parts.append('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fira+Mono:wght@400;600&family=Fira+Sans:wght@400;600&display=swap">')
    parts.append('<style>%s</style>' % CSS)
    parts.append('<div class="wrap"><header><h1>ZeD-GUI %s</h1><p>%s</p></header>' % (esc(v), esc(spec['intro'])))
    parts.append('<nav><a href="#changes">The changes</a><a href="#description">Workshop description</a><a href="#gallery">Gallery</a><a href="#tests">The release test</a><a href="#note">Change note</a></nav>')
    parts.append('<h2 id="changes">The changes, full screen</h2><p class="lead">Every picture is the whole 4K screen. Tap one to open it full size and zoom in.</p>')
    for g in spec['changes']:
        parts.append('<div class="group">%s</div>' % esc(g['group']))
        for it in g['items']:
            shots = it['shots'] if isinstance(it['shots'], list) else [it['shots']]
            figs = []
            for name in shots:
                src = os.path.join(shots_dir, name + '.png')
                if os.path.exists(src):
                    dst = os.path.join(out, 'shots', name + '.jpg')
                    shot_jpg(src, dst)
                    files['shots/%s.jpg' % name] = dst
                    figs.append('<a href="shots/%s.jpg" target="_blank" rel="noopener"><img src="shots/%s.jpg" alt="%s" loading="lazy"></a>' % (name, name, esc(it['title'])))
                else:
                    figs.append('<div class="missing">%s.png not taken yet</div>' % esc(name))
            body = ''.join(figs) if len(figs) == 1 else '<div class="pair">%s</div>' % ''.join('<div>%s</div>' % f for f in figs)
            parts.append('<figure>%s<figcaption><b>%s</b><span class="look">%s</span><span>%s</span></figcaption></figure>' % (
                body, esc(it['title']), esc(it.get('look', '')), esc(it.get('what', ''))))
    # the description, as Steam will show it
    bb = open(spec['description'], encoding='utf-8').read()
    # (the artifact may load pictures only from its own files: the description's GitHub pictures go in beside it)
    os.makedirs(os.path.join(out, 'desc'), exist_ok=True)
    for url in re.findall(r'\[img\](https://raw\.githubusercontent\.com/[^\[]*/description_img/([^\[/]+))\[/img\]', bb):
        local = os.path.join('ZeDUI', 'workshop', 'description_img', url[1])
        if os.path.exists(local):
            files['desc/' + url[1]] = local
            bb = bb.replace(url[0], 'desc/' + url[1])
    parts.append('<h2 id="description">Workshop description</h2><p class="lead">The page as Steam draws it: Steam colors, its widths, the pictures from GitHub.</p>')
    for n in spec.get('description_notes', []):
        parts.append('<div class="note">%s</div>' % esc(n))
    parts.append('<div class="steam"><div class="lbl">Description</div>%s</div>' % bb_to_html(bb))
    parts.append('<h2 id="gallery">Gallery</h2>')
    for n in spec.get('gallery_notes', []):
        parts.append('<div class="note">%s</div>' % esc(n))
    # the tests
    parts.append('<h2 id="tests">The release test</h2><p class="lead">%s</p>' % esc(spec.get('tests_lead', '')))
    parts.append('<div class="tablewrap"><table><thead><tr><th></th><th>Script</th><th>What it checks</th><th>Checks</th></tr></thead><tbody>')
    for t in spec['tests']:
        cls = {'added': 'add', 'changed': 'chg', 'removed': 'del'}[t['kind']]
        parts.append('<tr><td><span class="tag %s">%s</span></td><td><code>%s</code></td><td>%s</td><td class="n">%s</td></tr>' % (
            cls, esc(t['kind']), esc(t['script']), esc(t['what']), esc(str(t.get('checks', '')))))
    parts.append('</tbody></table></div>')
    for n in spec.get('tests_notes', []):
        parts.append('<div class="note">%s</div>' % esc(n))
    note = open(spec['changenote'], encoding='utf-8').read()
    parts.append('<h2 id="note">Change note</h2><pre class="change">%s</pre>' % esc(note))
    parts.append('</div>')
    p = os.path.join(out, 'index.html')
    open(p, 'w', encoding='utf-8').write('\n'.join(parts))
    json.dump(files, open(os.path.join(out, 'files.json'), 'w'), indent=1)
    print(p, len(files), 'shots')


if __name__ == '__main__':
    main()
