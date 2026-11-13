-- LuaConsole93/42/media/lua/client/LuaConsole93/Molecules.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's Molecules.lua the console uses (44 of its
-- 233 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/Molecules.lua by ZeDUI/tools/products/build_luaconsole93.py. Do
-- not edit it here: change ZeD-GUI's file and build again.
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

require "LuaConsole93/Atoms"
require "LuaConsole93/Tr"

LC93 = LC93 or {}
LC93.Molecules = LC93.Molecules or {}

local NO_OPTS = {}
local _focusOpts = {}

local function focusOptsOf(opts)
    local f = opts.focus
    if f == true then
        _focusOpts.win = opts.win
        return _focusOpts
    end
    return f
end

local _partFocus = {}

local function giveHelp(panel, opts)
    if not opts.help then return end
    local H = LC93.Help
    if H and H.set then H.set(opts.win or panel, opts.help) end
end

local function withAlpha(out, c, a)
    out.r, out.g, out.b, out.a = c.r, c.g, c.b, (c.a or 1) * a
    return out
end

function LC93.Molecules.drawButton(panel, x, y, w, h, text, variant, pressed, colors, opts)
    local T = LC93.T
    local A = LC93.Atoms
    variant = variant or "default"
    pressed = pressed or false

    if variant == "flat" then
        local c = colors or {}
        local bg     = c.bg     or T.surf3
        local border = c.border or T.borderS
        local txt    = c.text   or T.text
        local font   = c.font   or T.fontF3
        panel:drawRect(x, y, w, h, bg.a or 1.0, bg.r, bg.g, bg.b)
        panel:drawRectBorder(x, y, w, h, border.a or 1.0, border.r, border.g, border.b)
        local tw = LC93.TM:MeasureStringX(font, text)
        local th = LC93.TM:getFontHeight(font)
        local tx = x + math.floor((w - tw) / 2)
        local ty = y + math.floor((h - th) / 2)
        if pressed then tx = tx + T.px(1); ty = ty + T.px(1) end
        panel:drawText(text, tx, ty, txt.r, txt.g, txt.b, txt.a or 1, font)
        return x, y, w, h
    end

    opts = opts or NO_OPTS
    if opts.compact then
        local ch = T.buttonH - T.px(4)
        if h and h > ch then y = y + math.floor((h - ch) / 2) end
        h = ch
    end
    local alpha = opts.disabled and T.disabledAlpha or 1

    if not (colors and colors.keepCase) then text = LC93.btnCase(text) end
    local font = opts.font or T.fontF3

    if opts.hover and not opts.disabled then
        local hv = T.hover
        A.fillRounded(panel, x, y, w, h, hv.r, hv.g, hv.b, hv.a or 1)
    end

    if colors and colors.fill then
        local f = colors.fill
        A.fillRounded(panel, x, y, w, h, f.r, f.g, f.b, (f.a or 1) * alpha)
    end

    local borderColor, textColor
    if opts.disabled then
        borderColor = T.borderS
        textColor = T.text
    elseif variant == "primary" then
        borderColor = T.accent
        textColor = T.accentText
    elseif variant == "danger" then
        borderColor = T.danger
        textColor = T.dangerText
        local pulse = math.sin((getTimestampMs() or 0) / 400) * 0.5 + 0.5
        local fillA = T.dangerPulseMin + pulse * (T.dangerPulseMax - T.dangerPulseMin)
        A.fillRounded(panel, x, y, w, h, T.danger.r, T.danger.g, T.danger.b, fillA)
    else
        borderColor = T.borderS
        textColor = T.text
    end

    local onFocus = false
    if opts.focus and LC93.Focus and LC93.Focus.mark then
        onFocus = LC93.Focus.mark(panel, x, y, w, h, focusOptsOf(opts), true)
    end

    if colors and colors.text then
        textColor = colors.text
    elseif onFocus or (colors and colors.fill and (colors.fill.a or 1) >= 0.5) then
        textColor = T.textOnFocus
    end
    if colors and colors.border then borderColor = colors.border end
    if onFocus then borderColor = T.textOnFocus end

    if not opts.disabled and (variant == "primary" or opts.default) then
        A.borderDoubleRounded(panel, x, y, w, h, borderColor.r, borderColor.g, borderColor.b, (borderColor.a or 1) * alpha)
    else
        A.borderRounded(panel, x, y, w, h, borderColor.r, borderColor.g, borderColor.b, (borderColor.a or 1) * alpha)
    end

    local tw = LC93.TM:MeasureStringX(font, text)
    local th = LC93.TM:getFontHeight(font)
    local tx = x + math.floor((w - tw) / 2)
    local ty = y + math.floor((h - th) / 2)
    if pressed and not opts.disabled then tx = tx + T.px(1); ty = ty + T.px(1) end
    panel:drawText(text, tx, ty, textColor.r, textColor.g, textColor.b, (textColor.a or 1) * alpha, font)

    if opts.hover then giveHelp(panel, opts) end
    return x, y, w, h
