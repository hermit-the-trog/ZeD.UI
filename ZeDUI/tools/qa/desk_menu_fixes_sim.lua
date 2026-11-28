-- ZeDUI/tools/qa/desk_menu_fixes_sim.lua  (Nov 27 2026, the menus sweep's desk bugs): the real Tokens, Tr, Atoms,
-- Molecules, ZeD_MainMenu.lua, ZeD_MainMenuSaves.lua, ZeD_MainMenuDesktop.lua, ZeD_MainMenuDesktopPick.lua,
-- ZeD_MainMenuWorkshop.lua and ZeD_MainMenuDescEdit.lua run on Lua 5.1 against stubs of the game's UI classes (the
-- harness is desk_pad_sim.lua's). It checks:
--   * DK19 / DK59: a window with unsaved work asks its Back question on every way off it (a view change, the power
--     button's Quit, File > Continue) and goes on with the move only on its leave answer; the Workshop's and the
--     description editor's questions; the editor hands back to the Workshop when only the Workshop has edits
--   * DK58: an upload waiting for Steam survives the window being left and shown again
--   * DK51: File > Continue saves the notepad's draft first
--   * DK14: the quit question's and the Trash's footer name the focused answer
--   * DK2: the D-pad does nothing while the monitor switches on
--   * DK21: the ZeD menu's pull-down stays on the tube at 1280 x 800
--   * DK30: every left-side item stays on the desk when the columns run out
--   * DK44: the Desktop window scrolls on a short tube and follows the controller
-- What it can't show: the Mods window (MM2, MM3, MM5: its file needs the game's mod model), the drawing itself.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/desk_menu_fixes_sim.lua
-- It prints FAIL lines and a last line "desk_menu_fixes_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]desk_menu_fixes_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end

-- ============================================================================
-- THE GAME'S GLOBALS
-- ============================================================================
local nowMs = 1000000
function getTimestampMs() return nowMs end
function getTimestamp() return 1000 end
function isClient() return false end
function isServer() return false end
function isMouseButtonDown() return false end
function getMouseX() return -1 end
function getMouseY() return -1 end
function getDebug() return false end
function getFileReader() return nil end
function getTexture() return nil end
function getFileWriter() return { write = function() end, writeln = function() end, close = function() end } end
function isIngameState() return false end
function getSoundManager() return { playUISound = function() end, stopUISound = function() end, StopMusic = function() end } end
function updateJoypadFocus() end
function setJoypadFocus() end
function instanceof() return false end
function triggerEvent() end
function ZombRand(n) return 0 end
function getActivatedMods() return { size = function() return 0 end } end
local CORE = { screenW = 1920, screenH = 1080 }
function getCore()
    return {
        getScreenWidth = function() return CORE.screenW end, getScreenHeight = function() return CORE.screenH end,
        getObjectHighlitedColor = function() return { getR = function() return 0.5 end, getG = function() return 0.5 end, getB = function() return 0.5 end } end,
        getOptionFontSizeReal = function() return 1 end, getOptionControllerButtonStyleString = function() return "XBOX" end,
    }
end
UIManager = { setShowPausedMessage = function() end, isModalVisible = function() return false end, getMillisSinceLastRender = function() return 16 end }
Keyboard = { KEY_ESCAPE = 1, KEY_RETURN = 28, KEY_UP = 200, KEY_DOWN = 208, KEY_LEFT = 203, KEY_RIGHT = 205 }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
JoypadState = { players = {}, getMainMenuJoypad = function() return nil end }
UIFont = setmetatable({}, { __index = function(_, k) return k end })
LuaEventManager = { AddEvent = function() end }
Events = setmetatable({}, { __index = function(t, k)
    local e = { Add = function() end, Remove = function() end }
    rawset(t, k, e)
    return e
end })
Translator = { getLanguage = function() return { name = function() return "EN" end } end, getAvailableLanguage = function() return nil end }
local TEXT = {}
do
    local f = io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb")
    if f then
        local s = f:read("*a")
        f:close()
        for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\r?\n') do TEXT[k] = v end
    end
end
function getText(k) return TEXT[k] or k end
function getTextOrNull(k) return TEXT[k] end
function getTextManager()
    return { getFontHeight = function() return 14 end, MeasureStringX = function(_, _, s) return #tostring(s or "") * 7 end,
             getFontFromEnum = function() return { getLineHeight = function() return 14 end } end }
end
string.trim = string.trim or function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
Texture = { getSharedTexture = function(path) return { path = path, isReady = function() return true end } end }

-- ============================================================================
-- THE GAME'S UI CLASSES (enough for the desk's panels)
-- ============================================================================
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
    local o = { x = x or 0, y = y or 0, width = w or 0, height = h or 0, visible = true, children = {} }
    setmetatable(o, self)
    self.__index = self
    return o
