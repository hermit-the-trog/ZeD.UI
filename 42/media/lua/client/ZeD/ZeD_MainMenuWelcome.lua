-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuWelcome.lua
-- ============================================================================
-- WELCOME: the first-launch setup (beta 21). Client; an organism (a window on the desk, the "welcome" view).
-- The director, Nov 18 2026: "Pick their own experience including settings with preview on first launch out of a
-- live game, can be skipped and they get the setup we default to"; "there should be a choice to load a previous
-- setup"; the tutorial "an option up front to skip". Mockup: ZeDUI/mockups/zed_first_launch_v1.png (approved).
--
-- The first time ZeD runs (Zomboid/Lua/ZeD_setup_seen.txt not there yet; never on a QA autoload launch) the desk
-- opens this window in place of the Options page it used to open. Three ways in, as radio cards:
--   Pick your own   the choices that change the most (Style, Theme, Text, Playing with, Moodles, Tutorial, Accent),
--                   each a row of radio buttons, set live: the desk and the preview change as they are picked
--   Load a setup    Zomboid/Lua/ZeD_setup.txt (ZeD.Settings.saveSetup wrote it, here or on another machine)
--   Skip            ZeD as it comes: the choices go back to what they were when the window opened
-- The band: Save setup... (writes the file from the choices now) and Done (keeps them; Load reads the file first).
-- Done, Skip and Load each write the seen file, so the window never comes back by itself; ZeD setup keeps every
-- choice. The tutorial's answer goes in Zomboid/Lua/ZeD_tutorial.txt ("1" show, "0" no), read in game
-- (ZeD.Welcome.tutorialWanted).
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local function tr(k, ...) return ZeD.tr(k, ...) end

ZeD.Welcome = ZeD.Welcome or {}
local WL = ZeD.Welcome
WL.SEEN_FILE = "ZeD_setup_seen.txt"
WL.TUTORIAL_FILE = "ZeD_tutorial.txt"

local function writeFile(name, text)
    local ok, w = pcall(function() return getFileWriter(name, true, false) end)
    if not (ok and w) then return false end
    local wrote = pcall(function() w:write(text) end)
    pcall(function() w:close() end)
    return wrote
end
local function readFirst(name)
    local ok, r = pcall(function() return getFileReader(name, false) end)
    if not (ok and r) then return nil end
    local l = nil
    pcall(function() l = r:readLine() end)
    pcall(function() r:close() end)
    return l
end

--- True when the player asked for the tutorial on the first-launch setup (and it has not run yet).
function WL.tutorialWanted() local l = readFirst(WL.TUTORIAL_FILE); return l == "1" or l == "pad" end
--- The tutorial ran (or was stopped): it does not come again by itself.
function WL.tutorialDone() writeFile(WL.TUTORIAL_FILE, "0") end
--- True once the first-launch setup was answered.
function WL.seen() return readFirst(WL.SEEN_FILE) ~= nil end

-- ---------------------------------------------------------------------------
-- THE CHOICES: { key, option id, the items' words (translation keys), how an item maps to the option's value }
-- ---------------------------------------------------------------------------
local S = function() return ZeD.Settings end
local function optOf(id) local s = S(); return s and s.opts and s.opts.dict and s.opts.dict[id] end
local function idxOf(keys, k) for i, v in ipairs(keys or {}) do if v == k then return i end end return 1 end

WL.ROWS = {
    { key = "style", label = "UI_ZeD_Settings_LookStyle", opt = "lookStyle", items = { "UI_ZeD_Settings_Full", "UI_ZeD_Settings_Lite" } },
    { key = "theme", label = "UI_ZeD_Welcome_Theme", opt = "baseTheme", items = { "UI_ZeD_Welcome_Dark", "UI_ZeD_Welcome_Light", "UI_ZeD_Welcome_HighContrast" },
      keys = { "dark", "light", "hicon" }, keyList = function() return S().baseKeys end },
    { key = "text", label = "UI_ZeD_Settings_TextSize", opt = "textSize", items = { "UI_ZeD_Welcome_Small", "UI_ZeD_Welcome_Large" },
      keys = { "small", "large" }, keyList = function() return S().sizeKeys end },
    { key = "input", label = "UI_ZeD_Welcome_PlayingWith", items = { "UI_ZeD_Welcome_MouseKeys", "UI_ZeD_Welcome_Controller" } },
    { key = "moodles", label = "UI_ZeD_Settings_Moodles", opt = "moodlePlace", items = { "UI_ZeD_Options_MoodlesRight", "UI_ZeD_Options_MoodlesLeft", "UI_ZeD_Options_MoodlesBottom" } },
    { key = "tutorial", label = "UI_ZeD_Welcome_Tutorial", items = { "UI_ZeD_Welcome_ShowMe", "UI_ZeD_Welcome_NoThanks" } },
}

