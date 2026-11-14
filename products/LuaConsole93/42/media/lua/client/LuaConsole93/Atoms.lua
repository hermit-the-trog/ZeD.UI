-- LuaConsole93/42/media/lua/client/LuaConsole93/Atoms.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's Atoms.lua the console uses (51 of its 145
-- statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/Atoms.lua by ZeDUI/tools/products/build_luaconsole93.py. Do not
-- edit it here: change ZeD-GUI's file and build again.
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

require "ISUI/ISPanel"

LC93 = LC93 or {}
LC93.Atoms = LC93.Atoms or {}

LC93.HINT_DELAY_MS = 450

local function textCase(s)
    if s == nil then return "" end
    local f = LC93.textCase or LC93.btnCase
    if f then return f(s) end
    return tostring(s)
end
LC93.Atoms.textCase = textCase

function LC93.Atoms.surfaceFill(panel, x, y, w, h, key)
    if w <= 0 or h <= 0 then return end
    local S = LC93.Surface
    if S and S.fill then S.fill(panel, x, y, w, h, key); return end
    local c = LC93.T[key] or LC93.T.surf2
    panel:drawRect(x, y, w, h, c.a or 1, c.r, c.g, c.b)
end

function LC93.Atoms.frame(panel, x, y, w, h, color, alpha, t)
    if not color or w <= 0 or h <= 0 then return end
    t = t or LC93.T.hair
    local a = (color.a or 1) * (alpha or 1)
    local r, g, b = color.r, color.g, color.b
    panel:drawRect(x, y, w, t, a, r, g, b)
    panel:drawRect(x, y + h - t, w, t, a, r, g, b)
    if h > 2 * t then
        panel:drawRect(x, y + t, t, h - 2 * t, a, r, g, b)
        panel:drawRect(x + w - t, y + t, t, h - 2 * t, a, r, g, b)
    end
end

function LC93.Atoms.rootOf(panel)
    local p, n = panel, 0
    while p and p.parent and n < 64 do p = p.parent; n = n + 1 end
    return p
end

function LC93.Atoms.windowOf(panel)
    local S = LC93.Surface
    local w = S and S.windowOf and S.windowOf(panel)
    return w or LC93.Atoms.rootOf(panel)
end

function LC93.Atoms.isAncestor(anc, panel)
    local p, n = panel, 0
    while p and n < 64 do
        if p == anc then return true end
        p = p.parent; n = n + 1
    end
    return false
end

function LC93.Atoms.mouseIn(panel, x, y, w, h, view)
    local F = LC93.Input and LC93.Input.Focus
    if F and F.cuesVisible and F.cuesVisible() then return false end
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if view then
        x, y = x + (view.ox or 0), y + (view.oy or 0)
        if view.w and view.h then
            local vx, vy = view.x or 0, view.y or 0
            if mx < vx or mx >= vx + view.w or my < vy or my >= vy + view.h then return false end
        end
    end
    if not (mx >= x and mx < x + w and my >= y and my < y + h) then return false end
    local S = LC93.Surface
    local c = S and S.clip and S.clip()
    if c then
        local ax, ay = getMouseX(), getMouseY()
        if ax < c.x0 or ax >= c.x1 or ay < c.y0 or ay >= c.y1 then return false end
    end
    return true
end

function LC93.Atoms.drawTextRight(panel, text, x, y, font, color)
    local c = color or LC93.T.textSec
    local tw = LC93.TM:MeasureStringX(font or LC93.T.fontF1, text)
    panel:drawText(text, x - tw, y, c.r, c.g, c.b, c.a, font or LC93.T.fontF1)
end

function LC93.Atoms.drawDividerH(panel, x, y, w, strong)
    local c = strong and LC93.T.borderS or LC93.T.border
    local h = LC93.T.line(LC93.T.borderW)
    panel:drawRect(x, y, w, h, c.a, c.r, c.g, c.b)
end

