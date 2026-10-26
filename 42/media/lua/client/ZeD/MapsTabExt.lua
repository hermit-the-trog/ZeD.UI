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
--     button(win)    -> nil or { id, text, hint, icon = texture | glyph = fn(panel, x, y, s, c),
--                       on = bool, dim = bool, activate = fn(win) }
--                       one toolbar button after the inks; in the World window's drawer it is
--                       an icon only, its words in a hover hint
--     row(win)       -> nil or { h = design px, draw = fn(ctx) }: a row under the toolbar
--     gridRow(win)   -> the same, under the disclosure's mark grid (while it is open)
--                       ctx: ctx:label(text), ctx:text(text, dim), ctx:gap(px),
--                       ctx:button(id, text, { on, dim, hint, activate }),
--                       ctx:slider(id, { w, min, max, step, get, set, tick, fmt })
--     side(win)      -> nil or { key, title, count, rows = { row, ... }, empty }: a section of
--                       the side list. row = { key, dot = color, check = bool, onCheck = fn(win),
--                       title, sub, warn, activate = fn(win), del = { ask, onYes = fn(win) } }.
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
local function focusFill(panel, x, y, w, h)
    local ac = ZeD.T.accent
    panel:drawRect(x, y, w, h, 0.55, ac.r, ac.g, ac.b)
end

