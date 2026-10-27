-- ZeD-UI/42/media/lua/client/ZeD/WindowCurtain.lua
-- ============================================================================
-- WINDOW CURTAINS (Oct 19 2026, mockup ZeDUI/mockups/zed_curtains_v1)
--
-- A window's inventory side rolls up under its title, like a minimized
-- window, while the tab drawer (the map, say) stays open where it is. The
-- chrome keeps its full width: the window itself narrows to the drawer side
-- and a ROD (a title-bar strip of its own, over the rolled side) carries the
-- rolled side's tab. The engine cannot let clicks through part of a panel,
-- so the rolled side cannot simply be left empty inside the window.
--
--   roll:    the window narrows at once (the side's content hides) and the rod
--            starts as tall as the window, its plain fabric rolling up to the
--            title bar at the drawer's speed.
--   unroll:  the rod rolls down to the window's height, then the window widens
--            again and the content comes back.
--
-- The tab: press it to roll the side down; drop items on it to put them in
-- the side's container; with a controller it is a stop on the D-pad (A).
--
-- The rolled side is on the window's left (the World window: containers left of
-- the drawer) or, with spec.side = "right", on its right (the Character
-- window: the inventory right of the drawer). A left side's rod carries the
-- window's close box; a right side's window keeps its own.
--
-- A window opts in with ZeD.Curtain.attach(win, spec):
--   spec.sideW()       screen px of the side that rolls (strip + inventory)
--   spec.canRoll()     true while rolling makes sense (a tab drawer is open)
--   spec.chip()        name, count for the rolled tab
--   spec.dropInv()     the inventory a drop on the tab goes to
--   spec.title()       the window's title while rolled (optional; else it keeps its own)
--   spec.onChange(rolled)  after a roll / unroll (focus zones)
--   spec.onFrame()     every frame while rolled (the tab's controller stop)
-- and its layout reads win._rolled (no strip, no inventory) and calls
-- ZeD.Curtain.sync(win) every frame.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.Curtain = ZeD.Curtain or {}
local C = ZeD.Curtain

local SPEED = 2080          -- design units per second (the drawers' speed)
local TRI_W = 7             -- the roll triangle (the library's triangle atom), design units

-- The roll triangle: up (roll up) or down (roll down), the library's triangle atom
function C.drawTri(panel, x, y, up, col)
    local A, T = ZeD.Atoms, ZeD.T
    if up then A.drawTriangleUp(panel, x, y, T.px(TRI_W), col)
    else A.drawTriangleDown(panel, x, y, T.px(TRI_W), col) end
end

local function anyDragActive()
    for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
        local w = get and get()
        local c = w and w._mainContent
        if c and c._drag and c._drag:isActive() then return true end
        if w and w._equipDrag and w._equipDrag:isActive() then return true end   -- an Equip row's drag
    end
    return false
end

-- ---------------------------------------------------------------------------
-- The rod
-- ---------------------------------------------------------------------------
ZeD_CurtainRod = ISPanel:derive("ZeD_CurtainRod")

function ZeD_CurtainRod:new(win, x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.win = win
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._h = h                -- the animated height
    o._target = h
    return o
end

-- the tab's rect, rod-local
function ZeD_CurtainRod:chipRect()
    local T = ZeD.T
    local name, count = self.win._curtain.chip()
    local label = tostring(name or "") .. "  " .. tostring(count or "")
    self._label = label
    local tbH = T.titleBarH
    local x = self.win._closeOnRod and (T.sp.sm + T.closeBoxSz + T.sp.md - T.sp.titleBoxPad) or T.sp.sm
    local w = T.px(TRI_W) + T.sp.sm + ZeD.TM:MeasureStringX(T.fontF3, label) + T.sp.titleBoxPad * 2
    local h = tbH - T.px(6)
    return { x = x, y = math.floor((tbH - h) / 2), w = w, h = h }
end

function ZeD_CurtainRod:prerender()
    local win = self.win
    -- (a rod its window no longer holds: C.drop took it away with a closed window)
    if not (win and win._rod == self and win:isVisible() and win._rolled) then self:setVisible(false); return end
    local T = ZeD.T
    local tbH = T.titleBarH
    -- the roll: the fabric's height runs to its target at the drawers' speed
    if self._h ~= self._target then
        local dt = math.min(UIManager.getMillisSinceLastRender() / 1000.0, 0.1)
        local step = T.px(SPEED) * dt
        if self._h < self._target then self._h = math.min(self._h + step, self._target)
        else self._h = math.max(self._h - step, self._target) end
        if self._h == self._target and self._target > tbH then C.finishUnroll(win); return end
    end
    local h = math.max(math.floor(self._h), tbH)
    if self:getHeight() ~= h then self:setHeight(h) end
    local w = self:getWidth()
    -- the fabric below the title bar while it rolls
    if h > tbH then ZeD.Molecules.drawBodyBg(self, 0, tbH, w, h - tbH, "surf1") end
    ZeD.Molecules.drawWindowTitleBar(self, 0, 0, w, nil, nil)
    -- The frame: the window's own line weight on the rod's three open sides. The
    -- side against the window is the window's frame line (drawn there): the rod
    -- does not draw a second one beside it.
    local bs = T.borderS
    local fw = T.line and T.line(T.borderW or 1) or T.px(1)
    local right = win._curtain and win._curtain.side == "right"
    self:drawRect(0, 0, w, fw, bs.a or 1, bs.r, bs.g, bs.b)
    self:drawRect(0, h - fw, w, fw, bs.a or 1, bs.r, bs.g, bs.b)
    if right then self:drawRect(w - fw, 0, fw, h, bs.a or 1, bs.r, bs.g, bs.b)
    else self:drawRect(0, 0, fw, h, bs.a or 1, bs.r, bs.g, bs.b) end
    -- the close box closes the window (a left rod's: it is the window's left end)
    self._closeRect = nil
    if win._closeOnRod then
        local cb = T.closeBoxSz
        self._closeRect = { x = T.sp.sm, y = math.floor((tbH - cb) / 2), w = cb, h = cb }
        ZeD.Atoms.drawCloseBox(self, self._closeRect.x, self._closeRect.y, cb, self._overClose)
    end
    -- the tab: the title plate, framed (pressable), with the roll-down triangle.
    -- The pointer: the hover wash, and its help in the window's help line (the
    -- rod has no footer of its own); the controller: the player's focus mark.
    if h > tbH then return end
    local r = self:chipRect()
    self._chip = r
    ZeD.Molecules.drawBodyBg(self, r.x, r.y, r.w, r.h, "surf2")
    local over = self:isMouseOver() and ZeD.Atoms.mouseIn(self, r.x, r.y, r.w, r.h)
    local dragging = anyDragActive()
    if over then
        local hv = T.hover
        self:drawRect(r.x, r.y, r.w, r.h, hv.a, hv.r, hv.g, hv.b)
        if ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, C.tabHelp(win)) end
    end
    local Focus = ZeD.Input and ZeD.Input.Focus
    local onFocus = false
    if Focus and Focus.isFocused and Focus.isFocused(win, nil, "curtain:unroll") then
        onFocus = ZeD.Focus.mark(self, r.x, r.y, r.w, r.h, { win = win }) and true or false
    end
    -- (a drop held over the tab: its frame in the accent, the drop target's cue)
    local bc = (over and dragging) and T.accent or T.borderS
    ZeD.Atoms.frame(self, r.x, r.y, r.w, r.h, bc)
    local ink = onFocus and T.textOnFocus or T.textHead
    local tx = r.x + T.sp.titleBoxPad
    C.drawTri(self, tx, r.y + math.floor((r.h - T.px(TRI_W)) / 2), false, ink)
    tx = tx + T.px(TRI_W) + T.sp.sm
    local fh = ZeD.TM:getFontHeight(T.fontF3)
    self:drawText(self._label, tx, r.y + math.floor((r.h - fh) / 2), ink.r, ink.g, ink.b, ink.a or 1, T.fontF3)
end

-- the rolled tab's plain words for the window's help line ("Inventory, 9 items:
-- press to roll it down, or drop things on it")
function C.tabHelp(win)
    local name, count = win._curtain.chip()
    local n = tonumber(count) or 0
    return ZeD.tr(n == 1 and "UI_ZeD_Curtain_TabHelpOne" or "UI_ZeD_Curtain_TabHelp", tostring(name or ""), n)
end

local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

function ZeD_CurtainRod:onMouseMove(dx, dy)
    self._overClose = inRect(self._closeRect, self:getMouseX(), self:getMouseY())
    if self._dragging then
        local win = self.win
        win:setX(win:getX() + dx); win:setY(win:getY() + dy)
        self:setX(self:getX() + dx); self:setY(self:getY() + dy)
    end
end
function ZeD_CurtainRod:onMouseMoveOutside(dx, dy)
    self._overClose = false
    self:onMouseMove(dx, dy)
end
function ZeD_CurtainRod:onMouseDown(x, y)
    if inRect(self._closeRect, x, y) or inRect(self._chip, x, y) then self._pressed = true; return true end
    self._dragging = true
    return true
end
function ZeD_CurtainRod:onMouseUp(x, y)
    self._dragging = false
    if not self._pressed then return true end
    self._pressed = false
    if inRect(self._closeRect, x, y) then
        getSoundManager():playUISound("UIActivateButton")
        self.win:close()
    elseif inRect(self._chip, x, y) then
        getSoundManager():playUISound("UIActivateTab")
        C.unroll(self.win)
    end
    return true
end
function ZeD_CurtainRod:onMouseUpOutside(x, y) self._dragging = false; self._pressed = false end

-- ---------------------------------------------------------------------------
-- The window side
-- ---------------------------------------------------------------------------
function C.attach(win, spec)
    win._curtain = spec
    if win._curtainHooked then return end
    win._curtainHooked = true
    local baseDown = win.onMouseDown
    win.onMouseDown = function(self, x, y)
        if not self._rolled and inRect(self._rollBtn, x, y) and self._curtain.canRoll() then
            getSoundManager():playUISound("UIActivateTab")
            C.roll(self)
            return true
        end
        return baseDown(self, x, y)
    end
    local baseRender = win.render
    win.render = function(self)
        baseRender(self)
        C.drawRollButton(self)
    end
    -- Every way a window closes ends in its removeFromUIManager (its close box,
    -- the rod's close box, the inventory key, the controller's Y hold, death,
    -- safe mode): the rod is a top-level panel of its own and stayed on screen,
    -- tied to the closed window. It goes with the window.
    local baseRemove = win.removeFromUIManager
    win.removeFromUIManager = function(self)
        C.drop(self)
        return baseRemove(self)
    end
end

-- the roll-up box after the title, while the side can roll: a title-bar box,
-- the close box's size and look (surface 2, the hover wash, a 1u frame), with
-- an up triangle in it
function C.drawRollButton(win)
    win._rollBtn = nil
    if win._rolled or win.windowShaded or not (win._curtain and win._curtain.canRoll()) then return end
    local T = ZeD.T
    local tbH = T.titleBarH
    local tbp = T.sp.titleBoxPad
    local titleX = T.sp.sm + T.closeBoxSz + T.sp.md
    local titleW = ZeD.TM:MeasureStringX(T.fontF3, tostring(win.title or ""))
    local s = T.closeBoxSz
    local r = { x = titleX + titleW + tbp + T.px(2), y = math.floor((tbH - s) / 2), w = s, h = s }
    win._rollBtn = r
    local over = win:isMouseOver() and ZeD.Atoms.mouseIn(win, r.x, r.y, r.w, r.h)
    local bg = over and T.hover or T.surf2
    win:drawRect(r.x, r.y, r.w, r.h, 1, bg.r, bg.g, bg.b)
    ZeD.Atoms.frame(win, r.x, r.y, r.w, r.h, T.borderS)
    local tri = math.max(T.px(5), math.min(T.px(TRI_W), s - T.px(6)))
    ZeD.Atoms.drawTriangleUp(win, r.x + math.floor((r.w - tri) / 2), r.y + math.floor((r.h - tri) / 2), tri, T.textDim)
    if over and ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, ZeD.tr("UI_ZeD_Curtain_RollHelp")) end
end

function C.roll(win)
    if win._rolled then return end
    local spec = win._curtain
    local sideW = math.floor(spec.sideW())
    if sideW <= 0 then return end
    local x, y, h = win:getX(), win:getY(), win:getHeight()
    local right = spec.side == "right"
    -- The exact screen-px geometry before the roll (never design units): the
    -- unroll gives the width back to the pixel, at the x / y the rolled window
    -- was moved to. The saved layout of both windows adds the rolled side back
    -- (saveCharState / saveWorldState), so the rolled size is never persisted.
    local snap = { x = x, y = y, w = win:getWidth(), h = h }
    win._curtainSnap = snap
    win._rolled = true
    win._rollW = sideW
    win._closeOnRod = not right
    -- The window's minimum width still belongs to the unrolled layout until
    -- its next frame, and the engine enforces it right after a mouse press
    -- (ISUIElement:onResize after the window's update): the roll was undone to
    -- that minimum at once, and the unroll then added the side again (a wider
    -- window, shoved along the screen edge). The rolled window's minimum is no
    -- wider than itself; the window's layout sets its own one next frame.
    local rolledW = snap.w - sideW
    win.minimumWidth = math.min(win.minimumWidth or rolledW, rolledW)
    -- width first: setX keeps a top-level panel on screen against its current width
    win:setWidth(rolledW)
    if right then x = x + win:getWidth()      -- the rod: where the side was, right of the window
    else win:setX(x + sideW) end
    snap.rx, snap.rw = win:getX(), win:getWidth()   -- the rolled window as it starts
    local rod = win._rod
    if not rod then
        rod = ZeD_CurtainRod:new(win, x, y, sideW, h)
        rod:initialise()
        rod:instantiate()
        win._rod = rod
    end
    -- size before position (setX / setY keep a top-level panel on screen against its current size)
    rod:setWidth(sideW); rod:setHeight(h)
    rod:setX(x); rod:setY(y)
    rod._h, rod._target = h, ZeD.T.titleBarH
    rod:addToUIManager()
    rod:setVisible(true)
    if spec.onChange then spec.onChange(true) end
end

function C.unroll(win)
    if not win._rolled then return end
    local rod = win._rod
    if rod and rod:isVisible() then
        rod._target = win:getHeight()       -- rolls down; finishUnroll at the bottom
    else
        C.finishUnroll(win)
    end
end

-- the window back at its full geometry, the rod gone from the screen (no onChange)
local function restore(win)
    local w = win._rollW or 0
    local snap = win._curtainSnap
    win._rolled = false
    win._curtainSnap = nil
    local right = win._curtain and win._curtain.side == "right"
    -- The width from before the roll, to the pixel, unless something resized
    -- the rolled window (a tab with another drawer width): then the rolled
    -- width plus the side. x: where the window was before the roll, moved as
    -- far as the rolled window was moved (the same as the rolled x, less the
    -- side on the left). The height and y were never touched.
    local fullW, x = win:getWidth() + w, right and win:getX() or (win:getX() - w)
    if snap then
        if win:getWidth() == snap.rw then fullW = snap.w end
        x = snap.x + (win:getX() - snap.rx)
    end
    -- Width first, then x: setWidth / setX keep a top-level panel on screen
    -- against its current width, so the wider window must be in place first.
    x = math.max(0, math.min(x, getCore():getScreenWidth() - fullW))
    win:setWidth(fullW)
    win:setX(x)
    -- A window anchored on its right edge (the Character window: the drawer grows
    -- leftwards) reads that edge in the same frame (a Loot click snaps the width
    -- against it), so it is the unrolled edge from here on, not the rolled one
    if win._anchorRightEdge then win._anchorRightEdge = win:getX() + win:getWidth() end
    if win._lastSetX then win._lastSetX = win:getX() end
    win._closeOnRod = nil
    local rod = win._rod
    if rod then rod:setVisible(false); rod:removeFromUIManager() end
end

-- at once: back to the full window (also when the drawer closes under a rolled
-- side, and before a layout snap that measures the unrolled window: Loot)
function C.finishUnroll(win)
    if not win._rolled then return end
    restore(win)
    if win._curtain and win._curtain.onChange then win._curtain.onChange(false) end
end

-- The window closes (its removeFromUIManager, hooked in C.attach): the side
-- comes back without a sound or a ring rebuild and the rod leaves the UI
-- manager for good. Both windows are built afresh on every open from their
-- saved layout, which already counts a rolled side as down (saveCharState /
-- saveWorldState), and a roll is never saved: a reopened window opens unrolled,
-- at its pre-roll geometry, on its tab, like its other remembered state.
function C.drop(win)
    if win._rolled then restore(win) end
    local rod = win._rod
    win._rod = nil
    if rod then rod:setVisible(false); rod:removeFromUIManager() end
end

-- every frame from the window's layout: the rod follows the window; the side
-- comes back when there is no tab drawer to keep
function C.sync(win)
    if not win._rolled then return end
    local spec = win._curtain
    if not spec.canRoll() then C.finishUnroll(win); return end
    -- A rolled window moves with its rod: keep both on screen, so the unroll
    -- finds room for the side at the window's own x (never shoved aside)
    local scrW = getCore():getScreenWidth()
    local wx, ww = win:getX(), win:getWidth()
    local minX, maxX = 0, scrW - ww
    if spec.side == "right" then maxX = scrW - ww - win._rollW else minX = win._rollW end
    if maxX >= minX then
        local cx = math.max(minX, math.min(wx, maxX))
        if cx ~= wx then
            win:setX(cx)
            if win._lastSetX then win._lastSetX = cx end
        end
    end
    local rod = win._rod
    if rod then
        -- (the rod hides itself while the window is closed; it stays in the UI manager)
        if not rod:isVisible() and not win.windowShaded then rod:setVisible(true) end
        if win.windowShaded and rod:isVisible() then rod:setVisible(false) end
        rod:setX((spec.side == "right") and (win:getX() + win:getWidth()) or (win:getX() - win._rollW))
        rod:setY(win:getY())
    end
    if spec.title then
        win.title = spec.title() or win.title
        win.titleStats = {}
    end
    if spec.onFrame then spec.onFrame() end
end

-- a drop released over a rolled tab: that side's inventory
function C.dropTarget()
    for _, get in ipairs({ ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow, ZeD_WorldWindow and ZeD_WorldWindow.getWindow }) do
        local w = get and get()
        local rod = w and w._rolled and w._rod
        if rod and rod:isVisible() and rod:isMouseOver() and inRect(rod._chip, rod:getMouseX(), rod:getMouseY()) then
            return w._curtain.dropInv()
        end
    end
    return nil
end

-- the controller's stop on the tab, in the coordinates of a zone whose panel
-- sits at (px, py) in the window
function C.padElement(win, px, py)
    local rod = win._rod
    local r = rod and rod._chip
    if not (win._rolled and r) then return nil end
    return {
        x = ((win._curtain.side == "right") and win:getWidth() or -win._rollW) + r.x - px, y = r.y - py, w = r.w, h = r.h,
        id = "curtain:unroll",
        promptA = ZeD.tr("UI_ZeD_Curtain_Unroll"),
        onFocus = function() end,
        onActivate = function(w) C.unroll(w) end,
    }
end
