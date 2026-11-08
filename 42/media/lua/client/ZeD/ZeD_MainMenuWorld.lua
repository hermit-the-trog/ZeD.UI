-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuWorld.lua
-- ============================================================================
-- WORLD SELECT ON THE MONITOR: New Game's which-world step. Client-side; an
-- organism.
--
-- When map mods make more than one map group, vanilla's New Game asks which
-- world to play (WorldSelect: New Game > Sandbox > Next, and Sandbox's Back
-- lands on it again). A New Game step on the monitor in place of it, drawn
-- like Load Game: one card per map group on the left (its name, how many
-- maps), the chosen world on the right (its name large, then each map in it
-- with vanilla's map description). Band: Back | Next.
--
-- Vanilla's WorldSelect stays the engine: its fillList builds the groups (and
-- leaves out vanilla's IgnoredMap names), its listbox holds the choice, and
-- Back / Next run its own handler (world, seed and cell bounds saved as
-- vanilla does, then map / spawn or sandbox options follow, on the monitor
-- too). Safe mode: MM.root is gone and vanilla's screen shows.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "OptionScreens/WorldSelect"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

-- design units
local LIST_SHARE = 0.43
local ROW_H, ROW_ICON = 48, 32
local KV_LABEL_W = 96

local function ms() return MainScreen and MainScreen.instance end
local function ws() local m = ms(); return m and m.worldSelect end
local function s(v) if v == nil then return "" end; return tostring(v) end

-- the worlds vanilla's list holds, each with its maps: { index, name, maps = { { name, desc } } }
local function ignored(name)
    for _, n in ipairs(IgnoredMap or {}) do if n == name then return true end end
    return false
end
function MM.worldCards(w)
    local out = {}
    local lb = w and w.listbox
    for i, it in ipairs(lb and lb.items or {}) do
        local d = it.item or {}
        local card = { index = i, key = "world:" .. i, name = s(d.name or it.text), maps = {} }
        local dirs = d.mapDirs
        local n = 0
        pcall(function() n = dirs and dirs:size() or 0 end)
        for k = 0, n - 1 do
            local dir = dirs:get(k)
            local info = getMapInfo(dir)
            local name = (info and info.title) or dir
            if not ignored(name) then
                card.maps[#card.maps + 1] = { name = s(name), desc = info and info.description or nil }
            end
        end
        table.sort(card.maps, function(a, b) return a.name < b.name end)
        out[#out + 1] = card
    end
    return out
end

-- ============================================================================
ZeD_MMWorld = ZeD_MMWindow:derive("ZeD_MMWorld")

function ZeD_MMWorld:new()
    local o = ZeD_MMWindow.new(self, "world")
    o.noResetControl = true
    o.scroll = 0
    o.detailScroll = 0
    o.sel = 1
    return o
end

-- the world vanilla has chosen (its listbox), or the first
function ZeD_MMWorld:onShow()
    local w = ws()
    self.sel = (w and w.listbox and w.listbox.selected and w.listbox.selected > 0) and w.listbox.selected or 1
    self.scroll = 0
    self.detailScroll = 0
    self.focusId = "world:" .. self.sel
    self._cards = nil
end

function ZeD_MMWorld:cards()
    -- (built once each time the step shows: getMapInfo reads files)
    if not self._cards then self._cards = MM.worldCards(ws()) end
    return self._cards
end

function ZeD_MMWorld:pick(i)
    local w = ws()
    if w and w.listbox and w.listbox.items[i] then
        if self.sel ~= i then MM.hoverSound(); self.detailScroll = 0 end
        self.sel = i
        w.listbox.selected = i
        pcall(function() w:onSelectWorld() end)   -- (vanilla's own map list follows the choice too)
    end
end

-- a click picks the world; a second click on it soon after goes on (vanilla's double-click)
function ZeD_MMWorld:clickCard(i)
    local t = MM.now()
    if self.sel == i and self._lastClick and t - self._lastClick < 450 then
        self._lastClick = nil
        self:next()
        return
    end
    self._lastClick = t
    self:pick(i)
    self.focusId = "world:" .. i
end

-- NEXT / BACK: vanilla's own (it hides itself, then shows the next screen or the one it came from)
function ZeD_MMWorld:next()
    local w = ws()
    if not w then return end
    self:pick(self.sel)
    MM.clickSound()
    MM.toVanilla()
    w:onOptionMouseDown({ internal = "NEXT" }, 0, 0)
end
function ZeD_MMWorld:back()
    local w = ws()
    MM.clickSound()
    if not w then MM.showView("newgame"); return end
    MM.toVanilla()
    w:onOptionMouseDown({ internal = "BACK" }, 0, 0)
    -- (a Back vanilla could not place: New Game on the monitor)
    if MM.view == "world" or not (ms() and ms().bottomPanel:isVisible()) then MM.showView("newgame") end
end

function ZeD_MMWorld:prerender()
    local T = ZeD.T
    self._specs, self._hits = {}, {}
    local w, h = UI.placeOnTube(self)
    local cards = self:cards()
    if self.sel > #cards then self.sel = math.max(1, #cards) end
    self.title = ZeD.textCase(getText("UI_WorldSelect_title"))
    self.titleStats = { { text = ZeD.tr(#cards == 1 and "UI_ZeD_World_CountOne" or "UI_ZeD_World_CountMany", #cards), noMark = true } }
    ZeD_Window.prerender(self)
    local tb = T.titleBarH
    local pad = T.px(U.STACK_PAD)
    local stripH = MM.bandH()
    local stripY = h - self:footerHeight() - stripH
    local bodyY, bodyH = tb + pad, stripY - tb - pad * 2
    local listW = math.floor((w - pad * 3) * LIST_SHARE)
    self:drawList(pad, bodyY, listW, bodyH, cards)
    self:drawDetails(pad * 2 + listW, bodyY, w - pad * 3 - listW, bodyH, cards[self.sel])
    UI.stripSpecs(self, stripY, w, 1000,
        { { "back", getText("UI_btn_back"), function() self:back() end } },
        { { "next", getText("UI_btn_next"), function() self:next() end, "primary", #cards == 0, ZeD.tr("UI_ZeD_MMHelp_WorldNext") } })
end

function ZeD_MMWorld:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMWorld:getStatusLine()
    local n = #self:cards()
    return ZeD.tr(n == 1 and "UI_ZeD_World_CountOne" or "UI_ZeD_World_CountMany", n)
end

-- the cards, as Load Game's saves: an icon square, the world's name, how many maps and the first ones
function ZeD_MMWorld:drawList(x, y, w, h, cards)
    local T = ZeD.T
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    UI.insetBox(self, x, y, w, h)
    local vy, vh = y + T.px(1), h - T.px(2)
    local rh = T.px(ROW_H)
    local total = #cards * rh
    local sbW = T.sp.scrollbarW
    local over = total > vh
    local rw = w - T.px(2) - (over and sbW or 0)
    self.scroll = math.max(0, math.min(self.scroll, math.max(0, total - vh)))
    self._list = { x = x, y = vy, w = w, h = vh }
    local gp = MM.gamepad()
    self:setStencilRect(x + T.px(1), vy, w - T.px(2), vh)
    local ry = vy - self.scroll
    local f2, f3 = T.fontF2, T.fontF3
    for i, c in ipairs(cards) do
        self._specs[#self._specs + 1] = { id = c.key, listRow = true, row = i, col = 1, key = c.key, index = i, fn = function() self:next() end, ry = ry + self.scroll - vy, rh = rh }
        if ry + rh > vy and ry < vy + vh then
            local isSel = (i == self.sel)
            local hid = "world:" .. c.key
            local onFocus = MM.rowLook(self, x + T.px(1), ry, rw, rh, isSel, (not gp) and MM.ctx.hot == hid, gp and self.focusId == c.key)
            self:drawRect(x + T.px(1), ry + rh - T.px(1), rw, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
            local isz = T.px(ROW_ICON)
            local ix, iy = x + T.px(8), ry + math.floor((rh - isz) / 2)
            local s3 = T.surf3
            self:drawRect(ix, iy, isz, isz, 1, s3.r, s3.g, s3.b)
            pcall(ZeD.Atoms.drawPxIcon, self, "map", ix + T.px(4), iy + T.px(4), isz - T.px(8), 1, onFocus and T.textOnFocus or T.text)
            ZeD.Atoms.frame(self, ix, iy, isz, isz, T.border)
            local tx = ix + isz + T.px(10)
            local maxW = x + rw - T.px(8) - tx
            local nameC = onFocus and T.textOnFocus or T.textHead
            local dimC = onFocus and T.textOnFocus or T.textDim
            self:drawText(ZeD.Atoms.truncateText(c.name, f2, maxW), tx, ry + T.px(7), nameC.r, nameC.g, nameC.b, nameC.a or 1, f2)
            local names = {}
            for k, m in ipairs(c.maps) do if k <= 4 then names[#names + 1] = m.name end end
            local sub = ZeD.tr(#c.maps == 1 and "UI_ZeD_World_MapsOne" or "UI_ZeD_World_MapsMany", #c.maps)
            if #names > 0 and not (#c.maps == 1 and c.maps[1].name == c.name) then sub = sub .. MM.DOT .. table.concat(names, ", ") end
            self:drawText(ZeD.Atoms.truncateText(sub, f3, maxW), tx, ry + rh - T.px(7) - MM.fontH(f3), dimC.r, dimC.g, dimC.b, dimC.a or 1, f3)
            local cy, ch = math.max(ry, vy), math.min(ry + rh, vy + vh) - math.max(ry, vy)
            self._hits[#self._hits + 1] = { id = hid, x = ax + x, y = ay + cy, w = rw, h = ch, fn = function() self:clickCard(i) end }
            if MM.ctx.hot == hid and not gp then ZeD.Help.set(self, ZeD.tr("UI_ZeD_MMHelp_WorldRow")) end
        end
        ry = ry + rh
    end
    self:clearStencilRect()
    if over then
        MM.scrollBar(self, "world:track", x + w - T.px(1) - sbW, vy, sbW, vh, self.scroll, total, function(v) self.scroll = v end, { step = rh })
    end
end

-- the chosen world: its name large, then its maps, each with vanilla's description
function ZeD_MMWorld:drawDetails(x, y, w, h, card)
    local T = ZeD.T
    ZeD.Atoms.frame(self, x, y, w, h, T.borderS)
    if not card then return end
    local pad = T.px(12)
    local ix, iw = x + pad, w - pad * 2
    local top, bot = y + pad, y + h - pad
    self:setStencilRect(x + T.px(1), y + T.px(1), w - T.px(2), h - T.px(2))
    local cy = top - (self.detailScroll or 0)
    local tc = T.textHead
    local hf = ZeD.Font.sdf.head
    local z = 20 * (T.scale or 1) / (hf.face or 64)
    local big = card.name
    if ZeD.Text.width(hf, big, z) > iw then
        while #big > 1 and ZeD.Text.width(hf, big .. "...", z) > iw do big = big:sub(1, #big - 1) end
        big = big .. "..."
    end
    ZeD.Text.draw(self, hf, big, ix, cy, z, tc.r, tc.g, tc.b, tc.a or 1, "l")
    cy = cy + math.floor(ZeD.Text.height(hf, z)) + T.px(12)
    local f1, f2, f3 = T.fontF1, T.fontF2, T.fontF3
    local la = T.accent
    self:drawText(ZeD.tr("UI_ZeD_World_KvMaps"), ix, cy, la.r, la.g, la.b, la.a or 1, f1)
    cy = cy + MM.fontH(f1) + T.px(6)
    for _, m in ipairs(card.maps) do
        local c = T.text
        self:drawText(ZeD.Atoms.truncateText(m.name, f2, iw), ix, cy, c.r, c.g, c.b, c.a or 1, f2)
        cy = cy + MM.fontH(f2) + T.px(2)
        if m.desc and m.desc ~= "" then
            local d = T.textDim
            for _, l in ipairs(ZeD.Atoms.wrapText(UI.plain(m.desc), f3, iw - T.px(12))) do
                self:drawText(l, ix + T.px(12), cy, d.r, d.g, d.b, d.a or 1, f3)
                cy = cy + MM.fontH(f3) + T.px(2)
            end
        end
        cy = cy + T.px(8)
    end
    self:clearStencilRect()
    -- the details scroll with the wheel when a world holds more maps than fit
    local total = cy + (self.detailScroll or 0) - top
    self._details = { x = x, y = y, w = w, h = h, max = math.max(0, total - (bot - top)) }
    self.detailScroll = math.max(0, math.min(self.detailScroll or 0, self._details.max))
end

-- CONTROLLER + KEYS + WHEEL ---------------------------------------------------------
-- the list follows the controller: a focused card is the chosen world
function ZeD_MMWorld:joyDir(dir)
    ZeD_MMWindow.joyDir(self, dir)
    for _, b in ipairs(self._specs) do
        if b.id == self.focusId and b.listRow then
            self:pick(b.index)
            local vh = self._list and self._list.h or 0
            if b.ry < self.scroll then self.scroll = b.ry
            elseif b.ry + b.rh > self.scroll + vh then self.scroll = b.ry + b.rh - vh end
        end
    end
end
function ZeD_MMWorld:joyB() self:back() end
function ZeD_MMWorld:getFooterPrompts()
    if not MM.gamepad() then return nil end
    local f = self.focusId or ""
    if f:sub(1, 6) == "world:" then
        return { { glyph = "A", label = ZeD.btnCase(getText("UI_btn_next")) }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } }
    end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = ZeD.btnCase(getText("UI_btn_back")) } }
end
function ZeD_MMWorld:keyEscape() self:back(); return true end
function ZeD_MMWorld:keyOther(key)
    if key == Keyboard.KEY_RETURN then self:next(); return true end
    if key == Keyboard.KEY_UP or key == Keyboard.KEY_DOWN then
        self.focusId = "world:" .. self.sel
        self:joyDir(key == Keyboard.KEY_UP and "up" or "down")
        return true
    end
    return false
end
function ZeD_MMWorld:close() self:back() end
function ZeD_MMWorld:wheel(del)
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    local d = self._details
    if d and mx >= d.x and mx < d.x + d.w and my >= d.y and my < d.y + d.h then
        self.detailScroll = math.max(0, math.min(d.max, (self.detailScroll or 0) + del * ZeD.T.px(ROW_H)))
        return true
    end
    local l = self._list
    if not l or mx < l.x or mx > l.x + l.w or my < l.y or my > l.y + l.h then return false end
    self.scroll = self.scroll + del * ZeD.T.px(ROW_H)
    return true
end
function ZeD_MMWorld:onMouseWheel(del) return MM.wheel(del) end

local _wheel = MM.wheel
function MM.wheel(del)
    if MM.view == "world" and MM.root and MM.root.worldWin then
        if MM.root.worldWin:wheel(del) then return true end
    end
    return _wheel(del)
end

-- on the desk: vanilla's world select lands on "world" (its setVisible(true) is redirected)
MM.addView("world", "worldWin", function() return ZeD_MMWorld:new() end, "worldSelect")
