-- ZeD-UI/42/media/lua/client/ZeD/BodyFigure.lua
-- ============================================================================
-- BODY FIGURE — tile-grid body part textures with per-part positioning.
-- Each body part is a separate PNG drawn at a computed (x, y) offset on
-- the body canvas (916x2250). Scaled uniformly to fit the panel.
-- ============================================================================

require "ISUI/ISPanel"

ZeD = ZeD or {}

ZeD_BodyFigure = ISPanel:derive("ZeD_BodyFigure")

-- Full body canvas = exact panel size. All parts are same-canvas PNGs
-- layered at origin. Each part has only its zone visible, rest transparent.
-- S124 scale: canvas sizes, layouts and hit rects stay in CANVAS units (= texture px). drawAt()/render() fit the
-- canvas into the caller's rect with factor s, and the callers pass scaled rects (T.sp.figureW/H, T.px(FIGURE_W/H)),
-- so drawn size and hit rects follow the root scale through s. Wrapping these numbers in T.px would double-scale.
local CANVAS_W = 220
local CANVAS_H = 260
-- S123: the female atlas is a different canvas (240x590 tiles, see F_LAYOUT).
-- Every fit / hit-test calculation must use the ACTIVE canvas, otherwise the
-- female parts are scaled for the 220x260 male canvas and spill far outside
-- the figure box (the "body too large behind the skeleton" bug).
local F_CANVAS_W = 240
local F_CANVAS_H = 590
local function _canvasFor(fig)
    if fig and fig.isFemale then return F_CANVAS_W, F_CANVAS_H end
    return CANVAS_W, CANVAS_H
end

-- ============================================================================
-- PART LAYOUT — stacked layers, per-sex
-- Every part shares the same canvas (220x260) and is drawn at (0, 0).
-- Hit-test w/h = canvas size; actual clickable area is the opaque pixels.
-- "r" suffix = character's right (viewer's left), "l" = character's left
-- ============================================================================

-- M body layers (220x260, all drawn at origin)
-- hit = {x, y, w, h} — measured from opaque pixel bounds + 3px pad.
local HP = 3  -- hit padding
local M_LAYOUT = {
    { suffix = "head",      x = 0, y = 0, w = 220, h = 260, hit = { x = 98-HP, y = 10-HP, w = 24+HP*2, h = 33+HP*2 } },
    { suffix = "neck",      x = 0, y = 0, w = 220, h = 260, hit = { x =106-HP, y = 38-HP, w = 10+HP*2, h = 15+HP*2 } },
    { suffix = "up-torso",  x = 0, y = 0, w = 220, h = 260, hit = { x = 86-HP, y = 47-HP, w = 48+HP*2, h = 43+HP*2 } },
    { suffix = "bicep-r",   x = 0, y = 0, w = 220, h = 260, hit = { x = 77-HP, y = 54-HP, w = 18+HP*2, h = 37+HP*2 } },
    { suffix = "bicep-l",   x = 0, y = 0, w = 220, h = 260, hit = { x =126-HP, y = 54-HP, w = 18+HP*2, h = 38+HP*2 } },
    { suffix = "low-torso", x = 0, y = 0, w = 220, h = 260, hit = { x =104-HP, y = 86-HP, w = 13+HP*2, h = 37+HP*2 } },
    { suffix = "wrist-r",   x = 0, y = 0, w = 220, h = 260, hit = { x = 67-HP, y = 89-HP, w = 16+HP*2, h = 36+HP*2 } },
    { suffix = "wrist-l",   x = 0, y = 0, w = 220, h = 260, hit = { x =137-HP, y = 90-HP, w = 16+HP*2, h = 35+HP*2 } },
    { suffix = "groin",     x = 0, y = 0, w = 220, h = 260, hit = { x = 93-HP, y =103-HP, w = 35+HP*2, h = 27+HP*2 } },
    { suffix = "hand-r",    x = 0, y = 0, w = 220, h = 260, hit = { x = 57-HP, y =123-HP, w = 15+HP*2, h = 20+HP*2 } },
    { suffix = "hand-l",    x = 0, y = 0, w = 220, h = 260, hit = { x =148-HP, y =122-HP, w = 16+HP*2, h = 21+HP*2 } },
    { suffix = "thigh-r",   x = 0, y = 0, w = 220, h = 260, hit = { x = 90-HP, y =121-HP, w = 14+HP*2, h = 64+HP*2 } },
    { suffix = "thigh-l",   x = 0, y = 0, w = 220, h = 260, hit = { x =116-HP, y =121-HP, w = 14+HP*2, h = 64+HP*2 } },
    { suffix = "ankle-r",   x = 0, y = 0, w = 220, h = 260, hit = { x = 91-HP, y =185-HP, w = 10+HP*2, h = 52+HP*2 } },
    { suffix = "ankle-l",   x = 0, y = 0, w = 220, h = 260, hit = { x =119-HP, y =185-HP, w = 11+HP*2, h = 52+HP*2 } },
    { suffix = "foot-r",    x = 0, y = 0, w = 220, h = 260, hit = { x = 90-HP, y =236-HP, w = 11+HP*2, h = 17+HP*2 } },
    { suffix = "foot-l",    x = 0, y = 0, w = 220, h = 260, hit = { x =119-HP, y =236-HP, w = 11+HP*2, h = 17+HP*2 } },
}

