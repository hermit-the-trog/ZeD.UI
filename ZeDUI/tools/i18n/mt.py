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
    else:
        print(__doc__)
        sys.exit(2)
