"""Machine-translation drafts for ZeD-GUI (the director, Nov 2 2026, punch list 62).

Every language the game supports gets an AI-drafted UI.json, shipped in the mod and labelled as a machine translation
until players have checked it. This tool keeps the drafts honest:

  split <out_dir> [--size N]      the English, cut into parts of N keys (default 300), each key with its English, where
                                  it shows and its longest length (from ZeDUI/i18n/UI_ZeD.context.md), as part_NN.json
  check <file> [--lang L]         a translated part or a whole UI.json against the English: valid JSON, only known
                                  keys, every %1-%4 and %% kept, markup like <LINE> kept, no lone %, no English left
                                  where a translation is expected (reported, not failed: some words stay the same)
  merge <parts_dir> <LANG>        the translated parts into 42/media/lua/shared/Translate/<LANG>/UI.json, in the
                                  English key order, with the Sandbox and ItemName files beside it if parts hold them
  pack <out_dir> [--size N] [--with LANG]
                                  the English as numbered lines for a translator (fewer tokens than split): one
                                  pack_NN.txt per N keys (default 1100), "number | longest | where | English", a
                                  "^" where the place is the same as the line above; index.json maps the numbers back.
                                  --with adds ZeD's current LANG text under each line ("  = ..."), for a variant or a
                                  proofreader that sends back only the lines it changes
  glossary <LANG> <out_file>      the game's own words for <LANG>: short phrases of the game's English that ZeD's
                                  English uses, with what the game's <LANG> files call them (game wording wins)
  unpack <pack_dir> <out_dir> [--base LANG]
                                  a translator's out_NN.txt files ("number<TAB>text" per line, an optional third
                                  column, a reason, is dropped) back into part_NN.json files for check and merge;
                                  --base starts from ZeD's current LANG text, so the out files need only the changes

Run with the ComfyUI venv Python and -I, from the repo root.
"""
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
EN_DIR = os.path.join(ROOT, '42', 'media', 'lua', 'shared', 'Translate', 'EN')
CONTEXT = os.path.join(ROOT, 'ZeDUI', 'i18n', 'UI_ZeD.context.md')
FILES = ('UI.json', 'Sandbox.json', 'ItemName.json')

PLACE = re.compile(r'%[1-9]')
MARKUP = re.compile(r'<[A-Z_]+(?::[^>]*)?>')
MOJIBAKE = re.compile('[ÂÃ][\u0080-¿]|â€|�')


def load_json(path):
    with open(path, encoding='utf-8-sig') as f:
        return json.load(f)


def english():
    """{key: (file, english)} in file order, UI.json first."""
    out = {}
    for fn in FILES:
        p = os.path.join(EN_DIR, fn)
        if os.path.exists(p):
            for k, v in load_json(p).items():
                out[k] = (fn, v)
    return out


def context():
    ctx = {}
    if not os.path.exists(CONTEXT):
        return ctx
    row = re.compile(r'^\| `([^`]+)` \| `(.*)` \| (.*) \| ([^|]*) \|\s*$')
    with open(CONTEXT, encoding='utf-8') as f:
        for line in f:
            m = row.match(line)
            if m:
                ctx[m.group(1)] = (m.group(3).strip(), m.group(4).strip())
    return ctx


def split(out_dir, size=300):
    en, ctx = english(), context()
    os.makedirs(out_dir, exist_ok=True)
    keys = list(en.keys())
    n = 0
    for i in range(0, len(keys), size):
        n += 1
        part = {}
        for k in keys[i:i + size]:
            fn, v = en[k]
            where, mx = ctx.get(k, ('', '-'))
            part[k] = {'en': v, 'file': fn, 'where': where, 'max': mx}
        with open(os.path.join(out_dir, 'part_%02d.json' % n), 'w', encoding='utf-8') as f:
            json.dump(part, f, ensure_ascii=False, indent=1)
    print('split %d keys into %d parts in %s' % (len(keys), n, out_dir))


def check_pairs(pairs, en):
    """pairs: {key: translation}. Returns (errors, warnings)."""
    errs, warns = [], []
    for k, t in pairs.items():
        if k not in en:
            errs.append('%s: not an English key' % k)
            continue
        if not isinstance(t, str):
            errs.append('%s: not a string' % k)
            continue
        e = en[k][1]
        if sorted(PLACE.findall(e)) != sorted(PLACE.findall(t)):
            errs.append('%s: placeholders %s became %s' % (k, PLACE.findall(e), PLACE.findall(t)))
        if e.count('%%') != t.count('%%'):
            errs.append('%s: %%%% count %d became %d' % (k, e.count('%%'), t.count('%%')))
        lone = re.sub(r'%%|%[1-9]', '', t)
        if '%' in lone:
            errs.append('%s: a lone %% (write %%%%)' % k)
        if sorted(MARKUP.findall(e)) != sorted(MARKUP.findall(t)):
            errs.append('%s: markup %s became %s' % (k, MARKUP.findall(e), MARKUP.findall(t)))
        if t.strip() == '' and e.strip() != '':
            errs.append('%s: empty' % k)
        if MOJIBAKE.search(t) and not MOJIBAKE.search(e):
            errs.append('%s: garbled letters (UTF-8 read as Latin-1, e.g. "Ã³" for "ó")' % k)
        if t == e and re.search(r'[A-Za-z]{4,}', e):
            warns.append('%s: same as English (%r)' % (k, e[:40]))
    return errs, warns


