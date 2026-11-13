-- ZeDUI/tools/qa/pad_figure_sim.lua  (Nov 12 2026, Build): the drawn controller (punch list 108) with no game running.
-- The real ZeD_PadFigure.lua, ZeD_PadGlyphs.lua, ZeD_MainMenu.lua (its pull-down and the controller's B), the Options
-- window with ZeD_MainMenuOptionsSub.lua's Button map and test page, and ZeD_ControllerMap.lua run on Lua 5.1 against
-- stubs of the game's UI classes, its controller enums and bindings, and a texture store that records every
-- DrawSubTextureRGBA. It checks:
--   * the whole multiple per screen: the in-game Options at 4K and 1.75 (5) and on the Deck, 1280 x 800 at 0.75 (2);
--     the Controller map at 4K (4) and on the Deck (1)
--   * the labels: inside the figure's box, none over another or over the pad, every leader from its part to its
--     label, no two leaders crossing and none through another label, in English and in German (long words)
--   * the live test, draw call by draw call: at rest one draw of the resting pad; a held face button its under patch
--     then its shade, light and ink boxes one art pixel down and right, tinted; a trigger's bottom rows by its pull;
--     a pushed stick's cap moved, a clicked one lit; a D-pad arm in place; the labels and leaders lit
--   * the glyph set: the texture and the layout per set (Xbox and Nintendo stick up top, PlayStation and Deck the
--     D-pad), the glyph pictures off drawing the Xbox pad
--   * the pull-downs: a label's click or A opens its actions under the element's name; the sticks and the D-pad ask
--     which element first; B in the actions goes back to that question, B there closes; a pick edits the binding
-- What it can't show: the pixels themselves (pixel_pad_v2.py --check rebuilds lit states from the shipped files the
-- same way and compares them with the drawing), real fonts, the controller's hardware (QA: zedqa_pad_figure.lua).
-- Run from the repo root:  lua51 ZeDUI/tools/qa/pad_figure_sim.lua
-- It prints FAIL lines and a last line "pad_figure_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]pad_figure_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- ============================================================================
-- THE GAME'S GLOBALS
-- ============================================================================
function getTimestampMs() return 1000000 end
function getTimestamp() return 1000 end
function isClient() return false end
function isServer() return false end
function isMouseButtonDown() return false end
MOUSE = { x = -1, y = -1 }
function getMouseX() return MOUSE.x end
function getMouseY() return MOUSE.y end
function getDebug() return false end
function isIngameState() return true end
function getSoundManager() return { playUISound = function() end, stopUISound = function() end, StopMusic = function() end } end
function updateJoypadFocus() end
function setJoypadFocus() end
function instanceof() return false end
function triggerEvent() end
local CORE = { screenW = 3840, screenH = 2160, style = "XBOX" }
function getCore()
    return {
        getScreenWidth = function() return CORE.screenW end, getScreenHeight = function() return CORE.screenH end,
        getOptionFontSizeReal = function() return 1 end, getOptionControllerButtonStyleString = function() return CORE.style end,
    }
end
UIManager = { setShowPausedMessage = function() end, isModalVisible = function() return false end, getMillisSinceLastRender = function() return 16 end }
Keyboard = { KEY_ESCAPE = 1, KEY_RETURN = 28, KEY_UP = 200, KEY_DOWN = 208 }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
PAD = nil
JoypadState = { players = {}, getMainMenuJoypad = function() return PAD end }
UIFont = setmetatable({}, { __index = function(_, k) return k end })
LuaEventManager = { AddEvent = function() end }
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function() end, Remove = function() end }
    rawset(t, k, e)
    return e
end })

-- the words: ZeD's file and the game's own controller words
local TEXT = {}
local function readJson(path, into)
    local f = io.open(path, "rb")
    if not f then return false end
    local s = f:read("*a")
    f:close()
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\r?\n') do into[k] = v end
    return true
