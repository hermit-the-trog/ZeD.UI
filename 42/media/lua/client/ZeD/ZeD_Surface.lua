-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Surface.lua
-- ============================================================================
-- WINDOW SURFACES AND THE HELP LINE (cohesion spec sections 3.2 and 10)
--
-- ZeD.Surface: one layer of see-through everywhere in a window. A band, a
-- header or a card drawn over the window body would add its own alpha to the
-- body's, so at 60% a window with bands looked striped. A surface drawn with
-- ZeD.Surface.fill instead claims its rect: the window draws its body as its
-- rect minus the rects claimed in the frame before, so every spot of the
-- window carries exactly one surface. The claims of a frame are used by the
-- next frame's body (the body is drawn before the children that claim), and
-- start empty every frame.
--
--   ZeD.Surface.fill(panel, x, y, w, h, tokenName)
--       draws ZeD.T[tokenName] (default "surf2") at the window's alpha in
--       panel coordinates and claims the rect for the panel's ZeD_Window.
--       A panel outside any ZeD_Window just draws.
--   ZeD.Surface.claim(panel, x, y, w, h)
--       claims the rect without drawing: a strip drawn on a card that draws
--       its own body (the card's fill is the one layer there).
--
-- A claim is kept to the clip in force while it is made: a section head or
-- tab half scrolled out of a list is cut off by the list's stencil, and so is
-- its claim, so the body still shows above the list. The stencils are tracked
-- here for every panel (ZeD.Surface.clip: the visible rect on screen, or nil);
-- ZeD.Atoms.mouseIn uses the same clip for hover.
--
-- ZeD.Help: the words in a window's help line for what the pointer is over.
--
--   ZeD.Help.set(panel, text)
--       a surface calls it every frame while the pointer rests on one of its
--       elements (panel: the window or any panel inside it); the help line
--       shows it this frame and forgets it. Nothing set: the window's own
--       getStatusLine(), when it has one.
-- ============================================================================

require "ISUI/ISUIElement"

ZeD = ZeD or {}
ZeD.Surface = ZeD.Surface or {}
ZeD.Help = ZeD.Help or {}
local S = ZeD.Surface
local H = ZeD.Help

local MAX_CLAIMS = 64   -- a frame's claims past this many draw over the body as before
local MAX_CLIPS  = 16   -- deeper than this, a stencil is not tracked (its clear still pops)

-- ----------------------------------------------------------------------------
-- The clip in force: the engine's stencils, as screen rects
-- ----------------------------------------------------------------------------
-- The engine nests stencils (each one draws only where the one before it did), so the
-- clip in force is the meeting of every rect set and not yet cleared; each entry holds that
-- meeting, ready to use. A stencil left set by a failed draw would linger, so the stack
-- starts empty before and after every UI draw.
local _clips, _clipN = {}, 0

local function pushClip(panel, x, y, w, h)
    _clipN = _clipN + 1
    if _clipN > MAX_CLIPS then return end
    local jo = panel and panel.javaObject
    local ax = jo and jo:getAbsoluteX() or 0
    local ay = jo and jo:getAbsoluteY() or 0
    local x0, y0 = ax + (x or 0), ay + (y or 0)
    local x1, y1 = x0 + (w or 0), y0 + (h or 0)
    local prev = _clips[_clipN - 1]
    if _clipN > 1 and prev then
        if prev.x0 > x0 then x0 = prev.x0 end
        if prev.y0 > y0 then y0 = prev.y0 end
        if prev.x1 < x1 then x1 = prev.x1 end
        if prev.y1 < y1 then y1 = prev.y1 end
    end
    if x1 < x0 then x1 = x0 end
    if y1 < y0 then y1 = y0 end
    local c = _clips[_clipN]
    if not c then c = {}; _clips[_clipN] = c end
    c.x0, c.y0, c.x1, c.y1 = x0, y0, x1, y1
end

local function popClip()
    if _clipN > 0 then _clipN = _clipN - 1 end
end

--- The clip the draw in progress is under, in screen coordinates: { x0, y0, x1, y1 }
-- (read it, do not keep it), or nil when no stencil is set.
function S.clip()
    if _clipN <= 0 then return nil end
    return _clips[math.min(_clipN, MAX_CLIPS)]
end

function S.resetClips() _clipN = 0 end
S._pushClip, S._popClip = pushClip, popClip

-- Every panel's stencil calls go through ISUIElement (ZeD_Window and ZeD_Panel count theirs and
-- then call it too); the engine's own drawing is unchanged, this only watches. Wrapped once; the
-- wrapper looks the tracker up on each call, so a reloaded file's tracker is the one in use.
if not ISUIElement._zedClipWrapped then
    ISUIElement._zedClipWrapped = true
    local origSet, origClear = ISUIElement.setStencilRect, ISUIElement.clearStencilRect
    function ISUIElement:setStencilRect(x, y, w, h)
        local r = origSet(self, x, y, w, h)   -- (it makes the Java side when it is missing)
        local Sf = ZeD.Surface
        if Sf and Sf._pushClip then Sf._pushClip(self, x, y, w, h) end
        return r
    end
    function ISUIElement:clearStencilRect()
        local Sf = ZeD.Surface
        if Sf and Sf._popClip then Sf._popClip() end
        return origClear(self)
    end
