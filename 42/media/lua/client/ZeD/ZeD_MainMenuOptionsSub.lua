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
--   ISControllerTestPanel). The drawn pad (ZeD_PadFigure: the Controller
--   map's pixel-art pad, the face buttons of the set the glyph setting picks)
--   with a label on a line beside every part, like a figure in a manual: the
--   button's picture, ZeD's job for it, and under that the game's own actions
--   on it. The live test: a held button fills with the accent and sits pressed
--   in, a stick's cap moves (and its label's dial), a trigger fills as far as
--   it is pulled (its label says the percent). It follows the controller
--   chosen to test (vanilla's own pick, which holds the pad for the test until
--   A and Y are held together, as vanilla), else the controller driving the
--   menu. A click or A on a label opens its actions as a pull-down with the
--   bound ones ticked (a stick and the D-pad first ask which element), and a
--   pick adds or takes that action off it. Edits run on vanilla's bindings and
--   its editor's own hand-off (onJoypadButtonBindingEdited: a fixed preset
--   becomes a new one, Apply saves). The preset, button style, dead zone and
--   the controllers in use stay rows on the Controls page.
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
require "ZeD/ZeD_PadFigure"
require "OptionScreens/MainOptions"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local O  = ZeD_MMOptions
local PF = ZeD.PadFigure

-- design units
local SND_ROW_H, CAT_ROW_H, CATS_W = 32, 30, 200
local PICK_H, SLIDER_W, PLAY_W = 34, 220, 64

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

