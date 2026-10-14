-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Furniture.lua
-- ============================================================================
-- FURNITURE HOOKS — HOOK_MAP row 15
--   * Moveables mode: ZeD.FurnitureTab hooks ISMoveableCursor.setInfoPanel
--     (to read what the cursor reads) and ISMoveableInfoWindow.render (quiet
--     while the Furniture tab is up), and opens the tab for a cursor started
--     any other way. Nothing more is needed here.
--   * Extended 3D Placement: ISExtendedPlacementAction:perform (vanilla walks
--     next to the item first) opens the placement card in the World window
--     card drawer instead of ISExtendedPlacementUI. Controller players get
--     the option back (the engine leaves it out for them), in the world
--     menu and on a ground item's menu.
-- Vanilla runs only when ZeD declines (no World window, item gone).
-- ============================================================================

require "ZeD/ObjectCards"
require "ZeD/FurnitureTab"
require "ZeD/ObjectCardPlacement"

local OC = ZeD.ObjectCards

-- ---------------------------------------------------------------------------
-- Extended 3D Placement for controller players. The engine builds the world
-- menu's option in Java (ISWorldObjectContextMenuLogic.handleGrabWorldItem)
-- and leaves it out for a player with a controller; the placement card works
-- with the D-pad, so ZeD puts it back:
--   * the world menu (X), for exactly the players the engine leaves out;
--   * a ground item's menu in the Loot tab, for everyone (that is where a
--     controller player reaches items on the ground).
-- Same items as vanilla: lying in the world, with a 3D model, clothing or a
-- weapon, and no wall between it and you.
-- ---------------------------------------------------------------------------
local PLACE_MAX = 12

local function placeable(wi, player)
    if not (wi and instanceof(wi, "IsoWorldInventoryObject")) then return false end
    local item = wi:getItem()
    if not item then return false end
    if not (item:getWorldStaticItem() ~= nil or item:getClothingItem() ~= nil or instanceof(item, "HandWeapon")) then return false end
    local sq, psq = wi:getSquare(), player:getSquare()
    return sq ~= nil and not (psq and sq ~= psq and sq:isWallTo(psq))
end

-- one option, or a submenu when there are several
local function addPlaceOption(context, list, player)
    local label = getText("ContextMenu_ExtendedPlacement")
    if #list == 1 then
        local o = context:addOption(label, list[1], ISWorldObjectContextMenu.onExtendedPlacement, player)
        o.itemForTexture = list[1]:getItem()
        return
    end
    local opt = context:addOption(label)
    local sub = ISContextMenu:getNew(context)
    context:addSubMenu(opt, sub)
    for _, wi in ipairs(list) do
        local o = sub:addOption(wi:getItem():getDisplayName(), wi, ISWorldObjectContextMenu.onExtendedPlacement, player)
        o.itemForTexture = wi:getItem()
    end
end

local function onFillWorld(pn, context, worldobjects, test)
    if not (JoypadState and JoypadState.players[pn + 1]) then return end   -- the engine offers it to everyone else
    local player = getSpecificPlayer(pn)
    if not (player and worldobjects) or player:getVehicle() then return end
    local seen, list = {}, {}
    for _, o in ipairs(worldobjects) do
        local sq = o and o.getSquare and o:getSquare()
        if sq and not seen[sq] then
            seen[sq] = true
            local wos = sq:getWorldObjects()
            for i = 0, wos:size() - 1 do
                local wi = wos:get(i)
                if #list < PLACE_MAX and placeable(wi, player) then list[#list + 1] = wi end
            end
        end
    end
    if #list == 0 then return end
    if test then return ISWorldObjectContextMenu.setTest() end
    addPlaceOption(context, list, player)
end

local function onFillInventory(pn, context, items)
    local player = getSpecificPlayer(pn)
    if not (player and items) or player:getVehicle() then return end
    local list = {}
    for _, it in ipairs(ISInventoryPane.getActualItems(items)) do
        local wi = it.getWorldItem and it:getWorldItem()
        if #list < PLACE_MAX and placeable(wi, player) then list[#list + 1] = wi end
    end
    if #list > 0 then addPlaceOption(context, list, player) end
end

-- through a table, so a reload replaces the handlers without adding more
ZeD.FurniturePlace = { onFillWorld = onFillWorld, onFillInventory = onFillInventory, placeable = placeable }
if not ZeD._furniturePlaceMenus then
    ZeD._furniturePlaceMenus = true
    Events.OnFillWorldObjectContextMenu.Add(function(...) return ZeD.FurniturePlace.onFillWorld(...) end)
    Events.OnFillInventoryObjectContextMenu.Add(function(...) return ZeD.FurniturePlace.onFillInventory(...) end)
end

local function apply()
    if ZeD.FurnitureTab and ZeD.FurnitureTab.install then ZeD.FurnitureTab.install() end
    if ISExtendedPlacementAction and not ISExtendedPlacementAction._zedHooked then
        ISExtendedPlacementAction._zedHooked = true
        local orig = ISExtendedPlacementAction.perform
        ISExtendedPlacementAction.perform = function(self)
            local ok, handled = pcall(OC.open, self.character, "place3d", self.item)
            if ok and handled then
                ISBaseTimedAction.perform(self)
                return
            end
            if not ok then print("[ZeD] Furniture: placement route failed: " .. tostring(handled)) end
            return orig(self)
        end
    end
    print("[ZeD] Overrides/Furniture: moveables info and extended placement routed to the Furniture tab and placement card")
end

if Events and Events.OnGameBoot then Events.OnGameBoot.Add(apply) end
apply()
