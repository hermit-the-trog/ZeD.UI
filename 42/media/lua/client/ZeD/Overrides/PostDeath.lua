-- ZeD-UI/42/media/lua/client/ZeD/Overrides/PostDeath.lua
-- ============================================================================
-- AFTER DEATH (HOOK_MAP row 19; mockup zed_fish_sleep_death_v5, director Oct
-- 16 2026: "I like the stop one, but with the grave stone icon. Shut down,
-- let's just leave it as are you sure?")
--
-- Vanilla's ISPostDeathUI stays the host: vanilla makes it on death, keeps it
-- in ISPostDeathUI.instance (the respawn screen removes it, or shows it again
-- on Cancel), waits its three seconds, and its own handlers do the work
-- (onRespawn, onExit, onConfirmQuitToDesktop). What it draws is ZeD's: a
-- System 7 Stop alert with a gravestone. "Glen Finnegan died." and when; the
-- record in a System 7 list (vanilla's own lines: how long, zombies killed,
-- the game mode; then kills by kind, the best skills, the last line of the
-- log); Shut down | Main menu | Restart (the default, outlined). Shut down
-- asks "Are you sure?" in the same alert. Vanilla's rules stay: Restart only
-- when the game allows a respawn (greyed in the challenge mode), Main menu
-- and Shut down only when every player on this screen is dead.
-- Controller: A Restart, X Main menu, B Shut down (vanilla's own mapping);
-- asking, A Shut down, B Cancel. Return presses the default.
-- While ZeD's safe mode is on, the screen is vanilla's again: its three
-- buttons (built the first time they are needed), its size and place, its
-- scrolling lines and its controller mapping. It turns back into the alert
-- when safe mode goes off.
-- ============================================================================

require "ISUI/ISPostDeathUI"
require "ZeD/SafeMode"
require "ZeD/Tr"

if not ISPostDeathUI then return end

ZeD = ZeD or {}
ZeD.Death = ZeD.Death or { records = {} }
local D = ZeD.Death

-- vanilla's methods, kept once (a Lua reload of this file must not keep ZeD's as "vanilla")
ISPostDeathUI._zedOrig = ISPostDeathUI._zedOrig or {
    createChildren           = ISPostDeathUI.createChildren,
    prerender                = ISPostDeathUI.prerender,
    render                   = ISPostDeathUI.render,
    onMouseDown              = ISPostDeathUI.onMouseDown,
    onMouseUp                = ISPostDeathUI.onMouseUp,
    onMouseUpOutside         = ISPostDeathUI.onMouseUpOutside,   -- ISPanelJoypad's (inherited)
    onMouseMove              = ISPostDeathUI.onMouseMove,
    onMouseWheel             = ISPostDeathUI.onMouseWheel,
    onGainJoypadFocus        = ISPostDeathUI.onGainJoypadFocus,
    onJoypadBeforeDeactivate = ISPostDeathUI.onJoypadBeforeDeactivate,
    onJoypadReactivate       = ISPostDeathUI.onJoypadReactivate,
    onJoypadDown             = ISPostDeathUI.onJoypadDown,       -- ISPanelJoypad's (inherited)
    onJoypadDirUp            = ISPostDeathUI.onJoypadDirUp,      -- ISPanelJoypad's (inherited)
    onJoypadDirDown          = ISPostDeathUI.onJoypadDirDown,    -- ISPanelJoypad's (inherited)
}
local O = ISPostDeathUI._zedOrig

-- The screen handed to vanilla: its buttons built (ZeD's alert builds none) or
-- shown again, its size and place vanilla's, the controller on its buttons.
local function toVanilla(self)
    self._asking, self._down, self._hits, self._listRect = false, nil, {}, nil
    if not self.buttonRespawn then
        O.createChildren(self)   -- (builds, sizes and places them)
    else
        local w, h = self.buttonRespawn:getWidth(), self.buttonQuit:getBottom()
        self:setWidth(w); self:setHeight(h)
        self:setX(self.screenX + (self.screenWidth - w) / 2)
        self:setY(self.screenY + (self.screenHeight - 40 - h))
    end
    self._zedVanilla = true
    if self.joyfocus and O.onGainJoypadFocus then O.onGainJoypadFocus(self, self.joyfocus) end
end

-- ...and taken back: vanilla's buttons hidden and off the controller
local function toZeD(self)
    self._zedVanilla = nil
    if self.buttonQuit and O.onJoypadBeforeDeactivate then pcall(O.onJoypadBeforeDeactivate, self, self.joyfocus) end
    if self.buttonRespawn then self.buttonRespawn:setVisible(false) end
    if self.buttonExit then self.buttonExit:setVisible(false) end
    if self.buttonQuit then self.buttonQuit:setVisible(false) end
end

-- true while safe mode holds: this screen is vanilla's (switched over the first time it is asked)
local function vanilla(self)
    if ZeD.Safe.on() then
        if not self._zedVanilla then
            local ok, err = pcall(toVanilla, self)
            if not ok then self._zedVanilla = true; print("[ZeD] death screen: could not hand back to vanilla: " .. tostring(err)) end
        end
        return true
    end
    if self._zedVanilla then toZeD(self) end
    return false
end

-- (the month names are vanilla's: Farming_Month_1 .. Farming_Month_12)
local BLACK, WHITE, GREY = { r = 0, g = 0, b = 0 }, { r = 1, g = 1, b = 1 }, { r = 0.6, g = 0.6, b = 0.6 }

-- ---------------------------------------------------------------------------
-- THE RECORD, taken the moment the character dies
-- ---------------------------------------------------------------------------
local function bestSkills(p)
    local out = {}
    pcall(function()
        for i = 0, PerkFactory.PerkList:size() - 1 do
            local perk = PerkFactory.PerkList:get(i)
            if perk:getParent() ~= Perks.None then
                local lv = p:getPerkLevel(perk:getType())
                if lv > 0 then out[#out + 1] = { name = perk:getName(), lv = lv } end
            end
        end
    end)
    table.sort(out, function(a, b) if a.lv ~= b.lv then return a.lv > b.lv end return a.name < b.name end)
    local parts = {}
    for i = 1, math.min(4, #out) do parts[#parts + 1] = out[i].name .. " " .. out[i].lv end
    return table.concat(parts, " | ")
end

local function killsLine(p)
    local ok, data = pcall(function() return ZeD.JournalTab and ZeD.JournalTab.gatherData(p) end)
    if not (ok and data) then return "" end
    local parts = {}
    for _, c in ipairs(data.weaponCats or {}) do
        if (c.count or 0) > 0 then parts[#parts + 1] = { c.label, c.count } end
    end
    if (data.fireKills or 0) > 0 then parts[#parts + 1] = { ZeD.tr("UI_ZeD_Death_KillFire"), data.fireKills } end
    if (data.carKills or 0) > 0 then parts[#parts + 1] = { ZeD.tr("UI_ZeD_Death_KillVehicle"), data.carKills } end
    if (data.explosionKills or 0) > 0 then parts[#parts + 1] = { ZeD.tr("UI_ZeD_Death_KillExplosion"), data.explosionKills } end
    table.sort(parts, function(a, b) return a[2] > b[2] end)
    local s = {}
    for _, x in ipairs(parts) do s[#s + 1] = x[1] .. " " .. x[2] end
    return table.concat(s, " | ")
end

function D.capture(playerObj)
    local pn = playerObj:getPlayerNum()
    local rec = {}
    local who = playerObj:getDescriptor()
    rec.name = who and (who:getForename() .. " " .. who:getSurname()) or ZeD.tr("IGUI_WarManager_You")
    local gt = getGameTime()
    rec.when = ZeD.tr("UI_ZeD_Death_When", ZeD.tr("Farming_Month_" .. (gt:getMonth() + 1)), gt:getDay() + 1, gt:getYear(),
        string.format("%02d:%02d", gt:getHour(), math.floor((gt:getTimeOfDay() % 1) * 60)))
    rec.lines = {}
    pcall(function() rec.lines[#rec.lines + 1] = gt:getDeathString(playerObj) end)
    pcall(function() local s = gt:getZombieKilledText(playerObj); if s then rec.lines[#rec.lines + 1] = s end end)
    pcall(function() local s = gt:getGameModeText(); if s then rec.lines[#rec.lines + 1] = s end end)
    rec.kills = killsLine(playerObj)
    rec.skills = bestSkills(playerObj)
    local md = playerObj:getModData()
    local e = md and md.ZeD_Journal and md.ZeD_Journal.entries and md.ZeD_Journal.entries[1]
    rec.last = e and e.text or nil
    D.records[pn] = rec
end
Events.OnPlayerDeath.Add(function(playerObj) pcall(D.capture, playerObj) end)

-- ---------------------------------------------------------------------------
-- THE GRAVESTONE: a 32 x 32, 1-bit System 7 icon (mockup v5), as runs of black
-- ---------------------------------------------------------------------------
local GRAVE = nil
local RIP = {
    { "110", "101", "110", "101", "101" },   -- R
    { "111", "010", "010", "010", "111" },   -- I
    { "110", "101", "110", "100", "100" },   -- P
}
local function buildGrave()
    local px = {}
    local function set(x, y, v) if x >= 0 and x < 32 and y >= 0 and y < 32 then px[y * 32 + x] = v end end
    for y = 0, 31 do for x = 0, 31 do
        local dx, dy = x - 15.5, y - 11
        local inTop = y <= 11 and dx * dx + dy * dy <= 81
        local inBody = y > 11 and y <= 27 and x >= 7 and x <= 24
        if inTop or inBody then
            local edge = (y <= 11 and dx * dx + dy * dy > 64) or (y > 11 and (x == 7 or x == 24))
            set(x, y, edge and 1 or 0)
        end
    end end
    for y = 6, 27 do set(23, y, 1) end
    for y = 5, 10 do set(15, y, 1) end
    for x = 13, 17 do set(x, 7, 1) end
    local gx = 10
    for _, g in ipairs(RIP) do
        for j, row in ipairs(g) do for i = 1, #row do if row:sub(i, i) == "1" then set(gx + i - 1, 14 + j - 1, 1) end end end
        gx = gx + #g[1] + 1
    end
    for x = 10, 20 do set(x, 21, 1) end
    for x = 11, 19 do set(x, 24, 1) end
    for x = 2, 29 do set(x, 28, 1) end
    for _, t in ipairs({ { 4, 27 }, { 5, 26 }, { 6, 27 }, { 25, 27 }, { 26, 26 }, { 27, 27 }, { 10, 27 }, { 21, 27 } }) do set(t[1], t[2], 1) end
    for x = 3, 5 do set(x, 30, 1) end
    for x = 12, 15 do set(x, 30, 1) end
    for x = 22, 26 do set(x, 30, 1) end
    -- rows of runs: { y, x0, len, black }
    local runs = {}
    for y = 0, 31 do
        local x = 0
        while x < 32 do
            local v = px[y * 32 + x]
            if v == nil then x = x + 1 else
                local x0 = x
                while x < 32 and px[y * 32 + x] == v do x = x + 1 end
                runs[#runs + 1] = { y, x0, x - x0, v == 1 }
            end
        end
    end
    GRAVE = runs
end

local function drawGrave(self, x, y, k)
    if not GRAVE then buildGrave() end
    for _, r in ipairs(GRAVE) do
        local c = r[4] and BLACK or WHITE
        self:drawRect(x + r[2] * k, y + r[1] * k, r[3] * k, k, 1, c.r, c.g, c.b)
    end
end

-- ---------------------------------------------------------------------------
-- DRAWING (black on white, the System 7 alert; design units through T.px)
-- ---------------------------------------------------------------------------
local U = { W = 600, PAD = 18, ICON = 64, GAP = 16, LIST_MAX = 210, BTN_H = 22, BTN_MIN = 80, BTN_GAP = 12, ASK_W = 420 }

local function fh(f) return ZeD.TM:getFontHeight(f) end
local function tw(f, s) return ZeD.TM:MeasureStringX(f, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end

-- A rectangle's outline, t thick, drawn as four rects. (drawRectBorder is one screen pixel
-- whatever the scale, so rings spaced by T.px(1) left gaps between them at 1.5x and up.)
local function ring(p, x, y, w, h, t, c)
    p:drawRect(x, y, w, t, 1, c.r, c.g, c.b)
    p:drawRect(x, y + h - t, w, t, 1, c.r, c.g, c.b)
    p:drawRect(x, y + t, t, h - 2 * t, 1, c.r, c.g, c.b)
    p:drawRect(x + w - t, y + t, t, h - 2 * t, 1, c.r, c.g, c.b)
end

-- a System 7 push button: a rounded 1 px outline (corners cut), the default one ringed
function ISPostDeathUI:zedButton(id, x, y, w, h, label, isDefault, enabled, fn)
    local T = ZeD.T
    local one = math.max(1, T.px(1))
    local hot = enabled and inRect({ x = x, y = y, w = w, h = h }, self:getMouseX(), self:getMouseY())
    local down = hot and self._down == id
    local focus = enabled and self._joyFocusId == id
    local fill = down and BLACK or WHITE
    self:drawRect(x + one * 2, y, w - one * 4, h, 1, fill.r, fill.g, fill.b)
    self:drawRect(x, y + one * 2, w, h - one * 4, 1, fill.r, fill.g, fill.b)
    self:drawRect(x + one, y + one, w - one * 2, h - one * 2, 1, fill.r, fill.g, fill.b)
    if hot and not down then local ac = T.accent; self:drawRect(x + one, y + one, w - one * 2, h - one * 2, 0.22, ac.r, ac.g, ac.b) end
    if focus then local ac = T.accent; self:drawRect(x + one, y + one, w - one * 2, h - one * 2, 0.55, ac.r, ac.g, ac.b) end
    local bc = enabled and BLACK or GREY
    self:drawRect(x + one * 2, y, w - one * 4, one, 1, bc.r, bc.g, bc.b)
    self:drawRect(x + one * 2, y + h - one, w - one * 4, one, 1, bc.r, bc.g, bc.b)
    self:drawRect(x, y + one * 2, one, h - one * 4, 1, bc.r, bc.g, bc.b)
    self:drawRect(x + w - one, y + one * 2, one, h - one * 4, 1, bc.r, bc.g, bc.b)
    self:drawRect(x + one, y + one, one, one, 1, bc.r, bc.g, bc.b)
    self:drawRect(x + w - one * 2, y + one, one, one, 1, bc.r, bc.g, bc.b)
    self:drawRect(x + one, y + h - one * 2, one, one, 1, bc.r, bc.g, bc.b)
    self:drawRect(x + w - one * 2, y + h - one * 2, one, one, 1, bc.r, bc.g, bc.b)
    if isDefault and enabled then
        -- the default button's heavy ring, a little out from the button
        local o, th = one * 3, one * 3
        self:drawRect(x - o + one * 2, y - o, w + o * 2 - one * 4, th, 1, 0, 0, 0)
        self:drawRect(x - o + one * 2, y + h + o - th, w + o * 2 - one * 4, th, 1, 0, 0, 0)
        self:drawRect(x - o, y - o + one * 2, th, h + o * 2 - one * 4, 1, 0, 0, 0)
        self:drawRect(x + w + o - th, y - o + one * 2, th, h + o * 2 - one * 4, 1, 0, 0, 0)
        self:drawRect(x - o + one, y - o + one, th, th, 1, 0, 0, 0)
        self:drawRect(x + w + o - th - one, y - o + one, th, th, 1, 0, 0, 0)
        self:drawRect(x - o + one, y + h + o - th - one, th, th, 1, 0, 0, 0)
        self:drawRect(x + w + o - th - one, y + h + o - th - one, th, th, 1, 0, 0, 0)
    end
    local f = T.fontF2
    local tc = down and WHITE or (enabled and BLACK or GREY)
    self:drawText(label, x + math.floor((w - tw(f, label)) / 2), y + math.floor((h - fh(f)) / 2), tc.r, tc.g, tc.b, 1, f)
    self._hits[#self._hits + 1] = { id = id, x = x, y = y, w = w, h = h, fn = enabled and fn or nil }
end

-- the record's rows, wrapped to the list's width: { text, bold }
local function recordRows(rec, w, f2)
    local rows = {}
    local function add(text, bold)
        for _, l in ipairs(ZeD.Atoms.wrapText(text, f2, w)) do rows[#rows + 1] = { l, bold } end
    end
    for _, l in ipairs(rec.lines or {}) do add(l, false) end
    if rec.kills and rec.kills ~= "" then add(ZeD.tr("UI_ZeD_Death_Kills"), true); add(rec.kills, false) end
    if rec.skills and rec.skills ~= "" then add(ZeD.tr("UI_ZeD_Death_BestSkills"), true); add(rec.skills, false) end
    if rec.last and rec.last ~= "" then add(ZeD.tr("UI_ZeD_Death_LastLine"), true); add(rec.last, false) end
    return rows
end

-- the state of vanilla's rules this frame
function ISPostDeathUI:zedRules()
    local allDead = IsoPlayer.allPlayersDead()
    local allowRespawn = getCore():getGameMode() ~= "Tutorial"
    if isClient() and getServerOptions():getBoolean("DropOffWhiteListAfterDeath") then allowRespawn = false end
    local challenge = getCore():getGameMode() == "A Really CD DA"
    return { quit = allDead, exit = allDead, respawn = allowRespawn, respawnEnabled = allowRespawn and not challenge }
end

function ISPostDeathUI:zedRestart() if self:zedRules().respawnEnabled then self:onRespawn() end end
function ISPostDeathUI:zedMenu() if self:zedRules().exit then self:onExit() end end
function ISPostDeathUI:zedAsk() if self:zedRules().quit then self._asking = true; self._joyFocusId = nil end end
function ISPostDeathUI:zedCancel() self._asking = false end
function ISPostDeathUI:zedShutDown() self._asking = false; self:onConfirmQuitToDesktop({ internal = "YES" }) end

-- ---------------------------------------------------------------------------
-- vanilla's panel, drawn by ZeD
-- ---------------------------------------------------------------------------
-- (no vanilla buttons: the alert draws its own; in safe mode, vanilla's)
function ISPostDeathUI:createChildren()
    if ZeD.Safe.on() then self._zedVanilla = true; return O.createChildren(self) end
end

function ISPostDeathUI:prerender()
    if vanilla(self) then return O.prerender(self) end
    ISPostDeathUI.instance[self.playerIndex] = self
    self.screenX, self.screenY = getPlayerScreenLeft(self.playerIndex), getPlayerScreenTop(self.playerIndex)
    self.screenWidth, self.screenHeight = getPlayerScreenWidth(self.playerIndex), getPlayerScreenHeight(self.playerIndex)
    if not self.waitOver then self.waitOver = getTimestamp() > (self.timeOfDeath or 0) + 3 end
    self._hits = {}
    if not self.waitOver or not ZeD.T then
        -- (vanilla's three seconds: nothing yet, and nothing to click)
        self:setWidth(1); self:setHeight(1)
        return
    end
    local T = ZeD.T
    local one = math.max(1, T.px(1))
    local pad = T.px(U.PAD)
    local f2, fHead = T.fontF2, T.fontF4
    local asking = self._asking
    local w = T.px(asking and U.ASK_W or U.W)
    local icon = T.px(U.ICON)
    local k = math.max(1, math.floor(icon / 32))
    icon = 32 * k
    local rec = D.records[self.playerIndex] or { name = ZeD.tr("IGUI_WarManager_You"), lines = self.lines or {} }
    -- measure: the head row, the list, the buttons
    local frameIn = one * 4 + one * 3          -- outer line, white gap, the heavy frame
    local innerW = w - frameIn * 2 - pad * 2
    local textX = icon + T.px(U.GAP)
    local headH = math.max(icon, fh(fHead) + (asking and 0 or (T.px(6) + fh(f2))))
    local rows = asking and {} or recordRows(rec, innerW - T.px(28), f2)
    local rowH = fh(f2) + T.px(3)
    local listH = asking and 0 or math.min(T.px(U.LIST_MAX), #rows * rowH + T.px(8))
    local btnH = T.px(U.BTN_H)
    local h = frameIn * 2 + pad + headH + (asking and 0 or (T.px(12) + listH)) + T.px(16) + btnH + pad
    self:setWidth(w); self:setHeight(h)
    self:setX(self.screenX + math.floor((self.screenWidth - w) / 2))
    self:setY(self.screenY + math.floor((self.screenHeight - h) * 0.42))
    -- the dim behind (the world stays seen)
    self:drawRect(self.screenX - self:getAbsoluteX(), self.screenY - self:getAbsoluteY(), self.screenWidth, self.screenHeight, 0.5, 0, 0, 0)
    -- the alert: a 1 px outline and its drop shadow, a white gap, the heavy frame
    self:drawRect(one * 2, one * 2, w, h, 1, 0, 0, 0)
    self:drawRect(0, 0, w, h, 1, 1, 1, 1)
    ring(self, 0, 0, w, h, one, BLACK)
    -- (the heavy frame: three rings, each as thick as the outline, so they meet whole at every scale)
    local fx = one * 4
    for i = 0, 2 do ring(self, fx + one * i, fx + one * i, w - (fx + one * i) * 2, h - (fx + one * i) * 2, one, BLACK) end
    local x0, y = frameIn + pad, frameIn + pad
    -- the icon and the words
    drawGrave(self, x0, y + math.floor((headH - icon) / 2), k)
    if asking then
        self:drawText(ZeD.tr("UI_ZeD_Death_AreYouSure"), x0 + textX, y + math.floor((headH - fh(fHead)) / 2), 0, 0, 0, 1, fHead)
    else
        local ty = y + math.floor((headH - (fh(fHead) + T.px(6) + fh(f2))) / 2)
        self:drawText(ZeD.tr("UI_ZeD_Death_Died", rec.name), x0 + textX, ty, 0, 0, 0, 1, fHead)
        if rec.when then self:drawText(rec.when, x0 + textX, ty + fh(fHead) + T.px(6), 0, 0, 0, 1, f2) end
    end
    y = y + headH
    -- the record in a System 7 list (the wheel scrolls it when it runs long)
    if not asking then
        y = y + T.px(12)
        local lx, lw = x0, innerW
        ring(self, lx, y, lw, listH, one, BLACK)
        local sbW = T.px(16)
        local total = #rows * rowH + T.px(8)
        local scrolls = total > listH
        local textW = lw - (scrolls and sbW or 0)
        self._listRect = { x = lx, y = y, w = lw, h = listH, max = math.max(0, total - listH) }
        self._listScroll = math.max(0, math.min(self._listScroll or 0, self._listRect.max))
        self:setStencilRect(lx + one, y + one, textW - one * 2, listH - one * 2)
        local ry = y + T.px(4) - self._listScroll
        for _, r in ipairs(rows) do
            self:drawText(r[1], lx + T.px(6), ry, 0, 0, 0, 1, f2)
            -- (a heading in bold: drawn again a pixel over)
            if r[2] then self:drawText(r[1], lx + T.px(6) + one, ry, 0, 0, 0, 1, f2) end
            ry = ry + rowH
        end
        self:clearStencilRect()
        if scrolls then
            local sx = lx + lw - sbW
            self:drawRect(sx, y, one, listH, 1, 0, 0, 0)
            self:drawRect(sx + one, y + one, sbW - one * 2, listH - one * 2, 1, 0.75, 0.75, 0.75)
            self:drawRect(sx, y + sbW, sbW, one, 1, 0, 0, 0)
            self:drawRect(sx, y + listH - sbW, sbW, one, 1, 0, 0, 0)
            self:drawRect(sx + one, y + one, sbW - one * 2, sbW - one, 1, 1, 1, 1)
            self:drawRect(sx + one, y + listH - sbW + one, sbW - one * 2, sbW - one * 2, 1, 1, 1, 1)
            local track = listH - sbW * 2
            local th = math.max(sbW, math.floor(track * listH / total))
            local tyy = y + sbW + math.floor((track - th) * (self._listScroll / math.max(1, self._listRect.max)))
            self:drawRect(sx + one, tyy, sbW - one * 2, th, 1, 1, 1, 1)
            ring(self, sx, tyy, sbW, th, one, BLACK)
        end
        y = y + listH
    end
    -- the buttons, right-aligned; the default last
    y = y + T.px(16)
    local rules = self:zedRules()
    local f = T.fontF2
    local function bw(label) return math.max(T.px(U.BTN_MIN), tw(f, label) + T.px(24)) end
    local right = x0 + innerW
    local gap = T.px(U.BTN_GAP)
    if asking then
        local shutDown, cancel = ZeD.tr("UI_ZeD_Death_ShutDown"), ZeD.tr("UI_Cancel")
        local b2 = bw(shutDown); local b1 = bw(cancel)
        self:zedButton("yes", right - b2, y, b2, btnH, shutDown, true, true, function() self:zedShutDown() end)
        self:zedButton("no", right - b2 - gap - b1, y, b1, btnH, cancel, false, true, function() self:zedCancel() end)
    else
        local labels = {}
        if rules.respawn then labels[#labels + 1] = { "restart", ZeD.tr("UI_ZeD_Death_Restart"), true, rules.respawnEnabled, function() self:zedRestart() end } end
        labels[#labels + 1] = { "menu", ZeD.tr("UI_ZeD_Death_MainMenu"), false, rules.exit, function() self:zedMenu() end }
        labels[#labels + 1] = { "quit", ZeD.tr("UI_ZeD_Death_ShutDown"), false, rules.quit, function() self:zedAsk() end }
        local x = right
        for _, b in ipairs(labels) do
            local wdt = bw(b[2])
            x = x - wdt
            self:zedButton(b[1], x, y, wdt, btnH, b[2], b[3] and rules.respawnEnabled, b[4], b[5])
            x = x - gap
        end
    end
end

function ISPostDeathUI:render()
    if vanilla(self) then return O.render(self) end
    -- (everything is drawn in prerender; vanilla's scrolling lines are not drawn)
end

local function hitAt(self, x, y)
    for i = #(self._hits or {}), 1, -1 do
        local h = self._hits[i]
        if inRect(h, x, y) then return h end
    end
    return nil
end

function ISPostDeathUI:onMouseDown(x, y)
    if vanilla(self) then return O.onMouseDown(self, x, y) end
    if not self.waitOver then return false end
    local h = hitAt(self, x, y)
    self._down = h and h.fn and h.id or nil
    return true
end

function ISPostDeathUI:onMouseUp(x, y)
    if vanilla(self) then return O.onMouseUp(self, x, y) end
    if not self.waitOver then return false end
    local down = self._down
    self._down = nil
    local h = hitAt(self, x, y)
    if h and h.fn and h.id == down then
        pcall(function() getSoundManager():playUISound("UIActivateButton") end)
        h.fn()
    end
    return true
end

function ISPostDeathUI:onMouseUpOutside(x, y)
    if vanilla(self) then if O.onMouseUpOutside then return O.onMouseUpOutside(self, x, y) end; return end
    self._down = nil
end
function ISPostDeathUI:onMouseMove(dx, dy)
    if vanilla(self) then return O.onMouseMove(self, dx, dy) end
    return self.waitOver and true or false
end

function ISPostDeathUI:onMouseWheel(del)
    if vanilla(self) then return O.onMouseWheel(self, del) end
    local r = self._listRect
    if r and inRect(r, self:getMouseX(), self:getMouseY()) then
        self._listScroll = math.max(0, math.min(r.max, (self._listScroll or 0) + del * ZeD.T.px(18)))
    end
    return true
end

-- the controller: vanilla's own mapping (A respawn, X exit, B quit); asking, A Shut down and B Cancel
function ISPostDeathUI:onGainJoypadFocus(joypadData)
    self.joyfocus = joypadData
    if vanilla(self) then return O.onGainJoypadFocus(self, joypadData) end
end
function ISPostDeathUI:onJoypadBeforeDeactivate(joypadData)
    if vanilla(self) then return O.onJoypadBeforeDeactivate(self, joypadData) end
end
function ISPostDeathUI:onJoypadReactivate(joypadData)
    if vanilla(self) then return O.onJoypadReactivate(self, joypadData) end
end
function ISPostDeathUI:onJoypadDown(button, joypadData)
    if vanilla(self) then if O.onJoypadDown then return O.onJoypadDown(self, button, joypadData) end; return end
    if not self.waitOver then return end
    if self._asking then
        if button == Joypad.AButton then self:zedShutDown() elseif button == Joypad.BButton then self:zedCancel() end
        return
    end
    if button == Joypad.AButton then self:zedRestart()
    elseif button == Joypad.XButton then self:zedMenu()
    elseif button == Joypad.BButton then self:zedAsk() end
end
function ISPostDeathUI:onJoypadDirUp(joypadData)
    if vanilla(self) then if O.onJoypadDirUp then return O.onJoypadDirUp(self, joypadData) end; return end
    if self._listRect then self._listScroll = math.max(0, (self._listScroll or 0) - ZeD.T.px(18)) end
end
function ISPostDeathUI:onJoypadDirDown(joypadData)
    if vanilla(self) then if O.onJoypadDirDown then return O.onJoypadDirDown(self, joypadData) end; return end
    if self._listRect then self._listScroll = math.min(self._listRect.max, (self._listScroll or 0) + ZeD.T.px(18)) end
end

-- Return presses the default (Restart; asking, Shut down); Escape answers no
-- (vanilla's screen has no keys: none in safe mode)
Events.OnKeyPressed.Add(function(key)
    if ZeD.Safe.on() then return end
    for _, ui in pairs(ISPostDeathUI.instance or {}) do
        if ui and ui.waitOver and ui:isReallyVisible() then
            if key == Keyboard.KEY_RETURN then
                if ui._asking then ui:zedShutDown() else ui:zedRestart() end
            elseif key == Keyboard.KEY_ESCAPE and ui._asking then
                ui:zedCancel()
            end
            return
        end
    end
end)

print("[ZeD] Overrides/PostDeath: the death screen is a ZeD System 7 alert")
