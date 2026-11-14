-- ZeDUI/tools/qa/zedqa_playtest_stage.lua  (Nov 14 2026, QA): stages the director's playtest character (copied out to
-- Saves/Sandbox/ZeD-Playtest afterwards). Finds a house square near the character with a chair and a window, moves
-- there, puts a crate with a T-shirt and a jacket beside the character, gives the test items, sets ZeD's setup
-- (Put things back on, moodles above the belt, hint strip Always) and turns god mode off. grep "ZEDQA pts".
local function say(s) print("ZEDQA pts " .. tostring(s)) end
local p = getPlayer()
if not p then say("ERR no player"); say("DONE"); return end
local function spriteName(o) local s = o and o:getSprite(); return s and s:getName() or "" end
local function findHouse(cx, cy, r)
    local cell = getCell()
    local best, bestD
    for dx = -r, r do
        for dy = -r, r do
            local sq = cell:getGridSquare(cx + dx, cy + dy, 0)
            if sq and sq:getRoom() then
                local objs = sq:getObjects()
                for k = 0, objs:size() - 1 do
                    local sn = spriteName(objs:get(k)); if sn:find("furniture_seating") or sn:find("chair") then
                        -- a window in the same room
                        local room = sq:getRoom()
                        local hasWin = false
                        for wx = -6, 6 do for wy = -6, 6 do local s3 = cell:getGridSquare(sq:getX() + wx, sq:getY() + wy, 0); if s3 and s3:getRoom() == room and s3:getWindow() then hasWin = true end end end
                        local d = dx * dx + dy * dy
                        if hasWin and (not bestD or d < bestD) then best, bestD = sq, d end
                    end
                end
            end
        end
    end
    return best
end
local step, n, target = 0, 0, nil
local spots = { { 10620, 9840 }, { 10700, 9700 }, { 10600, 10000 }, { 1625, 14221 } }
local si = 0
local function stage(sq)
    -- stand on a free square next to the chair
    local stand = sq
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local s2 = getCell():getGridSquare(sq:getX() + d[1], sq:getY() + d[2], 0)
        if s2 and s2:isFree(false) and s2:getRoom() == sq:getRoom() then stand = s2; break end
    end
    p:setX(stand:getX() + 0.5); p:setY(stand:getY() + 0.5); p:setZ(0); p:setLastX(p:getX()); p:setLastY(p:getY())
    say("staged at " .. stand:getX() .. "," .. stand:getY() .. " (chair at " .. sq:getX() .. "," .. sq:getY() .. ")")
    -- a crate with clothes on a free square beside the character
    local csq
    for _, d in ipairs({ { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 }, { 1, 1 } }) do
        local s2 = getCell():getGridSquare(stand:getX() + d[1], stand:getY() + d[2], 0)
        if s2 and s2:isFree(false) and s2 ~= sq then csq = s2; break end
    end
    if csq then
        local crate = IsoThumpable.new(getCell(), csq, "carpentry_01_16", false, nil)
        crate:setIsContainer(true); crate:getContainer():setType("crate"); csq:AddSpecialObject(crate)
        pcall(function() crate:transmitCompleteItemToServer() end)
        local box = crate:getContainer()
        box:AddItem("Base.Tshirt_DefaultTEXTURE_TINT"); box:AddItem("Base.Jacket_Padded")
        say("crate with a T-shirt and a jacket at " .. csq:getX() .. "," .. csq:getY())
    else say("ERR no free square for the crate") end
    local inv = p:getInventory()
    for _, t in ipairs({ "Base.Mug", "Base.Saucepan", "Base.FirstAidKit", "Base.Notebook", "Base.Newspaper",
        "Base.BookBlacksmith1", "Base.BookBlacksmith2", "Base.BookButchering1", "Base.BookButchering2" }) do
        local it = inv:AddItem(t)
        say("gave " .. t .. ": " .. tostring(it ~= nil))
    end
    pcall(function() local kit = inv:getFirstType("FirstAidKit"); if kit and kit.getItemContainer then local c = kit:getItemContainer(); for _ = 1, 4 do c:AddItem("Base.Bandage") end; c:AddItem("Base.Disinfectant"); c:AddItem("Base.Scissors"); c:AddItem("Base.SutureNeedle") end end)
    -- ZeD setup
    pcall(function() ZeD.Settings.putBackOption:setValue(2) end)
    say("Put things back on: " .. tostring(ZeD.Settings.putBackOn and ZeD.Settings.putBackOn()))
    -- god mode off
    pcall(function() p:setGodMod(false) end); pcall(function() p:setInvincible(false) end); pcall(function() p:setGhostMode(false) end)
    say("god mode " .. tostring(p:isGodMod()))
end
local function tick()
    n = n + 1
    if step == 0 then
        si = si + 1
        local s = spots[si]
        if not s then say("ERR no house with a chair and a window found"); Events.OnTick.Remove(tick); say("DONE"); return end
        p:setX(s[1] + 0.5); p:setY(s[2] + 0.5); p:setZ(0); p:setLastX(p:getX()); p:setLastY(p:getY())
        say("looking around " .. s[1] .. "," .. s[2])
        step, n = 1, 0
    elseif step == 1 and n > 480 then
        target = findHouse(math.floor(p:getX()), math.floor(p:getY()), 45)
        if target then stage(target); step, n = 2, 0 else step = 0 end
    elseif step == 2 and n > 120 then
        Events.OnTick.Remove(tick)
        pcall(function() getCore():TakeFullScreenshot("zqa_playtest_spot.png") end)
        say("DONE")
    end
end
Events.OnTick.Add(tick)
say("start")
