-- ZeDUI/tools/qa/vk5_header.lua  (Nov 22 2026, QA; tag vk5_hdr): the in-game proof of branch header, head d179355c4
-- (394ed4611 Header order and "Number 1", d179355c4 a Take all per Loot column, the band's pad loop, Icon color), on
-- top of main. The director: "In the header strip of inventories, let's do buttons, icon, container name, and then
-- the weight and items." Then the World window's two Take all buttons: keep the heading's, drop the footer's. Then
-- "give the header and footer icons a little taste of color, just like we did for context menus."
-- Built on rt_kit.lua (the global RT), run after zedqa_prelude.lua. grep "ZEDQA vk5_hdr". Manifest: vk5.txt.
--
-- REFIT (Nov 22 2026, QA) for branch listgrid, head 1916f88ab. The director the same evening: "Buttons in headers and
-- footers... move them to the right"; "Transfer buttons, always in the footer. Selection buttons, always in the
-- header."; "Name always wins." So a heading now reads [icon] [name] ... [weight and count] [Pick all, Filter, view
-- flip], no Take all in any heading; the World band has Take all first, right-aligned; each Loot column has its own
-- foot with its Take all (view:lootall:<key>); pad Up from the top row lands on Pick all (view:all:<key>), Down past
-- the last row on the band's Take all (worldCtl:take). HDR 1-4, BAND, PAD 1, PAD 2 and COL below say the new order;
-- NARROW is new (the name keeps three letters and the dots at a narrow heading). They FAIL on main (header's order)
-- and PASS on listgrid; MARK and PAD 3 are unchanged. Run it at 4K and at 1280x800 (the Deck size: NARROW is the
-- Lite and Deck case there).
--
-- How to read the log: the proofs are the lines that start "HDR", "BAND", "PAD", "COL", "NARROW" and "MARK". A part
-- that cannot be staged FAILS with "(staging)" in its words (a part not proven is never a SKIP). "NOTE" lines are
-- readings. The "put back" check at the end passes on both.
--
-- The scene: two crates (carpentry_01_16) on free squares beside him: crate A holds an apple and a box of nails,
-- crate B a pencil and a pen. Given to him: a box of nails (so Same type has something to move both ways) and a
-- school bag (in his inventory, the Character window's bag for the columns' check). ZeD's input mode locked to the
-- mouse for the reads and the pictures, to the controller for the pad's walk (vx12_wheel.lua's lock).
-- What is read, never pixels written in (4K at UI scale 1.75 and 1280x800 alike): a heading as its list draws it in
-- one frame, ZeD.Atoms.drawIcon (the container's icon), the list's own drawText (the name in F4, the weight in F1,
-- the count in F5) and ZeD.Atoms.drawPxIcon (a pixel icon and the mark set and color it is handed) watched for that
-- frame; the heading's buttons as the list stamps them (content._viewToggleRects, a column's cs.viewToggleRects).
-- The pointer: while a frame is read, each list answers isMouseOver false (at rest), or the World list answers true
-- with its getMouseX / getMouseY on the Same type button's middle (hovered); for the pictures the cursor is hidden.
--
-- The checks:
--   HDR 1  Full, Dark, crate A on show alone in the World window: the container's icon at the heading's left pad
--          (within 2 px of the column's left plus its inset), the name right of the icon, the weight right of the
--          name, every button right of the weight and the name, Pick all the leftmost button, the buttons ending at
--          the column's right (within two insets), the count's right edge on the weight's, no Take all
--          (view:lootall) in the heading (a weight or count the heading drops where it would cut the name, by
--          design, is said in the words, not failed). Main: the buttons first at the left, Take all among them ->
--          FAIL. Picture vk5_header_full_dark.
--   HDR 2  The same in the Character window (his inventory alone). Main -> FAIL.
--   HDR 3  HDR 1 with Style Lite (word buttons). Main -> FAIL. Picture vk5_header_lite_dark.
--   HDR 4  HDR 2 with Style Lite. Main -> FAIL.
--   BAND   The World window's footer band (content._cc: its moves and laid-out rects, no rows marked) has Take all
--          ("take") as its first button and Same type; both bands (World and Character) are right-aligned: not a
--          ribbon, the last button ending at the band's right end (x1, within 1 px), room left of the first. Main:
--          no Take all in the band, the moves from the left -> FAIL.
--   NARROW Both windows narrowed to their least width (the window's own minimumWidth: the inventory's 200 units),
--          crate A in the World window, the school bag ("School Bag") in the Character window, Full and then Lite:
--          each heading draws the container's name whole or its first three letters and the dots, left of every
--          button (GV.headLevel, the buttons that gave way, said in the words). Main: Lite's word buttons squeeze
--          the name out -> FAIL. Pictures vk5_narrow_full, vk5_narrow_lite. At 1280x800 this is the Deck case.
--   MARK 1 At rest (the lists not under the pointer), the band's Same type and the heading's view button draw their
--          icon's mark (drawPxIcon handed a mark set) in both windows; hovered (the World list's pointer on Same
--          type), the World Same type draws no mark. Main: no mark ever handed -> FAIL.
--   MARK 2 Same type's mark color as handed and solved (ZeD.PxIcon.markColor): the theme's blue (T.marks.blue) in
--          the World window (Take), red (T.marks.red) in the Character window (Put in). Main: none -> FAIL.
--   PAD 1  Full, the controller, crate A alone: pad Up from the list's top stop lands on the heading's Pick all
--          (view:all:), pad Down from its last row on the band's Take all (worldCtl, ccKey "take"). Main: both on the
--          heading's Take all -> FAIL.
--   PAD 2  From the heading's Pick all: Up leaves the list for the title bar (a stop outside the list and the band),
--          further Ups (at most three) wrap to the footer band without passing the list, and Right walks the band
--          (another band stop). Main: the start is the heading's Take all -> FAIL.
--   PAD 3  From the band's first stop, Down lands on the list's first row on show; from the band, Up lands on its
--          last row on show. Main: Down from the band does not reach the list -> FAIL.
--          NOTE: the Character window's band, Down (listgrid: the loop holds in both windows, so Down goes to the list; read, not checked).
--   COL    Crate A on show, crate B added as a column (ZeD_WorldWindow.toggleColumn, the strip's Ctrl-click), the
--          school bag shown alone in the Character window: each column has a Take all in its own foot (its
--          view:lootall: rect in the column's bottom band, inside the column, none in its heading), and a press on
--          it (the list's own onMouseDown at that button's middle) takes that column's crate, both things, from that
--          crate only, into the school bag (the moves recorded at ISTimedActionQueue.add, nothing moved). Main:
--          the Take all sits in each column's heading -> FAIL. Picture vk5_columns_two (before the presses).
-- Pictures (Zomboid/Screenshots/vk5_<name>.png, cursor hidden, the lists at rest): header_full_dark,
-- header_lite_dark, header_full_light (Light), columns_two, band_hc (High contrast: the band and the heading),
-- narrow_full, narrow_lite.
--
-- Safety: nothing is eaten, moved or used: the presses that could move things run with ISTimedActionQueue.add /
-- addAfter recording and queuing nothing (vk1_pad.lua's recorder), and an action that reaches the real queue anyway
-- is cleared at once (FAIL). What it puts back (also when a step throws or the time runs out): the recorder, the
-- watched drawing and the faked pointer readings gone, the cursor shown; the columns closed; the pad's focus let go;
-- Style and the theme as found (values only, never saved); the input lock and the mode ZeD read; both crates and
-- what is in them removed, the nails and the bag taken back; the windows open or shut as found, where and as big as
-- they were, on their tabs, each window's saved inventory width (_baseInvW) as found (NARROW resizes them). No option
-- is saved, no file is written but the seven pictures.
-- The refit is not run in game yet; parse-checked with the game's Kahlua compiler (KCheck).

if not (RT and RT.make) then
    print("ZEDQA vk5_hdr ERR the kit (rt_kit.lua) did not run first")
    print("ZEDQA vk5_hdr VERDICT FAIL 1")
    print("ZEDQA vk5_hdr DONE")
    return
end

local Q = RT.make("vk5_hdr")
Q.maxMs = 600000   -- (ten minutes, then the put-back; a run takes about two)
local S = { p = RT.p, pn = RT.pn, was = { geo = {}, tab = {}, invW = {} }, k = { pad = {}, col = {}, mk = {}, nar = {} }, fakes = {} }
local H = {}
S.Z = ZeD or {}
S.F = S.Z.Input and S.Z.Input.Focus
S.Det = S.Z.Input and S.Z.Input.Detector
S.St, S.CT, S.IR = S.Z.Settings, S.Z.ContainerControls, S.Z.InventoryRenderer
S.AROUND = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
-- (listgrid: the heading's buttons; Take all, "lootall", is a Loot column's foot now, never a heading's)
S.HEAD_VIEWS = { all = true, filter = true, flip = true }

-- ===================================================================== words and numbers
function H.num(v)
    local x = tonumber(v)
    if x == nil then return "?" end
    local r = math.floor(x * 10 + 0.5) / 10
    if r == math.floor(r) then return tostring(math.floor(r)) end
    return tostring(r)
end
function H.itemName(it)
    if not it then return "nothing" end
    local nm = nil
    pcall(function() nm = it:getDisplayName() end)
    return tostring(nm or "a thing")
end
-- staging that cannot go on: one FAIL line, the part's checks not run
function H.fail(key, why)
    if S.off[key] then return end
    S.off[key] = true
    Q.check(false, tostring(key) .. " (staging): " .. tostring(why) .. " (not proven)")
end
S.off = {}
function H.measure(font, text)
    local w = 0
    pcall(function() w = ZeD.TM:MeasureStringX(font, tostring(text or "")) end)
    return w
end

-- ===================================================================== the windows
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
-- a window not where it was found, set back by its own setters (never ZEDQA_LAYOUT_BACK)
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
-- the windows open or shut as found (the opens first, the shuts last)
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
-- the World window on Loot with inv on show alone
function H.worldOn(inv)
    local ww = RT.ww()
    if not (ww and inv) then return end
    if ww._activeTab ~= "loot" then RT.worldTab("loot") end
    if #(ww._mcSelected or {}) > 0 then pcall(ZeD_WorldWindow.closeColumns, ww) end
    local c = ww._containers and ww._containers[ww._activeContainer or 0]
    if c and c.inventory == inv and ww._mainContent and ww._mainContent._inventory == inv then return end
    pcall(ZeD_WorldWindow.selectContainer, inv, 60, S.pn)
end
-- the Character window on Loot with inv (a bag of his, or his inventory) on show alone
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

-- ===================================================================== the input mode ZeD reads (vk3_pad.lua)
function H.lockFound()
    local key = nil
    local api = PZAPI and PZAPI.ModOptions
    local zo = (api and api.getOptions) and api:getOptions("ZeD_UI") or nil
    local o = zo and zo.dict and zo.dict.inputModeLock
    local keys = S.St and S.St.inputLockKeys
    if o and o.getValue and keys then key = keys[o:getValue() or 1] end
    if key == nil and S.p then
        local md = S.p:getModData()
        local g = md and md.ZeD_Gamepad
        key = g and g.inputModeLock
    end
    return key or "auto"
end
function H.mode() return (S.Det and S.Det.getMode) and S.Det.getMode(S.pn) or nil end
function H.lock(mode)
    if not (S.Det and S.Det.setLockedMode) then return end
    if mode then
        if S.lockWas == nil then S.lockWas = H.lockFound() end
        S.Det.setLockedMode(mode)
        S.locked = true
        return
    end
    if not S.locked then return end
    S.locked = false
    S.Det.setLockedMode(nil)
    if S.lockWas == "kbm" or S.lockWas == "gamepad" then S.Det.setLockedMode(S.lockWas) end
end
function H.modeBack()
    local held = S.locked
    H.lock(false)
    if not (held and S.lockWas == "auto" and S.was.mode ~= nil and S.Det and S.Det.setLockedMode) then return end
    local want = (S.was.mode == "gamepad") and "gamepad" or "kbm"
    if H.mode() == want then return end
    S.Det.setLockedMode(want)
    S.modeHeld = want
end
function H.modeFree()
    if not S.modeHeld then return end
    S.modeHeld = nil
    S.Det.setLockedMode(nil)
end

-- ===================================================================== settings (the values only)
function H.opt(id)
    local o = nil
    local d = S.St and S.St.opts and S.St.opts.dict
    if d then o = d[id] end
    if o == nil then
        local api = PZAPI and PZAPI.ModOptions
        local zo = (api and api.getOptions) and api:getOptions("ZeD_UI") or nil
        o = zo and zo.dict and zo.dict[id] or nil
    end
    return o
end
function H.val(id)
    local o, v = H.opt(id), nil
    if o then pcall(function() v = o:getValue() end) end
    return v
end
function H.style(n)
    local o = S.St and S.St.lookStyleOption
    if o and n ~= nil and o:getValue() ~= n then o:setValue(n) end
end
function H.lite() return (S.St and S.St.lite and S.St.lite()) and true or false end
-- the base theme as Options' Apply leaves it: the value, then the theme worked out again from the options
-- (1 Dark, 2 Light, 3 High contrast)
function H.theme(v)
    local o = H.opt("baseTheme")
    if not (o and v) then return false end
    pcall(function() if o:getValue() ~= v then o:setValue(v) end end)
    pcall(function() S.St.applyThemeNow() end)
    return true
end

-- ===================================================================== the pointer (the one thing faked)
function H.atPointer(gx, gy, fn)
    local ox, oy = getMouseX, getMouseY
    getMouseX = function() return gx end
    getMouseY = function() return gy end
    local ok, err = pcall(fn)
    getMouseX, getMouseY = ox, oy
    return ok, err
end
-- list c answers isMouseOver with over, and its getMouseX / getMouseY with mx, my (not over: far away, so no
-- heading button reads the pointer either); H.fakeOff puts back
function H.fake(c, over, mx, my)
    if not c then return end
    local f = { c = c, over = rawget(c, "isMouseOver"), gx = rawget(c, "getMouseX"), gy = rawget(c, "getMouseY") }
    local px, py = mx, my
    if not over then px, py = -100000, -100000 end
    f.fo = function() return over and true or false end
    f.fx = function() return px end
    f.fy = function() return py end
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
-- both lists at rest (not under the pointer)
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
-- a picture: the lists at rest, the cursor hidden, two frames, the shot, then the 4K stall
function H.shot(name)
    Q.step(1, function()
        if S.dead then return end
        H.rest()
        H.cursor(true)
    end)
    Q.step(3, function()
        if S.dead then return end
        local file = "vk5_" .. name .. ".png"
        local ok, e = pcall(function() getCore():TakeFullScreenshot(file) end)
        if ok then Q.say("NOTE picture Zomboid/Screenshots/" .. file) else Q.say("NOTE the picture " .. name .. " was not taken: " .. tostring(e)) end
        H.fakeOff()
    end)
    Q.waitMs(1800)
end

-- ===================================================================== one frame's drawing, watched
-- the container icons, pixel icons and texts the two lists draw while it is on
function H.recOn()
    if S.rec then return end
    local A = ZeD.Atoms
    local r = { icons = {}, px = {}, texts = {}, panels = {}, saved = {} }
    r.icon0, r.px0 = A.drawIcon, A.drawPxIcon
    r.wIcon = function(panel, tex, x, y, size, ...)
        if r.panels[panel] then
            local l = r.icons[panel] or {}
            r.icons[panel] = l
            l[#l + 1] = { tex = tex, x = x, y = y, s = size }
        end
        return r.icon0(panel, tex, x, y, size, ...)
    end
    r.wPx = function(panel, id, x, y, box, alpha, tint, marks, kind, ...)
        if r.panels[panel] then
            local l = r.px[panel] or {}
            r.px[panel] = l
            l[#l + 1] = { id = id, x = x, y = y, box = box, marks = marks, kind = kind }
        end
        return r.px0(panel, id, x, y, box, alpha, tint, marks, kind, ...)
    end
    A.drawIcon, A.drawPxIcon = r.wIcon, r.wPx
    for _, k in ipairs({ "c", "w" }) do
        local c = H.content(k)
        if c then
            r.panels[c] = true
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
    return r
end
function H.recOff()
    local r = S.rec
    if not r then return nil end
    S.rec = nil
    local A = ZeD.Atoms
    if A.drawIcon == r.wIcon then A.drawIcon = r.icon0 else S.stuck = true end
    if A.drawPxIcon == r.wPx then A.drawPxIcon = r.px0 else S.stuck = true end
    for _, sv in ipairs(r.saved) do
        if sv.c.drawText == sv.fn then sv.c.drawText = sv.raw else S.stuck = true end
    end
    return r
end

-- ===================================================================== the heading as drawn
function H.namePart(text, name)
    if not (text and name) or name == "" then return false end
    if text == name then return true end
    local n = math.min(#text, #name, 3)
    return n >= 2 and text:sub(1, n) == name:sub(1, n)
end
-- one window's heading read from the frame r: ok, words
function H.header(k, r)
    local c = H.content(k)
    if not (c and r) then return false, "no list" end
    local ci = c._containerInfo
    local T = ZeD.T
    if not ci then return false, "the list has no heading (_containerInfo)" end
    local b = { n = 0 }
    for _, t in ipairs(c._viewToggleRects or {}) do
        if S.HEAD_VIEWS[t.view] then
            b.n = b.n + 1
            b.l = math.min(b.l or t.x, t.x)
            b.r = math.max(b.r or (t.x + t.w), t.x + t.w)
            b.words = (b.words and (b.words .. ", ") or "") .. tostring(t.view) .. "@" .. H.num(t.x)
            if t.view == "all" then b.all = t.x end
        end
        if t.view == "lootall" then b.loot = t.x end
    end
    local ic = nil
    for _, e in ipairs(r.icons[c] or {}) do
        if ci.texture ~= nil and e.tex == ci.texture and (ic == nil or e.y < ic.y) then ic = e end
    end
    local nm, wt, ct = nil, nil, nil
    for _, e in ipairs(r.texts[c] or {}) do
        if e.font == T.fontF4 and H.namePart(e.text, ci.name) and (nm == nil or e.y < nm.y) then nm = e end
        if e.font == T.fontF1 and ci.stats and ci.stats ~= "" and e.text == ci.stats and (wt == nil or e.y < wt.y) then wt = e end
        if e.font == T.fontF5 and ci.count and ci.count ~= "" and e.text == ci.count and (ct == nil or e.y < ct.y) then ct = e end
    end
    local why = {}
    -- (listgrid, "Name always wins": a short heading drops the view flip, then Filter, then Pick all; Pick all stays
    -- at a usual width, so one button at least)
    if b.n < 1 then why[#why + 1] = "no heading button stamped" end
    if not nm then why[#why + 1] = "no name drawn" end
    -- (no weight drawn: the heading drops it where it would cut the name, by design; said in the words, not a FAIL)
    local nR = nm and (nm.x + H.measure(T.fontF4, nm.text)) or nil
    local wR = wt and (wt.x + H.measure(T.fontF1, wt.text)) or nil
    local cR = ct and (ct.x + H.measure(T.fontF5, ct.text)) or nil
    local colL = c._renderXOffset or 0
    local colR = colL + (c._renderW or c:getWidth())
    local inset = (T.sp and T.sp.sm) or T.px(10)
    -- (listgrid, Buttons right: [icon] [name] ... [weight and count] [Pick all, Filter, view flip])
    if ic and math.abs(ic.x - (colL + inset)) > 2 then why[#why + 1] = "the icon is not at the heading's left pad" end
    if ic and nm and ic.x + ic.s > nm.x + 1 then why[#why + 1] = "the icon is not left of the name" end
    if b.n > 0 and nm and b.l < nR - 1 then why[#why + 1] = "a button sits left of the name's end" end
    if b.n > 0 and (colR - b.r < -1 or colR - b.r > inset * 2) then why[#why + 1] = "the buttons do not end at the column's right" end
    if b.n > 0 and (b.all == nil or b.all > b.l + 1) then why[#why + 1] = "Pick all is not the first (leftmost) button" end
    if b.loot ~= nil then why[#why + 1] = "the heading has a Take all (view:lootall)" end
    if wt and nm and wt.x < nR - 1 then why[#why + 1] = "the weight is not right of the name" end
    if wR and b.n > 0 and wR > b.l + 1 then why[#why + 1] = "the weight runs into the buttons" end
    if cR and wR and math.abs(cR - wR) > 1 then why[#why + 1] = "the count's right edge is not the weight's" end
    local words = "buttons [" .. tostring(b.words) .. "] " .. H.num(b.l) .. ".." .. H.num(b.r) .. "; icon " .. (ic and ("at " .. H.num(ic.x) .. ", " .. H.num(ic.s) .. " wide") or "none drawn")
        .. "; name \"" .. tostring(nm and nm.text) .. "\" " .. H.num(nm and nm.x) .. ".." .. H.num(nR)
        .. "; weight \"" .. tostring(wt and wt.text) .. "\" ending " .. H.num(wR) .. "; count \"" .. tostring(ct and ct.text) .. "\" ending " .. H.num(cR)
        .. "; column " .. H.num(colL) .. ".." .. H.num(colR) .. ", inset " .. H.num(inset) .. "; Take all in the heading " .. tostring(b.loot ~= nil) .. "; headLevel " .. tostring(c._gv and c._gv.headLevel)
    if #why > 0 then words = words .. " -> " .. table.concat(why, "; ") end
    return #why == 0, words
end
-- (NARROW, listgrid "Name always wins") one window's heading name in frame r: drawn whole, or its first three
-- letters and the dots, and left of every heading button; ok, words
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
-- both windows at their least width (the window's own minimumWidth); their saved list widths kept for the put-back
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
-- the saved list widths as found (after the windows are set back where they were)
function H.baseBack()
    for _, k in ipairs({ "c", "w" }) do
        local w = H.win(k)
        local v = S.was.invW[k]
        if w and v ~= nil then w._baseInvW = (v ~= false) and v or nil end
    end
end

-- the band's ids and keys (no rows marked)
function H.band(c)
    local cc = c and c._cc
    local keys, take, same = {}, false, false
    for _, m in ipairs((cc and cc.moves) or {}) do
        if m.id == "take" then take = true end
        if m.id == "same" then same = true end
    end
    local rects = (cc and cc.bottom and cc.bottom.rects) or {}
    for _, rr in ipairs(rects) do
        keys[#keys + 1] = tostring(rr.key)
        if rr.key == "take" then take = true end
    end
    return #rects, take, same, table.concat(keys, ", ")
end
-- (listgrid, Buttons right) a band laid out as a dialog's footer: not a ribbon, its last button ending at the band's
-- right end x1 (1 px), room left of its first; ok, the first button's key, words
function H.bandRight(c)
    local row = c and c._cc and c._cc.bottom
    local rects = (row and row.rects) or {}
    if #rects == 0 then return false, nil, "no band laid out" end
    local l, r = nil, nil
    for _, rr in ipairs(rects) do
        local x = tonumber(rr.tx) or 0
        if l == nil or x < l then l = x end
        if r == nil or x + (rr.w or 0) > r then r = x + (rr.w or 0) end
    end
    local x0, x1 = tonumber(row.x0) or 0, tonumber(row.x1) or 0
    local ok = row.scroll == nil and math.abs(r - x1) <= 1 and l > x0 + 1
    return ok, rects[1].key, "buttons " .. H.num(l) .. ".." .. H.num(r) .. " in the band's " .. H.num(x0) .. ".." .. H.num(x1)
        .. ((row.scroll ~= nil) and " (a ribbon: too many to lay out)" or "") .. ", first " .. tostring(rects[1].key)
end

-- ===================================================================== the icon marks as handed
function H.colorName(mc)
    if not mc then return "none" end
    local M = ZeD.T and ZeD.T.marks
    for _, n in ipairs({ "blue", "red", "gold" }) do
        local x = M and M[n]
        if x and math.abs((x.r or 0) - (mc.r or 0)) < 0.01 and math.abs((x.g or 0) - (mc.g or 0)) < 0.01
            and math.abs((x.b or 0) - (mc.b or 0)) < 0.01 then return n end
    end
    return "another color"
end
-- the first draw of a pixel icon (one of ids) on list c in frame r: { marks, kind, color }
function H.pxOf(r, c, ids)
    for _, e in ipairs((r and c and r.px[c]) or {}) do
        if ids[e.id] then
            local mc = nil
            if e.marks and ZeD.PxIcon and ZeD.PxIcon.markColor then
                local ok, v = pcall(ZeD.PxIcon.markColor, e.id, e.marks, e.kind)
                if ok then mc = v end
            end
            return { id = e.id, marked = e.marks ~= nil, kind = e.kind, color = H.colorName(mc) }
        end
    end
    return nil
end
function H.pxWords(p)
    if not p then return "not drawn" end
    return tostring(p.id) .. (p.marked and (" marked, " .. tostring(p.color)) or " no mark")
end
S.SAME = { same_type = true }
S.VIEW = { view_list = true, view_grid = true }

-- ===================================================================== the crates (vk3_win.lua N.*)
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

-- ===================================================================== the recorder (vk1_pad.lua: nothing is queued)
function H.queueN()
    local n = 0
    if ISTimedActionQueue and ISTimedActionQueue.getTimedActionQueue then
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        if q and q.queue then n = #q.queue end
    end
    return n
end
function H.dryOn()
    if S.dry then return S.dry end
    local d = { acts = {} }
    d.add, d.after = ISTimedActionQueue.add, ISTimedActionQueue.addAfter
    d.wAdd = function(action, ...)
        d.acts[#d.acts + 1] = action
        local ch = (type(action) == "table") and action.character or nil
        if ch ~= nil then return ISTimedActionQueue.getTimedActionQueue(ch) end
        return nil
    end
    d.wAfter = function(prev, action, ...)
        d.acts[#d.acts + 1] = action
        return nil
    end
    ISTimedActionQueue.add, ISTimedActionQueue.addAfter = d.wAdd, d.wAfter
    S.dry = d
    return d
end
function H.dryOff()
    local d = S.dry
    if d == nil then return nil end
    S.dry = nil
    if ISTimedActionQueue.add == d.wAdd then ISTimedActionQueue.add = d.add else S.stuck = true end
    if ISTimedActionQueue.addAfter == d.wAfter then ISTimedActionQueue.addAfter = d.after else S.stuck = true end
    local n = H.queueN()
    if S.was.queue ~= nil and n > S.was.queue then
        pcall(ISTimedActionQueue.clear, S.p)
        S.leaked = (S.leaked or 0) + (n - S.was.queue)
        Q.say("ERR a timed action reached the real queue during a recording: the queue cleared")
    end
    return d
end
function H.actWords(acts)
    local t = {}
    for _, a in ipairs(acts or {}) do
        local ty = (type(a) == "table") and tostring(a.Type or "an action") or tostring(a)
        local it = (type(a) == "table") and a.item or nil
        t[#t + 1] = ty .. (it and (" of " .. H.itemName(it)) or "")
    end
    return (#t > 0) and table.concat(t, ", ") or "nothing"
end
-- the recorded moves out of crate c: all of its things moved, every move from c into dest; ok, words
function H.takes(acts, c, dest)
    local got, stray, n = {}, 0, 0
    for _, a in ipairs(acts or {}) do
        if type(a) == "table" and a.item ~= nil and a.srcContainer ~= nil then
            n = n + 1
            if a.srcContainer == c.inv and a.destContainer == dest and dest ~= nil then got[a.item] = true else stray = stray + 1 end
        end
    end
    local all = #c.items > 0
    for _, it in ipairs(c.items) do if not got[it] then all = false end end
    return all and stray == 0, n .. " moves, " .. stray .. " not from this crate into the bag, every thing of the crate moved " .. tostring(all)
end

-- ===================================================================== the pad's focus
function H.zoneEls(w, zn)
    for _, z in ipairs((w and w._focusRing) or {}) do
        if z.zone == zn then return z.elements or {} end
    end
    return {}
end
function H.rows(w, zn)
    local out = {}
    for _, e in ipairs(H.zoneEls(w, zn)) do
        if e.item ~= nil and not e.offscreen and not e.isViewToggle then out[#out + 1] = e end
    end
    table.sort(out, function(a, b) return (a.y or 0) < (b.y or 0) end)
    return out
end
function H.listTop(w, zn)
    local best = nil
    for _, e in ipairs(H.zoneEls(w, zn)) do
        if not e.isViewToggle and not e.offscreen and (e.item ~= nil or e.isCatHead or e.isStackHead) then
            if best == nil or (e.y or 0) < (best.y or 0) then best = e end
        end
    end
    return best
end
function H.focusNow()
    local F = S.F
    local w = F.getFocusedWindow(S.pn)
    local z = w and F.getFocusedZone(w) or nil
    local el = w and F.getFocusedElement(w) or nil
    return w, (z and z.zone) or nil, el
end
function H.elName(el)
    if not el then return "no stop" end
    return tostring(el.id) .. (el.item and (" (" .. H.itemName(el.item) .. ")") or "")
end
function H.focusSay()
    local w, zn, el = H.focusNow()
    local wn = (w == nil) and "no window" or ((w == RT.ww()) and "World" or ((w == RT.cw()) and "Character" or "a window"))
    return wn .. ", zone " .. tostring(zn) .. ", on " .. H.elName(el)
end
function H.isLoot(e) return e ~= nil and type(e.id) == "string" and e.id:sub(1, 13) == "view:lootall:" end
function H.isAll(e) return e ~= nil and type(e.id) == "string" and e.id:sub(1, 9) == "view:all:" end
function H.isTake(zn, e) return zn == "worldCtl" and e ~= nil and e.ccKey == "take" end
function H.step(dir, w)
    RT.padDir(dir, w)
    local _, zn, el = H.focusNow()
    return zn, el
end
-- until cond() holds (asked every drawn frame), for at most ms of real time; then fn(ok)
function H.waitUntil(ms, cond, fn)
    local st = {}
    Q.waitFor(1, math.floor(ms / 3) + 900, function()
        local now = getTimestampMs()
        st.t = st.t or now
        if cond() then st.ok = true; return true end
        return now - st.t >= ms
    end, function() fn(st.ok == true) end)
end

-- ===================================================================== 1: as found, the scene
Q.step(2, function()
    local ready = S.F ~= nil and S.F.focusWhere ~= nil and S.F.claimFocus ~= nil and S.Det ~= nil and S.St ~= nil
        and S.St.lookStyleOption ~= nil and H.opt("baseTheme") ~= nil and S.CT ~= nil and S.IR ~= nil
        and ZeD_CharacterWindow ~= nil and ZeD_WorldWindow ~= nil and ZeD.Atoms ~= nil and ZeD.TM ~= nil and S.p ~= nil
    if not Q.check(ready, "ZeD's windows, focus, Style, theme option, the lists and the input lock are loaded (staging)") then S.dead = true; return end
    S.was.char, S.was.world = H.charOpen(), H.worldOpen()
    S.was.geo.c = S.was.char and H.geo(RT.cw()) or nil
    S.was.geo.w = S.was.world and H.geo(RT.ww()) or nil
    S.was.tab.c = RT.cw() and RT.cw()._activeTab or nil
    S.was.tab.w = RT.ww() and RT.ww()._activeTab or nil
    S.was.style = S.St.lookStyleOption:getValue()
    S.was.theme = H.val("baseTheme")
    S.was.base = ZeD.currentBase
    S.was.mode = H.mode()
    S.was.queue = H.queueN()
    S.was.taken = true
    Q.say("NOTE as found: " .. "Character open " .. tostring(S.was.char) .. " " .. H.gs(S.was.geo.c) .. " on " .. tostring(S.was.tab.c)
        .. ", World open " .. tostring(S.was.world) .. " " .. H.gs(S.was.geo.w) .. " on " .. tostring(S.was.tab.w)
        .. ", Style " .. tostring(S.was.style) .. ", theme " .. tostring(S.was.theme) .. " (" .. tostring(S.was.base) .. "), mode "
        .. tostring(S.was.mode) .. ", lock " .. H.lockFound() .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight())
    H.lock("kbm")
    -- the crates and the things
    local sqA = H.freeSq(nil)
    local sqB = sqA and H.freeSq(sqA) or nil
    S.ca = sqA and H.mkCrate(sqA) or nil
    S.cb = sqB and H.mkCrate(sqB) or nil
    if not (S.ca and S.cb) then
        H.fail("the scene", "two free squares in reach beside him for the crates (" .. tostring(sqA ~= nil) .. ", " .. tostring(sqB ~= nil) .. ")")
        S.dead = true
        return
    end
    H.toCrate(S.ca, "Base.Apple")
    H.toCrate(S.ca, "Base.Nails")
    H.toCrate(S.cb, "Base.Pencil")
    H.toCrate(S.cb, "Base.Pen")
    S.nails = RT.give("Base.Nails")
    S.bag = RT.give("Base.Bag_Schoolbag")
    pcall(function() S.bagInv = S.bag and S.bag:getItemContainer() or nil end)
    if #S.ca.items < 2 or #S.cb.items < 2 or not S.nails or not S.bagInv then
        H.fail("the scene", "the crates' things or his nails and bag could not be made")
        S.dead = true
        return
    end
    H.style(1)
    H.theme(1)
    H.pairOpen()
end)
Q.waitMs(400)
Q.step(1, function()
    if S.dead then return end
    H.pairOpen()
    H.worldOn(S.ca.inv)
    H.charOn(S.p:getInventory())
    if S.IR.padClearMarks then pcall(S.IR.padClearMarks, RT.ww(), nil) end
end)
H.waitUntil(5000, function()
    if S.dead then return true end
    return H.worldShows(S.ca.inv) and H.charShows(S.p:getInventory())
end, function(ok)
    if S.dead then return end
    if not ok then
        H.fail("the scene", "the World window on crate A alone (" .. tostring(H.worldShows(S.ca.inv)) .. ") and the Character window on his inventory ("
            .. tostring(H.charShows(S.p:getInventory())) .. "), Character open " .. tostring(H.charOpen()) .. ", World open " .. tostring(H.worldOpen()))
        S.dead = true
    end
end)
Q.waitMs(600)

-- ===================================================================== 2: Full, Dark: the headings, the band, the marks at rest
Q.step(1, function()
    if S.dead then return end
    H.rest()
    H.recOn()
end)
Q.step(3, function()
    if S.dead then return end
    local r = H.recOff()
    H.fakeOff()
    local okW, wW = H.header("w", r)
    Q.check(okW, "HDR 1: World heading (Full): the icon at the left pad, the name, the weight and count, Pick all, Filter and the view flip at the right end, no Take all (crate A)", wW)
    local okC, wC = H.header("c", r)
    Q.check(okC, "HDR 2: Character heading (Full): the icon at the left pad, the name, the weight and count, the buttons at the right end, no Take all (his inventory)", wC)
    local n, take, same, keys = H.band(H.content("w"))
    local rW, firstW, wordsW = H.bandRight(H.content("w"))
    local rC, _, wordsC = H.bandRight(H.content("c"))
    Q.check(n > 0 and take and firstW == "take" and same and rW and rC,
        "BAND: the World band has Take all first and Same type; the World and Character bands are right-aligned as a dialog's footer",
        n .. " buttons laid out: [" .. keys .. "], a take move " .. tostring(take) .. ", Same type " .. tostring(same)
        .. "; World " .. wordsW .. "; Character " .. wordsC)
    local cw, ww = H.content("c"), H.content("w")
    S.k.mk.rest = { ws = H.pxOf(r, ww, S.SAME), wv = H.pxOf(r, ww, S.VIEW), cs = H.pxOf(r, cw, S.SAME), cv = H.pxOf(r, cw, S.VIEW) }
    -- the World list's pointer on Same type's middle for the next frames (hovered)
    local cc = ww and ww._cc
    local hit = nil
    for _, h in ipairs((cc and cc.hits) or {}) do if h.key == "same" then hit = h end end
    S.k.mk.hit = hit
    if hit then
        H.fake(cw, false)
        H.fake(ww, true, hit.x + math.floor(hit.w / 2), hit.y + math.floor(hit.h / 2))
        H.recOn()
    end
end)
Q.step(3, function()
    if S.dead then return end
    local r = H.recOff()
    H.fakeOff()
    local m = S.k.mk
    local R = m.rest or {}
    local hov = (r and m.hit) and H.pxOf(r, H.content("w"), S.SAME) or nil
    local restOk = R.ws ~= nil and R.ws.marked and R.wv ~= nil and R.wv.marked and R.cs ~= nil and R.cs.marked and R.cv ~= nil and R.cv.marked
    Q.check(restOk and hov ~= nil and not hov.marked,
        "MARK 1: at rest the band's Same type and the heading's view button carry their icon mark in both windows; hovered, Same type draws none",
        "at rest: World Same type " .. H.pxWords(R.ws) .. ", World view button " .. H.pxWords(R.wv) .. ", Character Same type " .. H.pxWords(R.cs)
        .. ", Character view button " .. H.pxWords(R.cv) .. "; the World list's pointer on Same type (" .. tostring(m.hit ~= nil) .. "): " .. H.pxWords(hov))
    Q.check(R.ws ~= nil and R.ws.marked and R.ws.color == "blue" and R.cs ~= nil and R.cs.marked and R.cs.color == "red",
        "MARK 2: Same type's mark is the theme's blue in the World window (Take) and red in the Character window (Put in)",
        "World " .. H.pxWords(R.ws) .. " (kind " .. tostring(R.ws and R.ws.kind) .. "), Character " .. H.pxWords(R.cs) .. " (kind " .. tostring(R.cs and R.cs.kind) .. ")")
end)
H.shot("header_full_dark")

-- ===================================================================== 3: the themes' pictures
Q.step(1, function() if not S.dead then H.theme(2) end end)
Q.waitMs(700)
Q.step(1, function() if not S.dead then Q.say("NOTE theme now " .. tostring(ZeD.currentBase)) end end)
H.shot("header_full_light")
Q.step(1, function() if not S.dead then H.theme(3) end end)
Q.waitMs(700)
Q.step(1, function() if not S.dead then Q.say("NOTE theme now " .. tostring(ZeD.currentBase)) end end)
H.shot("band_hc")
Q.step(1, function() if not S.dead then H.theme(1) end end)
Q.waitMs(500)

-- ===================================================================== 4: Lite
Q.step(1, function()
    if S.dead then return end
    H.style(2)
end)
Q.waitMs(900)
Q.step(1, function()
    if S.dead then return end
    H.rest()
    H.recOn()
end)
Q.step(3, function()
    if S.dead then return end
    local r = H.recOff()
    H.fakeOff()
    local lite = H.lite()
    local okW, wW = H.header("w", r)
    Q.check(lite and okW, "HDR 3: World heading (Lite): the icon at the left pad, the name, the weight and count, the buttons at the right end, no Take all",
        "Lite " .. tostring(lite) .. "; " .. wW)
    local okC, wC = H.header("c", r)
    Q.check(lite and okC, "HDR 4: Character heading (Lite): the icon at the left pad, the name, the weight and count, the buttons at the right end",
        "Lite " .. tostring(lite) .. "; " .. wC)
end)
H.shot("header_lite_dark")
Q.step(1, function() if not S.dead then H.style(1) end end)
Q.waitMs(600)

-- ===================================================================== 4b: NARROW (the name always wins; at 1280x800 the Deck case)
Q.step(1, function()
    if S.dead then return end
    H.charOn(S.bagInv)
    H.worldOn(S.ca.inv)
    S.k.nar.geoC, S.k.nar.geoW = H.geo(RT.cw()), H.geo(RT.ww())
end)
H.waitUntil(4000, function()
    if S.dead then return true end
    return H.charShows(S.bagInv) and H.worldShows(S.ca.inv)
end, function(ok)
    if S.dead then return end
    if not ok then
        H.fail("NARROW", "the school bag alone in the Character window (" .. tostring(H.charShows(S.bagInv)) .. ") and crate A alone in the World window ("
            .. tostring(H.worldShows(S.ca.inv)) .. ")")
        return
    end
    H.narrow()
end)
Q.waitMs(400)
-- (again: the windows set their minimum each frame, a narrower list can lower it once)
Q.step(1, function() if not (S.dead or S.off.NARROW) then H.narrow() end end)
Q.waitMs(600)
function H.narrowRead(style, label, shotName)
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
            "Lite " .. tostring(H.lite()) .. ", screen " .. getCore():getScreenWidth() .. "x" .. getCore():getScreenHeight()
            .. "; World (crate A): " .. wW .. "; Character (school bag): " .. wC)
    end)
    H.shot(shotName)
end
H.narrowRead(1, "(Full)", "narrow_full")
H.narrowRead(2, "(Lite)", "narrow_lite")
Q.step(1, function()
    if S.dead then return end
    H.style(1)
    if S.k.nar.geoC then H.placeBack(RT.cw(), S.k.nar.geoC) end
    if S.k.nar.geoW then H.placeBack(RT.ww(), S.k.nar.geoW) end
end)
Q.waitMs(400)
Q.step(1, function() if not S.dead then H.baseBack() end end)
Q.waitMs(300)

-- ===================================================================== 5: the pad on the World window (Full)
Q.step(1, function()
    if S.dead then return end
    H.lock("gamepad")
end)
H.waitUntil(3000, function() return S.dead or H.mode() == "gamepad" end, function(ok)
    if S.dead then return end
    if not ok then H.fail("PAD", "ZeD's input mode did not take the lock to the controller (" .. tostring(H.mode()) .. ")"); return end
    H.worldOn(S.ca.inv)
    if S.IR.padClearMarks then pcall(S.IR.padClearMarks, RT.ww(), nil) end
    S.F.claimFocus(RT.ww())
    S.claimed = true
end)
H.waitUntil(4000, function()
    if S.dead or S.off.PAD then return true end
    local ww = RT.ww()
    return #H.rows(ww, "worldMainInv") >= 2 and #H.zoneEls(ww, "worldCtl") > 0 and H.worldShows(S.ca.inv)
end, function(ok)
    if S.dead or S.off.PAD then return end
    local ww = RT.ww()
    if not ok then
        H.fail("PAD", "the World window's list (" .. #H.rows(ww, "worldMainInv") .. " rows) and band (" .. #H.zoneEls(ww, "worldCtl") .. " stops) are not in the pad's ring")
        return
    end
    local F, P = S.F, S.k.pad
    F.claimFocus(ww)
    -- PAD 1: Up from the top stop (the heading's Pick all), Down from the last row (the band's Take all)
    local top = H.listTop(ww, "worldMainInv")
    local t = top and F.focusWhere(ww, "worldMainInv", function(x) return x == top end) or nil
    if t then
        local _, e = H.step("up", ww)
        P.up, P.upSay = e, H.focusSay()
    end
    local rows = H.rows(ww, "worldMainInv")
    local last = rows[#rows]
    local l = last and F.focusWhere(ww, "worldMainInv", function(x) return x == last end) or nil
    if l then
        local zd, e = H.step("down", ww)
        P.dn, P.dnZ, P.dnSay = e, zd, H.focusSay()
    end
    Q.check(H.isAll(P.up) and H.isTake(P.dnZ, P.dn),
        "PAD 1: pad Up from the list's top stop lands on the heading's Pick all (view:all), Down from its last row on the band's Take all (worldCtl:take)",
        "Up from " .. H.elName(t) .. ": " .. tostring(P.upSay) .. "; Down from " .. H.elName(l) .. ": " .. tostring(P.dnSay)
        .. ", its band key " .. tostring(P.dn and P.dn.ccKey))
    -- PAD 2: from the heading's Pick all, Up to the title bar, Up wraps to the band, Right walks it
    local la = F.focusWhere(ww, "worldMainInv", function(x) return H.isAll(x) end)
    local path, first, reached, walk = {}, false, false, false
    if la then
        local z1 = H.step("up", ww)
        path[#path + 1] = H.focusSay()
        first = z1 ~= nil and z1 ~= "worldMainInv" and z1 ~= "worldCtl"
        local n = 0
        while first and not reached and n < 3 do
            n = n + 1
            local zi = H.step("up", ww)
            path[#path + 1] = H.focusSay()
            if zi == "worldCtl" then reached = true elseif zi == "worldMainInv" then n = 3 end
        end
        if reached then
            local _, _, b1 = H.focusNow()
            local zr, er = H.step("right", ww)
            path[#path + 1] = "Right: " .. H.focusSay()
            walk = zr == "worldCtl" and er ~= nil and er ~= b1
        end
    end
    Q.check(la ~= nil and first and reached and walk,
        "PAD 2: from the heading's Pick all, Up goes to the title bar, Up again wraps to the footer band, and Right walks the band",
        "from " .. H.elName(la) .. ": " .. table.concat(path, " | "))
    -- PAD 3: the band's Down and Up
    rows = H.rows(ww, "worldMainInv")
    local b = F.focusWhere(ww, "worldCtl", nil)
    local dz, de = nil, nil
    if b then dz, de = H.step("down", ww) end
    P.dSay = H.focusSay()
    local b2 = F.focusWhere(ww, "worldCtl", nil)
    local uz, ue = nil, nil
    if b2 then uz, ue = H.step("up", ww) end
    P.uSay = H.focusSay()
    local fr, lr = rows[1], rows[#rows]
    Q.check(b ~= nil and fr ~= nil and de ~= nil and de.item ~= nil and de.item == fr.item and ue ~= nil and ue.item ~= nil and ue.item == lr.item,
        "PAD 3: from the footer band, Down lands on the list's first row on show and Up on its last row on show",
        "Down from " .. H.elName(b) .. ": " .. tostring(P.dSay) .. " (first row " .. H.elName(fr) .. "); Up from the band: " .. tostring(P.uSay)
        .. " (last row " .. H.elName(lr) .. ")")
    -- NOTE: the Character window's band (listgrid: the loop holds in both windows)
    local cw = RT.cw()
    if cw then
        F.claimFocus(cw)
        local cb = F.focusWhere(cw, "charCtl", nil)
        if cb then
            H.step("down", cw)
            Q.say("NOTE the Character window's band, Down from " .. H.elName(cb) .. ": " .. H.focusSay() .. " (listgrid: the list's first row on show, the loop in both windows)")
        else
            Q.say("NOTE the Character window's band has no pad stop here")
        end
    end
end)
Q.step(1, function()
    if S.claimed and S.F and S.F.releaseFocus then pcall(S.F.releaseFocus, S.pn) end
    S.claimed = nil
    if not S.dead then H.lock("kbm") end
end)
H.waitUntil(3000, function() return S.dead or H.mode() == "kbm" end, function() end)

-- ===================================================================== 6: two Loot columns, the bag on show
Q.step(1, function()
    if S.dead then return end
    H.worldOn(S.ca.inv)
end)
H.waitUntil(4000, function()
    if S.dead then return true end
    local ci = ZeD_CharacterWindow.containerIndex and ZeD_CharacterWindow.containerIndex(S.pn, S.bagInv) or nil
    return H.worldShows(S.ca.inv) and ci ~= nil
end, function(ok)
    if S.dead then return end
    if not ok then H.fail("COL", "crate A alone in the World window (" .. tostring(H.worldShows(S.ca.inv)) .. ") and the school bag on the Character window's strip"); return end
    if not H.charOn(S.bagInv) then H.fail("COL", "the school bag could not be shown alone in the Character window"); return end
    local okT = pcall(ZeD_WorldWindow.toggleColumn, S.cb.inv, S.pn)
    if not okT then H.fail("COL", "ZeD_WorldWindow.toggleColumn threw for crate B") end
end)
H.waitUntil(5000, function()
    if S.dead or S.off.COL then return true end
    local c = H.content("w")
    local cols = c and c._colStates
    if not (cols and #cols == 2 and H.charShows(S.bagInv)) then return false end
    for _, cs in ipairs(cols) do
        if not (cs.inventory and #(cs.viewToggleRects or {}) > 0) then return false end
    end
    return true
end, function(ok)
    if S.dead or S.off.COL then return end
    if not ok then
        local c = H.content("w")
        H.fail("COL", "two Loot columns (crate A and B) with their headings drawn: columns " .. #((c and c._colStates) or {})
            .. ", the bag alone in the Character window " .. tostring(H.charShows(S.bagInv)))
    end
end)
Q.waitMs(600)
H.shot("columns_two")
Q.step(1, function()
    if S.dead or S.off.COL then return end
    local c = H.content("w")
    local words, allOk, seen = {}, true, 0
    local dest0 = S.CT.otherInventory and S.CT.otherInventory(c) or nil
    -- (listgrid: the column's Take all is in its own foot, the band's height along the column's bottom, at the
    -- column's right end, where the heading's buttons end too; no Take all in the heading)
    local bandH = 0
    pcall(function() bandH = ZeD.Molecules.bandH() end)
    local panH = c and c:getHeight() or 0
    for i, cs in ipairs((c and c._colStates) or {}) do
        local crate = (cs.inventory == S.ca.inv and S.ca) or ((cs.inventory == S.cb.inv) and S.cb) or nil
        local hit, nLoot, headR = nil, 0, nil
        for _, t in ipairs(cs.viewToggleRects or {}) do
            if t.view == "lootall" then hit = t; nLoot = nLoot + 1 end
            if S.HEAD_VIEWS[t.view] then headR = math.max(headR or (t.x + t.w), t.x + t.w) end
        end
        local w = "column " .. i .. " (" .. ((crate == S.ca) and "crate A" or ((crate == S.cb) and "crate B" or "?")) .. "): "
        if crate then seen = seen + 1 end
        local inFoot = hit ~= nil and bandH > 0 and hit.y >= panH - bandH - 1 and hit.y + hit.h <= panH + 1
            and headR ~= nil and math.abs((hit.x + hit.w) - headR) <= 2 and nLoot == 1
        if hit then
            w = w .. "Take all at " .. H.num(hit.x) .. "," .. H.num(hit.y) .. " " .. H.num(hit.w) .. "x" .. H.num(hit.h)
                .. " (the foot " .. H.num(panH - bandH) .. ".." .. H.num(panH) .. ", the heading's buttons end " .. H.num(headR)
                .. ", " .. nLoot .. " Take all rects) in its foot " .. tostring(inFoot) .. "; "
        end
        if not (crate and hit and inFoot) then
            allOk = false
            words[#words + 1] = w .. (hit and "not in the column's foot" or "no Take all in its foot")
        else
            local d = H.dryOn()
            local lx, ly = hit.x + math.floor(hit.w / 2), hit.y + math.floor(hit.h / 2)
            local okP, err = H.atPointer(c:getAbsoluteX() + lx, c:getAbsoluteY() + ly, function() c:onMouseDown(lx, ly) end)
            H.dryOff()
            local okT, tw = H.takes(d.acts, crate, S.bagInv)
            if not (okP and okT) then allOk = false end
            words[#words + 1] = w .. "pressed " .. tostring(hit.id) .. (okP and "" or (" (threw: " .. tostring(err) .. ")")) .. ", recorded "
                .. H.actWords(d.acts) .. "; " .. tw
        end
    end
    Q.check(allOk and seen == 2, "COL: each Loot column has its own Take all in its foot (not its heading), taking that column's crate into the Character window's bag on show",
        table.concat(words, " | ") .. "; the bag on show is the band's destination " .. tostring(dest0 ~= nil and dest0 == S.bagInv)
        .. " (moves recorded, nothing moved)")
end)

-- ===================================================================== 7: put back
Q.mark()
Q.step(1, function()
    H.dryOff()
    H.recOff()
    H.fakeOff()
    H.cursor(false)
    if S.claimed and S.F and S.F.releaseFocus then pcall(S.F.releaseFocus, S.pn) end
    S.claimed = nil
    H.closeCols()
    if RT.cw() and H.charOpen() then H.charOn(S.p:getInventory()) end
    if S.was.taken then
        H.style(S.was.style)
        if S.was.theme ~= nil then H.theme(S.was.theme) end
    end
    H.modeBack()
    H.rmCrate(S.ca)
    H.rmCrate(S.cb)
    RT.takeBack()
    local ww = RT.ww()
    if ww then ww._containerTimer = 30 end
    if S.was.taken and H.queueN() > (S.was.queue or 0) and (S.was.queue or 0) == 0 then
        S.queued = H.queueN()
        pcall(ISTimedActionQueue.clear, S.p)
    end
end)
Q.waitMs(400)
Q.step(1, function()
    H.modeFree()
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
Q.step(1, function()
    if not S.was.taken then return end
    local cw, ww = RT.cw(), RT.ww()
    local why = {}
    if H.charOpen() ~= S.was.char or H.worldOpen() ~= S.was.world then why[#why + 1] = "windows open " .. tostring(H.charOpen()) .. "/" .. tostring(H.worldOpen()) end
    if S.was.char and not H.sameGeo(H.geo(cw), S.was.geo.c) then why[#why + 1] = "Character at " .. H.gs(H.geo(cw)) end
    if S.was.world and not H.sameGeo(H.geo(ww), S.was.geo.w) then why[#why + 1] = "World at " .. H.gs(H.geo(ww)) end
    if S.St.lookStyleOption:getValue() ~= S.was.style then why[#why + 1] = "Style " .. tostring(S.St.lookStyleOption:getValue()) end
    if S.was.theme ~= nil and H.val("baseTheme") ~= S.was.theme then why[#why + 1] = "theme " .. tostring(H.val("baseTheme")) end
    if H.crateUp(S.ca) or H.crateUp(S.cb) then why[#why + 1] = "a crate still stands" end
    local kept = false
    pcall(function() kept = S.nails ~= nil and S.p:getInventory():containsID(S.nails:getID()) end)
    if kept then why[#why + 1] = "the given nails still in his inventory" end
    if S.stuck then why[#why + 1] = "a watched or faked function was replaced by someone else meanwhile" end
    if S.leaked then why[#why + 1] = S.leaked .. " timed actions reached the real queue (cleared)" end
    if S.queued then why[#why + 1] = S.queued .. " timed actions queued at the end (cleared)" end
    if S.locked then why[#why + 1] = "the input lock still held" end
    Q.check(#why == 0, "put back: windows, Style, theme, the input lock, the crates and the given things as found; nothing queued or left watched",
        (#why == 0) and ("Character " .. H.gs(H.geo(cw)) .. ", World " .. H.gs(H.geo(ww)) .. ", theme " .. tostring(ZeD.currentBase) .. ", mode " .. tostring(H.mode()))
        or table.concat(why, "; "))
end)

Q.start()