-- a hover hint for this frame (drawn by the map, under the pointer's control)
local function hintCand(win, panel, z)
    if not z.hint then return end
    local mx, my = panel:getMouseX(), panel:getMouseY()
    if inRect(z, mx, my) then win._mapExtHint = { key = z.id, text = z.hint, x = z.x, y = z.y, w = z.w, h = z.h } end
end

local function drawBtn(panel, win, b, x, y, h, narrow, focId)
    local T, tm = ZeD.T, ZeD.TM
    local f1 = T.fontF1
    local icon = (b.icon or b.glyph) and true or false
    local isz = h - T.px(6)
    local text = b.text and ZeD.btnCase(b.text) or nil
    local w
    if narrow and icon then w = h
    else w = (icon and (isz + T.px(5)) or 0) + (text and tm:MeasureStringX(f1, text) or 0) + T.px(12) end
    local id = "map:ext:" .. b.id
    if focId == id then focusFill(panel, x, y, w, h) end
    local ac, bd = T.accent, T.border
    if b.on then
        panel:drawRect(x, y, w, h, 0.2, ac.r, ac.g, ac.b)
        panel:drawRectBorder(x, y, w, h, 0.6, ac.r, ac.g, ac.b)
    else
        panel:drawRectBorder(x, y, w, h, bd.a * 0.45, bd.r, bd.g, bd.b)
    end
    local c = b.on and T.accent or T.text
    local cx = x + (narrow and icon and math.floor((w - isz) / 2) or T.px(6))
    if b.glyph then
        b.glyph(panel, cx, y + T.px(3), isz, c)
    elseif b.icon then
        panel:drawTextureScaledAspect(b.icon, cx, y + T.px(3), isz, isz, 0.85, c.r, c.g, c.b)
    end
    if text and not (narrow and icon) then
        local tx = icon and (cx + isz + T.px(5)) or (x + T.px(6))
        panel:drawText(text, tx, y + math.floor((h - tm:getFontHeight(f1)) / 2), c.r, c.g, c.b, b.on and 0.95 or 0.8, f1)
    end
    if b.dim then
        local s = T.surf1
        panel:drawRect(x, y, w, h, 0.6, s.r, s.g, s.b)
    end
    local z = { id = id, x = x, y = y, w = w, h = h, activate = b.activate, hint = b.hint or (narrow and text) or nil }
    win._mapExtZones[#win._mapExtZones + 1] = z
    hintCand(win, panel, z)
    return w
end

-- The extensions' buttons from x on, row one; returns the x after them. The
-- list button (drawer only) comes last, while the side list has something in it.
function E.drawButtons(panel, win, x, y, h, focId)
    local T = ZeD.T
    local narrow = not E.isPopout(win, panel)
    local btns = {}
    for _, d in ipairs(E.list) do
        local b = call(d, "button", win)
        if b then btns[#btns + 1] = b end
    end
    if narrow and E.hasSide(win) then
        if win._mapSideOpen == nil then win._mapSideOpen = true end
        if not E._listTex then E._listTex = getTexture("media/textures/ZeD/icons/list.png") end
        btns[#btns + 1] = { id = "list", icon = E._listTex, text = ZeD.tr("UI_ZeD_Map_SideList"),
            on = win._mapSideOpen, activate = function(w2) w2._mapSideOpen = not w2._mapSideOpen end }
    end
    if #btns == 0 then return x end
    local sep = T.border
    panel:drawRect(x, y + T.px(4), T.px(1), h - T.px(8), sep.a * 0.4, sep.r, sep.g, sep.b)
    x = x + T.px(1) + T.px(8)
    for _, b in ipairs(btns) do
        x = x + drawBtn(panel, win, b, x, y, h, narrow, focId) + T.px(4)
    end
    return x
end

-- design px the World window's Maps drawer grows by for these buttons (icons
-- only there: 20 + 4 each, the separator before them, and the list button when
-- any extension fills the side list), so the toolbar's row still holds the
-- Survey / Color / Paper switch (ZeD_WorldWindow's getWorldTabDrawerW)
function E.drawerExtraW()
    local n, side = 0, false
    for _, d in ipairs(E.list) do
        if d.button then n = n + 1 end
        if d.side then side = true end
    end
    if side then n = n + 1 end
    if n == 0 then return 0 end
    return 13 + 24 * n
end

-- ---------------------------------------------------------------------------
-- ROWS (under the toolbar, and under the mark grid)
-- ---------------------------------------------------------------------------
local Ctx = {}
Ctx.__index = Ctx

function Ctx:gap(px) self.cx = self.cx + ZeD.T.px(px or 6) end

function Ctx:label(text)
    local T = ZeD.T
    local f5 = T.fontF5
    local ac = T.accent
    text = ZeD.upper(text or "")
    self.panel:drawText(text, self.cx, self.y + math.floor((self.h - ZeD.TM:getFontHeight(f5)) / 2), ac.r, ac.g, ac.b, 1, f5)
    self.cx = self.cx + ZeD.TM:MeasureStringX(f5, text) + T.px(8)
end

function Ctx:text(text, dim)
    local T = ZeD.T
    local f1 = T.fontF1
    local c = dim and T.textSec or T.text
    self.panel:drawText(text or "", self.cx, self.y + math.floor((self.h - ZeD.TM:getFontHeight(f1)) / 2), c.r, c.g, c.b, c.a or 1, f1)
    self.cx = self.cx + ZeD.TM:MeasureStringX(f1, text or "") + ZeD.T.px(6)
end

function Ctx:button(id, text, o)
    o = o or {}
    local T = ZeD.T
    local bh = T.px(20)
    local w = drawBtn(self.panel, self.win, { id = id, text = text, on = o.on, dim = o.dim, hint = o.hint,
        activate = o.activate, icon = o.icon }, self.cx, self.y + math.floor((self.h - bh) / 2), bh, false, self.focId)
    self.cx = self.cx + w + T.px(4)
end

-- a slider: a 4 px track, an 8 x 12 thumb in the accent, a tick (the default),
-- the value in words after it. Click or drag to set; the controller's D-pad
-- left / right steps it while it has the focus.
function Ctx:slider(id, o)
    local T, tm = ZeD.T, ZeD.TM
    local panel = self.panel
    local w = T.px(o.w or 120)
    local x = self.cx
    local cy = self.y + math.floor(self.h / 2)
    local zid = "map:ext:" .. id
    if self.focId == zid then focusFill(panel, x - T.px(3), self.y + T.px(4), w + T.px(6), self.h - T.px(8)) end
    local s4, bs, ac = T.surf4, T.borderS, T.accentBright or T.accent
    panel:drawRect(x, cy - T.px(2), w, T.px(4), 1, s4.r, s4.g, s4.b)
    panel:drawRectBorder(x, cy - T.px(2), w, T.px(4), bs.a, bs.r, bs.g, bs.b)
    local span = math.max(1e-6, o.max - o.min)
    if o.tick then
        local tx = x + math.floor((o.tick - o.min) / span * w)
        local ts = T.textSec
        panel:drawRect(tx, cy + T.px(4), T.px(1), T.px(4), 1, ts.r, ts.g, ts.b)
    end
    local v = o.get()
    local px = x + math.floor((math.max(o.min, math.min(o.max, v)) - o.min) / span * w)
    panel:drawRect(px - T.px(4), cy - T.px(6), T.px(8), T.px(12), 1, ac.r, ac.g, ac.b)
    panel:drawRectBorder(px - T.px(4), cy - T.px(6), T.px(8), T.px(12), 1, 0, 0, 0)
    local z = { id = zid, x = x - T.px(4), y = self.y, w = w + T.px(8), h = self.h, slider = o, sx = x, sw = w, hint = o.hint }
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
            local s2, bd = T.surf2, T.border
            panel:drawRect(x, y + total, w, h, s2.a, s2.r, s2.g, s2.b)
            panel:drawRect(x, y + total, w, T.px(1), bd.a * 0.3, bd.r, bd.g, bd.b)
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

local function rowHeight(r, w)
    local T, tm = ZeD.T, ZeD.TM
    local h1, h2 = tm:getFontHeight(T.fontF1), tm:getFontHeight(T.fontF2)
    local tw = w - T.px(16) - T.px(20) - (r.del and T.px(22) or 0)
    local lines = ZeD.Atoms.wrapText(r.title or "", T.fontF2, tw)
    r._lines = lines
    local h = T.px(12) + #lines * (h2 + T.px(1)) + (r.sub and (h1 + T.px(2)) or 0) + (r.warn and (h1 + T.px(2)) or 0)
    return math.max(h, T.px(r.check ~= nil and 44 or 34))
end

-- Draws the side list on `target` at (x, y, w, h); (ox, oy) turn target
-- coordinates into the tab's (clicks are tested in the tab's coordinates).
function E.drawSide(target, win, x, y, w, h, ox, oy, focId)
    local secs = E.sections(win)
    if not secs then return end
    local T, tm, A = ZeD.T, ZeD.TM, ZeD.Atoms
    local f1, f2, f5 = T.fontF1, T.fontF2, T.fontF5
    local h1, h2, h5 = tm:getFontHeight(f1), tm:getFontHeight(f2), tm:getFontHeight(f5)
    local s1, bs = T.surf1, T.borderS
    target:drawRect(x, y, w, h, 0.97, s1.r, s1.g, s1.b)
    target:drawRect(x, y, T.px(1), h, bs.a, bs.r, bs.g, bs.b)
    win._mapSideZone = { x = x + ox, y = y + oy, w = w, h = h }
    -- the footer question (Delete ... ?), when one is asked
    local ask = win._mapSideAsk
    local footH = 0
    local askLines
    if ask then
        askLines = A.wrapText(ask.text, f1, w - T.px(16))
        footH = T.px(14) + #askLines * (h1 + T.px(2)) + T.px(28)
    end
    local listH = h - footH
    -- content height (rows measured once a frame)
    local contentH = 0
    for _, s in ipairs(secs) do
        contentH = contentH + T.px(26)
        if s.rows and #s.rows > 0 then
            for _, r in ipairs(s.rows) do r._h = rowHeight(r, w); contentH = contentH + r._h end
        elseif s.empty then
            s._lines = A.wrapText(s.empty, f1, w - T.px(16))
            contentH = contentH + T.px(16) + #s._lines * (h1 + T.px(2))
        end
    end
    local maxOff = math.max(0, contentH - listH)
    win._mapSideScroll = math.max(0, math.min(win._mapSideScroll or 0, maxOff))
    local cy = y - win._mapSideScroll
    target:setStencilRect(x, y, w, listH)
    local ac, ts, tx, bd = T.accent, T.textSec, T.text, T.border
    for _, s in ipairs(secs) do
        -- section head: PLAYERS        3
        target:drawRect(x + T.px(1), cy + T.px(26) - T.px(1), w - T.px(1), T.px(1), bd.a, bd.r, bd.g, bd.b)
        target:drawText(ZeD.upper(s.title or ""), x + T.px(8), cy + math.floor((T.px(26) - h5) / 2), ac.r, ac.g, ac.b, 1, f5)
        if s.count then A.drawTextRight(target, tostring(s.count), x + w - T.px(8), cy + math.floor((T.px(26) - h1) / 2), f1, ts) end
        cy = cy + T.px(26)
        if s.rows and #s.rows > 0 then
            for _, r in ipairs(s.rows) do
                local rh = r._h
                local rid = "map:side:" .. tostring(s.key) .. ":" .. tostring(r.key)
                if focId == rid or focId == rid .. ":x" then focusFill(target, x + T.px(1), cy, w - T.px(1), rh) end
                if ask and ask.row == r.key then target:drawRect(x + T.px(1), cy, w - T.px(1), rh, 0.12, ac.r, ac.g, ac.b) end
                local lx = x + T.px(8)
                local rowZ = { id = rid, x = x + ox, y = cy + oy, w = w, h = rh, activate = r.activate, row = r, sec = s }
                if r.check ~= nil then
                    local cb = T.px(12)
                    local cz = { x = lx, y = cy + T.px(7), w = cb, h = cb }
                    target:drawRectBorder(cz.x, cz.y, cb, cb, bs.a, bs.r, bs.g, bs.b)
                    if r.check then
                        local ab = T.accentBright or T.accent
                        target:drawRect(cz.x + T.px(3), cz.y + T.px(3), cb - T.px(6), cb - T.px(6), 1, ab.r, ab.g, ab.b)
                    end
                    rowZ.activate = r.onCheck
                    lx = lx + cb + T.px(8)
                elseif r.dot then
                    local ds = T.px(8)
                    local dc = r.dot
                    target:drawRect(lx, cy + math.floor((rh - ds) / 2), ds, ds, 1, dc.r, dc.g, dc.b)
                    target:drawRectBorder(lx, cy + math.floor((rh - ds) / 2), ds, ds, 1, 0, 0.2, 0)
                    lx = lx + ds + T.px(8)
                end
                local ty = cy + T.px(6)
                for _, l in ipairs(r._lines or {}) do
                    target:drawText(l, lx, ty, tx.r, tx.g, tx.b, tx.a or 1, f2)
                    ty = ty + h2 + T.px(1)
                end
                if r.sub then target:drawText(r.sub, lx, ty, ts.r, ts.g, ts.b, ts.a or 1, f1); ty = ty + h1 + T.px(2) end
                if r.warn then local wc = T.warning; target:drawText(r.warn, lx, ty, wc.r, wc.g, wc.b, 1, f1) end
                win._mapExtZones[#win._mapExtZones + 1] = rowZ
                if r.del then
                    local xs = T.px(16)
                    local xx, xy = x + w - T.px(8) - xs, cy + T.px(6)
                    local xz = { id = rid .. ":x", x = xx + ox, y = xy + oy, w = xs, h = xs, hint = ZeD.tr("ContextMenu_Delete"),
                        activate = function(w2) w2._mapSideAsk = { row = r.key, text = r.del.ask, onYes = r.del.onYes } end }
                    target:drawRectBorder(xx, xy, xs, xs, bs.a, bs.r, bs.g, bs.b)
                    local mx, my = target:getMouseX(), target:getMouseY()
                    local xc = (inRect({ x = xx, y = xy, w = xs, h = xs }, mx, my) or focId == xz.id) and T.danger or ts
                    target:drawText("x", xx + math.floor((xs - tm:MeasureStringX(f1, "x")) / 2), xy + math.floor((xs - h1) / 2), xc.r, xc.g, xc.b, 1, f1)
                    rowZ.del = xz
                    table.insert(win._mapExtZones, #win._mapExtZones, xz)   -- (tested before its row)
                end
                target:drawRect(x + T.px(1), cy + rh - T.px(1), w - T.px(1), T.px(1), 0.5, 0.09, 0.09, 0.09)
                cy = cy + rh
            end
        elseif s._lines then
            local ey = cy + T.px(8)
            for _, l in ipairs(s._lines) do
                target:drawText(l, x + T.px(8), ey, ts.r, ts.g, ts.b, ts.a or 1, f1)
                ey = ey + h1 + T.px(2)
            end
            cy = ey + T.px(8)
        end
    end
    target:clearStencilRect()
    if ask then
        local fy = y + listH
        local s2 = T.surf2
        target:drawRect(x + T.px(1), fy, w - T.px(1), footH, 1, s2.r, s2.g, s2.b)
        target:drawRect(x + T.px(1), fy, w - T.px(1), T.px(1), bs.a, bs.r, bs.g, bs.b)
        local ty = fy + T.px(7)
        for _, l in ipairs(askLines) do
            target:drawText(l, x + T.px(8), ty, tx.r, tx.g, tx.b, tx.a or 1, f1)
            ty = ty + h1 + T.px(2)
        end
        local bh = T.px(22)
        local by = fy + footH - bh - T.px(7)
        local noT, yesT = ZeD.tr("UI_Cancel"), ZeD.tr("ContextMenu_Delete")
        local yw = tm:MeasureStringX(T.fontF3, ZeD.btnCase(yesT)) + T.px(20)
        local nw = tm:MeasureStringX(T.fontF3, ZeD.btnCase(noT)) + T.px(20)
        local yx = x + w - T.px(8) - yw
        local nx = yx - T.px(6) - nw
        local yz = { id = "map:side:yes", x = yx + ox, y = by + oy, w = yw, h = bh,
            activate = function(w2) local a = w2._mapSideAsk; w2._mapSideAsk = nil; if a and a.onYes then a.onYes(w2) end end }
        local nz = { id = "map:side:no", x = nx + ox, y = by + oy, w = nw, h = bh, activate = function(w2) w2._mapSideAsk = nil end }
        ZeD.Molecules.drawButton(target, nx, by, nw, bh, noT, "default", false, focId == nz.id and { fill = ZeD.colorAlpha(T.accent, 0.55) } or nil)
        ZeD.Molecules.drawButton(target, yx, by, yw, bh, yesT, "danger", false, focId == yz.id and { fill = ZeD.colorAlpha(T.accent, 0.55) } or nil)
        table.insert(win._mapExtZones, 1, yz)
        table.insert(win._mapExtZones, 1, nz)
    end
end

-- ---------------------------------------------------------------------------
-- OVER THE MAP: the extensions' drawing, their panels (the key), the side list
-- in the drawer, the area name, the hover hint. From ZeD_WorldMap:render.
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
    local T, tm = ZeD.T, ZeD.TM
    local ox, oy = mp:getX(), mp:getY()
    -- the area name over the top of the map
    for _, d in ipairs(E.list) do
        local text = call(d, "banner", win)
        if text and text ~= "" then
            local f = T.fontF3
            local tw = tm:MeasureStringX(f, text)
            local bw, bh = tw + T.px(24), tm:getFontHeight(f) + T.px(6)
            local bx, by = math.floor((mp:getWidth() - bw) / 2), T.px(8)
            local s1, bs, th = T.surf1, T.borderS, T.textHead
            mp:drawRect(bx, by, bw, bh, 0.85, s1.r, s1.g, s1.b)
            mp:drawRectBorder(bx, by, bw, bh, bs.a, bs.r, bs.g, bs.b)
            mp:drawText(text, bx + T.px(12), by + T.px(3), th.r, th.g, th.b, th.a or 1, f)
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
        E.drawSide(mp, win, mp:getWidth() - w, 0, w, mp:getHeight(), ox, oy, focId)
    end
    -- the hover hint (a toolbar button's words, under it)
    local c = win._mapExtHint
    win._mapExtHint = nil
    if not c then win._mapExtHintKey = nil; return end
    local now = getTimestampMs()
    if win._mapExtHintKey ~= c.key then win._mapExtHintKey, win._mapExtHintSince = c.key, now; return end
    if now - (win._mapExtHintSince or now) < ZeD.Atoms.HINT_MS then return end
    local f2 = T.fontF2
    local padX, padY = T.px(10), T.px(4)
    local w = tm:MeasureStringX(f2, c.text) + padX * 2
    local h = tm:getFontHeight(f2) + padY * 2
    local x = math.max(T.px(2), math.min(c.x - ox, mp:getWidth() - w - T.px(2)))
    local y = c.y + c.h - oy + T.px(4)
    if y < T.px(2) then y = T.px(2) end
    local s2, bs, tc = T.surf2, T.borderS, T.text
    mp:drawRect(x + T.px(2), y + T.px(2), w, h, 0.5, 0, 0, 0)
    mp:drawRect(x, y, w, h, 1, s2.r, s2.g, s2.b)
    mp:drawRectBorder(x, y, w, h, bs.a, bs.r, bs.g, bs.b)
    mp:drawText(c.text, x + padX, y + padY, tc.r, tc.g, tc.b, tc.a or 1, f2)
end

-- ---------------------------------------------------------------------------
-- INPUT
-- ---------------------------------------------------------------------------

-- A click in the tab (tab coordinates). True when an extension's control took it.
function E.onClick(win, x, y)
    for _, z in ipairs(win._mapExtZones or {}) do
        if inRect(z, x, y) then
            if z.slider then
                setSlider(z, x)
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

-- a slider being dragged, or a press an extension took on the map
function E.mouseMove(mp, win)
    local z = win._mapExtDrag
    if z then
        if not isMouseButtonDown(0) then win._mapExtDrag = nil; return true end
        setSlider(z, mp:getMouseX() + mp:getX())
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
