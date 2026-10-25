-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuModsPanes.lua
-- ============================================================================
-- THE MODS SCREEN'S INFO PANE TABS AND THE FILE PICKER (director, Oct 24 2026;
-- mockup zed_mods_settings_picks_v1, approved: "build the Mods screen changes as
-- the mockup shows")
--
-- The info pane (ZeD_MainMenuMods drawDetail) gets folder tabs under the mod's
-- name: About (what it showed before), Options (the mod's own options, changed
-- in place with the Options window's rows: ZeD_ModSettings), Sandbox (the
-- settings it adds to each game, read from its files) and Conflicts (ZeD_ModScan,
-- now with same-text copies as grey notes and picked files). A tab the mod has
-- nothing for is greyed. Options and Sandbox have the help band at the pane's
-- foot: the row under the pointer (or the controller) in the mod's own words.
--
-- The picker (page "picks"): every Lua file two mods share, whose copy runs now,
-- both copies of the chosen file side by side with the lines that differ marked,
-- and a choice per file. Use these picks keeps them (ZeD_ModPicks writes the
-- copies into ZeD picks, turns it on and keeps it last) and the strip offers the
-- reload.
-- ============================================================================
require "ZeD/ZeD_MainMenuMods"
require "ZeD/ZeD_ModSettings"
require "ZeD/ZeD_ModPicks"
local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local MS = ZeD.ModScan
local S  = ZeD.ModSettings
local P  = ZeD.ModPicks

-- design units
local TAB_GAP_Y = 8
local OPT_ROW_H = 32
local LABEL_SHARE = 0.46
local HELP_MIN_H = 54
local CODE_LINES = 12

local function model() return ModSelector and ModSelector.instance and ModSelector.instance.model end
local function jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end
    return t
end

-- the help band's height (three lines of the body font, as the Options window's)
function ZeD_MMMods:helpBandH()
    local T = ZeD.T
    return math.max(T.px(HELP_MIN_H), T.px(14) + 3 * (MM.fontH(T.fontF2) + T.px(3)))
end

-- ----------------------------------------------------------------------------
-- THE TABS
-- ----------------------------------------------------------------------------
-- { id, label, count (nil: no number) } for a mod
function ZeD_MMMods:detailTabs(d)
    local on = d.isActive or MS.isLoaded(d.modId)
    local nOpt = on and S.count(d.modId) or nil
    local nSb = S.sandboxCount(d.modId)
    local nCf = 0
    if MS.isLoaded(d.modId) then nCf = #MS.forMod(d.modId) end
    return {
        { id = "about", label = ZeD.tr("UI_ZeD_Mods_DTabAbout") },
        { id = "options", label = ZeD.tr("UI_ZeD_Mods_DTabOptions"), count = nOpt, none = (nOpt == 0) },
        { id = "sandbox", label = ZeD.tr("UI_ZeD_Mods_DTabSandbox"), count = nSb, none = (nSb == 0) },
        { id = "conflicts", label = ZeD.tr("UI_ZeD_Mods_DTabConflicts"), count = nCf, none = (nCf == 0) },
    }
end

-- the tab strip at cy across the pane; returns the y under it
function ZeD_MMMods:drawDetailTabs(d, x, w, cy, vy, vh)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local pad = T.px(12)
    local tx = x + pad
    local th = T.tabH
    local gp = MM.gamepad()
    local ac, bs = T.accent, T.borderS
    self.dtab = self.dtab or "about"
    for i, t in ipairs(self:detailTabs(d)) do
        local text = t.count and ZeD.tr("UI_ZeD_Mods_DTabCount", t.label, t.count) or t.label
        local hid = "mods:dtab:" .. t.id
        local hot = MM.ctx.hot == hid
        local tw = ZeD.Molecules.drawTab(self, tx, cy, text, self.dtab == t.id, hot, t.none and self.dtab ~= t.id)
        local sid = "dtab:" .. t.id
        if gp and self.focusId == sid then self:drawRect(tx, cy, tw, th, 0.55, ac.r, ac.g, ac.b) end
        local pick = function()
            if self.dtab ~= t.id then self.dtab = t.id; self.dscroll = 0; MM.clickSound() end
        end
        local top, bot = math.max(cy, vy), math.min(cy + th, vy + vh)
        if bot > top then
            self._hits[#self._hits + 1] = { id = hid, x = ax + tx, y = ay + top, w = tw, h = bot - top, fn = pick }
        end
        self._specs[#self._specs + 1] = { id = sid, listRow = true, paneStop = true, row = 550, col = i, x = tx, y = cy, w = tw, h = th,
                                          clipTop = vy, clipBot = vy + vh, fn = pick }
        tx = tx + tw + T.sp.tabGap
    end
    self:drawRect(x + T.px(1), cy + th - T.px(1), w - 2 * T.px(1), T.px(1), bs.a, bs.r, bs.g, bs.b)
    return cy + th + T.px(TAB_GAP_Y)
end

-- a line of dim text for a tab with nothing to show
function ZeD_MMMods:paneNote(text, ix, iw, cy, color)
    local T = ZeD.T
    local dsz = T.px(7)
    local f2 = T.fontF2
    ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), color or T.textDim, dsz)
    return self:paneText(text, ix + dsz + T.px(7), cy, iw - dsz - T.px(7), f2, T.text) + T.px(6)
end

