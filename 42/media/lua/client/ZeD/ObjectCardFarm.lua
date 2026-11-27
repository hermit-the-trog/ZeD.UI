-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardFarm.lua
-- ============================================================================
-- OBJECT CARD: FARM PLOTS (HOOK_MAP row 12)
-- Client; one card kind for ZeD.ObjectCards (ObjectCards.lua draws the frame,
-- this def fills it). The World window's card for a plot under the pointer.
-- The plant card keeps vanilla's Farming-skill gates: the phase reads at
-- Farming 2, pests at 3 (+2 with a magnifier in hand), the water bar at 4 and
-- the next-stage timing at 6; health and fertilizer are never shown. A locked
-- reading carries a "Farming n" tag. Levels use vanilla's words. The garden
-- strip and the header arrows step through every plot in reach (vanilla's
-- info cursor); plowed land gets a Sow list with season tags (Farming 6 or
-- the crop's season recipe, as vanilla's tooltip).
-- Verbs queue vanilla's own timed actions directly: vanilla's menu handlers
-- also arm a click-another-square cursor and skip controller players.
-- ============================================================================

require "ZeD/ObjectCards"

local OC = ZeD.ObjectCards
local UI = OC.ui
local call = OC.call
local DOT = OC.DOT

-- (translation keys, shown through ZeD.tr where they are drawn)
local PHASES = { "Farming_Seedling", "Farming_Young", "UI_ZeD_Farm_PhaseAlmostReady",
                 "UI_ZeD_Farm_PhaseReady", "Farming_In_bloom", "Farming_Rotten" }

-- label is a translation key; sprayName is the English fallback if the game has no name for the spray
local PESTS = {
    { key = "mildewLvl", label = "Farming_Mildew",  cure = "Mildew", spray = "GardeningSprayMilk",       sprayName = "Mildew Spray" },
    { key = "fliesLvl",  label = "Farming_Pest_Flies",   cure = "Flies",  spray = "GardeningSprayCigarettes", sprayName = "Pest Flies Spray" },
    { key = "aphidLvl",  label = "Farming_Aphids",  cure = "Aphids", spray = "GardeningSprayAphids",     sprayName = "Aphids Spray" },
    { key = "slugsLvl",  label = "Farming_Slugs",   cure = "Slugs",  spray = "SlugRepellent",            sprayName = "Slug Repellent" },
}

local function farmSys() return CFarmingSystem and CFarmingSystem.instance or nil end
local function txt(k, fb) local s = getTextOrNull and getTextOrNull(k) return s or fb or k end

-- vanilla's predicateGoodSeed (local in ISFarmingMenu)
local function goodSeed(item)
    if not item then return false end
    if not instanceof(item, "Food") then return true end
    if item:isRotten() or item:isCooked() or item:isBurnt() then return false end
    if item:hasTag(ItemTag.IS_CUTTING) and not item:isFresh() then return false end
    local baseHunger = math.abs(item:getBaseHunger())
    local hungerChange = math.abs(item:getHungerChange())
    if item:isFresh() and hungerChange < baseHunger then return false end
    if not item:isFresh() and hungerChange < (baseHunger * 0.75) then return false end
    return true
end

local function sprayUses(item) return item:getCurrentUses() >= 1 end

local function findSpray(player, sprayType)
    local h = player:getPrimaryHandItem()
    if h and h:getType() == sprayType and h:getCurrentUses() > 0 then return h end
    return player:getInventory():getFirstTypeEvalRecurse(sprayType, sprayUses)
end

local function hasMagnifier(player)
    local p, s = player:getPrimaryHandItem(), player:getSecondaryHandItem()
    return (p and p:hasTag(ItemTag.MAGNIFIER)) or (s and s:hasTag(ItemTag.MAGNIFIER)) or false
end

