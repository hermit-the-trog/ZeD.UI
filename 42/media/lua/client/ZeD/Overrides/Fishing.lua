-- ZeD-UI/42/media/lua/client/ZeD/Overrides/Fishing.lua
-- ============================================================================
-- THE LINE'S TENSION (HOOK_MAP row 10; mockup zed_fish_sleep_death v4 / v5,
-- director Oct 16 2026: "more real world item with the fishing rod ... pixel
-- art", "something cool with the dial to show tension", "rings around the rod
-- change color based on tension? Start out white with none", "all three")
--
-- Vanilla's fishing stays: FishingManager makes its tension meter
-- (Fishing.ISTensionUI), shows it while the line is out, hides it when the
-- fish is landed or the line comes in, and feeds it the rod's tension every
-- frame (updateValue: below 0 slack, 0 to 1 the strain, past 1 it snaps).
-- In place of vanilla's little dial over the head, the meter draws the rod in
-- hand at the bottom of the screen, above the belt: a 1980s pistol-grip rod
-- with a low-profile baitcaster (the director's own tackle). Three reads of
-- the same tension: the blank bows deeper, the thread wraps light from the
-- reel toward the tip (white with none, gold, orange, red), and the reel's
-- side-plate dial turns its red pointer into MAX (lit near the limit); the
-- line sags slack, runs straight under load, and goes pale red before it
-- snaps.
--
-- The rod's body is a strip of 17 plate frames by tension (media/textures/
-- ZeD/props/rod_00 .. rod_16.png, 360 x 200 plate pixels; a stand-in from
-- the approved mockup until Design's plate pipeline draws the final art,
-- with the same anchors); the line, the pointer and the MAX glow are drawn
-- live on it, at whole multiples (2 at 1080p, 4 at 4K).
-- ============================================================================

require "Fishing/TensionUI"

if not (Fishing and Fishing.ISTensionUI) then return end
local TUI = Fishing.ISTensionUI

ZeD = ZeD or {}
ZeD.FishRod = ZeD.FishRod or {}
local F = ZeD.FishRod