def check(path, lang=None):
    en = english()
    data = load_json(path)
    # a part file may still carry the English layout ({key: {"en":..}}): take "tr" from it
    pairs = {}
    for k, v in data.items():
        pairs[k] = v.get('tr') if isinstance(v, dict) else v
    errs, warns = check_pairs(pairs, en)
    missing = [k for k in en if k not in pairs] if os.path.basename(path) == 'UI.json' else []
    for e in errs[:60]:
        print('  FAIL ' + e)
    for w in warns[:20]:
        print('  note ' + w)
    print('%s: %d keys, %d errors, %d same as English%s' % (
        path, len(pairs), len(errs), len(warns), (', %d missing (fall back to English)' % len(missing)) if missing else ''))
    return 1 if errs else 0


def merge(parts_dir, lang):
    en = english()
    got = {}
    for fn in sorted(os.listdir(parts_dir)):
        if fn.startswith('part_') and fn.endswith('.json'):
            for k, v in load_json(os.path.join(parts_dir, fn)).items():
                got[k] = v.get('tr') if isinstance(v, dict) else v
    errs, warns = check_pairs(got, en)
    if errs:
        for e in errs[:60]:
            print('  FAIL ' + e)
        print('merge stopped: %d errors' % len(errs))
        return 1
    out_dir = os.path.join(ROOT, '42', 'media', 'lua', 'shared', 'Translate', lang)
    os.makedirs(out_dir, exist_ok=True)
    for fn in FILES:
        keys = [k for k, (f, _) in en.items() if f == fn and k in got]
        if not keys:
            continue
        body = ',\n'.join('    %s: %s' % (json.dumps(k, ensure_ascii=False), json.dumps(got[k], ensure_ascii=False)) for k in keys)
        with open(os.path.join(out_dir, fn), 'w', encoding='utf-8', newline='\n') as f:
            f.write('{\n' + body + '\n}\n')
        print('wrote %s/%s: %d keys' % (lang, fn, len(keys)))
    missing = [k for k in en if k not in got]
    print('%s: %d translated, %d missing (fall back to English), %d same as English' % (lang, len(got), len(missing), len(warns)))
    return 0


GAME_TR = r'E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/shared/Translate'


def _esc(v):
    return v.replace('\\', '\\\\').replace('\n', '\\n').replace('\t', '\\t')


def _unesc(v):
    out, i = [], 0
    while i < len(v):
        c = v[i]
        if c == '\\' and i + 1 < len(v):
            n = v[i + 1]
            out.append({'n': '\n', 't': '\t', '\\': '\\'}.get(n, '\\' + n))
            i += 2
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def _ours(lang):
    """{key: text} from ZeD's own Translate/<lang> files (empty when the language has none yet)."""
    out = {}
    d = os.path.join(ROOT, '42', 'media', 'lua', 'shared', 'Translate', lang)
    for fn in FILES:
        p = os.path.join(d, fn)
        if os.path.exists(p):
            out.update(load_json(p))
    return out


def pack(out_dir, size=1100, with_lang=None):
    en, ctx = english(), context()
    have = _ours(with_lang) if with_lang else {}
    os.makedirs(out_dir, exist_ok=True)
    keys = list(en.keys())
    index = {}
    n = 0
    for i in range(0, len(keys), size):
        n += 1
        lines, prev = [], None
        for j, k in enumerate(keys[i:i + size]):
            num = i + j + 1
            index[str(num)] = k
            where, mx = ctx.get(k, ('', '-'))
            w = '^' if where == prev else (where or '-')
            prev = where
            lines.append('%d | %s | %s | %s' % (num, mx, w, _esc(en[k][1])))
            if with_lang:
                # the language's current text on its own line (the English may hold " | " itself)
                lines.append('  = ' + (_esc(have[k]) if k in have else '(none yet)'))
        with open(os.path.join(out_dir, 'pack_%02d.txt' % n), 'w', encoding='utf-8', newline='\n') as f:
            f.write('\n'.join(lines) + '\n')
    with open(os.path.join(out_dir, 'index.json'), 'w', encoding='utf-8') as f:
        json.dump(index, f, ensure_ascii=False)
    print('packed %d keys into %d packs in %s' % (len(keys), n, out_dir))


