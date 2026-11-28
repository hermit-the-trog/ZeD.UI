-- ZeD-UI/42/media/lua/client/ZeD/ZeD_MainMenuDesktopPick.lua
-- ============================================================================
-- THE DESKTOP WINDOW (Desktops, Nov 22 2026). Client; an organism (a window on the desk, the "desktopPick" view).
-- Settings, Desktop... opens it. It lays out every desktop ZeD OS has (ZeD_MainMenuDesktops.lua, ZeD.Desktops) as
-- swatches in four groups, Game art, Patterns, Quiet and Fun, each a heading over a grid of 8 columns. A swatch is
-- 64 x 48 units in a 1-hair frame with the option's name under it, and shows the desktop itself at its own dot size:
-- the patterns in the player's color, the flags as small copies, the painting and the title video as the game's own
-- pictures (MM.drawGameArt). The desktop in use is ringed in the accent and named in accent-text.
-- Picking a swatch sets the desktop at once and keeps it (MM.setDesktop): there is no Apply.
--   help line   "Name: note" for the swatch under the pointer or the controller's focus, else the desktop in use
--   band        left: where the patterns' color comes from (the game's own words for it); right: Done, which closes
--   controller  the D-pad walks the swatches and on to Done; A sets, B closes; nothing on L3 or R3
-- Handoff: ZeDUI/HANDOFF_design_desktops_20261122.md, section 1. The board (x 150, y 44 of a 960 x 720 tube at UI
-- scale 1) is the window centered under the menu bar, 660 units wide.
-- ============================================================================

require "ZeD/ZeD_MainMenu"
require "ZeD/ZeD_MainMenuSaves"
require "ZeD/ZeD_MainMenuDesktops"

local MM = ZeD.MainMenu
local U  = MM.U
local UI = MM.ui
local DT = ZeD.Desktops

-- design units
local WIN_W, WIN_TOP = 660, 20       -- the window's width; its gap under the menu bar
local COLS = 8                       -- swatches in a row
local SW_W, SW_H = 64, 48            -- a swatch
local NAME_GAP, ROW_GAP = 4, 8       -- swatch to its name; a row's name to the next row
local HEAD_GAP, GROUP_GAP = 4, 6     -- a heading to its grid; a group's last row to the next heading

ZeD_MMDesktopPick = ZeD_MMWindow:derive("ZeD_MMDesktopPick")

