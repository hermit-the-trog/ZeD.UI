-- ZeDUI/tools/qa/gallery_v1_c3_a.lua  (Nov 17 2026, QA): the ZeD-GUI 1.0 gallery's lived-in retakes, part a: chapters
-- 60 Two-Way Radios, 62 Keeping Count, 72 Hidden Actions and 74 The Survival Guide, at the West Point Fossoil
-- (gallery_story_stage.lua's Angel and spots). Same content and settings as the captures they replace; the new rule:
-- the window sits to one side (C3.side / C3.sideX) and the character and the place stay uncovered.
--   60  zqa_tw_1b_valutech_tab         behind the counter (spot clerk): the ValuTech in the hand, on, the Character
--                                      window's Radio tab grown to show the whole face (zedqa_twoway.lua 1b)
--       zqa_tw_3a_valutech_full_view   the same set in full view, beside the player (3a); the windows still open
--       zqa_tw_5_ham_civilian_tab      the three ham sets placed beside Angel, the World window's Radio tab on the
--                                      civilian set, on (5)
--   62  journal_kills_1                the forecourt (spot smoke), Light + Blue (the card's cast): the Character window
--                                      alone, 1.5x tall, on the Journal tab, Zombies killed expanded with the same seeded
--                                      kills (gallery_journal_kills.lua: 208 + 4 by fire = 212)
--   72  zqa_cw_29_hair_beard_folded    behind the counter: Identity tab, Hair and beard, no scissors or razor in reach,
--       zqa_cw_30_hair_beard_show_all  Hidden actions folded, then Show all (zedqa_cohesion_walk.lua 7)
--   74  gb_1_title (zqa_b83_3840x2160_D1_title), gb_2_contents_p1p2 (D2_contents), gb_3_chapter_opener
--       (D3_chapter_opener_clip), gb_4_skill_books_rules (D4_skill_books_rules), gb_5_shared_page (spread_07): the book
--       (Full), all from behind the counter, the book moved to one side of the screen (its own layout, shifted)
--       gw_zqa_g82s_<w>x<h>_2b_skill_books_rules_full, gw_zqa_g82s_<w>x<h>_4_find_book: the guide window (Simple), Skill
--       Books scrolled to the rules table, then Find narrowed to "book" (zedqa_guide82_stills.lua)
-- The book names are saved under the gallery names (gallery_b13_collect.ps1's aliases on the left).
-- Puts back: hands, radios and ham sets, the full view's saved place, the window heights, places and tabs, the kills,
-- the theme, the Hidden actions option and the Hair and beard folds, the scissors and razors, the guide look and video
-- effects, the place. grep "ZEDQA c3a".
if not C3 then print("ZEDQA c3a ERR run gallery_v1_c3_common.lua first"); print("ZEDQA c3a DONE"); return end
local Q = C3.make("c3a", 1500000)
local A = { added = {}, placed = {}, hams = {}, stash = {}, settle = {} }
A.C = C3
A.p, A.pn, A.core = C3.p, C3.pn, C3.core
A.TW, A.F, A.RT = ZeD.TwoWay, ZeD.TwoWayFull, ZeD.RadioTab
A.HAMS = { { ft = "Base.HamRadio1", pid = "ham_civilian", spr = "appliances_com_01_0" },
           { ft = "Base.HamRadio2", pid = "ham_army", spr = "appliances_com_01_8" },
           { ft = "Base.HamRadioMakeShift", pid = "ham_makeshift", spr = "appliances_com_01_56" } }

function A.tw(w) return w and w._radioTw end
function A.hitOf(t, id) for _, h in ipairs((t and t.hits) or {}) do if h.id == id then return h end end; return nil end
function A.click(w, id)
    local h = A.hitOf(A.tw(w), id)
    if not h then Q.say("ERR no control " .. id .. " on the face"); return false end
    A.RT.onClick(w, h.x + math.floor(h.w / 2), h.y + math.floor(h.h / 2))
    return true
end
-- the drawer has stopped growing (its width the same three frames running)
function A.settled(w)
    local e = math.floor(w and w._drawerEffW or -1)
    local s = A.settle[w] or { v = -2, n = 0 }
    A.settle[w] = s
    if e == s.v then s.n = s.n + 1 else s.v, s.n = e, 0 end
    return s.n >= 3 and e > 0
end
function A.newRadio(ft, charge)
    local it = A.p:getInventory():AddItem(ft)
    if not it then Q.say("ERR could not make " .. ft); return nil end
    A.added[#A.added + 1] = it
    local dd = it:getDeviceData()
    if dd then
        dd:setHasBattery(true); dd:setPower(charge or 0.6); dd:setIsTurnedOn(false); dd:setMicIsMuted(true); dd:setDeviceVolume(0.5)
        local pc = dd:getDevicePresets()
        if pc then pc:getPresets():clear() end
    end
    return it
end
function A.hold(it)
    A.p:setPrimaryHandItem(nil); A.p:setSecondaryHandItem(nil)
    if it then A.p:setPrimaryHandItem(it) end
end

-- ===================================================================== setup
Q.step(10, function()
    local p = A.p
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    A.look = { ZeD.currentBase, ZeD.currentAccent, ZeD.currentSize }
    A.wins = C3.snapWins()
    A.prim, A.sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    A.popWas = p:getModData().ZeD_TwoWayFull
    A.home = { x = p:getX(), y = p:getY(), z = p:getZ() }
    A.video = A.core:getOptionDoVideoEffects()
    pcall(function() A.guideLook = ZeD.Settings.guideStyleOption:getValue() end)
    pcall(function() A.hiddenWas = ZeD.Settings.hiddenActionsOption:getValue() end)
    C3.theme((GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "teal", A.look[3])
    C3.listView(true)
    Q.say("look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. " | " .. C3.where())
end)

-- ===================================================================== 60 Two-Way Radios (behind the counter)
Q.step(5, function()
    C3.go(Q, "clerk", "SE")
    C3.pairOpen()
    A.p:getModData().ZeD_TwoWayFull = nil           -- the first time: beside the player
    pcall(function() A.F.close(A.pn) end)
    A.hold(nil)
    A.hWas = { c = C3.CW():getHeight(), w = C3.WW():getHeight() }
    Q.hold = C3.pairSide
end)
Q.step(60, function()
    A.valu = A.newRadio("Base.WalkieTalkie2", 0.6)
    A.hold(A.valu)
end)
Q.waitFor(5, 200, function() local r = C3.CW()._radios and C3.CW()._radios[1]; return r ~= nil and r.radioInstance == A.valu end,
    function(ok) if not C3.charTab("radio") then Q.say("ERR no Radio tab on the Character window") end end)
Q.waitFor(5, 200, function() local t = A.tw(C3.CW()); return t ~= nil and t.dev == A.valu and A.settled(C3.CW()) end,
    function(ok) A.click(C3.CW(), "vol") end)
-- grow both windows so the whole face and its fill blocks show (as zedqa_twoway.lua does for 1b)
Q.step(15, function()
    local w, t = C3.CW(), A.tw(C3.CW())
    if not t then Q.say("ERR the ValuTech face is not drawn"); return end
    Q.say("valutech on " .. tostring(A.valu:getDeviceData():getIsTurnedOn()))
    local need = (2 * A.TW.PAD + t.des.h) * t.k + ZeD.T.px(22)
    local fillH = 0
    pcall(function() fillH = A.RT.renderFill(nil, w, t, 0, 0, t.view.w - (ZeD.T.sp.scrollbarW or 0) - ZeD.T.px(16)) or 0 end)
    if fillH > 0 then need = need + fillH + ZeD.T.px(6) end
    if need > t.view.h then
        local add = need - t.view.h + 2
        w:setHeight(w:getHeight() + add); C3.WW():setHeight(C3.WW():getHeight() + add)
    end
    Q.say(string.format("valutech: the face and fill need %d px (body %d)", need, t.view.h))
end)
Q.still(20, function()
    local w = C3.CW()
    if w._radioScroll and w._radioScroll.visible then Q.say("note: 1b: the Radio tab still scrolls") end
    Q.shot("zqa_tw_1b_valutech_tab")
end)
Q.step(5, function()
    local z = C3.CW()._radioFullZone
    if z then A.RT.onClick(C3.CW(), z.x + 2, z.y + 2) else Q.say("ERR no full view button in the header") end
end)
Q.step(30, function()
    A.v = A.F.get(A.pn)
    if not (A.v and A.v:isReallyVisible()) then Q.notTaken("zqa_tw_3a_valutech_full_view", "full view did not open"); return end
    -- full view sits beside the player; kept clear of the character and of the windows on the left
    local hold = function()
        C3.pairSide()
        local v = A.v
        if v and v:isReallyVisible() and C3.covers(v) then v:setX(C3.sideX(v:getWidth(), "right")) end
    end
    Q.hold = hold
end)
Q.step(20, function()
    if not (A.v and A.v:isReallyVisible()) then return end
    Q.shot("zqa_tw_3a_valutech_full_view", { { "fullview", A.v } })
end)
Q.step(5, function()
    pcall(function() A.F.close(A.pn) end)
    A.v = nil
    Q.hold = C3.pairSide
    A.hold(nil)
end)
-- the three ham sets on free squares beside Angel that the World window reaches
Q.step(20, function()
    local p = A.p
    local x0, y0, z0 = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local here = p:getCurrentSquare()
    local spots = {}
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }) do
        local sq = getCell():getGridSquare(x0 + d[1], y0 + d[2], z0)
        if sq and sq:isFree(false) and here and here:canReachTo(sq) then spots[#spots + 1] = sq end
    end
    Q.say(#spots .. " free squares in reach")
    for i, h in ipairs(A.HAMS) do
        local sq = spots[i]
        local it = instanceItem(h.ft)
        if sq and it then
            local d = it:getDeviceData()
            d:setHasBattery(true); d:setPower(0.8); d:setIsTurnedOn(false); d:setMicIsMuted(true)
            local obj = IsoRadio.new(getCell(), sq, getSprite(h.spr))
            obj:setDeviceData(d)
            sq:AddTileObject(obj)
            A.placed[#A.placed + 1] = obj
            A.hams[h.pid] = obj
        end
    end
    Q.say("placed " .. #A.placed .. " ham sets")
end)
Q.waitFor(5, 200, function()
    local n = 0
    for _, r in ipairs(C3.WW()._radios or {}) do for _, o in pairs(A.hams) do if r.radioInstance == o then n = n + 1 end end end
    return n == #A.placed and n > 0
end, function(ok) if not C3.worldTab("radio") then Q.say("ERR no Radio tab on the World window") end end)
Q.step(5, function()
    for i, r in ipairs(C3.WW()._radios or {}) do if r.radioInstance == A.hams.ham_civilian then C3.WW()._radioIdx = i end end
end)
Q.waitFor(5, 200, function() local t = A.tw(C3.WW()); return t ~= nil and t.dev == A.hams.ham_civilian and A.settled(C3.WW()) end,
    function(ok)
        if not A.hams.ham_civilian then return end
        if not A.hams.ham_civilian:getDeviceData():getIsTurnedOn() then A.click(C3.WW(), "vol") end
    end)
Q.still(15, function()
    if not A.hams.ham_civilian then Q.notTaken("zqa_tw_5_ham_civilian_tab", "no free square for the civilian ham set"); return end
    Q.say("ham_civilian on " .. tostring(A.hams.ham_civilian:getDeviceData():getIsTurnedOn()))
    Q.shot("zqa_tw_5_ham_civilian_tab")
end)
Q.step(10, function()
    Q.hold = nil
    for _, obj in ipairs(A.placed) do
        local sq = obj:getSquare()
        if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end
    end
    A.placed, A.hams = {}, {}
    for _, it in ipairs(A.added) do local c = it:getContainer(); if c then c:Remove(it) end end
    A.added = {}
    A.hold(nil)
    pcall(function() A.p:setPrimaryHandItem(A.prim); A.p:setSecondaryHandItem(A.sec) end)
    A.p:getModData().ZeD_TwoWayFull = A.popWas
    pcall(function() C3.CW():setHeight(A.hWas.c); C3.WW():setHeight(A.hWas.w) end)
    C3.charTab("loot"); C3.worldTab("loot")
    Q.say("60 put back: sets taken away, heights back")
end)

-- ===================================================================== 62 Keeping Count (the forecourt, Light + Blue)
Q.step(20, function()
    local p = A.p
    C3.go(Q, "smoke", "SE")
    A.md = p:getModData()
    A.killsWas = A.md.ZeD_Kills
    A.countWas = p:getZombieKills()
    C3.pairOpen()
    if C3.WWm.isOpen() then pcall(C3.WWm.close, C3.pn) end
    C3.theme("light", "blue")
    local c = C3.CW(); if c then c._accentKey = "blue" end
    local kills = { weapon = { Blunt = 38, SmallBlunt = 9, LongBlade = 21, SmallBlade = 14, Axe = 46, Spear = 11, Firearm = 52, Unarmed = 6, Other = 3 },
                    fire = 4, vehicle = 6, explosion = 2, v = 2 }
    local sum = 0
    for _, n in pairs(kills.weapon) do sum = sum + n end
    A.md.ZeD_Kills = kills
    p:setZombieKills(sum + kills.vehicle + kills.explosion)
    Q.say(string.format("seeded: game count %d + fire %d | look %s %s", sum + kills.vehicle + kills.explosion, kills.fire, tostring(ZeD.currentBase), tostring(ZeD.currentAccent)))
end)
Q.step(30, function()
    local w = C3.CW()
    if not (w and C3.charTab("journal")) then Q.say("ERR no Journal tab") end
end)
Q.step(5, function()
    local w = C3.CW()
    if not w then return end
    A.jWas = { exp = w._killsExpanded, sub = w._journalSubTab, h = w:getHeight() }
    local sh = A.core:getScreenHeight()
    local nh = math.min(math.floor(w:getHeight() * 1.5), sh - 200)
    w:setHeight(nh)
    pcall(function() w:onResize() end)
    w:setY(math.floor((sh - nh) / 3))
    w._journalSubTab = 1
    w._killsExpanded = true
    w._journalCache = nil
    pcall(function() w._journalScroll:setScrollPos(0) end)
    Q.hold = function() C3.side({ { C3.CW(), "char" } }, "left") end
end)
Q.still(60, function()
    local w = C3.CW()
    Q.say("journal tab " .. tostring(w and w._activeTab) .. " sub " .. tostring(w and w._journalSubTab) .. " expanded " .. tostring(w and w._killsExpanded))
    Q.shot("journal_kills_1")
end)
Q.step(5, function()
    Q.hold = nil
    local w = C3.CW()
    pcall(function() A.md.ZeD_Kills = A.killsWas end)
    pcall(function() A.p:setZombieKills(A.countWas) end)
    if w and A.jWas then
        w._killsExpanded = A.jWas.exp; w._journalSubTab = A.jWas.sub or 1; w._journalCache = nil
        pcall(function() w:setHeight(A.jWas.h); w:onResize() end)
    end
    C3.charTab("loot")
    C3.theme((GAL_LOOK and GAL_LOOK[1]) or "dark", (GAL_LOOK and GAL_LOOK[2]) or "teal", A.look[3])
    C3.pairOpen()
    Q.say("62 put back: kills " .. tostring(A.p:getZombieKills()) .. ", look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent))
end)

-- ===================================================================== 72 Hidden Actions (behind the counter)
function A.stashTools()
    local inv = A.p:getInventory()
    local preds = {
        function(it) return not it:isBroken() and (it:hasTag(ItemTag.SCISSORS) or it:getType() == "Scissors") end,
        function(it) return not it:isBroken() and (it:hasTag(ItemTag.RAZOR) or it:getType() == "Razor") end,
    }
    for _, pred in ipairs(preds) do
        for _ = 1, 8 do
            local ok, it = pcall(function() return inv:getFirstEvalRecurse(pred) end)
            if not (ok and it) then break end
            local c = it:getContainer()
            if not c then break end
            c:Remove(it)
            A.stash[#A.stash + 1] = { item = it, container = c }
        end
    end
    Q.say("hair: " .. #A.stash .. " scissors / razor set aside")
end
Q.step(20, function()
    C3.go(Q, "clerk", "SE")
    C3.pairOpen()
    A.stashTools()
    local DS = ZeD.Disclose
    A.hairOpenWas = {}
    for _, k in ipairs({ "hb:more:hair", "hb:more:beard" }) do
        A.hairOpenWas[k] = (DS and DS.isOpen(k)) and true or false
        if DS then DS.setOpen(k, false) end
    end
    pcall(function() ZeD.Settings.hiddenActionsOption:setValue(1) end)
    C3.charTab("identity")
    Q.hold = C3.pairSide
end)
Q.still(40, function()
    local c = C3.CW()
    if ZeD.HairBeard and c then pcall(ZeD.HairBeard.setPart, c, "hair") end
    if c and c._identityScroll then c._identityScroll:setScrollPos(0) end
end)
Q.step(45, function()
    local c = C3.CW()
    local st = c and ZeD.HairBeard and ZeD.HairBeard.state(c)
    local v = c and c._idView
    A.hairOff = (st and st.top and v) and (st.top - v.y) or nil
    if c and c._identityScroll then c._identityScroll:setScrollPos(1) end
end)
Q.step(12, function()
    local c = C3.CW()
    local maxOff = c and c._identityScrollOff or 0
    if c and c._identityScroll and A.hairOff and maxOff > 0 then
        c._identityScroll:setScrollPos(math.max(0, math.min(1, (A.hairOff - ZeD.T.px(4)) / maxOff)))
    end
end)
Q.still(30, function() Q.shot("zqa_cw_29_hair_beard_folded") end)
Q.step(2, function() pcall(function() ZeD.Settings.hiddenActionsOption:setValue(2) end) end)
Q.still(15, function() Q.shot("zqa_cw_30_hair_beard_show_all") end)
Q.step(5, function()
    Q.hold = nil
    if A.hiddenWas then pcall(function() ZeD.Settings.hiddenActionsOption:setValue(A.hiddenWas) end) end
    for i = #A.stash, 1, -1 do local s = A.stash[i]; pcall(function() s.container:AddItem(s.item) end) end
    Q.say("hair: " .. #A.stash .. " scissors / razor put back")
    A.stash = {}
    local DS = ZeD.Disclose
    for k, was in pairs(A.hairOpenWas or {}) do if DS then DS.setOpen(k, was) end end
    C3.charTab("loot")
end)

-- ===================================================================== 74 The Survival Guide (behind the counter)
-- the book's own layout, then the whole book moved to one side of the screen (left, else right) clear of Angel
function A.shiftBook(bk)
    local g = bk._g
    if not (g and g.book) then return end
    local W, m = A.core:getScreenWidth(), C3.m()
    local bw = g.book.w
    local want = C3.sideX(bw + 2 * m, "left") + m
    local dx = want - g.book.x
    if dx == 0 then return end
    for _, k in ipairs({ "book", "left", "right", "strip" }) do if g[k] then g[k].x = g[k].x + dx end end
    A.bookBox = { x = g.book.x, y = g.book.y, w = bw, h = g.book.h + (g.strip and (g.strip.y + g.strip.h - g.book.y - g.book.h) or 0) }
end
function A.bookLog(name)
    local b = A.bookBox
    if not b then Q.say("box " .. name .. " book: not shifted"); return end
    Q.say(string.format("box %s book %d,%d-%d,%d%s", name, b.x, b.y, b.x + b.w, b.y + b.h, C3.hits(b.x, b.y, b.w, b.h) and " COVERS the character" or ""))
end
function A.Bk() return ZeD.GuideBook and ZeD.GuideBook.books[0] end
Q.step(20, function()
    C3.pairShut()
    pcall(function() ZeD.Settings.guideStyleOption:setValue(1) end)
    A.core:setOptionDoVideoEffects(true)
    local ok, e = pcall(ZeD.GuideBook.open, 0)
    if not ok then Q.say("ERR the book did not open: " .. tostring(e)) end
end)
Q.step(30, function()
    local bk = A.Bk()
    if not bk then Q.say("ERR no book"); return end
    bk.layout = function(self) ZeD_GuideBook.layout(self); A.shiftBook(self) end
    bk.spread = 1
    Q.say("book open, spreads " .. tostring(#(bk.pages or {}) / 2))
end)
Q.step(40, function() if A.Bk() then Q.shot("gb_1_title"); A.bookLog("gb_1_title") end end)
Q.step(10, function() if A.Bk() then A.Bk().spread = 2 end end)
Q.step(40, function() if A.Bk() then Q.shot("gb_2_contents_p1p2"); A.bookLog("gb_2_contents_p1p2") end end)
Q.step(10, function()
    local b = A.Bk()
    if b and b.sections and b.sections[4] then
        b.spread = math.floor((b.sectionPage[b.sections[4].id] + 1) / 2)
        Q.say("chapter opener: " .. tostring(b.sections[4].title))
    end
end)
Q.step(150, function() if A.Bk() then Q.shot("gb_3_chapter_opener"); A.bookLog("gb_3_chapter_opener") end end)
Q.step(10, function()
    local b = A.Bk()
    for _, t in ipairs((b and b.flat) or {}) do if t.titleKey == "SurvivalGuide_skill_books_title" then b:goToTopic(t.id) end end
end)
Q.step(120, function() if A.Bk() then Q.shot("gb_4_skill_books_rules"); A.bookLog("gb_4_skill_books_rules") end end)
Q.step(10, function() local b = A.Bk(); if b then b.spread = math.min(7, math.floor(#b.pages / 2)) end end)
Q.step(40, function() if A.Bk() then Q.shot("gb_5_shared_page"); A.bookLog("gb_5_shared_page") end end)
Q.step(10, function()
    local b = A.Bk()
    if b then b.layout = nil end
    pcall(ZeD.GuideBook.close, 0)
end)
-- the guide window (Simple), as zedqa_guide82_stills.lua's 2b and 4
function A.Wn() return ZeD.Guide.get(0) end
function A.topicBy(key) local w = A.Wn(); for _, t in ipairs((w and w.flat) or {}) do if t.titleKey == key then return t end end; return nil end
A.gw = "gw_zqa_g82s_" .. A.core:getScreenWidth() .. "x" .. A.core:getScreenHeight() .. "_"
Q.step(20, function()
    pcall(function() ZeD.Settings.guideStyleOption:setValue(2) end)
    local ok, e = pcall(ZeD.Guide.openWindow, 0)
    if not ok then Q.say("ERR the guide window did not open: " .. tostring(e)) end
    Q.hold = function() local w = A.Wn(); if w and C3.vis(w) then C3.side({ { w, "guide" } }, "left") end end
end)
Q.step(20, function()
    local w, t = A.Wn(), A.topicBy("SurvivalGuide_skill_books_title")
    if w and t then w:choose(t.id, true) end
end)
Q.step(150, function()
    local w = A.Wn()
    if not w then return end
    local y = nil
    for _, it in ipairs((w._g and w._g.items) or {}) do if it.kind == "rules" then y = it.y; break end end
    w.scroll = math.min(w._maxS or 0, math.max(0, (y or (w._maxS or 0)) - ZeD.T.px(60)))
    Q.say("2b: rules table at " .. tostring(y) .. ", scroll " .. tostring(w.scroll) .. " of " .. tostring(w._maxS))
end)
Q.step(60, function()
    local w = A.Wn()
    if w and C3.vis(w) then Q.shot(A.gw .. "2b_skill_books_rules_full", { { "guide", w } }) else Q.notTaken(A.gw .. "2b_skill_books_rules_full", "no guide window") end
    if w then w.scroll = 0 end
end)
Q.step(10, function()
    local w = A.Wn()
    if not w then return end
    local t = A.topicBy("SurvivalGuide_skill_books_title"); if t then w:choose(t.id, true) end
    pcall(function() w._findField.input:setText("book") end)
    pcall(function() w._findField.onFilter(w._findField, "book") end)
end)
Q.step(120, function()
    local w = A.Wn()
    if w and C3.vis(w) then Q.shot(A.gw .. "4_find_book", { { "guide", w } }) else Q.notTaken(A.gw .. "4_find_book", "no guide window") end
end)
Q.step(10, function()
    Q.hold = nil
    local w = A.Wn()
    if w then
        pcall(function() w._findField.input:setText("") end)
        pcall(function() w._findField.onFilter(w._findField, "") end)
        pcall(function() w:close() end)
    end
end)

-- ===================================================================== put back
Q.mark()
Q.step(20, function()
    Q.hold = nil
    pcall(function() A.F.close(A.pn) end)
    pcall(function() local b = A.Bk(); if b then b.layout = nil end; ZeD.GuideBook.close(0) end)
    pcall(function() local w = A.Wn(); if w and w:isVisible() then w:close() end end)
    for _, obj in ipairs(A.placed) do local sq = obj:getSquare(); if sq then pcall(function() sq:transmitRemoveItemFromSquare(obj) end) end end
    for _, it in ipairs(A.added) do pcall(function() local c = it:getContainer(); if c then c:Remove(it) end end) end
    for i = #A.stash, 1, -1 do local s = A.stash[i]; pcall(function() s.container:AddItem(s.item) end) end
    A.placed, A.added, A.stash = {}, {}, {}
    pcall(function() A.p:setPrimaryHandItem(A.prim); A.p:setSecondaryHandItem(A.sec) end)
    A.p:getModData().ZeD_TwoWayFull = A.popWas
    if A.killsWas ~= nil or A.countWas then pcall(function() A.md.ZeD_Kills = A.killsWas; A.p:setZombieKills(A.countWas) end) end
    if A.hiddenWas then pcall(function() ZeD.Settings.hiddenActionsOption:setValue(A.hiddenWas) end) end
    if A.guideLook then pcall(function() ZeD.Settings.guideStyleOption:setValue(A.guideLook) end) end
    pcall(function() A.core:setOptionDoVideoEffects(A.video) end)
    C3.listView(false)
    C3.theme(A.look[1], A.look[2], A.look[3])
    pcall(function() STORY.tp(A.home.x, A.home.y, A.home.z) end)
end)
Q.step(20, function()
    C3.backWins(A.wins)
    Q.say("put back: hands, radios, ham sets, full view place, kills, Hidden actions, tools, guide look, video effects "
        .. tostring(A.core:getOptionDoVideoEffects()) .. ", look " .. tostring(ZeD.currentBase) .. " " .. tostring(ZeD.currentAccent) .. ", windows, place")
end)
Q.start()
