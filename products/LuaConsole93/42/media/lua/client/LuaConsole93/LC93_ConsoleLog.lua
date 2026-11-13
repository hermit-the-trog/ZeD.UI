-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_ConsoleLog.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the Log page's rows: the game's console box and the F11 error
-- list as one list.
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_ConsoleLog.lua by
-- ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change ZeD-GUI's file and build again.
-- ============================================================================================================

-- With ZeD-GUI on (mod ZeD_UI; the game can put a backslash before a mod's id), ZeD-GUI's console is the one:
-- this file stops here and defines nothing.
do
    local guiOn = false
    pcall(function()
        local mods = getActivatedMods()
        for i = 0, mods:size() - 1 do
            if string.gsub(tostring(mods:get(i)), "^\\", "") == "ZeD_UI" then guiOn = true end
        end
    end)
    if guiOn then return end
end

LC93 = LC93 or {}
LC93.ConsoleLog = LC93.ConsoleLog or {}
local L = LC93.ConsoleLog

L.CAP = 5000
L.FLUSH_MS = 300
L.BOX_KEEPS = 8192
L.KINDS = { "print", "warn", "error", "ran" }
L.GAME = "#game"
L.CONSOLE = "#console"
local GAME, CONSOLE = L.GAME, L.CONSOLE

L.rev = L.rev or 0
L.viewRev = L.viewRev or 0
L.q = L.q or ""
L.off = L.off or { kind = {}, mod = {}, file = {} }

local function tr(k, ...) if LC93.tr then return LC93.tr(k, ...) end return k end

function L.modName(m)
    if m == GAME then return tr("UI_LC93_Console_ModGame") end
    if m == CONSOLE then return tr("UI_LC93_Console_ModConsole") end
    return tostring(m or "")
end
function L.fileName(f)
    if f == nil or f == "" then return tr("UI_LC93_Console_NoFile") end
    return f
end
function L.srcOf(r)
    if not r.file or r.file == "" then return "" end
    if r.line then return r.file .. ":" .. tostring(r.line) end
    return r.file
end

local _fmt = {}
local function dateText(pattern)
    local f = _fmt[pattern]
    if f == nil then
        local ok, v = pcall(function() return SimpleDateFormat.new(pattern, Locale.ENGLISH) end)
        f = ok and v or false
        _fmt[pattern] = f
    end
    if not f then return nil end
    local ok, s = pcall(function() return tostring(f:format(Calendar.getInstance():getTime())) end)
    return ok and s or nil
end
function L.clock() return dateText("HH:mm:ss") or "" end
function L.stamp() return dateText("yyyy-MM-dd_HHmmss") or "export" end

function L.startsError(s)
    if s:find("^ERROR") or s:find("^SEVERE") or s:find("^%s*STACK TRACE") then return true end
    if s:find("console[\"%]]*:%d+:") then return true end
    if s:find("Exception") and not s:find("^LOG") then return true end
    if s:find("^%s*Lua%(") or s:find("^%s*se%.krka") or s:find("^%s*java%.") then return true end
    return false
end
function L.continuesError(s)
    if s == "" then return false end
    if s:find("^%s") then return true end
    if s:find("^STACK TRACE") or s:find("^%-%-%-%-") or s:find("%-%-%-%-%-%-%-%-%-%-$") then return true end
    if s:find("^Lua%(") or s:find("^Callframe") or s:find("^function: ") or s:find("^Caused by") or s:find("^java%.") or s:find("^se%.krka") then return true end
    return false
end

local function splitPrefix(s)
    local lvl, rest = s:match("^(%u+)%s*:%s*%S+%s+f:%d+,%s*t:%d+>%s?(.*)$")
    if lvl then return lvl, rest end
    return nil, s
end

function L.frames(text)
    local out = {}
    for l in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        local fr = nil
        local a = string.find(l, "Lua((MOD:", 1, true)
        if a then
            local b = string.find(l, ")).", a + 9, true)
            if b then
                local fn, file, line = string.sub(l, b + 3):match("^([^%(]*)%(([^%(%):]+):(%d+)%)")
                if file then fr = { mod = string.sub(l, a + 9, b - 1), fn = fn, file = file, line = tonumber(line) } end
            end
        elseif string.find(l, "Lua(Vanilla).", 1, true) then
            local fn, file, line = l:match("Lua%(Vanilla%)%.([^%(]*)%(([^%(%):]+):(%d+)%)")
            if file then fr = { fn = fn, file = file, line = tonumber(line) } end
        else
            local fn, file, line, rest = l:match("function:%s*(%S+)%s+%-%-%s+file:%s*(%S+)%s+line #%s*(%d+)%s*|%s*(.-)%.?%s*$")
            if file then fr = { fn = fn, file = file, line = tonumber(line), mod = rest:match("^MOD:%s*(.-)$") } end
        end
        if fr then out[#out + 1] = fr end
    end
    return out
end

function L.placeOf(text, msg)
    local frames = L.frames(text)
    local at = nil
    for _, f in ipairs(frames) do if f.mod and f.mod ~= "" then at = f; break end end
    at = at or frames[1]
    if at then
        if at.mod and at.mod ~= "" then return at.mod, at.file, at.line end
        if at.file == "console" then return CONSOLE, at.file, at.line end
        return GAME, at.file, at.line
    end
    local ln = tostring(msg or ""):match("console[\"%]]*:(%d+):")
    if ln then return CONSOLE, "console", tonumber(ln) end
    return GAME, "", nil
end

local function isHeadLine(t)
    return t:find("^ERROR") or t:find("^SEVERE") or t:find("^%-%-%-%-") or t:find("^STACK TRACE") or t:find("^dumping")
        or t:find("^Callframe") or t:find("^function:") or t:find("^Lua%(") or t:find("^se%.krka") or t:find("^at ")
end
function L.messageOf(text)
    text = tostring(text or "")
    for l in (text .. "\n"):gmatch("([^\n]*)\n") do
        local m = l:match("Exception:%s*(.-)%s*$")
        if m and m ~= "" then
            m = m:gsub("%s+at%s+[%w%.%$]+%([%w%.]+:%d+%)%.?$", "")
            return m:sub(1, 300)
        end
    end
    local first = nil
    for l in (text .. "\n"):gmatch("([^\n]*)\n") do
        local _, rest = splitPrefix(l)
        local t = rest:gsub("^%s+", ""):gsub("%s+$", "")
        if t:find("console[\"%]]*:%d+:") then return t:sub(1, 300) end
        if t ~= "" then
            first = first or t
            if not isHeadLine(t) then return t:sub(1, 300) end
        end
    end
    return (first or ""):sub(1, 300)
end

local _mods = nil
local function modTable()
    if _mods then return _mods end
    _mods = { ["lua console 93"] = "Lua Console 93" }
    pcall(function()
        local list = getActivatedMods()
        for i = 0, list:size() - 1 do
            local id = tostring(list:get(i))
            local name = id
            pcall(function() local mi = getModInfoByID(id); if mi then name = tostring(mi:getName()) end end)
            _mods[string.lower(id)] = name
            _mods[string.lower(name)] = name
        end
    end)
    return _mods
end
function L.forgetMods() _mods = nil end

function L.modOfPrint(msg)
    local tag = msg:match("^%[([^%]]+)%]") or msg:match("^([%w][%w _%-%.!%?']-):%s")
    if not tag then return GAME end
    return modTable()[string.lower(tag)] or GAME
end

local function lower(s) return string.lower(s) end

local function hayOf(r)
    if not r.hay then
        local parts = { r.msg, L.modName(r.mod), L.srcOf(r) }
        if r.stack then for i = 1, #r.stack do parts[#parts + 1] = r.stack[i] end end
        r.hay = lower(table.concat(parts, "\n"))
    end
    return r.hay
end
local function matches(r)
    if L._ql == "" then return true end
    return string.find(hayOf(r), L._ql, 1, true) ~= nil
end
local function passes(r)
    return r.m and not L.off.kind[r.kind] and not L.off.mod[r.mod] and not L.off.file[r.file or ""]
end

local function addName(list, all, key)
    local n = (all[key] or 0) + 1
    all[key] = n
    if n == 1 then list[#list + 1] = key; L.namesRev = L.namesRev + 1 end
end
local function dropName(list, all, key)
    local n = (all[key] or 0) - 1
    if n > 0 then all[key] = n; return end
    all[key] = nil
    for i = #list, 1, -1 do if list[i] == key then table.remove(list, i); break end end
    L.namesRev = L.namesRev + 1
end
local function count(r, d)
    local c = L.cnt
    c.kind[r.kind] = (c.kind[r.kind] or 0) + d
    c.mod[r.mod] = (c.mod[r.mod] or 0) + d
    local f = r.file or ""
    c.file[f] = (c.file[f] or 0) + d
end

function L.clear()
    L.rows, L.first, L.last = {}, 1, 0
    L.vis, L.vfirst, L.vlast = {}, 1, 0
    L.byKey = {}
    L.cnt = { kind = {}, mod = {}, file = {} }
    L.all = { mod = {}, file = {} }
    L.mods, L.files = {}, {}
    L.namesRev = (L.namesRev or 0) + 1
    L.nextId = L.nextId or 1
    L.shownErr, L.errTotal = 0, 0
    L._blk, L._f11 = nil, nil
    L._ql = lower(L.q or "")
    L.rev = L.rev + 1
    L.viewRev = L.viewRev + 1
end

function L.reset()
    L.clear()
    L._seen, L._part = nil, ""
    L._f11Seen = 0
    L._ran = {}
    L._expect = {}
    L.q, L._ql = "", ""
    L.off = { kind = {}, mod = {}, file = {} }
end

local function dropOldest()
    local r = L.rows[L.first]
    L.rows[L.first] = nil
    L.first = L.first + 1
    if not r then return end
    if r.m then count(r, -1) end
    dropName(L.mods, L.all.mod, r.mod)
    dropName(L.files, L.all.file, r.file or "")
    if L.vis[L.vfirst] == r then
        L.vis[L.vfirst] = nil
        L.vfirst = L.vfirst + 1
        if r.kind == "error" then L.shownErr = L.shownErr - 1 end
    end
    if r.key and L.byKey[r.key] == r then L.byKey[r.key] = nil end
    if r.kind == "error" then L.errTotal = L.errTotal - (r.n or 1) end
    r.vis = false
end

local function add(r)
    r.id = L.nextId
    L.nextId = L.nextId + 1
    r.n = r.n or 1
    L.last = L.last + 1
    L.rows[L.last] = r
    addName(L.mods, L.all.mod, r.mod)
    addName(L.files, L.all.file, r.file or "")
    r.m = matches(r)
    if r.m then count(r, 1) end
    if passes(r) then
        L.vlast = L.vlast + 1
        L.vis[L.vlast] = r
        r.vis = true
        if r.kind == "error" then L.shownErr = L.shownErr + 1 end
    end
    if r.kind == "error" then L.errTotal = L.errTotal + r.n end
    while L.last - L.first + 1 > L.CAP do dropOldest() end
    L.rev = L.rev + 1
    L.viewRev = L.viewRev + 1
    return r
end

function L.refilter()
    L._ql = lower(L.q or "")
    L.cnt = { kind = {}, mod = {}, file = {} }
    L.vis, L.vfirst, L.vlast = {}, 1, 0
    L.shownErr = 0
    for i = L.first, L.last do
        local r = L.rows[i]
        r.m = matches(r)
        if r.m then count(r, 1) end
        if passes(r) then
            L.vlast = L.vlast + 1
            L.vis[L.vlast] = r
            r.vis = true
            if r.kind == "error" then L.shownErr = L.shownErr + 1 end
        else
            r.vis = false
        end
    end
    L.viewRev = L.viewRev + 1
end

function L.setQuery(q)
    q = tostring(q or "")
    if q == L.q then return false end
    L.q = q
    L.refilter()
    return true
end

function L.toggle(group, key)
    local g = L.off[group]
    if not g then return end
    if g[key] then g[key] = nil else g[key] = true end
    L.refilter()
end
function L.isOn(group, key) return not (L.off[group] and L.off[group][key]) end

function L.showAll()
    L.off = { kind = {}, mod = {}, file = {} }
    L.q = ""
    L.refilter()
end

function L.counts() return L.vlast - L.vfirst + 1, L.last - L.first + 1, L.shownErr end
function L.shownAt(i) return L.vis[L.vfirst + i - 1] end
function L.indexOf(r)
    if not r or not r.vis then return nil end
    for i = L.vfirst, L.vlast do if L.vis[i] == r then return i - L.vfirst + 1 end end
    return nil
end

local function splitLines(text)
    local out = {}
    for l in (tostring(text or ""):gsub("\r", ""):gsub("\t", "    ") .. "\n"):gmatch("([^\n]*)\n") do
        if l ~= "" then out[#out + 1] = l end
    end
    return out
end

function L.addError(text, source, t)
    local msg = L.messageOf(text)
    local mod, file, line = L.placeOf(text, msg)
    local key = msg .. "|" .. tostring(file) .. ":" .. tostring(line)
    local stack = splitLines(text)
    local r = L.byKey[key]
    if r then
        local k = source == "f11" and "nF11" or "nBox"
        r[k] = (r[k] or 0) + 1
        local n = math.max(r.nF11 or 0, r.nBox or 0)
        if n > r.n then
            L.errTotal = L.errTotal + (n - r.n)
            r.n = n
            r.tLast = t or r.tLast
        end
        if #stack > #r.stack then
            r.stack, r.hay = stack, nil
            local was = r.m
            r.m = matches(r)
            if was ~= r.m then L.refilter() end
        end
        L.rev = L.rev + 1
        L.viewRev = L.viewRev + 1
        return r
    end
    r = { t = t or L.clock(), kind = "error", msg = msg, mod = mod, file = file, line = line, stack = stack, key = key }
    if source == "f11" then r.nF11 = 1 else r.nBox = 1 end
    L.byKey[key] = r
    return add(r)
end

function L.ran(line, t)
    line = tostring(line or "")
    L._ran = L._ran or {}
    L._ran[#L._ran + 1] = line
    if #L._ran > 8 then table.remove(L._ran, 1) end
    return add({ t = t or L.clock(), kind = "ran", msg = "> " .. line, mod = CONSOLE, file = "" })
end

function L.ranCode(code, t)
    code = tostring(code or "")
    local first = code:match("^([^\n]*)") or ""
    local more = 0
    for _ in code:gmatch("\n") do more = more + 1 end
    local msg = "> " .. first
    if more > 0 then msg = msg .. "  " .. tr("UI_LC93_Console_RanMore", more) end
    return add({ t = t or L.clock(), kind = "ran", msg = msg, mod = CONSOLE, file = "", code = code })
end

L.EXPECT_MS = 10000
function L.output(text, t, ms)
    text = tostring(text or ""):gsub("\r", ""):gsub("\t", "    ")
    ms = ms or (getTimestampMs and getTimestampMs()) or 0
    L._expect = L._expect or {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        add({ t = t or L.clock(), kind = "print", msg = line, mod = CONSOLE, file = "" })
        L._expect[#L._expect + 1] = { s = line, at = ms }
        if #L._expect > 64 then table.remove(L._expect, 1) end
    end
end

local function expected(msg)
    local e = L._expect
    if not e then return false end
    for i = 1, #e do
        if e[i].s == msg then table.remove(e, i); return true end
    end
    return false
end

local function closeBlock()
    local b = L._blk
    L._blk = nil
    if b then L.addError(table.concat(b.lines, "\n"), "box", b.t) end
end

local function boxLine(s, t, ms)
    s = s:gsub("\r", ""):gsub("\t", "    ")
    local b = L._blk
    if b then
        if L.continuesError(s) then
            b.lines[#b.lines + 1] = s
            b.at = ms
            return
        end
        closeBlock()
    end
    if L.startsError(s) then
        L._blk = { lines = { s }, t = t, at = ms }
        return
    end
    if s:find("^%s*$") then return end
    local echo = s:match("^%[USER%]%s?(.*)$")
    if echo then
        for i, r in ipairs(L._ran or {}) do
            if r == echo then table.remove(L._ran, i); return end
        end
        add({ t = t, kind = "ran", msg = "> " .. echo, mod = CONSOLE, file = "" })
        return
    end
    local lvl, msg = splitPrefix(s)
    local kind = (lvl == "WARN") and "warn" or "print"
    if kind == "print" and expected(msg) then return end
    add({ t = t, kind = kind, msg = msg, mod = L.modOfPrint(msg), file = "" })
end

local function newFrom(prev, text)
    if prev == "" then return 1, true end
    if #text >= #prev and text:sub(1, #prev) == prev then return #prev + 1, false end
    local tail = prev:sub(-math.min(#prev, 160))
    local ends = {}
    local i = 1
    while true do
        local a, b = string.find(text, tail, i, true)
        if not a then break end
        ends[#ends + 1] = b
        i = a + 1
    end
    for k = #ends, 1, -1 do
        local e = ends[k]
        if e <= #prev and text:sub(1, e) == prev:sub(#prev - e + 1) then return e + 1, false end
    end
    if #text >= L.BOX_KEEPS - 200 then
        local nl = string.find(text, "\n", 1, true)
        if nl then return nl + 1, true end
    end
    return 1, true
end

function L.feedText(text, ms)
    text = tostring(text or "")
    local prev = L._seen or ""
    if text == prev then return false end
    L._seen = text
    if text == "" then L._part = ""; return true end
    local from, fresh = newFrom(prev, text)
    if fresh then L._part = "" end
    local chunk = (L._part or "") .. text:sub(from)
    local cut = nil
    local p = 0
    while true do
        local a = string.find(chunk, "\n", p + 1, true)
        if not a then break end
        cut = a
        p = a
    end
    if not cut then L._part = chunk; return true end
    L._part = chunk:sub(cut + 1)
    local t = L.clock()
    local pos = 1
    while pos <= cut do
        local e = string.find(chunk, "\n", pos, true)
        boxLine(chunk:sub(pos, e - 1), t, ms or 0)
        pos = e + 1
    end
    return true
end

local function closeF11()
    local e = L._f11
    L._f11 = nil
    if e then L.addError(table.concat(e.parts, "\n"), "f11", e.t) end
end

local function f11Entry(s, ms)
    local e = L._f11
    local sep = s:find("^%s*%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-%-") ~= nil
    local exc = s:find("Exception", 1, true) ~= nil and not s:find("^%s") and not s:find("^at ")
    if sep or (exc and e and e.exc) then
        closeF11()
        e = nil
    end
    if not e then
        e = { parts = {}, t = L.clock(), at = ms }
        L._f11 = e
    end
    e.parts[#e.parts + 1] = s
    e.at = ms
    if exc then e.exc = true end
end

function L.feedErrors(list, n, ms)
    n = tonumber(n) or 0
    local seen = L._f11Seen or 0
    if n == seen or not list then return false end
    local new = n - seen
    L._f11Seen = n
    local size = 0
    pcall(function() size = list:size() end)
    local from = (new > 0) and math.max(0, size - new) or size
    for i = from, size - 1 do
        local s = ""
        pcall(function() s = tostring(list:get(i) or "") end)
        f11Entry(s, ms or 0)
    end
    return true
end

function L.tick(ms)
    ms = ms or 0
    if L._blk and ms - (L._blk.at or 0) >= L.FLUSH_MS then closeBlock() end
    if L._f11 and ms - (L._f11.at or 0) >= L.FLUSH_MS then closeF11() end
    local e = L._expect
    while e and e[1] and ms - (e[1].at or 0) >= L.EXPECT_MS do table.remove(e, 1) end
end

local KIND_KEY = { print = "UI_LC93_Console_WordPrint", warn = "UI_LC93_Console_WordWarn", error = "UI_LC93_Console_WordError", ran = "UI_LC93_Console_WordRan" }
function L.kindWord(kind) return tr(KIND_KEY[kind] or KIND_KEY.print) end

function L.rowText(r, out)
    out = out or {}
    local s = (r.t or "") .. " | " .. L.kindWord(r.kind) .. " | " .. tostring(r.msg or "") .. " | " .. L.modName(r.mod)
    local src = L.srcOf(r)
    if src ~= "" then s = s .. " " .. src end
    if (r.n or 1) > 1 then s = s .. " | x" .. tostring(r.n) end
    out[#out + 1] = s
    if r.stack then for i = 1, #r.stack do out[#out + 1] = "    " .. r.stack[i] end end
    return out
end

function L.shownText()
    local out = {}
    for i = L.vfirst, L.vlast do L.rowText(L.vis[i], out) end
    return table.concat(out, "\n")
end

local function scrubbed(text)
    local M = LC93.Messages
    if M and M.scrub then
        local ok, s = pcall(M.scrub, text)
        if ok and s then return s end
    end
    return text
end
L.scrubbed = scrubbed

function L.exportName()
    local base = "LuaConsole93_" .. L.stamp()
    local name = base .. ".log"
    if L._lastBase == base then
        L._sameN = (L._sameN or 1) + 1
        name = base .. "_" .. tostring(L._sameN) .. ".log"
    else
        L._lastBase, L._sameN = base, 1
    end
    return name
end

function L.export()
    local name = L.exportName()
    local shown, total, errs = L.counts()
    local head = "Lua Console 93 | " .. tostring(L.stamp()) .. " | " .. shown .. " of " .. total .. " | errors " .. errs
    if L.q ~= "" then head = head .. " | search \"" .. L.q .. "\"" end
    local text = scrubbed(head .. "\n" .. L.shownText() .. "\n")
    local ok = pcall(function()
        local w = getFileWriter(name, true, false)
        w:write(text)
        w:close()
    end)
    if not ok then return nil, 0, name end
    return name, shown
end

if not L.rows then L.reset() end

return L
