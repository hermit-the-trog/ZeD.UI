-- ZeD-UI/42/media/lua/client/ZeD/WatchMini.lua
-- ============================================================================
-- THE MINI WATCH ON THE BELT (Oct 19 2026, mockup ZeDUI/mockups/zed_belt_watch_v1;
-- director: "watch move opposite the belt on the primary, secondary icons. left
-- of primary, right of secondary depending on wrist")
--
-- The worn watch, small, outside the hand circle of its wrist (ZeD_Belt lays
-- it out). Its case is pixel art made by ZeDUI/tools/physpx/d_miniwatch.py,
-- 44 x 46 texels, one per plate, with night and Indiglow variants; the time is
-- drawn here, live, over the blank LCD or dial:
--   digital  the time in seven segments, the alarm dot, three speed marks
--            (hollow while paused), the run light on the case
--   analogue the hour and minute hands
-- The pushers are the full watch's: SPEED and START on the case's sides (at 8
-- and 4 o'clock on a round one), the crown lights a Timez; the face pops the
-- full watch up (ZeD_Watch.lua), a second press tucks it back.
-- ============================================================================

ZeD = ZeD or {}
ZeD.WatchMini = ZeD.WatchMini or {}
local M = ZeD.WatchMini

M.W, M.H = 44, 46
local DIR = "media/textures/ZeD/physpx/mini/"
local NEAREST = 3

local function rgb(h)
    local n = tonumber(h:sub(2), 16)
    return { r = math.floor(n / 65536) / 255, g = (math.floor(n / 256) % 256) / 255, b = (n % 256) / 255 }
end

-- per plate: the case kind and the live parts' colours (d_miniwatch.py has the art's)
M.SPEC = {
    digital_black = { kind = "digital", fg = rgb("#e8e8e8"), off = rgb("#161616"), nightFg = rgb("#8c8c8c") },
    digital_gold  = { kind = "digital", fg = rgb("#1e2416"), off = rgb("#b4b89c"), nightFg = rgb("#1a1e14") },
    timez_red     = { kind = "digital", fg = rgb("#1e2416"), off = rgb("#b8c0a0"), nightFg = rgb("#1a1e14"), light = true },
    timez_steel   = { kind = "digital", fg = rgb("#1e2416"), off = rgb("#b8c0a0"), nightFg = rgb("#1a1e14"), light = true },
    classic_black = { kind = "analog", ink = rgb("#e8e8e8"), nightInk = rgb("#7a7a7a") },
    classic_gold  = { kind = "analog", ink = rgb("#1e2022"), nightInk = rgb("#0e1011") },
    timez_easy    = { kind = "analog", ink = rgb("#1e2022"), nightInk = rgb("#0e1011"), light = true },
    timez_camper  = { kind = "analog", ink = rgb("#f0f0f0"), nightInk = rgb("#8a8a8a"), light = true },
    expensive     = { kind = "analog", ink = rgb("#2a2a2a"), nightInk = rgb("#7ef08a"), glow = true },   -- Rollex: hands glow in the dark
}
local LIT_INK = rgb("#0d3a36")
local RED, GREEN, GREEN_DIM = rgb("#d03030"), rgb("#44ee44"), rgb("#2a8a2a")

local _tex = {}
local function tex(name)
    local t = _tex[name]
    if t == nil then
        t = Texture.getSharedTexture(DIR .. name .. ".png", NEAREST) or false
        _tex[name] = t
    end
    return t or nil
end

function M.has(plate) return M.SPEC[plate] ~= nil and tex(plate) ~= nil end

-- the whole multiple the texels draw at, and the art's offset in a px(44) x px(46) box
local function fit()
    local T = ZeD.T
    local ck = math.max(1, math.floor(T.scale or 1))
    return ck, math.floor((T.px(M.W) - M.W * ck) / 2), math.floor((T.px(M.H) - M.H * ck) / 2)
end

-- ---------------------------------------------------------------------------
-- seven segments, 4 x 7 texels, one thick
-- ---------------------------------------------------------------------------
local SEG = { ["0"] = "abcdef", ["1"] = "bc", ["2"] = "abged", ["3"] = "abgcd", ["4"] = "fgbc", ["5"] = "afgcd",
              ["6"] = "afgedc", ["7"] = "abc", ["8"] = "abcdefg", ["9"] = "abcdfg" }
local SEGR = { a = { 1, 0, 2, 1 }, d = { 1, 6, 2, 1 }, g = { 1, 3, 2, 1 },
               f = { 0, 1, 1, 2 }, b = { 3, 1, 1, 2 }, e = { 0, 4, 1, 2 }, c = { 3, 4, 1, 2 } }

local function px(p, X, Y, ck, tx, ty, tw, th, cl, a)
    p:drawRect(X + tx * ck, Y + ty * ck, tw * ck, th * ck, a or 1, cl.r, cl.g, cl.b)
end

local function digits(p, X, Y, ck, s, x, y, cl)
    for i = 1, #s do
        local ch = s:sub(i, i)
        if ch == ":" then
            px(p, X, Y, ck, x, y + 2, 1, 1, cl); px(p, X, Y, ck, x, y + 4, 1, 1, cl)
            x = x + 2
        elseif ch == " " then
            x = x + 5
        else
            local segs = SEG[ch] or ""
            for j = 1, #segs do
                local r = SEGR[segs:sub(j, j)]
                px(p, X, Y, ck, x + r[1], y + r[2], r[3], r[4], cl)
            end
            x = x + 5
        end
    end
end
local function strW(s)
    local w = 0
    for i = 1, #s do w = w + ((s:sub(i, i) == ":") and 2 or 5) end
    return w - 1
end

-- a hand: the texels along the line from the centre, w wide
local function hand(p, X, Y, ck, ang, len, w, cl)
    local a = math.rad(ang - 90)
    local cx, cy = 21.5, 23
    local dx, dy = math.cos(a), math.sin(a)
    local seen = {}
    for t = 0, len * 2 do
        local d = t / 2
        for o = 0, w - 1 do
            local ox = (o == 0) and 0 or -dy * 0.7
            local oy = (o == 0) and 0 or dx * 0.7
            local tx, ty = math.floor(cx + dx * d + ox), math.floor(cy + dy * d + oy)
            local key = tx * 100 + ty
            if not seen[key] then seen[key] = true; px(p, X, Y, ck, tx, ty, 1, 1, cl) end
        end
    end
end

-- st: hour, minute (24 h), fmt24, speed (0 = paused), armed, dark, lit
function M.draw(p, x, y, plate, st)
    local spec = M.SPEC[plate]
    if not spec then return end
    local ck, ox, oy = fit()
    local X, Y = x + ox, y + oy
    local variant = plate
    if st.lit and spec.light then variant = plate .. "_lit" elseif st.dark then variant = plate .. "_night" end
    local t = tex(variant) or tex(plate)
    if t then p:drawTextureScaledAspect(t, X, Y, M.W * ck, M.H * ck, 1, 1, 1, 1) end
    if spec.kind == "digital" then
        local fg = (st.lit and spec.light) and LIT_INK or (st.dark and spec.nightFg or spec.fg)
        local h = st.hour
        if not st.fmt24 then h = h % 12; if h == 0 then h = 12 end end
        local s = string.format("%2d:%02d", h, st.minute)
        digits(p, X, Y, ck, s, 8 + math.floor((28 - strW(s)) / 2), 21, fg)
        if st.armed then px(p, X, Y, ck, 10, 20, 1, 1, RED) end
        for i = 0, 2 do
            local mx = 17 + i * 4
            if st.speed == 0 then px(p, X, Y, ck, mx, 30, 1, 1, fg)
            else px(p, X, Y, ck, mx, 30, 2, 1, (i < st.speed) and fg or spec.off) end
        end
        if st.speed > 0 then px(p, X, Y, ck, 5, 30, 1, 1, st.dark and GREEN_DIM or GREEN) end
    else
        local ink = (st.lit and spec.light) and LIT_INK or (st.dark and spec.nightInk or spec.ink)
        hand(p, X, Y, ck, ((st.hour % 12) + st.minute / 60) * 30, 7, 2, ink)
        hand(p, X, Y, ck, st.minute * 6, 11, 1, ink)
        px(p, X, Y, ck, 21, 23, 1, 1, RED)
    end
end

-- the control under a point in the box (screen px from the box's corner):
-- "speed", "start", "light" (a Timez's crown), "face", or nil
function M.hit(plate, lx, ly)
    local spec = M.SPEC[plate]
    if not spec then return nil end
    local ck, ox, oy = fit()
    local tx, ty = (lx - ox) / ck, (ly - oy) / ck
    if tx < 0 or ty < 0 or tx >= M.W or ty >= M.H then return nil end
    if spec.kind == "digital" then
        if ty >= 16 and ty < 30 then
            if tx < 6 then return "speed" end
            if tx >= 38 then return "start" end
        end
    else
        if ty >= 28 and ty < 40 then
            if tx < 10 then return "speed" end
            if tx >= 33 then return "start" end
        end
        if spec.light and tx >= 38 and ty >= 19 and ty < 28 then return "light" end
    end
    if ty >= 6 and ty < 40 then return "face" end
    return nil
end
