-- ZeDUI/tools/qa/log_cards_sim.lua  (Nov 6 2026, QA): the Log card with no game running.
-- The harness is admin_cards_sim.lua's: the real Tokens, Tr, Atoms, Molecules, ZeD_TicketCards, ZeD_Admin, ZeD_AdminCards, ZeD_Log,
-- ZeD_LogCards and AdminTab on Lua 5.1 stubs of a panel, text measures from the fonts' own sizes, the windows and the focus manager.
-- It draws every state of mp_log_cards.lua at Deck, 720, 1080 and 4K, Normal and Large text, mouse and pad; checks what drew (nothing
-- past the drawer's edges, no field outside its view, stops unique and whole, every grayed stop saying why), then walks the flows: the
-- Admin tab's row, the kind chips, Who, the time chips, Find, the pages, a line's buttons, Go there, the players' cards and back, the
-- ticket card's Around, Add to ticket, Clear, a refusal, the game's own PvP log with no server part. It proves the logic and the sums.
-- What it cannot prove is what the engine does: the text box, the keyboard, focus landing, real font widths.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/log_cards_sim.lua
-- It prints FAIL lines and a last line "log_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]log_cards_sim%.lua$", "")

local checks, failed = 0, 0
local function check(name, ok, detail)
    checks = checks + 1
    if not ok then
        failed = failed + 1
        print("FAIL " .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
    end
end

-- the clock, the game's globals -----------------------------------------------------------
local nowMs = 1793913240000
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
local Q = assert(loadfile(ROOT .. "ZeDUI/tools/qa/mp_log_cards.lua"))()

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
    if t and t.qaAfter then
        local fn = t.qaAfter
        t.qaAfter = nil
        fn(WINS[tab], stOf(tab))
        panel.texts = {}
        panel.ops = {}
        TABS[tab].render(panel, WINS[tab], 0, 0, w, h)
    end
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
local M, AC, Adm, LC, Lm, Lg = ZeD.Admin, ZeD.AdminCards, ZeD.Adm, ZeD.LogCards, ZeD.Logs, ZeD.Lg
S.present, S.staff, S.admin, S.adm, S.lg = true, true, true, true, true
local base = newPanel(480, 800)
frame("admin", base, 480, 800)
local states = Q.bind(TC, LC, Lm, M, C, S)
check("states to walk", #states >= 40, #states)

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
            if s.after then TC.qaState(st).qaAfter = s.after end
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
    Lm.qaHold, Lm.qaLink = nil, nil
    Lm.page = nil
    clear()
    draw()
end
local function flash() return st.tk.flashText end

-- the words on screen
local function drew(s)
    for _, t in ipairs(panel.texts) do
        if string.find(t.s, s, 1, true) then return true end
    end
    return false
end
local function drewAll(s)
    local all = {}
    for _, t in ipairs(panel.texts) do all[#all + 1] = t.s end
    return string.find(table.concat(all, " "), s, 1, true) ~= nil
end
local tr = ZeD.tr
-- words on the card, drawn or under the fold
local function onCard(s)
    for _, it in ipairs(st.tk.items or {}) do
        if it.text and string.find(it.text, s, 1, true) then return true end
    end
    return false
end
-- the server's page for the read just asked
local function answer(page)
    local a = sent("l_query")
    check("a read went out", a ~= nil)
    if not a then return end
    page.qid = a.qid
    S.routes[Lg.MOD]("l_page", page)
    S.routes[Tk.MOD]("t_ack", { ok = true, rid = a.rid })
    draw()
    draw()
end
-- the clock past the card's pace, and a frame
local function later(ms)
    nowMs = nowMs + (ms or 800)
    draw()
end
local function sends(c)
    local n = 0
    for _, e in ipairs(SENT) do if e.c == c then n = n + 1 end end
    return n
end

-- the Admin tab's row, to the card, and a read
fresh()
press("adm:tk:sum:log")
check("the row opens the card", st.card and st.card.kind == "log")
check("the card lands somewhere", #stops("admin") > 1)
check("back says where", stopOf("tk:back") ~= nil)
draw()
check("it asks for today, first page", sent("l_query") and sent("l_query").when == "today" and sent("l_query").page == 1, sent("l_query") and sent("l_query").when)
check("it says it is asking", drewAll(tr("UI_ZeD_Tk_Loading")))
answer(Q.page(getTimestamp()))
check("the lines drew", drew("mike_d") and stopOf("tk:l:494") ~= nil)
check("the count at the bar's right", drew("14 of 16"))
check("the kind is a word on a tag", drew("VEHICLE") and drew("PVP") and drew("ADMIN"))
check("the day", drew("Day 12"))
check("the place", drew("6283 x 5352"))
check("the source when it isn't ZeD's", drewAll(tr("UI_ZeD_Log_FromPvp")))
check("the older line says its date", drew("Day 11"))
check("the foot's line", onCard(tr("UI_ZeD_Log_Lines", 14)))
check("no Container chip with the opt-in off", stopOf("tk:lk:container") == nil)
check("the opt-in's line says so", onCard(tr("UI_ZeD_Log_NoContainer")))
check("help in the band", ZeD.Help.last == tr("UI_ZeD_Log_HelpCard"), ZeD.Help.last)
check("it lands on the newest line", (function()
    for _, e in ipairs(stops("admin")) do if e.tkLand then return e.id == "tk:l:500" or e.id == "tk:l:499" end end
    return false
end)())

-- the chips
later()
SENT = {}
press("tk:lk:vehicle")
later()
check("a kind goes to the server", sent("l_query") and sent("l_query").kind == "vehicle", sent("l_query") and sent("l_query").kind)
answer(Q.page(getTimestamp(), {}))
check("nothing matches, in words", drewAll(tr("UI_ZeD_Log_NoMatch")))
later()
SENT = {}
press("tk:lk:All")
later()
check("All clears it", sent("l_query") and sent("l_query").kind == nil)
answer(Q.page(getTimestamp()))
later()
SENT = {}
press("tk:lw:hour")
later()
check("the time chip", sent("l_query").when == "hour")
answer(Q.page(getTimestamp()))
later()
SENT = {}
press("tk:lw:d3")
later()
check("3 days", sent("l_query").when == "d3")
answer(Q.page(getTimestamp()))

-- the pace: three quick presses, one read
later()
SENT = {}
press("tk:lk:admin")
press("tk:lk:faction")
press("tk:lk:ticket")
check("presses in a burst wait their turn", sends("l_query") <= 1, sends("l_query"))
later()
check("the last one wins", sent("l_query").kind == "ticket", sent("l_query").kind)
answer(Q.page(getTimestamp()))
later()
SENT = {}
press("tk:lk:All")
later()
answer(Q.page(getTimestamp()))

-- Who: the pick list over the card
later()
SENT = {}
press("tk:lwho")
draw()
draw()
check("the list opens", st.tk.popup ~= nil)
check("it holds the names", drew("Kade_R") and drew(tr("UI_ZeD_Log_Anyone")))
local rows = stops("admin")
check("only its rows are stops", #rows == 7, #rows)
local function popRow(id)
    for _, e in ipairs(stops("admin")) do if e.id == id then return e end end
end
local e = popRow("adm:tk:row:u:mike_d") or popRow("tk:row:u:mike_d")
check("the name's row", e ~= nil)
if e then e.onActivate(win) end
draw()
later()
check("a name goes to the server", sent("l_query") and sent("l_query").who == "mike_d", sent("l_query") and sent("l_query").who)
answer(Q.page(getTimestamp()))
check("the box says who", drew("mike_d"))
later()
SENT = {}
press("tk:lwho")
draw()
draw()
e = popRow("adm:tk:row:ALL") or popRow("tk:row:ALL")
if e then e.onActivate(win) end
draw()
later()
check("Anyone clears it", sent("l_query") and sent("l_query").who == nil)
answer(Q.page(getTimestamp()))

-- Find settles before it asks
later()
SENT = {}
win._tkFields.lfind.input:setText("Chevalier")
win._tkFields.lfind:update()
draw()
check("Find waits for the keys to stop", sent("l_query") == nil)
later(450)
later(600)
check("then asks", sent("l_query") and sent("l_query").find == "Chevalier", sent("l_query") and sent("l_query").find)
answer(Q.page(getTimestamp()))
win._tkFields.lfind.input:setText("")
win._tkFields.lfind:update()
draw()
later(1100)
answer(Q.page(getTimestamp()))

-- the first page reads itself again; a later page stays put
later()
SENT = {}
nowMs = nowMs + 11000
draw()
check("the first page stays fresh", sent("l_query") ~= nil)
answer(Q.page(getTimestamp()))

-- the pages
do
    local p = Q.page(getTimestamp())
    p.n, p.page, p.pages = 60, 1, 3
    later()
    S.routes[Lg.MOD]("l_page", (function() p.qid = Lm.qid; return p end)())
    draw()
    draw()
    check("Previous is gray on the first page, and says why", grayWhy("tk:lprev") == tr("UI_ZeD_Tk_FirstPage"), grayWhy("tk:lprev"))
    SENT = {}
    press("tk:lnext")
    later()
    check("Next", sent("l_query") and sent("l_query").page == 2)
    p.page = 2
    answer(p)
    SENT = {}
    nowMs = nowMs + 11000
    draw()
    check("a later page stays put", sent("l_query") == nil)
    press("tk:lk:All")
    later()
    check("a chip goes back to the first page", st.card.page == 1)
    answer(Q.page(getTimestamp()))
end

-- a line's buttons
press("tk:l:494")
check("a pick opens the line", st.card.sel == 494)
draw()
draw()
check("Go there", stopOf("tk:lgo:494") ~= nil)
check("who did it", stopOf("tk:lpc:494") ~= nil)
check("the owner", stopOf("tk:lpo:494") ~= nil)
check("no Add to ticket off a ticket", stopOf("tk:lnote:494") == nil)
press("tk:l:494")
check("a second pick shuts it", st.card.sel == nil)
press("tk:l:494")
clear()
press("tk:lgo:494")
check("Go there teleports", hasS("/teleportto 6283,5352,0"), SEND[1])
check("and says so", st.tk.flashText == tr("UI_ZeD_Tk_Going", "6283 x 5352"), st.tk.flashText)
TC.qaGo = false
draw()
check("Go there gray, with why", grayWhy("tk:lgo:494") == tr("UI_ZeD_Tk_NoGo"), grayWhy("tk:lgo:494"))
TC.qaGo = nil
-- a player's card, and back to the same place
st.tk.scroll:setScrollPos(0.5)
draw()
local pos = st.tk.scroll.scrollPos
press("tk:lpc:494")
check("the player's card opens over the log", st.card.kind == "player" and st.card.user == "mike_d" and st.card.parent ~= nil and st.card.parent.kind == "log", st.card.kind)
TC.back(win, st)
draw()
draw()
check("back on the log", st.card.kind == "log")
check("where it was", st.tk.scroll.scrollPos == pos, st.tk.scroll.scrollPos)
check("with its page", Lm.page ~= nil and stopOf("tk:l:494") ~= nil)
press("tk:lpo:494")
check("the owner's card", st.card.kind == "player" and st.card.user == "Kade_R")
TC.back(win, st)
draw()
check("a mod's line has no player's card", (function()
    local now = getTimestamp()
    local page = Q.page(now, { { s = 79, t = now, day = 12, k = "vehicle", who = "Kade_R", what = "x", src = "tap", lg = "L", x = 1, y = 2, z = 0 } })
    page.qid = Lm.qid
    S.routes[Lg.MOD]("l_page", page)
    st.card.sel = 79
    Lm.bump()
    draw()
    draw()
    return stopOf("tk:lpc:79") == nil and stopOf("tk:lgo:79") ~= nil
end)())
do
    local now = getTimestamp()
    local page = Q.page(now, { { s = 80, t = now, day = 12, k = "admin", who = "Hermit", what = "power on: GodMod" } })
    page.qid = Lm.qid
    S.routes[Lg.MOD]("l_page", page)
    st.card.sel = 80
    Lm.bump()
    draw()
    draw()
    check("no place: Go there gray, with why", grayWhy("tk:lgo:80") == tr("UI_ZeD_Log_NoPlaceLine"), grayWhy("tk:lgo:80"))
end

-- leaving the card
click("tk:back")
check("back on the tab", st.card == nil)
check("the page goes with the card", Lm.page == nil)

-- a refusal
fresh()
press("adm:tk:sum:log")
draw()
S.routes[Tk.MOD]("t_ack", { ok = false, err = "perm", rid = sent("l_query").rid })
draw()
check("no right: back off the card, and it says so", st.card == nil, st.card and st.card.kind)
fresh()
press("adm:tk:sum:log")
draw()
S.routes[Tk.MOD]("t_ack", { ok = false, err = "wait", left = 1, rid = sent("l_query").rid })
draw()
check("wait: it stays and asks again", st.card ~= nil)
SENT = {}
later()
check("again", sent("l_query") ~= nil)
answer(Q.page(getTimestamp()))
TC.back(win, st)
-- no answer at all
fresh()
press("adm:tk:sum:log")
nowMs = nowMs + 11000
draw()
draw()
check("no answer: back, and it says so", st.card == nil and st.tk.flashText == tr("UI_ZeD_Tk_LoadFail"), st.tk.flashText)

-- from the ticket card
fresh()
TC.qaHold = nil
C.card = Q.ticket(getTimestamp())
TC.openStaff(win, st, 14)
C.card = Q.ticket(getTimestamp())
C.seq = C.seq + 1
draw()
draw()
check("the ticket card has the Log row", stopOf("tk:around") ~= nil)
press("tk:around")
check("the same card, around the ticket", st.card.kind == "log" and st.card.around == 14)
draw()
check("it names the ticket, not a day", sent("l_query") and sent("l_query").around == 14, sent("l_query") and sent("l_query").around)
do
    local now = getTimestamp()
    local p = Q.page(now, { Q.lines(now)[6], Q.lines(now)[7] })
    p.around = { id = 14, x = 6280, y = 5350, from = now - 216 * 60, to = now - 6 * 60, filed = now - 36 * 60, missed = { { who = "mike_d", from = now - 84 * 60, to = now - 74 * 60 } } }
    answer(p)
end
check("the band", drewAll(tr("UI_ZeD_Log_Around", 14)))
check("the time chips stay off", stopOf("tk:lw:today") == nil)
check("the Who and Find stay on", stopOf("tk:lwho") ~= nil and stopOf("tk:lfind") ~= nil)
check("the name the nearby list missed", drewAll("mike_d was here"))
check("help in the band", ZeD.Help.last == tr("UI_ZeD_Log_HelpAround"), ZeD.Help.last)
press("tk:l:494")
draw()
check("Add to ticket", stopOf("tk:lnote:494") ~= nil)
clear()
press("tk:lnote:494")
check("it goes to the server with the line and the ticket", sent("l_tonote") and sent("l_tonote").id == 14 and sent("l_tonote").s == 494)
S.routes[Tk.MOD]("t_ack", { ok = true, rid = sent("l_tonote").rid })
draw()
draw()
check("the answer", st.tk.flashText == tr("UI_ZeD_Log_Added", 14), st.tk.flashText)
check("gray now, with why", grayWhy("tk:lnote:494") == tr("UI_ZeD_Log_AlreadyOn"), grayWhy("tk:lnote:494"))
-- a refusal keeps the card
press("tk:l:493")
press("tk:lnote:493")
S.routes[Tk.MOD]("t_ack", { ok = false, err = "full", rid = sent("l_tonote").rid })
draw()
check("a refused note says why and stays", st.card.kind == "log" and st.tk.flashText ~= nil and st.tk.busy == nil)
-- Clear
SENT = {}
later()
press("tk:lclear")
later()
check("Clear asks for the whole log", sent("l_query") and sent("l_query").around == nil, sent("l_query") and sent("l_query").around)
answer(Q.page(getTimestamp()))
check("the band goes", not drewAll(tr("UI_ZeD_Log_Around", 14)))
check("the time chips come back", stopOf("tk:lw:today") ~= nil)
TC.back(win, st)
draw()
check("back on the ticket", st.card and st.card.kind == "staff" and st.card.id == 14, st.card and st.card.kind)
TC.back(win, st)

-- a log card over a log card takes the page with it: the one underneath reads again
fresh()
press("adm:tk:sum:log")
draw()
answer(Q.page(getTimestamp()))
press("tk:l:494")
press("tk:lpc:494")
check("over the log", st.card.kind == "player")
do
    local under = st.card.parent
    LC.openAround(win, st, 14)
    draw()
    answer(Q.page(getTimestamp()))
    TC.back(win, st)
    check("the page went with it", Lm.page == nil)
    TC.back(win, st)
    check("back on the first log card", st.card == under)
    SENT = {}
    nowMs = nowMs + 800
    draw()
    draw()
    check("it stays, and reads again", st.card == under and sent("l_query") ~= nil, st.card and st.card.kind)
    answer(Q.page(getTimestamp()))
    check("with its lines", stopOf("tk:l:494") ~= nil)
    TC.back(win, st)
end

-- the ticket with no place, and no log
fresh()
TC.qaHold = nil
C.card = Q.ticket(getTimestamp(), false)
TC.openStaff(win, st, 14)
C.card = Q.ticket(getTimestamp(), false)
C.seq = C.seq + 1
draw()
draw()
check("no place: gray, with why", grayWhy("tk:around") == tr("UI_ZeD_Log_NoPlaceTicket"), grayWhy("tk:around"))
S.lg = false
draw()
check("no log: gray, with why", grayWhy("tk:around") == tr("UI_ZeD_Adm_NeedPart"), grayWhy("tk:around"))
TC.back(win, st)
draw()

-- without the server part: the game's own window
ISPVPLogToolUI = { made = 0, new = function(self)
    ISPVPLogToolUI.made = ISPVPLogToolUI.made + 1
    return { initialise = function() end, addToUIManager = function() end, setVisible = function() end }
end }
fresh()
ZEDQA_CAPS.PVPLogTool = true
M.qaCaps = { PVPLogTool = true }
M.bump()
draw()
draw()
press("adm:tk:sum:log")
check("the row opens the game's PvP log", ISPVPLogToolUI.made == 1 and st.card == nil, ISPVPLogToolUI.made)
M.qaCaps = {}
M.bump()
draw()
draw()
check("and says why with no power", grayWhy("adm:tk:sum:log") == M.why("PVPLogTool"), grayWhy("adm:tk:sum:log"))
S.lg = true
M.qaCaps = { AnswerTickets = true }
M.bump()
draw()

-- the queue's line
fresh()
st.screen = "tickets"
TC.qaHold = true
C.gameSilent = true
C.queue = { rows = {}, n = 0, page = 1, pages = 1 }
C.seq = C.seq + 1
draw()
draw()
check("the queue says the game's list has stopped", drewAll(string.sub(tr("UI_ZeD_Tk_GameSilent"), 1, 30)), ZeD.Help.last)
C.gameSilent = nil
C.seq = C.seq + 1
draw()
draw()
check("and it goes when the list answers", not drewAll(string.sub(tr("UI_ZeD_Tk_GameSilent"), 1, 30)))
st.screen = nil

print("log_cards_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
