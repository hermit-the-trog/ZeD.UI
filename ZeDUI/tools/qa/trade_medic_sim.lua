-- ZeDUI/tools/qa/trade_medic_sim.lua  (Nov 7 2026, Build): trading with another player (B10) and the medical
-- check of another player (B11) as World window cards, with no game running.
-- Loads the game's own files from its install, unchanged: ISTradingUI.lua, ISHealthPanel.lua, ISMedicalCheckAction.lua,
-- luautils.lua, and ISWorldObjectContextMenu.onTrade / onMedicalCheck cut out of ISWorldObjectContextMenu.lua; then ZeD's
-- real ObjectCards.lua, HealthTab.lua, ZeD_Trade.lua, ObjectCardTrade.lua, ObjectCardMedic.lua and Overrides/TradeMedic.lua
-- on Lua 5.1 stubs of the UI classes, the Java objects (players, items, bodies) and the game's network calls (from their
-- javap listings; each call is logged). It walks:
--   trade: Trade with (the card, blocked, requestTrading), their request's Yes and No, the game's guards
--          (ISTradingUI.GetUIForPlayer(you):isVisible(), as its Java menu and transfer action ask), every add rule
--          (bag, equipped, favorite, 20 items, twice), seal and unseal, their add / remove / seal / close / refusal,
--          2 tiles apart, an offered item that leaves the inventory, Accept deal, Cancel, the card closing, safe mode,
--          the events routed (vanilla's handlers off the events and never handed ZeD's stand-in);
--          the card drawn at the full card (two columns) and narrow (stacked), its stops and grayed buttons
--   medical check: the action's end opens the card (not ISHealthPanel), the doctor receives the body, the remote body on a
--          server, what a First Aid 0 and a 5 doctor see, pain, the vanilla close rules (moved, same car, staff, 2 tiles),
--          and a part's treatment menu: the game's own doBodyPartContextMenu with doctor and patient right, its Bandage
--          option queueing the game's own HealthPanelAction for the doctor on the patient
-- Every name the cards draw with is checked against the real Molecules.lua / Atoms.lua.
-- Run from the repo root:   lua51 ZeDUI/tools/qa/trade_medic_sim.lua         (expects PASS)
--                           lua51 ZeDUI/tools/qa/trade_medic_sim.lua old     (without the hooks: the old code; expects FAIL)
-- Last line: "trade_medic_sim: N checks, M failed"; exit 1 when any failed.

io.stdout:setvbuf("no")
local OLD = arg and arg[1] == "old"
local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]trade_medic_sim%.lua$", "")
local PZ = os.getenv("ZEDSIM_PZ") or "E:/Project Zomboid/steamapps/common/ProjectZomboid/media/lua/"
local ZL = os.getenv("ZEDSIM_ZL") or (ROOT .. "42/media/lua/")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

local function readFile(p)
    local f = io.open(p, "rb")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s
end

-- ---------------------------------------------------------------------------
-- the game's words: its EN files, and ZeD's UI.json
-- ---------------------------------------------------------------------------
local WORDS = {}
local function loadWords(p)
    local s = readFile(p)
    if not s then return end
    for line in s:gmatch("[^\r\n]+") do
        local k, v = line:match('^%s*"([^"]+)"%s*:%s*"(.*)"%s*,?%s*$')
        if k then WORDS[k] = v:gsub('\\"', '"') end
    end
end
for _, f in ipairs({ "IG_UI", "ContextMenu", "UI", "Moodles", "Tooltip" }) do loadWords(PZ .. "shared/Translate/EN/" .. f .. ".json") end
loadWords(ZL .. "shared/Translate/EN/UI.json")
local MISSING_WORDS = {}
function getText(k, a, b, c, d)
    local s = WORDS[k]
    if not s then MISSING_WORDS[k] = true; return k end
    local args = { a, b, c, d }
    s = s:gsub("%%(%d)", function(n) local v = args[tonumber(n)]; return v ~= nil and tostring(v) or ("%" .. n) end)
    return s
end
function getTextOrNull(k) return WORDS[k] and getText(k) or nil end

-- ---------------------------------------------------------------------------
-- the engine: events, classes, UI
-- ---------------------------------------------------------------------------
local EVENTS = {}
Events = setmetatable({}, { __index = function(t, name)
    local ev = { list = {} }
    function ev.Add(f) ev.list[#ev.list + 1] = f end
    function ev.Remove(f) for i, g in ipairs(ev.list) do if g == f then table.remove(ev.list, i); return end end end
    rawset(t, name, ev)
    EVENTS[name] = ev
    return ev
end })
local function fire(name, ...)
    local ev = Events[name]
    for _, f in ipairs(ev.list) do f(...) end
end
local REQUIRED = {}
function require(p) REQUIRED[p] = true end

local function class(name, base)
    local c = {}
    c.__index = c
    c.Type = name
    if base then setmetatable(c, { __index = base }) end
    function c.derive(self, n) return class(n, self) end
    return c
end
ISBaseObject = class("ISBaseObject")
function ISBaseObject:new() local o = {}; setmetatable(o, self); self.__index = self; return o end

local UIM = {}
local NEWS = { tradingUI = 0, healthPanel = 0 }
ISUIElement = class("ISUIElement")
ISUIElement.IDMax = 1
function ISUIElement:new(x, y, w, h)
    local o = { x = x or 0, y = y or 0, width = w or 0, height = h or 0, anchorLeft = true, anchorTop = true }
    setmetatable(o, self); self.__index = self
    return o
end
function ISUIElement:initialise() self.children = {} end
function ISUIElement:instantiate()
    local jo = { vis = true }
    function jo.setVisible(j, v) j.vis = v end
    function jo.isVisible(j) return j.vis end
    function jo.isReallyVisible(j) return j.vis end
    self.javaObject = jo
end
function ISUIElement:setVisible(v) if not self.javaObject then self:instantiate() end self.javaObject:setVisible(v) end
function ISUIElement:isVisible() if not self.javaObject then self:instantiate() end return self.javaObject:isVisible() end
function ISUIElement:getIsVisible() return self:isVisible() end
function ISUIElement:isReallyVisible() return self:isVisible() end
function ISUIElement:addToUIManager() UIM[self] = true end
function ISUIElement:removeFromUIManager() UIM[self] = nil end
function ISUIElement:centerOnScreen() end
function ISUIElement:getWidth() return self.width end
function ISUIElement:getHeight() return self.height end
function ISUIElement:setWidth(w) self.width = w end
function ISUIElement:setHeight(h) self.height = h end
function ISUIElement:setX(x) self.x = x end
function ISUIElement:setY(y) self.y = y end
function ISUIElement:getAbsoluteX() return self.x end
function ISUIElement:getAbsoluteY() return self.y end
function ISUIElement:getRight() return self.x + self.width end
function ISUIElement:getBottom() return self.y + self.height end
function ISUIElement:addChild(c) c.parent = self end
for _, m in ipairs({ "drawRect", "drawRectBorder", "drawText", "drawTextCentre", "drawTextureScaled", "drawTextureScaledAspect",
        "setStencilRect", "clearStencilRect", "bringToTop", "setAlwaysOnTop", "setWantKeyEvents" }) do
    ISUIElement[m] = function() end
end
ISPanel = ISUIElement:derive("ISPanel")
function ISPanel:new(x, y, w, h)
    local o = ISUIElement.new(self, x, y, w, h)
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.2 }
    return o
