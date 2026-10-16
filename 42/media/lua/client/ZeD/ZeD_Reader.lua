-- ZeD-UI/42/media/lua/client/ZeD/ZeD_Reader.lua
-- ============================================================================
-- THE READER (HOOK_MAP rows 13 and 24; mockup zed_reader_v2, director Oct 16
-- 2026: "Both full and character menu are needed")
--
-- The full reader: a ZeD window of its own over the game (the Character
-- window's drawer is too narrow for a newspaper page), opened where vanilla
-- opens its print media window, when the Read action finishes
-- (Overrides/PrintMedia.lua). Reading stays vanilla's action; only how the
-- piece is shown changes.
--
--   * Paper: the piece as the paper prints it, its stories set by ZeD
--     (ZeD_PrintPage), zoom (the wheel, the strip's - / +) and drag.
--   * Words: the same piece as a clean page in ZeD's faces: headlines as
--     headings, stories as paragraphs, pictures as their captions.
--   * The side column: what it is (kind, date, read), the stories on the page
--     (a press jumps to it in Words), its places with vanilla's Show on map.
--
-- Controller: LB / RB Paper and Words; the D-pad moves the paper (or scrolls
-- the words); Y / X zoom in and out; A shows the first place on the map; B
-- closes. Escape closes.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/Organisms"
require "ZeD/ZeD_PrintPage"

ZeD = ZeD or {}
ZeD.Reader = ZeD.Reader or {}
local R = ZeD.Reader
local P = ZeD.Print
R.windows = R.windows or {}

-- design units (1 px at 1080p; T.px scales them)
local U = { W = 1180, H = 980, PAD = 10, SIDE = 270, STRIP_H = 40, BTN_H = 24, BTN_PAD = 10, GAP = 8,
            PAGE_W = 700, PAGE_PAD = 40, ROW_PAD = 8, SEG_PAD = 12 }
local ZOOMS = { 1, 1.25, 1.5, 2, 2.5, 3 }
-- the page's paper and ink (a printed page reads the same on every theme)
local PAPER = { r = 0.91, g = 0.886, b = 0.824 }
local INK   = { r = 0.141, g = 0.133, b = 0.118 }
local INK_DIM = { r = 0.424, g = 0.404, b = 0.361 }

local function fh(font) return ZeD.TM:getFontHeight(font) end
local function tw(font, s) return ZeD.TM:MeasureStringX(font, s) end
local function inRect(r, x, y) return r and x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h end
local function sound(name) pcall(function() getSoundManager():playUISound(name or "UIActivateButton") end) end

-- ============================================================================
ZeD_Reader = ZeD_Window:derive("ZeD_Reader")

function ZeD_Reader:new(character)
    local o = ZeD_Window.new(self, 0, 0, 100, 100, "")
    o.resizable = false
    o.themeFooter = false
    o.pin = true
    o.character = character
    o.playerNum = character:getPlayerNum()
    o.view = "paper"
    o.zoomIx = 1
    o.panX, o.panY = 0, 0
    o.wscroll = 0
    o.storyIx = nil
    o._hits = {}
    o:setWantKeyEvents(true)
    return o
end

function ZeD_Reader:createChildren()
    ZeD_Window.createChildren(self)
    self.minimumWidth, self.minimumHeight = 0, 0
end

-- a printed piece (an item with modData.printMedia)
function ZeD_Reader:setPrint(item)
    self.mode = "print"
    self.item = item
    self.media = P.media(item)
    self.page = P.page(self.media)
    self.words = P.words(self.media)
    self.places = P.places(self.media)
    self.view = self.page and "paper" or "words"
    self.zoomIx, self.panX, self.panY, self.wscroll, self.storyIx = 1, 0, 0, 0, nil
end

function ZeD_Reader:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum + 1] then setJoypadFocus(self.playerNum, nil) end
end

-- ---------------------------------------------------------------------------
-- LAYOUT
-- ---------------------------------------------------------------------------
function ZeD_Reader:place()
    local T = ZeD.T
    local sx, sy = getPlayerScreenLeft(self.playerNum), getPlayerScreenTop(self.playerNum)
    local sw, sh = getPlayerScreenWidth(self.playerNum), getPlayerScreenHeight(self.playerNum)
    local w = math.min(T.px(U.W), sw - T.px(60))
    local h = math.min(T.px(U.H), sh - T.px(40))
    if self.width ~= w or self.height ~= h then
        self:setWidth(w); self:setHeight(h)
        self:setX(sx + math.floor((sw - w) / 2)); self:setY(sy + math.floor((sh - h) / 2))
    end
end

function ZeD_Reader:layout()
    local T = ZeD.T
    local pad = T.px(U.PAD)
    local top = self:titleBarHeight() + pad
    local stripH = T.px(U.STRIP_H)
    local stripY = self.height - stripH
    local side = T.px(U.SIDE)
    local g = {}
    g.strip = { x = 0, y = stripY, w = self.width, h = stripH }
    g.side = { x = self.width - pad - side, y = top, w = side, h = stripY - pad - top }
    g.canvas = { x = pad, y = top, w = g.side.x - pad - pad, h = stripY - pad - top }
    self._g = g
    return g
end

-- ---------------------------------------------------------------------------
-- DRAWING
-- ---------------------------------------------------------------------------
function ZeD_Reader:prerender()
    local T = ZeD.T
    if not T then return end
    self:place()
    self._hits = {}
    local who = self.character:getDescriptor()
    local name = who and (who:getForename() .. " " .. who:getSurname()) or ""
    self.title = name .. "  +  " .. P.title(self.media)
    local read = self:isRead()
    self.titleStats = read and { { text = "Read", color = T.positive } } or {}
    local g = self:layout()
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    local bs = T.borderS
    -- the canvas
    local c = g.canvas
    self:drawRect(c.x, c.y, c.w, c.h, 1, 0.035, 0.043, 0.039)
    self:drawRectBorder(c.x, c.y, c.w, c.h, bs.a, bs.r, bs.g, bs.b)
    self:setStencilRect(c.x + 1, c.y + 1, c.w - 2, c.h - 2)
    if self.view == "paper" and self.page then self:drawPaper(c) else self:drawWords(c) end
    self:clearStencilRect()
    self:drawSide(g.side)
    self:drawStrip(g.strip)
end

function ZeD_Reader:paperScale(c)
    local pg = self.page
    local fit = math.min((c.w - 2) / pg.w, (c.h - 2) / pg.h)
    return fit * ZOOMS[self.zoomIx]
end

function ZeD_Reader:drawPaper(c)
    local pg = self.page
    local k = self:paperScale(c)
    local pw, ph = pg.w * k, pg.h * k
    -- the pan keeps some of the page in view
    local mx, my = math.max(0, (pw - c.w) / 2 + 40), math.max(0, (ph - c.h) / 2 + 40)
    self.panX = math.max(-mx, math.min(mx, self.panX))
    self.panY = math.max(-my, math.min(my, self.panY))
    local ox = c.x + math.floor((c.w - pw) / 2 + self.panX)
    local oy = c.y + math.floor((c.h - ph) / 2 + self.panY)
    P.draw(self, pg, ox, oy, k)
    self._hits[#self._hits + 1] = { id = "canvas", x = c.x, y = c.y, w = c.w, h = c.h, drag = true }
end

-- the words: a clean page in ZeD's faces, scrolled as one
function ZeD_Reader:drawWords(c)
    local T = ZeD.T
    local pw = math.min(T.px(U.PAGE_W), c.w - T.px(36))
    local px = c.x + math.floor((c.w - pw) / 2)
    local pad = T.px(U.PAGE_PAD)
    local f2, f3, f4 = T.fontF2, T.fontF3, T.fontF4
    local tw0 = pw - pad * 2
    local A = ZeD.Atoms
    -- measure, then draw (the page is as tall as its words)
    local function run(drawIt, y0)
        local y = y0 + pad
        local hf = ZeD.Font.sdf.head
        local z = 26 * (T.scale or 1) / (hf.face or 64)
        local tl = P.title(self.media)
        if drawIt then ZeD.Text.draw(self, hf, tl, px + pad, y, z, INK.r, INK.g, INK.b, 1, "l") end
        y = y + math.floor(ZeD.Text.height(hf, z)) + T.px(6)
        if drawIt then self:drawRect(px + pad, y, tw0, T.px(2), 1, INK.r, INK.g, INK.b) end
        y = y + T.px(14)
        self._storyY = {}
        local storyN = 0
        for _, b in ipairs(self.words) do
            if b.kind == "head" then
                storyN = storyN + 1
                self._storyY[storyN] = y - y0
                y = y + T.px(10)
                for _, l in ipairs(A.wrapText(b.text, f4, tw0)) do
                    if drawIt then self:drawText(l, px + pad, y, INK.r, INK.g, INK.b, 1, f4) end
                    y = y + fh(f4) + T.px(2)
                end
                y = y + T.px(6)
            elseif b.kind == "pic" then
                local lines = A.wrapText("Picture: " .. b.text, f3, tw0 - T.px(16))
                local bh = #lines * (fh(f3) + T.px(2)) + T.px(12)
                if drawIt then
                    self:drawRect(px + pad, y, tw0, bh, 1, 0.867, 0.839, 0.765)
                    self:drawRectBorder(px + pad, y, tw0, bh, 1, 0.706, 0.671, 0.584)
                    local yy = y + T.px(6)
                    for _, l in ipairs(lines) do self:drawText(l, px + pad + T.px(8), yy, INK_DIM.r, INK_DIM.g, INK_DIM.b, 1, f3); yy = yy + fh(f3) + T.px(2) end
                end
                y = y + bh + T.px(10)
            elseif b.kind == "kicker" or b.kind == "cont" then
                for _, l in ipairs(A.wrapText(b.text, f3, tw0)) do
                    if drawIt then self:drawText(l, px + pad, y, INK_DIM.r, INK_DIM.g, INK_DIM.b, 1, f3) end
                    y = y + fh(f3) + T.px(2)
                end
                y = y + T.px(8)
            else
                local text = b.dateline and (b.dateline .. " - " .. b.text) or b.text
                local first = true
                for _, l in ipairs(A.wrapText(text, f2, tw0)) do
                    if drawIt then
                        self:drawText(l, px + pad, y, INK.r, INK.g, INK.b, 1, f2)
                        -- the dateline in bold: drawn again a pixel over
                        if first and b.dateline then self:drawText(b.dateline, px + pad + 1, y, INK.r, INK.g, INK.b, 1, f2) end
                    end
                    first = false
                    y = y + fh(f2) + T.px(3)
                end
                y = y + T.px(8)
            end
        end
        return y + pad - y0
    end
    local total = run(false, 0)
    local top = c.y + T.px(14)
    local view = c.h - T.px(14)
    self.wscroll = math.max(0, math.min(self.wscroll, math.max(0, total - view)))
    local y0 = top - self.wscroll
    self:drawRect(px, y0, pw, total, 1, PAPER.r, PAPER.g, PAPER.b)
    run(true, y0)
    -- the scroll bar (the page scrolls as one)
    if total > view then
        local sb = T.sp.scrollbarW
        local sx = c.x + c.w - sb - 1
        ZeD.Atoms.drawScrollTrack(self, sx, c.y + 1, sb, c.h - 2)
        local th = math.max(T.px(24), math.floor((c.h - 2) * view / total))
        local ty = c.y + 1 + math.floor((c.h - 2 - th) * self.wscroll / (total - view))
        ZeD.Atoms.drawScrollThumb(self, sx, ty, sb, th, "default")
    end
    self._hits[#self._hits + 1] = { id = "canvas", x = c.x, y = c.y, w = c.w, h = c.h }
end

-- a section label with its rule
local function section(self, label, x, y, w)
    local T = ZeD.T
    local la = T.accent
    self:drawText(label, x, y, la.r, la.g, la.b, la.a or 1, T.fontF1)
    local h = fh(T.fontF1) + T.px(3)
    self:drawRect(x, y + h, w, 1, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    return y + h + T.px(6)
end

function ZeD_Reader:isRead()
    local m = self.media
    if not m then return false end
    -- (vanilla records a read by the piece's id: Read's complete, addReadPrintMedia)
    local ok, r = pcall(function() return self.character:isPrintMediaRead(m.id) or self.character:isPrintMediaRead(m.title) end)
    return ok and r or false
end

function ZeD_Reader:drawSide(s)
    local T = ZeD.T
    local bs, s1 = T.borderS, T.surf1
    self:drawRect(s.x, s.y, s.w, s.h, 1, s1.r, s1.g, s1.b)
    self:drawRectBorder(s.x, s.y, s.w, s.h, bs.a, bs.r, bs.g, bs.b)
    local pad = T.px(12)
    local x, w = s.x + pad, s.w - pad * 2
    local y = s.y + pad
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local tc, td, ac = T.text, T.textDim, T.accent
    -- THIS PIECE
    y = section(self, "THIS PIECE", x, y, w)
    local function kv(k, v, dot)
        self:drawText(k, x, y + 2, ac.r, ac.g, ac.b, ac.a or 1, f1)
        local vx = x + T.px(64)
        if dot then
            local dsz = T.px(7)
            ZeD.Atoms.drawStatusDot(self, vx, y + math.floor((fh(f2) - dsz) / 2), dot, dsz)
            vx = vx + dsz + T.px(6)
        end
        self:drawText(ZeD.Atoms.truncateText(v, f2, x + w - vx), vx, y, tc.r, tc.g, tc.b, tc.a or 1, f2)
        y = y + fh(f2) + T.px(5)
    end
    kv("KIND", P.kind(self.item))
    local date = P.title(self.media):match(" %- (.+)$")
    if date then kv("DATE", date) end
    local read = self:isRead()
    kv("READ", read and "Yes" or "Not yet", read and T.positive or T.textDim)
    y = y + T.px(10)
    -- ON THIS PAGE: its stories (a press jumps to it in Words)
    local heads = P.headlines(self.page)
    if #heads > 0 then
        y = section(self, "ON THIS PAGE", x, y, w)
        for i, h in ipairs(heads) do
            local lines = ZeD.Atoms.wrapText(h, f2, w - T.px(12))
            local rh = #lines * (fh(f2) + T.px(2)) + T.px(U.ROW_PAD) * 2
            if y + rh > s.y + s.h - pad then break end
            local id = "story:" .. i
            local on = (self.view == "words" and self.storyIx == i)
            local hot = self._hot == id
            if on then self:drawRect(x - T.px(4), y, w + T.px(8), rh, 0.22, ac.r, ac.g, ac.b)
            elseif hot then self:drawRect(x - T.px(4), y, w + T.px(8), rh, 0.12, ac.r, ac.g, ac.b) end
            local ly = y + T.px(U.ROW_PAD)
            for _, l in ipairs(lines) do self:drawText(l, x + T.px(2), ly, tc.r, tc.g, tc.b, tc.a or 1, f2); ly = ly + fh(f2) + T.px(2) end
            self:drawRect(x - T.px(4), y + rh - 1, w + T.px(8), 1, T.border.a, T.border.r, T.border.g, T.border.b)
            self._hits[#self._hits + 1] = { id = id, x = x - T.px(4), y = y, w = w + T.px(8), h = rh, fn = function() self:jumpTo(i) end }
            y = y + rh
        end
        y = y + T.px(12)
    end
    -- PLACES: vanilla's Show on map
    if #self.places > 0 then
        y = section(self, "PLACES", x, y, w)
        for i, loc in ipairs(self.places) do
            local label = (#self.places == 1) and P.title(self.media) or ("Place " .. i)
            local bh = T.px(U.BTN_H)
            local boxH = fh(f2) + T.px(8) + bh + T.px(16)
            if y + boxH > s.y + s.h - pad then break end
            self:drawRect(x, y, w, boxH, 1, T.base.r, T.base.g, T.base.b)
            self:drawRectBorder(x, y, w, boxH, bs.a, bs.r, bs.g, bs.b)
            self:drawText(ZeD.Atoms.truncateText(label, f2, w - T.px(16)), x + T.px(8), y + T.px(8), tc.r, tc.g, tc.b, tc.a or 1, f2)
            local text = "Show on map"
            local bw = tw(T.fontF3, text) + T.px(U.BTN_PAD) * 2
            local b = { x = x + T.px(8), y = y + T.px(8) + fh(f2) + T.px(6), w = bw, h = bh }
            local id = "place:" .. i
            ZeD.Molecules.drawButton(self, b.x, b.y, b.w, b.h, text, "primary", self._down == id,
                (self._hot == id) and { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.22 }, keepCase = true } or { keepCase = true })
            self._hits[#self._hits + 1] = { id = id, x = b.x, y = b.y, w = b.w, h = b.h, fn = function() self:showPlace(i) end }
            y = y + boxH + T.px(8)
        end
    end
end

-- the strip: Back, Paper | Words, and the zoom on Paper
function ZeD_Reader:drawStrip(st)
    local T = ZeD.T
    local s2 = T.surf2
    self:drawRect(1, st.y, st.w - 2, st.h, s2.a or 1, s2.r, s2.g, s2.b)
    ZeD.Atoms.drawDividerH(self, 1, st.y, st.w - 2, false)
    local bh = T.px(U.BTN_H)
    local by = st.y + math.floor((st.h - bh) / 2)
    local x = T.px(U.PAD)
    local ac = T.accent
    local function btn(id, text, fn, variant, on)
        local bw = tw(T.fontF3, ZeD.btnCase(text)) + T.px(U.BTN_PAD) * 2
        local colors = nil
        if on then colors = { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.55 } }
        elseif self._hot == id then colors = { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.22 } } end
        ZeD.Molecules.drawButton(self, x, by, bw, bh, text, variant or "default", self._down == id, colors)
        self._hits[#self._hits + 1] = { id = id, x = x, y = by, w = bw, h = bh, fn = fn }
        x = x + bw + T.px(U.GAP)
        return bw
    end
    btn("back", "BACK", function() self:close() end)
    x = x + T.px(6)
    if self.page then
        btn("view:paper", "PAPER", function() self:setView("paper") end, "default", self.view == "paper")
        x = x - T.px(U.GAP) + 1
        btn("view:words", "WORDS", function() self:setView("words") end, "default", self.view == "words")
    end
    if self.view == "paper" and self.page then
        -- the zoom, at the right
        local f3 = T.fontF3
        local pct = math.floor(ZOOMS[self.zoomIx] * 100) .. "%"
        local nw = tw(f3, "300%") + T.px(12)
        local sq = bh
        x = st.w - T.px(U.PAD) - sq * 2 - nw - T.px(U.GAP) * 2
        btn("zoom:out", "-", function() self:zoom(-1) end)
        local tc = T.textDim
        self:drawText(pct, x + math.floor((nw - tw(f3, pct)) / 2), by + math.floor((bh - fh(f3)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f3)
        x = x + nw + T.px(U.GAP)
        btn("zoom:in", "+", function() self:zoom(1) end)
    end
end

function ZeD_Reader:render()
    ZeD_Window.render(self)
end

-- ---------------------------------------------------------------------------
-- ACTIONS
-- ---------------------------------------------------------------------------
function ZeD_Reader:setView(v)
    if self.view == v then return end
    self.view = v
    sound("UISelectListItem")
end

function ZeD_Reader:zoom(d)
    local i = math.max(1, math.min(#ZOOMS, self.zoomIx + d))
    if i ~= self.zoomIx then
        local k = ZOOMS[i] / ZOOMS[self.zoomIx]
        self.panX, self.panY = self.panX * k, self.panY * k
        self.zoomIx = i
        sound("UISelectListItem")
    end
end

function ZeD_Reader:jumpTo(i)
    self.view = "words"
    self.storyIx = i
    -- (the heading's place is known once the words have been laid out: next frame)
    self._jump = i
    sound("UISelectListItem")
end

function ZeD_Reader:showPlace(i)
    local loc = self.places[i]
    if not loc then return end
    sound("UIActivateButton")
    P.showOnMap(self.character, loc)
    self:close()
end

-- ---------------------------------------------------------------------------
-- MOUSE (top level: hit-tested here)
-- ---------------------------------------------------------------------------
function ZeD_Reader:hitAt(x, y)
    for i = #self._hits, 1, -1 do
        local h = self._hits[i]
        if inRect(h, x, y) then return h end
    end
    return nil
end

function ZeD_Reader:onMouseDown(x, y)
    if not self:getIsVisible() then return true end
    local cb = self:closeRect()
    if cb and inRect(cb, x, y) then self._down = "close"; return true end
    if y < self:titleBarHeight() then return ZeD_Window.onMouseDown(self, x, y) end
    local h = self:hitAt(x, y)
    if h and h.drag then
        self._drag = { x = getMouseX(), y = getMouseY(), px = self.panX, py = self.panY }
        self:setCapture(true)
        return true
    end
    if h and h.fn then self._down = h.id end
    return true
end

function ZeD_Reader:onMouseMove(dx, dy)
    if self._drag then
        self.panX = self._drag.px + (getMouseX() - self._drag.x)
        self.panY = self._drag.py + (getMouseY() - self._drag.y)
        return true
    end
    return ZeD_Window.onMouseMove(self, dx, dy)
end
function ZeD_Reader:onMouseMoveOutside(dx, dy)
    if self._drag then return self:onMouseMove(dx, dy) end
    return ZeD_Window.onMouseMoveOutside(self, dx, dy)
end

function ZeD_Reader:onMouseUp(x, y)
    if self._drag then self._drag = nil; self:setCapture(false); return true end
    local down = self._down
    self._down = nil
    if down == "close" then
        local cb = self:closeRect()
        if cb and inRect(cb, x, y) then sound("UIActivateButton"); self:close() end
        return true
    end
    local h = self:hitAt(x, y)
    if h and h.id == down and h.fn then sound("UIActivateButton"); h.fn() end
    return ZeD_Window.onMouseUp(self, x, y)
end
function ZeD_Reader:onMouseUpOutside(x, y)
    if self._drag then self._drag = nil; self:setCapture(false) end
    self._down = nil
    return ZeD_Window.onMouseUpOutside(self, x, y)
end

function ZeD_Reader:onMouseWheel(del)
    local g = self._g
    if not g then return true end
    if inRect(g.canvas, self:getMouseX(), self:getMouseY()) then
        if self.view == "paper" and self.page then self:zoom(-del)
        else self.wscroll = self.wscroll + del * ZeD.T.px(60) end
    end
    return true
end

function ZeD_Reader:update()
    ISPanel.update(self)
    local h = self:hitAt(self:getMouseX(), self:getMouseY())
    self._hot = h and h.fn and h.id or nil
    local cb = self:closeRect()
    self._closeHover = cb and inRect(cb, self:getMouseX(), self:getMouseY()) or false
    if self._jump and self._storyY then
        self.wscroll = math.max(0, (self._storyY[self._jump] or 0) - ZeD.T.px(10))
        self._jump = nil
    end
    -- the character gone (dead, another player taking over): the reader closes
    if self.character:isDead() then self:close() end
end

-- ---------------------------------------------------------------------------
-- KEYS AND THE CONTROLLER
-- ---------------------------------------------------------------------------
function ZeD_Reader:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_Reader:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then self:close(); GameKeyboard.eatKeyPress(key) end
end

function ZeD_Reader:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_Reader:onLoseJoypadFocus(joypadData) self.joyfocus = nil end
function ZeD_Reader:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then self:close()
    elseif button == Joypad.LBumper or button == Joypad.RBumper then
        if self.page then self:setView(self.view == "paper" and "words" or "paper") end
    elseif button == Joypad.YButton then self:zoom(1)
    elseif button == Joypad.XButton then self:zoom(-1)
    elseif button == Joypad.AButton then if #self.places > 0 then self:showPlace(1) end end
end
local STEP = 60
function ZeD_Reader:onJoypadDirUp() if self.view == "paper" then self.panY = self.panY + ZeD.T.px(STEP) else self.wscroll = self.wscroll - ZeD.T.px(STEP) end end
function ZeD_Reader:onJoypadDirDown() if self.view == "paper" then self.panY = self.panY - ZeD.T.px(STEP) else self.wscroll = self.wscroll + ZeD.T.px(STEP) end end
function ZeD_Reader:onJoypadDirLeft() if self.view == "paper" then self.panX = self.panX + ZeD.T.px(STEP) end end
function ZeD_Reader:onJoypadDirRight() if self.view == "paper" then self.panX = self.panX - ZeD.T.px(STEP) end end

-- ---------------------------------------------------------------------------
-- ENTRY
-- ---------------------------------------------------------------------------
local function window(playerObj)
    local pn = playerObj:getPlayerNum()
    local win = R.windows[pn]
    if not win or win.character ~= playerObj then
        win = ZeD_Reader:new(playerObj)
        win:initialise()
        win:instantiate()
        R.windows[pn] = win
    end
    return win
end

local function show(win)
    win:setVisible(true)
    win:addToUIManager()
    win:bringToTop()
    local pn = win.playerNum
    if JoypadState.players[pn + 1] then
        JoypadState.players[pn + 1].focus = win
        updateJoypadFocus(JoypadState.players[pn + 1])
    end
end

-- a newspaper, flyer or brochure (an item carrying modData.printMedia)
function R.openPrint(playerObj, item)
    if not (playerObj and P.media(item)) then return false end
    local win = window(playerObj)
    win:setPrint(item)
    show(win)
    return true
end

function R.get(pn) return R.windows[pn or 0] end