F.TEXDIR = "media/textures/ZeD/props/rod_"
F.W, F.H = 360, 200
F.FRAMES = 16
-- per frame (tension 0, 1/16 .. 1): the rod tip, where the line leaves the reel, the guides
-- it runs through, the dial (centre x, y, radius) and the MAX printing (x, y, w, h), plate pixels
F.ANCH = {
    { tip = { 263.6, 12.6 }, start = { 110.4, 100.4 }, guides = { { 128.7, 98.8 }, { 165, 74 }, { 193.1, 54.8 }, { 216.2, 39 }, { 234.4, 26.5 }, { 249.2, 16.4 } }, dial = { 66, 121, 15 }, max = { 77, 95, 13, 7 } },
    { tip = { 269.8, 22.4 }, start = { 110.9, 100.9 }, guides = { { 129.5, 99.7 }, { 166.6, 75.9 }, { 195.6, 58 }, { 219.8, 43.8 }, { 239.1, 32.9 }, { 255, 24.4 } }, dial = { 66, 121, 15 }, max = { 78, 95, 13, 7 } },
    { tip = { 275.2, 32.5 }, start = { 111.4, 101.4 }, guides = { { 130.2, 100.6 }, { 168, 77.9 }, { 198, 61.4 }, { 223.2, 48.7 }, { 243.4, 39.6 }, { 260.2, 32.7 } }, dial = { 67, 121, 15 }, max = { 78, 95, 13, 7 } },
    { tip = { 279.8, 43 }, start = { 111.9, 101.9 }, guides = { { 130.9, 101.5 }, { 169.5, 79.9 }, { 200.3, 64.8 }, { 226.4, 53.8 }, { 247.4, 46.5 }, { 264.9, 41.4 } }, dial = { 67, 121, 15 }, max = { 79, 95, 13, 7 } },
    { tip = { 283.7, 53.8 }, start = { 112.4, 102.4 }, guides = { { 131.6, 102.4 }, { 170.9, 81.9 }, { 202.4, 68.3 }, { 229.3, 59.1 }, { 251, 53.6 }, { 269.1, 50.4 } }, dial = { 67, 121, 15 }, max = { 79, 96, 13, 7 } },
    { tip = { 286.7, 64.8 }, start = { 112.8, 102.9 }, guides = { { 132.3, 103.3 }, { 172.2, 84 }, { 204.5, 71.8 }, { 232, 64.5 }, { 254.2, 60.9 }, { 272.6, 59.6 } }, dial = { 68, 121, 15 }, max = { 80, 96, 13, 7 } },
    { tip = { 288.9, 75.9 }, start = { 113.3, 103.4 }, guides = { { 132.9, 104.3 }, { 173.5, 86.1 }, { 206.4, 75.5 }, { 234.5, 70 }, { 257, 68.3 }, { 275.5, 69 } }, dial = { 68, 121, 15 }, max = { 80, 96, 13, 7 } },
    { tip = { 290.3, 87 }, start = { 113.8, 103.9 }, guides = { { 133.6, 105.2 }, { 174.8, 88.2 }, { 208.2, 79.2 }, { 236.7, 75.6 }, { 259.4, 75.9 }, { 277.8, 78.5 } }, dial = { 68, 121, 15 }, max = { 81, 97, 13, 7 } },
    { tip = { 290.8, 98.1 }, start = { 114.2, 104.5 }, guides = { { 134.2, 106.2 }, { 176, 90.3 }, { 209.9, 82.9 }, { 238.7, 81.3 }, { 261.3, 83.6 }, { 279.4, 88.2 } }, dial = { 68, 121, 15 }, max = { 81, 97, 13, 7 } },
    { tip = { 290.5, 109.1 }, start = { 114.7, 105 }, guides = { { 134.9, 107.1 }, { 177.2, 92.5 }, { 211.5, 86.7 }, { 240.4, 87 }, { 262.8, 91.3 }, { 280.4, 97.8 } }, dial = { 69, 121, 15 }, max = { 82, 97, 13, 7 } },
    { tip = { 289.4, 120 }, start = { 115.1, 105.5 }, guides = { { 135.5, 108.1 }, { 178.3, 94.7 }, { 212.9, 90.6 }, { 241.8, 92.9 }, { 263.9, 99.1 }, { 280.8, 107.5 } }, dial = { 69, 122, 15 }, max = { 82, 97, 13, 7 } },
    { tip = { 287.6, 130.5 }, start = { 115.6, 106 }, guides = { { 136.1, 109.1 }, { 179.3, 97 }, { 214.2, 94.5 }, { 243, 98.7 }, { 264.5, 106.9 }, { 280.5, 117.1 } }, dial = { 69, 122, 15 }, max = { 83, 98, 13, 7 } },
    { tip = { 285, 140.8 }, start = { 116, 106.6 }, guides = { { 136.7, 110 }, { 180.4, 99.2 }, { 215.4, 98.4 }, { 243.9, 104.6 }, { 264.7, 114.7 }, { 279.6, 126.6 } }, dial = { 70, 122, 15 }, max = { 83, 98, 13, 7 } },
    { tip = { 281.7, 150.7 }, start = { 116.5, 107.1 }, guides = { { 137.3, 111 }, { 181.3, 101.5 }, { 216.5, 102.4 }, { 244.5, 110.5 }, { 264.4, 122.4 }, { 278, 135.9 } }, dial = { 70, 122, 15 }, max = { 84, 98, 13, 7 } },
    { tip = { 277.7, 160.2 }, start = { 116.9, 107.6 }, guides = { { 137.9, 112 }, { 182.2, 103.8 }, { 217.4, 106.4 }, { 244.9, 116.4 }, { 263.8, 130.1 }, { 275.9, 145 } }, dial = { 70, 122, 15 }, max = { 84, 99, 13, 7 } },
    { tip = { 273.2, 169.1 }, start = { 117.3, 108.2 }, guides = { { 138.4, 113 }, { 183.1, 106.1 }, { 218.1, 110.4 }, { 245, 122.3 }, { 262.7, 137.6 }, { 273.2, 153.8 } }, dial = { 71, 122, 15 }, max = { 85, 99, 13, 7 } },
    { tip = { 268.1, 177.5 }, start = { 117.8, 108.7 }, guides = { { 139, 114.1 }, { 183.9, 108.5 }, { 218.8, 114.5 }, { 244.9, 128.2 }, { 261.2, 145.1 }, { 270, 162.3 } }, dial = { 71, 122, 15 }, max = { 85, 99, 13, 7 } },
}

local A0, A1 = -135, 135                    -- the dial's scale, degrees from straight up
local LINE = { r = 0.914, g = 0.902, b = 0.855 }
local LINE_HOT = { r = 1.0, g = 0.541, b = 0.431 }
local NEEDLE = { r = 0.91, g = 0.251, b = 0.173 }

-- a 1-plate-pixel line (Bresenham) as k x k squares
local function pxLine(self, ox, oy, k, x0, y0, x1, y1, c)
    x0, y0, x1, y1 = math.floor(x0 + 0.5), math.floor(y0 + 0.5), math.floor(x1 + 0.5), math.floor(y1 + 0.5)
    local dx, sx = math.abs(x1 - x0), x0 < x1 and 1 or -1
    local dy, sy = -math.abs(y1 - y0), y0 < y1 and 1 or -1
    local e = dx + dy
    for _ = 1, 2000 do
        self:drawRect(ox + x0 * k, oy + y0 * k, k, k, 1, c.r, c.g, c.b)
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * e
        if e2 >= dy then e = e + dy; x0 = x0 + sx end
        if e2 <= dx then e = e + dx; y0 = y0 + sy end
    end
end

