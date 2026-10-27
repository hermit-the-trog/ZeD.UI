-- ZeD-UI/42/media/lua/client/ZeD/ZeD_FocusPaint.lua
-- ============================================================================
-- CONTROLLER FOCUS MARKS (cohesion spec 5 and 6)
-- One way to say "the controller is here", in the look the player picks in ZeD
-- setup or the window box (ZeD.Settings.focusStyle):
--   hand     the hover wash under the element and a pixel pointing hand at its
--            left, the fingertip touching the element's left edge (the default)
--   corners  the hover wash and four L marks just outside the element's corners
--   wash     one 0.55 accent wash, its words in textOnFocus; on an element that is
--            already solid accent, a 2u ring inside its edge instead
--   ants     the hover wash and a marching dashed rectangle just outside it
-- On a solid element (already solid accent: a primary key, the active tab) the
-- hover wash is left out; the hand, corners and ants still show.
--
-- A mark has two parts. The part under the words (the washes, the ring) is drawn
-- by ZeD.Focus.mark at the moment the surface draws its focused element, before
-- its words. The part on top (the hand, the corners, the ants) is drawn by
-- ZeD.Focus.drawOverlay in the window's overlay pass, after all of the window's
-- children, so a neighbour drawn later never covers it and it may cross the
-- window's edge. mark records the element's screen rect for that pass; the record
-- is used once and only in the frame it was made, so a mark never lingers.
--
-- Marks show only while the controller is in use (ZeD.Input.Focus.cuesVisible:
-- a pad press is newer than the last mouse use) and only in the focused window.
--
-- How a surface uses it, at its focused element, after the element's own fill:
--   local onFocus = ZeD.Focus.mark(self, x, y, w, h, { win = win, solid = isActive })
--   local tc = onFocus and T.textOnFocus or T.text      -- then draw the words in tc
-- Windows: the window's overlay child calls ZeD.Focus.drawOverlay(overlay, win).
-- HUD panels without that overlay (the belt, the dash) call
--   ZeD.Focus.drawOverlay(self, self) at the end of their own render.
-- Surfaces with a focus model of their own (prompts, the keyboard, main menu
-- screens, the belt) pass focused = true (they have decided the element has the
-- focus) and, where FocusManager does not run (the main menu), pad = their own
-- controller test (MM.gamepad()).
-- ============================================================================

ZeD = ZeD or {}
ZeD.Focus = ZeD.Focus or {}
local FP = ZeD.Focus

local STYLES   = { hand = true, corners = true, wash = true, ants = true }
local WASH_A   = 0.55   -- the one-wash style (words on it switch to textOnFocus)
local SHADOW_A = 0.45   -- the hand's shadow
local STALE_MS = 150    -- a record older than this was made in an earlier frame
local NO_OPTS  = {}

-- ---------------------------------------------------------------------------
-- The pointing hand: 16 x 11 art pixels, # black, . white (spec 6). Each row is
-- turned once into runs of one colour, and its silhouette for the shadow, so a
-- frame draws about fifty rects.
-- ---------------------------------------------------------------------------
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

-- one art pixel in screen pixels: the whole multiple of the root scale the
-- window tabs' pixel art uses (ZeD_TabPx.k)
local function artK()
    local TP = ZeD.TabPx
    if TP and TP.k then return TP.k() end
    local Sc = ZeD.Scale
    local s = (Sc and Sc.root and Sc.root()) or 1
    return math.max(1, math.floor(s + 0.5))
end

-- the hand with its fingertip touching (x, ...) and centred on the rect's height;
-- minTop (optional) keeps its top at or below that line
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

-- four L marks 3u outside the corners: arms 6u long, 2u thick, accentBright
-- with a 1u black edge
local _arms = {}
local function drawCorners(p, x, y, w, h)
    local T = ZeD.T
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

