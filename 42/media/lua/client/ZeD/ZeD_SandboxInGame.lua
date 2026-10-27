-- ZeD-UI/42/media/lua/client/ZeD/ZeD_SandboxInGame.lua
-- ============================================================================
-- SANDBOX OPTIONS IN GAME (director, Oct 24 2026: "add our own midgame sandbox
-- settings option, default off, setting in the options menu ... show what does
-- what, what might have negative affects on a save and tips"; mockup
-- zed_sandbox_ingame_v1, approved: "pause window line, default off, single
-- player first"; HOOK_MAP "Sandbox options in game"; spec SANDBOX_INGAME_SPEC.md)
--
-- This save's sandbox settings, changed without starting over: the Options
-- window's layout over the paused game (pages, Find, rows, the action strip),
-- opened from the pause window's "Sandbox options" line, which shows only with
-- Options > ZeD setup > Sandbox switched on, and only in single player.
--
-- The pages and settings are vanilla's (ServerSettingsScreen's table, as its own
-- admin editor ISServerSandboxOptionsUI uses; other mods' settings come on their
-- own pages). Each row carries two tags (ZeD_SandboxNotes): WHEN a change takes
-- effect (now / new places / new characters / fixed, locked) and its RISK
-- (careful / can't undo): the library tag, an outline with a square mark for the
-- state. The help band has three parts: what it does (vanilla's tooltip), what
-- changing it does to this save, a tip.
--
-- Nothing changes until Apply, which asks first (the Changed page shows what).
-- Apply sets each changed option on the game's own SandboxOptions (the game
-- writes them into the save, map_sand.bin, when it next saves), pushes them to
-- SandboxVars (toLua), sets the day's length on the clock when Day Length
-- changed, and re-reads the loot tables as vanilla's admin editor does. Every
-- apply goes into History (global ModData, kept in the save), where each change
-- has its Undo changes. The questions are bands (Cancel and the answer; leaving
-- with changes asks Cancel, Discard changes and Apply).
-- ============================================================================

require "ZeD/ZeD_MainMenuSandbox"
require "ZeD/ZeD_SandboxNotes"
require "OptionScreens/ServerSettingsScreen"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local N  = ZeD.SandboxNotes

-- design units
local WIN_W, WIN_H = 1060, 860
local PAGES_W, FIND_H, PAGE_ROW_H = 210, 34, 30   -- (the Options window's)
local STRING_W = 420
local HIST_MAX = 60          -- applies kept in History (the oldest go first)
local NOTE_MS = 6000         -- how long "Applied ..." stays in the strip
local MD_KEY = "ZeD_SandboxHistory"

-- vanilla's linked numbers (ISServerSandboxOptionsUI): Zombie Count sets Population
-- Multiplier; Zombie Respawn sets the three respawn numbers; Migration the hours
local RESPAWN = { { "16.0", "6.0", "0.5" }, { "72.0", "16.0", "0.1" }, { "216.0", "48.0", "0.05" }, { "0.0", "0.0", "0.0" } }

local function so() return getSandboxOptions() end

-- a number or text setting's value lives in a plain holder (the window edits it in its row)
local function holder(text) return { text = text or "", getText = function(s) return s.text end, setText = function(s, t) s.text = tostring(t or "") end } end

-- vanilla's tooltip, plain, without its "Default = ..." and "Min: ..." lines (the band shows those)
local function tipText(t)
    if type(t) ~= "string" then return "" end
    t = t:gsub("\\n", "\n"):gsub("\\\"", "\"")
    local keep = {}
    for line in (t .. "\n"):gmatch("(.-)\n") do
        if not line:match("^%s*Default%s*=") and not line:match("^%s*Min:") then keep[#keep + 1] = line end
    end
    return UI.plain(table.concat(keep, " "))
end

local function sectionTitle(raw)
    return getTextOrNull("Sandbox_Title_" .. raw) or getTextOrNull("Sandbox_" .. raw) or tostring(raw)
end

-- "1 change" / "3 changes"
local function count(n) if n == 1 then return ZeD.tr("UI_ZeD_Sbx_Count1") end; return ZeD.tr("UI_ZeD_Sbx_CountN", tostring(n)) end

local function numText(v)
    if v == nil then return "" end
    if math.floor(v) == v then return string.format("%d", v) end
    return tostring(v)
end

-- ============================================================================
ZeD_MMSandboxIG = ZeD_MMSandbox:derive("ZeD_MMSandboxIG")

function ZeD_MMSandboxIG:new()
    local o = ZeD_MMSandbox.new(self)
    o.kind = "sandbox_ig"
    o.inGame = true
    o.ctls = {}           -- setting name -> its row
    o.base = {}           -- setting name -> the save's value when the window opened (or last applied)
    return o
end

function ZeD_MMSandboxIG:place()
    local T = ZeD.T
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local w = math.min(T.px(WIN_W), sw - T.px(40))
    local h = math.min(T.px(WIN_H), sh - T.px(40))
    local x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    return w, h
end

-- PAGES AND ROWS ------------------------------------------------------------------

function ZeD_MMSandboxIG:pages()
    if not self._pages then
        local t = {}
        local ok, tbl = pcall(ServerSettingsScreen.getSandboxSettingsTable)
        for _, p in ipairs(ok and tbl or {}) do t[#t + 1] = { title = tostring(p.name), raw = tostring(p.name), page = p } end
        t[#t + 1] = { title = "", raw = "~changed", virtual = "changed" }
        t[#t + 1] = { title = "", raw = "~history", virtual = "history" }
        self._pages = t
    end
    local n = #self._pages
    self._pages[n - 1].title = (self.nDiff or 0) > 0 and ZeD.tr("UI_ZeD_Sbx_PageChangedN", tostring(self.nDiff)) or ZeD.tr("UI_ZeD_Sbx_PageChanged")
    self._pages[n].title = ZeD.tr("UI_ZeD_Sbx_PageHistory")
    return self._pages
end

function ZeD_MMSandboxIG:makeRow(st, page, section)
    local opt = so():getOptionByName(st.name)
    if not opt then return nil end
    local c, kind
    if st.type == "checkbox" then
        c = ISTickBox:new(0, 0, 10, 10, "", self, ZeD_MMSandboxIG.onTick, st.name)
        c:initialise()
        c:addOption("")
        kind = "tick"
    elseif st.type == "enum" then
        c = ISComboBox:new(0, 0, 10, 10, self, ZeD_MMSandboxIG.onCombo, st.name)
        c:initialise()
        for _, v in ipairs(st.values or {}) do c:addOption(tostring(v)) end
        kind = "combo"
    else
        c = holder(opt:getValueAsString())
        kind = "entry"
    end
    local label = N.LABEL[st.name] and ZeD.tr(N.LABEL[st.name]) or tostring(st.translatedName or st.name)
    local r = { kind = kind, control = c, label = label, name = st.name, setting = st, section = section,
                pageTitle = page.title, tickNoText = true, wide = (st.type == "string" or st.type == "text") }
    self.ctls[st.name] = r
    return r
end

-- a vanilla page's rows (built once), the World page with the world's day on top
function ZeD_MMSandboxIG:rowsFor(page)
    if not page then return {} end
    if page.virtual == "changed" then return self:changedRows() end
    if page.virtual == "history" then return self:historyRows() end
    self._rows = self._rows or {}
    local rows = self._rows[page.raw]
    if not rows then
        rows = {}
        local section = nil
        for _, st in ipairs(page.page.settings or {}) do
            if st.title then section = st.title; rows[#rows + 1] = { kind = "header", text = sectionTitle(st.title) } end
            local r = self:makeRow(st, page, section)
            if r then rows[#rows + 1] = r end
        end
        self._rows[page.raw] = rows
        if self.ctls.WaterShutModifier and self.ctls.WaterShutModifier.pageTitle == page.title then page.world = true end
    end
    if page.world then
        local t = { { kind = "note", text = self:worldLine() } }
        for _, r in ipairs(rows) do t[#t + 1] = r end
        return t
    end
    return rows
end

-- every row of every vanilla page (built on first use)
function ZeD_MMSandboxIG:allRows()
    local out = {}
    for _, p in ipairs(self:pages()) do
        if not p.virtual then for _, r in ipairs(self:rowsFor(p)) do if r.name then out[#out + 1] = r end end end
    end
    return out
end

function ZeD_MMSandboxIG:changedRows()
    local out, last = {}, nil
    for _, p in ipairs(self:pages()) do
        if not p.virtual then
            for _, r in ipairs(self:rowsFor(p)) do
                if r.name and self.diff[r.name] then
                    if last ~= p then out[#out + 1] = { kind = "header", text = p.title }; last = p end
                    out[#out + 1] = r
                end
            end
        end
    end
    if #out == 0 then out[1] = { kind = "note", text = ZeD.tr("UI_ZeD_Sbx_ChangedNone") } end
    return out
end

-- "On for good" / "On until day N" / "Off since day N", from the value in the row. The game
-- keeps the supply on while the world's age is under the day: -1 is off from the start, the
-- largest number (2147483647, the game's Never) on for good.
function ZeD_MMSandboxIG:supplyText(name, day, keys)
    local r = self.ctls[name]
    local m = r and tonumber(self:rowValue(r))
    if not m then return "" end
    if m >= 2147483647 then return ZeD.tr(keys[1]) end
    if m > day then return ZeD.tr(keys[2], numText(m)) end
    return ZeD.tr(keys[3], numText(math.max(0, m)))
end

local WATER_KEYS = { "UI_ZeD_Sbx_WaterOnGood", "UI_ZeD_Sbx_WaterOnUntil", "UI_ZeD_Sbx_WaterOff" }
local POWER_KEYS = { "UI_ZeD_Sbx_PowerOnGood", "UI_ZeD_Sbx_PowerOnUntil", "UI_ZeD_Sbx_PowerOff" }
function ZeD_MMSandboxIG:worldLine()
    local day = 0
    pcall(function() day = math.floor(getGameTime():getWorldAgeDaysSinceBegin()) end)
    local water = self:supplyText("WaterShutModifier", day, WATER_KEYS)
    local power = self:supplyText("ElecShutModifier", day, POWER_KEYS)
    local t = ZeD.tr("UI_ZeD_Sbx_WorldDay", numText(day), water, power)
    if self.diff and (self.diff.WaterShutModifier or self.diff.ElecShutModifier) then t = t .. " " .. ZeD.tr("UI_ZeD_Sbx_AfterApply") end
    return t
end

-- VALUES --------------------------------------------------------------------------

-- a row's value as the option would write it ("4", "true", "0.65", text)
function ZeD_MMSandboxIG:rowValue(r)
    local c = r.control
    if r.kind == "combo" then return tostring(c.selected or 1) end
    if r.kind == "tick" then return c.selected[1] == true and "true" or "false" end
    local text = tostring(c:getText() or "")
    if r.setting.type == "string" or r.setting.type == "text" then return text end
    self.scratch = self.scratch or SandboxOptions.new()
    local o = self.scratch:getOptionByName(r.name)
    local out = text
    if o and o:isValidString(text) then pcall(function() o:parse(text); out = o:getValueAsString() end) end
    return out
end

function ZeD_MMSandboxIG:setRowValue(r, s)
    local c = r.control
    if r.kind == "combo" then c.selected = tonumber(s) or 1
    elseif r.kind == "tick" then c.selected[1] = (s == "true")
    else c:setText(s) end
end

-- a value as the player reads it: the list's name, On / Off, the number or text
function ZeD_MMSandboxIG:valueText(r, s)
    if r.kind == "combo" then
        local ok, t = pcall(function() return r.control:getOptionText(tonumber(s) or 1) end)
        return ok and tostring(t or s) or tostring(s)
    end
    if r.kind == "tick" then return ZeD.btnCase(getText(s == "true" and "UI_On" or "UI_Off")) end
    if s == nil or s == "" then return ZeD.tr("UI_ZeD_Sbx_Empty") end
    return tostring(s)
end

-- every row from the save's live values; these are the base the dots compare with
function ZeD_MMSandboxIG:load()
    local opts = so()
    self.base = {}
    for _, r in ipairs(self:allRows()) do
        local o = opts:getOptionByName(r.name)
        if o then
            local v = o:getValueAsString()
            self:setRowValue(r, v)
            self.base[r.name] = self:rowValue(r)
        end
    end
end

function ZeD_MMSandboxIG:refreshDiff(force)
    local t = MM.now()
    if not force and self._diffAt and t - self._diffAt < 400 then return end
    self._diffAt = t
    self.diff, self.nDiff = {}, 0
    for _, r in ipairs(self:allRows()) do
        local b = self.base[r.name]
        local changed = b ~= nil and self:rowValue(r) ~= b
        if changed then
            self.diff[r.name] = true
            self.nDiff = self.nDiff + 1
            r.under = ZeD.tr("UI_ZeD_Sbx_Was", self:valueText(r, b))
        else
            r.under = nil
        end
    end
end

function ZeD_MMSandboxIG:snapshot() end

-- settings that do nothing now: the fixed ones, and vanilla's greyed pairs
local MAP_OPTS = { ["Map.AllowMiniMap"] = true, ["Map.MapAllKnown"] = true }
function ZeD_MMSandboxIG:rowDisabled(r)
    local n = r.name
    if not n then return false end
    if N.when(n) == "fix" then return true end
    local world = self.ctls["Map.AllowWorldMap"]
    if MAP_OPTS[n] and world and world.control.selected[1] ~= true then return true end
    local g = self.ctls["MultiplierConfig.GlobalToggle"]
    if g and n:sub(1, 17) == "MultiplierConfig." then
        local on = g.control.selected[1] == true
        if n == "MultiplierConfig.Global" then return not on end
        if n ~= "MultiplierConfig.GlobalToggle" then return on end
    end
    return false
end

-- vanilla's links (ISServerSandboxOptionsUI.onComboBoxSelected / onTickBoxSelected)
function ZeD_MMSandboxIG:onCombo(combo, name)
    if name == "Zombies" and ZombiePopulationMultiplierTable and self.ctls["ZombieConfig.PopulationMultiplier"] then
        local v = ZombiePopulationMultiplierTable[combo.selected]
        if v then self.ctls["ZombieConfig.PopulationMultiplier"].control:setText(tostring(v)) end
    elseif name == "ZombieRespawn" and RESPAWN[combo.selected] then
        local t = RESPAWN[combo.selected]
        local names = { "ZombieConfig.RespawnHours", "ZombieConfig.RespawnUnseenHours", "ZombieConfig.RespawnMultiplier" }
        for i, n in ipairs(names) do if self.ctls[n] then self.ctls[n].control:setText(t[i]) end end
    end
    self:refreshDiff(true)
end

function ZeD_MMSandboxIG:onTick(i, value, name)
    if name == "ZombieMigrate" and self.ctls["ZombieConfig.RedistributeHours"] then
        self.ctls["ZombieConfig.RedistributeHours"].control:setText(value and "12.0" or "0.0")
    end
    self:refreshDiff(true)
end

-- APPLY, UNDO, HISTORY --------------------------------------------------------------

local function history()
    local md = ModData.getOrCreate(MD_KEY)
    md.entries = md.entries or {}
    return md.entries
end

local function stamp()
    local gt = getGameTime()
    return { y = gt:getYear(), mo = gt:getMonth(), d = gt:getDay() + 1, h = gt:getHour(), mi = gt:getMinutes() }
end

local function stampText(s)
    if not s then return "" end
    local mon = MM.MONTHS[(s.mo or 0) + 1]
    local h = s.h or 0
    local clock = string.format("%d:%02d", h, s.mi or 0)
    return ZeD.tr("UI_ZeD_Sbx_HistWhen", (mon and ZeD.tr(mon) or "") .. " " .. tostring(s.d or 1) .. ", " .. tostring(s.y or ""), clock)
end

-- sets every changed option on the game's own options, as the admin editor does
function ZeD_MMSandboxIG:applyNow()
    self:commitCell()
    self:refreshDiff(true)
    local opts = so()
    local rows, dayLength = {}, false
    for _, r in ipairs(self:allRows()) do
        if self.diff[r.name] then
            local o = opts:getOptionByName(r.name)
            local to = self:rowValue(r)
            if o and o:isValidString(to) then
                local ok = pcall(function() o:parse(to) end)
                if ok then
                    rows[#rows + 1] = { n = r.name, from = self.base[r.name], to = o:getValueAsString() }
                    if r.name == "DayLength" then dayLength = true end
                end
            end
        end
    end
    if #rows == 0 then self.confirm = false; return end
    pcall(function() opts:toLua() end)
    if dayLength then pcall(function() getGameTime():setMinutesPerDay(opts:getDayLengthMinutes()) end) end
    -- the loot tables read the removal list and mods' settings (vanilla's admin editor does both)
    pcall(function() IsoWorld.parseDistributions() end)
    pcall(function() StoryClutter.Init() end)
    -- the Loot Rarity numbers are copied into the loot picker once, at world load (only IsoWorld
    -- calls this): without it they would wait for the next load
    pcall(function() ItemPickerJava.InitSandboxLootSettings() end)
    local h = history()
    h[#h + 1] = { at = stamp(), rows = rows }
    while #h > HIST_MAX do table.remove(h, 1) end
    print("[ZeD] Sandbox in game: applied " .. #rows .. " change(s)")
    if self.onApplied then pcall(self.onApplied, rows) end   -- (QA)
    self:load()
    self:refreshDiff(true)
    self.confirm = false
    self._note, self._noteAt = ZeD.tr("UI_ZeD_Sbx_Applied", count(#rows)), MM.now()
    MM.clickSound()
end

function ZeD_MMSandboxIG:undoAll()
    self:endCell()
    for _, r in ipairs(self:allRows()) do
        if self.diff[r.name] and self.base[r.name] then self:setRowValue(r, self.base[r.name]) end
    end
    self.confirm = false
    self:refreshDiff(true)
    MM.clickSound()
end

-- Undo changes (on a History row): the row goes back to what it was before that apply (waiting for Apply)
function ZeD_MMSandboxIG:putBack(name, value)
    local r = self.ctls[name]
    if not r then return end
    self:setRowValue(r, value)
    self:refreshDiff(true)
    self:showPage("~changed")
    MM.clickSound()
end

function ZeD_MMSandboxIG:showPage(raw)
    for i, p in ipairs(self:pages()) do
        if p.raw == raw then self.pageIdx = i; self.scroll = 0; self.focusId = nil end
    end
    if self.find:getInternalText() ~= "" then self.find:setText("") end
end

function ZeD_MMSandboxIG:historyRows()
    local h = history()
    local out = {}
    for i = #h, 1, -1 do
        local e = h[i]
        out[#out + 1] = { kind = "header", text = stampText(e.at) .. MM.DOT .. count(#(e.rows or {})) }
        for _, c in ipairs(e.rows or {}) do
            local r = self.ctls[c.n]
            if r then
                local from, to = c.from, c.to
                local hr = { kind = "button", label = r.label, histOf = r, histFrom = from,
                             under = self:valueText(r, from) .. "  >  " .. self:valueText(r, to),
                             control = { title = ZeD.tr("UI_ZeD_Sbx_UndoChanges"), target = self,
                                         onclick = function() self:putBack(c.n, from) end } }
                out[#out + 1] = hr
            end
        end
    end
    if #out == 0 then out[1] = { kind = "note", text = ZeD.tr("UI_ZeD_Sbx_HistNone") } end
    return out
end

-- OPENING AND LEAVING ---------------------------------------------------------------

function ZeD_MMSandboxIG:onShow()
    self.confirm = false
    self:endCell()
    self.field:setVisible(false)
    self.find:setText("")
    self.scroll = 0
    self.focusId = nil
    self.pageIdx = 1
    self._note = nil
    self._helpRow = nil
    self:load()
    self:refreshDiff(true)
end
-- Escape out of the game and back: the window opens fresh (as Options does)
function ZeD_MMSandboxIG:onEnterFromGame() if self:isVisible() then self:onShow() end end

function ZeD_MMSandboxIG:finish()
    if self.find:isFocused() then self.find:unfocus() end
    self:endCell()
    self.confirm = false
    MM.pauseView = "pause"
end

-- Close: changes not applied ask first
function ZeD_MMSandboxIG:back()
    self:commitCell()
    MM.clickSound()
    if self:anyChanged() then self:setConfirm("close"); return end
    self:finish()
end
function ZeD_MMSandboxIG:next() end
function ZeD_MMSandboxIG:close() self:back() end

function ZeD_MMSandboxIG:askApply()
    if not self:anyChanged() then return end
    self:setConfirm("apply")
    self:showPage("~changed")
end

function ZeD_MMSandboxIG:setConfirm(mode)
    if self.confirm == mode then return end
    self:commitCell()
    self.confirm = mode
    MM.ctx.open = nil
    self.focusId = mode and "confirm:yes" or self.focusId
end

-- THE STRIP --------------------------------------------------------------------------
-- The band at the foot (UI.stripSpecs: Molecules.drawBand): the screen's actions, and each
-- question as a band of its own, the negative answer first and the main one last.
function ZeD_MMSandboxIG:buildStrip(stripY, stripH, w)
    local row = 1000
    local n = self.nDiff or 0
    local cancel = getText("UI_btn_cancel")
    if self.confirm == "apply" then
        local undo, care = 0, 0
        for name in pairs(self.diff) do
            local k = N.risk(name)
            if k == "undo" then undo = undo + 1 elseif k == "care" then care = care + 1 end
        end
        local ask = ZeD.tr("UI_ZeD_Sbx_AskApply", count(n))
        if undo > 0 then ask = ask .. " " .. ZeD.tr("UI_ZeD_Sbx_AskUndoN", tostring(undo))
        elseif care > 0 then ask = ask .. " " .. ZeD.tr("UI_ZeD_Sbx_AskCareN", tostring(care)) end
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", cancel, function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.btnCase(getText("UI_btn_apply")), function() self:applyNow() end, undo > 0 and "danger" or "primary" } }, ask)
    elseif self.confirm == "close" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", cancel, function() self:setConfirm(false) end },
            { "confirm:discard", ZeD.tr("UI_ZeD_Options_Discard"), function() self:undoAll(); self:finish() end, "danger" },
            { "confirm:yes", ZeD.btnCase(getText("UI_btn_apply")), function() self:askApply() end, "primary" } },
            ZeD.tr("UI_ZeD_Sbx_AskClose", count(n)))
    elseif self.confirm == "undo" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", cancel, function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Sbx_UndoChanges"), function() self:undoAll() end, "primary" } },
            ZeD.tr("UI_ZeD_Sbx_AskUndo", count(n)))
    else
        local note = nil
        if self._note and MM.now() - (self._noteAt or 0) < NOTE_MS then note = self._note else self._note = nil end
        UI.stripSpecs(self, stripY, w, row,
            { { "back", ZeD.btnCase(getText("UI_btn_close")), function() self:back() end } },
            { { "undo", ZeD.tr("UI_ZeD_Sbx_UndoChanges"), function() self:undoAll() end, "default", n == 0 },
              { "apply", ZeD.btnCase(getText("UI_btn_apply")), function() self:askApply() end, "primary", n == 0 } },
            note, true, ZeD.T.positive)
    end
end

-- DRAWING ----------------------------------------------------------------------------

function ZeD_MMSandboxIG:prerender()
    local T = ZeD.T
    self:refreshDiff(false)
    self._specs, self._hits = {}, {}
    local w, h = self:place()
    local pages = self:pages()
    if self.pageIdx > #pages then self.pageIdx = 1 end
    local page = pages[self.pageIdx]
    local q = string.lower(tostring(self.find:getInternalText() or ""))
    self.title = ZeD.tr("UI_ZeD_Sandbox_Title")
    local stat = ZeD.tr("UI_ZeD_Sbx_StatSave")
    if self.nDiff > 0 then stat = ZeD.tr("UI_ZeD_Sbx_StatChanged", tostring(self.nDiff)) end
    self.titleStats = { { text = stat, noMark = true } }
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local pw = T.px(PAGES_W)
    local rows
    if q ~= "" then
        rows = {}
        for _, p in ipairs(pages) do
            if not p.virtual then
                local hits = {}
                for _, r in ipairs(self:rowsFor(p)) do
                    if r.name then
                        local hay = string.lower(tostring(r.label) .. " " .. tostring(r.name) .. " " .. tipText(r.setting.tooltip))
                        if hay:find(q, 1, true) then hits[#hits + 1] = r end
                    end
                end
                if #hits > 0 then
                    rows[#rows + 1] = { kind = "header", text = p.title }
                    for _, r in ipairs(hits) do rows[#rows + 1] = r end
                end
            end
        end
    else
        rows = self:rowsFor(page)
    end
    self._cellDrawn = false
    self._rowsNow = rows
    self:measureTags()
    self:drawPages(pad, bodyY, pw, bodyH, pages, q ~= "")
    self:drawRows(pad * 2 + pw, bodyY, w - pad * 3 - pw, bodyH, rows, page, q ~= "")
    if self._cellRow and not self._cellDrawn then self:commitCell() end
    self:buildStrip(stripY, stripH, w)
end

-- a square mark beside each page with changes
function ZeD_MMSandboxIG:drawPages(x, y, w, h, pages, finding)
    ZeD_MMOptions.drawPages(self, x, y, w, h, pages, finding)
    local T = ZeD.T
    local ry = y + T.px(FIND_H) + T.px(1)
    local rh = T.px(PAGE_ROW_H)
    local dsz = T.px(6)
    for _, p in ipairs(pages) do
        if not p.virtual then
            local any = false
            for _, r in ipairs(self:rowsFor(p)) do if r.name and self.diff[r.name] then any = true end end
            if any then ZeD.Atoms.drawStatusDot(self, x + w - T.px(16), ry + math.floor((rh - dsz) / 2), T.accent, dsz) end
        end
        ry = ry + rh
    end
end

-- TAGS: WHEN and RISK at the right of a row. The library tag (an outline, the word in the
-- default ink) with a square mark for the state; nothing else is coloured.
local WHEN_KEY = { now = "UI_ZeD_Sbx_TagNow", new = "UI_ZeD_Sbx_TagNew", chr = "UI_ZeD_Sbx_TagChr", fix = "UI_ZeD_Sbx_TagFix", load = "UI_ZeD_Sbx_TagLoad" }
local RISK_KEY = { care = "UI_ZeD_Sbx_TagCare", undo = "UI_ZeD_Sbx_TagUndo" }

-- the mark of a WHEN (now: done at once; new, chr, load: it waits for something; fix: nothing to do,
-- a hollow mark) and of a RISK (care: warning; undo: danger)
local function whenMark(T, w)
    if w == "now" then return T.positive, false end
    if w == "fix" then return T.textDim, true end
    return T.info, false
end
local function riskMark(T, k) return k == "undo" and T.danger or T.warning end

-- a tag's width with its mark: the word, 5u each side, the 6u square and 4u after it
local function tagW(text)
    local T = ZeD.T
    return ZeD.TM:MeasureStringX(T.fontF1, ZeD.textCase(text)) + T.px(5) * 2 + T.px(6) + T.px(4)
end

function ZeD_MMSandboxIG:measureTags()
    local T = ZeD.T
    local ww, rw = 0, 0
    for _, k in pairs(WHEN_KEY) do ww = math.max(ww, tagW(ZeD.tr(k))) end
    for _, k in pairs(RISK_KEY) do rw = math.max(rw, tagW(ZeD.tr(k))) end
    self._tagsW = ww + rw + T.px(14)
end
function ZeD_MMSandboxIG:tagsW() return self._tagsW or 0 end

function ZeD_MMSandboxIG:drawRowTags(r, right, ry, rh)
    if not r.name then return end
    local T = ZeD.T
    local Mo = ZeD.Molecules
    local f1 = T.fontF1
    local by = ry + math.floor((rh - T.px(16)) / 2)
    local w = N.when(r.name)
    local wt = ZeD.tr(WHEN_KEY[w])
    local x = right - tagW(wt)
    local mc, hollow = whenMark(T, w)
    Mo.drawTag(self, x, by, wt, mc, { font = f1, hollow = hollow })
    local k = N.risk(r.name)
    if k ~= "" then
        local rt = ZeD.tr(RISK_KEY[k])
        Mo.drawTag(self, x - T.px(6) - tagW(rt), by, rt, riskMark(T, k), { font = f1 })
    end
end

-- a text setting (the removal lists) gets a wide box; the rest draw as the new-game window's
function ZeD_MMSandboxIG:drawControl(r, cx, ry, cw, rh, rowId, clip)
    if r.kind == "entry" and r.wide and self._cellRow ~= r then
        local T = ZeD.T
        local f2 = T.fontF2
        local bh = T.px(24)
        local bw = math.min(T.px(STRING_W), cw)
        local by = ry + math.floor(rh / 2) - math.floor(bh / 2)
        UI.insetBox(self, cx, by, bw, bh, true)   -- (loose: the box sits in a scrolled row)
        local tc = T.text
        self:drawText(ZeD.Atoms.truncateText(tostring(r.control:getText() or ""), f2, bw - T.px(12)), cx + T.px(6), by + math.floor((bh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        local top, bot = math.max(by, clip.y), math.min(by + bh, clip.y + clip.h)
        if bot > top then
            self._hits[#self._hits + 1] = { id = self.kind .. ":" .. rowId .. ":str", x = self:getAbsoluteX() + cx, y = self:getAbsoluteY() + top, w = bw, h = bot - top, fn = function() self:startCell(r) end, sound = true }
        end
        return
    end
    if r.kind == "entry" and r.wide and self._cellRow == r then
        -- edited in place, as wide as its box
        local T = ZeD.T
        local bh = T.px(24)
        local by = ry + math.floor(rh / 2) - math.floor(bh / 2)
        if by >= clip.y and by + bh <= clip.y + clip.h then
            UI.styleEntry(self.cell, cx, by, math.min(T.px(STRING_W), cw), bh)
            if not self.cell:isVisible() then self.cell:setVisible(true) end
            self._cellDrawn = true
        end
        return
    end
    ZeD_MMSandbox.drawControl(self, r, cx, ry, cw, rh, rowId, clip)
end

-- THE HELP BAND: what it does | on this save | tip (ten lines: the longest "on this save",
-- 280 characters in a third of the band, with its warning line above it)
function ZeD_MMSandboxIG:helpBandH()
    local T = ZeD.T
    return T.px(16) + MM.fontH(T.fontF1) + 10 * (MM.fontH(T.fontF2) + T.px(3))
end

function ZeD_MMSandboxIG:drawHelpCol(x, y, w, h, head, body, foot, warn)
    local T = ZeD.T
    local f1, f2 = T.fontF1, T.fontF2
    local th, tc, d = T.textHead, T.text, T.textDim
    self:drawText(ZeD.textCase(head), x, y, th.r, th.g, th.b, th.a or 1, f1)
    local ly = y + MM.fontH(f1) + T.px(4)
    local lh = MM.fontH(f2) + T.px(3)
    local footH = foot and (MM.fontH(f1) + T.px(4)) or 0
    local maxL = math.max(1, math.floor((y + h - footH - ly) / lh))
    local n = 0
    if warn then
        -- a warning: its square mark, then the words in the default ink
        local sq, ind = T.px(6), T.px(12)
        local wc = warn.color
        for i, l in ipairs(ZeD.Atoms.wrapText(warn.text, f2, w - ind)) do
            n = n + 1
            if n > maxL then break end
            if i == 1 then ZeD.Atoms.drawStatusDot(self, x, ly + math.floor((MM.fontH(f2) - sq) / 2), wc, sq) end
            self:drawText(l, x + ind, ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
            ly = ly + lh
        end
    end
    for _, l in ipairs(ZeD.Atoms.wrapText(body or "", f2, w)) do
        n = n + 1
        if n > maxL then break end
        self:drawText(l, x, ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
        ly = ly + lh
    end
    if foot then self:drawText(ZeD.Atoms.truncateText(foot, f1, w), x, y + h - MM.fontH(f1), d.r, d.g, d.b, d.a or 1, f1) end
end

function ZeD_MMSandboxIG:drawHelp(x, hy, w, helpH, hr)
    local T = ZeD.T
    local bd = T.border   -- (the band's surface and its top line are drawn by ZeD_MMOptions:drawRows)
    if self.qaHelp then hr = self.qaHelp end   -- (QA: the setting a test points at, wherever the pointer is)
    -- the setting under the pointer, kept while the pointer moves down to read; a new page starts empty
    local view = tostring(self.pageIdx) .. "|" .. tostring(self.find:getInternalText() or "")
    if view ~= self._helpView then self._helpView = view; self._helpRow = nil end
    if hr and (hr.name or hr.histOf) then self._helpRow = hr end
    local r = self._helpRow
    local top, ih = hy + T.px(8), helpH - T.px(16)
    if not r then
        self:drawHelpCol(x + T.px(12), top, w - T.px(24), ih, ZeD.tr("UI_ZeD_Sbx_HeadWhat"), ZeD.tr("UI_ZeD_Sbx_HelpNone"))
        return
    end
    if r.histOf then
        self:drawHelpCol(x + T.px(12), top, w - T.px(24), ih, ZeD.tr("UI_ZeD_Sbx_UndoChanges"),
            ZeD.tr("UI_ZeD_Sbx_PutBackHelp", r.histOf.label, self:valueText(r.histOf, r.histFrom)))
        return
    end
    local st = r.setting
    local when, risk = N.when(r.name), N.risk(r.name)
    local tip = N.tip(r.name, r.section)
    local cols = tip and 3 or 2
    local gap = T.px(14)
    local cwid = math.floor((w - T.px(24) - gap * (cols - 1)) / cols)
    -- what it does: vanilla's words, its default and range
    local o = so():getOptionByName(r.name)
    local def, range = "", ""
    if o then
        pcall(function()
            local dv = o:getDefaultValue()
            if r.kind == "combo" then def = self:valueText(r, tostring(dv))
            elseif r.kind == "tick" then def = self:valueText(r, dv and "true" or "false")
            else def = self:valueText(r, type(dv) == "number" and numText(dv) or tostring(dv)) end
        end)
        if st.type == "entry" then
            pcall(function()
                local mx = o:getMax()
                range = ZeD.tr("UI_ZeD_Sbx_Range", numText(o:getMin()), mx >= 1e9 and ZeD.tr("UI_ZeD_Sbx_Any") or numText(mx))
            end)
        end
    end
    local what = tipText(st.tooltip)
    if what == "" then what = r.label end
    local foot1 = ZeD.tr("UI_ZeD_Options_DefaultIs", def) .. (range ~= "" and (MM.DOT .. range) or "")
    local cx = x + T.px(12)
    self:drawHelpCol(cx, top, cwid, ih, ZeD.tr("UI_ZeD_Sbx_HeadWhat"), what, foot1)
    -- on this save
    self:drawRect(cx + cwid + math.floor(gap / 2), top, T.px(1), ih, bd.a or 1, bd.r, bd.g, bd.b)
    cx = cx + cwid + gap
    local warn = nil
    if risk == "undo" then warn = { text = ZeD.tr("UI_ZeD_Sbx_WarnUndo"), color = T.danger }
    elseif risk == "care" then warn = { text = ZeD.tr("UI_ZeD_Sbx_WarnCare"), color = T.warning } end
    local now = ZeD.tr("UI_ZeD_Sbx_ThisSave", self:valueText(r, self.base[r.name]))
    if self.diff[r.name] then now = now .. MM.DOT .. ZeD.tr("UI_ZeD_Sbx_AfterApplyIs", self:valueText(r, self:rowValue(r))) end
    self:drawHelpCol(cx, top, cwid, ih, ZeD.tr("UI_ZeD_Sbx_HeadSave", ZeD.tr(WHEN_KEY[when])), N.save(r.name, r.section), now, warn)
    -- a tip
    if tip then
        self:drawRect(cx + cwid + math.floor(gap / 2), top, T.px(1), ih, bd.a or 1, bd.r, bd.g, bd.b)
        self:drawHelpCol(cx + cwid + gap, top, cwid, ih, ZeD.tr("UI_ZeD_Sbx_HeadTip"), tip)
    end
end

-- CONTROLLER + KEYS ------------------------------------------------------------------
function ZeD_MMSandboxIG:joyB()
    if self._cellRow then self:endCell(); return end
    if self.confirm then self:setConfirm(false); return end
    self:back()
end
function ZeD_MMSandboxIG:joyX() if not self.confirm and self:anyChanged() then self:setConfirm("undo") end end
function ZeD_MMSandboxIG:joyY() if not self.confirm then self:askApply() end end
function ZeD_MMSandboxIG:joyBumper(dir)
    if self.confirm then return end
    ZeD_MMOptions.joyBumper(self, dir)
end

function ZeD_MMSandboxIG:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    local r = self:focusedRow()
    local t = {}
    if r and r.name and not self:rowDisabled(r) then
        if r.kind == "combo" then t[#t + 1] = { glyph = "<>", label = ZeD.tr("UI_ZeD_Options_PromptChange") } end
        t[#t + 1] = { glyph = "A", label = ZeD.tr((r.kind == "tick") and "UI_ZeD_Options_PromptToggle" or ((r.kind == "entry") and "UI_ZeD_Sandbox_PromptEdit" or "UI_ZeD_MainMenu_PromptSelect")) }
    elseif r and r.kind == "button" then
        t[#t + 1] = { glyph = "A", label = ZeD.tr("UI_ZeD_Sbx_UndoChanges") }
    end
    t[#t + 1] = { glyph = "LB", label = "" }
    t[#t + 1] = { glyph = "RB", label = ZeD.tr("UI_ZeD_Options_PromptPage") }
    if self:anyChanged() then
        t[#t + 1] = { glyph = "X", label = ZeD.tr("UI_ZeD_Sbx_UndoChanges") }
        t[#t + 1] = { glyph = "Y", label = ZeD.btnCase(getText("UI_btn_apply")) }
    end
    t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_close")) }
    return t
end

function ZeD_MMSandboxIG:keyEscape()
    if self._cellRow then self:endCell(); return true end
    if self.confirm then self:setConfirm(false); return true end
    if self.find:isFocused() then self.find:unfocus(); return true end
    self:back()
    return true
end
function ZeD_MMSandboxIG:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self._cellRow then return key == Keyboard.KEY_RETURN end
    return false
end

-- ============================================================================
-- THE PAUSE WINDOW'S LINE
-- ============================================================================

-- the line shows with the switch on, in single player
function MM.sandboxIGShown()
    if isClient() then return false end
    return ZeD.Settings and ZeD.Settings.sandboxInGameOn and ZeD.Settings.sandboxInGameOn() and MM.pauseSandbox ~= nil or false
end

function MM.openSandboxIG()
    local m = MainScreen and MainScreen.instance
    if not (m and m.inGame and MM.pauseSandbox) or isClient() then return end
    MM.ctx.open = nil
    MM.clickSound()
    MM.pauseView = "sandbox"
    MM.pauseSandbox:onShow()
end

ZeD.SandboxIG = { history = history, stampText = stampText }   -- (QA)
