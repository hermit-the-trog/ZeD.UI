-- ZeD-UI/42/media/lua/client/ZeD/ModSupport/BB_WhereAmI.lua
-- ============================================================================
-- SUPPORT FOR WHERE AM I? (mod id BB_WhereAmI, Workshop 3097650043). Mockup
-- zed_map_overlays_v1, approved "as recommended" Oct 26 2026.
--
-- The mod shows the name of the area the character is in ("Muldraugh, KY") in a
-- header on the game's map (its MapLocationHeader), from its own list of areas
-- (BB_WhereAmI.areaDB, worked out by BB_WhereAmI.CheckPlayerArea when the game's
-- map opens). Off every area it shows "Kentucky, USA", or nothing when its sandbox
-- option Hide when off regions is on. ZeD's Maps tab is its own map, so ZeD shows
-- the same name over the top of the map, through the Maps tab's general hook
-- (MapsTabExt.lua), asking the mod's CheckPlayerArea every two seconds while the
-- map is up.
--
-- ModSupport/<mod id>.lua returns at once unless that mod is on.
-- ============================================================================

local MOD_ID = "BB_WhereAmI"

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

ZeD = ZeD or {}
ZeD.ModSupport = ZeD.ModSupport or {}
local S = {}
ZeD.ModSupport.BB_WhereAmI = S

local _t = -1

function S.area()
    local W = BB_WhereAmI
    if not (W and W.CheckPlayerArea) then return nil end
    local now = getTimestampMs()
    if now - _t > 2000 and getPlayer() and getPlayer():getSquare() then
        _t = now
        pcall(W.CheckPlayerArea)
    end
    local a = W.currentArea or ""
    if a == "" then
        local sv = SandboxVars and SandboxVars.WhereAmI
        if sv and sv.HideUIOffRegion then return nil end
        return ZeD.tr("UI_ZeD_Map_WhereOff")
    end
    return a
end

local X = { order = 60 }
function X.banner(win) return S.area() end
function X.mapMade(mp, win) _t = -1 end

S.X = X   -- (the QA scripts drive it)
ZeD.MapsTab.addExtension(MOD_ID, X)
