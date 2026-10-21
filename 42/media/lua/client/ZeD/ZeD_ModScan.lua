-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModScan.lua
-- ============================================================================
-- WHAT THE MOD MANAGER KNOWS THAT VANILLA DOESN'T SAY (director, Oct 16 2026:
-- "helping with identifying conflicts, updating mods from the workshop")
--
-- Two readers, both on the game's own data, nothing guessed:
--
-- CONFLICTS among the mods running now (the ones the game loaded):
--   * the same Lua file in two mods. The game runs only one copy: the mod
--     later in the load order wins and the other copy never loads (tested on
--     42.21.0). The loaded copies come from getLoadedLua; every other loaded
--     mod's matching folders are listed (listFilesInModDirectory, which reads a
--     mod's version folder and its common folder together) to find the losers.
--   * the same item, recipe, vehicle, building or model in two mods. Every
--     script object keeps one record per definition (getLoadedScriptBodies:
--     mod id, then the text, per definition), so a duplicate is any object with
--     more than one mod in its records. The last definition wins, and the game
--     reads script files in file-name order across all mods, NOT in load order
--     (tested on 42.21.0: renaming the file flips the winner; reordering does not).
--   A mod replacing one of the game's own scripts is counted (overrides), not
--   flagged: that is how mods change the game.
--   The scan runs a slice per frame while the Mods screen is up (a coroutine),
--   so a long mod list never stalls the menu. "Fine, hide this" is kept in
--   Zomboid/Lua/ZeD_modconflicts_hidden.txt.
--
-- WORKSHOP state of every subscribed item (getSteamWorkshopItemIDs and
-- querySteamWorkshopItemDetails): installed, update waiting, downloading,
-- queued, subscribed but not installed; when it was updated and its size. Steam
-- does the downloading (the game's download and subscribe calls are closed to
-- Lua); this only reads it, every 30 s at the main menu and every 10 s while
-- the Mods screen is open. An item that finishes an update while the game runs
-- is remembered: its new code needs a reload and its pictures a restart.
-- ============================================================================

ZeD = ZeD or {}
ZeD.ModScan = ZeD.ModScan or {}
local MS = ZeD.ModScan

local VANILLA = "pz-vanilla"
local HIDE_FILE = "ZeD_modconflicts_hidden.txt"
local SLICE = 60                  -- units of work per frame (a folder listing, or 40 script objects)
local WS_POLL_MS, WS_POLL_OPEN_MS = 30000, 10000

-- the script kinds that are read, with the word the screen uses for each
-- ([2] and [3] are the ids the scan keys its counts by; one / many / thing / same are the translation
-- keys of "1 item", "3 items", an `item "Base.Axe"` line, and the "Same 3 items as ..." title)
local SCRIPT_KINDS = {
    { "getAllItems", "item", "items", one = "UI_ZeD_ModScan_CountItem", many = "UI_ZeD_ModScan_CountItems", thing = "UI_ZeD_ModScan_ThingItem", same = "UI_ZeD_ModScan_SameItems", sameOne = "UI_ZeD_ModScan_SameItem" },
    { "getAllCraftRecipes", "recipe", "recipes", one = "UI_ZeD_ModScan_CountRecipe", many = "UI_ZeD_ModScan_CountRecipes", thing = "UI_ZeD_ModScan_ThingRecipe", same = "UI_ZeD_ModScan_SameRecipes", sameOne = "UI_ZeD_ModScan_SameRecipe" },
    { "getAllVehicleScripts", "vehicle", "vehicles", one = "UI_ZeD_ModScan_CountVehicle", many = "UI_ZeD_ModScan_CountVehicles", thing = "UI_ZeD_ModScan_ThingVehicle", same = "UI_ZeD_ModScan_SameVehicles", sameOne = "UI_ZeD_ModScan_SameVehicle" },
    { "getAllGameEntities", "building", "buildings", one = "UI_ZeD_ModScan_CountBuilding", many = "UI_ZeD_ModScan_CountBuildings", thing = "UI_ZeD_ModScan_ThingBuilding", same = "UI_ZeD_ModScan_SameBuildings", sameOne = "UI_ZeD_ModScan_SameBuilding" },
    { "getAllModelScripts", "model", "models", one = "UI_ZeD_ModScan_CountModel", many = "UI_ZeD_ModScan_CountModels", thing = "UI_ZeD_ModScan_ThingModel", same = "UI_ZeD_ModScan_SameModels", sameOne = "UI_ZeD_ModScan_SameModel" },
}

