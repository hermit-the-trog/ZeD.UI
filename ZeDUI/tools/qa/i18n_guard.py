"""Translation guard. Plain Python 3, nothing to install. Runs outside the game.

  usage:  py i18n_guard.py            check, exit 1 on any failure
          py i18n_guard.py --list     also print every English literal found (allowed or not)
          py i18n_guard.py --seed     print allowlist lines for every new finding (review them first!)

What it checks
  1. Translate/EN/UI.json is valid JSON, flat, every value is a non-empty string, every key is
     UI_ZeD_ plus ASCII letters, digits and underscores.
  2. Every literal key the Lua asks for exists in UI.json: ZeD.tr("UI_ZeD_..."), getText("UI_ZeD_..."),
     getTextOrNull("UI_ZeD_..."), and any whole-string "UI_ZeD_..." (keys kept in tables). The keys built
     in code (UI_ZeD_Act_<action>, UI_ZeD_Track_Compass<point>) are checked family by family.
  3. Placeholders: the number of arguments in a ZeD.tr call matches the highest %n in the English.
  4. No English drawn to screen from a bare string. In client/ZeD and shared/ZeD it looks at
        drawText / drawTextCentre / drawTextRight (and other drawText* variants): the first string argument
        label = "..", title = "..", text = "..", tooltip = "..", hint = ".."
        ISModalDialog:new(...) string arguments, and addOption("..")
     A string counts as English when it is not a bare key (Prefix_Name) and has a lowercase word of 2+ letters (once %1..%4 and <TAGS> are
     removed). Anything found that is not in i18n_allowlist.txt fails.

Allowlist: i18n_allowlist.txt next to this file. One entry per line, "file|exact string" (the file's base
name, the string exactly as written between the quotes). Not line numbers, so edits do not break it.
Blank lines and lines starting with # are ignored. An entry that no longer matches anything is reported
as stale (a warning, not a failure) so the list shrinks as the code is cleaned up.

To fix a failure: make the text a ZeD.tr("UI_ZeD_<Area>_<What>") key (and add it to the fragment/UI.json),
or, if it is meant to stay English (debug, QA, art, an id), add one line to the allowlist saying why above it.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MOD = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
LUA = os.path.join(MOD, "42", "media", "lua")
SCAN = [os.path.join(LUA, "client", "ZeD"), os.path.join(LUA, "shared", "ZeD")]
UI_JSON = os.path.join(LUA, "shared", "Translate", "EN", "UI.json")
ALLOW = os.path.join(HERE, "i18n_allowlist.txt")
KEY_RE = re.compile(r"^UI_ZeD_[A-Za-z0-9_]+$")

# keys built in code from a prefix; every value that can occur is checked below
DYNAMIC_PREFIX = {"UI_ZeD_Act_", "UI_ZeD_Track_Compass", "UI_ZeD_D", "UI_ZeD_Animals_Dis_", "UI_ZeD_Dash_Prompt",
                  "UI_ZeD_Watch_Day", "UI_ZeD_"}
TRACK_POINTS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

fails = []
warns = []


def fail(msg):
    fails.append(msg)
    print("  FAIL " + msg)


def ok(msg):
    print("  ok   " + msg)


def lua_files():
    for base in SCAN:
        for dp, _, fs in os.walk(base):
            for f in sorted(fs):
                if f.endswith(".lua"):
                    yield os.path.join(dp, f)


def strip_comments(src):
    """The source with comments blanked (newlines kept, so line numbers hold). Strings stay."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c == '"' or c == "'":
            q = c
            j = i + 1
            while j < n and src[j] != q and src[j] != "\n":
                if src[j] == "\\":
                    j += 1
                j += 1
            out.append(src[i:j + 1])
            i = j + 1
        elif c == "[" and src.startswith("[[", i):
            j = src.find("]]", i + 2)
            j = n if j < 0 else j + 2
            out.append(src[i:j])
            i = j
        elif c == "-" and src.startswith("--", i):
            if src.startswith("--[[", i):
                j = src.find("]]", i + 4)
                j = n if j < 0 else j + 2
                out.append(re.sub(r"[^\n]", " ", src[i:j]))
                i = j
            else:
                j = src.find("\n", i)
                j = n if j < 0 else j
                out.append(" " * (j - i))
                i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def unescape(s):
    esc = {"n": "\n", "t": "\t", '"': '"', "'": "'", "\\": "\\"}
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            nx = s[i + 1]
            if nx.isdigit():
                j = i + 1
                while j < len(s) and j < i + 4 and s[j].isdigit():
                    j += 1
                out.append(chr(int(s[i + 1:j])))
                i = j
                continue
            out.append(esc.get(nx, nx))
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


STR = r'(?:"((?:[^"\\\n]|\\.)*)"|\'((?:[^\'\\\n]|\\.)*)\')'


