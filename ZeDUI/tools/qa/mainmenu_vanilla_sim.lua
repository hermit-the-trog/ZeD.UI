-- ZeDUI/tools/qa/mainmenu_vanilla_sim.lua  (Nov 7 2026, Build): VANILLA_WINDOWS_20261107.md section A and D1 with no game running.
-- The game's own screens are loaded from its install (ServerWorkshopItemScreen, BootstrapConnectPopup, ServerConnectPopup, WorldSelect,
-- ISTermsOfServiceUI), on Lua 5.1 stubs of the game's UI classes, and driven the way the game drives them (its events, its calls).
-- ZeD's side is the real files: Tokens, Tr, Atoms, Molecules, ZeD_MainMenu (the views, MM.redirect / MM.mirror, the menus), Saves,
-- Join, Options, PadGlyphs and the four new files (JoinMore, World, Terms, OptionsSub). Each flow checks which view the desk shows,
-- what the ZeD window draws (inside the window, the band's buttons and their grayed states), the controller's stops, and that every
-- answer reached the game's own function. Safe mode is checked on each: the game's screen shows and ZeD stays out.
-- It proves the routing and the sums. What it cannot prove is what the engine does: real fonts, the Steam overlay, the download
-- itself, the controller's hardware.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/mainmenu_vanilla_sim.lua
-- It prints FAIL lines and a last line "mainmenu_vanilla_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]mainmenu_vanilla_sim%.lua$", "")
local GAME = "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

do
    local f = io.open(GAME .. "client/OptionScreens/ServerWorkshopItemScreen.lua", "rb")
    if not f then print("mainmenu_vanilla_sim: the game's install is not at " .. GAME .. "; skipped"); os.exit(0) end
    f:close()
end