end

function LC93.Molecules.buttonW(text, font)
    local T = LC93.T
    local s = LC93.btnCase(text or "")
    local w = LC93.TM:MeasureStringX(font or T.fontF3, s) + T.sp.buttonPadX * 2
    return math.max(w, T.px(60))
end

local _icC, _icFocus, _icHint = {}, {}, {}
local _icSide = { above = { side = "above" }, right = { side = "right" }, left = { side = "left" } }
local _icNow = { above = { side = "above", now = true }, right = { side = "right", now = true }, left = { side = "left", now = true } }
function LC93.Molecules.drawIconButton(panel, x, y, size, icon, opts)
    local T = LC93.T
    local A = LC93.Atoms
    opts = opts or NO_OPTS
    size = size or T.buttonH
    local alpha = opts.disabled and T.disabledAlpha or 1
    local active = opts.active and true or false
    if active then
        local ac = T.accent
        A.fillRounded(panel, x, y, size, size, ac.r, ac.g, ac.b, (ac.a or 1) * alpha)
    elseif opts.hover and not opts.disabled then
        local hv = T.hover
        A.fillRounded(panel, x, y, size, size, hv.r, hv.g, hv.b, hv.a or 1)
    end
    local onFocus = false
    if opts.focus and LC93.Focus and LC93.Focus.mark then
        local f = focusOptsOf(opts)
        if f then
            local m = _icFocus
            m.win, m.zone, m.focused, m.pad, m.solid = f.win, f.zone, f.focused, f.pad, active or f.solid
            onFocus = LC93.Focus.mark(panel, x, y, size, size, m, true)
        end
    end
    local bc = active and T.accent or (onFocus and T.textOnFocus or T.borderS)
    A.borderRounded(panel, x, y, size, size, bc.r, bc.g, bc.b, (bc.a or 1) * alpha)

    local ic = active and T.textOnAccent or (onFocus and T.textOnFocus or (opts.tint or T.text))
    local isz = math.min(opts.iconSize or T.px(16), size - T.px(4))
    local ix = x + math.floor((size - isz) / 2)
    local iy = y + math.floor((size - isz) / 2)
    if opts.pressed then ix = ix + T.px(1); iy = iy + T.px(1) end
    if type(icon) == "function" then
        icon(panel, ix, iy, isz, withAlpha(_icC, ic, alpha))
    elseif type(icon) == "string" then
        A.drawPxIcon(panel, icon, ix, iy, isz, (ic.a or 1) * alpha, ic)
    elseif icon then
        A.drawIcon(panel, icon, ix, iy, isz, (ic.a or 1) * alpha, ic)
    end

    local hintRect = nil
    if (opts.hover or onFocus) and opts.hint and A.requestHint then
        hintRect = _icHint
        hintRect.x, hintRect.y, hintRect.w, hintRect.h = x, y, size, size
    end
    if opts.hover then
        giveHelp(panel, opts)
        if hintRect then
            A.requestHint(opts.win or A.windowOf(panel), opts.id or opts.hint, opts.hint, panel, hintRect, opts.hintSide and _icSide[opts.hintSide])
        end
    elseif onFocus and hintRect then
        A.requestHint(opts.win or A.windowOf(panel), opts.id or opts.hint, opts.hint, panel, hintRect, _icNow[opts.hintSide or "above"])
    end
    return x, y, size, size
