-- ZeDUI/tools/qa/respawn_sim.lua  (Nov 7 2026, Build): back to the desk after a death (VANILLA_WINDOWS B3), with no
-- game running. The real ZeD_MainMenu.lua, ZeD_MainMenuSpawn.lua, ZeD_MainMenuTraits.lua and Overrides/Respawn.lua run
-- on Lua 5.1 with the game's OWN respawn files (CoopCharacterCreation.lua, CoopMapSpawnSelect.lua,
-- CoopCharacterCreationProfession.lua, CoopCharacterCreationMain.lua, CoopUserName.lua and ISPostDeathUI.lua, read
-- from the game's folder) over stubs of the UI classes and the engine. It walks Restart -> Spawn -> Traits -> Looks ->
-- Play and every Back, a second controller's "Add new player", the server name step, Random, a refused spawn, safe mode
-- before and during, the keys and the controller, and reads back what the game was asked to do (setPlayerMouse /
-- setPlayerJoypad, the spawn point, the death screen). Since the review (Nov 7): the controller on the server name step
-- after Back, This Is Your Life's Hometown window on the respawn desk (ModSupport/ThisIsYourLife.lua over a stand-in of
-- the mod), Escape and B with no window up, Random with nothing to land on, the CRT switch-off before the character is
-- made, a name typed and entered on Looks, and the pop-ups' room. What it can't show is the drawing, the 3D figure, the
-- map, and the engine's own focus and pause: CHECK_respawn_20261107.md, in the game.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/respawn_sim.lua
-- Set PZ_LUA to the game's media/lua folder if it is not at E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua.
-- It prints FAIL lines and a last line "respawn_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]respawn_sim%.lua$", "")
local PZ = os.getenv("PZ_LUA") or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local function section(s) print("-- " .. s) end
local function noop() end

-- ---------------------------------------------------------------------------
-- THE UI CLASSES (ISUIElement's contract, as far as these files use it)
-- ---------------------------------------------------------------------------
local UILIST = {}
local function uiIndex(o) for i, e in ipairs(UILIST) do if e == o then return i end end return nil end

local UIBase = {}
UIBase.__index = UIBase
-- (what these files call that the sim does not model does nothing; fields stay nil, as on a real panel)
for _, k in ipairs({ "setAnchorLeft", "setAnchorRight", "setAnchorTop", "setAnchorBottom", "setAnchorsTBLR", "setUIName", "setEnable",
    "setOnlyText", "setMaxTextLength", "unfocus", "focus", "setClearButton", "clearJoypadButton", "onGainJoypadFocus",
    "onLoseJoypadFocus", "create", "drawRect", "drawText", "drawRectBorder", "setStencilRect", "clearStencilRect",
    "removeChild", "setJoypadFocused", "drawTextureScaledAspect", "setCapture", "insertNewLineOfButtons" }) do
    UIBase[k] = noop
end
function UIBase:derive(name)
    local c = {}
    c.__index = c
    c.Type = name
    setmetatable(c, { __index = self })
    return c
end
function UIBase:new(x, y, w, h)
    local o = { x = x or 0, y = y or 0, width = w or 0, height = h or 0, visible = true, children = {},
        backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }, borderColor = { r = 1, g = 1, b = 1, a = 1 } }
    setmetatable(o, self)
    self.__index = self
    return o
end
function UIBase:instantiate()
    if self.javaObject then return end
    self.javaObject = true
    if self.createChildren then self:createChildren() end
