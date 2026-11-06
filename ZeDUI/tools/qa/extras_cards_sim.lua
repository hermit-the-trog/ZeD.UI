-- ZeDUI/tools/qa/extras_cards_sim.lua  (Nov 6 2026, QA): the Server extras card, the Server tab's block, Your claims, the
-- Vehicle tab's pieces and the map's teleport with no game running.
-- The harness is admin_cards_sim.lua's: the real Tokens, Tr, Atoms, Molecules, ZeD_TicketCards, ZeD_Admin, ZeD_AdminCards,
-- ZeD_ExtrasCards, AdminTab and ServerTab on Lua 5.1 stubs of a panel, text measures from the fonts' own sizes, the windows and
-- the focus manager. It draws every state of mp_extras_cards.lua at Deck, 720, 1080 and 4K, Normal and Large text, mouse and pad;
-- checks what drew (nothing past the drawer's edges, no field outside its view, stops unique and whole, every grayed stop saying
-- why), then walks the flows: the row, each tick, the steppers at their ends, Save and its answer, a refusal, Economy, what a
-- player reads, Your claims and Release behind its confirm, the Vehicle tab's footer and row, the map's button. It proves the
-- logic and the sums. What it cannot prove is what the engine does: the real band and map, focus landing, real font widths.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/extras_cards_sim.lua
-- It prints FAIL lines and a last line "extras_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]extras_cards_sim%.lua$", "")
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
local Q = assert(loadfile(ROOT .. "ZeDUI/tools/qa/mp_extras_cards.lua"))()

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
local M, AC, Ex, E, EC = ZeD.Admin, ZeD.AdminCards, ZeD.Ex, ZeD.Extras, ZeD.ExtrasCards
TEXT.IGUI_ZombiePopulation_TeleportHere = "Teleport Here"
TEXT.IGUI_VehicleNamePickUpTruck = "Chevalier D6"
TEXT.IGUI_VehicleNameCarStationWagon = "Dash Rancher"
S.present, S.staff, S.admin, S.adm = true, true, true, true
for _, tab in ipairs({ "admin", "server" }) do
    local base = newPanel(480, 800)
    frame(tab, base, 480, 800)
