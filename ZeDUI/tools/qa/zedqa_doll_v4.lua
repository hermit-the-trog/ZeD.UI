-- ZeDUI/tools/qa/zedqa_doll_v4.lua  (Oct 29 2026)
-- In game on the ZeD-QA save: the Equip tab's doll with its bands of small slots (EquipDoll.lua, handoff
-- ZeDUI/HANDOFF_equip_doll_v4_loadouts_20261029.md part A). Dresses the character in things from every small
-- slot's place (a belly button ring, an air tank, a tail, sport shoulder pads and the pair worn on top,
-- rings, a watch, knee / elbow / shin pads, a fanny pack, a shoulder holster, necklaces ...) and checks:
--   * the 38 small slots exist, with their words, and no slot (big or small) overlaps another
--   * every worn thing lands in its small slot (layers where two share one) and, folded, in its big slot
--   * Arms sits above Belt, no leader line crosses another
--   * a small slot's card opens (the pad's A) and steps its layers
--   * the D-pad walks into and out of both bands, reaches all 49 slots and leaves at the outer edges
--   * a dropped item that fits wears there (the drop handler's hook), one that doesn't is refused
--   * a narrow drawer folds the bands away: no small slots, every item a layer in its big slot
-- Waits for the windows to stop moving before each screenshot (zqa_dollv4_<W>x<H>_*.png). Everything worn
-- is taken off again, the view and the window cap put back. grep "ZEDQA dollv4"; PASS / FAIL lines.
local p = getPlayer()
local pn = p:getPlayerNum()
local inv = p:getInventory()
local Focus, Det, Doll = ZeD.Input.Focus, ZeD.Input.Detector, ZeD.EquipDoll
local T = ZeD.T
local function say(s) print("ZEDQA dollv4 " .. tostring(s)) end
local passN, failN = 0, 0
local function check(name, ok, extra)
    if ok then passN = passN + 1 else failN = failN + 1 end
    say((ok and "PASS " or "FAIL ") .. name .. (extra ~= nil and (" | " .. tostring(extra)) or ""))
end
local function cw() return ZeD_CharacterWindow.getWindow() end
local SW, SH = getCore():getScreenWidth(), getCore():getScreenHeight()
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_dollv4_" .. SW .. "x" .. SH .. "_" .. n .. ".png") end) end

-- the queue: { n = ticks to wait, fn }; whenStill puts a poll next in line (the windows the same for STILL ticks)
local Q, qi, waitT = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function insertNext(n, fn) table.insert(Q, qi + 1, { n = n, fn = fn }) end
local STILL, STILL_MAX = 30, 900
local function shape()
    local w = cw()
    if not (w and w:isVisible()) then return "none" end
    local dp = w._drawerPanel
    return string.format("%d,%d,%d,%d,%d,%d,%s", w:getX(), w:getY(), w:getWidth(), w:getHeight(),
        math.floor(w._drawerEffW or 0), dp and dp:getWidth() or 0, tostring(w._equipDollBands))
end
local function whenStill(fn)
    local last, same, waited = nil, 0, 0
    local function poll()
        local s = shape()
        if s == last then same = same + 1 else same, last = 0, s end
        waited = waited + 1
        if same >= STILL or waited >= STILL_MAX then
            if same < STILL then say("WARN the window was still moving after " .. waited .. " ticks: went ahead") end
            fn()
        else
            insertNext(0, poll)
        end
    end
    insertNext(0, poll)
end

local function tab(id)
    local w = cw(); local strip = w and w._tabStripPanel
    for _, z in ipairs(strip and strip._hitZones or {}) do
        if z.id == "tab:" .. id then if w._activeTab ~= id then strip:onMouseDown(z.x + 2, z.y + 2) end; return true end
    end
end
local function zone(w, name)
    for i, z in ipairs(w._focusRing or {}) do if z.zone == name then return i, z end end
end
local function focusId(id)
    local w = cw(); local zi, z = zone(w, "charTabContent")
    for ei, el in ipairs(z and z.elements or {}) do
        if el.id == id then w._focusIdx = zi; z.focusedElementIdx = ei; if el.onFocus then el.onFocus(w, el) end; return el, ei end
    end
end
local function focusedId()
    local w = cw(); local e = Focus.getFocusedElement(w)
    return e and e.id or "nil"
end

-- what to wear: { full type, its small slot, its big slot (folded) }. The game keeps some places apart (the sport
-- shoulder pads exclude the air tank, the webbing, the shoulder holster and the shoulder pads; a knee pad
-- excludes the shin), so the character is dressed in rounds.
local ROUND1 = {
    { "Base.BellyButton_DangleGold",        "belly",   "torso" },
    { "Base.SCBA",                          "airtank", "back" },
    { "Base.BunnyTail",                     "tail",    "back" },
    { "Base.Bag_LeatherWaterBag",           "satchel", "back" },
    { "Base.Ring_Left_RingFinger_Gold",     "lring",   "hands" },
    { "Base.Ring_Right_MiddleFinger_Silver", "rmiddle", "hands" },
    { "Base.WristWatch_Left_ClassicBlack",  "wristl",  "arms" },
    { "Base.ElbowPad_Right",                "elbowr",  "arms" },
    { "Base.Vambrace_BodyArmour_Right",     "forearmr", "arms" },
    { "Base.Kneepad_Right",                 "kneer",   "legs" },
    { "Base.ThighBodyArmour_L",             "thighl",  "legs" },
    { "Base.Shinpad_L",                     "shinl",   "legs" },
    { "Base.Gaiter_Right",                  "gaiterr", "legs" },
    { "Base.Bag_FannyPackFront",            "fpfront", "belt" },
    { "Base.AmmoStrap_Bullets",             "ammo",    "belt" },
    { "Base.HolsterSimple",                 "beltholster", "belt" },
    { "Base.HolsterAnkle",                  "ankleholster", "belt" },
    { "Base.Locket",                        "necklace", "neck" },
    { "Base.IceHockeyNeckGuard",            "gorget",  "neck" },
    { "Base.Earring_LoopLrg_Gold",          "ears",    "head" },
    { "Base.NoseStud_Gold",                 "nose",    "head" },
}
local ROUND2 = { { "Base.Shoulderpads_FootballOnTop", "padsport", "arms" } }   -- (the air tank off first)
local ROUND3 = { { "Base.Bag_ALICE_BeltSus", "webbing", "belt" } }         -- (the sport pads and the fanny pack off first)
local ROUND4 = {                                                              -- (the webbing off first)
    { "Base.Shoulderpad_Football_L",        "padl",    "arms" },
    { "Base.Shoulderpad_Football_R",        "padr",    "arms" },
}
local ROUND5 = { { "Base.HolsterShoulder", "holster", "outer" } }              -- (the shoulder pads off first)
local added, worn = {}, {}       -- everything made; { item, small, big, type } of what is on
local origView, origMax = Doll.view(), nil
local realGather = Doll.gather

local function wearList(list)
    local n = 0
    for _, w in ipairs(list) do
        local it = inv:AddItem(w[1])
        if it then
            added[#added + 1] = it
            pcall(function() p:setWornItem(it:getBodyLocation(), it) end)
            if p:isEquippedClothing(it) then
                worn[#worn + 1] = { it, w[2], w[3], w[1] }
                n = n + 1
            else
                say("WARN could not wear " .. w[1] .. " (" .. tostring(it:getBodyLocation()) .. "): left out")
            end
        else
            say("WARN no such item " .. w[1])
        end
    end
    triggerEvent("OnClothingUpdated", p)
    cw()._equipDollTimer = 99
    return n
end
local function takeOff(types)
    local want = {}
    for _, t in ipairs(types) do want[t] = true end
    local keep = {}
    for _, e in ipairs(worn) do
        if want[e[4]] then
            pcall(function() p:removeWornItem(e[1]) end)
            pcall(function() inv:Remove(e[1]) end)
        else
            keep[#keep + 1] = e
        end
    end
    worn = keep
    triggerEvent("OnClothingUpdated", p)
    cw()._equipDollTimer = 99
end

local function dataNow(bands)
    return Doll.gather(p, pn, bands)
end
local function has(items, it) for _, x in ipairs(items or {}) do if x == it then return true end end return false end

-- segments of a polyline, axis-aligned: { x1, y1, x2, y2 } with x1 <= x2, y1 <= y2
local function segsOf(pts)
    local out = {}
    for i = 1, #pts - 2, 2 do
        local x1, y1, x2, y2 = pts[i], pts[i + 1], pts[i + 2], pts[i + 3]
        out[#out + 1] = { math.min(x1, x2), math.min(y1, y2), math.max(x1, x2), math.max(y1, y2) }
    end
    return out
end
local function lineCrossings(lines)
    local n = 0
    for a = 1, #lines do
        local sa = segsOf(lines[a])
        for b = a + 1, #lines do
            local sb = segsOf(lines[b])
            for _, s in ipairs(sa) do
                for _, t in ipairs(sb) do
                    if s[1] <= t[3] and t[1] <= s[3] and s[2] <= t[4] and t[2] <= s[4] then n = n + 1 end
                end
            end
        end
    end
    return n
end
local function overlaps(rects)
    local n, firstA, firstB = 0, nil, nil
    for a = 1, #rects do
        local r = rects[a]
        for b = a + 1, #rects do
            local s = rects[b]
            if r.x < s.x + s.w and s.x < r.x + r.w and r.y < s.y + s.h and s.y < r.y + r.h then
                n = n + 1
                if not firstA then firstA, firstB = r.id, s.id end
            end
        end
    end
    return n, firstA, firstB
end
local function rectOf(id)
    for _, r in ipairs(cw()._equipDollAll or {}) do if r.id == id then return r end end
end

-- every worn thing in the slot the mode gives it (bands: its small slot; folded: its big slot) and a card zone there
local function checkSlots(label, bands)
    local d = dataNow(bands)
    local miss = {}
    for _, e in ipairs(worn) do
        local sl = bands and d.small[e[2]] or d.slots[e[3]]
        if not has(sl and sl.items, e[1]) then miss[#miss + 1] = e[4] .. "->" .. (bands and e[2] or e[3]) end
    end
    check(label .. ": every worn thing lands in its " .. (bands and "small" or "big") .. " slot (" .. #worn .. " on)", #miss == 0, table.concat(miss, " "))
    return d
end
local function checkZones(label)
    local w = cw()
    local bands = w._equipDollBands
    local zs = {}
    for _, z in ipairs(w._equipSlotZones or {}) do zs[z.type] = z end
    local nz, names = 0, {}
    for _, e in ipairs(worn) do
        if not zs["doll:" .. (bands and e[2] or e[3])] then nz = nz + 1; names[#names + 1] = e[2] end
    end
    check(label .. ": each has a card zone doll:<slot>", nz == 0, table.concat(names, ","))
end
local function layoutChecks(label, expectBands)
    local w = cw()
    local all = w._equipDollAll or {}
    check(label .. ": bands " .. (expectBands and "show" or "folded"), w._equipDollBands == expectBands,
        "drawer " .. tostring(math.floor(w._drawerEffW or 0)) .. "px = " .. tostring(math.floor((w._drawerEffW or 0) / (T.px(1000) / 1000))) .. " units, screen " .. SW .. "x" .. SH)
    check(label .. ": " .. (expectBands and "49 slot boxes (11 big + 38 small)" or "11 big slot boxes, no small ones"), #all == (expectBands and 49 or 11), #all)
    local nov, oa, ob = overlaps(all)
    check(label .. ": no slot overlaps another", nov == 0, nov > 0 and (tostring(oa) .. " x " .. tostring(ob)) or nil)
    local dp = w._drawerPanel
    local inside = true
    for _, r in ipairs(all) do if r.x < 0 or r.x + r.w > (dp and dp:getWidth() or 0) then inside = false end end
    check(label .. ": every box inside the drawer's width", inside, dp and dp:getWidth())
    local U = T.px(1000) / 1000
    local dUnits = (w._drawerEffW or 0) / U
    check(label .. ": the drawer is no wider than the full card (480 units)", dUnits <= 480.5, string.format("%.1f units", dUnits))
    if expectBands then
        local small = rectOf("ears")
        -- 14 units at the floor: a short window shrinks the doll that far before the tab scrolls (Oct 30 2026)
        check(label .. ": a small slot is 14 units or more on screen", small and small.w / U >= 13.9, small and string.format("%.1f units", small.w / U))
    end
    local lines = w._equipDollLines or {}
    check(label .. ": 11 leader lines, none crossing another", #lines == 11 and lineCrossings(lines) == 0, #lines .. " lines, " .. lineCrossings(lines) .. " crossings")
    local arms, belt, back = rectOf("arms"), rectOf("belt"), rectOf("back")
    check(label .. ": Back, Arms, Belt in that order down the right", arms and belt and back and back.y < arms.y and arms.y < belt.y,
        back and arms and belt and (back.y .. "," .. arms.y .. "," .. belt.y))
    local armsLine, beltLine
    for i, def in ipairs(Doll.SLOTS) do if def.id == "arms" then armsLine = lines[i] elseif def.id == "belt" then beltLine = lines[i] end end
    check(label .. ": arms' line is one straight run, belt's turns up", armsLine and #armsLine == 4 and armsLine[2] == armsLine[4] and beltLine and #beltLine == 8,
        (armsLine and #armsLine or "nil") .. "/" .. (beltLine and #beltLine or "nil"))
end

local function isBig(id)
    for _, s in ipairs(Doll.SLOTS) do if id == "doll:" .. s.id then return true end end
    return false
end
local function smallSide(id)
    for _, sm in ipairs(Doll.SMALL) do if id == "doll:" .. sm.id then return sm.side end end
    return nil
end

-- ---------------------------------------------------------------------------
step(2, function()
    if not (cw() and cw():isVisible()) then ZeD_CharacterWindow.toggleBothPaired(pn) end
end)
step(20, function()
    local n = wearList(ROUND1)
    Det.setLockedMode(Det.MODE_GAMEPAD); Focus.claimFocus(cw())
    tab("equip"); Doll.setView("doll")
    say("round 1: wearing " .. n .. " of " .. #ROUND1)
end)

-- ---- A. the wide doll
step(60, function() whenStill(function()
    local w = cw()
    check("38 small slots defined", #Doll.SMALL == 38, #Doll.SMALL)
    layoutChecks("wide", true)
    local bad = {}
    for _, g in ipairs(Doll.GROUPS) do for _, k in ipairs(g.name) do if ZeD.tr(k) == k then bad[#bad + 1] = k end end end
    for _, sm in ipairs(Doll.SMALL) do if ZeD.tr(sm.place) == sm.place then bad[#bad + 1] = sm.place end end
    check("every group name and place name has its words", #bad == 0, table.concat(bad, ","))
    local d = checkSlots("round 1 wide", true)
    checkZones("round 1 wide")
    checkSlots("round 1 folded (data)", false)
    check("belly button ring, air tank, tail in their small slots", has(d.small.belly.items, worn[1][1]) and #d.small.airtank.items == 1 and #d.small.tail.items == 1)
    say("empties " .. #(w._equipDollEmpty or {}) .. ", slots with things " .. #(w._equipSlotZones or {}))
    shot("wide")
end) end)

-- ---- B. the D-pad (the stops are the same whatever is worn)
step(5, function()
    local w = cw()
    local zi, z = zone(w, "charTabContent")
    check("charTabContent zone exists with the doll's stops", z ~= nil and #(z.elements or {}) > 40, z and #z.elements)
    focusId("equipslot:doll:neck")
    local el = Focus.getFocusedElement(w)
    local took = Doll.dpad(w, el, "left")
    local f = Focus.getFocusedElement(w)
    check("Left from Neck steps into the left band", took and smallSide(f and f.slotType) == "L", f and f.slotType)
    local took2 = Doll.dpad(w, f, "right")
    local g = Focus.getFocusedElement(w)
    check("Right from the band's inner edge returns to a big slot", took2 and g and isBig(g.slotType), g and g.slotType)
    focusId("equipslot:doll:belt")
    el = Focus.getFocusedElement(w)
    took = Doll.dpad(w, el, "right")
    f = Focus.getFocusedElement(w)
    check("Right from Belt steps into the right band", took and smallSide(f and f.slotType) == "R", f and f.slotType)
    took2 = Doll.dpad(w, f, "left")
    g = Focus.getFocusedElement(w)
    check("Left from the right band's inner edge returns to a big slot", took2 and g and isBig(g.slotType), g and g.slotType)
    -- reach every stop by the doll's own moves (breadth first over the four directions)
    local els = z.elements
    local idxOf = {}
    for i, e in ipairs(els) do idxOf[e.slotType or e.id] = i end
    local start = idxOf["doll:head"]
    local seen, queue, qh = { [start] = true }, { start }, 1
    local DIRS = { "up", "down", "left", "right" }
    while qh <= #queue do
        local cur = queue[qh]; qh = qh + 1
        for _, dir in ipairs(DIRS) do
            focusId(els[cur].id)
            local e = Focus.getFocusedElement(w)
            local nx = nil
            if e and Doll.dpad(w, e, dir) then
                nx = z.focusedElementIdx
            elseif e and (dir == "up" or dir == "down") and isBig(e.slotType) then
                -- a big slot's Up / Down is the cone's: the next big slot of its column by height
                local bestD = nil
                for j, o in ipairs(els) do
                    if o ~= e and isBig(o.slotType) and math.abs((o.x or 0) - (e.x or 0)) < 4 then
                        local dy = (dir == "down") and ((o.y or 0) - (e.y or 0)) or ((e.y or 0) - (o.y or 0))
                        if dy > 0 and (not bestD or dy < bestD) then bestD, nx = dy, j end
                    end
                end
            end
            if nx and not seen[nx] and tostring(els[nx].slotType):sub(1, 5) == "doll:" then seen[nx] = true; queue[#queue + 1] = nx end
        end
    end
    local nSmall, nBig, missed, missedBig = 0, 0, {}, {}
    for _, sm in ipairs(Doll.SMALL) do
        if seen[idxOf["doll:" .. sm.id]] then nSmall = nSmall + 1 else missed[#missed + 1] = sm.id end
    end
    for _, s in ipairs(Doll.SLOTS) do
        if seen[idxOf["doll:" .. s.id]] then nBig = nBig + 1 else missedBig[#missedBig + 1] = s.id end
    end
    check("the doll's moves reach all 38 small slots", nSmall == 38, nSmall .. " missed " .. table.concat(missed, ","))
    check("and all 11 big slots (Up / Down in a column are the cone's)", nBig == 11, nBig .. " missed " .. table.concat(missedBig, ","))
    -- the outer edges: the outermost slot of each band row refuses the outward move
    local leaveOk, leaveN = true, 0
    for _, sm in ipairs(Doll.SMALL) do
        local out = (sm.side == "L") and "left" or "right"
        local outer = true
        for _, o in ipairs(Doll.SMALL) do
            if o.side == sm.side and o.y == sm.y and ((sm.side == "L" and o.x < sm.x) or (sm.side == "R" and o.x > sm.x)) then outer = false end
        end
        if outer then
            leaveN = leaveN + 1
            focusId("equipslot:doll:" .. sm.id)
            local e = Focus.getFocusedElement(w)
            if Doll.dpad(w, e, out) then leaveOk = false; say("moved outward from " .. sm.id) end
        end
    end
    check("the outer edge of each band row leaves the doll (" .. leaveN .. " rows)", leaveOk)
end)
-- the real dispatch: Right from Belt goes into the band, Down walks it
step(10, function() focusId("equipslot:doll:belt"); Focus.dispatchJoypadDir(cw(), "right") end)
step(10, function() say("dispatch Right from belt -> " .. focusedId()) end)
step(2, function() Focus.dispatchJoypadDir(cw(), "down") end)
step(10, function() say("then Down -> " .. focusedId()) end)
step(2, function() whenStill(function() shot("dpad") end) end)
step(2, function() focusId("equipslot:doll:lmiddle"); Focus.dispatchJoypadDir(cw(), "left") end)
step(10, function()
    local f = focusedId()
    say("dispatch Left from the left band's outer edge -> " .. f)
    check("the real Left at the outer edge does not land on another doll slot", f == "equipslot:doll:lmiddle" or f:find("equipslot:doll:") == nil, f)
end)

-- ---- C. round 2: the sport shoulder pads worn on top (the air tank off); two layers in one small slot; the card
local extra = nil
step(5, function()
    takeOff({ "Base.SCBA" })
    local n = wearList(ROUND2)
    say("round 2: wearing " .. n .. " of " .. #ROUND2)
    -- a second layer in that slot, as a mod's items could make one (the game keeps the two sport pad places apart)
    extra = inv:AddItem("Base.Shoulderpads_Football"); added[#added + 1] = extra
    Doll.gather = function(pl, pnum, bands)
        local d = realGather(pl, pnum, bands)
        if d.small and d.small.padsport and extra then table.insert(d.small.padsport.items, extra) end
        return d
    end
    cw()._equipDollTimer = 99
end)
step(40, function() whenStill(function()
    local w = cw()
    local d = checkSlots("round 2 wide", true)
    check("the sport pads worn on top show in their small slot", d.small.padsport and has(d.small.padsport.items, worn[#worn][1]))
    check("the air tank is gone from its slot", #d.small.airtank.items == 0)
    check("a second layer shows as a count (2)", d.small.padsport and #d.small.padsport.items == 2, d.small.padsport and #d.small.padsport.items)
    shot("wide_pads")
    local el = focusId("equipslot:doll:padsport")
    check("pad stop for the filled small slot", el ~= nil)
    if el and el.onActivate then el.onActivate(w, el) end
end) end)
step(40, function()
    local w = cw()
    local item, idx, n = Doll.selection(w)
    check("A opens the small slot's card (outermost first)", w._equipSelected == "doll:padsport" and item ~= nil and idx == 1 and n == 2,
        tostring(w._equipSelected) .. " item " .. tostring(item and item:getType()) .. " layer " .. tostring(idx) .. "/" .. tostring(n))
    check("its outermost layer is the pair worn on top", item and item:getType() == "Shoulderpads_FootballOnTop", item and item:getType())
    Doll.stepLayer(w, 1)
    local i2 = select(2, Doll.selection(w))
    check("Inner steps to layer 2", i2 == 2, i2)
end)
step(10, function() whenStill(function() shot("card") end) end)
step(10, function()
    local w = cw()
    w._equipSelected = nil; w._equipLayer = 1; w._equipCache = nil; w._gpFocusedEquipSlot = nil
    Doll.gather = realGather
    w._equipDollTimer = 99
end)

-- ---- D. rounds 3 to 5: webbing; the shoulder pads; the shoulder holster (the game keeps these apart)
step(20, function()
    takeOff({ "Base.Shoulderpads_FootballOnTop", "Base.Bag_FannyPackFront" })
    say("round 3: wearing " .. wearList(ROUND3) .. " of " .. #ROUND3)
end)
step(40, function()
    checkSlots("round 3 wide", true); checkZones("round 3 wide"); checkSlots("round 3 folded (data)", false)
    takeOff({ "Base.Bag_ALICE_BeltSus" })
    say("round 4: wearing " .. wearList(ROUND4) .. " of " .. #ROUND4)
end)
step(40, function()
    checkSlots("round 4 wide", true); checkZones("round 4 wide"); checkSlots("round 4 folded (data)", false)
    takeOff({ "Base.Shoulderpad_Football_L", "Base.Shoulderpad_Football_R" })
    say("round 5: wearing " .. wearList(ROUND5) .. " of " .. #ROUND5)
end)
step(40, function()
    checkSlots("round 5 wide", true); checkZones("round 5 wide"); checkSlots("round 5 folded (data)", false)
end)

-- ---- E. dropping on a slot wears there (the pad's focus scrolls the slot into view first)
local dropped = {}
local function dropOn(id, items)
    local w = cw()
    local r = rectOf(id)
    if not r then return nil, "no rect" end
    local real = w._equipDollPanel
    w._equipDollPanel = { getMouseX = function() return r.x + math.floor(r.w / 2) end, getMouseY = function() return r.y + math.floor(r.h / 2) end }
    local took = Doll.takeDrop(pn, items)
    w._equipDollPanel = real
    return took, string.format("rect %d,%d %dx%d clip %s", r.x, r.y, r.w, r.h, w._equipDollClip and (w._equipDollClip.x .. "," .. w._equipDollClip.y .. " " .. w._equipDollClip.w .. "x" .. w._equipDollClip.h) or "nil")
end
step(5, function()
    local ring = inv:AddItem("Base.Ring_Left_MiddleFinger_Gold"); added[#added + 1] = ring
    local cap = inv:AddItem("Base.Hat_BaseballCapBlue"); added[#added + 1] = cap
    dropped = { ring = ring, cap = cap }
    focusId("equipslot:doll:head")
end)
step(40, function()
    local took, info = dropOn("head", { dropped.cap })
    check("a cap dropped on Head is taken", took == true, info .. " | loc " .. tostring(dropped.cap:getBodyLocation()))
    check("a cap dropped on a small slot that is not its place is refused", dropOn("nose", { dropped.cap }) == false)
    focusId("equipslot:doll:lmiddle")
end)
step(40, function()
    check("a ring dropped on the wrong small slot is refused", dropOn("lring", { dropped.ring }) == false)
    local took, info = dropOn("lmiddle", { dropped.ring })
    check("a ring dropped on its slot is taken", took == true, info)
end)
step(300, function()
    check("the ring was put on (vanilla's wear action ran)", p:isEquippedClothing(dropped.ring))
    check("the cap was put on", p:isEquippedClothing(dropped.cap))
    cw()._equipDollTimer = 99
end)

-- ---- F. the half card (220 units): the bands fold away
step(20, function()
    local w = cw()
    origMax = w._maxWinW
    -- the window's cap on its width is what leaves the drawer its room (ZeD_CharacterWindow.getTargetDrawerW)
    w._maxWinW = T.px(36 + 36 + 200 + 260)   -- room for less than the full card: the drawer steps down to the half card (220 units)
end)
step(20, function() whenStill(function()
    local w = cw()
    layoutChecks("narrow", false)
    checkSlots("narrow", false)
    checkZones("narrow")
    local sm = 0
    for _, z in ipairs(w._equipSlotZones or {}) do for _, s in ipairs(Doll.SMALL) do if z.type == "doll:" .. s.id then sm = sm + 1 end end end
    check("narrow: no small-slot zone left", sm == 0, sm)
    local d = dataNow(false)
    say("narrow: Arms layers " .. #d.slots.arms.items .. ", Back " .. #d.slots.back.items .. ", Legs " .. #d.slots.legs.items .. ", Belt " .. #d.slots.belt.items .. ", Hands " .. #d.slots.hands.items)
    shot("narrow")
end) end)
step(10, function()
    local el = focusId("equipslot:doll:back")
    if el and el.onActivate then el.onActivate(cw(), el) end
end)
step(40, function()
    local w = cw()
    local item, idx, n = Doll.selection(w)
    check("narrow: Back's card shows the folded layers (tail, satchel)", item ~= nil and n >= 2, "layers " .. tostring(n))
    w._equipSelected = nil; w._equipLayer = 1; w._equipCache = nil; w._gpFocusedEquipSlot = nil
end)

-- ---- G. a short window (director, Oct 30 2026: shrink the slots rather than scroll): with the full card back,
-- the window is cut so the doll's view is 80% of its full height; the doll, bands and all, shrinks to fit it
local realMeasure, lastView, origH = Doll.measure, nil, nil
step(20, function()
    local w = cw()
    if origMax then w._maxWinW = origMax end
    Doll.measure = function(win, mw, viewH) lastView = { w = mw, h = viewH }; return realMeasure(win, mw, viewH) end
end)
step(20, function() whenStill(function()
    local w = cw()
    if not lastView then check("short: the doll was measured", false); return end
    local fullH = realMeasure(w, lastView.w, 1e9)
    origH = w:getHeight()
    local target = math.floor(origH - lastView.h + fullH * 0.8)
    say(string.format("short: window %d -> %d px (view %d, doll at full size %d)", origH, target, lastView.h, fullH))
    w:setHeight(target)
end) end)
step(20, function() whenStill(function()
    local w = cw()
    local U = T.px(1000) / 1000
    local small = rectOf("ears")
    local su = small and small.w / U or 0
    check("short: the bands still show", w._equipDollBands == true)
    check("short: the small slots shrank (under 18 units, 14 or more)", su < 17.9 and su >= 13.9, string.format("%.1f units", su))
    local dollH = realMeasure(w, lastView.w, lastView.h)
    check("short: the doll fits its view, no scrolling to reach it", dollH <= lastView.h + 1, dollH .. " in " .. lastView.h)
    local nov, oa, ob = overlaps(w._equipDollAll or {})
    check("short: no slot overlaps another", nov == 0, nov > 0 and (tostring(oa) .. " x " .. tostring(ob)) or nil)
    check("short: 49 slot boxes", #(w._equipDollAll or {}) == 49, #(w._equipDollAll or {}))
    shot("short")
end) end)

-- ---- put everything back
step(20, function()
    local w = cw()
    if origMax then w._maxWinW = origMax end
    Doll.measure = realMeasure
    if origH then w:setHeight(origH) end
    Doll.gather = realGather
    for _, it in ipairs(added) do
        pcall(function() p:removeWornItem(it) end)
        pcall(function() inv:Remove(it) end)
    end
    triggerEvent("OnClothingUpdated", p)
    Doll.setView(origView)
    Det.setLockedMode(Det.MODE_KBM); Det.setLockedMode(nil)
    w._equipDollTimer = 99
end)
step(40, function() say("passed " .. passN .. ", failed " .. failN .. " | DONE") end)

local function onTick()
    local s = Q[qi + 1]
    if not s then Events.OnTick.Remove(onTick); return end
    waitT = waitT + 1
    if waitT < s.n then return end
    waitT = 0
    qi = qi + 1
    local ok, e = pcall(s.fn)
    if not ok then say("ERR step " .. qi .. " " .. tostring(e)) end
end
Events.OnTick.Add(onTick)
say("start")
