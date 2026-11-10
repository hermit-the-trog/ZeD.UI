-- ============================================================================
-- ZeD_InvTip.lua: the game's item tooltip over ZeD's inventory and loot lists (punch list 146)
-- ============================================================================
-- The director, Nov 10 2026, after watching a fast vanilla player loot on a stream: "for looting stats need to show
-- quick, without a click". Rulings: the game's own item tooltip (ISToolTipInv, in ZeD's look: Overrides/Tooltip.lua),
-- shown at once as vanilla's inventory shows it, following the pointer from row to row; the item card stays a click
-- away for a thorough look. Being the game's tooltip, it carries every line other mods add to it (More Item
-- Information, Starlit Library and the rest wrap ISToolTipInv's render).
--
-- A list row or grid cell under the pointer asks for it while it draws (ZeD.InvTip.want); once a frame, before the UI
-- draws, the tooltip shows the item asked for in the frame before, or goes. It stays away while items are dragged,
-- while a right-click menu is open, while that same item's card is open in the drawer, and on a controller (the rows
-- keep their pointer hover off while the pad's cues show, so nothing asks).
-- ============================================================================

ZeD = ZeD or {}
ZeD.InvTip = ZeD.InvTip or {}
local IT = ZeD.InvTip

IT._frame = IT._frame or 0
IT._want = nil

--- Ask for the tooltip of item, hovered in owner (a list or grid panel) this frame.
function IT.want(owner, item)
    if not (owner and item) then return end
    local w = IT._want
    if not w then w = {}; IT._want = w end
    w.owner, w.item, w.frame = owner, item, IT._frame
end

--- True when owner asked for item's tooltip this frame (its own hover box then stays away: one box at the pointer).
function IT.wantedBy(owner, item)
    local w = IT._want
    return w ~= nil and w.frame == IT._frame and w.owner == owner and (item == nil or w.item == item)
end

-- the character the owner's window is for (the tooltip reads skills and traits from it)
local function characterOf(win)
    if win then
        if win._playerObj then return win._playerObj end
        if win.playerNum then return getSpecificPlayer(win.playerNum) end
        if win.player and type(win.player) == "number" then return getSpecificPlayer(win.player) end
    end
    return getSpecificPlayer(0)
end

-- the reasons not to show it now
local function held(owner)
    if owner._drag and owner._drag.isActive and owner._drag:isActive() then return true end
    if owner._box and owner._box.live then return true end   -- (a selection box being drawn: ZeD_BoxSelect.lua)
    local d = ISMouseDrag and ISMouseDrag.dragging
    if d ~= nil and (type(d) ~= "table" or #d > 0) then return true end
    return false
end
local function blocked(w)
    local owner, item = w.owner, w.item
    if not (owner.isReallyVisible and owner:isReallyVisible()) then return true end
    if held(owner) then return true end
    local win = ZeD.Atoms and ZeD.Atoms.windowOf and ZeD.Atoms.windowOf(owner) or nil
    local chr = characterOf(win)
    local pn = chr and chr.getPlayerNum and chr:getPlayerNum() or 0
    local ctx = getPlayerContextMenu and getPlayerContextMenu(pn) or nil
    if ctx and ctx.isAnyVisible and ctx:isAnyVisible() then return true end
    -- (its card is open: the card says all of it already)
    if win and win._drawerItem == item then return true end
    return false, chr
end

local function hide()
    local tip = IT._tip
    if tip and tip:isVisible() then
        tip:setVisible(false)
        tip:removeFromUIManager()
    end
end
IT.hide = hide

-- once a frame, before the UI draws: the item asked for in the frame before, or nothing
local function frame()
    IT._frame = IT._frame + 1
    local w = IT._want
    if not (w and w.frame == IT._frame - 1 and w.item) then hide(); return end
    local ok, no, chr = pcall(blocked, w)
    if not ok or no then hide(); return end
    local tip = IT._tip
    if not tip then
        tip = ISToolTipInv:new(w.item)
        tip:initialise()
        IT._tip = tip
        tip._zedItem = w.item
    elseif tip._zedItem ~= w.item then
        tip:setItem(w.item)
        tip._zedItem = w.item
    end
    if tip._zedOwner ~= w.owner then tip:setOwner(w.owner); tip._zedOwner = w.owner end
    if chr and tip._zedChr ~= chr then tip:setCharacter(chr); tip._zedChr = chr end
    -- (beside the pointer, as vanilla's inventory has it; never pinned where the belt's stands)
    tip.followMouse = true
    tip.anchorBottomLeft = nil
    if not tip:isVisible() then
        tip:setVisible(true)
        tip:addToUIManager()
    end
    tip:bringToTop()
end
IT._onFrame = frame

if Events and Events.OnPreUIDraw and not IT._hooked then
    IT._hooked = true
    Events.OnPreUIDraw.Add(function() IT._onFrame() end)
end
