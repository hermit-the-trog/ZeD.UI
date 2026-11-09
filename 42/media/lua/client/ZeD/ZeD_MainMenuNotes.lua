-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuNotes.lua
-- ============================================================================
-- THE DESK'S NOTES: one sticky note always on the desktop, plus the CletusWorks notepad, whose
-- pages live in the Documents folder. Client-side; two organisms (the sticky's field, the
-- notepad window). ZeD_DeskNotes.lua is the model; this file draws.
--
-- THE STICKY NOTE sits at the top of the desktop's left edge, always, under the windows like the icons. Its words
-- are typed in place: a click puts the caret in it wherever it shows (a window over it keeps its own part), and on a
-- controller the D-pad reaches it like an icon and A brings up the keyboard. It saves itself a moment after the
-- typing stops and whenever it lets go of the keys. Pale yellow paper whatever the theme: it is a note stuck on the
-- screen, not part of the system.
--
-- CLETUSWORKS (named after ClarisWorks, the all-in-one on every school Mac in 1993; the desktop
-- icon reads CletusWorks, the window "CletusWorks Notepad") is a ZeD window on the monitor with one page in it. The
-- band holds New, Open, Rename, Delete and Save; the page's name is in the title bar's stats and the band's line
-- says whether it is saved, or that the page is full (N.TEXT_MAX: the box takes no more). A new page becomes a note
-- when it is first saved. The notes are listed in the desktop's one Documents folder
-- (ZeD_MainMenuDocs.lua), and Open goes to that list. Delete asks in the band, as every question on the desk does, and
-- lands on Cancel. Leaving a page with unsaved words (the close box, B, New, another note opened from Documents) asks
-- "Save changes?" first: Discard changes, Cancel, Save. Any other way out (another desktop icon, the menu bar) asks
-- nothing: the page stays as it was, and words not saved yet are kept as a draft (ZeD_DeskNotes), so a game started
-- from the menu bar loses nothing: the notepad opens with them next time.
--
-- The ZeD menu (the logo, where System 7 kept its desk accessories) opens CletusWorks too.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuDesktop"
require "ZeD/ZeD_DeskNotes"
require "ISUI/ISTextEntryBox"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local N  = ZeD.DeskNotes

-- design units
local STICKY_W, STICKY_H, STICKY_TOP, STICKY_PAD = 124, 124, 9, 5
local STICKY_LINES = 12
local STICKY_SAVE_MS = 800           -- the sticky saves this long after the typing stops
local DRAFT_MS = 1500                -- unsaved words go to the draft at most this often
local PAGE_W = 720                   -- the notepad window's widest
local PAGE_LINES = 1000

-- the sticky's paper: pale yellow on every theme (a note stuck on the screen), its strip a shade darker
-- (paper and strip at the paper tone, Tokens.lua: no large near-white areas; the hint ink dark enough for 4.5 : 1 on it)
local PAPER = ZeD.paperTone({ r = 1.0, g = 0.95, b = 0.6 })
local PAPER_TOP = ZeD.paperTone({ r = 0.93, g = 0.84, b = 0.38 })
local PAPER_EDGE = { r = 0.32, g = 0.27, b = 0.1 }
local INK = { r = 0.1, g = 0.1, b = 0.12 }
local INK_HINT = { r = 0.24, g = 0.215, b = 0.135 }

local function tr(k, ...) return ZeD.tr(k, ...) end
local function gamepadJoy() return MM.gamepad() and JoypadState and JoypadState.getMainMenuJoypad and JoypadState.getMainMenuJoypad() or nil end

--- A field with the controller: ZeD's keyboard types into it; with the mouse or keys, the caret.
local function editField(entry)
    local jd = gamepadJoy()
    if jd and OnScreenKeyboard and OnScreenKeyboard.Show then
        local ok, osk = pcall(OnScreenKeyboard.Show, jd.player or 0, entry, jd)
        if ok and osk then
            osk.prevFocus = jd.focus
            jd.focus = osk
            updateJoypadFocus(jd)
            return
        end
    end
    entry:focus()
end
MM.editField = editField

