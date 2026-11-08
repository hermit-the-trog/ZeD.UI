-- ZeDUI/tools/qa/zedqa_iron_mike2.lua  (Nov 6 2026, Design; the survival guide's Iron Mike ad, round 2)
-- Round 1 (zedqa_iron_mike.lua): the model stayed in idle (the UI model's default anim set has no fitness state) and
-- the QA character's model showed the rifle on the back but no dumbbell in hand. Here: a male stand-in only, the
-- "player" anim set, the fitness state with ExerciseType = bicepscurl; Spongie's Character Customisation's muscle
-- overlay (the director, Nov 6: "use Spongy's character mod and the body texture from that"; Base.M_Muscle, texture
-- choice 5 = M_MuscleStrong01) under a white tee; and a census of the Java model's methods and fields, to find a way
-- to put the dumbbell in his hand. Run with SPNCC on: zedqa_mods_run.ps1 -ModList iron_mike_mods.txt.
-- Shots zqa_mike2_*.png; grep "ZEDQA mike2".
local function say(s) print("ZEDQA mike2 " .. tostring(s)) end
local core = getCore()
local sw, sh = core:getScreenWidth(), core:getScreenHeight()
local Q, qi, wait = {}, 0, 0
local function step(n, fn) Q[#Q + 1] = { n = n, fn = fn } end
local function shot(n) pcall(function() core:TakeFullScreenshot(n .. ".png") end); say("shot " .. n) end
local BLACK = { r = 0.02, g = 0.02, b = 0.02, a = 1 }
local GREEN = { r = 0, g = 0.72, b = 0.18, a = 1 }
local back, model, desc

local function census(o, label, pat)
    local ok, n = pcall(getNumClassFunctions, o)
    if not ok or not n then say(label .. " no class functions (" .. tostring(n) .. ")"); return end
    local hits = {}
    for i = 0, n - 1 do
        local f = getClassFunction(o, i)
        local s = tostring(f)
        if s:find(pat) then hits[#hits + 1] = s:match("([%w_]+%b())") or s end
    end
    say(label .. " " .. n .. " functions; matching: " .. table.concat(hits, ", "))
    local okf, nf = pcall(getNumClassFields, o)
    if okf and nf then
        local fs = {}
        for i = 0, nf - 1 do fs[#fs + 1] = tostring(getClassField(o, i)):match("([%w_]+)$") or "?" end
        say(label .. " fields: " .. table.concat(fs, ", "))
    end
end
local function field(o, name)
    local ok, nf = pcall(getNumClassFields, o)
    if not ok or not nf then return nil end
    for i = 0, nf - 1 do
        local f = getClassField(o, i)
        if tostring(f):match("([%w_]+)$") == name then return getClassFieldVal(o, f) end
    end
end

local function worn(items)
    local w = desc:getWornItems()
    w:clear()
    for _, spec in ipairs(items) do
        local it = instanceItem(spec.t)
        if not it then say("ERR no item " .. spec.t)
        else
            if spec.tint then pcall(function() it:getVisual():setTint(ImmutableColor.new(1, 1, 1, 1)) end) end
            if spec.choice then pcall(function() it:getVisual():setTextureChoice(spec.choice) end) end
            w:setItem(it:getBodyLocation(), it)
        end
    end
    model:setSurvivorDesc(desc)
end
local DRESS = {
    { t = "Base.Tshirt_WhiteTINT", tint = true },
    { t = "Base.Trousers_Denim" },
    { t = "Base.M_Muscle", choice = 5 },
}
local function curl(dir)
    model:setDirection(dir)
    model:setState("fitness")
    model:setVariable("ExerciseType", "bicepscurl")
    pcall(function() model:setVariable("FitnessSpeed", 1.0) end)
    pcall(function() model:setVariable("ExerciseStarted", true) end)
    pcall(function() model:setVariable("ExerciseEnded", false) end)
    pcall(function() model:reportEvent("EventFitness") end)
end

step(30, function()
    pcall(function()
        local ui = UIManager.getUI()
        for i = 0, ui:size() - 1 do local e = ui:get(i); if e:getClass():getSimpleName() == "UIDebugConsole" then e:setVisible(false) end end
    end)
    say("SPNCC active " .. tostring(getActivatedMods():contains("SPNCC")) .. ", M_Muscle item " .. tostring(getScriptManager():FindItem("Base.M_Muscle") ~= nil))
    desc = SurvivorFactory.CreateSurvivor()
    desc:setFemale(false)
    local hv = desc:getHumanVisual()
    pcall(function() hv:setHairModel("Short") end)
    pcall(function() hv:setBeardModel("") end)
    pcall(function() hv:setSkinTextureIndex(1) end)
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
    model:setAnimSetName("player")
    worn(DRESS)
    model:setZoom(11)
    model:setYOffset(-0.75)
    model:addToUIManager()
    model:setAlwaysOnTop(true)
    curl(IsoDirections.SE)
    pcall(function() Mouse.setXY(sw - 2, sh - 2) end)
    census(model.javaObject, "UI3DModel", "Hand|Item|Model|Light|Attach|Anim|State|Weapon")
    local am = field(model.javaObject, "animatedModel")
    say("animatedModel " .. tostring(am))
    if am then census(am, "AnimatedModel", "Hand|Item|Light|Attach|Weapon|Model") end
end)

-- the dumbbell: try the likely calls on the Java model, each logged
step(10, function()
    local am = field(model.javaObject, "animatedModel")
    local tries = {
        { "UI3DModel:setPrimaryHandModelName", function() model.javaObject:setPrimaryHandModelName("DumbBell") end },
        { "AnimatedModel:setPrimaryHandModelName", function() am:setPrimaryHandModelName("DumbBell") end },
        { "AnimatedModel:setPrimaryHandModelName(Base.)", function() am:setPrimaryHandModelName("Base.DumbBell") end },
    }
    for _, t in ipairs(tries) do
        local ok, err = pcall(t[2])
        say("hand try " .. t[1] .. ": " .. (ok and "ok" or ("no: " .. tostring(err))))
    end
end)

local function burst(tag, n, k)
    for i = 1, n do step(k, function() shot("zqa_mike2_" .. tag .. "_" .. string.format("%02d", i)) end) end
end
step(90, function() say("SE, zoom 11"); say("ExerciseType=" .. tostring(model:getVariable("ExerciseType"))) end)
burst("se", 12, 6)
step(5, function() curl(IsoDirections.SW) end)
step(90, function() say("SW, zoom 11") end)
burst("sw", 12, 6)
step(5, function() model:setZoom(9); model:setYOffset(-0.6); curl(IsoDirections.SE) end)
step(90, function() say("SE, zoom 9") end)
burst("se_z9", 8, 8)
step(5, function() back.backgroundColor = GREEN; model:setZoom(11); model:setYOffset(-0.75); curl(IsoDirections.SE) end)
step(90, function() say("SE on green") end)
burst("se_key", 12, 6)
step(10, function()
    pcall(function() model:removeFromUIManager() end)
    pcall(function() back:removeFromUIManager() end)
    say("stand-in and backdrop removed")
end)
step(10, function() say("DONE") end)

-- (run 1 of this script: with SPNCC on, the game came up paused after the prelude and OnTick never ran; so the
-- steps ride OnRenderTick, which runs paused too, and every step first takes the pause off)
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
