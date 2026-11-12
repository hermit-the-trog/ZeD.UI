-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ConsoleComplete.lua
-- ============================================================================
-- THE CONSOLE'S SUGGESTIONS: what can follow the word at the cursor, for the line and the scratchpad. No drawing.
-- Client. Logic only (ZeD.ConsoleComplete); ZeD_DebugConsole.lua draws the pull-down above the caret.
--
-- Three kinds of word get suggestions:
--   * a global, after two letters ("getP"): every name in the game's environment, walked once and kept until the
--     window opens again (refresh). The walk is a few thousand names; a keystroke only looks them up.
--   * a table's field after "." ("ZeD.", "Events."): the table's own keys and those it inherits through its
--     metatable's __index tables (an ISUI window's methods come that way)
--   * a method after ":" ("getPlayer():get"): for a Java object, the names in its metatable's __index table (the
--     game hands each class one, about 2000 names for the player), kept per class; with the parameter counts read
--     once per class through the game's reflection helpers (debug mode only), so a pick knows to leave the caret
--     inside the brackets
-- The word before the "." or ":" is worked out only when it is safe: names, and calls with no arguments whose names
-- start with get or is (getPlayer(), getGameTime()); anything else is never run. A word inside a string or a comment
-- gets nothing.
--
-- The one thing to know: Kahlua has no next(), so every walk is a pairs loop, and every Java call is in a pcall.
-- ============================================================================

ZeD = ZeD or {}
ZeD.ConsoleComplete = ZeD.ConsoleComplete or {}
local C = ZeD.ConsoleComplete

C.SHOW = 9            -- rows the pull-down shows; the rest are counted
C.MIN_GLOBAL = 2      -- letters typed before globals are offered
C.DEPTH = 8           -- how far up a metatable chain the fields are read

local IDENT = "^[%a_][%w_]*$"

-- the kind of a value, as the pull-down's word says it
function C.kindOf(v)
    local t = type(v)
    if t == "userdata" then return "Java" end
    if t == "function" or t == "table" then return t end
    return "value"
end

-- ---------------------------------------------------------------------------
-- LISTS: sorted by name, any case; each { n = name, l = lower case, k = kind, ar = parameter count or nil }
-- ---------------------------------------------------------------------------
local function sortList(list)
    table.sort(list, function(a, b)
        if a.l ~= b.l then return a.l < b.l end
        return a.n < b.n
    end)
    return list
end

-- the names of a table, and of the __index tables up its metatable chain (onlyFn: functions only)
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

