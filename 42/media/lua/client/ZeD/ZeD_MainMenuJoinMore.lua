-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuJoinMore.lua
-- ============================================================================
-- THE REST OF JOINING, ON THE MONITOR. Client; three organisms (windows on
-- the desk), replacing the last of vanilla's join windows.
--
-- Three more of vanilla's join screens become ZeD windows on the desk. Each
-- stays vanilla's engine: built and "visible" but off the screen (it follows
-- the game's events only while shown), mirrored by its view (MM.mirror), and
-- every answer runs vanilla's own handler.
--
-- SERVER WORKSHOP ITEMS (ServerWorkshopItemScreen, Steam only): joining a
--   server whose Workshop mods are missing. The mods as a list, each with its
--   size, its state as a status square and a progress bar while it downloads;
--   vanilla's prompt or error above them. Band: Disconnect | Install. Once
--   vanilla hides it on success the connection goes on: the Connecting view
--   takes over again (where vanilla's own flow leaves an empty screen).
-- SERVER INVITE (BootstrapConnectPopup): a Steam invite or a +connect launch
--   asks Steam about the server first. Drawn like Connecting: the address, a
--   blinking square while it asks, vanilla's words. Band: Cancel (Back once it
--   failed).
-- CONNECT TO (ServerConnectPopup): the address from the invite or the command
--   line and vanilla's three fields (server password, account, password), the
--   Steam relay tick. Band: Cancel | Connect (grayed with vanilla's reason
--   while the account is empty).
--
-- Safe mode: MM.root is gone, so the mirrors pass every call straight to
-- vanilla and its own screens show.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuJoin"
require "OptionScreens/ConnectToServer"
require "OptionScreens/ServerWorkshopItemScreen"
require "OptionScreens/BootstrapConnectPopup"
require "OptionScreens/ServerConnectPopup"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local ROW_H, NOTE_H, BAR_W, BAR_H = 48, 20, 160, 10
local CONNECT_H, FORM_H = 330, 470

local function ms() return MainScreen and MainScreen.instance end
local function wsScreen() local m = ms(); return m and m.serverWorkshopItem end
local function bootScreen() local m = ms(); return m and m.bootstrapConnectPopup end
local function formScreen() local m = ms(); return m and m.serverConnectPopup end

