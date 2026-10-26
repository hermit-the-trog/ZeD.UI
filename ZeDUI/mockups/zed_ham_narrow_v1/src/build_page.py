"""builds ../../zed_ham_narrow_v1.html: the narrow ham sets for small screens (pictures inside the page, so the Browser
pane's snapshot of a local file shows them). Run sheet.py and the tab composite first."""
import base64
import io
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import d_ham_narrow as HN    # noqa: E402
import physlib               # noqa: E402
import preview as PV         # noqa: E402
import d_walkie as DW        # noqa: E402

MOCK = os.path.normpath(os.path.join(HERE, ".."))
PAGE = os.path.normpath(os.path.join(HERE, "..", "..", "zed_ham_narrow_v1.html"))
WIDE_FN = {"ham_civilian": DW.ham_civ, "ham_army": DW.ham_army, "ham_makeshift": DW.ham_make}
NAMES = {"ham_civilian_n": "Premium Technologies Ham Radio", "ham_army_n": "US ARMY COMM. Ham Radio", "ham_makeshift_n": "Makeshift Ham Radio"}


def b64(im, fmt="PNG", **kw):
    buf = io.BytesIO(); im.save(buf, fmt, **kw)
    return f"data:image/{fmt.lower()};base64," + base64.b64encode(buf.getvalue()).decode()


def face(fn, kind, kw):
    p, base, spr = physlib.build(fn, [])
    return PV.render_state(base, p.parts, spr, DW.state(kind, True, **kw))


cards = []
for pid, (fn, kind, kw) in HN.MODELS.items():
    narrow = face(fn, kind, kw)
    wide = face(WIDE_FN[HN.WIDE[pid]], kind, kw)
    cards.append(f'''<section class="set"><h2>{NAMES[pid]}</h2>
<div class="sw"><button class="on" data-v="n">Narrow, 200</button><button data-v="w">Wide, 400</button></div>
<div class="stage"><img class="n" src="{b64(narrow)}" width="{narrow.width * 2}" height="{narrow.height * 2}" alt="narrow">
<img class="w" src="{b64(wide)}" width="{wide.width * 2}" height="{wide.height * 2}" alt="wide" hidden></div></section>''')

comp = Image.open(os.path.join(MOCK, "narrow_ham_in_tab_4k.png")).convert("RGB")
comp_src = b64(comp, "JPEG", quality=88)

html = f'''<!doctype html><html><head><meta charset="utf-8"><title>Narrow ham sets</title>
<style>
body{{margin:0;background:#1a1a1e;color:#d4d4d8;font:14px 'Fira Sans',sans-serif}}
header{{padding:12px 16px;border-bottom:1px solid rgba(255,255,255,.2);font:600 15px 'Fira Mono',monospace}}
header small{{display:block;font:400 13px 'Fira Sans',sans-serif;color:rgba(255,255,255,.6);margin-top:4px;max-width:1100px}}
main{{display:flex;gap:16px;padding:16px;flex-wrap:wrap;align-items:flex-start}}
section{{border:1px solid rgba(255,255,255,.2);background:#222226}}
h2{{margin:0;padding:8px 12px;font:600 14px 'Fira Mono',monospace;color:#d4a04a;border-bottom:1px solid rgba(255,255,255,.1)}}
.stage{{padding:14px;display:flex;justify-content:center;min-height:620px;align-items:flex-start}}
.stage img,.tab img{{image-rendering:pixelated;max-width:100%;height:auto}}
.sw{{display:flex;gap:0;padding:8px 12px 0}}
.sw button{{font:600 12px 'Fira Mono',monospace;background:#2c2c31;color:#d4d4d8;border:1px solid rgba(255,255,255,.25);padding:4px 10px;cursor:pointer}}
.sw button.on{{background:#d4a04a;color:#111;border-color:#d4a04a}}
.tab{{max-width:100%}}
.tab img{{display:block;width:883px}}
.notes{{max-width:520px}}
.notes ul{{margin:8px 0;padding:0 12px 0 28px;line-height:1.5}}
.notes p{{margin:8px 12px;line-height:1.5;color:rgba(255,255,255,.8)}}
</style></head><body>
<header>ZeD-UI | radio tab | two-way radios | narrow ham sets | mockup v1
<small>The three ham sets rearranged into a walkie's width (200 wide, in the same 220 panel), for screens where the
400-wide set cannot fit the radio tab at the plates' size. Every control of the wide set is on it, in the same order
for the controller. Faces at 2x.</small></header>
<main>
<section class="tab"><h2>In the World window's radio tab | 4K, 2x, the tab as narrow as a walkie's</h2>
<img src="{comp_src}" alt="the narrow ham in the tab"></section>
<section class="notes"><h2>When it is used</h2>
<p>The wide set is used whenever it fits. The narrow one only where the tab cannot hold 400 at the plates' size
with the inventory open beside it:</p>
<ul><li>1280 and 1366 wide screens at UI scale 1.0 and up (on 1280, also its own scale with Large text)</li>
<li>1600 x 900 at UI scale 1.5 and up (1.25 with Large text)</li>
<li>1920 x 1080 at UI scale 1.5 to 2.0</li>
<li>2560 wide at UI scale 1.75 to 2.0 (1.5 with Large text)</li></ul>
<p>At your 4K setup (UI scale 1.75) the wide set always fits.</p>
<p>The narrow set fits wherever a walkie fits. Only screens 1600 px wide or less at UI scale 1.5 fit neither: there
both draw one size step smaller.</p>
<p>The tab narrows with it, as it does for a walkie, and the radio's name shows in the header only when it fits
whole. Full view keeps the wide set: it stands on its own over the world.</p></section>
{"".join(cards)}
</main>
<script>
document.querySelectorAll('.set').forEach(function (s) {{
  s.querySelectorAll('.sw button').forEach(function (b) {{
    b.addEventListener('click', function () {{
      s.querySelectorAll('.sw button').forEach(function (x) {{ x.classList.toggle('on', x === b); }});
      s.querySelector('img.n').hidden = b.dataset.v !== 'n';
      s.querySelector('img.w').hidden = b.dataset.v !== 'w';
    }});
  }});
}});
</script>
</body></html>
'''
with open(PAGE, "w", encoding="utf-8", newline="\n") as f: f.write(html)
print(PAGE, os.path.getsize(PAGE), "bytes")
