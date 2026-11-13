-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_ConsoleComplete.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the suggestions: what can follow the word at the caret.
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_ConsoleComplete.lua by
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
LC93.ConsoleComplete = LC93.ConsoleComplete or {}
local C = LC93.ConsoleComplete

C.SHOW = 9
C.MIN_GLOBAL = 2
C.DEPTH = 8

local IDENT = "^[%a_][%w_]*$"

function C.kindOf(v)
    local t = type(v)
    if t == "userdata" then return "Java" end
    if t == "function" or t == "table" then return t end
    return "value"
end

local function sortList(list)
    table.sort(list, function(a, b)
        if a.l ~= b.l then return a.l < b.l end
        return a.n < b.n
    end)
    return list
end

local function keysOf(t, onlyFn, out, seen)
    out, seen = out or {}, seen or {}
    local depth = 0
    while type(t) == "table" and depth < C.DEPTH do
        for k, v in pairs(t) do
            if type(k) == "string" and not seen[k] and string.find(k, IDENT) and (not onlyFn or type(v) == "function") then
                seen[k] = true
                out[#out + 1] = { n = k, l = string.lower(k), k = C.kindOf(v) }
            end
        end
        local ok, mt = pcall(getmetatable, t)
        local nxt = nil
        if ok and type(mt) == "table" and type(rawget(mt, "__index")) == "table" then nxt = rawget(mt, "__index") end
        if nxt == t then break end
        t = nxt
        depth = depth + 1
    end
    return out
end

function C.globals()
    if C._globals then return C._globals end
    local env = _G
    local list = keysOf(env, false)
    C._globals = sortList(list)
    return C._globals
end

function C.refresh()
    C._globals = nil
    C._base = nil
end

C._classes = C._classes or {}

local function className(obj)
    if getClassSimpleName then
        local ok, n = pcall(getClassSimpleName, obj)
        if ok and n ~= nil then return tostring(n) end
    end
    local ok2, mt = pcall(getmetatable, obj)
    if ok2 and mt then return tostring(mt) end
    return nil
end
C.className = className

local function methodName(m)
    local ok, n = pcall(function() return m:getName() end)
    if ok and n ~= nil then return tostring(n) end
    local s = tostring(m)
    return string.match(s, "([%w_]+)%(")
end

local function arities(obj)
    if not (getNumClassFunctions and getClassFunction and getMethodParameterCount) then return nil end
    local okN, n = pcall(getNumClassFunctions, obj)
    if not okN or type(n) ~= "number" then return nil end
    local out = {}
    for i = 0, n - 1 do
        local okM, m = pcall(getClassFunction, obj, i)
        if okM and m then
            local name = methodName(m)
            local okC, pc = pcall(getMethodParameterCount, m)
            if name and okC and type(pc) == "number" then
                local a = out[name]
                if not a then out[name] = { min = pc, max = pc }
                else
                    if pc < a.min then a.min = pc end
                    if pc > a.max then a.max = pc end
                end
            end
        end
    end
    return out
end

function C.javaMethods(obj)
    local cls = className(obj)
    if cls and C._classes[cls] then return C._classes[cls], cls end
    local list = {}
    local ok, mt = pcall(getmetatable, obj)
    local idx = (ok and type(mt) == "table") and rawget(mt, "__index") or nil
    if type(idx) == "table" then
        for k, v in pairs(idx) do
            if type(k) == "string" and string.find(k, IDENT) and v ~= nil then
                list[#list + 1] = { n = k, l = string.lower(k), k = "Java" }
            end
        end
    end
    local ar = arities(obj)
    if ar then
        for _, it in ipairs(list) do
            local a = ar[it.n]
            if a then it.ar, it.arMax = a.min, a.max end
        end
    end
    sortList(list)
    if cls then C._classes[cls] = list end
    return list, cls
end

local function inStringOrComment(before)
    local i, n = 1, #before
    local q = nil
    while i <= n do
        local c = string.sub(before, i, i)
        if q then
            if c == "\\" then i = i + 1
            elseif q == "]]" then
                if string.sub(before, i, i + 1) == "]]" then q = nil; i = i + 1 end
            elseif c == q then q = nil end
        elseif c == "\"" or c == "'" then q = c
        elseif c == "[" and (string.sub(before, i, i + 1) == "[[" or string.sub(before, i, i + 1) == "[=") then q = "]]"
        elseif c == "-" and string.sub(before, i, i + 1) == "--" then
            local nl = string.find(before, "\n", i, true)
            if not nl then return true end
            i = nl
        end
        i = i + 1
    end
    return q ~= nil
end

local function stepsOf(base)
    local steps = {}
    local pos = 1
    local n = #base
    while pos <= n do
        local sep = nil
        if pos > 1 then
            sep = string.sub(base, pos, pos)
            if sep ~= "." and sep ~= ":" then return nil end
            pos = pos + 1
        end
        local s, e = string.find(base, "^[%a_][%w_]*", pos)
        if not s then return nil end
        local name = string.sub(base, s, e)
        pos = e + 1
        local call = false
        if string.sub(base, pos, pos + 1) == "()" then call = true; pos = pos + 2 end
        if sep == ":" and not call then return nil end
        steps[#steps + 1] = { sep = sep, name = name, call = call }
    end
    return steps
end

function C.token(text, cur)
    text = tostring(text or "")
    cur = math.max(0, math.min(#text, cur or #text))
    local before = string.sub(text, 1, cur)
    local pre = string.match(before, "[%w_]*$") or ""
    local ps = cur - #pre
    if pre ~= "" and string.find(pre, "^%d") then return nil end
    local sep = ps > 0 and string.sub(text, ps, ps) or ""
    if inStringOrComment(before) then return nil end
    if sep ~= "." and sep ~= ":" then
        if #pre < C.MIN_GLOBAL then return nil end
        local prev = ps > 0 and string.sub(text, ps, ps) or ""
        if prev == "]" or prev == ")" then return nil end
        return { start = ps, pre = pre }
    end
    local b = ps - 1
    while b >= 1 do
        local c = string.sub(text, b, b)
        if string.find(c, "[%w_%.:]") then b = b - 1
        elseif c == ")" and b > 1 and string.sub(text, b - 1, b - 1) == "(" then b = b - 2
        else break end
    end
    local base = string.sub(text, b + 1, ps - 1)
    if base == "" or ".." == string.sub(text, ps - 1, ps) then return nil end
    local prev = b >= 1 and string.sub(text, b, b) or ""
    if prev == "]" or prev == ")" or prev == "\"" or prev == "'" then return nil end
    if not stepsOf(base) then return nil end
    return { start = ps, pre = pre, base = base, sep = sep }
end

local function safeCall(name) return string.find(name, "^get%u") ~= nil or string.find(name, "^is%u") ~= nil or name == "get" end

function C.resolve(base)
    local steps = stepsOf(base)
    if not steps then return nil, false end
    local v = nil
    for i, st in ipairs(steps) do
        local ok, r
        if i == 1 then
            ok, r = pcall(function() return _G[st.name] end)
        elseif st.sep == "." then
            if type(v) ~= "table" and type(v) ~= "userdata" then return nil, false end
            ok, r = pcall(function() return v[st.name] end)
        else
            local obj = v
            ok, r = pcall(function() return obj[st.name] end)
            if not ok or type(r) ~= "function" or not safeCall(st.name) then return nil, false end
            ok, r = pcall(r, obj)
            if not ok then return nil, false end
            st = { call = false }
        end
        if not ok then return nil, false end
        if st.call then
            if type(r) ~= "function" or not safeCall(st.name) then return nil, false end
            ok, r = pcall(r)
            if not ok then return nil, false end
        end
        v = r
        if v == nil then return nil, false end
    end
    return v, true
end

local function baseList(base, sep)
    local key = base .. sep
    if C._base and C._base.key == key then return C._base.list, C._base.java end
    local v, ok = C.resolve(base)
    local list, java = {}, false
    if ok then
        local t = type(v)
        if sep == "." and t == "table" then list = sortList(keysOf(v, false))
        elseif sep == ":" and t == "table" then list = sortList(keysOf(v, true))
        elseif sep == ":" and t == "userdata" then list = C.javaMethods(v); java = true
        elseif sep == ":" and t == "string" and type(string) == "table" then list = sortList(keysOf(string, true)) end
    end
    C._base = { key = key, list = list, java = java }
    return list, java
end

local function lowerBound(list, pl)
    local lo, hi = 1, #list + 1
    while lo < hi do
        local mid = math.floor((lo + hi) / 2)
        if list[mid].l < pl then lo = mid + 1 else hi = mid end
    end
    return lo
end

function C.complete(text, cur)
    text = tostring(text or "")
    cur = math.max(0, math.min(#text, cur or #text))
    local tok = C.token(text, cur)
    if not tok then return nil end
    local list, java
    if tok.base then list, java = baseList(tok.base, tok.sep) else list, java = C.globals(), false end
    local pl = string.lower(tok.pre)
    local items, count = {}, 0
    local i = lowerBound(list, pl)
    while i <= #list do
        local it = list[i]
        if string.sub(it.l, 1, #pl) ~= pl then break end
        if it.n ~= tok.pre then
            count = count + 1
            if #items < C.SHOW then items[#items + 1] = it end
        end
        i = i + 1
    end
    if #items == 0 then return nil end
    return { start = tok.start, stop = cur, pre = tok.pre, base = tok.base, sep = tok.sep, java = java,
             items = items, more = count - #items }
end

function C.signature(it)
    if not it or (it.k ~= "function" and it.k ~= "Java") or it.ar == nil then return nil end
    local parts = {}
    for i = 1, it.ar do parts[i] = "_" end
    if (it.arMax or it.ar) > it.ar then parts[#parts + 1] = ".." end
    return "(" .. table.concat(parts, ", ") .. ")"
end

function C.take(text, ac, i)
    text = tostring(text or "")
    local it = ac and ac.items[i or 1]
    if not it then return text, #text end
    local tail = string.sub(text, ac.stop + 1)
    local rest = string.match(tail, "^[%w_]*") or ""
    tail = string.sub(tail, #rest + 1)
    local ins = it.n
    local cur = ac.start + #ins
    if (it.k == "function" or it.k == "Java") and string.sub(tail, 1, 1) ~= "(" then
        ins = ins .. "()"
        cur = cur + ((it.ar == 0 and (it.arMax or 0) == 0) and 2 or 1)
    end
    return string.sub(text, 1, ac.start) .. ins .. tail, cur
end

return C
