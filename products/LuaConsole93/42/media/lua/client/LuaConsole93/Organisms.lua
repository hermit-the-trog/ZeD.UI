-- LuaConsole93/42/media/lua/client/LuaConsole93/Organisms.lua
-- ============================================================================================================
-- Lua Console 93 Professional Edition 1.0.0: the parts of ZeD-GUI's Organisms.lua the console uses (96 of its
-- 150 statements).
-- Made from ZeD-GUI's 42/media/lua/client/ZeD/Organisms.lua by ZeDUI/tools/products/build_luaconsole93.py. Do
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
require "LuaConsole93/AtomExtensions"
require "LuaConsole93/Molecules"
require "LuaConsole93/SafeMode"
require "LuaConsole93/LC93_Surface"

LC93 = LC93 or {}

local HELP_H   = 22
local EDGE_B   = 6
local EDGE_S   = 4
local GRIP_LEN = 40
local REST_MS  = 350
local SOLID_MS = 200

local SURF_KEYS = { "base", "surf1", "surf2", "surf3", "surf4" }

local function frameW(T) return T.line(T.borderW or 1) end

LC93_Window = ISPanel:derive("LC93_Window")

function LC93_Window:new(x, y, width, height, title)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.title = title or ""
    o.titleStats = {}
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0}
    o.borderColor     = {r = 0, g = 0, b = 0, a = 0}
    o.drawFrame     = false
    o.resizable     = true
    o.pin           = true
    o.clearStentil  = true
    o.windowShaded     = false
    o._lastTitleClick  = nil
    o.isLC93Window   = true

    return o
end

function LC93_Window:createChildren()
    local T = LC93.T
    local cbSz = T.closeBoxSz

    self._closeBtnRect = {
        x = T.sp.sm,
        y = math.floor((T.titleBarH - cbSz) / 2),
        w = cbSz, h = cbSz
    }
    self._closeHover = false
    self._closeWasDown = false

    self.closeButton = {}

    self.pinButton = {}
    self.collapseButton = {}

    self._resizing = false
    self.minimumWidth = T.minWinW
    self.minimumHeight = T.minWinH
end

function LC93_Window:titleBarHeight()
    return LC93.T.titleBarH
end

function LC93_Window:closeRect()
    local cb = self._closeBtnRect
    if not cb then return nil end
    local T = LC93.T
    local sz = T.closeBoxSz
    cb.x, cb.y, cb.w, cb.h = T.sp.sm, math.floor((self:titleBarHeight() - sz) / 2), sz, sz
    return cb
end

local COLLAPSE_MS = 2000
function LC93_Window:pinRect()
    if not self.autoCollapse then return nil end
    if self._halves and LC93.Halves then return LC93.Halves.pinRect(self, "right") end
    local box = self:windowBoxRect()
    if not box then return nil end
    local T = LC93.T
    local r = self._pinRect
    if not r then r = {}; self._pinRect = r end
    r.x, r.y, r.w, r.h = box.x - T.sp.sm - box.w, box.y, box.w, box.h
    return r
end
function LC93_Window:setPinned(on)
    if self._halves and LC93.Halves then LC93.Halves.setPin(self, nil, on); return end
    self.pinned = on and true or false
    if self.onPinChange then pcall(self.onPinChange, self, self.pinned) end
    if self.pinned and self._autoShaded and self.windowShaded then
        self._autoShaded = false
        self:setWindowShaded(false)
    end
