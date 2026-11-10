-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuDesktop.lua
-- ============================================================================
-- THE ZeD OS DESKTOP: the icons behind the menu's windows. Client; an organism
-- (the icon layer, a child of the desk under every window, plus the Trash).
--
-- The main window's close box only closes it (Quit stays in File and on the
-- case's power button) and leaves the bare desktop, so the icons open
-- everything the menus can: a player who closes the window and never finds the
-- menu bar still has a way in. Down the screen's right edge, the way a 1993
-- desktop kept them: Project Zomboid, New Game, Load Game, Join a Server,
-- Options, Mods, Mod Uploader (the Workshop, where Steam offers it); the Trash
-- in the bottom corner. 32 x 32 pixel icons drawn at whole multiples.
-- A click selects an icon (its name turns accent, the picture darkens), a
-- second click opens it; Return or A opens the selected one, the arrows or the
-- D-pad move between them. They sit under the windows, as icons do.
--
-- Down the left edge: the sticky note, always there and typed in place, then
-- CletusWorks (the notepad), ProtoPOP3 Mail and the Documents folder (the
-- notes, ZeD_MainMenuDocs.lua), columns to the right when one fills and never
-- over the right column. ZeD_MainMenuNotes.lua builds that list
-- (MM.leftItems); ZeD_MainMenuMail.lua adds Mail to it through MM.leftApps.
--
-- The Trash opens a small window holding one file: the Computer itself (the
-- old desktop joke of dragging the computer to the trash). Empty trash throws
-- the computer away: the window asks "Quit Project Zomboid?" in its band, the
-- same question as the main window's Quit. Cancel keeps everything.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/Input/SpatialNav"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui

local ICON_DIR = "media/textures/ZeD/mainmenu/icons/"
local NEAREST = 3                 -- Texture flag: nearest filtering (the pixels stay square)
local ICON_PX = 32                -- the art's own size
local CELL_W = 104                -- design units: an icon's cell (its name wraps no wider)
local EDGE = 14                   -- from the screen's edges
local GAP = 14                    -- between cells
local DOUBLE_MS = 450             -- a second click this soon opens

local _tex = {}
local function icon(name)
    if name == nil then return nil end
    local t = _tex[name]
    if t == nil then t = Texture.getSharedTexture(ICON_DIR .. name .. ".png", NEAREST) or false; _tex[name] = t end
    return t or nil
end

-- the icons, top first; each opens what its File / Multiplayer / Settings item opens
local function items()
    local A = MM.act
    return {
        { id = "pz", label = "Project Zomboid", open = function() MM.showView("main") end },
        { id = "newgame", label = ZeD.btnCase(getText("UI_NewGameScreen_title")), open = function() A.newGame() end },
        { id = "load", label = ZeD.tr("UI_ZeD_MainMenu_LoadGame"), open = function() A.load() end, off = function() return not MM.hasSaves() end },
        { id = "join", label = ZeD.tr("UI_ZeD_MainMenu_JoinServer"), open = function() A.join() end },
        { id = "options", label = ZeD.btnCase(getText("UI_mainscreen_option")), open = function() A.options() end },
        { id = "mods", label = getText("UI_NewGame_Mods"), open = function() A.mods() end },
        -- the Workshop window, where Steam offers it; named Mod Uploader and drawn
        -- as the kind of FTP program a 1993 desktop would upload with
        { id = "uploader", label = ZeD.tr("UI_ZeD_Desktop_ModUploader"), open = function() A.workshop() end,
          hide = function() local m = MainScreen and MainScreen.instance; return not (m and m.workshopOption) end },
    }
end
local TRASH = { id = "trash", label = "UI_ZeD_Desktop_Trash", open = function() MM.showView("trash") end }   -- (label: a translation key, drawn through ZeD.tr)