--- The globals, walked once and kept (a fresh walk after refresh()).
function C.globals()
    if C._globals then return C._globals end
    local env = _G
    local list = keysOf(env, false)
    -- (the walk above follows _G's metatable too; a game with none gives its own keys only)
    C._globals = sortList(list)
    return C._globals
end

--- Drop what was kept: the globals and the last base worked out (the window calls it each time it opens).
function C.refresh()
    C._globals = nil
    C._base = nil
end

-- ---------------------------------------------------------------------------
-- JAVA METHODS: the metatable's __index names, kept per class; parameter counts from reflection
-- ---------------------------------------------------------------------------
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

-- a method's name: m:getName(), or the name before "(" in tostring(m) ("public int zombie.X.getPlayerNum()")
local function methodName(m)
    local ok, n = pcall(function() return m:getName() end)
    if ok and n ~= nil then return tostring(n) end
    local s = tostring(m)
    return string.match(s, "([%w_]+)%(")
end

-- name -> { min, max } parameter counts over every overload, read once per class (nil: the helpers are missing)
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

--- A Java object's methods, sorted, each with its parameter counts when reflection gave them. Kept per class.
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

-- ---------------------------------------------------------------------------
-- THE WORD AT THE CURSOR
-- ---------------------------------------------------------------------------
-- Is the cursor inside a string or a comment? (a scan of the code before it, "--" to the line's end, quotes with
-- their backslash escapes; long brackets count as a string from "[[" or "[=[" on)
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

-- the steps of a base: { { name, call } , { sep, name, call }, ... } or nil when it is not a plain chain
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

--- The word before position cur (0-based: the characters before it) of text, or nil when none is offered:
--- { start = 0-based index where the typed part begins, pre = the typed part, base = what comes before the "." or
--- ":" (nil for a global), sep = "." or ":" }
function C.token(text, cur)
    text = tostring(text or "")
    cur = math.max(0, math.min(#text, cur or #text))
    local before = string.sub(text, 1, cur)
    local pre = string.match(before, "[%w_]*$") or ""
    local ps = cur - #pre
    -- (a number, or a name that starts with a digit, gets nothing)
    if pre ~= "" and string.find(pre, "^%d") then return nil end
    local sep = ps > 0 and string.sub(text, ps, ps) or ""
    if inStringOrComment(before) then return nil end
    if sep ~= "." and sep ~= ":" then
        if #pre < C.MIN_GLOBAL then return nil end
        -- (a field after a bracket or a closing call that is not a plain chain: nothing)
        local prev = ps > 0 and string.sub(text, ps, ps) or ""
        if prev == "]" or prev == ")" then return nil end
        return { start = ps, pre = pre }
    end
    -- the base: names, dots, colons and empty calls, back to where they start
    local b = ps - 1
    while b >= 1 do
        local c = string.sub(text, b, b)
        if string.find(c, "[%w_%.:]") then b = b - 1
        elseif c == ")" and b > 1 and string.sub(text, b - 1, b - 1) == "(" then b = b - 2
        else break end
    end
    local base = string.sub(text, b + 1, ps - 1)
    if base == "" or ".." == string.sub(text, ps - 1, ps) then return nil end
    -- (whatever stands before the base must not make it part of a bigger expression: "x).y." or "t[1].")
    local prev = b >= 1 and string.sub(text, b, b) or ""
    if prev == "]" or prev == ")" or prev == "\"" or prev == "'" then return nil end
    if not stepsOf(base) then return nil end
    return { start = ps, pre = pre, base = base, sep = sep }
end

-- may this call run while typing? Only an empty call whose name starts with get or is.
local function safeCall(name) return string.find(name, "^get%u") ~= nil or string.find(name, "^is%u") ~= nil or name == "get" end

--- The value a base stands for, worked out with no side effects beyond get and is calls (nil, false when it can't be).
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

-- the list for a base and its separator, kept while the base stays the same
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

-- the first index of a sorted list whose lower-case name is not below pl
local function lowerBound(list, pl)
    local lo, hi = 1, #list + 1
    while lo < hi do
        local mid = math.floor((lo + hi) / 2)
        if list[mid].l < pl then lo = mid + 1 else hi = mid end
    end
    return lo
end

--- What to offer at the cursor: { start, stop (0-based: the typed part runs start..stop), pre, base, sep, java,
--- items = the first SHOW { n, k, ar, arMax }, more = how many more match } or nil when nothing does.
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
        -- (the word typed out whole is not offered back)
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

--- The brackets a function's pick gets in the pull-down: "()" for none, "(_, _)" for two, "(_, ..)" when an
--- overload takes more; nil for anything not a function or with no count known.
function C.signature(it)
    if not it or (it.k ~= "function" and it.k ~= "Java") or it.ar == nil then return nil end
    local parts = {}
    for i = 1, it.ar do parts[i] = "_" end
    if (it.arMax or it.ar) > it.ar then parts[#parts + 1] = ".." end
    return "(" .. table.concat(parts, ", ") .. ")"
end

--- The text with item i of ac taken: the typed part (and the rest of the word after the cursor) replaced by its name;
--- a function gets "()" unless a bracket follows already, the caret inside unless it takes no parameters.
--- Returns the new text and the cursor (0-based).
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
