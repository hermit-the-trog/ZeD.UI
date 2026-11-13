"""Builds Lua Console 93 Professional Edition, a mod of its own made from ZeD-GUI's Lua console.

ZeD-GUI's files stay the one source. This tool reads the console's six files whole, then takes from ZeD's other
files only the parts the console reaches (its closure, worked out below), renames every ZeD name, path and
translation key to Lua Console 93's own, and writes the mod into products/LuaConsole93/ in the repo:

    products/LuaConsole93/
        42/mod.info, poster.png, icon.png, README.txt, LICENSE.txt (the repo's LICENSE, which the texts cite)
        42/media/lua/client/LuaConsole93/*.lua          the console and the parts of ZeD-GUI it uses
        42/media/lua/shared/Translate/<LANG>/UI.json     only the keys it uses, renamed, 28 languages
        42/media/textures/LuaConsole93/                  the controller's slice picture (the icon), ZeD-GUI's arrow strip
        workshop/preview.png, workshop/README.txt        the Workshop page's picture and the gallery shot list
        workshop_description.bbcode                      the Workshop page's text
The pictures are design's (ZeDUI/art/lua_console_93/: preview.png, poster.png, icon.png), copied at each build.
QA's gallery shots live in ZeDUI/workshop/luaconsole93/, outside the built folder.

Run it from anywhere with the no-install Python:
    python -I ZeDUI/tools/products/build_luaconsole93.py            build products/LuaConsole93
    python -I ZeDUI/tools/products/build_luaconsole93.py --stage    build, then copy the mod to ~/Zomboid/mods/LuaConsole93
    python -I ZeDUI/tools/products/build_luaconsole93.py --check    build into a temporary folder and compare with
                                                                    products/LuaConsole93 (exit 1 when they differ)
    python -I ZeDUI/tools/products/build_luaconsole93.py --report   also print the closure: every part taken and why,
                                                                    what is left out, and any function taken here
                                                                    that another of ZeD-GUI's files defines again
Then the checks: lua51 ZeDUI/tools/qa/luaconsole93_sim.lua, and
python -I ZeDUI/tools/qa/kahlua_guard.py --path products/LuaConsole93/42/media/lua. QA: ZeDUI/qa/CHECK_luaconsole93.md.

Everything in products/LuaConsole93 is written by this tool and rewritten whole on each run: a console fix in
ZeD-GUI is a run of this tool, never a hand edit there. The output is the same bytes for the same sources.

The rules the output keeps (and checks before it writes anything):
  * No clash with ZeD-GUI. The game loads Lua, textures and fonts by relative path, a later mod's file replacing an
    earlier one's, so no file here sits at a path ZeD-GUI ships. Translate files are the exception the game makes
    itself: Translator.tryFillMapFromMods reads every mod's own Translate folder and merges the keys (javap,
    42.22.2), so only the keys must differ, and they do (UI_LC93_*).
  * Nothing looks like ZeD-GUI. Other mods test `if ZeD then` to find ZeD-GUI, so the global table is LC93, the
    classes LC93_<Class>, the requires LuaConsole93/<file>. No ZeD name survives in the code, the strings or the
    keys; the file headers say where each file came from.
  * With ZeD-GUI on, ZeD-GUI's console is the one. Every file starts with a guard that returns before it defines
    anything when the mod ZeD_UI is active, whatever the load order.
  * The game's own fonts. ZeD-GUI draws in Fira by replacing the game's font list (media/fonts/EN/fonts.txt), the
    only way the game loads a font; a console mod must not restyle the whole game, and the path is ZeD-GUI's. So
    the roles draw in the game's own Small, Medium and Code faces (the fixed-pitch role on the game's Noto Sans Mono).
"""
import argparse
import filecmp
import json
import os
import re
import shutil
import sys
import tempfile

# ======================================================================================================================
# THE PRODUCT: its names in one place (rename it here and run again)
# ======================================================================================================================
NAME = "Lua Console 93 Professional Edition"   # mod.info, the Workshop page, the README
SHORT = "Lua Console 93"                        # the window's title and the log's "[Lua Console 93]" lines
MOD_ID = "LuaConsole93"                         # mod id, mod folder, media/.../LuaConsole93/ paths, file names
TABLE = "LC93"                                  # the global table, the classes (LC93_<Class>), the keys (UI_LC93_*)
VERSION = "1.0.0"
ZED_MOD_ID = "ZeD_UI"                           # ZeD-GUI's mod id: with it on, its console is used
ZED_NAME = "ZeD-GUI"

KEY_PREFIX = "UI_" + TABLE + "_"

# ======================================================================================================================
# WHERE THINGS ARE
# ======================================================================================================================
TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.normpath(os.path.join(TOOL_DIR, "..", "..", ".."))
SRC = os.path.join(REPO, "42", "media", "lua")
ZED_MOD_INFO = os.path.join(REPO, "42", "mod.info")
TRANSLATE = os.path.join(SRC, "shared", "Translate")
ART_DIR = os.path.join(REPO, "ZeDUI", "art", "lua_console_93")
LICENSE = os.path.join(REPO, "LICENSE")
LICENSE_URL = "https://github.com/hermit-the-trog/ZeD.UI/blob/main/LICENSE"
GALLERY_REL = "ZeDUI/workshop/luaconsole93"   # QA's gallery shots: outside the built folder
OUT_REL = os.path.join("products", MOD_ID)
LUA_DIR_REL = "42/media/lua/client/" + MOD_ID
TEX_DIR_REL = "42/media/textures/" + MOD_ID
SLICE_TEX = "media/textures/" + MOD_ID + "/console_slice.png"

# ======================================================================================================================
# WHAT GOES IN
# ======================================================================================================================
# The console's own files: taken whole.
WHOLE = [
    "client/ZeD/ZeD_DebugConsole.lua",
    "client/ZeD/ZeD_ConsoleLog.lua",
    "client/ZeD/ZeD_ConsoleScratch.lua",
    "client/ZeD/ZeD_ConsoleComplete.lua",
    "client/ZeD/ZeD_ConsolePages.lua",
    "client/ZeD/ZeD_ConsoleCommands.lua",
]
# ZeD-GUI's files the closure may take parts from. A name the console reaches outside these files is left out and
# listed in the report (every such reach in ZeD-GUI is guarded: `if ZeD.X and ZeD.X.y then`).
SUPPORT = [
    "shared/ZeD/Tokens.lua",       # the palette and its tokens
    "shared/ZeD/Scale.lua",        # the root scale (its text manager is the shim below)
    "shared/ZeD/Tr.lua",           # ZeD.tr
    "client/ZeD/Atoms.lua",
    "client/ZeD/AtomExtensions.lua",
    "client/ZeD/Molecules.lua",
    "client/ZeD/Organisms.lua",    # the window
    "client/ZeD/ZeD_Surface.lua",  # the window's surfaces and help line
    "client/ZeD/SafeMode.lua",     # the draw guard only
    "client/ZeD/ZeD_FocusPaint.lua",
    "client/ZeD/ZeD_PadGlyphs.lua",
    "client/ZeD/PixelFonts.lua",
    "client/ZeD/ZeD_Prompt.lua",   # the help line's D-pad prompt only
    "client/ZeD/ZeD_Messages.lua", # the user-name scrub for an export only
]
# Names never taken from ZeD-GUI's files: stood in for by the shims below, or left out on purpose (every reach to
# them is guarded in ZeD-GUI's code, so a missing one reads as "not here").
LEFT_OUT = {
    "ZeD.Text": "shim: the game's own fonts, measured as they are (LC93_Text.lua)",
    "ZeD.TM": "shim: the game's text manager with the measures kept (LC93_Text.lua)",
    "ZeD.Keyboard": "shim: the game's own pad keyboard (LC93_Standalone.lua)",
    "ZeD.Chat": "shim: a chat channel's line sent through the game's chat (LC93_Standalone.lua)",
    "ZeD.Input": "ZeD-GUI's focus manager: the console runs the controller itself",
    "ZeD.Settings": "ZeD setup: fixed defaults here (Dark, PZ Teal, normal text, the game's UI scale)",
    "ZeD.WindowMenu": "the window box's menu: the window has no window box here",
    "ZeD.Safe.fault": "safe mode's watchdog: ZeD-GUI's setting, not here",
    "ZeD.Safe.on": "safe mode: ZeD-GUI's setting, not here",
    "ZeD.Safe.register": "safe mode: ZeD-GUI's setting, not here",
    "ZeD.Admin": "the server roles ZeD-GUI's server part reads: the game's default roles stand in",
}
# Effects (top-level statements that define nothing) kept although nothing in the closure names them.
ROOT_EFFECTS = [
    ("shared/ZeD/Tokens.lua", 'ZeD.applyTheme("dark", ZeD.DEFAULT_ACCENT, "small")'),   # the palette, made at load
    ("shared/ZeD/Scale.lua", "if Events and Events.OnTick then"),   # the palette made again when the scale moves
    ("client/ZeD/ZeD_Surface.lua", "if Events then"),   # the clip stack starts empty before and after each UI draw
]
# Effects that write into the game's own tables or globals: each one decided here. An undecided one that touches
# the closure stops the build.
OVERRIDES = {
    ("shared/ZeD/Scale.lua", "getTextManager = function"): "drop",    # ZeD-GUI's global text manager proxy
    ("client/ZeD/ZeD_Surface.lua", "if not ISUIElement._zedClipWrapped"): "drop",   # every panel's stencil watched
}
# Methods the engine (or ISPanel) calls by name: a class taken keeps these.
ENGINE_CALLBACKS = {
    "new", "initialise", "instantiate", "createChildren", "prerender", "render", "update", "onResize",
    "onMouseDown", "onMouseUp", "onMouseUpOutside", "onMouseMove", "onMouseMoveOutside", "onRightMouseDown",
    "onRightMouseUp", "onRightMouseDownOutside", "onRightMouseUpOutside", "onMouseWheel", "onMouseDoubleClick",
    "onJoypadDown", "onJoypadDirUp", "onJoypadDirDown", "onJoypadDirLeft", "onJoypadDirRight",
    "onGainJoypadFocus", "onLoseJoypadFocus", "onKeyPress", "onKeyRelease", "close", "setVisible",
}