function LC93.Atoms.drawDividerV(panel, x, y, h, strong)
    local c = strong and LC93.T.borderS or LC93.T.border
    local w = LC93.T.line(LC93.T.borderW)
    panel:drawRect(x, y, w, h, c.a, c.r, c.g, c.b)
end

LC93.PxIcon = LC93.PxIcon or {}
local PXI = LC93.PxIcon
PXI.DIR = "media/textures/LuaConsole93/wheel/"
PXI.SIZES = { 48, 32, 24, 16 }
local _pxTex = {}
local function pxTex(size, id)
    local path = PXI.DIR .. size .. "/zw_" .. id .. ".png"
    local t = _pxTex[path]
    if t == nil then
        t = Texture.getSharedTexture(path, 3) or false
        _pxTex[path] = t
    end
    return t or nil
end

function PXI.tex(id, box)
    if not id then return nil, box end
    for _, s in ipairs(PXI.SIZES) do
        if s <= box then
            local t = pxTex(s, id)
            if t then return t, s end
        end
    end
    return pxTex(16, id), box
end

function PXI.markColor(id, set)
    local kind = id and LC93.PxIconMark and LC93.PxIconMark[id]
    if not kind then return nil end
    if type(set) == "table" and set.add then return (kind == "add") and set.add or set.remove end
    local C = LC93.Ctx
    return C and ((kind == "add") and C.markAdd or C.markRemove) or nil
end

function LC93.Atoms.drawPxIcon(panel, id, x, y, box, alpha, tint, marks)
    local tex, s = PXI.tex(id, box)
    if not tex then return end
    local c = tint or LC93.T.text
    local o = math.floor((box - s) / 2)
    panel:drawTextureScaledAspect(tex, x + o, y + o, s, s, alpha or 1, c.r, c.g, c.b)
    if marks then
        local mc = PXI.markColor(id, marks)
        local mt = mc and pxTex(s, id .. "_mk")
        if mt then panel:drawTextureScaledAspect(mt, x + o, y + o, s, s, alpha or 1, mc.r, mc.g, mc.b) end
    end
end

function LC93.Atoms.drawIcon(panel, texture, x, y, size, alpha, tint)
    if not texture then return end
    local a = alpha or 1.0
    local T = LC93.T
    local r, g, b = 1, 1, 1
    if tint then
        r, g, b = tint.r, tint.g, tint.b
    elseif T then
        r, g, b = T.text.r, T.text.g, T.text.b
    end
    panel:drawTextureScaledAspect(texture, x, y, size, size, a, r, g, b)
end

function LC93.Atoms.drawCheckbox(panel, x, y, checked, hovered, disabled)
    local T = LC93.T
    local sz = T.checkboxSz
    local alpha = disabled and T.disabledAlpha or 1.0

    if checked then
        local ac = T.accent
        panel:drawRect(x, y, sz, sz, ac.a * alpha, ac.r, ac.g, ac.b)
    else
        local bg = hovered and T.hover or T.surf2
        panel:drawRect(x, y, sz, sz, bg.a * alpha, bg.r, bg.g, bg.b)
    end

    local bc = checked and T.accent or T.borderS
    panel:drawRectBorder(x, y, sz, sz, bc.a * alpha, bc.r, bc.g, bc.b)

    if checked then
        local tc = T.textOnAccent
        local m = T.px(3)
        local u = T.px(1)
        for i = 0, sz - m * 2 - u, u do
            local px = x + m + i
            local py = y + m + i
            panel:drawRect(px, py, u, u, tc.a * alpha, tc.r, tc.g, tc.b)
            local py2 = y + sz - m - u - i
            panel:drawRect(px, py2, u, u, tc.a * alpha, tc.r, tc.g, tc.b)
        end
    end
end

local function markOrigin(x, y, size, sq)
    if not size then return x, y end
    local off = math.floor((size - sq) / 2)
    return x + off, y + off
end