-- a conflict's thing as words: a Lua file's path as it is, a script object as `item "Base.Axe"`
-- (MS.kindOf: the SCRIPT_KINDS row of a noun id such as "item")
function MS.kindOf(noun)
    for _, k in ipairs(SCRIPT_KINDS) do if k[2] == noun then return k end end
    return nil
end
function MS.thingText(t)
    if type(t) ~= "table" then return tostring(t or "") end
    local k = MS.kindOf(t.kind)
    return k and ZeD.tr(k.thing, t.name) or tostring(t.name)
end

local function nowMs() return getTimestampMs() end
local function norm(p) return string.lower((tostring(p or ""):gsub("\\", "/"))) end

-- a Java list (or nil) as a Lua array
local function jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end
    return t
end

local function modName(id)
    local m = getModInfoByID(id)
    local n = m and m:getName()
    return (n and n ~= "") and tostring(n) or tostring(id)
end
MS.modName = modName

-- ----------------------------------------------------------------------------
-- HIDDEN CONFLICTS ("Fine, hide this")
-- ----------------------------------------------------------------------------
local hidden = nil
local function hiddenLoad()
    hidden = {}
    local r = getFileReader(HIDE_FILE, false)
    if not r then return end
    local line = r:readLine()
    while line do
        if line ~= "" then hidden[line] = true end
        line = r:readLine()
    end
    r:close()
end
local function hiddenSave()
    local wr = getFileWriter(HIDE_FILE, true, false)
    if not wr then return end
    for k in pairs(hidden) do wr:write(k .. "\n") end
    wr:close()
end

function MS.isHidden(e)
    if not hidden then hiddenLoad() end
    return hidden[e.key] == true
end
function MS.hide(e)
    if not hidden then hiddenLoad() end
    hidden[e.key] = true
    hiddenSave()
    MS.res.counts = nil
end

-- ----------------------------------------------------------------------------
-- THE SCAN
-- ----------------------------------------------------------------------------
-- MS.res.byMod[id] = { entry, ... }; an entry is shared by the two mods it names:
--   { kind = "file" | "script", loser = id, winner = id, things = { text, ... }, nouns = { word = n }, key }
-- MS.res.overrides[id] = { total, kinds = { items = n, ... } }: the game's own scripts the mod replaces
MS.res = MS.res or { byMod = {}, overrides = {}, done = false }
local job = nil

