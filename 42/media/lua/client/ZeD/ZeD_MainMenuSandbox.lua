-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuSandbox.lua
-- ============================================================================
-- SANDBOX OPTIONS ON THE MONITOR (HOOK_MAP row 26; director, Oct 14 2026:
-- menus delegated, no mockups)
--
-- The Options window's layout (pages, Find, rows, the help band, list-box
-- pop-ups, the controller) over vanilla's SandboxOptionsScreen, which stays
-- built and hidden as the engine: its controls hold every value, its presets
-- load and save, its settingsFromUI / setSandboxVars and its BACK / NEXT run
-- as vanilla. Its setVisible(true) is redirected here.
--
-- What it adds over vanilla, on vanilla's data:
--   * a dot on every option that differs from the chosen preset, and the
--     count in the title (vanilla marked differences from the game default)
--   * numbers are edited in their row (Return keeps, Escape leaves, a red
--     outline while the number is out of range); the help band shows the range
--   * an option with named steps ("Zombie Count": Insane ... None) is one list
--     box of its steps with their numbers and Custom Number... (vanilla's
--     Advanced tick box switched every such option between two controls)
--   * options that do nothing in the current setup are greyed and inert
--     (the mini map without the world map, skill multipliers under the
--     global one), as vanilla greyed them
--   * presets in one pop-up (every preset, Save as Preset..., Delete);
--     loading one over changes asks first; save and delete ask in the band
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuOptions"
require "OptionScreens/SandboxOptions"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units (the Options window's)
local PAGES_W = 210
local ENTRY_W, COMBO_W = 170, 280

local function ms() return MainScreen and MainScreen.instance end
local function sand() local m = ms(); return m and m.sandOptions end
local MARK = string.char(171)

local function comboText(c, i) local ok, t = pcall(function() return c:getOptionText(i) end); return ok and tostring(t or "") or "" end

-- a setting's help for Find: its tooltip, plain
local function helpText(r)
    local c = r.control
    local t = c and c.tooltip
    if type(t) == "table" then t = t.defaultTooltip end
    if type(t) ~= "string" then return "" end
    return UI.plain(t)
end

-- ============================================================================
ZeD_MMSandbox = ZeD_MMOptions:derive("ZeD_MMSandbox")

function ZeD_MMSandbox:new()
    local o = ZeD_MMWindow.new(self, "sandbox")
    o.inGame = false
    o.noResetControl = true
    o.pageIdx = 1
    o.scroll = 0
    o.confirm = false     -- false | "load" | "save" | "delete"
    o.snap = {}
    o.diff, o.nDiff = {}, 0
    o.changedNote = "UI_ZeD_Sandbox_ChangedNote"   -- (a translation key; the Options window's help band turns it into words)
    o.ctx = { hot = nil, press = nil, wasDown = false }
    return o
end

function ZeD_MMSandbox:createChildren()
    ZeD_MMOptions.createChildren(self)   -- Find and the band's field
    -- the in-place number field (one, moved to the row being edited)
    self.cell = UI.newEntry(self)
    self.cell:setVisible(false)
    self.cell.onCommandEntered = function() self._enterAt = MM.now(); self:commitCell(true) end
    self.cell.onEscape = function() self:endCell() end
    -- Tab keeps the number and opens the next one down (Shift+Tab: up), as a spreadsheet does
    local escOnly = self.cell.onOtherKey
    self.cell.onOtherKey = function(entry, key)
        if key == Keyboard.KEY_TAB then
            local back = Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)
            self:tabCell(back and -1 or 1)
            return
        end
        return escOnly(entry, key)
    end
end

-- the next number row on screen after the one being edited
function ZeD_MMSandbox:tabCell(dir)
    local cur = self._cellRow
    local rows = self._rowsNow or {}
    if not cur then return end
    local at = nil
    for i, r in ipairs(rows) do if r == cur then at = i end end
    self:commitCell(true)
    if self._cellRow then return end   -- an invalid number stays open
    if not at then return end
    local i = at + dir
    while rows[i] do
        local r = rows[i]
        if (r.kind == "entry" or r.kind == "adv") and not self:rowDisabled(r) then
            self:startCell(r)
            self:scrollToRow(r)
            return
        end
        i = i + dir
    end
end

-- brings a row into view (the rows' laid-out spec carries its offset)
function ZeD_MMSandbox:scrollToRow(r)
    for _, b in ipairs(self._specs or {}) do
        if b.rowRef == r then
            local vh = self._list and self._list.h or 0
            if b.ry < self.scroll then self.scroll = b.ry
            elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
        end
    end
end

-- vanilla's pages (its list box), each with its settings
function ZeD_MMSandbox:pages()
    local s = sand()
    local t = {}
    for _, it in ipairs(s and s.listbox and s.listbox.items or {}) do
        local p = it.item and it.item.page
        if p then t[#t + 1] = { title = tostring(it.text), raw = tostring(p.name), page = p } end
    end
    return t
end

-- a page's rows: a header where vanilla puts a section title, then each setting with
-- its own vanilla control (built once in vanilla's create, so cached for good)
function ZeD_MMSandbox:rowsFor(page)
    if not page then return {} end
    self._rows = self._rows or {}
    local cached = self._rows[page.raw]
    if cached then return cached end
    local s = sand()
    local rows = {}
    for _, st in ipairs(page.page.settings or {}) do
        local ctl = s and s.controls and s.controls[st.name]
        if ctl then
            if st.title then rows[#rows + 1] = { kind = "header", text = getText("Sandbox_Title_" .. st.title) } end
            local kind = nil
            if st.type == "checkbox" then kind = "tick"
            elseif st.type == "enum" then kind = "combo"
            elseif st.advancedCombo then kind = "adv"
            elseif st.type == "entry" or st.type == "string" then kind = "entry" end
            if kind then rows[#rows + 1] = { kind = kind, control = ctl, label = tostring(st.translatedName or st.name), name = st.name, setting = st } end
        end
    end
    self._rows[page.raw] = rows
    return rows
end

-- the preset the screen holds, and its name as the list shows it
function ZeD_MMSandbox:preset()
    local s = sand()
    if not s or not s.presets then return nil, "" end
    local i = s.presetList.selected
    return s.presets[i], comboText(s.presetList, i)
end

-- which options differ from the preset (vanilla's settingsFromUI into a scratch set)
function ZeD_MMSandbox:refreshDiff(force)
    local t = MM.now()
    if not force and self._diffAt and t - self._diffAt < 400 then return end
    self._diffAt = t
    self.diff, self.nDiff = {}, 0
    local s = sand()
    local p = self:preset()
    if not s or not p or not p.options then return end
    self.scratch = self.scratch or SandboxOptions.new()
    s:settingsFromUI(self.scratch)
    for i = 0, self.scratch:getNumOptions() - 1 do
        local o = self.scratch:getOptionByIndex(i)
        local name = o:getName()
        if s.controls[name] then
            local po = p.options:getOptionByName(name)
            if po and po:getValueAsString() ~= o:getValueAsString() then
                self.diff[name] = true
                self.nDiff = self.nDiff + 1
            end
        end
    end
end

function ZeD_MMSandbox:snapshot() end
function ZeD_MMSandbox:isChanged(r) return r.name ~= nil and self.diff[r.name] == true end
function ZeD_MMSandbox:anyChanged() return self.nDiff > 0 end

-- options that do nothing in the current setup (vanilla greys the same ones)
local MAP_OPTS = { ["Map.AllowMiniMap"] = true, ["Map.MapAllKnown"] = true }
function ZeD_MMSandbox:rowDisabled(r)
    local s = sand()
    local n = r.name
    if not s or not n then return false end
    local ctl = s.controls
    local world = ctl["Map.AllowWorldMap"]
    if MAP_OPTS[n] and world and not world:isSelected(1) then return true end
    local global = ctl["MultiplierConfig.GlobalToggle"]
    if global and n:sub(1, 17) == "MultiplierConfig." then
        if n == "MultiplierConfig.Global" then return not global:isSelected(1) end
        if n ~= "MultiplierConfig.GlobalToggle" then return global:isSelected(1) end
    end
    return false
end

function ZeD_MMSandbox:onShow()
    self.confirm = false
    self:endCell()
    self.field:setVisible(false)
    self.find:setText("")
    self.scroll = 0
    self.focusId = nil
    self:refreshDiff(true)
end

-- LEAVING ------------------------------------------------------------------------

-- NEXT: vanilla's (SandboxVars from the controls, the preset's name, character creation)
function ZeD_MMSandbox:next()
    local s = sand()
    if not s then return end
    self:commitCell()
    MM.clickSound()
    MM.toVanilla()
    s:onOptionMouseDown({ internal = "PLAY" }, 0, 0)
end

-- BACK: vanilla's (map / spawn lands on the monitor); the values stay for next time
function ZeD_MMSandbox:back()
    local s = sand()
    self:commitCell()
    MM.clickSound()
    if not s then MM.showView("newgame"); return end
    MM.toVanilla()
    s:onOptionMouseDown({ internal = "BACK" }, 0, 0)
    local m = ms()
    local ws = m and m.worldSelect
    if MM.view == "sandbox" and not (ws and ws:isVisible()) then MM.showView("newgame") end
end

-- NUMBERS, EDITED IN THEIR ROW -----------------------------------------------------

function ZeD_MMSandbox:startCell(r)
    if self._cellRow then self:commitCell() end
    if self:rowDisabled(r) then return end
    MM.ctx.open = nil
    self._cellRow = r
    self._cellAt = MM.now()
    self.cell:setText(tostring(r.control:getText() or ""))
    self.cell:setVisible(true)
    self.cell:focus()
    pcall(function() self.cell:selectAll() end)   -- typing replaces the number, as in a spreadsheet cell
    MM.clickSound()
end

function ZeD_MMSandbox:cellValid()
    local r = self._cellRow
    if not r then return true end
    local opt = getSandboxOptions():getOptionByName(r.name)
    if not opt then return true end
    return opt:isValidString(self.cell:getText() or "")
end

-- keeps a valid number; Return on an invalid one keeps the field open
function ZeD_MMSandbox:commitCell(fromReturn)
    local r = self._cellRow
    if not r then return end
    if self:cellValid() then
        local text = self.cell:getText() or ""
        if text ~= tostring(r.control:getText() or "") then r.control:setText(text) end
        self:endCell()
        self:refreshDiff(true)
    elseif fromReturn then
        self._cellAt = MM.now()
        self.cell:focus()
    else
        self:endCell()
    end
end

function ZeD_MMSandbox:endCell()
    self._cellRow = nil
    if self.cell then
        if self.cell:isFocused() then self.cell:unfocus() end
        if self.cell:isVisible() then self.cell:setVisible(false) end
    end
end

-- NAMED STEPS (vanilla's SandboxAdvancedControl: a list of steps, or a typed number) -

function ZeD_MMSandbox:advLabel(c)
    local vals = c.setting.advancedCombo.values
    local sel = c.combo.selected
    if sel >= 1 and sel <= #vals then return getText(vals[sel].name) end
    return getText("Sandbox_Custom")
end

-- a step: its number into the field, and Zombie Count follows the population (vanilla)
function ZeD_MMSandbox:setAdv(r, i)
    local c = r.control
    local vals = c.setting.advancedCombo.values
    if not vals[i] then return end
    c.combo.selected = i
    c.entry:setText(tostring(vals[i].text))
    local s = sand()
    if c.setting.name == "ZombieConfig.PopulationMultiplier" and s and s.controls["Zombies"] then s.controls["Zombies"].selected = i end
    self:refreshDiff(true)
end

function ZeD_MMSandbox:openAdv(r, anchor)
    local c = r.control
    local vals = c.setting.advancedCombo.values
    local items = {}
    for i, v in ipairs(vals) do
        local t = getText(v.name) .. "  (" .. tostring(v.text) .. ")"
        if i == c.combo.selected then t = t .. "  " .. MARK end
        items[#items + 1] = { text = t, fn = function() self:setAdv(r, i) end }
    end
    items[#items + 1] = "-"
    items[#items + 1] = { text = ZeD.tr("UI_ZeD_Sandbox_CustomNumber"), fn = function() self:startCell(r) end }
    MM.openPopup("combo", items, anchor, false)
    MM.ctx.dropFocus = math.max(1, math.min(c.combo.selected or 1, #vals + 1))
end

-- DRAWING ----------------------------------------------------------------------------

function ZeD_MMSandbox:drawControl(r, cx, ry, cw, rh, rowId, clip)
    local T = ZeD.T
    local c = r.control
    local dis = self:rowDisabled(r)
    if r.kind == "entry" or r.kind == "adv" then
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        local f2 = T.fontF2
        local bs = T.borderS
        local hot = MM.ctx.hot
        local bh = T.px(24)
        local by = ry + math.floor(rh / 2) - math.floor(bh / 2)
        local inView = by >= clip.y and by + bh <= clip.y + clip.h
        local function hit(id, x, w, fn)
            local top, bot = math.max(by, clip.y), math.min(by + bh, clip.y + clip.h)
            if bot <= top or dis then return end
            self._hits[#self._hits + 1] = { id = self.kind .. ":" .. id, x = ax + x, y = ay + top, w = w, h = bot - top, fn = fn, sound = true }
        end
        local tc = T.text
        local a = (tc.a or 1) * (dis and T.disabledAlpha or 1)
        if r.kind == "entry" then
            local bw = math.min(T.px(ENTRY_W), cw)
            if self._cellRow == r then
                -- the field sits in the row while it is edited (only while the row is fully in view)
                if inView then
                    UI.styleEntry(self.cell, cx, by, bw, bh)
                    if not self.cell:isVisible() then self.cell:setVisible(true) end
                    self._cellDrawn = true
                    if not self:cellValid() then
                        ZeD.Atoms.frame(self, cx - T.px(2), by - T.px(2), bw + 2 * T.px(2), bh + 2 * T.px(2), T.danger)
                    end
                end
                return
            end
            UI.insetBox(self, cx, by, bw, bh, true)
            self:drawText(ZeD.Atoms.truncateText(tostring(c:getText() or ""), f2, bw - T.px(12)), cx + T.px(6), by + math.floor((bh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, a, f2)
            hit(rowId .. ":num", cx, bw, function() self:startCell(r) end)
        else
            -- a list box of the steps; a typed number edits in place like a number row
            if self._cellRow == r then
                local bw = math.min(T.px(ENTRY_W), cw)
                if inView then
                    UI.styleEntry(self.cell, cx, by, bw, bh)
                    if not self.cell:isVisible() then self.cell:setVisible(true) end
                    self._cellDrawn = true
                    if not self:cellValid() then
                        ZeD.Atoms.frame(self, cx - T.px(2), by - T.px(2), bw + 2 * T.px(2), bh + 2 * T.px(2), T.danger)
                    end
                end
                return
            end
            local bw = math.min(T.px(COMBO_W), cw)
            local id = rowId .. ":adv"
            -- the pop-up menu's closed box (the library look) with the step's name and its number in it
            MM.drawDropBox(self, cx, by, bw, bh, "", hot == self.kind .. ":" .. id and not dis and not MM.gamepad(), dis)
            local num = tostring(c:getText() or "")
            local d = T.textDim
            local nw = MM.textW(f2, num)
            local padX, tri = T.sp.inputPadX, T.px(5)
            self:drawText(num, cx + bw - padX - tri - T.px(8) - nw, by + math.floor((bh - MM.fontH(f2)) / 2), d.r, d.g, d.b, (d.a or 1) * (dis and T.disabledAlpha or 1), f2)
            self:drawText(ZeD.Atoms.truncateText(self:advLabel(c), f2, bw - padX * 2 - tri - T.px(16) - nw), cx + padX, by + math.floor((bh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, a, f2)
            hit(id, cx, bw, function() self:openAdv(r, { x = ax + cx, y = ay + by, w = bw, h = bh }) end)
        end
        return
    end
    -- list boxes and tick boxes: the Options window's, greyed and inert when they do nothing
    if dis and r.kind == "combo" then
        local was = c.disabled
        c.disabled = true
        ZeD_MMOptions.drawControl(self, r, cx, ry, cw, rh, rowId, clip)
        c.disabled = was
        return
    end
    if dis and r.kind == "tick" then
        local was = c.enable
        c.enable = false
        ZeD_MMOptions.drawControl(self, r, cx, ry, cw, rh, rowId, clip)
        c.enable = was
        return
    end
    ZeD_MMOptions.drawControl(self, r, cx, ry, cw, rh, rowId, clip)
end

function ZeD_MMSandbox:prerender()
    local T = ZeD.T
    local s = sand()
    if s then pcall(function() s:syncStartDay() end) end   -- vanilla's prerender keeps Start Day's days; it does not run while hidden
    self:refreshDiff(false)
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local pages = self:pages()
    if self.pageIdx > #pages then self.pageIdx = 1 end
    local page = pages[self.pageIdx]
    local q = string.lower(tostring(self.find:getInternalText() or ""))
    local _, pname = self:preset()
    self.title = ZeD.tr("UI_ZeD_Sandbox_Title")
    local stat = pname
    if self.nDiff > 0 then stat = ZeD.tr("UI_ZeD_Sandbox_StatChanged", pname, self.nDiff) end
    self.titleStats = { { text = stat, noMark = true } }
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local pw = T.px(PAGES_W)
    -- which rows: the page's, or every option matching Find
    local rows
    if q ~= "" then
        rows = {}
        for _, p in ipairs(pages) do
            local hits = {}
            for _, r in ipairs(self:rowsFor(p)) do
                if r.kind ~= "header" then
                    local hay = string.lower(tostring(r.label or "") .. " " .. helpText(r))
                    if hay:find(q, 1, true) then hits[#hits + 1] = r end
                end
            end
            if #hits > 0 then
                rows[#rows + 1] = { kind = "header", text = p.title }
                for _, r in ipairs(hits) do rows[#rows + 1] = r end
            end
        end
    else
        rows = self:rowsFor(page)
    end
    self._cellDrawn = false
    self._rowsNow = rows
    self:drawPages(pad, bodyY, pw, bodyH, pages, q ~= "")
    self:drawRows(pad * 2 + pw, bodyY, w - pad * 3 - pw, bodyH, rows, page, q ~= "")
    -- a number being edited whose row left the view is kept (or dropped when invalid)
    if self._cellRow and not self._cellDrawn then self:commitCell() end
    self:buildStrip(stripY, stripH, w)
end

-- PRESETS -----------------------------------------------------------------------------

function ZeD_MMSandbox:presetItems()
    local s = sand()
    local t = {}
    if not s then return t end
    for i, _ in ipairs(s.presets or {}) do
        local name = comboText(s.presetList, i)
        if i == s.presetList.selected then name = name .. "  " .. MARK end
        t[#t + 1] = { text = name, fn = function() self:pickPreset(i) end }
    end
    t[#t + 1] = "-"
    t[#t + 1] = { text = ZeD.tr("UI_ZeD_Sandbox_SavePreset"), fn = function() self:setConfirm("save") end }
    local p = self:preset()
    if p and p.userDefined then
        t[#t + 1] = { text = ZeD.tr("UI_ZeD_Sandbox_DeletePreset", tostring(p.name)), fn = function() self:setConfirm("delete") end }
    end
    return t
end

function ZeD_MMSandbox:openPresets()
    for _, b in ipairs(self._specs) do
        if b.id == "presets" then
            MM.openPopup("presets", self:presetItems(), { x = self:getAbsoluteX() + b.x, y = self:getAbsoluteY() + b.y, w = b.w, h = b.h }, true)
            return
        end
    end
end

-- picking a preset over changes asks first
function ZeD_MMSandbox:pickPreset(i)
    local s = sand()
    if not s then return end
    if i == s.presetList.selected and not self:anyChanged() then return end
    if self:anyChanged() then
        self._pending = i
        self:setConfirm("load")
        return
    end
    self:loadPreset(i)
end

function ZeD_MMSandbox:loadPreset(i)
    local s = sand()
    if not s then return end
    self:endCell()
    s.presetList.selected = i
    s:onPresetChange()
    self.confirm = false
    self:refreshDiff(true)
    MM.clickSound()
end

-- vanilla's onSavePreset (its name rules, the preset file, the list reloaded and the new one chosen)
function ZeD_MMSandbox:savePreset()
    local s = sand()
    local name = self.field:getText() or ""
    if not s or not SandboxOptions.isValidPresetName(name) then return end
    local options = SandboxOptions.new()
    s:settingsFromUI(options)
    options:savePresetFile(name)
    s:loadPresets()
    for i, p in ipairs(s.presets) do
        if p.name == name then
            s.presetList.selected = i
            s:onPresetChange()
            break
        end
    end
    self:setConfirm(false)
    self:refreshDiff(true)
    MM.clickSound()
end

function ZeD_MMSandbox:deletePreset()
    local s = sand()
    local p = self:preset()
    if s and p and p.userDefined then
        -- vanilla's reload applies whichever preset is chosen after it; the values on screen stay
        local keep = SandboxOptions.new()
        s:settingsFromUI(keep)
        deleteSandboxPreset(p.name)
        s:loadPresets()
        s:settingsToUI(keep)
    end
    self:setConfirm(false)
    self:refreshDiff(true)
end

function ZeD_MMSandbox:commitText()
    if self.confirm == "save" then self:savePreset() end
end

function ZeD_MMSandbox:setConfirm(mode)
    if self.confirm == mode then return end
    self:commitCell()
    self.confirm = mode
    MM.ctx.open = nil
    if mode == "save" then
        local p = self:preset()
        self.field:setText((p and p.userDefined) and tostring(p.name) or ZeD.tr("UI_ZeD_Sandbox_NewPresetName"))
        self.field:setVisible(true)
        self.field:focus()
    else
        self.field:setVisible(false)
        if self.field:isFocused() then self.field:unfocus() end
    end
    self.focusId = mode and "confirm:yes" or self.focusId
end

-- THE STRIP -----------------------------------------------------------------------------
function ZeD_MMSandbox:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    if self.confirm == "load" then
        local s = sand()
        local name = s and comboText(s.presetList, self._pending or 1) or ""
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_mainscreen_load"), function() self:loadPreset(self._pending or 1) end, "primary" } },
            ZeD.tr("UI_ZeD_Sandbox_AskLoad", name))
    elseif self.confirm == "delete" then
        local p = self:preset()
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:deletePreset() end, "danger" } },
            ZeD.tr("UI_ZeD_Sandbox_AskDelete", tostring(p and p.name or "")))
    elseif self.confirm == "save" then
        local ask = ZeD.tr("UI_ZeD_Sandbox_AskName")
        local valid = SandboxOptions.isValidPresetName(self.field:getText() or "")
        local fx = UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_save"), function() self:savePreset() end, "primary", not valid } }, ask, true)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    else
        UI.stripSpecs(self, stripY, w, row,
            { { "back", getText("UI_btn_back"), function() self:back() end } },
            { { "presets", ZeD.tr("UI_ZeD_Sandbox_Presets"), function() self:openPresets() end },
              { "next", getText("UI_btn_next"), function() self:next() end, "primary" } })
    end
end

-- ROWS: A on a controller, Space / Return on a focused row ---------------------------------
function ZeD_MMSandbox:activateRow(r)
    if self:rowDisabled(r) then return end
    if r.kind == "entry" then self:startCell(r); return end
    if r.kind == "adv" then
        local T = ZeD.T
        self:openAdv(r, { x = self:getAbsoluteX() + self.width / 2, y = self:getAbsoluteY() + self.height / 3, w = T.px(COMBO_W), h = T.px(24) })
        return
    end
    ZeD_MMOptions.activateRow(self, r)
    self:refreshDiff(true)
end

-- left / right: a list box's or a step list's neighbour
function ZeD_MMSandbox:nudge(r, dir)
    if self:rowDisabled(r) then return true end
    if r.kind == "adv" then
        local c = r.control
        local n = #c.setting.advancedCombo.values
        local i = math.max(1, math.min(n, (c.combo.selected or 1) + dir))
        if c.combo.selected > n then i = (dir < 0) and n or 1 end
        if i ~= c.combo.selected then self:setAdv(r, i); MM.hoverSound() end
        return true
    end
    if r.kind == "entry" then return false end
    local done = ZeD_MMOptions.nudge(self, r, dir)
    self:refreshDiff(true)
    return done
end

-- a press anywhere but the number field keeps the number
function ZeD_MMSandbox:update()
    if self._cellRow and isMouseButtonDown(0) and not self._cellDown then
        local e = self.cell
        local mx, my = getMouseX(), getMouseY()
        local ex, ey = e:getAbsoluteX(), e:getAbsoluteY()
        if not (mx >= ex and mx < ex + e.width and my >= ey and my < ey + e.height) then self:commitCell() end
    end
    self._cellDown = isMouseButtonDown(0)
    -- the field let go some other way: the number stays as it was
    if self._cellRow and not self.cell:isFocused() and MM.now() - (self._cellAt or 0) > 150 then self:endCell() end
    ZeD_MMOptions.update(self)
end

-- CONTROLLER + KEYS ------------------------------------------------------------------------
function ZeD_MMSandbox:joyB()
    if self._cellRow then self:endCell(); return end
    if self.confirm then self:setConfirm(false); return end
    self:back()
end
function ZeD_MMSandbox:joyX() end
function ZeD_MMSandbox:joyY() if not self.confirm then self:openPresets() end end

function ZeD_MMSandbox:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    local r = self:focusedRow()
    local t = {}
    if r then
        if r.kind == "combo" or r.kind == "adv" then t[#t + 1] = { glyph = "<>", label = ZeD.tr("UI_ZeD_Options_PromptChange") } end
        t[#t + 1] = { glyph = "A", label = ZeD.tr((r.kind == "tick") and "UI_ZeD_Options_PromptToggle" or ((r.kind == "entry") and "UI_ZeD_Sandbox_PromptEdit" or "UI_ZeD_MainMenu_PromptSelect")) }
    end
    t[#t + 1] = { glyph = "LB", label = "" }
    t[#t + 1] = { glyph = "RB", label = ZeD.tr("UI_ZeD_Options_PromptPage") }
    t[#t + 1] = { glyph = "Y", label = ZeD.tr("UI_ZeD_Sandbox_PromptPresets") }
    t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) }
    return t
end

function ZeD_MMSandbox:keyEscape()
    if self._cellRow then self:endCell(); return true end
    if self.confirm then self:setConfirm(false); return true end
    if self.find:isFocused() then self.find:unfocus(); return true end
    self:back()
    return true
end

function ZeD_MMSandbox:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self._cellRow then return key == Keyboard.KEY_RETURN end   -- never NEXT while a number is open
    if self.find:isFocused() or self.field:isFocused() or self.cell:isFocused() then return false end
    if self.confirm then return false end
    if key == Keyboard.KEY_RETURN then self:next(); return true end
    return false
end

function ZeD_MMSandbox:close() self:back() end

function ZeD_MMSandbox:wheel(del)
    if self._cellRow then self:commitCell() end
    return ZeD_MMOptions.wheel(self, del)
end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "sandbox" and MM.root and MM.root.sandWin then
        if MM.dropWheel and MM.dropWheel(del) then return true end
        return MM.root.sandWin:wheel(del)
    end
    return _wheel(del)
end

-- on the desk as the "sandbox" view; vanilla's sandOptions:setVisible(true) lands here
MM.addView("sandbox", "sandWin", function() return ZeD_MMSandbox:new() end, "sandOptions")