function LC93.Atoms.drawStatusDot(panel, x, y, color, size)
    if not color then return end
    local sq = LC93.T.px(6)
    x, y = markOrigin(x, y, size or LC93.T.px(7), sq)
    panel:drawRect(x, y, sq, sq, color.a or 1, color.r, color.g, color.b)
end

local HOVER_STALE_MS = 150

local _hoverReq = {}
local _hoverSt  = {}

local function hoverRequest(owner, key, panel, rect, opts)
    local r = _hoverReq[owner]
    if not r then r = {}; _hoverReq[owner] = r end
    r.key, r.t, r.panel = key, getTimestampMs(), panel
    if rect then
        r.rx, r.ry, r.rw, r.rh = rect.x, rect.y, rect.w or 1, rect.h or rect.w or 1
    else
        r.rx = nil
    end
    r.side = opts and opts.side or nil
    r.now = opts and opts.now or false
    r.below = opts and opts.below or nil
    return r
end

function LC93.Atoms.requestHint(owner, key, text, panel, rect, opts)
    if not owner or not text or text == "" then return end
    local r = hoverRequest(owner, key or text, panel, rect, opts)
    r.kind, r.text, r.card = "hint", text, nil
end

local function contentOf(st, r)
    if r.kind == "content" then return r.content end
    if r.kind == "card" then
        local c = LC93.Molecules and LC93.Molecules.cardContent and LC93.Molecules.cardContent(r.card)
        return c
    end
    if st.cText ~= r.text or not st.c then
        st.cText = r.text
        st.c = { kind = "plain", title = r.text }
    end
    return st.c
end

function LC93.Atoms.drawPendingHover(ov, win)
    win = win or ov
    local owner, r = win, _hoverReq[win]
    if not r then
        for o, rr in pairs(_hoverReq) do
            if rr.panel and LC93.Atoms.isAncestor(win, rr.panel) then owner, r = o, rr; break end
        end
    end
    local st = _hoverSt[win]
    if not st then st = {}; _hoverSt[win] = st end
    local now = getTimestampMs()
    local Bn = LC93.Balloon
    if not r then
        if st.lastT and now - st.lastT > HOVER_STALE_MS then st.key = nil end
        if Bn then Bn.redrawHeld(win, ov) end
        return
    end
    _hoverReq[owner] = nil
    if now - (r.t or 0) > HOVER_STALE_MS then st.key = nil; return end
    st.lastT = r.t
    if st.key ~= r.key then
        st.key, st.since = r.key, now
        st.warm = r.now or (Bn and Bn.warm()) or false
        st.px, st.py = getMouseX(), getMouseY()
    end
    if not st.warm and now - (st.since or now) < LC93.HINT_DELAY_MS then
        if Bn then Bn.redrawHeld(win, ov) end
        return
    end
    local c = contentOf(st, r)
    if not (c and Bn) then return end
    local a = st.a
    if not a then a = {}; st.a = a end
    local p = r.panel or ov
    if r.rx then
        a.x, a.y, a.w, a.h, a.below, a.noFlip = p:getAbsoluteX() + r.rx, p:getAbsoluteY() + r.ry, r.rw, r.rh, nil, nil
    else
        a.x, a.y, a.w, a.h, a.below, a.noFlip = st.px or 0, st.py or 0, 1, 1, nil, nil
    end
    if r.below then a.below = p:getAbsoluteY() + r.below end
    Bn.draw(ov, c, a, r.side or "above", { key = r.key, since = st.since, owner = win })
end

function LC93.Atoms.drawScrollTrack(panel, x, y, w, h)
    local T = LC93.T
    local bc = T.borderS
    panel:drawRect(x, y, T.px(1), h, bc.a, bc.r, bc.g, bc.b)
    panel:drawRect(x + w - T.px(1), y, T.px(1), h, bc.a, bc.r, bc.g, bc.b)
end