# ======================================================================================================================
# THE EDITS: exact text, each found exactly once in its file (the build stops when ZeD-GUI's file has moved on)
# ======================================================================================================================
EDITS = [
    # the window's own title bar: no window box (it pulls ZeD-GUI's window menu down, which is not here)
    ("client/ZeD/ZeD_DebugConsole.lua", "    o.pin = true\n", "    o.pin = true\n    o.noWindowBox = true\n"),
    # a print tagged with this mod's short name is this mod's row in the log's MOD filter
    ("client/ZeD/ZeD_ConsoleLog.lua", '_mods = { zed = "ZeD-GUI" }',
     '_mods = { ["%s"] = "%s" }' % (SHORT.lower(), SHORT)),
    # the console's own help keys: the prefix is one letter longer here (UI_LC93_ against UI_ZeD_)
    ("client/ZeD/ZeD_ConsoleCommands.lua", 'string.sub(c.help, 1, 7) == "UI_ZeD_"',
     'string.sub(c.help, 1, %d) == "UI_ZeD_"' % len(KEY_PREFIX)),
    # the button-label exception for ZeD's own name has nothing to do here
    ("shared/ZeD/Tokens.lua", ' ZED = "ZeD",', ""),
    # ZeD setup's see-through default (90%), which ZeD-GUI's setup hands the palette as it loads
    ("shared/ZeD/Tokens.lua", 'ZeD.currentSize   = "small"\n', 'ZeD.currentSize   = "small"\nZeD.surfaceAlpha = 0.9\n'),
    # the role fonts: the shim picks the game's face for each role, so it is told which role it is picking for
    ("shared/ZeD/Tokens.lua", 'T["fontF" .. i] = ZeD.Text.roleFallbackFont(rolePx[i])',
     'T["fontF" .. i] = ZeD.Text.roleFallbackFont(rolePx[i], i)'),
    # the game's fonts are in place before any Lua runs: nothing to wait for (ZeD-GUI waits for its own atlases)
    ("shared/ZeD/Scale.lua", "if S._tick == 0 then rootChanged(); fontsSettle() end",
     "if S._tick == 0 then rootChanged() end"),
    # the clip in force: ZeD-GUI watches every panel's stencils by wrapping ISUIElement (dropped here: a console mod
    # must not wrap the game's base class). Every stencil the console sets is its window's, so the window tells the
    # surface layer itself, and a claim half scrolled out of a list is cut to the list as in ZeD-GUI
    ("client/ZeD/Organisms.lua",
     "    self._zedStencilN = (self._zedStencilN or 0) + 1\n    return ISPanel.setStencilRect(self, x, y, w, h)\n",
     "    self._zedStencilN = (self._zedStencilN or 0) + 1\n    local r = ISPanel.setStencilRect(self, x, y, w, h)\n"
     "    if ZeD.Surface and ZeD.Surface._pushClip then ZeD.Surface._pushClip(self, x, y, w, h) end\n    return r\n"),
    ("client/ZeD/Organisms.lua",
     "    if n and n > 0 then self._zedStencilN = n - 1 end\n    return ISPanel.clearStencilRect(self)\n",
     "    if n and n > 0 then self._zedStencilN = n - 1 end\n"
     "    if ZeD.Surface and ZeD.Surface._popClip then ZeD.Surface._popClip() end\n"
     "    return ISPanel.clearStencilRect(self)\n"),
]
# Words inside strings, in this order. What is left with "ZeD" in it stops the build.
STRING_RULES = [
    ("[ZeD] Lua console: ", "[%s] " % SHORT),     # the log's lines
    ("[ZeD] ", "[%s] " % SHORT),
    ("ZeD-GUI Lua console", SHORT),               # an export's first line, the snippet file's
    ("ZeD_console_", MOD_ID + "_"),               # the files in Zomboid/Lua
    ("ZeD/", MOD_ID + "/"),                       # requires and texture folders
    ("UI_ZeD_", KEY_PREFIX),                      # translation keys
    ("ZeD_", TABLE + "_"),                        # class names
    ("OnZeD", "On" + TABLE),                      # an event's name
    ("ZeD.", TABLE + "."),                        # a logged place
    ("ZeD window menu", "window menu"),
]
# Translations that name ZeD-GUI's own parts, told the way they are here (by language where the grammar needs it).
# A value still holding "ZeD" after these stops the build.
VALUE_RULES = {
    "UI_ZeD_Console_HelpPadA": [("ZeD:n", "Project Zomboidin"), ("ZeD'nin", "Project Zomboid'in"),
                                ("ZeDs", "Project Zomboids"), ("ZeD", "Project Zomboid")],
}
FILE_RULES = [("ZeD_console_", MOD_ID + "_")]   # file names inside translated text

# ======================================================================================================================
# THE LUA LEXER: enough of Lua 5.1 to tell code, strings and comments apart
# ======================================================================================================================
KEYWORDS = {"and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local",
            "nil", "not", "or", "repeat", "return", "then", "true", "until", "while"}
LONG_OPEN = re.compile(r"\[=*\[")
NAME_RE = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
NUM_RE = re.compile(r"0[xX][0-9a-fA-F]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?")
OPS = ("...", "..", "==", "~=", "<=", ">=")


class Tok:
    __slots__ = ("k", "s", "line", "col")

    def __init__(self, k, s, line, col):
        self.k, self.s, self.line, self.col = k, s, line, col

    def __repr__(self):
        return "%s:%r@%d:%d" % (self.k, self.s, self.line, self.col)


class BuildError(Exception):
    pass


def lex(src, where):
    toks = []
    i, n, line, col = 0, len(src), 1, 0
    while i < n:
        c = src[i]
        if c == "\n":
            j = i + 1
            k = "nl"
        elif c in " \t\r\f\v":
            j = i
            while j < n and src[j] in " \t\r\f\v":
                j += 1
            k = "ws"
        elif src.startswith("--", i):
            m = LONG_OPEN.match(src, i + 2)
            if m:
                close = "]" + "=" * (len(m.group(0)) - 2) + "]"
                j = src.find(close, m.end())
                if j < 0:
                    raise BuildError("%s:%d: a long comment never ends" % (where, line))
                j += len(close)
            else:
                j = src.find("\n", i)
                if j < 0:
                    j = n
            k = "com"
        elif c == "[" and LONG_OPEN.match(src, i):
            m = LONG_OPEN.match(src, i)
            close = "]" + "=" * (len(m.group(0)) - 2) + "]"
            j = src.find(close, m.end())
            if j < 0:
                raise BuildError("%s:%d: a long string never ends" % (where, line))
            j += len(close)
            k = "str"
        elif c in "\"'":
            j = i + 1
            while True:
                if j >= n or src[j] == "\n":
                    raise BuildError("%s:%d: a string never ends" % (where, line))
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == c:
                    j += 1
                    break
                j += 1
            k = "str"
        elif c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            j = NUM_RE.match(src, i).end()
            k = "num"
        elif c.isalpha() or c == "_":
            j = NAME_RE.match(src, i).end()
            k = "kw" if src[i:j] in KEYWORDS else "name"
        else:
            j = i + 1
            for op in OPS:
                if src.startswith(op, i):
                    j = i + len(op)
                    break
            k = "op"
        s = src[i:j]
        toks.append(Tok(k, s, line, col))
        nl = s.count("\n")
        if nl:
            line += nl
            col = len(s) - s.rfind("\n") - 1
        else:
            col += len(s)
        i = j
    return toks


def significant(toks):
    return [t for t in toks if t.k not in ("ws", "nl", "com")]


# ======================================================================================================================
# THE CHUNKS: a file's top-level statements. ZeD-GUI starts every top-level statement at column 0 and indents what
# goes on inside one, so a statement starts at a token in column 0 where the blocks and brackets are all closed.
# ======================================================================================================================
OPENERS = {"function", "if", "do", "repeat"}
CLOSERS = {"end", "until"}


class Chunk:
    def __init__(self, file, idx, toks):
        self.file, self.idx, self.toks = file, idx, toks
        self.sig = significant(toks)
        self.line = self.sig[0].line if self.sig else 0
        self.kind = "effect"
        self.defs = []          # keys it defines: ("local", name) or ("path", "ZeD.Atoms.x")
        self.refs = set()       # keys it names
        self.methods = set()    # member names read off something not resolved (self:foo, win.bar)
        self.cls = None         # the class path when it makes one (X = Y:derive(...))
        self.is_table = False   # X = X or {}: a module table
        self.override = False   # writes into a table or global of the game's
        self.alias = None       # local X = ZeD.Path at the top level: (X, "ZeD.Path")
        self.require = None

    def first_line(self):
        """The chunk's first line of code, comments left out (how OVERRIDES and ROOT_EFFECTS name a chunk)."""
        out, started = [], False
        for t in self.toks:
            if t.k in ("ws", "nl", "com") and not started:
                continue
            started = True
            if t.k == "nl":
                break
            if t.k != "com":
                out.append(t.s)
        return "".join(out).strip()


def split_chunks(file, toks):
    starts, last_sig_of = [], []
    depth = 0
    semicolon_line = None
    for i, t in enumerate(toks):
        if t.k in ("ws", "nl", "com"):
            continue
        if depth == 0 and (t.col == 0 or semicolon_line == t.line) and not (t.k == "kw" and t.s in ("end", "until", "else", "elseif")):
            starts.append(i)
            last_sig_of.append(i)
        elif last_sig_of:
            last_sig_of[-1] = i
        semicolon_line = None
        if t.k == "kw":
            if t.s in OPENERS:
                depth += 1
            elif t.s in CLOSERS:
                depth -= 1
        elif t.k == "op":
            if t.s in "([{":
                depth += 1
            elif t.s in ")]}":
                depth -= 1
            elif t.s == ";" and depth == 0:
                semicolon_line = t.line
        if depth < 0:
            raise BuildError("%s:%d: more closers than openers" % (file, t.line))
    if depth != 0:
        raise BuildError("%s: blocks left open at the end" % file)
    # each chunk runs from the end of the one before it to the end of its own last line (the comments and blank
    # lines before a statement are its own)
    chunks, lead = [], 0
    for n, last in enumerate(last_sig_of):
        end = last + 1
        while end < len(toks) and toks[end].k in ("ws", "com"):
            end += 1
        if end < len(toks) and toks[end].k == "nl":
            end += 1
        chunks.append(Chunk(file, n, toks[lead:end]))
        lead = end
    if chunks and lead < len(toks):
        chunks[-1].toks.extend(toks[lead:])
    return chunks


