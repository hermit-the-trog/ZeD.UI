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
    -- the notebook's page and its name: the game's own text boxes, ink on the paper
    local function entry(multi)
        local e = ISTextEntryBox:new("", 0, 0, 100, 24)
        e:initialise()
        e:instantiate()
        e.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
        e.borderColor = { r = 0, g = 0, b = 0, a = 0 }
        -- ink straight on the paper: no frame (the Java box's own, nor ISTextEntryBox's)
        pcall(function() e:setHasFrame(false) end)
        e.prerender = function() end
        if multi then e:setMultipleLine(true) end
        e.onOtherKey = function(en, key) if key == Keyboard.KEY_ESCAPE then en:unfocus() end end
        self:addChild(e)
        e:setVisible(false)
        return e
    end
    self.nbEntry = entry(true)
    self.nbTitle = entry(false)
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

-- a printed piece known only by its id (a pin on the flyer map, FlyerMap.lua)
function ZeD_Reader:setPrintMedia(m)
    self.mode = "print"
    self.item = nil
    self.media = m
    self.page = P.page(m)
    self.words = P.words(m)
    self.places = P.places(m)
    self.view = self.page and "paper" or "words"
    self.zoomIx, self.panX, self.panY, self.wscroll, self.storyIx = 1, 0, 0, 0, nil
end

function ZeD_Reader:close()
    -- (a notebook's window closing ends the write action, as vanilla's Cancel does)
    if self.mode == "notebook" then self:endWriting(); return end
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
    if self.mode == "notebook" then return self:prerenderNotebook() end
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
    self:drawRect(x, y + h, w, T.px(1), T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
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
    local f1, f2 = T.fontF1, T.fontF2
    local tc, ac = T.text, T.accent
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
    -- (the write action gone some other way: the page closes with it)
    if self.mode == "notebook" and self.action and not ISTimedActionQueue.hasAction(self.action) then self:destroy() end
end

-- ---------------------------------------------------------------------------
-- KEYS AND THE CONTROLLER
-- ---------------------------------------------------------------------------
function ZeD_Reader:isKeyConsumed(key) return key == Keyboard.KEY_ESCAPE end
function ZeD_Reader:onKeyPress(key)
    if key == Keyboard.KEY_ESCAPE then
        if self.confirm then self.confirm = nil else self:close() end
        GameKeyboard.eatKeyPress(key)
    end
end

function ZeD_Reader:onGainJoypadFocus(joypadData) self.joyfocus = joypadData end
function ZeD_Reader:onLoseJoypadFocus(joypadData) self.joyfocus = nil end
-- a notebook: LB / RB or the D-pad turn the page, A writes (the keyboard), X erases (asks),
-- Y is Done, the Back / Select button locks, B goes back (or answers no)
function ZeD_Reader:onJoypadNotebook(button)
    if self.confirm == "erase" then
        if button == Joypad.AButton then self:erasePage() elseif button == Joypad.BButton then self.confirm = nil end
        return
    end
    if button == Joypad.BButton then self:endWriting()
    elseif button == Joypad.LBumper then self:turnPage(-1)
    elseif button == Joypad.RBumper then self:turnPage(1)
    elseif self.readOnly then return
    elseif button == Joypad.AButton then if not self:isLockedByMe() then self.nbEntry:focus() end
    elseif button == Joypad.XButton then if not self:isLockedByMe() then self.confirm = "erase" end
    elseif button == Joypad.YButton then self:done()
    elseif button == Joypad.Back then self:toggleLock() end
end
function ZeD_Reader:onJoypadDown(button, joypadData)
    if self.mode == "notebook" then return self:onJoypadNotebook(button) end
    if button == Joypad.BButton then self:close()
    elseif button == Joypad.LBumper or button == Joypad.RBumper then
        if self.page then self:setView(self.view == "paper" and "words" or "paper") end
    elseif button == Joypad.YButton then self:zoom(1)
    elseif button == Joypad.XButton then self:zoom(-1)
    elseif button == Joypad.AButton then if #self.places > 0 then self:showPlace(1) end end
end
local STEP = 60
function ZeD_Reader:onJoypadDirUp() if self.mode == "notebook" then return end; if self.view == "paper" then self.panY = self.panY + ZeD.T.px(STEP) else self.wscroll = self.wscroll - ZeD.T.px(STEP) end end
function ZeD_Reader:onJoypadDirDown() if self.mode == "notebook" then return end; if self.view == "paper" then self.panY = self.panY - ZeD.T.px(STEP) else self.wscroll = self.wscroll + ZeD.T.px(STEP) end end
function ZeD_Reader:onJoypadDirLeft() if self.mode == "notebook" then return self:turnPage(-1) end; if self.view == "paper" then self.panX = self.panX + ZeD.T.px(STEP) end end
function ZeD_Reader:onJoypadDirRight() if self.mode == "notebook" then return self:turnPage(1) end; if self.view == "paper" then self.panX = self.panX - ZeD.T.px(STEP) end end

-- ============================================================================
-- THE NOTEBOOK (HOOK_MAP row 24): vanilla's write action with ZeD's page
-- ============================================================================
-- Vanilla's Write / Read note (ISWriteSomething) runs as it does: the
-- character sits writing (light needed, and a pencil or pen for Write) for as
-- long as the page is open. Only its window is ZeD's (Overrides/WriteNote.lua):
-- ruled paper with the binder holes and the red margin, the notebook's name
-- at the top (edited in place), the game's 15 lines a page (80 letters a
-- line), the pages down the left with their first words. Every rule is
-- vanilla's ISUIWriteJournal: Erase clears the page (asked in the strip), the
-- padlock locks the notebook to you at once, Done saves every page and the
-- name, Back leaves it as it was; someone else's locked notebook, or a Read
-- note without a pencil, opens to read only.
local NB = { LINES = 15, LETTERS = 80, RAIL = 230, PAGE_W = 760, HOLE = 14, MARGIN = 64 }
local RULE = { r = 0.725, g = 0.776, b = 0.839 }
local MARGIN_C = { r = 0.827, g = 0.604, b = 0.573 }

