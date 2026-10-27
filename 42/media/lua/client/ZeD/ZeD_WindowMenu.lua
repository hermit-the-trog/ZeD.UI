-- ZeD-UI/42/media/lua/client/ZeD/ZeD_WindowMenu.lua
-- ============================================================================
-- THE WINDOW BOX'S MENU (cohesion spec 3.1)
--
-- The box at the right end of every ZeD window's title bar pulls this menu
-- down: a System 7 pull-down in the context list's look (ZeD_ContextList),
-- right-aligned under the box, its choices in submenus with a check beside
-- the one in use.
--
--   Theme > Dark, Light, High contrast
--   Accent > the nine (the Character and World windows: their own accent,
--            and "Same as Accent color")
--   Text size > Small, Large
--   See-through > 100% ... 60%, Solid while in use
--   Controller highlight > Pointing hand, Corner marks, One wash, Marching ants
--   ----
--   Reset this window (Reset both windows on the Character / World pair)
--   ----
--   ZeD setup...
--
-- Every choice calls what ZeD setup and the Select wheel call, so the three
-- always agree and the choice is saved with the other ZeD settings.
-- ZeD_Window (Organisms.lua) opens it: ZeD.WindowMenu.open(win).
-- ============================================================================

require "ZeD/ZeD_ContextList"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.WindowMenu = ZeD.WindowMenu or {}
local WM = ZeD.WindowMenu

ZeD_WindowMenu = ZeD_ContextList:derive("ZeD_WindowMenu")

-- the context list's row metrics (ZeD_ContextList.lua), design units: the check sits in the icon's place
local ROW_H, PAD_X, ICON = 24, 12, 14

-- System 7's check mark, one cell = one hairline
local CHECK = { "......#", ".....##", "#...##.", "##.##..", ".###...", "..#...." }

local function tr(k, ...) return ZeD.tr(k, ...) end