-- ----------------------------------------------------------------------------
-- OPTIONS
-- ----------------------------------------------------------------------------
-- borrowed from the Options window: its drop lists and its left / right nudge
ZeD_MMMods.openCombo = ZeD_MMOptions.openCombo

function ZeD_MMMods:openPalette(r, anchor)
    self._palette = { row = r, anchor = anchor }
    MM.clickSound()
end

-- vanilla's 84-colour palette (ISColorPicker: three base-6 digits per colour), as the Options window's
local PALETTE = { 555, 303, 304, 403, 503, 314, 315, 505, 414, 523, 524, 525, 535, 545,
                  444, 300, 400, 310, 500, 311, 501, 510, 422, 521, 433, 532, 533, 544,
                  333, 420, 330, 430, 431, 530, 341, 442, 443, 543, 451, 550, 553, 554,
                  222, 20, 121, 30, 132, 230, 141, 142, 50, 52, 243, 250, 343, 353,
                  111, 21, 22, 32, 33, 34, 43, 44, 143, 144, 154, 155, 254, 255,
                  0, 12, 13, 112, 23, 24, 102, 123, 124, 125, 134, 135, 234, 245 }
local function paletteColor(code)
    local r, g, b = math.floor(code / 100), math.floor(code / 10) % 10, code % 10
    return { r = r / 5, g = g / 5, b = b / 5 }
end

function ZeD_MMMods:pickColor(col)
    local p = self._palette
    self._palette = nil
    if not p then return end
    local c = p.row.control
    c.backgroundColor = { r = col.r, g = col.g, b = col.b, a = 1 }
    MM.clickSound()
end

