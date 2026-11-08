-- ZeD-UI/42/media/lua/client/ZeD/ServerTab.lua
-- ============================================================================
-- THE SERVER TAB (the director's multiplayer decisions, Nov 5 2026: ZeDUI/MP_DECISIONS.md, section 1)
-- "You on this server", in the Character window, only on a server (in single player the tab is not there):
--   SERVER     the server's name, the message of the day and The rules (a row that opens their card, ZeD_CommunityCards.lua, on
--              a server with that part), the players on it, your role; the server options to read (the game's window)
--   PVP        while the server's safety system is on: PvP on or off, the seconds left while it switches, a
--              non-PvP zone; the switch (the game's own toggle, ISEquippedItem:toggleSafety, with its log line)
--   PLAYERS    who is on the server (the game's scoreboard, asked again every few seconds while the tab shows)
--   NOTES      an invitation to a faction or a safehouse waits here, under the Server block, with Decline and Accept
--   NEWS       the server's posts, pinned first (ZeD_CommunityCards.lua)
--   EXTRAS     this server's extras in plain words, and your vehicle claims (ZeD_ExtrasCards.lua), with the server part
--   TICKETS    after the Server block, as drawn: N open, Ask the admins, my tickets (ZeD_TicketCards.lua: the block and
--              its two cards, Ask the admins and my ticket, pushed on top of this list behind st.card)
--   MAIL       on a server that keeps mail: the dial-in, Inbox, Write a letter (ZeD_MailCards.lua, punch list 104)
--   FACTION    yours as a row that opens its card; or Create Faction where the server allows
--   SAFEHOUSE  yours as a row that opens its card; or Can I claim this?, the server's rules and Claim Safehouse
--   WARS       on a server with wars: a row that opens their card
-- The game's user panel (ISUserPanelUI) is a set of buttons that open windows; this tab and its cards replace those for
-- players. Faction, safehouse and wars are ZeD_ClaimCards.lua, on the same frame as the ticket cards. Wording is the game's
-- own (MP_DECISIONS.md, section 6).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ZeD_CharacterWindow"
require "ZeD/ZeD_Claims"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_ClaimCards"
require "ZeD/ZeD_CommunityCards"
require "ZeD/ZeD_MailCards"

ZeD = ZeD or {}
local S = {}
ZeD.ServerTab = S

local TAB_ID = "server"
local PAD, ROW_GAP, BTN_GAP, SEC_GAP = 10, 4, 6, 8   -- design units
local PLAYERS_EVERY = 5000                          -- ms between scoreboard asks while the tab shows

local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function px(n) return ZeD.T.px(n) end

-- A button's words in sentence case: the game writes some of its English buttons in Title Case ("See Server
-- Options", "Create Faction"), and ZeD's buttons read in sentence case (ZeD.btnCase turns only ALL CAPS). English
-- only: other languages keep the game's own case (German nouns keep their capitals). A word with a capital inside
-- it (PvP) stays as written.
function S.btnWords(s)
    if not s then return s end
    local lang = safe(function() return tostring(Translator.getLanguage():name()) end, "EN")
    if lang ~= "EN" then return s end
    local n, caps = 0, 0
    for w in s:gmatch("%a+") do
        n = n + 1
        if w:sub(1, 1):find("%u") then caps = caps + 1 end
    end
    if n < 2 or caps < n then return s end
    local first = true
    local out = s:gsub("%a+", function(w)
        if first then first = false; return w end
        if w:sub(2):find("%u") then return w end
        return w:lower()
    end)
    return out
end

-- ---------------------------------------------------------------------------
-- THE PLAYERS: the game's scoreboard (the reply comes as an event)
-- ---------------------------------------------------------------------------
S.players = {}
S.askedAt = 0
function S.onScoreboard(usernames, displayNames)
    local out = {}
    pcall(function()
        for i = 0, usernames:size() - 1 do
            local u = tostring(usernames:get(i))
            local d = displayNames and displayNames:size() > i and tostring(displayNames:get(i)) or u
            out[#out + 1] = { user = u, name = (d ~= "" and d) or u }
        end
    end)
    table.sort(out, function(a, b) return a.name:lower() < b.name:lower() end)
    S.players = out
end
if Events and Events.OnScoreboardUpdate then Events.OnScoreboardUpdate.Add(S.onScoreboard) end
local function askPlayers()
    local now = getTimestampMs()
    if now - S.askedAt < PLAYERS_EVERY then return end
    S.askedAt = now
    if scoreboardUpdate then pcall(scoreboardUpdate) end
end
S.askPlayers = askPlayers

-- ---------------------------------------------------------------------------
-- WHAT THE TAB SHOWS, read once a frame while it shows
-- ---------------------------------------------------------------------------
local function pvpState(p)
    local so = getServerOptions and getServerOptions()
    if not (so and safe(function() return so:getBoolean("SafetySystem") end, false)) then return nil end
    local sf = safe(function() return p:getSafety() end, nil)
    if not sf then return nil end
    -- the game's safety on means PvP off (ISEquippedItem: the button is green while safety is on)
    local safetyOn = safe(function() return sf:isEnabled() end, true)
    local toggle = safe(function() return sf:getToggle() end, 0)
    local cool = safe(function() return sf:getCooldown() end, 0)
    local zone = safe(function() return NonPvpZone.getNonPvpZone(math.floor(p:getX()), math.floor(p:getY())) ~= nil end, false)
    return {
        on = not safetyOn,
        left = (toggle and toggle > 0) and math.ceil(toggle) or ((cool and cool > 0) and math.ceil(cool) or 0),
        switching = toggle and toggle > 0,
        zone = zone,
        allowed = safe(function() return sf:isToggleAllowed() end, false) and not zone,
    }
end
S.pvpState = pvpState

-- ---------------------------------------------------------------------------
-- WHAT THE TAB'S BUTTONS OPEN: the game's options window, as its user panel opens it, and ZeD's cards
-- ---------------------------------------------------------------------------
local OPEN = {}
function OPEN.options(p)
    if ISServerOptions and ISServerOptions.instance then ISServerOptions.instance:close() end
    local ui = ISServerOptions:new(50, 50, 800, 800, p)
    ui:initialise(); ui:addToUIManager()
end
function OPEN.faction(p, win) ZeD.ClaimCards.openFaction(win, win._serverTab) end
function OPEN.claim(p, win) ZeD.ClaimCards.claim(win, win._serverTab) end
function OPEN.ask(p, win) ZeD.TicketCards.openAsk(win, win._serverTab) end
function OPEN.pvp()
    if ISEquippedItem and ISEquippedItem.toggleSafety then ISEquippedItem.toggleSafety(nil) end
end
S.OPEN = OPEN

-- ---------------------------------------------------------------------------
-- LAYOUT: one list of items, the whole tab scrolling as one
-- ---------------------------------------------------------------------------
local function state(win)
    local st = win._serverTab
    if not st then
        st = { scroll = ZeD_ScrollbarState:new(), items = {}, btns = {} }
        win._serverTab = st
    end
    return st
end

local function add(L, it) L[#L + 1] = it; return it end
local function head(L, text, count) add(L, { k = "head", text = text, count = count }) end
local function row(L, label, value, dot) add(L, { k = "row", label = label, value = value, dot = dot }) end
local function line(L, text) add(L, { k = "line", text = text }) end
local function btn(L, id, text, help, disabled) add(L, { k = "btn", id = id, text = S.btnWords(text), help = help, disabled = disabled }) end

local function build(p, win, st)
    local T = ZeD.T
    local L = {}
    local so = getServerOptions and getServerOptions()
    -- SERVER
    head(L, tr("UI_ZeD_Srv_Server"))
    local name = safe(function() return so:getOption("PublicName") end, "")
    if name == "" then name = safe(function() return getServerName() end, "") end
    if name ~= "" then row(L, tr("UI_ZeD_Srv_Name"), name) end
    ZeD.CommunityCards.serverItems(L, win, st)
    row(L, tr("UI_ZeD_Srv_Online"), tostring(#S.players))
    local role = safe(function() return p:getRole():getName() end, nil)
    if role then row(L, tr("UI_ZeD_Srv_Role"), role) end
    local seeOpts = safe(function() return p:getRole():hasCapability(Capability.SeePublicServerOptions) end, false)
    btn(L, "options", getText("IGUI_AdminPanel_SeeServerOptions"), tr("UI_ZeD_Srv_HelpOptions"), not seeOpts)
    -- INVITATIONS
    ZeD.ClaimCards.notes(L, win, st)
    -- NEWS, then THIS SERVER'S EXTRAS, as drawn
    ZeD.CommunityCards.newsItems(L, win, st)
    if ZeD.ExtrasCards then ZeD.ExtrasCards.blocks(L, win, st) end
    -- TICKETS
    local function btnItem(id, text, help) return { k = "btn", id = id, text = S.btnWords(text), help = help } end
    ZeD.TicketCards.playerItems(L, win, st, btnItem)
    -- MAIL (punch list 104), on a server that keeps it
    if ZeD.MailCards then ZeD.MailCards.serverItems(L, win, st) end
    -- FACTION, SAFEHOUSE, WARS
    ZeD.ClaimCards.blocks(L, win, st, btnItem)
    -- PVP (only while the server's safety system is on)
    local pv = pvpState(p)
    if pv then
        head(L, tr("UI_ZeD_Srv_PvP"))
        local word = tr(pv.on and "UI_ZeD_Srv_PvPOn" or "UI_ZeD_Srv_PvPOff")
        local val = (pv.left > 0) and tr("UI_ZeD_Srv_PvPLeft", pv.left) or ""
        row(L, word, val, pv.on and T.danger or T.positive)
        if pv.zone then line(L, getText("IGUI_PvpZone_NonPvpZone")) end
        btn(L, "pvp", tr(pv.on and "UI_ZeD_Srv_PvPTurnOff" or "UI_ZeD_Srv_PvPTurnOn"),
            tr(pv.zone and "UI_ZeD_Srv_HelpPvPZone" or "UI_ZeD_Srv_HelpPvP"), not pv.allowed)
    end
    -- PLAYERS
    head(L, tr("UI_ZeD_Srv_Players"), #S.players)
    if #S.players == 0 then line(L, tr("UI_ZeD_Srv_PlayersWait")) end
    local me = safe(function() return p:getUsername() end, "")
    for _, pl in ipairs(S.players) do
        add(L, { k = "player", text = pl.name, me = (pl.user == me) })
    end
    return L
end

-- each item's height and place (y from the top of the list); buttons sit one to a line, at their own width
local function measure(L, w)
    local T = ZeD.T
    local f1h = ZeD.TM:getFontHeight(T.fontF1)
    local y = 0
    for i, it in ipairs(L) do
        if it.k == "head" then
            if i > 1 then y = y + px(SEC_GAP) end
            it.h = px(20)
        elseif it.k == "row" or it.k == "player" then
            it.h = math.max(f1h, ZeD.TM:getFontHeight(T.fontF3)) + px(ROW_GAP)
        elseif it.k == "line" then
            it.h = ZeD.TM:getFontHeight(T.fontF2) + px(ROW_GAP)
        elseif it.k == "btn" then
            y = y + px(BTN_GAP)
            it.h = T.buttonH
            it.w = math.min(w - 2 * px(PAD), ZeD.Molecules.buttonW(it.text))
        elseif it.k == "tk" then
            it.h = ZeD.TicketCards.itemH(it, w - 2 * px(PAD))
        elseif it.k == "cl" then
            it.h = ZeD.ClaimCards.itemH(it, w - 2 * px(PAD))
        end
        it.y = y
        y = y + it.h
    end
    return y + px(PAD)
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
local _fo = {}
local function focusOf(win, id)
    local Fo = ZeD.Input and ZeD.Input.Focus
    if Fo and Fo.isFocused and Fo.isFocused(win, nil, id) then _fo.win = win; return _fo end
    return nil
end

function S.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local M = ZeD.Molecules
    local st = state(win)
    local p = win._playerObj
    if not p then return end
    local TC = ZeD.TicketCards
    TC.bind(win, st, "srv:tk:", "charTabContent")
    TC.frameServer(win, st)
    ZeD.ClaimCards.frame(win, st)
    askPlayers()
    if st.card then
        TC.renderCard(panel, win, st, x, y, w, h)
        return
    end
    local L = build(p, win, st)
    st.items = L
    local headH = M.getTabHeaderH()
    local sy, sh = y + headH, h - headH
    local listH = measure(L, w - T.sp.scrollbarW)
    local scroll = st.scroll
    local needs = listH > sh
    scroll.visible = needs
    local maxOff = math.max(0, listH - sh)
    if needs then
        scroll.x, scroll.y, scroll.height = x + w - T.sp.scrollbarW, sy, sh
        scroll:setBarSize(sh / math.max(1, listH))
    else
        scroll:setScrollPos(0)
    end
    -- the controller's focus kept in view
    local Fo = ZeD.Input and ZeD.Input.Focus
    local fe = Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.getFocusedElement and Fo.getFocusedElement(win)
    if needs and fe and fe.srv and fe.cy then
        local off0 = math.floor(scroll.scrollPos * maxOff)
        local top, bot = fe.cy, fe.cy + (fe.h or 0)
        local off1 = off0
        if top < off0 then off1 = top elseif bot > off0 + sh then off1 = bot - sh end
        if off1 ~= off0 and maxOff > 0 then scroll:setScrollPos(math.max(0, math.min(1, off1 / maxOff))) end
    end
    local off = needs and math.floor(scroll.scrollPos * maxOff) or 0
    st.off, st.sy, st.x, st.w = off, sy, x, w
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    local cw = w - (needs and T.sp.scrollbarW or 0)
    local pad = px(PAD)
    local btns = {}
    st.btns = btns
    TC.beginList(win, st, sy, sh, ZeD.ClaimCards.listHelp())
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(L) do
        local dy = sy + it.y - off
        if dy + it.h >= sy and dy <= sy + sh then
            if it.k == "head" then
                M.drawSectionHeader(panel, x + pad, dy, cw - pad, it.text, it.count, true, false, nil, nil, pad, nil, true)
                if it.right then
                    ZeD.Atoms.drawTextRight(panel, it.right, x + cw - pad, dy + math.floor((it.h - ZeD.TM:getFontHeight(T.fontF1)) / 2), T.fontF1, T.textDim)
                end
            elseif it.k == "tk" then
                TC.drawItem(panel, win, st, it, x, dy, cw, mx, my)
            elseif it.k == "cl" then
                ZeD.ClaimCards.drawItem(panel, win, st, it, x, dy, cw, mx, my)
            elseif it.k == "row" then
                if it.dot then M.drawStatRowDot(panel, x + pad, dy, cw - 2 * pad, it.label, it.value, it.dot)
                else M.drawStatRow(panel, x + pad, dy, cw - 2 * pad, it.label, it.value) end
            elseif it.k == "line" then
                M.drawEmptyLine(panel, x + pad, dy, cw - 2 * pad, it.text)
            elseif it.k == "player" then
                local c = it.me and T.accent or T.text
                panel:drawText(it.text, x + pad, dy + math.floor(px(ROW_GAP) / 2), c.r, c.g, c.b, c.a or 1, T.fontF2)
            elseif it.k == "btn" then
                local bx = x + pad
                local hov = mx ~= nil and mx >= bx and mx < bx + it.w and my >= dy and my < dy + it.h
                M.drawButton(panel, bx, dy, it.w, it.h, it.text, it.variant or "default", hov and isMouseButtonDown(0), nil,
                    { hover = hov, disabled = it.disabled, help = it.help, win = win, focus = focusOf(win, "srv:" .. it.id) })
                btns[#btns + 1] = { x = bx, y = dy, w = it.w, h = it.h, cy = it.y, id = it.id, disabled = it.disabled }
            end
        end
    end
    panel:clearStencilRect()
    -- (PZ clips do not nest: the list's rect, once cleared, stays shut to what draws next, so the
    -- whole tab is opened again for the scrollbar and the pop-up over the list...)
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    M.drawTabHeader(panel, x, y, w, tr("UI_ZeD_Char_TabServer"), false, false, true)
    if needs then scroll:draw(panel) end
    TC.endList(panel, win, st, sy, sy + sh)
    -- (...and that clip comes off here: the tab ends with the clips it started with; punch list 95)
    panel:clearStencilRect()
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------
local function press(win, id)
    local p = win._playerObj
    if not p or not OPEN[id] then return end
    pcall(function() getSoundManager():playUISound("UIActivateButton") end)
    local ok, err = pcall(OPEN[id], p, win)
    if not ok then ZeD.logOnce("server tab " .. id, err) end
end

function S.onClick(win, x, y)
    local st = state(win)
    local TC = ZeD.TicketCards
    if st.card then
        TC.cardClick(win, st, x, y)
        return
    end
    local sc = st.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return
    end
    if TC.listClick(win, st, x, y) then return end
    for _, b in ipairs(st.btns or {}) do
        if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then
            if not b.disabled then press(win, b.id) end
            return
        end
    end
end

-- the controller's stops: each button (a greyed one too, so its help line can be read)
function S.buildFocusables(win)
    local st = win._serverTab
    if not st then return {} end
    if st.card then return ZeD.TicketCards.cardStops(win, st) end
    local out = {}
    local sy, off = st.sy or 0, st.off or 0
    for _, it in ipairs(st.items or {}) do
        if it.k == "btn" then
            local id = it.id
            local dis = it.disabled
            out[#out + 1] = { x = (st.x or 0) + px(PAD), y = sy + it.y - off, w = it.w, h = it.h, cy = it.y, id = "srv:" .. id,
                srv = true, help = it.help,
                onFocus = function() end,
                onActivate = function(w) if not dis then press(w, id) end end }
        elseif it.k == "tk" then
            ZeD.TicketCards.itemStops(out, st, it, (st.x or 0) + px(PAD), sy + it.y - off, st.w or 0, "srv")
        elseif it.k == "cl" then
            ZeD.ClaimCards.itemStops(out, st, it, (st.x or 0) + px(PAD), sy + it.y - off, st.w or 0, "srv")
        end
    end
    return out
end

function S.scrollKey(win)
    local st = win._serverTab
    if not st then return nil end
    if st.card then return ZeD.TicketCards.cardKey(st) end
    local n = 0
    for _, it in ipairs(st.items or {}) do if it.k == "btn" then n = n + 1 end end
    return tostring(st.off or 0) .. ":" .. n .. ":" .. #S.players .. ":" .. ZeD.TicketCards.listKey(st) .. ":" .. ZeD.ClaimCards.listKey(st)
end

-- ---------------------------------------------------------------------------
-- THE TAB: only on a server
-- ---------------------------------------------------------------------------
require "ZeD/ZeD_TabPx"
if ZeD.TabPx and ZeD.TabPx.ICONS then ZeD.TabPx.ICONS[TAB_ID] = true end

ZeD_CharacterWindow.addTab({
    id = TAB_ID, after = "skills", group = 2, glyph = "V",
    iconName = "server-tab-white",
    label = function() return tr("UI_ZeD_Char_TabServer") end,
    visible = function() return isClient() end,
    wheelHide = function() return not isClient() end,   -- (not on the D-pad wheels in single player either)
    render = S.render,
    scroll = function(win)
        local st = win._serverTab
        return st and (ZeD.TicketCards.activeScroll(st) or st.scroll) or nil
    end,
    onClick = S.onClick,
    buildFocusables = S.buildFocusables,
    scrollKey = S.scrollKey,
})

return S
