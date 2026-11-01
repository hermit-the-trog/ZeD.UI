-- ZeDUI/tools/qa/gallery_nov1_lot.lua  (Nov 1 2026, QA)
-- The Workshop gallery retake (workshop/gallery/REVIEW_20261101.md, "Retakes"), the mall lot's part: after
-- gallery_v3_core.lua, gallery_v3_reveal.lua and gallery_v3_stage.lua (needs GAL, GAL.spot, GAL.car), before
-- gallery_v3_teardown.lua. Every tab is taken with both windows as tall as the screen allows (gallery_v3_zed.lua's
-- Z.tall: a 12u margin top and bottom), so the whole tab is in the picture. Default look (GAL_LOOK, Dark + Orange).
-- Same screenshot names as gallery_v3_zed.lua, so the gallery's shots.json keeps working:
--   cards      zed_18_card_food (page 21: the apple's card, the whole nutrition label), zed_19_card_weapon
--   equip      zed_10_equip_doll (page 22: the doll, every slot in frame)
--   health     zed_11_health_exercise (page 23: the Exercise pop-up open, its dimmed choices, a body part under the
--              pointer so the figure's readout shows), zed_11b_health_hover (the same hover, the pop-up shut)
--   forage     zed_51_forage (page 29: Search pressed in the lot's real zone, More detail open, finds in the list)
--   furniture  zed_52_furniture (page 29: a chair on the lot under the pointer, its name on the tab and the chip)
-- NOV1_ONLY = { cards = true, ... } above this header takes only those sections.
-- Every capture logs "rect <name> drawer x y w h window x y w h header h footer h tab id" for each window shown.
-- Finds: the search runs for 8 s on its own; then, while the list has fewer than five, an icon in reach that the
-- character has not seen is seen the way vanilla's own force-find does it (ISBaseIcon:spotIcon, or
-- ISSearchManager:doMoveIconNearPlayer when none is in reach). Only if that yields nothing in 40 s are four finds
-- written into ZeD's list by hand ("finds staged" in the log). The list is put back as it was; the icons seen stay
-- seen (vanilla keeps them for the session) and the character keeps the little foraging XP they gave.
-- Puts back: window heights and places, tabs, the cards, the doll view, the health pick and pop-up, search mode, the
-- finds list, More detail, the chair (removed), the HUD options. "ZEDQA n1l ..." ending "ZEDQA n1l DONE".
local G = GAL
if not (G and G.spot and G.car and G.newSeq) then print("ZEDQA n1l ERR run gallery_v3_core.lua and gallery_v3_stage.lua first"); print("ZEDQA n1l DONE"); return end
if not (ZeD and ZeD_CharacterWindow and ZeD_WorldWindow) then print("ZEDQA n1l ERR ZeD is not loaded"); print("ZEDQA n1l DONE"); return end
if ZeD.trTestOn and ZeD.trTestOn() then print("ZEDQA n1l ERR the test language is on"); print("ZEDQA n1l DONE"); return end
local S = G.newSeq("n1l", 780000)
local say = S.say
local p, pn, core = G.p, G.pn, G.core
local CWm, WWm = ZeD_CharacterWindow, ZeD_WorldWindow
local Opt = ZeD.Settings
local Z = { lock = nil, sc = { ok = true, why = "" }, was = {} }
Z.was.ctx = Opt.contextStyleOption:getValue()
Z.was.watch = Opt.watchPlaceOption:getValue()
Z.was.bar = Opt.actionBarOption:getValue()
Z.was.equip = ZeD.EquipDoll.view()
function Z.want(k) return (not NOV1_ONLY) or NOV1_ONLY[k] == true end
function Z.CW() return CWm.getWindow() end
function Z.WW() return WWm.getWindow() end

-- ---------------------------------------------------------------------------
-- windows (as gallery_v3_zed.lua: placed once, centred, then held; Z.tall from its strips section)
-- ---------------------------------------------------------------------------
function Z.place()
    local c, w = Z.CW(), Z.WW()
    if not (c and w and CWm.isOpen() and WWm.isOpen()) then return false end
    if w._rolled then return false end
    local L = Z.lock
    if not L then
        local gap = ZeD.T.px(8)
        local x0 = math.floor((core:getScreenWidth() - (c:getWidth() + gap + w:getWidth())) / 2)
        L = { right = x0 + c:getWidth(), left = x0 + c:getWidth() + gap, cy = c:getY(), wy = w:getY() }
        Z.lock = L
    end
    c._anchorRightEdge = L.right
    c:setX(L.right - c:getWidth())
    w:setX(L.left)
    c:setY(L.cy)
    w:setY(L.wy)
    return true
end
function Z.openPair()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    if not (CWm.isOpen() and WWm.isOpen()) then CWm.toggleBothPaired(0) end
    Z.place()
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
-- both windows as tall as the screen allows (12u top and bottom); the first heights and places kept to put back
function Z.tall()
    local c, w = Z.CW(), Z.WW()
    if not (c and w) then return end
    if not Z.was.size then
        Z.was.size = { c = { c:getX(), c:getY(), c:getHeight() }, w = { w:getX(), w:getY(), w:getHeight() } }
    end
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
    if c then c:setHeight(s.c[3]); pcall(function() c:onResize() end); c:setX(s.c[1]); c:setY(s.c[2]) end
    if w then w:setHeight(s.w[3]); pcall(function() w:onResize() end); w:setX(s.w[1]); w:setY(s.w[2]) end
    Z.lock = nil
    Z.was.size = nil
end
-- the drawer card and the window on the screen, for the crops (gallery_v3_zed.lua's strips line)
function Z.rect(name, which)
    local win = (which == "c") and Z.CW() or Z.WW()
    local dp = win and win._drawerPanel
    if not (win and dp) then say("rect " .. name .. " " .. which .. " none"); return end
    local fh = 0
    pcall(function() fh = win:footerHeight() end)
    say(string.format("rect %s %s drawer %d %d %d %d window %d %d %d %d header %d footer %d tab %s",
        name, (which == "c") and "char" or "world",
        math.floor(dp:getAbsoluteX()), math.floor(dp:getAbsoluteY()), math.floor(dp:getWidth()), math.floor(dp:getHeight()),
        math.floor(win:getAbsoluteX()), math.floor(win:getAbsoluteY()), math.floor(win:getWidth()), math.floor(win:getHeight()),
        math.floor(ZeD.Molecules.getTabHeaderH()), math.floor(fh), tostring(win._activeTab)))
end
function Z.rects(name) Z.rect(name, "c"); Z.rect(name, "w") end
function Z.found(ft)
    local items = G.inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it:getFullType() == ft then return it end
    end
    return nil
end
function Z.selectItem(item)
    local w = Z.CW()
    local c = w and w._mainContent
    if not c then return false end
    local sel = c._selectedItems or {}
    for k in pairs(sel) do sel[k] = nil end
    if item then sel[item] = true end
    c._selectedItems, c._lastClickedItem = sel, item
    w._updateDrawer(c)
    return true
end
function Z.theme(base, accent)
    ZeD.applyTheme(base, accent, ZeD.currentSize)
    local c, w = Z.CW(), Z.WW()
    if c then c._accentKey = nil end
    if w then w._accentKey = nil end
end
function Z.pointAt(x, y)
    if Mouse and Mouse.setXY then pcall(function() Mouse.setXY(math.floor(x), math.floor(y)) end) end
end
-- the pointer where G.cleanLook leaves it: the bottom middle, under the tall windows
function Z.park() Z.pointAt(core:getScreenWidth() / 2, core:getScreenHeight() - 6) end

-- a scene: setup (may return false, why), settle, shot, rects
function Z.setup(fn)
    pcall(Z.place)
    G.faceFront()
    Z.sc.ok, Z.sc.why = true, ""
    if not fn then return end
    local ok, a, b = pcall(fn)
    if not ok then Z.sc.ok, Z.sc.why = false, tostring(a)
    elseif a == false then Z.sc.ok, Z.sc.why = false, tostring(b or "setup refused") end
end
function Z.finish(name)
    if Z.sc.ok then S.shot(name); Z.rects(name) else S.err(name, Z.sc.why) end
end
function Z.Sc(name, settle, fn)
    S.step(2, function() Z.setup(fn) end)
    S.step(settle or 30, function() Z.finish(name) end)
end
function Z.T(name, which, tab, settle, fn)
    S.step(2, function() Z.sc.ok, Z.sc.why = true, "" end)
    S.poll(2, 120, function()
        if which == "c" then return Z.charTab(tab) end
        return Z.worldTab(tab)
    end, function() Z.sc.ok = false; Z.sc.why = "no tab " .. tab end)
    S.step(6, function() if Z.sc.ok then Z.setup(fn) end end)
    S.step(settle or 30, function() Z.finish(name) end)
end
function Z.tabStep(which, tab)
    S.step(2, function() Z.sc.ok, Z.sc.why = true, "" end)
    S.poll(2, 120, function()
        if which == "c" then return Z.charTab(tab) end
        return Z.worldTab(tab)
    end, function() Z.sc.ok = false; Z.sc.why = "no tab " .. tab end)
end

-- ===========================================================================
S.step(2, function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    G.cleanLook()
    G.day()
    pcall(ZeD.Settings.reapplyFromOptions)
    local b, a = (GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "orange"
    if ZeD.currentBase ~= b or ZeD.currentAccent ~= a then Z.theme(b, a) end
    say("theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " size " .. tostring(ZeD.currentSize)
        .. " | scale " .. tostring(ZeD.Scale and ZeD.Scale.current and ZeD.Scale.current()))
    Opt.watchPlaceOption:setValue(1)
    Opt.contextStyleOption:setValue(1)
    Opt.actionBarOption:setValue(1)
    G.stand()
    Z.openPair()
end)
S.step(40, function() Z.charTab("loot"); Z.worldTab("loot"); Z.tall() end)
S.step(60, function() Z.tall(); Z.park() end)
S.zoomTo(1.0)
S.step(10, function()
    local c, w = Z.CW(), Z.WW()
    say(string.format("tall: char %dx%d at %d,%d | world %dx%d at %d,%d | screen %dx%d",
        math.floor(c:getWidth()), math.floor(c:getHeight()), math.floor(c:getX()), math.floor(c:getY()),
        math.floor(w:getWidth()), math.floor(w:getHeight()), math.floor(w:getX()), math.floor(w:getY()),
        core:getScreenWidth(), core:getScreenHeight()))
end)

-- ---- cards (page 21) ---------------------------------------------------------------
if Z.want("cards") then
    Z.Sc("zed_18_card_food", 50, function()
        local it = Z.found("Base.Apple")
        if not it then return false, "no apple" end
        if not Z.selectItem(it) then return false, "Loot list not ready" end
    end)
    Z.Sc("zed_19_card_weapon", 50, function()
        local it = Z.found("Base.Machete")
        if not it then return false, "no machete" end
        if not Z.selectItem(it) then return false, "Loot list not ready" end
    end)
    S.step(2, function() Z.selectItem(nil) end)
    S.step(30, function() Z.place() end)
end

-- ---- equip (page 22) ---------------------------------------------------------------
if Z.want("equip") then
    Z.T("zed_10_equip_doll", "c", "equip", 60, function()
        ZeD.EquipDoll.setView("doll")
        pcall(function() Z.CW()._equipScroll:setScrollPos(0) end)
    end)
    S.step(1, function()
        local sc = Z.CW() and Z.CW()._equipScroll
        -- (a visible bar means the doll still runs past the window: Rings right, Feet, Ankles may be cut)
        say("equip: the tab's scrollbar showing " .. tostring(sc and sc.visible))
    end)
    S.step(2, function() ZeD.EquipDoll.setView(Z.was.equip); Z.charTab("loot") end)
    S.step(20, function() Z.place() end)
end

-- ---- health (page 23) --------------------------------------------------------------
if Z.want("health") then
    Z.tabStep("c", "health")
    S.step(10, function()
        if not Z.sc.ok then return end
        local w = Z.CW()
        if not (ZeD.HealthTab and ZeD.HealthTab.exerciseInfo and ZeD.HealthTab.exerciseInfo(p, "pushups")) then Z.sc.ok, Z.sc.why = false, "no exercise info"; return end
        Z.was.exSel, Z.was.figExp = w._healthExerciseSel, w._healthFigureExpanded
        w._healthFigureExpanded = true
        pcall(function() w._healthScroll:setScrollPos(0) end)
        w._healthExerciseSel = "pushups"
        ZeD.HealthTab.openMenu(w)
        Z.place()
    end)
    -- the pointer on a body part of the figure (its rects, drawer-panel coordinates, from the last frame drawn)
    S.step(30, function()
        if not Z.sc.ok then return end
        local w = Z.CW()
        local fig, dp = w._healthBodyFigure, w._drawerPanel
        local rects = (fig and fig.getPartRects) and fig:getPartRects() or {}
        local pick = nil
        for _, r in ipairs(rects) do if r.name == "Upper Torso" then pick = r end end
        pick = pick or rects[1]
        if not (pick and dp) then Z.sc.ok, Z.sc.why = false, "the figure has no part rects (folded or not drawn)"; return end
        Z.hoverPart = pick.name
        Z.pointAt(dp:getAbsoluteX() + pick.x + pick.w / 2, dp:getAbsoluteY() + pick.y + pick.h / 2)
        say(string.format("health: the pointer on %s (%d parts on the figure) | pop-up open %s", tostring(pick.name), #rects, tostring(w._healthMenuOpen)))
    end)
    S.step(20, function()
        local w = Z.CW()
        -- (the drawer's own mouse-move sets the hover from the real pointer; this only covers a frame it missed)
        if Z.sc.ok and w and not w._healthHoveredPart then w._healthHoveredPart = Z.hoverPart end
    end)
    S.step(20, function()
        local w = Z.CW()
        say("health: hovered " .. tostring(w and w._healthHoveredPart) .. " | pop-up open " .. tostring(w and w._healthMenuOpen)
            .. " | pick " .. tostring(w and w._healthExerciseSel))
        Z.finish("zed_11_health_exercise")
    end)
    S.step(2, function()
        local w = Z.CW()
        if w then ZeD.HealthTab.closeMenu(w) end
    end)
    S.step(30, function()
        local w = Z.CW()
        if Z.sc.ok and w and not w._healthHoveredPart then w._healthHoveredPart = Z.hoverPart end
        say("health: hovered " .. tostring(w and w._healthHoveredPart) .. " | pop-up open " .. tostring(w and w._healthMenuOpen))
        Z.finish("zed_11b_health_hover")
    end)
    S.step(2, function()
        Z.park()
        local w = Z.CW()
        if w then
            if w._healthMenuOpen then ZeD.HealthTab.closeMenu(w) end
            w._healthExerciseSel = Z.was.exSel
            w._healthFigureExpanded = Z.was.figExp
            w._healthHoveredPart = nil
        end
        Z.charTab("loot")
    end)
    S.step(20, function() Z.place() end)
end

-- ---- forage (page 29) --------------------------------------------------------------
if Z.want("forage") then
    local FQ = { tries = 0, last = -9999 }
    function FQ.queue() return ZeD.ForagingTab._findQueues[pn] or {} end
    Z.tabStep("w", "forage")
    S.step(30, function()
        if not Z.sc.ok then return end
        local w = Z.WW()
        local mgr = ISSearchManager.getManager(p)
        FQ.mgr = mgr
        Z.was.more = w._moreDetailOpen
        Z.was.search = mgr and mgr.isSearchMode or false
        local q = ZeD.ForagingTab._findQueues[pn]
        Z.was.finds = q
        local copy = {}
        for i, e in ipairs(q or {}) do copy[i] = e end
        ZeD.ForagingTab._findQueues[pn] = copy
        w._moreDetailOpen = true
        -- the band's Search button: what its click runs (ZeD.ForagingTab.onClick)
        if mgr and not mgr.isSearchMode then ZeD.ForagingTab.toggleSearch(w) end
        Z.place()
        say(string.format("forage: search mode %s (was %s) | finds listed %d | More detail open",
            tostring(mgr and mgr.isSearchMode), tostring(Z.was.search), #copy))
    end)
    S.waitMs(8000)
    S.step(2, function()
        local mgr = FQ.mgr
        local nA, nF = 0, 0
        for _ in pairs(mgr and mgr.activeIcons or {}) do nA = nA + 1 end
        for _ in pairs(mgr and mgr.forageIcons or {}) do nF = nF + 1 end
        local zone = mgr and mgr.currentZone
        say(string.format("forage: zone %s | radius %s | icons %d (%d active) | finds %d by the search itself",
            tostring(zone and (zone.name or zone.type or zone.id)), tostring(mgr and mgr.radius), nF, nA, #FQ.queue()))
        if mgr and not mgr.isSearchMode then say("note: search mode went off (vanilla's checkShouldDisable): on again"); ZeD.ForagingTab.toggleSearch(Z.WW()) end
    end)
    S.poll(10, 2400, function()
        local mgr = FQ.mgr
        if not mgr then return true end
        if #FQ.queue() >= 5 then return true end
        if S.tick - FQ.last < 60 then return false end
        FQ.last = S.tick
        FQ.tries = FQ.tries + 1
        -- the nearest active icon in reach the character has not seen: seen as vanilla's force-find sees one
        local best, bd = nil, 1e9
        local px, py = p:getX(), p:getY()
        local reach = (tonumber(mgr.radius) or 6) + 3
        for _, icon in pairs(mgr.activeIcons or {}) do
            local seen = true
            pcall(function() seen = icon:getIsSeen() end)
            if not seen and icon.xCoord and icon.yCoord then
                local ddx, ddy = icon.xCoord - px, icon.yCoord - py
                local d = math.sqrt(ddx * ddx + ddy * ddy)
                if d <= reach and d < bd then best, bd = icon, d end
            end
        end
        if best then
            local ok = pcall(function() best:spotIcon() end)
            say(string.format("forage: seen %s at %.1f squares (%s)", tostring(best.itemType), bd, ok and "ok" or "failed"))
        elseif mgr.currentZone then
            pcall(function() mgr:doMoveIconNearPlayer() end)
        end
        return FQ.tries >= 40
    end, function() say("note: the finds did not reach five") end)
    S.step(2, function()
        if not FQ.mgr then return end
        local q = FQ.queue()
        if #q > 0 then say("forage: " .. #q .. " finds in the list from the search"); return end
        -- nothing came: four of the zone's own kinds written into the list (dist, bearing key, name, weight)
        local SM = getScriptManager()
        local picks = { { "Base.TinCanEmpty", 3, "UI_ZeD_Forage_CompassNE" }, { "Base.PopEmpty", 5, "UI_ZeD_Forage_CompassE" },
                        { "Base.Newspaper", 6, "UI_ZeD_Forage_CompassS" }, { "Base.ScrapMetal", 8, "UI_ZeD_Forage_CompassW" } }
        for _, k in ipairs(picks) do
            local si = nil
            pcall(function() si = SM:FindItem(k[1]) end)
            if si then
                table.insert(q, 1, { dist = k[2], bearing = k[3], name = si:getDisplayName(), weight = si:getActualWeight() or 0.1 })
            end
        end
        ZeD.ForagingTab._findQueues[pn] = q
        say("forage: finds staged (" .. #q .. "): the search gave none in time")
    end)
    S.step(60, function()
        local w = Z.WW()
        local mgr = FQ.mgr
        local names = {}
        for i, e in ipairs(FQ.queue()) do if i <= 8 then names[#names + 1] = tostring(e.name) end end
        say("forage: searching " .. tostring(mgr and mgr.isSearchMode) .. " | More detail " .. tostring(w and w._moreDetailOpen)
            .. " | finds: " .. table.concat(names, ", "))
        Z.finish("zed_51_forage")
    end)
    S.step(2, function()
        local w = Z.WW()
        local mgr = FQ.mgr
        if not mgr then Z.worldTab("loot"); return end
        if mgr.isSearchMode and not Z.was.search then pcall(function() mgr:toggleSearchMode(false) end) end
        ZeD.ForagingTab._findQueues[pn] = Z.was.finds
        if w then w._moreDetailOpen = Z.was.more end
        say("forage put back: search mode " .. tostring(mgr and mgr.isSearchMode) .. ", the finds list as it was")
        Z.worldTab("loot")
    end)
    S.step(30, function() Z.place() end)
end

-- ---- furniture (page 29) -----------------------------------------------------------
if Z.want("furniture") then
    local FU = { sprites = { "furniture_seating_outdoor_01_17", "furniture_seating_outdoor_01_16", "furniture_seating_indoor_01_0" } }
    -- the screen point of a square's middle on the ground
    function FU.screenOf(x, y)
        local sx, sy = -1, -1
        pcall(function() sx = isoToScreenX(pn, x + 0.5, y + 0.5, 0); sy = isoToScreenY(pn, x + 0.5, y + 0.5, 0) end)
        return math.floor(sx), math.floor(sy)
    end
    function FU.inWin(win, x, y, m)
        if not (win and win:isVisible()) then return false end
        local ax, ay = win:getAbsoluteX(), win:getAbsoluteY()
        return x >= ax - m and x < ax + win:getWidth() + m and y >= ay - m and y < ay + win:getHeight() + m
    end
    -- a free outdoor square near the character whose middle shows on the screen clear of both windows
    function FU.find()
        local cx, cy = math.floor(p:getX()), math.floor(p:getY())
        local sw, sh = core:getScreenWidth(), core:getScreenHeight()
        local m = ZeD.T.px(40)
        for r = 2, 26 do
            for dy = -r, r do
                for dx = -r, r do
                    if math.max(math.abs(dx), math.abs(dy)) == r then
                        local x, y = cx + dx, cy + dy
                        local sx, sy = FU.screenOf(x, y)
                        if sx > m and sy > m * 2 and sx < sw - m and sy < sh - m * 3
                                and not FU.inWin(Z.CW(), sx, sy, m) and not FU.inWin(Z.WW(), sx, sy, m) then
                            local sq = getCell():getGridSquare(x, y, 0)
                            local free = false
                            pcall(function() free = sq ~= nil and sq:isOutside() and sq:isFree(false) and not sq:getVehicleContainer() and not sq:HasTree() end)
                            if free and sq:getObjects():size() <= 2 then return sq, sx, sy end
                        end
                    end
                end
            end
        end
        return nil
    end
    Z.tabStep("w", "furniture")
    S.step(30, function()
        if not Z.sc.ok then return end
        local sq, sx, sy = FU.find()
        if not sq then
            -- no clear square beside the windows: the pair to the right edge, the left of the screen open
            local c, w = Z.CW(), Z.WW()
            local m, gap = ZeD.T.px(12), ZeD.T.px(8)
            local left = core:getScreenWidth() - m - w:getWidth()
            Z.lock = { right = left - gap, left = left, cy = c:getY(), wy = w:getY() }
            Z.place()
            say("furniture: no clear square beside the centred windows; the pair moved to the right edge")
        else
            FU.sq, FU.sx, FU.sy = sq, sx, sy
        end
    end)
    -- Nov 1 2026, second take: the pointer rests on the chosen screen spot first and the chair goes on the square the
    -- game itself reads under the pointer (the tab's capture), not the one isoToScreen named: at 4K they differed
    -- by six tiles and the tab read nil.
    S.step(20, function() if Z.sc.ok and FU.sx then Z.pointAt(FU.sx, FU.sy) end end)
    S.waitMs(500)
    S.step(20, function()
        if not Z.sc.ok then return end
        if not FU.sq then FU.sq, FU.sx, FU.sy = FU.find() end
        if not FU.sq then Z.sc.ok, Z.sc.why = false, "no clear square on the screen for the chair"; return end
        local FT = ZeD.FurnitureTab
        local c = FT and FT.cap and FT.cap[0]
        if c and c.sq then
            say(string.format("furniture: the pointer's square %d,%d (isoToScreen named %d,%d)", c.sq:getX(), c.sq:getY(), FU.sq:getX(), FU.sq:getY()))
            FU.sq = c.sq
        else
            say("furniture: the tab read no square under the pointer; using the named one")
        end
        for _, name in ipairs(FU.sprites) do
            if not FU.obj and getSprite(name) then
                pcall(function()
                    local o = IsoObject.new(FU.sq, name)
                    FU.sq:AddTileObject(o)
                    FU.obj, FU.sprite = o, name
                end)
            end
        end
        if not FU.obj then Z.sc.ok, Z.sc.why = false, "no furniture sprite could be placed"; return end
        say(string.format("furniture: %s placed at %d,%d (screen %d,%d)", FU.sprite, FU.sq:getX(), FU.sq:getY(), FU.sx, FU.sy))
    end)
    -- the pointer rests on the chair's square (the tab's hold reads a tile rested on for a quarter second)
    S.step(20, function() if Z.sc.ok then Z.pointAt(FU.sx + 3, FU.sy - 3) end end)
    S.waitMs(400)
    S.step(2, function() if Z.sc.ok then Z.pointAt(FU.sx, FU.sy) end end)
    S.waitMs(1200)
    S.step(2, function()
        local FT = ZeD.FurnitureTab
        local c = FT and FT.cap and FT.cap[0]
        local mp = c and c.mp
        local nm = nil
        pcall(function() nm = mp and (mp.name or mp.customName or mp.spriteName) end)
        say(string.format("furniture: mode %s | the tab reads %s at %s", tostring(FT and FT.state and FT.state.mode), tostring(nm),
            tostring(c and c.sq and (c.sq:getX() .. "," .. c.sq:getY()))))
        Z.finish("zed_52_furniture")
    end)
    S.step(2, function() Z.park(); Z.worldTab("loot") end)
    S.step(40, function()
        if FU.obj then
            pcall(function() FU.sq:transmitRemoveItemFromSquare(FU.obj) end)
            say("furniture put back: the chair removed")
        end
        FU.obj = nil
        Z.lock = nil
        Z.tall()
    end)
    S.step(20, function() Z.place() end)
end

-- ---- back ----------------------------------------------------------------------------
S.step(10, function()
    Z.park()
    Z.selectItem(nil)
    Z.charTab("loot"); Z.worldTab("loot")
    pcall(ZeD.Settings.reapplyFromOptions)
    Opt.contextStyleOption:setValue(Z.was.ctx)
    Opt.watchPlaceOption:setValue(Z.was.watch)
    Opt.actionBarOption:setValue(Z.was.bar)
    ZeD.EquipDoll.setView(Z.was.equip)
end)
S.step(20, function()
    Z.untall()
    Z.openPair()
    say("put back: heights, places, tabs, options | theme " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
end)
S.start()
