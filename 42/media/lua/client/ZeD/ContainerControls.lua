-- ZeD-UI/42/media/lua/client/ZeD/ContainerControls.lua
-- ============================================================================
-- CONTAINER BUTTONS (client) — vanilla B42's row of container controls in
-- the ZeD windows. One row at the bottom of each window's list: the
-- container's own actions were tried in the window's heading and kept down
-- here, where they make less noise. Common actions are icons that name
-- themselves in a hover hint, the unique ones are words. For the container
-- on show:
--   Character window (your side), bottom row: Transfer all | Same type |
--     Same type, all nearby (icons), then after a divider any buttons mods add
--   World window (the other side), bottom row: Take all | Same type |
--     To floor (not on the floor) (icons), then after a divider the
--     container's own buttons, vanilla's object controls, words first then
--     icons (a stove's power and settings, a washer's switch, a mannequin's
--     Wear all / Switch outfits, a car trunk's Close trunk / lock, a
--     campfire's Take apart / light / add fuel / put out, a propane
--     barbecue's tank and switch, buttons other mods register) and a trash
--     can's Delete all (the bin), whose question takes over the bottom row.
-- The moves keep vanilla's rules (ISInventoryPane:lootAll / transferAll and
-- the same-type handlers' item tables) but aim at the containers the ZeD
-- windows show, never at vanilla's own pages hidden behind them. Items go
-- through vanilla's transfer action, or ZeD's floor path
-- (InventoryRenderer.handleDrop's rules).
-- The container's own buttons are vanilla's handler classes
-- (ISLootWindowContainerControls_HandlerList) run with a small stand-in for
-- vanilla's loot window, so their visibility rules stay vanilla's. Light and
-- Add fuel open the fire card on its own lists instead of a context menu.
-- A washer, a dryer or a washer-dryer gets one button, the gears, that opens
-- its face card (ObjectCardLaundry) in place of vanilla's laundry buttons;
-- ZeD.ObjectCardLaundry.useFace is the one switch back to the plain ones.
-- A mod that puts buttons straight onto the game's inventory page (not in the
-- handler lists) gets them here through CT.addProvider, called from its
-- ModSupport file (Easy Drop'n'Loot: ModSupport/KADropnLoot.lua).
-- A mod's gate on the container on show (ContainerGates.lua: Immersive
-- Searching's unsearched container) can leave the moves out, add its own
-- buttons (Search, Search all) and put a status line and a moving bar at the
-- band's left ("Searching..."); a gate that refuses things on the other side
-- turns the moves into it off. Moves into a refusing container are dropped.
-- The row is one line, a ribbon that scrolls sideways when its buttons are
-- wider than the list (the wheel, its arrows, the controller's focus).
-- Pointing at (or focusing) a Same type button marks the rows it would move.
-- On a controller the buttons are stops in their own ring zone (charCtl /
-- worldCtl, appended to the window's ring), reached by the D-pad.
-- The row is drawn by InventoryRenderer.renderItemList (single-container view
-- only) for a content panel that carries _ccSide ("char" / "world") and
-- _ccWin; the windows set _ccEntry to the container entry on show.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/ObjectCards"
require "ZeD/ObjectCardLaundry"
require "ZeD/ContainerGates"
require "ZeD/ItemRules"        -- (Nov 15 2026, add-on hooks: an add-on's rule about what may go where)

ZeD = ZeD or {}
ZeD.ContainerControls = ZeD.ContainerControls or {}
local CT = ZeD.ContainerControls

-- (the band is the library's: ZeD.Molecules.bandH() tall, T.buttonH buttons)
CT.PAD_X   = 8     -- design units: the band's edges
CT.GAP     = 8     -- between buttons (4 between two icons)
CT.DIV_PAD = 5     -- each side of the divider before the container's own buttons
CT.REFRESH_MS = 1000   -- ms: the safety beat for rebuilding the button set when nothing it watches moved
CT.EVENT_MS   = 250    -- ms: a container event rebuilds it at most this often (a transfer fires many)
-- (These were 15 frames, a rebuild 4 times a second at 60 Hz and 10 at 144, whether
-- or not anything changed: a 300-item crate cost thousands of game calls each time.
-- Now the row is rebuilt when its signature changes (containers, counts, gates,
-- marks), soon after a container event, and once a second anyway for what none of
-- those catch, a favorite or an item equipped, say. QA's speed audit, Nov 20 2026.)

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
    ISLootWindowObjectControlHandler_PropaneBarbecueRemoveTank     = "UI_ZeD_Controls_RemoveTank",
    ISLootWindowObjectControlHandler_PropaneBarbecueAddTank        = "UI_ZeD_Controls_InsertTank",
    ISLootWindowObjectControlHandler_PropaneBarbecueToggle         = true,
    ISLootWindowObjectControlHandler_ClothingWasherToggle          = true,
    ISLootWindowObjectControlHandler_ClothingDryerToggle           = true,
    ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode = true,
    ISLootWindowObjectControlHandler_CombinationWasherDryerToggle  = true,
    ISLootWindowObjectControlHandler_StoveSettings                 = true,
    ISLootWindowObjectControlHandler_StoveToggle                   = true,
    ISLootWindowObjectControlHandler_VehicleLockTrunk              = true,
    ISLootWindowObjectControlHandler_VehicleCloseTrunk             = true,
    ISLootWindowObjectControlHandler_PutOut                        = "UI_ZeD_Controls_PutOut",
    ISLootWindowObjectControlHandler_LightFireOption               = "ContextMenu_Light",
    ISLootWindowObjectControlHandler_AddFuelOption                 = "ContextMenu_GeneratorAddFuel",
    ISLootWindowObjectControlHandler_RemoveCampfire                = "UI_ZeD_Controls_TakeApart",
    ISLootWindowObjectControlHandler_AddCorpseToCampfire           = "ContextMenu_AddCorpse",
}
-- vanilla's object controls many objects share draw as icons (ZeD's pixel
-- icons, ZeD.PxIcon, the wheels' style); the rest stay words. The rule: a
-- common action is an icon that names itself in a hover hint, a unique
-- action is text.
local VANILLA_ICON = {
    ISLootWindowObjectControlHandler_StoveToggle                  = "power",
    ISLootWindowObjectControlHandler_ClothingWasherToggle         = "power",
    ISLootWindowObjectControlHandler_ClothingDryerToggle          = "power",
    ISLootWindowObjectControlHandler_CombinationWasherDryerToggle = "power",
    ISLootWindowObjectControlHandler_PropaneBarbecueToggle        = "power",
    ISLootWindowObjectControlHandler_StoveSettings                = "gears",
    ISLootWindowObjectControlHandler_LightFireOption              = "match",
    ISLootWindowObjectControlHandler_AddFuelOption                = "campfire",
    ISLootWindowObjectControlHandler_PutOut                       = "extinguisher",
    ISLootWindowObjectControlHandler_VehicleLockTrunk             = "padlock",
}
-- these open the fire card on one of its lists (its own Light / Add fuel)
local FIRE_JUMP = {
    ISLootWindowObjectControlHandler_LightFireOption = "fire:light:1",
    ISLootWindowObjectControlHandler_AddFuelOption   = "fire:fuel:1",
}
-- the laundry machines' buttons: the face card's one button takes their place while it shows
local LAUNDRY = {
    ISLootWindowObjectControlHandler_ClothingWasherToggle          = true,
    ISLootWindowObjectControlHandler_ClothingDryerToggle           = true,
    ISLootWindowObjectControlHandler_CombinationWasherDryerSetMode = true,
    ISLootWindowObjectControlHandler_CombinationWasherDryerToggle  = true,
}

local function isFloor(inv) return inv ~= nil and inv:getType() == "floor" end

-- any key in a set (Kahlua has no next())
local function hasAny(t) for _ in pairs(t) do return true end return false end

-- pn: whose floor (each local player's World window has its own)
local function zedFloor(pn)
    return ZeD_WorldWindow and ZeD_WorldWindow.getFloorContainer and ZeD_WorldWindow.getFloorContainer(pn) or nil
end

-- A vanilla Title Case label as a button word ("Set Mode: Dryer" -> "Set mode: dryer").
-- Only English is re-cased: other languages capitalise by their own rules (German nouns),
-- so their vanilla wording is left exactly as the translators wrote it.
local function sentence(s)
    s = tostring(s or "")
    if CT._english == nil then
        local ok, name = pcall(function() return Translator.getLanguage():name() end)
        CT._english = (not ok) or tostring(name) == "EN"
    end
    if not CT._english then return s end
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
--- Moves items into dest, each by vanilla's transfer action; dest = the floor
--- drops them instead (favourites stay put). A container whose gate refuses
--- things takes nothing. unequip = true (Move To on a held item): a held or worn item is taken off just before its own
--- transfer, so a refused move leaves it in the hand (L1-1).
function CT.moveItems(playerObj, items, dest, unequip)
    if not (playerObj and dest and items and #items > 0) then return end
    -- a mod's gate refuses things into this container (ContainerGates.lua: never searched)
    if not isFloor(dest) and ZeD.ContainerGates.refuses(dest, playerObj) then return end
    local pn = playerObj:getPlayerNum()
    local floor = zedFloor(pn)
    -- (Nov 15 2026, add-on hooks: things an add-on's rule refuses stay where they are, the first reason once over the
    -- head, ItemRules.lua; every move below comes through here: Take all, Transfer all, Same type, the pad's X grab.
    -- Without a rule the same list comes back.)
    items = ZeD.ItemRules.filter(items, dest, playerObj, nil)
    if #items == 0 then return end
    sortForTransfer(items)
    if isFloor(dest) then
        -- seated with the window shut, nothing goes out to the ground (QA B6-9)
        if ZeD.InventoryRenderer.carWindowShut(playerObj) then return end
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
            -- take it off first, only now the move is sure to be queued (L1-1)
            if unequip and playerObj:isEquipped(item) then
                local off = ISUnequipAction:new(playerObj, item, 50)
                off._zedApart = true   -- (a move the player asked for, never part of an action's run: ZeD_PutBack.lua) (L1-3)
                ISTimedActionQueue.add(off)
            end
            local move = ISInventoryTransferUtil.newInventoryTransferAction(playerObj, item, src, dest)
            move._zedApart = true   -- (the player's own move: Put things back never counts it as an action's) (L1-3)
            ISTimedActionQueue.add(move)
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

--- The same two moves from outside the windows (a container's world menu, an
--- item's menu with a controller). Walks to a container first, as vanilla does.
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

--- Transfer all from src into dest (walks to dest first unless it is the floor).
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
-- pn: whose windows (the content's own player; split view gives each player a pair)
local function charContent(pn)
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.isOpen and ZeD_CharacterWindow.isOpen(pn) and ZeD_CharacterWindow.getWindow(pn)
    return cw and cw._mainContent or nil
end
local function worldWindow(pn)
    return ZeD_WorldWindow and ZeD_WorldWindow.isOpen and ZeD_WorldWindow.isOpen(pn) and ZeD_WorldWindow.getWindow(pn) or nil
end

-- The other side's container: what the other ZeD window shows. Your side's
-- moves need the World window open on one container; the World window's
-- moves go into the Character window's container, else your inventory.
local function otherInventory(content)
    if content._ccSide == "char" then
        local ww = worldWindow(ZeD.playerNumOf(content))
        local wc = ww and ww._mainContent
        return (wc and wc._ccEntry and wc._inventory) or nil
    end
    local cc = charContent(ZeD.playerNumOf(content))
    return (cc and cc._ccEntry and cc._inventory) or (content._playerObj and content._playerObj:getInventory())
end
CT.otherInventory = otherInventory

--- Where a take lands: the bag on show in the Character window, else his main inventory. The game's own takes fill its
--- inventory page's selected bag (ISInventoryPane's double-click: getPlayerInventory(pn).inventory), and ZeD's Loot all
--- and pad X on a row already went to the bag on show (the director, Nov 24 2026); the double-click, the card's Grab,
--- pad X on a container's button and the item menu's Loot all now land there too. (QA's loot KISS test, Nov 24 2026)
function CT.takeDest(playerObj)
    if not playerObj then return nil end
    local cc = charContent(playerObj:getPlayerNum())
    return (cc and cc._ccEntry and cc._inventory) or playerObj:getInventory()
end

-- Transfer all's destination: the other window's container, or, from your side with the World window shut (or with
-- no container across), the floor at your feet, as the game's own Transfer all does: its hidden loot pane is the floor
-- then (ISInventoryPane:transferAll, toFloor). Only Transfer all falls back; a single row's move (the controller's X,
-- a drag) keeps "nowhere to go" so nothing drops by accident. (The director, Nov 24 2026: "transfer all would
-- transfer to the floor, wouldn't it?")
local function transferDest(content)
    local d = otherInventory(content)
    if d or content._ccSide ~= "char" then return d end
    local pn = ZeD.playerNumOf(content)
    if ISInventoryPage and ISInventoryPage.GetFloorContainer then return ISInventoryPage.GetFloorContainer(pn) end
    return zedFloor(pn)
end
CT.transferDest = transferDest

--- True when dest can't take these things: it refuses one of them, or their weight (the ones not in it already) does
--- not fit. The drag chip's own test (InventoryRenderer.dragNoRoom); the floor has no limit here.
--- (loot KISS call 6, the director, Nov 24 2026)
function CT.noRoom(playerObj, items, dest)
    if not (playerObj and dest and items) or isFloor(dest) then return false end
    local total = 0
    for _, item in ipairs(items) do
        if item:getContainer() ~= dest then
            if not dest:isItemAllowed(item) then return true end
            total = total + (item:getUnequippedWeight() or 0)
        end
    end
    return total > 0 and not dest:hasRoomFor(playerObj, total)
end

--- (Nov 14 2026, punch list 223: the controller's X on a row is the game's grab, ISInventoryPane:doGrabOnJoypadSelected)
--- The items go to the other window's container by the band's own move (CT.moveItems: the game's transfer actions,
--- the floor's rules, a gate's refusal). From the World window: walk to the container first, as Take does, and a
--- heavy thing alone is picked up in the hands (the game's grab). False when there is nowhere to put them.
function CT.moveToOther(content, items)
    local playerObj = content and content._playerObj
    local dest = content and otherInventory(content)
    if not (playerObj and dest and items and #items > 0) then return false end
    if playerObj.isAsleep and playerObj:isAsleep() then return false end   -- (both moves below refuse asleep too)
    -- (loot KISS call 6, the director, Nov 24 2026) a bag that can't take them: "No room" over his head, nothing moves.
    -- A heavy thing alone out of the world goes into the hands, not the bag, so it is not asked.
    local heavyGrab = content._ccSide ~= "char" and #items == 1 and isForceDropHeavyItem and isForceDropHeavyItem(items[1])
    if not heavyGrab and CT.noRoom(playerObj, items, dest) then
        if ZeD.Bubbles and ZeD.Bubbles.note then
            pcall(ZeD.Bubbles.note, playerObj:getPlayerNum(), ZeD.tr("UI_ZeD_Drag_NoRoom"), "bad")
        end
        CT.lastNoRoom = getTimestampMs and getTimestampMs() or 0   -- (QA reads it: when pad X last said No room)
        return false
    end
    if content._ccSide ~= "char" then return CT.grabItems(playerObj, items, dest) end
    if playerObj.isAsleep and playerObj:isAsleep() then return false end
    CT.moveItems(playerObj, items, dest)
    return true
end

--- The game's grab out of the world (X on a World window row; the card's Grab, punch list 227): walk to the
--- container first (not the floor), a heavy thing alone into the hands, else the band's move into dest (nil: your
--- inventory). False when nothing could be done.
function CT.grabItems(playerObj, items, dest)
    if not (playerObj and items and #items > 0) then return false end
    if playerObj.isAsleep and playerObj:isAsleep() then return false end
    dest = dest or playerObj:getInventory()
    local src = items[1]:getContainer()
    if src and src ~= dest and not isFloor(src) and not luautils.walkToContainer(src, playerObj:getPlayerNum()) then return false end
    if #items == 1 and isForceDropHeavyItem and isForceDropHeavyItem(items[1]) then
        ISInventoryPaneContextMenu.equipHeavyItem(playerObj, items[1])
        return true
    end
    CT.moveItems(playerObj, items, dest)
    return true
end

local function nearbyContainers(pn)
    local ww = worldWindow(pn)
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
    -- a laundry machine: its face card (one button, below), else vanilla's plain buttons as they always were
    local LD = ZeD.ObjectCardLaundry
    local face = LD ~= nil and LD.useFace(object)
    for _, cls in ipairs(list) do
        local typ = cls.Type
        if not OURS[typ] and not (face and LAUNDRY[typ]) then
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
                        -- a ZeD phrase reads as its translator wrote it; vanilla's key gets the button case
                        if fixed:sub(1, 7) == "UI_ZeD_" then title = ZeD.tr(fixed) else title = sentence(getText(fixed)) end
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
                                local ww = ZeD_WorldWindow.getWindow(ZeD.playerNumOf(content))
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
    if face then specs[#specs + 1] = LD.rowSpec(playerObj, object) end
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

-- ----------------------------------------------------------------------------
-- BUTTONS A MOD'S SUPPORT FILE ADDS (ZeD/ModSupport/<mod id>.lua)
-- A mod that puts ISButtons on the game's inventory page itself (not in the
-- handler lists above) cannot be collected from here, so its support file
-- registers a provider: CT.addProvider("<mod id>", function(side, content, inv, other) ... end).
--   side    "char" (your side's row) or "world" (the World window's row)
--   inv     the container this row is for, other the container on the other
--           side (nil when that window shows none)
--   returns a list of specs, or nil: { id, label, enabled, help, run(content, hit), primary }
--           (help is the footer's line while the pointer rests on the button;
--           primary = true draws it as the main button).
-- Specs become words after the divider, with the container's own buttons.
-- Called when the row is rebuilt (once a second, sooner when items change),
-- inside pcall, so a provider that fails costs its buttons, never the row.
-- ----------------------------------------------------------------------------
CT.providers = CT.providers or {}

--- Registers a mod's button provider (the banner above has the contract).
function CT.addProvider(id, fn)
    for _, p in ipairs(CT.providers) do
        if p.id == id then p.fn = fn; return end   -- registered again (a reload): replace
    end
    CT.providers[#CT.providers + 1] = { id = id, fn = fn }
end

-- adds every provider's specs for this row onto the end of list
local function addProviderSpecs(list, side, content, inv, other)
    for _, p in ipairs(CT.providers) do
        local ok, got = pcall(p.fn, side, content, inv, other)
        if ok and type(got) == "table" then
            for _, spec in ipairs(got) do list[#list + 1] = spec end
        elseif not ok then
            print("[ZeD] ContainerControls: provider " .. tostring(p.id) .. " failed: " .. tostring(got))
        end
    end
    return list
end

-- the controller's marked rows of a list, nil without any, and the set the band washes
local function markedOf(content)
    local R = ZeD.InventoryRenderer
    return R and R.padMarkedAll and R.padMarkedAll(content) or nil
end
local function markedSet(items)
    local set = {}
    for _, it in ipairs(items) do set[it] = true end
    return set
end

-- (beta 21, Lite: "If vanilla does it, so does Lite". The game has Same type and Same type nearby too, in its
-- inventory page and loot page handlers (TransferSameType, TakeSameType), so Lite keeps them (QA's loot KISS test,
-- Nov 24 2026); the trim stays for a move the game lacks)
local LITE_DROP = {}
local function liteTrim(moves)
    if not (ZeD.Settings and ZeD.Settings.lite and ZeD.Settings.lite()) then return moves end
    for i = #moves, 1, -1 do
        if moves[i] and LITE_DROP[moves[i].id] then table.remove(moves, i) end
    end
    return moves
end
CT._liteTrim = liteTrim   -- (the test sim's way in)

local function buildChar(content)
    local playerObj = content._playerObj
    local inv = content._inventory
    local dest = otherInventory(content)
    local moves = {}
    local marked = markedOf(content)
    if marked then
        -- the controller's marks: with rows marked, the move is of the marked rows only
        local xdest = transferDest(content)
        local toFloor = xdest ~= nil and isFloor(xdest)
        moves[#moves + 1] = { id = "xfer", label = ZeD.tr(toFloor and "UI_ZeD_Controls_DropMarked" or "UI_ZeD_Controls_MoveMarked"),
            enabled = xdest ~= nil, marks = markedSet(marked),
            icon = "tray_out", hint = ZeD.tr(toFloor and "UI_ZeD_Controls_HintDropMarked" or "UI_ZeD_Controls_HintMoveMarked", #marked),
            run = function(ct)
                local d = transferDest(ct)
                local items = markedOf(ct)
                if not (items and d) then return end
                ZeD.InventoryRenderer.padClearMarksOf(ct)
                CT.moveItems(playerObj, items, d)
            end }
    else
        local xdest = transferDest(content)
        local xfer = transferAllItems(playerObj, inv, xdest)
        moves[#moves + 1] = { id = "xfer", label = sentence(getText("IGUI_invpage_Transfer_all")), enabled = xdest ~= nil and #xfer > 0,
            -- (no icon: Transfer all is a word button, a wrong guess dropped loose things on the floor; KISS #7)
            hint = sentence(getText("IGUI_invpage_Transfer_all")),
            run = function(ct)
                local d = transferDest(ct)
                CT.moveItems(playerObj, transferAllItems(playerObj, ct._inventory, d), d)
            end }
    end
    local keep = function(item) return not item:isFavorite() and not item:isEquipped() end
    local same, sameSet = sameTypeItems(inv, dest, keep)
    moves[#moves + 1] = { id = "same", label = ZeD.tr("UI_ZeD_Controls_SameType"), enabled = #same > 0, marks = sameSet,
        icon = "same_type", hint = ZeD.tr("UI_ZeD_Controls_HintPutInKinds"),
        mark = "red",   -- (Put in: the menu's red; the World window's Same type takes, blue. Icon color, Nov 22 2026)
        run = function(ct)
            local d = otherInventory(ct)
            CT.moveItems(playerObj, (sameTypeItems(ct._inventory, d, keep)), d)
        end }
    local _, nearSet = nearbyPlan(playerObj, inv, nearbyContainers(ZeD.playerNumOf(content)))
    moves[#moves + 1] = { id = "near", label = ZeD.tr("UI_ZeD_Controls_SameTypeNearby"), enabled = hasAny(nearSet), marks = nearSet,
        icon = "same_nearby", hint = ZeD.tr("UI_ZeD_Controls_HintNearby"),
        run = function(ct)
            for _, step in ipairs((nearbyPlan(playerObj, ct._inventory, nearbyContainers(ZeD.playerNumOf(ct))))) do
                CT.moveItems(playerObj, step.items, step.dest)
            end
        end }
    return liteTrim(moves), addProviderSpecs(inventorySpecs(content, inv), "char", content, inv, dest)
end

--- Loot all: everything wanted in src comes over to d, as the band's Loot all does (walks there first unless src is
--- the floor; a lone heavy thing is equipped the game's way). The one place the band's button, the list heading's
--- and the controller's X on a container's button take from. (KISS #18)
function CT.lootAll(playerObj, src, d)
    if not (playerObj and src and d) then return end
    local pn = playerObj:getPlayerNum()
    if not isFloor(src) and not luautils.walkToContainer(src, pn) then return end
    local items, heavy, n = takeAllItems(playerObj, src)
    if heavy and n == 1 then
        ISInventoryPaneContextMenu.equipHeavyItem(playerObj, heavy)
        return
    end
    CT.moveItems(playerObj, items, d)
end

--- The words of the Loot all buttons (the game's, sentence case): the band's and the list heading's. (KISS #18)
function CT.lootAllLabel() return sentence(getText("IGUI_invpage_Loot_all")) end

--- True when a World window Loot column (a column among several, _compactMode) shows its own foot with Take all
--- (InventoryRenderer.drawColumnFoot). The window's single list has the band's Take all instead. (KISS #18;
--- Transfer in the footer, the director, Nov 22 2026: no Take all in any heading.)
function CT.headLootOn(content)
    return content ~= nil and content._ccSide == "world" and content._compactMode == true
        and content._playerObj ~= nil and content._inventory ~= nil
end

-- A Loot column's "anything to take", per container: asked every frame by each column's heading, so the answer is
-- kept a moment (the band's row keeps its own the same way). (Header order, the director, Nov 22 2026)
CT._colLoot, CT._colLootN = CT._colLoot or {}, CT._colLootN or 0
CT.COL_LOOT_MS = 500

--- True when the heading's Loot all has something to take (as the band's row last built it said). (KISS #18;
--- Nov 22 2026: read from cc.lootEnabled, the band no longer has a Loot all of its own)
function CT.headLootEnabled(content)
    if content and content._compactMode then
        -- a column among several: its own container, not the window's (Header order, the director, Nov 22 2026)
        local inv, po = content._inventory, content._playerObj
        if not (inv and po) then return false end
        local now = getTimestampMs()
        local c = CT._colLoot[inv]
        if not c or now - c.at > CT.COL_LOOT_MS or now < c.at then
            if not c then
                -- (a new container: past 64 kept, start over, so the containers walked away from are let go)
                if CT._colLootN >= 64 then CT._colLoot, CT._colLootN = {}, 0 end
                CT._colLootN = CT._colLootN + 1
                c = {}
            end
            c.at, c.on = now, not inv:isEmptyOrUnwanted(po)
            CT._colLoot[inv] = c
        end
        return c.on
    end
    local cc = content and content._cc
    return (cc and cc.lootEnabled) and true or false
end

--- Loot all from src into the player's own inventory: what the World window's X on a container's button runs
--- (KISS #18). False when there is nothing wanted to take.
-- dest: where the things go; nil is his main inventory. (Nov 22 2026, "Number 1": the heading's Loot all, now the
-- only one, passes the band's own destination, the bag on show in the Character window, as the band's did.)
function CT.lootAllFrom(playerObj, src, dest)
    if not (playerObj and src) then return false end
    if src:isEmptyOrUnwanted(playerObj) then return false end
    CT.lootAll(playerObj, src, dest or playerObj:getInventory())
    return true
end

local function buildWorld(content)
    local playerObj = content._playerObj
    local pn = playerObj:getPlayerNum()
    local inv = content._inventory
    local dest = otherInventory(content)
    local onFloor = isFloor(inv)
    local moves = {}
    local marked = markedOf(content)
    if marked then
        -- the controller's marks: with rows marked, Take takes the marked rows only
        moves[#moves + 1] = { id = "take", label = ZeD.tr("UI_ZeD_Controls_TakeMarked"), enabled = true, marks = markedSet(marked),
            icon = "tray_in", hint = ZeD.tr("UI_ZeD_Controls_HintTakeMarked", #marked),
            run = function(ct)
                local src, d = ct._inventory, otherInventory(ct)
                if not isFloor(src) and not luautils.walkToContainer(src, pn) then return end
                local items = markedOf(ct)
                if not items then return end
                ZeD.InventoryRenderer.padClearMarksOf(ct)
                CT.moveItems(playerObj, items, d)
            end }
    else
        -- (Transfer in the footer, the director, Nov 22 2026: "Transfer buttons, always in the footer. Selection
        -- buttons, always in the header." Take all is back in the band, first, after the same day's "Number 1" had
        -- moved it to the heading)
        moves[#moves + 1] = { id = "take", label = CT.lootAllLabel(), enabled = not inv:isEmptyOrUnwanted(playerObj),
            -- (no icon: Loot all is a word button; KISS #7)
            hint = CT.lootAllLabel(),
            run = function(ct) CT.lootAll(playerObj, ct._inventory, otherInventory(ct)) end }   -- (KISS #18: one place)
    end
    local cc = content._cc
    if cc then cc.lootEnabled = not inv:isEmptyOrUnwanted(playerObj) end
    local keep = function(item) return not item:isFavorite() and not item:isUnwanted(playerObj) end
    local same, sameSet = sameTypeItems(inv, dest, keep)
    moves[#moves + 1] = { id = "same", label = ZeD.tr("UI_ZeD_Controls_SameType"), enabled = #same > 0, marks = sameSet,
        icon = "same_type", hint = ZeD.tr("UI_ZeD_Controls_HintTakeKinds"),
        run = function(ct)
            local src, d = ct._inventory, otherInventory(ct)
            if not isFloor(src) and not luautils.walkToContainer(src, pn) then return end
            CT.moveItems(playerObj, (sameTypeItems(src, d, keep)), d)
        end }
    if not onFloor then
        -- seated with the window shut it greys and says why, as the game greys its Drop (ISInventoryPaneContextMenu,
        -- ContextMenu_DropFromVehicle) (QA's loot KISS test, Nov 24 2026)
        local shut = ZeD.InventoryRenderer.carWindowShut(playerObj)
        moves[#moves + 1] = { id = "floor", label = ZeD.tr("UI_ZeD_Controls_ToFloor"), enabled = not inv:isEmpty() and not shut,
            icon = "to_floor", hint = ZeD.tr("UI_ZeD_Controls_HintToFloor"),
            help = shut and getText("ContextMenu_DropFromVehicle") or nil,
            run = function(ct)
                -- seated with the window shut, nothing goes out to the ground: ZeD's other floor moves refuse the
                -- same way (moveItems, handleDrop; QA B6-9) (L1-4)
                if ZeD.InventoryRenderer.carWindowShut(playerObj) then return end
                local src = ct._inventory
                local items = {}
                local it = src:getItems()
                for i = 0, it:size() - 1 do items[#items + 1] = it:get(i) end
                -- (Nov 15 2026, add-on hooks: what an add-on's rule refuses stays, ItemRules.lua)
                items = ZeD.ItemRules.filter(items, ISInventoryPage.GetFloorContainer(pn), playerObj, src)
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
        objs[#objs + 1] = { id = "trash", label = sentence(getText("IGUI_invpage_RemoveAll")), enabled = true, danger = true,
            icon = "trash", hint = sentence(getText("IGUI_invpage_RemoveAll")),
            ask = ZeD.tr(n == 1 and "UI_ZeD_Controls_DeleteAskOne" or "UI_ZeD_Controls_DeleteAskMany", n),
            run = function()
                local args = { x = object:getX(), y = object:getY(), z = object:getZ(), index = object:getObjectIndex() }
                sendClientCommand(playerObj, "object", "emptyTrash", args)
            end }
    end
    -- (buttons a mod's support file registered, CT.addProvider; words, so they sit with the words)
    addProviderSpecs(objs, "world", content, inv, dest)
    -- the container's own: the words first, then the icons
    local words, icons = {}, {}
    for _, o in ipairs(objs) do if o.icon then icons[#icons + 1] = o else words[#words + 1] = o end end
    for _, o in ipairs(icons) do words[#words + 1] = o end
    return liteTrim(moves), words
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

-- A mod's gate on the container on show (ContainerGates.lua): its own buttons
-- after the container's, the moves left out when it says so; the moves into
-- the other side off when that side refuses things.
local function applyGates(content, inv, other, moves, objs)
    local G = ZeD.ContainerGates
    local po = content._playerObj
    local gate = G.get(inv, po)
    content._cc.gated = gate ~= nil and gate.band ~= nil
    if gate then
        if gate.noMoves then moves = {} end
        if gate.specs then
            local ok, got = pcall(gate.specs, content._ccSide, content, inv)
            if ok and type(got) == "table" then
                for _, s in ipairs(got) do objs[#objs + 1] = s end
            elseif not ok then
                print("[ZeD] ContainerControls: a gate's buttons failed: " .. tostring(got))
            end
        end
    end
    if other and not isFloor(other) and G.refuses(other, po) then
        for _, m in ipairs(moves) do m.enabled = false end
    end
    return moves, objs
end

-- what a gate says about a container, for the row's signature (false: no gate)
local function gateMode(inv, po)
    local gate = ZeD.ContainerGates.get(inv, po)
    return gate and (gate.mode or true) or false
end

local function refresh(content)
    local cc = content._cc
    local now = getTimestampMs()
    local other = otherInventory(content)
    -- (the containers and their sizes compared as they are: a signature string
    -- built every frame cost two Java toString calls)
    local inv = content._inventory
    local n1, n2 = sizeOf(inv), sizeOf(other)
    -- (a mod's gate on either side: the row is built again when what it says changes)
    local g1, g2 = gateMode(inv, content._playerObj), gateMode(other, content._playerObj)
    local R = ZeD.InventoryRenderer
    local m = (R and R.padMarkCountOf) and R.padMarkCountOf(content) or 0   -- (the controller's marks)
    local same = cc.sigSet and cc.sigInv == inv and cc.sigN1 == n1 and cc.sigOther == other and cc.sigN2 == n2
        and cc.sigG1 == g1 and cc.sigG2 == g2 and cc.sigM == m
    -- (a container event anywhere: the lists' model number moved; rebuilt soon, not every frame of a transfer)
    local gen = (R and R.modelGen) and R.modelGen() or 0
    local age = now - cc.frame   -- (cc.frame: the clock at the last build; -1000 asks for one now)
    if same and cc.moves and age < CT.REFRESH_MS and (cc.sigGen == gen or age < CT.EVENT_MS) then return end
    if not same and cc.invSeen ~= inv then cc.ask = nil; cc.sx = {} end   -- another container: no pending question, the ribbons from their start
    cc.invSeen = inv
    cc.sigSet, cc.sigInv, cc.sigN1, cc.sigOther, cc.sigN2 = true, inv, n1, other, n2
    cc.sigG1, cc.sigG2, cc.sigM = g1, g2, m
    cc.frame, cc.sigGen = now, gen
    local ok, moves, objs
    if content._ccSide == "char" then ok, moves, objs = pcall(buildChar, content)
    else ok, moves, objs = pcall(buildWorld, content) end
    if not ok then
        local msg = tostring(moves)
        if cc.lastErr ~= msg then print("[ZeD] ContainerControls: building the row failed: " .. msg) end
        cc.lastErr = msg
        moves, objs = {}, {}
    end
    moves, objs = applyGates(content, inv, other, moves or {}, objs or {})
    cc.moves, cc.objs = moves, objs
end

-- a word button's width: the push button's (its label as it draws, sentence case)
local function btnW(label) return ZeD.Molecules.buttonW(label) end

CT.ICON_SZ   = 16    -- design units: the icon box inside an icon button (the button is T.buttonH square);
                     -- the pixel icon's drawing that fits it is drawn at its own size (ZeD.PxIcon)
CT.HINT_MS   = ZeD.HINT_DELAY_MS or 450   -- (the one hover delay; kept for older readers of this field)

-- (an icon button names a ZeD pixel icon by its id; one whose drawing is missing stays a word button)
local function isIcon(s) return s ~= nil and s.icon ~= nil and ZeD.PxIcon.has(s.icon) end

-- a button's width: an icon button is a T.buttonH square, a word button fits its word
local function rectW(s)
    if isIcon(s) then return ZeD.T.buttonH end
    return btnW(s.label)
end

-- the room between two buttons in the band: 4u between two icons, 8u otherwise
local function gapBetween(a, b)
    local T = ZeD.T
    if isIcon(a) and isIcon(b) then return T.px(4) end
    return T.px(CT.GAP)
end

-- Lays the band's buttons out between x0 and x1 (column-local): the moves
-- (icons), a divider, the container's own buttons (words first, then icons), the
-- whole run right-aligned at x1 as a dialog's footer (Buttons right, the director,
-- Nov 22 2026: "move them to the right, because on any dialogue or in other places,
-- they're always on the right"; the moves used to start at the band's left). The
-- order among them is kept. When they do not fit: one ribbon between two
-- arrows, each rect keeping tx, its place along the ribbon (draw scrolls it);
-- divX is the divider's place the same way.
local function layRow(moves, objs, x0, x1)
    local T = ZeD.T
    local gap, bh = T.px(CT.GAP), T.buttonH
    local divGap = T.px(CT.DIV_PAD) * 2 + T.px(1)
    local rects, tx = {}, 0
    local function rect(s, at)
        local r = { key = s.id, label = s.label, icon = isIcon(s) and s.icon or nil, spec = s, tx = at, w = rectW(s) }
        rects[#rects + 1] = r
        return r.w
    end
    for i, s in ipairs(moves) do tx = tx + rect(s, tx) + gapBetween(s, moves[i + 1]) end
    local movesEnd = (#moves > 0) and (tx - gapBetween(moves[#moves], nil)) or 0
    local both = #moves > 0 and #objs > 0
    local objW = 0
    for i, s in ipairs(objs) do objW = objW + rectW(s) + (i > 1 and gapBetween(objs[i - 1], s) or 0) end
    local total = movesEnd + (both and divGap or 0) + objW
    local row = { rects = rects, x0 = x0, x1 = x1 }
    local ox
    if total <= x1 - x0 then
        -- (the moves start where the run ends at x1: the band's spare room is left of them, Buttons right)
        local lead = x0 + (x1 - x0) - total
        for _, r in ipairs(rects) do r.tx = lead + r.tx end
        ox = x1 - objW
        if both then row.divX = ox - T.px(CT.DIV_PAD) - T.px(1) end
    else
        ox = movesEnd + (both and divGap or 0)
        if both then row.divX = movesEnd + T.px(CT.DIV_PAD) end
        local viewL = x0 + bh + gap
        row.scroll = { viewL = viewL, viewW = math.max(T.px(20), (x1 - bh - gap) - viewL), total = total }
    end
    for i, s in ipairs(objs) do ox = ox + rect(s, ox) + gapBetween(s, objs[i + 1]) end
    return row
end

--- Lays the band out for a list column colW wide; returns its height (0 = no
--- band: nothing to put in it). The band closes the list; a question
--- (Delete all) takes the whole band over.
function CT.layout(content, colW)
    content._ccMarks = nil
    local cc = state(content)
    if not cc then return 0 end
    refresh(content)
    cc.sx = cc.sx or {}
    cc.hits, cc.arrows, cc.hintCand, cc.strips = {}, {}, nil, {}
    local T = ZeD.T
    local padX = T.px(CT.PAD_X)
    local maxX = colW - padX
    if cc.ask then
        -- (the question band lays its two answers out itself, CT.draw)
        cc.bottom = { question = cc.ask.ask, verb = sentence(getText("IGUI_invpage_RemoveAll")), x0 = padX, x1 = maxX, rects = {} }
        return ZeD.Molecules.bandH()
    end
    if #cc.moves + #cc.objs == 0 and not cc.gated then cc.bottom = nil; return 0 end
    cc.bottom = layRow(cc.moves, cc.objs, padX, maxX)
    return ZeD.Molecules.bandH()
end

local function zoneName(content) return content._ccSide == "char" and "charCtl" or "worldCtl" end

-- the band's button the controller is on: the focus is in this band's zone, in
-- the focused window, with the controller in use (Focus.liveZone)
local function focusedKey(content)
    local F = ZeD.Input and ZeD.Input.Focus
    local win = content._ccWin
    if not (F and win and F.liveZone) then return nil end
    local z = F.liveZone(win)
    if not (z and z.zone == zoneName(content)) then return nil end
    local el = F.liveElement(win)
    return el and el.ccKey or nil
end

-- Draws the band's buttons (top, h) in the column at xOff; name keys its
-- scroll ("bot"; its arrows are cc:-1 / cc:-2). Words are push buttons, the
-- common moves icon buttons that name themselves in a hint after the pause.
local _ccBtn, _ccIcon, _ccFocus = {}, {}, {}
local function drawStrip(content, strip, name, top, h, xOff)
    local cc = content._cc
    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local win = content._ccWin
    local bh = T.buttonH
    local by = top + math.floor((h - bh) / 2)
    local fkey = focusedKey(content)
    _ccFocus.win, _ccFocus.zone = win, zoneName(content)
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
        -- (a content line between the moves and the container's own buttons)
        local bd = T.border
        content:drawRect(shift + strip.divX, by, T.px(1), bh, bd.a, bd.r, bd.g, bd.b)
    end
    local isz = T.px(CT.ICON_SZ)
    for _, r in ipairs(strip.rects) do
        local s = r.spec
        local enabled = (s == nil) or s.enabled
        local danger = r.danger or (s and s.danger)
        local x, y = shift + r.tx, by
        local focused = (fkey == r.key)
        local vx0, vx1 = math.max(x, clipL), math.min(x + r.w, clipR)
        local hover = vx1 > vx0 and content:isMouseOver() and A.mouseIn(content, vx0, y, vx1 - vx0, bh)
        if vx1 > vx0 then
            local help = s and (s.help or s.hint) or r.label
            if r.icon then
                local o = _ccIcon
                o.hover, o.disabled, o.active = hover, not enabled, (s and s.lit) and true or false
                o.focus = focused and _ccFocus or nil
                o.hint, o.id, o.help, o.win = (s and (s.hint or s.label)) or r.label, "cc:" .. tostring(r.key), help, win
                -- (Delete all's bin keeps the warning colour; the rest the text colour)
                o.tint = danger and T.danger or nil
                o.iconSize = isz
                -- (Icon color, the director, Nov 22 2026: the icon's mark in the theme's color at rest, as the
                -- right-click menu's; s.mark names it where the button's side picks it, a Same type that puts in)
                o.marks, o.markKind = T.marks, s and s.mark or nil
                M.drawIconButton(content, x, y, bh, r.icon, o)
            else
                local o = _ccBtn
                o.hover, o.disabled, o.help, o.win = hover, not enabled, help, win
                o.focus = focused and _ccFocus or nil
                M.drawButton(content, x, y, r.w, bh, r.label, danger and "danger" or (s and s.primary and "primary") or "default", false, nil, o)
            end
        end
        if (hover or focused) and s and s.enabled and s.marks then content._ccMarks = s.marks end
        cc.hits[#cc.hits + 1] = { key = r.key, label = (s and s.hint) or r.label, spec = s, ask = r.ask, x = x, y = y, w = r.w, h = bh,
            enabled = enabled, vx = vx0, vw = math.max(0, vx1 - vx0) }
    end
    if S then
        content:clearStencilRect()
        -- the arrows: a scrollbar's own, live while there is more that way; the
        -- other one is the disabled control (its outline at T.disabledAlpha)
        local canL, canR = sx > 0, sx < S.total - S.viewW
        local ax = { xOff + strip.x0, xOff + strip.x1 - bh }
        for k, dir in ipairs({ "left", "right" }) do
            local can = (k == 1 and canL) or (k == 2 and canR)
            local x = ax[k]
            if can then
                local hov = A.mouseIn(content, x, by, bh, bh)
                ZeD.Atoms.drawScrollArrow(content, x, by, bh, dir, hov and "hover" or "default")
                cc.arrows[#cc.arrows + 1] = { idx = -k, x = x, y = by, w = bh, h = bh }
            else
                local bs = T.borderS
                content:drawRectBorder(x, by, bh, bh, (bs.a or 1) * T.disabledAlpha, bs.r, bs.g, bs.b)
            end
        end
    end
end

-- A mod's gate on the container on show: its status mark and words at the
-- band's left, then its moving bar (a search running) up to the first button.
-- The ribbon that scrolls has no room for it.
local function drawGateLine(content, B, top, h, xOff)
    if B.scroll then return end
    local gate = ZeD.ContainerGates.get(content._inventory, content._playerObj)
    local band = gate and gate.band
    if not (band and band.text) then return end
    local T, A = ZeD.T, ZeD.Atoms
    local right = xOff + B.x1
    for _, r in ipairs(B.rects) do
        if xOff + r.tx < right then right = xOff + r.tx end
    end
    right = right - T.px(CT.GAP)
    local x = xOff + B.x0
    local sq = T.px(6)
    A.drawStatusDot(content, x, top + math.floor((h - sq) / 2), band.color or T.warning, sq)
    x = x + sq + T.px(6)
    local f2 = T.fontF2
    local room = right - x
    if room <= 0 then return end
    local s = A.truncateText(band.text, f2, room)
    local tc = T.text
    content:drawText(s, x, top + math.floor((h - ZeD.TM:getFontHeight(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    if band.progress then
        local bx = x + ZeD.TM:MeasureStringX(f2, s) + T.px(CT.GAP)
        local bw = right - bx
        local bh = T.fillBarH
        if bw >= T.px(24) then
            A.drawSmoothBar(content, bx, top + math.floor((h - bh) / 2), bw, band.progress, false, nil, bh)
        end
    end
end

-- ----------------------------------------------------------------------------
-- THE WORN AND HELD LINE (KISS #11, option 2 of the Worn and held setting): with the things you wear and hold kept off
-- the inventory list (they stand on the Equipment tab), the list ends with one line, "Worn and held: Equipment",
-- which opens that tab. It stands in for "Nothing here." while you wear things. The renderer asks wornLineOn, adds a
-- row's height to the list, and draws the line under the last row; a press on it is one more hit of the band (the
-- window already sends "cc:" presses here), so the controller's ring zone has it as a stop too.
-- ----------------------------------------------------------------------------
--- True when this list (your own inventory, one container on show) should end with the line.
function CT.wornLineOn(content)
    if not (content and content._ccSide == "char" and content._playerObj and content._inventory) then return false end
    local po = content._playerObj
    if content._inventory ~= po:getInventory() then return false end
    local R = ZeD.InventoryRenderer
    if R and R.wornListed and R.wornListed() then return false end   -- (they are in the list: no line)
    local ok, n = pcall(function()
        local c = po:getWornItems():size()
        if po:getPrimaryHandItem() then c = c + 1 end
        if po:getSecondaryHandItem() then c = c + 1 end
        return c
    end)
    return ok and n > 0
end

--- Draws the line at y (content-local), w wide and h tall, when it is in view between top and bottom, and makes it a
--- hit of the band. xOff = the list column's x.
function CT.drawWornLine(content, xOff, y, w, h, top, bottom)
    local cc = content._cc
    if not (cc and cc.hits) then return end
    if y + h <= top or y >= bottom then return end
    local T, A = ZeD.T, ZeD.Atoms
    local label = ZeD.tr("UI_ZeD_Inv_WornLine")
    local hover = content:isMouseOver() and A.mouseIn(content, xOff, y, w, h)
    local focused = focusedKey(content) == "wornline"
    if hover then
        local hv = T.hover
        content:drawRect(xOff, y, w, h, hv.a, hv.r, hv.g, hv.b)
    end
    if focused then
        _ccFocus.win, _ccFocus.zone = content._ccWin, zoneName(content)
        ZeD.Focus.mark(content, xOff, y, w, h, _ccFocus)
    end
    local tc = focused and (T.textOnFocus or T.toneNorm) or T.toneNorm
    local f2 = T.fontF2
    local pad = T.px(CT.PAD_X + 4)
    content:drawText(A.truncateText(label, f2, w - pad * 2), xOff + pad, y + math.floor((h - ZeD.TM:getFontHeight(f2)) / 2),
        tc.r, tc.g, tc.b, tc.a or 1, f2)
    local spec = { id = "wornline", label = label, enabled = true, hint = label,
        run = function(ct)
            local pn = ZeD.playerNumOf(ct)
            if ZeD_CharacterWindow and ZeD_CharacterWindow.openTab then ZeD_CharacterWindow.openTab(pn, "equip", false) end
        end }
    cc.hits[#cc.hits + 1] = { key = "wornline", label = label, spec = spec, x = xOff, y = y, w = w, h = h, enabled = true,
        vx = xOff, vw = w }
    content:addHitZone("cc:" .. #cc.hits, xOff, y, w, h)
end

--- Draws the band at top (content-local; xOff = the list column's x). The band
--- is the library's (surface 2 without stacking, its structure line on top);
--- the Delete all question takes it over as the question band (Cancel and the
--- verb, the verb in danger: it cannot be undone). atBottom = false leaves the
--- structure line out.
local _qOpts, _bandSpec = {}, {}
function CT.draw(content, top, colW, xOff, atBottom)
    local cc = content._cc
    local B = cc and cc.bottom
    if not B then return end
    local M = ZeD.Molecules
    local rowH = M.bandH()
    local win = content._ccWin
    cc.row = { x = xOff, y = top, w = colW, h = rowH }
    if B.question then
        local fkey = focusedKey(content)
        _ccFocus.win, _ccFocus.zone = win, zoneName(content)
        _qOpts.danger, _qOpts.win = true, win
        _qOpts.cancelFocus = (fkey == "no") and _ccFocus or nil
        _qOpts.verbFocus = (fkey == "yes") and _ccFocus or nil
        local _, cr, vr = M.drawQuestionBand(content, xOff, top, colW, B.question, B.verb, _qOpts)
        -- the two answers' rects, as the hits the presses and the controller's stops read
        if cr then cc.hits[#cc.hits + 1] = { key = "no", label = ZeD.tr("UI_Cancel"), ask = "no", x = cr.x, y = cr.y, w = cr.w, h = cr.h, enabled = true, vx = cr.x, vw = cr.w } end
        if vr then cc.hits[#cc.hits + 1] = { key = "yes", label = B.verb, ask = "yes", x = vr.x, y = vr.y, w = vr.w, h = vr.h, enabled = true, vx = vr.x, vw = vr.w } end
        return
    end
    _bandSpec.win, _bandSpec.noLine = win, not atBottom
    M.drawBand(content, xOff, top, colW, _bandSpec)
    drawStrip(content, B, "bot", top, rowH, xOff)
    if cc.gated then drawGateLine(content, B, top, rowH, xOff) end
end

--- The icons' hover hints are the library's (ZeD.Molecules.drawIconButton asks
--- the window's overlay for the hint box). Kept so older callers draw nothing.
function CT.drawHint(content) end

--- Hit zones go in after the renderer clears its zones for the frame: each
--- button's showing part, and the arrows.
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

--- The mouse wheel over a ribbon scrolls it sideways; true when it took the wheel.
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
--- Presses the band's hit zone idx. A negative idx is a ribbon arrow:
--- -1 steps one button left, any other negative one button right.
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
--- Rebuilds the row's ring zone from this frame's hits when they moved.
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
    -- a ribbon: Left / Right walk its buttons first (FocusManager), so no list
    -- row beside or under it comes between two of them
    zone.walkLR = true
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
    -- (Nov 16 2026, QA's audit: a second A on "Remove all" emptied the trash.) A question opening lands the focus on
    -- Cancel, never on the answer that acts; when it closes the focus goes back to the button that asked.
    local seat
    local asking = cc and cc.ask ~= nil
    if asking and not cc.askSeated then
        local old = zone.elements and zone.elements[zone.focusedElementIdx or 1]
        cc.askFrom = old and old.ccKey
        for i, e in ipairs(els) do if e.ccKey == "no" then seat = i; break end end
        cc.askSeated = seat ~= nil   -- the band not drawn yet: seat it on the frame it is
    elseif cc and not asking and cc.askSeated then
        for i, e in ipairs(els) do if e.ccKey == cc.askFrom then seat = i; break end end
        cc.askSeated, cc.askFrom = nil, nil
    end
    -- (KISS #18; Transfer in the footer, the director, Nov 22 2026) Down into the band always lands on its first
    -- move: the World window's Take all (or Take marked), the Character window's Transfer all (or Move marked), never
    -- To floor or Same type. FocusManager's Focus._lootAllWrap sends Down past the list's last row here too.
    zone.entryElementIdx = nil
    for i, e in ipairs(els) do if e.ccKey == "take" or e.ccKey == "xfer" then zone.entryElementIdx = i; break end end
    F.setRingZoneElements(win, zn, els, seat)
    F.setZoneFocusable(win, zn, #els > 0)
end

-- ----------------------------------------------------------------------------
-- GRAB ONE, GRAB HALF, GRAB ALL (KISS #31)
-- The game's right-click menu offers "Grab one / Grab half / Grab all" on a stack row of its own list, and only "Grab"
-- on single things. ZeD's lists hand the menu a closed stack as its things, so a stack of 60 rounds got a Grab that
-- took all 60. The game's doGrabMenu is wrapped: when the things it is given are exactly one closed stack of ZeD's
-- lists, it adds the game's three choices (the same options and handlers the game's stack row gets; the handlers
-- take any list of things). Anything else goes to the game's own doGrabMenu unchanged.
-- ----------------------------------------------------------------------------
-- is this list of things exactly one closed stack of a ZeD list (the main list or a column of either window)?
local function isWholeStack(items, pn)
    if type(items) ~= "table" or #items < 2 then return false end
    for _, it in ipairs(items) do
        if not instanceof(it, "InventoryItem") then return false end
    end
    local function fits(stacks)
        if type(stacks) ~= "table" then return false end
        for _, it in ipairs(items) do
            local st = stacks[it]
            if st and st.count == #items and st.items then
                -- every thing of the list is in that stack
                local inStack = {}
                for _, s in ipairs(st.items) do inStack[s] = true end
                for _, x in ipairs(items) do if not inStack[x] then return false end end
                return true
            end
        end
        return false
    end
    for _, W in ipairs({ ZeD_CharacterWindow, ZeD_WorldWindow }) do
        local win = W and W.getWindow and W.getWindow(pn)
        local c = win and win._mainContent
        if c then
            if fits(c._stacks) then return true end
            for _, cs in ipairs(c._colStates or {}) do
                if fits(cs.stacks) then return true end
            end
        end
    end
    return false
end
CT._isWholeStack = isWholeStack   -- (the test sim's way in)

if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.doGrabMenu and not ISInventoryPaneContextMenu._zedGrabWrapped then
    ISInventoryPaneContextMenu._zedGrabWrapped = true
    local origGrabMenu = ISInventoryPaneContextMenu.doGrabMenu
    ISInventoryPaneContextMenu.doGrabMenu = function(context, items, player)
        local ok, whole = pcall(isWholeStack, items, player)
        if ok and whole then
            local dest = getPlayerInventory(player).inventory
            -- (as the game's own stack row: a corpse or generator, or a thing the bag refuses, gets no Grab at all)
            if isForceDropHeavyItem(items[1]) or not dest:isItemAllowed(items[1]) then return end
            context:addOption(getText("ContextMenu_Grab_one"), items, ISInventoryPaneContextMenu.onGrabOneItems, player)
            context:addOption(getText("ContextMenu_Grab_half"), items, ISInventoryPaneContextMenu.onGrabHalfItems, player)
            context:addOption(getText("ContextMenu_Grab_all"), items, ISInventoryPaneContextMenu.onGrabItems, player)
            return
        end
        return origGrabMenu(context, items, player)
    end
end
