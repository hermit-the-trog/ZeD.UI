-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/CustomMapLabels.lua
-- ============================================================================
-- SUPPORT FOR [B42] CUSTOM MAP LABELS (mod id CustomMapLabels, Workshop
-- 3559737194). Client.
--
-- The mod names the places other map mods add. At game start it opens the game's
-- map (ISWorldMap.ShowWorldMap(0)), takes the map object that makes
-- (ISWorldMap_instance), writes its labels into the map's symbols and closes the
-- map again. ZeD opens its own map for ShowWorldMap, so no game map object
-- existed, the mod stopped at its line 93 with an error, and its labels were
-- never written.
--   * While the game starts, ShowWorldMap goes to the game's own Show (the hook in
--     Overrides/WorldMap.lua: ZeD.WorldMapHook.vanillaWhen). The mod then finds its
--     map, writes the labels and closes it, as it does without ZeD. The window
--     ends with the first tick after the game has started; every later
--     ShowWorldMap is ZeD's map.
--   * ZeD's map needs nothing more: marks and labels live in the game's one store
--     (MapNotes.lua binds ZeD's map to it), so the labels the mod writes show on
--     ZeD's map, as on the game's map and mini-map.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "CustomMapLabels"

-- Is the mod on? An id from getActivatedMods() can carry a leading backslash.
local function modOn()
    local list = getActivatedMods and getActivatedMods()
    if not list then return false end
    for i = 0, list:size() - 1 do
        local id = tostring(list:get(i)):gsub("^\\", "")
        if id == MOD_ID then return true end
    end
    return false
end
if not modOn() then return end

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = { starting = true }
ZeD.ModSupport.CustomMapLabels = S

-- The start window: open from the moment this file loads, closed by the first tick after OnGameStart (both
-- OnGameStart handlers, the mod's and ZeD's, run before any tick, whichever order they were added in).
local function closeAfterTick()
    local function tick()
        S.starting = false
        Events.OnTick.Remove(tick)
    end
    Events.OnTick.Add(tick)
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(closeAfterTick) end

-- The game's map is asked for only while the window is open and none exists yet (once one exists the game's Show
-- reuses it, and the mod does not ask).
function S.wantsGameMap()
    return S.starting == true and not ISWorldMap_instance
end

ZeD.WorldMapHook = ZeD.WorldMapHook or {}
ZeD.WorldMapHook.vanillaWhen = ZeD.WorldMapHook.vanillaWhen or {}
table.insert(ZeD.WorldMapHook.vanillaWhen, { id = MOD_ID, fn = S.wantsGameMap })
