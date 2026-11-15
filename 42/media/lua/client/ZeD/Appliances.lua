-- ZeD-UI/42/media/lua/client/ZeD/Appliances.lua
-- ============================================================================
-- ADDITIONAL APPLIANCE SUPPORT (Nov 15 2026, appliances). Client.
--
-- ZeD setup's switch "Additional appliance support" (Settings.lua, id "appliances"; off in every preset) makes
-- more of the game's appliances work. The first is the espresso machine (Mov_Espresso, tiles
-- appliances_cooking_01_60 to _63, one per facing): the game has it as furniture only, while the coffee
-- maker beside it works.
--
-- With the switch on the machine gets "Make espresso": in its right-click menu and on A when the player faces
-- it on a controller (the game's own A prompt, ISButtonPrompt, so ZeD's hint strip shows it too). It runs the
-- game's own coffee maker recipe, MakeCoffeeMug (media/scripts/generated/entities/appliances/workstations/
-- entity_coffeemachine_craftRecipe.txt: 5 uses of a can of coffee, Base.Coffee2; 0.2 L of water from any
-- container; an empty mug, tag base:coffeemaker, given back as the matching hot drink, Base.HotDrink... by its
-- itemMapper; OnCreate RecipeCodeOnCreate.makeCoffee), or MakeCoffeeTeacup for a teacup when there is no mug.
-- It is run through the game's own craft action, ISHandcraftAction, built as ZeD's Crafting tab builds it
-- (CraftingTab.startCraft), so the inputs are used and the coffee made by the game's own code, on the server
-- in multiplayer, as the coffee maker does. It needs power on the machine's square, asked as the game asks
-- for its own powered appliances (ISEntityUI.CanOpenWindowFor: haveElectricity or hasGridPower), before the
-- walk and again while the coffee is made.
--
-- Nothing is kept on the tile: no new item, no new fluid, no container, no mod data. A save stays sound if
-- the switch or ZeD goes away; the coffee made is the game's own item.
--
-- STAYING OUT OF THE WAY. If something else already makes the machine work, ZeD adds nothing to it:
--   * the tile has a game entity (a mod gave it a crafting window, as the coffee maker has one): checked
--     with ISEntityUI.GetEntityUiConfig;
--   * the tile has a container (a mod turned it into one);
--   * Functional Appliances 2 (Workshop 3042138819, global FA): its tile lists (FA.hotdogMachines and the
--     rest, shared/FATiles.lua) are searched for the espresso tiles, and any FA list named for espresso
--     counts. Its 42.20 build has no espresso machine, so today it never matches.
-- Also looked at (Nov 15 2026, the mods installed here): More Builds (builds the machine as decoration),
-- Lifestyle (gives the tile a beauty value only), Better Building Plus and Hands On Interactions (name the
-- tile only). None makes it work, so none is checked.
--
-- Design draws the machine's face later; this file draws nothing.
-- ============================================================================

require "ZeD/Tr"
require "ZeD/CraftingCore"

ZeD = ZeD or {}
ZeD.Appliances = ZeD.Appliances or {}
local A = ZeD.Appliances

-- the espresso machine's tiles, one per facing (Mov_Espresso's own is _61)
local ESPRESSO = {
    appliances_cooking_01_60 = true, appliances_cooking_01_61 = true,
    appliances_cooking_01_62 = true, appliances_cooking_01_63 = true,
}
-- the game's coffee maker recipes, the mug first
local RECIPES = { "MakeCoffeeMug", "MakeCoffeeTeacup" }

--- The switch is on (ZeD setup, Additional appliance support).
function A.on()
    local S = ZeD.Settings
    if not (S and S.appliancesOn) then return false end
    local ok, v = pcall(S.appliancesOn)
    return ok and v == true
end

--- True when obj is an espresso machine.
function A.isEspresso(obj)
    if not obj then return false end
    local ok, name = pcall(function() return obj:getSprite():getName() end)
    return ok and name ~= nil and ESPRESSO[name] == true
end

--- Power on a square, as the game asks for its own powered appliances (ISEntityUI.CanOpenWindowFor): a
--- generator's or the grid's.
function A.powered(sq)
    if not sq then return false end
    local ok, on = pcall(function() return sq:haveElectricity() end)
    if ok and on == true then return true end
    ok, on = pcall(function() return sq:hasGridPower() end)
    return ok and on == true
