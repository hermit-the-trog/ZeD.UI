-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuDocs.lua
-- ============================================================================
-- DOCUMENTS: the notes folder on the monitor. Client; an organism (a window on the desk, the "docs" view). One
-- Documents icon on the desktop stands in for an icon per note (the desktop would fill otherwise).
-- A ZeD window listing every CletusWorks note, its name and when it was saved, newest
-- first; the band: Rename (a field in the band), Delete (asks, lands on Cancel) and Open (the main one: the note in
-- CletusWorks, which asks "Save changes?" first when its page has unsaved words). CletusWorks' own Open comes here, and
-- closing then goes back to it. The band's line counts the notes against the cap (24).
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuNotes"
require "ZeD/ZeD_DeskNotes"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local N  = ZeD.DeskNotes

local ROW_H = 30                     -- design units
local function tr(k, ...) return ZeD.tr(k, ...) end

-- "Nov 7, 9:42 PM" on this computer's clock (the ticket cards' words when they are loaded)
local function when(sec)
    if type(sec) ~= "number" or sec <= 0 then return "" end
    local TCd = ZeD.TicketCards and ZeD.TicketCards._D
    if TCd and TCd.realDate then
        local ok, s = pcall(TCd.realDate, sec)
        if ok and s then return s end
    end
    local ok, d = pcall(os.date, "*t", sec)
    if not ok or type(d) ~= "table" then return "" end
    local months = MM.MONTHS or {}
    return tr(months[d.month or 1] or "") .. " " .. tostring(d.day or 1) .. ", " .. string.format("%02d:%02d", d.hour or 0, d.min or 0)
end

--- Show the Documents window. from: the view to go back to on close ("notepad" from CletusWorks' Open; the
--- desktop otherwise).
function MM.openDocs(from)
    MM.ctx.open = nil
    MM._docsFrom = from
    MM.showView("docs")
end

ZeD_MMDocs = ZeD_MMWindow:derive("ZeD_MMDocs")

function ZeD_MMDocs:new()
    local o = ZeD_MMWindow.new(self, "docs")
    o.noResetControl = true
    o.sel = nil              -- the picked note's id
    o.scroll = 0
    o.confirm = false        -- false | "delete" | "rename"
    return o
end

function ZeD_MMDocs:createChildren()
    ZeD_Window.createChildren(self)
    self.renameEntry = UI.newEntry(self)
    self.renameEntry.onCommandEntered = function() self:rename() end
    self.renameEntry.onEscape = function() self:setConfirm(false) end
    self.renameEntry:setVisible(false)
end

