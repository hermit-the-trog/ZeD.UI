-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuServer.lua
-- ============================================================================
-- SERVER SETTINGS ON THE MONITOR (HOOK_MAP row 26; director, Oct 14 2026:
-- menus delegated, no mockups)
--
-- Vanilla's ServerSettingsScreen stays built and hidden as the engine. Its
-- pages keep flipping their own visibility as vanilla navigates, so this one
-- window follows whichever page is current and calls that page's own methods:
--   list      the settings files (Page1): NEW... DUPLICATE... RENAME...
--             DELETE... and EDIT, the chosen settings' files beside the list
--   new / duplicate / rename   a name field with vanilla's rules, the reason a
--             name will not do, the files it makes (Page2 / 4 / 5)
--   delete    the files that go, asked in the band (Page6)
--   mods      the server's mods before editing (ChooseModsWindow); CHOOSE
--             MODS... opens the mod manager in its server mode
--   edit      Page3 on the Sandbox Options window's rows: the server's INI
--             pages and its sandbox pages, numbers edited in their row, a dot
--             on every option changed since the page opened; the special pages
--             as ZeD lists: Mods (read only), Map (order, remove, add installed
--             or by folder), Spawn Regions (each region's name and file, add,
--             remove, EDIT SPAWN POINTS..., the fixed spawn point), Steam
--             Workshop items (remove, add installed or by ID), sandbox presets
--   points    spawn points per occupation for one region file (Page7)
-- The screen's setVisible(true) is redirected here.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuOptions"
require "ZeD/ZeD_MainMenuSandbox"
require "OptionScreens/ServerSettingsScreen"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local PAGE_ROW_H, HEAD_H = 30, 24
local LIST_ROW_H, FIELD_H = 30, 24
local PAGES_W, ENTRY_W = 210, 170

local function ms() return MainScreen and MainScreen.instance end
local function sss() return ServerSettingsScreen and ServerSettingsScreen.instance end
local function s(v) if v == nil then return "" end; return tostring(v) end
local function comboText(c, i) local ok, t = pcall(function() return c:getOptionText(i) end); return ok and tostring(t or "") or "" end
local function plainTip(t)
    if type(t) == "table" then t = t.defaultTooltip end
    if type(t) ~= "string" then return "" end
    return UI.plain(t)
end