# ======================================================================================================================
# WHAT A CHUNK DEFINES AND NAMES
# ======================================================================================================================
def zed_root(name):
    return name == "ZeD" or name.startswith("ZeD_")


def read_path(S, j, allow_colon=True):
    """NAME(.NAME)*(:NAME)? from S[j]; returns (parts, next index) or (None, j)."""
    if j >= len(S) or S[j].k != "name":
        return None, j
    parts = [S[j].s]
    k = j + 1
    while k + 1 < len(S) and S[k].s == "." and S[k + 1].k == "name":
        parts.append(S[k + 1].s)
        k += 2
    if allow_colon and k + 1 < len(S) and S[k].s == ":" and S[k + 1].k == "name":
        parts.append(S[k + 1].s)
        k += 2
    return parts, k


def alias_of(rhs):
    """The ZeD path a local's value names: `ZeD.X.Y`, or the last path of `ZeD.X and ZeD.X.Y`; else None."""
    if not rhs:
        return None
    path, k = read_path(rhs, 0, allow_colon=False)
    if not path or not zed_root(path[0]):
        return None
    last = path
    while k < len(rhs) and rhs[k].s == "and":
        p2, k2 = read_path(rhs, k + 1, allow_colon=False)
        if not p2 or not zed_root(p2[0]):
            return None
        last, k = p2, k2
    if k != len(rhs):
        return None
    return ".".join(last)


def statement_end(S, j):
    """Index of the end of a `local X = <expr>` inside a function: the next token that starts another statement on
    a later line, or the end. Good enough for the alias forms ZeD-GUI writes (one line)."""
    line = S[j].line
    k = j
    while k < len(S) and S[k].line == line:
        k += 1
    return k


class FileInfo:
    def __init__(self, rel, whole):
        self.rel, self.whole = rel, whole
        self.path = os.path.join(SRC, rel.replace("/", os.sep))
        with open(self.path, encoding="utf-8") as f:
            self.src = f.read()
        self.aliases = {}
        self.locals = set()
        self.chunks = []


def apply_edits(rel, src):
    for f, old, new in EDITS:
        if f != rel:
            continue
        n = src.count(old)
        if n != 1:
            raise BuildError("edit for %s: %r found %d times (expected once): ZeD-GUI's file has changed, look at "
                             "the edit again" % (rel, old, n))
        src = src.replace(old, new)
    return src


def analyse_file(fi):
    fi.src = apply_edits(fi.rel, fi.src)
    toks = lex(fi.src, fi.rel)
    fi.chunks = split_chunks(fi.rel, toks)
    # pass 1: what each chunk defines; the file's locals and aliases
    for c in fi.chunks:
        S = c.sig
        if not S:
            c.kind = "blank"
            continue
        if S[0].s == "local" and len(S) > 2 and S[1].s == "function":
            c.kind = "local"
            c.defs.append(("local", S[2].s))
            fi.locals.add(S[2].s)
        elif S[0].s == "local":
            names, j = [], 1
            while j < len(S) and S[j].k == "name":
                names.append(S[j].s)
                j += 1
                if j < len(S) and S[j].s == ",":
                    j += 1
                    continue
                break
            c.kind = "local"
            for nm in names:
                c.defs.append(("local", nm))
                fi.locals.add(nm)
            if len(names) == 1 and j < len(S) and S[j].s == "=":
                a = alias_of(S[j + 1:])
                if a:
                    c.alias = (names[0], a)
                    fi.aliases[names[0]] = a
        elif S[0].s == "function":
            path, k = read_path(S, 1)
            c.kind = "func"
            c.target = path
            # function X:m(): X is a class, whatever made it (X = {} as well as X = Y:derive(...))
            c.colon = any(t.s == ":" for t in S[1:k])
        elif S[0].s == "require":
            c.kind = "require"
            c.require = S[1].s[1:-1] if len(S) > 1 and S[1].k == "str" else None
        elif S[0].s == "return":
            c.kind = "return"
        elif S[0].k == "name":
            # one or more targets (a, b.c = ...), then "="
            targets, j = [], 0
            while True:
                path, j = read_path(S, j, allow_colon=False)
                if not path:
                    break
                if j < len(S) and S[j].s == "[":
                    # an index write (t[k] = v): it fills the table t
                    depth, k = 0, j
                    while k < len(S):
                        if S[k].s == "[":
                            depth += 1
                        elif S[k].s == "]":
                            depth -= 1
                            if depth == 0:
                                break
                        k += 1
                    j = k + 1
                targets.append(path)
                if j < len(S) and S[j].s == ",":
                    j += 1
                    continue
                break
            if targets and j < len(S) and S[j].s == "=":
                c.kind = "assign"
                c.targets = targets
                rhs = S[j + 1:]
                if len(targets) == 1 and len(rhs) >= 3 and rhs[-2].s == "{" and rhs[-1].s == "}" and rhs[-3].s == "or":
                    c.is_table = True
                if any(t.s == "derive" for t in rhs) and len(targets) == 1 and len(targets[0]) == 1:
                    c.cls = targets[0][0]
            else:
                c.kind = "effect"
        else:
            c.kind = "effect"
        if c.kind == "func":
            c.targets = [c.target]
    # pass 2: canonical targets (aliases resolved) and the overrides
    for c in fi.chunks:
        if c.kind in ("func", "assign"):
            for path in c.targets:
                path = list(path)
                if path[0] in fi.aliases:
                    path = fi.aliases[path[0]].split(".") + path[1:]
                if zed_root(path[0]):
                    key = ".".join(path)
                    c.defs.append(("path", key))
                    if c.cls:
                        c.cls = key
                elif path[0] in fi.locals:
                    c.defs.append(("local", path[0]))
                else:
                    c.override = True
            if c.override:
                c.kind = "effect"
                c.defs = []
    # pass 3: what each chunk names
    for c in fi.chunks:
        collect_refs(c, fi)
    return fi


def bracket_inner(S):
    """For each token, the innermost bracket it sits in: "{", "(", "[" or None (a table field key is a name right
    inside "{" followed by "=", not a write)."""
    out, stack = [], []
    for t in S:
        out.append(stack[-1] if stack else None)
        if t.k == "op" and t.s in "({[":
            stack.append(t.s)
        elif t.k == "op" and t.s in ")}]" and stack:
            stack.pop()
        elif t.k == "kw" and t.s in OPENERS:
            stack.append("block")
        elif t.k == "kw" and t.s in CLOSERS and stack:
            stack.pop()
    return out


def collect_refs(c, fi):
    S = c.sig
    inner = bracket_inner(S)
    chunk_alias = {}
    for j in range(len(S) - 3):
        if S[j].s == "local" and S[j + 1].k == "name" and S[j + 2].s == "=":
            end = statement_end(S, j + 3)
            a = alias_of(S[j + 3:end])
            if a:
                chunk_alias[S[j + 1].s] = a
    # chunk-local declarations (for telling a write to the game's tables from a write to one of the chunk's own)
    own = set()
    for j in range(len(S)):
        if S[j].s == "local" and j + 1 < len(S) and S[j + 1].k == "name":
            k = j + 1
            while k < len(S) and S[k].k == "name":
                own.add(S[k].s)
                if k + 1 < len(S) and S[k + 1].s == ",":
                    k += 2
                else:
                    break
        if S[j].s == "function":
            k = j + 1
            while k < len(S) and S[k].s != "(":
                k += 1
            k += 1
            while k < len(S) and S[k].s != ")":
                if S[k].k == "name":
                    own.add(S[k].s)
                k += 1
        if S[j].s == "for":
            k = j + 1
            while k < len(S) and S[k].s not in ("=", "in"):
                if S[k].k == "name":
                    own.add(S[k].s)
                k += 1
    c.writes = set()
    j = 0
    while j < len(S):
        t = S[j]
        # a table field's key ({ win = win }): a name, not a reference
        if t.k == "name" and inner[j] == "{" and j + 1 < len(S) and S[j + 1].s == "=" and \
                (j == 0 or S[j - 1].s in ("{", ",", ";")):
            j += 1
            continue
        if t.k == "name" and not (j > 0 and S[j - 1].s in (".", ":")):
            chain, k = read_path(S, j, allow_colon=False)
            # a colon call after the dots: X.y:z(
            if k + 1 < len(S) and S[k].s == ":" and S[k + 1].k == "name":
                chain = chain + [S[k + 1].s]
                k += 2
            base = chain[0]
            root, key = None, None
            if base in chunk_alias and base not in fi.locals:
                root = chunk_alias[base].split(".")
            elif base in fi.aliases:
                root = fi.aliases[base].split(".")
                c.refs.add(("local", base))
            elif base in fi.locals and base not in own:
                key = ("local", base)
                c.refs.add(key)
            elif base in chunk_alias:
                root = chunk_alias[base].split(".")
            else:
                root = [base]
            full = None
            if root is not None:
                full = root + chain[1:]
                if zed_root(full[0]):
                    for m in range(1, len(full) + 1):
                        c.refs.add(("path", ".".join(full[:m])))
                    key = ("path", ".".join(full))
                elif len(chain) > 1:
                    c.methods.add(chain[1])
            # what the statement writes: X = ..., X.y = ..., X[k] = ... (a local of its own does not count)
            nxt = S[k].s if k < len(S) else ""
            if nxt == "[":
                depth, m = 0, k
                while m < len(S):
                    if S[m].s == "[":
                        depth += 1
                    elif S[m].s == "]":
                        depth -= 1
                        if depth == 0:
                            break
                    m += 1
                nxt = S[m + 1].s if m + 1 < len(S) else ""
            prev = S[j - 1].s if j > 0 else ""
            writes = nxt == "=" or prev == "function"
            if writes and base not in own and prev != "local" and key is not None:
                c.writes.add(key)
            # a write into the game's own tables or globals (an effect that does it is an override to decide)
            if c.kind == "effect" and writes and full is not None and not zed_root(full[0]) and base not in own \
                    and base not in fi.locals and prev != "local" and base != "Events":
                c.override = True
            j = k
            continue
        j += 1


# ======================================================================================================================
# THE CLOSURE: from the console's files, everything they reach, as long as it is in SUPPORT and not LEFT_OUT
# ======================================================================================================================
def left_out(key):
    if key[0] != "path":
        return None
    p = key[1]
    for pre, why in LEFT_OUT.items():
        if p == pre or p.startswith(pre + "."):
            return pre
    return None