function ZeD_Reader:setNotebook(item, action, editable)
    self.mode = "notebook"
    self.item = item
    self.action = action
    self.media = nil
    local me = self.character:getUsername()
    local by = item:getLockedBy()
    self.otherLock = by ~= nil and by ~= me and not isAdmin()
    self.readOnly = (not editable) or self.otherLock
    self.nPages = item:getPageToWrite()
    self.pages = {}
    local cp = item:getCustomPages()
    for i = 0, cp:size() - 1 do self.pages[i + 1] = item:seePage(i + 1) or "" end
    if self.otherLock then self.nPages = cp:size() end
    self.nPages = math.max(1, self.nPages)
    self.pageIx = 1
    self.confirm = nil
    self._loaded = false
    self.nbTitle:setText(item:getName())
    self:loadPage()
end

function ZeD_Reader:isLockedByMe()
    return self.item and self.item:getLockedBy() ~= nil and not self.otherLock
end

-- the page in the box into the notebook's pages (kept until Done)
function ZeD_Reader:keepPage()
    if self.mode ~= "notebook" or not self._loaded then return end
    self.pages[self.pageIx] = self.nbEntry:getText()
end

function ZeD_Reader:loadPage()
    self.nbEntry:setText(self.pages[self.pageIx] or "")
    pcall(function() self.nbEntry.javaObject:setCursorLine(0) end)
    self._loaded = true
end

function ZeD_Reader:turnPage(d)
    local j = self.pageIx + d
    if j < 1 or j > self.nPages then return end
    self:keepPage()
    self.pageIx = j
    self:loadPage()
    sound("UISelectListItem")
end

function ZeD_Reader:goPage(j)
    if j == self.pageIx then return end
    self:keepPage()
    self.pageIx = j
    self:loadPage()
    sound("UISelectListItem")
end

-- vanilla's LOCKBOOK / UNLOCKBOOK: applied to the notebook at once
function ZeD_Reader:toggleLock()
    if self.readOnly then return end
    if self:isLockedByMe() then
        self.item:setLockedBy(nil)
    else
        self.item:setLockedBy(self.character:getUsername())
        if self.item:hasTag(ItemTag.LOCK_ON_WRITE) then self.item:setLockedBy(tostring(ZombRand(1000000))) end
    end
    sound("UIActivateButton")
end

function ZeD_Reader:erasePage()
    self.pages[self.pageIx] = ""
    self.nbEntry:setText("")
    self.confirm = nil
    sound("UIActivateButton")
end

-- vanilla's OK (ISInventoryPaneContextMenu.onWriteSomethingClick): every page and the name
function ZeD_Reader:done()
    if not self.readOnly and not self:isLockedByMe() then
        self:keepPage()
        if self.item:hasTag(ItemTag.LOCK_ON_WRITE) then self.item:setLockedBy(tostring(ZombRand(1000000))) end
        for i = 1, self.nPages do
            if self.pages[i] ~= nil then self.item:addPage(i, self.pages[i]) end
        end
        local name = self.nbTitle:getText()
        if name and name ~= "" and name ~= self.item:getName() then
            self.item:setName(name)
            self.item:setCustomName(true)
        end
    end
    sound("UIActivateButton")
    self:endWriting()
