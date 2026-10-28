-- ZeDUI/tools/qa/zedqa_4222.lua  (Oct 27 2026, Project Zomboid 42.22 Pre-Release)
-- In game on the ZeD-QA save: the 42.22 features that reach ZeD's screens.
--   1 crowbars: a door near the character locked, a crowbar in the bag; ZeD's world menu on the door
--     has the game's Force row; picking it equips the crowbar (the belt's main hand) and forces the door
--   2 ladders: a wooden ladder placed where the character stands (or one found nearby); the game's
--     Climb Ladder / Climb Down Ladder row in ZeD's world menu
--   3 ammo boxes: a pistol in hand and a box of 9mm; the box's open row in ZeD's item menu; after it,
--     the rounds are loose and the belt's ammo pouch counts them
-- The door is unlocked again, the ladder removed and the character put back where it started.
-- Pictures zqa_4222_*.png. grep "ZEDQA 4222".
local TAG = "4222"
local function say(s) print("ZEDQA " .. TAG .. " " .. tostring(s)) end
local p = getPlayer()
local inv = p:getInventory()
local fails = 0
local function check(name, ok, detail)
    if not ok then fails = fails + 1 end
    say((ok and "PASS " or "ERR ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or ""))
end
local function shot(n) pcall(function() getCore():TakeFullScreenshot("zqa_4222_" .. n .. ".png") end) end
local function give(t) local ok, it = pcall(function() return inv:AddItem(t) end); return ok and it or nil end
local function zm() local v = getPlayerContextMenu(0); return v and v._zedMenu end
local function rowNames(li)
    local m = zm()
    local lv = m and m._levels and m._levels[li or 1]
    local out = {}
    for _, r in ipairs(lv and lv.rows or {}) do if not r.sep and r.def then out[#out + 1] = tostring(r.def.name) end end
    return out
end
local function hasRow(names, text)
    for _, n in ipairs(names) do if n:lower():find(text:lower(), 1, true) then return n end end
    return nil
end
local function pick(text)
    local m = zm()
    local lv = m and m._levels and m._levels[1]
    for i, r in ipairs(lv and lv.rows or {}) do
        if r.def and tostring(r.def.name):lower():find(text:lower(), 1, true) then lv.sel = i; m:onJoypadDown(Joypad.AButton); return true end
    end
    return false
end
local function closeMenu()
    local m = zm()
    if m then pcall(function() m:close() end) end
    local v = getPlayerContextMenu(0)
    if v then pcall(function() v:setVisible(false) end) end
end
-- ZeD's menu as its list (the strip has no rows to read); put back at the end
local styleOpt = ZeD.Settings.contextStyleOption
local styleWas = styleOpt:getValue()
styleOpt:setValue(2)
local function goTo(x, y, z) p:setX(x); p:setY(y); p:setZ(z); p:setLastX(x); p:setLastY(y); p:setLastZ(z) end
local function objsOf(sq)
    local t = {}
    local o = sq and sq:getObjects()
    for i = 0, (o and o:size() or 0) - 1 do t[#t + 1] = o:get(i) end
    return t
end

local Q = {}
local function step(fn, wait) Q[#Q + 1] = { fn = fn, wait = wait or 20 } end
local home = { x = p:getX(), y = p:getY(), z = p:getZ() }
local door, doorWasLocked, crowbar
local ladderObj, ladderSq
local box, pistol, loose0

-- the QA spot is in the woods: the door test goes to Muldraugh's houses, and back after
local TOWN = { x = 10650, y = 9800, z = 0 }
step(function()
    if getGameSpeed() <= 0 then setGameSpeed(1) end
    p:setGodMod(true)
    say("game " .. tostring(getCore():getVersion()))
    goTo(TOWN.x + 0.5, TOWN.y + 0.5, TOWN.z)
end, 240)
step(function()
    -- 1 the nearest door within 40 squares on the character's floor
    local cx, cy, cz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    local best, bd
    for dx = -40, 40 do for dy = -40, 40 do
        local sq = getCell():getGridSquare(cx + dx, cy + dy, cz)
        if sq then
            for _, o in ipairs(objsOf(sq)) do
                local sa, sb = instanceof(o, "IsoDoor") and o:getSquare(), instanceof(o, "IsoDoor") and o:getOppositeSquare()
                local outer = sa and sb and ((sa:getRoom() == nil) ~= (sb:getRoom() == nil))
                if outer and instanceof(o, "IForceablePortal") and not o:isBarricaded() then
                    local d = dx * dx + dy * dy
                    if not bd or d < bd then best, bd = o, d end
                end
            end
        end
    end end
    door = best
    check("a forceable door nearby", door ~= nil, door and (door:getSquare():getX() .. "," .. door:getSquare():getY()))
    if door then
        doorWasLocked = door:isLocked()
        if door:IsOpen() then door:ToggleDoorSilent() end
        door:setLockedByKey(true)
        door:setIsLocked(true)
        say("door locked " .. tostring(door:isLocked()) .. ", valid for forcing " .. tostring(not door:isNotValidForForcing()))
        -- forcing is for getting in: stand on the door's outside square (no room)
        local a, b = door:getSquare(), door:getOppositeSquare()
        local out = (a and not a:getRoom()) and a or b
        if out then goTo(out:getX() + 0.5, out:getY() + 0.5, out:getZ()); say("outside at " .. out:getX() .. "," .. out:getY() .. " room " .. tostring(out:getRoom() ~= nil)) end
    end
    crowbar = give("Base.Crowbar")
    check("crowbar given", crowbar ~= nil)
end, 30)
step(function()
    if not door then return end
    ISWorldObjectContextMenu.createMenu(0, objsOf(door:getSquare()), 700, 300, false)
end, 25)
-- the door's rows sit in its Door sub-menu (level 2)
local forceLevel
step(function()
    local names = rowNames(1)
    say("door menu: " .. table.concat(names, ", "))
    if hasRow(names, getText("ContextMenu_Force")) then forceLevel = 1; return end
    local m = zm()
    local lv = m and m._levels and m._levels[1]
    local opened = false
    for i, r in ipairs(lv and lv.rows or {}) do
        local n = r.def and tostring(r.def.name):lower()
        if not opened and n and (n == "door" or n == getText("ContextMenu_Door"):lower()) then
            lv.sel = i
            opened = m:_openSub(1, true)
        end
    end
    say("Door sub-menu opened " .. tostring(opened))
    -- what the game put under Door (ZeD draws the game's own rows)
    local v = getPlayerContextMenu(0)
    for _, o in ipairs(v and v.options or {}) do
        if o.subOption then
            local sub = v:getSubMenu(o.subOption)
            local kids = {}
            for _, k in ipairs(sub and sub.options or {}) do kids[#kids + 1] = tostring(k.name) end
            say("game's " .. tostring(o.name) .. " rows: " .. table.concat(kids, ", "))
        end
    end
end, 15)
step(function()
    local names = forceLevel == 1 and rowNames(1) or rowNames(2)
    if not forceLevel then forceLevel = 2; say("Door sub-menu: " .. table.concat(names, ", ")) end
    check("ZeD's world menu has the game's Force row", door ~= nil and hasRow(names, getText("ContextMenu_Force")) ~= nil, getText("ContextMenu_Force"))
    shot("1_force_row")
end, 10)
step(function()
    local m = zm()
    local lv = m and m._levels and m._levels[forceLevel or 1]
    local done = false
    for i, r in ipairs(lv and lv.rows or {}) do
        if not done and r.def and tostring(r.def.name) == getText("ContextMenu_Force") then lv.sel = i; m:onJoypadDown(Joypad.AButton); done = true end
    end
    if done then say("Force picked") else closeMenu() end
end, 600)
step(function()
    local prim = p:getPrimaryHandItem()
    check("the crowbar went to the main hand", prim ~= nil and prim:hasTag(ItemTag.CROWBAR), prim and prim:getFullType())
    say("door locked after forcing: " .. tostring(door and door:isLocked()) .. ", open " .. tostring(door and door:IsOpen()))
    shot("2_after_force")
end, 10)
-- 2 ladders
step(function()
    closeMenu()
    ISTimedActionQueue.clear(p)
    goTo(home.x, home.y, home.z)
end, 240)
step(function()
    local cx, cy, cz = math.floor(home.x), math.floor(home.y), math.floor(home.z)
    -- a ladder already in the world within 30 squares?
    for dx = -30, 30 do for dy = -30, 30 do
        local sq = getCell():getGridSquare(cx + dx, cy + dy, cz)
        if sq and not ladderSq then
            for _, o in ipairs(objsOf(sq)) do
                local pr = o:getProperties()
                if pr and (pr:has(IsoPropertyType.LADDER_N) or pr:has(IsoPropertyType.LADDER_W) or pr:has(IsoPropertyType.LADDER_S) or pr:has(IsoPropertyType.LADDER_E)) then
                    ladderSq = sq; say("found a ladder at " .. sq:getX() .. "," .. sq:getY() .. " " .. tostring(o:getSprite() and o:getSprite():getName()))
                end
            end
        end
    end end
    if not ladderSq then
        ladderSq = p:getCurrentSquare()
        ladderObj = IsoObject.new(getCell(), ladderSq, "carpentry_02_85")
        ladderSq:AddTileObject(ladderObj)
        say("placed carpentry_02_85 at " .. ladderSq:getX() .. "," .. ladderSq:getY() .. "," .. ladderSq:getZ())
    end
end, 30)
step(function()
    if ladderObj == nil then
        p:setX(ladderSq:getX() + 0.5); p:setY(ladderSq:getY() + 0.5); p:setZ(ladderSq:getZ())
        p:setLastX(p:getX()); p:setLastY(p:getY())
    end
end, 30)
step(function()
    local sq = p:getCurrentSquare()
    say("climb ladder here: up " .. tostring(p:getClimbLadder(sq) ~= nil) .. ", down " .. tostring(p:getClimbLadderDown(sq) ~= nil))
    ISWorldObjectContextMenu.createMenu(0, objsOf(ladderSq), 700, 300, false)
end, 25)
step(function()
    local names = rowNames(1)
    say("ladder menu: " .. table.concat(names, ", "))
    local sq = p:getCurrentSquare()
    local engine = p:getClimbLadder(sq) ~= nil or p:getClimbLadderDown(sq) ~= nil
    local row = hasRow(names, getText("ContextMenu_Climb_Ladder")) or hasRow(names, getText("ContextMenu_Climb_Down_Ladder"))
    if engine then
        check("ZeD's world menu has the game's Climb Ladder row", row ~= nil, row)
    else
        say("NOTE the game offers no climb here (no floor above the placed ladder); the row cannot show")
    end
    shot("3_ladder_menu")
    closeMenu()
end, 10)
-- 3 ammo boxes
step(function()
    if ladderObj then pcall(function() ladderSq:transmitRemoveItemFromSquare(ladderObj) end); pcall(function() ladderSq:RemoveTileObject(ladderObj) end) end
    p:setX(home.x); p:setY(home.y); p:setZ(home.z); p:setLastX(home.x); p:setLastY(home.y)
    pistol = give("Base.Pistol")
    if pistol then p:setPrimaryHandItem(pistol) end
    box = give("Base.Bullets9mmBox")
    loose0 = inv:getCountTypeRecurse("Base.Bullets9mm")
    check("pistol and a box of 9mm", pistol ~= nil and box ~= nil)
end, 40)
step(function()
    local a = ZeD.Belt.ammo and ZeD.Belt.ammo(p)
    say("pouch before: " .. tostring(a and (tostring(a.loose) .. " loose, " .. tostring(a.boxes) .. " boxes")))
    shot("4_pouch_before")
    ISInventoryPaneContextMenu.createMenu(0, true, { box }, 700, 300)
end, 25)
step(function()
    local names = rowNames(1)
    say("box menu: " .. table.concat(names, ", "))
    local row = hasRow(names, "open") or hasRow(names, getText("ContextMenu_Open"))
    check("ZeD's item menu has the box's open row", row ~= nil, row)
    shot("5_box_menu")
    if row then pick(row) else closeMenu() end
end, 400)
step(function()
    local loose = inv:getCountTypeRecurse("Base.Bullets9mm")
    check("the box opened into loose rounds", loose > loose0, loose0 .. " -> " .. loose)
    local a = ZeD.Belt.ammo and ZeD.Belt.ammo(p)
    say("pouch after: " .. tostring(a and (tostring(a.loose) .. " loose, " .. tostring(a.boxes) .. " boxes")))
    shot("6_pouch_after")
end, 10)
step(function()
    closeMenu()
    if door then door:setLockedByKey(doorWasLocked); door:setIsLocked(doorWasLocked) end
    p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil)
    for _, it in ipairs({ crowbar, pistol, box }) do if it and it:getContainer() then pcall(function() it:getContainer():DoRemoveItem(it) end) end end
    -- only the rounds the box made (the character's own stay)
    local extra = inv:getCountType("Base.Bullets9mm") - (loose0 or 0)
    for i = inv:getItems():size() - 1, 0, -1 do
        local it = inv:getItems():get(i)
        if extra > 0 and it and it:getFullType() == "Base.Bullets9mm" then inv:DoRemoveItem(it); extra = extra - 1 end
    end
    styleOpt:setValue(styleWas)
    goTo(home.x, home.y, home.z)
    say("errors " .. fails)
    say("DONE")
end, 1)

local i, wait = 1, 30
local function tick()
    if wait > 0 then wait = wait - 1; return end
    local s = Q[i]
    if not s then Events.OnRenderTick.Remove(tick); return end
    local ok, e = pcall(s.fn)
    if not ok then fails = fails + 1; say("ERR step " .. i .. ": " .. tostring(e)) end
    wait = s.wait
    i = i + 1
end
Events.OnRenderTick.Add(tick)
say("start")