class Closure:
    def __init__(self, files):
        self.files = files
        self.by_rel = {f.rel: f for f in files}
        self.index = {}     # key -> [chunk]
        self.classes = {}   # class path -> [method chunks]
        for f in files:
            for c in f.chunks:
                for d in c.defs:
                    if d[0] == "local":
                        key = ("local", f.rel, d[1])
                    else:
                        key = d
                    self.index.setdefault(key, []).append(c)
                if c.kind == "func":
                    path = c.defs[0][1] if c.defs and c.defs[0][0] == "path" else None
                    if path and "." in path:
                        cls, _, meth = path.rpartition(".")
                        self.classes.setdefault(cls, {}).setdefault(meth, []).append(c)
        self.included = set()
        self.reasons = {}
        self.needed = set()
        self.methods = set(ENGINE_CALLBACKS)
        self.class_paths = set()
        for f in files:
            for c in f.chunks:
                if c.cls:
                    self.class_paths.add(c.cls)
                if c.kind == "func" and getattr(c, "colon", False) and c.defs and c.defs[0][0] == "path":
                    self.class_paths.add(c.defs[0][1].rpartition(".")[0])
        # a class's metamethods (X.__index = X) come with it: nothing names them, the lookups need them
        for cls in self.class_paths:
            for m in ("__index", "__newindex", "__call", "__tostring", "__eq", "__lt", "__le"):
                for d in self.index.get(("path", cls + "." + m), []):
                    self.classes.setdefault(cls, {}).setdefault(m, []).append(d)
        self.methods |= {"__index", "__newindex", "__call", "__tostring", "__eq", "__lt", "__le"}
        self.missing = {}   # key -> [where]
        self.left = {}      # left-out prefix -> [where]

    def key_of(self, c, ref):
        if ref[0] == "local":
            return ("local", c.file, ref[1])
        return ref

    def add(self, c, why, work):
        if id(c) in self.included:
            return
        self.included.add(id(c))
        self.reasons[id(c)] = why
        work.append(c)

    def run(self):
        work = []
        for f in self.files:
            if f.whole:
                for c in f.chunks:
                    self.add(c, "the console's own file", work)
        for rel, first in ROOT_EFFECTS:
            for c in self.by_rel[rel].chunks:
                if c.first_line().startswith(first):
                    self.add(c, "kept on purpose", work)
                    break
            else:
                raise BuildError("root effect not found in %s: %s" % (rel, first))
        while True:
            while work:
                c = work.pop()
                where = "%s:%d" % (c.file, c.line)
                for ref in sorted(c.refs):
                    key = self.key_of(c, ref)
                    lo = left_out(key)
                    if lo:
                        self.left.setdefault(lo, set()).add(where)
                        continue
                    if key in self.needed:
                        continue
                    self.needed.add(key)
                    defs = self.index.get(key)
                    if defs:
                        for d in defs:
                            self.add(d, "named by %s" % where, work)
                    elif key[0] == "path":
                        self.missing.setdefault(key[1], set()).add(where)
                for m in sorted(c.methods):
                    if m not in self.methods:
                        self.methods.add(m)
                        for cls in self.class_paths:
                            if ("path", cls) in self.needed:
                                for d in self.classes.get(cls, {}).get(m, []):
                                    self.add(d, "method %s, called on some %s" % (m, where), work)
                # a class taken: its methods the closure calls, and the engine's
                for d in c.defs:
                    if d[0] == "path" and d[1] in self.class_paths:
                        for m, cs in self.classes.get(d[1], {}).items():
                            if m in self.methods:
                                for x in cs:
                                    self.add(x, "method of class %s" % d[1], work)
                # a path needed whose class was taken already: (handled by the index)
            if not self.sweep_effects(work):
                break
        return self

    def defined_keys(self):
        """What the taken chunks define, less the module tables and their aliases (every statement of a module
        names those: touching one says nothing about what the statement is for)."""
        out = set()
        for f in self.files:
            for c in f.chunks:
                if id(c) in self.included and not c.is_table and not c.alias:
                    for d in c.defs:
                        out.add(("local", f.rel, d[1]) if d[0] == "local" else d)
        return out

    def sweep_effects(self, work):
        """Effects that write into what is taken come along (data filled at load: the focus hand's runs, a table of
        letters). The game's own tables and globals written by one need a decision in OVERRIDES."""
        have = self.defined_keys()
        have.discard(("path", "ZeD"))
        added = False
        for f in self.files:
            if f.whole or not any(id(c) in self.included for c in f.chunks):
                continue
            for c in f.chunks:
                if id(c) in self.included or c.kind not in ("effect",):
                    continue
                touched = {self.key_of(c, w) for w in c.writes} & have
                if c.override:
                    touched |= {self.key_of(c, r) for r in c.refs} & have
                if not touched:
                    continue
                if c.override:
                    decision = None
                    for (rel, first), d in OVERRIDES.items():
                        if rel == f.rel and c.first_line().startswith(first):
                            decision = d
                    if decision is None:
                        raise BuildError("%s:%d writes into the game's own tables and touches the closure (%s); "
                                         "decide it in OVERRIDES: %s" % (f.rel, c.line, sorted(touched)[0],
                                                                         c.first_line()))
                    if decision == "drop":
                        continue
                self.add(c, "an effect on %s" % (sorted(touched)[0][-1],), work)
                added = True
        return added

    def is_in(self, c):
        return id(c) in self.included


# ======================================================================================================================
# THE RENAMES
# ======================================================================================================================
# "zed" as a part of a name: _zedHome, zedDrawsText (lower case, at the start or after "_"), slotIsZedAtlas (a
# capital in camel case), ZED_BASE (all capitals). "resized" and "initialized" are words, not parts, and stay.
PART_RES = [
    (re.compile(r"(?:(?<=^)|(?<=_))zed(?=$|_|[A-Z0-9])"), TABLE.lower()),
    (re.compile(r"(?:(?<=^)|(?<=_)|(?<=[a-z0-9]))Zed(?=$|_|[A-Z0-9])"), TABLE[0].upper() + TABLE[1:].lower()),
    (re.compile(r"(?:(?<=^)|(?<=_))ZED(?=$|_|[A-Z0-9])"), TABLE.upper()),
]


def rename_ident(name):
    if "ZeD" in name:
        name = name.replace("ZeD", TABLE)
    for rx, new in PART_RES:
        name = rx.sub(new, name)
    return name


def zed_parts(name):
    """The parts of a name that still say zed (the check after the renames)."""
    out = []
    if "ZeD" in name:
        out.append("ZeD")
    for rx, _ in PART_RES:
        out += rx.findall(name)
    return out


def rename_string(s):
    for old, new in STRING_RULES:
        s = s.replace(old, new)
    return s


def file_name_of(rel):
    base = os.path.basename(rel)
    if base.startswith("ZeD_"):
        base = TABLE + "_" + base[4:]
    return base


def module_of(rel):
    return file_name_of(rel)[:-4]


def emit_tokens(toks):
    """Tokens back to text with the comments taken out and every name and string renamed. A line that held only a
    comment goes; blank lines stay (runs of them become one)."""
    buf = []
    line = []
    had_comment = False
    for t in toks:
        if t.k == "nl":
            text = "".join(line).rstrip()
            if text or not had_comment:
                buf.append(text)
            line, had_comment = [], False
            continue
        if t.k == "com":
            had_comment = True
            if "\n" in t.s:
                # a long comment over several lines: the line it starts on ends here
                text = "".join(line).rstrip()
                if text:
                    buf.append(text)
                line = []
            else:
                line.append(" ")
            continue
        if t.k == "name":
            line.append(rename_ident(t.s))
        elif t.k == "str":
            line.append(rename_string(t.s))
        else:
            line.append(t.s)
    if line:
        text = "".join(line).rstrip()
        if text or not had_comment:
            buf.append(text)
    return buf


def collapse_blanks(lines):
    out = []
    for l in lines:
        if l == "" and (not out or out[-1] == ""):
            continue
        out.append(l)
    while out and out[-1] == "":
        out.pop()
    return out


# ======================================================================================================================
# THE LUA THIS TOOL WRITES ITSELF: the header and guard every file starts with, and the stand-ins for ZeD-GUI's parts
# ======================================================================================================================
BANNER = "-- " + "=" * 108
GUARD_LOG = 'print("[%s] %s is on: its console is used") ' % (SHORT, ZED_NAME)
GUARD_LINES = [
    "-- With %s on (mod %s; the game can put a backslash before a mod's id), %s's console is the one:" % (ZED_NAME, ZED_MOD_ID, ZED_NAME),
    "-- this file stops here and defines nothing.",
    "do",
    "    local guiOn = false",
    "    pcall(function()",
    "        local mods = getActivatedMods()",
    "        for i = 0, mods:size() - 1 do",
    '            if string.gsub(tostring(mods:get(i)), "^\\\\", "") == "%s" then guiOn = true end' % ZED_MOD_ID,
    "        end",
    "    end)",
    "    if guiOn then %sreturn end",
    "end",
]
# the strings the guard holds: the only places ZeD-GUI is named in code
GUARD_STRINGS = {'"%s"' % ZED_MOD_ID, '"[%s] %s is on: its console is used"' % (SHORT, ZED_NAME)}
# the one file that says so in the log
GUARD_LOGS_IN = TABLE + "_DebugConsole.lua"


def guard(file_name):
    lines = list(GUARD_LINES)
    lines[-2] = lines[-2] % (GUARD_LOG if file_name == GUARD_LOGS_IN else "")
    return lines


def comment_wrap(text, width=110):
    out, line = [], "--"
    for word in text.split():
        if len(line) + 1 + len(word) > width and line != "--":
            out.append(line)
            line = "--"
        line += " " + word
    out.append(line)
    return out


def header(file_name, what, source=None):
    lines = ["-- %s/42/media/lua/client/%s/%s" % (MOD_ID, MOD_ID, file_name), BANNER]
    lines += comment_wrap("%s %s: %s" % (NAME, VERSION, what))
    if source:
        lines += comment_wrap("Made from %s's %s by ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: "
                              "change %s's file and build again." % (ZED_NAME, source, ZED_NAME))
    else:
        lines += comment_wrap("Written by ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change the "
                              "tool and build again.")
    lines.append(BANNER)
    return lines


