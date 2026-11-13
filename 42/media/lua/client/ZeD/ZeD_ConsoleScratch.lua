-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ConsoleScratch.lua
-- ============================================================================
-- THE CONSOLE'S SCRATCHPAD: running a box of many lines, and the snippets and history kept on disk. No drawing.
-- Client. Logic only (ZeD.ConsoleScratch); ZeD_DebugConsole.lua draws the box and its two lists.
--
-- A run is compiled with loadstring(code, "console") and called with pcall, so it never goes through the game's
-- one line and its 256 characters. The log (ZeD_ConsoleLog.lua) gets a "ran" row first, then what the run printed
-- (print is swapped for the run's length: each line becomes a print row from Console at once, and still reaches the
-- game's box, where the log skips it as already told), then an error row from Console if it did not compile or
-- failed, with the message loadstring or pcall gave.
--
-- Two files in Zomboid/Lua, written whole on each change: ZeD_console_snippets.txt (a block per snippet, "== name"
-- then its lines) and ZeD_console_history.txt (a block per run, "==" then its lines, the last HIST_CAP runs, the
-- oldest dropped first). A line of code that starts with "==" or a backslash is written with a backslash in front.
--
-- The one thing to know: loadstring can go away. 42.20.4 took it out of the game and 42.21 put it back; with none,
-- canRun() is false, the box says why and only the one line runs.
-- ============================================================================

require "ZeD/ZeD_ConsoleLog"

ZeD = ZeD or {}
ZeD.ConsoleScratch = ZeD.ConsoleScratch or {}
local S = ZeD.ConsoleScratch
local L = ZeD.ConsoleLog

S.HIST_CAP = 200                               -- runs kept; the oldest goes first
S.SNIP_FILE = "ZeD_console_snippets.txt"
S.HIST_FILE = "ZeD_console_history.txt"
S.NAME_MAX = 40                                -- a name made from a first line is cut to this many characters
S.history = S.history or {}                    -- the runs, oldest first
S.snippets = S.snippets or {}                  -- { name, code }, in the order saved
S.rev = S.rev or 0                             -- counts every change to either list

-- the game's loadstring, looked up at each call (a sim takes it away to see the box gray)
local function compiler()
    local ls = loadstring
    if type(ls) == "function" then return ls end
    return nil
end

--- Can the scratchpad run? (false: this build of the game has no loadstring)
function S.canRun() return compiler() ~= nil end

-- ---------------------------------------------------------------------------
-- TEXT
-- ---------------------------------------------------------------------------
local function trimRight(s) return (tostring(s or ""):gsub("%s+$", "")) end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

--- The lines of a text, "\r" dropped, an empty text one empty line.
-- (Both walk the text with plain finds, the game's indexOf: Kahlua's gmatch is Lua that runs a match per step, about
-- 20 ms over a 1500-line box.)
function S.lines(text)
    local s = tostring(text or "")
    if string.find(s, "\r", 1, true) then s = string.gsub(s, "\r", "") end
    local out, p = {}, 1
    while true do
        local e = string.find(s, "\n", p, true)
        if not e then
            out[#out + 1] = string.sub(s, p)
            return out
        end
        out[#out + 1] = string.sub(s, p, e - 1)
        p = e + 1
    end
end

--- How many lines a text runs to.
function S.lineCount(text)
    local s = tostring(text or "")
    local n, p = 1, 1
    while true do
        local e = string.find(s, "\n", p, true)
        if not e then return n end
        n, p = n + 1, e + 1
    end
end

--- A snippet's name from its code: the first line with words on it, trimmed and cut to NAME_MAX.
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

-- ---------------------------------------------------------------------------
-- THE FILES
-- ---------------------------------------------------------------------------
local function escapeLine(l)
    if l:sub(1, 2) == "==" or l:sub(1, 1) == "\\" then return "\\" .. l end
    return l
end

--- Blocks as file text: each "== name" (or "==" with no name), then its lines.
function S.encode(blocks, head)
    local out = { head }
    for _, b in ipairs(blocks) do
        out[#out + 1] = (b.name and b.name ~= "") and ("== " .. b.name) or "=="
        for _, l in ipairs(S.lines(b.code)) do out[#out + 1] = escapeLine(l) end
    end
    return table.concat(out, "\n") .. "\n"
end

--- File lines back to blocks { name, code }; the lines before the first block are the file's head.
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
        -- (the blank lines a file ends a block with are not code)
        while #b.body > 0 and b.body[#b.body] == "" do table.remove(b.body) end
        b.code = table.concat(b.body, "\n")
        b.body = nil
    end
    return blocks
end

-- a file of Zomboid/Lua as its lines (none: an empty list)
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

-- a file of Zomboid/Lua written whole; true when it was
local function writeAll(name, text)
    local ok = pcall(function()
        local w = getFileWriter(name, true, false)
        w:write(text)
        w:close()
    end)
    return ok
end

local SNIP_HEAD = "# ZeD-GUI Lua console snippets: \"== name\", then its lines. Edit freely; the console reads this when it opens."
local HIST_HEAD = "# ZeD-GUI Lua console history: the last runs, oldest first, each after a \"==\" line."

--- Read both files (once a game; again with force).
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

-- ---------------------------------------------------------------------------
-- HISTORY AND SNIPPETS
-- ---------------------------------------------------------------------------
--- A run onto the history (not twice in a row), the oldest dropped past HIST_CAP, the file written.
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

--- The snippet of this name (its index), or nil.
function S.find(name)
    for i, s in ipairs(S.snippets) do if s.name == name then return i end end
    return nil
end

--- Save code as a snippet. A name already used takes the new code in its place; no name: from the first line.
--- Returns the snippet's index and whether the file was written.
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

--- A snippet renamed (a name another one has is refused). Returns true and whether the file was written.
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

-- ---------------------------------------------------------------------------
-- RUNNING
-- ---------------------------------------------------------------------------
-- the words one print call makes, as the game's print joins them
local function printed(...)
    local n = select("#", ...)
    local parts = {}
    for i = 1, n do parts[i] = tostring((select(i, ...))) end
    return table.concat(parts, "\t")
end

--- Run code from the scratchpad. Returns "ran", "compile" (did not compile), "failed" (raised an error), "noload"
--- (no loadstring) or nil (nothing to run).
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
    -- (print swapped while the code runs: its lines go to the log at once, and on to the game's)
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