end
local function loadWords(lang)
    TEXT = {}
    readJson(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", TEXT)
    if lang ~= "EN" then readJson(ROOT .. "42/media/lua/shared/Translate/" .. lang .. "/UI.json", TEXT) end
    TEXT.UI_btn_apply, TEXT.UI_btn_back, TEXT.UI_Cancel = "Apply", "Back", "Cancel"
    TEXT.UI_ControllerTest_Combo, TEXT.UI_ControllerTest_AY4exit = "Test Controller:", "Press A and Y buttons for exit"
    TEXT.UI_Bind_Interact, TEXT.UI_Bind_Aim, TEXT.UI_Bind_Run, TEXT.UI_Bind_Movement, TEXT.UI_Bind_Crouch = "Interact", "Aim", "Run", "Movement", "Crouch"
    local names = { A = "A", B = "B", X = "X", Y = "Y", LeftStick = "Left Hat", RightStick = "Right Hat", LeftBump = "Left Bump", RightBump = "Right Bump",
                    Back = "Back", Start = "Start", Guide = "Guide", DPadLeft = "DPad Left", DPadRight = "DPad Right", DPadUp = "DPad Up", DPadDown = "DPad Down",
                    LeftTrigger = "Left Trigger", RightTrigger = "Right Trigger", LeftStickX = "Left Stick X", LeftStickY = "Left Stick Y",
                    RightStickX = "Right Stick X", RightStickY = "Right Stick Y" }
    for k, v in pairs(names) do TEXT["UI_Joypad_" .. k] = v end
    TEXT.UI_Joypad2_LeftStick, TEXT.UI_Joypad2_RightStick = "Left Stick", "Right Stick"
    if ZeD then ZeD._trGen = (ZeD._trGen or 0) + 1 end
end
loadWords("EN")
function getText(k, ...)
    local s = TEXT[k] or k
    local a = { ... }
    for i = 1, 4 do if a[i] ~= nil then s = string.gsub(s, "%%" .. i, (string.gsub(tostring(a[i]), "%%", "%%%%"))) end end
    return s
end
function getTextOrNull(k, ...) if TEXT[k] then return getText(k, ...) end; return nil end
function getTextManager()
    return { getFontHeight = function() return 14 end, MeasureStringX = function(_, _, s) return #tostring(s or "") * 7 end,
             getFontFromEnum = function() return { getLineHeight = function() return 14 end } end }
end
string.trim = string.trim or function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- the texture store: every draw the drawing makes, through the element's Java side
JDRAW = {}
Texture = { getSharedTexture = function(path, flags) return { path = path, flags = flags } end }
local function newJava(owner)
    return {
        setMaxLines = function() end, setMaxTextLength = function() end, setCentreVertically = function() end,
        DrawSubTextureRGBA = function(_, tex, sx, sy, sw, sh, x, y, w, h, r, g, b, a)
            JDRAW[#JDRAW + 1] = { p = owner, tex = tex, sx = sx, sy = sy, sw = sw, sh = sh, x = x, y = y, w = w, h = h, r = r, g = g, b = b, a = a }
        end,
        DrawTextureScaledColor = function(_, tex, x, y, w, h)
            JDRAW[#JDRAW + 1] = { p = owner, tex = tex, x = x, y = y, w = w, h = h, scaled = true }
        end,
    }
end

-- ============================================================================
-- THE GAME'S UI CLASSES (enough for ZeD's windows)
-- ============================================================================
DRAWN = {}
local function newClass(name, parent)
    local c = {}
    c.__index = c
    c.Type = name
    if parent then setmetatable(c, parent) end
    return c
end
ISBaseObject = newClass("ISBaseObject")
function ISBaseObject:derive(name) return newClass(name, self) end
ISUIElement = ISBaseObject:derive("ISUIElement")
function ISUIElement:new(x, y, w, h)
    local o = { x = x or 0, y = y or 0, width = w or 0, height = h or 0, visible = true, children = {}, anchorLeft = true, anchorTop = true }
    setmetatable(o, self)
    self.__index = self
    return o
end
local E = ISUIElement
function E:initialise() end
function E:instantiate()
    if self._inst then return end
    self._inst = true
    self.javaObject = newJava(self)
    if self.createChildren then self:createChildren() end
end
function E:addChild(c) c.parent = self; self.children[#self.children + 1] = c; if not c._inst then c:instantiate() end; return c end
function E:removeChild() end
function E:getChildren() return self.children end
function E:addToUIManager() self:instantiate() end
function E:removeFromUIManager() end
function E:setVisible(v) self.visible = v and true or false end
function E:isVisible() return self.visible end
function E:getIsVisible() return self.visible end
function E:isReallyVisible() return self.visible end
function E:getX() return self.x end
function E:getY() return self.y end
function E:setX(v) self.x = v end
function E:setY(v) self.y = v end
function E:getWidth() return self.width end
function E:getHeight() return self.height end
function E:setWidth(v) self.width = v end
function E:setHeight(v) self.height = v end
function E:getAbsoluteX() return self.x + (self.parent and self.parent:getAbsoluteX() or 0) end
function E:getAbsoluteY() return self.y + (self.parent and self.parent:getAbsoluteY() or 0) end
function E:getMouseX() return MOUSE.x - self:getAbsoluteX() end
function E:getMouseY() return MOUSE.y - self:getAbsoluteY() end
function E:isMouseOver() return false end
for _, n in ipairs({ "setAnchorLeft", "setAnchorRight", "setAnchorTop", "setAnchorBottom", "setAlwaysOnTop", "bringToTop", "setFont",
                     "drawRectBorder", "drawTexture", "drawTextureScaledAspect", "drawTextCentre", "setStencilRect", "clearStencilRect",
                     "setWantKeyEvents", "setCapture", "unfocus" }) do
    E[n] = E[n] or function() end
end
function E:prerender() end
function E:render() end
function E:update() end
function E:createChildren() end
function E:drawRect(x, y, w, h, a, r, g, b) DRAWN[#DRAWN + 1] = { p = self, kind = "rect", x = x, y = y, w = w, h = h, a = a, r = r, g = g, b = b } end
function E:drawText(text, x, y, r, g, b, a, font) DRAWN[#DRAWN + 1] = { p = self, kind = "text", text = tostring(text), x = x, y = y, r = r, g = g, b = b, font = font } end
function E:drawTextureScaled(tex, x, y, w, h) JDRAW[#JDRAW + 1] = { p = self, tex = tex, x = x, y = y, w = w, h = h, scaled = true } end
function E:derive(name) return newClass(name, self) end
ISPanel = E:derive("ISPanel")
ISPanelJoypad = ISPanel:derive("ISPanelJoypad")
ISTextEntryBox = ISPanel:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, w, h) local o = ISPanel.new(self, x, y, w, h); o.text = text or ""; return o end
function ISTextEntryBox:setText(s) self.text = s end
function ISTextEntryBox:getText() return self.text end
function ISTextEntryBox:getInternalText() return self.text end
function ISTextEntryBox:focus() self.hasFocus = true end
function ISTextEntryBox:isFocused() return self.hasFocus == true end
ISComboBox = ISPanel:derive("ISComboBox")
function ISComboBox:new(x, y, w, h, target, onChange) local o = ISPanel.new(self, x, y, w, h); o.options = {}; o.selected = 0; o.target = target; o.onChange = onChange; return o end
function ISComboBox:addOptionWithData(t, d) self.options[#self.options + 1] = { text = t, data = d }; if self.selected == 0 then self.selected = 1 end end
function ISComboBox:getOptionText(i) local o = self.options[i]; return o and o.text end
function ISComboBox:getOptionData(i) local o = self.options[i]; return o and o.data end
MainOptions = { loadKeys = function() end, onGameSounds = function() end }
MainScreen = { onMenuItemMouseDownMainMenu = function() end }

-- ============================================================================
-- ZeD'S FILES
-- ============================================================================
local STUBBED = { ["ZeD/Organisms"] = true, ["ZeD/MenuNote"] = true, ["ZeD/ZeD_MouseTick"] = true, ["ZeD/SafeMode"] = true }
local LOADED = {}
function require(name)
    if LOADED[name] then return end
    LOADED[name] = true
    if STUBBED[name] or not string.find(name, "^ZeD/") then return end
    local short = string.sub(name, 5)
    local path = ROOT .. "42/media/lua/client/ZeD/" .. short .. ".lua"
    local f = io.open(path, "rb")
    if f then f:close() else path = ROOT .. "42/media/lua/shared/ZeD/" .. short .. ".lua" end
    local fn, err = loadfile(path)
    if not fn then error(err) end
    fn()
end

ZeD = {}
ZeD.logOnce = function(k, e) print("FAIL logged: " .. tostring(k) .. ": " .. tostring(e)); failed = failed + 1 end
local function fontPx(font)
    local T = ZeD.T
    if font == T.fontF1 then return 11 end
    if font == T.fontF2 then return 13 end
    if font == T.fontF3 then return 11 end
    if font == T.fontF4 then return 15 end
    return 11
end
-- (a wide stand-in face: 0.6 em a letter, wider than Fira's; a byte a letter, so accented words measure wider still)
ZeD.TM = {
    MeasureStringX = function(_, font, s) return math.ceil(#tostring(s) * fontPx(font) * ZeD.T.root * 0.60) end,
    MeasureStringY = function(_, font) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
    getFontHeight = function(_, font) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
}
ZeD.Scale = { root = function() return ZEDQA_ROOT or 1 end }
ZeD.Help = { set = function(_, s) ZeD.Help.last = s end }
ZeD.Safe = { on = function() return false end, register = function() end }
ZeD.Surface = { fill = function(p, x, y, w, h) p:drawRect(x, y, w, h, 1, 0, 0, 0) end }
ZeD.Focus = { mark = function() return false end, drawOverlay = function() end }
ZeD.MouseTick = { down = function() return false end }
ZeD.Font = { sdf = { head = { face = 64 } } }
ZeD.Text = { draw = function(p, face, s, x, y) p:drawText(s, x, y) end, width = function(face, s, z) return #tostring(s) * 32 * z end,
             height = function(face, z) return 64 * z end, fitEntry = function() end, entryFont = function() return "Small" end }
ZeD.btnCase = function(s) return s end
GLYPH = "auto"
ZeD.Settings = { glyphKey = function() return GLYPH end }

-- ZeD's window frame (Organisms.lua) as a stand-in: the frame draws nothing here
ZeD_Window = ISPanel:derive("ZeD_Window")
function ZeD_Window:new(x, y, w, h, title) local o = ISPanel.new(self, x, y, w, h); o.title = title; return o end
function ZeD_Window:createChildren() end
function ZeD_Window:prerender() end
function ZeD_Window:render() end
function ZeD_Window:update() end
function ZeD_Window:footerHeight() return ZeD.T.px(22) end
function ZeD_Window:titleBarHeight() return ZeD.T.px(22) end
function ZeD_Window:closeRect() return nil end

require "ZeD/Tokens"
do
    local char = string.char
    string.char = function(...)
        local a = { ... }
        for i, v in ipairs(a) do if v > 255 then a[i] = 63 end end
        return char(unpack(a))
    end
end
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
ZeD.btnCase = ZeD.btnCase or function(s) return s end
local function theme(root, base)
    ZEDQA_ROOT = root
    ZeD.applyTheme(base or "dark", "teal", "small")
end
theme(1)
ZeD.Atoms.drawPxIcon = function(p, id, x, y, box) p:drawRect(x, y, box, box, 1, 1, 1, 1) end
require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuOptions"
for _, n in ipairs({ "ZeD/ZeD_PadGlyphs", "ZeD/ZeD_PadFigure", "ZeD/ZeD_MainMenuOptionsSub", "ZeD/ZeD_ControllerMap" }) do
    local ok, err = pcall(require, n)
    check("loads " .. n, ok, err)
end
if failed > 0 then print("pad_figure_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local MM, PF, G = ZeD.MainMenu, ZeD.PadFigure, ZeD.PadGlyphs
MM.layout = function() return { sw = CORE.screenW, sh = CORE.screenH, tx = 0, ty = 0, tw = CORE.screenW, th = CORE.screenH, ox = 0, oy = 0, s = 1 } end

-- ============================================================================
-- THE CONTROLLER: the game's elements and bindings (stand-ins for the Java enums)
-- ============================================================================
local PRESSED, AXIS = {}, {}
local function enum(name, kind)
    local e = { name = name, kind = kind }
    setmetatable(e, { __tostring = function() return name end })
    e.getNameTranslationKey = function() return ((kind == "a2") and "UI_Joypad2_" or "UI_Joypad_") .. name end
    e.isDown = function() return PRESSED[name] == true end
    e.getValue = function() return AXIS[name] or -1 end
    e.getValueX = function() return (AXIS[name] or { 0, 0 })[1] end
    e.getValueY = function() return (AXIS[name] or { 0, 0 })[2] end
    return e
end
local BTN = {}
for _, n in ipairs({ "A", "B", "X", "Y", "LeftStick", "RightStick", "LeftBump", "RightBump", "Back", "Start", "Guide", "DPadLeft", "DPadRight", "DPadUp", "DPadDown" }) do BTN[#BTN + 1] = enum(n, "b"); BTN[n] = BTN[#BTN] end
JoypadButton = { getButtons = function() local t = {}; for i = 1, 15 do t[i] = BTN[i] end; return t end, Guide = BTN.Guide, A = BTN.A, Y = BTN.Y }
local AX1 = { enum("LeftTrigger", "a1"), enum("RightTrigger", "a1"), enum("LeftStickX", "a1"), enum("LeftStickY", "a1"), enum("RightStickX", "a1"), enum("RightStickY", "a1") }
JoypadAxis1d = { getAxes = function() return AX1 end }
local AX2 = { enum("LeftStick", "a2"), enum("RightStick", "a2") }
JoypadAxis2d = { getAxes = function() return AX2 end }
local BOUND = {}
CALLS = {}
local function rec(name, ...) CALLS[#CALLS + 1] = { name = name, a = { ... } } end
local function binding(name, thr)
    local b = { name = name }
    b.getNameTranslationKey = function() return "UI_Bind_" .. name end
    b.containsBinding = function(_, el) return BOUND[name] and BOUND[name][el] == true end
    b.addBinding = function(_, el) BOUND[name] = BOUND[name] or {}; BOUND[name][el] = true; rec("addBinding", name, tostring(el)) end
    b.removeBinding = function(_, el) if BOUND[name] then BOUND[name][el] = nil end; rec("removeBinding", name, tostring(el)) end
    b.isAxisMaxThresholdInfinity = function() return true end
    b.getAxisMinThreshold = function() return thr or 0.5 end
    return b
end
local BINDS = { binding("Interact"), binding("Run"), binding("Aim", -0.8), binding("Crouch") }
BOUND.Interact = { [BTN.A] = true }
BOUND.Aim = { [AX1[1]] = true }
BOUND.Crouch = { [BTN.LeftStick] = true }
CharacterJoypadButtonBinding = {
    allBindings = function() return BINDS end,
    findBindings = function(el) local t = {}; for _, b in ipairs(BINDS) do if BOUND[b.name] and BOUND[b.name][el] then t[#t + 1] = b end end; return t end,
}
local MOVE = { name = "Movement", getNameTranslationKey = function() return "UI_Bind_Movement" end }
MOVE.getBinding = function() return MOVE.on end
MOVE.setBinding = function(_, el) MOVE.on = el end
MOVE.removeBinding = function() MOVE.on = nil end
MOVE.on = AX2[1]
CharacterJoypadAxis2dBinding = {
    allBindings = function() return { MOVE } end,
    findBindings = function(el) if MOVE.on == el then return { MOVE } end; return {} end,
}
-- vanilla's controller page: the bindings editor and its test panel's pick
local testPanel = { selectedController = nil }
local combo = ISComboBox:new(0, 0, 100, 20, testPanel, function(self, c)
    local d = c:getOptionData(c.selected)
    self.selectedController = (d and d >= 0) and d or nil
    JoypadState.controllerTest = self.selectedController ~= nil
end)
combo:addOptionWithData("<None>", -1)
combo:addOptionWithData("Xbox Controller", 0)
testPanel.combo = combo
local editor = ISPanel:new(0, 0, 10, 10)
editor.Type = "ISControllerBindingsEditorPanel"
editor.gameOptionControllerTab = { controllerTestPanel = testPanel }
editor.onJoypadButtonBindingEdited = function() rec("editorEdited") end
local page = ISPanel:new(0, 0, 10, 10)
page:addChild(editor)
local mainOptions = { tabs = { viewList = { { name = "CONTROLLER", view = page } } }, gameOptions = { changed = false } }
setmetatable(mainOptions, { __index = MainOptions })
MainScreen.instance = { inGame = true, mainOptions = mainOptions }

-- ============================================================================
-- HELPERS
-- ============================================================================
local ow = ZeD_MMOptions:new(true)
ow:initialise()
ow:instantiate()
ow.anyChanged = function() return false end
ow:setVisible(true)

local function frame()
    DRAWN, JDRAW = {}, {}
    ow:prerender()
    return ow._padFig
end
local function openPage(w, h, root, base)
    CORE.screenW, CORE.screenH = w, h
    theme(root, base)
    ow.sub = nil
    ow:openSub("pad")
    ow.focusId = nil
    return frame()
end
local function rectsMeet(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
-- do segments (p1 p2) and (p3 p4) cross (touching at an end does not count)
local function segsCross(x1, y1, x2, y2, x3, y3, x4, y4)
    local function orient(ax, ay, bx, by, cx, cy) return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax) end
    local d1, d2 = orient(x3, y3, x4, y4, x1, y1), orient(x3, y3, x4, y4, x2, y2)
    local d3, d4 = orient(x1, y1, x2, y2, x3, y3), orient(x1, y1, x2, y2, x4, y4)
    return ((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0))
end
local function segHitsRect(x1, y1, x2, y2, r)
    -- sample the segment: a leader is a few hundred px at most
    local n = math.max(1, math.ceil(math.max(math.abs(x2 - x1), math.abs(y2 - y1))))
    for i = 0, n do
        local x, y = x1 + (x2 - x1) * i / n, y1 + (y2 - y1) * i / n
        if x > r.x + 1 and x < r.x + r.w - 1 and y > r.y + 1 and y < r.y + r.h - 1 then return true end
    end
    return false
end
local IDS = { "LT", "LB", "DPAD", "LS", "SEL", "START", "RT", "RB", "Y", "B", "A", "RS", "X" }

-- every label inside the box, none over another or over the pad; leaders from the part to the label, none crossing,
-- none through another label
local function checkPlacement(fig, label)
    local box = fig.box
    local pad = { x = fig.x, y = fig.y, w = fig.w, h = fig.h }
    local inside, overlap, onPad, ends = 0, nil, nil, 0
    for i, a in ipairs(IDS) do
        local la = fig.labs[a]
        if la.x < box.x or la.y < box.y or la.x + la.w > box.x + box.w or la.y + la.h > box.y + box.h then inside = inside + 1 end
        if rectsMeet(la, pad) then onPad = a end
        for j = i + 1, #IDS do if rectsMeet(la, fig.labs[IDS[j]]) then overlap = a .. "/" .. IDS[j] end end
        -- the leader ends on the label's edge (x on its left or right edge for the columns, y on its top or bottom)
        local l = la.lead
        local ex, ey = box.x + l[#l - 1], box.y + l[#l]
        local onEdge = (math.abs(ex - la.x) <= 1 or math.abs(ex - (la.x + la.w)) <= 1) or (math.abs(ey - la.y) <= 1 or math.abs(ey - (la.y + la.h)) <= 1)
        if not onEdge then ends = ends + 1 end
    end
    check(label .. ": every label inside the figure's box", inside == 0, inside)
    check(label .. ": no label over another", overlap == nil, overlap)
    check(label .. ": no label over the pad", onPad == nil, onPad)
    check(label .. ": every leader ends on its label", ends == 0, ends)
    local cross, through = nil, nil
    for i, a in ipairs(IDS) do
        local la = fig.labs[a].lead
        for s = 1, #la / 2 - 1 do
            local x1, y1, x2, y2 = box.x + la[2 * s - 1], box.y + la[2 * s], box.x + la[2 * s + 1], box.y + la[2 * s + 2]
            for j = i + 1, #IDS do
                local lb = fig.labs[IDS[j]].lead
                for t = 1, #lb / 2 - 1 do
                    if segsCross(x1, y1, x2, y2, box.x + lb[2 * t - 1], box.y + lb[2 * t], box.x + lb[2 * t + 1], box.y + lb[2 * t + 2]) then cross = a .. "/" .. IDS[j] end
                end
            end
            for _, b in ipairs(IDS) do
                if b ~= a and segHitsRect(x1, y1, x2, y2, fig.labs[b]) then through = a .. " through " .. b end
            end
        end
    end
    check(label .. ": no two leaders cross", cross == nil, cross)
    check(label .. ": no leader runs through another label", through == nil, through)
end

local function draws(pred)
    local t = {}
    for _, d in ipairs(JDRAW) do if d.p == ow and pred(d) then t[#t + 1] = d end end
    return t
end
local function texName(d) return d.tex and d.tex.path and d.tex.path:match("([%w_]+)%.png$") or "?" end

-- ============================================================================
-- 1. THE WHOLE MULTIPLE AND THE LABELS, PER SCREEN
-- ============================================================================
local fig = openPage(3840, 2160, 1.75)
check("4K 1.75: the page shows the figure", fig ~= nil)
check("4K 1.75: 5 screen px to an art px (the mockup's)", fig.k == 5, fig.k)
checkPlacement(fig, "4K 1.75")
check("4K 1.75: the pad is 188 x 106 art px at k", fig.w == 188 * fig.k and fig.h == 106 * fig.k, fig.w .. "x" .. fig.h)
fig = openPage(1280, 800, 0.75)
check("Deck 0.75: 2 screen px to an art px (the mockup's)", fig.k == 2, fig.k)
checkPlacement(fig, "Deck 0.75")
fig = openPage(1280, 720, 0.75)
check("720p 0.75: the drawing fits (at least 1)", fig.k >= 1, fig.k)
checkPlacement(fig, "720p 0.75")
fig = openPage(1920, 1080, 1)
checkPlacement(fig, "1080p 1.0")
-- Large text: the same labels, bigger
CORE.screenW, CORE.screenH = 3840, 2160
ZEDQA_ROOT = 1.75
ZeD.applyTheme("dark", "teal", "large")
ow.sub = nil
ow:openSub("pad")
fig = frame()
checkPlacement(fig, "4K 1.75 Large text")
-- German: longer words
loadWords("DE")
fig = openPage(3840, 2160, 1.75)
checkPlacement(fig, "4K 1.75 DE")
fig = openPage(1280, 800, 0.75)
checkPlacement(fig, "Deck 0.75 DE")
check("Deck 0.75 DE: still 2 px to an art px", fig.k == 2, fig.k)
loadWords("RU")
fig = openPage(1280, 800, 0.75)
checkPlacement(fig, "Deck 0.75 RU")
loadWords("EN")
-- the light theme: the leaders draw without their dark case
fig = openPage(3840, 2160, 1.75, "light")
checkPlacement(fig, "4K light")

-- ============================================================================
-- 2. THE LIVE TEST, DRAW BY DRAW
-- ============================================================================
fig = openPage(3840, 2160, 1.75)
local k = fig.k
local rest = draws(function(d) return texName(d) == "zpad_xbox_stickup" end)
check("at rest: one draw of the resting pad", #rest == 1 and #draws(function(d) return texName(d):find("_parts") end) == 0, #rest)
check("at rest: the whole 188 x 106 at k, from the pad's corner", rest[1] and rest[1].sw == 188 and rest[1].sh == 106 and rest[1].w == 188 * k and rest[1].h == 106 * k
      and rest[1].x == fig.x and rest[1].y == fig.y)
check("the textures load with nearest filtering", rest[1] and rest[1].tex.flags == 3)
for _, id in ipairs(IDS) do check("at rest: " .. id .. " not lit", fig.lit[id] == false) end
-- A held, from the menu's own controller
PAD = { id = 0, focus = MainScreen.instance }
PRESSED.A = true
fig = frame()
local parts = draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" end)
local function panelOf(d) return math.floor(d.sx / 188) end
local under, shade, light, ink
for _, d in ipairs(parts) do
    local p = panelOf(d)
    if p == 0 then under = d elseif p == 2 then shade = d elseif p == 3 then light = d elseif p == 4 then ink = d end
end
-- A rests at art (150, 83): its disc 144..156, its shadow to 157; the crop starts at (8, 21)
check("A held: the under patch covers its resting disc and shadow (14 x 14)", under and under.sx == 136 and under.sy == 56 and under.sw == 14 and under.sh == 14
      and under.x == fig.x + 136 * k and under.y == fig.y + 56 * k)
check("A held: its shade box one art px down and right", shade and shade.sx == 2 * 188 + 136 and shade.sw == 13 and shade.x == fig.x + 137 * k and shade.y == fig.y + 57 * k)
local ac = ZeD.T.accent
check("A held: the shade tinted with the accent", shade and math.abs(shade.r - ac.r) < 1e-9 and math.abs(shade.g - ac.g) < 1e-9 and math.abs(shade.b - ac.b) < 1e-9)
check("A held: the light rims tinted 38% toward white", light and math.abs(light.r - (ac.r + (1 - ac.r) * 0.38)) < 1e-9 and light.x == shade.x)
local on = ZeD.T.textOnAccent
check("A held: its letter in the ink on the accent", ink and math.abs(ink.r - on.r) < 1e-9 and ink.x == shade.x)
local order = {}
for _, d in ipairs(parts) do order[#order + 1] = panelOf(d) end
check("A held: the patch drawn before the lit part", order[1] == 0, table.concat(order, ","))
check("A held: the label and its leader lit", fig.lit.A == true)
PRESSED.A = nil
-- a trigger half pulled: 4 of its 7 rows, the bottom ones
AXIS.LeftTrigger = 0   -- (half: -1 rest, 1 full)
fig = frame()
parts = draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" end)
local rows
for _, d in ipairs(parts) do if panelOf(d) == 2 then rows = d end end
check("LT half pulled: its shade over the bottom 4 rows (27..30) of 34..59", rows and rows.sw == 26 and rows.sh == 4 and rows.sy == 27 - 21 and rows.sx == 2 * 188 + 34 - 8, rows and (rows.sy .. "/" .. rows.sh))
check("LT half pulled: no ink on a trigger", #draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" and panelOf(d) == 4 end) == 0)
check("LT half pulled: its label lit, 50 percent", fig.lit.LT == true and fig.st.lt == 0.5)
local pct = false
for _, d in ipairs(DRAWN) do if d.kind == "text" and d.text == "50%" then pct = true end end
check("LT half pulled: the label says 50%", pct)
AXIS.LeftTrigger = -0.99   -- (a trigger at rest reads about -1: under 2 percent, nothing lit)
fig = frame()
check("LT at rest (-0.99): not lit, no rows", fig.lit.LT == false and #draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" end) == 0)
AXIS.LeftTrigger = nil
-- the left stick pushed right (Xbox: the left stick up top, its well radius 15: 6 art px), clicked
AXIS.LeftStick = { 1, 0 }
PRESSED.LeftStick = true
fig = frame()
parts = draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" end)
local capU, capC, capL
for _, d in ipairs(parts) do
    local p = panelOf(d)
    if p == 0 then capU = d elseif p == 1 then capC = d elseif p == 2 then capL = d end
end
check("LS pushed: its resting cap covered (20 x 20 at art 41, 62)", capU and capU.sx == 41 - 8 and capU.sy == 62 - 21 and capU.sw == 20 and capU.sh == 20)
check("LS pushed: the cap drawn 6 art px right", capC and capC.sx == 188 + 33 and capC.x == fig.x + (33 + 6) * k and capC.y == fig.y + 41 * k)
check("LS clicked: the cap lit where it moved", capL and capL.x == fig.x + (33 + 6) * k and capL.sw == 19)
check("LS: its label lit, its dial's dot moved", fig.lit.LS == true)
AXIS.LeftStick, PRESSED.LeftStick = { 0.1, 0.1 }, nil
fig = frame()
check("LS barely pushed: not lit (under a quarter)", fig.lit.LS == false)
check("LS barely pushed: the cap already moves (0.1 x 6 rounds to 1 art px)", #draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" and panelOf(d) == 1 end) == 1)
AXIS.LeftStick = { 3, 4 }   -- (pushed past the unit circle: kept to it, 0.6 / 0.8 of 6)
fig = frame()
for _, d in ipairs(draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" and panelOf(d) == 1 end)) do capC = d end
check("LS pushed past the edge: kept to the unit circle (4, 5)", capC and capC.x == fig.x + (33 + 4) * k and capC.y == fig.y + (41 + 5) * k)
AXIS.LeftStick = nil
-- a D-pad arm: in place, with its arrow
PRESSED.DPadUp = true
fig = frame()
parts = draws(function(d) return texName(d) == "zpad_xbox_stickup_parts" end)
local arm
for _, d in ipairs(parts) do if panelOf(d) == 4 then arm = d end end
-- Xbox: the D-pad at (84, 93); its up arm 80..88 x 80..88
check("DU held: its arm lit in place, arrow and all", arm and arm.sx == 4 * 188 + 80 - 8 and arm.sy == 80 - 21 and arm.sw == 9 and arm.sh == 9 and arm.x == fig.x + 72 * k)
check("DU held: the D-pad's label lit", fig.lit.DPAD == true)
PRESSED.DPadUp = nil
-- the test's own controller: the drawing follows it, and A and Y together end the test
PAD = nil
combo.selected = 2
combo.onChange(testPanel, combo)
PRESSED.X = true
fig = frame()
check("test controller: the drawing follows it", fig.lit.X == true)
PRESSED.A, PRESSED.Y = true, true
frame()
check("test controller: A and Y held end the test, as the game's", JoypadState.controllerTest == false)
PRESSED.A, PRESSED.Y, PRESSED.X = nil, nil, nil
testPanel.selectedController = nil
JoypadState.controllerTest = nil
combo.selected = 1

-- ============================================================================
-- 3. THE GLYPH SET: THE TEXTURE AND THE LAYOUT
-- ============================================================================
local function restTex()
    frame()
    for _, d in ipairs(JDRAW) do if d.p == ow and texName(d):find("^zpad_") then return texName(d) end end
end
for _, c in ipairs({ { "xbox", "zpad_xbox_stickup", "stickup" }, { "ps", "zpad_ps_house", "house" }, { "deck", "zpad_deck_house", "house" },
                     { "nintendo", "zpad_nin_stickup", "stickup" } }) do
    GLYPH = c[1]
    check("glyphs " .. c[1] .. ": the drawing " .. c[2], restTex() == c[2], restTex())
end
GLYPH = "auto"
CORE.style = "PS4"
check("Auto on a PlayStation pad: the PlayStation drawing", restTex() == "zpad_ps_house")
CORE.style = "XBOX"
GLYPH = "off"
check("glyph pictures off: the Xbox drawing", restTex() == "zpad_xbox_stickup")
GLYPH = "auto"
check("Xbox: the D-pad's leader from its left arm lower down (art 71, 93)", PF.anchors("xbox").DPAD.a[1] == 71 and PF.anchors("xbox").DPAD.a[2] == 93)
check("PlayStation: the D-pad up top (art 37, 71)", PF.anchors("ps").DPAD.a[1] == 37 and PF.anchors("ps").DPAD.a[2] == 71)
check("PlayStation: View's label names Create in the pull-down", MM.padElName({ key = BTN.Back, kind = "button", role = "SEL" }, "ps") == "Back (Create)")
check("Xbox: the left bumper's pull-down name", MM.padElName({ key = BTN.LeftBump, kind = "button", role = "LB" }, "xbox") == "Left Bump (LB)")
check("a stick's click said as one", MM.padElName({ key = BTN.LeftStick, kind = "button", role = "L3" }, "xbox") == ZeD.tr("UI_ZeD_PadFig_StickClick", "Left Hat"))
-- the help line names this pad's bumpers
GLYPH = "ps"
MM.forceGamepad = true
ow.focusId = "lab:LB"
frame()
check("PlayStation: the left bumper's help says L1 + R1", ZeD.Help.last and ZeD.Help.last:find("L1 + R1", 1, true) ~= nil, ZeD.Help.last)
check("on a controller the help line says how to edit with its A (Cross)", ZeD.Help.last and ZeD.Help.last:find(ZeD.tr("UI_ZeD_PadFig_EditPad", "Cross"), 1, true) ~= nil)
MM.forceGamepad = nil
GLYPH = "auto"

-- ============================================================================
-- 4. THE PULL-DOWNS
-- ============================================================================
fig = openPage(3840, 2160, 1.75)
local function spec(id) for _, s in ipairs(ow._specs) do if s.id == id then return s end end end
for _, id in ipairs(IDS) do check("a stop for the label " .. id, spec("lab:" .. id) ~= nil) end
local nStops = 0
for _, s in ipairs(ow._specs) do if s.padLab then nStops = nStops + 1 end end
check("one stop per label (13)", nStops == 13, nStops)
-- the left trigger: its one element, straight to its actions
spec("lab:LT").fn()
local pop = MM.popup
check("LT: its actions under its name", MM.ctx.open == "combo" and pop.items[1].header and pop.items[1].text == "Left Trigger (LT)")
local aim
for _, it in ipairs(pop.items) do if type(it) == "table" and it.text and it.text:find("Aim", 1, true) then aim = it end end
check("LT: Aim ticked, with its pull point", aim and aim.check == true and aim.text == "Aim > -0.80", aim and aim.text)
check("LT: the pull-down opens at the label", pop.anchor.x == ow:getAbsoluteX() + fig.labs.LT.x and pop.anchor.w == fig.labs.LT.w)
check("LT: nothing to go back to", pop.back == nil)
MM.ctx.open = nil
-- the left stick: first which element
spec("lab:LS").fn()
pop = MM.popup
check("LS: asks which element: the stick, then its click", #pop.items == 2 and pop.items[1].text == "Left Stick" and pop.items[2].text == ZeD.tr("UI_ZeD_PadFig_StickClick", "Left Hat"))
check("LS: each with its picture and what it does now", pop.items[1].pad[1] == "LS" and pop.items[1].right == "Movement" and pop.items[2].pad[1] == "L3" and pop.items[2].right == "Crouch")
-- A on the click (the pull-down's own A: MM.joyDown), then B back to the question
local m = MainScreen.instance
MM.ctx.dropFocus = 2
MM.joyDown(m, Joypad.AButton)
pop = MM.popup
check("LS click: its actions, Crouch ticked", MM.ctx.open == "combo" and pop.items[1].header and pop.items[1].text == ZeD.tr("UI_ZeD_PadFig_StickClick", "Left Hat"))
check("LS click: B goes back", pop.back ~= nil)
MM.joyDown(m, Joypad.BButton)
check("LS click, B: back to which element", MM.ctx.open == "combo" and MM.popup.items[1].text == "Left Stick")
MM.joyDown(m, Joypad.BButton)
check("which element, B: closed", MM.ctx.open == nil)
-- the D-pad: its four arms
spec("lab:DPAD").fn()
check("D-pad: asks which arm (4)", #MM.popup.items == 4 and MM.popup.items[1].pad[1] == "DU")
MM.ctx.open = nil
-- a pick edits the game's binding (Run onto B), and the label says so
spec("lab:B").fn()
local run
for _, it in ipairs(MM.popup.items) do if type(it) == "table" and it.text == "Run" then run = it end end
CALLS = {}
run.fn()
check("B: a pick adds the action on the game's binding", CALLS[1] and CALLS[1].name == "addBinding" and CALLS[1].a[1] == "Run" and CALLS[1].a[2] == "B")
MM.ctx.open = nil
fig = frame()
check("B: its label says Game: Run", fig.labs.B.lines[1] == ZeD.tr("UI_ZeD_PadFig_Game", "Run"))
BOUND.Run = nil
-- the controller: A on the focused label opens it; the prompts say so; B on the page backs out
MM.forceGamepad = true
ow.focusId = "lab:RT"
frame()
ow:joyA()
check("A on a label opens its pull-down", MM.ctx.open == "combo" and MM.popup.items[1].text == "Right Trigger (RT)")
local pr = ow:getFooterPrompts()
check("pad prompts while a pull-down is open: move, choose, back", pr[1].pad[1] == "DUD" and pr[#pr].glyph == "B")
MM.ctx.open = nil
pr = ow:getFooterPrompts()
check("pad prompts on the page: D-pad move first", pr[1].pad[1] == "DPAD")
JoypadState.controllerTest = true
pr = ow:getFooterPrompts()
check("pad prompts during a test: only A and Y to leave it", #pr == 1 and pr[1].pad[1] == "A" and pr[1].pad[2] == "Y")
JoypadState.controllerTest = nil
-- the D-pad walks the labels (spatial): down from LT reaches the next left label
ow.focusId = "lab:LT"
frame()
ow:joyDir("down")
check("D-pad down from LT: the left bumper's label", ow.focusId == "lab:LB", ow.focusId)
ow:joyDir("right")
check("D-pad right from LB: somewhere new", ow.focusId ~= "lab:LB", ow.focusId)
ow:joyB()
check("B on the page: back to the Controls page", ow.sub == nil)
MM.forceGamepad = nil

-- ============================================================================
-- 5. THE CONTROLLER MAP: THE SAME DRAWING
-- ============================================================================
local CM = ZeD.ControllerMap
local function cmap(w, h, root)
    CORE.screenW, CORE.screenH = w, h
    theme(root)
    local win = ZeD_ControllerMap:new(0)
    win:initialise()
    win:instantiate()
    JDRAW = {}
    win:prerender()
    for _, d in ipairs(JDRAW) do if d.p == win then return d, win end end
end
local d, win = cmap(3840, 2160, 1.75)
check("Controller map 4K: the same resting pad", d and texName(d) == "zpad_xbox_stickup" and d.sw == 188)
check("Controller map 4K: 4 px to an art px, centered", d and d.w == 188 * 4 and math.abs((d.x - ZeD.T.px(14)) * 2 + d.w - (win.width - 2 * ZeD.T.px(14))) <= 1, d and d.w)
d = cmap(1280, 800, 0.75)
check("Controller map Deck: 1 px to an art px (its 360 px card)", d and d.w == 188, d and d.w)
GLYPH = "ps"
d = cmap(3840, 2160, 1.75)
check("Controller map PlayStation: the PlayStation drawing", d and texName(d) == "zpad_ps_house")
GLYPH = "auto"
check("the old picture is gone from the code", (function()
    local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_ControllerMap.lua", "rb")
    local s = f:read("*a")
    f:close()
    return s:find("controller_map.png", 1, true) == nil
end)())

print("pad_figure_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