end

-- Functional Appliances 2 lists the espresso machine (looked up once a game, after every mod has loaded)
-- (A.faAnswer: nil until asked; cleared at each game start)
local function faHasEspresso()
    if A.faAnswer ~= nil then return A.faAnswer end
    local found = false
    if type(FA) == "table" then
        pcall(function()
            for k, v in pairs(FA) do
                if type(v) == "table" then
                    if type(k) == "string" and string.find(string.lower(k), "espresso", 1, true) then found = true end
                    for _, s in ipairs(v) do
                        if type(s) == "string" and ESPRESSO[s] then found = true end
                    end
                end
            end
        end)
    end
    A.faAnswer = found
    return found
end

--- True when something else already makes this machine work (see STAYING OUT OF THE WAY, above).
function A.steppedAside(obj)
    local ok, cfg = pcall(function() return ISEntityUI and ISEntityUI.GetEntityUiConfig and ISEntityUI.GetEntityUiConfig(obj) end)
    if ok and cfg then return true end
    local okN, n = pcall(function() return obj:getContainerCount() end)
    if okN and n and n > 0 then return true end
    return faHasEspresso()
end

-- the machine ZeD offers Make espresso on, or nil
local function offered(obj)
    return A.isEspresso(obj) and not A.steppedAside(obj)
end

--- The coffee maker's recipe the player can make at this machine now, the mug first; nil when the water, the
--- coffee or a mug is missing. containers: the player's inventory and worn bags (CC.buildContainers). The
--- craft's own check, as ZeD's Crafting tab asks it (CraftingTab.startCheck): from across the room the
--- check's reach to the machine fails, so there it goes by what the recipe takes; the walk comes first.
function A.recipeFor(playerObj, machine, containers)
    local sm = getScriptManager()
    for _, name in ipairs(RECIPES) do
        local recipe = sm and sm:getCraftRecipe(name)
        if recipe then
            local ok, can = pcall(function()
                local l = HandcraftLogic.new(playerObj, nil, machine)
                l:setContainers(containers)
                l:setRecipe(recipe)
                if l:canPerformCurrentRecipe() then return true end
                if not l:isCharacterInRangeOfWorkbench() then return l:getPossibleCraftCount(true) > 0 end
                return false
            end)
            if ok and can then return recipe end
        end
    end
    return nil
end

local function badNote(playerObj, key)
    if HaloTextHelper and HaloTextHelper.addBadText then pcall(HaloTextHelper.addBadText, playerObj, ZeD.tr(key)) end
end

-- the craft action asked again each update: the power cut while the coffee is made stops it, as the game's
-- own check does for the craft (ISHandcraftAction:isValid)
local function stillPowered(self)
    local sq = self.isoObject and self.isoObject:getSquare()
    if not A.powered(sq) then return false end
    return ISHandcraftAction.isValid(self)
end

