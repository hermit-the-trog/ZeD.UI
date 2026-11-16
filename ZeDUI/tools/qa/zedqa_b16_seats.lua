-- ZeDUI/tools/qa/zedqa_b16_seats.lua  (Nov 15 2026, QA): beta 16's seat picker pop-out in three cars, with pictures
-- for the director: a whole sedan (Base.CarNormal), a pickup (Base.PickUpTruck) and a smashed sedan
-- (Base.CarNormalSmashedFront, which Build expects to get the cabin too; a fallback prints its reason as
-- "[ZeD] SeatPopout: <name> fell back to the window: ..."). Each car comes from the prelude's shared spawn
-- (ZEDQA_CAR_SPAWN), the character is set 2 tiles beside it (the pop-out closes past 6), the pop-out is opened as the
-- seat key opens it (ZeD.Seats.popToggle), pictured, closed, and the car taken away.
-- grep "ZEDQA b16s"; screenshots Screenshots/zqa_b16s_*.png.
local p = getPlayer()
local pn = p:getPlayerNum()
local S = ZeD.Seats
local function say(s) print("ZEDQA b16s " .. tostring(s)) end
local fails = 0
local function check(ok, what) if ok then say("PASS " .. what) else fails = fails + 1; say("FAIL " .. what) end; return ok end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_b16s_" .. n .. ".png") end) end
local Q = {}
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
if not (S and S.popToggle and ZEDQA_CAR_SPAWN) then say("ERR needs ZeD.Seats.popToggle and zedqa_prelude.lua"); say("DONE"); return end

local home = { x = p:getX(), y = p:getY(), z = p:getZ() }
local function moveTo(x, y, z)
    p:teleportTo(x, y, z)
    pcall(function() p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end)
end

local CARS = {
    { script = "Base.CarNormal", tag = "sedan", cabin = true },
    { script = "Base.PickUpTruck", tag = "pickup", cabin = true },
    { script = "Base.CarNormalSmashedFront", tag = "sedan_smashed", cabin = true },
}
for _, c in ipairs(CARS) do
    local car
    step(10, function()
        car = ZEDQA_CAR_SPAWN(c.script, "b16s")
        if not car then say("not run: " .. c.tag .. " (no spot to spawn)") end
    end)
    step(90, function()   -- (the car settles; the pop-out reads the seats, no physics needed: nobody sits)
        if not car then return end
        moveTo(car:getX() + 2.5, car:getY() + 0.5, car:getZ())
    end)
    step(30, function()
        if not car then return end
        local ok, opened = pcall(S.popToggle, p, car)
        if not ok then say("ERR " .. c.tag .. ": " .. tostring(opened)) end
        check(ok and opened == true, c.tag .. ": the seat picker pops out as the car's cabin" ..
            ((ok and not opened) and " (it fell back to the window: see the [ZeD] SeatPopout line)" or ""))
    end)
    step(40, function()
        if not car then return end
        local sp = S.getPopout and S.getPopout(pn)
        if sp and sp:isReallyVisible() then
            shot(c.tag)
            sp:close()
        else
            shot(c.tag .. "_window")
            pcall(function() if ISVehicleSeatUI and ISVehicleSeatUI.windows and ISVehicleSeatUI.windows[pn] then ISVehicleSeatUI.windows[pn]:close() end end)
        end
    end)
    step(20, function()
        moveTo(home.x, home.y, home.z)
        if car then pcall(function() car:permanentlyRemove() end) end
    end)
end

step(10, function()
    moveTo(home.x, home.y, home.z)
    say(fails == 0 and "all checks passed" or (fails .. " failed"))
    say("DONE")
end)

local qi, wait = 1, nil
local function tick()
    local s = Q[qi]
    if not s then Events.OnPreUIDraw.Remove(tick); return end
    wait = (wait or s.n) - 1
    if wait > 0 then return end
    wait = nil
    qi = qi + 1
    local ok, err = pcall(s.fn)
    if not ok then say("ERR step " .. (qi - 1) .. ": " .. tostring(err)) end
end
Events.OnPreUIDraw.Add(tick)
say("start")
