-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ModSafety.lua
-- ============================================================================
-- WHAT TURNING A MOD OFF DOES TO A SAVE (director, Oct 24 2026: "add feature
-- saying what will happen if you disable a mod on a save. if safe, if not
-- safe...")
--
-- A save remembers what its mods put into the world, and the game cannot keep
-- what a missing mod defined. ZeD cannot open a save to look (its world is in
-- the game's own binary files), so this says what the MOD holds, read from the
-- game's own data, and what the game does with each kind when the mod is gone:
--   * a map (getMapFoldersForMod): its places are part of the world; without it
--     they are empty, and a character inside them can load into nothing   NOT SAFE
--   * tiles (the mod's tile definitions): anything built or placed from them
--     goes missing                                                        NOT SAFE
--   * items, vehicles, buildable things it adds of its own (the scripts it
--     defines first, ZeD_ModScan): they disappear from the save            CAREFUL
--   * its own game lists (media/registries.lua: traits, tags...)           CAREFUL
--   * recipes, changes to the game's own items, sandbox settings: nothing
--     in the save is lost                                                   SAFE
--   * none of those: code only (screens, options, behaviour)               SAFE
-- Items and vehicles are counted from the scripts the game loaded, so a mod that
-- is not running now (off in the main list, on only in a save) is NOT CHECKED
-- for them; its map and tiles still are. Mods that need it turn off with it
-- (vanilla's cascade), and the worst of all of them is the grade.
--
--   SF.assess(modId)        { grade, lines = { { grade, text } }, unchecked }
--   SF.forTurnOff(m, d)     { grade, main, deps = { { name, assess } } }
--   SF.reset()              forget (the Mods screen opens, the scan finishes)
-- grade: "safe" | "careful" | "unchecked" | "unsafe"
-- ============================================================================
require "ZeD/ZeD_ModScan"
ZeD = ZeD or {}
ZeD.ModSafety = ZeD.ModSafety or {}
local SF = ZeD.ModSafety
local MS = ZeD.ModScan

local RANK = { safe = 1, careful = 2, unchecked = 2, unsafe = 3 }
local function safe(fn, ...) local ok, r = pcall(fn, ...); if ok then return r end return nil end
local function jsize(l) return l and safe(function() return l:size() end) or 0 end

local cache = {}

local function worse(a, b) if (RANK[b] or 1) > (RANK[a] or 1) then return b end return a end

local function hasRegistries(id)
    local files = safe(listFilesInModDirectory, id, "media")
    for i = 0, jsize(files) - 1 do
        if string.lower(tostring(files:get(i))) == "registries.lua" then return true end
    end
    return false
end

function SF.assess(id)
    local key = tostring(id) .. "|" .. tostring(MS.res.done)
    if cache[key] then return cache[key] end
    local out = { id = id, grade = "safe", lines = {} }
    local function add(grade, text)
        out.lines[#out.lines + 1] = { grade = grade, text = text }
        out.grade = worse(out.grade, grade)
    end
    local info = safe(getModInfoByID, id)
    -- the map and its tiles: read from the mod itself, running or not
    local maps = jsize(safe(getMapFoldersForMod, id))
    if maps > 0 then add("unsafe", ZeD.tr(maps == 1 and "UI_ZeD_Mods_OffMapOne" or "UI_ZeD_Mods_OffMapMany", maps)) end
    local tiles = info and jsize(safe(function() return info:getTileDefs() end)) or 0
    if tiles > 0 then add("unsafe", ZeD.tr(tiles == 1 and "UI_ZeD_Mods_OffTilesOne" or "UI_ZeD_Mods_OffTilesMany", tiles)) end
    -- what it defines of its own: from the scripts the game loaded
    local loaded = MS.isLoaded(id) and MS.res.done
    if loaded then
        local a = MS.res.adds and MS.res.adds[id] or {}
        if (a.item or 0) > 0 then add("careful", ZeD.tr(a.item == 1 and "UI_ZeD_Mods_OffItemsOne" or "UI_ZeD_Mods_OffItemsMany", a.item)) end
        if (a.vehicle or 0) > 0 then add("careful", ZeD.tr(a.vehicle == 1 and "UI_ZeD_Mods_OffVehiclesOne" or "UI_ZeD_Mods_OffVehiclesMany", a.vehicle)) end
        if (a.building or 0) > 0 then add("careful", ZeD.tr(a.building == 1 and "UI_ZeD_Mods_OffBuildingsOne" or "UI_ZeD_Mods_OffBuildingsMany", a.building)) end
        if (a.recipe or 0) > 0 then add("safe", ZeD.tr(a.recipe == 1 and "UI_ZeD_Mods_OffRecipesOne" or "UI_ZeD_Mods_OffRecipesMany", a.recipe)) end
        local o = MS.res.overrides and MS.res.overrides[id]
        if o and o.total > 0 then add("safe", ZeD.tr(o.total == 1 and "UI_ZeD_Mods_OffOverridesOne" or "UI_ZeD_Mods_OffOverridesMany", o.total)) end
    else
        out.unchecked = true
        add("unchecked", ZeD.tr("UI_ZeD_Mods_OffNotChecked"))
    end
    if hasRegistries(id) then add("careful", ZeD.tr("UI_ZeD_Mods_OffRegistries")) end
    local sb = ZeD.ModSettings and ZeD.ModSettings.sandboxCount(id) or 0
    if sb > 0 then add("safe", ZeD.tr(sb == 1 and "UI_ZeD_Mods_OffSandboxOne" or "UI_ZeD_Mods_OffSandboxMany", sb)) end
    if out.grade == "safe" then
        -- first: the reason it is safe
        table.insert(out.lines, 1, { grade = "safe", text = ZeD.tr("UI_ZeD_Mods_OffCodeOnly") })
    end
    cache[key] = out
    return out
end

-- the mods that turn off with it (they need it), as vanilla's cascade would
local function dependents(m, id, seen, out)
    for oid, r in pairs(m.mods or {}) do
        if r.isActive and not seen[oid] then
            local req = safe(function() return r.modInfo:getRequire() end)
            for i = 0, jsize(req) - 1 do
                if req:get(i) == id then
                    seen[oid] = true
                    out[#out + 1] = r
                    dependents(m, oid, seen, out)
                    break
                end
            end
        end
    end
    return out
end

function SF.forTurnOff(m, d)
    local main = SF.assess(d.modId)
    local res = { grade = main.grade, main = main, deps = {} }
    for _, r in ipairs(dependents(m, d.modId, { [d.modId] = true }, {})) do
        local a = SF.assess(r.modId)
        res.deps[#res.deps + 1] = { name = r.name, assess = a }
        res.grade = worse(res.grade, a.grade)
    end
    return res
end

-- the headline for a grade
function SF.headline(grade)
    if grade == "unsafe" then return ZeD.tr("UI_ZeD_Mods_OffUnsafe") end
    if grade == "careful" then return ZeD.tr("UI_ZeD_Mods_OffCareful") end
    if grade == "unchecked" then return ZeD.tr("UI_ZeD_Mods_OffUnchecked") end
    return ZeD.tr("UI_ZeD_Mods_OffSafe")
end

function SF.reset() cache = {} end
