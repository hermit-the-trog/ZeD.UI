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

ZeD = ZeD or {}


-- ============================================================================
-- O1: WINDOW FRAME
-- ============================================================================
-- The universal shell. Every panel in the mod lives inside one of these.
-- System 6 striped title bar, left-aligned title, right stat cluster,
-- close box, integrated resize grip at scrollbar base.
-- WindowShade collapse on title bar double-click (System 7.1).
--
-- Derives from ISPanel. All chrome, drag, WindowShade, and resize are
-- implemented from scratch using ZeD atomics — no vanilla window baggage.
-- ============================================================================

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

    -- Footer bar (toggle buttons, same row as grow box)
    o.footerToggles       = false   -- enable toggle buttons in footer
    o.footerItem          = nil     -- InventoryItem for toggle state
    o.footerToggleHover   = nil     -- index of hovered toggle (1-3) or nil
    o.footerToggleWasDown = false   -- track mouse-down for click detection
    o.footerToggleRects   = {}     -- cached hit rects {x,y,w,h} in absolute coords

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

    -- Resize state (managed by onMouseDown/onMouseMove on the grow box area)
    self._resizing = false
    self._resizeDownX = 0
    self._resizeDownY = 0
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

-- Public WindowShade toggle. Collapses to title bar on true; expands to prior
-- height on false. Idempotent (no-op if already in target state). Shared by
-- the title-bar double-click path AND FocusManager's windowshade-on-stick
-- trigger (S95). Children are hidden/restored so content doesn't render
-- underneath the collapsed title bar.
function ZeD_Window:setWindowShaded(shaded)
    local T = ZeD.T
    if self.windowShaded == shaded then return end
    self.windowShaded = shaded
    local tbH = self:titleBarHeight()
    if shaded then
        self.preShadeHeight = self.height
        self:setHeight(tbH)
        local children = self:getChildren()
        if children then
            for _, child in pairs(children) do
                child._wasVisible = child:isVisible()
                child:setVisible(false)
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

function ZeD_Window:resizeWidgetHeight()
    -- Match scrollbar width so the grow box and scrollbar arrows are the
    -- same size. System 7.1: grow box sits at the intersection of both
    -- scrollbar tracks, same dimension as the arrow buttons.
    return ZeD.T.sp.scrollbarW
end

