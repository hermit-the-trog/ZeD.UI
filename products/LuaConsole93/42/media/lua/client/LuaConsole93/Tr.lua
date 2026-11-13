-- LuaConsole93/42/media/lua/client/LuaConsole93/Tr.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's Tr.lua the console uses (39 of its 54
-- statements).
-- Made from ZeD-GUI's 42/media/lua/shared/ZeD/Tr.lua by ZeDUI/tools/products/build_luaconsole93.py. Do not
-- edit it here: change ZeD-GUI's file and build again.
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

local defaults = LC93._trDefaults or {}
LC93._trDefaults = defaults

local READ_MS   = 500
local CACHE_MAX = 2000

local st = LC93._trState or { on = false, nextRead = 0 }
LC93._trState = st

local function readOption()
    local o = LC93.Settings and LC93.Settings.testLanguageOption
    if not o then return false end
    local ok, v = pcall(o.getValue, o)
    return ok and v == 2
end

local checkLanguage = nil

local function testOn()
    if not getTimestampMs then return false end
    local now = getTimestampMs()
    if now >= st.nextRead then
        st.nextRead = now + READ_MS
        st.on = readOption()
        if checkLanguage then checkLanguage() end
    end
    return st.on
end

local CODES = {
    A = 192, C = 264, D = 270, E = 201, G = 284, H = 292, I = 204, J = 308, K = 310,
    L = 313, N = 209, O = 212, R = 340, S = 352, T = 356, U = 219, W = 372, Y = 221, Z = 381,
    a = 224, c = 265, d = 271, e = 233, g = 285, h = 293, i = 236, j = 309, k = 311,
    l = 314, n = 241, o = 244, r = 341, s = 353, t = 357, u = 251, w = 373, y = 253, z = 382,
}
local MAP = {}
for ch, code in pairs(CODES) do MAP[ch] = string.char(code) end

local VOWEL = { a = true, e = true, i = true, o = true, u = true, A = true, E = true, I = true, O = true, U = true }

local cache, order, head, count = {}, {}, 1, 0

local function keepAt(s, i)
    local c = s:sub(i, i)
    if c == "%" then
        local d = s:sub(i + 1, i + 1)
        if d == "1" or d == "2" or d == "3" or d == "4" then return "%" .. d end
    elseif c == "<" then
        local j = s:find(">", i, true)
        if j and j - i < 40 and s:sub(i + 1, i + 1):match("[%a/]") then return s:sub(i, j) end
    end
    return nil
end