-- the palette over the window (render, after everything)
function ZeD_MMMods:drawPalette()
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
    self._hits[#self._hits + 1] = { id = "mods:pal", x = ax + px, y = ay + py, w = pw, h = ph }
    for i, code in ipairs(PALETTE) do
        local col = paletteColor(code)
        local cx = px + T.px(4) + ((i - 1) % cols) * cell
        local cy = py + T.px(4) + math.floor((i - 1) / cols) * cell
        self:drawRect(cx + T.px(1), cy + T.px(1), cell - 2 * T.px(1), cell - 2 * T.px(1), 1, col.r, col.g, col.b)
        local isCur = math.abs((cur.r or -1) - col.r) < 0.02 and math.abs((cur.g or -1) - col.g) < 0.02 and math.abs((cur.b or -1) - col.b) < 0.02
        if isCur or MM.ctx.hot == "mods:pal:" .. i then self:drawRectBorder(cx, cy, cell, cell, 1, T.text.r, T.text.g, T.text.b) end
        self._hits[#self._hits + 1] = { id = "mods:pal:" .. i, x = ax + cx, y = ay + cy, w = cell, h = cell, fn = function() self:pickColor(col) end }
    end
    self._paletteRect = { x = ax + px, y = ay + py, w = pw, h = ph }
end

-- a click outside the palette closes it
function ZeD_MMMods:paletteWatch()
    if self._palette and isMouseButtonDown(0) and not self._palDown then
        local r = self._paletteRect
        local mx, my = getMouseX(), getMouseY()
        if r and not (mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h) then self._palette = nil end
    end
    self._palDown = isMouseButtonDown(0)
end

-- a row's change is kept once the pointer lets go (a slider while it is dragged waits)
function ZeD_MMMods:watchOption(e)
    local s = S.sig(e.r)
    if s == nil then return end
    self._optSeen = self._optSeen or {}
    self._optKept = self._optKept or {}
    if self._optSeen[e.key] == nil then self._optSeen[e.key] = s; self._optKept[e.key] = s end
    if self._optKept[e.key] ~= s and not isMouseButtonDown(0) then
        S.apply(e)
        self._optKept[e.key] = s
    end
end

-- an option row: the changed dot, its name, its control (the Options window's), its stop
function ZeD_MMMods:drawOptionRow(e, i, ix, iw, cy, vy, vh)
    local T = ZeD.T
    local r = e.r
    local f2 = T.fontF2
    local lw = math.floor(iw * LABEL_SHARE)
    local cx = ix + lw + T.px(10)
    local cw = ix + iw - cx
    local rh = r and ZeD_MMOptions.rowHeight(self, r, cw) or T.px(OPT_ROW_H)
    local gp = MM.gamepad()
    local sid = "mopt:" .. i
    local ac = T.accent
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local visible = cy + rh > vy and cy < vy + vh
    if visible then
        if gp and self.focusId == sid then self:drawRect(ix - T.px(4), cy, iw + T.px(8), rh, 0.55, ac.r, ac.g, ac.b) end
        if mx >= ix and mx < ix + iw and my >= cy and my < cy + rh and my >= vy and my < vy + vh then self._helpEntry = e end
        if gp and self.focusId == sid then self._helpEntry = e end
        local s = r and S.sig(r)
        if s and self._optSeen and self._optSeen[e.key] and self._optSeen[e.key] ~= s then
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((T.px(OPT_ROW_H) - dsz) / 2), T.accent, dsz)
        end
        local tc = (r and not (r.control and r.control.disabled)) and T.text or T.textDim
        self:drawText(ZeD.Atoms.truncateText(e.label, f2, lw - T.px(18)), ix + T.px(14), cy + math.floor((T.px(OPT_ROW_H) - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        if not r then
            local d = T.textDim
            self:drawText(ZeD.tr("UI_ZeD_Mods_OptInOptions"), cx, cy + math.floor((T.px(OPT_ROW_H) - MM.fontH(f2)) / 2), d.r, d.g, d.b, d.a or 1, f2)
        elseif r.kind == "key" or r.kind == "text" then
            -- a key or a typed value is set in the Options window (its key catcher, its field)
            local val
            if r.kind == "key" then val = tostring(getKeyName(r.entry and r.entry.keyCode or 0) or "")
            else val = tostring(r.control:getText() or "") end
            local d, c = T.textDim, T.text
            self:drawText(ZeD.Atoms.truncateText(val, f2, cw), cx, cy + math.floor((T.px(OPT_ROW_H) - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
            local note = ZeD.tr("UI_ZeD_Mods_OptInOptions")
            local nx = cx + MM.textW(f2, val) + T.px(12)
            if nx + MM.textW(T.fontF3, note) < cx + cw then
                self:drawText(note, nx, cy + math.floor((T.px(OPT_ROW_H) - MM.fontH(T.fontF3)) / 2), d.r, d.g, d.b, d.a or 1, T.fontF3)
            end
        else
            ZeD_MMOptions.drawControl(self, r, cx, cy, cw, rh, "mo" .. i, { y = vy, h = vh })
            self:watchOption(e)
        end
    end
    if r and r.kind ~= "key" and r.kind ~= "text" then
        self._specs[#self._specs + 1] = { id = sid, listRow = true, paneStop = true, optEntry = e, row = 800 + i, col = 1,
                                          x = ix, y = cy, w = iw, h = rh, clipTop = vy, clipBot = vy + vh,
                                          fn = function() ZeD_MMOptions.activateRow(self, r) end }
    end
    return cy + rh
end

function ZeD_MMMods:drawOptionsTab(d, ix, iw, cy, vy, vh)
    local T = ZeD.T
    local f1, f2 = T.fontF1, T.fontF2
    local dim = T.textDim
    if d.modId == "ZeD_UI" then
        cy = self:paneNote(ZeD.tr("UI_ZeD_Mods_OptZeDOwn"), ix, iw, cy, T.accent)
        return self:paneVerbs({ { "opt:open", ZeD.tr("UI_ZeD_Mods_VerbOpenOptions"), function() self:openInOptions() end } }, ix, cy, iw, vy, vh, 790) + T.px(8)
    end
    if not (d.isActive and MS.isLoaded(d.modId)) then
        local key = d.isActive and "UI_ZeD_Mods_OptAfterReload" or "UI_ZeD_Mods_OptTurnOn"
        cy = self:paneNote(ZeD.tr(key), ix, iw, cy)
        if not d.isActive then
            cy = self:paneVerbs({ { "opt:on", ZeD.tr("ContextMenu_Turn_On"), function() self:toggle(d) end, "primary", self:problem(d) ~= nil } }, ix, cy, iw, vy, vh, 790) + T.px(8)
        end
        local n = S.sandboxCount(d.modId)
        if n > 0 then cy = self:paneText(ZeD.tr(n == 1 and "UI_ZeD_Mods_OptSandboxStillOne" or "UI_ZeD_Mods_OptSandboxStill", n), ix, cy, iw, f2, dim) + T.px(4) end
        return cy
    end
    local data = S.optionRows(d.modId)
    if data.count == 0 then return self:paneNote(ZeD.tr("UI_ZeD_Mods_OptNone"), ix, iw, cy) end
    local idx = 0
    for _, sec in ipairs(data.sections) do
        local head = ZeD.upper(ZeD.tr("UI_ZeD_Mods_OptHead"))
        if #data.sections > 1 then head = ZeD.upper(sec.title) end
        local la = T.accent
        self:drawText(head, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
        local sub = ZeD.tr("UI_ZeD_Mods_OptHeadNote")
        local sw = MM.textW(T.fontF3, sub)
        if MM.textW(f1, head) + sw + T.px(20) < iw then self:drawText(sub, ix + iw - sw, cy, dim.r, dim.g, dim.b, dim.a or 1, T.fontF3) end
        cy = cy + MM.fontH(f1) + T.px(3)
        self:drawRect(ix, cy, iw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
        cy = cy + T.px(2)
        for _, e in ipairs(sec.entries) do
            if e.kind == "header" then
                cy = cy + T.px(6)
                cy = self:paneText(ZeD.upper(e.text), ix + T.px(14), cy, iw - T.px(14), f1, T.textHead) + T.px(2)
            elseif e.kind == "note" then
                cy = self:paneText(e.text, ix + T.px(14), cy + T.px(4), iw - T.px(14), f2, dim) + T.px(4)
            else
                idx = idx + 1
                cy = self:drawOptionRow(e, idx, ix, iw, cy, vy, vh)
            end
        end
        cy = cy + T.px(8)
    end
    local verbs = {
        { "opt:defaults", ZeD.tr("UI_ZeD_Options_Defaults"), function() if S.defaults(d.modId) then MM.clickSound(); self:say(ZeD.tr("UI_ZeD_Mods_SayDefaults", d.name)) end end, "default", not S.offDefault(d.modId) },
        { "opt:open", ZeD.tr("UI_ZeD_Mods_VerbOpenOptions"), function() self:openInOptions() end, "default", self:changed() or self:reordered() },
    }
    return self:paneVerbs(verbs, ix, cy, iw, vy, vh, 990) + T.px(8)
end

-- the Options window on its Mods page (the Mods screen has nothing waiting: the button is off then)
function ZeD_MMMods:openInOptions()
    MM.clickSound()
    MM.showView("options")
    local ow = MM.root and MM.root.optsWin
    if ow and ow.pages then
        for i, p in ipairs(ow:pages()) do if p.raw == "mods" then ow.pageIdx = i end end
        ow.scroll = 0
    end
end

-- ----------------------------------------------------------------------------
-- SANDBOX
-- ----------------------------------------------------------------------------
function ZeD_MMMods:drawSandboxTab(d, ix, iw, cy, vy, vh)
    local T = ZeD.T
    local f1, f2 = T.fontF1, T.fontF2
    local dim = T.textDim
    local s = S.sandbox(d.modId)
    if not s or #s.list == 0 then return self:paneNote(ZeD.tr("UI_ZeD_Mods_SbNone"), ix, iw, cy) end
    local la = T.accent
    local head = ZeD.upper(ZeD.tr("UI_ZeD_Mods_SbHead"))
    self:drawText(head, ix, cy, la.r, la.g, la.b, la.a or 1, f1)
    local sub = ZeD.tr(d.isActive and "UI_ZeD_Mods_SbHeadNote" or "UI_ZeD_Mods_SbHeadNoteOff")
    local sw = MM.textW(T.fontF3, sub)
    if MM.textW(f1, head) + sw + T.px(20) < iw then self:drawText(sub, ix + iw - sw, cy, dim.r, dim.g, dim.b, dim.a or 1, T.fontF3) end
    cy = cy + MM.fontH(f1) + T.px(3)
    self:drawRect(ix, cy, iw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
    cy = cy + T.px(6)
    -- where they are chosen
    local pages = table.concat(s.pages, ", ")
    cy = self:paneNote(pages ~= "" and ZeD.tr("UI_ZeD_Mods_SbWhere", pages) or ZeD.tr("UI_ZeD_Mods_SbWhereNoPage"), ix, iw, cy, T.info)
    local lw = math.floor(iw * LABEL_SHARE)
    local cx = ix + lw + T.px(10)
    local rh = T.px(OPT_ROW_H) - T.px(4)
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local gp = MM.gamepad()
    local ac = T.accent
    for i, st in ipairs(s.list) do
        local sid = "msb:" .. i
        if cy + rh > vy and cy < vy + vh then
            if gp and self.focusId == sid then self:drawRect(ix - T.px(4), cy, iw + T.px(8), rh, 0.55, ac.r, ac.g, ac.b); self._helpEntry = { sandbox = st } end
            if mx >= ix and mx < ix + iw and my >= cy and my < cy + rh and my >= vy and my < vy + vh then self._helpEntry = { sandbox = st } end
            local ty = cy + math.floor((rh - MM.fontH(f2)) / 2)
            local c = T.text
            self:drawText(ZeD.Atoms.truncateText(st.label, f2, lw - T.px(18)), ix + T.px(14), ty, c.r, c.g, c.b, c.a or 1, f2)
            if st.type == "boolean" then
                local cb = T.checkboxSz
                ZeD.Atoms.drawCheckbox(self, cx, cy + math.floor((rh - cb) / 2), st.on, false, true)
            else
                self:drawText(ZeD.Atoms.truncateText(tostring(st.value or ""), f2, ix + iw - cx), cx, ty, c.r, c.g, c.b, c.a or 1, f2)
            end
            self:drawRect(ix, cy + rh - T.px(1), iw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
        end
        self._specs[#self._specs + 1] = { id = sid, listRow = true, paneStop = true, row = 800 + i, col = 1, x = ix, y = cy, w = iw, h = rh,
                                          clipTop = vy, clipBot = vy + vh, fn = function() end }
        cy = cy + rh
    end
    return cy + T.px(8)
end

-- the band at the pane's foot: the row under the pointer, or the controller's
function ZeD_MMMods:drawHelpBand(x, y, w, h)
    local T = ZeD.T
    local s2, bs = T.surf2, T.borderS
    self:drawRect(x + T.px(1), y, w - 2 * T.px(1), h - T.px(1), 1, s2.r, s2.g, s2.b)
    self:drawRect(x + T.px(1), y, w - 2 * T.px(1), T.px(1), bs.a, bs.r, bs.g, bs.b)
    local e = (not MM.ctx.open and not self._palette) and self._helpEntry or nil
    if not e then return end
    local f2 = T.fontF2
    local title, text, side = nil, nil, {}
    if e.sandbox then
        local st = e.sandbox
        title, text = st.label, st.tooltip
        local def = (st.type == "boolean") and ZeD.tr(st.on and "UI_ZeD_Mods_ValueOn" or "UI_ZeD_Mods_ValueOff") or tostring(st.value or "")
        side[#side + 1] = ZeD.tr("UI_ZeD_Options_DefaultIs", def)
        if st.range and (st.range[1] or st.range[2]) then side[#side + 1] = ZeD.tr("UI_ZeD_Mods_SbRange", st.range[1] or "?", st.range[2] or "?") end
    else
        title, text = e.label, S.help(e)
        local def = S.defaultText(e)
        if def then side[#side + 1] = ZeD.tr("UI_ZeD_Options_DefaultIs", def) end
    end
    local dcol = 0
    if #side > 0 then
        local wmax = 0
        for _, l in ipairs(side) do wmax = math.max(wmax, MM.textW(T.fontF3, l)) end
        dcol = math.min(T.px(200), wmax + T.px(26))
        local dx = x + w - T.px(1) - dcol
        local bd, d = T.border, T.textDim
        self:drawRect(dx, y + T.px(7), T.px(1), h - 2 * T.px(7), bd.a or 1, bd.r, bd.g, bd.b)
        local ly = y + T.px(8)
        for _, l in ipairs(side) do
            self:drawText(ZeD.Atoms.truncateText(l, T.fontF3, dcol - T.px(24)), dx + T.px(12), ly, d.r, d.g, d.b, d.a or 1, T.fontF3)
            ly = ly + MM.fontH(T.fontF3) + T.px(3)
        end
    end
    local words = (text and text ~= "") and ZeD.tr("UI_ZeD_Mods_HelpTitled", title, text) or title
    local tc = T.text
    local ly = y + T.px(8)
    for k, l in ipairs(ZeD.Atoms.wrapText(words, f2, w - T.px(24) - dcol)) do
        if k > 3 then break end
        self:drawText(l, x + T.px(12), ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
        ly = ly + MM.fontH(f2) + T.px(3)
    end
end

-- ----------------------------------------------------------------------------
-- CONFLICTS: same text, picks
-- ----------------------------------------------------------------------------
-- the files of a conflict, as the picker lists them
local function thingsOf(e) local t = {}; for _, p in ipairs(e.things) do t[#t + 1] = p end; return t end

-- the picker can open: a file conflict whose copies differ, both mods on and loaded, the helper there
function ZeD_MMMods:canPick(e)
    if e.kind ~= "file" or e.sameAll then return false end
    if not P.helper() then return false end
    local m = model()
    local a, b = m and m.mods[e.loser], m and m.mods[e.winner]
    return a and b and a.isActive and b.isActive and MS.isLoaded(e.loser) and MS.isLoaded(e.winner) and true or false
end

-- the card for a conflict settled by picks (or the same-text note); returns the y under it, or nil
function ZeD_MMMods:drawConflictExtra(e, i, d, ix, iw, cy, vy, vh)
    local T = ZeD.T
    local f2, f3 = T.fontF2, T.fontF3
    local dsz = T.px(7)
    local tx, tw = ix + dsz + T.px(7), iw - dsz - T.px(7)
    local other = (e.loser == d.modId) and e.winner or e.loser
    if e.sameAll then
        ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.textDim, dsz)
        local title = (#e.things == 1) and ZeD.tr("UI_ZeD_Mods_SameTextOne", MS.modName(other)) or ZeD.tr("UI_ZeD_Mods_SameTextMany", #e.things, MS.modName(other))
        cy = self:paneText(title, tx, cy, tw, f2, T.textHead)
        cy = self:paneText(#e.things > 1 and ZeD.tr("UI_ZeD_Mods_AndMore", MS.thingText(e.things[1]), #e.things - 1) or MS.thingText(e.things[1]), tx, cy, tw, f3, T.textDim) + T.px(2)
        cy = self:paneText(ZeD.tr("UI_ZeD_Mods_SameTextWhy"), tx, cy, tw, f2, T.text) + T.px(6)
        return self:paneVerbs({ { "cf:hide:" .. i, ZeD.tr("UI_ZeD_Mods_VerbHide"), function() MS.hide(e); self:dirty(); MM.clickSound() end } }, tx, cy, tw, vy, vh, 600 + i) + T.px(10)
    end
    local n, from = P.countIn(e.things)
    if n == 0 then return nil end
    ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.positive, dsz)
    cy = self:paneText(ZeD.tr(n == 1 and "UI_ZeD_Mods_PickedOne" or "UI_ZeD_Mods_PickedMany", n, MS.modName(from)), tx, cy, tw, f2, T.textHead)
    local shown = 0
    for _, path in ipairs(e.things) do
        if P.pickOf(path) and shown < 4 then shown = shown + 1; cy = self:paneText(path, tx, cy, tw, f3, T.textDim) end
    end
    if n > shown then cy = self:paneText(ZeD.tr("UI_ZeD_Mods_PickedMore", n - shown), tx, cy, tw, f3, T.textDim) end
    local keep = #e.things - n
    local winnerName = MS.modName(from == e.loser and e.winner or e.loser)
    cy = self:paneText(ZeD.tr(keep == 1 and "UI_ZeD_Mods_PickedKeepsOne" or "UI_ZeD_Mods_PickedKeeps", winnerName, keep), tx, cy + T.px(2), tw, f2, T.text) + T.px(6)
    local verbs = {}
    if self:canPick(e) then verbs[#verbs + 1] = { "cf:repick:" .. i, ZeD.tr("UI_ZeD_Mods_VerbChangePicks"), function() self:enterPicks(e) end } end
    verbs[#verbs + 1] = { "cf:unpick:" .. i, ZeD.tr("UI_ZeD_Mods_VerbUndoPicks"), function() self:undoPicks(e) end }
    return self:paneVerbs(verbs, tx, cy, tw, vy, vh, 600 + i) + T.px(10)
end

function ZeD_MMMods:undoPicks(e)
    local draft = {}
    P.commit(thingsOf(e), draft)
    self:afterPicks()
    MM.clickSound()
    self:say(ZeD.tr("UI_ZeD_Mods_SayPicksUndone"))
end

-- ----------------------------------------------------------------------------
-- THE PICKER (page "picks")
-- ----------------------------------------------------------------------------
function ZeD_MMMods:enterPicks(e)
    MM.clickSound()
    MM.ctx.open = nil
    self.confirm = false
    self.page = "picks"
    self.pickFor = e
    self.pickFiles = thingsOf(e)
    self.pickDraft = {}
    for _, path in ipairs(self.pickFiles) do self.pickDraft[path] = P.pickOf(path) end
    self.pickSel = 1
    self.scroll = 0
    self.focusId = "pfile:1"
end

function ZeD_MMMods:leavePicks()
    self.page = "list"
    self.pickFor, self.pickFiles, self.pickDraft = nil, nil, nil
    self.scroll = 0
    self.focusId = nil
    MM.clickSound()
end

-- the draft differs from what is kept
function ZeD_MMMods:picksChanged()
    for _, path in ipairs(self.pickFiles or {}) do
        if self.pickDraft[path] ~= P.pickOf(path) then return true end
    end
    return false
end

-- after picks change: the helper's copies, the helper on and last, the counts
function ZeD_MMMods:afterPicks()
    local m = model()
    local order = m and jlist(m:getActiveMods():getMods()) or {}
    if P.holdsAny() and m then
        local h = m.mods[P.HELPER]
        if h and not h.isActive and P.activeCount(order) > 0 then
            m:forceActivateMods(h.modInfo, true)
            order = jlist(m:getActiveMods():getMods())
        end
    end
    if P.sync(order) > 0 then self._picksRefreshed = true end
    self:helperLast()
    MS.dirtyCounts()
    self:dirty()
end

-- ZeD picks loads after every other mod (its copies must win)
function ZeD_MMMods:helperLast()
    local m = model()
    if not m then return end
    local order = jlist(m:getActiveMods():getMods())
    local at = nil
    for i, id in ipairs(order) do if id == P.HELPER then at = i end end
    if not at or at == #order then return end
    table.remove(order, at)
    order[#order + 1] = P.HELPER
    m:correctAndSaveModOrder(order)
end

function ZeD_MMMods:usePicks()
    P.commit(self.pickFiles, self.pickDraft)
    local n = 0
    for _, path in ipairs(self.pickFiles) do if self.pickDraft[path] then n = n + 1 end end
    self:afterPicks()
    local e = self.pickFor
    self:leavePicks()
    if n > 0 and e then self:say(ZeD.tr("UI_ZeD_Mods_SayPicksKept", n)) end
end

-- the picker's two columns
function ZeD_MMMods:drawPicker(x, y, w, h)
    local T = ZeD.T
    local e = self.pickFor
    if not e then return end
    local lw = math.floor(w * 0.36)
    self:drawPickFiles(x, y, lw, h)
    self:drawPickCompare(x + lw + T.px(10), y, w - lw - T.px(10), h)
end

function ZeD_MMMods:drawPickFiles(x, y, w, h)
    local T = ZeD.T
    local e = self.pickFor
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    local f2, f3 = T.fontF2, T.fontF3
    local s2 = T.surf2
    local headH = T.px(30)
    self:drawRect(x + T.px(1), y + T.px(1), w - 2 * T.px(1), headH, 1, s2.r, s2.g, s2.b)
    local nPicked = 0
    for _, p in ipairs(self.pickFiles) do if self.pickDraft[p] then nPicked = nPicked + 1 end end
    local la = T.accent
    self:drawText(ZeD.upper(ZeD.tr("UI_ZeD_Mods_PickShared", #self.pickFiles, nPicked)), x + T.px(10), y + math.floor((headH - MM.fontH(T.fontF1)) / 2), la.r, la.g, la.b, la.a or 1, T.fontF1)
    self:drawRect(x, y + headH, w, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    local vy, vh = y + headH + T.px(1), h - headH - T.px(2)
    local rh = T.px(38)
    local rowsH = #self.pickFiles * rh
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, rowsH - vh)))
    self._list = { x = x, y = vy, w = w, h = vh }
    local gp, ac = MM.gamepad(), T.accent
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    for i, path in ipairs(self.pickFiles) do
        local ry = vy + (i - 1) * rh - self.scroll
        local rid = "pfile:" .. i
        self._specs[#self._specs + 1] = { id = rid, listRow = true, pickRow = i, row = i, col = 1, ry = (i - 1) * rh, rh = rh, index = i,
                                          fn = function() self:flipPick(path) end }
        if ry + rh > vy and ry < vy + vh then
            if gp and self.focusId == rid then self:drawRect(x + T.px(1), ry, w - T.px(2), rh, 0.55, ac.r, ac.g, ac.b)
            elseif self.pickSel == i then self:drawRect(x + T.px(1), ry, w - T.px(2), rh, 0.22, ac.r, ac.g, ac.b) end
            self:drawRect(x + T.px(1), ry + rh - T.px(1), w - T.px(2), T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local file = path:match("([^/]+)$") or path
            local dir = path:match("^media/lua/(.*)/[^/]+$") or ""
            local from = self.pickDraft[path]
            local chipText = from and ZeD.tr("UI_ZeD_Mods_PickChipPicked", MS.modName(from)) or MS.modName(e.winner)
            local cwid = math.min(math.floor(w * 0.45), MM.textW(T.fontF1, chipText) + T.sp.badgePadX * 2)
            chipText = ZeD.Atoms.truncateText(chipText, T.fontF1, cwid - T.sp.badgePadX * 2)
            local chh = MM.fontH(T.fontF1) + T.sp.badgePadY * 2
            local chx = x + w - T.px(10) - cwid
            local b = T.base
            self:drawRect(chx, ry + math.floor((rh - chh) / 2), cwid, chh, 1, b.r, b.g, b.b)
            ZeD.Atoms.drawBadge(self, chipText, chx, ry + math.floor((rh - chh) / 2), from and "positive" or "neutral", false, T.fontF1, true)
            local tc, dim = T.textHead, T.textDim
            local room = chx - T.px(8) - (x + T.px(10))
            self:drawText(ZeD.Atoms.truncateText(file, f2, room), x + T.px(10), ry + T.px(4), tc.r, tc.g, tc.b, tc.a or 1, f2)
            self:drawText(ZeD.Atoms.truncateText(dir, f3, room), x + T.px(10), ry + rh - T.px(4) - MM.fontH(f3), dim.r, dim.g, dim.b, dim.a or 1, f3)
            local cy0, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = "mods:pfile:" .. i, x = ax + x, y = ay + cy0, w = w - T.px(2), h = ch, fn = function()
                if self.pickSel ~= i then self.pickSel = i; MM.hoverSound() end
                self.focusId = rid
            end }
        end
    end
    self:clearStencilRect()
end

-- A on a file: the other copy (a pick of the losing mod, or back to load order)
function ZeD_MMMods:flipPick(path)
    local e = self.pickFor
    if not e then return end
    for i, p in ipairs(self.pickFiles) do if p == path then self.pickSel = i end end
    if self.pickDraft[path] then self.pickDraft[path] = nil else self.pickDraft[path] = e.loser end
    MM.clickSound()
end

function ZeD_MMMods:setPick(path, id)
    local e = self.pickFor
    self.pickDraft[path] = (id ~= e.winner) and id or nil
    MM.clickSound()
end

-- the chosen file: both copies, the choice, the differing lines
function ZeD_MMMods:drawPickCompare(x, y, w, h)
    local T = ZeD.T
    local e = self.pickFor
    local path = self.pickFiles[self.pickSel or 1]
    if not path then return end
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local bs = T.borderS
    self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    local pad = T.px(12)
    local ix, iw = x + pad, w - pad * 2
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local la, dim = T.accent, T.textDim
    local cy = y + pad
    local la1, lb1 = P.lines(e.loser, path), P.lines(e.winner, path)
    local nDiff = P.diffCount(la1, lb1)
    local file = path:match("([^/]+)$") or path
    self:drawText(ZeD.upper(file), ix, cy, la.r, la.g, la.b, la.a or 1, f1)
    local dtext = ZeD.tr(nDiff == 1 and "UI_ZeD_Mods_PickDiffOne" or "UI_ZeD_Mods_PickDiffMany", nDiff)
    self:drawText(dtext, ix + iw - MM.textW(f3, dtext), cy, dim.r, dim.g, dim.b, dim.a or 1, f3)
    cy = cy + MM.fontH(f1) + T.px(3)
    cy = self:paneText(path, ix, cy, iw, f3, dim)
    cy = self:paneText(ZeD.tr("UI_ZeD_Mods_PickChoose"), ix, cy + T.px(2), iw, f2, T.text) + T.px(8)
    -- the two choices
    local cardH = T.px(44)
    local cw = math.floor((iw - T.px(8)) / 2)
    local function card(cx, id, lines, now)
        local on = (self.pickDraft[path] or e.winner) == id
        local hid = "mods:pcard:" .. id
        local hot = MM.ctx.hot == hid
        local s = on and T.accent or T.surf2
        local s2 = T.surf2
        self:drawRect(cx, cy, cw, cardH, 1, s2.r, s2.g, s2.b)
        if on then self:drawRect(cx, cy, cw, cardH, 0.22, s.r, s.g, s.b) end
        local bc = (on or hot) and T.accent or T.borderS
        self:drawRectBorder(cx, cy, cw, cardH, bc.a or 1, bc.r, bc.g, bc.b)
        local rr = T.px(12)
        local rx, ry = cx + T.px(10), cy + T.px(9)
        -- a System 7 radio: a ring (border dot, then the fill), the accent dot when chosen
        ZeD.Atoms.drawStatusRing(self, rx, ry, (on or hot) and T.accent or T.borderS, rr)
        if on then ZeD.Atoms.drawStatusDot(self, rx + T.px(3), ry + T.px(3), T.accent, rr - 2 * T.px(3)) end
        local tc = T.textHead
        local tx = rx + rr + T.px(8)
        self:drawText(ZeD.Atoms.truncateText(MS.modName(id), f2, cx + cw - T.px(10) - tx), tx, ry - T.px(2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        local n = #(lines or {})
        local sub
        if self.pickDraft[path] == id then sub = ZeD.tr("UI_ZeD_Mods_PickPickedSub", n)
        elseif now and self.pickDraft[path] then sub = ZeD.tr("UI_ZeD_Mods_PickLoadsLater", n)
        elseif now then sub = ZeD.tr("UI_ZeD_Mods_PickRunsNow", n)
        else sub = ZeD.tr("UI_ZeD_Mods_PickNeverRuns", n) end
        self:drawText(ZeD.Atoms.truncateText(sub, f3, cx + cw - T.px(10) - tx), tx, ry + MM.fontH(f2), dim.r, dim.g, dim.b, dim.a or 1, f3)
        self._hits[#self._hits + 1] = { id = hid, x = ax + cx, y = ay + cy, w = cw, h = cardH, fn = function() self:setPick(path, id) end }
        self._specs[#self._specs + 1] = { id = "pcard:" .. id, listRow = true, paneStop = true, row = 400, col = (id == e.loser) and 1 or 2,
                                          x = cx, y = cy, w = cw, h = cardH, fn = function() self:setPick(path, id) end }
    end
    card(ix, e.loser, la1, false)
    card(ix + cw + T.px(8), e.winner, lb1, true)
    cy = cy + cardH + T.px(10)
    -- the two copies
    local noteH = T.px(44)
    local codeH = math.max(T.px(80), y + h - pad - noteH - T.px(8) - cy)
    -- as many lines as the boxes hold (their title row aside)
    local fit = math.floor((codeH - MM.fontH(T.fontF1) - T.px(14)) / (MM.fontH(T.fontF3) + T.px(2))) - 1
    local ea, eb = P.excerpt(la1, lb1, math.max(CODE_LINES, fit))
    self:drawCode(ix, cy, cw, codeH, ZeD.upper(MS.modName(e.loser)), ea)
    self:drawCode(ix + cw + T.px(8), cy, cw, codeH, ZeD.upper(MS.modName(e.winner)), eb)
    cy = cy + codeH + T.px(8)
    -- the warning
    local s2 = T.surf2
    self:drawRect(ix, cy, iw, noteH, 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(ix, cy, iw, noteH, bs.a, bs.r, bs.g, bs.b)
    local dsz = T.px(7)
    ZeD.Atoms.drawStatusDot(self, ix + T.px(10), cy + T.px(8) + math.floor((MM.fontH(f2) - dsz) / 2), T.warningText, dsz)
    local ly = cy + T.px(6)
    for k, l in ipairs(ZeD.Atoms.wrapText(ZeD.tr("UI_ZeD_Mods_PickWarn"), f2, iw - T.px(30))) do
        if k > 2 then break end
        self:drawText(l, ix + T.px(24), ly, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
        ly = ly + MM.fontH(f2) + T.px(2)
    end
end

-- a copy's stretch: line numbers, the text, changed lines marked
function ZeD_MMMods:drawCode(x, y, w, h, title, lines)
    local T = ZeD.T
    local f1, f3 = T.fontF1, T.fontF3
    UI.insetBox(self, x, y, w, h)
    local la, dim = T.accent, T.textDim
    local hy = y + T.px(5)
    self:drawText(ZeD.Atoms.truncateText(title, f1, w - T.px(16)), x + T.px(8), hy, la.r, la.g, la.b, la.a or 1, f1)
    local ly = hy + MM.fontH(f1) + T.px(5)
    self:drawRect(x + T.px(1), ly - T.px(3), w - 2 * T.px(1), T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
    local lh = MM.fontH(f3) + T.px(2)
    local numW = MM.textW(f3, "0000") + T.px(4)
    local wn = T.warning
    self:setStencilRect(x + T.px(1), y + T.px(1), w - T.px(2), h - T.px(2))
    for _, l in ipairs(lines or {}) do
        if ly + lh > y + h - T.px(2) then break end
        if l.gap then
            self:drawText("...", x + T.px(8), ly, dim.r, dim.g, dim.b, dim.a or 1, f3)
        else
            if l.changed then self:drawRect(x + T.px(1), ly - T.px(1), w - 2 * T.px(1), lh, 0.16, wn.r, wn.g, wn.b) end
            self:drawText(tostring(l.n), x + T.px(6), ly, dim.r, dim.g, dim.b, (dim.a or 1) * 0.7, f3)
            local c = l.changed and T.textHead or T.text
            local text = tostring(l.text or ""):gsub("\t", "    ")
            self:drawText(text, x + T.px(6) + numW, ly, c.r, c.g, c.b, c.a or 1, f3)
        end
        ly = ly + lh
    end
    self:clearStencilRect()
end

-- the picker's strip
function ZeD_MMMods:pickStrip(stripY, w, row)
    local T = ZeD.T
    local n = 0
    for _, p in ipairs(self.pickFiles or {}) do if self.pickDraft[p] then n = n + 1 end end
    local askX = UI.stripSpecs(self, stripY, w, row,
        { { "back", getText("UI_btn_cancel"), function() self:leavePicks() end } },
        { { "usepicks", ZeD.tr("UI_ZeD_Mods_BtnUsePicks"), function() self:usePicks() end, "primary", not self:picksChanged() } })
    local e = self.pickFor
    local ask
    if n > 0 then ask = ZeD.tr(n == 1 and "UI_ZeD_Mods_PickStripOne" or "UI_ZeD_Mods_PickStripMany", n, MS.modName(e.loser), MS.modName(e.winner), #self.pickFiles - n)
    else ask = ZeD.tr("UI_ZeD_Mods_PickStripNone") end
    local firstBtn = w
    for _, b in ipairs(self._specs) do if b.row == row and b.x > askX then firstBtn = math.min(firstBtn, b.x) end end
    local room = firstBtn - T.px(12) - (askX + T.px(4))
    if room > T.px(60) then return ZeD.Atoms.truncateText(ask, T.fontF2, room), askX + T.px(4) end
    return nil, nil
end