end
function ISPanel:update() end
-- (what vanilla's own trading window and health panel call while they build: no-ops here)
for _, m in ipairs({ "setFont", "setOnMouseDoubleClick", "enableCancelColor", "enableAcceptColor", "enableDisabledColor",
        "setAnchorLeft", "setAnchorRight", "setAnchorTop", "setAnchorBottom", "forceClick", "setTitle", "setISButtonForB",
        "setISButtonForY", "clearJoypadFocus", "insertNewLineOfButtons", "restoreJoypadFocus", "clearJoypadButtonsList",
        "setWidthAndParentWidth", "setHeightAndParentHeight", "noBackground", "setAlphas", "enableNodes", "deselect",
        "clearJoypadButton", "setJoypadFocus" }) do
    ISUIElement[m] = function() end
end
ISPanelJoypad = ISPanel:derive("ISPanelJoypad")
function ISPanelJoypad:initialise() ISUIElement.initialise(self) end
ISScrollingListBox = ISPanelJoypad:derive("ISScrollingListBox")
function ISScrollingListBox:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.items, o.selected, o.itemheight = {}, 1, 20
    return o
end
function ISScrollingListBox:addItem(name, item)
    local e = { text = name, item = item, index = #self.items + 1 }
    self.items[#self.items + 1] = e
    return e
end
function ISScrollingListBox:removeItemByIndex(i) table.remove(self.items, i) end
function ISScrollingListBox:clear() self.items = {} end
function ISScrollingListBox:size() return #self.items end
ISButton = ISPanel:derive("ISButton")
ISTickBox = ISPanel:derive("ISTickBox")
function ISTickBox:new(x, y, w, h) local o = ISPanel.new(self, x, y, w, h); o.selected = {}; return o end
function ISTickBox:addOption() end
ISBodyPartPanel = ISPanel:derive("ISBodyPartPanel")
ISCollapsableWindow = ISPanel:derive("ISCollapsableWindow")
ISModalRichText = ISPanelJoypad:derive("ISModalRichText")

-- the game's question (in game a ZeD prompt through Overrides/Prompts.lua: the same fields and answers)
local MODALS = {}
ISModalDialog = ISPanelJoypad:derive("ISModalDialog")
function ISModalDialog:new(x, y, w, h, text, yesno, target, onclick, player, p1, p2)
    local o = ISPanelJoypad.new(self, x, y, w, h)
    o.text, o.yesno, o.target, o.onclick, o.player = text, yesno, target, onclick, player
    MODALS[#MODALS + 1] = o
    return o
end
local function answer(modal, internal)
    local btn = { internal = internal, parent = modal }
    modal:setVisible(false)
    modal:removeFromUIManager()
    modal.onclick(modal.target, btn)
end

-- context menus (the treatment menu)
local MENUS = {}
local function newMenu(playerNum, x, y)
    local m = { playerNum = playerNum, x = x, y = y, options = {}, visible = true }
    function m.addOption(self, name, target, onSelect, a1, a2, a3, a4)
        local o = { name = name, target = target, onSelect = onSelect, args = { a1, a2, a3, a4 } }
        self.options[#self.options + 1] = o
        return o
    end
    function m.getNew(self) return newMenu(playerNum, x, y) end
    function m.addSubMenu(self, opt, sub) opt.sub = sub end
    function m.isEmpty(self) return #self.options == 0 end
    function m.setVisible(self, v) self.visible = v end
    function m.getIsVisible(self) return self.visible end
    return m
end
ISContextMenu = { get = function(playerNum, x, y) local m = newMenu(playerNum, x, y); MENUS[#MENUS + 1] = m; return m end }

local QUEUE = {}
ISTimedActionQueue = {
    add = function(a) QUEUE[#QUEUE + 1] = a; return a end,
    addAfter = function(prev, a) QUEUE[#QUEUE + 1] = a; return a end,
}
local PERFORMED = {}
ISBaseTimedAction = ISBaseObject:derive("ISBaseTimedAction")
function ISBaseTimedAction.new(self, character)
    local o = {}; setmetatable(o, self); self.__index = self
    o.character = character
    o.maxTime = 50
    return o
end
function ISBaseTimedAction:perform() PERFORMED[#PERFORMED + 1] = self end
function ISBaseTimedAction:stop() end
function ISBaseTimedAction:setActionAnim() end

-- ---------------------------------------------------------------------------
-- the game's globals
-- ---------------------------------------------------------------------------
local CALLS = {}
local function call(name) return function(...) CALLS[#CALLS + 1] = { name = name, args = { ... } } end end
local function calls(name)
    local out = {}
    for _, c in ipairs(CALLS) do if c.name == name then out[#out + 1] = c end end
    return out
end
local function clearCalls() CALLS = {} end
requestTrading = call("requestTrading")
acceptTrading = call("acceptTrading")
tradingUISendAddItem = call("tradingUISendAddItem")
tradingUISendRemoveItem = call("tradingUISendRemoveItem")
tradingUISendUpdateState = call("tradingUISendUpdateState")
requestMedicalCheck = call("requestMedicalCheck")
acceptMedicalCheck = call("acceptMedicalCheck")
TradingState = { WindowWasClosed = "WindowWasClosed", DealWasSealed = "DealWasSealed", DealWasUnsealed = "DealWasUnsealed", DealWasFinalized = "DealWasFinalized" }

local CLIENT, MP, DEBUG, SPEED = true, true, false, 1
function isClient() return CLIENT end
function isServer() return false end
function isMultiplayer() return MP end
function getDebug() return DEBUG end
function getTimestampMs() return 1000 end
function getMouseX() return 0 end
function getMouseY() return 0 end
function isMouseButtonDown() return false end
function instanceof() return false end
function getTexture() return nil end
function getJoypadData() return nil end
function setJoypadFocus() end
function updateJoypadFocus() end
function isJoypadFocusOnElementOrDescendant() return false end
function getPlayerHotbar() return nil end
function getPlayerScreenLeft() return 0 end
function getPlayerScreenTop() return 0 end
JoypadState = { players = {} }
UIFont = { Small = "Small", Medium = "Medium", Large = "Large", NewSmall = "NewSmall" }
function getTextManager() return { getFontHeight = function() return 14 end, MeasureStringX = function(_, f, s) return #tostring(s) * 7 end } end
function getCore() return { getScreenWidth = function() return 1920 end, getScreenHeight = function() return 1080 end,
    getOptionFontSizeReal = function() return 1 end, getGameMode = function() return "Multiplayer" end } end
UIManager = { getSpeedControls = function() return { getCurrentGameSpeed = function() return SPEED end } end }
Capability = setmetatable({}, { __index = function(_, k) return k end })
Perks = { Doctor = "Doctor" }
MoodleType = { PAIN = "PAIN" }
ItemType = { KEY_RING = "KEY_RING" }
ItemTag = setmetatable({}, { __index = function(_, k) return k end })
ComponentType = { FluidContainer = "FluidContainer" }
function instanceItem() return nil end
Joypad = { Texture = {} }
xpSystemText = {}
ISInventoryTransferUtil = { newInventoryTransferAction = function(p, item, src, dst) return { transfer = true, item = item } end }
MusicIntensityConfig = { getInstance = function() return { checkHealthPanelVisible = function() end } end }

-- body parts
local BPT = { "Hand_L", "Hand_R", "ForeArm_L", "ForeArm_R", "UpperArm_L", "UpperArm_R", "Torso_Upper", "Torso_Lower", "Head", "Neck",
    "Groin", "UpperLeg_L", "UpperLeg_R", "LowerLeg_L", "LowerLeg_R", "Foot_L", "Foot_R" }
BodyPartType = {}
for _, n in ipairs(BPT) do BodyPartType[n] = "BPT_" .. n end
BodyPartType.getDisplayName = function(t) return tostring(t) end

local function newPart(t)
    local p = { t = t, health = 100, f = {} }
    local num = { getDeepWoundTime = 0, getWoundInfectionLevel = 0, getFractureTime = 0, getSplintFactor = 0, getScratchTime = 0,
        getCutTime = 0, getBurnTime = 0, getStiffness = 0, getAdditionalPain = 0, getBandageLife = 0, getStitchTime = 0,
        getPlantainFactor = 0, getComfreyFactor = 0, getGarlicFactor = 0 }
    local bool = { "bitten", "bleeding", "deepWounded", "isInfectedWound", "haveBullet", "haveGlass", "scratched", "isCut",
        "isNeedBurnWash", "bandaged", "stitched" }
    for k, v in pairs(num) do p[k] = function(self) return self.f[k] or v end end
    for _, k in ipairs(bool) do p[k] = function(self) return self.f[k] == true end end
    function p.getHealth(self) return self.health end
    function p.getType(self) return self.t end
    function p.HasInjury(self) return self.f.deepWounded or self.f.scratched or self.f.bleeding or self.f.isCut or false end
    function p.getBandageType() return nil end
    function p.isDeepWounded(self) return self.f.deepWounded == true end
    function p.getSplintItem() return nil end
    return p
end
local function jlist(t)
    return { size = function() return #t end, get = function(_, i) return t[i + 1] end, isEmpty = function() return #t == 0 end }
end
local function newBody(health)
    local b = { parts = {}, byType = {}, overall = health or 100, pain = 0, restored = 0 }
    for _, n in ipairs(BPT) do local p = newPart(BodyPartType[n]); b.parts[#b.parts + 1] = p; b.byType[p.t] = p end
    function b.getBodyParts(self) return jlist(self.parts) end
    function b.getOverallBodyHealth(self) return self.overall end
    function b.getHealth(self) return self.overall end
    function b.getBodyPart(self, t) return self.byType[t] end
    function b.getRemotePainLevel(self) return self.pain end
    function b.RestoreToFullHealth(self) self.restored = self.restored + 1 end
    return b
end

-- containers and items
local function newContainer(kind)
    local c = { items = {}, kind = kind or "none" }
    function c.getItems(self) return jlist(self.items) end
    function c.getType(self) return self.kind end
    function c.contains(self, it) for _, x in ipairs(self.items) do if x == it then return true end end return false end
    return c
end
local itemN = 0
local function newItem(name, cont, opts)
    itemN = itemN + 1
    opts = opts or {}
    local it = { name = name, id = 1000 + itemN, cont = cont, fav = opts.fav, ftype = opts.ftype or ("Base." .. name:gsub(" ", "")),
        bandage = opts.bandage or 0 }
    function it.getName(self) return self.name end
    function it.getDisplayName(self) return self.name end
    function it.setName(self, n) self.name = n end
    function it.getTex() return "tex" end
    function it.getR() return 1 end
    function it.getG() return 1 end
    function it.getB() return 1 end
    function it.getID(self) return self.id end
    function it.isFavorite(self) return self.fav == true end
    function it.isHidden() return false end
    function it.IsFood() return false end
    function it.getContainer(self) return self.cont end
    function it.isItemType() return false end
    function it.hasTag() return false end
    function it.getFullType(self) return self.ftype end
    function it.getType(self) return (self.ftype:gsub("^Base%.", "")) end
    function it.getBandagePower(self) return self.bandage end
    function it.IsInventoryContainer() return false end
    function it.getCurrentUsesFloat() return 0 end
    function it.hasComponent() return false end
    function it.IsDrainable() return false end
    function it.getAlcoholPower() return 0 end
    function it.getUnequippedWeight() return 0.1 end
    function it.getDisplayCategory() return "Food" end
    if cont then cont.items[#cont.items + 1] = it end
    return it
end

-- players
local PLAYERS = {}
local function newPlayer(name, idx, onlineId, x, y)
    local p = { name = name, idx = idx, oid = onlineId, x = x, y = y, inv = newContainer("none"), worn = {}, equipped = {},
        doctor = 0, caps = {}, body = newBody(100), remote = newBody(100), recv = 0, local_ = true, dead = false, pain = 0,
        vehicle = nil, seated = false, driving = false }
    function p.getIndex(self) return self.idx end
    function p.getPlayerNum(self) return self.idx end
    function p.getOnlineID(self) return self.oid end
    function p.getX(self) return self.x end
    function p.getY(self) return self.y end
    function p.getZ() return 0 end
    function p.getDisplayName(self) return self.name end
    function p.getDisguisedDisplayName(self) return self.name end
    function p.getUsername(self) return self.name end
    function p.getDescriptor(self) local n = self.name; return { getForename = function() return n end, getSurname = function() return "Doe" end } end
    function p.isLocalPlayer(self) return self.local_ end
    function p.isLocal(self) return self.local_ end
    function p.isDead(self) return self.dead end
    function p.getInventory(self) return self.inv end
    function p.getWornItems(self)
        local w = self.worn
        return { size = function() return #w end, get = function(_, i) local it = w[i + 1]; return { getItem = function() return it end } end }
    end
    function p.getPrimaryHandItem(self) return self.equipped[1] end
    function p.getSecondaryHandItem(self) return self.equipped[2] end
    function p.isEquipped(self, it) return self.equipped[1] == it or self.equipped[2] == it end
    function p.isEquippedClothing(self, it) for _, w in ipairs(self.worn) do if w == it then return true end end return false end
    function p.isRecipeActuallyKnown() return false end
    function p.StopAllActionQueue(self) self.stopped = (self.stopped or 0) + 1 end
    function p.getPerkLevel(self, perk) return perk == "Doctor" and self.doctor or 0 end
    function p.getRole(self) local c = self.caps; return { hasCapability = function(_, k) return c[k] == true end } end
    function p.isSeatedInVehicle(self) return self.seated end
    function p.getVehicle(self) return self.vehicle end
    function p.isDriving(self) return self.driving end
    function p.startReceivingBodyDamageUpdates(self, o) self.recv = self.recv + 1 end
    function p.stopReceivingBodyDamageUpdates(self, o) self.recv = self.recv - 1 end
    function p.getBodyDamage(self) return self.body end
    function p.getBodyDamageRemote(self) return self.remote end
    function p.getMoodles(self) local pn = self.pain; return { getMoodleLevel = function() return pn end } end
    function p.isFemale() return false end
    function p.getCurrentSquare() return {} end
    function p.isTimedActionInstant() return false end
    function p.faceThisObject() end
    function p.getJoypadBind() return -1 end
    function p.isAsleep() return false end
    PLAYERS[#PLAYERS + 1] = p
    return p
end
local P1 = newPlayer("Aretha", 0, 11, 100.5, 100.5)
local P2 = newPlayer("Bobby", 1, 22, 101.5, 100.5)
P2.local_ = false
local ONLINE = { [11] = P1, [22] = P2 }
function getPlayerByOnlineID(id) return ONLINE[id] end
function getSpecificPlayer(n) return n == 0 and P1 or (n == 1 and P2 or nil) end
function getPlayer() return P1 end
ISInventoryPaneContextMenu = { getContainers = function(p) return jlist({ p:getInventory() }) end }

-- ---------------------------------------------------------------------------
-- the game's files, unchanged
-- ---------------------------------------------------------------------------
local function runFile(p, label)
    local src = readFile(p)
    if not src then print("FAIL cannot read " .. p); failed = failed + 1; return false end
    src = src:gsub("^\239\187\191", "")
    local fn, err = loadstring(src, "@" .. (label or p))
    if not fn then print("FAIL cannot load " .. tostring(label or p) .. ": " .. tostring(err)); failed = failed + 1; return false end
    local ok, e = pcall(fn)
    if not ok then print("FAIL running " .. tostring(label or p) .. ": " .. tostring(e)); failed = failed + 1; return false end
    return true
end
runFile(PZ .. "shared/luautils.lua", "luautils.lua")
local WALKS = 0
luautils.walkToContainer = function() WALKS = WALKS + 1 end
luautils.walkAdj = function() return true end
runFile(PZ .. "client/ISUI/ISTradingUI.lua", "ISTradingUI.lua")
-- ISTradingUI:new as built by vanilla, counted (the old code opens it)
do
    local orig = ISTradingUI.new
    ISTradingUI.new = function(...) NEWS.tradingUI = NEWS.tradingUI + 1; return orig(...) end
end
runFile(PZ .. "client/XpSystem/ISUI/ISHealthPanel.lua", "ISHealthPanel.lua")
do
    local orig = ISHealthPanel.new
    ISHealthPanel.new = function(...) NEWS.healthPanel = NEWS.healthPanel + 1; return orig(...) end
    -- (vanilla's wrapInCollapsableWindow lives on ISUIElement; the old code's window)
    ISUIElement.wrapInCollapsableWindow = function(self, title)
        local w = ISCollapsableWindow:new(0, 0, 10, 10); w.nested = self; w.title = title; return w
    end
    ISHealthPanel.setOtherPlayer = ISHealthPanel.setOtherPlayer
end
runFile(PZ .. "client/TimedActions/ISMedicalCheckAction.lua", "ISMedicalCheckAction.lua")
-- ISWorldObjectContextMenu.onTrade and .onMedicalCheck, cut out of the game's file as written
ISWorldObjectContextMenu = {}
do
    local src = readFile(PZ .. "client/ISUI/ISWorldObjectContextMenu.lua") or ""
    src = src:gsub("\r\n", "\n")
    for _, name in ipairs({ "onTrade", "onMedicalCheck" }) do
        local s = src:find("\nISWorldObjectContextMenu%." .. name .. " = function", 1)
        local e = s and src:find("\nend\n", s + 1, true)
        check("the game's ISWorldObjectContextMenu." .. name .. " is found", s and e)
        if s and e then
            local fn, err = loadstring(src:sub(s + 1, e + 4), "@ISWorldObjectContextMenu." .. name)
            check("the game's " .. name .. " loads", fn ~= nil, err)
            if fn then fn() end
        end
    end
end
check("vanilla's trade handlers are on the events", #Events.AcceptedTrade.list == 1 and Events.AcceptedTrade.list[1] == ISTradingUI.AcceptedTrade)
local VANILLA = {
    AcceptedTrade = ISTradingUI.AcceptedTrade, TradingUIAddItem = ISTradingUI.OtherAddNewItem,
    TradingUIRemoveItem = ISTradingUI.RemoveItem, TradingUIUpdateState = ISTradingUI.UpdateState,
}

-- ---------------------------------------------------------------------------
-- ZeD's library, stubbed; every name used is checked against the real files at the end
-- ---------------------------------------------------------------------------
local USED = { Molecules = {}, Atoms = {} }
local function recorder(kind, impl)
    return setmetatable({}, { __index = function(t, k)
        USED[kind][k] = true
        local f = impl[k] or function() return 0 end
        return f
    end })
end
local function col(r, g, b) return { r = r, g = g, b = b, a = 1 } end
ZeD = ZeD or {}
ZeD.T = {
    px = function(v) return v end, buttonH = 22, hair = 1, fontF1 = "F1", fontF2 = "F2", fontF3 = "F3", fontF4 = "F4", fontF5 = "F5",
    text = col(1, 1, 1), textDim = col(.6, .6, .6), textHead = col(1, 1, 1), textOnFocus = col(0, 0, 0), accent = col(.4, .6, 1),
    positive = col(0, 1, 0), warning = col(1, 1, 0), danger = col(1, 0, 0), border = col(.3, .3, .3), borderS = col(.5, .5, .5),
    stripe = col(1, 1, 1), surf1 = col(0, 0, 0), surf2 = col(.1, .1, .1), iconWhite = col(1, 1, 1), selectionA = 0.3, fillBarH = 8,
    line = function(n) return n end,
    sp = { scrollbarW = 12, figureW = 220, figureH = 260, rowGap = 6, afterLine = 10, afterGroove = 8, xs = 6, sm = 10, badgeGap = 4, buttonPadX = 8 },
}
ZeD.TM = { getFontHeight = function() return 14 end, MeasureStringX = function(_, f, s) return #tostring(s or "") * 7 end }
local BANDS = {}
local DRAWN = {}
ZeD.Molecules = recorder("Molecules", {
    bandH = function() return 32 end,
    buttonW = function(l) return #tostring(l or "") * 7 + 16 end,
    drawButton = function(p, x, y, w, h, label, variant, pressed, colors, o) DRAWN[#DRAWN + 1] = { button = label, disabled = o and o.disabled } end,
    drawBand = function(p, x, y, w, spec)
        BANDS[#BANDS + 1] = spec
        local out = { buttons = {}, icons = {}, lead = {} }
        local right = x + w - 8
        for i = #(spec.buttons or {}), 1, -1 do
            local b = spec.buttons[i]
            local bw = #tostring(b.label) * 7 + 16
            right = right - bw
            out.buttons[i] = { x = right, y = y + 5, w = bw, h = 22, id = b.id }
            right = right - 8
        end
        if spec.check then out.check = { x = x + 8, y = y + 5, w = 120, h = 22, id = spec.check.id } end
        return 32, out
    end,
    drawQuestionBand = function(p, x, y, w) return 32, { x = 0, y = y, w = 50, h = 22 }, { x = 60, y = y, w = 50, h = 22 } end,
    drawTag = function() return 40, 16 end,
    drawSectionHeader = function() return 20 end,
    drawEmptyLine = function(p, x, y, w, text) DRAWN[#DRAWN + 1] = { empty = text }; return 14 end,
    drawNeedsLine = function() return 14 end,
    drawMoreRow = function() return 0, nil, {} end,
    drawStatRowDot = function() return 18 end,
    drawFillBar = function() return 8 end,
})
ZeD.Atoms = recorder("Atoms", {
    textCase = function(s) return s end,
    truncateText = function(s) return s end,
    wrapText = function(s) return { s } end,
    mouseIn = function() return false end,
    drawPxIcon = function(p, id) DRAWN[#DRAWN + 1] = { px = id } end,
    drawBody = function(p, s) DRAWN[#DRAWN + 1] = { body = s } end,
})
ZeD.Focus = { mark = function() return false end }
ZeD.Help = { set = function() end }
ZeD.Disclose = { setting = function() return "fold" end, split = function(v) return v, {} end, needsLine = function() return "" end, toggle = function() end }
ZeD.CraftingCore = { truncText = function(s) return s end }
ZeD.partLabel = function(n) return n end
ZeD.btnCase = function(s) return s end
ZeD.textCase = function(s) return s end
table.wipe = table.wipe or function(t) for k in pairs(t) do t[k] = nil end end
ZeD.upper = string.upper
ZeD.tr = function(k, ...) return getText(k, ...) end
local LOGGED = {}
ZeD.logOnce = function(k, m) if not LOGGED[k] then LOGGED[k] = true; print("LOG " .. tostring(k) .. ": " .. tostring(m)) end end
local SAFE = false
ZeD.Safe = { on = function() return SAFE end }
ZeD_ScrollbarState = { new = function()
    return { scrollPos = 0, visible = false, setScrollPos = function(s, v) s.scrollPos = v end, setBarSize = function() end, draw = function() end }
end }
ZeD_BodyFigure = ISUIElement:derive("ZeD_BodyFigure")
function ZeD_BodyFigure:new() local o = ISUIElement.new(self, 0, 0, 100, 100); o.colors = {}; return o end
function ZeD_BodyFigure:loadTextures() end
function ZeD_BodyFigure:setSex() end
function ZeD_BodyFigure:clearColors() self.colors = {} end
function ZeD_BodyFigure:setPartColor(n, r, g, b) self.colors[n] = { r, g, b } end
function ZeD_BodyFigure:drawAt(panel, x, y, w, h) self.at = { x, y } end
function ZeD_BodyFigure:getPartRects()
    local x, y = self.at[1], self.at[2]
    return { { name = "Upper Torso", x = x + 90, y = y + 60, w = 40, h = 50 }, { name = "Left Hand", x = x + 20, y = y + 130, w = 16, h = 16 } }
end

-- the World window: one window, one card
local CARD
local WIN = { _playerObj = P1 }
local drawerObject = nil
-- (the World window's own drawer rules, as ZeD_WorldWindow.lua writes them: a pinned card stays when
-- something else drops it; only closeObjectCard, the card's own close, forces it out)
local WIN_OPEN = true
local function dropObject(force)
    local d = WIN._drawerObject
    if not d then return end
    if d.def and d.def.pinned and not force and d.def.pinned(d.t) then return end
    WIN._drawerObject = nil
    CARD:setEntry(nil)
end
ZeD_WorldWindow = {
    getWindow = function() return WIN_OPEN and WIN or nil end,
    openObjectCard = function(n, entry)
        WIN_OPEN = true
        WIN._drawerItem = nil
        WIN._drawerObject = entry
        WIN._drawerOpen = true
        CARD:setEntry(entry)
        return true
    end,
    closeObjectCard = function()
        if not (WIN_OPEN and WIN._drawerObject) then return end
        ZeD_WorldWindow._closingCard = true
        dropObject(true)
        ZeD_WorldWindow._closingCard = nil
    end,
    getObjectCard = function() return WIN_OPEN and WIN._drawerObject and CARD or nil end,
}

runFile(ZL .. "client/ZeD/ObjectCards.lua", "ObjectCards.lua")
runFile(ZL .. "client/ZeD/HealthTab.lua", "HealthTab.lua")
CARD = ZeD_ObjectCard:new(0, 0, 480, 900, 0)
if not OLD then
    runFile(ZL .. "client/ZeD/ZeD_Trade.lua", "ZeD_Trade.lua")
    runFile(ZL .. "client/ZeD/ObjectCardTrade.lua", "ObjectCardTrade.lua")
    runFile(ZL .. "client/ZeD/ObjectCardMedic.lua", "ObjectCardMedic.lua")
    runFile(ZL .. "client/ZeD/Overrides/TradeMedic.lua", "Overrides/TradeMedic.lua")
end
local TR = ZeD.Trade or { get = function() return nil end }

local function tick(n)
    for _ = 1, n or 1 do fire("OnTick") end
end
local function draw()
    BANDS, DRAWN = {}, {}
    local ok, err = pcall(function() CARD:prerender() end)
    check("the card draws without an error", ok, err)
    return CARD._zones
end
local function zone(fid)
    for _, z in ipairs(CARD._zones or {}) do if z.fid == fid then return z end end
    return nil
end
local function lastState() local c = calls("tradingUISendUpdateState"); return c[#c] and c[#c].args[3] end

-- ===========================================================================
-- TRADE
-- ===========================================================================
-- the events: vanilla's handlers off, one router each
for ev, f in pairs(VANILLA) do
    local present = false
    for _, g in ipairs(Events[ev].list) do if g == f then present = true end end
    check(ev .. ": vanilla's handler is off the event", not present)
    check(ev .. ": one handler on the event", #Events[ev].list == 1, #Events[ev].list)
end

-- Trade with Bobby
local apple = newItem("Apple", P1.inv)
local nails = {}
for i = 1, 3 do nails[i] = newItem("Nails", P1.inv) end
local bag = newContainer("Bag")
local inBag = newItem("Bandage", bag)
local worn = newItem("Jacket", P1.inv); P1.worn = { worn }
local held = newItem("Knife", P1.inv); P1.equipped = { held }
local fav = newItem("Watch", P1.inv, { fav = true })
clearCalls()
ISWorldObjectContextMenu.onTrade({}, P1, P2)
local s = TR.get(P1)
check("Trade with: no vanilla trading window", NEWS.tradingUI == 0, NEWS.tradingUI)
check("Trade with: ZeD's trade opens on the card", s ~= nil and CARD.entry and CARD.entry.def.id == "trade")
check("Trade with: requestTrading(you, them)", #calls("requestTrading") == 1 and calls("requestTrading")[1].args[1] == P1 and calls("requestTrading")[1].args[2] == P2)
check("Trade with: what you were doing stops (vanilla's new)", (P1.stopped or 0) >= 1)
if s then
    check("Trade with: blocked until they answer", s.pending and s.blocking == getText("IGUI_TradingUI_WaitingAnswer", "Bobby"), s.blocking)
    local ui = ISTradingUI.GetUIForPlayer(P1)
    check("the game finds the trade open: GetUIForPlayer(you):isVisible() (its Java menu, its transfer action)",
        ui ~= nil and ISTradingUI.isVisible(ui) == true)
    -- the inventory list: the main inventory only, no worn, held, favorite or bag items; nails grouped
    local names = {}
    for _, g in ipairs(s.groups) do names[g.label] = #g.items end
    check("the list: apple and the 3 nails, grouped", names.Apple == 1 and names.Nails == 3)
    check("the list: no worn, held, favorite or bag item", names.Jacket == nil and names.Knife == nil and names.Watch == nil and names.Bandage == nil)
    -- the card while waiting
    draw()
    local band = BANDS[#BANDS]
    check("waiting: the band has Seal offer, Cancel and Accept deal", band and band.check and band.buttons and #band.buttons == 2)
    check("waiting: Seal offer grayed", band and band.check and band.check.disabled == true)
    check("waiting: Cancel reads Close (vanilla, while blocked)", band and band.buttons[1].label == getText("IGUI_CraftUI_Close"), band and band.buttons[1].label)
    check("waiting: Accept deal grayed", band and band.buttons[2].disabled == true)
    local z = zone("tr:add:Apple")
    check("waiting: Add is a stop but grayed, saying why", z and z.run == nil and z.help == s.blocking)
    check("waiting: the tag says Waiting", (CARD.entry.def.pill(CARD.entry.t)) == getText("UI_ZeD_Trade_TagWaiting"))
    local px = false
    for _, d in ipairs(DRAWN) do if d.px == "swap" then px = true end end
    check("the header draws the swap icon", px)

    -- their answer
    fire("AcceptedTrade", P2, P1, true)
    check("they said yes: not blocked", not s.pending and s.blocking == nil)
    clearCalls()
    -- add rules, as vanilla's addItemToYourOffer
    check("add the apple", s:addItem(apple) == true and #s.your == 1)
    check("add: tradingUISendAddItem(you, them, item)", #calls("tradingUISendAddItem") == 1 and calls("tradingUISendAddItem")[1].args[3] == apple)
    check("add the apple twice: no", s:addItem(apple) == false and #s.your == 1)
    local w0 = WALKS
    check("an item in a bag: no", s:addItem(inBag) == false and s.flash == getText("IGUI_TradingUI_ItemNeedTransfer", "Bandage"), s.flash)
    check("an item in a bag: vanilla walks to its container", WALKS == w0 + 1)
    check("a held item: no", s:addItem(held) == false and s.flash == getText("IGUI_TradingUI_ItemNeedUnequip", "Knife"))
    check("a worn item: no", s:addItem(worn) == false)
    check("a favorite: no", s:addItem(fav) == false and s.flash == getText("IGUI_TradingUI_CantAddFavorite"))
    s:rebuild()
    local hasApple = false
    for _, g in ipairs(s.groups) do if g.label == "Apple" then hasApple = true end end
    check("an offered item leaves the list", not hasApple)
    -- the card, open: Add runs, the two columns
    draw()
    local addAll = zone("tr:all:Nails")
    check("Add all on a stack of 3", addAll ~= nil and addAll.run ~= nil)
    if addAll then addAll.run(CARD, P1) end
    check("Add all: the 3 nails on the offer", #s.your == 4, #s.your)
    draw()
    local rm = zone("tr:rm:" .. apple:getID())
    check("Remove on your offer's apple", rm ~= nil and rm.run ~= nil)
    local rmL = zone("tr:rm:" .. nails[1]:getID())
    check("two columns on the full card: your offer at the left", rmL and rmL.x + rmL.w <= 240 + 10, rmL and (rmL.x + rmL.w))
    clearCalls()
    if rm then rm.run(CARD, P1) end
    check("Remove: off the offer, tradingUISendRemoveItem", #s.your == 3 and #calls("tradingUISendRemoveItem") == 1)
    -- 20 items
    local many = {}
    for i = 1, 18 do many[i] = newItem("Stone" .. i, P1.inv) end
    for i = 1, 18 do s:addItem(many[i]) end
    check("20 items at most", #s.your == 20, #s.your)
    check("the 21st: vanilla's words", s.flash == getText("IGUI_TradingUI_MaxItemReached", 20), s.flash)
    s:rebuild()
    draw()
    local addA = zone("tr:add:Apple")
    check("full: Add grayed, saying why", addA and addA.run == nil and addA.help == getText("IGUI_TradingUI_MaxItemReached", 20))
    for i = 1, 18 do s:removeItem(many[i]) end
    -- seal
    clearCalls()
    draw()
    local seal = zone("oc:foot:seal")
    check("Seal offer is a stop that runs", seal and seal.run ~= nil)
    if seal then seal.run(CARD, P1) end
    check("sealed: DealWasSealed sent", s.sealed and lastState() == "DealWasSealed", lastState())
    local ok1, why1 = s:canAccept()
    check("only you sealed: Accept deal grayed, vanilla's reason", not ok1 and why1 == getText("IGUI_TradingUI_AcceptDealTooltip"))
    draw()
    local rmS = zone("tr:rm:" .. nails[1]:getID())
    check("sealed: Remove grayed, saying why", rmS and rmS.run == nil and rmS.help == getText("IGUI_TradingUI_OfferSealed"))
    check("sealed: adding is refused", s:addItem(newItem("Rock", P1.inv)) == false)
    fire("TradingUIUpdateState", P2, P1, "DealWasSealed")
    check("they sealed", s.otherSealed == true)
    check("both sealed: Accept deal can run", (s:canAccept()))
    check("both sealed: the tag says Ready", (CARD.entry.def.pill(CARD.entry.t)) == getText("UI_ZeD_Trade_TagReady"))
    -- their change unseals both, as vanilla
    local theirs = newItem("Shotgun", newContainer())
    fire("TradingUIAddItem", P2, P1, theirs)
    check("their add: on their offer", #s.his == 1 and s.his[1] == theirs)
    check("their add: yours unticked, theirs unsealed (locally, as vanilla)", s.sealed == false and s.otherSealed == false)
    check("their add: in the trade log", #s.log >= 1 and s.log[#s.log].message == getText("IGUI_TradingUI_AddedItem", "Bobby", "Shotgun"))
    fire("TradingUIAddItem", P2, P1, theirs)
    check("their add twice: once", #s.his == 1)
    fire("TradingUIRemoveItem", P2, P1, theirs:getID())
    check("their remove", #s.his == 0 and s.log[#s.log].message == getText("IGUI_TradingUI_RemovedItem", "Bobby", "Shotgun"))
    fire("TradingUIAddItem", P2, P1, theirs)
    -- 2 tiles apart
    P2.x = 104
    tick(1)
    check("too far: blocked with vanilla's words", s.blocking2 == getText("IGUI_TradingUI_TooFarAway", "Bobby"))
    s:setSealed(true)
    check("too far: Seal offer does nothing", s.sealed == false)
    P2.x = 101.5
    tick(1)
    check("close again: unblocked", s.blocking2 == nil)
    -- an offered item that leaves the main inventory
    clearCalls()
    nails[2].cont = bag
    tick(1)
    check("an offered item put in a bag comes off the offer", not s:isOffered(nails[2]) and #calls("tradingUISendRemoveItem") == 1)
    -- accept
    s:setSealed(true)
    fire("TradingUIUpdateState", P2, P1, "DealWasSealed")
    draw()
    local acc = zone("oc:foot:accept")
    check("Accept deal runs once both are sealed", acc and acc.run ~= nil)
    clearCalls()
    if acc then acc.run(CARD, P1) end
    check("Accept deal: DealWasFinalized, once", #calls("tradingUISendUpdateState") == 1 and lastState() == "DealWasFinalized")
    check("Accept deal: the trade is over and the card closed", TR.get(P1) == nil and CARD.entry == nil)
    check("Accept deal: the game no longer finds a trade", ISTradingUI.GetUIForPlayer(P1) == nil)
    check("Accept deal: the stand-in is no longer visible", not ISTradingUI.isVisible(s.element))
end

-- their request: Yes
clearCalls()
fire("RequestTrade", P2, P1)
local q = MODALS[#MODALS]
check("their request: the game's question (a ZeD prompt in game)", q ~= nil and q.text == getText("IGUI_TradingUI_RequestTrade", "Bobby"))
if q then answer(q, "YES") end
local s2 = TR.get(P1)
check("Yes: ZeD's trade opens, not vanilla's window", s2 ~= nil and NEWS.tradingUI == 0 and CARD.entry and CARD.entry.def.id == "trade")
check("Yes: acceptTrading(you, them, true)", #calls("acceptTrading") == 1 and calls("acceptTrading")[1].args[3] == true)
check("Yes: not blocked (no request of yours pending)", s2 and not s2.pending and s2.blocking == nil)
check("Yes: no requestTrading", #calls("requestTrading") == 0)
-- they close theirs
if s2 then
    fire("TradingUIUpdateState", P2, P1, "WindowWasClosed")
    check("they closed: blocked with vanilla's words", s2.blocking == getText("IGUI_TradingUI_ClosedTrade", "Bobby"))
    -- the card's close key: Cancel, sent once
    clearCalls()
    CARD:close()
    check("closing the card: WindowWasClosed, once", #calls("tradingUISendUpdateState") == 1 and lastState() == "WindowWasClosed")
    check("closing the card: the trade is over", TR.get(P1) == nil)
end
-- their request: No
clearCalls()
fire("RequestTrade", P2, P1)
q = MODALS[#MODALS]
if q then answer(q, "NO") end
check("No: acceptTrading(you, them, false), no trade", #calls("acceptTrading") == 1 and calls("acceptTrading")[1].args[3] == false and TR.get(P1) == nil)
-- they give up while you are still being asked: the question goes (vanilla's handler, no trade open)
fire("RequestTrade", P2, P1)
q = MODALS[#MODALS]
q:addToUIManager()
fire("TradingUIUpdateState", P2, P1, "WindowWasClosed")
check("they gave up: the question is put away", not q:isVisible())
-- refused
ISWorldObjectContextMenu.onTrade({}, P1, P2)
local s3 = TR.get(P1)
fire("AcceptedTrade", P2, P1, false)
check("they said no: blocked with vanilla's words", s3 and s3.blocking == getText("IGUI_TradingUI_RefusedTrade", "Bobby"))
-- pinned (the director, Nov 7 2026): only Cancel, their close, distance or them leaving end the trade
if s3 then
    local function shown() local c = ZeD_WorldWindow.getObjectCard(); return c and c.entry and c.entry.t and c.entry.t.s == s3 and WIN._drawerOpen and WIN._drawerItem == nil end
    clearCalls()
    -- an item card opens over it
    WIN._drawerItem = apple
    dropObject(false)
    tick(5)
    check("pinned: an item card opens over the trade, which stays open", s3.open and #calls("tradingUISendUpdateState") == 0)
    check("pinned: the trade card stays in the drawer under the item card", WIN._drawerObject and WIN._drawerObject.t.s == s3 and WIN._drawerItem == apple)
    WIN._drawerItem = nil
    tick(1)
    check("pinned: the item card closes, the trade is back", shown())
    -- a tab switch folds the drawer
    dropObject(false)
    WIN._drawerOpen = false
    tick(1)
    check("pinned: a tab switch, the trade is back", shown() and s3.open)
    -- another object card takes the drawer
    ZeD_WorldWindow.openObjectCard(0, { def = { id = "generator" }, t = {} })
    tick(3)
    check("pinned: another card in its place does not end the trade", s3.open and #calls("tradingUISendUpdateState") == 0)
    check("pinned: the other card is left alone while open", WIN._drawerObject.def.id == "generator")
    ZeD_WorldWindow.closeObjectCard()
    tick(1)
    check("pinned: the other card closes, the trade is back", shown())
    -- the World window shut
    WIN_OPEN = false
    tick(10)
    check("pinned: the World window shut does not end the trade", s3.open and #calls("tradingUISendUpdateState") == 0)
    WIN_OPEN, WIN._drawerObject, CARD.entry = true, nil, nil
    tick(1)
    check("pinned: the window opens again, the trade card is back", shown())
    WIN_OPEN = false
    fire("TradingUIUpdateState", P2, P1, "DealWasUnsealed")
    check("pinned: their next move opens the window on the trade", WIN_OPEN and shown())
    -- its own close is Cancel
    CARD:close()
    check("pinned: the card's close key still cancels", not s3.open and lastState() == "WindowWasClosed")
end
-- a narrow card stacks the offers
ISWorldObjectContextMenu.onTrade({}, P1, P2)
local s4 = TR.get(P1)
if s4 then
    fire("AcceptedTrade", P2, P1, true)
    s4:addItem(nails[1])
    CARD.width = 300
    draw()
    local r = zone("tr:rm:" .. nails[1]:getID())
    check("a narrow card: your offer full width (stacked)", r and r.x + r.w > 240, r and (r.x + r.w))
    CARD.width = 480
    -- the stops: unique
    local seen, dup = {}, nil
    for _, el in ipairs(CARD:buildFocusables(WIN)) do if seen[el.id] then dup = el.id end seen[el.id] = true end
    check("the card's stops are unique", dup == nil, dup)
    check("the controller lands on the first Add", CARD.entry.def.openFocus(CARD.entry.t) == "tr:add:Apple")
    s4:cancel()
end
-- safe mode: vanilla's window
SAFE = true
ISWorldObjectContextMenu.onTrade({}, P1, P2)
check("safe mode: the game's own trading window", NEWS.tradingUI == 1 and TR.get(P1) == nil, NEWS.tradingUI)
local vui = ISTradingUI.GetUIForPlayer(P1)
-- a trade opened in safe mode keeps vanilla's handlers to its end
local okE = pcall(fire, "AcceptedTrade", P2, P1, true)
check("safe mode: the events reach vanilla's window", okE and vui and vui.blockingMessage == nil)
if vui then vui:close(); ISTradingUI.windows[1] = nil end
SAFE = false

-- ===========================================================================
-- MEDICAL CHECK
-- ===========================================================================
local function startCheck()
    PERFORMED = {}
    local a = ISMedicalCheckAction:new(P1, P2)
    a:perform()
    return a
end
P2.x, P2.y = 101.5, 100.5
P1.doctor = 0
local hand = P2.remote.byType[BodyPartType.Hand_L]
hand.f.deepWounded = true; hand.f.deepWoundTime = nil; hand.f.getDeepWoundTime = 12; hand.health = 40
P2.remote.overall = 72
P2.remote.pain = 3
local recv0 = P1.recv
local a = startCheck()
check("the check's end: ZeD's card, not the game's health panel", NEWS.healthPanel == 0 and CARD.entry and CARD.entry.def.id == "medic", NEWS.healthPanel)
check("the check's end: the action finishes (ISBaseTimedAction.perform)", PERFORMED[1] == a)
check("the check's end: the doctor receives the patient's body", P1.recv == recv0 + 1)
if CARD.entry and CARD.entry.def.id == "medic" then
    local t = CARD.entry.t
    draw()
    check("a server: the remote body is read", t.d and math.floor(t.d.overall + 0.5) == 72)
    check("title: vanilla's words with their name", CARD.entry.def.title(t) == getText("IGUI_health_playerHealth", "Bobby"))
    local en = t.d and t.d.entries[1]
    check("the injury list: the left hand first", en and en.name ~= nil and en.bodyPart == hand)
    local label = en and en.conditions[1] and en.conditions[1].label
    check("a First Aid 0 doctor: a deep wound without its severity", label == getText("IGUI_health_DeepWound"), label)
    check("a First Aid 0 doctor: no pain line", t.pain == nil)
    -- a First Aid 5 doctor (a new check)
    CARD:close()
    P1.doctor = 5
    startCheck()
    t = CARD.entry.t
    draw()
    en = t.d.entries[1]
    label = en.conditions[1].label
    check("a First Aid 5 doctor: the severity", label == getText("UI_ZeD_Health_Qualified", getText("IGUI_health_DeepWound"), getText("IGUI_health_Severe")) or label:find(getText("IGUI_health_Severe"), 1, true) ~= nil, label)
    check("a First Aid 5 doctor: their pain", t.pain == 3)
    -- the parts are stops that open the game's treatment menu
    local rowZ = zone("mc:part:" .. tostring(en.name))
    local figZ = zone("mc:fig:Upper Torso")
    check("an injury row is a stop", rowZ and rowZ.run ~= nil and rowZ.body)
    check("a figure part is a stop", figZ and figZ.run ~= nil)
    local bandage = newItem("Bandage", P1.inv, { ftype = "Base.Bandage", bandage = 1 })
    MENUS, QUEUE = {}, {}
    rowZ.run(CARD, P1)
    local m = MENUS[1]
    check("treatment: the game's menu, for the doctor's screen", m ~= nil and m.playerNum == P1:getPlayerNum())
    local opt = nil
    for _, o in ipairs(m and m.options or {}) do if o.name == getText("ContextMenu_Bandage") then opt = o end end
    check("treatment: Bandage offered (the doctor's bandage)", opt ~= nil and opt.sub ~= nil)
    local sub = opt and opt.sub and opt.sub.options[1]
    if sub then sub.onSelect(sub.target, sub.args[1]) end
    local act = QUEUE[#QUEUE]
    check("treatment: the game's own HealthPanelAction, done by the doctor", act and act.character == P1 and act.handler ~= nil)
    check("treatment: on the patient", act and act.handler:getPatient() == P2 and act.handler:getDoctor() == P1)
    -- paused: no menu, as vanilla's list
    SPEED, MENUS = 0, {}
    rowZ.run(CARD, P1)
    check("paused: no treatment menu", #MENUS == 0)
    SPEED = 1
    -- the patient moves: the card closes and the updates stop
    local r0 = P1.recv
    P2.x = P2.x + 0.6
    draw()
    check("the patient moved: the card closes", CARD.entry == nil)
    check("the patient moved: the doctor stops receiving the body", P1.recv == r0 - 1)
    P2.x = 101.5
    -- staff (CanMedicalCheat) from afar: blocked past 2 tiles, the body restored and the updates stop, then back
    P1.caps.CanMedicalCheat = true
    startCheck()
    t = CARD.entry and CARD.entry.t
    local r1, rest0 = P1.recv, P2.remote.restored
    P2.x = 105
    draw()
    check("staff past 2 tiles: still open, blocked with vanilla's words", CARD.entry ~= nil and t and t.blocking == getText("IGUI_TradingUI_TooFarAway", "Bobby"))
    check("staff past 2 tiles: updates stop, the remote body restored (as vanilla)", P1.recv == r1 - 1 and P2.remote.restored == rest0 + 1)
    check("staff past 2 tiles: no treatment", zone("mc:part:" .. tostring(en.name)) == nil)
    P2.x = 101.5
    draw()
    check("staff close again: unblocked, updates again", t and t.blocking == nil and P1.recv == r1)
    CARD:close()
    P1.caps.CanMedicalCheat = nil
    -- the same car: either may move
    P1.seated, P2.seated = true, true
    local car = {}
    P1.vehicle, P2.vehicle = car, car
    startCheck()
    P2.x = P2.x + 1
    draw()
    check("the same car: the card stays open", CARD.entry ~= nil)
    CARD:close()
    P1.seated, P2.seated, P1.vehicle, P2.vehicle = false, false, nil, nil
    P2.x = 101.5
end
-- single player / split screen: the local body, read directly
CLIENT, MP = false, false
P2.local_ = true
P2.body.overall = 55
CARD:close()
startCheck()
if CARD.entry and CARD.entry.def.id == "medic" then
    draw()
    check("split screen: the other local player's own body", math.floor(CARD.entry.t.d.overall + 0.5) == 55)
    check("split screen: their name from the descriptor", CARD.entry.def.title(CARD.entry.t) == getText("IGUI_health_playerHealth", "Bobby Doe"))
    CARD:close()
else
    check("split screen: the card opens", false)
end
-- the World window belongs to another split-screen player: the game's own panel
WIN._playerObj = P2
startCheck()
check("the World window is another player's: the game's own health panel", NEWS.healthPanel == 1, NEWS.healthPanel)
WIN._playerObj = P1
CLIENT, MP = true, true
P2.local_ = false

-- ===========================================================================
-- every library name drawn with exists in the real files
-- ===========================================================================
local function realNames(file, prefix)
    local src = readFile(ZL .. "client/ZeD/" .. file) or ""
    local out = {}
    for n in src:gmatch("function " .. prefix .. "%.([%w_]+)") do out[n] = true end
    for n in src:gmatch(prefix .. "%.([%w_]+)%s*=[^=]") do out[n] = true end
    return out
end
local realM = realNames("Molecules.lua", "ZeD%.Molecules")
local realA = realNames("Atoms.lua", "ZeD%.Atoms")
for k, v in pairs(realNames("AtomExtensions.lua", "ZeD%.Atoms")) do realA[k] = v end
for k in pairs(USED.Molecules) do check("ZeD.Molecules." .. k .. " exists", realM[k] == true) end
for k in pairs(USED.Atoms) do check("ZeD.Atoms." .. k .. " exists", realA[k] == true) end
for k in pairs(MISSING_WORDS) do check("the word " .. k .. " exists (the game's or ZeD's English)", false) end

print("trade_medic_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed > 0 and 1 or 0)