local function s(v) if v == nil then return "" end; return tostring(v) end
-- (a clock in ms over a step, without % past 2^31: ZeD_MainMenuJoin.lua's clockStep)
local function clockStep(t, step, m)
    local n = math.floor(t / step)
    return n - math.floor(n / m) * m
end
-- a form field's name: vanilla's label without its colon, in sentence case
local function formLabel(key)
    local t = getText(key):gsub(":%s*$", "")
    return ZeD.textCase(t)
end

-- the heading face (the Connecting window's server line)
local function heading(win, text, x, y, maxW)
    local T = ZeD.T
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local tc = T.textHead
    local t = text
    if ZeD.Text.width(hf, t, z) > maxW then
        while #t > 1 and ZeD.Text.width(hf, t .. "...", z) > maxW do t = t:sub(1, #t - 1) end
        t = t .. "..."
    end
    ZeD.Text.draw(win, hf, t, x, y, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    return math.floor(ZeD.Text.height(hf, z))
end

-- a status line: a square mark (blinking while waiting, red on a fault) and the words, wrapped
local function statusLines(win, text, x, y, w, color, blink)
    local T = ZeD.T
    local f2 = T.fontF2
    local dsz = T.px(9)
    if not blink or clockStep(MM.now(), 450, 2) == 0 then
        ZeD.Atoms.drawStatusDot(win, x, y + math.floor((MM.fontH(f2) - dsz) / 2), color, dsz)
    end
    local tc = T.text
    local cy = y
    for line in (s(text) .. "\n"):gmatch("([^\n]*)\n") do
        for _, l in ipairs(ZeD.Atoms.wrapText(UI.plain(line), f2, w - dsz - T.px(10))) do
            win:drawText(l, x + dsz + T.px(10), cy, tc.r, tc.g, tc.b, tc.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(3)
        end
    end
    return math.max(cy, y + MM.fontH(f2))
end

-- ============================================================================
-- THE SERVER'S WORKSHOP ITEMS
-- ============================================================================
ZeD_MMWsItems = ZeD_MMWindow:derive("ZeD_MMWsItems")

function ZeD_MMWsItems:new()
    local o = ZeD_MMWindow.new(self, "wsitems")
    o.noResetControl = true
    o.scroll = 0
    return o
end

function ZeD_MMWsItems:onShow()
    self.scroll = 0
    self.focusId = nil
    self._autoFocus = nil
    self.done = nil
end

--- The mods vanilla's list holds: { key, id, title, size (MB), state; while downloading frac, done, of (MB) }.
function MM.wsItemRows(scr)
    local rows = {}
    local lb = scr and scr.listbox
    for i, it in ipairs(lb and lb.items or {}) do
        local d = it.item or {}
        local r = { key = "ws:" .. s(d.id or i), id = s(d.id or it.text) }
        if d.details then
            pcall(function()
                r.title = d.details:getTitle()
                r.size = math.floor(d.details:getFileSize() / 1024 / 1024 * 10 + 0.5) / 10
                r.state = d.details:getState()
            end)
        end
        if r.state == "Downloading" and d.downloaded and d.total and d.total > 0 then
            r.frac = math.max(0, math.min(1, d.downloaded / d.total))
            r.done = math.floor(d.downloaded / 1024 / 1024 * 10 + 0.5) / 10
            r.of = math.floor(d.total / 1024 / 1024 * 10 + 0.5) / 10
        end
        rows[#rows + 1] = r
    end
    return rows
end

--- Vanilla's words above the list, and true when they are an error that replaced its prompt.
function MM.wsItemsNote(scr)
    local text = s(scr and scr.label and scr.label.name)
    local prompt = getText("UI_ServerWorkshopItemScreen_Prompt")
    return text, (text ~= "" and text ~= prompt)
end

function ZeD_MMWsItems:install()
    local scr = wsScreen()
    if not scr or not (scr.installButton and scr.installButton.enable ~= false) then return end
    MM.clickSound()
    scr:onButtonInstall()
end

-- Disconnect: vanilla's (the screen it came from shows again, the join stops there)
function ZeD_MMWsItems:disconnect()
    local scr = wsScreen()
    MM.clickSound()
    if not scr then MM.showView("main"); return end
    scr._zedLeaving = true
    local ok, err = pcall(function() scr:onButtonDisconnect() end)
    scr._zedLeaving = nil
    if not ok then
        print("[ZeD] Workshop items: the game's Disconnect failed (" .. tostring(err) .. ")")
        if MM.view == "wsitems" then MM.showView("main") end
    end
end

function ZeD_MMWsItems:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local scr = wsScreen()
    local w, h = UI.placeOnTube(self)
    local rows = MM.wsItemRows(scr)
    self.title = ZeD.textCase(getText("UI_ServerWorkshopItemScreen_Title"))
    self.titleStats = { { text = ZeD.tr(#rows == 1 and "UI_ZeD_WsItems_CountOne" or "UI_ZeD_WsItems_CountMany", #rows), noMark = true } }
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    -- vanilla's prompt (or its error, a red square)
    local note, isErr = MM.wsItemsNote(scr)
    local f2, f3 = T.fontF2, T.fontF3
    local cy = by
    if self.done then
        cy = statusLines(self, getText("UI_servers_Connecting"), bx, cy, bw, T.accent, true) + T.px(8)
    elseif isErr then
        cy = statusLines(self, note, bx, cy, bw, T.danger, false) + T.px(8)
    else
        local d = T.text
        for _, l in ipairs(ZeD.Atoms.wrapText(UI.plain(note), f2, bw)) do
            self:drawText(l, bx, cy, d.r, d.g, d.b, d.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(3)
        end
        cy = cy + T.px(5)
    end
    -- the list
    local lx, ly, lw, lh = bx, cy, bw, by + bh - cy
    UI.insetBox(self, lx, ly, lw, lh)
    local vy, vh = ly + T.px(1), lh - T.px(2)
    local rh = T.px(ROW_H)
    local total = #rows * rh
    local sbW = T.sp.scrollbarW
    local over = total > vh
    local rw = lw - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, total - vh)))
    self._list = { x = lx, y = vy, w = lw, h = vh }
    local gp = MM.gamepad()
    self:setStencilRect(lx + T.px(1), vy, lw - T.px(2), vh)
    local ry = vy - self.scroll
    for i, r in ipairs(rows) do
        -- every mod is a controller stop (the list scrolls to follow; A does nothing on it)
        self._specs[#self._specs + 1] = { id = r.key, listRow = true, row = i, col = 1, key = r.key, ry = ry + self.scroll - vy, rh = rh }
        if ry + rh > vy and ry < vy + vh then
            local focused = gp and self.focusId == r.key
            local onFocus = MM.rowLook(self, lx + T.px(1), ry, rw, rh, false, false, focused)
            self:drawRect(lx + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local ix = lx + T.px(12)
            -- the state, as a square on the left: installed green, downloading the accent (blinking), a fault red
            local dsz = T.px(9)
            local dc = (r.state == "Installed") and T.positive or ((r.state == "Error") and T.danger or ((r.state == "Downloading") and T.accent or T.textDim))
            if r.state and not (r.state == "Downloading" and clockStep(MM.now(), 450, 2) == 1) then
                ZeD.Atoms.drawStatusDot(self, ix, ry + math.floor((rh - dsz) / 2), dc, dsz)
            end
            local tx = ix + dsz + T.px(10)
            local rightW = T.px(BAR_W) + T.px(12)
            local tw = lx + rw - rightW - tx - T.px(8)
            local nameC = onFocus and T.textOnFocus or T.textHead
            local dimC = onFocus and T.textOnFocus or T.textDim
            self:drawText(ZeD.Atoms.truncateText(r.title or (getText("UI_WorkshopSubmit_ItemID") .. " " .. r.id), f2, tw), tx, ry + T.px(7), nameC.r, nameC.g, nameC.b, nameC.a or 1, f2)
            local sub = r.size and getText("UI_WorkshopServerItemState_FileSize", r.size) or ""
            if r.state then
                local st = getTextOrNull("UI_WorkshopServerItemState_" .. r.state) or r.state
                sub = (sub ~= "" and (sub .. MM.DOT) or "") .. st
            end
            self:drawText(ZeD.Atoms.truncateText(sub, f3, tw), tx, ry + rh - T.px(7) - MM.fontH(f3), dimC.r, dimC.g, dimC.b, dimC.a or 1, f3)
            -- downloading: the bar and its numbers
            if r.frac then
                local barX = lx + rw - rightW
                local barY = ry + T.px(9)
                ZeD.Atoms.drawSmoothBar(self, barX, barY, T.px(BAR_W), r.frac, false, nil, T.px(BAR_H))
                local nums = ZeD.tr("UI_ZeD_WsItems_Progress", r.done, r.of)
                self:drawText(ZeD.Atoms.truncateText(nums, f3, T.px(BAR_W)), barX, barY + T.px(BAR_H) + T.px(5), dimC.r, dimC.g, dimC.b, dimC.a or 1, f3)
            end
            local cy0, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = "wsitems:" .. r.key, x = ax + lx, y = ay + cy0, w = rw, h = ch }
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    if over then
        MM.scrollBar(self, "wsitems:track", lx + lw - T.px(1) - sbW, vy, sbW, vh, self.scroll, total, function(v) self.scroll = v end, { step = rh })
    end
    -- the band: Disconnect | Install (grayed until Steam has the items' details, and once pressed)
    local canInstall = scr and scr.installButton and scr.installButton.enable ~= false and not self.done
    -- the controller lands on the main answer: Install once it is live (vanilla's A), else Disconnect
    -- (until the player moves it: then it stays where they put it)
    if not self.focusId or self._autoFocus or (self.focusId == "install" and not canInstall) then
        self.focusId = canInstall and "install" or "disconnect"
        self._autoFocus = true
    end
    local rights = {}
    if not self.done then
        rights[1] = { "install", ZeD.btnCase(getText("UI_btn_install")), function() self:install() end, "primary", not canInstall, ZeD.tr("UI_ZeD_MMHelp_WsInstall") }
    end
    UI.stripSpecs(self, stripY, w, 1000, { { "disconnect", ZeD.btnCase(getText("UI_btn_disconnect")), function() self:disconnect() end, "default", false, ZeD.tr("UI_ZeD_MMHelp_WsDisconnect") } }, rights)
end

function ZeD_MMWsItems:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMWsItems:getStatusLine()
    local n = #MM.wsItemRows(wsScreen())
    return ZeD.tr(n == 1 and "UI_ZeD_WsItems_CountOne" or "UI_ZeD_WsItems_CountMany", n)
end

-- the list follows the controller
function ZeD_MMWsItems:joyDir(dir)
    self._autoFocus = nil
    ZeD_MMWindow.joyDir(self, dir)
    for _, b in ipairs(self._specs) do
        if b.id == self.focusId and b.listRow then
            local vh = self._list and self._list.h or 0
            if b.ry < self.scroll then self.scroll = b.ry
            elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
        end
    end
end
function ZeD_MMWsItems:joyB() self:disconnect() end
function ZeD_MMWsItems:joyY() self:install() end
function ZeD_MMWsItems:keyEscape() self:disconnect(); return true end
function ZeD_MMWsItems:keyOther(key)
    if key == Keyboard.KEY_RETURN then self:install(); return true end
    return false
end
function ZeD_MMWsItems:close() self:disconnect() end
function ZeD_MMWsItems:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local t = {}
    local scr = wsScreen()
    if scr and scr.installButton and scr.installButton.enable ~= false and not self.done then
        t[#t + 1] = { glyph = "Y", label = ZeD.btnCase(getText("UI_btn_install")) }
    end
    t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_disconnect")) }
    return t
end
function ZeD_MMWsItems:wheel(del)
    local l = self._list
    if not l then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < l.x or mx > l.x + l.w or my < l.y or my > l.y + l.h then return false end
    self.scroll = self.scroll + del * ZeD.T.px(ROW_H)
    return true
end
function ZeD_MMWsItems:onMouseWheel(del) return MM.wheel(del) end

--- The keep function MM.mirror asks as vanilla hides the screen (true keeps the view up): Disconnect
--- leaves the view; success goes back to the connection still under way (vanilla's ConnectToServer,
--- shown again so the Connecting view follows it to the end); from Host's screen the view stays, saying
--- it is contacting the server.
function MM.wsItemsKeep(scr)
    if scr._zedLeaving then return false end
    local prev = scr.prevScreen
    local cts = ConnectToServer and ConnectToServer.instance
    if prev and cts and prev == cts then
        local ok = pcall(function() prev:setVisible(true, JoypadState.getMainMenuJoypad()) end)
        if ok then return true end
    end
    local w = MM.root and MM.root.wsItemsWin
    if w then w.done = true end
    return true
end

-- ============================================================================
-- THE SERVER INVITE (asking Steam about the server first)
-- ============================================================================
ZeD_MMBootstrap = ZeD_MMWindow:derive("ZeD_MMBootstrap")

function ZeD_MMBootstrap:new()
    local o = ZeD_MMWindow.new(self, "bootstrap")
    o.noResetControl = true
    return o
end

function ZeD_MMBootstrap:onShow() self.focusId = "back" end

-- Cancel while it asks (a late answer is ignored: vanilla checks its own connecting flag), Back once it failed
function ZeD_MMBootstrap:back()
    local b = bootScreen()
    MM.clickSound()
    if not b then MM.showView("main"); return end
    b.connecting = false
    b:onBackButton()
end

function ZeD_MMBootstrap:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local b = bootScreen()
    local w, h = UI.placeOnTube(self, T.px(CONNECT_H))
    self.title = ZeD.textCase(getText("UI_BootstrapConnectPopup_Title"))
    self.titleStats = {}
    ZeD_Window.prerender(self)
    if not b then return end
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, bx, by, bw, bh)
    local ix, iw = bx + T.px(20), bw - T.px(40)
    local cy = by + T.px(18)
    if b.host then
        cy = cy + heading(self, s(b.host) .. " : " .. s(b.port), ix, cy, iw) + T.px(18)
    end
    local failed = not b.connecting
    statusLines(self, s(b.connectLabel and b.connectLabel.name), ix, cy, iw, failed and T.danger or T.accent, b.connecting)
    local label = b.connecting and getText("UI_Cancel") or getText("UI_btn_back")
    UI.stripSpecs(self, stripY, w, 1000, { { "back", ZeD.btnCase(label), function() self:back() end } }, {})
end

function ZeD_MMBootstrap:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMBootstrap:joyB() self:back() end
function ZeD_MMBootstrap:keyEscape() self:back(); return true end
function ZeD_MMBootstrap:close() self:back() end
function ZeD_MMBootstrap:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local b = bootScreen()
    return { { glyph = "B", label = ZeD.btnCase((b and b.connecting) and getText("UI_Cancel") or getText("UI_btn_back")) } }
end

-- ============================================================================
-- CONNECT TO (the address an invite or the command line gave)
-- ============================================================================
ZeD_MMSrvForm = ZeD_MMWindow:derive("ZeD_MMSrvForm")

function ZeD_MMSrvForm:new()
    local o = ZeD_MMWindow.new(self, "srvform")
    o.noResetControl = true
    o.relay = false
    return o
end

function ZeD_MMSrvForm:createChildren()
    ZeD_Window.createChildren(self)
    local function entry(masked)
        local e = UI.newEntry(self)
        e:setVisible(false)
        if masked then e:setMasked(true) end
        e.onCommandEntered = function() self._enterAt = MM.now(); e:unfocus() end
        return e
    end
    self.fSrvPwd, self.fUser, self.fPwd = entry(true), entry(false), entry(true)
    self._fields = { self.fSrvPwd, self.fUser, self.fPwd }
end

-- vanilla filled its own fields (setServer: the last account used on that address): they start ours
local function entryText(e)
    if not e then return "" end
    if e.getInternalText then return s(e:getInternalText()) end
    return s(e:getText())
end
function ZeD_MMSrvForm:onShow()
    local p = formScreen()
    self.focusId = nil
    if not p then return end
    self.fSrvPwd:setText(entryText(p.serverPasswordEntry))
    self.fUser:setText(entryText(p.usernameEntry))
    self.fPwd:setText(entryText(p.passwordEntry))
    self.relay = (p.connectTypeEntry and p.connectTypeEntry.selected and p.connectTypeEntry.selected[1]) and true or false
end

function ZeD_MMSrvForm:userProblem()
    local u = s(self.fUser:getText()):gsub("^%s+", ""):gsub("%s+$", "")
    if u == "" then return getText("UI_servers_err_username") end
    return nil
end

-- Connect: our fields into vanilla's, then vanilla's own CONNECT (its checks, ConnectToServer)
function ZeD_MMSrvForm:connect()
    local p = formScreen()
    if not p or self:userProblem() then return end
    MM.clickSound()
    p.serverPasswordEntry:setText(self.fSrvPwd:getInternalText() or "")
    p.usernameEntry:setText(self.fUser:getInternalText() or "")
    p.passwordEntry:setText(self.fPwd:getInternalText() or "")
    if p.connectTypeEntry and p.connectTypeEntry.selected then p.connectTypeEntry.selected[1] = self.relay end
    for _, e in ipairs(self._fields) do if e:isFocused() then e:unfocus() end end
    p:onOptionMouseDown(p.connectBtn, 0, 0)
end

function ZeD_MMSrvForm:cancel()
    local p = formScreen()
    MM.clickSound()
    for _, e in ipairs(self._fields) do if e:isFocused() then e:unfocus() end end
    if not p then MM.showView("main"); return end
    p:onOptionMouseDown(p.cancelBtn, 0, 0)
end

-- a field: with a controller, A brings up the on-screen keyboard (ZeD_MainMenuSpawn's edit)
function ZeD_MMSrvForm:edit(entry)
    local jd = MM.gamepad() and JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local osk = OnScreenKeyboard.Show(jd.player or 0, entry, jd)
        if osk then
            osk.prevFocus = jd.focus
            jd.focus = osk
            updateJoypadFocus(jd)
            return
        end
    end
    entry:focus()
end

function ZeD_MMSrvForm:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local p = formScreen()
    local w, h = UI.placeOnTube(self, T.px(FORM_H))
    local addr = p and (s(p.ip) .. " : " .. s(p.port)) or ""
    self.title = ZeD.tr("UI_ZeD_Join_TitleConnect", addr)
    self.titleStats = {}
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, bx, by, bw, bh)
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local ix = bx + T.px(20)
    local iw = math.min(bw - T.px(40), T.px(420))
    local cy = by + T.px(16)
    local f1, f2 = T.fontF1, T.fontF2
    local d = T.textDim
    self:drawText(UI.plain(getText("UI_ServerConnectPopup_Label")), ix, cy, d.r, d.g, d.b, d.a or 1, f2)
    cy = cy + MM.fontH(f2) + T.px(4)
    cy = cy + heading(self, addr, ix, cy, bw - T.px(40)) + T.px(16)
    local shown = {}
    local lh, fh = T.px(18), T.px(24)
    local n = 0
    local function field(label, e, problem)
        n = n + 1
        local la = T.accent
        self:drawText(label, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
        cy = cy + lh
        UI.styleEntry(e, ix, cy, iw, fh)
        if not e:isVisible() then e:setVisible(true) end
        shown[e] = true
        self._hits[#self._hits + 1] = { id = "srvform:f" .. n, x = ax + ix, y = ay + cy, w = iw, h = fh, fn = function() e:focus() end }
        self._specs[#self._specs + 1] = { id = "field:" .. n, noDraw = true, row = n, col = 1, x = ix, y = cy, w = iw, h = fh, fn = function() self:edit(e) end }
        cy = cy + fh
        if problem then
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, ix, cy + T.px(6) + math.floor((MM.fontH(f2) - dsz) / 2), T.danger, dsz)
            local c = T.text
            self:drawText(ZeD.Atoms.truncateText(problem, f2, iw - dsz - T.px(6)), ix + dsz + T.px(6), cy + T.px(4), c.r, c.g, c.b, c.a or 1, f2)
        end
        cy = cy + T.px(NOTE_H) + T.px(6)
    end
    local problem = self:userProblem()
    -- the controller lands on Connect, or on the account field while it is empty
    if not self.focusId then self.focusId = problem and "field:2" or "connect" end
    field(formLabel("UI_servers_serverpwd"), self.fSrvPwd, nil)
    field(formLabel("UI_servers_username"), self.fUser, problem)
    field(formLabel("UI_servers_pwd"), self.fPwd, nil)
    -- the Steam relay (Steam only, as vanilla)
    if p and p.connectTypeEntry then
        local cb = T.checkboxSz
        local label = getText("UI_servers_useSteamRelay")
        local tw = MM.textW(f2, label)
        local b = { x = ix - T.px(3), y = cy - T.px(4), w = cb + T.px(12) + tw, h = cb + T.px(8), check = true, on = self.relay, text = label }
        self._specs[#self._specs + 1] = { id = "relay", noDraw = true, row = 10, col = 1, x = b.x, y = b.y, w = b.w, h = b.h, fn = function() self.relay = not self.relay; MM.clickSound() end }
        local gp = MM.gamepad()
        MM.drawBtn(self, b, (not gp) and MM.ctx.hot == "srvform:relay", gp and self.focusId == "relay", false)
        self._hits[#self._hits + 1] = { id = "srvform:relay", x = ax + b.x, y = ay + b.y, w = b.w, h = b.h, fn = function() self.relay = not self.relay end, sound = true }
    end
    for _, e in ipairs(self._fields) do
        if not shown[e] and e:isVisible() then if e:isFocused() then e:unfocus() end; e:setVisible(false) end
    end
    -- the focused field's ring (the controller's)
    if MM.gamepad() then
        for _, sp in ipairs(self._specs) do
            if sp.id == self.focusId and sp.id ~= "relay" then ZeD.Focus.mark(self, sp.x - T.px(2), sp.y - T.px(2), sp.w + T.px(4), sp.h + T.px(4), MM.focusOpts()) end
        end
    end
    UI.stripSpecs(self, stripY, w, 1000, { { "cancel", getText("UI_Cancel"), function() self:cancel() end } },
        { { "connect", getText("UI_ServerConnectPopup_Connect"), function() self:connect() end, "primary", problem ~= nil, problem or MM.helpFor("connect") } })
end

function ZeD_MMSrvForm:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMSrvForm:joyB() self:cancel() end
function ZeD_MMSrvForm:keyEscape()
    for _, e in ipairs(self._fields) do if e:isFocused() then e:unfocus(); return true end end
    self:cancel()
    return true
end
function ZeD_MMSrvForm:keyOther(key)
    -- (the Return that finished a field must not also press Connect)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    for _, e in ipairs(self._fields) do if e:isFocused() then return false end end
    if key == Keyboard.KEY_RETURN then self:connect(); return true end
    return false
end
function ZeD_MMSrvForm:close() self:cancel() end
function ZeD_MMSrvForm:getFooterPrompts()
    if not MM.gamepad() then return nil end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } }
end

-- ============================================================================
-- the wheel scrolls the Workshop items' list (each screen chains its view onto MM.wheel)
local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "wsitems" and MM.root and MM.root.wsItemsWin then
        if MM.root.wsItemsWin:wheel(del) then return true end
    end
    return _wheel(del)
end

-- on the desk: each stays shown off the screen and its view mirrors it
MM.addView("wsitems", "wsItemsWin", function() return ZeD_MMWsItems:new() end, "serverWorkshopItem", MM.wsItemsKeep)
MM.addView("bootstrap", "bootstrapWin", function() return ZeD_MMBootstrap:new() end, "bootstrapConnectPopup", true)
MM.addView("srvform", "srvFormWin", function() return ZeD_MMSrvForm:new() end, "serverConnectPopup", true)
