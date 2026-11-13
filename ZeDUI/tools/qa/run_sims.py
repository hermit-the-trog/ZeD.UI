"""Run every sim (ZeDUI/tools/qa/*_sim.lua) outside the game and print one line per sim.

    python ZeDUI/tools/qa/run_sims.py            every sim
    python ZeDUI/tools/qa/run_sims.py dash odo   only sims whose name holds one of the words

Finds Lua 5.1 in the VS Code Lua debugger's runtime (or the LUA51 environment variable).
Exit code 0 when every sim reports 0 failed, 1 when any fails, crashes or prints no count.
Run from anywhere; it works from the repo root.
"""
import glob
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..', '..'))


def find_lua():
    env = os.environ.get('LUA51')
    if env and os.path.isfile(env):
        return env
    pat = os.path.join(os.path.expanduser('~'), '.vscode', 'extensions', 'actboy168.lua-debug-*',
                       'runtime', 'win32-x64', 'lua51', 'lua.exe')
    hits = sorted(glob.glob(pat))
    return hits[-1] if hits else None


COUNT = re.compile(r'(\d+)\s+(?:checks?|pass(?:ed)?)[^\n]*?(\d+)\s+fail', re.I)


def main():
    lua = find_lua()
    if not lua:
        print('no Lua 5.1 found: set LUA51 to lua.exe')
        return 1
    words = [w.lower() for w in sys.argv[1:]]
    sims = sorted(glob.glob(os.path.join(HERE, '*_sim.lua')))
    if words:
        sims = [s for s in sims if any(w in os.path.basename(s).lower() for w in words)]
    bad = 0
    t0 = time.time()
    for s in sims:
        name = os.path.basename(s)[:-len('_sim.lua')]
        try:
            p = subprocess.run([lua, s], cwd=ROOT, capture_output=True, text=True, errors='replace', timeout=600)
            out = (p.stdout or '') + (p.stderr or '')
        except subprocess.TimeoutExpired:
            print(f'TIMEOUT  {name}')
            bad += 1
            continue
        m = None
        for m in COUNT.finditer(out):
            pass
        if m is None:
            print(f'NO COUNT {name} (exit {p.returncode}): {out.strip().splitlines()[-1][:120] if out.strip() else ""}')
            bad += 1
        elif int(m.group(2)) > 0 or p.returncode not in (0, None):
            print(f'FAIL     {name}: {m.group(1)} checks, {m.group(2)} failed')
            bad += 1
        else:
            print(f'ok       {name}: {m.group(1)} checks')
    print(f'{len(sims)} sims, {bad} not clean, {time.time() - t0:.0f} s')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
