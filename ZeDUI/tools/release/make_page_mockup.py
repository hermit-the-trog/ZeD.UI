"""ZeDUI/tools/release/make_page_mockup.py  (Oct 22 2026)

Builds ZeDUI/mockups/zed_workshop_page_v3.html: the Workshop item page as a subscriber
will see it, in an approximation of Steam's frame, with the real gallery (shots.json and
shots/out), the real preview (workshop/thumbnail/preview.png) and the description three
ways: with pictures (workshop_description_layout.bbcode, from make_desc.py), as text only
(workshop_description_draft.bbcode) and the tester build's (tester_description_*.bbcode).

    py -I ZeDUI/tools/release/make_page_mockup.py            the repo page, pictures by path
    py -I ZeDUI/tools/release/make_page_mockup.py --embed X  one file X with every picture in it
                                                             (to send or open anywhere)
"""
import argparse
import base64
import glob
import html
import io
import json
import os

from PIL import Image

STEAM_DESC_MAX = 8000
# a typical hosted address, to estimate the description's length once IMG_BASE is replaced
SAMPLE_BASE = "https://raw.githubusercontent.com/hermit-the-trog/ZeD.UI/main/ZeDUI/workshop/desc"


def read(p):
    return open(p, encoding="utf-8").read().replace("\r\n", "\n")


def embed(path, max_w=None, q=84):
    im = Image.open(path)
    fmt = "PNG" if path.lower().endswith(".png") else "JPEG"
    if max_w and im.width > max_w:
        im = im.resize((max_w, round(max_w * im.height / im.width)), Image.LANCZOS)
    b = io.BytesIO()
    if fmt == "JPEG":
        im.convert("RGB").save(b, "JPEG", quality=q, optimize=True, progressive=True)
    else:
        im.save(b, "PNG", optimize=True)
    return "data:image/%s;base64,%s" % (fmt.lower(), base64.b64encode(b.getvalue()).decode())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--embed", default=None)
    a = ap.parse_args()
    ws = os.path.join(a.root, "ZeDUI", "workshop")
    shots = json.load(open(os.path.join(ws, "shots", "shots.json"), encoding="utf-8"))["shots"]
    tester = sorted(glob.glob(os.path.join(ws, "tester_description_*.bbcode")))[-1]
    notes = sorted(glob.glob(os.path.join(ws, "tester_changenote_*.txt")))[-1]
    data = {
        "layout": read(os.path.join(ws, "workshop_description_layout.bbcode")),
        "text": read(os.path.join(ws, "workshop_description_draft.bbcode")),
        "tester": read(tester),
        "testerName": os.path.basename(tester),
        "note": read(notes).strip(),
        "noteName": os.path.basename(notes)[len("tester_changenote_"):-4],
        "sampleBase": SAMPLE_BASE,
        "max": STEAM_DESC_MAX,
    }
    # the gallery, in shots.json's order; the file names are make_shots.py's (NN_id.jpg)
    gal = []
    for i, s in enumerate(shots):
        f = "%02d_%s.jpg" % (i + 1, s["id"])
        p = os.path.join(ws, "shots", "out", f)
        gal.append({"t": s.get("title") or s["id"].replace("_", " ").capitalize(), "c": s.get("caption") or "",
                    "src": embed(p, 1280, 82) if a.embed else "../workshop/shots/out/" + f})
    data["gallery"] = gal
    pv = os.path.join(ws, "thumbnail", "preview.png")
    data["preview"] = embed(pv) if a.embed else "../workshop/thumbnail/preview.png"
    # the description's pictures: by path, or embedded (the full cards behind the links too)
    imgs = {}
    for p in sorted(glob.glob(os.path.join(ws, "desc", "*"))):
        n = os.path.basename(p)
        imgs[n] = embed(p) if a.embed else "../workshop/desc/" + n
    for i, s in enumerate(shots):
        f = "%02d_%s.jpg" % (i + 1, s["id"])
        imgs["full/" + f] = gal[i]["src"]
    data["imgs"] = imgs

    page = TEMPLATE.replace("/*DATA*/", "const D = " + json.dumps(data) + ";")
    out = a.embed or os.path.join(a.root, "ZeDUI", "mockups", "zed_workshop_page_v3.html")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    print("wrote", out, "%.1f MB" % (os.path.getsize(out) / 1e6))


TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ZeD-GUI Workshop Page</title>
<link href="https://fonts.googleapis.com/css2?family=Fira+Mono:wght@400;700&family=Fira+Sans:wght@400;600&family=Fira+Sans+Condensed:wght@600&display=swap" rel="stylesheet">
<style>
/* ============================================================================
   ZeD-GUI: the Steam Workshop item page, laid out (Oct 22 2026, v3). Built by
   ZeDUI/tools/release/make_page_mockup.py from the real files: the gallery
   (shots.json + shots/out), the preview, and the description with pictures
   (make_desc.py) next to the text-only draft and the tester build's. Steam's
   frame is approximate: close enough to judge the layout, not pixel-exact.
   ============================================================================ */
:root { --mono:'Fira Mono',monospace; --sans:'Fira Sans',sans-serif; --cond:'Fira Sans Condensed',sans-serif;
  --steam-bg:#1b2838; --steam-panel:#16202d; --steam-deep:#0e141b; --steam-text:#acb2b8; --steam-hi:#ffffff; --steam-link:#66c0f4;
  --page:#0b0a08; --ink:#d8d8d8; --dim:#b9b4a6; --head:#f0ece0; --gold:#efe6c4; }
* { margin:0; padding:0; box-sizing:border-box; }
html, body { background:var(--page); }
body { color:var(--ink); font-family:var(--sans); padding:22px 16px 70px; }
.wrap { max-width:1060px; margin:0 auto; }
.banner { font-family:var(--mono); font-size:11px; letter-spacing:2px; color:#cfc6a8; text-transform:uppercase; }
h1.t { font-family:var(--cond); font-weight:600; font-size:24px; color:var(--head); margin:4px 0 6px; }
.lede { font-size:13px; line-height:1.55; color:var(--dim); max-width:1060px; }
.lede b { color:var(--gold); font-weight:600; }
.switch { display:flex; gap:6px; flex-wrap:wrap; margin:14px 0 0; }
.switch button { font:12px var(--mono); letter-spacing:.5px; color:#d8d4c8; background:#1c1b18; border:1px solid #3a3832; padding:5px 10px; cursor:pointer; }
.switch button.on { background:#d4922a; color:#111; border-color:#d4922a; }

.steam { margin-top:14px; background:var(--steam-bg); color:var(--steam-text); font-family:Arial, Helvetica, sans-serif; font-size:13px; border:1px solid #2a3f5a; }
.crumbs { padding:10px 16px; font-size:12px; color:#8f98a0; background:var(--steam-deep); }
.title { padding:14px 16px 6px; font-size:26px; color:var(--steam-hi); font-weight:300; }
.cols { display:flex; gap:16px; padding:8px 16px 16px; flex-wrap:wrap; }
.left { width:636px; max-width:100%; }
.right { width:372px; max-width:100%; }
.viewer { width:100%; aspect-ratio:16/9; background:#000; position:relative; overflow:hidden; cursor:zoom-in; }
.viewer img { width:100%; height:100%; object-fit:contain; display:block; }
.cap { margin-top:6px; font-size:12.5px; color:#c6d4df; min-height:34px; line-height:1.4; }
.cap b { color:#fff; font-weight:600; }
.strip { display:flex; gap:6px; margin-top:6px; overflow-x:auto; padding-bottom:6px; }
.th { flex:none; width:116px; height:65px; background:#000; border:2px solid transparent; cursor:pointer; position:relative; }
.th.on { border-color:#fff; }
.th img { width:100%; height:100%; object-fit:cover; display:block; }
.th .n { position:absolute; top:2px; left:4px; font:700 11px var(--mono); color:#fff; text-shadow:0 0 3px #000; }
.count1 { font:11px var(--mono); color:#8f98a0; }

.prev { display:flex; gap:12px; align-items:flex-start; }
.prev img { width:128px; height:128px; image-rendering:pixelated; border:1px solid #000; flex:none; }
.sub { flex:1; }
.subbtn { display:block; width:100%; text-align:center; padding:10px; background:linear-gradient(to right, #75b022, #588a1b); color:#d2efa9; font-size:15px; border-radius:2px; margin-bottom:8px; }
.meta { background:var(--steam-panel); padding:10px 12px; margin-top:12px; font-size:12px; line-height:1.9; }
.meta .k { color:#8f98a0; display:inline-block; width:100px; }
.meta .v { color:#c6d4df; }
.side { background:var(--steam-panel); padding:10px 12px; margin-top:10px; font-size:12px; }
.side h4 { color:#fff; font-weight:400; font-size:13px; margin-bottom:6px; }
.side li { list-style:none; color:var(--steam-link); padding:2px 0; }
.small { font-size:12px; color:#8f98a0; line-height:1.5; }

.tabs { display:flex; gap:2px; padding:0 16px; border-bottom:1px solid #2a3f5a; flex-wrap:wrap; }
.tabs button { background:transparent; border:0; color:#8f98a0; font:13px Arial; padding:9px 14px; cursor:pointer; border-bottom:2px solid transparent; }
.tabs button.on { color:#fff; border-bottom-color:var(--steam-link); }
.pane { padding:16px 16px 24px; display:none; line-height:1.55; }
.pane.on { display:block; }
/* the description, as Steam draws its codes (approximate), in Steam's column */
.desc { width:636px; max-width:100%; color:#acb2b8; font-size:14px; }
.desc .h1 { font-size:22px; color:#5aa9d6; margin:8px 0 6px; font-weight:400; }
.desc .h2 { font-size:17px; color:#5aa9d6; margin:16px 0 6px; font-weight:400; }
.desc b { color:#c6d4df; }
.desc ul, .desc ol { margin:4px 0 8px 22px; }
.desc li { margin:2px 0; }
.desc pre { background:#0e141b; border:1px solid #2a3f5a; padding:8px 10px; color:#c6d4df; font:12.5px var(--mono); margin:6px 0; white-space:pre-wrap; }
.desc img { max-width:100%; display:block; }
.desc a img { cursor:zoom-in; }
.desc .rt { color:var(--steam-link); text-decoration:underline; }
.count { font:11px var(--mono); color:#8f98a0; margin-top:12px; line-height:1.6; }
.count .over { color:#e0703a; }
.post { background:#0e141b; border:1px solid #2a3f5a; padding:12px 14px; max-width:636px; color:#c6d4df; font-size:13px; }
.post h5 { color:#fff; font-size:14px; font-weight:400; margin-bottom:6px; }

.notes { margin-top:26px; }
h2.sec { font-family:var(--cond); font-weight:600; font-size:18px; color:var(--head); margin:0 0 6px; }
.notes li { font-size:13px; line-height:1.6; color:#c4bfb1; margin-bottom:6px; }
.notes ol { padding-left:20px; } .notes b { color:var(--gold); font-weight:600; }
.notes code { font:12px var(--mono); color:#e0d6b6; }

.lb { position:fixed; inset:0; background:rgba(0,0,0,.88); display:none; align-items:center; justify-content:center; padding:20px; z-index:9; cursor:zoom-out; }
.lb.on { display:flex; }
.lb img { max-width:100%; max-height:100%; }
@media (max-width: 700px) { body { padding:16px 16px 50px; } .title { font-size:20px; } }
</style>
</head>
<body>
<div class="wrap">
<div class="banner">ZeD-GUI | Steam Workshop | the item page, laid out | v3</div>
<h1 class="t">Workshop page, with the real gallery</h1>
<p class="lede">The page as a subscriber will see it, in an approximation of Steam's frame. <b>Gallery:</b> the cards Code built, in the
order of shots.json (v4: the Fossoil story). <b>Description:</b> the current text with a title plate, a plate for each section and eight of the cards placed where the
text describes them (Steam shows description pictures at most 636 px wide; they are made at twice that). Switch below to the text-only draft or
the tester build's text. Click any picture to see it full size.</p>
<div class="switch" id="sw">
  <button data-v="layout" class="on">With pictures</button>
  <button data-v="text">Text only</button>
  <button data-v="tester">Tester build</button>
</div>

<div class="steam">
  <div class="crumbs">Project Zomboid &gt; Workshop &gt; Hermit's Workshop</div>
  <div class="title" id="ttl">ZeD-GUI [B42]</div>
  <div class="cols">
    <div class="left">
      <div class="viewer" id="viewer"><img id="vimg" alt=""></div>
      <div class="cap" id="cap"></div>
      <div class="strip" id="strip"></div>
      <div class="count1" id="gcount"></div>
    </div>
    <div class="right">
      <div class="prev">
        <img id="pv" alt="Preview">
        <div class="sub">
          <a class="subbtn">+ Subscribe</a>
          <div class="small">The 256 &times; 256 preview (ZNIX USER), shown at half size as in the browse grid.</div>
        </div>
      </div>
      <div class="meta">
        <div><span class="k">File size</span><span class="v">(after upload)</span></div>
        <div><span class="k">Posted</span><span class="v">(first upload)</span></div>
        <div><span class="k">Updated</span><span class="v">(each upload, with a change note)</span></div>
        <div><span class="k">Tags</span><span class="v" style="color:#66c0f4">Build 42 | Interface</span></div>
        <div><span class="k">Created by</span><span class="v">Hermit</span></div>
      </div>
      <div class="side">
        <h4>Required items</h4>
        <div class="small">None.</div>
      </div>
      <div class="side">
        <h4>Discussions</h4>
        <ul><li>Bug reports</li><li>Compatibility</li><li>Requests</li><li>Add-on makers</li><li>Translations</li></ul>
      </div>
    </div>
  </div>
  <div class="tabs" id="tabs">
    <button class="on" data-p="p_desc">Description</button>
    <button data-p="p_notes">Change Notes</button>
  </div>
  <div class="pane on" id="p_desc"><div class="desc" id="desc"></div><div class="count" id="count"></div></div>
  <div class="pane" id="p_notes"><div class="post" id="note"></div></div>
</div>

<section class="notes">
  <h2 class="sec">Before it goes up</h2>
  <ol>
    <li><b>Hosting.</b> Steam only shows description pictures from a public web address. Upload the files in <code>ZeDUI/workshop/desc/</code>
      (and the full cards they link to, under <code>full/</code>) and replace <code>IMG_BASE</code> in
      <code>workshop_description_layout.bbcode</code> with that address. The repo's raw files work if the repo is public; Steam artwork
      uploads work too, but each picture then has its own long address.</li>
    <li><b>Length.</b> Steam allows 8,000 characters. The count under the description estimates it with a typical address in place of
      <code>IMG_BASE</code>. The cards carry no links by default; <code>make_desc.py --links</code> adds a link to each full card if the
      addresses are short enough to afford them.</li>
    <li><b>Rebuild.</b> After the gallery or the text changes: <code>py -I ZeDUI/tools/release/make_desc.py</code>, then
      <code>py -I ZeDUI/tools/release/make_page_mockup.py</code>.</li>
  </ol>
</section>
</div>
<div class="lb" id="lb"><img id="lbimg" alt=""></div>

<script>
/*DATA*/
const esc = t => t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const lb = document.getElementById("lb"), lbimg = document.getElementById("lbimg");
function zoom(src) { lbimg.src = src; lb.classList.add("on"); }
lb.onclick = () => lb.classList.remove("on");
document.addEventListener("keydown", e => { if (e.key === "Escape") lb.classList.remove("on"); });

// the gallery
let cur = 0;
const strip = document.getElementById("strip");
D.gallery.forEach((g, i) => {
  const t = document.createElement("div");
  t.className = "th";
  t.innerHTML = `<img src="${g.src}" alt=""><span class="n">${i + 1}</span>`;
  t.onclick = () => { cur = i; show(); };
  strip.appendChild(t);
});
function show() {
  const g = D.gallery[cur];
  document.getElementById("vimg").src = g.src;
  document.getElementById("cap").innerHTML = `<b>${cur + 1}. ${esc(g.t)}.</b> ${esc(g.c)}`;
  document.querySelectorAll(".th").forEach((t, i) => t.classList.toggle("on", i === cur));
}
document.getElementById("viewer").onclick = () => zoom(D.gallery[cur].src);
document.getElementById("gcount").textContent = `${D.gallery.length} pictures (Steam's gallery shows them in this order)`;
document.getElementById("pv").src = D.preview;
show();

// the description, from Steam's codes (the subset the drafts use)
function bb(s) {
  let h = esc(s);
  const src = n => D.imgs[n] || "";
  h = h.replace(/\[code\]([\s\S]*?)\[\/code\]/g, (m, c) => `<pre>${c}</pre>`);
  h = h.replace(/\[url=IMG_BASE\/([^\]]+)\]\[img\]IMG_BASE\/([^\[]+)\[\/img\]\[\/url\]/g,
    (m, full, n) => `<a data-full="${full}"><img src="${src(n)}" alt=""></a>`);
  h = h.replace(/\[img\]IMG_BASE\/([^\[]+)\[\/img\]/g, (m, n) => `<img src="${src(n)}" alt="">`);
  h = h.replace(/\[h1\](.*?)\[\/h1\]/g, '<div class="h1">$1</div>').replace(/\[h2\](.*?)\[\/h2\]/g, '<div class="h2">$1</div>');
  h = h.replace(/\[b\](.*?)\[\/b\]/g, "<b>$1</b>").replace(/\[i\](.*?)\[\/i\]/g, "<i>$1</i>");
  h = h.replace(/\[list\]([\s\S]*?)\[\/list\]/g, (m, c) => "<ul>" + c.split("[*]").slice(1).map(x => `<li>${x.trim()}</li>`).join("") + "</ul>");
  h = h.replace(/\[olist\]([\s\S]*?)\[\/olist\]/g, (m, c) => "<ol>" + c.split("[*]").slice(1).map(x => `<li>${x.trim()}</li>`).join("") + "</ol>");
  h = h.replace(/(Bug reports|Requests|Add-on makers|Translations|compatibility)( discussion)/g, '<span class="rt">$1</span>$2');
  h = h.replace(/\n{2,}/g, "<br><br>").replace(/\n/g, "<br>");
  // (Steam keeps the line breaks round a picture; a heading, list or code block takes its own)
  h = h.replace(/<br>(<(?:div|ul|ol|pre))/g, "$1").replace(/(<\/(?:div|ul|ol|pre)>)<br>/g, "$1");
  return h;
}
function renderDesc(v) {
  const s = D[v];
  const el = document.getElementById("desc");
  el.innerHTML = bb(s);
  el.querySelectorAll("a[data-full]").forEach(a => a.onclick = () => zoom(D.imgs[a.dataset.full] || a.querySelector("img").src));
  el.querySelectorAll(":scope > img").forEach(i => i.onclick = () => zoom(i.src));
  const n = (s.match(/IMG_BASE/g) || []).length;
  const est = s.length + n * (D.sampleBase.length - "IMG_BASE".length);
  const c = document.getElementById("count");
  c.innerHTML = `${s.length.toLocaleString()} characters as written` +
    (n ? `; about <span class="${est > D.max ? "over" : ""}">${est.toLocaleString()}</span> with ${n} picture addresses filled in` : "") +
    ` (Steam allows ${D.max.toLocaleString()})`;
  document.getElementById("ttl").textContent = v === "tester" ? "ZeD-GUI [B42] | tester build " + D.noteName : "ZeD-GUI [B42]";
}
document.getElementById("note").innerHTML = `<h5>Update: ${esc(D.noteName)}</h5>${esc(D.note)}`;
document.querySelectorAll("#sw button").forEach(b => b.onclick = () => {
  document.querySelectorAll("#sw button").forEach(x => x.classList.toggle("on", x === b));
  renderDesc(b.dataset.v);
});
renderDesc("layout");
document.querySelectorAll("#tabs button").forEach(b => b.onclick = () => {
  document.querySelectorAll("#tabs button").forEach(x => x.classList.remove("on")); b.classList.add("on");
  document.querySelectorAll(".pane").forEach(p => p.classList.toggle("on", p.id === b.dataset.p));
});
</script>
</body>
</html>
"""

if __name__ == "__main__":
    main()