end

require "ISUI/ISTextEntryBox"

LC93_ScrollbarState = {}
LC93_ScrollbarState.__index = LC93_ScrollbarState

function LC93_ScrollbarState:new()
    local o = {}
    setmetatable(o, self)
    local T = LC93.T
    o.x = 0
    o.y = 0
    o.width = T.sp.scrollbarW
    o.height = T.px(100)
    o.arrowH = T.sp.scrollbarW
    o.reserveBottom = 0
    o.scrollPos = 0
    o.barSizeRatio = 1.0
    o.dragging = false
    o.dragStartY = 0
    o.dragStartPos = 0
    o.thumbHover = false
    o.upHover = false
    o.downHover = false
    o.upPressed = false
    o.downPressed = false
    o.visible = false
    o.onScroll = nil
    return o
end

function LC93_ScrollbarState:getTrackHeight()
    return self.height - self.arrowH * 2 - self.reserveBottom
end

function LC93_ScrollbarState:getThumbHeight()
    local T = LC93.T
    local trackH = self:getTrackHeight()
    if trackH <= 0 then return 0 end
    local thumbH = math.floor(trackH * self.barSizeRatio)
    return math.max(T.px(20), math.min(thumbH, trackH))
end

function LC93_ScrollbarState:getThumbY()
    local trackH = self:getTrackHeight()
    local thumbH = self:getThumbHeight()
    local scrollRange = trackH - thumbH
    if scrollRange <= 0 then return self.arrowH end
    return self.arrowH + math.floor(scrollRange * self.scrollPos)
end

function LC93_ScrollbarState:setBarSize(ratio)
    self.barSizeRatio = math.max(0.0, math.min(1.0, ratio))
end

function LC93_ScrollbarState:setScrollPos(pos)
    pos = math.max(0.0, math.min(1.0, pos))
    if pos == self.scrollPos then return end
    self.scrollPos = pos
    if self.onScroll then
        self.onScroll(self.scrollPos)
    end
end

function LC93_ScrollbarState:draw(panel)
    if not self.visible then return end
    local T = LC93.T
    local A = LC93.Atoms
    local ox = self.x
    local oy = self.y
    local w = self.width

    if not self.dragging then
        local pmx = panel:getMouseX()
        local pmy = panel:getMouseY()
        local inSB = pmx >= ox and pmx < ox + w
            and pmy >= oy and pmy < oy + self.height
        if not inSB then
            self.thumbHover = false
            self.upHover    = false
            self.downHover  = false
        end
    end

    local trackH = self:getTrackHeight()
    A.drawScrollTrack(panel, ox, oy + self.arrowH, w, trackH)

    if self.arrowH > 0 then
        local upState = self.upPressed and "active" or (self.upHover and "hover" or "default")
        A.drawScrollArrow(panel, ox, oy, self.arrowH, "up", upState)

        local downY = oy + self.arrowH + trackH
        local downState = self.downPressed and "active" or (self.downHover and "hover" or "default")
        A.drawScrollArrow(panel, ox, downY, self.arrowH, "down", downState)
    end

    if self.barSizeRatio < 1.0 then
        local thumbY = self:getThumbY()
        local thumbH = self:getThumbHeight()
        local bg
        if self.dragging then
            bg = T.accent
        elseif self.thumbHover then
            bg = T.accentBright
        else
            bg = T.surf4
        end
        panel:drawRect(ox, oy + thumbY, w, thumbH, bg.a, bg.r, bg.g, bg.b)
        local bc = T.borderS
        panel:drawRectBorder(ox, oy + thumbY, w, thumbH, bc.a, bc.r, bc.g, bc.b)
        local gripY = oy + thumbY + math.floor(thumbH / 2) - T.sp.scrollGripOff
        local gripX = ox + T.sp.scrollGripOff
        local gripW = w - T.sp.scrollGripMar
        if gripW > T.px(2) and thumbH > T.px(16) then
            local gc = T.textDim
            for i = 0, 2 do
                panel:drawRect(gripX, gripY + i * T.sp.scrollGripOff, gripW, T.px(1), gc.a, gc.r, gc.g, gc.b)
            end
        end
    end
