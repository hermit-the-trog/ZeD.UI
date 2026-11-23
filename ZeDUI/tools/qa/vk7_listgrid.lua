-- ZeDUI/tools/qa/vk7_listgrid.lua  (Nov 22 2026, QA; tag vk7_lg): the in-game proof of branch listgrid, head
-- 1916f88ab, the director's two inventory notes. Grid view: "In grid mode, can the width of the inventory hug the grid
-- width? That is, shrink to reduce white space." List view: "Name always wins. Weight comes in second place. Category
-- comes in third place. And if there's room, it shows condition." And the headings: the buttons give way before the
-- name does (Lite's words turn to pictures, then the view flip goes, then Filter, then Pick all).
-- Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA vk7_lg". Manifest: vk7.txt.
--
-- How to read the log: the proofs are the lines that start "GRID", "DRAG", "BACK", "LIST" and "NARROW"; each PASSES
-- on listgrid (it may FAIL on main, which has no hug and the old column order: the merge follows). A part that
-- cannot be staged FAILS with "(staging)" in its words (never a SKIP). "NOTE" lines are readings. The "put back"
-- check at the end passes on both. Run it at 4K (UI scale 1.75), 1080p and 1280x800 (the Deck: "deck" below is a
-- screen 1280 px wide or less).
--
-- The scene: one crate (carpentry_01_16) on a free square beside him holding an apple, a box of nails, a pencil and a
-- hammer (four categories, a thing with a condition); a school bag given to him (the Character window's long name
-- for NARROW). What is read, never pixels written in: the list panel's width (content:getWidth(), the inventory side,
-- the residual of the window), the grid's own state (content._gv: cols, cell, gap), the window's hug state
-- (win._gridHug, content._hugN), the window's saved list width (win._baseInvW, design units), the head row's hit zones
-- (hdr:name, hdr:cat, hdr:cond, hdr:wt) and the list's own _showCat / _showCond, and a heading's name as the list
-- draws it in one frame (its own drawText in F4).
--
-- The checks:
--   GRID 1  World window, crate A alone, the list set to its base width (deck: 222 px; else 372 units), then its view
--           button pressed (the heading's view:flip zone, the list's own onMouseDown): the grid is on, the window
--           hugs (win._gridHug, content._hugN == 1) and the list's width is ZeD.InventoryRenderer.hugInvW(base, 1,
--           0) and whole cells: cols * (cell + gap) - gap + 2 insets + the scrollbar's gutter, and hugInvW of it is
--           itself. NOTE Build's figure for the screen (4K 642 px, 1080p 366, Deck 192). Picture vk7_grid_<W>x<H>.
--   GRID 2  The same in the Character window, his inventory alone.
--   DRAG    The World window's right edge dragged (its own resize: ZeD_Window:_startResize("e"), the pointer and the
--           button read through getMouseX / getMouseY / isMouseButtonDown, stood in for over about half a second) to
--           0.7 of a cell past the hugged width (0.3 of a cell under it when the window has no room): after the let
--           go the list is the NEAREST whole width to where the pointer let go (hugInvW(..., true)), whole cells.
--   BACK 1  The view button pressed again (list): the hug is let go and the list is its saved width again
--           (T.px(win._baseInvW), the _baseInvW found before the grid, within 1 px); _baseInvW unchanged by the grid
--           and the drag. BACK 2: the same in the Character window.
--   LIST 1  The World list (list view) at 372 units: Name, Category and Weight in the head row, no Status
--           (_showCat true, _showCond false). Deck: at 372 units too (Build: the usual list). Picture vk7_list_372.
--   LIST 2  Widened in steps (420, 480, 560, 640, 720 units, as far as the window goes): Status comes back at one of
--           them, and at every width read Name and Weight show, Status only with Category, and once shown Status
--           stays at the wider widths. Picture vk7_list_<units> at the first width with Status.
--   LIST 3  The Deck's width: on a deck screen the list at 222 px shows Name and Weight only (no Category, no
--           Status), picture vk7_list_<units>; on any screen the list at its least (200 units) shows Name and
--           Weight, no Status.
--   NARROW  Both windows at their least width (their own minimumWidth), crate A in the World window, the school bag
--           in the Character window, Full and then Lite: each heading draws the container's name whole or its first
--           three letters and the dots, left of every heading button (headLevel said in the words).
--
-- Safety: nothing is moved or used. The pointer and the button are stood in for only while the drag runs (put back
-- at once, and in the put-back). What it puts back (also when a step throws or the time runs out): the stood-in
-- functions (checked), the cursor shown, the resize stopped; the containers' List or Grid choices as found (the raw
-- values in his mod data, ZeD_GridViews); Style as found (the value only); the windows open or shut as found, where
-- and as big as they were, on their tabs, each window's _baseInvW as found; the crate and its things removed, the
-- bag taken back. No option is saved, no file is written but the pictures.
-- Not run in game yet; parse-checked with the game's Kahlua compiler (KCheck).

if not (RT and RT.make) then
    print("ZEDQA vk7_lg ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk7_lg VERDICT FAIL 1")
    print("ZEDQA vk7_lg DONE")
    return
end

local Q = RT.make("vk7_lg")
Q.maxMs = 720000   -- (twelve minutes, then the put-back; a run takes about three)
local S = { p = RT.p, pn = RT.pn, was = { geo = {}, tab = {}, invW = {} }, k = { g = {}, l = {}, nar = {} },
    fakes = {}, gk = { saved = {}, old = {}, keys = {} }, off = {} }
