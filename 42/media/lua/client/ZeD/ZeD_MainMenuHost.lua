-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuHost.lua
-- ============================================================================
-- HOST A GAME ON THE MONITOR (HOOK_MAP row 26; director, Oct 14 2026: menus
-- delegated, no mockups)
--
-- Vanilla's CoopOptionsScreen launches a co-op server and follows it only
-- while it is visible, so it stays shown but off the screen (MM.mirror) and
-- this window drives it: its account name (outside Steam), the server
-- settings to host with (EDIT SETTINGS... opens vanilla's settings editor;
-- its BACK returns here), the memory to give the server, the world's upkeep
-- (reset, delete the world, delete the player: each asks in the strip), and
-- START / ABORT. While the server starts: vanilla's status line and its
-- progress as a segmented bar.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "OptionScreens/CoopOptionsScreen"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local LABEL_W, ROW_H, BOX_W = 170, 40, 300

local function ms() return MainScreen and MainScreen.instance end
local function coop() local m = ms(); return m and m.onlineCoopScreen end
local function s(v) if v == nil then return "" end; return tostring(v) end
local function comboText(c, i) local ok, t = pcall(function() return c:getOptionText(i) end); return ok and tostring(t or "") or "" end
-- vanilla's translated text can carry a backslash and an n for a line break: real breaks
local function unescape(t)
    local out, i = {}, 1
    while true do
        local a, b = t:find("\\n", i, true)
        if not a then out[#out + 1] = t:sub(i); break end
        out[#out + 1] = t:sub(i, a - 1)
        i = b + 1
    end
    return table.concat(out, "\n")
end

ZeD_MMHost = ZeD_MMWindow:derive("ZeD_MMHost")

function ZeD_MMHost:new()
    local o = ZeD_MMWindow.new(self, "host")
    o.noResetControl = true
    o.confirm = false     -- false | "reset" | "deleteWorld" | "deletePlayer"
    return o
end

function ZeD_MMHost:createChildren()
    ZeD_Window.createChildren(self)
    self.account = UI.newEntry(self)
    self.account:setVisible(false)
    self.account.onCommandEntered = function() self._enterAt = MM.now(); self.account:unfocus() end
    self.account.onTextChange = function() local c = coop(); if c then c.accountNameEntry:setText(self.account:getText() or ""); c.checkPlayer = true end end
end

function ZeD_MMHost:onShow()
    local c = coop()
    self.confirm = false
    self.focusId = nil
    if c then self.account:setText(s(c.accountNameEntry:getText())) end
end

function ZeD_MMHost:idle()
    local c = coop()
    return c ~= nil and c.uiStatus == "idle"
end

-- ACTIONS (vanilla's own) -------------------------------------------------------------
function ZeD_MMHost:back()
    local c = coop()
    MM.clickSound()
    if not c then MM.showView("main"); return end
    if not self:idle() then return end
    c:onBackButtonDown()
end

function ZeD_MMHost:start()
    local c = coop()
    if not c or not self:idle() or self:problem() then return end
    MM.clickSound()
    c:onStartButtonDown()
end

function ZeD_MMHost:abort()
    local c = coop()
    if not c then return end
    MM.clickSound()
    c:onAbortButtonDown()
end

-- MANAGE SETTINGS...: vanilla's editor, on the monitor as the server settings window
-- (ZeD_MainMenuServer.lua); its BACK shows the host screen again, landing here
function ZeD_MMHost:editSettings()
    local c = coop()
    if not c then return end
    MM.clickSound()
    c:onEditSettings()
end

function ZeD_MMHost:answer(yes)
    local c = coop()
    local mode = self.confirm
    self:setConfirm(false)
    if not yes or not c then return end
    if mode == "reset" then c:onSoftResetStep2({ internal = "YES" }, nil)
    elseif mode == "deleteWorld" then c:onDeleteWorldStep2({ internal = "YES" }, nil)
    elseif mode == "deletePlayer" then c:onDeletePlayerStep2({ internal = "YES" }, nil) end
end

function ZeD_MMHost:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.ctx.open = nil
    self.focusId = mode and "confirm:yes" or nil
    MM.clickSound()
end

-- what keeps START from going: the account name (outside Steam), the server's name, the saved world
function ZeD_MMHost:problem()
    local c = coop()
    if not c then return nil end
    if not getSteamModeActive() and not isValidUserName(s(c.accountNameEntry:getText())) then return "That account name will not do." end
    local err = checkServerName(s(CoopConnection.servername))
    if err then return UI.plain(err) end
    if c.richText and c.richText:isVisible() and c.richText.text then return UI.plain(c.richText.text) end
    return nil
end

function ZeD_MMHost:openCombo(c, anchor)
    local items = {}
    for i = 1, #(c.options or {}) do
        local t = comboText(c, i)
        if i == c.selected then t = t .. "  " .. string.char(171) end
        items[#items + 1] = { text = t, fn = function()
            c.selected = i
            if c.onChange then c.onChange(c.target, c, c.onChangeArgs and c.onChangeArgs[1], c.onChangeArgs and c.onChangeArgs[2]) end
        end }
    end
    MM.openPopup("host", items, anchor, false)
    MM.ctx.dropFocus = c.selected or 1
    MM.ctx.dropScroll = math.max(0, ((c.selected or 1) - 4) * ZeD.T.px(26))
end

-- ============================================================================
-- DRAWING
-- ============================================================================
function ZeD_MMHost:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local c = coop()
    self.title = "Project Zomboid  +  Host a Game"
    self.titleStats = {}
    ZeD_Window.prerender(self)
    if not c then return end
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, bx, by, bw, bh)
    local ix = bx + T.px(24)
    local cy = by + T.px(20)
    local f1, f2 = T.fontF1, T.fontF2
    local rowH = T.px(ROW_H)
    local vx = ix + T.px(LABEL_W)
    local boxW = math.min(T.px(BOX_W), bx + bw - T.px(24) - vx)
    local idle = self:idle()
    local gp = MM.gamepad()
    local ac = T.accent
    local function label(text, ry)
        local la = T.accent
        self:drawText(text, ix, ry + math.floor((rowH - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
    end
    local function box(id, ry, combo)
        local bh2 = T.px(24)
        local yy = ry + math.floor((rowH - bh2) / 2)
        local hid = "host:" .. id
        local sf = (MM.ctx.hot == hid) and T.surf3 or T.surf2
        local bs, tc = T.borderS, T.text
        if gp and self.focusId == id then self:drawRect(vx - T.px(4), yy - T.px(4), boxW + T.px(8), bh2 + T.px(8), 0.55, ac.r, ac.g, ac.b) end
        self:drawRect(vx, yy, boxW, bh2, 1, sf.r, sf.g, sf.b)
        self:drawRectBorder(vx, yy, boxW, bh2, bs.a, bs.r, bs.g, bs.b)
        self:drawText(ZeD.Atoms.truncateText(comboText(combo, combo.selected), f2, boxW - T.px(28)), vx + T.px(8), yy + math.floor((bh2 - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        ZeD.Atoms.drawTriangleDown(self, vx + boxW - T.px(16), yy + math.floor((bh2 - T.px(5)) / 2), T.px(8), T.textDim)
        local anchor = { x = ax + vx, y = ay + yy, w = boxW, h = bh2 }
        local fn = function() self:openCombo(combo, anchor) end
        if idle then self._hits[#self._hits + 1] = { id = hid, x = anchor.x, y = anchor.y, w = boxW, h = bh2, fn = fn, sound = true } end
        self._specs[#self._specs + 1] = { id = id, listRow = true, row = 10 + #self._specs, col = 1, fn = fn, x = vx, y = yy, w = boxW, h = bh2 }
    end
    local function button(id, text, ry, fn, disabled)
        local bh2 = T.px(U.STRIP_BTN_H)
        local b = { id = id, text = text, x = vx, y = ry + math.floor((rowH - bh2) / 2), w = MM.textW(T.fontF3, text) + T.px(U.STRIP_BTN_PAD) * 2, h = bh2,
                    fn = fn, variant = "default", disabled = disabled or not idle, row = 10 + #self._specs, col = 1 }
        self._specs[#self._specs + 1] = b
    end

    if idle then
        -- the account (its own name outside Steam; Steam hosts as the Steam user)
        label("ACCOUNT", cy)
        if getSteamModeActive() then
            local tc = T.text
            self:drawText(s(getCurrentUserProfileName()), vx, cy + math.floor((rowH - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            if self.account:isVisible() then self.account:setVisible(false) end
        else
            UI.styleEntry(self.account, vx, cy + math.floor((rowH - T.px(24)) / 2), boxW, T.px(24))
            if not self.account:isVisible() then self.account:setVisible(true) end
            self._hits[#self._hits + 1] = { id = "host:account", x = ax + vx, y = ay + self.account.y, w = boxW, h = T.px(24), fn = function() self.account:focus() end }
        end
        cy = cy + rowH
        label("SERVER SETTINGS", cy)
        box("settings", cy, c.settingsComboBox)
        cy = cy + rowH
        button("edit", string.upper(UI.plain(getText("UI_coopscreen_edit_settings"))), cy, function() self:editSettings() end)
        cy = cy + rowH
        label("MEMORY", cy)
        box("memory", cy, c.memoryComboBox)
        cy = cy + rowH + T.px(10)
        -- the world's upkeep
        self:drawRect(ix, cy, bx + bw - T.px(24) - ix, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
        cy = cy + T.px(12)
        label("THE WORLD", cy)
        local wx = vx
        for _, a in ipairs({
            { "reset", string.upper(UI.plain(getText("UI_coopscreen_softreset"))), function() self:setConfirm("reset") end, not c.softResetButton.enable },
            { "delWorld", string.upper(UI.plain(getText("UI_coopscreen_delete_world"))), function() self:setConfirm("deleteWorld") end, not c.deleteWorldButton.enable },
            { "delPlayer", string.upper(UI.plain(getText("UI_coopscreen_delete_player"))), function() self:setConfirm("deletePlayer") end, not c.deletePlayerButton.enable } }) do
            local bh2 = T.px(U.STRIP_BTN_H)
            local bw2 = MM.textW(T.fontF3, a[2]) + T.px(U.STRIP_BTN_PAD) * 2
            if wx + bw2 > bx + bw - T.px(24) then wx = vx; cy = cy + bh2 + T.px(8) end
            self._specs[#self._specs + 1] = { id = a[1], text = a[2], x = wx, y = cy + math.floor((rowH - bh2) / 2), w = bw2, h = bh2, fn = a[3],
                                              variant = "default", disabled = a[4], row = 40, col = #self._specs }
            wx = wx + bw2 + T.px(8)
        end
        cy = cy + rowH
        -- a world question: vanilla's whole explanation (what a soft reset keeps and clears, the
        -- folders a delete removes, the character), the short question in the strip
        if self.confirm then
            local text
            if self.confirm == "reset" then text = getText("UI_coopscreen_softreset_prompt", getAbsoluteSaveFolderName(c:getServerSaveFolder()))
            elseif self.confirm == "deleteWorld" then
                local folder = getAbsoluteSaveFolderName(c:getServerSaveFolder())
                text = getText("UI_coopscreen_delete_world_prompt", folder, folder .. "_player")
            else text = getText("UI_coopscreen_delete_player_prompt", s(c.accountNameEntry:getText())) end
            text = unescape(s(text))
            cy = cy + T.px(8)
            local tc = T.text
            for line in (text .. "\n"):gmatch("([^\n]*)\n") do
                if line == "" then cy = cy + T.px(6) end
                for _, l in ipairs(ZeD.Atoms.wrapText(UI.plain(line), f2, bx + bw - T.px(24) - ix)) do
                    if cy + MM.fontH(f2) > by + bh - T.px(8) then break end
                    self:drawText(l, ix, cy, tc.r, tc.g, tc.b, tc.a or 1, f2)
                    cy = cy + MM.fontH(f2) + T.px(3)
                end
            end
        end
        -- what keeps START from going
        local why = self:problem()
        if why then
            cy = cy + T.px(8)
            local dsz = T.px(7)
            local tc = T.text
            local lines = ZeD.Atoms.wrapText(why, f2, bx + bw - T.px(24) - ix - dsz - T.px(8))
            for i, l in ipairs(lines) do
                if i == 1 then ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.danger, dsz) end
                self:drawText(l, ix + dsz + T.px(8), cy, tc.r, tc.g, tc.b, tc.a or 1, f2)
                cy = cy + MM.fontH(f2) + T.px(3)
            end
        end
    else
        if self.account:isVisible() then if self.account:isFocused() then self.account:unfocus() end; self.account:setVisible(false) end
        -- starting: vanilla's status line and its progress as a segmented bar
        local hf = ZeD.Font.sdf.head
        local z = 20 * (T.scale or 1) / (hf.face or 64)
        local tc = T.textHead
        ZeD.Text.draw(self, hf, s(CoopConnection.servername), ix, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
        cy = cy + math.floor(ZeD.Text.height(hf, z)) + T.px(16)
        local dsz = T.px(9)
        local blink = math.floor(MM.now() / 450) % 2 == 0
        if blink then ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.accent, dsz) end
        local t2 = T.text
        for _, l in ipairs(ZeD.Atoms.wrapText(UI.plain(s(c.serverStatus)), f2, bw - T.px(60))) do
            self:drawText(l, ix + dsz + T.px(10), cy, t2.r, t2.g, t2.b, t2.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(3)
        end
        cy = cy + T.px(12)
        local barW = bw - T.px(48)
        local prog = math.max(0, math.min(1, tonumber(c.progress) or 0))
        local n = 30
        ZeD.Atoms.drawSegBar(self, ix, cy, barW, T.px(14), n, math.floor(prog * n + 0.5), T.accent, T.surf3, T.px(2))
        cy = cy + T.px(28)
        if c.softresetProgress then
            local la = T.accent
            self:drawText("RESETTING", ix, cy, la.r, la.g, la.b, la.a or 1, f1)
            cy = cy + T.px(18)
            ZeD.Atoms.drawSegBar(self, ix, cy, barW, T.px(14), n, math.floor(c.softresetProgress * n + 0.5), T.accent, T.surf3, T.px(2))
        end
    end
    self:buildStrip(stripY, stripH, w)
end

function ZeD_MMHost:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask)
    ZeD_Window.render(self)
end

function ZeD_MMHost:buildStrip(stripY, stripH, w)
    local c = coop()
    local row = 1000
    local ask = nil
    if self.confirm == "reset" then
        ask = "Soft-reset the server?"
        UI.stripSpecs(self, stripY, w, row, {}, { { "confirm:no", "CANCEL", function() self:answer(false) end }, { "confirm:yes", "RESET", function() self:answer(true) end, "danger" } })
    elseif self.confirm == "deleteWorld" then
        ask = "Delete the world? It cannot be undone."
        UI.stripSpecs(self, stripY, w, row, {}, { { "confirm:no", "CANCEL", function() self:answer(false) end }, { "confirm:yes", "DELETE", function() self:answer(true) end, "danger" } })
    elseif self.confirm == "deletePlayer" then
        ask = "Delete this character from the server?"
        UI.stripSpecs(self, stripY, w, row, {}, { { "confirm:no", "CANCEL", function() self:answer(false) end }, { "confirm:yes", "DELETE", function() self:answer(true) end, "danger" } })
    else
        local idle = self:idle()
        local rights = {}
        if not idle then rights[#rights + 1] = { "abort", "ABORT", function() self:abort() end, "danger", not (c and c.abortButton.enable) } end
        rights[#rights + 1] = { "start", string.upper(UI.plain(getText("UI_coopscreen_btn_start"))), function() self:start() end, "primary", (not idle) or self:problem() ~= nil }
        UI.stripSpecs(self, stripY, w, row, { { "back", "BACK", function() self:back() end, "default", not idle } }, rights)
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- CONTROLLER + KEYS -----------------------------------------------------------------------
function ZeD_MMHost:joyB()
    if self.confirm then self:answer(false); return end
    self:back()
end
function ZeD_MMHost:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = "Select" }, { glyph = "B", label = "Cancel" } } end
    return { { glyph = "A", label = "Select" }, { glyph = "B", label = "Back" } }
end
function ZeD_MMHost:keyEscape()
    if self.confirm then self:answer(false); return true end
    if self.account:isFocused() then self.account:unfocus(); return true end
    self:back()
    return true
end
function ZeD_MMHost:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self.account:isFocused() or self.confirm then return false end
    if key == Keyboard.KEY_RETURN then self:start(); return true end
    return false
end
function ZeD_MMHost:close() self:back() end

-- on the desk: vanilla's host screen stays shown off the screen (it follows its server only
-- while visible) and "host" mirrors it
MM.addView("host", "hostWin", function() return ZeD_MMHost:new() end, "onlineCoopScreen", true)