def sval(m, a):
    return unescape(m.group(a) if m.group(a) is not None else m.group(a + 1))


def is_english(s):
    if re.fullmatch(r"[A-Za-z][A-Za-z0-9]*_[A-Za-z0-9_.]+", s):
        return False   # a translation key (UI_ZeD_..., IGUI_..., ContextMenu_...) or an id, not words
    t = re.sub(r"%[1-4]", " ", s)
    t = re.sub(r"<[A-Za-z/][^>]*>", " ", t)
    return re.search(r"[a-z]{2,}", t) is not None


def line_of(src, pos):
    return src.count("\n", 0, pos) + 1


def args_of(src, i):
    """Index just past the ( at i-1: the list of (start, end) spans of each top-level argument."""
    spans = []
    depth = 0
    start = i
    j = i
    n = len(src)
    while j < n:
        c = src[j]
        if c == '"' or c == "'":
            q = c
            j += 1
            while j < n and src[j] != q and src[j] != "\n":
                if src[j] == "\\":
                    j += 1
                j += 1
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            if depth == 0:
                if src[start:j].strip():
                    spans.append((start, j))
                return spans, j
            depth -= 1
        elif c == "," and depth == 0:
            spans.append((start, j))
            start = j + 1
        j += 1
    return spans, j


def load_allow():
    allow = {}
    if not os.path.exists(ALLOW):
        return allow
    for raw in open(ALLOW, encoding="utf-8"):
        line = raw.rstrip("\r\n")
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if "|" not in line:
            warns.append("allowlist line without a | : " + line[:80])
            continue
        f, s = line.split("|", 1)
        allow[(f.strip(), s)] = False
    return allow


DRAW_RE = re.compile(r"\bdrawText\w*\s*\(\s*" + STR)
FIELD_RE = re.compile(r"\b(label|title|text|tooltip|hint)\s*=(?!=)\s*" + STR)
OPT_RE = re.compile(r"\baddOption\s*\(\s*" + STR)
MODAL_RE = re.compile(r"\bISModalDialog\s*:\s*new\s*\(")


def english_findings(path, src):
    """(line, kind, string) for each English literal drawn to screen."""
    found = []
    for m in DRAW_RE.finditer(src):
        found.append((line_of(src, m.start()), "drawText", sval(m, 1)))
    for m in FIELD_RE.finditer(src):
        found.append((line_of(src, m.start()), m.group(1) + "=", sval(m, 2)))
    for m in OPT_RE.finditer(src):
        found.append((line_of(src, m.start()), "addOption", sval(m, 1)))
    for m in MODAL_RE.finditer(src):
        spans, _ = args_of(src, m.end())
        for a, b in spans:
            sm = re.fullmatch(r"\s*" + STR + r"\s*", src[a:b])
            if sm:
                found.append((line_of(src, a), "ISModalDialog", sval(sm, 1)))
    return [(ln, k, s) for ln, k, s in found if is_english(s)]


def check_json():
    try:
        data = json.load(open(UI_JSON, encoding="utf-8"))
    except Exception as e:
        fail("UI.json does not parse: " + str(e))
        return {}
    if not isinstance(data, dict):
        fail("UI.json is not a flat object")
        return {}
    bad = [k for k, v in data.items() if not KEY_RE.match(k) or not isinstance(v, str) or v == ""]
    if bad:
        fail("UI.json has %d bad entries (key shape or empty/non-string value), e.g. %s" % (len(bad), bad[:5]))
    else:
        ok("UI.json valid, %d keys" % len(data))
    return data