-- F body tile positions (pre-scaled 240x590 canvas)
local F_LAYOUT = {
    { suffix = "head",      x =   0, y =   0, w = 240, h =  88 },
    { suffix = "neck",      x =   0, y =  88, w = 240, h =  27 },
    { suffix = "bicep-r",   x =   0, y = 115, w =  84, h =  92 },
    { suffix = "up-torso",  x =  83, y = 115, w =  73, h =  92 },
    { suffix = "bicep-l",   x = 156, y = 115, w =  84, h =  92 },
    { suffix = "wrist-r",   x =   0, y = 207, w =  84, h =  52 },
    { suffix = "low-torso", x =  74, y = 207, w =  92, h =  52 },
    { suffix = "wrist-l",   x = 156, y = 207, w =  84, h =  52 },
    { suffix = "hand-r",    x =   0, y = 259, w =  66, h =  67 },
    { suffix = "groin",     x =  65, y = 259, w = 109, h =  67 },
    { suffix = "hand-l",    x = 174, y = 259, w =  66, h =  67 },
    { suffix = "thigh-r",   x =   0, y = 326, w = 120, h =  81 },
    { suffix = "thigh-l",   x = 120, y = 326, w = 120, h =  81 },
    { suffix = "ankle-r",   x =   0, y = 407, w = 120, h = 128 },
    { suffix = "ankle-l",   x = 120, y = 407, w = 120, h = 128 },
    { suffix = "foot-r",    x =   0, y = 535, w = 120, h =  54 },
    { suffix = "foot-l",    x = 120, y = 535, w = 120, h =  54 },
}

-- Suffix → display name mapping (for hit test → ThermalTab communication)
local SUFFIX_TO_DISPLAY = {
    ["head"]      = "Head",
    ["neck"]      = "Neck",
    ["up-torso"]  = "Upper Torso",
    ["low-torso"] = "Lower Torso",
    ["groin"]     = "Groin",
    ["bicep-l"]   = "Left Upper Arm",
    ["bicep-r"]   = "Right Upper Arm",
    ["wrist-l"]   = "Left Forearm",
    ["wrist-r"]   = "Right Forearm",
    ["hand-l"]    = "Left Hand",
    ["hand-r"]    = "Right Hand",
    ["thigh-l"]   = "Left Upper Leg",
    ["thigh-r"]   = "Right Upper Leg",
    ["ankle-l"]   = "Left Lower Leg",
    ["ankle-r"]   = "Right Lower Leg",
    ["foot-l"]    = "Left Foot",
    ["foot-r"]    = "Right Foot",
}

-- ============================================================================
-- CONSTRUCTOR
-- ============================================================================

function ZeD_BodyFigure:new(x, y, width, height, playerNum)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.playerNum = playerNum
    o.isFemale = false
    o.drawBorder = false
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.backgroundColor = {r=0, g=0, b=0, a=0}

    o.colorMap = {}       -- displayName -> {r, g, b, a}
    o.selectedPart = nil  -- display name of hovered part

    o.onPartHover = nil
    o.onPartClick = nil

    o.textures = {}       -- suffix -> texture
    o.texturesLoaded = false
    o.activeLayout = M_LAYOUT

    return o
end

-- ============================================================================
-- TEXTURE LOADING
-- ============================================================================

function ZeD_BodyFigure:setSex(isFemale)
    if isFemale ~= self.isFemale then
        self.isFemale = isFemale
        self.activeLayout = isFemale and F_LAYOUT or M_LAYOUT
        self.texturesLoaded = false
    end
end

function ZeD_BodyFigure:loadTextures()
    local prefix = self.isFemale and "f" or "m"
    self.textures = {}
    for _, entry in ipairs(self.activeLayout) do
        self.textures[entry.suffix] = getTexture("media/textures/ZeD/body/" .. prefix .. "-" .. entry.suffix .. ".png")
    end
    self.texturesLoaded = true
