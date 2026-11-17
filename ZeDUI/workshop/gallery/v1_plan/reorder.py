"""Re-orders the gallery book from one order list (order_v1.json: the parts, each a list of spread ids in reading order).

    py reorder.py ORDER.json SPREADS_IN SPREADS_OUT      writes the re-numbered spreads into SPREADS_OUT (never in place)
    py reorder.py --check SPREADS                         only checks a folder's references

For each spread it sets the chapter number n, the pages (left 2n+20, right 2n+21), the chapter block, every figure and
table label, and every "Chapter N", "Figure N-M" and "Table N-M" in any printed or handwritten text, old number to new.
The file becomes NN_<id>.json. "seed" is never touched (spread.py seeds the paper and tape from it), so no page's look
changes. It also writes BREAKS.py (make_v1's BREAKS list: one scene per part, after it, or before it when the
order says "openers": true) and REORDER.md (old to new).
Then it checks: every chapter 1..N once, figure and table labels counted 1, 2, 3 within their chapter, every reference
pointing at a real chapter, figure or table, and it lists each reference to a LATER chapter (for the editor to read).
"""
import json, os, re, sys

REF = re.compile(r"\b(Chapter|Figure|Table) (\d+)(-\d+)?")


def strings(o, fn):
    if isinstance(o, str): return fn(o)
    if isinstance(o, list): return [strings(x, fn) for x in o]
    if isinstance(o, dict): return {k: (v if k in ("src", "id", "kind", "pen", "tape") else strings(v, fn)) for k, v in o.items()}
    return o


def load(folder):
    sps = {}
    for f in sorted(os.listdir(folder)):
        if f.endswith(".json") and f[0].isdigit():
            sp = json.load(open(os.path.join(folder, f), encoding="utf-8")); sps[sp["id"]] = sp
    return sps


def title(sp): return [b["chapter"][1] for b in sp["left"]["blocks"] if "chapter" in b][0]


def reorder(order_path, src, dst):
    order = json.load(open(order_path, encoding="utf-8"))
    sps = load(src)
    ids = [c for p in order["parts"] for c in p["chapters"]]
    if sorted(ids) != sorted(sps): sys.exit("order and spreads differ: %s" % sorted(set(ids) ^ set(sps)))
    new = {sps[i]["n"]: k for k, i in enumerate(ids, 1)}            # old chapter number -> new

    def fix(s):
        return REF.sub(lambda m: "%s %d%s" % (m.group(1), new[int(m.group(2))], m.group(3) or "") if int(m.group(2)) in new else m.group(0), s)
    os.makedirs(dst, exist_ok=True)
    if [f for f in os.listdir(dst) if f.endswith(".json")]: sys.exit("%s is not empty" % dst)
    rows = []
    for i in ids:
        sp = sps[i]; old = sp["n"]; n = new[old]
        sp.setdefault("seed", old)                                   # the look stays the one it was approved under
        sp = strings(sp, fix)
        sp["n"] = n; sp["pages"] = [2 * n + 20, 2 * n + 21]
        for b in sp["left"]["blocks"]:
            if "chapter" in b: b["chapter"][0] = str(n)
        json.dump(sp, open(os.path.join(dst, "%02d_%s.json" % (n, i)), "w", encoding="utf-8", newline="\n"), indent=1, ensure_ascii=False)
        rows.append((n, old, i, title(sp)))
    for f in os.listdir(src):                                        # _book.json and the like
        if f.endswith(".json") and not f[0].isdigit():
            open(os.path.join(dst, f), "w", encoding="utf-8").write(open(os.path.join(src, f), encoding="utf-8").read())
    out = os.path.dirname(os.path.abspath(dst))
    L = ["# The 1.0 order: old chapter to new", "", "| Part | New | Old | File | Title | Pages |", "|---|---|---|---|---|---|"]
    B = ["# make_v1.py's BREAKS, written by reorder.py from %s: one scene per part" % os.path.basename(order_path), "BREAKS = ["]
    if order.get("open_break"): B.append('    ("00b_break_open", "%s"),' % order["open_break"])
    k = 0
    op = order.get("openers")                                        # true: a part's break is its opener, shown before it
    for pn, p in enumerate(order["parts"], 1):
        if op and p.get("break"): B.append('    ("%02db_scene_part%d", "%s"),   # opens Part %d, %s' % (k, pn, p["break"], pn, p["title"]))
        for c in p["chapters"]:
            n, old, i, t = rows[k]; k += 1
            L.append("| %d %s | %d | %d | `%02d_%s` | %s | %d-%d |" % (pn, p["title"], n, old, n, i, t, 2 * n + 20, 2 * n + 21))
        if not op and p.get("break"): B.append('    ("%02db_break_part%d", "%s"),   # after Part %d, %s' % (n, pn, p["break"], pn, p["title"]))
    if order.get("close_break"): B.append('    ("%02db_break_close", "%s"),' % (len(ids), order["close_break"]))
    B.append("]")
    open(os.path.join(out, "REORDER.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")
    open(os.path.join(out, "BREAKS.py"), "w", encoding="utf-8").write("\n".join(B) + "\n")
    return check(dst)


def check(folder):
    sps = sorted(load(folder).values(), key=lambda s: s["n"])
    bad = []; labels = set(); fwd = []
    if [s["n"] for s in sps] != list(range(1, len(sps) + 1)): bad.append("chapter numbers are not 1..%d" % len(sps))
    for sp in sps:
        n = sp["n"]; cnt = {"Figure": 0, "Table": 0}
        if sp["pages"] != [2 * n + 20, 2 * n + 21]: bad.append("%s: pages %s" % (sp["id"], sp["pages"]))
        for side in ("left", "right"):
            for b in sp[side].get("blocks", []):
                lab = b["caption"][0] if "caption" in b else b["table"]["label"] if "table" in b else None
                if "chapter" in b and b["chapter"][0] != str(n): bad.append("%s: chapter block says %s" % (sp["id"], b["chapter"][0]))
                if lab:
                    kind = lab.split()[0]; cnt[kind] += 1; labels.add(lab)
                    if lab != "%s %d-%d" % (kind, n, cnt[kind]): bad.append("%s: label %s, expected %s %d-%d" % (sp["id"], lab, kind, n, cnt[kind]))
    for sp in sps:
        def see(s, sp=sp):
            for m in REF.finditer(s):
                what, c, sub = m.group(1), int(m.group(2)), m.group(3)
                if what == "Chapter":
                    if not 1 <= c <= len(sps): bad.append("%s: no %s" % (sp["id"], m.group(0)))
                    elif c > sp["n"]: fwd.append("%02d %s -> Chapter %d (%s): ...%s..." % (sp["n"], sp["id"], c, title(sps[c - 1]), s[max(0, m.start() - 60):m.end() + 30]))
                    elif c < sp["n"]: fwd.append("%02d %s <- Chapter %d (%s), back" % (sp["n"], sp["id"], c, title(sps[c - 1])))
                elif m.group(0) not in labels: bad.append("%s: no %s" % (sp["id"], m.group(0)))
                elif c != sp["n"]: fwd.append("%02d %s cites %s in another chapter" % (sp["n"], sp["id"], m.group(0)))
            return s
        strings(sp, see)
    print("%d chapters, %d figures and tables, %d broken" % (len(sps), len(labels), len(bad)))
    for b in bad: print("  BROKEN", b)
    print("references to other chapters (for the editor):")
    for f in fwd: print("  ", f)
    return len(bad)


if __name__ == "__main__":
    a = sys.argv[1:]
    sys.exit(1 if (check(a[1]) if a[0] == "--check" else reorder(*a)) else 0)
