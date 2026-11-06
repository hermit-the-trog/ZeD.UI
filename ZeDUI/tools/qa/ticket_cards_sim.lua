-- ZeDUI/tools/qa/ticket_cards_sim.lua  (Nov 5 2026, QA): the ticket cards with no game running.
-- The real Tokens, Tr, Atoms, Molecules, ZeD_TicketProto, ZeD_ServerLink, ZeD_Tickets, ZeD_TicketCards, ServerTab and
-- AdminTab, on Lua 5.1 stubs of a panel, text measures from the fonts' own sizes, the windows and the focus manager. It
-- draws every state of mp_ticket_cards.lua at the Deck and 720 sizes (root 0.75) and 1080p, Normal and Large text, mouse
-- and pad; checks what drew (nothing past the drawer's edges, no field outside its view, stops unique and whole, every
-- grayed stop saying why), then walks the flows: Ask, a reply, the queue's filters, Find, paging, Take it, notes, Spam,
-- Not spam, Delete behind its confirm, Close, Reopen, Go there, and the fallback. It proves the logic and the sums. What
-- it cannot prove is what the engine does: the text box, the keyboard, focus landing, real font widths.
-- Run from the repo root:  lua51 ZeDUI/tools/qa/ticket_cards_sim.lua
-- It prints FAIL lines and a last line "ticket_cards_sim: N checks, M failed", and exits 1 if any failed.

local ROOT = string.gsub(arg and arg[0] or "", "ZeDUI[/\\]tools[/\\]qa[/\\]ticket_cards_sim%.lua$", "")

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
function getText(k, ...)
    local s = TEXT[k] or k
    return s
