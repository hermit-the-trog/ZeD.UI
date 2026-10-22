-- ZeDUI/tools/qa/zedqa_new_shot_save.lua  (Oct 21 2026)
-- A zombie-free save for the Workshop gallery, one per character (director, Oct 21:
-- "use multiple characters, female and male"). Based on zedqa_new_qa_save.lua:
-- vanilla's debug-scenario path from the main menu, Sandbox, zombie population
-- None, save folder Saves/Sandbox/<ZEDQA_CHAR.save>. The run puts a config table
-- above this header:
--   ZEDQA_CHAR = { save = "ZeD-Shots-Maggie", female = true, forename = "Maggie",
--                  surname = "Sutter", x = 10637, y = 10418,
--                  hair = "Bob", beard = nil, skin = 1 }
-- At the main menu it makes the world; run it again in game (after "click to
-- start") for god mode, the whole map known (the Maps shots), the hair and skin.
-- Never unattended (it makes a save). grep "ZEDQA nss".
local function say(s) print("ZEDQA nss " .. tostring(s)) end
local C = ZEDQA_CHAR
if not C then say("ERR no ZEDQA_CHAR"); return end

if not getPlayer() then
    local opts = getSandboxOptions()
    local zo = opts:getOptionByName("Zombies")
    local n = zo and zo:getNumValues() or 6
    -- the character: who, before the world is made (DebugScenarios.ongamestart dresses
    -- MainScreen.instance.desc in a random everyday outfit and hands it to the player)
    local ms = MainScreen and MainScreen.instance
    if not ms then say("ERR no MainScreen"); return end
    local desc = ms.desc
    if not desc then
        desc = SurvivorFactory.CreateSurvivor(SurvivorType.Neutral, C.female and true or false)
        ms.desc = desc
    end
    desc:setFemale(C.female and true or false)
    desc:setForename(C.forename)
    desc:setSurname(C.surname)
    debugScenarios = debugScenarios or {}
    debugScenarios.ZeDShots = {
        name = "ZeD shots",
        startLoc = { x = C.x, y = C.y, z = 0 },
        setSandbox = function()
            SandboxVars.Zombies = n
            SandboxVars.ZombieConfig = SandboxVars.ZombieConfig or {}
            SandboxVars.ZombieConfig.PopulationMultiplier = 0.0
            SandboxVars.ZombieConfig.PopulationStartMultiplier = 0.0
            SandboxVars.ZombieConfig.PopulationPeakMultiplier = 0.0
            SandboxVars.VehicleEasyUse = true
            pcall(function() opts:getOptionByName("Zombies"):setValue(n) end)
            pcall(function() opts:getOptionByName("ZombieConfig.PopulationMultiplier"):setValue(0.0) end)
            pcall(function() opts:getOptionByName("ZombieConfig.PopulationStartMultiplier"):setValue(0.0) end)
            pcall(function() opts:getOptionByName("ZombieConfig.PopulationPeakMultiplier"):setValue(0.0) end)
            pcall(function() opts:toLua() end)
        end,
        onStart = function() end,
    }
    selectedDebugScenario = debugScenarios.ZeDShots
    selectedDebugScenario.setSandbox()
    ZeD = ZeD or {}
    ZeD.QAAutoload = true   -- (ZeD setup's first-run page stays shut)
    getWorld():setGameMode("Sandbox")
    getWorld():setMap("Muldraugh, KY")
    createWorld(C.save)
    GameWindow.doRenderEvent(false)
    Events.OnNewGame.Add(DebugScenarios.ongamestart)
    forceChangeState(LoadingQueueState.new())
    say("launched " .. C.save .. " (" .. C.forename .. " " .. C.surname .. ", " .. (C.female and "female" or "male") .. ")")
    return
end

-- in game
local p = getPlayer()
p:setGodMod(true)
pcall(function() p:getDescriptor():setForename(C.forename); p:getDescriptor():setSurname(C.surname) end)
local ok = pcall(function() WorldMapVisited.getInstance():setKnownInSquares(0, 0, 20000, 17000) end)
pcall(function()
    local v = p:getHumanVisual()
    if C.hair then v:setHairModel(C.hair) end
    if C.beard ~= nil then v:setBeardModel(C.beard) end
    if C.skin then v:setSkinTextureIndex(C.skin) end
end)
pcall(function() p:resetModelNextFrame() end)
pcall(function() if getPlayerInventory(0) then end end)
say(string.format("in game: %s %s, %s, at %d,%d | map known %s | world %s",
    tostring(p:getDescriptor():getForename()), tostring(p:getDescriptor():getSurname()),
    p:isFemale() and "female" or "male", math.floor(p:getX()), math.floor(p:getY()), tostring(ok), tostring(getWorld():getWorld())))
say("DONE")
