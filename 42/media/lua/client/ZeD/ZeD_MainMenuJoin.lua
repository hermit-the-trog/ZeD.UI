-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuJoin.lua
-- ============================================================================
-- JOIN A SERVER + CONNECTING ON THE MONITOR (HOOK_MAP row 26; director, Oct 14
-- 2026: menus delegated, no mockups)
--
-- JOIN: a ZeD window over vanilla's MultiplayerUI, which stays built and
-- hidden as the engine: its saved servers and accounts (accountList), the
-- public list (Steam's or the master list, sorted and filtered by Java), the
-- selected server and its Steam details, the refresh timer. Vanilla's pop-up
-- forms and prompts become parts of the window:
--   left    SAVED / PUBLIC tabs. SAVED: each server, its accounts under it,
--           Add Account..., then Add Server... PUBLIC: Find, the "show" filters,
--           Name / Players / Ping column heads, the servers.
--   right   the chosen server: name, the facts (address, port, players, ping,
--           map, version, password, whitelist, last wipe), its description
--           and mods.
--   forms   adding or editing a server or an account replaces the list (the
--           facts stay beside it); the reason a field will not do shows under
--           it with a red status dot.
--   strip   per row: BACK | ADD SERVER..., EDIT, DELETE, ADD ACCOUNT... |
--           CONNECT; PUBLIC: REFRESH (with vanilla's wait), SAVE / FORGET |
--           CONNECT. Deleting asks in the strip; an account without a saved
--           password, and a locked server, ask for the password in the strip.
--
-- CONNECTING: vanilla's ConnectToServer only follows the connection while it
-- is visible, so it stays shown but off the screen and this window mirrors it
-- (server, account, its status line, the reminder, ABORT / BACK).
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "OptionScreens/MultiplayerUI"
require "OptionScreens/ConnectToServer"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local LIST_SHARE = 0.56
local TABS_H, FIND_H, FILTER_H, COLS_H, ROW_H, SUB_H = 30, 34, 30, 22, 46, 42
local KV_LABEL_W, KV_ROW_H = 96, 20
local NOTE_H = 20

local function ms() return MainScreen and MainScreen.instance end
local function mp() local m = ms(); return m and m.multiplayer end
local function cts() local m = ms(); return m and m.connectToServer end

local function s(v) if v == nil then return "" end; return tostring(v) end
-- does a table hold anything (Kahlua has no next(): KB Q221)
local function any(t) for _ in pairs(t or {}) do return true end; return false end
local function keyOf(server) return server and (s(server:getIp()) .. ":" .. s(server:getPort())) or "" end

-- the vanilla "show" filters, in order (MultiplayerUI fields)
local FILTERS = {
    { "filterVersion", "UI_ZeD_Join_FilterVersion" }, { "filterEmptyServer", "UI_ZeD_Join_FilterEmpty" }, { "filterFullServer", "UI_ZeD_Join_FilterFull" },
    { "filterPwdProtected", "UI_ZeD_Join_Password" }, { "filterWhitelistServer", "UI_ZeD_Join_Whitelist" }, { "filterModdedServer", "UI_ZeD_Join_Modded" },
}   -- (the labels are translation keys: ZeD.tr turns one into the player's language where it draws)

-- ============================================================================
-- JOIN
-- ============================================================================
ZeD_MMJoin = ZeD_MMWindow:derive("ZeD_MMJoin")

function ZeD_MMJoin:new()
    local o = ZeD_MMWindow.new(self, "join")
    o.noResetControl = true
    o.tab = "saved"
    o.scroll = 0
    o.sel = nil           -- the chosen row's key
    o.page = "list"       -- "list" | "server" | "account"
    o.confirm = false     -- false | "delServer" | "delAccount" | "forget" | "pwd" | "srvpwd"
    return o
end

function ZeD_MMJoin:createChildren()
    ZeD_Window.createChildren(self)
    local function entry(masked)
        local e = UI.newEntry(self)
        e:setVisible(false)
        if masked then e:setMasked(true) end
        e.onCommandEntered = function() self._enterAt = MM.now(); e:unfocus() end
        return e
    end
    self.find = entry(false)
    self.find.onTextChange = function() self:findChanged() end
    -- the forms' fields
    self.fName, self.fAddr, self.fPort, self.fSrvPwd = entry(false), entry(false), entry(false), entry(true)
    self.fUser, self.fPwd = entry(false), entry(true)
    -- the strip's password field
    self.field = entry(true)
    self.field.onCommandEntered = function() self._enterAt = MM.now(); self:answerPassword() end
    self.field.onEscape = function() self:setConfirm(false) end
    self._fields = { self.find, self.fName, self.fAddr, self.fPort, self.fSrvPwd, self.fUser, self.fPwd, self.field }
end

function ZeD_MMJoin:onShow()
    local m = mp()
    self.page = "list"
    self.form = nil
    self.confirm = false
    self.scroll = 0
    self.focusId = nil
    if m and m.created then
        pcall(function() m:refreshList() end)
        pcall(function() m:requestServerList() end)
    end
end

function ZeD_MMJoin:findChanged()
    local m = mp()
    if not m or not m.filter then return end
    m.filter:setText(self.find:getText() or "")
    m.listChanged = true
    self.scroll = 0
end

-- ROWS -------------------------------------------------------------------------------
function ZeD_MMJoin:savedRows()
    local m = mp()
    local rows = {}
    if not m or not m.accountList then return rows end
    for _, it in ipairs(m.accountList.items) do
        local d = it.item
        if d.type == "server" then
            rows[#rows + 1] = { kind = "server", key = "s:" .. keyOf(d.server), server = d.server, h = ROW_H }
        elseif d.type == "account" then
            rows[#rows + 1] = { kind = "account", key = "a:" .. keyOf(d.server) .. ":" .. s(d.account:getUserName()), server = d.server, account = d.account, h = SUB_H }
        elseif d.type == "new_account" then
            rows[#rows + 1] = { kind = "newAccount", key = "n:" .. keyOf(d.server), server = d.server, h = SUB_H }
        elseif d.type == "new_server" then
            rows[#rows + 1] = { kind = "newServer", key = "new", h = ROW_H }
        end
    end
    return rows
end

function ZeD_MMJoin:publicRows()
    local m = mp()
    local rows = {}
    if not m or not m.internetList then return rows end
    for _, it in ipairs(m.internetList.items) do
        local sv = it.item
        rows[#rows + 1] = { kind = "public", key = "p:" .. keyOf(sv), server = sv, h = ROW_H }
    end
    return rows
end

function ZeD_MMJoin:selectedRow(rows)
    for _, r in ipairs(rows or self._rows or {}) do if r.key == self.sel then return r end end
    return nil
end

-- choosing a row: vanilla's own selection (its Steam details request), the add rows open their forms
function ZeD_MMJoin:pick(r)
    local m = mp()
    if not r or not m then return end
    local t = MM.now()
    local double = (self.sel == r.key and self._lastClick and t - self._lastClick < 450)
    self._lastClick = t
    if self.sel ~= r.key then MM.hoverSound() end
    self.sel = r.key
    if r.kind == "newServer" then self:openServerForm(nil); return end
    if r.kind == "newAccount" then self:openAccountForm(r.server, nil, false); return end
    if r.server then pcall(function() m:onSelectInternetServer(r.server) end) end
    if double then self:connect() end
end

-- ACTIONS ----------------------------------------------------------------------------
function ZeD_MMJoin:back()
    MM.clickSound()
    if self.page ~= "list" then self:closeForm(); return end
    if getSteamModeActive() then pcall(steamReleaseInternetServersRequest) end
    MM.showView("main")
    MainScreen.resetLuaIfNeeded()
end

function ZeD_MMJoin:setTab(t)
    if self.tab == t then return end
    self.tab = t
    self.scroll = 0
    self.sel = nil
    self.focusId = nil
    MM.clickSound()
end

function ZeD_MMJoin:refresh()
    local m = mp()
    if not m then return end
    MM.clickSound()
    pcall(function() m:requestServerList() end)
end

-- the seconds left before vanilla allows another refresh (0 = now)
function ZeD_MMJoin:refreshWait()
    local wait = getDebug() and 5 or 60
    local since = getTimestamp() - (MultiplayerUI.startRefreshTime or 0)
    return math.max(0, wait - since)
end

-- connecting: a saved account, or a public server (its password first, then an account)
function ZeD_MMJoin:connect()
    local m = mp()
    if not m then return end
    local r = self:selectedRow()
    if not r then return end
    if r.kind == "account" then self:connectAccount(r.server, r.account); return end
    if r.kind == "server" then
        local accs = r.server:getAccounts()
        if accs:size() == 1 then self:connectAccount(r.server, accs:get(0)) end
        return
    end
    if r.kind == "public" then
        if self:needsServerPassword(r.server) then self:askServerPassword(r.server, "connect"); return end
        self:connectPublic(r.server)
    end
end

function ZeD_MMJoin:connectPublic(server)
    local m = mp()
    local fav = m:getServerFeatured(server)
    if fav then
        -- a saved server: its accounts are under it on SAVED
        local accs = fav.server:getAccounts()
        if accs:size() == 1 then self:connectAccount(fav.server, accs:get(0)); return end
        self.tab = "saved"
        self.scroll = 0
        self.sel = "s:" .. keyOf(fav.server)
        MM.clickSound()
        return
    end
    -- a new account for it, connecting when saved (vanilla does not keep it)
    self:openAccountForm(server, nil, true)
end

-- vanilla's MultiplayerUI:connectToServer, with its password prompt in the strip
function ZeD_MMJoin:connectAccount(server, account)
    local m = mp()
    if not m or not server or not account then return end
    MM.clickSound()
    getCore():setAccountUsed(account)
    if not account:isSavePwd() then
        self._pwdFor = { server = server, account = account }
        self:setConfirm("pwd")
        return
    end
    m:connectToServer(server, account)
end

-- vanilla's ISMPEnterPassword:onClick CONNECT, with the typed password
function ZeD_MMJoin:connectWithPassword(server, account, password)
    local m = mp()
    account:setLastLogonNow()
    updateAccountToAccountList(account)
    if getSteamModeActive() then pcall(steamReleaseInternetServersRequest) end
    stopSendSecretKey()
    getCore():setNoSave(false)
    local localIP = getSteamModeActive() and server:getLocalIP() or ""
    local useSteamRelay = getSteamModeActive() and account:getUseSteamRelay()
    ConnectToServer.instance.loadingBackground = server:getServerLoadingScreen()
    ConnectToServer.instance:connect(m, server:getName(), account:getUserName(), password,
        server:getIp(), localIP, tostring(server:getPort()), server:getServerPassword(), useSteamRelay, true, account:getAuthType())
end

-- vanilla's checkServerIsPwdProtected, as a question
function ZeD_MMJoin:needsServerPassword(server)
    local m = mp()
    if not server or not server:isPasswordProtected() then return false end
    local pwd = server:getServerPassword()
    if pwd and pwd ~= "" then return false end
    local fav = m and m:getServerFeatured(server)
    if fav and fav.server:getServerPassword() and fav.server:getServerPassword() ~= "" then return false end
    return true
end

function ZeD_MMJoin:askServerPassword(server, after)
    self._srvPwdFor = { server = server, after = after }
    self:setConfirm("srvpwd")
end

function ZeD_MMJoin:answerPassword()
    local text = self.field:getText() or ""
    if self.confirm == "pwd" then
        local p = self._pwdFor
        self:setConfirm(false)
        if p and text ~= "" then self:connectWithPassword(p.server, p.account, text) end
    elseif self.confirm == "srvpwd" then
        local p = self._srvPwdFor
        self:setConfirm(false)
        if p and text ~= "" then
            p.server:setServerPassword(text)
            if p.after == "save" then self:saveServer(p.server) else self:connectPublic(p.server) end
        end
    end
end

-- SAVED from PUBLIC: vanilla's FAVOURITES button
function ZeD_MMJoin:saveServer(server)
    local m = mp()
    if not m or not server then return end
    if self:needsServerPassword(server) then self:askServerPassword(server, "save"); return end
    addServerToAccountList(server)
    m:refreshList()
    self.tab = "saved"
    self.scroll = 0
    self.sel = "s:" .. keyOf(server)
    MM.clickSound()
end

function ZeD_MMJoin:forgetServer(server)
    local m = mp()
    self:setConfirm(false)
    if not m or not server then return end
    local fav = m:getServerFeatured(server)
    deleteServerToAccountList(fav and fav.server or server)
    m:refreshList()
    self.sel = nil
end

function ZeD_MMJoin:deleteAccount(account)
    local m = mp()
    self:setConfirm(false)
    if not m or not account then return end
    deleteAccountToAccountList(account)
    m:refreshList()
    self.sel = nil
end

function ZeD_MMJoin:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.ctx.open = nil
    if mode == "pwd" or mode == "srvpwd" then
        self.field:setText("")
        self.field:setVisible(true)
        self.field:focus()
    else
        self.field:setVisible(false)
        if self.field:isFocused() then self.field:unfocus() end
    end
    self.focusId = mode and "confirm:yes" or self.focusId
end

-- FORMS ------------------------------------------------------------------------------
function ZeD_MMJoin:openServerForm(server)
    MM.clickSound()
    self.page = "server"
    self.form = { server = server }
    self.fName:setText(server and s(server:getName()) or "")
    self.fAddr:setText(server and s(server:getIp()) or "")
    self.fPort:setText(server and s(server:getPort()) or "16261")
    self.fSrvPwd:setText(server and s(server:getServerPassword()) or "")
    self.fName:focus()
    self.focusId = nil
end

function ZeD_MMJoin:openAccountForm(server, account, connectAfter)
    MM.clickSound()
    self.page = "account"
    self.form = { server = server, account = account, connectAfter = connectAfter,
                  remember = (account == nil) or account:isSavePwd(),
                  relay = account ~= nil and getSteamModeActive() and account:getUseSteamRelay() or false }
    self.fUser:setText(account and s(account:getUserName()) or "")
    self.fUser:setMaxTextLength(getMaxUsernameLength())
    self.fPwd:setText("")
    self.fUser:focus()
    self.focusId = nil
end

function ZeD_MMJoin:closeForm()
    self.page = "list"
    self.form = nil
    for _, e in ipairs({ self.fName, self.fAddr, self.fPort, self.fSrvPwd, self.fUser, self.fPwd }) do
        if e:isFocused() then e:unfocus() end
        e:setVisible(false)
    end
end

-- what keeps a field from saving, in vanilla's terms
function ZeD_MMJoin:serverProblems()
    local p = {}
    local name, addr, port = self.fName:getText() or "", self.fAddr:getText() or "", self.fPort:getText() or ""
    if name:len() < 1 then p.name = ZeD.tr("UI_ZeD_Join_ErrNoName") elseif detectBadWords(name) then p.name = ZeD.tr("UI_ZeD_Join_ErrBadName") end
    if addr:len() < 7 then p.addr = ZeD.tr("UI_ZeD_Join_ErrShortAddress") elseif detectBadWords(addr) then p.addr = ZeD.tr("UI_ZeD_Join_ErrBadAddress") end
    if port:len() < 1 then p.port = ZeD.tr("UI_ZeD_Join_ErrNoPort") elseif not tonumber(port) then p.port = ZeD.tr("UI_ZeD_Join_ErrPortNumber") end
    return p
end

function ZeD_MMJoin:accountProblems()
    local p = {}
    local f = self.form
    local user = self.fUser:getText() or ""
    if user:len() < getMinUsernameLength() then p.user = getText("UI_servers_accountNameTooShort")
    elseif profanityFilterCheck(user) then p.user = getText("UI_servers_accountNameBadWord", user)
    else
        local accs = f and f.server and f.server:getAccounts()
        if accs then
            for i = 0, accs:size() - 1 do
                local a = accs:get(i)
                if a ~= f.account and a:getUserName() == user then p.user = getText("UI_servers_accountAlreadyExist") end
            end
        end
    end
    if f and not f.account and (self.fPwd:getText() or "") == "" then p.pwd = ZeD.tr("UI_ZeD_Join_ErrNoPassword") end
    return p
end

-- vanilla's ISMPEditServer SAVE
function ZeD_MMJoin:saveServerForm()
    local m = mp()
    if any(self:serverProblems()) or not m then return end
    local sv = self.form.server
    local name, addr = (self.fName:getText() or ""):trim(), (self.fAddr:getText() or ""):trim()
    local port = tonumber((self.fPort:getText() or ""):trim()) or 16262
    local pwd = (self.fSrvPwd:getText() or ""):trim()
    if sv then
        sv:setName(name); sv:setIp(addr); sv:setPort(port); sv:setServerPassword(pwd)
        updateServerToAccountList(sv)
    else
        sv = Server.new()
        sv:setName(name); sv:setIp(addr); sv:setPort(port); sv:setServerPassword(pwd)
        addServerToAccountList(sv)
    end
    m:refreshList()
    MM.clickSound()
    self:closeForm()
    self.tab = "saved"
    self.sel = "s:" .. keyOf(sv)
end

-- vanilla's ISMPEditAccount SAVE (password sign-in, the only kind it offers)
function ZeD_MMJoin:saveAccountForm()
    local m = mp()
    local f = self.form
    if any(self:accountProblems()) or not m or not f then return end
    local user = (self.fUser:getText() or ""):trim()
    local pwd = (self.fPwd:getText() or ""):trim()
    local acc = f.account
    if acc then
        acc:setUserName(user)
        if pwd ~= "" and f.remember then acc:encryptPwd(pwd) end
        if acc:isSavePwd() and not f.remember then acc:setPwd("") end
        acc:setAuthType(1)
        if getSteamModeActive() then acc:setUseSteamRelay(f.relay) end
        acc:setSavePwd(f.remember)
        acc:setLastLogonNow()
        if not f.connectAfter then updateAccountToAccountList(acc) end
    else
        acc = Account.new()
        acc:setUserName(user)
        acc:encryptPwd(pwd)
        acc:setAuthType(1)
        if getSteamModeActive() then acc:setUseSteamRelay(f.relay) end
        acc:setSavePwd(f.remember)
        acc:setLastLogonNow()
        if not f.connectAfter then addAccountToAccountList(f.server, acc) end
    end
    m:refreshList()
    local server, connectAfter = f.server, f.connectAfter
    self:closeForm()
    self.sel = "a:" .. keyOf(server) .. ":" .. user
    if connectAfter then
        if f.remember then m:connectToServer(server, acc) else self:connectWithPassword(server, acc, pwd) end
    else
        MM.clickSound()
    end
end

-- ============================================================================
-- DRAWING
-- ============================================================================
function ZeD_MMJoin:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local m = mp()
    if m and m.created then pcall(function() m:updateListSort() end) end
    self.title = ZeD.tr((self.page == "server") and (self.form and self.form.server and "UI_ZeD_Join_TitleEditServer" or "UI_ZeD_Join_TitleAddServer")
        or ((self.page == "account") and (self.form and self.form.account and "UI_ZeD_Join_TitleEditAccount" or "UI_ZeD_Join_TitleAddAccount") or "UI_ZeD_Join_Title"))
    local nSaved = m and #getServerList() or 0
    self.titleStats = { { text = ZeD.tr(nSaved == 1 and "UI_ZeD_Join_SavedOne" or "UI_ZeD_Join_SavedMany", nSaved), color = { r = 0, g = 0, b = 0, a = 0 } } }
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local lw = math.floor((w - pad * 3) * LIST_SHARE)
    self._shown = {}
    if self.page == "list" then
        self:drawList(pad, bodyY, lw, bodyH)
    else
        self:drawForm(pad, bodyY, lw, bodyH)
    end
    self:drawDetails(pad * 2 + lw, bodyY, w - pad * 3 - lw, bodyH)
    -- fields not placed this frame hide (the strip's field is placed by buildStrip)
    self:buildStrip(stripY, stripH, w)
    for _, e in ipairs(self._fields) do
        if not self._shown[e] and e:isVisible() then
            if e:isFocused() then e:unfocus() end
            e:setVisible(false)
        end
    end
end

function ZeD_MMJoin:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask)
    ZeD_Window.render(self)
end

function ZeD_MMJoin:place(e, x, y, w, h)
    UI.styleEntry(e, x, y, w, h)
    if not e:isVisible() then e:setVisible(true) end
    self._shown[e] = true
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    self._hits[#self._hits + 1] = { id = "join:f:" .. tostring(e.ID or e), x = ax + x, y = ay + y, w = w, h = h, fn = function() e:focus() end }
end

-- a tick with its label; returns its width
function ZeD_MMJoin:tick(id, x, y, label, on, fn)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local cb = T.checkboxSz
    local f2, tc = T.fontF2, T.text
    local hot = MM.ctx.hot == "join:" .. id
    ZeD.Atoms.drawCheckbox(self, x, y, on, hot, false)
    local tw = MM.textW(f2, label)
    self:drawText(label, x + cb + T.px(6), y + math.floor((cb - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    self._hits[#self._hits + 1] = { id = "join:" .. id, x = ax + x - T.px(2), y = ay + y - T.px(4), w = cb + tw + T.px(10), h = cb + T.px(8), fn = fn, sound = true }
    return cb + T.px(6) + tw
end

function ZeD_MMJoin:drawList(x, y, w, h)
    local T = ZeD.T
    local bs, s2 = T.borderS, T.surf2
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local m = mp()
    UI.insetBox(self, x, y, w, h)
    -- the tabs, and streamer mode at the right (vanilla's tick: addresses masked)
    local tH = T.px(TABS_H)
    self:drawRect(x + T.px(1), y + T.px(1), w - T.px(2), tH, 1, s2.r, s2.g, s2.b)
    local tx = x + T.px(8)
    local tY = y + tH - T.tabH
    for _, t in ipairs({ { "saved", ZeD.tr("UI_ZeD_Join_TabSaved") }, { "public", ZeD.tr("UI_ZeD_Join_TabPublic") } }) do
        local hid = "join:tab:" .. t[1]
        local tw = ZeD.Molecules.drawTab(self, tx, tY, t[2], self.tab == t[1], MM.ctx.hot == hid, false)
        self._hits[#self._hits + 1] = { id = hid, x = ax + tx, y = ay + tY, w = tw, h = T.tabH, fn = function() self:setTab(t[1]) end }
        tx = tx + tw + T.sp.tabGap
    end
    if m and m.showIPAddressesTickBox then
        local on = m.showIPAddressesTickBox:isSelected(1)
        local label = getText("UI_servers_streamerMode")
        local tw = T.checkboxSz + T.px(6) + MM.textW(T.fontF2, label)
        self:tick("streamer", x + w - T.px(10) - tw, y + math.floor((tH - T.checkboxSz) / 2), label, on, function()
            m.showIPAddressesTickBox:setSelected(1, not on)
            m:onToggleShowIPs()
        end)
    end
    self:drawRect(x, y + tH, w, T.px(1), bs.a, bs.r, bs.g, bs.b)
    local cy = y + tH + T.px(1)
    local rows
    if self.tab == "public" then
        -- Find, then the filters, then the column heads
        local fH = T.px(FIND_H)
        self:drawRect(x + T.px(1), cy, w - T.px(2), fH - T.px(1), 1, s2.r, s2.g, s2.b)
        local f2, c = T.fontF2, T.text
        local findLabel = ZeD.tr("UI_ZeD_Join_Find")
        self:drawText(findLabel, x + T.px(8), cy + math.floor((fH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
        local ex = x + T.px(8) + MM.textW(f2, findLabel) + T.px(8)
        self:place(self.find, ex, cy + math.floor((fH - T.px(24)) / 2), x + w - T.px(8) - ex, T.px(24))
        cy = cy + fH
        -- the "show" filters, wrapped onto as many lines as the pane needs
        local ffH = T.px(FILTER_H)
        local gap = T.px(14)
        local lines, lineW = 1, T.px(8)
        for _, fdef in ipairs(FILTERS) do
            local tw = T.checkboxSz + T.px(6) + MM.textW(T.fontF2, ZeD.tr(fdef[2]))
            if lineW + tw > w - T.px(8) and lineW > T.px(8) then lines = lines + 1; lineW = T.px(8) end
            lineW = lineW + tw + gap
        end
        self:drawRect(x + T.px(1), cy, w - T.px(2), ffH * lines, 1, s2.r, s2.g, s2.b)
        local fx, fy = x + T.px(8), cy
        for _, fdef in ipairs(FILTERS) do
            local tb = m and m[fdef[1]]
            if tb then
                local tw = T.checkboxSz + T.px(6) + MM.textW(T.fontF2, ZeD.tr(fdef[2]))
                if fx + tw > x + w - T.px(8) and fx > x + T.px(8) then fx = x + T.px(8); fy = fy + ffH end
                local on = tb.selected[1] == true
                self:tick("flt:" .. fdef[1], fx, fy + math.floor((ffH - T.checkboxSz) / 2), ZeD.tr(fdef[2]), on, function()
                    tb.selected[1] = not on
                    m:onChangeFilter()
                    m.listChanged = true
                end)
                fx = fx + tw + gap
            end
        end
        cy = cy + ffH * lines
        self:drawRect(x, cy, w, T.px(1), bs.a, bs.r, bs.g, bs.b)
        cy = cy + T.px(1)
        rows = self:publicRows()
        cy = self:drawColumnHeads(x, cy, w)
    else
        rows = self:savedRows()
    end
    self._rows = rows
    if (not self.sel or not self:selectedRow(rows)) and rows[1] and rows[1].kind ~= "newServer" then
        self.sel = rows[1].key
        if rows[1].server and m then pcall(function() m:onSelectInternetServer(rows[1].server) end) end
    end
    -- the rows, scrolled as one
    local vy, vh = cy, y + h - T.px(1) - cy
    local total = 0
    for _, r in ipairs(rows) do total = total + T.px(r.h) end
    local sbW = T.sp.scrollbarW
    local over = total > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, total - vh)))
    self._list = { x = x, y = vy, w = w, h = vh }
    local gp = MM.gamepad()
    local ac = T.accent
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    local ry = vy - self.scroll
    for i, r in ipairs(rows) do
        local rh = T.px(r.h)
        local fid = "row:" .. i
        self._specs[#self._specs + 1] = { id = fid, listRow = true, row = i, col = 1, rowRef = r, ry = ry + self.scroll - vy, rh = rh, fn = function() self:pick(r); self:connectOrOpen(r) end }
        if ry + rh > vy and ry < vy + vh then
            if gp and self.focusId == fid then self:drawRect(x + T.px(1), ry, rw, rh, 0.55, ac.r, ac.g, ac.b)
            elseif r.key == self.sel then self:drawRect(x + T.px(1), ry, rw, rh, 0.22, ac.r, ac.g, ac.b) end
            self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            self:drawRow(r, x + T.px(1), ry, rw, rh)
            local top, bot = math.max(ry, vy), math.min(ry + rh, vy + vh)
            self._hits[#self._hits + 1] = { id = "join:" .. r.key, x = ax + x, y = ay + top, w = rw, h = bot - top, fn = function() self:pick(r) end }
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    if #rows == 0 then
        local d = T.textDim
        local msg = (self.tab == "public") and ((self:refreshWait() > 0) and getText("UI_servers_Connecting") or "") or ""
        if self.tab == "public" then msg = ZeD.tr("UI_ZeD_Join_NoServers") end
        self:drawText(msg, x + T.px(12), vy + T.px(12), d.r, d.g, d.b, d.a or 1, T.fontF2)
    end
    if over then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / total))
        local tyy = vy + math.floor((vh - th) * self.scroll / (total - vh))
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, th, MM.ctx.hot == "join:track" and "hover" or "default")
        self._hits[#self._hits + 1] = { id = "join:track", x = ax + sx, y = ay + vy, w = sbW, h = vh, drag = function(_, myy)
            self.scroll = math.floor(((myy - ay - vy) / vh) * total - vh / 2) end }
    end
end

-- A on a row: an account connects, the add rows open their forms
function ZeD_MMJoin:connectOrOpen(r)
    if r.kind == "account" or r.kind == "public" then self:connect() end
end

-- PUBLIC's column heads: Name / Players / Ping, a click sorts (again: the other way)
function ZeD_MMJoin:drawColumnHeads(x, y, w)
    local T = ZeD.T
    local m = mp()
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local hH = T.px(COLS_H)
    local s3, bs = T.surf3, T.borderS
    self:drawRect(x + T.px(1), y, w - T.px(2), hH, 1, s3.r, s3.g, s3.b)
    self:drawRect(x, y + hH, w, T.px(1), bs.a, bs.r, bs.g, bs.b)
    local f1, la = T.fontF1, T.accent
    local cols = self:columnX(x, w)
    for _, c in ipairs({ { "name", ZeD.tr("UI_ZeD_Join_ColName"), cols.name }, { "player", ZeD.tr("UI_ZeD_Join_ColPlayers"), cols.players }, { "ping", ZeD.tr("UI_ZeD_Join_ColPing"), cols.ping } }) do
        local cx = c[3]
        self:drawText(c[2], cx, y + math.floor((hH - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
        local tw = MM.textW(f1, c[2])
        if m and m.sortType == c[1] then
            local tri = T.px(7)
            if m.sortDown then ZeD.Atoms.drawTriangleDown(self, cx + tw + T.px(6), y + math.floor((hH - T.px(4)) / 2), tri, T.textDim)
            else ZeD.Atoms.drawTriangleUp(self, cx + tw + T.px(6), y + math.floor((hH - T.px(4)) / 2), tri, T.textDim) end
        end
        self._hits[#self._hits + 1] = { id = "join:sort:" .. c[1], x = ax + cx - T.px(4), y = ay + y, w = tw + T.px(20), h = hH, sound = true,
            fn = function() if m then m:onClickSort({ internal = c[1] }) end end }
    end
    return y + hH + T.px(1)
end

function ZeD_MMJoin:columnX(x, w)
    local T = ZeD.T
    local f2 = T.fontF2
    local pingW = MM.textW(f2, "99999") + T.px(10)
    local plW = MM.textW(f2, "999/999") + T.px(16)
    local sbW = T.sp.scrollbarW
    return { name = x + T.px(12), players = x + w - sbW - T.px(8) - pingW - plW, ping = x + w - sbW - T.px(8) - pingW, pingW = pingW, plW = plW }
end

function ZeD_MMJoin:drawRow(r, x, y, w, h)
    local T = ZeD.T
    local f2, f3 = T.fontF2, T.fontF3
    local tc, d = T.text, T.textDim
    local hc = T.textHead
    local sv = r.server
    if r.kind == "server" or r.kind == "public" then
        local cols = self:columnX(x, w + T.sp.scrollbarW)
        local nx = x + T.px(12)
        if r.kind == "server" then
            -- a saved server: a dot for whether it answered
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, nx, y + T.px(8) + math.floor((MM.fontH(f2) - dsz) / 2), sv:isResponded() and T.positive or T.textDim, dsz)
            nx = nx + dsz + T.px(8)
        end
        -- the players and the ping (right), the name, then the address, version and what it asks
        local players = (sv:getPlayers() and sv:getMaxPlayers()) and (s(sv:getPlayers()) .. "/" .. s(sv:getMaxPlayers())) or "-/-"
        local ping = sv:getPing() and tonumber(sv:getPing()) and tonumber(sv:getPing()) > -1 and s(sv:getPing()) or "-"
        local midY = y + math.floor((h - MM.fontH(f2)) / 2)
        self:drawText(players, cols.players, midY, tc.r, tc.g, tc.b, tc.a or 1, f2)
        self:drawText(ping, cols.ping, midY, tc.r, tc.g, tc.b, tc.a or 1, f2)
        local maxW = cols.players - T.px(12) - nx
        self:drawText(ZeD.Atoms.truncateText(s(sv:getName()), f2, maxW), nx, y + T.px(6), hc.r, hc.g, hc.b, hc.a or 1, f2)
        local bits = { s(sv:getDisplayAddress()) }
        if sv:getVersion() and sv:getVersion() ~= "" then bits[#bits + 1] = "v" .. s(sv:getVersion()) end
        -- what it asks, once the server has answered (a saved server that has not reads as open)
        if r.kind == "public" or sv:isResponded() then
            if sv:isPasswordProtected() then bits[#bits + 1] = ZeD.tr("UI_ZeD_Join_Password") end
            if not sv:isOpen() then bits[#bits + 1] = ZeD.tr("UI_ZeD_Join_Whitelist") end
            if sv:getMods() and sv:getMods() ~= "" then bits[#bits + 1] = ZeD.tr("UI_ZeD_Join_Modded") end
        end
        self:drawText(ZeD.Atoms.truncateText(table.concat(bits, MM.DOT), f3, maxW), nx, y + h - T.px(6) - MM.fontH(f3), d.r, d.g, d.b, d.a or 1, f3)
    elseif r.kind == "account" then
        local acc = r.account
        local nx = x + T.px(34)
        local name = s(acc:getUserName())
        if acc:getPlayerFirstAndLastName() then name = name .. "  (" .. s(acc:getPlayerFirstAndLastName()) .. ")" end
        self:drawText(ZeD.Atoms.truncateText(name, f2, w - T.px(46)), nx, y + T.px(5), tc.r, tc.g, tc.b, tc.a or 1, f2)
        local played = acc:getTimePlayed() and ZeD.tr("UI_ZeD_Join_MinPlayed", s(acc:getTimePlayed())) or ZeD.tr("UI_ZeD_Join_NotPlayed")
        local last = acc:getLastLogon() and (MM.DOT .. ZeD.tr("UI_ZeD_Join_LastOn", s(acc:getLastLogon()))) or ""
        self:drawText(ZeD.Atoms.truncateText(played .. last, f3, w - T.px(46)), nx, y + h - T.px(5) - MM.fontH(f3), d.r, d.g, d.b, d.a or 1, f3)
        -- the tree line from the server
        local bc = T.border
        self:drawRect(x + T.px(18), y, T.px(1), h, bc.a, bc.r, bc.g, bc.b)
        self:drawRect(x + T.px(18), y + math.floor(h / 2), T.px(10), T.px(1), bc.a, bc.r, bc.g, bc.b)
    elseif r.kind == "newAccount" then
        local bc = T.border
        self:drawRect(x + T.px(18), y, T.px(1), math.floor(h / 2), bc.a, bc.r, bc.g, bc.b)
        self:drawRect(x + T.px(18), y + math.floor(h / 2), T.px(10), T.px(1), bc.a, bc.r, bc.g, bc.b)
        self:drawText(getText("UI_servers_add_new_account"), x + T.px(34), y + math.floor((h - MM.fontH(f2)) / 2), d.r, d.g, d.b, d.a or 1, f2)
    elseif r.kind == "newServer" then
        self:drawText(getText("UI_servers_addserver"), x + T.px(12), y + math.floor((h - MM.fontH(f2)) / 2), d.r, d.g, d.b, d.a or 1, f2)
    end
end

-- the chosen server's facts, description and mods
function ZeD_MMJoin:drawDetails(x, y, w, h)
    local T = ZeD.T
    local bs = T.borderS
    self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    local m = mp()
    local sv = m and m.selectedInternetServer
    local r = self:selectedRow()
    if self.page == "list" and r and r.server then sv = r.server end
    if self.page ~= "list" and self.form then sv = self.form.server end
    if not sv then return end
    local pad = T.px(12)
    local ix, iw = x + pad, w - pad * 2
    local cy = y + pad
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local bigH = math.floor(ZeD.Text.height(hf, z))
    local tc = T.textHead
    local name = s(sv:getName())
    if ZeD.Text.width(hf, name, z) > iw then
        while #name > 1 and ZeD.Text.width(hf, name .. "...", z) > iw do name = name:sub(1, #name - 1) end
        name = name .. "..."
    end
    ZeD.Text.draw(self, hf, name, ix, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    cy = cy + bigH + T.px(8)
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local kvH = T.px(KV_ROW_H)
    local vx = ix + T.px(KV_LABEL_W)
    local function kv(label, value)
        local la, c = T.accent, T.text
        self:drawText(label, ix, cy + math.floor((kvH - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
        self:drawText(ZeD.Atoms.truncateText(value, f2, ix + iw - vx), vx, cy + math.floor((kvH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
        cy = cy + kvH
    end
    kv(ZeD.tr("UI_ZeD_Join_KvAddress"), (sv:getDisplayIp() and sv:getDisplayIp() ~= "") and s(sv:getDisplayIp()) or "-")
    kv(ZeD.tr("UI_ZeD_Join_KvPort"), s(sv:getDisplayPort() or "-"))
    kv(ZeD.tr("UI_ZeD_Join_ColPlayers"), (sv:getPlayers() and sv:getMaxPlayers()) and ZeD.tr("UI_ZeD_Join_PlayersOf", s(sv:getPlayers()), s(sv:getMaxPlayers())) or "-")
    kv(ZeD.tr("UI_ZeD_Join_ColPing"), (sv:getPing() and tonumber(sv:getPing()) and tonumber(sv:getPing()) > -1) and ZeD.tr("UI_ZeD_Join_PingMs", s(sv:getPing())) or "-")
    kv(ZeD.tr("UI_ZeD_Join_KvMap"), (sv:getMapName() and sv:getMapName() ~= "") and s(sv:getMapName()) or "-")
    kv(ZeD.tr("UI_ZeD_Join_KvVersion"), (sv:getVersion() and sv:getVersion() ~= "") and s(sv:getVersion()) or "-")
    local known = sv:isResponded()
    kv(ZeD.tr("UI_ZeD_Join_KvPassword"), known and getText(sv:isPasswordProtected() and "UI_Yes" or "UI_No") or "-")
    kv(ZeD.tr("UI_ZeD_Join_KvWhitelist"), known and getText(sv:isOpen() and "UI_No" or "UI_Yes") or "-")
    local wipe = sv:getLastWipe() or 0
    if wipe and wipe > 0 then
        local days = math.floor((getTimestamp() - wipe) / 86400)
        kv(ZeD.tr("UI_ZeD_Join_KvLastWipe"), ((days <= 0) and getText("UI_servers_wipe_today") or getText("UI_servers_wipe_days_ago", days)))
    end
    cy = cy + T.px(8)
    -- the description and the mods (plain), as far as the box allows
    local lines = {}
    local desc = s(sv:getDescription()):gsub("<LINE>", "\n"):gsub("<BR>", "\n")
    for para in (desc .. "\n"):gmatch("([^\n]*)\n") do
        local p = UI.plain(para)
        if p ~= "" then for _, l in ipairs(ZeD.Atoms.wrapText(p, f2, iw)) do lines[#lines + 1] = { l, f2, T.text } end end
    end
    local mods = s(sv:getMods())
    if mods ~= "" then
        lines[#lines + 1] = { "", f2, T.text }
        lines[#lines + 1] = { ZeD.tr("UI_ZeD_Join_KvMods"), f1, T.accent }
        local list = mods:gsub(";", ","):gsub(",%s*", ", ")
        for _, l in ipairs(ZeD.Atoms.wrapText(list, f3, iw)) do lines[#lines + 1] = { l, f3, T.textDim } end
    end
    for _, l in ipairs(lines) do
        local lh = MM.fontH(l[2]) + T.px(3)
        if cy + lh > y + h - pad then break end
        local c = l[3]
        self:drawText(l[1], ix, cy, c.r, c.g, c.b, c.a or 1, l[2])
        cy = cy + lh
    end
end

-- a form: a label over each field, the reason under it, ticks below
function ZeD_MMJoin:drawForm(x, y, w, h)
    local T = ZeD.T
    UI.insetBox(self, x, y, w, h)
    local pad = T.px(16)
    local ix, iw = x + pad, w - pad * 2
    local cy = y + pad
    local f1, f2 = T.fontF1, T.fontF2
    local lh, fh = T.px(18), T.px(24)
    local function field(label, e, problem)
        local la = T.accent
        self:drawText(label, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
        cy = cy + lh
        self:place(e, ix, cy, iw, fh)
        cy = cy + fh
        if problem then
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, ix, cy + T.px(6) + math.floor((MM.fontH(f2) - dsz) / 2), T.danger, dsz)
            local c = T.text
            self:drawText(ZeD.Atoms.truncateText(problem, f2, iw - dsz - T.px(6)), ix + dsz + T.px(6), cy + T.px(4), c.r, c.g, c.b, c.a or 1, f2)
        end
        cy = cy + T.px(NOTE_H) + T.px(6)
    end
    if self.page == "server" then
        local p = self:serverProblems()
        field(ZeD.upper(getText("UI_servers_server_name")):gsub(":%s*$", ""), self.fName, p.name)
        field(ZeD.upper(getText("UI_servers_ip_domain")):gsub(":%s*$", ""), self.fAddr, p.addr)
        field(ZeD.upper(getText("UI_servers_port")):gsub(":%s*$", ""), self.fPort, p.port)
        field(ZeD.upper(getText("UI_servers_server_password")):gsub(":%s*$", ""), self.fSrvPwd, nil)
    else
        local p = self:accountProblems()
        local f = self.form
        field(ZeD.upper(getText("UI_servers_login")):gsub(":%s*$", ""), self.fUser, p.user)
        local pwdLabel = ZeD.upper(getText("UI_servers_password")):gsub(":%s*$", "")
        field(pwdLabel, self.fPwd, p.pwd)
        if f.account and f.account:isSavePwd() then
            local d = T.textDim
            self:drawText(ZeD.tr("UI_ZeD_Join_KeepPassword"), ix, cy - T.px(NOTE_H) - T.px(4), d.r, d.g, d.b, d.a or 1, T.fontF3)
        end
        self:tick("remember", ix, cy, getText("UI_servers_remember_password"), f.remember, function() f.remember = not f.remember end)
        cy = cy + T.checkboxSz + T.px(12)
        if getSteamModeActive() then
            self:tick("relay", ix, cy, getText("UI_servers_useSteamRelay"), f.relay, function() f.relay = not f.relay end)
            cy = cy + T.checkboxSz + T.px(12)
        end
        -- vanilla's warning about sharing a server's address
        local warn = UI.plain(getText("UI_servers_serveripwarning"))
        if warn ~= "" then
            local d = T.textDim
            for _, l in ipairs(ZeD.Atoms.wrapText(warn, T.fontF3, iw)) do
                if cy + MM.fontH(T.fontF3) > y + h - pad then break end
                self:drawText(l, ix, cy, d.r, d.g, d.b, d.a or 1, T.fontF3)
                cy = cy + MM.fontH(T.fontF3) + T.px(2)
            end
        end
    end
end

function ZeD_MMJoin:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    local ask = nil
    local r = self:selectedRow()
    local m = mp()
    local function fieldIn(label)
        local f2 = T.fontF2
        local fx = T.px(U.STRIP_PAD_X) + T.px(4) + MM.textW(f2, label) + T.px(10)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
        self._shown[self.field] = true
    end
    if self.confirm == "pwd" then
        ask = ZeD.tr("UI_ZeD_Join_AskPassword", s(self._pwdFor and self._pwdFor.account:getUserName()))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_servers_connect"), function() self:answerPassword() end, "primary", (self.field:getText() or "") == "" } })
        fieldIn(ask)
    elseif self.confirm == "srvpwd" then
        ask = getText("UI_servers_server_password")
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_MainMenu_Ok"), function() self:answerPassword() end, "primary", (self.field:getText() or "") == "" } })
        fieldIn(ask)
    elseif self.confirm == "delServer" or self.confirm == "forget" then
        local sv = r and r.server
        ask = ZeD.tr("UI_ZeD_Join_AskRemoveServer", s(sv and sv:getName()))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_remove"), function() self:forgetServer(sv) end, "danger" } })
    elseif self.confirm == "delAccount" then
        local acc = r and r.account
        ask = ZeD.tr("UI_ZeD_Join_AskDeleteAccount", s(acc and acc:getUserName()))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:deleteAccount(acc) end, "danger" } })
    elseif self.page == "server" then
        UI.stripSpecs(self, stripY, w, row,
            { { "cancel", getText("UI_btn_cancel"), function() self:back() end } },
            { { "save", getText("UI_btn_save"), function() self:saveServerForm() end, "primary", any(self:serverProblems()) } })
    elseif self.page == "account" then
        local f = self.form
        UI.stripSpecs(self, stripY, w, row,
            { { "cancel", getText("UI_btn_cancel"), function() self:back() end } },
            { { "save", getText((f and f.connectAfter) and "UI_servers_connect" or "UI_btn_save"), function() self:saveAccountForm() end, "primary", any(self:accountProblems()) } })
    elseif self.tab == "public" then
        local wait = self:refreshWait()
        local fav = r and m and m:getServerFeatured(r.server)
        local rights = {
            { "refresh", (wait > 0) and ZeD.tr("UI_ZeD_Join_RefreshWait", wait) or getText("UI_servers_refresh"), function() self:refresh() end, "default", wait > 0 },
        }
        if r and r.server then
            if fav then rights[#rights + 1] = { "fav", ZeD.tr("UI_ZeD_Join_Forget"), function() self:setConfirm("forget") end }
            else rights[#rights + 1] = { "fav", ZeD.tr("UI_ZeD_Join_SaveServer"), function() self:saveServer(r.server) end } end
        end
        rights[#rights + 1] = { "connect", getText("UI_servers_connect"), function() self:connect() end, "primary", not (r and r.server) }
        UI.stripSpecs(self, stripY, w, row, { { "back", getText("UI_btn_back"), function() self:back() end } }, rights)
    else
        local rights = {}
        if r and r.kind == "server" then
            rights[#rights + 1] = { "edit", getText("UI_servers_button_edit"), function() self:openServerForm(r.server) end }
            rights[#rights + 1] = { "del", getText("UI_btn_remove"), function() self:setConfirm("delServer") end }
            rights[#rights + 1] = { "addAcc", ZeD.tr("UI_ZeD_Join_AddAccount"), function() self:openAccountForm(r.server, nil, false) end }
        elseif r and r.kind == "account" then
            rights[#rights + 1] = { "edit", getText("UI_servers_button_edit"), function() self:openAccountForm(r.server, r.account, false) end }
            rights[#rights + 1] = { "del", getText("UI_btn_delete"), function() self:setConfirm("delAccount") end }
        end
        if not (r and (r.kind == "server" or r.kind == "account")) then
            rights[#rights + 1] = { "addSrv", ZeD.tr("UI_ZeD_Join_AddServer"), function() self:openServerForm(nil) end }
        end
        local canConnect = r and (r.kind == "account" or (r.kind == "server" and r.server:getAccounts():size() == 1))
        rights[#rights + 1] = { "connect", getText("UI_servers_connect"), function() self:connect() end, "primary", not canConnect }
        UI.stripSpecs(self, stripY, w, row, { { "back", getText("UI_btn_back"), function() self:back() end } }, rights)
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- CONTROLLER + KEYS + WHEEL --------------------------------------------------------------
function ZeD_MMJoin:joyDir(dir)
    ZeD_MMWindow.joyDir(self, dir)
    for _, b in ipairs(self._specs) do
        if b.id == self.focusId and b.rowRef then
            self.sel = b.rowRef.key
            local vh = self._list and self._list.h or 0
            if b.ry < self.scroll then self.scroll = b.ry
            elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
        end
    end
end
function ZeD_MMJoin:joyB()
    if self.confirm then self:setConfirm(false); return end
    self:back()
end
function ZeD_MMJoin:joyBumper(dir) if self.page == "list" and not self.confirm then self:setTab((dir < 0) and "saved" or "public") end end
function ZeD_MMJoin:joyY() if self.page == "list" and not self.confirm and self.tab == "public" then self:refresh() end end

function ZeD_MMJoin:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "LB", label = "" }, { glyph = "RB", label = ZeD.tr("UI_ZeD_Join_PromptTabs") }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } }
end

function ZeD_MMJoin:keyEscape()
    if self.confirm then self:setConfirm(false); return true end
    for _, e in ipairs(self._fields) do if e:isFocused() then e:unfocus(); return true end end
    self:back()
    return true
end

function ZeD_MMJoin:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    for _, e in ipairs(self._fields) do if e:isFocused() then return false end end
    if self.confirm then return false end
    if key == Keyboard.KEY_RETURN then
        if self.page == "server" then self:saveServerForm()
        elseif self.page == "account" then self:saveAccountForm()
        else self:connect() end
        return true
    end
    return false
end

function ZeD_MMJoin:close() self:back() end

function ZeD_MMJoin:wheel(del)
    local l = self._list
    if not l or self.page ~= "list" then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < l.x or mx > l.x + l.w or my < l.y or my > l.y + l.h then return false end
    self.scroll = self.scroll + del * ZeD.T.px(ROW_H)
    return true
end
function ZeD_MMJoin:onMouseWheel(del) return MM.wheel(del) end

-- ============================================================================
-- CONNECTING: vanilla's ConnectToServer, mirrored
-- ============================================================================
ZeD_MMConnect = ZeD_MMWindow:derive("ZeD_MMConnect")

function ZeD_MMConnect:new()
    local o = ZeD_MMWindow.new(self, "connect")
    o.noResetControl = true
    return o
end

function ZeD_MMConnect:createChildren()
    ZeD_Window.createChildren(self)
    self.code = UI.newEntry(self)        -- the authenticator code, when the server asks
    self.code:setVisible(false)
    self.code.onCommandEntered = function() self._enterAt = MM.now(); self:sendCode() end
end

function ZeD_MMConnect:onShow() self.focusId = "back" end

function ZeD_MMConnect:back()
    local c = cts()
    MM.clickSound()
    if c then c:onBackButton() else MM.showView("main") end
end

function ZeD_MMConnect:sendCode()
    local c = cts()
    if not c then return end
    sendGoogleAuth(c.userName:getName(), self.code:getText() or "")
    c.googleAuthPopup:setVisible(false)
    self.code:setText("")
    MM.clickSound()
end

function ZeD_MMConnect:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local c = cts()
    local wantH = T.px(330)
    local w, h = UI.placeOnTube(self, wantH)
    self.title = ZeD.tr("UI_ZeD_Join_TitleConnect", c and c.title and c.title:getName() or ZeD.tr("UI_ZeD_Join_Connecting"))
    self.titleStats = {}
    ZeD_Window.prerender(self)
    if not c then return end
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, bx, by, bw, bh)
    local ix, iw = bx + T.px(20), bw - T.px(40)
    local cy = by + T.px(18)
    -- the server (or address) and the account
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local tc = T.textHead
    if c.serverName:isVisible() then
        ZeD.Text.draw(self, hf, s(c.serverName:getName()), ix, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
        cy = cy + math.floor(ZeD.Text.height(hf, z)) + T.px(4)
    end
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local d = T.textDim
    self:drawText(ZeD.tr("UI_ZeD_Join_AsUser", s(c.userName:getName())), ix, cy, d.r, d.g, d.b, d.a or 1, f2)
    cy = cy + MM.fontH(f2) + T.px(18)
    -- the status: a dot (blinking while it tries, red when it failed) and vanilla's words
    local dsz = T.px(9)
    local failed = (not c.connecting) and (c.backBtn:getTitle() == getText("UI_btn_back"))
    local dc = failed and T.danger or T.accent
    local blink = c.connecting and (math.floor(MM.now() / 450) % 2 == 0)
    if not c.connecting or blink then ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), dc, dsz) end
    local status = s(c.connectLabel.name)
    local tcol = T.text
    local sy = cy
    for line in (status .. "\n"):gmatch("([^\n]*)\n") do
        for _, l in ipairs(ZeD.Atoms.wrapText(UI.plain(line), f2, iw - dsz - T.px(10))) do
            self:drawText(l, ix + dsz + T.px(10), sy, tcol.r, tcol.g, tcol.b, tcol.a or 1, f2)
            sy = sy + MM.fontH(f2) + T.px(3)
        end
    end
    cy = math.max(sy, cy + MM.fontH(f2)) + T.px(14)
    -- the authenticator code, when the server asks for it
    local codeOn = c.googleAuthPopup and c.googleAuthPopup:isVisible()
    if codeOn then
        local la = T.accent
        self:drawText(ZeD.upper(UI.plain(getText("UI_ConnectToServer_GoogleAuth_Request"))), ix, cy, la.r, la.g, la.b, la.a or 1, f1)
        cy = cy + T.px(18)
        UI.styleEntry(self.code, ix, cy, T.px(160), T.px(24))
        if not self.code:isVisible() then self.code:setVisible(true); self.code:focus() end
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        self._hits[#self._hits + 1] = { id = "connect:code", x = ax + ix, y = ay + cy, w = T.px(160), h = T.px(24), fn = function() self.code:focus() end }
        cy = cy + T.px(34)
    elseif self.code:isVisible() then
        self.code:setVisible(false)
    end
    -- vanilla's reminder
    local rem = UI.plain(s(c.richText and c.richText.text))
    for _, l in ipairs(ZeD.Atoms.wrapText(rem, f3, iw)) do
        if cy + MM.fontH(f3) > by + bh - T.px(10) then break end
        self:drawText(l, ix, cy, d.r, d.g, d.b, d.a or 1, f3)
        cy = cy + MM.fontH(f3) + T.px(2)
    end
    local rights = {}
    if codeOn then rights[#rights + 1] = { "send", ZeD.upper(UI.plain(getText("UI_ConnectToServer_GoogleAuth_Send"))), function() self:sendCode() end, "primary" } end
    UI.stripSpecs(self, stripY, w, 1000, { { "back", c.connecting and getText("UI_coopscreen_btn_abort") or getText("UI_btn_back"), function() self:back() end } }, rights)
    self._stripY, self._stripH = stripY, stripH
end

function ZeD_MMConnect:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, nil)
    ZeD_Window.render(self)
end

function ZeD_MMConnect:joyB() self:back() end
function ZeD_MMConnect:keyEscape() self:back(); return true end
function ZeD_MMConnect:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    return false
end
function ZeD_MMConnect:close() self:back() end
function ZeD_MMConnect:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local c = cts()
    return { { glyph = "B", label = (c and c.connecting) and ZeD.btnCase(getText("UI_coopscreen_btn_abort")) or ZeD.btnCase(getText("UI_btn_back")) } }
end

-- ============================================================================
local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "join" and MM.root and MM.root.joinWin then
        if MM.dropWheel and MM.dropWheel(del) then return true end
        return MM.root.joinWin:wheel(del)
    end
    return _wheel(del)
end

-- on the desk: vanilla's multiplayer screen lands on "join"; its connecting screen stays
-- shown off the screen (it follows the connection only while visible) and "connect" mirrors it
MM.addView("join", "joinWin", function() return ZeD_MMJoin:new() end, "multiplayer")
MM.addView("connect", "connectWin", function() return ZeD_MMConnect:new() end, "connectToServer", true)
