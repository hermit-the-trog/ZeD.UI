"""lupa.luajit21 without lupa: the few calls the tests use (LuaRuntime, globals, execute, eval, attribute and call access
on Lua tables and functions, Python callbacks set as globals) over a LuaJIT executable running as a child process.
orgtest.py uses this when `lupa` is not installed, the way platesame.py falls back to a LuaJIT run.

The executable: $LUAJIT, else the LuaJIT the VS Code Lua debugger ships (actboy168.lua-debug). Nothing to install.

Wire: both ways a message is one kind byte, a count and that many values. A value is z (nil), T, F, n<number>;,
s<length>:<bytes>, h<id>; (a Lua table or function, kept on the Lua side by id) or p<id>; (a Python callable, which Lua
sees as a function that calls back). Strings travel as bytes and come back as latin-1 text, as lupa's encoding="latin-1".
"""
import atexit
import glob
import os
import subprocess
import tempfile


class LuaError(Exception):
    pass


SERVER = r'''
local ffi = require("ffi")
ffi.cdef("int _setmode(int, int);")
ffi.C._setmode(0, 0x8000); ffi.C._setmode(1, 0x8000)
local stdin, stdout = io.stdin, io.stdout
local H, HR, NH, stubs = {}, {}, 0, {}
local buf
local function put(s) buf[#buf + 1] = s end
local function handle(o)
    local id = HR[o]
    if not id then NH = NH + 1; id = NH; H[id] = o; HR[o] = id end
    return id
end
local function enc(v)
    local t = type(v)
    if v == nil then put("z")
    elseif t == "boolean" then put(v and "T" or "F")
    elseif t == "number" then put("n" .. string.format("%.17g", v) .. ";")
    elseif t == "string" then put("s" .. #v .. ":"); put(v)
    else put("h" .. handle(v) .. ";") end
end
local function reply(kind, ...)
    buf = {}
    put(kind)
    local n = select("#", ...)
    put(n .. ";")
    for i = 1, n do enc((select(i, ...))) end
    stdout:write(table.concat(buf)); stdout:flush()
end
local function rd(n)
    local s = stdin:read(n)
    if not s or #s < n then os.exit(0) end
    return s
end
local function upto()
    local t = {}
    while true do
        local c = rd(1)
        if c == ";" or c == ":" then return table.concat(t) end
        t[#t + 1] = c
    end
end
local serve
local function pystub(id)
    local f = stubs[id]
    if not f then
        f = function(...) reply("B", id, ...); return serve() end
        stubs[id] = f
    end
    return f
end
local function dec()
    local c = rd(1)
    if c == "z" then return nil
    elseif c == "T" then return true
    elseif c == "F" then return false
    elseif c == "n" then return tonumber(upto())
    elseif c == "s" then local n = tonumber(upto()); if n == 0 then return "" end; return rd(n)
    elseif c == "h" then return H[tonumber(upto())]
    elseif c == "p" then return pystub(tonumber(upto())) end
    error("bad value " .. c)
end
local function pack(...) return { n = select("#", ...), ... } end
local function dispatch(op, a, n)
    if op == "E" then
        local f, e = loadstring(a[1], "=chunk"); if not f then error(e, 0) end
        return f()
    elseif op == "G" then local o = a[1]; if o == nil then o = _G end; return o[a[2]]
    elseif op == "S" then local o = a[1]; if o == nil then o = _G end; o[a[2]] = a[3]; return
    elseif op == "C" then return a[1](unpack(a, 2, n))
    elseif op == "L" then return #a[1]
    elseif op == "V" or op == "K" or op == "I" then
        local out = {}
        for k, v in pairs(a[1]) do
            if op ~= "V" then out[#out + 1] = k end
            if op ~= "K" then out[#out + 1] = v end
        end
        return unpack(out, 1, #out)
    end
    error("bad op " .. op)
end
serve = function()
    while true do
        local op = rd(1)
        local n = tonumber(upto())
        local a = {}
        for i = 1, n do a[i] = dec() end
        if op == "P" then return unpack(a, 1, n) end
        if op == "Q" then error(a[1], 0) end
        local res = pack(pcall(dispatch, op, a, n))
        if res[1] then reply("R", unpack(res, 2, res.n)) else reply("X", tostring(res[2])) end
    end
end
serve()
'''


def _exe():
    e = os.environ.get("LUAJIT")
    if e and os.path.exists(e): return e
    for p in (os.path.expanduser("~/.vscode/extensions/actboy168.lua-debug-*/runtime/win32-x64/luajit/lua.exe"),
              os.path.expanduser("~/.vscode/extensions/actboy168.lua-debug-*/runtime/linux-x64/luajit/lua")):
        hits = sorted(glob.glob(p))
        if hits: return hits[-1]
    raise SystemExit("no lupa and no LuaJIT: install lupa, or set LUAJIT to a LuaJIT executable")