function LC93.Atoms.drawScrollArrow(panel, x, y, size, direction, state)
    local T = LC93.T

    if state == "active" then
        local bg = LC93.colorAlpha(T.accent, 0.20)
        panel:drawRect(x, y, size, size, bg.a, bg.r, bg.g, bg.b)
    elseif state == "hover" then
        local bg = T.surf3
        panel:drawRect(x, y, size, size, bg.a, bg.r, bg.g, bg.b)
    end

    local bc = T.borderS
    panel:drawRectBorder(x, y, size, size, bc.a, bc.r, bc.g, bc.b)

    local gc
    if state == "active" then gc = T.accent
    elseif state == "hover" then gc = T.text
    else gc = T.textDim end

    local cx = x + math.floor(size / 2)
    local cy = y + math.floor(size / 2)
    local arrSz = math.max(T.px(3), math.floor(size / 4))

    if direction == "up" then
        for row = 0, arrSz - 1 do
            local px = cx - row
            local py = cy - arrSz / 2 + row
            panel:drawRect(px, py, row * 2 + 1, 1, gc.a, gc.r, gc.g, gc.b)
        end
    elseif direction == "down" then
        for row = 0, arrSz - 1 do
            local px = cx - (arrSz - 1 - row)
            local py = cy - arrSz / 2 + row
            panel:drawRect(px, py, (arrSz - 1 - row) * 2 + 1, 1, gc.a, gc.r, gc.g, gc.b)
        end
    elseif direction == "left" then
        for col = 0, arrSz - 1 do
            local px = cx - arrSz / 2 + col
            local py = cy - col
            panel:drawRect(px, py, 1, col * 2 + 1, gc.a, gc.r, gc.g, gc.b)
        end
    else
        for col = 0, arrSz - 1 do
            local px = cx - arrSz / 2 + col
            local py = cy - (arrSz - 1 - col)
            panel:drawRect(px, py, 1, (arrSz - 1 - col) * 2 + 1, gc.a, gc.r, gc.g, gc.b)
        end
    end
end

function LC93.playerRect(pn)
    pn = pn or 0
    local q = LC93._qaRect and LC93._qaRect[pn]
    if q then return q[1], q[2], q[3], q[4] end
    local core = getCore()
    local sw, sh = core:getScreenWidth(), core:getScreenHeight()
    local okW, w = pcall(getPlayerScreenWidth, pn)
    local okH, h = pcall(getPlayerScreenHeight, pn)
    if not (okW and okH and type(w) == "number" and type(h) == "number" and w > 0 and h > 0) then
        return 0, 0, sw, sh
    end
    local okX, x = pcall(getPlayerScreenLeft, pn)
    local okY, y = pcall(getPlayerScreenTop, pn)
    return (okX and type(x) == "number") and x or 0, (okY and type(y) == "number") and y or 0, w, h
end

LC93.splitWindows = LC93.splitWindows or false
do
    local ok, r = pcall(getFileReader, "LC93_splitview_on.txt", false)
    if ok and r then
        LC93.splitWindows = true
        pcall(function() r:close() end)
        print("[Lua Console 93] split view: on (LC93_splitview_on.txt in Zomboid/Lua)")
    end
end

local wrapRaw
local WT_MAX = 2000
local WT = { cur = {}, old = {}, n = 0, epoch = nil, hits = 0, misses = 0 }

local function wtFind(gen, font, cell, text, maxW)
    local byF = gen[font]
    local byW = byF and byF[cell]
    local e = byW and byW[text]
    if e and (e.fit == nil or e.fit <= maxW) and (e.over == nil or e.over > maxW) then return e end
    return nil
end