end
local states = Q.bind(TC, AC, EC, E, M, Ex)
check("states to walk", #states >= 35, #states)

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
    WINS.server._tkFields = nil
    for _, s in ipairs(states) do
        for _, pad in ipairs({ false, true }) do
            local name = prof.name .. (pad and " pad " or " mouse ") .. s.name
            FOCUS.pad = pad
            FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
            local win = WINS[s.tab]
            local st = stOf(s.tab)
            nowMs = nowMs + 20000
            s.reset(win, st)
            s.run(win, st)
            local ok, err = pcall(function()
                frame(s.tab, p, prof.w, prof.h)
                frame(s.tab, p, prof.w, prof.h)
                local list = verify(name, s.tab, p, prof.w, prof.h)
                whyAll(name, list)
                local t = st.tk
                local sc = st.card and t.scroll or st.scroll
                if sc.visible then
                    for i = 1, 6 do
                        sc:setScrollPos(i / 6)
                        frame(s.tab, p, prof.w, prof.h)
                        frame(s.tab, p, prof.w, prof.h)
                        verify(name .. " scrolled", s.tab, p, prof.w, prof.h)
                    end
                    sc:setScrollPos(0)
                    frame(s.tab, p, prof.w, prof.h)
                end
                if ZEDQA_SVG and not pad and (os.getenv("ZEDQA_SVG_ONLY") or "") == prof.name then writeSvg(p, s.name) end
                if pad then
                    for _, e in ipairs(list) do
                        FOCUS.id, FOCUS.el, FOCUS.win = e.id, e, win
                        frame(s.tab, p, prof.w, prof.h)
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
local tab = "admin"
local function win() return WINS[tab] end
local function st() return stOf(tab) end
local function draw() frame(tab, panel, W, H) end
local function stopOf(id)
    for _, e in ipairs(stops(tab)) do if e.id == id then return e end end
    return nil
end
local function press(id)
    draw()
    draw()
    local e = stopOf(id)
    check("the stop is there: " .. id, e ~= nil)
    if e then e.onActivate(win()) end
    draw()
    draw()
    return e
end
local function grayWhy(id)
    draw()
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
    if e then TABS[tab].onClick(win(), e.x + 1, e.y + 1) end
    draw()
    draw()
end
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
local function hasDrawn(s)
    for _, t in ipairs(panel.texts) do
        if string.find(t.s, s, 1, true) then return true end
    end
    return false
end
local function words()
    local all = {}
    for _, t in ipairs(panel.texts) do all[#all + 1] = t.s end
    return table.concat(all, " ")
end
-- words on the card, whether or not they're scrolled into view
local function cardHas(word)
    for _, it in ipairs(st().tk.items or {}) do
        for _, v in ipairs({ it.text or "", it.sub or "" }) do
            if string.find(v, word, 1, true) then return true end
        end
    end
    return false
end
local function fresh(which)
    tab = which or "admin"
    states[1].reset(win(), st())
    TC.qaHold, TC.qaRole, TC.qaLink = nil, nil, nil
    M.qaHold = true
    E.qaHold = nil
    SENT = {}
    local fresh_sent = SENT
    function sendClientCommand(p, m, c, a) fresh_sent[#fresh_sent + 1] = { m = m, c = c, a = a } end
    draw()
end
local function flash() return st().tk.flashText end

-- the row
fresh()
check("the row is on the list", stopOf("adm:tk:sum:extras") ~= nil)
check("the row's count", hasDrawn("All off"))
E.set.vc.on = true
E.bump()
draw()
check("the count follows", hasDrawn("1 on"))
E.set.vc.on = false
E.qaLink = false
E.bump()
draw()
check("no server part: the row is gray, and says why", grayWhy("adm:tk:sum:extras") == getText("UI_ZeD_Adm_NeedPart"))
press("adm:tk:sum:extras")
check("gray opens nothing", st().card == nil)
E.qaLink = true
E.bump()

-- the card
press("adm:tk:sum:extras")
check("the card opens", st().card ~= nil and st().card.kind == "extras")
check("its title", hasDrawn("Server extras"))
check("as drawn: the intro", hasDrawn("Systems the game doesn't have"))
check("as drawn: the help", ZeD.Help.last ~= nil and string.find(ZeD.Help.last, "Each is off by default", 1, true) ~= nil)
check("all off: no inner stops", stopOf("tk:vparts") == nil and stopOf("tk:sdis") == nil)
check("saved, and nothing to save", grayWhy("tk:xsave") == getText("UI_ZeD_Adm_NothingToSave") and hasDrawn("Saved."))
click("tk:xvc")
check("a tick opens its system", stopOf("tk:vparts") ~= nil and stopOf("tk:vvper:more") == nil)
check("not saved yet", hasDrawn("Not saved yet."))
check("Save lights", grayWhy("tk:xsave") == nil)
check("the draft, not the server's", st().card.d.vc.on == true and E.set.vc.on == false)
check("as drawn: Others can't", hasDrawn("Others can't") and hasDrawn("Take parts") and hasDrawn("Drive it") and hasDrawn("Tow it"))
check("as drawn: the numbers", hasDrawn("Claims per player") and hasDrawn("A claim lapses after") and hasDrawn("real days away") and hasDrawn("cars"))
check("the card doesn't promise what it can't", hasDrawn("aren't stopped"))
press("tk:vtow")
check("Tow ticks", st().card.d.vc.tow == true)
press("tk:vper:more")
check("up", st().card.d.vc.per == 3)
for _ = 1, 2 do press("tk:vper:more") end
check("to the most", st().card.d.vc.per == 5)
check("the most is gray and says so", string.find(tostring(grayWhy("tk:vper:more")), "5 is the most", 1, true) ~= nil)
press("tk:vper:more")
check("no further", st().card.d.vc.per == 5)
for _ = 1, 4 do press("tk:vper:less") end
check("to the least", st().card.d.vc.per == 1)
check("the least is gray, and says so", string.find(tostring(grayWhy("tk:vper:less")), "1 is the least", 1, true) ~= nil)
check("one car, in the singular", hasDrawn("car") and not hasDrawn("cars"))
press("tk:vlapse:less")
check("days down", st().card.d.vc.lapse == 6)
click("tk:xsp")
check("protection opens", stopOf("tk:sdis") ~= nil and stopOf("tk:sdes") ~= nil and stopOf("tk:slot") ~= nil)
check("as drawn: the words", hasDrawn("No dismantling") and hasDrawn("Claims cover the lot"))
check("the lot says how far", cardHas(tostring(Ex.LOT_TILES) .. " tiles out"))
press("tk:xtp")
check("who has the teleport", cardHas("Who: moderator, overseer, admin"))
press("tk:xcl")
check("players are told", cardHas("Players are told in the Server tab"))
check("the log says whose word it is", cardHas("reports its own takes"))
check("Economy says why it's gray", grayWhy("tk:xeco") == getText("UI_ZeD_Ex_EcoWhy"))
local before = st().card.rev
press("tk:xeco")
check("Economy does nothing", st().card.rev == before)
local pad = stopOf("tk:xvc")
check("X is Save under the controller", pad and pad.promptX == getText("IGUI_RolesList_Save"))
press("tk:xsave")
check("Save sends the draft", sent("x_save") ~= nil and sent("x_save").set.vc.on == true and sent("x_save").set.sp.on == true)
check("one at a time", grayWhy("tk:xsave") == getText("UI_ZeD_Tk_Busy"))
nak("x_save", "perm")
check("a refusal keeps the draft", st().card.d.vc.on == true and flash() ~= nil)
check("not saved yet, still", hasDrawn("Not saved yet."))
press("tk:xsave")
ack("x_save")
check("the answer in the help band", flash() == getText("UI_ZeD_Ex_SavedFlash"))
S.routes[Ex.MOD]("x_set", { set = Ex.clean(sent("x_save").set) })
draw()
draw()
check("saved", hasDrawn("Saved.") and grayWhy("tk:xsave") == getText("UI_ZeD_Adm_NothingToSave"))
-- another admin saves: a clean card follows, a changed one keeps its changes
do
    local other = Ex.clean(E.set)
    other.tp.on = false
    S.routes[Ex.MOD]("x_set", { set = other })
    draw()
    draw()
    check("a clean card follows", st().card.d.tp.on == false and hasDrawn("Saved."))
    press("tk:xtp")
    check("a change", st().card.d.tp.on == true)
    local again = Ex.clean(E.set)
    again.cl.on = false
    S.routes[Ex.MOD]("x_set", { set = again })
    draw()
    draw()
    check("a changed card keeps its changes", st().card.d.tp.on == true and st().card.d.cl.on == true and hasDrawn("Not saved yet."))
end
TC.back(win(), st())
draw()
check("back to the Admin tab", st().card == nil)

-- no power
fresh()
M.qaCaps = {}
E.bump()
M.bump()
draw()
press("adm:tk:sum:extras")
check("anyone with the tab can read it", st().card ~= nil)
local why = grayWhy("tk:xvc")
check("a tick says what it needs", type(why) == "string" and string.find(why, "ChangeAndReloadServerOptions", 1, true) ~= nil, why)
check("Save says the same", grayWhy("tk:xsave") == why)
press("tk:xvc")
check("gray changes nothing", st().card.d.vc.on == false)

-- what a player reads
fresh("server")
draw()
check("the head, as drawn", hasDrawn("This server's extras") and hasDrawn("set by the admins"))
check("off, as drawn", hasDrawn("No vehicle claims on this server."))
E.set.vc.on, E.set.sp.on, E.set.cl.on = true, true, true
E.mineRows = {}
E.bump()
draw()
draw()
local s = words()
check("claims, as drawn", string.find(s, "Vehicle claims: claim a car in its Vehicle tab", 1, true) ~= nil, s)
check("no word about the ones not ticked", string.find(s, "tow it", 1, true) == nil)
check("protection, as drawn", string.find(s, "Safehouses are protected", 1, true) ~= nil)
check("the log, as drawn", string.find(s, "logged, for the admins", 1, true) ~= nil)
check("off goes", not hasDrawn("No vehicle claims"))
E.set.vc.tow = true
E.bump()
draw()
draw()
check("a tick shows", string.find(words(), "tow it", 1, true) ~= nil)
check("your claims' row", stopOf("srv:tk:sum:xclaims") ~= nil)
check("a line can be stopped on and read", stopOf("srv:tk:exline:1") ~= nil)
E.qaLink = false
E.bump()
draw()
draw()
check("no server part: no block", not hasDrawn("This server's extras"))
E.qaLink = true
E.bump()

-- your claims
fresh("server")
E.set.vc.on = true
E.mineRows = nil
E.bump()
draw()
check("the tab asks for your claims", sent("x_mine") ~= nil)
S.routes[Ex.MOD]("x_mine", { rows = { { key = "v4021", name = "PickUpTruck", x = 6402, y = 5410 } }, n = 1, per = 2 })
draw()
draw()
check("n of m", string.find(words(), "1 of 2", 1, true) ~= nil)
press("srv:tk:sum:xclaims")
check("the card", st().card ~= nil and st().card.kind == "xclaims")
check("the car's name, the game's word", hasDrawn("Chevalier D6"))
check("where", hasDrawn("6402 x 5410"))
press("tk:xrel:1")
check("the foot asks", st().card.ask ~= nil and stopOf("tk:xkeep") ~= nil and stopOf("tk:xrelyes") ~= nil)
check("in the foot, in words", hasDrawn("Release your claim on the Chevalier D6?"))
local e = stopOf("tk:xkeep")
e.onCancel(win())
draw()
draw()
check("B keeps it", st().card ~= nil and st().card.ask == nil)
press("tk:xrel:1")
press("tk:xkeep")
check("Keep keeps it", st().card.ask == nil and sent("x_release") == nil)
press("tk:xrel:1")
press("tk:xrelyes")
check("Release sends the key", sent("x_release") ~= nil and sent("x_release").key == "v4021")
ack("x_release")
check("the answer", flash() == getText("UI_ZeD_Ex_Released"))
TC.back(win(), st())
draw()

-- the Vehicle tab's pieces: MechanicsTab.lua calls these, and each does nothing while claims are off
local VEH = { getId = function() return 7 end }
local function barOf(view)
    E.cars[7] = view and { at = nowMs, view = view } or { at = nowMs }
    local list, s2 = {}, {}
    EC.vehicleBar(list, s2, {}, VEH)
    return list, s2
end
fresh()
E.qaHold = true
check("off: no button", #barOf(nil) == 0)
check("off: no row", EC.statRow(panel, 0, 0, 200, VEH) == 0)
check("off: no block", E.partsBlock(VEH) == nil)
E.set.vc.on = true
E.bump()
local b1 = barOf(nil)
check("unheard: Claim gray, and why", #b1 == 1 and b1[1].disabled == true and b1[1].help == getText("UI_ZeD_Ex_Asking"))
b1 = barOf({ n = 0, per = 2 })
check("free: Claim", b1[1].id == "xclaim" and not b1[1].disabled)
b1 = barOf({ n = 2, per = 2 })
check("full: gray, and why", b1[1].disabled == true and string.find(b1[1].help, "limit", 1, true) ~= nil)
b1[1].fn()
check("gray sends nothing", sent("x_claim") == nil)
b1 = barOf({ n = 1, per = 2 })
b1[1].fn()
check("Claim sends", sent("x_claim") ~= nil and sent("x_claim").veh == 7)
local b2, s3 = barOf({ n = 1, per = 2, owner = "Aretha", mine = true, key = "v1" })
check("mine: Release", b2[1].id == "xrelease")
b2[1].fn()
check("Release asks first", s3.confirm == "xrelease")
b2 = barOf({ n = 0, per = 2, owner = "Aretha", mine = false, key = "v1" })
check("another's: nothing to press", #b2 == 0)
check("another's: parts gray", E.partsBlock(VEH) == "Aretha")
b2 = barOf({ n = 0, per = 2, owner = "Aretha", mine = false, staff = true, key = "v1" })
check("staff: Release", b2[1].id == "xrelease")
check("staff: parts stay", E.partsBlock(VEH) == nil)
E.set.vc.parts = false
barOf({ n = 0, per = 2, owner = "Aretha", mine = false, key = "v1" })
check("the tick off: parts stay", E.partsBlock(VEH) == nil)
check("the row names who", EC.statRow(panel, 0, 0, 200, VEH) > 0)
do
    local z = {}
    local h = { focusFor = function() return nil end, stamp = function(_, id, x, y, w2, h2, fn) z[id] = fn end }
    local q = {}
    EC.releaseBand(panel, {}, q, 0, 100, 480, VEH, h)
    check("the band's two answers", z["mech:confirm:no"] ~= nil and z["mech:confirm:yes"] ~= nil)
    q.confirm = "xrelease"
    z["mech:confirm:no"]()
    check("Keep shuts it", q.confirm == nil)
    q.confirm = "xrelease"
    z["mech:confirm:yes"]()
    check("Release sends", q.confirm == nil and sent("x_release") ~= nil and sent("x_release").key == "v1")
end

-- the map
local Ext = ZeD.MapsTabExt
local def
for _, d in ipairs(Ext.list) do if d.id == "extras_tp" then def = d end end
check("the map's extension is there", def ~= nil)
fresh()
E.qaHold = true
local mw = {}
check("off: no button", def.button(mw) == nil)
E.set.tp.on = true
M.qaCaps = {}
check("no power: no button", def.button(mw) == nil)
M.qaCaps = { [Ex.CAP_MAP] = true }
local btn = def.button(mw)
check("on: a button in the game's words", btn ~= nil and btn.text == "Teleport Here" and btn.on == false)
ZeD.MapsTab.putDownTool = function(w) w.putDown = true end
btn.activate(mw)
check("armed, and ZeD's mark tool down", def.armed(mw) == true and mw.putDown == true)
check("the banner says what to do", def.banner(mw) ~= nil)
function getWorld() return { getMetaGrid = function() return { isValidChunk = function(_, x, y) return x >= 0 end } end } end
local mp = { mapAPI = { uiToWorldX = function(_, x) return x + 0.7 end, uiToWorldY = function(_, _, y) return 5410.2 end } }
mp.mapAPI.uiToWorldY = function(_, x, y) return y + 0.2 end
def.mouseDown(mp, mw, 6402, 5410)
check("a click asks the server, in whole tiles", sent("x_tp") ~= nil and sent("x_tp").x == 6402 and sent("x_tp").y == 5410)
check("the tool goes down", def.armed(mw) == false)
ack("x_tp")
check("the game's command does the going", SEND[#SEND] == "/teleportto 6402,5410,0", SEND[#SEND])
btn = def.button(mw)
btn.activate(mw)
SENT[#SENT] = nil
def.padA(mp, mw, 100, 200, "hold")
check("A held does nothing", def.armed(mw) == true)
mp.mapAPI.uiToWorldX = function() return -40 end
def.padA(mp, mw, 100, 200, "down")
check("off the map: stays armed, nothing sent", def.armed(mw) == true)
def.putDown(mw)
check("ZeD's mark tool puts it down", def.armed(mw) == false)
btn = def.button(mw)
btn.activate(mw)
E.set.tp.on = false
check("the setting off takes the tool away", def.button(mw) == nil and def.armed(mw) == false)

print("extras_cards_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
