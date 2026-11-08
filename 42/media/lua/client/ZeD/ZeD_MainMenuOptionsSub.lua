-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuOptionsSub.lua
-- ============================================================================
-- TWO OPTIONS SUB-PAGES. Client-side; extends the ZeD_MMOptions organism
-- (ZeD_MainMenuOptions.lua) with two pages that replace whole vanilla screens,
-- part of replacing every vanilla window.
--
-- Two of vanilla's screens that ZeD's Options window (ZeD_MainMenuOptions.lua,
-- on the monitor and over the world in game) would otherwise hand over whole
-- are pages of the same window here, with Back to the page they came from:
--
-- BUTTON MAP AND TEST (Controls > Button map and test; in place of vanilla's
--   controller page with ISControllerBindingsEditorPanel and
--   ISControllerTestPanel). On the left a pad drawn in ZeD's lines with ZeD's
--   own button pictures (ZeD_PadGlyphs, the pad set the glyph setting picks):
--   each button lights while it is held, the sticks' dots move, the triggers
--   fill. It follows the controller chosen to test (vanilla's own pick, which
--   holds the pad for the test until A and Y are held together, as vanilla),
--   else the controller driving the menu. On the right every button, trigger
--   and stick with what it does in game; A or a click opens the actions as a
--   pull-down with the bound ones ticked, and a pick adds or takes that action
--   off it. Edits run on vanilla's bindings and its editor's own hand-off
--   (onJoypadButtonBindingEdited: a fixed preset becomes a new one, Apply
--   saves). The preset, button style, dead zone and the controllers in use
--   stay rows on the Controls page.
-- ADVANCED GAME SOUNDS (Audio > Advanced, only when the game's advanced sound
--   options are on; in place of ISGameSounds). The game's sound categories
--   down the left, each sound with a volume slider (0 to 200 percent in steps
--   of 5, as vanilla) and Play / Stop to hear it. Leaving the page saves the
--   volumes as vanilla's Close does (GameSounds.saveINI).
--
-- The window's methods this file takes over keep their originals once as
-- O._zedBase_*; while no sub-page is open (self.sub is nil) each one hands
-- straight back to its original.
-- Safe mode: ZeD's Options never shows, so vanilla's pages do.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuOptions"
require "ZeD/ZeD_PadGlyphs"
require "OptionScreens/MainOptions"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local O  = ZeD_MMOptions

-- design units
local PAD_ROW_H, SND_ROW_H, CAT_ROW_H, CATS_W = 44, 32, 30, 200
local PICK_H, SLIDER_W, PLAY_W = 34, 220, 64
local DIAGRAM_SHARE = 0.48

local function ms() return MainScreen and MainScreen.instance end
local function mo() local m = ms(); return m and m.mainOptions end
local function s(v) if v == nil then return "" end; return tostring(v) end

-- ============================================================================
-- THE PAD: vanilla's controller page, found on MainOptions
-- ============================================================================
local function findType(el, ty, depth)
    if not el or depth > 10 then return nil end
    if el.Type == ty then return el end
    local ch = el.getChildren and el:getChildren() or nil
    if ch then
        for _, c in pairs(ch) do
            local f = findType(c, ty, depth + 1)
            if f then return f end
        end
    end
    return nil
end

-- the bindings editor (its tab holds the test panel and the preset list)
function MM.padEditor()
    local o = mo()
    local list = o and o.tabs and o.tabs.viewList or {}
    for _, v in ipairs(list) do
        local e = findType(v.view, "ISControllerBindingsEditorPanel", 0)
        if e then return e, e.gameOptionControllerTab, e.gameOptionControllerTab and e.gameOptionControllerTab.controllerTestPanel end
    end
    return nil
end

-- the pad's parts as ZeD's button pictures (ZeD_PadGlyphs roles), by vanilla's element names
local BUTTON_ROLE = { A = "A", B = "B", X = "X", Y = "Y", LeftBump = "LB", RightBump = "RB", LeftStick = "L3", RightStick = "R3",
                      Back = "SEL", Start = "START", DPadUp = "DU", DPadDown = "DD", DPadLeft = "DL", DPadRight = "DR" }
local AXIS1_ROLE = { LeftTrigger = "LT", RightTrigger = "RT", LeftStickX = "LS", LeftStickY = "LS", RightStickX = "RS", RightStickY = "RS" }
local AXIS2_ROLE = { LeftStick = "LS", RightStick = "RS" }

-- (the game's Java arrays arrive as tables: vanilla's own controller page walks them with ipairs, and so
-- does this; nothing here probes them for methods)
local function listOf(t) return t or {} end