-- newest saved first
function ZeD_MMDocs:rows()
    local list = {}
    for _, n in ipairs(N.list()) do list[#list + 1] = n end
    table.sort(list, function(a, b)
        if (a.t or 0) ~= (b.t or 0) then return (a.t or 0) > (b.t or 0) end
        return a.id < b.id
    end)
    return list
end

function ZeD_MMDocs:onShow()
    self.from = MM._docsFrom
    MM._docsFrom = nil
    self:setConfirm(false)
    if not (self.sel and N.get(self.sel)) then
        local r = self:rows()[1]
        self.sel = r and r.id or nil
    end
    self.focusId = self.sel and ("row:" .. self.sel) or "close"
end

function ZeD_MMDocs:open()
    if not (self.sel and N.get(self.sel)) then return end
    MM.clickSound()
    MM.openNote(self.sel)
end

function ZeD_MMDocs:startRename()
    local n = self.sel and N.get(self.sel)
    if not n then return end
    self:setConfirm("rename")
    self.renameEntry:setText(n.name)
    self.renameEntry:setVisible(true)
    MM.editField(self.renameEntry)
end

function ZeD_MMDocs:rename()
    if not self.sel then return end
    if N.rename(self.sel, self.renameEntry:getText() or "") then self:setConfirm(false) end
end

function ZeD_MMDocs:delete()
    if self.sel then N.delete(self.sel) end
    local r = self:rows()[1]
    self.sel = r and r.id or nil
    self:setConfirm(false)
end

function ZeD_MMDocs:setConfirm(mode)
    if self.confirm == mode then return end
    self.confirm = mode
    if mode ~= "rename" then
        self.renameEntry:setVisible(false)
        if self.renameEntry:isFocused() then self.renameEntry:unfocus() end
    end
    if mode then
        self.focusId = "confirm:no"            -- (a question that loses work lands on Cancel)
    else
        self.focusId = self.sel and ("row:" .. self.sel) or "close"
    end
end

function ZeD_MMDocs:close()
    if self.confirm then self:setConfirm(false); return end
    MM.clickSound()
    MM.showView(self.from == "notepad" and "notepad" or "desktop")
end
function ZeD_MMDocs:back() self:close() end

function ZeD_MMDocs:prerender()
    local T = ZeD.T
    local L = MM.layout()
    self._specs, self._hits = {}, {}
    local barH, gap = T.px(U.BAR_H), T.px(12)
    local w = math.min(T.px(560), L.tw - T.px(40))
    local h = L.th - barH - gap * 2
    local x = L.tx + math.floor((L.tw - w) / 2)
    local y = L.ty + barH + gap
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self.title = tr("UI_ZeD_Desk_Documents")
    self.titleStats = { { text = tr("UI_ZeD_Desk_DocsCount", N.count(), N.MAX), noMark = true } }
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local lx, ly, lw, lh = pad, tb + pad, w - pad * 2, stripY - tb - pad * 2
    UI.insetBox(self, lx, ly, lw, lh)
    self._list = { x = lx, y = ly, w = lw, h = lh }
    local rows = self:rows()
    local rh = T.px(ROW_H)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, #rows * rh - lh + T.px(2))))
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local gp = MM.gamepad()
    if #rows == 0 then
        ZeD.Molecules.drawEmptyLine(self, lx + T.px(8), ly + T.px(8), lw - T.px(16), tr("UI_ZeD_Desk_NoNotes"))
    end
    self:setStencilRect(lx + T.px(1), ly + T.px(1), lw - T.px(2), lh - T.px(2))
    local f2, f3 = T.fontF2, T.fontF3
    for i, n in ipairs(rows) do
        local ry = ly + T.px(1) + (i - 1) * rh - self.scroll
        local id = "row:" .. n.id
        local isSel = n.id == self.sel
        if ry + rh > ly and ry < ly + lh then
            local hid = "docs:" .. id
            local onF = MM.rowLook(self, lx + T.px(1), ry, lw - T.px(2), rh, isSel, (not gp) and MM.ctx.hot == hid, gp and self.focusId == id, self)
            local c = onF and T.textOnFocus or T.text
            local d = onF and T.textOnFocus or T.textDim
            local date = when(n.t)
            local dw = MM.textW(f3, date)
            self:drawText(date, lx + lw - T.px(10) - dw, ry + math.floor((rh - MM.fontH(f3)) / 2), d.r, d.g, d.b, d.a or 1, f3)
            self:drawText(ZeD.Atoms.truncateText(n.name, f2, lw - T.px(30) - dw), lx + T.px(10), ry + math.floor((rh - MM.fontH(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
            local vy0, vy1 = math.max(ry, ly), math.min(ry + rh, ly + lh)
            local nid = n.id
            self._hits[#self._hits + 1] = { id = hid, x = ax + lx, y = ay + vy0, w = lw, h = vy1 - vy0, fn = function()
                -- (a second click on the picked note within 450 ms opens it, as on the desktop)
                local now = MM.now()
                if self.sel == nid and self._lastAt and now - self._lastAt < 450 then self:open(); return end
                self.sel, self._lastAt, self.focusId = nid, now, id
                MM.hoverSound()
            end }
        end
        local nid = n.id
        self._specs[#self._specs + 1] = { id = id, listRow = true, listId = "docs", clip = self._list, row = 10 + i, col = 1, x = lx, y = ry, w = lw, h = rh,
                                          chosen = isSel, fn = function() if self.sel == nid then self:open() else self.sel = nid; MM.hoverSound() end end }
    end
    self:clearStencilRect()
    local row = 1000
    local n = self.sel and N.get(self.sel)
    if self.confirm == "delete" then
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_delete"), function() self:delete() end, "danger", false, tr("UI_ZeD_Desk_HelpDelete") } },
            tr("UI_ZeD_Desk_AskDelete", n and n.name or ""))
    elseif self.confirm == "rename" then
        local valid, why = N.checkName(self.sel, self.renameEntry:getText() or "")
        local whyText = (why == "taken") and tr("UI_ZeD_Desk_NameTaken") or tr("UI_ZeD_Desk_NameEmpty")
        local fx = UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end },
            { "confirm:yes", getText("UI_btn_rename"), function() self:rename() end, "primary", valid == nil, valid and tr("UI_ZeD_Desk_HelpRename") or whyText } },
            tr("UI_ZeD_Desk_AskRename"), true)
        local firstBtn = w
        for _, b in ipairs(self._specs) do if b.row == row then firstBtn = math.min(firstBtn, b.x) end end
        local fh = T.px(24)
        local fw = math.max(T.px(80), firstBtn - T.px(12) - fx)
        UI.styleEntry(self.renameEntry, fx, stripY + math.floor((stripH - fh) / 2), fw, fh)
        self._specs[#self._specs + 1] = { id = "field:rename", listRow = true, noDraw = true, row = row, col = 0, x = fx, y = stripY + math.floor((stripH - fh) / 2), w = fw, h = fh,
                                          fn = function() MM.editField(self.renameEntry) end }
    else
        UI.stripSpecs(self, stripY, w, row, {},
            { { "rename", getText("UI_btn_rename"), function() self:startRename() end, "default", n == nil, tr("UI_ZeD_Desk_HelpRename") },
              { "delete", getText("UI_btn_delete"), function() self:setConfirm("delete") end, "default", n == nil, tr("UI_ZeD_Desk_HelpDelete") },
              { "open", getText("IGUI_Open"), function() self:open() end, "primary", n == nil, tr("UI_ZeD_Desk_HelpOpenDoc") } },
            tr("UI_ZeD_Desk_DocsCount", N.count(), N.MAX), true)
    end
end

function ZeD_MMDocs:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMDocs:joyB()
    if self.confirm then self:setConfirm(false); return end
    self:close()
end
function ZeD_MMDocs:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Cancel") } } end
    return { { glyph = "A", label = getText("IGUI_Open") }, { glyph = "B", label = getText("UI_Close") } }
end
function ZeD_MMDocs:keyEscape()
    if self.renameEntry:isFocused() then self.renameEntry:unfocus(); return true end
    self:joyB()
    return true
end
function ZeD_MMDocs:keyOther(key)
    if key == Keyboard.KEY_RETURN and not self.confirm then self:open(); return true end
    return false
end

function ZeD_MMDocs:wheel(del)
    local T = ZeD.T
    local r = self._list
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if not r or mx < r.x or my < r.y or mx > r.x + r.w or my > r.y + r.h then return false end
    self.scroll = self.scroll + del * T.px(ROW_H)
    return true
end
function ZeD_MMDocs:onMouseWheel(del) return MM.wheel(del) end
-- the wheel scrolls the list while Documents is up. Keep the base MM.wheel once, so a Lua reload never wraps
-- the wrapper.
local _wheel = MM._docsWheelBase or MM.wheel
MM._docsWheelBase = _wheel
function MM.wheel(del)
    if MM.view == "docs" and MM.root and MM.root.docsWin then return MM.root.docsWin:wheel(del) end
    return _wheel(del)
end

-- on the desk as the "docs" view (the Documents icon and CletusWorks' Open reach it through MM.openDocs)
MM.addView("docs", "docsWin", function() return ZeD_MMDocs:new() end)