function ZeD_MMDesktopPick:new()
    local o = ZeD_MMWindow.new(self, "desktopPick")
    o.noResetControl = true
    o._fns = {}           -- each swatch's press, made once (the window does not make a closure a frame)
    o.scroll = 0          -- (DK44: the body's scroll on a short tube)
    return o
end

-- the controller starts on the desktop in use
function ZeD_MMDesktopPick:onShow()
    self.focusId = "sw:" .. MM.desktop()
    self.scroll, self._follow = 0, nil
end

function ZeD_MMDesktopPick:close()
    MM.clickSound()
    MM.showView("main")
end

-- a swatch's press: set that desktop, and the controller's focus with it
function ZeD_MMDesktopPick:pickFn(id)
    local fn = self._fns[id]
    if not fn then
        fn = function()
            MM.setDesktop(id)
            self.focusId = "sw:" .. id
        end
        self._fns[id] = fn
    end
    return fn
end

-- the help line's words for an option: "Name: note"
local function helpOf(id)
    return ZeD.tr("UI_ZeD_Desktop_Help", ZeD.tr(DT.nameKey(id)), ZeD.tr(DT.noteKey(id)))
end

--- the help line when nothing in the window set one this frame: the swatch under the pointer or the controller's
--- focus, else the desktop in use (ZeD.Help.take asks for it)
function ZeD_MMDesktopPick:getStatusLine()
    return helpOf(self._helpId or MM.desktop())
end

-- the height of the four groups, in px (fh1, fh2: the heading's and the names' font heights)
local function groupsH(fh1, fh2)
    local T = ZeD.T
    local rowH = T.px(SW_H) + T.px(NAME_GAP) + fh2 + T.px(ROW_GAP)
    local h = 0
    for gi, g in ipairs(DT.GROUPS) do
        local rows = math.ceil(#g.ids / COLS)
        h = h + fh1 + T.px(HEAD_GAP) + rows * rowH
        if gi < #DT.GROUPS then h = h + T.px(GROUP_GAP) end
    end
    return h
end

-- one swatch: its wash or focus mark, the desktop, its frame, the ring when in use, the name under it
function ZeD_MMDesktopPick:drawSwatch(id, x, y, sw, sh, cellW, fh2, t, current)
    local T, A = ZeD.T, ZeD.Atoms
    local gp = MM.gamepad()
    local sid = "sw:" .. id
    local hid = self.kind .. ":" .. sid
    local hot = (not gp) and MM.ctx.hot == hid
    local focused = gp and self.focusId == sid
    local hair = T.hair or 1
    -- the cell: the swatch and its name, a little room round them
    local m = T.px(3)
    local cx, cy, cw, ch = x - m, y - m, sw + m * 2, sh + T.px(NAME_GAP) + fh2 + m * 2
    local onFocus = false
    if focused then
        onFocus = ZeD.Focus.mark(self, cx, cy, cw, ch, MM.focusOpts(self)) and true or false
    elseif hot then
        local hv = T.hover
        self:drawRect(cx, cy, cw, ch, hv.a or 1, hv.r, hv.g, hv.b)   -- the accent-hover wash
    end
    -- the desktop itself; the game's two pictures through MM.drawGameArt (the video moves once a frame: here only
    -- while the tube shows something else)
    if not DT.drawChip(self, id, x, y, sw, sh) then
        MM.drawGameArt(self, id, x, y, sw, sh, t, current ~= "video")
    end
    A.frame(self, x, y, sw, sh, T.borderS)
    local inUse = id == current
    if inUse then   -- the accent ring: 2 hairs, 1 hair out from the swatch's frame
        A.frame(self, x - hair * 3, y - hair * 3, sw + hair * 6, sh + hair * 6, T.accent, 1, hair * 2)
    end
    -- the name, centered under the swatch, cut to its column
    local f2 = T.fontF2
    local name = A.truncateText(ZeD.tr(DT.nameKey(id)), f2, cellW - T.px(4))
    local nw = MM.textW(f2, name)
    local c = (onFocus and T.textOnFocus) or (inUse and (T.accentText or T.accent)) or T.text
    self:drawText(name, x + math.floor((sw - nw) / 2), y + sh + T.px(NAME_GAP), c.r, c.g, c.b, c.a or 1, f2)
    if hot or focused then self._helpId = id end
    -- for the pointer and the controller: the whole cell
    local fn = self:pickFn(id)
    local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()
    self._hits[#self._hits + 1] = { id = hid, x = ax + cx, y = ay + cy, w = cw, h = ch, fn = fn, sound = true }
    return cx, cy, cw, ch, fn
end

function ZeD_MMDesktopPick:prerender()
    local T = ZeD.T
    local L = MM.layout()
    self._specs, self._hits = {}, {}
    self._helpId = nil
    -- the patterns' color, read once this frame; every swatch reuses it (ZeD.Desktops.drawChip)
    DT.ground()
    local f1, f2 = T.fontF1, T.fontF2
    local fh1, fh2 = MM.fontH(f1), MM.fontH(f2)
    local barH, pad = T.px(U.BAR_H), T.px(U.STACK_PAD)
    local w = math.min(T.px(WIN_W), L.tw - T.px(40))
    local fit = T.titleBarH + pad * 2 + groupsH(fh1, fh2) + MM.bandH() + self:footerHeight()
    local h = math.min(L.th - barH - T.px(WIN_TOP) * 2, fit)
    -- (DK44, Nov 27 2026: a short tube or Large text: the body between the title bar and the band scrolls as one,
    -- the whole-card scroll, its bar on the window's right edge; the swatches' columns give it the room)
    local scrolls = h < fit
    local sbW = scrolls and T.sp.scrollbarW or 0
    local x = L.tx + math.floor((L.tw - w) / 2)
    local y = L.ty + barH + T.px(WIN_TOP)
    if self.x ~= x or self.y ~= y then self:setX(x); self:setY(y) end
    if self.width ~= w or self.height ~= h then self:setWidth(w); self:setHeight(h) end
    self.title = ZeD.tr("UI_ZeD_Desktop_Title")
    ZeD_Window.prerender(self)

    -- the four groups: a heading (F1, text-sec) over a grid of 8 columns
    local cellW = math.floor((w - pad * 2 - sbW) / COLS)
    local sw = math.min(T.px(SW_W), cellW - T.px(8))      -- (a narrow monitor, a Steam Deck: the swatch shrinks to its column)
    local sh = math.floor(sw * SW_H / SW_W)
    local rowH = sh + T.px(NAME_GAP) + fh2 + T.px(ROW_GAP)
    local inset = math.floor((cellW - sw) / 2)
    local current = MM.desktop()
    local t = MM.now()
    local hc = T.textSec or T.textDim
    local stripY = h - self:footerHeight() - MM.bandH()
    local vy, vh = T.titleBarH, math.max(1, stripY - T.titleBarH)
    local contentH = pad * 2 + groupsH(fh1, fh2)
    self.scroll = math.max(0, math.min(self.scroll or 0, math.max(0, contentH - vh)))
    self._body = scrolls and { x = 0, y = vy, w = w, h = vh, max = math.max(0, contentH - vh) } or nil
    if scrolls then self:setStencilRect(0, vy, w, vh) end
    local i0, h0 = #self._specs + 1, #self._hits + 1
    local cy = T.titleBarH + pad - (scrolls and self.scroll or 0)
    local row = 0
    for gi, g in ipairs(DT.GROUPS) do
        self:drawText(ZeD.textCase(ZeD.tr(g.key)), pad + inset, cy, hc.r, hc.g, hc.b, hc.a or 1, f1)
        cy = cy + fh1 + T.px(HEAD_GAP)
        for i, id in ipairs(g.ids) do
            local col = (i - 1) % COLS          -- (i - 1 is never negative here)
            if col == 0 and i > 1 then cy = cy + rowH end
            if col == 0 then row = row + 1 end
            local sx = pad + col * cellW + inset
            local hx, hy, hw, hh, fn = self:drawSwatch(id, sx, cy, sw, sh, cellW, fh2, t, current)
            self._specs[#self._specs + 1] = { id = "sw:" .. id, listRow = true, row = row, col = col + 1,
                                              x = hx, y = hy, w = hw, h = hh, fn = fn }
        end
        cy = cy + rowH
        if gi < #DT.GROUPS then cy = cy + T.px(GROUP_GAP) end
    end
    if scrolls then
        self:clearStencilRect()
        -- (the swatches out of sight take no press; their stops count only from inside the list, which then follows)
        local ay = self:getAbsoluteY()
        for i = #self._hits, h0, -1 do
            local ht = self._hits[i]
            local t0, t1 = math.max(ht.y, ay + vy), math.min(ht.y + ht.h, ay + vy + vh)
            if t1 <= t0 then table.remove(self._hits, i) else ht.y, ht.h = t0, t1 - t0 end
        end
        for i = i0, #self._specs do
            local sp = self._specs[i]
            sp.clipTop, sp.clipBot = vy, vy + vh
        end
        -- the controller's swatch scrolled into sight once, as the Workshop's form does
        if MM.gamepad() and self.focusId ~= self._follow then
            self._follow = self.focusId
            for i = i0, #self._specs do
                local sp = self._specs[i]
                if sp.id == self.focusId then
                    if sp.y < vy then self.scroll = math.max(0, self.scroll - (vy - sp.y) - T.px(8))
                    elseif sp.y + sp.h > vy + vh then self.scroll = math.min(self._body.max, self.scroll + (sp.y + sp.h - vy - vh) + T.px(8)) end
                end
            end
        end
        MM.scrollBar(self, "dp:track", w - sbW, vy, sbW, vh, self.scroll, contentH, function(v) self.scroll = v end, { step = rowH })
    end

    -- the band: where the patterns' color comes from (the game's own words for it, so it matches Options in every
    -- language), and Done
    UI.stripSpecs(self, stripY, w, 1000, {},
        { { "done", ZeD.tr("UI_ZeD_Desktop_Done"), function() self:close() end, "primary", false, MM.helpFor("close") } },
        ZeD.tr("UI_ZeD_Desktop_Foot", getText("UI_optionscreen_objHighlightColor")), true)
end

function ZeD_MMDesktopPick:render()
    UI.drawStripAndButtons(self)
    ZeD_Window.render(self)
end

-- CONTROLLER + KEYS ---------------------------------------------------------------
-- (the D-pad, A and B are ZeD_MMWindow's: the D-pad goes by place over the swatches and the band, A presses the focused
-- swatch or Done, B closes through self:close; L3 and R3 have nothing)
-- (on a controller the help line shows the prompts in place of the help words, so the focused swatch's "Name: note"
-- rides along as a plain prompt, last: a line too long for the window drops its prompts from the front)
function ZeD_MMDesktopPick:getFooterPrompts()
    if not MM.gamepad() then return nil end
    return { { glyph = "A", label = ZeD.tr("UI_ZeD_MainMenu_PromptSelect") }, { glyph = "B", label = ZeD.tr("UI_ZeD_Desktop_Done") },
             self:getStatusLine() }
end
function ZeD_MMDesktopPick:keyEscape() self:close(); return true end
-- (DK44) the wheel over the body scrolls it while it runs past the window
function ZeD_MMDesktopPick:wheel(del)
    local b = self._body
    if not b then return false end
    local mx, my = getMouseX() - self:getAbsoluteX(), getMouseY() - self:getAbsoluteY()
    if mx < b.x or mx > b.x + b.w or my < b.y or my > b.y + b.h then return false end
    self.scroll = math.max(0, math.min(b.max, (self.scroll or 0) + del * ZeD.T.px(SW_H)))
    return true
end
function ZeD_MMDesktopPick:onMouseWheel(del) return MM.wheel(del) end
function ZeD_MMDesktopPick:keyOther(key)
    if key == Keyboard.KEY_RETURN then self:close(); return true end   -- (Done is the default keycap)
    return false
end

-- (the wheel anywhere on the desk while the window is up: kept once, so a Lua reload never wraps the wrapper)
local _wheel = MM._pickWheelBase or MM.wheel
MM._pickWheelBase = _wheel
function MM.wheel(del)
    if MM.view == "desktopPick" and MM.root and MM.root.desktopPickWin and MM.root.desktopPickWin:wheel(del) then return true end
    return _wheel(del)
end

-- on the desk as the "desktopPick" view
MM.addView("desktopPick", "desktopPickWin", function() return ZeD_MMDesktopPick:new() end)

--- Open the Desktop window (Settings, Desktop...).
function MM.openDesktopPick()
    MM.ctx.open = nil
    MM.showView("desktopPick")
end
