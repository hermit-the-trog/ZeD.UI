-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModReset.lua
-- ============================================================================
-- A MOD'S SETTINGS BACK TO ITS DEFAULTS (director, Oct 25 2026: "add a setting in
-- the mod manager to reset each mods settings (ini, settings....) to default";
-- design delegated)
--
-- What a mod keeps as the player's settings, and where:
--   * its PZAPI options: ModOptions.ini, one file for every mod. Reset puts its
--     options back to the values it declared (ZeD_ModSettings.defaults, which
--     keeps the other mods' lines and leaves key binds to the Options window).
--   * its own files in Zomboid/Lua. Lua can write only there (getFileWriter,
--     and only .ini .cfg .txt .json .log), so every settings file a mod keeps for
--     the player is in that folder. Found by reading the mod's own Lua:
--       - every quoted file name with one of those endings ("MyMod.ini",
--         "MyMod/settings.txt", a constant, a table of file names);
--       - the quoted start of a name built in a getFileWriter / getFileReader
--         call ("that_damn_" .. side, "MyMod/" .. name): the files starting so;
--       - files in Zomboid/Lua whose names hold the mod id, and the folder
--         Zomboid/Lua/<mod id>.
--     Only files that are there and hold something are listed. The game's own
--     files (ModOptions.ini, the key file, pz_modlist_settings.cfg ...) and
--     ZeD's are never listed.
--   * the Build 41 "Mod Options" library's mods_options.ini: one file for every
--     mod, a [section] each. Its part for the mod (the mod id, or the mod_id the
--     mod's code gives the library) is taken out; the rest stays. (That library
--     has no Build 42 folder, so it does not load in 42; a file left from 41 is
--     still handled.)
--
-- Nothing is lost: each file is copied first to Zomboid/Lua/ZeD_reset/<mod id>/
-- <yyyy-mm-dd_hhmm>/ (ModOptions.ini too, before its options change), the copy
-- read back, and only then is the file emptied. The game gives Lua no way to
-- delete or move a file (LuaManager.GlobalObject in 42.21 has getFileWriter,
-- getFileReader, listFilesInZomboidLuaDirectory and nothing that removes one),
-- so an emptied file is as near to "no file" as Lua can reach: a mod reading it
-- finds no lines and starts from its own defaults. A running mod still holds its
-- old values until a reload runs its code again.
--
-- Its code is read a little per frame while its Options tab is open (some mods
-- have hundreds of files). A mod that is on: every file the game loaded from it.
-- A mod that is off: the files in its media/lua/client, shared and server.
--
--   R.find(modId)    { files = { { path, why, lines } }, b41 = { sections } or nil, any } once read, else nil
--   R.plan(modId)    what Reset would do: { options = n, files = { path... }, any }
--   R.reset(modId)   do it: { options = bool, files = n, failed = n, folder = "ZeD_reset/<id>/<stamp>", reload = bool }
--   R.forget()       read afresh (the Mods screen opens, after a reset)
-- ============================================================================
require "ZeD/ZeD_ModSettings"
ZeD = ZeD or {}
ZeD.ModReset = ZeD.ModReset or {}
local R = ZeD.ModReset
local S = ZeD.ModSettings

R.BACKUP = "ZeD_reset"
local B41_FILE = "mods_options.ini"
local OPTIONS_FILE = "ModOptions.ini"
local LINES_PER_FRAME = 4000

-- what getFileWriter will write (LuaManager.ALLOWED_FILE_EXTENSIONS, 42.21)
local EXT = { ini = true, cfg = true, txt = true, json = true, log = true }
-- the game's own files in Zomboid/Lua (lower case)
local VANILLA = { ["modoptions.ini"] = true, ["pz_modlist_settings.cfg"] = true, ["keysb42.ini"] = true, ["keys.ini"] = true,
                  ["layout.ini"] = true, ["entitylayout.ini"] = true, ["emote.ini"] = true, ["host.ini"] = true, ["invited.ini"] = true,
                  ["cheatpanel.ini"] = true, ["screenresolution.ini"] = true, ["luaglobals.log"] = true, ["foragemissingitems.log"] = true,
                  ["statisticsdebug.log"] = true, ["saved_outfits.txt"] = true, ["saved_builds.txt"] = true, [B41_FILE] = true }
-- ZeD's own files and its tests' (never another mod's settings)
local OWN = { "zed_", "zedqa", "zqa_", "zed-" }

local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end
local function lower(s) return string.lower(tostring(s or "")) end
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function excluded(lp)
    if VANILLA[lp] then return true end
    if not EXT[lp:match("%.(%w+)$") or ""] then return true end
    local base = lp:match("([^/]+)$") or lp
    for _, p in ipairs(OWN) do
        if base:sub(1, #p) == p or lp:sub(1, #p) == p then return true end
    end
    return false
end

-- ----------------------------------------------------------------------------
-- ZOMBOID/LUA: listing, reading, writing
-- ----------------------------------------------------------------------------
local dirs = {}    -- folder ("" the top) -> { lower name -> name }
local function listing(dir)
    local t = dirs[dir]
    if t then return t end
    t = {}
    local l = safe(listFilesInZomboidLuaDirectory, dir)
    for i = 0, (l and l:size() or 0) - 1 do
        local n = tostring(l:get(i))
        t[lower(n)] = n
    end
    dirs[dir] = t
    return t
end

-- the lines of Zomboid/Lua/<path>; nil when it is not there
local function readLua(path)
    local r = safe(getFileReader, path, false)
    if not r then return nil end
    local t = {}
    local l = safe(function() return r:readLine() end)
    while l do
        t[#t + 1] = l
        l = safe(function() return r:readLine() end)
    end
    pcall(function() r:close() end)
    return t
end
R.readLua = readLua

local function writeLua(path, lines)
    local w = safe(getFileWriter, path, true, false)
    if not w then return false end
    local ok = pcall(function() for _, l in ipairs(lines) do w:write(l .. "\n") end end)
    pcall(function() w:close() end)
    return ok
end

-- ----------------------------------------------------------------------------
-- READING THE MOD'S CODE
-- ----------------------------------------------------------------------------
-- the mod's Lua files, relative to its folder ("media/lua/client/x.lua")
local function sourceFiles(modId)
    local out, seen = {}, {}
    local mi = safe(getModInfoByID, modId)
    if not mi then return out end
    local roots = {}
    for _, get in ipairs({ "getVersionDir", "getCommonDir" }) do
        local dir = safe(function() return mi[get](mi) end)
        if dir then roots[lower((tostring(dir):gsub("\\", "/")))] = true end
    end
    local function add(rel)
        local k = lower(rel)
        if not seen[k] then seen[k] = true; out[#out + 1] = rel end
    end
    if ZeD.ModScan and ZeD.ModScan.isLoaded(modId) then
        for i = 0, (getLoadedLuaCount() or 0) - 1 do
            local raw = tostring(getLoadedLua(i)):gsub("\\", "/")
            local at = lower(raw):find("/media/", 1, true)
            if at and roots[lower(raw:sub(1, at - 1))] then add(raw:sub(at + 1)) end
        end
    end
    for _, dir in ipairs({ "media/lua/client", "media/lua/shared", "media/lua/server" }) do
        local l = safe(listFilesInModDirectory, modId, dir)
        for i = 0, (l and l:size() or 0) - 1 do
            local n = tostring(l:get(i))
            if lower(n):sub(-4) == ".lua" then add(dir .. "/" .. n) end
        end
    end
    return out
end

-- one line of code: the file names it quotes, a built name's quoted start, the B41 library's mod_id
local function scanQuoted(acc, s)
    local p = s:gsub("\\\\", "/"):gsub("\\", "/")
    if not EXT[lower(p):match("%.(%w+)$") or ""] then return end
    if not p:match("^[%w_%-%. /]+$") or p:find("..", 1, true) or lower(p):sub(1, 6) == "media/" then return end
    acc.names[lower(p)] = p
end

function R.scanLine(acc, line)
    for s in line:gmatch('"([^"]*)"') do scanQuoted(acc, s) end
    for s in line:gmatch("'([^']*)'") do scanQuoted(acc, s) end
    for pre in line:gmatch("get%a*File%a*%s*%(%s*[\"']([^\"']+)[\"']%s*%.%.") do
        if pre:match("^[%w_%-%./]+$") and not pre:find("..", 1, true) then acc.prefixes[lower(pre)] = pre end
    end
    for id in line:gmatch("mod_id%s*=%s*[\"']([^\"']+)[\"']") do acc.b41[trim(id)] = true end
end

-- ----------------------------------------------------------------------------
-- WHAT IS THERE
-- ----------------------------------------------------------------------------
local function splitPath(path)
    local dir, name = path:match("^(.*)/([^/]+)$")
    if not dir then return "", path end
    return dir, name
end

local function addFound(res, seen, path, why)
    local dir, name = splitPath(path)
    local real = listing(dir)[lower(name)]
    if not real then return end
    local p = (dir ~= "" and (dir .. "/") or "") .. real
    local lp = lower(p)
    if seen[lp] or excluded(lp) or lp:sub(1, #R.BACKUP + 1) == lower(R.BACKUP) .. "/" then return end
    seen[lp] = true
    local lines = readLua(p)
    if lines and #lines > 0 then res.files[#res.files + 1] = { path = p, why = why, lines = #lines } end
end

local function addPrefix(res, seen, pre)
    local dir, start = pre:match("^(.*)/([^/]*)$")
    if not dir then dir, start = "", pre end
    if dir == "" and #start < 4 then return end   -- a short bare start would take other mods' files
    local ls = lower(start)
    for ln, real in pairs(listing(dir)) do
        if ls == "" or ln:sub(1, #ls) == ls then addFound(res, seen, (dir ~= "" and (dir .. "/") or "") .. real, "named") end
    end
end

-- the B41 library's file: the [sections] that are this mod's
local function b41Part(job)
    if not listing("")[B41_FILE] then return nil end
    local ids = { [job.modId] = true }
    for k in pairs(job.b41) do ids[k] = true end
    local secs = {}
    for _, l in ipairs(readLua(B41_FILE) or {}) do
        local s = l:match("^%s*%[([^%]]+)%]%s*$")
        if s and ids[trim(s)] then secs[#secs + 1] = trim(s) end
    end
    if #secs == 0 then return nil end
    return { path = B41_FILE, sections = secs }
end

local function resolve(job)
    local res = { files = {} }
    local seen = {}
    for _, p in pairs(job.names) do addFound(res, seen, p, "named") end
    for _, pre in pairs(job.prefixes) do addPrefix(res, seen, pre) end
    local id = lower(job.modId)
    if #id >= 4 then
        for ln, real in pairs(listing("")) do if ln:find(id, 1, true) then addFound(res, seen, real, "id") end end
        for _, real in pairs(listing(job.modId)) do addFound(res, seen, job.modId .. "/" .. real, "id") end
    end
    table.sort(res.files, function(a, b) return lower(a.path) < lower(b.path) end)
    res.b41 = b41Part(job)
    res.any = #res.files > 0 or res.b41 ~= nil
    return res
end

local jobs = {}    -- mod id -> { src, i, names, prefixes, b41, res }

-- what the mod keeps in Zomboid/Lua; nil while its code is still being read (call each frame)
function R.find(modId)
    if not modId or modId == "ZeD_UI" then return { files = {}, any = false } end
    local j = jobs[modId]
    if not j then
        j = { modId = modId, src = sourceFiles(modId), i = 1, names = {}, prefixes = {}, b41 = {} }
        jobs[modId] = j
    end
    if j.res then return j.res end
    local budget = LINES_PER_FRAME
    while j.i <= #j.src and budget > 0 do
        local lines = S.readLines(modId, j.src[j.i]) or {}
        for _, l in ipairs(lines) do R.scanLine(j, l) end
        budget = budget - math.max(1, #lines)
        j.i = j.i + 1
    end
    if j.i > #j.src then j.res = resolve(j) end
    return j.res
end

function R.forget() jobs, dirs = {}, {} end

-- ----------------------------------------------------------------------------
-- THE RESET
-- ----------------------------------------------------------------------------
local function optionsToReset(modId)
    if not (ZeD.ModScan and ZeD.ModScan.isLoaded(modId)) then return 0 end
    if not S.offDefault(modId) then return 0 end
    return S.count(modId)
end

-- what Reset would do (nil while the code is being read)
function R.plan(modId)
    local res = R.find(modId)
    if not res then return nil end
    local p = { options = optionsToReset(modId), files = {} }
    for _, f in ipairs(res.files) do p.files[#p.files + 1] = f.path end
    if res.b41 then p.files[#p.files + 1] = res.b41.path end
    p.any = p.options > 0 or #p.files > 0
    return p
end

local function stamp()
    return safe(function() return tostring(SimpleDateFormat.new("yyyy-MM-dd_HHmm", Locale.ENGLISH):format(Calendar.getInstance():getTime())) end)
        or tostring(getTimestamp and getTimestamp() or getTimestampMs())
end

-- a backup folder no earlier reset used for these files
local function backupFolder(modId, paths)
    local base = R.BACKUP .. "/" .. tostring(modId):gsub("[^%w_%-%.]", "_") .. "/" .. stamp()
    for k = 1, 50 do
        local f = (k == 1) and base or (base .. "_" .. k)
        local free = true
        for _, p in ipairs(paths) do if readLua(f .. "/" .. p) then free = false end end
        if free then return f end
    end
    return base .. "_" .. getTimestampMs()
end

-- copy, read the copy back, then write the kept lines (none: the file emptied)
local function copyThenWrite(path, folder, keep)
    local lines = readLua(path)
    if not lines then return false end
    local dest = folder .. "/" .. path
    if not writeLua(dest, lines) then return false end
    local back = readLua(dest)
    if not back or #back ~= #lines then return false end
    return writeLua(path, keep and keep(lines) or {})
end

-- mods_options.ini without the mod's [sections]
local function dropSections(secs)
    local drop = {}
    for _, s in ipairs(secs) do drop[s] = true end
    return function(lines)
        local out, skipping = {}, false
        for _, l in ipairs(lines) do
            local s = l:match("^%s*%[([^%]]+)%]%s*$")
            if s then skipping = drop[trim(s)] == true end
            if not skipping then out[#out + 1] = l end
        end
        return out
    end
end

function R.reset(modId)
    local p = R.plan(modId)
    local res = R.find(modId)
    local out = { options = false, files = 0, failed = 0 }
    if not (p and p.any) then return out end
    local all = {}
    for _, f in ipairs(p.files) do all[#all + 1] = f end
    if p.options > 0 then all[#all + 1] = OPTIONS_FILE end
    out.folder = backupFolder(modId, all)
    -- the options: ModOptions.ini copied as it was, then the declared values kept
    if p.options > 0 then
        local lines = readLua(OPTIONS_FILE)
        if lines then writeLua(out.folder .. "/" .. OPTIONS_FILE, lines) end
        out.options = S.defaults(modId) and true or false
    end
    for _, f in ipairs(res.files) do
        if copyThenWrite(f.path, out.folder) then out.files = out.files + 1 else out.failed = out.failed + 1 end
    end
    if res.b41 then
        if copyThenWrite(res.b41.path, out.folder, dropSections(res.b41.sections)) then out.files = out.files + 1 else out.failed = out.failed + 1 end
    end
    out.reload = out.files > 0 and ZeD.ModScan and ZeD.ModScan.isLoaded(modId) or false
    R.forget()
    return out
end
