-- ============================================================================
-- Overrides/TextScale.lua — ZeD text follows the root scale (S124, phase 2)
-- ============================================================================
-- The five ZeD role fonts (ZeD.T.fontF1..F5) live on distance-field slots
-- (ZeD.Font.sdf) whose atlases have a 64 px face. Every ISUIElement text draw
-- that uses one of them is routed through the engine's zoom path at
-- design px x root scale (ZeD.Text.zoomOf). Vanilla fonts (UIFont.Small and
-- friends, which still carry the bitmap Fira for the vanilla UI) are drawn by
-- the original functions, untouched.
--
-- Measuring goes through ZeD.TM (shared/ZeD/Scale.lua), which applies the same
-- zoom to MeasureStringX / MeasureStringY / getFontHeight.
--
-- When the game's own fonts hold those slots (Chinese, Japanese, Korean, Thai,
-- or the Dyslexic font option; ZeD.Text.checkRoleFonts) the roles are the
-- game's Small / Medium / Large with no zoom registered, so zoomOf is 1 and
-- every draw below takes the original path at native size.
-- ============================================================================

require "ZeD/Scale"

local X = ZeD.Text

if not ISUIElement._zedTextScalePatched then
    ISUIElement._zedTextScalePatched = true

    local origDrawText       = ISUIElement.drawText
    local origDrawTextRight  = ISUIElement.drawTextRight
    local origDrawTextCentre = ISUIElement.drawTextCentre

    -- drawText(str, x, y, r, g, b, a, font): x, y = top-left of the text box
    function ISUIElement:drawText(str, x, y, r, g, b, a, font)
        local z = X.zoomOf(font)
        if z == 1 then return origDrawText(self, str, x, y, r, g, b, a, font) end
        if self.javaObject ~= nil then
            self.javaObject:DrawText(font, tostring(str), x, y, z, r, g, b, a)
        end
    end

    -- drawTextRight(str, x, y, ...): the text ENDS at x
    function ISUIElement:drawTextRight(str, x, y, r, g, b, a, font)
        local z = X.zoomOf(font)
        if z == 1 then return origDrawTextRight(self, str, x, y, r, g, b, a, font) end
        if self.javaObject ~= nil then
            str = tostring(str)
            local w = X.realTM():MeasureStringX(font, str) * z
            self.javaObject:DrawText(font, str, x - w, y, z, r, g, b, a)
        end
    end

    -- drawTextCentre(str, x, y, ...): the text is centred on x
    function ISUIElement:drawTextCentre(str, x, y, r, g, b, a, font)
        local z = X.zoomOf(font)
        if z == 1 then return origDrawTextCentre(self, str, x, y, r, g, b, a, font) end
        if self.javaObject ~= nil then
            str = tostring(str)
            local w = X.realTM():MeasureStringX(font, str) * z
            self.javaObject:DrawText(font, str, x - w / 2, y, z, r, g, b, a)
        end
    end

    print("[ZeD] Overrides/TextScale: ISUIElement text draws follow the root scale for the ZeD role fonts")
end

-- ---------------------------------------------------------------------------
-- Borders (phase 2): the engine's drawRectBorder is always one screen pixel.
-- ZeD elements draw their outlines T.px(1) thick instead (four rects), so a
-- border scales like everything else. Vanilla elements keep the engine call.
-- An element counts as ZeD when its class carries `zedScaled = true`; the ZeD
-- classes are flagged once the mod's Lua has loaded (OnGameBoot).
-- ---------------------------------------------------------------------------
if not ISUIElement._zedBorderPatched then
    ISUIElement._zedBorderPatched = true
    local origDrawRectBorder = ISUIElement.drawRectBorder
    function ISUIElement:drawRectBorder(x, y, w, h, a, r, g, b)
        local T = ZeD.T
        local t = (self.zedScaled and T and T.px) and T.px(1) or 1
        if t <= 1 then return origDrawRectBorder(self, x, y, w, h, a, r, g, b) end
        if w <= 0 or h <= 0 then return end
        if w <= 2 * t or h <= 2 * t then return self:drawRect(x, y, w, h, a, r, g, b) end
        self:drawRect(x, y, w, t, a, r, g, b)                 -- top
        self:drawRect(x, y + h - t, w, t, a, r, g, b)         -- bottom
        self:drawRect(x, y + t, t, h - 2 * t, a, r, g, b)     -- left
        self:drawRect(x + w - t, y + t, t, h - 2 * t, a, r, g, b)  -- right
    end
