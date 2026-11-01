-- ZeDUI/tools/qa/modfolders_crossread.lua  (Nov 1 2026, QA; punch list 37, stage 2)
-- Outside the game (LuaJIT or Lua 5.1): does [B42]Mod Folders read a ModFolders.cfg that ZeD wrote?
-- ZeD's ZeD_ModFolders.lua is loaded as it ships, with getFileReader / getFileWriter stubbed on a temp
-- folder; ZeD starts from the mod's own sample (ZeDUI/ModFolders_sample.cfg, written in game by the
-- mod's code) and makes folders, moves mods, closes, reorders, renames and deletes. Then the mod's
-- loadConfig (ModFolders.lua lines 137-171 of Workshop 3779201168, copied unchanged but for MF) reads
-- ZeD's file, and what it sees is compared with what ZeD meant. Names are kept to one byte a letter
-- here (Lua 5.1 strings are bytes; in game they are UTF-16 units, checked by zedqa_mods_folders.lua 2b).
-- Run: lua.exe modfolders_crossread.lua <repo root> <temp dir>
local ROOT, TMP = arg[1], arg[2]
local function rd(p) local f = assert(io.open(p, "rb")); local s = f:read("*a"); f:close(); return s end
local function wr(p, s) local f = assert(io.open(p, "wb")); f:write(s); f:close() end

-- Lua 5.1's string.char stops at 255: a code above (the sample's Chinese folder) becomes "{hex}" on
-- both sides, so the two decoders still agree with each other
local char = string.char
string.char = function(...)
    local t = {}
    for i, c in ipairs({ ... }) do t[i] = c <= 255 and char(c) or string.format("{%X}", c) end
    return table.concat(t)
end

-- the game's file API, on TMP
function getFileReader(name)
    local f = io.open(TMP .. "/" .. name, "rb"); if not f then return nil end
    local s = f:read("*a"); f:close()
    local lines, i = {}, 0
    for l in (s .. (s:sub(-1) == "\n" and "" or "\n")):gmatch("(.-)\r?\n") do lines[#lines + 1] = l end
    if s == "" then lines = {} end
    return { readLine = function() i = i + 1; return lines[i] end, close = function() end }
end
function getFileWriter(name)
    local f = assert(io.open(TMP .. "/" .. name, "wb"))
    return { write = function(_, s) f:write(s) end, close = function() f:close() end }
end

dofile(ROOT .. "/42/media/lua/client/ZeD/ZeD_ModFolders.lua")
local F = ZeD.ModFolders
F.FILE = "ModFolders.cfg"
wr(TMP .. "/ModFolders.cfg", rd(ROOT .. "/ZeDUI/ModFolders_sample.cfg"))
F.load()

local fails, passes = 0, 0
local function check(ok, what) if ok then passes = passes + 1; print("PASS " .. what) else fails = fails + 1; print("FAIL " .. what) end end

-- ZeD's changes
local okA, cars = F.create("Cars & Trucks")
local okB, maps = F.create("Maps|North")      -- a | in a name (the line's separator)
local okC, ui   = F.create("Caf" .. string.char(0xE9) .. " UI")
F.assign({ "Constown42", "newhartburg", "KnoxPacks" }, cars)
F.assign({ "BB_KilometersPerHour" }, maps)
F.assign({ "ZeD_UI" }, ui)
F.setOpen(cars, false)
F.moveFolder(ui, -1)
F.rename(maps, "Maps, North")                  -- a comma in a name (the encoding's separator)
local okD = F.delete(1)                        -- the sample's first folder: its members go unfiled
F.assign({ "ModFolders" }, nil)                -- one mod taken out of every folder
check(okA and okB and okC and okD, "ZeD made its changes")

-- what ZeD means now
local want = {}
for _, fo in ipairs(F.folders()) do want[#want + 1] = fo end
local wantMember = {}
for _, fo in ipairs(want) do for _, m in ipairs(F.membersOf(fo.id) or {}) do wantMember[type(m) == "table" and m.mod or m] = fo.id end end
print("ZeD's file:"); io.write(rd(TMP .. "/ModFolders.cfg"))

-- [B42]Mod Folders reads it (its code from here)
local MF = { folders = {}, folderById = {}, membership = {}, nextId = 1 }
local function decodeValueV2(value)
    local out = {}
    for hex in tostring(value or ""):gmatch("([%x]+)") do
        local code = tonumber(hex, 16)
        if code then
            table.insert(out, string.char(code))
        end
    end
    return table.concat(out)
end
local function decodeValueV1(v) return v end
local function rebuildFolderIndex() MF.folderById = {}; for _, f in ipairs(MF.folders) do MF.folderById[f.id] = f end end
local lines = {}
do local r = getFileReader("ModFolders.cfg"); local l = r:readLine(); while l do lines[#lines + 1] = l; l = r:readLine() end end
    local version = 1
    for _, configLine in ipairs(lines) do
        local parsedVersion = configLine:match("^version=(%d+)$")
        if parsedVersion then
            version = tonumber(parsedVersion) or 1
            break
        end
    end
    local decodeValue = version >= 2 and decodeValueV2 or decodeValueV1

    local maxId = 0
    for _, configLine in ipairs(lines) do
        local nextId = configLine:match("^next=(%d+)$")
        if nextId then
            MF.nextId = math.max(1, tonumber(nextId) or 1)
        else
            local id, expanded, encodedName = configLine:match("^folder=(%d+)|([01])|(.*)$")
            if id then
                id = tonumber(id)
                table.insert(MF.folders, {
                    id = id,
                    name = decodeValue(encodedName),
                    expanded = expanded == "1",
                })
                if id > maxId then maxId = id end
            else
                local encodedModId, folderId = configLine:match("^member=(.-)|(%d+)$")
                if encodedModId and folderId then
                    MF.membership[decodeValue(encodedModId)] = tonumber(folderId)
                end
            end
        end
    end

    if MF.nextId <= maxId then MF.nextId = maxId + 1 end
    rebuildFolderIndex()
-- (end of its code)

check(version == 2, "the mod reads version 2")
check(#MF.folders == #want, "the mod sees " .. #MF.folders .. " folders, ZeD has " .. #want)
for i, fo in ipairs(want) do
    local g = MF.folders[i] or {}
    check(g.id == fo.id and g.name == fo.name and g.expanded == (fo.open and true or false),
        string.format("folder %d in place: %s / %s, open %s / %s", i, tostring(g.name), tostring(fo.name), tostring(g.expanded), tostring(fo.open)))
end
local same, n = true, 0
for mod, fid in pairs(wantMember) do n = n + 1; if MF.membership[mod] ~= fid then same = false; print("  member " .. mod .. ": mod " .. tostring(MF.membership[mod]) .. ", ZeD " .. fid) end end
for mod, fid in pairs(MF.membership) do if MF.folderById[fid] and wantMember[mod] == nil then same = false; print("  extra member " .. mod .. " -> " .. fid) end end
check(same, "the members agree (" .. n .. ")")
check(MF.nextId > maxId, "the next id is past every folder (" .. MF.nextId .. ")")
print(string.format("%d passed, %d failed", passes, fails))
