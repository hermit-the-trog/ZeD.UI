-- LuaConsole93/42/media/lua/client/LuaConsole93/LC93_FocusPaint.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's ZeD_FocusPaint.lua the console uses (28
-- of its 31 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/ZeD_FocusPaint.lua by
-- ZeDUI/tools/products/build_luaconsole93.py. Do not edit it here: change ZeD-GUI's file and build again.
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

LC93 = LC93 or {}
LC93.Focus = LC93.Focus or {}
local FP = LC93.Focus

local STYLES   = { hand = true, corners = true, wash = true, ants = true }
local WASH_A   = 0.55
local SHADOW_A = 0.45
local STALE_MS = 150
local NO_OPTS  = {}

local HAND = {
    "   ####         ",
    "  #....#########",
    " #.............#",
    "#..............#",
    "#.....######### ",
    "#......#        ",
    "#.....##        ",
    "#......#        ",
    "#.....##        ",
    " #....#         ",
    "  ####          ",
}
local HAND_W, HAND_H = 16, 11
local _handRuns, _handSil = {}, {}
for r = 1, HAND_H do
    local row = HAND[r]
    local runs, cur, c0, first, last = {}, nil, 1, nil, nil
    for c = 1, HAND_W + 1 do
        local ch = (c <= #row) and row:sub(c, c) or " "
        if ch ~= " " then
            if not first then first = c end
            last = c
        end
        if ch ~= cur then
            if cur == "#" or cur == "." then runs[#runs + 1] = { c0 - 1, c - c0, cur == "#" } end
            cur, c0 = ch, c
        end
    end
    _handRuns[r] = runs
    _handSil[r] = first and { first - 1, last - first + 1 } or false
end

local function artK()
    local TP = LC93.TabPx
    if TP and TP.k then return TP.k() end
    local Sc = LC93.Scale
    local s = (Sc and Sc.root and Sc.root()) or 1
    return math.max(1, math.floor(s + 0.5))
end

local function drawHand(p, x, y, h, minTop)
    local k = artK()
    local ax = x - HAND_W * k
    local ay = y + math.floor((h - HAND_H * k) / 2)
    if minTop and ay < minTop then ay = minTop end
    for r = 1, HAND_H do
        local s = _handSil[r]
        if s then p:drawRect(ax + (s[1] + 1) * k, ay + r * k, s[2] * k, k, SHADOW_A, 0, 0, 0) end
    end
    for r = 1, HAND_H do
        local ry = ay + (r - 1) * k
        for _, run in ipairs(_handRuns[r]) do
            local v = run[3] and 0 or 1
            p:drawRect(ax + run[1] * k, ry, run[2] * k, k, 1, v, v, v)
        end
    end
end

local _arms = {}
local function drawCorners(p, x, y, w, h)
    local T = LC93.T
    local L, t, o, e = T.px(6), T.px(2), T.px(3), T.hair
    local X0, Y0, X1, Y1 = x - o, y - o, x + w + o, y + h + o
    local a = _arms
    a[1], a[2], a[3], a[4]     = X0, Y0, L, t
    a[5], a[6], a[7], a[8]     = X0, Y0, t, L
    a[9], a[10], a[11], a[12]  = X1 - L, Y0, L, t
    a[13], a[14], a[15], a[16] = X1 - t, Y0, t, L
    a[17], a[18], a[19], a[20] = X0, Y1 - t, L, t
    a[21], a[22], a[23], a[24] = X0, Y1 - L, t, L
    a[25], a[26], a[27], a[28] = X1 - L, Y1 - t, L, t
    a[29], a[30], a[31], a[32] = X1 - t, Y1 - L, t, L
    for i = 1, 32, 4 do p:drawRect(a[i] - e, a[i + 1] - e, a[i + 2] + 2 * e, a[i + 3] + 2 * e, 1, 0, 0, 0) end
    local c = T.accentBright or T.accent
    for i = 1, 32, 4 do p:drawRect(a[i], a[i + 1], a[i + 2], a[i + 3], c.a or 1, c.r, c.g, c.b) end
end

local function antsEdge(p, horiz, rev, ex, ey, len, s0, phase, period, dash, u)
    if len <= 0 then return end
    if horiz then p:drawRect(ex, ey, len, u, 1, 1, 1, 1) else p:drawRect(ex, ey, u, len, 1, 1, 1, 1) end
    local q = s0 - phase
    local ds = -(q - math.floor(q / period) * period)
    while ds < len do
        local a0, a1 = math.max(0, ds), math.min(len, ds + dash)
        if a1 > a0 then
            if rev then a0, a1 = len - a1, len - a0 end
            if horiz then p:drawRect(ex + a0, ey, a1 - a0, u, 1, 0, 0, 0)
            else p:drawRect(ex, ey + a0, u, a1 - a0, 1, 0, 0, 0) end
        end
        ds = ds + period
    end
end

local function drawAnts(p, x, y, w, h)
    local T = LC93.T
    local u, o, dash = T.hair, T.px(2), T.px(2)
    local period = dash * 2
    local phase = ((getTimestampMs() or 0) / 1000) * T.px(8)
    local X0, Y0, W, H = x - o, y - o, w + 2 * o, h + 2 * o
    antsEdge(p, true,  false, X0, Y0, W, 0, phase, period, dash, u)
    antsEdge(p, false, false, X0 + W - u, Y0 + u, H - u, W, phase, period, dash, u)
    antsEdge(p, true,  true,  X0, Y0 + H - u, W - u, W + H - u, phase, period, dash, u)
    antsEdge(p, false, true,  X0, Y0 + u, H - 2 * u, 2 * W + H - 2 * u, phase, period, dash, u)
end

local function fillShape(p, x, y, w, h, c, a, rounded)
    if rounded and LC93.Atoms and LC93.Atoms.fillRounded then
        LC93.Atoms.fillRounded(p, x, y, w, h, c.r, c.g, c.b, a)
    else
        p:drawRect(x, y, w, h, a, c.r, c.g, c.b)
    end
end

local function paintUnder(p, x, y, w, h, style, solid, rounded)
    local T = LC93.T
    if style == "wash" then
        if solid then
            local c = T.textOnFocus or T.text
            LC93.Atoms.frame(p, x, y, w, h, c, 1, T.line(2))
            return false
        end
        fillShape(p, x, y, w, h, T.accent, WASH_A, rounded)
        return true
    end
    if not solid then
        local hv = T.hover
        fillShape(p, x, y, w, h, hv, hv.a or 0.2, rounded)
    end
    return false
end

local function paintOver(p, x, y, w, h, style, minTop)
    if style == "hand" then drawHand(p, x, y, h, minTop)
    elseif style == "corners" then drawCorners(p, x, y, w, h)
    elseif style == "ants" then drawAnts(p, x, y, w, h) end
end

function FP.style()
    local S = LC93.Settings
    local st = S and S.focusStyle and S.focusStyle() or "hand"
    if not STYLES[st] then st = "hand" end
    return st
end

function FP.isShowing(win, opts)
    opts = opts or NO_OPTS
    local F = LC93.Input and LC93.Input.Focus
    local pad = opts.pad
    if pad == nil then
        if F and F.cuesVisible then
            pad = F.cuesVisible()
        else
            local D = LC93.Input and LC93.Input.Detector
            pad = (D and D.getMode and D.getMode() == "gamepad") or false
        end
    end
    if not pad then return false end
    if opts.focused then return true end
    return win ~= nil and F ~= nil and F.getFocusedWindow ~= nil and F.getFocusedWindow() == win
end

local _marks = {}

function FP.mark(panel, x, y, w, h, opts, rounded)
    if not panel or not LC93.T then return false end
    if type(opts) ~= "table" then opts = NO_OPTS end
    local win = opts.win or (LC93.Atoms and LC93.Atoms.windowOf and LC93.Atoms.windowOf(panel)) or panel
    if not FP.isShowing(win, opts) then return false end
    local swap = paintUnder(panel, x, y, w, h, FP.style(), opts.solid, rounded)
    local rec = _marks[win]
    if not rec then rec = {}; _marks[win] = rec end
    rec.x, rec.y, rec.w, rec.h = panel:getAbsoluteX() + x, panel:getAbsoluteY() + y, w, h
    rec.solid, rec.zone, rec.t, rec.panel = opts.solid and true or false, opts.zone, getTimestampMs(), panel
    return swap
end

local function takeRecord(win)
    local rec = _marks[win]
    if rec then _marks[win] = nil; return rec end
    local A = LC93.Atoms
    if not (A and A.isAncestor) then return nil end
    for k, r in pairs(_marks) do
        if r.panel and A.isAncestor(win, r.panel) then _marks[k] = nil; return r end
    end
    return nil
end

local function handMinTop(ov, win, x, y, h)
    if not (win and win.closeRect and win.titleBarHeight) or win._closeOnRod then return nil end
    local cb = win:closeRect()
    if not cb then return nil end
    local k = artK()
    local hx0, hx1 = x - HAND_W * k, x
    local hy0 = y + math.floor((h - HAND_H * k) / 2)
    local hy1 = hy0 + (HAND_H + 1) * k
    local dx, dy = win:getAbsoluteX() - ov:getAbsoluteX(), win:getAbsoluteY() - ov:getAbsoluteY()
    local bx0, by0 = dx + cb.x, dy + cb.y
    if hx1 <= bx0 or hx0 >= bx0 + cb.w or hy1 <= by0 or hy0 >= by0 + cb.h then return nil end
    return dy + win:titleBarHeight()
end

function FP.drawOverlay(ov, win)
    if not ov or not LC93.T then return end
    win = win or ov
    local rec = takeRecord(win)
    if rec and (getTimestampMs() - (rec.t or 0)) <= STALE_MS then
        local style = FP.style()
        local x, y = rec.x - ov:getAbsoluteX(), rec.y - ov:getAbsoluteY()
        local minTop = (style == "hand") and handMinTop(ov, win, x, y, rec.h) or nil
        paintOver(ov, x, y, rec.w, rec.h, style, minTop)
    end
    local A = LC93.Atoms
    if A and A.drawPendingHover then A.drawPendingHover(ov, win) end
end
