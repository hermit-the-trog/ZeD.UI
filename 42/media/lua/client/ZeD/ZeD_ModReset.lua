-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModReset.lua
-- ============================================================================
-- A MOD'S SETTINGS BACK TO ITS DEFAULTS: the mod manager's Reset. Client-side;
-- no drawing (the Mods screen calls R.find / R.plan / R.reset below).
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
                  ["statisticsdebug.log"] = true, ["saved_outfits.txt"] = true, ["saved_builds.txt"] = true, [B41_FILE] = true,
                  -- the game's server lists (an id such as "server" or "list" must never take them) (beast W52)
                  ["serverlist.txt"] = true, ["serverliststeam.txt"] = true }
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

-- the lines of Zomboid/Lua/<path>; nil when it is not there, or did not read to its end (a part
-- of a file must not pass for the whole: the reset empties what it read)
local function readLua(path)
    local r = safe(getFileReader, path, false)
    if not r then return nil end
    local t = {}
    local ok = pcall(function()
        local l = r:readLine()
        while l do
            t[#t + 1] = l
            l = r:readLine()
        end
    end)
    pcall(function() r:close() end)
    if not ok then return nil end
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
            -- (the mod's folder ends before a "/media/": the first one that is its folder, since a Steam
            -- library can sit in a folder called Media, "D:/Media/SteamLibrary/...", or under /run/media/)
            local lp = lower(raw)
            local at = lp:find("/media/", 1, true)
            while at and not roots[lp:sub(1, at - 1)] do at = lp:find("/media/", at + 1, true) end
            if at then add(raw:sub(at + 1)) end
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

-- (ok, when given, is asked about each top-level file the start takes: false leaves it out) (QA B6-2)
local function addPrefix(res, seen, pre, ok)
    local dir, start = pre:match("^(.*)/([^/]*)$")
    if not dir then dir, start = "", pre end
    if dir == "" and #start < 4 then return end   -- a short bare start would take other mods' files
    local ls = lower(start)
    for ln, real in pairs(listing(dir)) do
        if (ls == "" or ln:sub(1, #ls) == ls) and (dir ~= "" or not ok or ok(ln)) then
            addFound(res, seen, (dir ~= "" and (dir .. "/") or "") .. real, "named")
        end
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

-- does the (lower-case) file name hold the (lower-case) id as a whole word? The id must start the name or
-- follow a non-letter, and end the name or be followed by ". _ - " or a space, so "zqamod" takes
-- "zqamod.ini" and "my_zqamod_settings.txt" but not "zqamodplus.ini" (another mod's id) (beast W52)
local function holdsId(ln, id)
    local from = 1
    while true do
        local at = ln:find(id, from, true)
        if not at then return false end
        local before = at > 1 and ln:sub(at - 1, at - 1) or ""
        local after = ln:sub(at + #id, at + #id)
        if not before:match("%w") and (after == "" or after == "." or after == "_" or after == "-" or after == " ") then
            return true
        end
        from = at + 1
    end
end

-- a (lower-case) name without its separators: "bandits_weekone" and "banditsweekone" read the same (QA B6-2)
local function bare(s) return (s:gsub("[%s_%-%.]", "")) end

-- the ids of the other installed or enabled mods that are longer than this one and hold it ("brita_armor"
-- for "brita"): a file named after one of them is that mod's, not this one's (beast W52). Kept without their
-- separators, so "banditsweekone" also holds "bandits" and claims "Bandits_WeekOne.ini" (QA B6-2)
local function longerIds(id)
    local out, seen = {}, {}
    local bid = bare(id)
    local function add(o)
        o = bare(lower(o):gsub("^\\", ""))   -- (an enabled id can carry a leading backslash)
        if bid ~= "" and not seen[o] and #o > #bid and o:find(bid, 1, true) then seen[o] = true; out[#out + 1] = o end
    end
    local act = safe(getActivatedMods)
    for i = 0, (act and act:size() or 0) - 1 do add(tostring(act:get(i))) end
    for _, dir in ipairs(safe(getModDirectoryTable) or {}) do
        local mi = safe(getModInfo, dir)
        local oid = mi and safe(function() return mi:getId() end)
        if oid then add(tostring(oid)) end
    end
    return out
end

-- the words a mod's own settings file may add around its id ("my_zqamod_keys.txt", "Bandits_Options.ini").
-- Any other word may be a mod's id too, one installed or one uninstalled that left its file ("Bandits_WeekOne.ini"
-- for Bandits): no list tells those apart, so such a file is left out (QA B6-2)
local OWN_WORDS = { my = true, mod = true, settings = true, setting = true, options = true, option = true, config = true,
                    configs = true, cfg = true, conf = true, prefs = true, preferences = true, keys = true, keybinds = true,
                    binds = true, hotkeys = true, notes = true, data = true, save = true, saved = true, state = true,
                    user = true, client = true, server = true, sandbox = true, vars = true, presets = true, preset = true,
                    profile = true, profiles = true, layout = true, ui = true, favorites = true, favourites = true,
                    cache = true, log = true }

-- may a top-level file (lower-case name) be emptied for this mod? Never when it is named after another
-- installed or enabled mod's longer id (separators aside); when it holds this mod's id, only if every other
-- word of its name is one of OWN_WORDS (QA B6-2)
local function mineOk(id, others)
    return function(ln)
        local base = ln:match("^(.*)%.[^%.]*$") or ln
        local bb = bare(base)
        for _, o in ipairs(others) do if bb:find(o, 1, true) then return false end end
        if not holdsId(ln, id) then return true end   -- (a start the code builds that is not the id: as before)
        -- the words left once the id is taken out of the name
        local at = base:find(id, 1, true)
        while at do
            local before, after = base:sub(at - 1, at - 1), base:sub(at + #id, at + #id)
            if (at == 1 or not before:match("%w")) and (after == "" or not after:match("%w")) then break end
            at = base:find(id, at + 1, true)
        end
        if not at then return false end
        local rest = base:sub(1, at - 1) .. " " .. base:sub(at + #id)
        for w in rest:gmatch("[^%s_%-%.]+") do if not OWN_WORDS[w] then return false end end
        return true
    end
end

local function resolve(job)
    local res = { files = {} }
    local seen = {}
    for _, p in pairs(job.names) do addFound(res, seen, p, "named") end
    local id = lower(job.modId)
    local ok = mineOk(id, longerIds(id))
    -- a start the code builds a name from ("Brita_" .. part) takes no other mod's file either (QA B6-2)
    for _, pre in pairs(job.prefixes) do addPrefix(res, seen, pre, ok) end
    if #id >= 4 then
        for ln, real in pairs(listing("")) do
            -- the file holds the id as a whole word, and no longer id's or unknown word claims it (beast W52, QA B6-2)
            if holdsId(ln, id) and ok(ln) then addFound(res, seen, real, "id") end
        end
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