end

function LC93_ScrollbarState:scrollRange()
    if self.rangePx then return self.rangePx end
    local r = self.barSizeRatio
    if r <= 0 or r >= 1 then return 0 end
    return self.height / r - self.height
end
function LC93_ScrollbarState:lineStep()
    local range = self:scrollRange()
    if range <= 0 then return 0.05 end
    return (self.lineH or LC93.T.px(24)) / range
end
function LC93_ScrollbarState:pageStep()
    local range = self:scrollRange()
    if range <= 0 then return 0.2 end
    return self.height * 0.9 / range
end

function LC93_ScrollbarState:handleMouseDown(localY)
    if self.barSizeRatio >= 1.0 then return end

    if localY < self.arrowH then
        self.upPressed = true
        self:setScrollPos(self.scrollPos - self:lineStep())
        return
    end
    local downTop = self.arrowH + self:getTrackHeight()
    if localY >= downTop and localY < downTop + self.arrowH then
        self.downPressed = true
        self:setScrollPos(self.scrollPos + self:lineStep())
        return
    end
    local thumbY = self:getThumbY()
    local thumbH = self:getThumbHeight()
    if localY >= thumbY and localY <= thumbY + thumbH then
        self.dragging = true
        self.dragStartY = localY
        self.dragStartPos = self.scrollPos
        return
    end
    if localY < thumbY then
        self:setScrollPos(self.scrollPos - self:pageStep())
    else
        self:setScrollPos(self.scrollPos + self:pageStep())
    end
end

function LC93_ScrollbarState:handleMouseUp()
    self.dragging = false
    self.upPressed = false
    self.downPressed = false
end

function LC93_ScrollbarState:handleMouseMove(localY)
    self.upHover = localY >= 0 and localY < self.arrowH
    local downTop = self.arrowH + self:getTrackHeight()
    self.downHover = localY >= downTop and localY < downTop + self.arrowH
    local thumbY = self:getThumbY()
    local thumbH = self:getThumbHeight()
    self.thumbHover = localY >= thumbY and localY <= thumbY + thumbH

    if self.dragging then
        local trackH = self:getTrackHeight()
        local scrollRange = trackH - self:getThumbHeight()
        if scrollRange > 0 then
            local delta = (localY - self.dragStartY) / scrollRange
            self:setScrollPos(self.dragStartPos + delta)
        end
    end
end