# what each file is, for its header
ROLES = {
    "client/ZeD/ZeD_DebugConsole.lua": "the console: the window over the game's own console, its Log page, the line and the scratchpad.",
    "client/ZeD/ZeD_ConsoleLog.lua": "the Log page's rows: the game's console box and the F11 error list as one list.",
    "client/ZeD/ZeD_ConsoleScratch.lua": "the scratchpad: running a box of many lines, its snippets and history on disk.",
    "client/ZeD/ZeD_ConsoleComplete.lua": "the suggestions: what can follow the word at the caret.",
    "client/ZeD/ZeD_ConsolePages.lua": "the Help and Commands pages.",
    "client/ZeD/ZeD_ConsoleCommands.lua": "the server command list, who may use each, and sending one.",
}

# The game's code face (media/fonts/codeSmall.fnt, Noto Sans Mono, every size) holds the characters 32 to 126 and
# 160 to 255 (the soft hyphen, 173, aside); anything past them it draws as "?". A language whose words all fit keeps
# the data role on it; the build fills the list in where the text shim marks it.
CODE_LANGS_MARK = "@CODE_LANGS@"


def code_face_has(text):
    return all(32 <= ord(c) <= 126 or (160 <= ord(c) <= 255 and ord(c) != 173) or c in "\n\t" for c in text)


T_ = {"T": TABLE, "MOD": MOD_ID, "KEY": KEY_PREFIX, "SLICE": SLICE_TEX, "tl": TABLE.lower()}

TEXT_SHIM = """
%(T)s = %(T)s or {}
%(T)s.Text = %(T)s.Text or {}
local X = %(T)s.Text

-- the game's face for each role: F1 chrome, F2 body, F3 data (fixed pitch: the log's columns and the caret are counted
-- in its character width), F4 heading, F5 micro
X.ROLE_FONTS = { "Small", "Small", "CodeSmall", "Medium", "Small" }

-- The languages whose words the code face draws: the game's codeSmall.fnt holds the first 256 characters only, so a
-- language with letters past them (Cyrillic, CJK, Thai, Polish, Turkish, German quotes) gets the data role in its own
-- Small face, which the game picks by language. Worked out by the build from each language's words here.
X.CODE_LANGS = { @CODE_LANGS@ }

local function langName() return tostring(Translator.getLanguage():name()) end

--- True when the game's language is one the code face draws (or the language cannot be read).
function X.codeFaceFits()
    local ok, name = pcall(langName)
    if not ok or type(name) ~= "string" then return true end
    return X.CODE_LANGS[name] == true
end

--- True: the roles draw in the game's own fonts (the palette then asks roleFallbackFont for each one).
function X.checkRoleFonts() return true end

--- The game's font for role i (1 to 5). px, the role's design size, is not needed: the game's faces come in the
--- size its font size option picks.
function X.roleFallbackFont(px, i)
    local name = X.ROLE_FONTS[i or 2] or "Small"
    if name == "CodeSmall" and not X.codeFaceFits() then name = "Small" end
    return UIFont[name] or UIFont.Small
end

-- The kept measures: two generations of MAX strings. They start over whenever a width could differ: a new palette
-- (theme, scale), another root scale, another language, the game's font size option (it loads other faces).
local MAX = 3000
local M = { T = false, root = false, gen = false, fs = false, x = {}, xOld = {}, h = {}, n = 0, epoch = 0 }
local fsNow = false

local function settle()
    local root = (%(T)s.Scale and %(T)s.Scale._root) or false
    if M.T ~= %(T)s.T or M.root ~= root or M.gen ~= %(T)s._trGen or M.fs ~= fsNow then
        M.T, M.root, M.gen, M.fs = %(T)s.T, root, %(T)s._trGen, fsNow
        M.x, M.xOld, M.h, M.n = {}, {}, {}, 0
        M.epoch = M.epoch + 1
    end
end

--- A number that changes whenever the kept measures start over (the atoms keep their wraps and cuts by it).
function X.measureEpoch()
    settle()
    return M.epoch
end

--- measureEpoch, for kept words
function X.wordsEpoch() return X.measureEpoch() * 2 end

%(T)s.TM = %(T)s.TM or {}
local TM = %(T)s.TM

--- A string's width in screen px, kept.
function TM:MeasureStringX(font, str)
    if type(str) ~= "string" then str = tostring(str) end
    if font == nil then return getTextManager():MeasureStringX(font, str) end
    settle()
    local byF = M.x[font]
    if byF then
        local v = byF[str]
        if v then return v end
    else
        byF = {}
        M.x[font] = byF
    end
    local old = M.xOld[font]
    local v = old and old[str]
    if not v then v = getTextManager():MeasureStringX(font, str) end
    if M.n >= MAX then
        M.xOld, M.x, M.n = M.x, {}, 0
        byF = {}
        M.x[font] = byF
    end
    byF[str] = v
    M.n = M.n + 1
    return v
end

--- A string's height in screen px (not kept).
function TM:MeasureStringY(font, str) return getTextManager():MeasureStringY(font, tostring(str)) end

--- A font's line height in screen px, kept.
function TM:getFontHeight(font)
    if font == nil then return getTextManager():getFontHeight(font) end
    settle()
    local v = M.h[font]
    if not v then
        v = getTextManager():getFontHeight(font)
        M.h[font] = v
    end
    return v
end

-- any other method of the game's text manager passes through, wrapped once
setmetatable(TM, { __index = function(t, k)
    local v = getTextManager()[k]
    if type(v) ~= "function" then return v end
    local wrapper = function(_, ...) local real = getTextManager(); return real[k](real, ...) end
    rawset(t, k, wrapper)
    return wrapper
end })

-- the game's font size option, read once a frame while the console can open (debug mode); one function made at
-- load, never one a frame. A new screen size starts the measures over.
local function readFontSize() return getCore():getOptionFontSize() end
local function onPreUIDraw()
    local ok, v = pcall(readFontSize)
    fsNow = ok and v or false
end
X._onPreUIDraw = onPreUIDraw
if Events then
    if Events.OnPreUIDraw and isDebugEnabled and isDebugEnabled() then Events.OnPreUIDraw.Add(onPreUIDraw) end
    if Events.OnResolutionChange then Events.OnResolutionChange.Add(function() M.T = false end) end
end
""" % T_

STANDALONE_SHIM = """
require "%(MOD)s/Organisms"
require "%(MOD)s/%(T)s_DebugConsole"

%(T)s = %(T)s or {}

-- THE PAD KEYBOARD: the game's own on-screen keyboard (OnScreenKeyboard). The console shows it with
-- OnScreenKeyboard.Show, asks here whether it is still up, and on closing puts it away when it types into one of the
-- console's boxes (instance.textEntryBox).
%(T)s.Keyboard = %(T)s.Keyboard or {}
local KB = %(T)s.Keyboard

--- True while the game's on-screen keyboard is up.
function KB.isVisible()
    return OnScreenKeyboard ~= nil and OnScreenKeyboard.IsVisible ~= nil and OnScreenKeyboard.IsVisible() == true
end

-- KB.instance: the game's keyboard while it is up, nil once it is put away. The game's keeps its textEntryBox after
-- it hides, and its hide() gives that box the keys again; the console closing would then leave its own hidden line
-- holding every key. So the console sees only a keyboard that is up, and putting it away leaves the box unfocused,
-- as ZeD-GUI's keyboard does.
local proxy = {}
function proxy.hide()
    local inst = OnScreenKeyboard and OnScreenKeyboard.instance
    if not inst then return end
    local box = inst.textEntryBox
    pcall(function() inst:hide() end)
    if box and box.unfocus then pcall(function() box:unfocus() end) end
end
setmetatable(KB, { __index = function(_, k)
    if k == "instance" and KB.isVisible() then
        proxy.textEntryBox = OnScreenKeyboard.instance and OnScreenKeyboard.instance.textEntryBox
        return proxy
    end
    return nil
end })

-- The game's keyboard's Accept (and RT) put the words in the box, hide, give the box the keys, then press Enter for
-- it (ISOnScreenKeyboard:KeyFunction_Enter queues KEY_RETURN). ZeD-GUI's keyboard only puts the words in: the console
-- then lands the controller on Run or Send, and A runs it. So the Enter that follows an Accept into one of the
-- console's boxes is let go here (within ACCEPT_MS of the Accept), and the box lets the keys go with it.
local ACCEPT_MS = 500
local function acceptRecorded(o)
    KB._acceptAt, KB._acceptBox = getTimestampMs(), o and o.textEntryBox
end
local function wrapAccept(osk)
    if type(osk) ~= "table" or osk._%(tl)sAccept then return end
    local orig = osk.accept
    if type(orig) ~= "function" then return end
    osk._%(tl)sAccept = orig
    osk.accept = function(o, ...)
        if o and o.textEntryBox and o.textEntryBox._%(tl)sEnter then acceptRecorded(o) end
        return orig(o, ...)
    end
end
--- True (once) when an Enter into box is the one the game's keyboard pressed after its Accept.
function KB.acceptEnter(box)
    if KB._acceptBox ~= box or not KB._acceptAt then return false end
    local now = getTimestampMs()
    KB._acceptBox = nil
    return now - KB._acceptAt <= ACCEPT_MS
end
local function wrapEnter(box)
    if type(box) ~= "table" or box._%(tl)sEnter then return end
    box._%(tl)sEnter = true
    local orig = box.onCommandEntered
    box.onCommandEntered = function(...)
        if KB.acceptEnter(box) then
            pcall(function() box:unfocus() end)
            return
        end
        if type(orig) == "function" then return orig(...) end
    end
end
local W = %(T)s_DebugConsoleWindow
if W and W.openKeyboard and not W._%(tl)sKbWrapped then
    W._%(tl)sKbWrapped = true
    local origOpen = W.openKeyboard
    function W:openKeyboard(jd, entry)
        entry = entry or self.input
        wrapEnter(entry)
        local r = origOpen(self, jd, entry)
        if self._kbOpen then wrapAccept(OnScreenKeyboard and OnScreenKeyboard.instance) end
        return r
    end
end

-- THE CHAT: a chat channel's line (/all, /say, /yell, /whisper, /faction, /safehouse, /admin) from the Commands page
-- goes through the game's own chat box (ISChat), which knows each channel's tab, its slow mode and its rules. The
-- game's chat drops a line without a word back in two cases: slow mode, and a channel of another tab than the one
-- the chat shows (it says so in the chat). Those are told here before the chat is asked, so the page never says Sent
-- for a line that went nowhere.
%(T)s.Chat = %(T)s.Chat or {}

local function streamOf(text)
    for _, s in ipairs(ISChat.allChatStreams or {}) do
        if (s.command and string.sub(text, 1, #s.command) == s.command)
            or (s.shortCommand and string.sub(text, 1, #s.shortCommand) == s.shortCommand) then return s end
    end
    return nil
end
local function ignoresSlowMode()
    local ok, yes = pcall(function() return getPlayer():getRole():hasCapability(Capability.IgnoreChatSlowMode) end)
    return ok and yes == true
end

--- Send a chat channel's line as the game's chat does. True when the chat sent it; false and why ("slow", "tab")
--- when it would not have.
function %(T)s.Chat.send(text)
    local chat = ISChat and ISChat.instance
    if not (chat and chat.textEntry and ISChat.onCommandEntered) then return false end
    text = tostring(text or "")
    if not ignoresSlowMode() and type(chat.timerMessageSlowMode) == "number" and chat.timerMessageSlowMode > getTimestampMs() then
        return false, "slow"
    end
    local stream = streamOf(text)
    if stream and stream.tabID and chat.currentTabID and stream.tabID ~= chat.currentTabID then return false, "tab" end
    local ok = pcall(function()
        chat.textEntry:setText(text)
        ISChat.onCommandEntered(chat)
    end)
    pcall(function() chat.textEntry:setText("") end)
    return ok
end

-- THE BORDERS: the game draws a border one screen pixel thick at any scale. The console's window and its overlay
-- draw theirs one design unit thick (T.px(1): two pixels at 4K), as four rects, so a border scales like everything
-- else; only these two classes, the game's own elements keep the game's call.
local function scaledBorder(self, x, y, w, h, a, r, g, b)
    local T = %(T)s.T
    local t = (T and T.px) and T.px(1) or 1
    if t <= 1 then return ISUIElement.drawRectBorder(self, x, y, w, h, a, r, g, b) end
    if w <= 0 or h <= 0 then return end
    if w <= 2 * t or h <= 2 * t then return self:drawRect(x, y, w, h, a, r, g, b) end
    self:drawRect(x, y, w, t, a, r, g, b)
    self:drawRect(x, y + h - t, w, t, a, r, g, b)
    self:drawRect(x, y + t, t, h - 2 * t, a, r, g, b)
    self:drawRect(x + w - t, y + t, t, h - 2 * t, a, r, g, b)
end
%(T)s.scaledBorder = scaledBorder
if %(T)s_Window then %(T)s_Window.drawRectBorder = scaledBorder end
if %(T)s_WindowOverlay then %(T)s_WindowOverlay.drawRectBorder = scaledBorder end
""" % T_