-- a level's rows: the entries with a line between groups (as the context list)
local function rowsOf(items)
    local rows, last = {}, nil
    for _, def in ipairs(items) do
        if last and def.category ~= last then rows[#rows + 1] = { sep = true } end
        rows[#rows + 1] = { def = def }
        last = def.category
    end
    return rows
end

-- Pulled down from the window box: right-aligned to it, just under it
function ZeD_WindowMenu:open()
    self._ctx.open = true
    local top = { items = self._ctx.actions }
    top.rows = rowsOf(top.items)
    self:_measure(top, false)
    self:_place(top, self._anchorX - top.w, self._anchorY, nil)
    self._levels = { top }
    if JoypadState and JoypadState.players and JoypadState.players[self.player + 1] then
        top.sel = self:_firstLive(top, 1, 1) or 1
        self._joyfocus = true
        pcall(function() if setJoypadIgnoreAimUntilCentered then setJoypadIgnoreAimUntilCentered(self.player, true) end end)
        pcall(function() if setJoypadFocus then setJoypadFocus(self.player, self) end end)
    end
    self:setWantKeyEvents(true)
    self:addToUIManager()
    pcall(function() self:bringToTop() end)
end

function ZeD_WindowMenu:close()
    if self.win then self.win._wboxOpen = nil end
    ZeD_ContextList.close(self)
    if WM.current == self then WM.current = nil end
end

local function drawCheck(p, x, y, k, c)
    for row = 1, #CHECK do
        local line = CHECK[row]
        local run0 = nil
        for col = 1, #line + 1 do
            local on = line:sub(col, col) == "#"
            if on and not run0 then run0 = col
            elseif not on and run0 then
                p:drawRect(x + (run0 - 1) * k, y + (row - 1) * k, (col - run0) * k, k, c.a or 1, c.r, c.g, c.b)
                run0 = nil
            end
        end
    end
end

-- the context list's drawing, then a check beside each choice in use
function ZeD_WindowMenu:prerender()
    ZeD_ContextList.prerender(self)
    if not self._ctx.open then return end
    local T = ZeD.T
    local k = T.hair
    local isz, rowH, padX = T.px(ICON), T.px(ROW_H), T.px(PAD_X)
    for _, lv in ipairs(self._levels) do
        for ri, r in ipairs(lv.rows) do
            local def = r.def
            if def and def.checked and r.y then
                local ok, on = pcall(def.checked)
                if ok and on then
                    local c = (lv.sel == ri) and T.textOnFocus or T.text
                    drawCheck(self, lv.x + padX + math.floor((isz - 7 * k) / 2), lv.y + r.y + math.floor((rowH - 6 * k) / 2), k, c)
                end
            end
        end
    end
end

-- ----------------------------------------------------------------------------
-- the choices
-- ----------------------------------------------------------------------------
-- the theme, the accent and the text size go through ZeD.applyTheme and back into the
-- mod options (as the Select wheel and ZeD setup)
local function setTheme(base, accent, size)
    ZeD.applyTheme(base or ZeD.currentBase, accent or ZeD.currentAccent, size or ZeD.currentSize)
    local S = ZeD.Settings
    if S and S.syncToModOptions then S.syncToModOptions() end
end

local function leaf(name, fire, checked, category)
    return { name = name, onFire = fire, checked = checked, category = category or "pick" }
end

-- ZeD setup: the main menu's Options on its first page, or in game the pause screen's
function WM.openSetup(win)
    local MM = ZeD.MainMenu
    local m = MainScreen and MainScreen.instance
    if m and not m.inGame then
        if MM and MM.openOptions then MM.openOptions() end
        local ow = MM and MM.root and MM.root.optsWin
        if ow then ow.pageIdx = 1; ow.scroll = 0 end
        return
    end
    local D = ZeD.DpadWheels
    local pn = (ZeD.playerNumOf and ZeD.playerNumOf(win)) or win.playerNum or 0
    if D and D.H and D.H.openSetup then D.H.openSetup(getSpecificPlayer(pn), pn) end
end

function WM.build(win)
    local S = ZeD.Settings
    if not S then return {} end
    local items = {}
    local pair = win.pairKey and win:pairKey() or nil

    local theme = { name = tr("UI_ZeD_WinMenu_Theme"), category = "look", children = {} }
    for i, k in ipairs(S.baseKeys or {}) do
        theme.children[#theme.children + 1] = leaf(tr(S.baseLabels[i]), function() setTheme(k, nil, nil) end,
            function() return ZeD.currentBase == k end)
    end
    items[#items + 1] = theme

    -- the Character and World windows each keep an accent of their own (the old footer square
    -- set it there too); any other window sets the whole interface's
    local accent = { name = tr("UI_ZeD_WinMenu_Accent"), category = "look", children = {} }
    for i, k in ipairs(S.accentKeys or {}) do
        local fire, chk
        if pair then
            fire = function() win._accentKey = k; S.syncWindowAccent(win) end
            chk = function() return win._accentKey == k end
        else
            fire = function() setTheme(nil, k, nil) end
            chk = function() return ZeD.currentAccent == k end
        end
        accent.children[#accent.children + 1] = leaf(tr(S.accentLabels[i]), fire, chk)
    end
    if pair then
        accent.children[#accent.children + 1] = leaf(tr("UI_ZeD_Settings_SameAsAccent"),
            function() win._accentKey = nil; S.syncWindowAccent(win) end,
            function() return win._accentKey == nil end, "follow")
    end
    items[#items + 1] = accent

    local size = { name = tr("UI_ZeD_Settings_TextSize"), category = "look", children = {} }
    for i, k in ipairs(S.sizeKeys or {}) do
        size.children[#size.children + 1] = leaf(tr(S.sizeLabels[i]), function() setTheme(nil, nil, k) end,
            function() return ZeD.currentSize == k end)
    end
    items[#items + 1] = size

    if S.seeThroughKeys then
        local see = { name = tr("UI_ZeD_Settings_SeeThrough"), category = "look", children = {} }
        for i, v in ipairs(S.seeThroughKeys) do
            see.children[#see.children + 1] = leaf(tr("UI_ZeD_Settings_SeeThroughPct", v), function() S.setSeeThrough(i) end,
                function() return S.seeThroughIndex() == i end)
        end
        see.children[#see.children + 1] = leaf(tr("UI_ZeD_Settings_SolidInUse"), function() S.setSolidInUse(not S.solidInUse()) end,
            function() return S.solidInUse() end, "solid")
        items[#items + 1] = see
    end

    if S.focusStyleKeys then
        local fs = { name = tr("UI_ZeD_Settings_FocusStyle"), category = "look", children = {} }
        for i, k in ipairs(S.focusStyleKeys) do
            fs.children[#fs.children + 1] = leaf(tr(S.focusStyleLabels[i]), function() S.setFocusStyle(k) end,
                function() return S.focusStyle() == k end)
        end
        items[#items + 1] = fs
    end

    if not win.noResetControl then
        items[#items + 1] = { name = tr("UI_ZeD_WinMenu_ResetThis"), category = "reset", onFire = function() win:resetWindow() end }
        if pair then
            items[#items + 1] = { name = tr("UI_ZeD_WinMenu_ResetBoth"), category = "reset",
                                  onFire = function() if ZeD_Window and ZeD_Window.resetLayout then ZeD_Window.resetLayout() end end }
        end
    end
    items[#items + 1] = { name = tr("UI_ZeD_WinMenu_Setup"), category = "setup", onFire = function() WM.openSetup(win) end }
    return items
end

-- Pull the menu down from win's window box (one menu at a time)
function WM.open(win)
    if WM.current and WM.current._ctx and WM.current._ctx.open then WM.current:close() end
    local box = win and win:windowBoxRect()
    if not box then return end
    local T = ZeD.T
    local ax = win:getAbsoluteX() + box.x + box.w
    local ay = win:getAbsoluteY() + box.y + box.h + T.px(1)
    local pn = (ZeD.playerNumOf and ZeD.playerNumOf(win)) or win.playerNum or 0
    local m = ZeD_WindowMenu:new(pn, "cursor", ax, ay, win, WM.build(win), nil)
    m.win = win
    m:initialise()
    m:open()
    win._wboxOpen = true
    WM.current = m
end
