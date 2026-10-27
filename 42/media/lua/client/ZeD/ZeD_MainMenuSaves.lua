-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuSaves.lua
-- ============================================================================
-- LOAD GAME + NEW GAME ON THE MONITOR (HOOK_MAP row 26, phase 2; mockup
-- zed_main_menu_v9, approved Oct 14 2026)
--
-- Two more ZeD windows on the desk's screen, one view at a time with the
-- Project Zomboid window (ZeD_MainMenu.lua: MM.showView).
--
-- LOAD GAME: the saves by mode under inventory category headers, newest
-- first, a plain "Find:" field; the chosen save on the right, leading with
-- its character (director: "lead with the character name large, then the
-- save name in a medium heading"), then mode, map, played, mods, version and
-- PLAYING AS. BACK, Delete (asks in the band), More (Rename File,
-- New Player, Choose Mods, Open File Location), PLAY. Every rule is vanilla's
-- LoadGameScreen: what may be played, the player switch, rename, delete.
--
-- NEW GAME: a 1993 icon view of vanilla's playstyles (and its challenges),
-- vanilla's description below; BACK, CHOOSE MODS, NEXT. NEXT runs vanilla's
-- own NewGameScreen.clickPlay, so map / spawn, sandbox options and character
-- creation follow as vanilla's screens; their BACK lands here again
-- (MM.redirect).
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ISUI/ISTextEntryBox"

local MM = ZeD.MainMenu
local U  = MM.U

-- design units
local MARGIN, TOP_GAP = 20, 12
local LIST_SHARE = 0.43             -- the list's share of the Load Game body
local FIND_H, HEAD_H, ROW_H, ROW_THUMB = 34, 20, 48, 40
local PREV_THUMB_H = 220
local KV_LABEL_W, KV_ROW_H = 96, 20
local ICON_W, ICON_H, ICON_COLS = 114, 128, 6

local function ms() return MainScreen and MainScreen.instance end

-- strip a rich-text string ("<LINE>", "<RGB:1,0,0>") to plain words
local function plain(s) return (tostring(s or ""):gsub("<[^>]*>", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")) end

-- ---------------------------------------------------------------------------
-- shared: the band at the window's foot (spec 8), as the screens' specs
-- A screen names the buttons it has: the old left group and right group are one run of push
-- buttons now, right-aligned, the main one last (the band is MM.band, in ZeD_MainMenu.lua). Each
-- is { id, text, fn, variant, disabled, help }; ask is the band's left line (a question with a
-- red square, or with plain a label; statusColor gives a plain line its square). The band is
-- drawn here, in the window's prerender, so a field standing in it is a child that draws over it.
-- ---------------------------------------------------------------------------
local function stripSpecs(win, y, w, row, lefts, rights, ask, plain, statusColor)
    local btns = {}
    for _, group in ipairs({ lefts, rights }) do
        for _, r in ipairs(group) do
            btns[#btns + 1] = { id = r[1], text = r[2], fn = r[3], variant = r[4], disabled = r[5], help = r[6] or MM.helpFor(r[1]) }
        end
    end
    MM.band(win, y, w, row, btns, ask, plain, statusColor)
    return MM.bandFieldX(ask)   -- where a field beside the band's line can start
end

-- the band's hit boxes, then every other button the window's specs hold (a pane's own buttons,
-- clipped to the pane), drawn and answered
local function drawStripAndButtons(win)
    local ctx, gp = (win.pctx and win:pctx()) or MM.ctx, MM.gamepad()
    local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
    MM.bandHits(win)
    for _, b in ipairs(win._specs) do
        -- a button inside a scrolled pane draws (and clicks) only while it is fully in view
        local clipped = b.clipTop and (b.y < b.clipTop or b.y + b.h > b.clipBot)
        if not b.band and not b.listRow and not clipped then
            local hid = win.kind .. ":" .. b.id
            local hot = not gp and ctx.hot == hid
            MM.drawBtn(win, b, hot, gp and win.focusId == b.id, hot and ctx.press == hid)
            win._hits[#win._hits + 1] = { id = hid, x = ax + b.x, y = ay + b.y, w = b.w, h = b.h, fn = b.fn, disabled = b.disabled, sound = true }
        end
    end
end

-- an inset box (System 7 list box / field well): the base surface without stacking on the body,
-- a 1u frame. loose = true for a box inside a scrolled list (it must not claim a place in the body)
local function insetBox(p, x, y, w, h, loose)
    local T = ZeD.T
    if loose then
        local b = T.base
        p:drawRect(x, y, w, h, b.a or 1, b.r, b.g, b.b)
    else
        ZeD.Surface.fill(p, x, y, w, h, "base")
    end
    ZeD.Atoms.frame(p, x, y, w, h, T.borderS)
end

-- a ZeD-styled text entry: role face, theme colours (ZeD.Text.fitEntry), inset look
local function newEntry(win)
    local e = ISTextEntryBox:new("", 0, 0, 100, 24)
    e:initialise()
    e:instantiate()
    e.font = ZeD.Text.entryFont and ZeD.Text.entryFont() or UIFont.Small
    -- Escape inside a focused field never reaches the menu (KB Q217): the field leaves
    -- itself, or runs its onEscape (a question's field cancels the question)
    e.onOtherKey = function(entry, key)
        if key == Keyboard.KEY_ESCAPE then
            if entry.onEscape then entry.onEscape() else entry:unfocus() end
        end
    end
    win:addChild(e)
    return e
end
local function styleEntry(e, x, y, w, h)
    local T = ZeD.T
    if ZeD.Text.fitEntry then ZeD.Text.fitEntry(e) end
    if e.x ~= x or e.y ~= y then e:setX(x); e:setY(y) end
    if e.width ~= w or e.height ~= h then e:setWidth(w); e:setHeight(h) end
    local b, bs = T.base, T.borderS
    e.backgroundColor = { r = b.r, g = b.g, b = b.b, a = 1 }
    e.borderColor = { r = bs.r, g = bs.g, b = bs.b, a = bs.a or 1 }
end

-- the window's place on the monitor: below the menu bar, margins all round
local function placeOnTube(win, h)
    local T, L = ZeD.T, MM.layout()
    local barH = T.px(U.BAR_H)
    local m = math.min(T.px(MARGIN), math.floor(L.tw / 40))
    local w = L.tw - m * 2
    local x = L.tx + m
    local y
    if h then
        y = L.ty + barH + math.max(T.px(TOP_GAP), math.floor((L.th - barH - h) / 2))
    else
        y = L.ty + barH + T.px(TOP_GAP)
        h = L.th - barH - T.px(TOP_GAP) * 2
    end
    if win.x ~= x or win.y ~= y then win:setX(x); win:setY(y) end
    if win.width ~= w or win.height ~= h then win:setWidth(w); win:setHeight(h) end
    return w, h
end

-- ============================================================================
-- LOAD GAME
-- ============================================================================
ZeD_MMLoad = ZeD_MMWindow:derive("ZeD_MMLoad")

function ZeD_MMLoad:new()
    local o = ZeD_MMWindow.new(self, "load")
    o.noResetControl = true
    o.saves, o.view = {}, {}
    o.sel = nil
    o.scroll = 0
    o.collapsed = {}
    o.confirm = false      -- false | "delete" | "rename"
    return o
end

function ZeD_MMLoad:createChildren()
    ZeD_Window.createChildren(self)
    self.find = newEntry(self)
    self.find.onTextChange = function() self:filter() end
    -- a focused field takes Return itself (the key never reaches the menu): onCommandEntered
    -- (the same key then also reaches the menu once the field lets go: _enterAt swallows it)
    self.find.onCommandEntered = function() self._enterAt = MM.now(); self.find:unfocus() end
    self.renameEntry = newEntry(self)
    self.renameEntry.onCommandEntered = function() self._enterAt = MM.now(); self:rename() end
    self.renameEntry.onEscape = function() self:setConfirm(false) end
    self.renameEntry:setVisible(false)
end

-- Reads every save the way vanilla's LoadGameScreen:setSaveGamesList does.
function ZeD_MMLoad:readSaves()
    local saves = {}
    local ok, dirs = pcall(getFullSaveDirectoryTable)
    for i, k in ipairs(ok and dirs or {}) do
        local okI, info = pcall(getSaveInfo, k)
        if okI and type(info) == "table" then
            local s = { key = k, order = i, info = info }
            s.mode = info.gameMode or tostring(k):match("^([^\\/]+)") or ""
            s.saveName = info.saveName or ""
            s.title = MM.saveTitle(s.saveName, s.mode)
            s.mapName = info.mapName
            s.activeMods = info.activeMods
            local okP, played = pcall(getLastPlayedDate, k)
            s.played = okP and MM.playedText(played) or ""
            self:readPlayers(s)
            saves[#saves + 1] = s
        end
    end
    self.saves = saves
end

-- the character the save plays as: vanilla's player 1 (sqlID 1) if alive, else the first alive one
function ZeD_MMLoad:readPlayers(s)
    local info = s.info
    s.dead = info.playerAlive == false
    local who, first = nil, nil
    for _, p in ipairs(info.players or {}) do
        if not p.isDead then
            first = first or p
            if p.sqlID == 1 then who = p end
        end
    end
    who = who or first or (info.players and info.players[1])
    s.who = who and who.name or nil
end

-- Groups (by mode, in order of each mode's newest save) and the Find filter -> self.view rows.
function ZeD_MMLoad:filter()
    local q = string.lower(tostring(self.find and self.find:getInternalText() or ""))
    local groups, order = {}, {}
    for _, s in ipairs(self.saves) do
        local hay = string.lower(table.concat({ s.title, s.saveName, s.who or "", MM.modeName(s.mode), MM.mapText(s.mapName) }, " "))
        if q == "" or hay:find(q, 1, true) then
            local g = groups[s.mode]
            if not g then g = { mode = s.mode, saves = {} }; groups[s.mode] = g; order[#order + 1] = g end
            g.saves[#g.saves + 1] = s
        end
    end
    local rows = {}
    for _, g in ipairs(order) do
        rows[#rows + 1] = { head = true, mode = g.mode, count = #g.saves }
        if not self.collapsed[g.mode] then
            for _, s in ipairs(g.saves) do rows[#rows + 1] = { save = s } end
        end
    end
    self.view = rows
    -- keep the chosen save if it is still listed, else the first
    local keep = false
    for _, r in ipairs(rows) do if r.save and r.save.key == self.sel then keep = true end end
    if not keep then
        self.sel = nil
        for _, r in ipairs(rows) do if r.save then self.sel = r.save.key; break end end
    end
end

function ZeD_MMLoad:selected()
    for _, s in ipairs(self.saves) do if s.key == self.sel then return s end end
    return nil
end

-- every time Load Game opens: a fresh list, nothing asked; the save chosen before stays
-- chosen (back from Choose Mods), else the latest
function ZeD_MMLoad:onShow()
    self.confirm = false
    self.renameEntry:setVisible(false)
    self.find:setText("")
    local keep = self.sel
    self:readSaves()
    self.sel = nil
    for _, s in ipairs(self.saves) do if s.key == keep then self.sel = keep end end
    if not self.sel then self.sel = self.saves[1] and self.saves[1].key or nil; self.scroll = 0 end
    self:filter()
    self.focusId = self.sel and ("save:" .. self.sel) or nil
end

-- vanilla's rules for what may be played (LoadGameScreen:disableBtn), with the reason
function ZeD_MMLoad:whyNot(s)
    if not s then return "none" end
    local info = s.info
    local wv = tonumber(info.worldVersion)
    if not wv or not info.mapName then return getText("UI_mainscreen_SavefileNotFound") end
    if wv == 0 then return getText("UI_worldscreen_SavefileCorrupt") end
    if wv > IsoWorld.getWorldVersion() then return getText("UI_worldscreen_SavefileNewerThanGame") end
    if wv <= 200 then return getText("UI_worldscreen_SavefileOld") end
    local m = ms()
    if m and m.loadScreen and s.mapsAvailable == nil then
        pcall(LoadGameScreen.checkMapsAvailable, m.loadScreen, s)
    end
    if s.mapsAvailable == false then return getText("UI_worldscreen_MapNotFound") end
    if s.dead and s.mode == "A Really CD DA" then return getText("UI_worldscreen_SavefileCDDA") end
    return nil
end

-- ACTIONS ---------------------------------------------------------------------

function ZeD_MMLoad:back()
    MM.clickSound()
    if self.find:isFocused() then self.find:unfocus() end
    MM.showView("main")
end

function ZeD_MMLoad:play()
    local s = self:selected()
    if not s or self:whyNot(s) then return end
    if self.find:isFocused() then self.find:unfocus() end
    MainScreen.continueLatestSave(s.mode, s.saveName)   -- vanilla's LoadGameScreen:clickPlay
end

function ZeD_MMLoad:askDelete()
    if not self:selected() then return end
    self:setConfirm("delete")
end

function ZeD_MMLoad:delete()
    local s = self:selected()
    if not s then return end
    pcall(deleteSave, s.key)
    self:setConfirm(false)
    -- vanilla keeps the main menu's Continue and Load in step with what is left
    local m = ms()
    if m then
        m:getLatestSave()
        local ok, dirs = pcall(getFullSaveDirectoryTable)
        m.hasSaveFiles = ok and #dirs > 0 or false
        if m.latestSaveOption then m.latestSaveOption:setVisible(m.hasSaveFiles and MainScreen.latestSaveWorld ~= nil) end
        if m.loadOption then m.loadOption:setVisible(m.hasSaveFiles) end
        MM.refresh()
        if not m.hasSaveFiles then
            MM.act.newGame()   -- vanilla goes to New Game when the last save is gone
            return
        end
    end
    self:readSaves()
    self.sel = nil
    self:filter()
    self.focusId = self.sel and ("save:" .. self.sel) or nil
end

-- vanilla's ConfigPanel:validateSavefileName
function ZeD_MMLoad:renameValid(text)
    local s = self:selected()
    if not s or not text then return false end
    if text == s.saveName then return false end
    local worldName = sanitizeWorldName(text)
    if worldName == "" or worldName ~= text or luautils.stringStarts(worldName, ".") or luautils.stringEnds(worldName, ".") then return false end
    local check = s.mode .. getFileSeparator() .. worldName
    if check ~= self._renameChecked then
        self._renameChecked = check
        self._renameExists = checkSaveFolderExists(check)
    end
    return not self._renameExists
end

function ZeD_MMLoad:startRename()
    local s = self:selected()
    if not s then return end
    self:setConfirm("rename")
    self.renameEntry:setText(s.saveName)
    self.renameEntry:setVisible(true)
    self.renameEntry:focus()
end

function ZeD_MMLoad:rename()
    local s = self:selected()
    if not s then return end
    local text = self.renameEntry:getText()
    if not self:renameValid(text) then return end
    local wasLatest = (MainScreen.latestSaveWorld == s.saveName and MainScreen.latestSaveGameMode == s.mode)
    if renameSavefile(s.mode, s.saveName, text) then
        self.sel = s.mode .. getFileSeparator() .. text
        if wasLatest and ms() then ms():getLatestSave(); MM.refresh() end
    end
    self:setConfirm(false)
    self:readSaves()
    self:filter()
end

-- vanilla's ConfigPanel:onNewPlayer: the save starts with a new character
function ZeD_MMLoad:newPlayer()
    local s = self:selected()
    if not s or s.mode == "A Really CD DA" then return end
    setSavefilePlayer1(s.mode, s.saveName, -1)
    self:play()
end

-- vanilla's ConfigPanel:onChooseMods: the mod list for this save, back here after
function ZeD_MMLoad:chooseMods()
    local s = self:selected()
    if not s or not ModSelector or not ModSelector.instance then return end
    local jd = JoypadState.getMainMenuJoypad()
    ModSelector.instance.model.isNewGame = false   -- vanilla leaves it set after a New Game visit
    ModSelector.instance.model.isServerSettingsMods = false
    ModSelector.instance:setExistingSavefile(s.key)
    ModSelector.instance:setVisible(true, jd)
    ModSelector.instance:reloadMods()
    ModSelector.showNagPanel()
    ModSelector.instance.returnToUI = LoadGameScreen.instance
    s.mapsAvailable = nil
end

function ZeD_MMLoad:openFolder()
    local s = self:selected()
    if s then pcall(function() showFolderInDesktop(getAbsoluteSaveFolderName(s.key)) end) end
end

function ZeD_MMLoad:moreItems()
    local s = self:selected()
    local t = {
        { text = ZeD.tr("UI_ZeD_Saves_RenameFile"), fn = function() self:startRename() end },
        { text = ZeD.btnCase(getText("UI_LoadGameScreen_ButtonNewPlayer")), fn = function() self:newPlayer() end, disabled = (s == nil) or s.mode == "A Really CD DA" },
        { text = ZeD.tr("UI_LoadGameScreen_ButtonChooseMods"), fn = function() self:chooseMods() end },
    }
    local okD, desk = pcall(isDesktopOpenSupported)
    if okD and desk then
        t[#t + 1] = "-"
        t[#t + 1] = { text = ZeD.tr("UI_LoadGameScreen_ButtonBrowseFiles"), fn = function() self:openFolder() end }
    end
    return t
end

function ZeD_MMLoad:openMore()
    for _, b in ipairs(self._specs) do
        if b.id == "more" then
            MM.openPopup("more", self:moreItems(), { x = self:getAbsoluteX() + b.x, y = self:getAbsoluteY() + b.y, w = b.w, h = b.h }, true)
            return
        end
    end
end

-- PLAYING AS: vanilla's player list (ConfigPanel:setSavefile / onPlayerSelected)
function ZeD_MMLoad:playerOptions(s)
    local opts = {}
    if not s.info.playerAlive then opts[#opts + 1] = { name = getText("UI_LoadGameScreen_NoPlayer1"), player = nil } end
    for _, p in ipairs(s.info.players or {}) do
        if not p.isDead then opts[#opts + 1] = { name = p.name, player = p } end
    end
    return opts
end

function ZeD_MMLoad:pickPlayer(s, p)
    if not p then return end
    setSavefilePlayer1(s.mode, s.saveName, p.sqlID)
    local ok, info = pcall(getSaveInfo, s.key)
    if ok and type(info) == "table" then s.info = info; self:readPlayers(s) end
end

function ZeD_MMLoad:openPlayers(anchor)
    local s = self:selected()
    if not s then return end
    local items = {}
    for _, o in ipairs(self:playerOptions(s)) do
        items[#items + 1] = { text = o.name, fn = function() self:pickPlayer(s, o.player) end, disabled = o.player == nil }
    end
    MM.openPopup("players", items, anchor, false)
end

-- the question or the rename field in the band; false closes it
function ZeD_MMLoad:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.clickSound()
    if mode ~= "rename" then
        self.renameEntry:setVisible(false)
        if self.renameEntry:isFocused() then self.renameEntry:unfocus() end
    end
    if mode == "delete" then self.focusId = "confirm:yes"
    elseif mode == "rename" then self.focusId = "confirm:no"
    else self.focusId = self.sel and ("save:" .. self.sel) or "back" end
end

-- LAYOUT + DRAWING ---------------------------------------------------------------

function ZeD_MMLoad:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = placeOnTube(self)
    self.title = ZeD.tr("UI_ZeD_Saves_Title")
    local n = #self.saves
    self.titleStats = { { text = ZeD.tr(n == 1 and "UI_ZeD_Saves_CountOne" or "UI_ZeD_Saves_CountMany", n), noMark = true } }
    ZeD_Window.prerender(self)

    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local listW = math.floor((w - pad * 3) * LIST_SHARE)
    local lx, px = pad, pad * 2 + listW
    local pw = w - px - pad
    self:drawList(lx, bodyY, listW, bodyH)
    self:drawPreview(px, bodyY, pw, bodyH)

    -- the band at the foot (spec 8): Delete asks in it, Rename puts its field in it
    local s = self:selected()
    local why = self:whyNot(s)
    local row = 1000
    if self.confirm == "delete" then
        stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:delete() end, "danger", false, ZeD.tr("UI_ZeD_MMHelp_DeleteSave") } },
            ZeD.tr("UI_ZeD_Saves_AskDelete", s and s.title or ""))
    elseif self.confirm == "rename" then
        local ask = ZeD.tr("UI_ZeD_Saves_AskRename")
        local valid = self:renameValid(self.renameEntry:getText())
        local fx = stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_rename"), function() self:rename() end, "primary", not valid, ZeD.tr("UI_ZeD_MMHelp_RenameSave") } },
            ask, true)
        -- the field fills the band between the label and the buttons
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        styleEntry(self.renameEntry, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
    else
        stripSpecs(self, stripY, w, row,
            { { "back", getText("UI_btn_back"), function() self:back() end } },
            { { "delete", getText("UI_btn_delete"), function() self:askDelete() end, "default", s == nil, ZeD.tr("UI_ZeD_MMHelp_DeleteSaveAsk") },
              { "more", ZeD.tr("UI_ZeD_Saves_More"), function() self:openMore() end, "default", s == nil },
              { "play", getText("UI_btn_play"), function() self:play() end, "primary", why ~= nil, ZeD.tr("UI_ZeD_MMHelp_PlaySave") } })
    end
end

function ZeD_MMLoad:render()
    drawStripAndButtons(self)
    ZeD_Window.render(self)
end

-- the footer line when nothing is under the pointer
function ZeD_MMLoad:getStatusLine()
    local n = #self.saves
    return ZeD.tr(n == 1 and "UI_ZeD_Saves_CountOne" or "UI_ZeD_Saves_CountMany", n)
end

function ZeD_MMLoad:drawList(x, y, w, h)
    local T = ZeD.T
    local bs, s2 = T.borderS, T.surf2
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    -- the box and the Find row
    insetBox(self, x, y, w, h)
    local fH = T.px(FIND_H)
    ZeD.Surface.fill(self, x + T.px(1), y + T.px(1), w - 2 * T.px(1), fH - T.px(1), "surf2")
    ZeD.Atoms.drawDividerH(self, x, y + fH, w, true)
    local f2, c = T.fontF2, T.text
    local label = ZeD.tr("UI_ZeD_Saves_Find")
    self:drawText(label, x + T.px(8), y + math.floor((fH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
    local ex = x + T.px(8) + MM.textW(f2, label) + T.px(8)
    local eh = T.px(24)
    styleEntry(self.find, ex, y + math.floor((fH - eh) / 2), x + w - T.px(8) - ex, eh)
    -- the field takes the click itself (the screen's glass sits above every panel)
    self._hits[#self._hits + 1] = { id = "load:find", x = ax + self.find.x, y = ay + self.find.y, w = self.find.width, h = self.find.height,
                                    fn = function() self.find:focus() end }

    -- the rows, scrolled inside the box
    local vy, vh = y + fH + T.px(1), h - fH - T.px(2)
    local rowsH = 0
    for _, r in ipairs(self.view) do rowsH = rowsH + (r.head and T.px(HEAD_H) or T.px(ROW_H)) end
    local sbW = T.sp.scrollbarW
    local over = rowsH > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, rowsH - vh)))
    self._list = { x = x, y = vy, w = w, h = vh, rowsH = rowsH }
    local gp = MM.gamepad()
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    local ry = vy - self.scroll
    local idx = 0
    for _, r in ipairs(self.view) do
        local rh = r.head and T.px(HEAD_H) or T.px(ROW_H)
        local visible = ry + rh > vy and ry < vy + vh
        if r.head then
            if visible then
                local hid = "load:head:" .. r.mode
                -- (a head half-scrolled out would claim a place outside the pane: it waits until it is wholly in)
                if ry >= vy and ry + rh <= vy + vh then ZeD.Molecules.drawSectionHeader(self, x + T.px(1) + T.px(8), ry, rw - T.px(8), MM.modeName(r.mode), r.count,
                    not self.collapsed[r.mode], MM.ctx.hot == hid, T.fontF1, true, T.px(8), rh) end
                local cy, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
                self._hits[#self._hits + 1] = { id = hid, x = ax + x, y = ay + cy, w = rw, h = ch,
                    fn = function() self.collapsed[r.mode] = not self.collapsed[r.mode]; self:filter() end }
            end
        else
            idx = idx + 1
            local s = r.save
            local sid = "save:" .. s.key
            -- every save is a controller row (A plays it)
            self._specs[#self._specs + 1] = { id = sid, listRow = true, row = idx, col = 1, fn = function() self:play() end, key = s.key, ry = ry + self.scroll - vy, rh = rh }
            if visible then
                local isSel = (s.key == self.sel)
                local onFocus = MM.rowLook(self, x + T.px(1), ry, rw, rh, isSel, (not gp) and MM.ctx.hot == "load:" .. sid, gp and self.focusId == sid)
                self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
                -- thumbnail
                local tsz = T.px(ROW_THUMB)
                local tx, ty = x + T.px(8), ry + math.floor((rh - tsz) / 2)
                if s.thumb == nil then
                    local okT, t = pcall(getTextureFromSaveDir, "thumb.png", s.key)
                    s.thumb = (okT and t) or false
                end
                if s.thumb then self:drawTextureScaledAspect(s.thumb, tx, ty, tsz, tsz, 1, 1, 1, 1)
                else local s3 = T.surf3; self:drawRect(tx, ty, tsz, tsz, 1, s3.r, s3.g, s3.b) end
                ZeD.Atoms.frame(self, tx, ty, tsz, tsz, T.border)
                -- the character, then the save and its map
                local ix = tx + tsz + T.px(10)
                local maxW = x + rw - T.px(8) - ix
                local f2b, f3, d = T.fontF2, T.fontF3, T.textDim
                local lx = ix
                local name = s.who or s.title
                local nameC = onFocus and T.textOnFocus or (s.dead and d or T.textHead)
                if onFocus then d = T.textOnFocus end
                local l1y = ry + T.px(7)
                if s.dead then
                    local dsz = T.px(7)
                    ZeD.Atoms.drawStatusDot(self, lx, l1y + math.floor((MM.fontH(f2b) - dsz) / 2), T.danger, dsz)
                    lx = lx + dsz + T.px(5)
                end
                self:drawText(ZeD.Atoms.truncateText(s.dead and ZeD.tr("UI_ZeD_Saves_NameDead", name) or name, f2b, maxW - (lx - ix)), lx, l1y, nameC.r, nameC.g, nameC.b, nameC.a or 1, f2b)
                local sub = (s.who and (s.title .. MM.DOT) or "") .. MM.mapText(s.mapName)
                self:drawText(ZeD.Atoms.truncateText(sub, f3, maxW), ix, ry + rh - T.px(7) - MM.fontH(f3), d.r, d.g, d.b, d.a or 1, f3)
                local cy, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
                self._hits[#self._hits + 1] = { id = "load:" .. sid, x = ax + x, y = ay + cy, w = rw, h = ch, fn = function() self:clickSave(s) end }
                if MM.ctx.hot == "load:" .. sid and not gp then ZeD.Help.set(self, ZeD.tr("UI_ZeD_MMHelp_SaveRow")) end
            end
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    -- the scroll bar: a track to click and a thumb
    if over then
        local sx = x + w - T.px(1) - sbW
        ZeD.Atoms.drawScrollTrack(self, sx, vy, sbW, vh)
        local th = math.max(T.px(24), math.floor(vh * vh / rowsH))
        local tyy = vy + math.floor((vh - th) * self.scroll / (rowsH - vh))
        ZeD.Atoms.drawScrollThumb(self, sx, tyy, sbW, th, MM.ctx.hot == "load:track" and "hover" or "default")
        self._hits[#self._hits + 1] = { id = "load:track", x = ax + sx, y = ay + vy, w = sbW, h = vh, fn = function()
            local my = getMouseY() - ay - vy
            self.scroll = math.floor((my / vh) * rowsH - vh / 2)
        end }
    end
end

-- a click picks the save; a second click on it soon after plays it (vanilla's double-click)
function ZeD_MMLoad:clickSave(s)
    local t = MM.now()
    if self.sel == s.key and self._lastClick and t - self._lastClick < 450 then
        self._lastClick = nil
        self:play()
        return
    end
    self._lastClick = t
    if self.sel ~= s.key then MM.hoverSound() end
    self.sel = s.key
    self.focusId = "save:" .. s.key
end

function ZeD_MMLoad:drawPreview(x, y, w, h)
    local T = ZeD.T
    local bs = T.borderS
    ZeD.Atoms.frame(self, x, y, w, h, bs)
    local s = self:selected()
    if not s then return end
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local pad = T.px(12)
    local ix, iw = x + pad, w - pad * 2
    local cy = y + pad
    -- the picture: full width, cropped to its middle band
    local th = math.min(T.px(PREV_THUMB_H), iw, math.floor(h * 0.42))
    if s.thumb == nil then
        local okT, t = pcall(getTextureFromSaveDir, "thumb.png", s.key)
        s.thumb = (okT and t) or false
    end
    if s.thumb then
        self:setStencilRect(ix, cy, iw, th)
        self:drawTextureScaledAspect(s.thumb, ix, cy - math.floor((iw - th) / 2), iw, iw, 1, 1, 1, 1)
        self:clearStencilRect()
    else
        local s3 = T.surf3
        self:drawRect(ix, cy, iw, th, 1, s3.r, s3.g, s3.b)
    end
    ZeD.Atoms.frame(self, ix, cy, iw, th, bs)
    cy = cy + th + T.px(10)
    -- the character, large; the save, a medium heading
    local tc = T.textHead
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local bigH = math.floor(ZeD.Text.height(hf, z))
    local lx = ix
    if s.who and s.dead then
        local dsz = T.px(9)
        ZeD.Atoms.drawStatusDot(self, lx, cy + math.floor((bigH - dsz) / 2), T.danger, dsz)
        lx = lx + dsz + T.px(6)
    end
    local big = (s.who and s.dead) and ZeD.tr("UI_ZeD_Saves_NameDead", s.who) or (s.who or s.title)
    if ZeD.Text.width(hf, big, z) > iw - (lx - ix) then
        while #big > 1 and ZeD.Text.width(hf, big .. "...", z) > iw - (lx - ix) do big = big:sub(1, #big - 1) end
        big = big .. "..."
    end
    ZeD.Text.draw(self, hf, big, lx, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    cy = cy + bigH + T.px(2)
    if s.who then
        local f4 = T.fontF4
        self:drawText(ZeD.Atoms.truncateText(s.title, f4, iw), ix, cy, tc.r, tc.g, tc.b, tc.a or 1, f4)
        cy = cy + math.floor(MM.fontH(f4)) + T.px(8)
    else
        cy = cy + T.px(6)
    end
    -- the facts: mono accent labels, plain values (the stat-grid look)
    local f1, f2 = T.fontF1, T.fontF2
    local kvH = T.px(KV_ROW_H)
    local vx = ix + T.px(KV_LABEL_W)
    local vw = ix + iw - vx
    local function kv(label, value, color)
        local la = T.accent
        self:drawText(label, ix, cy + math.floor((kvH - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
        if value then
            local c = color or T.text
            self:drawText(ZeD.Atoms.truncateText(value, f2, vw), vx, cy + math.floor((kvH - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
        end
        cy = cy + kvH
    end
    kv(ZeD.tr("UI_ZeD_Saves_KvMode"), MM.modeName(s.mode))
    kv(ZeD.textCase(ZeD.trBare("UI_servers_Map")), MM.mapText(s.mapName))
    kv(ZeD.tr("UI_ZeD_Saves_KvPlayed"), s.played)
    -- mods: names, and any the game cannot find
    local names, missing = {}, {}
    local okM = pcall(function()
        local list = s.activeMods and s.activeMods:getMods()
        if list then
            for i = 0, list:size() - 1 do
                local id = list:get(i)
                local mi = getModInfoByID(id)
                if mi and mi:isAvailable() then names[#names + 1] = mi:getName()
                else missing[#missing + 1] = mi and mi:getName() or id end
            end
        end
    end)
    local modsText = (#names > 0) and table.concat(names, ", ") or ((#missing > 0) and ZeD.tr("UI_ZeD_Saves_ModsMissing", #missing) or ZeD.tr("IGUI_None"))
    kv(ZeD.textCase(ZeD.trBare("UI_LoadGameScreen_Mods")), modsText)
    kv(ZeD.textCase(ZeD.tr("Version")), tostring(s.info.worldVersion or "?"))
    -- PLAYING AS: a list box when the save has more than one character to play
    local opts = self:playerOptions(s)
    if #opts > 1 then
        local la = T.accent
        self:drawText(ZeD.tr("UI_ZeD_Saves_KvPlayingAs"), ix, cy + math.floor((T.px(26) - MM.fontH(f1)) / 2), la.r, la.g, la.b, la.a or 1, f1)
        local cw = math.min(vw, math.max(T.px(160), MM.textW(f2, s.who or "") + T.px(40)))
        local cx0, cyy, ch = vx, cy + math.floor((T.px(26) - T.px(24)) / 2), T.px(24)
        local hid = "load:players"
        local cur = s.info.playerAlive and (s.who or "") or getText("UI_LoadGameScreen_NoPlayer1")
        MM.drawDropBox(self, cx0, cyy, cw, ch, cur, MM.ctx.hot == hid)
        local anchor = { x = ax + cx0, y = ay + cyy, w = cw, h = ch }
        self._hits[#self._hits + 1] = { id = hid, x = anchor.x, y = anchor.y, w = cw, h = ch, fn = function() self:openPlayers(anchor) end, sound = true }
        cy = cy + T.px(26)
    end
    -- what stops it loading, and mods it cannot find: a red status dot and the words
    local notes = {}
    local why = self:whyNot(s)
    if why then notes[#notes + 1] = getText("UI_worldscreen_SaveCannotBeLoaded") .. " " .. why end
    if #missing > 0 then notes[#notes + 1] = ZeD.tr("UI_ZeD_Saves_NoteModsMissing", table.concat(missing, ", ")) end
    cy = cy + T.px(6)
    for _, n in ipairs(notes) do
        local dsz = T.px(7)
        local lines = ZeD.Atoms.wrapText(plain(n), f2, iw - dsz - T.px(6))
        for i, l in ipairs(lines) do
            if cy + MM.fontH(f2) > y + h - pad then break end
            if i == 1 then ZeD.Atoms.drawStatusDot(self, ix, cy + math.floor((MM.fontH(f2) - dsz) / 2), T.danger, dsz) end
            local c = T.text
            self:drawText(l, ix + dsz + T.px(6), cy, c.r, c.g, c.b, c.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(2)
        end
    end
end

-- CONTROLLER + KEYS ------------------------------------------------------------

-- the list follows the controller: a focused save is the chosen one, scrolled into view
function ZeD_MMLoad:joyDir(dir)
    if self.confirm == "rename" and (dir == "up" or dir == "down") then return end
    ZeD_MMWindow.joyDir(self, dir)
    for _, b in ipairs(self._specs) do
        if b.id == self.focusId and b.listRow then
            self.sel = b.key
            local vh = self._list and self._list.h or 0
            if b.ry < self.scroll then self.scroll = b.ry
            elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
        end
    end
end

function ZeD_MMLoad:joyB()
    if self.confirm then self:setConfirm(false) else self:back() end
end
function ZeD_MMLoad:joyX() if not self.confirm then self:askDelete() end end
function ZeD_MMLoad:joyY() if not self.confirm and self:selected() then self:openMore() end end

function ZeD_MMLoad:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local back = ZeD.btnCase(getText("UI_btn_back"))
    if self.confirm == "delete" then return { { glyph = "A", label = ZeD.btnCase(getText("UI_btn_delete")) }, { glyph = "B", label = getText("UI_Cancel") } } end
    if self.confirm == "rename" then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    local f = self.focusId or ""
    if f:sub(1, 5) == "save:" then
        return { { glyph = "A", label = getText("IGUI_media_play") }, { glyph = "X", label = ZeD.btnCase(getText("UI_btn_delete")) }, { glyph = "Y", label = ZeD.tr("UI_ZeD_Saves_More") }, { glyph = "B", label = back } }
    end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = back } }
end

-- Escape: leave a field, then a question, then Load Game
function ZeD_MMLoad:keyEscape()
    if self.renameEntry:isFocused() or self.confirm then self:setConfirm(false); return true end
    if self.find:isFocused() then self.find:unfocus(); return true end
    self:back()
    return true
end

-- Return plays (or renames); Delete asks; the arrow keys walk the list
function ZeD_MMLoad:keyOther(key)
    if key == Keyboard.KEY_RETURN and self._enterAt and MM.now() - self._enterAt < 400 then return true end
    if self.confirm == "rename" then
        if key == Keyboard.KEY_RETURN then self:rename(); return true end
        return false
    end
    if self.find:isFocused() then
        if key == Keyboard.KEY_RETURN then self.find:unfocus(); return true end
        return false
    end
    if self.confirm == "delete" then
        if key == Keyboard.KEY_RETURN then self:delete(); return true end
        return false
    end
    if key == Keyboard.KEY_RETURN then self:play(); return true end
    if key == Keyboard.KEY_DELETE then self:askDelete(); return true end
    if key == Keyboard.KEY_UP or key == Keyboard.KEY_DOWN then
        self.focusId = self.sel and ("save:" .. self.sel) or nil
        self:joyDir(key == Keyboard.KEY_UP and "up" or "down")
        return true
    end
    return false
end

function ZeD_MMLoad:close() self:back() end

-- the mouse wheel scrolls the list while the pointer is over it
function ZeD_MMLoad:wheel(del)
    local l = self._list
    if not l then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < l.x or mx > l.x + l.w or my < l.y or my > l.y + l.h then return false end
    self.scroll = self.scroll + del * ZeD.T.px(ROW_H)
    return true
end

-- ============================================================================
-- NEW GAME: a 1993 icon view
-- ============================================================================
ZeD_MMNewGame = ZeD_MMWindow:derive("ZeD_MMNewGame")

function ZeD_MMNewGame:new()
    local o = ZeD_MMWindow.new(self, "newgame")
    o.noResetControl = true
    o.sel = 1
    o.challenges = false
    return o
end

-- vanilla's playstyles (NewGameScreen.defaultGameModeData), or its challenges
function ZeD_MMNewGame:items()
    if self.challenges then
        if not self._challengeItems then
            local t = {}
            local list = {}
            for _, c in ipairs(LastStandChallenge or {}) do list[#list + 1] = c end
            table.sort(list, function(a, b) return tostring(a.name) < tostring(b.name) end)
            for _, info in ipairs(list) do
                t[#t + 1] = { mode = info.name, title = info.name, desc = info.description or "", thumb = info.image, internal = info.name, challenge = info }
            end
            self._challengeItems = t
        end
        return self._challengeItems
    end
    return NewGameScreen.defaultGameModeData or {}
end

function ZeD_MMNewGame:onShow()
    self.confirm = false
    self.challenges = false
    self.sel = 1
    self.focusId = "icon:1"
end

function ZeD_MMNewGame:isChallengesItem(d)
    return d and GameMode and GameMode.CHALLENGES and d.mode == GameMode.CHALLENGES:toString() and not self.challenges
end

-- NEXT: vanilla's NewGameScreen:clickPlay with this choice (map / spawn, sandbox
-- options, character creation follow as vanilla's screens)
function ZeD_MMNewGame:next()
    local items = self:items()
    local d = items[self.sel]
    if not d then return end
    MM.clickSound()
    if self:isChallengesItem(d) then
        self.challenges = true
        self._challengeItems = nil
        self.sel = 1
        self.focusId = "icon:1"
        return
    end
    local m = ms()
    local ng = m and m.soloScreen
    if not ng then return end
    ng.inChallengesView = self.challenges
    ng.selectedItem = { data = d }
    MM.toVanilla()
    NewGameScreen.clickPlay(ng)
end

function ZeD_MMNewGame:back()
    MM.clickSound()
    if self.challenges then
        self.challenges = false
        local items = self:items()
        for i, d in ipairs(items) do if self:isChallengesItem(d) then self.sel = i end end
        self.focusId = "icon:" .. self.sel
        return
    end
    MainScreen.resetLuaIfNeeded()   -- vanilla: mods chosen for a new game may need a Lua reset
    MM.showView("main")
end

-- vanilla's CHOOSE MODS for a new game; the mod list's return lands back here
function ZeD_MMNewGame:chooseMods()
    if not ModSelector or not ModSelector.instance then return end
    local jd = JoypadState.getMainMenuJoypad()
    ModSelector.instance.model.loadGameFolder = nil
    ModSelector.instance.model.isServerSettingsMods = false
    ModSelector.instance:setNewGame()
    ModSelector.instance:setVisible(true, jd)
    ModSelector.instance:reloadMods()
    ModSelector.showNagPanel()
    ModSelector.instance.returnToUI = NewGameScreen.instance
end

function ZeD_MMNewGame:clickIcon(i)
    local t = MM.now()
    if self.sel == i and self._lastClick and t - self._lastClick < 450 then
        self._lastClick = nil
        self:next()
        return
    end
    self._lastClick = t
    if self.sel ~= i then MM.clickSound() end
    self.sel = i
    self.focusId = "icon:" .. i
end

function ZeD_MMNewGame:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local items = self:items()
    local L = MM.layout()
    local pad, gap = T.px(U.STACK_PAD), T.px(U.STACK_GAP)
    local tb = T.titleBarH
    local stripH = MM.bandH()
    -- measure: the icon grid, then the description box
    local m = math.min(T.px(MARGIN), math.floor(L.tw / 40))
    local w = L.tw - m * 2
    local gridW = w - pad * 2
    local cols = ICON_COLS
    local cellW = math.floor((gridW - T.px(12)) / cols)
    local iconW = math.min(T.px(ICON_W), cellW - T.px(12))
    local iconH = math.floor(iconW * ICON_H / ICON_W)
    -- the icon row is as tall as its tallest picture (challenges are wide screenshots)
    local tallest = 0
    for _, it in ipairs(items) do
        local tex = it.thumb and getTexture(it.thumb) or nil
        if tex and tex:getWidth() > 0 then
            tallest = math.max(tallest, math.min(iconH, math.floor(iconW * tex:getHeight() / tex:getWidth())))
        end
    end
    if tallest > 0 then iconH = tallest end
    local f2 = T.fontF2
    local labelH = MM.fontH(f2) + T.px(2)
    local cellH = T.px(8) + iconH + T.px(8) + labelH + T.px(10)
    local rows = math.max(1, math.ceil(#items / cols))
    local gridH = T.px(16) + rows * cellH + T.px(12)
    local d = items[self.sel] or items[1]
    local descW = gridW - T.px(32)
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local bigH = math.floor(ZeD.Text.height(hf, z))
    local descLines = ZeD.Atoms.wrapText(plain(d and getText(d.desc) or ""), f2, descW)
    local lineH = MM.fontH(f2) + T.px(4)
    local descH = T.px(14) * 2 + bigH + T.px(4) + #descLines * lineH
    local h = tb + pad + gridH + gap + descH + pad + stripH + self:footerHeight()
    local maxH = L.th - T.px(U.BAR_H) - T.px(TOP_GAP) * 2
    if h > maxH then h = maxH end
    placeOnTube(self, h)
    self.title = ZeD.tr(self.challenges and "UI_ZeD_NewGame_TitleChallenges" or "UI_ZeD_NewGame_Title")
    self.titleStats = {}
    ZeD_Window.prerender(self)

    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gx, gy = pad, tb + pad
    insetBox(self, gx, gy, gridW, gridH)
    local gp = MM.gamepad()
    for i, it in ipairs(items) do
        local r, c = math.floor((i - 1) / cols), (i - 1) % cols
        local cx = gx + T.px(6) + c * cellW
        local cy = gy + T.px(16) + r * cellH
        if cy + cellH <= gy + gridH then
            local isSel = (i == self.sel)
            local fid = "icon:" .. i
            -- the chosen cell: the accent wash; the pointer's: T.hover; the controller's: its mark
            local onFocus = MM.rowLook(self, cx, cy, cellW, cellH, isSel, (not gp) and MM.ctx.hot == "newgame:" .. fid, gp and self.focusId == fid)
            local tex = it.thumb and getTexture(it.thumb) or nil
            local ix, iy = cx + math.floor((cellW - iconW) / 2), cy + T.px(8)
            if tex then
                -- a wide picture (a challenge's screenshot) sits on its label, not mid-box
                local tw0, th0 = tex:getWidth(), tex:getHeight()
                local dh = iconH
                if tw0 > 0 and th0 > 0 and tw0 / th0 > iconW / iconH then dh = math.floor(iconW * th0 / tw0) end
                self:drawTextureScaledAspect(tex, ix, iy + iconH - dh, iconW, dh, 1, 1, 1, 1)
            end
            local title = it.challenge and (getTextOrNull(it.title) or it.title) or getText(it.title)
            title = ZeD.Atoms.truncateText(title, f2, cellW - T.px(6))
            local tw = MM.textW(f2, title)
            local lx, ly = cx + math.floor((cellW - tw) / 2), iy + iconH + T.px(8)
            local tc = onFocus and T.textOnFocus or T.text
            self:drawText(title, lx, ly, tc.r, tc.g, tc.b, tc.a or 1, f2)
            self._specs[#self._specs + 1] = { id = fid, listRow = true, row = r + 1, col = c + 1, fn = function() self:next() end, index = i,
                                              x = cx, y = cy, w = cellW, h = cellH }
            self._hits[#self._hits + 1] = { id = "newgame:" .. fid, x = ax + cx, y = ay + cy, w = cellW, h = cellH, fn = function() self:clickIcon(i) end }
            if MM.ctx.hot == "newgame:" .. fid and not gp then ZeD.Help.set(self, ZeD.tr("UI_ZeD_MMHelp_GameIcon")) end
        end
    end

    -- the description: the mode's name and vanilla's words
    local dy = gy + gridH + gap
    local dh = math.max(T.px(40), self.height - self:footerHeight() - stripH - pad - dy)
    insetBox(self, gx, dy, gridW, dh)
    if d then
        local tc = T.textHead
        local name = d.challenge and (getTextOrNull(d.title) or d.title) or getText(d.title)
        ZeD.Text.draw(self, hf, name, gx + T.px(16), dy + T.px(14), z, tc.r, tc.g, tc.b, tc.a or 1, "l")
        local ty = dy + T.px(14) + bigH + T.px(4)
        local c = T.text
        for _, l in ipairs(descLines) do
            if ty + MM.fontH(f2) > dy + dh - T.px(6) then break end
            self:drawText(l, gx + T.px(16), ty, c.r, c.g, c.b, c.a or 1, f2)
            ty = ty + lineH
        end
    end

    -- the band at the foot
    local stripY = self.height - self:footerHeight() - stripH
    stripSpecs(self, stripY, self.width, 1000,
        { { "back", getText("UI_btn_back"), function() self:back() end } },
        { { "mods", getText("UI_NewGame_ChooseMods"), function() self:chooseMods() end },
          { "next", getText("UI_btn_next"), function() self:next() end, "primary", d == nil } })
end

function ZeD_MMNewGame:render()
    drawStripAndButtons(self)
    ZeD_Window.render(self)
end

-- the controller's focus picks the icon
function ZeD_MMNewGame:joyDir(dir)
    ZeD_MMWindow.joyDir(self, dir)
    for _, b in ipairs(self._specs) do
        if b.id == self.focusId and b.index then self.sel = b.index end
    end
end
function ZeD_MMNewGame:joyB() self:back() end
function ZeD_MMNewGame:joyY() self:chooseMods() end

function ZeD_MMNewGame:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local f = self.focusId or ""
    if f:sub(1, 5) == "icon:" then
        return { { glyph = "A", label = ZeD.btnCase(getText("UI_btn_next")) }, { glyph = "Y", label = ZeD.tr("UI_ZeD_NewGame_PromptChooseMods") }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } }
    end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } }
end

function ZeD_MMNewGame:keyEscape() self:back(); return true end
function ZeD_MMNewGame:keyOther(key)
    if key == Keyboard.KEY_RETURN then self:next(); return true end
    local items = self:items()
    if key == Keyboard.KEY_LEFT and self.sel > 1 then self.sel = self.sel - 1; self.focusId = "icon:" .. self.sel; return true end
    if key == Keyboard.KEY_RIGHT and self.sel < #items then self.sel = self.sel + 1; self.focusId = "icon:" .. self.sel; return true end
    return false
end

function ZeD_MMNewGame:close() self:back() end

-- ============================================================================
-- THE MOUSE WHEEL: whichever panel the engine hands it to, the view's window gets it
-- ============================================================================
function MM.wheel(del)
    if MM.view ~= "load" or not MM.root then return false end
    return MM.root.loadWin:wheel(del)
end
function ZeD_MMGlass:onMouseWheel(del) return MM.wheel(del) end
function ZeD_MMLoad:onMouseWheel(del) return MM.wheel(del) end
function ZeD_MMDesk:onMouseWheel(del) return MM.wheel(del) end

-- shared with ZeD_MainMenuMods.lua / ZeD_MainMenuOptions.lua
MM.ui = { insetBox = insetBox, newEntry = newEntry, styleEntry = styleEntry, placeOnTube = placeOnTube,
          stripSpecs = stripSpecs, drawStripAndButtons = drawStripAndButtons, plain = plain }
