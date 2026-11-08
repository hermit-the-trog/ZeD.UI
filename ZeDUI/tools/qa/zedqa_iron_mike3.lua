-- ZeDUI/tools/qa/zedqa_iron_mike3.lua  (Nov 6 2026, Design; the survival guide's Iron Mike ad, round 3)
-- Round 2: the stand-in curls on the UI model, but a UI model holds nothing (the dumbbell rides the hand only in the
-- real exercise: ISFitnessAction's override hand models). The director: "give the character a dumbbell". So the
-- character himself does the real biceps curl: made a man (short dark hair, no beard), white tee, jeans and
-- Spongie's strongest muscle overlay (Base.M_Muscle, choice 5), the rifle off his back, a dumbbell in hand. Then:
-- (A) a UI model of him (setCharacter) on green, to see whether the hand model carries over; (B) the world itself,
-- UI hidden, zoomed all the way in, facing south and south-west. Only for zedqa_mods_run.ps1 (SPNCC on; the save is
-- put back from its snapshot afterwards, so the changes to the character leave no trace). Shots zqa_mike3_*.png.
local function say(s) print("ZEDQA mike3 " .. tostring(s)) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() core:TakeFullScreenshot(n .. ".png") end); say("shot " .. n) end
local function burst(tag, n, k)
    for i = 1, n do step(k, function() shot("zqa_mike3_" .. tag .. "_" .. string.format("%02d", i)) end) end
end
local GREEN = { r = 0, g = 0.72, b = 0.18, a = 1 }
local back, model, bell, hidden

local function put(t, choice)
    local it = p:getInventory():AddItem(t)
    if not it then say("ERR no item " .. t); return end
    if t:find("Tshirt") then pcall(function() it:getVisual():setTint(ImmutableColor.new(1, 1, 1, 1)) end) end
    if choice then pcall(function() it:getVisual():setTextureChoice(choice) end) end
    p:setWornItem(it:getBodyLocation(), it)
end

step(30, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    say("SPNCC active " .. tostring(getActivatedMods():contains("SPNCC")))
    pcall(function() p:setGodMod(true) end)
    pcall(function() p:getDescriptor():setFemale(false) end)
    pcall(function() p:setFemale(false) end)
    local hv = p:getHumanVisual()
    pcall(function() hv:setHairModel("Short") end)
    pcall(function() hv:setBeardModel("") end)
    pcall(function() hv:setHairColor(ImmutableColor.new(0.12, 0.09, 0.07, 1)) end)
    p:getWornItems():clear()
    pcall(function() p:clearAttachedItems() end)
    pcall(function() p:getAttachedItems():clear() end)
    put("Base.Tshirt_WhiteTINT")
    put("Base.Trousers_Denim")
    put("Base.M_Muscle", 5)
    bell = p:getInventory():AddItem("Base.DumbBell")
    p:setPrimaryHandItem(bell)
    p:setSecondaryHandItem(nil)
    pcall(function() p:resetModelNextFrame() end)
    pcall(function() p:resetModel() end)
    p:setDir(IsoDirections.S)
    say("dressed: female " .. tostring(p:isFemale()) .. ", worn " .. p:getWornItems():size() .. ", hand " .. tostring(p:getPrimaryHandItem()))
end)
step(30, function()
    pcall(function() p:getFitness():init() end)
    local data = FitnessExercises.exercisesType.bicepscurl
    ISTimedActionQueue.add(ISFitnessAction:new(p, "bicepscurl", 30, data, "bicepscurl"))
    say("curl queued")
end)
step(120, function() say("action " .. tostring(ISTimedActionQueue.getTimedActionQueue(p).queue[1] and ISTimedActionQueue.getTimedActionQueue(p).queue[1].Type)) end)

-- (A) the UI model of him, on green
step(5, function()
    back = ISPanel:new(0, 0, sw, sh)
    back:initialise()
    back.backgroundColor = GREEN
    back.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    back:addToUIManager()
    back:setAlwaysOnTop(true)
    model = ISUI3DModel:new(0, 0, sw, sh)
    model:initialise()
    model:instantiate()
    model:setIsometric(false)
    model:setDoRandomExtAnimations(false)
    pcall(function() model:setAnimateWhilePaused(true) end)
    model:setAnimSetName("player")
    model:setCharacter(p)
    model:setDirection(IsoDirections.SE)
    model:setZoom(11)
    model:setYOffset(-0.75)
    model:setState("fitness")
    model:setVariable("ExerciseType", "bicepscurl")
    pcall(function() model:setVariable("FitnessSpeed", 1.0) end)
    model:addToUIManager()
    model:setAlwaysOnTop(true)
    pcall(function() Mouse.setXY(sw - 2, sh - 2) end)
end)
step(60, function() say("UI model of the character") end)
burst("ui", 8, 8)
step(5, function()
    pcall(function() model:removeFromUIManager() end)
    pcall(function() back:removeFromUIManager() end)
end)

-- (B) the world: every UI element hidden, zoomed all the way in
step(5, function()
    hidden = {}
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e:isVisible() then e:setVisible(false); hidden[#hidden + 1] = e end
    end
    UIManager.setVisibleAllUI(false)
    say("hid " .. #hidden .. " UI elements")
end)
for _ = 1, 14 do step(4, function() core:doZoomScroll(0, -1) end) end
step(60, function() say("world, facing S, zoom " .. tostring(core:getZoom(0))) end)
burst("world_s", 10, 8)
step(5, function() p:setDir(IsoDirections.SW) end)
step(40, function() say("world, facing SW") end)
burst("world_sw", 10, 8)
step(5, function() p:setDir(IsoDirections.E) end)
step(40, function() say("world, facing E") end)
burst("world_e", 8, 8)
step(5, function()
    UIManager.setVisibleAllUI(true)
    for _, e in ipairs(hidden or {}) do pcall(function() e:setVisible(true) end) end
    pcall(function() ISTimedActionQueue.clear(p) end)
    say("UI back, action cleared (the save is put back from its snapshot by zedqa_mods_run.ps1)")
end)
step(10, function() say("DONE") end)

-- (rides OnRenderTick and takes the pause off each step: with SPNCC on the game came up paused in round 2)
local function tick()
    pcall(function() if isGamePaused() then setGameSpeed(1); togglePause() end end)
    local q = Q[qi + 1]
    if not q then Events.OnRenderTick.Remove(tick); return end
    wait = wait + 1
    if wait < q.n then return end
    wait = 0
    qi = qi + 1
    local ok, err = pcall(q.fn)
    if not ok then say("ERR step " .. qi .. ": " .. tostring(err)) end
end
Events.OnRenderTick.Add(tick)
say("start")