-- every button, the triggers and the sticks (a stick's own axes only when something is bound to them)
function MM.padElements()
    local out = {}
    if not JoypadButton then return out end
    for _, b in ipairs(listOf(JoypadButton.getButtons())) do
        local n = tostring(b)
        if b ~= JoypadButton.Guide and BUTTON_ROLE[n] then out[#out + 1] = { key = b, kind = "button", name = n, role = BUTTON_ROLE[n] } end
    end
    for _, a in ipairs(listOf(JoypadAxis1d.getAxes())) do
        local n = tostring(a)
        local trig = (n == "LeftTrigger" or n == "RightTrigger")
        local bound = false
        if not trig then pcall(function() bound = #listOf(CharacterJoypadButtonBinding.findBindings(a)) > 0 end) end
        if AXIS1_ROLE[n] and (trig or bound) then out[#out + 1] = { key = a, kind = "axis1d", name = n, role = AXIS1_ROLE[n] } end
    end
    for _, a in ipairs(listOf(JoypadAxis2d.getAxes())) do
        local n = tostring(a)
        if AXIS2_ROLE[n] then out[#out + 1] = { key = a, kind = "axis2d", name = n, role = AXIS2_ROLE[n] } end
    end
    for i, e in ipairs(out) do e.id = "pad:" .. e.kind .. ":" .. e.name; e.index = i end
    return out
end

-- what an element does in game: vanilla's actions, an axis with its threshold as vanilla writes it
function MM.padBound(el)
    local t = {}
    pcall(function()
        for _, cb in ipairs(listOf(CharacterJoypadButtonBinding.findBindings(el.key))) do
            local txt = getText(cb:getNameTranslationKey())
            if el.kind ~= "button" then
                if cb:isAxisMaxThresholdInfinity() then txt = txt .. " > " .. string.format("%.2f", cb:getAxisMinThreshold())
                else txt = string.format("%.2f", cb:getAxisMinThreshold()) .. " > " .. txt .. " < " .. string.format("%.2f", cb:getAxisMaxThreshold()) end
            end
            t[#t + 1] = { b = cb, text = txt }
        end
        if el.kind == "axis2d" then
            for _, ab in ipairs(listOf(CharacterJoypadAxis2dBinding.findBindings(el.key))) do
                t[#t + 1] = { b = ab, two = true, text = getText(ab:getNameTranslationKey()) }
            end
        end
    end)
    return t
end

-- adds or takes off one action on an element, then vanilla's editor's own hand-off
function MM.padToggle(el, b, two)
    if two then
        if b:getBinding() == el.key then b:removeBinding(el.key) else b:setBinding(el.key) end
    else
        if b:containsBinding(el.key) then b:removeBinding(el.key) else b:addBinding(el.key) end
    end
    local ed = MM.padEditor()
    if ed then ed:onJoypadButtonBindingEdited() end
end

-- the controller the drawing follows: the one picked to test, else the one driving the menu (or player 1's)
function MM.padLive()
    local _, _, tp = MM.padEditor()
    if tp and tp.selectedController then return tp.selectedController, true end
    local jd = JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
    if not jd and JoypadState and JoypadState.players then jd = JoypadState.players[1] end
    if jd and jd.id and jd.id >= 0 then return jd.id, false end
    return nil, false
end

-- ============================================================================
-- SUB-PAGES ON THE OPTIONS WINDOW
-- ============================================================================
local base = {}
for _, k in ipairs({ "prerender", "render", "joyDir", "joyA", "joyB", "joyX", "joyY", "joyBumper", "getFooterPrompts", "keyEscape",
                     "keyOther", "wheel", "onShow", "finish", "getStatusLine", "close" }) do
    base[k] = O["_zedBase_" .. k] or O[k]
    O["_zedBase_" .. k] = base[k]   -- (a reload of this file wraps the originals, never its own wrappers)
end

function O:openSub(name)
    if self.sub == name then return end
    MM.ctx.open = nil
    self:setConfirm(false)
    self._palette = nil
    self._mainScroll, self._mainFocus = self.scroll, self.focusId
    self.sub = name
    self.scroll = 0
    self.focusId = nil
    self.sndCat = self.sndCat or 1
    self._sndChanged = false
    if name == "sounds" then
        if ms() and not ms().inGame then pcall(GameSounds.fix3DListenerPosition, true) end   -- (vanilla: needed back at the menu after a death)
    end
    MM.clickSound()
end

function O:closeSub()
    if not self.sub then return end
    if self.sub == "pad" and JoypadState then JoypadState.controllerTest = nil end   -- (a pad left testing would stay dead after Back)
    if self.sub == "sounds" then
        self:stopPreview()
        if self._sndChanged then pcall(GameSounds.saveINI); self._sndChanged = false end
    end
    MM.ctx.open = nil
    self.sub = nil
    self.scroll = self._mainScroll or 0
    self.focusId = self._mainFocus
    self._subList, self._catsBox = nil, nil
end

-- the controller page's editor and test: a page of this window, in place of vanilla's
function O:openVanillaController() self:openSub("pad") end

function O:onShow()
    if self.sub then self:closeSub() end   -- (left with Escape in game: the volumes are saved now)
    return base.onShow(self)
end
function O:finish()
    if self.sub then self:closeSub() end
    return base.finish(self)
end

-- ----------------------------------------------------------------------------
-- DRAWING
-- ----------------------------------------------------------------------------
function O:prerender()
    if not self.sub then return base.prerender(self) end
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = self:place()
    self.title = (self.sub == "pad") and ZeD.tr("UI_ZeD_Options_ButtonMapAndTest") or ZeD.tr("UI_ZeD_Options_GameSounds")
    self.titleStats = {}
    if self:anyChanged() then self.titleStats = { { text = ZeD.tr("UI_ZeD_Options_Changed"), color = T.accent } } end
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    if self.sub == "pad" then self:drawPadPage(pad, bodyY, w - pad * 2, bodyH)
    else self:drawSoundsPage(pad, bodyY, w - pad * 2, bodyH) end
    -- the controller starts on the list's first row (and comes back to it when its row went: a new category)
    local onSpec, first = false, nil
    for _, sp in ipairs(self._specs) do
        if sp.id == self.focusId then onSpec = true end
        if not first and sp.listRow then first = sp end
    end
    if not onSpec and first then self.focusId = first.id end
    local rights = {}
    if self.sub == "pad" then
        rights[1] = { "apply", getText("UI_btn_apply"), function() self:apply(false) end, "primary", not self:anyChanged() }
    end
    UI.stripSpecs(self, stripY, w, 1000, { { "back", getText("UI_btn_back"), function() self:closeSub(); MM.clickSound() end } }, rights)
end

-- the pad drawn in lines: a body, two grips, the shoulders above; each part where the pad set puts it
local function padLayout(x, y, w, h, set)
    local L = {}
    local bw, bh = math.floor(w * 0.86), math.floor(h * 0.50)
    local bx, by = x + math.floor((w - bw) / 2), y + math.floor(h * 0.24)
    L.body = { bx, by, bw, bh }
    local gw, gh = math.floor(bw * 0.26), math.floor(h * 0.22)
    L.gripL = { bx + math.floor(bw * 0.04), by + bh, gw, gh }
    L.gripR = { bx + bw - math.floor(bw * 0.04) - gw, by + bh, gw, gh }
    local function at(fx, fy) return { bx + math.floor(bw * fx), by + math.floor(bh * fy) } end
    -- (PlayStation pads: the D-pad above the left stick; the others: the stick above)
    local upper, lower = at(0.20, 0.32), at(0.36, 0.72)
    L.pos = {
        LB = at(0.16, -0.30), RB = at(0.84, -0.30), LT = at(0.16, -0.66), RT = at(0.84, -0.66),
        SEL = at(0.42, 0.30), START = at(0.58, 0.30),
        A = at(0.80, 0.52), B = at(0.89, 0.30), X = at(0.71, 0.30), Y = at(0.80, 0.08),
        LS = (set == "ps") and lower or upper, DPAD = (set == "ps") and upper or lower, RS = at(0.64, 0.72),
    }
    return L
end

local DPAD_ARMS = { "DU", "DD", "DL", "DR" }
local FACE = { "A", "B", "X", "Y", "LB", "RB", "SEL", "START" }

-- the pad in lines: the shell, then each part at its place, lit while held. focusEl: the list's
-- chosen element, framed in the accent on the drawing
function O:drawPadDiagram(x, y, w, h, els, focusEl)
    local T = ZeD.T
    local G = ZeD.PadGlyphs
    local set = G.set() or "xbox"
    local L = padLayout(x, y, w, h, set)
    local bs, s2, ac = T.borderS, T.surf2, T.accent
    for _, r in ipairs({ L.gripL, L.gripR, L.body }) do
        self:drawRect(r[1], r[2], r[3], r[4], s2.a or 1, s2.r, s2.g, s2.b)
        ZeD.Atoms.frame(self, r[1], r[2], r[3], r[4], bs)
    end
    local ctrl = MM.padLive()
    local ph = math.max(T.px(14), math.min(T.px(26), math.floor(h / 12)))
    local k = G.k(ph)
    local byRole = {}
    for _, el in ipairs(els) do
        if el.kind == "button" or el.kind == "axis2d" or el.role == "LT" or el.role == "RT" then byRole[el.role] = el end
    end
    local function held(el)
        if not (el and ctrl) then return false end
        local ok, v = pcall(function() return el.key:isDown(ctrl) end)
        return ok and v == true
    end
    local function isFocus(roles)
        if not focusEl then return false end
        for _, r in ipairs(roles) do if focusEl.role == r then return true end end
        return false
    end
    -- one picture centered on p; its box (lit, framed) around it
    local function spot(role, p, lit, focus)
        local gw = math.max(G.width({ role }, k, set), ph)
        local bx0, by0, bw0, bh0 = p[1] - math.floor(gw / 2) - T.px(3), p[2] - math.floor(ph / 2) - T.px(3), gw + T.px(6), ph + T.px(6)
        if lit then self:drawRect(bx0, by0, bw0, bh0, T.selectionA, ac.r, ac.g, ac.b) end
        G.draw(self, { role }, p[1] - math.floor(G.width({ role }, k, set) / 2), by0 + T.px(3), ph, k, set)
        if focus then ZeD.Atoms.frame(self, bx0 - T.px(2), by0 - T.px(2), bw0 + T.px(4), bh0 + T.px(4), ac) end
        return bx0, by0, bw0, bh0
    end
    -- the face buttons, bumpers, View / Menu
    for _, role in ipairs(FACE) do
        if byRole[role] and L.pos[role] then spot(role, L.pos[role], held(byRole[role]), isFocus({ role })) end
    end
    -- the D-pad: one cross; a held arm draws as that arm
    local arm
    for _, r in ipairs(DPAD_ARMS) do if held(byRole[r]) then arm = r end end
    spot(arm or "DPAD", L.pos.DPAD, arm ~= nil, isFocus(DPAD_ARMS))
    -- the triggers: their picture, a bar that fills as they are pulled
    for _, role in ipairs({ "LT", "RT" }) do
        local el = byRole[role]
        if el then
            local fill = 0
            if ctrl then pcall(function() fill = (1 + el.key:getValue(ctrl)) / 2 end) end
            local bx0, by0, bw0, bh0 = spot(role, L.pos[role], fill > 0.55, isFocus({ role }))
            ZeD.Atoms.drawSmoothBar(self, bx0, by0 + bh0 + T.px(2), bw0, fill, false, nil, T.px(4))
        end
    end
    -- the sticks: a well with the stick's picture, a dot where the stick points; a click lights the well
    for _, pair in ipairs({ { "LS", "L3" }, { "RS", "R3" } }) do
        local el, click = byRole[pair[1]], byRole[pair[2]]
        local p = L.pos[pair[1]]
        if el and p then
            local sx, sy = 0, 0
            if ctrl then pcall(function() sx, sy = el.key:getValueX(ctrl), el.key:getValueY(ctrl) end) end
            local ws = math.floor(ph * 2.4)
            local wx, wy = p[1] - math.floor(ws / 2), p[2] - math.floor(ws / 2)
            local b0 = T.base
            self:drawRect(wx, wy, ws, ws, 1, b0.r, b0.g, b0.b)
            if held(click) then self:drawRect(wx, wy, ws, ws, T.selectionA, ac.r, ac.g, ac.b) end
            ZeD.Atoms.frame(self, wx, wy, ws, ws, bs)
            local gw = G.width({ pair[1] }, k, set)
            G.draw(self, { pair[1] }, p[1] - math.floor(gw / 2), p[2] - math.floor(ph / 2), ph, k, set)
            local dsz = T.px(8)
            local moved = math.abs(sx) > 0.25 or math.abs(sy) > 0.25
            local dx = p[1] + math.floor(sx * (ws / 2 - dsz)) - math.floor(dsz / 2)
            local dy = p[2] + math.floor(sy * (ws / 2 - dsz)) - math.floor(dsz / 2)
            ZeD.Atoms.drawStatusDot(self, dx, dy, moved and ac or T.textDim, dsz)
            if isFocus(pair) then ZeD.Atoms.frame(self, wx - T.px(2), wy - T.px(2), ws + T.px(4), ws + T.px(4), ac) end
        end
    end
    return L
end

function O:drawPadPage(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local ed, tab, tp = MM.padEditor()
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local gp = MM.gamepad()
    -- the test: vanilla's controller pick, as a pull-down box
    local cy = y
    local la = T.accent
    local label = ZeD.textCase((getText("UI_ControllerTest_Combo"):gsub(":%s*$", "")))
    self:drawText(label, x, cy + math.floor((T.px(24) - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
    local lx = x + MM.textW(f1, label) + T.px(10)
    local combo = tp and tp.combo
    if combo then
        local cur = ""
        pcall(function() cur = s(combo:getOptionText(combo.selected)) end)
        local cw = math.min(T.px(280), math.max(T.px(160), MM.textW(f2, cur) + T.px(40)))
        local hid = self.kind .. ":padtest"
        local anchor = { x = ax + lx, y = ay + cy, w = cw, h = T.px(24) }
        local focused = gp and self.focusId == "padtest"
        MM.drawDropBox(self, lx, cy, cw, T.px(24), cur, (not gp) and self:pctx().hot == hid, false, focused)
        local open = function() self:openTestPick(combo, anchor) end
        self._hits[#self._hits + 1] = { id = hid, x = anchor.x, y = anchor.y, w = cw, h = anchor.h, fn = open, sound = true }
        self._specs[#self._specs + 1] = { id = "padtest", noDraw = true, row = 0, col = 1, x = lx, y = cy, w = cw, h = T.px(24), fn = open }
        -- testing: the pad is held for the test; vanilla's way out
        if JoypadState and JoypadState.controllerTest then
            local nx = lx + cw + T.px(14)
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, nx, cy + math.floor((T.px(24) - dsz) / 2), T.warning, dsz)
            local tc = T.text
            self:drawText(ZeD.Atoms.truncateText(UI.plain(getText("UI_ControllerTest_AY4exit")), f2, x + w - nx - dsz - T.px(8)), nx + dsz + T.px(6), cy + math.floor((T.px(24) - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            local ctrl = tp.selectedController
            local both = false
            pcall(function() both = ctrl and JoypadButton.A:isDown(ctrl) and JoypadButton.Y:isDown(ctrl) end)
            if both then JoypadState.controllerTest = false end
        end
    end
    cy = cy + T.px(PICK_H)
    local bodyH = y + h - cy
    local dw = math.floor(w * DIAGRAM_SHARE)
    local els = MM.padElements()
    -- the list: every element and its actions
    local lx0, lw = x + dw + T.px(12), w - dw - T.px(12)
    UI.insetBox(self, lx0, cy, lw, bodyH)
    local vy, vh = cy + T.px(1), bodyH - T.px(2)
    local rh = T.px(PAD_ROW_H)
    local total = #els * rh
    local sbW = T.sp.scrollbarW
    local over = total > vh
    local rw = lw - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll or 0, math.max(0, total - vh)))
    self._list = { x = lx0, y = vy, w = lw, h = vh }
    self._subList = self._list
    local focusEl
    self:setStencilRect(lx0 + T.px(1), vy, lw - T.px(2), vh)
    local ry = vy - self.scroll
    local G = ZeD.PadGlyphs
    local set = G.set() or "xbox"
    for i, el in ipairs(els) do
        local anchorY = ay + math.max(vy, math.min(ry, vy + vh - rh))
        local open = function() self:openPadActions(el, { x = ax + lx0 + T.px(40), y = anchorY, w = rw - T.px(40), h = rh }) end
        self._specs[#self._specs + 1] = { id = el.id, listRow = true, row = i, col = 1, key = el.id, ry = ry + self.scroll - vy, rh = rh, fn = open, padEl = el }
        local hid = self.kind .. ":" .. el.id
        local hot = (not gp) and self:pctx().hot == hid
        if (gp and self.focusId == el.id) or hot then focusEl = el end
        if ry + rh > vy and ry < vy + vh then
            local onFocus = MM.rowLook(self, lx0 + T.px(1), ry, rw, rh, false, hot, gp and self.focusId == el.id)
            self:drawRect(lx0 + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local gh = T.px(16)
            G.draw(self, { el.role }, lx0 + T.px(10), ry + math.floor((rh - gh) / 2), gh, G.k(gh), set)
            local tx = lx0 + T.px(44)
            local tw = lx0 + rw - T.px(8) - tx
            local nameC = onFocus and T.textOnFocus or T.textHead
            local dimC = onFocus and T.textOnFocus or T.textDim
            local nm = ""
            pcall(function() nm = getText(el.key:getNameTranslationKey()) end)
            self:drawText(ZeD.Atoms.truncateText(nm, f2, tw), tx, ry + T.px(5), nameC.r, nameC.g, nameC.b, nameC.a or 1, f2)
            local names = {}
            for _, b in ipairs(MM.padBound(el)) do names[#names + 1] = b.text end
            local acts = (#names > 0) and table.concat(names, ", ") or ZeD.tr("UI_ZeD_PadMap_Nothing")
            self:drawText(ZeD.Atoms.truncateText(acts, f3, tw), tx, ry + rh - T.px(5) - MM.fontH(f3), dimC.r, dimC.g, dimC.b, dimC.a or 1, f3)
            local c0, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = hid, x = ax + lx0, y = ay + c0, w = rw, h = ch, fn = open }
            if hot then ZeD.Help.set(self, ZeD.tr("UI_ZeD_MMHelp_PadRow")) end
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    if over then
        MM.scrollBar(self, self.kind .. ":padtrack", lx0 + lw - T.px(1) - sbW, vy, sbW, vh, self.scroll, total, function(v) self.scroll = v end, { step = rh })
    end
    -- the drawing
    UI.insetBox(self, x, cy, dw, bodyH)
    self:drawPadDiagram(x + T.px(12), cy + T.px(12), dw - T.px(24), bodyH - T.px(24), els, focusEl)
end

-- the test's controller pick (vanilla's combo; its change starts or ends the test as vanilla's does)
function O:openTestPick(combo, anchor)
    local items = {}
    for i = 1, #(combo.options or {}) do
        local t = s(combo:getOptionText(i))
        items[#items + 1] = { text = t, check = (i == combo.selected), fn = function()
            combo.selected = i
            if combo.onChange then combo.onChange(combo.target, combo) end
            MM.clickSound()
        end }
    end
    MM.openPopup("combo", items, anchor, false)
    MM.ctx.dropFocus = math.max(1, combo.selected or 1)
end

-- an element's actions as a pull-down, the bound ones ticked; a pick adds it or takes it off
function O:openPadActions(el, anchor)
    local items = {}
    local bound = {}
    for _, b in ipairs(MM.padBound(el)) do bound[b.b] = true end
    if el.kind == "axis2d" then
        for _, ab in ipairs(listOf(CharacterJoypadAxis2dBinding.allBindings())) do
            items[#items + 1] = { text = getText(ab:getNameTranslationKey()), check = bound[ab] or false, fn = function() MM.padToggle(el, ab, true); MM.clickSound() end }
        end
        items[#items + 1] = "-"
    end
    for _, cb in ipairs(listOf(CharacterJoypadButtonBinding.allBindings())) do
        items[#items + 1] = { text = getText(cb:getNameTranslationKey()), check = bound[cb] or false, fn = function() MM.padToggle(el, cb, false); MM.clickSound() end }
    end
    MM.openPopup("combo", items, anchor, false)
    MM.ctx.dropFocus = 1
end

-- ----------------------------------------------------------------------------
-- ADVANCED GAME SOUNDS
-- ----------------------------------------------------------------------------
function MM.soundCategories()
    local out = {}
    pcall(function()
        local list = GameSounds.getCategories()
        for i = 0, list:size() - 1 do
            local c = list:get(i)
            out[#out + 1] = { id = c, title = getTextOrNull("GameSound_Category_" .. c) or c }
        end
    end)
    return out
end

function MM.soundsIn(cat)
    local out = {}
    if not cat then return out end
    pcall(function()
        local list = GameSounds.getSoundsInCategory(cat)
        for i = 0, list:size() - 1 do
            local gs = list:get(i)
            local name = gs:getName()
            out[#out + 1] = { snd = gs, name = name, label = getTextOrNull("GameSound_" .. name) or name }
        end
    end)
    return out
end

-- a volume as vanilla's control holds it: 0 to 2, steps of 0.05
local function snap(v) return math.max(0, math.min(2, math.floor(v * 20 + 0.5) / 20)) end
function O:setSoundVolume(r, v)
    v = snap(v)
    local cur = r.snd:getUserVolume()
    if math.abs(cur - v) < 0.001 then return end
    r.snd:setUserVolume(v)
    self._sndChanged = true
end

function O:playSound(r)
    MM.clickSound()
    if self._preview == r.name then self:stopPreview(); return end
    self:stopPreview()
    if ms() and not ms().inGame then pcall(function() getSoundManager():StopMusic() end) end
    GameSounds.previewSound(r.name)
    self._preview = r.name
end
function O:stopPreview()
    if self._preview then pcall(GameSounds.stopPreview); self._preview = nil end
end

function O:drawSoundsPage(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gp = MM.gamepad()
    local f2 = T.fontF2
    local cats = MM.soundCategories()
    if self.sndCat > #cats then self.sndCat = 1 end
    -- the volumes are kept as they change (at most once a second): a game left with Escape keeps them too
    if self._sndChanged and MM.now() - (self._sndSavedAt or 0) > 1000 then
        pcall(GameSounds.saveINI)
        self._sndChanged, self._sndSavedAt = false, MM.now()
    end
    -- the categories down the left
    local cw = T.px(CATS_W)
    UI.insetBox(self, x, y, cw, h)
    local crh = T.px(CAT_ROW_H)
    self._catsBox = { x = x, y = y, w = cw, h = h }
    for i, c in ipairs(cats) do
        local ry = y + T.px(1) + (i - 1) * crh
        if ry + crh <= y + h then
            local hid = self.kind .. ":cat:" .. i
            local isSel = (i == self.sndCat)
            MM.rowWash(self, x + T.px(1), ry, cw - T.px(2), crh, isSel, (not gp) and self:pctx().hot == hid)
            local tc = isSel and T.textHead or T.text
            self:drawText(ZeD.Atoms.truncateText(ZeD.textCase(c.title), f2, cw - T.px(20)), x + T.px(10), ry + math.floor((crh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            self._hits[#self._hits + 1] = { id = hid, x = ax + x, y = ay + ry, w = cw, h = crh, fn = function() self:setSoundCat(i) end }
        end
    end
    -- the sounds of the chosen one
    local lx, lw = x + cw + T.px(12), w - cw - T.px(12)
    UI.insetBox(self, lx, y, lw, h)
    local rows = MM.soundsIn(cats[self.sndCat] and cats[self.sndCat].id)
    local vy, vh = y + T.px(1), h - T.px(2)
    local rh = T.px(SND_ROW_H)
    local total = #rows * rh
    local sbW = T.sp.scrollbarW
    local over = total > vh
    local rw = lw - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll or 0, math.max(0, total - vh)))
    self._list = { x = lx, y = vy, w = lw, h = vh }
    self._subList = self._list
    local sw = math.min(T.px(SLIDER_W), math.floor(rw * 0.4))
    local pw = T.px(PLAY_W)
    local valW = MM.textW(f2, "200%") + T.px(10)
    self:setStencilRect(lx + T.px(1), vy, lw - T.px(2), vh)
    local ry = vy - self.scroll
    for i, r in ipairs(rows) do
        local id = "snd:" .. r.name
        self._specs[#self._specs + 1] = { id = id, listRow = true, row = i, col = 1, key = id, ry = ry + self.scroll - vy, rh = rh, fn = function() self:playSound(r) end, sndRow = r }
        if ry + rh > vy and ry < vy + vh then
            local focused = gp and self.focusId == id
            local onFocus = MM.rowLook(self, lx + T.px(1), ry, rw, rh, false, false, focused)
            self:drawRect(lx + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local tc = onFocus and T.textOnFocus or T.text
            local px0 = lx + rw - T.px(8) - pw
            local vx0 = px0 - T.px(8) - valW
            local sx0 = vx0 - T.px(6) - sw
            local labW = sx0 - T.px(12) - (lx + T.px(10))
            local midY = ry + math.floor(rh / 2)
            self:drawText(ZeD.Atoms.truncateText(r.label, f2, labW), lx + T.px(10), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            -- the slider: the System 7 track, a flat thumb
            local vol = 1
            pcall(function() vol = r.snd:getUserVolume() end)
            local frac = vol / 2
            local trH = T.px(6)
            ZeD.Atoms.drawSmoothBar(self, sx0, midY - math.floor(trH / 2), sw, frac, false, nil, trH)
            local thW, thH = T.px(12), T.px(18)
            local thX = sx0 + math.floor(sw * frac) - math.floor(thW / 2)
            local hid = self.kind .. ":" .. id .. ":sl"
            local tbk = (self:pctx().hot == hid) and T.accentBright or T.surf4
            self:drawRect(thX, midY - math.floor(thH / 2), thW, thH, 1, tbk.r, tbk.g, tbk.b)
            ZeD.Atoms.frame(self, thX, midY - math.floor(thH / 2), thW, thH, T.borderS)
            local pct = tostring(math.floor(vol * 100 + 0.5)) .. "%"
            self:drawText(pct, vx0 + valW - MM.textW(f2, pct), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            self._hits[#self._hits + 1] = { id = hid, x = ax + sx0 - T.px(6), y = ay + midY - math.floor(thH / 2), w = sw + T.px(12), h = thH, drag = function(mx)
                self:setSoundVolume(r, 2 * math.max(0, math.min(1, (mx - ax - sx0) / math.max(1, sw))))
            end }
            -- Play / Stop
            local playing = (self._preview == r.name) and GameSounds.isPreviewPlaying()
            if self._preview == r.name and not playing then self._preview = nil end
            local b = { x = px0, y = midY - math.floor(T.buttonH / 2), w = pw, h = T.buttonH, compact = true,
                        text = playing and getText("IGUI_media_stop") or getText("IGUI_media_play"), variant = "default" }
            local bid = self.kind .. ":" .. id .. ":play"
            MM.drawBtn(self, b, (not gp) and self:pctx().hot == bid, false, false)
            self._hits[#self._hits + 1] = { id = bid, x = ax + b.x, y = ay + b.y, w = b.w, h = b.h, fn = function() self:playSound(r) end, sound = true }
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    if over then
        MM.scrollBar(self, self.kind .. ":sndtrack", lx + lw - T.px(1) - sbW, vy, sbW, vh, self.scroll, total, function(v) self.scroll = v end, { step = rh })
    end
end

function O:setSoundCat(i)
    if self.sndCat == i then return end
    self:stopPreview()
    self.sndCat = i
    self.scroll = 0
    self.focusId = nil
    MM.clickSound()
end

-- ----------------------------------------------------------------------------
-- CONTROLLER, KEYS, WHEEL
-- ----------------------------------------------------------------------------
local function subFocused(self)
    for _, b in ipairs(self._specs or {}) do if b.id == self.focusId then return b end end
    return nil
end

function O:joyDir(dir)
    if not self.sub then return base.joyDir(self, dir) end
    local b = subFocused(self)
    if b and b.sndRow and (dir == "left" or dir == "right") then
        local v = 1
        pcall(function() v = b.sndRow.snd:getUserVolume() end)
        self:setSoundVolume(b.sndRow, v + (dir == "left" and -0.05 or 0.05))
        MM.hoverSound()
        return
    end
    ZeD_MMWindow.joyDir(self, dir)
    b = subFocused(self)
    if b and b.listRow then
        local vh = self._list and self._list.h or 0
        if b.ry < self.scroll then self.scroll = b.ry
        elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
    end
end
function O:joyB()
    if not self.sub then return base.joyB(self) end
    self:closeSub()
    MM.clickSound()
end
function O:joyX() if not self.sub then return base.joyX(self) end end
function O:joyBumper(dir)
    if not self.sub then return base.joyBumper(self, dir) end
    if self.sub == "sounds" then
        local n = #MM.soundCategories()
        if n == 0 then return end
        local i = self.sndCat + dir
        if i < 1 then i = n elseif i > n then i = 1 end
        self:setSoundCat(i)
    end
end
function O:getFooterPrompts()
    if not self.sub then return base.getFooterPrompts(self) end
    if not MM.gamepad() then return nil end
    local t = {}
    local b = subFocused(self)
    if self.sub == "sounds" then
        if b and b.sndRow then
            t[#t + 1] = { glyph = "<>", label = ZeD.tr("UI_ZeD_Options_PromptChange") }
            t[#t + 1] = { glyph = "A", label = getText("IGUI_media_play") }
        end
        t[#t + 1] = { glyph = "LB", label = "" }
        t[#t + 1] = { glyph = "RB", label = ZeD.tr("UI_ZeD_Options_PromptPage") }
    else
        t[#t + 1] = { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }
        if self:anyChanged() then t[#t + 1] = { glyph = "Y", label = ZeD.btnCase(getText("UI_btn_apply")) } end
    end
    t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) }
    return t
end
function O:keyEscape()
    if not self.sub then return base.keyEscape(self) end
    self:closeSub()
    MM.clickSound()
    return true
end
function O:keyOther(key)
    if not self.sub then return base.keyOther(self, key) end
    return false
end
function O:close()
    if self.sub then self:closeSub(); MM.clickSound(); return end
    return base.close(self)
end
function O:wheel(del)
    if not self.sub then return base.wheel(self, del) end
    local l = self._subList
    if not l then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < l.x or mx > l.x + l.w or my < l.y or my > l.y + l.h then return false end
    self.scroll = (self.scroll or 0) + del * ZeD.T.px(SND_ROW_H) * 2
    return true
end

-- ----------------------------------------------------------------------------
-- vanilla's Advanced sounds button: this window's page while it shows (vanilla's screen otherwise)
-- ----------------------------------------------------------------------------
if MainOptions and not MainOptions._zedSoundsOrig then
    MainOptions._zedSoundsOrig = MainOptions.onGameSounds
    MainOptions.onGameSounds = function(self, ...)
        local Safe = ZeD.Safe
        local m = ms()
        local w = nil
        if m and m.inGame then w = MM.pauseOpts elseif MM.root then w = MM.root.optsWin end
        if w and w:isVisible() and not (Safe and Safe.on()) then w:openSub("sounds"); return end
        return MainOptions._zedSoundsOrig(self, ...)
    end
end