local BAR_REPEAT_MS, BAR_STALE_MS = 300, 200
function LC93.Molecules.scrollBar(panel, win, key, x, y, w, h, scroll, total, set, opts)
    local T = LC93.T
    local owner = win or panel
    local bars = owner._lc93Bars
    if not bars then bars = {}; owner._lc93Bars = bars end
    local sb = bars[key]
    if not sb then
        sb = LC93_ScrollbarState:new()
        bars[key] = sb
        sb.onScroll = function(pos) if sb._set then sb._set(math.floor(pos * sb._max + 0.5)) end end
    end
    local view = (opts and opts.view) or h
    local maxS = math.max(1, total - view)
    sb.x, sb.y, sb.width, sb.height = x, y, w, h
    sb.arrowH = (h >= w * 2 + T.px(24)) and w or 0
    sb.visible = true
    sb.lineH = opts and opts.step or nil
    sb.rangePx = maxS
    sb._set, sb._max = set, maxS
    sb:setBarSize(view / math.max(1, total))
    if not sb.dragging then sb.scrollPos = math.max(0, math.min(1, scroll / maxS)) end
    local now = getTimestampMs()
    local down = isMouseButtonDown(0)
    local mx, my = panel:getMouseX(), panel:getMouseY()
    local inside = mx >= x and mx < x + w and my >= y and my < y + h
    if inside and win and win.pointerOn and not win:pointerOn() then inside = false end
    if sb._held then
        if down then
            sb:handleMouseMove(my - y)
            if (sb.upPressed or sb.downPressed) and now - sb._heldAt > BAR_REPEAT_MS then
                sb:setScrollPos(sb.scrollPos + (sb.upPressed and -sb:lineStep() or sb:lineStep()))
            end
        else
            sb._held = false
            sb:handleMouseUp()
        end
    elseif down and not sb._was and inside and now - (sb._at or 0) < BAR_STALE_MS then
        sb._held, sb._heldAt = true, now
        sb:handleMouseDown(my - y)
    elseif inside then
        sb:handleMouseMove(my - y)
    end
    sb._was, sb._at = down, now
    sb:draw(panel)
    return sb
end

require "ISUI/ISMouseDrag"

local SECTION_H = 20
function LC93.Molecules.drawSectionHeader(panel, x, y, w, text, count, expanded, hovered, fontOverride, countInline, bleedLeft, heightOverride, noArrow, opts)
    local T = LC93.T
    local sp = T.sp
    local h = heightOverride or T.px(SECTION_H)
    local font = T.fontF1
    local tm = LC93.TM
    local bleed = bleedLeft or 0
    opts = opts or NO_OPTS
    text = LC93.Atoms.textCase(text)

    if hovered then
        local hv = T.hover
        panel:drawRect(x - bleed, y, w + bleed, h, hv.a, hv.r, hv.g, hv.b)
    end
    local onFocus = false
    if opts.focus and LC93.Focus and LC93.Focus.mark then
        onFocus = LC93.Focus.mark(panel, x - bleed, y, w + bleed, h, opts.focus)
    end

    LC93.Atoms.drawDividerH(panel, x - bleed, y + h - (T.hair or T.px(1)), w + bleed, false)

    local tc = onFocus and T.textOnFocus or (T.toneLo or T.textDim)

    local discSz = math.min(T.px(8), h - T.px(4))
    local discX = x
    local discY = y + math.floor((h - discSz) / 2)
    if not noArrow then
        if expanded then
            LC93.Atoms.drawTriangleDown(panel, discX, discY, discSz, tc)
        else
            LC93.Atoms.drawTriangleRight(panel, discX, discY, discSz, tc)
        end
    end
    local textY = y + math.floor((h - tm:getFontHeight(font)) / 2)

    local titleX = noArrow and discX or (discX + discSz + T.px(4))
    local countStr = count and ("(" .. tostring(count) .. ")") or nil
    local room = x + w - sp.sm - titleX
    if countStr then room = room - tm:MeasureStringX(T.fontF1, countStr) - sp.xs end
    text = LC93.Atoms.truncateText(text, font, math.max(0, room))
    panel:drawText(text, titleX, textY, tc.r, tc.g, tc.b, tc.a or 1, font)

    if count then
        local dc = tc
        if countInline then
            local titleW = tm:MeasureStringX(font, text)
            local countX = titleX + titleW + sp.xs
            panel:drawText(countStr, countX, textY, dc.r, dc.g, dc.b, dc.a or 1, T.fontF1)
        else
            LC93.Atoms.drawTextRight(panel, countStr, x + w - sp.sm, textY, T.fontF1, dc)
        end
    end

    return h
