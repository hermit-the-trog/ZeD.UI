-- ZeDUI/tools/qa/zedqa_new_qa_save.lua  (Oct 15 2026)
-- Makes a fresh zombie-free QA save from the main menu through vanilla's
-- debug-scenario path (DebugScenarios:launchScenario without its window):
-- Sandbox mode, zombie population None (last value of the "Zombies" option,
-- population multipliers 0), save folder Saves/Sandbox/ZeD-QA. Once the game
-- is running the character gets god mode and is moved to the middle of the
-- largest clear outdoor patch near the start. Copy to Zomboid/Lua/zedqa.lua
-- at the main menu and bump zedqa.go; grep console.txt for "ZEDQA ns".
-- After "click to start", run it again in game to do the move.

local function say(s) print("ZEDQA ns " .. tostring(s)) end

if not getPlayer() then
    local opts = getSandboxOptions()
    local zo = opts:getOptionByName("Zombies")
    local n = zo and zo:getNumValues() or 6
    say("zombies option values=" .. tostring(n))
    debugScenarios = debugScenarios or {}
    debugScenarios.ZeDQA = {
        name = "ZeD QA",
        startLoc = { x = 10580, y = 11193, z = 0 },   -- the highway south of Muldraugh: road and fields
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
    selectedDebugScenario = debugScenarios.ZeDQA
    selectedDebugScenario.setSandbox()
    getWorld():setGameMode("Sandbox")
    getWorld():setMap("Muldraugh, KY")
    -- the save's mod list: vanilla's New Game copies the active mods into it
    -- (MainScreen "SOLO"); this path skips that, and on Oct 23 the save came
    -- out with no mods, so ZeD (and the bridge) never loaded in it
    pcall(function() ActiveMods.getById("currentGame"):copyFrom(ActiveMods.getById("default")) end)
    createWorld("ZeD-QA")
    GameWindow.doRenderEvent(false)
    Events.OnNewGame.Add(DebugScenarios.ongamestart)
    forceChangeState(LoadingQueueState.new())
    say("launched")
    return
end

-- in game: god mode, then find the clear patch and move there
local p = getPlayer()
p:setGodMod(true)
local cell = getCell()
local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), 0
local function clear(sq)
    if not sq or not sq:isOutside() or not sq:getFloor() then return false end
    if not sq:isFree(false) or sq:HasTree() or sq:getVehicleContainer() then return false end
    if sq:getProperties():has(IsoFlagType.water) then return false end
    return true
end
-- side of the largest clear square patch with (x, y) as its top-left corner, capped at 16
local best, bx, by = 0, px, py
for y = py - 50, py + 50, 2 do
    for x = px - 50, px + 50, 2 do
        local s = 0
        while s < 16 do
            local ok = true
            for i = 0, s do
                if not clear(cell:getGridSquare(x + s, y + i, pz)) or not clear(cell:getGridSquare(x + i, y + s, pz)) then ok = false; break end
            end
            if not ok then break end
            s = s + 1
        end
        if s > best then best, bx, by = s, x, y end
    end
end
local cx, cy = bx + math.floor(best / 2), by + math.floor(best / 2)
say(string.format("start %d,%d best patch %d at %d,%d -> move to %d,%d zombies=%d", px, py, best, bx, by, cx, cy, cell:getZombieList():size()))
p:teleportTo(cx + 0.5, cy + 0.5, 0)   -- vanilla's debug teleport
say("moved; god=" .. tostring(p:isGodMod()))