-- the rod at (ox, oy), k screen pixels a plate pixel, for vanilla's tension t
function F.draw(self, ox, oy, k, t)
    local i = 0
    if t > 0 then i = math.floor(math.min(1, t) * F.FRAMES + 0.5) end
    -- nearest filtering (3), so the pixel art stays square at 2x / 4x (Oct 16 2026: getTexture smoothed it)
    local tex = Texture.getSharedTexture(F.TEXDIR .. string.format("%02d", i) .. ".png", 3)
    local a = F.ANCH[i + 1]
    if not (tex and a) then return false end
    self:drawTextureScaledAspect(tex, ox, oy, F.W * k, F.H * k, 1, 1, 1, 1)
    local lc = (t >= 0.9) and LINE_HOT or LINE
    -- the line: reel to each guide, guide to the tip
    local x0, y0 = a.start[1], a.start[2]
    for _, g in ipairs(a.guides) do
        pxLine(self, ox, oy, k, x0, y0, g[1], g[2], lc)
        x0, y0 = g[1], g[2]
    end
    pxLine(self, ox, oy, k, x0, y0, a.tip[1], a.tip[2], lc)
    -- then off the tip to the water: a lazy sag when slack, straight under load
    local tx, ty = a.tip[1], a.tip[2]
    local wx, wy = F.W - 1, F.H - 3
    if t <= 0 then
        local sag = 30 + (-math.max(-1, t)) * 20
        local px, py = tx, ty
        for s = 1, 40 do
            local f = s / 40
            local nx = tx + (wx - tx) * f
            local ny = math.min(F.H - 1, ty + (wy - ty) * f + math.sin(f * math.pi) * sag)
            pxLine(self, ox, oy, k, px, py, nx, ny, lc)
            px, py = nx, ny
        end
    else
        pxLine(self, ox, oy, k, tx, ty, wx, wy, lc)
    end
    -- the dial's pointer: from 0 (slack) round into the red, and the hub over it
    local dcx, dcy, dr = a.dial[1], a.dial[2], a.dial[3]
    local deg = (t <= 0) and (A0 + (1 + math.max(-1, t)) * 12) or (A0 + 30 + math.min(1, t) * (A1 - A0 - 30))
    local rad = deg * math.pi / 180
    pxLine(self, ox, oy, k, dcx, dcy, dcx + (dr - 3) * math.sin(rad), dcy - (dr - 3) * math.cos(rad), NEEDLE)
    self:drawRect(ox + (dcx - 1) * k, oy + (dcy - 2) * k, 3 * k, 5 * k, 1, 0.765, 0.784, 0.804)
    self:drawRect(ox + (dcx - 2) * k, oy + (dcy - 1) * k, 5 * k, 3 * k, 1, 0.765, 0.784, 0.804)
    self:drawRect(ox + (dcx - 1) * k, oy + (dcy - 1) * k, k, k, 1, 0.949, 0.957, 0.965)
    self:drawRect(ox + dcx * k, oy + dcy * k, k, k, 1, 0.078, 0.067, 0.051)
    -- MAX lit near the limit
    if t >= 0.85 then
        local m = a.max
        self:drawRect(ox + m[1] * k, oy + m[2] * k, m[3] * k, m[4] * k, 0.45, 1, 0.353, 0.235)
    end
    return true
end

local _render = TUI._zedOrigRender or TUI.render
TUI._zedOrigRender = _render
local _prerender = TUI._zedOrigPrerender or TUI.prerender
TUI._zedOrigPrerender = _prerender
local _update = TUI._zedOrigUpdateValue or TUI.updateValue
TUI._zedOrigUpdateValue = _update

-- keep vanilla's raw tension as well as its dial angle
function TUI:updateValue(val)
    self.zedTension = val
    return _update(self, val)
end

-- (vanilla's dial face was drawn here; the rod draws in render)
function TUI:prerender() end

function TUI:render()
    local pn = self.playerIndex or 0
    local sx, sy = getPlayerScreenLeft(pn), getPlayerScreenTop(pn)
    local sw, sh = getPlayerScreenWidth(pn), getPlayerScreenHeight(pn)
    local root = (ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root()) or (sh / 1080)
    local k = math.max(1, math.floor(2 * root + 0.001))
    local pw, ph = F.W * k, F.H * k
    -- bottom centre, a little left (the line runs off to the right), clear of the belt
    local ox = sx + math.floor((sw - pw) / 2) - math.floor(40 * root) - self:getAbsoluteX()
    local oy = sy + sh - ph - math.floor(70 * root) - self:getAbsoluteY()
    local ok, drawn = pcall(F.draw, self, ox, oy, k, self.zedTension or 0)
    if not (ok and drawn) then
        if not ok then ZeD.logOnce("fishing rod", drawn) end
        _prerender(self)
        return _render(self)
    end
end

print("[ZeD] Overrides/Fishing: the tension meter is the rod in hand")
