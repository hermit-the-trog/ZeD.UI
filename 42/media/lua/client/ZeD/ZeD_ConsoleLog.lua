-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ConsoleLog.lua
-- ============================================================================
-- THE CONSOLE'S LOG: the rows the Lua console's Log page shows, with no drawing in it.
-- Client. Logic only (ZeD.ConsoleLog); ZeD_DebugConsole.lua feeds it and draws it.
--
-- Two sources make one list. The game's console box (everything the game prints in debug mode) arrives as text
-- that only grows at its end and loses its front past 8192 characters; the F11 Lua Debugger's error list
-- (getLuaDebuggerErrors) arrives as entries, several to one error. Each new line or error becomes a row: its time,
-- its kind (print, warn, error, ran), its message, the mod and file:line it came from, and for an error its stack.
--
-- The one thing to know: nothing here is rebuilt per frame. A row is added once, counted once and dropped once (the
-- oldest goes past CAP rows); the shown list and the filter counts change with it. Only a new search or a ticked
-- filter walks every row again. The same error seen again is the same row with a higher count, whichever source
-- told it, so an error the box prints and the F11 list keeps is counted once per time it happened.
-- ============================================================================

ZeD = ZeD or {}
ZeD.ConsoleLog = ZeD.ConsoleLog or {}
local L = ZeD.ConsoleLog

L.CAP = 5000           -- rows kept; the oldest goes first
L.FLUSH_MS = 300       -- an error still collecting stack lines becomes a row this long after its last line
L.BOX_KEEPS = 8192     -- the game's console box keeps this many characters, its front dropped past them
L.KINDS = { "print", "warn", "error", "ran" }
L.GAME = "#game"       -- the mod key of lines no mod can be told for (the game's own, or unknown)
L.CONSOLE = "#console" -- the mod key of the lines typed here and the errors they raised
local GAME, CONSOLE = L.GAME, L.CONSOLE

L.rev = L.rev or 0         -- counts every change to the rows
L.viewRev = L.viewRev or 0 -- counts every change to what is shown (a row in or out, a count, an open stack)
L.q = L.q or ""            -- the search, as typed
L.off = L.off or { kind = {}, mod = {}, file = {} }   -- unticked filters: off[group][key] = true

-- ---------------------------------------------------------------------------
-- WORDS: the names a mod key and a file key show as
-- ---------------------------------------------------------------------------
local function tr(k, ...) if ZeD.tr then return ZeD.tr(k, ...) end return k end

--- The name a mod key shows as ("Game", "Console", or the mod's own name).
function L.modName(m)
    if m == GAME then return tr("UI_ZeD_Console_ModGame") end
    if m == CONSOLE then return tr("UI_ZeD_Console_ModConsole") end
    return tostring(m or "")
end
--- The name a file key shows as ("No file" for a line with none).
function L.fileName(f)
    if f == nil or f == "" then return tr("UI_ZeD_Console_NoFile") end
    return f
end
--- The place a row came from, as the row shows it: "file:line", the file alone, or "".
function L.srcOf(r)
    if not r.file or r.file == "" then return "" end
    if r.line then return r.file .. ":" .. tostring(r.line) end
    return r.file
end

-- ---------------------------------------------------------------------------
-- THE CLOCK: the real time of day, for the rows and the export's name
-- ---------------------------------------------------------------------------
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
--- "14:30:05" now. A sim swaps it for its own clock.
function L.clock() return dateText("HH:mm:ss") or "" end
--- "2026-11-12_143005" now: the export's file name part.
function L.stamp() return dateText("yyyy-MM-dd_HHmmss") or "export" end

-- ---------------------------------------------------------------------------
-- READING THE GAME'S TEXT: what starts an error, what goes on with one, where it came from
-- ---------------------------------------------------------------------------
--- A line that starts an error: the log's ERROR lines, a stack trace, a line that did not compile ("console:1: ..."),
--- a bare stack frame (a runtime error typed into the console comes as frames after the [USER] line, no header).
function L.startsError(s)
    if s:find("^ERROR") or s:find("^SEVERE") or s:find("^%s*STACK TRACE") then return true end
    if s:find("console[\"%]]*:%d+:") then return true end
    if s:find("Exception") and not s:find("^LOG") then return true end
    if s:find("^%s*Lua%(") or s:find("^%s*se%.krka") or s:find("^%s*java%.") then return true end
    return false
end
--- A line that goes on with the error above it (its trace).
function L.continuesError(s)
    if s == "" then return false end
    if s:find("^%s") then return true end
    if s:find("^STACK TRACE") or s:find("^%-%-%-%-") or s:find("%-%-%-%-%-%-%-%-%-%-$") then return true end
    if s:find("^Lua%(") or s:find("^Callframe") or s:find("^function: ") or s:find("^Caused by") or s:find("^java%.") or s:find("^se%.krka") then return true end
    return false
end

-- The game's log prefix: its level and the words after it. 42.22.2 writes "LOG  : Lua          f:4821> ", and with
-- its debug options " t:<ms>", " st:<ms>" or " at <caller>" (padded to 36) before the ">"; 42.21 wrote
-- "LOG  : General      f:4821, t:1762935182311> ". Anything up to the first ">" after the frame number is prefix.
local function splitPrefix(s)
    local lvl, rest = s:match("^(%u+)%s*:%s*%S+%s+f:%d+[^>]*>%s?(.*)$")
    if lvl then return lvl, rest end
    return nil, s
end
L.splitPrefix = splitPrefix   -- (for the sims)

--- Every Lua frame in an error's text, top of the stack first: { mod (nil: the game's), fn, file, line }.
--- The game writes a frame three ways: "Lua((MOD:Bandits)).fn(file.lua:12)", "Lua(Vanilla).fn(file.lua:12)" and
--- "function: fn -- file: file.lua line # 12 | MOD: Bandits" (or "| Vanilla").
function L.frames(text)
    local out = {}
    for l in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        local fr = nil
        local a = string.find(l, "Lua((MOD:", 1, true)
        if a then
            -- (up to the ")). " that closes the name: a name may hold a bracket of its own, "Ladders!? (v0.0.13)")
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