-- The mods step's NEXT: vanilla reloads every Lua file with the server's mods when they
-- differ from the menu's (so their sandbox options are there to edit). When the only
-- difference is ZeD UI itself (a client interface with no sandbox options), that reload
-- would only take ZeD away for the edit, so NEXT goes on without it. Any other difference
-- reloads as vanilla does (the editor is then vanilla's until SAVE / CANCEL reloads back).
local ZED_ID = "ZeD_UI"
local function onlyZeDDiffers(ids)
    local loaded = getActivatedMods()
    local a, b = {}, {}
    for i = 0, loaded:size() - 1 do
        local id = loaded:get(i)
        if id ~= ZED_ID then a[#a + 1] = id end
    end
    for _, id in ipairs(ids) do if id ~= ZED_ID then b[#b + 1] = id end end
    if #a ~= #b then return false end
    for i = 1, #a do if a[i] ~= b[i] then return false end end
    return true
end
local function modsNext(cw)
    local ids = {}
    for _, it in ipairs(cw.listbox.items) do ids[#ids + 1] = it.item.modID end
    if not onlyZeDDiffers(ids) then cw:onButtonNext(); return end
    local orig = ActiveMods.requiresResetLua
    ActiveMods.requiresResetLua = function() return false end
    local ok, err = pcall(function() cw:onButtonNext() end)
    ActiveMods.requiresResetLua = orig
    if not ok then error(err) end
end

-- vanilla's page flips hand the controller to its hidden pages; the desk keeps it
local function holdJoypad()
    local jd = JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad()
    local m = ms()
    if jd and m and jd.focus ~= m then jd.focus = m; updateJoypadFocus(jd) end
end

-- OCCUPATIONS IN SPAWN POINT FILES (Page7).
-- Spawn files name the game's own occupations plainly ("unemployed", "chef": the maps'
-- files, vanilla's save rule); 42's list names them "base:unemployed", so an occupation
-- picked from the list is kept under its plain name (vanilla kept the long one, and its
-- save rule then never passed). Other mods' occupations keep their full name.
local function plainProf(id)
    id = s(id)
    if id:sub(1, 5) == "base:" then return id:sub(6) end
    return id
end
-- 42 looks occupations up by object, not by name (vanilla's page still passes the name,
-- which throws: its add and its loading of a file with occupations both fail), so the
-- name goes through the registry once and the answer is kept
local _profDefs = {}
local function profDef(id)
    id = s(id)
    local hit = _profDefs[id]
    if hit == nil then
        hit = false
        pcall(function()
            local p = CharacterProfession.get(ResourceLocation.of(id:find(":") and id or ("base:" .. id)))
            if p then hit = CharacterProfessionDefinition.getCharacterProfessionDefinition(p) or false end
        end)
        _profDefs[id] = hit
    end
    return hit or nil
end
local function profLabel(id)
    local d = profDef(id)
    return d and d:getLabel() or s(id)
end

-- vanilla's Page7:addProfessionToList with the lookup above
local function addProf(pg, id, points, select)
    local d = profDef(id)
    pg.profListBox:addItem(d and d:getLabel() or id, { professionType = id, points = points or {}, otherText = d and id or nil })
    if select then
        pg.profListBox.selected = #pg.profListBox.items
        pg:fillPointList()
    end
end

-- vanilla's SpawnRegionsPanel:onButtonEditRegion + Page7:aboutToShow, with the lookup
-- above (the region file's occupations in label order)
local function openPoints(panel)
    local S = sss()
    local pg = S and S.pageSpawnPoints
    local lb = panel.listbox
    local it = lb.items[lb.selected]
    if not pg or not it then return end
    pg.settings = panel.settings
    pg.region = it.item
    pg.profListBox:clear()
    local t = pg.settings:loadSpawnPointsFile(pg.region.file)
    local ids = {}
    for id, _ in pairs(t or {}) do ids[#ids + 1] = id end
    table.sort(ids, function(a, b) return profLabel(a) < profLabel(b) end)
    for _, id in ipairs(ids) do addProf(pg, id, t[id], false) end
    pg.profListBox.selected = 1
    pg:fillPointList()
    pg:fillProfessionCombo()
    S.pageEdit:setVisible(false)
    pg:setVisible(true)
    holdJoypad()
end

-- the list's choices without the ones already there (under either name)
local function trimProfChoices(pg)
    local keep = {}
    for _, o in ipairs(pg.profComboBox.options or {}) do
        local id = o.data and o.data:getType()
        if not (id and pg:isProfessionInList(plainProf(id))) then keep[#keep + 1] = o end
    end
    if #keep ~= #(pg.profComboBox.options or {}) then pg.profComboBox.options = keep; pg.profComboBox.selected = 1 end
end

-- ============================================================================
ZeD_MMServer = ZeD_MMSandbox:derive("ZeD_MMServer")

function ZeD_MMServer:new()
    local o = ZeD_MMWindow.new(self, "srvset")
    o.inGame = false
    o.noResetControl = true
    o.pageIdx = 2
    o.scroll = 0
    o.confirm = false     -- false | "discard"
    o.snap = {}
    o.diff, o.nDiff = {}, 0
    o.dirty = false       -- a special page (maps, regions, Workshop) changed
    o.changedNote = "UI_ZeD_Server_ChangedNote"   -- (a translation key; the Options window's help band turns it into words)
    o.ctx = { hot = nil, press = nil, wasDown = false }
    return o
end

function ZeD_MMServer:createChildren()
    ZeD_MMSandbox.createChildren(self)    -- Find, the band's field, the in-place number cell
    local function entry()
        local e = UI.newEntry(self)
        e:setVisible(false)
        e.onCommandEntered = function() self._enterAt = MM.now(); e:unfocus() end
        return e
    end
    self.nameEntry = entry()     -- a settings name (new / duplicate / rename): Return goes on
    self.nameEntry.onCommandEntered = function()
        self._enterAt = MM.now()
        if not self:nameProblem(self:mode()) then self.nameEntry:unfocus(); self:act("accept") end
    end
    self.regName, self.regFile = entry(), entry()   -- the chosen spawn region
    self.spawnPt = entry()       -- the fixed spawn point x,y,z
    self.other = entry()         -- a map folder, a Workshop ID or an occupation to add
    self.other.onCommandEntered = function() self._enterAt = MM.now(); self:addOther() end
    self.pointEntry = entry()    -- a spawn point x,y,z to add
    self.pointEntry.onCommandEntered = function() self._enterAt = MM.now(); self:addPoint() end
    self._extra = { self.nameEntry, self.regName, self.regFile, self.spawnPt, self.other, self.pointEntry }
end

-- WHICH PAGE VANILLA IS ON -----------------------------------------------------------
function ZeD_MMServer:mode()
    local S = sss()
    if not S then return "list" end
    if S.pageEdit and S.pageEdit:getIsVisible() then return "edit" end
    if S.pageEdit and S.pageEdit.chooseModsWindow and S.pageEdit.chooseModsWindow:getIsVisible() then return "mods" end
    if S.pageNew and S.pageNew:getIsVisible() then return "new" end
    if S.pageDuplicate and S.pageDuplicate:getIsVisible() then return "duplicate" end
    if S.pageRename and S.pageRename:getIsVisible() then return "rename" end
    if S.pageDelete and S.pageDelete:getIsVisible() then return "delete" end
    if S.pageSpawnPoints and S.pageSpawnPoints:getIsVisible() then return "points" end
    return "list"
end

-- entering a page: its fields from vanilla; the edit page's starting values (not when
-- coming back from a region's spawn points: that is the same edit going on)
function ZeD_MMServer:enterMode(m, prev)
    local S = sss()
    holdJoypad()
    self.confirm = false
    self:endCell()
    self._lists, self._listSel = {}, {}
    self.focusId = nil
    MM.ctx.open = nil
    if m == "new" or m == "duplicate" or m == "rename" then
        local p = (m == "new") and S.pageNew or ((m == "duplicate") and S.pageDuplicate or S.pageRename)
        self.nameEntry:setText(s(p.entry:getText()))
        self.nameEntry:setVisible(true)
        self.nameEntry:focus()
        pcall(function() self.nameEntry:selectAll() end)
    elseif m == "points" then
        self.other:setText("")
        self.pointEntry:setText("")
    elseif m == "edit" and prev ~= "points" then
        self.scroll = 0
        self.pagesScroll = 0
        self.find:setText("")
        self.other:setText("")
        self.dirty = false
        self._regFor = nil
        self:snapshotEdit()
        local sp = self:customPanel("SpawnRegionsPanel")
        if sp then self.spawnPt:setText(s(sp.entry:getText())) end
        self:selectPage(self.pageIdx)
    end
end

function ZeD_MMServer:onShow()
    self._mode = nil
    self.field:setVisible(false)
end

-- THE EDIT PAGE: vanilla's list of pages (category headers, then pages) ------------------
function ZeD_MMServer:pages()
    local S = sss()
    local t = {}
    local pe = S and S.pageEdit
    if not pe or not pe.listbox then return t end
    local cat = nil
    for _, it in ipairs(pe.listbox.items) do
        local d = it.item
        if d.category then
            cat = d.category.name
            t[#t + 1] = { head = true, title = ZeD.textCase(ZeD.tr((cat == "INI") and "UI_ZeD_Server_HeadServer" or "UI_mainscreen_sandbox")), item = d }
        else
            t[#t + 1] = { title = s(it.text), raw = s(cat) .. ":" .. s(it.text), page = d.page, panel = d.panel, category = cat, item = d }
        end
    end
    return t
end

-- a page chosen here is vanilla's current page too (a special page acts on its parent)
function ZeD_MMServer:selectPage(i)
    local S = sss()
    local pe = S and S.pageEdit
    local p = self:pages()[i]
    if not pe or not p or p.head then return end
    self.pageIdx = i
    if pe.listbox.selected ~= i or pe.currentPanel ~= p.panel then
        pe.listbox.selected = i
        pcall(function() pe:onMouseDownListBox(p.item) end)
        holdJoypad()
    end
end

function ZeD_MMServer:customPanel(typeName)
    local S = sss()
    for _, p in ipairs(S and S.pageEdit and S.pageEdit.customui or {}) do
        if p.Type == typeName then return p end
    end
    return nil
end

function ZeD_MMServer:rowsFor(page)
    if not page or page.head then return {} end
    self._rows = self._rows or {}
    local cached = self._rows[page.raw]
    if cached then return cached end
    local S = sss()
    local pe = S.pageEdit
    local rows = {}
    if page.page.customui then
        rows[1] = { kind = "custom", panel = page.panel, label = page.title }
    else
        local controls = pe.controls[page.category] or {}
        local group = page.page.groupBox and page.panel or nil
        if group and group.tickBox then
            rows[#rows + 1] = { kind = "tick", control = group.tickBox, label = "", groupTick = true }
        end
        for _, st in ipairs(page.page.settings or {}) do
            local c = controls[st.name]
            if c then
                if st.title then rows[#rows + 1] = { kind = "header", text = getText("Sandbox_Title_" .. st.title) } end
                local kind = nil
                if c.Type == "ISTickBox" then kind = "tick"
                elseif c.Type == "ISComboBox" then kind = "combo"
                elseif c.Type == "ISTextEntryBox" then kind = "entry" end
                if kind then
                    rows[#rows + 1] = { kind = kind, control = c, label = s(st.translatedName or st.name), name = st.name, category = page.category,
                                        group = group, secret = (page.category == "INI" and st.name == "Password") }
                end
            end
        end
    end
    self._rows[page.raw] = rows
    return rows
end

-- a control's value, to tell what changed since the page opened
local function sig(c)
    if c.Type == "ISTickBox" then return tostring(c.selected[1] == true) end
    if c.Type == "ISComboBox" then return tostring(c.selected) end
    if c.Type == "ISTextEntryBox" then return s(c:getText()) end
    return nil
end

function ZeD_MMServer:snapshotEdit()
    local S = sss()
    self.snap = {}
    for cat, list in pairs(S and S.pageEdit and S.pageEdit.controls or {}) do
        for name, c in pairs(list) do self.snap[cat .. ":" .. name] = sig(c) end
    end
    self:refreshDiff(true)
end

function ZeD_MMServer:refreshDiff(force)
    local t = MM.now()
    if not force and self._diffAt and t - self._diffAt < 400 then return end
    self._diffAt = t
    self.diff, self.nDiff = {}, 0
    local S = sss()
    for cat, list in pairs(S and S.pageEdit and S.pageEdit.controls or {}) do
        for name, c in pairs(list) do
            local k = cat .. ":" .. name
            if self.snap[k] ~= nil and self.snap[k] ~= sig(c) then self.diff[k] = true; self.nDiff = self.nDiff + 1 end
        end
    end
end
function ZeD_MMServer:isChanged(r) return r.name ~= nil and self.diff[s(r.category) .. ":" .. r.name] == true end
function ZeD_MMServer:anyChanged() return self.nDiff > 0 or self.dirty end

-- a group box's rows while its "defaults" tick is on (vanilla covers them)
function ZeD_MMServer:rowDisabled(r)
    if r.group and not r.groupTick and r.group.tickBox and r.group.tickBox.selected[1] then return true end
    return false
end

-- numbers: the option's own range, from the file being edited (INI or sandbox)
function ZeD_MMServer:cellValid()
    local r = self._cellRow
    local S = sss()
    if not r or not S or not S.pageEdit.settings then return true end
    local text = self.cell:getText() or ""
    local ok, valid = pcall(function()
        local set = S.pageEdit.settings
        local o = ((r.category == "INI") and set:getServerOptions() or set:getSandboxOptions()):getOptionByName(r.name)
        if not o then return true end
        if r.category == "INI" then o = o:asConfigOption() end
        return o:isValidString(text)
    end)
    return (not ok) or valid
end

-- the server password shows as stars until it is edited
function ZeD_MMServer:drawControl(r, cx, ry, cw, rh, rowId, clip)
    if r.secret and self._cellRow ~= r then
        local T = ZeD.T
        local f2 = T.fontF2
        local bw, bh = math.min(T.px(ENTRY_W), cw), T.px(24)
        local by = ry + math.floor(rh / 2) - math.floor(bh / 2)
        UI.insetBox(self, cx, by, bw, bh, true)
        local n = string.len(s(r.control:getText()))
        local tc = T.text
        self:drawText(string.rep("*", math.min(n, 24)), cx + T.px(6), by + math.floor((bh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
        local top, bot = math.max(by, clip.y), math.min(by + bh, clip.y + clip.h)
        if bot > top then
            local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
            self._hits[#self._hits + 1] = { id = self.kind .. ":" .. rowId .. ":num", x = ax + cx, y = ay + top, w = bw, h = bot - top, fn = function() self:startCell(r) end, sound = true }
        end
        return
    end
    ZeD_MMSandbox.drawControl(self, r, cx, ry, cw, rh, rowId, clip)
end

-- the pages list, with the two categories as headers (it scrolls: the sandbox has many)
function ZeD_MMServer:drawPages(x, y, w, h, pages, finding)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    local fH = T.px(34)
    ZeD.Surface.fill(self, x + T.px(1), y + T.px(1), w - 2 * T.px(1), fH - T.px(1), "surf2")
    ZeD.Atoms.drawDividerH(self, x, y + fH, w, true)
    local f2, c = T.fontF2, T.text
    local findLabel = ZeD.tr("UI_ZeD_Options_Find")
    self:drawText(findLabel, x + T.px(8), y + math.floor((fH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    local ex = x + T.px(8) + MM.textW(f2, findLabel) + T.px(8)
    UI.styleEntry(self.find, ex, y + math.floor((fH - T.px(24)) / 2), x + w - T.px(8) - ex, T.px(24))
    if not self.find:isVisible() then self.find:setVisible(true) end
    self._hits[#self._hits + 1] = { id = "srvset:find", x = ax + self.find.x, y = ay + self.find.y, w = self.find.width, h = self.find.height, fn = function() self.find:focus() end }
    local ry = y + fH + T.px(1)
    local vh = y + h - T.px(1) - ry
    local total = 0
    for _, p in ipairs(pages) do total = total + (p.head and T.px(HEAD_H) or T.px(PAGE_ROW_H)) end
    self.pagesScroll = math.max(0, math.min(self.pagesScroll or 0, math.max(0, total - vh)))
    self._pagesBox = { x = x, y = ry, w = w, h = vh }
    local sbW = T.sp.scrollbarW
    local rw = w - T.px(2) - ((total > vh) and sbW or 0)
    self:setStencilRect(x + T.px(1), ry, w - T.px(2), vh)
    local yy = ry - self.pagesScroll
    for i, p in ipairs(pages) do
        local rh = p.head and T.px(HEAD_H) or T.px(PAGE_ROW_H)
        if yy + rh > ry and yy < ry + vh then
            if p.head then
                if yy >= ry and yy + rh <= ry + vh then   -- (wholly inside the list: the head claims its place in the body)
                    ZeD.Molecules.drawSectionHeader(self, x + T.px(9), yy, rw - T.px(10), p.title, nil, true, false, T.fontF1, false, T.px(8), rh, true)
                end
            else
                local isSel = (i == self.pageIdx) and not finding
                local hid = "srvset:page:" .. i
                MM.rowWash(self, x + T.px(1), yy, rw, rh, isSel, (not MM.gamepad()) and MM.ctx.hot == hid)
                local tc = isSel and T.textHead or T.text
                self:drawText(ZeD.Atoms.truncateText(p.title, f2, rw - T.px(28)), x + T.px(18), yy + math.floor((rh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
                local top, bot = math.max(yy, ry), math.min(yy + rh, ry + vh)
                self._hits[#self._hits + 1] = { id = hid, x = ax + x, y = ay + top, w = rw, h = bot - top, fn = function()
                    self:commitCell()
                    if self.find:getInternalText() ~= "" then self.find:setText("") end
                    if self.pageIdx ~= i then
                        self:selectPage(i)
                        self.scroll = 0; self._lists, self._listSel = {}, {}; self.focusId = nil
                        self.other:setText("")
                        MM.clickSound()
                    end end }
            end
        end
        yy = yy + rh
    end
    self:clearStencilRect()
    if total > vh then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, ry, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / total))
        ZeD.Atoms.drawScrollThumb(self, sx, ry + math.floor((vh - th) * self.pagesScroll / (total - vh)), sbW, th, "default")
    end
end

-- ============================================================================
-- DRAWING
-- ============================================================================

-- one of the window's own fields, placed this frame (unplaced ones hide)
function ZeD_MMServer:place(e, x, y, w)
    local h = ZeD.T.px(FIELD_H)
    UI.styleEntry(e, x, y, w, h)
    if not e:isVisible() then e:setVisible(true) end
    self._shown[e] = true
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    self._hits[#self._hits + 1] = { id = "srvset:f:" .. tostring(e), x = ax + x, y = ay + y, w = w, h = h, fn = function() e:focus() end }
end

function ZeD_MMServer:prerender()
    local T = ZeD.T
    local S = sss()
    local m = self:mode()
    if m ~= self._mode then local prev = self._mode; self._mode = m; self:enterMode(m, prev) end
    self._specs, self._hits = {}, {}
    self._shown = {}
    self._listBoxes = {}
    local w, h = UI.placeOnTube(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    self.title = ZeD.tr("UI_ZeD_Server_Title")
    self.titleStats = {}
    if m == "edit" then
        pcall(function() S.pageEdit:syncStartDay() end)   -- vanilla's render keeps Start Day's days; it does not run while hidden
        self:refreshDiff(false)
        local stat = s(S.pageEdit.settings and S.pageEdit.settings:getName())
        if self.nDiff > 0 then stat = ZeD.tr("UI_ZeD_Sandbox_StatChanged", stat, self.nDiff) end
        self.titleStats = { { text = stat, noMark = true } }
    elseif m == "points" and S.pageSpawnPoints.region then
        self.titleStats = { { text = s(S.pageSpawnPoints.region.file), noMark = true } }
    end
    ZeD_Window.prerender(self)
    if not S then return end
    if m == "edit" then
        self:drawEdit(pad, bodyY, w, bodyH)
    else
        if self.find:isVisible() then if self.find:isFocused() then self.find:unfocus() end; self.find:setVisible(false) end
        self:endCell()
        local x, bw = pad, w - pad * 2
        if m == "list" then self:drawFileList(x, bodyY, bw, bodyH)
        elseif m == "new" or m == "duplicate" or m == "rename" then self:drawNameForm(m, x, bodyY, bw, bodyH)
        elseif m == "delete" then self:drawDelete(x, bodyY, bw, bodyH)
        elseif m == "mods" then self:drawMods(x, bodyY, bw, bodyH)
        elseif m == "points" then self:drawPoints(x, bodyY, bw, bodyH) end
    end
    self:buildStrip(stripY, stripH, w)
    for _, e in ipairs(self._extra) do
        if not self._shown[e] and e:isVisible() then
            if e:isFocused() then e:unfocus() end
            e:setVisible(false)
        end
    end
end

-- EDIT: pages, then the page's rows or its special panel
function ZeD_MMServer:drawEdit(pad, bodyY, w, bodyH)
    local T = ZeD.T
    local pages = self:pages()
    if not pages[self.pageIdx] or pages[self.pageIdx].head then self.pageIdx = 2 end
    local page = pages[self.pageIdx]
    local q = string.lower(tostring(self.find:getInternalText() or ""))
    local pw = T.px(PAGES_W)
    local rows
    if q ~= "" then
        rows = {}
        for _, p in ipairs(pages) do
            if not p.head then
                local hits = {}
                for _, r in ipairs(self:rowsFor(p)) do
                    if r.kind ~= "header" and r.kind ~= "custom" then
                        local hay = string.lower(s(r.label) .. " " .. s(r.name) .. " " .. plainTip(r.control and r.control.tooltip))
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
    self:drawPages(pad, bodyY, pw, bodyH, pages, q ~= "")
    local rx, rw = pad * 2 + pw, w - pad * 3 - pw
    if rows[1] and rows[1].kind == "custom" then
        self:drawCustom(rows[1].panel, rx, bodyY, rw, bodyH)
    else
        self:drawRows(rx, bodyY, rw, bodyH, rows, page, q ~= "")
    end
    if self._cellRow and not self._cellDrawn then self:commitCell() end
end

-- a list box of { text, sub } rows: click (or A) picks; row0 / col place its rows for the controller
function ZeD_MMServer:drawList(id, x, y, w, h, rows, sel, onPick, empty, row0, col)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    local vy, vh = y + T.px(1), h - T.px(2)
    local rh = T.px(LIST_ROW_H)
    local total = #rows * rh
    local gp = MM.gamepad()
    self._lists = self._lists or {}
    local sc = self._lists[id] or 0
    -- the controller's row stays in view, and so does a row chosen some other way (ADD, a move)
    for i = 1, #rows do
        if gp and self.focusId == "l:" .. id .. ":" .. i then
            if (i - 1) * rh < sc then sc = (i - 1) * rh elseif i * rh > sc + vh then sc = i * rh - vh end
        end
    end
    self._listSel = self._listSel or {}
    if sel and rows[sel] and sel ~= self._listSel[id] then
        if (sel - 1) * rh < sc then sc = (sel - 1) * rh elseif sel * rh > sc + vh then sc = sel * rh - vh end
    end
    self._listSel[id] = sel
    sc = math.max(0, math.min(sc, math.max(0, total - vh)))
    self._lists[id] = sc
    self._listBoxes[id] = { x = x, y = vy, w = w, h = vh }
    local f2, f3 = T.fontF2, T.fontF3
    local sbW = T.sp.scrollbarW
    local rw = w - T.px(2) - ((total > vh) and sbW or 0)
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    for i, r in ipairs(rows) do
        local ry = vy - sc + (i - 1) * rh
        local fid = "l:" .. id .. ":" .. i
        self._specs[#self._specs + 1] = { id = fid, listRow = true, row = (row0 or 100) + i, col = col or 1, fn = function() onPick(i) end,
                                          x = x + T.px(1), y = ry, w = rw, h = rh, listId = "pick:" .. id, clip = { x = x, y = vy, w = w, h = vh }, chosen = (i == sel) }
        if ry + rh > vy and ry < vy + vh then
            local hid = "srvset:" .. id .. ":" .. i
            local onFocus = MM.rowLook(self, x + T.px(1), ry, rw, rh, i == sel, (not gp) and MM.ctx.hot == hid, gp and self.focusId == fid)
            self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local tc = onFocus and T.textOnFocus or ((i == sel) and T.textHead or T.text)
            local textW = rw - T.px(20)
            if r.sub and r.sub ~= "" then
                local sw = math.min(MM.textW(f3, r.sub), math.floor(textW * 0.45))
                local d = onFocus and T.textOnFocus or T.textDim
                self:drawText(ZeD.Atoms.truncateText(r.sub, f3, sw), x + rw - T.px(10) - sw, ry + math.floor((rh - MM.fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
                textW = textW - sw - T.px(12)
            end
            self:drawText(ZeD.Atoms.truncateText(s(r.text), f2, textW), x + T.px(10), ry + math.floor((rh - MM.fontH(f2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f2)
            local top, bot = math.max(ry, vy), math.min(ry + rh, vy + vh)
            self._hits[#self._hits + 1] = { id = hid, x = ax + x, y = ay + top, w = rw, h = bot - top, fn = function() onPick(i) end }
        end
    end
    self:clearStencilRect()
    if #rows == 0 and empty then
        ZeD.Molecules.drawEmptyLine(self, x + T.px(10), vy + T.px(8), w - T.px(20), empty)
    end
    if total > vh then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / total))
        ZeD.Atoms.drawScrollThumb(self, sx, vy + math.floor((vh - th) * sc / (total - vh)), sbW, th, "default")
    end
end

-- a button under a list (drawn with the window's other buttons); returns its width
function ZeD_MMServer:button(id, text, x, y, fn, disabled, row, col)
    local T = ZeD.T
    local bw = ZeD.Molecules.buttonW(text)
    self._specs[#self._specs + 1] = { id = id, text = text, x = x, y = y, w = bw, h = T.buttonH, fn = fn, disabled = disabled,
                                      variant = "default", row = row or 600, col = col or 1 }
    return bw
end

function ZeD_MMServer:label(text, x, y)
    local T = ZeD.T
    local la = T.accent
    self:drawText(text, x, y, la.r, la.g, la.b, la.a or 1, T.fontF1)
    return MM.fontH(T.fontF1) + T.px(6)
end

function ZeD_MMServer:heading(text, x, y)
    local T = ZeD.T
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local tc = T.textHead
    ZeD.Text.draw(self, hf, text, x, y, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    return math.floor(ZeD.Text.height(hf, z))
end

-- a reason (a red square) under a field
function ZeD_MMServer:why(text, x, y, w)
    local T = ZeD.T
    local f2, c = T.fontF2, T.text
    local dsz = T.px(7)
    for i, l in ipairs(ZeD.Atoms.wrapText(text, f2, w - dsz - T.px(8))) do
        if i == 1 then ZeD.Atoms.drawStatusDot(self, x, y + math.floor((MM.fontH(f2) - dsz) / 2), T.danger, dsz) end
        self:drawText(l, x + dsz + T.px(8), y, c.r, c.g, c.b, c.a or 1, f2)
        y = y + MM.fontH(f2) + T.px(3)
    end
    return y
end

-- a vanilla list box's choices as a pop-up; picking one runs vanilla's add
function ZeD_MMServer:openPick(key, combo, anchor, after)
    local items = {}
    for i = 1, #(combo.options or {}) do
        items[#items + 1] = { text = comboText(combo, i), fn = function() combo.selected = i; if after then after(i) end end }
    end
    if #items == 0 then return end
    MM.openPopup(key, items, anchor, false)
    MM.ctx.dropFocus = 1
end

-- THE SPECIAL PAGES ---------------------------------------------------------------------
function ZeD_MMServer:drawCustom(panel, x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local bs = T.borderS
    ZeD.Atoms.frame(self, x, y, w, h, bs)
    local ix, iw = x + T.px(14), w - T.px(28)
    local cy = y + T.px(12)
    local bh = T.buttonH
    local fh = T.px(FIELD_H)
    local d = T.textDim
    local function note(text)
        for _, l in ipairs(ZeD.Atoms.wrapText(text, T.fontF2, iw)) do
            self:drawText(l, ix, cy, d.r, d.g, d.b, d.a or 1, T.fontF2)
            cy = cy + MM.fontH(T.fontF2) + T.px(3)
        end
        cy = cy + T.px(6)
    end
    local function touched() self.dirty = true end
    local lb = panel.listbox
    if panel.Type == "ServerSettingsScreenModsPanel" then
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelMods"), ix, cy)
        local rows = {}
        for _, it in ipairs(lb.items) do rows[#rows + 1] = { text = it.item.modInfo and it.item.modInfo:getName() or it.item.modID, sub = it.item.modID } end
        local listH = y + h - T.px(48) - cy
        self:drawList("mods", ix, cy, iw, listH, rows, nil, function() end, ZeD.tr("UI_ZeD_Server_NoMods"))
        cy = cy + listH + T.px(10)
        note(ZeD.tr("UI_ZeD_Server_ModsNote"))
    elseif panel.Type == "ServerSettingsScreenMapsPanel" then
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelMaps"), ix, cy)
        local rows = {}
        for _, it in ipairs(lb.items) do rows[#rows + 1] = { text = it.item.mapFolder } end
        local listH = math.max(T.px(90), y + h - cy - bh - fh - T.px(56))
        self:drawList("maps", ix, cy, iw, listH, rows, lb.selected, function(i) lb.selected = i end, ZeD.tr("UI_ZeD_Server_NoMaps"), 100, 1)
        cy = cy + listH + T.px(8)
        local has = lb.items[lb.selected] ~= nil
        local bx = ix
        bx = bx + self:button("mapUp", ZeD.tr("UI_ServerSettings_ButtonMoveUp"), bx, cy, function() panel:onButtonMoveUp(); touched() end, not has or lb.selected <= 1, 600, 1) + T.px(8)
        bx = bx + self:button("mapDown", ZeD.tr("UI_ServerSettings_ButtonMoveDown"), bx, cy, function() panel:onButtonMoveDown(); touched() end, not has or lb.selected >= #lb.items, 600, 2) + T.px(8)
        bx = bx + self:button("mapRemove", getText("UI_btn_remove"), bx, cy, function() panel:onButtonRemove(); touched() end, not has, 600, 3) + T.px(8)
        local addText = ZeD.tr("UI_ZeD_Server_AddInstalled")
        local anchor = { x = ax + bx, y = ay + cy, w = ZeD.Molecules.buttonW(addText), h = bh }
        self:button("mapAdd", addText, bx, cy, function()
            self:openPick("maps", panel.comboBox, anchor, function() panel:onAddInstalledMap(); touched() end) end, #(panel.comboBox.options or {}) == 0, 600, 4)
        cy = cy + bh + T.px(14)
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelAddMap"), ix, cy)
        self._otherFor = { kind = "map", panel = panel }
        self:place(self.other, ix, cy, math.min(iw, T.px(360)))
    elseif panel.Type == "SpawnRegionsPanel" then
        cy = cy + self:label(ZeD.textCase(ZeD.tr("UI_ServerSettingGroup_SpawnRegions")), ix, cy)
        local rows = {}
        for _, it in ipairs(lb.items) do rows[#rows + 1] = { text = (s(it.item.name) ~= "") and it.item.name or ZeD.tr("UI_ZeD_Server_NoName"), sub = it.item.file } end
        local listH = math.max(T.px(90), y + h - cy - T.px(250))
        self:drawList("regions", ix, cy, iw, listH, rows, lb.selected, function(i) lb.selected = i; lb.currentItem = nil end, ZeD.tr("UI_ZeD_Server_NoRegions"), 100, 1)
        cy = cy + listH + T.px(8)
        local it = lb.items[lb.selected]
        local lw = T.px(60)
        local fw = math.min(iw - lw, T.px(420))
        -- the chosen region's name and file, written into vanilla's list as they are typed
        if it then
            if self._regFor ~= it then self._regFor = it; self.regName:setText(s(it.item.name)); self.regFile:setText(s(it.item.file)) end
            if self.regName:isFocused() and (self.regName:getText() or "") ~= it.item.name then it.item.name = self.regName:getText() or ""; touched() end
            if self.regFile:isFocused() and (self.regFile:getText() or "") ~= it.item.file then it.item.file = self.regFile:getText() or ""; touched() end
            local la = T.accent
            self:drawText(ZeD.textCase(ZeD.tr("IGUI_Name")), ix, cy + math.floor((fh - MM.fontH(T.fontF1)) / 2), la.r, la.g, la.b, la.a or 1, T.fontF1)
            self:place(self.regName, ix + lw, cy, fw)
            cy = cy + fh + T.px(8)
            self:drawText(ZeD.tr("UI_ZeD_Server_LabelRegFile"), ix, cy + math.floor((fh - MM.fontH(T.fontF1)) / 2), la.r, la.g, la.b, la.a or 1, T.fontF1)
            self:place(self.regFile, ix + lw, cy, fw)
            cy = cy + fh + T.px(10)
        end
        local file = it and s(it.item.file) or ""
        local validFile = it ~= nil and not luautils.stringStarts(file, "media") and not file:contains("/") and not file:contains("\\") and file:sub(-15) == "spawnpoints.lua"
        local bx = ix
        bx = bx + self:button("regAdd", getText("UI_btn_add"), bx, cy, function()
            panel:onButtonAddRegion(); lb.currentItem = nil; touched()
            self._regFor = lb.items[lb.selected]
            self.regName:setText(""); self.regFile:setText("")
            self.regName:setVisible(true); self.regName:focus()
        end, false, 600, 1) + T.px(8)
        bx = bx + self:button("regRemove", getText("UI_btn_remove"), bx, cy, function() panel:onButtonRemoveRegion(); self._regFor = nil; touched() end, it == nil, 600, 2) + T.px(8)
        self:button("regEdit", ZeD.tr("UI_ZeD_Server_EditPoints"), bx, cy, function() lb.currentItem = nil; openPoints(panel) end, not validFile, 600, 3)
        cy = cy + bh + T.px(8)
        if it and not validFile then
            -- vanilla's reason, plain: a map's own file is read only; ours must be a plain name ending spawnpoints.lua
            cy = self:why(UI.plain(luautils.stringStarts(file, "media") and getText("UI_ServerSettings_ButtonEditRegion_tooltip1") or getText("UI_ServerSettings_ButtonEditRegion_tooltip2")), ix, cy, iw) + T.px(6)
        end
        cy = cy + T.px(6)
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelFixedPoint"), ix, cy)
        if self.spawnPt:isFocused() and s(panel.entry:getText()) ~= (self.spawnPt:getText() or "") then panel.entry:setText(self.spawnPt:getText() or ""); touched() end
        self:place(self.spawnPt, ix, cy, math.min(iw, T.px(240)))
        cy = cy + fh + T.px(6)
        note(UI.plain(getText("UI_ServerOption_SpawnPoint_tooltip")))
    elseif panel.Type == "ServerSettingsScreenWorkshopPanel" then
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelWorkshop"), ix, cy)
        local rows = {}
        for _, it2 in ipairs(lb.items) do
            local det = panel.itemDetails and panel.itemDetails[it2.item.workshopID]
            rows[#rows + 1] = { text = det and det:getTitle() or it2.item.workshopID, sub = it2.item.workshopID }
        end
        local listH = math.max(T.px(90), y + h - cy - bh - fh - T.px(56))
        self:drawList("workshop", ix, cy, iw, listH, rows, lb.selected, function(i) lb.selected = i end, ZeD.tr("UI_ZeD_Server_NoWorkshop"), 100, 1)
        cy = cy + listH + T.px(8)
        local bx = ix
        bx = bx + self:button("wsRemove", getText("UI_btn_remove"), bx, cy, function() panel:onButtonRemove(); touched() end, lb.items[lb.selected] == nil, 600, 1) + T.px(8)
        local addText = ZeD.tr("UI_ZeD_Server_AddInstalled")
        local anchor = { x = ax + bx, y = ay + cy, w = ZeD.Molecules.buttonW(addText), h = bh }
        self:button("wsAdd", addText, bx, cy, function()
            self:openPick("workshop", panel.comboBox, anchor, function() panel:onAddInstalledItem(); touched() end) end, #(panel.comboBox.options or {}) == 0, 600, 2)
        cy = cy + bh + T.px(14)
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelAddWorkshop"), ix, cy)
        self._otherFor = { kind = "workshop", panel = panel }
        self:place(self.other, ix, cy, math.min(iw, T.px(360)))
        local t = self.other:getText() or ""
        if t ~= "" and not panel:isValidWorkshopID(t) then self:why(ZeD.tr("UI_ZeD_Server_BadWorkshopId"), ix, cy + fh + T.px(6), iw) end
    elseif panel.Type == "SandboxPresetPanel" then
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelPreset"), ix, cy)
        local rows = {}
        for _, it2 in ipairs(lb.items) do rows[#rows + 1] = { text = s(it2.text), sub = it2.item.userDefined and ZeD.tr("UI_ZeD_Server_PresetYours") or nil } end
        local listH = math.max(T.px(90), y + h - cy - bh - T.px(70))
        self:drawList("presets", ix, cy, iw, listH, rows, lb.selected, function(i) lb.selected = i end, nil, 100, 1)
        cy = cy + listH + T.px(8)
        self:button("presetApply", getText("UI_btn_apply"), ix, cy, function()
            panel:onButtonApplyPreset(); self:refreshDiff(true); MM.clickSound() end, lb.items[lb.selected] == nil, 600, 1)
        cy = cy + bh + T.px(10)
        note(ZeD.tr("UI_ZeD_Server_PresetNote"))
    end
end

-- the field under a special page: a map folder, a Workshop ID, an occupation (vanilla's rules)
function ZeD_MMServer:addOther()
    local f = self._otherFor
    local text = (self.other:getText() or ""):trim()
    if not f or text == "" then return end
    local p = f.panel
    if f.kind == "map" then
        if text:contains(";") or p:findMapInList(text) then return end
        p:addMapToList(text)
        p.listbox.selected = #p.listbox.items
        p.pageEdit:notify("addedMap", text)
        self.dirty = true
    elseif f.kind == "workshop" then
        if not p:isValidWorkshopID(text) then return end
        p:addItemToList(text)
        p.listbox.selected = #p.listbox.items
        self.dirty = true
    elseif f.kind == "profession" then
        text = plainProf(text)
        if p:isProfessionInList(text) then return end
        addProf(p, text, {}, true)
        p:fillProfessionCombo()
    end
    self.other:setText("")
    MM.clickSound()
end

-- THE OTHER PAGES ---------------------------------------------------------------------------
function ZeD_MMServer:drawFileList(x, y, w, h)
    local T = ZeD.T
    local S = sss()
    local lb = S.pageStart.listbox
    local lw = math.floor(w * 0.45)
    local rows = {}
    for _, it in ipairs(lb.items) do rows[#rows + 1] = { text = s(it.text) } end
    self:drawList("files", x, y, lw, h, rows, lb.selected, function(i)
        local t = MM.now()
        if lb.selected == i and self._lastClick and t - self._lastClick < 450 then self._lastClick = nil; self:act("edit"); return end
        self._lastClick = t
        lb.selected = i
    end, ZeD.tr("UI_ZeD_Server_NoSettings"))
    -- the chosen settings' files
    local dx, dw = x + lw + T.px(10), w - lw - T.px(10)
    local bs = T.borderS
    ZeD.Atoms.frame(self, dx, y, dw, h, bs)
    local it = lb.items[lb.selected]
    if not it then return end
    local name = s(it.text)
    local ix, cy = dx + T.px(14), y + T.px(12)
    cy = cy + self:heading(name, ix, cy) + T.px(10)
    cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelFiles"), ix, cy)
    self:drawFiles(name, ix, cy, dw - T.px(28), name)
end

-- the files a settings name has (src: those that exist under that name; nil: all it would make)
function ZeD_MMServer:drawFiles(name, x, y, w, src)
    local T = ZeD.T
    local mgr = getServerSettingsManager()
    local prefix = mgr:getNameInSettingsFolder(name)
    local suffixes = mgr:getSuffixes()
    local f2, c = T.fontF2, T.text
    for i = 1, suffixes:size() do
        local suf = suffixes:get(i - 1)
        local show
        if src then show = serverFileExists(src .. suf) else show = (suf ~= "_zombies.ini") end
        if show then
            self:drawText(ZeD.Atoms.truncateText(prefix .. suf, f2, w), x, y, c.r, c.g, c.b, c.a or 1, f2)
            y = y + MM.fontH(f2) + T.px(4)
        end
    end
    return y
end

-- why a name will not do (vanilla's own checks), or nil
function ZeD_MMServer:nameProblem(m)
    local S = sss()
    if not S then return "" end
    local name = self.nameEntry:getText() or ""
    local mgr = getServerSettingsManager()
    if name == "" then return ZeD.tr("UI_ZeD_Server_ErrNoName") end
    -- (vanilla lets these through, and the files then land in the wrong place or fail)
    if name:find('[\\/:%*%?"<>|]') then return ZeD.tr("UI_ZeD_Server_ErrCharacters") end
    if m == "duplicate" or m == "rename" then
        local p = (m == "duplicate") and S.pageDuplicate or S.pageRename
        if p.settings and name == p.settings:getName() then return ZeD.tr("UI_ZeD_Server_ErrSameName") end
    end
    if not mgr:isValidNewName(name) then return ZeD.tr("UI_ZeD_Server_ErrTaken") end
    if not mgr:settingsFolderValidLengthChecks(name) then return ZeD.tr("UI_ZeD_Server_ErrTooLong") end
    return nil
end

function ZeD_MMServer:drawNameForm(m, x, y, w, h)
    local T = ZeD.T
    local S = sss()
    UI.insetBox(self, x, y, w, h)
    local ix, iw = x + T.px(24), w - T.px(48)
    local cy = y + T.px(20)
    local p = (m == "new") and S.pageNew or ((m == "duplicate") and S.pageDuplicate or S.pageRename)
    local from = p.settings and p.settings:getName() or ""
    local title = (m == "new") and ZeD.tr("UI_ZeD_Server_TitleNew") or ((m == "duplicate") and ZeD.tr("UI_ZeD_Server_TitleCopy", from) or ZeD.tr("UI_ZeD_Server_TitleRename", from))
    cy = cy + self:heading(title, ix, cy) + T.px(16)
    cy = cy + self:label(ZeD.textCase(ZeD.tr("IGUI_Name")), ix, cy)
    self:place(self.nameEntry, ix, cy, math.min(iw, T.px(400)))
    -- vanilla's page reads its own field on NEXT / ACCEPT
    if s(p.entry:getText()) ~= (self.nameEntry:getText() or "") then p.entry:setText(self.nameEntry:getText() or "") end
    cy = cy + T.px(FIELD_H) + T.px(8)
    local why = self:nameProblem(m)
    if why then self:why(why, ix, cy, iw) end
    cy = cy + T.px(34)
    local newName = self.nameEntry:getText() or ""
    if m == "new" then
        cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelMakes"), ix, cy)
        self:drawFiles(newName, ix, cy, iw, nil)
    elseif not why then
        cy = cy + self:label(ZeD.tr((m == "duplicate") and "UI_ZeD_Server_LabelCopies" or "UI_ZeD_Server_LabelBecome"), ix, cy)
        self:drawFiles(newName, ix, cy, iw, from)
    end
end

function ZeD_MMServer:drawDelete(x, y, w, h)
    local T = ZeD.T
    local S = sss()
    UI.insetBox(self, x, y, w, h)
    local ix = x + T.px(24)
    local cy = y + T.px(20)
    local name = s(S.pageDelete.settings and S.pageDelete.settings:getName())
    cy = cy + self:heading(ZeD.tr("UI_ZeD_Server_TitleDelete", name), ix, cy) + T.px(16)
    cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelGo"), ix, cy)
    self:drawFiles(name, ix, cy, w - T.px(48), name)
end

function ZeD_MMServer:drawMods(x, y, w, h)
    local T = ZeD.T
    local S = sss()
    local cw = S.pageEdit.chooseModsWindow
    local rows = {}
    for _, it in ipairs(cw.listbox.items) do rows[#rows + 1] = { text = it.item.modInfo and it.item.modInfo:getName() or it.item.modID, sub = it.item.modID } end
    local cy = y + self:heading(s(cw.settings and cw.settings:getName()), x, y) + T.px(10)
    cy = cy + self:label(ZeD.tr("UI_ZeD_Server_LabelMods"), x, cy)
    self:drawList("chooseMods", x, cy, w, y + h - cy, rows, nil, function() end, ZeD.tr("UI_ZeD_Server_NoMods"))
end


-- SPAWN POINTS (Page7): occupations on the left, the chosen one's points on the right
function ZeD_MMServer:pointsProblem()
    local S = sss()
    local pg = S and S.pageSpawnPoints
    if not pg then return nil end
    local hasUnemployed, empty = false, nil
    for _, it in ipairs(pg.profListBox.items) do
        if it.item.professionType == "unemployed" then hasUnemployed = true end
        if #(it.item.points or {}) == 0 and not empty then empty = profLabel(it.item.professionType) end
    end
    if not hasUnemployed then return ZeD.tr("UI_ZeD_Server_PointsNeedsOne", profLabel("unemployed")) end
    if empty then return ZeD.tr("UI_ZeD_Server_PointsEmpty", empty) end
    return nil
end

function ZeD_MMServer:drawPoints(x, y, w, h)
    local T = ZeD.T
    local S = sss()
    local pg = S.pageSpawnPoints
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local half = math.floor((w - T.px(10)) / 2)
    local px = x + half + T.px(10)
    local bh = T.buttonH
    local fh = T.px(FIELD_H)
    local cy = y
    self:label(ZeD.tr("UI_ZeD_Server_LabelOccupations"), x, cy)
    self:label(ZeD.tr("UI_ZeD_Server_LabelPoints"), px, cy)
    cy = cy + MM.fontH(T.fontF1) + T.px(6)
    local listH = h - (cy - y) - bh - fh - MM.fontH(T.fontF1) - T.px(70)
    local pl = pg.profListBox
    trimProfChoices(pg)
    local profs = {}
    for _, it in ipairs(pl.items) do
        local n = #(it.item.points or {})
        profs[#profs + 1] = { text = profLabel(it.item.professionType), sub = ZeD.tr((n == 1) and "UI_ZeD_Server_PointCountOne" or "UI_ZeD_Server_PointCountMany", n) }
    end
    self:drawList("profs", x, cy, half, listH, profs, pl.selected, function(i) pl.selected = i; pg:fillPointList() end, ZeD.tr("UI_ZeD_Server_NoOccupations"), 100, 1)
    local pts = {}
    for _, it in ipairs(pg.pointListBox.items) do pts[#pts + 1] = { text = s(it.text) } end
    self:drawList("points", px, cy, half, listH, pts, pg.pointListBox.selected, function(i) pg.pointListBox.selected = i end,
        ZeD.tr(pl.items[pl.selected] and "UI_ZeD_Server_NoPoints" or "UI_ZeD_Server_ChooseOccupation"), 100, 2)
    cy = cy + listH + T.px(8)
    local addText = ZeD.tr("UI_ZeD_Server_AddOccupation")
    local anchor = { x = ax + x, y = ay + cy, w = ZeD.Molecules.buttonW(addText), h = bh }
    local bx = x + self:button("profAdd", addText, x, cy, function()
        self:openPick("profs", pg.profComboBox, anchor, function(i)
            local o = pg.profComboBox.options[i]
            local id = o and o.data and plainProf(o.data:getType())
            if id and not pg:isProfessionInList(id) then addProf(pg, id, {}, true); pg:fillProfessionCombo() end
        end) end, #(pg.profComboBox.options or {}) == 0, 600, 1) + T.px(8)
    -- (vanilla's remove handlers run as the list box's, through the page)
    self:button("profRemove", getText("UI_btn_remove"), bx, cy, function() pg.onRemoveProfession(pl, pl.selected) end, pl.items[pl.selected] == nil, 600, 2)
    self:button("ptRemove", getText("UI_btn_remove"), px, cy, function() pg.onRemovePoint(pg.pointListBox, pg.pointListBox.selected) end, pg.pointListBox.items[pg.pointListBox.selected] == nil, 600, 3)
    cy = cy + bh + T.px(12)
    self:label(ZeD.tr("UI_ZeD_Server_LabelAnotherOccupation"), x, cy)
    self:label(ZeD.tr("UI_ZeD_Server_LabelAddPoint"), px, cy)
    cy = cy + MM.fontH(T.fontF1) + T.px(6)
    self._otherFor = { kind = "profession", panel = pg }
    self:place(self.other, x, cy, half)
    if pl.items[pl.selected] then self:place(self.pointEntry, px, cy, half) end
    local why = self:pointsProblem()
    if why then self:why(why, x, cy + fh + T.px(10), w) end
end

-- vanilla's Page7:onAddPoint with the typed x,y,z (x, y from 0; z 0 to 7)
function ZeD_MMServer:addPoint()
    local S = sss()
    local pg = S and S.pageSpawnPoints
    if not pg or not pg.profListBox.items[pg.profListBox.selected] then return end
    local ss = (self.pointEntry:getText() or ""):split(",")
    if #ss ~= 3 then return end
    local x, y, z = tonumber(ss[1]), tonumber(ss[2]), tonumber(ss[3])
    if not x or x < 0 or not y or y < 0 or not z or z < 0 or z > 7 then return end
    self.pointEntry:setText("")
    local point = { posX = x, posY = y, posZ = z }
    table.insert(pg.profListBox.items[pg.profListBox.selected].item.points, point)
    pg:addPointToList(point, true)
    MM.clickSound()
end

-- THE STRIP + LEAVING ----------------------------------------------------------------------
function ZeD_MMServer:act(what)
    local S = sss()
    if not S then return end
    local m = self:mode()
    MM.clickSound()
    self:commitCell()
    if m == "list" then
        local p1 = S.pageStart
        if what == "back" then
            local prev = S.prevScreen
            p1:onButtonBack()             -- Host comes back through its own view
            if not prev then MM.showView("main") end
        elseif what == "new" then p1:onButtonNew()
        elseif p1.listbox.items[p1.listbox.selected] then
            if what == "edit" then p1:onButtonEdit()
            elseif what == "duplicate" then p1:onButtonDuplicate()
            elseif what == "rename" then p1:onButtonRename()
            elseif what == "delete" then p1:onButtonDelete() end
        end
    elseif m == "new" then
        if what == "back" then S.pageNew:onButtonBack() elseif not self:nameProblem(m) then S.pageNew:onButtonNext() end
    elseif m == "duplicate" or m == "rename" then
        local p = (m == "duplicate") and S.pageDuplicate or S.pageRename
        if what == "back" then p:onButtonCancel() elseif not self:nameProblem(m) then p:onButtonAccept() end
    elseif m == "delete" then
        if what == "back" then S.pageDelete:onButtonCancel() elseif what == "accept" then S.pageDelete:onButtonAccept() end
    elseif m == "mods" then
        local cw = S.pageEdit.chooseModsWindow
        if what == "back" then cw:onButtonCancel() elseif what == "choose" then cw:onButtonMods() else modsNext(cw) end
    elseif m == "edit" then
        local pe = S.pageEdit
        if what == "save" then
            local sp = self:customPanel("SpawnRegionsPanel")
            if sp then sp.listbox.currentItem = nil end   -- the list holds the regions' values (vanilla's row fields are not in use)
            self.confirm = false
            pe:onButtonSave()
        elseif what == "back" then
            if self:anyChanged() and self.confirm ~= "discard" then self:setConfirm("discard"); return end
            self.confirm = false
            pe:onButtonCancel()
        end
    elseif m == "points" then
        if what == "back" then S.pageSpawnPoints:onButtonCancel() elseif not self:pointsProblem() then S.pageSpawnPoints:onButtonAccept() end
    end
    holdJoypad()
end

function ZeD_MMServer:back() self:act("back") end
function ZeD_MMServer:next() end

function ZeD_MMServer:setConfirm(mode)
    if self.confirm == mode then return end
    self:commitCell()
    self.confirm = mode
    MM.ctx.open = nil
    self.focusId = mode and "confirm:yes" or nil
end

function ZeD_MMServer:buildStrip(stripY, stripH, w)
    local S = sss()
    local m = self:mode()
    local row = 1000
    local ask = nil
    local cancel = getText("UI_btn_cancel")
    local lefts, rights = { { "back", getText("UI_btn_back"), function() self:act("back") end } }, {}
    if self.confirm == "discard" then
        -- (spec 11: Cancel stays and edits on; Discard changes is the danger answer)
        ask = ZeD.tr("UI_ZeD_Server_AskLeave")
        lefts = {}
        rights = { { "confirm:no", cancel, function() self:setConfirm(false) end },
                   { "confirm:yes", ZeD.tr("UI_ZeD_MMWord_DiscardChanges"), function() self:act("back") end, "danger", false, ZeD.tr("UI_ZeD_MMHelp_DiscardChanges") } }
    elseif m == "list" then
        local none = not (S and S.pageStart.listbox.items[S.pageStart.listbox.selected])
        rights = {
            { "new", ZeD.tr("UI_ZeD_Mods_BtnNew"), function() self:act("new") end },
            { "duplicate", ZeD.tr("UI_ZeD_Server_BtnDuplicate"), function() self:act("duplicate") end, "default", none },
            { "rename", ZeD.tr("UI_ZeD_Server_BtnRename"), function() self:act("rename") end, "default", none },
            { "delete", ZeD.tr("UI_ZeD_Server_BtnDelete"), function() self:act("delete") end, "default", none },
            { "edit", getText("UI_servers_button_edit"), function() self:act("edit") end, "primary", none } }
    elseif m == "new" then
        rights = { { "next", getText("UI_btn_next"), function() self:act("accept") end, "primary", self:nameProblem(m) ~= nil } }
    elseif m == "duplicate" or m == "rename" then
        lefts = { { "back", cancel, function() self:act("back") end } }
        rights = { { "accept", (m == "duplicate") and ZeD.tr("UI_ZeD_Server_Duplicate") or getText("UI_btn_rename"), function() self:act("accept") end, "primary", self:nameProblem(m) ~= nil } }
    elseif m == "delete" then
        ask = ZeD.tr("UI_ZeD_Server_AskDelete")
        lefts = {}
        rights = { { "confirm:no", cancel, function() self:act("back") end },
                   { "confirm:yes", getText("UI_btn_delete"), function() self:act("accept") end, "danger" } }
    elseif m == "mods" then
        lefts = { { "back", cancel, function() self:act("back") end } }
        rights = { { "choose", getText("UI_NewGame_ChooseMods"), function() self:act("choose") end },
                   { "next", getText("UI_btn_next"), function() self:act("next") end, "primary" } }
    elseif m == "edit" then
        lefts = { { "back", cancel, function() self:act("back") end } }
        rights = { { "save", getText("UI_btn_save"), function() self:act("save") end, "primary" } }
    elseif m == "points" then
        lefts = { { "back", cancel, function() self:act("back") end } }
        rights = { { "save", getText("UI_btn_save"), function() self:act("save") end, "primary", self:pointsProblem() ~= nil } }
    end
    UI.stripSpecs(self, stripY, w, row, lefts, rights, ask)
end

-- CONTROLLER + KEYS + WHEEL ----------------------------------------------------------------
function ZeD_MMServer:joyB()
    if self._cellRow then self:endCell(); return end
    if self.confirm then self:setConfirm(false); return end
    self:act("back")
end
function ZeD_MMServer:joyY() end
function ZeD_MMServer:joyBumper(dir)
    if self:mode() ~= "edit" or self.confirm then return end
    local pages = self:pages()
    if #pages < 2 then return end
    local i = self.pageIdx
    repeat i = i + dir; if i < 1 then i = #pages elseif i > #pages then i = 1 end until not pages[i].head
    self:commitCell()
    if self.find:getInternalText() ~= "" then self.find:setText("") end
    self:selectPage(i)
    self.scroll = 0
    self._lists, self._listSel = {}, {}
    self.focusId = nil
    MM.clickSound()
end

function ZeD_MMServer:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local sel = ZeD.tr("UI_ZeD_MainMenu_PromptSelect")
    if self.confirm then return { { glyph = "A", label = sel }, { glyph = "B", label = getText("UI_Cancel") } } end
    if self:mode() ~= "edit" then return { { glyph = "A", label = sel }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } } end
    local r = self:focusedRow()
    local t = {}
    if r then
        if r.kind == "combo" then t[#t + 1] = { glyph = "<>", label = ZeD.tr("UI_ZeD_Options_PromptChange") } end
        t[#t + 1] = { glyph = "A", label = ZeD.tr((r.kind == "tick") and "UI_ZeD_Options_PromptToggle" or ((r.kind == "entry") and "UI_ZeD_Sandbox_PromptEdit" or "UI_ZeD_MainMenu_PromptSelect")) }
    else
        t[#t + 1] = { glyph = "A", label = sel }
    end
    t[#t + 1] = { glyph = "LB", label = "" }
    t[#t + 1] = { glyph = "RB", label = ZeD.tr("UI_ZeD_Options_PromptPage") }
    t[#t + 1] = { glyph = "B", label = getText("UI_Cancel") }
    return t
end

function ZeD_MMServer:keyEscape()
    if self._cellRow then self:endCell(); return true end
    if self.confirm then self:setConfirm(false); return true end
    for _, e in ipairs(self._extra) do if e:isFocused() then e:unfocus(); return true end end
    if self.find:isFocused() then self.find:unfocus(); return true end
    self:act("back")
    return true
end

function ZeD_MMServer:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self._cellRow then return key == Keyboard.KEY_RETURN end
    for _, e in ipairs(self._extra) do if e:isFocused() then return false end end
    if self.find:isFocused() or self.confirm then return false end
    if key == Keyboard.KEY_RETURN then
        local m = self:mode()
        if m == "list" then self:act("edit")
        elseif m == "edit" or m == "points" then self:act("save")
        elseif m ~= "delete" then self:act("accept") end   -- (deleting is only ever the band's Delete)
        return true
    end
    return false
end

function ZeD_MMServer:wheel(del)
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    for key, b in pairs(self._listBoxes or {}) do
        if mx >= b.x and mx < b.x + b.w and my >= b.y and my < b.y + b.h then
            self._lists[key] = (self._lists[key] or 0) + del * ZeD.T.px(LIST_ROW_H)
            return true
        end
    end
    local pb = self._pagesBox
    if pb and self:mode() == "edit" and mx >= pb.x and mx < pb.x + pb.w and my >= pb.y and my < pb.y + pb.h then
        self.pagesScroll = (self.pagesScroll or 0) + del * ZeD.T.px(PAGE_ROW_H)
        return true
    end
    if self:mode() == "edit" then return ZeD_MMSandbox.wheel(self, del) end
    return false
end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "srvset" and MM.root and MM.root.srvWin then
        if MM.dropWheel and MM.dropWheel(del) then return true end
        return MM.root.srvWin:wheel(del)
    end
    return _wheel(del)
end

-- on the desk as the "srvset" view; vanilla's serverSettingsScreen:setVisible(true) lands here
MM.addView("srvset", "srvWin", function() return ZeD_MMServer:new() end, "serverSettingsScreen")
