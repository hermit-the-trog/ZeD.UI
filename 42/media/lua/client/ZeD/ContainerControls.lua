-- ZeD-UI/42/media/lua/client/ZeD/ContainerControls.lua
-- ============================================================================
-- CONTAINER BUTTONS — vanilla B42's row of container controls in the ZeD
-- windows (mockup ZeDUI/mockups/zed_container_controls_v1.html, built
-- Oct 16 2026; v2 Oct 16 2026: zed_container_controls_v2.html). One row at
-- the bottom of each window's list ("less noise down there"; the director
-- tried the container's own actions in the heading and kept them here:
-- "bottom row works best"). Common actions are icons that name themselves
-- in a hover hint, the unique ones are words. For the container on show:
--   Character window (your side), bottom row: Transfer all | Same type |
--     Same type, all nearby (icons)
--   World window (the other side), bottom row: Take all | Same type |
--     To floor (not on the floor) (icons), then after a divider the
--     container's own buttons, vanilla's object controls, words first then
--     icons (a stove's
--     power and settings, a washer's switch, a mannequin's Wear all / Switch
--     outfits, a car trunk's Close trunk / lock, a campfire's Take apart /
--     light / add fuel / put out, a propane barbecue's tank and switch,
--     buttons other mods register) and a trash can's Delete all (the bin),
--     whose question takes over the bottom row.
-- The moves keep vanilla's rules (ISInventoryPane:lootAll / transferAll and
-- the same-type handlers' item tables) but aim at the containers the ZeD
-- windows show, never at vanilla's parked pages. Items go through vanilla's
-- transfer action, or ZeD's floor path (InventoryRenderer.handleDrop's rules).
-- The container's own buttons are vanilla's handler classes
-- (ISLootWindowContainerControls_HandlerList) run with a small stand-in for
-- vanilla's loot window, so their visibility rules stay vanilla's. Light and
-- Add fuel open the fire card on its own lists instead of a context menu.
-- The row is one line, a ribbon that scrolls sideways when its buttons are
-- wider than the list (the wheel, its arrows, the controller's focus).
-- Pointing at (or focusing) a Same type button marks the rows it would move.
-- On a controller the buttons are stops in their own ring zone (charCtl /
-- worldCtl, appended to the window's ring), reached by the D-pad.
-- The row is drawn by InventoryRenderer.renderItemList (single-container view
-- only) for a content panel that carries _ccSide ("char" / "world") and
-- _ccWin; the windows set _ccEntry to the container entry on show.
-- ============================================================================

require "ZeD/ObjectCards"

ZeD = ZeD or {}
ZeD.ContainerControls = ZeD.ContainerControls or {}
local CT = ZeD.ContainerControls

CT.ROW_H   = 28    -- design units: one line of buttons
CT.BTN_H   = 20
CT.PAD_X   = 7
CT.GAP     = 5
CT.DIV_PAD = 5     -- each side of the divider before the container's own buttons
CT.REFRESH = 15    -- frames between rebuilding the button set (sooner when items change)

-- vanilla's moves, done here on the ZeD windows' containers
local OURS = {
    ISLootWindowObjectControlHandler_TakeAll      = true,
    ISLootWindowObjectControlHandler_TakeSameType = true,
    ISLootWindowObjectControlHandler_MoveToFloor  = true,
    ISLootWindowObjectControlHandler_RemoveAll    = true,
    ISLootWindowFloorControlHandler_TakeAll       = true,
    ISLootWindowFloorControlHandler_TakeSameType  = true,
    ISInventoryWindowControlHandler_TransferAll                   = true,
    ISInventoryWindowControlHandler_TransferSameType              = true,
    ISInventoryWindowControlHandler_TransferSameTypeMultiContainer = true,
}
-- vanilla's own object controls: their Title Case words become button words;
-- a few read as the fire card's verbs do. Mods' handlers keep their words.
local VANILLA = {
    ISLootWindowObjectControlHandler_MannequinWearAll              = true,
    ISLootWindowObjectControlHandler_MannequinSwitchOutfit         = true,
    ISLootWindowObjectControlHandler_PropaneBarbecueRemoveTank     = "Remove tank",
    ISLootWindowObjectControlHandler_PropaneBarbecueAddTank        = "Insert tank",
    ISLootWindowObjectControlHandler_PropaneBarbecueToggle         = true,
    ISLootWindowObjectControlHandler_ClothingWasherToggle          = true,
    ISLootWindowObjectControlHandler_ClothingDryerToggle           = true,
    ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode = true,
    ISLootWindowObjectControlHandler_CombinationWasherDryerToggle  = true,
    ISLootWindowObjectControlHandler_StoveSettings                 = true,
    ISLootWindowObjectControlHandler_StoveToggle                   = true,
    ISLootWindowObjectControlHandler_VehicleLockTrunk              = true,
    ISLootWindowObjectControlHandler_VehicleCloseTrunk             = true,
    ISLootWindowObjectControlHandler_PutOut                        = "Put out",
    ISLootWindowObjectControlHandler_LightFireOption               = "Light",
    ISLootWindowObjectControlHandler_AddFuelOption                 = "Add fuel",
    ISLootWindowObjectControlHandler_RemoveCampfire                = "Take apart",
    ISLootWindowObjectControlHandler_AddCorpseToCampfire           = "Add corpse",
}
-- vanilla's object controls many objects share draw as icons (the ZeD icon
-- library); the rest stay words (director, Oct 16 2026: "can common actions
-- be an icon, and unique actions be text?" ... "hover hints where it matters")
local VANILLA_ICON = {
    ISLootWindowObjectControlHandler_StoveToggle                  = "power",
    ISLootWindowObjectControlHandler_ClothingWasherToggle         = "power",
    ISLootWindowObjectControlHandler_ClothingDryerToggle          = "power",
    ISLootWindowObjectControlHandler_CombinationWasherDryerToggle = "power",
    ISLootWindowObjectControlHandler_PropaneBarbecueToggle        = "power",
    ISLootWindowObjectControlHandler_StoveSettings                = "settings",
    ISLootWindowObjectControlHandler_LightFireOption              = "fi-br-match-fire",
    ISLootWindowObjectControlHandler_AddFuelOption                = "fi-br-campfire",
    ISLootWindowObjectControlHandler_PutOut                       = "fi-br-fire-extinguisher",
    ISLootWindowObjectControlHandler_VehicleLockTrunk             = "lock",
}
-- these open the fire card on one of its lists (its own Light / Add fuel)
local FIRE_JUMP = {
    ISLootWindowObjectControlHandler_LightFireOption = "fire:light:1",
    ISLootWindowObjectControlHandler_AddFuelOption   = "fire:fuel:1",
}

local function isFloor(inv) return inv ~= nil and inv:getType() == "floor" end

-- any key in a set (Kahlua has no next())
local function hasAny(t) for _ in pairs(t) do return true end return false end

local function zedFloor()
    return ZeD_WorldWindow and ZeD_WorldWindow.getFloorContainer and ZeD_WorldWindow.getFloorContainer() or nil
end

-- A vanilla Title Case label as a button word ("Set Mode: Dryer" -> "Set mode: dryer")
local function sentence(s)
    s = tostring(s or "")
    return s:sub(1, 1):upper() .. s:sub(2):lower()
end

-- vanilla's getItemsTable: full type (and a garment's extra variants) -> its items
local function itemsTable(container)
    local result = {}
    local items = container and container:getItems()
    if not items then return result end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local t = item:getFullType()
        result[t] = result[t] or {}
        table.insert(result[t], item)
        local extra = item:getClothingItemExtra()
        if extra ~= nil then
            for j = 0, extra:size() - 1 do
                t = moduleDotType(item:getModule(), extra:get(j))
                result[t] = result[t] or {}
                table.insert(result[t], item)
            end
        end
    end
    return result
end

-- the items in src of a type ref also holds, that keep(item) lets go
local function sameTypeItems(src, ref, keep)
    local out, set = {}, {}
    if not (src and ref) or src == ref then return out, set end
    local mine, theirs = itemsTable(src), itemsTable(ref)
    for t in pairs(theirs) do
        local list = mine[t]
        if list then
            for _, item in ipairs(list) do
                if not set[item] and keep(item) then set[item] = true; out[#out + 1] = item end
            end
        end
    end
    return out, set
end

-- vanilla's order for a transfer: by type, lightest kinds first
local function sortForTransfer(items)
    if ISInventoryPane and ISInventoryPane.sortItemsByTypeAndWeight then
        pcall(ISInventoryPane.sortItemsByTypeAndWeight, nil, items)
    end
end

-- ----------------------------------------------------------------------------
-- MOVING (vanilla's ISInventoryPane:transferItemsByWeight, with ZeD's floor)
-- ----------------------------------------------------------------------------
function CT.moveItems(playerObj, items, dest)
    if not (playerObj and dest and items and #items > 0) then return end
    local pn = playerObj:getPlayerNum()
    local floor = zedFloor()
    sortForTransfer(items)
    if isFloor(dest) then
        local drop = {}
        for _, item in ipairs(items) do
            if not item:isFavorite() and item:getContainer() ~= floor then drop[#drop + 1] = item end
        end
        if #drop > 0 then ISInventoryPaneContextMenu.onDropItems(drop, pn) end
        return
    end
    for _, item in ipairs(items) do
        local src = item:getContainer()
        if src == nil or src == dest then
            -- moved or gone since the row was built
        elseif floor and src == floor then
            ZeD_WorldWindow.transferFromFloor(playerObj, item, dest)
        elseif dest:isItemAllowed(item) then
            if corpseStorageCheck and corpseStorageCheck.isPlayerGrabbingCorpseItem(pn, item, dest) then
                if playerObj:getVehicle() then return end
                ISTimedActionQueue.add(ISGrabCorpseItem:new(playerObj, item))
                break
            end
            ISTimedActionQueue.add(ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, src, dest))
        end
    end
end

-- Take all: ISInventoryPane:lootAll's rule. The unwanted stay; a heavy item
-- that is alone in the container is picked up in the hands.
local function takeAllItems(playerObj, src)
    local items, heavy = {}, nil
    local it = src:getItems()
    for i = 0, it:size() - 1 do
        local item = it:get(i)
        if not item:isUnwanted(playerObj) then
            if isForceDropHeavyItem and isForceDropHeavyItem(item) then heavy = item
            else items[#items + 1] = item end
        end
    end
    return items, heavy, it:size()
end

-- Transfer all: ISInventoryPane:transferAll's rule (nothing worn, held,
-- favourite, on the hotbar, or your key ring; furniture that cannot lie on
-- the floor stays when the target is the floor)
local function transferAllItems(playerObj, src, dest)
    local items = {}
    if not (src and dest) or src == dest then return items end
    local hotBar = getPlayerHotbar(playerObj:getPlayerNum())
    local toFloor = isFloor(dest)
    local mainInv = src == playerObj:getInventory()
    local it = src:getItems()
    for i = 0, it:size() - 1 do
        local item = it:get(i)
        local keyRing = false
        if mainInv then
            local ok, kr = pcall(function() return item:isItemType(ItemType.KEY_RING) or item:hasTag(ItemTag.KEY_RING) end)
            keyRing = ok and kr or false
        end
        local ok = not item:isEquipped() and not keyRing and not item:isFavorite()
            and not (hotBar and hotBar:isInHotbar(item))
        if ok and toFloor and instanceof(item, "Moveable") and item:getSpriteGrid() == nil and not item:CanBeDroppedOnFloor() then
            ok = false
        end
        if ok then items[#items + 1] = item end
    end
    return items
end

-- The same two moves from outside the windows (a container's world menu, an
-- item's menu with a controller). Walks to a container first, as vanilla does.
function CT.takeAll(playerObj, src, dest)
    if not (playerObj and src) then return end
    dest = dest or playerObj:getInventory()
    if not isFloor(src) and not luautils.walkToContainer(src, playerObj:getPlayerNum()) then return end
    local items, heavy, n = takeAllItems(playerObj, src)
    if heavy and n == 1 then
        ISInventoryPaneContextMenu.equipHeavyItem(playerObj, heavy)
        return
    end
    CT.moveItems(playerObj, items, dest)
end

function CT.transferAll(playerObj, src, dest)
    if not (playerObj and src and dest) then return end
    if not isFloor(dest) and not luautils.walkToContainer(dest, playerObj:getPlayerNum()) then return end
    CT.moveItems(playerObj, transferAllItems(playerObj, src, dest), dest)
end

-- Same type, all nearby: vanilla's multi-container transfer. Each container
-- takes the things of a type it already holds, as much as it has room for;
-- each thing goes once.
local function nearbyPlan(playerObj, src, containers)
    local plan, set = {}, {}
    if not src then return plan, set end
    local pool = itemsTable(src)
    for _, inv in ipairs(containers) do
        if inv ~= src then
            local list = {}
            for t in pairs(itemsTable(inv)) do
                for _, item in ipairs(pool[t] or {}) do
                    if not set[item] and not item:isFavorite() and not item:isEquipped() then
                        set[item] = true
                        list[#list + 1] = item
                    end
                end
            end
            sortForTransfer(list)
            local total, take = 0, {}
            for _, item in ipairs(list) do
                local w = item:getUnequippedWeight()
                if isFloor(inv) or inv:hasRoomFor(playerObj, total + w) then
                    take[#take + 1] = item
                    total = total + w
                else
                    set[item] = nil   -- no room here; another container may take it
                end
            end
            if #take > 0 then plan[#plan + 1] = { dest = inv, items = take } end
        end
    end
    return plan, set
end

-- ----------------------------------------------------------------------------
-- WHAT EACH ROW HOLDS
-- ----------------------------------------------------------------------------
local function charContent()
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen() and ZeD_CharacterWindow.getWindow()
    return cw and cw._mainContent or nil
end
local function worldWindow()
    return ZeD_WorldWindow and ZeD_WorldWindow.isOpen and ZeD_WorldWindow.isOpen() and ZeD_WorldWindow.getWindow() or nil
end

-- The other side's container: what the other ZeD window shows. Your side's
-- moves need the World window open on one container; the World window's
-- take into the Character window's container, else your inventory.
local function otherInventory(content)
    if content._ccSide == "char" then
        local ww = worldWindow()
        local wc = ww and ww._mainContent
        return (wc and wc._ccEntry and wc._inventory) or nil
    end
    local cc = charContent()
    return (cc and cc._ccEntry and cc._inventory) or (content._playerObj and content._playerObj:getInventory())
end

local function nearbyContainers()
    local ww = worldWindow()
    local out = {}
    for _, e in ipairs(ww and ww._containers or {}) do
        if e.inventory and not e.locked then out[#out + 1] = e.inventory end
    end
    return out
end

-- vanilla's ISLootWindowContainerControls:getDisplayedObject
local function displayedObject(inv)
    if not inv or isFloor(inv) then return nil end
    local outer = inv:getOutermostContainer()
    if outer ~= nil and outer:getVehiclePart() ~= nil then return outer:getVehiclePart():getVehicle() end
    if inv:getContainingItem() ~= nil then return inv:getContainingItem():getWorldItem() end
    return inv:getParent()
end

local function isTrashCan(object)
    if not (object and instanceof(object, "IsoObject")) then return false end
    local sprite = object:getSprite()
    local props = sprite and sprite:getProperties()
    return props ~= nil and props:has("IsTrashCan")
end

-- a stand-in for vanilla's loot window, for handlers that reach into it
local function standIn(content, inv)
    local cc = content._cc
    local s = cc.stand or {}
    cc.stand = s
    local pn = content._playerObj:getPlayerNum()
    s.player, s.inventory, s.onCharacter, s.backpacks = pn, inv, false, {}
    s.inventoryPane = s.inventoryPane or {}
    local pane = s.inventoryPane
    pane.player, pane.inventory, pane.selected = pn, inv, {}
    pane.setItemsToHighlight = function() end
    pane.transferItemsByWeight = function(_, items, dest) CT.moveItems(content._playerObj, items, dest) end
    pane.removeAll = function() end
    s.getX = function() return content:getAbsoluteX() end
    s.getY = function() return content:getAbsoluteY() end
    s.getWidth = function() return content:getWidth() end
    s.getHeight = function() return 0 end
    return s
end

-- vanilla's object controls for the container on show (mods' included)
local function objectSpecs(content, inv, object)
    local specs = {}
    local list = ISLootWindowContainerControls_HandlerList
    if not (list and object) then return specs end
    local cc = content._cc
    cc.handlers = cc.handlers or {}
    local playerObj = content._playerObj
    local stand = standIn(content, inv)
    for _, cls in ipairs(list) do
        local typ = cls.Type
        if not OURS[typ] then
            local h = cc.handlers[cls]
            if not h then
                local ok, made = pcall(cls.new, cls)
                h = ok and made or nil
                cc.handlers[cls] = h
            end
            if h then
                h.lootWindow, h.playerNum, h.playerObj = stand, playerObj:getPlayerNum(), playerObj
                h.object, h.container = object, inv
                local okV, vis = pcall(h.shouldBeVisible, h)
                if okV and vis then
                    local title
                    local fixed = VANILLA[typ]
                    if type(fixed) == "string" then
                        title = fixed
                    else
                        local okC, control = pcall(h.getControl, h)
                        title = okC and control and control.title or ""
                        if title == "" then title = (okC and control and control.tooltip) or tostring(typ):gsub("^.*_", "") end
                        if fixed then title = sentence(title) end
                    end
                    -- the washer-dryer's "Set mode: dryer" reads "Mode: dryer"
                    if typ == "ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode" then
                        title = sentence((title:gsub("^[Ss]et%s+", "")))
                    end
                    local jump = FIRE_JUMP[typ]
                    local icon = VANILLA_ICON[typ]
                    -- a switch lights while the thing runs (its words then read Turn off)
                    local lit = icon == "power" and title:lower() == sentence(getText("ContextMenu_Turn_Off")):lower()
                    specs[#specs + 1] = {
                        id = "obj:" .. tostring(typ), label = title, enabled = true,
                        icon = icon, hint = icon and title or nil, lit = lit,
                        run = function(ct, hit)
                            if jump and ZeD.ObjectCards and ZeD.ObjectCards.open(playerObj, "fire", object) then
                                local ww = ZeD_WorldWindow.getWindow()
                                local card = ww and ww._objectCard
                                if card then card._jumpTo = jump; card._pendingFocus = jump end
                                return
                            end
                            h.lootWindow, h.object, h.container = standIn(ct, inv), object, inv
                            if jump then
                                -- no fire card: vanilla's own menu, under the button
                                local ctx = ISContextMenu.get(playerObj:getPlayerNum(), ct:getAbsoluteX() + hit.x, ct:getAbsoluteY() + hit.y + hit.h)
                                pcall(h.handleJoypadContextMenu, h, ctx)
                                return
                            end
                            local ok, err = pcall(h.perform, h)
                            if not ok then print("[ZeD] ContainerControls: " .. tostring(typ) .. " failed: " .. tostring(err)) end
                        end,
                    }
                end
            end
        end
    end
    return specs
end

-- mods' extra buttons for your side (vanilla's three are the moves)
local function inventorySpecs(content, inv)
    local specs = {}
    local list = ISInventoryWindowContainerControls_HandlerList
    if not list then return specs end
    local cc = content._cc
    cc.invHandlers = cc.invHandlers or {}
    local playerObj = content._playerObj
    local pn = playerObj:getPlayerNum()
    local stand = cc.invStand or {}
    cc.invStand = stand
    stand.player, stand.inventory = pn, inv
    stand.inventoryPane = stand.inventoryPane or {}
    stand.inventoryPane.player, stand.inventoryPane.inventory, stand.inventoryPane.selected = pn, inv, {}
    stand.inventoryPane.setItemsToHighlight = function() end
    stand.inventoryPane.transferItemsByWeight = function(_, items, dest) CT.moveItems(playerObj, items, dest) end
    for _, cls in ipairs(list) do
        if not OURS[cls.Type] then
            local h = cc.invHandlers[cls]
            if not h then
                local ok, made = pcall(cls.new, cls)
                h = ok and made or nil
                cc.invHandlers[cls] = h
            end
            if h then
                h.inventoryWindow, h.playerNum, h.playerObj, h.container = stand, pn, playerObj, inv
                local okV, vis = pcall(h.shouldBeVisible, h)
                if okV and vis then
                    local okC, control = pcall(h.getControl, h)
                    local title = okC and control and control.title or ""
                    if title == "" then title = (okC and control and control.tooltip) or tostring(cls.Type):gsub("^.*_", "") end
                    specs[#specs + 1] = { id = "inv:" .. tostring(cls.Type), label = title, enabled = true,
                        run = function() pcall(h.perform, h) end }
                end
            end
        end
    end
    return specs
end

local function buildChar(content)
    local playerObj = content._playerObj
    local inv = content._inventory
    local dest = otherInventory(content)
    local moves = {}
    local xfer = transferAllItems(playerObj, inv, dest)
    moves[#moves + 1] = { id = "xfer", label = "Transfer all", enabled = dest ~= nil and #xfer > 0,
        icon = "inbox-out", hint = "Transfer all",
        run = function(ct)
            local d = otherInventory(ct)
            CT.moveItems(playerObj, transferAllItems(playerObj, ct._inventory, d), d)
        end }
    local keep = function(item) return not item:isFavorite() and not item:isEquipped() end
    local same, sameSet = sameTypeItems(inv, dest, keep)
    moves[#moves + 1] = { id = "same", label = "Same type", enabled = #same > 0, marks = sameSet,
        icon = "copy", hint = "Put in the kinds it already holds",
        run = function(ct)
            local d = otherInventory(ct)
            CT.moveItems(playerObj, (sameTypeItems(ct._inventory, d, keep)), d)
        end }
    local _, nearSet = nearbyPlan(playerObj, inv, nearbyContainers())
    moves[#moves + 1] = { id = "near", label = "Same type, all nearby", enabled = hasAny(nearSet), marks = nearSet,
        icon = "arrows-from-dotted-line", hint = "Each kind into a nearby container that holds it",
        run = function(ct)
            for _, step in ipairs((nearbyPlan(playerObj, ct._inventory, nearbyContainers()))) do
                CT.moveItems(playerObj, step.items, step.dest)
            end
        end }
    return moves, inventorySpecs(content, inv)
end

local function buildWorld(content)
    local playerObj = content._playerObj
    local pn = playerObj:getPlayerNum()
    local inv = content._inventory
    local dest = otherInventory(content)
    local onFloor = isFloor(inv)
    local moves = {}
    moves[#moves + 1] = { id = "take", label = "Take all", enabled = not inv:isEmptyOrUnwanted(playerObj),
        icon = "inbox-in", hint = "Take all",
        run = function(ct)
            local src, d = ct._inventory, otherInventory(ct)
            if not isFloor(src) and not luautils.walkToContainer(src, pn) then return end
            local items, heavy, n = takeAllItems(playerObj, src)
            if heavy and n == 1 then
                ISInventoryPaneContextMenu.equipHeavyItem(playerObj, heavy)
                return
            end
            CT.moveItems(playerObj, items, d)
        end }
    local keep = function(item) return not item:isFavorite() and not item:isUnwanted(playerObj) end
    local same, sameSet = sameTypeItems(inv, dest, keep)
    moves[#moves + 1] = { id = "same", label = "Same type", enabled = #same > 0, marks = sameSet,
        icon = "copy", hint = "Take the kinds you already carry",
        run = function(ct)
            local src, d = ct._inventory, otherInventory(ct)
            if not isFloor(src) and not luautils.walkToContainer(src, pn) then return end
            CT.moveItems(playerObj, (sameTypeItems(src, d, keep)), d)
        end }
    if not onFloor then
        moves[#moves + 1] = { id = "floor", label = "To floor", enabled = not inv:isEmpty(),
            icon = "fi-br-arrow-down-to-dotted-line", hint = "Everything to the floor",
            run = function(ct)
                local src = ct._inventory
                local items = {}
                local it = src:getItems()
                for i = 0, it:size() - 1 do items[#items + 1] = it:get(i) end
                if #items > 0 then
                    ISInventoryPaneContextMenu.onMoveItemsTo(items, ISInventoryPage.GetFloorContainer(pn), pn)
                end
            end }
    end
    local object = displayedObject(inv)
    local objs = objectSpecs(content, inv, object)
    -- a trash can empties for good (vanilla's Delete All; a server can turn it off)
    if isTrashCan(object) and not inv:isEmpty()
       and not (isClient() and not getServerOptions():getBoolean("TrashDeleteAll")) then
        local n = inv:getItems():size()
        objs[#objs + 1] = { id = "trash", label = "Delete all", enabled = true, danger = true,
            icon = "trash", hint = "Delete all",
            ask = string.format("Delete all %d item%s for good?", n, n == 1 and "" or "s"),
            run = function()
                local args = { x = object:getX(), y = object:getY(), z = object:getZ(), index = object:getObjectIndex() }
                sendClientCommand(playerObj, "object", "emptyTrash", args)
            end }
    end
    -- the container's own: the words first, then the icons
    local words, icons = {}, {}
    for _, o in ipairs(objs) do if o.icon then icons[#icons + 1] = o else words[#words + 1] = o end end
    for _, o in ipairs(icons) do words[#words + 1] = o end
    return moves, words
end

-- ----------------------------------------------------------------------------
-- STATE, LAYOUT, DRAWING
-- ----------------------------------------------------------------------------
local function state(content)
    if not (content and content._ccSide and content._playerObj and content._inventory) then return nil end
    content._cc = content._cc or { frame = -1000 }
    return content._cc
end

local function sizeOf(inv)
    local items = inv and inv:getItems()
    return items and items:size() or -1
end

local function refresh(content)
    local cc = content._cc
    cc.tick = (cc.tick or 0) + 1
    local other = otherInventory(content)
    local sig = tostring(content._inventory) .. "|" .. sizeOf(content._inventory) .. "|" .. tostring(other) .. "|" .. sizeOf(other)
    if cc.sig == sig and cc.tick - cc.frame < CT.REFRESH and cc.moves then return end
    if cc.sig ~= sig and cc.invSeen ~= content._inventory then cc.ask = nil; cc.sx = {} end   -- another container: no pending question, the ribbons from their start
    cc.invSeen = content._inventory
    cc.sig, cc.frame = sig, cc.tick
    local ok, moves, objs
    if content._ccSide == "char" then ok, moves, objs = pcall(buildChar, content)
    else ok, moves, objs = pcall(buildWorld, content) end
    if not ok then
        local msg = tostring(moves)
        if cc.lastErr ~= msg then print("[ZeD] ContainerControls: building the row failed: " .. msg) end
        cc.lastErr = msg
        moves, objs = {}, {}
    end
    cc.moves, cc.objs = moves or {}, objs or {}
end

local function btnW(label) return ZeD.ObjectCards.ui.buttonW(label) end

CT.ICON_W    = 24    -- design units: an icon button
CT.ICON_SZ   = 13    -- the icon inside it
CT.HINT_MS   = 450   -- the pause before an icon's hover hint shows

local ICON_TEX = {}
local function iconTex(name)
    if ICON_TEX[name] == nil then ICON_TEX[name] = getTexture("media/textures/ZeD/icons/" .. name .. ".png") or false end
    return ICON_TEX[name] or nil
end

-- a button's width: an icon button is a fixed square, a word button fits its word
local function rectW(s)
    if s.icon and iconTex(s.icon) then return ZeD.T.px(CT.ICON_W) end
    return btnW(s.label)
end

-- Lays the bottom row out between x0 and x1 (column-local): the moves, a
-- divider, the container's own buttons (words first, then icons). It fits:
-- the moves from the left, the container's own at the right. It does not:
-- one ribbon between two arrows, each rect keeping tx, its place along the
-- ribbon (draw scrolls it); divX is the divider's place the same way.
local function layRow(moves, objs, x0, x1)
    local T = ZeD.T
    local gap, bh = T.px(CT.GAP), T.px(CT.BTN_H)
    local divGap = T.px(CT.DIV_PAD) * 2 + T.px(1)
    local rects, tx = {}, 0
    local function rect(s, at)
        local r = { key = s.id, label = s.label, icon = s.icon and iconTex(s.icon) and s.icon or nil, spec = s, tx = at, w = rectW(s) }
        rects[#rects + 1] = r
        return r.w
    end
    for _, s in ipairs(moves) do tx = tx + rect(s, tx) + gap end
    local movesEnd = math.max(0, tx - gap)
    local both = #moves > 0 and #objs > 0
    local objW = 0
    for i, s in ipairs(objs) do objW = objW + rectW(s) + (i > 1 and gap or 0) end
    local total = movesEnd + (both and divGap or 0) + objW
    local row = { rects = rects, x0 = x0, x1 = x1 }
    local ox
    if total <= x1 - x0 then
        for _, r in ipairs(rects) do r.tx = x0 + r.tx end
        ox = x1 - objW
        if both then row.divX = ox - T.px(CT.DIV_PAD) - T.px(1) end
    else
        ox = movesEnd + (both and divGap or 0)
        if both then row.divX = movesEnd + T.px(CT.DIV_PAD) end
        local viewL = x0 + bh + gap
        row.scroll = { viewL = viewL, viewW = math.max(T.px(20), (x1 - bh - gap) - viewL), total = total }
    end
    for _, s in ipairs(objs) do ox = ox + rect(s, ox) + gap end
    return row
end

-- Lays the bottom row out for a list column colW wide; returns its height
-- (0 = no row). The row closes the list (the director tried the container's
-- own actions in the heading and kept them here: "bottom row works best").
function CT.layout(content, colW)
    content._ccMarks = nil
    local cc = state(content)
    if not cc then return 0 end
    refresh(content)
    cc.sx = cc.sx or {}
    cc.hits, cc.arrows, cc.hintCand, cc.strips = {}, {}, nil, {}
    local T = ZeD.T
    local padX, gap = T.px(CT.PAD_X), T.px(CT.GAP)
    local maxX = colW - padX
    if cc.ask then
        local wy, wn = btnW("Delete all"), btnW("Cancel")
        cc.bottom = { question = cc.ask.ask, x0 = padX, x1 = maxX, rects = {
            { key = "no",  label = "Cancel", tx = maxX - wy - gap - wn, w = wn, ask = "no" },
            { key = "yes", label = "Delete all", tx = maxX - wy, w = wy, ask = "yes", danger = true } } }
        return T.px(CT.ROW_H)
    end
    if #cc.moves + #cc.objs == 0 then cc.bottom = nil; return 0 end
    cc.bottom = layRow(cc.moves, cc.objs, padX, maxX)
    return T.px(CT.ROW_H)
end

local function zoneName(content) return content._ccSide == "char" and "charCtl" or "worldCtl" end

-- the row's button the controller is on, if the focus is in this row's zone
local function focusedKey(content)
    local F = ZeD.Input and ZeD.Input.Focus
    local win = content._ccWin
    if not (F and win and F.getFocusedWindow and F.getFocusedWindow() == win) then return nil end
    local z = F.getFocusedZone(win)
    if not (z and z.zone == zoneName(content)) then return nil end
    local el = F.getFocusedElement(win)
    return el and el.ccKey or nil
end

-- Draws the row's buttons in a band (top, h) of the column at xOff; name keys
-- its scroll ("bot"; its arrows are cc:-1 / cc:-2).
local function drawStrip(content, strip, name, top, h, xOff)
    local cc = content._cc
    local T = ZeD.T
    local UI = ZeD.ObjectCards.ui
    local ac = T.accent
    local bh = T.px(CT.BTN_H)
    local by = top + math.floor((h - bh) / 2)
    local mx, my = content:getMouseX(), content:getMouseY()
    local over = content:isMouseOver() and my >= top and my < top + h
    local fkey = focusedKey(content)
    local S = strip.scroll
    local clipL, clipR, shift = xOff + strip.x0, xOff + strip.x1, xOff
    local sx = cc.sx[name] or 0
    if S then
        local maxS = S.total - S.viewW
        sx = math.max(0, math.min(sx, maxS))
        -- the controller's focus walks the ribbon: keep its button in view
        if fkey then
            for _, r in ipairs(strip.rects) do
                if r.key == fkey then
                    if r.tx < sx then sx = r.tx
                    elseif r.tx + r.w > sx + S.viewW then sx = r.tx + r.w - S.viewW end
                end
            end
            sx = math.max(0, math.min(sx, maxS))
        end
        clipL, clipR = xOff + S.viewL, xOff + S.viewL + S.viewW
        shift = xOff + S.viewL - sx
        content:setStencilRect(clipL, top, S.viewW, h)
    end
    cc.sx[name] = sx
    cc.strips[name] = strip
    if strip.divX then
        local bs = T.borderS
        content:drawRect(shift + strip.divX, top + T.px(5), T.px(1), h - T.px(10), bs.a, bs.r, bs.g, bs.b)
    end
    local isz = T.px(CT.ICON_SZ)
    for _, r in ipairs(strip.rects) do
        local s = r.spec
        local enabled = (s == nil) or s.enabled
        local danger = r.danger or (s and s.danger)
        local x, y = shift + r.tx, by
        local focused = (fkey == r.key)
        local vx0, vx1 = math.max(x, clipL), math.min(x + r.w, clipR)
        if vx1 > vx0 then
            UI.button(content, x, y, r.icon and "" or r.label, { h = bh, w = r.w, disabled = not enabled, danger = danger, focused = focused })
            if r.icon then
                -- the icon: the text colour; the accent while its thing runs; the warning colour for Delete all
                local c = (danger and T.danger) or ((s and s.lit) and ac) or T.text
                ZeD.Atoms.drawIcon(content, iconTex(r.icon), x + math.floor((r.w - isz) / 2), y + math.floor((bh - isz) / 2), isz,
                    enabled and 1 or 0.35, c)
            end
        end
        local hover = over and vx1 > vx0 and mx >= vx0 and mx < vx1 and my >= y and my < y + bh
        if hover and enabled and not focused then content:drawRect(x, y, r.w, bh, 0.22, ac.r, ac.g, ac.b) end
        if (hover or focused) and s and s.enabled and s.marks then content._ccMarks = s.marks end
        -- an icon names itself in a hover hint, after a pause (CT.drawHint)
        if hover and r.icon and s then cc.hintCand = { key = r.key, text = s.hint or s.label, x = x, y = y, w = r.w, h = bh } end
        cc.hits[#cc.hits + 1] = { key = r.key, label = (s and s.hint) or r.label, spec = s, ask = r.ask, x = x, y = y, w = r.w, h = bh,
            enabled = enabled, vx = vx0, vw = math.max(0, vx1 - vx0) }
    end
    if S then
        content:clearStencilRect()
        -- the arrows: a scrollbar's own, live while there is more that way
        local canL, canR = sx > 0, sx < S.total - S.viewW
        local ax = { xOff + strip.x0, xOff + strip.x1 - bh }
        local s2 = T.surf2
        for k, dir in ipairs({ "left", "right" }) do
            local can = (k == 1 and canL) or (k == 2 and canR)
            local x = ax[k]
            local hov = can and over and mx >= x and mx < x + bh and my >= by and my < by + bh
            ZeD.Atoms.drawScrollArrow(content, x, by, bh, dir, hov and "hover" or "default")
            if not can then content:drawRect(x, by, bh, bh, 0.6, s2.r, s2.g, s2.b) end
            if can then cc.arrows[#cc.arrows + 1] = { idx = -k, x = x, y = by, w = bh, h = bh } end
        end
    end
end

-- Draws the bottom row at top (content-local; xOff = the list column's x);
-- atBottom: the row closes the list (its rule on top).
function CT.draw(content, top, colW, xOff, atBottom)
    local cc = content._cc
    local B = cc and cc.bottom
    if not B then return end
    local T = ZeD.T
    local rowH = T.px(CT.ROW_H)
    local s2 = T.surf2
    content:drawRect(xOff, top, colW, rowH, s2.a, s2.r, s2.g, s2.b)
    ZeD.Atoms.drawDividerH(content, xOff, atBottom and top or (top + rowH - T.px(1)), colW, true)
    cc.row = { x = xOff, y = top, w = colW, h = rowH }
    if B.question then
        local f2 = T.fontF2
        local fh = ZeD.TM:getFontHeight(f2)
        local dc, tc = T.danger, T.text
        local qx = xOff + B.x0
        local dot = T.px(6)
        content:drawRect(qx, top + math.floor((rowH - dot) / 2), dot, dot, 1, dc.r, dc.g, dc.b)
        local room = (xOff + B.rects[1].tx) - (qx + dot + T.px(6)) - T.px(6)
        content:drawText(ZeD.Atoms.truncateText(B.question, f2, room), qx + dot + T.px(6), top + math.floor((rowH - fh) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    drawStrip(content, B, "bot", top, rowH, xOff)
end

-- The hover hint: an icon names what it does in ZeD's hint box (ZeD_Tooltip's
-- look: surf2, the strong border, F2) once the pointer has rested on it for
-- CT.HINT_MS, above the icon, kept inside the column. Drawn last, after the
-- list's rows.
function CT.drawHint(content)
    local cc = content._cc
    local c = cc and cc.hintCand
    if not c then
        if cc then cc.hintKey = nil end
        return
    end
    local now = getTimestampMs()
    if cc.hintKey ~= c.key then cc.hintKey, cc.hintSince = c.key, now; return end
    if now - (cc.hintSince or now) < CT.HINT_MS then return end
    local T = ZeD.T
    local f2 = T.fontF2
    local padX, padY = T.px(10), T.px(4)
    local tw = ZeD.TM:MeasureStringX(f2, c.text)
    local w, h = tw + padX * 2, ZeD.TM:getFontHeight(f2) + padY * 2
    local R = cc.row
    local colL = R and R.x or 0
    local colR = R and (R.x + R.w) or content:getWidth()
    local x = math.max(colL + T.px(2), math.min(c.x, colR - w - T.px(2)))
    local y = c.y - h - T.px(4)
    local s2, bs, tc = T.surf2, T.borderS, T.text
    content:drawRect(x + T.px(2), y + T.px(2), w, h, 0.5, 0, 0, 0)
    content:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
    content:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    content:drawText(c.text, x + padX, y + padY, tc.r, tc.g, tc.b, tc.a or 1, f2)
end

-- Hit zones go in after the renderer clears its zones for the frame: each
-- button's showing part, and the arrows.
function CT.addZones(content)
    local cc = content._cc
    if not (cc and cc.hits) then return end
    for i, h in ipairs(cc.hits) do
        if h.vw > 0 then content:addHitZone("cc:" .. i, h.vx, h.y, h.vw, h.h) end
    end
    for _, a in ipairs(cc.arrows or {}) do content:addHitZone("cc:" .. a.idx, a.x, a.y, a.w, a.h) end
end

-- Moves a ribbon one button left (-1) or right (+1).
local function stepRibbon(cc, name, dir)
    local strip = cc.strips and cc.strips[name]
    local S = strip and strip.scroll
    if not S then return end
    local sx = cc.sx[name] or 0
    if dir < 0 then
        local to = 0
        for _, r in ipairs(strip.rects) do if r.tx < sx then to = r.tx end end
        sx = to
    else
        for _, r in ipairs(strip.rects) do
            if r.tx + r.w > sx + S.viewW + 1 then sx = r.tx + r.w - S.viewW; break end
        end
    end
    cc.sx[name] = math.max(0, math.min(sx, S.total - S.viewW))
end

-- The mouse wheel over a ribbon scrolls it sideways; true when it took the wheel.
function CT.wheel(content, del)
    local cc = content and content._cc
    if not (cc and cc.strips) then return false end
    local mx, my = content:getMouseX(), content:getMouseY()
    local function inside(R) return R and mx >= R.x and mx < R.x + R.w and my >= R.y and my < R.y + R.h end
    local strip = inside(cc.row) and cc.strips.bot
    if not (strip and strip.scroll) then return false end
    stepRibbon(cc, "bot", del > 0 and 1 or -1)
    return true
end

-- ----------------------------------------------------------------------------
-- PRESSING (mouse: content.onMouseDown with a "cc:<i>" zone; controller: A)
-- ----------------------------------------------------------------------------
function CT.press(content, idx)
    local cc = content._cc
    if not (cc and idx) then return end
    if idx < 0 then stepRibbon(cc, "bot", idx == -1 and -1 or 1); return end
    local h = cc.hits and cc.hits[idx]
    if not h then return end
    if isGamePaused() then return end
    if h.ask == "no" then cc.ask = nil; return end
    if h.ask == "yes" then
        local s = cc.ask
        cc.ask = nil
        if s then pcall(s.run, content, h) end
        cc.frame = -1000
        return
    end
    local s = h.spec
    if not (s and s.enabled) then return end
    if s.ask then cc.ask = s; return end
    local ok, err = pcall(s.run, content, h)
    if not ok then print("[ZeD] ContainerControls: " .. tostring(s.id) .. " failed: " .. tostring(err)) end
    cc.frame = -1000   -- rebuild next frame
end

-- B backs out of a question in the row
function CT.cancelAsk(content)
    local cc = content and content._cc
    if cc and cc.ask then cc.ask = nil; return true end
    return false
end

-- ----------------------------------------------------------------------------
-- CONTROLLER: the bottom row's buttons as one ring zone,
-- appended to the window's ring (appending keeps every other zone's index,
-- so focus never jumps). Every button is a stop, the ones scrolled out of
-- view too (at their place along the ribbon), so the D-pad walks on past an
-- arrow and the ribbon follows; the footer's prompt names an icon.
-- Called by the window after the list renders.
-- ----------------------------------------------------------------------------
function CT.syncFocus(win, content)
    local F = ZeD.Input and ZeD.Input.Focus
    if not (F and win and win._focusRing and content) then return end
    local zn = zoneName(content)
    local zone
    for _, z in ipairs(win._focusRing) do if z.zone == zn then zone = z; break end end
    if not zone then
        zone = { zone = zn, focusable = false, elements = {}, focusedElementIdx = 1,
                 uiRange = function(w) return content:getX(), content:getWidth() end }
        win._focusRing[#win._focusRing + 1] = zone
    end
    local cc = content._cc
    local hits = (cc and cc.bottom and cc.hits) or {}
    local parts = {}
    for _, h in ipairs(hits) do parts[#parts + 1] = h.key .. "@" .. h.x .. "," .. h.y .. "," .. h.w end
    local sig = table.concat(parts, ";")
    if cc then
        if cc.focusSig == sig then return end
        cc.focusSig = sig
    elseif #zone.elements == 0 then
        return
    end
    local els = {}
    for i, h in ipairs(hits) do
        els[i] = {
            x = h.x, y = h.y, w = h.w, h = h.h,
            id = zn .. ":" .. h.key, ccKey = h.key, ccIdx = i,
            promptA = h.label,
            onActivate = function(w, el) CT.press(content, el.ccIdx) end,
            onCancel = (cc and cc.ask) and function() CT.cancelAsk(content) end or nil,
        }
    end
    F.setRingZoneElements(win, zn, els)
    F.setZoneFocusable(win, zn, #els > 0)
end