-- The icon pictures are loose textures the engine streams in after boot, so they arrive
-- later than their plain-text names would: they are asked for now, the menu's wake-up
-- waits for them with the desk's own pictures, and a cell draws its name only once its
-- picture is in, so the two always arrive together
local ICON_IDS = { "pz", "newgame", "load", "join", "options", "mods", "uploader", "trash", "computer", "cletusworks", "note", "mail", "documents" }
pcall(function() for _, n in ipairs(ICON_IDS) do Texture.getSharedTexture(ICON_DIR .. n .. ".png", NEAREST) end end)
local function iconReady(t)
    if not t then return true end
    local ok, r = pcall(function() return t:isReady() end)
    return (not ok) or r
end
MM.readyChecks = MM.readyChecks or {}
MM.readyChecks.desktopIcons = function()
    for _, n in ipairs(ICON_IDS) do if not iconReady(icon(n)) then return false end end
    return true
end

-- the icons' places on the screen: { item, x, y, w, h (the cell), ix, iy, isz (the picture), ly, lh (its name),
-- left (a left-edge item) }
local function cells(L)
    local T = ZeD.T
    local k = math.max(1, math.floor((T.scale or 1) + 0.5))
    local isz = ICON_PX * k
    local labelH = MM.fontH(T.fontF2) + T.px(4)
    local cw = math.max(T.px(CELL_W), isz + T.px(16))
    local ch = isz + T.px(6) + labelH
    local x = L.tx + L.tw - T.px(EDGE) - cw
    local y = L.ty + T.px(U.BAR_H) + T.px(EDGE)
    local out = {}
    local function place(it, cy)
        out[#out + 1] = { item = it, x = x, y = cy, w = cw, h = ch, ix = x + math.floor((cw - isz) / 2), iy = cy, isz = isz, ly = cy + isz + T.px(6), lh = labelH }
    end
    -- top down; a cell that would reach the Trash starts a column to the left (a short screen at a big scale)
    local top, trashY = y, L.ty + L.th - T.px(EDGE) - ch
    for _, it in ipairs(items()) do
        if not (it.hide and it.hide()) then
            if y > top and y + ch > trashY - T.px(GAP) then x = x - cw - T.px(GAP); y = top end
            place(it, y); y = y + ch + T.px(GAP)
        end
    end
    x = L.tx + L.tw - T.px(EDGE) - cw
    place(TRASH, trashY)
    -- the left side: each item a cell of its own size (the sticky's is bigger), an icon centered in its column
    local rightX = x
    for _, c in ipairs(out) do if c.x < rightX then rightX = c.x end end
    local lx, ly = L.tx + T.px(EDGE), top
    -- (clear of the controller's prompts along the screen's foot, which sit at the left: the same place with a mouse)
    local colW, bottom = 0, L.ty + L.th - T.px(EDGE) - T.sp.scrollbarW - T.px(GAP)
    local full = false
    local free = {}           -- moved items: laid out last (below)
    for _, it in ipairs(MM.leftItems and MM.leftItems() or {}) do
        local iw, ih = cw, ch
        if it.size then iw, ih = it.size() end
        if not full and not (it.hide and it.hide()) then
            -- an item that can be moved (the sticky note, punch list 114): the room it moves in, the whole desktop
            -- under the menu bar; placed by its own fractions of that room, else it keeps its spot in the column
            local room = it.place and { x0 = L.tx + T.px(EDGE), y0 = top,
                x1 = math.max(L.tx + T.px(EDGE), L.tx + L.tw - T.px(EDGE) - iw), y1 = math.max(top, L.ty + L.th - T.px(EDGE) - ih) } or nil
            local fx, fy
            if room then fx, fy = it.place() end
            if fx and fy then
                local cx = math.floor(room.x0 + fx * (room.x1 - room.x0) + 0.5)
                local cy = math.floor(room.y0 + fy * (room.y1 - room.y0) + 0.5)
                free[#free + 1] = { item = it, x = cx, y = cy, w = iw, h = ih, ix = cx + math.floor((iw - isz) / 2), iy = cy, isz = isz,
                                    ly = cy + isz + T.px(6), lh = labelH, left = true, free = true, room = room }
            else
                if ly > top and ly + ih > bottom then lx = lx + colW + T.px(GAP); ly = top; colW = 0 end
                local colAfter = math.max(colW, iw)
                if lx + colAfter > rightX - T.px(GAP) then
                    full = true                                 -- (the rest are in the notepad's Open list)
                else
                    colW = colAfter
                    local cx = it.size and lx or (lx + math.floor((math.max(colW, cw) - iw) / 2))
                    out[#out + 1] = { item = it, x = cx, y = ly, w = iw, h = ih, ix = cx + math.floor((iw - isz) / 2), iy = ly, isz = isz,
                                      ly = ly + isz + T.px(6), lh = labelH, left = true, room = room }
                    ly = ly + ih + T.px(GAP)
                end
            end
        end
    end
    -- a moved item is a note stuck on the screen: drawn after every icon and its hit registered last, so it lies over
    -- an icon it was dropped on and its strip still takes the pointer there (QA's Mac run, Nov 10 2026: dropped in the
    -- top left corner it sat under CletusWorks and Mail, and could not be picked up again)
    for _, c in ipairs(free) do out[#out + 1] = c end
    return out
end
MM._deskCells = cells

--- The icon block as the main window's small layout needs it (ZeD_MainMenu.lua: MM.smallFits and the window's
--- build): its width across the columns the cells wrap into, the edge and the gap in px, and whether every
--- column is still on the monitor.
function MM.iconBlock(L)
    local T = ZeD.T
    local cs = cells(L)
    local minX = L.tx + L.tw
    for _, c in ipairs(cs) do if c.x < minX and not c.left then minX = c.x end end   -- (the left side lies under the window)
    local right = L.tx + L.tw - T.px(EDGE)
    return { w = right - minX, edge = T.px(EDGE), gap = T.px(GAP), fits = minX >= L.tx + T.px(EDGE) }
end

-- ============================================================================
-- THE ICON LAYER (a child of the desk under the windows; the "desktop" view's
-- controller and keys come here too)
-- ============================================================================
ZeD_MMIcons = ISPanel:derive("ZeD_MMIcons")

function ZeD_MMIcons:new()
    local o = ISPanel:new(0, 0, 1, 1)   -- draws over the desk; the desk's pointer tests its hits
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o._hits = {}
    o.focusId = nil      -- the selected icon (the controller's focus is the selection)
    o._lastClick = nil   -- { id, at } for the second click
    return o
end

function ZeD_MMIcons:onShow()
    if not self.focusId then self.focusId = "pz" end
end

function ZeD_MMIcons:find(id)
    for _, c in ipairs(self._cells or {}) do if c.item.id == id then return c end end
    return nil
end

function ZeD_MMIcons:open(id)
    local c = self:find(id)
    if not c then return end
    if c.item.off and c.item.off() then return end
    self._lastClick = nil
    self._openedAt = MM.now()
    MM.clickSound()
    c.item.open()
end

-- A double-click counted on every frame drawn. The desk's pointer runs in update(), every 100 ms, and a quick second
-- press can fall inside the same update as the first's release, so the pointer saw one click. Here each press is seen
-- the frame it comes; it counts only on the icon the pointer itself has under the mouse (MM.ctx.hot), so a window over
-- the icons, a menu or a dialog still keeps it out.
function ZeD_MMIcons:framePress()
    local down = isMouseButtonDown(0)
    local fresh = down and not self._frameDown
    self._frameDown = down
    if not fresh then return end
    local mx, my = getMouseX(), getMouseY()
    for _, h in ipairs(self._hits) do
        if mx >= h.x and mx < h.x + h.w and my >= h.y and my < h.y + h.h and MM.ctx.hot == h.id then
            local id, t, fp = string.sub(h.id, 6), MM.now(), self._framePress
            if fp and fp.id == id and t - fp.at < DOUBLE_MS then
                self._framePress = nil
                self:open(id)
            else
                self._framePress = { id = id, at = t }
            end
            return
        end
    end
    self._framePress = nil
end

function ZeD_MMIcons:click(id)
    local t = MM.now()
    if self._openedAt and t - self._openedAt < DOUBLE_MS then return end   -- (the frames' double-click already opened it)
    local lc = self._lastClick
    if lc and lc.id == id and t - lc.at < DOUBLE_MS then self:open(id); return end
    self.focusId = id
    self._lastClick = { id = id, at = t }
    MM.hoverSound()
end

function ZeD_MMIcons:prerender()
    local T = ZeD.T
    local L = MM.layout()
    -- (the drag first, on last frame's cells: the note is laid out where the pointer has it now, no frame behind)
    self:dragFrame()
    self._hits = {}
    local list = cells(L)
    self._cells = list
    local f2 = T.fontF2
    local ac, tc, onAc = T.accent, T.text, T.textOnAccent
    for _, c in ipairs(list) do
        local it = c.item
        local off = it.off and it.off()
        local sel = self.focusId == it.id
        local tex = icon(it.icon or it.id)
        local ready = iconReady(tex)
        if it.draw then                                   -- (an item that draws itself: the sticky note)
            it.draw(self, c, sel)
            ready = false
            self._hits[#self._hits + 1] = { id = "desk:" .. it.id, x = c.x, y = c.y, w = c.w, h = c.h, fn = function() self:click(it.id) end }
        end
        local k = sel and 0.55 or 1                       -- a selected icon darkens, as they did
        if ready then                                     -- (picture and name come together)
        if tex then self:drawTextureScaledAspect(tex, c.ix, c.iy, c.isz, c.isz, off and T.disabledAlpha or 1, k, k, k) end
        -- its name, on a theme backing (surf1) so it reads over the painting on every theme; selected: the accent
        local name = ZeD.Atoms.truncateText((it.id == "trash") and ZeD.tr(it.label) or it.label, f2, c.w - T.px(4))
        local nw = MM.textW(f2, name)
        local nx = c.x + math.floor((c.w - nw) / 2)
        local bx, bw = nx - T.px(4), nw + T.px(8)
        if sel then
            self:drawRect(bx, c.ly, bw, c.lh, 1, ac.r, ac.g, ac.b)
            self:drawText(name, nx, c.ly + T.px(2), onAc.r, onAc.g, onAc.b, off and T.disabledAlpha or 1, f2)
        else
            local s1 = T.surf1
            self:drawRect(bx, c.ly, bw, c.lh, 0.92, s1.r, s1.g, s1.b)
            self:drawText(name, nx, c.ly + T.px(2), tc.r, tc.g, tc.b, off and T.disabledAlpha or 1, f2)
        end
        if not off then
            self._hits[#self._hits + 1] = { id = "desk:" .. it.id, x = c.x, y = c.y, w = c.w, h = c.h, fn = function() self:click(it.id) end }
        end
        end
    end
    self:framePress()
    -- the controller's prompts along the screen's foot (the bare desktop only)
    if MM.view == "desktop" and MM.gamepad() then
        local h = T.sp.scrollbarW
        local y = L.ty + L.th - h - T.px(EDGE)
        local s2, bs = T.surf2, T.borderS
        local prompts = self:prompts()
        local w = math.max(T.px(260), (MM._measurePrompts(h, prompts) or 0) + T.sp.sm * 2)
        self:drawRect(L.tx + T.px(EDGE), y, w, h, 1, s2.r, s2.g, s2.b)
        self:drawRectBorder(L.tx + T.px(EDGE), y, w, h, bs.a or 1, bs.r, bs.g, bs.b)
        ZeD.Molecules.drawGlyphPrompts(self, L.tx + T.px(EDGE) + T.sp.sm, y, h, prompts)
    end
end

-- the prompts' width, drawn on a panel that only measures
local _measure = { drawText = function() end, drawRectBorder = function() end }
function MM._measurePrompts(h, prompts)
    return ZeD.Molecules.drawGlyphPrompts(_measure, 0, 0, h, prompts)
end

-- THE STICKY NOTE MOVES (punch list 114; the director, Nov 8 2026) ---------------------------------------------
-- An item with place / moveTo (the sticky) is moved by its top strip (grabH) with the mouse, and closed by the box at
-- that strip's right end (closeBox); on a controller A picks it up, the D-pad moves it, A puts it down, B puts it back
-- where it was, X writes on it and Y closes it. Show note in the ZeD menu brings it back where it last was.

-- the fractions of its room for a top left corner at (x, y)
local function fractions(room, x, y)
    local fx = (room.x1 > room.x0) and (x - room.x0) / (room.x1 - room.x0) or 0
    local fy = (room.y1 > room.y0) and (y - room.y0) / (room.y1 - room.y0) or 0
    return math.max(0, math.min(1, fx)), math.max(0, math.min(1, fy))
end
MM._stickyFractions = fractions

-- the press, the drag and the release, seen every frame (the desk's own pointer runs every 100 ms); only where the
-- desk's pointer has the item under it (MM.ctx.hot), so a window over the note keeps its own part
function ZeD_MMIcons:dragFrame()
    local down = isMouseButtonDown(0)
    local fresh = down and not self._dragDown
    self._dragDown = down
    local mx, my = getMouseX(), getMouseY()
    local d = self._drag
    if d then
        local c = self:find(d.id)
        if not c or not c.room then self._drag = nil; return end
        local fx, fy = fractions(c.room, mx - d.dx, my - d.dy)
        if down then
            c.item.moveTo(fx, fy, false)
        else
            c.item.moveTo(fx, fy, true)
            self._drag = nil
        end
        return
    end
    local cb = self._closePress
    if cb and not down then
        self._closePress = nil
        local c = self:find(cb)
        local r = c and c.item.closeBox and c.item.closeBox(c)
        if r and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h then self:closeItem(c) end
        return
    end
    if not fresh then return end
    for _, c in ipairs(self._cells or {}) do
        local it = c.item
        if it.moveTo and c.room and MM.ctx.hot == "desk:" .. it.id then
            local gh = it.grabH and it.grabH() or 0
            if mx >= c.x and mx < c.x + c.w and my >= c.y and my < c.y + gh then
                local r = it.closeBox and it.closeBox(c)
                if r and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h then
                    self._closePress = it.id
                else
                    self._drag = { id = it.id, dx = mx - c.x, dy = my - c.y }
                    self.focusId = it.id
                end
                return
            end
        end
    end
end

function ZeD_MMIcons:closeItem(c)
    if self._carry and self._carry.id == c.item.id then self._carry = nil end
    c.item.close()
    MM.clickSound()
    -- (on a controller the selection goes to the next thing on the desktop; with the mouse nothing is selected after,
    -- as a closed window leaves nothing selected: QA's Mac run, Nov 10 2026, read CletusWorks lit under the closed note
    -- as the click going through to it)
    if self.focusId == c.item.id then
        if MM.gamepad() then
            local nxt = nil
            for _, o in ipairs(self._cells or {}) do if o ~= c and o.left and not (o.item.off and o.item.off()) then nxt = o.item.id; break end end
            self.focusId = nxt or "pz"
        else
            self.focusId = nil
        end
    end
end

-- the selected item, when it is one that moves
function ZeD_MMIcons:movable()
    local c = self:find(self.focusId or "")
    return (c and c.item.moveTo and c.room) and c or nil
end

-- the controller's prompts along the foot: what A, X and Y do on the note, or while carrying it
function ZeD_MMIcons:prompts()
    local dpad = ZeD.tr("UI_ZeD_Desktop_PromptDpad")
    if self._carry then
        return { dpad, { glyph = "A", label = ZeD.tr("UI_ZeD_Desk_StickyPutDown") }, { glyph = "B", label = getText("UI_Cancel") } }
    end
    if self:movable() then
        return { dpad, { glyph = "A", label = ZeD.tr("UI_ZeD_Desk_StickyPickUp") }, { glyph = "X", label = ZeD.tr("UI_ZeD_Notebook_Write") },
                 { glyph = "Y", label = getText("UI_Close") } }
    end
    return { dpad, { glyph = "A", label = getText("IGUI_Open") } }
end

-- CONTROLLER + KEYS (the "desktop" view) ------------------------------------------
function ZeD_MMIcons:joyDir(dir)
    local carry = self._carry
    if carry then
        -- carrying the note: the D-pad moves it a step (16 units) inside its room
        local c = self:find(carry.id)
        if not (c and c.room) then self._carry = nil; return end
        local step = ZeD.T.px(16)
        local x, y = c.x, c.y
        if dir == "left" then x = x - step elseif dir == "right" then x = x + step
        elseif dir == "up" then y = y - step elseif dir == "down" then y = y + step end
        local fx, fy = fractions(c.room, x, y)
        c.item.moveTo(fx, fy, false)
        MM.hoverSound()
        return
    end
    local cur = self:find(self.focusId or "pz")
    if not cur then self.focusId = "pz"; return end
    local cands = {}
    for _, c in ipairs(self._cells or {}) do if c ~= cur and not (c.item.off and c.item.off()) then cands[#cands + 1] = c end end
    local best = ZeD.SpatialNav.pick(cur, cands, dir)
    if best then self.focusId = best.item.id; MM.hoverSound() end
end
function ZeD_MMIcons:joyA()
    local carry = self._carry
    if carry then
        -- put it down where it is
        local c = self:find(carry.id)
        self._carry = nil
        if c and c.room then
            local fx, fy = fractions(c.room, c.x, c.y)
            c.item.moveTo(fx, fy, true)
        end
        MM.clickSound()
        return
    end
    local c = self:movable()
    if c then
        -- pick it up: B puts it back where it was
        local fx, fy = c.item.place()
        self._carry = { id = c.item.id, fx = fx, fy = fy }
        MM.clickSound()
        return
    end
    self:open(self.focusId or "pz")
end
function ZeD_MMIcons:joyB()
    local carry = self._carry
    if not carry then return end
    self._carry = nil
    local c = self:find(carry.id)
    if c then c.item.moveTo(carry.fx, carry.fy, false) end
    MM.hoverSound()
end
function ZeD_MMIcons:joyX()
    if self._carry then return end
    local c = self:movable()
    if c then self:open(c.item.id) end          -- (writes on the note: the keyboard comes up)
end
function ZeD_MMIcons:joyY()
    if self._carry then return end
    local c = self:movable()
    if c and c.item.close then self:closeItem(c) end
end
function ZeD_MMIcons:getFooterPrompts() return nil end
function ZeD_MMIcons:keyEscape()
    if self._carry then self:joyB(); return true end   -- (carrying the note: Escape puts it back, as B does)
    return false
end
function ZeD_MMIcons:keyOther(key)
    if MM.stickyTyping and MM.stickyTyping() then return false end   -- (the sticky note has the keys)
    -- (Enter on the note writes on it, as it always did: picking it up is the controller's A)
    if key == Keyboard.KEY_RETURN then
        if self._carry then self:joyA() elseif self:movable() then self:open(self.focusId) else self:joyA() end
        return true
    end
    if key == Keyboard.KEY_UP then self:joyDir("up"); return true end
    if key == Keyboard.KEY_DOWN then self:joyDir("down"); return true end
    if key == Keyboard.KEY_LEFT then self:joyDir("left"); return true end
    if key == Keyboard.KEY_RIGHT then self:joyDir("right"); return true end
    return false
end

-- ============================================================================
-- THE TRASH (a small window on the desktop)
-- ============================================================================
ZeD_MMTrash = ZeD_MMWindow:derive("ZeD_MMTrash")

local TRASH_W = 440
local FILE = { name = "UI_ZeD_Desktop_FileName", size = "40 MB", kind = "UI_ZeD_Desktop_FileKind" }   -- (name, kind: translation keys)

function ZeD_MMTrash:new()
    local o = ZeD_MMWindow.new(self, "trash")
    o.noResetControl = true
    return o
end

function ZeD_MMTrash:onShow()
    self.confirm = false
    self.focusId = "close"
end

-- the question in the band (the main window's own, a band swap); off, the
-- controller goes back to Empty trash
function ZeD_MMTrash:setConfirm(on)
    ZeD_MMWindow.setConfirm(self, on)
    if not on then self.focusId = "empty" end
end

function ZeD_MMTrash:close()
    MM.clickSound()
    MM.showView("desktop")
end
function ZeD_MMTrash:back() self:close() end

-- emptying it throws the computer away
function ZeD_MMTrash:empty() self:setConfirm(true) end

function ZeD_MMTrash:prerender()
    local T = ZeD.T
    local L = MM.layout()
    self._specs, self._hits = {}, {}
    local f2, f3 = T.fontF2, T.fontF3
    local pad = T.px(U.STACK_PAD)
    local k = math.max(1, math.floor((T.scale or 1) + 0.5))
    local isz = ICON_PX * k
    local rowH = isz + T.px(12)
    local stripH = MM.bandH()
    local tb = T.titleBarH
    local w = math.min(T.px(TRASH_W), L.tw - T.px(40))
    local h = tb + pad + rowH + T.px(2) + pad + stripH + self:footerHeight()
    local x = L.tx + math.floor((L.tw - w) / 2)
    local y = L.ty + T.px(U.BAR_H) + math.floor((L.th - T.px(U.BAR_H) - h) / 2)
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self.title = ZeD.tr("UI_ZeD_Desktop_Trash")
    self.titleStats = { { text = ZeD.tr("UI_ZeD_Desktop_OneItem"), noMark = true } }   -- (no status mark: a plain count)
    ZeD_Window.prerender(self)

    -- the one file in it
    local bx, by, bw = pad, tb + pad, w - pad * 2
    UI.insetBox(self, bx, by, bw, rowH + T.px(2))
    local ry = by + T.px(1)
    local tex = icon("computer")
    if tex then self:drawTextureScaledAspect(tex, bx + T.px(10), ry + math.floor((rowH - isz) / 2), isz, isz, 1, 1, 1, 1) end
    local tc, td = T.text, T.textDim
    local nx = bx + T.px(20) + isz
    self:drawText(ZeD.tr(FILE.name), nx,ry + math.floor(rowH / 2) - MM.fontH(f2), tc.r, tc.g, tc.b, tc.a or 1, f2)
    self:drawText(ZeD.tr(FILE.kind), nx, ry + math.floor(rowH / 2), td.r, td.g, td.b, td.a or 1, f2)
    self:drawText(FILE.size, bx + bw - T.px(12) - MM.textW(f3, FILE.size), ry + math.floor((rowH - MM.fontH(f3)) / 2), td.r, td.g, td.b, td.a or 1, f3)

    local stripY = h - self:footerHeight() - stripH
    if self.confirm then
        UI.stripSpecs(self, stripY, w, 1000, {},
            { { "confirm:no", getText("UI_btn_cancel"), function() self:setConfirm(false) end, "default" },
              { "confirm:yes", getText("UI_mainscreen_exit"), MM.act.quit, "danger", false, ZeD.tr("UI_ZeD_MMHelp_QuitGame") } },
            ZeD.tr("UI_ZeD_MainMenu_AskQuitGame"))
    else
        UI.stripSpecs(self, stripY, w, 1000,
            { { "close", getText("UI_btn_close"), function() self:close() end } },
            { { "empty", ZeD.tr("UI_ZeD_Desktop_EmptyTrash"), function() self:empty() end } })
    end
end

function ZeD_MMTrash:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

function ZeD_MMTrash:joyB() if self.confirm then self:setConfirm(false) else self:close() end end
function ZeD_MMTrash:getFooterPrompts()
    if not MM.gamepad() then return nil end
    if self.confirm then return { { glyph = "A", label = getText("IGUI_Exit") }, { glyph = "B", label = getText("UI_Cancel") } } end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = getText("UI_Close") } }
end
function ZeD_MMTrash:keyEscape() self:joyB(); return true end

-- on the desk as the "trash" view (its icon opens it)
MM.addView("trash", "trashWin", function() return ZeD_MMTrash:new() end)
