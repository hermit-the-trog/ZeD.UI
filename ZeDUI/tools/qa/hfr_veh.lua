-- ZeDUI/tools/qa/hfr_veh.lua  (Nov 20 2026, QA; tag hfv): the beta 21 hotfix report, CUTS D, the car (git 107b914a8): the
-- Vehicle tab's rows, a tire's card and a part that needs another off first, the install progress band, the seat chooser
-- with the pointer on a free seat. At the QA home (the Irvington drag strip), no story stage: a pickup spawned beside the
-- character (the prelude's ZEDQA_CAR_*), repaired and fuelled, taken away at the end. Pictures to Screenshots/hfr_D_*.png.
-- Manifest hotfix_veh.txt. grep "ZEDQA hfv".
local S = HFR and HFR.init and HFR.init("hfv", true)
if not S then return end
local Q = S.Q
S.MT = ZeD.MechanicsTab
S.Seats = ZeD.Seats

function S.ms2() local w = S.WW(); return w and S.MT.getState(w) end

Q.step(5, function()
    S.start0()
    if getGameSpeed() <= 0 then pcall(setGameSpeed, 1) end
    if not (ZEDQA_CAR_WAIT and ZEDQA_CAR_PREP and ZEDQA_CAR_AWAY) then S.failWhy = "the prelude's car helpers are not loaded"; return end
    S.pairWas = S.CWm.isOpen() and S.WWm.isOpen()
    ZEDQA_CAR_WAIT("Base.PickUpTruck", "hfv", function(v)
        S.v = v
        S.key = ZEDQA_CAR_PREP(v)
        S.ready = true
    end, function(why) S.failWhy = why or "no ready car" end, 6000)
end)
Q.zoomTo(1.0)
Q.waitFor(5, 3600, function() return S.ready or S.failWhy ~= nil end, function() Q.say("car ready " .. tostring(S.v ~= nil) .. " " .. tostring(S.failWhy)) end)

-- the game's Vehicle Mechanics: the character inspects the car, the Vehicle tab opens
Q.step(10, function()
    if not S.v then return end
    S.openPair()
    pcall(function() S.p:getInventory():AddItem("Base.LugWrench") end)
    pcall(ISVehicleMenu.onMechanic, S.p, S.v)
end)
Q.waitFor(30, 1800, function()
    local w = S.WW()
    return not S.v or (S.MT.isInspected(S.v) and w ~= nil and w._activeTab == "vehicle")
end, function(ok) Q.say("Vehicle tab open " .. tostring(ok)) end)
Q.step(60, function() S.clearChar() end)
Q.still(10, function()
    local w = S.WW()
    if S.v and w and w._activeTab == "vehicle" then S.shot("D_vehicle_tab_rows") else Q.notTaken("D_vehicle_tab_rows", "the Vehicle tab did not open") end
end)

-- a row by part id fragment: its card (the click on the row's middle)
function S.openCard(frag, name, extra)
    Q.step(10, function()
        S.part = nil
        local s = S.ms2()
        local rows = s and s.lastRows or {}
        for _, z in ipairs(rows) do
            -- (QA, Nov 20: a row's part is the part's id text, not the part; the first pass called :getId on it)
            local id = tostring(z.part)
            if not S.part and id:find(frag, 1, true) then S.part = z end
        end
        if not S.part then local ids = {}; for _, z in ipairs(rows) do ids[#ids + 1] = tostring(z.part) end; Q.say("row ids: " .. table.concat(ids, ",")) end
        Q.say(name .. " row " .. tostring(S.part ~= nil) .. " of " .. #rows)
        if S.part then pcall(S.MT.onClick, S.WW(), S.part.x + math.floor(S.part.w / 2), S.part.y + math.floor(S.part.h / 2)) end
        -- (QA, Nov 20: a row far down the list is outside the view and the click misses it; the card is then set as the click would)
        if S.part then local s2 = S.ms2(); if s2 and s2.card == nil then s2.card = S.part.part; Q.say(name .. ": card set directly on " .. tostring(S.part.part) .. " (row y " .. tostring(S.part.y) .. ")") end end
    end)
    Q.step(40, function() S.clearChar() end)
    Q.still(10, function()
        local s = S.ms2()
        if S.part and s and s.card then S.shot(name) else Q.notTaken(name, "no row " .. frag .. " or its card did not open") end
    end)
    if extra then Q.step(5, extra) end
    Q.step(10, function()
        local s = S.ms2()
        local z = S.part and S.part.part and (function() for _, h in ipairs((s and s.zones) or {}) do if h.id == "mech:row:" .. tostring(S.part.part) then return h end end end)()
        if s and s.card then s.card = nil end
    end)
end
S.openCard("TireRearLeft", "D_tire_card")
S.openCard("BrakeRearLeft", "D_part_take_off_first")

-- the install progress band: a tire taken off (the game's own action, left to run a moment)
Q.step(10, function()
    pcall(function() S.p:setTimedActionInstantCheat(false) end)
    local part = nil
    pcall(function() part = S.v:getPartById("TireRearLeft") end)
    S.tire = part
    if part then pcall(function() ISVehiclePartMenu.onUninstallPart(S.p, part) end) end
    Q.say("uninstall tire asked " .. tostring(part ~= nil))
end)
function S.head()
    local t = "none"
    pcall(function()
        local q = ISTimedActionQueue.getTimedActionQueue(S.p)
        local a = q and q.queue and q.queue[1]
        if a then t = tostring(a.Type) end
    end)
    return t
end
-- (QA, Nov 20: the first pass shot while the character was still walking to the wheel, "Walking then equipping"; now it
-- waits for the game's uninstall action itself to run, then a moment more)
Q.waitFor(1, 1500, function() return S.head():find("Uninstall", 1, true) ~= nil or S.head():find("Install", 1, true) ~= nil end,
    function(ok) Q.say("queue head " .. S.head() .. ", reached " .. tostring(ok)) end)
Q.step(2, function()
    local h = S.head()
    Q.say("queue head at the shot " .. h)
    if h:find("nstall", 1, true) then S.shot("D_install_band_no_percent") else Q.notTaken("D_install_band_no_percent", "no install action running (head " .. h .. ")") end
end)
Q.step(10, function() pcall(function() ISTimedActionQueue.clear(S.p) end) end)

-- the seat chooser pop-out with the pointer on a free seat
Q.step(10, function()
    S.closePair()
    pcall(function() S.p:setX(S.v:getX() + 2.5); S.p:setY(S.v:getY() + 0.5) end)
    pcall(function() S.p:setLastX(S.p:getX()); S.p:setLastY(S.p:getY()) end)
end)
Q.step(20, function()
    local ok, err = pcall(S.Seats.toggle, S.p, S.v)
    Q.say("seat key " .. tostring(ok) .. " " .. tostring(err))
    S.Seats.qaPoint = { seat = 2 }
end)
Q.step(50, function() end)
Q.step(5, function()
    local sp = S.Seats.getPopout and S.Seats.getPopout(S.pn)
    if sp and sp:isReallyVisible() then S.shot("D_seat_free_hover", true) else Q.notTaken("D_seat_free_hover", "no seat pop-out") end
end)
Q.step(5, function()
    S.Seats.qaPoint = nil
    pcall(function() local sp = S.Seats.getPopout and S.Seats.getPopout(S.pn); if sp then sp:close() end end)
end)

-- ===================================================================== put back
Q.mark()
Q.step(5, function()
    S.Seats.qaPoint = nil
    pcall(function() ISTimedActionQueue.clear(S.p) end)
    pcall(function() S.p:getInventory():RemoveOneOf("LugWrench") end)
    pcall(function() ZeD.Stations.unbind(S.p) end)
    if S.v then pcall(ZEDQA_CAR_AWAY, S.v, S.key) end
    S.takeMade()
    G1.glassesBack(Q)
end)
Q.step(30, function()
    S.openPair(); S.charTab("loot"); S.worldTab("loot")
    S.back0()
end)
Q.step(30, function()
    if not S.pairWas then S.closePair() end
    pcall(function() Mouse.setCursorVisible(true) end)
    Q.say("put back")
end)
Q.start()