PAD_ENTRY = """
require "ISUI/ISBackButtonWheel"

%(T)s = %(T)s or {}

-- In debug mode, with the game's console made, the game's Back button wheel (ISBackButtonWheel) gets one more slice:
-- the console, opened with the controller in it, as the wheel's own slices open their windows. The keyboard's way in
-- is the game's own key. Keep the game's addCommands once, so a Lua reload never wraps the wrapper.
-- While the game is paused the slice is left off, as the game leaves off its own window slices (Player Info,
-- Crafting): a paused game drops every button but the D-pad for a window holding the controller
-- (JoypadControllerData:onPressButton), so the console could be neither typed in nor closed.
local function paused()
    local ok, yes = pcall(function()
        local sc = UIManager.getSpeedControls and UIManager.getSpeedControls()
        if sc and sc:getCurrentGameSpeed() == 0 then return true end
        return isGamePaused ~= nil and isGamePaused() == true
    end)
    return ok and yes == true
end
local function consoleHere()
    local DC = %(T)s.DebugConsole
    return DC and DC.exists and DC.exists()
end
if ISBackButtonWheel and not ISBackButtonWheel._%(tl)sOrig then
    ISBackButtonWheel._%(tl)sOrig = ISBackButtonWheel.addCommands
    function ISBackButtonWheel:addCommands()
        ISBackButtonWheel._%(tl)sOrig(self)
        local DC = %(T)s.DebugConsole
        local ok, here = pcall(consoleHere)
        if ok and here and not paused() then
            local pn = self.playerNum
            self:addSlice(%(T)s.tr("%(KEY)sConsole_Title"), getTexture("%(SLICE)s"), function() DC.open(pn) end)
        end
    end
end
""" % T_

TEMPLATES = [
    (TABLE + "_Text.lua", "the text: the game's own fonts for every role, and its text manager with the measures "
     "kept. It stands in for ZeD-GUI's Scale.lua text layer, which draws in Fira by replacing the game's font list. "
     "The palette (Tokens.lua) loads it first: it measures the font heights as it is made.", TEXT_SHIM),
    (TABLE + "_Standalone.lua", "the game's own pad keyboard and chat where ZeD-GUI has its own, and the window's "
     "borders one design unit thick (ZeD-GUI's TextScale.lua does that for all its classes).", STANDALONE_SHIM),
    (TABLE + "_PadEntry.lua", "the controller's way in: a slice on the game's Back button wheel, where ZeD-GUI has "
     "a slice on its own wheel.", PAD_ENTRY),
]
# files the palette needs before it is made (Tokens.lua makes it as it loads)
EXTRA_REQUIRES = {"shared/ZeD/Tokens.lua": [TABLE + "_Text", "Scale"]}


# ======================================================================================================================
# WRITING THE LUA
# ======================================================================================================================
def lua_files(files, cl):
    emitted = {f.rel: module_of(f.rel) for f in files if f.whole or any(cl.is_in(c) for c in f.chunks)}
    out = {}
    for f in files:
        if f.rel not in emitted:
            continue
        name = file_name_of(f.rel)
        if f.whole:
            what = ROLES.get(f.rel, "part of the console.")
        else:
            n_in = sum(1 for c in f.chunks if cl.is_in(c) and c.kind != "require")
            n_all = sum(1 for c in f.chunks if c.kind not in ("require", "blank"))
            what = "the parts of %s's %s the console uses (%d of its %d statements)." % (ZED_NAME, os.path.basename(f.rel), n_in, n_all)
        lines = header(name, what, f.rel.replace("client/ZeD/", "42/media/lua/client/ZeD/").replace("shared/ZeD/", "42/media/lua/shared/ZeD/"))
        lines.append("")
        lines += guard(name)
        lines.append("")
        body = []
        for c in f.chunks:
            if c.kind == "require":
                target = c.require or ""
                # a require of ZeD-GUI's goes only where that file is written here too
                if target.startswith("ZeD/") and module_of(target[4:] + ".lua") not in emitted.values():
                    continue
                body.append(emit_tokens(c.toks))
                continue
            if f.whole or cl.is_in(c):
                body.append(emit_tokens(c.toks))
        # the requires first, then the extra ones this file needs here
        flat = []
        for b in body:
            flat += b
        flat = collapse_blanks(flat)
        extra = EXTRA_REQUIRES.get(f.rel)
        if extra:
            reqs = ['require "%s/%s"' % (MOD_ID, m) for m in extra]
            # after the file's own requires, before its first statement
            at = 0
            for i, l in enumerate(flat):
                if l.startswith("require "):
                    at = i + 1
            flat = flat[:at] + reqs + [""] + flat[at:]
        lines += flat
        out[name] = "\n".join(lines) + "\n"
    for name, what, body in TEMPLATES:
        lines = header(name, what) + [""] + guard(name) + body.rstrip("\n").split("\n")
        out[name] = "\n".join(lines) + "\n"
    return out


# ======================================================================================================================
# THE TRANSLATIONS: the keys the Lua uses, renamed, in every language ZeD-GUI ships
# ======================================================================================================================
def keys_used(lua):
    keys, prefixes = set(), set()
    for name, text in lua.items():
        for t in lex(text, name):
            if t.k == "str" and t.s[:1] in "\"'":
                v = t.s[1:-1]
                if re.fullmatch(re.escape(KEY_PREFIX) + r"[A-Za-z0-9_]+", v):
                    keys.add(v)
                elif v.startswith(KEY_PREFIX) and v != KEY_PREFIX:   # (the prefix alone: the commands' "is it ours")
                    prefixes.add(v)
    return keys, prefixes


def translations(keys):
    langs = sorted(d for d in os.listdir(TRANSLATE) if os.path.isfile(os.path.join(TRANSLATE, d, "UI.json")))
    src = {}
    for lang in langs:
        with open(os.path.join(TRANSLATE, lang, "UI.json"), encoding="utf-8") as fh:
            src[lang] = json.load(fh)
    out, problems = {}, []
    for lang in langs:
        table = {}
        for k in sorted(keys):
            zk = "UI_ZeD_" + k[len(KEY_PREFIX):]
            if k == KEY_PREFIX + "Console_Title":
                v = SHORT   # the product's name: the same in every language
            else:
                v = src[lang].get(zk)
                if v is None:
                    v = src["EN"].get(zk)
                if v is None:
                    problems.append("%s: no English for %s" % (lang, zk))
                    continue
            for old, new in VALUE_RULES.get(zk, []):
                v = v.replace(old, new)
            for old, new in FILE_RULES:
                v = v.replace(old, new)
            if "ZeD" in v:
                problems.append("%s %s still names ZeD: %s" % (lang, k, v))
            table[k] = v
        out[lang] = json.dumps(table, ensure_ascii=False, indent=4) + "\n"
    return out, problems, langs


# ======================================================================================================================
# THE PICTURES: design's box art, copied as it is (ZeDUI/art/lua_console_93/, HANDOFF_design_lua_console_93_box_20261112)
# ======================================================================================================================
# Read at build time, so a re-export by design reaches the mod with no other step. The icon is the controller wheel's
# slice too (the director approved it, Nov 12 2026).
ART_FILES = {
    "workshop/preview.png": "preview.png",
    "42/poster.png": "poster.png",
    "42/icon.png": "icon.png",
    TEX_DIR_REL + "/console_slice.png": "icon.png",
}


def art():
    out = {}
    for rel, name in ART_FILES.items():
        p = os.path.join(ART_DIR, name)
        if not os.path.isfile(p):
            raise BuildError("the art is missing: %s (design exports it into ZeDUI/art/lua_console_93/)" % name)
        with open(p, "rb") as fh:
            out[rel] = fh.read()
    return out


