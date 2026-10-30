-- ZeD-UI/42/media/lua/client/ZeD/Organisms.lua
-- ============================================================================
-- ORGANISM COMPONENTS
-- Complete UI assemblies built from atoms and molecules.
-- Seven organisms: Window, ScrollList, TabPanel, ItemGrid, Modal, ContextMenu, ScrollPanel.
--
-- These are the rooms of the building. Every game panel is composed from
-- one or more of these organisms. They read from ZeD.T (the active palette)
-- and use ZeD.Atoms / ZeD.Molecules for consistent drawing.
--
-- Design anchor: System 7.1.2. Cherry-pick from 6, 7.5, OS 9 — dress in 7.1.2 clothes.
-- Structural containers: 0px corners. Pressable elements: 3px radius.
-- Groove dividers. Proportional scrollbar. Disclosure triangles.
-- Fonts: Fira Mono (chrome), Fira Sans (content).
-- Fill bars: 13px tall. Title bar: 26px with breathing room.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/SafeMode"
require "ZeD/ZeD_Surface"

ZeD = ZeD or {}


-- ============================================================================
-- O1: WINDOW FRAME
-- ============================================================================
-- The universal shell. Every panel in the mod lives inside one of these.
-- System 6 striped title bar: the close box at the left, the title, the
-- stats, and the window box at the right end (its pull-down: theme, accent,
-- text size, see-through, controller highlight, reset, ZeD setup;
-- ZeD_WindowMenu.lua). At the foot, the help line: the plain words for what
-- the pointer is over, or the controller's prompts, ending in the grow box on
-- a resizable window. WindowShade collapse on title bar double-click (System 7.1).
--
-- The frame is one rectangle around the whole window, drawn after everything
-- inside it: a click-through child (ZeD_WindowOverlay) kept as the window's
-- last child draws the help line, the resize handles, the frame and then the
-- controller's focus mark (ZeD.Focus.drawOverlay), so no drawer, card, strip
-- or scrollbar can cover the frame or leave a gap in it. Two line weights:
-- the frame (1u, 2u on High contrast: T.borderW) and the structure lines under
-- the title bar and over the help line (1u), which run to the frame's inner edge.
--
-- A resizable window resizes from its bottom edge (height), either bottom
-- corner (both; the bottom-left one moves the left edge) and either side edge
-- (width). A handle shows once the pointer rests on an edge.
--
-- Derives from ISPanel. All chrome, drag, WindowShade, and resize are
-- implemented from scratch using ZeD atomics — no vanilla window baggage.
-- ============================================================================

-- design units
local HELP_H   = 22    -- the help line, and the grow box at its right end
local EDGE_B   = 6     -- the bottom edge's grab zone
local EDGE_S   = 4     -- the side edges' grab zones
local GRIP_LEN = 40    -- a resize handle's ridged grip
-- milliseconds
local REST_MS  = 350   -- the pointer rests this long on an edge before its handle shows
local SOLID_MS = 200   -- solid while in use: the fade to solid and back

local SURF_KEYS = { "base", "surf1", "surf2", "surf3", "surf4" }

-- the frame's thickness: 1u, 2u on High contrast, in whole pixels
local function frameW(T) return T.line(T.borderW or 1) end

ZeD_Window = ISPanel:derive("ZeD_Window")