function LC93.Atoms.wrapText(text, font, maxW)
    local X = LC93.Text
    local epoch = X and X.measureEpoch and X.measureEpoch() or nil
    if epoch == nil or font == nil or type(text) ~= "string" or type(maxW) ~= "number" or maxW ~= maxW then
        return (wrapRaw(text, font, maxW))
    end
    if epoch ~= WT.epoch then WT.cur, WT.old, WT.n, WT.epoch = {}, {}, 0, epoch end
    local cell = math.floor(maxW)
    local e = wtFind(WT.cur, font, cell, text, maxW)
    if e then
        WT.hits = WT.hits + 1
        return e.lines
    end
    e = wtFind(WT.old, font, cell, text, maxW)
    if e then
        WT.hits = WT.hits + 1
    else
        WT.misses = WT.misses + 1
        local lines, fit, over = wrapRaw(text, font, maxW)
        e = { lines = lines, fit = fit, over = over }
    end
    if WT.n >= WT_MAX then WT.old, WT.cur, WT.n = WT.cur, {}, 0 end
    local byF = WT.cur[font]
    if not byF then byF = {}; WT.cur[font] = byF end
    local byW = byF[cell]
    if not byW then byW = {}; byF[cell] = byW end
    byW[text] = e
    WT.n = WT.n + 1
    return e.lines
end

wrapRaw = function(text, font, maxW)
    local lines = {}
    if not text or text == "" then return lines end
    local fit, over

    for paragraph in text:gmatch("[^\n]+") do
        local words = {}
        for word in paragraph:gmatch("%S+") do words[#words + 1] = word end
        local line = ""
        for _, word in ipairs(words) do
            local test = line == "" and word or (line .. " " .. word)
            local tw = LC93.TM:MeasureStringX(font, test)
            if tw > maxW then
                if over == nil or tw < over then over = tw end
                if line ~= "" then lines[#lines + 1] = line end
                line = word
            else
                if fit == nil or tw > fit then fit = tw end
                line = test
            end
        end
        if line ~= "" then lines[#lines + 1] = line end
    end

    if #lines == 0 then lines[1] = text end
    return lines, fit, over
end

local truncateRaw
local TT_MAX = 4000
local _tt, _ttN, _ttEpoch = {}, 0, nil
local function ttSame(e, maxW)
    if e.full then return e.w <= maxW end
    if not (e.w > maxW) then return false end
    if e.dots then return maxW <= e.ell end
    if maxW <= e.ell then return false end
    local target = maxW - e.ell
    return (e.fit == nil or e.fit <= target) and (e.over == nil or e.over > target)
end
function LC93.Atoms.truncateText(text, font, maxW)
    if maxW <= 0 then return "" end
    local X = LC93.Text
    local epoch = X and X.measureEpoch and X.measureEpoch() or nil
    if epoch == nil or font == nil or type(text) ~= "string" then return (truncateRaw(text, font, maxW)) end
    if epoch ~= _ttEpoch or _ttN >= TT_MAX then _tt, _ttN, _ttEpoch = {}, 0, epoch end
    local cell = math.floor(maxW)
    local byF = _tt[font]
    if not byF then byF = {}; _tt[font] = byF end
    local byW = byF[cell]
    if not byW then byW = {}; byF[cell] = byW end
    local e = byW[text]
    if e == nil or not ttSame(e, maxW) then
        local s, rec = truncateRaw(text, font, maxW)
        rec.s = s
        e = rec
        byW[text] = e
        _ttN = _ttN + 1
    end
    return e.s
end
truncateRaw = function(text, font, maxW)
    if maxW <= 0 then return "", {} end
    local tm = LC93.TM
    local w = tm:MeasureStringX(font, text)
    if w <= maxW then return text, { w = w, full = true } end
    local ellW = tm:MeasureStringX(font, "...")
    if maxW <= ellW then return "...", { w = w, ell = ellW, dots = true } end
    local target = maxW - ellW
    local fit, over
    local lo, hi = 1, #text
    while lo < hi do
        local mid = math.floor((lo + hi + 1) / 2)
        local pw = tm:MeasureStringX(font, string.sub(text, 1, mid))
        if pw <= target then
            if fit == nil or pw > fit then fit = pw end
            lo = mid
        else
            if over == nil or pw < over then over = pw end
            hi = mid - 1
        end
    end
    return string.sub(text, 1, lo) .. "...", { w = w, ell = ellW, fit = fit, over = over }
end