local H = {}
S.Z = ZeD or {}
S.F = S.Z.Input and S.Z.Input.Focus
S.St, S.IR = S.Z.Settings, S.Z.InventoryRenderer
S.AROUND = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
S.HEAD_VIEWS = { all = true, filter = true, flip = true }
S.W, S.Hs = getCore():getScreenWidth(), getCore():getScreenHeight()
S.deck = S.W <= 1280
S.WIDE = { 420, 480, 560, 640, 720 }

-- ===================================================================== words and numbers
function H.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function H.fail(key, why)
    if S.off[key] then return end
    S.off[key] = true
    Q.check(false, tostring(key) .. " (staging): " .. tostring(why) .. " (not proven)")
end
function H.measure(font, text)
    local w = 0
    pcall(function() w = ZeD.TM:MeasureStringX(font, tostring(text or "")) end)
    return w
end
function H.units(px)
    local sc = (ZeD.T and ZeD.T.scale) or 1
    if sc <= 0 then sc = 1 end
    return math.floor((tonumber(px) or 0) / sc + 0.5)
end

-- ===================================================================== the windows (vk5_header.lua)
function H.charOpen()
    local CW = ZeD_CharacterWindow
    return (CW ~= nil and CW.isOpen ~= nil and CW.isOpen(S.pn)) and true or false
end
function H.worldOpen()
    local WW = ZeD_WorldWindow
    return (WW ~= nil and WW.isOpen ~= nil and WW.isOpen(S.pn)) and true or false
end
function H.win(k) if k == "c" then return RT.cw() end; return RT.ww() end
function H.content(k) local w = H.win(k); return w and w._mainContent end
function H.geo(w)
    if not w then return nil end
    return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() }
end
function H.gs(g)
    if not g then return "none" end
    return H.num(g.x) .. "," .. H.num(g.y) .. " " .. H.num(g.w) .. "x" .. H.num(g.h)
end
function H.sameGeo(a, b)
    if a == nil or b == nil then return a == nil and b == nil end
    return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1
end
function H.placeBack(w, g)
    if not (w and g) or H.sameGeo(H.geo(w), g) then return end
    if math.abs(w:getWidth() - g.w) > 1 then
        w.minimumWidth = math.min(w.minimumWidth or g.w, g.w)
        w:setWidth(g.w)
    end
    if math.abs(w:getHeight() - g.h) > 1 then
        w.minimumHeight = math.min(w.minimumHeight or g.h, g.h)
        w:setHeight(g.h)
    end
    if w:getX() ~= g.x then w:setX(g.x) end
    if w:getY() ~= g.y then w:setY(g.y) end
    if w._anchorRightEdge ~= nil then w._anchorRightEdge = g.x + w:getWidth() end
end
function H.rolled(w)
    if not w then return false end
    if S.F and S.F.isRolled then
        local ok, r = pcall(S.F.isRolled, w)
        if ok then return r and true or false end
    end
    return w.windowShaded and true or false
end
function H.clickTab(strip, id)
    for _, z in ipairs((strip and strip._hitZones) or {}) do
        if z.id == "tab:" .. id then return pcall(strip.onMouseDown, strip, z.x + 2, z.y + 2) end
    end
    return false
end
function H.pairOpen()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if not H.charOpen() and not H.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if not H.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if not H.worldOpen() and WW.open then pcall(WW.open, S.pn) end
    for _, w in ipairs({ RT.cw() or false, RT.ww() or false }) do
        if w and H.rolled(w) and S.F and S.F.showWin then pcall(S.F.showWin, w) end
    end
end
function H.windowsBack()
    local CW, WW = ZeD_CharacterWindow, ZeD_WorldWindow
    if not (CW and WW) then return end
    if S.was.char and S.was.world and not H.charOpen() and not H.worldOpen() and CW.toggleBothPaired then
        pcall(CW.toggleBothPaired, S.pn)
    end
    if S.was.char and not H.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world and not H.worldOpen() and WW.open then pcall(WW.open, S.pn) end
    if S.was.char == false and H.charOpen() and H.worldOpen() and CW.toggleBothPaired then pcall(CW.toggleBothPaired, S.pn) end
    if S.was.char == false and H.charOpen() and CW.toggle then pcall(CW.toggle, S.pn) end
    if S.was.world == false and H.worldOpen() and WW.close then pcall(WW.close, S.pn) end
end
function H.closeCols()
    local cw, ww = RT.cw(), RT.ww()
    if cw and #(cw._mcSelected or {}) > 0 and ZeD_CharacterWindow.closeColumns then pcall(ZeD_CharacterWindow.closeColumns, cw) end
    if ww and #(ww._mcSelected or {}) > 0 and ZeD_WorldWindow.closeColumns then pcall(ZeD_WorldWindow.closeColumns, ww) end
end
function H.worldOn(inv)
    local ww = RT.ww()
    if not (ww and inv) then return end
    if ww._activeTab ~= "loot" then RT.worldTab("loot") end
    if #(ww._mcSelected or {}) > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
    local c = ww._containers and ww._containers[ww._activeContainer or 0]
    if c and c.inventory == inv and ww._mainContent and ww._mainContent._inventory == inv then return end
    pcall(ZeD_WorldWindow.selectContainer, inv, 60, S.pn)
end
function H.charOn(inv)
    local cw = RT.cw()
    if not (cw and inv) then return false end
    if cw._activeTab ~= "loot" or cw._drawerOpen == true then H.clickTab(cw._tabStripPanel, "loot") end
    if #(cw._mcSelected or {}) > 0 and ZeD_CharacterWindow.closeColumns then pcall(ZeD_CharacterWindow.closeColumns, cw) end
    local c = cw._mainContent
    if c and c._inventory == inv then return true end
    if not ZeD_CharacterWindow.showBagAlone then return false end
    local ok, r = pcall(ZeD_CharacterWindow.showBagAlone, S.pn, inv)
    return ok and r == true