# ======================================================================================================================
# THE WORDS: mod.info, the README, the Workshop page and its gallery list
# ======================================================================================================================
def zed_mod_info():
    out = {}
    with open(ZED_MOD_INFO, encoding="utf-8") as fh:
        for line in fh:
            k, _, v = line.rstrip("\r\n").partition("=")
            out[k.strip()] = v.strip()
    return out


DESCRIPTION = ("A Lua console for mod makers, in debug mode (-debug): the game's own console as a window, with its "
               "log filtered by kind, mod and file, a scratchpad, suggestions as you type and the server command list. "
               "Works on the plain game. With %s on, %s's console is used." % (ZED_NAME, ZED_NAME))


def mod_info_text(zed):
    lines = [
        "name=" + NAME,
        "id=" + MOD_ID,
        "description=" + DESCRIPTION,
        "modversion=" + VERSION,
        "versionMin=" + zed.get("versionMin", "42.17.0"),
        "author=" + zed.get("author", ""),
        "url=",
        "poster=poster.png",
        "icon=icon.png",
    ]
    return "\n".join(lines) + "\n"


def readme_text(zed, langs):
    return """%(NAME)s %(VERSION)s
A Lua console for Project Zomboid Build 42, for mod makers. Debug mode only.

WHAT IT IS
The game's own Lua console (the one -debug gives you) as a window you can work in. The game's
console still runs everything: this mod is the window over it. Close the window and the game's
console is closed too.

OPENING IT
Start the game with -debug. In a game, press the game's console key (Toggle Lua Console in the
key options). With a controller, hold the Back button: the wheel has a %(SHORT)s slice
(not while the game is paused). Close it with the same key, with B on a controller, or with its
close box.

WHAT IT DOES
- Log: everything the game prints in debug mode and the F11 Lua Debugger's errors, one row each.
  Filter by kind (print, warning, error, ran here), by mod and by file, and search. A repeated
  error is one row with a count; click an error to open its whole stack. Export writes what the
  filters show to a new .log file; Copy copies it.
- The line: type Lua and press Enter, and it runs through the game's own console. Up and Down
  step through what you ran.
- Scratchpad: many lines, past the game's 256 characters. Enter runs it, Shift+Enter makes a new
  line. Save what you write as snippets; your last runs are kept as history.
- Suggestions: globals after two letters, a table's fields after a dot, an object's methods
  after a colon, Java methods marked Java. Tab or Enter takes one.
- Commands: every server command with its syntax, an example and the role it needs. On a server
  only the ones your role may use; a click fills the line and Send sends it. In single player
  each one points at the debug menu's own way of doing it.
- Help: what runs where, the keys, the controller and the files, in the window.

FILES (in Zomboid/Lua)
- %(MOD)s_<date>_<time>.log: each Export.
- %(MOD)s_snippets.txt: your snippets (a plain text file: edit it freely).
- %(MOD)s_history.txt: your last runs.
- %(MOD)s_off.txt: make an empty file of this name and the game's own console is used instead,
  from the next game start.

WITH %(ZED_UP)s
%(ZED)s has this console built in. With %(ZED)s on, %(SHORT)s steps aside and %(ZED)s's
console is used; nothing to set. You do not need %(ZED)s for %(SHORT)s.

LOOK
Dark, with the PZ Teal accent, in the game's own fonts. The window grows with the screen and the
game's font size option. Its text is in the %(N)d languages the game ships.

CREDITS
Made from %(ZED)s's Lua console by %(AUTHOR)s. %(ZED)s's source-available license covers it:
LICENSE.txt beside this file, and %(LICENSE_URL)s
""" % {"NAME": NAME, "VERSION": VERSION, "SHORT": SHORT, "MOD": MOD_ID, "ZED": ZED_NAME, "ZED_UP": ZED_NAME.upper(),
       "AUTHOR": zed.get("author", ""), "N": len(langs), "LICENSE_URL": LICENSE_URL}


def workshop_text(zed, langs):
    return """[h1]%(NAME)s[/h1]
A Lua console for Project Zomboid Build 42, made for mod makers. Version %(VERSION)s.

The game's own Lua console, the one debug mode gives you, as a window you can work in: the log filtered and searched, a scratchpad of many lines, suggestions as you type, and every server command with its syntax and the role it needs. The game's console still runs everything; this mod is the window over it.

[h2]Before you subscribe[/h2]
[list]
[*][b]Debug mode only.[/b] Start the game with -debug. Without it there is no console, and %(SHORT)s does nothing.
[*][b]Build 42.[/b] It does not run on Build 41.
[*][b]Works on the plain game.[/b] You do not need %(ZED)s or any other mod.
[*][b]With [url=%(ZED_URL)s]%(ZED)s[/url] on,[/b] %(ZED)s's own console (this same console) is used and %(SHORT)s steps aside. Nothing to set.
[*][b]Nothing in your save.[/b] It is interface only: add it or remove it at any time.
[/list]

[h2]Opening it[/h2]
Press the game's console key (Toggle Lua Console in the key options). With a controller, hold the Back button: the wheel has a %(SHORT)s slice (not while the game is paused). Close it with the same key, with B on a controller, or with its close box.

[h2]What it does[/h2]
[list]
[*][b]Log.[/b] Everything the game prints in debug mode and the F11 Lua Debugger's errors, one row each. Filter by kind (print, warning, error, ran here), by mod and by file, and search the messages and the stacks. A repeated error is one row with a count; click an error to open its whole stack in place.
[*][b]Export and Copy.[/b] Export writes what the filters show to a new .log file in Zomboid/Lua, with your user name taken out of the paths. Copy copies the picked row, or everything shown.
[*][b]The line.[/b] Type Lua and press Enter: it runs through the game's own console, its history and its suggestion included.
[*][b]Scratchpad.[/b] A box of many lines, past the game's 256 characters. Enter runs it, Shift+Enter makes a new line. Save snippets, and step through your last runs.
[*][b]Suggestions.[/b] They open as you type: globals after two letters, a table's fields after a dot, an object's methods after a colon, Java methods marked.
[*][b]Commands.[/b] Every server command with its syntax, an example and the lowest role that may use it. On a server you see the ones your role allows; a click fills the line and Send sends it, asking first before one that can't be undone. In single player each command points at the debug menu's own way of doing it.
[*][b]Help.[/b] What runs where, the keys, the controller and the files, in the window itself.
[*][b]Controller.[/b] The whole window works with a controller: the D-pad moves, A picks or types, B closes.
[/list]

[h2]Files[/h2]
Everything %(SHORT)s keeps is in Zomboid/Lua: each export, your snippets (%(MOD)s_snippets.txt, a plain text file you can edit) and your last runs (%(MOD)s_history.txt). An empty file named %(MOD)s_off.txt there hands the console back to the game's own from the next game start.

[h2]Languages[/h2]
The window's text comes in the %(N)d languages the game ships. Server commands are described in the game's own words.

[h2]Credits[/h2]
Made from %(ZED)s's Lua console by %(AUTHOR)s. %(ZED)s's [url=%(LICENSE_URL)s]source-available license[/url] covers it; the mod carries a copy as LICENSE.txt.
""" % {"NAME": NAME, "VERSION": VERSION, "SHORT": SHORT, "MOD": MOD_ID, "ZED": ZED_NAME,
       "AUTHOR": zed.get("author", ""), "N": len(langs), "ZED_URL": zed.get("url", ""), "LICENSE_URL": LICENSE_URL}


def gallery_readme():
    return """%(NAME)s: the Workshop page's pictures

preview.png (512 x 512) is the item's preview picture: design's box art, copied from ZeDUI/art/lua_console_93/
by ZeDUI/tools/products/build_luaconsole93.py (the same picture as the mod's poster). A new export there and a
build bring it here; do not edit it here. This folder is rewritten by every build.

The gallery: shots QA takes in game, on the plain game with %(SHORT)s alone (-debug -nosteam, mods.txt
listing only %(MOD)s), at 4K unless the shot says otherwise, the window settled before each shot. Save
them in %(GALLERY)s/ (not here: a build rewrites this folder) under these names (1920 x 1080 crops or
reductions are fine for Steam):

  1. shot1_log_filters.png    The log with a few mods' prints, a warning and errors; the MOD filter folded open,
                              one mod unticked, a search typed in, the count "shown of total | Errors" in view.
  2. shot2_error_open.png     An error opened to its whole stack (a mod's error with its file:line), its count
                              above 1, the row picked.
  3. shot3_scratchpad.png     The scratchpad with a few lines of code and their line numbers, SNIPPETS and
                              HISTORY open beside it, a run's printed lines in the log above.
  4. shot4_suggestions.png    The suggestions open under the caret: getPlayer(): with Java methods listed and
                              their brackets, the foot saying how many more.
  5. shot5_commands.png       The Commands page on a server (a host's game), a command picked: its syntax,
                              example and level in the detail, the chat line filled.
  6. shot6_deck.png           The window at the Steam Deck's size (1280 x 800, the game's font size on Auto),
                              the log page whole.
""" % {"NAME": NAME, "SHORT": SHORT, "MOD": MOD_ID, "GALLERY": GALLERY_REL}


# ======================================================================================================================
# THE CHECKS (before anything is written)
# ======================================================================================================================
def zed_shipped_paths():
    out = set()
    root = os.path.join(REPO, "42")
    for d, _, fs in os.walk(root):
        for f in fs:
            out.add(os.path.relpath(os.path.join(d, f), root).replace(os.sep, "/").lower())
    return out


def zed_keys():
    keys = set()
    for lang in os.listdir(TRANSLATE):
        p = os.path.join(TRANSLATE, lang, "UI.json")
        if os.path.isfile(p):
            with open(p, encoding="utf-8") as fh:
                keys |= set(json.load(fh))
    return keys


