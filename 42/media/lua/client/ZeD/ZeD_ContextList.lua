-- ZeD-UI/42/media/lua/client/ZeD/ZeD_ContextList.lua
-- ============================================================================
-- THE CONTEXT MENU AS A LIST (Oct 19 2026; director: "as we are adding options
-- for viewing content. Can we add back in the text/list context menu. That way
-- people can have all lists or all grids options for the most used menus")
--
-- The other look for the right-click menu, beside the icon strip
-- (ZeD_ContextMenu): a System 7 pull-down. One row per action (its icon, its
-- name, a triangle when it opens a submenu), the action groups split by a
-- rule, submenus cascading to the side, and the pointed row's vanilla
-- tooltip (what it needs, why it can't) in a balloon beside it. The ZeD
-- option "Context menu" picks the look (Settings.lua contextStyle).
--
-- Same actions, same order, same firing as the strip: the ActionDef tree from
-- ContextMenuRegistry.buildActionsFromVanilla (vanilla's options, mods'
-- included), the same lazy submenus, the same open / close lifecycle with
-- the hidden vanilla menu. Mouse: point and click, outside closes. Controller:
-- D-pad up / down, right or A opens a submenu, left or B goes back, A runs.
-- Keyboard: arrows, Return, Escape.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/ZeD_Panel"
require "ZeD/Atoms"
require "ZeD/ContextMenuRegistry"

ZeD_ContextList = ZeD_Panel:derive("ZeD_ContextList")

-- design units (1 unit = 1 px at 1080p), the main menu's pull-down sizes
local ROW_H, PAD_X, PAD_Y, SEP_H, MIN_W, MAX_W = 24, 12, 4, 9, 200, 420
local ICON, HEAD_H, BALLOON_W = 14, 26, 280

function ZeD_ContextList:new(player, anchorMode, anchorX, anchorY, target, actionTree, vanillaMenu)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local o = ZeD_Panel:new(0, 0, sw, sh)   -- the whole screen: cascades go anywhere, a click outside closes
    setmetatable(o, self)
    self.__index = self
    o.player = player or 0
    o.anchorMode = anchorMode or "cursor"
    o._anchorX, o._anchorY = anchorX or 0, anchorY or 0
    o.vanillaMenu = vanillaMenu
    o.background = false
    o._ctx = { open = false, target = target, actions = actionTree or {} }
    o._levels = {}   -- { items, sel, x, y, w, h, rows = { {y, h, def} } }
    return o
end

function ZeD_ContextList:initialise() ZeD_Panel.initialise(self) end

-- ----------------------------------------------------------------------------
-- the levels
-- ----------------------------------------------------------------------------
local function disabled(def, target) return def.disabled and def.disabled(target) or false end

-- a level's rows: the actions with a rule between groups (the strip's categories)
local function rowsOf(items)
    local rows, last = {}, nil
    for _, def in ipairs(items) do
        if last and def.category ~= last then rows[#rows + 1] = { sep = true } end
        rows[#rows + 1] = { def = def }
        last = def.category
    end
    return rows
end

function ZeD_ContextList:_measure(lv, withHead)
    local T, tm = ZeD.T, ZeD.TM
    local f2 = T.fontF2
    local w = T.px(MIN_W)
    for _, r in ipairs(lv.rows) do
        if r.def then
            local tw = tm:MeasureStringX(f2, tostring(r.def.name or "")) + T.px(PAD_X) * 2 + T.px(ICON) + T.px(8) + T.px(16)
            if tw > w then w = tw end
        end
    end
    lv.w = math.min(w, T.px(MAX_W))
    local h = T.px(PAD_Y) * 2 + (withHead and T.px(HEAD_H) or 0)
    for _, r in ipairs(lv.rows) do h = h + (r.sep and T.px(SEP_H) or T.px(ROW_H)) end
    lv.h = h
end

-- place a level at (x, y), kept on screen (a cascade that would run off the
-- right opens to the left of its parent instead)
function ZeD_ContextList:_place(lv, x, y, parent)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local pad = ZeD.T.px(8)
    if x + lv.w > sw - pad then
        x = parent and (parent.x - lv.w + ZeD.T.px(2)) or (sw - pad - lv.w)
    end
    if y + lv.h > sh - pad then y = math.max(pad, sh - pad - lv.h) end
    lv.x, lv.y = math.max(pad, x), math.max(pad, y)
end

function ZeD_ContextList:_firstLive(lv, from, dir)
    local n = #lv.rows
    local i = from
    for _ = 1, n do
        local r = lv.rows[i]
        if r and r.def then return i end
        i = i + dir
        if i < 1 then i = n elseif i > n then i = 1 end
    end
    return nil
end

function ZeD_ContextList:open()
    self._ctx.open = true
    local top = { items = self._ctx.actions, head = true }
    top.rows = rowsOf(top.items)
    self:_measure(top, true)
    local x, y = self._anchorX, self._anchorY
    if self.anchorMode == "dock" then
        local psL = getPlayerScreenLeft and getPlayerScreenLeft(self.player) or 0
        local psT = getPlayerScreenTop and getPlayerScreenTop(self.player) or 0
        local psW = getPlayerScreenWidth and getPlayerScreenWidth(self.player) or getCore():getScreenWidth()
        local psH = getPlayerScreenHeight and getPlayerScreenHeight(self.player) or getCore():getScreenHeight()
        x = psL + math.floor((psW - top.w) / 2)
        y = psT + psH - top.h - ZeD.T.px(140)
    end
    self:_place(top, x, y, nil)
    top.sel = self:_firstLive(top, 1, 1) or 1
    self._levels = { top }
    if JoypadState and JoypadState.players and JoypadState.players[self.player + 1] then
        self._joyfocus = true
        pcall(function() if setJoypadIgnoreAimUntilCentered then setJoypadIgnoreAimUntilCentered(self.player, true) end end)
        pcall(function() if setJoypadFocus then setJoypadFocus(self.player, self) end end)
    end
    self:setWantKeyEvents(true)
    self:addToUIManager()
    pcall(function() self:bringToTop() end)
end

function ZeD_ContextList:close()
    if not self._ctx.open then return end
    self._ctx.open = false
    if self._joyfocus and setJoypadFocus then pcall(setJoypadFocus, self.player, nil) end
    self._joyfocus = false
    if ZeD and ZeD.Input and ZeD.Input.Focus and ZeD.Input.Focus.reclaimEngineFocus then
        ZeD.Input.Focus.reclaimEngineFocus()
    end
    -- the vanilla menu is a cached per-player singleton: hide it, never remove it
    if self.vanillaMenu then
        pcall(function() self.vanillaMenu:setVisible(false) end)
        self.vanillaMenu._zedSpawned = false
        self.vanillaMenu._zedMenu = nil
    end
    self:removeFromUIManager()
end

-- ----------------------------------------------------------------------------
-- actions
-- ----------------------------------------------------------------------------
-- the children of a def, filled lazily when a mod adds them only on hover
local function childrenOf(self, def)
    if def.subOption and def._vanillaMenu and (not def.children or #def.children == 0) then
        local vm, opt = def._vanillaMenu, def.vanillaRef
        if opt and opt.onSubMenu then pcall(function() opt:onSubMenu(vm, opt) end) end
        if vm.getSubMenu then
            local ok, sub = pcall(function() return vm:getSubMenu(def.subOption) end)
            local mk = ZeD.ContextMenu.Registry._makeActionDef
            if ok and sub and sub.options and #sub.options > 0 and mk then
                def.children = {}
                for j, so in ipairs(sub.options) do def.children[#def.children + 1] = mk(so, j, sub, self._ctx.target) end
            end
        end
    end
    return def.children
end

-- open the submenu of level li's selected row (focus = select its first row)
function ZeD_ContextList:_openSub(li, focus)
    local lv = self._levels[li]
    local r = lv and lv.rows[lv.sel]
    if not (r and r.def) or disabled(r.def, self._ctx.target) then return false end
    local kids = childrenOf(self, r.def)
    if not (kids and #kids > 0) then return false end
    for i = #self._levels, li + 1, -1 do self._levels[i] = nil end
    local sub = { items = kids, parentRow = lv.sel }
    sub.rows = rowsOf(kids)
    self:_measure(sub, false)
    local ry = lv.y + (r.y or 0)
    self:_place(sub, lv.x + lv.w - ZeD.T.px(2), ry - ZeD.T.px(PAD_Y), lv)
    sub.sel = focus and (self:_firstLive(sub, 1, 1) or 1) or nil
    self._levels[li + 1] = sub
    return true
end

-- run (or open) the selected row of the deepest focused level
function ZeD_ContextList:confirm(li)
    li = li or #self._levels
    local lv = self._levels[li]
    local r = lv and lv.sel and lv.rows[lv.sel]
    if not (r and r.def) then return end
    if disabled(r.def, self._ctx.target) then return end
    if self:_openSub(li, true) then return end
    if r.def.onFire then pcall(r.def.onFire, self._ctx.target) end
    self:close()
end

function ZeD_ContextList:cancel()
    if #self._levels > 1 then self._levels[#self._levels] = nil else self:close() end
end

function ZeD_ContextList:move(dir)
    local lv = self._levels[#self._levels]
    if not lv then return end
    local n = #lv.rows
    local i = (lv.sel or 0) + dir
    if i < 1 then i = n elseif i > n then i = 1 end
    lv.sel = self:_firstLive(lv, i, dir) or lv.sel
end

-- ----------------------------------------------------------------------------
-- drawing
-- ----------------------------------------------------------------------------
local ICONS = {}
function ZeD_ContextList:prerender()
    if not self._ctx.open then return end
    self:clearHitZones()
    local T, tm = ZeD.T, ZeD.TM
    local f1, f2 = T.fontF1, T.fontF2
    local rowH, padX, padY, sepH = T.px(ROW_H), T.px(PAD_X), T.px(PAD_Y), T.px(SEP_H)
    local s1, bs, ac = T.surf1, T.borderS, T.accent
    local mx, my = getMouseX(), getMouseY()
    local balloon = nil
    for li, lv in ipairs(self._levels) do
        local x, y, w, h = lv.x, lv.y, lv.w, lv.h
        ZeD.Atoms.drawSteppedShadow(self, x, y, w, h, { r = 0, g = 0, b = 0, a = 0.55 })
        self:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
        self:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
        local cy = y + padY
        -- the top level names what it acts on (the strip's target card, as a heading)
        if lv.head then
            local name, tex = ZeD.ContextMenu.Registry.getTargetDisplay(self._ctx.target)
            local d = T.textDim
            local tx = x + padX
            if tex and tex.getWidth then
                local isz = T.px(ICON)
                self:drawTextureScaledAspect(tex, tx, cy + math.floor((T.px(HEAD_H) - isz) / 2), isz, isz, 1, 1, 1, 1)
                tx = tx + isz + T.px(6)
            end
            self:drawText(ZeD.Atoms.truncateText(ZeD.upper(tostring(name or "")), f1, x + w - padX - tx),
                tx, cy + math.floor((T.px(HEAD_H) - (T.fontF1H or tm:getFontHeight(f1))) / 2), d.r, d.g, d.b, d.a or 1, f1)
            cy = cy + T.px(HEAD_H)
            self:drawRect(x, cy - T.px(1), w, T.px(1), bs.a, bs.r, bs.g, bs.b)
        end
        for ri, r in ipairs(lv.rows) do
            if r.sep then
                self:drawRect(x + T.px(1), cy + math.floor((sepH - T.px(1)) / 2), w - T.px(2), T.px(1), bs.a, bs.r, bs.g, bs.b)
                cy = cy + sepH
            else
                local def = r.def
                r.y = cy - y
                local off = disabled(def, self._ctx.target)
                local over = mx >= x and mx < x + w and my >= cy and my < cy + rowH
                local isSel = (lv.sel == ri)
                local openParent = self._levels[li + 1] and self._levels[li + 1].parentRow == ri
                if isSel or openParent then
                    -- System 7 selects a menu row whole: the accent fill (the controller's 0.55)
                    self:drawRect(x + T.px(1), cy, w - T.px(2), rowH, (isSel and not off) and 0.55 or 0.3, ac.r, ac.g, ac.b)
                end
                local a = off and 0.38 or 1
                -- on the controller's 0.55 fill the label is the focus ink (red or plain text would vanish into it)
                local tc = (isSel and not off) and T.textOnFocus
                    or ((def.stateKind and def.stateKind(self._ctx.target) == "bad") and T.dangerText or T.text)
                local ix = x + padX
                local isz = T.px(ICON)
                if def.iconTexture then
                    local tint = def.iconTintable and tc or { r = 1, g = 1, b = 1 }
                    ZeD.Atoms.drawIcon(self, def.iconTexture, ix, cy + math.floor((rowH - isz) / 2), isz, a, tint)
                end
                local tx = ix + isz + T.px(8)
                local hasKids = (def.children and #def.children > 0) or def.subOption
                local right = x + w - padX - (hasKids and T.px(10) or 0)
                self:drawText(ZeD.Atoms.truncateText(tostring(def.name or ""), f2, right - tx), tx,
                    cy + math.floor((rowH - (T.fontF2H or tm:getFontHeight(f2))) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * a, f2)
                if hasKids then
                    ZeD.Atoms.drawTriangleRight(self, x + w - padX - T.px(6), cy + math.floor((rowH - T.px(8)) / 2), T.px(8), T.textDim)
                end
                self:addHitZone("row:" .. li .. ":" .. ri, x, cy, w, rowH)
                if isSel then
                    local body = def.body or ""
                    local st = def.state and def.state(self._ctx.target) or ""
                    local txt = (st ~= "" and st ~= body) and ((body ~= "" and (body .. " ") or "") .. st) or body
                    if txt ~= "" then balloon = { text = txt, x = x + w, y = cy, lvx = x } end
                end
                cy = cy + rowH
            end
        end
    end
    -- the pointed row's tooltip, in a balloon beside its menu (System 7's Balloon Help)
    if balloon then self:_drawBalloon(balloon) end
end

function ZeD_ContextList:_drawBalloon(b)
    local T, tm = ZeD.T, ZeD.TM
    local f2 = T.fontF2
    local bw = T.px(BALLOON_W)
    local pad = T.px(8)
    -- vanilla tooltips carry rich-text tags (<RGB:..>, <LINE>): drop them, keep the words
    local txt = tostring(b.text or ""):gsub("<[^>]*>", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    local lines = ZeD.Atoms.wrapText(txt, f2, bw - pad * 2)
    local lh = (T.fontF2H or tm:getFontHeight(f2)) + T.px(2)
    local bh = #lines * lh + pad * 2
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local x = b.x + T.px(6)
    if x + bw > sw - T.px(4) then x = b.lvx - bw - T.px(6) end
    local y = math.min(b.y, sh - bh - T.px(4))
    local s2, bs, tc = T.surf2, T.borderS, T.text
    self:drawRect(x + T.px(2), y + T.px(2), bw, bh, 0.5, 0, 0, 0)
    self:drawRect(x, y, bw, bh, 1, s2.r, s2.g, s2.b)
    self:drawRectBorder(x, y, bw, bh, bs.a, bs.r, bs.g, bs.b)
    for i, l in ipairs(lines) do
        self:drawText(l, x + pad, y + pad + (i - 1) * lh, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
end

-- ----------------------------------------------------------------------------
-- mouse: the pointed row is the selection; hovering a submenu row opens it
-- ----------------------------------------------------------------------------
local function rowAt(self, x, y)
    local z = self:hitZoneAt(x, y)
    if not (z and type(z.id) == "string") then return nil end
    local li, ri = z.id:match("^row:(%d+):(%d+)$")
    return tonumber(li), tonumber(ri)
end

function ZeD_ContextList:update()
    ZeD_Panel.update(self)
    if not self._ctx.open then return end
    local mx, my = self:getMouseX(), self:getMouseY()
    if mx == self._lastMx and my == self._lastMy then return end   -- the controller keeps its row while the mouse rests
    self._lastMx, self._lastMy = mx, my
    local li, ri = rowAt(self, mx, my)
    if not li then return end
    local lv = self._levels[li]
    if not lv then return end
    if lv.sel ~= ri then
        lv.sel = ri
        for k = #self._levels, li + 1, -1 do self._levels[k] = nil end
        self._hoverAt, self._hoverRow = getTimestampMs(), li .. ":" .. ri
    end
    -- System 7 opens a hierarchical menu once the pointer rests on its row
    if self._hoverRow == li .. ":" .. ri and not self._levels[li + 1] and getTimestampMs() - (self._hoverAt or 0) > 180 then
        self:_openSub(li, false)
    end
end

function ZeD_ContextList:onMouseDown(x, y) return true end

function ZeD_ContextList:onMouseUp(x, y)
    local li, ri = rowAt(self, x, y)
    if not li then self:close(); return true end
    local lv = self._levels[li]
    lv.sel = ri
    for k = #self._levels, li + 1, -1 do self._levels[k] = nil end
    self:confirm(li)
    return true
end

function ZeD_ContextList:onRightMouseDown(x, y) self:close(); return true end
function ZeD_ContextList:onRightMouseUp(x, y) return true end
function ZeD_ContextList:onMouseWheel(del) self:move(del > 0 and 1 or -1); return true end

-- ----------------------------------------------------------------------------
-- controller and keyboard
-- ----------------------------------------------------------------------------
-- (directions only in onJoypadDir*: the engine fires onJoypadDown for the same
-- D-pad press too, and handling both moves twice)
function ZeD_ContextList:onJoypadDown(button)
    if button == Joypad.AButton then self:confirm()
    elseif button == Joypad.BButton then self:cancel() end
end
function ZeD_ContextList:onJoypadDirUp() self:move(-1) end
function ZeD_ContextList:onJoypadDirDown() self:move(1) end
function ZeD_ContextList:onJoypadDirRight() self:_openSub(#self._levels, true) end
function ZeD_ContextList:onJoypadDirLeft() if #self._levels > 1 then self:cancel() end end

local NAV = {}
function ZeD_ContextList:isKeyConsumed(key) return NAV[key] == true end
function ZeD_ContextList:onKeyPress(key)
    if key == Keyboard.KEY_UP then self:move(-1)
    elseif key == Keyboard.KEY_DOWN then self:move(1)
    elseif key == Keyboard.KEY_RIGHT then self:_openSub(#self._levels, true)
    elseif key == Keyboard.KEY_LEFT then if #self._levels > 1 then self:cancel() end
    elseif key == Keyboard.KEY_RETURN then self:confirm()
    elseif key == Keyboard.KEY_ESCAPE then self:cancel() end
end
if Keyboard then
    NAV = { [Keyboard.KEY_UP] = true, [Keyboard.KEY_DOWN] = true, [Keyboard.KEY_LEFT] = true,
            [Keyboard.KEY_RIGHT] = true, [Keyboard.KEY_RETURN] = true, [Keyboard.KEY_ESCAPE] = true }
end