end

-- Back: the notebook as it was; the write action ends (vanilla's Cancel)
function ZeD_Reader:endWriting()
    self.nbEntry:unfocus(); self.nbTitle:unfocus()
    self.nbEntry:setVisible(false); self.nbTitle:setVisible(false)
    self.mode = "print"
    ISTimedActionQueue.clear(self.character)   -- (the action's stop closes this window: destroy)
    if self:getIsVisible() then self:close() end
end

-- the action's own end (stop / perform) closes its window: vanilla's modal:destroy()
function ZeD_Reader:destroy()
    self.nbEntry:setVisible(false); self.nbTitle:setVisible(false)
    if self.mode == "notebook" then self.mode = "print" end
    if self:getIsVisible() then self:close() end
end

-- the page's first words, for the rail
local function firstWords(s)
    if not s or s == "" then return nil end
    local l = s:match("^%s*([^\n]+)")
    return l
end

function ZeD_Reader:prerenderNotebook()
    local T = ZeD.T
    local who = self.character:getDescriptor()
    local name = who and (who:getForename() .. " " .. who:getSurname()) or ""
    self.title = name .. "  +  " .. tostring(self.item:getName())
    self.titleStats = self.readOnly and { { text = "Reading" } } or { { text = "Writing", color = T.accent } }
    local g = self:layout()
    ZeD_Window.prerender(self)
    self.minimumWidth, self.minimumHeight = 0, 0
    self:keepPage()
    local pad = T.px(U.PAD)
    local rail = { x = pad, y = g.canvas.y, w = T.px(NB.RAIL), h = g.canvas.h }
    local area = { x = rail.x + rail.w + pad, y = g.canvas.y, w = self.width - pad * 3 - rail.w, h = g.canvas.h }
    self:drawRail(rail)
    self:drawNotePage(area)
    self:drawNoteStrip(g.strip)
end

function ZeD_Reader:drawRail(r)
    local T = ZeD.T
    local bs, s1 = T.borderS, T.surf1
    self:drawRect(r.x, r.y, r.w, r.h, 1, s1.r, s1.g, s1.b)
    self:drawRectBorder(r.x, r.y, r.w, r.h, bs.a, bs.r, bs.g, bs.b)
    local y = section(self, "PAGES", r.x + T.px(10), r.y + T.px(10), r.w - T.px(20))
    local f2, f3 = T.fontF2, T.fontF3
    local rh = fh(f2) + T.px(14)
    local ac, tc, td = T.accent, T.text, T.textDim
    for i = 1, self.nPages do
        if y + rh > r.y + r.h then break end
        local id = "page:" .. i
        if i == self.pageIx then self:drawRect(r.x + 1, y, r.w - 2, rh, 0.22, ac.r, ac.g, ac.b)
        elseif self._hot == id then self:drawRect(r.x + 1, y, r.w - 2, rh, 0.12, ac.r, ac.g, ac.b) end
        local num = tostring(i)
        self:drawText(num, r.x + T.px(32) - tw(f3, num), y + math.floor((rh - fh(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)
        local words = firstWords(self.pages[i])
        local c = words and tc or td
        self:drawText(ZeD.Atoms.truncateText(words or "Blank", f2, r.w - T.px(52)), r.x + T.px(42), y + math.floor((rh - fh(f2)) / 2), c.r, c.g, c.b, c.a or 1, f2)
        self:drawRect(r.x + T.px(1), y + rh - T.px(1), r.w - T.px(2), T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
        self._hits[#self._hits + 1] = { id = id, x = r.x, y = y, w = r.w, h = rh, fn = function() self:goPage(i) end }
        y = y + rh
    end
end

function ZeD_Reader:drawNotePage(a)
    local T = ZeD.T
    self:drawRect(a.x, a.y, a.w, a.h, 1, 0.035, 0.043, 0.039)
    -- the hand: the entry face nearest 18 px, and the rules spaced by its own line
    -- pitch, so every line of writing sits on a rule
    local ef, lh = UIFont.Medium, fh(UIFont.Medium)
    if ZeD.Text.entryFontAt then ef, lh = ZeD.Text.entryFontAt(18) end
    local headH = T.px(64)
    local band = (self.readOnly) and (fh(T.fontF2) + T.px(18)) or 0
    local pw = math.min(T.px(NB.PAGE_W), a.w - T.px(40))
    local ph = headH + lh * NB.LINES + T.px(48)
    local px = a.x + math.floor((a.w - pw) / 2)
    local py = a.y + T.px(18) + band
    -- why it reads only
    if self.readOnly then
        local s2, bs = T.surf2, T.borderS
        self:drawRect(px, a.y + T.px(10), pw, band - T.px(6), 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(px, a.y + T.px(10), pw, band - T.px(6), bs.a, bs.r, bs.g, bs.b)
        local why = self.otherLock and "Locked by its writer. You can read it; you cannot write in it." or "No pencil or pen: you can read it, not write in it."
        local tc = T.text
        self:drawText(why, px + T.px(12), a.y + T.px(10) + math.floor((band - T.px(6) - fh(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
    end
    -- the paper, its holes, the margin and the rules
    self:drawRect(px, py, pw, ph, 1, PAPER.r, PAPER.g, PAPER.b)
    local hole = T.px(NB.HOLE)
    for k = 0, 2 do
        local hy = py + T.px(40) + math.floor((ph - T.px(80)) * k / 2) - math.floor(hole / 2)
        ZeD.Atoms.drawStatusDot(self, px + T.px(14), hy, { r = 0.035, g = 0.043, b = 0.039, a = 1 }, hole)
    end
    local mx = px + T.px(NB.MARGIN)
    self:drawRect(mx, py + headH, T.px(2), ph - headH, 1, MARGIN_C.r, MARGIN_C.g, MARGIN_C.b)
    self:drawRect(mx, py + headH - T.px(2), pw - (mx - px), T.px(2), 1, MARGIN_C.r, MARGIN_C.g, MARGIN_C.b)
    -- (the box's first line starts LINE_TOP below its top; each rule runs under a line)
    local LINE_TOP = T.px(4)
    for i = 1, NB.LINES do
        self:drawRect(mx + T.px(2), py + headH + T.px(2) + LINE_TOP + lh * i, pw - (mx - px) - T.px(2), T.px(1), 1, RULE.r, RULE.g, RULE.b)
    end
    -- the name (edited in place) and the page number
    local f3 = T.fontF3
    local pn = "Page " .. self.pageIx .. " of " .. self.nPages
    self:drawText(pn, px + pw - T.px(20) - tw(f3, pn), py + T.px(30), INK_DIM.r, INK_DIM.g, INK_DIM.b, 1, f3)
    local tx, tyy = mx + T.px(12), py + T.px(18)
    local tWidth = pw - (mx - px) - T.px(40) - tw(f3, pn)
    self.nbTitle.font = ef
    self.nbTitle:setFont(ef)
    if self.nbTitle.x ~= tx or self.nbTitle.y ~= tyy then self.nbTitle:setX(tx); self.nbTitle:setY(tyy) end
    if self.nbTitle.width ~= tWidth or self.nbTitle.height ~= fh(ef) + T.px(8) then self.nbTitle:setWidth(tWidth); self.nbTitle:setHeight(fh(ef) + T.px(8)) end
    self.nbTitle:setVisible(true)
    self.nbTitle:setEditable(not self.readOnly and not self:isLockedByMe())
    self.nbTitle.javaObject:setTextRGBA(INK.r, INK.g, INK.b, 1)
    if not self.readOnly then self:drawRect(tx, tyy + fh(ef) + T.px(6), tWidth, 1, 0.6, INK_DIM.r, INK_DIM.g, INK_DIM.b) end
    -- the page's text box over the rules: one line per ruled line
    local ex, ey = mx + T.px(10), py + headH + T.px(2)
    local ew, eh = pw - (mx - px) - T.px(20), lh * NB.LINES + LINE_TOP * 2
    local e = self.nbEntry
    if e.font ~= ef then e.font = ef; e:setFont(ef) end
    if e.x ~= ex or e.y ~= ey then e:setX(ex); e:setY(ey) end
    if e.width ~= ew or e.height ~= eh then e:setWidth(ew); e:setHeight(eh) end
    e:setVisible(true)
    e:setEditable(not self.readOnly and not self:isLockedByMe())
    pcall(function()
        e.javaObject:setMaxLines(NB.LINES)
        e.javaObject:setMaxTextLength(NB.LINES * NB.LETTERS)
        e.javaObject:setTextRGBA(INK.r, INK.g, INK.b, 1)
    end)
    self._hits[#self._hits + 1] = { id = "pagebox", x = ex, y = ey, w = ew, h = eh, fn = function() if not self.readOnly then e:focus() end end }
    -- how much is left
    local text = self.pages[self.pageIx] or ""
    local lines = 0
    for _ in (text .. "\n"):gmatch("(.-)\n") do lines = lines + 1 end
    if text == "" then lines = 0 end
    local count = lines .. " of " .. NB.LINES .. " lines | " .. ZeD.BB_count(#text) .. " of " .. ZeD.BB_count(NB.LINES * NB.LETTERS) .. " letters"
    self:drawText(count, mx + T.px(10), py + ph - T.px(30), INK_DIM.r, INK_DIM.g, INK_DIM.b, 1, f3)
end

-- 1200 as "1,200"
function ZeD.BB_count(n)
    local s = tostring(math.floor(n or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if out:sub(1, 1) == "," then out = out:sub(2) end
    return out
end

function ZeD_Reader:drawNoteStrip(st)
    local T = ZeD.T
    local s2 = T.surf2
    self:drawRect(1, st.y, st.w - 2, st.h, s2.a or 1, s2.r, s2.g, s2.b)
    ZeD.Atoms.drawDividerH(self, 1, st.y, st.w - 2, false)
    local bh = T.px(U.BTN_H)
    local by = st.y + math.floor((st.h - bh) / 2)
    local x = T.px(U.PAD)
    local ac = T.accent
    local function btn(id, text, fn, variant, on, rightAlign)
        local bw = tw(T.fontF3, ZeD.btnCase(text)) + T.px(U.BTN_PAD) * 2
        if rightAlign then x = rightAlign - bw end
        local colors = nil
        if on then colors = { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.55 } }
        elseif self._hot == id then colors = { fill = { r = ac.r, g = ac.g, b = ac.b, a = 0.22 } } end
        ZeD.Molecules.drawButton(self, x, by, bw, bh, text, variant or "default", self._down == id, colors)
        self._hits[#self._hits + 1] = { id = id, x = x, y = by, w = bw, h = bh, fn = fn }
        x = x + bw + T.px(U.GAP)
        return bw
    end
    if self.confirm == "erase" then
        local q = "Erase page " .. self.pageIx .. "? Its words cannot be brought back."
        local tc = T.text
        self:drawText(q, x, st.y + math.floor((st.h - fh(T.fontF2)) / 2), tc.r, tc.g, tc.b, tc.a or 1, T.fontF2)
        local right = st.w - T.px(U.PAD)
        local ew = tw(T.fontF3, "Erase") + T.px(U.BTN_PAD) * 2
        btn("confirm:no", "KEEP IT", function() self.confirm = nil end, "default", false, right - ew - T.px(U.GAP))
        btn("confirm:yes", "ERASE", function() self:erasePage() end, "danger", false, right)
        return
    end
    btn("back", "BACK", function() self:endWriting() end)
    if not self.readOnly then
        local locked = self:isLockedByMe()
        if not locked then btn("erase", "ERASE PAGE", function() self.confirm = "erase" end, "danger") end
        btn("lock", locked and "UNLOCK" or "LOCK", function() self:toggleLock() end, "default", locked)
    end
    -- the pages, in the middle
    local f3 = T.fontF3
    local label = "Page " .. self.pageIx .. " of " .. self.nPages
    local mid = math.floor(st.w / 2)
    local lw = tw(f3, label) + T.px(16)
    x = mid - math.floor(lw / 2) - bh - T.px(U.GAP)
    btn("prev", "<", function() self:turnPage(-1) end, "default", false)
    local tc = T.textDim
    self:drawText(label, x + T.px(8), by + math.floor((bh - fh(f3)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f3)
    x = x + lw
    btn("next", ">", function() self:turnPage(1) end, "default", false)
    if not self.readOnly and not self:isLockedByMe() then btn("done", "DONE", function() self:done() end, "primary", false, st.w - T.px(U.PAD)) end
end

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

-- a piece by its id (the flyer map's pins)
function R.openPrintId(playerObj, id)
    if not (playerObj and id) then return false end
    local win = window(playerObj)
    win:setPrintMedia(P.ofId(id))
    show(win)
    return true
end

-- a notebook, journal or diary for vanilla's write action (Overrides/WriteNote.lua): the
-- window is handed to the action as its modal; the action adds it to the screen and
-- gives it the controller, and its stop / perform close it (destroy)
function R.openNotebook(playerObj, item, action, editable)
    if not (playerObj and item and item.getPageToWrite) then return nil end
    local win = window(playerObj)
    if win:getIsVisible() then win:removeFromUIManager() end
    win:setNotebook(item, action, editable)
    win:setVisible(true)
    return win
end

-- (vanilla's start calls modal:initialise() on the window it was handed: once is enough)
function ZeD_Reader:initialise()
    if self._initDone then return end
    self._initDone = true
    ZeD_Window.initialise(self)
end

function R.get(pn) return R.windows[pn or 0] end
