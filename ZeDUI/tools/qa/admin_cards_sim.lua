-- ZeDUI/tools/qa/admin_cards_sim.lua  (Nov 5 2026, QA): the Admin tab and its cards with no game running.
-- The harness is ticket_cards_sim.lua's: the real Tokens, Tr, Atoms, Molecules, ZeD_TicketCards, ZeD_Admin, ZeD_AdminCards and
-- AdminTab on Lua 5.1 stubs of a panel, text measures from the fonts' own sizes, the windows and the focus manager. It draws
-- every state of mp_admin_cards.lua at Deck, 720, 1080 and 4K, Normal and Large text, mouse and pad; checks what drew (nothing
-- past the drawer's edges, no field outside its view, stops unique and whole, every grayed stop saying why), then walks the
-- flows: Find, a player's card, Kick, Ban, warning points, a role change and its powers, Level Up, Mute, the server message and
-- its Stop list, Roles, Delete role behind its confirm, Bans, Unban behind its confirm, Spawn items, the Tickets screen, the
-- fallback. It proves the logic and the sums. What it cannot prove is what the engine does: the text box, the keyboard, focus
-- landing, real font widths.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/admin_cards_sim.lua
-- It prints FAIL lines and a last line "admin_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]admin_cards_sim%.lua$", "")
-- Kahlua has no next() (KB Q221): take it away here too, so a file that calls it fails in the sim as it would in the game
next = nil

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the clock, the game's globals -----------------------------------------------------------
local nowMs = 1000000
function getTimestampMs() return nowMs end
function getTimestamp() return math.floor(nowMs / 1000) end
function triggerEvent() end
function isClient() return true end
function isServer() return false end
function isMouseButtonDown() return false end
ZEDQA_CAPS = { TeleportToCoordinates = true, CanSeePlayersStats = true, AnswerTickets = true }
Capability = setmetatable({}, { __index = function(_, k) return k end })
local ROLE = { hasCapability = function(_, c) return ZEDQA_CAPS[c] == true end, getName = function() return "admin" end, hasAdminTool = function() return true end, hasAdminPower = function() return false end }
local PLAYER = { getUsername = function() return "Aretha" end, getX = function() return 6347.4 end, getY = function() return 5372.2 end, getZ = function() return 0 end,
    getRole = function() return ROLE end, getHoursSurvived = function() return 200 end, getSafety = function() return nil end, getPlayerNum = function() return 0 end }
