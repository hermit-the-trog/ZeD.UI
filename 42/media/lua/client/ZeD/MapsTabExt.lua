-- ZeD-UI/42/media/lua/client/ZeD/MapsTabExt.lua
-- ============================================================================
-- MAPS TAB EXTENSIONS (Oct 26 2026; mockup zed_map_overlays_v1, approved "as
-- recommended" Oct 26 2026). ZeD's map is its own (ZeD_WorldMap in MapsTab.lua),
-- not the game's ISWorldMap, so what other mods hang on the game's map never
-- shows in it. This is the one general way in for them: a support file
-- (ModSupport/<mod id>.lua) or a ZeD piece of its own (MapsTabKey.lua, the map
-- key) registers an extension, and the Maps tab draws its pieces in places kept
-- for them, in the drawer and in the unfolded Map window alike, with the mouse
-- and the controller. MapsTab.lua calls in here at a handful of points; nothing
-- here does anything while no extension is registered.
--
--   ZeD.MapsTab.addExtension(id, def)    -- def fields, all optional:
--     order          lower first (the built-in key is 10)
--     button(win)    -> nil or { id, text, hint, help, icon = texture | glyph = fn(panel, x, y, s, c),
--                       on = bool, dim = bool, activate = fn(win) }
--                       one toolbar button after the inks: an icon button (a button with no
--                       picture is a push button with its words); hint = its name after the
--                       pointer rests (default text), help = the help line's words while it is
--                       pointed at (default hint); on = the active look, dim = the disabled look
--     row(win)       -> nil or { h = design px, draw = fn(ctx) }: a row under the toolbar
--     gridRow(win)   -> the same, under the disclosure's mark grid (while it is open)
--                       ctx: ctx:label(text), ctx:text(text, dim), ctx:gap(px),
--                       ctx:button(id, text, { on, dim, hint, help, activate }) (a push button;
--                       a greyed one's hint is its reason, said in the help line),
--                       ctx:slider(id, { w, min, max, step, get, set, tick, fmt, help })
--     side(win)      -> nil or { key, title, count, rows = { row, ... }, empty }: a section of
--                       the side list. row = { key, dot = color, check = bool, onCheck = fn(win),
--                       title, sub, warn, help, activate = fn(win), del = { ask, onYes = fn(win) } }.
--                       del.ask is the question before the delete, worded "<Verb> the <thing>?
--                       <What is lost>." (asked at the list's foot, with Cancel and Delete).
--                       The list shows only while it has something in it: docked at the right
--                       of the unfolded map, a panel over the map's right edge in the drawer
--                       (a list button on the toolbar shows / hides it there)
--     banner(win)    -> nil or text: drawn over the top of the map
--     overlay(mp, win, ox, oy) -> a panel over the map (map-local drawing; ox / oy turn its
--                       zones into the tab's coordinates); returns a list of zones
--                       { id, x, y, w, h, activate = fn(win), hint }
--     drawMap(mp, win)  draws over the map (map-local coordinates)
--     armed(win)     -> the extension's own tool is up (ZeD's mark tools are put down)
--     putDown(win)      ZeD picked up a mark tool: put the extension's tool down
--     mouseDown(mp, win, x, y) -> true takes the press: mouseMove / mouseUp(mp, win, x, y) follow
--     padA(mp, win, x, y, phase) controller A on the map's cursor while armed ("down", "hold", "up")
--     cursor(mp, win, x, y)  preview at the pointer (or the controller's cursor) while armed
--     mapMade(mp, win)  a map was made (the drawer's, or the unfolded window's)
--
-- HOOK_MAP.md, "Other mods' screens", lists who uses it.
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Atoms"
require "ZeD/AtomExtensions"
require "ZeD/Molecules"
require "ZeD/Tr"

ZeD = ZeD or {}
ZeD.MapsTab = ZeD.MapsTab or {}
local E = ZeD.MapsTabExt or {}
ZeD.MapsTabExt = E
E.list = E.list or {}

function ZeD.MapsTab.addExtension(id, def)
    def.id = id
    for i, d in ipairs(E.list) do
        if d.id == id then table.remove(E.list, i); break end
    end
    E.list[#E.list + 1] = def
    table.sort(E.list, function(a, b) return (a.order or 50) < (b.order or 50) end)
end

local function call(d, name, ...)
    local f = d[name]
    if not f then return nil end
    local ok, r = pcall(f, ...)
    if ok then return r end
    if not E._errOnce then E._errOnce = {} end
    local k = tostring(d.id) .. ":" .. name
    if not E._errOnce[k] then
        E._errOnce[k] = true
        print("[ZeD] map extension " .. k .. " failed: " .. tostring(r))
    end
    return nil
end

local function inRect(z, x, y) return z and x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end

-- the unfolded Map window draws through `panel`; the drawer otherwise
function E.isPopout(win, panel)
    return win._mapPopout ~= nil and panel == win._mapPopout._contentPanel
end

function E.anyArmed(win)
    for _, d in ipairs(E.list) do
        if call(d, "armed", win) then return d end
    end
    return nil
end

-- ZeD picked up one of its own mark tools
function E.putDownAll(win)
    for _, d in ipairs(E.list) do call(d, "putDown", win) end
end

-- ---------------------------------------------------------------------------
-- TOOLBAR BUTTONS (row one, after the inks)
-- ---------------------------------------------------------------------------
-- The controls are the library's: a toolbar button is an icon button (its name
-- in the hint, what it does in the help line), a row's button a push button with
-- its words. on = the active look (solid accent), dim = the disabled look; the
-- controller's mark is ZeD.Focus.mark's, in the window the control is drawn in.
local FOCUS, FOCUS_SOLID = {}, { solid = true }   -- the mark's opts (its window: the panel's)
local _ib, _pb, _pbCol = {}, {}, {}

-- the help line's words for a button: a greyed one says why ("Line: Requires a
-- pen or pencil."); else its help, its hint or its words
local function helpOf(b)
    if b.dim and b.hint then return ZeD.tr("UI_ZeD_Map_HelpCant", b.text or "", b.hint) end
    return b.help or b.hint or b.text
end

-- One button at (x, y), h tall; returns its width. iconOnly: a toolbar button
-- (an icon button when it has a picture).
local function drawBtn(panel, win, b, x, y, h, iconOnly, focId)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local id = "map:ext:" .. b.id
    local pic = b.glyph or b.icon
    local focused = focId == id
    local w
    if pic and (iconOnly or not b.text) then
        w = h
        local o = _ib
        o.hover = A.mouseIn(panel, x, y, w, h)
        o.active, o.disabled, o.pressed = b.on and true or false, b.dim and true or false, false
        o.focus = focused and FOCUS or nil
        o.id = id
        o.hint = o.hover and (b.hint or b.text) or nil
        o.help = o.hover and helpOf(b) or nil
        M.drawIconButton(panel, x, y, h, pic, o)
    else
        local text = b.text or ""
        w = M.buttonW(text)
        local o = _pb
        o.hover = A.mouseIn(panel, x, y, w, h)
        o.disabled = b.dim and true or false
        o.focus = focused and (b.on and FOCUS_SOLID or FOCUS) or nil
        o.help = o.hover and helpOf(b) or nil
        -- on: the active look, solid accent with its words in textOnAccent
        local col = nil
        if b.on then
            col = _pbCol
            col.fill, col.text = T.accent, T.textOnAccent
        end
        M.drawButton(panel, x, y, w, h, text, b.on and "primary" or "default", false, col, o)
    end
    local z = { id = id, x = x, y = y, w = w, h = h, activate = b.activate }
    win._mapExtZones[#win._mapExtZones + 1] = z
    return w
end

-- The extensions' buttons from x on, row one; returns the x after them. The
-- list button (drawer only) comes last, while the side list has something in it.
-- noLead: no line before them (they start a row of their own).
function E.drawButtons(panel, win, x, y, h, focId, noLead)
    local T = ZeD.T
    local narrow = not E.isPopout(win, panel)
    local btns = {}
    for _, d in ipairs(E.list) do
        local b = call(d, "button", win)
        if b then btns[#btns + 1] = b end
    end
    if narrow and E.hasSide(win) then
        if win._mapSideOpen == nil then win._mapSideOpen = true end
        btns[#btns + 1] = { id = "list", icon = "view_list", text = ZeD.tr("UI_ZeD_Map_SideList"),
            help = ZeD.tr("UI_ZeD_Map_HelpSideList"),
            on = win._mapSideOpen, activate = function(w2) w2._mapSideOpen = not w2._mapSideOpen end }
    end
    if #btns == 0 then return x end
    -- a content line between the inks and these (1u T.border)
    if not noLead then
        ZeD.Atoms.drawDividerV(panel, x, y + T.px(4), h - T.px(8), false)
        x = x + T.hair + T.px(8)
    end
    for _, b in ipairs(btns) do
        x = x + drawBtn(panel, win, b, x, y, h, true, focId) + T.px(4)
    end
    return x
end

-- screen px the buttons drawButtons draws take (0 when there are none): the line before them, then each
-- button (an icon button, the standard height) and the 4 after it, the list button among them when any
-- extension fills the side list. MapsTab.lua puts them on a row of their own when row one has not the room.
function E.buttonsW(win, panel)
    local n = 0
    for _, d in ipairs(E.list) do
        if call(d, "button", win) then n = n + 1 end
    end
    if not E.isPopout(win, panel) and E.hasSide(win) then n = n + 1 end
    if n == 0 then return 0 end
    local T = ZeD.T
    return T.hair + T.px(8) + n * (T.buttonH + T.px(4))
end

-- ---------------------------------------------------------------------------
-- ROWS (under the toolbar, and under the mark grid)
-- ---------------------------------------------------------------------------
local Ctx = {}
Ctx.__index = Ctx

function Ctx:gap(px) self.cx = self.cx + ZeD.T.px(px or 6) end

-- the row's name, as the sort strip names itself: F1 in the secondary ink, sentence case
function Ctx:label(text)
    local T = ZeD.T
    local f1 = T.fontF1
    local c = T.textSec
    text = ZeD.Atoms.textCase(text or "")
    self.panel:drawText(text, self.cx, self.y + math.floor((self.h - ZeD.TM:getFontHeight(f1)) / 2), c.r, c.g, c.b, c.a or 1, f1)
    self.cx = self.cx + ZeD.TM:MeasureStringX(f1, text) + T.px(8)
end

function Ctx:text(text, dim)
    local T = ZeD.T
    local f1 = T.fontF1
    local c = dim and T.textSec or T.text
    self.panel:drawText(text or "", self.cx, self.y + math.floor((self.h - ZeD.TM:getFontHeight(f1)) / 2), c.r, c.g, c.b, c.a or 1, f1)
    self.cx = self.cx + ZeD.TM:MeasureStringX(f1, text or "") + ZeD.T.px(6)
end

-- a push button (the standard height, centred in the row)
function Ctx:button(id, text, o)
    o = o or {}
    local T = ZeD.T
    local bh = T.buttonH
    local w = drawBtn(self.panel, self.win, { id = id, text = text, on = o.on, dim = o.dim, hint = o.hint, help = o.help,
        activate = o.activate, icon = o.icon }, self.cx, self.y + math.floor((self.h - bh) / 2), bh, false, self.focId)
    self.cx = self.cx + w + T.px(4)
end

-- A slider in the look of ZeD setup's sliders (the library has no slider of its
-- own): the System 7 bar for the track (A.drawSmoothBar at the list rows' height),
-- a flat 12 x 18 thumb with a 1u frame, lit while pointed at or held, a tick at the
-- default, the value in words after it. Hover and the controller's mark are the
-- library's. Click or drag to set; the controller's D-pad left / right steps it
-- while it has the focus.
function Ctx:slider(id, o)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local panel = self.panel
    local w = T.px(o.w or 120)
    local x = self.cx
    local cy = self.y + math.floor(self.h / 2)
    local zid = "map:ext:" .. id
    local zx, zw = x - T.px(4), w + T.px(8)
    local hover = A.mouseIn(panel, zx, self.y, zw, self.h)
    local drag = self.win._mapExtDrag
    local held = drag ~= nil and drag.id == zid
    if hover then
        local hv = T.hover
        panel:drawRect(zx, self.y + T.px(4), zw, self.h - T.px(8), hv.a or 1, hv.r, hv.g, hv.b)
        local hl = o.help or o.hint
        if hl then ZeD.Help.set(panel, hl) end
    end
    if self.focId == zid then ZeD.Focus.mark(panel, zx, self.y + T.px(4), zw, self.h - T.px(8), FOCUS) end
    local span = math.max(1e-6, o.max - o.min)
    local v = o.get()
    local frac = (math.max(o.min, math.min(o.max, v)) - o.min) / span
    local bh = A.fillBarCompactH()
    A.drawSmoothBar(panel, x, cy - math.floor(bh / 2), w, frac, false, nil, bh)   -- (a track stays smooth: the thumb sits anywhere)
    if o.tick then
        local tx = x + math.floor((o.tick - o.min) / span * w)
        local ts = T.textSec
        panel:drawRect(tx, cy + math.ceil(bh / 2) + T.px(1), T.hair, T.px(4), ts.a or 1, ts.r, ts.g, ts.b)
    end
    local thW, thH = T.px(12), T.px(18)
    local thX, thY = x + math.floor(frac * w) - math.floor(thW / 2), cy - math.floor(thH / 2)
    local tb = (hover or held) and (T.accentBright or T.accent) or T.surf4
    panel:drawRect(thX, thY, thW, thH, 1, tb.r, tb.g, tb.b)
    A.frame(panel, thX, thY, thW, thH, T.borderS)
    local z = { id = zid, x = zx, y = self.y, w = zw, h = self.h, slider = o, sx = x, sw = w }
    self.win._mapExtZones[#self.win._mapExtZones + 1] = z
    self.cx = x + w + T.px(8)
    if o.fmt then
        local s = o.fmt(v)
        local tx = T.text
        panel:drawText(s, self.cx, self.y + math.floor((self.h - tm:getFontHeight(T.fontF1)) / 2), tx.r, tx.g, tx.b, tx.a or 1, T.fontF1)
        self.cx = self.cx + tm:MeasureStringX(T.fontF1, s) + T.px(8)
    end
end

-- a slider set from the pointer's x (tab coordinates), snapped to its step
local function setSlider(z, mx)
    local o = z.slider
    local f = math.max(0, math.min(1, (mx - z.sx) / math.max(1, z.sw)))
    local v = o.min + f * (o.max - o.min)
    if o.step and o.step > 0 then v = o.min + math.floor((v - o.min) / o.step + 0.5) * o.step end
    v = math.floor(math.max(o.min, math.min(o.max, v)) * 1e6 + 0.5) / 1e6   -- (no 0.9000000001)
    if math.abs(v - o.get()) > 1e-9 then o.set(v) end
end

local function stepSlider(z, dir)
    local o = z.slider
    local step = o.step or ((o.max - o.min) / 20)
    local v = o.get() + dir * step
    if o.step and o.step > 0 then v = o.min + math.floor((v - o.min) / o.step + 0.5) * o.step end
    v = math.floor(math.max(o.min, math.min(o.max, v)) * 1e6 + 0.5) / 1e6
    o.set(v)
end

-- Draws every extension's row of this kind ("row" / "gridRow") from y down;
-- returns the height drawn.
function E.drawRows(panel, win, x, y, w, kind, focId)
    local T = ZeD.T
    local total = 0
    for _, d in ipairs(E.list) do
        local r = call(d, kind, win)
        if r and r.draw then
            local h = T.px(r.h or 32)
            -- surface 2, one layer over the window (ZeD.Surface), a content line on top
            ZeD.Atoms.surfaceFill(panel, x, y + total, w, h, "surf2")
            ZeD.Atoms.drawDividerH(panel, x, y + total, w, false)
            local ctx = setmetatable({ panel = panel, win = win, x = x, y = y + total, w = w, h = h,
                cx = x + T.px(22), narrow = not E.isPopout(win, panel), focId = focId }, Ctx)
            local ok, err = pcall(r.draw, ctx)
            if not ok then call({ id = d.id, draw = function() error(err) end }, "draw") end
            total = total + h
        end
    end
    return total
end

-- ---------------------------------------------------------------------------
-- THE SIDE LIST
-- ---------------------------------------------------------------------------
local SIDE_W = 236

function E.sections(win)
    local now = getTimestampMs()
    if win._mapSideSecT and now - win._mapSideSecT < 100 then return win._mapSideSec end
    local out = {}
    local any = false
    for _, d in ipairs(E.list) do
        local s = call(d, "side", win)
        if s then
            out[#out + 1] = s
            if s.rows and #s.rows > 0 then any = true end
        end
    end
    win._mapSideSec = any and out or nil
    win._mapSideSecT = now
    return win._mapSideSec
end

function E.hasSide(win) return E.sections(win) ~= nil end

-- the side list's width while it is docked (unfolded map), else 0
function E.dockedSideW(win, panel)
    if not E.isPopout(win, panel) or not E.hasSide(win) then return 0 end
    return ZeD.T.px(SIDE_W)
end

-- The list is built from the library: section heads (M.drawSectionHeader), rows
-- with the hover wash, the selected wash and the controller's mark, a System 7
-- checkbox or a square status mark, prose in F2, an icon button to delete, a
-- scrollbar when it runs long, and the question before a delete as the band at
-- its foot (Cancel and Delete).
local ROW_PAD   = 8    -- design units: the text inset, and the gap after a row's mark
local ROW_TOP   = 6    -- design units: above the first line of a row (and below its last)
local SECTION_H = 20   -- design units: M.drawSectionHeader's height
local NO_LINES  = {}
local _delOpts, _askOpts, _askSpec = {}, {}, {}
local _askBtns = { {}, {} }

-- the delete button's picture
local function deletePic()
    return "no"   -- (the wheels' cross, a ZeD pixel icon)
end

-- the room a row's words have, in a list w wide (sbW: the scrollbar's width, or 0)
local function rowTextW(r, w, sbW)
    local T = ZeD.T
    local mark = 0
    if r.check ~= nil then mark = T.checkboxSz + T.px(ROW_PAD)
    elseif r.dot then mark = T.px(8) + T.px(ROW_PAD) end
    local del = r.del and (T.buttonH - T.px(4) + T.px(ROW_PAD)) or 0
    return w - T.px(ROW_PAD) * 2 - mark - del - sbW
end

local function rowHeight(r, tw)
    local T, tm = ZeD.T, ZeD.TM
    local h2 = tm:getFontHeight(T.fontF2)
    local lines = ZeD.Atoms.wrapText(r.title or "", T.fontF2, tw)
    r._lines = lines
    local n = #lines + (r.sub and 1 or 0) + (r.warn and 1 or 0)
    local h = T.px(ROW_TOP) * 2 + n * (h2 + T.px(1))
    return math.max(h, T.px(r.check ~= nil and 44 or 34))
end

-- every section's height, its rows measured, for a list w wide
local function measureSide(secs, w, sbW)
    local T, tm = ZeD.T, ZeD.TM
    local h2 = tm:getFontHeight(T.fontF2)
    local total = 0
    for _, s in ipairs(secs) do
        total = total + T.px(SECTION_H)
        if s.rows and #s.rows > 0 then
            for _, r in ipairs(s.rows) do
                r._h = rowHeight(r, rowTextW(r, w, sbW))
                total = total + r._h
            end
        elseif s.empty then
            s._lines = ZeD.Atoms.wrapText(s.empty, T.fontF2, w - T.px(ROW_PAD) * 2 - sbW)
            s._emptyH = T.px(8) * 2 + #s._lines * (h2 + T.px(2)) - T.px(2)
            total = total + s._emptyH
        else
            s._lines = nil
        end
    end
    return total
end

-- The question's footer: the band alone when the question fits its line, else
-- the question wrapped over the band's two answers (the list is narrow).
-- Returns its height and the wrapped lines (nil: one line in the band).
local function askLayout(ask, w)
    local T, tm, M = ZeD.T, ZeD.TM, ZeD.Molecules
    local room = w - T.px(8) * 3 - T.px(20) - M.buttonW(ZeD.tr("ContextMenu_Delete")) - M.buttonW(ZeD.tr("UI_Cancel"))
    local text = ask.text or ""
    if tm:MeasureStringX(T.fontF2, text) <= room then return M.bandH(), nil end
    local lines = ZeD.Atoms.wrapText(text, T.fontF2, w - T.px(8) * 2 - T.px(12))
    local h2 = tm:getFontHeight(T.fontF2)
    return T.px(8) * 2 + #lines * (h2 + T.px(2)) - T.px(2) + M.bandH(), lines
end

-- One row at (x, cy), w wide (the scrollbar's room left out); its zones go in
-- the tab's coordinates (ox, oy).
local function drawRow(target, win, s, r, x, cy, w, ox, oy, focId, ask)
    local T, A, tm = ZeD.T, ZeD.Atoms, ZeD.TM
    local rh = r._h
    local pad = T.px(ROW_PAD)
    local rid = "map:side:" .. tostring(s.key) .. ":" .. tostring(r.key)
    local act = r.activate
    if r.check ~= nil then act = r.onCheck end
    local rowZ = { id = rid, x = x + ox, y = cy + oy, w = w, h = rh, activate = act, row = r, sec = s }
    -- the delete button sits at the right; the row's hover leaves it out
    local ds = T.buttonH - T.px(4)
    local dx, dy = x + w - pad - ds, cy + math.floor((rh - ds) / 2)
    local overDel = r.del ~= nil and A.mouseIn(target, dx, dy, ds, ds)
    local hover = act ~= nil and not overDel and A.mouseIn(target, x, cy, w, rh)
    if ask and ask.row == r.key then
        -- the row the question is about: the selected wash
        local ac = T.accent
        target:drawRect(x, cy, w, rh, T.selectionA, ac.r, ac.g, ac.b)
    elseif hover then
        local hv = T.hover
        target:drawRect(x, cy, w, rh, hv.a or 1, hv.r, hv.g, hv.b)
    end
    if hover and r.help then ZeD.Help.set(target, r.help) end
    local onFocus = (focId == rid) and ZeD.Focus.mark(target, x, cy, w, rh, FOCUS)
    local f2 = T.fontF2
    local h2 = tm:getFontHeight(f2)
    local lx = x + pad
    local ty = cy + T.px(ROW_TOP)
    if r.check ~= nil then
        local cb = T.checkboxSz
        A.drawCheckbox(target, lx, ty + math.floor((h2 - cb) / 2), r.check and true or false, hover)
        lx = lx + cb + pad
    elseif r.dot then
        local box = T.px(8)
        A.drawStatusDot(target, lx, cy + math.floor((rh - box) / 2), r.dot, box)
        lx = lx + box + pad
    end
    local room = x + w - pad - (r.del and (ds + pad) or 0) - lx
    local tc = onFocus and T.textOnFocus or T.text
    for _, l in ipairs(r._lines or NO_LINES) do
        target:drawText(l, lx, ty, tc.r, tc.g, tc.b, tc.a or 1, f2)
        ty = ty + h2 + T.px(1)
    end
    if r.sub then
        local sc = onFocus and T.textOnFocus or T.textSec
        target:drawText(A.truncateText(r.sub, f2, room), lx, ty, sc.r, sc.g, sc.b, sc.a or 1, f2)
        ty = ty + h2 + T.px(1)
    end
    if r.warn then
        -- a warning: its square mark, the words in the text's own colour
        local sq = T.px(6)
        A.drawStatusDot(target, lx, ty + math.floor((h2 - sq) / 2), T.warning, sq)
        target:drawText(A.truncateText(r.warn, f2, room - sq - T.px(6)), lx + sq + T.px(6), ty, tc.r, tc.g, tc.b, tc.a or 1, f2)
    end
    win._mapExtZones[#win._mapExtZones + 1] = rowZ
    if r.del then
        local xz = { id = rid .. ":x", x = dx + ox, y = dy + oy, w = ds, h = ds,
            activate = function(w2) w2._mapSideAsk = { row = r.key, text = r.del.ask, onYes = r.del.onYes } end }
        local o = _delOpts
        o.hover = overDel
        o.focus = (focId == xz.id) and FOCUS or nil
        o.id = xz.id
        o.hint = overDel and ZeD.tr("ContextMenu_Delete") or nil
        o.help = overDel and ZeD.tr("UI_ZeD_Map_HelpRowDelete") or nil
        ZeD.Molecules.drawIconButton(target, dx, dy, ds, deletePic(), o)
        rowZ.del = xz
        table.insert(win._mapExtZones, #win._mapExtZones, xz)   -- (tested before its row)
    end
    -- a content line between rows
    A.drawDividerH(target, x, cy + rh - T.hair, w, false)
end

-- One section from cy down; returns the y after it.
local function drawSection(target, win, s, x, cy, w, ox, oy, focId, ask)
    local T, M = ZeD.T, ZeD.Molecules
    local pad = T.px(ROW_PAD)
    local headH = T.px(SECTION_H)
    M.drawSectionHeader(target, x + pad, cy, w - pad, s.title or "", s.count, true, false, nil, nil, pad, headH, true)
    cy = cy + headH
    if s.rows and #s.rows > 0 then
        for _, r in ipairs(s.rows) do
            drawRow(target, win, s, r, x, cy, w, ox, oy, focId, ask)
            cy = cy + r._h
        end
    elseif s._lines then
        M.drawEmptyLine(target, x + pad, cy + T.px(8), w - pad * 2, s.empty)
        cy = cy + (s._emptyH or 0)
    end
    return cy
end

-- The scrollbar at the list's right edge (the track's outer edge is the list's):
-- the thumb shows where the list is; a press or a drag on the track moves it.
local function drawSideScroll(target, win, sx, y, sw, h, contentH, maxOff, ox, oy)
    local T, A = ZeD.T, ZeD.Atoms
    A.drawScrollTrack(target, sx, y, sw, h)
    local th = math.max(T.px(20), math.floor(h * h / math.max(1, contentH)))
    local ty = y + math.floor((h - th) * ((win._mapSideScroll or 0) / math.max(1, maxOff)))
    local z = { id = "map:side:scroll", x = sx + ox, y = y + oy, w = sw, h = h, inert = true,
        scrollbar = { y = y + oy, h = h, th = th, max = maxOff } }
    local drag = win._mapExtDrag
    local state = "default"
    if drag ~= nil and drag.id == z.id then state = "dragging"
    elseif A.mouseIn(target, sx, ty, sw, th) then state = "hover" end
    A.drawScrollThumb(target, sx, ty, sw, th, state)
    table.insert(win._mapExtZones, 1, z)
end

-- The question before a delete, at the list's foot (fy): "<Verb> the <thing>?
-- <What is lost>." with its red square, then Cancel and Delete (danger).
local function drawSideAsk(target, win, x, fy, w, footH, ask, lines, ox, oy, focId)
    local T, A, M = ZeD.T, ZeD.Atoms, ZeD.Molecules
    local verb = ZeD.tr("ContextMenu_Delete")
    local noF = (focId == "map:side:no") and FOCUS or nil
    local yesF = (focId == "map:side:yes") and FOCUS or nil
    local cRect, vRect
    if not lines then
        local o = _askOpts
        o.danger, o.cancelFocus, o.verbFocus = true, noF, yesF
        local _
        _, cRect, vRect = M.drawQuestionBand(target, x, fy, w, ask.text or "", verb, o)
    else
        -- the question over the band, on the band's surface under its structure line
        local qH = footH - M.bandH()
        A.surfaceFill(target, x, fy, w, qH, "surf2")
        A.drawDividerH(target, x, fy, w, true)
        local f2 = T.fontF2
        local h2 = ZeD.TM:getFontHeight(f2)
        local sq = T.px(6)
        local ty = fy + T.px(8)
        A.drawStatusDot(target, x + T.px(8), ty + math.floor((h2 - sq) / 2), T.danger, sq)
        local tc = T.text
        for _, l in ipairs(lines) do
            target:drawText(l, x + T.px(8) + sq + T.px(6), ty, tc.r, tc.g, tc.b, tc.a or 1, f2)
            ty = ty + h2 + T.px(2)
        end
        local c, v = _askBtns[1], _askBtns[2]
        c.label, c.variant, c.focus, c.id = ZeD.tr("UI_Cancel"), "default", noF, "cancel"
        v.label, v.variant, v.focus, v.id = verb, "danger", yesF, "verb"
        _askSpec.buttons, _askSpec.noLine = _askBtns, true
        local _, out = M.drawBand(target, x, fy + qH, w, _askSpec)
        cRect, vRect = out.buttons[1], out.buttons[2]
    end
    local yz = { id = "map:side:yes", x = vRect.x + ox, y = vRect.y + oy, w = vRect.w, h = vRect.h,
        activate = function(w2) local a = w2._mapSideAsk; w2._mapSideAsk = nil; if a and a.onYes then a.onYes(w2) end end }
    local nz = { id = "map:side:no", x = cRect.x + ox, y = cRect.y + oy, w = cRect.w, h = cRect.h,
        activate = function(w2) w2._mapSideAsk = nil end }
    table.insert(win._mapExtZones, 1, yz)
    table.insert(win._mapExtZones, 1, nz)
end

-- Draws the side list on `target` at (x, y, w, h); (ox, oy) turn target
-- coordinates into the tab's (clicks are tested in the tab's coordinates).
-- overMap: a panel over the map (the drawer), which carries its own surface;
-- docked (the unfolded map) the window's own surface shows through.
function E.drawSide(target, win, x, y, w, h, ox, oy, focId, overMap)
    local secs = E.sections(win)
    if not secs then return end
    local T, A = ZeD.T, ZeD.Atoms
    if overMap then A.surfaceFill(target, x, y, w, h, "surf1") end
    win._mapSideZone = { x = x + ox, y = y + oy, w = w, h = h }
    -- the footer question (Delete ... ?), when one is asked
    local ask = win._mapSideAsk
    local footH, askLines = 0, nil
    if ask then footH, askLines = askLayout(ask, w) end
    local listH = h - footH
    -- content height (rows measured once a frame; again with the scrollbar's room when it runs long)
    local sbW = 0
    local contentH = measureSide(secs, w, 0)
    if contentH > listH then
        sbW = T.sp.scrollbarW
        contentH = measureSide(secs, w, sbW)
    end
    local maxOff = math.max(0, contentH - listH)
    win._mapSideScroll = math.max(0, math.min(win._mapSideScroll or 0, maxOff))
    local cy = y - win._mapSideScroll
    target:setStencilRect(x, y, w, listH)
    for _, s in ipairs(secs) do
        cy = drawSection(target, win, s, x, cy, w - sbW, ox, oy, focId, ask)
    end
    target:clearStencilRect()
    if sbW > 0 then drawSideScroll(target, win, x + w - sbW, y, sbW, listH, contentH, maxOff, ox, oy) end
    if ask then drawSideAsk(target, win, x, y + listH, w, footH, ask, askLines, ox, oy, focId) end
    -- the list's edge by the map (the line between the two panes), over all of it
    A.drawDividerV(target, x, y, h, true)
end

-- ---------------------------------------------------------------------------
-- OVER THE MAP: the extensions' drawing, their panels (the key), the side list
-- in the drawer, the area name. From ZeD_WorldMap:render. (The buttons' hints
-- are the library's, drawn by the window's overlay after the shared delay.)
-- ---------------------------------------------------------------------------
function E.drawMapUnder(mp, win)
    if #E.list == 0 then return end
    for _, d in ipairs(E.list) do call(d, "drawMap", mp, win) end
    -- an armed extension's preview at the pointer, or the controller's cursor
    local d = E.anyArmed(win)
    if d and d.cursor then
        local x, y
        if mp._gpCursorLive and mp._gpCursorX then x, y = mp._gpCursorX, mp._gpCursorY
        else x, y = mp:getMouseX(), mp:getMouseY() end
        if x >= 0 and y >= 0 and x <= mp:getWidth() and y <= mp:getHeight() then call(d, "cursor", mp, win, x, y) end
    end
end

function E.drawMapOver(mp, win, focId)
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local ox, oy = mp:getX(), mp:getY()
    -- the area name over the top of the map: a heading (F4) in a box of the
    -- window's surface with a 1u frame
    for _, d in ipairs(E.list) do
        local text = call(d, "banner", win)
        if text and text ~= "" then
            local f = T.fontF4
            text = A.truncateText(text, f, math.max(T.px(40), mp:getWidth() - T.px(56)))
            local tw = tm:MeasureStringX(f, text)
            local bw, bh = tw + T.px(24), tm:getFontHeight(f) + T.px(8)
            local bx, by = math.floor((mp:getWidth() - bw) / 2), T.px(8)
            A.surfaceFill(mp, bx, by, bw, bh, "surf1")
            A.frame(mp, bx, by, bw, bh, T.borderS)
            local th = T.textHead
            mp:drawText(text, bx + T.px(12), by + T.px(4), th.r, th.g, th.b, th.a or 1, f)
            break
        end
    end
    -- panels over the map (the key)
    for _, d in ipairs(E.list) do
        local zs = call(d, "overlay", mp, win, ox, oy, focId)
        if zs then
            for i = #zs, 1, -1 do table.insert(win._mapExtZones, 1, zs[i]) end
        end
    end
    -- the side list over the map's right edge (the drawer)
    if win._mapSideOpen and not mp._isPopoutMap and E.hasSide(win) then
        local w = math.min(T.px(SIDE_W), math.floor(mp:getWidth() * 0.6))
        E.drawSide(mp, win, mp:getWidth() - w, 0, w, mp:getHeight(), ox, oy, focId, true)
    end
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------

-- the side list's scrollbar set from the pointer's y (tab coordinates): the
-- thumb's middle goes under the pointer
local function setScroll(win, z, my)
    local s = z.scrollbar
    local f = (my - s.y - s.th / 2) / math.max(1, s.h - s.th)
    win._mapSideScroll = math.max(0, math.min(1, f)) * s.max
end

-- A click in the tab (tab coordinates). True when an extension's control took it.
function E.onClick(win, x, y)
    for _, z in ipairs(win._mapExtZones or {}) do
        if inRect(z, x, y) then
            if z.slider or z.scrollbar then
                if z.slider then setSlider(z, x) else setScroll(win, z, y) end
                win._mapExtDrag = z
                win._mapDragging = true
                return true
            end
            if z.activate then
                z.activate(win)
                pcall(function() getSoundManager():playUISound("UIActivateButton") end)
            end
            return true
        end
    end
    -- a click elsewhere in the side list (between rows) is the list's, not the map's
    if win._mapSideZone and inRect(win._mapSideZone, x, y) and E.hasSide(win) and (win._mapPopout or win._mapSideOpen) then
        return true
    end
    return false
end

-- the mouse wheel over the side list scrolls it (tab coordinates)
function E.wheel(win, x, y, del)
    local z = win._mapSideZone
    if z and inRect(z, x, y) and E.hasSide(win) and (win._mapPopout or win._mapSideOpen) then
        win._mapSideScroll = (win._mapSideScroll or 0) + del * ZeD.T.px(30)
        return true
    end
    return false
end

-- a slider or the side list's scrollbar being dragged, or a press an extension took on the map
function E.mouseMove(mp, win)
    local z = win._mapExtDrag
    if z then
        if not isMouseButtonDown(0) then win._mapExtDrag = nil; return true end
        if z.scrollbar then setScroll(win, z, mp:getMouseY() + mp:getY())
        else setSlider(z, mp:getMouseX() + mp:getX()) end
        return true
    end
    local d = mp._extCapture
    if d then call(d, "mouseMove", mp, win, mp:getMouseX(), mp:getMouseY()); return true end
    return false
end

function E.mouseUp(mp, win, x, y)
    if win._mapExtDrag then win._mapExtDrag = nil; return true end
    local d = mp._extCapture
    if d then
        mp._extCapture = nil
        call(d, "mouseUp", mp, win, mp:getMouseX(), mp:getMouseY())
        return true
    end
    return false
end

function E.mouseDown(mp, win, x, y)
    local d = E.anyArmed(win)
    if d and call(d, "mouseDown", mp, win, x, y) then
        mp._extCapture = d
        return true
    end
    return false
end

-- Each tick while the map's cursor has the controller: an armed extension
-- hears A going down, held and up at the cursor.
function E.padTick(win, mp, cid)
    local d = E.anyArmed(win)
    local down = false
    pcall(function() down = JoypadButton.A:isDown(cid) == true end)
    local x, y = mp._gpCursorX, mp._gpCursorY
    if not (d and x) then win._mapPadA = nil; return end
    if down and not win._mapPadA then
        win._mapPadA = true
        call(d, "padA", mp, win, x, y, "down")
    elseif down then
        call(d, "padA", mp, win, x, y, "hold")
    elseif win._mapPadA then
        win._mapPadA = nil
        call(d, "padA", mp, win, x, y, "up")
    end
end

-- the extensions' controls as controller stops (before the map's cursor)
function E.addFocusables(win, elements)
    for _, z in ipairs(win._mapExtZones or {}) do
        local el = { x = z.x, y = z.y, w = z.w, h = z.h, id = z.id }
        if z.slider then
            local zz = z
            el.onDpadDir = function(_, _, dir)
                if dir == "left" then stepSlider(zz, -1); return true end
                if dir == "right" then stepSlider(zz, 1); return true end
                return false
            end
        elseif z.activate then
            local zz = z
            el.onActivate = function(w2) zz.activate(w2) end
        end
        if z.row and z.row.del then
            local r = z.row
            el.onContextMenu = function(w2) w2._mapSideAsk = { row = r.key, text = r.del.ask, onYes = r.del.onYes } end
        end
        if not z.inert and not (z.row and z.row.del and z.id:sub(-2) == ":x") then elements[#elements + 1] = el end
    end
end

-- a map was made (drawer or unfolded window)
function E.mapMade(mp, win)
    for _, d in ipairs(E.list) do call(d, "mapMade", mp, win) end
end

-- ---------------------------------------------------------------------------
-- WHAT THE EXTENSIONS SHARE: the ink (MapsTab's rules) and the map's cursor
-- ---------------------------------------------------------------------------

-- where the map's pointer is (map-local), from the mouse or the controller's cursor
function E.pointer(mp)
    if mp._gpCursorLive and mp._gpCursorX then return mp._gpCursorX, mp._gpCursorY end
    return mp:getMouseX(), mp:getMouseY()
end