-- ============================================================================
-- THE STICKY NOTE: its field (a child of the desk, added after the icons: under every window)
-- ============================================================================
ZeD_MMSticky = ISPanel:derive("ZeD_MMSticky")

--- The sticky's field panel, made once by the desk (ZeD_MainMenu.lua); the icon layer places it each frame.
function ZeD_MMSticky:new()
    local o = ISPanel:new(-10000, -10000, 10, 10)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._changedAt = nil
    return o
end

function ZeD_MMSticky:createChildren()
    local e = ISTextEntryBox:new("", 0, 0, 100, 100)
    e:initialise()
    e:instantiate()
    e:setMultipleLine(true)
    e:setMaxLines(STICKY_LINES)
    e:setMaxTextLength(N.STICKY_MAX)
    e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    e.onTextChange = function() self._changedAt = MM.now() end
    e.onOtherKey = function(entry, key)
        if key == Keyboard.KEY_ESCAPE then entry:unfocus(); self:keep() end
    end
    pcall(function()
        e.javaObject:setTextRGBA(INK.r, INK.g, INK.b, 1)
        e.javaObject:setPlaceholderTextRGBA(INK_HINT.r, INK_HINT.g, INK_HINT.b, 1)
    end)
    self:addChild(e)
    self.entry = e
    e:setText(N.sticky())
    self._hint = nil
end

-- the words to the file, if they changed
function ZeD_MMSticky:keep()
    self._changedAt = nil
    local text = self.entry:getText() or ""
    if text ~= N.sticky() then N.saveSticky(text) end
end