end
function H.worldShows(inv)
    local ww = RT.ww()
    local c = ww and ww._mainContent
    if not (c and inv and ww._activeTab == "loot" and not H.rolled(ww)) then return false end
    local e = ww._containers and ww._containers[ww._activeContainer or 0]
    return e ~= nil and e.inventory == inv and #(ww._mcSelected or {}) == 0 and c._inventory == inv
        and c._containerInfo ~= nil and #(c._viewToggleRects or {}) > 0
end
function H.charShows(inv)
    local cw = RT.cw()
    local c = cw and cw._mainContent
    return c ~= nil and inv ~= nil and cw._activeTab == "loot" and not H.rolled(cw) and c._inventory == inv
        and c._containerInfo ~= nil and #(c._viewToggleRects or {}) > 0
end
function H.style(n)
    local o = S.St and S.St.lookStyleOption
    if o and n ~= nil and o:getValue() ~= n then o:setValue(n) end
end
function H.lite() return (S.St and S.St.lite and S.St.lite()) and true or false end

-- ===================================================================== a list's width
-- window k's list set to px wide (the window's own width moved by the difference, within its maximum; the Character
-- window keeps its right edge, the World window its left)
function H.setInvW(k, px)
    local w, c = H.win(k), H.content(k)
    if not (w and c) then return false end
    local want = w:getWidth() + (px - c:getWidth())
    local mx = tonumber(w.maximumWidth)
    if mx and mx > 0 and want > mx then want = mx end
    if want < (w.minimumWidth or 0) then w.minimumWidth = want end
    if S.was.invW[k] == nil then S.was.invW[k] = w._baseInvW or false end
    local right = w:getX() + w:getWidth()
    w:setWidth(want)
    if k == "c" then w:setX(right - w:getWidth()) end
    if w._anchorRightEdge ~= nil then w._anchorRightEdge = w:getX() + w:getWidth() end
    return true
end
-- queue: window k's list to px (twice: the windows set their minimum each frame), then a settle
function H.queueInvW(k, pxFn)
    Q.step(1, function() if not S.dead then H.setInvW(k, pxFn()) end end)
    Q.waitMs(350)
    Q.step(1, function() if not S.dead then H.setInvW(k, pxFn()) end end)
    Q.waitMs(500)
end
function H.narrow()
    for _, k in ipairs({ "c", "w" }) do
        local w = H.win(k)
        if w then
            if S.was.invW[k] == nil then S.was.invW[k] = w._baseInvW or false end
            local m = w.minimumWidth or w:getWidth()
            if w:getWidth() > m then
                local right = w:getX() + w:getWidth()
                w:setWidth(m)
                if k == "c" then w:setX(right - w:getWidth()) end
                if w._anchorRightEdge ~= nil then w._anchorRightEdge = w:getX() + w:getWidth() end
            end
        end
    end
end
function H.baseBack()
    for _, k in ipairs({ "c", "w" }) do
        local w = H.win(k)
        local v = S.was.invW[k]
        if w and v ~= nil then w._baseInvW = (v ~= false) and v or nil end
    end
end