-- one edge of the marching ants: white, then the black dashes where the
-- perimeter position s (s0 at the edge's start, counted clockwise) satisfies
-- (s - phase) mod period < dash. rev = the edge runs against screen order
-- (bottom: right to left; left: bottom to top), so the dashes march clockwise.
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

-- a 1u rectangle 2u outside the element: 2u black / 2u white, moving 8u a second
local function drawAnts(p, x, y, w, h)
    local T = ZeD.T
    local u, o, dash = T.hair, T.px(2), T.px(2)
    local period = dash * 2
    local phase = ((getTimestampMs() or 0) / 1000) * T.px(8)
    local X0, Y0, W, H = x - o, y - o, w + 2 * o, h + 2 * o
    antsEdge(p, true,  false, X0, Y0, W, 0, phase, period, dash, u)                                 -- top
    antsEdge(p, false, false, X0 + W - u, Y0 + u, H - u, W, phase, period, dash, u)                -- right
    antsEdge(p, true,  true,  X0, Y0 + H - u, W - u, W + H - u, phase, period, dash, u)            -- bottom
    antsEdge(p, false, true,  X0, Y0 + u, H - 2 * u, 2 * W + H - 2 * u, phase, period, dash, u)    -- left
end

-- ---------------------------------------------------------------------------
-- The two parts of a mark
-- ---------------------------------------------------------------------------
local function fillShape(p, x, y, w, h, c, a, rounded)
    if rounded and ZeD.Atoms and ZeD.Atoms.fillRounded then
        ZeD.Atoms.fillRounded(p, x, y, w, h, c.r, c.g, c.b, a)
    else
        p:drawRect(x, y, w, h, a, c.r, c.g, c.b)
    end
end

-- under the words; true when the words must switch to T.textOnFocus
local function paintUnder(p, x, y, w, h, style, solid, rounded)
    local T = ZeD.T
    if style == "wash" then
        if solid then
            -- the element is already solid accent: a 2u ring inside its edge
            local c = T.textOnFocus or T.text
            ZeD.Atoms.frame(p, x, y, w, h, c, 1, T.line(2))
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

-- on top (the overlay pass)
local function paintOver(p, x, y, w, h, style, minTop)
    if style == "hand" then drawHand(p, x, y, h, minTop)
    elseif style == "corners" then drawCorners(p, x, y, w, h)
    elseif style == "ants" then drawAnts(p, x, y, w, h) end
end

-- ---------------------------------------------------------------------------
-- Public
-- ---------------------------------------------------------------------------

--- The chosen look: "hand" (default), "corners", "wash" or "ants".
function FP.style()
    local S = ZeD.Settings
    local st = S and S.focusStyle and S.focusStyle() or "hand"
    if not STYLES[st] then st = "hand" end
    return st
end

--- True when a focus mark for an element of `win` shows now (see the header for
-- opts.focused / opts.pad).
function FP.isShowing(win, opts)
    opts = opts or NO_OPTS
    local F = ZeD.Input and ZeD.Input.Focus
    local pad = opts.pad
    if pad == nil then
        if F and F.cuesVisible then
            pad = F.cuesVisible()
        else
            local D = ZeD.Input and ZeD.Input.Detector
            pad = (D and D.getMode and D.getMode() == "gamepad") or false
        end
    end
    if not pad then return false end
    if opts.focused then return true end
    return win ~= nil and F ~= nil and F.getFocusedWindow ~= nil and F.getFocusedWindow() == win
end

local _marks = {}   -- [win] = { x, y, w, h (screen), solid, zone, t, panel }

--- Mark the focused element at (x, y, w, h) in panel space.
-- opts = { win = the ZeD window or HUD panel (default: the window the panel
--          is in), solid = the element is already solid accent, zone = its zone
--          name, focused = true for a focus model of the caller's own, pad = the
--          caller's own controller test (main menu) }
-- rounded (internal: the push buttons) = the washes follow the 2u rounded corners
-- @return true when the caller must draw the element's words in T.textOnFocus
function FP.mark(panel, x, y, w, h, opts, rounded)
    if not panel or not ZeD.T then return false end
    -- (opts = true, as the library's focus options allow: the defaults)
    if type(opts) ~= "table" then opts = NO_OPTS end
    local win = opts.win or (ZeD.Atoms and ZeD.Atoms.windowOf and ZeD.Atoms.windowOf(panel)) or panel
    if not FP.isShowing(win, opts) then return false end
    local swap = paintUnder(panel, x, y, w, h, FP.style(), opts.solid, rounded)
    local rec = _marks[win]
    if not rec then rec = {}; _marks[win] = rec end
    rec.x, rec.y, rec.w, rec.h = panel:getAbsoluteX() + x, panel:getAbsoluteY() + y, w, h
    rec.solid, rec.zone, rec.t, rec.panel = opts.solid and true or false, opts.zone, getTimestampMs(), panel
    return swap
end
FP.paint = FP.mark   -- the spec's name for it

-- the record for `win`: its own, else one made by a panel inside it under
-- another key (a window that is itself a child of another element)
local function takeRecord(win)
    local rec = _marks[win]
    if rec then _marks[win] = nil; return rec end
    local A = ZeD.Atoms
    if not (A and A.isAncestor) then return nil end
    for k, r in pairs(_marks) do
        if r.panel and A.isAncestor(win, r.panel) then _marks[k] = nil; return r end
    end
    return nil
end

--- The overlay pass for `win`: the top part of this frame's mark (the hand, the
-- corners, the ants) and then the hover box asked for in the window
-- (ZeD.Atoms.requestHint / requestDetailCard). Call it from the window's overlay
-- child, after all of the window's children, with that child as `ov`; a HUD
-- panel without one calls ZeD.Focus.drawOverlay(self, self) at the end of its render.
-- The hand may cross the window's frame, but not lie over its close box: an element just under
-- the title bar at the window's left edge (a tab, a first row shorter than the hand) would put
-- the hand's top over the box. Then the hand's top stays at the title bar's bottom edge (in
-- the overlay's coordinates); nil when the hand is clear of it.
local function handMinTop(ov, win, x, y, h)
    if not (win and win.closeRect and win.titleBarHeight) or win._closeOnRod then return nil end
    local cb = win:closeRect()
    if not cb then return nil end
    local k = artK()
    local hx0, hx1 = x - HAND_W * k, x
    local hy0 = y + math.floor((h - HAND_H * k) / 2)
    local hy1 = hy0 + (HAND_H + 1) * k   -- (the shadow hangs one art pixel lower)
    local dx, dy = win:getAbsoluteX() - ov:getAbsoluteX(), win:getAbsoluteY() - ov:getAbsoluteY()
    local bx0, by0 = dx + cb.x, dy + cb.y
    if hx1 <= bx0 or hx0 >= bx0 + cb.w or hy1 <= by0 or hy0 >= by0 + cb.h then return nil end
    return dy + win:titleBarHeight()
end

function FP.drawOverlay(ov, win)
    if not ov or not ZeD.T then return end
    win = win or ov
    local rec = takeRecord(win)
    if rec and (getTimestampMs() - (rec.t or 0)) <= STALE_MS then
        local style = FP.style()
        local x, y = rec.x - ov:getAbsoluteX(), rec.y - ov:getAbsoluteY()
        local minTop = (style == "hand") and handMinTop(ov, win, x, y, rec.h) or nil
        paintOver(ov, x, y, rec.w, rec.h, style, minTop)
    end
    local A = ZeD.Atoms
    if A and A.drawPendingHover then A.drawPendingHover(ov, win) end
end

--- A preview of a style for its chooser (ZeD setup, the window box): a row in
-- surface 1 with a small icon square and the word "Sample" in the row font,
-- carrying that style's whole mark. Input mode and window focus are ignored.
-- The hand sticks out left of (x, ...) by its width (16 x the art scale): the
-- caller leaves that room.
function FP.drawSample(panel, x, y, w, h, style)
    local T = ZeD.T
    if not (panel and T) then return end
    if not STYLES[style] then style = "hand" end
    local s1 = T.surf1
    panel:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
    local swap = paintUnder(panel, x, y, w, h, style, false, false)
    local isz = math.max(T.px(6), math.min(T.px(16), h - T.px(4)))
    local ix, iy = x + T.px(8), y + math.floor((h - isz) / 2)
    local s3 = T.surf3
    panel:drawRect(ix, iy, isz, isz, 1, s3.r, s3.g, s3.b)
    ZeD.Atoms.frame(panel, ix, iy, isz, isz, T.borderS)
    local f = T.fontF2
    local word = ZeD.tr and ZeD.tr("UI_ZeD_Focus_Sample") or "UI_ZeD_Focus_Sample"
    local tc = swap and T.textOnFocus or T.text
    local ty = y + math.floor((h - ZeD.TM:getFontHeight(f)) / 2)
    panel:drawText(word, ix + isz + T.px(8), ty, tc.r, tc.g, tc.b, tc.a or 1, f)
    paintOver(panel, x, y, w, h, style)
end

--- How far the hand reaches left of an element (for layouts that leave it room).
function FP.handWidth()
    return HAND_W * artK()
end