local function stretch(s)
    local hit = cache[s]
    if hit then return hit end

    local txt, vow, isLetter, n = {}, {}, {}, 0
    local visible, letters = 0, 0
    local i, len = 1, #s
    while i <= len do
        local keep = keepAt(s, i)
        n = n + 1
        if keep then
            txt[n] = keep
            i = i + #keep
        else
            local c = s:sub(i, i)
            txt[n] = MAP[c] or c
            vow[n] = VOWEL[c] and true or false
            local letter = (c:match("%a") ~= nil) or (c:byte() or 0) >= 128
            isLetter[n] = letter
            visible = visible + 1
            if letter then letters = letters + 1 end
            i = i + 1
        end
    end

    local result
    if letters == 0 then
        result = s
    else
        local extra = math.floor(visible * 0.4 + 0.5)
        if extra < 1 then extra = 1 end
        local cands = {}
        for k = 1, n do if vow[k] then cands[#cands + 1] = k end end
        if #cands == 0 then
            for k = 1, n do if isLetter[k] then cands[#cands + 1] = k end end
        end
        local dup = {}
        local nc = #cands
        local given = 0
        for ci = 1, nc do
            local upto = math.floor(ci * extra / nc)
            dup[cands[ci]] = upto - given
            given = upto
        end
        local parts = {}
        for k = 1, n do
            local d = dup[k]
            if d and d > 0 then parts[k] = string.rep(txt[k], d + 1) else parts[k] = txt[k] end
        end
        result = "[" .. table.concat(parts) .. "]"
    end

    cache[s] = result
    count = count + 1
    order[count] = s
    if count - head + 1 > CACHE_MAX then
        cache[order[head]] = nil
        order[head] = nil
        head = head + 1
    end
    return result
end

local TPL_MAX = 8000
local tpl, tplCount, tplLang = {}, 0, nil

local function languageNow()
    local ok, l = pcall(function() return Translator.getLanguage() end)
    if ok then return l end
    return nil
end

local function lookup(key)
    local t = tpl[key]
    if t ~= nil then
        if t == false then return nil end
        return t
    end
    local s = nil
    if getTextOrNull then
        s = getTextOrNull(key, "%1", "%2", "%3", "%4")
    elseif getText then
        s = getText(key, "%1", "%2", "%3", "%4")
        if s == key then s = nil end
    end
    if tplCount >= TPL_MAX then tpl, tplCount = {}, 0 end
    if s ~= nil then tpl[key] = s else tpl[key] = false end
    tplCount = tplCount + 1
    return s
end

LC93._trGen = LC93._trGen or 0
checkLanguage = function()
    local l = languageNow()
    if l ~= tplLang then
        tplLang = l
        tpl, tplCount = {}, 0
        LC93._trGen = LC93._trGen + 1
    end
end

local UPPER_MAX = 512
local upCache, upOrder, upHead, upCount = {}, {}, 1, 0
local upGen = -1
local turkic = false
local UPC = nil
local DOTTED_I = string.char(304)

local function buildUpperTable()
    local m = {}
    local function put(lo, hi) m[lo] = string.char(hi) end
    for c = 224, 254 do if c ~= 247 then put(c, c - 32) end end
    put(223, 223)
    put(255, 376)
    for c = 257, 311, 2 do put(c, c - 1) end
    for c = 314, 328, 2 do put(c, c - 1) end
    for c = 331, 375, 2 do put(c, c - 1) end
    for c = 378, 382, 2 do put(c, c - 1) end
    put(305, 73)
    put(383, 83)
    put(537, 536)
    put(539, 538)
    for c = 945, 969 do put(c, c - 32) end
    put(962, 931)
    put(940, 913)
    put(941, 917)
    put(942, 919)
    put(943, 921)
    put(972, 927)
    put(973, 933)
    put(974, 937)
    put(912, 938)
    put(944, 939)
    for c = 1072, 1103 do put(c, c - 32) end
    for c = 1104, 1119 do put(c, c - 80) end
    for c = 1121, 1153, 2 do put(c, c - 1) end
    for c = 1163, 1215, 2 do put(c, c - 1) end
    for c = 1218, 1230, 2 do put(c, c - 1) end
    put(1231, 1216)
    for c = 1233, 1327, 2 do put(c, c - 1) end
    return m
end

local function turkicNow()
    local ok, name = pcall(function() return Translator.getLanguage():name() end)
    if not ok then return false end
    return name == "TR" or name == "AZ"
end

function LC93.upper(s)
    if s == nil then return "" end
    if type(s) ~= "string" then s = tostring(s) end
    testOn()
    if upGen ~= LC93._trGen then
        upGen = LC93._trGen
        turkic = turkicNow()
        upCache, upOrder, upHead, upCount = {}, {}, 1, 0
    end
    local hit = upCache[s]
    if hit then return hit end

    local result
    if not s:find("[^ -~]") and not (turkic and s:find("i", 1, true)) then
        result = string.upper(s)
    else
        if not UPC then UPC = buildUpperTable() end
        local parts = {}
        for i = 1, #s do
            local c = s:byte(i)
            local r
            if c < 128 then
                if c >= 97 and c <= 122 then
                    if c == 105 and turkic then r = DOTTED_I else r = string.char(c - 32) end
                else
                    r = s:sub(i, i)
                end
            else
                r = UPC[c]
                if r == nil then
                    local ch = s:sub(i, i)
                    r = string.upper(ch)
                    if #r ~= 1 then r = ch end
                end
            end
            parts[i] = r
        end
        result = table.concat(parts)
    end

    upCache[s] = result
    upCount = upCount + 1
    upOrder[upCount] = s
    if upCount - upHead + 1 > UPPER_MAX then
        upCache[upOrder[upHead]] = nil
        upOrder[upHead] = nil
        upHead = upHead + 1
    end
    return result
end

local _f1, _f2, _f3, _f4 = nil, nil, nil, nil
local function fillOne(d)
    local v
    if d == "1" then v = _f1 elseif d == "2" then v = _f2 elseif d == "3" then v = _f3 else v = _f4 end
    if v == nil then return "" end
    return tostring(v)
end
local function fill(s, a1, a2, a3, a4)
    if a1 == nil and a2 == nil and a3 == nil and a4 == nil then return s end
    _f1, _f2, _f3, _f4 = a1, a2, a3, a4
    local out = s:gsub("%%([1-4])", fillOne)
    _f1, _f2, _f3, _f4 = nil, nil, nil, nil
    return out
end

local TRM_MAX = 4000
local SEP, NILA = string.char(1), string.char(2)
local trm, trmN, trmGen, trmOn = {}, 0, nil, nil
function LC93.tr(key, ...)
    if key == nil then return "" end
    if type(key) ~= "string" then key = tostring(key) end
    local a1, a2, a3, a4 = ...
    if type(a1) == "number" then a1 = tostring(a1) end
    if type(a2) == "number" then a2 = tostring(a2) end
    if type(a3) == "number" then a3 = tostring(a3) end
    if type(a4) == "number" then a4 = tostring(a4) end

    local on = testOn()
    if trmGen ~= LC93._trGen or trmOn ~= on or trmN >= TRM_MAX then trm, trmN, trmGen, trmOn = {}, 0, LC93._trGen, on end
    local mk = nil
    if a3 == nil and a4 == nil and (a1 == nil or type(a1) == "string") and (a2 == nil or type(a2) == "string") then
        if a1 == nil and a2 == nil then mk = key
        else mk = key .. SEP .. (a1 or NILA) .. SEP .. (a2 or NILA) end
        local hit = trm[mk]
        if hit then return hit end
    end
    local raw = lookup(key)
    if raw == nil then raw = defaults[key] end
    if raw == nil then return key end
    if on then raw = stretch(raw) end
    local out = fill(raw, a1, a2, a3, a4)
    if mk then
        trm[mk] = out
        trmN = trmN + 1
    end
    return out
end
