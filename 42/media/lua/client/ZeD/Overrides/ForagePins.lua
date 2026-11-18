-- ZeD-UI/42/media/lua/client/ZeD/Overrides/ForagePins.lua
-- ============================================================================
-- FORAGING PINS AND THE SEARCH-MODE EYE (override, client)
-- Design's handoff of Nov 17 2026 (ZeDUI/HANDOFF_design_overhead_icons_pins_20261117.md, sets A and B; art in
-- ZeDUI/art/overhead_20261117/).
--
-- A. The pins. In search mode the game marks a find (a forage find, a world item, a map's stash) with a pin, and
--    every kind of pin draws through one function, ISBaseIcon:renderPinIcon (media/lua/client/Foraging/ISBaseIcon.lua;
--    ISForageIcon, ISWorldItemIcon, ISWorldItemIconTrack and ISStashIcon inherit it). ZeD's pin is a magnifying glass
--    with the find in its lens (the director, Nov 15: "the icon showing what the item discovered is ... behind a
--    magnifying glass"), three layers on the game's own 60 x 90 canvas, so the game's size, position, bounce and fade
--    code is untouched. In canvas units, s = width / 60:
--      1. pinB_back over the whole pin;
--      2. identified (the game's own test: itemTexture, identified, renderItemTexture): the item centered on the
--         lens at (29, 26), at its own size up to 32 units (a larger one fitted to 32 on its longer side, never
--         stretched up; the game drew it at two thirds), then pinB_glass over it (it redraws the rim, so an item's
--         corners never show past it), then, for a known poison, poison_mark 12 x 12 at (42, 36);
--      3. not identified: pinB_unknown, the frosted lens with the "?", and no item.
--    Every layer keeps the game's alpha and textureColor. (pinB_hint, a half-frosted lens, is drawn but unused: the
--    game has only identified or not, and a blurred find would tell more than the game does. Design's note.)
-- B. The eye. The game draws its search-mode eye over the head itself (ISSearchManager:renderEye). ZeD draws it
--    as a note in its over-head stack (ZeD_Bubbles: the eye note, just above the speed bubble), so here the game's
--    own drawing is stopped. The same texture is also the eye in the game's search window; that one is untouched.
-- Both are the game's own again in safe mode. A failure drawing ZeD's pin draws the game's for that frame.
-- ============================================================================

require "Foraging/ISBaseIcon"
require "Foraging/ISSearchManager"
require "ZeD/SafeMode"

local DIR = "media/textures/ZeD/forage/"
local CANVAS_W = 60          -- the pin's canvas, as the game's pins: 60 x 90 units at zoom 1
local LENS_X, LENS_Y = 29, 26
local ITEM_MAX = 32
local MARK_X, MARK_Y, MARK_S = 42, 36, 12

local tex = {}
local function T(name)
    local t = tex[name]
    if t == nil then
        t = getTexture(DIR .. name .. ".png") or false
        tex[name] = t
    end
    return t or nil
end

-- A. the pin
if ISBaseIcon and ISBaseIcon.renderPinIcon then
    -- the original, kept once (a Lua reload of this file must not wrap the wrapper)
    ISBaseIcon._zedOrigRenderPinIcon = ISBaseIcon._zedOrigRenderPinIcon or ISBaseIcon.renderPinIcon
    local _orig = ISBaseIcon._zedOrigRenderPinIcon

    local function zedPin(self)
        local back, glass, unknown = T("pinB_back"), T("pinB_glass"), T("pinB_unknown")
        if not (back and glass and unknown) then return false end
        local tc = self.textureColor
        local a = self:getAlpha()
        local w, h = self.width, self.height
        local s = w / CANVAS_W
        if self.itemTexture and self.identified and self.renderItemTexture then
            self:drawTextureScaled(back, 0, 0, w, h, a, tc.r, tc.g, tc.b)
            local it = self.itemTexture
            local iw, ih = it:getWidth(), it:getHeight()
            local long = math.max(iw, ih)
            local f = (long > ITEM_MAX) and (ITEM_MAX / long) or 1
            local dw, dh = iw * f * s, ih * f * s
            self:drawTextureScaled(it, LENS_X * s - dw / 2, LENS_Y * s - dh / 2, dw, dh, a, tc.r, tc.g, tc.b)
            self:drawTextureScaled(glass, 0, 0, w, h, a, tc.r, tc.g, tc.b)
            if self.isKnownPoison then
                local mark = T("poison_mark")
                if mark then
                    self:drawTextureScaled(mark, MARK_X * s, MARK_Y * s, MARK_S * s, MARK_S * s, a, tc.r, tc.g, tc.b)
                end
            end
        else
            self:drawTextureScaled(unknown, 0, 0, w, h, a, tc.r, tc.g, tc.b)
        end
        return true
    end

    function ISBaseIcon:renderPinIcon()
        if ZeD.Safe.on() then return _orig(self) end   -- safe mode: the game's pin
        local ok, drawn = pcall(zedPin, self)
        if ok and drawn then return end
        if not ok and ZeD.Safe.fault then ZeD.Safe.fault("forage pin", drawn) end
        return _orig(self)
    end
end

-- B. the game's own eye over the head: ZeD's over-head stack draws it instead
if ISSearchManager and ISSearchManager.renderEye then
    ISSearchManager._zedOrigRenderEye = ISSearchManager._zedOrigRenderEye or ISSearchManager.renderEye
    local _origEye = ISSearchManager._zedOrigRenderEye

    function ISSearchManager:renderEye()
        if ZeD.Safe.on() then return _origEye(self) end   -- safe mode: the game's eye
    end
end

print("[ZeD] Overrides/ForagePins: search-mode pins are magnifying glasses; the eye is in ZeD's over-head stack")
