-- ZeDUI/tools/qa/zedqa_author_portrait2.lua  (Nov 3 2026, QA; the survival guide's author photo, second brief)
-- The director's reference (Screenshots/guide_author/reference_author_pose.png, kept out of the repo): straight on,
-- head and upper chest, short brown hair combed to the side, big square glasses, a full moustache, a plaid shirt,
-- indoors. A stand-in man (the QA character untouched) as a 3D bust (ISUI3DModel), over a flat backdrop that covers
-- all UI: on green (for Build to cut out and lay over the interior) and on a warm grey wall. Two glasses and two
-- shirts. Then the interior plate: the Fossoil store at West Point (shelves, counter), daylight, every UI element
-- hidden, the character see-through, the camera fully in. Shots zqa_author2_*.png; grep "ZEDQA au2".
local function say(s) print("ZEDQA au2 " .. tostring(s)) end
local p = getPlayer()
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() core:TakeFullScreenshot(n .. ".png") end); say("shot " .. n) end
local back, model, desc
local GREEN = { r = 0, g = 0.72, b = 0.18, a = 1 }
local WALL = { r = 0.62, g = 0.6, b = 0.56, a = 1 }

local function dress(glasses, shirt)
    local worn = desc:getWornItems()
    worn:clear()
    for _, ft in ipairs({ "Base.Tshirt_DefaultTEXTURE_TINT", shirt, glasses, "Base.Trousers_Denim" }) do
        local it = instanceItem(ft)
        local loc = it and it:getBodyLocation()
        if loc then worn:setItem(loc, it) else say("ERR no body location for " .. ft) end
    end
    model:setSurvivorDesc(desc)
end

step(30, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    desc = SurvivorFactory.CreateSurvivor()
    desc:setFemale(false)
    local hv = desc:getHumanVisual()
    hv:setHairModel("LeftParting")
    hv:setBeardModel("Moustache")
    local brown = ImmutableColor.new(0.30, 0.19, 0.11, 1)
    pcall(function() hv:setHairColor(brown) end)
    pcall(function() hv:setBeardColor(brown) end)
    say("stand-in: hair " .. tostring(hv:getHairModel()) .. ", beard " .. tostring(hv:getBeardModel()))
    back = ISPanel:new(0, 0, sw, sh)
    back:initialise()
    back.backgroundColor = GREEN
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
    model:setDirection(IsoDirections.S)
    model:setZoom(17)
    model:setYOffset(-0.8)
    dress("Base.Glasses_Prescription", "Base.Shirt_Lumberjack")
    model:addToUIManager()
    model:setAlwaysOnTop(true)
    pcall(function() Mouse.setXY(sw - 2, sh - 2) end)
end)

-- (run 1: Glasses_Prescription draws as silver aviators; the horn-rimmed square frames are the reference's. The
-- flannel takes a random colour each time it is made: four of them, Build picks)
local looks = {
    { g = "Base.Glasses_Normal_HornRimmed", s = "Base.Shirt_Lumberjack", tag = "a" },
    { g = "Base.Glasses_Normal_HornRimmed", s = "Base.Shirt_Lumberjack", tag = "b" },
    { g = "Base.Glasses_Normal_HornRimmed", s = "Base.Shirt_Lumberjack", tag = "c" },
    { g = "Base.Glasses_Normal_HornRimmed", s = "Base.Shirt_Lumberjack_Green", tag = "d" },
}
for _, bg in ipairs({ { c = GREEN, tag = "key" }, { c = WALL, tag = "wall" } }) do
    for _, lk in ipairs(looks) do
        step(10, function()
            back.backgroundColor = bg.c
            dress(lk.g, lk.s)
            model:setZoom(16); model:setYOffset(-0.85)
            back:bringToTop(); model:bringToTop()
        end)
        step(90, function() shot("zqa_author2_" .. bg.tag .. "_" .. lk.tag) end)
    end
end
-- two more framings of the first look on green (a little wider, a little closer)
for _, f in ipairs({ { z = 15, y = -0.85 }, { z = 17, y = -0.88 } }) do
    step(10, function()
        back.backgroundColor = GREEN
        dress(looks[1].g, looks[1].s)
        model:setZoom(f.z); model:setYOffset(f.y)
    end)
    step(90, function() shot("zqa_author2_key_a_z" .. f.z) end)
end
step(10, function()
    pcall(function() model:removeFromUIManager() end)
    pcall(function() back:removeFromUIManager() end)
    say("bust done: the stand-in and the backdrop removed")
end)

-- the interior plate: the Fossoil store, West Point (the gallery story's store: shelves and the counter)
local was = {}
step(10, function()
    was.x, was.y, was.z, was.tod, was.zoom = p:getX(), p:getY(), p:getZ(), getGameTime():getTimeOfDay(), core:getZoom(0)
    getGameTime():setTimeOfDay(11.0)
    p:teleportTo(12056.5, 7123.5, 0)
    pcall(function() p:setX(12056.5); p:setY(7123.5); p:setZ(0); p:setLastX(12056.5); p:setLastY(7123.5); p:setLastZ(0) end)
    say("to the Fossoil store")
end)
step(600, function()
    pcall(function() p:setAlpha(0, 0) end)
    pcall(function() p:setTargetAlpha(0, 0) end)
    pcall(function() p:setAlphaAndTarget(0, 0) end)
    -- every UI element hidden one by one (setVisibleAllUI leaves ZeD's windows up), put back after
    was.hidden = {}
    local ui = UIManager.getUI()
    for i = 0, ui:size() - 1 do
        local e = ui:get(i)
        if e:isVisible() then e:setVisible(false); was.hidden[#was.hidden + 1] = e end
    end
    UIManager.setVisibleAllUI(false)
    say("hid " .. #was.hidden .. " UI elements")
end)
for _ = 1, 12 do step(4, function() core:doZoomScroll(0, -1) end) end
step(120, function() say("zoom " .. tostring(core:getZoom(0))); shot("zqa_author2_interior_store") end)
for _, d in ipairs({ { 2, 0, "e" }, { 0, -2, "n" } }) do
    step(10, function() p:teleportTo(12056.5 + d[1], 7123.5 + d[2], 0) end)
    step(120, function() shot("zqa_author2_interior_store_" .. d[3]) end)
end
step(10, function()
    UIManager.setVisibleAllUI(true)
    for _, e in ipairs(was.hidden or {}) do pcall(function() e:setVisible(true) end) end
    pcall(function() local ui = UIManager.getUI(); for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end end)
    pcall(function() p:setAlphaAndTarget(0, 1) end)
    pcall(function() p:setTargetAlpha(0, 1) end)
    p:teleportTo(was.x, was.y, was.z)
    pcall(function() p:setX(was.x); p:setY(was.y); p:setZ(was.z); p:setLastX(was.x); p:setLastY(was.y); p:setLastZ(was.z) end)
    getGameTime():setTimeOfDay(was.tod)
end)
for _ = 1, 12 do step(4, function() if core:getZoom(0) < was.zoom then core:doZoomScroll(0, 1) end end) end
step(60, function() say("put back: the UI, the character's place, the clock and the zoom"); say("DONE") end)

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
