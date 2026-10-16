-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuDescEdit.lua
-- ============================================================================
-- THE DESCRIPTION EDITOR (director, Oct 16 2026: "edit descriptions with modern
-- layout controls for building communications that people will read cause
-- they can easily be worked on and made communicable and legible"; mockup
-- zed_mod_manager_v1, "boogie!")
--
-- A Workshop description as blocks (ZeD_WorkshopText): add a heading, text,
-- a list, a numbered list, a picture, a quote, code, a table, a divider, a
-- link or a spoiler from the palette, or a whole section readers look for
-- (Features, Requirements, Load order, Compatibility, Known issues,
-- Changelog, Credits). The picked block is edited in place; text blocks get
-- bold / italic / underline / strike / link, which put Steam's codes at the
-- cursor (the game's text boxes have no selection to wrap). Blocks move up
-- and down and go away with their icon buttons. On the right the description
-- the way Steam's page shows it, or as Steam's codes. The strip counts the
-- characters against Steam's 8,000, undoes and redoes, and hands the text back
-- to the upload window (Use this description) or drops it (Cancel).
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_WorkshopText"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local BB = ZeD.BB

-- design units
local PAL_SHARE, PREVIEW_SHARE = 0.2, 0.36
local CARD_PAD, CARD_GAP, HEAD_H, ICON_BTN = 8, 8, 24, 22
local HINT_MS = 450
local ICON = "media/textures/ZeD/icons/"

local function copyBlocks(bs)
    local out = {}
    for i, b in ipairs(bs) do out[i] = { kind = b.kind, text = b.text } end
    return out
end

-- ============================================================================
ZeD_MMDescEdit = ZeD_MMWindow:derive("ZeD_MMDescEdit")

function ZeD_MMDescEdit:new()
    local o = ZeD_MMWindow.new(self, "wsdesc")
    o.noResetControl = true
    o.blocks = {}
    o.sel = nil
    o.cscroll, o.pscroll = 0, 0
    o.view = "steam"        -- "steam" | "codes"
    o.undo, o.redo = {}, {}
    o.confirm = false
    return o
end

function ZeD_MMDescEdit:createChildren()
    ZeD_Window.createChildren(self)
    self.edit = UI.newEntry(self)
    self.edit:setMultipleLine(true)
    self.edit:setMaxLines(200)
    self.edit.onTextChange = function() self:typed() end
    self.edit.onEscape = function() self.edit:unfocus() end
    self.edit:setVisible(false)
end

function ZeD_MMDescEdit:onShow()
    local src = MM.wsEditor or { text = "" }
    self.src = src
    self.blocks = BB.parse(src.text or "")
    if #self.blocks == 0 then self.blocks = { { kind = "h1", text = (src.title ~= "" and src.title) or "Your mod" }, { kind = "text", text = "" } } end
    self.sel = 1
    self.cscroll, self.pscroll = 0, 0
    self.undo, self.redo = {}, {}
    self.confirm = false
    self.focusId = nil
    self:loadEdit()
end

-- the picked block's text into the entry
function ZeD_MMDescEdit:loadEdit()
    local b = self.blocks[self.sel or 0]
    self._loading = true
    self.edit:setText(b and b.text or "")
    self._loading = false
    self._typedSnap = false
end

function ZeD_MMDescEdit:snapshot()
    self.undo[#self.undo + 1] = { blocks = copyBlocks(self.blocks), sel = self.sel }
    if #self.undo > 100 then table.remove(self.undo, 1) end   -- (oldest goes first)
    self.redo = {}
end

function ZeD_MMDescEdit:typed()
    if self._loading then return end
    local b = self.blocks[self.sel or 0]
    if not b then return end
    if not self._typedSnap then self:snapshot(); self._typedSnap = true end   -- one undo step per block edited
    b.text = self.edit:getText()
end

function ZeD_MMDescEdit:select(i)
    if i == self.sel then return end
    self.sel = i
    self:loadEdit()
    MM.hoverSound()
end

function ZeD_MMDescEdit:restore(from, to)
    local s = table.remove(from)
    if not s then return end
    to[#to + 1] = { blocks = copyBlocks(self.blocks), sel = self.sel }
    self.blocks, self.sel = s.blocks, s.sel
    if self.sel and self.sel > #self.blocks then self.sel = #self.blocks end
    self:loadEdit()
    MM.clickSound()
end

-- a new block after the picked one
function ZeD_MMDescEdit:add(kind, text, quiet)
    if not quiet then self:snapshot() end
    local at = (self.sel or #self.blocks) + 1
    table.insert(self.blocks, at, { kind = kind, text = text or "" })
    self.sel = at
    self:loadEdit()
    self._scrollToSel = true
    if not quiet then MM.clickSound() end
end

function ZeD_MMDescEdit:addSection(s)
    self:snapshot()
    self:add("h2", s[1], true)
    self:add(s[2], s[3], true)
    MM.clickSound()
end

function ZeD_MMDescEdit:move(i, d)
    local j = i + d
    if j < 1 or j > #self.blocks then return end
    self:snapshot()
    self.blocks[i], self.blocks[j] = self.blocks[j], self.blocks[i]
    if self.sel == i then self.sel = j elseif self.sel == j then self.sel = i end
    self._scrollToSel = true
    MM.clickSound()
end

function ZeD_MMDescEdit:remove(i)
    self:snapshot()
    table.remove(self.blocks, i)
    if #self.blocks == 0 then self.sel = nil
    else self.sel = math.min(i, #self.blocks) end
    self:loadEdit()
    MM.clickSound()
end

function ZeD_MMDescEdit:setLevel(i, kind)
    local b = self.blocks[i]
    if not b or b.kind == kind then return end
    self:snapshot()
    b.kind = kind
    MM.clickSound()
end

-- Steam's codes at the cursor of the picked block, the cursor between them
function ZeD_MMDescEdit:wrapAtCursor(open, close)
    local e = self.edit
    local text = e:getText()
    local pos = 0
    pcall(function() pos = e:getCursorPos() end)
    pos = math.max(0, math.min(pos, #text))
    self:typed()
    self._loading = true
    e:setText(text:sub(1, pos) .. open .. close .. text:sub(pos + 1))
    self._loading = false
    local b = self.blocks[self.sel or 0]
    if b then b.text = e:getText() end
    e:focus()
    pcall(function() e:setCursorPos(pos + #open) end)
    MM.clickSound()
end

function ZeD_MMDescEdit:text() return BB.write(self.blocks) end

function ZeD_MMDescEdit:finish(keep)
    MM.clickSound()
    self.edit:unfocus()
    self.edit:setVisible(false)
    if keep and self.src and self.src.done then self.src.done(self:text()) end
    local ws = MM.root and MM.root.workshopWin
    if ws then ws._fromEditor = true end
    MM.showView("workshop")
end

function ZeD_MMDescEdit:back()
    if self.confirm then self.confirm = false; self.focusId = nil; MM.clickSound(); return end
    if self:text() ~= BB.write(BB.parse(self.src and self.src.text or "")) then
        self.confirm = "leave"; self.focusId = "confirm:yes"; MM.clickSound(); return
    end
    self:finish(false)
end

-- ----------------------------------------------------------------------------
-- DRAWING
-- ----------------------------------------------------------------------------
function ZeD_MMDescEdit:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    -- the box's text into its block every frame (its change call comes before the key lands)
    local cur = self.blocks[self.sel or 0]
    if cur and not self._loading and self.edit:getText() ~= cur.text then self:typed() end
    local w, h = UI.placeOnTube(self)
    local t = self.src and self.src.title or ""
    self.title = "Project Zomboid  +  Description" .. ((t ~= "") and (": " .. t) or "")
    self.titleStats = {}
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = T.px(U.STRIP_BTN_H) + T.px(U.STRIP_PAD_Y) * 2
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local inner = w - pad * 4
    local pw = math.floor(inner * PAL_SHARE)
    local vw = math.floor(inner * PREVIEW_SHARE)
    local cw = inner - pw - vw
    self:drawPalette(pad, bodyY, pw, bodyH)
    self:drawCanvas(pad * 2 + pw, bodyY, cw, bodyH)
    self:drawPreview(pad * 3 + pw + cw, bodyY, vw, bodyH)
    self:buildStrip(stripY, stripH, w)
end

function ZeD_MMDescEdit:render()
    UI.drawStripAndButtons(self, self._stripY, self._stripH, self._ask, self._askX)
    self:drawHint()
    ZeD_Window.render(self)
end

-- a column-wide button in the palette
function ZeD_MMDescEdit:palBtn(id, text, fn, x, y, w, row)
    local T = ZeD.T
    local bh = T.px(U.STRIP_BTN_H)
    self._specs[#self._specs + 1] = { id = id, text = text, fn = fn, variant = "default", row = row, col = 1, x = x, y = y, w = w, h = bh, keepCase = true }
    return y + bh + T.px(4)
end

function ZeD_MMDescEdit:drawPalette(x, y, w, h)
    local T = ZeD.T
    UI.insetBox(self, x, y, w, h)
    local la = T.accent
    local f1 = T.fontF1
    local ix, iw = x + T.px(8), w - T.px(16)
    local cy = y + T.px(8)
    self:drawText("ADD A BLOCK", ix, cy, la.r, la.g, la.b, la.a or 1, f1)
    cy = cy + MM.fontH(f1) + T.px(6)
    -- two to a row: the sections fit under them
    local half = math.floor((iw - T.px(4)) / 2)
    for i, k in ipairs(BB.KINDS) do
        local col = (i - 1) % 2
        local ny = self:palBtn("add:" .. k[1], k[2], function() self:add(k[1], k[3]) end, ix + col * (half + T.px(4)), cy, half, 100 + math.floor((i - 1) / 2))
        self._specs[#self._specs].col = col + 1
        if col == 1 or i == #BB.KINDS then cy = ny end
    end
    cy = cy + T.px(8)
    self:drawText("ADD A SECTION", ix, cy, la.r, la.g, la.b, la.a or 1, f1)
    cy = cy + MM.fontH(f1) + T.px(6)
    for i, s in ipairs(BB.SECTIONS) do
        if cy + T.px(U.STRIP_BTN_H) > y + h - T.px(4) then break end
        cy = self:palBtn("sec:" .. i, s[1], function() self:addSection(s) end, ix, cy, iw, 200 + i)
    end
end

-- a small button in a card's head; icon ones carry a hint
function ZeD_MMDescEdit:headBtn(id, x, y, opts)
    local T = ZeD.T
    local sz = T.px(ICON_BTN)
    local w = opts.text and (MM.textW(T.fontF3, opts.text) + T.px(12)) or sz
    local b = { id = id, x = x - w, y = y, w = w, h = sz, fn = opts.fn, variant = opts.variant or "default", row = opts.row, col = opts.col,
                icon = opts.icon, text = opts.text or "", hint = opts.hint, on = opts.on, keepCase = true, disabled = opts.disabled,
                clipTop = self._cv.y, clipBot = self._cv.y + self._cv.h }
    if opts.on and opts.text then b.variant = "primary" end
    self._specs[#self._specs + 1] = b
    return x - w - T.px(4)
end

-- a block's height on the canvas (its body as Steam shows it, or the entry while picked)
function ZeD_MMDescEdit:bodyH(b, i, w)
    local T = ZeD.T
    if i == self.sel then
        local n = 0
        for _, l in ipairs(BB.lines(b.text)) do n = n + math.max(1, #ZeD.Atoms.wrapText(l, self.edit.font and T.fontF2 or T.fontF2, w - T.px(12))) end
        local lh = MM.fontH(T.fontF2) + T.px(2)
        return math.max(2, n + 1) * lh + T.px(8)
    end
    return BB.drawBlock(nil, b, 0, 0, w)
end

local KIND_LABEL = { h1 = "HEADING", h2 = "HEADING", h3 = "HEADING", text = "TEXT", list = "LIST", olist = "NUMBERED LIST", img = "PICTURE",
                     quote = "QUOTE", code = "CODE", table = "TABLE", divider = "DIVIDER", url = "LINK", spoiler = "SPOILER" }
local HOW = { list = "One point per line", olist = "One step per line", table = "One row per line, cells split by \" | \"; the first row is the header",
              url = "The address on the first line, the words to show on the second", img = "The picture's address (Steam shows pictures from the web)" }
local INLINE = { text = true, list = true, olist = true, quote = true, table = true, spoiler = true }

function ZeD_MMDescEdit:drawCanvas(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    self._cv = { x = x, y = y + T.px(1), w = w, h = h - T.px(2) }
    local pad = T.px(CARD_PAD)
    local cx, cw = x + T.px(8), w - T.px(16)
    local bodyW = cw - pad * 2
    local f1, f3, dim, ac = T.fontF1, T.fontF3, T.textDim, T.accent
    -- the cards' heights first: the picked one is kept in view
    local hs, total = {}, T.px(8)
    for i, b in ipairs(self.blocks) do
        local hh = T.px(HEAD_H) + self:bodyH(b, i, bodyW) + pad * 2
        if i == self.sel and HOW[b.kind] then hh = hh + MM.fontH(f3) + T.px(4) end
        hs[i] = hh
        total = total + hh + T.px(CARD_GAP)
    end
    if self._scrollToSel and self.sel then
        local top = T.px(8)
        for i = 1, self.sel - 1 do top = top + hs[i] + T.px(CARD_GAP) end
        if top < self.cscroll then self.cscroll = top - T.px(8)
        elseif top + hs[self.sel] > self.cscroll + h then self.cscroll = top + hs[self.sel] - h + T.px(8) end
        self._scrollToSel = false
    end
    self.cscroll = math.max(0, math.min(self.cscroll, math.max(0, total - h)))
    self:setStencilRect(x + T.px(1), y + T.px(1), w - T.px(2), h - T.px(2))
    local cy = y + T.px(8) - self.cscroll
    local editShown = false
    local gp = MM.gamepad()
    for i, b in ipairs(self.blocks) do
        local hh = hs[i]
        local isSel = i == self.sel
        local s1, bs = T.surf1, isSel and ac or T.borderS
        self:drawRect(cx, cy, cw, hh, 1, s1.r, s1.g, s1.b)
        self:drawRectBorder(cx, cy, cw, hh, isSel and 1 or bs.a, bs.r, bs.g, bs.b)
        if gp and self.focusId == "card:" .. i then self:drawRect(cx, cy, cw, hh, 0.22, ac.r, ac.g, ac.b) end
        -- the head: what it is, then its buttons from the right
        local hy = cy + pad
        local lab = KIND_LABEL[b.kind] or string.upper(b.kind)
        self:drawText(lab, cx + pad, hy + math.floor((T.px(ICON_BTN) - MM.fontH(f1)) / 2), ac.r, ac.g, ac.b, ac.a or 1, f1)
        local bx = cx + cw - pad
        local row = 1000 + i * 2
        bx = self:headBtn("del:" .. i, bx, hy, { icon = ICON .. "cross-small.png", hint = "Remove this block", fn = function() self:remove(i) end, row = row, col = 9, variant = "danger" })
        bx = self:headBtn("dn:" .. i, bx, hy, { icon = ICON .. "arrow-down.png", hint = "Move down", fn = function() self:move(i, 1) end, row = row, col = 8, disabled = i == #self.blocks })
        bx = self:headBtn("up:" .. i, bx, hy, { icon = ICON .. "arrow-up.png", hint = "Move up", fn = function() self:move(i, -1) end, row = row, col = 7, disabled = i == 1 })
        if isSel and (b.kind == "h1" or b.kind == "h2" or b.kind == "h3") then
            bx = bx - T.px(6)
            for lv = 3, 1, -1 do
                local k = "h" .. lv
                bx = self:headBtn("lv:" .. i .. ":" .. lv, bx, hy, { text = "H" .. lv, on = b.kind == k, fn = function() self:setLevel(i, k) end, row = row, col = lv + 2 })
            end
        elseif isSel and INLINE[b.kind] then
            bx = bx - T.px(6)
            local marks = { { "LINK", "[url=https://]", "[/url]", "Link: put the address after the =" }, { "S", "[strike]", "[/strike]", "Strike through" },
                            { "U", "[u]", "[/u]", "Underline" }, { "I", "[i]", "[/i]", "Italic" }, { "B", "[b]", "[/b]", "Bold" } }
            for mi, mk in ipairs(marks) do
                bx = self:headBtn("mk:" .. i .. ":" .. mi, bx, hy, { text = mk[1], hint = mk[4], fn = function() self:wrapAtCursor(mk[2], mk[3]) end, row = row, col = 7 - mi })
            end
        end
        -- the body
        local by = hy + T.px(HEAD_H)
        local bodyH = hh - (by - cy) - pad
        if isSel then
            local eh = self:bodyH(b, i, bodyW)
            local inView = by >= y + T.px(1) and by + eh <= y + h - T.px(1)
            if inView then
                UI.styleEntry(self.edit, cx + pad, by, bodyW, eh)
                editShown = true
            end
            if HOW[b.kind] then self:drawText(HOW[b.kind], cx + pad, by + eh + T.px(4), dim.r, dim.g, dim.b, dim.a or 1, f3) end
        elseif by + bodyH > y and by < y + h then
            BB.drawBlock(self, b, cx + pad, by, bodyW)
        end
        -- the card answers a click and the controller (A types in it)
        local cid = "card:" .. i
        self._specs[#self._specs + 1] = { id = cid, listRow = true, x = cx, y = cy, w = cw, h = T.px(HEAD_H) + pad, clipTop = self._cv.y, clipBot = self._cv.y + self._cv.h,
                                          fn = function() self:select(i); self.edit:focus() end, chosen = isSel }
        local vy0, vy1 = math.max(cy, y), math.min(cy + hh, y + h)
        if vy1 > vy0 and not (isSel and editShown) then
            self._hits[#self._hits + 1] = { id = "wsd:card:" .. i, x = ax + cx, y = ay + vy0, w = cw, h = vy1 - vy0, fn = function() self:select(i); self.focusId = cid end }
        elseif vy1 > vy0 then   -- (the picked card: its head only; the entry takes its own clicks)
            self._hits[#self._hits + 1] = { id = "wsd:card:" .. i, x = ax + cx, y = ay + vy0, w = cw, h = math.max(0, math.min(by, vy1) - vy0), fn = function() self.focusId = cid end }
        end
        cy = cy + hh + T.px(CARD_GAP)
    end
    if #self.blocks == 0 then
        self:drawText("Empty. Add a block from the left.", cx, y + T.px(12), dim.r, dim.g, dim.b, dim.a or 1, T.fontF2)
    end
    self:clearStencilRect()
    if self.edit:isVisible() ~= editShown then self.edit:setVisible(editShown) end
end

function ZeD_MMDescEdit:drawPreview(x, y, w, h)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    local bs, s2 = T.borderS, T.surf2
    -- the two views as folder tabs
    local tH = T.tabH + T.px(6)
    self:drawRect(x, y, w, tH, 1, s2.r, s2.g, s2.b)
    local tx = x + T.px(8)
    for _, t in ipairs({ { "steam", "As Steam shows it" }, { "codes", "Steam codes" } }) do
        local hid = "wsd:tab:" .. t[1]
        local tw = ZeD.Molecules.drawTab(self, tx, y + tH - T.tabH, t[2], self.view == t[1], MM.ctx.hot == hid, false)
        self._hits[#self._hits + 1] = { id = hid, x = ax + tx, y = ay + y + tH - T.tabH, w = tw, h = T.tabH, fn = function()
            if self.view ~= t[1] then self.view = t[1]; self.pscroll = 0; MM.clickSound() end end }
        self._specs[#self._specs + 1] = { id = "view:" .. t[1], listRow = true, x = tx, y = y + tH - T.tabH, w = tw, h = T.tabH,
                                          fn = function() self.view = t[1]; self.pscroll = 0 end }
        tx = tx + tw + T.sp.tabGap
    end
    local py, ph = y + tH, h - tH
    -- Steam's page is dark whatever the theme: the preview keeps the base fill
    local b = T.base
    self:drawRect(x, py, w, ph, 1, b.r, b.g, b.b)
    self:drawRectBorder(x, py, w, ph, bs.a, bs.r, bs.g, bs.b)
    self._pv = { x = x, y = py, w = w, h = ph }
    local pad = T.px(12)
    self:setStencilRect(x + T.px(1), py + T.px(1), w - T.px(2), ph - T.px(2))
    local cy = py + pad - self.pscroll
    if self.view == "steam" then
        for _, blk in ipairs(self.blocks) do
            local bh = BB.drawBlock(nil, blk, 0, 0, w - pad * 2)
            if cy + bh > py and cy < py + ph then BB.drawBlock(self, blk, x + pad, cy, w - pad * 2) end
            cy = cy + bh + BB.gap(blk)
        end
    else
        local f3, c = T.fontF3, T.text
        for _, l in ipairs(BB.lines(self:text())) do
            for _, wl in ipairs((l == "") and { "" } or ZeD.Atoms.wrapText(l, f3, w - pad * 2)) do
                if cy + MM.fontH(f3) > py and cy < py + ph then self:drawText(wl, x + pad, cy, c.r, c.g, c.b, c.a or 1, f3) end
                cy = cy + MM.fontH(f3) + T.px(2)
            end
        end
    end
    self:clearStencilRect()
    local total = cy + self.pscroll - py + pad
    self.pscroll = math.max(0, math.min(self.pscroll, math.max(0, total - ph)))
end

function ZeD_MMDescEdit:buildStrip(stripY, stripH, w)
    local T = ZeD.T
    local row = 1000000
    local ask
    self._askX = nil
    if self.confirm == "leave" then
        ask = "Keep the changes to the description?"
        UI.stripSpecs(self, stripY, w, row, {}, {
            { "confirm:no", "DISCARD", function() self:finish(false) end },
            { "confirm:yes", "KEEP", function() self:finish(true) end, "primary" } })
    else
        local n = #self:text()
        local over = n > BB.LIMIT
        local askX = UI.stripSpecs(self, stripY, w, row,
            { { "undo", "UNDO", function() self:restore(self.undo, self.redo) end, "default", #self.undo == 0 },
              { "redo", "REDO", function() self:restore(self.redo, self.undo) end, "default", #self.redo == 0 } },
            { { "cancel", "CANCEL", function() self:back() end },
              { "use", "USE THIS DESCRIPTION", function() self:finish(true) end, "primary", over } })
        ask = BB.count(n) .. " of " .. BB.count(BB.LIMIT) .. " characters" .. (over and ": too long for Steam" or "")
        self._askX = askX + T.px(8)
        self._askBad = over
    end
    self._stripY, self._stripH, self._ask = stripY, stripH, ask
end

-- the words of an icon button, once the pointer rests on it
function ZeD_MMDescEdit:drawHint()
    local hot = MM.ctx.hot
    if hot ~= self._hintId then self._hintId = hot; self._hintAt = MM.now() end
    if not hot or MM.gamepad() or MM.now() - (self._hintAt or 0) < HINT_MS then return end
    for _, b in ipairs(self._specs) do
        if b.hint and hot == self.kind .. ":" .. b.id then
            local T = ZeD.T
            local f = T.fontF3
            local tw = MM.textW(f, b.hint) + T.px(12)
            local th = MM.fontH(f) + T.px(8)
            local hx = math.max(T.px(4), math.min(b.x + b.w - tw, self.width - tw - T.px(4)))
            local hy = b.y - th - T.px(4)
            local s2, bs, c = T.surf2, T.borderS, T.text
            self:drawRect(hx, hy, tw, th, 1, s2.r, s2.g, s2.b)
            self:drawRectBorder(hx, hy, tw, th, bs.a, bs.r, bs.g, bs.b)
            self:drawText(b.hint, hx + T.px(6), hy + T.px(4), c.r, c.g, c.b, c.a or 1, f)
            return
        end
    end
end

-- ----------------------------------------------------------------------------
-- KEYS, CONTROLLER, WHEEL
-- ----------------------------------------------------------------------------
function ZeD_MMDescEdit:joyB() self:back() end
function ZeD_MMDescEdit:keyEscape()
    if self.edit:isFocused() then self.edit:unfocus(); return true end
    self:back()
    return true
end
function ZeD_MMDescEdit:keyOther(key) return false end
function ZeD_MMDescEdit:close() self:back() end

function ZeD_MMDescEdit:wheel(del)
    local T = ZeD.T
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local function inside(r) return r and mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h end
    if inside(self._cv) then self.cscroll = self.cscroll + del * T.px(40); return true end
    if inside(self._pv) then self.pscroll = self.pscroll + del * T.px(40); return true end
    return false
end
function ZeD_MMDescEdit:onMouseWheel(del) return MM.wheel(del) end
local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "wsdesc" and MM.root and MM.root.wsdescWin then return MM.root.wsdescWin:wheel(del) end
    return _wheel(del)
end

MM.addView("wsdesc", "wsdescWin", function() return ZeD_MMDescEdit:new() end)
