-- ZeD-UI/42/media/lua/client/ZeD/AdminTab.lua
-- ============================================================================
-- THE ADMIN TAB (the director's multiplayer decisions, Nov 5 2026: ZeDUI/MP_DECISIONS.md, sections 1 and 4)
-- In the World window, for admins only (the game's own test: the role has an admin tool), on a server only.
-- The first pass redraws the everyday tools; each shows only with the capability the game asks for it:
--   PLAYERS       who is on (the game's scoreboard); pick one: Teleport to, Bring here, Check stats, Kick, Ban
--                 (Kick and Ban ask first, in place); the server's own commands, as the game's scoreboard sends them
--   ADMIN POWERS  your own powers (invisible, god mode, no clip ...), the game's list (ISAdminPowerUI.OptionList)
--                 with its words; a tick applies it and tells the server, as the game's Save does
--   SERVER MESSAGE a line every player sees (/servermsg), typed in the game's text prompt (ZeD draws it)
--   TICKETS       the players' tickets (the game's getTickets), each with its answer; Answer and Remove
--   SAFEHOUSES    every safehouse and FACTIONS every faction; pick one to open it in the game's own window
--   MORE TOOLS    the rest of the game's admin panel, its own windows: roles, users, statistics, the mini
--                 scoreboard, server and sandbox options, the PvP log, weather, safe zones, non-PvP zones, the zone
--                 editor, the item list, check your stats
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ServerTab"
require "ZeD/ZeD_WorldWindow"

ZeD = ZeD or {}
local A = {}
ZeD.AdminTab = A

local TAB_ID = "admin"
local PAD, ROW_GAP, BTN_GAP, SEC_GAP = 10, 4, 6, 8   -- design units
local TICKETS_EVERY = 10000

local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function px(n) return ZeD.T.px(n) end
local function cap(p, name) return safe(function() return p:getRole():hasCapability(Capability[name]) end, false) end
local function quote(s) return "\"" .. tostring(s):gsub("\"", "") .. "\"" end

function A.visible()
    if not isClient() then return false end
    local p = getPlayer()
    return p ~= nil and safe(function() return p:getRole():hasAdminTool() end, false)
end

-- ---------------------------------------------------------------------------
-- THE TICKETS (the reply comes as an event)
-- ---------------------------------------------------------------------------
A.tickets = {}
A.askedAt = 0
function A.onTickets(list)
    local out = {}
    pcall(function()
        for i = 0, list:size() - 1 do
            local t = list:get(i)
            local ans = safe(function() return t:getAnswer() end, nil)
            out[#out + 1] = {
                id = safe(function() return t:getTicketID() end, 0),
                author = safe(function() return t:getAuthor() end, ""),
                text = safe(function() return t:getMessage() end, ""),
                answer = ans and (safe(function() return ans:getAuthor() end, "") .. ": " .. safe(function() return ans:getMessage() end, "")) or nil,
            }
        end
    end)
    A.tickets = out
end
if Events and Events.ViewTickets then Events.ViewTickets.Add(A.onTickets) end
local function askTickets(force)
    local now = getTimestampMs()
    if not force and now - A.askedAt < TICKETS_EVERY then return end
    A.askedAt = now
    if getTickets then pcall(getTickets, nil) end
end

-- ---------------------------------------------------------------------------
-- WHAT THE BUTTONS DO
-- ---------------------------------------------------------------------------
local function openUI(ui) ui:initialise(); ui:addToUIManager(); if ui.setVisible then ui:setVisible(true) end end
local function closeOld(cls, how) if cls and cls.instance then pcall(function() cls.instance[how or "close"](cls.instance) end) end end
local function textPrompt(title, fill, fn)
    local box = ISTextBox:new(0, 0, 280, 180, title, fill or "", nil, function(_, button)
        if button.internal ~= "OK" then return end
        local entry = button.parent and button.parent.entry
        local text = entry and entry:getText() or ""
        text = text:match("^%s*(.-)%s*$")
        if text ~= "" then fn(text) end
    end)
    box:initialise()
    box:addToUIManager()
    if JoypadState.players[1] then setJoypadFocus(0, box) end
end

local DO = {}
function DO.tp(p, st) SendCommandToServer("/teleport " .. quote(st.sel.user)) end
function DO.bring(p, st) SendCommandToServer("/teleportplayer " .. quote(st.sel.user) .. " " .. quote(p:getUsername())) end
function DO.stats(p, st)
    local who = getPlayerFromUsername(st.sel.user)
    if not who then st.note = tr("UI_ZeD_Adm_NotSeen"); return end
    closeOld(ISPlayerStatsUI)
    openUI(ISPlayerStatsUI:new(50, 50, 800 + getCore():getOptionFontSizeReal() * 50, 800, who, p))
end
function DO.kick(p, st) st.ask = { act = "kick", user = st.sel.user, name = st.sel.name } end
function DO.ban(p, st) st.ask = { act = "ban", user = st.sel.user, name = st.sel.name } end
function DO.askno(p, st) st.ask = nil end
function DO.askyes(p, st)
    local a = st.ask
    st.ask = nil
    if not a then return end
    if a.act == "kick" then SendCommandToServer("/kickuser " .. quote(a.user))
    elseif a.act == "ban" then SendCommandToServer("/banuser " .. quote(a.user)) end
end
function DO.servermsg(p, st)
    textPrompt(tr("UI_ZeD_Adm_ServerMsgAsk"), "", function(text) SendCommandToServer("/servermsg " .. quote(text)) end)
end
function DO.answer(p, st)
    local t = st.ticket
    if not t then return end
    textPrompt(tr("UI_ZeD_Adm_AnswerAsk", t.author), "", function(text)
        addTicket(p:getUsername(), text, t.id)
        askTickets(true)
    end)
end
function DO.remove(p, st)
    local t = st.ticket
    if not t then return end
    removeTicket(t.id)
    st.ticket = nil
    askTickets(true)
end
function DO.safehouse(p, st)
    local h = st.house
    if not h then return end
    closeOld(ISSafehouseUI)
    local width = 500 + getCore():getOptionFontSizeReal() * 30
    openUI(ISSafehouseUI:new((getCore():getScreenWidth() - width) / 2, getCore():getScreenHeight() / 2 - 225, width, 450, h, p))
end
function DO.faction(p, st)
    local f = st.faction
    if not f then return end
    closeOld(ISFactionUI)
    openUI(ISFactionUI:new(getCore():getScreenWidth() / 2 - 250, getCore():getScreenHeight() / 2 - 225, 500, 450, f, p))
end
-- the rest of the game's admin panel, opened as its ISAdminPanelUI:onOptionMouseDown opens them
local MORE = {
    { id = "roles",   cap = "RolesRead",           key = "IGUI_AdminPanel_SeeRoles",
      run = function(p) requestRoles(); closeOld(ISRolesList, "closeModal"); openUI(ISRolesList:new(50, 50, 600, 800, p)) end },
    { id = "users",   cap = "SeeNetworkUsers",     key = "IGUI_AdminPanel_SeeUsers",
      run = function(p) requestUsers(); closeOld(ISUsersList, "closeModal"); openUI(ISUsersList:new(50, 50, 800 + getCore():getOptionFontSizeReal() * 50, 600, p)) end },
    { id = "statistics", cap = "GetStatistic",     key = "IGUI_AdminPanel_ShowStatistics",
      run = function(p) closeOld(ISStatisticsUI); openUI(ISStatisticsUI:new(50, 50, p)) end },
    { id = "scoreboard", cap = "SeePlayersConnected", key = "IGUI_AdminPanel_MiniScoreboard",
      run = function(p) closeOld(ISMiniScoreboardUI); openUI(ISMiniScoreboardUI:new(50, 50, 300, 300, p)) end },
    { id = "options", cap = "SeePublicServerOptions", key = "IGUI_AdminPanel_SeeServerOptions",
      run = function(p) closeOld(ISServerOptions); openUI(ISServerOptions:new(50, 50, 900, 800, p)) end },
    { id = "sandbox", cap = "SandboxOptions",      key = "IGUI_AdminPanel_SandboxOptions",
      run = function(p) closeOld(ISServerSandboxOptionsUI); openUI(ISServerSandboxOptionsUI:new(150, 150, 800, 600)) end },
    { id = "pvplog",  cap = "PVPLogTool",          key = "IGUI_AdminPanel_PVPLogTool",
      run = function(p) closeOld(ISPVPLogToolUI); openUI(ISPVPLogToolUI:new(50, 50, 500, 700)) end },
    { id = "climate", cap = "ClimateManager",      key = "IGUI_Adm_Weather_ClimateControl",
      run = function(p) local ui = ISAdminWeather.OnOpenPanel(); if ui and ui.onMadeActive then ui:onMadeActive() end end },
    { id = "safezone", cap = "CanSetupSafehouses", key = "IGUI_AdminPanel_Safezone",
      run = function(p) closeOld(ISAddSafeZoneUI); openUI(ISAddSafeZoneUI:new(getCore():getScreenWidth() / 2 - 210, getCore():getScreenHeight() / 2 - 200, 300 + getCore():getOptionFontSizeReal() * 50, 400, p)) end },
    { id = "nonpvp",  cap = "CanSetupNonPVPZone",  key = "IGUI_AdminPanel_NonPvpZone",
      run = function(p) closeOld(ISPvpZonePanel); openUI(ISPvpZonePanel:new(50, 50, 600, 600, p)) end },
    { id = "zones",   cap = { "CanSetupSafehouses", "CanSetupNonPVPZone" }, key = "IGUI_AdminPanel_ZoneEditor",
      run = function(p) ISMultiplayerZoneEditor.ToggleEditor() end },
    { id = "items",   cap = "AddItem",             key = "IGUI_AdminPanel_ItemList",
      run = function(p) closeOld(ISItemsListViewer); openUI(ISItemsListViewer:new(50, 200, 1050 + getCore():getOptionFontSizeReal() * 100, 650 + getCore():getOptionFontSizeReal() * 50, p)) end },
    { id = "mystats", cap = "CanSeePlayersStats",  key = "IGUI_AdminPanel_CheckYourStats",
      run = function(p) closeOld(ISPlayerStatsUI); openUI(ISPlayerStatsUI:new(50, 50, 800 + getCore():getOptionFontSizeReal() * 50, 800, p, p)) end },
}
local function allowed(p, c)
    if type(c) == "table" then for _, n in ipairs(c) do if cap(p, n) then return true end end; return false end
    return cap(p, c)
end
A.MORE = MORE

-- ---------------------------------------------------------------------------
-- LAYOUT
-- ---------------------------------------------------------------------------
local function state(win)
    local st = win._adminTab
    if not st then st = { scroll = ZeD_ScrollbarState:new(), items = {}, hits = {} }; win._adminTab = st end
    return st
end
local function add(L, it) L[#L + 1] = it; return it end
local function head(L, text, count) add(L, { k = "head", text = text, count = count }) end
local function line(L, text) add(L, { k = "line", text = text }) end
local function pick(L, id, text, sub, on) add(L, { k = "pick", id = id, text = text, sub = sub, on = on }) end
local function btns(L, list) if #list > 0 then add(L, { k = "btns", list = list }) end end
local function B(id, text, help, disabled, danger)
    local S = ZeD.ServerTab
    return { id = id, text = (S and S.btnWords) and S.btnWords(text) or text, help = help, disabled = disabled, danger = danger }
end

local function powers(p, L)
    local opts = ISAdminPowerUI and ISAdminPowerUI.OptionList
    if not (opts and safe(function() return p:getRole():hasAdminPower() end, false)) then return end
    head(L, getText("IGUI_AdminPanel_AdminPower"))
    for _, o in ipairs(opts) do
        if safe(function() return p:getRole():hasCapability(o.capability) end, false) then
            o.player = p
            local on = safe(function() return o:getValue() end, false) and true or false
            local help = safe(function() return getTextOrNull("IGUI_CheatPanel_" .. o.id .. "_tooltip") end, nil)
            add(L, { k = "check", id = o.id, text = o.text, on = on, help = help, opt = o })
        end
    end
end

local function build(p, st)
    local L = {}
    -- PLAYERS
    local S = ZeD.ServerTab
    local players = S and S.players or {}
    head(L, tr("UI_ZeD_Srv_Players"), #players)
    if #players == 0 then line(L, tr("UI_ZeD_Srv_PlayersWait")) end
    local me = safe(function() return p:getUsername() end, "")
    if st.sel then
        local still = false
        for _, pl in ipairs(players) do if pl.user == st.sel.user then still = true end end
        if not still then st.sel, st.ask = nil, nil end
    end
    for _, pl in ipairs(players) do
        pick(L, "p:" .. pl.user, pl.name, (pl.user == me) and tr("UI_ZeD_Adm_You") or nil, st.sel and st.sel.user == pl.user)
        L[#L].pl = pl
        if st.sel and st.sel.user == pl.user then
            if st.ask then
                line(L, tr(st.ask.act == "kick" and "UI_ZeD_Adm_KickAsk" or "UI_ZeD_Adm_BanAsk", st.ask.name))
                btns(L, { B("askno", getText("UI_Cancel"), nil), B("askyes", tr(st.ask.act == "kick" and "UI_ZeD_Adm_Kick" or "UI_ZeD_Adm_Ban"), nil, false, true) })
            else
                local self = pl.user == me
                local list = {}
                if not self and cap(p, "TeleportToPlayer") then list[#list + 1] = B("tp", getText("UI_Scoreboard_Teleport"), tr("UI_ZeD_Adm_HelpTp")) end
                if not self and cap(p, "TeleportPlayerToAnotherPlayer") then list[#list + 1] = B("bring", getText("UI_Scoreboard_TeleportToYou"), tr("UI_ZeD_Adm_HelpBring")) end
                if cap(p, "CanSeePlayersStats") then list[#list + 1] = B("stats", tr("UI_ZeD_Adm_Stats"), tr("UI_ZeD_Adm_HelpStats")) end
                if not self and cap(p, "KickUser") then list[#list + 1] = B("kick", tr("UI_ZeD_Adm_Kick"), tr("UI_ZeD_Adm_HelpKick"), false, true) end
                if not self and cap(p, "BanUnbanUser") then list[#list + 1] = B("ban", tr("UI_ZeD_Adm_Ban"), tr("UI_ZeD_Adm_HelpBan"), false, true) end
                btns(L, list)
                if st.note then line(L, st.note) end
            end
        end
    end
    -- ADMIN POWERS
    powers(p, L)
    -- SERVER MESSAGE
    if cap(p, "DisplayServerMessage") then
        head(L, tr("UI_ZeD_Adm_ServerMsg"))
        btns(L, { B("servermsg", tr("UI_ZeD_Adm_ServerMsgWrite"), tr("UI_ZeD_Adm_HelpServerMsg")) })
    end
    -- TICKETS
    if cap(p, "AnswerTickets") then
        askTickets()
        head(L, getText("IGUI_AdminPanel_SeeTickets"), #A.tickets)
        if #A.tickets == 0 then line(L, tr("UI_ZeD_Adm_NoTickets")) end
        for _, t in ipairs(A.tickets) do
            local on = st.ticket and st.ticket.id == t.id
            pick(L, "t:" .. tostring(t.id), t.author, t.answer and tr("UI_ZeD_Adm_Answered") or nil, on)
            L[#L].ticket = t
            add(L, { k = "text", text = t.text })
            if t.answer then add(L, { k = "text", text = t.answer, dim = true }) end
            if on then
                btns(L, { B("answer", getText("IGUI_TicketUI_AnswerTicket"), tr("UI_ZeD_Adm_HelpAnswer")),
                          B("remove", getText("IGUI_TicketUI_RemoveTicket"), tr("UI_ZeD_Adm_HelpRemove"), false, true) })
            end
        end
    end
    -- SAFEHOUSES
    if cap(p, "CanSetupSafehouses") then
        local list = safe(function() return SafeHouse.getSafehouseList() end, nil)
        local n = list and safe(function() return list:size() end, 0) or 0
        head(L, getText("IGUI_AdminPanel_SeeSafehouses"), n)
        if n == 0 then line(L, tr("UI_ZeD_Adm_NoSafehouses")) end
        for i = 0, n - 1 do
            local h = list:get(i)
            local title = safe(function() return h:getTitle() end, "")
            local owner = safe(function() return h:getOwner() end, "")
            local on = st.house == h
            pick(L, "h:" .. i, (title ~= "" and title) or owner, tr("UI_ZeD_Adm_OwnedBy", owner), on)
            L[#L].house = h
            if on then btns(L, { B("safehouse", tr("UI_ZeD_Adm_Open"), tr("UI_ZeD_Adm_HelpOpenSafehouse")) }) end
        end
    end
    -- FACTIONS
    if cap(p, "FactionCheat") then
        local list = safe(function() return Faction.getFactions() end, nil)
        local n = list and safe(function() return list:size() end, 0) or 0
        head(L, getText("IGUI_AdminPanel_SeeFaction"), n)
        if n == 0 then line(L, tr("UI_ZeD_Adm_NoFactions")) end
        for i = 0, n - 1 do
            local f = list:get(i)
            local on = st.faction == f
            pick(L, "f:" .. i, safe(function() return f:getName() end, ""), tr("UI_ZeD_Adm_OwnedBy", safe(function() return f:getOwner() end, "")), on)
            L[#L].faction = f
            if on then btns(L, { B("faction", tr("UI_ZeD_Adm_Open"), tr("UI_ZeD_Adm_HelpOpenFaction")) }) end
        end
    end
    -- MORE TOOLS: the game's own windows
    local more = {}
    for _, m in ipairs(MORE) do
        if allowed(p, m.cap) then more[#more + 1] = B("more:" .. m.id, getText(m.key), tr("UI_ZeD_Adm_HelpMore")) end
    end
    if #more > 0 then
        head(L, tr("UI_ZeD_Adm_MoreTools"))
        btns(L, more)
    end
    return L
end

-- each item's place; a row of buttons wraps to the next line when the width runs out
local function measure(L, w)
    local T = ZeD.T
    local M = ZeD.Molecules
    local f2h = ZeD.TM:getFontHeight(T.fontF2)
    local inner = w - 2 * px(PAD)
    local y = 0
    for i, it in ipairs(L) do
        if it.k == "head" then
            if i > 1 then y = y + px(SEC_GAP) end
            it.h = px(20)
        elseif it.k == "pick" then
            it.h = f2h + px(ROW_GAP) * 2
        elseif it.k == "line" then
            it.h = f2h + px(ROW_GAP)
        elseif it.k == "text" then
            it.lines = ZeD.Atoms.wrapText(it.text, T.fontF2, inner - px(PAD))
            it.h = math.max(1, #it.lines) * f2h + px(ROW_GAP)
        elseif it.k == "check" then
            it.h = math.max(f2h, T.checkboxSz or px(12)) + px(ROW_GAP) * 2
        elseif it.k == "btns" then
            y = y + px(BTN_GAP)
            local bx, by = 0, 0
            for _, b in ipairs(it.list) do
                b.w = math.min(inner, M.buttonW(b.text))
                if bx > 0 and bx + b.w > inner then bx = 0; by = by + T.buttonH + px(BTN_GAP) end
                b.dx, b.dy = bx, by
                bx = bx + b.w + px(BTN_GAP)
            end
            it.h = by + T.buttonH + px(BTN_GAP)
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
local function help(win, text) if text and ZeD.Help and ZeD.Help.set then ZeD.Help.set(win, text) end end

local function drawPick(panel, win, st, it, x, dy, cw, mx, my)
    local T = ZeD.T
    local pad = px(PAD)
    local rx, rw = x + pad, cw - 2 * pad
    local hov = mx ~= nil and mx >= rx and mx < rx + rw and my >= dy and my < dy + it.h
    if it.on then local a = T.accent; panel:drawRect(rx, dy, rw, it.h, 0.25, a.r, a.g, a.b)
    elseif hov then local hv = T.hover; panel:drawRect(rx, dy, rw, it.h, hv.a or 0.1, hv.r, hv.g, hv.b) end
    local f = focusOf(win, "adm:" .. it.id)
    if f and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(panel, rx, dy, rw, it.h, f) end
    local tc = T.text
    local ty = dy + px(ROW_GAP)
    panel:drawText(it.text, rx + px(4), ty, tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    if it.sub then
        local td = T.textDim
        local sw = ZeD.TM:MeasureStringX(T.fontF2, it.sub)
        panel:drawText(it.sub, rx + rw - sw - px(4), ty, td.r, td.g, td.b, td.a or 1, T.fontF2)
    end
    st.hits[#st.hits + 1] = { x = rx, y = dy, w = rw, h = it.h, item = it }
end

local function drawCheck(panel, win, st, it, x, dy, cw, mx, my)
    local T = ZeD.T
    local pad = px(PAD)
    local rx, rw = x + pad, cw - 2 * pad
    local hov = mx ~= nil and mx >= rx and mx < rx + rw and my >= dy and my < dy + it.h
    local sz = T.checkboxSz or px(12)
    ZeD.Atoms.drawCheckbox(panel, rx, dy + math.floor((it.h - sz) / 2), it.on, hov, false)
    local f = focusOf(win, "adm:c:" .. it.id)
    if f and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(panel, rx, dy, rw, it.h, f) end
    local tc = T.text
    panel:drawText(it.text, rx + sz + px(6), dy + math.floor((it.h - ZeD.TM:getFontHeight(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    if hov or f then help(win, it.help) end
    st.hits[#st.hits + 1] = { x = rx, y = dy, w = rw, h = it.h, item = it }
end

local function drawItem(panel, win, st, it, x, dy, cw, mx, my)
    local T = ZeD.T
    local M = ZeD.Molecules
    local pad = px(PAD)
    if it.k == "head" then
        M.drawSectionHeader(panel, x + pad, dy, cw - pad, it.text, it.count, true, false, nil, nil, pad, nil, true)
    elseif it.k == "line" then
        M.drawEmptyLine(panel, x + pad, dy, cw - 2 * pad, it.text)
    elseif it.k == "text" then
        local c = it.dim and T.textDim or T.text
        local fh = ZeD.TM:getFontHeight(T.fontF2)
        for i, s in ipairs(it.lines or {}) do
            panel:drawText(s, x + 2 * pad, dy + (i - 1) * fh, c.r, c.g, c.b, c.a or 1, T.fontF2)
        end
    elseif it.k == "pick" then
        drawPick(panel, win, st, it, x, dy, cw, mx, my)
    elseif it.k == "check" then
        drawCheck(panel, win, st, it, x, dy, cw, mx, my)
    elseif it.k == "btns" then
        for _, b in ipairs(it.list) do
            local bx, by = x + pad + b.dx, dy + b.dy
            local hov = mx ~= nil and mx >= bx and mx < bx + b.w and my >= by and my < by + T.buttonH
            M.drawButton(panel, bx, by, b.w, T.buttonH, b.text, b.danger and "danger" or "default", hov and isMouseButtonDown(0), nil,
                { hover = hov, disabled = b.disabled, help = b.help, win = win, focus = focusOf(win, "adm:b:" .. b.id), default = b.id == "askyes" })
            st.hits[#st.hits + 1] = { x = bx, y = by, w = b.w, h = T.buttonH, btn = b }
        end
    end
end

-- the controller's focus kept in view; returns the offset
local function follow(win, scroll, maxOff, sh)
    local Fo = ZeD.Input and ZeD.Input.Focus
    local fe = Fo and Fo.getFocusedWindow and Fo.getFocusedWindow() == win and Fo.getFocusedElement and Fo.getFocusedElement(win)
    if fe and fe.adm and fe.cy and maxOff > 0 then
        local off0 = math.floor(scroll.scrollPos * maxOff)
        local off1 = off0
        if fe.cy < off0 then off1 = fe.cy elseif fe.cy + (fe.h or 0) > off0 + sh then off1 = fe.cy + (fe.h or 0) - sh end
        if off1 ~= off0 then scroll:setScrollPos(math.max(0, math.min(1, off1 / maxOff))) end
    end
end

function A.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local M = ZeD.Molecules
    local st = state(win)
    local p = win._playerObj or getPlayer()
    if not p then return end
    -- (the players come from the game's scoreboard, as the Server tab asks it: asked here too while this tab shows)
    local S = ZeD.ServerTab
    if S and getTimestampMs() - (S.askedAt or 0) > 5000 then
        S.askedAt = getTimestampMs()
        if scoreboardUpdate then pcall(scoreboardUpdate) end
    end
    local L = build(p, st)
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
        follow(win, scroll, maxOff, sh)
    else
        scroll:setScrollPos(0)
    end
    local off = needs and math.floor(scroll.scrollPos * maxOff) or 0
    st.off, st.sy, st.x = off, sy, x
    local Fo = ZeD.Input and ZeD.Input.Focus
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    local cw = w - (needs and T.sp.scrollbarW or 0)
    st.hits = {}
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(L) do
        local dy = sy + it.y - off
        if dy + it.h >= sy and dy <= sy + sh then drawItem(panel, win, st, it, x, dy, cw, mx, my) end
    end
    panel:clearStencilRect()
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    M.drawTabHeader(panel, x, y, w, tr("UI_ZeD_World_TabAdmin"), false, false, true)
    if needs then scroll:draw(panel) end
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end

local function choose(st, it)
    if it.pl then
        if st.sel and st.sel.user == it.pl.user then st.sel = nil else st.sel = it.pl end
        st.ask, st.note = nil, nil
    elseif it.ticket then
        st.ticket = (st.ticket and st.ticket.id == it.ticket.id) and nil or it.ticket
    elseif it.house then
        st.house = (st.house == it.house) and nil or it.house
    elseif it.faction then
        st.faction = (st.faction == it.faction) and nil or it.faction
    end
    sound("UISelectListItem")
end

-- a tick on an admin power: the game's own setter, then the server told (as the game's Save does)
local function toggle(p, it)
    local o = it.opt
    if not (o and p) then return end
    o.player = p
    local ok, err = pcall(function()
        o:setValue(not it.on)
        sendPlayerExtraInfo(p)
    end)
    if not ok then ZeD.logOnce("admin power " .. tostring(it.id), err) end
    sound()
end

local function press(win, st, b)
    if b.disabled then return end
    local p = win._playerObj or getPlayer()
    if not p then return end
    sound()
    local id = b.id
    local ok, err = true, nil
    if id:sub(1, 5) == "more:" then
        local want = id:sub(6)
        for _, m in ipairs(MORE) do if m.id == want then ok, err = pcall(m.run, p) end end
    elseif DO[id] then
        ok, err = pcall(DO[id], p, st)
    end
    if not ok then ZeD.logOnce("admin tab " .. id, err) end
end

function A.onClick(win, x, y)
    local st = state(win)
    local sc = st.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return
    end
    for _, hz in ipairs(st.hits or {}) do
        if x >= hz.x and x < hz.x + hz.w and y >= hz.y and y < hz.y + hz.h then
            if hz.btn then press(win, st, hz.btn)
            elseif hz.item.k == "check" then toggle(win._playerObj or getPlayer(), hz.item)
            else choose(st, hz.item) end
            return
        end
    end
end

-- the controller's stops: each row to pick, each tick box and each button, in reading order
function A.buildFocusables(win)
    local st = win._adminTab
    if not st then return {} end
    local out = {}
    local sy, off, x0 = st.sy or 0, st.off or 0, (st.x or 0) + px(PAD)
    for _, it in ipairs(st.items or {}) do
        local dy = sy + it.y - off
        if it.k == "pick" then
            local item = it
            out[#out + 1] = { x = x0, y = dy, w = px(200), h = it.h, cy = it.y, id = "adm:" .. it.id, adm = true,
                onFocus = function() end, onActivate = function() choose(st, item) end }
        elseif it.k == "check" then
            local item = it
            out[#out + 1] = { x = x0, y = dy, w = px(200), h = it.h, cy = it.y, id = "adm:c:" .. it.id, adm = true, help = it.help,
                onFocus = function() end, onActivate = function(w) toggle(w._playerObj or getPlayer(), item) end }
        elseif it.k == "btns" then
            for _, b in ipairs(it.list) do
                local bb = b
                out[#out + 1] = { x = x0 + b.dx, y = dy + b.dy, w = b.w, h = ZeD.T.buttonH, cy = it.y + b.dy, id = "adm:b:" .. b.id, adm = true,
                    help = b.help, onFocus = function() end, onActivate = function(w) press(w, st, bb) end }
            end
        end
    end
    return out
end

-- the controller's stops are rebuilt when the list's shape or its scroll changes
function A.scrollKey(win)
    local st = win._adminTab
    if not st then return nil end
    local parts = { tostring(st.off or 0) }
    for _, it in ipairs(st.items or {}) do
        if it.k == "btns" then parts[#parts + 1] = "b" .. #it.list
        elseif it.k == "pick" or it.k == "check" then parts[#parts + 1] = it.k:sub(1, 1) end
    end
    return table.concat(parts, ",")
end

-- ---------------------------------------------------------------------------
-- THE TAB: admins on a server only
-- ---------------------------------------------------------------------------
require "ZeD/ZeD_TabPx"
if ZeD.TabPx and ZeD.TabPx.ICONS then ZeD.TabPx.ICONS[TAB_ID] = true end

ZeD_WorldWindow.addTab({
    id = TAB_ID, after = "vehicle", group = 2, glyph = "D",
    iconName = "admin-tab-white",
    label = function() return tr("UI_ZeD_World_TabAdmin") end,
    visible = function() return A.visible() end,
    wheelHide = function() return not A.visible() end,   -- (on the D-pad wheels only for an admin on a server)
    render = A.render,
    scroll = function(win) local st = win._adminTab; return st and st.scroll or nil end,
    onClick = A.onClick,
    buildFocusables = A.buildFocusables,
    scrollKey = A.scrollKey,
})

return A
