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

local ZED_CLASSES = { "ZeD_Panel", "ZeD_Window", "ZeD_Button", "ZeD_TextInput", "ZeD_TextEntry", "ZeD_SearchField",
    "ZeD_Tooltip", "ZeD_ScrollList", "ZeD_ScrollPanel", "ZeD_ZoneList", "ZeD_Dropdown", "ZeD_Modal", "ZeD_TabPanel",
    "ZeD_ItemGrid", "ZeD_ItemCard", "ZeD_BodyFigure", "ZeD_ContextMenu", "ZeD_Dashboard", "ZeD_Watch" }
local function flagZedClasses()
    local n = 0
    for _, name in ipairs(ZED_CLASSES) do local c = _G[name]; if type(c) == "table" then c.zedScaled = true; n = n + 1 end end
    print("[ZeD] Overrides/TextScale: " .. n .. " ZeD classes draw scaled borders")
end
if Events and Events.OnGameBoot then Events.OnGameBoot.Add(flagZedClasses) end
flagZedClasses()
