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
--
-- A pop-up over the game: solid surface 1, the 1u frame (drawn last on each
-- level) and System 7's hard shadow. A row has one cue at a time: the hover wash
-- under the pointer, the same wash for the keyboard's row, the controller's
-- focus mark (ZeD.Focus.mark) for the pad's; a row whose submenu is open wears
-- the selection wash.
-- ============================================================================

require "ISUI/ISPanel"
require "ZeD/ZeD_Panel"
require "ZeD/Atoms"
require "ZeD/ContextMenuRegistry"

ZeD_ContextList = ZeD_Panel:derive("ZeD_ContextList")

-- design units (1 unit = 1 px at 1080p), the main menu's pull-down sizes
local ROW_H, PAD_X, PAD_Y, SEP_H, MIN_W, MAX_W = 24, 12, 4, 9, 200, 420
-- (ICON 16: the pixel icons' smallest drawing, drawn at its own size at 1x)
local ICON, HEAD_H, BALLOON_W = 16, 26, 280

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
    o._nav = "mouse" -- who moves the selection now: "mouse" | "key" | "pad"
    o._hv = {}       -- the balloon's hover delay (ZeD.Atoms.hoverReady)
    return o
end

function ZeD_ContextList:initialise() ZeD_Panel.initialise(self) end

-- ----------------------------------------------------------------------------
-- the levels
-- ----------------------------------------------------------------------------
local function disabled(def, target) return def.disabled and def.disabled(target) or false end

-- Rows a list of choices needs (Oct 29 2026, the loadouts' menus): def.check (a
-- function or a bool: a checkbox in the icon's place, live), def.heading (a small
-- dim label over a group: no selection, no press), def.note (dim words at the
-- row's right), def.keepOpen (the menu stays after the press: ticking boxes).
local function checked(def)
    local c = def.check
    if type(c) == "function" then
        local ok, v = pcall(c)
        return ok and v and true or false
    end
    return c and true or false
end
local function live(def) return def and not def.heading end

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
            -- (a note that changes while the menu is open is measured at its longest: a place's words)
            if r.def.note then
                local ns = (type(r.def.note) == "function") and string.rep("n", 16) or tostring(r.def.note)
                tw = tw + tm:MeasureStringX(T.fontF1, ns) + T.px(12)
            end
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
        if r and live(r.def) then return i end
        i = i + dir
        if i < 1 then i = n elseif i > n then i = 1 end
    end
    return nil
end

function ZeD_ContextList:open()
    self._ctx.open = true
    local top = { items = self._ctx.actions, head = not self.noHead }
    top.rows = rowsOf(top.items)
    self:_measure(top, top.head)
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
    -- opened by the pad, the first row is marked at once; with the mouse, only the row it is on
    local D = ZeD.Input and ZeD.Input.Detector
    self._nav = (D and D.getMode and D.getMode() == "gamepad") and "pad" or "mouse"
    self._lastMx, self._lastMy = getMouseX(), getMouseY()   -- (the panel covers the screen: its mouse is the screen's)
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
    if not (r and live(r.def)) then return end
    if disabled(r.def, self._ctx.target) then return end
    if self:_openSub(li, true) then return end
    if r.def.onFire then pcall(r.def.onFire, self._ctx.target) end
    if r.def.keepOpen and self._ctx.open then return end
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
local _focus, _dim = { focused = true, pad = true }, {}
function ZeD_ContextList:prerender()
    if not self._ctx.open then return end
    self:clearHitZones()
    local A = ZeD.Atoms
    local T, tm = ZeD.T, ZeD.TM
    local f1, f2 = T.fontF1, T.fontF2
    local rowH, padX, padY, sepH = T.px(ROW_H), T.px(PAD_X), T.px(PAD_Y), T.px(SEP_H)
    local s1, bs, ac, hv = T.surf1, T.borderS, T.accent, T.hover
    local u = T.hair
    local mx, my = getMouseX(), getMouseY()
    local nav = self._nav
    local balloon = nil
    for li, lv in ipairs(self._levels) do
        local x, y, w, h = lv.x, lv.y, lv.w, lv.h
        lv.inkRow = nil
        A.drawHardShadow(self, x, y, w, h)
        self:drawRect(x, y, w, h, 1, s1.r, s1.g, s1.b)
        local cy = y + padY
        -- the top level names what it acts on (the strip's target card, as a heading)
        if lv.head then
            local name, tex = ZeD.ContextMenu.Registry.getTargetDisplay(self._ctx.target)
            -- a menu of its own may name itself (the mark strip's "Crowbar in lists", its icon)
            if self.headText then name, tex = self.headText, nil end
            local d = T.textDim
            local tx = x + padX
            if self.headPx then
                local isz = T.px(ICON)
                A.drawPxIcon(self, self.headPx, tx, cy + math.floor((T.px(HEAD_H) - isz) / 2), isz, 1, d)
                tx = tx + isz + T.px(6)
            elseif tex and tex.getWidth then
                local isz = T.px(ICON)
                self:drawTextureScaledAspect(tex, tx, cy + math.floor((T.px(HEAD_H) - isz) / 2), isz, isz, 1, 1, 1, 1)
                tx = tx + isz + T.px(6)
            end
            -- (the name as the game writes it: an item's own name keeps its case)
            self:drawText(A.truncateText(tostring(name or ""), f1, x + w - padX - tx),
                tx, cy + math.floor((T.px(HEAD_H) - (T.fontF1H or tm:getFontHeight(f1))) / 2), d.r, d.g, d.b, d.a or 1, f1)
            cy = cy + T.px(HEAD_H)
            self:drawRect(x, cy - u, w, u, bs.a, bs.r, bs.g, bs.b)
        end
        for ri, r in ipairs(lv.rows) do
            if r.sep then
                self:drawRect(x + u, cy + math.floor((sepH - u) / 2), w - 2 * u, u, bs.a, bs.r, bs.g, bs.b)
                cy = cy + sepH
            elseif r.def.heading then
                -- a group's small label (F1, dim, sentence case): not a choice
                r.y = cy - y
                local d = T.textDim
                self:drawText(A.truncateText(A.textCase(tostring(r.def.name or "")), f1, w - padX * 2), x + padX,
                    cy + math.floor((rowH - (T.fontF1H or tm:getFontHeight(f1))) / 2), d.r, d.g, d.b, d.a or 1, f1)
                self:addHitZone("row:" .. li .. ":" .. ri, x, cy, w, rowH)
                cy = cy + rowH
            else
                local def = r.def
                r.y = cy - y
                local off = disabled(def, self._ctx.target)
                local over = mx >= x and mx < x + w and my >= cy and my < cy + rowH
                local isSel = (lv.sel == ri)
                local openParent = self._levels[li + 1] and self._levels[li + 1].parentRow == ri
                -- the row whose submenu is open is selected: the one accent wash
                if openParent then
                    self:drawRect(x + u, cy, w - 2 * u, rowH, T.selectionA, ac.r, ac.g, ac.b)
                end
                -- the cue for the row the selection is on: the pad's mark, or the hover wash
                local onFocus = false
                if isSel then
                    if nav == "pad" then
                        _focus.win = self
                        onFocus = ZeD.Focus.mark(self, x + u, cy, w - 2 * u, rowH, _focus)
                        -- (the row whose words are on the focus ink, for a menu that draws more on its rows)
                        if onFocus then lv.inkRow = ri end
                    elseif nav == "key" or over then
                        self:drawRect(x + u, cy, w - 2 * u, rowH, hv.a or 1, hv.r, hv.g, hv.b)
                    end
                end
                local a = off and T.disabledAlpha or 1
                -- on a wash of 0.5 or more the label is the focus ink
                local tc = onFocus and T.textOnFocus or T.text
                local ix = x + padX
                local isz = T.px(ICON)
                if def.check ~= nil then
                    -- a choice that is on or off: the checkbox in the icon's place
                    local cs = T.checkboxSz
                    A.drawCheckbox(self, ix + math.floor((isz - cs) / 2), cy + math.floor((rowH - cs) / 2), checked(def), false, off)
                elseif def.pxIcon then
                    A.drawPxIcon(self, def.pxIcon, ix, cy + math.floor((rowH - isz) / 2), isz, a, tc)
                elseif def.iconTexture then
                    local tint = def.iconTintable and tc or { r = 1, g = 1, b = 1 }
                    A.drawIcon(self, def.iconTexture, ix, cy + math.floor((rowH - isz) / 2), isz, a, tint)
                end
                local tx = ix + isz + T.px(8)
                local hasKids = (def.children and #def.children > 0) or def.subOption
                local right = x + w - padX - (hasKids and T.px(10) or 0)
                -- a state that is bad (it cannot be done) is a red square, the words stay the default ink
                if def.stateKind and def.stateKind(self._ctx.target) == "bad" then
                    local sq = T.px(6)
                    local dc = T.danger
                    _dim.r, _dim.g, _dim.b, _dim.a = dc.r, dc.g, dc.b, (dc.a or 1) * a
                    A.drawStatusDot(self, right - sq, cy + math.floor((rowH - sq) / 2), _dim, sq)
                    right = right - sq - T.px(6)
                end
                local ns = def.note
                if type(ns) == "function" then
                    local okN, v = pcall(ns)
                    ns = okN and v or nil
                end
                if ns then
                    ns = tostring(ns)
                    local nw = tm:MeasureStringX(f1, ns)
                    local nc = onFocus and T.textOnFocus or T.textDim
                    self:drawText(ns, right - nw, cy + math.floor((rowH - (T.fontF1H or tm:getFontHeight(f1))) / 2),
                        nc.r, nc.g, nc.b, (nc.a or 1) * a, f1)
                    right = right - nw - T.px(8)
                end
                self:drawText(A.truncateText(tostring(def.name or ""), f2, right - tx), tx,
                    cy + math.floor((rowH - (T.fontF2H or tm:getFontHeight(f2))) / 2), tc.r, tc.g, tc.b, (tc.a or 1) * a, f2)
                if hasKids then
                    A.drawTriangleRight(self, x + w - padX - T.px(6), cy + math.floor((rowH - T.px(8)) / 2), T.px(8), onFocus and T.textOnFocus or T.textDim)
                end
                self:addHitZone("row:" .. li .. ":" .. ri, x, cy, w, rowH)
                if isSel and (nav ~= "mouse" or over or openParent) then
                    local body = def.body or ""
                    local st = def.state and def.state(self._ctx.target) or ""
                    local txt = (st ~= "" and st ~= body) and ((body ~= "" and (body .. " ") or "") .. st) or body
                    if txt ~= "" then balloon = { text = txt, x = x + w, y = cy, lvx = x, key = li .. ":" .. ri } end
                end
                cy = cy + rowH
            end
        end
        -- the level's frame, last: nothing of its own covers it
        A.frame(self, x, y, w, h, bs)
    end
    -- the pointed row's tooltip, in a balloon beside its menu (System 7's Balloon Help): at
    -- once for the pad and the keys, after the shared hover delay for the mouse
    local ready = A.hoverReady(self._hv, balloon and balloon.key or nil)
    if balloon and (nav ~= "mouse" or ready) then self:_drawBalloon(balloon) end
    ZeD.Focus.drawOverlay(self, self)
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
    -- a hover box: solid surface 1, the 1u frame, the hard shadow
    local s1, bs, tc = T.surf1, T.borderS, T.text
    ZeD.Atoms.drawHardShadow(self, x, y, bw, bh)
    self:drawRect(x, y, bw, bh, 1, s1.r, s1.g, s1.b)
    ZeD.Atoms.frame(self, x, y, bw, bh, bs)
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
    if self._lastMx == nil then
        -- (a list that did not come through :open, the window box's menu: who opened it)
        local D = ZeD.Input and ZeD.Input.Detector
        self._nav = (self._joyfocus and D and D.getMode and D.getMode() == "gamepad") and "pad" or "mouse"
        self._lastMx, self._lastMy = mx, my
    end
    if mx == self._lastMx and my == self._lastMy then return end   -- the controller keeps its row while the mouse rests
    self._lastMx, self._lastMy = mx, my
    self._nav = "mouse"
    local li, ri = rowAt(self, mx, my)
    if not li then return end
    local lv = self._levels[li]
    if not lv then return end
    if not live(lv.rows[ri] and lv.rows[ri].def) then return end   -- (a heading is not a choice)
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
    if not live(lv.rows[ri] and lv.rows[ri].def) then return true end
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
    self._nav = "pad"
    if button == Joypad.AButton then self:confirm()
    elseif button == Joypad.BButton then self:cancel() end
end
function ZeD_ContextList:onJoypadDirUp() self._nav = "pad"; self:move(-1) end
function ZeD_ContextList:onJoypadDirDown() self._nav = "pad"; self:move(1) end
function ZeD_ContextList:onJoypadDirRight() self._nav = "pad"; self:_openSub(#self._levels, true) end
function ZeD_ContextList:onJoypadDirLeft() self._nav = "pad"; if #self._levels > 1 then self:cancel() end end

local NAV = {}
function ZeD_ContextList:isKeyConsumed(key) return NAV[key] == true end
function ZeD_ContextList:onKeyPress(key)
    self._nav = "key"
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