-- what an element does in game: vanilla's actions, each { b = the binding, name = the action's name, text = the
-- name with an axis's threshold as vanilla writes it }
function MM.padBound(el)
    local t = {}
    pcall(function()
        for _, cb in ipairs(listOf(CharacterJoypadButtonBinding.findBindings(el.key))) do
            local name = getText(cb:getNameTranslationKey())
            local txt = name
            if el.kind ~= "button" then
                if cb:isAxisMaxThresholdInfinity() then txt = txt .. " > " .. string.format("%.2f", cb:getAxisMinThreshold())
                else txt = string.format("%.2f", cb:getAxisMinThreshold()) .. " > " .. txt .. " < " .. string.format("%.2f", cb:getAxisMaxThreshold()) end
            end
            t[#t + 1] = { b = cb, name = name, text = txt }
        end
        if el.kind == "axis2d" then
            for _, ab in ipairs(listOf(CharacterJoypadAxis2dBinding.findBindings(el.key))) do
                local name = getText(ab:getNameTranslationKey())
                t[#t + 1] = { b = ab, two = true, name = name, text = name }
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
    -- the controller starts on the list's first row or the first label (and comes back to it when its stop went:
    -- a new category)
    local onSpec, first = false, nil
    for _, sp in ipairs(self._specs) do
        if sp.id == self.focusId then onSpec = true end
        if not first and (sp.listRow or sp.padLab) then first = sp end
    end
    if not onSpec and first then self.focusId = first.id end
    local rights = {}
    if self.sub == "pad" then
        rights[1] = { "apply", getText("UI_btn_apply"), function() self:apply(false) end, "primary", not self:anyChanged() }
    end
    UI.stripSpecs(self, stripY, w, 1000, { { "back", getText("UI_btn_back"), function() self:closeSub(); MM.clickSound() end } }, rights)
end

-- ----------------------------------------------------------------------------
-- THE BUTTON MAP: the drawn pad (ZeD_PadFigure) with a label on a line beside
-- every part, like a figure in a manual
-- ----------------------------------------------------------------------------
-- The labels, one per part of the drawing. roles: the game's elements the label stands for (MM.padElements'
-- roles, the ones a click edits); words: ZeD's job for the part; help: the help line's words (the Controller
-- map's), names: the buttons its %1 and %2 name; dial: the stick's dial beside the words (and click: its click's
-- role); pct: the trigger's pull in percent beside them.
local PAD_PARTS = {
    { id = "LT",    roles = { "LT" },                   words = "UI_ZeD_PadFig_RoleLT",   help = "UI_ZeD_CMap_Triggers", pct = "lt" },
    { id = "LB",    roles = { "LB" },                   words = "UI_ZeD_PadFig_RoleLB",   help = "UI_ZeD_PadFig_HelpLB", names = { "LB", "RB" } },
    { id = "DPAD",  roles = { "DU", "DD", "DL", "DR" }, words = "UI_ZeD_PadFig_RoleDPad", help = "UI_ZeD_CMap_DPad" },
    { id = "LS",    roles = { "LS", "L3" },             words = "UI_ZeD_PadFig_RoleLS",   help = "UI_ZeD_CMap_LS", dial = "ls", click = "L3" },
    { id = "SEL",   roles = { "SEL" },                  words = "UI_ZeD_PadFig_RoleView", help = "UI_ZeD_CMap_View" },
    { id = "START", roles = { "START" },                words = "UI_ZeD_PadFig_RoleMenu", help = "UI_ZeD_CMap_Menu" },
    { id = "RT",    roles = { "RT" },                   words = "UI_ZeD_PadFig_RoleRT",   help = "UI_ZeD_CMap_Triggers", pct = "rt" },
    { id = "RB",    roles = { "RB" },                   words = "UI_ZeD_PadFig_RoleRB",   help = "UI_ZeD_PadFig_HelpRB", names = { "RB", "LB" } },
    { id = "Y",     roles = { "Y" },                    words = "UI_ZeD_PadFig_RoleY",    help = "UI_ZeD_CMap_Y" },
    { id = "B",     roles = { "B" },                    words = "UI_ZeD_PadFig_RoleB",    help = "UI_ZeD_CMap_B" },
    { id = "A",     roles = { "A" },                    words = "UI_ZeD_PadFig_RoleA",    help = "UI_ZeD_CMap_A" },
    { id = "RS",    roles = { "RS", "R3" },             words = "UI_ZeD_PadFig_RoleRS",   help = "UI_ZeD_CMap_RS", dial = "rs", click = "R3" },
    { id = "X",     roles = { "X" },                    words = "UI_ZeD_PadFig_RoleX",    help = "UI_ZeD_CMap_X" },
}
MM.PAD_PARTS = PAD_PARTS

-- design units: a label (its widest, padding, the gap between its pieces, its lines), its picture, the dial, the
-- percent's room
local LAB_MAX_W, LAB_PAD_X, LAB_PAD_T, LAB_PAD_B, LAB_GAP = 184, 6, 3, 4, 6
local LAB_L1_H, LAB_L2_H, LAB_PIC_U, DIAL_U, PCT_U = 18, 14, 15, 13, 30
local STICK_LIT, TRIG_LIT = 0.25, 0.02   -- a stick pushed this far lights its label; a trigger pulled this far
local ARMS = { "DU", "DD", "DL", "DR" }
local ARM_WORDS = { DU = "UI_ZeD_PadFig_ArmUp", DD = "UI_ZeD_PadFig_ArmDown", DL = "UI_ZeD_PadFig_ArmLeft", DR = "UI_ZeD_PadFig_ArmRight" }
-- (the parts whose own name on this pad differs from the game's: "Left Bump (L1)", "Back (Create)")
local SET_NAMED = { A = true, B = true, X = true, Y = true, LB = true, RB = true, LT = true, RT = true, SEL = true, START = true }
local CASE = { r = 0, g = 0, b = 0 }   -- the dark case under a leader on a dark theme

local function round(v) return math.floor(v + 0.5) end

-- the game's elements by role (a stick's own axes join its role when something is bound to them)
local function byRole(els)
    local t = {}
    for _, el in ipairs(els) do
        local l = t[el.role]
        if not l then l = {}; t[el.role] = l end
        l[#l + 1] = el
    end
    return t
end

-- a label's elements in its roles' order, a stick itself before its axes
local function partEls(part, br)
    local out = {}
    for _, r in ipairs(part.roles) do
        for _, el in ipairs(br[r] or {}) do if el.kind == "axis2d" then out[#out + 1] = el end end
        for _, el in ipairs(br[r] or {}) do if el.kind ~= "axis2d" then out[#out + 1] = el end end
    end
    return out
end

--- The element's name for the pull-downs: the game's, with this pad's own where it differs ("Left Bump (L1)"),
--- a stick's click said as one.
function MM.padElName(el, set)
    local nm = ""
    pcall(function() nm = getText(el.key:getNameTranslationKey()) end)
    if el.role == "L3" or el.role == "R3" then return ZeD.tr("UI_ZeD_PadFig_StickClick", nm) end
    if SET_NAMED[el.role] and el.kind ~= "axis2d" then
        local own = ZeD.PadGlyphs.name(el.role, set)
        if own and own ~= nm then return nm .. " (" .. own .. ")" end
    end
    return nm
end

--- The controller's state this frame for the drawing: { b = held buttons by role, ls, rs = { x, y }, lt, rt = the
--- triggers' pull 0..1 }. ctrl: the controller (MM.padLive), nil = all at rest.
function MM.padState(els, ctrl)
    local st = { b = {}, ls = { 0, 0 }, rs = { 0, 0 }, lt = 0, rt = 0 }
    if not ctrl then return st end
    for _, el in ipairs(els) do
        if el.kind == "button" then
            local ok, v = pcall(function() return el.key:isDown(ctrl) end)
            if ok and v == true then st.b[el.role] = true end
        elseif el.kind == "axis1d" and (el.role == "LT" or el.role == "RT") then
            -- (a trigger reads -1 at rest and 1 pulled all the way, as the game's own test draws it)
            local ok, v = pcall(function() return el.key:getValue(ctrl) end)
            if ok and type(v) == "number" then st[(el.role == "LT") and "lt" or "rt"] = math.max(0, math.min(1, (1 + v) / 2)) end
        elseif el.kind == "axis2d" then
            local ok, vx, vy = pcall(function() return el.key:getValueX(ctrl), el.key:getValueY(ctrl) end)
            if ok and type(vx) == "number" and type(vy) == "number" then st[(el.role == "LS") and "ls" or "rs"] = { vx, vy } end
        end
    end
    return st
end

-- whether a label's part is in use now (its words and leader in the accent)
local function partLit(part, st)
    local b = st.b
    if part.id == "DPAD" then
        for _, a in ipairs(ARMS) do if b[a] then return true end end
        return false
    end
    if part.dial then
        if b[part.click] then return true end
        local v = st[part.dial]
        return v[1] * v[1] + v[2] * v[2] > STICK_LIT * STICK_LIT
    end
    if part.pct then return (st[part.pct] or 0) > TRIG_LIT end
    return b[part.id] == true
end

local function boundNames(el, into)
    for _, b in ipairs(MM.padBound(el)) do into[#into + 1] = b.name end
    return into
end

-- the line(s) under a label's words: the game's actions on its part (the triggers' pull points stay in the pull-down)
local function gameLines(part, br)
    if part.id == "DPAD" then
        local arms = {}
        for _, a in ipairs(ARMS) do
            local names = {}
            for _, el in ipairs(br[a] or {}) do boundNames(el, names) end
            if #names > 0 then arms[#arms + 1] = ZeD.tr(ARM_WORDS[a], table.concat(names, ", ")) end
        end
        if #arms == 0 then return { ZeD.tr("UI_ZeD_PadFig_GameNothing") } end
        return { ZeD.tr("UI_ZeD_PadFig_Game", table.concat(arms, " | ")) }
    end
    local names = {}
    for _, el in ipairs(br[part.id] or {}) do boundNames(el, names) end
    local first = (#names > 0) and ZeD.tr("UI_ZeD_PadFig_Game", table.concat(names, ", ")) or ZeD.tr("UI_ZeD_PadFig_GameNothing")
    if not part.click then return { first } end
    local clicks = {}
    for _, el in ipairs(br[part.click] or {}) do boundNames(el, clicks) end
    return { first, (#clicks > 0) and ZeD.tr("UI_ZeD_PadFig_Click", table.concat(clicks, ", ")) or ZeD.tr("UI_ZeD_PadFig_ClickNothing") }
end

-- one label's pieces and size: the part's picture, ZeD's words, the readout; under them the game's actions,
-- wrapped to the label's widest. ra: read from the right (the left column, View, the right stick), so the
-- picture sits nearest the pad
local function measureLabel(part, br, set, st, side)
    local T = ZeD.T
    local G = ZeD.PadGlyphs
    local f2, f3 = T.fontF2, T.fontF3
    local lab = { part = part, pic = { part.id } }
    if part.id == "DPAD" then
        for _, a in ipairs(ARMS) do if st.b[a] then lab.pic = { a } end end   -- (the arm held shows on its picture)
    end
    lab.gh = T.px(LAB_PIC_U)
    lab.gk = G.k(lab.gh)
    lab.gw = G.width(lab.pic, lab.gk, set)
    lab.words = ZeD.tr(part.words)
    lab.ro = 0
    if part.dial then lab.ro = T.px(DIAL_U) elseif part.pct then lab.ro = math.max(T.px(PCT_U), MM.textW(f3, "100%")) end
    local gap = T.px(LAB_GAP)
    local room = T.px(LAB_MAX_W) - 2 * T.px(LAB_PAD_X)
    local fixed = lab.gw + gap + ((lab.ro > 0) and (gap + lab.ro) or 0)
    -- (words too long for the label's widest wrap to a second line, a longer translation keeps all its words)
    local wordsRoom = math.max(T.px(24), room - fixed)
    lab.wl = ZeD.Atoms.wrapText(lab.words, f2, wordsRoom)
    if #lab.wl == 0 then lab.wl = { "" } end
    if #lab.wl > 2 then
        local rest = {}
        for i = 2, #lab.wl do rest[#rest + 1] = lab.wl[i] end
        lab.wl = { lab.wl[1], ZeD.Atoms.truncateText(table.concat(rest, " "), f2, wordsRoom) }
    end
    lab.ww = 0
    for _, l in ipairs(lab.wl) do lab.ww = math.max(lab.ww, MM.textW(f2, l)) end
    lab.lines = {}
    for _, l in ipairs(gameLines(part, br)) do
        for _, wl in ipairs(ZeD.Atoms.wrapText(l, f3, room)) do lab.lines[#lab.lines + 1] = wl end
    end
    local l2w = 0
    for _, l in ipairs(lab.lines) do l2w = math.max(l2w, MM.textW(f3, l)) end
    lab.w = math.min(T.px(LAB_MAX_W), 2 * T.px(LAB_PAD_X) + math.max(fixed + lab.ww, l2w))
    lab.l1 = math.max(T.px(LAB_L1_H), lab.gh, MM.fontH(f2))
    lab.l2 = math.max(T.px(LAB_L2_H), MM.fontH(f3))
    lab.wrap = (#lab.wl - 1) * MM.fontH(f2)   -- (the words' second line, under the first)
    lab.h = T.px(LAB_PAD_T) + lab.l1 + lab.wrap + T.px(1) + #lab.lines * lab.l2 + T.px(LAB_PAD_B)
    lab.mid = T.px(LAB_PAD_T) + math.floor(lab.l1 / 2)
    lab.ra = (side == "L") or part.id == "SEL" or part.id == "RS"
    return lab
end

-- the dial beside a stick's words (where it points; the dot lit once it is pushed) or a trigger's pull in percent
local function drawReadout(self, lab, st, x, midY, onFocus)
    local T = ZeD.T
    local part = lab.part
    if part.dial then
        local v = st[part.dial]
        local s = T.px(DIAL_U)
        local y = midY - math.floor(s / 2)
        local s1, bd, hair = T.surf1, T.border, T.hair
        self:drawRect(x, y, s, s, 1, s1.r, s1.g, s1.b)
        ZeD.Atoms.frame(self, x, y, s, s, T.borderS)
        local mid = math.floor(s / 2)
        self:drawRect(x + mid, y + hair, hair, s - 2 * hair, bd.a or 1, bd.r, bd.g, bd.b)
        self:drawRect(x + hair, y + mid, s - 2 * hair, hair, bd.a or 1, bd.r, bd.g, bd.b)
        local vx, vy = v[1], v[2]
        local len = math.sqrt(vx * vx + vy * vy)
        if len > 1 then vx, vy = vx / len, vy / len end
        local dc = (len > STICK_LIT) and T.accent or T.textDim
        local ds, reach = T.px(3), T.px(4)
        self:drawRect(x + mid - math.floor(ds / 2) + round(vx * reach), y + mid - math.floor(ds / 2) + round(vy * reach), ds, ds, 1, dc.r, dc.g, dc.b)
        return
    end
    local p = st[part.pct] or 0
    local txt = tostring(round(p * 100)) .. "%"
    local f3 = T.fontF3
    local c = onFocus and T.textOnFocus or ((p > TRIG_LIT) and (T.accentText or T.accent) or T.textDim)
    local tx = lab.ra and (x + lab.ro - MM.textW(f3, txt)) or x   -- (read from the right: the number's right edge kept)
    self:drawText(txt, tx, midY - math.floor(MM.fontH(f3) / 2), c.r, c.g, c.b, c.a or 1, f3)
end

-- a label at (lx, ly): the wash or the controller's mark, line 1 (picture, words, readout), the game's line(s)
local function drawLabel(self, lab, lx, ly, set, st)
    local T = ZeD.T
    local f2, f3 = T.fontF2, T.fontF3
    local onFocus = MM.rowLook(self, lx, ly, lab.w, lab.h, false, lab.hot, lab.focus)
    local tc = onFocus and T.textOnFocus or (lab.lit and (T.accentText or T.accent) or T.text)
    local dc = onFocus and T.textOnFocus or T.textDim
    local padX, gap = T.px(LAB_PAD_X), T.px(LAB_GAP)
    local top = ly + T.px(LAB_PAD_T)
    local midY = top + math.floor(lab.l1 / 2)
    local fh2 = MM.fontH(f2)
    local wy = midY - math.floor(fh2 / 2)
    -- the picture at the side nearest the pad, the words beside it (each of their lines against it), the readout
    -- beyond the words' widest line
    local gx = lab.ra and (lx + lab.w - padX - lab.gw) or (lx + padX)
    ZeD.PadGlyphs.draw(self, lab.pic, gx, top, lab.l1, lab.gk, set)
    for i, l in ipairs(lab.wl) do
        local wx = lab.ra and (gx - gap - MM.textW(f2, l)) or (gx + lab.gw + gap)
        self:drawText(l, wx, wy + (i - 1) * fh2, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    if lab.ro > 0 then
        drawReadout(self, lab, st, lab.ra and (gx - gap - lab.ww - gap - lab.ro) or (gx + lab.gw + gap + lab.ww + gap), midY, onFocus)
    end
    local y2 = top + lab.l1 + lab.wrap + T.px(1)
    for _, l in ipairs(lab.lines) do
        local tx = lab.ra and (lx + lab.w - padX - MM.textW(f3, l)) or (lx + padX)
        self:drawText(l, tx, y2 + math.floor((lab.l2 - MM.fontH(f3)) / 2), dc.r, dc.g, dc.b, dc.a or 1, f3)
        y2 = y2 + lab.l2
    end
end

-- A straight line t px thick from (x0, y0) to (x1, y1): one rect when it runs straight across or down, else one
-- rect per t px along its shorter way (ZeD draws its lines as rects)
local function seg(p, x0, y0, x1, y1, t, c, a)
    local half = math.floor(t / 2)
    local dx, dy = x1 - x0, y1 - y0
    if math.abs(dy) < 1 then
        p:drawRect(math.floor(math.min(x0, x1)) - half, math.floor(y0) - half, math.floor(math.abs(dx)) + t, t, a, c.r, c.g, c.b)
        return
    end
    if math.abs(dx) < 1 then
        p:drawRect(math.floor(x0) - half, math.floor(math.min(y0, y1)) - half, t, math.floor(math.abs(dy)) + t, a, c.r, c.g, c.b)
        return
    end
    local steep = math.abs(dy) > math.abs(dx)
    local n = math.max(1, math.ceil((steep and math.abs(dx) or math.abs(dy)) / t))
    for i = 0, n - 1 do
        local ax, ay = x0 + dx * i / n, y0 + dy * i / n
        local bx, by = x0 + dx * (i + 1) / n, y0 + dy * (i + 1) / n
        if steep then
            p:drawRect(math.floor((ax + bx) / 2) - half, math.floor(math.min(ay, by)) - half, t, math.floor(math.abs(by - ay)) + t, a, c.r, c.g, c.b)
        else
            p:drawRect(math.floor(math.min(ax, bx)) - half, math.floor((ay + by) / 2) - half, math.floor(math.abs(bx - ax)) + t, t, a, c.r, c.g, c.b)
        end
    end
end
MM.padSeg = seg

-- a label's leader, (ox, oy) the figure's corner: on a dark theme a dark case under it; the line 1u; a 3u dot on
-- the part in a 5u case. In the accent while the part is in use, the text color while the label has the pointer
-- or the controller, else the dim text color.
local function drawLeader(self, ox, oy, pts, lab)
    local T = ZeD.T
    local t = T.hair
    local c = lab.lit and T.accent or ((lab.hot or lab.focus) and T.text or T.textDim)
    local dark = ZeD.currentBase ~= "light"
    local n = math.floor(#pts / 2)
    if dark then
        for i = 1, n - 1 do seg(self, ox + pts[2 * i - 1], oy + pts[2 * i], ox + pts[2 * i + 1], oy + pts[2 * i + 2], t * 3, CASE, 0.6) end
    end
    for i = 1, n - 1 do seg(self, ox + pts[2 * i - 1], oy + pts[2 * i], ox + pts[2 * i + 1], oy + pts[2 * i + 2], t, c, c.a or 1) end
    local px, py = ox + pts[1], oy + pts[2]
    local cs, ds = T.px(5), T.px(3)
    local cc = dark and CASE or T.base
    self:drawRect(math.floor(px - cs / 2), math.floor(py - cs / 2), cs, cs, dark and 0.6 or 1, cc.r, cc.g, cc.b)
    self:drawRect(math.floor(px - ds / 2), math.floor(py - ds / 2), ds, ds, c.a or 1, c.r, c.g, c.b)
end

-- the help line for a label: the part's job (the buttons it names in this pad's own names), then how to edit it
local function partHelp(part, set, gp)
    local G = ZeD.PadGlyphs
    local help = part.names and ZeD.tr(part.help, G.name(part.names[1], set), G.name(part.names[2], set)) or ZeD.tr(part.help)
    local edit = gp and ZeD.tr("UI_ZeD_PadFig_EditPad", G.name("A", set)) or ZeD.tr("UI_ZeD_PadFig_EditClick")
    return help .. " " .. edit
end

--- The figure in the box (x, y, w, h): the pad at the largest whole multiple that leaves the labels their room
--- (ZeD_PadFigure.layout), the leaders, the labels; a stop for the controller and a click on each label.
--- self._padFig keeps what was drawn (the sims and QA read it).
function O:drawPadFigure(x, y, w, h)
    local T = ZeD.T
    local set = ZeD.PadGlyphs.set() or "xbox"
    local els = MM.padElements()
    local br = byRole(els)
    local st = MM.padState(els, MM.padLive())
    local A = PF.anchors(set)
    local labs = {}
    for _, part in ipairs(PAD_PARTS) do labs[part.id] = measureLabel(part, br, set, st, A[part.id].side) end
    local L = PF.layout(w, h, labs, set, T.px)
    local gp = MM.gamepad()
    local hot = (not gp) and self:pctx().hot or nil
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    PF.draw(self, x + L.x, y + L.y, L.k, set, st)
    local fig = { k = L.k, set = set, st = st, x = x + L.x, y = y + L.y, w = L.w, h = L.h, lit = {}, labs = {},
                  box = { x = x, y = y, w = w, h = h } }
    for _, part in ipairs(PAD_PARTS) do
        local lab = labs[part.id]
        lab.lit = partLit(part, st)
        lab.hot = hot == self.kind .. ":lab:" .. part.id
        lab.focus = gp and self.focusId == "lab:" .. part.id
        drawLeader(self, x, y, L.leads[part.id], lab)
    end
    for i, part in ipairs(PAD_PARTS) do
        local lab, pl = labs[part.id], L.place[part.id]
        local lx, ly = x + pl.x, y + pl.y
        drawLabel(self, lab, lx, ly, set, st)
        local anchor = { x = ax + lx, y = ay + ly, w = lab.w, h = lab.h }
        local open = function() self:openPadPart(part, anchor) end
        self._specs[#self._specs + 1] = { id = "lab:" .. part.id, padLab = true, row = i, col = 1, x = lx, y = ly, w = lab.w, h = lab.h, fn = open }
        self._hits[#self._hits + 1] = { id = self.kind .. ":lab:" .. part.id, x = ax + lx, y = ay + ly, w = lab.w, h = lab.h, fn = open, sound = true }
        if lab.hot or lab.focus then ZeD.Help.set(self, partHelp(part, set, gp)) end
        fig.lit[part.id] = lab.lit
        fig.labs[part.id] = { x = lx, y = ly, w = lab.w, h = lab.h, lead = L.leads[part.id], lines = lab.lines, words = lab.words }
    end
    if MM.ctx.open and MM.popup and MM.popup.padMenu then ZeD.Help.set(self, ZeD.tr("UI_ZeD_PadFig_HelpMenu")) end
    self._padFig = fig
end

function O:drawPadPage(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local _, _, tp = MM.padEditor()
    local f1, f2 = T.fontF1, T.fontF2
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
        local hot = (not gp) and self:pctx().hot == hid
        MM.drawDropBox(self, lx, cy, cw, T.px(24), cur, hot, false, focused)
        local open = function() self:openTestPick(combo, anchor) end
        self._hits[#self._hits + 1] = { id = hid, x = anchor.x, y = anchor.y, w = cw, h = anchor.h, fn = open, sound = true }
        self._specs[#self._specs + 1] = { id = "padtest", noDraw = true, row = 0, col = 1, x = lx, y = cy, w = cw, h = T.px(24), fn = open }
        if hot or focused then ZeD.Help.set(self, ZeD.tr("UI_ZeD_PadFig_HelpTest")) end
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
    local fh = y + h - cy
    self._list, self._subList = nil, nil
    UI.insetBox(self, x, cy, w, fh)
    self:drawPadFigure(x, cy, w, fh)
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

--- A label's pull-down: the actions of its one element, or first which element (a stick and its click, the
--- D-pad's arms). anchor: the label in screen px.
function O:openPadPart(part, anchor)
    local els = partEls(part, byRole(MM.padElements()))
    if #els == 0 then return end
    if #els == 1 then self:openPadActions(els[1], anchor) else self:openPadWhich(part, els, anchor) end
end

-- which element: each with its picture and what it does in game now; a pick opens its actions, and B there
-- comes back here
function O:openPadWhich(part, els, anchor)
    local set = ZeD.PadGlyphs.set() or "xbox"
    local items = {}
    for _, el in ipairs(els) do
        local names = boundNames(el, {})
        items[#items + 1] = { text = MM.padElName(el, set), pad = { el.role },
            right = (#names > 0) and table.concat(names, ", ") or ZeD.tr("UI_ZeD_PadMap_Nothing"),
            fn = function() self:openPadActions(el, anchor, function() self:openPadWhich(part, els, anchor) end) end }
    end
    MM.openPopup("combo", items, anchor, false)
    MM.popup.padMenu = true
    MM.ctx.dropFocus = 1
end

-- an element's actions as a pull-down under its name, the bound ones ticked (a trigger's with its pull point, as
-- the game writes it); a pick adds it or takes it off. back: what B opens instead of only closing
function O:openPadActions(el, anchor, back)
    local items = { { text = MM.padElName(el, ZeD.PadGlyphs.set() or "xbox"), header = true, disabled = true } }
    local bound = {}
    for _, b in ipairs(MM.padBound(el)) do bound[b.b] = b end
    if el.kind == "axis2d" then
        for _, ab in ipairs(listOf(CharacterJoypadAxis2dBinding.allBindings())) do
            items[#items + 1] = { text = getText(ab:getNameTranslationKey()), check = bound[ab] ~= nil, fn = function() MM.padToggle(el, ab, true); MM.clickSound() end }
        end
        items[#items + 1] = "-"
    end
    for _, cb in ipairs(listOf(CharacterJoypadButtonBinding.allBindings())) do
        local bb = bound[cb]
        items[#items + 1] = { text = bb and bb.text or getText(cb:getNameTranslationKey()), check = bb ~= nil, fn = function() MM.padToggle(el, cb, false); MM.clickSound() end }
    end
    MM.openPopup("combo", items, anchor, false)
    MM.popup.padMenu = true
    MM.popup.back = back
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
        -- (while a test runs the pad is the test's until A and Y are held together, as the game's own)
        if JoypadState and JoypadState.controllerTest then
            return { { pad = { "A", "Y" }, glyph = "A Y", label = ZeD.tr("UI_ZeD_PadFig_PromptExitTest") } }
        end
        local menu = MM.ctx.open ~= nil
        t[#t + 1] = { pad = { menu and "DUD" or "DPAD" }, glyph = "D-PAD", label = ZeD.tr("UI_ZeD_Wheel_PromptMove") }
        t[#t + 1] = { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }
        if not menu and self:anyChanged() then t[#t + 1] = { glyph = "Y", label = ZeD.btnCase(getText("UI_btn_apply")) } end
    end
    t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) }
    return t
end
-- the help line with nothing under the pointer: on the button map, how the live test works
function O:getStatusLine()
    if self.sub == "pad" then return ZeD.tr("UI_ZeD_PadFig_HelpIdle") end
    return base.getStatusLine(self)
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