-- Every container he carries with water, the one in his hand first (it is the default, as the game's menu offers
-- it alone), then the rest biggest first. The game's menu lists only the hand item while it holds water; the card
-- lists them all, so a pick can be made and kept: with the soda in hand, Use on the bottle then Water poured from
-- the soda, the list at the press holding the hand item alone (QA FA8, Nov 26 2026; the director's call FA8).
local function waterSources(player)
    local out = {}
    local h = player:getPrimaryHandItem()
    local handHas = h and ISFarmingMenu.getWaterUsesInteger(h) > 0
    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it ~= h and ISFarmingMenu.getWaterUsesInteger(it) > 0 then out[#out + 1] = it end
    end
    table.sort(out, function(a, b) return ISFarmingMenu.getWaterUsesInteger(a) > ISFarmingMenu.getWaterUsesInteger(b) end)
    if handHas then table.insert(out, 1, h) end
    return out
end

-- (the director's call FA8, Nov 26 2026) the container Water pours from: the one he picked in the card's list,
-- while he still carries it with water in it; else the biggest, the card's default before the list
local function sameItem(a, b)
    if a == nil or b == nil then return false end
    if a == b then return true end
    local ia = call(a, "getID")
    return ia ~= nil and ia == call(b, "getID")
end
local function pickedSource(t, list)
    if t.waterPick then
        for _, it in ipairs(list) do
            if sameItem(it, t.waterPick) then return it end
        end
    end
    return list[1]
end

-- What a source holds, for its row: litres in a fluid container, else the game's uses.
local function sourceAmount(it)
    local fc = call(it, "getFluidContainer")
    local amt = fc and tonumber(call(fc, "getAmount"))
    if amt then return string.format("%.1f L", amt) end
    return tostring(ISFarmingMenu.getWaterUsesInteger(it))
end

-- (the director's call FA7, Nov 26 2026) how many uses one Treat sprays. Mildew, flies and slugs: one, the only
-- amount the game's menu offers. Aphids: what the plant needs, as the game's menu offers 1 to 10 at once
-- (ISFarmingMenu, the aphids submenu): each use kills 10 + his Farming level (SPlantGlobalObject.cureAphids, the
-- level ISCurePlantAction passes), so the level over that, at least 1, at most 10 and what the spray holds.
local function sprayUsesFor(cure, plant, spray, player)
    if cure ~= "Aphids" then return 1 end
    local skill = tonumber(call(player, "getPerkLevel", Perks and Perks.Farming)) or 0
    local need = math.ceil((plant and plant.aphidLvl or 0) / (10 + skill))
    local have = tonumber(call(spray, "getCurrentUses")) or 1
    return math.max(1, math.min(need, 10, have))
end

local function cropName(plant) return txt("Farming_" .. tostring(plant.typeOfSeed), tostring(plant.typeOfSeed)) end

-- 0-based phase index on the strip, or nil (plowed / dead)
local function phaseIndex(plant)
    if plant.state == "rotten" then return 5 end
    if not plant:isAlive() then return nil end
    local prop = farming_vegetableconf.props[plant.typeOfSeed]
    if plant.hasSeed then return 4 end
    if plant.hasVegetable then return 3 end
    if prop and plant.nbOfGrow and plant.nbOfGrow == prop.harvestLevel then return 2 end
    if plant.nbOfGrow and plant.nbOfGrow <= 2 then return 0 end
    return 1
end

-- vanilla's water words (ISFarmingInfo.getWaterLvl: fixed levels, the same for every crop)
local function waterWord(lvl)
    if lvl > 80 then return txt("Farming_Well_watered", "Well watered") end
    if lvl > 60 then return txt("Farming_Fine", "Fine") end
    if lvl > 50 then return txt("Farming_Thirsty", "Thirsty") end
    if lvl > 25 then return txt("Farming_Dry", "Dry") end
    return txt("Farming_Parched", "Parched")
end

-- The water mark, by the crop's own need: vanilla's ISFarmingInfo.getWaterLvlColor, rule for rule. Returns
-- the colour and a rank (0 fine, 1 orange, 2 red), or nil below Farming 3 or on a plant that is not alive.
-- (QA FA2, Nov 26 2026: fixed levels read "Fine" in green on a crop needing 80 at 65, where the game is orange
-- and the crop does not grow; vanilla colours from Farming 3, the card drew no mark there.)
local function waterMark(plant, skill)
    local T = ZeD.T
    if (skill or 0) < 3 or not plant:isAlive() then return nil, 0 end
    local lvl, need = plant.waterLvl or 0, plant.waterNeeded or 0
    -- the first stage must have its need: red under it
    if plant.nbOfGrow == 1 then
        if lvl < need then return T.danger, 2 end
        return T.positive, 0
    end
    local water = farming_vegetableconf.calcWater(plant.waterNeeded, plant.waterLvl)
    local waterMax = farming_vegetableconf.calcWater(plant.waterLvl, plant.waterNeededMax)
    if water >= 0 and waterMax >= 0 then return T.positive, 0 end
    if water == -1 or waterMax == -1 then return T.warning, 1 end
    return T.danger, 2
end

-- Each crop's garden label: the shortest start of its name (three letters or more) that no other crop's name
-- shares, worked out once per language. (QA FA11, Nov 26 2026: three letters made Bro of Broccoli and
-- Broadleaf Plantain, Com of Comfrey and Common Mallow, Ros of Rosemary and Roses.)
local labelCache = { lang = nil, map = nil }
local function gardenLabel(typeOfSeed)
    local lang = "?"
    pcall(function() lang = tostring(Translator.getLanguage()) end)
    if labelCache.lang ~= lang or not labelCache.map then
        local names = {}
        for k, _ in pairs(farming_vegetableconf.props) do names[k] = txt("Farming_" .. tostring(k), tostring(k)) end
        local map = {}
        for k, n in pairs(names) do
            local L = 3
            while L < #n do
                local pre = string.sub(n, 1, L)
                local clash = false
                for k2, n2 in pairs(names) do
                    if k2 ~= k and n2 ~= n and string.sub(n2, 1, L) == pre then clash = true; break end
                end
                -- (never end on a space or a dash: "Chou " reads as "Chou")
                local last = string.sub(pre, L, L)
                if not clash and last ~= " " and last ~= "-" then break end
                L = L + 1
            end
            map[k] = string.sub(n, 1, L)
        end
        labelCache.lang, labelCache.map = lang, map
    end
    local s = labelCache.map[typeOfSeed]
    if s then return s end
    return string.sub(txt("Farming_" .. tostring(typeOfSeed), tostring(typeOfSeed)), 1, 3)
end

local function pestWord(lvl)
    local T = ZeD.T
    if lvl <= 0 then return txt("Farming_None", "None"), nil end
    if lvl < 10 then return txt("Farming_Light", "Light"), T.warning end
    if lvl < 30 then return txt("Farming_Moderate", "Moderate"), T.warning end
    return txt("Farming_Heavy", "Heavy"), T.danger
end

-- Most urgent need of a plot for the garden strip (honours the pest gate, and the water mark's: QA FA2, the
-- cell's water reading is vanilla's getWaterLvlColor, from Farming 3).
local function urgency(plant, pestsVisible, skill)
    local T = ZeD.T
    if plant.state == "plow" then return nil, 0 end
    if not plant:isAlive() then return T.danger, 3 end
    local wc, wr = waterMark(plant, skill)
    if wr == 2 then return T.danger, 2 end
    if pestsVisible then
        for _, p in ipairs(PESTS) do
            if (plant[p.key] or 0) >= 30 then return T.danger, 2 end
        end
    end
    if wr == 1 then return T.warning, 1 end
    if pestsVisible then
        for _, p in ipairs(PESTS) do
            if (plant[p.key] or 0) > 0 then return T.warning, 1 end
        end
    end
    -- (below Farming 3 a living plant reads nothing: no mark, as vanilla's tooltip)
    if not wc and not pestsVisible then return nil, 0 end
    return T.positive, 0
end

local def = { id = "plant", keepOnLoss = true }

local function targetFor(plant)
    local sq = plant:getSquare()
    if not sq then return nil end
    return { obj = plant, sq = sq, key = OC.keyOf(sq, "plant") }
end

--- obj: a CPlantGlobalObject, or anything with a square.
function def.resolve(player, obj)
    local sys = farmSys()
    if not (sys and obj) then return nil end
    local sq = call(obj, "getSquare")
    local plant = sq and sys:getLuaObjectOnSquare(sq)
    if not plant then return nil end
    return targetFor(plant)
end

function def.valid(t)
    local sys = farmSys()
    local plant = sys and sys:getLuaObjectOnSquare(t.sq)
    if not plant then return false end
    t.obj = plant
    pcall(function() plant:updateFromIsoObject() end)
    return plant:getIsoObject() ~= nil
end

function def.nearby(player)
    local list = {}
    local sys = farmSys()
    if not sys then return list end
    OC.eachSquare(player, OC.LEASH, function(sq)
        local plant = sys:getLuaObjectOnSquare(sq)
        if plant and plant:getIsoObject() then   -- skip a plot dug up this frame
            local t = targetFor(plant)
            if t then list[#list + 1] = t end
        end
    end)
    return OC.sortTargets(list)
end

-- ---------------------------------------------------------------------------
-- REFRESH
-- ---------------------------------------------------------------------------
local function seedRows(player, skill)
    local rows = {}
    local inv = player:getInventory()
    local seasons = getSandboxOptions():getOptionByName("PlantGrowingSeasons"):getValue() == true
    local month = getGameTime():getMonth() + 1
    local function inList(list)
        if not list then return false end
        for _, m in ipairs(list) do if m == month then return true end end
        return false
    end
    for typeOfSeed, props in pairs(farming_vegetableconf.props) do
        local seedTypes = props.seedTypes or { props.seedName }
        for _, seedName in ipairs(seedTypes) do
            local n = seedName and inv:getCountTypeEvalRecurse(seedName, goodSeed) or 0
            if n > 0 then
                local si = getScriptManager():FindItem(seedName)
                local row = {
                    typeOfSeed = typeOfSeed, seedName = seedName, count = n,
                    name = ((si and si:getDisplayName()) or seedName) .. " (" .. tostring(n) .. ")",
                    tex = si and call(si, "getNormalTexture") or nil,
                }
                local knows = skill >= 6 or (props.seasonRecipe and player:isRecipeActuallyKnown(props.seasonRecipe))
                if seasons and knows and props.sowMonth then
                    local T = ZeD.T
                    if inList(props.bestMonth) then row.tag, row.tagC = ZeD.tr("Farming_Tooltip_BestMonth2"), T.positive
                    elseif inList(props.riskMonth) then row.tag, row.tagC = ZeD.tr("UI_ZeD_Farm_TagRiskyMonth"), T.warning
                    elseif inList(props.sowMonth) then row.tag, row.tagC = ZeD.tr("UI_ZeD_Farm_TagInSeason"), T.positive
                    else row.tag, row.tagC = ZeD.tr("Farming_Tooltip_BadMonth"), T.danger end
                end
                rows[#rows + 1] = row
            end
        end
    end
    table.sort(rows, function(a, b) return a.name < b.name end)
    return rows
end

function def.refresh(t, player)
    local plant = t.obj
    local sys = farmSys()
    local d = {}
    d.skill = sys:getXp(player)
    d.pestSkill = d.skill + (hasMagnifier(player) and 2 or 0)
    d.state = plant.state
    d.plowed = plant.state == "plow"
    d.alive = (not d.plowed) and plant:isAlive()
    d.name = farming_vegetableconf.getObjectName(plant) or ZeD.tr("UI_ZeD_Farm_Plot")
    local props = farming_vegetableconf.props[plant.typeOfSeed]
    d.tex = props and props.icon and getTexture(props.icon) or nil
    d.phase = (not d.plowed) and phaseIndex(plant) or nil
    d.water = plant.waterLvl or 0
    d.waterNeeded = plant.waterNeeded or 0
    d.waterMax = plant.waterNeededMax or 100
    d.firstStage = plant.nbOfGrow == 1
    d.waterC = (not d.plowed) and waterMark(plant, d.skill) or nil
    d.compost = plant.compost and true or false
    d.next = nil
    if d.alive and d.skill >= 6 then
        local ok, s = pcall(ISFarmingInfo.getNextGrowingPhase, { plant = plant, character = player })
        if ok and s then d.next = ZeD.tr("UI_ZeD_Farm_NextIn", string.lower(tostring(s))) end
    end
    d.pests = {}
    for _, p in ipairs(PESTS) do
        d.pests[#d.pests + 1] = { def = p, lvl = plant[p.key] or 0, spray = findSpray(player, p.spray) }
    end
    d.month = txt("Farming_Month_" .. tostring(getGameTime():getMonth() + 1), "")
    d.seeds = d.plowed and seedRows(player, d.skill) or {}
    d.shovel = ISFarmingMenu.getShovel(player)
    d.water_src = (d.alive and plant.state == "seeded" and d.water < 100) and waterSources(player) or {}
    local inv = player:getInventory()
    d.fert = (not d.plowed) and (inv:getFirstTypeRecurse("Fertilizer") or inv:getFirstTagRecurse(ItemTag.FERTILIZER)) or nil
    d.compostItem = (not d.plowed) and (inv:getFirstTypeRecurse("CompostBag") or inv:getFirstTagRecurse(ItemTag.COMPOST)) or nil
    local pestsVisible = d.pestSkill >= 3
    t.d = d
    -- (the director's call FA7, Nov 26 2026) a pest row's Treat: one walk, one equip and the game's cure action
    -- with every use the plant needs (sprayUsesFor) and the game's time for them, 10 * (uses * 10); heavy aphids
    -- took five presses, a walk and a use each
    t.treat = function(p, pestDef)
        local spray = findSpray(p, pestDef.spray)
        if not spray or not ISFarmingMenu.walkToPlant(p, t.sq) then return end
        local uses = sprayUsesFor(pestDef.cure, t.obj, spray, p)
        ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), spray, true)
        ISTimedActionQueue.add(ISCurePlantAction:new(p, spray, uses, t.obj, 10 * (uses * 10), pestDef.cure))
    end

    local verbs = {}
    if d.plowed then
        verbs[#verbs + 1] = { id = "sow", label = getText("ContextMenu_Sow_Seed"), enabled = #d.seeds > 0, primary = #d.seeds > 0, jump = "farm:sow:1",
            needs = ZeD.tr("UI_ZeD_Farm_NeedsSeeds"), hint = ZeD.tr("UI_ZeD_Farm_HintSow"), help = ZeD.tr("UI_ZeD_Farm_HelpSow") }
    else
        local seeded = plant.state == "seeded"
        local canHarvest = plant:canHarvest()
        local thirstyOK = d.alive and seeded and d.water < 100
        local canWater = thirstyOK and #d.water_src > 0
        -- (QA FA2/FA3: under the crop's own need counts as thirsty too, so Water leads on a crop needing 80 at 65)
        local thirsty = d.water <= 60 or d.water < d.waterNeeded
        -- a plant that is dead, or full of water, is not watered; one not ripe is not harvested:
        -- those verbs are gone (sensible = false); the rest wait for what they need
        verbs[#verbs + 1] = { id = "water", label = getText("ContextMenu_Water"), enabled = canWater, primary = canWater and thirsty and not canHarvest,
            sensible = thirstyOK, needs = ZeD.tr("UI_ZeD_Farm_NeedsWater"), hint = ZeD.tr("UI_ZeD_Farm_HintWater"),
            help = ZeD.tr("UI_ZeD_Farm_HelpWater"),
            run = function(p, tt)
                local src = pickedSource(tt, waterSources(p))   -- (FA8: the picked one, else the biggest)
                local pl = tt.obj
                if not src or not pl then return end
                local use = math.min(ISFarmingMenu.getWaterUsesInteger(src), math.ceil((100 - (pl.waterLvl or 0)) / 10), 10)
                if use < 1 then return end
                if p:getPrimaryHandItem() ~= src then ISTimedActionQueue.add(ISEquipWeaponAction:new(p, src, 50, true)) end
                if not ISFarmingMenu.walkToPlant(p, tt.sq) then return end
                ISTimedActionQueue.add(ISWaterPlantAction:new(p, src, use, tt.sq, 20 + (6 * use)))
            end }
        verbs[#verbs + 1] = { id = "fert", label = ZeD.tr("UI_ZeD_Farm_Fertilize"), enabled = d.fert ~= nil,
            needs = ZeD.tr("UI_ZeD_Farm_NeedsFertilizer"), hint = ZeD.tr("UI_ZeD_Farm_HintFertilize"), help = ZeD.tr("UI_ZeD_Farm_HelpFertilize"),
            run = function(p, tt)
                local inv2 = p:getInventory()
                local it = inv2:getFirstTypeRecurse("Fertilizer") or inv2:getFirstTagRecurse(ItemTag.FERTILIZER)
                if not it or not ISFarmingMenu.walkToPlant(p, tt.sq) then return end
                local hand = ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), it, true)
                ISTimedActionQueue.add(ISFertilizeAction:new(p, hand or it, tt.obj, 100))
            end }
        if d.compostItem then
            verbs[#verbs + 1] = { id = "compost", label = getText("Farming_Compost"), enabled = true,
                help = ZeD.tr("UI_ZeD_Farm_HelpCompost"),
                run = function(p, tt)
                    local inv2 = p:getInventory()
                    local it = inv2:getFirstTypeRecurse("CompostBag") or inv2:getFirstTagRecurse(ItemTag.COMPOST)
                    if not it or not ISFarmingMenu.walkToPlant(p, tt.sq) then return end
                    local hand = ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), it, true)
                    ISTimedActionQueue.add(ISFertilizeAction:new(p, hand or it, tt.obj, 100))
                end }
        end
        local anySpray, firstTreat = false, nil
        for i, pe in ipairs(d.pests) do
            if pe.spray then
                anySpray = true
                if not firstTreat or (pestsVisible and pe.lvl > 0 and d.pests[firstTreat].lvl <= 0) then firstTreat = i end
            end
        end
        -- the spray it would ask for: the first pest you can see that has none
        local sprayNeed = ZeD.tr("UI_ZeD_Farm_NeedsSpray")
        if pestsVisible then
            for _, pe in ipairs(d.pests) do
                if pe.lvl > 0 and not pe.spray then sprayNeed = ZeD.tr("UI_ZeD_Farm_NeedsSprayNamed", OC.itemName(pe.def.spray, pe.def.sprayName)); break end
            end
        end
        verbs[#verbs + 1] = { id = "treat", label = ZeD.tr("UI_ZeD_Farm_Treat"), enabled = seeded and anySpray, jump = firstTreat and ("farm:treat:" .. firstTreat) or nil,
            sensible = d.alive and seeded, needs = sprayNeed, hint = ZeD.tr("UI_ZeD_Farm_HintTreat"), help = ZeD.tr("UI_ZeD_Farm_HelpTreat") }
        verbs[#verbs + 1] = { id = "harvest", label = getText("ContextMenu_Harvest"), enabled = canHarvest, primary = canHarvest, sensible = canHarvest,
            help = ZeD.tr("UI_ZeD_Farm_HelpHarvest"),
            run = function(p, tt)
                if ISFarmingMenu.walkToPlant(p, tt.sq) then ISTimedActionQueue.add(ISHarvestPlantAction:new(p, tt.obj, 100)) end
            end }
        verbs[#verbs + 1] = { id = "dig", label = ZeD.tr("UI_ZeD_Farm_DigUp"), enabled = d.shovel ~= nil, danger = true,
            needs = ZeD.tr("UI_ZeD_Farm_NeedsShovel"), hint = ZeD.tr("UI_ZeD_Farm_HintDig"), help = ZeD.tr("UI_ZeD_Farm_HelpDig"),
            confirm = d.alive and ZeD.tr("UI_ZeD_Farm_ConfirmDig", string.lower(cropName(plant))) or ZeD.tr("UI_ZeD_Farm_ConfirmClear", string.lower(d.name)),
            run = function(p, tt)
                -- (QA FA12, Nov 26 2026: a shovel dropped between Dig up and Yes queued the dig with no tool, and the
                -- game's action threw every tick. The tool is looked for again at Yes; none, and nothing is queued.)
                local shovel = ISFarmingMenu.getShovel(p)
                if not shovel then
                    if HaloTextHelper and HaloTextHelper.addBadText then
                        pcall(HaloTextHelper.addBadText, p, ZeD.tr("UI_ZeD_Disclose_Needs", ZeD.btnCase(ZeD.tr("UI_ZeD_Farm_DigUp")), ZeD.tr("UI_ZeD_Farm_NeedsShovel")))
                    end
                    return
                end
                if not ISFarmingMenu.walkToPlant(p, tt.sq) then return end
                local hand = ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), shovel, true)
                ISTimedActionQueue.add(ISShovelAction:new(p, hand or shovel, tt.obj, 40))
            end }
    end
    t.verbs = verbs
    t.pestsVisible = pestsVisible
end

-- Where the pad lands when the card opens. (QA FA3, Nov 26 2026: with no choice here it fell on the first lit
-- verb, Fertilize on a watered plant, and A gave a dose.) Water when it is the card's main verb (lit, the plant
-- thirsty), Sow on plowed land (it only moves to the seed list); otherwise the back button, never a verb that
-- spends something.
function def.openFocus(t)
    for _, v in ipairs(t.verbs or {}) do
        if (v.id == "water" or v.id == "sow") and v.primary and v.enabled ~= false then return "oc:verb:" .. v.id end
    end
    return "oc:back"
end

function def.title(t) return ZeD.tr("UI_ZeD_Farm_Plot") end
function def.icon(t)
    local d = t.d
    if not d then return nil end
    if d.tex then return d.tex end
    -- plowed land: the furrow tile
    local tile = farming_vegetableconf.getSpriteName and farming_vegetableconf.getSpriteName(t.obj)
    local tex = tile and getTexture(tile)
    return tex and (call(tex, "splitIcon") or tex) or nil
end
--- The state tag: its words, and the colour of its square mark (none for a plain tag).
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.plowed then return ZeD.tr("UI_ZeD_Farm_PillEmpty"), T.textDim end
    if d.state == "rotten" then return ZeD.tr("Farming_Rotten"), T.danger end
    -- (QA FA11, Nov 26 2026: a trampled plant read "Dead" where the game's name says "Destroyed Carrots": the game's
    -- own word, without the brackets some languages put round it)
    if d.state == "destroyed" then
        local s = string.gsub(getText("Farming_Destroyed"), "[%(%)]", "")
        return OC.cap(s), T.danger
    end
    if not d.alive then return OC.cap(d.state == "harvested" and getText("Farming_Harvested") or getText("Farming_Dead")), T.danger end
    -- (QA's visual noise audit 31, Nov 20 2026: "Ready" sat in the title, the heading and the stage strip. A living
    -- plant's tag only repeated the heading, the strip or the water row under it; the tag stays for dead and rotten.)
    return nil
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
local function lockTag(n) return ZeD.tr("UI_ZeD_Farm_LockTag", n) end

local function drawPlantTag(card, x, y, w, d, title, sub)
    local T, tm = ZeD.T, ZeD.TM
    local ps = T.px(40)
    UI.fill(card, x, y, ps, ps, "surf2")
    ZeD.Atoms.frame(card, x, y, ps, ps, T.borderS)
    if d.tex then card:drawTextureScaledAspect(d.tex, x + T.px(4), y + T.px(4), ps - 2 * T.px(4), ps - 2 * T.px(4), 1, 1, 1, 1) end
    local tx = x + ps + T.px(10)
    local nameY = y + T.px(2)
    UI.big(card, ZeD.CraftingCore.truncText(title, T.fontF4, w - ps - T.px(10)), tx, nameY, 17, T.text)
    local f3 = T.fontF3
    card:drawText(sub, tx, y + ps - tm:getFontHeight(f3) - T.px(1), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f3)
    return ps
end

-- The stages as one framed strip (Seedling to Rotten, six equal steps) lit up to the current
-- stage, with the stage names under it, the current one in the full text colour. Rotten fills
-- the whole strip red. One segment per stage, under its name (as Skills give one per
-- level), not ten; pointing at it puts the stage's name in the help line.
local function drawPhaseStrip(card, x, y, w, d)
    local T, tm = ZeD.T, ZeD.TM
    local A = ZeD.Atoms
    local n = #PHASES
    local bh = T.fillBarH
    local f5 = T.fontF5
    local locked = d.skill < 2
    -- (QA's visual noise audit 31, Nov 20 2026: a locked strip was an empty bar with a "Farming 2" tag; it is hidden,
    -- and the body's one dim line says what more skill shows. This also ends bug B7's tag over the bars.)
    if locked then return 0 end
    local lit, fillC = 0, T.accent
    if not locked and d.phase ~= nil then
        lit = d.phase + 1
        if d.phase == 5 then fillC = T.danger end
    end
    -- QA's visual audit B7, Nov 20 2026: the "Farming 2" tag was drawn over the strip's right end. Locked, the
    -- strip (and its stage names) stops short and the tag sits in the room after it.
    local fullW = w
    if locked then w = math.max(n, w - UI.tagW(lockTag(2)) - T.px(6)) end
    if A.drawSegFill(card, x, y, w, bh, n, lit, fillC) and lit > 0 and PHASES[lit] then
        ZeD.Help.set(card, A.textCase(ZeD.tr(PHASES[lit])))
    end
    local cw = w / n
    local ly = y + bh + T.px(3)
    for i = 1, n do
        local cur = (not locked) and d.phase ~= nil and (i - 1) == d.phase
        local tc = cur and T.text or T.textDim
        local label = ZeD.CraftingCore.truncText(A.textCase(ZeD.tr(PHASES[i])), f5, math.floor(cw) - T.px(2))
        local lw = tm:MeasureStringX(f5, label)
        card:drawText(label, x + math.floor((i - 0.5) * cw - lw / 2), ly, tc.r, tc.g, tc.b, tc.a or 1, f5)
    end
    if locked then
        local tw = UI.tagW(lockTag(2))
        UI.tag(card, x + fullW - tw, y + math.floor((bh - T.px(16)) / 2), lockTag(2))
    end
    return bh + T.px(3) + tm:getFontHeight(f5)
end

-- The garden grid and its summary read each plot's plant. Asking the farming
-- system for it copies the plant's whole data table, so the grid reads the
-- plant each list entry already holds and brings those up to date a few times
-- a second instead of twice per plot per frame.
local GARDEN_SYNC_MS = 250
local function syncGarden(e, t)
    local list = (e and e.list) or { t }
    local now = getTimestampMs and getTimestampMs() or 0
    local holder = e or t
    if holder._gardenStamp and now - holder._gardenStamp < GARDEN_SYNC_MS and holder._gardenList == list then return end
    holder._gardenStamp, holder._gardenList = now, list
    local sys = farmSys()
    for _, o in ipairs(list) do
        local plant = o.obj
        if not plant and sys then plant = sys:getLuaObjectOnSquare(o.sq); o.obj = plant end
        if plant then pcall(plant.updateFromIsoObject, plant) end
    end
end

-- A plot's plant, or nil when the plot was dug up.
local function gardenPlant(o)
    local plant = o.obj
    if plant and plant:getIsoObject() then return plant end
    return nil
end

local function drawGarden(card, x, y, w, t, e)
    local T, tm = ZeD.T, ZeD.TM
    local A = ZeD.Atoms
    syncGarden(e, t)
    local list = (e and e.list) or { t }
    local cols = 8
    local gap = T.px(4)
    local cw = math.floor((w - gap * (cols - 1)) / cols)
    local ch = T.px(28)
    local f5 = T.fontF5
    for i, o in ipairs(list) do
        local c = (i - 1) % cols
        local r = math.floor((i - 1) / cols)
        local cx = x + c * (cw + gap)
        local cy = y + r * (ch + gap)
        local plant = gardenPlant(o)
        local cur = o.key == t.key
        local plowed = plant and plant.state == "plow"
        local fid = "farm:g:" .. i
        -- the plot you are on: the selected wash; the pointer: the hover wash; a plain 1u frame
        if cur then
            local ac = T.accent
            card:drawRect(cx, cy, cw, ch, T.selectionA, ac.r, ac.g, ac.b)
        end
        if UI.hovered(card, fid) then
            local hv = T.hover
            card:drawRect(cx, cy, cw, ch, hv.a, hv.r, hv.g, hv.b)
        end
        local onFocus = false
        local fm = card.focusOf and card:focusOf(fid)
        if fm then onFocus = ZeD.Focus.mark(card, cx, cy, cw, ch, fm) end
        A.frame(card, cx, cy, cw, ch, T.border)
        local label, dotC = "?", nil
        if plant then
            if plowed then label = A.textCase(ZeD.tr("UI_ZeD_Farm_GardenPlowed"))
            else
                label = gardenLabel(plant.typeOfSeed)
                dotC = urgency(plant, t.pestsVisible, t.d and t.d.skill)
            end
        end
        local tc = onFocus and T.textOnFocus or (cur and T.text or T.textDim)
        local lw = tm:MeasureStringX(f5, label)
        local fh = tm:getFontHeight(f5)
        if dotC then
            local ds = T.px(6)
            local total = ds + T.px(3) + fh
            local ty = cy + math.floor((ch - total) / 2)
            A.drawStatusDot(card, cx + math.floor((cw - ds) / 2), ty, dotC, ds)
            card:drawText(label, cx + math.floor((cw - lw) / 2), ty + ds + T.px(3), tc.r, tc.g, tc.b, tc.a or 1, f5)
        else
            card:drawText(label, cx + math.floor((cw - lw) / 2), cy + math.floor((ch - fh) / 2), tc.r, tc.g, tc.b, tc.a or 1, f5)
        end
        local idx = i
        card:zone({ fid = fid, x = cx, y = cy, w = cw, h = ch, body = true,
            help = ZeD.tr("UI_ZeD_Farm_HelpPlot"),
            run = function(c)
                if e and e.list and e.list[idx] then
                    e.idx = idx
                    e.t = e.list[idx]
                    e.t._refreshT = OC.REFRESH
                    c._confirm = nil
                    c._pendingFocus = "farm:g:" .. idx
                end
            end })
    end
    local rows = math.ceil(#list / cols)
    return rows * ch + math.max(0, rows - 1) * gap
end

local function gardenSummary(t, e)
    local list = (e and e.list) or { t }
    syncGarden(e, t)
    -- (QA FA2: counted by the cells' own water mark, red as dry and orange as thirsty, from Farming 3)
    local parched, thirsty = 0, 0
    local skill = t.d and t.d.skill
    for _, o in ipairs(list) do
        local plant = gardenPlant(o)
        if plant and plant.state == "seeded" and plant:isAlive() then
            local _, wr = waterMark(plant, skill)
            if wr == 2 then parched = parched + 1 elseif wr == 1 then thirsty = thirsty + 1 end
        end
    end
    local parts = {}
    if parched > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Farm_SummaryDry", parched) end
    if thirsty > 0 then parts[#parts + 1] = ZeD.tr("UI_ZeD_Farm_SummaryThirsty", thirsty) end
    if #parts == 0 then return ZeD.tr(#list == 1 and "UI_ZeD_Farm_SummaryPlotOne" or "UI_ZeD_Farm_SummaryPlotMany", #list) end
    return table.concat(parts, " " .. DOT .. " ")
end

function def.body(card, x, y, w, t, player)
    local T, tm = ZeD.T, ZeD.TM
    local d = t.d
    if not d then return 0 end
    local e = card.entry
    local y0 = y
    local gap = T.px(8)
    if d.plowed then
        y = y + drawPlantTag(card, x, y, w, d, d.name, ZeD.textCase(ZeD.tr("UI_ZeD_Farm_SkillReadyToSow", d.skill))) + gap
        if #d.seeds > 0 then
            y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Farm_SowFromBags"), d.month or "")
            for i, r in ipairs(d.seeds) do
                local rr = r
                y = y + UI.pick(card, x, y, w, {
                    tex = r.tex, name = r.name, tag = r.tag, tagC = r.tagC,
                    help = ZeD.tr("UI_ZeD_Farm_HelpSowSeed", r.name),
                    button = getText("ContextMenu_Sow_Seed"), fid = "farm:sow:" .. i,
                    run = function(c, p)
                        local seed = p:getInventory():getFirstTypeEvalRecurse(rr.seedName, goodSeed)
                        if not seed or not ISFarmingMenu.walkToPlant(p, t.sq) then return end
                        ISInventoryPaneContextMenu.transferIfNeeded(p, seed)
                        ISTimedActionQueue.add(ISSeedActionNew:new(p, seed, rr.typeOfSeed, t.obj))
                    end,
                })
            end
            y = y + gap
        end
    else
        y = y + drawPlantTag(card, x, y, w, d, d.name, ZeD.textCase(ZeD.tr("UI_ZeD_Farm_Skill", d.skill))) + gap
        -- (QA's visual noise audit 31, Nov 20 2026: "Farming 2", "Farming 3", "Farming 4" and "Farming 6" sat on four
        -- mostly empty bars. One dim line names the levels that show more; the locked bars and tags are gone.)
        if d.alive then
            local more = {}
            for _, lv in ipairs({ 2, 3, 4, 6 }) do
                if d.skill < lv then more[#more + 1] = tostring(lv) end
            end
            if #more > 0 then
                local list = more[#more]
                if #more > 1 then
                    list = ZeD.tr("UI_ZeD_Farm_ListAnd", table.concat(more, ", ", 1, #more - 1), more[#more])
                end
                y = y + UI.para(card, x, y, w, ZeD.tr("UI_ZeD_Farm_MoreAt", list), T.textDim) + gap
            end
        end
        local stripH = drawPhaseStrip(card, x, y, w, d)
        if stripH > 0 then y = y + stripH + gap end
        -- Next stage / Compost (Next stage only once the skill reads it)
        local compostV = d.compost and txt("Farming_Compost_True", "Yes") or txt("Farming_Compost_False", "No")
        if d.alive and d.skill < 6 then
            y = y + UI.pair(card, x, y, w, ZeD.tr("Farming_Compost"), compostV) + gap
        else
            local nextV = d.alive and (d.next or "?") or txt("UI_No", "No")
            y = y + UI.pair(card, x, y, w, ZeD.tr("UI_ZeD_Farm_NextStage"), nextV, ZeD.tr("Farming_Compost"), compostV) + gap
        end
        -- WATER
        if d.alive then
            local word, dotC = waterWord(d.water), d.waterC
            if d.skill >= 4 then
                local lo = d.waterNeeded
                local hi = d.firstStage and 100 or math.min(100, d.waterMax or 100)
                local fillC = T.info
                if not d.firstStage then
                    local a = farming_vegetableconf.calcWater(d.waterNeeded, d.water)
                    local b = farming_vegetableconf.calcWater(d.water, d.waterMax or 100)
                    if a == -1 or b == -1 then fillC = UI.hex("#FA8C00") elseif a < -1 or b < -1 then fillC = T.danger end
                elseif d.water < d.waterNeeded then fillC = T.danger end
                y = y + UI.meter(card, x, y, w, ZeD.tr("Fluid_Name_Water"), word, dotC, d.water, fillC, { lo, hi }) + gap
            else
                -- (the word without its locked bar: audit 31; its mark from Farming 3, as vanilla's: QA FA2)
                local wv = word
                if dotC then
                    wv = function(rx, ry, rh)
                        local f2 = T.fontF2
                        local ww = tm:MeasureStringX(f2, word)
                        ZeD.Atoms.drawTextRight(card, word, rx, ry + math.floor((rh - tm:getFontHeight(f2)) / 2), f2, T.text)
                        ZeD.Atoms.drawStatusDot(card, rx - ww - T.px(10), ry + math.floor((rh - T.px(6)) / 2), dotC, T.px(6))
                    end
                end
                y = y + UI.pairWide(card, x, y, w, ZeD.tr("Fluid_Name_Water"), wv) + gap
            end
        end
        -- (the director's call FA8, Nov 26 2026) Water from: each container he can pour, by name with what it holds
        -- and what it gives the plant, as the game's watering menu lists them (the one in his hand alone when it
        -- holds water, else every one in his inventory). The picked one has the selected wash; Use picks it and Water
        -- pours from it. Unpicked, the biggest leads, as before.
        if #d.water_src > 0 then
            y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Farm_WaterFrom"), tostring(#d.water_src))
            local cur = pickedSource(t, d.water_src)
            local missing = math.ceil((100 - d.water) / 10)
            local useW = ZeD.tr("UI_ZeD_Card_VerbUse")
            for i, it in ipairs(d.water_src) do
                local item = it
                local name = call(it, "getName") or "?"
                if sameItem(it, cur) then
                    local rh = math.max(T.px(26), T.buttonH)
                    card:drawRect(x, y, w, rh, T.selectionA, T.accent.r, T.accent.g, T.accent.b)
                end
                y = y + UI.pick(card, x, y, w, {
                    tex = call(it, "getTex"), name = name, where = sourceAmount(it),
                    gain = "+" .. tostring(math.min(ISFarmingMenu.getWaterUsesInteger(it), missing, 10) * 10),
                    button = useW, fid = "farm:water:" .. i,
                    help = ZeD.tr("UI_ZeD_Farm_HelpWaterFrom", name),
                    run = function(c, p) t.waterPick = item end,
                })
            end
            y = y + gap
        end
        -- Pests and disease: rows with Treat (vanilla lets you spray blind). A Treat with no spray to
        -- use is drawn only under Show all (greyed, with what it needs), as the verb row's is.
        if d.alive then
            local known, count = t.pestsVisible, 0
            for _, pe in ipairs(d.pests) do if pe.lvl > 0 then count = count + 1 end end
            local right = known and (count > 0 and tostring(count) or txt("Farming_None", "None")) or nil   -- (no lock tag: audit 31)
            y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Farm_Pests"), right)
            local showAll = ZeD.Disclose.setting() == "all"
            for i, pe in ipairs(d.pests) do
                local rh = math.max(T.px(24), T.buttonH)
                local f1 = T.fontF1
                local ac = T.accent
                card:drawText(ZeD.textCase(ZeD.tr(pe.def.label)), x + T.px(2), y + math.floor((rh - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
                local treat = ZeD.tr("UI_ZeD_Farm_Treat")
                local bw = UI.buttonW(treat)
                local bx = x + w - bw - T.px(2)
                local bh = T.buttonH - T.px(4)
                local by = y + math.floor((rh - bh) / 2)
                local fid = "farm:treat:" .. i
                local pp = pe
                local vx = bx - T.px(12)
                if pe.spray or showAll then
                    UI.button(card, bx, by, treat, { w = bw, h = bh, disabled = pe.spray == nil, fid = fid, body = true,
                        help = ZeD.tr("UI_ZeD_Farm_HelpTreatPest", ZeD.textCase(ZeD.tr(pe.def.label))),
                        focus = card:focusOf(fid),
                        run = pe.spray and function(c, p) t.treat(p, pp.def) end or nil })
                else
                    vx = x + w - T.px(2)
                end
                if known then
                    local word, dc = pestWord(pe.lvl)
                    local f3 = T.fontF3
                    local ww = tm:MeasureStringX(f3, word)
                    card:drawText(word, vx - ww, y + math.floor((rh - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, f3)
                    if dc then ZeD.Atoms.drawStatusDot(card, vx - ww - T.px(10), y + math.floor((rh - T.px(6)) / 2), dc, T.px(6)) end
                end
                card:drawRect(x, y + rh - T.px(1), w, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
                y = y + rh
                -- Show all: why a greyed Treat cannot run (only for a pest you can see)
                if showAll and known and pe.lvl > 0 and not pe.spray then
                    y = y + T.px(2) + ZeD.Molecules.drawNeedsLine(card, x, y + T.px(2), w,
                        ZeD.tr("UI_ZeD_Disclose_Needs", ZeD.btnCase(treat), OC.itemName(pe.def.spray, pe.def.sprayName))) + T.px(2)
                end
            end
            y = y + gap
        end
    end
    -- Garden in reach
    y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Farm_Garden"), gardenSummary(t, e)) + T.px(6)
    y = y + drawGarden(card, x, y, w, t, e)
    return y - y0
end

OC.register(def)
