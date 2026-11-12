"""The game's own Lua files, as a list ZeD ships (punch list 170, Nov 11 2026).

The Mods screen's Files tab switches a mod's Lua file off by putting a do-nothing copy at the same path in ZeD picks,
which loads last. When that path is also one of the game's own files (a mod that replaces ISInventoryPane.lua), the
do-nothing copy would replace the game's copy too, and Lua cannot read the game's media folder to tell (the reader for
it, getGameFilesTextInput, works only in -debug). So ZeD ships the list of the game's Lua paths, and those files are
never switched off.

  usage:  python -I vanilla_lua_index.py <game folder> <build>
          e.g.  python -I ZeDUI/tools/mods/vanilla_lua_index.py "E:/Project Zomboid/SteamApps/common/ProjectZomboid" 42.22

Writes 42/media/lua/client/ZeD/ZeD_VanillaLua.lua: every .lua under media/lua, lower case, relative to media/lua.
Run it again after a game update that adds Lua files.
"""
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
OUT = os.path.join(ROOT, '42', 'media', 'lua', 'client', 'ZeD', 'ZeD_VanillaLua.lua')


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    game, build = sys.argv[1], sys.argv[2]
    base = os.path.join(game, 'media', 'lua')
    paths = []
    for dirpath, _, files in os.walk(base):
        for f in files:
            if f.lower().endswith('.lua'):
                rel = os.path.relpath(os.path.join(dirpath, f), base).replace('\\', '/').lower()
                rel.encode('ascii')   # (a non-ASCII path would lose its high bytes in Kahlua)
                if ']]' in rel:
                    raise SystemExit('a path holds ]]: ' + rel)
                paths.append(rel)
    paths.sort()
    head = [
        '-- ZeD-UI/42/media/lua/client/ZeD/ZeD_VanillaLua.lua',
        '-- ============================================================================',
        "-- THE GAME'S OWN LUA FILES, a generated list (ZeDUI/tools/mods/vanilla_lua_index.py;",
        '-- do not edit by hand). Client; data only.',
        '--',
        "-- The Files tab never switches off a path the game has too: ZeD picks' do-nothing",
        "-- copy would replace the game's copy as well (ZeD_ModFiles.lua). Lower case,",
        '-- relative to media/lua, one per line.',
        '-- ============================================================================',
        'ZeD = ZeD or {}',
        'ZeD.VanillaLua = { build = "%s", count = %d, list = [[' % (build, len(paths)),
    ]
    with open(OUT, 'w', encoding='ascii', newline='\n') as f:
        f.write('\n'.join(head) + '\n')
        f.write('\n'.join(paths) + '\n')
        f.write(']] }\n')
    print('%d paths, build %s -> %s' % (len(paths), build, OUT))
    return 0


if __name__ == '__main__':
    sys.exit(main())
