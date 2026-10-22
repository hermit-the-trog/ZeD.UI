-- ZeD-UI/42/media/lua/client/ZeD/ObjectCardFarm.lua
-- ============================================================================
-- OBJECT CARD: FARM PLOTS (HOOK_MAP row 12; mockup zed_info_cards_v1.html)
-- The plant card keeps vanilla's Farming-skill gates: the phase reads at
-- Farming 2, pests at 3 (+2 with a magnifier in hand), the water bar at 4 and
-- the next-stage timing at 6; health and fertilizer are never shown. A locked
-- reading carries a FARMING n tag. Levels use vanilla's words. The garden
-- strip and the header arrows step through every plot in reach (vanilla's
-- info cursor); plowed land gets a SOW list with season tags (Farming 6 or
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

local function waterSources(player)
    local out = {}
    local h = player:getPrimaryHandItem()
    if h and ISFarmingMenu.getWaterUsesInteger(h) > 0 then
        out[1] = h
        return out
    end
    local items = player:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if ISFarmingMenu.getWaterUsesInteger(it) > 0 then out[#out + 1] = it end
    end
    table.sort(out, function(a, b) return ISFarmingMenu.getWaterUsesInteger(a) > ISFarmingMenu.getWaterUsesInteger(b) end)
    return out
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

-- vanilla's water words, with a dot
local function waterWord(lvl)
    local T = ZeD.T
    if lvl > 80 then return txt("Farming_Well_watered", "Well watered"), T.positive end
    if lvl > 60 then return txt("Farming_Fine", "Fine"), T.positive end
    if lvl > 50 then return txt("Farming_Thirsty", "Thirsty"), T.warning end
    if lvl > 25 then return txt("Farming_Dry", "Dry"), T.danger end
    return txt("Farming_Parched", "Parched"), T.danger
end

local function pestWord(lvl)
    local T = ZeD.T
    if lvl <= 0 then return txt("Farming_None", "None"), nil end
    if lvl < 10 then return txt("Farming_Light", "Light"), T.warning end
    if lvl < 30 then return txt("Farming_Moderate", "Moderate"), T.warning end
    return txt("Farming_Heavy", "Heavy"), T.danger
end

-- Most urgent need of a plot for the garden strip (honours the pest gate).
local function urgency(plant, pestsVisible)
    local T = ZeD.T
    if plant.state == "plow" then return nil, 0 end
    if not plant:isAlive() then return T.danger, 3 end
    local lvl = plant.waterLvl or 0
    if lvl <= 50 then return T.danger, (lvl <= 25 and 3 or 2) end
    if pestsVisible then
        for _, p in ipairs(PESTS) do
            if (plant[p.key] or 0) >= 30 then return T.danger, 2 end
        end
    end
    if lvl <= 60 then return T.warning, 1 end
    if pestsVisible then
        for _, p in ipairs(PESTS) do
            if (plant[p.key] or 0) > 0 then return T.warning, 1 end
        end
    end
    return T.positive, 0
end

local def = { id = "plant", keepOnLoss = true }

local function targetFor(plant)
    local sq = plant:getSquare()
    if not sq then return nil end
    return { obj = plant, sq = sq, key = OC.keyOf(sq, "plant") }
end

-- obj: a CPlantGlobalObject, or anything with a square
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
                    name = ((si and si:getDisplayName()) or seedName) .. " x" .. tostring(n),
                    tex = si and call(si, "getNormalTexture") or nil,
                }
                local knows = skill >= 6 or (props.seasonRecipe and player:isRecipeActuallyKnown(props.seasonRecipe))
                if seasons and knows and props.sowMonth then
                    local T = ZeD.T
                    if inList(props.bestMonth) then row.tag, row.tagC = ZeD.upper(ZeD.tr("Farming_Tooltip_BestMonth2")), T.positive
                    elseif inList(props.riskMonth) then row.tag, row.tagC = ZeD.tr("UI_ZeD_Farm_TagRiskyMonth"), T.warning
                    elseif inList(props.sowMonth) then row.tag, row.tagC = ZeD.tr("UI_ZeD_Farm_TagInSeason"), T.positive
                    else row.tag, row.tagC = ZeD.upper(ZeD.tr("Farming_Tooltip_BadMonth")), T.danger end
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

    local verbs, needs = {}, {}
    if d.plowed then
        verbs[#verbs + 1] = { id = "sow", label = getText("ContextMenu_Sow_Seed"), enabled = #d.seeds > 0, primary = #d.seeds > 0, jump = "farm:sow:1" }
        if #d.seeds == 0 then needs[#needs + 1] = ZeD.tr("UI_ZeD_Farm_NeedSeeds") end
    else
        local seeded = plant.state == "seeded"
        local canWater = d.alive and seeded and d.water < 100 and #d.water_src > 0
        local thirsty = d.water <= 60
        local canHarvest = plant:canHarvest()
        verbs[#verbs + 1] = { id = "water", label = getText("ContextMenu_Water"), enabled = canWater, primary = canWater and thirsty and not canHarvest,
            run = function(p, tt)
                local src = waterSources(p)[1]
                local pl = tt.obj
                if not src or not pl then return end
                local use = math.min(ISFarmingMenu.getWaterUsesInteger(src), math.ceil((100 - (pl.waterLvl or 0)) / 10), 10)
                if use < 1 then return end
                if p:getPrimaryHandItem() ~= src then ISTimedActionQueue.add(ISEquipWeaponAction:new(p, src, 50, true)) end
                if not ISFarmingMenu.walkToPlant(p, tt.sq) then return end
                ISTimedActionQueue.add(ISWaterPlantAction:new(p, src, use, tt.sq, 20 + (6 * use)))
            end }
        verbs[#verbs + 1] = { id = "fert", label = ZeD.tr("UI_ZeD_Farm_Fertilize"), enabled = d.fert ~= nil,
            run = function(p, tt)
                local inv2 = p:getInventory()
                local it = inv2:getFirstTypeRecurse("Fertilizer") or inv2:getFirstTagRecurse(ItemTag.FERTILIZER)
                if not it or not ISFarmingMenu.walkToPlant(p, tt.sq) then return end
                local hand = ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), it, true)
                ISTimedActionQueue.add(ISFertilizeAction:new(p, hand or it, tt.obj, 100))
            end }
        if d.compostItem then
            verbs[#verbs + 1] = { id = "compost", label = getText("Farming_Compost"), enabled = true,
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
        verbs[#verbs + 1] = { id = "treat", label = ZeD.tr("UI_ZeD_Farm_Treat"), enabled = seeded and anySpray, jump = firstTreat and ("farm:treat:" .. firstTreat) or nil }
        verbs[#verbs + 1] = { id = "harvest", label = getText("ContextMenu_Harvest"), enabled = canHarvest, primary = canHarvest,
            run = function(p, tt)
                if ISFarmingMenu.walkToPlant(p, tt.sq) then ISTimedActionQueue.add(ISHarvestPlantAction:new(p, tt.obj, 100)) end
            end }
        verbs[#verbs + 1] = { id = "dig", label = ZeD.tr("UI_ZeD_Farm_DigUp"), enabled = d.shovel ~= nil, danger = true,
            confirm = d.alive and ZeD.tr("UI_ZeD_Farm_ConfirmDig", string.lower(cropName(plant))) or ZeD.tr("UI_ZeD_Farm_ConfirmClear", string.lower(d.name)),
            run = function(p, tt)
                if not ISFarmingMenu.walkToPlant(p, tt.sq) then return end
                local hand = ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), ISFarmingMenu.getShovel(p), true)
                ISTimedActionQueue.add(ISShovelAction:new(p, hand, tt.obj, 40))
            end }
        if d.alive and seeded and d.water < 100 and #d.water_src == 0 then needs[#needs + 1] = ZeD.tr("UI_ZeD_Farm_NeedWater") end
        if pestsVisible then
            for _, pe in ipairs(d.pests) do
                if pe.lvl > 0 and not pe.spray then needs[#needs + 1] = ZeD.tr("UI_ZeD_Farm_NeedSpray", OC.itemName(pe.def.spray, pe.def.sprayName)) end
            end
        end
        if not d.shovel then needs[#needs + 1] = ZeD.tr("UI_ZeD_Farm_NeedShovel") end
    end
    t.verbs, t.needs = verbs, needs
    t.pestsVisible = pestsVisible
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
function def.pill(t)
    local T = ZeD.T
    local d = t.d
    if not d then return nil end
    if d.plowed then return ZeD.tr("UI_ZeD_Farm_PillEmpty"), T.textDim end
    if d.state == "rotten" then return ZeD.upper(ZeD.tr("Farming_Rotten")), T.danger end
    if not d.alive then return ZeD.upper(d.state == "harvested" and getText("Farming_Harvested") or getText("Farming_Dead")), T.danger end
    if t.obj:canHarvest() then return ZeD.tr("UI_ZeD_Farm_PhaseReady"), T.positive end
    local w = d.water
    if w <= 25 then return ZeD.upper(ZeD.tr("Farming_Parched")), T.danger end
    if w <= 50 then return ZeD.upper(ZeD.tr("Farming_Dry")), T.danger end
    if w <= 60 then return ZeD.upper(ZeD.tr("Farming_Thirsty")), T.warning end
    return ZeD.tr("UI_ZeD_Farm_PillGrowing"), T.positive
end

-- ---------------------------------------------------------------------------
-- BODY
-- ---------------------------------------------------------------------------
local function lockTag(n) return ZeD.tr("UI_ZeD_Farm_LockTag", n) end

local function drawPlantTag(card, x, y, w, d, title, sub)
    local T, tm = ZeD.T, ZeD.TM
    local ps = T.px(40)
    local s2 = T.surf2
    local tint = d.plowed and UI.hex("#7A5A3A") or T.positive
    card:drawRect(x, y, ps, ps, 1, s2.r, s2.g, s2.b)
    card:drawRect(x, y, ps, ps, 0.16, tint.r, tint.g, tint.b)
    card:drawRectBorder(x, y, ps, ps, T.borderS.a, T.borderS.r, T.borderS.g, T.borderS.b)
    if d.tex then card:drawTextureScaledAspect(d.tex, x + T.px(4), y + T.px(4), ps - 2 * T.px(4), ps - 2 * T.px(4), 1, 1, 1, 1) end
    local tx = x + ps + T.px(10)
    local nameY = y + T.px(2)
    UI.big(card, ZeD.CraftingCore.truncText(title, T.fontF4, w - ps - T.px(10)), tx, nameY, 17, T.text)
    local f3 = T.fontF3
    card:drawText(sub, tx, y + ps - tm:getFontHeight(f3) - T.px(1), T.textDim.r, T.textDim.g, T.textDim.b, T.textDim.a or 1, f3)
    return ps
end

local function drawPhaseStrip(card, x, y, w, d)
    local T, tm = ZeD.T, ZeD.TM
    local n = #PHASES
    local gap = T.px(3)
    local cw = math.floor((w - gap * (n - 1)) / n)
    local ch = T.px(22)
    local f5 = T.fontF5
    local locked = d.skill < 2
    for i = 1, n do
        local cx = x + (i - 1) * (cw + gap)
        local idx = i - 1
        local bg, tc = T.surf1, T.textDim
        local ba = bg.a
        if not locked and d.phase ~= nil then
            if idx < d.phase and d.phase ~= 5 then bg, tc, ba = ZeD.colorBlend(T.surf2, T.positive, 0.22), T.text, 1
            elseif idx == d.phase then bg, tc, ba = T.accent, T.textOnAccent, 1 end
        end
        card:drawRect(cx, y, cw, ch, ba, bg.r, bg.g, bg.b)
        local bc = (not locked and idx == d.phase) and T.accentBright or T.borderS
        if i == n then
            -- dashed edge for ROTTEN
            local seg = T.px(3)
            local sx = cx
            while sx < cx + cw do
                card:drawRect(sx, y, math.min(seg, cx + cw - sx), T.px(1), bc.a or 1, bc.r, bc.g, bc.b)
                card:drawRect(sx, y + ch - T.px(1), math.min(seg, cx + cw - sx), T.px(1), bc.a or 1, bc.r, bc.g, bc.b)
                sx = sx + seg * 2
            end
            local sy = y
            while sy < y + ch do
                card:drawRect(cx, sy, T.px(1), math.min(seg, y + ch - sy), bc.a or 1, bc.r, bc.g, bc.b)
                card:drawRect(cx + cw - T.px(1), sy, T.px(1), math.min(seg, y + ch - sy), bc.a or 1, bc.r, bc.g, bc.b)
                sy = sy + seg * 2
            end
        else
            card:drawRectBorder(cx, y, cw, ch, bc.a or 1, bc.r, bc.g, bc.b)
        end
        local label = ZeD.CraftingCore.truncText(ZeD.upper(ZeD.tr(PHASES[i])), f5, cw - T.px(4))
        local lw = tm:MeasureStringX(f5, label)
        card:drawText(label, cx + math.floor((cw - lw) / 2), y + math.floor((ch - tm:getFontHeight(f5)) / 2), tc.r, tc.g, tc.b, tc.a or 1, f5)
    end
    if locked then
        local tw = UI.tagW(lockTag(2))
        local s1 = T.surf1
        card:drawRect(x + w - tw - T.px(6), y + T.px(1), tw + T.px(6), ch - 2 * T.px(1), 1, s1.r, s1.g, s1.b)
        UI.tag(card, x + w - tw - T.px(2), y + math.floor((ch - T.px(16)) / 2), lockTag(2), T.textDim)
    end
    return ch
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
        local s2 = T.surf2
        if not plowed then card:drawRect(cx, cy, cw, ch, s2.a, s2.r, s2.g, s2.b) end
        local bc = cur and T.accent or T.border
        if plowed and not cur then
            local seg = T.px(3)
            local sx = cx
            while sx < cx + cw do
                card:drawRect(sx, cy, math.min(seg, cx + cw - sx), T.px(1), bc.a or 1, bc.r, bc.g, bc.b)
                card:drawRect(sx, cy + ch - T.px(1), math.min(seg, cx + cw - sx), T.px(1), bc.a or 1, bc.r, bc.g, bc.b)
                sx = sx + seg * 2
            end
            local sy = cy
            while sy < cy + ch do
                card:drawRect(cx, sy, T.px(1), math.min(seg, cy + ch - sy), bc.a or 1, bc.r, bc.g, bc.b)
                card:drawRect(cx + cw - T.px(1), sy, T.px(1), math.min(seg, cy + ch - sy), bc.a or 1, bc.r, bc.g, bc.b)
                sy = sy + seg * 2
            end
        else
            card:drawRectBorder(cx, cy, cw, ch, bc.a or 1, bc.r, bc.g, bc.b)
            if cur then card:drawRectBorder(cx + T.px(1), cy + T.px(1), cw - 2 * T.px(1), ch - 2 * T.px(1), 1, bc.r, bc.g, bc.b) end
        end
        local label, dotC = "?", nil
        if plant then
            if plowed then label = ZeD.tr("UI_ZeD_Farm_GardenPlowed")
            else
                label = ZeD.upper(string.sub(cropName(plant), 1, 3))
                dotC = urgency(plant, t.pestsVisible)
            end
        end
        local tc = cur and T.text or T.textDim
        local lw = tm:MeasureStringX(f5, label)
        local fh = tm:getFontHeight(f5)
        if dotC then
            local ds = T.px(6)
            local total = ds + T.px(3) + fh
            local ty = cy + math.floor((ch - total) / 2)
            ZeD.Atoms.drawStatusDot(card, cx + math.floor((cw - ds) / 2), ty, dotC, ds)
            card:drawText(label, cx + math.floor((cw - lw) / 2), ty + ds + T.px(3), tc.r, tc.g, tc.b, tc.a or 1, f5)
        else
            card:drawText(label, cx + math.floor((cw - lw) / 2), cy + math.floor((ch - fh) / 2), tc.r, tc.g, tc.b, tc.a or 1, f5)
        end
        local idx = i
        card:zone({ fid = "farm:g:" .. i, x = cx, y = cy, w = cw, h = ch, body = true,
            run = function(c)
                if e and e.list and e.list[idx] then
                    e.idx = idx
                    e.t = e.list[idx]
                    e.t._refreshT = OC.REFRESH
                    c._confirm = nil
                    c._pendingFocus = "farm:g:" .. idx
                end
            end })
        if card._fid == ("farm:g:" .. i) then card:drawRect(cx, cy, cw, ch, 0.55, T.accent.r, T.accent.g, T.accent.b) end
    end
    local rows = math.ceil(#list / cols)
    return rows * ch + math.max(0, rows - 1) * gap
end

local function gardenSummary(t, e)
    local list = (e and e.list) or { t }
    syncGarden(e, t)
    local parched, thirsty = 0, 0
    for _, o in ipairs(list) do
        local plant = gardenPlant(o)
        if plant and plant.state == "seeded" and plant:isAlive() then
            local w = plant.waterLvl or 0
            if w <= 50 then parched = parched + 1 elseif w <= 60 then thirsty = thirsty + 1 end
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
        y = y + drawPlantTag(card, x, y, w, d, d.name, ZeD.tr("UI_ZeD_Farm_SkillReadyToSow", d.skill)) + gap
        if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + gap end
        if #d.seeds > 0 then
            y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Farm_SowFromBags"), ZeD.upper(d.month or ""))
            for i, r in ipairs(d.seeds) do
                local rr = r
                y = y + UI.pick(card, x, y, w, {
                    tex = r.tex, name = r.name, tag = r.tag, tagC = r.tagC,
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
        y = y + drawPlantTag(card, x, y, w, d, d.name, ZeD.tr("UI_ZeD_Farm_Skill", d.skill)) + gap
        y = y + drawPhaseStrip(card, x, y, w, d) + gap
        -- NEXT STAGE / COMPOST
        local nextV
        if not d.alive then nextV = txt("UI_No", "No")
        elseif d.skill >= 6 then nextV = d.next or "?"
        else
            nextV = function(rx, ry, rh)
                local tw = UI.tagW(lockTag(6))
                UI.tag(card, rx - tw, ry + math.floor((rh - T.px(16)) / 2), lockTag(6), T.textDim)
            end
        end
        y = y + UI.pair(card, x, y, w, ZeD.tr("UI_ZeD_Farm_NextStage"), nextV, ZeD.upper(ZeD.tr("Farming_Compost")), d.compost and txt("Farming_Compost_True", "Yes") or txt("Farming_Compost_False", "No")) + gap
        -- WATER
        if d.alive then
            local word, dotC = waterWord(d.water)
            if d.skill >= 4 then
                local lo = d.waterNeeded
                local hi = d.firstStage and 100 or math.min(100, d.waterMax or 100)
                local fillC = T.info
                if not d.firstStage then
                    local a = farming_vegetableconf.calcWater(d.waterNeeded, d.water)
                    local b = farming_vegetableconf.calcWater(d.water, d.waterMax or 100)
                    if a == -1 or b == -1 then fillC = UI.hex("#FA8C00") elseif a < -1 or b < -1 then fillC = T.danger end
                elseif d.water < d.waterNeeded then fillC = T.danger end
                y = y + UI.meter(card, x, y, w, ZeD.upper(ZeD.tr("Fluid_Name_Water")), word, dotC, d.water, fillC, { lo, hi }) + gap
            else
                y = y + UI.meter(card, x, y, w, ZeD.upper(ZeD.tr("Fluid_Name_Water")), word, dotC, 0, nil, nil, lockTag(4)) + gap
            end
        end
        if t.needs and #t.needs > 0 then y = y + UI.needs(card, x, y, w, t.needs) + gap end
        -- PESTS AND DISEASE: rows with TREAT (vanilla lets you spray blind)
        if d.alive then
            local known, count = t.pestsVisible, 0
            for _, pe in ipairs(d.pests) do if pe.lvl > 0 then count = count + 1 end end
            local right = known and (count > 0 and tostring(count) or ZeD.upper(txt("Farming_None", "None"))) or lockTag(3)
            y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Farm_Pests"), right)
            for i, pe in ipairs(d.pests) do
                local rh = T.px(24)
                local f1 = T.fontF1
                local ac = T.accent
                card:drawText(ZeD.upper(ZeD.tr(pe.def.label)), x + T.px(2), y + math.floor((rh - tm:getFontHeight(f1)) / 2), ac.r, ac.g, ac.b, 1, f1)
                local bw = UI.buttonW(ZeD.tr("UI_ZeD_Farm_Treat"))
                local bx = x + w - bw - T.px(2)
                local by = y + math.floor((rh - T.px(20)) / 2)
                local fid = "farm:treat:" .. i
                UI.button(card, bx, by, ZeD.tr("UI_ZeD_Farm_Treat"), { h = T.px(20), disabled = pe.spray == nil, focused = card._fid == fid })
                local pp = pe
                card:zone({ fid = fid, x = bx, y = by, w = bw, h = T.px(20), body = true,
                    run = pe.spray and function(c, p)
                        local spray = findSpray(p, pp.def.spray)
                        if not spray or not ISFarmingMenu.walkToPlant(p, t.sq) then return end
                        ISWorldObjectContextMenu.equip(p, p:getPrimaryHandItem(), spray, true)
                        ISTimedActionQueue.add(ISCurePlantAction:new(p, spray, 1, t.obj, 100, pp.def.cure))
                    end or nil })
                local vx = bx - T.px(12)
                if known then
                    local word, dc = pestWord(pe.lvl)
                    local f3 = T.fontF3
                    local ww = tm:MeasureStringX(f3, word)
                    card:drawText(word, vx - ww, y + math.floor((rh - tm:getFontHeight(f3)) / 2), T.text.r, T.text.g, T.text.b, T.text.a, f3)
                    if dc then ZeD.Atoms.drawStatusDot(card, vx - ww - T.px(11), y + math.floor((rh - T.px(6)) / 2), dc, T.px(6)) end
                end
                card:drawRect(x, y + rh - T.px(1), w, T.px(1), T.border.a, T.border.r, T.border.g, T.border.b)
                y = y + rh
            end
            y = y + gap
        end
    end
    -- GARDEN IN REACH
    y = y + UI.section(card, x, y, w, ZeD.tr("UI_ZeD_Farm_Garden"), gardenSummary(t, e)) + T.px(6)
    y = y + drawGarden(card, x, y, w, t, e)
    return y - y0
end

OC.register(def)