function ZeD_Window:new(x, y, width, height, title)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.title = title or ""
    o.titleStats = {}
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0}
    o.borderColor     = {r = 0, g = 0, b = 0, a = 0}
    o.drawFrame     = false
    o.resizable     = true
    o.pin           = true
    o.clearStentil  = true
    o.windowShaded     = false
    o._lastTitleClick  = nil   -- timestamp for WindowShade double-click detection
    o.isZeDWindow   = true     -- (ZeD.Surface and ZeD.Help find a panel's window by it)

    return o
end

function ZeD_Window:createChildren()
    local T = ZeD.T
    local cbSz = T.closeBoxSz

    -- Close box: draw-based hit rect (no ISButton child).
    -- Geometry stored for hit-testing in update(); drawn in prerender().
    self._closeBtnRect = {
        x = T.sp.sm,
        y = math.floor((T.titleBarH - cbSz) / 2),
        w = cbSz, h = cbSz
    }
    self._closeHover = false
    self._closeWasDown = false

    -- Stub so any code that checks self.closeButton doesn't crash
    self.closeButton = {}

    -- No vanilla pin/collapse — stubs only
    self.pinButton = {}
    self.collapseButton = {}

    -- Resize state (managed by update / onMouseDown / onMouseMove on the edges)
    self._resizing = false
    self.minimumWidth = T.minWinW
    self.minimumHeight = T.minWinH
end

function ZeD_Window:titleBarHeight()
    return ZeD.T.titleBarH
end

-- The close box's rect from the current scale and text size (a window built before the
-- root scale settled, the menu's at 4K, kept a 1x box in the corner of a 2x title bar)
function ZeD_Window:closeRect()
    local cb = self._closeBtnRect
    if not cb then return nil end
    local T = ZeD.T
    local sz = T.closeBoxSz
    cb.x, cb.y, cb.w, cb.h = T.sp.sm, math.floor((self:titleBarHeight() - sz) / 2), sz, sz
    return cb
end

-- The window box at the right end of the title bar: the close box's size and look, three
-- lines inside. Every ZeD window has one (noWindowBox = true leaves it out).
function ZeD_Window:windowBoxRect()
    if self.noWindowBox then return nil end
    local T = ZeD.T
    local sz = T.closeBoxSz
    local r = self._wboxRect
    if not r then r = {}; self._wboxRect = r end
    r.x, r.y, r.w, r.h = self:getWidth() - T.sp.sm - sz, math.floor((self:titleBarHeight() - sz) / 2), sz, sz
    return r
end

-- Public WindowShade toggle. Collapses to title bar on true; expands to prior
-- height on false. Idempotent (no-op if already in target state). Shared by
-- the title-bar double-click path AND FocusManager's windowshade-on-stick
-- trigger (S95). Children are hidden/restored so content doesn't render
-- underneath the collapsed title bar; the overlay that draws the frame stays.
function ZeD_Window:setWindowShaded(shaded)
    local T = ZeD.T
    if self.windowShaded == shaded then return end
    self.windowShaded = shaded
    local tbH = self:titleBarHeight()
    local ov = self._zedOverlay
    if shaded then
        self.preShadeHeight = self.height
        self:setHeight(tbH)
        local children = self:getChildren()
        if children then
            for _, child in pairs(children) do
                if child ~= ov then
                    child._wasVisible = child:isVisible()
                    child:setVisible(false)
                end
            end
        end
    else
        self:setHeight(self.preShadeHeight or T.px(300))
        local children = self:getChildren()
        if children then
            for _, child in pairs(children) do
                if child._wasVisible ~= nil then
                    child:setVisible(child._wasVisible)
                    child._wasVisible = nil
                end
            end
        end
    end
end

-- The grow box: as tall as the help line it ends (the same square marks the bottom-left
-- corner while that corner's handle shows)
function ZeD_Window:resizeWidgetHeight()
    return ZeD.T.px(HELP_H)
end

-- The help line's height. Every ZeD window has it; a small window that still draws its
-- own footer strip says themeFooter = false and goes without until it moves onto the line.
function ZeD_Window:footerHeight()
    if self.themeFooter == false then return 0 end
    return ZeD.T.px(HELP_H)
end

-- The frame draws under pcall (SafeMode.lua): a failure counts towards safe
-- mode's watchdog and is logged once, rather than throwing every frame
function ZeD_Window:prerender()
    ZeD.Safe.guard(self, ZeD_Window._drawFrame)
end

-- The window's own render runs after its children, the overlay among them, which has
-- drawn the help line and the frame by now: only the palette goes back here
function ZeD_Window:render()
    self:_restoreSurfaces()
    self:_restoreAccent()
end

-- Stencils counted per window, as on ZeD_Panel (ZeD.Safe.guard clears the ones a failed draw left)
function ZeD_Window:setStencilRect(x, y, w, h)
    self._zedStencilN = (self._zedStencilN or 0) + 1
    return ISPanel.setStencilRect(self, x, y, w, h)
end

function ZeD_Window:clearStencilRect()
    local n = self._zedStencilN
    if n and n > 0 then self._zedStencilN = n - 1 end
    return ISPanel.clearStencilRect(self)
end

-- The palette a window with its own accent draws in, built once per base theme, accent
-- and see-through value (the tables are fixed) rather than blended again every frame
local accentPalettes = {}
local function windowAccentPalette(baseKey, accentKey)
    local sa = ZeD.surfaceAlpha
    local ck = baseKey .. "|" .. accentKey .. "|" .. tostring(sa)
    local p = accentPalettes[ck]
    if p then return p end
    local accentSet = ZeD.AccentColors[accentKey]
    local variant = baseKey == "light" and accentSet.light or accentSet.dark
    p = {
        accent       = variant.accent,
        accentBright = variant.bright,
        hover        = variant.hover,
    }
    -- Re-tint surfaces with this window's accent (none: the base theme's own)
    local base = ZeD.BaseThemes[baseKey]
    if accentKey ~= "mono" then
        local TINT = 0.03
        local ac = baseKey == "light" and variant.bright or variant.accent
        local blend = ZeD.colorBlend
        p.base    = blend(base.base, ac, TINT)
        p.surf1   = blend(base.surf1, ac, TINT)
        p.surf2   = blend(base.surf2, ac, TINT)
        p.surf3   = blend(base.surf3, ac, TINT)
        p.surf4   = blend(base.surf4, ac, TINT)
        p.border  = blend(base.border, ac, TINT)
        p.borderS = blend(base.borderS, ac, TINT)
        p.text     = blend(base.text, ac, TINT * 0.5)
        p.textHead = blend(base.textHead, ac, TINT * 0.5)
    else
        p.base = base.base;  p.surf1 = base.surf1; p.surf2 = base.surf2
        p.surf3 = base.surf3; p.surf4 = base.surf4
        p.border = base.border; p.borderS = base.borderS
        p.text = base.text; p.textHead = base.textHead
    end
    -- the see-through setting: the same surface alpha as the global palette (Tokens.lua applyTheme),
    -- before the readable colours are solved against these surfaces
    if type(sa) == "number" then
        local ca = ZeD.colorAlpha
        p.base, p.surf1, p.surf2 = ca(p.base, sa), ca(p.surf1, sa), ca(p.surf2, sa)
        p.surf3, p.surf4 = ca(p.surf3, sa), ca(p.surf4, sa)
    end
    -- the readable text colours (accentText, toneHi/Lo, textSec, textDim, textOnAccent, textOnFocus,
    -- the status *Text variants) are solved against THIS palette's surfaces and accent
    ZeD.deriveReadable(p, baseKey)
    accentPalettes[ck] = p
    return p
end

-- A new see-through value (Settings.lua): the windows' own palettes are built again
function ZeD_Window.clearPaletteCache()
    accentPalettes = {}   -- (a new table, not keys cleared while pairs walks them)
end

-- ----------------------------------------------------------------------------
-- See-through: solid while in use
-- ----------------------------------------------------------------------------
-- In use: the pointer over the window (no other window above it), or the controller in it
function ZeD_Window:_inUse()
    if self:pointerOn() then return true end
    local I = ZeD.Input
    local F, Det = I and I.Focus, I and I.Detector
    if F and F.getFocusedWindow and F.getFocusedWindow() == self
       and Det and Det.getMode and Det.getMode() == "gamepad" then
        return true
    end
    -- (the main menu's windows keep their own controller focus)
    local MM = ZeD.MainMenu
    if MM and MM.gamepad and MM.activeWindow and MM.gamepad() and MM.activeWindow() == self then return true end
    return false
end

-- This window's surface alpha this frame when it differs from the palette's (nil: the
-- palette's own). With "Solid while in use" on, it eases to 1 while the window is in use
-- and back over SOLID_MS when it is not, per window.
function ZeD_Window:_surfaceAlpha(T)
    local S = ZeD.Settings
    local base = (T.surf1 and T.surf1.a) or 1
    if base >= 0.999 or not (S and S.solidInUse and S.solidInUse()) then
        self._seeA, self._seeAt = nil, nil
        return nil
    end
    local now = getTimestampMs()
    local cur = self._seeA or base
    if cur < base then cur = base elseif cur > 1 then cur = 1 end
    local dt = now - (self._seeAt or now)
    self._seeAt = now
    local target = self:_inUse() and 1 or base
    if cur ~= target then
        local step = (1 - base) * dt / SOLID_MS
        if cur < target then cur = math.min(target, cur + step) else cur = math.max(target, cur - step) end
    end
    self._seeA = cur
    if cur - base < 0.004 then return nil end
    return cur
end

-- The surfaces at this window's alpha for its render cycle (put back in render): every fill
-- inside the window that reads T.surfN follows it. The window's own colour tables are reused.
function ZeD_Window:_swapSurfaces()
    local T = ZeD.T
    local a = self:_surfaceAlpha(T)
    if not a then return end
    local saved = self._surfSaved
    if not saved then saved = {}; self._surfSaved = saved end
    local mine = self._surfMine
    if not mine then mine = {}; self._surfMine = mine end
    for i = 1, #SURF_KEYS do
        local k = SURF_KEYS[i]
        local c = T[k]
        saved[k] = c
        local m = mine[k]
        if not m then m = {}; mine[k] = m end
        m.r, m.g, m.b, m.a = c.r, c.g, c.b, a
        T[k] = m
    end
    self._surfT = T
end

function ZeD_Window:_restoreSurfaces()
    local T = self._surfT
    if not T then return end
    local saved = self._surfSaved
    for i = 1, #SURF_KEYS do
        local k = SURF_KEYS[i]
        T[k] = saved[k]
    end
    self._surfT = nil
end

-- ----------------------------------------------------------------------------
-- The overlay: the window's last child, which draws over everything inside it
-- ----------------------------------------------------------------------------
ZeD_WindowOverlay = ISPanel:derive("ZeD_WindowOverlay")
ZeD_WindowOverlay.zedScaled = true   -- (its borders T.px(1) thick, as the window's own: Overrides/TextScale.lua)

function ZeD_WindowOverlay:new(win)
    local o = ISPanel:new(0, 0, win:getWidth(), win:getHeight())
    setmetatable(o, self)
    self.__index = self
    o.win = win
    o.background = false
    return o
end

function ZeD_WindowOverlay:prerender() end

function ZeD_WindowOverlay:render()
    local win = self.win
    if win then ZeD.Safe.guard(win, ZeD_Window._drawTop, "ZeD_Window frame") end
end

-- Click-through, except a press that starts a resize: that one is the window's alone, so
-- a tab strip or a scrollbar under a side edge does not take it as well
function ZeD_WindowOverlay:onMouseDown(x, y)
    local win = self.win
    if win and win:_resizeStartZone(x, y) then return true end
    return false
end
function ZeD_WindowOverlay:onMouseUp() return false end
function ZeD_WindowOverlay:onMouseUpOutside() return false end
function ZeD_WindowOverlay:onRightMouseDown() return false end
function ZeD_WindowOverlay:onRightMouseUp() return false end
function ZeD_WindowOverlay:onMouseWheel() return false end
function ZeD_WindowOverlay:onMouseMove() return false end
function ZeD_WindowOverlay:onMouseMoveOutside() return false end

-- The overlay made on the first frame, sized to the window, and kept last: a child added
-- later (a drawer, a hover layer, a figure) is moved under it here, before the children draw
-- (one added while they draw sits over it for that one frame)
function ZeD_Window:_keepOverlayLast()
    if not self.javaObject then return end
    local ov = self._zedOverlay
    if not ov then
        ov = ZeD_WindowOverlay:new(self)
        ov:initialise()
        ov:instantiate()
        ov.javaObject:setConsumeMouseEvents(false)
        self._zedOverlay = ov
        ISUIElement.addChild(self, ov)
    end
    local w, h = self:getWidth(), self:getHeight()
    if ov:getWidth() ~= w then ov:setWidth(w) end
    if ov:getHeight() ~= h then ov:setHeight(h) end
    if not ov:isVisible() then ov:setVisible(true) end
    -- (also back after a clearChildren took it out)
    local ctrls = self.javaObject:getControls()
    local n = ctrls and ctrls:size() or 0
    if n == 0 or ctrls:get(n - 1) ~= ov.javaObject then
        if self.children then ISUIElement.removeChild(self, ov) end
        ISUIElement.addChild(self, ov)
    end
end

-- ----------------------------------------------------------------------------
-- Drawing: the title bar and the body (prerender, under the children)
-- ----------------------------------------------------------------------------
-- the window box: the close box's look with three lines across it
local function drawWindowBox(p, x, y, sz, lit)
    local T = ZeD.T
    local bg = lit and T.hover or T.surf2
    p:drawRect(x, y, sz, sz, 1, bg.r, bg.g, bg.b)
    local bs = T.borderS
    p:drawRectBorder(x, y, sz, sz, bs.a, bs.r, bs.g, bs.b)
    local ins = T.px(3)
    local lh = T.hair
    local inner = sz - 2 * ins
    local step = math.floor((inner - lh) / 2)
    local y0 = y + ins + math.floor((inner - (2 * step + lh)) / 2)
    local c = T.textDim
    for i = 0, 2 do
        p:drawRect(x + ins, y0 + i * step, sz - 2 * ins, lh, c.a or 1, c.r, c.g, c.b)
    end
end

-- The title bar: surface 2 (one layer: ZeD.Surface), stripes broken behind the title and the
-- stats (System 7's knockout, without a second fill), the close box, the title, the stats
-- right-aligned left of the window box, the window box, and the structure line under it all.
-- A stat: { text, color = its mark's colour (default textDim), noMark = true for none }.
function ZeD_Window:_drawTitleBar(w, tbH)
    local T = ZeD.T
    local sp = T.sp
    local tm = ZeD.TM
    local f3 = T.fontF3
    local tbp = sp.titleBoxPad

    ZeD.Surface.fill(self, 0, 0, w, tbH, "surf2")

    local box = self:windowBoxRect()
    local right = box and (box.x - sp.md) or (w - sp.sm)
    local titleX = sp.sm + T.closeBoxSz + sp.md
    local textY = math.floor((tbH - (T.fontF3H or tm:getFontHeight(f3))) / 2)
    local shown, tW = nil, 0
    local title = self.title
    if title and title ~= "" then
        shown = ZeD.Atoms.truncateText(tostring(title), f3, math.max(0, right - titleX - tbp))
        tW = tm:MeasureStringX(f3, shown)
    end

    -- stats right to left from the window box; one that would reach the title is dropped
    local statL = nil
    local stats = self.titleStats
    if stats and #stats > 0 then
        local mk, mkGap = T.px(6), T.px(4)
        local minX = titleX + tW + tbp * 2 + sp.md
        local sx = right
        local tc = T.text
        local my = math.floor((tbH - mk) / 2)
        for i = #stats, 1, -1 do
            local st = stats[i]
            local txt = tostring(st.text or "")
            local sw = tm:MeasureStringX(f3, txt)
            local dc = st.color or T.textDim
            -- (a colour at alpha 0 was the old way to say "no mark")
            local mark = not st.noMark and (dc.a == nil or dc.a > 0)
            local need = sw + (mark and (mk + mkGap) or 0)
            if sx - need < minX then break end
            sx = sx - sw
            self:drawText(txt, sx, textY, tc.r, tc.g, tc.b, tc.a or 1, f3)
            if mark then
                sx = sx - mkGap - mk
                self:drawRect(sx, my, mk, mk, dc.a or 1, dc.r, dc.g, dc.b)
            end
            statL = sx
            sx = sx - sp.md
        end
    end

    -- the stripes, with a gap behind the title and behind the stats
    local st = T.stripe
    if st and st.a > 0 then
        local k1L, k1R = shown and (titleX - tbp) or nil, shown and (titleX + tW + tbp) or nil
        local k2L, k2R = statL and (statL - tbp) or nil, statL and (right + tbp) or nil
        local sh = T.px(1)
        for sy = T.px(2), tbH - T.px(2), T.px(4) do
            local x0 = 0
            if k1L then
                if k1L > x0 then self:drawRect(x0, sy, k1L - x0, sh, st.a, st.r, st.g, st.b) end
                x0 = k1R
            end
            if k2L then
                if k2L > x0 then self:drawRect(x0, sy, k2L - x0, sh, st.a, st.r, st.g, st.b) end
                if k2R > x0 then x0 = k2R end
            end
            if w > x0 then self:drawRect(x0, sy, w - x0, sh, st.a, st.r, st.g, st.b) end
        end
    end

    if shown then
        local th = T.textHead
        self:drawText(shown, titleX, textY, th.r, th.g, th.b, th.a or 1, f3)
    end
    -- Close box (a rolled-up side: the close box is on its rod, WindowCurtain)
    if self._closeBtnRect and not self._closeOnRod then
        local cb = self:closeRect()
        ZeD.Atoms.drawCloseBox(self, cb.x, cb.y, cb.w, self._closeHover)
    end
    if box then drawWindowBox(self, box.x, box.y, box.w, self._wboxHover or self._wboxOpen) end

    -- the structure line under the bar, to the frame's inner edges (a shaded window's frame closes it)
    if not (self.isCollapsed or self.windowShaded) then
        local fw = frameW(T)
        local bs = T.borderS
        self:drawRect(fw, tbH - T.hair, w - 2 * fw, T.hair, bs.a, bs.r, bs.g, bs.b)
    end
end

function ZeD_Window:_drawFrame()
    local T = ZeD.T

    -- Per-window accent override: swap ZeD.T accent + tinted surface fields for this render cycle
    if self._accentKey and ZeD.AccentColors[self._accentKey] and ZeD.BaseThemes[ZeD.currentBase] then
        local pal = windowAccentPalette(ZeD.currentBase, self._accentKey)
        -- the global values are kept in a table this window reuses (restored in _restoreAccent)
        local s = self._accentStore
        if not s then s = {}; self._accentStore = s end
        s.accent       = T.accent
        s.accentBright = T.accentBright
        s.hover        = T.hover
        local rk = ZeD.READABLE_KEYS
        for i = 1, #rk do s[rk[i]] = T[rk[i]] end
        s.base = T.base; s.surf1 = T.surf1; s.surf2 = T.surf2
        s.surf3 = T.surf3; s.surf4 = T.surf4
        s.border = T.border; s.borderS = T.borderS
        s.text = T.text; s.textHead = T.textHead
        self._savedAccent = s
        T.accent       = pal.accent
        T.accentBright = pal.accentBright
        T.hover        = pal.hover
        for i = 1, #rk do T[rk[i]] = pal[rk[i]] end
        T.base = pal.base; T.surf1 = pal.surf1; T.surf2 = pal.surf2
        T.surf3 = pal.surf3; T.surf4 = pal.surf4
        T.border = pal.border; T.borderS = pal.borderS
        T.text = pal.text; T.textHead = pal.textHead
    end
    -- this window's own see-through (solid while in use), after the accent's surfaces
    self:_swapSurfaces()

    self:_keepOverlayLast()
    ZeD.Surface.beginFrame(self)

    local w = self:getWidth()
    local h = self:getHeight()
    local tbH = self:titleBarHeight()
    -- where and how big it first opened ("Reset this window" on a window outside the pair)
    if not self._zedHome then self._zedHome = { x = self:getX(), y = self:getY(), w = w, h = h } end

    -- Reactive minimums — follow text size changes
    self.minimumWidth = T.minWinW
    self.minimumHeight = T.minWinH

    self:_drawTitleBar(w, tbH)

    -- Body: between the title bar and the help line, minus what bands, headers and cards drawn
    -- over it claimed last frame (ZeD.Surface), so every spot of the window carries one surface.
    -- No inset: the frame is drawn over it, last (the overlay).
    if not self.isCollapsed and not self.windowShaded then
        ZeD.Surface.drawBody(self, 0, tbH, w, h - tbH - self:footerHeight(), "surf1")
    end
end

-- ============================================================================
-- S123: CAPABILITY-DRIVEN BUTTON PROMPTS
-- The help line's prompts are derived from the focused element's callbacks,
-- never hand-authored: A if onActivate, hold-A if onHoldActivate, X if
-- onContextMenu (or onReset), B if onCancel, Y always (window pair). Labels
-- come from the element (promptA / promptHold / promptX / promptB) or from
-- the id-prefix table below, else generic verbs. Elements that gain a new
-- callback automatically gain a prompt; stale prompts are impossible.
-- ============================================================================
local PROMPT_LABELS = {
    -- (the values are translation keys, read through ZeD.tr when the legend is built)
    ["invrow"]          = { a = "UI_ZeD_Prompt_Card",   hold = "UI_ZeD_Prompt_Use", x = "UI_ZeD_Prompt_Menu" },
    ["tab"]             = { a = "IGUI_Open" },
    ["jsub"]            = { a = "UI_ZeD_Prompt_Switch" },
    ["animals:submode"] = { a = "UI_ZeD_Prompt_Switch" },
    ["container"]       = { a = "IGUI_Open" },
    ["cnt"]             = { a = "IGUI_Open" },
    ["map:canvas"]      = { a = "IGUI_Place",  x = "UI_ZeD_Prompt_Edit" },
    ["map:fold"]        = { a = "UI_ZeD_Prompt_Fold" },
    ["map:popout"]      = { a = "UI_ZeD_Prompt_Unfold" },
    ["map:tool"]        = { a = "UI_ZeD_Prompt_Tool" },
    ["map:gridtool"]    = { a = "UI_ZeD_Prompt_Tool",   x = "UI_ZeD_Prompt_Pin" },
    ["map:color"]       = { a = "IGUI_Color" },
    ["craft:row"]       = { a = "UI_ZeD_Prompt_Recipe" },
    ["jrecipe:row"]     = { a = "UI_ZeD_Prompt_Recipe" },
    ["build:row"]       = { a = "UI_ZeD_Prompt_Recipe" },
    ["exercise"]        = { a = "UI_ZeD_Prompt_Start" },
    ["skill:"]          = { a = "UI_ZeD_Prompt_Pin" },
    ["equipslot"]       = { a = "UI_ZeD_Prompt_Card" },
    ["equippart"]       = { a = "UI_ZeD_Prompt_Card" },
    ["cancel_band"]     = { a = "UI_Cancel" },
    ["forage:stance"]   = { a = "UI_ZeD_Prompt_Search" },
}

-- L3 / R3 (Oct 23 2026) lead the prompts while the pad is on an item list: the
-- leftmost go first when the help line is narrow, so A, X and Y outlast them
local function _addListPrompts(win, prompts)
    local z = win._focusRing and win._focusIdx and win._focusRing[win._focusIdx]
    local zn = z and tostring(z.zone) or ""
    if not (zn:find("MainInv$") or zn:find("MC%d+$")) then return end
    local R = ZeD.InventoryRenderer
    local extra = R and R.padPrompts and R.padPrompts(win)
    for i = #(extra or {}), 1, -1 do table.insert(prompts, 1, extra[i]) end
end

local function _promptsFor(el)
    local out = {}
    if not el then
        out[#out + 1] = { glyph = "Y", label = ZeD.tr("UI_ZeD_Prompt_Windows") }
        return out
    end
    local id = tostring(el.id or "")
    local labels, bestLen = nil, 0
    for prefix, def in pairs(PROMPT_LABELS) do
        if id:sub(1, #prefix) == prefix and #prefix > bestLen then labels = def; bestLen = #prefix end
    end
    labels = labels or {}
    if el.onActivate     then out[#out + 1] = { glyph = "A", label = el.promptA or ZeD.tr(labels.a or "UI_ZeD_Prompt_Select") } end
    if el.onHoldActivate then out[#out + 1] = { glyph = "A", label = ZeD.tr("UI_ZeD_Prompt_Hold", el.promptHold or ZeD.tr(labels.hold or "UI_ZeD_Prompt_Use")) } end
    if el.onContextMenu  then out[#out + 1] = { glyph = "X", label = el.promptX or ZeD.tr(labels.x or "UI_ZeD_Prompt_Menu") }
    elseif el.onReset    then out[#out + 1] = { glyph = "X", label = ZeD.tr("UI_ZeD_Prompt_Reset") } end
    if el.onCancel       then out[#out + 1] = { glyph = "B", label = el.promptB or ZeD.tr(labels.b or "UI_ZeD_Prompt_Back") } end
    -- controls the element answers to beyond the face buttons (the map: the triggers zoom, the stick moves)
    if el.extraPrompts then for _, p in ipairs(el.extraPrompts) do out[#out + 1] = p end end
    out[#out + 1] = { glyph = "Y", label = ZeD.tr("UI_ZeD_Prompt_Windows") }
    return out
end

-- The prompts the help line shows, or nil for the help words: a window outside FocusManager
-- (the main menu's) hands its own in (getFooterPrompts: the list, or nil in mouse mode);
-- otherwise the focused element's, in gamepad mode, while this window has the controller.
function ZeD_Window:_footerPrompts()
    if self.getFooterPrompts then
        local own = self:getFooterPrompts()
        if own then return own end
    end
    local I = ZeD.Input
    local Focus, Det = I and I.Focus, I and I.Detector
    if not (Det and Det.getMode and Det.getMode() == "gamepad") then return nil end
    if not (Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == self) then return nil end
    local el = Focus.getFocusedElement and Focus.getFocusedElement(self)
    local prompts = _promptsFor(el)
    pcall(_addListPrompts, self, prompts)
    -- the Y hold's lock, while it is on: a "Locked" prompt in place of Y's
    if Focus.isLocked and Focus.isLocked() then
        for i = #prompts, 1, -1 do
            if prompts[i].glyph == "Y" then table.remove(prompts, i) end
        end
        prompts[#prompts + 1] = { glyph = "Y", label = ZeD.tr("UI_ZeD_Prompt_Locked") }
    end
    return prompts
end

-- ----------------------------------------------------------------------------
-- Drawing: the help line, the resize handles and the frame (the overlay, last)
-- ----------------------------------------------------------------------------
-- The prompts left-aligned from x: each button's picture (ZeD_PadGlyphs) 14u tall, or its
-- name in a box with the glyph setting on Keyboard/mouse or Off, then its label in F2.
-- Too long for the line: the leftmost go first (an item list's L3 / R3 lead the list).
local _pw, _pr, _pg = {}, {}, {}
local function drawPrompts(p, prompts, x, y, h, maxX)
    local T = ZeD.T
    local tm = ZeD.TM
    local f2, f5 = T.fontF2, T.fontF5
    local pic = T.px(14)
    local gap, between = T.px(4), T.px(8)
    local PG = ZeD.PadGlyphs
    local set = PG and PG.set()
    local k = PG and PG.k(pic) or 1
    local n = #prompts
    local total = 0
    for i = 1, n do
        local pr = prompts[i]
        local label, gw, roles = nil, 0, false
        if type(pr) == "string" then
            label = pr
        else
            label = tostring(pr.label or "")
            roles = (set and (pr.pad or PG.roles(pr.glyph))) or false
            if roles then gw = PG.width(roles, k, set)
            else gw = math.max(pic, tm:MeasureStringX(f5, tostring(pr.glyph or "")) + T.px(4)) end
        end
        local wi = ((gw > 0) and (gw + gap) or 0) + ((label ~= "") and tm:MeasureStringX(f2, label) or 0)
        _pw[i], _pr[i], _pg[i] = wi, roles, gw
        total = total + wi + ((i > 1) and between or 0)
    end
    local first = 1
    while first < n and x + total > maxX do
        total = total - _pw[first] - between
        first = first + 1
    end
    if x + total > maxX then return end
    local fh2 = T.fontF2H or tm:getFontHeight(f2)
    local textY = y + math.floor((h - fh2) / 2)
    local bs, tc, td = T.borderS, T.text, T.textDim
    for i = first, n do
        local pr = prompts[i]
        local gw = _pg[i]
        if type(pr) == "string" then
            p:drawText(pr, x, textY, td.r, td.g, td.b, td.a or 1, f2)
        else
            if _pr[i] then
                PG.draw(p, _pr[i], x, y, h, k, set)
            else
                local g = tostring(pr.glyph or "")
                local gy = y + math.floor((h - pic) / 2)
                local fh5 = T.fontF5H or tm:getFontHeight(f5)
                p:drawRectBorder(x, gy, gw, pic, bs.a, bs.r, bs.g, bs.b)
                p:drawText(g, x + math.floor((gw - tm:MeasureStringX(f5, g)) / 2), gy + math.floor((pic - fh5) / 2), tc.r, tc.g, tc.b, tc.a or 1, f5)
            end
            local label = tostring(pr.label or "")
            if label ~= "" then p:drawText(label, x + gw + gap, textY, tc.r, tc.g, tc.b, tc.a or 1, f2) end
        end
        x = x + _pw[i] + between
    end
end

-- a grow box's three ridges (as ZeD.Atoms.drawResizeRidges) in a colour of their own;
-- mirror = the bottom-left corner's, the ridges running towards that corner
local function drawRidges(p, x, y, size, lt, la, mirror)
    local T = ZeD.T
    local dk = T.base
    local da = T.ridgeDarkA or 0.5
    local u = T.px(1)
    for i = 0, 2 do
        local off = T.px(i * 4)
        local x1 = x + size - T.px(4) - off
        local y1 = y + size - T.px(2)
        local x2 = x + size - T.px(2)
        local y2 = y + size - T.px(4) - off
        local steps = math.floor(math.max(math.abs(x2 - x1), math.abs(y2 - y1)) / u)
        if steps > 0 then
            for s = 0, steps do
                local px = x1 + math.floor((x2 - x1) * s / steps)
                local py = y1 + math.floor((y2 - y1) * s / steps)
                if mirror then px = 2 * x + size - px - u end
                p:drawRect(px, py, u, u, la, lt.r, lt.g, lt.b)
                local sx, sy = px + u, py + u
                if sx > x and sx < x + size - u and sy < y + size - u then
                    p:drawRect(sx, sy, u, u, da, dk.r, dk.g, dk.b)
                end
            end
        end
    end
end

-- the grow box (lit: its ridges in the accent, while its handle shows or it is dragged)
local function drawGrow(p, x, y, sz, lit, mirror)
    if not lit and not mirror then ZeD.Atoms.drawGrowBox(p, x, y, sz); return end
    local T = ZeD.T
    local bg, bs = T.surf2, T.borderS
    p:drawRect(x, y, sz, sz, bg.a or 1, bg.r, bg.g, bg.b)
    p:drawRectBorder(x, y, sz, sz, bs.a, bs.r, bs.g, bs.b)
    if lit then drawRidges(p, x, y, sz, T.accent, 1, mirror)
    else drawRidges(p, x, y, sz, T.textDim, T.ridgeLightA or 0.6, mirror) end
end

-- The help line: surface 2 with the structure line on top, then the controller's prompts
-- (gamepad) or the help words in F2 textDim (mouse), and the grow box at the right end
function ZeD_Window:_drawHelpLine(p, w, h, lit)
    -- The engine runs update() only every 100 ms, apart from drawing: a stamp made there was gone
    -- by the next frame drawn, and the line blinked between the window box's words and the status
    -- line (Oct 30 2026, the director's mouse pass). The boxes' hover (watched each frame,
    -- _watchBoxes) and what update() found (_updHelp, the Reader's) are stamped here instead.
    if not self._helpText then
        local uh = (self._wboxHover and ZeD.tr("UI_ZeD_WinMenu_Help"))
            or (self._closeHover and ZeD.tr("UI_ZeD_WinMenu_CloseHelp")) or self._updHelp
        if uh then ZeD.Help.set(self, uh) end
    end
    local text = ZeD.Help.take(self)   -- (taken every frame, so a stamp never outlives its frame)
    local T = ZeD.T
    local fH = self:footerHeight()
    local grow = self.resizable and self:resizeWidgetHeight() or 0
    if fH > 0 then
        local fY = h - fH
        local fw = frameW(T)
        ZeD.Surface.fill(p, 0, fY, w - grow, fH, "surf2")
        local bs = T.borderS
        p:drawRect(fw, fY, w - 2 * fw, T.hair, bs.a, bs.r, bs.g, bs.b)
        local x0 = (lit == "sw") and (grow + T.px(6)) or T.px(10)
        local maxX = w - grow - T.px(10)
        local prompts = self:_footerPrompts()
        if prompts and #prompts > 0 then
            drawPrompts(p, prompts, x0, fY, fH, maxX)
        else
            if lit then text = ZeD.tr("UI_ZeD_Window_ResizeHelp") end
            if text and maxX > x0 then
                local f2 = T.fontF2
                local d = T.textDim
                local fh2 = T.fontF2H or ZeD.TM:getFontHeight(f2)
                p:drawText(ZeD.Atoms.truncateText(text, f2, maxX - x0), x0, fY + math.floor((fH - fh2) / 2), d.r, d.g, d.b, d.a or 1, f2)
            end
        end
    end
    if grow > 0 then drawGrow(p, w - grow, h - grow, grow, lit == "se", false) end
end

-- the handle of the edge the pointer rests on (or drags): a ridged grip in the accent at the
-- middle of the bottom edge or of a side, or the bottom-left corner's box (the bottom-right's
-- is the grow box, lit in _drawHelpLine); the frame's line on that edge is lit in drawFrameRect
local function drawHandle(win, p, w, h, lit)
    local T = ZeD.T
    local fw = frameW(T)
    local ac, dk, s2 = T.accent, T.base, T.surf2
    local da = T.ridgeDarkA or 0.5
    local hair = T.hair
    local len = T.px(GRIP_LEN)
    local sg, pad = T.px(3), T.px(2)
    if lit == "s" then
        local gx = math.floor((w - len) / 2)
        local yA = h - fw - T.px(2) - 2 * hair
        local yB = yA - sg
        p:drawRect(gx - pad, yB - pad, len + 2 * pad, h - fw - (yB - pad), 1, s2.r, s2.g, s2.b)
        p:drawRect(gx, yB, len, hair, 1, ac.r, ac.g, ac.b)
        p:drawRect(gx, yB + hair, len, hair, da, dk.r, dk.g, dk.b)
        p:drawRect(gx, yA, len, hair, 1, ac.r, ac.g, ac.b)
        p:drawRect(gx, yA + hair, len, hair, da, dk.r, dk.g, dk.b)
    elseif lit == "w" or lit == "e" then
        local top = win:titleBarHeight()
        local gy = top + math.floor((h - top - win:footerHeight() - len) / 2)
        local xA, xB
        if lit == "w" then xA = fw + T.px(1); xB = xA + sg
        else xB = w - fw - T.px(1) - 2 * hair; xA = xB - sg end
        p:drawRect(xA - pad + T.px(1), gy - pad, xB + 2 * hair - xA + 2 * pad - T.px(1), len + 2 * pad, 1, s2.r, s2.g, s2.b)
        p:drawRect(xA, gy, hair, len, 1, ac.r, ac.g, ac.b)
        p:drawRect(xA + hair, gy, hair, len, da, dk.r, dk.g, dk.b)
        p:drawRect(xB, gy, hair, len, 1, ac.r, ac.g, ac.b)
        p:drawRect(xB + hair, gy, hair, len, da, dk.r, dk.g, dk.b)
    elseif lit == "sw" then
        local sz = win:resizeWidgetHeight()
        drawGrow(p, 0, h - sz, sz, true, true)
    end
end

-- the frame: one rectangle around the whole window, its edge lit in the accent while that
-- edge's resize handle shows
local function drawFrameRect(p, w, h, lit)
    local T = ZeD.T
    local t = frameW(T)
    local bs, ac = T.borderS, T.accent
    p:drawRect(0, 0, w, t, bs.a, bs.r, bs.g, bs.b)
    local c = (lit == "s") and ac or bs
    p:drawRect(0, h - t, w, t, c.a or 1, c.r, c.g, c.b)
    c = (lit == "w") and ac or bs
    p:drawRect(0, t, t, h - 2 * t, c.a or 1, c.r, c.g, c.b)
    c = (lit == "e") and ac or bs
    p:drawRect(w - t, t, t, h - 2 * t, c.a or 1, c.r, c.g, c.b)
end

-- The overlay's draw (ZeD_WindowOverlay:render), after every other child of the window: the
-- help line, a resize handle, the frame, then the controller's focus mark from ZeD.Focus
-- (which may reach past the window's edge: nothing here clips it)
function ZeD_Window._drawTop(win)
    local p = win._zedOverlay
    if not p then return end
    local w, h = win:getWidth(), win:getHeight()
    local shaded = win.isCollapsed or win.windowShaded
    local lit = (not shaded) and win._rzLit or nil
    win:_watchBoxes()   -- (every frame drawn: update() runs only every 100 ms)
    if not shaded then
        win:_drawHelpLine(p, w, h, lit)
        if lit then drawHandle(win, p, w, h, lit) end
    end
    drawFrameRect(p, w, h, lit)
    local F = ZeD.Focus
    if F and F.drawOverlay then
        local ok, err = pcall(F.drawOverlay, p, win)
        if not ok then ZeD.logOnce("ZeD.Focus.drawOverlay", err) end
    end
end

-- The global accent back after this window's render cycle (also when the draw failed)
function ZeD_Window:_restoreAccent()
    local T = ZeD.T
    if self._savedAccent then
        local s = self._savedAccent
        T.accent       = s.accent
        T.accentBright = s.accentBright
        T.hover        = s.hover
        local rk = ZeD.READABLE_KEYS
        for i = 1, #rk do T[rk[i]] = s[rk[i]] end
        T.base = s.base; T.surf1 = s.surf1; T.surf2 = s.surf2
        T.surf3 = s.surf3; T.surf4 = s.surf4
        T.border = s.border; T.borderS = s.borderS
        T.text = s.text; T.textHead = s.textHead
        self._savedAccent = nil
    end
end

-- ----------------------------------------------------------------------------
-- Resizing: the bottom edge (height), the bottom corners (both; the bottom-left
-- moves the left edge and keeps the right one), the side edges (width). The
-- engine only reports a press inside the panel, so the zones lie inside the
-- window: the bottom 6u, the 22u corner squares (the bottom-right one is the
-- grow box), the outer 4u of each side below the title bar. The bottom edge
-- and the corners start a drag at once (nothing else there takes a press); a
-- side edge, where the tab strips, the container strips and the scrollbars
-- live, only once its handle shows, after the pointer has rested on it.
-- ----------------------------------------------------------------------------
-- the zone at (mx, my) in window coordinates: "s", "se", "sw", "w", "e" or nil
function ZeD_Window:_resizeZoneAt(mx, my)
    if not self.resizable or self.windowShaded or self.isCollapsed then return nil end
    local T = ZeD.T
    local w, h = self:getWidth(), self:getHeight()
    if mx < 0 or my < 0 or mx >= w or my >= h then return nil end
    local cz = self:resizeWidgetHeight()
    if my >= h - cz then
        if mx >= w - cz then return "se" end
        if mx < cz then return "sw" end
    end
    if my >= h - T.px(EDGE_B) then return "s" end
    if my >= self:titleBarHeight() then
        local e = T.px(EDGE_S)
        if mx < e then return "w" end
        if mx >= w - e then return "e" end
    end
    return nil
end

-- the zone a press at (mx, my) starts a resize from (a side edge only while its handle shows)
function ZeD_Window:_resizeStartZone(mx, my)
    local z = self:_resizeZoneAt(mx, my)
    if (z == "w" or z == "e") and self._rzLit ~= z then return nil end
    return z
end

function ZeD_Window:_startResize(mode)
    self._resizing = true
    self._resizeMode = mode
    self._resizeYOnly = (mode == "s")
    self._resizeRight = self:getX() + self:getWidth()   -- (the left edge moves; this one stays)
    self._growBoxWasDown = true
    self.moving = false   -- kill any drag that started in onMouseDown
    self:setCapture(true)
    self:bringToTop()
end

--- Release resize state and capture. Called from multiple exit points.
function ZeD_Window:_stopResize()
    local mode = self._resizeMode
    self._resizing = false
    self._resizeYOnly = false
    self._resizeMode = nil
    self._growBoxWasDown = false
    self:setCapture(false)
    -- the handle stays lit while the pointer is still on that edge, and goes when it leaves
    if mode then self._rzZone = mode; self._rzSince = getTimestampMs() - REST_MS end
end

-- one step of the drag, from where the pointer is now; the minimums hold (Java's setWidth
-- clamps to minimumWidth too, and onResize runs after update and clamps again)
function ZeD_Window:_resizeStep()
    local T = ZeD.T
    local mode = self._resizeMode or "se"
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local mx, my = getMouseX(), getMouseY()
    local minW = self.minimumWidth or T.px(200)
    local minH = self.minimumHeight or T.px(120)
    if mode == "s" or mode == "se" or mode == "sw" then
        local newH = math.max(my - ay, minH)
        newH = math.min(newH, getCore():getScreenHeight() - self:getY())
        if newH ~= self:getHeight() then self:setHeight(newH) end
    end
    if mode == "se" or mode == "e" then
        local newW = math.max(mx - ax, minW)
        if newW ~= self:getWidth() then self:setWidth(newW) end
    elseif mode == "sw" or mode == "w" then
        local right = self._resizeRight or (self:getX() + self:getWidth())
        local mxp = mx - (ax - self:getX())   -- (the pointer in the coordinates the window's x is in)
        local newW = math.min(math.max(right - mxp, minW), right)
        if newW ~= self:getWidth() then self:setWidth(newW) end
        local nx = right - self:getWidth()
        if nx ~= self:getX() then self:setX(nx) end
    end
    -- Java anchor system propagates to children automatically.
end

-- the zone under the pointer, the rest before its handle shows, and a press that starts a drag
function ZeD_Window:_updateResize(down, fresh, mx, my)
    if not self.resizable or self.windowShaded or self.isCollapsed then
        if self._resizing then self:_stopResize() end
        self._rzLit, self._rzZone = nil, nil
        return
    end
    if self._resizing then
        -- Safety release: PZ's capture system can miss onMouseUp
        if down then
            self:_resizeStep()
            self._rzLit = self._resizeMode
            return
        end
        self:_stopResize()
    end
    local zone = self:pointerOn() and self:_resizeZoneAt(mx, my) or nil
    -- a fresh press (a button already held when the pointer arrived never starts one)
    if fresh and zone then
        local start = self:_resizeStartZone(mx, my)   -- (a side edge: lit last frame, before the press)
        if start then
            self:_startResize(start)
            self._rzLit = start
            return
        end
    end
    local now = getTimestampMs()
    if zone ~= self._rzZone then self._rzZone = zone; self._rzSince = now end
    if down then self._rzSince = now end   -- (only a rest with no button down shows a handle)
    self._rzLit = (zone and now - (self._rzSince or now) >= REST_MS) and zone or nil
end

function ZeD_Window:onMouseDown(x, y)
    if not self:getIsVisible() then return end

    -- If update() already claimed this click for resize, don't also start a drag
    if self._resizing then return true end

    -- An edge or a corner: start the resize here too (belt-and-suspenders with update(),
    -- since some child panels eat events)
    local start = self:_resizeStartZone(x, y)
    if start then
        self:_startResize(start)
        return true
    end

    -- the window box answers on release (update): a press on it neither drags the window
    -- nor counts towards a double-click
    local box = self:windowBoxRect()
    if box and x >= box.x and x < box.x + box.w and y >= box.y and y < box.y + box.h then return true end

    local tbH = self:titleBarHeight()
    if y < tbH and y > 0 then
        -- WindowShade: double-click title bar to collapse/expand.
        -- Use getTimestampMs() which is available everywhere in PZ.
        local now = getTimestampMs()
        if self._lastTitleClick and (now - self._lastTitleClick) < 500 then
            -- Double-click detected — toggle WindowShade via the public method
            -- (S95: shared with FocusManager's windowshade-on-stick path).
            self:setWindowShaded(not self.windowShaded)
            self._lastTitleClick = nil  -- reset so triple-click doesn't re-trigger
            self.moving = false
            return true
        end
        self._lastTitleClick = now
    end

    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
    return true
end

function ZeD_Window:onMouseMove(dx, dy)
    if self._resizing then
        -- Safety: if mouse button released but we missed onMouseUp
        if not isMouseButtonDown(0) then
            self:_stopResize()
            return
        end
        self:_resizeStep()
        return
    end
    -- Inline drag (replaces ISCollapsableWindow super-call)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function ZeD_Window:onMouseMoveOutside(dx, dy)
    if self._resizing then
        self:onMouseMove(dx, dy)
        return
    end
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function ZeD_Window:onMouseUp(x, y)
    if self._resizing then
        self:_stopResize()
        return true
    end
    self.moving = false
end

function ZeD_Window:onMouseUpOutside(x, y)
    if self._resizing then
        self:_stopResize()
        return true
    end
    self.moving = false
end

-- ---------------------------------------------------------------------------
-- Reset the windows to the default page-spread layout: "Reset this window"
-- and "Reset both windows" in the window menu, the Select wheel's Reset
-- windows (and the QA scripts). which: "char", "world", or nil for both. A
-- rolled side (WindowCurtain) comes back down first, so the reset starts
-- from the whole window.
-- ---------------------------------------------------------------------------
local function resetChar(charWin, defW, defH, gap, screenW)
    local S = ZeD.Settings
    local T = ZeD.T
    charWin.minimumWidth = defW  -- reset before setWidth (stale min from open drawer)
    charWin:setWidth(defW)
    charWin:setHeight(defH)
    charWin:setX(math.floor(screenW / 2) - defW - gap)
    charWin:setY(0)
    charWin._anchorRightEdge = charWin:getX() + defW
    charWin._lastSetX = charWin:getX()
    charWin._preDrawerW = nil
    -- Reset saved settings: tab, drawer, accent
    charWin._activeTab = "loot"
    charWin._drawerOpen = false
    charWin._drawerEffW = 0
    charWin._prevEffW   = 0
    charWin._drawerMode = nil
    charWin._accentKey = nil
    if S then S.syncWindowAccent(charWin) end   -- the option, the next open and the saved copy follow
    -- Reset inventory drawer state (S78 two-drawer)
    charWin._invDrawerOpen    = true
    charWin._invDrawerEffW    = defW - T.px(36) - T.px(36)  -- invW = defW minus strips
    charWin._invDrawerTargetW = defW - T.px(36) - T.px(36)
    charWin._prevDesiredW     = nil
    charWin._baseInvW         = (defW - T.px(36) - T.px(36)) / (T.scale or 1)  -- S124 scale: _baseInvW is stored in design units (the window files T.px it at use)
    -- Clear MC
    charWin._mcSelected = {}
    charWin._mcColStates = {}
    charWin._mainVisible = true
    -- Clear persisted state so defaults apply on next load
    if charWin._playerObj then
        local md = charWin._playerObj:getModData()
        if md.ZeD_WinState then md.ZeD_WinState.char = nil end
    end
end

local function resetWorld(worldWin, defW, defH, gap, screenW)
    local S = ZeD.Settings
    local T = ZeD.T
    worldWin.minimumWidth = defW  -- reset before setWidth (stale min from open drawer)
    worldWin:setWidth(defW)
    worldWin:setHeight(defH)
    worldWin:setX(math.floor(screenW / 2) + gap)
    worldWin:setY(0)
    worldWin._anchorRightEdge = worldWin:getX() + defW
    worldWin._lastSetX = worldWin:getX()
    worldWin._preDrawerW = nil
    worldWin._drawerOpen = false
    worldWin._drawerEffW = 0
    worldWin._prevEffW   = 0
    worldWin._drawerMode = nil
    worldWin._accentKey = nil
    if S then S.syncWindowAccent(worldWin) end
    -- Reset inventory drawer state (S78 two-drawer)
    worldWin._invDrawerOpen    = true
    worldWin._invDrawerEffW    = defW - T.px(36) - T.px(36)  -- invW = defW minus strips
    worldWin._invDrawerTargetW = defW - T.px(36) - T.px(36)
    worldWin._prevDesiredW     = nil
    worldWin._baseInvW         = (defW - T.px(36) - T.px(36)) / (T.scale or 1)  -- S124 scale: design units, as above
    -- Clear MC
    worldWin._mcSelected = {}
    worldWin._mainVisible = true
    -- Clear persisted state
    if worldWin._playerObj then
        local md = worldWin._playerObj:getModData()
        if md.ZeD_WinState then md.ZeD_WinState.world = nil end
    end
end

function ZeD_Window.resetLayout(which)
    local T = ZeD.T
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local defW = math.min(T.px(444), math.floor(screenW * 0.5))   -- 36 + 372 + 36 design units, as a fresh open
    local defH = math.min(T.px(420), screenH - T.px(80))
    local gap = T.px(5)  -- 5px each side = 10px total gap

    -- Position as page spread: character left, world right
    local charWin = (which ~= "world") and ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow() or nil
    local worldWin = (which ~= "char") and ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow() or nil
    for _, w in ipairs({ charWin or false, worldWin or false }) do
        if w and w._rolled and ZeD.Curtain and ZeD.Curtain.finishUnroll then ZeD.Curtain.finishUnroll(w) end
    end
    if charWin then resetChar(charWin, defW, defH, gap, screenW) end
    if worldWin then resetWorld(worldWin, defW, defH, gap, screenW) end
end

-- "char" or "world" for the Character / World pair, nil for any other window
function ZeD_Window:pairKey()
    local cw = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    if cw == self then return "char" end
    local ww = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    if ww == self then return "world" end
    return nil
end

-- "Reset this window": the Character or World window to its place in the default spread;
-- any other window back to where it first opened, at the size it opened at
function ZeD_Window:resetWindow()
    local k = self:pairKey()
    if k then ZeD_Window.resetLayout(k); return end
    if self.windowShaded then self:setWindowShaded(false) end
    local home = self._zedHome
    if not home then return end
    if self.resizable then
        self:setWidth(home.w)
        self:setHeight(home.h)
    end
    self:setX(home.x)
    self:setY(home.y)
end

-- the window menu under the window box (ZeD_WindowMenu.lua)
function ZeD_Window:openWindowMenu()
    local WM = ZeD.WindowMenu
    if not (WM and WM.open) then return end
    local ok, err = pcall(WM.open, self)
    if not ok then ZeD.logOnce("ZeD window menu", err) end
end

-- ---------------------------------------------------------------------------
-- The close box, the window box and the resize edges answer the raw mouse in
-- update(), with absolute coordinates: child panels can't eat these clicks.
-- (WHAT_CODE_DID.md quirk #1)
-- ---------------------------------------------------------------------------
-- No window above this one holds the pointer: the engine's own picking, as for a click.
-- (The main menu's windows answer for themselves: the desk's glass lies over them, ZeD_MMWindow)
function ZeD_Window:pointerOn() return self:isMouseOver() end

-- The close box and the window box. These controls poll the raw mouse, so each one has to
-- tell a press that began on it from a button that was already down when the pointer
-- arrived (a drag released over the close box) and from a press that landed on another
-- window drawn above this one: they arm on the frame the button went down only, while
-- pointerOn says no window above holds the pointer. The engine runs update() only every
-- 100 ms (its UI tick, 42.22), so a quick click could fall between two updates and the box
-- missed it (Oct 30 2026, the director's mouse pass): the boxes are watched on every frame
-- drawn too (_drawTop), and what a release on them asks for waits in _boxDo for update(),
-- so a window never closes and a menu never opens in the middle of a draw.
function ZeD_Window:_watchBoxes()
    local down = isMouseButtonDown(0)
    local fresh = down and not self._boxPrevDown
    self._boxPrevDown = down
    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()

    -- Close box hit-testing (absolute coords, same pattern as grow box)
    if self._closeBtnRect and not self._closeOnRod then
        local cb = self:closeRect()
        local inside = mx >= cb.x and mx <= cb.x + cb.w and my >= cb.y and my <= cb.y + cb.h
        if inside and not self:pointerOn() then inside = false end
        self._closeHover = inside
        if down then
            if fresh and inside then self._closeWasDown = true end
        elseif self._closeWasDown then
            self._closeWasDown = false
            if inside then self._boxDo = "close" end
        end
    end

    -- The window box: a press and release on it pulls its menu down
    local box = self:windowBoxRect()
    if box then
        local inside = mx >= box.x and mx < box.x + box.w and my >= box.y and my < box.y + box.h
        if inside and not self:pointerOn() then inside = false end
        self._wboxHover = inside
        if down then
            if fresh and inside then self._wboxWasDown = true end
        elseif self._wboxWasDown then
            self._wboxWasDown = false
            if inside then self._boxDo = "menu" end
        end
    else
        self._wboxHover = false
    end
end

function ZeD_Window:update()
    ISPanel.update(self)
    self._updHelp = nil   -- (the help line stamps it on each frame drawn: _drawHelpLine)

    self:_watchBoxes()
    local act = self._boxDo
    self._boxDo = nil
    if act == "close" then
        -- a window whose close means something of its own (a prompt's close is its No)
        -- says so in closeAction; any other window just closes
        if self.closeAction then self:closeAction() else self:close() end
        return
    elseif act == "menu" then
        self:openWindowMenu()
    end

    -- The resize edges and corners (resizable windows only): `fresh` is the update the
    -- button went down, as for the boxes
    local down = isMouseButtonDown(0)
    local fresh = down and not self._uiPrevDown
    self._uiPrevDown = down
    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    self:_updateResize(down, fresh, mx, my)
end

function ZeD_Window:setTitleStats(stats)
    self.titleStats = stats or {}
end

function ZeD_Window:getBodyY()
    return self:titleBarHeight()
end

function ZeD_Window:getBodyHeight()
    return self.height - self:titleBarHeight() - self:footerHeight()
end

function ZeD_Window:close()
    self:setVisible(false)
end

-- ============================================================================
-- JOYPAD DISPATCH (S93 — Layer 3 plumbing shims)
-- ============================================================================
-- ZeD_Window derives from ISPanel directly (NOT from ZeD_Panel), so it needs
-- its own copy of the joypad stubs — inheritance from ZeD_Panel's stubs
-- doesn't reach here. See PZAPI-KB Q80 on duck-typed joypad dispatch:
-- the engine calls these method names on whatever joypadData.focus points
-- at, without requiring ISPanelJoypad inheritance.
--
-- Each stub gates on "is this window the focused one per FocusManager?"
-- and delegates to the central dispatcher. Focus.dispatchJoypad* is a no-op
-- in S93 — button presses are silently swallowed while a ZeD window has
-- focus. S94 fills in real button translation + focus-stack routing.
-- ============================================================================

function ZeD_Window:onJoypadDown(button, joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDown(self, button, joypadData)
    end
end

function ZeD_Window:onJoypadDirUp(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "up", joypadData)
    end
end

function ZeD_Window:onJoypadDirDown(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "down", joypadData)
    end
end

function ZeD_Window:onJoypadDirLeft(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "left", joypadData)
    end
end

function ZeD_Window:onJoypadDirRight(joypadData)
    if ZeD and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        ZeD.Input.Focus.dispatchJoypadDir(self, "right", joypadData)
    end
end


-- ============================================================================
-- O2: SCROLLABLE LIST
-- ============================================================================
-- Derives from ISPanel (NOT ISScrollingListBox) to avoid vanilla scrollbar.
-- Uses ZeD_ScrollbarState as a plain Lua state table for scrolling.
-- All mouse interaction uses absolute coordinates via update().
-- (WHAT_CODE_DID.md quirks #1, #2, #3)
-- ============================================================================

ZeD_ScrollList = ISPanel:derive("ZeD_ScrollList")

function ZeD_ScrollList:new(x, y, width, height, selectionMode)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    local T = ZeD.T
    o.backgroundColor = {r = T.surf1.r, g = T.surf1.g, b = T.surf1.b, a = T.surf1.a}
    o.borderColor     = {r = T.borderS.r, g = T.borderS.g, b = T.borderS.b, a = T.borderS.a}

    -- Item storage: each entry is {text=, item=} matching ISScrollingListBox
    o.items           = {}
    o.itemheight      = T.rowH
    o.font            = T.fontF2
    o.selected        = 0       -- 1-based index of selected item
    o.hoveredIndex    = 0       -- 1-based index of hovered item
    o.selectionMode   = selectionMode or "single"  -- "single" or "none"

    -- Scrollbar: plain Lua state table, NOT an ISPanel child
    o.sb = ZeD_ScrollbarState:new()
    o.sb.width = T.sp.scrollbarW
    o.sb.visible = false
    -- reserveBottom = 0 because the list panel already stops above the
    -- grow box area (ZeD_Window:getBodyHeight subtracts resizeWidgetHeight).
    -- The grow box is drawn by the window, not by the list.
    o.sb.reserveBottom = 0
    o.scrollPixels = 0

    -- Wire scrollbar callback
    o.sb.onScroll = function(pos)
        local totalH = #o.items * o.itemheight
        local maxScroll = math.max(0, totalH - o.height)
        o.scrollPixels = math.floor(pos * maxScroll)
    end

    return o
end

--- Add an item to the list. Matches ISScrollingListBox:addItem() signature.
-- @param text  Display text
-- @param item  Arbitrary data table (or string for meta text)
function ZeD_ScrollList:addItem(text, item)
    table.insert(self.items, {text = text, item = item})
end

function ZeD_ScrollList:clear()
    self.items = {}
    self.selected = 0
    self.scrollPixels = 0
    self.sb:setScrollPos(0)
end

function ZeD_ScrollList:getSelectedIndex()
    return self.selected
end

function ZeD_ScrollList:getSelectedItem()
    if self.selected > 0 and self.selected <= #self.items then
        return self.items[self.selected]
    end
    return nil
end

function ZeD_ScrollList:prerender()
    local T = ZeD.T
    ZeD.colorSync(self.backgroundColor, T.surf1)
    ZeD.colorSync(self.borderColor, T.borderS)
    self.itemheight      = T.rowH
    self.font            = T.fontF2
    -- Keep scrollbar dimensions in sync with theme
    self.sb.width        = T.sp.scrollbarW
    self.sb.arrowH       = T.sp.scrollbarW
    ISPanel.prerender(self)
end

function ZeD_ScrollList:render()
    local w = self:getWidth()
    local h = self:getHeight()
    local rowH = self.itemheight
    local totalH = #self.items * rowH
    local needsScroll = totalH > h

    -- Update scrollbar geometry
    self.sb.visible = needsScroll
    if needsScroll then
        self.sb.x = w - self.sb.width
        self.sb.y = 0
        self.sb.height = h
        self.sb:setBarSize(h / totalH)
    end

    local contentW = needsScroll and (w - self.sb.width) or w

    -- Clamp scroll
    local maxScroll = math.max(0, totalH - h)
    if self.scrollPixels > maxScroll then self.scrollPixels = maxScroll end
    if self.scrollPixels < 0 then self.scrollPixels = 0 end

    -- Stencil clipping — prevents rows from drawing outside panel bounds.
    -- This is how vanilla ISScrollingListBox does it.
    self:setStencilRect(0, 0, contentW, h)

    -- Determine visible range
    local firstVisible = math.floor(self.scrollPixels / rowH) + 1
    local lastVisible = math.min(#self.items, firstVisible + math.ceil(h / rowH) + 1)

    -- Draw visible items
    for i = firstVisible, lastVisible do
        local entry = self.items[i]
        if entry then
            local drawY = (i - 1) * rowH - self.scrollPixels
            self:drawListItem(drawY, i, entry, contentW)
        end
    end

    self:clearStencilRect()

    -- Draw scrollbar (outside stencil so it's never clipped)
    if needsScroll then
        self.sb:draw(self)
    end
end

--- Draw a single list item row. Override this for custom row rendering.
function ZeD_ScrollList:drawListItem(y, index, entry, contentW)
    local T = ZeD.T
    local h = self.itemheight

    -- Selection / hover background
    if index == self.selected then
        self:drawRect(0, y, contentW, h, T.selectionA, T.accent.r, T.accent.g, T.accent.b)
    elseif index == self.hoveredIndex then
        self:drawRect(0, y, contentW, h, T.hover.a, T.hover.r, T.hover.g, T.hover.b)
    end

    -- Groove divider between rows (skip first)
    if index > 1 then
        ZeD.Atoms.drawGroove(self, 0, y, contentW)
    end

    local textX = T.sp.md
    local item = entry.item

    -- Disclosure triangle for expandable items
    if item and type(item) == "table" and item.expandable then
        local triY = y + math.floor((h - T.px(8)) / 2)
        local triColor = T.arrow
        local A = ZeD.Atoms
        if item.expanded and A.drawTriangleDown then
            A.drawTriangleDown(self, textX, triY, T.px(8), triColor)
        elseif A.drawTriangleRight then
            A.drawTriangleRight(self, textX, triY, T.px(8), triColor)
        end
        textX = textX + T.px(12)
    end

    -- Icon (tinted to match text color — accent on selected, theme text otherwise)
    if item and type(item) == "table" and item.icon then
        local iconSz = T.iconSm
        local iconY = y + math.floor((h - iconSz) / 2)
        local ic = (index == self.selected) and T.accentText or T.text
        self:drawTextureScaledAspect(item.icon, textX, iconY, iconSz, iconSz, ic.a or 1, ic.r, ic.g, ic.b)
        textX = textX + iconSz + (T.sp.sm)
    end

    -- Primary text
    local textColor = (item and type(item) == "table" and item.textColor) or T.text
    if index == self.selected then textColor = T.accentText end
    local textY = y + math.floor((h - ZeD.TM:getFontHeight(self.font)) / 2)
    self:drawText(entry.text or "", textX, textY,
        textColor.r, textColor.g, textColor.b, textColor.a or 1, self.font)

    -- Meta text (right-aligned) — supports both string item and table.meta
    local meta = nil
    if type(item) == "string" then
        meta = item  -- simple string meta (used by gallery addItem(text, meta))
    elseif type(item) == "table" and item.meta then
        meta = item.meta
    end
    if meta then
        local metaColor = (item and type(item) == "table" and item.metaColor) or T.textSec
        local metaW = ZeD.TM:MeasureStringX(T.fontF1, meta)
        local metaX = contentW - metaW - (T.sp.md)
        local metaY = y + math.floor((h - ZeD.TM:getFontHeight(T.fontF1)) / 2)
        self:drawText(meta, metaX, metaY,
            metaColor.r, metaColor.g, metaColor.b, metaColor.a or 1, T.fontF1)
    end
end

-- ---------------------------------------------------------------------------
-- INPUT: absolute coordinate hit testing via update()
-- ---------------------------------------------------------------------------
function ZeD_ScrollList:update()
    ISPanel.update(self)

    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    local inPanel = mx >= 0 and mx < self.width and my >= 0 and my < self.height

    -- Hover detection for rows
    if inPanel and (not self.sb.visible or mx < self.sb.x) then
        local rowIndex = math.floor((my + self.scrollPixels) / self.itemheight) + 1
        if rowIndex >= 1 and rowIndex <= #self.items then
            self.hoveredIndex = rowIndex
        else
            self.hoveredIndex = 0
        end
    else
        self.hoveredIndex = 0
    end

    -- Scrollbar hover/drag
    if self.sb.visible then
        local inSb = inPanel and mx >= self.sb.x
        if inSb then
            self.sb:handleMouseMove(my - self.sb.y)
        else
            self.sb.upHover = false
            self.sb.downHover = false
            self.sb.thumbHover = false
        end
        if self.sb.dragging then
            self.sb:handleMouseMove(my - self.sb.y)
        end
    end
end

function ZeD_ScrollList:onMouseWheel(del)
    if self.sb.visible then
        self.sb:handleMouseWheel(del)
        return true
    end
    return false
end

function ZeD_ScrollList:onMouseDown(x, y)
    -- Scrollbar click
    if self.sb.visible and x >= self.sb.x then
        self.sb:handleMouseDown(y - self.sb.y)
        return true
    end

    -- Row click for selection
    if self.selectionMode == "single" then
        local rowIndex = math.floor((y + self.scrollPixels) / self.itemheight) + 1
        if rowIndex >= 1 and rowIndex <= #self.items then
            self.selected = rowIndex
        end
    end
    return true
end

function ZeD_ScrollList:onMouseUp(x, y)
    self.sb:handleMouseUp()
end

function ZeD_ScrollList:onMouseUpOutside(x, y)
    self.sb:handleMouseUp()
end


-- ============================================================================
-- O3: TAB PANEL
-- ============================================================================

ZeD_TabPanel = ISPanel:derive("ZeD_TabPanel")

function ZeD_TabPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    local T = ZeD.T
    o.backgroundColor = {r = T.surf1.r, g = T.surf1.g, b = T.surf1.b, a = T.surf1.a}
    o.borderColor     = {r = T.borderS.r, g = T.borderS.g, b = T.borderS.b, a = T.borderS.a}
    o.tabs = {}
    o.activeIndex = 1
    o.tabHeight = T.tabH
    o.tabPadH = T.sp.md
    o.tabGap = T.sp.tabGap

    return o
end

function ZeD_TabPanel:addTab(name, panel)
    table.insert(self.tabs, {name = name, panel = panel})
    panel:setX(0)
    panel:setY(self.tabHeight)
    panel:setWidth(self.width)
    panel:setHeight(self.height - self.tabHeight)
    panel.anchorLeft   = true
    panel.anchorRight  = true
    panel.anchorTop    = true
    panel.anchorBottom = true
    self:addChild(panel)
    panel:setVisible(#self.tabs == self.activeIndex)
end

function ZeD_TabPanel:activateTab(index)
    if index < 1 or index > #self.tabs then return end
    self.activeIndex = index
    for i, tab in ipairs(self.tabs) do
        tab.panel:setVisible(i == index)
    end
end

--- Propagate size changes to tab content panels.
-- Called every frame in prerender to keep children in sync.
function ZeD_TabPanel:resizeChildren()
    local contentW = self:getWidth()
    local contentH = self:getHeight() - self.tabHeight
    for _, tab in ipairs(self.tabs) do
        tab.panel:setWidth(contentW)
        tab.panel:setHeight(contentH)
    end
end

function ZeD_TabPanel:onMouseDown(x, y)
    if y > self.tabHeight then return end
    local T = ZeD.T
    local tabX = T.sp.sm
    for i, tab in ipairs(self.tabs) do
        local tw = ZeD.TM:MeasureStringX(T.fontF5, tab.name) + self.tabPadH * 2
        if x >= tabX and x <= tabX + tw then
            self:activateTab(i)
            return
        end
        tabX = tabX + tw + self.tabGap
    end
end

function ZeD_TabPanel:prerender()
    local T = ZeD.T
    ZeD.colorSync(self.backgroundColor, T.surf1)
    ZeD.colorSync(self.borderColor, T.borderS)
    self.tabHeight       = T.tabH
    self.tabPadH         = T.sp.md
    self.tabGap          = T.sp.tabGap
    ISPanel.prerender(self)

    -- Keep tab content panels in sync with our size
    self:resizeChildren()

    local w = self:getWidth()
    local h = self:getHeight()
    local tH = self.tabHeight
    local bc = T.borderS

    -- Tab strip background
    ZeD.Molecules.drawBodyBg(self, 0, 0, w, tH, "surf2")

    -- Content area border: left, right, bottom edges
    -- (top edge of content is the tab strip bottom line)
    self:drawRect(0, tH - T.px(1), w, T.px(1), bc.a, bc.r, bc.g, bc.b)       -- top of content
    self:drawRect(0, tH, T.px(1), h - tH, bc.a, bc.r, bc.g, bc.b)       -- left edge
    self:drawRect(w - T.px(1), tH, T.px(1), h - tH, bc.a, bc.r, bc.g, bc.b)   -- right edge
    self:drawRect(0, h - T.px(1), w, T.px(1), bc.a, bc.r, bc.g, bc.b)          -- bottom edge

    -- Tab strip left/right borders (above the content area)
    self:drawRect(0, 0, T.px(1), tH, bc.a, bc.r, bc.g, bc.b)             -- left
    self:drawRect(w - T.px(1), 0, T.px(1), tH, bc.a, bc.r, bc.g, bc.b)         -- right

    local tabX = T.sp.sm
    for i, tab in ipairs(self.tabs) do
        local tw = ZeD.TM:MeasureStringX(T.fontF5, tab.name) + self.tabPadH * 2
        local isActive = (i == self.activeIndex)

        if isActive then
            -- Active tab: filled with content bg, open bottom (connects to content)
            self:drawRect(tabX, 0, tw, tH, T.surf1.a, T.surf1.r, T.surf1.g, T.surf1.b)
            self:drawRect(tabX, 0, tw, T.px(1), bc.a, bc.r, bc.g, bc.b)          -- top
            self:drawRect(tabX, 0, T.px(1), tH, bc.a, bc.r, bc.g, bc.b)          -- left
            self:drawRect(tabX + tw - T.px(1), 0, T.px(1), tH, bc.a, bc.r, bc.g, bc.b) -- right
            -- Erase the content area top border behind the active tab (open bottom)
            self:drawRect(tabX + T.px(1), tH - T.px(1), tw - T.px(1) * 2, T.px(1), T.surf1.a, T.surf1.r, T.surf1.g, T.surf1.b)

            local textY = math.floor((tH - ZeD.TM:getFontHeight(T.fontF5)) / 2)
            self:drawText(tab.name, tabX + self.tabPadH, textY, T.accent.r, T.accent.g, T.accent.b, 1, T.fontF5)
        else
            local textY = math.floor((tH - ZeD.TM:getFontHeight(T.fontF5)) / 2)
            local c = T.textSec
            self:drawText(tab.name, tabX + self.tabPadH, textY, c.r, c.g, c.b, c.a, T.fontF5)
        end

        tabX = tabX + tw + self.tabGap
    end
end


-- ============================================================================
-- O4: ITEM GRID
-- ============================================================================

ZeD_ItemGrid = ISPanel:derive("ZeD_ItemGrid")

function ZeD_ItemGrid:new(x, y, width, height, columns)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    local T = ZeD.T
    o.backgroundColor = {r = T.surf1.r, g = T.surf1.g, b = T.surf1.b, a = T.surf1.a}
    o.borderColor     = {r = T.borderS.r, g = T.borderS.g, b = T.borderS.b, a = T.borderS.a}
    o.columns   = columns or 5
    o.cellGap   = T.sp.gridCellGap
    o.cellPad   = T.sp.gridCellPad
    o.items     = {}
    o.totalSlots = 20
    o.selectedIndex = 0

    return o
end

function ZeD_ItemGrid:setItems(items, totalSlots)
    self.items = items or {}
    self.totalSlots = totalSlots or #self.items
end

function ZeD_ItemGrid:prerender()
    local T = ZeD.T
    ZeD.colorSync(self.backgroundColor, T.surf1)
    ZeD.colorSync(self.borderColor, T.borderS)
    self.cellGap = T.sp.gridCellGap
    self.cellPad = T.sp.gridCellPad
    ISPanel.prerender(self)
end

function ZeD_ItemGrid:render()
    local T = ZeD.T
    local gap  = self.cellGap
    local pad  = self.cellPad
    local availW = self.width - pad * 2
    local availH = self.height - pad * 2
    local targetCell = self.targetCellSize or T.px(48)

    -- Auto-calculate columns from available width and target cell size
    local cols = math.max(1, math.floor((availW + gap) / (targetCell + gap)))
    local cellW = math.floor((availW - (cols - 1) * gap) / cols)

    -- Constrain cell height so all rows fit vertically
    local slotCount = math.max(self.totalSlots, #self.items)
    local rows = math.ceil(slotCount / cols)
    local maxCellH = rows > 0 and math.floor((availH - (rows - 1) * gap) / rows) or cellW
    local cellH = math.min(cellW, maxCellH)

    for i = 1, slotCount do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = pad + col * (cellW + gap)
        local cy = pad + row * (cellH + gap)

        local item = self.items[i]
        local isSelected = (i == self.selectedIndex)

        if isSelected then
            self:drawRect(cx, cy, cellW, cellH, T.hover.a, T.hover.r, T.hover.g, T.hover.b)
        else
            self:drawRect(cx, cy, cellW, cellH, T.surf2.a, T.surf2.r, T.surf2.g, T.surf2.b)
        end

        local bc = isSelected and T.accent or T.border
        self:drawRectBorder(cx, cy, cellW, cellH, bc.a, bc.r, bc.g, bc.b)

        if item then
            if item.icon then
                local iconMargin = math.floor(cellW * 0.15)
                local iconSz = cellW - iconMargin * 2
                self:drawTextureScaledAspect(item.icon, cx + iconMargin, cy + iconMargin, iconSz, iconSz, 1, 1, 1, 1)
            else
                local phM = math.floor(cellW * 0.2)
                local phSz = cellW - phM * 2
                self:drawRect(cx + phM, cy + phM, phSz, phSz, 0.3, T.surf4.r, T.surf4.g, T.surf4.b)
                self:drawRectBorder(cx + phM, cy + phM, phSz, phSz, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
            end

            if item.count and item.count > 1 then
                local countStr = tostring(item.count)
                local countW = ZeD.TM:MeasureStringX(T.fontF3, countStr)
                local countX = cx + cellW - countW - T.px(3)
                local countY = cy + cellH - ZeD.TM:getFontHeight(T.fontF3) - T.px(2)
                self:drawText(countStr, countX, countY, T.textSec.r, T.textSec.g, T.textSec.b, T.textSec.a, T.fontF3)
            end

            if item.condition then
                local barW = cellW - T.px(2) * 2
                local barH = T.px(3)
                local barX = cx + T.px(2)
                local barY = cy + cellH - barH - T.px(2)
                local fillW = math.floor(barW * item.condition)

                local barColor
                if item.condition > 0.6 then
                    barColor = T.positive
                elseif item.condition > 0.25 then
                    barColor = T.warning
                else
                    barColor = T.danger
                end
                self:drawRect(barX, barY, fillW, barH, 1, barColor.r, barColor.g, barColor.b)
            end
        end
    end
end


-- ============================================================================
-- O5: MODAL DIALOG
-- ============================================================================

ZeD_Modal = ISPanel:derive("ZeD_Modal")

function ZeD_Modal.show(message, confirmText, cancelText, onConfirm, onCancel, flavor)
    flavor = flavor or "confirm"
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local overlay = ZeD_Modal:new(0, 0, screenW, screenH)
    overlay.message     = message
    overlay.confirmText = confirmText or ZeD.upper(ZeD.tr("UI_Ok"))
    overlay.cancelText  = cancelText or ZeD.tr("UI_Cancel")
    overlay.onConfirm   = onConfirm
    overlay.onCancel    = onCancel
    overlay.flavor      = flavor
    overlay:initialise()
    overlay:addToUIManager()
    overlay:bringToTop()
    overlay.alwaysOnTop = true
    return overlay
end

function ZeD_Modal:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0}
    o.borderColor     = {r = 0, g = 0, b = 0, a = 0}
    o.message     = ""
    o.confirmText = ZeD.upper(ZeD.tr("UI_Ok"))
    o.cancelText  = ZeD.tr("UI_Cancel")
    o.onConfirm   = nil
    o.onCancel    = nil
    o.flavor      = "confirm"
    o.modalW = ZeD.T.modalW
    o.modalH = ZeD.T.modalH
    return o
end

function ZeD_Modal:createChildren() end

function ZeD_Modal:prerender()
    local T = ZeD.T
    self.modalW = T.modalW
    self.modalH = T.modalH
    self:drawRect(0, 0, self.width, self.height, T.modalOverlayA, 0, 0, 0)

    local mx = math.floor((self.width - self.modalW) / 2)
    local my = math.floor((self.height - self.modalH) / 2)

    ZeD.Molecules.drawBodyBg(self, mx, my, self.modalW, self.modalH, "surf1")

    local tbH = T.titleBarH
    ZeD.Molecules.drawBodyBg(self, mx, my, self.modalW, tbH, "surf2")
    self:drawRect(mx, my + tbH - T.px(1), self.modalW, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)

    local titleText = ZeD.tr("UI_ZeD_Modal_Confirm")
    local titleColor = T.textHead
    if self.flavor == "warning" then
        titleText = ZeD.tr("UI_ZeD_Modal_Warning")
        titleColor = T.warning
    elseif self.flavor == "danger" then
        titleText = ZeD.tr("UI_ZeD_Modal_Warning")
        titleColor = T.danger
    end
    local titleY = my + math.floor((tbH - ZeD.TM:getFontHeight(T.fontF4)) / 2)
    self:drawText(titleText, mx + (T.sp.md), titleY, titleColor.r, titleColor.g, titleColor.b, titleColor.a or 1, T.fontF4)

    local msgY = my + tbH + (T.sp.lg)
    self:drawText(self.message, mx + (T.sp.lg), msgY, T.text.r, T.text.g, T.text.b, T.text.a, T.fontF2)

    local btnH = T.buttonH
    local btnW = T.px(90)
    local btnGap = T.sp.md
    local btnY = my + self.modalH - btnH - (T.sp.md)
    local btnAreaW = btnW * 2 + btnGap
    local btnX = mx + self.modalW - btnAreaW - (T.sp.lg)

    -- Cancel button: default outline style
    ZeD.Molecules.drawButton(self, btnX, btnY, btnW, btnH, self.cancelText, "default")
    self._cancelRect = {x = btnX, y = btnY, w = btnW, h = btnH}

    -- Confirm/action button: primary or danger outline style
    local cbX = btnX + btnW + btnGap
    local actionVariant = (self.flavor == "danger") and "danger" or "primary"
    ZeD.Molecules.drawButton(self, cbX, btnY, btnW, btnH, self.confirmText, actionVariant)
    self._confirmRect = {x = cbX, y = btnY, w = btnW, h = btnH}

    self:drawRectBorder(mx, my, self.modalW, self.modalH, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
end

function ZeD_Modal:onMouseDown(x, y)
    if self._cancelRect then
        local r = self._cancelRect
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            if self.onCancel then self.onCancel() end
            self:removeFromUIManager()
            return
        end
    end
    if self._confirmRect then
        local r = self._confirmRect
        if x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h then
            if self.onConfirm then self.onConfirm() end
            self:removeFromUIManager()
            return
        end
    end
end

function ZeD_Modal:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then
        if self.onCancel then self.onCancel() end
        self:removeFromUIManager()
    end
end


-- ============================================================================
-- O6: CONTEXT MENU — REMOVED S88
-- ============================================================================
-- The original O6 was a small vertical dropdown used briefly in S25-S26 for
-- internal ZeD menus (theme picker, etc.). No callers remained by S87. The
-- ZeD_ContextMenu class name is now claimed by the unified strip menu organism
-- in its own file: 42/media/lua/client/ZeD/ZeD_ContextMenu.lua (S88).
-- See CONTEXT_MENU_SPEC.md for the new design.


-- ============================================================================
-- O7: SCROLL PANEL
-- ============================================================================
-- A scrollable content area driven by a custom draw callback.
-- Uses ZeD_ScrollbarState (plain Lua state table, not an ISPanel child)
-- to avoid PZ's broken nested-panel mouse event dispatch.
--
-- The parent panel owns all interaction via update() with absolute
-- screen coordinates — never relies on self:isMouseOver() or
-- self:getMouseX() for nested panels (PZ quirk #1 from WHAT_CODE_DID.md).
--
-- Your draw callback: onDrawContent(self, offsetY, contentWidth)
--   • offsetY is negative (scroll offset), add it to all y positions
--   • contentWidth excludes scrollbar when scrollbar is visible
--   • Return total content height so scrollbar knows the range
-- ============================================================================

ZeD_ScrollPanel = ISPanel:derive("ZeD_ScrollPanel")

function ZeD_ScrollPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    local T = ZeD.T
    o.backgroundColor = {r = T.surf1.r, g = T.surf1.g, b = T.surf1.b, a = T.surf1.a}
    o.borderColor     = {r = 0, g = 0, b = 0, a = 0}

    -- Scroll state
    o.contentHeight   = T.px(500)    -- total height of content (updated by onDrawContent return)
    o.scrollPixels    = 0      -- current scroll offset in pixels

    -- Scrollbar: plain Lua state table, NOT an ISPanel child.
    -- The parent (this panel) draws it and forwards mouse events manually.
    o.sb = ZeD_ScrollbarState:new()
    o.sb.width = T.sp.scrollbarW
    o.sb.visible = false
    -- reserveBottom = 0 because the scroll panel already stops above the
    -- grow box area (parent body height excludes it).
    o.sb.reserveBottom = 0

    -- Wire scrollbar callback to update our pixel offset
    o.sb.onScroll = function(pos)
        local maxScroll = math.max(0, o.contentHeight - o.height)
        o.scrollPixels = math.floor(pos * maxScroll)
    end

    -- Override this with your draw callback:
    -- function(self, offsetY, contentWidth) ... return totalContentHeight end
    o.onDrawContent   = nil

    return o
end

function ZeD_ScrollPanel:prerender()
    local T = ZeD.T
    ZeD.colorSync(self.backgroundColor, T.surf1)
    -- borderColor stays transparent (set in new())
    -- Keep scrollbar dimensions in sync with theme
    self.sb.width        = T.sp.scrollbarW
    self.sb.arrowH       = T.sp.scrollbarW
    ISPanel.prerender(self)
end

function ZeD_ScrollPanel:render()
    local w = self:getWidth()
    local h = self:getHeight()
    local needsScroll = self.contentHeight > h

    -- Update scrollbar visibility and geometry
    self.sb.visible = needsScroll
    if needsScroll then
        self.sb.x = w - self.sb.width
        self.sb.y = 0
        self.sb.height = h
        self.sb:setBarSize(h / self.contentHeight)
    end

    local contentW = needsScroll and (w - self.sb.width) or w

    -- Clamp scroll
    local maxScroll = math.max(0, self.contentHeight - h)
    if self.scrollPixels > maxScroll then self.scrollPixels = maxScroll end
    if self.scrollPixels < 0 then self.scrollPixels = 0 end

    -- Stencil clipping — prevents content from drawing outside panel bounds
    self:setStencilRect(0, 0, contentW, h)

    -- Draw content via callback
    if self.onDrawContent then
        local returned = self.onDrawContent(self, -self.scrollPixels, contentW)
        if returned and returned > 0 then
            self.contentHeight = returned
        end
    end

    self:clearStencilRect()

    -- Draw scrollbar outside stencil so it's never clipped
    if needsScroll then
        self.sb:draw(self)
    end
end

-- ---------------------------------------------------------------------------
-- INPUT: Use update() with absolute screen coordinates for all mouse
-- interaction. This avoids PZ's broken nested-panel event dispatch.
-- (WHAT_CODE_DID.md quirk #1 and #3)
-- ---------------------------------------------------------------------------
function ZeD_ScrollPanel:update()
    ISPanel.update(self)
    if not self.sb.visible then return end

    -- Absolute coordinate hit testing
    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    local inPanel = mx >= 0 and mx < self.width and my >= 0 and my < self.height
    local inScrollbar = inPanel and mx >= self.sb.x

    -- Forward mouse position to scrollbar for hover states
    if inScrollbar then
        self.sb:handleMouseMove(my - self.sb.y)
    else
        -- Clear hover states when mouse leaves scrollbar
        self.sb.upHover = false
        self.sb.downHover = false
        self.sb.thumbHover = false
    end

    -- Handle drag continuation (even if mouse moves outside scrollbar)
    if self.sb.dragging then
        self.sb:handleMouseMove(my - self.sb.y)
    end
end

function ZeD_ScrollPanel:onMouseWheel(del)
    if not self.sb.visible then return false end
    -- PZ: positive del = scroll down
    self.sb:handleMouseWheel(del)
    return true  -- consume the event
end

function ZeD_ScrollPanel:onMouseDown(x, y)
    if not self.sb.visible then return false end

    -- Check if click is in scrollbar area
    if x >= self.sb.x then
        self.sb:handleMouseDown(y - self.sb.y)
        return true
    end
    return false
end

function ZeD_ScrollPanel:onMouseUp(x, y)
    self.sb:handleMouseUp()
end

function ZeD_ScrollPanel:onMouseUpOutside(x, y)
    self.sb:handleMouseUp()
end