end

function LC93.Molecules.bandH()
    local T = LC93.T
    return T.buttonH + 2 * T.px(5)
end

local _bandBtn, _bandIcon = {}, {}

local function drawBandCheck(panel, x, by, bh, c, win)
    local T, A, tm = LC93.T, LC93.Atoms, LC93.TM
    local f2 = T.fontF2
    local cb = T.checkboxSz
    local label = tostring(c.label or "")
    local cw = cb + T.px(6) + tm:MeasureStringX(f2, label)
    local hover = c.hover
    if hover == nil then hover = A.mouseIn(panel, x, by, cw, bh) end
    hover = hover and not c.disabled
    local onFocus = false
    if c.focus and LC93.Focus and LC93.Focus.mark then
        local f = c.focus
        if f == true then _partFocus.win = win; f = _partFocus end
        onFocus = LC93.Focus.mark(panel, x - T.px(2), by, cw + T.px(4), bh, f) and true or false
    end
    A.drawCheckbox(panel, x, by + math.floor((bh - cb) / 2), c.on and true or false, hover, c.disabled)
    local tc = onFocus and T.textOnFocus or T.text
    local a = (tc.a or 1) * (c.disabled and T.disabledAlpha or 1)
    panel:drawText(label, x + cb + T.px(6), by + math.floor((bh - tm:getFontHeight(f2)) / 2), tc.r, tc.g, tc.b, a, f2)
    if hover and c.help then
        local H = LC93.Help
        if H and H.set then H.set(win or panel, c.help) end
    end
    return { x = x, y = by, w = cw, h = bh, id = c.id }
end

function LC93.Molecules.bandRoom(panel, x, w, need)
    local l, r = x, x + w
    local cx, cl = panel and panel._coverX, panel and panel._coverL
    if cx and cx < r then r = cx end
    if cl and cl > l then l = cl end
    if r - l < (need or 0) or r <= l then return x, x + w end
    return l, r
end