local function addConflict(res, kind, loser, winner, thing, noun)
    local key = kind .. ":" .. loser .. ">" .. winner
    local e = res.index[key]
    if not e then
        e = { kind = kind, loser = loser, winner = winner, things = {}, nouns = {}, key = key }
        res.index[key] = e
        res.byMod[loser] = res.byMod[loser] or {}
        res.byMod[winner] = res.byMod[winner] or {}
        table.insert(res.byMod[loser], e)
        table.insert(res.byMod[winner], e)
    end
    e.things[#e.things + 1] = thing
    if noun then e.nouns[noun] = (e.nouns[noun] or 0) + 1 end
end

local function scanBody(res)
    local loaded = jlist(getActivatedMods())
    local roots, isLoaded = {}, {}
    for _, id in ipairs(loaded) do
        isLoaded[id] = true
        local m = getModInfoByID(id)
        if m then
            roots[norm(m:getVersionDir())] = id
            roots[norm(m:getCommonDir())] = id
        end
    end
    -- 1. the Lua files: which mod's copy loaded, by relative path
    local winner, shown, dirs, dirList = {}, {}, {}, {}
    local n = getLoadedLuaCount()
    local work = 0
    for i = 0, n - 1 do
        local raw = tostring(getLoadedLua(i)):gsub("\\", "/")
        local p = string.lower(raw)
        local at = p:find("/media/", 1, true)
        local id = at and roots[p:sub(1, at - 1)]
        if id then
            local rel = p:sub(at + 1)
            winner[rel] = id
            shown[rel] = raw:sub(at + 1)
            local dir = rel:match("^(.*)/[^/]+$")
            if dir and not dirs[dir] then dirs[dir] = true; dirList[#dirList + 1] = dir end
        end
        work = work + 1
        if work % 400 == 0 then coroutine.yield() end
    end
    -- every loaded mod's copy of those folders: a .lua there that another mod's copy beat
    work = 0
    for _, id in ipairs(loaded) do
        for _, dir in ipairs(dirList) do
            local files = listFilesInModDirectory(id, dir)
            if files then
                for k = 0, files:size() - 1 do
                    local f = string.lower(tostring(files:get(k)))
                    if f:sub(-4) == ".lua" then
                        local rel = dir .. "/" .. f
                        local w = winner[rel]
                        if w and w ~= id then addConflict(res, "file", id, w, shown[rel] or rel) end
                    end
                end
            end
            work = work + 1
            if work % SLICE == 0 then coroutine.yield() end
        end
    end
    -- 2. the scripts: an object defined by more than one mod
    local sm = getScriptManager()
    for _, k in ipairs(SCRIPT_KINDS) do
        local ok, list = pcall(function() return sm[k[1]](sm) end)
        if ok and list then
            for i = 0, list:size() - 1 do
                local o = list:get(i)
                if o:getLoadedScriptBodyCount() > 2 then
                    local bodies = o:getLoadedScriptBodies()
                    local mods, seen, vanilla = {}, {}, false
                    for b = 0, bodies:size() - 1, 2 do
                        local mid = tostring(bodies:get(b))
                        if mid == VANILLA then vanilla = true
                        elseif not seen[mid] then seen[mid] = true; mods[#mods + 1] = mid end
                    end
                    if #mods >= 2 then
                        local name = tostring(o:getScriptObjectFullType())
                        local w = mods[#mods]
                        for j = 1, #mods - 1 do addConflict(res, "script", mods[j], w, { kind = k[2], name = name }, k[2]) end
                    end
                    if vanilla then
                        for _, mid in ipairs(mods) do
                            local o2 = res.overrides[mid] or { total = 0, kinds = {} }
                            o2.total = o2.total + 1
                            o2.kinds[k[3]] = (o2.kinds[k[3]] or 0) + 1
                            res.overrides[mid] = o2
                        end
                    end
                end
                if i % 40 == 39 then coroutine.yield() end
            end
        end
    end
    -- mods no longer loaded are not reported (their entries name only loaded mods)
    res.done = true
end

-- start (or restart) the scan of the mods loaded now
function MS.start()
    local res = { byMod = {}, overrides = {}, index = {}, done = false, startedAt = nowMs() }
    MS.res = res
    job = coroutine.create(function() scanBody(res) end)
end

-- slices of the scan for up to STEP_MS of a frame; the Mods screen calls this every frame it is up
local STEP_MS = 6
local errLogged = false
function MS.step()
    if not job then
        if not MS.res.startedAt then MS.start() else return end
    end
    local t0 = nowMs()
    repeat
        if coroutine.status(job) == "dead" then job = nil; return end
        local ok, err = coroutine.resume(job)
        if not ok then
            if not errLogged then print("ZeD ModScan: " .. tostring(err)); errLogged = true end
            MS.res.done = true
            job = nil
            return
        end
    until nowMs() - t0 >= STEP_MS
end

function MS.scanning() return job ~= nil and not MS.res.done end

-- the conflicts that name a mod, without the hidden ones
function MS.forMod(id)
    local out = {}
    for _, e in ipairs(MS.res.byMod[id] or {}) do
        if not MS.isHidden(e) then out[#out + 1] = e end
    end
    return out
end

-- per mod, how many shown conflicts (kept until the scan or a hide changes it)
function MS.count(id)
    local c = MS.res.counts
    if not c or c.done ~= MS.res.done then
        c = { done = MS.res.done }
        for mid in pairs(MS.res.byMod) do
            local k = #MS.forMod(mid)
            if k > 0 then c[mid] = k end
        end
        MS.res.counts = c
    end
    return c[id] or 0
end

-- ----------------------------------------------------------------------------
-- THE WORKSHOP
-- ----------------------------------------------------------------------------
-- MS.ws.items[idString] = { id, title, state, updated, size, children }
MS.ws = MS.ws or { items = {}, order = {}, at = 0, pending = false, first = {}, updatedNow = {}, asked = false }

-- Steam's state flags (a text like "Subscribed|Installed") as one word for the screen
function MS.wsState(st)
    st = tostring(st or "")
    if st:find("Downloading", 1, true) then return "downloading" end
    if st:find("DownloadPending", 1, true) then return "queued" end
    if st:find("NeedsUpdate", 1, true) then return "update" end
    if st:find("Installed", 1, true) then return "ok" end
    if st:find("Subscribed", 1, true) then return "missing" end
    return "none"
end

-- (translation keys by state; MS.wsText gives the player's words)
MS.WS_TEXT = { downloading = "UI_ZeD_ModScan_WsDownloading", queued = "UI_ZeD_ModScan_WsQueued", update = "UI_ZeD_ModScan_WsUpdate",
               ok = "UI_ZeD_ModScan_WsOk", missing = "UI_ZeD_ModScan_WsMissing", none = "UI_ZeD_ModScan_WsNone" }
function MS.wsText(state)
    local k = MS.WS_TEXT[state]
    return k and ZeD.tr(k) or nil
end

local function onDetails(target, status, info)
    local ws = MS.ws
    ws.pending = false
    if tostring(status) ~= "Completed" or not info then return end
    local items, order = {}, {}
    for i = 0, info:size() - 1 do
        local d = info:get(i)
        local id = tostring(d:getIDString())
        local it = { id = id, title = tostring(d:getTitle() or id), state = MS.wsState(d:getState()),
                     updated = tonumber(tostring(d:getTimeUpdated())) or 0, size = tonumber(tostring(d:getFileSize())) or 0,
                     children = d:getNumChildren() or 0 }
        -- an update that lands while the game runs: Steam was fetching it (or its time moved on)
        local f = ws.first[id]
        if not f then ws.first[id] = { state = it.state, updated = it.updated }
        elseif it.state == "ok" and (f.state ~= "ok" or it.updated > f.updated) then ws.updatedNow[id] = true end
        items[id] = it
        order[#order + 1] = it
    end
    table.sort(order, function(a, b) return string.lower(a.title) < string.lower(b.title) end)
    ws.items, ws.order = items, order
end

function MS.wsPoll(open)
    local ws = MS.ws
    if ws.fake then return end
    local t = nowMs()
    if ws.pending and t - ws.at < 20000 then return end
    if t - ws.at < (open and WS_POLL_OPEN_MS or WS_POLL_MS) then return end
    ws.at = t
    local ok = pcall(function()
        if not getSteamModeActive() then ws.steamOff = true; return end
        ws.steamOff = false
        local ids = getSteamWorkshopItemIDs()
        ws.subscribed = ids and ids:size() or 0
        if ids and ids:size() > 0 then
            ws.pending = true
            querySteamWorkshopItemDetails(ids, onDetails, MS)
        else
            ws.items, ws.order = {}, {}
        end
    end)
    if not ok then ws.pending = false end
    ws.asked = true
end

-- a mod's Workshop item (nil when it is not from the Workshop or Steam has not answered)
function MS.wsFor(modInfo)
    local wid = nil
    pcall(function() wid = modInfo:getWorkshopID() end)
    if not wid or wid == "" then return nil end
    return MS.ws.items[tostring(wid)]
end

-- the loaded mods whose Workshop item updated while the game ran
function MS.updatedLoaded()
    local out = {}
    for _, id in ipairs(jlist(getActivatedMods())) do
        local m = getModInfoByID(id)
        local wid = nil
        pcall(function() wid = m and m:getWorkshopID() end)
        if wid and MS.ws.updatedNow[tostring(wid)] then out[#out + 1] = id end
    end
    return out
end

-- "2 h ago", "3 days ago", "Sep 30"
-- (the month names are the main menu's keys, translated where they show)
local MONTHS = { "UI_ZeD_MainMenu_MonthJan", "UI_ZeD_MainMenu_MonthFeb", "UI_ZeD_MainMenu_MonthMar",
    "UI_ZeD_MainMenu_MonthApr", "UI_ZeD_MainMenu_MonthMay", "UI_ZeD_MainMenu_MonthJun",
    "UI_ZeD_MainMenu_MonthJul", "UI_ZeD_MainMenu_MonthAug", "UI_ZeD_MainMenu_MonthSep",
    "UI_ZeD_MainMenu_MonthOct", "UI_ZeD_MainMenu_MonthNov", "UI_ZeD_MainMenu_MonthDec" }
function MS.ago(secs)
    if not secs or secs <= 0 then return "" end
    local d = getTimestamp() - secs
    if d < 3600 then return ZeD.tr("UI_ZeD_ModScan_AgoHour") end
    if d < 86400 then return ZeD.tr("UI_ZeD_ModScan_AgoHours", math.floor(d / 3600)) end
    if d < 86400 * 2 then return ZeD.tr("UI_ZeD_ModScan_AgoYesterday") end
    if d < 86400 * 14 then return ZeD.tr("UI_ZeD_ModScan_AgoDays", math.floor(d / 86400)) end
    local ok, s = pcall(function() local t = os.date("*t", secs); return ZeD.tr("UI_ZeD_ModScan_AgoDate", ZeD.tr(MONTHS[t.month]), t.day, t.year) end)
    return ok and s or ZeD.tr("UI_ZeD_ModScan_AgoDays", math.floor(d / 86400))
end

function MS.size(bytes)
    if not bytes or bytes <= 0 then return "" end
    if bytes < 1048576 then return string.format("%.0f KB", bytes / 1024) end
    if bytes < 1073741824 then
        local mb = bytes / 1048576
        return (mb < 10 and string.format("%.1f MB", mb) or string.format("%.0f MB", mb))
    end
    return string.format("%.1f GB", bytes / 1073741824)
end

-- Steam's page for an item: the overlay when it is on, the browser otherwise
function MS.openInSteam(wid)
    if not wid or wid == "" then return end
    local overlay = false
    pcall(function() overlay = isSteamOverlayEnabled() end)
    if overlay then activateSteamOverlayToWorkshopItem(tostring(wid))
    else openUrl("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. tostring(wid)) end
end

-- the main menu polls the Workshop now and then (the Mods screen asks more often)
local function onFETick()
    if MainScreen and MainScreen.instance and MainScreen.instance.inGame then return end
    MS.wsPoll(false)
end
Events.OnFETick.Add(onFETick)

-- the mods the game loaded (fixed until the next reload, which reloads this file too)
local loadedSet = nil
function MS.isLoaded(id)
    if not loadedSet then
        loadedSet = {}
        for _, x in ipairs(jlist(getActivatedMods())) do loadedSet[x] = true end
    end
    return loadedSet[id] == true
end

-- the game's Workshop front page, the same way
function MS.openWorkshop()
    local overlay = false
    pcall(function() overlay = isSteamOverlayEnabled() end)
    local url = "https://steamcommunity.com/app/108600/workshop/"
    if overlay then activateSteamOverlayToWebPage(url) else openUrl(url) end
end

-- "the game's 3 items and 2 recipes" (nil: it replaces none)
function MS.overrideText(id)
    local o = MS.res.overrides[id]
    if not o or o.total == 0 then return nil end
    local parts = {}
    for _, k in ipairs(SCRIPT_KINDS) do
        local n = o.kinds[k[3]]
        if n then parts[#parts + 1] = ZeD.tr(n == 1 and k.one or k.many, n) end
    end
    local list = parts[1]
    if #parts == 2 then list = ZeD.tr("UI_ZeD_ModScan_ListAnd", parts[1], parts[2])
    elseif #parts > 2 then list = ZeD.tr("UI_ZeD_ModScan_ListAnd", table.concat(parts, ", ", 1, #parts - 1), parts[#parts]) end
    return ZeD.tr("UI_ZeD_ModScan_TheGames", list)
end

-- the hidden conflicts that name a mod, and showing them again
function MS.hiddenFor(id)
    local n = 0
    for _, e in ipairs(MS.res.byMod[id] or {}) do if MS.isHidden(e) then n = n + 1 end end
    return n
end
function MS.unhideFor(id)
    if not hidden then hiddenLoad() end
    for _, e in ipairs(MS.res.byMod[id] or {}) do hidden[e.key] = nil end
    hiddenSave()
    MS.res.counts = nil
end
