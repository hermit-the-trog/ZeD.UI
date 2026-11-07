"""render.js without Node: sets every ad (or the ones named) at 2x in headless Microsoft Edge, driven over the DevTools
protocol with the standard library only. out/preview/<name>.png on the book's paper, out/final/<name>.png ink on
transparent, each cropped to #ad; prints each ad's size and OVERFLOW for anything inside #ad that pokes out of it.
python render_edge.py [--out DIR] [--edge PATH] [name ...]
Edge runs on a fresh profile in a temp folder, and only the Edge this script starts is closed (by its PID)."""
import argparse, base64, glob, json, os, shutil, socket, struct, subprocess, sys, tempfile, time, urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

OVERFLOW_JS = """[...document.querySelectorAll('#ad *')].filter(e => { const r = e.getBoundingClientRect(),
 a = document.getElementById('ad').getBoundingClientRect(); return r.width > 0 && (r.right > a.right + .5 ||
 r.bottom > a.bottom + .5 || r.left < a.left - .5); }).map(e => e.className.baseVal ?? e.className).slice(0, 5)"""
BOX_JS = """(() => { const r = document.getElementById('ad').getBoundingClientRect();
 return [r.left + scrollX, r.top + scrollY, r.width, r.height]; })()"""


class WS:
    """The least websocket client CDP needs: masked text frames out, fragments and pings handled in."""
    def __init__(self, url):
        hostport, path = url[len("ws://"):].split("/", 1)
        host, port = hostport.rsplit(":", 1)
        self.s = socket.create_connection((host, int(port)), timeout=60)
        key = base64.b64encode(os.urandom(16)).decode()
        self.s.sendall(("GET /%s HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                        "Sec-WebSocket-Key: %s\r\nSec-WebSocket-Version: 13\r\n\r\n" % (path, hostport, key)).encode())
        head = b""
        while b"\r\n\r\n" not in head:
            c = self.s.recv(4096)
            if not c: raise RuntimeError("websocket handshake closed")
            head += c
        head, self.buf = head.split(b"\r\n\r\n", 1)
        if b" 101 " not in head.split(b"\r\n", 1)[0]: raise RuntimeError("websocket handshake: " + head.decode(errors="replace"))

    def _take(self, n):
        while len(self.buf) < n:
            c = self.s.recv(1 << 20)
            if not c: raise RuntimeError("websocket closed")
            self.buf += c
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def _frame(self, op, data):
        n, mask = len(data), os.urandom(4)
        hdr = bytes([0x80 | op]) + (bytes([0x80 | n]) if n < 126 else
              bytes([0x80 | 126]) + struct.pack(">H", n) if n < 65536 else bytes([0x80 | 127]) + struct.pack(">Q", n))
        self.s.sendall(hdr + mask + bytes(b ^ mask[i & 3] for i, b in enumerate(data)))

    def send(self, text): self._frame(1, text.encode())

    def recv(self):
        msg = b""
        while True:
            b0, b1 = self._take(2)
            n = b1 & 0x7f
            if n == 126: n = struct.unpack(">H", self._take(2))[0]
            elif n == 127: n = struct.unpack(">Q", self._take(8))[0]
            mask = self._take(4) if b1 & 0x80 else None
            data = self._take(n)
            if mask: data = bytes(b ^ mask[i & 3] for i, b in enumerate(data))
            op = b0 & 0x0f
            if op == 9: self._frame(10, data); continue
            if op == 8: raise RuntimeError("websocket closed by Edge")
            if op in (0, 1, 2): msg += data
            if b0 & 0x80 and op != 10: return msg.decode()


class CDP:
    def __init__(self, url): self.ws, self.n = WS(url), 0

    def __call__(self, method, **params):
        self.n += 1
        self.ws.send(json.dumps({"id": self.n, "method": method, "params": params}))
        while True:
            m = json.loads(self.ws.recv())
            if m.get("id") == self.n:
                if "error" in m: raise RuntimeError("%s: %s" % (method, m["error"]))
                return m.get("result", {})

    def js(self, expr, wait=False):
        r = self("Runtime.evaluate", expression=expr, returnByValue=True, awaitPromise=wait)
        if "exceptionDetails" in r: raise RuntimeError("page script: %s" % r["exceptionDetails"])
        return r["result"].get("value")


def start_edge(edge, profile):
    proc = subprocess.Popen([edge, "--headless=new", "--remote-debugging-port=0", "--user-data-dir=" + profile,
                             "--no-first-run", "--no-default-browser-check", "--disable-extensions", "--hide-scrollbars",
                             "--mute-audio", "--force-color-profile=srgb", "--disable-background-timer-throttling",
                             "--disable-renderer-backgrounding", "--disable-features=msEdgeStartupBoost", "about:blank"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    port_file, t0 = os.path.join(profile, "DevToolsActivePort"), time.time()
    while time.time() - t0 < 30:
        if proc.poll() is not None: raise RuntimeError("Edge exited at start (code %s)" % proc.returncode)
        try:
            port = int(open(port_file).read().split()[0])
            for t in json.load(urllib.request.urlopen("http://127.0.0.1:%d/json/list" % port, timeout=5)):
                if t.get("type") == "page": return proc, t["webSocketDebuggerUrl"]
        except (OSError, ValueError, IndexError):
            pass
        time.sleep(0.2)
    raise RuntimeError("Edge's DevTools port never came up")


def stop_edge(proc, cdp):
    try:
        if cdp: cdp.ws._frame(1, json.dumps({"id": 999999, "method": "Browser.close"}).encode())
    except OSError:
        pass
    try:
        proc.wait(10)
    except subprocess.TimeoutExpired:
        # only the tree under the PID this script started
        subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        proc.wait(10)


def render(cdp, src, out, name):
    url = "file:///" + os.path.join(src, name + ".html").replace("\\", "/")
    for hsh, sub, omit in (("", "preview", False), ("#final", "final", True)):
        cdp("Page.navigate", url="about:blank")   # a hash-only change would not reload the page
        cdp("Page.navigate", url=url + hsh)
        t0 = time.time()
        want = json.dumps("/" + name + ".html" + hsh)
        while not cdp.js("document.readyState === 'complete' && decodeURI(location.href).endsWith(%s)" % want):
            if time.time() - t0 > 20: raise RuntimeError(name + ": page never finished loading")
            time.sleep(0.02)
        cdp.js("document.fonts.ready.then(() => document.fonts.size)", wait=True)
        time.sleep(0.08)
        if cdp.js("!document.getElementById('ad')"): raise RuntimeError(name + ": no #ad")
        x, y, w, h = cdp.js(BOX_JS)
        if omit: cdp("Emulation.setDefaultBackgroundColorOverride", color={"r": 0, "g": 0, "b": 0, "a": 0})
        else: cdp("Emulation.setDefaultBackgroundColorOverride")
        shot = cdp("Page.captureScreenshot", format="png", captureBeyondViewport=True,
                   clip={"x": x, "y": y, "width": w, "height": h, "scale": 1})
        with open(os.path.join(out, sub, name + ".png"), "wb") as f: f.write(base64.b64decode(shot["data"]))
        if not omit:
            of = cdp.js(OVERFLOW_JS)
            print(name, "%gx%g" % (w, h), "OVERFLOW " + ",".join(map(str, of)) if of else "", flush=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("names", nargs="*")
    ap.add_argument("--out", default=os.path.join(HERE, "out"), help="output folder (default out/ beside this script)")
    ap.add_argument("--edge", default=os.environ.get("ZED_EDGE", EDGE))
    a = ap.parse_args()
    src = os.path.join(HERE, "src")
    names = [n[:-5] if n.endswith(".html") else n for n in a.names] or \
            sorted(os.path.basename(f)[:-5] for f in glob.glob(os.path.join(src, "*.html")))
    for n in names:
        if not os.path.isfile(os.path.join(src, n + ".html")): sys.exit("no such ad: src/%s.html" % n)
    for sub in ("preview", "final"): os.makedirs(os.path.join(a.out, sub), exist_ok=True)
    profile = tempfile.mkdtemp(prefix="zed_adrender_")
    proc = cdp = None
    try:
        proc, wsurl = start_edge(a.edge, profile)
        cdp = CDP(wsurl)
        cdp("Page.enable")
        cdp("Emulation.setDeviceMetricsOverride", width=700, height=900, deviceScaleFactor=2, mobile=False)
        for n in names: render(cdp, src, a.out, n)
    finally:
        if proc: stop_edge(proc, cdp)
        shutil.rmtree(profile, ignore_errors=True)


if __name__ == "__main__":
    main()
