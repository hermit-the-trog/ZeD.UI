-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModFiles.lua
-- ============================================================================
-- A MOD'S CODE FILES, ONE BY ONE: what the Mods screen's Files tab lists and
-- switches. Client-side; data only (ZeD_MainMenuModsFiles.lua draws the tab).
--
-- How a file is switched off. The game has no list of files to skip. It builds
-- one map of relative path -> file as the mods load, and a later mod's file at
-- the same path replaces an earlier one's (ZomboidFileSystem.loadMod puts every
-- file into activeFileMap, overwriting); LuaManager.LoadDirBase then runs each
-- path once, from that map. ZeD picks (the helper mod, kept last) already holds
-- copies for file picks, so a file switched off is a path the helper holds with
-- a line that does nothing in it (ZeD_ModPicks: off=<path>|<mod id>). The mod's
-- own folder is never written to. A reload puts it in place; the list and the
-- helper's copy are files, so it lasts through a restart until switched back
-- on, and Steam updates of the mod do not undo it (it goes by path).
--
-- Never a path the game has too: the helper's empty copy would replace the
-- game's own file as well, and Lua cannot read the game's files to copy them
-- (ZeD_VanillaLua.lua, a generated list, says which paths those are).
--
-- "Used by": the mod's other files that name this one, read as text: its file
-- name (a require of it) or the table it makes (Foo = {}, Foo = Foo or {},
-- Foo = ISPanel:derive(...)). A name two of the mod's files both make tells
-- nothing and is left out. Reading text can miss a use; the tab says so.
--
-- Errors: Messages writes each place an error came from (mod, file, line) to
-- Zomboid/Lua/ZeD_error_places.txt during the game; the Mods screen reads it at
-- the main menu, where the last game's errors are, so each file shows its own.
-- The error's "Open in Mods" leaves Zomboid/Lua/ZeD_mods_jump.txt for the Mods
-- screen to open at that file.
--
--   F.isGameFile(path)        the game ships this path too (never switched off)
--   F.files(modId)            { { path, key, side, sub, gone } } sorted, the mod's Lua files (key: path in lower case)
--   F.step(modId)             read a frame's share of them (the Files tab, once a frame); the scan once done
--   F.scan(modId)             { byPath = { path -> { bytes, first, lines } } } once read, else nil (reads nothing)
--   F.usedBy(modId, path)     the mod's other files that name this one (sorted), once scanned (reads nothing)
--   F.places(name)            the last game's error places for a mod by its name
--   F.placesOn(name, path)    those on one file; F.errorCount(name) all of them
--   F.setJump / F.takeJump    Open in Mods' target, kept across the trip to the main menu
--   F.forget()                read afresh (the Mods screen opens)
-- ============================================================================
require "ZeD/ZeD_VanillaLua"
require "ZeD/ZeD_ModSettings"
require "ZeD/ZeD_ModPicks"
ZeD = ZeD or {}
ZeD.ModFiles = ZeD.ModFiles or {}
local F = ZeD.ModFiles

F.PLACES_FILE = "ZeD_error_places.txt"
F.JUMP_FILE = "ZeD_mods_jump.txt"
-- a frame's share of the reading: this many lines (a file opened counts as one), and no more than STEP_MS
-- (a line costs tens of microseconds in the game), the clock read every CHECK_EVERY lines
local LINES_PER_FRAME = 4000
local STEP_MS = 6
local CHECK_EVERY = 100
local FIRST_LINES = 4
local SIDES = { "client", "shared", "server" }

local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end
local function lower(s) return string.lower(tostring(s or "")) end
local function slash(s) return (tostring(s or ""):gsub("\\", "/")) end

-- ----------------------------------------------------------------------------
-- THE GAME'S OWN FILES
-- ----------------------------------------------------------------------------
local gameSet, gameDirs = nil, nil
local function gameIndex()
    if gameSet then return end
    gameSet, gameDirs = {}, {}
    local V = ZeD.VanillaLua
    for l in tostring(V and V.list or ""):gmatch("[^\n]+") do
        gameSet[l] = true
        local dir = l:match("^(.*)/[^/]+$")
        if dir then gameDirs[dir] = true end
    end
end

-- the game's build as major.minor ("42.22"), and whether the shipped list was made from it
local function sameBuild()
    local v = safe(function() return tostring(getCore():getVersion()) end) or ""
    local mm = v:match("^(%d+%.%d+)")
    local V = ZeD.VanillaLua
    return mm ~= nil and V ~= nil and mm == V.build
