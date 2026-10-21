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
-- workshop.txt (vanilla's writeWorkshopTxt); UPLOAD asks in the strip, then
-- creates the item when it is new (create) and sends it (submitUpdate) with
-- the progress in the strip. Steam's answers come as vanilla's events.
-- Vanilla's workshopSubmit:setVisible(true) is redirected here.
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
    self.noteE.onTextChange = function() self:formChanged() end
end

function ZeD_MMWorkshop:onShow()
    self.confirm = false
    if self._fromEditor then self._fromEditor = nil; self.focusId = nil; return end   -- (back from the description editor: the form stays as it was)
    self.busy = nil
    self.note = nil
    self.scroll, self.fscroll = 0, 0
    self.focusId = nil
    self.items = {}
    pcall(function() self.items = jlist(getSteamWorkshopStagedItems()) end)
    self.unsaved = {}
    self.sel = math.max(1, math.min(self.sel or 1, #self.items))
    self:load()
    MM.wsEditor = nil
end

function ZeD_MMWorkshop:item() return self.items[self.sel] end

-- the picked folder's fields into the form
function ZeD_MMWorkshop:load()
    local it = self:item()
    self._loading = true
    self.titleE:setText(it and tostring(it:getTitle() or "") or "")
    self.noteE:setText(it and tostring(it:getChangeNote() or "") or "")
    self._loading = false
    self.vis = it and it:getVisibilityInteger() or 0
    self.tags = {}
    if it then for _, t in ipairs(jlist(it:getTags())) do self.tags[tostring(t)] = true end end
    self.desc = it and tostring(it:getDescription() or "") or ""
    self.contents = nil
    self._preview = nil
    if it then
        local ok, err = pcall(function() return it:validateContents() end)
        self.contents = ok and (err or false) or tostring(err)
        if self.contents and ok then   -- vanilla's own words for the code (UI_WorkshopError_*)
            local extra = ""
            pcall(function() extra = tostring(it:getExtendedErrorInfo(err) or "") end)
            local words = getTextOrNull("UI_WorkshopError_" .. tostring(err), extra)
            if words then self.contents = (words:gsub("\\n", " ")) end
        end
    end
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

function ZeD_MMWorkshop:save()
    local it = self:item()
    if not it then return end
    self:apply()
    local ok = false
    pcall(function() ok = it:writeWorkshopTxt() end)
    if ok then
        self.unsaved[it:getFolderName()] = nil
        self:say(ZeD.tr("UI_ZeD_Workshop_Saved", it:getFolderName()))
    else self:say(ZeD.tr("UI_ZeD_Workshop_SaveFailed"), true) end
    MM.clickSound()
end

function ZeD_MMWorkshop:pick(i)
    if i == self.sel or self.busy then return end
    self:apply()                      -- (the edits stay with their folder until saved or the screen closes)
    self.sel = i
    self.fscroll = 0
    self:load()
    MM.hoverSound()
end

-- what keeps it from going up (nil = nothing)
function ZeD_MMWorkshop:blocker()
    if BB.trim(self.titleE:getText()) == "" then return ZeD.tr("UI_ZeD_Workshop_NeedTitle") end
    if BB.trim(self.desc) == "" then return ZeD.tr("UI_ZeD_Workshop_NeedDescription") end
    if #self.desc > BB.LIMIT then return ZeD.tr("UI_ZeD_Workshop_DescriptionTooLong", BB.LIMIT) end
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
    self:apply()
    pcall(function() it:writeWorkshopTxt() end)
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
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local lw = math.floor((w - pad * 3) * LIST_SHARE)
    self:drawFolders(pad, bodyY, lw, bodyH)
    self:drawForm(pad * 2 + lw, bodyY, w - pad * 3 - lw, bodyH)
    self:buildStrip(stripY, stripH, w)
end

function ZeD_MMWorkshop:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask, self._askX)
    if self.busy then self:drawProgress() end
    self:drawHint()
    ZeD_Window.render(self)
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
    local ac = T.accent
    local gp = MM.gamepad()
    if #self.items == 0 then
        self:paneText(ZeD.tr("UI_ZeD_Workshop_NoFolders"), x + T.px(10), vy, w - T.px(20), f2, dim)
    end
    for i, it in ipairs(self.items) do
        local ry = vy + (i - 1) * rh
        if ry + rh > y + h then break end
        local rid = "frow:" .. i
        self._specs[#self._specs + 1] = { id = rid, listRow = true, row = i, col = 1, x = x + T.px(1), y = ry, w = w - T.px(2), h = rh,
                                          chosen = (i == self.sel), fn = function() self:pick(i) end }
        if gp and self.focusId == rid then self:drawRect(x + T.px(1), ry, w - T.px(2), rh, 0.55, ac.r, ac.g, ac.b)
        elseif i == self.sel then self:drawRect(x + T.px(1), ry, w - T.px(2), rh, 0.22, ac.r, ac.g, ac.b) end
        self:drawRect(x + T.px(1), ry + rh - T.px(1), w - T.px(2), T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
        local title = (i == self.sel) and BB.trim(self.titleE:getText()) or BB.trim(tostring(it:getTitle() or ""))
        if title == "" then title = tostring(it:getFolderName()) end
        local tx = x + T.px(10)
        local tc = T.textHead
        self:drawText(ZeD.Atoms.truncateText(title, f2, w - T.px(20)), tx, ry + T.px(6), tc.r, tc.g, tc.b, tc.a or 1, f2)
        local id = it:getID()
        local sub = id and ZeD.tr("UI_ZeD_Workshop_OnWorkshop", tostring(id)) or ZeD.tr("UI_ZeD_Workshop_NotOnWorkshop")
        if self.unsaved[it:getFolderName()] then sub = sub .. MM.DOT .. ZeD.tr("UI_ZeD_Workshop_NotSaved") end
        self:drawText(ZeD.Atoms.truncateText(sub, f3, w - T.px(20)), tx, ry + rh - T.px(6) - MM.fontH(f3), dim.r, dim.g, dim.b, dim.a or 1, f3)
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

-- a spec button inside the form (clipped with it); returns its right edge
function ZeD_MMWorkshop:formBtn(id, text, fn, x, y, variant, row, col, disabled, extra)
    local T = ZeD.T
    local bw = MM.textW(T.fontF3, ZeD.btnCase(text)) + T.px(U.STRIP_BTN_PAD) * 2
    local b = { id = id, text = text, fn = fn, variant = variant or "default", row = row, col = col, disabled = disabled,
                x = x, y = y, w = bw, h = T.px(U.STRIP_BTN_H), clipTop = self._fv.y, clipBot = self._fv.y + self._fv.h }
    if extra then for k, v in pairs(extra) do b[k] = v end end
    self._specs[#self._specs + 1] = b
    return x + bw
end

-- an entry in the form: shown only while it is wholly in view
function ZeD_MMWorkshop:formEntry(e, id, x, y, w)
    local T = ZeD.T
    local eh = T.px(24)
    local fv = self._fv
    local inView = y >= fv.y and y + eh <= fv.y + fv.h
    if e:isVisible() ~= inView then e:setVisible(inView) end
    if inView then
        UI.styleEntry(e, x, y, w, eh)
        if self.focusId == id and MM.gamepad() then
            local ac = T.accent
            self:drawRectBorder(x - T.px(2), y - T.px(2), w + T.px(4), eh + T.px(4), 1, ac.r, ac.g, ac.b)
        end
    end
    -- (the controller lands on the field as on a button: A types in it)
    self._specs[#self._specs + 1] = { id = id, listRow = true, x = x, y = y, w = w, h = eh, clipTop = fv.y, clipBot = fv.y + fv.h,
                                      fn = function() e:focus() end }
    return eh
end

function ZeD_MMWorkshop:drawForm(x, y, w, h)
    local T = ZeD.T
    local bs = T.borderS
    self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    local pad = T.px(PAD)
    local ix, iw = x + pad, w - pad * 2
    local top = y
    -- the note band: what Save or Upload did
    if self.note and MM.now() < self.note.untilMs then
        local f2 = T.fontF2
        local lines = ZeD.Atoms.wrapText(self.note.text, f2, iw - T.px(14))
        local nh = #lines * (MM.fontH(f2) + T.px(2)) + T.px(12)
        local s2 = T.surf2
        self:drawRect(x + T.px(1), y + T.px(1), w - T.px(2), nh, 1, s2.r, s2.g, s2.b)
        self:drawRect(x + T.px(1), y + nh, w - T.px(2), T.px(1), bs.a, bs.r, bs.g, bs.b)
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
    local bh = T.px(U.STRIP_BTN_H)
    local f2, f3, dim = T.fontF2, T.fontF3, T.textDim
    -- TITLE
    label(self, ZeD.upper(ZeD.trBare("UI_WorkshopSubmit_ItemTitle")), ix, cy, T.px(24))
    cy = cy + self:formEntry(self.titleE, "f:title", vx, cy, vw) + T.px(10)
    -- WHO CAN SEE IT
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelWho"), ix, cy, bh)
    local bx = vx
    for i, v in ipairs(VIS) do
        bx = self:formBtn("vis:" .. v[1], ZeD.tr(v[2]), function() self.vis = v[1]; self:formChanged(); MM.clickSound() end, bx, cy,
            (self.vis == v[1]) and "primary" or "default", 300, i) + T.px(6)
    end
    cy = cy + bh + T.px(4)
    cy = self:paneText(ZeD.tr(VIS_SEEN[self.vis] or VIS_SEEN[0]), vx, cy, vw, f3, dim) + T.px(8)
    -- TAGS
    label(self, ZeD.upper(ZeD.trBare("UI_WorkshopSubmit_ItemTags")), ix, cy, bh)
    bx = vx
    local tags = {}
    pcall(function() tags = jlist(SteamWorkshopItem.getAllowedTags()) end)
    local row = 310
    for i, t in ipairs(tags) do
        local name = tostring(t)
        local tw = MM.textW(T.fontF3, name) + T.px(U.STRIP_BTN_PAD) * 2
        if bx + tw > vx + vw and bx > vx then bx = vx; cy = cy + bh + T.px(6); row = row + 1 end
        bx = self:formBtn("tag:" .. name, name, function() self.tags[name] = not self.tags[name] or nil; self:formChanged(); MM.clickSound() end,
            bx, cy, self.tags[name] and "primary" or "default", row, i, false, { keepCase = true }) + T.px(6)
    end
    cy = cy + bh + T.px(12)
    -- PREVIEW PICTURE
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelPreview"), ix, cy, T.px(20))
    local path = tostring(it:getPreviewImage() or "")
    local tex = (path ~= "") and getTexture(path) or nil
    local tsz = T.px(THUMB)
    local bs = T.borderS
    if tex then self:drawTextureScaledAspect(tex, vx, cy, tsz, tsz, 1, 1, 1, 1) end
    self:drawRectBorder(vx, cy, tsz, tsz, bs.a, bs.r, bs.g, bs.b)
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
    local bh = T.px(U.STRIP_BTN_H)
    local f2, f3, dim, txt = T.fontF2, T.fontF3, T.textDim, T.text
    -- DESCRIPTION
    label(self, ZeD.upper(ZeD.trBare("UI_WorkshopSubmit_ItemDescription")), ix, cy, T.px(20))
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
    local n = #self.desc
    cy = self:paneText(ZeD.tr("UI_ZeD_DescEdit_Count", BB.count(n), BB.count(BB.LIMIT)), vx, cy + T.px(2), vw, f3, (n > BB.LIMIT) and T.danger or dim) + T.px(6)
    local bx = self:formBtn("desc:edit", ZeD.tr("UI_WorkshopSubmit_EditDescription"), function() self:openEditor() end, vx, cy, "default", 400, 1) + T.px(6)
    self:formBtn("desc:copy", ZeD.tr("UI_ZeD_Workshop_CopyCodes"), function() Clipboard.setClipboard(self.desc); self:say(ZeD.tr("UI_ZeD_Workshop_CodesCopied")); MM.clickSound() end,
        bx, cy, "default", 400, 2, self.desc == "")
    cy = cy + bh + T.px(12)
    -- CHANGE NOTE
    label(self, ZeD.tr("UI_ZeD_Workshop_LabelChangeNote"), ix, cy, T.px(24))
    cy = cy + self:formEntry(self.noteE, "f:note", vx, cy, vw) + T.px(4)
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

function ZeD_MMWorkshop:openEditor()
    self:apply()
    MM.clickSound()
    MM.wsEditor = { text = self.desc, title = BB.trim(self.titleE:getText()), done = function(text) self:setDescription(text) end }
    MM.showView("wsdesc")
end

function ZeD_MMWorkshop:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000
    local ask = nil
    self._askX = nil
    local it = self:item()
    if self.busy then
        UI.stripSpecs(self, stripY, w, row, { { "back", getText("UI_btn_back"), function() end, "default", true } }, {})
        self._stripY, self._stripH, self._ask = stripY, stripH, nil
        return
    end
    if self.confirm == "upload" then
        ask = ZeD.tr(VIS_ASK[self.vis] or VIS_ASK[0], BB.trim(self.titleE:getText()))
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", ZeD.tr("UI_ZeD_Workshop_Upload"), function() self:upload() end, "primary" } })
    elseif self.confirm == "leave" then
        ask = ZeD.tr("UI_ZeD_Workshop_AskSave")
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", ZeD.tr("UI_ZeD_DescEdit_Discard"), function()
                for _, x in ipairs(self.items) do pcall(function() x:readWorkshopTxt() end) end
                self.unsaved = {}; self.confirm = false; MM.clickSound(); MM.showView("main") end },
            { "confirm:yes", getText("UI_btn_save"), function()
                for _, x in ipairs(self.items) do if self.unsaved[x:getFolderName()] then pcall(function() x:writeWorkshopTxt() end) end end
                self:apply(); local cur = self:item(); if cur then pcall(function() cur:writeWorkshopTxt() end) end
                self.unsaved = {}; self.confirm = false; MM.clickSound(); MM.showView("main") end, "primary" } })
    else
        local block = it and self:blocker() or ZeD.tr("UI_ZeD_Workshop_NothingToUpload")
        local rights = {
            { "save", getText("UI_btn_save"), function() self:save() end, "default", not self:isUnsaved() },
            { "upload", ZeD.tr((it and it:getID()) and "UI_ZeD_Workshop_UploadUpdate" or "UI_ZeD_Workshop_Upload"), function() self:setConfirm("upload") end, "primary", block ~= nil },
        }
        local askX = UI.stripSpecs(self, stripY, w, row, { { "back", getText("UI_btn_back"), function() self:back() end } }, rights)
        if block and it then
            local firstBtn = w
            for _, b in ipairs(self._specs) do if b.row == row and b.x > askX then firstBtn = math.min(firstBtn, b.x) end end
            ask = ZeD.Atoms.truncateText(block, T.fontF2, firstBtn - T.px(12) - (askX + T.px(4)))
            self._askX = askX + T.px(4)
        end
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- the upload's progress where the buttons were
function ZeD_MMWorkshop:drawProgress()
    local T = ZeD.T
    local it = self:item()
    local f2, txt = T.fontF2, T.text
    local y, h = self._stripY, self._stripH
    local x0 = T.px(U.STRIP_PAD_X) + MM.textW(T.fontF3, ZeD.btnCase(getText("UI_btn_back"))) + T.px(U.STRIP_BTN_PAD) * 2 + T.px(16)
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
    local bw = self.width - T.px(U.STRIP_PAD_X) - bx
    if bw > T.px(60) then
        local bh = T.px(10)
        local by = y + math.floor((h - bh) / 2)
        local bs, ac = T.borderS, T.accent
        self:drawRectBorder(bx, by, bw, bh, bs.a, bs.r, bs.g, bs.b)
        local k = frac or ((MM.now() - self.busy.t0) % 1600) / 1600   -- (no total yet: a sweep)
        if frac then self:drawRect(bx + T.px(1), by + T.px(1), math.floor((bw - T.px(2)) * k), bh - T.px(2), 1, ac.r, ac.g, ac.b)
        else self:drawRect(bx + T.px(1) + math.floor((bw - T.px(40)) * k), by + T.px(1), T.px(38), bh - T.px(2), 1, ac.r, ac.g, ac.b) end
    end
end

-- an icon button's words, after the pointer rests on it (none here yet; the editor has them)
function ZeD_MMWorkshop:drawHint() end

-- ----------------------------------------------------------------------------
-- KEYS, CONTROLLER, WHEEL
-- ----------------------------------------------------------------------------
function ZeD_MMWorkshop:joyB() self:back() end
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
