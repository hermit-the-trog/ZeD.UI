-- ZeD-UI/42/media/lua/client/ZeD/Overrides/WorldMap.lua
-- ============================================================================
-- WORLD MAP HOOK (S123) — the "Map" key, the mini-map click, the D-pad
-- wheel slice and the equipped-item HUD button all funnel through
-- ISWorldMap.ToggleWorldMap / ShowWorldMap / HideWorldMap. Every one of
-- those now opens ZeD's unfolded map (World window → Maps tab → pop-out)
-- instead of the vanilla full-screen map. Vanilla is only reached when ZeD
-- cannot serve the request (no player, world not loaded, pop-out failed).
-- See HOOK_MAP.md.
-- ============================================================================

if not ISWorldMap then return end

local _origShow   = ISWorldMap.ShowWorldMap
local _origHide   = ISWorldMap.HideWorldMap
local _origToggle = ISWorldMap.ToggleWorldMap

-- Returns true when ZeD handled the request.
local function _zedOpenUnfolded(playerNum)
    playerNum = playerNum or 0
    if not (ZeD and ZeD.MapsTab and ZeD.MapsTab.openPopout) then return false end
    if not (ZeD_WorldWindow and ZeD_WorldWindow.open and ZeD_WorldWindow.getWindow) then return false end
    if not getSpecificPlayer(playerNum) then return false end

    if not ZeD_WorldWindow.isOpen() then
        local ok = pcall(ZeD_WorldWindow.open, playerNum)
        if not ok then return false end
    end
    local win = ZeD_WorldWindow.getWindow()
    if not win then return false end

    -- The tab strip stamps its hit zones during render, so a freshly opened
    -- window has none yet. Try now, then retry for a handful of ticks.
    local tries = 0
    local function attempt()
        tries = tries + 1
        local strip = win._actionTabStrip
        if strip and strip._hitZones then
            for _, z in ipairs(strip._hitZones) do
                if z.id == "tab:maps" then
                    if win._activeTab ~= "maps" then strip:onMouseDown(z.x + 2, z.y + 2) end
                    ZeD.MapsTab.openPopout(win)
                    return true
                end
            end
        end
        return false
    end
    if attempt() then return true end
    local function tick()
        if attempt() or tries >= 15 then Events.OnTick.Remove(tick) end
    end
    Events.OnTick.Add(tick)
    return true
end

-- The map looks where it was asked to (vanilla's reveal-on-map for print media, a map
-- item's Read): once the World window's map widget exists (it is built on the Maps
-- tab's first draw), it is centred and zoomed there.
local function _centerWhenReady(playerNum, centerX, centerY, zoom)
    if not (centerX and centerY) then return end
    local tries = 0
    local function tick()
        tries = tries + 1
        local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
        local mp = win and win._worldMapPanel
        if mp and mp.mapAPI then
            mp.mapAPI:centerOn(centerX, centerY)
            if zoom then mp.mapAPI:setZoom(zoom) end
            Events.OnTick.Remove(tick)
        elseif tries > 60 then
            Events.OnTick.Remove(tick)
        end
    end
    Events.OnTick.Add(tick)
end

function ISWorldMap.ShowWorldMap(playerNum, centerX, centerY, zoom)
    if _zedOpenUnfolded(playerNum) then _centerWhenReady(playerNum, centerX, centerY, zoom); return end
    return _origShow(playerNum, centerX, centerY, zoom)
end

function ISWorldMap.HideWorldMap(playerNum)
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if win and win._mapPopout and ZeD.MapsTab and ZeD.MapsTab.closePopout then
        ZeD.MapsTab.closePopout(win)
        return
    end
    return _origHide(playerNum)
end

function ISWorldMap.ToggleWorldMap(playerNum)
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if win and win._mapPopout then
        ZeD.MapsTab.closePopout(win)
        return
    end
    if _zedOpenUnfolded(playerNum) then return end
    return _origToggle(playerNum)
end

print("[ZeD] Overrides/WorldMap: ISWorldMap Show/Hide/Toggle routed to the ZeD map pop-out")
