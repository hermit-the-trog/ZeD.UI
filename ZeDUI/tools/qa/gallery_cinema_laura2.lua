-- ZeDUI/tools/qa/gallery_cinema_laura2.lua  (Nov 11 2026, QA; the director's two new Laura Craft cinema shots)
-- Run: cinema_run_laura2.ps1 (the Rosa shot save, ZeD-Shots-Rosa; cinema_laura2.txt). Light + Teal as her other shots.
--   cin_lau_forage.png    Laura crouched (sneaking on) in the woods with the game's search mode on, the World window on the
--                         Forage tab: More detail open (the tab's only disclosure), the finds listed, the window tall
--   cin_lau_fishing.png   Laura at the water with the fishing rod in hand, the rod's tension display (ZeD's rod and line
--                         meter, Fishing.ISTensionUI) showing "tight"; the windows closed so the rod reads clearly
-- The look and the dressing follow gallery_cinema_laura.lua (not changed). grep "ZEDQA clau2".
local C = CIN
local S = C.seq("clau2")
local p = getPlayer()
local pn = 0
local site, water = nil, nil

local function natural(sq)
    local fl = sq and sq:getFloor()
    local nm = string.lower(tostring(fl and fl:getSprite() and fl:getSprite():getName() or ""))
    return nm:find("natural", 1, true) ~= nil
end
local function findClearing(cx, cy, r)
    local cell = getCell()
    local best, bd = nil, 1e9
    for dx = -r, r, 3 do for dy = -r, r, 3 do
        local x, y = cx + dx, cy + dy
        local sq = cell:getGridSquare(x, y, 0)
        if sq and natural(sq) and not sq:getBuilding() then
            local ok, trees = true, 0
            for ex = -2, 2 do for ey = -2, 2 do
                local s2 = cell:getGridSquare(x + ex, y + ey, 0)
                if not s2 or s2:getTree() or not natural(s2) then ok = false end
            end end
            if ok then
                for ex = -12, 12, 2 do for ey = -12, 12, 2 do
                    local s2 = cell:getGridSquare(x + ex, y + ey, 0)
                    if s2 and s2:getTree() then trees = trees + 1 end
                end end
                local d = dx * dx + dy * dy
                if trees >= 6 and d < bd then best, bd = { x, y, trees }, d end
            end
        end
    end end
    return best
end
local function isWater(sq)
    if not sq then return false end
    local ok, r = pcall(function() return sq:getProperties() and sq:getProperties():has(IsoFlagType.water) end)
    return (ok and r) and true or false
end
-- a shore: a land square with water on one side for at least 4 squares in a row (the line has somewhere to go)
local DIRS = { { "S", 0, 1 }, { "W", -1, 0 }, { "E", 1, 0 }, { "N", 0, -1 } }
local function findShore(cx, cy, r, only)
    local cell = getCell()
    for dx = -r, r, 2 do for dy = -r, r, 2 do
        local x, y = cx + dx, cy + dy
        local sq = cell:getGridSquare(x, y, 0)
        if sq and sq:getFloor() and not isWater(sq) and not sq:getBuilding() and not sq:getTree() then
            for _, d in ipairs(DIRS) do
              if not only or only == d[1] then
                local run = 0
                for k = 1, 6 do
                    if isWater(cell:getGridSquare(x + d[2] * k, y + d[3] * k, 0)) then run = run + 1 else break end
                end
                if run >= 5 then return { x, y, d[1] } end
              end
            end
        end
    end end
    return nil
end

local function dress()
    pcall(function() local d = p:getDescriptor(); d:setForename("Laura"); d:setSurname("Craft") end)
    C.dress({ "Base.Vest_DefaultTEXTURE_TINT", "Base.Shorts_OliveDrabLong", "Base.Shoes_HikingBoots", "Base.HolsterDouble",
              "Base.WristWatch_Left_DigitalBlack" }, nil, { "Base.Bullets9mm", "Base.Lighter", "Base.WaterBottle" })
    C.profession("PARK_RANGER")
    C.tint("Base.Vest_DefaultTEXTURE_TINT", 0.22, 0.55, 0.56)
    local lv = { Woodwork = 6, Carving = 6, FlintKnapping = 5, PlantScavenging = 7, Trapping = 6, Cooking = 5, Tailoring = 4, Maintenance = 5, Fishing = 4, Strength = 10 }
    for k, l in pairs(lv) do pcall(function() p:setPerkLevelDebug(Perks[k], l) end) end
    pcall(function()
        local hv = p:getHumanVisual()
        hv:setHairModel("PonyTailBraids")
        hv:setHairColor(ImmutableColor.new(0.30, 0.18, 0.10, 1))
    end)
    pcall(function() triggerEvent("OnClothingUpdated", p) end)
    pcall(function() p:resetModelNextFrame() end)
    S.say("dressed; name " .. tostring(p:getDescriptor():getForename()) .. " " .. tostring(p:getDescriptor():getSurname()))
end

-- the closest zoom the game allows (down to `target`): scroll in until it stops getting smaller
local function zoomIn(S, target)
    local last = nil
    S.poll(20, 40, function()
        local z = C.core:getZoom(0)
        if z <= target + 0.01 or (last and math.abs(last - z) < 0.001) then return true end
        last = z
        C.core:doZoomScroll(0, -1)
        return false
    end)
    S.step(90, function() S.say("zoom " .. tostring(C.core:getZoom(0))) end)
end
-- (Nov 11 2026, plan v2 shot 7: her movie's look, Light + Teal; both windows, the World window on the left)
S.step(5, function() C.look("light", "teal"); C.noWindows(); pcall(function() p:setGodMod(true) end) end)
S.step(5, function() C.time(11.0); C.clearSky() end)

-- ---------------------------------------------------------------------------------------------- 1: forage
local SPOTS = { { 8800, 10800 }, { 9500, 11600 }, { 10300, 12000 }, { 8200, 9800 } }
for k = 1, #SPOTS do
    S.step(5, function() if site then return end; C.moveTo(SPOTS[k][1], SPOTS[k][2], 0) end)
    S.step(150, function()
        if site then return end
        site = findClearing(SPOTS[k][1], SPOTS[k][2], 60)
        S.say("woods spot " .. k .. ": " .. tostring(site and (site[1] .. "," .. site[2] .. " (" .. site[3] .. " trees)")))
    end)
end
S.step(10, function()
    if not site then S.say("ERR no woods clearing"); return end
    C.moveTo(site[1], site[2], 0)
    dress()
    -- (plan v2) a fanny pack with a few finds in it: the Character window's one open source
    pcall(function()
        local fp = p:getInventory():AddItem("Base.Bag_FannyPackFront")
        p:setWornItem(fp:getBodyLocation(), fp)
        for _, ft in ipairs({ "Base.BerryBlack", "Base.MushroomGeneric1", "Base.Twigs" }) do fp:getInventory():AddItem(ft) end
        CLAU2_PACK = fp
    end)
    p:setDir(IsoDirections.S)     -- (facing front: the narrowest silhouette, clear of the window's left edge)
end)
C.lookAround(S, "S")
C.pointerAway(S)
zoomIn(S, 0.25)
S.step(10, function() pcall(function() p:setSneaking(true) end) end)
S.step(60, function() pcall(function() p:setSneaking(true) end); S.say("sneaking " .. tostring(p:isSneaking())) end)
S.step(30, function()
    C.windows("loot", "forage")
    local ww = ZeD_WorldWindow.getWindow()
    if ww then ww._moreDetailOpen = true end
    local mgr = ISSearchManager.getManager(p)
    if mgr and not mgr.isSearchMode then pcall(function() ZeD.ForagingTab.toggleSearch(ww) end) end
    S.say("search mode " .. tostring(mgr and mgr.isSearchMode))
end)
-- the search runs on its own for a while, the character kept crouched; then icons in reach are spotted as vanilla's
-- force-find does, until the list holds five finds
local tries, last = 0, -9999
local tick = 0
S.poll(30, 2400, function()
    tick = tick + 30
    pcall(function() p:setSneaking(true) end)
    local mgr = ISSearchManager.getManager(p)
    if mgr and not mgr.isSearchMode then pcall(function() ZeD.ForagingTab.toggleSearch(ZeD_WorldWindow.getWindow()) end) end
    local q = ZeD.ForagingTab._findQueues[pn] or {}
    if #q >= 5 or not mgr then return true end
    if tick < 480 or tick - last < 120 then return false end
    last = tick
    tries = tries + 1
    local best, bd = nil, 1e9
    local reach = (tonumber(mgr.radius) or 6) + 3
    for _, icon in pairs(mgr.activeIcons or {}) do
        local seen = true
        pcall(function() seen = icon:getIsSeen() end)
        if not seen and icon.xCoord and icon.yCoord then
            local d = math.sqrt((icon.xCoord - p:getX()) ^ 2 + (icon.yCoord - p:getY()) ^ 2)
            if d <= reach and d < bd then best, bd = icon, d end
        end
    end
    if best then pcall(function() best:spotIcon() end) elseif mgr.currentZone then pcall(function() mgr:doMoveIconNearPlayer() end) end
    return tries >= 14
end)
S.step(90, function()
    local q = ZeD.ForagingTab._findQueues[pn] or {}
    local names = {}
    for i, e in ipairs(q) do if i <= 8 then names[#names + 1] = tostring(e.name) end end
    local mgr = ISSearchManager.getManager(p)
    S.say("forage: " .. #q .. " finds (" .. table.concat(names, ", ") .. ") | search " .. tostring(mgr and mgr.isSearchMode) .. " | sneaking " .. tostring(p:isSneaking()))
    pcall(function() p:setSneaking(true) end)
end)
-- (Nov 11: the World window sits at the left edge; Laura stays centered, clear of it on the right)
S.poll(10, 12, function() pcall(function() p:setSneaking(true) end); return false end)
-- (plan v2) the World window on the left, the Character window beside it on the right (their places swapped), the
-- fanny pack opened as the Character window's one source
local function swap()
    local c, w = ZeD_CharacterWindow.getWindow(), ZeD_WorldWindow.getWindow()
    if not (c and w and c:isVisible() and w:isVisible()) then return end
    if w:getX() < c:getX() then return end
    local gap = w:getX() - (c:getX() + c:getWidth())
    local x0 = c:getX()
    w:setX(x0)
    c:setX(x0 + w:getWidth() + gap)
    c._anchorRightEdge = c:getX() + c:getWidth()
end
local function colOn(win, inv)
    for i, cc in ipairs(win and win._containers or {}) do
        if cc.inventory == inv then
            for _, j in ipairs(win._mcSelected or {}) do if j == i then return true end end
            return false
        end
    end
    return false
end
S.step(10, function() swap() end)
S.poll(10, 60, function()
    local c = ZeD_CharacterWindow.getWindow()
    local inv = CLAU2_PACK and CLAU2_PACK:getInventory()
    if not inv then return true end
    if colOn(c, inv) then return true end
    ZeD_CharacterWindow.toggleColumn(inv)
    return false
end)
S.step(30, function() swap(); pcall(function() p:setSneaking(true) end) end)
C.whenStill(S, function()
    swap()
    S.say("pack column open " .. tostring(colOn(ZeD_CharacterWindow.getWindow(), CLAU2_PACK and CLAU2_PACK:getInventory())))
    C.boxes(S, "lau_forage")
end)
S.step(5, function() pcall(function() p:setSneaking(true) end); C.shot(S, "lau_forage") end)
S.step(10, function()
    local mgr = ISSearchManager.getManager(p)
    if mgr and mgr.isSearchMode then pcall(function() mgr:toggleSearchMode(false) end) end
    pcall(function() p:setSneaking(false) end)
    C.noWindows()
    if CLAU2_PACK then pcall(function() p:removeWornItem(CLAU2_PACK, false); p:getInventory():Remove(CLAU2_PACK) end) end
    CLAU2_PACK = nil
end)

-- CLAU2_ONLY = "forage" (gallery_cinema_laura2_forage.lua, run before this): the forage shot alone
if CLAU2_ONLY == "forage" then S.step(5, function() S.say("DONE") end); S.run(); return end
-- ---------------------------------------------------------------------------------------------- 2: fishing
local WSPOTS = { { 13933, 4563 }, { 6600, 5450 }, { 6150, 5550 }, { 7800, 5200 }, { 8500, 6000 }, { 10000, 6300 }, { 12000, 6900 } }
for pass = 1, 2 do
    for k = 1, #WSPOTS do
        S.step(5, function() if water then return end; C.moveTo(WSPOTS[k][1], WSPOTS[k][2], 0) end)
        S.step(150, function()
            if water then return end
            water = findShore(WSPOTS[k][1], WSPOTS[k][2], 40, (pass == 1) and "S" or nil)
            S.say("water spot " .. k .. " pass " .. pass .. ": " .. tostring(water and (water[1] .. "," .. water[2] .. " facing " .. water[3])))
        end)
    end
end
S.step(10, function()
    if not water then S.say("ERR no shore found"); return end
    C.moveTo(water[1], water[2], 0)
    p:setDir(IsoDirections[water[3]])
    local rod = nil
    for _, ft in ipairs({ "Base.FishingRod", "Base.FishingRodTwineLure", "Base.FishingRod_Twine" }) do
        local ok, it = pcall(function() return p:getInventory():AddItem(ft) end)
        if ok and it then rod = it; S.say("rod " .. ft); break end
    end
    if rod then
        pcall(function() p:setPrimaryHandItem(rod); p:setSecondaryHandItem(rod) end)
        pcall(function() triggerEvent("OnEquipPrimary", p, rod) end)
    else S.say("ERR no fishing rod item") end
end)
S.step(40, function() p:setDir(IsoDirections[water[3] or "E"]) end)
C.lookAround(S, "E")
S.step(10, function() if water then p:setDir(IsoDirections[water[3]]) end end)
zoomIn(S, 0.25)
-- the game's real fishing: the manager made for the rod runs its states (None -> Idle -> Cast -> Wait). The mouse aim is
-- stood in for by the water square to the front and the cast click by a flag (QA-side wrappers, put back after); the
-- game's own cast puts the bobber in the water and draws the line from the rod. The tension is then held at "tight".
local mgr, castNow = nil, false
local origAim, origCast = nil, nil
S.step(40, function()
    mgr = Fishing and Fishing.ManagerInstances and (Fishing.ManagerInstances[pn + 1] or Fishing.ManagerInstances[pn]) or nil
    if not mgr then S.say("ERR no fishing manager"); return end
    local d = { S = { 0, 1 }, E = { 1, 0 }, W = { -1, 0 }, N = { 0, -1 } }
    local dd = d[water[3]] or d.S
    local tx, ty = water[1] + dd[1] * 5 + 0.5, water[2] + dd[2] * 5 + 0.5
    origAim, origCast = Fishing.Utils.getAimCoords, Fishing.Utils.isCastButtonPressed
    Fishing.Utils.getAimCoords = function(pl, len) return tx, ty end
    Fishing.Utils.isCastButtonPressed = function(j) return castNow end
    pcall(function() p:setIsAiming(true) end)
    if getGameSpeed() <= 0 then setGameSpeed(1) end     -- (the bobber's spawn delay runs on the game clock)
    S.say("aim stood in for at " .. tx .. "," .. ty)
end)
local function stateName()
    if not mgr then return "none" end
    for k, v in pairs(mgr.states) do if v == mgr.state then return k end end
    return "?"
end
S.poll(10, 60, function()
    if not mgr then return true end
    pcall(function() p:setIsAiming(true) end)
    local st = stateName()
    if st == "Idle" then castNow = true end
    if st == "Cast" or st == "Wait" then castNow = false end
    S.say("fishing state " .. st .. " | player state " .. tostring(p:getCurrentState() and p:getCurrentState():getClass():getSimpleName()))
    return st == "Wait"
end)
S.step(60, function()
    if not mgr then return end
    castNow = false
    -- tight, whatever the line does
    mgr.updateTensionUI = function(self) self.tensionUI:updateValue(0.4) end
    mgr.tensionUI:setVisible(true)
    mgr.tensionUI:updateValue(0.4)
    CLAU2_UI = mgr.tensionUI
    S.say("state " .. stateName() .. "; bobber " .. tostring(mgr.fishingRod and mgr.fishingRod.bobber ~= nil) .. "; tension shown " .. tostring(mgr.tensionUI.zedTension))
end)
S.step(120, function() end)S.step(30, function() C.shot(S, "lau_fishing") end)
S.step(10, function()
    if origAim then Fishing.Utils.getAimCoords, Fishing.Utils.isCastButtonPressed = origAim, origCast end
    pcall(function() p:setIsAiming(false) end)
    if mgr then pcall(function() mgr:changeState("None") end); mgr.updateTensionUI = nil end
    if CLAU2_UI then CLAU2_UI:setVisible(false) end
    CLAU2_UI = nil
    pcall(function() p:setPrimaryHandItem(nil); p:setSecondaryHandItem(nil) end)
end)
S.step(30, function() S.say("DONE") end)
S.run()