function getPlayer() return PLAYER end
function getSpecificPlayer() return PLAYER end
local ONLINE = true
function getPlayerFromUsername(u) return ONLINE and { getUsername = function() return u end } or nil end
function getGameTime() return { getWorldAgeHours = function() return 270 end } end
function getSoundManager() return { playUISound = function() end } end
function getCore() return { getOptionFontSizeReal = function() return 1 end, getScreenWidth = function() return 1280 end, getScreenHeight = function() return 800 end } end
function getServerOptions() return { getOption = function() return "Knox Survivors" end, getBoolean = function() return false end, getInteger = function() return 0 end } end
function getServerName() return "Knox" end
function scoreboardUpdate() end
getCapabilities = function()
    local list = {}
    for _, n in ipairs(ZeD.Admin.qaAllCaps or {}) do list[#list + 1] = { name = function() return n end } end
    return { size = function() return #list end, get = function(_, i) return list[i + 1] end }
end
SafeHouse = { hasSafehouse = function() return nil end, getSafehouseList = function() return nil end }
Faction = { getPlayerFaction = function() return nil end, getFactions = function() return nil end }
NonPvpZone = { getNonPvpZone = function() return nil end }
JoypadState = { players = {} }
Joypad = {}
Keyboard = { KEY_ESCAPE = 1 }
Translator = { getLanguage = function() return { name = function() return "EN" end } end, getAvailableLanguage = function() return nil end }
UIFont = setmetatable({}, { __index = function(_, k) return k end })
local TEXT = {}
do
    local f = assert(io.open(ROOT .. "42/media/lua/shared/Translate/EN/UI.json", "rb"))
    local s = f:read("*a")
    f:close()
    for k, v in s:gmatch('"([%w_]+)": "(.-)",?%s*\n') do TEXT[k] = v end
end
TEXT.UI_Cancel, TEXT.UI_userpanel_tickets = "Cancel", "Tickets"
TEXT.IGUI_UserList_BannedIPs_Refresh = "Refresh"
TEXT.UI_Scoreboard_Teleport, TEXT.UI_Scoreboard_TeleportToYou, TEXT.UI_Scoreboard_Mute, TEXT.UI_Scoreboard_Unmute = "Teleport", "Teleport To You", "Mute", "Unmute"
TEXT.IGUI_UserList_Kick, TEXT.IGUI_UserList_Ban, TEXT.IGUI_UserList_UnBan, TEXT.IGUI_UserList_AddWarningPoint = "Kick", "Ban", "Unban", "Add Warning Points"
TEXT.IGUI_PlayerStats_UserLogs, TEXT.IGUI_PlayerStats_LevelUp, TEXT.IGUI_PlayerStats_LevelDown = "User Logs", "Level Up", "Level Down"
TEXT.IGUI_PlayerStats_ManageInventory = "Manage this player's Inventory"
TEXT.IGUI_RolesList_AddRole, TEXT.IGUI_RolesList_DeleteRole, TEXT.IGUI_RolesList_Save, TEXT.IGUI_RolesList_Up, TEXT.IGUI_RolesList_Down, TEXT.IGUI_RolesList_Edit = "Add role", "Delete role", "Save", "Up", "Down", "Edit"
TEXT.IGUI_RolesList_SetDefaultForNewUser = "Set default for New User"
TEXT.IGUI_AdminPanel_AdminPower = "Edit your Admin Powers"
TEXT.IGUI_AdminPanel_SeeServerOptions, TEXT.IGUI_AdminPanel_SandboxOptions, TEXT.IGUI_AdminPanel_PVPLogTool, TEXT.IGUI_AdminPanel_ZoneEditor = "See Server Options", "Sandbox Options", "PVP Log Tool", "Zone Editor"
TEXT.IGUI_AdminPanel_NonPvpZone, TEXT.IGUI_AdminPanel_Safezone, TEXT.IGUI_AdminPanel_ShowStatistics, TEXT.IGUI_Adm_Weather_ClimateControl = "Non PVP Zone", "Add Safezone", "Show Statistics", "Climate Control"
TEXT.IGUI_CheatPanel_Invisible, TEXT.IGUI_CheatPanel_GodMod, TEXT.IGUI_CheatPanel_NoClip = "Invisible", "God Mode", "No Clip"
TEXT.IGUI_CheatPanel_Invisible_tooltip, TEXT.IGUI_CheatPanel_GodMod_tooltip, TEXT.IGUI_CheatPanel_NoClip_tooltip = "Can't be seen or heard by other players.", "Makes you immune to all damage.", "Move through walls and collision tiles."
TEXT.IGUI_CapabilitiesTooltips_KickUser = "Player can kick other players from the server. Use /kick or /kickuser console commands."
-- punch list 95's new keys, until UI.json carries them (the same English)
TEXT.UI_ZeD_Adm_SpawnLineMe = TEXT.UI_ZeD_Adm_SpawnLineMe or "%1 x %2 to you"
TEXT.UI_ZeD_Adm_SpawnLineGround = TEXT.UI_ZeD_Adm_SpawnLineGround or "%1 x %2 to the ground"
TEXT.UI_ZeD_Adm_SpawnedMe = TEXT.UI_ZeD_Adm_SpawnedMe or "%1 x %2 spawned to you. Logged."
TEXT.UI_ZeD_Adm_SpawnedGround = TEXT.UI_ZeD_Adm_SpawnedGround or "%1 x %2 spawned to the ground. Logged."
TEXT.UI_ZeD_Adm_NoItemMatch = TEXT.UI_ZeD_Adm_NoItemMatch or "No items match."
-- the game's words the stats and inventory cards use
for k, v in pairs({ IGUI_PlayerStats_Change = "Change", IGUI_PlayerStats_Username = "Username:", IGUI_PlayerStats_DisplayName = "Display Name:",
    UI_characreation_forename = "Forename", UI_characreation_surname = "Surname", IGUI_PlayerStats_Profession = "Profession:", IGUI_char_Survived_For = "Survived For",
    IGUI_char_Zombies_Killed = "Zombies Killed", IGUI_char_Weight = "Weight", IGUI_char_Traits = "Traits", IGUI_PlayerStats_AddTrait = "Add Trait",
    IGUI_PlayerStats_AddTraitTitle = "Add Trait", IGUI_PlayerStats_AddTraitTooltip = "Will add trait, but not skill levels or XP multiplier. Skill levels can be added below.",
    IGUI_PlayerStats_AddXP = "Add XP", IGUI_PlayerStats_AddXPTitle = "Add XP", IGUI_PlayerStats_Amount = "Amount", IGUI_PlayerStats_AddXPMultipliers = "Use XP multipliers",
    IGUI_PlayerStats_Level = "Level", IGUI_PlayerStats_XP = "XP", IGUI_PlayerStats_Boost = "Boost", IGUI_PlayerStats_Multiplier = "Multiplier",
    IGUI_PlayerStats_WarningPts = "Warning Points:", IGUI_PlayerStats_Add = "Add", IGUI_PlayerStats_WarningPointTitle = "Add Warning Points",
    IGUI_PlayerStats_AddLog = "Add Log", IGUI_PlayerStats_AddLogOn = "Add log on %1", IGUI_PlayerStats_RemoveLogConfirm = "Are you sure you want to remove this log?",
    IGUI_PlayerStats_ChangeProfTitle = "Change Profession", IGUI_PlayerStats_SameName = "%1 is the same", ContextMenu_Remove = "Remove",
    IGUI_RolesList_Save = "Save", UI_servers_refresh = "REFRESH", IGUI_invpanel_Condition = "Condition", IGUI_ItemCat_Weapon = "Weapon" }) do TEXT[k] = TEXT[k] or v end
getItemName = function(full) return (string.gsub(full, "^Base%.", "")) end
getItemTex = function() return nil end
getItemConditionMax = function() return 10 end
INVCALLS = {}
InvMngRemoveItem = function(id, oid, user) INVCALLS[#INVCALLS + 1] = "rm:" .. tostring(id) .. ":" .. tostring(oid) .. ":" .. tostring(user) end
InvMngGetItem = function(id, full, oid, user) INVCALLS[#INVCALLS + 1] = "get:" .. tostring(id) .. ":" .. tostring(full) .. ":" .. tostring(oid) .. ":" .. tostring(user) end
sendRequestInventory = function(oid, user) INVCALLS[#INVCALLS + 1] = "ask:" .. tostring(oid) .. ":" .. tostring(user) end
function getText(k, ...)
    local s = TEXT[k] or k
    return s
end
getTextOrNull = function(k) return TEXT[k] end
local SENT, COMMANDS, GAME = {}, {}, {}
function sendClientCommand(p, m, c, a) SENT[#SENT + 1] = { m = m, c = c, a = a } end
function SendCommandToServer(s) COMMANDS[#COMMANDS + 1] = s end
SEND = {}
function SendCommandToServer(s) SEND[#SEND + 1] = s end
GAMECALLS = {}
local function game(name) return function(...)
    local parts = { name }
    for _, v in ipairs({ ... }) do parts[#parts + 1] = tostring(v) end
    GAMECALLS[#GAMECALLS + 1] = table.concat(parts, ":")
end end
addWarningPoint, networkUserAction, banUnbanUserAction, addRole, deleteRole, moveRole, setDefaultRoleFor = game("warn"), game("net"), game("ban"), game("addRole"), game("deleteRole"), game("moveRole"), game("default")
setupRole = function(role, desc, color, capsT)
    local n = 0
    for k, v in pairs(capsT) do if v then n = n + 1 end end
    GAMECALLS[#GAMECALLS + 1] = "setup:" .. tostring(role and role.name) .. ":" .. tostring(desc) .. ":" .. n
end
requestUsers, requestRoles, requestUserlog, getBannedIPs, getBannedSteamIDs = function() end, function() end, function() end, function() end, function() end
getUsers = function() return { size = function() return 0 end } end
getSteamModeActive = function() return false end
getCurrentUserSteamID = function() return nil end
forceDisconnect, sendPlayerExtraInfo = game("leave"), game("extra")
Color = { new = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end }
ISPlayerStatsManageInvUI = { opened = 0 }
function ISPlayerStatsManageInvUI:new() ISPlayerStatsManageInvUI.opened = ISPlayerStatsManageInvUI.opened + 1; return { initialise = function() end, addToUIManager = function() end } end
ISAdminPowerUI = { OptionList = {}, OptionById = {} }
for _, id in ipairs({ "Invisible", "GodMod", "NoClip", "UnlimitedCarry" }) do
    local o = { id = id, text = id, capability = id, value = false }
    function o:getValue() return self.value end
    function o:setValue(v) self.value = v end
    ISAdminPowerUI.OptionList[#ISAdminPowerUI.OptionList + 1] = o
    ISAdminPowerUI.OptionById[id] = o
end
function getTickets(who) GAME[#GAME + 1] = { "get", who } end
function addTicket(a, b, c) GAME[#GAME + 1] = { "add", a, b, c } end
function removeTicket(id) GAME[#GAME + 1] = { "remove", id } end
function viewedTicket(a, b) GAME[#GAME + 1] = { "viewed", a, b } end

local EVENTS = setmetatable({}, { __index = function(t, k)
    local e = { list = {} }
    e.Add = function(fn) e.list[#e.list + 1] = fn end
    e.Remove = function(fn) for i = #e.list, 1, -1 do if e.list[i] == fn then table.remove(e.list, i) end end end
    rawset(t, k, e)
    return e
end })
Events = EVENTS
LuaEventManager = { AddEvent = function() end }

-- the game's classes the files derive ------------------------------------------------------
ISUIElement = {}
ISPanel = {}
ISPanel.__index = ISPanel
function ISPanel:derive(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.Type = name
    return o
end
function ISPanel:new(x, y, w, h)
    local o = { x = x, y = y, width = w, height = h, visible = true, kids = {} }
    setmetatable(o, self)
    self.__index = self
    return o
end
function ISPanel:initialise() end
function ISPanel:instantiate() end
function ISPanel:createChildren() end
function ISPanel:update() end
function ISPanel:prerender() end
function ISPanel:render() end
function ISPanel:addChild(c)
    self.kids[#self.kids + 1] = c
    if c.createChildren then c:createChildren() end
end
function ISPanel:setVisible(v) self.visible = v end
function ISPanel:isVisible() return self.visible end
function ISPanel:getX() return self.x end
function ISPanel:getY() return self.y end
function ISPanel:getWidth() return self.width end
function ISPanel:getHeight() return self.height end
function ISPanel:setX(v) self.x = v end
function ISPanel:setY(v) self.y = v end
function ISPanel:setWidth(v) self.width = v end
function ISPanel:setHeight(v) self.height = v end
function ISPanel:drawRect() end
function ISPanel:drawRectBorder() end
function ISPanel:drawText() end

ISTextEntryBox = ISPanel:derive("ISTextEntryBox")
function ISTextEntryBox:new(text, x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.text = text or ""
    o.javaObject = { setMaxLines = function(_, n) o.maxL = n end, setMaxTextLength = function(_, n) o.maxT = n end, setCentreVertically = function() end }
    return o
end
function ISTextEntryBox:setMultipleLine() end
function ISTextEntryBox:setPlaceholderText() end
function ISTextEntryBox:setMaxTextLength(n) self.maxT = n end
function ISTextEntryBox:getText() return self.text end
function ISTextEntryBox:setText(s) self.text = s end
function ISTextEntryBox:focus() self.hasFocus = true end
function ISTextEntryBox:unfocus() self.hasFocus = false end
function ISTextEntryBox:isFocused() return self.hasFocus == true end

ISMouseDrag = {}
ISPlayerStatsUI = { opened = 0 }
function ISPlayerStatsUI:new()
    ISPlayerStatsUI.opened = ISPlayerStatsUI.opened + 1
    return { initialise = function() end, addToUIManager = function() end }
end
ISAdminMessage = { AddAdminMessage = function() end }

-- the files --------------------------------------------------------------------------------
local LOADED = {}
local STUBBED = { ["ZeD/ZeD_CharacterWindow"] = true, ["ZeD/ZeD_WorldWindow"] = true, ["ZeD/ZeD_TabPx"] = true, ["ZeD/ZeD_Messages"] = true }
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
-- measures from the font's own size: a little wider than Fira's real average, so this errs on the side of too long
-- the five role fonts' sizes (Tokens.lua: ZeD.TextSizes), Normal and Large
local function fontPx(font)
    local T, big = ZeD.T, ZEDQA_LARGE
    if font == T.fontF1 then return big and 13 or 11 end
    if font == T.fontF2 then return big and 15 or 13 end
    if font == T.fontF3 then return big and 13 or 11 end
    if font == T.fontF4 then return big and 17 or 15 end
    if font == T.fontF5 then return big and 11 or 9 end
    return 11
end
ZeD.TM = {
    MeasureStringX = function(_, font, s) return math.ceil(#tostring(s) * fontPx(font) * ZeD.T.root * 0.60) end,
    MeasureStringY = function(_, font, s) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
    getFontHeight = function(_, font) return math.ceil(fontPx(font) * ZeD.T.root * 1.3) end,
}
ZeD.Scale = { root = function() return ZEDQA_ROOT or 1 end }
ZeD.Help = { set = function(_, s) ZeD.Help.last = s end }
ZeD.Surface = nil
ZeD.Focus = { mark = function(panel, x, y, w, h, f) ZEDQA_MARKS = (ZEDQA_MARKS or 0) + 1; return true end }
ZeD.Messages = { ticket = function() end, ticketNew = function() end }
ZeD.PadGlyphs = nil
ZeD.btnCase = function(s) return s end
ZeD.upper = function(s) return string.upper(s) end

local TABS = {}
ZeD_CharacterWindow = { addTab = function(def) TABS.server = def end }
ZeD_WorldWindow = { addTab = function(def) TABS.admin = def end }

local FOCUS = { id = nil, pad = false, soon = {} }
ZeD.Input = { Focus = {
    isFocused = function(_, _, id) return FOCUS.pad and id == FOCUS.id end,
    cuesVisible = function() return FOCUS.pad end,
    focusSoon = function(_, zone, pred) FOCUS.soon[#FOCUS.soon + 1] = { zone = zone, pred = pred } end,
    getFocusedWindow = function() return FOCUS.win end,
    getFocusedElement = function() return FOCUS.el end,
} }

require "ZeD/Tokens"
do
    -- (Kahlua's string.char takes wide characters, the test language's letters; Lua 5.1's does not)
    local char = string.char
    string.char = function(...)
        local a = { ... }
        for i, v in ipairs(a) do if v > 255 then a[i] = 63 end end
        return char(unpack(a))
    end
end
require "ZeD/Tr"
ZeD.tr = ZeD.tr
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
ZeD.btnCase = ZeD.btnCase or function(s) return s end
require "ZeD/ServerTab"
require "ZeD/AdminTab"
local TC, C, S, Tk = ZeD.TicketCards, ZeD.Tickets, ZeD.ServerPart, ZeD.Tk
ZeD.applyTheme("dark", "orange", "small")
check("the real files load", TC ~= nil and TABS.server ~= nil and TABS.admin ~= nil)

ZEDQA_CARDS_SIM = true
local Q = assert(loadfile(ROOT .. "ZeDUI/tools/qa/mp_admin_cards.lua"))()

-- the stub panel: every draw is checked against the drawer ---------------------------------
local function newPanel(w, h)
    local p = { w = w, h = h, texts = {}, kids = {}, mx = -1, my = -1 }
    function p:getWidth() return self.w end
    function p:getHeight() return self.h end
    function p:getMouseX() return self.mx end
    function p:getMouseY() return self.my end
    function p:getAbsoluteX() return 0 end
    function p:getAbsoluteY() return 0 end
    local function op(self, o)
        if ZEDQA_SVG then
            o.clip = self.st
            self.ops[#self.ops + 1] = o
        end
    end
    p.op = op
    p.ops = {}
    function p:drawRect(x, y, ww, hh, a, r, g, b)
        assert(type(x) == "number" and type(y) == "number" and type(ww) == "number" and type(hh) == "number", "drawRect args")
        assert(type(b) == "number", "drawRect color")
        op(self, { k = "r", x = x, y = y, w = ww, h = hh, a = a, r = r, g = g, b = b })
    end
    function p:drawRectBorder(x, y, ww, hh, a, r, g, b)
        assert(type(b) == "number", "drawRectBorder color")
        op(self, { k = "b", x = x, y = y, w = ww, h = hh, a = a, r = r, g = g, b = b })
    end
    function p:drawText(s, x, y, r, g, b, a, font)
        assert(type(s) == "string", "drawText words: " .. tostring(s))
        assert(type(a) == "number", "drawText alpha")
        assert(font ~= nil, "drawText font")
        self.texts[#self.texts + 1] = { s = s, x = x, y = y, w = ZeD.TM:MeasureStringX(font, s), font = font }
        op(self, { k = "t", s = s, x = x, y = y, a = a, r = r, g = g, b = b, font = font })
    end
    function p:drawTexture() end
    function p:drawTextureScaled() end
    function p:drawTextureScaledAspect() end
    function p:setStencilRect(x, y, ww, hh) self.st = { x = x, y = y, w = ww, h = hh } end
    function p:clearStencilRect() self.st = nil end
    function p:addChild(c)
        self.kids[#self.kids + 1] = c
        if c.createChildren then c:createChildren() end
    end
    return p
end

local WINS = { server = { _playerObj = PLAYER, playerNum = 0 }, admin = { _playerObj = PLAYER, playerNum = 0 } }
local function stOf(tab)
    return (tab == "server") and WINS.server._serverTab or WINS.admin._adminTab
end

-- ZEDQA_SVG=<folder>: each state of a profile named in ZEDQA_SVG_ONLY is written as a picture, to read against the mockup
ZEDQA_SVG = os.getenv and os.getenv("ZEDQA_SVG")
local function esc(s) return (string.gsub(string.gsub(string.gsub(s, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")) end
local function hex(c) return string.format("#%02x%02x%02x", math.floor(c.r * 255), math.floor(c.g * 255), math.floor(c.b * 255)) end
local function writeSvg(panel, name)
    local out = { string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" font-family="Fira Sans, Segoe UI, sans-serif">', panel.w, panel.h) }
    local T = ZeD.T
    out[#out + 1] = string.format('<rect width="%d" height="%d" fill="%s"/>', panel.w, panel.h, hex(T.base))
    local n = 0
    for _, o in ipairs(panel.ops) do
        local clip = ""
        if o.clip then
            n = n + 1
            out[#out + 1] = string.format('<clipPath id="%s%d"><rect x="%d" y="%d" width="%d" height="%d"/></clipPath>', name, n, o.clip.x, o.clip.y, o.clip.w, o.clip.h)
            clip = string.format(' clip-path="url(#%s%d)"', name, n)
        end
        if o.k == "r" then
            out[#out + 1] = string.format('<rect x="%g" y="%g" width="%g" height="%g" fill="%s" fill-opacity="%.2f"%s/>', o.x, o.y, o.w, o.h, hex(o), o.a or 1, clip)
        elseif o.k == "b" then
            out[#out + 1] = string.format('<rect x="%g" y="%g" width="%g" height="%g" fill="none" stroke="%s" stroke-opacity="%.2f"%s/>', o.x, o.y, o.w, o.h, hex(o), o.a or 1, clip)
        else
            local px = math.ceil(fontPx(o.font) * T.root)
            local mono = o.font == T.fontF1 or o.font == T.fontF3
            out[#out + 1] = string.format('<text x="%g" y="%g" font-size="%d" fill="%s" fill-opacity="%.2f"%s%s>%s</text>', o.x, o.y + px, px, hex(o), o.a or 1,
                mono and ' font-family="Fira Mono, Consolas, monospace"' or "", clip, esc(o.s))
        end
    end
    for _, c in ipairs(panel.kids) do
        if c.visible then
            local text = c:getText()
            out[#out + 1] = string.format('<text x="%g" y="%g" font-size="%d" fill="#888">%s</text>', c.x + 6, c.y + 16, 12, esc(text ~= "" and text or (c.placeholder or "")))
        end
    end
    out[#out + 1] = "</svg>"
    local f = assert(io.open(ZEDQA_SVG .. "/" .. name .. ".svg", "wb"))
    f:write(table.concat(out, string.char(10)))
    f:close()
end

-- a frame of a tab, then its children as the engine would draw them; returns the panel
local function frame(tab, panel, w, h)
    panel.texts = {}
    panel.ops = {}
    TABS[tab].render(panel, WINS[tab], 0, 0, w, h)
    for _, c in ipairs(panel.kids) do
        if c.visible then c:prerender() end
    end
    local t = stOf(tab) and stOf(tab).tk
    if t and t.qaPopNext then
        local k = t.qaPopNext
        t.qaPopNext = nil
        TC._D.openPopup(stOf(tab), t, k)
        panel.texts = {}
        panel.ops = {}
        TABS[tab].render(panel, WINS[tab], 0, 0, w, h)
    end
    return panel
end

local function stops(tab) return TABS[tab].buildFocusables(WINS[tab]) end

-- what must hold in a drawn frame
local function verify(name, tab, panel, w, h)
    for _, t in ipairs(panel.texts) do
        if t.x + t.w > w + 1 or t.x < -1 then
            check(name .. ": text inside the drawer", false, t.s .. " at " .. t.x .. "+" .. t.w .. " of " .. w)
        end
    end
    checks = checks + 1
    local list = stops(tab)
    local seen = {}
    for _, e in ipairs(list) do
        check(name .. ": a stop has an id", type(e.id) == "string", tostring(e.id))
        check(name .. ": stop unique " .. tostring(e.id), not seen[e.id])
        seen[e.id] = true
        check(name .. ": stop size " .. tostring(e.id), type(e.x) == "number" and type(e.y) == "number" and (e.w or 0) > 0 and (e.h or 0) > 0)
        check(name .. ": stop inside the width " .. tostring(e.id), e.x >= -1 and e.x + e.w <= w + 1, e.x .. "+" .. tostring(e.w))
    end
    local st = stOf(tab)
    local t = st and st.tk
    if st and st.card then
        check(name .. ": card has stops", #list > 0)
        check(name .. ": every stop answers to B", (function()
            for _, e in ipairs(list) do if not e.onCancel then return false end end
            return true
        end)())
        check(name .. ": a card leaves room to read", (t.csh or 0) >= ZeD.T.px(120), t.csh)
        for _, r in ipairs(t.footRects or {}) do
            check(name .. ": foot button inside", r.x >= 0 and r.x + r.w <= w + 1 and r.y + r.h <= h + 1, r.b.id)
            if r.b.disabled then check(name .. ": grayed " .. r.b.id .. " says why", type(r.b.why) == "string" and r.b.why ~= "") end
        end
        -- no two foot buttons on top of each other
        local rects = t.footRects or {}
        for i = 1, #rects do
            for j = i + 1, #rects do
                local a, b = rects[i], rects[j]
                check(name .. ": foot buttons apart", a.x + a.w <= b.x or b.x + b.w <= a.x or a.y + a.h <= b.y or b.y + b.h <= a.y, a.b.id .. "/" .. b.b.id)
            end
        end
    end
    for _, c in ipairs(panel.kids) do
        if c.visible then
            local sy, sh
            if st.card then sy, sh = t.csy, t.csh else sy, sh = t.sy, t.sh end
            check(name .. ": a text box whole in its view", c.y >= sy and c.y + c.height <= sy + sh, c.y .. "+" .. c.height .. " in " .. sy .. "+" .. sh)
        end
    end
    return list
end


local PROFILES = {
    { name = "720 Normal", root = 0.75, size = "small", w = 360, h = 500 },
    { name = "720 Large", root = 0.75, size = "large", w = 414, h = 500 },
    { name = "Deck Normal", root = 0.75, size = "small", w = 360, h = 560 },
    { name = "Deck Large", root = 0.75, size = "large", w = 414, h = 560 },
    { name = "1080 Normal", root = 1, size = "small", w = 480, h = 800 },
    { name = "1080 Large", root = 1, size = "large", w = 552, h = 800 },
    { name = "4K Normal", root = 1.75, size = "small", w = 840, h = 1500 },
    { name = "4K Large", root = 1.75, size = "large", w = 966, h = 1500 },
    -- (no real window is this narrow: it stands in for a language with longer words)
    { name = "Narrow", root = 1, size = "large", w = 300, h = 560 },
}

-- every state ----------------------------------------------------------------------------
local M, AC, Adm = ZeD.Admin, ZeD.AdminCards, ZeD.Adm
S.present, S.staff, S.admin, S.adm = true, true, true, true
local base = newPanel(480, 800)
frame("admin", base, 480, 800)
local states = Q.bind(TC, AC, M, Adm)
check("states to walk", #states >= 55, #states)

-- a grayed stop says why, under the controller and in its reason
local function whyAll(name, list)
    for _, e in ipairs(list) do
        if e.tkWhy then
            local why = e.tkWhy()
            if why ~= nil then check(name .. ": a why has words " .. e.id, type(why) == "string" and why ~= "") end
        end
    end
end

for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    local p = newPanel(prof.w, prof.h)
    WINS.admin._tkFields = nil
    for _, s in ipairs(states) do
        for _, pad in ipairs({ false, true }) do
            local name = prof.name .. (pad and " pad " or " mouse ") .. s.name
            FOCUS.pad = pad
            FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
            local win = WINS.admin
            local st = stOf("admin")
            nowMs = nowMs + 20000
            s.reset(win, st)
            s.run(win, st)
            local ok, err = pcall(function()
                frame("admin", p, prof.w, prof.h)
                frame("admin", p, prof.w, prof.h)
                local list = verify(name, "admin", p, prof.w, prof.h)
                whyAll(name, list)
                local t = st.tk
                local sc = st.card and t.scroll or st.scroll
                if sc.visible then
                    for i = 1, 6 do
                        sc:setScrollPos(i / 6)
                        frame("admin", p, prof.w, prof.h)
                        frame("admin", p, prof.w, prof.h)
                        verify(name .. " scrolled", "admin", p, prof.w, prof.h)
                    end
                    sc:setScrollPos(0)
                    frame("admin", p, prof.w, prof.h)
                end
                if ZEDQA_SVG and not pad and (os.getenv("ZEDQA_SVG_ONLY") or "") == prof.name then writeSvg(p, s.name) end
                if pad then
                    for _, e in ipairs(list) do
                        FOCUS.id, FOCUS.el, FOCUS.win = e.id, e, WINS.admin
                        frame("admin", p, prof.w, prof.h)
                    end
                    FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
                end
            end)
            check(name .. ": draws", ok, err)
        end
    end
end
FOCUS.pad = false
ZEDQA_ROOT = 1
ZEDQA_LARGE = false
ZeD.applyTheme("dark", "orange", "small")

-- the flows ------------------------------------------------------------------------------
local W, H = 480, 800
local panel = newPanel(W, H)
local win = WINS.admin
win._tkFields = nil
local st = stOf("admin")
local function draw() frame("admin", panel, W, H) end
local function stopOf(id)
    for _, e in ipairs(stops("admin")) do if e.id == id then return e end end
    return nil
end
local function press(id)
    draw()
    draw()
    local e = stopOf(id)
    check("the stop is there: " .. id, e ~= nil)
    if e then e.onActivate(win) end
    draw()
    return e
end
local function grayWhy(id)
    draw()
    local e = stopOf(id)
    check("the stop is there: " .. id, e ~= nil)
    return e and e.tkWhy and e.tkWhy() or nil
end
local function click(id)
    draw()
    draw()
    local e = stopOf(id)
    check("clickable: " .. id, e ~= nil)
    if e then TABS.admin.onClick(win, e.x + 1, e.y + 1) end
    draw()
end
local function typeIn(key, text)
    draw()
    local box = win._tkFields[key]
    check("the field is there: " .. key, box ~= nil)
    if box then D_set(key, text) end
end
function D_set(key, text) TC._D.setField(win, key, text) end
local function sent(c)
    for i = #SENT, 1, -1 do if SENT[i].c == c then return SENT[i].a end end
    return nil
end
local function ack(c, extra)
    local a = sent(c)
    check("sent " .. c, a ~= nil)
    if not a then return end
    local r = { ok = true, rid = a.rid }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    S.routes[Tk.MOD]("t_ack", r)
    draw()
end
local function nak(c, err)
    local a = sent(c)
    S.routes[Tk.MOD]("t_ack", { ok = false, err = err, rid = a and a.rid })
    draw()
end
local function hasS(s)
    for _, v in ipairs(SEND) do if string.find(v, s, 1, true) then return true end end
    return false
end
local function hasG(s)
    for _, v in ipairs(GAMECALLS) do if string.find(v, s, 1, true) then return true end end
    return false
end
local function clear() SENT, SEND, GAMECALLS = {}, {}, {} end

-- real traffic from here on, the mockup's data in the model
local function fresh()
    states[1].reset(win, st)
    TC.qaHold, TC.qaRole, TC.qaLink, TC.qaGo, TC.qaStats = nil, nil, nil, nil, nil
    M.qaHold, M.qaLink = true, true       -- (the lists stay the mockup's: acts still go to the server)
    clear()
    draw()
end
local function flash() return st.tk.flashText end

-- the list: Find, Online only, the summary row
fresh()
draw()
check("a row per player", stopOf("adm:tk:p:Kade_R") ~= nil and stopOf("adm:tk:p:tjk") ~= nil)
win._tkFields.pfind.input:setText("rosa")
win._tkFields.pfind:update()
draw()
draw()
check("Find keeps one", stopOf("adm:tk:p:Rosa") ~= nil and stopOf("adm:tk:p:Kade_R") == nil)
win._tkFields.pfind.input:setText("")
win._tkFields.pfind:update()
press("adm:tk:ponly")
check("Online only hides who isn't on", stopOf("adm:tk:p:tjk") == nil and stopOf("adm:tk:p:Kade_R") ~= nil)
press("adm:tk:ponly")

-- tickets: the summary opens the queue, and back
C.counts = { open = 5, spam = 1, kinds = { STUCK = 2, GRIEF = 1, OTHER = 1, NONE = 1 } }
C.seq = C.seq + 1
draw()
local sumText = nil
for _, it in ipairs(st.items) do if it.c and it.c.id == "sum:tickets" then sumText = it.left end end
check("the summary reads as drawn", sumText == "1 Griefing, 2 Stuck, 1 Other, 1 with no kind", sumText)
press("adm:tk:sum:tickets")
check("the row opens the queue", st.screen == "tickets")
draw()
draw()
check("the back key is first", stops("admin")[1].id == "adm:back")
check("B leaves the queue", stops("admin")[2].onCancel ~= nil)
click("adm:back")
check("back on the list", st.screen == nil)

-- the player card, with the server's card arriving
fresh()
press("adm:tk:p:Kade_R")
check("the card opens", st.card and st.card.kind == "player" and st.card.user == "Kade_R")
press("tk:kick")
check("Kick opens in the card", st.card.open == "kick")
check("Kick grays without a reason", grayWhy("tk:kyes") == ZeD.tr("UI_ZeD_Adm_WriteReason"))
typeIn("reason", "Spamming chat")
draw()
check("a reason lights it", grayWhy("tk:kyes") == nil)
press("tk:kyes")
check("the server is asked first", sent("a_kick") and sent("a_kick").reason == "Spamming chat" and #SEND == 0)
ack("a_kick", { reason = "Spamming chat" })
check("then the game's kick, with the reason", hasS('/kickuser "Kade_R" -r "Spamming chat"'))
check("the part closes", st.card.open == nil)
check("the answer is in the help band", flash() == ZeD.tr("UI_ZeD_Adm_Kicked", "Kade_R"))
-- a refusal keeps the words
clear()
press("tk:kick")
typeIn("reason", "Words to keep")
press("tk:kyes")
nak("a_kick", "protected")
check("a refusal says why", flash() == ZeD.tr("UI_ZeD_Adm_Err_protected"))
check("the words stay", TC._D.fieldText(win, "reason") == "Words to keep")
check("no game call", #SEND == 0)
stops("admin")[1].onCancel(win)
check("B closes the part, not the card", st.card and st.card.open == nil)

-- ban
clear()
press("tk:ban")
check("the ban opens with 3 days", st.card.open == "ban" and st.card.len == "d3")
check("Ban IP too grays on a timed ban", grayWhy("tk:banip") == ZeD.tr("UI_ZeD_Adm_IpPermOnly"))
press("tk:bl:perm")
check("Permanent lights it", grayWhy("tk:banip") == nil)
press("tk:banip")
check("Ban IP ticks", st.card.banIp == true)
press("tk:bl:d1")
check("a timed length clears it", st.card.banIp == false)
typeIn("reason", "Griefing")
press("tk:byes")
local a = sent("a_ban")
check("the ban goes with its length, on the row's name", a and a.user == "Kade_R" and a.target == nil and a.len == "d1" and a.banIp == false and a.sid == nil)
ack("a_ban", { id = 3 })
check("no game call from the card: the server owes it", #SEND == 0 and #GAMECALLS == 0)

-- warning points
clear()
press("tk:warnb")
check("warn opens at one", st.card.open == "warn" and st.card.warnN == 1)
check("the least is one", grayWhy("tk:wm") ~= nil)
press("tk:wp")
press("tk:wp")
check("the stepper counts", st.card.warnN == 3)
typeIn("reason", "Third time")
press("tk:wyes")
check("warn asks", sent("a_warn") and sent("a_warn").n == 3)
ack("a_warn", { reason = "Third time", n = 3 })
check("then the game's", hasG("warn:Kade_R:Third time:3"))

-- a role: the pick, what it means, the powers
clear()
press("tk:role")
check("the pick opens over the card", st.tk.popup ~= nil)
draw()
local rows = stops("admin")
check("its rows are the stops", #rows == 8, #rows)
for _, e in ipairs(rows) do
    if e.tkPop == "GM" then e.onActivate(win) end
end
draw()
check("picking asks in the card", st.card.open == "role" and st.card.newRole == "GM")
check("the powers show, off", stopOf("tk:kp:Invisible") ~= nil and stopOf("tk:kp:GodMod") ~= nil and stopOf("tk:kp:NoClip") == nil)
press("tk:kp:GodMod")
press("tk:ryes")
local r = sent("a_role")
check("the role goes with what is kept", r and r.role == "GM" and r.keep[1] == "GodMod" and r.keep[2] == nil)
ack("a_role")
check("then the game's", hasG("net:SetRole:Kade_R:GM"))
check("the answer says the rest start off", flash() == ZeD.tr("UI_ZeD_Adm_RoleSetOff", "Kade_R", "GM"))
-- a pick of the same role does nothing
press("tk:role")
draw()
for _, e in ipairs(stops("admin")) do
    if e.tkPop == "user" then e.onActivate(win) end
end
draw()
check("the same role asks nothing", st.card.open == nil)

-- Level Up, mute, teleport
clear()
press("tk:su:Farming")
check("Level Up asks the server", sent("a_skill") and sent("a_skill").dir == 1)
ack("a_skill", { perk = "Farming", amount = 750.5 })
check("then /addxp", hasS('/addxp "Kade_R" Farming=750.5 -false'))
check("the top of a skill grays", grayWhy("tk:su:Sprinting") == ZeD.tr("UI_ZeD_Adm_SkillMost"))
-- the server's names are in its language; with the ids, the card shows the game's own in the viewer's (punch list 95)
do
    local function jl(t) return { size = function() return #t end, get = function(_, i) return t[i + 1] end } end
    local function def(id, label) return { getType = function() return id end, getUIName = function() return label end } end
    local function perk(id) return setmetatable({}, { __tostring = function() return id end }) end
    local PERKS = { perk("Farming"), perk("Woodwork") }
    local NAMES = { Farming = "Landwirtschaft", Woodwork = "Tischlerei" }
    CharacterProfessionDefinition = { getProfessions = function() return jl({ def("base:farmer", "Landwirt") }) end }
    CharacterTraitDefinition = { getTraits = function() return jl({ def("base:strong", "Stark") }) end }
    Perks = { getMaxIndex = function() return #PERKS end, fromIndex = function(i) return PERKS[i + 1] end }
    PerkFactory = { getPerk = function(p) return { getName = function() return NAMES[tostring(p)] end } end }
    local v = M.cards.Kade_R
    v.profId, v.traitIds = "base:farmer", { "base:strong", "base:gardener" }   -- (no game name for the second: the server's stays)
    ZeD._trGen = ZeD._trGen + 1
    M.bump()
    draw()
    draw()
    local line, farming, wood = nil, nil, nil
    for _, it in ipairs(st.tk.items or {}) do
        if it.k == "sub" and it.text and string.find(it.text, "Landwirt", 1, true) then line = it.text end
        if it.k == "askill" and it.lv == 5 then farming = it.name end
        if it.k == "askill" and it.lv == 2 then wood = it.name end
    end
    check("the profession and traits in the viewer's language", line == ZeD.tr("UI_ZeD_Adm_ProfWith", "Landwirt", "Stark, Gardener, Smoker"), line)
    check("the skills too", farming == "Landwirtschaft" and wood == "Tischlerei", tostring(farming) .. " " .. tostring(wood))
    v.profId, v.traitIds = nil, nil
    CharacterProfessionDefinition, CharacterTraitDefinition, Perks, PerkFactory = nil, nil, nil, nil
    ZeD._trGen = ZeD._trGen + 1
    M.bump()
    draw()
end
clear()
press("tk:mute")
ack("a_mute")
check("mute: voice too", hasS('/voiceban "Kade_R" -true'))
clear()
press("tk:tp")
ack("a_tp")
check("teleport", hasS('/teleport "Kade_R"'))
clear()
press("tk:tpme")
ack("a_bring")
check("bring", hasS('/teleportplayer "Kade_R" "Aretha"'))
local invWas = ISPlayerStatsManageInvUI.opened
press("tk:inv")
check("Inventory opens its card over the player card, not the game's window", st.card.kind == "pinv" and st.card.parent and st.card.parent.kind == "player"
    and ISPlayerStatsManageInvUI.opened == invWas)
TC.back(win, st)
draw()
check("back to the player card from the inventory", st.card.kind == "player")
-- a ticket on the card, and back to the card
TC.qaHold = true
press("tk:tkt:14")
check("a ticket opens over the card", st.card.kind == "staff" and st.card.parent ~= nil)
C.card = { id = 14, source = "zed", kind = "GRIEF", author = "Kade_R", status = "Open", thread = { n = 1, { who = "Kade_R", text = "Words" } }, notes = { n = 0 } }
C.seq = C.seq + 1
draw()
press("tk:pcard")
check("the ticket's Player card is this card", st.card.kind == "player" and st.card.parent.kind == "staff")
TC.back(win, st)
check("back to the ticket", st.card.kind == "staff")
C.card = nil
TC.back(win, st)
check("back to the player card", st.card and st.card.kind == "player")
TC.qaHold = nil
-- an offline player: the acts that need them on gray and say so
fresh()
M.qaHold = true
press("adm:tk:p:tjk")
check("an offline player can't be kicked", grayWhy("tk:kick") == ZeD.tr("UI_ZeD_Adm_NotOnline", "tjk"))
check("but can be banned", grayWhy("tk:ban") == nil)
-- Mute on an offline player (the outside review of beta 7: the label dipped and came back, nothing went, no line said why).
-- With the server part the mute is its list of names, which a_mute keeps for an account that is off: Mute works and the card
-- says so in its own line, under the acts (the help band is where hover said things already)
local function cardLine()
    draw()
    for _, it in ipairs(st.tk.items or {}) do if it.k == "aline" then return it.text end end
    return nil
end
local function hoverHelp(id)
    draw()
    for _, it in ipairs(st.tk.items or {}) do
        for _, c in ipairs(it.k == "aflow" and it.ctls or {}) do if c.id == id then return c.help end end
    end
    return nil
end
do
    check("no answer line before a press", cardLine() == nil, cardLine())
    check("Mute is not gray for an offline player with the server part", grayWhy("tk:mute") == nil, grayWhy("tk:mute"))
    check("before the press it says what Mute does to someone who is off", hoverHelp("mute") == ZeD.tr("UI_ZeD_Adm_HelpMuteOff", "tjk"), hoverHelp("mute"))
    clear()
    st.tk.flashText = nil
    click("tk:mute")
    local a = sent("a_mute")
    check("a click asks the server to mute tjk", a ~= nil and a.user == "tjk" and a.on == true)
    ack("a_mute")
    check("the answer is a line on the card", cardLine() == ZeD.tr("UI_ZeD_Adm_Muted", "tjk"), cardLine())
    check("the game's voice ban is not sent for someone who is off (it finds only a player who is on)", not hasS("/voiceban"))
    -- a refusal is a line on the card too
    clear()
    M.mutes = {}
    M.bump()
    press("tk:mute")
    nak("a_mute", "full")
    check("a refusal is the card's line", cardLine() == ZeD.tr("UI_ZeD_Adm_Err_full"), cardLine())
    -- a gray act pressed: its why as the card's line, and nothing asked
    clear()
    st.tk.flashText = nil
    click("tk:kick")
    check("a gray Kick pressed says why in the card's line", cardLine() == ZeD.tr("UI_ZeD_Adm_NotOnline", "tjk"), cardLine())
    check("and in the help band as before", flash() == ZeD.tr("UI_ZeD_Adm_NotOnline", "tjk"), flash())
    check("and asks the server nothing", #SENT == 0)
    st.tk.flashText = nil
    -- without the server part Mute is the game's voice ban, which finds only a player who is on: gray, saying so before
    -- the press, and the press says it in the card's line
    M.qaLink = false
    M.voice = {}
    M.bump()
    check("without the part: gray, and why", grayWhy("tk:mute") == ZeD.tr("UI_ZeD_Adm_VoiceNeedsOn", "tjk"), grayWhy("tk:mute"))
    clear()
    click("tk:mute")
    check("a click says it in the card's line", cardLine() == ZeD.tr("UI_ZeD_Adm_VoiceNeedsOn", "tjk"), cardLine())
    check("and sends nothing", #SENT == 0 and not hasS("/voiceban"))
    st.card.said = nil
    M.bump()
    press("tk:mute")
    check("the pad's A says the same in the card's line", cardLine() == ZeD.tr("UI_ZeD_Adm_VoiceNeedsOn", "tjk"), cardLine())
    check("and sends nothing either", #SENT == 0 and not hasS("/voiceban"))
    M.qaLink = true
    M.mutes = {}
    M.bump()
    st.tk.flashText = nil
end
TC.back(win, st)
-- a gray button does not go down under the pointer (its label dipped and came back on a press that did nothing)
do
    local xs = {}
    local p = { drawText = function(_, s, x, y) xs[#xs + 1] = x .. "," .. y end, drawRect = function() end, drawRectBorder = function() end,
        drawTextureScaled = function() end, drawTexture = function() end, drawTextureScaledAspect = function() end }
    local Mo = ZeD.Molecules
    local function at(pressed, disabled)
        xs = {}
        pcall(Mo.drawButton, p, 10, 10, 80, 20, "Mute", "default", pressed, nil, { disabled = disabled })
        return xs[#xs]
    end
    check("a gray button's label stays put when pressed", at(true, true) ~= nil and at(true, true) == at(false, true), tostring(at(true, true)) .. " " .. tostring(at(false, true)))
    check("a live one still goes down", at(true, false) ~= at(false, false))
end
-- a moderator: every gray says the capability and the role
fresh()
M.qaHold = true
M.qaCaps = { CanSeePlayersStats = true, KickUser = true, RolesRead = true }
M.bump()
press("adm:tk:p:Kade_R")
check("a gray says the capability and the role", grayWhy("tk:ban") == ZeD.tr("UI_ZeD_Adm_NeedCap", M.capWord("BanUnbanUser"), "BanUnbanUser", "moderator"), grayWhy("tk:ban"))
TC.back(win, st)
M.qaCaps = {}
M.bump()
draw()
check("the tab's rows gray too", grayWhy("adm:tk:sum:spawn") ~= nil and grayWhy("adm:tk:sum:bans") ~= nil)
check("More tools gray too", grayWhy("adm:b:more:options") ~= nil)

-- the server message: once, repeating, Stop
fresh()
M.qaHold = true
M.repeats = {}
M.bump()
draw()
draw()
check("Send grays with nothing written", grayWhy("adm:tk:send") == ZeD.tr("UI_ZeD_Adm_WriteMsg"))
typeIn("msg", "Hello")
draw()
press("adm:tk:send")
ack("a_msg", { text = "Hello" })
check("once: the game's /servermsg", hasS('/servermsg "Hello"'))
clear()
typeIn("msg", "Trading post")
press("adm:tk:rep")
press("adm:tk:ev:30")
press("adm:tk:send")
check("a repeat asks the server", sent("a_repeat") and sent("a_repeat").every == 30)
ack("a_repeat", { text = "Trading post" })
check("and goes once now", hasS('/servermsg "Trading post"'))
M.repeats = { { id = 4, text = "Trading post", every = 30 } }
M.bump()
press("adm:tk:stop:4")
check("Stop", sent("a_stop") and sent("a_stop").id == 4)
ack("a_stop")
-- the repeats need the server part
M.qaLink = false
M.bump()
draw()
check("repeats gray without the server part", grayWhy("adm:tk:rep") == ZeD.tr("UI_ZeD_Adm_NeedPart"))
M.qaLink = true

-- roles
fresh()
M.qaHold = true
press("adm:tk:sum:roles")
check("the roles card", st.card.kind == "roles")
press("tk:r:moderator")
check("a role's card", st.card.kind == "role" and st.card.parent.kind == "roles")
draw()
draw()
check("Save grays until something changes", (function()
    local b = nil
    for _, rc in ipairs(st.tk.footRects) do if rc.b.id == "rsave" then b = rc.b end end
    return b and b.disabled and b.why == ZeD.tr("UI_ZeD_Adm_NothingToSave")
end)())
press("tk:cap:AddItem")
draw()
check("a tick changes the draft only", st.card.d.caps.AddItem == true and M.role("moderator").caps.AddItem == nil)
draw()
press("tk:rsave")
check("Save asks the server", sent("a_rolelog") and sent("a_rolelog").what == "save")
ack("a_rolelog")
check("then the game's setupRole", hasG("setup:moderator"))
-- Delete behind its confirm
clear()
press("tk:rdel")
check("a foot confirm", st.tk.confirm == true)
draw()
check("it lands on Keep it", stopOf("tk:cno") ~= nil)
press("tk:cno")
check("Keep it keeps it", st.tk.confirm == nil)
press("tk:rdel")
press("tk:cyes")
check("Delete asks the server", sent("a_rolelog") and sent("a_rolelog").what == "delete")
ack("a_rolelog")
check("then the game's", hasG("deleteRole:moderator"))
check("back on the list", st.card.kind == "roles")
-- a new role
clear()
press("tk:addrole")
check("a new role's card", st.card.kind == "role" and st.card.name == nil)
typeIn("rname", "builder")
typeIn("rdesc", "Builds things")
draw()
press("tk:rsave")
ack("a_rolelog")
check("the game makes the role", hasG("addRole:builder"))
TC.back(win, st)
TC.back(win, st)
-- a locked role
press("adm:tk:sum:roles")
press("tk:r:admin")
check("a locked role's ticks gray", grayWhy("tk:cap:KickUser") == ZeD.tr("UI_ZeD_Adm_RoleLocked"))
check("groups fold", (function()
    press("tk:g:players")
    return stopOf("tk:cap:KickUser") == nil
end)())
TC.back(win, st)
TC.back(win, st)

-- bans
fresh()
M.qaHold = true
press("adm:tk:sum:bans")
check("the bans card", st.card.kind == "bans")
draw()
draw()
check("Ban grays with nothing written", grayWhy("tk:bgo") == ZeD.tr("UI_ZeD_Adm_WriteTarget"))
typeIn("btarget", "203.0.113.7")
typeIn("breason", "Alt")
press("tk:bo:d1")
check("an IP with a length says so", grayWhy("tk:bgo") == ZeD.tr("UI_ZeD_Adm_IpPermOnly"))
press("tk:bo:perm")
press("tk:bgo")
check("an offline ban asks the server", sent("a_ban") and sent("a_ban").target == "203.0.113.7")
ack("a_ban", { id = 9 })
check("the fields clear", TC._D.fieldText(win, "btarget") == "")
press("tk:ub:1")
check("Unban asks in the foot", st.tk.confirm ~= nil)
draw()
press("tk:cno")
check("Keep the ban", st.tk.confirm == nil)
clear()
press("tk:ub:1")
press("tk:cyes")
check("Unban goes", sent("a_unban") and sent("a_unban").id == 1)
ack("a_unban")
M.bans[2].stay = 1
M.bump()
draw()
draw()
check("a client that stayed offers the game's ban", stopOf("tk:gb:2") ~= nil)
clear()
press("tk:gb:2")
check("the game's ban goes through the server", sent("a_gameban") ~= nil)
ack("a_gameban")
TC.back(win, st)

-- spawn
fresh()
M.qaHold = true
press("adm:tk:sum:spawn")
check("the spawn card", st.card.kind == "spawn")
draw()
draw()
win._tkFields.ifind.input:setText("bat")
win._tkFields.ifind:update()
draw()
draw()
check("Find keeps what matches", stopOf("tk:it:Base.BaseballBat") ~= nil and stopOf("tk:it:Base.Axe") == nil)
local function subSays(s)
    for _, it in ipairs(st.tk.items or {}) do if it.k == "sub" and it.text == s then return true end end
    return false
end
win._tkFields.ifind.input:setText("zzqx")
win._tkFields.ifind:update()
draw()
draw()
check("no item: the items' own words, not the tickets'", subSays("No items match.") and not subSays(ZeD.tr("UI_ZeD_Tk_NoMatch")))
win._tkFields.ifind.input:setText("bat")
win._tkFields.ifind:update()
draw()
draw()
press("tk:it:Base.BaseballBat")
check("a pick opens How many", stopOf("tk:nm") ~= nil)
press("tk:n50")
press("tk:np")
check("how many", st.card.n == 51)
press("tk:to:ground")
press("tk:spawnb")
local sp = sent("a_spawn")
check("the spawn goes", sp and sp.item == "Base.BaseballBat" and sp.n == 51 and sp.to == "ground")
ack("a_spawn", { n = 51 })
check("the answer", flash() == "51 x Baseball Bat spawned to the ground. Logged.", flash())
-- a whole sentence per target, so each language gives it its own case (QA's German "an du", punch list 95)
local function spawnLine() return TC.kinds.spawn.foot(win, st, st.tk, st.card).status end
check("the line, to the ground", spawnLine() == "51 x Baseball Bat to the ground", spawnLine())
st.card.to = "me"
check("the line, to you", spawnLine() == "51 x Baseball Bat to you", spawnLine())
st.card.to = "Rosa"
check("the line, to a player", spawnLine() == "51 x Baseball Bat to Rosa", spawnLine())
-- the four whole-sentence keys are written out in the file, so the translation guard sees them (not glued from parts)
do
    local f = assert(io.open(ROOT .. "42/media/lua/client/ZeD/ZeD_AdminCards.lua", "rb"))
    local src = f:read("*a")
    f:close()
    for _, k in ipairs({ "UI_ZeD_Adm_SpawnLineMe", "UI_ZeD_Adm_SpawnLineGround", "UI_ZeD_Adm_SpawnedMe", "UI_ZeD_Adm_SpawnedGround" }) do
        check("spawn key written whole: " .. k, string.find(src, '"' .. k .. '"', 1, true) ~= nil)
    end
end
st.card.to = "ground"
st.card.n = 100
M.bump()
draw()
check("the top grays", grayWhy("tk:np") == ZeD.tr("UI_ZeD_Adm_UpTo", 100))
TC.back(win, st)

-- without the server part: the game's own calls at once
fresh()
M.qaLink = false
M.qaHold = true
TC.qaLink = "off"
M.bump()
press("adm:tk:p:Kade_R")
press("tk:ban")
check("a timed ban grays without the server part", grayWhy("tk:bl:h1") == ZeD.tr("UI_ZeD_Adm_NeedPart"))
check("and the ban opens on what the game can do", st.card.len == "perm")
st.card.len = "d3"                -- (the link fell with the part open)
typeIn("reason", "Griefing")
M.bump()
check("a timed length left over grays Ban", grayWhy("tk:byes") == ZeD.tr("UI_ZeD_Adm_NeedPart"))
TC._D.setField(win, "reason", "")
st.card.open = nil
M.bump()
press("tk:role")
stops("admin")[1].onCancel(win)
draw()
TC.back(win, st)
press("adm:tk:p:Kade_R")
st.card.newRole, st.card.open = "moderator", "role"
M.bump()
draw()
draw()
check("no ticks: only the server part can turn powers off", stopOf("tk:kp:Invisible") == nil)
st.card.newRole, st.card.open = nil, nil
TC.back(win, st)
press("adm:tk:sum:spawn")
draw()
draw()
press("tk:it:Base.Axe")
st.card.to = "ground"
M.bump()
draw()
check("Spawn to the ground grays without the part", (function()
    for _, rc in ipairs(st.tk.footRects) do
        if rc.b.id == "spawnb" then return rc.b.why == ZeD.tr("UI_ZeD_Adm_NeedPart") end
    end
    return false
end)())
TC.back(win, st)
TC.qaLink = nil

-- a press waits for its answer
fresh()
M.qaHold = true
press("adm:tk:p:Kade_R")
press("tk:warnb")
typeIn("reason", "Third time")
press("tk:wyes")
clear()
draw()
check("the button says it waits", grayWhy("tk:wyes") == ZeD.tr("UI_ZeD_Tk_Busy"))
stopOf("tk:wyes").onActivate(win)
AC._F.act(win, st, function(cb) M.warn("Kade_R", 1, "again", cb) end)
check("a second press sends nothing", sent("a_warn") == nil)
st.tk.busy = nil
stops("admin")[1].onCancel(win)
TC.back(win, st)

-- a player on a ban: Unban in Ban's place, behind the foot
fresh()
M.qaHold = true
M.bans = { { id = 5, user = "Kade_R", reason = "x", by = "Hermit", day = 3, untilT = 1793913240 + 86400 } }
M.bump()
press("adm:tk:p:Kade_R")
draw()
draw()
check("no second ban", stopOf("tk:ban") == nil and stopOf("tk:unban") ~= nil)
press("tk:unban")
check("it asks in the foot", st.tk.confirm ~= nil and st.tk.confirm.id == 5)
draw()
press("tk:cno")
check("Keep the ban", st.tk.confirm == nil)
clear()
press("tk:unban")
draw()
press("tk:cyes")
check("Unban goes", sent("a_unban") and sent("a_unban").id == 5)
ack("a_unban")
TC.back(win, st)
M.bans = {}
M.bump()

-- the role's list, top to bottom, least to most: Up is less rank
fresh()
M.qaHold = true
clear()
press("adm:tk:sum:roles")
press("tk:r:moderator")
draw()
draw()
check("a role's back says Roles", TC._D.backHelp(st, st.card) == ZeD.tr("UI_ZeD_Adm_BackRoles"))
press("tk:rup")
ack("a_rolelog")
check("Up: one row up this list", hasG("moveRole:-1:moderator"), GAMECALLS[1])
clear()
press("tk:rdown")
ack("a_rolelog")
check("Down: one row down", hasG("moveRole:1:moderator"), GAMECALLS[1])
-- Delete asks: X is not Save while it does
press("tk:rdel")
draw()
check("X has no Save during the confirm", TC.kinds.role.padX(win, st, st.tk, st.card) == nil)
stops("admin")[1].onCancel(win)
TC.back(win, st)
TC.back(win, st)

-- Keep the ban goes back to the row
fresh()
M.qaHold = true
press("adm:tk:sum:bans")
draw()
draw()
press("tk:ub:2")
check("the confirm remembers its row", st.tk.confirmFrom == "tk:ub:2")
press("tk:cno")
check("and lets go", st.tk.confirmFrom == nil)
TC.back(win, st)

-- the spawn card's find box starts empty each time
fresh()
M.qaHold = true
press("adm:tk:sum:spawn")
draw()
draw()
win._tkFields.ifind.input:setText("bat")
win._tkFields.ifind:update()
draw()
TC.back(win, st)
press("adm:tk:sum:spawn")
draw()
draw()
check("the box is empty again", TC._D.fieldText(win, "ifind") == "" and stopOf("tk:it:Base.Axe") ~= nil)
TC.back(win, st)

-- a power this role lacks stays, gray, and says why
fresh()
M.qaHold = true
M.qaCaps = { Invisible = true, RolesRead = true }
M.bump()
check("gray with its reason", grayWhy("adm:tk:pw:GodMod") == M.why("GodMod"), grayWhy("adm:tk:pw:GodMod"))
check("the one it has works", grayWhy("adm:tk:pw:Invisible") == nil)
M.qaCaps = {}
M.bump()
check("rich text tags go", AC._F.plainTip("Fast move: <LINE> Move - arrow keys<LINE>Floor") == "Fast move: Move - arrow keys Floor")

-- a card with no right to a player's tickets says so, and warning points nobody can read say that too
fresh()
M.qaHold = true
M.qaCaps = { CanSeePlayersStats = true, RolesRead = true }
M.rows = { { user = "Quiet", on = true, role = "user" } }
M.bump()
press("adm:tk:p:Quiet")
draw()
local why = M.why("AnswerTickets")
local saw, sawWarn = false, false
for _, it in ipairs(st.tk.items or {}) do
    if it.text == why then saw = true end
    if it.k == "fact" and it.value == M.why("SeeNetworkUsers") then sawWarn = true end
end
check("the tickets say why", saw)
check("warning points say why", sawWarn)
TC.back(win, st)
-- an offline card the server keeps closed (no See every account): the power, never "loading" or "not seen yet"
-- (no role on the row: the list leaves offline accounts out for this role, so nothing on the client knows it)
M.rows = { { user = "Away", on = false } }
M.cards.Away = { user = "Away", on = false, closed = true }
M.bump()
press("adm:tk:p:Away")
draw()
local netWhy, sawProf, sawStatus, sawLoading = M.why("SeeNetworkUsers"), false, false, false
local roleBox, roleText = nil, nil
local netWhyN, sawNoSkills = 0, false
for _, it in ipairs(st.tk.items or {}) do
    if it.text == netWhy then sawProf = true; netWhyN = netWhyN + 1 end
    if it.text == ZeD.tr("UI_ZeD_Adm_NoSkills") then sawNoSkills = true end
    if it.k == "fact" and it.label == ZeD.tr("UI_ZeD_Adm_Role") then roleBox, roleText = it.c, it.value end
    if it.text == ZeD.tr("UI_ZeD_Tk_Loading") then sawLoading = true end
    if it.k == "fact" and it.label == ZeD.tr("UI_ZeD_Adm_Status") and it.value == netWhy then sawStatus = true end
end
check("a closed card says which power its record takes", sawProf and not sawLoading)
check("a closed card's status says it too", sawStatus)
-- (as wrapped text like Status, no box: a one-line box ran past the card's edge at 1280x800, QA Nov 7 2026)
check("a closed card's role says it too, never \"user\"", roleBox == nil and roleText == netWhy)
-- (the skills were kept back too: the card names the power, never "no skill above 0" for an account it cannot see)
check("a closed card's skills say it too, never \"no skill above 0\"", (not sawNoSkills) and netWhyN >= 2)
TC.back(win, st)
-- a role that may change roles still gets no role change on a closed card: there is no role to say what they lose
M.qaCaps = { CanSeePlayersStats = true, RolesRead = true, ChangeAccessLevel = true, ModifyNetworkUsers = true }
M.bump()
press("adm:tk:p:Away")
draw()
check("a closed card offers no role change", stopOf("tk:role") == nil)
-- (the card closed while an ask was open: no ask, so no confirm that says they lose nothing)
st.card.newRole, st.card.open, st.card.keep = "user", "role", {}
M.bump()
draw()
check("a closed card shows no role ask", stopOf("tk:rno") == nil and stopOf("tk:ryes") == nil)
st.card.newRole, st.card.open = nil, nil
check("nothing to press, no pick", stopOf("tk:role") == nil and st.tk.popup == nil)
TC.back(win, st)
M.cards.Away = nil
M.qaCaps = {}
M.bump()

-- the words of a confirm are the card's own
check("Keep it on a role", ZeD.tr("UI_ZeD_Adm_HelpKeepRole") ~= ZeD.tr("UI_ZeD_Tk_HelpKeep"))
check("one warning point reads as one", ZeD.tr("UI_ZeD_Adm_WarnDone1", "Kade") == "1 warning point added. Kade sees the reason.")

-- the leave screen's words
do
    local lines = AC.leaveLines({ kind = "ban", reason = "Griefing", untilT = 1793913240 })
    check("a timed ban's words", string.find(lines[1], "until", 1, true) ~= nil and lines[2] == "Reason: Griefing")
    lines = AC.leaveLines({ kind = "ban", reason = "Griefing", appeal = "discord.gg/x" })
    check("Phase 5's appeal line has its place", lines[3] == "Appeal: discord.gg/x")
    M.leaveScreen = function(info) M.hooked5 = info end
    S.routes[Adm.MOD]("a_leave", { kind = "ban", reason = "R" })
    check("the hook takes it", M.hooked5 and M.hooked5.reason == "R")
    M.hooked5 = nil
    S.routes[Adm.MOD]("a_leave", { kind = "ban", reason = "R" })
    check("said again, the clock runs on", M.hooked5 == nil)
    M.leaveScreen, M.leaveAt, M.leave = nil, nil, nil
end

-- the stats card and the inventory card (ZeD_StatsCards.lua): the game's calls, as its windows make them -----------------
do
    local SC = ZeD.StatsCards
    fresh()
    SC.qaView, SC.qaLists, SC.qaInv = nil, nil, nil
    M.qaCaps = { CanSeePlayersStats = true, CanModifyPlayerStatsInThePlayerStatsUI = true, AddXP = true, AddUserlog = true, ReadUserLog = true,
        WorkWithUserlog = true, InspectPlayerInventory = true, ManipulateWhitelist = true, AddItem = true }
    M.bump()
    -- the game's side, from the javap listings: a player, its descriptor, traits, XP and the definitions
    local CALLS = {}
    local function log(s) CALLS[#CALLS + 1] = s end
    local function has(s) for _, v in ipairs(CALLS) do if v == s then return true end end return false end
    local PERKS = { "Farming", "Aiming" }
    local perkObj = {}
    for i, n in ipairs(PERKS) do
        perkObj[n] = { n = n, getName = function() return n end, getParent = function() return { pn = "Skill" } end,
            getXpForLevel = function(_, lv) return 75 * lv end, getTotalXpForLevel = function(_, lv) return 100 * lv end }
        setmetatable(perkObj[n], { __tostring = function() return n end })
    end
    Perks = { None = "none", getMaxIndex = function() return #PERKS end, fromIndex = function(i) return perkObj[PERKS[i + 1]] end }
    PerkFactory = { getPerk = function(p) return p end, getPerkName = function() return "Skill" end }
    ISSkillProgressBar = nil
    local function trait(id, cost) return { getType = function() return id end, getTexture = function() return {} end, getLabel = function() return id end,
        getDescription = function() return id .. " <LINE> more" end, getCost = function() return cost end } end
    local DEFS = { trait("Strong", 10), trait("Brave", 4), trait("Smoker", -4) }
    CharacterTraitDefinition = { getTraits = function() return { size = function() return #DEFS end, get = function(_, i) return DEFS[i + 1] end } end,
        getCharacterTraitDefinition = function(id) for _, d in ipairs(DEFS) do if d:getType() == id then return d end end return nil end }
    local PROFS = { { t = "unemployed", n = "Unemployed" }, { t = "farmer", n = "Farmer" }, { t = "nurse", n = "Nurse" } }
    CharacterProfession = { UNEMPLOYED = "unemployed" }
    local function prof(p) return { getType = function() return p.t end, getUIName = function() return p.n end, getDescription = function() return p.n end } end
    CharacterProfessionDefinition = { getProfessions = function() return { size = function() return #PROFS end, get = function(_, i) return prof(PROFS[i + 1]) end } end,
        getCharacterProfessionDefinition = function(t) for _, p in ipairs(PROFS) do if p.t == t then return prof(p) end end return nil end }
    local known = { "Strong" }
    local xp = { Farming = 120, Aiming = 0 }
    local rolePos = 1
    local desc = { fore = "Kade", sur = "Rourke", prof = "farmer" }
    function desc.getForename(self) return self.fore end
    function desc.setForename(self, s) self.fore = s; log("fore:" .. s) end
    function desc.getSurname(self) return self.sur end
    function desc.setSurname(self, s) self.sur = s end
    function desc.getCharacterProfession(self) return self.prof end
    function desc.setCharacterProfession(self, p) self.prof = p; log("prof:" .. tostring(p)) end
    local CHAR = { inWorld = true }
    function CHAR.getUsername() return "Kade_R" end
    function CHAR.getDisplayName() return "Kade" end
    function CHAR.setDisplayName(_, s) log("display:" .. s) end
    function CHAR.getDescriptor() return desc end
    function CHAR.getTimeSurvived() return "9 days" end
    function CHAR.getZombieKills() return 212 end
    function CHAR.getNutrition() return { getWeight = function() return 81.6 end } end
    function CHAR.getRole() return { getName = function() return "user" end, getPosition = function() return rolePos end } end
    function CHAR.setRole(_, name) log("role:" .. tostring(name)) end
    function CHAR.getOnlineID() return 7 end
    function CHAR.getCurrentSquare() return {} end
    function CHAR.isExistInTheWorld(self) return self.inWorld end
    function CHAR.hasTrait(_, id) for _, k in ipairs(known) do if k == id then return true end end return false end
    function CHAR.getCharacterTraits() return {
        getKnownTraits = function() return { size = function() return #known end, get = function(_, i) return known[i + 1] end } end,
        add = function(_, id) known[#known + 1] = id; log("trait+" .. id) end,
        remove = function(_, id) for i = #known, 1, -1 do if known[i] == id then table.remove(known, i) end end log("trait-" .. id) end } end
    function CHAR.modifyTraitXPBoost(_, id, off) log("boost:" .. id .. ":" .. tostring(off)) end
    function CHAR.getPerkLevel(_, p) return math.floor(xp[p.n] / 100) end
    function CHAR.getXp() return { getXP = function(_, p) return xp[p.n] end, getPerkBoost = function() return 1 end, getMultiplier = function() return 1 end,
        AddXP = function(_, p, n, a, mult) xp[p.n] = xp[p.n] + n; log("addxp:" .. p.n .. ":" .. n .. ":" .. tostring(mult)) end } end
    SC.qaChar = { Kade_R = CHAR }
    sendPlayerStatsChange = function() log("stats") end
    SyncXp = function() log("syncxp") end
    addUserlog = function(u, ty, text) log("log+" .. u .. ":" .. tostring(ty) .. ":" .. text) end
    removeUserlog = function(u, ty, text) log("log-" .. u .. ":" .. ty .. ":" .. text) end
    getRoles = function()
        local rs = { { "user", 1 }, { "moderator", 5 }, { "admin", 7 } }
        return { size = function() return #rs end, get = function(_, i) local r = rs[i + 1]; return { getName = function() return r[1] end, getPosition = function() return r[2] end, getDescription = function() return "" end } end }
    end
    PLAYER.getRole = function() return { getPosition = function() return 5 end, getName = function() return "moderator" end, hasCapability = function() return true end } end

    press("adm:tk:p:Kade_R")
    press("tk:stats")
    check("Check stats opens the stats card over the player card, not the game's window", st.card.kind == "pstats" and st.card.parent.kind == "player" and ISPlayerStatsUI.opened == 0)
    check("it reads the player: names, profession, weight, traits, skills", st.card.view.fore == "Kade" and st.card.view.profName == "Farmer" and st.card.view.weight == 81
        and #st.card.view.traits == 1 and #st.card.view.skills == 2)
    -- a name: the field in the card, Save in the foot, the game's setter and its packet
    press("tk:c:fore")
    check("Change opens the name in the card", st.card.open == "name" and TC._D.fieldText(win, "sname") == "Kade")
    check("the same name grays Save with the game's words", grayWhy("tk:sgo") == "%1 is the same" or grayWhy("tk:sgo") == getText("IGUI_PlayerStats_SameName", "Forename"))
    typeIn("sname", "")
    check("an empty name grays Save", grayWhy("tk:sgo") == ZeD.tr("UI_ZeD_St_NameEmpty"))
    typeIn("sname", "Kaden")
    press("tk:sgo")
    check("Save: the descriptor's setter, then sendPlayerStatsChange", has("fore:Kaden") and CALLS[#CALLS] == "stats" and st.card.open == nil)
    -- weight: the server's own command, 30 to 130
    press("tk:c:wt")
    typeIn("sweight", "200")
    check("a weight out of range grays Save", grayWhy("tk:sgo") == ZeD.tr("UI_ZeD_St_WeightRange", 30, 130))
    typeIn("sweight", "90")
    press("tk:sgo")
    check("weight goes as the game's setWeight with the online ID", sent("setWeight") and sent("setWeight").weight == 90 and sent("setWeight").id == 7)
    -- profession: a pick, then the foot
    press("tk:c:prof")
    check("Change profession grays until a pick", grayWhy("tk:sgo") == ZeD.tr("UI_ZeD_St_PickFirst"))
    press("tk:pk:3")
    press("tk:sgo")
    check("profession: setCharacterProfession and the packet", has("prof:nurse"))
    -- traits: add a good one, remove behind the foot's ask
    press("tk:addtrait")
    press("tk:pk:1")
    press("tk:sgo")
    check("Add trait: add, the XP boost, SyncXp", has("trait+Brave") and has("boost:Brave:false") and has("syncxp"))
    st.card.stale = true
    draw()
    press("tk:tr:1")
    check("Remove asks in the foot first", TC.qaState(st).confirm ~= nil and not has("trait-Strong"))
    press("tk:sgo")
    check("then the game's remove and boost", has("trait-Strong") and has("boost:Strong:true"))
    -- XP: Level Up as the window's LEVELPERK: /addxp to the next level's start
    clear()
    st.card.stale = true
    draw()
    press("tk:su:Farming")
    check("Level Up: the server's /addxp for the gap, without multipliers", hasS('/addxp "Kade_R" Farming=80 -false') and has("addxp:Farming:80:false"))
    press("tk:addxp")
    press("tk:pk:1")
    typeIn("sxp", "25")
    press("tk:sgo")
    check("Add XP: the amount with multipliers ticked", hasS('/addxp "Kade_R" Aiming=25 -true'))
    -- logs and warning points
    press("tk:addlog")
    typeIn("slog", "Asked about the generator")
    press("tk:sgo")
    check("Add log: the game's addUserlog as AdminLog", has("log+Kade_R:AdminLog:Asked about the generator"))
    M.logs.Kade_R = { { type = "AdminLog", text = "Old", by = "Rosa", amount = 0 } }
    M.bump()
    press("tk:lg:1")
    press("tk:sgo")
    check("Remove log behind the ask: removeUserlog", has("log-Kade_R:AdminLog:Old"))
    clear()
    press("tk:addwarn")
    typeIn("sreason", "Third time")
    press("tk:sgo")
    check("warning points: the game's addWarningPoint", hasG("warn:Kade_R:Third time:1"))
    -- the gates: the window's rank rule, the packet's capability
    rolePos = 7
    st.card.stale = true
    draw()
    check("a role above yours grays every Change", grayWhy("tk:c:fore") == ZeD.tr("UI_ZeD_St_RankAbove", "user"))
    rolePos = 1
    CHAR.inWorld = false
    st.card.stale = true
    draw()
    check("out of the world grays them", grayWhy("tk:c:wt") == ZeD.tr("UI_ZeD_St_NotInWorld"))
    CHAR.inWorld = true
    M.qaCaps.WorkWithUserlog, M.qaCaps.CanModifyPlayerStatsInThePlayerStatsUI = nil, nil
    st.card.stale = true
    M.bump()
    draw()
    check("without the window's capability: its reason", grayWhy("tk:c:wt") == M.why("CanModifyPlayerStatsInThePlayerStatsUI"))
    M.qaCaps.CanModifyPlayerStatsInThePlayerStatsUI = true
    M.bump()
    check("a log off needs WorkWithUserlog", grayWhy("tk:lg:1") == M.why("WorkWithUserlog"))
    -- B closes an open part, not the card
    press("tk:c:fore")
    stops("admin")[2].onCancel(win)
    check("B closes the part first", st.card.kind == "pstats" and st.card.open == nil)
    -- someone this client hasn't loaded: no stats, the logs stay
    SC.qaChar = {}
    st.card.stale = true
    M.bump()
    draw()
    check("not loaded: says so, no Change", stopOf("tk:c:fore") == nil and stopOf("tk:addlog") ~= nil)
    SC.qaChar = { Kade_R = CHAR }
    -- the inventory card: the server's table, Remove behind the ask, Take
    INVCALLS = {}
    M.qaHold = false
    press("tk:inv")
    check("the inventory card asks the server with the online ID", INVCALLS[1] == "ask:7:Kade_R")
    M.qaHold = true
    local items = { capacityWeight = 3.21, maxWeight = 18,
        { itemId = 11, fullType = "Base.Axe", count = "1", cat = "Weapon", inInv = false, parrentId = -1, var = 5, isEquip = true },
        { itemId = 12, fullType = "Base.Nails", count = "40", cat = "Material", inInv = true, parrentId = 13, hasParrent = true, container = "Bag" } }
    for _, fn in ipairs(EVENTS.MngInvReceiveItems.list) do fn(items) end
    draw()
    check("its rows arrive, weapons first", SC.inv.Kade_R and #SC.inv.Kade_R.rows == 2 and SC.inv.Kade_R.rows[1].name == "Axe")
    check("Remove grays until a pick", grayWhy("tk:iremove") == ZeD.tr("UI_ZeD_St_PickFirst"))
    press("tk:it:1")
    press("tk:iremove")
    check("Remove asks first", TC.qaState(st).confirm ~= nil and #INVCALLS == 1)
    press("tk:ryes")
    check("then the game's InvMngRemoveItem", INVCALLS[2] == "rm:11:7:Kade_R")
    for _, fn in ipairs(EVENTS.MngInvReceiveItems.list) do fn(items) end
    press("tk:it:2")
    press("tk:itake")
    check("Take a stack: the game's InvMngGetItem by type", INVCALLS[#INVCALLS] == "get:0:Base.Nails:7:Kade_R")
    TC.back(win, st)
    TC.back(win, st)
    TC.back(win, st)
    SC.qaChar = nil
    M.qaCaps = {}
    M.bump()
end

-- More tools' Check your stats is the card, and a ticket's Player card without the server part is too
do
    fresh()
    local SC = ZeD.StatsCards
    local p = { getUsername = function() return "Aretha" end }
    for _, m in ipairs(ZeD.AdminTab.MORE) do
        if m.id == "mystats" then m.run(p, win, st) end
    end
    check("Check your stats opens your own stats card", st.card and st.card.kind == "pstats" and st.card.user == "Aretha" and ISPlayerStatsUI.opened == 0)
    TC.back(win, st)
    ZeD.AdminTab.next = nil
    st.card = { kind = "player", user = "Kade_R" }
    TC._D.statsWindow(win, "Kade_R")
    check("from a card in the Admin tab: the stats card over it", st.card.kind == "pstats" and st.card.parent and st.card.parent.kind == "player")
    st.card = nil
    draw()
end

print("admin_cards_sim: " .. checks .. " checks, " .. failed .. " failed")
os.exit(failed == 0 and 0 or 1)
