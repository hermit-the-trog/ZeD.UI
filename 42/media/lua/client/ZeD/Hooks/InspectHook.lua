-- ZeD-UI/42/media/lua/client/ZeD/Hooks/InspectHook.lua
-- ============================================================================
-- INSPECT ITEM — Context Menu Hook
-- Adds "Inspect Item" to the inventory right-click context menu.
-- Opens a fixed-size ZeD_Window containing a ZeD_ItemCard.
-- No resize handle — card auto-sizes to fit content.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ItemCard"

ZeD = ZeD or {}
ZeD._inspectWindows = ZeD._inspectWindows or {}

-- ============================================================================
-- INSPECT WINDOW
-- ============================================================================

local function getItemUID(item)
    local id = item:getID()
    if id then return tostring(id) end
    return tostring(item)
end

local function openInspectWindow(item, playerNum)
    if not item then return end

    local uid = getItemUID(item)

    if ZeD._inspectWindows[uid] then
        local existing = ZeD._inspectWindows[uid]
        if existing:getIsVisible() then
            existing:bringToTop()
            return
        else
            ZeD._inspectWindows[uid] = nil
        end
    end

    local T = ZeD.T
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    -- Create the item card and measure
    local cardW = 220
    local card = ZeD_ItemCard:new(0, 0, cardW, 200, "inspect", playerNum)
    card:initialise()
    card:setItem(item)
    local cardH = card:calcHeight()

    -- Fixed window — card v10 layout owns the action strip, no footer needed
    local winW = cardW
    local winH = cardH + T.titleBarH
    local winX = math.floor((screenW - winW) / 2)
    local winY = math.floor((screenH - winH) / 2)

    -- Cascade offset
    local offset = 0
    for _, w in pairs(ZeD._inspectWindows) do
        if w:getIsVisible() then offset = offset + 24 end
    end
    winX = winX + offset
    winY = winY + offset

    local displayName = item:getDisplayName() or "Item"
    local win = ZeD_Window:new(winX, winY, winW, winH, displayName)
    win.resizable = false
    win.cardOwnsActionStrip = true  -- card v10 renders its own strip; suppress footer
    win:initialise()
    win:addToUIManager()
    win:bringToTop()

    -- Card fills the body exactly
    local bodyY = win:getBodyY()
    card:setX(0)
    card:setY(bodyY)
    card:setWidth(winW)
    card:setHeight(cardH)
    card:setAnchorLeft(true)
    card:setAnchorRight(true)
    card:setAnchorTop(true)
    -- card:initialise() already called above — do NOT call again or ZoneList child doubles
    win:addChild(card)

    local _origPrerender = win.prerender
    win.prerender = function(self)
        if card.item then
            self.title = card.item:getDisplayName() or "Item"
        end
        -- Track card height changes (text size toggle, theme switch) and
        -- resize the window to match. The card resizes itself in its own
        -- prerender, but the window must follow or the bg goes stale.
        local T = ZeD.T
        local newCardH = card:calcHeight()
        local expectedWinH = newCardH + T.titleBarH
        if math.abs(expectedWinH - self:getHeight()) > 1 then
            self:setHeight(expectedWinH)
            card:setHeight(newCardH)
        end
        _origPrerender(self)
    end

    local _origClose = win.close
    win.close = function(self)
        ZeD._inspectWindows[uid] = nil
        _origClose(self)
    end

    ZeD._inspectWindows[uid] = win
end

-- ============================================================================
-- CONTEXT MENU HOOK
-- ============================================================================

local function onFillInventoryContextMenu(playerNum, context, items)
    if not items or #items == 0 then return end

    local firstItem = nil
    for _, entry in ipairs(items) do
        if instanceof(entry, "InventoryItem") then
            firstItem = entry
            break
        elseif type(entry) == "table" and entry.items then
            for _, subItem in ipairs(entry.items) do
                if instanceof(subItem, "InventoryItem") then
                    firstItem = subItem
                    break
                end
            end
            if firstItem then break end
        end
    end

    if not firstItem then return end

    context:addOption("Inspect Item", firstItem, function(item)
        openInspectWindow(item, playerNum)
    end)
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)