end
if Events then
    if Events.OnPreUIDraw then Events.OnPreUIDraw.Add(S.resetClips) end
    if Events.OnPostUIDraw then Events.OnPostUIDraw.Add(S.resetClips) end
end

-- The ZeD_Window a panel lives in (the panel itself when it is one), or nil
function S.windowOf(panel)
    local p = panel
    local guard = 0
    while p and guard < 32 do
        if p.isZeDWindow then return p end
        p = p.parent
        guard = guard + 1
    end
    return nil
end

-- this frame's claims start empty; last frame's become the ones the body skips
-- (ZeD_Window calls it at the top of its own drawing, once a frame)
function S.beginFrame(win)
    local cur = win._srfCur or { n = 0 }
    local prev = win._srfPrev or { n = 0 }
    prev.n = 0
    win._srfPrev, win._srfCur = cur, prev
end

-- record a claim in window coordinates (clamped to the window)
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

-- a rect in panel coordinates claimed for the panel's window: kept to the part inside the panel
-- itself and inside the clip in force (a stencil cuts what is drawn, so it cuts the claim too)
local function claimRect(panel, x, y, w, h)
    local win = S.windowOf(panel)
    if not win then return end
    -- panel coordinates to window coordinates (the engine draws at the absolute place plus the scroll),
    -- kept to the part of the rect inside the panel itself
    local px0, py0 = math.max(0, x), math.max(0, y)
    local px1, py1 = math.min(panel:getWidth(), x + w), math.min(panel:getHeight(), y + h)
    if panel ~= win then
        local jo = panel.javaObject
        local sx = jo and jo:getXScroll() or 0
        local sy = jo and jo:getYScroll() or 0
        -- (a scrolled panel draws its content shifted: the visible part is what counts)
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
    local T = ZeD.T
    local col = T[tokenName or "surf2"] or T.surf2
    panel:drawRect(x, y, w, h, col.a or 1, col.r, col.g, col.b)
    claimRect(panel, x, y, w, h)
end

--- Claim (x, y, w, h) in panel coordinates for the panel's window without drawing it: the
-- window's body leaves it out next frame. For a library strip on a card that draws its own
-- body (one layer there already); the claim is kept to the clip in force, as fill's is.
function S.claim(panel, x, y, w, h)
    if not panel or not w or not h or w <= 0 or h <= 0 then return end
    claimRect(panel, x, y, w, h)
end

-- the rect (x, y, w, h) minus last frame's claims, drawn in tokenName: the window body
local bufA, bufB = {}, {}
function S.drawBody(win, x, y, w, h, tokenName)
    if w <= 0 or h <= 0 then return end
    local T = ZeD.T
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
                -- what is left of this piece around the claim: above, below, then the two sides
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

-- ----------------------------------------------------------------------------
-- the help line's words
-- ----------------------------------------------------------------------------
function H.set(panel, text)
    if text == nil or text == "" then return end
    local win = S.windowOf(panel)
    if win then win._helpText = tostring(text) end
end

-- what the help line says this frame (and forgets the stamp): the pointed element's help,
-- else the window's own status line
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
