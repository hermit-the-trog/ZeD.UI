-- ZeDUI/tools/qa/zedqa_modfolders_sample.lua  (Oct 31 2026, QA; punch list 37)
-- A ModFolders.cfg sample written in game by [B42]Mod Folders' own save code (ModFolders.lua, Workshop 3779201168,
-- saveConfig / encodeValue copied unchanged), so the file is what that mod writes under PZ's Lua: two folders,
-- "地图" (Chinese) and "Café" (accented), and "Weapons", with a few mod ids each; then read back with its own
-- loadConfig / decodeValueV2 and compared. Writes Zomboid/Lua/ModFolders_sample.cfg (never ModFolders.cfg, the
-- player's own). grep "ZEDQA mfs".
local function say(s) print("ZEDQA mfs " .. tostring(s)) end
local OUT = "ModFolders_sample.cfg"

-- [B42]Mod Folders, ModFolders.lua lines 45-63 and 177-193, unchanged but for the file name and the MF table
local MF = { folders = {}, folderById = {}, membership = {}, nextId = 1 }
local function encodeValue(value)
    value = tostring(value or "")
    local out = {}
    value:gsub(".", function(c)
        table.insert(out, string.format("%X", string.byte(c)))
    end)
    return table.concat(out, ",")
end
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
local function saveConfig()
    local file = getFileWriter(OUT, true, false)
    if not file then return end
    file:write("version=2\n")
    file:write("next=" .. tostring(MF.nextId) .. "\n")
    for _, folder in ipairs(MF.folders) do
        file:write("folder=" .. tostring(folder.id) .. "|" .. (folder.expanded and "1" or "0") .. "|" .. encodeValue(folder.name) .. "\n")
    end
    for modId, folderId in pairs(MF.membership) do
        if MF.folderById[folderId] then
            file:write("member=" .. encodeValue(modId) .. "|" .. tostring(folderId) .. "\n")
        end
    end
    file:close()
end

-- the layout: the way its createFolder / assignMod leave the tables
-- (built from character codes: the bridge does not read a script file as UTF-8, so a literal "地图" arrives broken)
local names = { string.char(0x5730) .. string.char(0x56FE), "Caf" .. string.char(0xE9), "Weapons" }
for i, n in ipairs(names) do
    local f = { id = i, name = n, expanded = (i ~= 2) }
    MF.folders[#MF.folders + 1] = f
    MF.folderById[i] = f
end
MF.nextId = #names + 1
local members = { Constown42 = 1, newhartburg = 1, ModFolders = 2, ZeD_UI = 2, GaelGunStore_B42 = 3, ModernFirearmsSystem = 3 }
for id, fid in pairs(members) do MF.membership[id] = fid end
saveConfig()

-- read it back the way its loadConfig does
local r = getFileReader(OUT, true)
local lines = {}
if r then local l = r:readLine(); while l do lines[#lines + 1] = l; l = r:readLine() end; r:close() end
local ok = true
local got = {}
for _, line in ipairs(lines) do
    say("line " .. line)
    local id, ex, enc = line:match("^folder=(%d+)|([01])|(.*)$")
    if id then got[tonumber(id)] = decodeValueV2(enc) end
    local em, fid = line:match("^member=(.-)|(%d+)$")
    if em then local m = decodeValueV2(em); if members[m] ~= tonumber(fid) then ok = false; say("FAIL member " .. m) end end
end
for i, n in ipairs(names) do
    local same = got[i] == n
    if not same then ok = false end
    say((same and "PASS" or "FAIL") .. " folder " .. i .. " round trip: " .. tostring(got[i]) .. " (length " .. #n .. ", encoded " .. encodeValue(n) .. ")")
end
say(ok and "all round trips held" or "a round trip failed")
-- DONE a few ticks later: the runner looks for it after the bridge's own "run #n" line
local n = 0
local function later() n = n + 1; if n < 10 then return end; Events.OnTick.Remove(later); say("DONE") end
Events.OnTick.Add(later)