end

-- ============================================================================
-- COLOR API
-- ============================================================================

function ZeD_BodyFigure:setPartColor(displayName, r, g, b, a)
    self.colorMap[displayName] = {r=r, g=g, b=b, a=a or 1.0}
end

function ZeD_BodyFigure:clearColors()
    self.colorMap = {}
end

-- ============================================================================
-- SCALE + OFFSET (fit canvas into panel)
-- ============================================================================

function ZeD_BodyFigure:getDrawParams()
    local panelW = self:getWidth()
    local panelH = self:getHeight()
    local cw, ch = _canvasFor(self)
    -- Uniform scale to fit the active canvas in the panel
    local scaleX = panelW / cw
    local scaleY = panelH / ch
    local s = math.min(scaleX, scaleY)
    -- Center in panel
    local scaledW = math.floor(cw * s)
    local scaledH = math.floor(ch * s)
    local xOff = math.floor((panelW - scaledW) / 2)
    local yOff = math.floor((panelH - scaledH) / 2)
    return s, xOff, yOff
end

-- ============================================================================
-- HIT TESTING (uses per-part hit regions, scaled)
-- ============================================================================

function ZeD_BodyFigure:hitTest(mx, my)
    local s, xOff, yOff = self:getDrawParams()

    -- Convert mouse to canvas coords
    local cx = (mx - xOff) / s
    local cy = (my - yOff) / s

    local cw, ch = _canvasFor(self)
    if cx < 0 or cx > cw or cy < 0 or cy > ch then
        return nil
    end

    -- Test in reverse order (extremities first for priority)
    local layout = self.activeLayout
    for i = #layout, 1, -1 do
        local e = layout[i]
        local h = e.hit or e  -- use hit region if defined, else full bounds
        if cx >= h.x and cx < h.x + h.w and cy >= h.y and cy < h.y + h.h then
            return SUFFIX_TO_DISPLAY[e.suffix]
        end
    end
    return nil
end

-- ============================================================================
-- RENDER
-- ============================================================================

function ZeD_BodyFigure:render()
    ISPanel.render(self)

    if not self.texturesLoaded then
        self:loadTextures()
    end

    local s, xOff, yOff = self:getDrawParams()

    for _, entry in ipairs(self.activeLayout) do
        local tex = self.textures[entry.suffix]
        if tex then
            local displayName = SUFFIX_TO_DISPLAY[entry.suffix]
            local color = displayName and self.colorMap[displayName]
            local isHovered = (displayName == self.selectedPart)

            -- Scaled position on panel
            local dx = xOff + math.floor(entry.x * s)
            local dy = yOff + math.floor(entry.y * s)

            if color then
                if isHovered then
                    self:drawTextureScaledUniform(tex, dx, dy, s, 1.0, 1, 1, 1)
                else
                    self:drawTextureScaledUniform(tex, dx, dy, s, color.a or 0.9, color.r, color.g, color.b)
                end
            else
                local a = isHovered and 0.20 or 0.10
                self:drawTextureScaledUniform(tex, dx, dy, s, a, ZeD.T.textDim.r, ZeD.T.textDim.g, ZeD.T.textDim.b)
            end
        end
    end
end

-- ============================================================================
-- DRAW-AT: Render onto an external panel at a given position.
-- Used when the figure is NOT a child panel — drawn inside the parent's
-- stencil rect so it clips properly with scroll.
-- ============================================================================