-- ===================================================================== the pointer (stood in for)
function H.atPointer(gx, gy, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return gx end
    getMouseY = function() return gy end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, err
end
function H.fake(c, over)
    if not c then return end
    local f = { c = c, over = rawget(c, "isMouseOver"), gx = rawget(c, "getMouseX"), gy = rawget(c, "getMouseY") }
    f.fo = function() return over and true or false end
    f.fx = function() return -100000 end
    f.fy = function() return -100000 end
    c.isMouseOver, c.getMouseX, c.getMouseY = f.fo, f.fx, f.fy
    S.fakes[#S.fakes + 1] = f
end
function H.fakeOff()
    for i = #S.fakes, 1, -1 do
        local f = S.fakes[i]
        if f.c.isMouseOver == f.fo then f.c.isMouseOver = f.over else S.stuck = true end
        if f.c.getMouseX == f.fx then f.c.getMouseX = f.gx else S.stuck = true end
        if f.c.getMouseY == f.fy then f.c.getMouseY = f.gy else S.stuck = true end
    end
    S.fakes = {}
end
function H.rest()
    H.fakeOff()
    H.fake(H.content("c"), false)
    H.fake(H.content("w"), false)
end
function H.cursor(hide)
    if hide then
        pcall(function() Mouse.setXY(4, getCore():getScreenHeight() - 4) end)
        pcall(function() Mouse.setCursorVisible(false) end)
        S.cursorHidden = true
        return
    end
    if S.cursorHidden then
        S.cursorHidden = nil
        pcall(function() Mouse.setCursorVisible(true) end)
    end
end
-- a picture (name: a function or a string, asked when it is taken): the lists at rest, the cursor hidden
function H.shot(name)
    Q.step(1, function()
        if S.dead then return end
        H.rest()
        H.cursor(true)
    end)
    Q.step(3, function()
        if S.dead then return end
        local nm = (type(name) == "function") and name() or name
        local file = "vk7_" .. tostring(nm) .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file) else Q.say("NOTE the picture " .. tostring(nm) .. " was not taken: " .. tostring(e)) end
        H.fakeOff()
    end)
    Q.waitMs(1800)
end
-- the drag's stand-ins: the button held, the pointer at gx, gy (global reads); H.dragOff puts them back
function H.dragOn(gx, gy)
    if S.drag then return end
    local d = { down0 = isMouseButtonDown, mx0 = getMouseX, my0 = getMouseY }
    d.down = function(b) if b == 0 then return true end; return d.down0(b) end
    d.mx = function() return gx end
    d.my = function() return gy end
    isMouseButtonDown, getMouseX, getMouseY = d.down, d.mx, d.my
    S.drag = d
end
-- the button let go (still stood in for, so the windows read the release); then H.dragOff
function H.dragUp()
    local d = S.drag
    if not d then return end
    d.up = function(b) if b == 0 then return false end; return d.down0(b) end
    isMouseButtonDown = d.up
end
function H.dragOff()
    local d = S.drag
    if not d then return end
    S.drag = nil
    if isMouseButtonDown == d.down or isMouseButtonDown == d.up then isMouseButtonDown = d.down0 else S.stuck = true end
    if getMouseX == d.mx then getMouseX = d.mx0 else S.stuck = true end
    if getMouseY == d.my then getMouseY = d.my0 else S.stuck = true end
end

-- ===================================================================== a heading's name, drawn
function H.recOn()
    if S.rec then return end
    local r = { texts = {}, saved = {} }
    for _, k in ipairs({ "c", "w" }) do
        local c = H.content(k)
        if c then
            local base = c.drawText
            local sv = { c = c, raw = rawget(c, "drawText") }
            sv.fn = function(self, text, x, y, cr, cg, cb, ca, font, ...)
                local l = r.texts[self] or {}
                r.texts[self] = l
                l[#l + 1] = { text = tostring(text), x = x, y = y, font = font }
                return base(self, text, x, y, cr, cg, cb, ca, font, ...)
            end
            c.drawText = sv.fn
            r.saved[#r.saved + 1] = sv
        end
    end
    S.rec = r
end
function H.recOff()
    local r = S.rec
    if not r then return nil end
    S.rec = nil
    for _, sv in ipairs(r.saved) do
        if sv.c.drawText == sv.fn then sv.c.drawText = sv.raw else S.stuck = true end
    end
    return r
end
function H.namePart(text, name)
    if not (text and name) or name == "" then return false end
    if text == name then return true end
    local n = math.min(#text, #name, 3)
    return n >= 2 and text:sub(1, n) == name:sub(1, n)
end
function H.nameDrawn(k, r)
    local c = H.content(k)
    if not (c and r) then return false, "no list" end
    local ci = c._containerInfo
    if not ci then return false, "the list has no heading (_containerInfo)" end
    local T = ZeD.T
    local name = tostring(ci.name or "")
    local nm = nil
    for _, e in ipairs(r.texts[c] or {}) do
        if e.font == T.fontF4 and H.namePart(e.text, name) and (nm == nil or e.y < nm.y) then nm = e end
    end
    local bl, nb = nil, 0
    for _, t in ipairs(c._viewToggleRects or {}) do
        if S.HEAD_VIEWS[t.view] then
            nb = nb + 1
            bl = math.min(bl or t.x, t.x)
        end
    end
    local whole = nm ~= nil and nm.text == name
    local cut = nm ~= nil and #name > 3 and #nm.text >= 6 and nm.text:sub(-3) == "..." and nm.text:sub(1, 3) == name:sub(1, 3)
    local nR = nm and (nm.x + H.measure(T.fontF4, nm.text)) or nil
    local clear = nR ~= nil and (bl == nil or nR <= bl + 1)
    local lvl = c._gv and c._gv.headLevel or nil
    local words = "name \"" .. name .. "\" drawn as \"" .. tostring(nm and nm.text) .. "\" " .. H.num(nm and nm.x) .. ".." .. H.num(nR)
        .. "; " .. nb .. " heading buttons from " .. H.num(bl) .. "; headLevel " .. tostring(lvl) .. "; the list " .. H.num(c:getWidth()) .. " px wide"
    return (whole or cut) and clear, words
end

-- ===================================================================== the grid
-- the container key of window k's list, and whether it is a grid now
function H.key(k)
    local c = H.content(k)
    return c and c._gv and c._gv.key or nil
end
function H.isGrid(k)
    local key = H.key(k)
    if not key then return false end
    local ok, v = pcall(S.IR.isGridKey, key, S.p)
    return ok and v == true
end
-- the raw choice kept before the first change, for the put-back
function H.keep(key)
    if not key or S.gk.saved[key] then return end
    local md = S.p:getModData()
    if S.gk.had == nil then S.gk.had = (md.ZeD_GridViews ~= nil) end
    local t = md.ZeD_GridViews
    S.gk.saved[key] = true
    S.gk.old[key] = t and t[key]
    S.gk.keys[#S.gk.keys + 1] = key
end
-- window k's list to the grid (on) or the list: its heading's view button pressed as a click does (its view:flip
-- rect, the list's own onMouseDown); the choice set directly only where the button is not drawn (said in the words)
function H.view(k, on)
    local c = H.content(k)
    local key = H.key(k)
    if not (c and key) then return "no list" end
    H.keep(key)
    if H.isGrid(k) == on then return "already" end
    local hit = nil
    for _, t in ipairs(c._viewToggleRects or {}) do if t.view == "flip" then hit = t end end
    if hit then
        local lx, ly = hit.x + math.floor(hit.w / 2), hit.y + math.floor(hit.h / 2)
        H.atPointer(c:getAbsoluteX() + lx, c:getAbsoluteY() + ly, function() c:onMouseDown(lx, ly) end)
        if H.isGrid(k) == on then return "the view button" end
    end
    pcall(S.IR.setGridKey, key, on, S.p)
    return "set directly (the view button " .. (hit and "did not flip it" or "not drawn") .. ")"
end
function H.gridBack()
    local md = S.p and S.p:getModData()
    if not md then return end
    local t = md.ZeD_GridViews
    if t then
        for _, key in ipairs(S.gk.keys) do t[key] = S.gk.old[key] end
        if S.gk.had == false then
            local any = false
            for _ in pairs(t) do any = true; break end
            if not any then md.ZeD_GridViews = nil end
        end
    end
    S.gk.keys, S.gk.saved, S.gk.old = {}, {}, {}
end
-- the whole width for c's grid cols: cols cells, cols - 1 gaps, two insets and the scrollbar's gutter
function H.wholeW(c)
    local T, gv = ZeD.T, c and c._gv
    if not (gv and gv.cols and gv.cell and gv.gap) then return nil end
    return gv.cols * (gv.cell + gv.gap) - gv.gap + T.sp.sm * 2 + T.sp.scrollbarW
end
-- one window's grid read: ok, words. want: the list's expected width (nil: whole cells only)
function H.gridRead(k, want)
    local w, c = H.win(k), H.content(k)
    if not (w and c) then return false, "no window" end
    local R = S.IR
    local cw = c:getWidth()
    local whole = H.wholeW(c)
    local fix = R.hugInvW(cw, 1, 0, false)
    local why = {}
    if not H.isGrid(k) or not (c._gv and c._gv.on) then why[#why + 1] = "the grid is not on" end
    if c._hugN ~= 1 or w._gridHug == nil then why[#why + 1] = "the window does not hug (hugN " .. tostring(c._hugN) .. ")" end
    if whole == nil or math.abs(whole - cw) > 0 then why[#why + 1] = "not whole cells" end
    if fix ~= cw then why[#why + 1] = "hugInvW of the width is not itself" end
    if want ~= nil and math.abs(want - cw) > 0 then why[#why + 1] = "not the width expected" end
    local words = "list " .. H.num(cw) .. " px (" .. H.units(cw) .. " units), expected " .. H.num(want) .. ", whole width for "
        .. tostring(c._gv and c._gv.cols) .. " cells " .. H.num(whole) .. ", hugInvW of it " .. H.num(fix) .. ", window " .. H.gs(H.geo(w))
    if #why > 0 then words = words .. " -> " .. table.concat(why, "; ") end
    return #why == 0, words
end

-- ===================================================================== the list's columns
function H.cols(k)
    local c = H.content(k)
    local z = {}
    for _, h in ipairs((c and c._hitZones) or {}) do
        if type(h.id) == "string" and h.id:sub(1, 4) == "hdr:" then z[h.id:sub(5)] = true end
    end
    local o = { name = z.name == true, cat = z.cat == true, cond = z.cond == true, wt = z.wt == true,
        showCat = c and c._showCat, showCond = c and c._showCond, w = c and c:getWidth() or 0 }
    o.words = H.units(o.w) .. " units (" .. H.num(o.w) .. " px): head row Name " .. tostring(o.name) .. ", Category " .. tostring(o.cat)
        .. ", Status " .. tostring(o.cond) .. ", Weight " .. tostring(o.wt) .. " (_showCat " .. tostring(o.showCat) .. ", _showCond " .. tostring(o.showCond) .. ")"
    return o
end

-- ===================================================================== the crate (vk5_header.lua)
function H.freeSq(skip)
    local cell = getCell()
    local here = S.p:getCurrentSquare()
    if not (cell and here) then return nil end
    local x, y, z = math.floor(S.p:getX()), math.floor(S.p:getY()), math.floor(S.p:getZ())
    for _, d in ipairs(S.AROUND) do
        local sq = cell:getGridSquare(x + d[1], y + d[2], z)
        local ok = false
        if sq and sq ~= skip then
            pcall(function()
                ok = sq:isFree(false) and sq:getObjects():size() <= 1 and sq:getWorldObjects():size() == 0
                    and sq:getVehicleContainer() == nil and here:canReachTo(sq)
            end)
        end
        if ok then return sq end
    end
    return nil
end
function H.mkCrate(sq)
    local c = nil
    pcall(function()
        local o = IsoObject.new(getCell(), sq, "carpentry_01_16")
        if not o then return end
        o:createContainersFromSpriteProperties()
        sq:AddTileObject(o)
        local inv = o:getContainer()
        if inv then
            pcall(function() inv:setExplored(true) end)
            c = { obj = o, inv = inv, sq = sq, items = {} }
        end
    end)
    return c
end
function H.toCrate(c, ft)
    local it = nil
    pcall(function() it = c.inv:AddItem(ft) end)
    if it then
        pcall(function() it:getModData().ZeDQA_spawned = true end)
        c.items[#c.items + 1] = it
    end
    return it
end
function H.rmCrate(c)
    if not c then return end
    for _, it in ipairs(c.items) do
        pcall(function() local con = it:getContainer(); if con then con:Remove(it) end end)
    end
    if c.obj then
        pcall(function()
            local sq = c.obj:getSquare() or c.sq
            if sq then
                pcall(function() sq:transmitRemoveItemFromSquare(c.obj) end)
                if c.obj:getObjectIndex() >= 0 then sq:RemoveTileObject(c.obj) end
            end
        end)
    end
    c.obj = nil
end
function H.crateUp(c)
    local up = false
    pcall(function() up = c ~= nil and c.obj ~= nil and c.obj:getSquare() ~= nil and c.obj:getObjectIndex() >= 0 end)
    return up
end
function H.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if cond() then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end
-- the base width of a list for GRID (deck: the Deck's 222 px; else the usual 372 units)
function H.basePx() if S.deck then return 222 end; return ZeD.T.px(372) end

-- ===================================================================== 1: as found, the scene
Q.step(2, function()
    local ready = S.F ~= nil and S.St ~= nil and S.St.lookStyleOption ~= nil and S.IR ~= nil and S.IR.hugInvW ~= nil
        and S.IR.isGridKey ~= nil and S.IR.setGridKey ~= nil and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil
        and ZeD.TM ~= nil and ZeD.T ~= nil and S.p ~= nil
    if not Q.check(ready, "ZeD's windows, Style, the lists and the grid's hug (InventoryRenderer.hugInvW) are loaded (staging)",
        "hugInvW " .. tostring(S.IR ~= nil and S.IR.hugInvW ~= nil) .. " (main has none)") then S.dead = true; return end
    S.was.char, S.was.world = H.charOpen(), H.worldOpen()
    S.was.geo.c = S.was.char and H.geo(RT.cw()) or nil
    S.was.geo.w = S.was.world and H.geo(RT.ww()) or nil
    S.was.tab.c = RT.cw() and RT.cw()._activeTab or nil
    S.was.tab.w = RT.ww() and RT.ww()._activeTab or nil
    S.was.style = S.St.lookStyleOption:getValue()
    S.was.taken = true
    Q.say("NOTE as found: Character open " .. tostring(S.was.char) .. " " .. H.gs(S.was.geo.c) .. " on " .. tostring(S.was.tab.c)
        .. ", World open " .. tostring(S.was.world) .. " " .. H.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w)
        .. ", Style " .. tostring(S.was.style) .. ", screen " .. S.W .. "x" .. S.Hs .. ", UI scale " .. tostring(ZeD.T.scale)
        .. ", deck " .. tostring(S.deck))
    local sq = H.freeSq(nil)
    S.ca = sq and H.mkCrate(sq) or nil
    if not S.ca then
        H.fail("the scene", "a free square in reach beside him for the crate")
        S.dead = true
        return
    end
    H.toCrate(S.ca, "Base.Apple")
    H.toCrate(S.ca, "Base.Nails")
    H.toCrate(S.ca, "Base.Pencil")
    H.toCrate(S.ca, "Base.Hammer")
    S.bag = RT.give("Base.Bag_Schoolbag")
    pcall(function() S.bagInv = S.bag and S.bag:getItemContainer() or nil end)
    if #S.ca.items < 4 or not S.bagInv then
        H.fail("the scene", "the crate's four things or his school bag could not be made")
        S.dead = true
        return
    end
    H.style(1)
    H.pairOpen()
end)
Q.waitMs(400)
Q.step(1, function()
    if S.dead then return end
    H.pairOpen()
    H.worldOn(S.ca.inv)
    H.charOn(S.p:getInventory())
end)
H.waitUntil(5000, function()
    if S.dead then return true end
    return H.worldShows(S.ca.inv) and H.charShows(S.p:getInventory())
end, function(ok)
    if S.dead then return end
    if not ok then
        H.fail("the scene", "the World window on the crate alone (" .. tostring(H.worldShows(S.ca.inv)) .. ") and the Character window on his inventory ("
            .. tostring(H.charShows(S.p:getInventory())) .. ")")
        S.dead = true
        return
    end
    -- both lists as lists first (the choices kept for the put-back)
    S.k.g.v0w = H.view("w", false)
    S.k.g.v0c = H.view("c", false)
end)
Q.waitMs(500)

-- ===================================================================== 2: GRID (both windows at the base width)
H.queueInvW("w", H.basePx)
H.queueInvW("c", H.basePx)
Q.step(1, function()
    if S.dead then return end
    for _, k in ipairs({ "w", "c" }) do
        local w, c = H.win(k), H.content(k)
        S.k.g[k] = { base = w and w._baseInvW, listW = c and c:getWidth() }
    end
    Q.say("NOTE the lists at their base width: World " .. H.num(S.k.g.w.listW) .. " px (_baseInvW " .. H.num(S.k.g.w.base)
        .. "), Character " .. H.num(S.k.g.c.listW) .. " px (_baseInvW " .. H.num(S.k.g.c.base) .. "), asked " .. H.num(H.basePx()))
    S.k.g.vw = H.view("w", true)
    S.k.g.vc = H.view("c", true)
end)
Q.waitMs(900)
Q.step(1, function()
    if S.dead then return end
    local R = S.IR
    for i, k in ipairs({ "w", "c" }) do
        local g = S.k.g[k]
        local want = g.listW and R.hugInvW(g.listW, 1, 0, false) or nil
        local ok, words = H.gridRead(k, want)
        Q.check(ok, "GRID " .. i .. ": the " .. ((k == "w") and "World" or "Character") .. " window's grid hugs whole cells (hugInvW of its list width)",
            "turned on by " .. tostring((k == "w") and S.k.g.vw or S.k.g.vc) .. "; " .. words)
    end
    local fig = (S.W >= 3800 and 642) or ((S.W == 1920) and 366) or (S.deck and 192) or nil
    Q.say("NOTE Build's figure for this screen: " .. tostring(fig) .. " px; World " .. H.num(H.content("w") and H.content("w"):getWidth())
        .. ", Character " .. H.num(H.content("c") and H.content("c"):getWidth()))
end)
H.shot(function() return "grid_" .. S.W .. "x" .. S.Hs end)

-- ===================================================================== 3: DRAG (the World window's right edge)
Q.step(1, function()
    if S.dead then return end
    local w, c = RT.ww(), H.content("w")
    if not (w and c and w._startResize and H.isGrid("w")) then H.fail("DRAG", "the World window's grid and its resize"); return end
    local gv = c._gv
    local step = (gv and gv.cell and gv.gap) and (gv.cell + gv.gap) or ZeD.T.px(56)
    local w0, inv0 = w:getWidth(), c:getWidth()
    local mx = tonumber(w.maximumWidth) or 0
    local room = getCore():getScreenWidth() - (w:getX() + w0)
    if mx > 0 then room = math.min(room, mx - w0) end
    local d = (room > step * 2) and math.floor(step * 0.7) or -math.floor(step * 0.3)
    S.k.g.drag = { w0 = w0, inv0 = inv0, d = d, aim = inv0 + d, step = step }
    local cw = RT.cw()
    if cw then cw._uiPrevDown = true end   -- (no fresh press on the other window)
    w._uiPrevDown = true
    local ax, ay = w:getAbsoluteX(), w:getAbsoluteY()
    w:_startResize("e")
    H.dragOn(ax + w0 + d, ay + math.floor(w:getHeight() / 2))
end)
Q.waitMs(600)
Q.step(1, function() if S.drag then H.dragUp() end end)
Q.waitMs(400)
Q.step(1, function()
    H.dragOff()
    local w = RT.ww()
    if w and w._resizing and w._stopResize then pcall(w._stopResize, w) end
end)
Q.waitMs(500)
Q.step(1, function()
    if S.dead or S.off.DRAG then return end
    local g = S.k.g.drag
    local c = H.content("w")
    local want = S.IR.hugInvW(g.aim, 1, 0, true)
    local floorW = S.IR.hugInvW(g.aim, 1, 0, false)
    local ok, words = H.gridRead("w", want)
    Q.check(ok, "DRAG: a drag of the World window's right edge snaps to the nearest whole cell (hugInvW nearest), whole cells after the let go",
        "dragged " .. H.num(g.d) .. " px from the list's " .. H.num(g.inv0) .. " (a cell is " .. H.num(g.step) .. "): the pointer's width "
        .. H.num(g.aim) .. ", nearest " .. H.num(want) .. ", the floor would be " .. H.num(floorW) .. "; " .. words
        .. "; still resizing " .. tostring(RT.ww() and RT.ww()._resizing))
end)

-- ===================================================================== 4: BACK (the list's width again)
Q.step(1, function()
    if S.dead then return end
    S.k.g.bw = H.view("w", false)
    S.k.g.bc = H.view("c", false)
end)
Q.waitMs(900)
Q.step(1, function()
    if S.dead then return end
    local T = ZeD.T
    for i, k in ipairs({ "w", "c" }) do
        local g = S.k.g[k]
        local w, c = H.win(k), H.content(k)
        local cw = c and c:getWidth() or 0
        local want = g.base and T.px(g.base) or nil
        local ok = w ~= nil and not H.isGrid(k) and w._gridHug == nil and want ~= nil and math.abs(cw - want) <= 1
            and w._baseInvW ~= nil and math.abs(w._baseInvW - g.base) < 0.5
        Q.check(ok, "BACK " .. i .. ": the " .. ((k == "w") and "World" or "Character") .. " window back in List gets its saved list width (_baseInvW) again",
            "turned back by " .. tostring((k == "w") and S.k.g.bw or S.k.g.bc) .. "; list " .. H.num(cw) .. " px, T.px(_baseInvW found "
            .. H.num(g.base) .. ") = " .. H.num(want) .. ", _baseInvW now " .. H.num(w and w._baseInvW) .. ", still hugging "
            .. tostring(w and w._gridHug ~= nil) .. ", grid " .. tostring(H.isGrid(k)))
    end
end)

-- ===================================================================== 5: LIST (the World list's columns by width)
H.queueInvW("w", function() return ZeD.T.px(372) end)
Q.step(1, function()
    if S.dead then return end
    local o = H.cols("w")
    S.k.l.at372 = o
    local okW = o.name and o.wt and o.cat and not o.cond and o.showCat == true and o.showCond == false
    Q.check(okW and math.abs(H.units(o.w) - 372) <= 1,
        "LIST 1: at 372 units the list shows Name, Category and Weight, no Status (name first, weight second, Category third)", o.words)
end)
H.shot("list_372")
S.k.l.reads = {}
for _, u in ipairs(S.WIDE) do
    H.queueInvW("w", function() return ZeD.T.px(u) end)
    Q.step(1, function()
        if S.dead then return end
        local o = H.cols("w")
        o.asked = u
        local t = S.k.l.reads
        t[#t + 1] = o
        if o.cond and not S.k.l.firstCond then S.k.l.firstCond = H.units(o.w) end
    end)
end
Q.step(1, function()
    if S.dead then return end
    local ok, words, seen, last = true, {}, false, 0
    for _, o in ipairs(S.k.l.reads) do
        words[#words + 1] = "asked " .. o.asked .. ": " .. o.words
        if not (o.name and o.wt) then ok = false end
        if o.cond and not o.cat then ok = false end
        if seen and not o.cond and o.w > last then ok = false end
        if o.cond then seen = true; last = o.w end
    end
    Q.check(ok and seen, "LIST 2: widened, Status comes back once there is room, only with Category, and Name and Weight always show",
        table.concat(words, " | "))
    S.k.l.shotU = S.k.l.firstCond
end)
Q.step(1, function()
    if S.dead or not S.k.l.shotU then return end
    H.setInvW("w", ZeD.T.px(S.k.l.shotU))
end)
Q.waitMs(600)
H.shot(function() return "list_" .. tostring(S.k.l.shotU or "none") end)
-- LIST 3: the Deck's width (a deck screen: 222 px), then the least (200 units)
if S.deck then
    H.queueInvW("w", function() return 222 end)
    Q.step(1, function()
        if S.dead then return end
        local o = H.cols("w")
        Q.check(o.name and o.wt and not o.cat and not o.cond and math.abs(o.w - 222) <= 1,
            "LIST 3 (Deck): at the Deck's 222 px the list shows Name and Weight only", o.words)
        S.k.l.deckU = H.units(o.w)
    end)
    H.shot(function() return "list_" .. tostring(S.k.l.deckU) end)
end
H.queueInvW("w", function() return ZeD.T.px(200) end)
Q.step(1, function()
    if S.dead then return end
    local o = H.cols("w")
    local w = RT.ww()
    Q.check(o.name and o.wt and not o.cond and H.units(o.w) <= 210,
        "LIST 3: at the list's least width (about 200 units) Name and Weight show, no Status",
        o.words .. "; the window's minimum " .. H.num(w and w.minimumWidth))
end)

-- ===================================================================== 6: NARROW (the name always wins)
Q.step(1, function()
    if S.dead then return end
    H.charOn(S.bagInv)
    H.worldOn(S.ca.inv)
end)
H.waitUntil(4000, function()
    if S.dead then return true end
    return H.charShows(S.bagInv) and H.worldShows(S.ca.inv)
end, function(ok)
    if S.dead then return end
    if not ok then
        H.fail("NARROW", "the school bag alone in the Character window (" .. tostring(H.charShows(S.bagInv)) .. ") and the crate alone in the World window ("
            .. tostring(H.worldShows(S.ca.inv)) .. ")")
        return
    end
    H.narrow()
end)
Q.waitMs(400)
Q.step(1, function() if not (S.dead or S.off.NARROW) then H.narrow() end end)
Q.waitMs(600)
function H.narrowRead(style, label)
    Q.step(1, function() if not (S.dead or S.off.NARROW) then H.style(style) end end)
    Q.waitMs(900)
    Q.step(1, function()
        if S.dead or S.off.NARROW then return end
        H.rest()
        H.recOn()
    end)
    Q.step(3, function()
        if S.dead or S.off.NARROW then return end
        local r = H.recOff()
        H.fakeOff()
        local okW, wW = H.nameDrawn("w", r)
        local okC, wC = H.nameDrawn("c", r)
        Q.check(okW and okC and (style ~= 2 or H.lite()),
            "NARROW " .. label .. ": at the windows' least width each heading draws its container's name (whole, or three letters and the dots) left of its buttons",
            "Lite " .. tostring(H.lite()) .. "; World (the crate): " .. wW .. "; Character (the school bag): " .. wC)
    end)
end
H.narrowRead(1, "(Full)")
H.narrowRead(2, "(Lite)")

-- ===================================================================== 7: put back
Q.mark()
Q.step(1, function()
    H.dragOff()
    local ww = RT.ww()
    if ww and ww._resizing and ww._stopResize then pcall(ww._stopResize, ww) end
    H.recOff()
    H.fakeOff()
    H.cursor(false)
    H.closeCols()
    if S.p then H.gridBack() end
    if RT.cw() and H.charOpen() then H.charOn(S.p:getInventory()) end
    if S.was.taken then H.style(S.was.style) end
    H.rmCrate(S.ca)
    RT.takeBack()
    if ww then ww._containerTimer = 30 end
end)
Q.waitMs(400)
Q.step(1, function()
    if not S.was.taken then return end
    H.windowsBack()
    local cw, ww = RT.cw(), RT.ww()
    if S.was.char and cw and S.was.tab.c and cw._activeTab ~= S.was.tab.c then pcall(RT.charTab, S.was.tab.c) end
    if S.was.world and ww and S.was.tab.w and ww._activeTab ~= S.was.tab.w then pcall(RT.worldTab, S.was.tab.w) end
end)
Q.waitMs(400)
Q.step(1, function()
    if not S.was.taken then return end
    if S.was.char then H.placeBack(RT.cw(), S.was.geo.c) end
    if S.was.world then H.placeBack(RT.ww(), S.was.geo.w) end
end)
Q.waitMs(300)
Q.step(1, function() if S.was.taken then H.baseBack() end end)
Q.waitMs(300)
Q.step(1, function()
    if not S.was.taken then return end
    local cw, ww = RT.cw(), RT.ww()
    local why = {}
    if H.charOpen() ~= S.was.char or H.worldOpen() ~= S.was.world then why[#why + 1] = "windows open " .. tostring(H.charOpen()) .. "/" .. tostring(H.worldOpen()) end
    if S.was.char and not H.sameGeo(H.geo(cw), S.was.geo.c) then why[#why + 1] = "Character at " .. H.gs(H.geo(cw)) end
    if S.was.world and not H.sameGeo(H.geo(ww), S.was.geo.w) then why[#why + 1] = "World at " .. H.gs(H.geo(ww)) end
    if S.St.lookStyleOption:getValue() ~= S.was.style then why[#why + 1] = "Style " .. tostring(S.St.lookStyleOption:getValue()) end
    if H.crateUp(S.ca) then why[#why + 1] = "the crate still stands" end
    if S.stuck then why[#why + 1] = "a watched or stood-in function was replaced by someone else meanwhile" end
    if S.drag then why[#why + 1] = "the drag's stand-ins still on" end
    if #S.gk.keys > 0 then why[#why + 1] = "List or Grid choices not put back" end
    for _, k in ipairs({ "c", "w" }) do
        local w, v = H.win(k), S.was.invW[k]
        if w and v ~= nil and v ~= false and math.abs((w._baseInvW or 0) - v) > 0.5 then
            why[#why + 1] = k .. " _baseInvW " .. H.num(w._baseInvW) .. " (found " .. H.num(v) .. ")"
        end
    end
    Q.check(#why == 0, "put back: windows, Style, the saved list widths, the List or Grid choices, the crate and the bag as found; nothing left stood in",
        (#why == 0) and ("Character " .. H.gs(H.geo(cw)) .. ", World " .. H.gs(H.geo(ww))) or table.concat(why, "; "))
end)

Q.start()
