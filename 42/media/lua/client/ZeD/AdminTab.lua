-- ZeD-UI/42/media/lua/client/ZeD/AdminTab.lua
-- ============================================================================
-- THE ADMIN TAB (ZeDUI/MP_ADMIN_SCOPE.md, Phase 2; the drawing is mockups/zed_admin_tools_v1.html)
-- In the World window, for admins only (the game's own test: the role has an admin tool), on a server only. One list:
--   TICKETS        the summary, as drawn; its row opens the queue (ZeD_TicketCards.lua: filters, Find, rows, pages) on a
--                  screen of its own behind st.screen, and a ticket card on top of that behind st.card
--   PLAYERS        the one list, online and offline, with role, last seen, warning points and Find; a row opens the
--                  Player card
--   ADMIN POWERS   your own powers, the game's list (ISAdminPowerUI.OptionList), with a line on what each does
--   SERVER MESSAGE typed in place, Repeat every 15, 30, 60, 120 min, and the Stop list
--   ROLES, BANS, SPAWN ITEMS, SERVER EXTRAS   a row each, opening their cards (Server extras: ZeD_ExtrasCards.lua)
--   SAFEHOUSES     every safehouse and FACTIONS every faction. The Server tab's cards (ZeD_ClaimCards.lua) hold only your
--                  own, so staff see everyone else's here: pick one to open it in the game's own window. Your own opens its
--                  card
--   MORE TOOLS     the game's remaining windows
-- The list's parts above Safehouses and every card are in ZeD_AdminCards.lua. A control this role cannot use stays on
-- the list, gray, and the help band says the capability it needs and the role that has it.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Tr"
require "ZeD/ServerTab"
require "ZeD/ZeD_WorldWindow"
require "ZeD/ZeD_TicketCards"
require "ZeD/ZeD_Admin"
require "ZeD/ZeD_AdminCards"
require "ZeD/ZeD_ExtrasCards"

ZeD = ZeD or {}
local A = {}
ZeD.AdminTab = A

local TAB_ID = "admin"
local PAD, ROW_GAP, BTN_GAP, SEC_GAP = 10, 4, 6, 8   -- design units

local function tr(k, ...) return ZeD.tr(k, ...) end
local function safe(fn, d) local ok, v = pcall(fn); if ok and v ~= nil then return v end; return d end
local function px(n) return ZeD.T.px(n) end
local function cap(p, name) return safe(function() return p:getRole():hasCapability(Capability[name]) end, false) end

function A.visible()
    if not isClient() then return false end
    local p = getPlayer()
    return p ~= nil and safe(function() return p:getRole():hasAdminTool() end, false)
end

-- ---------------------------------------------------------------------------
-- WHAT THE BUTTONS DO
-- ---------------------------------------------------------------------------
local function openUI(ui) ui:initialise(); ui:addToUIManager(); if ui.setVisible then ui:setVisible(true) end end
local function closeOld(cls, how) if cls and cls.instance then pcall(function() cls.instance[how or "close"](cls.instance) end) end end

-- your own safehouse or faction: its card in the Server tab. False if the tab cannot open
local function ownCard(p, kind)
    if not (ZeD_CharacterWindow and ZeD_CharacterWindow.openTab) then return false end
    if not ZeD_CharacterWindow.openTab(p:getPlayerNum(), "server") then return false end
    ZeD.Claims.openNext = kind
    return true
end
local function isOwnHouse(h) local C = ZeD.Claims; return C ~= nil and C.safe ~= nil and C.safe.obj == h end
local function isOwnFaction(f) local C = ZeD.Claims; return C ~= nil and C.fac ~= nil and C.fac.obj == f end

local DO = {}
function DO.safehouse(p, st)
    local h = st.house
    if not h then return end
    if isOwnHouse(h) and ownCard(p, "safe") then return end
    closeOld(ISSafehouseUI)
    local width = 500 + getCore():getOptionFontSizeReal() * 30
    openUI(ISSafehouseUI:new((getCore():getScreenWidth() - width) / 2, getCore():getScreenHeight() / 2 - 225, width, 450, h, p))
end
function DO.faction(p, st)
    local f = st.faction
    if not f then return end
    if isOwnFaction(f) and ownCard(p, "faction") then return end
    closeOld(ISFactionUI)
    openUI(ISFactionUI:new(getCore():getScreenWidth() / 2 - 250, getCore():getScreenHeight() / 2 - 225, 500, 450, f, p))
end
-- the game's remaining windows, opened as its ISAdminPanelUI:onOptionMouseDown opens them
local MORE = {
    { id = "options", cap = "SeePublicServerOptions", key = "IGUI_AdminPanel_SeeServerOptions",
      run = function(p) closeOld(ISServerOptions); openUI(ISServerOptions:new(50, 50, 900, 800, p)) end },
    { id = "sandbox", cap = "SandboxOptions",      key = "IGUI_AdminPanel_SandboxOptions",
      run = function(p) closeOld(ISServerSandboxOptionsUI); openUI(ISServerSandboxOptionsUI:new(150, 150, 800, 600)) end },
    { id = "pvplog",  cap = "PVPLogTool",          key = "IGUI_AdminPanel_PVPLogTool",
      run = function(p) closeOld(ISPVPLogToolUI); openUI(ISPVPLogToolUI:new(50, 50, 500, 700)) end },
    { id = "zones",   cap = "CanSetupSafehouses", capAlt = "CanSetupNonPVPZone", key = "IGUI_AdminPanel_ZoneEditor",
      run = function(p) ISMultiplayerZoneEditor.ToggleEditor() end },
    { id = "nonpvp",  cap = "CanSetupNonPVPZone",  key = "IGUI_AdminPanel_NonPvpZone",
      run = function(p) closeOld(ISPvpZonePanel); openUI(ISPvpZonePanel:new(50, 50, 600, 600, p)) end },
    { id = "safezone", cap = "CanSetupSafehouses", key = "IGUI_AdminPanel_Safezone",
      run = function(p) closeOld(ISAddSafeZoneUI); openUI(ISAddSafeZoneUI:new(getCore():getScreenWidth() / 2 - 210, getCore():getScreenHeight() / 2 - 200, 300 + getCore():getOptionFontSizeReal() * 50, 400, p)) end },
    { id = "statistics", cap = "GetStatistic",     key = "IGUI_AdminPanel_ShowStatistics",
      run = function(p) closeOld(ISStatisticsUI); openUI(ISStatisticsUI:new(50, 50, p)) end },
    -- accounts, passwords and the whitelist, and the game's lists of banned IPs and Steam IDs, until cards hold them
    { id = "users",   cap = "SeeNetworkUsers",     key = "IGUI_AdminPanel_SeeUsers",
      run = function(p) requestUsers(); closeOld(ISUsersList, "closeModal"); openUI(ISUsersList:new(50, 50, 800 + getCore():getOptionFontSizeReal() * 50, 600, p)) end },
    { id = "mystats", cap = "CanSeePlayersStats",  key = "IGUI_AdminPanel_CheckYourStats",
      run = function(p) closeOld(ISPlayerStatsUI); openUI(ISPlayerStatsUI:new(50, 50, 800 + getCore():getOptionFontSizeReal() * 50, 800, p, p)) end },
    { id = "climate", cap = "ClimateManager",      key = "IGUI_Adm_Weather_ClimateControl",
      run = function(p) local ui = ISAdminWeather.OnOpenPanel(); if ui and ui.onMadeActive then ui:onMadeActive() end end },
}
A.MORE = MORE

-- ---------------------------------------------------------------------------
-- LAYOUT
-- ---------------------------------------------------------------------------
local function state(win)
    local st = win._adminTab
    if not st then st = { scroll = ZeD_ScrollbarState:new(), items = {}, hits = {}, barRects = {} }; win._adminTab = st end
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

local function build(p, st, win)
    local L = {}
    ZeD.AdminCards.homeItems(L, win, st, p)
    -- SAFEHOUSES: every one. The Server tab's cards hold only your own
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
            if on then btns(L, { B("safehouse", tr("UI_ZeD_Adm_Open"), tr(isOwnHouse(h) and "UI_ZeD_Adm_HelpOpenOwn" or "UI_ZeD_Adm_HelpOpenSafehouse")) }) end
        end
    end
    -- FACTIONS: every one, the same
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
            if on then btns(L, { B("faction", tr("UI_ZeD_Adm_Open"), tr(isOwnFaction(f) and "UI_ZeD_Adm_HelpOpenOwn" or "UI_ZeD_Adm_HelpOpenFaction")) }) end
        end
    end
    -- MORE TOOLS: the game's own windows
    local M = ZeD.Admin
    local more = {}
    for _, m in ipairs(MORE) do
        local ok = M.can(m.cap) or (m.capAlt ~= nil and M.can(m.capAlt))
        more[#more + 1] = B("more:" .. m.id, getText(m.key), ok and tr("UI_ZeD_Adm_HelpMore") or M.why(m.cap), not ok)
    end
    add(L, { k = "head", text = tr("UI_ZeD_Adm_MoreTools"), right = tr("UI_ZeD_Adm_MoreLine") })
    btns(L, more)
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
        elseif it.k == "tk" then
            it.h = ZeD.TicketCards.itemH(it, inner)
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

local function drawItem(panel, win, st, it, x, dy, cw, mx, my)
    local T = ZeD.T
    local M = ZeD.Molecules
    local pad = px(PAD)
    if it.k == "head" then
        M.drawSectionHeader(panel, x + pad, dy, cw - pad, it.text, it.count, true, false, nil, nil, pad, nil, true)
        if it.right then
            ZeD.Atoms.drawTextRight(panel, it.right, x + cw - pad, dy + math.floor((it.h - ZeD.TM:getFontHeight(T.fontF1)) / 2), T.fontF1, T.textDim)
        end
    elseif it.k == "tk" then
        ZeD.TicketCards.drawItem(panel, win, st, it, x, dy, cw, mx, my)
    elseif it.k == "line" then
        M.drawEmptyLine(panel, x + pad, dy, cw - 2 * pad, it.text)
    elseif it.k == "pick" then
        drawPick(panel, win, st, it, x, dy, cw, mx, my)
    elseif it.k == "btns" then
        for _, b in ipairs(it.list) do
            local bx, by = x + pad + b.dx, dy + b.dy
            local hov = mx ~= nil and mx >= bx and mx < bx + b.w and my >= by and my < by + T.buttonH
            M.drawButton(panel, bx, by, b.w, T.buttonH, b.text, b.danger and "danger" or "default", hov and isMouseButtonDown(0), nil,
                { hover = hov, disabled = b.disabled, help = b.help, win = win, focus = focusOf(win, "adm:b:" .. b.id) })
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

local function backToTab(win, st)
    st.screen = nil
    st.homeKey = nil
    ZeD.TicketCards._D.focusId(win, st, "adm:tk:sum:tickets")
end

function A.render(panel, win, x, y, w, h)
    local T = ZeD.T
    local M = ZeD.Molecules
    local st = state(win)
    local p = win._playerObj or getPlayer()
    if not p then return end
    local TC = ZeD.TicketCards
    TC.bind(win, st, "adm:tk:", "worldTabContent")
    ZeD.AdminCards.frame(win, st)
    if st.card then
        TC.renderCard(panel, win, st, x, y, w, h)
        return
    end
    ZeD.Admin.watch()
    local onQueue = st.screen == "tickets"
    local L = {}
    if onQueue then
        TC.queueItems(L, win, st)
    else
        if ZeD.Admin.can("AnswerTickets") then TC.queueWatch(st) end
        L = build(p, st, win)
    end
    st.items = L
    local headH
    if onQueue then
        headH = M.drawCardBackBar(panel, x, y, w, getText("UI_userpanel_tickets"), nil, false, false, st.barRects,
            { win = win, focusParts = { back = focusOf(win, "adm:back") }, backHelp = tr("UI_ZeD_Tk_BackQueue") })
    else
        headH = M.getTabHeaderH()
    end
    -- with the controller the help band holds the prompts: a grayed stop's reason and a press's answer get a line here
    local words = (not onQueue) and TC.padWords(win, st) or nil   -- (the queue says these in its own list)
    local lineH, lineWords = TC._D.footLine({}, w, words, 0)
    local sy, sh = y + headH, h - headH - lineH
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
    st.off, st.sy, st.x, st.w = off, sy, x, w
    local Fo = ZeD.Input and ZeD.Input.Focus
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if not (mx >= x and mx < x + w and my >= sy and my < sy + sh) or (Fo and Fo.cuesVisible and Fo.cuesVisible()) then mx, my = nil, nil end
    local cw = w - (needs and T.sp.scrollbarW or 0)
    st.hits = {}
    TC.beginList(win, st, sy, sh, onQueue and TC.queueHelp(st) or ZeD.AdminCards.homeHelp())
    panel:setStencilRect(x, sy, w, sh)
    for _, it in ipairs(L) do
        local dy = sy + it.y - off
        if dy + it.h >= sy and dy <= sy + sh then drawItem(panel, win, st, it, x, dy, cw, mx, my) end
    end
    panel:clearStencilRect()
    panel:setStencilRect(0, 0, panel:getWidth(), panel:getHeight())
    if not onQueue then
        M.drawTabHeader(panel, x, y, w, TC.tabLabel(tr("UI_ZeD_World_TabAdmin")), false, false, true)
        ZeD.AdminCards.drawYou(panel, x, y, w, headH)
    end
    if needs then scroll:draw(panel) end
    if lineH > 0 then TC._D.drawFootLine(panel, x, y + h - lineH, w, lineH, lineWords) end
    TC.endList(panel, win, st, sy, sy + sh)
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------
local function sound(n) pcall(function() getSoundManager():playUISound(n or "UIActivateButton") end) end

local function choose(st, it)
    if it.house then
        st.house = (st.house == it.house) and nil or it.house
    elseif it.faction then
        st.faction = (st.faction == it.faction) and nil or it.faction
    end
    sound("UISelectListItem")
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
    local TC = ZeD.TicketCards
    if st.card then
        TC.cardClick(win, st, x, y)
        return
    end
    local r = st.barRects and st.barRects.back
    if st.screen == "tickets" and r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then
        sound()
        backToTab(win, st)
        return
    end
    local sc = st.scroll
    if sc.visible and x >= sc.x and x < sc.x + sc.width and y >= sc.y and y < sc.y + sc.height then
        sc:handleMouseDown(y - sc.y)
        return
    end
    if TC.listClick(win, st, x, y) then return end
    for _, hz in ipairs(st.hits or {}) do
        if x >= hz.x and x < hz.x + hz.w and y >= hz.y and y < hz.y + hz.h then
            if hz.btn then press(win, st, hz.btn)
            else choose(st, hz.item) end
            return
        end
    end
end

-- the controller's stops: each row to pick, each tick box and each button, in reading order
function A.buildFocusables(win)
    local st = win._adminTab
    if not st then return {} end
    local TC = ZeD.TicketCards
    if st.card then return TC.cardStops(win, st) end
    local out = {}
    if TC.popupStops(st, out) then return out end
    local sy, off, x0 = st.sy or 0, st.off or 0, (st.x or 0) + px(PAD)
    local onQueue = st.screen == "tickets"
    local r = st.barRects and st.barRects.back
    if onQueue and r then
        out[#out + 1] = { x = r.x, y = math.min(r.y, sy - off - r.h), w = r.w, h = r.h, id = "adm:back", promptA = tr("UI_ZeD_Tk_PromptBack"),
            onFocus = function() end, onActivate = function(w) backToTab(w, st) end }
    end
    for _, it in ipairs(st.items or {}) do
        local dy = sy + it.y - off
        if it.k == "tk" then
            TC.itemStops(out, st, it, x0, dy, st.w or 0, "adm")
        elseif it.k == "pick" then
            local item = it
            out[#out + 1] = { x = x0, y = dy, w = px(200), h = it.h, cy = it.y, id = "adm:" .. it.id, adm = true,
                onFocus = function() end, onActivate = function() choose(st, item) end }
        elseif it.k == "btns" then
            for _, b in ipairs(it.list) do
                local bb = b
                out[#out + 1] = { x = x0 + b.dx, y = dy + b.dy, w = b.w, h = ZeD.T.buttonH, cy = it.y + b.dy, id = "adm:b:" .. b.id, adm = true,
                    help = b.help, tkWhy = function() return bb.disabled and bb.help or nil end,
                    onFocus = function() end, onActivate = function(w) press(w, st, bb) end }
            end
        end
    end
    if onQueue then
        for _, e in ipairs(out) do
            e.onCancel = function(w) backToTab(w, st) end
            e.promptB = tr("UI_ZeD_Tk_PromptBack")
        end
    end
    return out
end

-- the controller's stops are rebuilt when the list's shape or its scroll changes
function A.scrollKey(win)
    local st = win._adminTab
    if not st then return nil end
    if st.card then return ZeD.TicketCards.cardKey(st) end
    local parts = { tostring(st.off or 0), ZeD.TicketCards.listKey(st), tostring(st.screen) }
    for _, it in ipairs(st.items or {}) do
        if it.k == "btns" then parts[#parts + 1] = "b" .. #it.list
        elseif it.k == "pick" then parts[#parts + 1] = "p" end
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
    label = function() return ZeD.TicketCards.tabLabel(tr("UI_ZeD_World_TabAdmin")) end,
    visible = function() return A.visible() end,
    wheelHide = function() return not A.visible() end,   -- (on the D-pad wheels only for an admin on a server)
    render = A.render,
    scroll = function(win)
        local st = win._adminTab
        return st and (ZeD.TicketCards.activeScroll(st) or st.scroll) or nil
    end,
    onClick = A.onClick,
    buildFocusables = A.buildFocusables,
    scrollKey = A.scrollKey,
})

return A
