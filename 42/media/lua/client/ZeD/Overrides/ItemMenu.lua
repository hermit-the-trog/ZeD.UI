-- ZeD-UI/42/media/lua/client/ZeD/Overrides/ItemMenu.lua
-- ============================================================================
-- MENU ADDITIONS — things that had only one way in
--   * Move to (an item's menu): the World window's open container, your main
--     inventory, the bags you wear or hold, key rings, the floor. Vanilla shows
--     its own only to controller players and aims it at its hidden loot page;
--     ZeD's replaces it for everyone, so stashing is not drag-only.
--   * Rename (an item's menu): any item, as the card's name row does. Vanilla
--     names only bags, keys and evolved dishes; those keep vanilla's option.
--   * Loot all / Transfer all (an item's menu, controller): vanilla's pair
--     reads the hidden pages; ZeD's use the windows' containers.
--   * Take all (a container's world menu): empty a container you can see
--     without opening the World window first.
-- The moves go through ZeD.ContainerControls (ZeD's floor, corpse items,
-- vanilla's walk-to-container).
-- ============================================================================

require "ISUI/ISInventoryPaneContextMenu"
require "ISUI/ISTextBox"
require "ZeD/ContainerControls"
require "ZeD/SafeMode"

-- In safe mode (SafeMode.lua) both menu fillers step aside: vanilla's own
-- Move To / Loot all / Transfer all stay, aimed at its own pages, which are back.

local CT = ZeD.ContainerControls
local RENAME_MAX = 28   -- vanilla's MAXIMUM_RENAME_LENGTH

local function txt(key, fallback) return getTextOrNull(key) or fallback end

-- The World window's open container, if it is a real one (not the floor)
local function worldActive()
    local win = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if not (win and win:isVisible() and win._containers and win._activeContainer) then return nil end
    local e = win._containers[win._activeContainer]
    if not (e and e.inventory and not e.isFloor and not e.locked) then return nil end
    return e.inventory, e.name
end

local function floorInv(pn)
    local f = ZeD_WorldWindow and ZeD_WorldWindow.getFloorContainer and ZeD_WorldWindow.getFloorContainer()
    return f or (ISInventoryPage and ISInventoryPage.GetFloorContainer and ISInventoryPage.GetFloorContainer(pn))
end

-- true when every item already sits in inv
local function allIn(items, inv)
    for _, it in ipairs(items) do if it:getContainer() ~= inv then return false end end
    return true
end

local function onMove(items, dest, pn)
    local playerObj = getSpecificPlayer(pn)
    if not playerObj then return end
    if dest:getType() ~= "floor" and not luautils.walkToContainer(dest, pn) then return end
    local keep = {}
    for _, it in ipairs(items) do
        if not it:isFavorite() then
            if playerObj:isEquipped(it) then ISTimedActionQueue.add(ISUnequipAction:new(playerObj, it, 50)) end
            keep[#keep + 1] = it
        end
    end
    CT.moveItems(playerObj, keep, dest)
end

local function addMoveTo(context, playerObj, pn, items)
    local dests = {}
    local function add(name, inv)
        if inv and not allIn(items, inv) then dests[#dests + 1] = { name = name, inv = inv } end
    end
    local wInv, wName = worldActive()
    add(wName or txt("ContextMenu_MoveToContainer", "Container"), wInv)
    add(txt("ContextMenu_MoveToInventory", "Inventory"), playerObj:getInventory())
    local seen = {}
    local function bag(item)
        if item and not seen[item] and ISInventoryPaneContextMenu.canMoveTo(items, item, pn) then
            seen[item] = true
            add(item:getName(), item:getInventory())
        end
    end
    local worn = playerObj:getWornItems()
    for i = 0, worn:size() - 1 do bag(worn:get(i):getItem()) end
    bag(playerObj:getPrimaryHandItem())
    bag(playerObj:getSecondaryHandItem())
    local inv = playerObj:getInventory():getItems()
    for i = 0, inv:size() - 1 do
        local it = inv:get(i)
        if it:isItemType(ItemType.KEY_RING) or it:hasTag(ItemTag.KEY_RING) then bag(it) end
    end
    add(txt("ContextMenu_Floor", "Floor"), floorInv(pn))
    if #dests == 0 then return end
    local option = context:addOption(txt("ContextMenu_Move_To", "Move To"))
    local sub = context:getNew(context)
    context:addSubMenu(option, sub)
    for _, d in ipairs(dests) do
        local o = sub:addOption(d.name, items, onMove, d.inv, pn)
        if d.inv:getType() ~= "floor" and not ISInventoryPaneContextMenu.hasRoomForAny(playerObj, d.inv, items) then
            o.notAvailable = true
        end
    end
end

-- Rename: vanilla's prompt and length rule, for anything vanilla does not name
local function vanillaNames(item)
    if instanceof(item, "InventoryContainer") or instanceof(item, "Key") then return true end
    if item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING) then return true end
    if instanceof(item, "Food") and item:haveExtraItems() and item:getExtraItems():size() >= 3 then return true end
    return false
end

local function onRenameClick(_, button, playerObj, item)
    if button.internal ~= "OK" then return end
    local entry = button.parent and button.parent.entry
    local text = entry and entry:getText() or ""
    text = text:match("^%s*(.-)%s*$")
    if text == "" then return end
    if text:len() > RENAME_MAX then
        HaloTextHelper.addBadText(playerObj, getText("IGUI_PlayerText_ItemNameTooLong", RENAME_MAX))
        return
    end
    item:setName(text)
    item:setCustomName(true)
    pcall(function() item:syncItemFields() end)
end

local function onRename(item, pn)
    local box = ISTextBox:new(0, 0, 280, 180, "Name this item", item:getName(), nil, onRenameClick, pn, getSpecificPlayer(pn), item)
    box:initialise()
    box:addToUIManager()
    if JoypadState.players[pn + 1] then setJoypadFocus(pn, box) end
end

local function onFillInventory(pn, context, rawItems)
    if ZeD.Safe.on() then return end
    local playerObj = getSpecificPlayer(pn)
    if not (playerObj and context and rawItems) then return end
    local items = ISInventoryPane.getActualItems(rawItems)
    if #items == 0 then return end
    -- vanilla's controller-only Move To / Loot all / Transfer all aim at its hidden pages
    context:removeOptionByName(txt("ContextMenu_Move_To", "Move To"))
    local hadLoot = context:getOptionFromName(txt("IGUI_invpage_Loot_all", "Loot all")) ~= nil
    local hadXfer = context:getOptionFromName(txt("IGUI_invpage_Transfer_all", "Transfer all")) ~= nil
    if hadLoot then context:removeOptionByName(txt("IGUI_invpage_Loot_all", "Loot all")) end
    if hadXfer then context:removeOptionByName(txt("IGUI_invpage_Transfer_all", "Transfer all")) end

    addMoveTo(context, playerObj, pn, items)

    local src = items[1]:getContainer()
    if hadLoot and src then
        context:addOption(txt("IGUI_invpage_Loot_all", "Loot all"), playerObj, CT.takeAll, src, playerObj:getInventory())
    end
    local wInv = worldActive()
    if hadXfer and src and (wInv or floorInv(pn)) then
        context:addOption(txt("IGUI_invpage_Transfer_all", "Transfer all"), playerObj, CT.transferAll, src, wInv or floorInv(pn))
    end

    if #items == 1 and not vanillaNames(items[1]) then
        context:addOption("Rename", items[1], onRename, pn)
    end
end

-- Take all on a container's world menu
local function containerTitle(c)
    return getTextOrNull("IGUI_ContainerTitle_" .. tostring(c:getType())) or tostring(c:getType())
end

local function padlocked(obj)
    local ok, r = pcall(function()
        return (obj.isLockedByPadlock and obj:isLockedByPadlock()) or (obj.getLockedByCode and obj:getLockedByCode() > 0)
    end)
    return ok and r or false
end

local function onFillWorld(pn, context, worldobjects, test)
    if test or ZeD.Safe.on() then return end
    local playerObj = getSpecificPlayer(pn)
    if not (playerObj and context and worldobjects) or playerObj:getVehicle() then return end
    local found, seen = {}, {}
    for _, obj in ipairs(worldobjects) do
        if obj and not seen[obj] and obj.getContainerCount and not padlocked(obj) then
            seen[obj] = true
            for i = 0, obj:getContainerCount() - 1 do
                local c = obj:getContainerByIndex(i)
                if c and c:isExplored() and not c:isEmptyOrUnwanted(playerObj) then found[#found + 1] = c end
            end
        end
    end
    if #found == 0 then return end
    local label = "Take all"
    if #found == 1 then
        context:addOption(label, playerObj, CT.takeAll, found[1], playerObj:getInventory())
        return
    end
    local option = context:addOption(label)
    local sub = context:getNew(context)
    context:addSubMenu(option, sub)
    for _, c in ipairs(found) do
        sub:addOption(containerTitle(c), playerObj, CT.takeAll, c, playerObj:getInventory())
    end
end

if not _G._zedItemMenuHooked then
    _G._zedItemMenuHooked = true
    Events.OnFillInventoryObjectContextMenu.Add(onFillInventory)
    Events.OnFillWorldObjectContextMenu.Add(onFillWorld)
end

-- the card's name row asks through the same prompt with a controller
ZeD.ItemMenu = ZeD.ItemMenu or {}
ZeD.ItemMenu.rename = onRename