end
F.sameBuild = sameBuild

--- The game ships this path too ("media/lua/client/ISUI/ISInventoryPane.lua", any case). On a
--- game build the list was not made from, a path in one of the game's own sub-folders (ISUI,
--- TimedActions ...) counts as the game's as well: a new file there could be missing from the
--- list. (Not the side folders themselves: every mod has files in client/, and the list is
--- made again with each game update, ZeDUI/tools/mods/vanilla_lua_index.py.)
function F.isGameFile(path)
    gameIndex()
    local p = lower(slash(path))
    local rel = p:match("^media/lua/(.+)$") or p
    if gameSet[rel] then return true end
    if not sameBuild() then
        local dir = rel:match("^(.*)/[^/]+$")
        if dir and dir:find("/", 1, true) and gameDirs[dir] then return true end
    end
    return false
end

-- ----------------------------------------------------------------------------
-- THE MOD'S FILES
-- ----------------------------------------------------------------------------
local fileLists = {}   -- modId -> list
local jobs = {}        -- modId -> scan job

local function roots(modId)
    local mi = safe(getModInfoByID, modId)
    local out = {}
    if not mi then return out end
    for _, get in ipairs({ "getVersionDir", "getCommonDir" }) do
        local dir = safe(function() return mi[get](mi) end)
        if dir then out[lower(slash(dir))] = true end
    end
    return out
end

-- "media/lua/client/ISUI/X.lua" -> "client", "ISUI/X.lua"
local function split(path)
    local side, sub = slash(path):match("^[Mm][Ee][Dd][Ii][Aa]/[Ll][Uu][Aa]/([^/]+)/(.+)$")
    return lower(side or ""), sub or slash(path)
end

local function sideRank(side)
    for i, s in ipairs(SIDES) do if s == side then return i end end
    return #SIDES + 1
end