-- the row's picked item, read from its option (or the window's own answer)
local function pickedOf(win, row)
    if row.key == "input" then return win.input or 1 end
    if row.key == "tutorial" then return win.tutorial or 1 end
    local o = row.opt and optOf(row.opt)
    if not o then return 1 end
    local v = o:getValue() or 1
    if row.keys and row.keyList then
        local key = (row.keyList() or {})[v]
        for i, k in ipairs(row.keys) do if k == key then return i end end
        return 1
    end
    return v
end

-- an item picked: the option set and the look put on screen at once (the preview is the desk itself, and the box)
local function pick(win, row, i)
    if row.key == "input" then win.input = i; return end
    if row.key == "tutorial" then win.tutorial = i; return end
    local o = row.opt and optOf(row.opt)
    if not o then return end
    local v = i
    if row.keys and row.keyList then v = idxOf(row.keyList(), row.keys[i]) end
    o:setValue(v)
    -- (QA's bug hunt WL-1, Nov 20 2026: the preset was set on the options screen's controls only, so Done saved the
    -- additions as they were. The Vanilla preset goes onto the options themselves.)
    if row.key == "style" and i == 2 then
        local P = S().ADDITION_PRESETS and S().ADDITION_PRESETS[1]
        for id, v in pairs(P or {}) do
            local ao = optOf(id)
            if ao and ao.setValue then pcall(ao.setValue, ao, v) end
        end
        local pre = optOf("additionsPreset")
        if pre and pre.setValue then pcall(pre.setValue, pre, 1) end
        if S().pickAdditionsPreset then pcall(S().pickAdditionsPreset, 1) end
    end
    if S().applyThemeNow then pcall(S().applyThemeNow) end
end

-- ---------------------------------------------------------------------------
-- THE WINDOW
-- ---------------------------------------------------------------------------
ZeD_MMWelcome = ZeD_MMWindow:derive("ZeD_MMWelcome")

