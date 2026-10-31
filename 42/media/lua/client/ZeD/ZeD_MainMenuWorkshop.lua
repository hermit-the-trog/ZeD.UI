-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuWorkshop.lua
-- ============================================================================
-- UPLOADING YOUR MODS (HOOK_MAP row 26; director, Oct 16 2026: "make it easier
-- to upload mods to the workshop"; mockup zed_mod_manager_v1, "boogie!")
--
-- Vanilla's eight-page wizard (WorkshopSubmitScreen) as one ZeD window on the
-- monitor, on the game's own SteamWorkshopItem: your folders in
-- Zomboid/Workshop on the left; on the right everything Steam needs, each
-- checked before you press Upload: title, who can see it, tags, the preview
-- picture, the description (written in the description editor,
-- ZeD_MainMenuDescEdit), the change note, what goes up (vanilla's
-- validateContents) and the item's Workshop number. SAVE writes the folder's
-- workshop.txt (vanilla's writeWorkshopTxt); Upload asks in the band, then
-- creates the item when it is new (create) and sends it (submitUpdate) with
-- the progress in the band. Steam's answers come as vanilla's events.
-- Vanilla's workshopSubmit:setVisible(true) is redirected here.
-- The folder picked last, and each folder's change note until it goes up, are
-- kept in Zomboid/Lua/ZeD_workshop.txt (workshop.txt has no change note, so
-- vanilla's is lost when the game closes; director, Oct 24 2026: "set it up so
-- I can just press upload").
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_WorkshopText"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local BB = ZeD.BB

-- design units
local LIST_SHARE, ROW_H, LABEL_W, PAD, THUMB = 0.32, 44, 128, 12, 96

-- vanilla's visibility numbers (setVisibilityInteger), in the order the screen offers them
-- (translation keys: the button names, the "Seen by ..." line under them, and the upload question)
local VIS = { { 0, "UI_WorkshopSubmit_VisibilityPublic" }, { 1, "UI_WorkshopSubmit_VisibilityFriendsOnly" }, { 3, "UI_WorkshopSubmit_VisibilityUnlisted" }, { 2, "UI_WorkshopSubmit_VisibilityPrivate" } }
local VIS_SEEN = { [0] = "UI_ZeD_Workshop_SeenEveryone", [1] = "UI_ZeD_Workshop_SeenFriends", [2] = "UI_ZeD_Workshop_SeenOnlyYou", [3] = "UI_ZeD_Workshop_SeenLink" }
local VIS_ASK = { [0] = "UI_ZeD_Workshop_AskEveryone", [1] = "UI_ZeD_Workshop_AskFriends", [2] = "UI_ZeD_Workshop_AskOnlyYou", [3] = "UI_ZeD_Workshop_AskLink" }

local function jlist(l)
    local t = {}
    if l then for i = 0, l:size() - 1 do t[#t + 1] = l:get(i) end end
    return t
end

-- the change note: a box of several lines, as vanilla's (Page6, 512 lines); it grows with its
-- text from NOTE_MIN to NOTE_MAX lines, then keeps the cursor in view
local NOTE_LINES, NOTE_MIN, NOTE_MAX = 512, 3, 8

-- ZeD_workshop.txt: "picked=<folder>", then for each folder "note <folder>" and the note's
-- lines, each after a "|" (a note line may start with anything, BBCode brackets included)
local KEEP_FILE = "ZeD_workshop.txt"
local Keep = { picked = nil, notes = {} }

local function keepLoad()
    Keep.picked, Keep.notes = nil, {}
    local r = getFileReader(KEEP_FILE, false)
    if not r then return end
    local lines, cur = {}, nil
    local line = r:readLine()
    while line do
        local body = line:match("^|(.*)$")
        if body then
            if cur then cur[#cur + 1] = body end
        elseif line:sub(1, 7) == "picked=" then Keep.picked = line:sub(8); cur = nil
        elseif line:sub(1, 5) == "note " then cur = {}; lines[line:sub(6)] = cur end
        line = r:readLine()
    end
    r:close()
    for name, ls in pairs(lines) do Keep.notes[name] = table.concat(ls, "\n") end
end

local function keepSave()
    local w = getFileWriter(KEEP_FILE, true, false)
    if not w then return end
    w:write("ZeD-UI Workshop window: the folder picked last, and the change notes not uploaded yet\n")
    if Keep.picked then w:write("picked=" .. Keep.picked .. "\n") end
    local names = {}
    for n in pairs(Keep.notes) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do
        w:write("note " .. n .. "\n")
        local text = (Keep.notes[n]:gsub("\r", ""))
        for l in (text .. "\n"):gmatch("(.-)\n") do w:write("|" .. l .. "\n") end
    end
    w:close()
end

-- the item's change note as it stands (an empty one is dropped)
local function keepNote(it)
    local text = tostring(it:getChangeNote() or "")
    Keep.notes[tostring(it:getFolderName())] = (BB.trim(text) ~= "") and text or nil
end

-- ============================================================================
ZeD_MMWorkshop = ZeD_MMWindow:derive("ZeD_MMWorkshop")

function ZeD_MMWorkshop:new()
    local o = ZeD_MMWindow.new(self, "workshop")
    o.noResetControl = true
    o.items = {}
    o.sel = 1
    o.scroll, o.fscroll = 0, 0
    o.confirm = false       -- false | "upload" | "leave"
    o.busy = nil            -- nil | { stage = "create" | "send", t0 }
    o.note = nil
    return o
end

function ZeD_MMWorkshop:createChildren()
    ZeD_Window.createChildren(self)
    self.titleE = UI.newEntry(self)
    self.titleE.onTextChange = function() self:formChanged() end
    self.noteE = UI.newEntry(self)
    self.noteE:setMultipleLine(true)
    self.noteE:setMaxLines(NOTE_LINES)
    self.noteE.onTextChange = function() self:formChanged() end
end

function ZeD_MMWorkshop:onShow()
    self.confirm = false
    if self._fromEditor then   -- (back from the description editor: the form stays as it was; only the folder is read again)
        self._fromEditor = nil; self.focusId = nil; self:checkContents(); return
    end
    self.busy = nil
    self.note = nil
    self.scroll, self.fscroll = 0, 0
    self.focusId = nil
    self.items = {}
    pcall(function() self.items = jlist(getSteamWorkshopStagedItems()) end)
    self.unsaved = {}
    keepLoad()
    if not self._pickedLast then   -- (the first time this session: the folder picked last)
        self._pickedLast = true
        for i, x in ipairs(self.items) do if tostring(x:getFolderName()) == Keep.picked then self.sel = i end end
    end
    self.sel = math.max(1, math.min(self.sel or 1, #self.items))
    self:load()
    MM.wsEditor = nil
end

function ZeD_MMWorkshop:item() return self.items[self.sel] end

-- The room for our description: the game adds its own lines when it sends it
-- (SteamWorkshopItem.getSubmitDescription: a blank line, "Workshop ID: <id>", a "Mod ID:"
-- line per mod, a "Map Folder:" line per map), and Steam refuses the whole update past 8,000
-- (Oct 25 2026: 7,976 + 58 went over, and Steam answered 8, an invalid field).
function ZeD_MMWorkshop:descRoom()
    local it = self:item()
    local extra = 0
    if it then
        local okS, sub = pcall(function() return it:getSubmitDescription() end)
        local okD, own = pcall(function() return it:getDescription() end)
        if okS and okD and sub and own then
            extra = #tostring(sub) - #tostring(own)
            if tostring(own) == "" then extra = extra + 2 end      -- (its blank line comes only after a description)
            local okI, id = pcall(function() return it:getID() end)
            if not (okI and id) then extra = extra + 6 end         -- (a new item: "null" now, ten digits once Steam gives it an id)
        end
    end
    return BB.LIMIT - extra
end

-- the picked folder's fields into the form
function ZeD_MMWorkshop:load()
    local it = self:item()
    self._loading = true
    self.titleE:setText(it and tostring(it:getTitle() or "") or "")
    local note = it and tostring(it:getChangeNote() or "") or ""
    if note == "" and it then note = Keep.notes[tostring(it:getFolderName())] or "" end
    self.noteE:setText(note)
    self._loading = false
    self.vis = it and it:getVisibilityInteger() or 0
    self.tags = {}
    if it then for _, t in ipairs(jlist(it:getTags())) do self.tags[tostring(t)] = true end end
    self.desc = it and tostring(it:getDescription() or "") or ""
    self:checkContents()
end

-- The preview picture's texture, looked up again with each folder check instead of every frame.
-- The game remembers a texture name that was not there, under that exact spelling, for the rest of
-- the session (QA, Oct 23 2026: a preview.png added while the window was open stayed "no picture"),
-- so a picture that is still missing is asked for under a fresh spelling of the same path
-- (a "\.\" in it), a new name each time, up to PV_TRIES.
local PV_TRIES = 120
function ZeD_MMWorkshop:checkPreview(it)
    self._pvTex = nil
    local path = it and tostring(it:getPreviewImage() or "") or ""
    if path == "" then return end
    local tex = getTexture(path)
    if not tex and self._pvAlias and self._pvFor == path then tex = getTexture(self._pvAlias) end   -- (the spelling that found it)
    if not tex and (self._pvN or 0) < PV_TRIES then
        self._pvN = (self._pvN or 0) + 1
        local dir, file = path:match("^(.*[/\\])([^/\\]*)$")
        if dir then
            local alias = dir .. string.rep(".\\", self._pvN) .. file
            tex = getTexture(alias)
            if tex then self._pvAlias, self._pvFor = alias, path end
        end
    end
    self._pvTex = tex
end

-- What goes up, read from the folder on disk (vanilla's validateContents). Touches nothing in the
-- form: it runs on a pick and again whenever the folder may have changed (Oct 23 2026: a Contents
-- folder made while the window was open kept reading "no Contents folder" until the item was
-- picked again, and picking again reloads the form from the item and drops unsaved edits).
function ZeD_MMWorkshop:checkContents()
    local it = self:item()
    self:checkPreview(it)
    self.contents = nil
    local t0 = MM.now()
    self._checkAt = t0
    if not it then return end
    local ok, err = pcall(function() return it:validateContents() end)
    self._checkCost = MM.now() - t0   -- (a big Contents folder takes longer to walk: the timer backs off)
    -- (Oct 22 2026: was `ok and (err or false) or tostring(err)`, which turns a clean folder's
    -- false into the text "nil": every valid folder read "nil" under WHAT GOES UP and could not upload)
    if ok then self.contents = err or false else self.contents = tostring(err) end
    if self.contents and ok then   -- vanilla's own words for the code (UI_WorkshopError_*)
        local extra = ""
        pcall(function() extra = tostring(it:getExtendedErrorInfo(err) or "") end)
        local words = getTextOrNull("UI_WorkshopError_" .. tostring(err), extra)
        if words then self.contents = (words:gsub("\\n", " ")) end
    end
end

-- every couple of seconds while the window shows (it only updates while visible), and not
-- during an upload: the folder is read, nothing else
local RECHECK_MS = 2000
function ZeD_MMWorkshop:update()
    ZeD_MMWindow.update(self)
    if self.busy or not self:isVisible() then return end
    if MM.now() - (self._checkAt or 0) >= math.max(RECHECK_MS, (self._checkCost or 0) * 100) then self:checkContents() end
end

-- the form onto the item (in memory; SAVE writes it)
function ZeD_MMWorkshop:apply()
    local it = self:item()
    if not it then return end
    it:setTitle(self.titleE:getText())
    it:setChangeNote(self.noteE:getText())
    it:setVisibilityInteger(self.vis)
    it:setDescription(self.desc)
    local l = ArrayList.new()
    for _, t in ipairs(jlist(SteamWorkshopItem.getAllowedTags())) do if self.tags[tostring(t)] then l:add(t) end end
    it:setTags(l)
end

function ZeD_MMWorkshop:formChanged()
    if self._loading then return end
    local it = self:item()
    if it then self.unsaved[it:getFolderName()] = true end
end

function ZeD_MMWorkshop:isUnsaved()
    local it = self:item()
    return it and self.unsaved[it:getFolderName()] or false
end

function ZeD_MMWorkshop:say(text, bad) self.note = { text = text, bad = bad, untilMs = MM.now() + 8000 } end

-- a folder's workshop.txt, and its change note into ZeD_workshop.txt (keepSave writes that file)
local function writeItem(it)
    local ok = false
    pcall(function() ok = it:writeWorkshopTxt() end)
    keepNote(it)
    return ok
end

function ZeD_MMWorkshop:save()
    local it = self:item()
    if not it then return end
    self:apply()
    local ok = writeItem(it)
    keepSave()
    if ok then
        self.unsaved[it:getFolderName()] = nil
        self:say(ZeD.tr("UI_ZeD_Workshop_Saved", it:getFolderName()))
    else self:say(ZeD.tr("UI_ZeD_Workshop_SaveFailed"), true) end
    self:checkContents()
    MM.clickSound()
end

-- the folder read again right before the question and before the send; a block is shown as a
-- note and nothing goes up (the form is not touched)
function ZeD_MMWorkshop:freshOk()
    self:checkContents()
    local block = self:blocker()
    if block then self:say(block, true); return false end
    return true
end

function ZeD_MMWorkshop:pick(i)
    if i == self.sel or self.busy then return end
    self:apply()                      -- (the edits stay with their folder until saved or the screen closes)
    self.sel = i
    self.fscroll = 0
    self:load()
    local it = self:item()
    if it then Keep.picked = tostring(it:getFolderName()); keepSave() end
    MM.hoverSound()
end

-- what keeps it from going up (nil = nothing)
function ZeD_MMWorkshop:blocker()
    if BB.trim(self.titleE:getText()) == "" then return ZeD.tr("UI_ZeD_Workshop_NeedTitle") end
    if BB.trim(self.desc) == "" then return ZeD.tr("UI_ZeD_Workshop_NeedDescription") end
    local room = self:descRoom()
    if #self.desc > room then return ZeD.tr("UI_ZeD_Workshop_DescriptionTooLong", room) end
    if self.contents then return tostring(self.contents) end
    return nil
end

function ZeD_MMWorkshop:back()
    if self.busy then return end
    if self.confirm then self:setConfirm(false); return end
    local any = false
    for _ in pairs(self.unsaved) do any = true end
    if any then self:setConfirm("leave"); return end
    MM.clickSound()
    MM.showView("main")
end

function ZeD_MMWorkshop:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    self.focusId = mode and "confirm:yes" or nil
    MM.clickSound()
end

-- ----------------------------------------------------------------------------
-- UPLOADING (vanilla's Page7, without the log)
-- ----------------------------------------------------------------------------
local function vanillaPage7(it)
    -- vanilla's own handlers answer Steam's events too and expect its page to hold the item
    local ws = WorkshopSubmitScreen and WorkshopSubmitScreen.instance
    if ws and ws.page7 then ws.page7.item = it end
end

function ZeD_MMWorkshop:upload()
    local it = self:item()
    if not it or self.busy then return end
    self.confirm = false
    if not self:freshOk() then return end
    self:apply()
    writeItem(it)                     -- (the note stays kept until Steam says it went up)
    keepSave()
    self.unsaved[it:getFolderName()] = nil
    vanillaPage7(it)
    MM.clickSound()
    if it:getID() then self:send()
    else
        local ok = false
        pcall(function() ok = it:create() end)
        if ok then self.busy = { stage = "create", t0 = MM.now() }
        else self:say(ZeD.tr("UI_ZeD_Workshop_CreateFailed"), true) end
    end
end

function ZeD_MMWorkshop:send()
    local it = self:item()
    local ok = false
    pcall(function() ok = it:submitUpdate() end)
    if ok then self.busy = { stage = "send", t0 = MM.now() }
    else self.busy = nil; self:say(ZeD.tr("UI_ZeD_Workshop_SendFailed"), true) end
end

function ZeD_MMWorkshop:onCreated(itemID, legal)
    local it = self:item()
    if not (self.busy and it) then return end
    it:setID(tostring(itemID))
    pcall(function() it:writeWorkshopTxt() end)
    self.legal = legal
    self:send()
end
function ZeD_MMWorkshop:onNotCreated(result)
    if not self.busy then return end
    self.busy = nil
    self:say(ZeD.tr("UI_ZeD_Workshop_NotCreated", tostring(result)), true)
end
function ZeD_MMWorkshop:onUpdated(legal)
    if not self.busy then return end
    self.busy = nil
    local it = self:item()
    if it then   -- (the note went up with this update: the next one starts empty)
        pcall(function() it:setChangeNote("") end)
        Keep.notes[tostring(it:getFolderName())] = nil
        keepSave()
        self._loading = true; self.noteE:setText(""); self._loading = false
    end
    local msg = ZeD.tr((legal or self.legal) and "UI_ZeD_Workshop_UploadedLegal" or "UI_ZeD_Workshop_Uploaded", tostring(it and it:getID() or ""))
    self:say(msg)
    self.legal = nil
end
function ZeD_MMWorkshop:onNotUpdated(result)
    if not self.busy then return end
    self.busy = nil
    self:say(ZeD.tr("UI_ZeD_Workshop_NotUpdated", tostring(result)), true)
end

-- (vanilla registers these events only with Steam on; the window listens alongside)
if getSteamModeActive and getSteamModeActive() and Events.OnSteamWorkshopItemCreated then
    local function win() return MM.root and MM.root.workshopWin end
    Events.OnSteamWorkshopItemCreated.Add(function(id, legal) local w = win(); if w then w:onCreated(id, legal) end end)
    Events.OnSteamWorkshopItemNotCreated.Add(function(r) local w = win(); if w then w:onNotCreated(r) end end)
    Events.OnSteamWorkshopItemUpdated.Add(function(legal) local w = win(); if w then w:onUpdated(legal) end end)
    Events.OnSteamWorkshopItemNotUpdated.Add(function(r) local w = win(); if w then w:onNotUpdated(r) end end)
end

-- the description editor hands its text back here
function ZeD_MMWorkshop:setDescription(text)
    self.desc = text
    local it = self:item()
    if it then it:setDescription(text); self.unsaved[it:getFolderName()] = true end
end

-- ----------------------------------------------------------------------------
-- DRAWING
-- ----------------------------------------------------------------------------
function ZeD_MMWorkshop:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    self.title = ZeD.tr("UI_ZeD_Workshop_Title")
    self.titleStats = {}
    if not (getSteamModeActive and getSteamModeActive()) then self.titleStats = { { text = ZeD.tr("UI_ZeD_Workshop_NoSteam"), color = T.danger } } end
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local lw = math.floor((w - pad * 3) * LIST_SHARE)
    self:drawFolders(pad, bodyY, lw, bodyH)
    self:drawForm(pad * 2 + lw, bodyY, w - pad * 3 - lw, bodyH)
    self:buildStrip(stripY, stripH, w)
end

function ZeD_MMWorkshop:render()
    UI.drawStripAndButtons(self)
    if self.busy then self:drawProgress() end
    ZeD_Window.render(self)
end

-- the footer line when nothing is under the pointer
function ZeD_MMWorkshop:getStatusLine()
    local n = #self.items
    if n == 0 then return nil end
    return ZeD.tr(n == 1 and "UI_ZeD_Workshop_StatusOne" or "UI_ZeD_Workshop_StatusMany", n)
end

-- the folders in Zomboid/Workshop
function ZeD_MMWorkshop:drawFolders(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    UI.insetBox(self, x, y, w, h)
    local la, dim = T.accent, T.textDim
    self:drawText(ZeD.tr("UI_ZeD_Workshop_YourMods"), x + T.px(10), y + T.px(8), la.r, la.g, la.b, la.a or 1, f1)
    local vy = y + T.px(8) + MM.fontH(f1) + T.px(8)
    local rh = T.px(ROW_H)
    local gp = MM.gamepad()
    if #self.items == 0 then
        ZeD.Molecules.drawEmptyLine(self, x + T.px(10), vy, w - T.px(20), ZeD.tr("UI_ZeD_Workshop_NoFolders"))
    end
    for i, it in ipairs(self.items) do
        local ry = vy + (i - 1) * rh
        if ry + rh > y + h then break end
        local rid = "frow:" .. i
        self._specs[#self._specs + 1] = { id = rid, listRow = true, row = i, col = 1, x = x + T.px(1), y = ry, w = w - T.px(2), h = rh,
                                          chosen = (i == self.sel), fn = function() self:pick(i) end }
        local onFocus = MM.rowLook(self, x + T.px(1), ry, w - 2 * T.px(1), rh, i == self.sel, (not gp) and MM.ctx.hot == "ws:row:" .. i, gp and self.focusId == rid)
        if (not gp) and MM.ctx.hot == "ws:row:" .. i then ZeD.Help.set(self, ZeD.tr("UI_ZeD_MMHelp_WsFolder")) end
        self:drawRect(x + T.px(1), ry + rh - T.px(1), w - T.px(2), T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
        local title = (i == self.sel) and BB.trim(self.titleE:getText()) or BB.trim(tostring(it:getTitle() or ""))
        if title == "" then title = tostring(it:getFolderName()) end
        local tx = x + T.px(10)
        local tc = onFocus and T.textOnFocus or T.textHead
        local dm = onFocus and T.textOnFocus or dim
        self:drawText(ZeD.Atoms.truncateText(title, f2, w - T.px(20)), tx, ry + T.px(6), tc.r, tc.g, tc.b, tc.a or 1, f2)
        local id = it:getID()
        local sub = id and ZeD.tr("UI_ZeD_Workshop_OnWorkshop", tostring(id)) or ZeD.tr("UI_ZeD_Workshop_NotOnWorkshop")
        if self.unsaved[it:getFolderName()] then sub = sub .. MM.DOT .. ZeD.tr("UI_ZeD_Workshop_NotSaved") end
        self:drawText(ZeD.Atoms.truncateText(sub, f3, w - T.px(20)), tx, ry + rh - T.px(6) - MM.fontH(f3), dm.r, dm.g, dm.b, dm.a or 1, f3)
        self._hits[#self._hits + 1] = { id = "ws:row:" .. i, x = ax + x, y = ay + ry, w = w, h = rh, fn = function() self:pick(i); self.focusId = rid end }
    end
end

-- wrapped text; returns the y under it
function ZeD_MMWorkshop:paneText(text, x, cy, w, font, color)
    local T = ZeD.T
    for _, l in ipairs(ZeD.Atoms.wrapText(text, font, w)) do
        self:drawText(l, x, cy, color.r, color.g, color.b, color.a or 1, font)
        cy = cy + MM.fontH(font) + T.px(2)
    end
    return cy
end

-- a spec button inside the form (clipped with it); returns its right edge. extra.radio / extra.check
-- make it a radio button or a checkbox with its words after it (one of a few / on or off)
function ZeD_MMWorkshop:formBtn(id, text, fn, x, y, variant, row, col, disabled, extra)
    local T = ZeD.T
    local keep = extra and extra.keepCase
    local label = keep and text or ZeD.btnCase(text)
    local bw = math.max(T.px(60), MM.textW(T.fontF3, label) + T.sp.buttonPadX * 2)
    if extra and (extra.radio or extra.check) then
        bw = (extra.radio and ZeD.Atoms.radioSize() or T.checkboxSz) + T.px(14) + MM.textW(T.fontF3, label)
    end
    local b = { id = id, text = text, fn = fn, variant = variant or "default", row = row, col = col, disabled = disabled,
                x = x, y = y, w = bw, h = T.buttonH, clipTop = self._fv.y, clipBot = self._fv.y + self._fv.h }
    if extra then for k, v in pairs(extra) do b[k] = v end end
    self._specs[#self._specs + 1] = b
    return x + bw
end

-- an entry in the form: shown only while it is wholly in view (one line unless h is given)
function ZeD_MMWorkshop:formEntry(e, id, x, y, w, h)
    local T = ZeD.T
    local eh = h or T.px(24)
    local fv = self._fv
    local inView = y >= fv.y and y + eh <= fv.y + fv.h
    if e:isVisible() ~= inView then e:setVisible(inView) end
    if inView then
        UI.styleEntry(e, x, y, w, eh)
        if self.focusId == id and MM.gamepad() then ZeD.Focus.mark(self, x, y, w, eh, MM.focusOpts()) end
    end
    -- (the controller lands on the field as on a button: A types in it)
    self._specs[#self._specs + 1] = { id = id, listRow = true, x = x, y = y, w = w, h = eh, clipTop = fv.y, clipBot = fv.y + fv.h,
                                      fn = function() e:focus() end }
    return eh
end

function ZeD_MMWorkshop:drawForm(x, y, w, h)
    local T = ZeD.T
    local bs = T.borderS
    ZeD.Atoms.frame(self, x, y, w, h, bs)
    local pad = T.px(PAD)
    local ix, iw = x + pad, w - pad * 2
    local top = y
    -- the note band: what Save or Upload did
    if self.note and MM.now() < self.note.untilMs then
        local f2 = T.fontF2
        local lines = ZeD.Atoms.wrapText(self.note.text, f2, iw - T.px(14))
        local nh = #lines * (MM.fontH(f2) + T.px(2)) + T.px(12)
        ZeD.Surface.fill(self, x + T.px(1), y + T.px(1), w - 2 * T.px(1), nh, "surf2")
        ZeD.Atoms.drawDividerH(self, x, y + nh, w, true)
        local dsz = T.px(7)
        ZeD.Atoms.drawStatusDot(self, ix, y + T.px(6) + math.floor((MM.fontH(f2) - dsz) / 2), self.note.bad and T.danger or T.accent, dsz)
        self:paneText(self.note.text, ix + dsz + T.px(7), y + T.px(6), iw - T.px(14), f2, T.text)
        top = y + nh + T.px(1)
    end
    self._fv = { x = x, y = top, w = w, h = y + h - top }
    local it = self:item()
    if not it then
        self.titleE:setVisible(false); self.noteE:setVisible(false)
        return
    end
    self:setStencilRect(x + T.px(1), top + T.px(1), w - T.px(2), y + h - top - T.px(2))
    local cy = top + pad - self.fscroll
    cy = self:formTop(it, ix, iw, cy)
    cy = self:formBottom(it, ix, iw, cy)
    self:clearStencilRect()
    local contentH = cy + self.fscroll - top + pad
    self.fscroll = math.max(0, math.min(self.fscroll, math.max(0, contentH - (y + h - top))))
end

local function label(self, text, x, y, h)
    local T = ZeD.T
    local la = T.accent
    self:drawText(text, x, y + math.floor((h - MM.fontH(T.fontF1)) / 2), la.r, la.g, la.b, la.a or 1, T.fontF1)
end

-- title, who can see it, tags, the picture
function ZeD_MMWorkshop:formTop(it, ix, iw, cy)
    local T = ZeD.T
    local vx = ix + T.px(LABEL_W)
    local vw = ix + iw - vx
    local bh = T.buttonH
    local f2, f3, dim = T.fontF2, T.fontF3, T.textDim
    -- the title
    label(self, ZeD.textCase(ZeD.trBare("UI_WorkshopSubmit_ItemTitle")), ix, cy, T.px(24))
    cy = cy + self:formEntry(self.titleE, "f:title", vx, cy, vw) + T.px(10)
    -- who can see it: one of a few, radio buttons
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelWho"), ix, cy, bh)
    local bx = vx
    for i, v in ipairs(VIS) do
        bx = self:formBtn("vis:" .. v[1], ZeD.tr(v[2]), function() self.vis = v[1]; self:formChanged(); MM.clickSound() end, bx, cy,
            "default", 300, i, false, { radio = true, on = (self.vis == v[1]) }) + T.px(10)
    end
    cy = cy + bh + T.px(4)
    cy = self:paneText(ZeD.tr(VIS_SEEN[self.vis] or VIS_SEEN[0]), vx, cy, vw, f3, dim) + T.px(8)
    -- the tags: each on or off, checkboxes
    label(self, ZeD.textCase(ZeD.trBare("UI_WorkshopSubmit_ItemTags")), ix, cy, bh)
    bx = vx
    local tags = {}
    pcall(function() tags = jlist(SteamWorkshopItem.getAllowedTags()) end)
    local row = 310
    for i, t in ipairs(tags) do
        local name = tostring(t)
        local tw = T.checkboxSz + T.px(14) + MM.textW(T.fontF3, name)
        if bx + tw > vx + vw and bx > vx then bx = vx; cy = cy + bh + T.px(6); row = row + 1 end
        bx = self:formBtn("tag:" .. name, name, function() self.tags[name] = not self.tags[name] or nil; self:formChanged(); MM.clickSound() end,
            bx, cy, "default", row, i, false, { keepCase = true, check = true, on = self.tags[name] and true or false }) + T.px(10)
    end
    cy = cy + bh + T.px(12)
    -- PREVIEW PICTURE
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelPreview"), ix, cy, T.px(20))
    local path = tostring(it:getPreviewImage() or "")
    local tex = (path ~= "") and self._pvTex or nil   -- (looked up with each folder check)
    local tsz = T.px(THUMB)
    local bs = T.borderS
    if tex then self:drawTextureScaledAspect(tex, vx, cy, tsz, tsz, 1, 1, 1, 1) end
    ZeD.Atoms.frame(self, vx, cy, tsz, tsz, bs)
    local px = vx + tsz + T.px(10)
    local pw = ix + iw - px
    local name = path:match("([^/\\]+)$") or "preview.png"
    local yy = self:paneText(name, px, cy, pw, f2, T.text)
    -- (the game's own rule, checked again when it uploads: a 256 x 256 PNG of 1000 KB at most)
    local check, good
    if not tex then check, good = ZeD.tr("UI_ZeD_Workshop_NoPicture"), false
    else
        local tw2, th2 = tex:getWidthOrig(), tex:getHeightOrig()
        good = tw2 == 256 and th2 == 256
        check = good and ZeD.tr("UI_ZeD_Workshop_PictureOk")
            or ZeD.tr("UI_ZeD_Workshop_PictureWrongSize", tw2, th2)
    end
    local dsz = T.px(7)
    ZeD.Atoms.drawStatusDot(self, px, yy + T.px(2) + math.floor((MM.fontH(f3) - dsz) / 2), good and T.positive or T.danger, dsz)
    self:paneText(check, px + dsz + T.px(6), yy + T.px(2), pw - dsz - T.px(6), f3, dim)
    return cy + tsz + T.px(12)
end

-- description, change note, what goes up, the Workshop number
function ZeD_MMWorkshop:formBottom(it, ix, iw, cy)
    local T = ZeD.T
    local vx = ix + T.px(LABEL_W)
    local vw = ix + iw - vx
    local bh = T.buttonH
    local f2, f3, dim, txt = T.fontF2, T.fontF3, T.textDim, T.text
    -- the description
    label(self, ZeD.textCase(ZeD.trBare("UI_WorkshopSubmit_ItemDescription")), ix, cy, T.px(20))
    local plain = BB.plain(self.desc)
    if plain == "" then cy = self:paneText(ZeD.tr("UI_ZeD_Workshop_NoneYet"), vx, cy + T.px(2), vw, f2, dim)
    else
        local ls = ZeD.Atoms.wrapText(plain, f2, vw)
        for i = 1, math.min(3, #ls) do
            local l = ls[i]
            if i == 3 and #ls > 3 then l = ZeD.Atoms.truncateText(l .. " ...", f2, vw) end
            self:drawText(l, vx, cy + T.px(2), txt.r, txt.g, txt.b, txt.a or 1, f2)
            cy = cy + MM.fontH(f2) + T.px(2)
        end
    end
    local n, room = #self.desc, self:descRoom()
    -- the count: the words in the default dim, a square mark that is red when it is over
    local cdsz = T.px(6)
    ZeD.Atoms.drawStatusDot(self, vx, cy + T.px(2) + math.floor((MM.fontH(f3) - cdsz) / 2), (n > room) and T.danger or T.positive, cdsz)
    cy = self:paneText(ZeD.tr("UI_ZeD_DescEdit_Count", BB.count(n), BB.count(room)), vx + cdsz + T.px(6), cy + T.px(2), vw - cdsz - T.px(6), f3, dim) + T.px(6)
    local bx = self:formBtn("desc:edit", ZeD.tr("UI_WorkshopSubmit_EditDescription"), function() self:openEditor() end, vx, cy, "default", 400, 1) + T.px(6)
    self:formBtn("desc:copy", ZeD.tr("UI_ZeD_Workshop_CopyCodes"), function() Clipboard.setClipboard(self.desc); self:say(ZeD.tr("UI_ZeD_Workshop_CodesCopied")); MM.clickSound() end,
        bx, cy, "default", 400, 2, self.desc == "")
    cy = cy + bh + T.px(12)
    -- CHANGE NOTE
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelChangeNote"), ix, cy, T.px(24))
    cy = cy + self:formEntry(self.noteE, "f:note", vx, cy, vw, self:noteH(vw)) + T.px(4)
    cy = self:paneText(ZeD.tr(it:getID() and "UI_ZeD_Workshop_NoteHelpUpdate" or "UI_ZeD_Workshop_NoteHelpNew"), vx, cy, vw, f3, dim) + T.px(10)
    -- WHAT GOES UP
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelWhatGoesUp"), ix, cy, T.px(20))
    local dsz = T.px(7)
    local ok = not self.contents
    ZeD.Atoms.drawStatusDot(self, vx, cy + T.px(2) + math.floor((MM.fontH(f2) - dsz) / 2), ok and T.positive or T.danger, dsz)
    cy = self:paneText(ok and ZeD.tr("UI_ZeD_Workshop_ContentsOk") or tostring(self.contents), vx + dsz + T.px(7), cy + T.px(2), vw - dsz - T.px(7), f2, txt)
    cy = self:paneText(tostring(it:getContentFolder() or ""), vx + dsz + T.px(7), cy, vw - dsz - T.px(7), f3, dim) + T.px(10)
    -- WORKSHOP ITEM
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelItem"), ix, cy, bh)
    local id = it:getID()
    if id then
        local tw = MM.textW(f2, tostring(id))
        self:drawText(tostring(id), vx, cy + math.floor((bh - MM.fontH(f2)) / 2), txt.r, txt.g, txt.b, txt.a or 1, f2)
        self:formBtn("ws:open", ZeD.tr("UI_ZeD_Workshop_OpenInSteam"), function() ZeD.ModScan.openInSteam(id) end, vx + tw + T.px(12), cy, "default", 500, 1)
        cy = cy + bh
    else
        cy = self:paneText(ZeD.tr("UI_ZeD_Workshop_ItemNew"), vx, cy + T.px(3), vw, f2, txt)
    end
    return cy
end

-- the change note box's height: its lines as wrapped, plus one to type on (counted again only
-- when the text or the width changes)
function ZeD_MMWorkshop:noteH(w)
    local T = ZeD.T
    local text = self.noteE:getText() or ""
    local c = self._noteHC
    if not (c and c.text == text and c.w == w and c.px == T.px(100)) then
        local n = 0
        for l in (text:gsub("\r", "") .. "\n"):gmatch("(.-)\n") do n = n + math.max(1, #ZeD.Atoms.wrapText(l, T.fontF2, w - T.px(12))) end
        local lh = MM.fontH(T.fontF2) + T.px(2)
        c = { text = text, w = w, px = T.px(100), h = math.max(NOTE_MIN, math.min(NOTE_MAX, n + 1)) * lh + T.px(8) }
        self._noteHC = c
    end
    return c.h
end

function ZeD_MMWorkshop:openEditor()
    self:apply()
    MM.clickSound()
    MM.wsEditor = { text = self.desc, title = BB.trim(self.titleE:getText()), limit = self:descRoom(), done = function(text) self:setDescription(text) end }
    MM.showView("wsdesc")
end

function ZeD_MMWorkshop:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    local it = self:item()
    if self.busy then
        -- the upload's progress takes the band's left (drawProgress); Back waits
        UI.stripSpecs(self, stripY, w, row, { { "back", getText("UI_btn_back"), function() end, "default", true } }, {})
        return
    end
    if self.confirm == "upload" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Workshop_Upload"), function() self:upload() end, "primary" } },
            ZeD.tr(VIS_ASK[self.vis] or VIS_ASK[0], BB.trim(self.titleE:getText())))
    elseif self.confirm == "leave" then
        -- Cancel stays; Discard changes drops what was edited; Save keeps it
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:cancel", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:no", ZeD.tr("UI_ZeD_MMWord_DiscardChanges"), function()
                for _, x in ipairs(self.items) do pcall(function() x:readWorkshopTxt() end) end
                self.unsaved = {}; self.confirm = false; MM.clickSound(); MM.showView("main") end, "danger" },
            { "confirm:yes", getText("UI_btn_save"), function()
                self:apply()
                for _, x in ipairs(self.items) do if self.unsaved[x:getFolderName()] or x == self:item() then writeItem(x) end end
                keepSave()
                self.unsaved = {}; self.confirm = false; MM.clickSound(); MM.showView("main") end, "primary" } },
            ZeD.tr("UI_ZeD_Workshop_AskSave"))
    else
        -- (Oct 22 2026: was `it and self:blocker() or ...`, which read "Nothing to upload" whenever
        -- nothing blocked the folder, so Upload never lit)
        local block
        if it then block = self:blocker() else block = ZeD.tr("UI_ZeD_Workshop_NothingToUpload") end
        local rights = {
            { "save", getText("UI_btn_save"), function() self:save() end, "default", not self:isUnsaved() },
            { "upload", ZeD.tr((it and it:getID()) and "UI_ZeD_Workshop_UploadUpdate" or "UI_ZeD_Workshop_Upload"), function() if self:freshOk() then self:setConfirm("upload") end end, "primary", block ~= nil },
        }
        -- what keeps Upload from going is the band's own line (a square mark, then the reason)
        UI.stripSpecs(self, stripY, w, row, { { "back", getText("UI_btn_back"), function() self:back() end } }, rights, (block and it) and block or nil, true, T.warning)
    end
end

-- the upload's progress where the buttons were
function ZeD_MMWorkshop:drawProgress()
    local T = ZeD.T
    local it = self:item()
    local f2, txt = T.fontF2, T.text
    local y, h = self._bandY or 0, self._bandH or MM.bandH()
    -- the band's left, up to the Back button waiting at its right
    local x0 = T.px(8)
    local right = self.width - T.px(8)
    for _, b in ipairs(self._specs) do if b.band then right = math.min(right, b.x - T.px(8)) end end
    local text, frac = ZeD.tr("UI_ZeD_Workshop_Asking"), nil
    if self.busy.stage == "send" then
        local pr = { processed = 0, total = 0 }
        pcall(function() it:getUpdateProgress(pr) end)
        local total = tonumber(pr.total) or 0
        local done = tonumber(pr.processed) or 0
        if total > 0 then
            frac = math.max(0, math.min(1, done / total))
            text = ZeD.tr("UI_ZeD_Workshop_Uploading", math.floor(frac * 100) .. "%", ZeD.ModScan.size(done), ZeD.ModScan.size(total))
        else text = ZeD.tr("UI_ZeD_Workshop_UploadingNoTotal") end
    end
    self:drawText(text, x0, y + math.floor((h - MM.fontH(f2)) / 2), txt.r, txt.g, txt.b, txt.a or 1, f2)
    local bx = x0 + MM.textW(f2, text) + T.px(16)
    local bw = right - bx
    if bw > T.px(60) then
        -- the System 7 bar: a framed strip, a flat solid fill; with no total yet an empty strip with a block sweeping across it
        local bh = T.fillBarH
        local by = y + math.floor((h - bh) / 2)
        ZeD.Atoms.drawSmoothBar(self, bx, by, bw, frac or 0, false, nil, bh)   -- (an upload's progress: smooth)
        if not frac then
            local k = ((MM.now() - self.busy.t0) % 1600) / 1600
            local ac, line = T.accent, T.line(T.borderW)
            local chunk = T.px(40)
            self:drawRect(bx + line + math.floor((bw - 2 * line - chunk) * k), by + line, chunk, bh - 2 * line, 1, ac.r, ac.g, ac.b)
        end
    end
end

-- ----------------------------------------------------------------------------
-- KEYS, CONTROLLER, WHEEL
-- ----------------------------------------------------------------------------
function ZeD_MMWorkshop:joyB() self:back() end

function ZeD_MMWorkshop:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.busy then return nil end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = self.confirm and getText("UI_Cancel") or ZeD.btnCase(getText("UI_btn_back")) } }
end
function ZeD_MMWorkshop:keyEscape()
    if self.titleE:isFocused() then self.titleE:unfocus(); return true end
    if self.noteE:isFocused() then self.noteE:unfocus(); return true end
    self:back()
    return true
end
function ZeD_MMWorkshop:keyOther(key)
    if self.titleE:isFocused() or self.noteE:isFocused() then return false end
    return false
end
function ZeD_MMWorkshop:close() self:back() end

function ZeD_MMWorkshop:wheel(del)
    local T = ZeD.T
    local fv = self._fv
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if fv and mx >= fv.x and mx <= fv.x + fv.w and my >= fv.y and my <= fv.y + fv.h then
        self.fscroll = self.fscroll + del * T.px(40)
        return true
    end
    return false
end
function ZeD_MMWorkshop:onMouseWheel(del) return MM.wheel(del) end
local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "workshop" and MM.root and MM.root.workshopWin then return MM.root.workshopWin:wheel(del) end
    return _wheel(del)
end

MM.addView("workshop", "workshopWin", function() return ZeD_MMWorkshop:new() end, "workshopSubmit")