function LC93.Molecules.drawBand(panel, x, y, w, spec)
    local T = LC93.T
    local A = LC93.Atoms
    local M = LC93.Molecules
    spec = spec or NO_OPTS
    local H = M.bandH()
    local edge, gap = spec.edge or T.px(8), spec.gap or T.px(8)
    local bh = T.buttonH
    local by = y + T.px(5)
    local out = { buttons = {}, icons = {}, lead = {} }

    A.surfaceFill(panel, x, y, w, H, "surf2")
    if not spec.noLine then A.drawDividerH(panel, x, y, w, true) end

    local buttons = spec.buttons
    local roomL, roomR = x, x + w
    if panel and (panel._coverX or panel._coverL) then
        local need = 2 * edge
        if buttons then
            for i = 1, #buttons do
                local b = buttons[i]
                need = need + (b.w or math.max(M.buttonW(b.label), b.minW or 0)) + (i > 1 and gap or 0)
            end
        end
        roomL, roomR = M.bandRoom(panel, x, w, need)
    end

    local right = roomR - edge
    if buttons then
        for i = #buttons, 1, -1 do
            local b = buttons[i]
            local bw = b.w or math.max(M.buttonW(b.label), b.minW or 0)
            right = right - bw
            local o = _bandBtn
            o.disabled, o.focus, o.help, o.win = b.disabled, b.focus, b.help, spec.win
            o.default = i == #buttons and b.variant == "danger"
            if b.hover ~= nil then o.hover = b.hover else o.hover = A.mouseIn(panel, right, by, bw, bh) end
            M.drawButton(panel, right, by, bw, bh, b.label, b.variant or "default", b.pressed, nil, o)
            out.buttons[i] = { x = right, y = by, w = bw, h = bh, id = b.id }
            right = right - gap
        end
    end

    local left = roomL + edge
    local icons = spec.icons
    if icons then
        for i, ic in ipairs(icons) do
            local o = _bandIcon
            o.active, o.disabled, o.focus, o.hint, o.help, o.id, o.win =
                ic.active, ic.disabled, ic.focus, ic.hint, ic.help, ic.id, spec.win
            if ic.hover ~= nil then o.hover = ic.hover else o.hover = A.mouseIn(panel, left, by, bh, bh) end
            M.drawIconButton(panel, left, by, bh, ic.icon, o)
            out.icons[i] = { x = left, y = by, w = bh, h = bh, id = ic.id }
            left = left + bh + T.px(4)
        end
        if #icons > 0 then left = left - T.px(4) + gap end
    end

    if spec.lead then
        for i, b in ipairs(spec.lead) do
            local bw = b.w or math.max(M.buttonW(b.label), b.minW or 0)
            local o = _bandBtn
            o.disabled, o.focus, o.help, o.win, o.default = b.disabled, b.focus, b.help, spec.win, false
            if b.hover ~= nil then o.hover = b.hover else o.hover = A.mouseIn(panel, left, by, bw, bh) end
            M.drawButton(panel, left, by, bw, bh, b.label, b.variant or "default", b.pressed, nil, o)
            out.lead[i] = { x = left, y = by, w = bw, h = bh, id = b.id }
            left = left + bw + gap
        end
    end

    if spec.check then
        local r = drawBandCheck(panel, left, by, bh, spec.check, spec.win)
        out.check = r
        left = left + r.w + gap
    end

    local line, mark = nil, nil
    if spec.question then
        line, mark = spec.question, T.danger
    elseif spec.status then
        line, mark = spec.status.text, spec.status.color
    end
    if line and line ~= "" then
        local f2 = T.fontF2
        local sq = T.px(6)
        local tx = left
        if mark then
            A.drawStatusDot(panel, left, y + math.floor((H - sq) / 2), mark, sq)
            tx = left + sq + T.px(6)
        end
        local room = right - tx
        if room > 0 then
            local s = A.truncateText(line, f2, room)
            local tc = T.text
            panel:drawText(s, tx, y + math.floor((H - LC93.TM:getFontHeight(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        end
    end
    return H, out
end

local _qButtons = { {}, {} }
local _qSpec = { buttons = _qButtons }
function LC93.Molecules.drawQuestionBand(panel, x, y, w, question, verb, opts)
    opts = opts or NO_OPTS
    local c, v = _qButtons[1], _qButtons[2]
    c.label, c.variant, c.focus, c.help, c.id = LC93.tr("UI_Cancel"), "default", opts.cancelFocus, opts.cancelHelp, "cancel"
    v.label, v.focus, v.help, v.id = verb, opts.verbFocus, opts.verbHelp, "verb"
    v.variant = (opts.danger == false) and "primary" or "danger"
    _qSpec.question, _qSpec.win, _qSpec.noLine = question, opts.win, opts.noLine
    local H, out = LC93.Molecules.drawBand(panel, x, y, w, _qSpec)
    return H, out.buttons[1], out.buttons[2]
end

local function wrapped(text, font, w)
    return LC93.Atoms.wrapText(text or "", font, math.max(1, w))
end

function LC93.Molecules.drawEmptyLine(panel, x, y, w, text)
    local T = LC93.T
    local f2 = T.fontF2
    local fh = LC93.TM:getFontHeight(f2)
    local tc = T.textDim
    local step = fh + T.px(2)
    local lines = wrapped(text, f2, w)
    for i, s in ipairs(lines) do
        panel:drawText(s, x, y + (i - 1) * step, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    return math.max(0, #lines * step - T.px(2))
end

function LC93.Molecules.cardContent(card)
    if not card then return nil end
    local c = card._balloon
    if c and c.title == card.title and c.lines == card.lines then return c end
    c = { kind = "rich", title = card.title, lines = card.lines }
    card._balloon = c
    return c
end