--- Make espresso: power and the things checked, a walk to the machine, then the game's craft action.
--- Returns true when the action was queued.
function A.makeEspresso(playerObj, machine)
    if not (A.on() and playerObj and machine and offered(machine)) then return false end
    local sq = machine:getSquare()
    if not A.powered(sq) then badNote(playerObj, "UI_ZeD_Espresso_NeedPower"); return false end
    local CC = ZeD.CraftingCore
    local containers = CC.buildContainers(playerObj)
    local recipe = A.recipeFor(playerObj, machine, containers)
    if not recipe then badNote(playerObj, "UI_ZeD_Espresso_NeedThings"); return false end
    if not luautils.walkAdj(playerObj, sq, true) then return false end
    -- Built as ZeD's Crafting tab builds its crafts (CraftingTab.startCraft): ISHandcraftAction:new hands its
    -- manualInputs to convertToPZNetTable, which fails on nil and false, and start() wants them falsy so it finds
    -- the inputs from the recipe. The machine is the action's object, so the player faces it.
    local ok = pcall(function()
        local action = ISBaseTimedAction.new(ISHandcraftAction, playerObj)
        action.stopOnAim    = false
        action.character    = playerObj
        action.isoObject    = machine
        action.craftBench   = nil
        action.containers   = containers
        action.manualInputs = nil
        action.craftRecipe  = recipe
        action.actionScript = recipe:getTimedActionScript()
        action.stopOnWalk   = true
        action.stopOnRun    = true
        action.variableInputRatio = 1
        action.eatPercentage = 0
        action.maxTime      = recipe:getTime(playerObj) * 5   -- (ISHandcraftAction:getDuration's time: 40 for a mug)
        if playerObj:isTimedActionInstant() then action.maxTime = 1 end
        action.isValid      = stillPowered
        ISTimedActionQueue.add(action)
    end)
    return ok
end

-- ----- THE RIGHT-CLICK MENU -----
-- the machines on the clicked squares
local function machinesIn(worldobjects)
    local out, seen = {}, {}
    for _, o in ipairs(worldobjects) do
        local okS, sq = pcall(function() return o:getSquare() end)
        if okS and sq and not seen[sq] then
            seen[sq] = true
            local objs = sq:getObjects()
            for i = 0, objs:size() - 1 do
                local x = objs:get(i)
                if offered(x) then out[#out + 1] = x end
            end
        end
    end
    return out
end

local function onMenuMake(playerObj, machine)
    A.makeEspresso(playerObj, machine)
end

function A.onFillWorld(pn, context, worldobjects, test)
    if not A.on() then return end
    local playerObj = getSpecificPlayer(pn)
    if not (playerObj and context and worldobjects) or playerObj:getVehicle() then return end
    local list = machinesIn(worldobjects)
    local machine = list[1]
    if not machine then return end
    if test then return ISWorldObjectContextMenu.setTest() end
    local option = context:addGetUpOption(ZeD.tr("UI_ZeD_Espresso_Make"), playerObj, onMenuMake, machine)
    -- what is missing, said on the option as the game says it (greyed, with a tooltip)
    local why = nil
    if not A.powered(machine:getSquare()) then
        why = "UI_ZeD_Espresso_NeedPower"
    elseif not A.recipeFor(playerObj, machine, ZeD.CraftingCore.buildContainers(playerObj)) then
        why = "UI_ZeD_Espresso_NeedThings"
    end
    if why and option then
        option.notAvailable = true
        local tip = ISWorldObjectContextMenu.addToolTip()
        tip:setVisible(false)
        tip.description = ZeD.tr(why)
        option.toolTip = tip
    end
end

-- ----- A ON A CONTROLLER -----
-- The game's A prompt (ISButtonPrompt:testInteractButtonAction, once for each square the player faces):
-- when the game offers nothing there, a machine on that square offers Make espresso. Pressed without power or
-- the things, it says what is missing over the player's head, as the game's own refusals do.
local function promptMake(bp, machine)
    A.makeEspresso(getSpecificPlayer(bp.player), machine)
end

function A.testInteract(bp, dir)
    if bp.aPrompt ~= nil or not A.on() then return end
    local playerObj = getSpecificPlayer(bp.player)
    if not playerObj or playerObj:getVehicle() then return end
    local sq1 = playerObj:getCurrentSquare()
    local sq2 = sq1 and sq1:getAdjacentSquare(dir)
    if not sq2 then return end
    local objs = sq2:getObjects()
    for i = 0, objs:size() - 1 do
        local x = objs:get(i)
        if offered(x) then
            bp:setButtonBindingPrompt(CharacterJoypadButtonBinding.Interact, ZeD.tr("UI_ZeD_Espresso_Make"), promptMake, x)
            return
        end
    end
end

-- ----- HOOKS (through ZeD.Appliances, so a reload replaces the handlers without adding more) -----
if not ZeD._appliancesHooked then
    ZeD._appliancesHooked = true
    Events.OnFillWorldObjectContextMenu.Add(function(...) return ZeD.Appliances.onFillWorld(...) end)
    Events.OnGameStart.Add(function() ZeD.Appliances.faAnswer = nil end)
    if ISButtonPrompt and ISButtonPrompt.testInteractButtonAction then
        local orig = ISButtonPrompt.testInteractButtonAction
        ISButtonPrompt.testInteractButtonAction = function(self, dir)
            orig(self, dir)
            local ok, err = pcall(ZeD.Appliances.testInteract, self, dir)
            if not ok then print("[ZeD] Appliances: A prompt: " .. tostring(err)) end
        end
    end
end