def check_output(files, lua):
    problems, notes = [], []
    # no ZeD name in the code, the strings or the keys (the guard's two strings and the comments aside)
    for name, text in lua.items():
        for t in lex(text, name):
            if t.k == "com":
                continue
            if t.k == "str":
                if "ZeD" in t.s and t.s not in GUARD_STRINGS:
                    problems.append("%s:%d: a string still names ZeD: %s" % (name, t.line, t.s))
                if re.search(r"beta", t.s, re.I):
                    problems.append("%s:%d: a string says beta: %s" % (name, t.line, t.s))
            elif t.k == "name":
                bad = zed_parts(t.s)
                if bad:
                    problems.append("%s:%d: a name still says %s: %s" % (name, t.line, bad[0], t.s))
                elif "zed" in t.s.lower():
                    notes.append("%s:%d: %s" % (name, t.line, t.s))
    # every require of this mod names a file it has
    mods = {n[:-4] for n in lua}
    for name, text in lua.items():
        for m in re.finditer(r'require\s+"%s/([^"]+)"' % MOD_ID, text):
            if m.group(1) not in mods:
                problems.append("%s requires %s/%s, which is not written" % (name, MOD_ID, m.group(1)))
    # no path ZeD-GUI ships under media/ (the game loads those by relative path across mods; mod.info and the
    # pictures beside it are each mod's own, and the Translate files merge by key: Translator.tryFillMapFromMods)
    shipped = zed_shipped_paths()
    for rel in files:
        if not rel.startswith("42/media/"):
            continue
        r = rel[3:]
        if r.lower() in shipped and not re.fullmatch(r"media/lua/shared/Translate/[A-Za-z_]+/UI\.json", r):
            problems.append("%s is a path %s ships" % (rel, ZED_NAME))
    # no key ZeD-GUI ships
    zk = zed_keys()
    for rel, data in files.items():
        if rel.endswith("/UI.json"):
            for k in json.loads(data.decode("utf-8")):
                if k in zk:
                    problems.append("%s: the key %s is %s's too" % (rel, k, ZED_NAME))
                if not k.startswith(KEY_PREFIX):
                    problems.append("%s: the key %s is not %s*" % (rel, k, KEY_PREFIX))
    # no "beta" anywhere a player reads, and nothing personal
    for rel, data in files.items():
        if rel.endswith((".txt", ".info", ".bbcode", ".json")):
            text = data.decode("utf-8")
            if re.search(r"\bbeta\b", text, re.I):
                problems.append("%s says beta" % rel)
            if re.search(r"users[\\/]+[a-z]", text, re.I):
                problems.append("%s holds a user folder path" % rel)
    return problems, notes


# ======================================================================================================================
# THE BUILD
# ======================================================================================================================
def build():
    """Everything the product holds, as { relative path: bytes }, and the closure for the report."""
    files_ = [analyse_file(FileInfo(r, True)) for r in WHOLE] + [analyse_file(FileInfo(r, False)) for r in SUPPORT]
    cl = Closure(files_).run()
    lua = lua_files(files_, cl)
    keys, prefixes = keys_used(lua)
    if prefixes:
        raise BuildError("translation keys built at run time, which this tool cannot list: %s" % sorted(prefixes))
    tr, tr_problems, langs = translations(keys)
    if tr_problems:
        raise BuildError("translations:\n  " + "\n  ".join(tr_problems))
    # the languages the game's code face draws (the text shim's CODE_LANGS)
    fits = [lang for lang in langs if all(code_face_has(v) for v in json.loads(tr[lang]).values())]
    if "EN" not in fits:
        raise BuildError("the English words have a letter the game's code face does not draw")
    filled = " ".join("%s = true," % lang for lang in fits)
    for name in list(lua):
        if CODE_LANGS_MARK in lua[name]:
            lua[name] = lua[name].replace(CODE_LANGS_MARK, filled)
    zed = zed_mod_info()
    out = {}
    for name, text in lua.items():
        out[LUA_DIR_REL + "/" + name] = text.encode("utf-8")
    for lang, text in tr.items():
        out["42/media/lua/shared/Translate/%s/UI.json" % lang] = text.encode("utf-8")
    out.update(art())
    out["42/mod.info"] = mod_info_text(zed).encode("utf-8")
    out["42/README.txt"] = readme_text(zed, langs).encode("utf-8")
    # the licence the texts cite travels with the mod, beside mod.info (each mod's own file: no path the game loads)
    with open(LICENSE, "rb") as fh:
        out["42/LICENSE.txt"] = fh.read()
    for tex in TEXTURES:
        with open(os.path.join(REPO, "42", "media", "textures", "ZeD", tex.replace("/", os.sep)), "rb") as fh:
            out[TEX_DIR_REL + "/" + tex] = fh.read()
    out["workshop/README.txt"] = gallery_readme().encode("utf-8")
    out["workshop_description.bbcode"] = workshop_text(zed, langs).encode("utf-8")
    problems, notes = check_output(out, lua)
    if problems:
        raise BuildError("the output breaks a rule:\n  " + "\n  ".join(problems))
    return out, files_, cl, notes


# the textures of ZeD-GUI's the closure draws with (AtomExtensions' arrows: chev.png, one draw per arrow)
TEXTURES = ["lines/chev.png"]


def kept_by_hand(rel):
    """A file a person puts in the built folder that no build makes: a gallery shot saved in workshop/ before the
    shots moved out (GALLERY_REL). A build leaves it where it is and --check does not count it."""
    return re.fullmatch(r"workshop/shot[^/]*\.png", rel) is not None


def write_tree(out, root):
    if os.path.isdir(root):
        for d, dirs, fs in os.walk(root, topdown=False):
            for f in fs:
                p = os.path.join(d, f)
                if not kept_by_hand(os.path.relpath(p, root).replace(os.sep, "/")):
                    os.remove(p)
            for sub in dirs:
                sp = os.path.join(d, sub)
                if os.path.isdir(sp) and not os.listdir(sp):
                    os.rmdir(sp)
    for rel in sorted(out):
        p = os.path.join(root, rel.replace("/", os.sep))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, "wb") as fh:
            fh.write(out[rel])


def same_tree(a, b):
    """The relative paths that differ between two folders (missing on either side, or other bytes)."""
    diff = []
    def walk(root):
        got = set()
        for d, _, fs in os.walk(root):
            for f in fs:
                rel = os.path.relpath(os.path.join(d, f), root).replace(os.sep, "/")
                if not kept_by_hand(rel):
                    got.add(rel)
        return got
    fa, fb = walk(a), walk(b) if os.path.isdir(b) else set()
    for rel in sorted(fa | fb):
        if rel not in fa or rel not in fb:
            diff.append(rel)
        elif not filecmp.cmp(os.path.join(a, rel), os.path.join(b, rel), shallow=False):
            diff.append(rel)
    return diff


def report(files_, cl, notes):
    print("THE CLOSURE: what each of %s's files gives" % ZED_NAME)
    for f in files_:
        inc = [c for c in f.chunks if cl.is_in(c)]
        if f.whole:
            print("  %-40s whole (%d statements)" % (f.rel, len(inc)))
            continue
        print("  %-40s %d of %d statements" % (f.rel, len([c for c in inc if c.kind != "require"]), len([c for c in f.chunks if c.kind not in ("require", "blank")])))
        for c in inc:
            print("      %5d  %-60s %s" % (c.line, c.first_line()[:60], cl.reasons[id(c)]))
    print("LEFT OUT (stood in for, or not here; every reach to them is guarded in %s's code):" % ZED_NAME)
    for k in sorted(cl.left):
        print("  %-20s %s; reached from %s" % (k, LEFT_OUT[k], ", ".join(sorted(cl.left[k])[:3])))
    absent = sorted({k.split(".")[0] + "." + k.split(".")[1] if "." in k else k for k in cl.missing
                     if not cl.index.get(("path", ".".join(k.split(".")[:2])))})
    print("NOT IN THE SOURCES TAKEN (guarded reaches):", ", ".join(absent))
    # a function taken here that another of ZeD-GUI's files defines again (a patch the console would then miss)
    taken = {d for f in files_ for c in f.chunks if cl.is_in(c) for d in c.defs if d[0] == "path"}
    known = set(WHOLE) | set(SUPPORT)
    again = []
    for d, _, fs in os.walk(SRC):
        for name in sorted(fs):
            rel = os.path.relpath(os.path.join(d, name), SRC).replace(os.sep, "/")
            if not name.endswith(".lua") or rel in known or "/ZeD/" not in "/" + rel:
                continue
            try:
                other = analyse_file(FileInfo(rel, False))
            except BuildError:
                continue
            for c in other.chunks:
                for dd in c.defs:
                    if dd in taken and not getattr(c, "is_table", False):
                        again.append("%s:%d defines %s again" % (rel, c.line, dd[1]))
    print("DEFINED AGAIN ELSEWHERE IN %s (not taken here):" % ZED_NAME, "none" if not again else "")
    for a in again:
        print("  " + a)
    if notes:
        print("NAMES WITH zed IN A WORD (left as they are):")
        for n in notes:
            print("  " + n)


def main(argv=None):
    ap = argparse.ArgumentParser(description="Build %s from %s's Lua console." % (NAME, ZED_NAME))
    ap.add_argument("--stage", action="store_true", help="also copy the mod to ~/Zomboid/mods/%s for QA" % MOD_ID)
    ap.add_argument("--check", action="store_true", help="build into a temporary folder and compare with %s" % OUT_REL)
    ap.add_argument("--report", action="store_true", help="print the closure")
    a = ap.parse_args(argv)
    try:
        out, files_, cl, notes = build()
    except BuildError as e:
        print("BUILD STOPPED: %s" % e)
        return 1
    if a.report:
        report(files_, cl, notes)
    dest = os.path.join(REPO, OUT_REL)
    if a.check:
        tmp = tempfile.mkdtemp(prefix="lc93_check_")
        try:
            write_tree(out, tmp)
            diff = same_tree(tmp, dest)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)
        if diff:
            print("CHECK: %s differs from a fresh build in %d files:" % (OUT_REL.replace(os.sep, "/"), len(diff)))
            for d in diff[:40]:
                print("  " + d)
            return 1
        print("CHECK: %s is what the sources build (%d files)" % (OUT_REL.replace(os.sep, "/"), len(out)))
        return 0
    write_tree(out, dest)
    n_lua = sum(1 for r in out if r.endswith(".lua"))
    n_tr = sum(1 for r in out if r.endswith("UI.json"))
    print("BUILT %s: %d files (%d Lua, %d translations) in %s" % (NAME, len(out), n_lua, n_tr, OUT_REL.replace(os.sep, "/")))
    if a.stage:
        stage = os.path.join(os.path.expanduser("~"), "Zomboid", "mods", MOD_ID)
        mod_files = {r: b for r, b in out.items() if r.startswith("42/")}
        write_tree(mod_files, stage)
        print("STAGED the mod to ~/Zomboid/mods/%s (%d files)" % (MOD_ID, len(mod_files)))
    return 0


if __name__ == "__main__":
    sys.exit(main())