end
getTextOrNull = function(k) return TEXT[k] end
local SENT, COMMANDS, GAME = {}, {}, {}
function sendClientCommand(p, m, c, a) SENT[#SENT + 1] = { m = m, c = c, a = a } end
function SendCommandToServer(s) COMMANDS[#COMMANDS + 1] = s end
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
local Q = assert(loadfile(ROOT .. "ZeDUI/tools/qa/mp_ticket_cards.lua"))()

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
    { name = "4K 1.75", root = 1.75, size = "small", w = 840, h = 1500 },
    -- (no real window is this narrow: it stands in for a language with longer words, where the chips and the foot must wrap)
    { name = "Narrow", root = 1, size = "large", w = 300, h = 560 },
}

-- every state ----------------------------------------------------------------------------
S.present, S.staff, S.admin = true, true, true
-- (one drawing first, so the tabs have their state)
local base = newPanel(480, 800)
frame("server", base, 480, 800)
frame("admin", base, 480, 800)
local states = Q.bind(TC, C, S, "Aretha")
check("states to walk", #states >= 50, #states)

function ZeDQA_noop() end
for _, prof in ipairs(PROFILES) do
    ZEDQA_ROOT = prof.root
    ZEDQA_LARGE = prof.size == "large"
    ZeD.applyTheme("dark", "orange", prof.size)
    local panels = { server = newPanel(prof.w, prof.h), admin = newPanel(prof.w, prof.h) }
    -- (each profile its own drawer, and so its own text boxes)
    WINS.server._tkFields, WINS.admin._tkFields = nil, nil
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
            local p = panels[s.tab]
            WINS[s.tab]._tkFields = WINS[s.tab]._tkFields
            local ok, err = pcall(function()
                frame(s.tab, p, prof.w, prof.h)
                frame(s.tab, p, prof.w, prof.h)
                local list = verify(name, s.tab, p, prof.w, prof.h)
                -- a box half under a fold must not show: a child is not cut by the stencil
                local t = st.tk
                if st.card and t.scroll.visible then
                    for i = 1, 8 do
                        t.scroll:setScrollPos(i / 8)
                        frame(s.tab, p, prof.w, prof.h)
                        frame(s.tab, p, prof.w, prof.h)
                        verify(name .. " scrolled", s.tab, p, prof.w, prof.h)
                    end
                    t.scroll:setScrollPos(0)
                    frame(s.tab, p, prof.w, prof.h)
                end
                if ZEDQA_SVG and not pad and (os.getenv("ZEDQA_SVG_ONLY") or "") == prof.name then writeSvg(p, s.name) end
                -- each stop under the controller: its mark draws, and the card's band has the reason for a gray one
                if pad then
                    for _, e in ipairs(list) do
                        FOCUS.id, FOCUS.el, FOCUS.win = e.id, e, WINS[s.tab]
                        frame(s.tab, p, prof.w, prof.h)
                    end
                    FOCUS.id, FOCUS.el, FOCUS.win = nil, nil, nil
                end
            end)
            check(name .. ": draws", ok, err)
        end
    end
    -- one flow per tab with the taller words: what is typed in a field grows the field, and nothing scrolls in it
end
FOCUS.pad = false
ZEDQA_ROOT = 1
ZEDQA_LARGE = false
ZeD.applyTheme("dark", "orange", "small")

-- the flows ------------------------------------------------------------------------------
TC.qaHold, TC.qaRole, TC.qaGo, TC.qaStats, TC.qaLink = nil, nil, nil, nil, nil
local W, H = 480, 800
local panels = { server = newPanel(W, H), admin = newPanel(W, H) }
WINS.server._tkFields, WINS.admin._tkFields = nil, nil
local function draw(tab) frame(tab, panels[tab], W, H) end
local function stopOf(tab, id)
    for _, e in ipairs(stops(tab)) do if e.id == id then return e end end
    return nil
end
local function press(tab, id)
    draw(tab)
    local e = stopOf(tab, id)
    check("the stop is there: " .. id, e ~= nil)
    if e then e.onActivate(WINS[tab]) end
    draw(tab)
    return e
end
local function clearSent() SENT = {} end
local function lastSent(c)
    for i = #SENT, 1, -1 do if SENT[i].c == c then return SENT[i].a end end
    return nil
end
local function deliver(command, args)
    S.routes[Tk.MOD](command, args)
end
local function ackLast(c, extra)
    local a = lastSent(c)
    local r = { ok = true, rid = a and a.rid }
    if extra then for k, v in pairs(extra) do r[k] = v end end
    deliver("t_ack", r)
end
local function field(tab, key) return WINS[tab]._tkFields[key] end
local function type_(tab, key, text) field(tab, key)._entry:setText(text) end
local function clickStop(tab, id)
    draw(tab)
    local e = stopOf(tab, id)
    check("clickable: " .. id, e ~= nil)
    TABS[tab].onClick(WINS[tab], e.x + 1, e.y + 1)
    draw(tab)
end

C.mine, C.one, C.queue, C.card, C.list = {}, {}, nil, nil, nil
local sv, ad = stOf("server"), stOf("admin")
sv.card, ad.card = nil, nil

-- Ask the admins
draw("server")
press("server", "srv:ask")
check("Ask opens", sv.card and sv.card.kind == "ask")
do
    local e = stopOf("server", "tk:send")
    check("Send is gray before a kind", TC.state == nil and sv.tk.footRects ~= nil)
    for _, r in ipairs(sv.tk.footRects) do
        if r.b.id == "send" then check("Send says pick a kind", r.b.disabled and r.b.why == ZeD.tr("UI_ZeD_Tk_AskPickShort")) end
    end
    press("server", "tk:k:GRIEF")
    check("Griefing ticks Include where I am", sv.tk.ask.here == true and sv.tk.ask.kind == "GRIEF")
    for _, r in ipairs(sv.tk.footRects) do
        if r.b.id == "send" then check("Send says write", r.b.disabled and r.b.why == ZeD.tr("UI_ZeD_Tk_AskWrite")) end
    end
    press("server", "tk:here")
    check("the tick comes off", sv.tk.ask.here == false)
    press("server", "tk:here")
    type_("server", "ask", "Someone took my engine")
    draw("server")
    for _, r in ipairs(sv.tk.footRects) do
        if r.b.id == "send" then check("Send is ready", not r.b.disabled) end
    end
    clearSent()
    press("server", "tk:send")
    local a = lastSent("t_new")
    check("t_new goes with kind, here and text", a and a.kind == "GRIEF" and a.here == true and a.text == "Someone took my engine")
    deliver("t_ack", { rid = a.rid, ok = false, err = "wait", left = 42 })
    draw("server")
    check("a refusal keeps the card and the words", sv.card ~= nil and field("server", "ask"):getText() == "Someone took my engine")
    check("and says so", ZeD.Help.last == ZeD.tr("UI_ZeD_Tk_Err_wait", 42), ZeD.Help.last)
    clearSent()
    press("server", "tk:send")
    a = lastSent("t_new")
    GAME = {}
    deliver("t_ack", { rid = a.rid, ok = true, id = 16, file = "[GRIEF #16] Someone took my engine" })
    draw("server")
    check("sent: the card closes", sv.card == nil)
    check("the field is empty for next time", field("server", "ask"):getText() == "")
    check("the game's ticket is filed", GAME[1] and GAME[1][1] == "add" and GAME[1][3] == "[GRIEF #16] Someone took my engine")
    check("the answer is in the help line", ZeD.Help.last == ZeD.tr("UI_ZeD_Tk_Sent", 16), ZeD.Help.last)
    deliver("t_row", { pv = true, id = 16, kind = "GRIEF", st = "Sent", day = 12, last = "Someone took my engine", replies = 0 })
    draw("server")
    check("the row is in my tickets", stopOf("server", "srv:tk:t:16") ~= nil)
end

-- my ticket: a reply, staff closing it while it is open
press("server", "srv:tk:t:16")
check("my card opens", sv.card and sv.card.kind == "mine")
check("it asks for the ticket and marks it read", lastSent("t_one") and lastSent("t_read"))
deliver("t_one", { id = 16, kind = "GRIEF", st = "Sent", day = 12, filed = 1793913240, place = { x = 1, y = 2, z = 0 }, can = true, thread = { n = 1, { who = "Aretha", text = "Someone took my engine", t = 1 } } })
draw("server")
check("the reply field lands", stopOf("server", "tk:f:reply") and stopOf("server", "tk:f:reply").tkLand)
type_("server", "reply", "It was the blue pickup")
clearSent()
press("server", "tk:psend")
local a = lastSent("t_reply")
check("t_reply carries the words", a and a.text == "It was the blue pickup" and a.id == 16)
deliver("t_ack", { rid = a.rid, ok = true })
draw("server")
check("the field clears", field("server", "reply"):getText() == "")
clearSent()
deliver("t_row", { pv = true, id = 16, kind = "GRIEF", st = "Closed", day = 12, last = "x", replies = 1 })
check("a status change asks for the ticket again", lastSent("t_one") ~= nil)
deliver("t_one", { id = 16, kind = "GRIEF", st = "Closed", day = 12, filed = 1793913240, can = false, thread = { n = 1, { who = "Aretha", text = "x", t = 1 } } })
draw("server")
check("a closed ticket has no field", stopOf("server", "tk:f:reply") == nil)
deliver("t_gone", { id = 16 })
draw("server")
check("a ticket that goes takes its card with it", sv.card == nil)

-- the note's Open
C.openId = 5
deliver("t_one", { id = 5, kind = "BUG", st = "Answered", day = 2, can = false, thread = { n = 1, { who = "Aretha", text = "x", t = 1 } } })
draw("server")
check("the note's Open lands on the ticket", sv.card and sv.card.id == 5)
TC.back(WINS.server, sv)

-- the queue
local PAGE = { page = 1, pages = 2, n = 26, open = 9, spam = 1, gameMax = 0, skipped = 0, authors = { "Kade_R", "Rosa" }, rows = {} }
for i = 1, 25 do PAGE.rows[i] = { id = i, kind = "BUG", author = "Rosa", st = "Open", day = 3, first = "Ticket " .. i, replies = 0, src = "zed" } end
ad.tk.q = { status = "Open", newest = true, page = 1, find = "" }
ad.tk.queueKey = nil
clearSent()
C.queueOpen = false
draw("admin")
check("the queue opens on a frame", lastSent("t_queue") ~= nil and C.queueOpen == true)
deliver("t_queue", PAGE)
draw("admin")
check("the tab's label carries the count", TABS.admin.label() == ZeD.tr("UI_ZeD_Tk_TabCount", ZeD.tr("UI_ZeD_World_TabAdmin"), 9), TABS.admin.label())
check("a row per ticket", stopOf("admin", "adm:tk:t:25") ~= nil)
check("Previous is gray and says why", (function()
    for _, it in ipairs(ad.items) do
        for _, c in ipairs(it.ctls or {}) do
            if c.id == "prev" then return c.disabled and c.why == ZeD.tr("UI_ZeD_Tk_FirstPage") end
        end
    end
end)())
clearSent()
nowMs = nowMs + 2000
press("admin", "adm:tk:next")
check("Next asks for page 2", lastSent("t_queue") and lastSent("t_queue").page == 2)
clearSent()
nowMs = nowMs + 2000
press("admin", "adm:tk:s:Spam")
local q = lastSent("t_queue")
check("a filter goes to page 1", q and q.status == "Spam" and q.page == 1)
clearSent()
nowMs = nowMs + 2000
press("admin", "adm:tk:s:Open")
press("admin", "adm:tk:sort")
check("sort flips", lastSent("t_queue") and lastSent("t_queue").newest == false)
nowMs = nowMs + 2000
press("admin", "adm:tk:sort")
-- a pop-up: modal, its rows the only stops, B shuts it
press("admin", "adm:tk:pop:kind")
check("the pop-up opens", ad.tk.popup ~= nil)
draw("admin")
local rows = stops("admin")
check("its rows alone are the stops", rows._menuRows == true and #rows == 8, #rows)
check("the Find box hides under it", (function()
    for _, c in ipairs(panels.admin.kids) do if c.input and c.visible then return false end end
    return true
end)())
rows[1].onCancel()
draw("admin")
check("B shuts it", ad.tk.popup == nil)
press("admin", "adm:tk:pop:kind")
draw("admin")
clearSent()
nowMs = nowMs + 2000
for _, e in ipairs(stops("admin")) do
    if e.tkPop == "NONE" then e.onActivate(WINS.admin) end
end
check("picking No kind filters", lastSent("t_queue") and lastSent("t_queue").kind == "NONE", lastSent("t_queue") and lastSent("t_queue").kind)
press("admin", "adm:tk:pop:kind")
draw("admin")
nowMs = nowMs + 2000
for _, e in ipairs(stops("admin")) do
    if e.tkPop == "ALL" then e.onActivate(WINS.admin) end
end
-- Find waits for the last key
clearSent()
nowMs = nowMs + 2000
draw("admin")
clearSent()
field("admin", "find").input:setText("eng")
field("admin", "find"):update()
draw("admin")
check("Find does not ask on the key", lastSent("t_queue") == nil)
nowMs = nowMs + 500
draw("admin")
check("Find asks when it settles", lastSent("t_queue") and lastSent("t_queue").find == "eng", lastSent("t_queue") and lastSent("t_queue").find)
field("admin", "find").input:setText("")
field("admin", "find"):update()
nowMs = nowMs + 2000
draw("admin")
deliver("t_queue", PAGE)
ad.tk.q.page = 1
draw("admin")

-- the ticket card, each action
local REC = { id = 14, source = "zed", kind = "GRIEF", author = "Kade_R", status = "Open", day = 12, filed = 1793913240, place = { x = 6280, y = 5350, z = 0 },
    near = { n = 1, "Rosa" }, thread = { n = 1, { who = "Kade_R", t = 1, text = "Engine gone" } }, notes = { n = 0 }, gameFiled = true }
PAGE.rows[1] = { id = 14, kind = "GRIEF", author = "Kade_R", st = "Open", day = 12, first = "Engine gone", replies = 0 }
deliver("t_queue", PAGE)
clearSent()
press("admin", "adm:tk:t:14")
check("the card asks", lastSent("t_card") and lastSent("t_card").id == 14)
nowMs = nowMs + 11000
draw("admin")
check("no answer in 10 seconds: back, with the words", ad.card == nil and ad.tk.flashText == ZeD.tr("UI_ZeD_Tk_LoadFail"))
press("admin", "adm:tk:t:14")
deliver("t_card", REC)
draw("admin")
check("the answer field lands", stopOf("admin", "tk:f:answer") and stopOf("admin", "tk:f:answer").tkLand)
clearSent()
press("admin", "tk:take")
check("Take it goes", lastSent("t_take") ~= nil)
check("buttons wait while it goes", ad.tk.busy == true)
ackLast("t_take")
REC.status, REC.assignee = "Progress", "Aretha"
deliver("t_card", REC)
draw("admin")
check("taken by me: no Take it", stopOf("admin", "tk:take") == nil)
press("admin", "tk:pcard")
check("Player card opens the game's stats window", ISPlayerStatsUI.opened == 1)
type_("admin", "note", "Check the log")
clearSent()
press("admin", "tk:addnote")
check("Add note goes", lastSent("t_addnote") and lastSent("t_addnote").text == "Check the log")
ackLast("t_addnote")
draw("admin")
check("the note field clears", field("admin", "note"):getText() == "")
type_("admin", "answer", "On my way")
clearSent()
press("admin", "tk:ans")
check("Answer goes", lastSent("t_answer") and lastSent("t_answer").text == "On my way")
ackLast("t_answer", { first = false })
REC.status = "Answered"
REC.thread = { n = 2, REC.thread[1], { who = "Aretha", t = 2, text = "On my way", staff = true } }
deliver("t_card", REC)
draw("admin")
check("Answered offers Reopen, no field (E12 as drawn)", stopOf("admin", "tk:reopen") ~= nil and stopOf("admin", "tk:f:answer") == nil and stopOf("admin", "tk:close") == nil)
clearSent()
press("admin", "tk:reopen")
check("Reopen goes", lastSent("t_reopen") ~= nil)
ackLast("t_reopen")
REC.status = "Progress"
deliver("t_card", REC)
draw("admin")
clearSent()
press("admin", "tk:close")
check("Close goes", lastSent("t_close") ~= nil)
ackLast("t_close")
REC.status = "Closed"
deliver("t_card", REC)
draw("admin")
check("Closed offers Reopen", stopOf("admin", "tk:reopen") ~= nil)
COMMANDS = {}
press("admin", "tk:go")
check("Go there sends the game's command", COMMANDS[1] == "/teleportto 6280,5350,0", COMMANDS[1])
ZEDQA_CAPS.TeleportToCoordinates = false
draw("admin")
COMMANDS = {}
press("admin", "tk:go")
check("without the power Go there is gray and sends nothing", COMMANDS[1] == nil)
local e = stopOf("admin", "tk:go")
check("and says why", e and e.tkWhy() == ZeD.tr("UI_ZeD_Tk_NoGo"))
e.onContextMenu()
check("X says why too", ad.tk.flashText == ZeD.tr("UI_ZeD_Tk_NoGo"))
ZEDQA_CAPS.TeleportToCoordinates = true
ONLINE = false
draw("admin")
e = stopOf("admin", "tk:pcard")
check("Player card says the player is away", e and e.tkWhy() == ZeD.tr("UI_ZeD_Tk_NotOnline"))
ONLINE = true
ZEDQA_CAPS.CanSeePlayersStats = false
draw("admin")
e = stopOf("admin", "tk:pcard")
check("Player card says the role can't", e and e.tkWhy() == ZeD.tr("UI_ZeD_Tk_NoStats"))
ZEDQA_CAPS.CanSeePlayersStats = true
clearSent()
press("admin", "tk:spam")
ackLast("t_spam")
draw("admin")
check("Spam goes back to the queue", ad.card == nil and lastSent("t_spam") ~= nil)
check("the queue is asked again, and the server forgets the open card", lastSent("t_queue") ~= nil)
press("admin", "adm:tk:t:14")
REC.status, REC.spamBy = "Spam", "Aretha"
deliver("t_card", REC)
draw("admin")
clearSent()
press("admin", "tk:unspam")
check("Not spam goes", lastSent("t_unspam") ~= nil)
ackLast("t_unspam")
REC.status, REC.spamBy = "Open", nil
deliver("t_card", REC)
draw("admin")
check("Not spam stays on the card, open", ad.card ~= nil and stopOf("admin", "tk:spam") ~= nil)
-- Delete: admins only, behind the foot
S.admin = false
draw("admin")
check("a moderator has no Delete", stopOf("admin", "tk:del") == nil)
REC.status = "Spam"
deliver("t_card", REC)
draw("admin")
check("a moderator has no Delete on the Spam pile", stopOf("admin", "tk:del") == nil and stopOf("admin", "tk:unspam") ~= nil)
REC.status = "Open"
deliver("t_card", REC)
S.admin = true
draw("admin")
press("admin", "tk:del")
check("Delete asks in the foot", ad.tk.confirm == true and stopOf("admin", "tk:yesdel") ~= nil and stopOf("admin", "tk:nodel") ~= nil)
stopOf("admin", "tk:nodel").onCancel(WINS.admin)
draw("admin")
check("B keeps it", ad.tk.confirm == nil and stopOf("admin", "tk:del") ~= nil)
press("admin", "tk:del")
press("admin", "tk:nodel")
check("Keep it keeps it", ad.tk.confirm == nil)
press("admin", "tk:del")
clearSent()
press("admin", "tk:yesdel")
check("Delete for good goes", lastSent("t_delete") ~= nil)
ackLast("t_delete", {})
draw("admin")
check("it goes back to the queue", ad.card == nil)
press("admin", "adm:tk:t:14")
deliver("t_card", REC)
draw("admin")
deliver("t_gone", { id = 14 })
draw("admin")
check("deleted while open: back, with the words", ad.card == nil and ad.tk.flashText == ZeD.tr("UI_ZeD_Tk_Err_gone"))
-- leaving the tab closes the queue
nowMs = nowMs + 3000
EVENTS.OnTick.list[#EVENTS.OnTick.list]()
for _, fn in ipairs(EVENTS.OnTick.list) do fn() end
check("no frames: the queue closes", C.queueOpen == false)
draw("admin")
check("a frame opens it again", C.queueOpen == true)

-- the fallback (B9)
-- (the game calls so far had no reply here: the model's clock lets them go)
nowMs = nowMs + 11000
for _, fn in ipairs(EVENTS.OnTick.list) do fn() end
S.forceOff = true
C.mine, C.queue, C.card = {}, nil, nil
ad.tk.queueKey, sv.tk.mineKey = nil, nil
nowMs = nowMs + 20000
GAME = {}
draw("server")
check("my list comes from the game", GAME[1] and GAME[1][1] == "get" and GAME[1][2] == "Aretha")
C.onViewTickets({ size = function() return 0 end })
press("server", "srv:ask")
press("server", "tk:k:STUCK")
type_("server", "ask", "Under the floor")
GAME = {}
clearSent()
press("server", "tk:send")
check("Send files the game's ticket with the place in the words", GAME[1] and GAME[1][1] == "add" and GAME[1][3] == "[STUCK] Under the floor (6347 x 5372)", GAME[1] and GAME[1][3])
check("nothing to the server", lastSent("t_new") == nil)
check("the card closes", sv.card == nil)
check("the help line says one question and one answer", ZeD.Help.last == ZeD.tr("UI_ZeD_Tk_SentGame"), ZeD.Help.last)
local function row(g, a, m, v, aw, at)
    return { getTicketID = function() return g end, getAuthor = function() return a end, getMessage = function() return m end, isViewed = function() return v end,
        getAnswer = function()
            if not aw then return nil end
            return { getAuthor = function() return aw end, getMessage = function() return at end }
        end }
end
local function jlist(list) return { size = function() return #list end, get = function(_, i) return list[i + 1] end } end
C.onViewTickets(jlist({ row(5, "Aretha", "[STUCK] Under the floor (6347 x 5372)", true), row(6, "Aretha", "[BUG] Old one", true, "Hermit", "Fixed.") }))
draw("server")
check("my rows from the game", stopOf("server", "srv:tk:t:5") ~= nil and stopOf("server", "srv:tk:t:6") ~= nil)
press("server", "srv:tk:t:6")
check("a fallback card has no reply field", sv.card and sv.card.game and stopOf("server", "tk:f:reply") == nil)
local found = false
for _, t in ipairs(panels.server.texts) do if t.s == "Fixed." then found = true end end
check("and shows the game's one answer", found)
TC.back(WINS.server, sv)
nowMs = nowMs + 20000
GAME = {}
draw("admin")
check("the queue polls the game", GAME[1] and GAME[1][1] == "get" and GAME[1][2] == nil)
C.onViewTickets(jlist({ row(7, "Rosa", "[GRIEF] My fence", false), row(8, "tjk", "plain words", true, "Hermit", "Done.") }))
draw("admin")
check("rows from the game's list", stopOf("admin", "adm:tk:t:7") ~= nil and stopOf("admin", "adm:tk:t:8") == nil)
check("no Spam filter, no Closed", stopOf("admin", "adm:tk:s:Spam") == nil and stopOf("admin", "adm:tk:s:Closed") == nil and stopOf("admin", "adm:tk:pop:mine") == nil)
check("the count comes from the game's list", TC.openCount() == 1, TC.openCount())
press("admin", "adm:tk:s:All")
check("All shows the answered one", stopOf("admin", "adm:tk:t:8") ~= nil)
press("admin", "adm:tk:s:Open")
GAME = {}
press("admin", "adm:tk:t:7")
check("the fallback card is open", ad.card and ad.card.game)
check("opening it views the game's row", GAME[1] and GAME[1][1] == "viewed" and GAME[1][3] == 7)
C.onViewTickets(jlist({ row(7, "Rosa", "[GRIEF] My fence", true), row(8, "tjk", "plain words", true, "Hermit", "Done.") }))
check("no Take, Spam, Close or notes", stopOf("admin", "tk:take") == nil and stopOf("admin", "tk:spam") == nil and stopOf("admin", "tk:close") == nil and stopOf("admin", "tk:f:note") == nil)
type_("admin", "answer", "Looking")
draw("admin")
GAME = {}
press("admin", "tk:ans")
check("Answer is the game's answer", GAME[1] and GAME[1][1] == "add" and GAME[1][4] == 7 and GAME[1][3] == "Looking")
C.onViewTickets(jlist({ row(7, "Rosa", "[GRIEF] My fence", true, "Aretha", "Looking"), row(8, "tjk", "plain words", true, "Hermit", "Done.") }))
draw("admin")
check("then the field closes", stopOf("admin", "tk:f:answer") == nil)
press("admin", "tk:del")
GAME = {}
press("admin", "tk:yesdel")
check("Delete is the game's Remove", GAME[1] and GAME[1][1] == "remove" and GAME[1][2] == 7)
check("back at the queue", ad.card == nil)
C.onViewTickets(jlist({}))
S.forceOff = nil

-- frozen: Send still files the game's ticket
S.frozen = true
C.queue = PAGE
press("server", "srv:ask")
press("server", "tk:k:BUG")
type_("server", "ask", "Frozen one")
draw("server")
GAME = {}
clearSent()
press("server", "tk:send")
check("frozen: Send goes by the game", GAME[1] and GAME[1][1] == "add" and lastSent("t_new") == nil)
S.frozen = false

-- E12 flipped: Answered stays open to more words
Tk.REPLY_AT_ANSWERED = true
REC.status = "Answered"
C.card = REC
ad.tk.qaFresh = true
TC.qaOpen(WINS.admin, ad, "staff", 14)
draw("admin")
check("E12 on: an Answered ticket takes another answer", stopOf("admin", "tk:ans") ~= nil and stopOf("admin", "tk:close") ~= nil and stopOf("admin", "tk:reopen") == nil)
TC.back(WINS.admin, ad)
Tk.REPLY_AT_ANSWERED = false

-- what the review found ------------------------------------------------------------------
do
    local D = TC._D
    local function drew(tab, words)
        for _, t in ipairs(panels[tab].texts) do
            if t.s == words then return true end
        end
        return false
    end
    local function longRec(id, n)
        local r = { id = id, source = "zed", kind = "GRIEF", author = "Kade_R", status = "Progress", day = 1, filed = 1793913240, assignee = "Aretha",
            thread = { n = n }, notes = { n = 0 }, gameFiled = true }
        for i = 1, n do r.thread[i] = { who = "Kade_R", t = 1, text = string.rep("word ", 40) } end
        return r
    end
    local function openAdmin(r)
        C.queue = { page = 1, pages = 1, n = 1, open = 1, spam = 0, rows = { { id = r.id, kind = r.kind, author = r.author, st = r.status, day = 1, first = "x", replies = 0 } } }
        C.seq = C.seq + 1
        ad.tk.q = { status = "Open", newest = true, page = 1, find = "" }
        draw("admin")
        press("admin", "adm:tk:t:" .. r.id)
        deliver("t_card", r)
        draw("admin")
    end

    -- a field being typed in keeps its box and its caret, on a card that scrolls and one that does not
    FOCUS.pad = false
    for _, size in ipairs({ { 480, 800 }, { 360, 560 } }) do
        W, H = size[1], size[2]
        panels.admin = newPanel(W, H)
        WINS.admin._tkFields = nil
        local r = longRec(30, 12)
        openAdmin(r)
        ad.tk.scroll:setScrollPos(1)
        draw("admin")
        local box = field("admin", "answer")
        local inner = box._entry
        check("the field shows at the card's foot", box.visible, H)
        inner:focus()
        local kept = true
        for n = 1, 76 do
            inner:setText(string.rep("typing words ", n))
            draw("admin")
            if not (box.visible and inner:isFocused()) then kept = false end
        end
        check("typing 1000 characters keeps the box and the caret", kept, H)
        for _, it in ipairs(ad.tk.items) do
            if it.k == "field" and it.key == "answer" then
                check("a field is never taller than the view", it.h <= ad.tk.csh, it.h)
                check("and stays in it", it.y - ad.tk.off >= 0 and it.y - ad.tk.off + it.h <= ad.tk.csh + 1, it.y - ad.tk.off)
            end
        end
        inner:unfocus()
        inner:setText("")
        TC.back(WINS.admin, ad)
    end
    W, H = 480, 800
    panels.admin = newPanel(W, H)
    WINS.admin._tkFields = nil

    -- a staff answer closes the field a player is typing in
    do
        local me = { id = 40, kind = "BUG", st = "Progress", day = 1, filed = 1793913240, can = true, thread = { n = 1, { who = "Aretha", t = 1, text = "x" } } }
        C.one[40] = me
        TC.openMine(WINS.server, sv, 40)
        draw("server")
        type_("server", "reply", "half a thought")
        C.one[40] = { id = 40, kind = "BUG", st = "Answered", day = 1, filed = 1793913240, can = false, thread = me.thread }
        C.seq = C.seq + 1
        draw("server")
        check("the field goes, the words stay", stopOf("server", "tk:f:reply") == nil and drew("server", "half a thought"))
        check("the foot says why", drew("server", ZeD.tr("UI_ZeD_Tk_FieldGone")))
        check("an answer read on the card is said to be on screen", C.seeing(40))
        TC.back(WINS.server, sv)
        C.seeId = nil
    end

    -- with the controller the words have a line, in full
    do
        local r = longRec(31, 1)
        r.place = { x = 1, y = 2, z = 0 }
        r.status = "Open"
        r.assignee = nil
        openAdmin(r)
        FOCUS.pad = true
        ad.tk.flashText = nil
        draw("admin")
        local ans = stopOf("admin", "tk:ans")
        FOCUS.el, FOCUS.win, FOCUS.id = ans, WINS.admin, ans and ans.id
        draw("admin")
        check("a grayed Answer's reason is read in full", drew("admin", ZeD.tr("UI_ZeD_Tk_WriteAnswer")))
        TC.qaFlash(ad, ZeD.tr("UI_ZeD_Tk_Answered", "Kade_R"))
        draw("admin")
        check("so is the answer to a press", drew("admin", ZeD.tr("UI_ZeD_Tk_Answered", "Kade_R")))
        ad.tk.flashText = nil
        FOCUS.el, FOCUS.win, FOCUS.id = nil, nil, nil
        TC.back(WINS.admin, ad)
    end

    -- Previous and Next say why they are gray
    do
        C.queue = { page = 1, pages = 2, n = 30, open = 30, spam = 0, rows = { { id = 32, kind = "BUG", author = "a", st = "Open", first = "x", replies = 0 } } }
        C.seq = C.seq + 1
        ad.tk.q = { status = "Open", newest = true, page = 1, find = "" }
        FOCUS.pad = true
        draw("admin")
        local prev = stopOf("admin", "adm:tk:prev")
        check("grayed Previous is a stop", prev ~= nil)
        FOCUS.el, FOCUS.win, FOCUS.id = prev, WINS.admin, prev and prev.id
        draw("admin")
        check("its reason is a line in the list", drew("admin", ZeD.tr("UI_ZeD_Tk_FirstPage")))
        FOCUS.el, FOCUS.win, FOCUS.id = nil, nil, nil
        FOCUS.pad = false
        draw("admin")
    end

    -- a push of data lands the controller once, unless it has moved
    do
        local r = longRec(33, 1)
        C.queue = { page = 1, pages = 1, n = 1, open = 1, spam = 0, rows = { { id = 33, kind = "GRIEF", author = "Kade_R", st = "Progress", first = "x", replies = 0 } } }
        C.seq = C.seq + 1
        FOCUS.pad = true
        draw("admin")
        press("admin", "adm:tk:t:33")
        FOCUS.el = stopOf("admin", "tk:back")
        FOCUS.soon = {}
        deliver("t_card", r)
        draw("admin")
        local f = FOCUS.soon[1]
        check("the first frame with data lands", f ~= nil and #FOCUS.soon == 1)
        check("on the answer field", f and f.pred(stopOf("admin", "tk:f:answer")) and not f.pred(stopOf("admin", "tk:back")))
        TC.back(WINS.admin, ad)
        press("admin", "adm:tk:t:33")
        FOCUS.el = { id = "tk:m:1" }
        FOCUS.soon = {}
        deliver("t_card", r)
        draw("admin")
        check("not once the controller moved", #FOCUS.soon == 0)
        FOCUS.el = nil
        FOCUS.pad = false
        TC.back(WINS.admin, ad)
    end

    -- the back key ends the card's pushes
    do
        local r = longRec(34, 1)
        openAdmin(r)
        clearSent()
        TC.back(WINS.admin, ad)
        check("closing a card tells the server", lastSent("t_cardoff") ~= nil)
        check("a late push is dropped", (function() deliver("t_card", r); return C.card == nil end)())
    end

    -- Add note waits for its ack
    do
        local r = longRec(35, 1)
        openAdmin(r)
        type_("admin", "note", "one note")
        draw("admin")
        clearSent()
        press("admin", "tk:addnote")
        draw("admin")
        check("a second press sends nothing", stopOf("admin", "tk:addnote") ~= nil and (function()
            SENT = {}
            stopOf("admin", "tk:addnote").onActivate(WINS.admin)
            return lastSent("t_addnote") == nil
        end)())
        ad.tk.busy = nil
        TC.back(WINS.admin, ad)
    end

    -- a card the server has no record of leaves at once
    do
        clearSent()
        TC.openMine(WINS.server, sv, 77)
        draw("server")
        ackLast("t_one", { ok = false, err = "gone" })
        draw("server")
        check("gone comes at once", sv.card == nil and sv.tk.flashText == ZeD.tr("UI_ZeD_Tk_Err_gone"))
        sv.tk.flashText = nil
    end

    -- the wrap: a run with no spaces, and blank lines
    do
        local T = ZeD.T
        local long = string.rep("x", 1000)
        local lines = D.wrap(long, T.fontF2, 300)
        local total, fits = 0, true
        for _, s in ipairs(lines) do
            total = total + #s
            if ZeD.TM:MeasureStringX(T.fontF2, s) > 300 then fits = false end
        end
        check("a run with no spaces is cut to the width", #lines > 1 and fits and total == 1000, #lines)
        local para = D.wrap("one\n\ntwo", T.fontF2, 300)
        check("a blank line stays", #para == 3 and para[2] == "", #para)
        local r = longRec(36, 1)
        r.thread[1].text = long
        openAdmin(r)
        for _, t in ipairs(panels.admin.texts) do
            check("a long run draws inside the drawer", t.x + t.w <= W + 1, t.s)
        end
        TC.back(WINS.admin, ad)
    end

    -- the place on a card: a name and the coordinates
    do
        check("a row's where is the name", Tk.whereText({ name = "Riverside farm", x = 6280, y = 5350 }) == "Riverside farm")
        check("a card's where has both", Tk.whereFull({ name = "Riverside farm", x = 6280, y = 5350 }) == "Riverside farm, 6280 x 5350")
        check("with no name, the coordinates", Tk.whereFull({ x = 6280, y = 5350 }) == "6280 x 5350")
    end

    -- the claim on an adopted ticket is on the card, and a game answer in notes says what it is
    do
        local r = longRec(37, 1)
        r.source = "game"
        r.notes = { n = 1, { who = "Hermit", t = 1, text = "claimed", game = true } }
        openAdmin(r)
        draw("admin")
        check("the card says what it can't prove", drew("admin", ZeD.tr("UI_ZeD_Tk_HelpGameCard")) or (function()
            for _, it in ipairs(ad.tk.items) do
                if it.k == "sub" and it.text == ZeD.tr("UI_ZeD_Tk_HelpGameCard") then return true end
            end
            return false
        end)())
        local found = false
        for _, it in ipairs(ad.tk.items) do
            if it.k == "msg" and it.who == ZeD.tr("UI_ZeD_Tk_NoteGame", "Hermit", "Kade_R") then found = true end
        end
        check("a game answer is labeled", found)
        TC.back(WINS.admin, ad)
    end

    -- the wheel over a field scrolls the card
    do
        local r = longRec(38, 12)
        openAdmin(r)
        ad.tk.scroll:setScrollPos(1)
        draw("admin")
        local box = field("admin", "answer")
        local before = ad.tk.scroll.scrollPos
        local r2 = box._entry:onMouseWheel(-1)
        check("the wheel moves the card", r2 == true and ad.tk.scroll.scrollPos < before, ad.tk.scroll.scrollPos)
        TC.back(WINS.admin, ad)
    end

    -- the hint is drawn by the card, wrapped, under the empty box
    do
        local r = longRec(39, 1)
        openAdmin(r)
        draw("admin")
        check("the box draws no hint of its own", field("admin", "answer").placeholder == "")
        check("the card does", drew("admin", ZeD.tr("UI_ZeD_Tk_AnswerHint", "Kade_R")))
        TC.back(WINS.admin, ad)
    end

    -- the Player card's reason
    do
        local r = longRec(41, 1)
        ONLINE = false
        ZeD.ServerTab.players = { { user = "Kade_R", name = "Kade_R" } }
        openAdmin(r)
        draw("admin")
        check("on the server, not near", stopOf("admin", "tk:pcard").help == ZeD.tr("UI_ZeD_Adm_NotSeen"), stopOf("admin", "tk:pcard").help)
        ZeD.ServerTab.players = { { user = "other", name = "other" } }
        ad.tk.items = nil
        draw("admin")
        draw("admin")
        check("not on the server", stopOf("admin", "tk:pcard").help == ZeD.tr("UI_ZeD_Tk_NotOnline"), stopOf("admin", "tk:pcard").help)
        ZeD.ServerTab.players = {}
        ONLINE = true
        TC.back(WINS.admin, ad)
    end

    -- the fallback's claim
    do
        S.forceOff = true
        ad.tk.q = { status = "Open", newest = true, page = 1, find = "" }
        nowMs = nowMs + 20000
        draw("admin")
        C.onViewTickets(jlist({}))       -- (the frozen filing above is still waiting for its reply)
        C.onViewTickets(jlist({ row(50, "Rosa", "[BUG] help", false, "griefer", "go away") }))
        draw("admin")
        check("an unviewed answer stays in the Open list", stopOf("admin", "adm:tk:t:50") ~= nil)
        press("admin", "adm:tk:t:50")
        C.onViewTickets(jlist({ row(50, "Rosa", "[BUG] help", true, "griefer", "go away") }))
        check("the card still takes an answer", ad.card ~= nil)
        TC.back(WINS.admin, ad)
        C.onViewTickets(jlist({}))
        S.forceOff = nil
    end
end

print("ticket_cards_sim: " .. checks .. " checks, " .. failed .. " failed")
if failed > 0 then os.exit(1) end