end
local function pairWindows()
    local out = {}
    local CWm, WWm = LC93_CharacterWindow, LC93_WorldWindow
    for pn = 0, 3 do
        local cw = CWm and CWm.getWindow and CWm.getWindow(pn)
        local ww = WWm and WWm.getWindow and WWm.getWindow(pn)
        if cw then out[#out + 1] = cw end
        if ww then out[#out + 1] = ww end
    end
    return out
end

function LC93_Window:_autoCollapse()
    if not self.autoCollapse or not self:getIsVisible() then return end
    if self._halves and LC93.Halves then return LC93.Halves.update(self) end
    local pn = self.playerNum or 0
    local pad = JoypadState and JoypadState.players and JoypadState.players[pn + 1] ~= nil
    local now = getTimestampMs()
    local itemDrag = false
    for _, w in ipairs(pairWindows()) do
        local c = w and w._mainContent
        if c and c._drag and c._drag:isActive() then itemDrag = true end
        if w and w._equipDrag and w._equipDrag:isActive() then itemDrag = true end
    end
    if itemDrag and self.windowShaded and not (pad or self.pinned) then
        local dx, dy = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
        if dx >= 0 and dx <= self:getWidth() and dy >= 0 and dy < self:titleBarHeight() then
            self._autoShaded = false
            self:setWindowShaded(false)
        end
    end
    if pad or self.pinned or itemDrag or self.moving or isMouseButtonDown(0) or isMouseButtonDown(1) then
        self._outSince = nil
        return
    end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local inside = mx >= 0 and my >= 0 and mx <= self:getWidth() and my <= self:shownHeight()
    if inside then
        self._outSince = nil
        if self.windowShaded and my < self:titleBarHeight() then
            self._autoShaded = false
            self:setWindowShaded(false)
        end
        return
    end
    if self.windowShaded then self._outSince = nil; return end
    local p = getSpecificPlayer(pn)
    local aiming = false
    pcall(function() aiming = p and p:isAiming() end)
    self._outSince = self._outSince or now
    if aiming or now - self._outSince > COLLAPSE_MS then
        self._outSince = nil
        self._autoShaded = true
        self:setWindowShaded(true)
    end
end

function LC93_Window:windowBoxRect()
    if self.noWindowBox then return nil end
    local T = LC93.T
    local sz = T.closeBoxSz
    local r = self._wboxRect
    if not r then r = {}; self._wboxRect = r end
    r.x, r.y, r.w, r.h = self:getWidth() - T.sp.sm - sz, math.floor((self:titleBarHeight() - sz) / 2), sz, sz
    return r
end

function LC93_Window:shownHeight()
    if self.windowShaded or self.isCollapsed then return math.min(self:getHeight(), self:titleBarHeight()) end
    return self:getHeight()
end

function LC93_Window:setWindowShaded(shaded)
    local T = LC93.T
    if self.windowShaded == shaded then return end
    self.windowShaded = shaded
    local tbH = self:titleBarHeight()
    local ov = self._lc93Overlay
    if shaded then
        self.preShadeHeight = self.height
        self.minimumHeight = tbH
        self:setHeight(tbH)
        self:setMaxDrawHeight(tbH)
        local children = self:getChildren()
        if children then
            for _, child in pairs(children) do
                if child ~= ov then
                    child._wasVisible = child:isVisible()
                    child:setVisible(false)
                end
            end
        end
    else
        self.minimumHeight = T.minWinH
        self:clearMaxDrawHeight()
        self:setHeight(self.preShadeHeight or T.px(300))
        self._containerTimer = 30
        local children = self:getChildren()
        if children then
            for _, child in pairs(children) do
                if child._wasVisible ~= nil then
                    child:setVisible(child._wasVisible)
                    child._wasVisible = nil
                end
            end
        end
    end
end

function LC93_Window:resizeWidgetHeight()
    return LC93.T.px(HELP_H)
end

function LC93_Window:footerHeight()
    if self.themeFooter == false then return 0 end
    return LC93.T.px(HELP_H)
end

function LC93_Window:addToUIManager()
    if LC93.Theme and LC93.Theme.adopt then LC93.Theme.adopt(self, nil, true) end
    return ISPanel.addToUIManager(self)
end

function LC93_Window:prerender()
    LC93.Safe.guard(self, LC93_Window._drawFrame)
end

function LC93_Window:render()
    self:_restoreSurfaces()
    self:_restoreAccent()
end

function LC93_Window:setStencilRect(x, y, w, h)
    self._lc93StencilN = (self._lc93StencilN or 0) + 1
    local r = ISPanel.setStencilRect(self, x, y, w, h)
    if LC93.Surface and LC93.Surface._pushClip then LC93.Surface._pushClip(self, x, y, w, h) end
    return r
end

function LC93_Window:clearStencilRect()
    local n = self._lc93StencilN
    if n and n > 0 then self._lc93StencilN = n - 1 end
    if LC93.Surface and LC93.Surface._popClip then LC93.Surface._popClip() end
    return ISPanel.clearStencilRect(self)
end

local accentPalettes = {}
local function windowAccentPalette(baseKey, accentKey, statusKey, sa)
    local ck = baseKey .. "|" .. accentKey .. "|" .. tostring(statusKey) .. "|" .. tostring(sa)
    local p = accentPalettes[ck]
    if p then return p end
    local accentSet = LC93.AccentColors[accentKey]
    local variant = baseKey == "light" and accentSet.light or accentSet.dark
    p = {
        accent       = variant.accent,
        accentBright = variant.bright,
        hover        = variant.hover,
    }
    local base = LC93.BaseThemes[baseKey]
    if accentKey ~= "mono" then
        local TINT = 0.03
        local ac = baseKey == "light" and variant.bright or variant.accent
        local blend = LC93.colorBlend
        p.base    = blend(base.base, ac, TINT)
        p.surf1   = blend(base.surf1, ac, TINT)
        p.surf2   = blend(base.surf2, ac, TINT)
        p.surf3   = blend(base.surf3, ac, TINT)
        p.surf4   = blend(base.surf4, ac, TINT)
        p.border  = blend(base.border, ac, TINT)
        p.borderS = blend(base.borderS, ac, TINT)
        p.text     = blend(base.text, ac, TINT * 0.5)
        p.textHead = blend(base.textHead, ac, TINT * 0.5)
    else
        p.base = base.base;  p.surf1 = base.surf1; p.surf2 = base.surf2
        p.surf3 = base.surf3; p.surf4 = base.surf4
        p.border = base.border; p.borderS = base.borderS
        p.text = base.text; p.textHead = base.textHead
    end
    if type(sa) == "number" then
        local ca = LC93.colorAlpha
        p.base, p.surf1, p.surf2 = ca(p.base, sa), ca(p.surf1, sa), ca(p.surf2, sa)
        p.surf3, p.surf4 = ca(p.surf3, sa), ca(p.surf4, sa)
    end
    p.statusKey = statusKey
    LC93.deriveReadable(p, baseKey, statusKey)
    accentPalettes[ck] = p
    return p
end

function LC93_Window:_inUse()
    if self:pointerOn() then return true end
    local I = LC93.Input
    local F, Det = I and I.Focus, I and I.Detector
    if F and F.getFocusedWindow and F.getFocusedWindow(self.playerNum) == self
       and Det and Det.getMode and Det.getMode(self.playerNum) == "gamepad" then
        return true
    end
    local MM = LC93.MainMenu
    if MM and MM.gamepad and MM.activeWindow and MM.gamepad() and MM.activeWindow() == self then return true end
    return false
end

function LC93_Window:_surfaceAlpha(T)
    local S = LC93.Settings
    local base = (T.surf1 and T.surf1.a) or 1
    if base >= 0.999 or not (S and S.solidInUse and S.solidInUse()) then
        self._seeA, self._seeAt = nil, nil
        return nil
    end
    local now = getTimestampMs()
    local cur = self._seeA or base
    if cur < base then cur = base elseif cur > 1 then cur = 1 end
    local dt = now - (self._seeAt or now)
    self._seeAt = now
    local target = self:_inUse() and 1 or base
    if cur ~= target then
        local step = (1 - base) * dt / SOLID_MS
        if cur < target then cur = math.min(target, cur + step) else cur = math.max(target, cur - step) end
    end
    self._seeA = cur
    if cur - base < 0.004 then return nil end
    return cur
end

function LC93_Window:_swapSurfaces()
    local T = LC93.T
    local a = self:_surfaceAlpha(T)
    if not a then return end
    local saved = self._surfSaved
    if not saved then saved = {}; self._surfSaved = saved end
    local mine = self._surfMine
    if not mine then mine = {}; self._surfMine = mine end
    for i = 1, #SURF_KEYS do
        local k = SURF_KEYS[i]
        local c = T[k]
        saved[k] = c
        local m = mine[k]
        if not m then m = {}; mine[k] = m end
        m.r, m.g, m.b, m.a = c.r, c.g, c.b, a
        T[k] = m
    end
    self._surfT = T
end

function LC93_Window:_restoreSurfaces()
    local T = self._surfT
    if not T then return end
    local saved = self._surfSaved
    for i = 1, #SURF_KEYS do
        local k = SURF_KEYS[i]
        T[k] = saved[k]
    end
    self._surfT = nil
end

LC93_WindowOverlay = ISPanel:derive("LC93_WindowOverlay")

function LC93_WindowOverlay:new(win)
    local o = ISPanel:new(0, 0, win:getWidth(), win:getHeight())
    setmetatable(o, self)
    self.__index = self
    o.win = win
    o.background = false
    return o
end

function LC93_WindowOverlay:prerender() end

function LC93_WindowOverlay:render()
    local win = self.win
    if win then LC93.Safe.guard(win, LC93_Window._drawTop, "LC93_Window frame") end
end

function LC93_WindowOverlay:onMouseDown(x, y)
    local win = self.win
    if win and win:_resizeStartZone(x, y) then return true end
    return false
end
function LC93_WindowOverlay:onMouseUp() return false end
function LC93_WindowOverlay:onMouseUpOutside() return false end
function LC93_WindowOverlay:onRightMouseDown() return false end
function LC93_WindowOverlay:onRightMouseUp() return false end
function LC93_WindowOverlay:onMouseWheel() return false end
function LC93_WindowOverlay:onMouseMove() return false end
function LC93_WindowOverlay:onMouseMoveOutside() return false end

function LC93_Window:_keepOverlayLast()
    if not self.javaObject then return end
    local ov = self._lc93Overlay
    if not ov then
        ov = LC93_WindowOverlay:new(self)
        ov:initialise()
        ov:instantiate()
        ov.javaObject:setConsumeMouseEvents(false)
        self._lc93Overlay = ov
        ISUIElement.addChild(self, ov)
    end
    local w, h = self:getWidth(), self:shownHeight()
    if ov:getWidth() ~= w then ov:setWidth(w) end
    if ov:getHeight() ~= h then ov:setHeight(h) end
    if not ov:isVisible() then ov:setVisible(true) end
    local ctrls = self.javaObject:getControls()
    local n = ctrls and ctrls:size() or 0
    if n == 0 or ctrls:get(n - 1) ~= ov.javaObject then
        if self.children then ISUIElement.removeChild(self, ov) end
        ISUIElement.addChild(self, ov)
    end
end

local function drawWindowBox(p, x, y, sz, lit)
    local T = LC93.T
    local bg = lit and T.hover or T.surf2
    p:drawRect(x, y, sz, sz, 1, bg.r, bg.g, bg.b)
    local bs = T.borderS
    p:drawRectBorder(x, y, sz, sz, bs.a, bs.r, bs.g, bs.b)
    local ins = T.px(3)
    local lh = T.hair
    local inner = sz - 2 * ins
    local step = math.floor((inner - lh) / 2)
    local y0 = y + ins + math.floor((inner - (2 * step + lh)) / 2)
    local c = T.textDim
    for i = 0, 2 do
        p:drawRect(x + ins, y0 + i * step, sz - 2 * ins, lh, c.a or 1, c.r, c.g, c.b)
    end
end

function LC93_Window.drawPinBox(p, r, on, hover)
    local T = LC93.T
    local bg = hover and T.hover or T.surf2
    p:drawRect(r.x, r.y, r.w, r.h, 1, bg.r, bg.g, bg.b)
    local bs = T.borderS
    p:drawRectBorder(r.x, r.y, r.w, r.h, bs.a, bs.r, bs.g, bs.b)
    local ins = T.px(2)
    if LC93.Atoms.drawPxIcon then
        LC93.Atoms.drawPxIcon(p, "pin", r.x + ins, r.y + ins, r.w - ins * 2, on and 1 or 0.55, on and T.accent or T.textDim)
    end
end

local BLINK_MS = 500
LC93_Window.PIXEL_BLINK = true

local function clockStep(t, ms, m)
    local n = math.floor(t / ms)
    return n - math.floor(n / m) * m
end

function LC93_Window.pixelLit(blink, ms)
    if not blink or not LC93_Window.PIXEL_BLINK then return true end
    local S = LC93.Settings
    if S and S.healthBlink and not S.healthBlink() then return true end
    return clockStep(ms or getTimestampMs(), BLINK_MS, 2) == 0
end

local function fitStats(self, stats, right, edgeFull, edgeLeast, markRoom, gap, tm, f3)
    local tx, tw, mw = self._tsText, self._tsW, self._tsMark
    if not tx then
        tx, tw, mw = {}, {}, {}
        self._tsText, self._tsW, self._tsMark = tx, tw, mw
    end
    local dim = LC93.T.textDim
    local n = #stats
    for i = 1, n do
        local st = stats[i]
        local t = tostring(st.text or "")
        local w = tm:MeasureStringX(f3, t)
        local alts = st.alts
        for k = 1, (alts and #alts or 0) do
            local a = tostring(alts[k])
            local aw = tm:MeasureStringX(f3, a)
            if aw < w then t, w = a, aw end
        end
        local dc = st.color or dim
        mw[i] = (not st.noMark and (dc.a == nil or dc.a > 0)) and markRoom or 0
        tx[i], tw[i] = t, w
    end
    local first, total = n + 1, 0
    for i = n, 1, -1 do
        local add = tw[i] + mw[i] + ((i < n) and gap or 0)
        if right - (total + add) < edgeLeast then break end
        total, first = total + add, i
    end
    if right - total >= edgeFull then
        for i = n, first, -1 do
            local st = stats[i]
            local alts = st.alts
            local t, k = tostring(st.text or ""), 0
            while t ~= tx[i] do
                local w = tm:MeasureStringX(f3, t)
                if right - (total - tw[i] + w) >= edgeFull then
                    total = total - tw[i] + w
                    tx[i], tw[i] = t, w
                    break
                end
                k = k + 1
                if not (alts and alts[k]) then break end
                t = tostring(alts[k])
            end
        end
    end
    return first
end

function LC93_Window:_drawTitleBar(w, tbH)
    local T = LC93.T
    local sp = T.sp
    local tm = LC93.TM
    local f3 = T.fontF3
    local tbp = sp.titleBoxPad

    LC93.Surface.fill(self, 0, 0, w, tbH, "surf2")

    local box = self:windowBoxRect()
    local pinR = self:pinRect()
    local right = (pinR and (pinR.x - sp.md)) or (box and (box.x - sp.md)) or (w - sp.sm)
    local titleX = sp.sm + T.closeBoxSz + sp.md + ((self._halves and LC93.Halves) and LC93.Halves.titleShift(self) or 0)
    local textY = math.floor((tbH - (T.fontF3H or tm:getFontHeight(f3))) / 2)
    local mk, mkGap = T.px(6), T.px(4)
    local my = math.floor((tbH - mk) / 2)
    local pix = self._titleMark
    local pixW = pix and (mk + mkGap) or 0
    local nameX = titleX + pixW
    local reserve = self._titleReserve or 0
    local shown, tW = nil, 0
    local title = (not self._hideTitle) and self.title or nil
    if title == "" then title = nil end
    local yields = title and self._titleYields
    local fullW, leastW
    if yields then
        title = tostring(title)
        fullW = tm:MeasureStringX(f3, title)
        leastW = math.min(fullW, tm:MeasureStringX(f3, "Mmmm..."))
    elseif title then
        shown = LC93.Atoms.truncateText(tostring(title), f3, math.max(0, right - nameX - tbp - reserve))
        tW = tm:MeasureStringX(f3, shown)
        fullW, leastW = tW, tW
    else
        fullW, leastW = 0, 0
    end

    local statL = nil
    local stats = self.titleStats
    if stats and #stats > 0 then
        local pad = tbp * 2 + sp.md + reserve
        local first = fitStats(self, stats, right, nameX + fullW + pad, nameX + leastW + pad, mk + mkGap, sp.md, tm, f3)
        local tx, tw, mw = self._tsText, self._tsW, self._tsMark
        local sx = right
        local tc = T.text
        for i = #stats, first, -1 do
            local dc = stats[i].color or T.textDim
            sx = sx - tw[i]
            self:drawText(tx[i], sx, textY, tc.r, tc.g, tc.b, tc.a or 1, f3)
            if mw[i] > 0 then
                sx = sx - mkGap - mk
                self:drawRect(sx, my, mk, mk, dc.a or 1, dc.r, dc.g, dc.b)
            end
            statL = sx
            sx = sx - sp.md
        end
    end
    if yields then
        local stop = statL and (statL - tbp * 2 - sp.md) or (right - tbp)
        shown = LC93.Atoms.truncateText(title, f3, math.max(0, stop - nameX - reserve))
        tW = tm:MeasureStringX(f3, shown)
    end
    self._titleShownW = pixW + tW
    self._titleHitL, self._titleHitR = titleX, nameX + tW

    local st = T.stripe
    if st and st.a > 0 then
        local head = shown or pix
        local k1L, k1R = head and (titleX - tbp) or nil, head and (nameX + tW + tbp) or nil
        local k2L, k2R = statL and (statL - tbp) or nil, statL and (right + tbp) or nil
        local sh = T.px(1)
        for sy = T.px(2), tbH - T.px(2), T.px(4) do
            local x0 = 0
            if k1L then
                if k1L > x0 then self:drawRect(x0, sy, k1L - x0, sh, st.a, st.r, st.g, st.b) end
                x0 = k1R
            end
            if k2L then
                if k2L > x0 then self:drawRect(x0, sy, k2L - x0, sh, st.a, st.r, st.g, st.b) end
                if k2R > x0 then x0 = k2R end
            end
            if w > x0 then self:drawRect(x0, sy, w - x0, sh, st.a, st.r, st.g, st.b) end
        end
    end

    if pix and LC93_Window.pixelLit(self._titleMarkBlink) then
        self:drawRect(titleX, my, mk, mk, pix.a or 1, pix.r, pix.g, pix.b)
    end
    if shown then
        local th = T.textHead
        self:drawText(shown, nameX, textY, th.r, th.g, th.b, th.a or 1, f3)
    end
    if self._closeBtnRect and not self._closeOnRod then
        local cb = self:closeRect()
        LC93.Atoms.drawCloseBox(self, cb.x, cb.y, cb.w, self._closeHover)
    end
    if box then drawWindowBox(self, box.x, box.y, box.w, self._wboxHover or self._wboxOpen) end
    if self._halves and LC93.Halves then
        LC93.Halves.drawTitlePins(self)
    elseif pinR then
        LC93_Window.drawPinBox(self, pinR, self.pinned, self._pinHover)
    end

    if not (self.isCollapsed or self.windowShaded) then
        local fw = frameW(T)
        local bs = T.borderS
        self:drawRect(fw, tbH - T.hair, w - 2 * fw, T.hair, bs.a, bs.r, bs.g, bs.b)
    end
end

function LC93_Window:_drawFrame()
    local T = LC93.T

    local bk = T.baseKey or LC93.currentBase
    if self._accentKey and LC93.AccentColors[self._accentKey] and LC93.BaseThemes[bk] then
        local sa = T.surfaceAlpha
        if T.baseKey == nil then sa = LC93.surfaceAlpha end
        local pal = windowAccentPalette(bk, self._accentKey, T.statusKey or LC93.currentStatus, sa)
        local s = self._accentStore
        if not s then s = {}; self._accentStore = s end
        s.accent       = T.accent
        s.accentBright = T.accentBright
        s.hover        = T.hover
        local rk = LC93.READABLE_KEYS
        for i = 1, #rk do s[rk[i]] = T[rk[i]] end
        s.base = T.base; s.surf1 = T.surf1; s.surf2 = T.surf2
        s.surf3 = T.surf3; s.surf4 = T.surf4
        s.border = T.border; s.borderS = T.borderS
        s.text = T.text; s.textHead = T.textHead
        self._savedAccent = s
        self._accentT = T
        T.accent       = pal.accent
        T.accentBright = pal.accentBright
        T.hover        = pal.hover
        for i = 1, #rk do T[rk[i]] = pal[rk[i]] end
        T.base = pal.base; T.surf1 = pal.surf1; T.surf2 = pal.surf2
        T.surf3 = pal.surf3; T.surf4 = pal.surf4
        T.border = pal.border; T.borderS = pal.borderS
        T.text = pal.text; T.textHead = pal.textHead
    end
    self:_swapSurfaces()

    self:_keepOverlayLast()
    LC93.Surface.beginFrame(self)

    local w = self:getWidth()
    local h = self:getHeight()
    local tbH = self:titleBarHeight()
    if not self._lc93Home then self._lc93Home = { x = self:getX(), y = self:getY(), w = w, h = h } end

    self.minimumWidth = T.minWinW
    self.minimumHeight = (self.windowShaded or self.isCollapsed) and tbH or T.minWinH

    self:_drawTitleBar(w, tbH)

    if not self.isCollapsed and not self.windowShaded then
        LC93.Surface.drawBody(self, 0, tbH, w, h - tbH - self:footerHeight(), "surf1")
    end
end

local PROMPT_LABELS = {
    ["invrow"]          = { a = "UI_LC93_Prompt_Card",   hold = "UI_LC93_Prompt_Use", x = "UI_LC93_Prompt_Menu" },
    ["tab"]             = { a = "IGUI_Open" },
    ["jsub"]            = { a = "UI_LC93_Prompt_Switch" },
    ["animals:submode"] = { a = "UI_LC93_Prompt_Switch" },
    ["container"]       = { a = "IGUI_Open" },
    ["cnt"]             = { a = "IGUI_Open" },
    ["map:canvas"]      = { a = "IGUI_Place",  x = "UI_LC93_Prompt_Edit" },
    ["map:fold"]        = { a = "UI_LC93_Prompt_Fold" },
    ["map:popout"]      = { a = "UI_LC93_Prompt_Unfold" },
    ["map:tool"]        = { a = "UI_LC93_Prompt_Tool" },
    ["map:gridtool"]    = { a = "UI_LC93_Prompt_Tool",   x = "UI_LC93_Prompt_Pin" },
    ["map:color"]       = { a = "IGUI_Color" },
    ["craft:row"]       = { a = "UI_LC93_Prompt_Recipe" },
    ["jrecipe:row"]     = { a = "UI_LC93_Prompt_Recipe" },
    ["build:row"]       = { a = "UI_LC93_Prompt_Recipe" },
    ["health:start"]    = { a = "UI_LC93_Prompt_Start" },
    ["skill:"]          = { a = "UI_LC93_Prompt_Pin" },
    ["equipslot"]       = { a = "UI_LC93_Prompt_Card" },
    ["equippart"]       = { a = "UI_LC93_Prompt_Card" },
    ["cancel_band"]     = { a = "UI_Cancel" },
}

local function _addListPrompts(win, prompts)
    local z = win._focusRing and win._focusIdx and win._focusRing[win._focusIdx]
    local zn = z and tostring(z.zone) or ""
    if not (zn:find("MainInv$") or zn:find("MC%d+$")) then return end
    local R = LC93.InventoryRenderer
    local extra = R and R.padPrompts and R.padPrompts(win)
    for i = #(extra or {}), 1, -1 do table.insert(prompts, 1, extra[i]) end
end

local function _pv(v, win, el)
    if type(v) == "function" then
        local ok, r = pcall(v, win, el)
        if ok then return r end
        return nil
    end
    return v
end

local function _promptsFor(el, win)
    local out = {}
    if not el then
        out[#out + 1] = { glyph = "Y", label = LC93.tr("UI_LC93_Prompt_Windows") }
        return out
    end
    local id = tostring(el.id or "")
    local labels, bestLen = nil, 0
    for prefix, def in pairs(PROMPT_LABELS) do
        if id:sub(1, #prefix) == prefix and #prefix > bestLen then labels = def; bestLen = #prefix end
    end
    labels = labels or {}
    local pA, pH, pX, pB = _pv(el.promptA, win, el), _pv(el.promptHold, win, el), _pv(el.promptX, win, el), _pv(el.promptB, win, el)
    if el.onActivate     and pA ~= false then out[#out + 1] = { glyph = "A", label = pA or LC93.tr(labels.a or "UI_LC93_Prompt_Select") } end
    if el.onHoldActivate and pH ~= false then out[#out + 1] = { glyph = "A", label = LC93.tr("UI_LC93_Prompt_Hold", pH or LC93.tr(labels.hold or "UI_LC93_Prompt_Use")) } end
    if el.onContextMenu  then if pX ~= false then out[#out + 1] = { glyph = "X", label = pX or LC93.tr(labels.x or "UI_LC93_Prompt_Menu") } end
    elseif el.onReset    then out[#out + 1] = { glyph = "X", label = LC93.tr("UI_LC93_Prompt_Reset") } end
    if el.onCancel       and pB ~= false then out[#out + 1] = { glyph = "B", label = pB or LC93.tr(labels.b or "UI_LC93_Prompt_Back") } end
    if el.extraPrompts then for _, p in ipairs(el.extraPrompts) do out[#out + 1] = p end end
    out[#out + 1] = { glyph = "Y", label = LC93.tr("UI_LC93_Prompt_Windows") }
    return out
end

function LC93_Window:_footerPrompts()
    if self.getFooterPrompts then
        local own = self:getFooterPrompts()
        if own then return own end
    end
    local I = LC93.Input
    local Focus, Det = I and I.Focus, I and I.Detector
    if not (Det and Det.getMode and Det.getMode(self.playerNum) == "gamepad") then return nil end
    if not (Focus and Focus.getFocusedWindow and Focus.getFocusedWindow(self.playerNum) == self) then return nil end
    local el = Focus.getFocusedElement and Focus.getFocusedElement(self)
    local prompts = _promptsFor(el, self)
    pcall(_addListPrompts, self, prompts)
    if Focus.isLocked and Focus.isLocked() then
        for i = #prompts, 1, -1 do
            if prompts[i].glyph == "Y" then table.remove(prompts, i) end
        end
        prompts[#prompts + 1] = { glyph = "Y", label = LC93.tr("UI_LC93_Prompt_Locked") }
    end
    return prompts
end

local _pw, _pr, _pg = {}, {}, {}
local function drawPrompts(p, prompts, x, y, h, maxX, pn)
    local T = LC93.T
    local tm = LC93.TM
    local f2, f5 = T.fontF2, T.fontF5
    local pic = T.px(14)
    local gap, between = T.px(4), T.px(8)
    local PG = LC93.PadGlyphs
    local set = PG and PG.set(pn)
    local k = PG and PG.k(pic) or 1
    local n = #prompts
    local total = 0
    for i = 1, n do
        local pr = prompts[i]
        local label, gw, roles = nil, 0, false
        if type(pr) == "string" then
            label = pr
        else
            label = tostring(pr.label or "")
            roles = (set and (pr.pad or PG.roles(pr.glyph))) or false
            if roles then gw = PG.width(roles, k, set)
            else gw = math.max(pic, tm:MeasureStringX(f5, tostring(pr.glyph or "")) + T.px(4)) end
        end
        local wi = ((gw > 0) and (gw + gap) or 0) + ((label ~= "") and tm:MeasureStringX(f2, label) or 0)
        _pw[i], _pr[i], _pg[i] = wi, roles, gw
        total = total + wi + ((i > 1) and between or 0)
    end
    local first = 1
    while first < n and x + total > maxX do
        total = total - _pw[first] - between
        first = first + 1
    end
    if x + total > maxX then return end
    local fh2 = T.fontF2H or tm:getFontHeight(f2)
    local textY = y + math.floor((h - fh2) / 2)
    local bs, tc, td = T.borderS, T.text, T.textDim
    for i = first, n do
        local pr = prompts[i]
        local gw = _pg[i]
        if type(pr) == "string" then
            p:drawText(pr, x, textY, td.r, td.g, td.b, td.a or 1, f2)
        else
            if _pr[i] then
                PG.draw(p, _pr[i], x, y, h, k, set)
            else
                local g = tostring(pr.glyph or "")
                local gy = y + math.floor((h - pic) / 2)
                local fh5 = T.fontF5H or tm:getFontHeight(f5)
                p:drawRectBorder(x, gy, gw, pic, bs.a, bs.r, bs.g, bs.b)
                p:drawText(g, x + math.floor((gw - tm:MeasureStringX(f5, g)) / 2), gy + math.floor((pic - fh5) / 2), tc.r, tc.g, tc.b, tc.a or 1, f5)
            end
            local label = tostring(pr.label or "")
            if label ~= "" then p:drawText(label, x + gw + gap, textY, tc.r, tc.g, tc.b, tc.a or 1, f2) end
        end
        x = x + _pw[i] + between
    end
end

local function drawRidges(p, x, y, size, lt, la, mirror)
    local T = LC93.T
    local dk = T.base
    local da = T.ridgeDarkA or 0.5
    local u = T.px(1)
    for i = 0, 2 do
        local off = T.px(i * 4)
        local x1 = x + size - T.px(4) - off
        local y1 = y + size - T.px(2)
        local x2 = x + size - T.px(2)
        local y2 = y + size - T.px(4) - off
        local steps = math.floor(math.max(math.abs(x2 - x1), math.abs(y2 - y1)) / u)
        if steps > 0 then
            for s = 0, steps do
                local px = x1 + math.floor((x2 - x1) * s / steps)
                local py = y1 + math.floor((y2 - y1) * s / steps)
                if mirror then px = 2 * x + size - px - u end
                p:drawRect(px, py, u, u, la, lt.r, lt.g, lt.b)
                local sx, sy = px + u, py + u
                if sx > x and sx < x + size - u and sy < y + size - u then
                    p:drawRect(sx, sy, u, u, da, dk.r, dk.g, dk.b)
                end
            end
        end
    end
end

local function drawGrow(p, x, y, sz, lit, mirror)
    if not lit and not mirror then LC93.Atoms.drawGrowBox(p, x, y, sz); return end
    local T = LC93.T
    local bg, bs = T.surf2, T.borderS
    p:drawRect(x, y, sz, sz, bg.a or 1, bg.r, bg.g, bg.b)
    p:drawRectBorder(x, y, sz, sz, bs.a, bs.r, bs.g, bs.b)
    if lit then drawRidges(p, x, y, sz, T.accent, 1, mirror)
    else drawRidges(p, x, y, sz, T.textDim, T.ridgeLightA or 0.6, mirror) end
end

function LC93_Window:_drawHelpLine(p, w, h, lit)
    if not self._helpText then
        local uh = (self._wboxHover and LC93.tr("UI_LC93_WinMenu_Help"))
            or (self._closeHover and LC93.tr("UI_LC93_WinMenu_CloseHelp")) or self._updHelp
        if uh then LC93.Help.set(self, uh) end
    end
    local text = LC93.Help.take(self)
    local T = LC93.T
    local fH = self:footerHeight()
    local grow = self.resizable and self:resizeWidgetHeight() or 0
    if fH > 0 then
        local fY = h - fH
        local fw = frameW(T)
        LC93.Surface.fill(p, 0, fY, w - grow, fH, "surf2")
        local bs = T.borderS
        p:drawRect(fw, fY, w - 2 * fw, T.hair, bs.a, bs.r, bs.g, bs.b)
        local x0 = (lit == "sw") and (grow + T.px(6)) or T.px(10)
        local maxX = w - grow - T.px(10)
        local prompts = self:_footerPrompts()
        if prompts and #prompts > 0 then
            drawPrompts(p, prompts, x0, fY, fH, maxX, self.playerNum)
        else
            if lit then text = LC93.tr("UI_LC93_Window_ResizeHelp") end
            if text and maxX > x0 then
                local f2 = T.fontF2
                local d = T.textDim
                local fh2 = T.fontF2H or LC93.TM:getFontHeight(f2)
                p:drawText(LC93.Atoms.truncateText(text, f2, maxX - x0), x0, fY + math.floor((fH - fh2) / 2), d.r, d.g, d.b, d.a or 1, f2)
            end
        end
    end
    if grow > 0 then drawGrow(p, w - grow, h - grow, grow, lit == "se", false) end
end

local function drawHandle(win, p, w, h, lit)
    local T = LC93.T
    local fw = frameW(T)
    local ac, dk, s2 = T.accent, T.base, T.surf2
    local da = T.ridgeDarkA or 0.5
    local hair = T.hair
    local len = T.px(GRIP_LEN)
    local sg, pad = T.px(3), T.px(2)
    if lit == "s" then
        local gx = math.floor((w - len) / 2)
        local yA = h - fw - T.px(2) - 2 * hair
        local yB = yA - sg
        p:drawRect(gx - pad, yB - pad, len + 2 * pad, h - fw - (yB - pad), 1, s2.r, s2.g, s2.b)
        p:drawRect(gx, yB, len, hair, 1, ac.r, ac.g, ac.b)
        p:drawRect(gx, yB + hair, len, hair, da, dk.r, dk.g, dk.b)
        p:drawRect(gx, yA, len, hair, 1, ac.r, ac.g, ac.b)
        p:drawRect(gx, yA + hair, len, hair, da, dk.r, dk.g, dk.b)
    elseif lit == "w" or lit == "e" then
        local top = win:titleBarHeight()
        local gy = top + math.floor((h - top - win:footerHeight() - len) / 2)
        local xA, xB
        if lit == "w" then xA = fw + T.px(1); xB = xA + sg
        else xB = w - fw - T.px(1) - 2 * hair; xA = xB - sg end
        p:drawRect(xA - pad + T.px(1), gy - pad, xB + 2 * hair - xA + 2 * pad - T.px(1), len + 2 * pad, 1, s2.r, s2.g, s2.b)
        p:drawRect(xA, gy, hair, len, 1, ac.r, ac.g, ac.b)
        p:drawRect(xA + hair, gy, hair, len, da, dk.r, dk.g, dk.b)
        p:drawRect(xB, gy, hair, len, 1, ac.r, ac.g, ac.b)
        p:drawRect(xB + hair, gy, hair, len, da, dk.r, dk.g, dk.b)
    elseif lit == "sw" then
        local sz = win:resizeWidgetHeight()
        drawGrow(p, 0, h - sz, sz, true, true)
    end
end

local function drawFrameRect(p, w, h, lit)
    local T = LC93.T
    local t = frameW(T)
    local bs, ac = T.borderS, T.accent
    p:drawRect(0, 0, w, t, bs.a, bs.r, bs.g, bs.b)
    local c = (lit == "s") and ac or bs
    p:drawRect(0, h - t, w, t, c.a or 1, c.r, c.g, c.b)
    c = (lit == "w") and ac or bs
    p:drawRect(0, t, t, h - 2 * t, c.a or 1, c.r, c.g, c.b)
    c = (lit == "e") and ac or bs
    p:drawRect(w - t, t, t, h - 2 * t, c.a or 1, c.r, c.g, c.b)
end

local PAIR_GAP = 16
local function drawPairGap(win, p, w, h)
    local k = win:pairKey()
    if not k then return end
    local CWm, WWm = LC93_CharacterWindow, LC93_WorldWindow
    local other
    if k == "char" then other = WWm and WWm.getWindow and WWm.getWindow(win.playerNum) else other = CWm and CWm.getWindow and CWm.getWindow(win.playerNum) end
    if not (other and other:isVisible()) then return end
    local gap = other:getX() - (win:getX() + w)
    if gap <= 0 or gap > LC93.T.px(PAIR_GAP) then return end
    local y0 = win:getY()
    local top = math.max(y0, other:getY())
    local bot = math.min(y0 + h, other:getY() + other:shownHeight())
    if bot <= top then return end
    local bs = LC93.T.borderS
    p:drawRect(w, top - y0, gap, bot - top, bs.a or 1, bs.r, bs.g, bs.b)
end

function LC93_Window._drawTop(win)
    local p = win._lc93Overlay
    if not p then return end
    local w, h = win:getWidth(), win:shownHeight()
    local shaded = win.isCollapsed or win.windowShaded
    local lit = (not shaded) and win._rzLit or nil
    win:_watchBoxes()
    if not shaded then
        win:_drawHelpLine(p, w, h, lit)
        if lit then drawHandle(win, p, w, h, lit) end
    end
    drawFrameRect(p, w, h, lit)
    drawPairGap(win, p, w, h)
    local F = LC93.Focus
    if F and F.drawOverlay then
        local ok, err = pcall(F.drawOverlay, p, win)
        if not ok then LC93.logOnce("LC93.Focus.drawOverlay", err) end
    end
end

function LC93_Window:_restoreAccent()
    local T = self._accentT or LC93.T
    self._accentT = nil
    if self._savedAccent then
        local s = self._savedAccent
        T.accent       = s.accent
        T.accentBright = s.accentBright
        T.hover        = s.hover
        local rk = LC93.READABLE_KEYS
        for i = 1, #rk do T[rk[i]] = s[rk[i]] end
        T.base = s.base; T.surf1 = s.surf1; T.surf2 = s.surf2
        T.surf3 = s.surf3; T.surf4 = s.surf4
        T.border = s.border; T.borderS = s.borderS
        T.text = s.text; T.textHead = s.textHead
        self._savedAccent = nil
    end
end

function LC93_Window:_resizeZoneAt(mx, my)
    if not self.resizable or self.windowShaded or self.isCollapsed then return nil end
    local T = LC93.T
    local w, h = self:getWidth(), self:getHeight()
    if mx < 0 or my < 0 or mx >= w or my >= h then return nil end
    local cz = self:resizeWidgetHeight()
    if my >= h - cz then
        if mx >= w - cz then return "se" end
        if mx < cz then return "sw" end
    end
    if my >= h - T.px(EDGE_B) then return "s" end
    if my >= self:titleBarHeight() then
        local e = T.px(EDGE_S)
        if mx < e then return "w" end
        if mx >= w - e then return "e" end
    end
    return nil
end

function LC93_Window:_resizeStartZone(mx, my)
    local z = self:_resizeZoneAt(mx, my)
    if (z == "w" or z == "e") and self._rzLit ~= z then return nil end
    return z
end

function LC93_Window:_startResize(mode)
    self._resizing = true
    self._resizeMode = mode
    self._resizeYOnly = (mode == "s")
    self._resizeRight = self:getX() + self:getWidth()
    self._growBoxWasDown = true
    self.moving = false
    self:setCapture(true)
    self:bringToTop()
end

function LC93_Window:_stopResize()
    local mode = self._resizeMode
    self._resizing = false
    self._resizeYOnly = false
    self._resizeMode = nil
    self._growBoxWasDown = false
    self:setCapture(false)
    if mode then self._rzZone = mode; self._rzSince = getTimestampMs() - REST_MS end
end

function LC93_Window:_resizeStep()
    local T = LC93.T
    local mode = self._resizeMode or "se"
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local mx, my = getMouseX(), getMouseY()
    local minW = self.minimumWidth or T.px(200)
    local minH = self.minimumHeight or T.px(120)
    if mode == "s" or mode == "se" or mode == "sw" then
        local _, screenH, _, screenT = LC93.screenOf(self)
        local newH = math.min(my - ay, screenT + screenH - self:getY())
        newH = math.max(newH, minH)
        if newH ~= self:getHeight() then self:setHeight(newH) end
    end
    if mode == "se" or mode == "e" then
        local newW = math.max(mx - ax, minW)
        if newW ~= self:getWidth() then self:setWidth(newW) end
    elseif mode == "sw" or mode == "w" then
        local right = self._resizeRight or (self:getX() + self:getWidth())
        local mxp = mx - (ax - self:getX())
        local newW = math.min(math.max(right - mxp, minW), right)
        if newW ~= self:getWidth() then self:setWidth(newW) end
        local nx = right - self:getWidth()
        if nx ~= self:getX() then self:setX(nx) end
    end
end

function LC93_Window:_updateResize(down, fresh, mx, my)
    if not self.resizable or self.windowShaded or self.isCollapsed then
        if self._resizing then self:_stopResize() end
        self._rzLit, self._rzZone = nil, nil
        return
    end
    if self._resizing then
        if down then
            self:_resizeStep()
            self._rzLit = self._resizeMode
            return
        end
        self:_stopResize()
    end
    local zone = self:pointerOn() and self:_resizeZoneAt(mx, my) or nil
    if fresh and zone then
        local start = self:_resizeStartZone(mx, my)
        if start then
            self:_startResize(start)
            self._rzLit = start
            return
        end
    end
    local now = getTimestampMs()
    if zone ~= self._rzZone then self._rzZone = zone; self._rzSince = now end
    if down then self._rzSince = now end
    self._rzLit = (zone and now - (self._rzSince or now) >= REST_MS) and zone or nil
end

function LC93_Window:onMouseDown(x, y)
    if not self:getIsVisible() then return end

    if self._resizing then return true end

    local start = self:_resizeStartZone(x, y)
    if start then
        self:_startResize(start)
        return true
    end

    local box = self:windowBoxRect()
    if box and x >= box.x and x < box.x + box.w and y >= box.y and y < box.y + box.h then return true end
    local pr = self:pinRect()
    if pr and x >= pr.x and x < pr.x + pr.w and y >= pr.y and y < pr.y + pr.h then return true end
    local lp = self._halves and LC93.Halves and LC93.Halves.pinRect(self, "left")
    if lp and x >= lp.x and x < lp.x + lp.w and y >= lp.y and y < lp.y + lp.h then return true end

    local tbH = self:titleBarHeight()
    if y < tbH and y > 0 then
        local now = getTimestampMs()
        if self._lastTitleClick and (now - self._lastTitleClick) < 500 then
            self:setWindowShaded(not self.windowShaded)
            self._lastTitleClick = nil
            self.moving = false
            return true
        end
        self._lastTitleClick = now
    end

    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
    return true
end

function LC93_Window:onMouseMove(dx, dy)
    if self._resizing then
        if not isMouseButtonDown(0) then
            self:_stopResize()
            return
        end
        self:_resizeStep()
        return
    end
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function LC93_Window:onMouseMoveOutside(dx, dy)
    if self._resizing then
        self:onMouseMove(dx, dy)
        return
    end
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function LC93_Window:onMouseUp(x, y)
    if self._resizing then
        self:_stopResize()
        return true
    end
    self.moving = false
end

function LC93_Window:onMouseUpOutside(x, y)
    if self._resizing then
        self:_stopResize()
        return true
    end
    self.moving = false
end

function LC93.screenOf(w)
    if LC93.splitWindows == true then
        local pn = (type(w) == "number") and w or (type(w) == "table" and w.playerNum) or nil
        if type(pn) == "number" then
            local x, y, pw, ph = LC93.playerRect(pn)
            return pw, ph, x, y
        end
    end
    local core = getCore()
    return core:getScreenWidth(), core:getScreenHeight(), 0, 0
end

function LC93_Window:pairKey()
    local cw = LC93_CharacterWindow and LC93_CharacterWindow.getWindow and LC93_CharacterWindow.getWindow(self.playerNum)
    if cw == self then return "char" end
    local ww = LC93_WorldWindow and LC93_WorldWindow.getWindow and LC93_WorldWindow.getWindow(self.playerNum)
    if ww == self then return "world" end
    return nil
end

function LC93_Window:openWindowMenu()
    local WM = LC93.WindowMenu
    if not (WM and WM.open) then return end
    local ok, err = pcall(WM.open, self)
    if not ok then LC93.logOnce("window menu", err) end
end

function LC93_Window:pointerOn() return self:isMouseOver() end

function LC93_Window:_watchBoxes()
    local down = isMouseButtonDown(0)
    local fresh = down and not self._boxPrevDown
    self._boxPrevDown = down
    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()

    if self._closeBtnRect and not self._closeOnRod then
        local cb = self:closeRect()
        local inside = mx >= cb.x and mx <= cb.x + cb.w and my >= cb.y and my <= cb.y + cb.h
        if inside and not self:pointerOn() then inside = false end
        self._closeHover = inside
        if down then
            if fresh and inside then self._closeWasDown = true end
        elseif self._closeWasDown then
            self._closeWasDown = false
            if inside then self._boxDo = "close" end
        end
    end

    local box = self:windowBoxRect()
    if box then
        local inside = mx >= box.x and mx < box.x + box.w and my >= box.y and my < box.y + box.h
        if inside and not self:pointerOn() then inside = false end
        self._wboxHover = inside
        if down then
            if fresh and inside then self._wboxWasDown = true end
        elseif self._wboxWasDown then
            self._wboxWasDown = false
            if inside then self._boxDo = "menu" end
        end
    else
        self._wboxHover = false
    end
    local pr = self:pinRect()
    if self._halves and LC93.Halves then
        LC93.Halves.watch(self, mx, my, down, fresh)
    elseif pr then
        local inside = mx >= pr.x and mx < pr.x + pr.w and my >= pr.y and my < pr.y + pr.h
        if inside and not self:pointerOn() then inside = false end
        self._pinHover = inside
        if inside then self._updHelp = LC93.tr(self.pinned and "UI_LC93_Win_HelpUnpin" or "UI_LC93_Win_HelpPin") end
        if down then
            if fresh and inside then self._pinWasDown = true end
        elseif self._pinWasDown then
            self._pinWasDown = false
            if inside then self._boxDo = "pin" end
        end
    else
        self._pinHover = false
    end
    local th = self._titleHelp
    if th and self._titleHitR and my >= 0 and my < self:titleBarHeight() and mx >= self._titleHitL
        and mx < self._titleHitR and self:pointerOn() then
        self._updHelp = th
    end
end

function LC93_Window:update()
    ISPanel.update(self)
    self._updHelp = nil

    self:_watchBoxes()
    local act = self._boxDo
    self._boxDo = nil
    if act == "close" then
        if self.closeAction then self:closeAction() else self:close() end
        return
    elseif act == "menu" then
        self:openWindowMenu()
    elseif act == "pin" then
        self:setPinned(not self.pinned)
    elseif (act == "pin:inv" or act == "pin:drawer") and LC93.Halves then
        LC93.Halves.togglePin(self, act:sub(5))
    end
    self:_autoCollapse()

    local down = isMouseButtonDown(0)
    local fresh = down and not self._uiPrevDown
    self._uiPrevDown = down
    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    self:_updateResize(down, fresh, mx, my)
end

function LC93_Window:close()
    self:setVisible(false)
end

function LC93_Window:onJoypadDown(button, joypadData)
    if LC93 and LC93.Input and LC93.Input.Focus
       and LC93.Input.Focus.getFocusedWindow(joypadData and joypadData.player) == self then
        LC93.Input.Focus.dispatchJoypadDown(self, button, joypadData)
    end
end

function LC93_Window:onJoypadDirUp(joypadData)
    if LC93 and LC93.Input and LC93.Input.Focus
       and LC93.Input.Focus.getFocusedWindow(joypadData and joypadData.player) == self then
        LC93.Input.Focus.dispatchJoypadDir(self, "up", joypadData)
    end
end

function LC93_Window:onJoypadDirDown(joypadData)
    if LC93 and LC93.Input and LC93.Input.Focus
       and LC93.Input.Focus.getFocusedWindow(joypadData and joypadData.player) == self then
        LC93.Input.Focus.dispatchJoypadDir(self, "down", joypadData)
    end
end

function LC93_Window:onJoypadDirLeft(joypadData)
    if LC93 and LC93.Input and LC93.Input.Focus
       and LC93.Input.Focus.getFocusedWindow(joypadData and joypadData.player) == self then
        LC93.Input.Focus.dispatchJoypadDir(self, "left", joypadData)
    end
end

function LC93_Window:onJoypadDirRight(joypadData)
    if LC93 and LC93.Input and LC93.Input.Focus
       and LC93.Input.Focus.getFocusedWindow(joypadData and joypadData.player) == self then
        LC93.Input.Focus.dispatchJoypadDir(self, "right", joypadData)
    end
end
