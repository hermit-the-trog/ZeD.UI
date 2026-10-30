-- ZeDUI/tools/qa/zedqa_two_widths.lua  (Oct 29 2026)
-- The director's rule: a drawer is the half card or the full card, nothing between and nothing wider,
-- so a card never bumps another and the two windows never move each other or overlap.
-- Both windows open (the prelude does that). Each case opens something in one window, waits until the
-- windows stop moving, and checks:
--   the drawer (_drawerEffW) is exactly px(220) (half) or px(480) (full), in screen pixels;
--   the other window has the same place and size it had before;
--   the two windows do not overlap and both are on the screen;
-- and after it is closed again, the window is where and as wide as it was.
-- The cases: every tab of both windows, the Equip to-do, the Journal's Loadouts page, an item card in each
-- window, every object card with something of its kind nearby (the deep run's objects: run
-- zedqa_deep_run.lua first for all of them), Craft at an oven, the Radio tab with a walkie (Character) and a
-- ham set (World), the Maps tab and its pop-out; then a window held in (room for less than the full card),
-- where every tab must be the half card. All put back. grep "ZEDQA tww".
local p = getPlayer()
local pn = p:getPlayerNum()
local Focus = ZeD.Input.Focus
local function say(s) print("ZEDQA tww " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
-- the pictures are named for the code they show: "before" while the Maps drawer still grows by its toolbar buttons
local PREFIX = (ZeD.MapsTabExt and ZeD.MapsTabExt.drawerExtraW) and "before" or "after"
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_tww_" .. PREFIX .. "_" .. n .. ".png") end) end
local function cw() return ZeD_CharacterWindow.getWindow() end
local function ww() return ZeD_WorldWindow.getWindow() end
local T = ZeD.T
local SW, SH = getCore():getScreenWidth(), getCore():getScreenHeight()

-- ---- the step queue (as the pad map's): wait n ticks, or until the windows are still
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end
local STILL, STILL_MAX = 30, 900
local function shape()
    local t = {}
    for _, w in ipairs({ cw(), ww() }) do
        if w and w:isVisible() then
            t[#t + 1] = string.format("%d,%d,%d,%d,%d", w:getX(), w:getY(), w:getWidth(), w:getHeight(), math.floor(w._drawerEffW or 0))
        end
    end
    return table.concat(t, ";")
end
local function whenStill(fn)
    local last, same, waited = nil, 0, 0
    local function poll()
        local s = shape()
        if s == last then same = same + 1 else same, last = 0, s end
        waited = waited + 1
        if same >= STILL or waited >= STILL_MAX then
            if same < STILL then say("WARN the windows were still moving after " .. waited .. " ticks: checked anyway") end
            fn()
        else
            insertNext(0, poll)
        end
    end
    insertNext(0, poll)
end

-- ---- geometry
local function geo(w) return { x = w:getX(), y = w:getY(), w = w:getWidth(), h = w:getHeight() } end
local function same(a, b) return math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and math.abs(a.w - b.w) <= 1 and math.abs(a.h - b.h) <= 1 end
local function gs(g) return string.format("%d,%d %dx%d", g.x, g.y, g.w, g.h) end
local HALF, FULL = T.px(220), T.px(480)
local function cardName(eff)
    if eff <= 0 then return "closed" end
    if math.abs(eff - HALF) <= 1 then return "half" end
    if math.abs(eff - FULL) <= 1 then return "full" end
    return "NEITHER"
end
local base = nil      -- both windows as the run found them
local function bothGeo() return { c = geo(cw()), w = geo(ww()) } end

-- the state of the pair right now, against before = bothGeo() from before the case; acted: "c" or "w"
-- want: "half", "full" or nil (either). Returns the drawer's card name in the acted window.
local function verify(name, acted, before, want)
    local c, w = cw(), ww()
    local gc, gw = geo(c), geo(w)
    local aw = (acted == "c") and c or w
    local eff = math.floor(aw._drawerEffW or 0)
    local card = cardName(eff)
    say(string.format("%s: drawer %d px = %s | Character %s | World %s", name, eff, card, gs(gc), gs(gw)))
    check(card == "half" or card == "full", name .. ": the drawer is the half card or the full card (" .. eff .. " px; half " .. HALF .. ", full " .. FULL .. ")")
    if want then check(card == want, name .. ": it is the " .. want .. " card (" .. card .. ")") end
    -- the other window's drawer too, if one is open
    local ow = (acted == "c") and w or c
    local oe = math.floor(ow._drawerEffW or 0)
    if oe > 0 then check(cardName(oe) ~= "NEITHER", name .. ": the other window's drawer is a card too (" .. oe .. " px)") end
    local og = (acted == "c") and gw or gc
    local ob = (acted == "c") and before.w or before.c
    check(same(og, ob), name .. ": the other window did not move or change size (" .. gs(ob) .. " -> " .. gs(og) .. ")")
    check(gc.x + gc.w <= gw.x, name .. ": the windows do not overlap (Character ends at " .. (gc.x + gc.w) .. ", World starts at " .. gw.x .. ")")
    check(gc.x >= 0 and gw.x + gw.w <= SW, name .. ": both windows are on the screen")
    return card
end
-- the window as it was, once the case is shut
local function verifyBack(name, acted, before)
    local g = (acted == "c") and geo(cw()) or geo(ww())
    local b = (acted == "c") and before.c or before.w
    check(same(g, b), name .. ": closed, the window is back where and as wide as it was (" .. gs(b) .. " -> " .. gs(g) .. ")")
    local o = (acted == "c") and geo(ww()) or geo(cw())
    local ob = (acted == "c") and before.w or before.c
    check(same(o, ob), name .. ": closed, the other window is where it was")
end

local function goTab(w, strip, id)
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
    return false
end
local function charTab(id) local w = cw(); return w and goTab(w, w._tabStripPanel, id) end
local function worldTab(id) local w = ww(); return w and goTab(w, w._actionTabStrip, id) end
local function tabsOf(strip)
    local out = {}
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if type(z.id) == "string" and z.id:sub(1, 4) == "tab:" then out[#out + 1] = z.id:sub(5) end
    end
    return out
end
local function backToLoot()
    local c, w = cw(), ww()
    if c then goTab(c, c._tabStripPanel, "loot") end
    if w then goTab(w, w._actionTabStrip, "loot") end
end

-- ---- what the run adds, to be taken away
local added, placed = {}, {}
local winsWere = ZeD_CharacterWindow.isOpen()
local MT = ZeD.MapsTab
local origMaxC, origMaxW

step(10, function()
    if not ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    pcall(function() Mouse.setXY(20, 20) end)
    pcall(function() setGameSpeed(1) end)
    backToLoot()
    local it = p:getInventory():AddItem("Base.Apple")
    if it then added[#added + 1] = it end
    say(string.format("screen %dx%d, root %.2f, half card %d px, full card %d px", SW, SH, ZeD.Scale.root(), HALF, FULL))
end)
-- the deep run's objects (every object card's kind) stand round its home, which the prelude moved the character
-- away from: back there for the run, and back to the drag strip at the end
local walkHome = { x = p:getX(), y = p:getY(), z = p:getZ() }
local function moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end
step(5, function()
    local dr = p:getModData().ZeDDeepRun
    local h = dr and dr.home
    if h and (math.abs(h.x - p:getX()) > 2 or math.abs(h.y - p:getY()) > 2) then
        moveTo(h.x + 0.5, h.y + 0.5, 0)
        say(string.format("to the deep run's home, %d,%d", h.x, h.y))
    else
        say("no deep run home to go to (run zedqa_deep_run.lua first for every object card)")
    end
end)
step(90, function() whenStill(function()
    base = bothGeo()
    say("the pair at the start: Character " .. gs(base.c) .. ", World " .. gs(base.w))
    check(base.c.x + base.c.w <= base.w.x, "the pair starts apart")
end) end)

-- ===================================================================== the cases
-- A case: { name, acted = "c" | "w", want = "half" | "full" | nil, open(), stage2() (optional, after the
-- first stillness), close(), note() (optional, after the checks) }. open() returning false means the thing is
-- not there to open: the case is skipped and named at the end.
local skipped = {}
local function runCases(list)
    local i = 0
    local function insertSeq(seq) for k, st in ipairs(seq) do table.insert(Q, qi + k, st) end end
    local function nextCase()
        i = i + 1
        local cs = list[i]
        if not cs then return end
        local before, skip = nil, false
        local seq = {}
        seq[#seq + 1] = { n = 5, fn = function()
            before = bothGeo()
            local ok, r = pcall(cs.open)
            if not ok then say("ERR open " .. cs.name .. ": " .. tostring(r)) end
            if ok and r == false then skip = true; skipped[#skipped + 1] = cs.name end
        end }
        seq[#seq + 1] = { n = 20, fn = function() whenStill(function()
            if skip then return end
            if cs.stage2 then
                local ok, e = pcall(cs.stage2)
                if not ok then say("ERR stage2 " .. cs.name .. ": " .. tostring(e)) end
                insertNext(10, function() whenStill(function() end) end)
            end
        end) end }
        seq[#seq + 1] = { n = 5, fn = function()
            if skip then return end
            verify(cs.name, cs.acted, before, cs.want)
            if cs.shot then shot(cs.shot) end
            if cs.note then pcall(cs.note) end
        end }
        seq[#seq + 1] = { n = 5, fn = function() local ok, e = pcall(cs.close); if not ok then say("ERR close " .. cs.name .. ": " .. tostring(e)) end end }
        seq[#seq + 1] = { n = 20, fn = function() whenStill(function() if not skip then verifyBack(cs.name, cs.acted, before) end end) end }
        seq[#seq + 1] = { n = 2, fn = nextCase }
        insertSeq(seq)
    end
    nextCase()
end

local tabList = {}
step(5, function()
    for _, id in ipairs(tabsOf(cw()._tabStripPanel)) do
        if id ~= "loot" then tabList[#tabList + 1] = { name = "Character " .. id, acted = "c", want = "full", open = function() return charTab(id) end, close = function() charTab("loot") end } end
    end
    for _, id in ipairs(tabsOf(ww()._actionTabStrip)) do
        if id ~= "loot" and id ~= "radio" then
            tabList[#tabList + 1] = { name = "World " .. id, acted = "w", want = "full", open = function() return worldTab(id) end, close = function() worldTab("loot") end }
        end
    end
    say(#tabList .. " tab cases")
    runCases(tabList)
end)

-- ===================================================================== 2. the Equip to-do, the Journal's Loadouts page
local EL = ZeD.EquipLoadout
local extra = {}
if EL then
    extra[#extra + 1] = { name = "Character Equip to-do", acted = "c",
        open = function() charTab("equip"); EL.openTodo(cw()) end,
        close = function() EL.closeTodo(cw()); charTab("loot") end }
    extra[#extra + 1] = { name = "Character Journal Loadouts page", acted = "c", want = "full",
        open = function() EL.openJournal(cw(), nil) end,
        close = function() cw()._journalSubTab = 1; charTab("loot") end }
end
-- each Journal page
for sub = 1, 5 do
    extra[#extra + 1] = { name = "Character Journal page " .. sub, acted = "c", want = "full",
        open = function() charTab("journal"); cw()._journalSubTab = sub end,
        close = function() cw()._journalSubTab = 1; charTab("loot") end }
end

-- ===================================================================== 3. item cards
local function openFirstItem(w, zoneName)
    Focus.claimFocus(w)
    -- (a row of a stack of several opens the stack, not a card: the next row is tried)
    local tried = 0
    for _, c in ipairs(Focus.flatElements(w)) do
        if c.zone == zoneName and c.el and c.el.item and tried < 12 then
            tried = tried + 1
            Focus.focusWhere(w, zoneName, function(e) return e == c.el end)
            c.el.onActivate(w, c.el)
            if w._drawerItem ~= nil then return true end
        end
    end
    say("WARN no item row opened a card in " .. zoneName .. " (" .. tried .. " tried)")
    return false
end
extra[#extra + 1] = { name = "World item card", acted = "w", want = "half",
    open = function()
        worldTab("loot")
        -- a container beside the character with something in it (the deep run's crate), on show in the World window
        local w = ww()
        for _, c in ipairs(Focus.flatElements(w)) do
            local inv = c.zone == "worldContainerStrip" and c.el and c.el.inventory
            if inv and inv ~= p:getInventory() and inv:getItems():size() > 0 then c.el.onActivate(w, c.el); break end
        end
        return openFirstItem(w, "worldMainInv")
    end,
    close = function() local w = ww(); local cnt = w._mainContent; if cnt then cnt._selectedItems = {}; cnt._lastClickedItem = nil; w._updateDrawer() end end }
extra[#extra + 1] = { name = "Character item card", acted = "c", want = "half",
    open = function() charTab("loot"); return openFirstItem(cw(), "charMainInv") end,
    close = function() local c = cw(); local cnt = c._mainContent; if cnt then cnt._selectedItems = {}; cnt._lastClickedItem = nil; c._updateDrawer(cnt) end end }

-- ===================================================================== 4. object cards
local OC = ZeD.ObjectCards
local function findNear(pred)
    local px, py = math.floor(p:getX()), math.floor(p:getY())
    for r = 0, 8 do for dy = -r, r do for dx = -r, r do
        if math.max(math.abs(dx), math.abs(dy)) == r then
            local sq = getCell():getGridSquare(px + dx, py + dy, 0)
            local objs = sq and sq:getObjects()
            for i = 0, (objs and objs:size() or 0) - 1 do
                local o = objs:get(i)
                if pred(o) then return o end
            end
        end
    end end end
end
local function openCard(kind)
    local def = OC.kinds[kind]
    local t
    if def.nearby then
        local ok, list = pcall(def.nearby, p)
        t = ok and list and list[1] or nil
    elseif kind == "lock" then
        local o = findNear(function(o)
            local tg
            pcall(function() tg = o:getModData().ZeDDeepRun end)
            return tg == "door" or tg == "padlock" or tg == "near_crate"
        end)
        t = o and def.resolve(p, o)
    elseif kind == "fluid" then
        local o = findNear(function(o) local fc; pcall(function() fc = o:getFluidContainer() end); return fc ~= nil end)
        local ok, c = pcall(function() return o and ISFluidContainer:new(o:getFluidContainer()) end)
        t = ok and c and def.resolve(p, { container = c, into = true }) or nil
    elseif kind == "place3d" then
        local px, py = math.floor(p:getX()), math.floor(p:getY())
        for r = 0, 2 do for dy = -r, r do for dx = -r, r do
            local sq = (not t) and math.max(math.abs(dx), math.abs(dy)) == r and getCell():getGridSquare(px + dx, py + dy, 0)
            local wos = sq and sq:getWorldObjects()
            if wos and wos:size() > 0 then t = def.resolve(p, wos:get(0)) end
        end end end
    end
    if not t then return false end
    return ZeD_WorldWindow.openObjectCard(pn, { def = def, t = t })
end
local cardKinds = {}
do
    for k, _ in pairs(OC.kinds) do cardKinds[#cardKinds + 1] = k end
    table.sort(cardKinds)
end
-- an object card needs its object near the character: a kind with none is skipped and named at the end
for _, kind in ipairs(cardKinds) do
    extra[#extra + 1] = { name = "World object card " .. kind, acted = "w", want = "full",
        open = function() return openCard(kind) end,
        close = function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end }
end

-- ===================================================================== 5. Craft at an oven, Radio (a walkie, a ham set), Maps
local ST, SA = ZeD.Stations, ZeD.StationAppliance
local stove
step(5, function()
    if not (ST and SA) then return end
    local sq = getCell():getGridSquare(math.floor(p:getX()) + 2, math.floor(p:getY()), math.floor(p:getZ()))
    if sq and sq:isFree(false) then
        local obj = IsoStove.new(getCell(), sq, getSprite("appliances_cooking_01_12"))
        pcall(function() obj:createContainersFromSpriteProperties() end)
        sq:AddSpecialObject(obj)
        if obj:getObjectIndex() < 0 then pcall(function() sq:AddTileObject(obj) end) end
        stove = obj
        placed[#placed + 1] = obj
    end
    say("an oven placed: " .. tostring(stove ~= nil))
    -- a generator, for its object card when the deep run's are out of reach (taken away at the end)
    local gsq = getCell():getGridSquare(math.floor(p:getX()) - 2, math.floor(p:getY()), math.floor(p:getZ()))
    if gsq and gsq:isFree(false) then
        local ok = pcall(function()
            local g = IsoGenerator.new(instanceItem("Base.Generator"), getCell(), gsq)
            g:setConnected(true)
            g:setFuel(50)
            placed[#placed + 1] = g
        end)
        say("a generator placed: " .. tostring(ok))
    end
end)
extra[#extra + 1] = { name = "World Craft at an oven", acted = "w", want = "full", shot = "oven",
    open = function() if not stove then return false end; ST.open(p, stove) end,
    close = function() pcall(function() ST.unbind(p) end); worldTab("loot") end }
extra[#extra + 1] = { name = "World Craft (no station)", acted = "w", want = "full",
    open = function() worldTab("craft") end, close = function() worldTab("loot") end }

local walkie
step(5, function()
    local it = p:getInventory():AddItem("Base.WalkieTalkie2")
    if it then
        added[#added + 1] = it
        local dd = it:getDeviceData()
        if dd then dd:setHasBattery(true); dd:setPower(0.6); dd:setIsTurnedOn(false) end
        p:setPrimaryHandItem(it)
        walkie = it
    end
end)
extra[#extra + 1] = { name = "Character Radio (a walkie)", acted = "c", shot = "walkie",
    open = function() return charTab("radio") end, close = function() charTab("loot") end }

local ham
step(5, function()
    local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local here = p:getCurrentSquare()
    for _, d in ipairs({ { 0, 1 }, { 0, -1 }, { -1, 0 }, { 1, 1 }, { -1, 1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x0 + d[1], y0 + d[2], z0)
        if not ham and sq and sq:isFree(false) and here and here:canReachTo(sq) then
            local it = instanceItem("Base.HamRadio1")
            if it then
                local dd = it:getDeviceData()
                dd:setHasBattery(true); dd:setPower(0.8); dd:setIsTurnedOn(false); dd:setMicIsMuted(true)
                local obj = IsoRadio.new(getCell(), sq, getSprite("appliances_com_01_0"))
                obj:setDeviceData(dd)
                sq:AddTileObject(obj)
                placed[#placed + 1] = obj
                ham = obj
            end
        end
    end
    say("a ham set placed: " .. tostring(ham ~= nil))
end)
extra[#extra + 1] = { name = "World Radio (a ham set)", acted = "w", shot = "ham",
    open = function()
        if not ham then return false end
        for i, r in ipairs(ww()._radios or {}) do if r.radioInstance == ham then ww()._radioIdx = i end end
        return worldTab("radio")
    end,
    close = function() worldTab("loot") end }

-- the Maps tab and its pop-out (the pop-out is a window of its own; the two windows must not change)
extra[#extra + 1] = { name = "World Maps", acted = "w", want = "full", shot = "maps",
    open = function() return worldTab("maps") end,
    close = function() worldTab("loot") end }
extra[#extra + 1] = { name = "World Maps pop-out", acted = "w", want = "full",
    open = function() return worldTab("maps") end,
    stage2 = function() MT.openPopout(ww()) end,
    note = function()
        local pop = ww()._mapPopout
        if not pop then say("FAIL the pop-out did not open"); fails = fails + 1; return end
        local pg, gc, gw = geo(pop), geo(cw()), geo(ww())
        local function ov(a, b) return a.x < b.x + b.w and b.x < a.x + a.w and a.y < b.y + b.h and b.y < a.y + a.h end
        say(string.format("the pop-out %s: over the Character window %s, over the World window %s (it is a window of its own, centred)", gs(pg), tostring(ov(pg, gc)), tostring(ov(pg, gw))))
        shot("maps_popout")
    end,
    close = function() MT.closePopout(ww()); worldTab("loot") end }

-- ===================================================================== run them all
step(5, function()
    say(#extra .. " more cases")
    runCases(extra)
end)

-- ===================================================================== 6. held in: room for less than the full card
local held = {}
step(5, function()
    backToLoot()
    origMaxC, origMaxW = cw()._maxWinW, ww()._maxWinW
    -- room for the inventory's minimum and 300 units of drawer
    cw()._maxWinW = T.px(36 + 36 + 200 + 300)
    ww()._maxWinW = T.px(36 + 36 + 200 + 300)
    for _, id in ipairs(tabsOf(cw()._tabStripPanel)) do
        if id ~= "loot" then held[#held + 1] = { name = "held in: Character " .. id, acted = "c", want = "half", open = function() charTab(id) end, close = function() charTab("loot") end } end
    end
    for _, id in ipairs(tabsOf(ww()._actionTabStrip)) do
        if id ~= "loot" then held[#held + 1] = { name = "held in: World " .. id, acted = "w", want = "half", open = function() worldTab(id) end, close = function() worldTab("loot") end } end
    end
    say(#held .. " held-in cases")
    runCases(held)
end)

-- ===================================================================== put everything back
step(10, function()
    if origMaxC then cw()._maxWinW = origMaxC end
    if origMaxW then ww()._maxWinW = origMaxW end
    pcall(function() if MT.isPopoutOpen(ww()) then MT.closePopout(ww()) end end)
    pcall(function() ST.unbind(p) end)
    pcall(function() if ZeD_WorldWindow.closeObjectCard then ZeD_WorldWindow.closeObjectCard() end end)
    backToLoot()
    moveTo(walkHome.x, walkHome.y, walkHome.z)
    p:setPrimaryHandItem(nil)
    for _, o in ipairs(placed) do
        pcall(function() local sq = o:getSquare(); if sq then sq:transmitRemoveItemFromSquare(o) end end)
        pcall(function() if instanceof(o, "IsoGenerator") then o:remove() end end)
    end
    for _, it in ipairs(added) do
        local c = it:getContainer()
        if c then pcall(function() c:Remove(it) end) end
    end
end)
step(60, function() whenStill(function()
    local now = bothGeo()
    check(same(now.c, base.c) and same(now.w, base.w), "after the whole run both windows are where and as big as they were (" .. gs(base.c) .. " / " .. gs(base.w) .. " -> " .. gs(now.c) .. " / " .. gs(now.w) .. ")")
    say("skipped, the thing was not there to open: " .. (#skipped > 0 and table.concat(skipped, ", ") or "none"))
    say(fails == 0 and "ALL PASS" or (fails .. " FAILED"))
    if not winsWere and ZeD_CharacterWindow.isOpen() then ZeD_CharacterWindow.toggleBothPaired(pn) end
    say("DONE")
end) end)

local function onTick()
    if waitT > 0 then waitT = waitT - 1; return end
    qi = qi + 1
    local s = Q[qi]
    if not s then Events.OnTick.Remove(onTick); return end
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
    waitT = s.n
end
Events.OnTick.Add(onTick)
say("start")
