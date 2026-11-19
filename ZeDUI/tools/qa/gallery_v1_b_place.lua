-- ZeDUI/tools/qa/gallery_v1_b_place.lua  (Nov 17 2026, QA): the lived-in place for the ZeD-GUI 1.0 gallery's crafting
-- and building pictures (the director's review: not the test field by the road). Defines the global GV1P; calls NOTHING
-- of ZeD's, so the vanilla run uses it too. Run it after gallery_v1_b_lib.lua. grep "ZEDQA g1pl".
-- The place is gallery_v1_c1_common.lua's West Point kitchen (the house at 12021-12033,7078-7090; the kitchen
-- 12028-12030 x 7078-7082): the nearest free square in the room named "kitchen" with room to stand round it (3 of 4
-- sides), facing SE. The world gets 8 s to stream in after the jump. The grid power is put on for the shots (the
-- house lit: ElecShutModifier and WaterShutModifier far off, the hydro power on) and put back by GV1P.back(S);
-- zombies within 30 squares are taken out of the world (the QA save only; counted in the log).
--   GV1P.kitchen(S)   adds the steps that take S's character there; S.placed = "kitchen x,y" or nil (then the
--                     script stays where it is and says so)
--   GV1P.back(S)      the power as it was (the script moves its character back itself)
--   GV1P.side(S, list)  each { label, window, "left" | "right" } to that screen edge (24 px in), logged
GV1P = GV1P or {}
local P = GV1P
P.K = { ax = 12029, ay = 7080, room = "kitchen", r = 6, dir = "SE" }
P.SIDES = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }
function P.roomName(sq)
    local r = sq and sq:getRoom()
    return r and r:getName() or nil
end
function P.fits(sq)
    if not sq then return false end
    if not sq:isFree(false) then return false end
    return P.roomName(sq) == P.K.room
end
function P.spot()
    local cell = getCell()
    for r = 0, P.K.r do
        for dy = -r, r do
            for dx = -r, r do
                if math.abs(dx) == r or math.abs(dy) == r then
                    local x, y = P.K.ax + dx, P.K.ay + dy
                    if P.fits(cell:getGridSquare(x, y, 0)) then
                        local n = 0
                        for _, d in ipairs(P.SIDES) do if P.fits(cell:getGridSquare(x + d[1], y + d[2], 0)) then n = n + 1 end end
                        -- (Nov 18 2026, the director: nothing in front of the character. The camera looks from the south-east,
                        -- so the squares south, east and south-east of the spot must be free floor too: no counter,
                        -- island or table drawn over the character's legs.)
                        -- (free floor in any room: run 1 asked for kitchen floor and the small kitchen had none)
                        local function open(q) return q ~= nil and q:isFree(false) end
                        local front = open(cell:getGridSquare(x + 1, y, 0)) and open(cell:getGridSquare(x, y + 1, 0))
                            and open(cell:getGridSquare(x + 1, y + 1, 0))
                        if n >= 2 and front then return { x = x, y = y } end
                    end
                end
            end
        end
    end
    return nil
end
function P.power(S, on)
    local W = S.powerWas
    if not W then
        W = {}
        S.powerWas = W
        W.so = getSandboxOptions()
        W.elec = W.so:getOptionByName("ElecShutModifier")
        W.watr = W.so:getOptionByName("WaterShutModifier")
        W.elecWas = W.elec and W.elec:getValue()
        W.watrWas = W.watr and W.watr:getValue()
        W.hydro = getWorld():isHydroPowerOn()
    end
    if W.elec then W.elec:setValue(on and 99999 or W.elecWas) end
    if W.watr then W.watr:setValue(on and 99999 or W.watrWas) end
    W.so:toLua()
    getWorld():setHydroPowerOn(on and true or (W.hydro == true))
end
function P.back(S)
    if S.powerWas then
        local ok, e = pcall(P.power, S, false)
        S.say("the grid power put back" .. (ok and "" or (": ERR " .. tostring(e))))
    end
end
function P.clearZombies(x, y, rad)
    local rm = {}
    local zs = getCell():getZombieList()
    for i = 0, zs:size() - 1 do
        local z = zs:get(i)
        if math.abs(z:getX() - x) <= rad and math.abs(z:getY() - y) <= rad then rm[#rm + 1] = z end
    end
    for _, z in ipairs(rm) do z:removeFromWorld(); z:removeFromSquare() end
    return #rm
end
function P.kitchen(S)
    S.step(5, function()
        S.say("to the West Point kitchen (" .. P.K.ax .. "," .. P.K.ay .. ")")
        GV1.moveTo(S, P.K.ax + 0.5, P.K.ay + 0.5, 0)
        S.kt0 = getTimestampMs()
    end)
    S.step(10, function()
        local loaded = getCell():getGridSquare(P.K.ax, P.K.ay, 0) ~= nil
        if (not loaded or getTimestampMs() - S.kt0 < 8000) and getTimestampMs() - S.kt0 < 30000 then return true end
        local s = P.spot()
        if not s then
            S.say("ERR no free square in the kitchen near " .. P.K.ax .. "," .. P.K.ay .. " (loaded " .. tostring(loaded) .. "): the shots stay here")
            return
        end
        GV1.moveTo(S, s.x + 0.5, s.y + 0.5, 0)
        S.p:setDir(IsoDirections[P.K.dir])
        local ok, n = pcall(P.clearZombies, s.x, s.y, 30)
        local okP, eP = pcall(P.power, S, true)
        S.placed = "kitchen " .. s.x .. "," .. s.y
        S.say("place: the kitchen of the house at 12021-12033,7078-7090 (West Point), square " .. s.x .. "," .. s.y
            .. " room " .. tostring(P.roomName(getCell():getGridSquare(s.x, s.y, 0))) .. " | " .. tostring(ok and n or "?")
            .. " zombies within 30 squares taken out | grid power on " .. tostring(okP) .. (okP and "" or (" ERR " .. tostring(eP))))
    end)
    S.step(90, function() if S.placed then S.p:setDir(IsoDirections[P.K.dir]) end end)
end
function P.side(S, list)
    local Wd = getCore():getScreenWidth()
    local at = { left = 24, right = Wd - 24 }
    for _, e in ipairs(list) do
        local win, side = e[2], e[3]
        if win and win:isVisible() then
            local x0 = math.floor(win:getX())
            if side == "right" then win:setX(at.right - win:getWidth()); at.right = at.right - win:getWidth() - 24
            else win:setX(at.left); at.left = at.left + win:getWidth() + 24 end
            if win._anchorRightEdge ~= nil then win._anchorRightEdge = win:getX() + win:getWidth() end
            S.say("moved " .. tostring(e[1]) .. " from x " .. x0 .. " to " .. math.floor(win:getX()) .. " (" .. side .. " side)")
        end
    end
end

print("ZEDQA g1pl GV1P defined (the West Point kitchen)")
P.n = 0
P.later = function()
    P.n = P.n + 1
    if P.n < 10 then return end
    Events.OnPreUIDraw.Remove(P.later)
    print("ZEDQA g1pl DONE")
end
Events.OnPreUIDraw.Add(P.later)
