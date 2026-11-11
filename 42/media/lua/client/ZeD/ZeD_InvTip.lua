-- ============================================================================
-- ZeD_InvTip.lua: what the pointer shows over ZeD's inventory and loot lists (punch list 146)
-- ============================================================================
-- Since the director's "use our parts" (Nov 10 2026): the row under the pointer shows ZeD's loot card
-- (ZeD_LootCard.lua, ZeD's balloon by the pointer, at once); holding Alt shows the game's own tooltip below instead,
-- with every line mods add to it. This file also keeps the transfers waiting in the player's queue, for the rows
-- that show them (IT.queued). What follows is the game's tooltip, as first built:
--
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

-- Alt held (either one): the game's tooltip rather than ZeD's card
local function altDown()
    if not (isKeyDown and Keyboard) then return false end
    return isKeyDown(Keyboard.KEY_LMENU) or isKeyDown(Keyboard.KEY_RMENU)
end
IT.altDown = altDown

local blocked   -- (below)

--- The row or cell under the pointer, while it draws: item, hovered in owner (a list or grid panel); rect = the
--- row or cell in owner's space { x, y, w, h }; count = a stack's count; beside = true for a grid cell (the card
--- stands beside the cell rather than over it). ZeD's loot card is drawn this frame by the card's own layer, on top
--- of every window (ZeD_LootCard's layer, below), or with Alt held, the game's tooltip (shown before the next frame).
--- pref = "above": the card stands above rect, its tail on it, rather than by the pointer (the belt's boxes: the
--- belt keeps its own game box for Alt, so it asks only without Alt).
function IT.want(owner, item, rect, count, beside, pref)
    if not (owner and item) then return end
    local w = IT._want
    if not w then w = {}; IT._want = w end
    w.owner, w.item, w.frame = owner, item, IT._frame
    w.alt = altDown()
    w.content = nil
    if w.alt or not (rect and ZeD.LootCard) then return end
    local ok, no, chr = pcall(blocked, w)
    if not ok or no then return end
    local okC, c = pcall(ZeD.LootCard.content, item, chr, count)
    if not (okC and c) then return end
    -- by the pointer: the balloon's tail on the row where the pointer is, the card to its right; a row's name, once
    -- drawn, moves the tail past it (IT.nameEnd); a grid cell's card stands at the cell's right edge
    local ox, oy = owner:getAbsoluteX(), owner:getAbsoluteY()
    local mx = owner.getMouseX and owner:getMouseX() or rect.x
    local rw = rect.w or 1
    w.content, w.count = c, count
    w.rx, w.rw, w.ox, w.oy = rect.x, rw, ox, oy
    w.ax = beside and (rect.x + rw - 1) or math.max(rect.x, math.min(rect.x + rw - 1, mx))
    w.ay, w.ah, w.aw, w.pref = rect.y, rect.h or 1, 1, nil
    if pref == "above" then w.ax, w.aw, w.pref = rect.x, rw, "above" end
    IT.showLayer()
end

--- A hovered row's name ends at x (owner's space): the card's tail goes past it, so the name stays in sight (QA's
--- Mac run, Nov 10 2026: the card covered the row's own name).
function IT.nameEnd(owner, item, x)
    local w = IT._want
    if not (w and w.content and w.frame == IT._frame and w.owner == owner and w.item == item) then return end
    local T = ZeD.T
    local nx = x + T.px(4)
    if nx > w.ax then w.ax = math.min(w.rx + w.rw - 1, nx) end
end

-- THE CARD'S LAYER: a top-level panel, above every window, that draws the card asked for this frame (the windows'
-- own overlays clip at their edges: on the last rows the card lost its bottom lines, QA's Mac run, Nov 10 2026)
local Layer = nil
function IT.showLayer()
    if Layer then
        if not Layer:isVisible() then Layer:setVisible(true) end
        Layer:bringToTop()
        return
    end
    if not ISPanel then return end
    Layer = ISPanel:new(0, 0, 1, 1)
    Layer.background = false
    Layer.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    Layer.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    Layer:initialise()
    Layer:instantiate()
    pcall(function() Layer.javaObject:setConsumeMouseEvents(false) end)
    Layer.prerender = function() end
    Layer.render = function(self)
        local w = IT._want
        -- (this frame's, or the last frame's when the layer draws before the lists do)
        if not (w and w.content and w.frame >= IT._frame - 1 and ZeD.Balloon) then return end
        local a = IT._rect or {}
        IT._rect = a
        a.x, a.y, a.w, a.h, a.below, a.noFlip = w.ox + w.ax, w.oy + w.ay, w.aw or 1, w.ah, nil, nil
        ZeD.Balloon.draw(self, w.content, a, w.pref or "right", { key = w.item, owner = self })
    end
    Layer:addToUIManager()
    Layer:setAlwaysOnTop(true)
    IT._layer = Layer
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
blocked = function(w)
    local owner, item = w.owner, w.item
    if not (owner.isReallyVisible and owner:isReallyVisible()) then return true end
    if held(owner) then return true end
    local win = ZeD.Atoms and ZeD.Atoms.windowOf and ZeD.Atoms.windowOf(owner) or nil
    local chr = characterOf(win or owner)   -- (the belt is in no window: its own player)
    local pn = chr and chr.getPlayerNum and chr:getPlayerNum() or 0
    local ctx = getPlayerContextMenu and getPlayerContextMenu(pn) or nil
    if ctx and ctx.isAnyVisible and ctx:isAnyVisible() then return true end
    -- (its card is open: the card says all of it already)
    if win and win._drawerItem == item then return true end
    return false, chr
end

-- (whether the tooltip is on screen is kept here, not read from it: a new ISToolTipInv already reports itself
-- visible, so "add it when it isn't visible" never added it, and the first hover of a session drew nothing until the
-- pointer had left the lists once: QA's Mac run, Nov 10 2026)
local function hide()
    local tip = IT._tip
    if tip and tip._zedShown then
        tip:setVisible(false)
        tip:removeFromUIManager()
        tip._zedShown = false
    end
end
IT.hide = hide

-- once a frame, before the UI draws: the item asked for in the frame before, or nothing
local function frame()
    IT._frame = IT._frame + 1
    local w = IT._want
    if not (w and w.frame == IT._frame - 1 and w.item and w.alt) then hide(); return end
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
    if not tip._zedShown then
        tip:setVisible(true)
        tip:addToUIManager()
        tip._zedShown = true
    end
    tip:bringToTop()
end
IT._onFrame = frame

-- ---------------------------------------------------------------------------
-- THE QUEUE: the items waiting to move (ISInventoryTransferAction in the player's timed action queue), read once a
-- frame per player, for the rows that say so (InventoryRenderer's queueMark). 0..1: the one moving now, how far.
-- ---------------------------------------------------------------------------
local Q = { frame = -1, chr = nil, map = {}, any = false }
IT._queue = Q
local function readQueue(chr)
    Q.frame, Q.chr = IT._frame, chr
    if Q.any then Q.map = {}; Q.any = false end
    if not (chr and ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue) then return end
    local ok, q = pcall(ISTimedActionQueue.getTimedActionQueue, chr)
    local list = ok and q and q.queue
    if not list then return end
    for i, act in ipairs(list) do
        local it = act and act.item
        if it and (act.Type == "ISInventoryTransferAction" or (act.srcContainer and act.destContainer)) then
            local d = 0
            if i == 1 and act.action then
                local okD, v = pcall(function() return act.action:getJobDelta() end)
                if okD and type(v) == "number" then d = math.max(0, math.min(1, v)) end
            end
            Q.map[it] = d
            Q.any = true
        end
    end
end
--- How far item, shown in owner's list, is in its move: nil (not waiting), 0 (waiting), to 1 (all but there).
function IT.queued(owner, item)
    local win = ZeD.Atoms and ZeD.Atoms.windowOf and ZeD.Atoms.windowOf(owner) or nil
    local chr = characterOf(win)
    if Q.frame ~= IT._frame or Q.chr ~= chr then readQueue(chr) end
    if not Q.any then return nil end
    return Q.map[item]
end

if Events and Events.OnPreUIDraw and not IT._hooked then
    IT._hooked = true
    Events.OnPreUIDraw.Add(function() IT._onFrame() end)
end
