-- ZeDUI/tools/qa/zedqa_iron_mike.lua  (Nov 6 2026, Design; the survival guide's Iron Mike ad, round 1: a probe)
-- The director's reference (ZeD_design_refs/ads/ref_iron_mike_curl.png, reference only): a man in a white T-shirt
-- curling a dumbbell, three-quarter view, the dumbbell up by his face, against black. A 3D model (ISUI3DModel) over
-- a flat backdrop that covers all UI, in the fitness state with ExerciseType = bicepscurl, shot in bursts so one
-- frame lands at the top of the lift. Two subjects: a stand-in (SurvivorDesc, white tee) and the QA character
-- itself (white tee and a dumbbell in hand, to see whether the model carries hand items); the character's clothes
-- and hands are put back. Shots zqa_mike_*.png; grep "ZEDQA mike".
local function say(s) print("ZEDQA mike " .. tostring(s)) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() core:TakeFullScreenshot(n .. ".png") end); say("shot " .. n) end
local BLACK = { r = 0.02, g = 0.02, b = 0.02, a = 1 }
local GREEN = { r = 0, g = 0.72, b = 0.18, a = 1 }
local back, model, desc
local saved = { worn = {}, prim = nil, sec = nil }
local bell, tee

local function whiteTee()
    local it = instanceItem("Base.Tshirt_WhiteTINT")
    pcall(function() it:getVisual():setTint(ImmutableColor.new(1, 1, 1, 1)) end)
    pcall(function() it:setColor(Color.new(1, 1, 1, 1)) end)
    return it
end

local function fit(m)
    m:setState("fitness")
    m:setVariable("ExerciseType", "bicepscurl")
    pcall(function() m:setVariable("FitnessSpeed", 1.0) end)
    pcall(function() m:setVariable("ExerciseStarted", true) end)
    pcall(function() m:reportEvent("EventFitness") end)
end

step(30, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    desc = SurvivorFactory.CreateSurvivor()
    desc:setFemale(false)
    local hv = desc:getHumanVisual()
    pcall(function() hv:setHairModel("Short") end)
    pcall(function() hv:setBeardModel("") end)
    local worn = desc:getWornItems()
    worn:clear()
    for _, it in ipairs({ whiteTee(), instanceItem("Base.Trousers_Denim") }) do worn:setItem(it:getBodyLocation(), it) end
    back = ISPanel:new(0, 0, sw, sh)
    back:initialise()
    back.backgroundColor = BLACK
    back.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    back:addToUIManager()
    back:setAlwaysOnTop(true)
    model = ISUI3DModel:new(0, 0, sw, sh)
    model:initialise()
    model:instantiate()
    model:setIsometric(false)
    model:setDoRandomExtAnimations(false)
    pcall(function() model:setAnimateWhilePaused(true) end)
    model:setSurvivorDesc(desc)
    model:setDirection(IsoDirections.SE)
    model:setZoom(12)
    model:setYOffset(-0.6)
    model:addToUIManager()
    model:setAlwaysOnTop(true)
    fit(model)
    pcall(function() Mouse.setXY(sw - 2, sh - 2) end)
    say("stand-in up; state " .. tostring(model:getVariable("ExerciseType")))
end)

-- a burst: n frames, k ticks apart
local function burst(tag, n, k)
    for i = 1, n do step(k, function() shot("zqa_mike_" .. tag .. "_" .. string.format("%02d", i)) end) end
end

step(60, function() say("stand-in, SE") end)
burst("stand_se", 8, 10)

-- the QA character: white tee only above the waist, a dumbbell in the right hand
step(10, function()
    local wi = p:getWornItems()
    for i = 0, wi:size() - 1 do saved.worn[#saved.worn + 1] = wi:get(i):getItem() end
    saved.prim, saved.sec = p:getPrimaryHandItem(), p:getSecondaryHandItem()
    say("saved " .. #saved.worn .. " worn items")
    local keepLegs = {}
    for _, it in ipairs(saved.worn) do
        local loc = tostring(it:getBodyLocation())
        if loc:find("Pants") or loc:find("Shoes") or loc:find("Socks") or loc:find("Under") or loc:find("Belt") then keepLegs[#keepLegs + 1] = it end
    end
    wi:clear()
    for _, it in ipairs(keepLegs) do p:setWornItem(it:getBodyLocation(), it) end
    tee = p:getInventory():AddItem(whiteTee())
    p:setWornItem(tee:getBodyLocation(), tee)
    bell = p:getInventory():AddItem("Base.DumbBell")
    p:setPrimaryHandItem(bell)
    p:setSecondaryHandItem(nil)
    pcall(function() p:resetModelNextFrame() end)
    say("character dressed: tee and dumbbell; kept " .. #keepLegs)
end)
step(20, function()
    model:setCharacter(p)
    model:setDirection(IsoDirections.SE)
    fit(model)
end)
step(60, function() say("character, SE") end)
burst("char_se", 10, 8)
step(5, function() model:setDirection(IsoDirections.SW); fit(model) end)
step(60, function() say("character, SW") end)
burst("char_sw", 10, 8)
step(5, function() model:setDirection(IsoDirections.E); fit(model) end)
step(60, function() say("character, E") end)
burst("char_e", 6, 10)
step(5, function() back.backgroundColor = GREEN; model:setDirection(IsoDirections.SE); fit(model) end)
step(60, function() say("character, SE, on green") end)
burst("char_se_key", 10, 8)

-- put everything back
step(10, function()
    pcall(function() model:removeFromUIManager() end)
    pcall(function() back:removeFromUIManager() end)
    local wi = p:getWornItems()
    wi:clear()
    for _, it in ipairs(saved.worn) do pcall(function() p:setWornItem(it:getBodyLocation(), it) end) end
    p:setPrimaryHandItem(saved.prim)
    p:setSecondaryHandItem(saved.sec)
    pcall(function() p:getInventory():Remove(bell) end)
    pcall(function() p:getInventory():Remove(tee) end)
    pcall(function() p:resetModelNextFrame() end)
    say("put back: " .. p:getWornItems():size() .. " worn items, the hands, the tee and dumbbell removed")
end)
step(10, function() say("DONE") end)

local function tick()
    local q = Q[qi + 1]
    if not q then Events.OnTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnTick.Add(tick)
say("start")
