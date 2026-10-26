-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/MapSymbolSizeSlider.lua
-- ============================================================================
-- SUPPORT FOR MAP SYMBOL SIZE SLIDER (mod id MapSymbolSizeSlider, Workshop
-- 2734705913). Mockup zed_map_overlays_v1, approved "as recommended" Oct 26 2026.
--
-- The mod puts a Symbol Size slider under the game's map symbols panel. It sets
-- the size marks and notes are made at (ISMap.SCALE, through its
-- ISWorldMapSymbols:ChangeGlobalScale) and keeps it in the character's modData
-- under its own key, MapSymbolSizeSlider_currentScale, read back when the game's
-- map makes the slider. ZeD's Maps tab is its own map, so ZeD shows the same
-- slider under the toolbar's disclosure, beside the full mark grid (where the mod
-- puts it on the game's map), through the Maps tab's general hook (MapsTabExt.lua):
--   * the mod's range and step (0.066 to 2.266, steps of 0.1), its word (Symbol
--     Size), a tick at the game's own size, Reset back to it, the size as a
--     percentage of the game's;
--   * a move saves to the mod's own setting and goes through the mod's own
--     ChangeGlobalScale, so ZeD's map and the game's agree;
--   * the size the mod saved is put back when the game starts (the mod only reads
--     it when the game's map opens, which ZeD's map replaces).
-- As in the mod, the size is the one new marks and notes are made at; marks
-- already on the map keep theirs.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "MapSymbolSizeSlider"

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

require "ZeD/Tr"
require "ZeD/MapsTab"
require "ISUI/Maps/ISMap"

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.MapSymbolSizeSlider = S

-- the mod's numbers (MapSymbolSizeSlider.consts) and its modData key
local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.066, 2.266, 0.1
local KEY = "MapSymbolSizeSlider_currentScale"
-- the game's own size (the mod's params.defaultScale: ISMap.SCALE as the game set it)
S.DEFAULT = (ISMap and ISMap.SCALE) or 0.666

function S.get()
    return (ISMap and ISMap.SCALE) or S.DEFAULT
end

-- through the mod's own function, and into its own setting
function S.set(v)
    v = math.max(SCALE_MIN, math.min(SCALE_MAX, v))
    if ISWorldMapSymbols and ISWorldMapSymbols.ChangeGlobalScale then
        pcall(ISWorldMapSymbols.ChangeGlobalScale, ISWorldMapSymbols, v)
    end
    if ISMap then ISMap.SCALE = v end
    local p = getPlayer()
    if p then p:getModData()[KEY] = v end
end

-- the saved size back on, as the mod does when its slider is made
local function restore()
    local p = getPlayer()
    local v = p and p:getModData()[KEY]
    if type(v) == "number" and ISMap then
        pcall(function()
            if ISWorldMapSymbols and ISWorldMapSymbols.ChangeGlobalScale then ISWorldMapSymbols:ChangeGlobalScale(v) end
        end)
        ISMap.SCALE = v
    end
end
if Events and Events.OnGameStart then Events.OnGameStart.Add(restore) end

local X = { order = 30 }

-- under the mark grid (the toolbar's disclosure)
function X.gridRow(win)
    return { h = 32, draw = function(ctx)
        ctx:label(ZeD.tr("IGUI_Map_MapSymbolSize"))
        ctx:slider("size", { w = ctx.narrow and 120 or 150, min = SCALE_MIN, max = SCALE_MAX, step = SCALE_STEP, tick = S.DEFAULT,
            get = S.get, set = S.set,
            fmt = function(v) return tostring(math.floor(v / S.DEFAULT * 100 + 0.5)) .. "%" end })
        ctx:button("size:reset", ZeD.tr("IGUI_WorldMapEditor_Reset"), { activate = function() S.set(S.DEFAULT) end })
    end }
end

-- a map made: the saved size is on (the game may have started before this file)
function X.mapMade(mp, win)
    if not S._restored then S._restored = true; restore() end
end

S.X = X   -- (the QA scripts drive it)
ZeD.MapsTab.addExtension(MOD_ID, X)
