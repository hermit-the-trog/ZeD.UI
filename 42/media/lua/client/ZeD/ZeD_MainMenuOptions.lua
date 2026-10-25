-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuOptions.lua
-- ============================================================================
-- OPTIONS (HOOK_MAP row 26; director, Oct 14 2026: "Settings menu is
-- obviously the biggest mess", design delegated, no mockup)
--
-- A ZeD window in place of vanilla's Options: on the desk's monitor at the
-- main menu, centred over the dimmed world in game (from the pause window).
-- Vanilla's MainOptions stays the engine. Its pages and controls are built as
-- always (hidden); this window READS them, every frame, and draws each option
-- with ZeD parts, and a change is made on vanilla's control exactly as a click
-- would (the combo's onChange, the tick box's changeOptionMethod, setVolume,
-- setCurrentValue, a colour button's backgroundColor + gameOptions:onChange).
-- APPLY / ACCEPT run vanilla's MainOptions:apply, so every rule stays vanilla's:
-- what applies live, restart-required options, the screen-settings revert,
-- Lua resets, mod options (PZAPI.ModOptions) saved to ModOptions.ini.
--
-- Rows are discovered, not listed: each page's controls are paired with the
-- label on their row, section titles become headers. Mod options and any
-- future vanilla option show up by themselves.
--
-- What it adds over vanilla:
--   * one Find field across every page
--   * a dot on every option changed since the window opened
--   * the option under the pointer (or the controller) explained in a band
--     at the bottom (vanilla's tooltips)
--   * BACK with changes asks in the action strip: DISCARD or APPLY (and a
--     discard really reverts key bindings; vanilla kept them for the next Apply)
--   * the 20-second "keep these screen settings?" and "restart to apply"
--     are strip states, not pop-ups
--   * binding a key happens in the strip: press the key (or a mouse button),
--     NO KEY / DEFAULT / CANCEL; a key already in use asks there too
--   * LB / RB walk the pages; left / right change a value in place
--   * ZeD setup draws ZeD's own options as switches, swatches, a stepped slider
--     and on/off switches, in five groups, with a Defaults button (Oct 21 2026)
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuOptionGroups"
require "OptionScreens/MainOptions"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local PAGES_W, FIND_H, PAGE_ROW_H = 210, 34, 30
local ROW_H, HEAD_H, HELP_H = 32, 26, 54
local LABEL_SHARE = 0.44
local COMBO_W, SWATCH_W = 280, 48
local INGAME_W, INGAME_H = 1000, 700

local function ms() return MainScreen and MainScreen.instance end
local function mo() local m = ms(); return m and m.mainOptions end

-- vanilla's 84-colour palette (ISColorPicker: three base-6 digits per colour)
local PALETTE = { 555, 303, 304, 403, 503, 314, 315, 505, 414, 523, 524, 525, 535, 545,
                  444, 300, 400, 310, 500, 311, 501, 510, 422, 521, 433, 532, 533, 544,
                  333, 420, 330, 430, 431, 530, 341, 442, 443, 543, 451, 550, 553, 554,
                  222, 20, 121, 30, 132, 230, 141, 142, 50, 52, 243, 250, 343, 353,
                  111, 33, 35, 134, 43, 233, 44, 144, 145, 53, 55, 154, 254, 455,
                  0, 2, 3, 4, 5, 103, 113, 125, 224, 225, 325, 235, 345, 445 }
local function paletteColor(code)
    return { r = math.floor(code / 100) / 5, g = math.fmod(math.floor(code / 10), 10) / 5, b = math.fmod(code, 10) / 5 }
end

-- "DISPLAY & PERFORMANCE" -> "Display & Performance" (a plain loop: Kahlua's gsub with a
-- function replacement broke here, KB Q211)
local function titleCase(s)
    s = tostring(s or "")
    if s:upper() ~= s then return s end
    local out, up = {}, true
    for i = 1, #s do
        local ch = s:sub(i, i)
        if ch:match("%a") then
            out[#out + 1] = up and ch:upper() or ch:lower()
            up = false
        else
            out[#out + 1] = ch
            up = (ch == " " or ch == "(" or ch == "/" or ch == "-")
        end
    end
    local t = table.concat(out)
    t = t:gsub(" And ", " and ")
    t = t:gsub("%(Ui%)", "(UI)")
    return t
end

-- ============================================================================
-- READING VANILLA'S PAGES
-- ============================================================================
local CONTROL = { ISComboBox = "combo", ISTickBox = "tick", ISVolumeControl = "volume", ISMegaVolumeControl = "volume",
                  ISSliderPanel = "slider", ISButton = "button", ISTextEntryBox = "text", ISRichTextPanel = "desc" }
local SPECIAL = { ISControllerBindingsEditorPanel = true, ISControllerTestPanel = true }
local SKIP = { HorizontalLine = true, ISVolumeIndicator = true, ISScrollBar = true }

local function childList(el)
    local t = {}
    local ch = el.getChildren and el:getChildren() or nil
    if ch then for _, c in pairs(ch) do t[#t + 1] = c end end
    return t
end

local function labelText(l)
    local t = l.translation or l.name
    if t == nil and l.getName then t = l:getName() end
    return tostring(t or "")
end

-- every label and control under a page, with absolute positions
local function collect(el, out, depth)
    if depth > 8 then return end
    local kids = childList(el)
    local hasSlider = false
    for _, c in ipairs(kids) do if c.Type == "ISSliderPanel" then hasSlider = true end end
    for _, c in ipairs(kids) do
        local ty = c.Type
        local ok, ax, ay = pcall(function() return c:getAbsoluteX(), c:getAbsoluteY() end)
        if ok then
            if SPECIAL[ty] then
                out.controls[#out.controls + 1] = { kind = "special", el = c, x = ax, y = ay, w = c.width, h = c.height }
            elseif SKIP[ty] then
                -- nothing
            elseif ty == "ISLabel" then
                if not hasSlider then   -- a slider's value label sits beside it; it is not a row label
                    out.labels[#out.labels + 1] = { el = c, x = ax, y = ay, w = c.width or 0, h = c.height or 0, text = labelText(c),
                                                     medium = (c.font == UIFont.Medium) }
                end
            elseif CONTROL[ty] then
                out.controls[#out.controls + 1] = { kind = CONTROL[ty], el = c, x = ax, y = ay, w = c.width, h = c.height }
            else
                collect(c, out, depth + 1)
            end
        end
    end
end

-- the controller page's deadzone stepper (vanilla: a "Deadzone" label over a "-" button, a
-- value label and a "+" button). GameOptionControllerTab only builds the panels, so it is
-- found through a collected button's target.
local function stepperOwner(controls)
    for _, c in ipairs(controls) do
        local t = c.el and c.el.target
        if type(t) == "table" and t.btnJoypadSensitivityM and t.btnJoypadSensitivityP and t.labelJoypadSensitivity then return t end
    end
    return nil
end

-- the rows of a page: headers, options (control + its label), descriptions
function MM.optionRows(page)
    local o = mo()
    if not (o and page and page.view) then return {} end
    local bucket = { labels = {}, controls = {} }
    collect(page.view, bucket, 0)
    -- the deadzone's three parts and its label become one stepper row
    local st = stepperOwner(bucket.controls)
    local stepper = nil
    if st then
        local dzText = getText("UI_optionscreen_gamepad_deadzone")
        local keep = {}
        for _, c in ipairs(bucket.controls) do
            if c.el ~= st.btnJoypadSensitivityM and c.el ~= st.btnJoypadSensitivityP then keep[#keep + 1] = c end
        end
        bucket.controls = keep
        local keepL = {}
        for _, l in ipairs(bucket.labels) do
            if l.el == st.labelJoypadSensitivity then -- the value: drawn in the row
            elseif l.text == dzText and not stepper then
                stepper = { kind = "stepper", label = l.text, owner = st, minus = st.btnJoypadSensitivityM, plus = st.btnJoypadSensitivityP,
                            value = st.labelJoypadSensitivity, y = l.y, x = l.x }
            else keepL[#keepL + 1] = l end
        end
        bucket.labels = keepL
    end
    local optOf = {}
    for _, opt in ipairs(o.gameOptions.options or {}) do if opt.control then optOf[opt.control] = opt end end
    local keyOf = {}
    for _, e in ipairs(MainOptions.keyText or {}) do if not e.value and e.btn then keyOf[e.btn] = e end end
    local used = {}
    local rows = {}
    for _, c in ipairs(bucket.controls) do
        local best, bestRight = nil, -1e9
        for _, l in ipairs(bucket.labels) do
            if not used[l] and not l.medium then
                local right = l.x + l.w
                local sameRow = math.abs((l.y + l.h / 2) - (c.y + math.min(c.h, 40) / 2)) <= math.max(8, math.min(c.h, 40) / 2)
                if sameRow and right <= c.x + 6 and right > bestRight then best, bestRight = l, right end
            end
        end
        if best then used[best] = true end
        local r = { kind = c.kind, control = c.el, label = best and best.text or "", y = c.y, x = c.x, opt = optOf[c.el] }
        -- a lone tick box that carries its own words (vanilla's toggles): the words become
        -- the row's name, so it reads like every other row (Oct 19 2026)
        if c.kind == "tick" and not best and c.el.options and #c.el.options == 1 and tostring(c.el.options[1] or "") ~= "" then
            r.label = tostring(c.el.options[1])
            r.tickNoText = true
        end
        if c.kind == "button" then
            local e = keyOf[c.el]
            if e then r.kind = "key"; r.entry = e
            elseif c.el.backgroundColor and (c.el.title == "" or c.el.title == nil) and optOf[c.el] then r.kind = "color"
            elseif (c.el.title == "" or c.el.title == nil) and c.el.colorPicker then r.kind = "color" end
        end
        if c.kind == "desc" then r.text = UI.plain(c.el.text or "") end
        if c.kind == "special" then r.label = ZeD.tr((c.el.Type == "ISControllerTestPanel") and "UI_ZeD_Options_ControllerTest" or "UI_ZeD_Options_ButtonMap") end
        if not (c.kind == "desc" and (r.text == nil or r.text == "")) then rows[#rows + 1] = r end
    end
    for _, l in ipairs(bucket.labels) do
        if not used[l] and l.text ~= "" then
            rows[#rows + 1] = { kind = l.medium and "header" or "note", text = l.text, y = l.y, x = l.x }
        end
    end
    if stepper then rows[#rows + 1] = stepper end
    table.sort(rows, function(a, b) if math.abs(a.y - b.y) > 2 then return a.y < b.y end; return a.x < b.x end)
    -- the controller page's two special panels become one row
    local out, sawSpecial = {}, false
    for _, r in ipairs(rows) do
        if r.kind == "special" then
            if not sawSpecial then out[#out + 1] = { kind = "special", label = ZeD.tr("UI_ZeD_Options_ButtonMapAndTest") }; sawSpecial = true end
        else
            out[#out + 1] = r
        end
    end
    return out
end

-- the key bindings page: vanilla's own list (MainOptions.keyText), its toggles first
function MM.keyRows(page)
    local rows = {}
    local o = mo()
    local generic = page and MM.optionRows(page) or {}
    local toggles = {}
    for _, r in ipairs(generic) do if r.kind == "tick" then toggles[#toggles + 1] = r end end
    if #toggles > 0 then
        rows[#rows + 1] = { kind = "header", text = ZeD.tr("UI_ZeD_Options_Toggles"), id = "toggles" }   -- (id: ZeD_MainMenuOptionGroups finds this header by it)
        for _, r in ipairs(toggles) do rows[#rows + 1] = r end
    end
    for _, e in ipairs(MainOptions.keyText or {}) do
        if e.value then
            local name = tostring(e.value):gsub("^%[", ""):gsub("%]$", "")
            rows[#rows + 1] = { kind = "header", text = getTextOrNull("UI_optionscreen_binding_" .. name) or name }
        elseif not e.isModBind and e.txt then
            rows[#rows + 1] = { kind = "key", entry = e, label = labelText(e.txt) }
        end
    end
    return rows
end

-- ============================================================================
-- VALUES: read, change (as vanilla's own control would), compare
-- ============================================================================
local function comboText(c, i) local ok, t = pcall(function() return c:getOptionText(i) end); return ok and tostring(t or "") or "" end

local function setCombo(c, i)
    if c.disabled then return end
    c.selected = i
    if c.onChange then c.onChange(c.target, c, c.onChangeArgs and c.onChangeArgs[1], c.onChangeArgs and c.onChangeArgs[2]) end
end

local function tickDisabled(c, i)
    if c.enable == false then return true end
    local name = c.optionsIndex and c.optionsIndex[i]
    return name ~= nil and c.disabledOptions and c.disabledOptions[name] and true or false
end

local function setTick(c, i, v)
    if tickDisabled(c, i) then return end
    c.selected[i] = v
    if c.changeOptionMethod then c.changeOptionMethod(c.changeOptionTarget, i, v, c.changeOptionArg1, c.changeOptionArg2, c) end
end

local function volumeMax(c) return (c.Type == "ISMegaVolumeControl") and 11 or 10 end

local function keyLabel(e)
    if not e then return "" end
    local ok, s = pcall(function() return MainOptions.getKeyPrefix(e) .. getKeyName(e.keyCode or 0) end)
    return ok and s or tostring(e.keyCode)
end

-- a short signature of a row's value (the "changed" dot compares these)
local function sig(r)
    local c = r.control
    if r.kind == "combo" then return tostring(c.selected)
    elseif r.kind == "tick" then
        local t = {}
        for i = 1, #(c.options or {}) do t[#t + 1] = c.selected[i] and "1" or "0" end
        return table.concat(t)
    elseif r.kind == "volume" then return tostring(c.volume)
    elseif r.kind == "slider" then return tostring(c.currentValue)
    elseif r.kind == "color" then local b = c.backgroundColor or {}; return string.format("%.3f%.3f%.3f", b.r or 0, b.g or 0, b.b or 0)
    elseif r.kind == "key" then local e = r.entry; return tostring(e.keyCode) .. tostring(e.shift) .. tostring(e.ctrl) .. tostring(e.alt)
    elseif r.kind == "text" then return tostring(c:getText())
    end
    return nil
end

local function rowKey(r)
    if r.kind == "key" then return "key:" .. tostring(r.entry.txt and r.entry.txt:getName()) end
    if r.opt then return "opt:" .. tostring(r.opt.name) end
    if r.control then return "ctl:" .. tostring(r.control.ID or r.control) end
    return nil
end

-- the option's help: vanilla's tooltip for it, plain
local function help(r)
    local c = r.control
    local t = nil
    pcall(function()
        if r.kind == "combo" then
            local tt = c.tooltip
            if type(tt) == "table" then t = tt[comboText(c, c.selected)] or tt.defaultTooltip
            elseif type(tt) == "string" then t = tt end
            local ot = c:getOptionTooltip(c.selected)
            if ot and ot ~= "" and type(ot) == "string" then t = ot end
        elseif c and c.tooltip and type(c.tooltip) == "string" then
            t = c.tooltip
        end
    end)
    if r.zedTipKey then t = ZeD.tr(r.zedTipKey) end   -- ZeD's own options (ZeD_MainMenuOptionGroups)
    if r.kind == "chord" then
        -- what the chord does, in the pad's own names (ZeD_PadGlyphs)
        local PG = ZeD.PadGlyphs
        local b, f = r.chord:match("^(%a+)%+(%w+)$")
        local nb, nf = PG and PG.name(b) or b, PG and PG.name(f) or f
        local path, words = ZeD.QuickChords.get(r.chord)
        if not path then return ZeD.tr("UI_ZeD_Chord_HelpNone", nb, nf) end
        return ZeD.tr("UI_ZeD_Chord_Help", nb, nf, table.concat(words or {}, " \226\128\186 "))
    end
    if r.kind == "key" then t = ZeD.tr("UI_ZeD_Options_HelpKey") end
    if r.kind == "special" then t = ZeD.tr("UI_ZeD_Options_HelpSpecial") end
    if r.kind == "stepper" then t = ZeD.tr("UI_ZeD_Options_HelpDeadzone") end
    t = t and UI.plain(t) or nil
    -- the groups' marks (ZeD_MainMenuOptionGroups): why it does nothing, where it works, where it lives
    -- (r.moot, r.only[2] and r.why are translation keys or plain words: G.text turns them into the player's language)
    if r.moot then return ZeD.tr("UI_ZeD_Options_MootHelp", MM.optionGroups.text(r.moot)) end
    -- vanilla's tooltips often end without a full stop: add one before ZeD's words
    local function join(a, b)
        if not a or a == "" then return b end
        if not a:match("[%.%!%?]%s*$") then a = a .. "." end
        return a .. " " .. b
    end
    if r.only then t = join(t, MM.optionGroups.text(r.only[2])) end
    if r.why then t = join(t, MM.optionGroups.text(r.why)) end
    return t
end

-- the line under a row's name: does nothing / only somewhere / where it lives
local function underLine(r)
    if r.moot then return ZeD.tr("UI_ZeD_Options_MootUnder") end
    if r.under then return MM.optionGroups.text(r.under) end
    return r.only and MM.optionGroups.text(r.only[1])
end

-- ============================================================================
-- THE KEY CATCHER: a top-level element that takes the next key or mouse button
-- while a binding is being set (vanilla's ISSetKeybindDialog, without the dialog)
-- ============================================================================
ZeD_MMKeyCatcher = ISPanel:derive("ZeD_MMKeyCatcher")

function ZeD_MMKeyCatcher:new(win)
    local o = ISPanel:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    o.win = win
    o.background = false
    o.keepOnScreen = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o:setWantKeyEvents(true)
    o:setWantExtraMouseEvents(true)
    return o
end
function ZeD_MMKeyCatcher:prerender() end
function ZeD_MMKeyCatcher:render() end
function ZeD_MMKeyCatcher:isKeyConsumed(key) return true end
function ZeD_MMKeyCatcher:onKeyRelease(key)
    local shift = Keyboard.isKeyDown(Keyboard.KEY_LSHIFT) or Keyboard.isKeyDown(Keyboard.KEY_RSHIFT)
    local ctrl = Keyboard.isKeyDown(Keyboard.KEY_LCONTROL) or Keyboard.isKeyDown(Keyboard.KEY_RCONTROL)
    local alt = Keyboard.isKeyDown(Keyboard.KEY_LMENU) or Keyboard.isKeyDown(Keyboard.KEY_RMENU)
    if shift and (ctrl or alt) then ctrl, alt = false, false end   -- one modifier, as vanilla
    if ctrl and alt then alt = false end
    -- a modifier on its own is the key itself
    if key == Keyboard.KEY_LSHIFT or key == Keyboard.KEY_RSHIFT then shift = false end
    if key == Keyboard.KEY_LCONTROL or key == Keyboard.KEY_RCONTROL then ctrl = false end
    if key == Keyboard.KEY_LMENU or key == Keyboard.KEY_RMENU then alt = false end
    self.win:gotKey(key, shift, ctrl, alt)
end
function ZeD_MMKeyCatcher:onMouseButtonDown(btn)
    -- a click on the strip's own buttons (NO KEY / DEFAULT / CANCEL) is not a binding
    if self.win:pointerOnStrip() then return end
    self.win:gotKey(Mouse.BTN_OFFSET + btn, false, false, false)
end

-- ============================================================================
-- ZeD_MMOptions
-- ============================================================================
ZeD_MMOptions = ZeD_MMWindow:derive("ZeD_MMOptions")

-- quick action chords (ZeD_QuickChords): the chord's two buttons, and its action's
-- name with where it lives on the wheels (the drawing and the drop list below use them)
local CHEV = " \226\128\186 "   -- (U+203A, the wheels' crumb)
local function chordParts(chord) return chord:match("^(%a+)%+(%w+)$") end
local function chordAction(chord)
    local Qc = ZeD.QuickChords
    local path, words = Qc.get(chord)
    if not path then return nil, nil end
    local w = words or {}
    local where = {}
    for i = 1, #w - 1 do where[#where + 1] = w[i] end
    return w[#w] or "?", table.concat(where, CHEV)
end

function ZeD_MMOptions:new(inGame)
    local o = ZeD_MMWindow.new(self, inGame and "options_ig" or "options")
    o.inGame = inGame and true or false
    o.noResetControl = true
    o.pageIdx = 1
    o.scroll = 0
    o.confirm = false     -- false | "back" | "monitor" | "restart" | "key" | "dup" | "text"
    o.snap = {}
    o.ctx = { hot = nil, press = nil, wasDown = false }   -- in game: its own pointer
    return o
end

-- pop-ups (MM.openPopup) live on the shared context, in game too
function ZeD_MMOptions:pctx() return MM.ctx end

function ZeD_MMOptions:createChildren()
    ZeD_Window.createChildren(self)
    self.find = UI.newEntry(self)
    self.find.onTextChange = function() self.scroll = 0 end
    self.find.onCommandEntered = function() self._enterAt = MM.now(); self.find:unfocus() end
    self.field = UI.newEntry(self)
    self.field:setVisible(false)
    self.field.onCommandEntered = function() self._enterAt = MM.now(); self:commitText() end
    self.field.onEscape = function() self:setConfirm(false) end
end

-- the pages vanilla built (tab title + its panel)
function ZeD_MMOptions:vpages()
    local o = mo()
    local t = {}
    local list = o and o.tabs and o.tabs.viewList or {}
    local keyTitle = getText("UI_optionscreen_keybinding")
    for _, v in ipairs(list) do
        t[#t + 1] = { title = titleCase(v.name), raw = v.name, view = v.view, keys = (v.name == keyTitle) }
    end
    return t
end

-- a vanilla page's rows (cached for two seconds: the pairing walks every
-- control; values are read live anyway)
function ZeD_MMOptions:vrowsFor(page)
    if not page then return {} end
    self._cache = self._cache or {}
    local c = self._cache[page.raw]
    local t = MM.now()
    if c and t - c.at < 2000 then return c.rows end
    local rows = page.keys and MM.keyRows(page) or MM.optionRows(page)
    self._cache[page.raw] = { at = t, rows = rows }
    return rows
end

-- The window's pages are the groups (ZeD_MainMenuOptionGroups: ZeD setup,
-- Display, Graphics, Audio, Controls, Gameplay, Interface, Accessibility,
-- Mods), each re-filed from vanilla's pages.
function ZeD_MMOptions:pages()
    local t = {}
    for _, g in ipairs(MM.optionGroups.GROUPS) do
        t[#t + 1] = { title = MM.optionGroups.text(g.title), raw = g.id, group = true, setup = g.setup }
    end
    return t
end

function ZeD_MMOptions:rowsFor(page)
    if not page then return {} end
    local now = MM.now()
    local gc = self._groupCache
    if not (gc and now - gc.at < 2000) then
        gc = { at = now, rows = MM.optionGroups.build(self:vpages(), function(p) return self:vrowsFor(p) end) }
        self._groupCache = gc
    end
    local rows = gc.rows[page.raw] or {}
    -- the first time ZeD runs, its setup opens by itself with a word on top
    if page.setup and self.firstRun then
        local t = { { kind = "note", text = ZeD.tr("UI_ZeD_Options_FirstRunNote") } }
        for _, r in ipairs(rows) do t[#t + 1] = r end
        return t
    end
    return rows
end

-- how many settings changed since the window opened (ZeD setup's copies not counted twice)
function ZeD_MMOptions:changedCount()
    local n, seen = 0, {}
    for _, p in ipairs(self:pages()) do
        if not p.setup then
            for _, r in ipairs(self:rowsFor(p)) do
                local k = rowKey(r)
                if k and not seen[k] and self:isChanged(r) then seen[k] = true; n = n + 1 end
            end
        end
    end
    return n
end

-- every time Options opens: vanilla's toUI (Core -> controls, live values stored), a fresh snapshot
function ZeD_MMOptions:onShow()
    self._cache = nil
    self._groupCache = nil
    local o = mo()
    if o then pcall(function() o:toUI() end) end
    self.confirm = false
    self.field:setVisible(false)
    self.find:setText("")
    self.scroll = 0
    self.focusId = nil
    self:snapshot()
end
function ZeD_MMOptions:onEnterFromGame() if self:isVisible() then self:onShow() end end

function ZeD_MMOptions:snapshot()
    self.snap = {}
    for _, p in ipairs(self:pages()) do
        for _, r in ipairs(self:rowsFor(p)) do
            local k, s = rowKey(r), sig(r)
            if k and s then self.snap[k] = s end
        end
    end
end

function ZeD_MMOptions:isChanged(r)
    local k, s = rowKey(r), sig(r)
    return k and s and self.snap[k] ~= nil and self.snap[k] ~= s
end

function ZeD_MMOptions:anyChanged()
    local o = mo()
    return o and o.gameOptions.changed and true or false
end

-- CLOSING ---------------------------------------------------------------------

function ZeD_MMOptions:finish()
    self.firstRun = nil
    if self.find:isFocused() then self.find:unfocus() end
    self.confirm = false
    self:stopCapture()
    JoypadState.controllerTest = nil
    if self.inGame then MM.pauseView = "pause" else MM.showView("main") end
end

-- vanilla's BACK: no changes -> reload the keys file and leave
function ZeD_MMOptions:back()
    MM.clickSound()
    if self:anyChanged() then self:setConfirm("back"); return end
    pcall(MainOptions.loadKeys)
    self:finish()
end

-- DISCARD: vanilla's "No" (live values restored), and the key list put back as the file has it
function ZeD_MMOptions:discard()
    local o = mo()
    if o then
        pcall(function() o.gameOptions:restoreOriginalValues() end)
        o.gameOptions.changed = false
        pcall(MainOptions.loadKeys)
        for _, e in ipairs(MainOptions.keyText or {}) do
            if not e.value and e.txt then
                for _, k in ipairs(MainOptions.keys or {}) do
                    if k.value == e.txt:getName() then
                        e.keyCode, e.altCode, e.shift, e.ctrl, e.alt = k.key, k.altCode, k.shift, k.ctrl, k.alt
                        if e.btn then e.btn:setTitle(keyLabel(e)) end
                    end
                end
            end
        end
        pcall(function() o:toUI() end)
    end
    self:finish()
end

-- DISCARD in the footer: the changes go, the window stays
function ZeD_MMOptions:discardStay()
    local fin = self.finish
    self.finish = function() end
    self:discard()
    self.finish = fin
    self.confirm = false
    self._groupCache = nil
    self._cache = nil
    self:snapshot()
end

function ZeD_MMOptions:apply(closeAfter)
    local o = mo()
    if not o then return end
    MM.clickSound()
    self.confirm = false
    self._closeAfter = closeAfter
    o:apply(closeAfter)          -- vanilla: keys, options, mod options, save, then the dialogs (ours, below)
    if not closeAfter and self:isVisible() then self:snapshot() end
end

-- vanilla's dialogs, as strip states (installed on MainOptions in MM.hookOptions)
function ZeD_MMOptions:askMonitor(closeAfter)
    self._closeAfter = closeAfter
    self._monitorUntil = MM.now() + 20000
    self:setConfirm("monitor")
end
function ZeD_MMOptions:answerMonitor(keep)
    local o = mo()
    self.confirm = false
    if o then o:onConfirmMonitorSettingsClick({ internal = keep and "YES" or "NO" }, self._closeAfter) end
    if self:isVisible() then self:snapshot() end
end
function ZeD_MMOptions:askRestart(closeAfter)
    self._closeAfter = closeAfter
    self:setConfirm("restart")
end
function ZeD_MMOptions:answerRestart()
    local o = mo()
    self.confirm = false
    if o then o:onRestartRequiredClick({ internal = "OK" }, self._closeAfter) end
end

-- KEYS --------------------------------------------------------------------------

function ZeD_MMOptions:startCapture(e)
    self._keyEntry = e
    self:setConfirm("key")
    if not self.catcher then
        self.catcher = ZeD_MMKeyCatcher:new(self)
        self.catcher:initialise()
    end
    self.catcher:addToUIManager()
    self.catcher:setAlwaysOnTop(true)
    GameKeyboard.setDoLuaKeyPressed(false)
end

function ZeD_MMOptions:stopCapture()
    if self.catcher then self.catcher:removeFromUIManager() end
    GameKeyboard.setDoLuaKeyPressed(true)
end

function ZeD_MMOptions:pointerOnStrip()
    local mx, my = getMouseX(), getMouseY()
    for _, h in ipairs(self._hits or {}) do
        if h.strip and mx >= h.x and mx < h.x + h.w and my >= h.y and my < h.y + h.h then return true end
    end
    return false
end

local function same(a, b) return (a and true or false) == (b and true or false) end

-- vanilla's keyPressHandler, with the duplicate question in the strip
function ZeD_MMOptions:gotKey(key, shift, ctrl, alt)
    local e = self._keyEntry
    if not e or not key or key <= 0 then return end
    self:stopCapture()
    local dups = {}
    for _, v in ipairs(MainOptions.keyText or {}) do
        if not v.value and v ~= e and v.keyCode == key and same(v.shift, shift) and same(v.ctrl, ctrl) and same(v.alt, alt) then dups[#dups + 1] = v end
    end
    if #dups > 0 then
        self._dup = { key = key, shift = shift, ctrl = ctrl, alt = alt, others = dups }
        self:setConfirm("dup")
        return
    end
    self:assignKey(e, key, shift, ctrl, alt)
    self:setConfirm(false)
end

function ZeD_MMOptions:assignKey(e, key, shift, ctrl, alt)
    local o = mo()
    e.keyCode, e.shift, e.ctrl, e.alt = key, shift, ctrl, alt
    if e.btn then e.btn:setTitle(keyLabel(e)) end
    if o then
        pcall(function() o:onKeybindChanged(e.txt:getName(), key) end)
        o.gameOptions.changed = true
    end
    MM.clickSound()
end

function ZeD_MMOptions:answerDup(clearOthers)
    local d, e = self._dup, self._keyEntry
    if d and e then
        if clearOthers then for _, v in ipairs(d.others) do self:assignKey(v, 0, nil, nil, nil) end end
        self:assignKey(e, d.key, d.shift, d.ctrl, d.alt)
    end
    self._dup = nil
    self:setConfirm(false)
end

-- NO KEY / DEFAULT (vanilla's dialog buttons)
function ZeD_MMOptions:clearKey()
    local e = self._keyEntry
    self:stopCapture()
    if e then self:assignKey(e, 0, nil, nil, nil) end
    self:setConfirm(false)
end
function ZeD_MMOptions:defaultKey()
    local e = self._keyEntry
    self:stopCapture()
    if not e then self:setConfirm(false); return end
    local def = 0
    if e.isModBind then def = e.defaultKeyCode or 0
    else
        for _, v in ipairs(keyBinding or {}) do if v.value == e.txt:getName() then def = v.key or 0 end end
    end
    self:setConfirm(false)
    if def == 0 then self:assignKey(e, 0, nil, nil, nil) else self._keyEntry = e; self:gotKey(def, nil, nil, nil) end
end

-- TEXT FIELDS (a mod's text option) ------------------------------------------------
function ZeD_MMOptions:editText(r)
    self._textRow = r
    self:setConfirm("text")
    self.field:setText(tostring(r.control:getText() or ""))
    self.field:setVisible(true)
    self.field:focus()
end
function ZeD_MMOptions:commitText()
    local r = self._textRow
    if r and self.confirm == "text" then
        r.control:setText(self.field:getText())
        if r.control.onTextChange then r.control.onTextChange(r.control) end
    end
    self:setConfirm(false)
end

-- the controller page's editor + test: vanilla's own page, then back here
function ZeD_MMOptions:openVanillaController(page)
    local o = mo()
    if not o then return end
    MM._vanillaOptions = true
    if not self.inGame then MM.toVanilla() else MM.pauseView = "vanilla" end
    o:setVisible(true, JoypadState.getMainMenuJoypad())
    -- (the groups file the controller page under Controls: open vanilla's own page)
    pcall(function() o.tabs:activateView(getText("UI_optionscreen_controller")) end)
end

function ZeD_MMOptions:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.ctx.open = nil
    if mode ~= "text" then
        self.field:setVisible(false)
        if self.field:isFocused() then self.field:unfocus() end
    end
    if mode ~= "key" then self:stopCapture() end
    self.focusId = mode and "confirm:yes" or self.focusId
end

-- ============================================================================
-- DRAWING
-- ============================================================================
function ZeD_MMOptions:place()
    if not self.inGame then return UI.placeOnTube(self) end
    local T = ZeD.T
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local w = math.min(T.px(INGAME_W), sw - T.px(40))
    local h = math.min(T.px(INGAME_H), sh - T.px(40))
    local x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    return w, h
end

function ZeD_MMOptions:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = self:place()
    local pages = self:pages()
    if self.pageIdx > #pages then self.pageIdx = 1 end
    local page = pages[self.pageIdx]
    local q = string.lower(tostring(self.find:getInternalText() or ""))
    self.title = ZeD.tr("UI_ZeD_Options_Title")
    self.titleStats = {}
    if self:anyChanged() then self.titleStats = { { text = ZeD.tr("UI_ZeD_Options_Changed"), color = T.accent } } end
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local pw = T.px(PAGES_W)
    -- which rows: the page's, or everything matching Find
    local rows
    if q ~= "" then
        rows = {}
        for _, p in ipairs(pages) do
            local hits = {}
            -- (ZeD setup's rows are copies of rows in the other groups: found there)
            for _, r in ipairs(p.setup and {} or self:rowsFor(p)) do
                if r.kind ~= "header" and r.kind ~= "note" and r.kind ~= "desc" then
                    local hay = string.lower(tostring(r.label or "") .. " " .. tostring(help(r) or ""))
                    if hay:find(q, 1, true) then hits[#hits + 1] = r end
                end
            end
            if #hits > 0 then
                rows[#rows + 1] = { kind = "header", text = p.title }
                for _, r in ipairs(hits) do rows[#rows + 1] = r end
            end
        end
        self._findCounts = true
    else
        rows = self:rowsFor(page)
    end
    self:drawPages(pad, bodyY, pw, bodyH, pages, q ~= "")
    self:drawRows(pad * 2 + pw, bodyY, w - pad * 3 - pw, bodyH, rows, page, q ~= "")
    self:buildStrip(stripY, stripH, w)
end

function ZeD_MMOptions:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask)
    -- the strip's buttons are what the key catcher leaves alone
    for _, hh in ipairs(self._hits) do if hh.id and hh.id:find(":confirm:") then hh.strip = true end end
    ZeD_Window.render(self)
end

function ZeD_MMOptions:drawPages(x, y, w, h, pages, finding)
    local T = ZeD.T
    local bs, s2 = T.borderS, T.surf2
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    local fH = T.px(FIND_H)
    self:drawRect(x + T.px(1), y + T.px(1), w - 2 * T.px(1), fH - T.px(1), 1, s2.r, s2.g, s2.b)
    self:drawRect(x, y + fH, w, T.px(1), bs.a, bs.r, bs.g, bs.b)
    local f2, c = T.fontF2, T.text
    local findLabel = ZeD.tr("UI_ZeD_Options_Find")
    self:drawText(findLabel, x + T.px(8), y + math.floor((fH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    local ex = x + T.px(8) + MM.textW(f2, findLabel) + T.px(8)
    local eh = T.px(24)
    UI.styleEntry(self.find, ex, y + math.floor((fH - eh) / 2), x + w - T.px(8) - ex, eh)
    local kind = self.kind
    self._hits[#self._hits + 1] = { id = kind .. ":find", x = ax + self.find.x, y = ay + self.find.y, w = self.find.width, h = self.find.height,
                                    fn = function() self.find:focus() end }
    local ry = y + fH + T.px(1)
    local rh = T.px(PAGE_ROW_H)
    local ac = T.accent
    for i, p in ipairs(pages) do
        local isSel = (i == self.pageIdx) and not finding
        local hid = kind .. ":page:" .. i
        if isSel then self:drawRect(x + T.px(1), ry, w - 2 * T.px(1), rh, 0.22, ac.r, ac.g, ac.b)
        elseif self:pctx().hot == hid then self:drawRect(x + T.px(1), ry, w - 2 * T.px(1), rh, 0.10, ac.r, ac.g, ac.b) end
        local tc = isSel and T.textHead or T.text
        self:drawText(ZeD.Atoms.truncateText(p.title, f2, w - T.px(20)), x + T.px(10), ry + math.floor((rh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        self._hits[#self._hits + 1] = { id = hid, x = ax + x, y = ay + ry, w = w, h = rh, fn = function()
            if self.find:getInternalText() ~= "" then self.find:setText("") end
            if self.pageIdx ~= i then self.pageIdx = i; self.scroll = 0; self.focusId = nil; MM.clickSound() end end }
        ry = ry + rh
    end
end

-- ============================================================================
-- ZeD SETUP'S CONTROLS (Oct 21 2026, mockup ZeDUI/mockups/zed_settings_v2.html)
-- Each of ZeD's own options is still a combo (ModOptions saves its item's number); these
-- draw it as the control that fits it, and a click picks the item exactly as the drop-down
-- would (setCombo). Left / right step it (nudge), A moves to the next choice (activateRow).
-- ============================================================================
local SEG_PAD, SEG_H = 12, 24
local SW_SZ, SW_GAP = 22, 4
local SW_TRACK, SW_KNOB = 44, 18
local SCALE_W, SCALE_MIN = 270, 140

-- the accents in Settings.lua's order (the swatches' items 1..9)
local function accentKeys() return (ZeD.Settings and ZeD.Settings.accentKeys) or {} end

-- an accent's colour for the base theme in use (Light has its own, darker set)
local function accentColor(key)
    local set = ZeD.AccentColors and ZeD.AccentColors[key]
    if not set then return nil end
    local v = (ZeD.currentBase == "light") and set.light or set.dark
    return v and v.accent
end

-- a scale as words: 2 -> "2x", 1.333 -> "1.33x"
local function scaleText(v)
    local s = string.format("%.2f", tonumber(v) or 1):gsub("0+$", ""):gsub("%.$", "")
    return s .. "x"
end

-- what the stepped slider says beside it: the size picked, or what Auto picks on this screen
local function scaleReadout(c)
    if (c.selected or 1) == 1 then
        local root = ZeD.Scale and ZeD.Scale.root and ZeD.Scale.root() or 1
        return ZeD.tr("UI_ZeD_Options_ScaleAutoNow", scaleText(root))
    end
    return comboText(c, c.selected)
end

-- a choice's words on a ZeD control: the short ones where G.ZED_GROUPS gives them, else the item's
local function itemText(r, i)
    local k = r.zedShort and r.zedShort[i]
    if k then return ZeD.tr(k) end
    return comboText(r.control, i)
end

-- the width a ZeD control needs in the space cw (wider: drawn as the drop-down). The window
-- accents' "Same as Accent" button shrinks to a tenth swatch when the button does not fit
-- (r._swCompact, read by drawZedControl).
local function zedWidth(r, cw)
    local T = ZeD.T
    local c = r.control
    local f2 = T.fontF2
    local n = #(c.options or {})
    if r.zedStyle == "seg" then
        local w = 0
        for i = 1, n do w = w + MM.textW(f2, itemText(r, i)) + T.px(SEG_PAD) * 2 end
        return w
    elseif r.zedStyle == "swatch" then
        local k = #accentKeys()
        local w = k * T.px(SW_SZ) + (k - 1) * T.px(SW_GAP)
        r._swCompact = false
        if n > k then
            local full = w + T.px(10) + T.px(30) + MM.textW(f2, ZeD.tr("UI_ZeD_Options_SameAsAccent"))
            if full <= cw then return full end
            r._swCompact = true
            return w + T.px(SW_GAP) + T.px(SW_SZ)
        end
        return w
    elseif r.zedStyle == "scale" then
        return T.px(SCALE_MIN) + T.px(14) + MM.textW(f2, scaleReadout(c))
    elseif r.zedStyle == "onoff" then
        return T.px(SW_TRACK) + T.px(10) + MM.textW(f2, ZeD.upper(getText("UI_Off")))
    end
    return math.huge   -- (no style: the drop-down)
end

function ZeD_MMOptions:drawZedControl(r, cx, ry, cw, rowId, hit)
    local T = ZeD.T
    local c = r.control
    local f2 = T.fontF2
    local bs = T.borderS
    local kind = self.kind
    local hot = self:pctx().hot
    local n = #(c.options or {})
    local sel = c.selected or 1
    local dim = c.disabled and 0.4 or 1
    local midY = ry + math.floor(T.px(ROW_H) / 2)
    local function isHot(id) return hot == kind .. ":" .. id end
    local function pick(i) return function() if i ~= c.selected then setCombo(c, i) end end end

    if r.zedStyle == "seg" then
        -- joined outline buttons; the pick filled with the accent
        local bh = T.px(SEG_H)
        local by = midY - math.floor(bh / 2)
        local x0 = cx
        for i = 1, n do
            local t = itemText(r, i)
            local bw = MM.textW(f2, t) + T.px(SEG_PAD) * 2
            local id = rowId .. ":seg" .. i
            local on = (i == sel)
            local bg = on and T.accent or (isHot(id) and T.surf4 or T.surf3)
            self:drawRect(x0, by, bw, bh, 1, bg.r, bg.g, bg.b)
            if not on then
                -- the System 7 lit edge on the buttons not picked
                local hi = T.chromeHi or T.surf4
                self:drawRect(x0 + T.px(1), by + T.px(1), bw - 2 * T.px(1), T.px(1), hi.a or 1, hi.r, hi.g, hi.b)
            end
            if i > 1 then self:drawRect(x0, by, T.px(1), bh, bs.a, bs.r, bs.g, bs.b) end
            local tc = on and T.textOnAccent or T.text
            self:drawText(t, x0 + T.px(SEG_PAD), by + math.floor((bh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * dim, f2)
            hit(id, x0, by, bw, bh, pick(i), { disabled = c.disabled })
            x0 = x0 + bw
        end
        self:drawRectBorder(cx, by, x0 - cx, bh, bs.a, bs.r, bs.g, bs.b)

    elseif r.zedStyle == "swatch" then
        -- the nine accents; the pick framed in the heading colour
        local keys = accentKeys()
        local sz, gap = T.px(SW_SZ), T.px(SW_GAP)
        local sy = midY - math.floor(sz / 2)
        local th = T.textHead
        local x0 = cx
        local function frame(x, y, w, h)
            self:drawRectBorder(x - T.px(3), y - T.px(3), w + 2 * T.px(3), h + 2 * T.px(3), th.a or 1, th.r, th.g, th.b)
            self:drawRectBorder(x - T.px(2), y - T.px(2), w + 2 * T.px(2), h + 2 * T.px(2), th.a or 1, th.r, th.g, th.b)
        end
        for i, key in ipairs(keys) do
            local col = accentColor(key)
            local id = rowId .. ":sw" .. i
            if col then self:drawRect(x0, sy, sz, sz, dim, col.r, col.g, col.b) end
            self:drawRectBorder(x0, sy, sz, sz, 0.45, 0, 0, 0)
            if i == sel then frame(x0, sy, sz, sz)
            elseif isHot(id) then self:drawRectBorder(x0 - T.px(2), sy - T.px(2), sz + 2 * T.px(2), sz + 2 * T.px(2), 0.6, th.r, th.g, th.b) end
            hit(id, x0, sy, sz, sz, pick(i), { disabled = c.disabled })
            x0 = x0 + sz + gap
        end
        x0 = x0 - gap
        -- a window's accent: "Same as Accent" (the item after the nine), with the Accent color in it
        local follow = #keys + 1
        if n >= follow and r._swCompact then
            -- no room for the button: a tenth swatch, the Accent color ringed (its name shows beside it)
            x0 = x0 + gap
            local id = rowId .. ":same"
            local ac, s1 = T.accent, T.surf1
            self:drawRect(x0, sy, sz, sz, dim, ac.r, ac.g, ac.b)
            self:drawRect(x0 + T.px(5), sy + T.px(5), sz - 2 * T.px(5), sz - 2 * T.px(5), 1, s1.r, s1.g, s1.b)
            self:drawRect(x0 + T.px(8), sy + T.px(8), sz - 2 * T.px(8), sz - 2 * T.px(8), dim, ac.r, ac.g, ac.b)
            self:drawRectBorder(x0, sy, sz, sz, 0.45, 0, 0, 0)
            if sel == follow then frame(x0, sy, sz, sz)
            elseif isHot(id) then self:drawRectBorder(x0 - T.px(2), sy - T.px(2), sz + 2 * T.px(2), sz + 2 * T.px(2), 0.6, th.r, th.g, th.b) end
            hit(id, x0, sy, sz, sz, pick(follow), { disabled = c.disabled })
            x0 = x0 + sz
        elseif n >= follow then
            x0 = x0 + T.px(10)
            local st = ZeD.tr("UI_ZeD_Options_SameAsAccent")
            local chW, chH = T.px(30) + MM.textW(f2, st), T.px(SEG_H)
            local chY = midY - math.floor(chH / 2)
            local id = rowId .. ":same"
            local bg = isHot(id) and T.surf4 or T.surf3
            self:drawRect(x0, chY, chW, chH, 1, bg.r, bg.g, bg.b)
            self:drawRectBorder(x0, chY, chW, chH, bs.a, bs.r, bs.g, bs.b)
            local q = T.px(10)
            local ac = T.accent
            self:drawRect(x0 + T.px(8), midY - math.floor(q / 2), q, q, dim, ac.r, ac.g, ac.b)
            self:drawRectBorder(x0 + T.px(8), midY - math.floor(q / 2), q, q, 0.4, 0, 0, 0)
            local tc = T.text
            self:drawText(st, x0 + T.px(24), chY + math.floor((chH - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * dim, f2)
            if sel == follow then frame(x0, chY, chW, chH) end
            hit(id, x0, chY, chW, chH, pick(follow), { disabled = c.disabled })
            x0 = x0 + chW
        end
        -- the pick's name, when there is room for it
        if sel <= #keys or r._swCompact then
            local name = (sel <= #keys) and comboText(c, sel) or ZeD.tr("UI_ZeD_Options_SameAsAccent")
            local nx = x0 + T.px(12)
            if nx + MM.textW(f2, name) <= cx + cw then
                local d = T.textDim
                self:drawText(name, nx, midY - math.floor(MM.fontH(f2) / 2), d.r, d.g, d.b, d.a or 1, f2)
            end
        end

    elseif r.zedStyle == "scale" then
        -- a stepped track: a tick and its name under every step, Auto at the left
        local ro = scaleReadout(c)
        local tw = math.min(T.px(SCALE_W), cw - T.px(14) - MM.textW(f2, ro))
        local barY = midY - T.px(3)
        local s1, ac = T.surf1, T.accent
        local function stepX(i) return cx + math.floor((i - 1) / math.max(1, n - 1) * tw) end
        self:drawRect(cx, barY, tw, T.px(6), 1, s1.r, s1.g, s1.b)
        self:drawRect(cx, barY, stepX(sel) - cx, T.px(6), dim, ac.r, ac.g, ac.b)
        self:drawRectBorder(cx, barY, tw, T.px(6), bs.a, bs.r, bs.g, bs.b)
        local f1 = T.fontF1
        local d = T.textDim
        -- a tick under every step; a step's name where it does not run into another: the two ends
        -- first, then the rest left to right (all eight at 1x, fewer with Large text)
        local spans = {}
        local function place(i)
            local lt = itemText(r, i)
            local lw = MM.textW(f1, lt)
            local lx = math.max(cx, math.min(cx + tw - lw, stepX(i) - math.floor(lw / 2)))
            for _, sp in ipairs(spans) do
                if lx < sp[2] + T.px(4) and lx + lw + T.px(4) > sp[1] then return end
            end
            spans[#spans + 1] = { lx, lx + lw }
            local lc = (i == sel) and T.text or d
            self:drawText(lt, lx, barY + T.px(12), lc.r, lc.g, lc.b, lc.a or 1, f1)
        end
        for i = 1, n do self:drawRect(stepX(i), barY + T.px(7), T.px(1), T.px(4), bs.a, bs.r, bs.g, bs.b) end
        place(1)
        if n > 1 then place(n) end
        for i = 2, n - 1 do place(i) end
        local id = rowId .. ":sc"
        local thW, thH = T.px(12), T.px(18)
        local thX, thY = stepX(sel) - math.floor(thW / 2), midY - math.floor(thH / 2)
        local tbk = isHot(id) and T.accentBright or T.text
        self:drawRect(thX, thY, thW, thH, 1, tbk.r, tbk.g, tbk.b)
        self:drawRectBorder(thX, thY, thW, thH, bs.a, bs.r, bs.g, bs.b)
        self:drawRect(thX + T.px(1), thY + thH, thW, T.px(1), 0.4, 0, 0, 0)
        local tc = T.text
        self:drawText(ro, cx + tw + T.px(14), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * dim, f2)
        -- a click picks the nearest step (no drag: a new UI scale re-lays the window out under the pointer)
        local ax = self:getAbsoluteX()
        hit(id, cx - T.px(8), thY, tw + T.px(16), thH + MM.fontH(f1), function()
            local f = (getMouseX() - ax - cx) / math.max(1, tw)
            local i = math.max(1, math.min(n, math.floor(f * (n - 1) + 0.5) + 1))
            if i ~= c.selected then setCombo(c, i) end
        end, { disabled = c.disabled })

    elseif r.zedStyle == "onoff" then
        -- square-ended switch: the knob slides right and the track fills when on (red for Safe mode)
        local on = (sel == 2)
        local tw, th = T.px(SW_TRACK), T.px(SEG_H)
        local ty = midY - math.floor(th / 2)
        local id = rowId .. ":onoff"
        local fill = on and (r.zedDanger and T.danger or T.accent) or (isHot(id) and T.surf4 or T.surf3)
        self:drawRect(cx, ty, tw, th, dim, fill.r, fill.g, fill.b)
        if on then self:drawRectBorder(cx, ty, tw, th, 1, fill.r, fill.g, fill.b)
        else self:drawRectBorder(cx, ty, tw, th, bs.a, bs.r, bs.g, bs.b) end
        local kw = T.px(SW_KNOB)
        local kx = on and (cx + tw - T.px(2) - kw) or (cx + T.px(2))
        local kc = on and T.textOnAccent or T.text
        self:drawRect(kx, ty + T.px(2), kw, th - 2 * T.px(2), 1, kc.r, kc.g, kc.b)
        local st = ZeD.upper(getText(on and "UI_On" or "UI_Off"))
        local tc = (on and r.zedDanger) and T.danger or T.text
        self:drawText(st, cx + tw + T.px(10), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * dim, f2)
        hit(id, cx, ty, tw + T.px(10) + MM.textW(f2, st), th, pick(on and 1 or 2), { disabled = c.disabled })
    end
end

-- one row's control, drawn at (cx, ry) in width cw; registers its hit boxes
function ZeD_MMOptions:drawControl(r, cx, ry, cw, rh, rowId, clip)
    local T = ZeD.T
    local c = r.control
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f2 = T.fontF2
    local bs = T.borderS
    local hot = self:pctx().hot
    local ctx = self:pctx()
    local kind = self.kind
    local function hit(id, x, y, w, h, fn, extra)
        if self._inert then return end   -- (a setting that does nothing with ZeD active)
        local top, bot = math.max(y, clip.y), math.min(y + h, clip.y + clip.h)
        if bot <= top then return end
        local hh = { id = kind .. ":" .. id, x = ax + x, y = ay + top, w = w, h = bot - top, fn = fn, sound = true }
        if extra then for k, v in pairs(extra) do hh[k] = v end end
        self._hits[#self._hits + 1] = hh
    end
    local midY = ry + math.floor(rh / 2)
    if r.zedStyle == "scale" then midY = ry + math.floor(T.px(ROW_H) / 2) end   -- (its row is taller: the step names go under it)
    -- ZeD's own options on ZeD setup: the control each one wants (ZeD_MainMenuOptionGroups
    -- G.ZED_GROUPS). Too wide for the space: the drop-down below instead.
    if r.kind == "combo" and r.zedStyle and zedWidth(r, cw) <= cw then
        self:drawZedControl(r, cx, ry, cw, rowId, hit)
        return
    end
    if r.kind == "chord" then
        -- the chord's action in a drop-down box: its name, where it lives on the wheels (dim), the triangle
        local bw = math.min(math.floor(T.px(COMBO_W) * 1.6), cw)
        local bh = T.px(24)
        local by = midY - math.floor(bh / 2)
        local id = rowId .. ":box"
        local s = (hot == kind .. ":" .. id) and T.surf3 or T.surf2
        self:drawRect(cx, by, bw, bh, 1, s.r, s.g, s.b)
        self:drawRectBorder(cx, by, bw, bh, bs.a, bs.r, bs.g, bs.b)
        local name, where = chordAction(r.chord)
        local ty = by + math.floor((bh - MM.fontH(f2)) / 2)
        local tc, d = T.text, T.textDim
        local room = bw - T.px(30)
        if name then
            local nt = ZeD.Atoms.truncateText(name, f2, room)
            self:drawText(nt, cx + T.px(8), ty, tc.r, tc.g, tc.b, tc.a or 1, f2)
            local nw = MM.textW(f2, nt) + T.px(12)
            if where and where ~= "" and nw < room then
                local f3 = T.fontF3
                local wt = ZeD.Atoms.truncateText(where, f3, room - nw)
                self:drawText(wt, cx + bw - T.px(22) - MM.textW(f3, wt), by + math.floor((bh - MM.fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
            end
        else
            self:drawText(ZeD.tr("UI_ZeD_Chord_None"), cx + T.px(8), ty, d.r, d.g, d.b, d.a or 1, f2)
        end
        ZeD.Atoms.drawTriangleDown(self, cx + bw - T.px(16), by + math.floor((bh - T.px(5)) / 2), T.px(8), T.textDim)
        hit(id, cx, by, bw, bh, function() self:openChord(r, { x = ax + cx, y = ay + by, w = bw, h = bh }) end)
        return
    end
    if r.kind == "combo" then
        local bw = math.min(T.px(COMBO_W), cw)
        local bh = T.px(24)
        local by = midY - math.floor(bh / 2)
        local id = rowId .. ":box"
        local s = (hot == kind .. ":" .. id) and T.surf3 or T.surf2
        self:drawRect(cx, by, bw, bh, 1, s.r, s.g, s.b)
        self:drawRectBorder(cx, by, bw, bh, bs.a, bs.r, bs.g, bs.b)
        local tc = T.text
        local a = (tc.a or 1) * (c.disabled and 0.4 or 1)
        self:drawText(ZeD.Atoms.truncateText(comboText(c, c.selected), f2, bw - T.px(30)), cx + T.px(8), by + math.floor((bh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, a, f2)
        ZeD.Atoms.drawTriangleDown(self, cx + bw - T.px(16), by + math.floor((bh - T.px(5)) / 2), T.px(8), T.textDim)
        hit(id, cx, by, bw, bh, function() self:openCombo(r, { x = ax + cx, y = ay + by, w = bw, h = bh }) end, { disabled = c.disabled })
    elseif r.kind == "tick" then
        local cb = T.checkboxSz
        local x0 = cx
        local ly = midY - math.floor(cb / 2)
        for i, name in ipairs(c.options or {}) do
            local text = r.tickNoText and "" or tostring(name or "")
            local tw = (text ~= "") and (MM.textW(f2, text) + T.px(6)) or 0
            if x0 + cb + tw > cx + cw and x0 > cx then x0 = cx; ly = ly + cb + T.px(10) end
            local id = rowId .. ":t" .. i
            local dis = tickDisabled(c, i)
            ZeD.Atoms.drawCheckbox(self, x0, ly, c.selected[i] == true, hot == kind .. ":" .. id, dis)
            if text ~= "" then
                local tc = T.text
                self:drawText(text, x0 + cb + T.px(6), ly + math.floor((cb - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * (dis and 0.4 or 1), f2)
            end
            hit(id, x0 - T.px(2), ly - T.px(4), cb + tw + T.px(6), cb + T.px(8), function() setTick(c, i, not (c.selected[i] == true)); MM.clickSound() end, { disabled = dis })
            x0 = x0 + cb + tw + T.px(16)
        end
    elseif r.kind == "volume" then
        local n = volumeMax(c)
        local bw = math.min(T.px(COMBO_W), cw - T.px(30))
        local bh = T.px(14)
        local by = midY - math.floor(bh / 2)
        local ac = T.accent
        local seg = bw / n
        for i = 1, n do
            local sx = cx + math.floor((i - 1) * seg)
            local sw = math.floor(i * seg) - math.floor((i - 1) * seg) - T.px(2)
            if i <= (c.volume or 0) then self:drawRect(sx, by, sw, bh, 1, ac.r, ac.g, ac.b)
            else local s1 = T.surf1; self:drawRect(sx, by, sw, bh, 1, s1.r, s1.g, s1.b) end
            self:drawRectBorder(sx, by, sw, bh, bs.a, bs.r, bs.g, bs.b)
        end
        local tc = T.text
        self:drawText(tostring(c.volume or 0), cx + bw + T.px(10), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        hit(rowId .. ":vol", cx, by - T.px(4), bw, bh + T.px(8), nil, { drag = function(mx)
            local v = math.max(0, math.min(n, math.ceil((mx - ax - cx) / seg)))
            if v ~= c.volume then c:setVolume(v) end
        end })
    elseif r.kind == "slider" then
        local bw = math.min(T.px(COMBO_W), cw - T.px(50))
        local trY = midY - T.px(3)
        local s1 = T.surf1
        local ac = T.accent
        local minV, maxV = c.minValue or 0, c.maxValue or 1
        local frac = (maxV > minV) and ((c.currentValue or minV) - minV) / (maxV - minV) or 0
        self:drawRect(cx, trY, bw, T.px(6), 1, s1.r, s1.g, s1.b)
        self:drawRect(cx, trY, math.floor(bw * frac), T.px(6), 1, ac.r, ac.g, ac.b)
        self:drawRectBorder(cx, trY, bw, T.px(6), bs.a, bs.r, bs.g, bs.b)
        local thW, thH = T.px(12), T.px(18)
        local thX = cx + math.floor(bw * frac) - math.floor(thW / 2)
        local thY = midY - math.floor(thH / 2)
        local tbk = (hot == kind .. ":" .. rowId .. ":sl") and T.accentBright or T.surf3
        self:drawRect(thX, thY, thW, thH, tbk.a or 1, tbk.r, tbk.g, tbk.b)
        self:drawRect(thX, thY, thW, T.px(1), T.surf4.a or 1, T.surf4.r, T.surf4.g, T.surf4.b)
        self:drawRect(thX, thY, T.px(1), thH, T.surf4.a or 1, T.surf4.r, T.surf4.g, T.surf4.b)
        self:drawRect(thX, thY + thH - T.px(1), thW, T.px(1), 1, 0, 0, 0)
        self:drawRect(thX + thW - T.px(1), thY, T.px(1), thH, 1, 0, 0, 0)
        local step = c.stepValue or 1
        local txt = (step < 1) and string.format("%.2f", c.currentValue or 0) or tostring(math.floor((c.currentValue or 0) + 0.5))
        local tc = T.text
        self:drawText(txt, cx + bw + T.px(12), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        hit(rowId .. ":sl", cx - T.px(6), thY, bw + T.px(12), thH, nil, { drag = function(mx)
            local f = math.max(0, math.min(1, (mx - ax - cx) / math.max(1, bw)))
            c:setCurrentValue(minV + (maxV - minV) * f)
        end })
    elseif r.kind == "color" then
        local sw, sh = T.px(SWATCH_W), T.px(22)
        local sy = midY - math.floor(sh / 2)
        local b = c.backgroundColor or { r = 1, g = 1, b = 1 }
        self:drawRect(cx, sy, sw, sh, 1, b.r or 1, b.g or 1, b.b or 1)
        self:drawRectBorder(cx, sy, sw, sh, bs.a, bs.r, bs.g, bs.b)
        if hot == kind .. ":" .. rowId .. ":sw" then self:drawRectBorder(cx - T.px(2), sy - T.px(2), sw + 2 * T.px(2), sh + 2 * T.px(2), 1, T.accent.r, T.accent.g, T.accent.b) end
        hit(rowId .. ":sw", cx, sy, sw, sh, function() self:openPalette(r, { x = ax + cx, y = ay + sy, w = sw, h = sh }) end)
    elseif r.kind == "key" then
        local text = keyLabel(r.entry)
        local capturing = (self.confirm == "key" and self._keyEntry == r.entry)
        local bw = math.max(T.px(90), MM.textW(T.fontF3, text) + T.px(24))
        local b = { x = cx, y = midY - math.floor(T.px(26) / 2), w = bw, h = T.px(26), text = capturing and ZeD.tr("UI_ZeD_Options_PressKey") or text, variant = capturing and "primary" or "default", keepCase = not capturing }
        local id = rowId .. ":key"
        MM.drawBtn(self, b, hot == kind .. ":" .. id, false, false)
        hit(id, b.x, b.y, b.w, b.h, function() self:startCapture(r.entry) end)
    elseif r.kind == "button" then
        local text = tostring(c.title or "")
        local b = { x = cx, y = midY - math.floor(T.px(26) / 2), w = MM.textW(T.fontF3, text) + T.px(28), h = T.px(26), text = text, variant = "default", disabled = (c.enable == false) }
        local id = rowId .. ":btn"
        MM.drawBtn(self, b, hot == kind .. ":" .. id, false, false)
        hit(id, b.x, b.y, b.w, b.h, function()
            if c.onclick then c.onclick(c.target, c, c.onClickArgs and c.onClickArgs[1], c.onClickArgs and c.onClickArgs[2]) end
        end, { disabled = b.disabled })
    elseif r.kind == "text" then
        local bw = math.min(T.px(COMBO_W) * 1.4, cw)
        local bh = T.px(24)
        local by = midY - math.floor(bh / 2)
        UI.insetBox(self, cx, by, bw, bh)
        local tc = T.text
        self:drawText(ZeD.Atoms.truncateText(tostring(c:getText() or ""), f2, bw - T.px(12)), cx + T.px(6), by + math.floor((bh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        hit(rowId .. ":txt", cx, by, bw, bh, function() self:editText(r) end)
    elseif r.kind == "stepper" then
        -- the deadzone: [-] value [+] on vanilla's buttons (off until a test controller is chosen)
        local bh = T.px(26)
        local by = midY - math.floor(bh / 2)
        local gap = T.px(8)
        local off = (r.minus.enable == false)
        -- the live value: vanilla's label reads it right after a step, before the engine has
        -- applied it, so it showed the value one press behind
        local tp = r.owner and r.owner.controllerTestPanel
        local ctrl = tp and tp.selectedController
        local val
        if off then val = ZeD.tr("UI_ZeD_Options_PickController")
        elseif ctrl then val = string.format("%.2f", getControllerDeadZone(ctrl, 0))
        else val = tostring(r.value.name or "") end
        local vw = math.max(T.px(64), MM.textW(f2, val) + T.px(16))
        local function step(id, text, x, btn)
            local b = { x = x, y = by, w = bh, h = bh, text = text, variant = "default", disabled = (btn.enable == false) }
            MM.drawBtn(self, b, hot == kind .. ":" .. id, false, false)
            hit(id, b.x, b.y, b.w, b.h, function() if btn.onclick then btn.onclick(btn.target, btn) end end, { disabled = b.disabled })
        end
        step(rowId .. ":dzm", "-", cx, r.minus)
        local tc = off and T.textDim or T.text
        local vx = cx + bh + gap
        self:drawText(val, vx + math.floor((vw - MM.textW(f2, val)) / 2), midY - math.floor(MM.fontH(f2) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        step(rowId .. ":dzp", "+", vx + vw + gap, r.plus)
    elseif r.kind == "special" then
        local text = ZeD.tr("UI_ZeD_Options_OpenController")
        local b = { x = cx, y = midY - math.floor(T.px(26) / 2), w = MM.textW(T.fontF3, text) + T.px(28), h = T.px(26), text = text, variant = "default" }
        local id = rowId .. ":spc"
        MM.drawBtn(self, b, hot == kind .. ":" .. id, false, false)
        local pages = self:pages()
        hit(id, b.x, b.y, b.w, b.h, function() self:openVanillaController(pages[self.pageIdx]) end)
    end
end

-- the height a row needs (a tick box with many options wraps)
function ZeD_MMOptions:rowHeight(r, cw)
    local T = ZeD.T
    if r.kind == "header" then return T.px(HEAD_H) + T.px(6) end
    if r.kind == "note" or r.kind == "desc" then
        local lines = ZeD.Atoms.wrapText(r.text or "", T.fontF2, cw)
        return math.max(1, #lines) * (MM.fontH(T.fontF2) + T.px(3)) + T.px(8)
    end
    if r.kind == "tick" and #(r.control.options or {}) > 1 then
        local f2, cb = T.fontF2, T.checkboxSz
        local x0, lines = 0, 1
        for _, name in ipairs(r.control.options) do
            local tw = (tostring(name or "") ~= "") and (MM.textW(f2, tostring(name)) + T.px(6)) or 0
            if x0 + cb + tw > cw and x0 > 0 then x0 = 0; lines = lines + 1 end
            x0 = x0 + cb + tw + T.px(16)
        end
        return math.max(T.px(ROW_H), lines * (cb + T.px(10)) + T.px(12)) + (underLine(r) and MM.fontH(T.fontF1) or 0)
    end
    -- UI scale's stepped slider: the step names go under the track
    if r.zedStyle == "scale" then return T.px(ROW_H) + MM.fontH(T.fontF1) + T.px(6) end
    -- a row with a line under its name grows by that line
    if underLine(r) then return T.px(ROW_H) + MM.fontH(T.fontF1) + T.px(2) end
    return T.px(ROW_H)
end

function ZeD_MMOptions:drawRows(x, y, w, h, rows, page, finding)
    local T = ZeD.T
    local bs = T.borderS
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    -- the help band: three lines of the body font (Oct 21 2026: two cut the longer ZeD tips short)
    -- (a window without help text has no band; one with its own band says how tall: Sandbox in game)
    local helpH = self.noHelpBand and 0 or (self.helpBandH and self:helpBandH()) or math.max(T.px(HELP_H), T.px(14) + 3 * (MM.fontH(T.fontF2) + T.px(3)))
    local vy, vh = y + T.px(1), h - helpH - T.px(2)
    local sbW = T.sp.scrollbarW
    local inner = w - T.px(2) - sbW
    local lw = math.floor(inner * LABEL_SHARE)
    local cx0 = x + T.px(1) + lw + T.px(12)
    local tagsW = self.tagsW and self:tagsW() or 0   -- (room at the right for a row's tags: Sandbox in game)
    local cw = x + inner - T.px(10) - cx0 - tagsW
    -- layout pass
    local total = 0
    for _, r in ipairs(rows) do r._h = self:rowHeight(r, (r.kind == "note" or r.kind == "desc") and (inner - T.px(24)) or cw); total = total + r._h end
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, total - vh)))
    self._list = { x = x, y = vy, w = w, h = vh }
    local gp = MM.gamepad()
    local ac = T.accent
    local f2 = T.fontF2
    local clip = { y = vy, h = vh }
    local focusRow = nil
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    local ry = vy - self.scroll
    local idx = 0
    local hovered = nil
    local mx, my = getMouseX() - ax, getMouseY() - ay
    for i, r in ipairs(rows) do
        local rh = r._h
        local visible = ry + rh > vy and ry < vy + vh
        if r.kind == "header" then
            if visible then
                ZeD.Molecules.drawSectionHeader(self, x + T.px(12), ry + T.px(3), inner - T.px(12), ZeD.upper(tostring(r.text)), nil, true, false, T.fontF1, false, T.px(11), T.px(HEAD_H), true)
            end
        elseif r.kind == "note" or r.kind == "desc" then
            if visible then
                local d = T.textDim
                local ly = ry + T.px(4)
                for _, l in ipairs(ZeD.Atoms.wrapText(r.text or "", f2, inner - T.px(24))) do
                    self:drawText(l, x + T.px(12), ly, d.r, d.g, d.b, d.a or 1, f2)
                    ly = ly + MM.fontH(f2) + T.px(3)
                end
            end
        else
            idx = idx + 1
            local rowId = "r" .. i
            local fid = "orow:" .. idx
            self._specs[#self._specs + 1] = { id = fid, listRow = true, row = idx, col = 1, rowRef = r, ry = ry + self.scroll - vy, rh = rh,
                fn = function() self:activateRow(r) end }
            if gp and self.focusId == fid then focusRow = r end
            if visible then
                if gp and self.focusId == fid then self:drawRect(x + T.px(1), ry, inner, rh, 0.55, ac.r, ac.g, ac.b) end
                if mx >= x and mx < x + inner and my >= ry and my < ry + rh and my >= vy and my < vy + vh then hovered = r end
                -- the changed dot, the label
                local lx = x + T.px(12)
                if self:isChanged(r) then
                    local dsz = T.px(7)
                    ZeD.Atoms.drawStatusDot(self, lx, ry + math.floor((T.px(ROW_H) - dsz) / 2), T.accent, dsz)
                end
                lx = lx + T.px(14)
                local tc = T.text
                if self.rowDisabled and self:rowDisabled(r) then tc = T.textDim end   -- (Sandbox: an option that does nothing now)
                if r.moot then tc = T.textDim end
                local label = r.label ~= "" and r.label or ""
                if r.labelKey then label = ZeD.tr(r.labelKey) end   -- ZeD's own options: read at draw time (test language)
                local PG = ZeD.PadGlyphs
                if r.kind == "chord" and PG and PG.set() then
                    -- a quick action chord's name is its two buttons, as ZeD's pictures (ZeD_PadGlyphs)
                    local b, f = chordParts(r.chord)
                    local k = PG.k(MM.fontH(f2))
                    local gx = lx + PG.draw(self, { b }, lx, ry, T.px(ROW_H), k) + T.px(4)
                    self:drawText("+", gx, ry + math.floor((T.px(ROW_H) - MM.fontH(f2)) / 2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f2)
                    PG.draw(self, { f }, gx + MM.textW(f2, "+") + T.px(4), ry, T.px(ROW_H), k)
                    label = ""
                elseif r.kind == "chord" then
                    label = r.chord:gsub("%+", " + ")
                end
                self:drawText(ZeD.Atoms.truncateText(label, f2, lw - T.px(26)), lx, ry + math.floor((T.px(ROW_H) - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
                -- the line under the name (Does nothing with ZeD active / Only ... / Game: where it lives)
                local ul = underLine(r)
                if ul then
                    local f1 = T.fontF1
                    local uc = r.moot and T.warning or T.textDim
                    self:drawText(ZeD.Atoms.truncateText(ul, f1, lw - T.px(26)), lx, ry + T.px(ROW_H) - T.px(6), uc.r, uc.g, uc.b, uc.a or 1, f1)
                end
                local crh = (r.kind == "tick" and #(r.control.options or {}) > 1) and T.px(ROW_H) or (ul and T.px(ROW_H) or rh)
                -- a setting that does nothing with ZeD active: its control drawn, dimmed, and inert
                self._inert = r.moot and true or false
                self:drawControl(r, cx0, ry, cw, crh, rowId, clip)
                self._inert = false
                if self.drawRowTags then self:drawRowTags(r, x + inner - T.px(10), ry, crh) end
                if r.moot then
                    -- dim just the control (a drop-down's box, a bar and its number, else the row's control area)
                    local dw = cw
                    if r.kind == "combo" then dw = math.min(T.px(COMBO_W), cw)
                    elseif r.kind == "volume" or r.kind == "slider" then dw = math.min(T.px(COMBO_W) + T.px(50), cw) end
                    local s1 = T.surf1
                    self:drawRect(cx0 - T.px(2), ry + T.px(2), dw + 2 * T.px(2), crh - 2 * T.px(2), 0.6, s1.r, s1.g, s1.b)
                end
            end
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    -- the scroll bar
    if total > vh then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / total))
        local tyy = vy + math.floor((vh - th) * self.scroll / (total - vh))
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, th, self:pctx().hot == self.kind .. ":track" and "hover" or "default")
        self._hits[#self._hits + 1] = { id = self.kind .. ":track", x = ax + sx, y = ay + vy, w = sbW, h = vh, drag = function(_, myy)
            self.scroll = math.floor(((myy - ay - vy) / vh) * total - vh / 2) end }
    end
    if #rows == 0 then
        local d = T.textDim
        self:drawText(finding and ZeD.tr("UI_ZeD_Options_NoMatch") or "", x + T.px(12), vy + T.px(12), d.r, d.g, d.b, d.a or 1, f2)
    end
    -- the help band: the option under the pointer (or the controller's)
    if helpH == 0 then return end
    local hy = y + h - helpH
    local s2 = T.surf2
    self:drawRect(x + T.px(1), hy, w - 2 * T.px(1), helpH - T.px(1), 1, s2.r, s2.g, s2.b)
    self:drawRect(x + T.px(1), hy, w - 2 * T.px(1), T.px(1), bs.a, bs.r, bs.g, bs.b)
    local hr = self._cellRow or focusRow or ((not MM.ctx.open and not self._palette) and hovered or nil)   -- (_cellRow: a row edited in place)
    if self.drawHelp then self:drawHelp(x, hy, w, helpH, hr); return end   -- (a window with its own band: Sandbox in game)
    local htext = hr and help(hr) or nil
    if hr and not htext and self:isChanged(hr) then htext = self.changedNote and MM.optionGroups.text(self.changedNote) or ZeD.tr("UI_ZeD_Options_ChangedNote") end
    -- ZeD's own options: their default in a column at the right of the band (mockup zed_settings_v2)
    local dcol = 0
    local chordDefault = hr and hr.kind == "chord" and ZeD.QuickChords.defaultName(hr.chord) or nil
    if (hr and hr.zedDefault and hr.control) or chordDefault then
        local dt = ZeD.tr("UI_ZeD_Options_DefaultIs", chordDefault or comboText(hr.control, hr.zedDefault))
        dcol = math.min(T.px(240), MM.textW(f2, dt) + T.px(26))
        local dx = x + w - T.px(1) - dcol
        local bd, d = T.border, T.textDim
        self:drawRect(dx, hy + T.px(7), T.px(1), helpH - 2 * T.px(7), bd.a or 1, bd.r, bd.g, bd.b)
        self:drawText(ZeD.Atoms.truncateText(dt, f2, dcol - T.px(24)), dx + T.px(12), hy + T.px(8), d.r, d.g, d.b, d.a or 1, f2)
    end
    if htext then
        local tc = T.text
        local ly = hy + T.px(8)
        for k, l in ipairs(ZeD.Atoms.wrapText(htext, f2, w - T.px(24) - dcol)) do
            if k > 3 then break end
            self:drawText(l, x + T.px(12), ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
            ly = ly + MM.fontH(f2) + T.px(3)
        end
    end
end

-- POP-UPS -------------------------------------------------------------------------

function ZeD_MMOptions:openCombo(r, anchor)
    local c = r.control
    if c.disabled then return end
    local items = {}
    for i = 1, #(c.options or {}) do
        local t = comboText(c, i)
        items[#items + 1] = { text = (i == c.selected) and (t .. "  " .. string.char(171)) or t, fn = function() setCombo(c, i) end }
    end
    MM.openPopup("combo", items, anchor, false)
    MM.ctx.dropFocus = c.selected or 1
    -- a long list opens with its current value in view
    MM.ctx.dropScroll = math.max(0, ((c.selected or 1) - 4) * ZeD.T.px(26))
end

-- QUICK ACTION CHORDS (ZeD_QuickChords; mockup zed_quick_chords_v1): a row per
-- chord; A opens the wheels' actions as a drop list, X clears it.
-- The wheels' actions, a drop list item each, under its wheel's name; None first
function ZeD_MMOptions:openChord(r, anchor)
    local Qc = ZeD.QuickChords
    local p = getSpecificPlayer(0)
    local items = { { text = ZeD.tr("UI_ZeD_Chord_None"), fn = function() Qc.clear(r.chord); MM.clickSound() end } }
    local cur = Qc.get(r.chord)
    local focus = 1
    if not p then
        items[#items + 1] = "-"
        items[#items + 1] = { text = ZeD.tr("UI_ZeD_Chord_LoadGame"), disabled = true }
    else
        for _, wheel in ipairs(Qc.catalog(p, 0)) do
            items[#items + 1] = "-"
            items[#items + 1] = { text = ZeD.upper(wheel.title), disabled = true }
            for _, a in ipairs(wheel.actions) do
                local t = a.text
                if a.path == cur then t = t .. "  " .. string.char(171); focus = #items + 1 end
                items[#items + 1] = { text = t, fn = function() Qc.set(r.chord, a.path, a.words); MM.clickSound() end }
            end
        end
    end
    MM.openPopup("combo", items, anchor, false)
    -- (the live rows the controller walks: None and the actions; the one in use in view)
    local live = 0
    for i = 1, focus do local it = items[i]; if type(it) == "table" and not it.disabled then live = live + 1 end end
    MM.ctx.dropFocus = math.max(1, live)
    MM.ctx.dropScroll = math.max(0, (focus - 5) * ZeD.T.px(26))
end

-- vanilla's palette as a pop-up of swatches (a ZeD drop with colour rows would not read)
function ZeD_MMOptions:openPalette(r, anchor)
    self._palette = { row = r, anchor = anchor }
    MM.clickSound()
end

function ZeD_MMOptions:pickColor(col)
    local p = self._palette
    self._palette = nil
    if not p then return end
    local c = p.row.control
    c.backgroundColor = { r = col.r, g = col.g, b = col.b, a = 1 }
    local o = mo()
    if o and p.row.opt then o.gameOptions:onChange(p.row.opt) end
    MM.clickSound()
end

-- the palette draws over the window (in render, after the rows)
local _render = ZeD_MMOptions.render
function ZeD_MMOptions:render()
    _render(self)
    if MM.debugHits and self.inGame then MM.drawHitOverlay(self, { self }) end   -- (QA: the click audit; at the menu the desk's glass draws it)
    local p = self._palette
    if not p then return end
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local cell = T.px(20)
    local cols, rowsN = 14, 6
    local pw, ph = cols * cell + T.px(8), rowsN * cell + T.px(8)
    local px = math.min(p.anchor.x - ax, self.width - pw - T.px(8))
    local py = p.anchor.y - ay + p.anchor.h + T.px(4)
    if py + ph > self.height - T.px(8) then py = p.anchor.y - ay - ph - T.px(4) end
    local s1, bs = T.surf1, T.borderS
    ZeD.Atoms.drawSteppedShadow(self, px, py, pw, ph, { r = 0, g = 0, b = 0, a = 0.55 })
    self:drawRect(px, py, pw, ph, 1, s1.r, s1.g, s1.b)
    self:drawRectBorder(px, py, pw, ph, bs.a, bs.r, bs.g, bs.b)
    local cur = p.row.control.backgroundColor or {}
    -- the pop-up's frame takes a click itself (nothing happens), so it never reaches the row under it
    self._hits[#self._hits + 1] = { id = self.kind .. ":pal", x = ax + px, y = ay + py, w = pw, h = ph }
    for i, code in ipairs(PALETTE) do
        local col = paletteColor(code)
        local cx = px + T.px(4) + ((i - 1) % cols) * cell
        local cy = py + T.px(4) + math.floor((i - 1) / cols) * cell
        self:drawRect(cx + T.px(1), cy + T.px(1), cell - 2 * T.px(1), cell - 2 * T.px(1), 1, col.r, col.g, col.b)
        local isCur = math.abs((cur.r or -1) - col.r) < 0.02 and math.abs((cur.g or -1) - col.g) < 0.02 and math.abs((cur.b or -1) - col.b) < 0.02
        if isCur or self:pctx().hot == self.kind .. ":pal:" .. i then
            self:drawRectBorder(cx, cy, cell, cell, 1, T.text.r, T.text.g, T.text.b)
        end
        self._hits[#self._hits + 1] = { id = self.kind .. ":pal:" .. i, x = ax + cx, y = ay + cy, w = cell, h = cell, fn = function() self:pickColor(col) end }
    end
    -- anywhere else closes it
    self._paletteRect = { x = ax + px, y = ay + py, w = pw, h = ph }
end

-- ACTIVATING A ROW (A on a controller, Space / Return on the keyboard) ---------------
function ZeD_MMOptions:activateRow(r)
    if r.moot then return end   -- does nothing with ZeD active: inert here too
    local c = r.control
    if r.kind == "combo" and r.zedStyle then
        -- ZeD setup's switches, swatches and slider: the next choice (an on/off flips)
        local n = #(c.options or {})
        if n > 0 and not c.disabled then setCombo(c, (c.selected or 1) % n + 1); MM.clickSound() end
    elseif r.kind == "combo" then
        local anchor = { x = self:getAbsoluteX() + self.width / 2, y = self:getAbsoluteY() + self.height / 3, w = ZeD.T.px(COMBO_W), h = ZeD.T.px(24) }
        self:openCombo(r, anchor)
    elseif r.kind == "tick" then
        local i = self._tickCol or 1
        setTick(c, i, not (c.selected[i] == true)); MM.clickSound()
    elseif r.kind == "key" then self:startCapture(r.entry)
    elseif r.kind == "button" then if c.onclick then c.onclick(c.target, c) end
    elseif r.kind == "color" then self:openPalette(r, { x = self:getAbsoluteX() + self.width / 2, y = self:getAbsoluteY() + self.height / 3, w = 10, h = 10 })
    elseif r.kind == "text" then self:editText(r)
    elseif r.kind == "special" then self:openVanillaController(self:pages()[self.pageIdx])
    elseif r.kind == "chord" then
        self:openChord(r, { x = self:getAbsoluteX() + self.width / 2, y = self:getAbsoluteY() + self.height / 4, w = math.floor(ZeD.T.px(COMBO_W) * 1.6), h = ZeD.T.px(24) })
    end
end

-- left / right change a value in place (combo: previous / next; volume / slider: a step)
function ZeD_MMOptions:nudge(r, dir)
    if r.moot then return true end
    local c = r.control
    if r.kind == "combo" then
        local n = #(c.options or {})
        local i = math.max(1, math.min(n, (c.selected or 1) + dir))
        if i ~= c.selected then setCombo(c, i); MM.hoverSound() end
        return true
    elseif r.kind == "volume" then
        local v = math.max(0, math.min(volumeMax(c), (c.volume or 0) + dir))
        if v ~= c.volume then c:setVolume(v); MM.hoverSound() end
        return true
    elseif r.kind == "slider" then
        c:setCurrentValue((c.currentValue or 0) + dir * (c.stepValue or 1)); MM.hoverSound()
        return true
    elseif r.kind == "tick" and #(c.options or {}) > 1 then
        self._tickCol = math.max(1, math.min(#c.options, (self._tickCol or 1) + dir))
        return true
    elseif r.kind == "stepper" then
        local b = (dir < 0) and r.minus or r.plus
        if b.enable ~= false and b.onclick then b.onclick(b.target, b); MM.hoverSound() end
        return true
    end
    return false
end

-- ZeD setup's DEFAULTS: every one of ZeD's own options back on the item it starts on (the game
-- settings below them are the game's, left alone). Like any change here it waits for Apply.
function ZeD_MMOptions:zedSetupRows()
    for _, p in ipairs(self:pages()) do if p.setup then return self:rowsFor(p) end end
    return {}
end
function ZeD_MMOptions:zedOffDefault()
    for _, r in ipairs(self:zedSetupRows()) do
        if r.zedDefault and r.control and r.control.selected ~= r.zedDefault then return true end
        if r.kind == "chord" and not ZeD.QuickChords.isDefault(r.chord) then return true end
    end
    return false
end
function ZeD_MMOptions:zedDefaults()
    for _, r in ipairs(self:zedSetupRows()) do
        local c = r.control
        if r.zedDefault and c and not c.disabled and c.selected ~= r.zedDefault then setCombo(c, r.zedDefault) end
        if r.kind == "chord" then ZeD.QuickChords.reset(r.chord) end   -- (the chords keep no Apply: back to their start at once)
    end
end

-- THE STRIP -----------------------------------------------------------------------
function ZeD_MMOptions:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    local ask = nil
    if self.confirm == "back" then
        -- (Oct 19 2026: Apply keeps the window open, so Back with changes only
        -- asks whether to lose them; the old Accept is gone)
        local n = self:changedCount()
        ask = (n == 1) and ZeD.tr("UI_ZeD_Options_AskDiscardOne") or ZeD.tr("UI_ZeD_Options_AskDiscardMany", math.max(n, 1))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", ZeD.tr("UI_ZeD_Options_KeepEditing"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Options_Discard"), function() self:discard() end, "primary" } })
    elseif self.confirm == "discard" then
        local n = self:changedCount()
        ask = (n == 1) and ZeD.tr("UI_ZeD_Options_AskDiscardOne") or ZeD.tr("UI_ZeD_Options_AskDiscardMany", math.max(n, 1))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", ZeD.tr("UI_ZeD_Options_KeepEditing"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Options_Discard"), function() self:discardStay() end, "primary" } })
    elseif self.confirm == "monitor" then
        local left = math.max(0, math.ceil(((self._monitorUntil or 0) - MM.now()) / 1000))
        if left <= 0 then self:answerMonitor(false); return self:buildStrip(stripY, stripH, w) end
        ask = (left == 1) and ZeD.tr("UI_ZeD_Options_AskMonitorOne") or ZeD.tr("UI_ZeD_Options_AskMonitorMany", left)
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", ZeD.tr("UI_ZeD_Options_GoBack"), function() self:answerMonitor(false) end },
            { "confirm:yes", getText("ContextMenu_Keep"), function() self:answerMonitor(true) end, "primary" } })
    elseif self.confirm == "restart" then
        ask = MM.ui.plain(getText("UI_restart_game_to_apply"))
        UI.stripSpecs(self, stripY, w, row, {}, { { "confirm:yes", ZeD.upper(ZeD.tr("UI_Ok")), function() self:answerRestart() end, "primary" } })
    elseif self.confirm == "key" then
        local e = self._keyEntry
        ask = ZeD.tr("UI_ZeD_Options_AskKey", (e and e.txt and labelText(e.txt) or ZeD.tr("UI_ZeD_Options_AskKeyIt")))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:clear", ZeD.tr("UI_ZeD_Options_NoKey"), function() self:clearKey() end },
            { "confirm:default", ZeD.tr("UI_ZeD_Options_KeyDefault"), function() self:defaultKey() end },
            { "confirm:no", getText("UI_btn_cancel"), function() self:stopCapture(); self:setConfirm(false) end } })
    elseif self.confirm == "dup" then
        local d = self._dup
        local other = d and d.others[1] and d.others[1].txt and labelText(d.others[1].txt) or ""
        local fake = d and { keyCode = d.key, shift = d.shift, ctrl = d.ctrl, alt = d.alt } or nil
        ask = ZeD.tr("UI_ZeD_Options_AskDup", keyLabel(fake), other)
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self._dup = nil; self:setConfirm(false) end },
            { "confirm:both", getText("UI_optionscreen_KeybindKeep"), function() self:answerDup(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Options_TakeIt"), function() self:answerDup(true) end, "primary" } })
    elseif self.confirm == "text" then
        ask = ZeD.tr("UI_ZeD_Options_AskValue")
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Options_Set"), function() self:commitText() end, "primary" } })
        local f2 = T.fontF2
        local fx = T.px(U.STRIP_PAD_X) + T.px(4) + MM.textW(f2, ask) + T.px(10)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        UI.styleEntry(self.field, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    else
        -- Back (| Defaults on ZeD setup) | Discard, Apply (Apply keeps the window open)
        local changed = self:anyChanged()
        local lefts = { { "back", getText("UI_btn_back"), function() self:back() end } }
        local pg = self:pages()[self.pageIdx]
        if pg and pg.setup and tostring(self.find:getInternalText() or "") == "" then
            lefts[2] = { "defaults", ZeD.tr("UI_ZeD_Options_Defaults"), function() self:zedDefaults() end, "default", not self:zedOffDefault() }
        end
        UI.stripSpecs(self, stripY, w, row, lefts,
            { { "discard", ZeD.tr("UI_ZeD_Options_Discard"), function() self:setConfirm("discard") end, "default", not changed },
              { "apply", getText("UI_btn_apply"), function() self:apply(false) end, "primary", not changed } })
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- POINTER (in game the window has its own; at the menu the desk's) ---------------------
function ZeD_MMOptions:update()
    -- a click outside the open palette closes it
    if self._palette and isMouseButtonDown(0) and not self._palDown then
        local r = self._paletteRect
        local mx, my = getMouseX(), getMouseY()
        if r and not (mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h) then self._palette = nil end
    end
    self._palDown = isMouseButtonDown(0)
    ZeD_MMWindow.update(self)
    if self.inGame then
        local drop = MM.igDrop
        MM.pointer(MM.ctx, drop and { drop, self } or { self })
        local open = MM.ctx.open ~= nil
        if drop and drop:isVisible() ~= open then drop:setVisible(open) end
    end
end

-- CONTROLLER + KEYS ------------------------------------------------------------------
function ZeD_MMOptions:focusedRow()
    for _, b in ipairs(self._specs or {}) do if b.id == self.focusId and b.rowRef then return b.rowRef, b end end
    return nil
end

function ZeD_MMOptions:joyDir(dir)
    if self._palette then return end
    if dir == "left" or dir == "right" then
        local r = self:focusedRow()
        if r and self:nudge(r, dir == "left" and -1 or 1) then return end
    end
    ZeD_MMWindow.joyDir(self, dir)
    self._tickCol = 1
    local _, b = self:focusedRow()
    if b then
        local vh = self._list and self._list.h or 0
        if b.ry < self.scroll then self.scroll = b.ry
        elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
    end
end
function ZeD_MMOptions:joyB()
    if self._palette then self._palette = nil; return end
    if self.confirm == "key" then self:stopCapture(); self:setConfirm(false); return end
    if self.confirm and self.confirm ~= "monitor" then self:setConfirm(false); return end
    self:back()
end
-- X: on a quick action chord, clears it (ZeD_QuickChords); else Discard, when there is something to discard
function ZeD_MMOptions:joyX()
    local r = (not self.confirm) and self:focusedRow()
    if r and r.kind == "chord" then ZeD.QuickChords.clear(r.chord); MM.clickSound(); return end
    if not self.confirm and self:anyChanged() then self:setConfirm("discard") end
end
function ZeD_MMOptions:joyY() if not self.confirm and self:anyChanged() then self:apply(false) end end
function ZeD_MMOptions:joyBumper(dir)
    if self.confirm then return end
    local n = #self:pages()
    local i = self.pageIdx + dir
    if i < 1 then i = n elseif i > n then i = 1 end
    self.pageIdx = i
    self.scroll = 0
    self.focusId = nil
    if self.find:getInternalText() ~= "" then self.find:setText("") end
    MM.clickSound()
end

function ZeD_MMOptions:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    local r = self:focusedRow()
    local t = {}
    if r then
        if r.kind == "combo" or r.kind == "volume" or r.kind == "slider" or r.kind == "stepper" then t[#t + 1] = { glyph = "<>", label = ZeD.tr("UI_ZeD_Options_PromptChange") } end
        local toggles = (r.kind == "tick") or (r.zedStyle == "onoff")
        if r.kind == "chord" then
            t[#t + 1] = { glyph = "A", label = ZeD.tr("UI_ZeD_Options_PromptChange") }
            t[#t + 1] = { glyph = "X", label = ZeD.tr("UI_ZeD_Chord_PromptClear") }
        else
            t[#t + 1] = { glyph = "A", label = ZeD.tr(toggles and "UI_ZeD_Options_PromptToggle" or "UI_ZeD_MainMenu_PromptSelect") }
        end
    end
    t[#t + 1] = { glyph = "LB", label = "" }
    t[#t + 1] = { glyph = "RB", label = ZeD.tr("UI_ZeD_Options_PromptPage") }
    if self:anyChanged() then
        if not (r and r.kind == "chord") then t[#t + 1] = { glyph = "X", label = ZeD.tr("UI_ZeD_Options_Discard") } end
        t[#t + 1] = { glyph = "Y", label = ZeD.btnCase(getText("UI_btn_apply")) }
    end
    t[#t + 1] = { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) }
    return t
end

function ZeD_MMOptions:keyEscape()
    if self._palette then self._palette = nil; return true end
    if self.confirm == "monitor" then self:answerMonitor(false); return true end
    if self.confirm then self:setConfirm(false); return true end
    if self.find:isFocused() then self.find:unfocus(); return true end
    self:back()
    return true
end

function ZeD_MMOptions:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self.find:isFocused() or self.field:isFocused() then return false end
    if self.confirm then return false end
    if key == Keyboard.KEY_RETURN then if self:anyChanged() then self:apply(false) end; return true end
    return false
end

function ZeD_MMOptions:close() self:back() end

function ZeD_MMOptions:wheel(del)
    local l = self._list
    if not l then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < l.x or mx > l.x + l.w or my < l.y or my > l.y + l.h then return false end
    self.scroll = self.scroll + del * ZeD.T.px(ROW_H) * 2
    return true
end
function ZeD_MMOptions:onMouseWheel(del)
    if MM.dropWheel(del) then return true end
    return self:wheel(del)
end

-- ============================================================================
-- ENTRY POINTS + VANILLA HOOKS
-- ============================================================================

-- Opens Options: vanilla's toUI (MainScreen's OPTIONS item does the same), our window.
function MM.openOptions()
    local m = ms()
    if not m or (not m.inGame and m.delay > 0) then return end
    MM.ctx.open = nil
    if m.inGame then
        if not MM.pauseOpts then return end
        MM.pauseView = "options"
        MM.pauseOpts:onShow()
    else
        MM.showView("options")
    end
end

-- MainOptions keeps running underneath: its close, its two dialogs and its "show me"
-- (the Advanced sounds screen returns with setVisible(true)) come to the window.
function MM.hookOptions(m)
    local o = m and m.mainOptions
    if not o or o._zedHooked then return end
    o._zedHooked = true
    local win = function() if m.inGame then return MM.pauseOpts end; return MM.root and MM.root.optsWin end
    local origClose = o.close
    o.close = function(self)
        if MM._vanillaOptions then
            -- back from vanilla's controller page: our Options again
            MM._vanillaOptions = nil
            JoypadState.controllerTest = nil
            self:setVisible(false)
            if m.inGame then MM.pauseView = "options"; if MM.pauseOpts then MM.pauseOpts:onShow() end
            else MM.showView("options") end
            return
        end
        local w = win()
        JoypadState.controllerTest = nil
        self:setVisible(false)
        if w then w:finish() else origClose(self) end
    end
    o.showConfirmMonitorSettingsDialog = function(self, closeAfter)
        local w = win()
        if w and w:isVisible() then w:askMonitor(closeAfter); return true end
        return MainOptions.showConfirmMonitorSettingsDialog(self, closeAfter)
    end
    o.showRestartRequiredDialog = function(self, closeAfter)
        local w = win()
        if w and w:isVisible() then w:askRestart(closeAfter); return end
        return MainOptions.showRestartRequiredDialog(self, closeAfter)
    end
    local origVis = o.setVisible
    o.setVisible = function(self, visible, joypadData)
        if visible and not MM._vanillaOptions then
            origVis(self, false, joypadData)
            MM.openOptions()
            return
        end
        return origVis(self, visible, joypadData)
    end
end

-- vanilla's OPTIONS item (also how a Lua reset after "Apply" reopens Options)
MainScreen._zedItemOrig = MainScreen._zedItemOrig or MainScreen.onMenuItemMouseDownMainMenu
MainScreen.onMenuItemMouseDownMainMenu = function(item, x, y)
    -- vanilla's CREDITS item hides the menu after its screen shows: the credits view opens straight
    if item and item.internal == "CREDITS" and ms() and not ms().inGame and MM.root and ms().delay <= 0 then
        getSoundManager():playUISound("UIActivateMainMenuItem")
        MM.showView("credits")
        return
    end
    if item and item.internal == "OPTIONS" and ms() then
        local m = ms()
        if m and (m.inGame or m.delay <= 0) then
            getSoundManager():playUISound("UIActivateMainMenuItem")
            MM.openOptions()
            return
        end
    end
    return MainScreen._zedItemOrig(item, x, y)
end

-- the wheel goes to whichever list view is up
local _wheel = MM.wheel
function MM.wheel(del)
    if MM.dropWheel and MM.dropWheel(del) then return true end   -- an open pull-down first
    if MM.view == "options" and MM.root and MM.root.optsWin then return MM.root.optsWin:wheel(del) end
    return _wheel(del)
end