end

-- ---------------------------------------------------------------------------
-- Lean draw calls for the ZeD classes (Oct 22 2026, the drawing-cost work). A draw
-- through ISUIElement costs three to seven times the Java call it makes (measured in
-- game, -debug: a rect 1.56 us against 0.60, a text 3.12 against 1.02, a texture fitted
-- 3.40 against 0.48): the method is found five classes up, the texture goes through
-- ISUITextureGetter's type test, the text asks the zoom the long way. ZeD's panels draw
-- hundreds a frame, so the ZeD classes get their own copies of drawRect, drawRectBorder,
-- drawText, drawTextureScaled and drawTextureScaledAspect that make exactly the same Java
-- calls with exactly the same values (the vanilla rules and the zoom rules above, line
-- for line), only shorter. A class that has its own (ZeD_ActionBar's fade) keeps it.
-- ---------------------------------------------------------------------------
local getterCheck = function(t) return ISUITextureGetter.checkGetTexture(t) end
local LEAN = {}
function LEAN.drawRect(self, x, y, w, h, a, r, g, b)
    local jo = self.javaObject
    if jo ~= nil then
        if self.isCollapsed then return end
        jo:DrawTextureScaledColor(nil, x, y, w, h, r, g, b, a)
    end
end
function LEAN.drawRectBorder(self, x, y, w, h, a, r, g, b)
    local T = ZeD.T
    local t = (self.zedScaled and T and T.px) and T.px(1) or 1
    local jo = self.javaObject
    if t <= 1 then
        -- the engine's one-pixel border (ISUIElement:drawRectBorder)
        if jo ~= nil then
            jo:DrawTextureScaledColor(nil, x, y, 1, h, r, g, b, a)
            jo:DrawTextureScaledColor(nil, x + 1, y, w - 2, 1, r, g, b, a)
            jo:DrawTextureScaledColor(nil, x + w - 1, y, 1, h, r, g, b, a)
            jo:DrawTextureScaledColor(nil, x + 1, y + h - 1, w - 2, 1, r, g, b, a)
        end
        return
    end
    if w <= 0 or h <= 0 then return end
    local dr = self.drawRect
    if dr ~= LEAN.drawRect then
        -- a class with its own drawRect (ZeD_ActionBarLayer's fade): through it, as before
        if w <= 2 * t or h <= 2 * t then return dr(self, x, y, w, h, a, r, g, b) end
        dr(self, x, y, w, t, a, r, g, b)
        dr(self, x, y + h - t, w, t, a, r, g, b)
        dr(self, x, y + t, t, h - 2 * t, a, r, g, b)
        dr(self, x + w - t, y + t, t, h - 2 * t, a, r, g, b)
        return
    end
    if jo == nil or self.isCollapsed then return end
    if w <= 2 * t or h <= 2 * t then jo:DrawTextureScaledColor(nil, x, y, w, h, r, g, b, a); return end
    jo:DrawTextureScaledColor(nil, x, y, w, t, r, g, b, a)                 -- top
    jo:DrawTextureScaledColor(nil, x, y + h - t, w, t, r, g, b, a)         -- bottom
    jo:DrawTextureScaledColor(nil, x, y + t, t, h - 2 * t, r, g, b, a)     -- left
    jo:DrawTextureScaledColor(nil, x + w - t, y + t, t, h - 2 * t, r, g, b, a)  -- right
end
local Sc = ZeD.Scale
function LEAN.drawText(self, str, x, y, r, g, b, a, font)
    -- the zoom kept per font (X.zoomOf's own table, read inline while it is current)
    local z = nil
    local Zc = X._zoom
    if font ~= nil and Zc and Zc.T == ZeD.T and Zc.root == Sc._root then z = Zc.z[font] end
    if z == nil then z = X.zoomOf(font) end
    local jo = self.javaObject
    if z == 1 then
        -- ISUIElement:drawText as the engine has it
        if jo ~= nil then
            if self.isCollapsed then return end
            if font ~= nil then jo:DrawText(font, str, x, y, r, g, b, a)
            else jo:DrawText(UIFont.Small, str, x, y, r, g, b, a) end
        end
        return
    end
    if jo ~= nil then jo:DrawText(font, tostring(str), x, y, z, r, g, b, a) end
end
function LEAN.drawTextureScaled(self, texture, x, y, w, h, a, r, g, b)
    local jo = self.javaObject
    if jo ~= nil then
        if type(texture) == "table" then texture = getterCheck(texture) end   -- (anything else passes through unchanged)
        if r == nil then jo:DrawTextureScaled(texture, x, y, w, h, a)
        else jo:DrawTextureScaledColor(texture, x, y, w, h, r, g, b, a) end
    end
end
function LEAN.drawTextureScaledAspect(self, texture, x, y, w, h, a, r, g, b)
    local jo = self.javaObject
    if jo ~= nil then
        if type(texture) == "table" then texture = getterCheck(texture) end
        if r == nil then jo:DrawTextureScaledAspect(texture, x, y, w, h, 1, 1, 1, a)
        else jo:DrawTextureScaledAspect(texture, x, y, w, h, r, g, b, a) end
    end
end
ZeD.LeanDraw = LEAN
local LEAN_NAMES = { "drawRect", "drawRectBorder", "drawText", "drawTextureScaled", "drawTextureScaledAspect" }

local ZED_CLASSES = { "ZeD_Panel", "ZeD_Window", "ZeD_Button", "ZeD_TextInput", "ZeD_TextEntry", "ZeD_SearchField",
    "ZeD_Tooltip", "ZeD_ScrollList", "ZeD_ScrollPanel", "ZeD_ZoneList", "ZeD_Dropdown", "ZeD_Modal", "ZeD_TabPanel",
    "ZeD_ItemGrid", "ZeD_ItemCard", "ZeD_BodyFigure", "ZeD_ContextMenu", "ZeD_ContextList", "ZeD_Dashboard", "ZeD_Watch",
    -- (code audit Oct 17 2026: ZeD classes that derive straight from ISPanel / ISUIElement were
    -- missed and kept hairline borders at 4K. The pixel-art panels (the desk, the CRT glass and
    -- wake, the car radio, the siren controller) stay off this list: their thin lines are art.)
    "ZeD_ObjectCard", "ZeD_FurnitureChip", "ZeD_MMBar", "ZeD_MMDrop", "ZeD_MMIcons" }
-- The lean calls go on every ZeD class (any global "ZeD_*" class table), not only the listed ones:
-- they make the same calls ISUIElement's do for any element. A class keeps a method of its own; the
-- game's Lua keeps a copy of an inherited method on the class table itself, so a raw value equal to
-- ISUIElement's is a copy, not an override, and is replaced too.
local function leanInstall(c)
    local n = 0
    for _, m in ipairs(LEAN_NAMES) do
        local own = rawget(c, m)
        if own == nil or own == ISUIElement[m] then c[m] = LEAN[m]; n = n + 1 end
    end
    return n
end
local function flagZedClasses()
    local n = 0
    for _, name in ipairs(ZED_CLASSES) do
        local c = _G[name]
        if type(c) == "table" then
            c.zedScaled = true
            n = n + 1
        end
    end
    local nc, nm = 0, 0
    for k, v in pairs(_G) do
        if type(v) == "table" and type(k) == "string" and k:sub(1, 4) == "ZeD_" and rawget(v, "Type") == k then
            local got = leanInstall(v)
            if got > 0 then nc, nm = nc + 1, nm + got end
        end
    end
    print("[ZeD] Overrides/TextScale: " .. n .. " ZeD classes draw scaled borders; lean draw calls on " .. nc .. " classes (" .. nm .. ")")
end
if Events and Events.OnGameBoot then Events.OnGameBoot.Add(flagZedClasses) end
if Events and Events.OnGameStart then Events.OnGameStart.Add(flagZedClasses) end   -- (again in game: classes defined late)
flagZedClasses()

-- Text entries: the Java text box under ISTextEntryBox draws its font at the
-- native size, so ZeD entries (flag `zedEntry`: the search fields, note and
-- rename boxes) switch to the baked face that matches the scale, and take the
-- theme's text colours (ZeD.Text.fitEntry). Vanilla entries are untouched.
require "ISUI/ISTextEntryBox"
if ISTextEntryBox and not ISTextEntryBox._zedEntryPatched then
    ISTextEntryBox._zedEntryPatched = true
    local origEntryPrerender = ISTextEntryBox.prerender
    function ISTextEntryBox:prerender()
        if self.zedEntry then X.fitEntry(self) end
        return origEntryPrerender(self)
    end
end