function ZeD_Window:footerHeight()
    if self.footerToggles then
        -- Footer sized to fit action strip buttons with comfortable vertical padding.
        local T = ZeD.T
        local btnSz = T.iconSm + T.px(4)
        return btnSz + T.sp.sm * 2 + T.px(2)
    end
    -- Theme controls footer: same height as grow box. A fixed-size window
    -- (the main menu's windows) can keep the footer with themeFooter = true.
    if self.resizable or self.themeFooter then
        return self:resizeWidgetHeight()
    end
    return 0
end

-- The frame draws under pcall (SafeMode.lua): a failure counts towards safe
-- mode's watchdog and is logged once, rather than throwing every frame
function ZeD_Window:prerender()
    ZeD.Safe.guard(self, ZeD_Window._drawFrame)
end

function ZeD_Window:render()
    if not ZeD.Safe.guard(self, ZeD_Window._drawFooter) then self:_restoreAccent() end
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

-- The palette a window with its own accent draws in, built once per base theme and
-- accent (both tables are fixed) rather than blended again every frame
local accentPalettes = {}
local function windowAccentPalette(baseKey, accentKey)
    local ck = baseKey .. "|" .. accentKey
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
    -- the readable text colours (accentText, toneHi/Lo, textSec, textDim, textOnAccent, textOnFocus,
    -- the status *Text variants) are solved against THIS palette's surfaces and accent
    ZeD.deriveReadable(p, baseKey)
    accentPalettes[ck] = p
    return p
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

    local w = self:getWidth()
    local h = self:getHeight()
    local tbH = self:titleBarHeight()

    -- Reactive minimums — follow text size changes
    self.minimumWidth = T.minWinW
    self.minimumHeight = T.minWinH

    -- Title bar (molecule draws bg, stripes, title, stats, bottom border)
    ZeD.Molecules.drawWindowTitleBar(self, 0, 0, w, self.title, self.titleStats)

    -- Close box (drawn on top of title bar)
    if self._closeBtnRect and not self._closeOnRod then   -- (a rolled-up side: the close box is on its rod, WindowCurtain)
        local cb = self:closeRect()
        ZeD.Atoms.drawCloseBox(self, cb.x, cb.y, cb.w, self._closeHover)
    end

    -- Body background (skip if shaded)
    if not self.isCollapsed and not self.windowShaded then
        ZeD.Molecules.drawBodyBg(self, 0, tbH, w, h - tbH, "surf1")
    end

    -- Outer border: when shaded, draw only around the title bar height
    local borderH = (self.isCollapsed or self.windowShaded) and tbH or h
    self:drawRectBorder(0, 0, w, borderH, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)

    -- S99 focus chrome v4 / S107 QA v6 / S108 QA v7: Scoped accent underline
    -- at the BOTTOM edge of the window. v6 placed it in prerender (below the
    -- title bar logically), but on resizable windows the surf2 footer fill in
    -- render() at line ~310 paints over y=h-rh..h every frame, hiding the
    -- focus line entirely. v7 moves the draw to the END of render() (after
    -- footer + grow box) so nothing can overdraw it. See ZeD_Window:render.
end

-- ============================================================================
-- S123: CAPABILITY-DRIVEN BUTTON PROMPTS
-- The footer legend is derived from the focused element's callbacks, never
-- hand-authored: A if onActivate, hold-A if onHoldActivate, X if
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
-- leftmost go first when the footer is narrow, so A, X and Y outlast them
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

function ZeD_Window:_drawFooter()
    if self.isCollapsed or self.windowShaded then return end

    local T = ZeD.T
    local A = ZeD.Atoms
    local M = ZeD.Molecules
    local sp = T.sp
    local w = self:getWidth()
    local h = self:getHeight()

    -- FOOTER ACTION STRIP — toggle buttons + optional grow box
    -- Suppressed when the hosted card renders its own action strip (v10 layout).
    local fH = self:footerHeight()
    if fH > 0 and self.footerToggles and self.footerItem and not self.cardOwnsActionStrip then
        local fY = h - fH

        -- Footer background — inset 1px so the window border wraps over it
        M.drawBodyBg(self, T.px(1), fY, w - T.px(1) * 2, fH - T.px(1), "surf2")

        -- Groove separator at footer top edge
        A.drawGroove(self, T.px(1), fY, w - T.px(1) * 2)

        -- Action strip — left-aligned, vertically centered below groove
        local grooveH = T.grooveH  -- groove = a dark and a light hairline
        local stripX = sp.sm
        local stripY = fY + grooveH + sp.sm
        self.footerToggleRects = M.drawActionStrip(
            self, stripX, stripY,
            ZeD.ActionStrip.TOGGLE_DEFS, self.footerItem, self.footerToggleHover
        )
    end

    -- Footer: theme controls + grow box (resizable windows; themeFooter keeps
    -- the controls on a fixed-size window, without the grow box; noResetControl
    -- drops R where there are no Character / World windows to reset)
    if self.resizable or self.themeFooter then
        local rh = self:resizeWidgetHeight()
        local fY = h - rh
        local bs = T.borderS
        local hoverIdx = self._themeControlHover
        self._themeControlRects = {}

        -- Footer bar background + top divider
        local s2 = T.surf2
        self:drawRect(T.px(1), fY, w - T.px(1) * 2, rh, s2.a, s2.r, s2.g, s2.b)
        A.drawDividerH(self, T.px(1), fY, w - T.px(1) * 2, false)

        -- Button style matches grow box: surf2 bg, borderS border, same size
        local btnX = 0
        local btnGap = T.px(4)

        -- 1. Theme dot: next theme's preview color
        local nextC
        if ZeD.currentBase == "dark" then
            nextC = {r=0.75, g=0.75, b=0.72}
        elseif ZeD.currentBase == "light" then
            nextC = {r=1, g=1, b=1}
        else
            nextC = {r=0.05, g=0.08, b=0.12}
        end
        local bg1 = hoverIdx == 1 and T.surf4 or s2
        self:drawRect(btnX, fY, rh, rh, bg1.a, bg1.r, bg1.g, bg1.b)
        self:drawRectBorder(btnX, fY, rh, rh, bs.a, bs.r, bs.g, bs.b)
        -- 5px filled circle centered: pixel art on the hairline grid, each of its 5 x 5 cells T.hair square
        -- (Oct 21 2026: rows on T.px(r) edges came out 2, 5, 2 px tall at 1.75)
        local p1 = T.hair
        local p4, p5 = 4 * p1, 5 * p1
        local cx, cy = btnX + math.floor((rh - p5) / 2), fY + math.floor((rh - p5) / 2)
        self:drawRect(cx + p1, cy,      p4 - p1, p1,      1, nextC.r, nextC.g, nextC.b)
        self:drawRect(cx,      cy + p1, p5,      p4 - p1, 1, nextC.r, nextC.g, nextC.b)
        self:drawRect(cx + p1, cy + p4, p4 - p1, p5 - p4, 1, nextC.r, nextC.g, nextC.b)
        self._themeControlRects[1] = {x=self:getAbsoluteX()+btnX, y=self:getAbsoluteY()+fY, w=rh, h=rh}
        btnX = btnX + rh + btnGap

        -- 2. Accent dot: current accent color
        local ac = T.accent
        local bg2 = hoverIdx == 2 and T.surf4 or s2
        self:drawRect(btnX, fY, rh, rh, bg2.a, bg2.r, bg2.g, bg2.b)
        self:drawRectBorder(btnX, fY, rh, rh, bs.a, bs.r, bs.g, bs.b)
        cx, cy = btnX + math.floor((rh - p5) / 2), fY + math.floor((rh - p5) / 2)
        self:drawRect(cx + p1, cy,      p4 - p1, p1,      1, ac.r, ac.g, ac.b)
        self:drawRect(cx,      cy + p1, p5,      p4 - p1, 1, ac.r, ac.g, ac.b)
        self:drawRect(cx + p1, cy + p4, p4 - p1, p5 - p4, 1, ac.r, ac.g, ac.b)
        self._themeControlRects[2] = {x=self:getAbsoluteX()+btnX, y=self:getAbsoluteY()+fY, w=rh, h=rh}
        btnX = btnX + rh + btnGap

        -- 3. Scale: "A" label
        local bg3 = hoverIdx == 3 and T.surf4 or s2
        self:drawRect(btnX, fY, rh, rh, bg3.a, bg3.r, bg3.g, bg3.b)
        self:drawRectBorder(btnX, fY, rh, rh, bs.a, bs.r, bs.g, bs.b)
        local aW = ZeD.TM:MeasureStringX(T.fontF5, "A")
        local aH = ZeD.TM:getFontHeight(T.fontF5)
        local aX = btnX + math.floor((rh - aW) / 2)
        local aY = fY + math.floor((rh - aH) / 2)
        self:drawText("A", aX, aY, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF5)
        self._themeControlRects[3] = {x=self:getAbsoluteX()+btnX, y=self:getAbsoluteY()+fY, w=rh, h=rh}
        btnX = btnX + rh + btnGap

        -- 4. Reset window position: "R" label
        if not self.noResetControl then
        local bg4 = hoverIdx == 4 and T.surf4 or s2
        self:drawRect(btnX, fY, rh, rh, bg4.a, bg4.r, bg4.g, bg4.b)
        self:drawRectBorder(btnX, fY, rh, rh, bs.a, bs.r, bs.g, bs.b)
        local rLbl = "R"
        local rLblW = ZeD.TM:MeasureStringX(T.fontF5, rLbl)
        local rLblH = ZeD.TM:getFontHeight(T.fontF5)
        local rLblX = btnX + math.floor((rh - rLblW) / 2)
        local rLblY = fY + math.floor((rh - rLblH) / 2)
        self:drawText(rLbl, rLblX, rLblY, T.toneNorm.r, T.toneNorm.g, T.toneNorm.b, T.toneNorm.a, T.fontF5)
        self._themeControlRects[4] = {x=self:getAbsoluteX()+btnX, y=self:getAbsoluteY()+fY, w=rh, h=rh}
        end

        -- 5. Dyslexic toggle (commented out — requires Lua reset, deferred)
        -- local isDyslexic = getCore():getOptionEnableDyslexicFont()
        -- local bg4 = isDyslexic and T.accent or (hoverIdx == 4 and T.surf4 or s2)
        -- local dyTextC = isDyslexic and T.textOnAccent or T.text
        -- self:drawRect(btnX, fY, rh, rh, bg4.a, bg4.r, bg4.g, bg4.b)
        -- self:drawRectBorder(btnX, fY, rh, rh, bs.a, bs.r, bs.g, bs.b)
        -- local dyW = ZeD.TM:MeasureStringX(T.fontF1, "DY")
        -- local dyH = ZeD.TM:getFontHeight(T.fontF1)
        -- local dyX = btnX + math.floor((rh - dyW) / 2)
        -- local dyY = fY + math.floor((rh - dyH) / 2)
        -- self:drawText("DY", dyX, dyY, dyTextC.r, dyTextC.g, dyTextC.b, dyTextC.a, T.fontF1)
        -- self._themeControlRects[4] = {x=self:getAbsoluteX()+btnX, y=self:getAbsoluteY()+fY, w=rh, h=rh}

        -- S123: button prompts (gamepad mode, this window focused). Right-
        -- aligned, left of the grow box; drops prompts from the left when the
        -- footer is too narrow rather than overlapping the theme controls.
        do
            local Focus = ZeD.Input and ZeD.Input.Focus
            local Det   = ZeD.Input and ZeD.Input.Detector
            local gpMode = Det and Det.getMode and Det.getMode() == "gamepad"
            -- a window outside FocusManager (the main menu's) hands its own
            -- prompts in: getFooterPrompts returns the list, or nil for none
            local prompts = self.getFooterPrompts and self:getFooterPrompts() or nil
            if not prompts and gpMode and Focus and Focus.getFocusedWindow and Focus.getFocusedWindow() == self then
                local el = Focus.getFocusedElement and Focus.getFocusedElement(self)
                prompts = _promptsFor(el)
                pcall(_addListPrompts, self, prompts)
            end
            if prompts then
                local tm   = ZeD.TM
                local font = T.fontF5
                local fh   = tm:getFontHeight(font)
                local box  = rh - T.px(4)
                local px   = w - rh - btnGap - sp.sm
                local minX = btnX + rh + btnGap * 3
                local textY = fY + math.floor((rh - fh) / 2)
                -- (the buttons as ZeD's pixel pictures, ZeD_PadGlyphs; boxed names with the glyph setting on Keyboard/mouse or Off)
                local PG = ZeD.PadGlyphs
                local set = PG and PG.set()
                local gk = PG and PG.k(box) or 1
                for i = #prompts, 1, -1 do
                    local p  = prompts[i]
                    local lw = tm:MeasureStringX(font, p.label)
                    local roles = set and (p.pad or PG.roles(p.glyph)) or nil
                    local bw = roles and PG.width(roles, gk, set) or box
                    local total = bw + T.px(3) + lw
                    if px - total < minX then break end
                    local x0 = px - total
                    if roles then
                        PG.draw(self, roles, x0, fY, rh, gk, set)
                    else
                        local gw = tm:MeasureStringX(font, p.glyph)
                        self:drawRectBorder(x0, fY + T.px(2), box, box, bs.a, bs.r, bs.g, bs.b)
                        self:drawText(p.glyph, x0 + math.floor((box - gw) / 2), textY, T.text.r, T.text.g, T.text.b, T.text.a, font)
                    end
                    self:drawText(p.label, x0 + bw + T.px(3), textY, T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a, font)
                    px = x0 - sp.sm * 2
                end
            end
        end

        -- Grow box (right corner, same style)
        if self.resizable then A.drawGrowBox(self, w - rh, h - rh, rh) end
    end

    -- S108 QA v7: Scoped accent underline at the BOTTOM edge of the window,
    -- positioned above the currently-focused zone's horizontal range. Drawn
    -- LAST so the resizable footer fill (line ~310) and grow box don't
    -- overdraw it. Windows declare `uiRange = function(win) return x, w end`
    -- on each ring zone entry; zones without uiRange get no underline (quiet
    -- degrade). Locked state (Y-hold) uses brighter accent + thicker bar.
    local mode = ZeD.Input and ZeD.Input.Detector and ZeD.Input.Detector.getMode
                 and ZeD.Input.Detector.getMode()
    if mode == "gamepad"
       and ZeD.Input and ZeD.Input.Focus
       and ZeD.Input.Focus.getFocusedWindow() == self then
        local Focus = ZeD.Input.Focus
        local zone = Focus.getFocusedZone(self)
        if zone and zone.uiRange then
            local zx, zw = zone.uiRange(self)
            if zx and zw and zw > 0 then
                local locked = (Focus.isLocked and Focus.isLocked()) or false
                local a = locked and (T.accentBright or T.accent) or T.accent
                local barH = locked and T.px(4) or T.px(3)
                local underY = h - barH
                self:drawRect(zx, underY, zw, barH, 1.0, a.r, a.g, a.b)
            end
        end
    end

    -- Restore global accent after this window's render cycle
    self:_restoreAccent()
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

--- Release resize state and capture. Called from multiple exit points.
function ZeD_Window:_stopResize()
    self._resizing = false
    self._resizeYOnly = false
    self._growBoxWasDown = false
    self:setCapture(false)
end

function ZeD_Window:onMouseDown(x, y)
    local T = ZeD.T
    if not self:getIsVisible() then return end

    -- If update() already claimed this click for resize, don't also start a drag
    if self._resizing then return true end

    local w = self:getWidth()
    local h = self:getHeight()
    local rh = self:resizeWidgetHeight()

    -- Grow box click: start resize directly from onMouseDown too
    -- (belt-and-suspenders with update() — some child panels eat events)
    if self.resizable and not self.windowShaded
       and x >= w - rh and y >= h - rh then
        self._resizing = true
        self._resizeYOnly = false
        self.moving = false
        self:setCapture(true)
        self:bringToTop()
        return true
    end

    -- Bottom edge resize
    if self.resizable and not self.windowShaded
       and y >= h - T.px(4) and x < w - rh then
        self._resizing = true
        self._resizeYOnly = true
        self.moving = false
        self:setCapture(true)
        self:bringToTop()
        return true
    end

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
    local T = ZeD.T
    if self._resizing then
        -- Safety: if mouse button released but we missed onMouseUp
        if not isMouseButtonDown(0) then
            self:_stopResize()
            return
        end
        local mx = self:getMouseX()
        local my = self:getMouseY()
        local newW = self._resizeYOnly and self.width or mx
        local newH = my

        newW = math.max(newW, self.minimumWidth or T.px(200))
        newH = math.max(newH, self.minimumHeight or T.px(120))
        newH = math.min(newH, getCore():getScreenHeight() - self:getY())

        self:setWidth(newW)
        self:setHeight(newH)
        -- Java anchor system propagates to children automatically.
        -- ZeD_TabPanel:prerender calls resizeChildren() as safety net.
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
-- Reset both windows to the default page-spread layout: the "R" square in a
-- window's footer (also called by the QA scripts). A rolled side
-- (WindowCurtain) comes back down first, so the reset starts from the whole
-- window.
-- ---------------------------------------------------------------------------
function ZeD_Window.resetLayout()
    local S = ZeD.Settings
    local T = ZeD.T
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local defW = math.min(T.px(444), math.floor(screenW * 0.5))   -- 36 + 372 + 36 design units, as a fresh open
    local defH = math.min(T.px(420), screenH - T.px(80))
    local gap = T.px(5)  -- 5px each side = 10px total gap

    -- Position as page spread: character left, world right
    local charWin = ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and ZeD_CharacterWindow.getWindow()
    local worldWin = ZeD_WorldWindow and ZeD_WorldWindow.getWindow and ZeD_WorldWindow.getWindow()
    for _, w in ipairs({ charWin or false, worldWin or false }) do
        if w and w._rolled and ZeD.Curtain and ZeD.Curtain.finishUnroll then ZeD.Curtain.finishUnroll(w) end
    end
    if charWin then
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
    if worldWin then
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
end

-- ---------------------------------------------------------------------------
-- Grow box resize via update() with absolute coordinates.
-- Child panels can't eat these clicks because we check raw screen position.
-- (WHAT_CODE_DID.md quirk #1)
-- ---------------------------------------------------------------------------
function ZeD_Window:update()
    ISPanel.update(self)

    -- These controls poll the raw mouse, so each one has to tell a press that began on
    -- it from a button that was already down when the pointer arrived (a drag released
    -- over the close box, a held button crossing the grow box) and from a press that
    -- landed on another window drawn above this one. `fresh` is the frame the button
    -- went down; the squares and boxes arm on that frame only, while isMouseOver says
    -- no window above holds the pointer (the engine's own picking, as for a click).
    local down = isMouseButtonDown(0)
    local fresh = down and not self._uiPrevDown
    self._uiPrevDown = down

    -- Close box hit-testing (absolute coords, same pattern as grow box)
    if self._closeBtnRect and not self._closeOnRod then
        local cb = self:closeRect()
        local mx = getMouseX() - self:getAbsoluteX()
        local my = getMouseY() - self:getAbsoluteY()
        local inside = mx >= cb.x and mx <= cb.x + cb.w and my >= cb.y and my <= cb.y + cb.h
        if inside and not self:isMouseOver() then inside = false end
        self._closeHover = inside

        if down then
            if fresh and inside then self._closeWasDown = true end
        elseif self._closeWasDown then
            self._closeWasDown = false
            if inside then
                self:close()
                return
            end
        end
    end

    -- Footer action strip interaction (suppressed when card owns strip)
    if self.footerToggles and self.footerItem and not self.windowShaded and not self.cardOwnsActionStrip then
        self.footerToggleHover, self.footerToggleWasDown = ZeD.Molecules.updateActionStrip(
            self.footerToggleRects, ZeD.ActionStrip.TOGGLE_DEFS,
            self.footerItem, self.footerToggleHover, self.footerToggleWasDown, self.playerNum
        )
    end

    -- Theme control buttons interaction
    if self._themeControlRects and not self.windowShaded then
        local amx, amy = getMouseX(), getMouseY()
        local newHover = nil
        for i, rect in ipairs(self._themeControlRects) do
            if amx >= rect.x and amx <= rect.x + rect.w
            and amy >= rect.y and amy <= rect.y + rect.h then
                newHover = i
                break
            end
        end
        if newHover and not self:isMouseOver() then newHover = nil end   -- another window is over it
        self._themeControlHover = newHover

        if down then
            if fresh and newHover then self._themeControlWasDown = newHover end   -- which square the press began on
        elseif self._themeControlWasDown then
            local armed = self._themeControlWasDown
            self._themeControlWasDown = false
            if newHover and newHover == armed and ZeD.Settings then
                local S = ZeD.Settings
                if newHover == 1 then
                    ZeD.applyTheme(S.cycleNext(S.baseKeys, ZeD.currentBase), nil, nil)
                    S.syncToModOptions()
                elseif newHover == 2 and self.globalAccentControl then
                    -- A lone window (the main menu's) cycles the whole UI's accent
                    ZeD.applyTheme(nil, S.cycleNext(S.accentKeys, ZeD.currentAccent), nil)
                    S.syncToModOptions()
                elseif newHover == 2 then
                    -- Per-window accent: cycle this window's _accentKey independently
                    -- (the cycle runs through the colours, then a step that follows
                    -- the Accent color option, which is where a window starts)
                    local keys, curKey = S.accentKeys, self._accentKey
                    if curKey == nil then
                        self._accentKey = keys[1]
                    elseif curKey == keys[#keys] then
                        self._accentKey = nil
                    else
                        self._accentKey = S.cycleNext(keys, curKey)
                    end
                    -- Persist per-window accent to modData + ModOptions
                    S.syncWindowAccent(self)
                elseif newHover == 3 then
                    ZeD.applyTheme(nil, nil, S.cycleNext(S.sizeKeys, ZeD.currentSize))
                    S.syncToModOptions()
                elseif newHover == 4 then
                    ZeD_Window.resetLayout()   -- both windows back to the default page spread
                -- elseif newHover == 5 then
                --     local cur = getCore():getOptionEnableDyslexicFont()
                --     getCore():setOptionEnableDyslexicFont(not cur)
                --     getCore():saveOptions()
                end
            end
        end
    end

    -- Resize logic (resizable windows only)
    if not self.resizable or self.windowShaded then return end

    -- Safety release: if we're resizing but the mouse button is up,
    -- force-release. PZ's capture system can miss onMouseUp.
    if self._resizing and not isMouseButtonDown(0) then
        self:_stopResize()
        return
    end

    if self._resizing then return end  -- already resizing, handled by onMouseMove

    -- Only start resize on fresh mouse-down: a button already held when the pointer
    -- reaches the corner (a drag from another window) never starts one, nor does a
    -- press that landed on a window above this one
    if not down then
        self._growBoxWasDown = false
        return
    end
    if not fresh or not self:isMouseOver() then return end

    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    local w = self:getWidth()
    local h = self:getHeight()
    local rh = self:resizeWidgetHeight()

    -- Grow box: bottom-right corner
    if mx >= w - rh and mx <= w and my >= h - rh and my <= h then
        self._resizing = true
        self._resizeYOnly = false
        self._growBoxWasDown = true
        self.moving = false  -- kill any drag that started in onMouseDown
        self:setCapture(true)
        self:bringToTop()
        return
    end

    -- Bottom edge: hot zone along bottom, excluding grow box
    local T = ZeD.T
    local hotZ = T.sp.resizeHotZone
    if my >= h - hotZ and my <= h and mx >= 0 and mx < w - rh then
        self._resizing = true
        self._resizeYOnly = true
        self._growBoxWasDown = true
        self.moving = false
        self:setCapture(true)
        self:bringToTop()
        return
    end
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
