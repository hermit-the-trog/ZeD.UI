-- ZeD-UI/42/media/lua/client/ZeD/PaperMap.lua
-- ============================================================================
-- PAPER MAPS (Nov 7 2026; vanilla windows list B2, the director: "ZeD's map,
-- that area"). Read Map on a map item (a town map, a Louisville square, a
-- stash map) opens ZeD's map window on that paper: the area the paper shows,
-- drawn as the game draws it, with the paper's own marks (a stash map's
-- crosses and notes, and whatever was written on it), and ZeD's marking tools,
-- which write on that paper as vanilla's do. The world map's tools (other
-- mods' map extensions, Survey / Color / Paper, sharing) stay off it.
--
-- The game's read stays the game's, in its order (ISInventoryPaneContextMenu.
-- onCheckMap and ISMap:initMapData, 42.22):
--   1. a map not in the main inventory is taken there first (vanilla's own
--      transfer; its end comes back to Read Map)
--   2. item:doBuildingStash()          the stash's building is made
--   3. the window opens (MapOpen)
--   4. playerObj:addReadMap(item)      the map counts as read
--   5. LootMaps.callLua("Init", map)   the paper's area and look
--   6. MapUtils.revealKnownArea(map)   that area is known on the world map,
--      and on a server sendClientCommand("map", "setKnownInSquares", bounds)
--   7. resetView                       the whole paper in view
-- The window closes when the map leaves the main inventory (ISMap:update) and
-- puts the map away with MapClose. A stash map keeps vanilla's reveal button
-- (ISMap REVEAL) as a band button: the game's short map-reading action, then
-- ZeD's own map on that place.
--
-- The window is the World window's unfolded map (MapsTab.lua: openPopout with
-- the item); the hook is Overrides/PaperMap.lua. The game's window comes back
-- in safe mode, for a split-screen player whose World window it isn't, and
-- whenever ZeD's cannot open or cannot draw the paper (openVanilla: the window
-- alone, steps 2 and 4 are not done twice).
-- When Read Map had to open the World window just to show the paper, putting the
-- paper away closes the World window again (as closing the game's map window
-- returns you to play); a World window that was already open stays (P.closed).
-- ============================================================================

require "ZeD/Tr"
require "ZeD/MapsTab"
require "ZeD/MapsTabExt"

ZeD = ZeD or {}
ZeD.PaperMap = ZeD.PaperMap or {}
local P = ZeD.PaperMap

-- the paper map the unfolded window shows now, or nil
function P.itemOf(win)
    if not (win and win._mapPopout) then return nil end
    return win._mapPaperItem
end

-- Read Map in ZeD's window. True when ZeD shows it (the game's read is done);
-- false sends the read to the game's own window, untouched.
function P.open(item, playerNum)
    playerNum = playerNum or 0
    local playerObj = getSpecificPlayer(playerNum)
    if not (item and playerObj) then return false end
    -- the window the controller reads from, to go back to (another paper's: where that one came from)
    local Focus = ZeD.Input and ZeD.Input.Focus
    local back = Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() or nil
    if back and back._isMapPopout then
        local w0 = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
        back = w0 and w0._mapPaperBack or nil
    end
    if not (ZeD.MapsTab and ZeD.MapsTab.openPopout and ZeD_WorldWindow and ZeD_WorldWindow.getWindow) then return false end
    local win = ZeD_WorldWindow.getWindow()
    -- (one World window: another split-screen player's keeps it, and this player reads in the game's window)
    if win and win._playerObj ~= playerObj then return false end
    local opened = false   -- (the World window opened here, only for the paper)
    if not win then
        if not pcall(ZeD_WorldWindow.open, playerNum) then return false end
        win = ZeD_WorldWindow.getWindow()
        opened = win ~= nil
    end
    if not (win and win._playerObj == playerObj) then return false end
    -- (another paper over one that opened the World window: this one closes it too)
    local owns = opened or (win._mapPaperItem ~= nil and win._mapPopout ~= nil and win._mapPaperOwnsWindow == true)
    if win._mapPopout then ZeD.MapsTab.closePopout(win, true) end   -- (the world map, or another paper)
    local ok, err = pcall(ZeD.MapsTab.openPopout, win, item)
    if not (ok and win._mapPopout and win._mapPaperItem == item) then
        if not ok then print("[ZeD] paper map: " .. tostring(err)) end
        if win._mapPopout then pcall(ZeD.MapsTab.closePopout, win, true) end
        -- (the game's window reads it: a World window opened for the paper goes again)
        if owns and ZeD_WorldWindow.getWindow() == win and ZeD_WorldWindow.close then pcall(ZeD_WorldWindow.close) end
        return false
    end
    win._mapPaperOwnsWindow = owns or nil
    win._mapPaperBack = back
    -- the game's read (steps 2 and 4; 5 to 7 come with the map's drawing: instantiate, frame)
    local ok2, err2 = pcall(function()
        item:doBuildingStash()
        playerObj:addReadMap(item)
    end)
    if not ok2 then print("[ZeD] paper map read: " .. tostring(err2)) end
    return true
end

-- The paper map is put away (MapsTab.closePopout): the controller goes back to
-- the window Read Map was chosen in, and a World window Read Map opened only for
-- the paper closes again, unless the fold came from the World window itself
-- (keepWorld: its own close or fold, the world map opening there, another paper).
function P.closed(win, pop, keepWorld)
    local owns = win._mapPaperOwnsWindow
    win._mapPaperOwnsWindow = nil
    pcall(P.returnFocus, win, pop)
    if not owns or keepWorld then return false end
    if not (ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.close) then return false end
    if ZeD_WorldWindow.getWindow() ~= win then return false end
    ZeD_WorldWindow.close()
    return true
end

-- The paper map is put away (MapsTab.closePopout): the controller goes back to
-- the window Read Map was chosen in (the inventory it read the map from), when
-- that is still up; else the focus manager's own hand-back stands.
function P.returnFocus(win, pop)
    local back = win._mapPaperBack
    win._mapPaperBack = nil
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and back) or back == pop or back._isMapPopout then return false end
    if Focus.isRegistered and not Focus.isRegistered(back) then return false end
    Focus.claimFocus(back)
    return true