end
function UIBase:addToUIManager()
    self:instantiate()
    if not uiIndex(self) then UILIST[#UILIST + 1] = self end
end
function UIBase:removeFromUIManager() local i = uiIndex(self); if i then table.remove(UILIST, i) end end
function UIBase:bringToTop() local i = uiIndex(self); if i then table.remove(UILIST, i); UILIST[#UILIST + 1] = self end end
function UIBase:setVisible(v, joypadData)
    self.visible = v and true or false
    if v and joypadData then joypadData.focus = self end
end
function UIBase:isVisible() return self.visible end
function UIBase:getIsVisible() return self.visible end
function UIBase:isReallyVisible() return self.visible and (self.parent == nil or self.parent:isReallyVisible()) end
-- (ISUIElement:setX: a panel with no parent is kept on the screen unless keepOnScreen is false)
function UIBase:setX(v)
    local keep = self.keepOnScreen
    if keep == nil then keep = not self.parent end
    if keep then v = math.max(0, math.min(v, 1920 - self.width)) end
    self.x = v
end
function UIBase:setY(v) self.y = v end
function UIBase:getX() return self.x end
function UIBase:getY() return self.y end
function UIBase:setWidth(v) self.width = v end
function UIBase:setHeight(v) self.height = v end
function UIBase:getWidth() return self.width end
function UIBase:getHeight() return self.height end
function UIBase:getAbsoluteX() return self.x + (self.parent and self.parent:getAbsoluteX() or 0) end
function UIBase:getAbsoluteY() return self.y + (self.parent and self.parent:getAbsoluteY() or 0) end
function UIBase:addChild(c) c.parent = self; self.children[#self.children + 1] = c; c:instantiate() end
function UIBase:toString() return tostring(self) end
function UIBase:initialise() end
function UIBase:update() end
function UIBase:prerender() end
function UIBase:isFocused() return false end
function UIBase:getText() return self._text or "" end
function UIBase:setText(t) self._text = t end

ISUIElement = UIBase
ISPanel = UIBase:derive("ISPanel")
ISPanelJoypad = ISPanel:derive("ISPanelJoypad")
ISButton = UIBase:derive("ISButton")
ISTextEntryBox = UIBase:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, w, h) local o = UIBase.new(self, x, y, w, h); o._text = text; return o end
function ISTextEntryBox:focus() self._focused = true end
function ISTextEntryBox:unfocus() self._focused = false end
function ISTextEntryBox:isFocused() return self._focused == true end
ZeD_Window = ISPanel:derive("ZeD_Window")
function ZeD_Window:new(x, y, w, h, title) local o = UIBase.new(self, x, y, w, h); o.title = title; return o end
function ZeD_Window:createChildren() end
MapSpawnSelectImage = UIBase:derive("MapSpawnSelectImage")

-- ---------------------------------------------------------------------------
-- THE ENGINE
-- ---------------------------------------------------------------------------
local calls = {}
local function log(s) calls[#calls + 1] = s end
local function called(prefix)
    for _, c in ipairs(calls) do if c:sub(1, #prefix) == prefix then return c end end
    return nil
end

local function jlist(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
local SAFE, CLIENT, PAUSED_SPEED = false, false, nil
local PLAYERS = {}   -- index -> { dead = bool, x, y, z, user }
local SPAWN = nil
local TOWNS = {
    { name = "Muldraugh, KY", points = { unemployed = { { posX = 10800, posY = 9800, posZ = 0 } } } },
    { name = "Riverside, KY", points = { unemployed = { { posX = 6500, posY = 5400, posZ = 0 } } } },
}
local KEY = { ESCAPE = 1, RETURN = 28 }

Events = setmetatable({}, { __index = function(t, k)
    local e = { fns = {} }
    e.Add = function(fn) e.fns[#e.fns + 1] = fn end
    e.Remove = noop
    rawset(t, k, e)
    return e
end })
require = function() return nil end
getText = function(k) return k end
local NOW = 1000   -- (the clock: the CRT switch-off waits on it)
getTimestampMs = function() return NOW end
getTimestamp = function() return 1 end
ZombRand = function(n) return 0 end
isClient = function() return CLIENT end
isServer = function() return false end
getDebug = function() return false end
getMouseX, getMouseY = function() return -1 end, function() return -1 end
isMouseButtonDown = function() return false end
Texture = { getSharedTexture = function() return nil end }
getTexture = function() return nil end
getSoundManager = function() return { playUISound = noop, stopUISound = noop } end
Keyboard = { KEY_ESCAPE = KEY.ESCAPE, KEY_RETURN = KEY.RETURN, KEY_LEFT = 203, KEY_RIGHT = 205, KEY_UP = 200, KEY_DOWN = 208 }
Joypad = { AButton = 0, BButton = 1, XButton = 2, YButton = 3, LBumper = 4, RBumper = 5, Start = 7 }
UIFont = { Small = 1, Medium = 2, Large = 3 }
getTextManager = function()
    return { getFontHeight = function() return 16 end, MeasureStringX = function(_, _, s) return #tostring(s) * 7 end,
        getFontFromEnum = function() return { getLineHeight = function() return 18 end } end, DrawStringCentre = noop }
end
local CORE = { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end,
    getGameMode = function() return "Survival" end, isChallenge = function() return false end,
    getOptionDoVideoEffects = function() return false end, getKey = function() return 1 end, isKey = function() return false end }
getCore = function() return CORE end
Core = { isLastStand = function() return false end }
local DESC = nil
local function newDesc()
    local d = { prof = "unemployed" }
    for _, k in ipairs({ "setForename", "setSurname", "setVoicePrefix", "setVoiceType", "setVoicePitch" }) do
        d[k] = function(self, v) self[k] = v end
    end
    d.getCharacterProfession = function(self) return { getName = function() return self.prof end } end
    return d
end
SurvivorFactory = { CreateSurvivor = function() DESC = newDesc(); return DESC end }
CharacterProfession = { UNEMPLOYED = { getName = function() return "unemployed" end } }
BaseGameCharacterDetails = { DoProfessions = noop }
local WORLD = { traits = {} }
function WORLD:setLuaPosX(v) self.x = v end
function WORLD:setLuaPosY(v) self.y = v end
function WORLD:setLuaPosZ(v) self.z = v end
function WORLD:setLuaPlayerDesc(d) self.desc = d end
function WORLD:getLuaTraits() local w = self; return { clear = function() w.traits = {} end } end
function WORLD:addLuaTrait(t) self.traits[#self.traits + 1] = t end
function WORLD:getGameMode() return "Survival" end
getWorld = function() return WORLD end
setSpawnRegion = function(n) SPAWN = n end
getCellSizeInSquares = function() return 256 end
getSpecificPlayer = function(i)
    local p = PLAYERS[i]
    if not p then return nil end
    return { isDead = function() return p.dead end, isAlive = function() return not p.dead end, getX = function() return p.x or 0 end,
        getY = function() return p.y or 0 end, getZ = function() return 0 end, getUsername = function() return p.user or "" end }
end
getMaxActivePlayers = function() return 4 end
getNumActivePlayers = function() local n = 0; for _ in pairs(PLAYERS) do n = n + 1 end; return n end
IsoPlayer = { allPlayersDead = function() for _, p in pairs(PLAYERS) do if not p.dead then return false end end; return true end }
local SPEED = { SetCurrentGameSpeed = function(_, s) PAUSED_SPEED = s; log("speed " .. s) end }
UIManager = { getSpeedControls = function() return SPEED end, setVisibleAllUI = noop, getUI = function() return jlist(UILIST) end,
    isModalVisible = function() return false end, getMillisSinceLastRender = function() return 16 end }
setShowPausedMessage = noop
setGameSpeed = noop
setPlayerMouse = function(p) log("setPlayerMouse " .. tostring(p)) end
setPlayerJoypad = function(i, j, p, user) log("setPlayerJoypad " .. tostring(i) .. " " .. tostring(j) .. " " .. tostring(user)) end
getServerOptions = function() return { getBoolean = function() return false end } end
SafeHouse = { getSafehouseList = function() return jlist({}) end }
getClientUsername = function() return "me" end
local JFOCUS = {}
updateJoypadFocus = function(jd) JFOCUS[#JFOCUS + 1] = jd.focus end
JoypadState = { players = {}, joypads = {}, getMainMenuJoypad = function() return nil end }
local function newJoypad(id)
    return { id = id, controller = { id = id }, setController = noop, setActive = noop }
end

-- the game's three base screens (the respawn screens derive from them; their own files are 1000+ lines)
CharacterCreationMain = ISPanelJoypad:derive("CharacterCreationMain")
function CharacterCreationMain:new(x, y, w, h)
    local o = ISPanelJoypad.new(self, x, y, w, h)
    o.forenameEntry = ISTextEntryBox:new("Kate", 0, 0, 10, 10)
    o.surnameEntry = ISTextEntryBox:new("Bishop", 0, 0, 10, 10)
    CharacterCreationMain.instance = o
    return o
end
function CharacterCreationMain:getVoicePrefix() return "VoiceFemale" end
function CharacterCreationMain:getVoiceType() return 1 end
function CharacterCreationMain:getVoicePitch() return 0 end
function CharacterCreationMain:onOptionMouseDown(button) log("looks " .. tostring(button.internal)) end
CharacterCreationProfession = ISPanelJoypad:derive("CharacterCreationProfession")
function CharacterCreationProfession:new(x, y, w, h)
    local o = ISPanelJoypad.new(self, x, y, w, h)
    o.listboxTraitSelected = { items = { { item = { getType = function() return "Brave" end } } } }
    o.listboxProf = { items = {}, selected = 1 }
    CharacterCreationProfession.instance = o
    return o
end
function CharacterCreationProfession:PointToSpend() return 0 end
function CharacterCreationProfession:onOptionMouseDown(button) log("traits " .. tostring(button.internal)) end
MapSpawnSelect = ISPanelJoypad:derive("MapSpawnSelect")
function MapSpawnSelect:new(x, y, w, h)
    local o = ISPanelJoypad.new(self, x, y, w, h)
    o.listbox = { items = {}, selected = 1 }
    function o.listbox:addItem(name, item) self.items[#self.items + 1] = { text = name, item = item } end
    function o.listbox:clear() self.items = {} end
    o.mapPanel = UIBase:new(0, 0, 10, 10)
    MapSpawnSelect.instance = o
    return o
end
function MapSpawnSelect:getSpawnRegions() return TOWNS end
function MapSpawnSelect:hasChoices() return #TOWNS > 1 end
function MapSpawnSelect:useDefaultSpawnRegion() self.selectedRegion = TOWNS[1]; return TOWNS[1] end
function MapSpawnSelect:fillList()
    self.listbox:clear()
    for _, r in ipairs(TOWNS) do self.listbox:addItem(r.name, { name = r.name, region = r, dir = r.name, desc = "" }) end
    if #self.listbox.items > 1 then self.listbox:addItem("UI_mapspawn_random", { name = "UI_mapspawn_random", dir = "", desc = "" }) end
end

-- ZeD's library, as far as the desk's glue reads it
ZeD = {
    T = setmetatable({ px = function(n) return n end, scale = 1 }, { __index = function() return { r = 0, g = 0, b = 0, a = 1 } end }),
    TM = getTextManager(),
    tr = function(k) return k end,
    btnCase = function(s) return s end,
    Safe = { on = function() return SAFE end, register = noop },
    Atoms = setmetatable({}, { __index = function() return noop end }),
    Molecules = setmetatable({ bandH = function() return 40 end }, { __index = function() return noop end }),
    MouseTick = { down = function() return false end },
}

-- ---------------------------------------------------------------------------
-- THE FILES: ZeD's, then the game's own respawn files, then ZeD's hook
-- ---------------------------------------------------------------------------
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenu.lua")
local MM = ZeD.MainMenu
MM.ui = { placeOnTube = function(w) return w.width, w.height end, newEntry = function(p) return ISTextEntryBox:new("", 0, 0, 10, 10) end }
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuSpawn.lua")
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuTraits.lua")
-- Looks, for its name fields (its Options base is the main menu's Options window; only the band's fields here)
ZeD_MMOptions = ZeD_MMWindow:derive("ZeD_MMOptions")
function ZeD_MMOptions:createChildren() self.find = MM.ui.newEntry(self); self.field = MM.ui.newEntry(self) end
dofile(ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuLooks.lua")

-- the windows on the desk: the real classes' Next and Back (what the respawn changed), on stand-in windows
local shown = {}
local View = UIBase:derive("View")
function View:new(kind)
    local o = UIBase.new(self, 0, 0, 900, 600)
    o.kind, o.sel, o.esc, o.keys, o.joys = kind, 1, 0, {}, {}
    return o
end
function View:onShow() shown[#shown + 1] = self.kind end
function View:keyEscape() self.esc = self.esc + 1; return true end
function View:keyOther(key) self.keys[#self.keys + 1] = key; return true end
function View:joyA() self.joys[#self.joys + 1] = "A" end
function View:joyB() self.joys[#self.joys + 1] = "B" end
function View:joyDir(d) self.joys[#self.joys + 1] = d end
for _, k in ipairs({ "items", "isRandom", "hasDetails", "nameProblem", "syncToVanilla", "next", "back" }) do
    View["spawn_" .. k] = ZeD_MMSpawn[k]
end
MM.addView("spawn", "spawnWin", function() return View:new("spawn") end, "mapSpawnSelect")
MM.addView("traits", "traitsWin", function() return View:new("traits") end, "charCreationProfession")
MM.addView("looks", "looksWin", function() return View:new("looks") end, "charCreationMain")
MM.addView("credits", "creditsWin", function() return View:new("credits") end, "creditsScreen")   -- (a main-menu-only view)

-- what the windows' buttons do (the real ZeD_MMSpawn / ZeD_MMTraits methods; Looks as ZeD_MMLooks:play / back)
local function spawnWin() return MM.root and MM.root.spawnWin end
local function asSpawn(sel)
    local w = spawnWin()
    local proxy = setmetatable({ sel = sel or 1 }, { __index = ZeD_MMSpawn })
    return proxy, w
end
local function spawnNext(sel) local p = asSpawn(sel); ZeD_MMSpawn.next(p) end
local function spawnBack() local p = asSpawn(); ZeD_MMSpawn.back(p) end
local function traitsNext() ZeD_MMTraits.next(setmetatable({}, { __index = ZeD_MMTraits })) end
local function traitsBack() ZeD_MMTraits.back(setmetatable({}, { __index = ZeD_MMTraits })) end
local function looks() return MainScreen.instance.charCreationMain end
local function looksPlay() local l = looks(); if l then MM.toVanilla(); l:onOptionMouseDown({ internal = "NEXT" }, 0, 0) end end   -- (no looks screen: the desk is down)
local frame
-- Play, then the monitor's switch-off runs out (a second of frames) and the game makes the character
local function playThrough()
    looksPlay()
    for _ = 1, 4 do NOW = NOW + 300; frame() end
end
local function looksBack() MM.toVanilla(); looks():onOptionMouseDown({ internal = "BACK" }, 0, 0) end

-- the game's files
local function game(path) dofile(PZ .. "/" .. path) end
game("client/OptionScreens/CoopCharacterCreation.lua")
game("client/OptionScreens/CoopUserName.lua")
game("client/OptionScreens/CoopMapSpawnSelect.lua")
game("client/OptionScreens/CoopCharacterCreationProfession.lua")
game("client/OptionScreens/CoopCharacterCreationMain.lua")
game("client/ISUI/ISPostDeathUI.lua")

-- the in-game MainScreen (the pause menu's)
MainScreen = { instance = { inGame = true, isReallyVisible = function() return false end, isVisible = function() return false end,
    bottomPanel = UIBase:new(0, 0, 10, 10) } }

dofile(ROOT .. "42/media/lua/client/ZeD/Overrides/Respawn.lua")
local R = ZeD.Respawn
check("the respawn hook loaded", R ~= nil and R.begin ~= nil and ZeD_MMRespawnDesk ~= nil)
check("the desk class is the main menu's", getmetatable(ZeD_MMRespawnDesk).__index == ZeD_MMDesk)

-- ---------------------------------------------------------------------------
-- HELPERS
-- ---------------------------------------------------------------------------
local function coop() return CoopCharacterCreation.instance end
function frame()   -- a frame: the game's panel and the desk update
    local c = coop()
    if c and uiIndex(c) then c:prerender() end
    if MM.root and MM.root:isVisible() then MM.root:update() end
end
local function deathScreen(playerIndex)
    local d = { playerIndex = playerIndex, visible = true, removed = false }
    function d:setVisible(v) self.visible = v end
    function d:removeFromUIManager() self.removed = true end
    ISPostDeathUI.instance[playerIndex] = d
    return d
end
local function restart(d) local ok, err = pcall(ISPostDeathUI.onRespawn, d); if not ok then print("ERR restart " .. tostring(err)) end end
local function reset()
    calls, shown, JFOCUS, SPAWN, PAUSED_SPEED = {}, {}, {}, nil, nil
    for i = #UILIST, 1, -1 do UILIST[i] = nil end
    WORLD.x, WORLD.y, WORLD.desc = nil, nil, nil
    JoypadState.players, JoypadState.joypads = {}, {}
    ISPostDeathUI.instance = {}
end

-- ---------------------------------------------------------------------------
section("Restart with the mouse, single player: the desk over the world, the Spawn window")
reset()
PLAYERS = { [0] = { dead = true } }
local dead = deathScreen(0)
restart(dead)
local c = coop()
check("the game's respawn panel was built", c ~= nil and uiIndex(c) ~= nil)
check("the desk is up", MM.root ~= nil and MM.root.respawn == true and uiIndex(MM.root) ~= nil)
check("the respawn is held", MM.respawn ~= nil and MM.respawn.coop == c and MM.respawn.joypadData == nil)
check("the desk is visible", MM.root and MM.root:isVisible())
check("the desk is above the game's panel", uiIndex(MM.root) and uiIndex(c) and uiIndex(MM.root) > uiIndex(c), tostring(uiIndex(MM.root)) .. " " .. tostring(uiIndex(c)))
check("the view is Spawn", MM.view == "spawn", MM.view)
check("Spawn showed once", #shown == 1 and shown[1] == "spawn", table.concat(shown, ","))
check("only the three windows are built", MM.root.spawnWin and MM.root.traitsWin and MM.root.looksWin and MM.root.creditsWin == nil and MM.root.win == nil and MM.root.loadWin == nil)
check("the game's spawn screen is hidden", not c.mapSpawnSelect:isVisible())
check("the looks screen is where the views look", MainScreen.instance.charCreationMain == c.charCreationMain)
check("traits are where the views look (the game's own)", MainScreen.instance.charCreationProfession == c.charCreationProfession)
frame()
check("the game's panel waits off the screen", c:getX() <= -10000, c:getX())
check("the death screen is hidden", dead.visible == false)
check("the menu bar has only the ZeD menu", #MM.menus() == 1 and MM.menus()[1].key == "zed")
local zi = MM.menuItems("zed")
check("the ZeD menu has only the About block", #zi == 1 and zi[1].about == true)
-- the notepad file adds CletusWorks and the apps to the ZeD menu; the desk after a death has none of their views
do
    ZeD.DeskNotes = ZeD.DeskNotes or { seq = 0 }
    local okN, errN = pcall(dofile, ROOT .. "42/media/lua/client/ZeD/ZeD_MainMenuNotes.lua")
    check("the notepad file loads", okN, errN)
    MM.leftApps = { { id = "mail", menu = "UI_ZeD_Desk_Mail", open = function() end } }
    local zn = MM.menuItems("zed")
    check("with it loaded: still only the About block (no CletusWorks, no Mail)", #zn == 1 and zn[1].about == true, #zn)
    MM.leftApps = {}
end
check("no File menu items", #MM.menuItems("file") == 0)
check("no power button on this desk", (function()
    local real = ZeD_MMDesk.prerender
    ZeD_MMDesk.prerender = function(self) self._hits = { { id = "power" } } end   -- (the room's drawing is not the sim's)
    ZeD_MMRespawnDesk.prerender(MM.root)
    ZeD_MMDesk.prerender = real
    return #MM.root._hits == 0
end)())
check("the pause menu's bottom panel was not touched", MainScreen.instance.bottomPanel:isVisible())
check("the mouse: no controller look", MM.gamepad() == false)

section("Spawn -> Traits -> Looks, and every Back")
spawnNext(1)
check("the town was handed to the game", SPAWN == "Muldraugh, KY", SPAWN)
check("Traits on the desk", MM.view == "traits", MM.view)
check("the game's occupation screen hidden", not c.charCreationProfession:isVisible())
traitsNext()
check("Looks on the desk", MM.view == "looks", MM.view)
check("the game's looks screen hidden", not c.charCreationMain:isVisible())
looksBack()
check("Looks' Back: Traits", MM.view == "traits", MM.view)
traitsBack()
check("Traits' Back: Spawn (the game's: there is a choice of towns)", MM.view == "spawn", MM.view)
check("the pause menu's bottom panel still untouched", MainScreen.instance.bottomPanel:isVisible())
spawnBack()
check("Spawn's Back: the desk is down", MM.root == nil and MM.respawn == nil)
check("the desk left the screen", uiIndex(c) == nil and #UILIST == 0, #UILIST)
check("the death screen is back", dead.visible == true and dead.removed == false)
check("the looks screen field is put back", MainScreen.instance.charCreationMain == nil)
check("nothing was made", called("setPlayerMouse") == nil)

section("Restart again, through to Play: the same world, the character made")
restart(dead)
c = coop()
check("a new desk", MM.root ~= nil and MM.respawn and MM.respawn.coop == c)
check("Spawn first", MM.view == "spawn")
spawnNext(2)
traitsNext()
check("Looks", MM.view == "looks")
looksPlay()
-- (the director, Nov 7: Play switches the desk off with the CRT, as starting a game from the main menu does)
check("Play: the monitor switches off first", MM.powerOff ~= nil and MM.powerOff.run ~= nil)
check("Play: nothing made while it switches off", called("setPlayerMouse") == nil, table.concat(calls, ";"))
check("Play: the desk stays up while it switches off", MM.root ~= nil and MM.root:isVisible() and MM.respawn ~= nil)
looksPlay()
R.onKey(KEY.RETURN)
check("Play again meanwhile: still one switch-off", MM.powerOff ~= nil and called("setPlayerMouse") == nil)
check("Escape meanwhile is kept and does nothing", ZeD.EscapeTakers.respawn() == true and MM.respawn ~= nil and MM.view == "looks")
NOW = NOW + 200; frame()
check("not yet made 200 ms in", called("setPlayerMouse") == nil)
NOW = NOW + 600; frame()
check("the game made the character on the mouse", called("setPlayerMouse nil") ~= nil, table.concat(calls, ";"))
check("made once", (function() local n = 0; for _, s in ipairs(calls) do if s:sub(1, 14) == "setPlayerMouse" then n = n + 1 end end; return n == 1 end)())
check("the switch-off is cleared", MM.powerOff == nil)
check("in Riverside", WORLD.x == 6500 and WORLD.y == 5400, tostring(WORLD.x))
check("with the looks' names", DESC and DESC.setForename == "Kate" and DESC.setSurname == "Bishop")
check("with the traits", WORLD.traits[1] == "Brave")
check("the desk is down", MM.root == nil and MM.respawn == nil and #UILIST == 0, #UILIST)
check("the death screen is gone", dead.removed == true and ISPostDeathUI.instance[0] == nil)
check("the game's panel is finished", CoopCharacterCreation.instance == nil)

section("Random picks a town, never a player's place")
reset()
PLAYERS = { [0] = { dead = true }, [1] = { dead = false, x = 300, y = 400 } }
restart(deathScreen(0))
c = coop()
local items = {}
for i, it in ipairs(c.mapSpawnSelect.listbox.items) do items[i] = it.item.name end
check("the list has the towns, Random and the players' places (the game's rule)", #items == 5 and items[3] == "UI_mapspawn_random"
    and items[4] == "UI_mapspawn_WithPlayer1" and items[5] == "UI_mapspawn_WithPlayer2", table.concat(items, ","))
ZombRand = function(n) return n - 1 end   -- (the last town the roll can give)
spawnNext(3)
check("Random's last pick is still a town", SPAWN == "Riverside, KY", SPAWN)
check("Traits", MM.view == "traits")
traitsBack()
check("back on Spawn", MM.view == "spawn")
ZombRand = function(n) return 0 end
spawnNext(3)
check("Random went to a town", SPAWN == "Muldraugh, KY", SPAWN)
check("Traits", MM.view == "traits")
c:cancel()
check("cancelled: the desk is down", MM.root == nil and MM.respawn == nil)

section("A refused spawn: the Looks window comes back")
reset()
PLAYERS = { [0] = { dead = true } }
restart(deathScreen(0))
c = coop()
spawnNext(1)
traitsNext()
DESC.prof = "nurse"
local savedPts = TOWNS[1].points
TOWNS[1].points = { carpenter = { { posX = 1, posY = 1 } } }
playThrough()
check("nothing was made", called("setPlayerMouse") == nil)
check("the desk is still up", MM.root ~= nil and MM.respawn ~= nil)
check("Looks again", MM.view == "looks" and shown[#shown] == "looks", MM.view)
check("the monitor switches back on", MM.powerOff == nil and MM.powerOn ~= nil)
TOWNS[1].points = savedPts
c:cancel()

section("A second controller's Add new player: the same desk, on the pad")
reset()
PLAYERS = { [0] = { dead = false } }
local jd = newJoypad(2)
JoypadState.joypads[2] = jd
CoopCharacterCreation.newPlayer(jd.id, jd)
c = coop()
check("player 2's slot", c and c.playerIndex == 1, c and c.playerIndex)
check("the game is paused for it (the game's own rule)", PAUSED_SPEED == 0 and jd.activeWhilePaused == true)
check("the desk is up on the pad", MM.respawn and MM.respawn.joypadData == jd)
check("the pad is on the desk", jd.focus == MM.root, tostring(jd.focus))
check("the controller look", MM.gamepad() == true)
check("MM.joypad is the respawning pad", MM.joypad() == jd)
MM.root:onJoypadDown(Joypad.BButton, jd)
MM.root:onJoypadDirDown(jd)
MM.root:onJoypadDown(Joypad.YButton, jd)
local w = MM.root.spawnWin
check("B and the D-pad reach the window", w.joys[1] == "B" and w.joys[2] == "down", table.concat(w.joys, ","))
check("Y has no Terms of service here", #calls == 0 or called("tos") == nil)
check("keys stay off the desk while a pad drives it", R.deskKeys() == false)
spawnNext(1); traitsNext()
check("the pad followed to Looks", MM.view == "looks" and jd.focus == MM.root)
looksPlay()
local deskNow = MM.root
if deskNow then deskNow:onJoypadDown(Joypad.AButton, jd) end
check("A while the monitor switches off: nothing", deskNow ~= nil and #deskNow.looksWin.joys == 0 and called("setPlayerJoypad") == nil)
for _ = 1, 4 do NOW = NOW + 300; frame() end
check("the game made player 2 on the pad", called("setPlayerJoypad 1 2") ~= nil, table.concat(calls, ";"))
check("the game runs again", PAUSED_SPEED == 1)
check("the desk is down", MM.root == nil and MM.respawn == nil and #UILIST == 0)

section("A second player on a server: the game's name step, then the desk")
reset()
CLIENT = true
PLAYERS = { [0] = { dead = false } }
jd = newJoypad(3)
JoypadState.joypads[2] = jd
CoopCharacterCreation.newPlayer(jd.id, jd)
c = coop()
check("the game's name step shows", c.coopUserName:isVisible())
frame()
check("over the world: the game's panel on the screen", c:getX() == 0, c:getX())
check("the desk waits hidden", MM.root and not MM.root:isVisible())
c.coopUserName.entry:setText("Kate2")
c.coopUserName:clickNext()
frame()
check("then Spawn on the desk", MM.view == "spawn" and MM.root:isVisible())
check("the game's panel off the screen again", c:getX() <= -10000, c:getX())
check("the pad on the desk", jd.focus == MM.root, tostring(jd.focus))
-- Back from Spawn: the game's clickBack shows the name step with no controller (its joyfocus is nil)
spawnBack()
frame()
check("Back to the name step: it shows over the world", c.coopUserName:isVisible() and c:getX() == 0 and not MM.root:isVisible())
check("Back to the name step: the pad is on it", jd.focus == c.coopUserName, tostring(jd.focus))
frame()
check("the pad stays where the name step put it", jd.focus == c.coopUserName)
c.coopUserName:clickNext()
frame()
check("Next again: Spawn on the desk, the pad with it", MM.view == "spawn" and MM.root:isVisible() and jd.focus == MM.root)
spawnNext(1); traitsNext(); playThrough()
check("made with the server name", called("setPlayerJoypad 1 3 Kate2") ~= nil, table.concat(calls, ";"))
CLIENT = false

section("Keys with the mouse")
reset()
PLAYERS = { [0] = { dead = true } }
restart(deathScreen(0))
check("the desk takes keys", R.deskKeys() == true)
R.onKey(KEY.RETURN)
check("Return reaches the window", MM.root.spawnWin.keys[1] == KEY.RETURN)
check("Escape is the desk's", ZeD.EscapeTakers.respawn() == true and MM.root.spawnWin.esc == 1)
MM.ctx.open = "zed"
check("Escape closes an open menu first", ZeD.EscapeTakers.respawn() == true and MM.ctx.open == nil and MM.root.spawnWin.esc == 1)
-- a view this desk has no window for (an empty monitor): Escape is the Spawn window's Back, never kept for nothing
MM.view = "credits"
check("an empty monitor (no window for the view)", MM.activeWindow() == nil)
check("Escape on an empty monitor goes back", ZeD.EscapeTakers.respawn() == true and MM.respawn == nil and MM.root == nil)
check("back on the death screen", ISPostDeathUI.instance[0] and ISPostDeathUI.instance[0].visible == true)
check("no desk: Escape is not taken", ZeD.EscapeTakers.respawn() == false)

section("Safe mode")
reset()
SAFE = true
PLAYERS = { [0] = { dead = true } }
restart(deathScreen(0))
c = coop()
check("safe mode: no desk", MM.root == nil and MM.respawn == nil)
check("safe mode: the game's spawn screen shows", c.mapSpawnSelect:isVisible())
check("safe mode: the game's panel on the screen", c:getX() == 0)
c:cancel()
SAFE = false
reset()
PLAYERS = { [0] = { dead = true } }
dead = deathScreen(0)
restart(dead)
c = coop()
check("the desk is up", MM.root ~= nil)
SAFE = true
frame()
check("safe mode on mid-way: the desk is down", MM.root == nil and MM.respawn == nil)
check("back to the death screen", dead.visible == true and CoopCharacterCreation.instance == nil)
SAFE = false

section("A failure building the desk leaves the game's screens")
reset()
PLAYERS = { [0] = { dead = true } }
local realNew = ZeD_MMRespawnDesk.new
ZeD_MMRespawnDesk.new = function() error("boom") end
restart(deathScreen(0))
c = coop()
ZeD_MMRespawnDesk.new = realNew
check("no desk", MM.root == nil and MM.respawn == nil)
check("the game's panel on the screen", c:getX() == 0)
check("the game's spawn screen shows (no redirect without a desk)", c.mapSpawnSelect:isVisible())
c:cancel()

section("The Looks window's names: Return after typing keeps the typed name")
do
    local lw = ZeD_MMLooks:new()
    lw:createChildren()
    local cv = { forenameEntry = ISTextEntryBox:new("Kate", 0, 0, 1, 1), surnameEntry = ISTextEntryBox:new("Bishop", 0, 0, 1, 1) }
    local saved = MainScreen.instance.charCreationMain
    MainScreen.instance.charCreationMain = cv
    lw.fore:focus()
    lw.fore:setText("Zed")   -- (typed, and Return before a frame copied it over)
    lw.fore.onCommandEntered()
    check("Return: the field lets go", not lw.fore:isFocused())
    lw:syncNames()
    check("Return: the typed forename sticks", cv.forenameEntry:getText() == "Zed" and lw.fore:getText() == "Zed", cv.forenameEntry:getText() .. " / " .. lw.fore:getText())
    lw.sur:focus(); lw.sur:setText("Zero"); lw.sur.onCommandEntered(); lw:syncNames()
    check("Return: the typed surname sticks", cv.surnameEntry:getText() == "Zero")
    check("the same Return does not play", lw:keyOther(KEY.RETURN) == true and called("setPlayerMouse") == nil)
    MainScreen.instance.charCreationMain = saved
end

section("Pop-ups at Deck size: kept on the monitor on the respawn desk")
reset()
PLAYERS = { [0] = { dead = true } }
restart(deathScreen(0))
do
    local savedLayout = MM.layout
    MM.layout = function() return { tx = 200, ty = 100, tw = 800, th = 600, s = 1, ox = 0, oy = 0 } end
    local popRoom = MM.popRoom or function() return nil end   -- (the old drop measured the game screen in game, inline)
    local top, bot, left, right = popRoom()
    check("a pop-up's room is the monitor, not the game screen", top == 104 and bot == 696 and left == 204 and right == 996,
        tostring(top) .. "," .. tostring(bot) .. "," .. tostring(left) .. "," .. tostring(right))
    coop():cancel()
    top = popRoom()
    check("in game with no desk: the game screen", top == 8, top)
    MM.layout = savedLayout
end

section("Random with nothing to land on says so")
reset()
PLAYERS = { [0] = { dead = true }, [1] = { dead = false, x = 300, y = 400 } }
restart(deathScreen(0))
c = coop()
do
    -- only the players' places and Random left in the list
    local keep = {}
    for _, e in ipairs(c.mapSpawnSelect.listbox.items) do if e.item.region == nil or tostring(e.item.region.key or ""):sub(1, 10) == "WithPlayer" then keep[#keep + 1] = e end end
    c.mapSpawnSelect.listbox.items = keep
    local ri = 1
    for i, e in ipairs(keep) do if e.item.name == "UI_mapspawn_random" then ri = i end end
    local p = setmetatable({ sel = ri }, ZeD_MMSpawn)
    check("the reason shows for Random", p.randomProblem ~= nil and p:randomProblem(keep[ri].item) == "UI_ZeD_Spawn_RandomNone")
    SPAWN = nil
    local ok, err = pcall(ZeD_MMSpawn.next, p)
    check("Next on Random with nothing to pick: no error", ok, err)
    check("Next waits on Spawn (no town handed over)", MM.view == "spawn" and SPAWN == nil, tostring(SPAWN))
    check("a players' place has no such reason", keep[#keep].item.region ~= nil and p.randomProblem ~= nil and p:randomProblem(keep[#keep].item) == nil)
    c:cancel()
end

section("This Is Your Life on Restart: the Hometown window, and Random never lands on the mod's town")
-- the mod, as far as ModSupport/ThisIsYourLife.lua reads it (the real mod is Workshop 3773911887)
getActivatedMods = function() return jlist({ "ThisIsYourLife" }) end
local TIYL_REGION = { name = "This Is Your Life", points = { unemployed = { { posX = 7, posY = 7 } } } }
TIYL = { REGION_NAME = "This Is Your Life", Origins = { { id = "riverside", name = "Riverside kid", blurb = "b", uniqueBenefit = "u", spawnPoints = { unemployed = { { posX = 6400, posY = 5300 } } } },
    { id = "random", name = "Random", blurb = "b", uniqueBenefit = "u" } } }
TIYL.Flow = {
    completeOrigin = function(id)
        local v = MapSpawnSelect.instance
        if not (v and v.selectedRegion and v.selectedRegion.name == TIYL.REGION_NAME) then return end
        v.selectedRegion.points = { unemployed = { { posX = 6400, posY = 5300, posZ = 0 } } }
        TIYL.PendingOriginId = id
    end,
    completePosterStory = noop,
    abandon = function() TIYL.PendingOriginId = nil end,
}
CORE.setSelectedMap = noop
dofile(ROOT .. "42/media/lua/client/ZeD/ModSupport/ThisIsYourLife.lua")
MM.addView("tiyl", "tiylWin", function() return View:new("tiyl") end)   -- (a stand-in window; the real page's Next and Back run below)
TOWNS[#TOWNS + 1] = TIYL_REGION
reset()
PLAYERS = { [0] = { dead = true } }
local dead2 = deathScreen(0)
restart(dead2)
c = coop()
check("the respawn desk builds the Hometown window", MM.root and MM.root.tiylWin ~= nil)
local ti
for i, e in ipairs(c.mapSpawnSelect.listbox.items) do if e.item.region == TIYL_REGION then ti = i end end
check("the mod's town is in the respawn list", ti ~= nil)
-- Random: the last town the roll can give is never the mod's
ZombRand = function(n) return n - 1 end
local rIdx
for i, e in ipairs(c.mapSpawnSelect.listbox.items) do if e.item.name == "UI_mapspawn_random" then rIdx = i end end
SPAWN = nil
ZeD_MMSpawn.next(setmetatable({ sel = rIdx }, ZeD_MMSpawn))
check("Random never lands on the mod's town", SPAWN == "Riverside, KY", SPAWN)
traitsBack()
ZombRand = function(n) return 0 end
check("back on Spawn", MM.view == "spawn", MM.view)
-- the mod's town: the Hometown window on the monitor (it was an empty monitor with no way out)
ZeD_MMSpawn.next(setmetatable({ sel = ti }, ZeD_MMSpawn))
check("the mod's town opens the Hometown window", MM.view == "tiyl" and MM.activeWindow() == MM.root.tiylWin, MM.view)
check("Escape there is the window's (a window shows)", R.deskKeys() and ZeD.EscapeTakers.respawn() == true and MM.root.tiylWin.esc == 1)
-- the real Hometown page's Back, then its Next
ZeD_MMHometown.back(setmetatable({ sel = 1 }, ZeD_MMHometown))
check("Hometown's Back: the town list", MM.view == "spawn", MM.view)
ZeD_MMSpawn.next(setmetatable({ sel = ti }, ZeD_MMSpawn))
SPAWN = nil
local okH, errH = pcall(ZeD_MMHometown.next, setmetatable({ sel = 1 }, ZeD_MMHometown))
check("Hometown's Next: no error", okH, errH)
check("the hometown was handed to the mod", TIYL.PendingOriginId == "riverside", tostring(TIYL.PendingOriginId))
check("the respawn screen's own Next: the mod's town to the game", SPAWN == "This Is Your Life", tostring(SPAWN))
check("Traits on the desk", MM.view == "traits", MM.view)
traitsNext()
playThrough()
check("made in the hometown", WORLD.x == 6400 and WORLD.y == 5300 and called("setPlayerMouse nil") ~= nil, tostring(WORLD.x))
check("the desk is down", MM.root == nil and MM.respawn == nil)
TOWNS[#TOWNS] = nil

print("respawn_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