-- ============================================================================
-- THE GAME'S GLOBALS
-- ============================================================================
local nowMs = 1000000
function getTimestampMs() return nowMs end
function getTimestamp() return math.floor(nowMs / 1000) end
STEAM = true
function getSteamModeActive() return STEAM end
function isClient() return false end
function isServer() return false end
function isMouseButtonDown() return false end
function getMouseX() return 0 end
function getMouseY() return 0 end
function getDebug() return false end
function isDemo() return false end
function isIngameState() return false end
function isSteamOverlayEnabled() return true end
CALLS = {}
local function rec(name, ...) CALLS[#CALLS + 1] = { name = name, a = { ... } } end
local function called(name)
    for i = #CALLS, 1, -1 do if CALLS[i].name == name then return CALLS[i] end end
    return nil
end
function connectToServerStateCallback(s) rec("connectToServerStateCallback", s) end
function forceDisconnect() rec("forceDisconnect") end
function triggerEvent(name, ...) rec("triggerEvent", name, ...) end
function steamRequestServerDetails(h, p) rec("steamRequestServerDetails", h, p); return true end
function getHostByName(h) return h end
function isValidSteamID() return false end
function activateSteamOverlayToWebPage(u) rec("overlay", u) end
function openUrl(u) rec("openUrl", u) end
function backToSinglePlayer() rec("backToSinglePlayer") end
function round(n, d) local m = 10 ^ (d or 0); return math.floor(n * m + 0.5) / m end
function getTexture(path) return { path = path, getWidth = function() return 64 end, getHeight = function() return 64 end, isReady = function() return true end } end
function getSoundManager() return { playUISound = function() end, StopMusic = function() rec("StopMusic") end } end
function updateJoypadFocus() end
function setJoypadFocus() end
function getServerList() return SERVERS or {} end
function instanceof(o, name) return type(o) == "table" and o._instanceof == name end
local CORE = { tos = 0, screenW = 1280, screenH = 800 }
function getCore()
    return {
        getScreenWidth = function() return CORE.screenW end, getScreenHeight = function() return CORE.screenH end,
        getOptionFontSizeReal = function() return 1 end, getOptionControllerButtonStyleString = function() return "XBOX" end,
        getTermsOfServiceVersion = function() return CORE.tos end,
        setTermsOfServiceVersion = function(_, v) CORE.tos = v; rec("setTermsOfServiceVersion", v) end,
        saveOptions = function() rec("saveOptions") end, quitToDesktop = function() rec("quitToDesktop") end,
    }
end
UIManager = { setShowPausedMessage = function() end, getSpeedControls = function() return nil end, isModalVisible = function() return false end,
              getMillisSinceLastRender = function() return 16 end }
GameWindow = { doRenderEvent = function() end }
Keyboard = { KEY_ESCAPE = 1, KEY_RETURN = 28, KEY_UP = 200, KEY_DOWN = 208, KEY_DELETE = 211, KEY_SPACE = 57 }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5 }
PAD = nil
JoypadState = { players = {}, getMainMenuJoypad = function() return PAD end }
Translator = { getLanguage = function() return { name = function() return "EN" end } end, getAvailableLanguage = function() return nil end }
UIFont = setmetatable({}, { __index = function(_, k) return k end })
LuaEventManager = { AddEvent = function() end }
local EVENTS = setmetatable({}, { __index = function(t, k)
    local e = { list = {} }
    e.Add = function(fn) e.list[#e.list + 1] = fn end
    e.Remove = function(fn) for i = #e.list, 1, -1 do if e.list[i] == fn then table.remove(e.list, i) end end end
    rawset(t, k, e)
    return e
end })
Events = EVENTS
local function fire(name, ...) for _, fn in ipairs(Events[name].list) do fn(...) end end

-- the game's words: ZeD's file, then the game's own (as they will draw)
local TEXT = {}
local function readJson(path, into, keep)
    local f = io.open(path, "rb")
    if not f then return end
    local s = f:read("*a")
    f:close()
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\r?\n') do if not (keep and into[k]) then into[k] = v end end
end
readJson(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", TEXT)
for _, n in ipairs({ "UI.json", "IG_UI.json", "ContextMenu.json", "GameSound.json" }) do readJson(GAME .. "shared/Translate/EN/" .. n, TEXT, true) end
function getText(k, ...)
    local s = TEXT[k] or k
    local a = { ... }
    for i = 1, 4 do if a[i] ~= nil then s = string.gsub(s, "%%" .. i, (string.gsub(tostring(a[i]), "%%", "%%%%"))) end end
    return s
end
function getTextOrNull(k, ...) if TEXT[k] then return getText(k, ...) end; return nil end
function getTextManager()
    return { getFontHeight = function() return 14 end, MeasureStringX = function(_, _, s) return #tostring(s or "") * 7 end,
             getFontFromEnum = function() return { getLineHeight = function() return 14 end } end, CentreStringYOffset = function() return 0 end }
end

-- a Java list
string.trim = string.trim or function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
-- a Java list
local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end

-- ============================================================================
-- THE GAME'S UI CLASSES (enough for its screens to build and run)
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
function ISBaseObject:derive(name) local c = newClass(name, self); return c end
function ISBaseObject:new() local o = {}; setmetatable(o, self); self.__index = self; return o end
ISUIElement = ISBaseObject:derive("ISUIElement")
function ISUIElement:new(x, y, w, h)
    local o = { x = x or 0, y = y or 0, width = w or 0, height = h or 0, visible = true, children = {}, joypadButtonsY = {}, joypadButtons = {},
                joypadIndexY = 0, joypadIndex = 0, backgroundColor = { r = 0, g = 0, b = 0, a = 0 }, borderColor = { r = 1, g = 1, b = 1, a = 1 },
                backgroundColorMouseOver = { r = 0, g = 0, b = 0, a = 0 }, anchorLeft = true, anchorTop = true, enable = true }
    setmetatable(o, self)
    self.__index = self
    return o
end
local E = ISUIElement
function E:initialise() end
function E:instantiate()
    if self._inst then return end
    self._inst = true
    self.javaObject = { setMaxLines = function() end, setMaxTextLength = function() end, setCentreVertically = function() end, setRenderClippedChildren = function() end }
    if self.createChildren then self:createChildren() end
end
function E:addChild(c) c.parent = self; self.children[#self.children + 1] = c; if not c._inst then c:instantiate() end; return c end
function E:removeChild(c) for i = #self.children, 1, -1 do if self.children[i] == c then table.remove(self.children, i) end end end
function E:getChildren() return self.children end
function E:clearChildren() self.children = {} end
UIMANAGER = {}
function E:addToUIManager() self:instantiate(); UIMANAGER[self] = true end
function E:removeFromUIManager() UIMANAGER[self] = nil end
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
function E:getRight() return self.x + self.width end
function E:getBottom() return self.y + self.height end
function E:getAbsoluteX() return self.x + (self.parent and self.parent:getAbsoluteX() or 0) end
function E:getAbsoluteY() return self.y + (self.parent and self.parent:getAbsoluteY() or 0) end
function E:getMouseX() return 0 end
function E:getMouseY() return 0 end
function E:isMouseOver() return false end
for _, n in ipairs({ "setAnchorLeft", "setAnchorRight", "setAnchorTop", "setAnchorBottom", "setAnchorsTBLR", "setAlwaysOnTop", "bringToTop",
                     "insertNewLineOfButtons", "setISButtonForA", "setISButtonForB", "clearJoypadButton", "setTooltip", "setValid", "setOnlyText",
                     "setMaxTextLength", "setJoypadFocused", "restoreJoypadFocus", "clearJoypadFocus", "setScrollChildren", "addScrollBars",
                     "setScrollHeight", "setMargins", "paginate", "setFont", "setOnMouseDownFunction", "setOnMouseDoubleClick",
                     "drawRectBorder", "drawTexture", "drawTextureScaled", "drawTextureScaledAspect", "drawTextCentre", "drawProgressBar",
                     "setStencilRect", "clearStencilRect", "enableCancelColor", "enableAcceptColor", "setColor", "setCentreVertically",
                     "autoGenerateJoypadButtonsLists", "setWantMouseEvents", "doLayout", "unfocus" }) do
    E[n] = E[n] or function() end
end
function E:prerender() end
function E:createChildren() end
function E:render() end
function E:update() end
function E:onGainJoypadFocus(jd) self.joyfocus = jd end
function E:onLoseJoypadFocus() self.joyfocus = nil end
function E:noBackground() return self end
function E:setEnable(v) self.enable = v and true or false end
function E:isEnabled() return self.enable end
function E:setTitle(t) self.title = t end
function E:getTitle() return self.title end
function E:setName(n) self.name = n end
function E:getName() return self.name end
function E:drawRect(x, y, w, h, a, r, g, b) DRAWN[#DRAWN + 1] = { p = self, kind = "rect", x = x, y = y, w = w, h = h, a = a } end
function E:drawText(text, x, y) DRAWN[#DRAWN + 1] = { p = self, kind = "text", text = tostring(text), x = x, y = y } end
function E:derive(name) local c = newClass(name, self); return c end
ISPanel = E:derive("ISPanel")
ISPanelJoypad = ISPanel:derive("ISPanelJoypad")
function ISPanelJoypad:onJoypadDown() end
ISLabel = ISPanel:derive("ISLabel")
function ISLabel:new(x, y, h, name, r, g, b, a, font, left)
    local o = ISPanel.new(self, x, y, #tostring(name or "") * 7, h)
    o.name = name
    o.font = font
    return o
end
ISButton = ISPanel:derive("ISButton")
function ISButton:new(x, y, w, h, title, target, onclick)
    local o = ISPanel.new(self, x, y, w, h)
    o.title, o.target, o.onclick = title, target, onclick
    return o
end
function ISButton:setWidthToTitle() end
function ISButton:forceClick() if self.onclick then self.onclick(self.target, self) end end
ISTextEntryBox = ISPanel:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, w, h) local o = ISPanel.new(self, x, y, w, h); o.text = text or ""; return o end
function ISTextEntryBox:setText(s) self.text = s end
-- (a masked box gives its mask from getText, as the game's UITextBox2 does: the real words only from getInternalText)
function ISTextEntryBox:getText() if self.masked then return string.rep("*", #(self.text or "")) end; return self.text end
function ISTextEntryBox:getInternalText() return self.text end
function ISTextEntryBox:setMasked(m) self.masked = m end
function ISTextEntryBox:focus() self.hasFocus = true end
function ISTextEntryBox:unfocus() self.hasFocus = false end
function ISTextEntryBox:isFocused() return self.hasFocus == true end
ISTickBox = ISPanel:derive("ISTickBox")
function ISTickBox:new(x, y, w, h, name) local o = ISPanel.new(self, x, y, w, h); o.options = {}; o.selected = {}; return o end
function ISTickBox:addOption(name, data) self.options[#self.options + 1] = name; return #self.options end
ISScrollingListBox = ISPanel:derive("ISScrollingListBox")
function ISScrollingListBox:new(x, y, w, h) local o = ISPanel.new(self, x, y, w, h); o.items = {}; o.selected = 1; return o end
function ISScrollingListBox:clear() self.items = {}; self.selected = 1 end
function ISScrollingListBox:addItem(text, item) self.items[#self.items + 1] = { text = text, item = item, index = #self.items + 1, height = 20 }; return self.items[#self.items] end
function ISScrollingListBox:sort() table.sort(self.items, function(a, b) return tostring(a.text) < tostring(b.text) end) end
ISSliderPanel = ISPanel:derive("ISSliderPanel")
function ISSliderPanel:new(x, y, w, h) local o = ISPanel.new(self, x, y, w, h); o.cv = 0; return o end
function ISSliderPanel:setValues() end
function ISSliderPanel:setCurrentValue(v) self.cv = v end
function ISSliderPanel:getCurrentValue() return self.cv end
ISRichTextPanel = ISPanel:derive("ISRichTextPanel")
function ISRichTextPanel:new(x, y, w, h) local o = ISPanel.new(self, x, y, w, h); o.text = ""; return o end
ISComboBox = ISPanel:derive("ISComboBox")
function ISComboBox:new(x, y, w, h, target, onChange) local o = ISPanel.new(self, x, y, w, h); o.options = {}; o.selected = 0; o.target = target; o.onChange = onChange; return o end
function ISComboBox:clear() self.options = {}; self.selected = 0 end
function ISComboBox:addOptionWithData(t, d) self.options[#self.options + 1] = { text = t, data = d }; if self.selected == 0 then self.selected = 1 end end
function ISComboBox:addOption(t) self:addOptionWithData(t, nil) end
function ISComboBox:getOptionText(i) local o = self.options[i]; return o and o.text end
function ISComboBox:getOptionData(i) local o = self.options[i]; return o and o.data end

-- the classes ZeD's files name from the game, as plain stand-ins
ModSelector = { instance = nil }
NewGameScreen = { clickPlay = function() rec("NewGameScreen.clickPlay") end }
MainOptions = { loadKeys = function() end }
function MainOptions.onGameSounds(self) rec("vanilla onGameSounds") end
MainScreen = { onMenuItemMouseDownMainMenu = function() end, resetLuaIfNeeded = function() end }
ISTermsOfServiceUI = nil   -- (the game's file defines it)
ConnectToServer = {}
CoopOptionsScreen = { instance = nil }
MapSpawnSelect = { instance = nil }
LoadGameScreen = { instance = nil }
WorldGenParams = { INSTANCE = setmetatable({}, { __index = function(_, k) return function(_, ...) rec("WorldGenParams." .. k, ...) end end }) }
WorldGenUtils = { INSTANCE = { generateSeed = function() return "seed1993" end } }
IgnoredMap = nil
MAPINFO = {}
function getMapInfo(dir) return MAPINFO[dir] end
GROUPS = {}
MapGroups = { new = function()
    return { createGroups = function() end, getNumberOfGroups = function() return #GROUPS end,
             getMapDirectoriesInGroup = function(_, i) return jlist(GROUPS[i + 1] or {}) end,
             setWorld = function(_, i) rec("MapGroups.setWorld", i) end }
end }
function getWorld() return { getGameMode = function() return "Sandbox" end } end

-- ============================================================================
-- THE FILES
-- ============================================================================
local LOADED = {}
local STUBBED = { ["ZeD/Organisms"] = true, ["ZeD/MenuNote"] = true, ["ZeD/ZeD_MouseTick"] = true, ["ZeD/SafeMode"] = true }
local GAME_FILES = { ["OptionScreens/ServerWorkshopItemScreen"] = true, ["OptionScreens/BootstrapConnectPopup"] = true,
                     ["OptionScreens/ServerConnectPopup"] = true, ["OptionScreens/WorldSelect"] = true, ["ISUI/ISTermsOfServiceUI"] = true }
function require(name)
    if LOADED[name] then return end
    LOADED[name] = true
    if GAME_FILES[name] then
        local fn = assert(loadfile(GAME .. "client/" .. name .. ".lua"))
        fn()
        return
    end
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
ZeD.TM = {
    MeasureStringX = function(_, font, s) return math.ceil(#tostring(s) * fontPx(font) * ZeD.T.root * 0.60) end,
    MeasureStringY = function(_, font, s) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
    getFontHeight = function(_, font) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
}
ZeD.Scale = { root = function() return ZEDQA_ROOT or 1 end }
ZeD.Help = { set = function(_, s) ZeD.Help.last = s end }
SAFE = false
ZeD.Safe = { on = function() return SAFE end, register = function() end }
ZeD.Surface = { fill = function(p, x, y, w, h) p:drawRect(x, y, w, h, 1, 0, 0, 0) end }
ZeD.Focus = { mark = function() ZEDQA_MARKS = (ZEDQA_MARKS or 0) + 1; return true end }
ZeD.MouseTick = { down = function() return false end }
ZeD.Font = { sdf = { head = { face = 64 } } }
ZeD.Text = {
    draw = function(p, face, s, x, y) p:drawText(s, x, y) end,
    width = function(face, s, z) return #tostring(s) * 32 * z end,
    height = function(face, z) return 64 * z end,
    fitEntry = function() end, entryFont = function() return "Small" end,
}
ZeD.btnCase = function(s) return s end

-- ZeD's window frame (Organisms.lua) as a stand-in: the frame draws nothing here
ZeD_Window = ISPanel:derive("ZeD_Window")
function ZeD_Window:new(x, y, w, h, title) local o = ISPanel.new(self, x, y, w, h); o.title = title; return o end
function ZeD_Window:createChildren() end
function ZeD_Window:prerender() end
function ZeD_Window:render() end
function ZeD_Window:update() end
function ZeD_Window:footerHeight() return ZeD.T.px(22) end

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
ZeD.applyTheme("dark", "orange", "small")
ZeD.Atoms.drawPxIcon = function(p, id, x, y, box) p:drawRect(x, y, box, box, 1, 1, 1, 1) end

-- the game's files ZeD's views stand in for (loaded before ZeD's, as the game does)
require "OptionScreens/ServerWorkshopItemScreen"
require "OptionScreens/BootstrapConnectPopup"
require "OptionScreens/ServerConnectPopup"
require "OptionScreens/WorldSelect"
require "ISUI/ISTermsOfServiceUI"
check("the game's files load", ServerWorkshopItemScreen and BootstrapConnectPopup and ServerConnectPopup and WorldSelect and ISTermsOfServiceUI)
local vanillaTermsHandler = ISTermsOfServiceUI.OnGameStateEnter

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuJoin"
require "ZeD/ZeD_MainMenuOptions"
-- the four files this pass added (before them none of this was ZeD's: each missing one is a failure, and the run stops)
for _, n in ipairs({ "ZeD/ZeD_MainMenuJoinMore", "ZeD/ZeD_MainMenuWorld", "ZeD/ZeD_MainMenuTerms", "ZeD/ZeD_MainMenuOptionsSub" }) do
    local ok, err = pcall(require, n)
    check("loads " .. n, ok, err)
end
if failed > 0 then print("mainmenu_vanilla_sim: " .. checks .. " checks, " .. failed .. " failed"); os.exit(1) end
local MM = ZeD.MainMenu
check("ZeD's files load", MM and MM.views and ZeD_MMOptions)
-- the monitor: Deck size unless a pass says otherwise
local LAY = { sw = 1280, sh = 800, tx = 160, ty = 40, tw = 960, th = 720, ox = 0, oy = 0, s = 2 }
MM.layout = function() return LAY end

-- ============================================================================
-- THE MAIN SCREEN, AS THE GAME BUILDS IT
-- ============================================================================
local function stubScreen(name)
    local s = ISPanel:new(0, 0, 1280, 800)
    s.Type = name
    s.setVisible = function(self, v, jd) self.visible = v and true or false; rec(name .. ".setVisible", v) end
    return s
end
local m = {}
MainScreen.instance = m
m.inGame, m.delay = false, 0
m.bottomPanel = ISPanel:new(0, 0, 100, 100)
m.onClickTermsOfService = function() rec("vanilla onClickTermsOfService") end
m.onTermsOfServiceOK = function() rec("onTermsOfServiceOK") end
-- the connecting screen (ConnectToServer, a stand-in): shown while it follows a connection
local cts = stubScreen("ConnectToServer")
cts.connect = function(self, prev, serverName, user, pwd, ip, localIP, port, srvPwd, relay, doHash, auth)
    rec("ConnectToServer.connect", user, pwd, ip, port, srvPwd, relay)
    prev:setVisible(false)
    self:setVisible(true)
end
cts.connectLabel = { name = "" }
cts.backBtn = ISButton:new(0, 0, 10, 10, "ABORT")
ConnectToServer.instance = cts
m.connectToServer = cts
local coop = stubScreen("CoopOptionsScreen")
CoopOptionsScreen.instance = coop
m.onlineCoopScreen = coop
m.soloScreen = stubScreen("NewGameScreen")
m.sandOptions = stubScreen("SandboxOptionsScreen")
MapSpawnSelect.instance = stubScreen("MapSpawnSelect")
MapSpawnSelect.instance.hasChoices = function() return true end
MapSpawnSelect.instance.fillList = function() rec("MapSpawnSelect.fillList") end
m.mapSpawnSelect = MapSpawnSelect.instance
local function build(cls)
    local s = cls:new(0, 0, 1280, 800)
    s:initialise()
    s:setVisible(false)
    if s.create then s:create() end
    return s
end
m.serverWorkshopItem = build(ServerWorkshopItemScreen)
m.bootstrapConnectPopup = build(BootstrapConnectPopup)
m.serverConnectPopup = build(ServerConnectPopup)
m.worldSelect = build(WorldSelect)

-- the desk (MM.attach's main-menu half, without the desk's own drawing): each view's window, then vanilla's
-- screens redirected or mirrored exactly as MM.attach does it
local W = {}
local function attach()
    MM.root = { isVisible = function() return true end, win = { confirm = false } }   -- (win: the main window, no Y of its own)
    for _, v in ipairs(MM.views) do
        local w = v.make()
        w:initialise()
        w:instantiate()
        MM.root[v.field] = w
        W[v.view] = w
    end
    MM.view = "main"
    for _, v in ipairs(MM.views) do
        if v.screen then if v.mirror then MM.mirror(m[v.screen], v.view, v.mirror) else MM.redirect(m[v.screen], v.view) end end
    end
    MM.redirect(m.soloScreen, "newgame")
end
attach()
do   -- (MM.attach must hand each view's mirror field to MM.mirror: the Workshop items' keep rides on it)
    local f = io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenu.lua", "rb")
    local src = f:read("*a")
    f:close()
    check("MM.attach passes the view's mirror field on", src:find("MM.mirror(m[v.screen], v.view, v.mirror)", 1, true) ~= nil)
end
check("A1 the Workshop items view is registered on the game's screen", W.wsitems ~= nil and m.serverWorkshopItem._zedRedirect == true)
check("A2 the invite view is registered", W.bootstrap ~= nil and m.bootstrapConnectPopup._zedRedirect == true)
check("A2 the connect-to view is registered", W.srvform ~= nil and m.serverConnectPopup._zedRedirect == true)
check("A3 the world select view is registered", W.world ~= nil and m.worldSelect._zedRedirect == true)
check("A4 the terms view is registered", W.terms ~= nil)

-- ============================================================================
-- DRAWING A WINDOW: everything it drew inside it, the band, the controller's stops
-- ============================================================================
local function draw(w, label)
    DRAWN = {}
    w:prerender()
    w:render()
    local out = 0
    for _, d in ipairs(DRAWN) do
        if d.p == w and d.kind == "text" then
            if d.x < 0 or d.y < 0 or d.x >= w.width or d.y >= w.height then out = out + 1; if out == 1 then print("  (" .. label .. ": '" .. d.text .. "' at " .. d.x .. "," .. d.y .. " in " .. w.width .. "x" .. w.height .. ")") end end
        end
    end
    check(label .. ": every word inside the window", out == 0, out)
    -- every stop unique, every band button whole
    local seen, dup = {}, nil
    for _, s in ipairs(w._specs or {}) do if seen[s.id] then dup = s.id end; seen[s.id] = true end
    check(label .. ": the controller's stops are unique", dup == nil, dup)
    return DRAWN
end
local function texts(list)
    local t = {}
    for _, d in ipairs(list or DRAWN) do if d.kind == "text" then t[#t + 1] = d.text end end
    return table.concat(t, "\n")
end
local function band(w, id)
    for _, s in ipairs(w._specs or {}) do if s.band and s.id == id then return s end end
    return nil
end
local function stop(w, id)
    for _, s in ipairs(w._specs or {}) do if s.id == id then return s end end
    return nil
end
local function pressBand(w, id)
    local b = band(w, id)
    if not b then return false end
    if b.disabled then return false end
    b.fn()
    return true
end

-- ============================================================================
-- A1: THE SERVER'S WORKSHOP ITEMS
-- ============================================================================
local ws = m.serverWorkshopItem
local function details(id, title, size, state)
    return { getIDString = function() return id end, getTitle = function() return title end, getFileSize = function() return size end,
             getState = function() return state end }
end
local function wsRun(fromCoop)
    CALLS = {}
    MM.view = "main"
    ws:setVisible(false)
    if fromCoop then coop:setVisible(true); cts:setVisible(false) else cts:setVisible(true) end
    if not fromCoop then check("A1 joining shows Connecting", MM.view == "connect", MM.view) end
    fire("OnServerWorkshopItems", "Required", jlist({ "2503622437", "2804531012" }))
    check("A1 the game's Required lands on the Workshop items view", MM.view == "wsitems", MM.view)
    check("A1 the game's screen stays shown, off the screen", ws:isVisible() and ws:getX() <= -10000, ws:getX())
    W.wsitems:onShow()
end
wsRun(false)
local wi = W.wsitems
draw(wi, "A1 waiting for details")
check("A1 each mod by its Workshop ID until Steam has its details", texts():find("2503622437", 1, true) ~= nil)
check("A1 Install grayed until the details come", band(wi, "install") and band(wi, "install").disabled == true)
check("A1 Disconnect in the band", band(wi, "disconnect") ~= nil and band(wi, "disconnect").text == ZeD.btnCase(getText("UI_btn_disconnect")))
fire("OnServerWorkshopItems", "Details", jlist({ details("2503622437", "Skill Recovery Journal", 3 * 1024 * 1024, "NotSubscribed"),
                                                 details("2804531012", "Draw On The Map", 1024 * 1024, "Downloading") }))
fire("OnServerWorkshopItems", "Progress", "2804531012", 512 * 1024, 1024 * 1024)
local rows = MM.wsItemRows(ws)
check("A1 the rows read the game's list", #rows == 2 and rows[1].title == "Skill Recovery Journal" and rows[2].frac == 0.5, rows[2] and rows[2].frac)
draw(wi, "A1 details in")
local tx = texts()
check("A1 the mods' names and states drawn", tx:find("Skill Recovery Journal", 1, true) and tx:find(getText("UI_WorkshopServerItemState_NotSubscribed"), 1, true))
check("A1 a download's progress drawn", tx:find(ZeD.tr("UI_ZeD_WsItems_Progress", 0.5, 1), 1, true) ~= nil)
check("A1 Install live once the details came", band(wi, "install") and not band(wi, "install").disabled)
-- the controller: it lands on Install (vanilla's A); up walks the mods, down comes back to the band; A on a mod does nothing
check("A1 pad: lands on Install once it is live", wi.focusId == "install", wi.focusId)
wi:joyDir("up")
check("A1 pad: up reaches a mod", wi.focusId == "ws:2503622437" or wi.focusId == "ws:2804531012", wi.focusId)
local before = #CALLS
wi:joyA()
check("A1 pad: A on a mod does nothing", #CALLS == before)
for _ = 1, 4 do wi:joyDir("down") end
check("A1 pad: down reaches the band", wi.focusId == "install" or wi.focusId == "disconnect", wi.focusId)
check("A1 footer prompts name Install and Disconnect", (function()
    MM.forceGamepad = true
    local p = wi:getFooterPrompts()
    MM.forceGamepad = false
    return p and #p == 2
end)())
pressBand(wi, "install")
check("A1 Install runs the game's own (its callback)", called("connectToServerStateCallback") and called("connectToServerStateCallback").a[1] == "install")
check("A1 Install grays once pressed", ws.installButton.enable == false)
-- success: the connection goes on, and the Connecting view follows it again
fire("OnServerWorkshopItems", "Success")
check("A1 success: the Connecting view again (the game showed nothing)", MM.view == "connect" and cts:isVisible(), MM.view)
check("A1 success: the game's screen back where it was", ws:getX() > -10000)
-- Disconnect: the game's own, back to the screen it came from
wsRun(false)
wi:disconnect()
check("A1 Disconnect runs the game's own", called("connectToServerStateCallback") and called("connectToServerStateCallback").a[1] == "disconnect")
check("A1 Disconnect lands on the screen it came from", MM.view == "connect", MM.view)
-- from Host a Game: success keeps the view, contacting the server
wsRun(true)
fire("OnServerWorkshopItems", "Success")
check("A1 from Host, success keeps the view", MM.view == "wsitems" and wi.done == true, MM.view)
draw(wi, "A1 contacting")
check("A1 contacting: the status words, Install gone", texts():find(getText("UI_servers_Connecting"), 1, true) ~= nil and band(wi, "install") == nil)
-- an error from Steam: its words with a red square, Install grayed
wsRun(false)
fire("OnServerWorkshopItems", "Details", jlist({ details("2503622437", "Skill Recovery Journal", 1024, "NotSubscribed") }))
fire("OnServerWorkshopItems", "Error", "2503622437", "DownloadItemFalse")
local note, isErr = MM.wsItemsNote(ws)
check("A1 an error shows the game's words", isErr and note == getText("UI_ServerWorkshopItemError_DownloadItemFalse"), note)
draw(wi, "A1 error")
check("A1 an error grays Install", band(wi, "install").disabled == true)
-- at 4K
LAY = { sw = 3840, sh = 2160, tx = 480, ty = 120, tw = 2880, th = 2160, ox = 0, oy = 0, s = 6 }
ZEDQA_ROOT = 1.75
ZeD.applyTheme("dark", "orange", "small")
draw(wi, "A1 4K")
ZEDQA_ROOT = 1
ZeD.applyTheme("dark", "orange", "small")
LAY = { sw = 1280, sh = 800, tx = 160, ty = 40, tw = 960, th = 720, ox = 0, oy = 0, s = 2 }
wi:disconnect()

-- ============================================================================
-- A2: THE INVITE, AND CONNECT TO
-- ============================================================================
local bp, sp = m.bootstrapConnectPopup, m.serverConnectPopup
CALLS = {}
MM.view = "main"
bp:connect("10.0.0.5", "16261", "")
check("A2 a Steam invite lands on the invite view", MM.view == "bootstrap" and bp:getX() <= -10000, MM.view)
draw(W.bootstrap, "A2 invite asking")
check("A2 the address and the game's words", texts():find("10.0.0.5 : 16261", 1, true) and texts():find(getText("UI_servers_Connecting"), 1, true))
check("A2 Cancel while it asks", band(W.bootstrap, "back") and band(W.bootstrap, "back").text == ZeD.btnCase(getText("UI_Cancel")))
-- Steam fails to answer: Back
bp:OnSteamServerFailedToRespond2("10.0.0.5", 16261)
draw(W.bootstrap, "A2 invite failed")
check("A2 failed: the game's reason and Back", texts():find(getText("UI_servers_ServerFailedToRespond"), 1, true) and band(W.bootstrap, "back").text == ZeD.btnCase(getText("UI_btn_back")))
pressBand(W.bootstrap, "back")
check("A2 Back: the menu again", MM.view == "main" and m.bottomPanel:isVisible())
-- Steam answers, a dedicated server: the connect-to form
bp:connect("10.0.0.5", "16261", "hunter2")
SERVERS = { { getIp = function() return "10.0.0.5" end, getPort = function() return "16261" end, getServerPassword = function() return "" end,
              getUserName = function() return "Aretha" end, getPwd = function() return "pw" end, getUseSteamRelay = function() return true end } }
bp:OnSteamServerResponded2("10.0.0.5", 16261, { isHosted = function() return false end })
check("A2 the server answered: the connect-to view", MM.view == "srvform" and sp:getX() <= -10000, MM.view)
local sf = W.srvform
check("A2 the form starts with the game's fields", sf.fUser:getText() == "Aretha" and sf.fSrvPwd:getInternalText() == "hunter2" and sf.relay == true,
      sf.fUser:getText() .. "/" .. sf.fSrvPwd:getInternalText())
draw(sf, "A2 connect to")
check("A2 Connect live with an account", band(sf, "connect") and not band(sf, "connect").disabled)
check("A2 Cancel in the band", band(sf, "cancel") ~= nil)
check("A2 the fields are controller stops", stop(sf, "field:1") and stop(sf, "field:2") and stop(sf, "field:3") and stop(sf, "relay"))
check("A2 pad: lands on Connect", sf.focusId == "connect", sf.focusId)
sf.fUser:setText("  ")
draw(sf, "A2 no account")
check("A2 no account: Connect grayed with the game's reason", band(sf, "connect").disabled and texts():find(getText("UI_servers_err_username"), 1, true))
sf.fUser:setText("Kate")
sf.fPwd:setText("secret")
sf.relay = false
draw(sf, "A2 account typed")
check("A2 the masked fields hold their real words", sf.fPwd:getText() ~= "secret" and sf.fPwd:getInternalText() == "secret")
pressBand(sf, "connect")
local cc = called("ConnectToServer.connect")
check("A2 Connect runs the game's own with ZeD's fields", cc and cc.a[1] == "Kate" and cc.a[2] == "secret" and cc.a[3] == "10.0.0.5" and cc.a[5] == "hunter2" and cc.a[6] == false,
      cc and table.concat({ tostring(cc.a[1]), tostring(cc.a[2]), tostring(cc.a[5]), tostring(cc.a[6]) }, ","))
check("A2 Connect: the Connecting view", MM.view == "connect", MM.view)
cts:setVisible(false)
-- the non-Steam command line: the form at once, and Cancel
STEAM = false
MM.view = "main"
bp:connect("10.0.0.6", "16262", nil)
check("A2 a +connect launch without Steam: the connect-to view", MM.view == "srvform", MM.view)
pressBand(sf, "cancel")
check("A2 Cancel: the menu again", MM.view == "main" and m.bottomPanel:isVisible(), MM.view)
STEAM = true

-- ============================================================================
-- A3: WORLD SELECT
-- ============================================================================
GROUPS = { { "Muldraugh, KY", "Riverside, KY" }, { "Raven Creek" }, { "Fort Rock", "Fort Rock Ext" } }
MAPINFO = { ["Muldraugh, KY"] = { title = "Muldraugh, KY", description = "The Knox Country." }, ["Riverside, KY"] = { title = "Riverside, KY" },
            ["Raven Creek"] = { title = "Raven Creek", description = "A city by the river." }, ["Fort Rock"] = { title = "Fort Rock" }, ["Fort Rock Ext"] = { title = "Fort Rock (more)" } }
local wsel = m.worldSelect
CALLS = {}
MM.view = "newgame"
check("A3 vanilla says there is a choice", wsel:hasChoices())
wsel:fillList()
wsel.previousScreen = "NewGameScreen"
wsel:setVisible(true)
check("A3 New Game's world step lands on the monitor", MM.view == "world" and not wsel:isVisible(), MM.view)
local ww = W.world
ww:onShow()
local cards = ww:cards()
check("A3 a card per map group", #cards == 3 and cards[2].name == "Raven Creek" and #cards[1].maps == 2, #cards)
draw(ww, "A3 worlds")
check("A3 the cards and the chosen world's maps drawn", texts():find("Raven Creek", 1, true) and texts():find("The Knox Country.", 1, true))
check("A3 Back and Next in the band", band(ww, "back") and band(ww, "next") and not band(ww, "next").disabled)
ww.focusId = "world:1"
ww:joyDir("down")
check("A3 pad: down picks the next world", ww.sel == 2 and wsel.listbox.selected == 2, ww.sel)
pressBand(ww, "next")
local sw = called("MapGroups.setWorld")
check("A3 Next runs the game's own with the chosen world", sw and sw.a[1] == 1, sw and sw.a[1])
check("A3 Next goes on to map / spawn", called("MapSpawnSelect.setVisible") ~= nil)
-- Back: New Game on the monitor
MM.view = "world"
wsel.previousScreen = "NewGameScreen"
ww:back()
check("A3 Back: New Game on the monitor", MM.view == "newgame", MM.view)
-- Y on a step with no Y of its own stays there (the main window's Y is Legal; it used to fire on every view)
MM.view, MM.ctx.open = "world", nil
MM.joyDown(m, Joypad.YButton)
check("A3 Y on the world step does not leave it for the terms", MM.view == "world", MM.view)
MM.view = "main"
MM.joyDown(m, Joypad.YButton)
check("A4 Y on the main window opens the terms", MM.view == "terms", MM.view)
MM.view = "world"
-- at 4K
LAY = { sw = 3840, sh = 2160, tx = 480, ty = 120, tw = 2880, th = 2160, ox = 0, oy = 0, s = 6 }
draw(ww, "A3 4K")
LAY = { sw = 1280, sh = 800, tx = 160, ty = 40, tw = 960, th = 720, ox = 0, oy = 0, s = 2 }

-- ============================================================================
-- A4: TERMS OF SERVICE
-- ============================================================================
CALLS = {}
MM.view = "main"
MM.act.tos()
check("A4 the ZeD menu's Terms of service: the ZeD window", MM.view == "terms" and called("vanilla onClickTermsOfService") == nil, MM.view)
local tw = W.terms
tw:onShow()
draw(tw, "A4 terms")
check("A4 the game's words drawn", texts():find("Greetings doomed survivor", 1, true) ~= nil)
check("A4 Accept, the two pages and Quit in the band", band(tw, "accept") and band(tw, "terms") and band(tw, "privacy") and band(tw, "quit"))
check("A4 Accept is the main button, last", (function() local last; for _, s in ipairs(tw._specs) do if s.band then last = s end end; return last and last.id == "accept" and last.variant == "primary" end)())
pressBand(tw, "terms")
check("A4 View terms: the game's own (the Steam overlay)", called("overlay") ~= nil)
pressBand(tw, "accept")
check("A4 Accept: the game's own (its version, the options saved)", called("setTermsOfServiceVersion") and called("saveOptions") and called("onTermsOfServiceOK"))
check("A4 Accept: back to the menu", MM.view == "main", MM.view)
-- B on the monitor: back without an answer
MM.act.tos(); tw:joyB()
check("A4 B leaves the terms", MM.view == "main")
-- the first run: the game's start-up state
CORE.tos = 0
CALLS = {}
local state = { _instanceof = "TermsOfServiceState", fromLua0 = function(_, s) rec("state." .. s) end }
local handlers = Events.OnGameStateEnter.list
local vanillaStill = false
for _, fn in ipairs(handlers) do if fn == vanillaTermsHandler then vanillaStill = true end end
check("A4 the game's own start-up handler is swapped for ZeD's", not vanillaStill and #handlers >= 1)
fire("OnGameStateEnter", state)
local bw = MM.termsBootWin
check("A4 first run: ZeD's window, on its own", bw ~= nil and ISTermsOfServiceUI.instance == bw and UIMANAGER[bw] == true)
check("A4 first run: the game's window never shows", (function() for el in pairs(UIMANAGER) do if el ~= bw and el.Type == "ISTermsOfServiceUI" then return false end end; return true end)())
draw(bw, "A4 first run")
check("A4 first run: no Back", band(bw, "back") == nil and band(bw, "accept") ~= nil)
check("A4 first run: the pad lands on View terms, never on Accept", bw.focusId == "terms", bw.focusId)
CALLS = {}
bw:onJoypadDown(Joypad.AButton)
check("A4 first run: A there opens the terms, accepts nothing", called("overlay") ~= nil and called("setTermsOfServiceVersion") == nil and UIMANAGER[bw] == true)
bw.focusId = "accept"   -- (the player moves to Accept)
bw:onJoypadDown(Joypad.AButton)
check("A4 first run: A accepts, the state goes on", called("state.exit") ~= nil and called("setTermsOfServiceVersion") ~= nil and UIMANAGER[bw] == nil)
-- accepted already: nothing shows
CALLS = {}
MM.termsBootWin = nil
fire("OnGameStateEnter", state)
check("A4 accepted before: straight on, no window", called("state.exit") ~= nil and MM.termsBootWin == nil)
-- safe mode: the game's own window
CORE.tos = 0
SAFE = true
CALLS = {}
fire("OnGameStateEnter", state)
check("A4 safe mode: the game's own window", MM.termsBootWin == nil and ISTermsOfServiceUI.instance and ISTermsOfServiceUI.instance.Type == "ISTermsOfServiceUI")
SAFE = false

-- ============================================================================
-- D1: THE TUTORIAL, LABELED AS THE GAME'S OWN
-- ============================================================================
local file = MM.menuItems("file")
local found = false
for _, it in ipairs(file) do if type(it) == "table" and it.text == ZeD.tr("UI_ZeD_MainMenu_TutorialVanilla") and it.fn == MM.act.tutorial then found = true end end
check("D1 File menu: the Tutorial as the game's own, without mods", found)
check("D1 the label says it runs without mods", ZeD.tr("UI_ZeD_MainMenu_TutorialVanilla"):find("without mods", 1, true) ~= nil)

-- ============================================================================
-- A5 + A6: THE OPTIONS SUB-PAGES
-- ============================================================================
-- the controller's parts and the game's bindings (a stand-in for the Java enums)
local PRESSED = {}
local function enum(name, kind)
    local e = { name = name, kind = kind }
    setmetatable(e, { __tostring = function() return name end })
    e.getNameTranslationKey = function() return "UI_Joypad_" .. name end
    e.isDown = function(_, c) return PRESSED[name] == true end
    e.getValue = function() return PRESSED[name] and 1 or -1 end
    e.getValueX = function() return PRESSED[name .. "X"] or 0 end
    e.getValueY = function() return 0 end
    return e
end
local BTN = {}
for _, n in ipairs({ "A", "B", "X", "Y", "LeftStick", "RightStick", "LeftBump", "RightBump", "Back", "Start", "Guide", "DPadLeft", "DPadRight", "DPadUp", "DPadDown" }) do BTN[#BTN + 1] = enum(n, "b"); BTN[n] = BTN[#BTN] end
JoypadButton = { getButtons = function() local t = {}; for i = 1, 15 do t[i] = BTN[i] end; return t end, Guide = BTN.Guide, A = BTN.A, Y = BTN.Y }
local AX1 = { enum("LeftTrigger", "a1"), enum("RightTrigger", "a1"), enum("LeftStickX", "a1"), enum("LeftStickY", "a1"), enum("RightStickX", "a1"), enum("RightStickY", "a1") }
JoypadAxis1d = { getAxes = function() return AX1 end }
local AX2 = { enum("LeftStick", "a2"), enum("RightStick", "a2") }
JoypadAxis2d = { getAxes = function() return AX2 end }
local BOUND = {}   -- binding name -> set of element tables
local function binding(name)
    local b = { name = name }
    b.getNameTranslationKey = function() return "UI_Bind_" .. name end
    b.containsBinding = function(_, el) return BOUND[name] and BOUND[name][el] == true end
    b.addBinding = function(_, el) BOUND[name] = BOUND[name] or {}; BOUND[name][el] = true; rec("addBinding", name, tostring(el)) end
    b.removeBinding = function(_, el) if BOUND[name] then BOUND[name][el] = nil end; rec("removeBinding", name, tostring(el)) end
    b.isAxisMaxThresholdInfinity = function() return true end
    b.getAxisMinThreshold = function() return 0.5 end
    return b
end
local BINDS = { binding("Interact"), binding("Run"), binding("Aim") }
BOUND.Interact = { [BTN.A] = true }
BOUND.Aim = { [AX1[1]] = true }
CharacterJoypadButtonBinding = {
    allBindings = function() return BINDS end,
    findBindings = function(el) local t = {}; for _, b in ipairs(BINDS) do if BOUND[b.name] and BOUND[b.name][el] then t[#t + 1] = b end end; return t end,
}
local MOVE = { name = "Movement", getNameTranslationKey = function() return "UI_Bind_Movement" end }
MOVE.getBinding = function() return MOVE.on end
MOVE.setBinding = function(_, el) MOVE.on = el; rec("setBinding2d", tostring(el)) end
MOVE.removeBinding = function(_, el) MOVE.on = nil; rec("removeBinding2d", tostring(el)) end
MOVE.on = AX2[1]
CharacterJoypadAxis2dBinding = {
    allBindings = function() return { MOVE } end,
    findBindings = function(el) if MOVE.on == el then return { MOVE } end; return {} end,
}
TEXT.UI_Joypad_A, TEXT.UI_Bind_Interact, TEXT.UI_Bind_Aim, TEXT.UI_Bind_Run, TEXT.UI_Bind_Movement = "A button", "Interact", "Aim", "Run", "Movement"
-- vanilla's controller page: its bindings editor (the hand-off after an edit) and its test panel's pick
local testPanel = { selectedController = nil }
local combo = ISComboBox:new(0, 0, 100, 20, testPanel, function(self, c)
    rec("onControllerSelected", c.selected)
    local d = c:getOptionData(c.selected)
    self.selectedController = (d and d >= 0) and d or nil
    JoypadState.controllerTest = self.selectedController ~= nil
end)
combo:addOptionWithData("<None>", -1)
combo:addOptionWithData("Xbox Controller", 0)
testPanel.combo = combo
local tab = { controllerTestPanel = testPanel }
local editor = ISPanel:new(0, 0, 10, 10)
editor.Type = "ISControllerBindingsEditorPanel"
editor.gameOptionControllerTab = tab
editor.onJoypadButtonBindingEdited = function() rec("editorEdited") end
local page = ISPanel:new(0, 0, 10, 10)
page:addChild(editor)
local mainOptions = { tabs = { viewList = { { name = "CONTROLLER", view = page } } }, gameOptions = { changed = false } }
setmetatable(mainOptions, { __index = MainOptions })
m.mainOptions = mainOptions
-- the game's sounds
local SOUNDS = {}
local function snd(name) local s = { v = 1 }; s.getName = function() return name end; s.getUserVolume = function() return s.v end; s.setUserVolume = function(_, v) s.v = v; rec("setUserVolume", name, v) end; SOUNDS[name] = s; return s end
GameSounds = {
    getCategories = function() return jlist({ "Item", "Zombie" }) end,
    getSoundsInCategory = function(c) if c == "Item" then return jlist({ snd("Rip"), snd("Unzip") }) end; return jlist({ snd("ZombieGroan") }) end,
    saveINI = function() rec("saveINI") end, previewSound = function(n) rec("previewSound", n) end, stopPreview = function() rec("stopPreview") end,
    isPreviewPlaying = function() return true end, fix3DListenerPosition = function() end,
}

local ow = ZeD_MMOptions:new(false)
ow:initialise()
ow:instantiate()
ow.anyChanged = function() return mainOptions.gameOptions.changed end
MM.root.optsWin = ow
ow:setVisible(true)
CALLS = {}
ow:openVanillaController()
check("A5 the controller page's editor and test open as a ZeD page", ow.sub == "pad" and not MM._vanillaOptions)
local els = MM.padElements()
check("A5 every button but Guide, the triggers and both sticks", #els == 18, #els)
draw(ow, "A5 button map")
check("A5 each part and what it does", texts():find("A button", 1, true) and texts():find("Interact", 1, true))
local elLT
for _, e in ipairs(els) do if e.name == "LeftTrigger" then elLT = e end end
check("A5 a trigger's action with its threshold, as the game writes it", elLT and MM.padBound(elLT)[1] and MM.padBound(elLT)[1].text == "Aim > 0.50")
check("A5 the controller lands on the first part", ow.focusId == els[1].id, ow.focusId)
check("A5 an unbound part says Nothing", texts():find(ZeD.tr("UI_ZeD_PadMap_Nothing"), 1, true) ~= nil)
check("A5 the test pick is a controller stop", stop(ow, "padtest") ~= nil)
-- live: the menu's own pad lights the drawing
PAD = { id = 0 }
PRESSED.A = true
DRAWN = {}
draw(ow, "A5 A held")
local lit = 0
for _, d in ipairs(DRAWN) do if d.kind == "rect" and d.p == ow and d.a == ZeD.T.selectionA then lit = lit + 1 end end
check("A5 a held button lights on the drawing", lit >= 1, lit)
PRESSED.A = nil
-- pick the test controller: the game's own pick, which holds the pad for the test
ow:openTestPick(combo, { x = 0, y = 0, w = 10, h = 10 })
check("A5 the test pick lists the game's controllers", MM.popup and #MM.popup.items == 2)
MM.popup.items[2].fn()
check("A5 picking runs the game's own (the test starts)", called("onControllerSelected") and testPanel.selectedController == 0 and JoypadState.controllerTest == true)
PRESSED.A, PRESSED.Y = true, true
draw(ow, "A5 A and Y")
check("A5 A and Y held end the test, as the game's", JoypadState.controllerTest == false)
PRESSED.A, PRESSED.Y = nil, nil
-- edit: Run onto B through the pull-down
local elB
for _, e in ipairs(els) do if e.name == "B" then elB = e end end
ow:openPadActions(elB, { x = 0, y = 0, w = 10, h = 10 })
local runItem
for _, it in ipairs(MM.popup.items) do if type(it) == "table" and it.text == "Run" then runItem = it end end
check("A5 the actions pull-down, nothing ticked on B", runItem and runItem.check == false)
runItem.fn()
check("A5 a pick adds the action on the game's binding", called("addBinding") and called("addBinding").a[1] == "Run" and called("addBinding").a[2] == "B")
check("A5 an edit hands off to the game's editor (preset, Apply)", called("editorEdited") ~= nil)
ow:openPadActions(elB, { x = 0, y = 0, w = 10, h = 10 })
for _, it in ipairs(MM.popup.items) do if type(it) == "table" and it.text == "Run" then runItem = it end end
check("A5 a bound action shows ticked", runItem.check == true)
runItem.fn()
check("A5 picking it again takes it off", called("removeBinding") and called("removeBinding").a[1] == "Run")
-- a stick: its movement binding
local elLS
for _, e in ipairs(els) do if e.kind == "axis2d" and e.name == "LeftStick" then elLS = e end end
ow:openPadActions(elLS, { x = 0, y = 0, w = 10, h = 10 })
check("A5 a stick lists Movement ticked", MM.popup.items[1].text == "Movement" and MM.popup.items[1].check == true)
-- the pad: down walks the list, the band at the foot; B back to the Options page
ow.focusId = nil
ow:joyDir("down")
local f1 = ow.focusId
ow:joyDir("down")
check("A5 pad: down walks the parts", f1 ~= nil and ow.focusId ~= f1, tostring(f1) .. " " .. tostring(ow.focusId))
JoypadState.controllerTest = true   -- (a test left running)
ow:joyB()
check("A5 Back ends a test left running: the pad is not left dead", JoypadState.controllerTest == nil)
check("A5 B: back to the Options page", ow.sub == nil)
-- 4K
LAY = { sw = 3840, sh = 2160, tx = 480, ty = 120, tw = 2880, th = 2160, ox = 0, oy = 0, s = 6 }
ow:openSub("pad")
draw(ow, "A5 4K")
ow:closeSub()
LAY = { sw = 1280, sh = 800, tx = 160, ty = 40, tw = 960, th = 720, ox = 0, oy = 0, s = 2 }

-- A6: the game's Advanced button (its handler) opens the page while ZeD's Options show
CALLS = {}
MainOptions.onGameSounds(mainOptions)
check("A6 Advanced opens ZeD's page, not the game's screen", ow.sub == "sounds" and called("vanilla onGameSounds") == nil)
draw(ow, "A6 sounds")
check("A6 the categories and the sounds drawn", texts():find("Item", 1, true) and texts():find("Rip", 1, true) and texts():find("100%", 1, true))
check("A6 pad: the controller lands on the first sound", ow.focusId == "snd:Rip", ow.focusId)
ow:joyDir("right")
check("A6 pad: right turns it up a step", math.abs(SOUNDS.Rip.v - 1.05) < 1e-6, SOUNDS.Rip.v)
for _ = 1, 30 do ow:joyDir("right") end
check("A6 the volume stops at 200 percent", math.abs(SOUNDS.Rip.v - 2) < 1e-6, SOUNDS.Rip.v)
ow:joyA()
check("A6 A plays the sound", called("previewSound") and called("previewSound").a[1] == "Rip")
ow:joyBumper(1)
check("A6 RB: the next category", ow.sndCat == 2 and called("stopPreview") ~= nil)
ow:keyEscape()
check("A6 leaving saves the volumes as the game's Close did", ow.sub == nil and called("saveINI") ~= nil)
-- safe mode, or ZeD's Options not up: the game's own screen
SAFE = true
CALLS = {}
MainOptions.onGameSounds(mainOptions)
check("A6 safe mode: the game's own screen", called("vanilla onGameSounds") ~= nil and ow.sub == nil)
SAFE = false
ow:setVisible(false)
CALLS = {}
MainOptions.onGameSounds(mainOptions)
check("A6 ZeD's Options not up: the game's own screen", called("vanilla onGameSounds") ~= nil)

-- ============================================================================
-- SAFE MODE: no desk, every screen the game's own
-- ============================================================================
MM.root = nil
MM.view = "main"
cts:setVisible(true)
fire("OnServerWorkshopItems", "Required", jlist({ "1" }))
check("safe mode: the game's Workshop items screen shows where the game puts it", ws:isVisible() and ws:getX() > -10000 and MM.view == "main")
ws:onButtonDisconnect()
bp:connect("10.0.0.5", "16261", "")
check("safe mode: the game's invite screen shows", bp:isVisible() and bp:getX() > -10000)
bp:onBackButton()
wsel:setVisible(true)
check("safe mode: the game's world select shows", wsel:isVisible() and MM.view == "main")

print("mainmenu_vanilla_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