end

-- ZeD_WorldMap:instantiate for a paper map (MapsTab.lua): bound to the item
-- and set up as vanilla's ISMap (instantiate, then initMapData), with ZeD's
-- mark pictures for the tools' previews.
function P.instantiate(mp, icons)
    local item = mp._paperItem
    local api = mp.mapAPI
    mp.mapObj = item                  -- (LootMaps.callLua reads mapUI.mapItem or mapUI.mapObj)
    api:setBoolean("Isometric", false)
    api:setMapItem(item)              -- the paper's own symbols (before anything asks for them)
    mp._zedNotesBound = true          -- (MapNotes.panelAPI: this map's symbols, for hit tests and marks)
    mp._annotTextures = {}
    for _, icon in ipairs(icons or {}) do mp._annotTextures[icon.id] = getTexture(icon.tex) end
    local jo = mp.javaObject
    jo:setX(mp.x)
    jo:setY(mp.y)
    jo:setWidth(mp.width)
    jo:setHeight(mp.height)
    jo:setAnchorLeft(true)
    jo:setAnchorRight(false)
    jo:setAnchorTop(true)
    jo:setAnchorBottom(true)
    P.init(mp)
end

-- ISMap:initMapData: the paper's area and look, and its reveal on the world map
function P.init(mp)
    if LootMaps and LootMaps.callLua then LootMaps.callLua("Init", mp) end
    if ZeD.MapsTab.scaleLabels then ZeD.MapsTab.scaleLabels(mp) end   -- (its names grow with the UI, as the world map's)
    P.reveal(mp)
end

function P.reveal(mp)
    if MapUtils and MapUtils.revealKnownArea then MapUtils.revealKnownArea(mp) end
    if isClient() then
        local api = mp.mapAPI
        sendClientCommand(mp.playerObj, "map", "setKnownInSquares", {
            x1 = api:getMinXInSquares(), y1 = api:getMinYInSquares(),
            x2 = api:getMaxXInSquares(), y2 = api:getMaxYInSquares(),
        })
    end
    mp._paperRevealed = true
end

-- Each frame the paper map draws (ZeD_WorldMap:render): the whole paper in view
-- once it has its size (ISMap:update's resetView after initMapData).
function P.frame(mp)
    if mp._paperViewSet then return end
    mp._paperViewSet = true
    pcall(function() mp.mapAPI:resetView() end)
end

-- the map is still in the main inventory (ISMap:update closes it otherwise)
function P.stillHeld(win)
    local item, p = win and win._mapPaperItem, win and win._playerObj
    if not (item and p) or p:isDead() then return false end
    return p:getInventory():contains(item, true) == true
end

-- The paper map could not be drawn (MapsTab.lua): its window is put away and the
-- game's opens on the same map (next tick, out of the drawing).
function P.failed(win, err)
    print("[ZeD] paper map not drawn: " .. tostring(err))
    win._mapPaperFail = { item = win._mapPaperItem, playerNum = win._playerObj and win._playerObj:getPlayerNum() or 0 }
end

-- The game's paper map window alone (ISInventoryPaneContextMenu.onCheckMap after
-- its transfer, without doBuildingStash and addReadMap: ZeD has done those).
function P.openVanilla(item, playerNum)
    if not (ISMap and ISMapWrapper and item) then return false end
    playerNum = playerNum or 0
    local pad = JoypadState and JoypadState.players and JoypadState.players[playerNum + 1]
    if pad then
        local inv, loot = getPlayerInventory(playerNum), getPlayerLoot(playerNum)
        if inv then inv:setVisible(false) end
        if loot then loot:setVisible(false) end
    end
    local titleBarHgt = ISCollapsableWindow.TitleBarHeight()
    local x = getPlayerScreenLeft(playerNum) + 20
    local y = getPlayerScreenTop(playerNum) + 20
    local width = getPlayerScreenWidth(playerNum) - 20 * 2
    local height = getPlayerScreenHeight(playerNum) - 20 * 2 - titleBarHgt
    local mapUI = ISMap:new(x, y, width, height, item, playerNum)
    mapUI:initialise()
    local wrap = mapUI:wrapInCollapsableWindow(item:getName(), false, ISMapWrapper)
    wrap:setInfo(getText("IGUI_Map_Info"))
    wrap:setWantKeyEvents(true)
    mapUI.wrap = wrap
    wrap.mapUI = mapUI
    wrap:setVisible(true)
    wrap:addToUIManager()
    if pad then setJoypadFocus(playerNum, mapUI) end
    return true
end

-- Each tick: the paper map's window is put away when the map leaves the main
-- inventory, and a paper ZeD could not draw goes to the game's window.
function P.tick()
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if not win then return end
    local fail = win._mapPaperFail
    if fail then
        win._mapPaperFail = nil
        if win._mapPopout and win._mapPaperItem then ZeD.MapsTab.closePopout(win) end
        local ok, err = pcall(P.openVanilla, fail.item, fail.playerNum)
        if not ok then print("[ZeD] paper map, the game's window: " .. tostring(err)) end
        return
    end
    if win._mapPopout and win._mapPaperItem and not P.stillHeld(win) then
        ZeD.MapsTab.closePopout(win)
    end
end

-- A stash map's reveal button (ISMap REVEAL, revealOnWorldMap): the game's
-- map-reading action, centered on the paper's area at its zoom; its end opens
-- ZeD's own map there (Overrides/WorldMap.lua puts the paper away first).
function P.revealOnWorldMap(win)
    local mp = win and win._worldMapPanel
    local p = win and win._playerObj
    if not (mp and mp._paperItem and p and P.itemOf(win)) then return false end
    if not (ISWorldMap and ISWorldMap.IsAllowed and ISWorldMap.IsAllowed()) then return false end
    local api = mp.mapAPI
    local cx = (api:getMinXInSquares() + api:getMaxXInSquares()) / 2
    local cy = (api:getMinYInSquares() + api:getMaxYInSquares()) / 2
    setJoypadIgnoreAimUntilCentered(p:getPlayerNum(), true)
    ISTimedActionQueue.clear(p)
    ISTimedActionQueue.add(ISReadWorldMap:new(p, cx, cy, api:getZoomF()))
    return true
end

-- the reveal button on the band, on a stash map only (as vanilla's)
local R = { order = 5, paper = true }
function R.button(win)
    local item = P.itemOf(win)
    if not item then return nil end
    local stash = item:getStashMap()
    if stash == nil or stash == "" then return nil end
    local allowed = ISWorldMap and ISWorldMap.IsAllowed and ISWorldMap.IsAllowed()
    return {
        id = "paperfind",
        text = ZeD.tr("UI_ZeD_Map_PaperFind"),
        help = ZeD.tr("UI_ZeD_Map_HelpPaperFind"),
        hint = (not allowed) and ZeD.tr("UI_ZeD_Map_Unavailable") or nil,
        dim = not allowed,
        activate = function(w) P.revealOnWorldMap(w) end,
    }
end
P.ext = R
ZeD.MapsTab.addExtension("paperfind", R)

if not P._tickAdded and Events and Events.OnTick then
    P._tickAdded = true
    Events.OnTick.Add(function() P.tick() end)
end
