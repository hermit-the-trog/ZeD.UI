-- ZeDUI/tools/qa/gallery_nov1_story.lua  (Nov 1 2026, QA)
-- The Workshop gallery retake (workshop/gallery/REVIEW_20261101.md, "Retakes" 5, 6 and the optional 02), the Fossoil
-- story's part: after gallery_story_stage.lua (needs STORY.ready), before gallery_story_teardown.lua. Same screenshot
-- names as gallery_story_shots.lua / gallery_story_traits.lua, so the gallery's shots.json keeps working. Both
-- windows as tall as the screen allows (12u top and bottom) for the tab pictures; the default look but beat 08.
--   02  story_02a_journal_entry    page 3: the Journal tab with its Page pop-up open (Journal, Notebooks, Papers,
--                                  Recipes ... listed), the story's entry under it
--   03  story_03_route_map         page 4: the Maps tab between the flyer's pin and the store, the map key open, the
--                                  red note "fossoil. my old pumps" (the stage's seed) by the pin, the pin's card up
--       story_03b_route_note       the same view with the pointer parked (no card over the note: the inset's source)
--   08  story_08b_footer_light     page 9: Light and Blue chosen FIRST from the window menus (no picture), then the
--       story_08c_footer_blue      World window's menu down again: Theme open with Light checked (08b), Accent open
--       story_08d_open_light_blue  with Blue checked (08c), both shut without a pick; then the pair in Light + Blue
--   00  story_00a_identity_tall    page 2 (optional): the tall Character window on Identity with a hair style picked,
--                                  so Hair and beard's After box shows it (nothing is cut)
-- NOV1_STORY_ONLY = { ["02"] = true, ... } above this header takes only those beats.
-- Every capture logs the windows ("box <name> char|world x0,y0-x1,y1", the window box too) and the map's note and pin
-- on the screen for the crops. Puts back: heights, the Page pop-up, the map key, hover and view, the theme options
-- (Theme, Accent, both window accents) as they were, the hair pick, kills and the crowbar count.
-- "ZEDQA n1s ..." ending "ZEDQA n1s DONE".
local ST = STORY
if not (ST and ST.ready and ST.newSeq) then print("ZEDQA n1s ERR run gallery_story_stage.lua first"); print("ZEDQA n1s DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA n1s ERR ZeD is not loaded"); print("ZEDQA n1s DONE"); return end
local S = ST.newSeq("n1s", 900000)
local say = S.say
local p, pn, core = ST.p, ST.pn, ST.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Z = { lock = nil, was = {} }
local P = ST.P
function Z.want(k) return (not NOV1_STORY_ONLY) or NOV1_STORY_ONLY[k] == true end
Z.flyerId = string.lower(ST.site.flyer)
Z.lookB = (GAL_LOOK and GAL_LOOK[1]) or "dark"
Z.lookA = (GAL_LOOK and GAL_LOOK[2]) or "orange"

-- ---------------------------------------------------------------------------
-- windows (gallery_story_shots.lua's, the tops held where Z.tall puts them)
-- ---------------------------------------------------------------------------
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end
function Z.closePair()
    if CWm.isOpen() and WWm.isOpen() then CWm.toggleBothPaired(pn)
    else
        if CWm.isOpen() then CWm.toggle(pn) end
        if WWm.isOpen() then WWm.close() end
    end
end
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) or w._rolled then return false end
    if not Z.lock then
        local gap = ZeD.T.px(8)
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        Z.lock = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, y = c:getY() }
    end
    c._anchorRightEdge = Z.lock.right
    c:setX(Z.lock.right - c:getWidth()); w:setX(Z.lock.left)
    c:setY(Z.lock.y); w:setY(Z.lock.y)
    return true
end
function Z.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then
        if WWm.isOpen() then WWm.close() end
        if CWm.isOpen() then CWm.toggle(pn) end
        CWm.toggleBothPaired(pn)
    end
    Z.place()
end
function Z.tall()
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return end
    if not Z.was.size then Z.was.size = { c:getHeight(), w:getHeight() } end
    local m = ZeD.T.px(12)
    local h = core:getScreenHeight() - 2 * m
    Z.lock = nil
    for _, win in ipairs({ c, w }) do
        win:setY(m); win:setHeight(h)
        pcall(function() win:onResize() end)
    end
    Z.place()
end
function Z.untall()
    local c, w = Z.CW(), Z.WW()
    local s = Z.was.size
    if not s then return end
    if c then c:setHeight(s[1]); pcall(function() c:onResize() end) end
    if w then w:setHeight(s[2]); pcall(function() w:onResize() end) end
    Z.was.size, Z.lock = nil, nil
end
function Z.goTab(win, strip, tab)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. tab then
            if win._activeTab ~= tab then strip:onMouseDown(z.x + 2, z.y + 2) end
            return true
        end
    end
    return false
end
function Z.charTab(id) local w = Z.CW(); return (w and Z.goTab(w, w._tabStripPanel, id)) and true or false end
function Z.worldTab(id) local w = Z.WW(); return (w and Z.goTab(w, w._actionTabStrip, id)) and true or false end
function Z.boxRect(win)
    local b = win and win.windowBoxRect and win:windowBoxRect()
    if not b then return nil end
    local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
    return math.floor(ax + b.x), math.floor(ay + b.y), math.floor(ax + b.x + b.w), math.floor(ay + b.y + b.h)
end
function Z.box(tag, win)
    if win and win:isVisible() then
        say(string.format("box %s %d,%d-%d,%d", tag, math.floor(win:getX()), math.floor(win:getY()),
            math.floor(win:getX() + win:getWidth()), math.floor(win:getY() + win:getHeight())))
        local x0, y0, x1, y1 = Z.boxRect(win)
        if x0 then say(string.format("box %s windowbox %d,%d-%d,%d", tag, x0, y0, x1, y1)) end
        local dp = win._drawerPanel
        if dp then
            say(string.format("box %s drawer %d,%d-%d,%d", tag, math.floor(dp:getAbsoluteX()), math.floor(dp:getAbsoluteY()),
                math.floor(dp:getAbsoluteX() + dp:getWidth()), math.floor(dp:getAbsoluteY() + dp:getHeight())))
        end
    end
end
function Z.shot(name)
    S.shot(name)
    if CWm.isOpen() then Z.box(name .. " char", Z.CW()) end
    if WWm.isOpen() then Z.box(name .. " world", Z.WW()) end
end
-- the extent of a list of zones ({x, y, w, h}) as a string, nil when there are none (a pop-up's rows)
function Z.zonesSig(zs)
    if not (zs and #zs > 0) then return nil end
    local x0, y0, x1, y1 = 1e9, 1e9, -1e9, -1e9
    for _, z in ipairs(zs) do
        x0, y0 = math.min(x0, z.x), math.min(y0, z.y)
        x1, y1 = math.max(x1, z.x + z.w), math.max(y1, z.y + z.h)
    end
    return string.format("%d rows %d,%d %dx%d", #zs, math.floor(x0), math.floor(y0), math.floor(x1 - x0), math.floor(y1 - y0))
end
function Z.pointAt(x, y)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(x), math.floor(y)) end) end
end
function Z.hoverBox(win)
    local x0, y0, x1, y1 = Z.boxRect(win)
    if x0 then Z.pointAt((x0 + x1) / 2, (y0 + y1) / 2) end
end
function Z.leafName(kind, key)
    local Sx = ZeD.Settings
    local keys, labels = Sx.baseKeys, Sx.baseLabels
    if kind == "accent" then keys, labels = Sx.accentKeys, Sx.accentLabels end
    for i, k in ipairs(keys or {}) do
        if k == key then return ZeD.tr(labels[i]) end
    end
    return tostring(key)
end
function Z.menu()
    local m = ZeD.WindowMenu and ZeD.WindowMenu.current
    return (m and m._ctx and m._ctx.open) and m or nil
end
function Z.menuRow(li, name)
    local m = Z.menu()
    local lv = m and m._levels and m._levels[li]
    if not lv then return nil end
    for ri, r in ipairs(lv.rows) do
        if r.def and r.def.name == name then
            for _, zn in ipairs(m._hitZones or {}) do
                if zn.id == "row:" .. li .. ":" .. ri then return zn end
            end
        end
    end
    return nil
end
function Z.menuHover(li, name)
    local zn = Z.menuRow(li, name)
    if zn then Z.pointAt(zn.x + zn.w / 2, zn.y + zn.h / 2) end
    return zn ~= nil
end
function Z.menuClick(li, name)
    local m, zn = Z.menu(), Z.menuRow(li, name)
    if not (m and zn) then return false end
    m:onMouseUp(math.floor(zn.x + zn.w / 2), math.floor(zn.y + zn.h / 2))
    return true
end
-- the menu pulled down, the parent row opened, the pointer on the choice; then either a click on the choice
-- (pick = true: it runs and the menu closes) or a shot and the menu shut without a pick (gallery_story_shots.lua's
-- Z.menuPick, split in two)
function Z.menuOpen(getWin, parent, choice, tag)
    S.step(2, function()
        local w = getWin()
        if not w then S.err(tag, "no window to pull the menu from"); return end
        Z.hoverBox(w)
        w:openWindowMenu()
    end)
    S.poll(2, 180, function() return Z.menuRow(1, parent) ~= nil end,
        function() S.err(tag, "the menu did not draw its " .. parent .. " row") end)
    S.step(2, function() Z.menuClick(1, parent) end)
    S.poll(2, 180, function() return Z.menuRow(2, choice) ~= nil end,
        function() S.err(tag, "the " .. parent .. " submenu did not draw " .. choice) end)
    S.step(2, function() Z.menuHover(2, choice) end)
end
function Z.menuPick(getWin, parent, choice, tag)
    Z.menuOpen(getWin, parent, choice, tag)
    S.step(20, function()
        local ok = Z.menuClick(2, choice)
        say(string.format("%s: %s picked %s | menu closed %s", tag, choice, tostring(ok), tostring(Z.menu() == nil)))
    end)
    S.step(20, function() local m = Z.menu(); if m then pcall(function() m:close() end) end end)
end
function Z.menuShot(getWin, parent, choice, name)
    Z.menuOpen(getWin, parent, choice, name)
    S.step(30, function()
        say(string.format("%s: theme %s accent %s | char accent %s world accent %s", name, tostring(ZeD.currentBase),
            tostring(ZeD.currentAccent), tostring(Z.CW() and Z.CW()._accentKey), tostring(Z.WW() and Z.WW()._accentKey)))
        Z.shot(name)
    end)
    S.step(2, function()
        local m = Z.menu()
        if m then pcall(function() m:close() end) end
        ST.parkMouse()
    end)
    S.step(20, function() end)
end
-- the theme options the window menus save (put back at the end, as gallery_t14_look.lua does)
Z.OPT_IDS = { "baseTheme", "accentColor", "textSize", "charAccent", "worldAccent" }
function Z.opts() return PZAPI and PZAPI.ModOptions and PZAPI.ModOptions:getOptions("ZeD_UI") end
function Z.saveOpts()
    local o = Z.opts()
    Z.was.opts = {}
    for _, id in ipairs(Z.OPT_IDS) do
        local x = o and o:getOption(id)
        if x then Z.was.opts[id] = x:getValue() end
    end
end
function Z.putOpts()
    local o = Z.opts()
    if not (o and Z.was.opts) then return end
    for id, v in pairs(Z.was.opts) do
        local x = o:getOption(id)
        if x then pcall(function() x:setValue(v) end) end
    end
    pcall(function() ZeD.Settings.reapplyFromOptions() end)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
    pcall(function() PZAPI.ModOptions:save() end)
end
function Z.theme(base, accent)
    ZeD.applyTheme(base, accent, ZeD.currentSize)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end

-- ===========================================================================
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    ST.cleanLook()
    ST.parkMouse()
    ST.day(10.0)
    Z.saveOpts()
    Z.theme(Z.lookB, Z.lookA)
    say("theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " | options kept: "
        .. tostring(Z.was.opts and Z.was.opts.baseTheme) .. " " .. tostring(Z.was.opts and Z.was.opts.accentColor))
    Z.closePair()
end)
S.zoomTo(1.0)

-- ---- 00 (optional) Identity, tall, a hair style picked -----------------------------------
if Z.want("00") then
    S.step(2, function()
        ST.tpSq(P.smoke); ST.face("SE")
        Z.was.kills, Z.was.fav = p:getZombieKills(), p:getModData()["Fav:Crowbar"]
        p:setZombieKills(23)
        p:getModData()["Fav:Crowbar"] = 23
        Z.openPair()
    end)
    S.poll(10, 120, function() return Z.charTab("identity") end)
    -- (gallery_story_traits.lua's tall window: fixed x 902, 86 per cent of the screen)
    S.step(120, function()
        local c, w = Z.CW(), Z.WW()
        Z.was.idH = c:getHeight()
        c:setX(902); c:setY(0)
        w:setX(c:getX() + c:getWidth() + ZeD.T.px(8)); w:setY(0)
        c:setHeight(math.floor(core:getScreenHeight() * 0.86))
    end)
    S.step(40, function()
        local c = Z.CW()
        local st = c and c._hb
        local cur = nil
        pcall(function() cur = p:getHumanVisual():getHairModel() end)
        local pick = nil
        for _, r in ipairs(st and st.rows or {}) do
            if not pick and r.key and r.ok and tostring(r.key):find(tostring(cur), 1, true) == nil then pick = r end
        end
        for _, r in ipairs(st and st.rows or {}) do if not pick and r.key then pick = r end end
        if st and pick then st.sel = pick.key end
        say(string.format("identity: hair rows %d | now %s | picked %s (ok %s)", st and #(st.rows or {}) or 0, tostring(cur),
            tostring(pick and pick.key), tostring(pick and pick.ok)))
    end)
    S.step(90, function()
        local c, w = Z.CW(), Z.WW()
        c:setX(902); w:setX(c:getX() + c:getWidth() + ZeD.T.px(8))
        ST.parkMouse()
    end)
    S.step(30, function()
        local st = Z.CW() and Z.CW()._hb
        say("identity: After shows " .. tostring(st and st.sel))
        Z.shot("story_00a_identity_tall")
    end)
    S.step(2, function()
        local c = Z.CW()
        if c and c._hb then c._hb.sel = nil end
        if c and Z.was.idH then c:setHeight(Z.was.idH) end
        Z.charTab("loot")
        p:setZombieKills(Z.was.kills)
        p:getModData()["Fav:Crowbar"] = Z.was.fav
        Z.closePair()
        Z.lock = nil
        say("identity put back: hair pick, height, kills " .. p:getZombieKills())
    end)
    S.step(30, function() end)
end

-- ---- 02 the plan: the Journal tab, its title and its pages' tab strip ---------------------
-- (Nov 12 2026, punch list 175h: the "Page: Journal" pop-up is gone; the pages are a tab strip under the
-- tab's title, so the spread shows the strip with the Journal page open)
if Z.want("02") then
    S.step(10, function() ST.gt:setTimeOfDay(10.25); Z.openPair() end)
    S.poll(10, 120, function() return Z.charTab("journal") end)
    S.step(10, function()
        local w = Z.CW()
        if w._journalSubTab ~= 1 then
            local ok = pcall(function() ZeD.JournalTab.setPage(w, 1) end)
            if not ok then w._journalSubTab = 1 end
        end
        w._journalCache = nil
        Z.tall()
    end)
    S.step(60, function() Z.tall(); ST.parkMouse() end)
    S.step(2, function()
        local w = Z.CW()
        w._journalTabZones = nil
        Z.jr = nil
    end)
    -- the strip's tabs must stand still for 20 frames running, and 30 frames at least must have passed, before the shot
    S.poll(1, 600, function()
        local w = Z.CW()
        local s = w and Z.zonesSig(w._journalTabZones) or nil
        Z.jr = Z.jr or { same = 0, f = 0 }
        local R = Z.jr
        R.f = R.f + 1
        if s ~= nil and s == R.last then R.same = R.same + 1 else R.same, R.last = 0, s end
        return s ~= nil and R.same >= 20 and R.f >= 30
    end, function() say("note: the Journal's tab strip did not settle (" .. tostring(Z.jr and Z.jr.last) .. ")") end)
    S.step(2, function()
        local w = Z.CW()
        local zs = w._journalTabZones or {}
        if #zs == 0 then S.err("story_02a_journal_entry", "no tab strip under the Journal's title") end
        local ids = {}
        for _, z in ipairs(zs) do ids[#ids + 1] = tostring(z.page) end
        say("journal: page " .. tostring(w._journalSubTab) .. " open, " .. #zs .. " tabs (" .. table.concat(ids, " ")
            .. ") | " .. tostring(Z.zonesSig(zs)))
        Z.shot("story_02a_journal_entry")
    end)
    S.step(2, function() Z.charTab("loot") end)
    S.step(20, function() end)
end

-- ---- 03 the route: the Maps tab, the note by the pin ---------------------------------------
if Z.want("03") then
    local M3 = { zoom = STORY_MAPZOOM or 14, tries = 0 }
    S.step(10, function() ST.gt:setTimeOfDay(10.5); Z.openPair() end)
    S.poll(10, 120, function() return Z.worldTab("maps") end)
    S.step(10, function() Z.tall() end)
    S.step(40, function()
        local w = Z.WW()
        Z.tall()
        pcall(function() ZeD.MapsTab.setStyle(w, "survey") end)
        M3.keyWas = w._mapKeyOpen
        w._mapKeyOpen = true
        local loc = PrintMediaDefinitions.MiscDetails[Z.flyerId].location1[1]
        M3.pin = { (loc.x1 + loc.x2) / 2, (loc.y1 + loc.y2) / 2 }
        M3.mid = { (M3.pin[1] + P.centre[1]) / 2, (M3.pin[2] + P.centre[2]) / 2 }
        -- the stage's note (gallery_story_stage.lua ST.seed: red, six squares north of the store's middle); one of
        -- this script's own by the pin when it is missing (taken away after)
        local MN = ZeD.MapNotes
        M3.note = (MN and MN.findByText and MN.findByText(ST.NOTE)) or (ST.R and ST.R.note)
        if not M3.note and MN then
            M3.note = MN.addNote(ST.NOTE, M3.pin[1] + 0.5, M3.pin[2] - 6, 4)
            M3.added = M3.note
        end
        say(string.format("map: flyer place %d,%d | the store %d,%d | note %s (%s)", math.floor(M3.pin[1]), math.floor(M3.pin[2]),
            P.centre[1], P.centre[2], tostring(M3.note ~= nil), M3.added and "added by this script" or "the stage's"))
    end)
    -- centred between the flyer's place and the store; out a level at a time until the pin is on the map
    S.poll(10, 1200, function()
        local mp = Z.WW()._worldMapPanel
        if not mp then return false end
        if not M3.set then
            pcall(function() mp.mapAPI:centerOn(M3.mid[1], M3.mid[2]); mp:_zoomTo(M3.zoom) end)
            M3.set, M3.t = true, S.tick
            return false
        end
        if S.tick - M3.t < 90 then return false end
        for _, q in ipairs(mp._flyerPins or {}) do
            if q.id == Z.flyerId then M3.q = q; return true end
        end
        M3.tries = M3.tries + 1
        if M3.tries > 4 then return true end
        M3.zoom = M3.zoom - 1
        M3.set = false
        return false
    end)
    function M3.where()
        local mp = Z.WW()._worldMapPanel
        if not mp then return end
        local ax, ay = mp:getAbsoluteX(), mp:getAbsoluteY()
        local nx, ny = nil, nil
        pcall(function()
            local wx, wy = M3.note:getWorldX(), M3.note:getWorldY()
            nx, ny = mp.mapAPI:worldToUIX(wx, wy), mp.mapAPI:worldToUIY(wx, wy)
        end)
        local q = M3.q
        say(string.format("map on screen: panel %d,%d %dx%d | pin %s | note %s | zoom %s",
            math.floor(ax), math.floor(ay), math.floor(mp:getWidth()), math.floor(mp:getHeight()),
            q and string.format("%d,%d %dx%d", math.floor(ax + q.x), math.floor(ay + q.y), math.floor(q.w), math.floor(q.h)) or "none",
            nx and string.format("%d,%d", math.floor(ax + nx), math.floor(ay + ny)) or "?", tostring(M3.zoom)))
    end
    S.step(2, function()
        local mp = Z.WW()._worldMapPanel
        local q = M3.q
        say("map zoom " .. M3.zoom .. " | pin " .. tostring(q ~= nil) .. " | key open " .. tostring(Z.WW()._mapKeyOpen))
        if q then
            local fx, fy = q.x + math.floor(q.w / 2), q.y + math.floor(q.h / 2)
            mp.isMouseOver = function() return true end
            mp.getMouseX = function() return fx end
            mp.getMouseY = function() return fy end
        end
        Z.place()
    end)
    S.step(40, function()
        local mp = Z.WW()._worldMapPanel
        say("hover card on " .. tostring(mp and mp._flyerHover and mp._flyerHover.id))
        M3.where()
        Z.shot("story_03_route_map")
    end)
    S.step(2, function()
        local mp = Z.WW()._worldMapPanel
        if mp then mp.isMouseOver, mp.getMouseX, mp.getMouseY = nil, nil, nil end
        ST.parkMouse()
    end)
    S.step(40, function() M3.where(); Z.shot("story_03b_route_note") end)
    S.step(2, function()
        local w = Z.WW()
        if w then w._mapKeyOpen = M3.keyWas end
        if M3.added and ZeD.MapNotes then pcall(function() ZeD.MapNotes.remove(M3.added) end) end
        Z.worldTab("loot")
        say("map put back: key " .. tostring(M3.keyWas) .. ", hover hooks off" .. (M3.added and ", the added note removed" or ""))
    end)
    S.step(20, function() end)
end

-- ---- 08 open for business: Light and Blue chosen, then the menus with them checked -----------
if Z.want("08") then
    local themeRow, accentRow = ZeD.tr("UI_ZeD_WinMenu_Theme"), ZeD.tr("UI_ZeD_WinMenu_Accent")
    S.step(10, function()
        ST.gt:setTimeOfDay(14.0)
        ST.tpSq(P.stock)
        Z.openPair()
        Z.charTab("loot"); Z.worldTab("loot")
    end)
    S.step(20, function() Z.tall() end)
    S.step(40, function() Z.place(); ST.parkMouse() end)
    -- the choices, as a player makes them (gallery_story_shots.lua's order): World Theme > Light, Character Accent >
    -- Blue, World Accent > Blue; the rest of the UI blue in memory (STORY_GLOBAL_BLUE ~= false, as there)
    Z.menuPick(Z.WW, themeRow, Z.leafName("base", "light"), "08 light")
    Z.menuPick(Z.CW, accentRow, Z.leafName("accent", "blue"), "08 char blue")
    Z.menuPick(Z.WW, accentRow, Z.leafName("accent", "blue"), "08 world blue")
    S.step(2, function()
        if STORY_GLOBAL_BLUE ~= false then ZeD.applyTheme(nil, "blue", nil) end
        say("chosen: theme " .. tostring(ZeD.currentBase) .. " | accent char " .. tostring(Z.CW()._accentKey)
            .. " world " .. tostring(Z.WW()._accentKey) .. " global " .. tostring(ZeD.currentAccent))
        ST.parkMouse()
    end)
    S.step(40, function() Z.place() end)
    -- the World window's menu again: Theme with Light checked, Accent with Blue checked (shut without a pick)
    Z.menuShot(Z.WW, themeRow, Z.leafName("base", "light"), "story_08b_footer_light")
    Z.menuShot(Z.WW, accentRow, Z.leafName("accent", "blue"), "story_08c_footer_blue")
    S.step(2, function() ST.parkMouse() end)
    S.step(30, function() Z.place(); Z.shot("story_08d_open_light_blue") end)
    S.step(2, function()
        Z.putOpts()
        Z.theme(Z.lookB, Z.lookA)
        say("theme put back: " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
    end)
    S.step(20, function() end)
end

-- ---- back --------------------------------------------------------------------------------
S.step(2, function()
    Z.putOpts()
    Z.theme(Z.lookB, Z.lookA)
    Z.charTab("loot"); Z.worldTab("loot")
    Z.untall()
    Z.closePair()
    ST.parkMouse()
    say("put back: heights, tabs, theme options | theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
end)
S.start()