function ZeD_MMWelcome:new()
    local o = ZeD_MMWindow.new(self, "welcome")
    o.noResetControl = true
    o.way = 1             -- 1 pick your own, 2 load a setup, 3 skip
    o.input, o.tutorial = 1, 1
    -- (KISS #53: Playing with starts on the device in use: a pad drives the window, so Controller)
    if MM.gamepad() then o.input = 2 end
    o.focusId = "way:1"
    o.note = nil          -- a line in the band after Save or a failed Load
    return o
end

function ZeD_MMWelcome:onShow()
    -- what the choices were as the window opened: Skip puts them back
    self.snap = {}
    local s = S()
    for _, o in ipairs((s and s.opts and s.opts.data) or {}) do
        if o.id and o.type ~= "multipletickbox" and o.getValue and o.type ~= "button" then
            local ok, v = pcall(o.getValue, o)
            if ok and type(v) ~= "table" then self.snap[o.id] = v end
        end
    end
    self.way, self.note = 1, nil
    self.input = MM.gamepad() and 2 or 1   -- (Playing with follows the device in use, KISS #53)
    -- (QA OP74, Nov 27 2026: reopened from the Settings menu, Tutorial started on Show me around again, so Accept
    -- turned a finished or refused tour back on. It starts on the stored answer: once the setup was answered, Show me
    -- around only while the tour is still wanted; never answered, Show me around.)
    self.tutorial = (WL.seen() and not WL.tutorialWanted()) and 2 or 1
    self.focusId = "way:1"
end

local function finish(win, tutorialWord)
    writeFile(WL.SEEN_FILE, "1")
    writeFile(WL.TUTORIAL_FILE, tutorialWord)
    local s = S()
    if s and s.saveNow then pcall(s.saveNow) end
    MM.clickSound()
    MM.showView("main")
end

function ZeD_MMWelcome:done()
    if self.way == 3 then return self:skip() end
    if self.way == 2 then
        local n = S().loadSetup and S().loadSetup()
        if not n then self.note = tr("UI_ZeD_Welcome_NoFile", S().SETUP_FILE); return end
        -- (QA OP76, Nov 27 2026: a file with no line ZeD can take loaded 0 settings and closed as done, nothing
        -- changed and no word. It says so and stays.)
        if n == 0 then self.note = tr("UI_ZeD_Welcome_LoadEmpty", S().SETUP_FILE); MM.clickSound(); return end
        -- (QA OP75, Nov 27 2026: the load put the theme on screen only; UI scale and Playing with waited for the next
        -- menu or game. Everything stored goes on now, as the options window's own rows apply it.)
        if S().reapplyFromOptions then pcall(S().reapplyFromOptions) end
        return finish(self, "0")
    end
    -- (the tour's words follow Playing with: "pad" gives the controller's, ZeD_Tutorial.lua)
    finish(self, (self.tutorial == 1) and ((self.input == 2) and "pad" or "1") or "0")
end

function ZeD_MMWelcome:skip()
    for id, v in pairs(self.snap or {}) do
        local o = optOf(id)
        if o and o.setValue then pcall(o.setValue, o, v) end
    end
    if S().applyThemeNow then pcall(S().applyThemeNow) end
    finish(self, "0")
end

function ZeD_MMWelcome:saveSetup()
    local ok = S().saveSetup and S().saveSetup()
    self.note = ok and tr("UI_ZeD_Welcome_Saved", S().SETUP_FILE) or tr("UI_ZeD_Welcome_SaveFailed")
    MM.clickSound()
end

-- (KISS #33: the close box keeps the picks, as Accept does; it no longer throws them back like Skip. A load or a skip
-- picked as the way has nothing picked here, so it ends as Skip does.)
function ZeD_MMWelcome:close()
    if self.way == 1 then return self:done() end
    return self:skip()
end
-- (QA OP72, director's pick Nov 27 2026: Skip is only its own button. B, Escape and the way out no longer throw the
-- picks away; they do what the close box does.)
function ZeD_MMWelcome:back() self:close() end

-- (OP72, Nov 27 2026) the pad's B goes back one step: from a choice or the band to the way cards (on the way that
-- is picked); on the way cards, the first step, it does what the close box does, keeping the picks.
function ZeD_MMWelcome:onFirstStep()
    local f = self.focusId
    return f == nil or string.sub(f, 1, 4) == "way:"
end
function ZeD_MMWelcome:stepBack()
    if self:onFirstStep() then return self:close() end
    self.focusId = "way:" .. (self.way or 1)
    MM.hoverSound()
end

-- a radio and its word; returns the width it took
local function radioWord(p, x, y, h, on, word, focused, hot)
    local T, A = ZeD.T, ZeD.Atoms
    local rs = A.radioSize()
    local f = T.fontF2
    local fh = MM.fontH(f)
    A.drawRadio(p, x, y + math.floor((h - rs) / 2), on, { hover = hot })
    local c = focused and T.textOnFocus or T.text
    p:drawText(word, x + rs + T.px(6), y + math.floor((h - fh) / 2), c.r, c.g, c.b, c.a or 1, f)
    return rs + T.px(6) + MM.textW(f, word)
end

function ZeD_MMWelcome:prerender()
    local T = ZeD.T
    local L = MM.layout()
    self._specs, self._hits = {}, {}
    local barH, gap = T.px(U.BAR_H), T.px(12)
    local w = math.min(T.px(720), L.tw - T.px(40))
    -- (QA's visual noise audit 14, Nov 20 2026: the window ran to the desk's foot with its lower half blank.
    -- It is as tall as its rows: the intro, the three ways, the choices and Accent, the band and the help line.)
    local f2h, f3h = MM.fontH(T.fontF2), MM.fontH(T.fontF3)
    local rowH = math.max(T.buttonH, f2h) + T.px(8)
    -- (KISS #53: the Style tip sits under the Style row, wrapped to the choices' column; its lines add to the height)
    local tipPad = T.px(U.STACK_PAD)
    local tipPrevW = math.floor((w - tipPad * 2) * 0.34)
    local tipLines = ZeD.Atoms.wrapText(tr("UI_ZeD_Settings_LookStyleTip"), T.fontF3, w - tipPad * 2 - tipPrevW - T.px(16))
    local tipH = #tipLines * f3h + T.px(6)
    local fit = T.titleBarH + T.px(U.STACK_PAD) * 2 + f2h + T.px(10) + (f2h + f3h + T.px(16)) + T.px(14)
                + (#WL.ROWS + 1) * rowH + tipH + MM.bandH() + self:footerHeight()
    local h = math.min(L.th - barH - gap * 2, fit)
    local x = L.tx + math.floor((L.tw - w) / 2)
    local y = L.ty + barH + gap
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self.title = tr("UI_ZeD_Welcome_Title")
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gp = MM.gamepad()
    local ctx = MM.ctx
    local f2, f3 = T.fontF2, T.fontF3
    local c, d = T.text, T.textDim
    local cy = tb + pad
    self:drawText(tr("UI_ZeD_Welcome_Intro"), pad, cy, c.r, c.g, c.b, c.a or 1, f2)
    cy = cy + MM.fontH(f2) + T.px(10)
    -- the three ways in
    local ways = { { "UI_ZeD_Welcome_WayPick", "UI_ZeD_Welcome_WayPickSub" }, { "UI_ZeD_Welcome_WayLoad", "UI_ZeD_Welcome_WayLoadSub" },
                   { "UI_ZeD_Welcome_WaySkip", "UI_ZeD_Welcome_WaySkipSub" } }
    local cw = math.floor((w - pad * 2 - T.px(16)) / 3)
    local ch = MM.fontH(f2) + MM.fontH(f3) + T.px(16)
    for i, wy in ipairs(ways) do
        local bx = pad + (i - 1) * (cw + T.px(8))
        local id = "way:" .. i
        local hid = "welcome:" .. id
        local on = self.way == i
        local onF = MM.rowLook(self, bx, cy, cw, ch, on, (not gp) and ctx.hot == hid, gp and self.focusId == id, self)
        ZeD.Atoms.frame(self, bx, cy, cw, ch, on and T.accent or T.borderS)
        radioWord(self, bx + T.px(8), cy + T.px(6), MM.fontH(f2), on, tr(wy[1]), onF, false)
        local dd = onF and T.textOnFocus or d
        -- (QA, Nov 19 2026: the line ran past its card: cut to the card)
        local subX = bx + T.px(8) + ZeD.Atoms.radioSize() + T.px(6)
        self:drawText(ZeD.Atoms.truncateText(tr(wy[2]), f3, cw - (subX - bx) - T.px(8)), subX, cy + T.px(8) + MM.fontH(f2), dd.r, dd.g, dd.b, dd.a or 1, f3)
        local wi = i
        local fn = function() self.way = wi; self.focusId = "way:" .. wi; MM.hoverSound() end
        self._hits[#self._hits + 1] = { id = hid, x = ax + bx, y = ay + cy, w = cw, h = ch, fn = fn }
        self._specs[#self._specs + 1] = { id = id, listRow = true, row = 1, col = i, x = bx, y = cy, w = cw, h = ch, fn = fn }
    end
    cy = cy + ch + T.px(14)
    -- the choices (dimmed and inert unless Pick your own), and the preview at the right
    local live = self.way == 1
    local prevW = math.floor((w - pad * 2) * 0.34)
    local leftW = w - pad * 2 - prevW - T.px(16)
    local labelW = T.px(120)
    local rh = math.max(T.buttonH, MM.fontH(f2)) + T.px(8)
    for r, row in ipairs(WL.ROWS) do
        local ry = cy + (r - 1) * rh + ((r > 1) and tipH or 0)   -- (rows below Style drop by the tip's height, KISS #53)
        local dl = live and d or { r = d.r, g = d.g, b = d.b, a = (d.a or 1) * T.disabledAlpha }
        self:drawText(tr(row.label), pad, ry + math.floor((rh - MM.fontH(f2)) / 2), dl.r, dl.g, dl.b, dl.a or 1, f2)
        local ix = pad + labelW
        local picked = pickedOf(self, row)
        for i, item in ipairs(row.items) do
            local word = tr(item)
            local iw = ZeD.Atoms.radioSize() + T.px(6) + MM.textW(f2, word)
            local id = "opt:" .. row.key .. ":" .. i
            local hid = "welcome:" .. id
            local hot = live and (not gp) and ctx.hot == hid
            local onF = live and gp and self.focusId == id and ZeD.Focus.mark(self, ix - T.px(3), ry + T.px(2), iw + T.px(6), rh - T.px(4), MM.focusOpts(self))
            if live then
                radioWord(self, ix, ry, rh, picked == i, word, onF, hot)
            else
                self:drawText(word, ix + ZeD.Atoms.radioSize() + T.px(6), ry + math.floor((rh - MM.fontH(f2)) / 2), dl.r, dl.g, dl.b, dl.a or 1, f2)
            end
            if live then
                local rw, ri = row, i
                local fn = function() pick(self, rw, ri); self.focusId = "opt:" .. rw.key .. ":" .. ri; MM.hoverSound() end
                self._hits[#self._hits + 1] = { id = hid, x = ax + ix, y = ay + ry, w = iw, h = rh, fn = fn }
                self._specs[#self._specs + 1] = { id = id, listRow = true, row = 1 + r, col = i, x = ix, y = ry, w = iw, h = rh, fn = fn }
            end
            ix = ix + iw + T.px(16)
        end
    end
    -- the Style tip, under the Style row (what Full and Lite change; KISS #53)
    local tdl = live and d or { r = d.r, g = d.g, b = d.b, a = (d.a or 1) * T.disabledAlpha }
    for li, line in ipairs(tipLines) do
        self:drawText(line, pad + labelW, cy + rh + (li - 1) * f3h, tdl.r, tdl.g, tdl.b, tdl.a or 1, f3)
    end
    -- Accent: the swatches
    local ar = cy + #WL.ROWS * rh + tipH
    local s = S()
    local accents = (s and s.accentKeys) or {}
    local aopt = optOf("accentColor")
    local acur = aopt and aopt:getValue() or 1
    local dl = live and d or { r = d.r, g = d.g, b = d.b, a = (d.a or 1) * T.disabledAlpha }
    self:drawText(tr("UI_ZeD_Settings_AccentColor"), pad, ar + math.floor((rh - MM.fontH(f2)) / 2), dl.r, dl.g, dl.b, dl.a or 1, f2)
    local sw = T.px(16)
    for i, key in ipairs(accents) do
        local sx = pad + labelW + (i - 1) * (sw + T.px(6))
        local sy = ar + math.floor((rh - sw) / 2)
        local set = ZeD.AccentColors and ZeD.AccentColors[key]
        local tone = set and set[(ZeD.currentBase == "light") and "light" or "dark"]
        local col = (tone and tone.accent) or T.accent
        self:drawRect(sx, sy, sw, sw, live and 1 or T.disabledAlpha, col.r, col.g, col.b)
        if i == acur then ZeD.Atoms.frame(self, sx - T.px(2), sy - T.px(2), sw + T.px(4), sw + T.px(4), T.text) end
        local id = "opt:accent:" .. i
        if live then
            if gp and self.focusId == id then ZeD.Focus.mark(self, sx - T.px(3), sy - T.px(3), sw + T.px(6), sw + T.px(6), MM.focusOpts(self)) end
            local ai = i
            local fn = function()
                if aopt then aopt:setValue(ai) end
                if s and s.applyThemeNow then pcall(s.applyThemeNow) end
                self.focusId = "opt:accent:" .. ai
                MM.hoverSound()
            end
            self._hits[#self._hits + 1] = { id = "welcome:" .. id, x = ax + sx, y = ay + sy, w = sw, h = sw, fn = fn }
            self._specs[#self._specs + 1] = { id = id, listRow = true, row = 2 + #WL.ROWS, col = i, x = sx, y = sy, w = sw, h = sw, fn = fn }
        end
    end
    -- the preview: a small inventory window drawn with what is picked (the theme, the accent, Lite's buttons)
    local px0, py0 = w - pad - prevW, cy
    local ac = T.accent
    self:drawText(tr("UI_ZeD_Welcome_Preview"), px0, py0, ac.r, ac.g, ac.b, ac.a or 1, f3)
    py0 = py0 + MM.fontH(f3) + T.px(6)
    local ph = math.min(T.px(190), (#WL.ROWS + 1) * rh - MM.fontH(f3) - T.px(6))
    UI.insetBox(self, px0, py0, prevW, ph)
    local mx, my, mw = px0 + T.px(10), py0 + T.px(10), prevW - T.px(20)
    ZeD.Surface.fill(self, mx, my, mw, ph - T.px(20), "surf1")
    ZeD.Atoms.frame(self, mx, my, mw, ph - T.px(20), T.borderS)
    local th = T.px(16)
    ZeD.Surface.fill(self, mx + 1, my + 1, mw - 2, th, "surf2")
    local title = tr("UI_ZeD_Welcome_SampleTitle")
    local tw = MM.textW(f3, title)
    self:drawText(title, mx + math.floor((mw - tw) / 2), my + 1, ac.r, ac.g, ac.b, ac.a or 1, f3)
    local items = { { "", tr("UI_ZeD_Welcome_SampleApple") }, { "", tr("UI_ZeD_Welcome_SampleKnife") },
                    { "", tr("UI_ZeD_Welcome_SampleLighter") } }
    local iy = my + th + T.px(6)
    local ih = MM.fontH(f3) + T.px(6)
    for i, it in ipairs(items) do
        if i == 1 then self:drawRect(mx + T.px(2), iy, mw - T.px(4), ih, T.selectionA, ac.r, ac.g, ac.b) end
        self:drawText(it[2], mx + T.px(8), iy + T.px(3), c.r, c.g, c.b, c.a or 1, f3)
        iy = iy + ih
    end
    local bw = math.floor((mw - T.px(30)) / 2)
    local by = my + ph - T.px(20) - T.buttonH - T.px(8)
    ZeD.Molecules.drawButton(self, mx + T.px(10), by, bw, T.buttonH, tr("UI_ZeD_Welcome_SampleDrop"), "default", false, nil, {})
    ZeD.Molecules.drawButton(self, mx + T.px(20) + bw, by, bw, T.buttonH, tr("UI_ZeD_Welcome_SampleEat"), "primary", false, nil, {})
    -- (QA's visual noise audit 14, Nov 20 2026: no note under the preview saying it changes as you pick; it does)
    -- the band
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    -- is there a setup file to load? Asked at most once a second: hasSetup opens the file (beast W53)
    local noFile = false
    if self.way == 2 then
        local now = MM.now()
        if not self._setupAt or now - self._setupAt >= 1000 then
            self._setupAt = now
            self._hasSetup = (S().hasSetup and S().hasSetup()) and true or false
        end
        noFile = not self._hasSetup
    end
    local doneWord = (self.way == 3) and tr("UI_ZeD_Welcome_WaySkip") or ((self.way == 2) and tr("UI_ZeD_Welcome_LoadDone") or getText("UI_btn_accept"))
    UI.stripSpecs(self, stripY, w, 1000, {},
        { { "save", tr("UI_ZeD_Welcome_SaveSetup"), function() self:saveSetup() end, "default", self.way ~= 1, tr("UI_ZeD_Welcome_HelpSave", S().SETUP_FILE) },
          -- (QA: Load with no setup file to read is grayed, and the band says where the file goes)
          { "done", doneWord, function() self:done() end, "primary", noFile, tr("UI_ZeD_Welcome_HelpDone") } },
        self.note or (noFile and tr("UI_ZeD_Welcome_NoFile", S().SETUP_FILE) or tr("UI_ZeD_Welcome_Band")), true)
end

function ZeD_MMWelcome:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMWelcome:joyB() self:stepBack() end   -- (OP72, Nov 27 2026: was Skip)
-- (KISS #53: Y accepts on a pad, as the band's Accept does)
function ZeD_MMWelcome:joyY() self:done() end
function ZeD_MMWelcome:getFooterPrompts()
    if not MM.gamepad() then return nil end
    -- (OP72, Nov 27 2026: B says where it goes: Back from a choice, Close on the way cards)
    local bWord = self:onFirstStep() and getText("UI_Close") or ZeD.btnCase(getText("UI_btn_back"))
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = bWord },
             { glyph = "Y", label = getText("UI_btn_accept") } }   -- (KISS #53)
end
function ZeD_MMWelcome:keyEscape() self:close(); return true end   -- (OP72, Nov 27 2026: as the close box, not Skip)
function ZeD_MMWelcome:keyOther(key)
    if key == Keyboard.KEY_RETURN then self:done(); return true end
    return false
end

-- on the desk as the "welcome" view
MM.addView("welcome", "welcomeWin", function() return ZeD_MMWelcome:new() end)

--- Open the first-launch setup (the desk's first run; ZeD setup can open it again).
function MM.openWelcome()
    MM.ctx.open = nil
    MM.showView("welcome")
end