GAME_UI_FILES = ('UI.json', 'IG_UI.json', 'ContextMenu.json', 'Tooltip.json', 'Moodles.json', 'BodyParts.json', 'Sandbox.json')
STOP = set('a an the and or of to in on at by for from with as is are be it its this that you your yes no up out off one all can '
           'not but if so do does has have will what when where which who how more most less other some any each '.split())


def _game_strings(lang, files=GAME_UI_FILES):
    """{key: text} from the game's interface files in Translate/<lang> (files that do not parse are skipped)."""
    out = {}
    d = os.path.join(GAME_TR, lang)
    if not os.path.isdir(d):
        return out
    for fn in sorted(os.listdir(d)):
        if fn in files:
            try:
                data = load_json(os.path.join(d, fn))
            except Exception:
                continue
            for k, v in data.items():
                if isinstance(v, str):
                    out[k] = v
    return out


def glossary(lang, out_file, top=160):
    zed = [v.lower() for _, v in english().values()]
    gen, gl = _game_strings('EN'), _game_strings(lang)
    phrase = re.compile(r"^[A-Za-z][A-Za-z' -]{1,23}$")
    by_en = {}
    for k, v in gen.items():
        v2 = v.strip()
        if phrase.match(v2) and len(v2.split()) <= 3 and v2.lower() not in STOP and k in gl and gl[k].strip() and gl[k].strip() != v2:
            by_en.setdefault(v2.lower(), {}).setdefault(gl[k].strip(), 0)
            by_en[v2.lower()][gl[k].strip()] += 1
    scored = []
    for term, targets in by_en.items():
        pat = re.compile(r'(?<![a-z])' + re.escape(term) + r'(?![a-z])')
        hits = sum(1 for z in zed if pat.search(z))
        if hits >= 3:
            best = sorted(targets.items(), key=lambda t: -t[1])[:2]
            scored.append((hits, term, ' / '.join(t for t, _ in best)))
    scored.sort(key=lambda t: (-t[0], t[1]))
    with open(out_file, 'w', encoding='utf-8', newline='\n') as f:
        f.write('# The game\'s own interface words in %s (English = the game\'s %s; two when the game uses both), most '
                'used in ZeD first. Use the game\'s word where the meaning matches; a word can be wrong for a given line.\n'
                % (lang, lang))
        for hits, term, tgt in scored[:top]:
            f.write('%s = %s\n' % (term, tgt))
    print('glossary %s: %d terms in %s' % (lang, min(top, len(scored)), out_file))


def unpack(pack_dir, out_dir, base=None):
    """With base=LANG the out files hold only changed lines: ZeD's current <base> text is written first as part_00.json,
    so merge (later parts win) keeps every line the out files leave alone. A third tab column (a reason) is dropped."""
    index = load_json(os.path.join(pack_dir, 'index.json'))
    os.makedirs(out_dir, exist_ok=True)
    total, bad = 0, 0
    if base:
        have = _ours(base)
        with open(os.path.join(out_dir, 'part_00.json'), 'w', encoding='utf-8') as f:
            json.dump(have, f, ensure_ascii=False, indent=1)
        print('base %s: %d keys' % (base, len(have)))
    for fn in sorted(os.listdir(pack_dir)):
        if not (fn.startswith('out_') and fn.endswith('.txt')):
            continue
        part = {}
        with open(os.path.join(pack_dir, fn), encoding='utf-8-sig') as f:
            for ln, line in enumerate(f, 1):
                line = line.rstrip('\r\n')
                if not line.strip():
                    continue
                num, sep, text = line.partition('\t')
                k = index.get(num.strip())
                if not sep or not k:
                    print('  FAIL %s line %d: not "number<TAB>text": %r' % (fn, ln, line[:60]))
                    bad += 1
                    continue
                part[k] = _unesc(text.split('\t')[0])
        total += len(part)
        with open(os.path.join(out_dir, fn.replace('out_', 'part_').replace('.txt', '.json')), 'w', encoding='utf-8') as f:
            json.dump(part, f, ensure_ascii=False, indent=1)
    print('unpacked %d lines (%d bad) of %d keys into %s' % (total, bad, len(index), out_dir))
    return 1 if bad else 0


if __name__ == '__main__':
    a = sys.argv[1:]
    if not a:
        print(__doc__)
        sys.exit(2)
    if a[0] == 'split':
        size = int(a[a.index('--size') + 1]) if '--size' in a else 300
        split(a[1], size)
    elif a[0] == 'check':
        sys.exit(check(a[1]))
    elif a[0] == 'merge':
        sys.exit(merge(a[1], a[2]))
    elif a[0] == 'pack':
        pack(a[1], int(a[a.index('--size') + 1]) if '--size' in a else 1100,
             a[a.index('--with') + 1] if '--with' in a else None)
    elif a[0] == 'glossary':
        glossary(a[1], a[2])
    elif a[0] == 'unpack':
        sys.exit(unpack(a[1], a[2], a[a.index('--base') + 1] if '--base' in a else None))
    else:
        print(__doc__)
        sys.exit(2)