end
local E = ISUIElement
function E:initialise() end
function E:instantiate()
    if self._inst then return end
    self._inst = true
    self.javaObject = { setMaxLines = function() end, setMaxTextLength = function() end }
    if self.createChildren then self:createChildren() end
end
function E:addChild(c) c.parent = self; self.children[#self.children + 1] = c; if not c._inst then c:instantiate() end; return c end
function E:removeChild() end
function E:setVisible(v) self.visible = v and true or false end
function E:isVisible() return self.visible end
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
function E:getMouseX() return -1 end
function E:getMouseY() return -1 end
function E:isMouseOver() return false end
for _, n in ipairs({ "setAnchorLeft", "setAnchorRight", "setAnchorTop", "setAnchorBottom", "setAlwaysOnTop", "bringToTop", "setFont",
                     "drawRect", "drawText", "drawRectBorder", "drawTexture", "drawTextureScaled", "drawTextureScaledAspect", "drawTextCentre",
                     "setStencilRect", "clearStencilRect", "setWantKeyEvents", "setCapture", "unfocus" }) do
    E[n] = E[n] or function() end
end
function E:prerender() end
function E:render() end
function E:update() end
function E:createChildren() end
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
function ISTextEntryBox:unfocus() self.hasFocus = false end
for _, n in ipairs({ "setMultipleLine", "setMaxLines", "setCursorPos", "setEditable", "setSelectable", "selectAll", "clear" }) do ISTextEntryBox[n] = ISTextEntryBox[n] or function() end end
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
ZeD.TM = {
    MeasureStringX = function(_, font, s) return #tostring(s or "") * 7 end,
    MeasureStringY = function() return 14 end,
    getFontHeight = function() return 14 end,
}
ZeD.Scale = { root = function() return 1 end }
ZeD.Help = { set = function() end }
ZeD.Safe = { on = function() return false end, register = function() end }
ZeD.Surface = { fill = function() end }
-- the controller's mark: every mark that shows (its opts' pad, as FocusPaint's isShowing reads it), by panel
MARKS = {}
ZeD.Focus = {
    mark = function(p, x, y, w, h, opts)
        if type(opts) == "table" and opts.pad then MARKS[#MARKS + 1] = { p = p, x = x, y = y, w = w, h = h }; return true end
        return false
    end,
    drawOverlay = function() end,
}
ZeD.MouseTick = { down = function() return false end }
ZeD.Font = { sdf = { head = { face = 64 } } }
ZeD.Text = { draw = function() end, width = function(face, s, z) return #tostring(s) * 32 * z end,
             height = function(face, z) return 64 * z end, fitEntry = function() end, entryFont = function() return "Small" end }
ZeD.btnCase = function(s) return s end

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
ZeD.applyTheme("dark", "teal", "small")
ZeD.Atoms.drawPxIcon = function() end
local MM
do
    local ok, err = pcall(function()
        require "ZeD/ZeD_MainMenu"
        require "ZeD/ZeD_MainMenuSaves"
        require "ZeD/ZeD_MainMenuDesktop"
        require "ZeD/ZeD_MainMenuDesktopPick"
        require "ZeD/ZeD_MainMenuWorkshop"
        require "ZeD/ZeD_MainMenuDescEdit"
    end)
    check("the desk's files load", ok, err)
    if not ok then print("desk_menu_fixes_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
    MM = ZeD.MainMenu
end
MM.leftItems = function() return {} end
MM.drawGameArt = function() end   -- (the game's pictures: drawing only)

local m = { inGame = false, delay = 0 }
m.bottomPanel = ISPanel:new(0, 0, 10, 10)
MainScreen.instance = m
MM.forceGamepad = true
local root = ISPanel:new(0, 0, 1920, 1080)
MM.root = root
root.bar = ZeD_MMBar:new(); root:addChild(root.bar)
root.icons = ZeD_MMIcons:new(); root:addChild(root.icons)
root.win = ZeD_MMWindow:new("main"); root:addChild(root.win)
root.drop = ZeD_MMDrop:new(); root:addChild(root.drop)
for _, v in ipairs(MM.views) do
    local ok, w = pcall(v.make)
    if ok and w then
        local ok2, e2 = pcall(function() root:addChild(w) end)
        if ok2 then root[v.field] = w elseif os.getenv("SIM_DEBUG") then print("view " .. v.view .. ": " .. tostring(e2)) end
    elseif os.getenv("SIM_DEBUG") then print("view " .. v.view .. ": " .. tostring(w)) end
end
MM.view = "main"

-- ---------------------------------------------------------------------------
section("DK19: the shared leave route (MM.showView, MM.leaveGuard, MM.leaveRun)")
-- a stand-in window with unsaved work, on the desk as the "stub" view
STUB = { asked = 0, dirty = true }
local stub = ZeD_MMWindow:new("stub")
function stub:askLeave(go, view)
    if not STUB.dirty then return false end
    STUB.asked, STUB.go, STUB.view = STUB.asked + 1, go, view
    return true
end
MM.addView("stub", "stubWin", function() return stub end)
root:addChild(stub); root.stubWin = stub
MM.showView("stub")
check("the view goes up", MM.view == "stub", MM.view)
MM.showView("credits")
check("leaving by a view change asks first", STUB.asked == 1 and MM.view == "stub", MM.view)
check("the guard keeps where the move went", STUB.view == "credits", STUB.view)
MM.leaveRun(STUB.go)
check("the leave answer goes on with the move, past the question", MM.view == "credits", MM.view)
MM.showView("stub")
STUB.asked = 0
MM.act.askQuit()
check("the power button / Quit asks first", STUB.asked == 1 and MM.view == "stub" and not root.win.confirm, MM.view)
MM.leaveRun(STUB.go)
check("its leave answer goes to the quit question", MM.view == "main" and root.win.confirm == true, MM.view)
root.win:setConfirm(false)
MM.showView("stub")
STUB.asked = 0
local FIRED = {}
local orig = MainScreen.onMenuItemMouseDownMainMenu
MainScreen.onMenuItemMouseDownMainMenu = function(item) FIRED[#FIRED + 1] = item end
m.latestSaveOption = { name = "continue" }
MM.act.continue()
check("File > Continue asks first", STUB.asked == 1 and #FIRED == 0)
MM.leaveRun(STUB.go)
check("its leave answer starts the game", #FIRED == 1 and FIRED[1] == m.latestSaveOption)
STUB.dirty = false
MM.showView("credits")
check("nothing unsaved: the move goes through", MM.view == "credits", MM.view)

-- ---------------------------------------------------------------------------
section("DK51: File > Continue saves the notepad's words first")
local flushed = 0
MM.flushNotepad = function() flushed = flushed + 1 end
FIRED = {}
MM.showView("main")
MM.act.continue()
check("the notepad is flushed before the game's item fires", flushed == 1 and #FIRED == 1, flushed)
MM.flushNotepad = nil
MainScreen.onMenuItemMouseDownMainMenu = orig

-- ---------------------------------------------------------------------------
section("DK59, DK58: the Workshop")
local ws = root.workshopWin
check("the Workshop window is built", ws ~= nil)
if ws then
    local STRIP = {}
    local stripSpecs = MM.ui.stripSpecs
    MM.ui.stripSpecs = function(win, y, w, row, lefts, rights) STRIP.lefts, STRIP.rights = lefts, rights end
    local function answer(id)
        ws:buildStrip(0, 20, 600)
        for _, r in ipairs(STRIP.rights or {}) do if r[1] == id then r[3](); return true end end
        return false
    end
    local FOLDER = { getFolderName = function() return "MyMod" end, readWorkshopTxt = function() end, getID = function() return nil end }
    ws.checkContents = function() end   -- (the folder's files on disk: Steam's, not here)
    ws.items, ws.sel, ws.unsaved = { FOLDER }, 1, { MyMod = true }
    ws.busy = nil
    MM.view = "workshop"
    MM.showView("main")
    check("unsaved edits: the menu bar's move asks Back's question", MM.view == "workshop" and ws.confirm == "leave", tostring(ws.confirm))
    check("the controller lands on Keep editing", ws.focusId == "confirm:cancel", ws.focusId)
    answer("confirm:cancel")
    check("Keep editing stays, and forgets the move", MM.view == "workshop" and not ws.confirm and ws._leaveGo == nil)
    MM.showView("credits")
    check("asked again", ws.confirm == "leave")
    check("Discard changes goes on to where the move went", answer("confirm:no") and MM.view == "credits" and next(ws.unsaved) == nil, MM.view)
    -- Back's own question still lands on the main window
    MM.view = "workshop"
    ws.unsaved = { MyMod = true }
    ws:back()
    check("Back asks", ws.confirm == "leave" and ws._leaveGo == nil)
    answer("confirm:no")
    check("its Discard goes to the main window as before", MM.view == "main", MM.view)
    -- the description editor is the window's own step
    MM.view = "workshop"
    ws.unsaved = { MyMod = true }
    check("opening the description editor never asks", ws:askLeave(function() end, "wsdesc") == false)
    -- DK58: an upload waiting for Steam
    ws.busy = { stage = "send", t0 = 0 }
    ws.note = { text = "x", untilMs = 0 }
    check("an upload waiting lets the move through", ws:askLeave(function() end, "main") == false)
    ws:onShow()
    check("shown again: still waiting for Steam", ws.busy ~= nil and ws.busy.stage == "send")
    check("and the form kept", ws.items[1] == FOLDER and ws.unsaved.MyMod == true)
    ws.busy = nil
    MM.ui.stripSpecs = stripSpecs
end

-- ---------------------------------------------------------------------------
section("DK59: the description editor")
local de = root.wsdescWin
check("the editor is built", de ~= nil)
if de and ws then
    local BB = ZeD.BB
    MM.wsEditor = { text = "old words", title = "T", limit = 8000, done = function(text) ws.desc = text end }
    MM.view = "wsdesc"
    de:onShow()
    ws.unsaved = {}
    check("unchanged, nothing unsaved: the move goes through", de:askLeave(function() end, "main") == false)
    de.blocks = BB.parse("new words")
    local went = 0
    local go = function() went = went + 1; MM.showView("main") end
    check("changed text: Back's question first", de:askLeave(go, "main") == true and de.confirm == "leave")
    de:finish(true)
    check("Keep hands the text to the Workshop", ws.desc == de:text(), ws.desc)
    check("and, nothing else unsaved there, goes on with the move", went == 1 and MM.view == "main", MM.view)
    -- unchanged here but the Workshop holds unsaved edits: the Workshop asks its own question
    MM.view = "wsdesc"
    de:onShow()
    ws.unsaved = { MyMod = true }
    ws.confirm = false
    went = 0
    check("the Workshop's unsaved edits: handed back", de:askLeave(go, "main") == true)
    check("the Workshop asks its question, its form kept", MM.view == "workshop" and ws.confirm == "leave" and ws.unsaved.MyMod == true, MM.view)
    check("the move waits on its answer", went == 0 and ws._leaveGo == go)
    ws:setConfirm(false)
    -- the Workshop picked from the menu bar while editing: back to it, its form kept
    MM.view = "wsdesc"
    de:onShow()
    check("to the Workshop itself: back as Cancel goes", de:askLeave(function() end, "workshop") == true and MM.view == "workshop" and ws.unsaved.MyMod == true)
    ws.unsaved = {}
end

-- ---------------------------------------------------------------------------
section("DK14: the quit question's footer follows the focused answer")
MM.showView("main")
local win = root.win
win:setConfirm(true)
-- (fitted Nov 27 2026 for DK13, the director's pick: the question opens on Cancel; Exit is a deliberate move)
check("the question lands on Cancel (DK13)", win.focusId == "confirm:no", win.focusId)
local fp = win:getFooterPrompts()
check("on Cancel: A Cancel", fp[1].label == getText("UI_Cancel"), fp[1].label)
win.focusId = "confirm:yes"
fp = win:getFooterPrompts()
check("on Quit: A Quit", fp[1].label == getText("IGUI_Exit"), fp[1].label)
win:setConfirm(false)
local tr = root.trashWin
if tr then
    tr.confirm, tr.focusId = true, "confirm:no"
    fp = tr:getFooterPrompts()
    check("the Trash's too", fp[1].label == getText("UI_Cancel"), fp[1].label)
    tr.confirm, tr.focusId = false, nil
end

-- ---------------------------------------------------------------------------
section("DK2: no pad moves while the monitor switches on")
MM.showView("main")
win.focusId = "newgame"
MM.powerOn = { t0 = nowMs }
MM.joyDir(m, "down")
check("the D-pad does nothing while powering on", win.focusId == "newgame", win.focusId)
MM.powerOn = nil

-- ---------------------------------------------------------------------------
section("DK21: a menu bar pull-down fits the tube")
CORE.screenW, CORE.screenH = 1280, 800
MM._layoutKey = nil
local L = MM.layout()
root.bar:prerender()
MM.ctx.open = "zed"
local ok = pcall(function() root.drop:prerender() end)
check("the ZeD menu draws", ok)
local d = root.drop
check("its foot stays on the tube", d.y + d.height <= L.ty + L.th + 1, (d.y + d.height) .. " vs " .. (L.ty + L.th))
MM.ctx.open = nil

-- ---------------------------------------------------------------------------
section("DK30: the left side keeps every item")
local LEFT = {}
for i = 1, 14 do LEFT[i] = { id = "l" .. i, label = "Item " .. i, open = function() end } end
MM.leftItems = function() return LEFT end
local cs = MM._deskCells(MM.layout())
local seen = 0
for _, c in ipairs(cs) do if c.left then seen = seen + 1 end end
check("all 14 left items are on the desk", seen == 14, seen)
for _, c in ipairs(cs) do
    if c.left then check("item " .. c.item.id .. " lies on the tube", c.x >= L.tx and c.y >= L.ty and c.y + c.h <= L.ty + L.th, c.x .. "," .. c.y) end
end
MM.leftItems = function() return {} end

-- ---------------------------------------------------------------------------
section("DK44: the Desktop window scrolls on a short tube")
local dp = root.desktopPickWin
check("the Desktop window is built", dp ~= nil)
if dp then
    MM.showView("desktopPick")
    local ok2, e2 = pcall(function() dp:prerender() end)
    check("it draws", ok2, e2)
    if dp._body then
        check("its body scrolls", dp._body.max > 0, dp._body.max)
        local last = dp._specs[#dp._specs]
        dp.scroll = 0
        local okw = dp:wheel(1)
        check("the wheel needs the pointer over it", okw == false)
        dp.focusId = nil
        for i = #dp._specs, 1, -1 do if dp._specs[i].id and dp._specs[i].id:find("^sw:") then dp.focusId = dp._specs[i].id; break end end
        dp:prerender()
        check("the controller's last swatch is scrolled into sight", dp.scroll > 0, dp.scroll)
    else
        check("its body scrolls (the window was cut)", false, "no scroll at 1280 x 800")
    end
end

print("desk_menu_fixes_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
