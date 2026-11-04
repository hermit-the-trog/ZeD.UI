-- ZeDUI/tools/qa/zedqa_author_portrait.lua  (Nov 3 2026, QA; the survival guide's author photo, for Build)
-- A stand-in man (SurvivorFactory, the QA character untouched): short dark hair, a moustache, horn-rimmed glasses,
-- a flannel shirt. Drawn as a 3D bust (ISUI3DModel, as the Identity tab's) over a plain wall-coloured backdrop that
-- covers the screen, so no game or ZeD UI shows. Shots at three framings and three angles (straight on and both
-- three-quarter turns): Screenshots/zqa_author_<dir>_<zoom>.png. Everything made is removed after. grep "ZEDQA aut".
local function say(s) print("ZEDQA aut " .. tostring(s)) end
local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local back, model, desc

step(30, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    desc = SurvivorFactory.CreateSurvivor()
    desc:setFemale(false)
    local hv = desc:getHumanVisual()
    hv:setHairModel("Short")
    hv:setBeardModel("Moustache")
    local dark = ImmutableColor.new(0.16, 0.11, 0.07, 1)
    pcall(function() hv:setHairColor(dark) end)
    pcall(function() hv:setBeardColor(dark) end)
    local worn = desc:getWornItems()
    worn:clear()
    for _, ft in ipairs({ "Base.Tshirt_DefaultTEXTURE_TINT", "Base.Shirt_Lumberjack", "Base.Glasses_Normal_HornRimmed", "Base.Trousers_Denim" }) do
        local it = instanceItem(ft)
        local loc = it and it:getBodyLocation()
        if loc then worn:setItem(loc, it) else say("ERR no body location for " .. ft) end
    end
    say("stand-in: hair " .. tostring(hv:getHairModel()) .. ", beard " .. tostring(hv:getBeardModel()) .. ", worn " .. worn:size())

    -- the wall behind: a plain warm grey, the whole screen (covers the HUD and both ZeD windows)
    back = ISPanel:new(0, 0, sw, sh)
    back:initialise()
    back.backgroundColor = { r = 0.62, g = 0.6, b = 0.56, a = 1 }
    back.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    back:addToUIManager()
    back:setAlwaysOnTop(true)

    model = ISUI3DModel:new(0, 0, sw, sh)
    model:initialise()
    model:instantiate()
    model:setState("idle")
    model:setIsometric(false)
    model:setDoRandomExtAnimations(false)
    pcall(function() model:setAnimateWhilePaused(true) end)
    model:setSurvivorDesc(desc)
    model:setDirection(IsoDirections.S)
    model:setZoom(19)
    model:setYOffset(-0.875)
    model:addToUIManager()
    model:setAlwaysOnTop(true)
    pcall(function() Mouse.setXY(sw - 2, sh - 2) end)
end)

local frames = { { z = 16, y = -0.85 }, { z = 20, y = -0.88 }, { z = 24, y = -0.9 } }
local dirs = { { d = "S", v = IsoDirections.S }, { d = "SW", v = IsoDirections.SW }, { d = "SE", v = IsoDirections.SE } }
for _, f in ipairs(frames) do
    for _, d in ipairs(dirs) do
        step(10, function()
            model:setDirection(d.v); model:setZoom(f.z); model:setYOffset(f.y)
            back:bringToTop(); model:bringToTop()
        end)
        step(90, function()
            local n = "zqa_author_" .. d.d .. "_" .. f.z
            pcall(function() getCore():TakeFullScreenshot(n .. ".png") end)
            say("shot " .. n)
        end)
    end
end
step(20, function()
    pcall(function() model:removeFromUIManager() end)
    pcall(function() back:removeFromUIManager() end)
    say("put back: the stand-in and the backdrop removed (the QA character untouched)")
    say("DONE")
end)

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
