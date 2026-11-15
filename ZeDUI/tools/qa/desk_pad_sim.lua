-- ZeDUI/tools/qa/desk_pad_sim.lua  (Nov 14 2026, punch list 213): the desk as one screen for the controller, with no
-- game running. The real Tokens, Tr, Atoms, AtomExtensions, Molecules, ZeD_MainMenu.lua, ZeD_MainMenuSaves.lua and
-- ZeD_MainMenuDesktop.lua run on Lua 5.1 against stubs of the game's UI classes (as pad_figure_sim.lua builds them),
-- on the 1080p room: the menu bar, the desktop's icons (the right column, the Trash, two stand-in icons on the left),
-- the main window and the Trash. It checks:
--   * D-pad off the edge: Up past the top of the main window's controls lands on the menu bar (its first title, the
--     mark there and not in the window); Left / Right walk the titles and stop at the ends; Down and B go back to the
--     window on the button it left; A opens the title's pull-down as a click does; Left / Right in an open one go to
--     the next title's; B shuts it and stays on the bar; a pick hands the controller back to the window
--   * Left / Right past the window's side land on the icons that side of it (never one under it); pushing back
--     toward the window returns to it; Up off the top icon goes on to the bar and Down comes back to the icons
--   * A on an icon opens what its double-click opens (the Trash); X / Y / B keep the notes' own meaning
--   * B closes at the top: the Trash closes on B, a window with no B of its own closes on B, the main window never
--   * the bare desktop (the icons are the view): Up from the top icon to the bar and back
--   * the desk after a death (MM.respawn: the ZeD menu only) and the pause menu in game (no desk) stay as they were
-- What it can't show: the drawing itself (the mark's look is ZeD.Focus's), the engine's own pad events.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/desk_pad_sim.lua
-- It prints FAIL lines and a last line "desk_pad_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]desk_pad_sim%.lua$", "")

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
    end)
    check("the desk's files load", ok, err)
    if not ok then print("desk_pad_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
    MM = ZeD.MainMenu
end

-- two stand-in icons down the left edge (ZeD_MainMenuNotes.lua's list in the game)
OPENED = {}
MM.leftItems = function()
    return { { id = "cletusworks", label = "CletusWorks", open = function() OPENED[#OPENED + 1] = "cletusworks" end },
             { id = "documents", label = "Documents", open = function() OPENED[#OPENED + 1] = "documents" end } }
end

-- ============================================================================
-- THE DESK: MainScreen, the menu bar, the icons, the main window, the Trash
-- ============================================================================
local m = { inGame = false, delay = 0 }
m.bottomPanel = ISPanel:new(0, 0, 10, 10)
MainScreen.instance = m
MM.forceGamepad = true
local root = ISPanel:new(0, 0, 1920, 1080)
MM.root = root
root.bar = ZeD_MMBar:new(); root:addChild(root.bar)
root.icons = ZeD_MMIcons:new(); root:addChild(root.icons)
root.win = ZeD_MMWindow:new("main"); root:addChild(root.win)
for _, v in ipairs(MM.views) do
    local w = v.make()
    root:addChild(w)
    root[v.field] = w
end
MM.view = "main"
local L = MM.layout()

-- one frame: the bar, the icons, the view's window draw (the controller's marks counted afresh)
local function frame()
    nowMs = nowMs + 16
    MARKS = {}
    root.bar:prerender()
    root.icons:prerender()
    local w = MM.activeWindow()
    if w and w ~= root.icons then w:prerender() end
end
local function marksOn(p) local n = 0; for _, k in ipairs(MARKS) do if k.p == p then n = n + 1 end end; return n end
local function joy(dir) MM.joyDir(m, dir); frame() end
local function press(b) MM.joyDown(m, b); frame() end
local function cell(id) return root.icons:find(id) end

frame()
local win = root.win
check("the room's monitor holds the 1080p menu (no small layout)", L.tw == 960 and L.th == 720, L.tw .. "x" .. L.th)
check("the main window is up", MM.activeWindow() == win and win.width > 0)
check("its controller starts on New Game", win.focusId == "newgame", win.focusId)
check("the window shows its mark", marksOn(win) == 1, marksOn(win))
check("the left icons lie beside the window", cell("cletusworks") and cell("cletusworks").x + cell("cletusworks").w <= win.x)
check("the right column lies beside it", cell("pz") and cell("pz").x >= win.x + win.width)

-- ---------------------------------------------------------------------------
section("Up off the top: the menu bar")
joy("up")
check("Up from the top button lands on the menu bar", MM.deskAt == "bar", MM.deskAt)
check("on its first title, the ZeD menu", MM.ctx.barFocus == 1 and MM.menus()[1].key == "zed", MM.ctx.barFocus)
check("the bar shows the mark", marksOn(root.bar) == 1, marksOn(root.bar))
check("and the window shows none", marksOn(win) == 0, marksOn(win))
check("the window keeps its place", win.focusId == "newgame", win.focusId)
local mark = MARKS[1]
check("the mark covers the title", mark and mark.x == root.bar.pos.zed.x and mark.w == root.bar.pos.zed.w, mark and (mark.x .. "," .. mark.w))
joy("left")
check("Left at the first title stays", MM.ctx.barFocus == 1)
joy("right")
check("Right walks to File", MM.ctx.barFocus == 2 and MM.menus()[2].key == "file")
check("the mark follows", MARKS[1] and MARKS[1].x == root.bar.pos.file.x)
for _ = 1, 8 do joy("right") end
check("Right stops at the last title", MM.ctx.barFocus == #MM.menus(), MM.ctx.barFocus)
joy("left")
check("Left walks back", MM.ctx.barFocus == #MM.menus() - 1)
joy("up")
check("Up on the bar stays there", MM.deskAt == "bar")
joy("down")
check("Down returns to the window", MM.deskAt == nil)
check("on the button it left", win.focusId == "newgame", win.focusId)
check("its mark is back", marksOn(win) == 1 and marksOn(root.bar) == 0)
joy("up")
check("and Up again goes back to the bar, on the title it was on", MM.deskAt == "bar" and MM.ctx.barFocus == #MM.menus() - 1)
press(Joypad.BButton)
check("B on the bar returns to the window", MM.deskAt == nil and win.focusId == "newgame")

-- ---------------------------------------------------------------------------
section("A on a title: its pull-down")
joy("up")
MM.ctx.barFocus = 2
press(Joypad.AButton)
check("A opens File, as a click on the title does", MM.ctx.open == "file", MM.ctx.open)
check("the controller on its first row", MM.ctx.dropFocus == 1)
check("the pull-down stands under its title", MM.openItems() ~= nil and select(2, MM.openItems()) == root.bar.pos.file)
joy("down")
check("Down walks its rows", MM.ctx.dropFocus == 2, MM.ctx.dropFocus)
joy("right")
check("Right goes to the next title's pull-down", MM.ctx.open == "mp" and MM.ctx.barFocus == 3 and MM.ctx.dropFocus == 1, MM.ctx.open)
joy("left"); joy("left")
check("Left back to the ZeD menu's", MM.ctx.open == "zed" and MM.ctx.barFocus == 1, MM.ctx.open)
joy("left")
check("Left at the first title stays on it", MM.ctx.open == "zed")
press(Joypad.BButton)
check("B shuts it", MM.ctx.open == nil)
check("and stays on the bar", MM.deskAt == "bar" and MM.ctx.barFocus == 1)
press(Joypad.AButton)
check("A opens the ZeD menu", MM.ctx.open == "zed")
local live = MM.dropLive()
check("its first live row is Credits", live[1] and live[1].text == getText("UI_mainscreen_credits"), live[1] and live[1].text)
press(Joypad.AButton)
check("a pick runs the row (Credits)", MM.view == "credits", MM.view)
check("and the controller is off the bar", MM.deskAt == nil and MM.ctx.open == nil)
MM.showView("main"); frame()

-- ---------------------------------------------------------------------------
section("Left and Right off the side: the icons")
win.focusId = "newgame"
local steps = 0
while MM.deskAt == nil and steps < 8 do joy("left"); steps = steps + 1 end
check("Left past the window's side lands on the icons", MM.deskAt == "icons", steps)
check("straight to the icons: Left from New Game (full width) in one press", steps == 1, steps)
check("the window keeps New Game", win.focusId == "newgame", win.focusId)
local lid = root.icons.focusId
local lc = cell(lid or "")
check("on an icon left of the window", lc and lc.x + lc.w / 2 < win.x, lid)
check("the icon shows the mark, the window none", marksOn(root.icons) == 1 and marksOn(win) == 0, marksOn(root.icons) .. "/" .. marksOn(win))
local wasFocus = win.focusId
root.icons.focusId = "cletusworks"
joy("down")
check("Down walks the icons on that side", root.icons.focusId == "documents" and cell(root.icons.focusId).x + cell(root.icons.focusId).w / 2 < win.x, root.icons.focusId)
for _ = 1, 6 do joy("down") end
check("never across under the window to the Trash", root.icons.focusId ~= "trash", root.icons.focusId)
joy("right")
check("pushing back toward the window returns to it", MM.deskAt == nil, MM.deskAt)
check("on the control it left", win.focusId == wasFocus, win.focusId)
-- the right side
steps = 0
while MM.deskAt == nil and steps < 8 do joy("right"); steps = steps + 1 end
check("Right past the window's side lands on the icons", MM.deskAt == "icons", steps)
check("straight to the icons: Right from New Game in one press", steps == 1 and win.focusId == "newgame", steps)
local rc = cell(root.icons.focusId or "")
check("on an icon right of the window", rc and rc.x >= win.x + win.width, root.icons.focusId)
check("an icon in reach of the window's row (lined up)", rc and rc.y < win.y + win.height, root.icons.focusId)
-- Up off the top icon: the bar, and back
root.icons.focusId = "pz"
joy("up")
check("Up from the top icon goes on to the bar", MM.deskAt == "bar" and MM.deskBack == "icons", MM.deskAt)
joy("down")
check("Down from the bar comes back to the icons", MM.deskAt == "icons" and root.icons.focusId == "pz", MM.deskAt)
-- an icon under the window is out of reach
do
    local ox = win.x
    win.x = cell("documents").x - 10
    local cands = 0
    for _, c in ipairs(root.icons._cells) do if c.left and root.icons:reachable(c, { x = win.x, y = win.y, w = win.width, h = win.height }) then cands = cands + 1 end end
    check("an icon under the window is out of reach", cands < 2, cands)
    win.x = ox
end
-- B on the icons: back to the window
press(Joypad.BButton)
check("B on the icons returns to the window", MM.deskAt == nil and MM.view == "main")

-- ---------------------------------------------------------------------------
section("straight to the icons: only from a full-width button")
MM.showView("main"); frame()
win.focusId = "tutorial"
joy("down")
local bandStop = nil
for _, sp in ipairs(win._specs) do if sp.id == win.focusId then bandStop = sp end end
check("Down from the last big button still reaches the foot band", bandStop and bandStop.band == true and MM.deskAt == nil, win.focusId)
local bf = win.focusId
joy("right")
check("Right in the band walks the band (not off to the icons)", MM.deskAt == nil and win.focusId ~= bf, win.focusId)
win.focusId = "load"
joy("left")
check("Left from Load Game, full width too, goes straight to the left icons", MM.deskAt == "icons" and cell(root.icons.focusId).x < win.x, root.icons.focusId)
MM.showView("main"); frame()
-- the Continue card's button (narrower, but the card's: marked wide)
MM._cont = { title = "Save", where = "Sandbox | Muldraugh", info = true }
frame()
check("Continue shows with a save", win.focusId ~= nil and (function() for _, sp in ipairs(win._specs) do if sp.id == "continue" then return sp.wide == true end end end)())
win.focusId = "continue"
joy("right")
check("Right from Continue goes straight to the right icons", MM.deskAt == "icons" and cell(root.icons.focusId).x >= win.x + win.width, root.icons.focusId)
MM._cont = false
MM.showView("main"); frame()

-- ---------------------------------------------------------------------------
section("A on an icon opens what a click opens")
steps = 0
while MM.deskAt == nil and steps < 8 do joy("right"); steps = steps + 1 end
root.icons.focusId = "trash"
press(Joypad.AButton)
check("A on the Trash opens the Trash", MM.view == "trash", MM.view)
check("the Trash takes the controller", MM.deskAt == nil and MM.activeWindow() == root.trashWin)
-- the mouse: two quick clicks on the Trash icon (its hit's fn) open the same view
MM.showView("main"); frame()
local function hitFn(id) for _, h in ipairs(root.icons._hits) do if h.id == id then return h.fn end end end
nowMs = nowMs + 2000
hitFn("desk:trash")(); nowMs = nowMs + 100; hitFn("desk:trash")()
check("a double-click on it opens the same view", MM.view == "trash", MM.view)
-- a left icon through A
MM.showView("main"); frame()
win.focusId = "newgame"
steps = 0
while MM.deskAt == nil and steps < 8 do joy("left"); steps = steps + 1 end
root.icons.focusId = "cletusworks"
press(Joypad.AButton)
check("A on CletusWorks opens it", OPENED[#OPENED] == "cletusworks")

-- ---------------------------------------------------------------------------
section("B closes at the top")
MM.showView("trash"); frame()
check("the Trash is up", MM.activeWindow() == root.trashWin)
press(Joypad.BButton)
check("B closes the Trash, as its close box does", MM.view == "desktop", MM.view)
MM.showView("main"); frame()
press(Joypad.BButton)
check("B on the main window does nothing", MM.view == "main" and MM.activeWindow() == win)
win:setConfirm(true)
press(Joypad.BButton)
check("B on the main window's question answers it", win.confirm == false and MM.view == "main")
-- a window with no B of its own: the rule in ZeD_MMWindow:joyB
local Plain = ZeD_MMWindow:derive("ZeD_SimPlain")
function Plain:new() return ZeD_MMWindow.new(self, "plain") end
function Plain:prerender() self._specs = {} end
local closed = 0
function Plain:close() closed = closed + 1; MM.showView("desktop") end
MM.addView("plain", "plainWin", function() return Plain:new() end)
root.plainWin = Plain:new(); root:addChild(root.plainWin)
MM.showView("plain")
check("a plain window is up", MM.activeWindow() == root.plainWin)
root.plainWin.confirm = true
press(Joypad.BButton)
check("B first answers its question", closed == 0 and root.plainWin.confirm == false)
press(Joypad.BButton)
check("then B closes it (its close)", closed == 1 and MM.view == "desktop", closed)

-- ---------------------------------------------------------------------------
section("the bare desktop: the icons are the view")
MM.showView("desktop"); frame()
check("the icons hold the controller", MM.activeWindow() == root.icons and root.icons.focusId ~= nil)
check("their mark shows", marksOn(root.icons) == 1, marksOn(root.icons))
root.icons.focusId = "pz"
joy("up")
check("Up from the top icon lands on the bar", MM.deskAt == "bar" and MM.deskBack == nil)
check("the icons' mark steps aside", marksOn(root.icons) == 0 and marksOn(root.bar) == 1)
joy("down")
check("Down returns to the icons", MM.deskAt == nil and root.icons.focusId == "pz")
joy("down")
check("Down walks the icons as before", root.icons.focusId == "newgame", root.icons.focusId)
joy("left")
check("Left off the right column with no window goes on to the left side (as before)", MM.deskAt == nil)

-- ---------------------------------------------------------------------------
section("the desk after a death, and in game")
MM.showView("main"); frame()
MM.respawn = { joypadData = {} }
local JOY = { inGame = false, respawn = true }
win.focusId = "newgame"
MM.joyDir(JOY, "up"); frame()
check("respawn: Up off the top to the bar", MM.deskAt == "bar")
MM.joyDir(JOY, "right"); frame()
check("respawn: the ZeD menu is the only title", MM.ctx.barFocus == 1 and #MM.menus() == 1)
MM.joyDown(JOY, Joypad.AButton); frame()
check("respawn: A opens it (the About block)", MM.ctx.open == "zed" and #MM.dropLive() == 0)
MM.joyDown(JOY, Joypad.BButton); frame()
check("respawn: B shuts it", MM.ctx.open == nil and MM.deskAt == "bar")
MM.joyDir(JOY, "down"); frame()
check("respawn: Down back to the window", MM.deskAt == nil)
MM.respawn = nil
local GAME = { inGame = true }
MM.joyDir(GAME, "up")
check("in game: no desk to leave to", MM.deskAt == nil)
MM.joyFocus(m)
check("the controller handed back starts in the window", MM.deskAt == nil)

print("desk_pad_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
