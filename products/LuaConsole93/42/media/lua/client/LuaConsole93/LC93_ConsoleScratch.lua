-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_ConsoleScratch.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the scratchpad: running a box of many lines, its snippets and
-- history on disk.
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_ConsoleScratch.lua by
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

require "LuaConsole93/LC93_ConsoleLog"

LC93 = LC93 or {}
LC93.ConsoleScratch = LC93.ConsoleScratch or {}
local S = LC93.ConsoleScratch
local L = LC93.ConsoleLog

S.HIST_CAP = 200
S.SNIP_FILE = "LuaConsole93_snippets.txt"
S.HIST_FILE = "LuaConsole93_history.txt"
S.NAME_MAX = 40
S.history = S.history or {}
S.snippets = S.snippets or {}
S.rev = S.rev or 0

local function compiler()
    local ls = loadstring
    if type(ls) == "function" then return ls end
    return nil
end

function S.canRun() return compiler() ~= nil end

local function trimRight(s) return (tostring(s or ""):gsub("%s+$", "")) end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

function S.lines(text)
    local out = {}
    for l in (tostring(text or ""):gsub("\r", "") .. "\n"):gmatch("([^\n]*)\n") do out[#out + 1] = l end
    return out
end

function S.lineCount(text)
    local n = 1
    for _ in tostring(text or ""):gmatch("\n") do n = n + 1 end
    return n
end

function S.nameFrom(code)
    for _, l in ipairs(S.lines(code)) do
        local t = trim(l)
        if t ~= "" then
            if #t > S.NAME_MAX then t = t:sub(1, S.NAME_MAX) end
            return t
        end
    end
    return ""
end

local function escapeLine(l)
    if l:sub(1, 2) == "==" or l:sub(1, 1) == "\\" then return "\\" .. l end
    return l
end

function S.encode(blocks, head)
    local out = { head }
    for _, b in ipairs(blocks) do
        out[#out + 1] = (b.name and b.name ~= "") and ("== " .. b.name) or "=="
        for _, l in ipairs(S.lines(b.code)) do out[#out + 1] = escapeLine(l) end
    end
    return table.concat(out, "\n") .. "\n"
end

function S.decode(lines)
    local blocks, cur = {}, nil
    for _, l in ipairs(lines) do
        l = tostring(l):gsub("\r", "")
        if l == "==" or l:sub(1, 3) == "== " then
            cur = { name = trim(l:sub(4)), body = {} }
            blocks[#blocks + 1] = cur
        elseif cur then
            if l:sub(1, 1) == "\\" then l = l:sub(2) end
            cur.body[#cur.body + 1] = l
        end
    end
    for _, b in ipairs(blocks) do
        while #b.body > 0 and b.body[#b.body] == "" do table.remove(b.body) end
        b.code = table.concat(b.body, "\n")
        b.body = nil
    end
    return blocks
end

local function readLines(name)
    local out = {}
    local ok = pcall(function()
        local r = getFileReader(name, false)
        if not r then return end
        while true do
            local l = r:readLine()
            if l == nil then break end
            out[#out + 1] = tostring(l)
        end
        r:close()
    end)
    if not ok then return {} end
    return out
end

local function writeAll(name, text)
    local ok = pcall(function()
        local w = getFileWriter(name, true, false)
        w:write(text)
        w:close()
    end)
    return ok
end

local SNIP_HEAD = "# Lua Console 93 snippets: \"== name\", then its lines. Edit freely; the console reads this when it opens."
local HIST_HEAD = "# Lua Console 93 history: the last runs, oldest first, each after a \"==\" line."

function S.load(force)
    if S._loaded and not force then return end
    S._loaded = true
    S.snippets = {}
    for _, b in ipairs(S.decode(readLines(S.SNIP_FILE))) do
        if b.code ~= "" then S.snippets[#S.snippets + 1] = { name = b.name ~= "" and b.name or S.nameFrom(b.code), code = b.code } end
    end
    S.history = {}
    for _, b in ipairs(S.decode(readLines(S.HIST_FILE))) do
        if b.code ~= "" then S.history[#S.history + 1] = b.code end
    end
    while #S.history > S.HIST_CAP do table.remove(S.history, 1) end
    S.rev = S.rev + 1
end

function S.writeSnippets() return writeAll(S.SNIP_FILE, S.encode(S.snippets, SNIP_HEAD)) end
function S.writeHistory()
    local blocks = {}
    for i, c in ipairs(S.history) do blocks[i] = { code = c } end
    return writeAll(S.HIST_FILE, S.encode(blocks, HIST_HEAD))
end

function S.addHistory(code)
    code = trimRight(code)
    if trim(code) == "" then return false end
    S.load()
    if S.history[#S.history] ~= code then
        S.history[#S.history + 1] = code
        while #S.history > S.HIST_CAP do table.remove(S.history, 1) end
        S.rev = S.rev + 1
        S.writeHistory()
    end
    return true
end

function S.find(name)
    for i, s in ipairs(S.snippets) do if s.name == name then return i end end
    return nil
end

function S.saveSnippet(name, code)
    code = trimRight(code)
    if trim(code) == "" then return nil, false end
    S.load()
    name = trim(name)
    if name == "" then name = S.nameFrom(code) end
    local i = S.find(name)
    if i then
        S.snippets[i].code = code
    else
        S.snippets[#S.snippets + 1] = { name = name, code = code }
        i = #S.snippets
    end
    S.rev = S.rev + 1
    return i, S.writeSnippets()
end

function S.rename(i, name)
    local s = S.snippets[i]
    name = trim(name)
    if not s or name == "" then return false, false end
    local other = S.find(name)
    if other and other ~= i then return false, false end
    s.name = name
    S.rev = S.rev + 1
    return true, S.writeSnippets()
end

local function printed(...)
    local n = select("#", ...)
    local parts = {}
    for i = 1, n do parts[i] = tostring((select(i, ...))) end
    return table.concat(parts, "\t")
end

function S.run(code)
    code = trimRight(code)
    if trim(code) == "" then return nil end
    local ls = compiler()
    if not ls then return "noload" end
    S.addHistory(code)
    L.ranCode(code)
    local okC, fn, cerr = pcall(ls, code, "console")
    if not okC then fn, cerr = nil, fn end
    if type(fn) ~= "function" then
        L.addError(tostring(cerr or "?"), "run")
        return "compile"
    end
    local real = print
    print = function(...)
        local s = printed(...)
        L.output(s)
        return real(...)
    end
    local ok, err = pcall(fn)
    print = real
    if not ok then
        L.addError(tostring(err or "?"), "run")
        return "failed"
    end
    return "ran"
end

return S