function ZeD_BodyFigure:drawAt(panel, px, py, pw, ph)
    if not self.texturesLoaded then
        self:loadTextures()
    end

    -- Fit the ACTIVE canvas (per sex) into the given rect
    local cw, ch = _canvasFor(self)
    local scaleX = pw / cw
    local scaleY = ph / ch
    local s = math.min(scaleX, scaleY)
    local scaledW = math.floor(cw * s)
    local scaledH = math.floor(ch * s)
    local xOff = px + math.floor((pw - scaledW) / 2)
    local yOff = py + math.floor((ph - scaledH) / 2)

    -- Store draw params for hitTestAt
    self._drawAtS = s
    self._drawAtX = xOff
    self._drawAtY = yOff

    -- Background texture (grid) — light/dark variant
    local isLight = ZeD.currentBase == "light"
    local bgPath  = isLight
                    and "media/textures/ZeD/body/fig-bg-light.png"
                    or  "media/textures/ZeD/body/fig-bg-dark.png"
    if not self._bgTex or self._bgIsLight ~= isLight then
        self._bgTex     = getTexture(bgPath)
        self._bgIsLight = isLight
    end
    -- S123: the skeleton backdrop is authored on the MALE 220x260 canvas, so
    -- it is drawn into the fitted canvas rect (xOff/yOff/scaledW/scaledH),
    -- never the raw panel rect — that is what kept it from lining up with
    -- the parts. There is no female skeleton asset yet (design item): the
    -- female figure uses its whole-body silhouette (f-body.png, 240x590)
    -- as a dim base instead so nothing male-proportioned bleeds through.
    local ac = ZeD.T.accent
    local tint = ZeD.colorBlend(ZeD.T.iconWhite, ac, 0.45)
    if self.isFemale then
        if not self._fBodyTex then self._fBodyTex = getTexture("media/textures/ZeD/body/f-body.png") end
        if self._fBodyTex then
            panel:drawTextureScaledAspect(self._fBodyTex, xOff, yOff, scaledW, scaledH, 0.18, tint.r, tint.g, tint.b)
        end
    elseif self._bgTex then
        panel:drawTextureScaledAspect(self._bgTex, xOff, yOff, scaledW, scaledH, 1.0, tint.r, tint.g, tint.b)
    end

    for _, entry in ipairs(self.activeLayout) do
        local tex = self.textures[entry.suffix]
        if tex then
            local displayName = SUFFIX_TO_DISPLAY[entry.suffix]
            local color = displayName and self.colorMap[displayName]
            local isHovered = (displayName == self.selectedPart)

            local dx = xOff + math.floor(entry.x * s)
            local dy = yOff + math.floor(entry.y * s)

            if color then
                if isHovered then
                    panel:drawTextureScaledUniform(tex, dx, dy, s, 1.0, 1, 1, 1)
                else
                    panel:drawTextureScaledUniform(tex, dx, dy, s, color.a or 0.9, color.r, color.g, color.b)
                end
            else
                local a = isHovered and 0.20 or 0.10
                panel:drawTextureScaledUniform(tex, dx, dy, s, a, ZeD.T.textDim.r, ZeD.T.textDim.g, ZeD.T.textDim.b)
            end
        end
    end
end

-- S101 gamepad support: return panel-local rects for every hittable body
-- part, using the current drawAt transform. Empty list if the figure has
-- not been drawn yet (first frame after tab switch) — caller drops the
-- body-part zone entirely rather than stamping phantom rects.
function ZeD_BodyFigure:getPartRects()
    local s = self._drawAtS
    if not s or s <= 0 then return {} end
    local xOff = self._drawAtX or 0
    local yOff = self._drawAtY or 0
    local out = {}
    for _, e in ipairs(self.activeLayout) do
        local displayName = SUFFIX_TO_DISPLAY[e.suffix]
        if displayName then
            local h = e.hit or e
            out[#out + 1] = {
                name = displayName,
                x = xOff + math.floor(h.x * s),
                y = yOff + math.floor(h.y * s),
                w = math.floor(h.w * s),
                h = math.floor(h.h * s),
            }
        end
    end
    return out
end

-- Hit test using drawAt coordinates (mouse coords relative to the parent panel)
function ZeD_BodyFigure:hitTestAt(mx, my)
    local s = self._drawAtS or 1
    local xOff = self._drawAtX or 0
    local yOff = self._drawAtY or 0

    local cx = (mx - xOff) / s
    local cy = (my - yOff) / s

    local cw, ch = _canvasFor(self)
    if cx < 0 or cx > cw or cy < 0 or cy > ch then
        return nil
    end

    local layout = self.activeLayout
    for i = #layout, 1, -1 do
        local e = layout[i]
        local h = e.hit or e
        if cx >= h.x and cx < h.x + h.w and cy >= h.y and cy < h.y + h.h then
            return SUFFIX_TO_DISPLAY[e.suffix]
        end
    end
    return nil
end

-- ============================================================================
-- MOUSE HANDLING
-- ============================================================================

function ZeD_BodyFigure:onMouseMove(dx, dy)
    ISPanel.onMouseMove(self, dx, dy)
    local hitPart = self:hitTest(self:getMouseX(), self:getMouseY())
    if hitPart ~= self.selectedPart then
        self.selectedPart = hitPart
        if self.onPartHover then
            self.onPartHover(hitPart)
        end
    end
end

function ZeD_BodyFigure:onMouseMoveOutside(dx, dy)
    ISPanel.onMouseMoveOutside(self, dx, dy)
    if self.selectedPart ~= nil then
        self.selectedPart = nil
        if self.onPartHover then
            self.onPartHover(nil)
        end
    end
end

function ZeD_BodyFigure:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)
    if self.selectedPart and self.onPartClick then
        self.onPartClick(self.selectedPart)
    end
end