--- Where an error came from: the first frame a mod owns (the top frame can be the game's code the mod called), else
--- the top frame. Returns mod key, file, line (file "" and line nil when no frame is named).
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
    -- (a line that did not compile names no frame: '[string "console"]:1: ...' or 'console:1: ...')
    local ln = tostring(msg or ""):match("console[\"%]]*:(%d+):")
    if ln then return CONSOLE, "console", tonumber(ln) end
    return GAME, "", nil
end

local function isHeadLine(t)
    return t:find("^ERROR") or t:find("^SEVERE") or t:find("^%-%-%-%-") or t:find("^STACK TRACE") or t:find("^dumping")
        or t:find("^Callframe") or t:find("^DEBUG%-MODE STACK TRACE") or t:find("^function:") or t:find("^Lua%(") or t:find("^se%.krka") or t:find("^at ")
        -- a bare Java frame ("zombie.ui.UIDebugConsole.ProcessCommand(UIDebugConsole.java:391)") is a head line too
        or t:find("%([%w_%$%.]+%.java:%d+%)$") or t:find("%(Unknown Source%)$") or t:find("%(Native Method%)$")
end
--- An error's message in the game's words: "attempted index: x of non-table: null", with the Java class in front and
--- the "at KahluaThread.tableget(...)." behind taken off; a line that did not compile as the console said it.
--- A text of head lines only (the box's block for an error typed into the console: Java frames and the Lua dump, no
--- "Exception:" line) has no message: "" comes back, its first line second (what its row shows until the F11 list
--- tells the message).
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
    return "", (first or ""):sub(1, 300)
end

-- the active mods by lower-case id and name, found once (a print's "[Tag]" or "Tag:" is matched against them)
local _mods = nil
local function modTable()
    if _mods then return _mods end
    _mods = { zed = "ZeD-GUI" }
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
--- Forget the active mods (a sim, or a new game's list).
function L.forgetMods() _mods = nil end

--- The mod a printed line came from, when it says: "[ZeD] ..." or "Bandits: ..." naming an active mod; else the game.
function L.modOfPrint(msg)
    local tag = msg:match("^%[([^%]]+)%]") or msg:match("^([%w][%w _%-%.!%?']-):%s")
    if not tag then return GAME end
    return modTable()[string.lower(tag)] or GAME
end

-- ---------------------------------------------------------------------------
-- THE ROWS: a ring of at most CAP rows, oldest first; the shown rows, a ring in the same order
-- ---------------------------------------------------------------------------
local function lower(s) return string.lower(s) end

-- The lines a scratchpad run told ahead (L.output): a queue, oldest first, read from its head (first .. last, each
-- { s, at }), and the same lines queued by their words (by[s], h .. t), so a box line costs one lookup whether it
-- was told or not, however many wait. (A list walked from its front, cut to 64, doubled a run's lines past the 64th.)
local function newExpect() return { first = 1, last = 0, by = {} } end

-- the words the search looks in: the message, the mod, the place and every stack line (made once, on first need)
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

--- Empty the log (the band's Clear). The filters and the search stay; the F11 list's errors already read stay read.
function L.clear()
    L.rows, L.first, L.last = {}, 1, 0
    L.vis, L.vfirst, L.vlast = {}, 1, 0
    L.byKey, L.byPlace = {}, {}
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

--- Start again from nothing: no rows, no text seen, no F11 entries read (a new game, or a sim).
function L.reset()
    L.clear()
    L._seen, L._part = nil, ""
    L._f11Seen = 0
    L._ran = {}
    L._expect = newExpect()
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
    if r.place and L.byPlace[r.place] == r then L.byPlace[r.place] = nil end
    if r.kind == "error" then L.errTotal = L.errTotal - (r.n or 1) end
    r.vis = false
end

-- a new row at the end: counted, shown if it passes, the oldest dropped past CAP
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

--- Walk every row again for the search and the filters (only when one of them changed).
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

--- A new search (the field's text); the rows are walked again only when it changed.
function L.setQuery(q)
    q = tostring(q or "")
    if q == L.q then return false end
    L.q = q
    L.refilter()
    return true
end

--- Tick or untick one filter: group "kind" | "mod" | "file", key the kind, the mod key or the file ("" no file).
function L.toggle(group, key)
    local g = L.off[group]
    if not g then return end
    if g[key] then g[key] = nil else g[key] = true end
    L.refilter()
end
--- Is this filter ticked?
function L.isOn(group, key) return not (L.off[group] and L.off[group][key]) end

--- Every filter ticked and the search empty (the "nothing matches" line's way back).
function L.showAll()
    L.off = { kind = {}, mod = {}, file = {} }
    L.q = ""
    L.refilter()
end

--- Rows shown, rows kept, error rows shown.
function L.counts() return L.vlast - L.vfirst + 1, L.last - L.first + 1, L.shownErr end
--- The i-th shown row, oldest first (1 .. shown).
function L.shownAt(i) return L.vis[L.vfirst + i - 1] end
--- Where a row sits among the shown rows (nil when it is not shown).
function L.indexOf(r)
    if not r or not r.vis then return nil end
    for i = L.vfirst, L.vlast do if L.vis[i] == r then return i - L.vfirst + 1 end end
    return nil
end

-- ---------------------------------------------------------------------------
-- ERRORS: one row per error, the same error again counted on it
-- ---------------------------------------------------------------------------
local function splitLines(text)
    local out = {}
    for l in (tostring(text or ""):gsub("\r", ""):gsub("\t", "    ") .. "\n"):gmatch("([^\n]*)\n") do
        if l ~= "" then out[#out + 1] = l end
    end
    return out
end

-- the row an error at a place joins: the newest row at that file:line when it has no message yet (the box told it,
-- the F11 list not yet), or, for an error told without a message, when the other source told it more often than this
-- one (this source's twin not told yet)
local function rowAtPlace(place, k, noMsg)
    local r = place and L.byPlace[place]
    if not r then return nil end
    if r.noMsg then return r end
    if not noMsg then return nil end
    local other = k == "nF11" and "nBox" or "nF11"
    if (r[k] or 0) < (r[other] or 0) then return r end
    return nil
end

-- a row taken out of the log wherever it sits (a row without a message folded into its twin)
local function removeRow(s)
    local at = nil
    for i = L.last, L.first, -1 do if L.rows[i] == s then at = i; break end end
    if not at then return end
    for i = at, L.last - 1 do L.rows[i] = L.rows[i + 1] end
    L.rows[L.last] = nil
    L.last = L.last - 1
    if s.m then count(s, -1) end
    dropName(L.mods, L.all.mod, s.mod)
    dropName(L.files, L.all.file, s.file or "")
    if s.vis then
        for i = L.vlast, L.vfirst, -1 do
            if L.vis[i] == s then
                for j = i, L.vlast - 1 do L.vis[j] = L.vis[j + 1] end
                L.vis[L.vlast] = nil
                L.vlast = L.vlast - 1
                L.shownErr = L.shownErr - 1
                break
            end
        end
    end
    if L.byKey[s.key] == s then L.byKey[s.key] = nil end
    if s.place and L.byPlace[s.place] == s then L.byPlace[s.place] = nil end
    L.errTotal = L.errTotal - (s.n or 1)
    s.vis = false
end

-- an error with its message that already has a row, while the box told it a moment ago without one (a row at the same
-- place, no message, newer): that row is this sighting's box twin, so its sightings join the row and it goes
local function foldTwin(r, place, k)
    local s = place and L.byPlace[place]
    if not s or s == r or not s.noMsg then return end
    local other = k == "nF11" and "nBox" or "nF11"
    if (r[k] or 0) < (r[other] or 0) then return end
    removeRow(s)
    r[other] = (r[other] or 0) + (s[other] or 0)
    if #s.stack > #r.stack then r.stack, r.hay = s.stack, nil end
end

--- An error, told by a source ("box": the console's box, "f11": the error list), from its whole text. The same message
--- from the same place is the same row: each source counts its own sightings and the row shows the larger count, so
--- one error both sources tell counts once. The box tells an error typed into the console without its message (only
--- Java frames and the Lua dump): that row is found by its place, and takes the message when the F11 list tells it.
function L.addError(text, source, t)
    local msg, first = L.messageOf(text)
    local mod, file, line = L.placeOf(text, msg)
    local place = (file ~= nil and file ~= "" and line ~= nil) and (tostring(file) .. ":" .. tostring(line)) or nil
    local noMsg = msg == "" and place ~= nil
    if msg == "" and not noMsg then msg = first or "" end
    local key = msg .. "|" .. tostring(file) .. ":" .. tostring(line)
    local stack = splitLines(text)
    local k = source == "f11" and "nF11" or "nBox"
    local r = L.byKey[key]
    if not r or noMsg then r = rowAtPlace(place, k, noMsg) or r
    elseif not noMsg then foldTwin(r, place, k) end
    if r and r.noMsg and not noMsg then
        -- the message at last: the row takes it and its key
        if L.byKey[r.key] == r then L.byKey[r.key] = nil end
        r.msg, r.key, r.noMsg, r.hay = msg, key, nil, nil
        L.byKey[key] = r
        local was = r.m
        r.m = matches(r)
        if was ~= r.m then L.refilter() end
    end
    if r then
        -- (a newer row still without its message keeps the place: the F11 list's word for it comes next)
        local p = place and L.byPlace[place]
        if place and not (p and p ~= r and p.noMsg) then L.byPlace[place] = r end
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
    r = { t = t or L.clock(), kind = "error", msg = noMsg and (first or "") or msg, mod = mod, file = file, line = line,
        stack = stack, key = key, place = place, noMsg = noMsg or nil }
    r[k] = 1
    L.byKey[key] = r
    if place then L.byPlace[place] = r end
    return add(r)
end

--- A line run from the console ("ran"), put in before what it prints.
function L.ran(line, t)
    line = tostring(line or "")
    L._ran = L._ran or {}
    L._ran[#L._ran + 1] = line
    if #L._ran > 8 then table.remove(L._ran, 1) end
    return add({ t = t or L.clock(), kind = "ran", msg = "> " .. line, mod = CONSOLE, file = "" })
end

--- Code run from the scratchpad ("ran"): its first line, and how many more it has.
function L.ranCode(code, t)
    code = tostring(code or "")
    local first = code:match("^([^\n]*)") or ""
    local more = 0
    for _ in code:gmatch("\n") do more = more + 1 end
    local msg = "> " .. first
    if more > 0 then msg = msg .. "  " .. tr("UI_ZeD_Console_RanMore", more) end
    return add({ t = t or L.clock(), kind = "ran", msg = msg, mod = CONSOLE, file = "", code = code })
end

L.EXPECT_MS = 10000    -- a line told ahead (L.output) waits this long for the box to print it
L.EXPECT_CAP = 4096    -- and at most this many wait: the most lines the box's 8192 characters hold

-- the oldest line told ahead off the queue, and off its words' queue unless the box already printed it
local function dropExpect(e)
    local x = e[e.first]
    e[e.first] = nil
    e.first = e.first + 1
    if x and not x.done then
        x.done = true
        -- (the oldest line of the queue is the oldest of its words too)
        local q = e.by[x.s]
        if q and q[q.h] == x then
            q[q.h] = nil
            q.h = q.h + 1
            if q.h > q.t then e.by[x.s] = nil end
        end
    end
end

--- A line a scratchpad run printed: a print row from Console now. The same words reach the game's box a frame
--- later; the box's copy is skipped, once, as already told.
function L.output(text, t, ms)
    text = tostring(text or ""):gsub("\r", ""):gsub("\t", "    ")
    ms = ms or (getTimestampMs and getTimestampMs()) or 0
    local e = L._expect
    if not (e and e.by) then e = newExpect(); L._expect = e end
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        add({ t = t or L.clock(), kind = "print", msg = line, mod = CONSOLE, file = "" })
        local x = { s = line, at = ms }
        e.last = e.last + 1
        e[e.last] = x
        local q = e.by[line]
        if not q then q = { h = 1, t = 0 }; e.by[line] = q end
        q.t = q.t + 1
        q[q.t] = x
        while e.last - e.first + 1 > L.EXPECT_CAP do dropExpect(e) end
    end
end

-- a box line already told by L.output: the oldest line told with its words is taken off, once
local function expected(msg)
    local e = L._expect
    local q = e and e.by and e.by[msg]
    if not q then return false end
    local x = q[q.h]
    q[q.h] = nil
    q.h = q.h + 1
    if q.h > q.t then e.by[msg] = nil end
    x.done = true
    -- (the queue's head loses the lines the box has printed)
    while e.first <= e.last and e[e.first].done do
        e[e.first] = nil
        e.first = e.first + 1
    end
    return true
end

-- ---------------------------------------------------------------------------
-- THE BOX: the game's console text, read for what is new since the last read
-- ---------------------------------------------------------------------------
local function closeBlock()
    local b = L._blk
    L._blk = nil
    if b then L.addError(table.concat(b.lines, "\n"), "box", b.t) end
end

-- One print reaches the box twice while the game's console has its print callback: once bare (UIDebugConsole.addOutput)
-- and once through the log stream with its "LOG  : Lua  f:N> " in front, in either order. A bare line and a prefixed
-- line of the same words within TWIN_MS are one print: the second is skipped. Two prints of the same words come both
-- prefixed (or both bare), so they stay two rows. Returns true when this line is the twin of one already seen.
L.TWIN_MS = 3000
L.TWIN_CAP = 64
local function twinOf(msg, prefixed, ms)
    ms = tonumber(ms) or 0
    local q = L._twins
    if not q then q = {}; L._twins = q end
    for i = 1, #q do
        local x = q[i]
        if x.msg == msg and x.pref ~= prefixed and math.abs(ms - x.at) <= L.TWIN_MS then
            table.remove(q, i)
            return true
        end
    end
    q[#q + 1] = { msg = msg, pref = prefixed, at = ms }
    -- (old lines leave from the front: too old to pair, or past the cap)
    while #q > 0 and (#q > L.TWIN_CAP or ms - q[1].at > L.TWIN_MS) do table.remove(q, 1) end
    return false
end
L._twinOf = twinOf   -- (for the sims)

-- one whole line of the box
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
    -- the console's echo of a line run here: the "ran" row is already in
    local echo = s:match("^%[USER%]%s?(.*)$")
    if echo then
        -- (42.22 writes it [USER] - "line".)
        echo = echo:match('^%-%s"(.*)"%.?$') or echo
        for i, r in ipairs(L._ran or {}) do
            if r == echo then table.remove(L._ran, i); return end
        end
        add({ t = t, kind = "ran", msg = "> " .. echo, mod = CONSOLE, file = "" })
        return
    end
    local lvl, msg = splitPrefix(s)
    local kind = (lvl == "WARN") and "warn" or "print"
    if kind == "print" and twinOf(msg, lvl ~= nil, ms) then return end
    if kind == "print" and expected(msg) then return end
    add({ t = t, kind = kind, msg = msg, mod = L.modOfPrint(msg), file = "" })
end

-- where the new part of the box starts: the box only grows at its end, and past 8192 characters it loses its front,
-- so what was there before is the start of what is there now (the longest such overlap wins). With no overlap the box
-- was cleared (all of it is new), or more than 8192 characters came at once: then its first line is cut and is skipped.
-- Returns where the new part starts and true when it does not go on from the last text.
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

--- The game's console box as it stands now: the lines new since the last call become rows. A line the box has not
--- finished (no newline yet) waits; an error collecting its stack waits until a line that is not part of it comes,
--- or L.tick finds it FLUSH_MS old. ms: getTimestampMs().
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

-- ---------------------------------------------------------------------------
-- THE F11 LIST: the game keeps its last 40 entries and counts every one it adds, so the new entries are the count's
-- rise, read from the list's end. One error is several entries: a separator with the message, "dumping Lua stack
-- trace" with the Lua stack, the exception, then (in -debug) the Java stack.
-- ---------------------------------------------------------------------------
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

--- Read the F11 list's new entries. list: getLuaDebuggerErrors() (a Java list), n: getLuaDebuggerErrorCount().
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

--- Each frame: an error still collecting lines becomes a row once FLUSH_MS has passed since its last line.
function L.tick(ms)
    ms = ms or 0
    if L._blk and ms - (L._blk.at or 0) >= L.FLUSH_MS then closeBlock() end
    if L._f11 and ms - (L._f11.at or 0) >= L.FLUSH_MS then closeF11() end
    local e = L._expect
    while e and e.by and e.first <= e.last and ms - (e[e.first].at or 0) >= L.EXPECT_MS do dropExpect(e) end
end

-- ---------------------------------------------------------------------------
-- COPY AND EXPORT: rows as text, and the shown rows written to Zomboid/Lua/ZeD_console_<date>_<time>.log
-- ---------------------------------------------------------------------------
local KIND_KEY = { print = "UI_ZeD_Console_WordPrint", warn = "UI_ZeD_Console_WordWarn", error = "UI_ZeD_Console_WordError", ran = "UI_ZeD_Console_WordRan" }
--- The short word a row's kind shows as (print, warn, error, ran).
function L.kindWord(kind) return tr(KIND_KEY[kind] or KIND_KEY.print) end

--- One row as text: "14:30:05 | error | message | Mod file:line | x37", then its stack, each line indented.
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

--- What the filters show, as text (Copy all, Export).
function L.shownText()
    local out = {}
    for i = L.vfirst, L.vlast do L.rowText(L.vis[i], out) end
    return table.concat(out, "\n")
end

-- the user name out of a path before the text leaves the game (the Messages window's own scrub), when it is loaded
local function scrubbed(text)
    local M = ZeD.Messages
    if M and M.scrub then
        local ok, s = pcall(M.scrub, text)
        if ok and s then return s end
    end
    return text
end
L.scrubbed = scrubbed

--- A new file name for an export, named for the time; a second export in the same second gets "_2" and so on.
function L.exportName()
    local base = "ZeD_console_" .. L.stamp()
    local name = base .. ".log"
    if L._lastBase == base then
        L._sameN = (L._sameN or 1) + 1
        name = base .. "_" .. tostring(L._sameN) .. ".log"
    else
        L._lastBase, L._sameN = base, 1
    end
    return name
end

--- Write the shown rows to a new .log file in Zomboid/Lua. Returns the file's name and how many rows went in, or nil.
function L.export()
    local name = L.exportName()
    local shown, total, errs = L.counts()
    local head = "ZeD-GUI Lua console | " .. tostring(L.stamp()) .. " | " .. shown .. " of " .. total .. " | errors " .. errs
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
