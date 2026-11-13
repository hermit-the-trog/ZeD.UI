-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_Surface.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's ZeD_Surface.lua the console uses (18 of
-- its 25 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_Surface.lua by ZeDUI/tools/products/build_luaconsole93.py.
-- Do not edit it here: change ZeD-GUI's file and build again.
-- ============================================================================================================

-- With ZeD-GUI on (mod ZeD_UI; the game can put a backslash before a mod's id), ZeD-GUI's console is the one:
-- this file stops here and defines nothing.
do
    local guiOn = false
    pcall(function()
        local mods = getActivatedMods()
        for i = 0, mods:size() - 1 do
            if string.gsub(tostring(mods:get(i)), "^\\", "") == "ZeD_UI" then guiOn = true end
        end
    end)
    if guiOn then return end
end

require "ISUI/ISUIElement"

LC93 = LC93 or {}
LC93.Surface = LC93.Surface or {}
LC93.Help = LC93.Help or {}
local S = LC93.Surface
local H = LC93.Help

local MAX_CLAIMS = 64
local MAX_CLIPS  = 16

local _clips, _clipN = {}, 0

function S.clip()
    if _clipN <= 0 then return nil end
    return _clips[math.min(_clipN, MAX_CLIPS)]
end

function S.windowOf(panel)
    local p = panel
    local guard = 0
    while p and guard < 32 do
        if p.isLC93Window then return p end
        p = p.parent
        guard = guard + 1
    end
    return nil
end

function S.beginFrame(win)
    local cur = win._srfCur or { n = 0 }
    local prev = win._srfPrev or { n = 0 }
    prev.n = 0
    win._srfPrev, win._srfCur = cur, prev
end

local function claim(win, x0, y0, x1, y1)
    local c = win._srfCur
    if not c then c = { n = 0 }; win._srfCur = c end
    if c.n >= MAX_CLAIMS then return end
    local ww, wh = win:getWidth(), win:getHeight()
    if x0 < 0 then x0 = 0 end
    if y0 < 0 then y0 = 0 end
    if x1 > ww then x1 = ww end
    if y1 > wh then y1 = wh end
    if x1 <= x0 or y1 <= y0 then return end
    local b = c.n * 4
    c[b + 1], c[b + 2], c[b + 3], c[b + 4] = x0, y0, x1, y1
    c.n = c.n + 1
end

local function claimRect(panel, x, y, w, h)
    local win = S.windowOf(panel)
    if not win then return end
    local px0, py0 = math.max(0, x), math.max(0, y)
    local px1, py1 = math.min(panel:getWidth(), x + w), math.min(panel:getHeight(), y + h)
    if panel ~= win then
        local jo = panel.javaObject
        local sx = jo and jo:getXScroll() or 0
        local sy = jo and jo:getYScroll() or 0
        px0, py0 = math.max(0, x + sx), math.max(0, y + sy)
        px1, py1 = math.min(panel:getWidth(), x + w + sx), math.min(panel:getHeight(), y + h + sy)
        local dx = panel:getAbsoluteX() - win:getAbsoluteX()
        local dy = panel:getAbsoluteY() - win:getAbsoluteY()
        px0, px1, py0, py1 = px0 + dx, px1 + dx, py0 + dy, py1 + dy
    end
    local c = S.clip()
    if c then
        local wx, wy = win:getAbsoluteX(), win:getAbsoluteY()
        if px0 < c.x0 - wx then px0 = c.x0 - wx end
        if py0 < c.y0 - wy then py0 = c.y0 - wy end
        if px1 > c.x1 - wx then px1 = c.x1 - wx end
        if py1 > c.y1 - wy then py1 = c.y1 - wy end
    end
    claim(win, math.floor(px0 + 0.5), math.floor(py0 + 0.5), math.floor(px1 + 0.5), math.floor(py1 + 0.5))
end

function S.fill(panel, x, y, w, h, tokenName)
    if not panel or w <= 0 or h <= 0 then return end
    local T = LC93.T
    local col = T[tokenName or "surf2"] or T.surf2
    panel:drawRect(x, y, w, h, col.a or 1, col.r, col.g, col.b)
    claimRect(panel, x, y, w, h)
end

local bufA, bufB = {}, {}
function S.drawBody(win, x, y, w, h, tokenName)
    if w <= 0 or h <= 0 then return end
    local T = LC93.T
    local col = T[tokenName or "surf1"] or T.surf1
    local a, r, g, b = col.a or 1, col.r, col.g, col.b
    local prev = win._srfPrev
    if not prev or prev.n == 0 then
        win:drawRect(x, y, w, h, a, r, g, b)
        return
    end
    local src, dst = bufA, bufB
    src[1], src[2], src[3], src[4] = x, y, x + w, y + h
    local n = 1
    for k = 0, prev.n - 1 do
        local kb = k * 4
        local cx0, cy0, cx1, cy1 = prev[kb + 1], prev[kb + 2], prev[kb + 3], prev[kb + 4]
        local m = 0
        for i = 0, n - 1 do
            local ib = i * 4
            local x0, y0, x1, y1 = src[ib + 1], src[ib + 2], src[ib + 3], src[ib + 4]
            if cx1 <= x0 or cx0 >= x1 or cy1 <= y0 or cy0 >= y1 then
                local o = m * 4
                dst[o + 1], dst[o + 2], dst[o + 3], dst[o + 4] = x0, y0, x1, y1
                m = m + 1
            else
                local my0 = (cy0 > y0) and cy0 or y0
                local my1 = (cy1 < y1) and cy1 or y1
                if cy0 > y0 then local o = m * 4; dst[o + 1], dst[o + 2], dst[o + 3], dst[o + 4] = x0, y0, x1, cy0; m = m + 1 end
                if cy1 < y1 then local o = m * 4; dst[o + 1], dst[o + 2], dst[o + 3], dst[o + 4] = x0, cy1, x1, y1; m = m + 1 end
                if cx0 > x0 then local o = m * 4; dst[o + 1], dst[o + 2], dst[o + 3], dst[o + 4] = x0, my0, cx0, my1; m = m + 1 end
                if cx1 < x1 then local o = m * 4; dst[o + 1], dst[o + 2], dst[o + 3], dst[o + 4] = cx1, my0, x1, my1; m = m + 1 end
            end
        end
        src, dst = dst, src
        n = m
        if n == 0 then return end
    end
    for i = 0, n - 1 do
        local ib = i * 4
        local x0, y0 = src[ib + 1], src[ib + 2]
        win:drawRect(x0, y0, src[ib + 3] - x0, src[ib + 4] - y0, a, r, g, b)
    end
end

function H.set(panel, text)
    if text == nil or text == "" then return end
    local win = S.windowOf(panel)
    if win then win._helpText = tostring(text) end
end

function H.take(win)
    local t = win._helpText
    win._helpText = nil
    if t and t ~= "" then return t end
    if win.getStatusLine then
        local ok, s = pcall(win.getStatusLine, win)
        if ok and s and s ~= "" then return tostring(s) end
    end
    return nil
end