-- A loaded file's path under its mod's folder ("media/lua/client/X.lua"), when the full path is under
-- one of roots (lower case, forward slashes); else nil. The mod's folder ends before a "/media/", but
-- not always the first one: a Steam library can sit in a folder called Media ("D:/Media/SteamLibrary/
-- ..."), or under /run/media/ on a Steam Deck, so the first "/media/" whose part before it is a root.
local function relIn(raw, rt)
    local lp = lower(raw)
    local at = lp:find("/media/", 1, true)
    while at and not rt[lp:sub(1, at - 1)] do at = lp:find("/media/", at + 1, true) end
    if at and lp:sub(at + 1, at + 10) == "media/lua/" then return raw:sub(at + 1) end
    return nil
end

--- The mod's Lua files: every one the game loaded from it (sub-folders too: listing a mod's
--- folder gives no sub-folders), its top-level client, shared and server files, and the ones
--- switched off (loaded from ZeD picks now, so listed by the list of them). A file switched
--- off that the mod no longer ships (a Steam update took it out) is "gone".
function F.files(modId)
    if fileLists[modId] then return fileLists[modId] end
    local out, seen = {}, {}
    local function add(rel, gone)
        local k = lower(rel)
        if seen[k] then return end
        seen[k] = true
        local side, sub = split(rel)
        out[#out + 1] = { path = rel, key = k, side = side, sub = sub, gone = gone == true }
    end
    local rt = roots(modId)
    local n = safe(getLoadedLuaCount) or 0
    for i = 0, n - 1 do
        local rel = relIn(slash(safe(getLoadedLua, i) or ""), rt)
        if rel then add(rel) end
    end
    for _, side in ipairs(SIDES) do
        local dir = "media/lua/" .. side
        local l = safe(listFilesInModDirectory, modId, dir)
        for i = 0, (l and l:size() or 0) - 1 do
            local nm = tostring(l:get(i))
            if lower(nm):sub(-4) == ".lua" then add(dir .. "/" .. nm) end
        end
    end
    local P = ZeD.ModPicks
    for _, path in ipairs(P.offFor(modId)) do
        local ok = ZeD.ModSettings and ZeD.ModSettings.readLines(modId, path)
        add(path, not ok)
    end
    table.sort(out, function(a, b)
        if a.side ~= b.side then return sideRank(a.side) < sideRank(b.side) end
        return lower(a.sub) < lower(b.sub)
    end)
    fileLists[modId] = out
    return out
end

-- ----------------------------------------------------------------------------
-- READING THEM (sizes, first lines, used by)
-- ----------------------------------------------------------------------------
local function baseName(path) return (slash(path):match("([^/]+)$") or path):gsub("%.[Ll][Uu][Aa]$", "") end
F.baseName = baseName

local function isName(s) return s ~= nil and s:match("^[%a_][%w_]*$") ~= nil and #s >= 3 end

-- the table a line makes at a file's top level (no indent): Foo = {}, Foo = Foo or {}, Foo = X:derive(...)
local function madeName(l)
    local name, rhs = l:match("^([%a_][%w_]*)%s*=%s*(.-)%s*$")
    if name and name ~= "local" and isName(name) then
        if rhs:sub(1, 1) == "{" or rhs:find("derive(", 1, true) or rhs:match("^" .. name .. "%s+or%s+{") then return name end
    end
    return nil
end
local function madeNames(lines)
    local out = {}
    for _, l in ipairs(lines) do
        local nm = madeName(l)
        if nm then out[#out + 1] = nm end
    end
    return out
end
F.madeNames = madeNames

local function now() return safe(getTimestampMs) or 0 end

-- the file being read, kept across frames: a file can be longer than a frame's share
local function openFile(modId, f)
    if f.gone then return nil end
    local r = safe(function() return getModFileReader(modId, f.path, false) end)
    if not r then return nil end
    local c = { r = r, n = 0, bytes = 0, first = {}, made = {}, words = {} }
    c.read = function() return r:readLine() end   -- (one closure a file, not one a line)
    return c
end
local function closeFile(c)
    if c and c.r then
        local r = c.r
        c.r = nil
        pcall(function() r:close() end)
    end
end

local function finish(j)
    -- a name more than one file makes tells nothing about which file a use means
    local makers = {}
    for _, f in ipairs(j.files) do
        local e = j.byPath[f.path]
        if e then for _, nm in ipairs(e.made) do makers[nm] = (makers[nm] or 0) + 1 end end
    end
    for _, f in ipairs(j.files) do
        local e = j.byPath[f.path]
        if e then
            local toks = {}
            local b = baseName(f.path)
            if isName(b) then toks[#toks + 1] = b end
            for _, nm in ipairs(e.made) do if makers[nm] == 1 and nm ~= b then toks[#toks + 1] = nm end end
            e.tokens = toks
        end
    end
    j.res = { byPath = j.byPath, used = {} }
end

-- the job that holds a file open: one at a time (another mod's turn shuts it, and its file is read
-- again from the start when it comes back)
local reading = nil

--- Read a frame's share of the mod's files (a mod can have hundreds, and one file tens of thousands of
--- lines): the Files tab calls this once a frame, and nothing else reads, so the share holds however
--- many rows ask. Lines are counted as they are read; a file longer than the share carries on next
--- frame. Returns the scan once every file is read (as F.scan), else nil.
function F.step(modId)
    local j = jobs[modId]
    if not j then
        j = { files = F.files(modId), i = 1, byPath = {} }
        jobs[modId] = j
    end
    if j.res then return j.res end
    if reading and reading ~= j then closeFile(reading.cur); reading.cur = nil end
    reading = j
    local budget, t0, ops = LINES_PER_FRAME, now(), 0
    while j.i <= #j.files and budget > 0 do
        local f = j.files[j.i]
        local c = j.cur
        if c == nil then
            c = openFile(modId, f) or false
            j.cur = c
            budget, ops = budget - 1, ops + 1
        end
        local ended = true
        if c then
            ended = false
            while budget > 0 do
                local ok, l = pcall(c.read)
                if not ok or l == nil then ended = true; break end
                c.n = c.n + 1
                c.bytes = c.bytes + #l + 1
                if #c.first < FIRST_LINES and l:match("%S") then c.first[#c.first + 1] = { n = c.n, text = l } end
                local nm = madeName(l)
                if nm then c.made[#c.made + 1] = nm end
                for word in l:gmatch("[%a_][%w_]*") do c.words[word] = true end
                budget, ops = budget - 1, ops + 1
                if ops % CHECK_EVERY == 0 and now() - t0 >= STEP_MS then budget = 0 end
            end
            if ended then
                closeFile(c)
                j.byPath[f.path] = { bytes = c.bytes, first = c.first, lines = c.n, made = c.made, words = c.words }
            end
        end
        if ended then j.cur, j.i = nil, j.i + 1 end
        if ops % CHECK_EVERY == 0 and now() - t0 >= STEP_MS then budget = 0 end
    end
    if j.i > #j.files then
        finish(j)
        if reading == j then reading = nil end
    end
    return j.res
end

--- The mod's files once read ({ byPath = { path -> { bytes, first, lines } } }), else nil. Reads nothing
--- (F.step does, once a frame).
function F.scan(modId)
    local j = jobs[modId]
    return j and j.res or nil
end

--- The mod's other files that name this one (paths, sorted); nil while the mod is being read.
function F.usedBy(modId, path)
    local res = F.scan(modId)
    if not res then return nil end
    if res.used[path] then return res.used[path] end
    local out = {}
    local me = res.byPath[path]
    local toks = me and me.tokens or {}
    if #toks > 0 then
        for _, f in ipairs(F.files(modId)) do
            local e = res.byPath[f.path]
            if f.path ~= path and e then
                for _, t in ipairs(toks) do
                    if e.words[t] then out[#out + 1] = f.path; break end
                end
            end
        end
    end
    res.used[path] = out
    return out
end

--- A file's size in words: "812 B", "1.9 KB" (nil while unread).
function F.sizeText(modId, path)
    local res = jobs[modId] and jobs[modId].res
    local e = res and res.byPath[path]
    if not e then return nil end
    if e.bytes < 1024 then return tostring(e.bytes) .. " B" end
    return string.format("%.1f KB", e.bytes / 1024)
end

-- ----------------------------------------------------------------------------
-- ERRORS ON THEIR FILE (written by ZeD_Messages.lua in the game)
-- ----------------------------------------------------------------------------
-- The file: one place a line, tab-separated (a mod's name can hold any other sign):
--   place<TAB>mod name<TAB>file<TAB>line<TAB>function<TAB>count<TAB>message
local placeList = nil
function F.readPlaces(reader)
    placeList = {}
    local r = reader or safe(function() return getFileReader(F.PLACES_FILE, false) end)
    if not r then return placeList end
    local l = safe(function() return r:readLine() end)
    while l do
        local name, file, line, fn, count, msg = l:match("^place\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
        if name then
            placeList[#placeList + 1] = { name = name, file = file, line = tonumber(line), fn = fn, count = tonumber(count) or 1, msg = msg }
        end
        l = safe(function() return r:readLine() end)
    end
    pcall(function() r:close() end)
    return placeList
end

function F.places(name)
    if not placeList then F.readPlaces() end
    local out = {}
    for _, p in ipairs(placeList) do if p.name == name then out[#out + 1] = p end end
    return out
end

--- The error places on one of a mod's files (the game names the file without its folder).
function F.placesOn(name, path)
    local want = lower(slash(path):match("([^/]+)$") or path)
    local out = {}
    for _, p in ipairs(F.places(name)) do if lower(p.file) == want then out[#out + 1] = p end end
    return out
end

function F.errorCount(name)
    local n = 0
    for _, p in ipairs(F.places(name)) do n = n + p.count end
    return n
end

-- ----------------------------------------------------------------------------
-- OPEN IN MODS (from an error card in the game, to the Mods screen at the menu)
-- ----------------------------------------------------------------------------
function F.setJump(name, file)
    local w = safe(function() return getFileWriter(F.JUMP_FILE, true, false) end)
    if not w then return false end
    pcall(function() w:write("jump\t" .. tostring(name) .. "\t" .. tostring(file or "") .. "\n"); w:close() end)
    return true
end

--- The target left by Open in Mods ({ name, file }), once: the file is emptied.
function F.takeJump()
    local r = safe(function() return getFileReader(F.JUMP_FILE, false) end)
    if not r then return nil end
    local l = safe(function() return r:readLine() end)
    pcall(function() r:close() end)
    local name, file = tostring(l or ""):match("^jump\t([^\t]*)\t(.*)$")
    if not name then return nil end
    local w = safe(function() return getFileWriter(F.JUMP_FILE, true, false) end)
    if w then pcall(function() w:close() end) end
    return { name = name, file = file }
end

function F.forget()
    if reading then closeFile(reading.cur); reading = nil end
    fileLists, jobs, placeList = {}, {}, nil
end