class LuaObj:
    """a Lua table or function, seen from Python: attribute and item access, call, values / keys / items"""
    __slots__ = ("_rt", "_id")

    def __init__(self, rt, id_):
        object.__setattr__(self, "_rt", rt)
        object.__setattr__(self, "_id", id_)

    def __getattr__(self, k):
        if k.startswith("__"): raise AttributeError(k)
        return self._rt._one(self._rt._request("G", self, k))

    def __setattr__(self, k, v): self._rt._request("S", self, k, v)
    def __getitem__(self, k): return self._rt._one(self._rt._request("G", self, k))
    def __setitem__(self, k, v): self._rt._request("S", self, k, v)
    def __call__(self, *a): return self._rt._one(self._rt._request("C", self, *a))
    def __len__(self): return int(self._rt._request("L", self)[0])
    def __eq__(self, o): return isinstance(o, LuaObj) and o._rt is self._rt and o._id == self._id
    def __hash__(self): return hash(self._id)
    def values(self): return self._rt._request("V", self)
    def keys(self): return self._rt._request("K", self)

    def items(self):
        f = self._rt._request("I", self)
        return list(zip(f[0::2], f[1::2]))


class _Globals(LuaObj):
    """_G: sent as nil, which the server reads as the globals"""
    __slots__ = ()


class LuaRuntime:
    def __init__(self, unpack_returned_tuples=False, encoding="latin-1", **kw):
        self.enc = encoding
        self.unpack = unpack_returned_tuples
        path = os.path.join(tempfile.gettempdir(), "zed_luashim_server.lua")
        with open(path, "w", newline="") as f: f.write(SERVER)
        self.p = subprocess.Popen([_exe(), path], stdin=subprocess.PIPE, stdout=subprocess.PIPE, bufsize=0)
        self.rf = self.p.stdout
        self.pys, self.pyid = [], {}
        self._g = _Globals(self, None)
        atexit.register(self.close)

    def close(self):
        try:
            if self.p.poll() is None:
                self.p.stdin.close(); self.p.wait(timeout=5)
        except Exception:
            try: self.p.kill()
            except Exception: pass

    # ---- wire
    def _enc(self, v, out):
        if v is None or isinstance(v, _Globals): out.append(b"z")
        elif v is True: out.append(b"T")
        elif v is False: out.append(b"F")
        elif isinstance(v, (int, float)): out.append(b"n" + repr(v).encode() + b";")
        elif isinstance(v, str): b = v.encode(self.enc); out.append(b"s%d:" % len(b) + b)
        elif isinstance(v, (bytes, bytearray)): out.append(b"s%d:" % len(v) + bytes(v))
        elif isinstance(v, LuaObj): out.append(b"h%d;" % v._id)
        elif callable(v):
            i = self.pyid.get(id(v))
            if i is None:
                i = len(self.pys); self.pys.append(v); self.pyid[id(v)] = i
            out.append(b"p%d;" % i)
        else: raise TypeError(f"cannot pass {type(v)} to Lua")

    def _send(self, kind, vals):
        out = [kind.encode(), b"%d;" % len(vals)]
        for v in vals: self._enc(v, out)
        self.p.stdin.write(b"".join(out))

    def _rd(self, n):
        b = self.rf.read(n)
        if b is None or len(b) < n: raise LuaError("the LuaJIT process ended")
        return b

    def _upto(self):
        t = []
        while True:
            c = self._rd(1)
            if c in (b";", b":"): return b"".join(t)
            t.append(c)

    def _dec(self):
        c = self._rd(1)
        if c == b"z": return None
        if c == b"T": return True
        if c == b"F": return False
        if c == b"n":
            f = float(self._upto())
            return int(f) if f == f and abs(f) < 2 ** 53 and f == int(f) else f
        if c == b"s":
            n = int(self._upto())
            return self._rd(n).decode(self.enc) if n else ""
        if c == b"h": return LuaObj(self, int(self._upto()))
        raise LuaError("bad reply " + repr(c))

    def _request(self, op, *vals):
        self._send(op, vals)
        while True:
            kind = self._rd(1).decode()
            n = int(self._upto())
            got = [self._dec() for _ in range(n)]
            if kind == "R": return got
            if kind == "X": raise LuaError(got[0])
            if kind == "B":
                try: ret = self.pys[got[0]](*got[1:])
                except Exception as e:
                    self._send("Q", (f"{type(e).__name__}: {e}",)); continue
                self._send("P", ret if isinstance(ret, tuple) else (ret,))

    def _one(self, rets):
        if not self.unpack: return rets[0] if rets else None
        return None if not rets else rets[0] if len(rets) == 1 else tuple(rets)

    # ---- the lupa calls the tests use
    def globals(self): return self._g
    def execute(self, code): return self._one(self._request("E", code))
    def eval(self, code): return self.execute("return " + code)
