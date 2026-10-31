-- ZeD-UI/42/media/lua/client/ZeD/FurnitureTab.lua
-- ============================================================================
-- FURNITURE TAB — World window (HOOK_MAP row 15; mockup zed_furniture_v1.html)
-- Vanilla moves furniture with a world cursor (ISMoveableCursor) in five modes
-- (pickup, place, rotate, scrap, repair), switched from the left-edge button's
-- pop-up (hidden by ZeD) or the controller's radial, and explains the tile
-- under the cursor in a floating ISMoveableInfoWindow. This tab is the home
-- of that mode:
--   * opening the tab starts the cursor; leaving it ends the cursor; a cursor
--     started any other way (Install furniture, the controller wheel, a drag
--     out of the inventory) opens the tab;
--   * a strip of the five modes (vanilla's words);
--   * TARGET: what the cursor reads, captured from vanilla's own info lines
--     (ISMoveableSpriteProps:getInfoPanelDescription through setInfoPanel),
--     shown as a preview, a status line, facts with dots and NEEDS lines;
--   * ON THIS TILE / YOUR FURNITURE lists in place of the cycle key, FACING
--     buttons, MAY YIELD from vanilla's scrap table;
--   * a chip at the cursor tile with the name and the mode or first blocker;
--     the vanilla info window stops drawing while the tab is up.
-- Every layout number is a DESIGN UNIT (T.px at use).
-- ============================================================================

require "ZeD/Tokens"
require "ZeD/Tr"
require "ZeD/Atoms"
require "ZeD/Molecules"
require "ZeD/ObjectCards"

ZeD = ZeD or {}
ZeD.FurnitureTab = ZeD.FurnitureTab or {}
local FT = ZeD.FurnitureTab

FT.cap = FT.cap or {}          -- per player: what the cursor read last
FT.state = FT.state or { mode = "pickup" }
local DOT = "|"   -- the separator: ZeD OS's pipe (director, Oct 16 2026: no middle dots)

local MODES = {
    -- ready / no are keys, translated where they are drawn
    { id = "pickup", key = "IGUI_Pickup", fb = "Pick up",     ready = "UI_ZeD_Furn_PickupReady", no = "UI_ZeD_Furn_PickupNo" },
    { id = "place",  key = "IGUI_Place",  fb = "Place",       ready = "UI_ZeD_Furn_PlaceReady",  no = "UI_ZeD_Furn_PlaceNo" },
    { id = "rotate", key = "IGUI_Rotate", fb = "Rotate",      ready = "UI_ZeD_Furn_RotateReady", no = "UI_ZeD_Furn_RotateNo" },
    { id = "scrap",  key = "IGUI_Scrap",  fb = "Disassemble", ready = "UI_ZeD_Furn_ScrapReady",  no = "UI_ZeD_Furn_ScrapNo" },
    { id = "repair", key = "IGUI_Repair", fb = "Repair",      ready = "UI_ZeD_Furn_RepairReady", no = "UI_ZeD_Furn_RepairNo" },
}
local MODE_BY_ID = {}
for _, m in ipairs(MODES) do MODE_BY_ID[m.id] = m end

local PAD = 10
local TAB_TOP_PAD = 13   -- the sub-tab strip's top pad, as Animals' (header = pad + T.tabH = 37u; Oct 30 2026)
local PREV_W, PREV_H = 84, 104
local ROW_H, FACT_H, SEC_H = 28, 18, 20
local SCROLL_STEP = 40
-- facing: vanilla's face index (1 N, 2 W, 3 S, 4 E)
local FACES = { { "N", 1 }, { "E", 4 }, { "S", 3 }, { "W", 2 } }

local function txt(k, fb) local s = getTextOrNull and getTextOrNull(k) return s or fb or k end
local function call(o, m, ...) return ZeD.ObjectCards.call(o, m, ...) end
local function col(c) return c.r, c.g, c.b end
local function hit(z, x, y) return z ~= nil and x >= z.x and x < z.x + z.w and y >= z.y and y < z.y + z.h end

local function cursorOf(pn)
    local cell = getCell()
    local d = cell and cell:getDrag(pn)
    if d and d.Type == "ISMoveableCursor" then return d end
    return nil
end
FT.cursorOf = cursorOf

-- the mode's name as the game writes it (sentence case in the windows)
local function modeLabel(id)
    local m = MODE_BY_ID[id]
    return ZeD.textCase(m and txt(m.key, m.fb) or tostring(id))
end

-- ---------------------------------------------------------------------------
-- Capture: vanilla builds its info box every frame through setInfoPanel; keep
-- a copy of what it says (colours are 0..1 after setBodyText).
-- ---------------------------------------------------------------------------
function FT.capture(cur, sq, obj, mp, tex, panel)
    local c = { sq = sq, obj = obj, mode = ISMoveableCursor.mode[cur.player], canCreate = cur.canCreate == true }
    if mp then
        c.mp = mp
        c.tex = tex or mp.spriteName
        local lines = {}
        local tbl = panel and panel.bodyText and panel.bodyText.table
        if tbl then
            for _, ln in ipairs(tbl) do
                local a, b = ln[1], ln[2]
                lines[#lines + 1] = {
                    a = a and { txt = tostring(a.txt or ""), r = a.r or 1, g = a.g or 1, b = a.b or 1 } or nil,
                    b = b and { txt = tostring(b.txt or ""), r = b.r or 1, g = b.g or 1, b = b.b or 1 } or nil,
                }
            end
        end
        c.lines = lines
    end
    FT.cap[cur.player] = c
end

-- ok / bad / plain from vanilla's line colours (good and bad highlight colours)
local function colorState(c)
    if not c then return "plain" end
    if c.g > c.r + 0.15 and c.g > 0.45 then return "ok" end
    if c.r > c.g + 0.15 and c.r > 0.45 then return "bad" end
    return "plain"
end

-- Turn vanilla's lines into name, facts and notes.
local function readLines(c)
    local out = { facts = {}, notes = {} }
    local nameLabel = txt("IGUI_Name", "Name")
    for _, ln in ipairs(c.lines or {}) do
        -- vanilla's debug-only lines (magenta, grey DEBUG block) stay out
        local dbg = ln.a and ((ln.a.r > 0.9 and ln.a.g < 0.1 and ln.a.b > 0.9) or ln.a.txt == "DEBUG" or ln.a.txt == "END DEBUG")
        if dbg then
            -- skip
        elseif ln.a and ln.b then
            local label = string.gsub(string.gsub(ln.a.txt, "%s+$", ""), ":$", "")
            if label == nameLabel then
                out.name = ln.b.txt
            else
                local st = colorState(ln.b)
                local prev = out.facts[#out.facts]
                if label == "" and prev then
                    -- a continuation line: one more acceptable tool, folded into the row
                    prev.more = (prev.more or 0) + 1
                    if st == "ok" then prev.state = "ok" end
                    if st == "ok" and prev.firstState ~= "ok" then prev.value, prev.firstState = ln.b.txt, "ok" end
                else
                    out.facts[#out.facts + 1] = { label = label, value = ln.b.txt, state = st, firstState = st }
                end
            end
        elseif ln.a and ln.a.txt ~= "" then
            local t = string.gsub(ln.a.txt, "^%-%s*", "")
            out.notes[#out.notes + 1] = { text = t, state = colorState(ln.a) }
        end
    end
    if not out.name and c.mp then
        local ok, n = pcall(function() return Translator.getMoveableDisplayName(c.mp.name) end)
        out.name = (ok and n) or c.mp.name or "?"
    end
    return out
end
FT.readLines = readLines

local function iconOfSprite(name)
    local t = name and getTexture(name)
    if not t then return nil end
    return call(t, "splitIcon") or t
end

local function displayName(mp)
    if not mp then return "?" end
    local ok, n = pcall(function() return Translator.getMoveableDisplayName(mp.name) end)
    return (ok and n) or mp.name or "?"
end

-- ---------------------------------------------------------------------------
-- Cursor lifecycle
-- ---------------------------------------------------------------------------
local function st(win)
    local s = win._fur
    if not s then
        s = { zones = {}, byId = {}, scrollY = 0, maxScroll = 0 }
        win._fur = s
    end
    return s
end

function FT.startCursor(pn, mode)
    local player = getSpecificPlayer(pn)
    if not player then return nil end
    local cur = cursorOf(pn)
    if not cur then
        cur = ISMoveableCursor:new(player)
        getCell():setDrag(cur, pn)
    end
    cur:setMoveableMode(mode or FT.state.mode or "pickup")
    return cur
end

function FT.setMode(pn, mode)
    FT.state.mode = mode
    FT.pick = nil
    local cur = cursorOf(pn) or FT.startCursor(pn, mode)
    if cur then cur:setMoveableMode(mode) end
end

-- the tab is up while the furniture cursor exists
function FT.active(pn)
    return FT.state.active == true and (pn == nil or pn == 0)
end

-- ---------------------------------------------------------------------------
-- Hold: the tab sits across the screen from the tile. Vanilla's cursor follows
-- the mouse, so on the way to the tab it would read the tiles under the window
-- and drop the target, and with it anything picked on the tab. While the mouse
-- is over a ZeD window the cursor keeps the tile it last rested on (a quarter
-- second; tiles crossed on the way do not count). A pick made on the tab (the
-- object on the tile, a facing) sticks to that tile: going back to click it
-- finds the pick still set, until you rest on another tile or change mode.
-- Mouse only; a controller's cursor does not follow the mouse.
-- ---------------------------------------------------------------------------
local REST_MS = 250

local function overWindow(w)
    if not (w and w:getIsVisible()) then return false end
    local mx, my = getMouseX(), getMouseY()
    local ax, ay = w:getAbsoluteX(), w:getAbsoluteY()
    return mx >= ax and my >= ay and mx < ax + w:getWidth() and my < ay + w:getHeight()
end

local function mouseOverZeD()
    if ZeD_WorldWindow and ZeD_WorldWindow.getWindow and overWindow(ZeD_WorldWindow.getWindow()) then return true end
    if ZeD_CharacterWindow and ZeD_CharacterWindow.getWindow and overWindow(ZeD_CharacterWindow.getWindow()) then return true end
    return false
end

-- The square the cursor works on this frame; sq is what vanilla passes (the
-- tile under the mouse, or nil over vanilla UI).
function FT.heldSquare(cur, sq)
    local H = cur._zedHold
    if not H then H = {}; cur._zedHold = H end
    if not (cur.player == 0 and FT.active(0) and wasMouseActiveMoreRecentlyThanJoypad()) then
        H.on = nil
        return sq
    end
    if mouseOverZeD() then
        if not H.on then H.on, H.sq = true, H.rest or cur.currentSquare end
        return H.sq or sq
    end
    H.on = nil
    local now = getTimestampMs()
    if sq ~= H.cur then H.cur, H.since = sq, now end
    if sq and now - (H.since or now) >= REST_MS and H.rest ~= sq then
        H.rest = sq
        if FT.pick and FT.pick.sq ~= sq then FT.pick = nil end
    end
    return sq
end

-- the tile the tab is reading now (held or under the cursor)
local function targetSquare(cur)
    local H = cur and cur._zedHold
    if H and H.on and H.sq then return H.sq end
    return cur and cur.currentSquare
end

-- remember a pick made on the tab for the tile it was made on
local function pickOn(cur, idx)
    local sq = targetSquare(cur)
    FT.pick = sq and { sq = sq, mode = ISMoveableCursor.mode[cur.player], idx = idx } or nil
end

-- Before vanilla's isValid: coming back onto the picked tile, keep the pick
-- through vanilla's reset of the object index on a new square.
function FT.restorePick(cur, sq)
    local p = FT.pick
    if p and sq and p.sq == sq and cur.currentSquare ~= sq and p.mode == ISMoveableCursor.mode[cur.player] then
        cur.currentSquare = sq
        cur.objectListCache = nil
        cur.objectIndex = p.idx
    end
end

-- Leave the tab for the Loot view (the cursor went away some other way).
local function leaveTab(pn)
    if ZeD_WorldWindow and ZeD_WorldWindow.openTab then ZeD_WorldWindow.openTab(pn, "loot") end
end

-- Per tick: end the cursor when the tab goes, show the tab when a cursor
-- appears another way.
local function watch()
    -- ISMoveableCursor lives in server/ Lua, which loads with the save: hook it
    -- once it exists
    if ISMoveableCursor and not ISMoveableCursor._zedFurnitureHooked then FT.install() end
    if not (ZeD_WorldWindow and ZeD_WorldWindow.isTabShowing) then return end
    local pn = 0
    local cur = cursorOf(pn)
    local showing = ZeD_WorldWindow.isOpen() and ZeD_WorldWindow.isTabShowing("furniture")
    local S = FT.state
    if showing then return end
    if S.active then
        S.active = false
        S.hadCursor = false
        if cur then pcall(function() cur:exitCursor() end) end
        return
    end
    if cur then
        local nowMs = getTimestampMs and getTimestampMs() or 0
        if (S.openingMs or 0) + 1500 < nowMs then
            S.openingMs = nowMs
            S.mode = ISMoveableCursor.mode[pn] or S.mode
            pcall(ZeD_WorldWindow.openTab, pn, "furniture")
        end
    end
end

-- ---------------------------------------------------------------------------
-- Drawing helpers (on the drawer panel)
-- ---------------------------------------------------------------------------
local function stamp(s, id, x, y, w, h, fn, opts)
    local z = { id = id, x = x, y = y, w = w, h = h, fn = fn }
    if opts then for k, v in pairs(opts) do z[k] = v end end
    s.zones[#s.zones + 1] = z
    s.byId[id] = z
    return z
end

-- the focused element's id while the mark may show (the window has the controller
-- and the pad is in use)
local function gpFocusedId(win)
    local Focus = ZeD.Input and ZeD.Input.Focus
    if not (Focus and Focus.isFocused and Focus.isFocused(win, "worldTabContent")) then return nil end
    local el = Focus.liveElement(win)
    local id = el and el.id
    if id and id:sub(1, 4) == "fur:" then return id end
    return nil
end

local function dashed(panel, x, y, w, h, c)
    local T = ZeD.T
    local seg, one = T.px(4), T.px(1)
    local sx = x
    while sx < x + w do
        local l = math.min(seg, x + w - sx)
        panel:drawRect(sx, y, l, one, c.a or 1, col(c)); panel:drawRect(sx, y + h - one, l, one, c.a or 1, col(c))
        sx = sx + seg * 2
    end
    local sy = y
    while sy < y + h do
        local l = math.min(seg, y + h - sy)
        panel:drawRect(x, sy, one, l, c.a or 1, col(c)); panel:drawRect(x + w - one, sy, one, l, c.a or 1, col(c))
        sy = sy + seg * 2
    end
end

local function dotFor(state)
    local T = ZeD.T
    if state == "ok" then return T.positive end
    if state == "bad" then return T.danger end
    return nil
end

-- ---------------------------------------------------------------------------
-- Content blocks; each returns its height. `vis(y, h)` says whether a block at
-- y (unscrolled body coordinate) is inside the body view; rows outside are
-- skipped (the drawer already holds the one stencil, which cannot nest).
-- ---------------------------------------------------------------------------
local function drawTarget(panel, s, x, y, w, c, mode, info)
    local T, tm = ZeD.T, ZeD.TM
    local pw, ph = T.px(PREV_W), T.px(PREV_H)
    local ok = c and c.mp and c.canCreate
    -- preview
    if c and c.mp then
        local s1 = T.surf1
        panel:drawRect(x, y, pw, ph, 1, col(s1))
        local tex = c.tex and getTexture(c.tex)
        if tex then panel:drawTextureScaledAspect(tex, x + T.px(4), y + T.px(4), pw - 2 * T.px(4), ph - 2 * T.px(4), 1, 1, 1, 1) end
        -- (whether it can be done is the status square under the name, not the frame)
        panel:drawRectBorder(x, y, pw, ph, T.borderS.a or 1, col(T.borderS))
    else
        dashed(panel, x, y, pw, ph, T.border)
    end
    -- name, status, facts
    local tx = x + pw + T.px(10)
    local tw = w - pw - T.px(10)
    local f1, f2, f3, f4 = T.fontF1, T.fontF2, T.fontF3, T.fontF4
    local cy = y
    local m = MODE_BY_ID[mode] or MODES[1]
    if not (c and c.mp) then
        -- vanilla repairs only what has health: things built or crafted (doors, walls, fences, stations)
        local msg = (mode == "place") and ZeD.tr("UI_ZeD_Furn_NothingToPlace")
            or (mode == "repair") and ZeD.tr("UI_ZeD_Furn_PointBuilt")
            or ZeD.tr("UI_ZeD_Furn_PointFurniture")
        ZeD.Molecules.drawEmptyLine(panel, tx, cy, tw, msg)
        return ph
    end
    local name = ZeD.CraftingCore.truncText(info.name or "?", f4, tw)
    panel:drawText(name, tx, cy, T.text.r, T.text.g, T.text.b, T.text.a or 1, f4)
    cy = cy + tm:getFontHeight(f4) + T.px(2)
    local sc = ok and T.positive or T.danger
    ZeD.Atoms.drawStatusDot(panel, tx, cy + math.floor((tm:getFontHeight(f2) - T.px(6)) / 2), sc, T.px(6))
    panel:drawText(ZeD.tr(ok and m.ready or m.no), tx + T.px(12), cy, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    cy = cy + tm:getFontHeight(f2) + T.px(6)
    -- facts: label  value (with a square for ok / bad); labels as the game writes them
    local lw = 0
    for _, f in ipairs(info.facts) do lw = math.max(lw, tm:MeasureStringX(f1, f.label)) end
    lw = math.min(lw, math.floor(tw * 0.5))
    local lc = T.textDim
    for _, f in ipairs(info.facts) do
        local fh = T.px(FACT_H)
        panel:drawText(ZeD.CraftingCore.truncText(f.label, f1, lw), tx, cy + math.floor((fh - tm:getFontHeight(f1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, f1)
        local vx = tx + lw + T.px(10)
        local dc = dotFor(f.state)
        if dc then
            ZeD.Atoms.drawStatusDot(panel, vx, cy + math.floor((fh - T.px(6)) / 2), dc, T.px(6))
            vx = vx + T.px(11)
        end
        local value = f.value
        if f.more and f.more > 0 then
            -- "Claw Hammer  + 3 more" (any one of them will do, as in vanilla)
            local tail = "  " .. ZeD.tr("UI_ZeD_Furn_More", f.more)
            local tailW = tm:MeasureStringX(f3, tail)
            value = ZeD.CraftingCore.truncText(value, f3, tx + tw - vx - tailW)
            panel:drawText(value, vx, cy + math.floor((fh - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f3)
            panel:drawText(tail, vx + tm:MeasureStringX(f3, value), cy + math.floor((fh - tm:getFontHeight(f3)) / 2),
                T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f3)
        else
            panel:drawText(ZeD.CraftingCore.truncText(value, f3, tx + tw - vx), vx, cy + math.floor((fh - tm:getFontHeight(f3)) / 2),
                T.text.r, T.text.g, T.text.b, T.text.a or 1, f3)
        end
        cy = cy + fh
    end
    return math.max(ph, cy - y)
end

local function drawNotes(panel, x, y, w, notes)
    local T, tm = ZeD.T, ZeD.TM
    local y0 = y
    local f2 = T.fontF2
    for _, n in ipairs(notes) do
        local dc = dotFor(n.state) or T.textDim
        local lh = tm:getFontHeight(f2) + T.px(4)
        ZeD.Atoms.drawStatusDot(panel, x + T.px(2), y + math.floor((lh - T.px(6)) / 2), dc, T.px(6))
        panel:drawText(ZeD.CraftingCore.truncText(n.text, f2, w - T.px(16)), x + T.px(14), y + math.floor((lh - tm:getFontHeight(f2)) / 2),
            T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
        y = y + lh
    end
    return y - y0
end

-- one list row: icon, name + sub, button (a push button at the list-row height);
-- the row the cursor carries wears the selected wash
local function drawRow(panel, s, x, y, w, id, tex, name, sub, label, primary, fn, enabled)
    local T, tm = ZeD.T, ZeD.TM
    local M = ZeD.Molecules
    local rh = T.px(ROW_H)
    if primary then panel:drawRect(x, y, w, rh, T.selectionA, col(T.accent)) end
    local isz = T.px(16)
    if tex then panel:drawTextureScaledAspect(tex, x + T.px(2), y + math.floor((rh - isz) / 2), isz, isz, 1, 1, 1, 1) end
    local bh = T.buttonH - T.px(4)
    local bw = math.max(T.px(56), M.buttonW(label))
    local bx = x + w - T.px(2) - bw
    local by = y + math.floor((rh - bh) / 2)
    local dis = enabled == false
    M.drawButton(panel, bx, by, bw, bh, label, primary and "primary" or "default", false, nil,
        { disabled = dis, hover = not dis and ZeD.Atoms.mouseIn(panel, bx, by, bw, bh), focus = (s.gpId == id) or nil })
    stamp(s, id, bx, by, bw, bh, fn)
    local f2, f5 = T.fontF2, T.fontF5
    local nx = x + T.px(2) + isz + T.px(8)
    local nmax = bx - T.px(8) - nx
    local ny = y + math.floor((rh - tm:getFontHeight(f2) - (sub and tm:getFontHeight(f5) or 0)) / 2)
    panel:drawText(ZeD.CraftingCore.truncText(name or "?", f2, nmax), nx, ny, T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    if sub then
        panel:drawText(ZeD.CraftingCore.truncText(sub, f5, nmax), nx, ny + tm:getFontHeight(f2), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f5)
    end
    panel:drawRect(x, y + rh - T.px(1), w, T.px(1), T.border.a or 1, col(T.border))
    return rh
end

-- facing: which faces the object has and which one the cursor shows now.
-- Vanilla pads its four face slots (1 N, 2 W, 3 S, 4 E) with the opposite
-- face when one is missing (a pottery wheel has only S and E), so the real
-- faces come from getFaces and the shown one is matched by sprite name.
local function facingInfo(cur, mode)
    local omp = cur and cur.origMoveProps
    if not omp then return nil end
    local faces = call(omp, "hasFaces") == true
    local dir = call(omp, "canRotateDirection") == true
    if not (faces or dir) then return nil end
    local fi = { faces = faces, dir = dir }
    if faces then
        local f = call(omp, "getFaces") or {}
        fi.avail = { N = f.N, E = f.E, S = f.S, W = f.W }
        fi.shown = cur.currentMoveProps and cur.currentMoveProps.spriteName
    elseif dir then
        fi.idx = cur.joypadFacing
    end
    return fi
end

local function setFacing(cur, mode, fi, idx)
    if not cur then return end
    if fi.dir then
        cur.joypadFacing = idx
    elseif mode == "rotate" then
        cur.cursorFacing = nil
        cur.objectIndex = idx
        pickOn(cur, idx)
    else
        cur:setCursorFacing(idx)
    end
    pcall(function() getSoundManager():playUISound("UIObjectMenuObjectRotateOutline") end)
end

-- facing: one of four, so System 7 radio buttons (the compass letter beside each)
local function drawFacing(panel, s, x, y, w, cur, mode, fi)
    local T, tm = ZeD.T, ZeD.TM
    local A = ZeD.Atoms
    local h = T.px(24)
    local f1, f2 = T.fontF1, T.fontF2
    local lc = T.textDim
    local facingTxt = ZeD.textCase(ZeD.tr("UI_ZeD_Furn_Facing"))
    panel:drawText(facingTxt, x, y + math.floor((h - tm:getFontHeight(f1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, f1)
    local bx = x + tm:MeasureStringX(f1, facingTxt) + T.px(12)
    local bw = T.px(42)
    local rs = A.radioSize()
    local ih = h - T.px(2)
    for _, fc in ipairs(FACES) do
        local id = "fur:face:" .. fc[1]
        local idx = fc[2]
        local has, on
        if fi.faces then
            has = fi.avail[fc[1]] ~= nil
            on = has and fi.avail[fc[1]] == fi.shown
        else
            has, on = true, fi.idx == idx
        end
        local iy = y + T.px(1)
        local hov = has and A.mouseIn(panel, bx, iy, bw, ih)
        local onFocus = (s.gpId == id) and ZeD.Focus.mark(panel, bx, iy, bw, ih) or false
        A.drawRadio(panel, bx + T.px(4), iy + math.floor((ih - rs) / 2), on, { hover = hov, disabled = not has })
        local tc = onFocus and T.textOnFocus or T.text
        local ta = (tc.a or 1) * (has and 1 or T.disabledAlpha)
        panel:drawText(fc[1], bx + T.px(4) + rs + T.px(6), iy + math.floor((ih - tm:getFontHeight(f2)) / 2), tc.r, tc.g, tc.b, ta, f2)
        if has then stamp(s, id, bx, iy, bw, ih, function() setFacing(cur, mode, fi, idx) end) end
        bx = bx + bw + T.px(4)
    end
    return h
end

-- What a disassembly may give, from vanilla's scrap table (one row per item)
local function yieldsOf(mp)
    local out = {}
    local defs = ISMoveableDefinitions and ISMoveableDefinitions:getInstance()
    if not (defs and mp) then return out end
    for _, mat in ipairs({ mp.material, mp.material2, mp.material3 }) do
        local def = mat and defs.getScrapDefinition(mat)
        if def then
            for _, r in ipairs(def.returnItems or {}) do out[#out + 1] = { item = r.returnItem, max = r.maxAmount, chance = r.chancePerRoll } end
            for _, r in ipairs(def.returnItemsStatic or {}) do out[#out + 1] = { item = r.returnItem, max = r.maxAmount, static = true } end
        end
    end
    return out
end

local function drawYield(panel, x, y, w, r)
    local T, tm = ZeD.T, ZeD.TM
    local rh = T.px(24)
    local si = getScriptManager():FindItem(r.item)
    local tex = si and call(si, "getNormalTexture")
    local isz = T.px(16)
    if tex then panel:drawTextureScaledAspect(tex, x + T.px(2), y + math.floor((rh - isz) / 2), isz, isz, 1, 1, 1, 1) end
    local f2, f3 = T.fontF2, T.fontF3
    local name = (si and si:getDisplayName()) or tostring(r.item)
    panel:drawText(ZeD.CraftingCore.truncText(name, f2, w - T.px(170)), x + T.px(2) + isz + T.px(8), y + math.floor((rh - tm:getFontHeight(f2)) / 2),
        T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    local ty = y + math.floor((rh - tm:getFontHeight(f3)) / 2)
    ZeD.Atoms.drawTextRight(panel, r.static and ZeD.textCase(ZeD.tr("UI_ZeD_Furn_Always")) or (tostring(r.chance or 0) .. "%"), x + w - T.px(2), ty, f3, T.textDim)
    ZeD.Atoms.drawTextRight(panel, tostring(r.max or 0), x + w - T.px(80), ty, f3, T.text)
    panel:drawRect(x, y + rh - T.px(1), w, T.px(1), T.border.a or 1, col(T.border))
    return rh
end

-- ---------------------------------------------------------------------------
-- The mode strip (the header): the five modes as sub-tabs. Where they do not fit
-- the card (1280x720, UI scale 2.0, Large text; Oct 31 2026, break-it E7) the tabs
-- close up their side room, then take the small words (F5); if even that is too
-- wide the strip scrolls by whole tabs between a scrollbar's left and right arrows
-- (live while there is more that way). A tab out of view has no zone; the
-- controller's newly focused tab, else the newly active one, is brought into view,
-- and an arrow pressed to its end hands the focus to the tab it revealed.
-- ---------------------------------------------------------------------------
local _modeTws, _modeTabOpts = {}, {}
local function modeStripFit(s, idx, nM)
    -- the first tab such that tabs first..idx fit (idx kept in view)
    local first = s.stripFirst or 1
    if idx < first then first = idx end
    local T = ZeD.T
    while first < idx do
        local used = 0
        for i = first, idx do used = used + _modeTws[i] + (i > first and T.sp.tabGap or 0) end
        if used <= s.stripView then break end
        first = first + 1
    end
    return first
end

local function arrowFn(s, win, dir)
    local key = (dir < 0) and "_stripLeftFn" or "_stripRightFn"
    local fn = s[key]
    if fn then return fn end
    fn = function()
        local id = (dir < 0) and "fur:strip:left" or "fur:strip:right"
        local wasFocused = (s.gpId == id)
        local f = (s.stripFirst or 1) + dir
        f = math.max(1, math.min(s.stripMaxFirst or 1, f))
        s.stripFirst = f
        local edge = (dir < 0 and f <= 1) or (dir > 0 and f >= (s.stripMaxFirst or 1))
        local Focus = ZeD.Input and ZeD.Input.Focus
        if wasFocused and edge and Focus and Focus.focusByIdSoon then
            local m = (dir < 0) and MODES[1] or MODES[#MODES]
            Focus.focusByIdSoon(win, "worldTabContent", "fur:mode:" .. m.id)
        end
    end
    s[key] = fn
    return fn
end

local function drawModeStrip(panel, win, s, x, tabY, w, mode, pn)
    local T, tm = ZeD.T, ZeD.TM
    local M, A = ZeD.Molecules, ZeD.Atoms
    local tH, gap, nM = T.tabH, T.sp.tabGap, #MODES
    local avail = w - T.sp.sm * 2
    local font, padX = T.fontF2, T.sp.tabPadX
    local textSum = 0
    for i = 1, nM do
        _modeTws[i] = tm:MeasureStringX(font, A.textCase(txt(MODES[i].key, MODES[i].fb)))
        textSum = textSum + _modeTws[i]
    end
    local fixed = gap * (nM - 1)
    if textSum + padX * 2 * nM + fixed > avail then
        padX = math.max(T.px(4), math.floor((avail - textSum - fixed) / (2 * nM)))
        if textSum + padX * 2 * nM + fixed > avail then
            font, textSum = T.fontF5, 0
            for i = 1, nM do
                _modeTws[i] = tm:MeasureStringX(font, A.textCase(txt(MODES[i].key, MODES[i].fb)))
                textSum = textSum + _modeTws[i]
            end
            padX = math.max(T.px(4), math.floor((avail - textSum - fixed) / (2 * nM)))
        end
    end
    for i = 1, nM do _modeTws[i] = _modeTws[i] + padX * 2 end
    local scrolls = textSum + padX * 2 * nM + fixed > avail
    local tabL = x + T.sp.sm
    local aw = tH
    local activeIdx, focusIdx
    for i = 1, nM do
        if MODES[i].id == mode then activeIdx = i end
        if s.gpId == "fur:mode:" .. MODES[i].id then focusIdx = i end
    end
    local first, last = 1, nM
    if scrolls then
        tabL = x + T.sp.sm + aw + gap
        s.stripView = avail - (aw + gap) * 2
        -- the last first tab that still fills the view to the end
        local maxFirst, used = nM, _modeTws[nM]
        while maxFirst > 1 and used + gap + _modeTws[maxFirst - 1] <= s.stripView do
            maxFirst = maxFirst - 1
            used = used + gap + _modeTws[maxFirst]
        end
        s.stripMaxFirst = maxFirst
        if focusIdx and s.stripFocusSeen ~= focusIdx then s.stripFirst = modeStripFit(s, focusIdx, nM)
        elseif activeIdx and s.stripModeSeen ~= mode then s.stripFirst = modeStripFit(s, activeIdx, nM) end
        first = math.max(1, math.min(maxFirst, s.stripFirst or 1))
        s.stripFirst = first
        last, used = first, _modeTws[first]
        while last < nM and used + gap + _modeTws[last + 1] <= s.stripView do
            last = last + 1
            used = used + gap + _modeTws[last]
        end
    else
        s.stripFirst, s.stripMaxFirst = 1, 1
    end
    s.stripFocusSeen, s.stripModeSeen = focusIdx, mode

    local o = _modeTabOpts
    o.font, o.padX = font, padX
    local tabX = tabL
    local activeX, activeW
    for i = first, last do
        local m = MODES[i]
        local id = "fur:mode:" .. m.id
        local mid = m.id
        local tw = _modeTws[i]
        local on = (mode == mid)
        o.focus = (s.gpId == id) or nil
        M.drawTab(panel, tabX, tabY, txt(m.key, m.fb), on, A.mouseIn(panel, tabX, tabY, tw, tH), false, o)
        stamp(s, id, tabX, tabY, tw, tH, function() FT.setMode(pn, mid) end)
        if on then activeX, activeW = tabX, tw end
        tabX = tabX + tw + gap
    end
    local ly = tabY + tH - T.hair
    if activeX then
        A.drawDividerH(panel, x, ly, activeX - x, true)
        A.drawDividerH(panel, activeX + activeW, ly, x + w - (activeX + activeW), true)
    else
        A.drawDividerH(panel, x, ly, w, true)
    end
    if not scrolls then return end
    for k = 1, 2 do
        local dir = (k == 1) and -1 or 1
        local can = (k == 1 and first > 1) or (k == 2 and first < s.stripMaxFirst)
        local axk = (k == 1) and (x + T.sp.sm) or (x + w - T.sp.sm - aw)
        if can then
            local id = (k == 1) and "fur:strip:left" or "fur:strip:right"
            local hov = A.mouseIn(panel, axk, tabY, aw, tH)
            A.drawScrollArrow(panel, axk, tabY, aw, (k == 1) and "left" or "right", hov and "hover" or "default")
            if s.gpId == id and ZeD.Focus and ZeD.Focus.mark then ZeD.Focus.mark(panel, axk, tabY, aw, tH) end
            stamp(s, id, axk, tabY, aw, tH, arrowFn(s, win, dir))
        else
            local bs = T.borderS
            panel:drawRectBorder(axk, tabY, aw, tH, (bs.a or 1) * T.disabledAlpha, bs.r, bs.g, bs.b)
        end
    end
end

-- ---------------------------------------------------------------------------
-- RENDER
-- ---------------------------------------------------------------------------
function FT.render(panel, win, x, y, w, h)
    local T, tm = ZeD.T, ZeD.TM
    if not T then return end
    local s = st(win)
    s.zones, s.byId = {}, {}
    s.gpId = gpFocusedId(win)
    local pn = 0
    local S = FT.state
    local cur = cursorOf(pn)
    if not S.active then
        S.active = true
        S.hadCursor = false
        if not cur then cur = FT.startCursor(pn, S.mode) end
    end
    if cur then
        S.hadCursor = true
        S.mode = ISMoveableCursor.mode[pn] or S.mode
    elseif S.hadCursor then
        -- the cursor went (right click, the run key, interact): leave the tab
        S.hadCursor = false
        leaveTab(pn)
        return
    else
        cur = FT.startCursor(pn, S.mode)
    end
    local mode = S.mode or "pickup"
    local c = FT.cap[pn]
    if c and c.mode ~= mode then c = nil end

    -- header strip (the standard height): the five modes as sub-tabs, drawn as Animals' Ranch | Butcher
    -- (13u top pad + the tab, the strip's line around the active one); no title line, no band
    local M = ZeD.Molecules
    local tabY = y + T.px(TAB_TOP_PAD)
    local sy = tabY + T.tabH
    drawModeStrip(panel, win, s, x, tabY, w, mode, pn)

    -- body (scrolls as one unit; rows outside the view are skipped)
    local top = sy + T.px(8)
    local bottom = y + h - T.px(6)
    s.bodyTop, s.bodyBottom = top, bottom
    -- the library scrollbar at the drawer's right edge when the body overflowed last frame
    local sbW = ((s.maxScroll or 0) > 0) and T.sp.scrollbarW or 0
    local bx0, bw0 = x + T.px(PAD), w - T.px(PAD) * 2 - sbW
    local off = s.scrollY or 0
    local cy = top - off
    local function vis(yy, hh2) return yy >= top - T.px(2) and yy + hh2 <= bottom + T.px(2) end

    local info = (c and c.mp) and readLines(c) or { facts = {}, notes = {} }
    -- TARGET
    local tH = T.px(PREV_H)
    if c and c.mp then
        local th0 = T.px(PREV_H)
        local facts = #info.facts * T.px(FACT_H) + tm:getFontHeight(T.fontF4) + tm:getFontHeight(T.fontF2) + T.px(8)
        tH = math.max(th0, facts)
    end
    if vis(cy, tH) then drawTarget(panel, s, bx0, cy, bw0, c, mode, info) end
    cy = cy + tH + T.px(8)
    -- notes (vanilla's blockers and remarks)
    if #info.notes > 0 then
        local nh = #info.notes * (tm:getFontHeight(T.fontF2) + T.px(4))
        if vis(cy, nh) then drawNotes(panel, bx0, cy, bw0, info.notes) end
        cy = cy + nh + T.px(6)
    end
    -- FACING (place, rotate)
    if (mode == "place" or mode == "rotate") and cur then
        local fi = facingInfo(cur, mode)
        if fi then
            if vis(cy, T.px(24)) then drawFacing(panel, s, bx0, cy, bw0, cur, mode, fi) end
            cy = cy + T.px(24) + T.px(8)
        end
    end
    -- MAY YIELD (disassemble)
    if mode == "scrap" and c and c.mp then
        local ys = yieldsOf(c.mp)
        if #ys > 0 then
            if vis(cy, T.px(SEC_H)) then
                M.drawSectionHeader(panel, bx0, cy, bw0, ZeD.tr("UI_ZeD_Furn_MayYield"), nil, true, false, nil, false, 0, T.px(SEC_H), true)
                -- the columns' names, right-aligned on the head
                local cols = ZeD.textCase(ZeD.tr("UI_ZeD_Furn_UpTo")) .. " " .. DOT .. " " .. ZeD.textCase(ZeD.tr("UI_ZeD_Furn_RollChance"))
                ZeD.Atoms.drawTextRight(panel, cols, bx0 + bw0 - T.px(2), cy + math.floor((T.px(SEC_H) - tm:getFontHeight(T.fontF1)) / 2), T.fontF1, T.textDim)
            end
            cy = cy + T.px(SEC_H)
            for _, r in ipairs(ys) do
                if vis(cy, T.px(24)) then drawYield(panel, bx0, cy, bw0, r) end
                cy = cy + T.px(24)
            end
            cy = cy + T.px(8)
        end
    end
    -- lists
    if cur then
        if mode == "place" then
            local list = cur.objectListCache
            if not list then local ok, l = pcall(function() return cur:getInventoryObjectList() end); list = ok and l or {} end
            if vis(cy, T.px(SEC_H)) then M.drawSectionHeader(panel, bx0, cy, bw0, ZeD.tr("UI_ZeD_Furn_YourFurniture"), #list, true, false, nil, false, 0, T.px(SEC_H), true) end
            cy = cy + T.px(SEC_H)
            for i, e in ipairs(list) do
                local it = e.object
                local oi = cur.objectIndex or -1
                local selected = (oi == i) or (oi < 1 and i == 1)
                local idx = i
                if vis(cy, T.px(ROW_H)) then
                    drawRow(panel, s, bx0, cy, bw0, "fur:inv:" .. i, it and call(it, "getTex"), it and it:getDisplayName() or "?",
                        (ZeD.ObjectCards.whereOf(it, getSpecificPlayer(pn)) or "") .. " " .. DOT .. " " .. string.format("%.1f", it and it:getActualWeight() or 0),
                        selected and ZeD.tr("UI_ZeD_Furn_OnCursor") or txt("IGUI_Place", "Place"), selected,
                        function() cur.objectIndex = idx; cur.cacheInvObjectSprite = nil; cur.cursorFacing = nil; cur.joypadFacing = nil end)
                end
                cy = cy + T.px(ROW_H)
            end
            if #list == 0 then
                if vis(cy, T.px(26)) then M.drawEmptyLine(panel, bx0 + T.px(2), cy + T.px(8), bw0 - T.px(4), ZeD.tr("UI_ZeD_Furn_CarryNone")) end
                cy = cy + T.px(26)
            end
        elseif mode ~= "rotate" then
            local list = cur.objectListCache
            if type(list) == "table" and #list > 0 then
                if vis(cy, T.px(SEC_H)) then M.drawSectionHeader(panel, bx0, cy, bw0, ZeD.tr("UI_ZeD_Furn_OnThisTile"), #list, true, false, nil, false, 0, T.px(SEC_H), true) end
                cy = cy + T.px(SEC_H)
                for i, e in ipairs(list) do
                    local selected = (cur.objectIndex == i)
                    local idx = i
                    if vis(cy, T.px(ROW_H)) then
                        drawRow(panel, s, bx0, cy, bw0, "fur:obj:" .. i, iconOfSprite(e.moveProps and e.moveProps.spriteName), displayName(e.moveProps),
                            nil, ZeD.tr("UI_ZeD_Furn_Target"), selected, function() cur.objectIndex = idx; pickOn(cur, idx) end)
                    end
                    cy = cy + T.px(ROW_H)
                end
            end
        end
    end
    -- scroll range
    local total = (cy + off) - top
    s.maxScroll = math.max(0, total - (bottom - top))
    if (s.scrollY or 0) > s.maxScroll then s.scrollY = s.maxScroll end
    -- the library scrollbar, its outer edge on the drawer's edge (the wheel and its arrows move it)
    local sb = s.sb
    if not sb then sb = ZeD_ScrollbarState:new(); s.sb = sb end
    sb.visible = s.maxScroll > 0
    if sb.visible then
        sb.width, sb.arrowH = T.sp.scrollbarW, T.sp.scrollbarW
        sb.x, sb.y, sb.height = x + w - sb.width, top, bottom - top
        sb:setBarSize((bottom - top) / math.max(1, total))
        sb.scrollPos = (s.scrollY or 0) / s.maxScroll
        sb:draw(panel)
    end
    s.cur = cur
end

function FT.register(dispatch)
    -- wrapper: a hot reload replaces the renderer, and a fault never takes the
    -- window's frame down (logged once per distinct error)
    dispatch["furniture"] = function(...)
        local ok, err = pcall(ZeD.FurnitureTab.render, ...)
        if not ok and FT._lastErr ~= tostring(err) then
            FT._lastErr = tostring(err)
            ZeD.logOnce("FurnitureTab: render failed", err)
        end
    end
end

function FT.isVisible(win) return true end

-- ---------------------------------------------------------------------------
-- Mouse
-- ---------------------------------------------------------------------------
function FT.onClick(win, x, y)
    local s = st(win)
    -- the scrollbar: its arrows and track step the body (no drag; the wheel scrolls too)
    local sb = s.sb
    if sb and sb.visible and x >= sb.x and x < sb.x + sb.width and y >= sb.y and y < sb.y + sb.height then
        sb:handleMouseDown(y - sb.y)
        sb:handleMouseUp()
        s.scrollY = math.floor(sb.scrollPos * (s.maxScroll or 0) + 0.5)
        return true
    end
    for i = #s.zones, 1, -1 do
        local z = s.zones[i]
        if hit(z, x, y) and z.fn then
            pcall(function() getSoundManager():playUISound("UIActivateButton") end)
            z.fn()
            return true
        end
    end
    return true
end

function FT.onMouseWheel(win, del)
    local s = st(win)
    s.scrollY = math.max(0, math.min(s.maxScroll or 0, (s.scrollY or 0) + ZeD.T.px(SCROLL_STEP) * del))
    return true
end

-- ---------------------------------------------------------------------------
-- Gamepad: this frame's zones; B hands the stick back to the world cursor
-- ---------------------------------------------------------------------------
function FT.buildFocusables(win)
    local s = win and win._fur
    if not s then return {} end
    local els = {}
    for _, z in ipairs(s.zones) do
        local zz = z
        els[#els + 1] = { x = zz.x, y = zz.y, w = zz.w, h = zz.h, id = zz.id,
            onActivate = function() if zz.fn then zz.fn() end end,
            onCancel = function()
                local Focus = ZeD.Input and ZeD.Input.Focus
                if Focus and Focus.releaseFocus then Focus.releaseFocus() end
                return true
            end,
            promptB = ZeD.tr("UI_ZeD_Furn_ToCursor") }
    end
    return els
end

function FT.focusKey(win)
    local s = win and win._fur
    if not s then return "none" end
    local c = FT.cap[0]
    return tostring(FT.state.mode) .. ":" .. tostring(#s.zones) .. ":" .. tostring(math.floor(s.scrollY or 0)) .. ":"
        .. tostring(s.stripFirst or 1) .. ":"   -- (the mode strip scrolled: other tabs in view)
        .. tostring(c and c.sq and (c.sq:getX() .. "," .. c.sq:getY()) or "-")
end

-- ---------------------------------------------------------------------------
-- The chip at the cursor tile
-- ---------------------------------------------------------------------------
ZeD_FurnitureChip = ZeD_FurnitureChip or ISUIElement:derive("ZeD_FurnitureChip")

function ZeD_FurnitureChip:new(pn)
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.playerNum = pn
    o.anchorLeft, o.anchorTop = true, true
    return o
end

function ZeD_FurnitureChip:onMouseDown() return false end
function ZeD_FurnitureChip:onMouseUp() return false end
function ZeD_FurnitureChip:onRightMouseDown() return false end
function ZeD_FurnitureChip:onRightMouseUp() return false end

function ZeD_FurnitureChip:prerender()
    local T, tm = ZeD.T, ZeD.TM
    local pn = self.playerNum
    local c = FT.cap[pn]
    if not (FT.active(pn) and T and c and c.mp and c.sq and cursorOf(pn)) or c.mode ~= FT.state.mode then
        self:setWidth(1); self:setHeight(1); self:setX(-10); self:setY(-10)
        return
    end
    local info = readLines(c)
    local ok = c.canCreate
    local line = modeLabel(c.mode)
    if not ok then
        for _, n in ipairs(info.notes) do if n.state == "bad" then line = n.text; break end end
        if line == modeLabel(c.mode) then
            for _, f in ipairs(info.facts) do if f.state == "bad" then line = f.label .. " " .. f.value; break end end
        end
        if line == modeLabel(c.mode) then
            local m = MODE_BY_ID[c.mode]
            line = m and ZeD.tr(m.no) or line
        end
    end
    self._name, self._line, self._ok = info.name or "?", line, ok
    local f2, f1 = T.fontF2, T.fontF1
    local w = T.px(7) + T.px(6) + T.px(6) + tm:MeasureStringX(f2, self._name) + T.px(8) + tm:MeasureStringX(f1, line) + T.px(7)
    local h = T.px(20)
    local sq = c.sq
    local x = isoToScreenX(pn, sq:getX() + 1, sq:getY(), sq:getZ()) + T.px(6)
    local y = isoToScreenY(pn, sq:getX(), sq:getY(), sq:getZ()) - math.floor(h / 2)
    -- the mouse sits on the tile: flip above when the chip would cover it
    local mx, my = getMouseX(), getMouseY()
    if mx >= x and mx < x + w and my >= y and my < y + h then y = y - h - T.px(16) end
    self:setX(x); self:setY(y); self:setWidth(w + T.hair); self:setHeight(h + T.hair)
end

function ZeD_FurnitureChip:render()
    local T, tm = ZeD.T, ZeD.TM
    if not (self._name and self:getWidth() > 2) then return end
    -- a box that pops up over the game: solid, the 1u frame and System 7's hard shadow
    -- (the shadow sits outside the box: the element is a unit wider and taller than it)
    local w, h = self:getWidth() - T.hair, self:getHeight() - T.hair
    local s1 = T.surf1
    self:drawRect(0, 0, w, h, 1, col(s1))
    self:drawRectBorder(0, 0, w, h, T.borderS.a or 1, col(T.borderS))
    ZeD.Atoms.drawHardShadow(self, 0, 0, w, h)
    local dc = self._ok and T.positive or T.danger
    ZeD.Atoms.drawStatusDot(self, T.px(7), math.floor((h - T.px(6)) / 2), dc, T.px(6))
    local f2, f1 = T.fontF2, T.fontF1
    local nx = T.px(7) + T.px(12)
    self:drawText(self._name, nx, math.floor((h - tm:getFontHeight(f2)) / 2), T.text.r, T.text.g, T.text.b, T.text.a or 1, f2)
    local lc = T.textDim
    self:drawText(self._line, nx + tm:MeasureStringX(f2, self._name) + T.px(8), math.floor((h - tm:getFontHeight(f1)) / 2), lc.r, lc.g, lc.b, lc.a or 1, f1)
end

local function ensureChip()
    if FT.chip then return end
    local chip = ZeD_FurnitureChip:new(0)
    chip:initialise()
    chip:addToUIManager()
    FT.chip = chip
end

-- ---------------------------------------------------------------------------
-- Hooks
-- ---------------------------------------------------------------------------
function FT.install()
    if ISMoveableCursor and not ISMoveableCursor._zedFurnitureHooked then
        ISMoveableCursor._zedFurnitureHooked = true
        local orig = ISMoveableCursor.setInfoPanel
        ISMoveableCursor.setInfoPanel = function(self, sq, obj, mp, tex)
            local panel = orig(self, sq, obj, mp, tex)
            local ok, err = pcall(FT.capture, self, sq, obj, mp, tex, panel)
            if not ok then ZeD.logOnce("FurnitureTab: capture failed", err) end
            return panel
        end
    end
    if ISMoveableCursor and not ISMoveableCursor._zedFurnitureHold then
        ISMoveableCursor._zedFurnitureHold = true
        -- the hold: vanilla calls isValid from beforeWorldRender and from
        -- DoTileBuilding, then render; all three see the held tile
        local origV = ISMoveableCursor.isValid
        ISMoveableCursor.isValid = function(self, sq, ...)
            local ok, held = pcall(ZeD.FurnitureTab.heldSquare, self, sq)
            if ok then sq = held end
            pcall(ZeD.FurnitureTab.restorePick, self, sq)
            return origV(self, sq, ...)
        end
        local origRn = ISMoveableCursor.render
        ISMoveableCursor.render = function(self, x, y, z, sq)
            local H = self._zedHold
            if H and H.on and H.sq then return origRn(self, H.sq:getX(), H.sq:getY(), H.sq:getZ(), H.sq) end
            return origRn(self, x, y, z, sq)
        end
    end
    if ISMoveableInfoWindow and not ISMoveableInfoWindow._zedFurnitureHooked then
        ISMoveableInfoWindow._zedFurnitureHooked = true
        local origR = ISMoveableInfoWindow.render
        ISMoveableInfoWindow.render = function(self)
            if FT.active(self.playerNum) then return end   -- the tab and the chip carry it
            return origR(self)
        end
    end
end

if not FT._ticking then
    FT._ticking = true
    Events.OnTick.Add(function()
        local ok, err = pcall(watch)
        if not ok then ZeD.logOnce("FurnitureTab: watch failed", err) end
        if FT.state.active then pcall(ensureChip) end
    end)
end
if Events and Events.OnGameBoot then Events.OnGameBoot.Add(FT.install) end
if Events and Events.OnGameStart then Events.OnGameStart.Add(FT.install) end
FT.install()

print("[ZeD] FurnitureTab: Furniture tab loaded")
return FT