def check_keys(ui, sources):
    missing = []
    call_re = re.compile(r"\b(?:ZeD\.tr|getText|getTextOrNull)\s*\(\s*\"(UI_ZeD_[A-Za-z0-9_]*)\"")
    bare_re = re.compile(r"\"(UI_ZeD_[A-Za-z0-9_]*)\"")
    nlit = 0
    for path, src in sources:
        base = os.path.basename(path)
        for m in call_re.finditer(src):
            nlit += 1
            k = m.group(1)
            tail = src[m.end():m.end() + 6].lstrip()
            if tail.startswith(".."):
                continue   # a prefix, checked as a family below
            if k not in ui:
                missing.append("%s:%d %s" % (base, line_of(src, m.start()), k))
        for m in bare_re.finditer(src):
            k = m.group(1)
            tail = src[m.end():m.end() + 6].lstrip()
            if k in ui or k.endswith("_") or tail.startswith("..") or k in DYNAMIC_PREFIX:
                continue
            missing.append("%s:%d %s" % (base, line_of(src, m.start()), k))
    missing = list(dict.fromkeys(missing))
    if missing:
        fail("%d keys used in the Lua are not in UI.json:" % len(missing))
        for x in missing[:60]:
            print("         " + x)
    else:
        ok("every literal key in the Lua exists in UI.json (%d calls)" % nlit)

    # UI_ZeD_Act_<action type> for every action the bar knows
    ab = None
    for path, src in sources:
        if os.path.basename(path) == "ZeD_ActionBar.lua":
            ab = src
    if ab is not None:
        i = ab.find("AB.LABELS = {")
        j = ab.find("\n}", i) if i >= 0 else -1
        if i >= 0 and j > i:
            types = re.findall(r"(?:^|[\s,{])\[?\"?([A-Za-z0-9_]+)\"?\]?\s*=\s*\"", ab[i:j])
            lack = [t for t in types if "UI_ZeD_Act_" + t not in ui]
            if lack:
                fail("action bar labels without a UI_ZeD_Act_ key: %s" % lack[:10])
            else:
                ok("all %d action bar labels have a UI_ZeD_Act_ key" % len(types))
        else:
            warns.append("could not find AB.LABELS in ZeD_ActionBar.lua")
    lack = [p for p in TRACK_POINTS if "UI_ZeD_Track_Compass" + p not in ui]
    if lack:
        fail("compass points without a key: %s" % lack)
    else:
        ok("all 8 compass points have a UI_ZeD_Track_Compass key")


def check_placeholders(ui, sources):
    bad = []
    n = 0
    call_re = re.compile(r"\bZeD\.tr\s*\(\s*\"(UI_ZeD_[A-Za-z0-9_]+)\"")
    for path, src in sources:
        for m in call_re.finditer(src):
            k = m.group(1)
            if k not in ui:
                continue
            spans, _ = args_of(src, m.start() + m.group(0).index("(") + 1)
            given = max(len(spans) - 1, 0)
            need = max([int(x) for x in re.findall(r"%([1-4])", ui[k])] or [0])
            n += 1
            if given != need:
                bad.append("%s:%d %s needs %d argument(s), call passes %d" % (os.path.basename(path), line_of(src, m.start()), k, need, given))
    if bad:
        fail("%d ZeD.tr calls whose arguments do not match the placeholders:" % len(bad))
        for x in bad[:40]:
            print("         " + x)
    else:
        ok("placeholders match the arguments in %d ZeD.tr calls" % n)


def check_percent(ui):
    """A literal percent sign is written %% (as in vanilla's files). The game runs every text through
    Java's String.formatted, where a lone % is a format error: "cond %1%" would show "cond 80$s%"."""
    bad = []
    for k, v in ui.items():
        rest = re.sub(r"%%|%[1-9]", "", v)
        if "%" in rest:
            bad.append("%s: %r" % (k, v))
    if bad:
        fail("%d texts with a lone %% (write a percent sign as %%%%):" % len(bad))
        for x in bad[:40]:
            print("         " + x)
    else:
        ok("no lone % in UI.json (a percent sign is written %%)")


def main():
    show_list = "--list" in sys.argv
    seed = "--seed" in sys.argv
    print("i18n guard")
    ui = check_json()

    sources = []
    for path in lua_files():
        raw = open(path, encoding="utf-8", errors="replace").read()
        sources.append((path, strip_comments(raw)))

    if ui:
        check_keys(ui, sources)
        check_placeholders(ui, sources)
        check_percent(ui)

    allow = load_allow()
    new = []
    total = 0
    for path, src in sources:
        base = os.path.basename(path)
        for ln, kind, s in english_findings(path, src):
            total += 1
            hit = (base, s) in allow
            if hit:
                allow[(base, s)] = True
            else:
                new.append((base, ln, kind, s))
            if show_list:
                print("  %-5s %s:%d %s %r" % ("allow" if hit else "NEW", base, ln, kind, s))
    if new:
        fail("%d English literal(s) drawn to screen are not translated and not in the allowlist:" % len(new))
        for base, ln, kind, s in new[:80]:
            print("         %s:%d  %s  %r" % (base, ln, kind, s))
        if len(new) > 80:
            print("         ... and %d more (run with --list)" % (len(new) - 80))
        print("       Make each a ZeD.tr(\"UI_ZeD_<Area>_<What>\") key, or add 'file|string' to i18n_allowlist.txt with a reason.")
    else:
        ok("no unlisted English drawn to screen (%d literals found, all allowlisted)" % total)
    stale = [k for k, used in allow.items() if not used]
    if stale:
        warns.append("%d allowlist entries match nothing now (safe to delete), e.g. %s|%s" % (len(stale), stale[0][0], stale[0][1][:40]))
    if seed:
        print("\n# seed lines:")
        for base, ln, kind, s in new:
            print("%s|%s" % (base, s))
    for w in warns:
        print("  warn " + w)
    print("\nRESULT: " + ("FAIL (%d)" % len(fails) if fails else "PASS"))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
