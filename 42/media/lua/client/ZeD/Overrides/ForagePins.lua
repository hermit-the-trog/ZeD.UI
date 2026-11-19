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
-- A2. The pointer to a find: the game's homing point dressed as Design's hand from the cloud (below).
-- B. The eye. The game draws its search-mode eye over the head itself (ISSearchManager:renderEye). ZeD draws it
--    as a note in its over-head stack (ZeD_Bubbles: the eye note, just above the speed bubble), so here the game's
--    own drawing is stopped. The same texture is also the eye in the game's search window; that one is untouched.
-- Both are the game's own again in safe mode. A failure drawing ZeD's pin draws the game's for that frame.
-- ============================================================================

require "Foraging/ISBaseIcon"
require "Foraging/ISSearchManager"
require "Foraging/ISWorldItemIcon"
require "Foraging/ISStashIcon"
require "Foraging/ISWorldItemIconTrack"
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

-- A2. the pointer to a find: the hand from the cloud (the director, Nov 17: "Pixel, please")
-- The game points at a near, seen, forageable find with a homing point (ISBaseIcon:addWorldMarker:
-- getWorldMarkers():addPlayerHomingPoint). Its Java places it, turns it toward the find, eases it along, fades it in
-- fog and keeps it on the screen: 130 px out from the character, or by the find itself while the find is on screen
-- and within 20 tiles (WorldMarkers$PlayerHomingPoint, read from 42.21's jar). Lua cannot read where it is, but it
-- can change its picture (setTexture, a name under media/textures/highlights/) and its size, so ZeD keeps the
-- game's marker and all of that, and dresses it as the hand: white at full alpha in place of the game's grey, the
-- picture 44 x 77 (Design's 77 x 44 pixel hand turned upright, as the game's arrow points up before it is turned).
-- The game turns the picture right round, so one hand pointing left would hang with its thumb underneath. Two
-- upright hands: zed_forage_hand_up_a (thumb at its left) while the find is to the right of the character on
-- screen, zed_forage_hand_up_b (its mirror) while it is to the left; turned to point, each has its thumb on top.
-- Safe mode puts the game's arrow back, grey, on the next update.
local HAND_A, HAND_B = "zed_forage_hand_up_a", "zed_forage_hand_up_b"
local HAND_NONE = "zed_forage_hand_none"   -- (an empty picture: a pinned find's pointer, below)
-- (smaller and a little see-through, the director, Nov 18 2026: "scale down the hand of God a little and make it a
-- little bit transparent"; was 44 x 77 at full alpha)
local HAND_W, HAND_H, HAND_ALPHA = 36, 63, 0.40   -- (0.40: "Can the hand of God be more transparent?", Nov 18)
local GAME_ARROW, GAME_W, GAME_H = "arrow_triangle", 32, 32

-- true while the find is to the right of the character on the screen (iso: screen x grows with x - y)
local function findOnRight(self)
    local chr = self.character
    if not (chr and self.xCoord and self.yCoord) then return true end
    local ok, cx, cy = pcall(function() return chr:getX(), chr:getY() end)
    if not ok then return true end
    return (self.xCoord - cx) - (self.yCoord - cy) >= 0
end

-- the marker as ZeD's hand (or, in safe mode, as the game's arrow again); only on a change
local function dress(self)
    local m = self.worldMarker
    if not m then return end
    if ZeD.Safe.on() then
        if self._zedHandOn == m then
            pcall(function() m:setTexture(GAME_ARROW); m:setRenderWidth(GAME_W); m:setRenderHeight(GAME_H) end)
            self._zedHandOn, self._zedHand = nil, nil
        end
        return
    end
    -- (the director, Nov 18 2026: "If there's a magnifying glass pin, it means the image is identified and it
    -- doesn't need a finger pointing at it anymore... The hand should be pointing at things that aren't pinned yet."
    -- A find with any pin, the frosted ? or the glass, is spotted (getIsSeen) and marked on screen: its pointer
    -- wears an empty picture. The game's marker stays, so the game doesn't make it again each update.)
    local pinned = self.getIsSeen and self:getIsSeen()
    local want = pinned and HAND_NONE or (findOnRight(self) and HAND_A or HAND_B)
    if self._zedHandOn == m and self._zedHand == want then return end
    local ok = pcall(function()
        m:setTexture(want)
        if self._zedHandOn ~= m then m:setRenderWidth(HAND_W); m:setRenderHeight(HAND_H) end
    end)
    if ok then self._zedHandOn, self._zedHand = m, want end
end
if ISBaseIcon then ISBaseIcon._zedDressPointer = dress end   -- (the test sim's way in)
if ISBaseIcon then ISBaseIcon._zedHandSize = { HAND_W, HAND_H, HAND_ALPHA } end   -- (the release test reads it)

if ISBaseIcon and ISBaseIcon.addWorldMarker and ISBaseIcon.setWorldMarkerPosition then
    ISBaseIcon._zedOrigAddWorldMarker = ISBaseIcon._zedOrigAddWorldMarker or ISBaseIcon.addWorldMarker
    ISBaseIcon._zedOrigSetWorldMarkerPosition = ISBaseIcon._zedOrigSetWorldMarkerPosition or ISBaseIcon.setWorldMarkerPosition
    local _origAdd, _origSetPos = ISBaseIcon._zedOrigAddWorldMarker, ISBaseIcon._zedOrigSetWorldMarkerPosition

    -- the game's own steps, with white at full alpha in place of its grey (0.8)
    function ISBaseIcon:addWorldMarker()
        if ZeD.Safe.on() then return _origAdd(self) end
        self:updateManagerMarkers()
        if self.isBeingRemoved then return end
        self.worldMarker = getWorldMarkers():addPlayerHomingPoint(self.character, self.xCoord, self.yCoord, 1, 1, 1, HAND_ALPHA)
        self:setWorldMarkerPosition()
    end

    -- run on every update while the marker is up: the game's placement, then the hand for the side the find is on
    function ISBaseIcon:setWorldMarkerPosition()
        _origSetPos(self)
        dress(self)
    end

    -- (QA and the director, Nov 18 2026: "most of them are the vanilla arrows, and I only saw a few of the hands".
    -- Three of the game's finds place their pointer with their own setWorldMarkerPosition, which the wrap above never
    -- reaches: items lying found on the ground (ISWorldItemIcon, the most common), stashes (ISStashIcon) and animal
    -- tracks (ISWorldItemIconTrack). Each one's own placement is wrapped the same way.)
    local SUBS = { "ISWorldItemIcon", "ISStashIcon", "ISWorldItemIconTrack" }
    for _, name in ipairs(SUBS) do
        local cls = _G[name]
        local own = cls and rawget(cls, "setWorldMarkerPosition")
        if own then
            cls._zedOrigSetWorldMarkerPosition = rawget(cls, "_zedOrigSetWorldMarkerPosition") or own
            local orig = cls._zedOrigSetWorldMarkerPosition
            cls.setWorldMarkerPosition = function(self)
                orig(self)
                dress(self)
            end
        end
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

print("[ZeD] Overrides/ForagePins: search-mode pins are magnifying glasses, the pointer to a find is the hand; the eye is in ZeD's over-head stack")
