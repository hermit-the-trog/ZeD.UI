-- ZeDUI/tools/qa/step_aside_sim.lua  (Nov 7 2026, Build): ZeD steps aside for a mod that takes a screen
-- (ZeD_StepAside.lua; the director's ruling of Nov 7 2026), with no game running. Lua 5.1 stubs of the game's
-- classes; ZeD's real SafeMode.lua, ZeD_Messages.lua, Overrides/CharacterInfo.lua and ZeD_StepAside.lua; the REAL
-- Lua of Wounds Overhaul (Workshop 3775026731) and of the seven mods QA has (3835479468, 3832759095, 3834708364,
-- 3830103302, 3834856444, 3834889317, 3834902827), each loaded from its Workshop folder in load order after ZeD, with
-- anything of the game they ask for that is not stubbed here answered by an inert stand-in. Two fake mods are written
-- here: one replaces the inventory (ISInventoryPage:createChildren, never calling the game's), one wraps the inventory
-- and the belt and calls the originals.
--   WO       Wounds Overhaul after ZeD: exactly the Character Info window handed back (its Health page holds WO's
--            examination), nothing else; the notice in Messages names WO and the screen; ZeD setup's line under the
--            switch names WO; ZeD.Safe.on("charinfo") true, the other screens ZeD's
--   SEVEN    the seven hand back nothing (and with ZeD's supported list emptied, only the ones that really replace a
--            page's drawing are found, which is why ZeD supports them)
--   FAKE     a mod replacing the inventory (every core function of ISInventoryPage): only the inventory handed back;
--            a mod that wraps and calls the originals: nothing
--   ADDS     the review's false positives, none of which may hand anything back: one copied function (the inventory's
--            createChildren alone, logged for QA as partial), a copy-edited ISCharacterInfoWindow:createChildren adding
--            a tab, originals kept in a table (hooks.render(self)), originals named vanilla / og / default
--            (MyMod.vanilla.render), a hook library's wrapper, an inline function in the first statement
--   ORDER    Wounds Overhaul loaded BEFORE ZeD (the director, Nov 7 2026: "Either order"): the same hand-back
--   STICK    unticking the switch takes the screen back and it holds over the next start and when an unrelated mod is
--            added; WO gone gives the screen back to ZeD; WO back asks again
--   READ     the file reading on its own: wrapper shapes (local orig, field copy, "if orig then orig(self) end",
--            pcall(orig, ...), a helper's wrapped) are wrapping; a body with no call through is replacing
-- Run from the repo root:  lua51 ZeDUI/tools/qa/step_aside_sim.lua
-- It prints FAIL lines and a last line "step_aside_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]step_aside_sim%.lua$", "")
if ROOT == "" then ROOT = "./" end
local CLIENT = ROOT .. "42/media/lua/client/"
local WS = "C:/steamcmd/steamapps/workshop/content/108600/"

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end
local rawPrint = print
local QUIET = true
local LOGS = {}
print = function(s) LOGS[#LOGS + 1] = tostring(s); if not QUIET or not tostring(s):find("^%[") then rawPrint(s) end end

local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- an inert stand-in for whatever a mod asks of the game that is not stubbed
-- ---------------------------------------------------------------------------
local magicMT = {}
local function magic() return setmetatable({}, magicMT) end
magicMT.__index = function(t, k) local m = magic(); rawset(t, k, m); return m end
magicMT.__call = function() return magic() end
magicMT.__concat = function(a, b) return tostring(type(a) == "table" and "" or a) .. tostring(type(b) == "table" and "" or b) end
for _, op in ipairs({ "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm" }) do magicMT[op] = function() return 0 end end
magicMT.__tostring = function() return "magic" end
magicMT.__len = function() return 0 end

-- ---------------------------------------------------------------------------
-- THE GAME
-- ---------------------------------------------------------------------------
local G = _G
local clock = 0
function getTimestampMs() clock = clock + 1000; return clock end
function getTimestamp() return math.floor(clock / 1000) end
local function newEvents()
    Events = setmetatable({}, { __index = function(t, k)
        local e = { fns = {} }
        e.Add = function(fn) e.fns[#e.fns + 1] = fn end
        e.Remove = function(fn) for i = #e.fns, 1, -1 do if e.fns[i] == fn then table.remove(e.fns, i) end end end
        rawset(t, k, e); return e
    end })
end
newEvents()
local WORDS = { IGUI_XP_Info = "Info", IGUI_XP_Skills = "Skills", IGUI_XP_Health = "Health", IGUI_XP_Protection = "Protection",
    IGUI_XP_ClothingIns = "Temperature", UI_Off = "Off", UI_On = "On" }
function getText(k, ...) return WORDS[k] or k end
function getTextOrNull(k) return WORDS[k] end
function isClient() return false end
function isServer() return false end
function isDebugEnabled() return false end
function getDebug() return false end
function getSpecificPlayer(n) if n == 0 then return G._player end return nil end
function getPlayer() return G._player end
function getCore() return setmetatable({ getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end,
    getOptionFontSize = function() return 1 end }, magicMT) end
function instanceof(o, c) return c == "LuaClosure" and type(o) == "function" end
function getFilenameOfClosure(fn)
    local s = debug.getinfo(fn, "S").source
    return (s:gsub("^@", ""))
end
function getFirstLineOfClosure(fn) return debug.getinfo(fn, "S").linedefined end

-- files: Zomboid/Lua kept in memory
local FILES = {}
local function reader(text)
    local lines, i = {}, 0
    for l in (text .. "\n"):gmatch("(.-)\r?\n") do lines[#lines + 1] = l end
    if lines[#lines] == "" then lines[#lines] = nil end
    return { readLine = function() i = i + 1; return lines[i] end, close = function() end }
end
function getFileReader(name, create)
    local t = FILES[name]
    if t == nil then if create then FILES[name] = ""; return reader("") end return nil end
    return reader(t)
end
function getFileWriter(name, create, append)
    local buf = {}
    return { write = function(_, s) buf[#buf + 1] = s end, close = function() FILES[name] = table.concat(buf) end }
end

-- the mods: id -> { name, dir }; the load order is MODLIST
local MODS = {
    ZeD_UI = { name = "ZeD-GUI", dir = ROOT },
    WoundsOverhaul = { name = "Wounds Overhaul [B42]", dir = WS .. "3775026731/mods/WoundsOverhaul" },
    AutoHideHotbar = { name = "Auto-Hide Hotbar", dir = WS .. "3835479468/mods/AutoHideHotbar" },
    MaskFilterIndicator = { name = "Mask Filter Indicator", dir = WS .. "3832759095/mods/MaskFilterIndicator" },
    ItemConditionRestored = { name = "Item Condition Restored", dir = WS .. "3834708364/mods/ItemConditionRestored" },
    BetterItemTransfer = { name = "Better Item Transfer", dir = WS .. "3830103302/mods/BetterItemTransfer" },
    Clear_SkillSheet = { name = "Clear Skill Sheet", dir = WS .. "3834856444/mods/Clear_SkillSheet" },
    VIF_DualRender_B42 = { name = "Better Folders", dir = WS .. "3834889317/mods/VIF_DualRender_B42" },
    BetterModExperience = { name = "Better Mod Experience", dir = WS .. "3834902827/mods/BetterModExperience" },
    FakeInventory = { name = "Fake Inventory", dir = "C:/sim/mods/FakeInventory" },
    FakeWrapper = { name = "Fake Wrapper", dir = "C:/sim/mods/FakeWrapper" },
    LaterMod = { name = "Later Mod", dir = "C:/sim/mods/LaterMod" },
}
local SEVEN = { "AutoHideHotbar", "MaskFilterIndicator", "ItemConditionRestored", "BetterItemTransfer", "Clear_SkillSheet",
    "VIF_DualRender_B42", "BetterModExperience" }
local MODLIST = {}
function getActivatedMods()
    return { size = function() return #MODLIST end, get = function(_, i) return MODLIST[i + 1] end }
end
function getModInfoByID(id)
    local m = MODS[(tostring(id):gsub("^\\", ""))]
    if not m then return nil end
    return { getDir = function() return m.dir end, getName = function() return m.name end, getId = function() return id end,
        getVersionDir = function() return m.dir .. "/42" end, getCommonDir = function() return m.dir .. "/common" end }
end
-- the fake mods' files live here (path -> text)
local FAKE_SRC = {}
function getModFileReader(id, rel, create)
    local m = MODS[(tostring(id):gsub("^\\", ""))]
    if not m then return nil end
    for _, base in ipairs({ m.dir .. "/42/", m.dir .. "/common/" }) do
        local text = FAKE_SRC[base .. rel] or readFile(base .. rel)
        if text then return reader(text) end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- the game's classes (written as if in the game's own files: a path with no mods folder)
-- ---------------------------------------------------------------------------
local VANILLA = [[
ISBaseObject = {}
ISBaseObject.Type = "ISBaseObject"
function ISBaseObject:derive(type)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = type
    return o
end
function ISBaseObject:new() local o = {}; setmetatable(o, self); self.__index = self; return o end
ISUIElement = ISBaseObject:derive("ISUIElement")
function ISUIElement:new(x, y, w, h)
    local o = {}; setmetatable(o, self); self.__index = self
    o.x, o.y, o.width, o.height, o.children, o.visible = x or 0, y or 0, w or 0, h or 0, {}, true
    return o
end
function ISUIElement:initialise() end
function ISUIElement:instantiate() end
function ISUIElement:createChildren() end
function ISUIElement:addChild(c) self.children[#self.children + 1] = c; c.parent = self end
function ISUIElement:removeChild(c) for i = #self.children, 1, -1 do if self.children[i] == c then table.remove(self.children, i) end end; c.parent = nil end
function ISUIElement:setVisible(v) self.visible = v end
function ISUIElement:getIsVisible() return self.visible end
function ISUIElement:isVisible() return self.visible end
function ISUIElement:setY(y) self.y = y end
function ISUIElement:setX(x) self.x = x end
function ISUIElement:getWidth() return self.width end
function ISUIElement:getHeight() return self.height end
function ISUIElement:setWidth(w) self.width = w end
function ISUIElement:setHeight(h) self.height = h end
function ISUIElement:addToUIManager() end
function ISUIElement:removeFromUIManager() end
function ISUIElement:setAnchorRight() end
function ISUIElement:setAnchorBottom() end
function ISUIElement:setAnchorLeft() end
function ISUIElement:setAnchorTop() end
function ISUIElement:getParent() return self.parent end
function ISUIElement:bringToTop() end
function ISUIElement:setCapture() end
function ISUIElement:prerender() end
function ISUIElement:render() end
function ISUIElement:update() end
ISPanel = ISUIElement:derive("ISPanel")
function ISPanel:new(x, y, w, h) local o = ISUIElement.new(self, x, y, w, h); return o end
function ISPanel:createChildren() end
ISPanelJoypad = ISPanel:derive("ISPanelJoypad")
ISCollapsableWindow = ISPanel:derive("ISCollapsableWindow")
function ISCollapsableWindow:createChildren() end
ISTabPanel = ISPanel:derive("ISTabPanel")
function ISTabPanel:new(x, y, w, h) local o = ISPanel.new(self, x, y, w, h); o.viewList = {}; o.tabHeight = 20; return o end
function ISTabPanel:addView(name, view)
    local v = { name = name, id = #self.viewList + 1, view = view }
    table.insert(self.viewList, v)
    self:addChild(view)
end
function ISTabPanel:removeView(view)
    local nl = {}
    for _, v in ipairs(self.viewList) do if v.view ~= view then nl[#nl + 1] = v end end
    self.viewList = nl
    self:removeChild(view)
end
function ISTabPanel:getActiveView() return self.viewList[1] and self.viewList[1].view end
ISCharacterScreen = ISPanelJoypad:derive("ISCharacterScreen")
function ISCharacterScreen:render() end
function ISCharacterScreen:createChildren() end
ISCharacterInfo = ISPanelJoypad:derive("ISCharacterInfo")
function ISCharacterInfo:render() end
function ISCharacterInfo:createChildren() end
ISHealthPanel = ISPanelJoypad:derive("ISHealthPanel")
function ISHealthPanel:new(chr, x, y, w, h) local o = ISPanelJoypad.new(self, x, y, w, h); o.character = chr; return o end
function ISHealthPanel:render() end
function ISHealthPanel:createChildren() end
function ISHealthPanel:checkItems() end
function ISHealthPanel.doBodyPartContextMenu() end
function ISHealthPanel.setBodyPartActionForPlayer() end
ISHealthBodyPartListBox = ISPanel:derive("ISHealthBodyPartListBox")
function ISHealthBodyPartListBox:doDrawItem() end
ISCharacterProtection = ISPanelJoypad:derive("ISCharacterProtection")
function ISCharacterProtection:render() end
ISClothingInsPanel = ISPanelJoypad:derive("ISClothingInsPanel")
function ISClothingInsPanel:new(chr, x, y, w, h) local o = ISPanelJoypad.new(self, x, y, w, h); return o end
function ISClothingInsPanel:render() end
ISCharacterInfoWindow = ISCollapsableWindow:derive("ISCharacterInfoWindow")
function ISCharacterInfoWindow:new(x, y, w, h, n) local o = ISCollapsableWindow.new(self, x, y, w, h); o.playerNum = n; return o end
function ISCharacterInfoWindow:initialise() end
function ISCharacterInfoWindow:createChildren()
    self.panel = ISTabPanel:new(0, 0, 400, 400)
    self:addChild(self.panel)
    self.charScreen = ISCharacterScreen:new(0, 8, 400, 250, self.playerNum)
    self.panel:addView(getText("IGUI_XP_Info"), self.charScreen)
    self.characterView = ISCharacterInfo:new(0, 8, 400, 400, self.playerNum)
    self.panel:addView(getText("IGUI_XP_Skills"), self.characterView)
    self.healthView = ISHealthPanel:new(getSpecificPlayer(self.playerNum), 0, 8, 400, 400)
    self.panel:addView(getText("IGUI_XP_Health"), self.healthView)
    self.protectionView = ISCharacterProtection:new(0, 8, 400, 400, self.playerNum)
    self.panel:addView(getText("IGUI_XP_Protection"), self.protectionView)
    self.clothingView = ISClothingInsPanel:new(getSpecificPlayer(self.playerNum), 0, 8, 400, 400)
    self.panel:addView(getText("IGUI_XP_ClothingIns"), self.clothingView)
end
function ISCharacterInfoWindow:toggleView(name) self._vanillaToggled = name end
function ISCharacterInfoWindow:prerender() end
function ISCharacterInfoWindow:render() end
function ISCharacterInfoWindow:SaveLayout() end
ISInventoryPage = ISPanel:derive("ISInventoryPage")
function ISInventoryPage:createChildren() end
function ISInventoryPage:prerender() end
function ISInventoryPage:render() end
function ISInventoryPage:refreshBackpacks() end
function ISInventoryPage:update() end
ISInventoryPane = ISPanel:derive("ISInventoryPane")
function ISInventoryPane:createChildren() end
function ISInventoryPane:prerender() end
function ISInventoryPane:render() end
function ISInventoryPane:renderdetails() end
function ISInventoryPane:refreshContainer() end
function ISInventoryPane:update() end
function ISInventoryPane:onMouseDown() end
function ISInventoryPane:onMouseUp() end
function ISInventoryPane:onRightMouseUp() end
function ISInventoryPane:selectIndex() end
function ISInventoryPane:doButtons() end
function ISInventoryPane:updateTooltip() end
function ISInventoryPane:onMouseDoubleClick() end
ISHotbar = ISPanel:derive("ISHotbar")
function ISHotbar:render() end
function ISHotbar:update() end
function ISHotbar:refresh() end
ISEquippedItem = ISPanel:derive("ISEquippedItem")
function ISEquippedItem:prerender() end
function ISEquippedItem:render() end
ISVehicleDashboard = ISPanel:derive("ISVehicleDashboard")
function ISVehicleDashboard:createChildren() end
function ISVehicleDashboard:prerender() end
function ISVehicleDashboard:render() end
ISRadialMenu = ISPanel:derive("ISRadialMenu")
function ISRadialMenu:new() end
function ISRadialMenu:instantiate() end
function ISRadialMenu:addSlice() end
ISTimedActionQueue = { add = function() end }
]]

-- a chunk run with the game's globals, and an inert stand-in for any other (the mods' own globals land in _G)
local function inert(t, k)
    if k == "_G" then return G end
    return magic()
end
-- the game's require: a mod's own file by its path under media/lua (shared, then client), run once; the game's own
-- files are the stubs above, already loaded
local RAN = {}
local MODROOT = nil   -- the mod whose files are loading
local runFile
local function gameRequire(name)
    if package.loaded[name] then return package.loaded[name] end
    if MODROOT then
        for _, side in ipairs({ "shared", "client" }) do
            local p = MODROOT .. "/42/media/lua/" .. side .. "/" .. name .. ".lua"
            if RAN[p] then return true end
            if readFile(p) then
                RAN[p] = true
                local ok, err = runFile(p)
                if not ok then error(err, 0) end
                return true
            end
        end
    end
    return true
end
function runFile(path, text, strict)
    local fn, err = loadstring(text or readFile(path) or "", "@" .. path)
    if not fn then return false, err end
    RAN[path] = true
    setfenv(fn, setmetatable({ require = gameRequire }, { __index = function(_, k) local v = rawget(G, k); if v ~= nil or strict then return v end return inert(_, k) end,
        __newindex = function(_, k, v) rawset(G, k, v) end }))
    return pcall(fn)
end

-- the Lua files of a Workshop mod in the game's order: shared, then client, each by path
local function luaFiles(dir)
    local out = {}
    for _, side in ipairs({ "shared", "client" }) do
        local base = dir .. "/42/media/lua/" .. side
        local h = io.popen('dir /s /b "' .. base:gsub("/", "\\") .. '\\*.lua" 2>nul')
        local list = {}
        for l in h:lines() do list[#list + 1] = (l:gsub("\\", "/")) end
        h:close()
        table.sort(list, function(a, b) return a:lower() < b:lower() end)
        for _, l in ipairs(list) do out[#out + 1] = l end
    end
    return out
end

-- ZeD's files: the real ones this work touches, with stand-ins for the rest of ZeD
local function zedStubs()
    package.loaded["ZeD/Tokens"] = true
    package.loaded["ZeD/Tr"] = true
    package.loaded["ZeD/ZeD_CharacterWindow"] = true
    package.loaded["XpSystem/ISUI/ISCharacterInfoWindow"] = true
    package.loaded["ZeD/SafeMode"] = true
    ZeD = { _sim = true }
    ZeD.windowsFor = function(pn) return pn == nil or pn == 0 end   -- (Atoms.lua: split-screen, the first player's windows)
    local en = readFile(ROOT .. "42/media/lua/shared/Translate/EN/UI.json")
    ZeD.tr = function(key, ...)
        local v = en:match('"' .. key .. '":%s*"(.-)",?\r?\n') or key
        local a = { ... }
        return (v:gsub("%%(%d)", function(d) return tostring(a[tonumber(d)]) end))
    end
    ZeD.btnCase = function(s) return s end
    ZeD.logOnce = function() end
    ZeD_CharacterWindow = { _extTabs = {}, isOpen = function() return true end, getWindow = function() return { _activeTab = "skills" } end }
    -- Settings.lua's switches (combos, item 1 Off, item 2 On), as PZAPI's
    ZeD.Settings = { screenOptions = {}, messagesToastOn = function() return true end, messagesCatchOn = function() return true end }
    PZAPI = { ModOptions = setmetatable({ saved = 0 }, magicMT) }
    function PZAPI.ModOptions:save() self.saved = self.saved + 1 end
end
local function combo()
    local o = { selected = 1 }
    o.getValue = function(self) return self.selected end
    o.setValue = function(self, v) self.selected = v end
    return o
end

local SCREENS = { "windows", "belt", "watch", "dashboard", "moodles", "wheels", "charinfo" }
local OPTS
local NOTES

-- one game start: a fresh world (the game's classes, ZeD, then the mods in MODLIST order), the windows built
local function start(modlist, opts)
    opts = opts or {}
    MODLIST = modlist
    for _, k in ipairs({ "ISBaseObject", "ISUIElement", "ISPanel", "Wounds", "WoundsPanel", "WoundsBodyView", "ZeD" }) do G[k] = nil end
    G._player = magic()
    newEvents()
    local ok, err = runFile("media/lua/client/ISUI/vanilla_stub.lua", VANILLA)
    assert(ok, err)
    zedStubs()
    OPTS = OPTS or {}
    for _, s in ipairs(SCREENS) do
        OPTS[s] = OPTS[s] or combo()
        ZeD.Settings.screenOptions[s] = OPTS[s]
    end
    getPlayerInfoPanel = nil
    RAN = {}
    local loaded = {}
    for _, id in ipairs(modlist) do
        if id == "ZeD_UI" then
            for _, f in ipairs({ "ZeD/SafeMode.lua", "ZeD/ZeD_Messages.lua", "ZeD/Overrides/CharacterInfo.lua", "ZeD/ZeD_StepAside.lua" }) do
                local okz, e = runFile(CLIENT .. f, nil, true)
                check("ZeD loads " .. f, okz, e)
                if f == "ZeD/SafeMode.lua" then
                    for _, s in ipairs(SCREENS) do ZeD.Safe.setPieceOption(s, OPTS[s]) end
                end
            end
        elseif FAKE_SRC[MODS[id].dir .. "/42/media/lua/client/" .. id .. ".lua"] then
            local p = MODS[id].dir .. "/42/media/lua/client/" .. id .. ".lua"
            local okf, e = runFile(p, FAKE_SRC[p])
            check("fake mod loads " .. id, okf, e)
        else
            local n, bad = 0, {}
            MODROOT = MODS[id].dir
            for _, f in ipairs(luaFiles(MODS[id].dir)) do
                if not RAN[f] then
                    local okm, e = runFile(f)
                    if not okm then bad[#bad + 1] = f:match("[^/]+$") .. ": " .. tostring(e):sub(1, 120) end
                end
                n = n + 1
            end
            MODROOT = nil
            loaded[id] = { n = n, bad = bad }
        end
    end
    -- the game's start: Character Info windows are made for the player (ISPlayerDataObject.createUI)
    local win = ISCharacterInfoWindow:new(0, 0, 400, 400, 0)
    win:initialise()
    local okw, e = pcall(win.createChildren, win)
    check("the Character Info window builds", okw, e)
    getPlayerInfoPanel = function(n) if n == 0 then return win end return nil end
    NOTES = {}
    if ZeD.Messages then
        local orig = ZeD.Messages.notice
        ZeD.Messages.notice = function(head, text) NOTES[#NOTES + 1] = { head = head, text = text }; return orig(head, text) end
    end
    return win, loaded
end

local function handedBack()
    local out = {}
    for _, s in ipairs(SCREENS) do if ZeD.Safe.on(s) then out[#out + 1] = s end end
    return table.concat(out, ",")
end

-- the fake mods
FAKE_SRC[MODS.FakeInventory.dir .. "/42/media/lua/client/FakeInventory.lua"] = [[
-- a mod that draws its own inventory: the game's page built its way, the game's never called
require "ISUI/ISInventoryPage"
function ISInventoryPage:createChildren()
    self.fakeGrid = {}   -- "end" in a comment, and in a string: "end end end"
    if self.x then
        for i = 1, 3 do self.fakeGrid[i] = i end
    end
end
function ISInventoryPage:prerender()
    self:drawRect(0, 0, self.width, self.height, 1, 0, 0, 0)
end
ISInventoryPage.render = function(self)
    for _, c in ipairs(self.fakeGrid or {}) do self:drawText(tostring(c), 0, 0, 1, 1, 1, 1) end
end
]]
FAKE_SRC[MODS.FakeWrapper.dir .. "/42/media/lua/client/FakeWrapper.lua"] = [[
local originalRender = ISInventoryPage.render
function ISInventoryPage:render()
    originalRender(self)
    self.extra = true
end
FakeWrapper = {}
FakeWrapper.oldHotbarRender = ISHotbar.render
ISHotbar.render = function(self, ...)
    local ok = pcall(FakeWrapper.oldHotbarRender, self, ...)
    return ok
end
local origPre = ISHotbar.prerender
function ISHotbar:prerender()
    if origPre then origPre(self) end
end
-- a context menu entry: adding, not replacing
Events.OnFillInventoryObjectContextMenu.Add(function() end)
]]
-- (loaded after ZeD and never touching a screen: the mod set changes, nothing else)
FAKE_SRC[MODS.LaterMod.dir .. "/42/media/lua/client/LaterMod.lua"] = [[ LaterMod = {} ]]

local function before(list, ...) local t = {}; for _, x in ipairs(list) do t[#t + 1] = x end; for _, x in ipairs({ ... }) do t[#t + 1] = x end; return t end
local BASE = { "ZeD_UI" }

-- ---------------------------------------------------------------------------
print("-- WO: Wounds Overhaul after ZeD")
-- ---------------------------------------------------------------------------
local win, loaded = start(before(BASE, "WoundsOverhaul"))
check("WO's files load", loaded.WoundsOverhaul and loaded.WoundsOverhaul.n > 30 and #loaded.WoundsOverhaul.bad == 0,
    loaded.WoundsOverhaul and (loaded.WoundsOverhaul.n .. " files, " .. table.concat(loaded.WoundsOverhaul.bad, " | ")))
local healthName
for _, v in ipairs(win.panel.viewList) do if v.view == win.woundsView then healthName = v.name end end
check("WO put its examination in the Health page (its own code)", healthName == "Health", tostring(healthName))
check("ZeD's own wrapper is under WO's", ISCharacterInfoWindow._zedOrigCreateChildren ~= nil)
check("no screen handed back before the check", handedBack() == "", handedBack())
win:toggleView("Health")
check("before the check the Health key goes to ZeD's window", win._vanillaToggled == nil, tostring(win._vanillaToggled))
local found = ZeD.StepAside.check()
check("WO: exactly the Character Info window handed back", handedBack() == "charinfo", handedBack())
check("WO: found by its Health page", found.charinfo and found.charinfo.id == "WoundsOverhaul" and found.charinfo.why == "IGUI_XP_Health",
    found.charinfo and (found.charinfo.id .. " " .. tostring(found.charinfo.why)))
check("WO: its wrapped health functions alone do not count",
    (function() local c = 0; for _ in pairs(found) do c = c + 1 end; return c end)() == 1)
check("WO: the switch is ticked and saved", OPTS.charinfo.selected == 2 and PZAPI.ModOptions.saved >= 1)
check("WO: one notice", #NOTES == 1, #NOTES)
check("WO: the notice names the mod and the screen",
    NOTES[1] and NOTES[1].text:find("Wounds Overhaul [B42]", 1, true) and NOTES[1].text:find("character info", 1, true)
    and NOTES[1].text:find("ZeD setup", 1, true), NOTES[1] and NOTES[1].text)
local src = ZeD.Messages.sources[ZeD.tr("UI_ZeD_StepAside_Head")]
check("WO: the notice is kept in Messages, unread", src and #src.items == 1 and src.items[1].read == false)
check("WO: and comes out of the belt's Messages note as a toast", #ZeD.Messages.toasts >= 1 and ZeD.Messages.toasts[#ZeD.Messages.toasts].text == NOTES[1].text)
check("WO: ZeD setup's line under the switch", ZeD.StepAside.underFor("charinfo") == "Taken by Wounds Overhaul [B42]", ZeD.StepAside.underFor("charinfo"))
check("WO: no line under the others", ZeD.StepAside.underFor("windows") == nil and ZeD.StepAside.underFor("belt") == nil)
win._vanillaToggled = nil
win:toggleView("Health")
check("WO: the game's own window opens on Health now (WO's page reachable)", win._vanillaToggled == "Health", tostring(win._vanillaToggled))
check("WO: the record on disk", FILES["ZeD_step_aside.txt"] and FILES["ZeD_step_aside.txt"]:find("set=charinfo|WoundsOverhaul|", 1, true), FILES["ZeD_step_aside.txt"])
-- the next start, the same mods: no second notice, still handed back
start(before(BASE, "WoundsOverhaul"))
ZeD.StepAside.check()
check("WO again: still handed back, no new notice", handedBack() == "charinfo" and #NOTES == 0, handedBack() .. " " .. #NOTES)
check("WO again: the line is read from disk", ZeD.StepAside.underFor("charinfo") == "Taken by Wounds Overhaul [B42]")

-- ---------------------------------------------------------------------------
print("-- STICK: taking the screen back")
-- ---------------------------------------------------------------------------
OPTS.charinfo.selected = 1   -- the player unticks it in ZeD setup
start(before(BASE, "WoundsOverhaul"))
ZeD.StepAside.check()
check("STICK: taken back, ZeD's again", handedBack() == "" and #NOTES == 0, handedBack())
check("STICK: kept on disk", FILES["ZeD_step_aside.txt"]:find("kept=charinfo|WoundsOverhaul", 1, true), FILES["ZeD_step_aside.txt"])
check("STICK: no line under the switch", ZeD.StepAside.underFor("charinfo") == nil)
start(before(BASE, "WoundsOverhaul"))
ZeD.StepAside.check()
check("STICK: it holds at the next start", handedBack() == "" and OPTS.charinfo.selected == 1)
-- (taken back mid-game: the per-second look notices)
-- the mod set changes: asked again
start(before(BASE, "WoundsOverhaul", "LaterMod"))
ZeD.StepAside.check()
check("STICK: an unrelated mod added does not take it again", handedBack() == "" and #NOTES == 0, handedBack())
-- WO gone: ZeD's again, without a word
start(before(BASE, "LaterMod"))
ZeD.StepAside.check()
check("STICK: WO gone gives the screen back to ZeD", handedBack() == "" and OPTS.charinfo.selected == 1 and #NOTES == 0, handedBack())
check("STICK: and the record forgets it", not FILES["ZeD_step_aside.txt"]:find("charinfo", 1, true), FILES["ZeD_step_aside.txt"])
start(before(BASE, "WoundsOverhaul"))
ZeD.StepAside.check()
check("STICK: WO back asks again", handedBack() == "charinfo" and #NOTES == 1, handedBack())
OPTS.charinfo.selected = 1
FILES = {}
-- a switch the player ticked themselves is never unticked by ZeD
OPTS.belt.selected = 2
start(before(BASE))
ZeD.StepAside.check()
check("STICK: the player's own tick stays", OPTS.belt.selected == 2 and ZeD.StepAside.underFor("belt") == nil)
OPTS.belt.selected = 1
-- mid-game: the per-second look
start(before(BASE, "WoundsOverhaul"))
ZeD.StepAside.check()
check("STICK: handed back for the mid-game test", handedBack() == "charinfo")
OPTS.charinfo.selected = 1
for _ = 1, 61 do for _, fn in ipairs(Events.OnTickEvenPaused.fns) do pcall(fn) end end
check("STICK: unticked mid-game is noted at once", FILES["ZeD_step_aside.txt"]:find("kept=charinfo", 1, true), FILES["ZeD_step_aside.txt"])

-- ---------------------------------------------------------------------------
print("-- ORDER: Wounds Overhaul before ZeD")
-- ---------------------------------------------------------------------------
FILES = {}
for _, s in ipairs(SCREENS) do OPTS[s].selected = 1 end
start({ "WoundsOverhaul", "ZeD_UI" })
ZeD.StepAside.check()
check("ORDER: a mod loaded before ZeD gets its screen too", handedBack() == "charinfo" and #NOTES == 1, handedBack())
FILES = {}
for _, s in ipairs(SCREENS) do OPTS[s].selected = 1 end
start({ "FakeInventory", "ZeD_UI" })
ZeD.StepAside.check()
check("ORDER: a fake inventory before ZeD too", handedBack() == "windows", handedBack())
FILES = {}
for _, s in ipairs(SCREENS) do OPTS[s].selected = 1 end
start({ "FakeWrapper", "ZeD_UI" })
ZeD.StepAside.check()
check("ORDER: a wrapper before ZeD still nothing", handedBack() == "", handedBack())

-- ---------------------------------------------------------------------------
print("-- SEVEN: the seven mods QA has")
-- ---------------------------------------------------------------------------
FILES = {}
local seven = before(BASE)
for _, id in ipairs(SEVEN) do seven[#seven + 1] = id end
local _, l7 = start(seven)
for _, id in ipairs(SEVEN) do
    check("SEVEN: " .. id .. " loads", l7[id] and l7[id].n > 0 and #l7[id].bad == 0, l7[id] and (l7[id].n .. " " .. table.concat(l7[id].bad, " | ")))
end
local f7 = ZeD.StepAside.check()
check("SEVEN: nothing handed back", handedBack() == "" and #NOTES == 0, handedBack())
-- what the reading finds without ZeD's supported list (each one ZeD supports)
local keep = ZeD.StepAside.SUPPORTED
ZeD.StepAside.SUPPORTED = {}
local raw7 = ZeD.StepAside.detect()
ZeD.StepAside.SUPPORTED = keep
local rawList = {}
for sc, f in pairs(raw7) do rawList[#rawList + 1] = sc .. "=" .. f.id .. "(" .. tostring(f.why) .. ")" end
table.sort(rawList)
rawPrint("   (without ZeD's supported list the reading finds: " .. (#rawList > 0 and table.concat(rawList, ", ") or "nothing") .. ")")
for sc, f in pairs(raw7) do
    check("SEVEN: only a page-drawing replacement is found (" .. sc .. ")",
        (f.id == "Clear_SkillSheet" and sc == "charinfo") or (f.id == "VIF_DualRender_B42" and sc == "windows"), f.id .. " " .. tostring(f.why))
end

-- ---------------------------------------------------------------------------
print("-- FAKE: a mod replacing the inventory, a mod wrapping it")
-- ---------------------------------------------------------------------------
FILES = {}
start(before(BASE, "FakeWrapper"))
ZeD.StepAside.check()
check("FAKE: wrapping and calling the originals hands back nothing", handedBack() == "" and #NOTES == 0, handedBack())
FILES = {}
start(before(BASE, "FakeInventory"))
local ff = ZeD.StepAside.check()
check("FAKE: replacing the inventory hands back only the inventory", handedBack() == "windows", handedBack())
check("FAKE: found by every core function", ff.windows and ff.windows.why == "ISInventoryPage:createChildren+prerender+render", ff.windows and ff.windows.why)
check("FAKE: the notice names it", NOTES[1] and NOTES[1].text:find("Fake Inventory", 1, true) and NOTES[1].text:find("inventory windows", 1, true), NOTES[1] and NOTES[1].text)
-- everything at once, in load order after ZeD
FILES = {}
for _, s in ipairs(SCREENS) do OPTS[s].selected = 1 end
local all = before(BASE, "WoundsOverhaul")
for _, id in ipairs(SEVEN) do all[#all + 1] = id end
all[#all + 1] = "FakeWrapper"
all[#all + 1] = "FakeInventory"
start(all)
ZeD.StepAside.check()
check("ALL: WO and the fake inventory, nothing else", handedBack() == "windows,charinfo" and #NOTES == 2, handedBack())

-- ---------------------------------------------------------------------------
print("-- ADDS: mods that only add never cost a ZeD screen")
-- ---------------------------------------------------------------------------
local function adds(name, src, wantLog)
    FILES = {}
    for _, s in ipairs(SCREENS) do OPTS[s].selected = 1 end
    local p = MODS.FakeInventory.dir .. "/42/media/lua/client/FakeInventory.lua"
    local keepSrc = FAKE_SRC[p]
    FAKE_SRC[p] = src
    start(before(BASE, "FakeInventory"))
    local n0 = #LOGS
    ZeD.StepAside.check()
    check("ADDS: " .. name .. ": nothing handed back, no notice", handedBack() == "" and #NOTES == 0, handedBack())
    if wantLog then
        local logged = false
        for i = n0 + 1, #LOGS do if LOGS[i]:find("^%[ZeD%] Step aside: partial") then logged = true end end
        check("ADDS: " .. name .. ": one line for QA", logged)
    end
    FAKE_SRC[p] = keepSrc
end
adds("one copied function (the inventory's createChildren)", "function ISInventoryPage:createChildren()\n    self.mine = true\nend\n", true)
adds("a copy-edited createChildren adding a tab", [=[
function ISCharacterInfoWindow:createChildren()
    self.panel = ISTabPanel:new(0, 0, 400, 400)
    self:addChild(self.panel)
    self.charScreen = ISCharacterScreen:new(0, 8, 400, 250, self.playerNum)
    self.panel:addView(getText("IGUI_XP_Info"), self.charScreen)
    self.characterView = ISCharacterInfo:new(0, 8, 400, 400, self.playerNum)
    self.panel:addView(getText("IGUI_XP_Skills"), self.characterView)
    self.healthView = ISHealthPanel:new(getSpecificPlayer(self.playerNum), 0, 8, 400, 400)
    self.panel:addView(getText("IGUI_XP_Health"), self.healthView)
    self.protectionView = ISCharacterProtection:new(0, 8, 400, 400, self.playerNum)
    self.panel:addView(getText("IGUI_XP_Protection"), self.protectionView)
    self.clothingView = ISClothingInsPanel:new(getSpecificPlayer(self.playerNum), 0, 8, 400, 400)
    self.panel:addView(getText("IGUI_XP_ClothingIns"), self.clothingView)
    MyTabPanel = ISPanel:derive("MyTabPanel")
    self.myView = MyTabPanel:new(0, 8, 400, 400)
    self.panel:addView("My tab", self.myView)
end
]=], true)
adds("originals kept in a table", [=[
local hooks = { createChildren = ISInventoryPage.createChildren, prerender = ISInventoryPage.prerender, render = ISInventoryPage.render }
function ISInventoryPage:createChildren() hooks.createChildren(self); self.extra = 1 end
function ISInventoryPage:prerender()
    hooks.prerender(self)
end
function ISInventoryPage:render()
    hooks.render(self)
end
]=])
adds("originals named vanilla, og and default", [=[
MyMod = { vanilla = {} }
MyMod.vanilla.createChildren = ISInventoryPage.createChildren
local og, default_prerender = ISInventoryPage.render, ISInventoryPage.prerender
function ISInventoryPage:createChildren()
    MyMod.vanilla.createChildren(self)
end
function ISInventoryPage:prerender()
    default_prerender(self)
end
function ISInventoryPage:render()
    og(self)
end
]=])
adds("a hook library", [=[
HookLib = {}
function HookLib.wrap(c, n, fn)
    local old = c[n]
    c[n] = function(self, ...) return fn(old, self, ...) end
end
for _, n in ipairs({ "createChildren", "prerender", "render" }) do
    HookLib.wrap(ISInventoryPage, n, function(orig, self) orig(self) end)
end
]=])
adds("an inline function in the first statement", [=[
local oc, op, orr = ISInventoryPage.createChildren, ISInventoryPage.prerender, ISInventoryPage.render
local o1 = ISInventoryPage.createChildren
local o2 = ISInventoryPage.prerender
local o3 = ISInventoryPage.render
function ISInventoryPage:createChildren() local cb = function() return 1 end
    o1(self)
end
function ISInventoryPage:prerender() local cb = function() return 2 end
    o2(self)
end
function ISInventoryPage:render() local cb = function() return 3 end
    o3(self)
end
]=])

-- ---------------------------------------------------------------------------
print("-- READ: the file reading on its own")
-- ---------------------------------------------------------------------------
local function shape(name, src, cls, method, wantReplace, unreadable)
    FILES = {}
    for _, s in ipairs(SCREENS) do OPTS[s].selected = 1 end
    local p = MODS.FakeInventory.dir .. "/42/media/lua/client/FakeInventory.lua"
    local keepSrc = FAKE_SRC[p]
    FAKE_SRC[p] = src
    start(before(BASE, "FakeInventory"))
    if unreadable then FAKE_SRC[p] = nil end
    local hit = ZeD.StepAside._replaced(cls, method)
    check("READ: " .. name, hit == wantReplace, hit and "found" or "not found")
    FAKE_SRC[p] = keepSrc
end
shape("a field copy called through", "local M = {}\nM.r = ISInventoryPane.render\nfunction ISInventoryPane:render() M.r(self) end\n", "ISInventoryPane", "render", false)
shape("a dotted assignment of a new function, no call", "ISInventoryPane.render = function(self)\n  local x = 1\nend\n", "ISInventoryPane", "render", true)
shape("the wheel built another way", "function ISRadialMenu:instantiate()\n  self.javaObject = nil\nend\n", "ISRadialMenu", "instantiate", true)
shape("a helper's wrapped", "local function wrap(f) return function(self, ...) return f(self, ...) end end\nlocal function hook(old)\n  return function(self) wrapped = old; wrappedCall(self) end\nend\nISVehicleDashboard.render = hook(ISVehicleDashboard.render)\n", "ISVehicleDashboard", "render", false)
shape("a copy kept but never called", "local o = ISVehicleDashboard.render\nfunction ISVehicleDashboard:render()\n  if true then return end\nend\n", "ISVehicleDashboard", "render", true)
shape("a dynamic name: unsure, so not replacing", "for _, k in ipairs({'render'}) do ISHotbar[k] = function() end end\n", "ISHotbar", "render", false)
shape("a long string holding end", "local s = [[ end end ]]\nfunction ISHotbar:render()\n  local t = 'end'\nend\n", "ISHotbar", "render", true)
shape("an unreadable file: not replacing", "function ISHotbar:render()\nend\n", "ISHotbar", "render", false, true)
shape("the same, readable: replacing", "function ISHotbar:render()\nend\n", "ISHotbar", "render", true)
shape("an inline function in the first statement", "local origR = ISHotbar.render\nfunction ISHotbar:render() local cb = function() return 1 end\n    origR(self)\nend\n", "ISHotbar", "render", false)
shape("a table-kept original", "local hooks = { render = ISHotbar.render }\nfunction ISHotbar:render()\n    hooks.render(self)\nend\n", "ISHotbar", "render", false)
shape("MyMod.vanilla.render", "MyMod = { vanilla = {} }\nMyMod.vanilla.render = ISHotbar.render\nfunction ISHotbar:render()\n    MyMod.vanilla.render(self)\nend\n", "ISHotbar", "render", false)
shape("an original named og", "local a, b = 1, ISHotbar.render\nlocal function og(s) end\nfunction ISHotbar:render()\n    og(self)\nend\n", "ISHotbar", "render", false)
shape("a hook library's wrapper", "HookLib = {}\nfunction HookLib.wrap(c, n, fn)\n    local old = c[n]\n    c[n] = function(self, ...) return fn(old, self, ...) end\nend\nHookLib.wrap(ISHotbar, \"render\", function(orig, self) orig(self) end)\n", "ISHotbar", "render", false)

QUIET = false
print("step_aside_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
