-- ZeDUI/tools/qa/zedqa_modapi_probe.lua  (Oct 16 2026)
-- At the main menu: what the mod manager's new parts can read. Lists the mod
-- folders and their ids, tries listFilesInModDirectory with a few argument
-- forms, reads the Workshop items and their details (state, update time,
-- size), and the staged Workshop folders. Read only. grep "ZEDQA mp".
local function say(s) print("ZEDQA mp " .. tostring(s)) end
local function try(label, fn)
    local ok, r = pcall(fn)
    if not ok then say(label .. " ERR " .. tostring(r)); return nil end
    return r
end
local function jsize(l) return l and l.size and l:size() or -1 end

local dirs = try("getModDirectoryTable", function() return getModDirectoryTable() end) or {}
say("mod folders: " .. #dirs)
for i, d in ipairs(dirs) do
    if i > 12 then break end
    local m = try("getModInfo", function() return getModInfo(d) end)
    say(string.format("  %s | id %s | ws %s | packs %d | tiledefs %d | ver %s | common %s",
        tostring(d), tostring(m and m:getId()), tostring(m and m:getWorkshopID()), jsize(m and m:getPacks()), jsize(m and m:getTileDefs()),
        tostring(m and m:getVersionDir()), tostring(m and m:getCommonDir())))
end

-- listFilesInModDirectory: which arguments does it take?
local probeMod = getModInfoByID("ZeD_UI")
local candidates = {
    { "id, media/lua/client", function() return listFilesInModDirectory("ZeD_UI", "media/lua/client") end },
    { "id, media", function() return listFilesInModDirectory("ZeD_UI", "media") end },
    { "id, ''", function() return listFilesInModDirectory("ZeD_UI", "") end },
    { "dir, media", function() return listFilesInModDirectory(probeMod:getDir(), "media") end },
    { "versionDir, media", function() return listFilesInModDirectory(probeMod:getVersionDir(), "media") end },
    { "id, lua", function() return listFilesInModDirectory("ZeD_UI", "lua") end },
}
for _, c in ipairs(candidates) do
    local r = try("list " .. c[1], c[2])
    local n = jsize(r)
    local sample = {}
    for i = 0, math.min(n, 4) - 1 do sample[#sample + 1] = tostring(r:get(i)) end
    say("listFilesInModDirectory(" .. c[1] .. ") -> " .. n .. " [" .. table.concat(sample, " ; ") .. "]")
end

-- the Workshop
local ids = try("ids", function() return getSteamWorkshopItemIDs() end)
say("workshop subscribed ids: " .. jsize(ids))
if ids and ids:size() > 0 then
    local target = {}
    function target.done(self, status, info)
        say("details status " .. tostring(status) .. " count " .. jsize(info))
        for i = 0, math.min(jsize(info), 8) - 1 do
            local d = info:get(i)
            say(string.format("  %s | %s | state %s | updated %s | size %s | children %s",
                d:getIDString(), tostring(d:getTitle()), tostring(d:getState()), tostring(d:getTimeUpdated()), tostring(d:getFileSize()), tostring(d:getNumChildren())))
        end
    end
    try("query", function() querySteamWorkshopItemDetails(ids, target.done, target) end)
end
local staged = try("staged", function() return getSteamWorkshopStagedItems() end)
say("staged workshop folders: " .. jsize(staged))
for i = 0, math.min(jsize(staged), 6) - 1 do
    local it = staged:get(i)
    say(string.format("  %s | title %s | id %s | vis %s | preview %s", tostring(it:getFolderName()), tostring(it:getTitle()), tostring(it:getID()),
        tostring(it:getVisibility()), tostring(it:getPreviewImage())))
end
say("overlay " .. tostring(try("overlay", function() return isSteamOverlayEnabled() end)) .. " steam " .. tostring(try("steam", function() return getSteamModeActive() end)))
say("DONE")