-- placed over its paper by the icon layer each frame (c: the cell, in the desk's coordinates)
function ZeD_MMSticky:place(c)
    local T = ZeD.T
    local x, y, w, h = c.x, c.y, c.w, c.h
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    local top, pad = T.px(STICKY_TOP), T.px(STICKY_PAD)
    local e = self.entry
    local ex, ey, ew, eh = pad, top + pad, w - pad * 2, h - top - pad * 2
    if e.x ~= ex or e.y ~= ey then e:setX(ex); e:setY(ey) end
    if e.width ~= ew or e.height ~= eh then e:setWidth(ew); e:setHeight(eh) end
    local f = ZeD.Text and ZeD.Text.entryFont and ZeD.Text.entryFont()
    if f and e._zedFont ~= f then e._zedFont = f; e:setFont(f) end
    local hint = tr("UI_ZeD_Desk_StickyHint")
    if self._hint ~= hint then self._hint = hint; pcall(function() e:setPlaceholderText(hint) end) end
    self._placedAt = MM.now()
end

function ZeD_MMSticky:prerender()
    -- (not placed in the last half second: the icon layer stopped drawing it, so the field goes too)
    local shown = self._placedAt ~= nil and MM.now() - self._placedAt < 500
    if self.entry:isVisible() ~= shown then self.entry:setVisible(shown) end
end

function ZeD_MMSticky:update()
    ISPanel.update(self)
    local e = self.entry
    -- a press anywhere else lets go of the keys (the glass takes presses, so the field never hears them)
    local down = ZeD.MouseTick and ZeD.MouseTick.down() or false
    if down and not self._wasDown and e:isFocused() then
        local mx, my = getMouseX(), getMouseY()
        local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
        if not (mx >= ax and my >= ay and mx < ax + self.width and my < ay + self.height) then
            e:unfocus()
            self:keep()
        end
    end
    self._wasDown = down
    if self._changedAt and (MM.now() - self._changedAt >= STICKY_SAVE_MS or not e:isFocused()) then self:keep() end
end

-- the field under the pointer takes the press (MM.entryUnder hands the glass's press to a field): the sticky's,
-- when it shows there and nothing on the monitor lies over it. Each MM function this file wraps (entryUnder,
-- menuItems, wheel, showView) keeps its base once in MM._notes*Base, so a Lua reload never wraps the wrapper.
local _entryUnder = MM._notesEntryBase or MM.entryUnder
MM._notesEntryBase = _entryUnder
function MM.entryUnder(mx, my)
    local e = _entryUnder(mx, my)
    if e then return e end
    local st = MM.root and MM.root.sticky
    if not (st and st.entry and st.entry:isVisible()) then return nil end
    if MM.ctx.open or MM.waking or MM.powerOff or MM.poweringOn() or MM.blocked() then return nil end
    local se = st.entry
    local ex, ey = se:getAbsoluteX(), se:getAbsoluteY()
    if not (mx >= ex and my >= ey and mx < ex + se.width and my < ey + se.height) then return nil end
    local w = MM.activeWindow()
    if w and w ~= MM.root.icons and w:isVisible() then
        local wx, wy = w:getAbsoluteX(), w:getAbsoluteY()
        if mx >= wx and my >= wy and mx < wx + w.width and my < wy + w.height then return nil end
    end
    return se
end

--- Is the sticky typing (its keys are its own)?
function MM.stickyTyping()
    local st = MM.root and MM.root.sticky
    return st ~= nil and st.entry ~= nil and st.entry:isFocused()
end

-- the paper, drawn by the icon layer (under the windows); sel: the desktop's selection is on it
local function drawSticky(p, c, sel)
    local T = ZeD.T
    local top = T.px(STICKY_TOP)
    p:drawRect(c.x + T.px(2), c.y + T.px(2), c.w, c.h, 0.35, 0, 0, 0)                     -- (its shadow)
    p:drawRect(c.x, c.y, c.w, c.h, 1, PAPER.r, PAPER.g, PAPER.b)
    p:drawRect(c.x, c.y, c.w, top, 1, PAPER_TOP.r, PAPER_TOP.g, PAPER_TOP.b)
    p:drawRect(c.x, c.y + top, c.w, T.px(1), 1, PAPER_EDGE.r, PAPER_EDGE.g, PAPER_EDGE.b)
    p:drawRectBorder(c.x, c.y, c.w, c.h, 1, PAPER_EDGE.r, PAPER_EDGE.g, PAPER_EDGE.b)
    -- the desktop's selection (the controller's focus): the accent round it
    local typing = MM.stickyTyping()
    if (sel and MM.view == "desktop") or typing then
        local ac = T.accent
        local b = T.px(2)
        p:drawRectBorder(c.x - b, c.y - b, c.w + b * 2, c.h + b * 2, 1, ac.r, ac.g, ac.b)
        p:drawRectBorder(c.x - b + 1, c.y - b + 1, c.w + b * 2 - 2, c.h + b * 2 - 2, 1, ac.r, ac.g, ac.b)
    end
    local st = MM.root and MM.root.sticky
    if st then st:place(c) end
end

-- ============================================================================
-- THE DESKTOP'S LEFT SIDE (ZeD_MainMenuDesktop.lua lays it out): the sticky, the apps, the files
-- ============================================================================
local STICKY_ITEM = {
    id = "sticky",
    size = function() local T = ZeD.T; return T.px(STICKY_W), T.px(STICKY_H) end,
    draw = drawSticky,
    open = function()
        local st = MM.root and MM.root.sticky
        if st and st.entry then editField(st.entry) end
    end,
}

--- Show the notepad, on page id when given (openNote is the same door, for the Documents list).
function MM.openNotepad(id)
    MM.ctx.open = nil
    MM._noteWant = id or false        -- (false: the notepad as it was, or a new page)
    MM.showView("notepad")
end
function MM.openNote(id) MM.openNotepad(id) end

local CLETUS_ITEM = { id = "cletusworks", label = "", open = function() MM.openNotepad() end }
-- (the notes are not icons of their own; one Documents folder lists them all)
local DOCS_ITEM = { id = "documents", label = "", open = function() MM.openDocs() end }

MM.leftApps = MM.leftApps or {}       -- more apps after CletusWorks (ZeD_MainMenuMail.lua adds Mail)
local _left = { key = nil, list = nil }
--- The desktop's left column, top to bottom: the sticky, CletusWorks, the apps, Documents
--- (rebuilt when a note, an app or the mail count changes).
function MM.leftItems()
    local MSq = ZeD.MailStore and ZeD.MailStore.seq or 0
    local key = tostring(N.seq) .. ":" .. tostring(#MM.leftApps) .. ":" .. tostring(MSq)
    if _left.key == key and _left.list then return _left.list end
    CLETUS_ITEM.label = tr("UI_ZeD_Desk_CletusWorks")
    DOCS_ITEM.label = tr("UI_ZeD_Desk_Documents")
    local out = { STICKY_ITEM, CLETUS_ITEM }
    for _, a in ipairs(MM.leftApps) do
        if a.labelFn then a.label = a.labelFn() end   -- (an app's name can carry a count: ProtoPOP3 Mail (2))
        out[#out + 1] = a
    end
    out[#out + 1] = DOCS_ITEM
    _left.key, _left.list = key, out
    return out
end

-- The ZeD menu (where System 7 kept the desk accessories): CletusWorks Notepad, and the apps after it
local _menuItems = MM._notesMenuBase or MM.menuItems
MM._notesMenuBase = _menuItems
function MM.menuItems(key)
    local t = _menuItems(key)
    -- (the desk after a death has no notepad or app views to show: picking one there blanked the monitor)
    if key ~= "zed" or MM.respawn then return t end
    local out = {}
    for i, it in ipairs(t) do
        out[#out + 1] = it
        if i == 1 then
            out[#out + 1] = "-"
            out[#out + 1] = { text = tr("UI_ZeD_Desk_NotepadTitle"), fn = function() MM.openNotepad() end }
            for _, a in ipairs(MM.leftApps) do
                if a.menu then out[#out + 1] = { text = tr(a.menu), fn = a.open } end
            end
        end
    end
    return out
end

-- ============================================================================
-- CLETUSWORKS NOTEPAD
-- ============================================================================
ZeD_MMNotepad = ZeD_MMWindow:derive("ZeD_MMNotepad")

function ZeD_MMNotepad:new()
    local o = ZeD_MMWindow.new(self, "notepad")
    o.noResetControl = true
    o.doc = nil            -- { id (nil: not on the desktop yet), name, saved (the words as last saved) }
    o.confirm = false      -- false | "delete" | "rename" | "unsaved"
    o.pending = nil        -- what runs once "Save changes?" is answered
    o.note = nil           -- a line for the band (full, a write that failed)
    return o
end

function ZeD_MMNotepad:createChildren()
    ZeD_Window.createChildren(self)
    local e = UI.newEntry(self)
    e:setMultipleLine(true)
    e:setMaxLines(PAGE_LINES)
    e:setMaxTextLength(N.TEXT_MAX)
    e.onTextChange = function() self.note = nil end
    e.onEscape = function() e:unfocus() end
    self.edit = e
    self.renameEntry = UI.newEntry(self)
    self.renameEntry.onCommandEntered = function() self:rename() end
    self.renameEntry.onEscape = function() self:setConfirm(false) end
    self.renameEntry:setVisible(false)
end

function ZeD_MMNotepad:text() return N.clean(self.edit:getText() or "", N.TEXT_MAX) end

function ZeD_MMNotepad:dirty()
    local d = self.doc
    if not d then return false end
    return self:text() ~= (d.saved or "")
end

function ZeD_MMNotepad:load(doc, text)
    self.doc = doc
    self.edit:setText(text or doc.saved or "")
    pcall(function() self.edit:setCursorPos(0) end)
    pcall(function() self.edit:setYScroll(0) end)
    self.note = nil
end

function ZeD_MMNotepad:newPage()
    self:load({ id = nil, name = N.freshName(tr("UI_ZeD_Desk_Untitled")), saved = "" }, "")
end

function ZeD_MMNotepad:openId(id)
    local n = N.get(id)
    if not n then self:newPage(); return end
    local text = N.read(id) or ""
    self:load({ id = id, name = n.name, saved = text }, text)
    N.clearDraft()
end

-- runs fn now, or after "Save changes?" when the page has words not saved
function ZeD_MMNotepad:leave(fn)
    if self:dirty() then
        self.pending = fn
        self:setConfirm("unsaved")
        return
    end
    N.clearDraft()
    fn()
end

-- every time the window shows: the page it was asked for, else the page as it was, else last time's draft, else a new page
function ZeD_MMNotepad:onShow()
    local want = MM._noteWant
    MM._noteWant = nil
    self.focusId = "doc"
    if not self.doc then
        local d = N.draft()
        if d then
            local n = (d.id ~= 0) and N.get(d.id) or nil
            if n then self:load({ id = d.id, name = n.name, saved = N.read(d.id) or "", recovered = true }, d.text)
            else self:load({ id = nil, name = (d.name ~= "" and d.name) or N.freshName(tr("UI_ZeD_Desk_Untitled")), saved = "", recovered = true }, d.text) end
        elseif want then
            self:openId(want)
        else
            self:newPage()
        end
        if not (want and self.doc and self.doc.id ~= want) then return end
    end
    if self.doc.id and not N.get(self.doc.id) then self.doc.id = nil end   -- (deleted while away: a page not on the desktop)
    if self.doc.id then self.doc.name = N.get(self.doc.id).name end         -- (renamed in Documents while away)
    if want and want ~= self.doc.id then
        self:leave(function() self:openId(want) end)
    end
end

-- ACTIONS ---------------------------------------------------------------------

function ZeD_MMNotepad:save()
    local d = self.doc
    if not d then return false end
    local text = self:text()
    if d.id then
        if not N.save(d.id, text) then self.note = tr("UI_ZeD_Desk_WriteFailed"); return false end
    else
        local n, err = N.create(d.name, text)
        if not n then
            self.note = (err == "full") and tr("UI_ZeD_Desk_Full", N.MAX) or tr("UI_ZeD_Desk_WriteFailed")
            return false
        end
        d.id, d.name = n.id, n.name
    end
    d.saved, d.recovered = text, nil
    N.clearDraft()
    self.note = nil
    MM.clickSound()
    return true
end

function ZeD_MMNotepad:doNew() self:leave(function() self:newPage(); self.focusId = "doc" end) end

function ZeD_MMNotepad:openItems()
    local items = {}
    for _, n in ipairs(N.list()) do
        local id = n.id
        items[#items + 1] = { text = n.name, check = self.doc and self.doc.id == id, fn = function()
            if self.doc and self.doc.id == id then return end
            self:leave(function() self:openId(id); self.focusId = "doc" end)
        end }
    end
    if #items == 0 then items[1] = { text = tr("UI_ZeD_Desk_NoNotes"), disabled = true } end
    return items
end

-- Open: the Documents window's list (its Open comes back here, through "Save changes?" when the page has unsaved words)
function ZeD_MMNotepad:doOpen() MM.openDocs("notepad") end

-- the name the rename field holds, or nil and why not
function ZeD_MMNotepad:renameCheck()
    local d = self.doc
    if not d then return nil end
    local name = self.renameEntry:getText() or ""
    if d.id then
        local clean, err = N.checkName(d.id, name)
        if not clean then return nil, err end
        return clean
    end
    local clean = N.cleanName(name)
    if clean == "" then return nil, "empty" end
    if N.taken(clean) then return nil, "taken" end
    return clean
end

function ZeD_MMNotepad:startRename()
    if not self.doc then return end
    self:setConfirm("rename")
    self.renameEntry:setText(self.doc.name)
    self.renameEntry:setVisible(true)
    editField(self.renameEntry)
    pcall(function() self.renameEntry:selectAll() end)   -- (typing replaces the old name, as a desktop's rename does)
end

function ZeD_MMNotepad:rename()
    local name = self:renameCheck()
    if not name then return end
    local d = self.doc
    if d.id then
        if not N.rename(d.id, name) then return end
        d.name = N.get(d.id).name
    else
        d.name = name
    end
    self:setConfirm(false)
end

function ZeD_MMNotepad:delete()
    local d = self.doc
    if not (d and d.id) then return end
    N.delete(d.id)
    self:setConfirm(false)
    self:newPage()
end

function ZeD_MMNotepad:close()
    if self.confirm then self:setConfirm(false); return end
    if self.edit:isFocused() then self.edit:unfocus() end
    self:leave(function()
        MM.clickSound()
        MM.showView("desktop")
    end)
end
function ZeD_MMNotepad:back() self:close() end

-- the question or the field in the band; false closes it
function ZeD_MMNotepad:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    MM.clickSound()
    if mode ~= "rename" then
        self.renameEntry:setVisible(false)
        if self.renameEntry:isFocused() then self.renameEntry:unfocus() end
    end
    if mode == "unsaved" or mode == "delete" or mode == "rename" then
        if self.edit:isFocused() then self.edit:unfocus() end
        self.focusId = "confirm:no"            -- (a question that loses work lands on Cancel)
    else
        self.pending = nil
        self.focusId = "doc"
    end
end

-- "Save changes?" answered: Save keeps the words, Discard changes drops them; either way what was asked goes on
function ZeD_MMNotepad:answer(keep)
    local fn = self.pending
    if keep and not self:save() then self:setConfirm(false); return end
    if not keep and self.doc then self.edit:setText(self.doc.saved or "") end
    N.clearDraft()
    self.pending = nil
    self:setConfirm(false)
    if fn then fn() end
end

-- LAYOUT + DRAWING ---------------------------------------------------------------

function ZeD_MMNotepad:update()
    ZeD_MMWindow.update(self)
    -- words not saved go to the draft now and then, and the draft goes once nothing is unsaved
    local t = MM.now()
    if not self.doc then return end
    if self:dirty() then
        if not self._draftAt or t - self._draftAt >= DRAFT_MS then
            self._draftAt = t
            N.saveDraft(self.doc.id or 0, self.doc.name, self:text())
        end
    elseif N.draft() and MM.view == "notepad" then
        N.clearDraft()
    end
end

function ZeD_MMNotepad:prerender()
    local T = ZeD.T
    local L = MM.layout()
    self._specs, self._hits = {}, {}
    if not self.doc then self:newPage() end
    local d = self.doc
    -- the window: centred on the monitor below the menu bar, at most PAGE_W wide
    local barH = T.px(U.BAR_H)
    local gap = T.px(12)
    local w = math.min(T.px(PAGE_W), L.tw - T.px(40))
    local h = L.th - barH - gap * 2
    local x = L.tx + math.floor((L.tw - w) / 2)
    local y = L.ty + barH + gap
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self.title = tr("UI_ZeD_Desk_NotepadTitle")
    self.titleStats = { { text = d.name, noMark = true } }
    ZeD_Window.prerender(self)

    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    -- the page: one inset box, the field inside it
    local bx, by, bw, bh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, bx, by, bw, bh)
    UI.styleEntry(self.edit, bx + T.px(1), by + T.px(1), bw - T.px(2), bh - T.px(2))
    self._page = { x = bx, y = by, w = bw, h = bh }
    -- the controller's stop for the page (A: the keyboard); the pointer's press goes through the glass to the field
    self._specs[#self._specs + 1] = { id = "doc", listRow = true, noDraw = true, row = 1, col = 1, x = bx, y = by, w = bw, h = bh,
                                      fn = function() editField(self.edit) end, help = tr("UI_ZeD_Desk_HelpDocument") }
    if MM.gamepad() and self.focusId == "doc" and not self.edit:isFocused() then
        local ac = T.accent
        self:drawRectBorder(bx - T.px(2), by - T.px(2), bw + T.px(4), bh + T.px(4), 1, ac.r, ac.g, ac.b)
    end

    local row = 1000
    if self.confirm == "unsaved" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:discard", ZeD.tr("UI_ZeD_MMWord_DiscardChanges"), function() self:answer(false) end, "danger", false, tr("UI_ZeD_Desk_HelpDiscard") },
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_save"), function() self:answer(true) end, "primary", false, tr("UI_ZeD_Desk_HelpSave") } },
            tr("UI_ZeD_Desk_AskSave", d.name))
    elseif self.confirm == "delete" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:delete() end, "danger", false, tr("UI_ZeD_Desk_HelpDelete") } },
            tr("UI_ZeD_Desk_AskDelete", d.name))
    elseif self.confirm == "rename" then
        local valid, why = self:renameCheck()
        local whyText = (why == "taken") and tr("UI_ZeD_Desk_NameTaken") or ((why == "empty") and tr("UI_ZeD_Desk_NameEmpty") or tr("UI_ZeD_Desk_HelpRename"))
        local fx = UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_rename"), function() self:rename() end, "primary", valid == nil, valid and tr("UI_ZeD_Desk_HelpRename") or whyText } },
            tr("UI_ZeD_Desk_AskRename"), true)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        UI.styleEntry(self.renameEntry, fx, stripY + math.floor((stripH - fh) / 2), math.max(T.px(80), firstBtn - T.px(12) - fx), fh)
        self._specs[#self._specs + 1] = { id = "field:rename", listRow = true, noDraw = true, row = row, col = 0,
                                          x = fx, y = stripY + math.floor((stripH - fh) / 2), w = math.max(T.px(80), firstBtn - T.px(12) - fx), h = fh,
                                          fn = function() editField(self.renameEntry) end }
    else
        local dirty = self:dirty()
        local status, color
        if self.note then status, color = self.note, T.danger
        elseif #(self.edit:getText() or "") >= N.TEXT_MAX then status, color = tr("UI_ZeD_Desk_NoteFull", N.TEXT_MAX), T.warning
        elseif dirty and d.recovered then status, color = tr("UI_ZeD_Desk_Recovered"), T.warning
        elseif dirty then status, color = tr("UI_ZeD_Desk_NotSaved"), T.warning
        elseif d.id then status, color = tr("UI_ZeD_Desk_Saved"), T.positive
        else status, color = tr("UI_ZeD_Desk_NotOnDesktop"), T.textDim end
        UI.stripSpecs(self, stripY, w, row, {},
            { { "new", getText("UI_btn_new"), function() self:doNew() end, "default", false, tr("UI_ZeD_Desk_HelpNew") },
              { "open", getText("IGUI_Open"), function() self:doOpen() end, "default", false, tr("UI_ZeD_Desk_HelpOpen") },
              { "rename", getText("UI_btn_rename"), function() self:startRename() end, "default", false, tr("UI_ZeD_Desk_HelpRename") },
              { "delete", getText("UI_btn_delete"), function() self:setConfirm("delete") end, "default", d.id == nil,
                d.id and tr("UI_ZeD_Desk_HelpDelete") or tr("UI_ZeD_Desk_HelpDeleteNone") },
              { "save", getText("UI_btn_save"), function() self:save() end, "primary", not dirty and d.id ~= nil, tr("UI_ZeD_Desk_HelpSave") } },
            status, true, color)
    end
end

function ZeD_MMNotepad:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMNotepad:getStatusLine() return tr("UI_ZeD_Desk_HelpDocument") end

-- KEYS, CONTROLLER, WHEEL ----------------------------------------------------------
function ZeD_MMNotepad:joyB()
    if self.confirm then self:setConfirm(false); return end
    self:close()
end
function ZeD_MMNotepad:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Close") } }
end
function ZeD_MMNotepad:keyEscape()
    if self.edit:isFocused() then self.edit:unfocus(); return true end
    if self.confirm then self:setConfirm(false); return true end
    self:close()
    return true
end
function ZeD_MMNotepad:keyOther(key) return false end

function ZeD_MMNotepad:wheel(del)
    local r = self._page
    if not r then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < r.x or my < r.y or mx > r.x + r.w or my > r.y + r.h then return false end
    local e = self.edit
    pcall(function() e:setYScroll(math.min(0, (e:getYScroll() or 0) - del * ZeD.T.px(40))) end)
    return true
end
function ZeD_MMNotepad:onMouseWheel(del) return MM.wheel(del) end
local _wheel = MM._notesWheelBase or MM.wheel
MM._notesWheelBase = _wheel
function MM.wheel(del)
    if MM.view == "notepad" and MM.root and MM.root.notepadWin then return MM.root.notepadWin:wheel(del) end
    return _wheel(del)
end

-- leaving the notepad by any way at all (the menu bar, a game starting): the unsaved words go to the draft at once
local _show = MM._notesShowBase or MM.showView
MM._notesShowBase = _show
function MM.showView(view, joypadData)
    local np = MM.root and MM.root.notepadWin
    if np and np.doc and MM.view == "notepad" and view ~= "notepad" and np:dirty() then
        pcall(N.saveDraft, np.doc.id or 0, np.doc.name, np:text())
    end
    return _show(view, joypadData)
end

MM.addView("notepad", "notepadWin", function() return ZeD_MMNotepad:new() end)
