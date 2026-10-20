-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Panel.lua
-- ============================================================================
-- ZeD_PANEL — Base panel class for all ZeD UI components
-- One hop from vanilla (ISPanel:derive). Last vanilla touch ever.
--
-- Features:
--   - Transparent by default (no border, no background)
--   - Opt-in drawBg / drawBorder flags
--   - _hitZones table for manual hit testing (ISPanel child mouse dispatch
--     is unreliable — we enumerate zones instead)
--   - _onPrerender hook for draw logic without subclassing
--   - Theme-reactive: reads ZeD.T fresh every prerender(), zero stale data
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/Tokens"
require "ZeD/SafeMode"

ZeD_Panel = ISPanel:derive("ZeD_Panel")

function ZeD_Panel:new(x, y, w, h)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self

    -- Transparent by default — subclasses/instances opt in
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0}
    o.borderColor     = {r = 0, g = 0, b = 0, a = 0}

    -- Anchor to parent resize (standard ISPanel convention)
    o.anchorBottom = true
    o.anchorRight  = true

    -- Opt-in drawing flags
    o.drawBg     = false   -- draw surf1 fill
    o.drawBorder = false   -- draw borderS outline

    -- Hit zone registry — rebuilt each prerender by the owning draw function.
    -- Each entry: {id=any, x=num, y=num, w=num, h=num}
    -- 'id' is whatever the component wants back on click (item ref, row index, etc.)
    o._hitZones = {}

    -- Optional draw hook. Signature: function(panel) ... end
    -- Called at the end of prerender(), after bg and border are drawn.
    -- Set this on instances instead of subclassing for one-off panels.
    o._onPrerender = nil

    return o
end

function ZeD_Panel:initialise()
    ISPanel.initialise(self)
end

-- ============================================================================
-- PRERENDER — draws bg/border then calls the hook
-- ============================================================================

function ZeD_Panel:prerender()
    local T = ZeD.T

    if self.drawBg then
        local c = T.surf1
        self:drawRect(0, 0, self.width, self.height, c.a, c.r, c.g, c.b)
    end

    if self.drawBorder then
        local c = T.borderS
        self:drawRectBorder(0, 0, self.width, self.height, c.a, c.r, c.g, c.b)
        if T.borderW >= 2 then
            do local i = T.px(1); self:drawRectBorder(i, i, self.width - 2 * i, self.height - 2 * i, c.a, c.r, c.g, c.b) end  -- HC double ring: inset by the border's own (scaled) thickness
        end
    end

    -- the hook runs under pcall (SafeMode.lua): a failure clears the stencils it
    -- set, counts towards safe mode's watchdog and is logged once
    local fn = self._onPrerender
    if fn then ZeD.Safe.guard(self, fn) end
end

-- ============================================================================
-- RENDER — called after prerender + children, outside stencil clip.
-- Ghost cards and overlays draw here so they float above everything.
-- ============================================================================

function ZeD_Panel:render()
    local fn = self._onRender
    if fn then ZeD.Safe.guard(self, fn) end
end

-- Stencils are counted per panel, so a draw hook that fails between setting
-- one and clearing it can have it cleared for it (ZeD.Safe.guard)
function ZeD_Panel:setStencilRect(x, y, w, h)
    self._zedStencilN = (self._zedStencilN or 0) + 1
    return ISPanel.setStencilRect(self, x, y, w, h)
end

function ZeD_Panel:clearStencilRect()
    local n = self._zedStencilN
    if n and n > 0 then self._zedStencilN = n - 1 end
    return ISPanel.clearStencilRect(self)
end

-- ============================================================================
-- HIT TESTING
-- ============================================================================

--- Returns true if (mx, my) is inside the rectangle (x, y, w, h).
-- All coordinates are panel-local.
function ZeD_Panel:hitTest(mx, my, x, y, w, h)
    return mx >= x and mx < x + w and my >= y and my < y + h
end

--- Returns the first registered hit zone that contains (mx, my), or nil.
-- Zones are checked in registration order (top of list = first match).
function ZeD_Panel:hitZoneAt(mx, my)
    for _, zone in ipairs(self._hitZones) do
        if self:hitTest(mx, my, zone.x, zone.y, zone.w, zone.h) then
            return zone
        end
    end
    return nil
end

--- Clear all hit zones. Call at the start of each prerender before rebuilding.
function ZeD_Panel:clearHitZones()
    self._hitZones = {}
end

--- Register a hit zone.
-- @param id    Any value returned by hitZoneAt when this zone is hit.
-- @param x, y  Top-left in panel-local coordinates.
-- @param w, h  Dimensions.
function ZeD_Panel:addHitZone(id, x, y, w, h)
    self._hitZones[#self._hitZones + 1] = {id = id, x = x, y = y, w = w, h = h}
end

-- ============================================================================
-- JOYPAD DISPATCH (S93 — Layer 3 plumbing shims)
-- ============================================================================
-- PZ uses duck-typed joypad dispatch (PZAPI-KB Q80): when a joypad button
-- fires, the engine calls onJoypadDown / onJoypadDir* on whatever element
-- joypadData.focus points to, regardless of its class. ISPanelJoypad
-- inheritance is NOT required — any ISPanel subclass that defines these
-- method names receives dispatch.
--
-- These stubs gate on "is THIS panel the focused ZeD window?" via the
-- FocusManager singleton. Unfocused panels ignore joypad input even if
-- joypadData.focus happens to point at them for some other reason.
--
-- In S93, Focus.dispatchJoypadDown / dispatchJoypadDir are themselves
-- no-op stubs — button presses while a ZeD window is focused are silently
-- swallowed. That's intentional for this session: the wiring is in place,
-- and S94 fills in ActionMap translation + focus-stack routing.
--
-- Note: ZeD_Window (in Organisms.lua) derives from ISPanel directly rather
-- than from ZeD_Panel, so it has its own parallel copy of these stubs.
-- Adding them here as well keeps ZeD_Panel subclasses (e.g. ZeD_ContextMenu)
-- forward-compatible for the day we register them with the focus system.
-- ============================================================================

function ZeD_Panel:onJoypadDown(button, joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDown(self, button, joypadData)
    end
end

function ZeD_Panel:onJoypadDirUp(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "up", joypadData)
    end
end

function ZeD_Panel:onJoypadDirDown(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "down", joypadData)
    end
end

function ZeD_Panel:onJoypadDirLeft(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "left", joypadData)
    end
end

function ZeD_Panel:onJoypadDirRight(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "right", joypadData)
    end
end
